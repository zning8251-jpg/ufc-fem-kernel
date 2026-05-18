! LEGACY: Reference only — not conforming to UFC v3 naming convention.
!   This file uses lowercase module/type names without layer prefixes.
!   Do NOT copy directly into ufc_core; use PH_Elem_* naming when porting.
! Element library (template)
module ElemLib
    use IF_Prec_Core, ONLY: wp, i4
    implicit none
    private
    public :: element_data, inp_processor, &
              ELEM_UNKNOWN, ELEM_C3D4, ELEM_C3D8, ELEM_C3D8R, ELEM_C3D8I, &
              ELEM_C3D8H, ELEM_C3D8T, ELEM_C3D10, ELEM_C3D10M, ELEM_C3D10E, &
              ELEM_C3D15, ELEM_C3D20, ELEM_C3D20R, ELEM_C3D20H, ELEM_C3D20T, &
              ELEM_C3D27, ELEM_CPE4, ELEM_CPE4R, ELEM_CPE4T, ELEM_CPS4, &
              ELEM_CPS4R, ELEM_CPS4T, ELEM_CPE3, ELEM_CPS3, ELEM_CPE6, &
              ELEM_CPE6R, ELEM_CPS6, ELEM_CPS6R, ELEM_CPE8, ELEM_CPE8R, &
              ELEM_CPE8T, ELEM_CPS8, ELEM_CPS8R, ELEM_CPS8T, ELEM_CAX4, &
              ELEM_CAX4R, ELEM_CAX4H, ELEM_CAX4T, ELEM_CAX3, ELEM_CAX6, &
              ELEM_CAX6R, ELEM_CAX8, ELEM_CAX8R, ELEM_CAX8T, ELEM_S4, &
              ELEM_S4R, ELEM_S4RS, ELEM_S4T, ELEM_S3, ELEM_STRI3, ELEM_STRI65, &
              ELEM_S6, ELEM_S6R, ELEM_S8, ELEM_S8R, ELEM_S8RT, ELEM_S9R5, &
              ELEM_SC6R, ELEM_SC8R, ELEM_B21, ELEM_B21H, ELEM_B21T, ELEM_B22, &
              ELEM_B22H, ELEM_B31, ELEM_B31H, ELEM_B31OS, ELEM_B31T, ELEM_B31EX, &
              ELEM_B32, ELEM_B32H, ELEM_B32OS, ELEM_B33, ELEM_B33H, ELEM_B34, &
              ELEM_B34H, ELEM_M3D4, ELEM_M3D4R, ELEM_M3D3, ELEM_M3D3R, ELEM_M3D6, &
              ELEM_M3D6R, ELEM_M3D8, ELEM_M3D8R, ELEM_M2D4, ELEM_M2D4R, ELEM_M2D3, &
              ELEM_M2D3R, ELEM_T2D2, ELEM_T2D2H, ELEM_T2D2T, ELEM_T2D3, ELEM_T2D3H, &
              ELEM_T3D2, ELEM_T3D2H, ELEM_T3D2T, ELEM_T3D3, ELEM_T3D3H, ELEM_DC1D2, &
              ELEM_DC1D3, ELEM_DC2D3, ELEM_DC2D4, ELEM_DC2D6, ELEM_DC2D8, ELEM_DC3D4, &
              ELEM_DC3D6, ELEM_DC3D8, ELEM_DC3D10, ELEM_DC3D15, ELEM_DC3D20, ELEM_AC1D2, &
              ELEM_AC1D3, ELEM_AC2D3, ELEM_AC2D4, ELEM_AC2D6, ELEM_AC2D8, ELEM_AC3D4, &
              ELEM_AC3D6, ELEM_AC3D8, ELEM_AC3D10, ELEM_AC3D15, ELEM_AC3D20

    ! Constants
    integer, parameter :: max_elements = 100000
    integer, parameter :: max_nodes_per_elem = 100
    integer, parameter :: max_faces_per_elem = 6
    integer, parameter :: max_edges_per_elem = 12
    integer, parameter :: max_nodes_per_face = 9
    integer, parameter :: max_nodes_per_edge = 3

    ! Element type ids (121 kinds)
    integer, parameter :: &
        ELEM_UNKNOWN = 0, &
        ! 3D solid
        ELEM_C3D4 = 1, ELEM_C3D8 = 2, ELEM_C3D8R = 3, ELEM_C3D8I = 4, &
        ELEM_C3D8H = 5, ELEM_C3D8T = 6, ELEM_C3D10 = 7, ELEM_C3D10M = 8, &
        ELEM_C3D10E = 9, ELEM_C3D15 = 10, ELEM_C3D20 = 11, ELEM_C3D20R = 12, &
        ELEM_C3D20H = 13, ELEM_C3D20T = 14, ELEM_C3D27 = 15, &
        ! 2D solid
        ELEM_CPE4 = 16, ELEM_CPE4R = 17, ELEM_CPE4T = 18, ELEM_CPS4 = 19, &
        ELEM_CPS4R = 20, ELEM_CPS4T = 21, ELEM_CPE3 = 22, ELEM_CPS3 = 23, &
        ELEM_CPE6 = 24, ELEM_CPE6R = 25, ELEM_CPS6 = 26, ELEM_CPS6R = 27, &
        ELEM_CPE8 = 28, ELEM_CPE8R = 29, ELEM_CPE8T = 30, ELEM_CPS8 = 31, &
        ELEM_CPS8R = 32, ELEM_CPS8T = 33, &
        ! Axisymmetric solid
        ELEM_CAX4 = 34, ELEM_CAX4R = 35, ELEM_CAX4H = 36, ELEM_CAX4T = 37, &
        ELEM_CAX3 = 38, ELEM_CAX6 = 39, ELEM_CAX6R = 40, ELEM_CAX8 = 41, &
        ELEM_CAX8R = 42, ELEM_CAX8T = 43, &
        ! Shell
        ELEM_S4 = 44, ELEM_S4R = 45, ELEM_S4RS = 46, ELEM_S4T = 47, &
        ELEM_S3 = 48, ELEM_STRI3 = 49, ELEM_STRI65 = 50, ELEM_S6 = 51, &
        ELEM_S6R = 52, ELEM_S8 = 53, ELEM_S8R = 54, ELEM_S8RT = 55, &
        ELEM_S9R5 = 56, ELEM_SC6R = 57, ELEM_SC8R = 58, &
        ! Beam
        ELEM_B21 = 59, ELEM_B21H = 60, ELEM_B21T = 61, ELEM_B22 = 62, &
        ELEM_B22H = 63, ELEM_B31 = 64, ELEM_B31H = 65, ELEM_B31OS = 66, &
        ELEM_B31T = 67, ELEM_B31EX = 68, ELEM_B32 = 69, ELEM_B32H = 70, &
        ELEM_B32OS = 71, ELEM_B33 = 72, ELEM_B33H = 73, ELEM_B34 = 74, &
        ELEM_B34H = 75, &
        ! Membrane
        ELEM_M3D4 = 76, ELEM_M3D4R = 77, ELEM_M3D3 = 78, ELEM_M3D3R = 79, &
        ELEM_M3D6 = 80, ELEM_M3D6R = 81, ELEM_M3D8 = 82, ELEM_M3D8R = 83, &
        ELEM_M2D4 = 84, ELEM_M2D4R = 85, ELEM_M2D3 = 86, ELEM_M2D3R = 87, &
        ! Truss
        ELEM_T2D2 = 88, ELEM_T2D2H = 89, ELEM_T2D2T = 90, ELEM_T2D3 = 91, &
        ELEM_T2D3H = 92, ELEM_T3D2 = 93, ELEM_T3D2H = 94, ELEM_T3D2T = 95, &
        ELEM_T3D3 = 96, ELEM_T3D3H = 97, &
        ! Thermal
        ELEM_DC1D2 = 98, ELEM_DC1D3 = 99, ELEM_DC2D3 = 100, ELEM_DC2D4 = 101, &
        ELEM_DC2D6 = 102, ELEM_DC2D8 = 103, ELEM_DC3D4 = 104, ELEM_DC3D6 = 105, &
        ELEM_DC3D8 = 106, ELEM_DC3D10 = 107, ELEM_DC3D15 = 108, ELEM_DC3D20 = 109, &
        ! Acoustic
        ELEM_AC1D2 = 110, ELEM_AC1D3 = 111, ELEM_AC2D3 = 112, ELEM_AC2D4 = 113, &
        ELEM_AC2D6 = 114, ELEM_AC2D8 = 115, ELEM_AC3D4 = 116, ELEM_AC3D6 = 117, &
        ELEM_AC3D8 = 118, ELEM_AC3D10 = 119, ELEM_AC3D15 = 120, ELEM_AC3D20 = 121

    ! Static element-type metadata
    type element_type_info
        integer :: etype        ! type code
        integer :: nnode        ! node count
        integer :: nface        ! num faces
        integer :: nedge        ! num edges
        integer :: dimension    ! dim (1/2/3)
        integer :: analysis_type ! analysis kind (0=gen,1=impl,2=expl)
        character(len=10) :: name  ! type name
        character(len=50) :: description ! description
        integer, allocatable :: face_nodes(:,:)  ! face connectivity (nface x max_nodes_per_face)
        integer, allocatable :: edge_nodes(:,:)  ! edge connectivity (nedge x max_nodes_per_edge)
    end type element_type_info

    ! Per-element data
    type element_data
        integer :: id                     ! element id
        integer :: etype                  ! type id (ELEM_*)
        integer, allocatable :: nodes(:)  ! node list
        integer, allocatable :: face_nodes(:,:)  ! face nodes
        integer, allocatable :: edge_nodes(:,:)  ! edge nodes
        integer, allocatable :: line_nodes(:,:)  ! line connectivity
        integer :: ndim                  ! dim 1/2/3
        logical :: reduced_integration    ! reduced integration
    end type element_data

    ! INP reader stub
    type inp_processor
        character(len=256) :: filename    ! INP path
        integer :: n_elements             ! num elements
        type(element_data), allocatable :: elements(:)  ! element array
        type(element_type_info), allocatable :: elem_types(:)  ! type table
        integer :: n_element_types        ! num types
    contains
        procedure :: initialize_element_types  ! init type table
        procedure :: read_inp_file             ! read INP
        procedure :: identify_element_type     ! classify element
        procedure :: extract_geometry_info     ! extract geometry
        procedure :: print_element_summary     ! print summary
        procedure :: print_detailed_results    ! print details
        procedure :: cleanup                   ! cleanup
    end type inp_processor

