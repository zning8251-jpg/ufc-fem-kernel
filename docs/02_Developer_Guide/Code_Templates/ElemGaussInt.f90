! LEGACY: Reference only — not conforming to UFC v3 naming convention.
!   This file uses lowercase module/type names without layer prefixes.
!   Do NOT copy directly into ufc_core; use PH_Elem_* naming when porting.
! Shape functions and Gauss quadrature (boundary rules included)
module ElemGaussInt
    use IF_Prec_Core, ONLY: wp, i4
    use ElemLib
    implicit none

    ! Gauss quadrature rule type
    type gauss_rule
        integer :: dim               ! integration dim (1=1D,2=2D,3=3D)
        integer :: order             ! quadrature order
        integer :: n_points          ! number of points
        real(wp), allocatable :: xi(:,:) ! point coords (n_points x dim)
        real(wp), allocatable :: w(:)    ! weights (n_points)
    end type gauss_rule

    ! Shape function bundle
    type shape_function_result
        integer :: nnode             ! number of nodes
        real(wp), allocatable :: N(:)      ! N values (nnode)
        real(wp), allocatable :: dN_dxi(:,:) ! dN/d parent (nnode x dim)
        real(wp) :: detJ                  ! detJ
        real(wp), allocatable :: dN_dx(:,:)  ! dN/dx (nnode x dim)
    end type shape_function_result

