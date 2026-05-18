!===============================================================================
! MODULE: NM_DirSparsePak_Brg
! LAYER:  L2_NM
! DOMAIN: Bridge
! ROLE:   Brg — SparsePak Cholesky direct solver bridge
! BRIEF:  Wraps NM_SparsePakWrapper for L2_NM/RT. One-shot solve or
!         symbolic/numeric/solve/cleanup phased workflow.
!
! Status: PROD
! Last verified: 2026-04-28
!===============================================================================

MODULE NM_DirSparsePak_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_Mtx_Core, ONLY: UF_CSRMatrix
  USE NM_Solv_SparsePakWrap, ONLY: UF_SparsePakHandle, &
    spk_solve_csr, spk_symbolic_csr, spk_numeric_csr, spk_solve_factored, &
    NM_SPK_REORDER_RCM, NM_SPK_REORDER_QMD, NM_SPK_REORDER_ND, &
    NM_SPK_SUCCESS, NM_SPK_ERR_ALLOC, NM_SPK_ERR_SINGULAR, NM_SPK_ERR_NOT_SPD
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_SparsePak_Solv
  PUBLIC :: NM_SparsePak_Symbolic
  PUBLIC :: NM_SparsePak_Numeric
  PUBLIC :: NM_SparsePak_Solv_Factored
  PUBLIC :: NM_SparsePak_Cleanup
  PUBLIC :: NM_SparsePak_Handle
  ! Re-export constants from NM_SparsePakWrapper
  PUBLIC :: NM_SPK_REORDER_RCM, NM_SPK_REORDER_QMD, NM_SPK_REORDER_ND
  PUBLIC :: NM_SPK_SUCCESS, NM_SPK_ERR_ALLOC, NM_SPK_ERR_SINGULAR, NM_SPK_ERR_NOT_SPD

  !=============================================================================
  ! HANDLE TYPE - Opaque wrapper around UF_SparsePakHandle
  !=============================================================================
  TYPE, PUBLIC :: NM_SparsePak_Handle
    TYPE(UF_SparsePakHandle) :: uf_handle
  END TYPE NM_SparsePak_Handle

CONTAINS

  !-----------------------------------------------------------------------------
  ! One-shot direct solve: Ax = b
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparsePak_Solv(A, b, x, ierr, reorder_type)
    TYPE(UF_CSRMatrix), INTENT(IN) :: A
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(OUT) :: ierr
    INTEGER(i4), INTENT(IN), OPTIONAL :: reorder_type

    IF (PRESENT(reorder_type)) THEN
      CALL spk_solve_csr(A, b, x, reorder_type, ierr)
    ELSE
      CALL spk_solve_csr(A, b, x, ierr=ierr)
    END IF
  END SUBROUTINE NM_SparsePak_Solv

  !-----------------------------------------------------------------------------
  ! Symbolic factorization (structure analysis)
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparsePak_Symbolic(A, handle, reorder_type, ierr)
    TYPE(UF_CSRMatrix), INTENT(IN) :: A
    TYPE(NM_SparsePak_Handle), INTENT(INOUT) :: handle
    INTEGER(i4), INTENT(IN) :: reorder_type
    INTEGER(i4), INTENT(OUT) :: ierr

    CALL spk_symbolic_csr(A, handle%uf_handle, reorder_type, ierr)
  END SUBROUTINE NM_SparsePak_Symbolic

  !-----------------------------------------------------------------------------
  ! Numeric factorization (values)
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparsePak_Numeric(A, handle, ierr)
    TYPE(UF_CSRMatrix), INTENT(IN) :: A
    TYPE(NM_SparsePak_Handle), INTENT(INOUT) :: handle
    INTEGER(i4), INTENT(OUT) :: ierr

    CALL spk_numeric_csr(A, handle%uf_handle, ierr)
  END SUBROUTINE NM_SparsePak_Numeric

  !-----------------------------------------------------------------------------
  ! Solve with existing factorization
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparsePak_Solv_Factored(handle, b, x, ierr)
    TYPE(NM_SparsePak_Handle), INTENT(INOUT) :: handle
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(OUT) :: ierr

    CALL spk_solve_factored(handle%uf_handle, b, x, ierr)
  END SUBROUTINE NM_SparsePak_Solv_Factored

  !-----------------------------------------------------------------------------
  ! Release handle resources
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparsePak_Cleanup(handle)
    TYPE(NM_SparsePak_Handle), INTENT(INOUT) :: handle

    CALL handle%uf_handle%cleanup()
  END SUBROUTINE NM_SparsePak_Cleanup

END MODULE NM_DirSparsePak_Brg