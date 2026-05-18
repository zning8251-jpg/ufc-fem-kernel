!===============================================================================
! MODULE: PH_Elem_CPS8T
! LAYER:  L4_PH
! DOMAIN: Element/Solid2Dt
! ROLE:   Proc
! BRIEF:  CPS8T unified interface (merged Defn + Sect + Constraints + Cont + Loads + Out)
!===============================================================================
MODULE PH_Elem_CPS8T
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_Elem_CPS8, ONLY: &
    PH_Elem_CPS8_ShapeFunc, PH_Elem_CPS8_Jac, PH_Elem_CPS8_JacB, &
    PH_Elem_CPS8_GaussPoints, PH_Elem_CPS8_ConstMatrix, &
    PH_Elem_CPS8_FormBodyForce, PH_Elem_CPS8_FormEdgePressure, &
    PH_Elem_CPS8_GetArea, PH_Elem_CPS8_GetCentroid, &
    PH_Elem_CPS8_ConsMass, PH_Elem_CPS8_LumpMass, &
    PH_ELEM_CPS8_EDGE_NODES, PH_ELEM_CPS8_FACE_NODES
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_CPS8T_NNODE       = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS8T_NIP        = 9_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS8T_NDOF_MECH  = 16_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS8T_NDOF_THERM = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS8T_NDOF_TOTAL = 24_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS8T_EDGE_NODES(2, 4) = RESHAPE([ 1,2, 2,3, 3,4, 4,1 ], [2, 4])
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS8T_LOAD_BODY = 1_i4, PH_ELEM_CPS8T_LOAD_EDGE_P = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS8T_LOAD_HEAT_SOURCE = 3_i4, PH_ELEM_CPS8T_LOAD_THERMAL_FLUX = 4_i4

  PUBLIC :: PH_Elem_CPS8T_DefInit, PH_Elem_CPS8T_ThermStrain2D
  PUBLIC :: PH_Elem_CPS8T_FormStiffMatrix, PH_Elem_CPS8T_FormThermalStiffness
  PUBLIC :: PH_Elem_CPS8T_FormCouplingStiffness, PH_Elem_CPS8T_FormIntForce
  PUBLIC :: PH_Elem_CPS8T_ConsMass, PH_Elem_CPS8T_LumpMass
  PUBLIC :: PH_Elem_CPS8T_ShapeFunc, PH_Elem_CPS8T_Jac, PH_Elem_CPS8T_GaussPoints, PH_Elem_CPS8T_JacB
  PUBLIC :: PH_ELEM_CPS8T_NNODE, PH_ELEM_CPS8T_NIP, PH_ELEM_CPS8T_NDOF_MECH, PH_ELEM_CPS8T_NDOF_THERM, PH_ELEM_CPS8T_NDOF_TOTAL
  PUBLIC :: PH_Elem_CPS8T_GetArea, PH_Elem_CPS8T_GetCentroid, PH_Elem_CPS8T_GetSectProps
  PUBLIC :: PH_Elem_CPS8T_FormMechBodyForce, PH_Elem_CPS8T_FormMechEdgePressure
  PUBLIC :: PH_Elem_CPS8T_FormThermalBodySource, PH_Elem_CPS8T_FormThermalEdgeFlux
  PUBLIC :: PH_Elem_CPS8T_FormNodalForce
  PUBLIC :: PH_Elem_CPS8T_Material_Update_Thermo_Routed
  PUBLIC :: PH_ELEM_CPS8T_LOAD_BODY, PH_ELEM_CPS8T_LOAD_EDGE_P, PH_ELEM_CPS8T_LOAD_HEAT_SOURCE, PH_ELEM_CPS8T_LOAD_THERMAL_FLUX

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Sld2DT_Args
  TYPE :: PH_Elem_Sld2DT_Args
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
  END TYPE PH_Elem_Sld2DT_Args