contains

    ! ------------------------------------------------------
    ! Gauss rule builders
    ! ------------------------------------------------------

    ! Build 1D Gauss rule
    subroutine init_gauss_1d(this, order)
        type(gauss_rule), intent(out) :: this
        integer, intent(in) :: order
        
        this%dim = 1
        this%order = order
        
        select case(order)
            case(1)  ! order 1 (1 pt)
                this%n_points = 1
                allocate(this%xi(1,1), this%w(1))
                this%xi(1,:) = [0.0_wp]
                this%w(1) = 2.0_wp
                
            case(2)  ! order 2 (2 pts)
                this%n_points = 2
                allocate(this%xi(2,1), this%w(2))
                this%xi(:,1) = [-sqrt(1.0_wp/3.0_wp), sqrt(1.0_wp/3.0_wp)]
                this%w(:) = [1.0_wp, 1.0_wp]
                
            case(3)  ! order 3 (3 pts)
                this%n_points = 3
                allocate(this%xi(3,1), this%w(3))
                this%xi(:,1) = [-sqrt(3.0_wp/5.0_wp), 0.0_wp, sqrt(3.0_wp/5.0_wp)]
                this%w(:) = [5.0_wp/9.0_wp, 8.0_wp/9.0_wp, 5.0_wp/9.0_wp]
                
            case default
                write(*,*) "Unsupported 1D Gauss order:", order
                error stop
        end select
    end subroutine init_gauss_1d

    ! 2D tensor product (quad ref element)
    subroutine init_gauss_2d_quad(this, order)
        type(gauss_rule), intent(out) :: this
        integer, intent(in) :: order
        type(gauss_rule) :: gauss1d
        integer :: i, j, ip
        
        this%dim = 2
        this%order = order
        
        call init_gauss_1d(gauss1d, order)
        this%n_points = gauss1d%n_points ** 2
        allocate(this%xi(this%n_points, 2), this%w(this%n_points))
        
        ip = 1
        do i = 1, gauss1d%n_points
            do j = 1, gauss1d%n_points
                this%xi(ip,:) = [gauss1d%xi(j,1), gauss1d%xi(i,1)]
                this%w(ip) = gauss1d%w(j) * gauss1d%w(i)
                ip = ip + 1
            end do
        end do
        deallocate(gauss1d%xi, gauss1d%w)
    end subroutine init_gauss_2d_quad

    ! 3D tensor product (hex ref element)
    subroutine init_gauss_3d_hex(this, order)
        type(gauss_rule), intent(out) :: this
        integer, intent(in) :: order
        type(gauss_rule) :: gauss1d
        integer :: i, j, k, ip
        
        this%dim = 3
        this%order = order
        
        call init_gauss_1d(gauss1d, order)
        this%n_points = gauss1d%n_points ** 3
        allocate(this%xi(this%n_points, 3), this%w(this%n_points))
        
        ip = 1
        do i = 1, gauss1d%n_points
            do j = 1, gauss1d%n_points
                do k = 1, gauss1d%n_points
                    this%xi(ip,:) = [gauss1d%xi(k,1), gauss1d%xi(j,1), gauss1d%xi(i,1)]
                    this%w(ip) = gauss1d%w(k) * gauss1d%w(j) * gauss1d%w(i)
                    ip = ip + 1
                end do
            end do
        end do
        deallocate(gauss1d%xi, gauss1d%w)
    end subroutine init_gauss_3d_hex

    ! ------------------------------------------------------
    ! Boundary quadrature (surface/edge loads)
    ! ------------------------------------------------------

    ! Gauss points on hex face
    subroutine get_hex_face_gauss(face_id, order, gauss)
        integer, intent(in) :: face_id  ! face id (1-6)
        integer, intent(in) :: order    ! quadrature order
        type(gauss_rule), intent(out) :: gauss
        type(gauss_rule) :: gauss2d
        integer :: i
        
        call init_gauss_2d_quad(gauss2d, order)
        gauss%dim = 3
        gauss%order = order
        gauss%n_points = gauss2d%n_points
        allocate(gauss%xi(gauss%n_points, 3), gauss%w(gauss%n_points))
        gauss%w = gauss2d%w
        
        select case(face_id)
            case(1)  ! xi=-1 face
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [-1.0_wp, gauss2d%xi(i,1), gauss2d%xi(i,2)]
                end do
            case(2)  ! xi=+1 face
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [1.0_wp, gauss2d%xi(i,1), gauss2d%xi(i,2)]
                end do
            case(3)  ! eta=-1 face
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [gauss2d%xi(i,1), -1.0_wp, gauss2d%xi(i,2)]
                end do
            case(4)  ! eta=+1 face
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [gauss2d%xi(i,1), 1.0_wp, gauss2d%xi(i,2)]
                end do
            case(5)  ! zeta=-1 face
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [gauss2d%xi(i,1), gauss2d%xi(i,2), -1.0_wp]
                end do
            case(6)  ! zeta=+1 face
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [gauss2d%xi(i,1), gauss2d%xi(i,2), 1.0_wp]
                end do
            case default
                write(*,*) "Hex face id must be 1-6, got:", face_id
                error stop
        end select
        
        deallocate(gauss2d%xi, gauss2d%w)
    end subroutine get_hex_face_gauss

    ! Gauss points on quad edge
    subroutine get_quad_edge_gauss(edge_id, order, gauss)
        integer, intent(in) :: edge_id  ! edge id (1-4)
        integer, intent(in) :: order    ! quadrature order
        type(gauss_rule), intent(out) :: gauss
        type(gauss_rule) :: gauss1d
        integer :: i
        
        call init_gauss_1d(gauss1d, order)
        gauss%dim = 2
        gauss%order = order
        gauss%n_points = gauss1d%n_points
        allocate(gauss%xi(gauss%n_points, 2), gauss%w(gauss%n_points))
        gauss%w = gauss1d%w
        
        select case(edge_id)
            case(1)  ! xi=-1 edge
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [-1.0_wp, gauss1d%xi(i,1)]
                end do
            case(2)  ! xi=+1 edge
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [1.0_wp, gauss1d%xi(i,1)]
                end do
            case(3)  ! eta=-1 edge
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [gauss1d%xi(i,1), -1.0_wp]
                end do
            case(4)  ! eta=+1 edge
                do i = 1, gauss%n_points
                    gauss%xi(i,:) = [gauss1d%xi(i,1), 1.0_wp]
                end do
            case default
                write(*,*) "Quad edge id must be 1-4, got:", edge_id
                error stop
        end select
        
        deallocate(gauss1d%xi, gauss1d%w)
    end subroutine get_quad_edge_gauss

    ! ------------------------------------------------------
    ! Shape function API
    ! ------------------------------------------------------

    ! Dispatch by element type name
    function compute_shape_functions(elem_type, xi) result(sf)
        character(len=*), intent(in) :: elem_type  ! element type string
        real(wp), intent(in) :: xi(:)          ! parent coords
        type(shape_function_result) :: sf
        
        select case(trim(elem_type))
            ! 3D solid — tet
            case('C3D4', 'DC3D4', 'AC3D4'); call compute_shape_tet4(xi, sf)
            case('C3D10', 'C3D10M', 'C3D10E', 'DC3D10', 'AC3D10'); call compute_shape_tet10(xi, sf)
            
            ! 3D solid — hex
            case('C3D8', 'C3D8R', 'C3D8I', 'C3D8H', 'C3D8T', &
                 'DC3D8', 'AC3D8'); call compute_shape_hex8(xi, sf)
            case('C3D20', 'C3D20R', 'C3D20H', 'C3D20T', 'DC3D20', 'AC3D20'); call compute_shape_hex20(xi, sf)
            case('C3D27'); call compute_shape_hex27(xi, sf)
            
            ! 2D solid — triangle
            case('CPE3', 'CPS3', 'CAX3', 'S3', 'STRI3'); call compute_shape_tri3(xi, sf)
            case('CPE6', 'CPE6R', 'CPS6', 'CPS6R', 'CAX6', 'CAX6R'); call compute_shape_tri6(xi, sf)
            
            ! 2D solid — quad
            case('CPE4', 'CPE4R', 'CPE4T', 'CPS4', 'CPS4R', 'CPS4T', &
                 'CAX4', 'CAX4R', 'CAX4H', 'CAX4T', 'S4', 'S4R', 'S4RS', 'S4T'); call compute_shape_quad4(xi, sf)
            case('CPE8', 'CPE8R', 'CPE8T', 'CPS8', 'CPS8R', 'CPS8T', &
                 'CAX8', 'CAX8R', 'CAX8T', 'S8', 'S8R', 'S8RT'); call compute_shape_quad8(xi, sf)
            
            ! 1D elements
            case('B21', 'B21H', 'B21T', 'B31', 'B31H', 'B31OS', 'B31T', 'B31EX', &
                 'T2D2', 'T2D2H', 'T2D2T', 'T3D2', 'T3D2H', 'T3D2T'); call compute_shape_line2(xi, sf)
            case('B22', 'B22H', 'B32', 'B32H', 'B32OS', 'T2D3', 'T2D3H', 'T3D3', 'T3D3H'); call compute_shape_line3(xi, sf)
            
            ! Thermal — reuse mechanical shapes
            case('DC1D2', 'AC1D2'); call compute_shape_line2(xi, sf)
            case('DC1D3', 'AC1D3'); call compute_shape_line3(xi, sf)
            case('DC2D3', 'AC2D3'); call compute_shape_tri3(xi, sf)
            case('DC2D4', 'AC2D4'); call compute_shape_quad4(xi, sf)
            case('DC2D6', 'AC2D6'); call compute_shape_tri6(xi, sf)
            case('DC2D8', 'AC2D8'); call compute_shape_quad8(xi, sf)
            case('DC3D6', 'AC3D6'); call compute_shape_wedge6(xi, sf)
            case('DC3D15', 'AC3D15'); call compute_shape_wedge15(xi, sf)
            
            case default
                write(*,*) "Unimplemented element type:"//trim(elem_type)
                error stop
        end select
    end function compute_shape_functions

    ! ------------------------------------------------------
    ! 3D shapes
    ! ------------------------------------------------------

    ! 8-node hex (C3D8*)
    subroutine compute_shape_hex8(xi, sf)
        real(wp), intent(in) :: xi(3)  ! parent (xi,eta,zeta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(8), dN_dxi(8,3)
        
        N = 0.125_wp * [ &
            (1-xi(1))*(1-xi(2))*(1-xi(3)), &  ! n1
            (1+xi(1))*(1-xi(2))*(1-xi(3)), &  ! n2
            (1+xi(1))*(1+xi(2))*(1-xi(3)), &  ! n3
            (1-xi(1))*(1+xi(2))*(1-xi(3)), &  ! n4
            (1-xi(1))*(1-xi(2))*(1+xi(3)), &  ! n5
            (1+xi(1))*(1-xi(2))*(1+xi(3)), &  ! n6
            (1+xi(1))*(1+xi(2))*(1+xi(3)), &  ! n7
            (1-xi(1))*(1+xi(2))*(1+xi(3))]    ! n8
        
        dN_dxi(:,1) = 0.125_wp * [ &  ! dN/dξ
            -(1-xi(2))*(1-xi(3)),  (1-xi(2))*(1-xi(3)), &
            (1+xi(2))*(1-xi(3)),  -(1+xi(2))*(1-xi(3)), &
            -(1-xi(2))*(1+xi(3)),  (1-xi(2))*(1+xi(3)), &
            (1+xi(2))*(1+xi(3)),  -(1+xi(2))*(1+xi(3))]
        
        dN_dxi(:,2) = 0.125_wp * [ &  ! dN/dη
            -(1-xi(1))*(1-xi(3)), -(1+xi(1))*(1-xi(3)), &
            (1+xi(1))*(1-xi(3)),  (1-xi(1))*(1-xi(3)), &
            -(1-xi(1))*(1+xi(3)), -(1+xi(1))*(1+xi(3)), &
            (1+xi(1))*(1+xi(3)),  (1-xi(1))*(1+xi(3))]
        
        dN_dxi(:,3) = 0.125_wp * [ &  ! dN/dζ
            -(1-xi(1))*(1-xi(2)), -(1+xi(1))*(1-xi(2)), &
            -(1+xi(1))*(1+xi(2)), -(1-xi(1))*(1+xi(2)), &
            (1-xi(1))*(1-xi(2)),  (1+xi(1))*(1-xi(2)), &
            (1+xi(1))*(1+xi(2)),  (1-xi(1))*(1+xi(2))]
        
        sf%nnode = 8
        allocate(sf%N(8), sf%dN_dxi(8,3), sf%dN_dx(8,3))
        sf%N = N
        sf%dN_dxi = dN_dxi
        sf%detJ = 1.0_wp
    end subroutine compute_shape_hex8

    ! 20-node hex (C3D20*)
    subroutine compute_shape_hex20(xi, sf)
        real(wp), intent(in) :: xi(3)  ! parent (xi,eta,zeta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(20), xi1, xi2, xi3, xi1s, xi2s, xi3s
        
        xi1 = xi(1); xi2 = xi(2); xi3 = xi(3)
        xi1s = 1.0_wp - xi1**2; xi2s = 1.0_wp - xi2**2; xi3s = 1.0_wp - xi3**2
        
        ! corner nodes 1-8
        N(1)  = -0.125_wp*(1.0_wp-xi1)*(1.0_wp-xi2)*(1.0_wp-xi3)*(1.0_wp+xi1+xi2+xi3)
        N(2)  = -0.125_wp*(1.0_wp+xi1)*(1.0_wp-xi2)*(1.0_wp-xi3)*(1.0_wp-xi1+xi2+xi3)
        N(3)  = -0.125_wp*(1.0_wp+xi1)*(1.0_wp+xi2)*(1.0_wp-xi3)*(1.0_wp-xi1-xi2+xi3)
        N(4)  = -0.125_wp*(1.0_wp-xi1)*(1.0_wp+xi2)*(1.0_wp-xi3)*(1.0_wp+xi1-xi2+xi3)
        N(5)  = -0.125_wp*(1.0_wp-xi1)*(1.0_wp-xi2)*(1.0_wp+xi3)*(1.0_wp+xi1+xi2-xi3)
        N(6)  = -0.125_wp*(1.0_wp+xi1)*(1.0_wp-xi2)*(1.0_wp+xi3)*(1.0_wp-xi1+xi2-xi3)
        N(7)  = -0.125_wp*(1.0_wp+xi1)*(1.0_wp+xi2)*(1.0_wp+xi3)*(1.0_wp-xi1-xi2-xi3)
        N(8)  = -0.125_wp*(1.0_wp-xi1)*(1.0_wp+xi2)*(1.0_wp+xi3)*(1.0_wp+xi1-xi2-xi3)
        
        ! midside nodes 9-20
        N(9)  = 0.5_wp*xi1s*(1.0_wp-xi2)*(1.0_wp-xi3)  ! midside along xi
        N(10) = 0.5_wp*xi2s*(1.0_wp+xi1)*(1.0_wp-xi3)
        N(11) = 0.5_wp*xi1s*(1.0_wp+xi2)*(1.0_wp-xi3)
        N(12) = 0.5_wp*xi2s*(1.0_wp-xi1)*(1.0_wp-xi3)
        N(13) = 0.5_wp*xi1s*(1.0_wp-xi2)*(1.0_wp+xi3)
        N(14) = 0.5_wp*xi2s*(1.0_wp+xi1)*(1.0_wp+xi3)
        N(15) = 0.5_wp*xi1s*(1.0_wp+xi2)*(1.0_wp+xi3)
        N(16) = 0.5_wp*xi2s*(1.0_wp-xi1)*(1.0_wp+xi3)
        N(17) = 0.5_wp*xi3s*(1.0_wp-xi1)*(1.0_wp-xi2)  ! midside along zeta
        N(18) = 0.5_wp*xi3s*(1.0_wp+xi1)*(1.0_wp-xi2)
        N(19) = 0.5_wp*xi3s*(1.0_wp+xi1)*(1.0_wp+xi2)
        N(20) = 0.5_wp*xi3s*(1.0_wp-xi1)*(1.0_wp+xi2)
        
        sf%nnode = 20
        allocate(sf%N(20), sf%dN_dxi(20,3), sf%dN_dx(20,3))
        sf%N = N
        sf%dN_dxi = 0.0_wp  ! TODO: set dN/dxi in production
        sf%detJ = 1.0_wp
    end subroutine compute_shape_hex20

    ! 27-node hex (C3D27)
    subroutine compute_shape_hex27(xi, sf)
        real(wp), intent(in) :: xi(3)  ! parent (xi,eta,zeta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(27), xi1, xi2, xi3, xi1s, xi2s, xi3s
        
        xi1 = xi(1); xi2 = xi(2); xi3 = xi(3)
        xi1s = 1.0_wp - xi1**2; xi2s = 1.0_wp - xi2**2; xi3s = 1.0_wp - xi3**2
        
        ! corner nodes 1-8
        N(1) = 0.125_wp*xi1*xi2*xi3*(xi1-1)*(xi2-1)*(xi3-1)
        N(2) = 0.125_wp*xi1*xi2*xi3*(xi1+1)*(xi2-1)*(xi3-1)
        N(3) = 0.125_wp*xi1*xi2*xi3*(xi1+1)*(xi2+1)*(xi3-1)
        N(4) = 0.125_wp*xi1*xi2*xi3*(xi1-1)*(xi2+1)*(xi3-1)
        N(5) = 0.125_wp*xi1*xi2*xi3*(xi1-1)*(xi2-1)*(xi3+1)
        N(6) = 0.125_wp*xi1*xi2*xi3*(xi1+1)*(xi2-1)*(xi3+1)
        N(7) = 0.125_wp*xi1*xi2*xi3*(xi1+1)*(xi2+1)*(xi3+1)
        N(8) = 0.125_wp*xi1*xi2*xi3*(xi1-1)*(xi2+1)*(xi3+1)
        
        ! midside nodes 9-20
        N(9)  = 0.25_wp*xi1s*xi2*xi3*(xi2-1)*(xi3-1)
        N(10) = 0.25_wp*xi1*xi2s*xi3*(xi1+1)*(xi3-1)
        N(11) = 0.25_wp*xi1s*xi2*xi3*(xi2+1)*(xi3-1)
        N(12) = 0.25_wp*xi1*xi2s*xi3*(xi1-1)*(xi3-1)
        N(13) = 0.25_wp*xi1s*xi2*xi3*(xi2-1)*(xi3+1)
        N(14) = 0.25_wp*xi1*xi2s*xi3*(xi1+1)*(xi3+1)
        N(15) = 0.25_wp*xi1s*xi2*xi3*(xi2+1)*(xi3+1)
        N(16) = 0.25_wp*xi1*xi2s*xi3*(xi1-1)*(xi3+1)
        N(17) = 0.25_wp*xi1*xi2*xi3s*(xi1-1)*(xi2-1)
        N(18) = 0.25_wp*xi1*xi2*xi3s*(xi1+1)*(xi2-1)
        N(19) = 0.25_wp*xi1*xi2*xi3s*(xi1+1)*(xi2+1)
        N(20) = 0.25_wp*xi1*xi2*xi3s*(xi1-1)*(xi2+1)
        
        ! face interior nodes 21-26
        N(21) = 0.5_wp*xi1s*xi2s*xi3*(xi3-1)
        N(22) = 0.5_wp*xi1s*xi2*xi3s*(xi2-1)
        N(23) = 0.5_wp*xi1*xi2s*xi3s*(xi1+1)
        N(24) = 0.5_wp*xi1s*xi2*xi3s*(xi2+1)
        N(25) = 0.5_wp*xi1*xi2s*xi3s*(xi1-1)
        N(26) = 0.5_wp*xi1s*xi2s*xi3*(xi3+1)
        
        ! body-centered node 27
        N(27) = xi1s*xi2s*xi3s
        
        sf%nnode = 27
        allocate(sf%N(27), sf%dN_dxi(27,3), sf%dN_dx(27,3))
        sf%N = N
        sf%dN_dxi = 0.0_wp  ! TODO: set dN/dxi in production
        sf%detJ = 1.0_wp
    end subroutine compute_shape_hex27

    ! 4-node tet (C3D4)
    subroutine compute_shape_tet4(xi, sf)
        real(wp), intent(in) :: xi(3)  ! parent (xi,eta,zeta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(4), dN_dxi(4,3)
        
        N(1) = xi(1)
        N(2) = xi(2)
        N(3) = xi(3)
        N(4) = 1.0_wp - xi(1) - xi(2) - xi(3)
        
        dN_dxi = reshape([1.0_wp, 0.0_wp, 0.0_wp, -1.0_wp, &
                          0.0_wp, 1.0_wp, 0.0_wp, -1.0_wp, &
                          0.0_wp, 0.0_wp, 1.0_wp, -1.0_wp], [4, 3])
        
        sf%nnode = 4
        allocate(sf%N(4), sf%dN_dxi(4,3), sf%dN_dx(4,3))
        sf%N = N
        sf%dN_dxi = dN_dxi
        sf%detJ = 1.0_wp
    end subroutine compute_shape_tet4

    ! 10-node tet (C3D10)
    subroutine compute_shape_tet10(xi, sf)
        real(wp), intent(in) :: xi(3)  ! parent (xi,eta,zeta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(10), xi1, xi2, xi3, xi12, xi23, xi31
        
        xi1 = xi(1); xi2 = xi(2); xi3 = xi(3)
        xi12 = xi1*xi2; xi23 = xi2*xi3; xi31 = xi3*xi1
        
        ! vertices
        N(1) = xi1*(2.0_wp*xi1 - 1.0_wp)
        N(2) = xi2*(2.0_wp*xi2 - 1.0_wp)
        N(3) = xi3*(2.0_wp*xi3 - 1.0_wp)
        N(4) = (1.0_wp - xi1 - xi2 - xi3)*(2.0_wp*(1.0_wp - xi1 - xi2 - xi3) - 1.0_wp)
        
        ! edge midside
        N(5) = 4.0_wp*xi1*xi2
        N(6) = 4.0_wp*xi2*xi3
        N(7) = 4.0_wp*xi3*xi1
        N(8) = 4.0_wp*xi1*(1.0_wp - xi1 - xi2 - xi3)
        N(9) = 4.0_wp*xi2*(1.0_wp - xi1 - xi2 - xi3)
        N(10) = 4.0_wp*xi3*(1.0_wp - xi1 - xi2 - xi3)
        
        sf%nnode = 10
        allocate(sf%N(10), sf%dN_dxi(10,3), sf%dN_dx(10,3))
        sf%N = N
        sf%dN_dxi = 0.0_wp  ! TODO: set dN/dxi in production
        sf%detJ = 1.0_wp
    end subroutine compute_shape_tet10

    ! 6-node wedge
    subroutine compute_shape_wedge6(xi, sf)
        real(wp), intent(in) :: xi(3)  ! parent (xi,eta,zeta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(6)
        
        N(1) = 0.5_wp*(1.0_wp - xi(1) - xi(2))*(1.0_wp - xi(3))
        N(2) = 0.5_wp*xi(1)*(1.0_wp - xi(3))
        N(3) = 0.5_wp*xi(2)*(1.0_wp - xi(3))
        N(4) = 0.5_wp*(1.0_wp - xi(1) - xi(2))*(1.0_wp + xi(3))
        N(5) = 0.5_wp*xi(1)*(1.0_wp + xi(3))
        N(6) = 0.5_wp*xi(2)*(1.0_wp + xi(3))
        
        sf%nnode = 6
        allocate(sf%N(6), sf%dN_dxi(6,3), sf%dN_dx(6,3))
        sf%N = N
        sf%dN_dxi = 0.0_wp  ! TODO: set dN/dxi in production
        sf%detJ = 1.0_wp
    end subroutine compute_shape_wedge6

    ! 15-node wedge
    subroutine compute_shape_wedge15(xi, sf)
        real(wp), intent(in) :: xi(3)  ! parent (xi,eta,zeta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(15), xi1, xi2, xi3
        
        xi1 = xi(1); xi2 = xi(2); xi3 = xi(3)
        
        ! corners
        N(1) = 0.5_wp*(1.0_wp - xi1 - xi2)*(1.0_wp - xi3)*( -2.0_wp*(1.0_wp - xi1 - xi2) - 2.0_wp*(1.0_wp - xi3) + 1.0_wp)
        N(2) = 0.5_wp*xi1*(1.0_wp - xi3)*( -2.0_wp*xi1 - 2.0_wp*(1.0_wp - xi3) + 1.0_wp)
        N(3) = 0.5_wp*xi2*(1.0_wp - xi3)*( -2.0_wp*xi2 - 2.0_wp*(1.0_wp - xi3) + 1.0_wp)
        N(4) = 0.5_wp*(1.0_wp - xi1 - xi2)*(1.0_wp + xi3)*( -2.0_wp*(1.0_wp - xi1 - xi2) - 2.0_wp*(1.0_wp + xi3) + 1.0_wp)
        N(5) = 0.5_wp*xi1*(1.0_wp + xi3)*( -2.0_wp*xi1 - 2.0_wp*(1.0_wp + xi3) + 1.0_wp)
        N(6) = 0.5_wp*xi2*(1.0_wp + xi3)*( -2.0_wp*xi2 - 2.0_wp*(1.0_wp + xi3) + 1.0_wp)
        
        ! midside
        N(7) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi1*(1.0_wp - xi3)
        N(8) = 2.0_wp*xi1*xi2*(1.0_wp - xi3)
        N(9) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi2*(1.0_wp - xi3)
        N(10) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi1*(1.0_wp + xi3)
        N(11) = 2.0_wp*xi1*xi2*(1.0_wp + xi3)
        N(12) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi2*(1.0_wp + xi3)
        N(13) = 2.0_wp*(1.0_wp - xi1 - xi2)*(1.0_wp - xi3)*(1.0_wp + xi3)
        N(14) = 2.0_wp*xi1*(1.0_wp - xi3)*(1.0_wp + xi3)
        N(15) = 2.0_wp*xi2*(1.0_wp - xi3)*(1.0_wp + xi3)
        
        sf%nnode = 15
        allocate(sf%N(15), sf%dN_dxi(15,3), sf%dN_dx(15,3))
        sf%N = N
        sf%dN_dxi = 0.0_wp  ! TODO: set dN/dxi in production
        sf%detJ = 1.0_wp
    end subroutine compute_shape_wedge15

    ! ------------------------------------------------------
    ! 2D shapes
    ! ------------------------------------------------------

    ! 3-node triangle
    subroutine compute_shape_tri3(xi, sf)
        real(wp), intent(in) :: xi(2)  ! parent (xi,eta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(3), dN_dxi(3,2)
        
        N(1) = xi(1)
        N(2) = xi(2)
        N(3) = 1.0_wp - xi(1) - xi(2)
        
        dN_dxi = reshape([1.0_wp, 0.0_wp, -1.0_wp, &
                          0.0_wp, 1.0_wp, -1.0_wp], [3, 2])
        
        sf%nnode = 3
        allocate(sf%N(3), sf%dN_dxi(3,2), sf%dN_dx(3,2))
        sf%N = N
        sf%dN_dxi = dN_dxi
        sf%detJ = 1.0_wp
    end subroutine compute_shape_tri3

    ! 6-node triangle
    subroutine compute_shape_tri6(xi, sf)
        real(wp), intent(in) :: xi(2)  ! parent (xi,eta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(6), xi1, xi2, xi3
        
        xi1 = xi(1); xi2 = xi(2); xi3 = 1.0_wp - xi1 - xi2
        
        N(1) = xi1*(2.0_wp*xi1 - 1.0_wp)
        N(2) = xi2*(2.0_wp*xi2 - 1.0_wp)
        N(3) = xi3*(2.0_wp*xi3 - 1.0_wp)
        N(4) = 4.0_wp*xi1*xi2
        N(5) = 4.0_wp*xi2*xi3
        N(6) = 4.0_wp*xi3*xi1
        
        sf%nnode = 6
        allocate(sf%N(6), sf%dN_dxi(6,2), sf%dN_dx(6,2))
        sf%N = N
        sf%dN_dxi = 0.0_wp  ! TODO: set dN/dxi in production
        sf%detJ = 1.0_wp
    end subroutine compute_shape_tri6

    ! 4-node quad
    subroutine compute_shape_quad4(xi, sf)
        real(wp), intent(in) :: xi(2)  ! parent (xi,eta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(4), dN_dxi(4,2)
        
        N = 0.25_wp * [ &
            (1-xi(1))*(1-xi(2)), &  ! n1
            (1+xi(1))*(1-xi(2)), &  ! n2
            (1+xi(1))*(1+xi(2)), &  ! n3
            (1-xi(1))*(1+xi(2))]    ! n4
        
        dN_dxi(:,1) = 0.25_wp * [-(1-xi(2)), (1-xi(2)), (1+xi(2)), -(1+xi(2))]
        dN_dxi(:,2) = 0.25_wp * [-(1-xi(1)), -(1+xi(1)), (1+xi(1)), (1-xi(1))]
        
        sf%nnode = 4
        allocate(sf%N(4), sf%dN_dxi(4,2), sf%dN_dx(4,2))
        sf%N = N
        sf%dN_dxi = dN_dxi
        sf%detJ = 1.0_wp
    end subroutine compute_shape_quad4

    ! 8-node quad
    subroutine compute_shape_quad8(xi, sf)
        real(wp), intent(in) :: xi(2)  ! parent (xi,eta)
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(8), xi1, xi2, xi1s, xi2s
        
        xi1 = xi(1); xi2 = xi(2)
        xi1s = 1.0_wp - xi1**2; xi2s = 1.0_wp - xi2**2
        
        N(1) = 0.25_wp*(1.0_wp-xi1)*(1.0_wp-xi2)*(-1.0_wp-xi1-xi2)
        N(2) = 0.25_wp*(1.0_wp+xi1)*(1.0_wp-xi2)*(-1.0_wp+xi1-xi2)
        N(3) = 0.25_wp*(1.0_wp+xi1)*(1.0_wp+xi2)*(-1.0_wp+xi1+xi2)
        N(4) = 0.25_wp*(1.0_wp-xi1)*(1.0_wp+xi2)*(-1.0_wp-xi1+xi2)
        N(5) = 0.5_wp*xi1s*(1.0_wp-xi2)
        N(6) = 0.5_wp*(1.0_wp+xi1)*xi2s
        N(7) = 0.5_wp*xi1s*(1.0_wp+xi2)
        N(8) = 0.5_wp*(1.0_wp-xi1)*xi2s
        
        sf%nnode = 8
        allocate(sf%N(8), sf%dN_dxi(8,2), sf%dN_dx(8,2))
        sf%N = N
        sf%dN_dxi = 0.0_wp  ! TODO: set dN/dxi in production
        sf%detJ = 1.0_wp
    end subroutine compute_shape_quad8

    ! ------------------------------------------------------
    ! 1D shapes
    ! ------------------------------------------------------

    ! 2-node line (beam/truss)
    subroutine compute_shape_line2(xi, sf)
        real(wp), intent(in) :: xi(1)  ! parent coord xi
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(2), dN_dxi(2,1)
        
        N = [0.5_wp*(1-xi(1)), 0.5_wp*(1+xi(1))]
        dN_dxi = reshape([-0.5_wp, 0.5_wp], [2, 1])
        
        sf%nnode = 2
        allocate(sf%N(2), sf%dN_dxi(2,1), sf%dN_dx(2,1))
        sf%N = N
        sf%dN_dxi = dN_dxi
        sf%detJ = 1.0_wp
    end subroutine compute_shape_line2

    ! 3-node line (quadratic)
    subroutine compute_shape_line3(xi, sf)
        real(wp), intent(in) :: xi(1)  ! parent coord xi
        type(shape_function_result), intent(out) :: sf
        real(wp) :: N(3), dN_dxi(3,1), xi_val
        
        xi_val = xi(1)
        
        N(1) = 0.5_wp*xi_val*(xi_val - 1.0_wp)
        N(2) = 1.0_wp - xi_val**2
        N(3) = 0.5_wp*xi_val*(xi_val + 1.0_wp)
        
        dN_dxi(1,1) = xi_val - 0.5_wp
        dN_dxi(2,1) = -2.0_wp*xi_val
        dN_dxi(3,1) = xi_val + 0.5_wp
        
        sf%nnode = 3
        allocate(sf%N(3), sf%dN_dxi(3,1), sf%dN_dx(3,1))
        sf%N = N
        sf%dN_dxi = dN_dxi
        sf%detJ = 1.0_wp
    end subroutine compute_shape_line3

    ! ------------------------------------------------------
    ! Jacobian
    ! ------------------------------------------------------

    ! Physical dN from dN/d parent
    subroutine compute_jacobian(nodes, dN_dxi, detJ, dN_dx)
        real(wp), intent(in) :: nodes(:,:)    ! nodal coords (nnode x 3)
        real(wp), intent(in) :: dN_dxi(:,:)   ! dN/d parent (nnode x dim)
        real(wp), intent(out) :: detJ         ! detJ
        real(wp), allocatable, intent(out) :: dN_dx(:,:)  ! dN/dx (nnode x dim)
        integer :: nnode, dim
        real(wp) :: J(size(dN_dxi,2), size(nodes,2)), invJ(size(dN_dxi,2), size(dN_dxi,2))
        
        nnode = size(nodes, 1)
        dim = size(dN_dxi, 2)
        
        J = matmul(transpose(dN_dxi), nodes)
        
        if (dim == 3) then
            detJ = determinant3(J)
            invJ = inverse3(J)
        else if (dim == 2) then
            detJ = J(1,1)*J(2,2) - J(1,2)*J(2,1)
            invJ = (1.0_wp/detJ) * reshape([J(2,2), -J(1,2), -J(2,1), J(1,1)], [2,2])
        else  ! dim == 1
            detJ = J(1,1)
            invJ = reshape([1.0_wp/J(1,1)], [1,1])
        end if
        
        allocate(dN_dx(nnode, dim))
        dN_dx = matmul(dN_dxi, invJ)
    end subroutine compute_jacobian

    ! 3x3 determinant
    function determinant3(A) result(det)
        real(wp), intent(in) :: A(3,3)
        real(wp) :: det
        det = A(1,1)*(A(2,2)*A(3,3)-A(2,3)*A(3,2)) &
            - A(1,2)*(A(2,1)*A(3,3)-A(2,3)*A(3,1)) &
            + A(1,3)*(A(2,1)*A(3,2)-A(2,2)*A(3,1))
    end function determinant3

    ! 3x3 inverse
    function inverse3(A) result(invA)
        real(wp), intent(in) :: A(3,3)
        real(wp) :: invA(3,3), det
        det = determinant3(A)
        if (abs(det) < 1e-10_wp) then
            write(*,*) "Singular matrix, det=", det
            error stop
        end if
        
        invA(1,1) = (A(2,2)*A(3,3)-A(2,3)*A(3,2))/det
        invA(1,2) = (A(1,3)*A(3,2)-A(1,2)*A(3,3))/det
        invA(1,3) = (A(1,2)*A(2,3)-A(1,3)*A(2,2))/det
        invA(2,1) = (A(2,3)*A(3,1)-A(2,1)*A(3,3))/det
        invA(2,2) = (A(1,1)*A(3,3)-A(1,3)*A(3,1))/det
        invA(2,3) = (A(1,3)*A(2,1)-A(1,1)*A(2,3))/det
        invA(3,1) = (A(2,1)*A(3,2)-A(2,2)*A(3,1))/det
        invA(3,2) = (A(1,2)*A(3,1)-A(1,1)*A(3,2))/det
        invA(3,3) = (A(1,1)*A(2,2)-A(1,2)*A(2,1))/det
    end function inverse3

end module ElemGaussInt