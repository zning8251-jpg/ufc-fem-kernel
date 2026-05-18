!===============================================================================
! Module: MD_MatELATransIsotropic
! Layer:  L3_MD - Model Description Layer
! Domain: Material - Elastic (Transversely Isotropic, mat_id=103)
! Purpose: Descriptor type and input validation for transversely isotropic
!          elastic model with 5 independent parameters.
! Abaqus 6.14 / Leaf41: `*ELASTIC, TYPE=TRAVERSE ISOTROPIC` (E1,E2, nu12,nu23, G12) — **MD_MAT_ID_103** / **MAT_ELAS_TRANSV_ISO**.
! **W1**：**props** ↔ **Populate** / **`desc%props`**（文件头 **mat_id=103**；与 **`MD_Mat_Ids`** 对表）。
!
! Props layout (5 required):
!   props(1) = E1   : Young's modulus in fiber direction (direction 1)
!   props(2) = E2   : Young's modulus in transverse plane (directions 2,3)
!   props(3) = nu12 : Poisson's ratio (strain in 2 / strain in 1)
!   props(4) = nu23 : Poisson's ratio in transverse plane
!   props(5) = G12  : Shear modulus in 1-2 plane
!
! nProps_min = 5
! Statev: (1)=strain_energy_density
!===============================================================================
MODULE MD_Mat_Elas_TransIso
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_103
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_Elas_TransIso_Desc
  PUBLIC :: UF_TransIsoElastic_L3_ValidateProps
  PUBLIC :: UF_TransIsoElastic_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_TRANSISO = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_103 = MD_MAT_ID_103

  !> L3 descriptor for transversely isotropic elastic model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Elas_TransIso_Desc
    REAL(wp) :: E1 = 0.0_wp           ! Fiber direction Young's modulus
    REAL(wp) :: E2 = 0.0_wp           ! Transverse plane Young's modulus
    REAL(wp) :: nu12 = 0.0_wp         ! Major Poisson's ratio
    REAL(wp) :: nu23 = 0.0_wp         ! Transverse Poisson's ratio
    REAL(wp) :: G12 = 0.0_wp          ! In-plane shear modulus
    REAL(wp) :: G23 = 0.0_wp          ! Transverse shear modulus (computed)
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Elas_TransIso_Desc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_TransIsoElastic_L3_ValidateProps
  !   Validates flat props array for transversely isotropic elastic model.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_TransIsoElastic_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_TRANSISO) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "TransIsoElastic: need >=5 props (E1,E2,nu12,nu23,G12)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "TransIsoElastic: E1 must be > 0"
      RETURN
    END IF
    IF (props(2) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "TransIsoElastic: E2 must be > 0"
      RETURN
    END IF
    IF (props(5) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "TransIsoElastic: G12 must be > 0"
      RETURN
    END IF
    IF (props(3) <= -1.0_wp .OR. props(3) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "TransIsoElastic: nu12 must be in (-1,0.5)"
      RETURN
    END IF
    IF (props(4) <= -1.0_wp .OR. props(4) >= 0.5_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "TransIsoElastic: nu23 must be in (-1,0.5)"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_TransIsoElastic_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_TransIsoElastic_L3_InitFromProps
  !   Unpacks flat props array into a MD_Mat_Elas_TransIso_Desc instance.
  !   Computes G23 from E2 and nu23.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_TransIsoElastic_L3_InitFromProps(desc, nprops, props, st)
    TYPE(MD_Mat_Elas_TransIso_Desc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_TransIsoElastic_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%E1 = props(1)
    desc%E2 = props(2)
    desc%nu12 = props(3)
    desc%nu23 = props(4)
    desc%G12 = props(5)
    desc%G23 = desc%E2 / (2.0_wp * (1.0_wp + desc%nu23))
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_TransIsoElastic_L3_InitFromProps

END MODULE MD_Mat_Elas_TransIso