contains

    ! ---------------------------- init type table ----------------------------
    subroutine initialize_element_types(this)
        class(inp_processor), intent(inout) :: this
        integer :: i
        
        this%n_element_types = 121  ! count = 121
        allocate(this%elem_types(this%n_element_types))
        
        ! default to unknown
        do i = 1, this%n_element_types
            this%elem_types(i)%etype = ELEM_UNKNOWN
            this%elem_types(i)%nnode = 0
            this%elem_types(i)%nface = 0
            this%elem_types(i)%nedge = 0
            this%elem_types(i)%dimension = 0
            this%elem_types(i)%analysis_type = 0
            this%elem_types(i)%name = 'UNKNOWN'
            this%elem_types(i)%description = 'Unknown element type'
        end do
        
        ! register families
        call init_3d_solid_elements(this%elem_types)    ! 3D solid
        call init_2d_solid_elements(this%elem_types)    ! 2D solid
        call init_axisymmetric_elements(this%elem_types)
        call init_shell_elements(this%elem_types)        ! Shell
        call init_beam_elements(this%elem_types)        ! Beam
        call init_membrane_elements(this%elem_types)     ! Membrane
        call init_truss_elements(this%elem_types)       ! Truss
        call init_thermal_elements(this%elem_types)      ! Thermal
        call init_acoustic_elements(this%elem_types)     ! Acoustic
    end subroutine initialize_element_types

    ! ---------------------------- init 3D solids ----------------------------
    subroutine init_3d_solid_elements(elem_types)
        type(element_type_info), intent(inout) :: elem_types(:)
        
        ! C3D4 - 4-node tet
        elem_types(ELEM_C3D4)%etype = ELEM_C3D4
        elem_types(ELEM_C3D4)%name = 'C3D4'
        elem_types(ELEM_C3D4)%nnode = 4
        elem_types(ELEM_C3D4)%nface = 4
        elem_types(ELEM_C3D4)%nedge = 6
        elem_types(ELEM_C3D4)%dimension = 3
        elem_types(ELEM_C3D4)%analysis_type = 1
        elem_types(ELEM_C3D4)%description = '4-node linear tetrahedron'
        allocate(elem_types(ELEM_C3D4)%face_nodes(4,3))
        elem_types(ELEM_C3D4)%face_nodes = reshape([1,2,3, 1,2,4, 2,3,4, 1,3,4], [4,3])  ! 4 faces x 3 nodes
        allocate(elem_types(ELEM_C3D4)%edge_nodes(6,2))
        elem_types(ELEM_C3D4)%edge_nodes = reshape([1,2, 2,3, 3,1, 1,4, 2,4, 3,4], [6,2])  ! 6 edges x 2 nodes

        ! C3D8 - 8-node hex
        elem_types(ELEM_C3D8)%etype = ELEM_C3D8
        elem_types(ELEM_C3D8)%name = 'C3D8'
        elem_types(ELEM_C3D8)%nnode = 8
        elem_types(ELEM_C3D8)%nface = 6
        elem_types(ELEM_C3D8)%nedge = 12
        elem_types(ELEM_C3D8)%dimension = 3
        elem_types(ELEM_C3D8)%analysis_type = 1
        elem_types(ELEM_C3D8)%description = '8-node linear hexahedron'
        allocate(elem_types(ELEM_C3D8)%face_nodes(6,4))
        elem_types(ELEM_C3D8)%face_nodes = reshape([ &
            1,2,3,4, 5,6,7,8, 1,2,6,5, 2,3,7,6, 3,4,8,7, 4,1,5,8], [6,4])
        allocate(elem_types(ELEM_C3D8)%edge_nodes(12,2))
        elem_types(ELEM_C3D8)%edge_nodes = reshape([ &
            1,2, 2,3, 3,4, 4,1, 5,6, 6,7, 7,8, 8,5, 1,5, 2,6, 3,7, 4,8], [12,2])


        elem_types(ELEM_C3D8R)%etype = ELEM_C3D8R
        elem_types(ELEM_C3D8R)%name = 'C3D8R'
        elem_types(ELEM_C3D8R)%nnode = 8
        elem_types(ELEM_C3D8R)%nface = 6
        elem_types(ELEM_C3D8R)%nedge = 12
        elem_types(ELEM_C3D8R)%dimension = 3
        elem_types(ELEM_C3D8R)%analysis_type = 2
        elem_types(ELEM_C3D8R)%description = '8-node reduced integration hexahedron'
        allocate(elem_types(ELEM_C3D8R)%face_nodes(6,4))
        elem_types(ELEM_C3D8R)%face_nodes = elem_types(ELEM_C3D8)%face_nodes
        allocate(elem_types(ELEM_C3D8R)%edge_nodes(12,2))
        elem_types(ELEM_C3D8R)%edge_nodes = elem_types(ELEM_C3D8)%edge_nodes


        elem_types(ELEM_C3D8I)%etype = ELEM_C3D8I
        elem_types(ELEM_C3D8I)%name = 'C3D8I'
        elem_types(ELEM_C3D8I)%nnode = 8
        elem_types(ELEM_C3D8I)%nface = 6
        elem_types(ELEM_C3D8I)%nedge = 12
        elem_types(ELEM_C3D8I)%dimension = 3
        elem_types(ELEM_C3D8I)%analysis_type = 1
        elem_types(ELEM_C3D8I)%description = '8-node incompatible modes hexahedron'
        allocate(elem_types(ELEM_C3D8I)%face_nodes(6,4))
        elem_types(ELEM_C3D8I)%face_nodes = elem_types(ELEM_C3D8)%face_nodes
        allocate(elem_types(ELEM_C3D8I)%edge_nodes(12,2))
        elem_types(ELEM_C3D8I)%edge_nodes = elem_types(ELEM_C3D8)%edge_nodes


        elem_types(ELEM_C3D8H)%etype = ELEM_C3D8H
        elem_types(ELEM_C3D8H)%name = 'C3D8H'
        elem_types(ELEM_C3D8H)%nnode = 8
        elem_types(ELEM_C3D8H)%nface = 6
        elem_types(ELEM_C3D8H)%nedge = 12
        elem_types(ELEM_C3D8H)%dimension = 3
        elem_types(ELEM_C3D8H)%analysis_type = 1
        elem_types(ELEM_C3D8H)%description = '8-node hybrid hexahedron'
        allocate(elem_types(ELEM_C3D8H)%face_nodes(6,4))
        elem_types(ELEM_C3D8H)%face_nodes = elem_types(ELEM_C3D8)%face_nodes
        allocate(elem_types(ELEM_C3D8H)%edge_nodes(12,2))
        elem_types(ELEM_C3D8H)%edge_nodes = elem_types(ELEM_C3D8)%edge_nodes


        elem_types(ELEM_C3D8T)%etype = ELEM_C3D8T
        elem_types(ELEM_C3D8T)%name = 'C3D8T'
        elem_types(ELEM_C3D8T)%nnode = 8
        elem_types(ELEM_C3D8T)%nface = 6
        elem_types(ELEM_C3D8T)%nedge = 12
        elem_types(ELEM_C3D8T)%dimension = 3
        elem_types(ELEM_C3D8T)%analysis_type = 1
        elem_types(ELEM_C3D8T)%description = '8-node coupled temp-displacement hexahedron'
        allocate(elem_types(ELEM_C3D8T)%face_nodes(6,4))
        elem_types(ELEM_C3D8T)%face_nodes = elem_types(ELEM_C3D8)%face_nodes
        allocate(elem_types(ELEM_C3D8T)%edge_nodes(12,2))
        elem_types(ELEM_C3D8T)%edge_nodes = elem_types(ELEM_C3D8)%edge_nodes


        elem_types(ELEM_C3D10)%etype = ELEM_C3D10
        elem_types(ELEM_C3D10)%name = 'C3D10'
        elem_types(ELEM_C3D10)%nnode = 10
        elem_types(ELEM_C3D10)%nface = 4
        elem_types(ELEM_C3D10)%nedge = 6
        elem_types(ELEM_C3D10)%dimension = 3
        elem_types(ELEM_C3D10)%analysis_type = 1
        elem_types(ELEM_C3D10)%description = '10-node quadratic tetrahedron'
        allocate(elem_types(ELEM_C3D10)%face_nodes(4,6))
        elem_types(ELEM_C3D10)%face_nodes = reshape([ &
            1,2,3,4,5,6, 1,2,4,7,8,9, 2,3,4,5,9,10, 1,3,4,6,8,10], [4,6])
        allocate(elem_types(ELEM_C3D10)%edge_nodes(6,3))
        elem_types(ELEM_C3D10)%edge_nodes = reshape([1,2,5, 2,3,6, 3,1,4, 1,4,8, 2,4,9, 3,4,10], [6,3])


        elem_types(ELEM_C3D10M)%etype = ELEM_C3D10M
        elem_types(ELEM_C3D10M)%name = 'C3D10M'
        elem_types(ELEM_C3D10M)%nnode = 10
        elem_types(ELEM_C3D10M)%nface = 4
        elem_types(ELEM_C3D10M)%nedge = 6
        elem_types(ELEM_C3D10M)%dimension = 3
        elem_types(ELEM_C3D10M)%analysis_type = 2
        elem_types(ELEM_C3D10M)%description = '10-node modified quadratic tetrahedron'
        allocate(elem_types(ELEM_C3D10M)%face_nodes(4,6))
        elem_types(ELEM_C3D10M)%face_nodes = elem_types(ELEM_C3D10)%face_nodes
        allocate(elem_types(ELEM_C3D10M)%edge_nodes(6,3))
        elem_types(ELEM_C3D10M)%edge_nodes = elem_types(ELEM_C3D10)%edge_nodes


        elem_types(ELEM_C3D10E)%etype = ELEM_C3D10E
        elem_types(ELEM_C3D10E)%name = 'C3D10E'
        elem_types(ELEM_C3D10E)%nnode = 10
        elem_types(ELEM_C3D10E)%nface = 4
        elem_types(ELEM_C3D10E)%nedge = 6
        elem_types(ELEM_C3D10E)%dimension = 3
        elem_types(ELEM_C3D10E)%analysis_type = 2
        elem_types(ELEM_C3D10E)%description = '10-node explicit tetrahedron'
        allocate(elem_types(ELEM_C3D10E)%face_nodes(4,6))
        elem_types(ELEM_C3D10E)%face_nodes = elem_types(ELEM_C3D10)%face_nodes
        allocate(elem_types(ELEM_C3D10E)%edge_nodes(6,3))
        elem_types(ELEM_C3D10E)%edge_nodes = elem_types(ELEM_C3D10)%edge_nodes


        elem_types(ELEM_C3D15)%etype = ELEM_C3D15
        elem_types(ELEM_C3D15)%name = 'C3D15'
        elem_types(ELEM_C3D15)%nnode = 15
        elem_types(ELEM_C3D15)%nface = 5
        elem_types(ELEM_C3D15)%nedge = 9
        elem_types(ELEM_C3D15)%dimension = 3
        elem_types(ELEM_C3D15)%analysis_type = 1
        elem_types(ELEM_C3D15)%description = '15-node quadratic wedge'
        allocate(elem_types(ELEM_C3D15)%face_nodes(5,8))
        elem_types(ELEM_C3D15)%face_nodes = reshape([ &
            1,2,3,7,8,9,0,0, 4,5,6,10,11,12,0,0, &
            1,2,5,4,7,14,10,13, 2,3,6,5,8,15,11,14, 3,1,4,6,9,13,12,15], [5,8])


        elem_types(ELEM_C3D20)%etype = ELEM_C3D20
        elem_types(ELEM_C3D20)%name = 'C3D20'
        elem_types(ELEM_C3D20)%nnode = 20
        elem_types(ELEM_C3D20)%nface = 6
        elem_types(ELEM_C3D20)%nedge = 12
        elem_types(ELEM_C3D20)%dimension = 3
        elem_types(ELEM_C3D20)%analysis_type = 1
        elem_types(ELEM_C3D20)%description = '20-node quadratic hexahedron'
        allocate(elem_types(ELEM_C3D20)%face_nodes(6,8))
        elem_types(ELEM_C3D20)%face_nodes = reshape([ &
            1,2,3,4,9,10,11,12, 5,6,7,8,13,14,15,16, &
            1,2,6,5,9,18,13,17, 2,3,7,6,10,19,14,18, 3,4,8,7,11,20,15,19, 4,1,5,8,12,17,16,20], [6,8])


        elem_types(ELEM_C3D20R)%etype = ELEM_C3D20R
        elem_types(ELEM_C3D20R)%name = 'C3D20R'
        elem_types(ELEM_C3D20R)%nnode = 20
        elem_types(ELEM_C3D20R)%nface = 6
        elem_types(ELEM_C3D20R)%nedge = 12
        elem_types(ELEM_C3D20R)%dimension = 3
        elem_types(ELEM_C3D20R)%analysis_type = 1
        elem_types(ELEM_C3D20R)%description = '20-node reduced integration hexahedron'
        allocate(elem_types(ELEM_C3D20R)%face_nodes(6,8))
        elem_types(ELEM_C3D20R)%face_nodes = elem_types(ELEM_C3D20)%face_nodes


        elem_types(ELEM_C3D20H)%etype = ELEM_C3D20H
        elem_types(ELEM_C3D20H)%name = 'C3D20H'
        elem_types(ELEM_C3D20H)%nnode = 20
        elem_types(ELEM_C3D20H)%nface = 6
        elem_types(ELEM_C3D20H)%nedge = 12
        elem_types(ELEM_C3D20H)%dimension = 3
        elem_types(ELEM_C3D20H)%analysis_type = 1
        elem_types(ELEM_C3D20H)%description = '20-node hybrid hexahedron'
        allocate(elem_types(ELEM_C3D20H)%face_nodes(6,8))
        elem_types(ELEM_C3D20H)%face_nodes = elem_types(ELEM_C3D20)%face_nodes


        elem_types(ELEM_C3D20T)%etype = ELEM_C3D20T
        elem_types(ELEM_C3D20T)%name = 'C3D20T'
        elem_types(ELEM_C3D20T)%nnode = 20
        elem_types(ELEM_C3D20T)%nface = 6
        elem_types(ELEM_C3D20T)%nedge = 12
        elem_types(ELEM_C3D20T)%dimension = 3
        elem_types(ELEM_C3D20T)%analysis_type = 1
        elem_types(ELEM_C3D20T)%description = '20-node coupled temp-displacement hexahedron'
        allocate(elem_types(ELEM_C3D20T)%face_nodes(6,8))
        elem_types(ELEM_C3D20T)%face_nodes = elem_types(ELEM_C3D20)%face_nodes


        elem_types(ELEM_C3D27)%etype = ELEM_C3D27
        elem_types(ELEM_C3D27)%name = 'C3D27'
        elem_types(ELEM_C3D27)%nnode = 27
        elem_types(ELEM_C3D27)%nface = 6
        elem_types(ELEM_C3D27)%nedge = 12
        elem_types(ELEM_C3D27)%dimension = 3
        elem_types(ELEM_C3D27)%analysis_type = 1
        elem_types(ELEM_C3D27)%description = '27-node quadratic hexahedron'
        allocate(elem_types(ELEM_C3D27)%face_nodes(6,9))
        elem_types(ELEM_C3D27)%face_nodes = reshape([ &
            1,2,3,4,9,10,11,12,21, 5,6,7,8,13,14,15,16,22, &
            1,2,6,5,9,18,13,17,23, 2,3,7,6,10,19,14,18,24, &
            3,4,8,7,11,20,15,19,25, 4,1,5,8,12,17,16,20,26], [6,9])
    end subroutine init_3d_solid_elements

    ! ---------------------------- init 2D solids ----------------------------
    subroutine init_2d_solid_elements(elem_types)
        type(element_type_info), intent(inout) :: elem_types(:)
        

        elem_types(ELEM_CPE4)%etype = ELEM_CPE4
        elem_types(ELEM_CPE4)%name = 'CPE4'
        elem_types(ELEM_CPE4)%nnode = 4
        elem_types(ELEM_CPE4)%nface = 1
        elem_types(ELEM_CPE4)%nedge = 4
        elem_types(ELEM_CPE4)%dimension = 2
        elem_types(ELEM_CPE4)%analysis_type = 1
        elem_types(ELEM_CPE4)%description = '4-node plane strain quadrilateral'
        allocate(elem_types(ELEM_CPE4)%face_nodes(1,4))
        elem_types(ELEM_CPE4)%face_nodes = reshape([1,2,3,4], [1,4])
        allocate(elem_types(ELEM_CPE4)%edge_nodes(4,2))
        elem_types(ELEM_CPE4)%edge_nodes = reshape([1,2, 2,3, 3,4, 4,1], [4,2])


        elem_types(ELEM_CPE4R)%etype = ELEM_CPE4R
        elem_types(ELEM_CPE4R)%name = 'CPE4R'
        elem_types(ELEM_CPE4R)%nnode = 4
        elem_types(ELEM_CPE4R)%nface = 1
        elem_types(ELEM_CPE4R)%nedge = 4
        elem_types(ELEM_CPE4R)%dimension = 2
        elem_types(ELEM_CPE4R)%analysis_type = 2
        elem_types(ELEM_CPE4R)%description = '4-node reduced integration plane strain quadrilateral'
        allocate(elem_types(ELEM_CPE4R)%face_nodes(1,4))
        elem_types(ELEM_CPE4R)%face_nodes = elem_types(ELEM_CPE4)%face_nodes
        allocate(elem_types(ELEM_CPE4R)%edge_nodes(4,2))
        elem_types(ELEM_CPE4R)%edge_nodes = elem_types(ELEM_CPE4)%edge_nodes


        elem_types(ELEM_CPE4T)%etype = ELEM_CPE4T
        elem_types(ELEM_CPE4T)%name = 'CPE4T'
        elem_types(ELEM_CPE4T)%nnode = 4
        elem_types(ELEM_CPE4T)%nface = 1
        elem_types(ELEM_CPE4T)%nedge = 4
        elem_types(ELEM_CPE4T)%dimension = 2
        elem_types(ELEM_CPE4T)%analysis_type = 1
        elem_types(ELEM_CPE4T)%description = '4-node coupled temp-displacement plane strain quadrilateral'
        allocate(elem_types(ELEM_CPE4T)%face_nodes(1,4))
        elem_types(ELEM_CPE4T)%face_nodes = elem_types(ELEM_CPE4)%face_nodes
        allocate(elem_types(ELEM_CPE4T)%edge_nodes(4,2))
        elem_types(ELEM_CPE4T)%edge_nodes = elem_types(ELEM_CPE4)%edge_nodes


        elem_types(ELEM_CPS4)%etype = ELEM_CPS4
        elem_types(ELEM_CPS4)%name = 'CPS4'
        elem_types(ELEM_CPS4)%nnode = 4
        elem_types(ELEM_CPS4)%nface = 1
        elem_types(ELEM_CPS4)%nedge = 4
        elem_types(ELEM_CPS4)%dimension = 2
        elem_types(ELEM_CPS4)%analysis_type = 1
        elem_types(ELEM_CPS4)%description = '4-node plane stress quadrilateral'
        allocate(elem_types(ELEM_CPS4)%face_nodes(1,4))
        elem_types(ELEM_CPS4)%face_nodes = reshape([1,2,3,4], [1,4])
        allocate(elem_types(ELEM_CPS4)%edge_nodes(4,2))
        elem_types(ELEM_CPS4)%edge_nodes = reshape([1,2, 2,3, 3,4, 4,1], [4,2])


        elem_types(ELEM_CPS4R)%etype = ELEM_CPS4R
        elem_types(ELEM_CPS4R)%name = 'CPS4R'
        elem_types(ELEM_CPS4R)%nnode = 4
        elem_types(ELEM_CPS4R)%nface = 1
        elem_types(ELEM_CPS4R)%nedge = 4
        elem_types(ELEM_CPS4R)%dimension = 2
        elem_types(ELEM_CPS4R)%analysis_type = 2
        elem_types(ELEM_CPS4R)%description = '4-node reduced integration plane stress quadrilateral'
        allocate(elem_types(ELEM_CPS4R)%face_nodes(1,4))
        elem_types(ELEM_CPS4R)%face_nodes = elem_types(ELEM_CPS4)%face_nodes
        allocate(elem_types(ELEM_CPS4R)%edge_nodes(4,2))
        elem_types(ELEM_CPS4R)%edge_nodes = elem_types(ELEM_CPS4)%edge_nodes


        elem_types(ELEM_CPS4T)%etype = ELEM_CPS4T
        elem_types(ELEM_CPS4T)%name = 'CPS4T'
        elem_types(ELEM_CPS4T)%nnode = 4
        elem_types(ELEM_CPS4T)%nface = 1
        elem_types(ELEM_CPS4T)%nedge = 4
        elem_types(ELEM_CPS4T)%dimension = 2
        elem_types(ELEM_CPS4T)%analysis_type = 1
        elem_types(ELEM_CPS4T)%description = '4-node coupled temp-displacement plane stress quadrilateral'
        allocate(elem_types(ELEM_CPS4T)%face_nodes(1,4))
        elem_types(ELEM_CPS4T)%face_nodes = elem_types(ELEM_CPS4)%face_nodes
        allocate(elem_types(ELEM_CPS4T)%edge_nodes(4,2))
        elem_types(ELEM_CPS4T)%edge_nodes = elem_types(ELEM_CPS4)%edge_nodes


        elem_types(ELEM_CPE3)%etype = ELEM_CPE3
        elem_types(ELEM_CPE3)%name = 'CPE3'
        elem_types(ELEM_CPE3)%nnode = 3
        elem_types(ELEM_CPE3)%nface = 1
        elem_types(ELEM_CPE3)%nedge = 3
        elem_types(ELEM_CPE3)%dimension = 2
        elem_types(ELEM_CPE3)%analysis_type = 1
        elem_types(ELEM_CPE3)%description = '3-node plane strain triangle'
        allocate(elem_types(ELEM_CPE3)%face_nodes(1,3))
        elem_types(ELEM_CPE3)%face_nodes = reshape([1,2,3], [1,3])
        allocate(elem_types(ELEM_CPE3)%edge_nodes(3,2))
        elem_types(ELEM_CPE3)%edge_nodes = reshape([1,2, 2,3, 3,1], [3,2])


        elem_types(ELEM_CPS3)%etype = ELEM_CPS3
        elem_types(ELEM_CPS3)%name = 'CPS3'
        elem_types(ELEM_CPS3)%nnode = 3
        elem_types(ELEM_CPS3)%nface = 1
        elem_types(ELEM_CPS3)%nedge = 3
        elem_types(ELEM_CPS3)%dimension = 2
        elem_types(ELEM_CPS3)%analysis_type = 1
        elem_types(ELEM_CPS3)%description = '3-node plane stress triangle'
        allocate(elem_types(ELEM_CPS3)%face_nodes(1,3))
        elem_types(ELEM_CPS3)%face_nodes = reshape([1,2,3], [1,3])
        allocate(elem_types(ELEM_CPS3)%edge_nodes(3,2))
        elem_types(ELEM_CPS3)%edge_nodes = reshape([1,2, 2,3, 3,1], [3,2])


        elem_types(ELEM_CPE6)%etype = ELEM_CPE6
        elem_types(ELEM_CPE6)%name = 'CPE6'
        elem_types(ELEM_CPE6)%nnode = 6
        elem_types(ELEM_CPE6)%nface = 1
        elem_types(ELEM_CPE6)%nedge = 3
        elem_types(ELEM_CPE6)%dimension = 2
        elem_types(ELEM_CPE6)%analysis_type = 1
        elem_types(ELEM_CPE6)%description = '6-node quadratic plane strain triangle'
        allocate(elem_types(ELEM_CPE6)%face_nodes(1,6))
        elem_types(ELEM_CPE6)%face_nodes = reshape([1,2,3,4,5,6], [1,6])
        allocate(elem_types(ELEM_CPE6)%edge_nodes(3,3))
        elem_types(ELEM_CPE6)%edge_nodes = reshape([1,2,4, 2,3,5, 3,1,6], [3,3])


        elem_types(ELEM_CPE6R)%etype = ELEM_CPE6R
        elem_types(ELEM_CPE6R)%name = 'CPE6R'
        elem_types(ELEM_CPE6R)%nnode = 6
        elem_types(ELEM_CPE6R)%nface = 1
        elem_types(ELEM_CPE6R)%nedge = 3
        elem_types(ELEM_CPE6R)%dimension = 2
        elem_types(ELEM_CPE6R)%analysis_type = 2
        elem_types(ELEM_CPE6R)%description = '6-node reduced integration plane strain triangle'
        allocate(elem_types(ELEM_CPE6R)%face_nodes(1,6))
        elem_types(ELEM_CPE6R)%face_nodes = elem_types(ELEM_CPE6)%face_nodes
        allocate(elem_types(ELEM_CPE6R)%edge_nodes(3,3))
        elem_types(ELEM_CPE6R)%edge_nodes = elem_types(ELEM_CPE6)%edge_nodes


        elem_types(ELEM_CPS6)%etype = ELEM_CPS6
        elem_types(ELEM_CPS6)%name = 'CPS6'
        elem_types(ELEM_CPS6)%nnode = 6
        elem_types(ELEM_CPS6)%nface = 1
        elem_types(ELEM_CPS6)%nedge = 3
        elem_types(ELEM_CPS6)%dimension = 2
        elem_types(ELEM_CPS6)%analysis_type = 1
        elem_types(ELEM_CPS6)%description = '6-node quadratic plane stress triangle'
        allocate(elem_types(ELEM_CPS6)%face_nodes(1,6))
        elem_types(ELEM_CPS6)%face_nodes = reshape([1,2,3,4,5,6], [1,6])
        allocate(elem_types(ELEM_CPS6)%edge_nodes(3,3))
        elem_types(ELEM_CPS6)%edge_nodes = reshape([1,2,4, 2,3,5, 3,1,6], [3,3])


        elem_types(ELEM_CPS6R)%etype = ELEM_CPS6R
        elem_types(ELEM_CPS6R)%name = 'CPS6R'
        elem_types(ELEM_CPS6R)%nnode = 6
        elem_types(ELEM_CPS6R)%nface = 1
        elem_types(ELEM_CPS6R)%nedge = 3
        elem_types(ELEM_CPS6R)%dimension = 2
        elem_types(ELEM_CPS6R)%analysis_type = 2
        elem_types(ELEM_CPS6R)%description = '6-node reduced integration plane stress triangle'
        allocate(elem_types(ELEM_CPS6R)%face_nodes(1,6))
        elem_types(ELEM_CPS6R)%face_nodes = elem_types(ELEM_CPS6)%face_nodes
        allocate(elem_types(ELEM_CPS6R)%edge_nodes(3,3))
        elem_types(ELEM_CPS6R)%edge_nodes = elem_types(ELEM_CPS6)%edge_nodes


        elem_types(ELEM_CPE8)%etype = ELEM_CPE8
        elem_types(ELEM_CPE8)%name = 'CPE8'
        elem_types(ELEM_CPE8)%nnode = 8
        elem_types(ELEM_CPE8)%nface = 1
        elem_types(ELEM_CPE8)%nedge = 4
        elem_types(ELEM_CPE8)%dimension = 2
        elem_types(ELEM_CPE8)%analysis_type = 1
        elem_types(ELEM_CPE8)%description = '8-node quadratic plane strain quadrilateral'
        allocate(elem_types(ELEM_CPE8)%face_nodes(1,8))
        elem_types(ELEM_CPE8)%face_nodes = reshape([1,2,3,4,5,6,7,8], [1,8])
        allocate(elem_types(ELEM_CPE8)%edge_nodes(4,3))
        elem_types(ELEM_CPE8)%edge_nodes = reshape([1,2,5, 2,3,6, 3,4,7, 4,1,8], [4,3])


        elem_types(ELEM_CPE8R)%etype = ELEM_CPE8R
        elem_types(ELEM_CPE8R)%name = 'CPE8R'
        elem_types(ELEM_CPE8R)%nnode = 8
        elem_types(ELEM_CPE8R)%nface = 1
        elem_types(ELEM_CPE8R)%nedge = 4
        elem_types(ELEM_CPE8R)%dimension = 2
        elem_types(ELEM_CPE8R)%analysis_type = 2
        elem_types(ELEM_CPE8R)%description = '8-node reduced integration plane strain quadrilateral'
        allocate(elem_types(ELEM_CPE8R)%face_nodes(1,8))
        elem_types(ELEM_CPE8R)%face_nodes = elem_types(ELEM_CPE8)%face_nodes
        allocate(elem_types(ELEM_CPE8R)%edge_nodes(4,3))
        elem_types(ELEM_CPE8R)%edge_nodes = elem_types(ELEM_CPE8)%edge_nodes


        elem_types(ELEM_CPE8T)%etype = ELEM_CPE8T
        elem_types(ELEM_CPE8T)%name = 'CPE8T'
        elem_types(ELEM_CPE8T)%nnode = 8
        elem_types(ELEM_CPE8T)%nface = 1
        elem_types(ELEM_CPE8T)%nedge = 4
        elem_types(ELEM_CPE8T)%dimension = 2
        elem_types(ELEM_CPE8T)%analysis_type = 1
        elem_types(ELEM_CPE8T)%description = '8-node coupled temp-displacement plane strain quadrilateral'
        allocate(elem_types(ELEM_CPE8T)%face_nodes(1,8))
        elem_types(ELEM_CPE8T)%face_nodes = elem_types(ELEM_CPE8)%face_nodes
        allocate(elem_types(ELEM_CPE8T)%edge_nodes(4,3))
        elem_types(ELEM_CPE8T)%edge_nodes = elem_types(ELEM_CPE8)%edge_nodes


        elem_types(ELEM_CPS8)%etype = ELEM_CPS8
        elem_types(ELEM_CPS8)%name = 'CPS8'
        elem_types(ELEM_CPS8)%nnode = 8
        elem_types(ELEM_CPS8)%nface = 1
        elem_types(ELEM_CPS8)%nedge = 4
        elem_types(ELEM_CPS8)%dimension = 2
        elem_types(ELEM_CPS8)%analysis_type = 1
        elem_types(ELEM_CPS8)%description = '8-node quadratic plane stress quadrilateral'
        allocate(elem_types(ELEM_CPS8)%face_nodes(1,8))
        elem_types(ELEM_CPS8)%face_nodes = reshape([1,2,3,4,5,6,7,8], [1,8])
        allocate(elem_types(ELEM_CPS8)%edge_nodes(4,3))
        elem_types(ELEM_CPS8)%edge_nodes = reshape([1,2,5, 2,3,6, 3,4,7, 4,1,8], [4,3])


        elem_types(ELEM_CPS8R)%etype = ELEM_CPS8R
        elem_types(ELEM_CPS8R)%name = 'CPS8R'
        elem_types(ELEM_CPS8R)%nnode = 8
        elem_types(ELEM_CPS8R)%nface = 1
        elem_types(ELEM_CPS8R)%nedge = 4
        elem_types(ELEM_CPS8R)%dimension = 2
        elem_types(ELEM_CPS8R)%analysis_type = 2
        elem_types(ELEM_CPS8R)%description = '8-node reduced integration plane stress quadrilateral'
        allocate(elem_types(ELEM_CPS8R)%face_nodes(1,8))
        elem_types(ELEM_CPS8R)%face_nodes = elem_types(ELEM_CPS8)%face_nodes
        allocate(elem_types(ELEM_CPS8R)%edge_nodes(4,3))
        elem_types(ELEM_CPS8R)%edge_nodes = elem_types(ELEM_CPS8)%edge_nodes


        elem_types(ELEM_CPS8T)%etype = ELEM_CPS8T
        elem_types(ELEM_CPS8T)%name = 'CPS8T'
        elem_types(ELEM_CPS8T)%nnode = 8
        elem_types(ELEM_CPS8T)%nface = 1
        elem_types(ELEM_CPS8T)%nedge = 4
        elem_types(ELEM_CPS8T)%dimension = 2
        elem_types(ELEM_CPS8T)%analysis_type = 1
        elem_types(ELEM_CPS8T)%description = '8-node coupled temp-displacement plane stress quadrilateral'
        allocate(elem_types(ELEM_CPS8T)%face_nodes(1,8))
        elem_types(ELEM_CPS8T)%face_nodes = elem_types(ELEM_CPS8)%face_nodes
        allocate(elem_types(ELEM_CPS8T)%edge_nodes(4,3))
        elem_types(ELEM_CPS8T)%edge_nodes = elem_types(ELEM_CPS8)%edge_nodes
    end subroutine init_2d_solid_elements

    ! ---------------------------- init axisymmetric ----------------------------
    subroutine init_axisymmetric_elements(elem_types)
        type(element_type_info), intent(inout) :: elem_types(:)
        

        elem_types(ELEM_CAX4)%etype = ELEM_CAX4
        elem_types(ELEM_CAX4)%name = 'CAX4'
        elem_types(ELEM_CAX4)%nnode = 4
        elem_types(ELEM_CAX4)%nface = 1
        elem_types(ELEM_CAX4)%nedge = 4
        elem_types(ELEM_CAX4)%dimension = 2
        elem_types(ELEM_CAX4)%analysis_type = 1
        elem_types(ELEM_CAX4)%description = '4-node axisymmetric quadrilateral'
        allocate(elem_types(ELEM_CAX4)%face_nodes(1,4))
        elem_types(ELEM_CAX4)%face_nodes = reshape([1,2,3,4], [1,4])
        allocate(elem_types(ELEM_CAX4)%edge_nodes(4,2))
        elem_types(ELEM_CAX4)%edge_nodes = reshape([1,2, 2,3, 3,4, 4,1], [4,2])


        elem_types(ELEM_CAX4R)%etype = ELEM_CAX4R
        elem_types(ELEM_CAX4R)%name = 'CAX4R'
        elem_types(ELEM_CAX4R)%nnode = 4
        elem_types(ELEM_CAX4R)%nface = 1
        elem_types(ELEM_CAX4R)%nedge = 4
        elem_types(ELEM_CAX4R)%dimension = 2
        elem_types(ELEM_CAX4R)%analysis_type = 2
        elem_types(ELEM_CAX4R)%description = '4-node reduced integration axisymmetric quadrilateral'
        allocate(elem_types(ELEM_CAX4R)%face_nodes(1,4))
        elem_types(ELEM_CAX4R)%face_nodes = elem_types(ELEM_CAX4)%face_nodes
        allocate(elem_types(ELEM_CAX4R)%edge_nodes(4,2))
        elem_types(ELEM_CAX4R)%edge_nodes = elem_types(ELEM_CAX4)%edge_nodes


        elem_types(ELEM_CAX4H)%etype = ELEM_CAX4H
        elem_types(ELEM_CAX4H)%name = 'CAX4H'
        elem_types(ELEM_CAX4H)%nnode = 4
        elem_types(ELEM_CAX4H)%nface = 1
        elem_types(ELEM_CAX4H)%nedge = 4
        elem_types(ELEM_CAX4H)%dimension = 2
        elem_types(ELEM_CAX4H)%analysis_type = 1
        elem_types(ELEM_CAX4H)%description = '4-node hybrid axisymmetric quadrilateral'
        allocate(elem_types(ELEM_CAX4H)%face_nodes(1,4))
        elem_types(ELEM_CAX4H)%face_nodes = elem_types(ELEM_CAX4)%face_nodes
        allocate(elem_types(ELEM_CAX4H)%edge_nodes(4,2))
        elem_types(ELEM_CAX4H)%edge_nodes = elem_types(ELEM_CAX4)%edge_nodes


        elem_types(ELEM_CAX4T)%etype = ELEM_CAX4T
        elem_types(ELEM_CAX4T)%name = 'CAX4T'
        elem_types(ELEM_CAX4T)%nnode = 4
        elem_types(ELEM_CAX4T)%nface = 1
        elem_types(ELEM_CAX4T)%nedge = 4
        elem_types(ELEM_CAX4T)%dimension = 2
        elem_types(ELEM_CAX4T)%analysis_type = 1
        elem_types(ELEM_CAX4T)%description = '4-node coupled temp-displacement axisymmetric quadrilateral'
        allocate(elem_types(ELEM_CAX4T)%face_nodes(1,4))
        elem_types(ELEM_CAX4T)%face_nodes = elem_types(ELEM_CAX4)%face_nodes
        allocate(elem_types(ELEM_CAX4T)%edge_nodes(4,2))
        elem_types(ELEM_CAX4T)%edge_nodes = elem_types(ELEM_CAX4)%edge_nodes


        elem_types(ELEM_CAX3)%etype = ELEM_CAX3
        elem_types(ELEM_CAX3)%name = 'CAX3'
        elem_types(ELEM_CAX3)%nnode = 3
        elem_types(ELEM_CAX3)%nface = 1
        elem_types(ELEM_CAX3)%nedge = 3
        elem_types(ELEM_CAX3)%dimension = 2
        elem_types(ELEM_CAX3)%analysis_type = 1
        elem_types(ELEM_CAX3)%description = '3-node axisymmetric triangle'
        allocate(elem_types(ELEM_CAX3)%face_nodes(1,3))
        elem_types(ELEM_CAX3)%face_nodes = reshape([1,2,3], [1,3])
        allocate(elem_types(ELEM_CAX3)%edge_nodes(3,2))
        elem_types(ELEM_CAX3)%edge_nodes = reshape([1,2, 2,3, 3,1], [3,2])


        elem_types(ELEM_CAX6)%etype = ELEM_CAX6
        elem_types(ELEM_CAX6)%name = 'CAX6'
        elem_types(ELEM_CAX6)%nnode = 6
        elem_types(ELEM_CAX6)%nface = 1
        elem_types(ELEM_CAX6)%nedge = 3
        elem_types(ELEM_CAX6)%dimension = 2
        elem_types(ELEM_CAX6)%analysis_type = 1
        elem_types(ELEM_CAX6)%description = '6-node quadratic axisymmetric triangle'
        allocate(elem_types(ELEM_CAX6)%face_nodes(1,6))
        elem_types(ELEM_CAX6)%face_nodes = reshape([1,2,3,4,5,6], [1,6])
        allocate(elem_types(ELEM_CAX6)%edge_nodes(3,3))
        elem_types(ELEM_CAX6)%edge_nodes = reshape([1,2,4, 2,3,5, 3,1,6], [3,3])


        elem_types(ELEM_CAX6R)%etype = ELEM_CAX6R
        elem_types(ELEM_CAX6R)%name = 'CAX6R'
        elem_types(ELEM_CAX6R)%nnode = 6
        elem_types(ELEM_CAX6R)%nface = 1
        elem_types(ELEM_CAX6R)%nedge = 3
        elem_types(ELEM_CAX6R)%dimension = 2
        elem_types(ELEM_CAX6R)%analysis_type = 2
        elem_types(ELEM_CAX6R)%description = '6-node reduced integration axisymmetric triangle'
        allocate(elem_types(ELEM_CAX6R)%face_nodes(1,6))
        elem_types(ELEM_CAX6R)%face_nodes = elem_types(ELEM_CAX6)%face_nodes
        allocate(elem_types(ELEM_CAX6R)%edge_nodes(3,3))
        elem_types(ELEM_CAX6R)%edge_nodes = elem_types(ELEM_CAX6)%edge_nodes


        elem_types(ELEM_CAX8)%etype = ELEM_CAX8
        elem_types(ELEM_CAX8)%name = 'CAX8'
        elem_types(ELEM_CAX8)%nnode = 8
        elem_types(ELEM_CAX8)%nface = 1
        elem_types(ELEM_CAX8)%nedge = 4
        elem_types(ELEM_CAX8)%dimension = 2
        elem_types(ELEM_CAX8)%analysis_type = 1
        elem_types(ELEM_CAX8)%description = '8-node quadratic axisymmetric quadrilateral'
        allocate(elem_types(ELEM_CAX8)%face_nodes(1,8))
        elem_types(ELEM_CAX8)%face_nodes = reshape([1,2,3,4,5,6,7,8], [1,8])
        allocate(elem_types(ELEM_CAX8)%edge_nodes(4,3))
        elem_types(ELEM_CAX8)%edge_nodes = reshape([1,2,5, 2,3,6, 3,4,7, 4,1,8], [4,3])


        elem_types(ELEM_CAX8R)%etype = ELEM_CAX8R
        elem_types(ELEM_CAX8R)%name = 'CAX8R'
        elem_types(ELEM_CAX8R)%nnode = 8
        elem_types(ELEM_CAX8R)%nface = 1
        elem_types(ELEM_CAX8R)%nedge = 4
        elem_types(ELEM_CAX8R)%dimension = 2
        elem_types(ELEM_CAX8R)%analysis_type = 2
        elem_types(ELEM_CAX8R)%description = '8-node reduced integration axisymmetric quadrilateral'
        allocate(elem_types(ELEM_CAX8R)%face_nodes(1,8))
        elem_types(ELEM_CAX8R)%face_nodes = elem_types(ELEM_CAX8)%face_nodes
        allocate(elem_types(ELEM_CAX8R)%edge_nodes(4,3))
        elem_types(ELEM_CAX8R)%edge_nodes = elem_types(ELEM_CAX8)%edge_nodes


        elem_types(ELEM_CAX8T)%etype = ELEM_CAX8T
        elem_types(ELEM_CAX8T)%name = 'CAX8T'
        elem_types(ELEM_CAX8T)%nnode = 8
        elem_types(ELEM_CAX8T)%nface = 1
        elem_types(ELEM_CAX8T)%nedge = 4
        elem_types(ELEM_CAX8T)%dimension = 2
        elem_types(ELEM_CAX8T)%analysis_type = 1
        elem_types(ELEM_CAX8T)%description = '8-node coupled temp-displacement axisymmetric quadrilateral'
        allocate(elem_types(ELEM_CAX8T)%face_nodes(1,8))
        elem_types(ELEM_CAX8T)%face_nodes = elem_types(ELEM_CAX8)%face_nodes
        allocate(elem_types(ELEM_CAX8T)%edge_nodes(4,3))
        elem_types(ELEM_CAX8T)%edge_nodes = elem_types(ELEM_CAX8)%edge_nodes
    end subroutine init_axisymmetric_elements

    ! ---------------------------- init shells ----------------------------
    subroutine init_shell_elements(elem_types)
        type(element_type_info), intent(inout) :: elem_types(:)
        

        elem_types(ELEM_S4)%etype = ELEM_S4
        elem_types(ELEM_S4)%name = 'S4'
        elem_types(ELEM_S4)%nnode = 4
        elem_types(ELEM_S4)%nface = 1
        elem_types(ELEM_S4)%nedge = 4
        elem_types(ELEM_S4)%dimension = 2
        elem_types(ELEM_S4)%analysis_type = 1
        elem_types(ELEM_S4)%description = '4-node linear shell'
        allocate(elem_types(ELEM_S4)%face_nodes(1,4))
        elem_types(ELEM_S4)%face_nodes = reshape([1,2,3,4], [1,4])
        allocate(elem_types(ELEM_S4)%edge_nodes(4,2))
        elem_types(ELEM_S4)%edge_nodes = reshape([1,2, 2,3, 3,4, 4,1], [4,2])


        elem_types(ELEM_S4R)%etype = ELEM_S4R
        elem_types(ELEM_S4R)%name = 'S4R'
        elem_types(ELEM_S4R)%nnode = 4
        elem_types(ELEM_S4R)%nface = 1
        elem_types(ELEM_S4R)%nedge = 4
        elem_types(ELEM_S4R)%dimension = 2
        elem_types(ELEM_S4R)%analysis_type = 2
        elem_types(ELEM_S4R)%description = '4-node reduced integration shell'
        allocate(elem_types(ELEM_S4R)%face_nodes(1,4))
        elem_types(ELEM_S4R)%face_nodes = elem_types(ELEM_S4)%face_nodes
        allocate(elem_types(ELEM_S4R)%edge_nodes(4,2))
        elem_types(ELEM_S4R)%edge_nodes = elem_types(ELEM_S4)%edge_nodes


    end subroutine init_shell_elements



    subroutine init_beam_elements(elem_types)
        type(element_type_info), intent(inout) :: elem_types(:)

    end subroutine init_beam_elements

    subroutine init_membrane_elements(elem_types)
        type(element_type_info), intent(inout) :: elem_types(:)

    end subroutine init_membrane_elements

    subroutine init_truss_elements(elem_types)
        type(element_type_info), intent(inout) :: elem_types(:)

    end subroutine init_truss_elements

    subroutine init_thermal_elements(elem_types)
        type(element_type_info), intent(inout) :: elem_types(:)

    end subroutine init_thermal_elements

    subroutine init_acoustic_elements(elem_types)
        type(element_type_info), intent(inout) :: elem_types(:)

    end subroutine init_acoustic_elements

    ! ---------------------------- read INP ----------------------------
