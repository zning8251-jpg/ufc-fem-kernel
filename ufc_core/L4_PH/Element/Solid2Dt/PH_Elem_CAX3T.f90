!===============================================================================
! MODULE: PH_Elem_CAX3T
! LAYER:  L4_PH
! DOMAIN: Element/Solid2Dt
! ROLE:   Proc
! BRIEF:  CAX3T unified interface (merged Defn + Sect + Constraints + Cont + Loads + Out)
!===============================================================================
MODULE PH_Elem_CAX3T
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_Elem_CAX3, ONLY: &
    PH_Elem_CAX3_ShapeFunc, PH_Elem_CAX3_Jac, PH_Elem_CAX3_JacB, &
    PH_Elem_CAX3_GaussPoints, PH_Elem_CAX3_ConstMatrix, PH_Elem_CAX3_ThermStrainVector, &
    PH_Elem_CAX3_FormBodyForce, PH_Elem_CAX3_FormEdgePressure, &
    PH_ELEM_CAX3_EDGE_NODES, PH_ELEM_CAX3_FACE_NODES, PH_ELEM_GAUSS_PT
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3T_NNODE       = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3T_NIP        = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3T_NDOF_MECH  = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3T_NDOF_THERM = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3T_NDOF_TOTAL = 9_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3T_EDGE_NODES(2, 3) = RESHAPE([ 1,2, 2,3, 3,1 ], [2, 3])
  REAL(wp), PARAMETER :: TWOPI = 6.283185307179586_wp
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3T_LOAD_BODY = 1_i4, PH_ELEM_CAX3T_LOAD_EDGE_P = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CAX3T_LOAD_HEAT_SOURCE = 3_i4, PH_ELEM_CAX3T_LOAD_THERMAL_FLUX = 4_i4

  PUBLIC :: PH_Elem_CAX3T_DefInit, PH_Elem_CAX3T_ThermStrainAxisym
  PUBLIC :: PH_Elem_CAX3T_FormStiffMatrix, PH_Elem_CAX3T_FormThermalStiffness
  PUBLIC :: PH_Elem_CAX3T_FormCouplingStiffness, PH_Elem_CAX3T_FormIntForce
  PUBLIC :: PH_Elem_CAX3T_ConsMass, PH_Elem_CAX3T_LumpMass
  PUBLIC :: PH_Elem_CAX3T_ShapeFunc, PH_Elem_CAX3T_Jac, PH_Elem_CAX3T_GaussPoints, PH_Elem_CAX3T_JacB
  PUBLIC :: PH_ELEM_CAX3T_NNODE, PH_ELEM_CAX3T_NIP, PH_ELEM_CAX3T_NDOF_MECH, PH_ELEM_CAX3T_NDOF_THERM, PH_ELEM_CAX3T_NDOF_TOTAL
  PUBLIC :: PH_Elem_CAX3T_GetArea, PH_Elem_CAX3T_GetVolume, PH_Elem_CAX3T_GetCentroid, PH_Elem_CAX3T_GetSectProps
  PUBLIC :: PH_Elem_CAX3T_FormMechBodyForce, PH_Elem_CAX3T_FormMechEdgePressure
  PUBLIC :: PH_Elem_CAX3T_FormThermalBodySource, PH_Elem_CAX3T_FormThermalEdgeFlux
  PUBLIC :: PH_Elem_CAX3T_FormNodalForce
  PUBLIC :: PH_Elem_CAX3T_Material_Update_Thermo_Routed
  PUBLIC :: PH_ELEM_CAX3T_LOAD_BODY, PH_ELEM_CAX3T_LOAD_EDGE_P, PH_ELEM_CAX3T_LOAD_HEAT_SOURCE, PH_ELEM_CAX3T_LOAD_THERMAL_FLUX

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

  SUBROUTINE PH_Elem_CAX3T_ThermStrainAxisym(T, T_ref, alpha, strain_th)
    REAL(wp), INTENT(IN)  :: T(:)
    REAL(wp), INTENT(IN)  :: T_ref
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(OUT) :: strain_th(4)
    REAL(wp) :: dT_avg
    dT_avg = SUM(T) / REAL(SIZE(T), wp) - T_ref
    strain_th(1:3) = alpha * dT_avg
    strain_th(4) = ZERO
  END SUBROUTINE PH_Elem_CAX3T_ThermStrainAxisym

  SUBROUTINE PH_Elem_CAX3T_FormStiffMatrix(coords, E_young, nu, alpha, k_thermal, T_ref, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha, k_thermal, T_ref
    REAL(wp), INTENT(OUT) :: Ke(9, 9)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), detJ, r_pt, B(4, 6)
    REAL(wp) :: D(4, 4), dV
    REAL(wp) :: Ke_uu(6, 6), Ke_tt(3, 3), Ke_ut(6, 3)
    INTEGER(i4) :: ip, i, j

    Ke = ZERO
    Ke_uu = ZERO
    Ke_tt = ZERO
    Ke_ut = ZERO
    CALL PH_Elem_CAX3_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      dV = TWOPI * r_pt * detJ * weights(ip)
      Ke_uu = Ke_uu + MATMUL(TRANSPOSE(B), MATMUL(D, B)) * dV
    END DO
    CALL PH_Elem_CAX3T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    CALL PH_Elem_CAX3T_FormCouplingStiffness(coords, E_young, nu, alpha, Ke_ut)
    Ke(1:6, 1:6) = Ke_uu
    Ke(7:9, 7:9) = Ke_tt
    Ke(1:6, 7:9) = Ke_ut
    DO j = 1, 3
      DO i = 1, 6
        Ke(6 + j, i) = Ke_ut(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX3T_FormStiffMatrix

  SUBROUTINE PH_Elem_CAX3T_FormCouplingStiffness(coords, E_young, nu, alpha, Ke_ut)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha
    REAL(wp), INTENT(OUT) :: Ke_ut(6, 3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), detJ, r_pt, B(4, 6), D(4, 4)
    REAL(wp) :: coeff(4), dV
    INTEGER(i4) :: ip, i, j

    Ke_ut = ZERO
    IF (ABS(alpha) <= 1.0e-12_wp) RETURN
    CALL PH_Elem_CAX3_ConstMatrix(E_young, nu, D)
    coeff(1) = D(1, 1) + D(1, 2) + D(1, 3)
    coeff(2) = D(2, 1) + D(2, 2) + D(2, 3)
    coeff(3) = D(3, 1) + D(3, 2) + D(3, 3)
    coeff(4) = ZERO
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      dV = alpha * detJ * weights(ip) * TWOPI * r_pt
      DO j = 1, 3
        DO i = 1, 6
          Ke_ut(i, j) = Ke_ut(i, j) + dV * DOT_PRODUCT(B(:, i), coeff) * N(j)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX3T_FormCouplingStiffness

  SUBROUTINE PH_Elem_CAX3T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: k_thermal
    REAL(wp), INTENT(OUT) :: Ke_tt(3, 3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), detJ, r_pt, B_dum(4, 6)
    INTEGER(i4) :: ip

    Ke_tt = ZERO
    IF (k_thermal <= 1.0e-12_wp) RETURN
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B_dum)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      Ke_tt = Ke_tt + k_thermal * TWOPI * r_pt * detJ * weights(ip) * MATMUL(TRANSPOSE(dNdx), dNdx)
    END DO
  END SUBROUTINE PH_Elem_CAX3T_FormThermalStiffness

  SUBROUTINE PH_Elem_CAX3T_FormIntForce(coords, u, E_young, nu, alpha, k_thermal, T_ref, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: u(9)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha, k_thermal, T_ref
    REAL(wp), INTENT(OUT) :: R_int(9)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdx(2, 3), J(2, 2), detJ, r_pt, B(4, 6)
    REAL(wp) :: dV, strain_mech(4), strain_thermal(4), strain_total(4)
    REAL(wp) :: sigma(4), grad_T(2), q_thermal(2)
    REAL(wp) :: T_elem(3), D(4, 4)
    INTEGER(i4) :: ip, i

    R_int = ZERO
    T_elem = u(7:9)
    CALL PH_Elem_CAX3T_ThermStrainAxisym(T_elem, T_ref, alpha, strain_thermal)
    CALL PH_Elem_CAX3_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      strain_mech = MATMUL(B, u(1:6))
      strain_total = strain_mech + strain_thermal
      sigma = MATMUL(D, strain_total)
      dV = TWOPI * r_pt * detJ * weights(ip)
      R_int(1:6) = R_int(1:6) + MATMUL(TRANSPOSE(B), sigma) * dV
    END DO
    DO ip = 1, 3
      CALL PH_Elem_CAX3_JacB(coords, xi(ip), eta(ip), N, dNdx, J, detJ, r_pt, B)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      grad_T(1) = DOT_PRODUCT(dNdx(1, :), T_elem)
      grad_T(2) = DOT_PRODUCT(dNdx(2, :), T_elem)
      q_thermal = -k_thermal * grad_T
      dV = TWOPI * r_pt * detJ * weights(ip)
      DO i = 1, 3
        R_int(6 + i) = R_int(6 + i) + (dNdx(1, i) * q_thermal(1) + dNdx(2, i) * q_thermal(2)) * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX3T_FormIntForce

  SUBROUTINE PH_Elem_CAX3T_DefInit()
  END SUBROUTINE PH_Elem_CAX3T_DefInit

  SUBROUTINE PH_Elem_CAX3T_GaussPoints(xi, eta, weights)
    REAL(wp), INTENT(OUT) :: xi(3), eta(3), weights(3)
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
  END SUBROUTINE PH_Elem_CAX3T_GaussPoints

  SUBROUTINE PH_Elem_CAX3T_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 3), coords(2, 3)
    REAL(wp), INTENT(OUT) :: J(2, 2), detJ
    CALL PH_Elem_CAX3_Jac(dNdxi, coords, J, detJ)
  END SUBROUTINE PH_Elem_CAX3T_Jac

  SUBROUTINE PH_Elem_CAX3T_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, r_pt, B)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: xi_pt, eta_pt
    REAL(wp), INTENT(OUT) :: N(3), dNdx(2, 3), J(2, 2), detJ, r_pt, B(4, 6)
    CALL PH_Elem_CAX3_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, r_pt, B)
  END SUBROUTINE PH_Elem_CAX3T_JacB

  SUBROUTINE PH_Elem_CAX3T_ShapeFunc(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(3), dNdxi(2, 3)
    CALL PH_Elem_CAX3_ShapeFunc(xi, eta, N, dNdxi)
  END SUBROUTINE PH_Elem_CAX3T_ShapeFunc

  SUBROUTINE PH_Elem_CAX3T_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(9, 9)
    Me = ZERO
    CALL PH_Elem_CAX3_ConsMass(coords, rho, Me(1:6, 1:6))
  END SUBROUTINE PH_Elem_CAX3T_ConsMass

  SUBROUTINE PH_Elem_CAX3T_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(9)
    M_lumped = ZERO
    CALL PH_Elem_CAX3_LumpMass(coords, rho, M_lumped(1:6))
  END SUBROUTINE PH_Elem_CAX3T_LumpMass

  SUBROUTINE PH_Elem_CAX3T_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_Elem_CAX3_GetArea(coords, area)
  END SUBROUTINE PH_Elem_CAX3T_GetArea

  SUBROUTINE PH_Elem_CAX3T_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: volume
    CALL PH_Elem_CAX3_GetVolume(coords, volume)
  END SUBROUTINE PH_Elem_CAX3T_GetVolume

  SUBROUTINE PH_Elem_CAX3T_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(OUT) :: centroid(2)
    CALL PH_Elem_CAX3_GetCentroid(coords, centroid)
  END SUBROUTINE PH_Elem_CAX3T_GetCentroid

  SUBROUTINE PH_Elem_CAX3T_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume, mass
    CALL PH_Elem_CAX3_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_CAX3T_GetSectProps

  SUBROUTINE PH_Elem_CAX3T_FormMechBodyForce(coords, br, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: br, bz
    REAL(wp), INTENT(OUT) :: F_eq(9)
    F_eq = ZERO
    CALL PH_Elem_CAX3_FormBodyForce(coords, br, bz, F_eq(1:6))
  END SUBROUTINE PH_Elem_CAX3T_FormMechBodyForce

  SUBROUTINE PH_Elem_CAX3T_FormMechEdgePressure(coords, p, edge_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(9)
    F_eq = ZERO
    CALL PH_Elem_CAX3_FormEdgePressure(coords, p, edge_id, F_eq(1:6))
  END SUBROUTINE PH_Elem_CAX3T_FormMechEdgePressure

  SUBROUTINE PH_Elem_CAX3T_FormThermalBodySource(coords, Q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: Q
    REAL(wp), INTENT(OUT) :: F_therm(3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), J(2, 2), detJ, r_pt
    INTEGER(i4) :: ip, i

    F_therm = ZERO
    CALL PH_Elem_CAX3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_CAX3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_CAX3_Jac(dNdxi, coords, J, detJ)
      r_pt = N(1)*coords(1,1) + N(2)*coords(1,2) + N(3)*coords(1,3)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) CYCLE
      DO i = 1, 3
        F_therm(i) = F_therm(i) + N(i) * Q * TWOPI * r_pt * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_CAX3T_FormThermalBodySource

  SUBROUTINE PH_Elem_CAX3T_FormThermalEdgeFlux(coords, edge_id, q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: q
    REAL(wp), INTENT(OUT) :: F_therm(3)
    REAL(wp) :: t(2), len, rmid
    INTEGER(i4) :: n1, n2

    F_therm = ZERO
    IF (edge_id < 1 .OR. edge_id > 3) RETURN
    n1 = PH_ELEM_CAX3T_EDGE_NODES(1, edge_id)
    n2 = PH_ELEM_CAX3T_EDGE_NODES(2, edge_id)
    t(1) = coords(1, n2) - coords(1, n1)
    t(2) = coords(2, n2) - coords(2, n1)
    len = SQRT(t(1)*t(1) + t(2)*t(2))
    IF (len < 1.0e-15_wp) RETURN
    rmid = (coords(1, n1) + coords(1, n2)) * HALF
    F_therm(n1) = F_therm(n1) + q * len * rmid * TWOPI * HALF
    F_therm(n2) = F_therm(n2) + q * len * rmid * TWOPI * HALF
  END SUBROUTINE PH_Elem_CAX3T_FormThermalEdgeFlux

  SUBROUTINE PH_Elem_CAX3T_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(2, 3)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(9)
    F_eq = ZERO
    IF (load_type == PH_ELEM_CAX3T_LOAD_BODY) THEN
      CALL PH_Elem_CAX3_FormBodyForce(coords, val(1), val(2), F_eq(1:6))
    ELSE IF (load_type == PH_ELEM_CAX3T_LOAD_EDGE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CAX3_FormEdgePressure(coords, val(1), edge_id, F_eq(1:6))
    ELSE IF (load_type == PH_ELEM_CAX3T_LOAD_HEAT_SOURCE .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CAX3T_FormThermalBodySource(coords, val(1), F_eq(7:9))
    ELSE IF (load_type == PH_ELEM_CAX3T_LOAD_THERMAL_FLUX .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_CAX3T_FormThermalEdgeFlux(coords, edge_id, val(1), F_eq(7:9))
    END IF
  END SUBROUTINE PH_Elem_CAX3T_FormNodalForce

  SUBROUTINE PH_Elem_CAX3T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, &
                                                         dStrain_total, thermal_strain, &
                                                         stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ThermoElasticAxisymmetric

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dStrain_total(4)
    REAL(wp),                  INTENT(IN)    :: thermal_strain(4)
    REAL(wp),                  INTENT(IN)    :: stress_old(4)
    REAL(wp),                  INTENT(OUT)   :: stress_new(4)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(4, 4)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ThermoElasticAxisymmetric(rt_ctx, mat_slot, dStrain_total, &
                                                    thermal_strain, stress_old, stress_new, &
                                                    D_tangent, status)
  END SUBROUTINE PH_Elem_CAX3T_Material_Update_Thermo_Routed

END MODULE PH_Elem_CAX3T


