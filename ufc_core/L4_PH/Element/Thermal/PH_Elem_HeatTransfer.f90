!===============================================================================
! MODULE: PH_Elem_HeatTransfer
! LAYER:  L4_PH
! DOMAIN: Element/Thermal
! ROLE:   Proc
! BRIEF:  Thermal conductivity and capacity matrices assembly
!===============================================================================
MODULE PH_Elem_HeatTransfer
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Elem_HeatTransfer_Kcond
  PUBLIC :: PH_Elem_HeatTransfer_Ccap
  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_HeatTransfer_Args
  TYPE :: PH_Elem_HeatTransfer_Args
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
  END TYPE PH_Elem_HeatTransfer_Args


CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Elem_HeatTransfer_Kcond: K_e = ?B^T·k·B dV (scalar thermal)
  !   B = dN/dx (gradient of shape functions)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_HeatTransfer_Kcond(B, k, detJ, w, nnode, K_e, status)
    REAL(wp), INTENT(IN) :: B(:,:)
    REAL(wp), INTENT(IN) :: k
    REAL(wp), INTENT(IN) :: detJ, w
    INTEGER(i4), INTENT(IN) :: nnode
    REAL(wp), INTENT(OUT) :: K_e(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, ndim

    CALL init_error_status(status)
    ndim = SIZE(B, 1)
    IF (SIZE(K_e, 1) < nnode .OR. SIZE(K_e, 2) < nnode) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_HeatTransfer_Kcond: K_e size < nnode"
      RETURN
    END IF

    DO j = 1, nnode
      DO i = 1, nnode
        K_e(i,j) = k * detJ * w * DOT_PRODUCT(B(:,i), B(:,j))
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_HeatTransfer_Kcond

  !-----------------------------------------------------------------------------
  ! PH_Elem_HeatTransfer_Ccap: C_e = ?ρ·c_p·N^T·N dV (lumped or consistent)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_HeatTransfer_Ccap(N, rho_cp, detJ, w, nnode, C_e, lumped, status)
    REAL(wp), INTENT(IN) :: N(:)
    REAL(wp), INTENT(IN) :: rho_cp
    REAL(wp), INTENT(IN) :: detJ, w
    INTEGER(i4), INTENT(IN) :: nnode
    REAL(wp), INTENT(OUT) :: C_e(:,:)
    LOGICAL, INTENT(IN), OPTIONAL :: lumped
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j
    REAL(wp) :: vol

    CALL init_error_status(status)
    IF (SIZE(C_e, 1) < nnode .OR. SIZE(C_e, 2) < nnode) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_HeatTransfer_Ccap: C_e size < nnode"
      RETURN
    END IF

    vol = rho_cp * detJ * w
    C_e = 0.0_wp
    IF (PRESENT(lumped) .AND. lumped) THEN
      DO i = 1, nnode
        C_e(i,i) = vol * N(i)
      END DO
    ELSE
      DO j = 1, nnode
        DO i = 1, nnode
          C_e(i,j) = vol * N(i) * N(j)
        END DO
      END DO
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_HeatTransfer_Ccap

END MODULE PH_Elem_HeatTransfer