subroutine read_inp_file(this, filename)
    class(inp_processor), intent(inout) :: this
    character(len=*), intent(in) :: filename
    character(len=256) :: line, elem_type_str
    integer :: iunit, io_stat, ielem, nnode, elem_id, pos, i
    logical :: in_element_section, inside_element_data
    integer, allocatable :: temp_nodes(:)
    
    this%filename = trim(filename)
    call this%initialize_element_types()  ! init type table
    

    open(newunit=iunit, file=trim(this%filename), status='old', action='read', iostat=io_stat)
    if (io_stat /= 0) then
        write(*,*) 'Error: cannot open file ', trim(filename)
        stop
    end if
    

    this%n_elements = 0
    in_element_section = .false.
    nnode = 0
    do
        read(iunit, '(A)', iostat=io_stat) line
        if (io_stat /= 0) exit
        line = adjustl(line)
        if (len_trim(line) == 0 .or. line(1:2) == '**') cycle
        

        if (line(1:1) == '*' .and. index(adjustl(line), '*ELEMENT') == 1) then
            in_element_section = .true.
            call extract_element_type(line, elem_type_str, nnode)
        else if (line(1:1) == '*') then
            in_element_section = .false.
        else if (in_element_section .and. nnode > 0) then
            this%n_elements = this%n_elements + 1
        end if
    end do
    rewind(iunit)
    

    if (this%n_elements > 0) allocate(this%elements(this%n_elements))
    

    in_element_section = .false.
    inside_element_data = .false.
    ielem = 0
    nnode = 0
    allocate(temp_nodes(max_nodes_per_elem))  ! temp node buffer
    
    do
        read(iunit, '(A)', iostat=io_stat) line
        if (io_stat /= 0) exit
        line = adjustl(line)
        if (len_trim(line) == 0 .or. line(1:2) == '**') cycle
        

        if (line(1:1) == '*') then
            inside_element_data = .false.
            if (index(adjustl(line), '*ELEMENT') == 1) then
                in_element_section = .true.
                call extract_element_type(line, elem_type_str, nnode)
                

                if (nnode > max_nodes_per_elem) then
                    write(*,*) 'Error: element type ', trim(elem_type_str), ' node count ', nnode, &
                        ' exceeds max_nodes_per_elem ', max_nodes_per_elem
                    write(*,*) 'Increase max_nodes_per_elem (current ', max_nodes_per_elem, ')'
                    error stop
                end if
                inside_element_data = (nnode > 0)
            else
                in_element_section = .false.
            end if
        else if (inside_element_data) then
            ielem = ielem + 1
            if (ielem > this%n_elements) then
                write(*,*) 'Warning: more elements than expected; check INP format'
                cycle
            end if
            

            pos = index(line, ',')
            if (pos > 0) then

                read(line(1:pos-1), *, iostat=io_stat) elem_id
                if (io_stat /= 0) then
                    write(*,*) 'Warning: cannot read element id, line: ', trim(line)
                    elem_id = ielem
                end if
                

                read(line(pos+1:), *, iostat=io_stat) temp_nodes(1:nnode)
                if (io_stat /= 0) then
                    write(*,*) 'Warning: element ', elem_id, ' node read failed, line: ', trim(line)
                    temp_nodes(1:nnode) = 0
                end if
            else

                read(line, *, iostat=io_stat) elem_id, temp_nodes(1:nnode)
                if (io_stat /= 0) then
                    write(*,*) 'Warning: element data read failed, line: ', trim(line)
                    elem_id = ielem
                    temp_nodes(1:nnode) = 0
                end if
            end if
            
            ! store element
            this%elements(ielem)%id = elem_id
            allocate(this%elements(ielem)%nodes(nnode))
            this%elements(ielem)%nodes = temp_nodes(1:nnode)
            

            call this%identify_element_type(this%elements(ielem), elem_type_str)
        end if
    end do
    
    close(iunit)
    deallocate(temp_nodes)
    
    ! geometry metadata
    call this%extract_geometry_info()
    
    write(*,*) 'Found ', this%n_elements, ' elements'
