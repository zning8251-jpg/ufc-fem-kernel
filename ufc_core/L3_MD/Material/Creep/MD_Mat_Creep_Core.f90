!===============================================================================
! MODULE: MD_Mat_Creep_Core
! LAYER:  L3_MD
! DOMAIN: Material / Creep
! ROLE:   Core
! BRIEF:  Core implementation for creep material family.
!         Provides initialization, validation, registration, and utility functions.
!         Updated for Phase 3 Stage 1: Template promotion with temperature/field 
!         dependency and density support.
!
!         Design principle:
!         - Single source of truth (SSOT) for creep material definitions
!         - Three-level nesting validation
!         - ABAQUS keyword parsing and mapping
!         - Temperature/field variable dependency support
!===============================================================================
MODULE MD_Mat_Creep_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Creep_Def, ONLY: MD_Mat_Creep_Desc, &
                              MD_Mat_Creep_State, &
                              MD_Mat_Creep_Algo, &
                              MD_Mat_Creep_Ctx, &
                              MD_Mat_Creep_Desc_Init, &
                              MD_Mat_Creep_Desc_Validate, &
                              MD_Mat_Creep_Desc_ComputeDerived
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_CREEP, &
                               MD_MAT_CREEP_SUB_POWER, &
                               MD_MAT_CREEP_SUB_USER, &
                               MD_MAT_CREEP_SUB_TWO_LAYER, &
                               MD_MAT_CREEP_SUB_ANNEAL, &
                               MD_MAT_CREEP_SUB_GAROFALO, &
                               MD_MAT_CREEP_SUB_PERZYNA, &
                               MD_MAT_CREEP_SUB_DUVAUT, &
                               MD_MAT_CREEP_SUB_BODNER

  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Creep_Create_From_Props
  PUBLIC :: MD_Mat_Creep_Parse_ABAQUS_Keyword
  PUBLIC :: MD_Mat_Creep_Register

CONTAINS

  !-----------------------------------------------------------------------------
  ! [OUT] desc: Material descriptor to populate
  ! [IN] sub_type: Creep sub-type
  ! [IN] nprops: Number of properties per data point
  ! [IN] props: Flat array of properties
  ! [IN] dependencies: 0=none, 1=temp, 2=field
  ! [OUT] status: Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Creep_Create_From_Props(desc, sub_type, nprops, props, &
                                            dependencies, status)
    TYPE(MD_Mat_Creep_Desc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, deps

    CALL init_error_status(status)

    ! Determine dependencies
    deps = 0
    IF (PRESENT(dependencies)) deps = dependencies

    ! Initialize descriptor
    CALL MD_Mat_Creep_Desc_Init(desc, sub_type, nprops, deps, status)
    IF (status%status_code /= 0) RETURN

    ! Copy material constants
    IF (deps > 0) THEN
      ! Temperature/field dependent: props array layout is
      ! [const1_ref, const2_ref, ..., constN_ref, temp1/field1, const1_t1, const2_t1, ...]
      DO i = 1, nprops
        desc%constants(i, 1) = props(i)
      END DO
      ! Additional temperature/field points would be handled by interpolation module
    ELSE
      ! No dependencies: simple copy
      DO i = 1, nprops
        desc%constants(i, 1) = props(i)
      END DO
    END IF

    ! Compute derived parameters
    CALL MD_Mat_Creep_Desc_ComputeDerived(desc, status)
    IF (status%status_code /= 0) RETURN

    ! Validate
    CALL MD_Mat_Creep_Desc_Validate(desc, status)
  END SUBROUTINE MD_Mat_Creep_Create_From_Props

  !-----------------------------------------------------------------------------
  ! [OUT] desc: Material descriptor to populate
  ! [IN] keyword_type: ABAQUS creep law type string
  ! [IN] nprops: Number of properties
  ! [IN] props: Properties array
  ! [IN] dependencies: 0=none, 1=temp, 2=field
  ! [OUT] status: Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Creep_Parse_ABAQUS_Keyword(desc, keyword_type, &
                                               nprops, props, &
                                               dependencies, status)
    TYPE(MD_Mat_Creep_Desc), INTENT(OUT) :: desc
    CHARACTER(LEN=*), INTENT(IN) :: keyword_type
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: sub_type

    CALL init_error_status(status)

    ! Map ABAQUS keyword TYPE parameter to sub_type
    SELECT CASE (TRIM(keyword_type))
    CASE ("STRAIN", "TIME", "POWER")
      sub_type = MD_MAT_CREEP_SUB_POWER
    CASE ("USER")
      sub_type = MD_MAT_CREEP_SUB_USER
    CASE ("ANNEAL")
      sub_type = MD_MAT_CREEP_SUB_ANNEAL
    CASE ("GAROFALO")
      sub_type = MD_MAT_CREEP_SUB_GAROFALO
    CASE ("PERZYNA")
      sub_type = MD_MAT_CREEP_SUB_PERZYNA
    CASE ("BODNER")
      sub_type = MD_MAT_CREEP_SUB_BODNER
    CASE DEFAULT
      status%status_code = 1
      status%message = "Unknown ABAQUS creep TYPE: " // TRIM(keyword_type)
      RETURN
    END SELECT

    ! Create material descriptor
    CALL MD_Mat_Creep_Create_From_Props(desc, sub_type, nprops, props, &
                                       dependencies, status)
  END SUBROUTINE MD_Mat_Creep_Parse_ABAQUS_Keyword

  !-----------------------------------------------------------------------------
  ! [IN] desc: Material descriptor to register
  ! [IN] mat_id: Material ID
  ! [OUT] status: Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Creep_Register(desc, mat_id, status)
    USE MD_Mat_Registry, ONLY: MD_Mat_Registry_Register

    TYPE(MD_Mat_Creep_Desc), INTENT(IN) :: desc
    INTEGER(i4), INTENT(IN) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Register material using unified registry
    CALL MD_Mat_Registry_Register(mat_id, MD_MAT_FAMILY_CREEP, &
                                   desc%sub_type, desc, status)
  END SUBROUTINE MD_Mat_Creep_Register

END MODULE MD_Mat_Creep_Core
