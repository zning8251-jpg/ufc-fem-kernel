!===============================================================================
! Module: MD_MatELAOrthotropic
! Layer:  L3_MD - Model Description Layer
! Domain: Material - Elastic (Orthotropic, mat_id=102)
! Purpose: Descriptor type and input validation for orthotropic linear
!          elastic model with 9 independent parameters.
! Abaqus 6.14 / Leaf41: `*ELASTIC, TYPE=ENGINEERING CONSTANTS` (9 props: E1,E2,E3, nu12,nu13,nu23, G12,G13,G23) —
!   **MD_MAT_ID_102** / **MAT_ELAS_ORTHO**.
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**102 / MD_MAT_ID_102**）。
!
! Props layout (9 required):
!   props(1) = MD_MAT_E_11      : Young's modulus in direction 1
!   props(2) = MD_MAT_E_22      : Young's modulus in direction 2
!   props(3) = MD_MAT_E_33      : Young's modulus in direction 3
!   props(4) = nu_12     : Poisson's ratio (strain in 2 / strain in 1)
!   props(5) = nu_13     : Poisson's ratio (strain in 3 / strain in 1)
!   props(6) = nu_23     : Poisson's ratio (strain in 3 / strain in 2)
!   props(7) = G_12      : Shear modulus in plane 1-2
!   props(8) = G_13      : Shear modulus in plane 1-3
!   props(9) = G_23      : Shear modulus in plane 2-3
!
! nProps_min = 9
! Statev: (1)=strain_energy_density
!===============================================================================
MODULE MD_Mat_Elas_Ortho
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_102
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_Elas_Ortho_Desc
  PUBLIC :: MD_Mat_Elas_Ortho_L3_ValidateProps
  PUBLIC :: MD_Mat_Elas_Ortho_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_ORTHO = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_102 = MD_MAT_ID_102

  !> L3 descriptor for orthotropic linear elastic model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Elas_Ortho_Desc
    REAL(wp) :: E(3) = 0.0_wp           ! Young's moduli (E1, E2, E3)
    REAL(wp) :: nu(3,3) = 0.0_wp        ! Poisson's ratios (nu_ij)
    REAL(wp) :: G(3) = 0.0_wp           ! Shear moduli (G12, G13, G23)
    REAL(wp) :: C(6,6) = 0.0_wp         ! Stiffness matrix
    REAL(wp) :: S(6,6) = 0.0_wp         ! Compliance matrix
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Elas_Ortho_Desc

