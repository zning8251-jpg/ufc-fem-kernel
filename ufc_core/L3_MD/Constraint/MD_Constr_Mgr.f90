!===============================================================================
! MODULE: MD_Constr_Mgr
! LAYER:  L3_MD
! DOMAIN: Constraint
! ROLE:   Mgr — Domain container with Register/Query/Validate operations
! BRIEF:  Constraint domain container (Tie/MPC/Coupling/Rigid) with Algo+Ctx.
!===============================================================================
!
! Four-type layout:
!   [Desc]  MD_ConstraintUnion (re-exported from MD_Constr_Def)
!   [Algo]  MD_Constr_Algo     — enforcement method & penalty config
!   [Ctx]   MD_Constr_Ctx      — transient per-operation context
!   [State] (none in L3 — purely Desc)
!
! Container: MD_Constraint_Domain — holds Desc union + Algo
!
! Arg types:
!   MD_Constr_GetTie_Arg / GetMPC_Arg / GetCpl_Arg / GetRigid_Arg
!   MD_Constr_GetSummary_Arg
!
! Procedures:
!   [P0] Init / Finalize / ValidateAll
!   [P0] AddTie / AddMPC / AddCpl / AddRigid  (Register)
!   [P0] GetTie / GetMPC / GetCpl / GetRigid  (Query)
!   [P1] SyncFromUnion
!   [P3] GetSummary
!
! Status: FOUR-TYPE | SIO-REFACTORED | ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Const | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Constraint/CONTRACT.md

MODULE MD_Constr_Mgr
  USE IF_Prec_Core,               ONLY: wp, i4
  USE IF_Err_Brg,            ONLY: ErrorStatusType, init_error_status, &
                                    IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Constr_Def,   ONLY: CONSTRAINT_TIE, CONSTRAINT_MPC, &
                                    CONSTRAINT_COUPLING, CONSTRAINT_RIGID, &
                                    TieConstraintDef, MPCConstraintDef, &
                                    CplConstraintDef, RigidBodyDef, &
                                    MD_ConstraintUnion
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTRAINT_MAX_CONSTRAINTS = 10000_i4

  !--------------------------------------------------------------------
  ! [Algo] MD_Constr_Algo — algorithm parameters
  ! Frozen after L6_AP parse; read-only during Solve phase.
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_Algo
    INTEGER(i4) :: default_enforcement = 1_i4    !! 1=Transform, 2=Lagrange, 3=Penalty
    REAL(wp)    :: default_penalty       = 1.0E+10_wp  !! Default penalty stiffness
    REAL(wp)    :: default_tolerance     = 1.0E-8_wp   !! Constraint tolerance
    INTEGER(i4) :: max_aug_lag_iter      = 10_i4       !! Max augmented Lagrangian iterations
    LOGICAL     :: auto_detect_redundant = .TRUE.      !! Auto-detect redundant constraints
  END TYPE MD_Constr_Algo

  !--------------------------------------------------------------------
  ! [Ctx] MD_Constr_Ctx — transient context (per-operation, not stored)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_Ctx
    INTEGER(i4) :: current_constraint_id = 0_i4
    INTEGER(i4) :: operation_type        = 0_i4  ! 1=Add, 2=Modify, 3=Delete
    LOGICAL     :: validation_pending    = .FALSE.
    CHARACTER(LEN=64) :: last_operation  = ""
  END TYPE MD_Constr_Ctx

  ! MD_ConstraintUnion lives in MD_Constr_Def (breaks UFC_GlobalContainer cycle)
  PUBLIC :: MD_ConstraintUnion

  !--------------------------------------------------------------------
  ! MD_Constraint_Domain — domain container (Desc+Algo)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constraint_Domain
    !--- Desc (Write-Once) ---
    TYPE(MD_ConstraintUnion) :: constraint_union
    
    !--- State: None (purely Desc in L3) ---
    
    !--- Algo (Solve-phase read-only) ---
    TYPE(MD_Constr_Algo) :: algo
    
    !--- Ctx (transient, not stored) ---
    ! MD_Constr_Ctx created per-operation
    
    !--- Internal ---
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddTie
    PROCEDURE :: AddMPC
    PROCEDURE :: AddCpl
    PROCEDURE :: AddRigid
    PROCEDURE :: GetTie
    PROCEDURE :: GetMPC
    PROCEDURE :: GetCpl
    PROCEDURE :: GetRigid
    PROCEDURE :: ValidateAll
    PROCEDURE :: SyncFromUnion
    PROCEDURE :: GetSummary
  END TYPE MD_Constraint_Domain

  ! Index-based Get* args
  TYPE, PUBLIC :: MD_Constr_GetTie_Arg
    TYPE(TieConstraintDef) :: def
  END TYPE MD_Constr_GetTie_Arg
  TYPE, PUBLIC :: MD_Constr_GetMPC_Arg
    TYPE(MPCConstraintDef) :: def
  END TYPE MD_Constr_GetMPC_Arg
  TYPE, PUBLIC :: MD_Constr_GetCpl_Arg
    TYPE(CplConstraintDef) :: def
  END TYPE MD_Constr_GetCpl_Arg
  TYPE, PUBLIC :: MD_Constr_GetRigid_Arg
    TYPE(RigidBodyDef) :: def
  END TYPE MD_Constr_GetRigid_Arg

  !--------------------------------------------------------------------
  ! Arg type for GetSummary
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""   ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Constr_GetSummary_Arg

