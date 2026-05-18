!===============================================================================
! MODULE: RT_Cont_Core
! LAYER:  L5_RT
! DOMAIN: Contact
! ROLE:   Core — unified facade + lifecycle / registration / pair init
! BRIEF:  Four-type facade (Part-A) + RT_Cont_Mgr lifecycle (Part-B).
!===============================================================================
MODULE RT_Cont_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Cont_Def, ONLY: RT_Contact_Desc, RT_Contact_State, &
                             RT_Contact_Algo, RT_Contact_Ctx
  USE MD_Model_Mgr, ONLY: UF_ModelVarContext, UF_ModelVar_RegisterField, &
       UF_VarLoc_Contact, UF_VarType_DP
  USE RT_Base_Core, ONLY: UF_Model
  IMPLICIT NONE
  PRIVATE

  ! ===========================================================================
  ! Part-A: Simplified four-type facade (original RT_Cont_Core)
  ! ===========================================================================
  PUBLIC :: RT_Contact_Core_Init
  PUBLIC :: RT_Contact_Core_Finalize
  PUBLIC :: RT_Contact_Search
  PUBLIC :: RT_Contact_Evaluate_Pairs
  PUBLIC :: RT_Contact_Assemble_K
  PUBLIC :: RT_Contact_Assemble_F
  PUBLIC :: RT_Contact_Update_Status
  PUBLIC :: RT_Contact_Get_N_Active

  ! ===========================================================================
  ! Part-B: Lifecycle / registration / pair init (merged from RT_Cont_Core2)
  ! ===========================================================================

  ! ---------------------------------------------------------------------------
  ! Internal minimal types (replace deleted Legacy RT_ContactSurface/PairDef/Pair)
  ! ---------------------------------------------------------------------------

  !> Minimal surface descriptor — node count + surface ID only
  TYPE :: RT_Cont_SurfDesc
    INTEGER(i4) :: surf_id  = 0_i4  ! Unique surface ID
    INTEGER(i4) :: n_nodes  = 0_i4  ! Slave/master node count
  END TYPE RT_Cont_SurfDesc

  !> Minimal pair definition — surface ID pair + enforcement flags
  TYPE :: RT_Cont_PairDef
    INTEGER(i4) :: pair_id       = 0_i4  ! Pair index
    INTEGER(i4) :: master_surf_id = 0_i4
    INTEGER(i4) :: slave_surf_id  = 0_i4
    LOGICAL     :: friction       = .FALSE.
    LOGICAL     :: thermal        = .FALSE.
  END TYPE RT_Cont_PairDef

  !> Per-pair runtime buffers (gap / force / friction force)
  TYPE :: RT_Cont_PairBuf
    TYPE(RT_Cont_PairDef)         :: def
    LOGICAL                       :: active         = .FALSE.
    INTEGER(i4)                   :: n_active_nodes = 0_i4
    REAL(wp), ALLOCATABLE         :: gap(:)          ! (n_slave_nodes)
    REAL(wp), ALLOCATABLE         :: normal_force(:) ! (n_slave_nodes)
    REAL(wp), ALLOCATABLE         :: fric_force(:,:) ! (3, n_slave_nodes)
  END TYPE RT_Cont_PairBuf

  ! Public API — lifecycle / registration
  PUBLIC :: RT_Cont_Mgr
  PUBLIC :: g_cont_mgr
  PUBLIC :: RT_Cont_Init
  PUBLIC :: RT_Cont_Clean
  PUBLIC :: RT_Cont_RegVars
  PUBLIC :: RT_Cont_RegModel
  PUBLIC :: RT_Cont_GetStat
  PUBLIC :: contact_init_from_pair

  ! ===================================================================
  ! Contact Manager Type
  ! ===================================================================
  TYPE, PUBLIC :: RT_Cont_Mgr
    LOGICAL     :: inited = .FALSE.
    INTEGER(i4) :: nContPairs = 0_i4
    INTEGER(i4) :: maxContPairs = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => Mgr_Init
    PROCEDURE, PUBLIC :: Clean => Mgr_Clean
    PROCEDURE, PUBLIC :: Reg => Mgr_Reg
    PROCEDURE, PUBLIC :: GetStat => Mgr_GetStat
  END TYPE RT_Cont_Mgr

  ! ===================================================================
  ! Global Manager Instance
  ! ===================================================================
  TYPE(RT_Cont_Mgr), SAVE, PUBLIC :: g_cont_mgr

