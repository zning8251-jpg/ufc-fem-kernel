!===============================================================================
! MODULE: PH_Elem_ComplexStiff
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  Form complex stiffness K* = K*(1 + 2i*eta) for structural damping
!         [SIO Phase 3C] Form uses PH_Elem_ComplexStiff_Form_Arg.
!===============================================================================
MODULE PH_Elem_ComplexStiff
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_Def, ONLY: PH_Elem_ComplexStiff_Form_Arg
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Elem_ComplexStiff_Form

  !=============================================================================
  ! INTF-001 Arg TYPE (legacy — retained for backward compatibility)
  !=============================================================================
  PUBLIC :: PH_Elem_ComplexStiff_Args
  TYPE :: PH_Elem_ComplexStiff_Args
  ! Purpose: INTF-style argument bundle; see module header.
  ! Theory:
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE PH_Elem_ComplexStiff_Args


CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Elem_ComplexStiff_Form: Form K* = K*(1 + 2i*eta) from real K (CSR)
  !   K_real = K, K_imag = 2*eta*K
  !   Hermitian: K*(i,j) = CONJG(K*(j,i)) when K symmetric
  ! SIO: (arg, status) — arg = PH_Elem_ComplexStiff_Form_Arg
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_ComplexStiff_Form(arg, status)
    TYPE(PH_Elem_ComplexStiff_Form_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: k

    CALL init_error_status(status)

    ! Allocate outputs if needed
    IF (.NOT. ALLOCATED(arg%K_real)) ALLOCATE(arg%K_real(arg%nnz))
    IF (.NOT. ALLOCATED(arg%K_imag)) ALLOCATE(arg%K_imag(arg%nnz))

    IF (SIZE(arg%K_val) < arg%nnz .OR. SIZE(arg%K_real) < arg%nnz &
        .OR. SIZE(arg%K_imag) < arg%nnz) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_ComplexStiff_Form: array size < nnz"
      RETURN
    END IF

    ! K* = K*(1 + 2i*eta) => K_real = K, K_imag = 2*eta*K
    DO k = 1, arg%nnz
      arg%K_real(k) = arg%K_val(k)
      arg%K_imag(k) = 2.0_wp * arg%eta * arg%K_val(k)
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_ComplexStiff_Form

END MODULE PH_Elem_ComplexStiff
