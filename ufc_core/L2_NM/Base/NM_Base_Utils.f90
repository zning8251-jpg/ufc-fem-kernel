!===============================================================================
! MODULE: NM_Base_Utils
! LAYER:  L2_NM
! DOMAIN: Base
! ROLE:   Proc — utility functions for numerical algorithms
! BRIEF:  Dot product, cross product, triple product, angle between vectors.
!         Pure functions, optimized for hot path. SIO Arg bundles provided.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_Base_Utils
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Dot_Product_Fast, Cross_Product, Triple_Product, Angle_Between

  !====================================================================
  ! Arg Bundle Structures (Principle #14: 5-tuple with [IN]/[OUT])
  !====================================================================

  !--------------------------------------------------------------------
  ! Dot_Product_Fast_Arg: Arguments for Dot_Product_Fast
  !--------------------------------------------------------------------
  TYPE :: Dot_Product_Fast_Arg
    ! [IN] vec1 - First vector
    ! [IN] vec2 - Second vector
    REAL(wp), ALLOCATABLE :: vec1(:)
    REAL(wp), ALLOCATABLE :: vec2(:)
  END TYPE Dot_Product_Fast_Arg

  !--------------------------------------------------------------------
  ! Cross_Product_Arg: Arguments for Cross_Product (3D)
  !--------------------------------------------------------------------
  TYPE :: Cross_Product_Arg
    ! [IN]  a - First 3D vector
    ! [IN]  b - Second 3D vector
    ! [OUT] c - Cross product result (3D)
    REAL(wp) :: a(3)
    REAL(wp) :: b(3)
    REAL(wp) :: c(3)
  END TYPE Cross_Product_Arg

  !--------------------------------------------------------------------
  ! Triple_Product_Arg: Arguments for Triple_Product
  !--------------------------------------------------------------------
  TYPE :: Triple_Product_Arg
    ! [IN] a - First 3D vector
    ! [IN] b - Second 3D vector
    ! [IN] c - Third 3D vector
    REAL(wp) :: a(3)
    REAL(wp) :: b(3)
    REAL(wp) :: c(3)
  END TYPE Triple_Product_Arg

  !--------------------------------------------------------------------
  ! Angle_Between_Arg: Arguments for Angle_Between
  !--------------------------------------------------------------------
  TYPE :: Angle_Between_Arg
    ! [IN]  vec1  - First vector
    ! [IN]  vec2  - Second vector
    ! [OUT] angle - Angle between vectors (radians)
    REAL(wp), ALLOCATABLE :: vec1(:)
    REAL(wp), ALLOCATABLE :: vec2(:)
    REAL(wp)              :: angle
  END TYPE Angle_Between_Arg

CONTAINS

  !===============================================================================
  ! Dot_Product_Fast
  ! Fast dot product (wrapper for intrinsic DOT_PRODUCT)
  !===============================================================================
  PURE FUNCTION Dot_Product_Fast(vec1, vec2) RESULT(dot)
    !> [IN] vec1 - First vector
    !> [IN] vec2 - Second vector
    REAL(wp), INTENT(IN) :: vec1(:), vec2(:)
    REAL(wp) :: dot

    ! Compiler intrinsic is already optimized
    dot = DOT_PRODUCT(vec1, vec2)
  END FUNCTION Dot_Product_Fast

  !===============================================================================
  ! Dot_Product_Fast_Proc
  ! Procedure-style wrapper with Arg bundle (SIO compliant)
  !===============================================================================
  SUBROUTINE Dot_Product_Fast_Proc(arg, dot)
    !> [IN]  arg - Arg bundle (vec1[IN], vec2[IN])
    !> [OUT] dot - Dot product result
    TYPE(Dot_Product_Fast_Arg), INTENT(IN)  :: arg
    REAL(wp),                   INTENT(OUT) :: dot

    dot = DOT_PRODUCT(arg%vec1, arg%vec2)
  END SUBROUTINE Dot_Product_Fast_Proc

  !===============================================================================
  ! Cross_Product
  ! Cross product (3D vectors only)
  !===============================================================================
  PURE FUNCTION Cross_Product(a, b) RESULT(cross)
    !> [IN] a - First 3D vector
    !> [IN] b - Second 3D vector
    REAL(wp), INTENT(IN) :: a(3), b(3)
    REAL(wp) :: cross(3)

    cross(1) = a(2)*b(3) - a(3)*b(2)
    cross(2) = a(3)*b(1) - a(1)*b(3)
    cross(3) = a(1)*b(2) - a(2)*b(1)
  END FUNCTION Cross_Product

  !===============================================================================
  ! Cross_Product_Proc
  ! Procedure-style wrapper with Arg bundle (SIO compliant)
  !===============================================================================
  SUBROUTINE Cross_Product_Proc(arg)
    !> [INOUT] arg - Arg bundle (a[IN], b[IN], c[OUT])
    TYPE(Cross_Product_Arg), INTENT(INOUT) :: arg

    arg%c(1) = arg%a(2)*arg%b(3) - arg%a(3)*arg%b(2)
    arg%c(2) = arg%a(3)*arg%b(1) - arg%a(1)*arg%b(3)
    arg%c(3) = arg%a(1)*arg%b(2) - arg%a(2)*arg%b(1)
  END SUBROUTINE Cross_Product_Proc

  !===============================================================================
  ! Triple_Product
  ! Scalar triple product (a · (b × c))
  !===============================================================================
  PURE FUNCTION Triple_Product(a, b, c) RESULT(triple)
    !> [IN] a - First 3D vector
    !> [IN] b - Second 3D vector
    !> [IN] c - Third 3D vector
    REAL(wp), INTENT(IN) :: a(3), b(3), c(3)
    REAL(wp) :: triple

    triple = DOT_PRODUCT(a, Cross_Product(b, c))
  END FUNCTION Triple_Product

  !===============================================================================
  ! Triple_Product_Proc
  ! Procedure-style wrapper with Arg bundle (SIO compliant)
  !===============================================================================
  SUBROUTINE Triple_Product_Proc(arg, triple)
    !> [IN]  arg    - Arg bundle (a[IN], b[IN], c[IN])
    !> [OUT] triple - Triple product result
    TYPE(Triple_Product_Arg), INTENT(IN)  :: arg
    REAL(wp),                 INTENT(OUT) :: triple
    REAL(wp) :: cross(3)

    cross(1) = arg%b(2)*arg%c(3) - arg%b(3)*arg%c(2)
    cross(2) = arg%b(3)*arg%c(1) - arg%b(1)*arg%c(3)
    cross(3) = arg%b(1)*arg%c(2) - arg%b(2)*arg%c(1)
    triple = DOT_PRODUCT(arg%a, cross)
  END SUBROUTINE Triple_Product_Proc

  !===============================================================================
  ! Angle_Between
  ! Angle between two vectors (in radians)
  !===============================================================================
  PURE FUNCTION Angle_Between(vec1, vec2) RESULT(angle)
    !> [IN] vec1 - First vector
    !> [IN] vec2 - Second vector
    REAL(wp), INTENT(IN) :: vec1(:), vec2(:)
    REAL(wp) :: angle, dot, norm1, norm2

    dot = DOT_PRODUCT(vec1, vec2)
    norm1 = SQRT(DOT_PRODUCT(vec1, vec1))
    norm2 = SQRT(DOT_PRODUCT(vec2, vec2))

    IF (norm1 > 1.0E-14_wp .AND. norm2 > 1.0E-14_wp) THEN
      angle = ACOS(MAX(-1.0_wp, MIN(1.0_wp, dot / (norm1 * norm2))))
    ELSE
      angle = 0.0_wp  ! Undefined if either vector is zero
    END IF
  END FUNCTION Angle_Between

  !===============================================================================
  ! Angle_Between_Proc
  ! Procedure-style wrapper with Arg bundle (SIO compliant)
  !===============================================================================
  SUBROUTINE Angle_Between_Proc(arg)
    !> [INOUT] arg - Arg bundle (vec1[IN], vec2[IN], angle[OUT])
    TYPE(Angle_Between_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: dot, norm1, norm2

    dot = DOT_PRODUCT(arg%vec1, arg%vec2)
    norm1 = SQRT(DOT_PRODUCT(arg%vec1, arg%vec1))
    norm2 = SQRT(DOT_PRODUCT(arg%vec2, arg%vec2))

    IF (norm1 > 1.0E-14_wp .AND. norm2 > 1.0E-14_wp) THEN
      arg%angle = ACOS(MAX(-1.0_wp, MIN(1.0_wp, dot / (norm1 * norm2))))
    ELSE
      arg%angle = 0.0_wp  ! Undefined if either vector is zero
    END IF
  END SUBROUTINE Angle_Between_Proc

END MODULE NM_Base_Utils