end subroutine read_inp_file

    ! ---------------------------- classify element ----------------------------
    subroutine identify_element_type(this, elem, elem_type_str)
        class(inp_processor), intent(in) :: this
        type(element_data), intent(inout) :: elem
        character(len=*), intent(in) :: elem_type_str
        integer :: i, etype_id
        
        etype_id = get_element_type_id(elem_type_str)
        if (etype_id /= ELEM_UNKNOWN) then
            elem%etype = etype_id
            return
        end if
        
        do i = 1, this%n_element_types
            if (index(this%elem_types(i)%name, trim(elem_type_str)) > 0 .or. &
                this%elem_types(i)%nnode == size(elem%nodes)) then
                elem%etype = this%elem_types(i)%etype
                return
            end if
        end do
        elem%etype = ELEM_UNKNOWN
    end subroutine identify_element_type


    function get_element_type_id(etype_name) result(etype_id)
        character(len=*), intent(in) :: etype_name
        integer :: etype_id
        select case(trim(etype_name))
            case('C3D4'); etype_id = ELEM_C3D4
            case('C3D8'); etype_id = ELEM_C3D8
            case('C3D8R'); etype_id = ELEM_C3D8R
            case('C3D8I'); etype_id = ELEM_C3D8I
            case('C3D8H'); etype_id = ELEM_C3D8H
            case('C3D8T'); etype_id = ELEM_C3D8T
            case('C3D10'); etype_id = ELEM_C3D10
            case('C3D10M'); etype_id = ELEM_C3D10M
            case('C3D10E'); etype_id = ELEM_C3D10E
            case('C3D15'); etype_id = ELEM_C3D15
            case('C3D20'); etype_id = ELEM_C3D20
            case('C3D20R'); etype_id = ELEM_C3D20R
            case('C3D20H'); etype_id = ELEM_C3D20H
            case('C3D20T'); etype_id = ELEM_C3D20T
            case('C3D27'); etype_id = ELEM_C3D27
            case('CPE4'); etype_id = ELEM_CPE4
            case('CPE4R'); etype_id = ELEM_CPE4R
            case('CPE4T'); etype_id = ELEM_CPE4T
            case('CPS4'); etype_id = ELEM_CPS4
            case('CPS4R'); etype_id = ELEM_CPS4R
            case('CPS4T'); etype_id = ELEM_CPS4T
            case('CPE3'); etype_id = ELEM_CPE3
            case('CPS3'); etype_id = ELEM_CPS3
            case('CPE6'); etype_id = ELEM_CPE6
            case('CPE6R'); etype_id = ELEM_CPE6R
            case('CPS6'); etype_id = ELEM_CPS6
            case('CPS6R'); etype_id = ELEM_CPS6R
            case('CPE8'); etype_id = ELEM_CPE8
            case('CPE8R'); etype_id = ELEM_CPE8R
            case('CPE8T'); etype_id = ELEM_CPE8T
            case('CPS8'); etype_id = ELEM_CPS8
            case('CPS8R'); etype_id = ELEM_CPS8R
            case('CPS8T'); etype_id = ELEM_CPS8T
            case('CAX4'); etype_id = ELEM_CAX4
            case('CAX4R'); etype_id = ELEM_CAX4R
            case('CAX4H'); etype_id = ELEM_CAX4H
            case('CAX4T'); etype_id = ELEM_CAX4T
            case('CAX3'); etype_id = ELEM_CAX3
            case('CAX6'); etype_id = ELEM_CAX6
            case('CAX6R'); etype_id = ELEM_CAX6R
            case('CAX8'); etype_id = ELEM_CAX8
            case('CAX8R'); etype_id = ELEM_CAX8R
            case('CAX8T'); etype_id = ELEM_CAX8T

            case default; etype_id = ELEM_UNKNOWN
        end select
    end function get_element_type_id

    ! ---------------------------- extract geometry ----------------------------
