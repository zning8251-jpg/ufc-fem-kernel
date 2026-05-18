!===============================================================================
! MODULE: PH_Elem_C3D27
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Proc
! BRIEF:  C3D27 element definition (27-node quadratic hexahedron)
!===============================================================================
MODULE PH_Elem_C3D27
!> Status: Production | Last verified: 2026-03-01
!> Theory: Element definition and shape functions | Ref: Hughes(2000) FEM Ch.3
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF, QUARTER
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag, PH_RT_Elem_GeomNonlin_UpdLag
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Elem_C3D27_DefInit
  PUBLIC :: PH_Elem_C3D27_ShapeFunc
  PUBLIC :: PH_Elem_C3D27_Jac
  PUBLIC :: PH_Elem_C3D27_BMatrix
  PUBLIC :: PH_Elem_C3D27_GaussPoints
  PUBLIC :: PH_Elem_C3D27_JacB
  PUBLIC :: PH_Elem_C3D27_Strain
  PUBLIC :: PH_Elem_C3D27_Stress
  PUBLIC :: PH_Elem_C3D27_ConstMatrix
  PUBLIC :: PH_Elem_C3D27_StiffMatrix
  PUBLIC :: PH_Elem_C3D27_StiffMatrixSelective
  PUBLIC :: PH_Elem_C3D27_StiffMatrixReduced
  PUBLIC :: PH_Elem_C3D27_StiffMatrixIncompatible
  PUBLIC :: PH_Elem_C3D27_StiffMatrix27
  PUBLIC :: PH_Elem_C3D27_IntForce
  PUBLIC :: PH_Elem_C3D27_IntForceSelective
  PUBLIC :: PH_Elem_C3D27_IntForceReduced
  PUBLIC :: PH_Elem_C3D27_IntForceIncompatible
  PUBLIC :: PH_Elem_C3D27_IntForce27
  PUBLIC :: PH_Elem_C3D27_ConsMass
  PUBLIC :: PH_Elem_C3D27_LumpMass
  PUBLIC :: PH_Elem_C3D27_LumpMassReduced
  PUBLIC :: PH_Elem_C3D27_LumpMass27
  PUBLIC :: PH_Elem_C3D27_ThermStrainVector
  PUBLIC :: PH_Elem_C3D27_GaussPoints27
  PUBLIC :: PH_Elem_C3D27_Volume27
  PUBLIC :: PH_Elem_C3D27_StiffMatrixByVariant
  PUBLIC :: PH_Elem_C3D27_IntForceByVariant
  PUBLIC :: PH_Elem_C3D27_FormStiffMatrix
  PUBLIC :: PH_Elem_C3D27_FormStiffMatrixFromD
  PUBLIC :: PH_Elem_C3D27_FormIntForce
  PUBLIC :: PH_Elem_C3D27_FormIntForceFromStress
  PUBLIC :: PH_Elem_C3D27_FormStiffMatrixByVariant
  PUBLIC :: PH_Elem_C3D27_FormIntForceByVariant
  PUBLIC :: PH_Elem_C3D27_FormGeomStiff
  PUBLIC :: PH_ELEM_GAUSS_PT
  PUBLIC :: PH_ELEM_C3D27_NNODE
  PUBLIC :: PH_ELEM_C3D27_NIP
  PUBLIC :: PH_ELEM_C3D27_NDOF
  PUBLIC :: PH_ELEM_C3D27_NFACE
  PUBLIC :: PH_ELEM_C3D27_FACE_NODES
  PUBLIC :: PH_Elem_C3D27_NL_TL
  PUBLIC :: PH_Elem_C3D27_NL_UL
  PUBLIC :: PH_ELEM_C3D27_VARIANT_STANDARD
  PUBLIC :: PH_ELEM_C3D27_VARIANT_REDUCED
  PUBLIC :: PH_ELEM_C3D27_VARIANT_HYBRID
  PUBLIC :: PH_ELEM_C3D27_VARIANT_INCOMPAT
  PUBLIC :: PH_ELEM_C3D27_VARIANT_MODIFIED
  PUBLIC :: PH_ELEM_C3D27_VARIANT_27PT
  PUBLIC :: PH_Elem_C3D27_GetVolume, PH_Elem_C3D27_GetSectProps, PH_Elem_C3D27_GetCentroid
  PUBLIC :: PH_Elem_C3D27_GetInertiaOrig
  PUBLIC :: PH_Elem_C3D27_ApplyConstraint, PH_Elem_C3D27_ApplyMPC
  PUBLIC :: PH_Elem_C3D27_FormContactContrib, PH_Elem_C3D27_FormContactFaceCtr
  PUBLIC :: PH_Elem_C3D27_FormNodalForce, PH_Elem_C3D27_FormBodyForce, PH_Elem_C3D27_FormFacePressure
  PUBLIC :: PH_Elem_C3D27_CollectIPVars, PH_Elem_C3D27_MapToNode, PH_Elem_C3D27_GetExtrapMat
  PUBLIC :: PH_Elem_C3D27_EvalVonMises, PH_Elem_C3D27_EvalPrincStress
  PUBLIC :: PH_Elem_C3D27_EvalStressInvar, PH_Elem_C3D27_EvalStrainInvar, PH_Elem_C3D27_EvalTriaxiality
  PUBLIC :: PH_Elem_C3D27_Material_Update_Routed
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR, PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_FACE_P = 2_i4

  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_NNODE = 27_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_NIP   = 27_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_NDOF  = 81_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_NFACE  = 6_i4
  ! Variant indices for unified API (C3D27/C3D27R/C3D27H/C3D27I/C3D27M/C3D27S)
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_VARIANT_STANDARD  = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_VARIANT_REDUCED   = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_VARIANT_HYBRID   = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_VARIANT_INCOMPAT = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_VARIANT_MODIFIED = 5_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_VARIANT_27PT    = 6_i4
  ! 2x2x2 Gauss: ?1/sqrt(3), weight 1 per dim -> weight = 1 per IP
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp  ! 1/sqrt(3)
  ! Face topology: face k has nodes PH_ELEM_C3D27_FACE_NODES(1:4, k). Order for outward normal.
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D27_FACE_NODES(4, 6) = RESHAPE([ &
    1,2,3,4, 5,8,7,6, 1,2,6,5, 4,3,7,8, 1,4,8,5, 2,6,7,3 ], [4, 6])
  ! C3D27R: hourglass (Flanagan-Belytschko)
  REAL(wp), PARAMETER :: GAMMA8(8, 4) = RESHAPE([ &
    1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp, &
    1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp, &
    1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp, &
    1.0_wp,  1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp ], [8, 4])
  REAL(wp), PARAMETER :: HG_COEFF = 0.10_wp
  REAL(wp), PARAMETER :: W1 = 8.0_wp
  ! C3D27S: 3-point Gauss ?sqrt(3/5), 0; weights 5/9, 8/9, 5/9
  REAL(wp), PARAMETER :: GP3(3) = [-0.774596669241483_wp, 0.0_wp, 0.774596669241483_wp]
  REAL(wp), PARAMETER :: W3(3)  = [5.0_wp/9.0_wp, 8.0_wp/9.0_wp, 5.0_wp/9.0_wp]

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Sld3D_Args
  TYPE :: PH_Elem_Sld3D_Args
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
  END TYPE PH_Elem_Sld3D_Args


