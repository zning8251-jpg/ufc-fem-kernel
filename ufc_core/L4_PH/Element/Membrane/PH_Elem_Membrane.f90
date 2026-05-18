!===============================================================================
! MODULE: PH_Elem_Membrane
! LAYER:  L4_PH
! DOMAIN: Element/Membrane
! ROLE:   Proc
! BRIEF:  Membrane element unified interface
!===============================================================================
MODULE PH_Elem_Membrane
!> [CORE] Membrane element unified interface (M3D3/M3D4/M3D4R/M3D8R/M3D9R)
!> Merged: Mem_Defn + M3D9R Defn/Sect/Constraints/Cont/Loads/Out
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF, THREE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ElemLib
  USE MD_Base_ObjModel, ONLY: MatCtxLegacy, MatRes, MatProps, IPState
  USE MD_Model_Lib_Core
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                          UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib, ONLY: MatProperties
  USE UF_Material_Base
  IMPLICIT NONE
  PRIVATE

  ! Parameters
  INTEGER(i4), PARAMETER :: PH_ELEM_M3D9R_NNODE  = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_M3D9R_NIP   = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_M3D9R_NDOF  = 12_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_M3D9R_NEDGE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_EDGE_P = 2_i4

  PUBLIC :: UF_Elem_Membrane_Calc
  PUBLIC :: PH_ELEM_M3D9R_NNODE, PH_ELEM_M3D9R_NIP, PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NEDGE
  PUBLIC :: PH_Elem_M3D9R_DefInit, PH_Elem_M3D9R_FormStiffMatrix, PH_Elem_M3D9R_FormIntForce
  PUBLIC :: PH_Elem_M3D9R_ConsMass, PH_Elem_M3D9R_LumpMass, PH_Elem_M3D9R_ThermStrainVector
  PUBLIC :: PH_Elem_M3D9R_NL_TL, PH_Elem_M3D9R_NL_UL
  PUBLIC :: PH_Elem_M3D9R_GetArea, PH_Elem_M3D9R_GetSectProps, PH_Elem_M3D9R_GetCentroid
  PUBLIC :: PH_Elem_M3D9R_ApplyConstraint, PH_Elem_M3D9R_ApplyMPC
  PUBLIC :: PH_Elem_M3D9R_FormContactContrib, PH_Elem_M3D9R_FormContactEdgeCtr
  PUBLIC :: PH_Elem_M3D9R_FormNodalForce, PH_Elem_M3D9R_FormBodyForce
  PUBLIC :: PH_Elem_M3D9R_CollectIPVars, PH_Elem_M3D9R_MapToNode
  PUBLIC :: PH_Elem_M3D9R_GetExtrapMat, PH_Elem_M3D9R_EvalVonMises, PH_Elem_M3D9R_EvalMembraneStress
  PUBLIC :: PH_Elem_M3D9R_Material_Update_Routed

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Membrane_Args
  TYPE :: PH_Elem_Membrane_Args
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
  END TYPE PH_Elem_Membrane_Args


