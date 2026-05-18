!===============================================================================
! MODULE: PH_Elem_DS4
! LAYER:  L4_PH
! DOMAIN: Element/Shell
! ROLE:   Proc
! BRIEF:  DS4 shell thermal element definition (4-node)
!===============================================================================
MODULE PH_Elem_DS4
!> [CORE] DS4 shell thermal element unified interface (merged 6 files)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF, QUARTER
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Elem_DS4_DefInit
  PUBLIC :: PH_Elem_DS4_ShapeFunc
  PUBLIC :: PH_Elem_DS4_SurfMetric
  PUBLIC :: PH_Elem_DS4_GaussPoints
  PUBLIC :: PH_Elem_DS4_FormStiffMatrix
  PUBLIC :: PH_Elem_DS4_FormIntForce
  PUBLIC :: PH_Elem_DS4_ConsMass
  PUBLIC :: PH_Elem_DS4_LumpMass
  PUBLIC :: PH_Elem_DS4_ThermStrainVector
  PUBLIC :: PH_ELEM_DS4_NNODE
  PUBLIC :: PH_ELEM_DS4_NIP
  PUBLIC :: PH_ELEM_DS4_NDOF
  PUBLIC :: PH_ELEM_DS4_NEDGE
  PUBLIC :: PH_ELEM_DS4_AreaInt
  PUBLIC :: PH_Elem_DS4_GetArea
  PUBLIC :: PH_Elem_DS4_GetSectProps
  PUBLIC :: PH_Elem_DS4_GetCentroid
  PUBLIC :: PH_Elem_DS4_ApplyConstraint
  PUBLIC :: PH_Elem_DS4_ApplyMPC
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF
  PUBLIC :: PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_Elem_DS4_FormContactContrib
  PUBLIC :: PH_Elem_DS4_FormContactEdgeCtr
  PUBLIC :: PH_Elem_DS4_FormNodalForce
  PUBLIC :: PH_Elem_DS4_FormBodyForce
  PUBLIC :: PH_ELEM_LOAD_BODY
  PUBLIC :: PH_ELEM_LOAD_EDGE_P
  PUBLIC :: PH_Elem_DS4_CollectIPVars
  PUBLIC :: PH_Elem_DS4_MapToNode
  PUBLIC :: PH_Elem_DS4_GetExtrapMat
  PUBLIC :: PH_Elem_DS4_EvalVonMises
  PUBLIC :: PH_Elem_DS4_Material_Update_Thermal_Routed

  INTEGER(i4), PARAMETER :: PH_ELEM_DS4_NNODE  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_DS4_NIP   = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_DS4_NDOF  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_DS4_NEDGE = 0_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Shell_Args
  TYPE :: PH_Elem_Shell_Args
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
  END TYPE PH_Elem_Shell_Args


