!===================================================================
! MODULE : MD_Inp_Parse
! LAYER  : L3_MD
! DOMAIN : KeyWord (KW)
! ROLE   : Brg / Bridge  (INP file parser)
! BRIEF  : Abaqus-style INP file parser.  Reads *NODE, *ELEMENT,
!          *BOUNDARY, *CLOAD, *MATERIAL etc. and populates a
!          UF_ParsedModel container.
!===================================================================

MODULE MD_Inp_Parse
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE
    
    !--------------------------------------------------------------------------
    ! Public interface
    !--------------------------------------------------------------------------
    PUBLIC :: UF_ParsedModel, parse_inp_file
    PUBLIC :: parser_get_coords, parser_get_conn, parser_get_elem_types
    PUBLIC :: parser_get_bc_dofs, parser_get_bc_vals
    PUBLIC :: parser_get_loads, parser_destroy
    
    !--------------------------------------------------------------------------
    ! Maximum dimensions
    !--------------------------------------------------------------------------
    INTEGER(i4), PARAMETER :: MAX_NODES = 1000000
    INTEGER(i4), PARAMETER :: MAX_ELEMENTS = 1000000
    INTEGER(i4), PARAMETER :: MAX_BC = 10000
    INTEGER(i4), PARAMETER :: MAX_LOADS = 10000
    INTEGER(i4), PARAMETER :: MAX_LINE = 256
    INTEGER(i4), PARAMETER :: MAX_NNODE_ELEM = 27  ! Max nodes per element
    
    !--------------------------------------------------------------------------
    ! Element type codes (JTYPE compatible)
    !--------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_C3D4 = 101
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_C3D8 = 102
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_C3D8R = 103
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_C3D10 = 104
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_C3D20 = 105
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_CPE4 = 201
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_CPE8 = 202
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_CPS4 = 211
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_CPS8 = 212
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_CAX4 = 221
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_T2D2 = 301
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_T3D2 = 302
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_B31 = 401
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_B32 = 402
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_S4R = 501
    INTEGER(i4), PARAMETER, PUBLIC :: ELEM_S8R = 502
    
    !=============================================================================
    ! Parsed Model Data Container (Ctx category)
    !=============================================================================
    !> @brief Parsed model data container type (Ctx category)
    !! @details Context aggregating parsed model data from INP file
    !! Theory: Contains node coordinates X ?ℝ^(n_dim×n_nodes), element connectivity conn ?ℤ^(max_nodes×n_elems),
    !! material properties (E ? ? ν ? ? ρ ? ?, boundary conditions (u_0 ? ?, loads (F_0 ? ?
    TYPE :: UF_ParsedModel
        ! Header
        CHARACTER(LEN=256) :: title = ''                           ! Model title
        
        ! Nodes
        INTEGER(i4) :: num_nodes = 0                              ! Number of nodes n_nodes  ? ?
        INTEGER(i4) :: ndim = 3                                    ! Spatial dimension n_dim  ? ?
        REAL(wp), ALLOCATABLE :: coords(:,:)                       ! Node coordinates X  ?ℝ^(n_dim×n_nodes)
        INTEGER(i4), ALLOCATABLE :: node_id(:)                     ! Original node IDs  ?ℤ^n_nodes
        
        ! Elements
        INTEGER(i4) :: num_elements = 0                            ! Number of elements n_elems  ? ?
        INTEGER(i4), ALLOCATABLE :: elem_conn(:,:)                 ! Element connectivity conn  ?ℤ^(max_nodes×n_elems)
        INTEGER(i4), ALLOCATABLE :: elem_type(:)                   ! Element type codes  ?ℤ^n_elems
        INTEGER(i4), ALLOCATABLE :: elem_id(:)                     ! Original element IDs  ?ℤ^n_elems
        INTEGER(i4), ALLOCATABLE :: elem_nnode(:)                  ! Nodes per element  ?ℤ^n_elems
        
        ! Material (simplified: one elastic material)
        REAL(wp) :: E = 0.0_wp                                     ! Young's modulus E  ? ?
        REAL(wp) :: nu = 0.0_wp                                    ! Poisson's ratio ν  ? ?
        REAL(wp) :: rho = 0.0_wp                                   ! Density ρ  ? ?
        
        ! Boundary conditions
        INTEGER(i4) :: num_bc = 0                                  ! Number of BCs n_bc  ? ?
        INTEGER(i4), ALLOCATABLE :: bc_node(:)                     ! BC node IDs  ?ℤ^n_bc
        INTEGER(i4), ALLOCATABLE :: bc_dof(:)                      ! BC DOF directions  ?ℤ^n_bc
        REAL(wp), ALLOCATABLE :: bc_val(:)                         ! Prescribed values u_0  ?ℝ^n_bc
        
        ! Concentrated loads
        INTEGER(i4) :: num_loads = 0                               ! Number of loads n_loads  ? ?
        INTEGER(i4), ALLOCATABLE :: load_node(:)                   ! Load node IDs  ?ℤ^n_loads
        INTEGER(i4), ALLOCATABLE :: load_dof(:)                    ! Load DOF directions  ?ℤ^n_loads
        REAL(wp), ALLOCATABLE :: load_val(:)                        ! Load magnitudes F_0  ?ℝ^n_loads
        
        ! Analysis parameters
        LOGICAL :: is_static = .TRUE.                              ! Static analysis flag
        REAL(wp) :: time_period = 1.0_wp                           ! Time period T  ? ?
        REAL(wp) :: initial_inc = 0.1_wp                           ! Initial increment Δt_0  ? ?
        
        ! Internal mapping
        INTEGER(i4), ALLOCATABLE :: node_map(:)                     ! Original→Internal node mapping  ?ℤ^n_nodes
        INTEGER(i4) :: max_node_id = 0                             ! Maximum node ID  ? ?
        
    CONTAINS
        PROCEDURE :: init => parsed_model_init
        PROCEDURE :: destroy => parsed_model_destroy
    END TYPE UF_ParsedModel

    !=============================================================================
    ! Structured Interface Types
    !=============================================================================
    !> @brief Parse INP file input structure (Desc category)
    TYPE, PUBLIC :: ParseInpFile_In
        CHARACTER(LEN=256) :: filename = ""                         ! Input filename
        INTEGER(i4) :: ndim = 3                                     ! Spatial dimension n_dim  ? ?(optional)
    END TYPE ParseInpFile_In

    !> @brief Parse INP file output structure (State category)
    TYPE, PUBLIC :: ParseInpFile_Out
        TYPE(UF_ParsedModel) :: model                               ! Parsed model
        INTEGER(i4) :: ierr = 0                                     ! Error code  ? ?(0=OK, <0=error)
    END TYPE ParseInpFile_Out
    
CONTAINS

    !=============================================================================
    !> @brief Initialize parsed model (legacy interface)
    !! @details Initializes parsed model with default allocations
    !! @param[inout] this Parsed model object
    !! @param[in] ndim Spatial dimension n_dim ? ?(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use ParseInpFile_In and ParseInpFile_Out types
    !=============================================================================
    SUBROUTINE parsed_model_init(this, ndim)
        CLASS(UF_ParsedModel), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: ndim
        
        IF (PRESENT(ndim)) this%cfg%ndim = ndim
        
        ALLOCATE(this%coords(this%cfg%ndim, MAX_NODES))
        ALLOCATE(this%node_id(MAX_NODES))
        ALLOCATE(this%elem_conn(MAX_NNODE_ELEM, MAX_ELEMENTS))
        ALLOCATE(this%elem_type(MAX_ELEMENTS))
        ALLOCATE(this%elem_id(MAX_ELEMENTS))
        ALLOCATE(this%elem_nnode(MAX_ELEMENTS))
        ALLOCATE(this%bc_node(MAX_BC))
        ALLOCATE(this%bc_dof(MAX_BC))
        ALLOCATE(this%bc_val(MAX_BC))
        ALLOCATE(this%load_node(MAX_LOADS))
        ALLOCATE(this%load_dof(MAX_LOADS))
        ALLOCATE(this%load_val(MAX_LOADS))
        
        this%coords = 0.0_wp
        this%node_id = 0
        this%elem_conn = 0
        this%elem_type = 0
        this%elem_id = 0
        this%elem_nnode = 0
        this%bc_node = 0
        this%bc_dof = 0
        this%bc_val = 0.0_wp
        this%load_node = 0
        this%load_dof = 0
        this%load_val = 0.0_wp
        
    END SUBROUTINE parsed_model_init
    
    !=============================================================================
    !> @brief Destroy parsed model (legacy interface)
    !! @details Destroys and deallocates parsed model data
    !! @param[inout] this Parsed model object
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE parsed_model_destroy(this)
        CLASS(UF_ParsedModel), INTENT(INOUT) :: this
        
        IF (ALLOCATED(this%coords)) DEALLOCATE(this%coords)
        IF (ALLOCATED(this%node_id)) DEALLOCATE(this%node_id)
        IF (ALLOCATED(this%elem_conn)) DEALLOCATE(this%elem_conn)
        IF (ALLOCATED(this%elem_type)) DEALLOCATE(this%elem_type)
        IF (ALLOCATED(this%elem_id)) DEALLOCATE(this%elem_id)
        IF (ALLOCATED(this%elem_nnode)) DEALLOCATE(this%elem_nnode)
        IF (ALLOCATED(this%bc_node)) DEALLOCATE(this%bc_node)
        IF (ALLOCATED(this%bc_dof)) DEALLOCATE(this%bc_dof)
        IF (ALLOCATED(this%bc_val)) DEALLOCATE(this%bc_val)
        IF (ALLOCATED(this%load_node)) DEALLOCATE(this%load_node)
        IF (ALLOCATED(this%load_dof)) DEALLOCATE(this%load_dof)
        IF (ALLOCATED(this%load_val)) DEALLOCATE(this%load_val)
        IF (ALLOCATED(this%node_map)) DEALLOCATE(this%node_map)
        
    END SUBROUTINE parsed_model_destroy
    
    !=============================================================================
    !> @brief Parse INP file (legacy interface)
    !! @details Parses Abaqus-style INP file and populates parsed model
    !! @param[in] filename Input file name
    !! @param[out] model Parsed model object
    !! @param[out] ierr Error code ? ?(0=success, <0=error)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use ParseInpFile_In and ParseInpFile_Out types:
    !!     TYPE(ParseInpFile_In) :: parse_in
    !!     parse_in%filename = ...
    !!     CALL parse_inp_file_structured(parse_in, parse_out)
    !=============================================================================
    SUBROUTINE parse_inp_file(filename, model, ierr)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        TYPE(UF_ParsedModel), INTENT(OUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: unit_num, ios
        CHARACTER(LEN=MAX_LINE) :: line, keyword
        CHARACTER(LEN=64) :: elem_type_str
        INTEGER(i4) :: current_elem_type
        LOGICAL :: in_step, in_material
        CHARACTER(LEN=64) :: current_material
        
        ierr = 0
        CALL model%init(3)
        
        unit_num = 99
        OPEN(UNIT=unit_num, FILE=TRIM(filename), STATUS='OLD', &
             ACTION='READ', IOSTAT=ios)
        IF (ios /= 0) THEN
            ierr = -1
            WRITE(*,'(A,A)') 'ERROR: Cannot open file: ', TRIM(filename)
            RETURN
        END IF
        
        in_step = .FALSE.
        in_material = .FALSE.
        current_elem_type = ELEM_C3D8
        current_material = ''
        
        !-----------------------------------------------------------------------
        ! Parse line by line
        !-----------------------------------------------------------------------
        DO
            READ(unit_num, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT
            
            ! Skip empty lines and comments
            line = ADJUSTL(line)
            IF (LEN_TRIM(line) == 0) CYCLE
            IF (line(1:2) == '**') CYCLE  ! Abaqus comment
            
            ! Check for keyword (starts with *)
            IF (line(1:1) == '*') THEN
                keyword = get_keyword(line)
                
                SELECT CASE (TRIM(keyword))
                
                CASE ('HEADING')
                    ! Read title on next line
                    READ(unit_num, '(A)', IOSTAT=ios) model%title
                    
                CASE ('NODE')
                    CALL parse_nodes(unit_num, model, ierr)
                    IF (ierr /= 0) EXIT
                    
                CASE ('ELEMENT')
                    ! Get element type from keyword line
                    elem_type_str = get_option(line, 'TYPE')
                    current_elem_type = element_type_code(elem_type_str)
                    CALL parse_elements(unit_num, model, current_elem_type, ierr)
                    IF (ierr /= 0) EXIT
                    
                CASE ('NSET')
                    CALL parse_nset(unit_num, model, ierr)
                    IF (ierr /= 0) EXIT
                    
                CASE ('ELSET')
                    CALL parse_elset(unit_num, model, ierr)
                    IF (ierr /= 0) EXIT
                    
                CASE ('MATERIAL')
                    in_material = .TRUE.
                    current_material = get_option(line, 'NAME')
                    
                CASE ('ELASTIC')
                    CALL parse_elastic(unit_num, model, ierr)
                    
                CASE ('PLASTIC')
                    CALL parse_plastic(unit_num, model, ierr)
                    
                CASE ('DENSITY')
                    CALL parse_density(unit_num, model, ierr)
                    
                CASE ('AMPLITUDE')
                    CALL parse_amplitude(unit_num, model, ierr)
                    
                CASE ('SOLID SECTION', 'SHELL SECTION')
                    CALL parse_section(unit_num, model, ierr)
                    
                CASE ('BOUNDARY')
                    CALL parse_boundary(unit_num, model, ierr)
                    IF (ierr /= 0) EXIT
                    
                CASE ('CLOAD')
                    CALL parse_cload(unit_num, model, ierr)
                    IF (ierr /= 0) EXIT
                    
                CASE ('DLOAD')
                    CALL parse_dload(unit_num, model, ierr)
                    IF (ierr /= 0) EXIT
                    
                CASE ('INITIAL CONDITIONS')
                    CALL parse_initial_conditions(unit_num, model, ierr)
                    
                CASE ('STEP')
                    in_step = .TRUE.
                    
                CASE ('STATIC')
                    model%is_static = .TRUE.
                    CALL parse_static_params(line, model)
                    
                CASE ('DYNAMIC')
                    model%is_static = .FALSE.
                    CALL parse_dynamic_params(line, model)
                    
                CASE ('OUTPUT')
                    CALL parse_output(unit_num, model, ierr)
                    
                CASE ('END')
                    IF (INDEX(ADJUSTL(line), 'END STEP') > 0) THEN
                        in_step = .FALSE.
                    END IF
                    
                CASE DEFAULT
                    ! Unknown keyword - skip, but log warning
                    WRITE(*,'(A,A)') 'WARNING: Unknown keyword: ', TRIM(keyword)
                    
                END SELECT
            END IF
        END DO
        
        CLOSE(unit_num)
        
        ! Build node mapping
        CALL build_node_mapping(model)
        
        WRITE(*,'(A,A)') 'Parsed input file: ', TRIM(filename)
        WRITE(*,'(A,I8)') '  Nodes:    ', model%num_nodes
        WRITE(*,'(A,I8)') '  Elements: ', model%num_elements
        WRITE(*,'(A,I8)') '  BCs:      ', model%num_bc
        WRITE(*,'(A,I8)') '  Loads:    ', model%num_loads
        
    END SUBROUTINE parse_inp_file
    
    !===========================================================================
    ! Get keyword from line (uppercase)
    !===========================================================================
    FUNCTION get_keyword(line) RESULT(keyword)
        CHARACTER(LEN=*), INTENT(IN) :: line
        CHARACTER(LEN=64) :: keyword
        INTEGER(i4) :: i, comma_pos
        
        keyword = ''
        IF (LEN_TRIM(line) < 2) RETURN
        
        ! Find comma or end of keyword
        comma_pos = INDEX(line, ',')
        IF (comma_pos > 0) THEN
            keyword = line(2:comma_pos-1)
        ELSE
            keyword = line(2:)
        END IF
        
        keyword = ADJUSTL(keyword)
        
        ! Convert to uppercase
        DO i = 1, LEN_TRIM(keyword)
            IF (keyword(i:i) >= 'a' .AND. keyword(i:i) <= 'z') THEN
                keyword(i:i) = CHAR(ICHAR(keyword(i:i)) - 32)
            END IF
        END DO
        
    END FUNCTION get_keyword
    
    !===========================================================================
    ! Get option value from keyword line
    !===========================================================================
    FUNCTION get_option(line, option_name) RESULT(value)
        CHARACTER(LEN=*), INTENT(IN) :: line, option_name
        CHARACTER(LEN=64) :: value
        INTEGER(i4) :: pos, eq_pos, comma_pos, end_pos
        CHARACTER(LEN=MAX_LINE) :: upper_line
        
        value = ''
        upper_line = to_upper(line)
        
        pos = INDEX(upper_line, TRIM(option_name))
        IF (pos == 0) RETURN
        
        eq_pos = INDEX(upper_line(pos:), '=')
        IF (eq_pos == 0) RETURN
        
        pos = pos + eq_pos
        comma_pos = INDEX(line(pos:), ',')
        IF (comma_pos > 0) THEN
            end_pos = pos + comma_pos - 2
        ELSE
            end_pos = LEN_TRIM(line)
        END IF
        
        value = ADJUSTL(line(pos:end_pos))
        value = to_upper(value)
        
    END FUNCTION get_option
    
    !===========================================================================
    ! Convert string to uppercase
    !===========================================================================
    FUNCTION to_upper(str) RESULT(upper)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=LEN(str)) :: upper
        INTEGER(i4) :: i
        
        upper = str
        DO i = 1, LEN_TRIM(upper)
            IF (upper(i:i) >= 'a' .AND. upper(i:i) <= 'z') THEN
                upper(i:i) = CHAR(ICHAR(upper(i:i)) - 32)
            END IF
        END DO
    END FUNCTION to_upper
    
    !===========================================================================
    ! Get element type code from string
    !===========================================================================
    FUNCTION element_type_code(type_str) RESULT(code)
        CHARACTER(LEN=*), INTENT(IN) :: type_str
        INTEGER(i4) :: code
        CHARACTER(LEN=16) :: upper_str
        
        upper_str = to_upper(ADJUSTL(type_str))
        
        SELECT CASE (TRIM(upper_str))
            CASE ('C3D4')
            code = ELEM_C3D4
            CASE ('C3D8')
            code = ELEM_C3D8
            CASE ('C3D8R')
            code = ELEM_C3D8R
            CASE ('C3D10')
            code = ELEM_C3D10
            CASE ('C3D20')
            code = ELEM_C3D20
            CASE ('CPE4')
            code = ELEM_CPE4
            CASE ('CPE8')
            code = ELEM_CPE8
            CASE ('CPS4')
            code = ELEM_CPS4
            CASE ('CPS8')
            code = ELEM_CPS8
            CASE ('CAX4')
            code = ELEM_CAX4
            CASE ('T2D2')
            code = ELEM_T2D2
            CASE ('T3D2')
            code = ELEM_T3D2
            CASE ('B31')
            code = ELEM_B31
            CASE ('B32')
            code = ELEM_B32
            CASE ('S4R')
            code = ELEM_S4R
            CASE ('S8R')
            code = ELEM_S8R
            CASE DEFAULT
            code = ELEM_C3D8
        END SELECT
    END FUNCTION element_type_code
    
    !===========================================================================
    ! Get nodes per element for given type
    !===========================================================================
    FUNCTION nodes_per_element(etype) RESULT(n)
        INTEGER(i4), INTENT(IN) :: etype
        INTEGER(i4) :: n
        
        SELECT CASE (etype)
            CASE (ELEM_C3D4)
            n = 4
            CASE (ELEM_C3D8)
            n = 8
            CASE (ELEM_C3D8R)
            n = 8
            CASE (ELEM_C3D10)
            n = 10
            CASE (ELEM_C3D20)
            n = 20
            CASE (ELEM_CPE4)
            n = 4
            CASE (ELEM_CPE8)
            n = 8
            CASE (ELEM_CPS4)
            n = 4
            CASE (ELEM_CPS8)
            n = 8
            CASE (ELEM_CAX4)
            n = 4
            CASE (ELEM_T2D2)
            n = 2
            CASE (ELEM_T3D2)
            n = 2
            CASE (ELEM_B31)
            n = 2
            CASE (ELEM_B32)
            n = 3
            CASE (ELEM_S4R)
            n = 4
            CASE (ELEM_S8R)
            n = 8
            CASE DEFAULT
            n = 8
        END SELECT
    END FUNCTION nodes_per_element
    
    !===========================================================================
    ! Parse *NODE data
    !===========================================================================
    SUBROUTINE parse_nodes(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        
        CHARACTER(LEN=MAX_LINE) :: line
        INTEGER(i4) :: ios, node_id
        REAL(wp) :: x, y, z
        INTEGER(i4) :: n
        
        ierr = 0
        
        DO
            READ(unit_num, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT
            
            line = ADJUSTL(line)
            IF (LEN_TRIM(line) == 0) CYCLE
            IF (line(1:1) == '*') THEN
                BACKSPACE(unit_num)
                EXIT
            END IF
            IF (line(1:2) == '**') CYCLE
            
            ! Parse: node_id, x, y, z
            z = 0.0_wp
            READ(line, *, IOSTAT=ios) node_id, x, y, z
            IF (ios /= 0) THEN
                ! Try 2D
                READ(line, *, IOSTAT=ios) node_id, x, y
                IF (ios /= 0) CYCLE
            END IF
            
            n = model%num_nodes + 1
            IF (n > MAX_NODES) THEN
                ierr = -2
                WRITE(*,'(A)') 'ERROR: Exceeded maximum nodes'
                RETURN
            END IF
            
            model%num_nodes = n
            model%node_id(n) = node_id
            model%coords(1, n) = x
            model%coords(2, n) = y
            IF (model%cfg%ndim >= 3) model%coords(3, n) = z
            
            IF (node_id > model%max_node_id) model%max_node_id = node_id
        END DO
        
    END SUBROUTINE parse_nodes
    
    !===========================================================================
    ! Parse *ELEMENT data
    !===========================================================================
    SUBROUTINE parse_elements(unit_num, model, elem_type, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(IN) :: elem_type
        INTEGER(i4), INTENT(OUT) :: ierr
        
        CHARACTER(LEN=MAX_LINE) :: line, combined_line
        INTEGER(i4) :: ios, elem_id
        INTEGER(i4) :: nodes(MAX_NNODE_ELEM)
        INTEGER(i4) :: nnode, e, i
        LOGICAL :: need_continuation
        
        ierr = 0
        nnode = nodes_per_element(elem_type)
        
        DO
            READ(unit_num, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT
            
            line = ADJUSTL(line)
            IF (LEN_TRIM(line) == 0) CYCLE
            IF (line(1:1) == '*') THEN
                BACKSPACE(unit_num)
                EXIT
            END IF
            IF (line(1:2) == '**') CYCLE
            
            ! Handle continuation lines
            combined_line = line
            need_continuation = (INDEX(line, ',') == LEN_TRIM(line))
            DO WHILE (need_continuation)
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
                combined_line = TRIM(combined_line) // ' ' // TRIM(ADJUSTL(line))
                need_continuation = (INDEX(line, ',') == LEN_TRIM(line))
            END DO
            
            ! Parse element line: elem_id, node1, node2, ...
            nodes = 0
            CALL parse_int_list(combined_line, elem_id, nodes, nnode)
            
            e = model%num_elements + 1
            IF (e > MAX_ELEMENTS) THEN
                ierr = -3
                WRITE(*,'(A)') 'ERROR: Exceeded maximum elements'
                RETURN
            END IF
            
            model%num_elements = e
            model%elem_id(e) = elem_id
            model%elem_type(e) = elem_type
            model%elem_nnode(e) = nnode
            DO i = 1, nnode
                model%elem_conn(i, e) = nodes(i)
            END DO
        END DO
        
    END SUBROUTINE parse_elements
    
    !===========================================================================
    ! Parse comma-separated integer list
    !===========================================================================
    SUBROUTINE parse_int_list(line, first_val, rest, max_rest)
        CHARACTER(LEN=*), INTENT(IN) :: line
        INTEGER(i4), INTENT(OUT) :: first_val
        INTEGER(i4), INTENT(OUT) :: rest(:)
        INTEGER(i4), INTENT(IN) :: max_rest
        
        CHARACTER(LEN=MAX_LINE) :: work
        INTEGER(i4) :: ios, i, pos, comma
        CHARACTER(LEN=32) :: token
        
        work = ADJUSTL(line)
        rest = 0
        
        ! Get first value
        comma = INDEX(work, ',')
        IF (comma > 0) THEN
            token = work(1:comma-1)
            work = ADJUSTL(work(comma+1:))
        ELSE
            token = work
            work = ''
        END IF
        READ(token, *, IOSTAT=ios) first_val
        IF (ios /= 0) first_val = 0
        
        ! Get rest
        i = 0
        DO WHILE (LEN_TRIM(work) > 0 .AND. i < max_rest)
            comma = INDEX(work, ',')
            IF (comma > 0) THEN
                token = work(1:comma-1)
                work = ADJUSTL(work(comma+1:))
            ELSE
                token = work
                work = ''
            END IF
            
            i = i + 1
            READ(token, *, IOSTAT=ios) rest(i)
            IF (ios /= 0) rest(i) = 0
        END DO
        
    END SUBROUTINE parse_int_list
    
    !===========================================================================
    ! Parse *ELASTIC material data
    !===========================================================================
    SUBROUTINE parse_elastic(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        
        CHARACTER(LEN=MAX_LINE) :: line
        INTEGER(i4) :: ios
        
        ierr = 0
        
        READ(unit_num, '(A)', IOSTAT=ios) line
        IF (ios /= 0) RETURN
        
        line = ADJUSTL(line)
        IF (line(1:1) == '*') THEN
            BACKSPACE(unit_num)
            RETURN
        END IF
        
        READ(line, *, IOSTAT=ios) model%E, model%nu
        
    END SUBROUTINE parse_elastic
    
    !===========================================================================
    ! Parse *BOUNDARY data
    !===========================================================================
    SUBROUTINE parse_boundary(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        
        CHARACTER(LEN=MAX_LINE) :: line
        INTEGER(i4) :: ios, node_id, dof1, dof2, d
        REAL(wp) :: val
        INTEGER(i4) :: n
        
        ierr = 0
        
        DO
            READ(unit_num, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT
            
            line = ADJUSTL(line)
            IF (LEN_TRIM(line) == 0) CYCLE
            IF (line(1:1) == '*') THEN
                BACKSPACE(unit_num)
                EXIT
            END IF
            IF (line(1:2) == '**') CYCLE
            
            ! Parse: node, dof1, dof2, value
            val = 0.0_wp
            dof2 = 0
            READ(line, *, IOSTAT=ios) node_id, dof1, dof2, val
            IF (ios /= 0) THEN
                dof2 = dof1
                val = 0.0_wp
                READ(line, *, IOSTAT=ios) node_id, dof1, dof2
                IF (ios /= 0) CYCLE
            END IF
            
            IF (dof2 < dof1) dof2 = dof1
            
            ! Add BCs for DOF range
            DO d = dof1, dof2
                n = model%num_bc + 1
                IF (n > MAX_BC) THEN
                    ierr = -4
                    RETURN
                END IF
                model%num_bc = n
                model%bc_node(n) = node_id
                model%bc_dof(n) = d
                model%bc_val(n) = val
            END DO
        END DO
        
    END SUBROUTINE parse_boundary
    
    !===========================================================================
    ! Parse *CLOAD data
    !===========================================================================
    SUBROUTINE parse_cload(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        
        CHARACTER(LEN=MAX_LINE) :: line
        INTEGER(i4) :: ios, node_id, dof
        REAL(wp) :: val
        INTEGER(i4) :: n
        
        ierr = 0
        
        DO
            READ(unit_num, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT
            
            line = ADJUSTL(line)
            IF (LEN_TRIM(line) == 0) CYCLE
            IF (line(1:1) == '*') THEN
                BACKSPACE(unit_num)
                EXIT
            END IF
            IF (line(1:2) == '**') CYCLE
            
            ! Parse: node, dof, value
            READ(line, *, IOSTAT=ios) node_id, dof, val
            IF (ios /= 0) CYCLE
            
            n = model%num_loads + 1
            IF (n > MAX_LOADS) THEN
                ierr = -5
                RETURN
            END IF
            model%num_loads = n
            model%load_node(n) = node_id
            model%load_dof(n) = dof
            model%load_val(n) = val
        END DO
        
    END SUBROUTINE parse_cload
    
    !===========================================================================
    ! Parse *STATIC parameters
    !===========================================================================
    SUBROUTINE parse_static_params(line, model)
        CHARACTER(LEN=*), INTENT(IN) :: line
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        
        ! Default values already set
        ! Could parse: initial_inc, time_period from next data line
        
    END SUBROUTINE parse_static_params
    
    !===========================================================================
    ! Build node ID mapping (original internal index)
    !===========================================================================
    SUBROUTINE build_node_mapping(model)
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4) :: i
        
        IF (model%max_node_id <= 0) RETURN
        
        ALLOCATE(model%node_map(model%max_node_id))
        model%node_map = 0
        
        DO i = 1, model%num_nodes
            IF (model%node_id(i) > 0 .AND. model%node_id(i) <= model%max_node_id) THEN
                model%node_map(model%node_id(i)) = i
            END IF
        END DO
        
    END SUBROUTINE build_node_mapping
    
    !===========================================================================
    ! Helper: Get coordinates array for solver
    !===========================================================================
    SUBROUTINE parser_get_coords(model, coords, num_nodes, ndim)
        TYPE(UF_ParsedModel), INTENT(IN) :: model
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: coords(:,:)
        INTEGER(i4), INTENT(OUT) :: num_nodes, ndim
        
        num_nodes = model%num_nodes
        ndim = model%cfg%ndim
        
        ALLOCATE(coords(ndim, num_nodes))
        coords = model%coords(:, 1:num_nodes)
        
    END SUBROUTINE parser_get_coords
    
    !===========================================================================
    ! Helper: Get connectivity array (remapped to internal indices)
    !===========================================================================
    SUBROUTINE parser_get_conn(model, conn, num_elements, max_nnode)
        TYPE(UF_ParsedModel), INTENT(IN) :: model
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: conn(:,:)
        INTEGER(i4), INTENT(OUT) :: num_elements, max_nnode
        INTEGER(i4) :: ie, in, orig_node, internal_idx
        
        num_elements = model%num_elements
        max_nnode = MAXVAL(model%elem_nnode(1:num_elements))
        
        ALLOCATE(conn(max_nnode, num_elements))
        conn = 0
        
        DO ie = 1, num_elements
            DO in = 1, model%elem_nnode(ie)
                orig_node = model%elem_conn(in, ie)
                IF (orig_node > 0 .AND. orig_node <= model%max_node_id) THEN
                    internal_idx = model%node_map(orig_node)
                    conn(in, ie) = internal_idx
                END IF
            END DO
        END DO
        
    END SUBROUTINE parser_get_conn
    
    !===========================================================================
    ! Helper: Get element types
    !===========================================================================
    SUBROUTINE parser_get_elem_types(model, elem_types)
        TYPE(UF_ParsedModel), INTENT(IN) :: model
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: elem_types(:)
        
        ALLOCATE(elem_types(model%num_elements))
        elem_types = model%elem_type(1:model%num_elements)
        
    END SUBROUTINE parser_get_elem_types
    
    !===========================================================================
    ! Helper: Get BC DOF indices (global DOF numbers)
    !===========================================================================
    SUBROUTINE parser_get_bc_dofs(model, dof_per_node, bc_dofs, bc_vals, num_bc)
        TYPE(UF_ParsedModel), INTENT(IN) :: model
        INTEGER(i4), INTENT(IN) :: dof_per_node
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: bc_dofs(:)
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: bc_vals(:)
        INTEGER(i4), INTENT(OUT) :: num_bc
        
        INTEGER(i4) :: i, orig_node, internal_idx, global_dof
        
        num_bc = model%num_bc
        ALLOCATE(bc_dofs(num_bc), bc_vals(num_bc))
        
        DO i = 1, num_bc
            orig_node = model%bc_node(i)
            IF (orig_node > 0 .AND. orig_node <= model%max_node_id) THEN
                internal_idx = model%node_map(orig_node)
                global_dof = (internal_idx - 1) * dof_per_node + model%bc_dof(i)
                bc_dofs(i) = global_dof
            ELSE
                bc_dofs(i) = 0
            END IF
            bc_vals(i) = model%bc_val(i)
        END DO
        
    END SUBROUTINE parser_get_bc_dofs
    
    !===========================================================================
    ! Helper: Get BC values only
    !===========================================================================
    SUBROUTINE parser_get_bc_vals(model, bc_vals)
        TYPE(UF_ParsedModel), INTENT(IN) :: model
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: bc_vals(:)
        
        ALLOCATE(bc_vals(model%num_bc))
        bc_vals = model%bc_val(1:model%num_bc)
        
    END SUBROUTINE parser_get_bc_vals
    
    !===========================================================================
    ! Helper: Get loads (node_dof, value)
    !===========================================================================
    SUBROUTINE parser_get_loads(model, dof_per_node, load_dofs, load_vals, num_loads)
        TYPE(UF_ParsedModel), INTENT(IN) :: model
        INTEGER(i4), INTENT(IN) :: dof_per_node
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: load_dofs(:)
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: load_vals(:)
        INTEGER(i4), INTENT(OUT) :: num_loads
        
        INTEGER(i4) :: i, orig_node, internal_idx, global_dof
        
        num_loads = model%num_loads
        ALLOCATE(load_dofs(num_loads), load_vals(num_loads))
        
        DO i = 1, num_loads
            orig_node = model%load_node(i)
            IF (orig_node > 0 .AND. orig_node <= model%max_node_id) THEN
                internal_idx = model%node_map(orig_node)
                global_dof = (internal_idx - 1) * dof_per_node + model%load_dof(i)
                load_dofs(i) = global_dof
            ELSE
                load_dofs(i) = 0
            END IF
            load_vals(i) = model%load_val(i)
        END DO
        
    END SUBROUTINE parser_get_loads
    
    !===========================================================================
    ! Destroy parser and free memory
    !===========================================================================
    SUBROUTINE parser_destroy(model)
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        CALL model%destroy()
    END SUBROUTINE parser_destroy

    !===========================================================================
    ! Parse *NSET
    !===========================================================================
    SUBROUTINE parse_nset(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        ! TODO: Implement NSET parsing, store in new model%nsets array
        ierr = 0
    END SUBROUTINE parse_nset
    
    !===========================================================================
    ! Parse *ELSET
    !===========================================================================
    SUBROUTINE parse_elset(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        ! TODO: Implement ELSET parsing
        ierr = 0
    END SUBROUTINE parse_elset
    
    !===========================================================================
    ! Parse *PLASTIC
    !===========================================================================
    SUBROUTINE parse_plastic(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        ! TODO: Read yield stress, plastic strain
        ierr = 0
    END SUBROUTINE parse_plastic
    
    !===========================================================================
    ! Parse *DENSITY
    !===========================================================================
    SUBROUTINE parse_density(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        REAL(wp) :: rho
        READ(unit_num, *) rho
        model%rho = rho
        ierr = 0
    END SUBROUTINE parse_density
    
    !===========================================================================
    ! Parse *AMPLITUDE
    !===========================================================================
    SUBROUTINE parse_amplitude(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        ! TODO: Read amplitude name, type, data
        ierr = 0
    END SUBROUTINE parse_amplitude
    
    !===========================================================================
    ! Parse *SECTION (SOLID/SHELL)
    !===========================================================================
    SUBROUTINE parse_section(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        ! TODO: Assign material to elset, thickness for shell
        ierr = 0
    END SUBROUTINE parse_section
    
    !===========================================================================
    ! Parse *DLOAD
    !===========================================================================
    SUBROUTINE parse_dload(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        ! TODO: Parse distributed loads on elements
        ierr = 0
    END SUBROUTINE parse_dload
    
    !===========================================================================
    ! Parse *INITIAL CONDITIONS
    !===========================================================================
    SUBROUTINE parse_initial_conditions(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        ! TODO: Parse initial stress, temperature, etc.
        ierr = 0
    END SUBROUTINE parse_initial_conditions
    
    !===========================================================================
    ! Parse *DYNAMIC parameters
    !===========================================================================
    SUBROUTINE parse_dynamic_params(line, model)
        CHARACTER(LEN=*), INTENT(IN) :: line
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        ! TODO: Parse time period, increments for dynamic analysis
    END SUBROUTINE parse_dynamic_params
    
    !===========================================================================
    ! Parse *OUTPUT
    !===========================================================================
    SUBROUTINE parse_output(unit_num, model, ierr)
        INTEGER(i4), INTENT(IN) :: unit_num
        TYPE(UF_ParsedModel), INTENT(INOUT) :: model
        INTEGER(i4), INTENT(OUT) :: ierr
        ! TODO: Parse output requests (field, history)
        ierr = 0
    END SUBROUTINE parse_output
    
END MODULE MD_Inp_Parse