CONTAINS

  !====================================================================
  ! [P0] Init — Initialize constraint domain container.
  !====================================================================
  SUBROUTINE Init(this, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    
    this%algo = MD_Constr_Algo()
    this%constraint_union%n_tie   = 0_i4
    this%constraint_union%n_mpc   = 0_i4
    this%constraint_union%n_cpl   = 0_i4
    this%constraint_union%n_rigid = 0_i4
    this%constraint_union%n_total = 0_i4
    this%constraint_union%validated = .FALSE.
    this%initialized = .TRUE.
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  !====================================================================
  ! [P0] Finalize — Release all constraint resources.
  !====================================================================
  SUBROUTINE Finalize(this)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN
    
    ! Deallocate all constraint arrays
    IF (ALLOCATED(this%constraint_union%tie)) &
      DEALLOCATE(this%constraint_union%tie)
    IF (ALLOCATED(this%constraint_union%mpc)) &
      DEALLOCATE(this%constraint_union%mpc)
    IF (ALLOCATED(this%constraint_union%cpl)) &
      DEALLOCATE(this%constraint_union%cpl)
    IF (ALLOCATED(this%constraint_union%rigid)) &
      DEALLOCATE(this%constraint_union%rigid)
    
    ! Reset counts
    this%constraint_union%n_tie   = 0_i4
    this%constraint_union%n_mpc   = 0_i4
    this%constraint_union%n_cpl   = 0_i4
    this%constraint_union%n_rigid = 0_i4
    this%constraint_union%n_total = 0_i4
    this%constraint_union%validated = .FALSE.
    
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  !====================================================================
  ! [P0] AddTie — Register a tie constraint.
  !====================================================================
  SUBROUTINE AddTie(this, tie_def, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(TieConstraintDef),      INTENT(IN)    :: tie_def
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    TYPE(TieConstraintDef), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF
    
    ! Validate before adding
    IF (.NOT. tie_def%Valid()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Tie constraint validation failed"
      RETURN
    END IF
    
    this%constraint_union%n_tie = this%constraint_union%n_tie + 1_i4
    
    IF (.NOT. ALLOCATED(this%constraint_union%tie)) THEN
      ALLOCATE(this%constraint_union%tie(16))
    ELSE IF (this%constraint_union%n_tie > SIZE(this%constraint_union%tie)) THEN
      ALLOCATE(tmp(this%constraint_union%n_tie * 2))
      tmp(1:this%constraint_union%n_tie-1) = this%constraint_union%tie(1:this%constraint_union%n_tie-1)
      CALL MOVE_ALLOC(tmp, this%constraint_union%tie)
    END IF
    
    this%constraint_union%tie(this%constraint_union%n_tie) = tie_def
    this%constraint_union%n_total = this%constraint_union%n_total + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddTie

  !====================================================================
  ! [P0] AddMPC — Register a multi-point constraint.
  !====================================================================
  SUBROUTINE AddMPC(this, mpc_def, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(MPCConstraintDef),      INTENT(IN)    :: mpc_def
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    TYPE(MPCConstraintDef), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF
    
    ! Validate before adding
    IF (.NOT. mpc_def%Valid()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MPC constraint validation failed"
      RETURN
    END IF
    
    this%constraint_union%n_mpc = this%constraint_union%n_mpc + 1_i4
    
    IF (.NOT. ALLOCATED(this%constraint_union%mpc)) THEN
      ALLOCATE(this%constraint_union%mpc(16))
    ELSE IF (this%constraint_union%n_mpc > SIZE(this%constraint_union%mpc)) THEN
      ALLOCATE(tmp(this%constraint_union%n_mpc * 2))
      tmp(1:this%constraint_union%n_mpc-1) = this%constraint_union%mpc(1:this%constraint_union%n_mpc-1)
      CALL MOVE_ALLOC(tmp, this%constraint_union%mpc)
    END IF
    
    this%constraint_union%mpc(this%constraint_union%n_mpc) = mpc_def
    this%constraint_union%n_total = this%constraint_union%n_total + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddMPC

  !====================================================================
  ! [P0] AddCpl — Register a coupling constraint.
  !====================================================================
  SUBROUTINE AddCpl(this, cpl_def, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(CplConstraintDef),      INTENT(IN)    :: cpl_def
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    TYPE(CplConstraintDef), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF
    
    ! Validate before adding
    IF (.NOT. cpl_def%Valid()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Coupling constraint validation failed"
      RETURN
    END IF
    
    this%constraint_union%n_cpl = this%constraint_union%n_cpl + 1_i4
    
    IF (.NOT. ALLOCATED(this%constraint_union%cpl)) THEN
      ALLOCATE(this%constraint_union%cpl(16))
    ELSE IF (this%constraint_union%n_cpl > SIZE(this%constraint_union%cpl)) THEN
      ALLOCATE(tmp(this%constraint_union%n_cpl * 2))
      tmp(1:this%constraint_union%n_cpl-1) = this%constraint_union%cpl(1:this%constraint_union%n_cpl-1)
      CALL MOVE_ALLOC(tmp, this%constraint_union%cpl)
    END IF
    
    this%constraint_union%cpl(this%constraint_union%n_cpl) = cpl_def
    this%constraint_union%n_total = this%constraint_union%n_total + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddCpl

  !====================================================================
  ! [P0] AddRigid — Register a rigid body constraint.
  !====================================================================
  SUBROUTINE AddRigid(this, rigid_def, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(RigidBodyDef),          INTENT(IN)    :: rigid_def
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    TYPE(RigidBodyDef), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF
    
    ! Validate before adding
    IF (.NOT. rigid_def%Valid()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Rigid body constraint validation failed"
      RETURN
    END IF
    
    this%constraint_union%n_rigid = this%constraint_union%n_rigid + 1_i4
    
    IF (.NOT. ALLOCATED(this%constraint_union%rigid)) THEN
      ALLOCATE(this%constraint_union%rigid(16))
    ELSE IF (this%constraint_union%n_rigid > SIZE(this%constraint_union%rigid)) THEN
      ALLOCATE(tmp(this%constraint_union%n_rigid * 2))
      tmp(1:this%constraint_union%n_rigid-1) = this%constraint_union%rigid(1:this%constraint_union%n_rigid-1)
      CALL MOVE_ALLOC(tmp, this%constraint_union%rigid)
    END IF
    
    this%constraint_union%rigid(this%constraint_union%n_rigid) = rigid_def
    this%constraint_union%n_total = this%constraint_union%n_total + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddRigid

  !====================================================================
  ! [P0] GetTie — Query tie constraint by index.
  !====================================================================
  SUBROUTINE GetTie(this, idx, tie_def, status)
    CLASS(MD_Constraint_Domain), INTENT(IN)  :: this
    INTEGER(i4),                 INTENT(IN)  :: idx
    TYPE(TieConstraintDef),      INTENT(OUT) :: tie_def
    TYPE(ErrorStatusType),       INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF
    
    IF (idx < 1_i4 .OR. idx > this%constraint_union%n_tie) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0,A,I0)') "Tie constraint index ", idx, &
            " out of range [1, ", this%constraint_union%n_tie, "]"
      RETURN
    END IF
    
    tie_def = this%constraint_union%tie(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetTie

  !====================================================================
  ! [P0] GetMPC — Query MPC constraint by index.
  !====================================================================
  SUBROUTINE GetMPC(this, idx, mpc_def, status)
    CLASS(MD_Constraint_Domain), INTENT(IN)  :: this
    INTEGER(i4),                 INTENT(IN)  :: idx
    TYPE(MPCConstraintDef),      INTENT(OUT) :: mpc_def
    TYPE(ErrorStatusType),       INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF
    
    IF (idx < 1_i4 .OR. idx > this%constraint_union%n_mpc) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0,A,I0)') "MPC constraint index ", idx, &
            " out of range [1, ", this%constraint_union%n_mpc, "]"
      RETURN
    END IF
    
    mpc_def = this%constraint_union%mpc(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetMPC

  !====================================================================
  ! [P0] GetCpl — Query coupling constraint by index.
  !====================================================================
  SUBROUTINE GetCpl(this, idx, cpl_def, status)
    CLASS(MD_Constraint_Domain), INTENT(IN)  :: this
    INTEGER(i4),                 INTENT(IN)  :: idx
    TYPE(CplConstraintDef),      INTENT(OUT) :: cpl_def
    TYPE(ErrorStatusType),       INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF
    
    IF (idx < 1_i4 .OR. idx > this%constraint_union%n_cpl) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0,A,I0)') "Coupling constraint index ", idx, &
            " out of range [1, ", this%constraint_union%n_cpl, "]"
      RETURN
    END IF
    
    cpl_def = this%constraint_union%cpl(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetCpl

  !====================================================================
  ! [P0] GetRigid — Query rigid body constraint by index.
  !====================================================================
  SUBROUTINE GetRigid(this, idx, rigid_def, status)
    CLASS(MD_Constraint_Domain), INTENT(IN)  :: this
    INTEGER(i4),                 INTENT(IN)  :: idx
    TYPE(RigidBodyDef),          INTENT(OUT) :: rigid_def
    TYPE(ErrorStatusType),       INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF
    
    IF (idx < 1_i4 .OR. idx > this%constraint_union%n_rigid) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0,A,I0)') "Rigid constraint index ", idx, &
            " out of range [1, ", this%constraint_union%n_rigid, "]"
      RETURN
    END IF
    
    rigid_def = this%constraint_union%rigid(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetRigid

  ! Index-based global lookup is intentionally not hosted here (breaks UFC_GlobalContainer cycle).

  !====================================================================
  ! [P0] ValidateAll — Validate all constraints in the domain.
  !====================================================================
  SUBROUTINE ValidateAll(this, valid, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    LOGICAL,                     INTENT(OUT) :: valid
    TYPE(ErrorStatusType),       INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    valid = .TRUE.
    
    IF (.NOT. this%initialized) THEN
      valid = .FALSE.
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF
    
    ! Validate all Tie constraints
    DO i = 1, this%constraint_union%n_tie
      IF (.NOT. this%constraint_union%tie(i)%Valid()) THEN
        valid = .FALSE.
        EXIT
      END IF
    END DO
    
    ! Validate all MPC constraints
    DO i = 1, this%constraint_union%n_mpc
      IF (.NOT. this%constraint_union%mpc(i)%Valid()) THEN
        valid = .FALSE.
        EXIT
      END IF
    END DO
    
    ! Validate all Coupling constraints
    DO i = 1, this%constraint_union%n_cpl
      IF (.NOT. this%constraint_union%cpl(i)%Valid()) THEN
        valid = .FALSE.
        EXIT
      END IF
    END DO
    
    ! Validate all Rigid constraints
    DO i = 1, this%constraint_union%n_rigid
      IF (.NOT. this%constraint_union%rigid(i)%Valid()) THEN
        valid = .FALSE.
        EXIT
      END IF
    END DO
    
    this%constraint_union%validated = valid
    
    IF (valid) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "One or more constraints failed validation"
    END IF
  END SUBROUTINE ValidateAll

  !====================================================================
  ! [P1] SyncFromUnion — Sync from another constraint_union.
  !====================================================================
  SUBROUTINE SyncFromUnion(this, src_union, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(MD_ConstraintUnion),    INTENT(IN)    :: src_union
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4) :: i, n_tie, n_mpc, n_cpl, n_rigid

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Constraint domain not initialized"
      RETURN
    END IF

    ! Clear existing (avoid duplicates when Sync called after delegation)
    IF (ALLOCATED(this%constraint_union%tie)) DEALLOCATE(this%constraint_union%tie)
    IF (ALLOCATED(this%constraint_union%mpc)) DEALLOCATE(this%constraint_union%mpc)
    IF (ALLOCATED(this%constraint_union%cpl)) DEALLOCATE(this%constraint_union%cpl)
    IF (ALLOCATED(this%constraint_union%rigid)) DEALLOCATE(this%constraint_union%rigid)
    this%constraint_union%n_tie   = 0_i4
    this%constraint_union%n_mpc   = 0_i4
    this%constraint_union%n_cpl   = 0_i4
    this%constraint_union%n_rigid = 0_i4
    this%constraint_union%n_total = 0_i4

    n_tie   = src_union%n_tie
    n_mpc   = src_union%n_mpc
    n_cpl   = src_union%n_cpl
    n_rigid = src_union%n_rigid

    IF (n_tie + n_mpc + n_cpl + n_rigid == 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Copy Tie constraints
    IF (n_tie > 0 .AND. ALLOCATED(src_union%tie)) THEN
      DO i = 1, n_tie
        IF (i <= SIZE(src_union%tie)) THEN
          CALL AddTieRaw(this, src_union%tie(i), status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
      END DO
    END IF

    ! Copy MPC constraints
    IF (n_mpc > 0 .AND. ALLOCATED(src_union%mpc)) THEN
      DO i = 1, n_mpc
        IF (i <= SIZE(src_union%mpc)) THEN
          CALL AddMPCRaw(this, src_union%mpc(i), status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
      END DO
    END IF

    ! Copy Coupling constraints
    IF (n_cpl > 0 .AND. ALLOCATED(src_union%cpl)) THEN
      DO i = 1, n_cpl
        IF (i <= SIZE(src_union%cpl)) THEN
          CALL AddCplRaw(this, src_union%cpl(i), status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
      END DO
    END IF

    ! Copy Rigid constraints
    IF (n_rigid > 0 .AND. ALLOCATED(src_union%rigid)) THEN
      DO i = 1, n_rigid
        IF (i <= SIZE(src_union%rigid)) THEN
          CALL AddRigidRaw(this, src_union%rigid(i), status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
      END DO
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE SyncFromUnion

  !--------------------------------------------------------------------
  ! Raw Add routines (no validation) -- for SyncFromUnion only
  !--------------------------------------------------------------------
  SUBROUTINE AddTieRaw(this, tie_def, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(TieConstraintDef),      INTENT(IN)    :: tie_def
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    TYPE(TieConstraintDef), ALLOCATABLE :: tmp(:)
    CALL init_error_status(status)
    this%constraint_union%n_tie = this%constraint_union%n_tie + 1_i4
    IF (.NOT. ALLOCATED(this%constraint_union%tie)) THEN
      ALLOCATE(this%constraint_union%tie(16))
    ELSE IF (this%constraint_union%n_tie > SIZE(this%constraint_union%tie)) THEN
      ALLOCATE(tmp(this%constraint_union%n_tie * 2))
      tmp(1:this%constraint_union%n_tie-1) = this%constraint_union%tie(1:this%constraint_union%n_tie-1)
      CALL MOVE_ALLOC(tmp, this%constraint_union%tie)
    END IF
    this%constraint_union%tie(this%constraint_union%n_tie) = tie_def
    this%constraint_union%n_total = this%constraint_union%n_total + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddTieRaw

  SUBROUTINE AddMPCRaw(this, mpc_def, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(MPCConstraintDef),      INTENT(IN)    :: mpc_def
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    TYPE(MPCConstraintDef), ALLOCATABLE :: tmp(:)
    CALL init_error_status(status)
    this%constraint_union%n_mpc = this%constraint_union%n_mpc + 1_i4
    IF (.NOT. ALLOCATED(this%constraint_union%mpc)) THEN
      ALLOCATE(this%constraint_union%mpc(16))
    ELSE IF (this%constraint_union%n_mpc > SIZE(this%constraint_union%mpc)) THEN
      ALLOCATE(tmp(this%constraint_union%n_mpc * 2))
      tmp(1:this%constraint_union%n_mpc-1) = this%constraint_union%mpc(1:this%constraint_union%n_mpc-1)
      CALL MOVE_ALLOC(tmp, this%constraint_union%mpc)
    END IF
    this%constraint_union%mpc(this%constraint_union%n_mpc) = mpc_def
    this%constraint_union%n_total = this%constraint_union%n_total + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddMPCRaw

  SUBROUTINE AddCplRaw(this, cpl_def, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(CplConstraintDef),      INTENT(IN)    :: cpl_def
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    TYPE(CplConstraintDef), ALLOCATABLE :: tmp(:)
    CALL init_error_status(status)
    this%constraint_union%n_cpl = this%constraint_union%n_cpl + 1_i4
    IF (.NOT. ALLOCATED(this%constraint_union%cpl)) THEN
      ALLOCATE(this%constraint_union%cpl(16))
    ELSE IF (this%constraint_union%n_cpl > SIZE(this%constraint_union%cpl)) THEN
      ALLOCATE(tmp(this%constraint_union%n_cpl * 2))
      tmp(1:this%constraint_union%n_cpl-1) = this%constraint_union%cpl(1:this%constraint_union%n_cpl-1)
      CALL MOVE_ALLOC(tmp, this%constraint_union%cpl)
    END IF
    this%constraint_union%cpl(this%constraint_union%n_cpl) = cpl_def
    this%constraint_union%n_total = this%constraint_union%n_total + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddCplRaw

  SUBROUTINE AddRigidRaw(this, rigid_def, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    TYPE(RigidBodyDef),          INTENT(IN)    :: rigid_def
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    TYPE(RigidBodyDef), ALLOCATABLE :: tmp(:)
    CALL init_error_status(status)
    this%constraint_union%n_rigid = this%constraint_union%n_rigid + 1_i4
    IF (.NOT. ALLOCATED(this%constraint_union%rigid)) THEN
      ALLOCATE(this%constraint_union%rigid(16))
    ELSE IF (this%constraint_union%n_rigid > SIZE(this%constraint_union%rigid)) THEN
      ALLOCATE(tmp(this%constraint_union%n_rigid * 2))
      tmp(1:this%constraint_union%n_rigid-1) = this%constraint_union%rigid(1:this%constraint_union%n_rigid-1)
      CALL MOVE_ALLOC(tmp, this%constraint_union%rigid)
    END IF
    this%constraint_union%rigid(this%constraint_union%n_rigid) = rigid_def
    this%constraint_union%n_total = this%constraint_union%n_total + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddRigidRaw

  !====================================================================
  ! [P3] GetSummary
  !====================================================================
  SUBROUTINE GetSummary(this, arg)
    CLASS(MD_Constraint_Domain),         INTENT(IN)    :: this
    TYPE(MD_Constr_GetSummary_Arg),      INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%summary = "Constraint Domain: not initialized"
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    WRITE(arg%summary, '(A,I0,A,I0,A,I0,A,I0,A,I0,A,L1)') &
      "Constraint Summary: Total=", this%constraint_union%n_total, &
      " (Tie=", this%constraint_union%n_tie, &
      ", MPC=", this%constraint_union%n_mpc, &
      ", Coupling=", this%constraint_union%n_cpl, &
      ", Rigid=", this%constraint_union%n_rigid, &
      "), Validated=", this%constraint_union%validated
    arg%status%status_code = IF_STATUS_OK

  END SUBROUTINE GetSummary

END MODULE MD_Constr_Mgr