CONTAINS

  PURE SUBROUTINE Memb_Q4_ShapesAndDerivs(xi, eta, N, dN1dxi, dN2dxi, dN3dxi, dN4dxi, &
      dN1de, dN2de, dN3de, dN4de)
    REAL(wp), INTENT(IN) :: xi, eta
    REAL(wp), INTENT(OUT) :: N(4)
    REAL(wp), INTENT(OUT) :: dN1dxi, dN2dxi, dN3dxi, dN4dxi, dN1de, dN2de, dN3de, dN4de
    N(1) = 0.25_wp*(ONE - xi)*(ONE - eta)
    N(2) = 0.25_wp*(ONE + xi)*(ONE - eta)
    N(3) = 0.25_wp*(ONE + xi)*(ONE + eta)
    N(4) = 0.25_wp*(ONE - xi)*(ONE + eta)
    dN1dxi = -0.25_wp*(ONE - eta)
    dN2dxi =  0.25_wp*(ONE - eta)
    dN3dxi =  0.25_wp*(ONE + eta)
    dN4dxi = -0.25_wp*(ONE + eta)
    dN1de = -0.25_wp*(ONE - xi)
    dN2de = -0.25_wp*(ONE + xi)
    dN3de =  0.25_wp*(ONE + xi)
    dN4de =  0.25_wp*(ONE - xi)
  END SUBROUTINE Memb_Q4_ShapesAndDerivs

  SUBROUTINE Memb_BuildPlaneFrame(c4, e1, e2, e3, x0, ok)
    REAL(wp), INTENT(IN) :: c4(3, 4)
    REAL(wp), INTENT(OUT) :: e1(3), e2(3), e3(3), x0(3)
    LOGICAL, INTENT(OUT) :: ok
    REAL(wp) :: v1(3), v2(3), vn(3), sn, s1
    INTEGER(i4) :: j
    x0 = ZERO
    DO j = 1, 4
      x0(:) = x0(:) + c4(:, j)
    END DO
    x0 = x0 * 0.25_wp
    v1 = c4(:, 2) - c4(:, 1)
    v2 = c4(:, 4) - c4(:, 1)
    vn(1) = v1(2)*v2(3) - v1(3)*v2(2)
    vn(2) = v1(3)*v2(1) - v1(1)*v2(3)
    vn(3) = v1(1)*v2(2) - v1(2)*v2(1)
    sn = SQRT(SUM(vn*vn))
    IF (sn <= 1.0e-14_wp) THEN
      ok = .FALSE.
      RETURN
    END IF
    e3 = vn / sn
    s1 = SQRT(SUM(v1*v1))
    IF (s1 <= 1.0e-14_wp) THEN
      ok = .FALSE.
      RETURN
    END IF
    e1 = v1 / s1
    e2(1) = e3(2)*e1(3) - e3(3)*e1(2)
    e2(2) = e3(3)*e1(1) - e3(1)*e1(3)
    e2(3) = e3(1)*e1(2) - e3(2)*e1(1)
    ok = .TRUE.
  END SUBROUTINE Memb_BuildPlaneFrame

  SUBROUTINE Memb_FillTransformT(e1, e2, T)
    REAL(wp), INTENT(IN) :: e1(3), e2(3)
    REAL(wp), INTENT(OUT) :: T(12, 8)
    INTEGER(i4) :: i
    T = ZERO
    DO i = 1, 4
      T(3*(i-1)+1, 2*(i-1)+1) = e1(1)
      T(3*(i-1)+2, 2*(i-1)+1) = e1(2)
      T(3*(i-1)+3, 2*(i-1)+1) = e1(3)
      T(3*(i-1)+1, 2*(i-1)+2) = e2(1)
      T(3*(i-1)+2, 2*(i-1)+2) = e2(2)
      T(3*(i-1)+3, 2*(i-1)+2) = e2(3)
    END DO
  END SUBROUTINE Memb_FillTransformT

  SUBROUTINE Memb_Q4_StiffMass(xl, yl, rho, want_mass, E, nu, t, Ke8, Me8, ok)
    REAL(wp), INTENT(IN) :: xl(4), yl(4)
    REAL(wp), INTENT(IN) :: rho
    LOGICAL, INTENT(IN) :: want_mass
    REAL(wp), INTENT(IN) :: E, nu, t
    REAL(wp), INTENT(OUT) :: Ke8(8, 8), Me8(8, 8)
    LOGICAL, INTENT(OUT) :: ok
    REAL(wp) :: Dm(3, 3), gp, xi, eta, wgp, detJ, detJi
    REAL(wp) :: J11, J12, J21, J22
    REAL(wp) :: inv11, inv12, inv21, inv22
    REAL(wp) :: dN1dxi, dN2dxi, dN3dxi, dN4dxi, dN1de, dN2de, dN3de, dN4de
    REAL(wp) :: dNdx(4), dNdy(4)
    REAL(wp) :: B(3, 8), N(4)
    INTEGER(i4) :: iq, jq, a, rr, cc
    REAL(wp) :: fac, mfac

    Ke8 = ZERO
    Me8 = ZERO
    ok = .TRUE.
    gp = ONE / SQRT(THREE)
    Dm = ZERO
    fac = E * t / (ONE - nu * nu)
    Dm(1, 1) = fac
    Dm(1, 2) = fac * nu
    Dm(2, 1) = fac * nu
    Dm(2, 2) = fac
    Dm(3, 3) = fac * (ONE - nu) * HALF

    DO iq = 1, 2
      DO jq = 1, 2
        IF (iq == 1) THEN
          xi = -gp
        ELSE
          xi = gp
        END IF
        IF (jq == 1) THEN
          eta = -gp
        ELSE
          eta = gp
        END IF
        wgp = ONE
        CALL Memb_Q4_ShapesAndDerivs(xi, eta, N, dN1dxi, dN2dxi, dN3dxi, dN4dxi, &
            dN1de, dN2de, dN3de, dN4de)
        J11 = dN1dxi*xl(1) + dN2dxi*xl(2) + dN3dxi*xl(3) + dN4dxi*xl(4)
        J12 = dN1de*xl(1) + dN2de*xl(2) + dN3de*xl(3) + dN4de*xl(4)
        J21 = dN1dxi*yl(1) + dN2dxi*yl(2) + dN3dxi*yl(3) + dN4dxi*yl(4)
        J22 = dN1de*yl(1) + dN2de*yl(2) + dN3de*yl(3) + dN4de*yl(4)
        detJ = J11*J22 - J12*J21
        IF (detJ <= 1.0e-16_wp) THEN
          ok = .FALSE.
          RETURN
        END IF
        detJi = ONE / detJ
        inv11 = J22 * detJi
        inv12 = -J12 * detJi
        inv21 = -J21 * detJi
        inv22 = J11 * detJi
        dNdx(1) = inv11*dN1dxi + inv12*dN1de
        dNdx(2) = inv11*dN2dxi + inv12*dN2de
        dNdx(3) = inv11*dN3dxi + inv12*dN3de
        dNdx(4) = inv11*dN4dxi + inv12*dN4de
        dNdy(1) = inv21*dN1dxi + inv22*dN1de
        dNdy(2) = inv21*dN2dxi + inv22*dN2de
        dNdy(3) = inv21*dN3dxi + inv22*dN3de
        dNdy(4) = inv21*dN4dxi + inv22*dN4de
        B = ZERO
        DO a = 1, 4
          B(1, 2*a-1) = dNdx(a)
          B(2, 2*a) = dNdy(a)
          B(3, 2*a-1) = dNdy(a)
          B(3, 2*a) = dNdx(a)
        END DO
        Ke8 = Ke8 + wgp * detJ * MATMUL(TRANSPOSE(B), MATMUL(Dm, B))
        IF (want_mass) THEN
          mfac = rho * t * wgp * detJ
          DO rr = 1, 4
            DO cc = 1, 4
              Me8(2*rr-1, 2*cc-1) = Me8(2*rr-1, 2*cc-1) + mfac * N(rr) * N(cc)
              Me8(2*rr, 2*cc) = Me8(2*rr, 2*cc) + mfac * N(rr) * N(cc)
            END DO
          END DO
        END IF
      END DO
    END DO
  END SUBROUTINE Memb_Q4_StiffMass

  SUBROUTINE Memb_AssembleGlobalK(Ke8, e1, e2, Ke12)
    REAL(wp), INTENT(IN) :: Ke8(8, 8), e1(3), e2(3)
    REAL(wp), INTENT(OUT) :: Ke12(12, 12)
    REAL(wp) :: T(12, 8), work(8, 12)
    CALL Memb_FillTransformT(e1, e2, T)
    work = MATMUL(Ke8, TRANSPOSE(T))
    Ke12 = MATMUL(T, work)
  END SUBROUTINE Memb_AssembleGlobalK

  SUBROUTINE Memb_AssembleGlobalM(Me8, e1, e2, Me12)
    REAL(wp), INTENT(IN) :: Me8(8, 8), e1(3), e2(3)
    REAL(wp), INTENT(OUT) :: Me12(12, 12)
    REAL(wp) :: T(12, 8), work(8, 12)
    CALL Memb_FillTransformT(e1, e2, T)
    work = MATMUL(Me8, TRANSPOSE(T))
    Me12 = MATMUL(T, work)
  END SUBROUTINE Memb_AssembleGlobalM

  SUBROUTINE Memb_M3D9R_LinearCore(coords, E_young, nu, thick, rho, want_mass, Ke12, Me12, &
      e1, e2, ok)
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(IN) :: E_young, nu, thick, rho
    LOGICAL, INTENT(IN) :: want_mass
    REAL(wp), INTENT(OUT) :: Ke12(12, 12), Me12(12, 12)
    REAL(wp), INTENT(OUT) :: e1(3), e2(3)
    LOGICAL, INTENT(OUT) :: ok
    REAL(wp) :: e3(3), x0(3), xl(4), yl(4)
    REAL(wp) :: Ke8(8, 8), Me8(8, 8)
    INTEGER(i4) :: j
    CALL Memb_BuildPlaneFrame(coords, e1, e2, e3, x0, ok)
    IF (.NOT. ok) RETURN
    DO j = 1, 4
      xl(j) = DOT_PRODUCT(coords(:, j) - x0, e1)
      yl(j) = DOT_PRODUCT(coords(:, j) - x0, e2)
    END DO
    CALL Memb_Q4_StiffMass(xl, yl, rho, want_mass, E_young, nu, thick, Ke8, Me8, ok)
    IF (.NOT. ok) RETURN
    CALL Memb_AssembleGlobalK(Ke8, e1, e2, Ke12)
    IF (want_mass) THEN
      CALL Memb_AssembleGlobalM(Me8, e1, e2, Me12)
    ELSE
      Me12 = ZERO
    END IF
  END SUBROUTINE Memb_M3D9R_LinearCore

  !=============================================================================
  ! DEFINITION: Unified dispatcher
  !=============================================================================
  SUBROUTINE UF_Elem_Membrane_Calc(ElemType, Formul, Ctx, state_in, &
                                    Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CHARACTER(len=10) :: ename
    INTEGER(i4) :: nNode

    ename = ElemType%name
    CALL UPPER_CASE(ename)
    nNode = ElemType%numNodes

    IF (INDEX(ename, 'M3D9R') > 0) THEN
      CALL UF_Elem_M3D9R_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    END IF

    IF (nNode == PH_ELEM_M3D9R_NNODE) THEN
      CALL UF_Elem_M3D9R_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    ELSE
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      state_out%Me = 0.0_wp
      state_out%Ce = 0.0_wp
      flags%failed = .TRUE.
      flags%suggest_cutback = .FALSE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_Membrane_Calc: membrane type not implemented (use M3D9R / 4-node)')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
    END IF
  END SUBROUTINE UF_Elem_Membrane_Calc

  SUBROUTINE UPPER_CASE(str)
    CHARACTER(len=*), INTENT(INOUT) :: str
    INTEGER(i4) :: i
    DO i = 1, LEN(str)
      IF (str(i:i) >= 'a' .AND. str(i:i) <= 'z') &
        str(i:i) = CHAR(ICHAR(str(i:i)) - 32)
    END DO
  END SUBROUTINE UPPER_CASE

  !=============================================================================
  ! M3D9R: definition + Calc (registry pattern; extend when M3D9R kernel is split out)
  !=============================================================================
  SUBROUTINE PH_Elem_M3D9R_DefInit()
  END SUBROUTINE PH_Elem_M3D9R_DefInit

  SUBROUTINE PH_Elem_M3D9R_FormStiffMatrix(coords, E_young, nu, Ke, thickness)
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(IN) :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF)
    REAL(wp), INTENT(IN), OPTIONAL :: thickness
    REAL(wp) :: Me(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF), e1(3), e2(3), tloc
    LOGICAL :: ok
    Ke = ZERO
    tloc = ONE
    IF (PRESENT(thickness)) THEN
      IF (thickness > 0.0_wp) tloc = thickness
    END IF
    CALL Memb_M3D9R_LinearCore(coords, E_young, nu, tloc, ZERO, .FALSE., Ke, Me, e1, e2, ok)
    IF (.NOT. ok) Ke = ZERO
  END SUBROUTINE PH_Elem_M3D9R_FormStiffMatrix

  SUBROUTINE PH_Elem_M3D9R_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    INTEGER(i4) :: i, n
    eps_th = ZERO
    ! Isotropic thermal expansion placeholder: each translational DOF gets alpha*dT (see module contract).
    n = INT(SIZE(eps_th), i4)
    DO i = 1, n
      eps_th(i) = alpha * deltaT
    END DO
  END SUBROUTINE PH_Elem_M3D9R_ThermStrainVector

  SUBROUTINE PH_Elem_M3D9R_ConsMass(coords, rho, Me, thickness)
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(IN) :: rho
    REAL(wp), INTENT(OUT) :: Me(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF)
    REAL(wp), INTENT(IN), OPTIONAL :: thickness
    REAL(wp) :: Ke(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF), e1(3), e2(3), tloc
    LOGICAL :: ok
    Me = ZERO
    tloc = ONE
    IF (PRESENT(thickness)) THEN
      IF (thickness > 0.0_wp) tloc = thickness
    END IF
    CALL Memb_M3D9R_LinearCore(coords, ONE, 0.3_wp, tloc, rho, .TRUE., Ke, Me, e1, e2, ok)
    IF (.NOT. ok) Me = ZERO
  END SUBROUTINE PH_Elem_M3D9R_ConsMass

  SUBROUTINE PH_Elem_M3D9R_FormIntForce(coords, u, E_young, nu, R_int, thickness)
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(IN) :: u(PH_ELEM_M3D9R_NDOF)
    REAL(wp), INTENT(IN) :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(PH_ELEM_M3D9R_NDOF)
    REAL(wp), INTENT(IN), OPTIONAL :: thickness
    REAL(wp) :: Ke(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF), Me(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF)
    REAL(wp) :: e1(3), e2(3), tloc
    LOGICAL :: ok
    R_int = ZERO
    tloc = ONE
    IF (PRESENT(thickness)) THEN
      IF (thickness > 0.0_wp) tloc = thickness
    END IF
    CALL Memb_M3D9R_LinearCore(coords, E_young, nu, tloc, ZERO, .FALSE., Ke, Me, e1, e2, ok)
    IF (.NOT. ok) RETURN
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_M3D9R_FormIntForce

  SUBROUTINE PH_Elem_M3D9R_LumpMass(coords, rho, M_lumped, thickness)
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(IN) :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(PH_ELEM_M3D9R_NDOF)
    REAL(wp), INTENT(IN), OPTIONAL :: thickness
    REAL(wp) :: Me(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF), Ke(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF)
    REAL(wp) :: e1(3), e2(3), tloc
    INTEGER(i4) :: i
    LOGICAL :: ok
    M_lumped = ZERO
    tloc = ONE
    IF (PRESENT(thickness)) THEN
      IF (thickness > 0.0_wp) tloc = thickness
    END IF
    CALL Memb_M3D9R_LinearCore(coords, ONE, 0.3_wp, tloc, rho, .TRUE., Ke, Me, e1, e2, ok)
    IF (.NOT. ok) RETURN
    DO i = 1, PH_ELEM_M3D9R_NDOF
      M_lumped(i) = SUM(Me(i, :))
    END DO
  END SUBROUTINE PH_Elem_M3D9R_LumpMass

  SUBROUTINE PH_Elem_M3D9R_NL_TL(coords_ref, u_elem, D, thickness, Ke_mat, Ke_geo, R_int, status)
    !--------------------------------------------------------------------------
    ! M3D9R: Total Lagrangian (TL) formulation - Geometric nonlinearity
    ! Reference: PH_ElemNlgeom_Algo (ST-7.1)
    ! Theory:
    !   - Green-Lagrange strain: E = 0.5*(F^T*F - I)
    !   - 2nd Piola-Kirchhoff stress: S = D:E
    !   - Internal force: R_int = ?B_NL^T * S dV_0
    !   - Material stiffness: K_mat = ?B_NL^T * D * B_NL dV_0
    !   - Geometric stiffness: K_geo = ?G^T * τ * G dV_0 (τ = FSF^T)
    !--------------------------------------------------------------------------
    USE PH_Elem_Nlgeom, ONLY: PH_Nlgeom_Args, PH_ELEM_NLGEOM_TL, &
         PH_Compute_Deformation_Gradient, PH_Compute_Green_Lagrange_Strain, &
         PH_Transform_Stress_PK2_to_Cauchy, PH_Compute_B_Matrix_NL
    
    REAL(wp), INTENT(IN)  :: coords_ref(3, 4)    ! Reference configuration [dim, n_nodes]
    REAL(wp), INTENT(IN)  :: u_elem(12)          ! Displacement vector [n_dof]
    REAL(wp), INTENT(IN)  :: D(6, 6)             ! Constitutive matrix (plane stress)
    REAL(wp), INTENT(IN)  :: thickness           ! Membrane thickness
    REAL(wp), INTENT(OUT) :: Ke_mat(12, 12)      ! Material stiffness
    REAL(wp), INTENT(OUT) :: Ke_geo(12, 12)      ! Geometric stiffness
    REAL(wp), INTENT(OUT) :: R_int(12)           ! Internal force residual
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    !-- Local variables
    INTEGER(i4), PARAMETER :: N_NODES = 4, N_DOF = 12, N_IP = 4
    INTEGER(i4), PARAMETER :: N_STR = 3  ! Plane stress: [ε_xx, ε_yy, 2ε_xy]
    INTEGER(i4) :: ip, node, i, j
    REAL(wp) :: coords_cur(3, N_NODES)     ! Current configuration
    REAL(wp) :: xi_vals(4), eta_vals(4), wts(4)
    REAL(wp) :: N(4), dN_dxi(4, 2)         ! Shape functions and derivatives
    REAL(wp) :: dN_dX(4, 3)                ! Spatial derivatives (reference)
    REAL(wp) :: detJ, weight
    REAL(wp) :: F(3, 3), E_GL(6)           ! Deformation gradient, GL strain
    REAL(wp) :: S_PK2(6), sigma_cauchy(6)  ! PK2 stress, Cauchy stress
    REAL(wp) :: B_NL(3, N_DOF)             ! Nonlinear B-matrix
    REAL(wp) :: dV0                        ! Volume element (reference)
    REAL(wp) :: tau(6)                     | Kirchhoff stress (τ = Jσ)
    REAL(wp) :: work_mat(N_DOF, N_DOF)
    LOGICAL :: geom_ok
    
    ! Initialize
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    CALL init_error_status(status)
    
    ! Current configuration: x = X + u
    DO node = 1, N_NODES
      coords_cur(1, node) = coords_ref(1, node) + u_elem((node-1)*3 + 1)
      coords_cur(2, node) = coords_ref(2, node) + u_elem((node-1)*3 + 2)
      coords_cur(3, node) = coords_ref(3, node) + u_elem((node-1)*3 + 3)
    END DO
    
    ! 2×2 Gauss quadrature
    xi_vals  = [-ONE/SQRT(THREE), ONE/SQRT(THREE), ONE/SQRT(THREE), -ONE/SQRT(THREE)]
    eta_vals = [-ONE/SQRT(THREE), -ONE/SQRT(THREE), ONE/SQRT(THREE), ONE/SQRT(THREE)]
    wts      = [ONE, ONE, ONE, ONE]
    
    ! Integration loop
    DO ip = 1, N_IP
      ! Shape functions and parametric derivatives
      CALL Memb_Q4_ShapesAndDerivs(xi_vals(ip), eta_vals(ip), N, &
           dN_dxi(1,1), dN_dxi(2,1), dN_dxi(3,1), dN_dxi(4,1), &
           dN_dxi(1,2), dN_dxi(2,2), dN_dxi(3,2), dN_dxi(4,2))
      
      ! Jacobian: dX/dξ (reference configuration)
      detJ = ZERO
      dN_dX = ZERO
      DO node = 1, N_NODES
        dN_dX(node, 1) = dN_dxi(node, 1) * coords_ref(1, node) + &
                         dN_dxi(node, 2) * coords_ref(2, node)
        dN_dX(node, 2) = dN_dxi(node, 1) * coords_ref(2, node) + &
                         dN_dxi(node, 2) * coords_ref(3, node)
      END DO
      detJ = coords_ref(1,1)*coords_ref(2,2) - coords_ref(1,2)*coords_ref(2,1)  ! Simplified
      
      IF (detJ <= 1.0e-14_wp) THEN
        CALL init_error_status(status, IF_STATUS_INVALID, "Invalid Jacobian")
        RETURN
      END IF
      
      weight = wts(ip) * thickness * detJ
      dV0 = weight  ! For membrane: dV_0 = t * dA_0
      
      !--- TL Formulation Core ---
      ! Step 1: Compute deformation gradient F = dx/dX
      ALLOCATE(PH_Nlgeom_Args :: nl_args)
      nl_args%coords_ref = coords_ref
      nl_args%coords_cur = coords_cur
      nl_args%dN_dxi = RESHAPE(dN_dX, [N_NODES, 3, 1])  ! Adapt for API
      nl_args%cfg%ndim = 2  ! Membrane (plane stress)
      nl_args%nlgeom_type = PH_ELEM_NLGEOM_TL
      nl_args%is_valid = .TRUE.
      
      CALL PH_Compute_Deformation_Gradient(nl_args, status)
      IF (.NOT. status%ok()) THEN
        DEALLOCATE(nl_args)
        RETURN
      END IF
      F = nl_args%F
      
      ! Step 2: Compute Green-Lagrange strain E = 0.5*(F^T*F - I)
      CALL PH_Compute_Green_Lagrange_Strain(nl_args, status)
      E_GL = nl_args%E_gl
      
      ! Step 3: Constitutive: S = D:E (2nd PK stress)
      S_PK2(1:3) = MATMUL(D(1:3,1:3), E_GL(1:3))
      S_PK2(4:6) = ZERO  ! Out-of-plane
      
      ! Step 4: Stress transformation (for geometric stiffness)
      CALL PH_Transform_Stress_PK2_to_Cauchy(nl_args, S_PK2, status)
      sigma_cauchy = nl_args%sigma_cauchy
      tau = sigma_cauchy * nl_args%detF  ! Kirchhoff stress
      
      ! Step 5: Build nonlinear B-matrix (strain-displacement)
      ! B_NL relates δE to δu: δE = B_NL * δu
      B_NL = ZERO
      DO node = 1, N_NODES
        ! Linear part: B_lin = [dN/dX, 0; 0, dN/dX; dN/dY, dN/dX]
        B_NL(1, (node-1)*3+1) = dN_dX(node, 1)  ! ∂N/∂X
        B_NL(2, (node-1)*3+2) = dN_dX(node, 2)  ! ∂N/∂Y
        B_NL(3, (node-1)*3+1) = dN_dX(node, 2)  ! ∂N/∂Y (shear)
        B_NL(3, (node-1)*3+2) = dN_dX(node, 1)  ! ∂N/∂X (shear)
      END DO
      
      ! Step 6: Internal force: R_int += ?B_NL^T * S dV_0
      DO i = 1, N_DOF
        R_int(i) = R_int(i) + weight * DOT_PRODUCT(B_NL(:,i), S_PK2(1:3))
      END DO
      
      ! Step 7: Material stiffness: K_mat += ?B_NL^T * D * B_NL dV_0
      DO i = 1, N_DOF
        DO j = 1, N_DOF
          Ke_mat(i,j) = Ke_mat(i,j) + weight * DOT_PRODUCT(B_NL(:,i), MATMUL(D(1:3,1:3), B_NL(:,j)))
        END DO
      END DO
      
      ! Step 8: Geometric stiffness: K_geo += ?G^T * τ * G dV_0
      ! (Simplified for membrane: only in-plane τ_xx, τ_yy, τ_xy)
      DO i = 1, N_DOF
        DO j = 1, N_DOF
          Ke_geo(i,j) = Ke_geo(i,j) + weight * (tau(1)*B_NL(1,i)*B_NL(1,j) + &
                                                tau(2)*B_NL(2,i)*B_NL(2,j) + &
                                                tau(3)*B_NL(3,i)*B_NL(3,j))
        END DO
      END DO
      
      DEALLOCATE(nl_args)
    END DO
    
  END SUBROUTINE PH_Elem_M3D9R_NL_TL

  SUBROUTINE PH_Elem_M3D9R_NL_UL(coords_prev, u_incr, D, thickness, Ke_mat, Ke_geo, R_int, status)
    !--------------------------------------------------------------------------
    ! M3D9R: Updated Lagrangian (UL) formulation - Geometric nonlinearity
    ! Reference: PH_ElemNlgeom_Algo (ST-7.1)
    ! Theory:
    !   - Almansi strain: e = 0.5*(I - F^{-T}*F^{-1})
    !   - Cauchy stress: σ = D:e (objective rate via Truesdell/Jaumann)
    !   - Internal force: R_int = ?B_NL^T * σ dV_t
    !   - Material stiffness: K_mat = ?B_NL^T * D^ep * B_NL dV_t
    !   - Geometric stiffness: K_geo = ?G^T * σ * G dV_t
    !--------------------------------------------------------------------------
    USE PH_Elem_Nlgeom, ONLY: PH_Nlgeom_Args, PH_ELEM_NLGEOM_UL, &
         PH_Compute_Deformation_Gradient, PH_Compute_Almansi_Strain, &
         PH_Compute_B_Matrix_NL
    
    REAL(wp), INTENT(IN)  :: coords_prev(3, 4)   ! Previous configuration [dim, n_nodes]
    REAL(wp), INTENT(IN)  :: u_incr(12)          ! Incremental displacement [n_dof]
    REAL(wp), INTENT(IN)  :: D(6, 6)             ! Constitutive matrix (plane stress)
    REAL(wp), INTENT(IN)  :: thickness           ! Membrane thickness
    REAL(wp), INTENT(OUT) :: Ke_mat(12, 12)      ! Material stiffness
    REAL(wp), INTENT(OUT) :: Ke_geo(12, 12)      ! Geometric stiffness
    REAL(wp), INTENT(OUT) :: R_int(12)           ! Internal force residual
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    !-- Local variables
    INTEGER(i4), PARAMETER :: N_NODES = 4, N_DOF = 12, N_IP = 4
    INTEGER(i4), PARAMETER :: N_STR = 3  ! Plane stress
    INTEGER(i4) :: ip, node, i, j
    REAL(wp) :: coords_cur(3, N_NODES)     ! Current configuration (updated)
    REAL(wp) :: xi_vals(4), eta_vals(4), wts(4)
    REAL(wp) :: N(4), dN_dxi(4, 2)
    REAL(wp) :: dN_dx(4, 3)                ! Spatial derivatives (current)
    REAL(wp) :: detJ, weight
    REAL(wp) :: F(3, 3), e_alm(6)          ! Deformation gradient, Almansi strain
    REAL(wp) :: sigma_cauchy(6)            ! Cauchy stress
    REAL(wp) :: B_NL(3, N_DOF)             ! Nonlinear B-matrix
    REAL(wp) :: dVt                        ! Volume element (current)
    REAL(wp) :: work_mat(N_DOF, N_DOF)
    LOGICAL :: geom_ok
    
    ! Initialize
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    CALL init_error_status(status)
    
    ! Current configuration: x = x_prev + u_incr
    DO node = 1, N_NODES
      coords_cur(1, node) = coords_prev(1, node) + u_incr((node-1)*3 + 1)
      coords_cur(2, node) = coords_prev(2, node) + u_incr((node-1)*3 + 2)
      coords_cur(3, node) = coords_prev(3, node) + u_incr((node-1)*3 + 3)
    END DO
    
    ! 2×2 Gauss quadrature
    xi_vals  = [-ONE/SQRT(THREE), ONE/SQRT(THREE), ONE/SQRT(THREE), -ONE/SQRT(THREE)]
    eta_vals = [-ONE/SQRT(THREE), -ONE/SQRT(THREE), ONE/SQRT(THREE), ONE/SQRT(THREE)]
    wts      = [ONE, ONE, ONE, ONE]
    
    ! Integration loop
    DO ip = 1, N_IP
      ! Shape functions and parametric derivatives
      CALL Memb_Q4_ShapesAndDerivs(xi_vals(ip), eta_vals(ip), N, &
           dN_dxi(1,1), dN_dxi(2,1), dN_dxi(3,1), dN_dxi(4,1), &
           dN_dxi(1,2), dN_dxi(2,2), dN_dxi(3,2), dN_dxi(4,2))
      
      ! Jacobian: dx/dξ (current configuration)
      detJ = ZERO
      dN_dx = ZERO
      DO node = 1, N_NODES
        dN_dx(node, 1) = dN_dxi(node, 1) * coords_cur(1, node) + &
                         dN_dxi(node, 2) * coords_cur(2, node)
        dN_dx(node, 2) = dN_dxi(node, 1) * coords_cur(2, node) + &
                         dN_dxi(node, 2) * coords_cur(3, node)
      END DO
      detJ = coords_cur(1,1)*coords_cur(2,2) - coords_cur(1,2)*coords_cur(2,1)
      
      IF (detJ <= 1.0e-14_wp) THEN
        CALL init_error_status(status, IF_STATUS_INVALID, "Invalid Jacobian")
        RETURN
      END IF
      
      weight = wts(ip) * thickness * detJ
      dVt = weight  ! For membrane: dV_t = t * dA_t
      
      !--- UL Formulation Core ---
      ! Step 1: Compute deformation gradient F (incremental, from prev to cur)
      ALLOCATE(PH_Nlgeom_Args :: nl_args)
      nl_args%coords_ref = coords_prev  ! Previous as "reference" for increment
      nl_args%coords_cur = coords_cur
      nl_args%dN_dxi = RESHAPE(dN_dx, [N_NODES, 3, 1])
      nl_args%cfg%ndim = 2
      nl_args%nlgeom_type = PH_ELEM_NLGEOM_UL
      nl_args%is_valid = .TRUE.
      
      CALL PH_Compute_Deformation_Gradient(nl_args, status)
      IF (.NOT. status%ok()) THEN
        DEALLOCATE(nl_args)
        RETURN
      END IF
      F = nl_args%F
      
      ! Step 2: Compute Almansi strain e = 0.5*(I - F^{-T}*F^{-1})
      CALL PH_Compute_Almansi_Strain(nl_args, status)
      e_alm = nl_args%e_alm
      
      ! Step 3: Constitutive: σ = D:e (Cauchy stress, plane stress)
      sigma_cauchy(1:3) = MATMUL(D(1:3,1:3), e_alm(1:3))
      sigma_cauchy(4:6) = ZERO
      
      ! Step 4: Build nonlinear B-matrix (rate form, spatial)
      B_NL = ZERO
      DO node = 1, N_NODES
        B_NL(1, (node-1)*3+1) = dN_dx(node, 1)  ! ∂N/∂x
        B_NL(2, (node-1)*3+2) = dN_dx(node, 2)  ! ∂N/∂y
        B_NL(3, (node-1)*3+1) = dN_dx(node, 2)  ! ∂N/∂y (shear)
        B_NL(3, (node-1)*3+2) = dN_dx(node, 1)  ! ∂N/∂x (shear)
      END DO
      
      ! Step 5: Internal force: R_int += ?B_NL^T * σ dV_t
      DO i = 1, N_DOF
        R_int(i) = R_int(i) + weight * DOT_PRODUCT(B_NL(:,i), sigma_cauchy(1:3))
      END DO
      
      ! Step 6: Material stiffness: K_mat += ?B_NL^T * D * B_NL dV_t
      DO i = 1, N_DOF
        DO j = 1, N_DOF
          Ke_mat(i,j) = Ke_mat(i,j) + weight * DOT_PRODUCT(B_NL(:,i), MATMUL(D(1:3,1:3), B_NL(:,j)))
        END DO
      END DO
      
      ! Step 7: Geometric stiffness: K_geo += ?G^T * σ * G dV_t
      DO i = 1, N_DOF
        DO j = 1, N_DOF
          Ke_geo(i,j) = Ke_geo(i,j) + weight * (sigma_cauchy(1)*B_NL(1,i)*B_NL(1,j) + &
                                                sigma_cauchy(2)*B_NL(2,i)*B_NL(2,j) + &
                                                sigma_cauchy(3)*B_NL(3,i)*B_NL(3,j))
        END DO
      END DO
      
      DEALLOCATE(nl_args)
    END DO
    
  END SUBROUTINE PH_Elem_M3D9R_NL_UL

  SUBROUTINE UF_Elem_M3D9R_Calc(ElemType, Formul, Ctx, state_in, &
                                 Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, PH_ELEM_M3D9R_NNODE)
    REAL(wp) :: u(PH_ELEM_M3D9R_NDOF)
    REAL(wp) :: E_young, nu
    REAL(wp) :: Ke(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF)
    REAL(wp) :: R_int(PH_ELEM_M3D9R_NDOF)
    REAL(wp) :: Me_work(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF), tloc
    REAL(wp) :: e1(3), e2(3)
    LOGICAL :: geom_ok
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_M3D9R_Calc: coords_ref not allocated'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < PH_ELEM_M3D9R_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_M3D9R_Calc: insufficient nodes in coords_ref'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    DO i = 1, PH_ELEM_M3D9R_NNODE
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
    END DO

    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= PH_ELEM_M3D9R_NNODE) THEN
        DO i = 1, PH_ELEM_M3D9R_NNODE
          IF (SIZE(Ctx%disp_total, 1) >= 3) THEN
            u(3*(i-1)+1) = Ctx%disp_total(1, i)
            u(3*(i-1)+2) = Ctx%disp_total(2, i)
            u(3*(i-1)+3) = Ctx%disp_total(3, i)
          END IF
        END DO
      END IF
    END IF

    E_young = 0.0_wp
    nu = 0.3_wp
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= UF_MAT_PROP_ELA) E_young = Mat%props(UF_MAT_PROP_ELA)
      IF (SIZE(Mat%props) >= UF_MAT_PROP_NU) nu = Mat%props(UF_MAT_PROP_NU)
    END IF

    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_M3D9R_Calc: invalid Young modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    tloc = ONE
    IF (ALLOCATED(Mat%props)) THEN
      IF (SIZE(Mat%props) >= 3_i4) THEN
        IF (Mat%props(3) > 0.0_wp) tloc = Mat%props(3)
      END IF
    END IF

    CALL Memb_M3D9R_LinearCore(coords, E_young, nu, tloc, ZERO, .FALSE., Ke, Me_work, e1, e2, geom_ok)
    IF (.NOT. geom_ok) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_M3D9R_Calc: degenerate membrane geometry'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    R_int = MATMUL(Ke, u)

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, needMass=.FALSE., needDamp=.FALSE.)

    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(PH_ELEM_M3D9R_NDOF, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(PH_ELEM_M3D9R_NDOF, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(PH_ELEM_M3D9R_NDOF, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, PH_ELEM_M3D9R_NIP)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    flags%status%status_code = IF_STATUS_OK
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt
  END SUBROUTINE UF_Elem_M3D9R_Calc

  !=============================================================================
  ! M3D9R: Section
  !=============================================================================
  SUBROUTINE PH_Elem_M3D9R_GetArea(coords, area)
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: e1(3), e2(3), e3(3), x0(3), xl(4), yl(4)
    INTEGER(i4) :: j
    LOGICAL :: ok
    area = ZERO
    CALL Memb_BuildPlaneFrame(coords, e1, e2, e3, x0, ok)
    IF (.NOT. ok) RETURN
    DO j = 1, 4
      xl(j) = DOT_PRODUCT(coords(:, j) - x0, e1)
      yl(j) = DOT_PRODUCT(coords(:, j) - x0, e2)
    END DO
    area = HALF * ABS( &
        xl(1)*yl(2) - xl(2)*yl(1) + xl(2)*yl(3) - xl(3)*yl(2) &
        + xl(3)*yl(4) - xl(4)*yl(3) + xl(4)*yl(1) - xl(1)*yl(4))
  END SUBROUTINE PH_Elem_M3D9R_GetArea

  SUBROUTINE PH_Elem_M3D9R_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: centroid(3)
    INTEGER(i4) :: j
    centroid = ZERO
    DO j = 1, 4
      centroid(:) = centroid(:) + coords(:, j)
    END DO
    centroid = centroid * 0.25_wp
  END SUBROUTINE PH_Elem_M3D9R_GetCentroid

  SUBROUTINE PH_Elem_M3D9R_GetSectProps(coords, density_in, area, mass, thickness)
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(IN) :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    REAL(wp), INTENT(IN), OPTIONAL :: thickness
    REAL(wp) :: tloc
    tloc = ONE
    IF (PRESENT(thickness)) THEN
      IF (thickness > 0.0_wp) tloc = thickness
    END IF
    CALL PH_Elem_M3D9R_GetArea(coords, area)
    mass = density_in * area * tloc
  END SUBROUTINE PH_Elem_M3D9R_GetSectProps

  !=============================================================================
  ! M3D9R: Constraints
  !=============================================================================
  SUBROUTINE PH_Elem_M3D9R_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype, idof
    REAL(wp), INTENT(IN)    :: val, penalty
    REAL(wp), INTENT(INOUT) :: K_el(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF), F_el(PH_ELEM_M3D9R_NDOF)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > PH_ELEM_M3D9R_NDOF) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_M3D9R_ApplyConstraint

  SUBROUTINE PH_Elem_M3D9R_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(PH_ELEM_M3D9R_NDOF)
    REAL(wp), INTENT(IN)    :: val, penalty
    REAL(wp), INTENT(INOUT) :: K_el(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF), F_el(PH_ELEM_M3D9R_NDOF)
    INTEGER(i4) :: i, j
    DO i = 1, PH_ELEM_M3D9R_NDOF
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, PH_ELEM_M3D9R_NDOF
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_M3D9R_ApplyMPC

  !=============================================================================
  ! M3D9R: Contact
  !=============================================================================
  SUBROUTINE PH_Elem_M3D9R_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(4)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF), F_el(PH_ELEM_M3D9R_NDOF)
  END SUBROUTINE PH_Elem_M3D9R_FormContactContrib

  SUBROUTINE PH_Elem_M3D9R_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(PH_ELEM_M3D9R_NDOF, PH_ELEM_M3D9R_NDOF), F_el(PH_ELEM_M3D9R_NDOF)
    K_el = ZERO
    F_el = ZERO
  END SUBROUTINE PH_Elem_M3D9R_FormContactEdgeCtr

  !=============================================================================
  ! M3D9R: Loads
  !=============================================================================
  SUBROUTINE PH_Elem_M3D9R_FormBodyForce(coords, bx, by, bz, F_eq, thickness)
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(IN) :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(PH_ELEM_M3D9R_NDOF)
    REAL(wp), INTENT(IN), OPTIONAL :: thickness
    REAL(wp) :: e1(3), e2(3), e3(3), x0(3), xl(4), yl(4), area, tloc, wn
    INTEGER(i4) :: j
    LOGICAL :: ok
    F_eq = ZERO
    tloc = ONE
    IF (PRESENT(thickness)) THEN
      IF (thickness > 0.0_wp) tloc = thickness
    END IF
    CALL Memb_BuildPlaneFrame(coords, e1, e2, e3, x0, ok)
    IF (.NOT. ok) RETURN
    DO j = 1, 4
      xl(j) = DOT_PRODUCT(coords(:, j) - x0, e1)
      yl(j) = DOT_PRODUCT(coords(:, j) - x0, e2)
    END DO
    area = HALF * ABS( &
        xl(1)*yl(2) - xl(2)*yl(1) + xl(2)*yl(3) - xl(3)*yl(2) &
        + xl(3)*yl(4) - xl(4)*yl(3) + xl(4)*yl(1) - xl(1)*yl(4))
    wn = tloc * area * 0.25_wp
    DO j = 1, 4
      F_eq(3*(j-1)+1) = wn * bx
      F_eq(3*(j-1)+2) = wn * by
      F_eq(3*(j-1)+3) = wn * bz
    END DO
  END SUBROUTINE PH_Elem_M3D9R_FormBodyForce

  SUBROUTINE PH_Elem_M3D9R_FormNodalForce(load_type, coords, val, edge_id, F_eq, thickness)
    INTEGER(i4), INTENT(IN) :: load_type
    REAL(wp), INTENT(IN) :: coords(3, 4)
    REAL(wp), INTENT(IN) :: val(:)
    INTEGER(i4), INTENT(IN) :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(PH_ELEM_M3D9R_NDOF)
    REAL(wp), INTENT(IN), OPTIONAL :: thickness
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY .AND. SIZE(val) >= 3) THEN
      CALL PH_Elem_M3D9R_FormBodyForce(coords, val(1), val(2), val(3), F_eq, thickness)
    END IF
  END SUBROUTINE PH_Elem_M3D9R_FormNodalForce

  !=============================================================================
  ! M3D9R: Output
  !=============================================================================
  SUBROUTINE PH_Elem_M3D9R_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :), ip_strain(:, :), ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    out_vars = ZERO
  END SUBROUTINE PH_Elem_M3D9R_CollectIPVars

  SUBROUTINE PH_Elem_M3D9R_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: sx, sy, sxy
    seq = ZERO
    IF (SIZE(sigma) < 3) RETURN
    sx = sigma(1)
    sy = sigma(2)
    sxy = sigma(3)
    seq = SQRT(MAX(ZERO, sx*sx - sx*sy + sy*sy + THREE*sxy*sxy))
  END SUBROUTINE PH_Elem_M3D9R_EvalVonMises

  SUBROUTINE PH_Elem_M3D9R_EvalMembraneStress(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    CALL PH_Elem_M3D9R_EvalVonMises(sigma, seq)
  END SUBROUTINE PH_Elem_M3D9R_EvalMembraneStress

  SUBROUTINE PH_Elem_M3D9R_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 4)
    INTEGER(i4) :: i
    E = ZERO
    DO i = 1, 4
      E(i, i) = ONE
    END DO
  END SUBROUTINE PH_Elem_M3D9R_GetExtrapMat

  SUBROUTINE PH_Elem_M3D9R_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :), weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    node_vars = ZERO
  END SUBROUTINE PH_Elem_M3D9R_MapToNode

  SUBROUTINE PH_Elem_M3D9R_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                                  stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ElasticPlaneStress

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticPlaneStress(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_M3D9R_Material_Update_Routed

END MODULE PH_Elem_Membrane

