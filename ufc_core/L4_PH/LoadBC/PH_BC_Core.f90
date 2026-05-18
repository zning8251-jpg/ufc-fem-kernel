!===============================================================================
! MODULE:  PH_BC_Core
! LAYER:   L4_PH
! DOMAIN:  BC
! ROLE:    Core
! BRIEF:   BC computation kernels (Dirichlet penalty method).
!===============================================================================
MODULE PH_BC_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                         IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_BC_Core_Init
  PUBLIC :: PH_BC_Core_Finalize
  PUBLIC :: PH_BC_Apply_Dirichlet
  PUBLIC :: PH_BC_Apply_Dirichlet_CSR

CONTAINS

  SUBROUTINE PH_BC_Core_Init(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_BC_Core_Finalize(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_BC_Apply_Dirichlet(dof, value, big_num, K, F, status)
    INTEGER(i4), INTENT(IN) :: dof
    REAL(wp), INTENT(IN) :: value, big_num
    REAL(wp), INTENT(INOUT) :: K(:,:), F(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, ndof_k

    CALL init_error_status(status)
    ndof_k = SIZE(F)

    IF (dof < 1 .OR. dof > ndof_k) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO i = 1, ndof_k
      IF (i /= dof) THEN
        F(i) = F(i) - K(i, dof) * value
        K(i, dof) = 0.0_wp
        K(dof, i) = 0.0_wp
      END IF
    END DO

    K(dof, dof) = big_num
    F(dof) = big_num * value
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE PH_BC_Apply_Dirichlet_CSR(dof, value, big_num, K_csr, F, status)
    INTEGER(i4), INTENT(IN) :: dof
    REAL(wp), INTENT(IN) :: value, big_num
    TYPE(*), INTENT(INOUT) :: K_csr
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

END MODULE PH_BC_Core