CONTAINS

  SUBROUTINE PH_Elem_CPS8T_ThermStrain2D(T, T_ref, alpha, strain_th)
    REAL(wp), INTENT(IN)  :: T(:)
    REAL(wp), INTENT(IN)  :: T_ref
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(OUT) :: strain_th(3)
    REAL(wp) :: dT_avg
    dT_avg = SUM(T) / REAL(SIZE(T), wp) - T_ref
    strain_th(1:2) = alpha * dT_avg
    strain_th(3) = ZERO
  END SUBROUTINE PH_Elem_CPS8T_ThermStrain2D

  SUBROUTINE PH_Elem_CPS8T_FormStiffMatrix(coords, E_young, nu, alpha, k_thermal, T_ref, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha, k_thermal, T_ref
    REAL(wp), INTENT(OUT) :: Ke(24, 24)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), detJ, B(3, 16)
    REAL(wp) :: D(3, 3), dA
    REAL(wp) :: Ke_uu(16, 16), Ke_tt(8, 8), Ke_ut(16, 8)
    INTEGER(i4) :: ip, i, j

    Ke = ZERO
    Ke_uu = ZERO
    Ke_tt = ZERO
    Ke_ut = ZERO
    CALL PH_Elem_CPS8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPS8_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dA = detJ * weights(ip)
      Ke_uu = Ke_uu + MATMUL(TRANSPOSE(B), MATMUL(D, B)) * dA
    END DO
    CALL PH_Elem_CPS8T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    CALL PH_Elem_CPS8T_FormCouplingStiffness(coords, E_young, nu, alpha, Ke_ut)
    Ke(1:16, 1:16) = Ke_uu
    Ke(17:24, 17:24) = Ke_tt
    Ke(1:16, 17:24) = Ke_ut
    DO j = 1, 8
      DO i = 1, 16
        Ke(16 + j, i) = Ke_ut(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS8T_FormStiffMatrix

  SUBROUTINE PH_Elem_CPS8T_FormCouplingStiffness(coords, E_young, nu, alpha, Ke_ut)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha
    REAL(wp), INTENT(OUT) :: Ke_ut(16, 8)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), detJ, B(3, 16), D(3, 3)
    REAL(wp) :: beta, dA, B_vol(16)
    INTEGER(i4) :: ip, i

    Ke_ut = ZERO
    IF (ABS(alpha) <= 1.0e-12_wp) RETURN
    CALL PH_Elem_CPS8_ConstMatrix(E_young, nu, D)
    beta = D(1, 1) + D(1, 2)
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPS8_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dA = alpha * beta * detJ * weights(ip)
      B_vol(1:16) = B(1, 1:16) + B(2, 1:16)
      DO i = 1, 8
        Ke_ut(1:16, i) = Ke_ut(1:16, i) + dA * B_vol(1:16) * N(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS8T_FormCouplingStiffness

  SUBROUTINE PH_Elem_CPS8T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: k_thermal
    REAL(wp), INTENT(OUT) :: Ke_tt(8, 8)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), detJ, B_dum(3, 16)
    INTEGER(i4) :: ip

    Ke_tt = ZERO
    IF (k_thermal <= 1.0e-12_wp) RETURN
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPS8_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B_dum)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      Ke_tt = Ke_tt + k_thermal * detJ * weights(ip) * MATMUL(TRANSPOSE(dNdx), dNdx)
    END DO
  END SUBROUTINE PH_Elem_CPS8T_FormThermalStiffness

  SUBROUTINE PH_Elem_CPS8T_FormIntForce(coords, u, E_young, nu, alpha, k_thermal, T_ref, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha, k_thermal, T_ref
    REAL(wp), INTENT(OUT) :: R_int(24)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdx(2, 8), J(2, 2), detJ, B(3, 16)
    REAL(wp) :: dA, strain_mech(3), strain_thermal(3), strain_total(3)
    REAL(wp) :: sigma(3), grad_T(2), q_thermal(2)
    REAL(wp) :: T_elem(8), D(3, 3)
    INTEGER(i4) :: ip, i

    R_int = ZERO
    T_elem = u(17:24)
    CALL PH_Elem_CPS8T_ThermStrain2D(T_elem, T_ref, alpha, strain_thermal)
    CALL PH_Elem_CPS8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPS8_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      strain_mech = MATMUL(B, u(1:16))
      strain_total = strain_mech + strain_thermal
      sigma = MATMUL(D, strain_total)
      dA = detJ * weights(ip)
      R_int(1:16) = R_int(1:16) + MATMUL(TRANSPOSE(B), sigma) * dA
    END DO
    DO ip = 1, 9
      CALL PH_Elem_CPS8_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      grad_T(1) = DOT_PRODUCT(dNdx(1, :), T_elem)
      grad_T(2) = DOT_PRODUCT(dNdx(2, :), T_elem)
      q_thermal = -k_thermal * grad_T
      dA = detJ * weights(ip)
      DO i = 1, 8
        R_int(16 + i) = R_int(16 + i) + (dNdx(1, i) * q_thermal(1) + dNdx(2, i) * q_thermal(2)) * dA
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS8T_FormIntForce

  SUBROUTINE PH_Elem_CPS8T_DefInit()
  END SUBROUTINE PH_Elem_CPS8T_DefInit

  SUBROUTINE PH_Elem_CPS8T_GaussPoints(xi, eta, weights)
    REAL(wp), INTENT(OUT) :: xi(9), eta(9), weights(9)
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
  END SUBROUTINE PH_Elem_CPS8T_GaussPoints

  SUBROUTINE PH_Elem_CPS8T_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 8), coords(2, 8)
    REAL(wp), INTENT(OUT) :: J(2, 2), detJ
    CALL PH_Elem_CPS8_Jac(dNdxi, coords, J, detJ)
  END SUBROUTINE PH_Elem_CPS8T_Jac

  SUBROUTINE PH_Elem_CPS8T_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt
    REAL(wp), INTENT(OUT) :: N(8), dNdx(2, 8), J(2, 2), detJ, B(3, 16)
    CALL PH_Elem_CPS8_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)
  END SUBROUTINE PH_Elem_CPS8T_JacB

  SUBROUTINE PH_Elem_CPS8T_ShapeFunc(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(8), dNdxi(2, 8)
    CALL PH_Elem_CPS8_ShapeFunc(xi, eta, N, dNdxi)
  END SUBROUTINE PH_Elem_CPS8T_ShapeFunc

  SUBROUTINE PH_Elem_CPS8T_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(24, 24)
    Me = ZERO
    CALL PH_Elem_CPS8_ConsMass(coords, rho, Me(1:16, 1:16))
  END SUBROUTINE PH_Elem_CPS8T_ConsMass

  SUBROUTINE PH_Elem_CPS8T_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(24)
    M_lumped = ZERO
    CALL PH_Elem_CPS8_LumpMass(coords, rho, M_lumped(1:16))
  END SUBROUTINE PH_Elem_CPS8T_LumpMass

  SUBROUTINE PH_Elem_CPS8T_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_Elem_CPS8_GetArea(coords, area)
  END SUBROUTINE PH_Elem_CPS8T_GetArea

  SUBROUTINE PH_Elem_CPS8T_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: centroid(2)
    CALL PH_Elem_CPS8_GetCentroid(coords, centroid)
  END SUBROUTINE PH_Elem_CPS8T_GetCentroid

  SUBROUTINE PH_Elem_CPS8T_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_CPS8T_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_CPS8T_GetSectProps

  SUBROUTINE PH_Elem_CPS8T_FormMechBodyForce(coords, bx, by, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: bx, by
    REAL(wp), INTENT(OUT) :: F_eq(24)
    F_eq = ZERO
    CALL PH_Elem_CPS8_FormBodyForce(coords, bx, by, F_eq(1:16))
  END SUBROUTINE PH_Elem_CPS8T_FormMechBodyForce

  SUBROUTINE PH_Elem_CPS8T_FormMechEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(24)
    F_eq = ZERO
    CALL PH_Elem_CPS8_FormEdgePressure(coords, p, edge_id, F_eq(1:16))
  END SUBROUTINE PH_Elem_CPS8T_FormMechEdgePressure

  SUBROUTINE PH_Elem_CPS8T_FormThermalBodySource(coords, Q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: Q
    REAL(wp), INTENT(OUT) :: F_therm(8)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    INTEGER(i4) :: ip, i

    F_therm = ZERO
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      CALL PH_Elem_CPS8_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CPS8_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 8
        F_therm(i) = F_therm(i) + N(i) * Q * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CPS8T_FormThermalBodySource

  SUBROUTINE PH_Elem_CPS8T_FormThermalEdgeFlux(coords, edge_id, q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: q
    REAL(wp), INTENT(OUT) :: F_therm(8)
    REAL(wp) :: t(2), len
    INTEGER(i4) :: n1, n2

    F_therm = ZERO
    IF (edge_id < 1 .OR. edge_id > 4) RETURN
    n1 = PH_ELEM_CPS8T_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CPS8T_EDGE_NODES(2, edge_id)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    F_therm(n1) = F_therm(n1) + q * len * HALF
    F_therm(n2) = F_therm(n2) + q * len * HALF
  END SUBROUTINE PH_Elem_CPS8T_FormThermalEdgeFlux

  SUBROUTINE PH_Elem_CPS8T_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(24)
    F_eq = ZERO
    IF (load_type == PH_ELEM_CPS8T_LOAD_BODY) THEN
      CALL PH_Elem_CPS8_FormBodyForce(coords, val(1), val(2), F_eq(1:16))
    ELSE IF (load_type == PH_ELEM_CPS8T_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CPS8_FormEdgePressure(coords, val(1), edge_id, F_eq(1:16))
    ELSE IF (load_type == PH_ELEM_CPS8T_LOAD_HEAT_SOURCE .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CPS8T_FormThermalBodySource(coords, val(1), F_eq(17:24))
    ELSE IF (load_type == PH_ELEM_CPS8T_LOAD_THERMAL_FLUX .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CPS8T_FormThermalEdgeFlux(coords, edge_id, val(1), F_eq(17:24))
    END IF
  END SUBROUTINE PH_Elem_CPS8T_FormNodalForce

  SUBROUTINE PH_Elem_CPS8T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, &
                                                         dStrain_total, thermal_strain, &
                                                         stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ThermoElasticPlaneStress

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dStrain_total(3)
    REAL(wp),                  INTENT(IN)    :: thermal_strain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ThermoElasticPlaneStress(rt_ctx, mat_slot, dStrain_total, &
                                                   thermal_strain, stress_old, stress_new, &
                                                   D_tangent, status)
  END SUBROUTINE PH_Elem_CPS8T_Material_Update_Thermo_Routed

END MODULE PH_Elem_CPS8T


