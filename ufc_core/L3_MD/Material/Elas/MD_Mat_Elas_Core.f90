!===============================================================================
! MODULE: MD_Mat_Elas_Core
! LAYER:  L3_MD
! DOMAIN: Material / Elas
! ROLE:   Core
! BRIEF:  Core implementation for elastic material family.
!         Provides initialization, validation, registration, and utility functions.
!
!         Three-level nesting validation and ABAQUS keyword mapping.
!         Single source of truth for elastic material definitions.
!===============================================================================
MODULE MD_Mat_Elas_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Elas_Def, ONLY: MD_Mat_Elas_Desc, &
                              MD_Mat_Elas_State, &
                              MD_Mat_Elas_Algo, &
                              MD_Mat_Elas_Ctx
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_ELASTIC, &
                                MD_MAT_ELAS_SUB_ISO, &
                                MD_MAT_ELAS_SUB_ORTHO, &
                                MD_MAT_ELAS_SUB_TRANSISO, &
                                MD_MAT_ELAS_SUB_ANISO, &
                                MD_MAT_ELAS_SUB_POROUS, &
                                MD_MAT_ELAS_SUB_HYPO, &
                                MD_MAT_ELAS_SUB_SHEAR, &
                                MD_MAT_ELAS_SUB_ENGINEERING
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Elas_Create_From_Props
  PUBLIC :: MD_Mat_Elas_Create_Isotropic
  PUBLIC :: MD_Mat_Elas_Create_Orthotropic
  PUBLIC :: MD_Mat_Elas_Create_Anisotropic
  PUBLIC :: MD_Mat_Elas_Parse_ABAQUS_Keyword
  PUBLIC :: MD_Mat_Elas_Register

CONTAINS

  !-----------------------------------------------------------------------------
  ! MD_Mat_Elas_Create_From_Props
  ! Create elastic material descriptor from flat props array
  ! Spatial: - | Temporal: Init | Action: Create
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Create_From_Props(desc, sub_type, nprops, props, &
                                            dependencies, status)
    TYPE(MD_Mat_Elas_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: deps, i, j

    CALL init_error_status(status)

    deps = 0
    IF (PRESENT(dependencies)) deps = dependencies

    ! Initialize descriptor via TBP
    CALL desc%Init(sub_type, nprops, deps, status)
    IF (status%status_code /= 0) RETURN

    ! Copy material constants
    DO i = 1, nprops
      desc%constants(i, 1) = props(i)
    END DO

    ! Compute derived parameters via TBP
    CALL desc%ComputeDerived(status)
    IF (status%status_code /= 0) RETURN

    ! Validate via TBP
    CALL desc%Valid(status)
  END SUBROUTINE MD_Mat_Elas_Create_From_Props

  !-----------------------------------------------------------------------------
  ! MD_Mat_Elas_Create_Isotropic
  ! Convenience function for creating isotropic elastic material
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Create_Isotropic(desc, E, nu, status)
    TYPE(MD_Mat_Elas_Desc), INTENT(INOUT) :: desc
    REAL(wp), INTENT(IN) :: E, nu
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: props(2)
    props(1) = E
    props(2) = nu
    CALL MD_Mat_Elas_Create_From_Props(desc, MD_MAT_ELAS_SUB_ISO, 2, props, status=status)
  END SUBROUTINE MD_Mat_Elas_Create_Isotropic

  !-----------------------------------------------------------------------------
  ! MD_Mat_Elas_Create_Orthotropic
  ! Convenience function for creating orthotropic elastic material
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Create_Orthotropic(desc, E11, E22, E33, &
                                             nu12, nu13, nu23, &
                                             G12, G13, G23, status)
    TYPE(MD_Mat_Elas_Desc), INTENT(INOUT) :: desc
    REAL(wp), INTENT(IN) :: E11, E22, E33, nu12, nu13, nu23, G12, G13, G23
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: props(9)
    props(1) = E11; props(2) = E22; props(3) = E33
    props(4) = nu12; props(5) = nu13; props(6) = nu23
    props(7) = G12; props(8) = G13; props(9) = G23
    CALL MD_Mat_Elas_Create_From_Props(desc, MD_MAT_ELAS_SUB_ORTHO, 9, props, status=status)
  END SUBROUTINE MD_Mat_Elas_Create_Orthotropic

  !-----------------------------------------------------------------------------
  ! MD_Mat_Elas_Create_Anisotropic
  ! Convenience function for creating anisotropic elastic material
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Create_Anisotropic(desc, C_props, status)
    TYPE(MD_Mat_Elas_Desc), INTENT(INOUT) :: desc
    REAL(wp), INTENT(IN) :: C_props(21)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL MD_Mat_Elas_Create_From_Props(desc, MD_MAT_ELAS_SUB_ANISO, 21, C_props, status=status)
  END SUBROUTINE MD_Mat_Elas_Create_Anisotropic

  !-----------------------------------------------------------------------------
  ! MD_Mat_Elas_Parse_ABAQUS_Keyword
  ! Parse ABAQUS *Elastic keyword parameters
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Parse_ABAQUS_Keyword(desc, keyword_params, &
                                               num_params, status)
    TYPE(MD_Mat_Elas_Desc), INTENT(INOUT) :: desc
    CHARACTER(LEN=*), INTENT(IN) :: keyword_params(:)
    INTEGER(i4), INTENT(IN) :: num_params
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, sub_type, deps
    CHARACTER(LEN=64) :: type_str

    CALL init_error_status(status)

    sub_type = MD_MAT_ELAS_SUB_ISO  ! Default
    type_str = "ISOTROPIC"
    deps = 0

    ! Parse keyword parameters
    DO i = 1, num_params
      IF (keyword_params(i) == "TYPE=ISOTROPIC") THEN
        sub_type = MD_MAT_ELAS_SUB_ISO
      ELSE IF (keyword_params(i) == "TYPE=ORTHOTROPIC") THEN
        sub_type = MD_MAT_ELAS_SUB_ORTHO
      ELSE IF (keyword_params(i) == "TYPE=ANISOTROPIC") THEN
        sub_type = MD_MAT_ELAS_SUB_ANISO
      ELSE IF (keyword_params(i) == "TYPE=ENGINEERING") THEN
        sub_type = MD_MAT_ELAS_SUB_ENGINEERING
      ELSE IF (INDEX(keyword_params(i), "DEPENDENCIES=") > 0) THEN
        READ(keyword_params(i)(13:), *) deps
      END IF
    END DO

    CALL desc%Init(sub_type, 0, deps, status)
  END SUBROUTINE MD_Mat_Elas_Parse_ABAQUS_Keyword

  !-----------------------------------------------------------------------------
  ! MD_Mat_Elas_Register
  ! Register elastic material in the global material registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Elas_Register(desc, mat_id, status)
    TYPE(MD_Mat_Elas_Desc), INTENT(IN) :: desc
    INTEGER(i4), INTENT(OUT) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ! Placeholder: delegate to MD_Mat_Reg
    mat_id = 1
    status%status_code = 0
  END SUBROUTINE MD_Mat_Elas_Register

END MODULE MD_Mat_Elas_Core