!===============================================================================
! MODULE: PH_Elem_ShapeFunc
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Core
! BRIEF:  Shape function calculations for various element types
! **W2**：**N/B**、Jacobian、**B** 矩阵由单元几何与 **`PH_Elem_Desc`** / IP 上下文驱动；纯数学核，不持有材料状态。
!===============================================================================
MODULE PH_Elem_ShapeFunc
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_ShapeFunc_Def, ONLY: PH_Elem_ShapeFunc_Ctx
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_Elem_ShapeFunc_Ctx
  PUBLIC :: ComputeShapeFunc
  PUBLIC :: ComputeJacobian
  PUBLIC :: ComputeStrainDisplacementMatrix
  
  !-----------------------------------------------------------------------------
  ! Abstract interface for shape function subroutines
  !-----------------------------------------------------------------------------
  ABSTRACT INTERFACE
    SUBROUTINE ShapeFuncHandler(xi, sf)
      IMPORT :: wp
      REAL(wp), INTENT(IN) :: xi(:)
      CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    END SUBROUTINE ShapeFuncHandler
  END INTERFACE
  
CONTAINS

  !=============================================================================
  ! Subroutine: ComputeShapeFunc
  ! Purpose: Main dispatcher - compute shape functions based on element type
  !=============================================================================
  SUBROUTINE ComputeShapeFunc(elem_type_id, xi, sf)
    INTEGER(i4), INTENT(IN) :: elem_type_id    ! Element type ID (MD_ELEM_C3D8 etc.)
    REAL(wp), INTENT(IN) :: xi(:)              ! Natural coordinates
    TYPE(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf ! Output result
    
    ! Dispatch based on element type
    SELECT CASE(elem_type_id)
      !--- 3D Solid Elements - Hexahedral ---
      CASE(2)  ! C3D8
        CALL ComputeShape_Hex8(xi, sf)
      CASE(3)  ! C3D8R
        CALL ComputeShape_Hex8(xi, sf)  ! Same shape func, different integration
      CASE(20) ! C3D20
        CALL ComputeShape_Hex20(xi, sf)
      CASE(21) ! C3D20R
        CALL ComputeShape_Hex20(xi, sf)
      CASE(22)  ! C3D27
        CALL ComputeShape_Hex27(xi, sf)
      CASE(23)  ! C3D27R
        CALL ComputeShape_Hex27(xi, sf)
      
      !--- 3D Solid Elements - Tetrahedral ---
      CASE(1)  ! C3D4
        CALL ComputeShape_Tet4(xi, sf)
      CASE(10) ! C3D10
        CALL ComputeShape_Tet10(xi, sf)
      
      !--- 3D Solid Elements - Wedge ---
      CASE(15) ! C3D6
        CALL ComputeShape_Wedge6(xi, sf)
      CASE(16) ! C3D15
        CALL ComputeShape_Wedge15(xi, sf)
      
      !--- 2D Solid Elements - Quadrilateral ---
      CASE(30) ! CPE4
        CALL ComputeShape_Quad4(xi, sf)
      CASE(31) ! CPE4R
        CALL ComputeShape_Quad4(xi, sf)
      CASE(32) ! CPE8
        CALL ComputeShape_Quad8(xi, sf)
      CASE(33) ! CPE8R
        CALL ComputeShape_Quad8(xi, sf)
      CASE(40) ! CPS4
        CALL ComputeShape_Quad4(xi, sf)
      CASE(41) ! CPS4R
        CALL ComputeShape_Quad4(xi, sf)
      CASE(42) ! CPS8
        CALL ComputeShape_Quad8(xi, sf)
      CASE(50) ! S4
        CALL ComputeShape_Quad4(xi, sf)
      CASE(51) ! S4R
        CALL ComputeShape_Quad4(xi, sf)
      CASE(52) ! S8
        CALL ComputeShape_Quad8(xi, sf)
      CASE(53) ! S8R
        CALL ComputeShape_Quad8(xi, sf)
      
      !--- 2D Solid Elements - Triangular ---
      CASE(35) ! CPE3
        CALL ComputeShape_Tri3(xi, sf)
      CASE(36) ! CPE6
        CALL ComputeShape_Tri6(xi, sf)
      CASE(45) ! CPS3
        CALL ComputeShape_Tri3(xi, sf)
      CASE(46) ! CPS6
        CALL ComputeShape_Tri6(xi, sf)
      
      !--- 1D Elements ---
      CASE(70) ! B21
        CALL ComputeShape_Line2(xi, sf)
      CASE(71) ! B22
        CALL ComputeShape_Line3(xi, sf)
      CASE(80) ! T2D2
        CALL ComputeShape_Line2(xi, sf)
      CASE(81) ! T2D3
        CALL ComputeShape_Line3(xi, sf)
      
      CASE DEFAULT
        WRITE(*,*) "ERROR: Unsupported element type ID:", elem_type_id
        ERROR STOP "Unsupported element type in ComputeShapeFunc"
    END SELECT
  END SUBROUTINE ComputeShapeFunc

  !=============================================================================
  ! Subroutine: ComputeJacobian
  ! Purpose: Compute Jacobian matrix and transform dN/dxi to dN/dx
  !=============================================================================
  SUBROUTINE ComputeJacobian(sf, coords)
    TYPE(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    REAL(wp), INTENT(IN) :: coords(:,:)      ! [dim, nnode] nodal coordinates
    
    INTEGER(i4) :: i, j, k
    REAL(wp) :: J_tmp(3,3)
    
    IF (.NOT. ALLOCATED(sf%dN_dxi)) THEN
      ERROR STOP "ComputeJacobian: dN_dxi not allocated"
    END IF
    
    ! Initialize Jacobian
    J_tmp = 0.0_wp
    DO k = 1, sf%nnode
      DO i = 1, sf%dim
        DO j = 1, sf%dim
          J_tmp(i,j) = J_tmp(i,j) + sf%dN_dxi(k,i) * coords(j,k)
        END DO
      END DO
    END DO
    
    ! Allocate and copy
    IF (.NOT. ALLOCATED(sf%J)) ALLOCATE(sf%J(sf%dim, sf%dim))
    IF (.NOT. ALLOCATED(sf%J_inv)) ALLOCATE(sf%J_inv(sf%dim, sf%dim))
    
    sf%J = J_tmp(1:sf%dim, 1:sf%dim)
    
    ! Compute determinant
    SELECT CASE(sf%dim)
      CASE(1)
        sf%detJ = sf%J(1,1)
      CASE(2)
        sf%detJ = sf%J(1,1)*sf%J(2,2) - sf%J(1,2)*sf%J(2,1)
      CASE(3)
        sf%detJ = sf%J(1,1)*(sf%J(2,2)*sf%J(3,3) - sf%J(2,3)*sf%J(3,2)) &
                - sf%J(1,2)*(sf%J(2,1)*sf%J(3,3) - sf%J(2,3)*sf%J(3,1)) &
                + sf%J(1,3)*(sf%J(2,1)*sf%J(3,2) - sf%J(2,2)*sf%J(3,1))
    END SELECT
    
    ! Check for invalid Jacobian
    IF (sf%detJ <= 0.0_wp) THEN
      WRITE(*,*) "ERROR: Non-positive Jacobian determinant:", sf%detJ
      ERROR STOP "Invalid element geometry"
    END IF
    
    ! Compute inverse Jacobian
    CALL InvertMatrix(sf%J, sf%J_inv, sf%dim)
    
    ! Transform dN/dxi to dN/dx: dN/dx = J^(-1) * dN/dxi
    IF (.NOT. ALLOCATED(sf%dN_dx)) ALLOCATE(sf%dN_dx(sf%nnode, sf%dim))
    DO k = 1, sf%nnode
      DO i = 1, sf%dim
        sf%dN_dx(k,i) = 0.0_wp
        DO j = 1, sf%dim
          sf%dN_dx(k,i) = sf%dN_dx(k,i) + sf%J_inv(i,j) * sf%dN_dxi(k,j)
        END DO
      END DO
    END DO
  END SUBROUTINE ComputeJacobian

  !=============================================================================
  ! Subroutine: ComputeStrainDisplacementMatrix
  ! Purpose: Compute B-matrix (strain-displacement matrix) at integration point
  !=============================================================================
  SUBROUTINE ComputeStrainDisplacementMatrix(sf, ndofel, B_matrix)
    TYPE(PH_Elem_ShapeFunc_Ctx), INTENT(IN) :: sf
    INTEGER(i4), INTENT(IN) :: ndofel          ! Total DOFs per element
    REAL(wp), INTENT(OUT) :: B_matrix(:,:)     ! [nstrs, ndofel] B-matrix
    
    INTEGER(i4) :: i, node, dof_idx
    REAL(wp) :: dNdx, dNdy, dNdz
    
    B_matrix = 0.0_wp
    
    SELECT CASE(sf%dim)
      CASE(2)
        ! 2D: [εxx, εyy, γxy]^T
        DO i = 1, sf%nnode
          dNdx = sf%dN_dx(i,1)
          dNdy = sf%dN_dx(i,2)
          
          ! Node DOF mapping (assuming 2 DOFs per node in 2D)
          dof_idx = (i-1) * 2
          
          IF (dof_idx+1 <= ndofel) THEN
            B_matrix(1, dof_idx+1) = dNdx  ! εxx
            B_matrix(2, dof_idx+1) = dNdy  ! εyy
            B_matrix(3, dof_idx+1) = dNdy  ! γxy
          END IF
          
          IF (dof_idx+2 <= ndofel) THEN
            B_matrix(3, dof_idx+2) = dNdx  ! γxy
          END IF
        END DO
        
      CASE(3)
        ! 3D: [εxx, εyy, εzz, γxy, γyz, γzx]^T
        DO i = 1, sf%nnode
          dNdx = sf%dN_dx(i,1)
          dNdy = sf%dN_dx(i,2)
          dNdz = sf%dN_dx(i,3)
          
          ! Node DOF mapping (assuming 3 DOFs per node in 3D)
          dof_idx = (i-1) * 3
          
          IF (dof_idx+1 <= ndofel) THEN
            B_matrix(1, dof_idx+1) = dNdx  ! εxx
            B_matrix(4, dof_idx+1) = dNdy  ! γxy
            B_matrix(6, dof_idx+1) = dNdz  ! γzx
          END IF
          
          IF (dof_idx+2 <= ndofel) THEN
            B_matrix(2, dof_idx+2) = dNdy  ! εyy
            B_matrix(4, dof_idx+2) = dNdx  ! γxy
            B_matrix(5, dof_idx+2) = dNdz  ! γyz
          END IF
          
          IF (dof_idx+3 <= ndofel) THEN
            B_matrix(3, dof_idx+3) = dNdz  ! εzz
            B_matrix(5, dof_idx+3) = dNdy  ! γyz
            B_matrix(6, dof_idx+3) = dNdx  ! γzx
          END IF
        END DO
    END SELECT
  END SUBROUTINE ComputeStrainDisplacementMatrix

  !=============================================================================
  ! Helper: Matrix inversion
  !=============================================================================
  SUBROUTINE InvertMatrix(A, A_inv, n)
    REAL(wp), INTENT(IN) :: A(:,:)
    REAL(wp), INTENT(OUT) :: A_inv(:,:)
    INTEGER(i4), INTENT(IN) :: n
    
    REAL(wp) :: det, inv_det
    REAL(wp) :: tmp(3,3)
    
    IF (n > 3) THEN
      ERROR STOP "InvertMatrix: Only supports up to 3x3 matrices"
    END IF
    
    ! Compute determinant (already computed, but verify)
    SELECT CASE(n)
      CASE(1)
        det = A(1,1)
      CASE(2)
        det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      CASE(3)
        det = A(1,1)*(A(2,2)*A(3,3) - A(2,3)*A(3,2)) &
            - A(1,2)*(A(2,1)*A(3,3) - A(2,3)*A(3,1)) &
            + A(1,3)*(A(2,1)*A(3,2) - A(2,2)*A(3,1))
    END SELECT
    
    IF (ABS(det) < 1.0E-15_wp) THEN
      ERROR STOP "InvertMatrix: Matrix is singular"
    END IF
    
    inv_det = 1.0_wp / det
    
    ! Compute inverse
    SELECT CASE(n)
      CASE(1)
        tmp(1,1) = 1.0_wp
        A_inv(1,1) = tmp(1,1) * inv_det
        
      CASE(2)
        tmp(1,1) = A(2,2); tmp(1,2) = -A(1,2)
        tmp(2,1) = -A(2,1); tmp(2,2) = A(1,1)
        A_inv = tmp(1:n,1:n) * inv_det
        
      CASE(3)
        tmp(1,1) = A(2,2)*A(3,3) - A(2,3)*A(3,2)
        tmp(1,2) = A(1,3)*A(3,2) - A(1,2)*A(3,3)
        tmp(1,3) = A(1,2)*A(2,3) - A(1,3)*A(2,2)
        tmp(2,1) = A(2,3)*A(3,1) - A(2,1)*A(3,3)
        tmp(2,2) = A(1,1)*A(3,3) - A(1,3)*A(3,1)
        tmp(2,3) = A(1,3)*A(2,1) - A(1,1)*A(2,3)
        tmp(3,1) = A(2,1)*A(3,2) - A(2,2)*A(3,1)
        tmp(3,2) = A(1,2)*A(3,1) - A(1,1)*A(3,2)
        tmp(3,3) = A(1,1)*A(2,2) - A(1,2)*A(2,1)
        A_inv = tmp(1:n,1:n) * inv_det
    END SELECT
  END SUBROUTINE InvertMatrix

  !=============================================================================
  ! Shape Function Implementations
  !=============================================================================
  
  !-----------------------------------------------------------------------------
  ! 8-node hexahedral element (C3D8, C3D8R, etc.)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Hex8(xi, sf)
    REAL(wp), INTENT(IN) :: xi(3)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(8), dN_dxi(8,3)
    
    sf%nnode = 8
    sf%dim = 3
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(8))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(8,3))
    
    ! Shape functions
    N(1) = 0.125_wp * (1.0_wp-xi(1))*(1.0_wp-xi(2))*(1.0_wp-xi(3))
    N(2) = 0.125_wp * (1.0_wp+xi(1))*(1.0_wp-xi(2))*(1.0_wp-xi(3))
    N(3) = 0.125_wp * (1.0_wp+xi(1))*(1.0_wp+xi(2))*(1.0_wp-xi(3))
    N(4) = 0.125_wp * (1.0_wp-xi(1))*(1.0_wp+xi(2))*(1.0_wp-xi(3))
    N(5) = 0.125_wp * (1.0_wp-xi(1))*(1.0_wp-xi(2))*(1.0_wp+xi(3))
    N(6) = 0.125_wp * (1.0_wp+xi(1))*(1.0_wp-xi(2))*(1.0_wp+xi(3))
    N(7) = 0.125_wp * (1.0_wp+xi(1))*(1.0_wp+xi(2))*(1.0_wp+xi(3))
    N(8) = 0.125_wp * (1.0_wp-xi(1))*(1.0_wp+xi(2))*(1.0_wp+xi(3))
    
    ! Derivatives w.r.t. ξ
    dN_dxi(:,1) = 0.125_wp * [ &
      -(1.0_wp-xi(2))*(1.0_wp-xi(3)), &
       (1.0_wp-xi(2))*(1.0_wp-xi(3)), &
       (1.0_wp+xi(2))*(1.0_wp-xi(3)), &
      -(1.0_wp+xi(2))*(1.0_wp-xi(3)), &
      -(1.0_wp-xi(2))*(1.0_wp+xi(3)), &
       (1.0_wp-xi(2))*(1.0_wp+xi(3)), &
       (1.0_wp+xi(2))*(1.0_wp+xi(3)), &
      -(1.0_wp+xi(2))*(1.0_wp+xi(3))]
    
    ! Derivatives w.r.t. η
    dN_dxi(:,2) = 0.125_wp * [ &
      -(1.0_wp-xi(1))*(1.0_wp-xi(3)), &
      -(1.0_wp+xi(1))*(1.0_wp-xi(3)), &
       (1.0_wp+xi(1))*(1.0_wp-xi(3)), &
       (1.0_wp-xi(1))*(1.0_wp-xi(3)), &
      -(1.0_wp-xi(1))*(1.0_wp+xi(3)), &
      -(1.0_wp+xi(1))*(1.0_wp+xi(3)), &
       (1.0_wp+xi(1))*(1.0_wp+xi(3)), &
       (1.0_wp-xi(1))*(1.0_wp+xi(3))]
    
    ! Derivatives w.r.t. ζ
    dN_dxi(:,3) = 0.125_wp * [ &
      -(1.0_wp-xi(1))*(1.0_wp-xi(2)), &
      -(1.0_wp+xi(1))*(1.0_wp-xi(2)), &
      -(1.0_wp+xi(1))*(1.0_wp+xi(2)), &
      -(1.0_wp-xi(1))*(1.0_wp+xi(2)), &
       (1.0_wp-xi(1))*(1.0_wp-xi(2)), &
       (1.0_wp+xi(1))*(1.0_wp-xi(2)), &
       (1.0_wp+xi(1))*(1.0_wp+xi(2)), &
       (1.0_wp-xi(1))*(1.0_wp+xi(2))]
    
    sf%N = N
    sf%dN_dxi = dN_dxi
  END SUBROUTINE ComputeShape_Hex8

  !-----------------------------------------------------------------------------
  ! 4-node tetrahedral element (C3D4)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Tet4(xi, sf)
    REAL(wp), INTENT(IN) :: xi(3)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(4), dN_dxi(4,3)
    
    sf%nnode = 4
    sf%dim = 3
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(4))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(4,3))
    
    ! Shape functions (volume coordinates)
    N(1) = xi(1)
    N(2) = xi(2)
    N(3) = xi(3)
    N(4) = 1.0_wp - xi(1) - xi(2) - xi(3)
    
    ! Derivatives
    dN_dxi = RESHAPE([ &
      1.0_wp, 0.0_wp, 0.0_wp, -1.0_wp, &
      0.0_wp, 1.0_wp, 0.0_wp, -1.0_wp, &
      0.0_wp, 0.0_wp, 1.0_wp, -1.0_wp], [4, 3])
    
    sf%N = N
    sf%dN_dxi = dN_dxi
  END SUBROUTINE ComputeShape_Tet4

  !-----------------------------------------------------------------------------
  ! 4-node quadrilateral element (CPE4, CPS4, S4, etc.)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Quad4(xi, sf)
    REAL(wp), INTENT(IN) :: xi(2)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(4), dN_dxi(4,2)
    
    sf%nnode = 4
    sf%dim = 2
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(4))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(4,2))
    
    ! Shape functions
    N(1) = 0.25_wp * (1.0_wp-xi(1))*(1.0_wp-xi(2))
    N(2) = 0.25_wp * (1.0_wp+xi(1))*(1.0_wp-xi(2))
    N(3) = 0.25_wp * (1.0_wp+xi(1))*(1.0_wp+xi(2))
    N(4) = 0.25_wp * (1.0_wp-xi(1))*(1.0_wp+xi(2))
    
    ! Derivatives w.r.t. ξ
    dN_dxi(:,1) = 0.25_wp * [-(1.0_wp-xi(2)), (1.0_wp-xi(2)), &
                              (1.0_wp+xi(2)), -(1.0_wp+xi(2))]
    
    ! Derivatives w.r.t. η
    dN_dxi(:,2) = 0.25_wp * [-(1.0_wp-xi(1)), -(1.0_wp+xi(1)), &
                              (1.0_wp+xi(1)), (1.0_wp-xi(1))]
    
    sf%N = N
    sf%dN_dxi = dN_dxi
  END SUBROUTINE ComputeShape_Quad4

  !-----------------------------------------------------------------------------
  ! 3-node triangular element (CPE3, CPS3, S3)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Tri3(xi, sf)
    REAL(wp), INTENT(IN) :: xi(2)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(3), dN_dxi(3,2)
    
    sf%nnode = 3
    sf%dim = 2
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(3))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(3,2))
    
    ! Shape functions (area coordinates)
    N(1) = xi(1)
    N(2) = xi(2)
    N(3) = 1.0_wp - xi(1) - xi(2)
    
    ! Derivatives
    dN_dxi = RESHAPE([ &
      1.0_wp, 0.0_wp, -1.0_wp, &
      0.0_wp, 1.0_wp, -1.0_wp], [3, 2])
    
    sf%N = N
    sf%dN_dxi = dN_dxi
  END SUBROUTINE ComputeShape_Tri3

  !-----------------------------------------------------------------------------
  ! 2-node line element (B21, T2D2, etc.)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Line2(xi, sf)
    REAL(wp), INTENT(IN) :: xi(1)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(2), dN_dxi(2,1)
    
    sf%nnode = 2
    sf%dim = 1
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(2))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(2,1))
    
    ! Shape functions
    N(1) = 0.5_wp * (1.0_wp - xi(1))
    N(2) = 0.5_wp * (1.0_wp + xi(1))
    
    ! Derivatives
    dN_dxi(:,1) = [-0.5_wp, 0.5_wp]
    
    sf%N = N
    sf%dN_dxi = dN_dxi
  END SUBROUTINE ComputeShape_Line2

  !-----------------------------------------------------------------------------
  ! 20-node hexahedral element (C3D20, C3D20R)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Hex20(xi, sf)
    REAL(wp), INTENT(IN) :: xi(3)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(20), dN_dxi(20,3)
    REAL(wp) :: xi1, xi2, xi3, xi1s, xi2s, xi3s
    
    xi1 = xi(1); xi2 = xi(2); xi3 = xi(3)
    xi1s = 1.0_wp - xi1**2
    xi2s = 1.0_wp - xi2**2
    xi3s = 1.0_wp - xi3**2
    
    sf%nnode = 20
    sf%dim = 3
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(20))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(20,3))
    
    ! Corner nodes (1-8)
    N(1)  = -0.125_wp*(1.0_wp-xi1)*(1.0_wp-xi2)*(1.0_wp-xi3)*(1.0_wp+xi1+xi2+xi3)
    N(2)  = -0.125_wp*(1.0_wp+xi1)*(1.0_wp-xi2)*(1.0_wp-xi3)*(1.0_wp-xi1+xi2+xi3)
    N(3)  = -0.125_wp*(1.0_wp+xi1)*(1.0_wp+xi2)*(1.0_wp-xi3)*(1.0_wp-xi1-xi2+xi3)
    N(4)  = -0.125_wp*(1.0_wp-xi1)*(1.0_wp+xi2)*(1.0_wp-xi3)*(1.0_wp+xi1-xi2+xi3)
    N(5)  = -0.125_wp*(1.0_wp-xi1)*(1.0_wp-xi2)*(1.0_wp+xi3)*(1.0_wp+xi1+xi2-xi3)
    N(6)  = -0.125_wp*(1.0_wp+xi1)*(1.0_wp-xi2)*(1.0_wp+xi3)*(1.0_wp-xi1+xi2-xi3)
    N(7)  = -0.125_wp*(1.0_wp+xi1)*(1.0_wp+xi2)*(1.0_wp+xi3)*(1.0_wp-xi1-xi2-xi3)
    N(8)  = -0.125_wp*(1.0_wp-xi1)*(1.0_wp+xi2)*(1.0_wp+xi3)*(1.0_wp+xi1-xi2-xi3)
    
    ! Mid-edge nodes (9-20)
    N(9)  = 0.5_wp*xi1s*(1.0_wp-xi2)*(1.0_wp-xi3)  ! ξ edge mid
    N(10) = 0.5_wp*xi2s*(1.0_wp+xi1)*(1.0_wp-xi3)
    N(11) = 0.5_wp*xi1s*(1.0_wp+xi2)*(1.0_wp-xi3)
    N(12) = 0.5_wp*xi2s*(1.0_wp-xi1)*(1.0_wp-xi3)
    N(13) = 0.5_wp*xi1s*(1.0_wp-xi2)*(1.0_wp+xi3)
    N(14) = 0.5_wp*xi2s*(1.0_wp+xi1)*(1.0_wp+xi3)
    N(15) = 0.5_wp*xi1s*(1.0_wp+xi2)*(1.0_wp+xi3)
    N(16) = 0.5_wp*xi2s*(1.0_wp-xi1)*(1.0_wp+xi3)
    N(17) = 0.5_wp*xi3s*(1.0_wp-xi1)*(1.0_wp-xi2)  ! ζ edge mid
    N(18) = 0.5_wp*xi3s*(1.0_wp+xi1)*(1.0_wp-xi2)
    N(19) = 0.5_wp*xi3s*(1.0_wp+xi1)*(1.0_wp+xi2)
    N(20) = 0.5_wp*xi3s*(1.0_wp-xi1)*(1.0_wp+xi2)
    
    ! Derivatives for corner nodes
    dN_dxi(1,:) = [-0.125_wp*(1.0_wp-xi2)*(1.0_wp-xi3)*(-2.0_wp*xi1-xi2-xi3), &
                   -0.125_wp*(1.0_wp-xi1)*(1.0_wp-xi3)*(-xi1-2.0_wp*xi2-xi3), &
                   -0.125_wp*(1.0_wp-xi1)*(1.0_wp-xi2)*(-xi1-xi2-2.0_wp*xi3)]
    dN_dxi(2,:) = [-0.125_wp*(1.0_wp-xi2)*(1.0_wp-xi3)*(2.0_wp*xi1-xi2-xi3), &
                   -0.125_wp*(1.0_wp+xi1)*(1.0_wp-xi3)*(-xi1-2.0_wp*xi2-xi3), &
                   -0.125_wp*(1.0_wp+xi1)*(1.0_wp-xi2)*(-xi1-xi2-2.0_wp*xi3)]
    dN_dxi(3,:) = [-0.125_wp*(1.0_wp+xi2)*(1.0_wp-xi3)*(2.0_wp*xi1+xi2-xi3), &
                   -0.125_wp*(1.0_wp+xi1)*(1.0_wp-xi3)*(xi1+2.0_wp*xi2-xi3), &
                   -0.125_wp*(1.0_wp+xi1)*(1.0_wp+xi2)*(-xi1-xi2-2.0_wp*xi3)]
    dN_dxi(4,:) = [-0.125_wp*(1.0_wp+xi2)*(1.0_wp-xi3)*(-2.0_wp*xi1+xi2-xi3), &
                   -0.125_wp*(1.0_wp-xi1)*(1.0_wp-xi3)*(xi1+2.0_wp*xi2-xi3), &
                   -0.125_wp*(1.0_wp-xi1)*(1.0_wp+xi2)*(-xi1-xi2-2.0_wp*xi3)]
    dN_dxi(5,:) = [-0.125_wp*(1.0_wp-xi2)*(1.0_wp+xi3)*(-2.0_wp*xi1-xi2+xi3), &
                   -0.125_wp*(1.0_wp-xi1)*(1.0_wp+xi3)*(-xi1-2.0_wp*xi2+xi3), &
                   -0.125_wp*(1.0_wp-xi1)*(1.0_wp-xi2)*(-xi1-xi2+2.0_wp*xi3)]
    dN_dxi(6,:) = [-0.125_wp*(1.0_wp-xi2)*(1.0_wp+xi3)*(2.0_wp*xi1-xi2+xi3), &
                   -0.125_wp*(1.0_wp+xi1)*(1.0_wp+xi3)*(-xi1-2.0_wp*xi2+xi3), &
                   -0.125_wp*(1.0_wp+xi1)*(1.0_wp-xi2)*(-xi1-xi2+2.0_wp*xi3)]
    dN_dxi(7,:) = [-0.125_wp*(1.0_wp+xi2)*(1.0_wp+xi3)*(2.0_wp*xi1+xi2+xi3), &
                   -0.125_wp*(1.0_wp+xi1)*(1.0_wp+xi3)*(xi1+2.0_wp*xi2+xi3), &
                   -0.125_wp*(1.0_wp+xi1)*(1.0_wp+xi2)*(-xi1-xi2+2.0_wp*xi3)]
    dN_dxi(8,:) = [-0.125_wp*(1.0_wp+xi2)*(1.0_wp+xi3)*(-2.0_wp*xi1+xi2+xi3), &
                   -0.125_wp*(1.0_wp-xi1)*(1.0_wp+xi3)*(xi1+2.0_wp*xi2+xi3), &
                   -0.125_wp*(1.0_wp-xi1)*(1.0_wp+xi2)*(-xi1-xi2+2.0_wp*xi3)]
    
    ! Derivatives for mid-edge nodes (ξ edges: 9,11,13,15)
    dN_dxi(9,:) = [0.5_wp*(-2.0_wp*xi1)*(1.0_wp-xi2)*(1.0_wp-xi3), &
                   0.5_wp*xi1s*(-1.0_wp)*(1.0_wp-xi3), &
                   0.5_wp*xi1s*(1.0_wp-xi2)*(-1.0_wp)]
    dN_dxi(11,:) = [0.5_wp*(-2.0_wp*xi1)*(1.0_wp+xi2)*(1.0_wp-xi3), &
                    0.5_wp*xi1s*(1.0_wp)*(1.0_wp-xi3), &
                    0.5_wp*xi1s*(1.0_wp+xi2)*(-1.0_wp)]
    dN_dxi(13,:) = [0.5_wp*(-2.0_wp*xi1)*(1.0_wp-xi2)*(1.0_wp+xi3), &
                    0.5_wp*xi1s*(-1.0_wp)*(1.0_wp+xi3), &
                    0.5_wp*xi1s*(1.0_wp-xi2)*(1.0_wp)]
    dN_dxi(15,:) = [0.5_wp*(-2.0_wp*xi1)*(1.0_wp+xi2)*(1.0_wp+xi3), &
                    0.5_wp*xi1s*(1.0_wp)*(1.0_wp+xi3), &
                    0.5_wp*xi1s*(1.0_wp+xi2)*(1.0_wp)]
    
    ! Derivatives for mid-edge nodes (η edges: 10,12,14,16)
    dN_dxi(10,:) = [0.5_wp*xi2s*(1.0_wp)*(1.0_wp-xi3), &
                    0.5_wp*(-2.0_wp*xi2)*(1.0_wp+xi1)*(1.0_wp-xi3), &
                    0.5_wp*xi2s*(1.0_wp+xi1)*(-1.0_wp)]
    dN_dxi(12,:) = [0.5_wp*xi2s*(-1.0_wp)*(1.0_wp-xi3), &
                    0.5_wp*(-2.0_wp*xi2)*(1.0_wp-xi1)*(1.0_wp-xi3), &
                    0.5_wp*xi2s*(1.0_wp-xi1)*(-1.0_wp)]
    dN_dxi(14,:) = [0.5_wp*xi2s*(1.0_wp)*(1.0_wp+xi3), &
                    0.5_wp*(-2.0_wp*xi2)*(1.0_wp+xi1)*(1.0_wp+xi3), &
                    0.5_wp*xi2s*(1.0_wp+xi1)*(1.0_wp)]
    dN_dxi(16,:) = [0.5_wp*xi2s*(-1.0_wp)*(1.0_wp+xi3), &
                    0.5_wp*(-2.0_wp*xi2)*(1.0_wp-xi1)*(1.0_wp+xi3), &
                    0.5_wp*xi2s*(1.0_wp-xi1)*(1.0_wp)]
    
    ! Derivatives for mid-edge nodes (ζ edges: 17,18,19,20)
    dN_dxi(17,:) = [0.5_wp*(-2.0_wp*xi3)*(1.0_wp-xi1)*(1.0_wp-xi2), &
                    0.5_wp*xi3s*(-1.0_wp)*(1.0_wp-xi2), &
                    0.5_wp*xi3s*(1.0_wp-xi1)*(-1.0_wp)]
    dN_dxi(18,:) = [0.5_wp*(-2.0_wp*xi3)*(1.0_wp+xi1)*(1.0_wp-xi2), &
                    0.5_wp*xi3s*(1.0_wp)*(1.0_wp-xi2), &
                    0.5_wp*xi3s*(1.0_wp+xi1)*(-1.0_wp)]
    dN_dxi(19,:) = [0.5_wp*(-2.0_wp*xi3)*(1.0_wp+xi1)*(1.0_wp+xi2), &
                    0.5_wp*xi3s*(1.0_wp)*(1.0_wp+xi2), &
                    0.5_wp*xi3s*(1.0_wp+xi1)*(1.0_wp)]
    dN_dxi(20,:) = [0.5_wp*(-2.0_wp*xi3)*(1.0_wp-xi1)*(1.0_wp+xi2), &
                    0.5_wp*xi3s*(-1.0_wp)*(1.0_wp+xi2), &
                    0.5_wp*xi3s*(1.0_wp-xi1)*(1.0_wp)]
    
    sf%N = N
    sf%dN_dxi = dN_dxi
  END SUBROUTINE ComputeShape_Hex20

  !-----------------------------------------------------------------------------
  ! 10-node tetrahedral element (C3D10)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Tet10(xi, sf)
    REAL(wp), INTENT(IN) :: xi(3)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(10), xi1, xi2, xi3, xi12, xi23, xi31
    
    xi1 = xi(1); xi2 = xi(2); xi3 = xi(3)
    xi12 = xi1*xi2; xi23 = xi2*xi3; xi31 = xi3*xi1
    
    sf%nnode = 10
    sf%dim = 3
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(10))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(10,3))
    
    ! Corner nodes
    N(1) = xi1*(2.0_wp*xi1 - 1.0_wp)
    N(2) = xi2*(2.0_wp*xi2 - 1.0_wp)
    N(3) = xi3*(2.0_wp*xi3 - 1.0_wp)
    N(4) = (1.0_wp - xi1 - xi2 - xi3)*(2.0_wp*(1.0_wp - xi1 - xi2 - xi3) - 1.0_wp)
    
    ! Mid-edge nodes
    N(5) = 4.0_wp*xi1*xi2
    N(6) = 4.0_wp*xi2*xi3
    N(7) = 4.0_wp*xi3*xi1
    N(8) = 4.0_wp*xi1*(1.0_wp - xi1 - xi2 - xi3)
    N(9) = 4.0_wp*xi2*(1.0_wp - xi1 - xi2 - xi3)
    N(10) = 4.0_wp*xi3*(1.0_wp - xi1 - xi2 - xi3)
    
    ! Derivatives for corner nodes
    dN_dxi(1,:) = [4.0_wp*xi1 - 1.0_wp, 0.0_wp, 0.0_wp]
    dN_dxi(2,:) = [0.0_wp, 4.0_wp*xi2 - 1.0_wp, 0.0_wp]
    dN_dxi(3,:) = [0.0_wp, 0.0_wp, 4.0_wp*xi3 - 1.0_wp]
    dN_dxi(4,:) = [-4.0_wp + 4.0_wp*(2.0_wp*(1.0_wp-xi1-xi2-xi3)-1.0_wp), &
                   -4.0_wp + 4.0_wp*(2.0_wp*(1.0_wp-xi1-xi2-xi3)-1.0_wp), &
                   -4.0_wp + 4.0_wp*(2.0_wp*(1.0_wp-xi1-xi2-xi3)-1.0_wp)]
    
    ! Derivatives for mid-edge nodes
    dN_dxi(5,:) = [4.0_wp*xi2, 4.0_wp*xi1, 0.0_wp]
    dN_dxi(6,:) = [0.0_wp, 4.0_wp*xi3, 4.0_wp*xi2]
    dN_dxi(7,:) = [4.0_wp*xi3, 0.0_wp, 4.0_wp*xi1]
    dN_dxi(8,:) = [4.0_wp*(1.0_wp-2.0_wp*xi1-xi2-xi3), -4.0_wp*xi1, -4.0_wp*xi1]
    dN_dxi(9,:) = [-4.0_wp*xi2, 4.0_wp*(1.0_wp-xi1-2.0_wp*xi2-xi3), -4.0_wp*xi2]
    dN_dxi(10,:)= [-4.0_wp*xi3, -4.0_wp*xi3, 4.0_wp*(1.0_wp-xi1-xi2-2.0_wp*xi3)]
    
    sf%N = N
    sf%dN_dxi = dN_dxi
  END SUBROUTINE ComputeShape_Tet10

  !-----------------------------------------------------------------------------
  ! 6-node wedge element (C3D6)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Wedge6(xi, sf)
    REAL(wp), INTENT(IN) :: xi(3)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(6)
    
    sf%nnode = 6
    sf%dim = 3
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(6))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(6,3))
    
    N(1) = 0.5_wp*(1.0_wp - xi(1) - xi(2))*(1.0_wp - xi(3))
    N(2) = 0.5_wp*xi(1)*(1.0_wp - xi(3))
    N(3) = 0.5_wp*xi(2)*(1.0_wp - xi(3))
    N(4) = 0.5_wp*(1.0_wp - xi(1) - xi(2))*(1.0_wp + xi(3))
    N(5) = 0.5_wp*xi(1)*(1.0_wp + xi(3))
    N(6) = 0.5_wp*xi(2)*(1.0_wp + xi(3))
    
    ! Derivatives for Wedge6
    sf%dN_dxi(1,:) = [-0.5_wp*(1.0_wp-xi(3)), -0.5_wp*(1.0_wp-xi(3)), -0.5_wp*(1.0_wp-xi(1)-xi(2))]
    sf%dN_dxi(2,:) = [0.5_wp*(1.0_wp-xi(3)), 0.0_wp, -0.5_wp*xi(1)]
    sf%dN_dxi(3,:) = [0.0_wp, 0.5_wp*(1.0_wp-xi(3)), -0.5_wp*xi(2)]
    sf%dN_dxi(4,:) = [-0.5_wp*(1.0_wp+xi(3)), -0.5_wp*(1.0_wp+xi(3)), 0.5_wp*(1.0_wp-xi(1)-xi(2))]
    sf%dN_dxi(5,:) = [0.5_wp*(1.0_wp+xi(3)), 0.0_wp, 0.5_wp*xi(1)]
    sf%dN_dxi(6,:) = [0.0_wp, 0.5_wp*(1.0_wp+xi(3)), 0.5_wp*xi(2)]
    
    sf%N = N
    sf%dN_dxi = sf%dN_dxi
  END SUBROUTINE ComputeShape_Wedge6

  !-----------------------------------------------------------------------------
  ! 15-node wedge element (C3D15)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Wedge15(xi, sf)
    REAL(wp), INTENT(IN) :: xi(3)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(15), xi1, xi2, xi3
    
    xi1 = xi(1); xi2 = xi(2); xi3 = xi(3)
    
    sf%nnode = 15
    sf%dim = 3
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(15))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(15,3))
    
    ! Corner nodes (1-6)
    N(1) = 0.5_wp*(1.0_wp - xi1 - xi2)*(1.0_wp - xi3)*(-2.0_wp*(1.0_wp - xi1 - xi2) - 2.0_wp*(1.0_wp - xi3) + 1.0_wp)
    N(2) = 0.5_wp*xi1*(1.0_wp - xi3)*(-2.0_wp*xi1 - 2.0_wp*(1.0_wp - xi3) + 1.0_wp)
    N(3) = 0.5_wp*xi2*(1.0_wp - xi3)*(-2.0_wp*xi2 - 2.0_wp*(1.0_wp - xi3) + 1.0_wp)
    N(4) = 0.5_wp*(1.0_wp - xi1 - xi2)*(1.0_wp + xi3)*(-2.0_wp*(1.0_wp - xi1 - xi2) - 2.0_wp*(1.0_wp + xi3) + 1.0_wp)
    N(5) = 0.5_wp*xi1*(1.0_wp + xi3)*(-2.0_wp*xi1 - 2.0_wp*(1.0_wp + xi3) + 1.0_wp)
    N(6) = 0.5_wp*xi2*(1.0_wp + xi3)*(-2.0_wp*xi2 - 2.0_wp*(1.0_wp + xi3) + 1.0_wp)
    
    ! Mid-edge nodes (7-15)
    N(7) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi1*(1.0_wp - xi3)
    N(8) = 2.0_wp*xi1*xi2*(1.0_wp - xi3)
    N(9) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi2*(1.0_wp - xi3)
    N(10) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi1*(1.0_wp + xi3)
    N(11) = 2.0_wp*xi1*xi2*(1.0_wp + xi3)
    N(12) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi2*(1.0_wp + xi3)
    N(13) = 2.0_wp*(1.0_wp - xi1 - xi2)*(1.0_wp - xi3)*(1.0_wp + xi3)
    N(14) = 2.0_wp*xi1*(1.0_wp - xi3)*(1.0_wp + xi3)
    ! Mid-edge nodes (7-15)
    N(7) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi1*(1.0_wp - xi3)
    N(8) = 2.0_wp*xi1*xi2*(1.0_wp - xi3)
    N(9) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi2*(1.0_wp - xi3)
    N(10) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi1*(1.0_wp + xi3)
    N(11) = 2.0_wp*xi1*xi2*(1.0_wp + xi3)
    N(12) = 2.0_wp*(1.0_wp - xi1 - xi2)*xi2*(1.0_wp + xi3)
    N(13) = 2.0_wp*(1.0_wp - xi1 - xi2)*(1.0_wp - xi3)*(1.0_wp + xi3)
    N(14) = 2.0_wp*xi1*(1.0_wp - xi3)*(1.0_wp + xi3)
    N(15) = 2.0_wp*xi2*(1.0_wp - xi3)*(1.0_wp + xi3)
    
    ! Derivatives for corner nodes (1-6)
    sf%dN_dxi(1,:) = [0.5_wp*(1.0_wp-xi3)*(4.0_wp*(1.0_wp-xi1-xi2)+2.0_wp*(1.0_wp-xi3)-2.0_wp), &
                      0.5_wp*(1.0_wp-xi3)*(4.0_wp*(1.0_wp-xi1-xi2)+2.0_wp*(1.0_wp-xi3)-2.0_wp), &
                      0.5_wp*(1.0_wp-xi1-xi2)*(-2.0_wp)]
    sf%dN_dxi(2,:) = [0.5_wp*(1.0_wp-xi3)*(-4.0_wp*xi1-2.0_wp*(1.0_wp-xi3)+1.0_wp-2.0_wp*xi1), &
                      0.0_wp, &
                      0.5_wp*xi1*(-2.0_wp)]
    sf%dN_dxi(3,:) = [0.0_wp, &
                      0.5_wp*(1.0_wp-xi3)*(-4.0_wp*xi2-2.0_wp*(1.0_wp-xi3)+1.0_wp-2.0_wp*xi2), &
                      0.5_wp*xi2*(-2.0_wp)]
    sf%dN_dxi(4,:) = [0.5_wp*(1.0_wp+xi3)*(4.0_wp*(1.0_wp-xi1-xi2)+2.0_wp*(1.0_wp+xi3)-2.0_wp), &
                      0.5_wp*(1.0_wp+xi3)*(4.0_wp*(1.0_wp-xi1-xi2)+2.0_wp*(1.0_wp+xi3)-2.0_wp), &
                      0.5_wp*(1.0_wp-xi1-xi2)*(2.0_wp)]
    sf%dN_dxi(5,:) = [0.5_wp*(1.0_wp+xi3)*(-4.0_wp*xi1-2.0_wp*(1.0_wp+xi3)+1.0_wp-2.0_wp*xi1), &
                      0.0_wp, &
                      0.5_wp*xi1*(2.0_wp)]
    sf%dN_dxi(6,:) = [0.0_wp, &
                      0.5_wp*(1.0_wp+xi3)*(-4.0_wp*xi2-2.0_wp*(1.0_wp+xi3)+1.0_wp-2.0_wp*xi2), &
                      0.5_wp*xi2*(2.0_wp)]
    
    ! Derivatives for mid-edge nodes (7-15)
    ! Bottom triangle mid-edges (7-9): z = (1-xi3)
    sf%dN_dxi(7,:) = [2.0_wp*(1.0_wp-2.0_wp*xi1-xi2)*(1.0_wp-xi3), &
                      -2.0_wp*xi1*(1.0_wp-xi3), &
                      -2.0_wp*(1.0_wp-xi1-xi2)*xi1]
    sf%dN_dxi(8,:) = [2.0_wp*xi2*(1.0_wp-xi3), &
                      2.0_wp*xi1*(1.0_wp-xi3), &
                      -2.0_wp*xi1*xi2]
    sf%dN_dxi(9,:) = [-2.0_wp*xi2*(1.0_wp-xi3), &
                      2.0_wp*(1.0_wp-xi1-2.0_wp*xi2)*(1.0_wp-xi3), &
                      -2.0_wp*(1.0_wp-xi1-xi2)*xi2]
    ! Top triangle mid-edges (10-12): z = (1+xi3)
    sf%dN_dxi(10,:) = [2.0_wp*(1.0_wp-2.0_wp*xi1-xi2)*(1.0_wp+xi3), &
                       -2.0_wp*xi1*(1.0_wp+xi3), &
                       2.0_wp*(1.0_wp-xi1-xi2)*xi1]
    sf%dN_dxi(11,:) = [2.0_wp*xi2*(1.0_wp+xi3), &
                       2.0_wp*xi1*(1.0_wp+xi3), &
                       2.0_wp*xi1*xi2]
    sf%dN_dxi(12,:) = [-2.0_wp*xi2*(1.0_wp+xi3), &
                       2.0_wp*(1.0_wp-xi1-2.0_wp*xi2)*(1.0_wp+xi3), &
                       2.0_wp*(1.0_wp-xi1-xi2)*xi2]
    ! Vertical mid-edges (13-15): (1-xi3^2)
    sf%dN_dxi(13,:) = [-(1.0_wp-xi3**2), &
                       -(1.0_wp-xi3**2), &
                       -2.0_wp*xi3*(1.0_wp-xi1-xi2)]
    sf%dN_dxi(14,:) = [(1.0_wp-xi3**2), &
                       0.0_wp, &
                       -2.0_wp*xi3*xi1]
    sf%dN_dxi(15,:) = [0.0_wp, &
                       (1.0_wp-xi3**2), &
                       -2.0_wp*xi3*xi2]
    
    sf%N = N
    sf%dN_dxi = sf%dN_dxi
  END SUBROUTINE ComputeShape_Wedge15

  !-----------------------------------------------------------------------------
  ! 8-node quadrilateral element (CPE8, CPS8, S8, etc.)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Quad8(xi, sf)
    REAL(wp), INTENT(IN) :: xi(2)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(8), xi1, xi2, xi1s, xi2s
    
    xi1 = xi(1); xi2 = xi(2)
    xi1s = 1.0_wp - xi1**2
    xi2s = 1.0_wp - xi2**2
    
    sf%nnode = 8
    sf%dim = 2
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(8))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(8,2))
    
    N(1) = 0.25_wp*(1.0_wp-xi1)*(1.0_wp-xi2)*(-1.0_wp-xi1-xi2)
    N(2) = 0.25_wp*(1.0_wp+xi1)*(1.0_wp-xi2)*(-1.0_wp+xi1-xi2)
    N(3) = 0.25_wp*(1.0_wp+xi1)*(1.0_wp+xi2)*(-1.0_wp+xi1+xi2)
    N(4) = 0.25_wp*(1.0_wp-xi1)*(1.0_wp+xi2)*(-1.0_wp-xi1+xi2)
    N(5) = 0.5_wp*xi1s*(1.0_wp-xi2)
    N(6) = 0.5_wp*(1.0_wp+xi1)*xi2s
    N(7) = 0.5_wp*xi1s*(1.0_wp+xi2)
    N(8) = 0.5_wp*(1.0_wp-xi1)*xi2s
    
    ! Derivatives for corner nodes (1-4)
    sf%dN_dxi(1,:) = [-0.25_wp*(1.0_wp-xi2)*(-2.0_wp*xi1-xi2), -0.25_wp*(1.0_wp-xi1)*(-xi1-2.0_wp*xi2)]
    sf%dN_dxi(2,:) = [0.25_wp*(1.0_wp-xi2)*(2.0_wp*xi1-xi2), -0.25_wp*(1.0_wp+xi1)*(-xi1-2.0_wp*xi2)]
    sf%dN_dxi(3,:) = [0.25_wp*(1.0_wp+xi2)*(2.0_wp*xi1+xi2), 0.25_wp*(1.0_wp+xi1)*(xi1+2.0_wp*xi2)]
    sf%dN_dxi(4,:) = [-0.25_wp*(1.0_wp+xi2)*(-2.0_wp*xi1+xi2), 0.25_wp*(1.0_wp-xi1)*(xi1+2.0_wp*xi2)]
    
    ! Derivatives for mid-edge nodes (5-8)
    sf%dN_dxi(5,:) = [-0.5_wp*2.0_wp*xi1*(1.0_wp-xi2), -0.5_wp*xi1s]
    sf%dN_dxi(6,:) = [0.5_wp*xi2s, 0.5_wp*(1.0_wp+xi1)*(-2.0_wp*xi2)]
    sf%dN_dxi(7,:) = [-0.5_wp*2.0_wp*xi1*(1.0_wp+xi2), 0.5_wp*xi1s]
    sf%dN_dxi(8,:) = [-0.5_wp*xi2s, 0.5_wp*(1.0_wp-xi1)*(-2.0_wp*xi2)]
    
    sf%N = N
    sf%dN_dxi = sf%dN_dxi
  END SUBROUTINE ComputeShape_Quad8

  !-----------------------------------------------------------------------------
  ! 6-node triangular element (CPE6, CPS6, CAX6)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Tri6(xi, sf)
    REAL(wp), INTENT(IN) :: xi(2)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(6), xi1, xi2, xi3
    
    xi1 = xi(1); xi2 = xi(2); xi3 = 1.0_wp - xi1 - xi2
    
    sf%nnode = 6
    sf%dim = 2
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(6))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(6,2))
    
    N(1) = xi1*(2.0_wp*xi1 - 1.0_wp)
    N(2) = xi2*(2.0_wp*xi2 - 1.0_wp)
    N(3) = xi3*(2.0_wp*xi3 - 1.0_wp)
    N(4) = 4.0_wp*xi1*xi2
    N(5) = 4.0_wp*xi2*xi3
    N(6) = 4.0_wp*xi3*xi1
    
    ! Derivatives for corner nodes
    sf%dN_dxi(1,:) = [4.0_wp*xi1 - 1.0_wp - 4.0_wp*xi3, -4.0_wp*xi3]
    sf%dN_dxi(2,:) = [-4.0_wp*xi3, 4.0_wp*xi2 - 1.0_wp - 4.0_wp*xi3]
    sf%dN_dxi(3,:) = [4.0_wp*xi3*(1.0_wp-2.0_wp*xi3), 4.0_wp*xi3*(1.0_wp-2.0_wp*xi3)]
    
    ! Derivatives for mid-edge nodes
    sf%dN_dxi(4,:) = [4.0_wp*xi2, 4.0_wp*xi1]
    sf%dN_dxi(5,:) = [-4.0_wp*xi2, 4.0_wp*(xi3-xi2)]
    sf%dN_dxi(6,:) = [4.0_wp*(xi3-xi1), -4.0_wp*xi1]
    
    sf%N = N
    sf%dN_dxi = sf%dN_dxi
  END SUBROUTINE ComputeShape_Tri6

  !-----------------------------------------------------------------------------
  ! 27-node hexahedral element (C3D27)
  ! Serendipity: 8 corner + 12 mid-edge + 6 mid-face + 1 center
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Hex27(xi, sf)
    REAL(wp), INTENT(IN) :: xi(3)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf

    REAL(wp) :: N(27)
    REAL(wp) :: r, s, t
    REAL(wp) :: L1r, L2r, L3r, L1s, L2s, L3s, L1t, L2t, L3t
    REAL(wp) :: dL1r, dL2r, dL3r, dL1s, dL2s, dL3s, dL1t, dL2t, dL3t
    INTEGER(i4) :: i

    r = xi(1); s = xi(2); t = xi(3)

    sf%nnode = 27
    sf%dim = 3

    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(27))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(27,3))

    ! 1D Lagrange quadratic shape functions in each direction
    ! L1(x) = x(x-1)/2,  L2(x) = (1-x)(1+x),  L3(x) = x(x+1)/2
    L1r = 0.5_wp*r*(r - 1.0_wp); L2r = (1.0_wp - r)*(1.0_wp + r); L3r = 0.5_wp*r*(r + 1.0_wp)
    L1s = 0.5_wp*s*(s - 1.0_wp); L2s = (1.0_wp - s)*(1.0_wp + s); L3s = 0.5_wp*s*(s + 1.0_wp)
    L1t = 0.5_wp*t*(t - 1.0_wp); L2t = (1.0_wp - t)*(1.0_wp + t); L3t = 0.5_wp*t*(t + 1.0_wp)

    ! Derivatives of 1D Lagrange quadratic
    dL1r = r - 0.5_wp; dL2r = -2.0_wp*r; dL3r = r + 0.5_wp
    dL1s = s - 0.5_wp; dL2s = -2.0_wp*s; dL3s = s + 0.5_wp
    dL1t = t - 0.5_wp; dL2t = -2.0_wp*t; dL3t = t + 0.5_wp

    ! Node numbering: corners (1-8), mid-edge (9-20), mid-face (21-26), center (27)
    ! Corners: (-1,-1,-1), (1,-1,-1), (1,1,-1), (-1,1,-1),
    !          (-1,-1,1), (1,-1,1), (1,1,1), (-1,1,1)
    N(1)  = L1r*L1s*L1t;  N(2)  = L3r*L1s*L1t
    N(3)  = L3r*L3s*L1t;  N(4)  = L1r*L3s*L1t
    N(5)  = L1r*L1s*L3t;  N(6)  = L3r*L1s*L3t
    N(7)  = L3r*L3s*L3t;  N(8)  = L1r*L3s*L3t
    ! Mid-edges bottom (9-12)
    N(9)  = L2r*L1s*L1t;  N(10) = L3r*L2s*L1t
    N(11) = L2r*L3s*L1t;  N(12) = L1r*L2s*L1t
    ! Mid-edges top (13-16)
    N(13) = L2r*L1s*L3t;  N(14) = L3r*L2s*L3t
    N(15) = L2r*L3s*L3t;  N(16) = L1r*L2s*L3t
    ! Mid-edges vertical (17-20)
    N(17) = L1r*L1s*L2t;  N(18) = L3r*L1s*L2t
    N(19) = L3r*L3s*L2t;  N(20) = L1r*L3s*L2t
    ! Mid-faces (21-26)
    N(21) = L2r*L2s*L1t   ! bottom face
    N(22) = L2r*L2s*L3t   ! top face
    N(23) = L2r*L1s*L2t   ! front face
    N(24) = L3r*L2s*L2t   ! right face
    N(25) = L2r*L3s*L2t   ! back face
    N(26) = L1r*L2s*L2t   ! left face
    ! Center (27)
    N(27) = L2r*L2s*L2t

    ! Derivatives: dN/dr, dN/ds, dN/dt (tensor product rule)
    ! Corners
    sf%dN_dxi(1,:)  = [dL1r*L1s*L1t,  L1r*dL1s*L1t,  L1r*L1s*dL1t]
    sf%dN_dxi(2,:)  = [dL3r*L1s*L1t,  L3r*dL1s*L1t,  L3r*L1s*dL1t]
    sf%dN_dxi(3,:)  = [dL3r*L3s*L1t,  L3r*dL3s*L1t,  L3r*L3s*dL1t]
    sf%dN_dxi(4,:)  = [dL1r*L3s*L1t,  L1r*dL3s*L1t,  L1r*L3s*dL1t]
    sf%dN_dxi(5,:)  = [dL1r*L1s*L3t,  L1r*dL1s*L3t,  L1r*L1s*dL3t]
    sf%dN_dxi(6,:)  = [dL3r*L1s*L3t,  L3r*dL1s*L3t,  L3r*L1s*dL3t]
    sf%dN_dxi(7,:)  = [dL3r*L3s*L3t,  L3r*dL3s*L3t,  L3r*L3s*dL3t]
    sf%dN_dxi(8,:)  = [dL1r*L3s*L3t,  L1r*dL3s*L3t,  L1r*L3s*dL3t]
    ! Mid-edges bottom
    sf%dN_dxi(9,:)  = [dL2r*L1s*L1t,  L2r*dL1s*L1t,  L2r*L1s*dL1t]
    sf%dN_dxi(10,:) = [dL3r*L2s*L1t,  L3r*dL2s*L1t,  L3r*L2s*dL1t]
    sf%dN_dxi(11,:) = [dL2r*L3s*L1t,  L2r*dL3s*L1t,  L2r*L3s*dL1t]
    sf%dN_dxi(12,:) = [dL1r*L2s*L1t,  L1r*dL2s*L1t,  L1r*L2s*dL1t]
    ! Mid-edges top
    sf%dN_dxi(13,:) = [dL2r*L1s*L3t,  L2r*dL1s*L3t,  L2r*L1s*dL3t]
    sf%dN_dxi(14,:) = [dL3r*L2s*L3t,  L3r*dL2s*L3t,  L3r*L2s*dL3t]
    sf%dN_dxi(15,:) = [dL2r*L3s*L3t,  L2r*dL3s*L3t,  L2r*L3s*dL3t]
    sf%dN_dxi(16,:) = [dL1r*L2s*L3t,  L1r*dL2s*L3t,  L1r*L2s*dL3t]
    ! Mid-edges vertical
    sf%dN_dxi(17,:) = [dL1r*L1s*L2t,  L1r*dL1s*L2t,  L1r*L1s*dL2t]
    sf%dN_dxi(18,:) = [dL3r*L1s*L2t,  L3r*dL1s*L2t,  L3r*L1s*dL2t]
    sf%dN_dxi(19,:) = [dL3r*L3s*L2t,  L3r*dL3s*L2t,  L3r*L3s*dL2t]
    sf%dN_dxi(20,:) = [dL1r*L3s*L2t,  L1r*dL3s*L2t,  L1r*L3s*dL2t]
    ! Mid-faces
    sf%dN_dxi(21,:) = [dL2r*L2s*L1t,  L2r*dL2s*L1t,  L2r*L2s*dL1t]
    sf%dN_dxi(22,:) = [dL2r*L2s*L3t,  L2r*dL2s*L3t,  L2r*L2s*dL3t]
    sf%dN_dxi(23,:) = [dL2r*L1s*L2t,  L2r*dL1s*L2t,  L2r*L1s*dL2t]
    sf%dN_dxi(24,:) = [dL3r*L2s*L2t,  L3r*dL2s*L2t,  L3r*L2s*dL2t]
    sf%dN_dxi(25,:) = [dL2r*L3s*L2t,  L2r*dL3s*L2t,  L2r*L3s*dL2t]
    sf%dN_dxi(26,:) = [dL1r*L2s*L2t,  L1r*dL2s*L2t,  L1r*L2s*dL2t]
    ! Center
    sf%dN_dxi(27,:) = [dL2r*L2s*L2t,  L2r*dL2s*L2t,  L2r*L2s*dL2t]

    sf%N = N
  END SUBROUTINE ComputeShape_Hex27

  !-----------------------------------------------------------------------------
  ! 3-node line element (B22, T2D3, etc.)
  !-----------------------------------------------------------------------------
  SUBROUTINE ComputeShape_Line3(xi, sf)
    REAL(wp), INTENT(IN) :: xi(1)
    CLASS(PH_Elem_ShapeFunc_Ctx), INTENT(INOUT) :: sf
    
    REAL(wp) :: N(3), xi1
    
    xi1 = xi(1)
    
    sf%nnode = 3
    sf%dim = 1
    
    IF (.NOT. ALLOCATED(sf%N)) ALLOCATE(sf%N(3))
    IF (.NOT. ALLOCATED(sf%dN_dxi)) ALLOCATE(sf%dN_dxi(3,1))
    
    N(1) = -0.5_wp*xi1*(1.0_wp - xi1)
    N(2) = 0.5_wp*xi1*(1.0_wp + xi1)
    N(3) = (1.0_wp - xi1)*(1.0_wp + xi1)
    
    ! Derivatives for Line3
    sf%dN_dxi(1,:) = [-0.5_wp*(1.0_wp - 2.0_wp*xi1)]
    sf%dN_dxi(2,:) = [0.5_wp*(1.0_wp + 2.0_wp*xi1)]
    sf%dN_dxi(3,:) = [-2.0_wp*xi1]
    
    sf%N = N
    sf%dN_dxi = sf%dN_dxi
  END SUBROUTINE ComputeShape_Line3

END MODULE PH_Elem_ShapeFunc