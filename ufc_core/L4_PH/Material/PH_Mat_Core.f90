!===============================================================================
! MODULE: PH_Mat_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Standard facade for material-level computations (Init/Compute/Eval).
! **W1**：**L4 材料热路径门面**；真源 **槽 `PH_Mat_Desc` / `desc%props` / `PH_Mat_Desc_Effective_Model`**；**S1–S4** 经 **`PH_Mat_Dispatch_*`** 与族核、**`PH_MatEval`** / **`RT_Mat_Brg`** 金线对齐。
!===============================================================================
! Provides the canonical Init/Compute_Stress/Compute_Tangent/Init_SDV interface,
! dispatching to family-specific kernels (Elas/Plast/HyperElas/Damage/Creep/...)
! via the registry.
!
! Phase 5C: Standardized 4-step Execute pipeline:
!   PH_Mat_Execute_Flow -> S1_FetchState -> S2_Dispatch -> S3_StressUpdate -> S4_Tangent
!
! Theory: sigma_{n+1} = f(eps_{n+1}, state_n, mat_params)
!         C_tan = d(sigma)/d(eps)  (algorithmic tangent)
!
! Contents (A-Z):
!   Functions:
!     - PH_Mat_Core_Get_NSDV
!   Subroutines:
!     - PH_Mat_Core_Compute_Tangent
!     - PH_Mat_Core_Execute
!     - PH_Mat_Core_Finalize
!     - PH_Mat_Core_Init
!     - PH_Mat_Core_Init_SDV
!     - PH_Mat_Core_Update_Stress
!     - PH_Mat_Execute_Flow  (S1->S4 pipeline)
!     - PH_Mat_S1_FetchState
!     - PH_Mat_S2_Dispatch
!     - PH_Mat_S3_StressUpdate
!     - PH_Mat_S4_Tangent
!===============================================================================
MODULE PH_Mat_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Reg, ONLY: PH_Mat_Init_AllKernels, &
                         PH_Mat_GetKernel
  USE PH_Mat_KernelDefn, ONLY: PH_Mat_KernelBase, PH_Mat_Update_Arg
  USE PH_Mat_Def, ONLY: PH_Mat_Domain, PH_Mat_Slot, &
                                      PH_Mat_Desc, PH_Mat_Ctx, &
                                      PH_Mat_State, PH_Mat_Algo, &
                                      PH_MAT_UNKNOWN, &
                                      PH_Mat_State_DualWrite_Stress6, &
                                      PH_Mat_State_DualWrite_Ctan66, &
                                      PH_Mat_State_DualWrite_StateVars
  USE PH_Mat_Dsp, ONLY: PH_Mat_Dispatch_Stress, &
                         PH_Mat_Dispatch_Tangent
  IMPLICIT NONE
  PRIVATE

  !--- [PUBLIC PROCEDURES] ---
  PUBLIC :: PH_Mat_Core_Init
  PUBLIC :: PH_Mat_Core_Finalize
  PUBLIC :: PH_Mat_Core_Update_Stress
  PUBLIC :: PH_Mat_Core_Compute_Tangent
  PUBLIC :: PH_Mat_Core_Init_SDV
  PUBLIC :: PH_Mat_Core_Get_NSDV
  ! Standardized 4-step Execute pipeline (Phase 5C)
  PUBLIC :: PH_Mat_Core_Execute
  PUBLIC :: PH_Mat_Execute_Flow
  PUBLIC :: PH_Mat_Execute_Tangent_Flow
  PUBLIC :: PH_Mat_S1_FetchState
  PUBLIC :: PH_Mat_S2_Dispatch
  PUBLIC :: PH_Mat_S3_StressUpdate
  PUBLIC :: PH_Mat_S4_Tangent
  PUBLIC :: PH_Mat_Desc_Effective_Model

  !--- Effective material family: nested cfg first, deprecated flat fallback ---
  PURE FUNCTION PH_Mat_Desc_Effective_Model(desc) RESULT(m)
    INTEGER(i4) :: m
    TYPE(PH_Mat_Desc), INTENT(IN) :: desc

    m = desc%cfg%matModel
  END FUNCTION PH_Mat_Desc_Effective_Model

  !--- P0 Cold Path: Init/Finalize/Validate ---

  !==========================================================================
  ! SUBROUTINE: PH_Mat_Core_Init
  ! PHASE:   P0 (cold path)
  ! PURPOSE: Initialize material domain - register all family kernels.
  !==========================================================================
  SUBROUTINE PH_Mat_Core_Init(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    !  S1-S6. Register all family kernels via factory registry
    CALL PH_Mat_Init_AllKernels()

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Core_Init

  !==========================================================================
  ! SUBROUTINE: PH_Mat_Core_Finalize
  ! PHASE:   P0 (cold path)
  ! PURPOSE: Release material domain resources.
  !==========================================================================
  SUBROUTINE PH_Mat_Core_Finalize(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ! Registry entries are module-level SAVE; cleared at program exit.
    ! No explicit deallocation needed for factory singletons.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Core_Finalize

  !==========================================================================
  ! SUBROUTINE: PH_Mat_Core_Init_SDV
  ! PHASE:   P0 (cold path)
  ! PURPOSE: Initialize state-dependent variables for a material type.
  !==========================================================================
  SUBROUTINE PH_Mat_Core_Init_SDV(mat_type, mat_id, nsdv, sdv, status)
    INTEGER(i4), INTENT(IN)  :: mat_type
    INTEGER(i4), INTENT(IN)  :: mat_id
    INTEGER(i4), INTENT(OUT) :: nsdv
    REAL(wp),    INTENT(OUT) :: sdv(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CLASS(PH_Mat_KernelBase), POINTER :: kernel_ptr
    INTEGER(i4) :: reg_st

    CALL init_error_status(status)
    nsdv = 0

    !  S1. Look up kernel by (mat_type)
    CALL PH_Mat_GetKernel(mat_type, kernel_ptr, reg_st)
    IF (reg_st /= 0 .OR. .NOT. ASSOCIATED(kernel_ptr)) THEN
      ! Kernel not found -> default: zero SDVs (pure elastic, etc.)
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    !  S2. Delegate to kernel-specific SDV initialization
    nsdv = kernel_ptr%n_sdv
    IF (nsdv > 0 .AND. SIZE(sdv) >= nsdv) THEN
      CALL kernel_ptr%InitSDV(sdv, nsdv, reg_st)
      IF (reg_st /= 0) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = '[PH_Mat_Core_Init_SDV]: kernel init_sdv failed'
        RETURN
      END IF
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Core_Init_SDV

  !--- P2 Hot Path: 4-step Execute Pipeline ---

  !==========================================================================
  ! SUBROUTINE: PH_Mat_Core_Execute
  ! PHASE:   P2 (hot path)
  ! BRIEF:   Standardized material evaluation via 4-step pipeline.
  !          Delegates to PH_Mat_Execute_Flow(S1->S2->S3->S4).
  !==========================================================================
  SUBROUTINE PH_Mat_Core_Execute(domain, mat_pt_idx, status)
    TYPE(PH_Mat_Domain),   INTENT(INOUT) :: domain
    INTEGER(i4),           INTENT(IN)    :: mat_pt_idx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    CALL PH_Mat_Execute_Flow(domain, mat_pt_idx, status)
  END SUBROUTINE PH_Mat_Core_Execute

  !==========================================================================
  ! SUBROUTINE: PH_Mat_Execute_Flow
  ! PHASE:   P2 (hot path)
  ! PURPOSE: 4-step material constitutive pipeline (S1->S4).
  !==========================================================================
  SUBROUTINE PH_Mat_Execute_Flow(domain, mat_pt_idx, status)
    TYPE(PH_Mat_Domain),   INTENT(INOUT) :: domain
    INTEGER(i4),           INTENT(IN)    :: mat_pt_idx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    TYPE(PH_Mat_Desc)  :: desc_loc
    TYPE(PH_Mat_Ctx)   :: ctx_loc
    TYPE(PH_Mat_State)  :: state_loc
    TYPE(PH_Mat_Algo)  :: algo_loc

    CALL init_error_status(status)

    ! Guard: valid slot
    IF (.NOT. domain%initialized .OR. .NOT. ALLOCATED(domain%slot_pool)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_Execute_Flow]: domain not initialized'
      RETURN
    END IF
    IF (mat_pt_idx < 1 .OR. mat_pt_idx > domain%pool_count) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_Execute_Flow]: invalid mat_pt_idx'
      RETURN
    END IF

    ! S1: Fetch state from slot
    CALL PH_Mat_S1_FetchState(domain, mat_pt_idx, desc_loc, ctx_loc, &
                               state_loc, algo_loc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! S2: Dispatch to family kernel
    CALL PH_Mat_S2_Dispatch(desc_loc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! S3: Stress update
    CALL PH_Mat_S3_StressUpdate(desc_loc, ctx_loc, state_loc, algo_loc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! S4: Compute tangent
    CALL PH_Mat_S4_Tangent(desc_loc, ctx_loc, state_loc, algo_loc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Commit updated state back to slot
    domain%slot_pool(mat_pt_idx)%state = state_loc
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Execute_Flow

  !==========================================================================
  ! SUBROUTINE: PH_Mat_Execute_Tangent_Flow
  ! PHASE:   P2 (hot path)
  ! PURPOSE: Algorithmic tangent only (S1 -> S2 -> S4), after stress state
  !          has been updated by PH_Mat_Execute_Flow / S3.
  !==========================================================================
  SUBROUTINE PH_Mat_Execute_Tangent_Flow(domain, mat_pt_idx, status)
    TYPE(PH_Mat_Domain),   INTENT(INOUT) :: domain
    INTEGER(i4),           INTENT(IN)    :: mat_pt_idx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    TYPE(PH_Mat_Desc)  :: desc_loc
    TYPE(PH_Mat_Ctx)   :: ctx_loc
    TYPE(PH_Mat_State)  :: state_loc
    TYPE(PH_Mat_Algo)  :: algo_loc

    CALL init_error_status(status)

    IF (.NOT. domain%initialized .OR. .NOT. ALLOCATED(domain%slot_pool)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_Execute_Tangent_Flow]: domain not initialized'
      RETURN
    END IF
    IF (mat_pt_idx < 1 .OR. mat_pt_idx > domain%pool_count) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_Execute_Tangent_Flow]: invalid mat_pt_idx'
      RETURN
    END IF

    CALL PH_Mat_S1_FetchState(domain, mat_pt_idx, desc_loc, ctx_loc, &
                               state_loc, algo_loc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_S2_Dispatch(desc_loc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_S4_Tangent(desc_loc, ctx_loc, state_loc, algo_loc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    domain%slot_pool(mat_pt_idx)%state = state_loc
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Execute_Tangent_Flow

  !==========================================================================
  ! SUBROUTINE: PH_Mat_S1_FetchState
  ! PHASE:   P2 (hot path)
  ! PURPOSE: Step 1 - Fetch material point state from domain slot.
  !==========================================================================
  SUBROUTINE PH_Mat_S1_FetchState(domain, mat_pt_idx, desc, ctx, state, algo, status)
    TYPE(PH_Mat_Domain), INTENT(IN)       :: domain
    INTEGER(i4),         INTENT(IN)       :: mat_pt_idx
    TYPE(PH_Mat_Desc),   INTENT(OUT)      :: desc
    TYPE(PH_Mat_Ctx),    INTENT(OUT)      :: ctx
    TYPE(PH_Mat_State),   INTENT(OUT)     :: state
    TYPE(PH_Mat_Algo),   INTENT(OUT)      :: algo
    TYPE(ErrorStatusType), INTENT(INOUT)  :: status

    desc  = domain%slot_pool(mat_pt_idx)%desc
    ctx   = domain%slot_pool(mat_pt_idx)%ctx
    state = domain%slot_pool(mat_pt_idx)%state
    algo  = domain%slot_pool(mat_pt_idx)%algo
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_S1_FetchState

  !==========================================================================
  ! SUBROUTINE: PH_Mat_S2_Dispatch
  ! PHASE:   P2 (hot path)
  ! PURPOSE: Step 2 - Dispatch to family-level kernel via mat_type.
  !==========================================================================
  SUBROUTINE PH_Mat_S2_Dispatch(desc, status)
    TYPE(PH_Mat_Desc),    INTENT(IN)    :: desc
    TYPE(ErrorStatusType), INTENT(INOUT) :: status

    ! Validate: ensure kernel exists for this material type
    CALL PH_Mat_Dispatch_Stress(PH_Mat_Desc_Effective_Model(desc), status)
  END SUBROUTINE PH_Mat_S2_Dispatch

  !==========================================================================
  ! SUBROUTINE: PH_Mat_S3_StressUpdate
  ! PHASE:   P2 (hot path)
  ! PURPOSE: Step 3 - Perform constitutive stress update at IP.
  !==========================================================================
  SUBROUTINE PH_Mat_S3_StressUpdate(desc, ctx, state, algo, status)
    TYPE(PH_Mat_Desc),    INTENT(IN)     :: desc
    TYPE(PH_Mat_Ctx),     INTENT(IN)     :: ctx
    TYPE(PH_Mat_State),    INTENT(INOUT) :: state
    TYPE(PH_Mat_Algo),    INTENT(IN)     :: algo
    TYPE(ErrorStatusType), INTENT(INOUT) :: status

    CLASS(PH_Mat_KernelBase), POINTER :: kernel_ptr
    INTEGER(i4) :: reg_st
    TYPE(PH_Mat_Update_Arg) :: uarg
    REAL(wp) :: s6_w(6)
    INTEGER(i4) :: j

    CALL PH_Mat_GetKernel(PH_Mat_Desc_Effective_Model(desc), kernel_ptr, reg_st)
    IF (reg_st /= 0 .OR. .NOT. ASSOCIATED(kernel_ptr)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_S3_StressUpdate]: kernel not found'
      RETURN
    END IF

    ! Pack Update_Arg from four-type state (nested comp/evo)
    uarg%ntens = 6_i4
    uarg%dt    = ctx%inc%dt
    IF (ALLOCATED(desc%props)) uarg%props => desc%props
    IF (ALLOCATED(state%evo%stateVars_n)) THEN
      uarg%sdv_n => state%evo%stateVars_n
    END IF
    IF (ALLOCATED(state%comp%stress) .AND. SIZE(state%comp%stress) >= 6_i4) THEN
      uarg%stress_new(1:6) = state%comp%stress(1:6)
    ELSE
      uarg%stress_new(1:6) = 0.0_wp
    END IF
    uarg%mat_model_id = desc%pop%mat_model_id
    uarg%dstrain(1:6) = ctx%lcl%dstrain(1:6)
    ALLOCATE(uarg%sdv_tr(MAX(kernel_ptr%n_sdv, 1)))
    uarg%sdv_tr = 0.0_wp

    CALL kernel_ptr%UpdateStress(uarg, reg_st)

    IF (reg_st /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_S3_StressUpdate]: kernel update failed'
      IF (ASSOCIATED(uarg%sdv_tr)) DEALLOCATE(uarg%sdv_tr)
      RETURN
    END IF

    ! Write back to state (dual-track via Domain_Core helper + SDV inline)
    DO j = 1, 6
      s6_w(j) = REAL(uarg%stress_new(j), KIND=wp)
    END DO
    CALL PH_Mat_State_DualWrite_Stress6(state, s6_w)
    IF (kernel_ptr%n_sdv > 0) THEN
      BLOCK
        REAL(wp) :: sdv_pack(kernel_ptr%n_sdv)
        sdv_pack(1:kernel_ptr%n_sdv) = REAL(uarg%sdv_tr(1:kernel_ptr%n_sdv), KIND=wp)
        CALL PH_Mat_State_DualWrite_StateVars(state, kernel_ptr%n_sdv, sdv_pack)
      END BLOCK
    END IF
    IF (ASSOCIATED(uarg%sdv_tr)) DEALLOCATE(uarg%sdv_tr)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_S3_StressUpdate

  !==========================================================================
  ! SUBROUTINE: PH_Mat_S4_Tangent
  ! PHASE:   P2 (hot path)
  ! PURPOSE: Step 4 - Compute consistent algorithmic tangent.
  !==========================================================================
  SUBROUTINE PH_Mat_S4_Tangent(desc, ctx, state, algo, status)
    TYPE(PH_Mat_Desc),    INTENT(IN)     :: desc
    TYPE(PH_Mat_Ctx),     INTENT(IN)     :: ctx
    TYPE(PH_Mat_State),    INTENT(INOUT) :: state
    TYPE(PH_Mat_Algo),    INTENT(IN)     :: algo
    TYPE(ErrorStatusType), INTENT(INOUT) :: status

    CLASS(PH_Mat_KernelBase), POINTER :: kernel_ptr
    INTEGER(i4) :: reg_st
    TYPE(PH_Mat_Update_Arg) :: uarg
    REAL(wp) :: d66_w(6, 6)
    INTEGER(i4) :: ia, ib

    CALL PH_Mat_GetKernel(PH_Mat_Desc_Effective_Model(desc), kernel_ptr, reg_st)
    IF (reg_st /= 0 .OR. .NOT. ASSOCIATED(kernel_ptr)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_S4_Tangent]: kernel not found'
      RETURN
    END IF

    uarg%ntens = 6_i4
    uarg%mat_model_id = desc%pop%mat_model_id
    uarg%dstrain(1:6) = ctx%lcl%dstrain(1:6)
    IF (ALLOCATED(desc%props)) uarg%props => desc%props
    IF (ALLOCATED(state%evo%stateVars)) THEN
      uarg%sdv_n => state%evo%stateVars
    END IF
    IF (ALLOCATED(state%comp%stress) .AND. SIZE(state%comp%stress) >= 6_i4) THEN
      uarg%stress_new(1:6) = state%comp%stress(1:6)
    ELSE
      uarg%stress_new(1:6) = 0.0_wp
    END IF

    CALL kernel_ptr%ComputeCTM(uarg, reg_st)

    IF (reg_st /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_S4_Tangent]: kernel ctm failed'
      RETURN
    END IF

    DO ia = 1, 6
      DO ib = 1, 6
        d66_w(ia, ib) = REAL(uarg%D_tang(ia, ib), KIND=wp)
      END DO
    END DO
    CALL PH_Mat_State_DualWrite_Ctan66(state, d66_w)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_S4_Tangent

  !--- P2 Hot Path: Legacy flat-parameter interfaces ---

  !==========================================================================
  ! SUBROUTINE: PH_Mat_Core_Update_Stress
  ! PHASE:   P2 (hot path)
  ! PURPOSE: Unified material stress update (dispatch by mat_type).
  !          NOTE: Legacy flat-parameter interface kept for backward compat.
  !          Prefer PH_Mat_Core_Execute for new code.
  !==========================================================================
  SUBROUTINE PH_Mat_Core_Update_Stress(mat_type, mat_id, nprops, props, &
                                        strain, d_strain, stress_old, &
                                        state_old, nsdv, &
                                        stress_new, state_new, status)
    INTEGER(i4), INTENT(IN)  :: mat_type
    INTEGER(i4), INTENT(IN)  :: mat_id
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    REAL(wp),    INTENT(IN)  :: strain(6)
    REAL(wp),    INTENT(IN)  :: d_strain(6)
    REAL(wp),    INTENT(IN)  :: stress_old(6)
    REAL(wp),    INTENT(IN)  :: state_old(:)
    INTEGER(i4), INTENT(IN)  :: nsdv
    REAL(wp),    INTENT(OUT) :: stress_new(6)
    REAL(wp),    INTENT(INOUT) :: state_new(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CLASS(PH_Mat_KernelBase), POINTER :: kernel_ptr
    INTEGER(i4) :: reg_st
    TYPE(PH_Mat_Update_Arg) :: uarg

    CALL init_error_status(status)
    stress_new = 0.0_wp

    !  S1. Look up kernel by mat_type
    CALL PH_Mat_GetKernel(mat_type, kernel_ptr, reg_st)
    IF (reg_st /= 0 .OR. .NOT. ASSOCIATED(kernel_ptr)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_Core_Update_Stress]: kernel not found'
      RETURN
    END IF

    !  S2. Pack Update_args and delegate
    uarg%dstrain(1:6)  = d_strain(1:6)
    uarg%strain_n(1:6) = strain(1:6)
    uarg%ntens         = 6_i4
    IF (nprops > 0 .AND. SIZE(props) >= nprops) uarg%props => props
    IF (nsdv > 0 .AND. SIZE(state_old) >= nsdv) uarg%sdv_n => state_old
    ALLOCATE(uarg%sdv_tr(MAX(nsdv, 1)))
    uarg%sdv_tr = 0.0_wp

    CALL kernel_ptr%UpdateStress(uarg, reg_st)

    !  S3. Propagate results and check sub-status
    IF (reg_st /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_Core_Update_Stress]: kernel update failed'
      IF (ASSOCIATED(uarg%sdv_tr)) DEALLOCATE(uarg%sdv_tr)
      RETURN
    END IF

    stress_new(1:6) = uarg%stress_new(1:6)
    IF (nsdv > 0 .AND. SIZE(state_new) >= nsdv) THEN
      state_new(1:nsdv) = uarg%sdv_tr(1:nsdv)
    END IF
    IF (ASSOCIATED(uarg%sdv_tr)) DEALLOCATE(uarg%sdv_tr)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Core_Update_Stress

  !==========================================================================
  ! SUBROUTINE: PH_Mat_Core_Compute_Tangent
  ! PHASE:   P2 (hot path)
  ! PURPOSE: Compute algorithmic tangent modulus C_tan.
  !==========================================================================
  SUBROUTINE PH_Mat_Core_Compute_Tangent(mat_type, mat_id, nprops, props, &
                                          strain, state, nsdv, &
                                          tangent, status)
    INTEGER(i4), INTENT(IN)  :: mat_type
    INTEGER(i4), INTENT(IN)  :: mat_id
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    REAL(wp),    INTENT(IN)  :: strain(6)
    REAL(wp),    INTENT(IN)  :: state(:)
    INTEGER(i4), INTENT(IN)  :: nsdv
    REAL(wp),    INTENT(OUT) :: tangent(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CLASS(PH_Mat_KernelBase), POINTER :: kernel_ptr
    INTEGER(i4) :: reg_st
    TYPE(PH_Mat_Update_Arg) :: uarg

    CALL init_error_status(status)
    tangent = 0.0_wp

    !  S1. Look up kernel
    CALL PH_Mat_GetKernel(mat_type, kernel_ptr, reg_st)
    IF (reg_st /= 0 .OR. .NOT. ASSOCIATED(kernel_ptr)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_Core_Compute_Tangent]: kernel not found'
      RETURN
    END IF

    !  S2. Pack args and call kernel tangent
    uarg%strain_n(1:6) = strain(1:6)
    uarg%ntens         = 6_i4
    IF (nprops > 0 .AND. SIZE(props) >= nprops) uarg%props => props
    IF (nsdv > 0 .AND. SIZE(state) >= nsdv) uarg%sdv_n => state

    CALL kernel_ptr%ComputeCTM(uarg, reg_st)

    IF (reg_st /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[PH_Mat_Core_Compute_Tangent]: kernel ctm failed'
      RETURN
    END IF

    tangent(1:6, 1:6) = uarg%D_tang(1:6, 1:6)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Core_Compute_Tangent

  !==========================================================================
  ! FUNCTION: PH_Mat_Core_Get_NSDV
  ! PHASE:   P0 (cold path)
  ! PURPOSE: Query number of state variables for a material.
  !==========================================================================
  FUNCTION PH_Mat_Core_Get_NSDV(mat_type, mat_id) RESULT(nsdv)
    INTEGER(i4), INTENT(IN) :: mat_type
    INTEGER(i4), INTENT(IN) :: mat_id
    INTEGER(i4) :: nsdv

    CLASS(PH_Mat_KernelBase), POINTER :: kernel_ptr
    INTEGER(i4) :: reg_st

    CALL PH_Mat_GetKernel(mat_type, kernel_ptr, reg_st)
    IF (reg_st == 0 .AND. ASSOCIATED(kernel_ptr)) THEN
      nsdv = kernel_ptr%n_sdv
    ELSE
      nsdv = 0_i4
    END IF
  END FUNCTION PH_Mat_Core_Get_NSDV

END MODULE PH_Mat_Core


