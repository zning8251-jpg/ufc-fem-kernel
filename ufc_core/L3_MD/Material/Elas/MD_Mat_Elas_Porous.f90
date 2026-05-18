!===============================================================================
! Module: MD_MatELAPorous
! Layer:  L3_MD - Model Description Layer
! Domain: Material - Elastic (Porous, mat_id=105)
! Purpose: Descriptor type and input validation for porous elastic model
!          (crushable foam behavior with volumetric hardening).
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**105 / MD_MAT_ID_105**）。
!
! Props layout (5 required):
!   props(1) = E0        : Initial Young's modulus
!   props(2) = nu0       : Initial Poisson's ratio
!   props(3) = sigma_c0  : Initial uniaxial crush stress
!   props(4) = h         : Volumetric hardening parameter
!   props(5) = alpha     : Yield surface shape parameter
!
! nProps_min = 5
! Statev: (1)=eps_vol_pl (volumetric plastic strain),
!         (2)=sigma_c (current crush stress)
!===============================================================================
MODULE MD_Mat_Elas_Porous
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_105
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_Elas_Porous_Desc
  PUBLIC :: MD_Mat_Elas_Porous_L3_ValidateProps
  PUBLIC :: MD_Mat_Elas_Porous_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_POROUS = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_105 = MD_MAT_ID_105

  !> L3 descriptor for porous elastic model (crushable foam)
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Elas_Porous_Desc
    REAL(wp) :: E0 = 0.0_wp           ! Initial Young's modulus
    REAL(wp) :: nu0 = 0.0_wp          ! Initial Poisson's ratio
    REAL(wp) :: sigma_c0 = 0.0_wp     ! Initial crush stress
    REAL(wp) :: h = 0.0_wp            ! Hardening parameter
    REAL(wp) :: alpha = 0.0_wp        ! Yield surface shape parameter
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Elas_Porous_Desc

CONTAINS

  !----------------------------------------------------------------------------
  ! MD_Mat_Elas_Porous_L3_ValidateProps
  !   Validates flat props array for porous elastic model.
  !----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Porous_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_POROUS) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "PorousElastic: need >=5 props (E0,nu0,sigma_c0,h,alpha)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "PorousElastic: E0 must be > 0"
      RETURN
    END IF
    IF (props(2) <= -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "PorousElastic: nu0 must be in (-1,0.5)"
      RETURN
    END IF
    IF (props(3) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "PorousElastic: sigma_c0 must be > 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_Mat_Elas_Porous_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! MD_Mat_Elas_Porous_L3_InitFromProps
  !   Unpacks flat props array into a MD_Mat_Elas_Porous_Desc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Porous_L3_InitFromProps(desc, nprops, props, st)
    TYPE(MD_Mat_Elas_Porous_Desc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL MD_Mat_Elas_Porous_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%E0 = props(1)
    desc%nu0 = props(2)
    desc%sigma_c0 = props(3)
    desc%h = props(4)
    desc%alpha = props(5)
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_Mat_Elas_Porous_L3_InitFromProps

END MODULE MD_Mat_Elas_Porous

