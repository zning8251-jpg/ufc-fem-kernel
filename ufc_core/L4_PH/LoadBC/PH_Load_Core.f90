!===============================================================================
! MODULE:  PH_Load_Core
! LAYER:   L4_PH
! DOMAIN:  Load
! ROLE:    Core
! BRIEF:   Load computation kernels + GeostaticAlgo merged.
!===============================================================================
MODULE PH_Load_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                         IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Load_Core_Init
  PUBLIC :: PH_Load_Core_Finalize
  PUBLIC :: PH_Load_Concentrated_Force
  PUBLIC :: PH_Load_Distributed_Load
  PUBLIC :: PH_Load_Pressure_Load
  PUBLIC :: PH_Load_Body_Force
  PUBLIC :: PH_Load_Gravity_Load
  PUBLIC :: PH_Load_Thermal_Load
  PUBLIC :: PH_Load_K0Assign
  PUBLIC :: PH_Load_GravityForce
  PUBLIC :: PH_Geostatic_Algo_Args

  TYPE, PUBLIC :: PH_Geostatic_Algo_Args
    INTEGER(i4) :: n_node = 0_i4
    INTEGER(i4) :: n_dof = 0_i4
    INTEGER(i4) :: n_ip = 0_i4
    INTEGER(i4) :: load_type = 0_i4
    INTEGER(i4) :: ctype = 0_i4
    INTEGER(i4) :: idof = 0_i4
    INTEGER(i4) :: face_id = 0_i4
    REAL(wp) :: xi = 0.0_wp
    REAL(wp) :: eta = 0.0_wp
    REAL(wp) :: zeta = 0.0_wp
    REAL(wp) :: penalty = 0.0_wp
    REAL(wp) :: val = 0.0_wp
    REAL(wp) :: tol = 1.0e-12_wp
    REAL(wp), POINTER :: coords(:,:) => NULL()
    REAL(wp), POINTER :: u_elem(:) => NULL()
    REAL(wp), POINTER :: D(:,:) => NULL()
    REAL(wp), POINTER :: Ke(:,:) => NULL()
    REAL(wp), POINTER :: F_eq(:) => NULL()
    REAL(wp), POINTER :: state(:) => NULL()
    REAL(wp), POINTER :: stress(:) => NULL()
    REAL(wp), POINTER :: strain(:) => NULL()
    REAL(wp), POINTER :: F_def(:,:) => NULL()
    REAL(wp), POINTER :: R_int(:) => NULL()
  END TYPE

CONTAINS

  SUBROUTINE PH_Load_Core_Init(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_Load_Core_Finalize(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_Load_Concentrated_Force(value, amp_factor, dof, F_vec, status)
    REAL(wp), INTENT(IN) :: value, amp_factor
    INTEGER(i4), INTENT(IN) :: dof
    REAL(wp), INTENT(INOUT) :: F_vec(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (dof >= 1 .AND. dof <= SIZE(F_vec)) THEN
      F_vec(dof) = F_vec(dof) + value * amp_factor
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_Load_Distributed_Load(nn, ndof_per_node, dof_dir, N_shape, &
                                       value, area, Fe, status)
    INTEGER(i4), INTENT(IN) :: nn, ndof_per_node, dof_dir
    REAL(wp), INTENT(IN) :: N_shape(:), value, area
    REAL(wp), INTENT(INOUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, idx

    CALL init_error_status(status)
    Fe = 0.0_wp
    DO i = 1, nn
      idx = (i - 1) * ndof_per_node + dof_dir
      Fe(idx) = N_shape(i) * value * area
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_Load_Pressure_Load(nn, ndof_per_node, pressure, N_shape, &
                                    normal, area, Fe, status)
    INTEGER(i4), INTENT(IN) :: nn, ndof_per_node
    REAL(wp), INTENT(IN) :: pressure, N_shape(:), normal(:), area
    REAL(wp), INTENT(INOUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, j, idx

    CALL init_error_status(status)
    Fe = 0.0_wp
    DO i = 1, nn
      DO j = 1, MIN(3, ndof_per_node)
        idx = (i - 1) * ndof_per_node + j
        Fe(idx) = -pressure * N_shape(i) * normal(j) * area
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_Load_Body_Force(nn, ndof_per_node, N_shape, body_force, &
                                 volume, Fe, status)
    INTEGER(i4), INTENT(IN) :: nn, ndof_per_node
    REAL(wp), INTENT(IN) :: N_shape(:), body_force(:), volume
    REAL(wp), INTENT(INOUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, j, idx

    CALL init_error_status(status)
    Fe = 0.0_wp
    DO i = 1, nn
      DO j = 1, MIN(3, ndof_per_node)
        idx = (i - 1) * ndof_per_node + j
        Fe(idx) = N_shape(i) * body_force(j) * volume
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_Load_Gravity_Load(nn, ndof_per_node, N_shape, rho, g_vec, &
                                   volume, Fe, status)
    INTEGER(i4), INTENT(IN) :: nn, ndof_per_node
    REAL(wp), INTENT(IN) :: N_shape(:), rho, g_vec(:), volume
    REAL(wp), INTENT(INOUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: bf(3)

    bf = rho * g_vec
    CALL PH_Load_Body_Force(nn, ndof_per_node, N_shape, bf, volume, Fe, &
                            status)
  END SUBROUTINE

  SUBROUTINE PH_Load_Thermal_Load(D_mat, eps_th, ndof, volume, Fe, status)
    REAL(wp), INTENT(IN) :: D_mat(:,:), eps_th(:), volume
    INTEGER(i4), INTENT(IN) :: ndof
    REAL(wp), INTENT(INOUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: sigma_th(6)
    INTEGER(i4) :: i, j

    CALL init_error_status(status)
    sigma_th = 0.0_wp
    DO i = 1, 6
      DO j = 1, 6
        sigma_th(i) = sigma_th(i) + D_mat(i, j) * eps_th(j)
      END DO
    END DO
    Fe = 0.0_wp
    IF (ndof >= 6) THEN
      DO i = 1, 6
        Fe(i) = -sigma_th(i) * volume
      END DO
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_Load_K0Assign(k0, rho, g_z, gauss_z, n_gauss, sigma0, status)
    REAL(wp), INTENT(IN) :: k0, rho, g_z, gauss_z(:)
    INTEGER(i4), INTENT(IN) :: n_gauss
    REAL(wp), INTENT(OUT) :: sigma0(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ig
    REAL(wp) :: depth, sv, sh

    CALL init_error_status(status)
    IF (SIZE(sigma0, 1) < 6 .OR. SIZE(sigma0, 2) < n_gauss) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (SIZE(gauss_z) < n_gauss) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO ig = 1, n_gauss
      depth = -gauss_z(ig)
      sv = -rho * g_z * depth
      sh = k0 * sv
      sigma0(1, ig) = sh
      sigma0(2, ig) = sh
      sigma0(3, ig) = sv
      sigma0(4:6, ig) = 0.0_wp
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_Load_GravityForce(rho, g_vec, n_dof, F_grav, status)
    REAL(wp), INTENT(IN) :: rho, g_vec(3)
    INTEGER(i4), INTENT(IN) :: n_dof
    REAL(wp), INTENT(OUT) :: F_grav(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (SIZE(F_grav) < n_dof) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    F_grav = 0.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

END MODULE PH_Load_Core
