!===============================================================================
! MODULE: PH_Elem_JacobianBUtils
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Elem JacobianB Utils module (auto-filled)
!===============================================================================
MODULE PH_Elem_JacobianBUtils
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  !! ===================================================================
  !! UniField-Core Jacobian and B Matrix Utilities Module
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Element/Shared
  !!   KIND: Utils (Jacobian and B matrix computation for special element types)
  !!
  !! This module provides Jacobian and B matrix computation functions extracted
  !! from PH_Elem_Impl.f90 for special element types (tetrahedra, prisms, pyramids):
  !!   - Tetrahedron: Tet4, Tet10
  !!   - Prism/Wedge: Prism6, Prism15
  !!   - Pyramid: Pyram5, Pyram13
  !!   - Hexahedron: Hex27
  !!
  !! Design Principles:
  !!   - Shared utilities for all element families
  !!   - Optimized implementations for specific geometries
  !!   - Extracted from PH_Elem_Impl.f90 to avoid code duplication
  !! ===================================================================

  USE IF_Prec_Core, ONLY: wp, i4

  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  ! Tetrahedron functions
  PUBLIC :: UF_ComputeJacobianAndB_Tet4
  PUBLIC :: UF_ComputeStrain_Tet4
  PUBLIC :: UF_ComputeJacobianAndB_Tet10
  PUBLIC :: UF_ComputeStrain_Tet10

  ! Prism/Wedge functions
  PUBLIC :: UF_ComputeJacobianAndB_Prism6
  PUBLIC :: UF_ComputeStrain_Prism6
  PUBLIC :: UF_ComputeJacobianAndB_Prism15
  PUBLIC :: UF_ComputeStrain_Prism15

  ! Pyramid functions
  PUBLIC :: UF_ComputeJacobianAndB_Pyram5
  PUBLIC :: UF_ComputeStrain_Pyram5
  PUBLIC :: UF_ComputeJacobianAndB_Pyram13
  PUBLIC :: UF_ComputeStrain_Pyram13

  ! Hexahedron functions
  PUBLIC :: UF_ComputeJacobianAndB_Hex27
  PUBLIC :: UF_ComputeStrain_Hex27

  ! Helper function
  PUBLIC :: UF_ComputeInverse3x3

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Shared_Args
  TYPE :: PH_Elem_Shared_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Shared_Args


