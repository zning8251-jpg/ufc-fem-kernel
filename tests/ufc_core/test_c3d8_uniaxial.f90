!===============================================================================
! Test: Single C3D8 under uniaxial tension
! Purpose: Milestone 1 validation — verify displacement against analytical
!          solution for a unit cube with E=200GPa, nu=0.3, applied stress=100MPa.
!
! Analytical solution:
!   eps_x = sigma / E = 100e6 / 200e9 = 5e-4
!   eps_y = eps_z = -nu * eps_x = -0.3 * 5e-4 = -1.5e-4
!   u_x(face x=1) = eps_x * L = 5e-4 * 1.0 = 5e-4 m
!
! Setup:
!   Unit cube [0,1]^3, 8 nodes, 1 C3D8 element
!   BCs: fix x=0 face (nodes 1,4,5,8) in x; fix node 1 in y,z
!   Load: sigma_x = 100 MPa on x=1 face -> concentrated forces on nodes 2,3,6,7
!         F_total = sigma * A = 100e6 * 1.0 = 100e6 N
!         F_per_node = 100e6 / 4 = 25e6 N
!
! Status: ACTIVE | Milestone 1 validation
!===============================================================================
PROGRAM test_c3d8_uniaxial
  USE IF_Prec_Core,          ONLY: wp, i4
  USE IF_Err_Brg,       ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Elas_Def,  ONLY: PH_Mat_Elas_Desc, PH_Mat_Elas_Ctx
  USE PH_Mat_Elas_Core, ONLY: PH_Mat_Elas_Init_From_Props, PH_Mat_Elas_Build_D_el
  USE PH_Elem_Def,      ONLY: PH_ElemConfig
  USE PH_Elem_Def,      ONLY: PH_Elem_Ctx
  USE PH_Elem_Core,     ONLY: PH_Elem_Core_Init, PH_Elem_Core_Compute_Ke
  USE NM_Solv_Core,   ONLY: NM_Solver_Cholesky
  IMPLICIT NONE

  INTEGER(i4), PARAMETER :: NDIM     = 3
  INTEGER(i4), PARAMETER :: NNODE    = 8
  INTEGER(i4), PARAMETER :: NDOF_E   = NNODE * NDIM     ! 24
  INTEGER(i4), PARAMETER :: NDOF_G   = NNODE * NDIM     ! 24 (single element)
  INTEGER(i4), PARAMETER :: NSTRS    = 6

  REAL(wp) :: coords(NDIM, NNODE)
  REAL(wp) :: Ke(NDOF_E, NDOF_E)
  REAL(wp) :: K_global(NDOF_G, NDOF_G)
  REAL(wp) :: F_global(NDOF_G)
  REAL(wp) :: u_global(NDOF_G)
  REAL(wp) :: props(3)

  TYPE(PH_Mat_Elas_Desc) :: mat_desc
  TYPE(PH_Mat_Elas_Ctx)  :: mat_ctx
  TYPE(PH_ElemConfig)     :: elem_config
  TYPE(PH_Elem_Ctx)       :: elem_ctx
  TYPE(ErrorStatusType)   :: status

  REAL(wp) :: E_mod, nu, sigma_x, F_node, u_analytical, u_computed, error_pct
  REAL(wp) :: penalty
  INTEGER(i4) :: i

  E_mod   = 200.0E9_wp
  nu      = 0.3_wp
  sigma_x = 100.0E6_wp

  ! Unit cube node coordinates
  !   1:(0,0,0) 2:(1,0,0) 3:(1,1,0) 4:(0,1,0)
  !   5:(0,0,1) 6:(1,0,1) 7:(1,1,1) 8:(0,1,1)
  coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
  coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]
  coords(:,3) = [1.0_wp, 1.0_wp, 0.0_wp]
  coords(:,4) = [0.0_wp, 1.0_wp, 0.0_wp]
  coords(:,5) = [0.0_wp, 0.0_wp, 1.0_wp]
  coords(:,6) = [1.0_wp, 0.0_wp, 1.0_wp]
  coords(:,7) = [1.0_wp, 1.0_wp, 1.0_wp]
  coords(:,8) = [0.0_wp, 1.0_wp, 1.0_wp]

  ! --- Material setup ---
  props(1) = E_mod
  props(2) = nu
  props(3) = 7800.0_wp
  CALL PH_Mat_Elas_Init_From_Props(mat_desc, 3, props, status)
  IF (status%status_code /= IF_STATUS_OK) THEN
    WRITE(*,*) "FAIL: Material init"
    STOP 1
  END IF

  CALL PH_Mat_Elas_Build_D_el(mat_desc, mat_ctx, status)
  IF (status%status_code /= IF_STATUS_OK) THEN
    WRITE(*,*) "FAIL: D_el build"
    STOP 1
  END IF

  ! --- Element setup ---
  elem_config%elem_id   = 1
  elem_config%family_id = 2       ! C3D8
  elem_config%n_node    = NNODE
  elem_config%n_dof     = NDOF_E
  elem_config%n_ip      = 8
  elem_config%ndim      = NDIM

  CALL PH_Elem_Core_Init(elem_config, elem_ctx, status)
  IF (status%status_code /= IF_STATUS_OK) THEN
    WRITE(*,*) "FAIL: Element init"
    STOP 1
  END IF

  ! --- Compute element stiffness ---
  CALL PH_Elem_Core_Compute_Ke(elem_config, elem_ctx, coords, &
                                 mat_ctx%D_el, Ke, status)
  IF (status%status_code /= IF_STATUS_OK) THEN
    WRITE(*,*) "FAIL: Compute Ke"
    STOP 1
  END IF

  WRITE(*,*) "Element stiffness Ke computed successfully"
  WRITE(*,'(A,E12.4)') "  Ke(1,1) = ", Ke(1,1)
  WRITE(*,'(A,E12.4)') "  Ke(1,2) = ", Ke(1,2)

  ! --- Assembly (single element, DOF map is identity) ---
  K_global = Ke
  F_global = 0.0_wp

  ! --- Apply loads ---
  F_node = sigma_x * 1.0_wp / 4.0_wp   ! 100MPa * 1m^2 / 4 nodes
  ! Nodes 2,3,6,7 are on x=1 face, x-DOF indices: 4,7,16,19
  F_global(4)  = F_node  ! node 2, x-dof
  F_global(7)  = F_node  ! node 3, x-dof
  F_global(16) = F_node  ! node 6, x-dof
  F_global(19) = F_node  ! node 7, x-dof

  ! --- Apply BCs ---
  penalty = 1.0E20_wp * ABS(K_global(1,1))
  ! Fix nodes 1,4,5,8 in x-direction (DOFs 1,10,13,22)
  DO i = 1, 4
    SELECT CASE(i)
      CASE(1); K_global(1,1)   = K_global(1,1) + penalty;   F_global(1)  = 0.0_wp
      CASE(2); K_global(10,10) = K_global(10,10) + penalty;  F_global(10) = 0.0_wp
      CASE(3); K_global(13,13) = K_global(13,13) + penalty;  F_global(13) = 0.0_wp
      CASE(4); K_global(22,22) = K_global(22,22) + penalty;  F_global(22) = 0.0_wp
    END SELECT
  END DO

  ! Fix node 1 in y and z (DOFs 2,3) to prevent rigid body motion
  K_global(2,2) = K_global(2,2) + penalty; F_global(2) = 0.0_wp
  K_global(3,3) = K_global(3,3) + penalty; F_global(3) = 0.0_wp
  ! Fix node 4 in z (DOF 12) and node 5 in y (DOF 14) for symmetry
  K_global(12,12) = K_global(12,12) + penalty; F_global(12) = 0.0_wp
  K_global(14,14) = K_global(14,14) + penalty; F_global(14) = 0.0_wp

  ! --- Solve ---
  CALL NM_Solver_Cholesky(NDOF_G, K_global, F_global, u_global, status)
  IF (status%status_code /= IF_STATUS_OK) THEN
    WRITE(*,*) "FAIL: Solver - ", TRIM(status%message)
    STOP 1
  END IF

  ! --- Check results ---
  u_analytical = sigma_x / E_mod * 1.0_wp   ! 5.0e-4

  ! Average x-displacement of x=1 face nodes (2,3,6,7)
  u_computed = (u_global(4) + u_global(7) + u_global(16) + u_global(19)) / 4.0_wp

  error_pct = ABS(u_computed - u_analytical) / u_analytical * 100.0_wp

  WRITE(*,*)
  WRITE(*,*) "========================================="
  WRITE(*,*) "  M1 Validation: C3D8 Uniaxial Tension"
  WRITE(*,*) "========================================="
  WRITE(*,'(A,E12.4,A)') "  E        = ", E_mod, " Pa"
  WRITE(*,'(A,F8.4)')    "  nu       = ", nu
  WRITE(*,'(A,E12.4,A)') "  sigma_x  = ", sigma_x, " Pa"
  WRITE(*,*)
  WRITE(*,'(A,E14.6)')   "  u_analytical = ", u_analytical
  WRITE(*,'(A,E14.6)')   "  u_computed   = ", u_computed
  WRITE(*,'(A,F8.4,A)')  "  error        = ", error_pct, " %"
  WRITE(*,*)
  WRITE(*,*) "  Node displacements (x-direction):"
  DO i = 1, NNODE
    WRITE(*,'(A,I2,A,E14.6)') "    node ", i, ": u_x = ", u_global((i-1)*3+1)
  END DO
  WRITE(*,*)

  IF (error_pct < 1.0_wp) THEN
    WRITE(*,*) "  RESULT: PASS (error < 1%)"
  ELSE
    WRITE(*,*) "  RESULT: FAIL (error >= 1%)"
  END IF
  WRITE(*,*) "========================================="

END PROGRAM test_c3d8_uniaxial
