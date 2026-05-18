!===============================================================================
! MODULE:  MD_Base_ElemLib
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Impl (element library)
! BRIEF:   Element library core: Gauss point generation, shape function
!          evaluation, and Jacobian computation. Topology-aware interfaces.
!===============================================================================
!   Unified interface for element library operations: Gauss point generation,
!   shape function evaluation, and Jacobian computation. Wraps lower-level numerical
!   core modules (UF_GaussQuad, UF_ShapeFunc, UF_Jacobian) to provide element
!   topology-aware interfaces.
!
! Theory chain:
!   Gauss quadrature: Numerical integration using weighted Gauss points for accurate
!   integration of polynomial functions. Order determines number of points (1-5 for
!   line, up to 7 for triangle, n*n for quad, n*n*n for hex). Shape functions:
!   Interpolation functions N(ξ) for mapping from natural coordinates to physical
!   space. Jacobian: Transformation matrix J = ∂x/�??mapping natural to physical
!   coordinates, det(J) for volume/area scaling. Ref: Finite element method,
!   numerical integration, isoparametric mapping.
!
! Logic chain:
!   UF_GetGaussPoints: Input (topo, order, nDim) -> Select topology -> Call lower-level
!   Gauss routine -> Output (gaussCoords, weights). UF_GetShapeFunctions: Input (elemName, xi) ->
!   Parse element name -> Select shape function routine -> Evaluate N and dN/dξ ->
!   Output (sf). UF_ComputeJacobian: Input (coords, dN_dxi) -> Transpose coords ->
!   Call jacobian_1d/2d/3d -> Compute detJ and dN/dx -> Output (detJ, dN_dx).
!   Dependency: L3_MD Base -> L5_RT (UF_GaussQuad, UF_ShapeFunc, UF_Jacobian).
!
! Computation chain:
!   GetGaussPoints: Select topology (Point/Line/Tri/Quad/Tet/Hex/Wedge/Pyramid) ->
!   Determine npts from order -> Allocate arrays -> Call topology-specific Gauss routine
!   (gauss_line/triangle/quad/tetrahedron/hexahedron/prism/pyramid) -> Fill gaussCoords
!   and weights. GetShapeFunctions: Parse elemName (B31, CPE4, C3D8, etc.) -> Determine
!   nNode and nDim -> Call shape function routine (shape_line2/quad4/hex8, etc.) ->
!   Store N and dN_dxi in ShapeFuncResult. ComputeJacobian: Transpose coords (nDim, nNode)
!   to (nNode, nDim) -> Call jacobian_1d/2d/3d based on nDim -> Compute detJ and dN/dx.
!
! Data chain:
!   Input: topo (topology enum), order (integration order), nDim (spatial dimension),
!   elemName (element name string), xi (natural coordinates), coords (nodal coordinates),
!   dN_dxi (shape function derivatives in natural coordinates).
!   Output: gaussCoords (Gauss point coordinates), weights (integration weights),
!   sf (ShapeFuncResult with N, dN_dxi), detJ (Jacobian determinant), dN_dx (shape function
!   derivatives in physical coordinates).
!   State: Element topology state (topo), integration order state (order), shape function
!   state (sf%numNodes, sf%numIntPoints).
!
! Data structure:
!   Container path: Base (element library core).
!   - Desc: N/A (no persistent descriptors, element types from enums).
!   - Algo: Gauss quadrature algorithms (gauss_line, gauss_triangle, etc.), shape function
!   algorithms (shape_line2, shape_quad4, etc.), Jacobian algorithms (jacobian_1d/2d/3d).
!   - Ctx: N/A (stateless functions, no context storage).
!   - State: N/A (stateless, inputs/outputs only).
!   Supporting types: ShapeFuncResult (from MD_Element_Types), topology enums (MD_MODEL_UF_TOPO_*).
!
! Three-step mapping:
!   GetGaussPoints: Step level (element integration setup, compute Gauss points for element).
!   GetShapeFunctions: Step level (element evaluation, compute shape functions at point).
!   ComputeJacobian: Step level (element evaluation, compute Jacobian at point).
!
! Contents (A-Z):
!   Subroutines: UF_ComputeJacobian, UF_GetGaussPoints, UF_GetShapeFunctions
!
! Notes:
!   Wraps lower-level numerical core: UF_GaussQuad (Gauss quadrature), UF_ShapeFunc (shape
!   functions), UF_Jacobian (Jacobian computation). Supports all standard element topologies:
!   Point, Line (2/3 nodes), Triangle (3/6 nodes), Quad (4/8/9 nodes), Tet (4/10 nodes),
!   Hex (8/20/27 nodes), Wedge (6/15 nodes), Pyramid (5/13 nodes). Element name parsing
!   supports Abaqus-style names (B31, CPE4, C3D8, etc.). ToUpper function needed for case-
!   insensitive element name matching (should USE MD_BaseMathUtils).
!   Logic/Computation chain diagrams: see MD_Base_ElemLib_Core_Chains.md
!
! Status: CORE | Last verified: 2026-03-02
! Theory: N/A
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Model | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Model/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Model | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Base_ElemLib
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_Enums, ONLY: MD_MODEL_UF_TOPO_Line, MD_MODEL_UF_TOPO_Tri, MD_MODEL_UF_TOPO_Quad, &
         MD_MODEL_UF_TOPO_Tet, MD_MODEL_UF_TOPO_Hex, MD_MODEL_UF_TOPO_Wedge, MD_MODEL_UF_TOPO_Pyramid, MD_MODEL_UF_TOPO_Point
    USE MD_Base_MathUtils, ONLY: ToUpper
    USE MD_Elem_Types, ONLY: ShapeFuncResult
    USE UF_GaussQuad, ONLY: gauss_line, gauss_triangle, gauss_quad, &
         gauss_tetrahedron, gauss_hexahedron, gauss_prism, gauss_pyramid
    USE UF_Jacobian, ONLY: jacobian_1d, jacobian_2d, jacobian_3d
    USE UF_ShapeFunc, ONLY: shape_line2, shape_line3, shape_tri3, shape_tri6, &
         shape_quad4, shape_quad8, shape_quad9, shape_tet4, shape_tet10, &
         shape_hex8, shape_hex20, shape_hex27, shape_prism6, shape_prism15, &
         shape_pyram5, shape_pyram13
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: UF_ComputeJacobian, UF_GetGaussPoints, UF_GetShapeFunctions

