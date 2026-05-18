!===============================================================================
! MODULE: PH_Elem_C3D20T
! LAYER:  L4_PH
! DOMAIN: Element/Solid3Dt
! ROLE:   Proc
! BRIEF:  C3D20T unified interface (merged Defn + Sect + Constraints + Cont + Loads + Out)
!===============================================================================
MODULE PH_Elem_C3D20T
!> [CORE] C3D20T element unified interface (merged 6 files)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_Elem_C3D20, ONLY: &
    PH_Elem_C3D20_ShapeFunc, PH_Elem_C3D20_Jac, PH_Elem_C3D20_BMatrix, &
    PH_Elem_C3D20_ConsMass, PH_Elem_C3D20_LumpMass, PH_Elem_C3D20_ThermStrainVector, &
    PH_Elem_C3D20_GaussPoints, PH_Elem_C3D20_JacB, PH_Elem_C3D20_ConstMatrix, &
    PH_ELEM_C3D20_FACE_NODES, PH_ELEM_GAUSS_PT, &
    PH_Elem_C3D20_FormBodyForce, PH_Elem_C3D20_FormFacePressure, &
    PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_NNODE       = 20_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_NIP         = 27_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_NDOF_MECH   = 60_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_NDOF_THERM  = 20_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_NDOF_TOTAL  = 80_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_LOAD_BODY         = PH_ELEM_LOAD_BODY
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_LOAD_FACE_P      = PH_ELEM_LOAD_FACE_P
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_LOAD_GRAV        = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_LOAD_HEAT_SOURCE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20T_LOAD_THERMAL_FLUX = 5_i4

  TYPE :: PH_ELEM_C3D20T_OutputData
    REAL(wp) :: nodal_displacements(60)
    REAL(wp) :: nodal_temperatures(20)
    REAL(wp) :: nodal_stresses(6, 20)
    REAL(wp) :: nodal_strains(6, 20)
    REAL(wp) :: von_mises_stress(20)
    REAL(wp) :: thermal_stress(6, 20)
    REAL(wp) :: total_stress(6, 20)
    REAL(wp) :: heat_flux(3, 20)
    REAL(wp) :: element_energy(3)
  END TYPE PH_ELEM_C3D20T_OutputData

  PUBLIC :: PH_Elem_C3D20T_DefInit, PH_Elem_C3D20T_ThermStrain3D
  PUBLIC :: PH_Elem_C3D20T_FormStiffMatrix, PH_Elem_C3D20T_FormStiffMatrix_MatAware
  PUBLIC :: PH_Elem_C3D20T_FormThermalStiffness, PH_Elem_C3D20T_FormCouplingStiffness
  PUBLIC :: PH_Elem_C3D20T_FormIntForce, PH_Elem_C3D20T_FormIntForce_MatAware
  PUBLIC :: PH_Elem_C3D20T_ConsMass, PH_Elem_C3D20T_LumpMass
  PUBLIC :: PH_Elem_C3D20T_ShapeFunc, PH_Elem_C3D20T_Jac, PH_Elem_C3D20T_GaussPoints, PH_Elem_C3D20T_JacB
  PUBLIC :: PH_ELEM_C3D20T_NNODE, PH_ELEM_C3D20T_NIP, PH_ELEM_C3D20T_NDOF_MECH, PH_ELEM_C3D20T_NDOF_THERM, PH_ELEM_C3D20T_NDOF_TOTAL
  PUBLIC :: PH_Elem_C3D20T_GetVolume, PH_Elem_C3D20T_GetSectProps, PH_Elem_C3D20T_GetCentroid
  PUBLIC :: PH_Elem_C3D20T_FormMechBodyForce, PH_Elem_C3D20T_FormMechFacePressure
  PUBLIC :: PH_Elem_C3D20T_FormThermalBodySource, PH_Elem_C3D20T_FormThermalFaceFlux
  PUBLIC :: PH_Elem_C3D20T_FormNodalForce
  PUBLIC :: PH_ELEM_C3D20T_LOAD_BODY, PH_ELEM_C3D20T_LOAD_FACE_P, PH_ELEM_C3D20T_LOAD_GRAV
  PUBLIC :: PH_ELEM_C3D20T_LOAD_HEAT_SOURCE, PH_ELEM_C3D20T_LOAD_THERMAL_FLUX
  PUBLIC :: PH_ELEM_C3D20T_OutputData
  PUBLIC :: PH_Elem_C3D20T_Material_Update_Thermo_Routed

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Sld3DT_Args
  TYPE :: PH_Elem_Sld3DT_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  REAL(wp)              :: k_therm     = 0.0_wp  ! thermal conductivity scale
  REAL(wp)              :: rho_cp      = 0.0_wp  ! density times heat capacity
  REAL(wp), POINTER     :: T_elem(:)   => NULL()  ! element temperature vector ptr
  REAL(wp), POINTER     :: Ktherm(:,:) => NULL()  ! thermal-thermal block ptr
  REAL(wp), POINTER     :: F_heat(:)   => NULL()  ! thermal force / heat flux load ptr
  REAL(wp), POINTER     :: ip_temp(:)  => NULL()  ! IP temperature ptr
  END TYPE PH_Elem_Sld3DT_Args


