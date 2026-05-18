!===============================================================================
! MODULE: PH_Cont_Domain
! LAYER:  L4_PH
! DOMAIN: Contact
! ROLE:   Domain
! BRIEF:  Contact domain aggregate (detection, force, search, friction, mortar)
!
! Four-Type: PH_Contact_Ctx (Ctx), PH_Contact_State (State), PH_Contact_Params (Algo)
! Constants: PH_CONT_* (algorithm enums), PH_CSTAT_* (status), PH_FRIC_* (domain-level)
! Contract: L4_PH/Contact/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_PH_QUENCH | Domain:Contact | Role:Domain | FuncSet?Core | 热路�?�?!>>> Basis:PLAN/04_实施路线�任务规�?实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md �附�热路径�?L3?!>>> UFC_PH_CONTRACT | Contact/CONTRACT.md
MODULE PH_Cont_Domain
  USE IF_Base_Def,   ONLY: ZERO
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Brg_L3, ONLY: PH_Brg_GetNodeCoords_Idx
  ! Phase 3 Enhancement: Import new contact pair types
  USE PH_Cont_Def, ONLY: PH_Contact_Pair_Desc, PH_Contact_Surface_Desc
  IMPLICIT NONE
  PRIVATE

  ! --- Contact algorithm enums ---
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_NODE_TO_SURF  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_SURF_TO_SURF  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_MORTAR        = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_SELF_CONTACT  = 4_i4

  ! --- Contact status enums ---
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CSTAT_OPEN    = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CSTAT_STICK   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CSTAT_SLIP    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CSTAT_TIED    = 3_i4

  ! --- Friction model enums [AUTHORITY: domain-level family classification] ---
  ! NOTE: These are high-level friction family IDs for domain configuration.
  !   For algorithm-level friction model IDs, see PH_ContFriction.PH_FRICT_*.
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRIC_COULOMB      = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRIC_PENALTY      = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRIC_EXPONENTIAL  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRIC_USER         = 4_i4

  ! AP-8: Pre-allocated buffers for Detect (zero ALLOCATE in warm path)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_DEFAULT_MAX_SLAVE  = 1024_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_DEFAULT_MAX_MASTER = 1024_i4

  !---------------------------------------------------------------------------
  ! TYPE: PH_Cont_Inc_Evo_Ctx
  ! PHASE: Increment | VERB: Evolve
  ! KIND:  Ctx (auxiliary)
  ! DESC:  Increment-phase evolution context - step/increment tracking
  !        for Contact evolution. Mirrors PH_Mat_Inc_Evo_Ctx pattern.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Cont_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Cont_Inc_Evo_Ctx

  TYPE, PUBLIC :: PH_Contact_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Cont_Inc_Evo_Ctx) :: inc   ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4)              :: step_idx       = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4)              :: incr_idx       = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4)              :: nContactPairs  = 0_i4
    INTEGER(i4)              :: nActiveNodes   = 0_i4
    INTEGER(i4), ALLOCATABLE :: masterSurfIds(:)   ! (nPairs)
    INTEGER(i4), ALLOCATABLE :: slaveSurfIds(:)     ! (nPairs)
    INTEGER(i4), ALLOCATABLE :: slaveNodeIds(:)     ! (nActiveNodes)
    REAL(wp),    ALLOCATABLE :: gap(:)              ! (nActiveNodes) signed gap
    REAL(wp),    ALLOCATABLE :: normal(:,:)         ! (3, nActiveNodes)
    REAL(wp),    ALLOCATABLE :: projXi(:,:)         ! (2, nActiveNodes) parametric
    INTEGER(i4), ALLOCATABLE :: projElemId(:)       ! (nActiveNodes)
    ! AP-8: Pre-allocated in Init (cold path), used by Detect (warm path)
    REAL(wp),    ALLOCATABLE :: x_slave_buf(:,:)   ! (3, maxSlaveNodes)
    REAL(wp),    ALLOCATABLE :: x_master_buf(:,:)  ! (3, maxMasterNodes)
    INTEGER(i4)              :: maxSlaveNodes  = 0_i4
    INTEGER(i4)              :: maxMasterNodes = 0_i4
  END TYPE PH_Contact_Ctx

  TYPE, PUBLIC :: PH_Contact_State
    REAL(wp),    ALLOCATABLE :: pNormal(:)         ! (nActiveNodes) normal pressure
    REAL(wp),    ALLOCATABLE :: pTangent(:,:)      ! (2, nActiveNodes) tangential
    REAL(wp),    ALLOCATABLE :: slipDisp(:,:)      ! (2, nActiveNodes) accumulated slip
    REAL(wp),    ALLOCATABLE :: slipRate(:)         ! (nActiveNodes) slip rate magnitude
    REAL(wp),    ALLOCATABLE :: lambda_n(:)         ! (nActiveNodes) AL multiplier normal
    REAL(wp),    ALLOCATABLE :: lambda_t(:,:)       ! (2, nActiveNodes) AL multiplier tan
    INTEGER(i4), ALLOCATABLE :: contactStatus(:)    ! (nActiveNodes) open/stick/slip
    REAL(wp)                 :: totalContactForce = 0.0_wp
    INTEGER(i4)              :: nOpen   = 0_i4
    INTEGER(i4)              :: nStick  = 0_i4
    INTEGER(i4)              :: nSlip   = 0_i4
  END TYPE PH_Contact_State

  !> @brief Contact algorithm configuration (nested auxiliary)
  TYPE, PUBLIC :: PH_Contact_Cfg_Algorithm
    INTEGER(i4) :: algorithm      = PH_CONT_SURF_TO_SURF
    INTEGER(i4) :: frictionModel  = PH_FRIC_COULOMB
  END TYPE PH_Contact_Cfg_Algorithm

  !> @brief Contact physical parameters (nested auxiliary)
  TYPE, PUBLIC :: PH_Contact_Cfg_Physical
    REAL(wp)    :: frictionCoeff  = 0.0_wp         ! Coulomb mu (mapped from L3)
    REAL(wp)    :: penaltyNormal  = 1.0e+10_wp     ! k_N
    REAL(wp)    :: penaltyTangent = 1.0e+10_wp     ! k_T
  END TYPE PH_Contact_Cfg_Physical

  !> @brief Contact control parameters (nested auxiliary)
  TYPE, PUBLIC :: PH_Contact_Cfg_Control
    REAL(wp)    :: contactTol     = 1.0e-6_wp      ! gap tolerance
    REAL(wp)    :: searchTol      = 0.0_wp         ! search extension
    INTEGER(i4) :: maxAugIter     = 10_i4
    LOGICAL     :: adjustPenalty  = .FALSE.         ! auto penalty adjustment
    LOGICAL     :: finiteSlidng   = .TRUE.          ! finite vs small sliding
  END TYPE PH_Contact_Cfg_Control

  TYPE, PUBLIC :: PH_Contact_Params
    TYPE(PH_Contact_Cfg_Algorithm) :: algo
    TYPE(PH_Contact_Cfg_Physical)  :: phys
    TYPE(PH_Contact_Cfg_Control)   :: ctrl
    ! NOTE: Flat fields removed after P2 migration (zero external references verified)
  END TYPE PH_Contact_Params

  ! ------------------------------------------------------------------
  ! Arg types
  ! ------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Cont_RegisterPair_Arg
    INTEGER(i4) :: masterSurfId = 0_i4  ! master surface id (IN)
    INTEGER(i4) :: slaveSurfId  = 0_i4  ! slave  surface id (IN)
    INTEGER(i4) :: pairId       = 0_i4  ! assigned pair id  (OUT)
    TYPE(ErrorStatusType) :: status     !                   (OUT)
  END TYPE PH_Cont_RegisterPair_Arg

  TYPE, PUBLIC :: PH_Cont_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status        ! (OUT)
  END TYPE PH_Cont_GetSummary_Arg

  ! ------------------------------------------------------------------
  ! Algorithm Arg types (Phase B)
  ! ------------------------------------------------------------------

  !> Detect contact: gap, normal, projection
  !> Theory: gN = (x_slave - x_proj) n
  !> L3 geometry: when slaveNodeIds/masterNodeIds provided, fetch coords via Bridge
  TYPE, PUBLIC :: PH_Cont_Detect_Arg
    INTEGER(i4) :: pairIdx       = 0_i4     ! IN: contact pair index
    INTEGER(i4) :: nSlaveNodes   = 0_i4     ! IN: slave nodes count
    INTEGER(i4) :: nMasterNodes   = 0_i4     ! IN: master nodes count
    INTEGER(i4), ALLOCATABLE :: slaveNodeIds(:)   ! IN: L3 node indices (fetch coords)
    INTEGER(i4), ALLOCATABLE :: masterNodeIds(:)  ! IN: L3 node indices (fetch coords)
    REAL(wp), ALLOCATABLE :: x_slave(:,:)   ! IN: slave coords (3, nSlaveNodes), or OUT from L3
    REAL(wp), ALLOCATABLE :: x_master(:,:) ! IN: master coords (3, nMasterNodes), or OUT from L3
    INTEGER(i4), ALLOCATABLE :: masterConn(:,:)   ! IN: master connectivity (elem, node)
    REAL(wp), ALLOCATABLE :: gap(:)         ! OUT: signed gap (nSlaveNodes)
    REAL(wp), ALLOCATABLE :: normal(:,:)   ! OUT: normal (3, nSlaveNodes)
    INTEGER(i4), ALLOCATABLE :: projElemId(:)     ! OUT: projected elem id
    TYPE(ErrorStatusType) :: status        ! OUT
  END TYPE PH_Cont_Detect_Arg

  !> Compute contact force from gap/penalty
  !> Theory: pN = ?N <-gN>+ (penalty)
  TYPE, PUBLIC :: PH_Cont_ComputeForce_Arg
    INTEGER(i4) :: nActiveNodes = 0_i4    ! IN
    REAL(wp)    :: penaltyNormal = 0.0_wp ! IN: ?N
    REAL(wp), ALLOCATABLE :: gap(:)       ! IN: signed gap
    REAL(wp), ALLOCATABLE :: normal(:,:)   ! IN: normal (3, n)
    REAL(wp), ALLOCATABLE :: pNormal(:)   ! OUT: normal pressure
    REAL(wp), ALLOCATABLE :: pTangent(:,:)! OUT: tangential (2, n)
    INTEGER(i4), ALLOCATABLE :: contactStatus(:) ! OUT: open/stick/slip
    REAL(wp)    :: totalForce = 0.0_wp    ! OUT
    TYPE(ErrorStatusType) :: status      ! OUT
  END TYPE PH_Cont_ComputeForce_Arg

  !> Update contact state after convergence
  !> slipDisp, contactStatus, lambda_n/t
  TYPE, PUBLIC :: PH_Cont_UpdateState_Arg
    INTEGER(i4) :: nActiveNodes = 0_i4    ! IN
    REAL(wp), ALLOCATABLE :: pNormal(:)   ! IN: converged normal pressure
    REAL(wp), ALLOCATABLE :: pTangent(:,:)! IN: converged tangential
    INTEGER(i4), ALLOCATABLE :: contactStatus(:) ! IN
    REAL(wp), ALLOCATABLE :: slipDisp(:,:) ! INOUT: accumulated slip
    TYPE(ErrorStatusType) :: status      ! OUT
  END TYPE PH_Cont_UpdateState_Arg

  TYPE, PUBLIC :: PH_Contact_Domain
    TYPE(PH_Contact_Ctx)    :: ctx
    TYPE(PH_Contact_State)  :: state
    TYPE(PH_Contact_Params) :: params
    ! Phase 3 Enhancement: Contact pair collection (NEW)
    INTEGER(i4)             :: n_pairs = 0_i4
    TYPE(PH_Contact_Pair_Desc), ALLOCATABLE :: pairs(:)
    LOGICAL                 :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RegisterPair
    ! Phase 3 Enhancement: New interface for Pair Desc (NEW)
    PROCEDURE :: RegisterFromDesc
    PROCEDURE :: GetPair
    PROCEDURE :: GetPairCount
    PROCEDURE :: GetSummary
    PROCEDURE :: Detect
    PROCEDURE :: ComputeForce
    PROCEDURE :: UpdateState
  END TYPE PH_Contact_Domain