CONTAINS

    SUBROUTINE UF_ComputeJacobian(coords, dN_dxi, detJ, dN_dx)
        REAL(wp), INTENT(IN) :: coords(:,:), dN_dxi(:,:)
        REAL(wp), INTENT(OUT) :: detJ
        REAL(wp), INTENT(OUT) :: dN_dx(:,:)

        INTEGER(i4) :: nNode, nDim, ierr
        REAL(wp) :: Jac1, coords_T(27, 3), Jac2(2,2), Jac3(3,3)
        REAL(wp) :: dNdx_vec(27), dNdy_vec(27), dNdz_vec(27)

        nNode = SIZE(dN_dxi, 1)
        nDim = SIZE(dN_dxi, 2)

        ! UF_Jacobian expects coords (nNode, nDim), we have (nDim, nNode)
        coords_T(1:nNode, 1:nDim) = TRANSPOSE(coords(1:nDim, 1:nNode))

        IF (nDim == 1) THEN
            CALL jacobian_1d(dN_dxi(1:nNode, 1), coords(1, 1:nNode), Jac1, detJ, dNdx_vec(1:nNode), ierr)
            dN_dx(1:nNode, 1) = dNdx_vec(1:nNode)
        ELSE IF (nDim == 2) THEN
            CALL jacobian_2d(dN_dxi(1:nNode, 1), dN_dxi(1:nNode, 2), coords_T(1:nNode, 1:2), &
                             Jac2, detJ, dNdx=dNdx_vec(1:nNode), dNdy=dNdy_vec(1:nNode), ierr=ierr)
            dN_dx(1:nNode, 1) = dNdx_vec(1:nNode)
            dN_dx(1:nNode, 2) = dNdy_vec(1:nNode)
        ELSE
            CALL jacobian_3d(dN_dxi(1:nNode, 1), dN_dxi(1:nNode, 2), dN_dxi(1:nNode, 3), &
                             coords_T(1:nNode, 1:3), Jac3, detJ, dNdx=dNdx_vec(1:nNode), &
                             dNdy=dNdy_vec(1:nNode), dNdz=dNdz_vec(1:nNode), ierr=ierr)
            dN_dx(1:nNode, 1) = dNdx_vec(1:nNode)
            dN_dx(1:nNode, 2) = dNdy_vec(1:nNode)
            dN_dx(1:nNode, 3) = dNdz_vec(1:nNode)
        END IF

    END SUBROUTINE UF_ComputeJacobian

    SUBROUTINE UF_GetGaussPoints(topo, order, nDim, gaussCoords, weights)
        INTEGER(i4), INTENT(IN) :: topo, order, nDim
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: gaussCoords(:,:), weights(:)

        INTEGER(i4) :: npts, n
        REAL(wp) :: xi(125), eta(125), zeta(125), w(125)

        npts = 0
        SELECT CASE (topo)
        CASE (MD_MODEL_UF_TOPO_Point)
            npts = 1
            ALLOCATE(gaussCoords(npts, MAX(1,nDim)), weights(npts))
            gaussCoords = 0.0_wp
            weights(1) = 1.0_wp

        CASE (MD_MODEL_UF_TOPO_Line)
            npts = MAX(1, MIN(order, 5))
            ALLOCATE(gaussCoords(npts, MAX(1,nDim)), weights(npts))
            CALL gauss_line(npts, xi, w)
            gaussCoords(1:npts, 1) = xi(1:npts)
            weights(1:npts) = w(1:npts)
            IF (nDim > 1) gaussCoords(1:npts, 2:nDim) = 0.0_wp

        CASE (MD_MODEL_UF_TOPO_Tri)
            npts = MAX(1, MIN(order, 7))
            IF (npts == 2) npts = 3
            ALLOCATE(gaussCoords(npts, MAX(1,nDim)), weights(npts))
            CALL gauss_triangle(npts, xi, eta, w)
            gaussCoords(1:npts, 1) = xi(1:npts)
            gaussCoords(1:npts, 2) = eta(1:npts)
            weights(1:npts) = w(1:npts)
            IF (nDim > 2) gaussCoords(1:npts, 3) = 0.0_wp

        CASE (MD_MODEL_UF_TOPO_Quad)
            n = MAX(1, MIN(order, 5))
            npts = n * n
            ALLOCATE(gaussCoords(npts, MAX(1,nDim)), weights(npts))
            CALL gauss_quad(n, xi, eta, w)
            gaussCoords(1:npts, 1) = xi(1:npts)
            gaussCoords(1:npts, 2) = eta(1:npts)
            weights(1:npts) = w(1:npts)
            IF (nDim > 2) gaussCoords(1:npts, 3) = 0.0_wp

        CASE (MD_MODEL_UF_TOPO_Tet)
            npts = MAX(1, MIN(order, 5))
            IF (npts == 2) npts = 4
            ALLOCATE(gaussCoords(npts, MAX(1,nDim)), weights(npts))
            CALL gauss_tetrahedron(npts, xi, eta, zeta, w)
            gaussCoords(1:npts, 1) = xi(1:npts)
            gaussCoords(1:npts, 2) = eta(1:npts)
            gaussCoords(1:npts, 3) = zeta(1:npts)
            weights(1:npts) = w(1:npts)

        CASE (MD_MODEL_UF_TOPO_Hex)
            n = MAX(1, MIN(order, 5))
            npts = n * n * n
            ALLOCATE(gaussCoords(npts, MAX(1,nDim)), weights(npts))
            CALL gauss_hexahedron(n, xi, eta, zeta, w)
            gaussCoords(1:npts, 1) = xi(1:npts)
            gaussCoords(1:npts, 2) = eta(1:npts)
            gaussCoords(1:npts, 3) = zeta(1:npts)
            weights(1:npts) = w(1:npts)

        CASE (MD_MODEL_UF_TOPO_Wedge)
            npts = 6
            IF (order >= 2) npts = 9
            ALLOCATE(gaussCoords(npts, MAX(1,nDim)), weights(npts))
            CALL gauss_prism(3, npts/3, xi, eta, zeta, w)
            gaussCoords(1:npts, 1) = xi(1:npts)
            gaussCoords(1:npts, 2) = eta(1:npts)
            gaussCoords(1:npts, 3) = zeta(1:npts)
            weights(1:npts) = w(1:npts)

        CASE (MD_MODEL_UF_TOPO_Pyramid)
            npts = 5
            IF (order >= 2) npts = 8
            ALLOCATE(gaussCoords(npts, MAX(1,nDim)), weights(npts))
            CALL gauss_pyramid(npts, xi, eta, zeta, w)
            gaussCoords(1:npts, 1) = xi(1:npts)
            gaussCoords(1:npts, 2) = eta(1:npts)
            gaussCoords(1:npts, 3) = zeta(1:npts)
            weights(1:npts) = w(1:npts)

        CASE DEFAULT
            npts = 1
            ALLOCATE(gaussCoords(1, MAX(1,nDim)), weights(1))
            gaussCoords = 0.0_wp
            weights(1) = 1.0_wp
        END SELECT

    END SUBROUTINE UF_GetGaussPoints

    SUBROUTINE UF_GetShapeFunctions(elemName, xi, sf)
        CHARACTER(LEN=*), INTENT(IN) :: elemName
        REAL(wp), INTENT(IN) :: xi(:)
        TYPE(ShapeFuncResult), INTENT(INOUT) :: sf

        CHARACTER(LEN=32) :: name
        INTEGER(i4) :: nNode, nDim, ierr
        REAL(wp) :: Nvec(27), dNdxi_vec(27), dNdeta_vec(27), dNdzeta_vec(27)

        name = elemName
        CALL ToUpper(name)

        nNode = 0
        nDim = 1
        IF (SIZE(xi) >= 2) nDim = 2
        IF (SIZE(xi) >= 3) nDim = 3

        ! Clear and allocate for single integration point
        CALL sf%Clear()
        sf%numIntPoints = 1

        ! 1D elements
        IF (INDEX(name, 'B31') > 0 .OR. INDEX(name, 'T2D2') > 0 .OR. INDEX(name, 'T3D2') > 0) THEN
            nNode = 2
            sf%numNodes = nNode
            CALL sf%Init(nNode, 1)
            CALL shape_line2(xi(1), Nvec(1:2), dNdxi_vec(1:2))
            sf%N(1:nNode, 1) = Nvec(1:nNode)
            IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, nDim))
            sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
            RETURN
        END IF
    IF (INDEX(name, 'B32') > 0 .OR. INDEX(name, 'T3D3') > 0) THEN
      nNode = 3
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_line3(xi(1), Nvec(1:3), dNdxi_vec(1:3))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, nDim))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      RETURN
    END IF

    ! 2D triangle
    IF (INDEX(name, 'CPE3') > 0 .OR. INDEX(name, 'CPS3') > 0 .OR. INDEX(name, 'CAX3') > 0 .OR. &
        INDEX(name, 'S3') > 0 .OR. INDEX(name, 'DC2D3') > 0) THEN
      nNode = 3
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_tri3(xi(1), xi(2), Nvec(1:3), dNdxi_vec(1:3), dNdeta_vec(1:3))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 2))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      RETURN
    END IF
    IF (INDEX(name, 'CPE6') > 0 .OR. INDEX(name, 'CPS6') > 0 .OR. INDEX(name, 'S3R') > 0 .OR. &
        INDEX(name, 'DC2D6') > 0) THEN
      nNode = 6
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_tri6(xi(1), xi(2), Nvec(1:6), dNdxi_vec(1:6), dNdeta_vec(1:6))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 2))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      RETURN
    END IF

    ! 2D quad
    IF (INDEX(name, 'CPE4') > 0 .OR. INDEX(name, 'CPS4') > 0 .OR. INDEX(name, 'CAX4') > 0 .OR. &
        INDEX(name, 'S4') > 0 .OR. INDEX(name, 'S4R') > 0 .OR. INDEX(name, 'M3D4') > 0 .OR. &
        INDEX(name, 'DC2D4') > 0 .OR. INDEX(name, 'AC2D4') > 0) THEN
      nNode = 4
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_quad4(xi(1), xi(2), Nvec(1:4), dNdxi_vec(1:4), dNdeta_vec(1:4))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 2))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      RETURN
    END IF
    IF (INDEX(name, 'CPE8') > 0 .OR. INDEX(name, 'CPS8') > 0 .OR. INDEX(name, 'S8R') > 0 .OR. &
        INDEX(name, 'M3D8R') > 0 .OR. INDEX(name, 'DC2D8') > 0) THEN
      nNode = 8
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_quad8(xi(1), xi(2), Nvec(1:8), dNdxi_vec(1:8), dNdeta_vec(1:8))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 2))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      RETURN
    END IF
    IF (INDEX(name, 'S9R5') > 0) THEN
      nNode = 9
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_quad9(xi(1), xi(2), Nvec(1:9), dNdxi_vec(1:9), dNdeta_vec(1:9))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 2))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      RETURN
    END IF

    ! 3D tet
    IF (INDEX(name, 'C3D4') > 0 .OR. INDEX(name, 'DC3D4') > 0 .OR. INDEX(name, 'AC3D4') > 0) THEN
      nNode = 4
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_tet4(xi(1), xi(2), xi(3), Nvec(1:4), dNdxi_vec(1:4), dNdeta_vec(1:4), dNdzeta_vec(1:4))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
      RETURN
    END IF
    IF (INDEX(name, 'C3D10') > 0 .OR. INDEX(name, 'DC3D10') > 0 .OR. INDEX(name, 'AC3D10') > 0) THEN
      nNode = 10
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_tet10(xi(1), xi(2), xi(3), Nvec(1:10), dNdxi_vec(1:10), dNdeta_vec(1:10), dNdzeta_vec(1:10))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
      RETURN
    END IF

    ! 3D hex
    IF (INDEX(name, 'C3D8') > 0 .OR. INDEX(name, 'DC3D8') > 0 .OR. INDEX(name, 'AC3D8') > 0) THEN
      nNode = 8
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_hex8(xi(1), xi(2), xi(3), Nvec(1:8), dNdxi_vec(1:8), dNdeta_vec(1:8), dNdzeta_vec(1:8))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
      RETURN
    END IF
    IF (INDEX(name, 'C3D20') > 0 .OR. INDEX(name, 'DC3D20') > 0 .OR. INDEX(name, 'AC3D20') > 0) THEN
      nNode = 20
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_hex20(xi(1), xi(2), xi(3), Nvec(1:20), dNdxi_vec(1:20), dNdeta_vec(1:20), dNdzeta_vec(1:20))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
      RETURN
    END IF
    IF (INDEX(name, 'C3D27') > 0 .OR. INDEX(name, 'DC3D27') > 0 .OR. INDEX(name, 'AC3D27') > 0) THEN
      nNode = 27
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_hex27(xi(1), xi(2), xi(3), Nvec(1:27), dNdxi_vec(1:27), dNdeta_vec(1:27), dNdzeta_vec(1:27))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
      RETURN
    END IF

    ! 3D wedge
    IF (INDEX(name, 'C3D6') > 0 .OR. INDEX(name, 'DC3D6') > 0 .OR. INDEX(name, 'AC3D6') > 0) THEN
      nNode = 6
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_prism6(xi(1), xi(2), xi(3), Nvec(1:6), dNdxi_vec(1:6), dNdeta_vec(1:6), dNdzeta_vec(1:6))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
      RETURN
    END IF
    IF (INDEX(name, 'C3D15') > 0 .OR. INDEX(name, 'DC3D15') > 0 .OR. INDEX(name, 'AC3D15') > 0) THEN
      nNode = 15
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_prism15(xi(1), xi(2), xi(3), Nvec(1:15), dNdxi_vec(1:15), dNdeta_vec(1:15), dNdzeta_vec(1:15))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
      RETURN
    END IF

    ! 3D pyramid
    IF (INDEX(name, 'C3D5') > 0 .OR. INDEX(name, 'DC3D5') > 0) THEN
      nNode = 5
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_pyram5(xi(1), xi(2), xi(3), Nvec(1:5), dNdxi_vec(1:5), dNdeta_vec(1:5), dNdzeta_vec(1:5))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
      RETURN
    END IF
    IF (INDEX(name, 'C3D13') > 0 .OR. INDEX(name, 'DC3D13') > 0) THEN
      nNode = 13
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_pyram13(xi(1), xi(2), xi(3), Nvec(1:13), dNdxi_vec(1:13), dNdeta_vec(1:13), dNdzeta_vec(1:13))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
      RETURN
    END IF

    ! Fallback: default to quad4 for 2D, hex8 for 3D
    IF (nDim == 2) THEN
      nNode = 4
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_quad4(xi(1), xi(2), Nvec(1:4), dNdxi_vec(1:4), dNdeta_vec(1:4))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 2))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
    ELSE
      nNode = 8
      sf%numNodes = nNode
      CALL sf%Init(nNode, 1)
      CALL shape_hex8(xi(1), xi(2), xi(3), Nvec(1:8), dNdxi_vec(1:8), dNdeta_vec(1:8), dNdzeta_vec(1:8))
      sf%N(1:nNode, 1) = Nvec(1:nNode)
      IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(nNode, 3))
      sf%dN_dxi(1:nNode, 1) = dNdxi_vec(1:nNode)
      sf%dN_dxi(1:nNode, 2) = dNdeta_vec(1:nNode)
      sf%dN_dxi(1:nNode, 3) = dNdzeta_vec(1:nNode)
    END IF

    END SUBROUTINE UF_GetShapeFunctions

END MODULE MD_Base_ElemLib