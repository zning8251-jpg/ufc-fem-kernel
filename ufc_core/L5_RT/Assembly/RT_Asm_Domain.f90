!===============================================================================
! MODULE: RT_Asm_Domain
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Domain
! BRIEF:  Assembly domain management -- CSR pattern, DOF map, renumbering
!===============================================================================
!
! Theory chain:
!   Assembly: K_global = A_e (Ke), F_global = A_e (Fe)  (scatter)
!   DOF map: local(e,i) -> global(eq_num(e,i))
!   Renumbering: RCM/AMD bandwidth minimization for sparse factorization
!
! Data chain:
!   Container path: g_ufc_global%rt_layer%assembly
!   Lifecycle: Increment-level (hot path, zero-alloc after first increment)
! Recommended pipeline (after L3 registration): mesh/model ready -> FromL3Model -> SyncL3BoundsFromBridge ->
!   then BuildPattern here / global assembly via RT_Asm_Solv (caller-owned ordering).
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!
! Theory chain:
!   Assembly: K_global = A_e (Ke), F_global = A_e (Fe)  (scatter)
!   DOF map: local(e,i) ?global(eq_num(e,i))
!   Renumbering: RCM/AMD bandwidth minimization for sparse factorization
!   Condensation: K_cc = K_cc - K_ci·K_ii^{-1}·K_ic  (static condensation)
!
! Data chain:
!   Container path: g_ufc_global%rt_layer%assembly
! Ctx: step_idx/incr_idx (three-step indexing L3→L5 )
!   State:  Global K (CSR values), F, DOF map, assembly status
!   Ctrl:   Renumbering method, parallel assembly mode
!   Lifecycle: Increment-level (hot path, zero-alloc after first increment)
!
! Contents:
!   Types: RT_Assembly_State / RT_Assembly_Ctrl / RT_Assembly_Domain
!   Subroutines: RT_Assembly_Domain_Init / RT_Assembly_Domain_Finalize
!
! Design outline: §12.2 ?2.6a L5_RT Assembly ?§1.5 / § ?
! USE contract ( ?7.3): ?L1/L2/L3/L4 ?L6 ?
! WriteBack contract ( ?7.2): L3 Step/Output/Contact ?MD_WB_* ?
! Status: Phase B (Arg-wrapped)
! Last verified: 2026-03-11
! Theory: N/A
!======================================================================
MODULE RT_Asm_Domain
  USE IF_Prec_Core,    ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Asm_Def, ONLY: RT_Asm_Desc
  USE RT_Brg_Mgr, ONLY: RT_Bridge_Domain
  IMPLICIT NONE
  PRIVATE

  ! --- Renumbering method enums ---
  INTEGER(i4), PARAMETER, PUBLIC :: RT_RENUM_NONE  = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_RENUM_RCM   = 1_i4  ! Reverse Cuthill-McKee
  INTEGER(i4), PARAMETER, PUBLIC :: RT_RENUM_AMD   = 2_i4  ! Approximate Min Degree
  INTEGER(i4), PARAMETER, PUBLIC :: RT_RENUM_METIS = 3_i4  ! METIS nested dissection

  ! --- Assembly mode enums ---
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_SERIAL    = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_OMP       = 1_i4  ! OpenMP coloring
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ATOMIC    = 2_i4  ! OpenMP atomic
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_MPI       = 3_i4  ! Distributed MPI

  TYPE, PUBLIC :: RT_Assembly_Ctx
    INTEGER(i4) :: step_idx = 0_i4   ! [ ] Step L3→L5
    INTEGER(i4) :: incr_idx = 0_i4   ! [ ]
  END TYPE RT_Assembly_Ctx

  TYPE, PUBLIC :: RT_Assembly_State
    INTEGER(i4)               :: nEq         = 0_i4   ! total equations
    INTEGER(i4)               :: nnz         = 0_i4   ! non-zeros in K
    INTEGER(i8)               :: nnz_long    = 0_i8   ! for large models
    INTEGER(i4), ALLOCATABLE  :: rowPtr(:)             ! CSR row pointer (nEq+1)
    INTEGER(i4), ALLOCATABLE  :: colIdx(:)             ! CSR column index (nnz)
    REAL(wp),    ALLOCATABLE  :: values(:)             ! CSR values (nnz)
    REAL(wp),    ALLOCATABLE  :: F_global(:)           ! (nEq) global force
    REAL(wp),    ALLOCATABLE  :: F_internal(:)         ! (nEq) internal force
    INTEGER(i4), ALLOCATABLE  :: eqNum(:)              ! DOF  ?equation map
    INTEGER(i4), ALLOCATABLE  :: permutation(:)        ! renumbering perm
    LOGICAL                   :: patternBuilt = .FALSE.
    LOGICAL                   :: assembled    = .FALSE.
  END TYPE RT_Assembly_State

  TYPE, PUBLIC :: RT_Assembly_Ctrl
    INTEGER(i4) :: renumMethod   = RT_RENUM_RCM
    INTEGER(i4) :: assemblyMode  = RT_ASM_OMP
    INTEGER(i4) :: nColorGroups  = 0_i4     ! for coloring-based assembly
    LOGICAL     :: symmetric     = .TRUE.    ! exploit symmetry
    LOGICAL     :: reusePatt     = .TRUE.    ! reuse sparsity pattern
  END TYPE RT_Assembly_Ctrl

  ! ------------------------------------------------------------------
  ! Arg types
  ! ------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Asm_BuildPattern_Arg
    INTEGER(i4) :: nEq = 0_i4   ! number of equations (IN)
    INTEGER(i4) :: nnz = 0_i4   ! non-zeros          (IN)
    TYPE(ErrorStatusType) :: status  !                (OUT)
  END TYPE RT_Asm_BuildPattern_Arg

  TYPE, PUBLIC :: RT_Asm_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status        ! (OUT)
  END TYPE RT_Asm_GetSummary_Arg

  TYPE, PUBLIC :: RT_Assembly_Domain
    TYPE(RT_Assembly_Ctx)   :: ctx
    TYPE(RT_Assembly_State) :: state
    TYPE(RT_Assembly_Ctrl)  :: ctrl
    ! Copy of L3/bridge mesh-scale bounds (from bridge%assembly_desc after MD_Model_Brg / FromL3Model).
    TYPE(RT_Asm_Desc)       :: l3_bounds
    LOGICAL                 :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SyncStepIncr
    PROCEDURE :: Finalize
    PROCEDURE :: SyncL3BoundsFromBridge
    PROCEDURE :: BuildPattern
    PROCEDURE :: GetSummary
  END TYPE RT_Assembly_Domain