subroutine extract_geometry_info(this)
    class(inp_processor), intent(inout) :: this
    integer :: i, j, etype, nface, nedge, n_nodes_per_face, n_nodes_per_edge
    
    do i = 1, this%n_elements
        etype = this%elements(i)%etype
        if (etype == ELEM_UNKNOWN) cycle
        

        nface = this%elem_types(etype)%nface
        if (nface > 0) then
            n_nodes_per_face = size(this%elem_types(etype)%face_nodes, 2)
            

            if (allocated(this%elements(i)%face_nodes)) then
                if (size(this%elements(i)%face_nodes,1) /= nface .or. &
                    size(this%elements(i)%face_nodes,2) /= n_nodes_per_face) then
                    deallocate(this%elements(i)%face_nodes)
                    allocate(this%elements(i)%face_nodes(nface, n_nodes_per_face))
                end if
            else
                allocate(this%elements(i)%face_nodes(nface, n_nodes_per_face))
            end if
            

            do j = 1, nface
                this%elements(i)%face_nodes(j, :) = &
                    this%elements(i)%nodes(this%elem_types(etype)%face_nodes(j, :))
            end do
        else

            if (allocated(this%elements(i)%face_nodes)) deallocate(this%elements(i)%face_nodes)
        end if
        

        nedge = this%elem_types(etype)%nedge
        if (nedge > 0) then
            if (.not. allocated(this%elem_types(etype)%edge_nodes)) then
                write(*,*) 'Warning: element type ', this%elem_types(etype)%name, ' has no edge_nodes table'
                cycle
            end if
            n_nodes_per_edge = size(this%elem_types(etype)%edge_nodes, 2)
            

            if (allocated(this%elements(i)%edge_nodes)) then
                if (size(this%elements(i)%edge_nodes,1) /= nedge .or. &
                    size(this%elements(i)%edge_nodes,2) /= n_nodes_per_edge) then
                    deallocate(this%elements(i)%edge_nodes)
                    allocate(this%elements(i)%edge_nodes(nedge, n_nodes_per_edge))
                end if
            else
                allocate(this%elements(i)%edge_nodes(nedge, n_nodes_per_edge))
            end if
            

            do j = 1, nedge
                this%elements(i)%edge_nodes(j, :) = &
                    this%elements(i)%nodes(this%elem_types(etype)%edge_nodes(j, :))
            end do
        else

            if (allocated(this%elements(i)%edge_nodes)) deallocate(this%elements(i)%edge_nodes)
        end if
        

        if (this%elem_types(etype)%dimension == 1) then
            if (allocated(this%elements(i)%line_nodes)) then
                if (size(this%elements(i)%line_nodes,2) /= size(this%elements(i)%nodes)) then
                    deallocate(this%elements(i)%line_nodes)
                    allocate(this%elements(i)%line_nodes(1, size(this%elements(i)%nodes)))
                end if
            else
                allocate(this%elements(i)%line_nodes(1, size(this%elements(i)%nodes)))
            end if
            this%elements(i)%line_nodes(1,:) = this%elements(i)%nodes
        else
            if (allocated(this%elements(i)%line_nodes)) deallocate(this%elements(i)%line_nodes)
        end if
        

        this%elements(i)%ndim = this%elem_types(etype)%dimension
        this%elements(i)%reduced_integration = &
            (index(this%elem_types(etype)%name, 'R') > 0) .or. &
            (index(this%elem_types(etype)%name, 'H') > 0)
    end do
    
    write(*,*) 'Geometry extraction done, elements processed: ', this%n_elements
