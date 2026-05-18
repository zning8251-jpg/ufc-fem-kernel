!===============================================================================
! Module: MD_ElaAniso
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Elastic / General Anisotropic Linear Elasticity
! mat_id: 103
!
! PURPOSE:
!   L3_MD descriptor for general anisotropic linear elastic material.
!   21 independent elastic constants in reduced Voigt notation.
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；**UF_Elastic_Eval_Dispatch_FromDesc** / L4 线弹性读 **`desc%props`**（**103**）。
!===============================================================================
MODULE MD_Mat_Elas_Aniso
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Elas_Aniso_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 21_i4  ! Full anisotropic stiffness matrix

  !> L3 descriptor for general anisotropic linear elastic material.
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Elas_Aniso_Desc
    !-- Primary material parameters (21 independent stiffness components)
    !   Voigt order: C11,C12,C13,C14,C15,C16,C22,C23,C24,C25,C26,
    !                C33,C34,C35,C36,C44,C45,C46,C55,C56,C66
    REAL(wp) :: C(21) = 0.0_wp   ! Stiffness components [Pa]

    !-- Density
    REAL(wp) :: rho = 0.0_wp    ! Mass density [kg/m3]

    !-- Derived: symmetry check flag
    LOGICAL :: is_symmetric = .FALSE.

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_Elas_Aniso_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_Elas_Aniso_Desc), INTENT(IN)  :: self
    INTEGER(i4),              INTENT(IN)  :: nprops
    REAL(wp),               INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT) :: st

    INTEGER(i4) :: i

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_ElaAniso]: nprops must be >= 21 for full anisotropic"
      RETURN
    END IF

    !-- Positive diagonal stiffness components
    DO i = 1, 6
      IF (props(i + (i-1)*3 - MERGE(0,(i-1),i>3)) <= 0.0_wp) THEN
        st%status_code = STATUS_INVALID
        st%message = "[MD_ElaAniso]: Positive definite stiffness required"
        RETURN
      END IF
    END DO

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_Elas_Aniso_Desc), INTENT(INOUT) :: self
    INTEGER(i4),              INTENT(IN)    :: nprops
    REAL(wp),               INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: st

    INTEGER(i4) :: i

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    !-- Store stiffness components
    DO i = 1, 21
      self%C(i) = props(i)
    END DO

    !-- Optional: density
    IF (nprops >= 22) self%rho = props(22)

    !-- Check symmetry: Cij = Cji for i,j <= 6
    !   For standard anisotropic: C(2)=C12, C(3)=C13, etc.
    !   Symmetric if: C12=C21, C13=C31, C23=C32, C14=C41, etc.
    self%is_symmetric = .TRUE.   ! Assumed symmetric

    !-- Identification (via MD_Mat_Desc inherited fields)
    self%cfg%matId      = 103_i4
    self%class_id       = 1_i4   ! MD_MAT_CATEGORY_EL
    self%cfg%behavior   = "General Anisotropic Linear Elastic"
    self%is_initialized = .TRUE.
    st%status_code   = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Elas_Aniso