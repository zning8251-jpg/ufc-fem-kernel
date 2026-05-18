!===============================================================================
! MODULE: MD_Elem_Validate
! LAYER:  L3_MD
! DOMAIN: Element
! ROLE:   Validate (Validation)
! BRIEF:  Element validation — domain checks, connectivity, cross-domain refs
! **W2**：校验 **Populate/Domain** 产物（连通性、**`elem_type_id`**、截面/材料引用）；与 **`MD_Elem_Reg`** 一致，
!         勿引入旁路拓扑。
!===============================================================================
MODULE MD_Elem_Validate
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_Elem_Def,     ONLY: MD_Elem_Desc, MD_Elem_State, &
                              MD_Elem_Algo, MD_Elem_Ctx
  USE MD_Elem_Domain,  ONLY: MD_Elem_Domain_Algo
  USE MD_Elem_Reg,     ONLY: MD_Elem_Reg_Validate

  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Validate_State
  ! KIND: State
  ! DESC: Mutable validation result structure
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Validate_State
    LOGICAL     :: is_valid      = .FALSE.    ! Overall validity
    INTEGER(i4) :: n_errors      = 0_i4       ! Error count
    INTEGER(i4) :: n_warnings    = 0_i4       ! Warning count
    !--- Detailed checks ---
    LOGICAL     :: desc_valid    = .FALSE.    ! Descriptor valid
    LOGICAL     :: conn_valid    = .FALSE.    ! Connectivity valid
    LOGICAL     :: mat_ref_valid = .FALSE.    ! Material reference valid
    LOGICAL     :: sect_ref_valid = .FALSE.   ! Section reference valid
    LOGICAL     :: mesh_ref_valid = .FALSE.   ! Mesh reference valid
    !--- Error messages ---
    CHARACTER(LEN=256) :: error_msg = ""      ! First error message
  END TYPE MD_Elem_Validate_State

  !=============================================================================
  ! SECTION: Public interfaces (three-segment naming)
  !=============================================================================
  PUBLIC :: MD_Elem_Validate_Domain
  PUBLIC :: MD_Elem_Validate_Conn
  PUBLIC :: MD_Elem_Validate_MatRef
  PUBLIC :: MD_Elem_Validate_SectRef


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Validate_Domain
  ! PHASE:      P0
  ! PURPOSE:    Validate entire element domain
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Validate_Domain(domain, result, status) RESULT(is_valid)
    TYPE(MD_Elem_Domain_Algo),  INTENT(IN)  :: domain
    TYPE(MD_Elem_Validate_State), INTENT(OUT) :: result
    TYPE(ErrorStatusType),      INTENT(OUT) :: status
    LOGICAL :: is_valid

    is_valid = .FALSE.
    result   = MD_Elem_Validate_State()

    ! Check initialization
    IF (.NOT. domain%is_initialized) THEN
      result%n_errors = result%n_errors + 1
      result%error_msg = "Domain not initialized"
      CALL init_error_status(status, IF_STATUS_ERROR, result%error_msg)
      RETURN
    END IF

    ! Validate descriptor
    result%desc_valid = MD_Elem_Reg_Validate(domain%desc, status)
    IF (.NOT. result%desc_valid) THEN
      result%n_errors = result%n_errors + 1
      result%error_msg = "Descriptor validation failed"
    END IF

    ! Check domain metadata
    IF (domain%n_elements <= 0) THEN
      result%n_errors = result%n_errors + 1
      result%error_msg = "Invalid element count"
    END IF

    ! Check context
    IF (.NOT. domain%ctx%is_active) THEN
      result%n_warnings = result%n_warnings + 1
    END IF

    ! Cross-domain references
    result%mat_ref_valid  = MD_Elem_Validate_MatRef(domain, status)
    result%sect_ref_valid = MD_Elem_Validate_SectRef(domain, status)

    ! Overall validity
    IF (result%n_errors == 0) THEN
      is_valid         = .TRUE.
      result%is_valid  = .TRUE.
      CALL init_error_status(status, IF_STATUS_OK)
    ELSE
      CALL init_error_status(status, IF_STATUS_ERROR, result%error_msg)
    END IF
  END FUNCTION MD_Elem_Validate_Domain

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Validate_Conn
  ! PHASE:      P0
  ! PURPOSE:    Validate element connectivity against mesh nodes
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Validate_Conn(domain, node_ids, status) RESULT(is_valid)
    TYPE(MD_Elem_Domain_Algo), INTENT(IN)  :: domain
    INTEGER(i4),               INTENT(IN)  :: node_ids(:)
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    LOGICAL :: is_valid

    is_valid = .FALSE.

    IF (domain%desc%cfg_topo%n_nodes <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid n_nodes")
      RETURN
    END IF

    IF (domain%desc%cfg_topo%dof_per_node <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid dof_per_node")
      RETURN
    END IF

    ! Placeholder: full connectivity check requires L4_PH data
    is_valid = .TRUE.
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Validate_Conn

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Validate_MatRef
  ! PHASE:      P0
  ! PURPOSE:    Validate material reference exists
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Validate_MatRef(domain, status) RESULT(is_valid)
    TYPE(MD_Elem_Domain_Algo), INTENT(IN)  :: domain
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    LOGICAL :: is_valid

    is_valid = .FALSE.

    IF (domain%desc%cfg_id%mat_id <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid mat_id")
      RETURN
    END IF

    is_valid = .TRUE.
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Validate_MatRef

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Validate_SectRef
  ! PHASE:      P0
  ! PURPOSE:    Validate section reference exists
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Validate_SectRef(domain, status) RESULT(is_valid)
    TYPE(MD_Elem_Domain_Algo), INTENT(IN)  :: domain
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    LOGICAL :: is_valid

    is_valid = .FALSE.

    IF (domain%desc%cfg_id%sect_id <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid sect_id")
      RETURN
    END IF

    is_valid = .TRUE.
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Validate_SectRef

END MODULE MD_Elem_Validate