end subroutine extract_geometry_info

    ! ---------------------------- print summary ----------------------------
    subroutine print_element_summary(this)
        class(inp_processor), intent(in) :: this
        integer :: i, type_count(this%n_element_types)
        
        type_count = 0
        do i = 1, this%n_elements
            if (this%elements(i)%etype > 0 .and. this%elements(i)%etype <= this%n_element_types) &
                type_count(this%elements(i)%etype) = type_count(this%elements(i)%etype) + 1
        end do
        
        write(*,*) '==================== Element type summary ===================='
        write(*,*) 'INP file: ', trim(this%filename)
        write(*,*) 'num elements: ', this%n_elements
        write(*,*) '---------------------------------------------------------'
        do i = 1, this%n_element_types
            if (type_count(i) > 0) then
                write(*, '(A, I6, 2X, A)') trim(this%elem_types(i)%name)//':', &
                    type_count(i), trim(this%elem_types(i)%description)
            end if
        end do
        write(*,*) '========================================================='
    end subroutine print_element_summary


subroutine extract_element_type(line, elem_type_str, nnode)
    character(len=*), intent(in) :: line
    character(len=20), intent(out) :: elem_type_str
    integer, intent(out) :: nnode
    integer :: eq_pos, pos1, pos2
    
    nnode = 0
    elem_type_str = 'UNKNOWN'
    eq_pos = index(line, 'TYPE=')
    if (eq_pos == 0) return
    

    pos1 = eq_pos + 5
    pos2 = index(line(pos1:), ',')
    if (pos2 > 0) then
        elem_type_str = adjustl(line(pos1:pos1+pos2-2))
    else
        elem_type_str = adjustl(line(pos1:))
    end if
    

    if (elem_type_str(1:1) == '"') then
        pos2 = index(elem_type_str, '"', back=.true.)
        if (pos2 > 1) elem_type_str = elem_type_str(2:pos2-1)
    end if
    
    ! ---------------------------- 3D solid section ----------------------------
    select case(trim(elem_type_str))
        case('C3D4', 'DC3D4', 'AC3D4'); nnode = 4
        case('C3D8', 'C3D8R', 'C3D8I', 'C3D8H', 'C3D8T', 'DC3D8', 'AC3D8'); nnode = 8
        case('C3D10', 'C3D10M', 'C3D10E', 'DC3D10', 'AC3D10'); nnode = 10
        case('C3D15', 'DC3D15', 'AC3D15'); nnode = 15
        case('C3D20', 'C3D20R', 'C3D20H', 'C3D20T', 'DC3D20', 'AC3D20'); nnode = 20
        case('C3D27'); nnode = 27
        
    ! ---------------------------- 2D solid section ----------------------------
        case('CPE4', 'CPE4R', 'CPE4T', 'CPS4', 'CPS4R', 'CPS4T', &
             'CAX4', 'CAX4R', 'CAX4H', 'CAX4T', 'S4', 'S4R', 'S4RS', 'S4T'); nnode = 4
        case('CPE3', 'CPS3', 'CAX3', 'S3', 'STRI3'); nnode = 3
        case('CPE6', 'CPE6R', 'CPS6', 'CPS6R', 'CAX6', 'CAX6R'); nnode = 6
        case('CPE8', 'CPE8R', 'CPE8T', 'CPS8', 'CPS8R', 'CPS8T', &
             'CAX8', 'CAX8R', 'CAX8T', 'S8', 'S8R', 'S8RT'); nnode = 8
        case('S9R5'); nnode = 9
        

        case('B21', 'B21H', 'B21T', 'B31', 'B31H', 'B31OS', 'B31T', 'B31EX', &
             'T2D2', 'T2D2H', 'T2D2T', 'T3D2', 'T3D2H', 'T3D2T', 'DC1D2', 'AC1D2'); nnode = 2
        case('B22', 'B22H', 'B32', 'B32H', 'B32OS', 'T2D3', 'T2D3H', 'T3D3', 'T3D3H', &
             'DC1D3', 'AC1D3'); nnode = 3
        
    ! ---------------------------- Membrane ----------------------------
        case('M3D4', 'M3D4R', 'M2D4', 'M2D4R'); nnode = 4
        case('M3D3', 'M3D3R', 'M2D3', 'M2D3R'); nnode = 3
        case('M3D6', 'M3D6R'); nnode = 6
        case('M3D8', 'M3D8R'); nnode = 8
        

        case('DC2D3', 'AC2D3'); nnode = 3
        case('DC2D4', 'AC2D4'); nnode = 4
        case('DC2D6', 'AC2D6'); nnode = 6
        case('DC2D8', 'AC2D8'); nnode = 8
        

        case('SC6R'); nnode = 6
        case('SC8R'); nnode = 8
        

        case default
            call extract_node_count_from_name(elem_type_str, nnode)
            nnode = min(nnode, max_nodes_per_elem)
    end select
