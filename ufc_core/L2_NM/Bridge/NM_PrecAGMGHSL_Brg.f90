!===============================================================================
! MODULE: NM_PrecAGMGHSL_Brg
! LAYER:  L2_NM
! DOMAIN: Bridge
! ROLE:   Brg — HSL MI20 AMG preconditioner bridge
! BRIEF:  Wraps NM_AMGInterface (HSL MI20 AMG) for L2_NM/RT.
!         Setup/Apply/Solve/Destroy workflow.
!
! Status: PROD
! Last verified: 2026-04-28
!===============================================================================

MODULE NM_PrecAGMGHSL_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_Solv_AMGInterface, ONLY: UF_AMG_Precond, UF_AMG_Control, UF_AMG_Info, &
    amg_setup, amg_apply, amg_solve, amg_destroy, amg_set_defaults, &
    NM_AMG_PURE, NM_AMG_PCG, NM_AMG_GMRES, NM_AMG_BICGSTAB, NM_AMG_MINRES
  USE NM_Mtx_Core, ONLY: UF_CSRMatrix
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_AMG_HSL_Setup
  PUBLIC :: NM_AMG_HSL_Apply
  PUBLIC :: NM_AMG_HSL_Solv
  PUBLIC :: NM_AMG_HSL_Destroy
  PUBLIC :: NM_AMG_HSL_SetDefaults
  PUBLIC :: NM_AMG_HSL_Handle
  PUBLIC :: NM_AMG_HSL_Control
  PUBLIC :: NM_AMG_HSL_Info

  ! Re-export Krylov solver constants for convenience
  PUBLIC :: NM_AMG_PURE, NM_AMG_PCG, NM_AMG_GMRES, NM_AMG_BICGSTAB, NM_AMG_MINRES

  !=============================================================================
  ! HANDLE TYPE - Opaque wrapper around UF_AMG_Precond
  !=============================================================================
  TYPE, PUBLIC :: NM_AMG_HSL_Handle
    TYPE(UF_AMG_Precond) :: uf_amg
  END TYPE NM_AMG_HSL_Handle

  TYPE, PUBLIC :: NM_AMG_HSL_Control
    TYPE(UF_AMG_Control) :: uf_ctrl
  END TYPE NM_AMG_HSL_Control

  TYPE, PUBLIC :: NM_AMG_HSL_Info
    TYPE(UF_AMG_Info) :: uf_info
  END TYPE NM_AMG_HSL_Info

CONTAINS

  !-----------------------------------------------------------------------------
  ! Setup AMG preconditioner using HSL MI20
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_AMG_HSL_Setup(amg, K, ierr, control)
    TYPE(NM_AMG_HSL_Handle), INTENT(INOUT) :: amg
    TYPE(UF_CSRMatrix), INTENT(IN) :: K
    INTEGER(i4), INTENT(OUT) :: ierr
    TYPE(NM_AMG_HSL_Control), INTENT(IN), OPTIONAL :: control

    IF (PRESENT(control)) THEN
      CALL amg_setup(amg%uf_amg, K, ierr, control%uf_ctrl)
    ELSE
      CALL amg_setup(amg%uf_amg, K, ierr)
    END IF
  END SUBROUTINE NM_AMG_HSL_Setup

  !-----------------------------------------------------------------------------
  ! Apply AMG as preconditioner: y = M^(-1) * x
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_AMG_HSL_Apply(amg, x, y)
    TYPE(NM_AMG_HSL_Handle), INTENT(INOUT) :: amg
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)

    CALL amg_apply(amg%uf_amg, x, y)
  END SUBROUTINE NM_AMG_HSL_Apply

  !-----------------------------------------------------------------------------
  ! Solve linear system using AMG with Krylov acceleration
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_AMG_HSL_Solv(amg, b, x, ierr)
    TYPE(NM_AMG_HSL_Handle), INTENT(INOUT) :: amg
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(OUT) :: ierr

    CALL amg_solve(amg%uf_amg, b, x, ierr)
  END SUBROUTINE NM_AMG_HSL_Solv

  !-----------------------------------------------------------------------------
  ! Destroy AMG preconditioner
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_AMG_HSL_Destroy(amg)
    TYPE(NM_AMG_HSL_Handle), INTENT(INOUT) :: amg

    CALL amg_destroy(amg%uf_amg)
  END SUBROUTINE NM_AMG_HSL_Destroy

  !-----------------------------------------------------------------------------
  ! Set default control parameters
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_AMG_HSL_SetDefaults(control)
    TYPE(NM_AMG_HSL_Control), INTENT(OUT) :: control

    CALL amg_set_defaults(control%uf_ctrl)
  END SUBROUTINE NM_AMG_HSL_SetDefaults

END MODULE NM_PrecAGMGHSL_Brg