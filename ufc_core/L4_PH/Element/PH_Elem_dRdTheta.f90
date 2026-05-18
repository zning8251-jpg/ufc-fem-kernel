!===============================================================================
! MODULE: PH_Elem_dRdTheta
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  ABSTRACT INTERFACE for element-level residual sensitivity
!===============================================================================
MODULE PH_Elem_dRdTheta
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! Gradient method enumeration
  !============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_GRAD_NONE     = 0
  INTEGER(i4), PARAMETER, PUBLIC :: PH_GRAD_FD       = 1
  INTEGER(i4), PARAMETER, PUBLIC :: PH_GRAD_ANALYTIC = 2
  INTEGER(i4), PARAMETER, PUBLIC :: PH_GRAD_AD       = 3

  !============================================================================
  ! PH_Elem_DiffPhys_Desc — per-element differentiability configuration
  !============================================================================
  TYPE, PUBLIC :: PH_Elem_DiffPhys_Desc
    LOGICAL     :: enabled        = .FALSE.
    INTEGER(i4) :: grad_method    = PH_GRAD_NONE
    REAL(wp)    :: fd_perturbation = 1.0E-7_wp
    INTEGER(i4) :: n_theta        = 0
  END TYPE PH_Elem_DiffPhys_Desc

  !============================================================================
  ! Abstract interface: element residual sensitivity dR_e/dtheta
  !============================================================================
  ABSTRACT INTERFACE
    SUBROUTINE PH_Elem_dRdTheta_Interface( &
        config, &
        coords, u_elem, theta, n_theta, &
        dRdtheta, status)
      IMPORT :: wp, i4, PH_Elem_DiffPhys_Desc, ErrorStatusType
      TYPE(PH_Elem_DiffPhys_Desc), INTENT(IN) :: config
      REAL(wp), INTENT(IN)  :: coords(:,:)
      REAL(wp), INTENT(IN)  :: u_elem(:)
      REAL(wp), INTENT(IN)  :: theta(:)
      INTEGER(i4), INTENT(IN) :: n_theta
      REAL(wp), INTENT(OUT) :: dRdtheta(:,:)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
    END SUBROUTINE PH_Elem_dRdTheta_Interface
  END INTERFACE

  PUBLIC :: PH_Elem_dRdTheta_FD

CONTAINS

  !============================================================================
  ! PH_Elem_dRdTheta_FD — Tier 1: Finite difference fallback
  !============================================================================
  SUBROUTINE PH_Elem_dRdTheta_FD( &
      config, &
      coords, u_elem, theta, n_theta, &
      dRdtheta, status)
    TYPE(PH_Elem_DiffPhys_Desc), INTENT(IN) :: config
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: u_elem(:)
    REAL(wp), INTENT(IN)  :: theta(:)
    INTEGER(i4), INTENT(IN) :: n_theta
    REAL(wp), INTENT(OUT) :: dRdtheta(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    dRdtheta = 0.0_wp

    status%code = IF_STATUS_ERROR
    status%message = 'PH_Elem_dRdTheta_FD: STUB — FD gradient not yet implemented'

  END SUBROUTINE PH_Elem_dRdTheta_FD

END MODULE PH_Elem_dRdTheta
