!===============================================================================
! MODULE: PH_Elem_C3D15T
! LAYER:  L4_PH
! DOMAIN: Element/Solid3Dt
! ROLE:   Proc
! BRIEF:  C3D15T unified interface (merged Defn + Sect + Constraints + Cont + Loads + Out)
!===============================================================================
MODULE PH_Elem_C3D15T
!> [CORE] C3D15T element unified interface (merged 6 files)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_Elem_C3D15, ONLY: &
    PH_Elem_C3D15_ShapeFunc, PH_Elem_C3D15_Jac, PH_Elem_C3D15_BMatrix, &
    PH_Elem_C3D15_ConsMass, PH_Elem_C3D15_LumpMass, PH_Elem_C3D15_ThermStrainVector, &
    PH_Elem_C3D15_GaussPoints, PH_Elem_C3D15_JacB, PH_Elem_C3D15_ConstMatrix, &
    PH_ELEM_C3D15_FACE_NODES, PH_Elem_C3D15_FormBodyForce, PH_Elem_C3D15_FormFacePressure, &
    PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_NNODE       = 15_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_NIP         = 9_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_NDOF_MECH   = 45_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_NDOF_THERM  = 15_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_NDOF_TOTAL  = 60_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_LOAD_BODY         = PH_ELEM_LOAD_BODY
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_LOAD_FACE_P      = PH_ELEM_LOAD_FACE_P
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_LOAD_GRAV        = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_LOAD_HEAT_SOURCE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D15T_LOAD_THERMAL_FLUX = 5_i4

  TYPE :: PH_ELEM_C3D15T_OutputData
    REAL(wp) :: nodal_displacements(45)
    REAL(wp) :: nodal_temperatures(15)
    REAL(wp) :: nodal_stresses(6, 15)
    REAL(wp) :: nodal_strains(6, 15)
    REAL(wp) :: von_mises_stress(15)
    REAL(wp) :: thermal_stress(6, 15)
    REAL(wp) :: total_stress(6, 15)
    REAL(wp) :: heat_flux(3, 15)
    REAL(wp) :: element_energy(3)
  END TYPE PH_ELEM_C3D15T_OutputData

  PUBLIC :: PH_Elem_C3D15T_DefInit, PH_Elem_C3D15T_ThermStrain3D
  PUBLIC :: PH_Elem_C3D15T_FormStiffMatrix, PH_Elem_C3D15T_FormStiffMatrix_MatAware
  PUBLIC :: PH_Elem_C3D15T_FormThermalStiffness, PH_Elem_C3D15T_FormCouplingStiffness
  PUBLIC :: PH_Elem_C3D15T_FormIntForce, PH_Elem_C3D15T_FormIntForce_MatAware
  PUBLIC :: PH_Elem_C3D15T_ConsMass, PH_Elem_C3D15T_LumpMass
  PUBLIC :: PH_Elem_C3D15T_ShapeFunc, PH_Elem_C3D15T_Jac, PH_Elem_C3D15T_GaussPoints, PH_Elem_C3D15T_JacB
  PUBLIC :: PH_ELEM_C3D15T_NNODE, PH_ELEM_C3D15T_NIP, PH_ELEM_C3D15T_NDOF_MECH, PH_ELEM_C3D15T_NDOF_THERM, PH_ELEM_C3D15T_NDOF_TOTAL
  PUBLIC :: PH_Elem_C3D15T_GetVolume, PH_Elem_C3D15T_GetSectProps, PH_Elem_C3D15T_GetCentroid
  PUBLIC :: PH_Elem_C3D15T_FormMechBodyForce, PH_Elem_C3D15T_FormMechFacePressure
  PUBLIC :: PH_Elem_C3D15T_FormThermalBodySource, PH_Elem_C3D15T_FormThermalFaceFlux
  PUBLIC :: PH_Elem_C3D15T_FormNodalForce
  PUBLIC :: PH_ELEM_C3D15T_LOAD_BODY, PH_ELEM_C3D15T_LOAD_FACE_P, PH_ELEM_C3D15T_LOAD_GRAV
  PUBLIC :: PH_ELEM_C3D15T_LOAD_HEAT_SOURCE, PH_ELEM_C3D15T_LOAD_THERMAL_FLUX
  PUBLIC :: PH_ELEM_C3D15T_OutputData
  PUBLIC :: PH_Elem_C3D15T_Material_Update_Thermo_Routed

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

  SUBROUTINE PH_Elem_C3D15T_ThermStrain3D(T, T_ref, alpha, strain_th)
    REAL(wp), INTENT(IN)  :: T(:)
    REAL(wp), INTENT(IN)  :: T_ref, alpha
    REAL(wp), INTENT(OUT) :: strain_th(6)
    REAL(wp) :: dT_avg
    INTEGER(i4) :: nNode
    nNode = SIZE(T)
    dT_avg = SUM(T) / REAL(nNode, wp) - T_ref
    strain_th(1:3) = alpha * dT_avg
    strain_th(4:6) = ZERO
  END SUBROUTINE PH_Elem_C3D15T_ThermStrain3D

  SUBROUTINE PH_Elem_C3D15T_FormStiffMatrix_MatAware(coords, mat_prop, mat_state, &
                                                     alpha, k_thermal, T_elem, T_ref, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: alpha, k_thermal, T_ref
    REAL(wp), INTENT(IN)  :: T_elem(15)
    REAL(wp), INTENT(OUT) :: Ke(60, 60)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdx(3, 15), J(3, 3), detJ, B(6, 45)
    REAL(wp) :: dV, D_tangent(6, 6), strain_thermal(6)
    REAL(wp) :: Ke_uu(45, 45), Ke_tt(15, 15), Ke_ut(45, 15)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: ip, i, j

    Ke = ZERO
    Ke_uu = ZERO
    CALL PH_Elem_C3D15T_ThermStrain3D(T_elem, T_ref, alpha, strain_thermal)
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
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
    Ke(1:45, 1:45) = Ke_uu
    CALL PH_Elem_C3D15T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    Ke(46:60, 46:60) = Ke_tt
    CALL PH_Elem_C3D15T_FormCouplingStiffness(coords, D_tangent, alpha, Ke_ut)
    Ke(1:45, 46:60) = Ke_ut
    DO j = 1, 15
      DO i = 1, 45
        Ke(45 + j, i) = Ke_ut(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D15T_FormStiffMatrix_MatAware

  SUBROUTINE PH_Elem_C3D15T_FormCouplingStiffness(coords, D_tangent, alpha, Ke_ut)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: D_tangent(6, 6)
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(OUT) :: Ke_ut(45, 15)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdx(3, 15), J(3, 3), detJ, B(6, 45)
    REAL(wp) :: beta, dV, B_vol(45)
    INTEGER(i4) :: ip, i
    Ke_ut = ZERO
    IF (ABS(alpha) <= 1.0e-12_wp) RETURN
    beta = D_tangent(1,1) + D_tangent(1,2) + D_tangent(1,3)
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = alpha * beta * detJ * weights(ip)
      B_vol(1:45) = B(1, 1:45) + B(2, 1:45) + B(3, 1:45)
      DO i = 1, 15
        Ke_ut(1:45, i) = Ke_ut(1:45, i) + dV * B_vol(1:45) * N(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D15T_FormCouplingStiffness

  SUBROUTINE PH_Elem_C3D15T_FormStiffMatrix(coords, E_young, nu, alpha, k_thermal, T_ref, Ke)
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha, k_thermal, T_ref
    REAL(wp), INTENT(OUT) :: Ke(60, 60)
    TYPE(MatPropertyDef) :: mat_prop_dummy
    TYPE(PH_MatPoint_State) :: mat_state_dummy(9)
    REAL(wp) :: T_elem(15)
    INTEGER(i4) :: i
    mat_prop_dummy%mat_id = 1
    mat_prop_dummy%num_props = 2
    ALLOCATE(mat_prop_dummy%props(2))
    mat_prop_dummy%props(1) = E_young
    mat_prop_dummy%props(2) = nu
    mat_prop_dummy%num_state_vars = 0
    DO i = 1, 9
      mat_state_dummy(i)%mat_id = 1
      mat_state_dummy(i)%nStatev = 0
      mat_state_dummy(i)%is_initialized = .TRUE.
    END DO
    T_elem = T_ref
    CALL PH_Elem_C3D15T_FormStiffMatrix_MatAware(coords, mat_prop_dummy, mat_state_dummy, &
                                                   alpha, k_thermal, T_elem, T_ref, Ke)
    DEALLOCATE(mat_prop_dummy%props)
  END SUBROUTINE PH_Elem_C3D15T_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D15T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: k_thermal
    REAL(wp), INTENT(OUT) :: Ke_tt(15, 15)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdx(3, 15), J(3, 3), detJ, B_dum(6, 45)
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    Ke_tt = ZERO
    IF (k_thermal <= 1.0e-12_wp) RETURN
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B_dum)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = k_thermal * detJ * weights(ip)
      Ke_tt(1:15, 1:15) = Ke_tt(1:15, 1:15) + dV * MATMUL(TRANSPOSE(dNdx), dNdx)
    END DO
  END SUBROUTINE PH_Elem_C3D15T_FormThermalStiffness

  SUBROUTINE PH_Elem_C3D15T_FormIntForce_MatAware(coords, u, mat_prop, mat_state, &
                                                  alpha, k_thermal, T_elem, T_ref, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: u(60)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: alpha, k_thermal, T_ref
    REAL(wp), INTENT(IN)  :: T_elem(15)
    REAL(wp), INTENT(OUT) :: R_int(60)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdx(3, 15), J(3, 3), detJ, B(6, 45)
    REAL(wp) :: dV, strain_mech(6), strain_thermal(6), strain_total(6)
    REAL(wp) :: sigma(6), grad_T(3), q_thermal(3)
    REAL(wp) :: Ke_ut(45, 15), D_tangent(6, 6)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: ip, i

    R_int = ZERO
    CALL PH_Elem_C3D15T_ThermStrain3D(T_elem, T_ref, alpha, strain_thermal)
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      strain_mech = MATMUL(B, u(1:45))
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
      R_int(1:45) = R_int(1:45) + MATMUL(TRANSPOSE(B), sigma) * dV
    END DO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      grad_T(1) = DOT_PRODUCT(dNdx(1, :), T_elem)
      grad_T(2) = DOT_PRODUCT(dNdx(2, :), T_elem)
      grad_T(3) = DOT_PRODUCT(dNdx(3, :), T_elem)
      q_thermal = -k_thermal * grad_T
      dV = detJ * weights(ip)
      DO i = 1, 15
        R_int(45 + i) = R_int(45 + i) + (dNdx(1, i)*q_thermal(1) + dNdx(2, i)*q_thermal(2) + dNdx(3, i)*q_thermal(3)) * dV
      END DO
    END DO
    CALL PH_Elem_C3D15T_FormCouplingStiffness(coords, D_tangent, alpha, Ke_ut)
    R_int(1:45) = R_int(1:45) + MATMUL(Ke_ut, T_elem)
  END SUBROUTINE PH_Elem_C3D15T_FormIntForce_MatAware

  SUBROUTINE PH_Elem_C3D15T_FormIntForce(coords, u, E_young, nu, alpha, k_thermal, T_ref, R_int)
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: u(60)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha, k_thermal, T_ref
    REAL(wp), INTENT(OUT) :: R_int(60)
    TYPE(MatPropertyDef) :: mat_prop_dummy
    TYPE(PH_MatPoint_State) :: mat_state_dummy(9)
    REAL(wp) :: T_elem(15)
    INTEGER(i4) :: i
    mat_prop_dummy%mat_id = 1
    mat_prop_dummy%num_props = 2
    ALLOCATE(mat_prop_dummy%props(2))
    mat_prop_dummy%props(1) = E_young
    mat_prop_dummy%props(2) = nu
    mat_prop_dummy%num_state_vars = 0
    DO i = 1, 9
      mat_state_dummy(i)%mat_id = 1
      mat_state_dummy(i)%nStatev = 0
      mat_state_dummy(i)%is_initialized = .TRUE.
    END DO
    T_elem = u(46:60)
    CALL PH_Elem_C3D15T_FormIntForce_MatAware(coords, u, mat_prop_dummy, mat_state_dummy, &
                                                alpha, k_thermal, T_elem, T_ref, R_int)
    DEALLOCATE(mat_prop_dummy%props)
  END SUBROUTINE PH_Elem_C3D15T_FormIntForce

  SUBROUTINE PH_Elem_C3D15T_DefInit()
  END SUBROUTINE PH_Elem_C3D15T_DefInit

  SUBROUTINE PH_Elem_C3D15T_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(60, 60)
    Me = ZERO
    CALL PH_Elem_C3D15_ConsMass(coords, rho, Me(1:45, 1:45))
  END SUBROUTINE PH_Elem_C3D15T_ConsMass

  SUBROUTINE PH_Elem_C3D15T_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(60)
    M_lumped = ZERO
    CALL PH_Elem_C3D15_LumpMass(coords, rho, M_lumped(1:45))
  END SUBROUTINE PH_Elem_C3D15T_LumpMass

  SUBROUTINE PH_Elem_C3D15T_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(15), dNdxi(3, 15)
    CALL PH_Elem_C3D15_ShapeFunc(xi, eta, zeta, N, dNdxi)
  END SUBROUTINE PH_Elem_C3D15T_ShapeFunc

  SUBROUTINE PH_Elem_C3D15T_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 15), coords(3, 15)
    REAL(wp), INTENT(OUT) :: J(3, 3), detJ
    CALL PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
  END SUBROUTINE PH_Elem_C3D15T_Jac

  SUBROUTINE PH_Elem_C3D15T_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(9), eta(9), zeta(9), weights(9)
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
  END SUBROUTINE PH_Elem_C3D15T_GaussPoints

  SUBROUTINE PH_Elem_C3D15T_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(15), dNdx(3, 15), J(3, 3), detJ, B(6, 45)
    CALL PH_Elem_C3D15_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
  END SUBROUTINE PH_Elem_C3D15T_JacB

  SUBROUTINE PH_Elem_C3D15T_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D15T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15T_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D15T_GetVolume

  SUBROUTINE PH_Elem_C3D15T_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume, mass
    CALL PH_Elem_C3D15T_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D15T_GetSectProps

  SUBROUTINE PH_Elem_C3D15T_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: vol, dV
    INTEGER(i4) :: ip, i, j
    vol = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D15T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15T_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      vol = vol + dV
      DO i = 1, 3
        DO j = 1, 15
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (vol > 1.0e-20_wp) centroid = centroid / vol
  END SUBROUTINE PH_Elem_C3D15T_GetCentroid

  SUBROUTINE PH_Elem_C3D15T_FormMechBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(60)
    F_eq = ZERO
    CALL PH_Elem_C3D15_FormBodyForce(coords, bx, by, bz, F_eq(1:45))
  END SUBROUTINE PH_Elem_C3D15T_FormMechBodyForce

  SUBROUTINE PH_Elem_C3D15T_FormMechFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(60)
    F_eq = ZERO
    CALL PH_Elem_C3D15_FormFacePressure(coords, p, face_id, F_eq(1:45))
  END SUBROUTINE PH_Elem_C3D15T_FormMechFacePressure

  SUBROUTINE PH_Elem_C3D15T_FormThermalBodySource(coords, Q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: Q
    REAL(wp), INTENT(OUT) :: F_therm(15)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_therm = ZERO
    CALL PH_Elem_C3D15T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15T_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 15
        F_therm(i) = F_therm(i) + N(i) * Q * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D15T_FormThermalBodySource

  SUBROUTINE PH_Elem_C3D15T_FormThermalFaceFlux(coords, face_id, q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: q
    REAL(wp), INTENT(OUT) :: F_therm(15)
    REAL(wp) :: n(3), area
    INTEGER(i4) :: nodes(4), i, j, nnode_face
    F_therm = ZERO
    IF (face_id < 1 .OR. face_id > 5) RETURN
    nodes(1:4) = PH_ELEM_C3D15_FACE_NODES(1:4, face_id)
    nnode_face = 3
    IF (nodes(4) /= 0) nnode_face = 4
    IF (nnode_face == 3) THEN
      n(1) = (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(3,nodes(3))-coords(3,nodes(1))) - (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(2,nodes(3))-coords(2,nodes(1)))
      n(2) = (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(1,nodes(3))-coords(1,nodes(1))) - (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(3,nodes(3))-coords(3,nodes(1)))
      n(3) = (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(2,nodes(3))-coords(2,nodes(1))) - (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(1,nodes(3))-coords(1,nodes(1)))
      area = 0.5_wp * SQRT(n(1)*n(1) + n(2)*n(2) + n(3)*n(3))
      IF (area < 1.0e-15_wp) RETURN
      DO j = 1, 3
        F_therm(nodes(j)) = F_therm(nodes(j)) + (q * area / 3.0_wp)
      END DO
    ELSE
      n(1) = (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(3,nodes(4))-coords(3,nodes(1))) - (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(2,nodes(4))-coords(2,nodes(1)))
      n(2) = (coords(3,nodes(2))-coords(3,nodes(1)))*(coords(1,nodes(4))-coords(1,nodes(1))) - (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(3,nodes(4))-coords(3,nodes(1)))
      n(3) = (coords(1,nodes(2))-coords(1,nodes(1)))*(coords(2,nodes(4))-coords(2,nodes(1))) - (coords(2,nodes(2))-coords(2,nodes(1)))*(coords(1,nodes(4))-coords(1,nodes(1)))
      area = 0.5_wp * SQRT(n(1)*n(1) + n(2)*n(2) + n(3)*n(3))
      IF (area < 1.0e-15_wp) RETURN
      DO j = 1, 4
        F_therm(nodes(j)) = F_therm(nodes(j)) + (q * area / 4.0_wp)
      END DO
    END IF
  END SUBROUTINE PH_Elem_C3D15T_FormThermalFaceFlux

  SUBROUTINE PH_Elem_C3D15T_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(60)
    REAL(wp) :: F_mech(45), F_therm(15)
    F_eq = ZERO
    F_mech = ZERO
    F_therm = ZERO
    IF (load_type == PH_ELEM_C3D15T_LOAD_BODY) THEN
      CALL PH_Elem_C3D15_FormBodyForce(coords, val(1), val(2), val(3), F_mech)
    ELSE IF (load_type == PH_ELEM_C3D15T_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D15_FormFacePressure(coords, val(1), face_id, F_mech)
    ELSE IF (load_type == PH_ELEM_C3D15T_LOAD_GRAV .AND. SIZE(val) >= 5) THEN
      CALL PH_Elem_C3D15_FormBodyForce(coords, val(1)*val(2)*val(5), val(1)*val(3)*val(5), val(1)*val(4)*val(5), F_mech)
    ELSE IF (load_type == PH_ELEM_C3D15T_LOAD_HEAT_SOURCE .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D15T_FormThermalBodySource(coords, val(1), F_therm)
    ELSE IF (load_type == PH_ELEM_C3D15T_LOAD_THERMAL_FLUX .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D15T_FormThermalFaceFlux(coords, face_id, val(1), F_therm)
    END IF
    F_eq(1:45) = F_mech
    F_eq(46:60) = F_therm
  END SUBROUTINE PH_Elem_C3D15T_FormNodalForce

  SUBROUTINE PH_Elem_C3D15T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, &
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
  END SUBROUTINE PH_Elem_C3D15T_Material_Update_Thermo_Routed

END MODULE PH_Elem_C3D15T