CONTAINS

  SUBROUTINE UF_Co_Prism15(coords, dNdxi, detJ, B)
    !! Compute Jacobian and B matrix for 15-node prism
    !!
    !! @param coords Node coordinates (3, 15)
    !! @param dNdxi Shape function derivatives in natural coordinates (15, 3)
    !! @param detJ Determinant of Jacobian matrix
    !! @param B Strain-displacement matrix (6, 45)

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, 15)
    REAL(wp), INTENT(IN) :: dNdxi(15, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 45)  ! B matrix for 15 nodes, 3 DOFs each

    REAL(wp) :: Jac(3, 3), invJ(3, 3)
    REAL(wp) :: dNdx(15, 3)
    INTEGER(i4) :: i

    ! Compute Jacobian matrix
    Jac = 0.0_wp
    DO i = 1, 15
      Jac(1, 1) = Jac(1, 1) + dNdxi(i, 1) * coords(1, i)
      Jac(1, 2) = Jac(1, 2) + dNdxi(i, 2) * coords(1, i)
      Jac(1, 3) = Jac(1, 3) + dNdxi(i, 3) * coords(1, i)
      Jac(2, 1) = Jac(2, 1) + dNdxi(i, 1) * coords(2, i)
      Jac(2, 2) = Jac(2, 2) + dNdxi(i, 2) * coords(2, i)
      Jac(2, 3) = Jac(2, 3) + dNdxi(i, 3) * coords(2, i)
      Jac(3, 1) = Jac(3, 1) + dNdxi(i, 1) * coords(3, i)
      Jac(3, 2) = Jac(3, 2) + dNdxi(i, 2) * coords(3, i)
      Jac(3, 3) = Jac(3, 3) + dNdxi(i, 3) * coords(3, i)
    END DO

    ! Compute determinant
    detJ = Jac(1,1) * (Jac(2,2) * Jac(3,3) - Jac(2,3) * Jac(3,2)) - &
           Jac(1,2) * (Jac(2,1) * Jac(3,3) - Jac(2,3) * Jac(3,1)) + &
           Jac(1,3) * (Jac(2,1) * Jac(3,2) - Jac(2,2) * Jac(3,1))

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      ! Compute inverse Jacobian
      CALL UF_ComputeInverse3x3(Jac, invJ)

      ! Compute derivatives in physical coordinates
      dNdx = MATMUL(dNdxi, TRANSPOSE(invJ))

      ! Build B matrix (3D: ε_xx, ε_yy, ε_zz, γ_xy, γ_yz, γ_xz)
      B = 0.0_wp
      DO i = 1, 15
        B(1, 3*(i-1)+1) = dNdx(i, 1)  ! ε_xx
        B(2, 3*(i-1)+2) = dNdx(i, 2)  ! ε_yy
        B(3, 3*(i-1)+3) = dNdx(i, 3)  ! ε_zz
        B(4, 3*(i-1)+1) = dNdx(i, 2)  ! γ_xy
        B(4, 3*(i-1)+2) = dNdx(i, 1)
        B(5, 3*(i-1)+2) = dNdx(i, 3)  ! γ_yz
        B(5, 3*(i-1)+3) = dNdx(i, 2)
        B(6, 3*(i-1)+1) = dNdx(i, 3)  ! γ_xz
        B(6, 3*(i-1)+3) = dNdx(i, 1)
      END DO
    ELSE
      B = 0.0_wp
    END IF
  END SUBROUTINE UF_ComputeJacobianAndB_Prism15

  SUBROUTINE UF_Co_Prism6(coords, dNdxi, detJ, B)
    !! Compute Jacobian and B matrix for 6-node prism/wedge
    !!
    !! @param coords Node coordinates (3, 6)
    !! @param dNdxi Shape function derivatives in natural coordinates (6, 3)
    !! @param detJ Determinant of Jacobian matrix
    !! @param B Strain-displacement matrix (6, 18)

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, 6)
    REAL(wp), INTENT(IN) :: dNdxi(6, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 18)

    REAL(wp) :: Jac(3, 3), invJ(3, 3)
    REAL(wp) :: dNdx(6, 3)
    INTEGER(i4) :: i, j, k

    ! Compute Jacobian matrix
    Jac = 0.0_wp
    DO i = 1, 6
      DO j = 1, 3
        DO k = 1, 3
          Jac(j, k) = Jac(j, k) + dNdxi(i, k) * coords(j, i)
        END DO
      END DO
    END DO

    ! Compute determinant
    detJ = Jac(1,1) * (Jac(2,2)*Jac(3,3) - Jac(2,3)*Jac(3,2)) - &
           Jac(1,2) * (Jac(2,1)*Jac(3,3) - Jac(2,3)*Jac(3,1)) + &
           Jac(1,3) * (Jac(2,1)*Jac(3,2) - Jac(2,2)*Jac(3,1))

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      ! Compute inverse Jacobian
      CALL UF_ComputeInverse3x3(Jac, invJ)

      ! Compute derivatives in physical coordinates
      dNdx = MATMUL(dNdxi, TRANSPOSE(invJ))

      ! Build B matrix (3D: ε_xx, ε_yy, ε_zz, γ_xy, γ_xz, γ_yz)
      B = 0.0_wp
      DO i = 1, 6
        B(1, 3*(i-1)+1) = dNdx(i, 1)  ! ε_xx
        B(2, 3*(i-1)+2) = dNdx(i, 2)  ! ε_yy
        B(3, 3*(i-1)+3) = dNdx(i, 3)  ! ε_zz
        B(4, 3*(i-1)+1) = dNdx(i, 2)  ! γ_xy
        B(4, 3*(i-1)+2) = dNdx(i, 1)
        B(5, 3*(i-1)+1) = dNdx(i, 3)  ! γ_xz
        B(5, 3*(i-1)+3) = dNdx(i, 1)
        B(6, 3*(i-1)+2) = dNdx(i, 3)  ! γ_yz
        B(6, 3*(i-1)+3) = dNdx(i, 2)
      END DO
    ELSE
      B = 0.0_wp
    END IF
  END SUBROUTINE UF_ComputeJacobianAndB_Prism6

  SUBROUTINE UF_Co_Pyram13(coords, dNdxi, detJ, B)
    !! Compute Jacobian and B matrix for 13-node pyramid
    !!
    !! @param coords Node coordinates (3, 13)
    !! @param dNdxi Shape function derivatives in natural coordinates (13, 3)
    !! @param detJ Determinant of Jacobian matrix
    !! @param B Strain-displacement matrix (6, 39)

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, 13)
    REAL(wp), INTENT(IN) :: dNdxi(13, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 39)  ! B matrix for 13 nodes, 3 DOFs each

    REAL(wp) :: Jac(3, 3), invJ(3, 3)
    REAL(wp) :: dNdx(13, 3)
    INTEGER(i4) :: i

    ! Compute Jacobian matrix
    Jac = 0.0_wp
    DO i = 1, 13
      Jac(1, 1) = Jac(1, 1) + dNdxi(i, 1) * coords(1, i)
      Jac(1, 2) = Jac(1, 2) + dNdxi(i, 2) * coords(1, i)
      Jac(1, 3) = Jac(1, 3) + dNdxi(i, 3) * coords(1, i)
      Jac(2, 1) = Jac(2, 1) + dNdxi(i, 1) * coords(2, i)
      Jac(2, 2) = Jac(2, 2) + dNdxi(i, 2) * coords(2, i)
      Jac(2, 3) = Jac(2, 3) + dNdxi(i, 3) * coords(2, i)
      Jac(3, 1) = Jac(3, 1) + dNdxi(i, 1) * coords(3, i)
      Jac(3, 2) = Jac(3, 2) + dNdxi(i, 2) * coords(3, i)
      Jac(3, 3) = Jac(3, 3) + dNdxi(i, 3) * coords(3, i)
    END DO

    ! Compute determinant
    detJ = Jac(1,1) * (Jac(2,2) * Jac(3,3) - Jac(2,3) * Jac(3,2)) - &
           Jac(1,2) * (Jac(2,1) * Jac(3,3) - Jac(2,3) * Jac(3,1)) + &
           Jac(1,3) * (Jac(2,1) * Jac(3,2) - Jac(2,2) * Jac(3,1))

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      ! Compute inverse Jacobian
      CALL UF_ComputeInverse3x3(Jac, invJ)

      ! Compute derivatives in physical coordinates
      dNdx = MATMUL(dNdxi, TRANSPOSE(invJ))

      ! Build B matrix (3D: ε_xx, ε_yy, ε_zz, γ_xy, γ_yz, γ_xz)
      B = 0.0_wp
      DO i = 1, 13
        B(1, 3*(i-1)+1) = dNdx(i, 1)  ! ε_xx
        B(2, 3*(i-1)+2) = dNdx(i, 2)  ! ε_yy
        B(3, 3*(i-1)+3) = dNdx(i, 3)  ! ε_zz
        B(4, 3*(i-1)+1) = dNdx(i, 2)  ! γ_xy
        B(4, 3*(i-1)+2) = dNdx(i, 1)
        B(5, 3*(i-1)+2) = dNdx(i, 3)  ! γ_yz
        B(5, 3*(i-1)+3) = dNdx(i, 2)
        B(6, 3*(i-1)+1) = dNdx(i, 3)  ! γ_xz
        B(6, 3*(i-1)+3) = dNdx(i, 1)
      END DO
    ELSE
      B = 0.0_wp
    END IF
  END SUBROUTINE UF_ComputeJacobianAndB_Pyram13

  SUBROUTINE UF_Co_Pyram5(coords, dNdxi, detJ, B)
    !! Compute Jacobian and B matrix for 5-node pyramid
    !!
    !! @param coords Node coordinates (3, 5)
    !! @param dNdxi Shape function derivatives in natural coordinates (5, 3)
    !! @param detJ Determinant of Jacobian matrix
    !! @param B Strain-displacement matrix (6, 15)

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, 5)
    REAL(wp), INTENT(IN) :: dNdxi(5, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 15)  ! B matrix for 5 nodes, 3 DOFs each

    REAL(wp) :: Jac(3, 3), invJ(3, 3)
    REAL(wp) :: dNdx(5, 3)
    INTEGER(i4) :: i

    ! Compute Jacobian matrix
    Jac = 0.0_wp
    DO i = 1, 5
      Jac(1, 1) = Jac(1, 1) + dNdxi(i, 1) * coords(1, i)
      Jac(1, 2) = Jac(1, 2) + dNdxi(i, 2) * coords(1, i)
      Jac(1, 3) = Jac(1, 3) + dNdxi(i, 3) * coords(1, i)
      Jac(2, 1) = Jac(2, 1) + dNdxi(i, 1) * coords(2, i)
      Jac(2, 2) = Jac(2, 2) + dNdxi(i, 2) * coords(2, i)
      Jac(2, 3) = Jac(2, 3) + dNdxi(i, 3) * coords(2, i)
      Jac(3, 1) = Jac(3, 1) + dNdxi(i, 1) * coords(3, i)
      Jac(3, 2) = Jac(3, 2) + dNdxi(i, 2) * coords(3, i)
      Jac(3, 3) = Jac(3, 3) + dNdxi(i, 3) * coords(3, i)
    END DO

    ! Compute determinant
    detJ = Jac(1,1) * (Jac(2,2) * Jac(3,3) - Jac(2,3) * Jac(3,2)) - &
           Jac(1,2) * (Jac(2,1) * Jac(3,3) - Jac(2,3) * Jac(3,1)) + &
           Jac(1,3) * (Jac(2,1) * Jac(3,2) - Jac(2,2) * Jac(3,1))

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      ! Compute inverse Jacobian
      CALL UF_ComputeInverse3x3(Jac, invJ)

      ! Compute derivatives in physical coordinates
      dNdx = MATMUL(dNdxi, TRANSPOSE(invJ))

      ! Build B matrix (3D: ε_xx, ε_yy, ε_zz, γ_xy, γ_yz, γ_xz)
      B = 0.0_wp
      DO i = 1, 5
        B(1, 3*(i-1)+1) = dNdx(i, 1)  ! ε_xx
        B(2, 3*(i-1)+2) = dNdx(i, 2)  ! ε_yy
        B(3, 3*(i-1)+3) = dNdx(i, 3)  ! ε_zz
        B(4, 3*(i-1)+1) = dNdx(i, 2)  ! γ_xy
        B(4, 3*(i-1)+2) = dNdx(i, 1)
        B(5, 3*(i-1)+2) = dNdx(i, 3)  ! γ_yz
        B(5, 3*(i-1)+3) = dNdx(i, 2)
        B(6, 3*(i-1)+1) = dNdx(i, 3)  ! γ_xz
        B(6, 3*(i-1)+3) = dNdx(i, 1)
      END DO
    ELSE
      B = 0.0_wp
    END IF
  END SUBROUTINE UF_ComputeJacobianAndB_Pyram5

  SUBROUTINE UF_ComputeInverse3x3(A, A_inv)
    !! Compute inverse of 3x3 matrix
    !!
    !! @param A Input 3x3 matrix
    !! @param A_inv Output inverse matrix

    REAL(wp), INTENT(IN) :: A(3, 3)
    REAL(wp), INTENT(OUT) :: A_inv(3, 3)

    REAL(wp) :: det

    det = A(1,1) * (A(2,2) * A(3,3) - A(2,3) * A(3,2)) - &
          A(1,2) * (A(2,1) * A(3,3) - A(2,3) * A(3,1)) + &
          A(1,3) * (A(2,1) * A(3,2) - A(2,2) * A(3,1))

    IF (ABS(det) > 1.0e-12_wp) THEN
      A_inv(1,1) = (A(2,2) * A(3,3) - A(2,3) * A(3,2)) / det
      A_inv(1,2) = (A(1,3) * A(3,2) - A(1,2) * A(3,3)) / det
      A_inv(1,3) = (A(1,2) * A(2,3) - A(1,3) * A(2,2)) / det
      A_inv(2,1) = (A(2,3) * A(3,1) - A(2,1) * A(3,3)) / det
      A_inv(2,2) = (A(1,1) * A(3,3) - A(1,3) * A(3,1)) / det
      A_inv(2,3) = (A(1,3) * A(2,1) - A(1,1) * A(2,3)) / det
      A_inv(3,1) = (A(2,1) * A(3,2) - A(2,2) * A(3,1)) / det
      A_inv(3,2) = (A(1,2) * A(3,1) - A(1,1) * A(3,2)) / det
      A_inv(3,3) = (A(1,1) * A(2,2) - A(1,2) * A(2,1)) / det
    ELSE
      A_inv = 0.0_wp
    END IF
  END SUBROUTINE UF_ComputeInverse3x3

  SUBROUTINE UF_ComputeJacobianAndB_Hex27(coords, dNdxi, detJ, B)
    !! Compute Jacobian and B matrix for 27-node hexahedron
    !!
    !! @param coords Node coordinates (3, 27)
    !! @param dNdxi Shape function derivatives in natural coordinates (27, 3)
    !! @param detJ Determinant of Jacobian matrix
    !! @param B Strain-displacement matrix (6, 81)

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, 27)
    REAL(wp), INTENT(IN) :: dNdxi(27, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 81)

    REAL(wp) :: Jac(3, 3), invJ(3, 3)
    REAL(wp) :: dNdx(27, 3)
    INTEGER(i4) :: i, j, k

    ! Compute Jacobian matrix
    Jac = 0.0_wp
    DO i = 1, 27
      DO j = 1, 3
        DO k = 1, 3
          Jac(j, k) = Jac(j, k) + dNdxi(i, k) * coords(j, i)
        END DO
      END DO
    END DO

    ! Compute determinant
    detJ = Jac(1,1) * (Jac(2,2)*Jac(3,3) - Jac(2,3)*Jac(3,2)) - &
           Jac(1,2) * (Jac(2,1)*Jac(3,3) - Jac(2,3)*Jac(3,1)) + &
           Jac(1,3) * (Jac(2,1)*Jac(3,2) - Jac(2,2)*Jac(3,1))

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      ! Compute inverse Jacobian
      CALL UF_ComputeInverse3x3(Jac, invJ)

      ! Compute derivatives in physical coordinates
      dNdx = MATMUL(dNdxi, TRANSPOSE(invJ))

      ! Build B matrix (3D: ε_xx, ε_yy, ε_zz, γ_xy, γ_xz, γ_yz)
      B = 0.0_wp
      DO i = 1, 27
        B(1, 3*(i-1)+1) = dNdx(i, 1)  ! ε_xx
        B(2, 3*(i-1)+2) = dNdx(i, 2)  ! ε_yy
        B(3, 3*(i-1)+3) = dNdx(i, 3)  ! ε_zz
        B(4, 3*(i-1)+1) = dNdx(i, 2)  ! γ_xy
        B(4, 3*(i-1)+2) = dNdx(i, 1)
        B(5, 3*(i-1)+1) = dNdx(i, 3)  ! γ_xz
        B(5, 3*(i-1)+3) = dNdx(i, 1)
        B(6, 3*(i-1)+2) = dNdx(i, 3)  ! γ_yz
        B(6, 3*(i-1)+3) = dNdx(i, 2)
      END DO
    ELSE
      B = 0.0_wp
    END IF
  END SUBROUTINE UF_ComputeJacobianAndB_Hex27

  SUBROUTINE UF_ComputeJacobianAndB_Tet10(coords, dNdxi, detJ, B)
    !! Compute Jacobian and B matrix for 10-node tetrahedron
    !!
    !! @param coords Node coordinates (3, 10)
    !! @param dNdxi Shape function derivatives in natural coordinates (10, 3)
    !! @param detJ Determinant of Jacobian matrix
    !! @param B Strain-displacement matrix (6, 30)

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, 10)
    REAL(wp), INTENT(IN) :: dNdxi(10, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 30)

    REAL(wp) :: Jac(3, 3), invJ(3, 3)
    REAL(wp) :: dNdx(10, 3)
    INTEGER(i4) :: i, j, k

    ! Compute Jacobian matrix
    Jac = 0.0_wp
    DO i = 1, 10
      DO j = 1, 3
        DO k = 1, 3
          Jac(j, k) = Jac(j, k) + dNdxi(i, k) * coords(j, i)
        END DO
      END DO
    END DO

    ! Compute determinant
    detJ = Jac(1,1) * (Jac(2,2)*Jac(3,3) - Jac(2,3)*Jac(3,2)) - &
           Jac(1,2) * (Jac(2,1)*Jac(3,3) - Jac(2,3)*Jac(3,1)) + &
           Jac(1,3) * (Jac(2,1)*Jac(3,2) - Jac(2,2)*Jac(3,1))

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      ! Compute inverse Jacobian
      CALL UF_ComputeInverse3x3(Jac, invJ)

      ! Compute derivatives in physical coordinates
      dNdx = MATMUL(dNdxi, TRANSPOSE(invJ))

      ! Build B matrix (3D: ε_xx, ε_yy, ε_zz, γ_xy, γ_xz, γ_yz)
      B = 0.0_wp
      DO i = 1, 10
        B(1, 3*(i-1)+1) = dNdx(i, 1)  ! ε_xx
        B(2, 3*(i-1)+2) = dNdx(i, 2)  ! ε_yy
        B(3, 3*(i-1)+3) = dNdx(i, 3)  ! ε_zz
        B(4, 3*(i-1)+1) = dNdx(i, 2)  ! γ_xy
        B(4, 3*(i-1)+2) = dNdx(i, 1)
        B(5, 3*(i-1)+1) = dNdx(i, 3)  ! γ_xz
        B(5, 3*(i-1)+3) = dNdx(i, 1)
        B(6, 3*(i-1)+2) = dNdx(i, 3)  ! γ_yz
        B(6, 3*(i-1)+3) = dNdx(i, 2)
      END DO
    ELSE
      B = 0.0_wp
    END IF
  END SUBROUTINE UF_ComputeJacobianAndB_Tet10

  SUBROUTINE UF_ComputeJacobianAndB_Tet4(coords, dNdxi, detJ, B)
    !! Compute Jacobian and B matrix for 4-node tetrahedron
    !!
    !! @param coords Node coordinates (3, 4)
    !! @param dNdxi Shape function derivatives in natural coordinates (4, 3)
    !! @param detJ Determinant of Jacobian matrix
    !! @param B Strain-displacement matrix (6, 12)

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, 4)
    REAL(wp), INTENT(IN) :: dNdxi(4, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 12)

    REAL(wp) :: Jac(3, 3), invJ(3, 3)
    REAL(wp) :: dNdx(4, 3)
    INTEGER(i4) :: i, j, k

    ! Compute Jacobian matrix
    Jac = 0.0_wp
    DO i = 1, 4
      DO j = 1, 3
        DO k = 1, 3
          Jac(j, k) = Jac(j, k) + dNdxi(i, k) * coords(j, i)
        END DO
      END DO
    END DO

    ! Compute determinant
    detJ = Jac(1,1) * (Jac(2,2)*Jac(3,3) - Jac(2,3)*Jac(3,2)) - &
           Jac(1,2) * (Jac(2,1)*Jac(3,3) - Jac(2,3)*Jac(3,1)) + &
           Jac(1,3) * (Jac(2,1)*Jac(3,2) - Jac(2,2)*Jac(3,1))

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      ! Compute inverse Jacobian
      CALL UF_ComputeInverse3x3(Jac, invJ)

      ! Compute derivatives in physical coordinates
      dNdx = MATMUL(dNdxi, TRANSPOSE(invJ))

      ! Build B matrix (3D: ε_xx, ε_yy, ε_zz, γ_xy, γ_xz, γ_yz)
      B = 0.0_wp
      DO i = 1, 4
        B(1, 3*(i-1)+1) = dNdx(i, 1)  ! ε_xx
        B(2, 3*(i-1)+2) = dNdx(i, 2)  ! ε_yy
        B(3, 3*(i-1)+3) = dNdx(i, 3)  ! ε_zz
        B(4, 3*(i-1)+1) = dNdx(i, 2)  ! γ_xy
        B(4, 3*(i-1)+2) = dNdx(i, 1)
        B(5, 3*(i-1)+1) = dNdx(i, 3)  ! γ_xz
        B(5, 3*(i-1)+3) = dNdx(i, 1)
        B(6, 3*(i-1)+2) = dNdx(i, 3)  ! γ_yz
        B(6, 3*(i-1)+3) = dNdx(i, 2)
      END DO
    ELSE
      B = 0.0_wp
    END IF
  END SUBROUTINE UF_ComputeJacobianAndB_Tet4

  SUBROUTINE UF_ComputeStrain_Hex27(B, disp, strain)
    !! Compute strain from B matrix and displacements for 27-node hexahedron
    !!
    !! @param B Strain-displacement matrix (6, 81)
    !! @param disp Displacements (3, 27)
    !! @param strain Output strain vector (6)

    REAL(wp), INTENT(IN) :: B(6, 81)
    REAL(wp), INTENT(IN) :: disp(:,:)  ! (3, 27)
    REAL(wp), INTENT(OUT) :: strain(6)

    REAL(wp) :: u_vec(81)
    INTEGER(i4) :: i

    ! Flatten displacement vector
    DO i = 1, 27
      u_vec(3*(i-1)+1) = disp(1, i)
      u_vec(3*(i-1)+2) = disp(2, i)
      u_vec(3*(i-1)+3) = disp(3, i)
    END DO

    ! Compute strain: ε = B * u
    strain = MATMUL(B, u_vec)
  END SUBROUTINE UF_ComputeStrain_Hex27

  SUBROUTINE UF_ComputeStrain_Prism15(B, disp, strain)
    !! Compute strain from B matrix and displacements for 15-node prism
    !!
    !! @param B Strain-displacement matrix (6, 45)
    !! @param disp Displacements (3, 15)
    !! @param strain Output strain vector (6)

    REAL(wp), INTENT(IN) :: B(6, 45)
    REAL(wp), INTENT(IN) :: disp(:,:)  ! (3, 15)
    REAL(wp), INTENT(OUT) :: strain(6)

    REAL(wp) :: u_vec(45)
    INTEGER(i4) :: i

    ! Flatten displacement vector
    DO i = 1, 15
      u_vec(3*(i-1)+1) = disp(1, i)
      u_vec(3*(i-1)+2) = disp(2, i)
      u_vec(3*(i-1)+3) = disp(3, i)
    END DO

    ! Compute strain: ε = B * u
    strain = MATMUL(B, u_vec)
  END SUBROUTINE UF_ComputeStrain_Prism15

  SUBROUTINE UF_ComputeStrain_Prism6(B, disp, strain)
    !! Compute strain from B matrix and displacements for 6-node prism/wedge
    !!
    !! @param B Strain-displacement matrix (6, 18)
    !! @param disp Displacements (3, 6)
    !! @param strain Output strain vector (6)

    REAL(wp), INTENT(IN) :: B(6, 18)
    REAL(wp), INTENT(IN) :: disp(:,:)  ! (3, 6)
    REAL(wp), INTENT(OUT) :: strain(6)

    REAL(wp) :: u_vec(18)
    INTEGER(i4) :: i

    ! Flatten displacement vector
    DO i = 1, 6
      u_vec(3*(i-1)+1) = disp(1, i)
      u_vec(3*(i-1)+2) = disp(2, i)
      u_vec(3*(i-1)+3) = disp(3, i)
    END DO

    ! Compute strain: ε = B * u
    strain = MATMUL(B, u_vec)
  END SUBROUTINE UF_ComputeStrain_Prism6

  SUBROUTINE UF_ComputeStrain_Pyram13(B, disp, strain)
    !! Compute strain from B matrix and displacements for 13-node pyramid
    !!
    !! @param B Strain-displacement matrix (6, 39)
    !! @param disp Displacements (3, 13)
    !! @param strain Output strain vector (6)

    REAL(wp), INTENT(IN) :: B(6, 39)
    REAL(wp), INTENT(IN) :: disp(:,:)  ! (3, 13)
    REAL(wp), INTENT(OUT) :: strain(6)

    REAL(wp) :: u_vec(39)
    INTEGER(i4) :: i

    ! Flatten displacement vector
    DO i = 1, 13
      u_vec(3*(i-1)+1) = disp(1, i)
      u_vec(3*(i-1)+2) = disp(2, i)
      u_vec(3*(i-1)+3) = disp(3, i)
    END DO

    ! Compute strain: ε = B * u
    strain = MATMUL(B, u_vec)
  END SUBROUTINE UF_ComputeStrain_Pyram13

  SUBROUTINE UF_ComputeStrain_Pyram5(B, disp, strain)
    !! Compute strain from B matrix and displacements for 5-node pyramid
    !!
    !! @param B Strain-displacement matrix (6, 15)
    !! @param disp Displacements (3, 5)
    !! @param strain Output strain vector (6)

    REAL(wp), INTENT(IN) :: B(6, 15)
    REAL(wp), INTENT(IN) :: disp(:,:)  ! (3, 5)
    REAL(wp), INTENT(OUT) :: strain(6)

    REAL(wp) :: u_vec(15)
    INTEGER(i4) :: i

    ! Flatten displacement vector
    DO i = 1, 5
      u_vec(3*(i-1)+1) = disp(1, i)
      u_vec(3*(i-1)+2) = disp(2, i)
      u_vec(3*(i-1)+3) = disp(3, i)
    END DO

    ! Compute strain: ε = B * u
    strain = MATMUL(B, u_vec)
  END SUBROUTINE UF_ComputeStrain_Pyram5

  SUBROUTINE UF_ComputeStrain_Tet10(B, disp, strain)
    !! Compute strain from B matrix and displacements for 10-node tetrahedron
    !!
    !! @param B Strain-displacement matrix (6, 30)
    !! @param disp Displacements (3, 10)
    !! @param strain Output strain vector (6)

    REAL(wp), INTENT(IN) :: B(6, 30)
    REAL(wp), INTENT(IN) :: disp(:,:)  ! (3, 10)
    REAL(wp), INTENT(OUT) :: strain(6)

    REAL(wp) :: u_vec(30)
    INTEGER(i4) :: i

    ! Flatten displacement vector
    DO i = 1, 10
      u_vec(3*(i-1)+1) = disp(1, i)
      u_vec(3*(i-1)+2) = disp(2, i)
      u_vec(3*(i-1)+3) = disp(3, i)
    END DO

    ! Compute strain: ε = B * u
    strain = MATMUL(B, u_vec)
  END SUBROUTINE UF_ComputeStrain_Tet10

  SUBROUTINE UF_ComputeStrain_Tet4(B, disp, strain)
    !! Compute strain from B matrix and displacements for 4-node tetrahedron
    !!
    !! @param B Strain-displacement matrix (6, 12)
    !! @param disp Displacements (3, 4)
    !! @param strain Output strain vector (6)

    REAL(wp), INTENT(IN) :: B(6, 12)
    REAL(wp), INTENT(IN) :: disp(:,:)  ! (3, 4)
    REAL(wp), INTENT(OUT) :: strain(6)

    REAL(wp) :: u_vec(12)
    INTEGER(i4) :: i

    ! Flatten displacement vector
    DO i = 1, 4
      u_vec(3*(i-1)+1) = disp(1, i)
      u_vec(3*(i-1)+2) = disp(2, i)
      u_vec(3*(i-1)+3) = disp(3, i)
    END DO

    ! Compute strain: ε = B * u
    strain = MATMUL(B, u_vec)
  END SUBROUTINE UF_ComputeStrain_Tet4
end module PH_Elem_JacobianBUtils