!===================================================================
! MODULE:  MD_KW_Dispatch
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Impl
! BRIEF:   Keyword dispatch - route keywords to domain-specific
!          Unified_Parse procedures by domain identification.
!===================================================================
MODULE MD_KW_Dispatch
  USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_KW_Def,    ONLY: KW_ASTNodeType
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------
  ! Constants - Domain IDs
  !-----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_MATERIAL      = 1
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_LOADBC        = 2
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_PROPERTY      = 3
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_SYSTEM        = 4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_OUTPUT        = 5
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_ELEMENT       = 6
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_MANUFACTURING = 7
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_INTERACTION   = 8
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_CONNECTOR     = 9
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_COUPLING      = 10
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_KINEMATIC     = 11
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_FLUID         = 12
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_MULTIPHYSICS  = 13
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_DATA          = 14
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_MESH          = 15
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_OPTIMIZATION  = 16
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_DOMAIN_SOLVER        = 17


  PUBLIC :: MD_KW_GetDomain
  PUBLIC :: MD_KW_GetTypeStr
  PUBLIC :: MD_KW_Dispatch_Info

CONTAINS

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Dispatch_Info
  ! PHASE:      P0
  ! PURPOSE:    Get dispatch info string for a domain
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Dispatch_Info(domain_id, info_str, status)
    INTEGER(i4), INTENT(IN)        :: domain_id                 ! [in]
    CHARACTER(LEN=*), INTENT(OUT)  :: info_str                  ! [out]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (domain_id)
    CASE (MD_KW_DOMAIN_MATERIAL)
      info_str = 'Mat domain: Use MD_Mat_*_Unified_Parse(material_type, ast_node, out_data, material_name, status)'
    CASE (MD_KW_DOMAIN_LOADBC)
      info_str = 'LoadBC domain: Use MD_Ldbc_*_Unified_Parse(bc_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_PROPERTY)
      info_str = 'Property domain: Use MD_Prop_*_Unified_Parse(prop_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_SYSTEM)
      info_str = 'System domain: Use MD_Model_Coord_*_Parse / MD_Model_Coord_*_Cfg (SYSTEM/NORMAL/ORIENTATION/TRANSFORM)'
    CASE (MD_KW_DOMAIN_OUTPUT)
      info_str = 'Output domain: Use MD_Output_*_Unified_Parse(out_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_ELEMENT)
      info_str = 'Element domain: Use MD_Elem_*_Unified_Parse(entity_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_INTERACTION)
      info_str = 'Interaction domain: Use MD_Interaction_*_Unified_Parse(int_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_CONNECTOR)
      info_str = 'Connector domain: Use MD_Connector_*_Unified_Parse(conn_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_COUPLING)
      info_str = 'Coupling domain: multiphysics model-definition coupling (no MD_Coupling / L3 slot)'
    CASE (MD_KW_DOMAIN_KINEMATIC)
      info_str = 'Kinematic domain: Use MD_LoadBC_Kinematic_Parse_*_Unified_Parse(kin_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_FLUID)
      info_str = 'Fluid domain: Use MD_Fluid_*_Unified_Parse(fluid_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_MULTIPHYSICS)
      info_str = 'Multiphysics domain: Use MD_Multiphysics_*_Unified_Parse(mph_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_DATA)
      info_str = 'Data domain: Use MD_Model_Data_*_Parse / MD_Model_Data_*_Cfg (TABLE/FIELD/DISTRIBUTION/VARIABLE/PARAMETER/PHYSICAL CONSTANTS)'
    CASE (MD_KW_DOMAIN_MESH)
      info_str = 'Mesh domain: Use MD_Mesh_*_Unified_Parse(mesh_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_OPTIMIZATION)
      info_str = 'Optimization domain: Use MD_Optimization_*_Unified_Parse(opt_type, ast_node, out_data, context_name, status)'
    CASE (MD_KW_DOMAIN_SOLVER)
      info_str = 'Solver domain (L5_RT): Use RT_Solver_*_Unified_Parse(solver_type, ast_node, out_data, context_name, status)'
    CASE DEFAULT
      info_str = 'Unknown domain'
      status%status_code = IF_STATUS_INVALID
      RETURN
    END SELECT

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_Dispatch_Info

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_GetDomain
  ! PHASE:      P1
  ! PURPOSE:    Map keyword name to domain ID via pattern matching
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_GetDomain(keyword_name, domain_id, status)
    CHARACTER(LEN=*), INTENT(IN)       :: keyword_name          ! [in]
    INTEGER(i4), INTENT(OUT)           :: domain_id             ! [out]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CHARACTER(LEN=64) :: kw_upper

    CALL init_error_status(status)
    kw_upper = keyword_name
    CALL to_upper(kw_upper)

    IF (INDEX(kw_upper, 'Mat') > 0 .OR. &
        INDEX(kw_upper, 'ELASTIC') > 0 .OR. &
        INDEX(kw_upper, 'PLASTIC') > 0 .OR. &
        INDEX(kw_upper, 'DAMAGE') > 0 .OR. &
        INDEX(kw_upper, 'CREEP') > 0 .OR. &
        INDEX(kw_upper, 'VISCO') > 0 .OR. &
        INDEX(kw_upper, 'HYPER') > 0) THEN
      domain_id = MD_KW_DOMAIN_MATERIAL
    ELSE IF (INDEX(kw_upper, 'FILM') > 0 .OR. &
             INDEX(kw_upper, 'RADIATE') > 0 .OR. &
             INDEX(kw_upper, 'DSFLUX') > 0 .OR. &
             INDEX(kw_upper, 'MASS_FLOW') > 0) THEN
      domain_id = MD_KW_DOMAIN_LOADBC
    ELSE IF (INDEX(kw_upper, 'MASS') > 0 .OR. &
             INDEX(kw_upper, 'INERTIA') > 0) THEN
      domain_id = MD_KW_DOMAIN_PROPERTY
    ELSE IF (INDEX(kw_upper, 'SYSTEM') > 0 .OR. &
             INDEX(kw_upper, 'ORIENTATION') > 0 .OR. &
             INDEX(kw_upper, 'NORMAL') > 0) THEN
      domain_id = MD_KW_DOMAIN_SYSTEM
    ELSE IF (INDEX(kw_upper, 'OUTPUT') > 0 .OR. &
             INDEX(kw_upper, 'REPORT') > 0 .OR. &
             INDEX(kw_upper, 'PLOT') > 0 .OR. &
             INDEX(kw_upper, 'EXPORT') > 0) THEN
      domain_id = MD_KW_DOMAIN_OUTPUT
    ELSE IF (INDEX(kw_upper, 'ELEMENT') > 0 .OR. &
             INDEX(kw_upper, 'USER_ELEMENT') > 0) THEN
      domain_id = MD_KW_DOMAIN_ELEMENT
    ELSE IF (INDEX(kw_upper, 'FRICTION') > 0 .OR. &
             INDEX(kw_upper, 'CONTACT') > 0) THEN
      domain_id = MD_KW_DOMAIN_INTERACTION
    ELSE IF (INDEX(kw_upper, 'CONNECTOR') > 0 .OR. &
             INDEX(kw_upper, 'SPRING') > 0 .OR. &
             INDEX(kw_upper, 'DASHPOT') > 0) THEN
      domain_id = MD_KW_DOMAIN_CONNECTOR
    ELSE IF (INDEX(kw_upper, 'COUPL') > 0 .OR. &
             INDEX(kw_upper, 'FSI') > 0) THEN
      domain_id = MD_KW_DOMAIN_COUPLING
    ELSE IF (INDEX(kw_upper, 'KINEMATIC') > 0 .OR. &
             INDEX(kw_upper, 'VELOCITY') > 0 .OR. &
             INDEX(kw_upper, 'ACCELERATION') > 0) THEN
      domain_id = MD_KW_DOMAIN_KINEMATIC
    ELSE IF (INDEX(kw_upper, 'FLUID') > 0 .OR. &
             INDEX(kw_upper, 'AQUA') > 0 .OR. &
             INDEX(kw_upper, 'DRAG') > 0) THEN
      domain_id = MD_KW_DOMAIN_FLUID
    ELSE IF (INDEX(kw_upper, 'MULTIPHYSICS') > 0 .OR. &
             INDEX(kw_upper, 'ACOUSTIC') > 0 .OR. &
             INDEX(kw_upper, 'ELECTRICAL') > 0) THEN
      domain_id = MD_KW_DOMAIN_MULTIPHYSICS
    ELSE IF (INDEX(kw_upper, 'DATA') > 0 .OR. &
             INDEX(kw_upper, 'TABLE') > 0 .OR. &
             INDEX(kw_upper, 'FIELD') > 0 .OR. &
             INDEX(kw_upper, 'PARAMETER') > 0) THEN
      domain_id = MD_KW_DOMAIN_DATA
    ELSE IF (INDEX(kw_upper, 'MESH') > 0 .OR. &
             INDEX(kw_upper, 'REMESH') > 0) THEN
      domain_id = MD_KW_DOMAIN_MESH
    ELSE IF (INDEX(kw_upper, 'OPTIMIZATION') > 0 .OR. &
             INDEX(kw_upper, 'DESIGN') > 0) THEN
      domain_id = MD_KW_DOMAIN_OPTIMIZATION
    ELSE
      domain_id = 0
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_KW_GetDomain: unknown keyword ' // TRIM(keyword_name)
    END IF

    IF (domain_id > 0) status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_GetDomain

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_GetTypeStr
  ! PHASE:      P1
  ! PURPOSE:    Extract type string from keyword name
  !             (spaces -> underscores for Unified_Parse)
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_GetTypeStr(keyword_name, type_str, status)
    CHARACTER(LEN=*), INTENT(IN)       :: keyword_name          ! [in]
    CHARACTER(LEN=*), INTENT(OUT)      :: type_str              ! [out]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, len_kw

    CALL init_error_status(status)
    type_str = TRIM(keyword_name)

    len_kw = LEN_TRIM(type_str)
    DO i = 1, len_kw
      IF (type_str(i:i) == ' ') type_str(i:i) = '_'
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_GetTypeStr

  !-----------------------------------------------------------------
  ! SUBROUTINE: to_upper  (PRIVATE)
  ! PHASE:      P0
  ! PURPOSE:    Convert string to uppercase in-place
  !-----------------------------------------------------------------
  SUBROUTINE to_upper(str)
    CHARACTER(LEN=*), INTENT(INOUT) :: str                      ! [inout]
    INTEGER(i4) :: i, len_str, diff

    diff    = ICHAR('a') - ICHAR('A')
    len_str = LEN(str)
    DO i = 1, len_str
      IF (str(i:i) >= 'a' .AND. str(i:i) <= 'z') THEN
        str(i:i) = CHAR(ICHAR(str(i:i)) - diff)
      END IF
    END DO
  END SUBROUTINE to_upper

END MODULE MD_KW_Dispatch