CONTAINS

  !----------------------------------------------------------------------------
  ! MD_Mat_Elas_Ortho_L3_ValidateProps
  !   Validates flat props array for orthotropic elastic model.
  !----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Ortho_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_ORTHO) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "OrthoElastic: need >=9 props (E1,E2,E3,nu12,nu13,nu23,G12,G13,G23)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp .OR. props(2) <= 0.0_wp .OR. props(3) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "OrthoElastic: E1, E2, E3 must be > 0"
      RETURN
    END IF
    IF (props(7) <= 0.0_wp .OR. props(8) <= 0.0_wp .OR. props(9) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "OrthoElastic: G12, G13, G23 must be > 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_Mat_Elas_Ortho_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! MD_Mat_Elas_Ortho_L3_InitFromProps
  !   Unpacks flat props array into a MD_Mat_Elas_Ortho_Desc instance.
  !   Computes compliance matrix S and stiffness matrix C.
  !----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Ortho_L3_InitFromProps(desc, nprops, props, st)
    TYPE(MD_Mat_Elas_Ortho_Desc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    REAL(wp) :: nu21, nu31, nu32, delta
    CALL MD_Mat_Elas_Ortho_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%E(1) = props(1)
    desc%E(2) = props(2)
    desc%E(3) = props(3)
    desc%nu(1,2) = props(4)
    desc%nu(1,3) = props(5)
    desc%nu(2,3) = props(6)
    desc%G(1) = props(7)
    desc%G(2) = props(8)
    desc%G(3) = props(9)
    nu21 = desc%nu(1,2) * desc%E(2) / desc%E(1)
    nu31 = desc%nu(1,3) * desc%E(3) / desc%E(1)
    nu32 = desc%nu(2,3) * desc%E(3) / desc%E(2)
    desc%nu(2,1) = nu21
    desc%nu(3,1) = nu31
    desc%nu(3,2) = nu32
    delta = 1.0_wp - desc%nu(1,2)*nu21 - desc%nu(1,3)*nu31 - desc%nu(2,3)*nu32 - &
            2.0_wp*desc%nu(1,2)*desc%nu(2,3)*nu31
    IF (delta <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "OrthoElastic: Mat constants violate stability condition"
      RETURN
    END IF
    desc%S = 0.0_wp
    desc%S(1,1) = 1.0_wp / desc%E(1)
    desc%S(2,2) = 1.0_wp / desc%E(2)
    desc%S(3,3) = 1.0_wp / desc%E(3)
    desc%S(4,4) = 1.0_wp / desc%G(1)
    desc%S(5,5) = 1.0_wp / desc%G(2)
    desc%S(6,6) = 1.0_wp / desc%G(3)
    desc%S(1,2) = -desc%nu(1,2) / desc%E(1)
    desc%S(2,1) = -nu21 / desc%E(2)
    desc%S(1,3) = -desc%nu(1,3) / desc%E(1)
    desc%S(3,1) = -nu31 / desc%E(3)
    desc%S(2,3) = -desc%nu(2,3) / desc%E(2)
    desc%S(3,2) = -nu32 / desc%E(3)
    CALL Invert6x6(desc%S, desc%C)
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_Mat_Elas_Ortho_L3_InitFromProps

CONTAINS

  !----------------------------------------------------------------------------
  ! Invert6x6: Invert 6x6 symmetric compliance matrix to get stiffness matrix
  !----------------------------------------------------------------------------
  SUBROUTINE Invert6x6(S, D)
    REAL(wp), INTENT(IN)  :: S(6,6)
    REAL(wp), INTENT(OUT) :: D(6,6)
    REAL(wp) :: S33(3,3), D33(3,3)
    D = 0.0_wp
    S33(1:3,1:3) = S(1:3,1:3)
    CALL Invert3x3(S33, D33)
    D(1:3,1:3) = D33
    IF (S(4,4) > 1.0e-30_wp) THEN
      D(4,4) = 1.0_wp / S(4,4)
    END IF
    IF (S(5,5) > 1.0e-30_wp) THEN
      D(5,5) = 1.0_wp / S(5,5)
    END IF
    IF (S(6,6) > 1.0e-30_wp) THEN
      D(6,6) = 1.0_wp / S(6,6)
    END IF
  END SUBROUTINE Invert6x6

  !----------------------------------------------------------------------------
  ! Invert3x3: Invert 3x3 matrix using analytical formula
  !----------------------------------------------------------------------------
  SUBROUTINE Invert3x3(A, Ainv)
    REAL(wp), INTENT(IN)  :: A(3,3)
    REAL(wp), INTENT(OUT) :: Ainv(3,3)
    REAL(wp) :: det
    det = A(1,1)*(A(2,2)*A(3,3) - A(2,3)*A(3,2)) - &
          A(1,2)*(A(2,1)*A(3,3) - A(2,3)*A(3,1)) + &
          A(1,3)*(A(2,1)*A(3,2) - A(2,2)*A(3,1))
    IF (ABS(det) < 1.0e-30_wp) THEN
      det = 1.0_wp
    END IF
    Ainv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) / det
    Ainv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) / det
    Ainv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) / det
    Ainv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) / det
    Ainv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) / det
    Ainv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) / det
    Ainv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) / det
    Ainv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) / det
    Ainv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) / det
  END SUBROUTINE Invert3x3

END MODULE MD_Mat_Elas_Ortho