end subroutine extract_element_type

    subroutine extract_node_count_from_name(elem_name, nnode)
        character(len=*), intent(in) :: elem_name
        integer, intent(out) :: nnode
        integer :: i, j
        character(len=5) :: num_str
        
        nnode = 0
        num_str = ''
        do i = 1, len_trim(elem_name)
            if (elem_name(i:i) >= '0' .and. elem_name(i:i) <= '9') then
                j = len_trim(num_str) + 1
                if (j <= 5) num_str(j:j) = elem_name(i:i)
            end if
        end do
        if (len_trim(num_str) > 0) read(num_str, *) nnode
    end subroutine extract_node_count_from_name

    subroutine print_detailed_results(this, max_print)
        class(inp_processor), intent(in) :: this
        integer, intent(in), optional :: max_print
        integer :: i, j, n_print
        
        n_print = merge(max_print, 5, present(max_print))
        n_print = min(n_print, this%n_elements)
        
        write(*,*) '==================== Element details ===================='
        do i = 1, n_print
            write(*,*) 'element id: ', this%elements(i)%id
            write(*,*) 'type: ', trim(this%elem_types(this%elements(i)%etype)%name)
            write(*,*) 'nodes: ', this%elements(i)%nodes
            if (allocated(this%elements(i)%face_nodes)) then
                write(*,*) 'face nodes:'
                do j = 1, size(this%elements(i)%face_nodes, 1)
                    write(*,*) '  face', j, ':', this%elements(i)%face_nodes(j,:)
                end do
            end if
            if (allocated(this%elements(i)%edge_nodes)) then
                write(*,*) 'edge nodes:'
                do j = 1, size(this%elements(i)%edge_nodes, 1)
                    write(*,*) '  edge', j, ':', this%elements(i)%edge_nodes(j,:)
                end do
            end if
            write(*,*) '---------------------------------------------------------'
        end do
    end subroutine print_detailed_results

    subroutine cleanup(this)
        class(inp_processor), intent(inout) :: this
        integer :: i
        do i = 1, this%n_elements
            if (allocated(this%elements(i)%nodes)) deallocate(this%elements(i)%nodes)
            if (allocated(this%elements(i)%face_nodes)) deallocate(this%elements(i)%face_nodes)
            if (allocated(this%elements(i)%edge_nodes)) deallocate(this%elements(i)%edge_nodes)
            if (allocated(this%elements(i)%line_nodes)) deallocate(this%elements(i)%line_nodes)
        end do
        if (allocated(this%elements)) deallocate(this%elements)
        if (allocated(this%elem_types)) deallocate(this%elem_types)
        this%n_elements = 0
        this%n_element_types = 0
        write(*,*) 'Cleanup done'
    end subroutine cleanup

end module ElemLib
