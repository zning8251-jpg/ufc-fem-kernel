!===============================================================================
! MODULE: PH_Mat_Damage_Gurson_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Gurson-Tvergaard-Needleman porous plasticity damage model —
!         **W1**：Populate 写入 **MD_Mat_GTN_Desc** 与槽 **`PH_Mat_Desc`** / **`desc%props`**
!         金线一致；金线上勿误读 **`ctx%props`**。
!===============================================================================
MODULE PH_Mat_Damage_Gurson_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_Mat_Def,  ONLY: MD_MatState, MD_MatAlgo
  USE MD_Mat_Plast_GTN, ONLY: MD_Mat_GTN_Desc
  USE PH_Mat_Aux_Def, ONLY: PH_Mat_Krnl_Ctx, PH_Mat_Krnl_Algo  ! formerly PH_Mat_Base_Ctx/Base_Algo, renamed per R-09
  USE RT_Com_Def,  ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_GTN_State
  PUBLIC :: PH_GTN_UMAT_Args
  PUBLIC :: PH_GTN_UMAT_API
  PUBLIC :: PH_GTN_UMAT_Impl

  TYPE, PUBLIC, EXTENDS(MD_MatState) :: PH_Mat_GTN_State
    REAL(wp) :: peeq           = 0.0_wp
    REAL(wp) :: porosity       = 0.0_wp  ! f (void volume fraction)
    REAL(wp) :: ddsdde(6,6)    = 0.0_wp
    TYPE(ErrorStatusType) :: status
    LOGICAL :: converged = .TRUE.
    INTEGER(i4) :: iterations = 0_i4
  END TYPE PH_Mat_GTN_State

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: PH_Mat_GTN_Algo
    INTEGER(i4) :: ntens = 6_i4
    LOGICAL :: compute_tangent = .TRUE.
  END TYPE PH_Mat_GTN_Algo

  TYPE, PUBLIC :: PH_GTN_UMAT_Args
    LOGICAL     :: flag_nlgeom   = .FALSE.
    LOGICAL     :: flag_firstinc = .FALSE.
    INTEGER(i4) :: ip_index      = 0_i4
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success      = .FALSE.
    REAL(wp)              :: pnewdt       = 1.0_wp
    REAL(wp)              :: residual_norm = 0.0_wp
    INTEGER(i4)           :: iterations   = 0_i4
  END TYPE PH_GTN_UMAT_Args

