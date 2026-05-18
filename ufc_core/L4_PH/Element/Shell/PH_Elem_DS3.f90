!===============================================================================
! MODULE: PH_Elem_DS3
! LAYER:  L4_PH
! DOMAIN: Element/Shell
! ROLE:   Proc
! BRIEF:  DS3 shell thermal element definition (3-node)
!===============================================================================
MODULE PH_Elem_DS3
!> [CORE] DS3 shell thermal element unified interface (merged 6 files)
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_CPE3, ONLY: PH_Elem_CPE3_ShapeFunc, PH_Elem_CPE3_GaussPoints
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Elem_DS3_DefInit
  PUBLIC :: PH_Elem_DS3_ShapeFunc
  PUBLIC :: PH_Elem_DS3_SurfMetric
  PUBLIC :: PH_Elem_DS3_GaussPoints
  PUBLIC :: PH_Elem_DS3_FormStiffMatrix
  PUBLIC :: PH_Elem_DS3_FormIntForce
  PUBLIC :: PH_Elem_DS3_ConsMass
  PUBLIC :: PH_Elem_DS3_LumpMass
  PUBLIC :: PH_Elem_DS3_ThermStrainVector
  PUBLIC :: PH_ELEM_DS3_NNODE
  PUBLIC :: PH_ELEM_DS3_NIP
  PUBLIC :: PH_ELEM_DS3_NDOF
  PUBLIC :: PH_ELEM_DS3_NEDGE
  PUBLIC :: PH_ELEM_DS3_AreaInt
  PUBLIC :: PH_Elem_DS3_GetArea
  PUBLIC :: PH_Elem_DS3_GetSectProps
  PUBLIC :: PH_Elem_DS3_GetCentroid
  PUBLIC :: PH_Elem_DS3_ApplyConstraint
  PUBLIC :: PH_Elem_DS3_ApplyMPC
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF
  PUBLIC :: PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_Elem_DS3_FormContactContrib
  PUBLIC :: PH_Elem_DS3_FormContactEdgeCtr
  PUBLIC :: PH_Elem_DS3_FormNodalForce
  PUBLIC :: PH_Elem_DS3_FormBodyForce
  PUBLIC :: PH_ELEM_LOAD_BODY
  PUBLIC :: PH_ELEM_LOAD_EDGE_P
  PUBLIC :: PH_Elem_DS3_CollectIPVars
  PUBLIC :: PH_Elem_DS3_MapToNode
  PUBLIC :: PH_Elem_DS3_GetExtrapMat
  PUBLIC :: PH_Elem_DS3_Material_Update_Thermal_Routed

  INTEGER(i4), PARAMETER :: PH_ELEM_DS3_NNODE  = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_DS3_NIP   = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_DS3_NDOF  = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_DS3_NEDGE = 0_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

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
  SUBROUTINE PH_ELEM_DS3_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), G(2, 2), Ginv(2, 2), detG
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_DS3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_DS3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_DS3_SurfMetric(dNdxi, coords, G, detG, Ginv)
      area = area + SQRT(MAX(detG, ZERO)) * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_DS3_AreaInt

  SUBROUTINE PH_Elem_DS3_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    eps_th = ZERO
  END SUBROUTINE PH_Elem_DS3_ThermStrainVector

  SUBROUTINE PH_Elem_DS3_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(3, 3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), G(2, 2), Ginv(2, 2), detG
    REAL(wp) :: dS
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_DS3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_DS3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_DS3_SurfMetric(dNdxi, coords, G, detG, Ginv)
      IF (ABS(detG) <= 1.0e-12_wp) CYCLE
      dS = SQRT(detG) * weights(ip)
      DO i = 1, 3
        DO j = 1, 3
          Me(i, j) = Me(i, j) + rho * N(i) * N(j) * dS
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_DS3_ConsMass

  SUBROUTINE PH_Elem_DS3_DefInit()
  END SUBROUTINE PH_Elem_DS3_DefInit

  SUBROUTINE PH_Elem_DS3_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: u(3)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(3)
    REAL(wp) :: Ke(3, 3)
    CALL PH_Elem_DS3_FormStiffMatrix(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_DS3_FormIntForce

  SUBROUTINE PH_Elem_DS3_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(3, 3)
    REAL(wp) :: k_cond
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), G(2, 2), Ginv(2, 2), detG
    REAL(wp) :: dS, grad_ij
    INTEGER(i4) :: ip, i, j
    k_cond = E_young
    Ke = ZERO
    CALL PH_Elem_DS3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_DS3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_DS3_SurfMetric(dNdxi, coords, G, detG, Ginv)
      IF (ABS(detG) <= 1.0e-12_wp) CYCLE
      dS = SQRT(detG) * weights(ip)
      DO i = 1, 3
        DO j = 1, 3
          grad_ij = dNdxi(1, i) * (Ginv(1, 1)*dNdxi(1, j) + Ginv(1, 2)*dNdxi(2, j)) &
                  + dNdxi(2, i) * (Ginv(2, 1)*dNdxi(1, j) + Ginv(2, 2)*dNdxi(2, j))
          Ke(i, j) = Ke(i, j) + k_cond * grad_ij * dS
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_DS3_FormStiffMatrix

  SUBROUTINE PH_Elem_DS3_GaussPoints(xi, eta, weights)
    REAL(wp), INTENT(OUT) :: xi(3), eta(3), weights(3)
    CALL PH_Elem_CPE3_GaussPoints(xi, eta, weights)
  END SUBROUTINE PH_Elem_DS3_GaussPoints

  SUBROUTINE PH_Elem_DS3_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(3)
    REAL(wp) :: area, m
    INTEGER(i4) :: i
    CALL PH_ELEM_DS3_AreaInt(coords, area)
    m = rho * area / 3.0_wp
    DO i = 1, 3
      M_lumped(i) = m
    END DO
  END SUBROUTINE PH_Elem_DS3_LumpMass

  SUBROUTINE PH_Elem_DS3_ShapeFunc(xi, eta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(OUT) :: N(3)
    REAL(wp), INTENT(OUT) :: dNdxi(2, 3)
    CALL PH_Elem_CPE3_ShapeFunc(xi, eta, N, dNdxi)
  END SUBROUTINE PH_Elem_DS3_ShapeFunc

  SUBROUTINE PH_Elem_DS3_SurfMetric(dNdxi, coords, G, detG, Ginv)
    REAL(wp), INTENT(IN)  :: dNdxi(2, 3)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(OUT) :: G(2, 2)
    REAL(wp), INTENT(OUT) :: detG
    REAL(wp), INTENT(OUT) :: Ginv(2, 2)
    REAL(wp) :: r_xi(3), r_eta(3)
    INTEGER(i4) :: i
    r_xi = ZERO
    r_eta = ZERO
    DO i = 1, 3
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
  END SUBROUTINE PH_Elem_DS3_SurfMetric

  ! ---- Sect ----
  SUBROUTINE PH_Elem_DS3_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_DS3_AreaInt(coords, area)
  END SUBROUTINE PH_Elem_DS3_GetArea

  SUBROUTINE PH_Elem_DS3_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: area, dS
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), G(2, 2), Ginv(2, 2), detG
    INTEGER(i4) :: ip, j
    area = ZERO
    centroid = ZERO
    CALL PH_Elem_DS3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_DS3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_DS3_SurfMetric(dNdxi, coords, G, detG, Ginv)
      IF (ABS(detG) <= 1.0e-12_wp) CYCLE
      dS = SQRT(detG) * weights(ip)
      area = area + dS
      DO j = 1, 3
        centroid(j) = centroid(j) + (N(1)*coords(j,1) + N(2)*coords(j,2) + N(3)*coords(j,3)) * dS
      END DO
    END DO
    IF (area > 1.0e-20_wp) centroid(1:3) = centroid(1:3) / area
  END SUBROUTINE PH_Elem_DS3_GetCentroid

  SUBROUTINE PH_Elem_DS3_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_DS3_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_DS3_GetSectProps

  ! ---- Constraints ----
  SUBROUTINE PH_Elem_DS3_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(3, 3)
    REAL(wp), INTENT(INOUT) :: F_el(3)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 3) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_DS3_ApplyConstraint

  SUBROUTINE PH_Elem_DS3_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(3)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(3, 3)
    REAL(wp), INTENT(INOUT) :: F_el(3)
    INTEGER(i4) :: i, j
    DO i = 1, 3
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 3
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_DS3_ApplyMPC

  ! ---- Cont (PH_ELEM_DS3_NEDGE=0, stubs; FormContactEdgeCtr uses INOUT for ADD pattern) ----
  SUBROUTINE PH_Elem_DS3_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(3)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(3, 3)
    REAL(wp), INTENT(INOUT) :: F_el(3)
  END SUBROUTINE PH_Elem_DS3_FormContactContrib

  SUBROUTINE PH_Elem_DS3_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(INOUT) :: K_el(3, 3)
    REAL(wp), INTENT(INOUT) :: F_el(3)
    ! PH_ELEM_DS3_NEDGE=0: no edges; stub adds nothing (INOUT for ADD pattern when called from FormContactContrib loop)
  END SUBROUTINE PH_Elem_DS3_FormContactEdgeCtr

  ! ---- Loads ----
  SUBROUTINE PH_Elem_DS3_FormBodyForce(coords, q, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: q  ! Heat source per unit area
    REAL(wp), INTENT(OUT) :: F_eq(3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3), G(2, 2), Ginv(2, 2), detG
    REAL(wp) :: dS
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_DS3_GaussPoints(xi, eta, weights)
    DO ip = 1, 3
      CALL PH_Elem_DS3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      CALL PH_Elem_DS3_SurfMetric(dNdxi, coords, G, detG, Ginv)
      IF (ABS(detG) <= 1.0e-12_wp) CYCLE
      dS = SQRT(detG) * weights(ip)
      DO i = 1, 3
        F_eq(i) = F_eq(i) + N(i) * q * dS
      END DO
    END DO
  END SUBROUTINE PH_Elem_DS3_FormBodyForce

  SUBROUTINE PH_Elem_DS3_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 3)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(3)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_DS3_FormBodyForce(coords, val(1), F_eq)
    END IF
  END SUBROUTINE PH_Elem_DS3_FormNodalForce

  ! ---- Out ----
  SUBROUTINE PH_Elem_DS3_CollectIPVars(ip_temp, ip_flux, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_temp(:)
    REAL(wp), INTENT(IN)  :: ip_flux(:, :)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 3)
      IF (SIZE(out_vars, 1) >= 1 .AND. SIZE(ip_temp) >= ip) out_vars(1, ip) = ip_temp(ip)
      IF (SIZE(out_vars, 1) >= 2 .AND. SIZE(ip_flux, 1) >= 2) out_vars(2:3, ip) = ip_flux(1:2, ip)
    END DO
  END SUBROUTINE PH_Elem_DS3_CollectIPVars

  SUBROUTINE PH_Elem_DS3_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(3, 3)
    REAL(wp) :: xi(3), eta(3), weights(3)
    REAL(wp) :: N(3), dNdxi(2, 3)
    INTEGER(i4) :: ip, i
    CALL PH_Elem_DS3_GaussPoints(xi, eta, weights)
    E = ZERO
    DO ip = 1, 3
      CALL PH_Elem_DS3_ShapeFunc(xi(ip), eta(ip), N, dNdxi)
      DO i = 1, 3
        E(i, ip) = N(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_DS3_GetExtrapMat

  SUBROUTINE PH_Elem_DS3_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(3, 3)
    INTEGER(i4) :: nv, n_ip
    node_vars = ZERO
    CALL PH_Elem_DS3_GetExtrapMat(E)
    nv = MIN(SIZE(ip_vars, 1), SIZE(node_vars, 1))
    n_ip = MIN(SIZE(ip_vars, 2), SIZE(weights), 3)
    IF (nv >= 1 .AND. n_ip >= 1) THEN
      node_vars(1:nv, 1:3) = MATMUL(ip_vars(1:nv, 1:n_ip), TRANSPOSE(E(1:3, 1:n_ip)))
    END IF
  END SUBROUTINE PH_Elem_DS3_MapToNode

  SUBROUTINE PH_Elem_DS3_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
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
  END SUBROUTINE PH_Elem_DS3_Material_Update_Thermal_Routed

END MODULE PH_Elem_DS3