CONTAINS

  SUBROUTINE PH_Elem_C3D20T_ThermStrain3D(T, T_ref, alpha, strain_th)
    REAL(wp), INTENT(IN)  :: T(:)
    REAL(wp), INTENT(IN)  :: T_ref, alpha
    REAL(wp), INTENT(OUT) :: strain_th(6)
    REAL(wp) :: dT_avg
    INTEGER(i4) :: nNode
    nNode = SIZE(T)
    dT_avg = SUM(T) / REAL(nNode, wp) - T_ref
    strain_th(1:3) = alpha * dT_avg
    strain_th(4:6) = ZERO
  END SUBROUTINE PH_Elem_C3D20T_ThermStrain3D

  SUBROUTINE PH_Elem_C3D20T_FormStiffMatrix_MatAware(coords, mat_prop, mat_state, &
                                                     alpha, k_thermal, T_elem, T_ref, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: alpha, k_thermal, T_ref
    REAL(wp), INTENT(IN)  :: T_elem(20)
    REAL(wp), INTENT(OUT) :: Ke(80, 80)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60)
    REAL(wp) :: dV, D_tangent(6, 6), strain_thermal(6)
    REAL(wp) :: Ke_uu(60, 60), Ke_tt(20, 20), Ke_ut(60, 20)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: ip, i, j

    Ke = ZERO
    Ke_uu = ZERO
    CALL PH_Elem_C3D20T_ThermStrain3D(T_elem, T_ref, alpha, strain_thermal)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      ss_gp%strain = strain_thermal
      ss_gp%strain_inc = ZERO
      ss_gp%sigma = ZERO
      ss_gp%tangent = ZERO
      CALL PH_UpdateStress(mat_prop, mat_state(ip), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) CYCLE
      D_tangent = ss_gp%tangent
      dV = detJ * weights(ip)
      Ke_uu = Ke_uu + MATMUL(TRANSPOSE(B), MATMUL(D_tangent, B)) * dV
    END DO
    Ke(1:60, 1:60) = Ke_uu
    CALL PH_Elem_C3D20T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    Ke(61:80, 61:80) = Ke_tt
    CALL PH_Elem_C3D20T_FormCouplingStiffness(coords, D_tangent, alpha, Ke_ut)
    Ke(1:60, 61:80) = Ke_ut
    DO j = 1, 20
      DO i = 1, 60
        Ke(60 + j, i) = Ke_ut(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20T_FormStiffMatrix_MatAware

  SUBROUTINE PH_Elem_C3D20T_FormCouplingStiffness(coords, D_tangent, alpha, Ke_ut)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: D_tangent(6, 6)
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(OUT) :: Ke_ut(60, 20)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60)
    REAL(wp) :: beta, dV, B_vol(60)
    INTEGER(i4) :: ip, i
    Ke_ut = ZERO
    IF (ABS(alpha) <= 1.0e-12_wp) RETURN
    beta = D_tangent(1,1) + D_tangent(1,2) + D_tangent(1,3)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = alpha * beta * detJ * weights(ip)
      B_vol(1:60) = B(1, 1:60) + B(2, 1:60) + B(3, 1:60)
      DO i = 1, 20
        Ke_ut(1:60, i) = Ke_ut(1:60, i) + dV * B_vol(1:60) * N(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20T_FormCouplingStiffness

  SUBROUTINE PH_Elem_C3D20T_FormStiffMatrix(coords, E_young, nu, alpha, k_thermal, T_ref, Ke)
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha, k_thermal, T_ref
    REAL(wp), INTENT(OUT) :: Ke(80, 80)
    TYPE(MatPropertyDef) :: mat_prop_dummy
    TYPE(PH_MatPoint_State) :: mat_state_dummy(27)
    REAL(wp) :: T_elem(20)
    INTEGER(i4) :: i
    mat_prop_dummy%mat_id = 1
    mat_prop_dummy%num_props = 2
    ALLOCATE(mat_prop_dummy%props(2))
    mat_prop_dummy%props(1) = E_young
    mat_prop_dummy%props(2) = nu
    mat_prop_dummy%num_state_vars = 0
    DO i = 1, 27
      mat_state_dummy(i)%mat_id = 1
      mat_state_dummy(i)%nStatev = 0
      mat_state_dummy(i)%is_initialized = .TRUE.
    END DO
    T_elem = T_ref
    CALL PH_Elem_C3D20T_FormStiffMatrix_MatAware(coords, mat_prop_dummy, mat_state_dummy, &
                                                   alpha, k_thermal, T_elem, T_ref, Ke)
    DEALLOCATE(mat_prop_dummy%props)
  END SUBROUTINE PH_Elem_C3D20T_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D20T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: k_thermal
    REAL(wp), INTENT(OUT) :: Ke_tt(20, 20)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B_dum(6, 60)
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    Ke_tt = ZERO
    IF (k_thermal <= 1.0e-12_wp) RETURN
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B_dum)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = k_thermal * detJ * weights(ip)
      Ke_tt(1:20, 1:20) = Ke_tt(1:20, 1:20) + dV * MATMUL(TRANSPOSE(dNdx), dNdx)
    END DO
  END SUBROUTINE PH_Elem_C3D20T_FormThermalStiffness

  SUBROUTINE PH_Elem_C3D20T_FormIntForce_MatAware(coords, u, mat_prop, mat_state, &
                                                  alpha, k_thermal, T_elem, T_ref, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(80)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: alpha, k_thermal, T_ref
    REAL(wp), INTENT(IN)  :: T_elem(20)
    REAL(wp), INTENT(OUT) :: R_int(80)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60)
    REAL(wp) :: dV, strain_mech(6), strain_thermal(6), strain_total(6)
    REAL(wp) :: sigma(6), grad_T(3), q_thermal(3)
    REAL(wp) :: Ke_ut(60, 20), D_tangent(6, 6)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: ip, i

    R_int = ZERO
    CALL PH_Elem_C3D20T_ThermStrain3D(T_elem, T_ref, alpha, strain_thermal)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      strain_mech = MATMUL(B, u(1:60))
      strain_total = strain_mech + strain_thermal
      ss_gp%strain = strain_total
      ss_gp%strain_inc = strain_total
      ss_gp%sigma = ZERO
      ss_gp%tangent = ZERO
      CALL PH_UpdateStress(mat_prop, mat_state(ip), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) CYCLE
      sigma = ss_gp%sigma
      D_tangent = ss_gp%tangent
      dV = detJ * weights(ip)
      R_int(1:60) = R_int(1:60) + MATMUL(TRANSPOSE(B), sigma) * dV
    END DO
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      grad_T(1) = DOT_PRODUCT(dNdx(1, :), T_elem)
      grad_T(2) = DOT_PRODUCT(dNdx(2, :), T_elem)
      grad_T(3) = DOT_PRODUCT(dNdx(3, :), T_elem)
      q_thermal = -k_thermal * grad_T
      dV = detJ * weights(ip)
      DO i = 1, 20
        R_int(60 + i) = R_int(60 + i) + (dNdx(1, i)*q_thermal(1) + dNdx(2, i)*q_thermal(2) + dNdx(3, i)*q_thermal(3)) * dV
      END DO
    END DO
    CALL PH_Elem_C3D20T_FormCouplingStiffness(coords, D_tangent, alpha, Ke_ut)
    R_int(1:60) = R_int(1:60) + MATMUL(Ke_ut, T_elem)
  END SUBROUTINE PH_Elem_C3D20T_FormIntForce_MatAware

  SUBROUTINE PH_Elem_C3D20T_FormIntForce(coords, u, E_young, nu, alpha, k_thermal, T_ref, R_int)
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: u(80)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha, k_thermal, T_ref
    REAL(wp), INTENT(OUT) :: R_int(80)
    TYPE(MatPropertyDef) :: mat_prop_dummy
    TYPE(PH_MatPoint_State) :: mat_state_dummy(27)
    REAL(wp) :: T_elem(20)
    INTEGER(i4) :: i
    mat_prop_dummy%mat_id = 1
    mat_prop_dummy%num_props = 2
    ALLOCATE(mat_prop_dummy%props(2))
    mat_prop_dummy%props(1) = E_young
    mat_prop_dummy%props(2) = nu
    mat_prop_dummy%num_state_vars = 0
    DO i = 1, 27
      mat_state_dummy(i)%mat_id = 1
      mat_state_dummy(i)%nStatev = 0
      mat_state_dummy(i)%is_initialized = .TRUE.
    END DO
    T_elem = u(61:80)
    CALL PH_Elem_C3D20T_FormIntForce_MatAware(coords, u, mat_prop_dummy, mat_state_dummy, &
                                                alpha, k_thermal, T_elem, T_ref, R_int)
    DEALLOCATE(mat_prop_dummy%props)
  END SUBROUTINE PH_Elem_C3D20T_FormIntForce

  SUBROUTINE PH_Elem_C3D20T_DefInit()
  END SUBROUTINE PH_Elem_C3D20T_DefInit

  SUBROUTINE PH_Elem_C3D20T_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(80, 80)
    Me = ZERO
    CALL PH_Elem_C3D20_ConsMass(coords, rho, Me(1:60, 1:60))
  END SUBROUTINE PH_Elem_C3D20T_ConsMass

  SUBROUTINE PH_Elem_C3D20T_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(80)
    M_lumped = ZERO
    CALL PH_Elem_C3D20_LumpMass(coords, rho, M_lumped(1:60))
  END SUBROUTINE PH_Elem_C3D20T_LumpMass

  SUBROUTINE PH_Elem_C3D20T_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(20), dNdxi(3, 20)
    CALL PH_Elem_C3D20_ShapeFunc(xi, eta, zeta, N, dNdxi)
  END SUBROUTINE PH_Elem_C3D20T_ShapeFunc

  SUBROUTINE PH_Elem_C3D20T_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 20), coords(3, 20)
    REAL(wp), INTENT(OUT) :: J(3, 3), detJ
    CALL PH_Elem_C3D20_Jac(dNdxi, coords, J, detJ)
  END SUBROUTINE PH_Elem_C3D20T_Jac

  SUBROUTINE PH_Elem_C3D20T_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(27), eta(27), zeta(27), weights(27)
    CALL PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)
  END SUBROUTINE PH_Elem_C3D20T_GaussPoints

  SUBROUTINE PH_Elem_C3D20T_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(20), dNdx(3, 20), J(3, 3), detJ, B(6, 60)
    CALL PH_Elem_C3D20_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
  END SUBROUTINE PH_Elem_C3D20T_JacB

  SUBROUTINE PH_Elem_C3D20T_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D20T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20T_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D20T_GetVolume

  SUBROUTINE PH_Elem_C3D20T_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume, mass
    CALL PH_Elem_C3D20T_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D20T_GetSectProps

  SUBROUTINE PH_Elem_C3D20T_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    REAL(wp) :: vol, dV
    INTEGER(i4) :: ip, i, j
    vol = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D20T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20T_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      vol = vol + dV
      DO i = 1, 3
        DO j = 1, 20
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (vol > 1.0e-20_wp) centroid = centroid / vol
  END SUBROUTINE PH_Elem_C3D20T_GetCentroid

  SUBROUTINE PH_Elem_C3D20T_FormMechBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(80)
    F_eq = ZERO
    CALL PH_Elem_C3D20_FormBodyForce(coords, bx, by, bz, F_eq(1:60))
  END SUBROUTINE PH_Elem_C3D20T_FormMechBodyForce

  SUBROUTINE PH_Elem_C3D20T_FormMechFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(80)
    F_eq = ZERO
    CALL PH_Elem_C3D20_FormFacePressure(coords, p, face_id, F_eq(1:60))
  END SUBROUTINE PH_Elem_C3D20T_FormMechFacePressure

  SUBROUTINE PH_Elem_C3D20T_FormThermalBodySource(coords, Q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: Q
    REAL(wp), INTENT(OUT) :: F_therm(20)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(20), dNdxi(3, 20), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_therm = ZERO
    CALL PH_Elem_C3D20T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D20T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D20T_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 20
        F_therm(i) = F_therm(i) + N(i) * Q * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D20T_FormThermalBodySource

  SUBROUTINE PH_Elem_C3D20T_FormThermalFaceFlux(coords, face_id, q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: q
    REAL(wp), INTENT(OUT) :: F_therm(20)
    REAL(wp) :: xi_f(4), eta_f(4), w_f(4)
    REAL(wp) :: N(20), dNdxi(3, 20)
    REAL(wp) :: dr_dxi(3), dr_deta(3), dA
    REAL(wp) :: xi, et, zet
    INTEGER(i4) :: nodes(4), ip, i
    F_therm = ZERO
    xi_f(1) = -PH_ELEM_GAUSS_PT
    xi_f(2) = PH_ELEM_GAUSS_PT
    xi_f(3) = -PH_ELEM_GAUSS_PT
    xi_f(4) = PH_ELEM_GAUSS_PT
    eta_f(1) = -PH_ELEM_GAUSS_PT
    eta_f(2) = -PH_ELEM_GAUSS_PT
    eta_f(3) = PH_ELEM_GAUSS_PT
    eta_f(4) = PH_ELEM_GAUSS_PT
    w_f = ONE
    IF (face_id < 1 .OR. face_id > 6) RETURN
    nodes(1:4) = PH_ELEM_C3D20_FACE_NODES(1:4, face_id)
    SELECT CASE (face_id)
    CASE (1)
      zet = -ONE
      DO ip = 1, 4
        xi = xi_f(ip)
        et = eta_f(ip)
        CALL PH_Elem_C3D20T_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        dA = SQRT(SUM((/ dr_dxi(2)*dr_deta(3)-dr_dxi(3)*dr_deta(2), dr_dxi(3)*dr_deta(1)-dr_dxi(1)*dr_deta(3), dr_dxi(1)*dr_deta(2)-dr_dxi(2)*dr_deta(1) /)**2))
        IF (dA < 1.0e-15_wp) CYCLE
        DO i = 1, 4
          F_therm(nodes(i)) = F_therm(nodes(i)) + N(nodes(i)) * q * dA * w_f(ip)
        END DO
      END DO
    CASE (2)
      zet = ONE
      DO ip = 1, 4
        xi = xi_f(ip)
        et = eta_f(ip)
        CALL PH_Elem_C3D20T_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        dA = SQRT(SUM((/ dr_dxi(2)*dr_deta(3)-dr_dxi(3)*dr_deta(2), dr_dxi(3)*dr_deta(1)-dr_dxi(1)*dr_deta(3), dr_dxi(1)*dr_deta(2)-dr_dxi(2)*dr_deta(1) /)**2))
        IF (dA < 1.0e-15_wp) CYCLE
        DO i = 1, 4
          F_therm(nodes(i)) = F_therm(nodes(i)) + N(nodes(i)) * q * dA * w_f(ip)
        END DO
      END DO
    CASE (3, 4)
      et = MERGE(-ONE, ONE, face_id == 3)
      DO ip = 1, 4
        xi = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D20T_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        dA = SQRT(SUM((/ dr_dxi(2)*dr_deta(3)-dr_dxi(3)*dr_deta(2), dr_dxi(3)*dr_deta(1)-dr_dxi(1)*dr_deta(3), dr_dxi(1)*dr_deta(2)-dr_dxi(2)*dr_deta(1) /)**2))
        IF (dA < 1.0e-15_wp) CYCLE
        DO i = 1, 4
          F_therm(nodes(i)) = F_therm(nodes(i)) + N(nodes(i)) * q * dA * w_f(ip)
        END DO
      END DO
    CASE (5, 6)
      xi = MERGE(-ONE, ONE, face_id == 5)
      DO ip = 1, 4
        et = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D20T_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(2, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        dA = SQRT(SUM((/ dr_dxi(2)*dr_deta(3)-dr_dxi(3)*dr_deta(2), dr_dxi(3)*dr_deta(1)-dr_dxi(1)*dr_deta(3), dr_dxi(1)*dr_deta(2)-dr_dxi(2)*dr_deta(1) /)**2))
        IF (dA < 1.0e-15_wp) CYCLE
        DO i = 1, 4
          F_therm(nodes(i)) = F_therm(nodes(i)) + N(nodes(i)) * q * dA * w_f(ip)
        END DO
      END DO
    CASE DEFAULT
    END SELECT
  END SUBROUTINE PH_Elem_C3D20T_FormThermalFaceFlux

  SUBROUTINE PH_Elem_C3D20T_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 20)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(80)
    REAL(wp) :: F_mech(60), F_therm(20)
    F_eq = ZERO
    F_mech = ZERO
    F_therm = ZERO
    IF (load_type == PH_ELEM_C3D20T_LOAD_BODY) THEN
      CALL PH_Elem_C3D20_FormBodyForce(coords, val(1), val(2), val(3), F_mech)
    ELSE IF (load_type == PH_ELEM_C3D20T_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D20_FormFacePressure(coords, val(1), face_id, F_mech)
    ELSE IF (load_type == PH_ELEM_C3D20T_LOAD_GRAV .AND. SIZE(val) >= 5) THEN
      CALL PH_Elem_C3D20_FormBodyForce(coords, val(1)*val(2)*val(5), val(1)*val(3)*val(5), val(1)*val(4)*val(5), F_mech)
    ELSE IF (load_type == PH_ELEM_C3D20T_LOAD_HEAT_SOURCE .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D20T_FormThermalBodySource(coords, val(1), F_therm)
    ELSE IF (load_type == PH_ELEM_C3D20T_LOAD_THERMAL_FLUX .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D20T_FormThermalFaceFlux(coords, face_id, val(1), F_therm)
    END IF
    F_eq(1:60) = F_mech
    F_eq(61:80) = F_therm
  END SUBROUTINE PH_Elem_C3D20T_FormNodalForce

  SUBROUTINE PH_Elem_C3D20T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, &
                                                          dStrain_total, thermal_strain, &
                                                          stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ThermoElastic3D

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dStrain_total(6)
    REAL(wp),                  INTENT(IN)    :: thermal_strain(6)
    REAL(wp),                  INTENT(IN)    :: stress_old(6)
    REAL(wp),                  INTENT(OUT)   :: stress_new(6)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(6, 6)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ThermoElastic3D(rt_ctx, mat_slot, dStrain_total, thermal_strain, &
                                          stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_C3D20T_Material_Update_Thermo_Routed

END MODULE PH_Elem_C3D20T