CONTAINS

  SUBROUTINE PH_GTN_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, &
      MD_Mat, PH_Mat_Algo, RT_Com_Ctx, pnewdt)
    TYPE(MD_Mat_GTN_Desc),    INTENT(IN)    :: MD_Mat_Desc
    TYPE(PH_Mat_Krnl_Ctx),     INTENT(IN)    :: PH_Mat_Ctx
    TYPE(PH_Mat_GTN_State),    INTENT(INOUT) :: PH_Mat_State
    TYPE(PH_Mat_GTN_Algo), INTENT(IN) :: MD_Mat
    TYPE(PH_Mat_Krnl_Algo),   INTENT(IN)    :: PH_Mat_Algo
    TYPE(RT_Com_Base_Ctx),    INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                 INTENT(INOUT) :: pnewdt

    TYPE(PH_GTN_UMAT_Args) :: umat_args
    umat_args%flag_nlgeom   = RT_Com_Ctx%stp%nlgeom
    umat_args%flag_firstinc = RT_Com_Ctx%first_increment
    umat_args%ip_index      = RT_Com_Ctx%gauss_pt
    umat_args%success = .FALSE.

    CALL PH_GTN_UMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, &
        MD_Mat, PH_Mat_Algo, umat_args)
    pnewdt = umat_args%pnewdt
  END SUBROUTINE PH_GTN_UMAT_API

  !$UFC HOT_PATH
  SUBROUTINE PH_GTN_UMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, &
      MD_Mat, PH_Mat_Algo, args)
    TYPE(MD_Mat_GTN_Desc),    INTENT(IN)    :: MD_Mat_Desc
    TYPE(PH_Mat_Krnl_Ctx),    INTENT(IN)    :: PH_Mat_Ctx
    TYPE(PH_Mat_GTN_State),   INTENT(INOUT) :: PH_Mat_State
    TYPE(PH_Mat_GTN_Algo), INTENT(IN) :: MD_Mat
    TYPE(PH_Mat_Krnl_Algo),    INTENT(IN)    :: PH_Mat_Algo
    TYPE(PH_GTN_UMAT_Args),  INTENT(INOUT) :: args

    REAL(wp)    :: D_el(6,6), stress_trial(6), f_yield
    REAL(wp)    :: d_lambda, q_dev(6), p, q, f, f_star
    REAL(wp)    :: sigma_mises, phi_val
    INTEGER(i4)  :: it, ntens
    LOGICAL      :: map_ok

    CALL init_error_status(args%status)
    args%success = .FALSE.
    args%pnewdt  = RT_PNEWDT_NO_CHANGE
    ntens = MD_Mat%ntens
    IF (.NOT. ALLOCATED(PH_Mat_State%stress)) ALLOCATE(PH_Mat_State%stress(6))
    IF (.NOT. ALLOCATED(PH_Mat_State%strain)) ALLOCATE(PH_Mat_State%strain(6))

    IF (.NOT. MD_Mat_Desc%is_initialized) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[GTN_UMAT]: Desc not initialized'); RETURN
    END IF

    CALL GTN_Build_D_el(MD_Mat_Desc, D_el)
    stress_trial(1:ntens) = PH_Mat_State%stress(1:ntens) &
        + MATMUL(D_el(1:ntens,1:ntens), PH_Mat_Ctx%dstran(1:ntens))

    p = (stress_trial(1)+stress_trial(2)+stress_trial(3))/3.0_wp
    q_dev = stress_trial; q_dev(1)=q_dev(1)-p; q_dev(2)=q_dev(2)-p; q_dev(3)=q_dev(3)-p
    q = SQRT(1.5_wp*(q_dev(1)**2+q_dev(2)**2+q_dev(3)**2 &
             +2.0_wp*(q_dev(4)**2+q_dev(5)**2+q_dev(6)**2)))

    f = PH_Mat_State%porosity
    f_star = GTN_f_star(f, MD_Mat_Desc%fc, MD_Mat_Desc%fN, MD_Mat_Desc%q1, &
                        MD_Mat_Desc%q2, MD_Mat_Desc%q3, PH_Mat_State%peeq)

    phi_val = (q/MD_Mat_Desc%sigma_y0)**2 + 2.0_wp*f_star*MD_Mat_Desc%q1*COSH(q/(2.0_wp*MD_Mat_Desc%sigma_y0)) &
            - 1.0_wp - (MD_Mat_Desc%q1*f_star)**2
    f_yield = phi_val

    IF (f_yield <= 0.0_wp) THEN
      PH_Mat_State%stress(1:ntens) = stress_trial(1:ntens)
      IF (MD_Mat%compute_tangent) &
        PH_Mat_State%ddsdde(1:ntens,1:ntens) = D_el(1:ntens,1:ntens)
    ELSE
      map_ok = .TRUE.
      d_lambda = f_yield / (2.0_wp*MD_Mat_Desc%sigma_y0)
      d_lambda = MAX(d_lambda, 0.0_wp)

      PH_Mat_State%peeq = PH_Mat_State%peeq + d_lambda

      ! Porosity evolution (simplified)
      PH_Mat_State%porosity = f + (MD_Mat_Desc%fN + (f - MD_Mat_Desc%fN)* &
                  EXP(MD_Mat_Desc%q1*(PH_Mat_State%peeq - 0.0_wp))) * d_lambda
      PH_Mat_State%porosity = MAX(f, MIN(PH_Mat_State%porosity, 0.99_wp))

      args%iterations = 1
    END IF

    PH_Mat_State%strain(1:ntens) = PH_Mat_State%strain(1:ntens) + PH_Mat_Ctx%dstran(1:ntens)
    args%success = .TRUE.
    args%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_GTN_UMAT_Impl

  SUBROUTINE GTN_Build_D_el(desc, D)
    TYPE(MD_Mat_GTN_Desc), INTENT(IN)  :: desc
    REAL(wp),              INTENT(OUT) :: D(6,6)
    REAL(wp) :: lam, mu, nu_temp
    ! lambda = 2*G*nu / (1 - 2*nu)
    nu_temp = 0.3_wp
    IF (desc%E > 0.0_wp) nu_temp = desc%E / (2.0_wp * desc%G) - 1.0_wp
    lam = 2.0_wp * desc%G * nu_temp / (1.0_wp - 2.0_wp * nu_temp)
    mu = desc%G
    D = 0.0_wp
    D(1,1) = lam + 2.0_wp*mu; D(1,2) = lam; D(1,3) = lam
    D(2,1) = lam; D(2,2) = lam + 2.0_wp*mu; D(2,3) = lam
    D(3,1) = lam; D(3,2) = lam; D(3,3) = lam + 2.0_wp*mu
    D(4,4) = mu; D(5,5) = mu; D(6,6) = mu
  END SUBROUTINE GTN_Build_D_el

  PURE FUNCTION GTN_f_star(f, f_c, f_N, q1, q2, q3, eps_p) RESULT(f_star)
    REAL(wp), INTENT(IN) :: f, f_c, f_N, q1, q2, q3, eps_p
    REAL(wp) :: f_star
    IF (f <= f_c) THEN
      f_star = f
    ELSE
      f_star = f_c + (q1*f_c - f_c) * ((f - f_c)/(q1*f_c - f_c))**q2
    END IF
  END FUNCTION GTN_f_star

END MODULE PH_Mat_Damage_Gurson_Core