CONTAINS

  ! ***************************************************************************
  ! Part-A: Simplified four-type facade
  ! ***************************************************************************

  SUBROUTINE RT_Contact_Core_Init(desc, state, algo, ctx, status)
    TYPE(RT_Contact_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Contact_State), INTENT(INOUT) :: state
    TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%n_active_pairs = 0_i4
    NULLIFY(state%pair_active)
    NULLIFY(state%penetration)
    NULLIFY(state%f_contact)
    NULLIFY(ctx%temp_force)
    NULLIFY(ctx%temp_disp)
    ctx%current_pair_idx = 0_i4

    IF (desc%n_contact_pairs > 0) THEN
      ALLOCATE(state%pair_active(desc%n_contact_pairs))
      ALLOCATE(state%penetration(desc%n_contact_pairs))
      ALLOCATE(state%f_contact(desc%n_contact_pairs))
      state%pair_active = .FALSE.
      state%penetration  = 0.0_wp
      state%f_contact    = 0.0_wp
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Core_Init

  SUBROUTINE RT_Contact_Core_Finalize(state, ctx, status)
    TYPE(RT_Contact_State), INTENT(INOUT) :: state
    TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (ASSOCIATED(state%pair_active))  DEALLOCATE(state%pair_active)
    IF (ASSOCIATED(state%penetration))  DEALLOCATE(state%penetration)
    IF (ASSOCIATED(state%f_contact))    DEALLOCATE(state%f_contact)
    NULLIFY(state%pair_active)
    NULLIFY(state%penetration)
    NULLIFY(state%f_contact)
    IF (ASSOCIATED(ctx%temp_force)) NULLIFY(ctx%temp_force)
    IF (ASSOCIATED(ctx%temp_disp))  NULLIFY(ctx%temp_disp)
    state%n_active_pairs = 0_i4
    ctx%current_pair_idx = 0_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Core_Finalize

  SUBROUTINE RT_Contact_Search(desc, state, algo, status)
    TYPE(RT_Contact_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Contact_State), INTENT(INOUT) :: state
    TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: ip

    CALL init_error_status(status)
    IF (desc%n_contact_pairs <= 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    state%n_active_pairs = 0_i4

    IF (algo%use_global_search) THEN
      ! Global search: mark pairs with penetration < tolerance as active
      DO ip = 1, desc%n_contact_pairs
        IF (ASSOCIATED(state%penetration)) THEN
          IF (ABS(state%penetration(ip)) < desc%global_search_tol) THEN
            state%pair_active(ip) = .TRUE.
            state%n_active_pairs = state%n_active_pairs + 1_i4
          ELSE
            state%pair_active(ip) = .FALSE.
          END IF
        END IF
      END DO
    ELSE
      ! Local search: all pairs active
      DO ip = 1, desc%n_contact_pairs
        IF (ASSOCIATED(state%pair_active)) THEN
          state%pair_active(ip) = .TRUE.
          state%n_active_pairs = state%n_active_pairs + 1_i4
        END IF
      END DO
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Search

  SUBROUTINE RT_Contact_Evaluate_Pairs(desc, state, algo, ctx, status)
    TYPE(RT_Contact_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Contact_State), INTENT(INOUT) :: state
    TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: ip
    REAL(wp)    :: pen, k_pen

    CALL init_error_status(status)

    SELECT CASE (algo%enforcement_method)
    CASE (RT_CONT_ENFORCE_PENALTY)
      ! Penalty method: f = k_pen * penetration
      k_pen = algo%penalty_scale_factor
      DO ip = 1, desc%n_contact_pairs
        IF (ASSOCIATED(state%pair_active) .AND. state%pair_active(ip)) THEN
          pen = 0.0_wp
          IF (ASSOCIATED(state%penetration)) pen = state%penetration(ip)
          IF (pen < 0.0_wp) THEN
            ! Penetration detected: compute penalty force
            IF (ASSOCIATED(state%f_contact)) THEN
              state%f_contact(ip) = -k_pen * pen
            END IF
          ELSE
            IF (ASSOCIATED(state%f_contact)) state%f_contact(ip) = 0.0_wp
          END IF
        END IF
      END DO
    CASE (RT_CONT_ENFORCE_LAGRANGE, RT_CONT_ENFORCE_AUG_LAGRANGE)
      ! Lagrange / Augmented Lagrange: handled by RT_Cont_AugLagSolv
      CONTINUE
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      RETURN
    END SELECT

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Evaluate_Pairs

  SUBROUTINE RT_Contact_Assemble_K(desc, state, ctx, status)
    TYPE(RT_Contact_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Contact_State), INTENT(IN)    :: state
    TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: ip, idof

    CALL init_error_status(status)

    ! Contact stiffness assembly: loop active pairs, compute contact stiffness
    ! from contact force derivatives, scatter to global K via ctx%temp_force
    IF (.NOT. desc%is_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Contact descriptor not initialized"
      RETURN
    END IF

    IF (.NOT. ASSOCIATED(ctx%temp_force)) THEN
      status%status_code = IF_STATUS_OK
      RETURN  ! No global tangent array available
    END IF

    ctx%temp_force = 0.0_wp

    DO ip = 1, desc%n_contact_pairs
      IF (.NOT. state%pair_active(ip)) CYCLE

      ! Penalty stiffness contribution: K_cont = k_pen * n * n^T
      ! where n is the normal vector at the contact point
      ! Scatter to global DOF positions via ctx%temp_disp mapping
      IF (ASSOCIATED(ctx%temp_disp)) THEN
        DO idof = 1, SIZE(ctx%temp_disp)
          ! Simplified: distribute contact stiffness along normal
          ctx%temp_force(idof) = ctx%temp_force(idof) + &
            state%f_contact(ip) * ctx%temp_disp(idof)
        END DO
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Assemble_K

  SUBROUTINE RT_Contact_Assemble_F(desc, state, ctx, status)
    TYPE(RT_Contact_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Contact_State), INTENT(IN)    :: state
    TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: ip

    CALL init_error_status(status)

    IF (.NOT. desc%is_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Contact descriptor not initialized"
      RETURN
    END IF

    IF (.NOT. ASSOCIATED(ctx%temp_force)) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ctx%temp_force = 0.0_wp

    ! Loop active pairs and accumulate contact forces into global force vector
    DO ip = 1, desc%n_contact_pairs
      IF (.NOT. state%pair_active(ip)) CYCLE
      ! Scatter pair contact force to global force vector
      ! In production: map per-pair forces to global DOF via mesh connectivity
      IF (ASSOCIATED(state%f_contact)) THEN
        ctx%temp_force(ip) = ctx%temp_force(ip) + state%f_contact(ip)
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Assemble_F

  SUBROUTINE RT_Contact_Update_Status(desc, state, status)
    TYPE(RT_Contact_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Contact_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: ip

    CALL init_error_status(status)
    state%n_active_pairs = 0_i4
    DO ip = 1, desc%n_contact_pairs
      IF (ASSOCIATED(state%penetration)) THEN
        state%pair_active(ip) = (state%penetration(ip) <= 0.0_wp)
        IF (state%pair_active(ip)) state%n_active_pairs = state%n_active_pairs + 1_i4
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Contact_Update_Status

  PURE FUNCTION RT_Contact_Get_N_Active(state) RESULT(n)
    TYPE(RT_Contact_State), INTENT(IN) :: state
    INTEGER(i4) :: n
    n = state%n_active_pairs
  END FUNCTION RT_Contact_Get_N_Active

  ! ***************************************************************************
  ! Part-B: Lifecycle / registration / pair init (merged from RT_Cont_Core2)
  ! ***************************************************************************

  ! ===================================================================
  ! Variable Registration
  ! ===================================================================
  SUBROUTINE RT_Cont_RegVars(model, varCtx)
    !! Reg contact variables
    !!
    !! Arguments:
    !!   model: Model instance
    !!   varCtx: Model variable Ctx

    TYPE(UF_Model),           INTENT(IN)    :: model
    TYPE(UF_ModelVarContext), INTENT(INOUT) :: varCtx

    INTEGER(i4) :: dims1(1), ierr_var

    dims1(1) = 1_i4

    CALL UF_ModelVar_RegisterField(varCtx, 'CONTACT_ALM_MAX_PEN', &
         location  = UF_VarLoc_Contact, &
         dType = UF_VarType_DP, &
         rank      = 1_i4, &
         dims      = dims1, &
         is_persistent = .TRUE., &
         ierr      = ierr_var)

    CALL UF_ModelVar_RegisterField(varCtx, 'CONTACT_ALM_LAMBDA_NORM', &
         location  = UF_VarLoc_Contact, &
         dType = UF_VarType_DP, &
         rank      = 1_i4, &
         dims      = dims1, &
         is_persistent = .TRUE., &
         ierr      = ierr_var)

  END SUBROUTINE RT_Cont_RegVars

  ! ===================================================================
  ! RT_Cont_Mgr Procedures
  ! ===================================================================
  SUBROUTINE Mgr_Init(this, maxContPairs, status)
    CLASS(RT_Cont_Mgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: maxContPairs
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (this%inited) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "RT_Cont_Mgr: Already initialized"
      END IF
      RETURN
    END IF

    this%maxContPairs = 100_i4
    IF (PRESENT(maxContPairs)) THEN
      this%maxContPairs = MAX(1_i4, maxContPairs)
    END IF

    this%nContPairs = 0_i4
    this%inited = .TRUE.

    IF (PRESENT(status)) THEN
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE Mgr_Init

  SUBROUTINE Mgr_Clean(this, status)
    CLASS(RT_Cont_Mgr), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    this%inited = .FALSE.
    this%nContPairs = 0_i4
    this%maxContPairs = 0_i4

    IF (PRESENT(status)) THEN
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE Mgr_Clean

  SUBROUTINE Mgr_Reg(this, model, status)
    CLASS(RT_Cont_Mgr), INTENT(INOUT) :: this
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. this%inited) THEN
      CALL this%Init(status=status)
      IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
    END IF

    ! Update statistics
    this%nContPairs = this%nContPairs + 1_i4
    ! Note: Actual contact pair counting would require model inspection

    IF (PRESENT(status)) THEN
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE Mgr_Reg

  SUBROUTINE Mgr_GetStat(this, nContactPairs)
    CLASS(RT_Cont_Mgr), INTENT(IN) :: this
    INTEGER(i4), INTENT(OUT), OPTIONAL :: nContactPairs

    IF (PRESENT(nContactPairs)) nContactPairs = this%nContPairs
  END SUBROUTINE Mgr_GetStat

  ! ===================================================================
  ! Global System Procedures
  ! ===================================================================
  SUBROUTINE RT_Cont_Init(maxContactPairs, status)
    !! Init contact system
    !!
    !! Arguments:
    !!   maxContactPairs: Maximum number of contact pairs (optional)
    !!   status: Error status (optional)

    INTEGER(i4), INTENT(IN), OPTIONAL :: maxContactPairs
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    CALL g_cont_mgr%Init(maxContactPairs=maxContactPairs, status=status)
  END SUBROUTINE RT_Cont_Init

  SUBROUTINE RT_Cont_Clean(status)
    !! Cleanup contact system
    !!
    !! Arguments:
    !!   status: Error status (optional)

    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    CALL g_cont_mgr%Clean(status=status)
  END SUBROUTINE RT_Cont_Clean

  SUBROUTINE RT_Cont_RegModel(model, varCtx, status)
    !! Reg model in contact system
    !!
    !! Arguments:
    !!   model: Model to register
    !!   varCtx: Model variable Ctx
    !!   status: Error status (optional)

    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(UF_ModelVarContext), INTENT(INOUT) :: varCtx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    ! Reg contact variables
    CALL RT_Cont_RegVars(model, varCtx)

    ! Reg contact in manager
    CALL g_cont_mgr%Reg(model=model, status=status)
    IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN

    IF (PRESENT(status)) THEN
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE RT_Cont_RegModel

  SUBROUTINE RT_Cont_GetStat(nContactPairs)
    !! Get contact system statistics
    !!
    !! Arguments:
    !!   nContactPairs: Number of contact pairs (optional)

    INTEGER(i4), INTENT(OUT), OPTIONAL :: nContactPairs

    CALL g_cont_mgr%GetStat(nContactPairs=nContactPairs)
  END SUBROUTINE RT_Cont_GetStat

  ! ===========================================================================
  ! Core Contact Pair Initialization
  ! ===========================================================================

  SUBROUTINE contact_init_from_pair(pair, pair_def, &
                                     master_surf, slave_surf, status)
    !> Allocate per-slave-node gap/force buffers for a single contact pair.
    !> Uses internal types RT_Cont_PairBuf, RT_Cont_PairDef, RT_Cont_SurfDesc.
    TYPE(RT_Cont_PairBuf),  INTENT(OUT) :: pair
    TYPE(RT_Cont_PairDef),  INTENT(IN)  :: pair_def
    TYPE(RT_Cont_SurfDesc), INTENT(IN)  :: master_surf
    TYPE(RT_Cont_SurfDesc), INTENT(IN)  :: slave_surf
    TYPE(ErrorStatusType),  INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: nsl

    IF (PRESENT(status)) CALL init_error_status(status)

    nsl = slave_surf%n_nodes
    IF (nsl < 1_i4) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "contact_init_from_pair: slave surface has no nodes"
      END IF
      RETURN
    END IF

    IF (pair_def%master_surf_id > 0_i4 .AND. &
        master_surf%surf_id /= pair_def%master_surf_id) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "contact_init_from_pair: master surface id mismatch"
      END IF
      RETURN
    END IF

    IF (pair_def%slave_surf_id > 0_i4 .AND. &
        slave_surf%surf_id /= pair_def%slave_surf_id) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "contact_init_from_pair: slave surface id mismatch"
      END IF
      RETURN
    END IF

    pair%def            = pair_def
    pair%active         = .FALSE.
    pair%n_active_nodes = 0_i4

    IF (ALLOCATED(pair%gap))          DEALLOCATE(pair%gap)
    IF (ALLOCATED(pair%normal_force)) DEALLOCATE(pair%normal_force)
    IF (ALLOCATED(pair%fric_force))   DEALLOCATE(pair%fric_force)

    ALLOCATE(pair%gap(nsl));          pair%gap          = 0.0_wp
    ALLOCATE(pair%normal_force(nsl)); pair%normal_force = 0.0_wp
    ALLOCATE(pair%fric_force(3_i4, nsl)); pair%fric_force = 0.0_wp

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE contact_init_from_pair

END MODULE RT_Cont_Core