CONTAINS

  SUBROUTINE PH_ELEM_C3D27_BEnhanced(dN_xi, dN_eta, dN_zeta, J_inv, B_enh)
    REAL(wp), INTENT(IN)  :: dN_xi(3), dN_eta(3), dN_zeta(3)
    REAL(wp), INTENT(IN)  :: J_inv(3, 3)
    REAL(wp), INTENT(OUT) :: B_enh(6, 3)
    INTEGER(i4) :: i
    REAL(wp) :: dx(3), dy(3), dz(3)
    DO i = 1, 3
      dx(i) = J_inv(1,1)*dN_xi(i) + J_inv(1,2)*dN_eta(i) + J_inv(1,3)*dN_zeta(i)
      dy(i) = J_inv(2,1)*dN_xi(i) + J_inv(2,2)*dN_eta(i) + J_inv(2,3)*dN_zeta(i)
      dz(i) = J_inv(3,1)*dN_xi(i) + J_inv(3,2)*dN_eta(i) + J_inv(3,3)*dN_zeta(i)
    END DO
    B_enh = ZERO
    DO i = 1, 3
      B_enh(1, i) = dx(i)
      B_enh(2, i) = dy(i)
      B_enh(3, i) = dz(i)
      B_enh(4, i) = dy(i) + dx(i)
      B_enh(5, i) = dz(i) + dy(i)
      B_enh(6, i) = dx(i) + dz(i)
    END DO
  END SUBROUTINE PH_ELEM_C3D27_BEnhanced

  SUBROUTINE PH_ELEM_C3D27_IncompatibleShapeFunc(xi, eta, zeta, N_enh, dN_xi, dN_eta, dN_zeta)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N_enh(3), dN_xi(3), dN_eta(3), dN_zeta(3)
    REAL(wp) :: oxi, oeta, ozeta
    oxi   = ONE - xi*xi
    oeta  = ONE - eta*eta
    ozeta = ONE - zeta*zeta
    N_enh(1) = oxi * oeta * ozeta
    N_enh(2) = xi * oeta * ozeta
    N_enh(3) = eta * oxi * ozeta
    dN_xi(1)  = -2.0_wp*xi * oeta * ozeta
    dN_xi(2)  = oeta * ozeta
    dN_xi(3)  = -2.0_wp*eta*xi * ozeta
    dN_eta(1) = -2.0_wp*eta * oxi * ozeta
    dN_eta(2) = -2.0_wp*xi*eta * ozeta
    dN_eta(3) = oxi * ozeta
    dN_zeta(1)= -2.0_wp*zeta * oxi * oeta
    dN_zeta(2)= -2.0_wp*xi*zeta * oeta
    dN_zeta(3)= -2.0_wp*eta*zeta * oxi
  END SUBROUTINE PH_ELEM_C3D27_IncompatibleShapeFunc

  SUBROUTINE PH_ELEM_C3D27_Inv3x3(A, Ainv, detA)
    REAL(wp), INTENT(IN)  :: A(3, 3)
    REAL(wp), INTENT(OUT) :: Ainv(3, 3)
    REAL(wp), INTENT(OUT) :: detA
    REAL(wp) :: c11, c12, c13, c21, c22, c23, c31, c32, c33
    c11 = A(2,2)*A(3,3) - A(2,3)*A(3,2)
    c12 = -(A(2,1)*A(3,3) - A(2,3)*A(3,1))
    c13 = A(2,1)*A(3,2) - A(2,2)*A(3,1)
    c21 = -(A(1,2)*A(3,3) - A(1,3)*A(3,2))
    c22 = A(1,1)*A(3,3) - A(1,3)*A(3,1)
    c23 = -(A(1,1)*A(3,2) - A(1,2)*A(3,1))
    c31 = A(1,2)*A(2,3) - A(1,3)*A(2,2)
    c32 = -(A(1,1)*A(2,3) - A(1,3)*A(2,1))
    c33 = A(1,1)*A(2,2) - A(1,2)*A(2,1)
    detA = A(1,1)*c11 + A(1,2)*c12 + A(1,3)*c13
    IF (ABS(detA) <= 1.0e-20_wp) THEN
      Ainv = ZERO
      RETURN
    END IF
    Ainv(1,1) = c11/detA
    Ainv(1,2) = c21/detA
    Ainv(1,3) = c31/detA
    Ainv(2,1) = c12/detA
    Ainv(2,2) = c22/detA
    Ainv(2,3) = c32/detA
    Ainv(3,1) = c13/detA
    Ainv(3,2) = c23/detA
    Ainv(3,3) = c33/detA
  END SUBROUTINE PH_ELEM_C3D27_Inv3x3

  SUBROUTINE PH_ELEM_C3D27_Volume_8pt(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_C3D27_Volume_8pt

  SUBROUTINE PH_Elem_C3D27_FormIntForceByVariant(coords, u, E_young, nu, variant, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: u(81)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: R_int(81)
    CALL PH_Elem_C3D27_IntForceByVariant(coords, u, E_young, nu, variant, R_int)
  END SUBROUTINE PH_Elem_C3D27_FormIntForceByVariant

  SUBROUTINE PH_Elem_C3D27_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(81, 81)
    CALL PH_Elem_C3D27_StiffMatrix(coords, E_young, nu, Ke)
  END SUBROUTINE PH_Elem_C3D27_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D27_FormStiffMatrixFromD(coords, D6, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: D6(6, 6)
    REAL(wp), INTENT(OUT) :: Ke(81, 81)
    CALL PH_Elem_C3D27_StiffMatrixFromD(coords, D6, Ke)
  END SUBROUTINE PH_Elem_C3D27_FormStiffMatrixFromD

  SUBROUTINE PH_Elem_C3D27_FormStiffMatrixByVariant(coords, E_young, nu, variant, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: Ke(81, 81)
    CALL PH_Elem_C3D27_StiffMatrixByVariant(coords, E_young, nu, variant, Ke)
  END SUBROUTINE PH_Elem_C3D27_FormStiffMatrixByVariant

  SUBROUTINE PH_Elem_C3D27_IntForceByVariant(coords, u, E_young, nu, variant, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: u(81)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: R_int(81)
    IF (variant == PH_ELEM_C3D27_VARIANT_REDUCED) THEN
      CALL PH_Elem_C3D27_IntForceReduced(coords, u, E_young, nu, R_int)
    ELSE IF (variant == PH_ELEM_C3D27_VARIANT_HYBRID) THEN
      CALL PH_Elem_C3D27_IntForceSelective(coords, u, E_young, nu, R_int)
    ELSE IF (variant == PH_ELEM_C3D27_VARIANT_INCOMPAT) THEN
      CALL PH_Elem_C3D27_IntForceIncompatible(coords, u, E_young, nu, R_int)
    ELSE IF (variant == PH_ELEM_C3D27_VARIANT_27PT) THEN
      CALL PH_Elem_C3D27_IntForce27(coords, u, E_young, nu, R_int)
    ELSE
      CALL PH_Elem_C3D27_IntForce(coords, u, E_young, nu, R_int)
    END IF
  END SUBROUTINE PH_Elem_C3D27_IntForceByVariant

  SUBROUTINE PH_Elem_C3D27_IntForceIncompatible(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: u(81)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(81)
    REAL(wp) :: Ke(81, 81)
    CALL PH_Elem_C3D27_StiffMatrixIncompatible(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_C3D27_IntForceIncompatible

  SUBROUTINE PH_Elem_C3D27_IntForceReduced(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: u(81)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(81)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81), D(6, 6)
    REAL(wp) :: strain(6), sigma(6)
    REAL(wp) :: volume, mu_hg, L_char, invL2, k_hg
    REAL(wp) :: q(3)
    INTEGER(i4) :: i, m, a
    R_int = ZERO
    CALL PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D27_JacB(coords, ZERO, ZERO, ZERO, N, dNdx, J, detJ, B)
    IF (ABS(detJ) > 1.0e-12_wp) THEN
      CALL PH_Elem_C3D27_Strain(B, u, strain)
      CALL PH_Elem_C3D27_Stress(strain, D, sigma)
      R_int = R_int + W1 * detJ * MATMUL(TRANSPOSE(B), sigma)
    END IF
    CALL PH_ELEM_C3D27_Volume_8pt(coords, volume)
    IF (volume <= 1.0e-20_wp) RETURN
    mu_hg = E_young / (2.0_wp * (ONE + nu))
    L_char = volume**(1.0_wp/3.0_wp)
    invL2 = ONE / (L_char * L_char)
    k_hg = HG_COEFF * mu_hg * volume * invL2
    DO m = 1, 4
      q = ZERO
      DO i = 1, 27
        q(1) = q(1) + GAMMA8(i, m) * u(3*(i-1)+1)
        q(2) = q(2) + GAMMA8(i, m) * u(3*(i-1)+2)
        q(3) = q(3) + GAMMA8(i, m) * u(3*(i-1)+3)
      END DO
      DO i = 1, 27
        DO a = 1, 3
          R_int(3*(i-1)+a) = R_int(3*(i-1)+a) + k_hg * GAMMA8(i, m) * q(a)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_IntForceReduced

  SUBROUTINE PH_Elem_C3D27_IntForceSelective(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: u(81)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(81)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81), D(6, 6)
    REAL(wp) :: B_vol(81), B_vol_avg(81), B_mod(6, 81)
    REAL(wp) :: strain(6), sigma(6), dV, volume
    INTEGER(i4) :: ip

    R_int = ZERO
    B_vol_avg = ZERO
    volume = ZERO
    CALL PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      volume = volume + dV
      B_vol(1:81) = (B(1,1:81) + B(2,1:81) + B(3,1:81)) / 3.0_wp
      B_vol_avg(1:81) = B_vol_avg(1:81) + B_vol(1:81) * dV
    END DO
    IF (volume <= 1.0e-20_wp) RETURN
    B_vol_avg(1:81) = B_vol_avg(1:81) / volume

    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      B_vol(1:81) = (B(1,1:81) + B(2,1:81) + B(3,1:81)) / 3.0_wp
      B_mod(1, 1:81) = B(1, 1:81) + (B_vol_avg(1:81) - B_vol(1:81))
      B_mod(2, 1:81) = B(2, 1:81) + (B_vol_avg(1:81) - B_vol(1:81))
      B_mod(3, 1:81) = B(3, 1:81) + (B_vol_avg(1:81) - B_vol(1:81))
      B_mod(4:6, 1:81) = B(4:6, 1:81)
      CALL PH_Elem_C3D27_Strain(B_mod, u, strain)
      CALL PH_Elem_C3D27_Stress(strain, D, sigma)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B_mod), sigma)
    END DO
  END SUBROUTINE PH_Elem_C3D27_IntForceSelective

  SUBROUTINE PH_Elem_C3D27_LumpMassReduced(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(81)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    INTEGER(i4) :: i, d
    M_lumped = ZERO
    CALL PH_Elem_C3D27_ShapeFunc(ZERO, ZERO, ZERO, N, dNdxi)
    CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
    IF (ABS(detJ) > 1.0e-12_wp) THEN
      DO i = 1, 27
        DO d = 1, 3
          M_lumped(3*(i-1)+d) = rho * N(i) * detJ * W1
        END DO
      END DO
    END IF
  END SUBROUTINE PH_Elem_C3D27_LumpMassReduced

  SUBROUTINE PH_Elem_C3D27_StiffMatrixByVariant(coords, E_young, nu, variant, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: Ke(81, 81)
    IF (variant == PH_ELEM_C3D27_VARIANT_REDUCED) THEN
      CALL PH_Elem_C3D27_StiffMatrixReduced(coords, E_young, nu, Ke)
    ELSE IF (variant == PH_ELEM_C3D27_VARIANT_HYBRID) THEN
      CALL PH_Elem_C3D27_StiffMatrixSelective(coords, E_young, nu, Ke)
    ELSE IF (variant == PH_ELEM_C3D27_VARIANT_INCOMPAT) THEN
      CALL PH_Elem_C3D27_StiffMatrixIncompatible(coords, E_young, nu, Ke)
    ELSE IF (variant == PH_ELEM_C3D27_VARIANT_27PT) THEN
      CALL PH_Elem_C3D27_StiffMatrix27(coords, E_young, nu, Ke)
    ELSE
      CALL PH_Elem_C3D27_StiffMatrix(coords, E_young, nu, Ke)
    END IF
  END SUBROUTINE PH_Elem_C3D27_StiffMatrixByVariant

  SUBROUTINE PH_Elem_C3D27_StiffMatrixIncompatible(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(81, 81)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81), D(6, 6)
    REAL(wp) :: J_inv(3, 3)
    REAL(wp) :: N_enh(3), dN_xi(3), dN_eta(3), dN_zeta(3)
    REAL(wp) :: B_enh(6, 3)
    REAL(wp) :: Ke_uu(81, 81), Ke_ua(81, 3), Ke_aa(3, 3)
    REAL(wp) :: Ke_aa_inv(3, 3), tmp(81, 3), det_aa
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    Ke_uu = ZERO
    Ke_ua = ZERO
    Ke_aa = ZERO
    CALL PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      J_inv(1,1) = (J(2,2)*J(3,3)-J(2,3)*J(3,2))/detJ
      J_inv(1,2) = -(J(1,2)*J(3,3)-J(1,3)*J(3,2))/detJ
      J_inv(1,3) = (J(1,2)*J(2,3)-J(1,3)*J(2,2))/detJ
      J_inv(2,1) = -(J(2,1)*J(3,3)-J(2,3)*J(3,1))/detJ
      J_inv(2,2) = (J(1,1)*J(3,3)-J(1,3)*J(3,1))/detJ
      J_inv(2,3) = -(J(1,1)*J(2,3)-J(1,3)*J(2,1))/detJ
      J_inv(3,1) = (J(2,1)*J(3,2)-J(2,2)*J(3,1))/detJ
      J_inv(3,2) = -(J(1,1)*J(3,2)-J(1,2)*J(3,1))/detJ
      J_inv(3,3) = (J(1,1)*J(2,2)-J(1,2)*J(2,1))/detJ
      CALL PH_ELEM_C3D27_IncompatibleShapeFunc(xi(ip), eta(ip), zeta(ip), N_enh, dN_xi, dN_eta, dN_zeta)
      CALL PH_ELEM_C3D27_BEnhanced(dN_xi, dN_eta, dN_zeta, J_inv, B_enh)
      Ke_uu = Ke_uu + dV * MATMUL(MATMUL(TRANSPOSE(B), D), B)
      Ke_ua = Ke_ua + dV * MATMUL(MATMUL(TRANSPOSE(B), D), B_enh)
      Ke_aa = Ke_aa + dV * MATMUL(MATMUL(TRANSPOSE(B_enh), D), B_enh)
    END DO
    CALL PH_ELEM_C3D27_Inv3x3(Ke_aa, Ke_aa_inv, det_aa)
    IF (ABS(det_aa) <= 1.0e-20_wp) THEN
      Ke = Ke_uu
      RETURN
    END IF
    tmp = MATMUL(Ke_ua, Ke_aa_inv)
    Ke = Ke_uu - MATMUL(tmp, TRANSPOSE(Ke_ua))
  END SUBROUTINE PH_Elem_C3D27_StiffMatrixIncompatible

  SUBROUTINE PH_Elem_C3D27_StiffMatrixReduced(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(81, 81)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81), D(6, 6)
    REAL(wp) :: volume, mu_hg, L_char, invL2, k_hg
    REAL(wp) :: BTD(81, 6)
    INTEGER(i4) :: i, j, m, a
    Ke = ZERO
    CALL PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D27_JacB(coords, ZERO, ZERO, ZERO, N, dNdx, J, detJ, B)
    IF (ABS(detJ) > 1.0e-12_wp) THEN
      BTD = MATMUL(TRANSPOSE(B), D)
      Ke = Ke + W1 * detJ * MATMUL(BTD, B)
    END IF
    CALL PH_ELEM_C3D27_Volume_8pt(coords, volume)
    IF (volume <= 1.0e-20_wp) RETURN
    mu_hg = E_young / (2.0_wp * (ONE + nu))
    L_char = volume**(1.0_wp/3.0_wp)
    invL2 = ONE / (L_char * L_char)
    k_hg = HG_COEFF * mu_hg * volume * invL2
    DO m = 1, 4
      DO i = 1, 27
        DO j = 1, 8
          DO a = 1, 3
            Ke(3*(i-1)+a, 3*(j-1)+a) = Ke(3*(i-1)+a, 3*(j-1)+a) + &
              k_hg * GAMMA8(i, m) * GAMMA8(j, m)
          END DO
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_StiffMatrixReduced

  SUBROUTINE PH_Elem_C3D27_StiffMatrixSelective(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(81, 81)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81), D(6, 6)
    REAL(wp) :: B_vol(81), B_vol_avg(81), B_mod(6, 81)
    REAL(wp) :: dV, volume, BTD(81, 6)
    INTEGER(i4) :: ip

    Ke = ZERO
    B_vol_avg = ZERO
    volume = ZERO
    CALL PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      volume = volume + dV
      B_vol(1:81) = (B(1,1:81) + B(2,1:81) + B(3,1:81)) / 3.0_wp
      B_vol_avg(1:81) = B_vol_avg(1:81) + B_vol(1:81) * dV
    END DO
    IF (volume <= 1.0e-20_wp) RETURN
    B_vol_avg(1:81) = B_vol_avg(1:81) / volume

    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      B_vol(1:81) = (B(1,1:81) + B(2,1:81) + B(3,1:81)) / 3.0_wp
      B_mod(1, 1:81) = B(1, 1:81) + (B_vol_avg(1:81) - B_vol(1:81))
      B_mod(2, 1:81) = B(2, 1:81) + (B_vol_avg(1:81) - B_vol(1:81))
      B_mod(3, 1:81) = B(3, 1:81) + (B_vol_avg(1:81) - B_vol(1:81))
      B_mod(4:6, 1:81) = B(4:6, 1:81)
      BTD = MATMUL(TRANSPOSE(B_mod), D)
      Ke = Ke + dV * MATMUL(BTD, B_mod)
    END DO
  END SUBROUTINE PH_Elem_C3D27_StiffMatrixSelective

  SUBROUTINE PH_Elem_C3D27_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(IN)  :: deltaT
    REAL(wp), INTENT(OUT) :: eps_th(6)
    eps_th(1:3) = alpha * deltaT
    eps_th(4:6) = ZERO
  END SUBROUTINE PH_Elem_C3D27_ThermStrainVector

  SUBROUTINE PH_Elem_C3D27_BMatrix(dNdx, B)
    REAL(wp), INTENT(IN)  :: dNdx(3, 27)
    REAL(wp), INTENT(OUT) :: B(6, 81)

    INTEGER(i4) :: i, c

    B = ZERO
    DO i = 1, 27
      c = 3 * (i - 1) + 1
      B(1, c)     = dNdx(1, i)
      B(2, c+1)   = dNdx(2, i)
      B(3, c+2)   = dNdx(3, i)
      B(4, c)     = dNdx(2, i)
      B(4, c+1)   = dNdx(1, i)
      B(5, c+1)   = dNdx(3, i)
      B(5, c+2)   = dNdx(2, i)
      B(6, c)     = dNdx(3, i)
      B(6, c+2)   = dNdx(1, i)
    END DO
  END SUBROUTINE PH_Elem_C3D27_BMatrix

  SUBROUTINE PH_Elem_C3D27_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(81, 81)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    REAL(wp) :: dV, M_scalar
    INTEGER(i4) :: ip, i, j, d

    Me = ZERO
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 27
        DO j = 1, 8
          M_scalar = N(i) * N(j) * dV
          DO d = 1, 3
            Me(3*(i-1)+d, 3*(j-1)+d) = Me(3*(i-1)+d, 3*(j-1)+d) + M_scalar
          END DO
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_ConsMass

  SUBROUTINE PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: D(6, 6)
    REAL(wp) :: lambda, mu, c1, c2
    lambda = E_young * nu / ((ONE + nu) * (ONE - 2.0_wp * nu))
    mu = E_young / (2.0_wp * (ONE + nu))
    c1 = lambda + 2.0_wp * mu
    c2 = lambda
    D = ZERO
    D(1,1) = c1
    D(2,2) = c1
    D(3,3) = c1
    D(1,2) = c2
    D(1,3) = c2
    D(2,1) = c2
    D(2,3) = c2
    D(3,1) = c2
    D(3,2) = c2
    D(4,4) = mu
    D(5,5) = mu
    D(6,6) = mu
  END SUBROUTINE PH_Elem_C3D27_ConstMatrix

  SUBROUTINE PH_Elem_C3D27_DefInit()
    !! No-op: C3D27 has fixed topology (27 nodes, 27 IPs).
  END SUBROUTINE PH_Elem_C3D27_DefInit

  SUBROUTINE PH_Elem_C3D27_FormGeomStiff(coords, sigma, Kg)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: Kg(81, 81)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), dNdx(3, 27), J(3, 3), J_inv(3, 3), detJ
    REAL(wp) :: S(3, 3), GtS(81, 3)
    INTEGER(i4) :: ip, i, j, k, node_i, node_j

    Kg = ZERO
    S(1, 1) = sigma(1)
    S(1, 2) = sigma(4)
    S(1, 3) = sigma(6)
    S(2, 1) = sigma(4)
    S(2, 2) = sigma(2)
    S(2, 3) = sigma(5)
    S(3, 1) = sigma(6)
    S(3, 2) = sigma(5)
    S(3, 3) = sigma(3)
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL PH_ELEM_C3D27_Inv3x3(J, J_inv, detJ)
      dNdx = MATMUL(J_inv, dNdxi)
      ! GtS(i,k) = (G^T S)(i,k); G(i,:)=dNdx at node_i => GtS(i,k)= sum_j dNdx(j,node_i)*S(j,k)
      GtS = ZERO
      DO i = 1, 81
        node_i = (i + 2) / 3
        DO k = 1, 3
          DO j = 1, 3
            GtS(i, k) = GtS(i, k) + dNdx(j, node_i) * S(j, k)
          END DO
        END DO
      END DO
      DO j = 1, 81
        node_j = (j + 2) / 3
        DO i = 1, 81
          Kg(i, j) = Kg(i, j) + (GtS(i, 1)*dNdx(1, node_j) + GtS(i, 2)*dNdx(2, node_j) + GtS(i, 3)*dNdx(3, node_j)) * detJ * weights(ip)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_FormGeomStiff

  SUBROUTINE PH_Elem_C3D27_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: u(81)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(81)
    CALL PH_Elem_C3D27_IntForce(coords, u, E_young, nu, R_int)
  END SUBROUTINE PH_Elem_C3D27_FormIntForce

  !> Internal force from fixed Voigt stress (e.g. material slot), F = sum_gp B^T sigma dV.
  SUBROUTINE PH_Elem_C3D27_FormIntForceFromStress(coords, sigma6, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: sigma6(6)
    REAL(wp), INTENT(OUT) :: R_int(81)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81)
    REAL(wp) :: dV
    INTEGER(i4) :: ip

    R_int = ZERO
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma6)
    END DO
  END SUBROUTINE PH_Elem_C3D27_FormIntForceFromStress

  SUBROUTINE PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(27), eta(27), zeta(27), weights(27)
    INTEGER(i4) :: i, j, k, idx
    idx = 0
    DO i = 1, 3
      DO j = 1, 3
        DO k = 1, 3
          idx = idx + 1
          xi(idx) = GP3(i)
          eta(idx) = GP3(j)
          zeta(idx) = GP3(k)
          weights(idx) = W3(i) * W3(j) * W3(k)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_GaussPoints

  SUBROUTINE PH_Elem_C3D27_GaussPoints27(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(27), eta(27), zeta(27), weights(27)
    INTEGER(i4) :: i, j, k, idx
    idx = 0
    DO i = 1, 3
      DO j = 1, 3
        DO k = 1, 3
          idx = idx + 1
          xi(idx) = GP3(i)
          eta(idx) = GP3(j)
          zeta(idx) = GP3(k)
          weights(idx) = W3(i) * W3(j) * W3(k)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_GaussPoints27

  SUBROUTINE PH_Elem_C3D27_IntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: u(81)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(81)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81), D(6, 6)
    REAL(wp) :: strain(6), sigma(6), dV
    INTEGER(i4) :: ip

    R_int = ZERO
    CALL PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      CALL PH_Elem_C3D27_Strain(B, u, strain)
      CALL PH_Elem_C3D27_Stress(strain, D, sigma)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma)
    END DO
  END SUBROUTINE PH_Elem_C3D27_IntForce

  SUBROUTINE PH_Elem_C3D27_IntForce27(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: u(81)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(81)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81), D(6, 6)
    REAL(wp) :: strain(6), sigma(6), dV
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D27_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      CALL PH_Elem_C3D27_Strain(B, u, strain)
      CALL PH_Elem_C3D27_Stress(strain, D, sigma)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma)
    END DO
  END SUBROUTINE PH_Elem_C3D27_IntForce27

  SUBROUTINE PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 27)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ

    INTEGER(i4) :: i, j, k

    J = ZERO
    DO j = 1, 3
      DO k = 1, 3
        DO i = 1, 27
          J(j, k) = J(j, k) + dNdxi(k, i) * coords(j, i)
        END DO
      END DO
    END DO
    detJ = J(1,1)*(J(2,2)*J(3,3) - J(2,3)*J(3,2)) &
         - J(1,2)*(J(2,1)*J(3,3) - J(2,3)*J(3,1)) &
         + J(1,3)*(J(2,1)*J(3,2) - J(2,2)*J(3,1))
  END SUBROUTINE PH_Elem_C3D27_Jac

  SUBROUTINE PH_Elem_C3D27_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(27)
    REAL(wp), INTENT(OUT) :: dNdx(3, 27)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp), INTENT(OUT) :: B(6, 81)

    REAL(wp) :: dNdxi(3, 27), J_inv(3, 3)
    INTEGER(i4) :: i, j, k

    CALL PH_Elem_C3D27_ShapeFunc(xi, eta, zeta, N, dNdxi)
    CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)

    IF (ABS(detJ) > 1.0e-12_wp) THEN
      ! J_inv = cofactor(J)^T / detJ
      J_inv(1,1) = (J(2,2)*J(3,3) - J(2,3)*J(3,2)) / detJ
      J_inv(1,2) = -(J(1,2)*J(3,3) - J(1,3)*J(3,2)) / detJ
      J_inv(1,3) = (J(1,2)*J(2,3) - J(1,3)*J(2,2)) / detJ
      J_inv(2,1) = -(J(2,1)*J(3,3) - J(2,3)*J(3,1)) / detJ
      J_inv(2,2) = (J(1,1)*J(3,3) - J(1,3)*J(3,1)) / detJ
      J_inv(2,3) = -(J(1,1)*J(2,3) - J(1,3)*J(2,1)) / detJ
      J_inv(3,1) = (J(2,1)*J(3,2) - J(2,2)*J(3,1)) / detJ
      J_inv(3,2) = -(J(1,1)*J(3,2) - J(1,2)*J(3,1)) / detJ
      J_inv(3,3) = (J(1,1)*J(2,2) - J(1,2)*J(2,1)) / detJ
      ! dN_i/dx_j = sum_k J_inv(j,k) * dN_i/dxi_k
      DO i = 1, 27
        DO j = 1, 3
          dNdx(j, i) = ZERO
          DO k = 1, 3
            dNdx(j, i) = dNdx(j, i) + J_inv(j, k) * dNdxi(k, i)
          END DO
        END DO
      END DO
      CALL PH_Elem_C3D27_BMatrix(dNdx, B)
    ELSE
      dNdx = ZERO
      B = ZERO
    END IF
  END SUBROUTINE PH_Elem_C3D27_JacB

  SUBROUTINE PH_Elem_C3D27_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(81)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, d

    M_lumped = ZERO
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 27
        DO d = 1, 3
          M_lumped(3*(i-1)+d) = M_lumped(3*(i-1)+d) + N(i) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_LumpMass

  SUBROUTINE PH_Elem_C3D27_LumpMass27(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(81)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, d
    M_lumped = ZERO
    CALL PH_Elem_C3D27_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 27
        DO d = 1, 3
          M_lumped(3*(i-1)+d) = M_lumped(3*(i-1)+d) + N(i) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_LumpMass27

  SUBROUTINE PH_Elem_C3D27_NL_TL(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_ref(3, 27)
    REAL(wp), INTENT(IN) :: u_elem(81)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(81, 81)
    REAL(wp), INTENT(OUT) :: Ke_geo(81, 81)
    REAL(wp), INTENT(OUT) :: R_int(81)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 27)
    REAL(wp) :: xi_gp(27), eta_gp(27), zeta_gp(27), wt_gp(27)
    REAL(wp) :: N(27), dN_dxi(3, 27), dN_dX(3, 27)
    REAL(wp) :: J_ref(3, 3), det_J, J_inv(3, 3)
    REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
    REAL(wp) :: E_voigt(6)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: K_mat_gp(81, 81), K_geo_gp(81, 81), R_gp(81)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp, j

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 27
      coords_curr(1, i) = coords_ref(1, i) + u_elem(3*(i-1)+1)
      coords_curr(2, i) = coords_ref(2, i) + u_elem(3*(i-1)+2)
      coords_curr(3, i) = coords_ref(3, i) + u_elem(3*(i-1)+3)
    END DO

    CALL PH_Elem_C3D27_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)



    cfg%formulation_typ = 1

    DO igp = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi_gp(igp), eta_gp(igp), zeta_gp(igp), N, dN_dxi)
      CALL PH_Elem_C3D27_Jac(dN_dxi, coords_ref, J_ref, det_J)

      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE

      CALL Invert3x3(J_ref, J_inv, det_J)
      DO i = 1, 27
        dN_dX(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i) + J_inv(1,3)*dN_dxi(3,i)
        dN_dX(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i) + J_inv(2,3)*dN_dxi(3,i)
        dN_dX(3, i) = J_inv(3,1)*dN_dxi(1,i) + J_inv(3,2)*dN_dxi(2,i) + J_inv(3,3)*dN_dxi(3,i)
      END DO

      DO i = 1, 27
        cfg%coords_ref(i, 1) = coords_ref(1, i)
        cfg%coords_ref(i, 2) = coords_ref(2, i)
        cfg%coords_ref(i, 3) = coords_ref(3, i)
        cfg%coords_curr(i, 1) = coords_curr(1, i)
        cfg%coords_curr(i, 2) = coords_curr(2, i)
        cfg%coords_curr(i, 3) = coords_curr(3, i)
        cfg%lcl%dN_dX(i, 1) = dN_dX(1, i)
        cfg%lcl%dN_dX(i, 2) = dN_dX(2, i)
        cfg%lcl%dN_dX(i, 3) = dN_dX(3, i)
      END DO

      ! Compute 3D deformation gradient F = ?x/?X
      F = ZERO
      DO i = 1, 27
        DO j = 1, 3
          F(j, 1) = F(j, 1) + coords_curr(j, i) * cfg%lcl%dN_dX(i, 1)
          F(j, 2) = F(j, 2) + coords_curr(j, i) * cfg%lcl%dN_dX(i, 2)
          F(j, 3) = F(j, 3) + coords_curr(j, i) * cfg%lcl%dN_dX(i, 3)
        END DO
      END DO

      ! Green-Lagrange strain E = 0.5*(F^T*F - I)
      E(1,1) = 0.5_wp * (F(1,1)*F(1,1) + F(2,1)*F(2,1) + F(3,1)*F(3,1) - ONE)
      E(2,2) = 0.5_wp * (F(1,2)*F(1,2) + F(2,2)*F(2,2) + F(3,2)*F(3,2) - ONE)
      E(3,3) = 0.5_wp * (F(1,3)*F(1,3) + F(2,3)*F(2,3) + F(3,3)*F(3,3) - ONE)
      E(1,2) = 0.5_wp * (F(1,1)*F(1,2) + F(2,1)*F(2,2) + F(3,1)*F(3,2))
      E(2,3) = 0.5_wp * (F(1,2)*F(1,3) + F(2,2)*F(2,3) + F(3,2)*F(3,3))
      E(1,3) = 0.5_wp * (F(1,1)*F(1,3) + F(2,1)*F(2,3) + F(3,1)*F(3,3))
      E(2,1) = E(1,2); E(3,2) = E(2,3); E(3,1) = E(1,3)

      ! Voigt notation
      E_voigt(1) = E(1,1); E_voigt(2) = E(2,2); E_voigt(3) = E(3,3)
      E_voigt(4) = E(1,2); E_voigt(5) = E(2,3); E_voigt(6) = E(1,3)

      ! Call Mat constitutive (TL mode)
      ss_gp%strain = E_voigt; ss_gp%strain_inc = E_voigt
      CALL PH_UpdateStress(mat_prop, mat_state(igp), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) THEN
        status%code = IF_STATUS_ERROR

        RETURN
      END IF

      ! Extract 2nd Piola-Kirchhoff stress
      S(1,1) = ss_gp%sigma(1); S(2,2) = ss_gp%sigma(2); S(3,3) = ss_gp%sigma(3)
      S(1,2) = ss_gp%sigma(4); S(2,3) = ss_gp%sigma(5); S(1,3) = ss_gp%sigma(6)
      S(2,1) = S(1,2); S(3,2) = S(2,3); S(3,1) = S(1,3)

      CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
      IF (status%code /= STATUS_SUCCESS) EXIT

      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int = R_int + R_gp * det_J * wt_gp(igp)
    END DO

  CONTAINS
    SUBROUTINE Invert3x3(A, A_inv, det)
      REAL(wp), INTENT(IN) :: A(3, 3)
      REAL(wp), INTENT(OUT) :: A_inv(3, 3), det
      A_inv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) / det
      A_inv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) / det
      A_inv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) / det
      A_inv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) / det
      A_inv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) / det
      A_inv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) / det
      A_inv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) / det
      A_inv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) / det
      A_inv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) / det
    END SUBROUTINE Invert3x3
  END SUBROUTINE PH_Elem_C3D27_NL_TL

  SUBROUTINE PH_Elem_C3D27_NL_UL(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN) :: coords_prev(3, 27)
    REAL(wp), INTENT(IN) :: u_incr(81)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(81, 81)
    REAL(wp), INTENT(OUT) :: Ke_geo(81, 81)
    REAL(wp), INTENT(OUT) :: R_int(81)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: coords_curr(3, 27)
    REAL(wp) :: xi_gp(27), eta_gp(27), zeta_gp(27), wt_gp(27)
    REAL(wp) :: N(27), dN_dxi(3, 27), dN_dx(3, 27)
    REAL(wp) :: J_prev(3, 3), det_J, J_inv(3, 3)
    REAL(wp) :: F(3, 3), epsilon(3, 3), sigma(3, 3)
    REAL(wp) :: b(3,3), b_inv(3,3), det_b
    REAL(wp) :: e_Almansi(3,3)
    REAL(wp) :: E_voigt(6)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    REAL(wp) :: K_mat_gp(81, 81), K_geo_gp(81, 81), R_gp(81)
    TYPE(RT_LagrCfg) :: cfg
    INTEGER(i4) :: i, igp, j

    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    status%code = STATUS_SUCCESS

    DO i = 1, 27
      coords_curr(1, i) = coords_prev(1, i) + u_incr(3*(i-1)+1)
      coords_curr(2, i) = coords_prev(2, i) + u_incr(3*(i-1)+2)
      coords_curr(3, i) = coords_prev(3, i) + u_incr(3*(i-1)+3)
    END DO

    CALL PH_Elem_C3D27_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)



    cfg%formulation_typ = 2

    DO igp = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi_gp(igp), eta_gp(igp), zeta_gp(igp), N, dN_dxi)
      CALL PH_Elem_C3D27_Jac(dN_dxi, coords_prev, J_prev, det_J)

      IF (ABS(det_J) <= 1.0e-12_wp) CYCLE

      CALL Invert3x3(J_prev, J_inv, det_J)
      DO i = 1, 27
        dN_dx(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i) + J_inv(1,3)*dN_dxi(3,i)
        dN_dx(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i) + J_inv(2,3)*dN_dxi(3,i)
        dN_dx(3, i) = J_inv(3,1)*dN_dxi(1,i) + J_inv(3,2)*dN_dxi(2,i) + J_inv(3,3)*dN_dxi(3,i)
      END DO

      DO i = 1, 27
        cfg%coords_prev(i, 1) = coords_prev(1, i)
        cfg%coords_prev(i, 2) = coords_prev(2, i)
        cfg%coords_prev(i, 3) = coords_prev(3, i)
        cfg%coords_curr(i, 1) = coords_curr(1, i)
        cfg%coords_curr(i, 2) = coords_curr(2, i)
        cfg%coords_curr(i, 3) = coords_curr(3, i)
        cfg%dN_dx(i, 1) = dN_dx(1, i)
        cfg%dN_dx(i, 2) = dN_dx(2, i)
        cfg%dN_dx(i, 3) = dN_dx(3, i)
      END DO

      ! Compute 3D deformation gradient F = ?x/?X_prev
      F = ZERO
      DO i = 1, 27
        DO j = 1, 3
          F(j, 1) = F(j, 1) + coords_curr(j, i) * cfg%dN_dx(i, 1)
          F(j, 2) = F(j, 2) + coords_curr(j, i) * cfg%dN_dx(i, 2)
          F(j, 3) = F(j, 3) + coords_curr(j, i) * cfg%dN_dx(i, 3)
        END DO
      END DO

      ! Left Cauchy-Green tensor b = F*F^T
      b(1,1) = F(1,1)*F(1,1) + F(1,2)*F(1,2) + F(1,3)*F(1,3)
      b(2,2) = F(2,1)*F(2,1) + F(2,2)*F(2,2) + F(2,3)*F(2,3)
      b(3,3) = F(3,1)*F(3,1) + F(3,2)*F(3,2) + F(3,3)*F(3,3)
      b(1,2) = F(1,1)*F(2,1) + F(1,2)*F(2,2) + F(1,3)*F(2,3)
      b(2,3) = F(2,1)*F(3,1) + F(2,2)*F(3,2) + F(2,3)*F(3,3)
      b(1,3) = F(1,1)*F(3,1) + F(1,2)*F(3,2) + F(1,3)*F(3,3)
      b(2,1) = b(1,2); b(3,2) = b(2,3); b(3,1) = b(1,3)

      ! Compute b^{-1}
      det_b = b(1,1)*(b(2,2)*b(3,3) - b(2,3)*b(3,2)) - b(1,2)*(b(2,1)*b(3,3) - b(2,3)*b(3,1)) + b(1,3)*(b(2,1)*b(3,2) - b(2,2)*b(3,1))
      IF (ABS(det_b) <= 1.0e-14_wp) CYCLE
      b_inv(1,1) = (b(2,2)*b(3,3) - b(2,3)*b(3,2)) / det_b
      b_inv(1,2) = (b(1,3)*b(3,2) - b(1,2)*b(3,3)) / det_b
      b_inv(1,3) = (b(1,2)*b(2,3) - b(1,3)*b(2,2)) / det_b
      b_inv(2,1) = (b(2,3)*b(3,1) - b(2,1)*b(3,3)) / det_b
      b_inv(2,2) = (b(1,1)*b(3,3) - b(1,3)*b(3,1)) / det_b
      b_inv(2,3) = (b(1,3)*b(2,1) - b(1,1)*b(2,3)) / det_b
      b_inv(3,1) = (b(2,1)*b(3,2) - b(2,2)*b(3,1)) / det_b
      b_inv(3,2) = (b(1,2)*b(3,1) - b(1,1)*b(3,2)) / det_b
      b_inv(3,3) = (b(1,1)*b(2,2) - b(1,2)*b(2,1)) / det_b

      ! Almansi strain e = 0.5*(I - b^{-1})
      e_Almansi(1,1) = 0.5_wp * (ONE - b_inv(1,1))
      e_Almansi(2,2) = 0.5_wp * (ONE - b_inv(2,2))
      e_Almansi(3,3) = 0.5_wp * (ONE - b_inv(3,3))
      e_Almansi(1,2) = -0.5_wp * b_inv(1,2)
      e_Almansi(2,3) = -0.5_wp * b_inv(2,3)
      e_Almansi(1,3) = -0.5_wp * b_inv(1,3)
      e_Almansi(2,1) = e_Almansi(1,2); e_Almansi(3,2) = e_Almansi(2,3); e_Almansi(3,1) = e_Almansi(1,3)

      ! Voigt notation
      E_voigt(1) = e_Almansi(1,1); E_voigt(2) = e_Almansi(2,2); E_voigt(3) = e_Almansi(3,3)
      E_voigt(4) = e_Almansi(1,2); E_voigt(5) = e_Almansi(2,3); E_voigt(6) = e_Almansi(1,3)

      ! Call Mat constitutive (UL mode)
      ss_gp%strain = E_voigt; ss_gp%strain_inc = E_voigt
      CALL PH_UpdateStress(mat_prop, mat_state(igp), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) THEN
        status%code = IF_STATUS_ERROR

        RETURN
      END IF

      ! Extract Cauchy stress
      sigma(1,1) = ss_gp%sigma(1); sigma(2,2) = ss_gp%sigma(2); sigma(3,3) = ss_gp%sigma(3)
      sigma(1,2) = ss_gp%sigma(4); sigma(2,3) = ss_gp%sigma(5); sigma(1,3) = ss_gp%sigma(6)
      sigma(2,1) = sigma(1,2); sigma(3,2) = sigma(2,3); sigma(3,1) = sigma(1,3)

      CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, status, R_gp, ss_gp%tangent)
      IF (status%code /= STATUS_SUCCESS) EXIT

      Ke_mat = Ke_mat + K_mat_gp * det_J * wt_gp(igp)
      Ke_geo = Ke_geo + K_geo_gp * det_J * wt_gp(igp)
      R_int = R_int + R_gp * det_J * wt_gp(igp)
    END DO

  CONTAINS
    SUBROUTINE Invert3x3(A, A_inv, det)
      REAL(wp), INTENT(IN) :: A(3, 3)
      REAL(wp), INTENT(OUT) :: A_inv(3, 3), det
      A_inv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) / det
      A_inv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) / det
      A_inv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) / det
      A_inv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) / det
      A_inv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) / det
      A_inv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) / det
      A_inv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) / det
      A_inv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) / det
      A_inv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) / det
    END SUBROUTINE Invert3x3
  END SUBROUTINE PH_Elem_C3D27_NL_UL

  SUBROUTINE PH_Elem_C3D27_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(27)
    REAL(wp), INTENT(OUT) :: dNdxi(3, 27)
    REAL(wp) :: L_xi(3), L_eta(3), L_zeta(3), dL_xi(3), dL_eta(3), dL_zeta(3)
    INTEGER(i4) :: xi_p(27), eta_p(27), zeta_p(27)
    INTEGER(i4) :: i, ix, iy, iz
    ! 1D Lagrange at -1,0,1: L_{-1}=s(s-1)/2, L_0=1-s^2, L_1=s(s+1)/2
    L_xi(1) = xi * (xi - ONE) * HALF
    L_xi(2) = ONE - xi * xi
    L_xi(3) = xi * (xi + ONE) * HALF
    dL_xi(1) = (xi - HALF)
    dL_xi(2) = -2.0_wp * xi
    dL_xi(3) = (xi + HALF)
    L_eta(1) = eta * (eta - ONE) * HALF
    L_eta(2) = ONE - eta * eta
    L_eta(3) = eta * (eta + ONE) * HALF
    dL_eta(1) = (eta - HALF)
    dL_eta(2) = -2.0_wp * eta
    dL_eta(3) = (eta + HALF)
    L_zeta(1) = zeta * (zeta - ONE) * HALF
    L_zeta(2) = ONE - zeta * zeta
    L_zeta(3) = zeta * (zeta + ONE) * HALF
    dL_zeta(1) = (zeta - HALF)
    dL_zeta(2) = -2.0_wp * zeta
    dL_zeta(3) = (zeta + HALF)
    ! Node ordering: corners 1-8 (ix,iy,iz = 1 or 3), edges 9-20, faces 21-26, center 27
    ! Map: (xi,eta,zeta)_i in {-1,0,1} -> index 1,2,3. Node i: xi_p(i), eta_p(i), zeta_p(i) in {1,2,3}
    xi_p(1:27) = [1,3,3,1, 1,3,3,1, 2,3,2,1, 1,3,3,1, 2,3,2,1, 2,2,1,3,2,2,2]
    eta_p(1:27)= [1,1,3,3, 1,1,3,3, 1,2,3,2, 1,1,3,3, 1,2,3,2, 2,2,2,2,1,3,2]
    zeta_p(1:27)=[1,1,1,1, 3,3,3,3, 1,1,1,1, 2,2,2,2, 3,3,3,3, 1,3,2,2,2,2,2]
    DO i = 1, 27
      ix = xi_p(i)
      iy = eta_p(i)
      iz = zeta_p(i)
      N(i) = L_xi(ix) * L_eta(iy) * L_zeta(iz)
      dNdxi(1, i) = dL_xi(ix) * L_eta(iy) * L_zeta(iz)
      dNdxi(2, i) = L_xi(ix) * dL_eta(iy) * L_zeta(iz)
      dNdxi(3, i) = L_xi(ix) * L_eta(iy) * dL_zeta(iz)
    END DO
  END SUBROUTINE PH_Elem_C3D27_ShapeFunc

  SUBROUTINE PH_Elem_C3D27_StiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(81, 81)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81), D(6, 6)
    REAL(wp) :: BTD(81, 6), dV
    INTEGER(i4) :: ip, i, j, k

    Ke = ZERO
    CALL PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      ! Ke += B^T D B * dV
      BTD = MATMUL(TRANSPOSE(B), D)
      Ke = Ke + dV * MATMUL(BTD, B)
    END DO
  END SUBROUTINE PH_Elem_C3D27_StiffMatrix

  !> Stiffness from caller-supplied 6x6 tangent (e.g. C_tan from material slot).
  SUBROUTINE PH_Elem_C3D27_StiffMatrixFromD(coords, D6, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: D6(6, 6)
    REAL(wp), INTENT(OUT) :: Ke(81, 81)

    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81)
    REAL(wp) :: BTD(81, 6), dV
    INTEGER(i4) :: ip

    Ke = ZERO
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(B), D6)
      Ke = Ke + dV * MATMUL(BTD, B)
    END DO
  END SUBROUTINE PH_Elem_C3D27_StiffMatrixFromD

  SUBROUTINE PH_Elem_C3D27_StiffMatrix27(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(81, 81)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdx(3, 27), J(3, 3), detJ, B(6, 81), D(6, 6)
    REAL(wp) :: BTD(81, 6), dV
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_C3D27_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D27_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(B), D)
      Ke = Ke + dV * MATMUL(BTD, B)
    END DO
  END SUBROUTINE PH_Elem_C3D27_StiffMatrix27

  SUBROUTINE PH_Elem_C3D27_Strain(B, u, strain)
    REAL(wp), INTENT(IN)  :: B(6, 81)
    REAL(wp), INTENT(IN)  :: u(81)
    REAL(wp), INTENT(OUT) :: strain(6)
    INTEGER(i4) :: i, j
    strain = ZERO
    DO i = 1, 6
      DO j = 1, 81
        strain(i) = strain(i) + B(i, j) * u(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_Strain

  SUBROUTINE PH_Elem_C3D27_Stress(epsilon, D, sigma)
    REAL(wp), INTENT(IN)  :: epsilon(6)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: sigma(6)
    INTEGER(i4) :: i, j
    sigma = ZERO
    DO i = 1, 6
      DO j = 1, 6
        sigma(i) = sigma(i) + D(i, j) * epsilon(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_Stress

  SUBROUTINE PH_Elem_C3D27_Volume27(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D27_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D27_Volume27

  ! ---- Sect ----
  SUBROUTINE PH_Elem_C3D27_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    REAL(wp) :: volume, dV
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 3
        DO j = 1, 27
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / volume
      centroid(2) = centroid(2) / volume
      centroid(3) = centroid(3) / volume
    END IF
  END SUBROUTINE PH_Elem_C3D27_GetCentroid

  SUBROUTINE PH_Elem_C3D27_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(3, 3)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    REAL(wp) :: x(3), r2, dV
    INTEGER(i4) :: ip, i, j, k
    I_out = ZERO
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      dV = rho * detJ * weights(ip)
      x(1) = ZERO
      x(2) = ZERO
      x(3) = ZERO
      DO k = 1, 27
        x(1) = x(1) + N(k) * coords(1, k)
        x(2) = x(2) + N(k) * coords(2, k)
        x(3) = x(3) + N(k) * coords(3, k)
      END DO
      r2 = x(1)*x(1) + x(2)*x(2) + x(3)*x(3)
      DO i = 1, 3
        DO j = 1, 3
          I_out(i, j) = I_out(i, j) - x(i) * x(j) * dV
        END DO
        I_out(i, i) = I_out(i, i) + r2 * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_GetInertiaOrig

  SUBROUTINE PH_Elem_C3D27_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp), INTENT(OUT) :: mass
    CALL PH_Elem_C3D27_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D27_GetSectProps

  SUBROUTINE PH_Elem_C3D27_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D27_GetVolume

  ! ---- Constraints ----
  SUBROUTINE PH_Elem_C3D27_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(81, 81)
    REAL(wp), INTENT(INOUT) :: F_el(81)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 81) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_C3D27_ApplyConstraint

  SUBROUTINE PH_Elem_C3D27_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(81)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(81, 81)
    REAL(wp), INTENT(INOUT) :: F_el(81)
    INTEGER(i4) :: i, j
    DO i = 1, 81
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 81
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_ApplyMPC

  ! ---- Cont ----
  SUBROUTINE PH_Elem_C3D27_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(IN)  :: N(27)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(81, 81)
    REAL(wp), INTENT(INOUT) :: F_el(81)
    REAL(wp) :: f_a(3), k_ab
    INTEGER(i4) :: a, b, ia, ib
    DO a = 1, 27
      ia = 3 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * n(1)
      f_a(2) = penalty * gap * N(a) * n(2)
      f_a(3) = penalty * gap * N(a) * n(3)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
      F_el(ia+2) = F_el(ia+2) + f_a(3)
    END DO
    DO a = 1, 27
      DO b = 1, 27
        k_ab = penalty * N(a) * N(b)
        ia = 3 * (a - 1) + 1
        ib = 3 * (b - 1) + 1
        K_el(ia,   ib)   = K_el(ia,   ib)   + k_ab * n(1) * n(1)
        K_el(ia,   ib+1) = K_el(ia,   ib+1) + k_ab * n(1) * n(2)
        K_el(ia,   ib+2) = K_el(ia,   ib+2) + k_ab * n(1) * n(3)
        K_el(ia+1, ib)   = K_el(ia+1, ib)   + k_ab * n(2) * n(1)
        K_el(ia+1, ib+1) = K_el(ia+1, ib+1) + k_ab * n(2) * n(2)
        K_el(ia+1, ib+2) = K_el(ia+1, ib+2) + k_ab * n(2) * n(3)
        K_el(ia+2, ib)   = K_el(ia+2, ib)   + k_ab * n(3) * n(1)
        K_el(ia+2, ib+1) = K_el(ia+2, ib+1) + k_ab * n(3) * n(2)
        K_el(ia+2, ib+2) = K_el(ia+2, ib+2) + k_ab * n(3) * n(3)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_FormContactContrib

  SUBROUTINE PH_Elem_C3D27_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(81, 81)
    REAL(wp), INTENT(INOUT) :: F_el(81)
    REAL(wp) :: xi, eta, zeta, N(27), n(3), dNdxi(3, 27)
    REAL(wp) :: r(3), dr_dxi(3), dr_deta(3)
    INTEGER(i4) :: nodes(4), i
    SELECT CASE (face_id)
    CASE (1)
      xi = 0.0_wp
      eta = 0.0_wp
      zeta = -ONE
      nodes(1) = 1
      nodes(2) = 2
      nodes(3) = 3
      nodes(4) = 4
    CASE (2)
      xi = 0.0_wp
      eta = 0.0_wp
      zeta = ONE
      nodes(1) = 5
      nodes(2) = 8
      nodes(3) = 7
      nodes(4) = 6
    CASE (3)
      xi = 0.0_wp
      eta = -ONE
      zeta = 0.0_wp
      nodes(1) = 1
      nodes(2) = 2
      nodes(3) = 6
      nodes(4) = 5
    CASE (4)
      xi = 0.0_wp
      eta = ONE
      zeta = 0.0_wp
      nodes(1) = 4
      nodes(2) = 3
      nodes(3) = 7
      nodes(4) = 8
    CASE (5)
      xi = -ONE
      eta = 0.0_wp
      zeta = 0.0_wp
      nodes(1) = 1
      nodes(2) = 4
      nodes(3) = 8
      nodes(4) = 5
    CASE (6)
      xi = ONE
      eta = 0.0_wp
      zeta = 0.0_wp
      nodes(1) = 2
      nodes(2) = 6
      nodes(3) = 7
      nodes(4) = 3
    CASE DEFAULT
      RETURN
    END SELECT
    CALL PH_Elem_C3D27_ShapeFunc(xi, eta, zeta, N, dNdxi)
    r(1) = ZERO
    r(2) = ZERO
    r(3) = ZERO
    dr_dxi(1) = ZERO
    dr_dxi(2) = ZERO
    dr_dxi(3) = ZERO
    dr_deta(1) = ZERO
    dr_deta(2) = ZERO
    dr_deta(3) = ZERO
    IF (face_id <= 2) THEN
      DO i = 1, 4
        r(1) = r(1) + N(nodes(i)) * coords(1, nodes(i))
        r(2) = r(2) + N(nodes(i)) * coords(2, nodes(i))
        r(3) = r(3) + N(nodes(i)) * coords(3, nodes(i))
        dr_dxi(1) = dr_dxi(1) + dNdxi(1, nodes(i)) * coords(1, nodes(i))
        dr_dxi(2) = dr_dxi(2) + dNdxi(1, nodes(i)) * coords(2, nodes(i))
        dr_dxi(3) = dr_dxi(3) + dNdxi(1, nodes(i)) * coords(3, nodes(i))
        dr_deta(1) = dr_deta(1) + dNdxi(2, nodes(i)) * coords(1, nodes(i))
        dr_deta(2) = dr_deta(2) + dNdxi(2, nodes(i)) * coords(2, nodes(i))
        dr_deta(3) = dr_deta(3) + dNdxi(2, nodes(i)) * coords(3, nodes(i))
      END DO
      n(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
      n(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
      n(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
      IF (face_id == 1) THEN
        n(1) = -n(1)
        n(2) = -n(2)
        n(3) = -n(3)
      END IF
    ELSE IF (face_id <= 4) THEN
      DO i = 1, 4
        dr_dxi(1) = dr_dxi(1) + dNdxi(1, nodes(i)) * coords(1, nodes(i))
        dr_dxi(2) = dr_dxi(2) + dNdxi(1, nodes(i)) * coords(2, nodes(i))
        dr_dxi(3) = dr_dxi(3) + dNdxi(1, nodes(i)) * coords(3, nodes(i))
        dr_deta(1) = dr_deta(1) + dNdxi(3, nodes(i)) * coords(1, nodes(i))
        dr_deta(2) = dr_deta(2) + dNdxi(3, nodes(i)) * coords(2, nodes(i))
        dr_deta(3) = dr_deta(3) + dNdxi(3, nodes(i)) * coords(3, nodes(i))
      END DO
      n(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
      n(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
      n(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
      IF (face_id == 3) THEN
        n(1) = -n(1)
        n(2) = -n(2)
        n(3) = -n(3)
      END IF
    ELSE
      DO i = 1, 4
        dr_dxi(1) = dr_dxi(1) + dNdxi(2, nodes(i)) * coords(1, nodes(i))
        dr_dxi(2) = dr_dxi(2) + dNdxi(2, nodes(i)) * coords(2, nodes(i))
        dr_dxi(3) = dr_dxi(3) + dNdxi(2, nodes(i)) * coords(3, nodes(i))
        dr_deta(1) = dr_deta(1) + dNdxi(3, nodes(i)) * coords(1, nodes(i))
        dr_deta(2) = dr_deta(2) + dNdxi(3, nodes(i)) * coords(2, nodes(i))
        dr_deta(3) = dr_deta(3) + dNdxi(3, nodes(i)) * coords(3, nodes(i))
      END DO
      n(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
      n(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
      n(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
      IF (face_id == 5) THEN
        n(1) = -n(1)
        n(2) = -n(2)
        n(3) = -n(3)
      END IF
    END IF
    IF (SUM(n**2) > 1.0e-20_wp) THEN
      r(1) = SQRT(SUM(n**2))
      n(1) = n(1) / r(1)
      n(2) = n(2) / r(1)
      n(3) = n(3) / r(1)
    END IF
    CALL PH_Elem_C3D27_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
  END SUBROUTINE PH_Elem_C3D27_FormContactFaceCtr

  ! ---- Loads ---- (FormFacePressure, FormBodyForce, FormNodalForce from Loads)
  SUBROUTINE PH_Elem_C3D27_FormFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(81)
    REAL(wp) :: N(27), dNdxi(3, 27)
    REAL(wp) :: r(3), dr_dxi(3), dr_deta(3), nvec(3), dA
    REAL(wp) :: xi_f(4), eta_f(4), w_f(4)
    INTEGER(i4) :: ip, i, nodes(4)
    REAL(wp) :: u, v, xi, et, zet
    F_eq = ZERO
    xi_f(1) = -PH_ELEM_GAUSS_PT
    xi_f(2) = PH_ELEM_GAUSS_PT
    xi_f(3) = -PH_ELEM_GAUSS_PT
    xi_f(4) = PH_ELEM_GAUSS_PT
    eta_f(1) = -PH_ELEM_GAUSS_PT
    eta_f(2) = -PH_ELEM_GAUSS_PT
    eta_f(3) = PH_ELEM_GAUSS_PT
    eta_f(4) = PH_ELEM_GAUSS_PT
    w_f(1) = ONE
    w_f(2) = ONE
    w_f(3) = ONE
    w_f(4) = ONE
    SELECT CASE (face_id)
    CASE (1)
      nodes = [1, 2, 3, 4]
      zet = -ONE
      DO ip = 1, 4
        u = xi_f(ip)
        v = eta_f(ip)
        xi = u
        et = v
        CALL PH_Elem_C3D27_ShapeFunc(xi, et, zet, N, dNdxi)
        r = ZERO
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          r = r + N(nodes(i)) * coords(:, nodes(i))
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(nvec(1)**2 + nvec(2)**2 + nvec(3)**2)
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = -nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (2)
      nodes = [5, 8, 7, 6]
      zet = ONE
      DO ip = 1, 4
        u = xi_f(ip)
        v = eta_f(ip)
        xi = u
        et = v
        CALL PH_Elem_C3D27_ShapeFunc(xi, et, zet, N, dNdxi)
        r = ZERO
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          r = r + N(nodes(i)) * coords(:, nodes(i))
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(nvec(1)**2 + nvec(2)**2 + nvec(3)**2)
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (3)
      nodes = [1, 2, 6, 5]
      et = -ONE
      DO ip = 1, 4
        xi = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D27_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = -nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (4)
      nodes = [4, 3, 7, 8]
      et = ONE
      DO ip = 1, 4
        xi = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D27_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (5)
      nodes = [1, 4, 8, 5]
      xi = -ONE
      DO ip = 1, 4
        et = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D27_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(2, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = -nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE (6)
      nodes = [2, 6, 7, 3]
      xi = ONE
      DO ip = 1, 4
        et = xi_f(ip)
        zet = eta_f(ip)
        CALL PH_Elem_C3D27_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(2, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        nvec(1) = dr_dxi(2)*dr_deta(3) - dr_dxi(3)*dr_deta(2)
        nvec(2) = dr_dxi(3)*dr_deta(1) - dr_dxi(1)*dr_deta(3)
        nvec(3) = dr_dxi(1)*dr_deta(2) - dr_dxi(2)*dr_deta(1)
        dA = SQRT(SUM(nvec**2))
        IF (dA < 1.0e-15_wp) CYCLE
        nvec = nvec / dA
        DO i = 1, 4
          F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) = F_eq(3*(nodes(i)-1)+1:3*(nodes(i)-1)+3) &
            + N(nodes(i)) * p * nvec * dA * w_f(ip)
        END DO
      END DO
    CASE DEFAULT
    END SELECT
  END SUBROUTINE PH_Elem_C3D27_FormFacePressure

  SUBROUTINE PH_Elem_C3D27_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(81)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 27
        F_eq(3*(i-1)+1) = F_eq(3*(i-1)+1) + N(i) * bx * detJ * weights(ip)
        F_eq(3*(i-1)+2) = F_eq(3*(i-1)+2) + N(i) * by * detJ * weights(ip)
        F_eq(3*(i-1)+3) = F_eq(3*(i-1)+3) + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_FormBodyForce

  SUBROUTINE PH_Elem_C3D27_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 27)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(81)
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_C3D27_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D27_FormFacePressure(coords, val(1), face_id, F_eq)
    END IF
  END SUBROUTINE PH_Elem_C3D27_FormNodalForce

  ! ---- Out ----
  SUBROUTINE invert_27x27(A, info)
    REAL(wp), INTENT(INOUT) :: A(27, 27)
    INTEGER(i4), INTENT(OUT) :: info
    REAL(wp) :: B(27, 27)
    INTEGER(i4) :: i, k
    REAL(wp) :: fac
    B = A
    A = ZERO
    DO i = 1, 27
      A(i, i) = ONE
    END DO
    info = 0
    DO k = 1, 27
      IF (ABS(B(k, k)) < 1.0e-14_wp) THEN
        info = -1
        RETURN
      END IF
      fac = ONE / B(k, k)
      B(k, :) = B(k, :) * fac
      A(k, :) = A(k, :) * fac
      DO i = 1, 27
        IF (i == k) CYCLE
        fac = B(i, k)
        B(i, :) = B(i, :) - fac * B(k, :)
        A(i, :) = A(i, :) - fac * A(k, :)
      END DO
    END DO
  END SUBROUTINE invert_27x27

  SUBROUTINE PH_Elem_C3D27_EvalPrincStress(sigma, principal)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: principal(3)
    REAL(wp) :: s(3,3), p, q, r, phi, a
    INTEGER(i4) :: i
    s(1,1) = sigma(1)
    s(2,2) = sigma(2)
    s(3,3) = sigma(3)
    s(1,2) = sigma(4)
    s(2,1) = sigma(4)
    s(2,3) = sigma(5)
    s(3,2) = sigma(5)
    s(1,3) = sigma(6)
    s(3,1) = sigma(6)
    p = (s(1,1) + s(2,2) + s(3,3)) / 3.0_wp
    q = (s(1,1)*s(2,2) + s(2,2)*s(3,3) + s(3,3)*s(1,1) - s(1,2)**2 - s(2,3)**2 - s(1,3)**2) / 3.0_wp - p**2
    r = (s(1,1)-p)*(s(2,2)-p)*(s(3,3)-p) + 2.0_wp*s(1,2)*s(2,3)*s(1,3) &
        - (s(1,1)-p)*s(2,3)**2 - (s(2,2)-p)*s(1,3)**2 - (s(3,3)-p)*s(1,2)**2
    r = r / 2.0_wp
    IF (q <= 1.0e-20_wp) THEN
      principal(1) = p
      principal(2) = p
      principal(3) = p
      RETURN
    END IF
    a = SQRT(MAX(q, ZERO))
    IF (ABS(a) < 1.0e-20_wp) THEN
      principal(1) = p
      principal(2) = p
      principal(3) = p
      RETURN
    END IF
    r = MAX(-ONE, MIN(ONE, r / (a**3)))
    phi = ACOS(r) / 3.0_wp
    principal(1) = p + 2.0_wp * a * COS(phi)
    principal(2) = p + 2.0_wp * a * COS(phi - 8.0_wp*ATAN(1.0_wp)/3.0_wp)
    principal(3) = p + 2.0_wp * a * COS(phi + 8.0_wp*ATAN(1.0_wp)/3.0_wp)
    IF (principal(1) < principal(2)) THEN
      a = principal(1)
      principal(1) = principal(2)
      principal(2) = a
    END IF
    IF (principal(2) < principal(3)) THEN
      a = principal(2)
      principal(2) = principal(3)
      principal(3) = a
    END IF
    IF (principal(1) < principal(2)) THEN
      a = principal(1)
      principal(1) = principal(2)
      principal(2) = a
    END IF
  END SUBROUTINE PH_Elem_C3D27_EvalPrincStress

  SUBROUTINE PH_Elem_C3D27_EvalStrainInvar(strain, I1e, J2e)
    REAL(wp), INTENT(IN)  :: strain(6)
    REAL(wp), INTENT(OUT) :: I1e, J2e
    REAL(wp) :: em, edev(6)
    I1e = strain(1) + strain(2) + strain(3)
    em = I1e / 3.0_wp
    edev(1:3) = strain(1:3) - em
    edev(4:6) = strain(4:6)
    J2e = HALF * (edev(1)*edev(1) + edev(2)*edev(2) + edev(3)*edev(3)) &
          + edev(4)*edev(4) + edev(5)*edev(5) + edev(6)*edev(6)
  END SUBROUTINE PH_Elem_C3D27_EvalStrainInvar

  SUBROUTINE PH_Elem_C3D27_EvalStressInvar(sigma, I1, J2, J3)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: I1, J2, J3
    REAL(wp) :: p, sdev(6), s3(3, 3)
    I1 = sigma(1) + sigma(2) + sigma(3)
    p = I1 / 3.0_wp
    sdev(1:3) = sigma(1:3) - p
    sdev(4:6) = sigma(4:6)
    J2 = HALF * (sdev(1)*sdev(1) + sdev(2)*sdev(2) + sdev(3)*sdev(3)) &
         + sdev(4)*sdev(4) + sdev(5)*sdev(5) + sdev(6)*sdev(6)
    s3(1,1) = sdev(1)
    s3(1,2) = sdev(4)
    s3(1,3) = sdev(6)
    s3(2,1) = sdev(4)
    s3(2,2) = sdev(2)
    s3(2,3) = sdev(5)
    s3(3,1) = sdev(6)
    s3(3,2) = sdev(5)
    s3(3,3) = sdev(3)
    J3 = s3(1,1)*(s3(2,2)*s3(3,3) - s3(2,3)*s3(3,2)) &
       - s3(1,2)*(s3(2,1)*s3(3,3) - s3(2,3)*s3(3,1)) &
       + s3(1,3)*(s3(2,1)*s3(3,2) - s3(2,2)*s3(3,1))
  END SUBROUTINE PH_Elem_C3D27_EvalStressInvar

  SUBROUTINE PH_Elem_C3D27_EvalTriaxiality(sigma, triax)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: triax
    REAL(wp) :: I1, J2, J3, p, seq
    CALL PH_Elem_C3D27_EvalStressInvar(sigma, I1, J2, J3)
    p = -I1 / 3.0_wp
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
    IF (seq > 1.0e-20_wp) THEN
      triax = p / seq
    ELSE
      triax = ZERO
    END IF
  END SUBROUTINE PH_Elem_C3D27_EvalTriaxiality

  SUBROUTINE PH_Elem_C3D27_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    INTEGER(i4) :: ip, nv
    nv = 13
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, 27)
      IF (SIZE(out_vars, 1) >= nv .AND. SIZE(ip_stress, 1) >= 6) THEN
        out_vars(1:6, ip) = ip_stress(1:6, ip)
      END IF
      IF (SIZE(ip_strain, 1) >= 6) THEN
        out_vars(7:12, ip) = ip_strain(1:6, ip)
      END IF
      IF (SIZE(ip_peeq) >= ip) THEN
        out_vars(13, ip) = ip_peeq(ip)
      END IF
    END DO
  END SUBROUTINE PH_Elem_C3D27_CollectIPVars

  SUBROUTINE PH_Elem_C3D27_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: seq
    REAL(wp) :: s1, s2, s3, p, J2
    s1 = sigma(1)
    s2 = sigma(2)
    s3 = sigma(3)
    p = (s1 + s2 + s3) / 3.0_wp
    J2 = HALF * ((s1-p)**2 + (s2-p)**2 + (s3-p)**2) &
         + sigma(4)**2 + sigma(5)**2 + sigma(6)**2
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
  END SUBROUTINE PH_Elem_C3D27_EvalVonMises

  SUBROUTINE PH_Elem_C3D27_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(27, 27)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(27), dNdxi(3, 27)
    REAL(wp) :: A(27, 27), AT(27, 27)
    INTEGER(i4) :: ip, i, j
    INTEGER(i4) :: info
    CALL PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)
    A = ZERO
    DO ip = 1, 27
      CALL PH_Elem_C3D27_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      DO i = 1, 27
        A(i, ip) = N(i)
      END DO
    END DO
    AT = TRANSPOSE(A)
    E = AT
    CALL invert_27x27(E, info)
    IF (info /= 0) E = ZERO
  END SUBROUTINE PH_Elem_C3D27_GetExtrapMat

  SUBROUTINE PH_Elem_C3D27_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    REAL(wp) :: E(27, 27)
    INTEGER(i4) :: ic, i, j
    INTEGER(i4) :: n_comp
    node_vars = ZERO
    CALL PH_Elem_C3D27_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 27
        DO j = 1, 27
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D27_MapToNode

  SUBROUTINE PH_Elem_C3D27_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
                                                  stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_Elastic3D

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dStrain(6)
    REAL(wp),                  INTENT(IN)    :: stress_old(6)
    REAL(wp),                  INTENT(OUT)   :: stress_new(6)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(6, 6)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_Elastic3D(rt_ctx, mat_slot, dStrain, &
                                    stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_C3D27_Material_Update_Routed
END MODULE PH_Elem_C3D27