CONTAINS

  SUBROUTINE Finalize(this)
    CLASS(PH_Contact_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%ctx%masterSurfIds)) DEALLOCATE(this%ctx%masterSurfIds)
    IF (ALLOCATED(this%ctx%slaveSurfIds))  DEALLOCATE(this%ctx%slaveSurfIds)
    IF (ALLOCATED(this%ctx%slaveNodeIds))  DEALLOCATE(this%ctx%slaveNodeIds)
    IF (ALLOCATED(this%ctx%gap))           DEALLOCATE(this%ctx%gap)
    IF (ALLOCATED(this%ctx%normal))        DEALLOCATE(this%ctx%normal)
    IF (ALLOCATED(this%ctx%projXi))        DEALLOCATE(this%ctx%projXi)
    IF (ALLOCATED(this%ctx%projElemId))    DEALLOCATE(this%ctx%projElemId)
    IF (ALLOCATED(this%ctx%x_slave_buf))   DEALLOCATE(this%ctx%x_slave_buf)
    IF (ALLOCATED(this%ctx%x_master_buf))  DEALLOCATE(this%ctx%x_master_buf)
    IF (ALLOCATED(this%state%pNormal))     DEALLOCATE(this%state%pNormal)
    IF (ALLOCATED(this%state%pTangent))    DEALLOCATE(this%state%pTangent)
    IF (ALLOCATED(this%state%slipDisp))    DEALLOCATE(this%state%slipDisp)
    IF (ALLOCATED(this%state%slipRate))    DEALLOCATE(this%state%slipRate)
    IF (ALLOCATED(this%state%lambda_n))    DEALLOCATE(this%state%lambda_n)
    IF (ALLOCATED(this%state%lambda_t))    DEALLOCATE(this%state%lambda_t)
    IF (ALLOCATED(this%state%contactStatus)) DEALLOCATE(this%state%contactStatus)
    this%state%totalContactForce = 0.0_wp
    this%state%nOpen  = 0_i4
    this%state%nStick = 0_i4
    this%state%nSlip  = 0_i4
    this%initialized  = .FALSE.
  END SUBROUTINE Finalize

  SUBROUTINE Init(this, stepId, status, maxSlaveNodes, maxMasterNodes, incr_idx)
    CLASS(PH_Contact_Domain), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: stepId   ! step_idx (md_layer%step )
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status
    INTEGER(i4),              INTENT(IN), OPTIONAL :: maxSlaveNodes, maxMasterNodes, incr_idx
    INTEGER(i4) :: maxS, maxM
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctx%inc%step_idx = stepId
    this%ctx%inc%incr_idx = MERGE(incr_idx, 0_i4, PRESENT(incr_idx))
    this%ctx%inc%step_idx = stepId
    this%ctx%inc%incr_idx = MERGE(incr_idx, 0_i4, PRESENT(incr_idx))
    this%ctx%nContactPairs = 0_i4
    this%ctx%nActiveNodes  = 0_i4
    this%params            = PH_Contact_Params()
    ! AP-8: Pre-allocate Detect buffers (cold path), zero ALLOCATE in Detect warm path
    maxS = PH_CONT_DEFAULT_MAX_SLAVE
    maxM = PH_CONT_DEFAULT_MAX_MASTER
    IF (PRESENT(maxSlaveNodes))  maxS = MAX(1_i4, maxSlaveNodes)
    IF (PRESENT(maxMasterNodes)) maxM = MAX(1_i4, maxMasterNodes)
    this%ctx%maxSlaveNodes  = maxS
    this%ctx%maxMasterNodes = maxM
    ALLOCATE(this%ctx%x_slave_buf(3, maxS))
    ALLOCATE(this%ctx%x_master_buf(3, maxM))
    this%ctx%x_slave_buf  = ZERO
    this%ctx%x_master_buf = ZERO
    this%initialized       = .TRUE.
    status%status_code     = IF_STATUS_OK
  END SUBROUTINE Init

  !====================================================================
  ! PH_Contact_Domain_RegisterContactPair  (Arg-wrapped)
  !====================================================================
  SUBROUTINE RegisterPair(this, arg)
    CLASS(PH_Contact_Domain),        INTENT(INOUT) :: this
    TYPE(PH_Cont_RegisterPair_Arg), INTENT(INOUT) :: arg
    CALL PH_Contact_RegisterContactPair_Impl(this, arg%masterSurfId, &
                                             arg%slaveSurfId, arg%pairId, arg%status)
  END SUBROUTINE RegisterPair

  !--------------------------------------------------------------------
  SUBROUTINE PH_Contact_RegisterContactPair_Impl(this, masterSurfId, &
                                                  slaveSurfId, pairId, status)
    CLASS(PH_Contact_Domain), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: masterSurfId, slaveSurfId
    INTEGER(i4),              INTENT(OUT)   :: pairId
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4), ALLOCATABLE :: tmp_m(:), tmp_s(:)

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Contact domain not initialized"
      pairId = 0_i4
      RETURN
    END IF

    IF (masterSurfId < 1 .OR. slaveSurfId < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid surface IDs (must be > 0)"
      pairId = 0_i4
      RETURN
    END IF

    this%ctx%nContactPairs = this%ctx%nContactPairs + 1_i4
    pairId = this%ctx%nContactPairs

    ALLOCATE(tmp_m(pairId))
    ALLOCATE(tmp_s(pairId))
    IF (pairId > 1) THEN
      tmp_m(1:pairId-1) = this%ctx%masterSurfIds
      tmp_s(1:pairId-1) = this%ctx%slaveSurfIds
    END IF
    tmp_m(pairId) = masterSurfId
    tmp_s(pairId) = slaveSurfId

    CALL MOVE_ALLOC(tmp_m, this%ctx%masterSurfIds)
    CALL MOVE_ALLOC(tmp_s, this%ctx%slaveSurfIds)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Contact_RegisterContactPair_Impl

  !====================================================================
  ! PH_Contact_Domain_GetSummary  (Arg-wrapped)
  !====================================================================
  SUBROUTINE GetSummary(this, arg)
    CLASS(PH_Contact_Domain),      INTENT(IN)    :: this
    TYPE(PH_Cont_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL PH_Contact_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE GetSummary

  !--------------------------------------------------------------------
  SUBROUTINE PH_Contact_GetSummary_Impl(this, summary, status)
    CLASS(PH_Contact_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),       INTENT(OUT) :: summary
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Contact domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0,A,I0,A,ES10.3,A,ES10.3)') &
      "Contact Summary: Pairs=", this%ctx%nContactPairs, &
      ", Nodes=", this%ctx%nActiveNodes, &
      ", Open=", this%state%nOpen, &
      ", Stick=", this%state%nStick, &
      ", Slip=", this%state%nSlip, &
      ", Force=", this%state%totalContactForce, &
      ", Friction=", this%params%phys%frictionCoeff

    status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Contact_GetSummary_Impl

  !====================================================================
  ! Algorithm ?Detect
  ! Theory: gN = (x_slave - x_proj) n; node-to-surface projection
  ! L3 geometry: fetch coords via PH_Brg_GetNodeCoords_Idx when node IDs given
  ! Node-to-node: find closest master, gap = signed dist, n = (x_s-x_m)/|...|
  !====================================================================
  SUBROUTINE Detect(this, arg)
    CLASS(PH_Contact_Domain),              INTENT(INOUT) :: this
    TYPE(PH_Cont_Detect_Arg),   INTENT(INOUT) :: arg
    INTEGER(i4) :: i, j, n, nm, k
    REAL(wp) :: d(3), dist, dist2, minDist2
    TYPE(ErrorStatusType) :: st
    LOGICAL :: use_ctx_coords  ! true = use ctx buffers (we fetched), false = use arg (caller provided)

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Contact domain not initialized"
      RETURN
    END IF
    n = arg%nSlaveNodes
    nm = arg%nMasterNodes
    IF (n < 1) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (.NOT. ALLOCATED(arg%gap) .OR. SIZE(arg%gap) < n) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "gap not allocated"
      RETURN
    END IF

    ! AP-8: Use pre-allocated ctx buffers (Init cold path), zero ALLOCATE in Detect
    IF (ALLOCATED(arg%slaveNodeIds) .AND. SIZE(arg%slaveNodeIds) >= n) THEN
      IF (n > this%ctx%maxSlaveNodes .OR. .NOT. ALLOCATED(this%ctx%x_slave_buf)) THEN
        arg%status%status_code = IF_STATUS_INVALID
        arg%status%message = "Detect: nSlaveNodes exceeds ctx%maxSlaveNodes or buf not allocated"
        RETURN
      END IF
      DO i = 1, n
        CALL PH_Brg_GetNodeCoords_Idx(arg%slaveNodeIds(i), this%ctx%x_slave_buf(1:3, i), st)
        IF (st%status_code /= IF_STATUS_OK) THEN
          arg%status = st
          RETURN
        END IF
      END DO
    END IF
    IF (nm > 0 .AND. ALLOCATED(arg%masterNodeIds) .AND. SIZE(arg%masterNodeIds) >= nm) THEN
      IF (nm > this%ctx%maxMasterNodes .OR. .NOT. ALLOCATED(this%ctx%x_master_buf)) THEN
        arg%status%status_code = IF_STATUS_INVALID
        arg%status%message = "Detect: nMasterNodes exceeds ctx%maxMasterNodes or buf not allocated"
        RETURN
      END IF
      DO i = 1, nm
        CALL PH_Brg_GetNodeCoords_Idx(arg%masterNodeIds(i), this%ctx%x_master_buf(1:3, i), st)
        IF (st%status_code /= IF_STATUS_OK) THEN
          arg%status = st
          RETURN
        END IF
      END DO
    END IF

    ! Projection: use ctx buffers (we fetched) or arg (caller provided), zero ALLOCATE
    use_ctx_coords = (ALLOCATED(arg%slaveNodeIds) .AND. SIZE(arg%slaveNodeIds) >= n) .AND. &
         (nm == 0 .OR. (ALLOCATED(arg%masterNodeIds) .AND. SIZE(arg%masterNodeIds) >= nm))
    use_ctx_coords = use_ctx_coords .AND. ALLOCATED(this%ctx%x_slave_buf) .AND. &
         (nm == 0 .OR. ALLOCATED(this%ctx%x_master_buf))

    IF (nm > 0 .AND. use_ctx_coords .AND. this%ctx%maxSlaveNodes >= n .AND. this%ctx%maxMasterNodes >= nm) THEN
      DO i = 1, n
        minDist2 = HUGE(1.0_wp)
        k = 1
        DO j = 1, nm
          d = this%ctx%x_slave_buf(1:3, i) - this%ctx%x_master_buf(1:3, j)
          dist2 = SUM(d**2)
          IF (dist2 < minDist2) THEN
            minDist2 = dist2
            k = j
          END IF
        END DO
        dist = SQRT(minDist2)
        IF (dist > 1.0e-30_wp) THEN
          arg%gap(i) = dist
          IF (ALLOCATED(arg%normal) .AND. SIZE(arg%normal, 2) >= n) &
            arg%normal(1:3, i) = (this%ctx%x_slave_buf(1:3, i) - this%ctx%x_master_buf(1:3, k)) / dist
        ELSE
          arg%gap(i) = ZERO
          IF (ALLOCATED(arg%normal) .AND. SIZE(arg%normal, 2) >= n) &
            arg%normal(1:3, i) = ZERO
        END IF
        IF (ALLOCATED(arg%projElemId) .AND. SIZE(arg%projElemId) >= n) &
          arg%projElemId(i) = 0_i4
      END DO
    ELSE IF (nm > 0 .AND. ALLOCATED(arg%x_slave) .AND. ALLOCATED(arg%x_master) .AND. &
        SIZE(arg%x_slave, 2) >= n .AND. SIZE(arg%x_master, 2) >= nm) THEN
      ! Caller provided coords (no L3 fetch), use arg buffers
      DO i = 1, n
        minDist2 = HUGE(1.0_wp)
        k = 1
        DO j = 1, nm
          d = arg%x_slave(1:3, i) - arg%x_master(1:3, j)
          dist2 = SUM(d**2)
          IF (dist2 < minDist2) THEN
            minDist2 = dist2
            k = j
          END IF
        END DO
        dist = SQRT(minDist2)
        IF (dist > 1.0e-30_wp) THEN
          arg%gap(i) = dist
          IF (ALLOCATED(arg%normal) .AND. SIZE(arg%normal, 2) >= n) &
            arg%normal(1:3, i) = (arg%x_slave(1:3, i) - arg%x_master(1:3, k)) / dist
        ELSE
          arg%gap(i) = ZERO
          IF (ALLOCATED(arg%normal) .AND. SIZE(arg%normal, 2) >= n) &
            arg%normal(1:3, i) = ZERO
        END IF
        IF (ALLOCATED(arg%projElemId) .AND. SIZE(arg%projElemId) >= n) &
          arg%projElemId(i) = 0_i4
      END DO
    ELSE
      ! No geometry: placeholder zero gap
      arg%gap(1:n) = ZERO
      IF (ALLOCATED(arg%normal) .AND. SIZE(arg%normal, 2) >= n) &
        arg%normal(1:3, 1:n) = ZERO
      IF (ALLOCATED(arg%projElemId) .AND. SIZE(arg%projElemId) >= n) &
        arg%projElemId(1:n) = 0_i4
    END IF
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE Detect

  !====================================================================
  ! Algorithm ?ComputeForce
  ! Theory: pN = ?N <-gN>+ (penalty); gN<0 ?contact, pN>0
  !====================================================================
  SUBROUTINE ComputeForce(this, arg)
    ! > [Theory] p_N = ε_N · <-g> <x>=max(0,-x) ε_N g
    ! > [Logic] �?nActiveNodes �?�?(stick/open) �?    !> [Compute] g=arg%gap(i); pn=epsN*max(0,-g); arg%pNormal(i)=pn; contactStatus(i)=STICK(pn>0)/OPEN; totalForce+=pn
    !> [Data chain] arg%gap(nActiveNodes), arg%penaltyNormal, arg%normal(3,n) �?arg%pNormal(:), arg%contactStatus(:), arg%totalForce
    CLASS(PH_Contact_Domain),                 INTENT(INOUT) :: this
    TYPE(PH_Cont_ComputeForce_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i, n
    REAL(wp) :: epsN, g, pn

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Contact domain not initialized"
      RETURN
    END IF
    n = arg%nActiveNodes
    IF (n < 1) THEN
      arg%totalForce = ZERO
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    epsN = MERGE(arg%penaltyNormal, this%params%phys%penaltyNormal, arg%penaltyNormal > 0.0_wp)
    arg%totalForce = ZERO

    DO i = 1, n
      g = arg%gap(i)
      pn = epsN * MAX(-g, ZERO)
      IF (ALLOCATED(arg%pNormal) .AND. SIZE(arg%pNormal) >= i) arg%pNormal(i) = pn
      IF (ALLOCATED(arg%pTangent) .AND. SIZE(arg%pTangent, 2) >= i) &
        arg%pTangent(1:2, i) = ZERO
      IF (ALLOCATED(arg%contactStatus) .AND. SIZE(arg%contactStatus) >= i) &
        arg%contactStatus(i) = MERGE(PH_CSTAT_STICK, PH_CSTAT_OPEN, pn > ZERO)
      arg%totalForce = arg%totalForce + pn
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE ComputeForce

  !====================================================================
  ! Algorithm ?UpdateState
  ! Warm path: commit slipDisp, contactStatus after convergence
  !====================================================================
  SUBROUTINE UpdateState(this, arg)
    CLASS(PH_Contact_Domain),                  INTENT(INOUT) :: this
    TYPE(PH_Cont_UpdateState_Arg),  INTENT(INOUT) :: arg
    INTEGER(i4) :: i, n

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Contact domain not initialized"
      RETURN
    END IF
    n = arg%nActiveNodes
    IF (n < 1) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (ALLOCATED(arg%pNormal) .AND. ALLOCATED(this%state%pNormal) .AND. SIZE(arg%pNormal) >= n) &
      this%state%pNormal(1:n) = arg%pNormal(1:n)
    IF (ALLOCATED(arg%contactStatus) .AND. ALLOCATED(this%state%contactStatus) .AND. SIZE(arg%contactStatus) >= n) &
      this%state%contactStatus(1:n) = arg%contactStatus(1:n)
    IF (ALLOCATED(arg%slipDisp) .AND. ALLOCATED(this%state%slipDisp)) THEN
      DO i = 1, MIN(n, SIZE(arg%slipDisp, 2), SIZE(this%state%slipDisp, 2))
        this%state%slipDisp(1:2, i) = arg%slipDisp(1:2, i)
      END DO
    END IF
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE UpdateState
  
  !====================================================================
  ! Phase 3 Enhancement: New interface methods for Pair Desc
  !====================================================================
  
  !--------------------------------------------------------------------
  !> @brief Register contact pair from descriptor
  !--------------------------------------------------------------------
  SUBROUTINE RegisterFromDesc(this, pair_desc, status)
    CLASS(PH_Contact_Domain), INTENT(INOUT) :: this
    TYPE(PH_Contact_Pair_Desc), INTENT(IN) :: pair_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: new_n
    TYPE(PH_Contact_Pair_Desc), ALLOCATABLE :: tmp(:)
    
    CALL init_error_status(status)
    
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Contact domain not initialized"
      RETURN
    END IF
    
    ! Expand pairs array
    new_n = this%n_pairs + 1_i4
    ALLOCATE(tmp(new_n))
    
    IF (this%n_pairs > 0) THEN
      tmp(1:this%n_pairs) = this%pairs
    END IF
    
    ! Add new pair
    tmp(new_n) = pair_desc
    CALL MOVE_ALLOC(tmp, this%pairs)
    this%n_pairs = new_n
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RegisterFromDesc
  
  !--------------------------------------------------------------------
  !> @brief Get contact pair by index
  !--------------------------------------------------------------------
  FUNCTION PH_Contact_Domain_GetPair(this, index, status) RESULT(pair_ptr)
    CLASS(PH_Contact_Domain), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: index
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(PH_Contact_Pair_Desc), POINTER :: pair_ptr
    
    CALL init_error_status(status)
    
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Contact domain not initialized"
      NULLIFY(pair_ptr)
      RETURN
    END IF
    
    IF (index < 1_i4 .OR. index > this%n_pairs) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid pair index"
      NULLIFY(pair_ptr)
      RETURN
    END IF
    
    pair_ptr => this%pairs(index)
    status%status_code = IF_STATUS_OK
  END FUNCTION PH_Contact_Domain_GetPair
  
  !--------------------------------------------------------------------
  !> @brief Get number of registered contact pairs
  !--------------------------------------------------------------------
  FUNCTION PH_Contact_Domain_GetPairCount(this) RESULT(n)
    CLASS(PH_Contact_Domain), INTENT(IN) :: this
    INTEGER(i4) :: n
    n = this%n_pairs
  END FUNCTION PH_Contact_Domain_GetPairCount
  
END MODULE PH_Cont_Domain