CONTAINS

  ! ---- Defn ----
  SUBROUTINE PH_ELEM_DS4_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), G(2, 2), Ginv(2, 2), detG
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_DS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_DS4_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_DS4_SurfMetric(dNdxi, coords, G, detG, Ginv)
      area = area + SQRT(MAX(detG, ZERO)) * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_DS4_AreaInt

  SUBROUTINE PH_Elem_DS4_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    eps_th = ZERO
  END SUBROUTINE PH_Elem_DS4_ThermStrainVector

  SUBROUTINE PH_Elem_DS4_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(4, 4)
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), G(2, 2), Ginv(2, 2), detG
    REAL(wp) :: dS
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_DS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_DS4_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_DS4_SurfMetric(dNdxi, coords, G, detG, Ginv)
      IF (ABS(detG) <= 1.0e-12_wp) CYCLE
      dS = SQRT(detG) * weights(ip)
      DO i = 1, 4
        DO j = 1, 4
          Me(i, j) = Me(i, j) + rho * N(i) * N(j) * dS
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_DS4_ConsMass

  SUBROUTINE PH_Elem_DS4_DefInit()
  END SUBROUTINE PH_Elem_DS4_DefInit

  SUBROUTINE PH_Elem_DS4_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: u(4)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(4)
    REAL(wp) :: Ke(4, 4)
    CALL PH_Elem_DS4_FormStiffMatrix(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_DS4_FormIntForce

  SUBROUTINE PH_Elem_DS4_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(4, 4)
    REAL(wp) :: k_cond
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), G(2, 2), Ginv(2, 2), detG
    REAL(wp) :: dS, grad_ij
    INTEGER(i4) :: ip, i, j
    k_cond = E_young
    Ke = ZERO
    CALL PH_Elem_DS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_DS4_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_DS4_SurfMetric(dNdxi, coords, G, detG, Ginv)
      IF (ABS(detG) <= 1.0e-12_wp) CYCLE
      dS = SQRT(detG) * weights(ip)
      DO i = 1, 4
        DO j = 1, 4
          grad_ij = dNdxi(1, i) * (Ginv(1, 1)*dNdxi(1, j) + Ginv(1, 2)*dNdxi(2, j)) &
                  + dNdxi(2, i) * (Ginv(2, 1)*dNdxi(1, j) + Ginv(2, 2)*dNdxi(2, j))
          Ke(i, j) = Ke(i, j) + k_cond * grad_ij * dS
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_DS4_FormStiffMatrix

  SUBROUTINE PH_Elem_DS4_GaussPoints(xi, eta, weights)
    REAL(wp), INTENT(OUT) :: xi(4), eta(4), weights(4)
    REAL(wp) :: g
    g = PH_ELEM_GAUSS_PT
    xi(1) = -g
    eta(1) = -g
    weights(1) = ONE
    xi(2) =  g
    eta(2) = -g
    weights(2) = ONE
    xi(3) =  g
    eta(3) =  g
    weights(3) = ONE
    xi(4) = -g
    eta(4) =  g
    weights(4) = ONE
  END SUBROUTINE PH_Elem_DS4_GaussPoints

  SUBROUTINE PH_Elem_DS4_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(4)
    REAL(wp) :: area, m
    INTEGER(i4) :: i
    CALL PH_ELEM_DS4_AreaInt(coords, area)
    m = rho * area / 4.0_wp
    DO i = 1, 4
      M_lumped(i) = m
    END DO
  END SUBROUTINE PH_Elem_DS4_LumpMass

  SUBROUTINE PH_Elem_DS4_ShapeFunc(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(4)
    REAL(wp), INTENT(OUT) :: dNdxi(2, 4)
    N(1) = QUARTER * (ONE - xi) * (ONE - eta)
    N(2) = QUARTER * (ONE + xi) * (ONE - eta)
    N(3) = QUARTER * (ONE + xi) * (ONE + eta)
    N(4) = QUARTER * (ONE - xi) * (ONE + eta)
    dNdxi(1, 1) = -QUARTER * (ONE - eta)
    dNdxi(2, 1) = -QUARTER * (ONE - xi)
    dNdxi(1, 2) =  QUARTER * (ONE - eta)
    dNdxi(2, 2) = -QUARTER * (ONE + xi)
    dNdxi(1, 3) =  QUARTER * (ONE + eta)
    dNdxi(2, 3) =  QUARTER * (ONE + xi)
    dNdxi(1, 4) = -QUARTER * (ONE + eta)
    dNdxi(2, 4) =  QUARTER * (ONE - xi)
  END SUBROUTINE PH_Elem_DS4_ShapeFunc

  SUBROUTINE PH_Elem_DS4_SurfMetric(dNdxi, coords, G, detG, Ginv)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 4)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: G(2, 2)
    REAL(wp), INTENT(OUT) :: detG
    REAL(wp), INTENT(OUT) :: Ginv(2, 2)
    REAL(wp) :: r_xi(3), r_eta(3)
    INTEGER(i4) :: i
    r_xi = ZERO
    r_eta = ZERO
    DO i = 1, 4
      r_xi(1:3)  = r_xi(1:3)  + dNdxi(1, i) * coords(1:3, i)
      r_eta(1:3) = r_eta(1:3) + dNdxi(2, i) * coords(1:3, i)
    END DO
    G(1, 1) = SUM(r_xi * r_xi)
    G(1, 2) = SUM(r_xi * r_eta)
    G(2, 1) = G(1, 2)
    G(2, 2) = SUM(r_eta * r_eta)
    detG = G(1, 1) * G(2, 2) - G(1, 2) * G(1, 2)
    IF (ABS(detG) <= 1.0e-20_wp) THEN
      Ginv = ZERO
      RETURN
    END IF
    Ginv(1, 1) =  G(2, 2) / detG
    Ginv(1, 2) = -G(1, 2) / detG
    Ginv(2, 1) = -G(2, 1) / detG
    Ginv(2, 2) =  G(1, 1) / detG
  END SUBROUTINE PH_Elem_DS4_SurfMetric

  ! ---- Sect ----
  SUBROUTINE PH_Elem_DS4_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_DS4_AreaInt(coords, area)
  END SUBROUTINE PH_Elem_DS4_GetArea

  SUBROUTINE PH_Elem_DS4_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: area, dS
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: N(4), dNdxi(2, 4), G(2, 2), Ginv(2, 2), detG
    INTEGER(i4) :: ip, j
    area = ZERO
    centroid = ZERO
    CALL PH_Elem_DS4_GaussPoints(xi, eta, weights)
    DO ip = 1, 4
      CALL PH_Elem_DS4_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_DS4_SurfMetric(dNdxi, coords, G, detG, Ginv)
      IF (ABS(detG) <= 1.0e-12_wp) CYCLE
      dS = SQRT(detG) * weights(ip)
      area = area + dS
      DO j = 1, 3
        centroid(j) = centroid(j) + (N(1)*coords(j,1) + N(2)*coords(j,2) + N(3)*coords(j,3) + N(4)*coords(j,4)) * dS
      END DO
    END DO
    IF (area > 1.0e-20_wp) centroid(1:3) = centroid(1:3) / area
  END SUBROUTINE PH_Elem_DS4_GetCentroid

  SUBROUTINE PH_Elem_DS4_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_DS4_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_DS4_GetSectProps

  ! ---- Constraints ----
  SUBROUTINE PH_Elem_DS4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 4) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_DS4_ApplyConstraint

  SUBROUTINE PH_Elem_DS4_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(4)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
    INTEGER(i4) :: i, j
    DO i = 1, 4
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 4
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_DS4_ApplyMPC

  ! ---- Cont (PH_ELEM_DS4_NEDGE=0, stubs; FormContactEdgeCtr uses INOUT for ADD pattern) ----
  SUBROUTINE PH_Elem_DS4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(4)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
  END SUBROUTINE PH_Elem_DS4_FormContactContrib

  SUBROUTINE PH_Elem_DS4_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
    ! PH_ELEM_DS4_NEDGE=0: no edges; stub adds nothing (INOUT for ADD pattern)
  END SUBROUTINE PH_Elem_DS4_FormContactEdgeCtr

  ! ---- Loads ----
  SUBROUTINE PH_Elem_DS4_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(4)
    F_eq = ZERO
  END SUBROUTINE PH_Elem_DS4_FormBodyForce

  SUBROUTINE PH_Elem_DS4_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(4)
    F_eq = ZERO
  END SUBROUTINE PH_Elem_DS4_FormNodalForce

  ! ---- Out ----
  SUBROUTINE PH_Elem_DS4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    out_vars = ZERO
  END SUBROUTINE PH_Elem_DS4_CollectIPVars

  SUBROUTINE PH_Elem_DS4_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    seq = ZERO
  END SUBROUTINE PH_Elem_DS4_EvalVonMises

  SUBROUTINE PH_Elem_DS4_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 4)
    E = ZERO
  END SUBROUTINE PH_Elem_DS4_GetExtrapMat

  SUBROUTINE PH_Elem_DS4_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    node_vars = ZERO
  END SUBROUTINE PH_Elem_DS4_MapToNode

  SUBROUTINE PH_Elem_DS4_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
                                                        heat_flux, K_tangent, status)
    USE IF_Err_Brg, ONLY: ErrorStatusType
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ThermalConductivityScalar

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: temp_gradient
    REAL(wp),                  INTENT(OUT)   :: heat_flux
    REAL(wp),                  INTENT(OUT)   :: K_tangent
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ThermalConductivityScalar(rt_ctx, mat_slot, temp_gradient, &
                                                    heat_flux, K_tangent, status)
  END SUBROUTINE PH_Elem_DS4_Material_Update_Thermal_Routed

END MODULE PH_Elem_DS4


