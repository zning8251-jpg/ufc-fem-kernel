!===============================================================================
! MODULE: NM_Base_Norms
! LAYER:  L2_NM
! DOMAIN: Base
! ROLE:   Proc — pure norm computations (hot-path optimized)
! BRIEF:  Vector and matrix norm computations: L1, L2, Inf, Frobenius,
!         Normalize. LAPACK/BLAS compatible. SIO Arg bundles provided.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_Base_Norms
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Norm_L1, Norm_L2, Norm_Inf, Norm_Fro, Normalize

  !====================================================================
  ! Arg Bundle Structures (Principle #14: 5-tuple with [IN]/[OUT])
  !====================================================================

  !--------------------------------------------------------------------
  ! Norm_L2_Arg: Arguments for Norm_L2
  !--------------------------------------------------------------------
  TYPE :: Norm_L2_Arg
    ! [IN] vec - Input vector
    REAL(wp), ALLOCATABLE :: vec(:)
  END TYPE Norm_L2_Arg

  !--------------------------------------------------------------------
  ! Norm_L1_Arg: Arguments for Norm_L1
  !--------------------------------------------------------------------
  TYPE :: Norm_L1_Arg
    ! [IN] vec - Input vector
    REAL(wp), ALLOCATABLE :: vec(:)
  END TYPE Norm_L1_Arg

  !--------------------------------------------------------------------
  ! Norm_Inf_Arg: Arguments for Norm_Inf
  !--------------------------------------------------------------------
  TYPE :: Norm_Inf_Arg
    ! [IN] vec - Input vector
    REAL(wp), ALLOCATABLE :: vec(:)
  END TYPE Norm_Inf_Arg

  !--------------------------------------------------------------------
  ! Norm_Fro_Arg: Arguments for Norm_Fro
  !--------------------------------------------------------------------
  TYPE :: Norm_Fro_Arg
    ! [IN] mat - Input matrix
    REAL(wp), ALLOCATABLE :: mat(:,:)
  END TYPE Norm_Fro_Arg

  !--------------------------------------------------------------------
  ! Normalize_Arg: Arguments for Normalize
  !--------------------------------------------------------------------
  TYPE :: Normalize_Arg
    ! [IN]  vec      - Input vector
    ! [OUT] unit_vec - Unit vector (same shape as vec)
    REAL(wp), ALLOCATABLE :: vec(:)
    REAL(wp), ALLOCATABLE :: unit_vec(:)
  END TYPE Normalize_Arg

CONTAINS

  !===============================================================================
  ! Norm_L2
  ! Vector L2 norm (Euclidean norm)
  !===============================================================================
  PURE FUNCTION Norm_L2(vec) RESULT(norm)
    !> [IN] vec - Input vector
    REAL(wp), INTENT(IN) :: vec(:)
    REAL(wp) :: norm

    ! Optimized: SQRT(DOT_PRODUCT(vec, vec)) avoids temporary array from vec**2
    norm = SQRT(DOT_PRODUCT(vec, vec))
  END FUNCTION Norm_L2

  !===============================================================================
  ! Norm_L2_Proc
  ! Procedure-style wrapper with Arg bundle (SIO compliant)
  !===============================================================================
  SUBROUTINE Norm_L2_Proc(arg, norm)
    !> [IN]  arg - Arg bundle (vec[IN])
    !> [OUT] norm - L2 norm result
    TYPE(Norm_L2_Arg), INTENT(IN)  :: arg
    REAL(wp),          INTENT(OUT) :: norm

    norm = SQRT(DOT_PRODUCT(arg%vec, arg%vec))
  END SUBROUTINE Norm_L2_Proc

  !===============================================================================
  ! Norm_L1
  ! Vector L1 norm (Manhattan norm)
  !===============================================================================
  PURE FUNCTION Norm_L1(vec) RESULT(norm)
    !> [IN] vec - Input vector
    REAL(wp), INTENT(IN) :: vec(:)
    REAL(wp) :: norm
    INTEGER(i4) :: i, n

    n = SIZE(vec)
    norm = 0.0_wp
    DO CONCURRENT (i = 1:n)
      norm = norm + ABS(vec(i))
    END DO
  END FUNCTION Norm_L1

  !===============================================================================
  ! Norm_L1_Proc
  ! Procedure-style wrapper with Arg bundle (SIO compliant)
  !===============================================================================
  SUBROUTINE Norm_L1_Proc(arg, norm)
    !> [IN]  arg - Arg bundle (vec[IN])
    !> [OUT] norm - L1 norm result
    TYPE(Norm_L1_Arg), INTENT(IN)  :: arg
    REAL(wp),          INTENT(OUT) :: norm
    INTEGER(i4) :: i, n

    n = SIZE(arg%vec)
    norm = 0.0_wp
    DO CONCURRENT (i = 1:n)
      norm = norm + ABS(arg%vec(i))
    END DO
  END SUBROUTINE Norm_L1_Proc

  !===============================================================================
  ! Norm_Inf
  ! Vector infinity norm (maximum absolute value)
  !===============================================================================
  PURE FUNCTION Norm_Inf(vec) RESULT(norm)
    !> [IN] vec - Input vector
    REAL(wp), INTENT(IN) :: vec(:)
    REAL(wp) :: norm
    INTEGER(i4) :: i, n

    n = SIZE(vec)
    norm = 0.0_wp
    DO CONCURRENT (i = 1:n)
      norm = MAX(norm, ABS(vec(i)))
    END DO
  END FUNCTION Norm_Inf

  !===============================================================================
  ! Norm_Inf_Proc
  ! Procedure-style wrapper with Arg bundle (SIO compliant)
  !===============================================================================
  SUBROUTINE Norm_Inf_Proc(arg, norm)
    !> [IN]  arg - Arg bundle (vec[IN])
    !> [OUT] norm - Infinity norm result
    TYPE(Norm_Inf_Arg), INTENT(IN)  :: arg
    REAL(wp),          INTENT(OUT) :: norm
    INTEGER(i4) :: i, n

    n = SIZE(arg%vec)
    norm = 0.0_wp
    DO CONCURRENT (i = 1:n)
      norm = MAX(norm, ABS(arg%vec(i)))
    END DO
  END SUBROUTINE Norm_Inf_Proc

  !===============================================================================
  ! Norm_Fro
  ! Matrix Frobenius norm
  !===============================================================================
  PURE FUNCTION Norm_Fro(mat) RESULT(norm)
    !> [IN] mat - Input matrix
    REAL(wp), INTENT(IN) :: mat(:,:)
    REAL(wp) :: norm
    INTEGER(i4) :: m, n

    m = SIZE(mat, DIM=1)
    n = SIZE(mat, DIM=2)

    ! Optimized: treat as 1D array for DOT_PRODUCT
    norm = SQRT(DOT_PRODUCT(RESHAPE(mat, [m*n]), RESHAPE(mat, [m*n])))
  END FUNCTION Norm_Fro

  !===============================================================================
  ! Norm_Fro_Proc
  ! Procedure-style wrapper with Arg bundle (SIO compliant)
  !===============================================================================
  SUBROUTINE Norm_Fro_Proc(arg, norm)
    !> [IN]  arg - Arg bundle (mat[IN])
    !> [OUT] norm - Frobenius norm result
    TYPE(Norm_Fro_Arg), INTENT(IN)  :: arg
    REAL(wp),           INTENT(OUT) :: norm
    INTEGER(i4) :: m, n

    m = SIZE(arg%mat, DIM=1)
    n = SIZE(arg%mat, DIM=2)
    norm = SQRT(DOT_PRODUCT(RESHAPE(arg%mat, [m*n]), RESHAPE(arg%mat, [m*n])))
  END SUBROUTINE Norm_Fro_Proc

  !===============================================================================
  ! Normalize
  ! Vector normalization (returns unit vector)
  !===============================================================================
  PURE FUNCTION Normalize(vec) RESULT(unit_vec)
    !> [IN] vec - Input vector
    REAL(wp), INTENT(IN) :: vec(:)
    REAL(wp), ALLOCATABLE :: unit_vec(:)
    REAL(wp) :: norm

    ALLOCATE(unit_vec(SIZE(vec)))
    norm = Norm_L2(vec)

    IF (norm > 1.0E-14_wp) THEN
      unit_vec = vec / norm
    ELSE
      unit_vec = vec  ! Already zero or near-zero
    END IF
  END FUNCTION Normalize

  !===============================================================================
  ! Normalize_Proc
  ! Procedure-style wrapper with Arg bundle (SIO compliant)
  !===============================================================================
  SUBROUTINE Normalize_Proc(arg)
    !> [INOUT] arg - Arg bundle (vec[IN], unit_vec[OUT])
    TYPE(Normalize_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: norm

    ALLOCATE(arg%unit_vec(SIZE(arg%vec)))
    norm = Norm_L2(arg%vec)

    IF (norm > 1.0E-14_wp) THEN
      arg%unit_vec = arg%vec / norm
    ELSE
      arg%unit_vec = arg%vec  ! Already zero or near-zero
    END IF
  END SUBROUTINE Normalize_Proc

END MODULE NM_Base_Norms
