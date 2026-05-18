!===============================================================================
! Ultra-Compact: PH_XXX_UMAT.f90  (One-Page PPT Edition)
! 五步 UMAT: D_el → trial → yield → branch → stran_update
!===============================================================================
MODULE PH_XXX_UMAT_Compact
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_Mat_Types,  ONLY: MD_Mat_Base_State, MD_Mat_Base_Algo
  USE MD_Mat_XXX,    ONLY: MD_Mat_XXX_Desc
  USE PH_Mat_Types,  ONLY: PH_Mat_Base_Ctx, PH_Mat_Base_Algo
  USE RT_Com_Types,  ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_XXX_State, PH_XXX_UMAT_Args, PH_XXX_UMAT_API

  TYPE, PUBLIC, EXTENDS(MD_Mat_Base_State) :: PH_Mat_XXX_State
    REAL(wp) :: ivar1 = 0.0_wp, ivar2 = 0.0_wp
  END TYPE

  TYPE, PUBLIC :: PH_XXX_UMAT_Args
    LOGICAL :: flag_nlgeom = .FALSE., flag_firstinc = .FALSE., success = .FALSE.
    INTEGER(i4) :: ip_index = 0_i4, iterations = 0_i4
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: pnewdt = 1.0_wp, residual_norm = 0.0_wp
  END TYPE

CONTAINS

  SUBROUTINE PH_XXX_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, MD_Mat_Algo, &
      PH_Mat_Algo, RT_Com_Ctx, pnewdt)
    TYPE(MD_Mat_XXX_Desc),    INTENT(IN)    :: MD_Mat_Desc
    TYPE(PH_Mat_Base_Ctx),    INTENT(IN)    :: PH_Mat_Ctx
    TYPE(PH_Mat_XXX_State),   INTENT(INOUT) :: PH_Mat_State
    TYPE(MD_Mat_Base_Algo),   INTENT(IN)    :: MD_Mat_Algo
    TYPE(PH_Mat_Base_Algo),   INTENT(IN)    :: PH_Mat_Algo
    TYPE(RT_Com_Base_Ctx),    INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                 INTENT(INOUT) :: pnewdt
    TYPE(PH_XXX_UMAT_Args) :: args

    args%flag_nlgeom = RT_Com_Ctx%nlgeom; args%flag_firstinc = RT_Com_Ctx%first_increment
    args%ip_index = RT_Com_Ctx%gauss_pt; args%success = .FALSE.
    CALL PH_XXX_UMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, MD_Mat_Algo, PH_Mat_Algo, args)
    pnewdt = args%pnewdt
  END SUBROUTINE

  SUBROUTINE PH_XXX_UMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, MD_Mat_Algo, PH_Mat_Algo, args)
    TYPE(MD_Mat_XXX_Desc),  INTENT(IN)    :: MD_Mat_Desc
    TYPE(PH_Mat_Base_Ctx),  INTENT(IN)    :: PH_Mat_Ctx
    TYPE(PH_Mat_XXX_State), INTENT(INOUT) :: PH_Mat_State
    TYPE(MD_Mat_Base_Algo), INTENT(IN)    :: MD_Mat_Algo
    TYPE(PH_Mat_Base_Algo), INTENT(IN)    :: PH_Mat_Algo
    TYPE(PH_XXX_UMAT_Args), INTENT(INOUT) :: args
    !$UFC HOT_PATH
    REAL(wp) :: D_el(6,6), stress_trial(6), f_yield, lam, mu
    INTEGER(i4) :: ntens

    CALL init_error_status(args%status); args%success = .FALSE.; args%pnewdt = RT_PNEWDT_NO_CHANGE
    CALL init_error_status(PH_Mat_State%status)

    ntens = MD_Mat_Algo%ntens
    IF (ntens < 1 .OR. ntens > 6 .OR. .NOT. MD_Mat_Desc%is_initialized) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, message='[UMAT]: init guard failed')
      RETURN
    END IF

    ! ========== STEP 1: D_el ==========
    lam = MD_Mat_Desc%lambda; mu = MD_Mat_Desc%G
    D_el = 0.0_wp
    D_el(1,1:3) = [lam+2*mu, lam, lam]; D_el(2,1:3) = [lam, lam+2*mu, lam]
    D_el(3,1:3) = [lam, lam, lam+2*mu]; D_el(4,4) = mu; D_el(5,5) = mu; D_el(6,6) = mu

    ! ========== STEP 2: Trial ==========
    stress_trial(1:ntens) = PH_Mat_State%stress(1:ntens) + &
                            MATMUL(D_el(1:ntens,1:ntens), PH_Mat_Ctx%dstran(1:ntens))

    ! ========== STEP 3: Yield ==========
    f_yield = von_Mises(stress_trial(1:ntens)) - (MD_Mat_Desc%sigma_y + MD_Mat_Desc%H * PH_Mat_State%ivar1)

    ! ========== STEP 4: Branch ==========
    IF (f_yield <= 0.0_wp) THEN
      PH_Mat_State%stress(1:ntens) = stress_trial(1:ntens)
      IF (MD_Mat_Algo%compute_tangent) PH_Mat_State%ddsdde(1:ntens,1:ntens) = D_el(1:ntens,1:ntens)
    ELSE
      ! Return mapping stub: replace with actual Newton iteration
      CALL init_error_status(args%status, IF_STATUS_ERROR, message='[UMAT]: return_map stub')
      RETURN
    END IF

    ! ========== STEP 5: stran update ==========
    PH_Mat_State%stran(1:ntens) = PH_Mat_State%stran(1:ntens) + PH_Mat_Ctx%dstran(1:ntens)

    args%success = .TRUE.; PH_Mat_State%status%status_code = IF_STATUS_OK
  END SUBROUTINE

  PURE FUNCTION von_Mises(sigma) RESULT(q)
    REAL(wp), INTENT(IN) :: sigma(:)
    REAL(wp) :: p, q
    p = (sigma(1) + sigma(2) + sigma(3)) / 3.0_wp
    q = SQRT(1.5_wp * ((sigma(1)-p)**2 + (sigma(2)-p)**2 + (sigma(3)-p)**2 + &
                       2.0_wp*(sigma(4)**2 + sigma(5)**2 + sigma(6)**2)))
  END FUNCTION

END MODULE PH_XXX_UMAT_Compact