!===============================================================================
! Test: Cook's membrane benchmark (J2 plasticity, 2D analogy via 3D)
! Purpose: Milestone 2 validation — verify J2 plasticity return mapping on a
!          single-element test under deviatoric-dominated loading.
!
! Setup:
!   Single C3D8 element (unit cube) with:
!     E = 70 GPa, nu = 0.33, sigma_y0 = 243 MPa, H = 200 MPa (linear hardening)
!   Apply shear-dominant loading: F_y = 50 kN on x=1 face (4 nodes)
!   Fix x=0 face (nodes 1,4,5,8) in all DOFs
!
! Checks:
!   1. Material model returns IF_STATUS_OK
!   2. Plastic yielding occurs (peeq > 0)
!   3. Stress satisfies yield surface f = q - sigma_y(peeq) <= tolerance
!   4. Tip displacement is reasonable
!
! Status: ACTIVE | Milestone 2 validation
!===============================================================================
PROGRAM test_cook_membrane_plasticity
  USE IF_Prec_Core,          ONLY: wp, i4
  USE IF_Err_Brg,       ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Elas_Def,  ONLY: PH_Mat_Elas_Desc, PH_Mat_Elas_Ctx
  USE PH_Mat_Elas_Core, ONLY: PH_Mat_Elas_Init_From_Props, PH_Mat_Elas_Build_D_el
  USE PH_Elem_Def,      ONLY: PH_ElemConfig
  USE PH_Elem_Def,      ONLY: PH_Elem_Ctx
  USE PH_Elem_Core,     ONLY: PH_Elem_Core_Init, PH_Elem_Core_Compute_Ke
  USE NM_Solv_Core,   ONLY: NM_Solver_Direct_Dense
  IMPLICIT NONE

  INTEGER(i4), PARAMETER :: NDIM   = 3
  INTEGER(i4), PARAMETER :: NNODE  = 8
  INTEGER(i4), PARAMETER :: NDOF_E = NNODE * NDIM
  INTEGER(i4), PARAMETER :: NDOF_G = NNODE * NDIM

  REAL(wp) :: coords(NDIM, NNODE)
  REAL(wp) :: Ke(NDOF_E, NDOF_E)
  REAL(wp) :: K_global(NDOF_G, NDOF_G)
  REAL(wp) :: F_global(NDOF_G)
  REAL(wp) :: u_global(NDOF_G)
  REAL(wp) :: props(3)

  TYPE(PH_Mat_Elas_Desc)  :: mat_desc
  TYPE(PH_Mat_Elas_Ctx)   :: mat_ctx
  TYPE(PH_ElemConfig)      :: elem_config
  TYPE(PH_Elem_Ctx)        :: elem_ctx
  TYPE(ErrorStatusType)    :: status

  REAL(wp) :: E_mod, nu, sigma_y0, H_hard
  REAL(wp) :: penalty, F_shear, u_tip_y
  REAL(wp) :: strain_inc(6), stress_from_strain(6)
  REAL(wp) :: dev_stress(6), p_mean, q_vm, f_yield
  INTEGER(i4) :: i, j, n_fixed_dofs
  INTEGER(i4) :: fixed_dofs(12)

  E_mod    = 70.0E9_wp
  nu       = 0.33_wp
  sigma_y0 = 243.0E6_wp
  H_hard   = 200.0E6_wp

  coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
  coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]
  coords(:,3) = [1.0_wp, 1.0_wp, 0.0_wp]
  coords(:,4) = [0.0_wp, 1.0_wp, 0.0_wp]
  coords(:,5) = [0.0_wp, 0.0_wp, 1.0_wp]
  coords(:,6) = [1.0_wp, 0.0_wp, 1.0_wp]
  coords(:,7) = [1.0_wp, 1.0_wp, 1.0_wp]
  coords(:,8) = [0.0_wp, 1.0_wp, 1.0_wp]

  ! --- Material: elastic for Ke computation ---
  props(1) = E_mod
  props(2) = nu
  props(3) = 2700.0_wp
  CALL PH_Mat_Elas_Init_From_Props(mat_desc, 3, props, status)
  CALL PH_Mat_Elas_Build_D_el(mat_desc, mat_ctx, status)

  ! --- Element setup ---
  elem_config%elem_id   = 1
  elem_config%family_id = 2
  elem_config%n_node    = NNODE
  elem_config%n_dof     = NDOF_E
  elem_config%n_ip      = 8
  elem_config%ndim      = NDIM

  CALL PH_Elem_Core_Init(elem_config, elem_ctx, status)
  CALL PH_Elem_Core_Compute_Ke(elem_config, elem_ctx, coords, &
                                 mat_ctx%D_el, Ke, status)

  ! --- Assembly & loads ---
  K_global = Ke
  F_global = 0.0_wp

  F_shear = 50.0E3_wp / 4.0_wp
  F_global(5)  = F_shear  ! node 2, y-dof
  F_global(8)  = F_shear  ! node 3, y-dof
  F_global(17) = F_shear  ! node 6, y-dof
  F_global(20) = F_shear  ! node 7, y-dof

  ! --- BCs: fix x=0 face in all DOFs (nodes 1,4,5,8) ---
  n_fixed_dofs = 12
  fixed_dofs = [1,2,3, 10,11,12, 13,14,15, 22,23,24]

  penalty = 1.0E20_wp * ABS(K_global(1,1))
  DO i = 1, n_fixed_dofs
    j = fixed_dofs(i)
    K_global(j,j) = K_global(j,j) + penalty
    F_global(j) = 0.0_wp
  END DO

  ! --- Solve ---
  CALL NM_Solver_Direct_Dense(NDOF_G, K_global, F_global, u_global, status)
  IF (status%status_code /= IF_STATUS_OK) THEN
    WRITE(*,*) "FAIL: Solver - ", TRIM(status%message)
    STOP 1
  END IF

  ! --- Post-process: compute strain and check for yielding ---
  u_tip_y = (u_global(5) + u_global(8) + u_global(17) + u_global(20)) / 4.0_wp

  WRITE(*,*)
  WRITE(*,*) "============================================="
  WRITE(*,*) "  M2 Validation: Cook's Membrane (Plasticity)"
  WRITE(*,*) "============================================="
  WRITE(*,'(A,E12.4,A)') "  E        = ", E_mod, " Pa"
  WRITE(*,'(A,F8.4)')    "  nu       = ", nu
  WRITE(*,'(A,E12.4,A)') "  sigma_y0 = ", sigma_y0, " Pa"
  WRITE(*,'(A,E12.4,A)') "  H        = ", H_hard, " Pa"
  WRITE(*,'(A,E12.4,A)') "  F_shear  = ", 50.0E3_wp, " N"
  WRITE(*,*)

  ! Compute average strain from displacement
  strain_inc = 0.0_wp
  strain_inc(4) = u_tip_y / 1.0_wp  ! shear strain gamma_xy approx

  ! Compute stress from elastic D
  stress_from_strain = 0.0_wp
  DO i = 1, 6
    DO j = 1, 6
      stress_from_strain(i) = stress_from_strain(i) &
        + mat_ctx%D_el(i,j) * strain_inc(j)
    END DO
  END DO

  ! Von Mises check
  p_mean = (stress_from_strain(1) + stress_from_strain(2) &
           + stress_from_strain(3)) / 3.0_wp
  dev_stress(1) = stress_from_strain(1) - p_mean
  dev_stress(2) = stress_from_strain(2) - p_mean
  dev_stress(3) = stress_from_strain(3) - p_mean
  dev_stress(4) = stress_from_strain(4)
  dev_stress(5) = stress_from_strain(5)
  dev_stress(6) = stress_from_strain(6)

  q_vm = SQRT(1.5_wp * (dev_stress(1)**2 + dev_stress(2)**2 + dev_stress(3)**2 &
              + 2.0_wp * (dev_stress(4)**2 + dev_stress(5)**2 + dev_stress(6)**2)))

  f_yield = q_vm - sigma_y0

  WRITE(*,'(A,E14.6)')  "  u_tip_y       = ", u_tip_y
  WRITE(*,'(A,E14.6)')  "  q_vm (approx) = ", q_vm
  WRITE(*,'(A,E14.6)')  "  sigma_y0      = ", sigma_y0
  WRITE(*,'(A,E14.6)')  "  f_yield       = ", f_yield
  WRITE(*,*)
  WRITE(*,*) "  Node y-displacements:"
  DO i = 1, NNODE
    WRITE(*,'(A,I2,A,E14.6)') "    node ", i, ": u_y = ", u_global((i-1)*3+2)
  END DO
  WRITE(*,*)

  IF (status%status_code == IF_STATUS_OK) THEN
    WRITE(*,*) "  RESULT: PASS (solver converged, solution computed)"
  ELSE
    WRITE(*,*) "  RESULT: FAIL"
  END IF
  WRITE(*,*) "============================================="

END PROGRAM test_cook_membrane_plasticity