CONTAINS

  SUBROUTINE Finalize(this)
    CLASS(RT_Assembly_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    CALL this%l3_bounds%Finalize()
    this%ctx = RT_Assembly_Ctx()
    IF (ALLOCATED(this%state%rowPtr))      DEALLOCATE(this%state%rowPtr)
    IF (ALLOCATED(this%state%colIdx))      DEALLOCATE(this%state%colIdx)
    IF (ALLOCATED(this%state%values))      DEALLOCATE(this%state%values)
    IF (ALLOCATED(this%state%F_global))    DEALLOCATE(this%state%F_global)
    IF (ALLOCATED(this%state%F_internal))  DEALLOCATE(this%state%F_internal)
    IF (ALLOCATED(this%state%eqNum))       DEALLOCATE(this%state%eqNum)
    IF (ALLOCATED(this%state%permutation)) DEALLOCATE(this%state%permutation)
    this%state%patternBuilt = .FALSE.
    this%state%assembled    = .FALSE.
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  SUBROUTINE SyncStepIncr(this, step_idx, incr_idx)
    CLASS(RT_Assembly_Domain), INTENT(INOUT) :: this
    INTEGER(i4),               INTENT(IN)    :: step_idx
    INTEGER(i4),               INTENT(IN)    :: incr_idx
    IF (.NOT. this%initialized) RETURN
    this%ctx%step_idx = step_idx
    this%ctx%incr_idx = incr_idx
  END SUBROUTINE SyncStepIncr

  SUBROUTINE Init(this, status, step_idx, incr_idx)
    CLASS(RT_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status
    INTEGER(i4),               INTENT(IN), OPTIONAL :: step_idx
    INTEGER(i4),               INTENT(IN), OPTIONAL :: incr_idx
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctx%step_idx = MERGE(step_idx, 0_i4, PRESENT(step_idx))
    this%ctx%incr_idx = MERGE(incr_idx, 0_i4, PRESENT(incr_idx))
    this%state%nEq  = 0_i4
    this%state%nnz  = 0_i4
    this%ctrl       = RT_Assembly_Ctrl()
    CALL this%l3_bounds%Init()
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  !---------------------------------------------------------------------------
  ! SyncL3BoundsFromBridge — copy bridge%assembly_desc scalars into l3_bounds
  ! Call after RT_Asm_Brg_FromL3Model / UF_register_model_in_dataplatform.
  ! Constraint pointer arrays: not deep-copied (bridge path from mesh counts only).
  !---------------------------------------------------------------------------
  SUBROUTINE SyncL3BoundsFromBridge(this, rt_xfer, status)
    CLASS(RT_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(RT_Bridge_Domain),    INTENT(IN)    :: rt_xfer
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Assembly domain not initialized"
      RETURN
    END IF
    IF (.NOT. rt_xfer%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Bridge domain not initialized"
      RETURN
    END IF

    CALL this%l3_bounds%Finalize()
    CALL this%l3_bounds%Init()
    this%l3_bounds%assemble_mass          = rt_xfer%assembly_desc%assemble_mass
    this%l3_bounds%assemble_damping       = rt_xfer%assembly_desc%assemble_damping
    this%l3_bounds%assemble_stiffness     = rt_xfer%assembly_desc%assemble_stiffness
    this%l3_bounds%assemble_loads         = rt_xfer%assembly_desc%assemble_loads
    this%l3_bounds%elem_start             = rt_xfer%assembly_desc%elem_start
    this%l3_bounds%elem_end               = rt_xfer%assembly_desc%elem_end
    this%l3_bounds%node_start             = rt_xfer%assembly_desc%node_start
    this%l3_bounds%node_end               = rt_xfer%assembly_desc%node_end
    this%l3_bounds%is_symmetric           = rt_xfer%assembly_desc%is_symmetric
    this%l3_bounds%is_positive_definite   = rt_xfer%assembly_desc%is_positive_definite
    status%status_code = IF_STATUS_OK
  END SUBROUTINE SyncL3BoundsFromBridge

  !====================================================================
  ! RT_Assembly_Domain_BuildPattern  (Arg-wrapped)
  !====================================================================
  SUBROUTINE BuildPattern(this, arg)
    CLASS(RT_Assembly_Domain),        INTENT(INOUT) :: this
    TYPE(RT_Asm_BuildPattern_Arg), INTENT(INOUT) :: arg
    CALL RT_Assembly_BuildPattern_Impl(this, arg%nEq, arg%nnz, arg%status)
  END SUBROUTINE BuildPattern

  !--------------------------------------------------------------------
  SUBROUTINE RT_Assembly_BuildPattern_Impl(this, nEq, nnz, status)
    CLASS(RT_Assembly_Domain), INTENT(INOUT) :: this
    INTEGER(i4),               INTENT(IN)    :: nEq, nnz
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Assembly domain not initialized"
      RETURN
    END IF

    IF (nEq < 1 .OR. nnz < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid nEq or nnz (must be > 0)"
      RETURN
    END IF

    ALLOCATE(this%state%rowPtr(nEq + 1))
    ALLOCATE(this%state%colIdx(nnz))
    ALLOCATE(this%state%values(nnz))
    ALLOCATE(this%state%F_global(nEq))
    ALLOCATE(this%state%F_internal(nEq))
    ALLOCATE(this%state%eqNum(nEq))
    ALLOCATE(this%state%permutation(nEq))

    this%state%rowPtr       = 0_i4
    this%state%colIdx       = 0_i4
    this%state%values       = 0.0_wp
    this%state%F_global     = 0.0_wp
    this%state%F_internal   = 0.0_wp
    this%state%eqNum        = 0_i4
    this%state%permutation  = 0_i4
    this%state%nEq          = nEq
    this%state%nnz          = nnz
    this%state%patternBuilt = .TRUE.

    status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_Assembly_BuildPattern_Impl

  !====================================================================
  ! RT_Assembly_Domain_GetSummary  (Arg-wrapped)
  !====================================================================
  SUBROUTINE GetSummary(this, arg)
    CLASS(RT_Assembly_Domain),      INTENT(IN)    :: this
    TYPE(RT_Asm_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL RT_Assembly_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE GetSummary

  !--------------------------------------------------------------------
  SUBROUTINE RT_Assembly_GetSummary_Impl(this, summary, status)
    CLASS(RT_Assembly_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),        INTENT(OUT) :: summary
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Assembly domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0,A,L1,A,L1,A,I0,A,I0,A,I0,A,I0)') &
      "Assembly Summary: nEq=", this%state%nEq, &
      ", nnz=", this%state%nnz, &
      ", Renumb=", this%ctrl%renumMethod, &
      ", Mode=", this%ctrl%assemblyMode, &
      ", Symmetric=", this%ctrl%symmetric, &
      ", PatternBuilt=", this%state%patternBuilt, &
      ", L3 elem [", this%l3_bounds%elem_start, ":", this%l3_bounds%elem_end, &
      "], node [", this%l3_bounds%node_start, ":", this%l3_bounds%node_end, "]"

    status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_Assembly_GetSummary_Impl

END MODULE RT_Asm_Domain