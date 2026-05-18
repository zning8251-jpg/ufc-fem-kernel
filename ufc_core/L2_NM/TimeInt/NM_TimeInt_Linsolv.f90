!===============================================================================
! MODULE: NM_TimeInt_Linsolv
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Proc — Dense small-system LU solve (DGETRF/DGETRS) for Newmark/HHT
! BRIEF:  Local dense linear solve for time integration sub-problems
!===============================================================================
MODULE NM_TimeInt_Linsolv
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: NM_TimeInt_Dense_LU_Solve

  INTERFACE
    SUBROUTINE DGETRF(M, N, A, LDA, IPIV, INFO) BIND(C, NAME='dgetrf')
      IMPORT :: i4, wp
      INTEGER(i4), VALUE :: m, n, lda
      REAL(wp), INTENT(INOUT) :: a(lda, *)
      INTEGER(i4), INTENT(OUT) :: ipiv(*)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DGETRF

    SUBROUTINE DGETRS(TRANS, N, NRHS, A, LDA, IPIV, B, LDB, INFO) &
        BIND(C, NAME='dgetrs')
      IMPORT :: i4, wp
      CHARACTER(len=1), VALUE :: trans
      INTEGER(i4), VALUE :: n, nrhs, lda, ldb
      REAL(wp), INTENT(IN) :: a(lda, *)
      INTEGER(i4), INTENT(IN) :: ipiv(*)
      REAL(wp), INTENT(INOUT) :: b(ldb, *)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DGETRS
  END INTERFACE

CONTAINS

  SUBROUTINE NM_TimeInt_Dense_LU_Solve(n, A, b, x, info)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(INOUT) :: A(:, :)
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: info

    INTEGER(i4) :: ipiv(n), ierr, lda
    REAL(wp) :: bx(n, 1)

    lda = MAX(1, n)
    bx(:, 1) = b(1:n)
    CALL DGETRF(n, n, A, lda, ipiv, ierr)
    IF (PRESENT(info)) info = ierr
    IF (ierr /= 0) THEN
      x = 0.0_wp
      RETURN
    END IF
    CALL DGETRS('N', n, 1, A, lda, ipiv, bx, lda, ierr)
    IF (PRESENT(info)) info = ierr
    x(1:n) = bx(:, 1)
  END SUBROUTINE NM_TimeInt_Dense_LU_Solve

END MODULE NM_TimeInt_Linsolv