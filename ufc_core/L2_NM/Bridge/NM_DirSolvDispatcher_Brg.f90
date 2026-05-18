!===============================================================================
! MODULE: NM_DirSolvDispatcher_Brg
! LAYER:  L2_NM
! DOMAIN: Bridge
! ROLE:   Brg -- dispatcher for SparsePak/MUMPS via ufc_numcore
! BRIEF:  Routes CSR matrix to external sparse solvers. Avoids
!         NM_Solver_Direct_Core depending on ufc_numcore directly.
!
! SIO Compliance (Principle #14):
!   NM_Direct_Solv_SparsePak uses NM_Direct_Solv_SparsePak_Arg bundle.
!
! Status: PROD
! Last verified: 2026-04-29
!===============================================================================

MODULE NM_DirSolvDispatcher_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_DirSparsePak_Brg, ONLY: NM_SparsePak_Solv, NM_SparsePak_Handle, &
    NM_SPK_REORDER_RCM, NM_SPK_SUCCESS, NM_SPK_ERR_ALLOC, NM_SPK_ERR_SINGULAR, NM_SPK_ERR_NOT_SPD
  USE NM_Mtx_Core, ONLY: UF_CSRMatrix
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: NM_Direct_Solv_SparsePak
  PUBLIC :: NM_Direct_Solv_SparsePak_Arg

  ! Re-export error codes for caller convenience
  INTEGER(i4), PARAMETER, PUBLIC :: NM_DSP_OK = 0
  INTEGER(i4), PARAMETER, PUBLIC :: NM_DSP_ERR_ALLOC = -1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_DSP_ERR_SINGULAR = -2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_DSP_ERR_NOT_SPD = -3

  !===========================================================================
  ! NM_Direct_Solv_SparsePak_Arg - SIO Arg bundle for direct sparse solve
  ! Bundles CSR arrays + RHS/solution; ierr stays as independent status param.
  !===========================================================================
  TYPE :: NM_Direct_Solv_SparsePak_Arg
    INTEGER(i4) :: nrows = 0_i4             ! [IN]  Number of rows
    INTEGER(i4) :: ncols = 0_i4             ! [IN]  Number of columns
    INTEGER(i4) :: nnz   = 0_i4             ! [IN]  Number of non-zeros
    INTEGER(i4), POINTER :: row_ptr(:) => NULL()  ! [IN]  CSR row pointer (nrows+1)
    INTEGER(i4), POINTER :: col_ind(:) => NULL()  ! [IN]  CSR column index (nnz)
    REAL(wp), POINTER    :: values(:)  => NULL()  ! [IN]  CSR values (nnz)
    REAL(wp), POINTER    :: b(:)       => NULL()  ! [IN]  Right-hand side vector
    REAL(wp), POINTER    :: x(:)       => NULL()  ! [OUT] Solution vector
    INTEGER(i4)          :: reorder_type = -1_i4  ! [IN]  Reorder type (-1=default RCM)
  END TYPE NM_Direct_Solv_SparsePak_Arg

CONTAINS

  !-----------------------------------------------------------------------------
  !> Solve Ax = b via SparsePak; input as SIO Arg bundle
  !> Old: NM_Direct_Solv_SparsePak(nrows, ncols, nnz, row_ptr, col_ind,
  !>        values, b, x, ierr, reorder_type)  -- 10 params
  !> New: NM_Direct_Solv_SparsePak(arg, ierr)  -- 2 params
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_Direct_Solv_SparsePak(arg, ierr)
    !> [INOUT] arg  - SIO Arg bundle (CSR arrays + RHS + solution)
    !> [OUT]   ierr - Error code (0=success, negative=error)
    TYPE(NM_Direct_Solv_SparsePak_Arg), INTENT(INOUT) :: arg
    INTEGER(i4), INTENT(OUT) :: ierr

    TYPE(UF_CSRMatrix) :: A_uf
    INTEGER(i4) :: rtype

    ierr = NM_DSP_ERR_ALLOC
    IF (SIZE(arg%row_ptr) < arg%nrows + 1_i4 .OR. &
        SIZE(arg%col_ind) < arg%nnz .OR. SIZE(arg%values) < arg%nnz) RETURN
    IF (SIZE(arg%b) /= arg%nrows .OR. SIZE(arg%x) /= arg%nrows) RETURN

    A_uf%nrows = arg%nrows
    A_uf%ncols = arg%ncols
    A_uf%nnz = arg%nnz
    ALLOCATE(A_uf%row_ptr(arg%nrows + 1), A_uf%col_ind(arg%nnz), A_uf%val(arg%nnz))
    A_uf%row_ptr(1:arg%nrows+1) = arg%row_ptr(1:arg%nrows+1)
    A_uf%col_ind(1:arg%nnz) = arg%col_ind(1:arg%nnz)
    A_uf%val(1:arg%nnz) = arg%values(1:arg%nnz)
    A_uf%is_initialized = .TRUE.

    rtype = NM_SPK_REORDER_RCM
    IF (arg%reorder_type >= 0_i4) rtype = arg%reorder_type

    CALL NM_SparsePak_Solv(A_uf, arg%b, arg%x, ierr, rtype)

    DEALLOCATE(A_uf%row_ptr, A_uf%col_ind, A_uf%val)
    A_uf%is_initialized = .FALSE.
  END SUBROUTINE NM_Direct_Solv_SparsePak

END MODULE NM_DirSolvDispatcher_Brg
