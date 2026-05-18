!===============================================================================
! MODULE: PH_Mat_Acou_Linear_Core
! LAYER:  L4_PH
! DOMAIN: Material / Acoustic
! ROLE:   Core
! BRIEF:  Acoustic fluid constitutive model — pressure-volume strain relation
!===============================================================================
MODULE PH_Mat_Acou_Linear_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Acou_Def, ONLY: PH_Mat_Acou_Desc, PH_Mat_Acou_State
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Acoustic_Compute_Stress
  PUBLIC :: PH_Mat_Acoustic_Compute_Tangent
  PUBLIC :: PH_Mat_Acoustic_Update_State
  PUBLIC :: PH_Mat_Acoustic_Validate_Params

CONTAINS

  SUBROUTINE PH_Mat_Acoustic_Compute_Stress(mat_desc, strain, state, stress, ierr)
    TYPE(PH_Mat_Acou_Desc),  INTENT(IN)    :: mat_desc
    REAL(wp),                 INTENT(IN)    :: strain(6)
    TYPE(PH_Mat_Acou_State), INTENT(INOUT) :: state
    REAL(wp),                 INTENT(OUT)   :: stress(6)
    TYPE(ErrorStatusType),    INTENT(OUT)   :: ierr

    REAL(wp) :: eps_vol, pressure

    CALL init_error_status(ierr)
    eps_vol = strain(1) + strain(2) + strain(3)
    pressure = mat_desc%bulk_modulus * eps_vol

    stress(1) = pressure; stress(2) = pressure; stress(3) = pressure
    stress(4) = 0.0_wp; stress(5) = 0.0_wp; stress(6) = 0.0_wp
    state%pressure = pressure
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Acoustic_Compute_Stress

  SUBROUTINE PH_Mat_Acoustic_Compute_Tangent(mat_desc, strain, state, C_tangent, ierr)
    TYPE(PH_Mat_Acou_Desc),  INTENT(IN)  :: mat_desc
    REAL(wp),                 INTENT(IN)  :: strain(6)
    TYPE(PH_Mat_Acou_State), INTENT(IN)  :: state
    REAL(wp),                 INTENT(OUT) :: C_tangent(6,6)
    TYPE(ErrorStatusType),    INTENT(OUT) :: ierr

    REAL(wp) :: K_bulk
    CALL init_error_status(ierr)
    K_bulk = mat_desc%bulk_modulus
    C_tangent = 0.0_wp
    C_tangent(1,1) = K_bulk; C_tangent(1,2) = K_bulk; C_tangent(1,3) = K_bulk
    C_tangent(2,1) = K_bulk; C_tangent(2,2) = K_bulk; C_tangent(2,3) = K_bulk
    C_tangent(3,1) = K_bulk; C_tangent(3,2) = K_bulk; C_tangent(3,3) = K_bulk
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Acoustic_Compute_Tangent

  SUBROUTINE PH_Mat_Acoustic_Update_State(mat_desc, strain, state, ierr)
    TYPE(PH_Mat_Acou_Desc),  INTENT(IN)    :: mat_desc
    REAL(wp),                 INTENT(IN)    :: strain(6)
    TYPE(PH_Mat_Acou_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),    INTENT(OUT)   :: ierr
    REAL(wp) :: eps_vol
    CALL init_error_status(ierr)
    eps_vol = strain(1) + strain(2) + strain(3)
    state%pressure = mat_desc%bulk_modulus * eps_vol
    state%strain = strain
    state%initialized = .TRUE.
    state%num_evaluations = state%num_evaluations + 1
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Acoustic_Update_State

  SUBROUTINE PH_Mat_Acoustic_Validate_Params(mat_desc, ierr)
    TYPE(PH_Mat_Acou_Desc), INTENT(IN)  :: mat_desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: ierr
    CALL init_error_status(ierr)
    IF (mat_desc%bulk_modulus <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Acoustic]: bulk_modulus must be > 0'
      RETURN
    END IF
    IF (mat_desc%density <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Acoustic]: density must be > 0'
      RETURN
    END IF
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Acoustic_Validate_Params

END MODULE PH_Mat_Acou_Linear_Core
