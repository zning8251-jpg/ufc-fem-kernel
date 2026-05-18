!===============================================================================
! Module: MD_UsrVUMAT
! Layer:  L3_MD - Model Description Layer
! Domain: Material / UserDefined / VUMAT
! mat_id: 1102
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**1102**）；**USER_MATERIAL** / **`MD_MAT_USER_CORE`** / **L4 VUMAT**。
!
! PURPOSE:
!   L3_MD descriptor for user-defined VUMAT (explicit dynamics).
!   Generic wrapper for custom rate-dependent models.
!===============================================================================
MODULE MD_Mat_User_VUMAT
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_UsrVUMAT_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 1_i4

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_UsrVUMAT_Desc
    INTEGER(i4) :: n_user_props = 0_i4
    CHARACTER(LEN=64) :: subroutine_name = ''
    INTEGER(i4) :: user_flags(10) = 0_i4
    REAL(wp) :: user_data(100) = 0.0_wp
    REAL(wp), ALLOCATABLE :: props_store(:)

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_UsrVUMAT_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_UsrVUMAT_Desc), INTENT(IN)  :: self
    INTEGER(i4),              INTENT(IN)  :: nprops
    REAL(wp),               INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_UsrVUMAT_Desc), INTENT(INOUT) :: self
    INTEGER(i4),              INTENT(IN)    :: nprops
    REAL(wp),               INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: st

    INTEGER(i4) :: i

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%n_user_props = nprops
    IF (ALLOCATED(self%props_store)) DEALLOCATE(self%props_store)
    ALLOCATE(self%props_store(nprops))
    self%props_store = props(1:nprops)

    DO i = 1, MIN(nprops, 100)
      self%user_data(i) = props(i)
    END DO

    self%cfg%matId = 1102_i4; self%class_id = 11_i4
    self%cfg%behavior = "User-Defined VUMAT"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_User_VUMAT