!===============================================================================
! MODULE: MD_Elem_Populate
! LAYER:  L3_MD
! DOMAIN: Element
! ROLE:   Populate (Input population)
! BRIEF:  Element input population — parse *ELEMENT cards, connectivity, validation
! **W2**：**Populate** 写入 **`MD_Elem_*`**（连通性、**`elem_type_id`**/`sect_id`/`mat_id`）；
!         顺序对齐 **`MD_Elem_Reg`** 注册后再映 L4 槽。
!===============================================================================
MODULE MD_Elem_Populate
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_Elem_Def,     ONLY: MD_Elem_Desc, MD_Elem_State, &
                              MD_Elem_Algo, MD_Elem_Ctx
  USE MD_Elem_Domain,  ONLY: MD_Elem_Domain_Algo
  USE MD_Elem_Reg,     ONLY: MD_Elem_Reg_LookupById

  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Populate_Arg
  ! KIND: Arg
  ! DESC: Input population arguments from ABAQUS parser
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Populate_Arg
    !--- Input data (IN) ---
    INTEGER(i4) :: elem_type_id    = 0_i4     ! Element type ID
    INTEGER(i4) :: sect_id         = 0_i4     ! Section ID
    INTEGER(i4) :: mat_id          = 0_i4     ! Material ID
    !--- Instance data (INOUT) ---
    INTEGER(i4), ALLOCATABLE :: elem_ids(:)   ! Element IDs [n_elems]
    INTEGER(i4), ALLOCATABLE :: conn_table(:,:) ! Connectivity [n_nodes, n_elems]
    INTEGER(i4), ALLOCATABLE :: node_ids(:)   ! Node IDs [n_nodes_total]
    !--- Metadata (OUT) ---
    INTEGER(i4) :: n_elements       = 0_i4    ! Number of elements
    INTEGER(i4) :: n_nodes_per_elem = 0_i4    ! Nodes per element
    LOGICAL     :: is_valid         = .FALSE.  ! Validation flag
  END TYPE MD_Elem_Populate_Arg

  !=============================================================================
  ! SECTION: Public interfaces (three-segment naming)
  !=============================================================================
  PUBLIC :: MD_Elem_Populate_Domain
  PUBLIC :: MD_Elem_Populate_ParseConn
  PUBLIC :: MD_Elem_Populate_Validate


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Populate_Domain
  ! PHASE:      P1
  ! PURPOSE:    Populate element domain from input data
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Populate_Domain(domain, args, status)
    TYPE(MD_Elem_Domain_Algo), INTENT(INOUT) :: domain
    TYPE(MD_Elem_Populate_Arg), INTENT(IN)   :: args
    TYPE(ErrorStatusType),      INTENT(OUT)  :: status

    IF (.NOT. args%is_valid) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid populate args")
      RETURN
    END IF

    IF (args%n_elements <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Zero elements")
      RETURN
    END IF

    ! Get descriptor from registry
    domain%desc = MD_Elem_Reg_LookupById(args%elem_type_id, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Update context
    domain%ctx%n_instances = args%n_elements
    domain%ctx%is_active   = .TRUE.
    domain%n_elements      = args%n_elements

    ! Store section/material references (nested auxiliary path)
    domain%desc%cfg_id%sect_id = args%sect_id
    domain%desc%cfg_id%mat_id  = args%mat_id

    ! Initialize state
    domain%state%total_elements  = args%n_elements
    domain%state%active_elements = args%n_elements

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Populate_Domain

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Populate_ParseConn
  ! PHASE:      P1
  ! PURPOSE:    Parse element connectivity from input table
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Populate_ParseConn(args, conn_data, status)
    TYPE(MD_Elem_Populate_Arg), INTENT(INOUT) :: args
    INTEGER(i4),                INTENT(IN)    :: conn_data(:,:)
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4) :: n_elems, n_nodes, i, j

    n_elems = SIZE(conn_data, 1)
    n_nodes = SIZE(conn_data, 2) - 1  ! First column = element ID

    IF (n_elems <= 0 .OR. n_nodes <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid dimensions")
      RETURN
    END IF

    IF (ALLOCATED(args%elem_ids))   DEALLOCATE(args%elem_ids)
    IF (ALLOCATED(args%conn_table)) DEALLOCATE(args%conn_table)
    IF (ALLOCATED(args%node_ids))   DEALLOCATE(args%node_ids)

    ALLOCATE(args%elem_ids(n_elems))
    ALLOCATE(args%conn_table(n_nodes, n_elems))
    ALLOCATE(args%node_ids(n_elems * n_nodes))

    DO i = 1, n_elems
      args%elem_ids(i) = conn_data(i, 1)
      DO j = 1, n_nodes
        args%conn_table(j, i) = conn_data(i, j + 1)
      END DO
    END DO

    args%n_elements       = n_elems
    args%n_nodes_per_elem = n_nodes
    args%is_valid         = .TRUE.

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Populate_ParseConn

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Populate_Validate
  ! PHASE:      P0
  ! PURPOSE:    Validate input connectivity table
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Populate_Validate(args, expected_n_nodes, status) RESULT(is_valid)
    TYPE(MD_Elem_Populate_Arg), INTENT(IN)  :: args
    INTEGER(i4),                INTENT(IN)  :: expected_n_nodes
    TYPE(ErrorStatusType),      INTENT(OUT) :: status
    LOGICAL :: is_valid
    INTEGER(i4) :: i, j

    is_valid = .FALSE.

    IF (.NOT. ALLOCATED(args%elem_ids)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "elem_ids not allocated")
      RETURN
    END IF

    IF (.NOT. ALLOCATED(args%conn_table)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "conn_table not allocated")
      RETURN
    END IF

    IF (SIZE(args%elem_ids) /= args%n_elements) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "elem_ids size mismatch")
      RETURN
    END IF

    IF (SIZE(args%conn_table, 1) /= expected_n_nodes) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "conn_table node mismatch")
      RETURN
    END IF

    IF (SIZE(args%conn_table, 2) /= args%n_elements) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "conn_table elem mismatch")
      RETURN
    END IF

    ! Check duplicate element IDs
    DO i = 1, args%n_elements - 1
      DO j = i + 1, args%n_elements
        IF (args%elem_ids(i) == args%elem_ids(j)) THEN
          CALL init_error_status(status, IF_STATUS_ERROR, "Duplicate elem ID")
          RETURN
        END IF
      END DO
    END DO

    ! Check connectivity bounds (> 0)
    DO i = 1, args%n_elements
      DO j = 1, expected_n_nodes
        IF (args%conn_table(j, i) <= 0) THEN
          CALL init_error_status(status, IF_STATUS_ERROR, "Invalid node ID")
          RETURN
        END IF
      END DO
    END DO

    is_valid = .TRUE.
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Populate_Validate

END MODULE MD_Elem_Populate
