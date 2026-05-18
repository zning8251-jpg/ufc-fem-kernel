!===============================================================================
! Module: MD_UsrUMAT
! Layer:  L3_MD - Model Description Layer
! Domain: Material / UserDefined / UMAT
! mat_id: 1101
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**1101**）；**USER_MATERIAL** / **`MD_MAT_USER_CORE`** / **L4 UMAT**。
!
! PURPOSE:
!   L3_MD descriptor for user-defined UMAT material.
!   Generic wrapper for custom constitutive models.
!===============================================================================
MODULE MD_Mat_User_UMAT_Simple
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_UsrUMAT_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 1_i4   ! At least 1 for nprops

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_UsrUMAT_Desc
    !-- User-defined parameters (passthrough)
    INTEGER(i4) :: n_user_props = 0_i4

    !-- User subroutine name (for reference)
    CHARACTER(LEN=64) :: subroutine_name = ''

    !-- User-defined flags
    INTEGER(i4) :: user_flags(10) = 0_i4
    REAL(wp) :: user_data(100) = 0.0_wp

    !-- Storage for original props
    REAL(wp), ALLOCATABLE :: props_store(:)

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_UsrUMAT_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_UsrUMAT_Desc), INTENT(IN)  :: self
    INTEGER(i4),              INTENT(IN)  :: nprops
    REAL(wp),               INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_UsrUMAT]: nprops must be >= 1"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_UsrUMAT_Desc), INTENT(INOUT) :: self
    INTEGER(i4),              INTENT(IN)    :: nprops
    REAL(wp),               INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: st

    INTEGER(i4) :: i

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    !-- Store user props count
    self%n_user_props = nprops

    !-- Copy all props for passthrough to user UMAT
    IF (ALLOCATED(self%props_store)) DEALLOCATE(self%props_store)
    ALLOCATE(self%props_store(nprops))
    self%props_store = props(1:nprops)

    !-- Copy first 100 values to user_data array
    DO i = 1, MIN(nprops, 100)
      self%user_data(i) = props(i)
    END DO

    self%cfg%matId = 1101_i4; self%class_id = 11_i4
    self%cfg%behavior = "User-Defined UMAT"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_User_UMAT_Simple