!===============================================================================
! MODULE: PH_Elem_C3D8
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Proc
! BRIEF:  C3D8 element definition (8-node 3D continuum hexahedron)
!===============================================================================
MODULE PH_Elem_C3D8
!> [CORE] C3D8 element definition
!> Theory: N_i = (1/8)(1+xi_i*xi)(1+eta_i*eta)(1+zeta_i*zeta), K = integral B^T*D*B dV
!> Status: CORE | Last verified: 2026-02-28
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF, QUARTER
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef, UF_MatProp_Init, MAT_CAT_ELASTIC, MAT_ID_ELASTIC_ISOTROPIC_101
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  ! Structured interfaces (new)
  PUBLIC :: PH_Elem_C3D8_ShapeFunc_Arg
  PUBLIC :: PH_Elem_C3D8_ShapeFunc
  PUBLIC :: PH_Elem_C3D8_Jac_Arg
  PUBLIC :: PH_Elem_C3D8_Jac
  PUBLIC :: PH_Elem_C3D8_BMatrix_Arg
  PUBLIC :: PH_Elem_C3D8_BMatrix
  PUBLIC :: PH_Elem_C3D8_JacB_Arg
  PUBLIC :: PH_Elem_C3D8_JacB
  PUBLIC :: PH_Elem_C3D8_Strain_Arg
  PUBLIC :: PH_Elem_C3D8_Strain
  PUBLIC :: PH_Elem_C3D8_Stress_Arg
  PUBLIC :: PH_Elem_C3D8_Stress
  PUBLIC :: PH_Elem_C3D8_StiffMatrix_Arg
  PUBLIC :: PH_Elem_C3D8_StiffMatrix
  PUBLIC :: PH_Elem_C3D8_NL_TL_Arg
  PUBLIC :: PH_Elem_C3D8_NL_TL
  PUBLIC :: PH_Elem_C3D8_NL_UL_Arg
  PUBLIC :: PH_Elem_C3D8_NL_UL
  PUBLIC :: PH_Elem_C3D8_Material_Update_Routed
  
  ! Legacy interfaces (kept for backward compatibility, will be deprecated)
  PUBLIC :: PH_Elem_C3D8_DefInit
  PUBLIC :: PH_Elem_C3D8_GaussPoints
  PUBLIC :: PH_Elem_C3D8_ConstMatrix
  PUBLIC :: PH_Elem_C3D8_StiffMatrixSelective
  PUBLIC :: PH_Elem_C3D8_StiffMatrixReduced
  PUBLIC :: PH_Elem_C3D8_StiffMatrixIncompatible
  PUBLIC :: PH_Elem_C3D8_StiffMatrix27
  PUBLIC :: PH_Elem_C3D8_IntForce
  PUBLIC :: PH_Elem_C3D8_IntForceSelective
  PUBLIC :: PH_Elem_C3D8_IntForceReduced
  PUBLIC :: PH_Elem_C3D8_IntForceIncompatible
  PUBLIC :: PH_Elem_C3D8_IntForce27
  PUBLIC :: PH_Elem_C3D8_ConsMass
  PUBLIC :: PH_Elem_C3D8_LumpMass
  PUBLIC :: PH_Elem_C3D8_LumpMassReduced
  PUBLIC :: PH_Elem_C3D8_LumpMass27
  PUBLIC :: PH_Elem_C3D8_ThermStrainVector
  PUBLIC :: PH_Elem_C3D8_GaussPoints27
  PUBLIC :: PH_Elem_C3D8_Volume27
  PUBLIC :: PH_Elem_C3D8_StiffMatrixByVariant
  PUBLIC :: PH_Elem_C3D8_IntForceByVariant
  PUBLIC :: PH_Elem_C3D8_FormStiffMatrix
  PUBLIC :: PH_Elem_C3D8_FormIntForce
  PUBLIC :: PH_Elem_C3D8_FormIntForceFromStress
  PUBLIC :: PH_Elem_C3D8_FormStiffMatrixByVariant
  PUBLIC :: PH_Elem_C3D8_FormIntForceByVariant
  PUBLIC :: PH_Elem_C3D8_FormGeomStiff
  PUBLIC :: PH_Elem_C3D8_NL_TL_Structured
  PUBLIC :: PH_Elem_C3D8_NL_TL_Legacy
  PUBLIC :: PH_Elem_C3D8_NL_UL_Legacy
  PUBLIC :: PH_Elem_C3D8_NL_TL_FromD
  PUBLIC :: PH_Elem_C3D8_NL_UL_FromD
  PUBLIC :: PH_Elem_C3D8_GetVolume, PH_Elem_C3D8_GetSectProps, PH_Elem_C3D8_GetCentroid
  PUBLIC :: PH_Elem_C3D8_GetInertiaOrig
  PUBLIC :: PH_Elem_C3D8_ApplyConstraint, PH_Elem_C3D8_ApplyMPC
  PUBLIC :: PH_Elem_C3D8_FormContactContrib, PH_Elem_C3D8_FormContactFaceCtr
  PUBLIC :: PH_Elem_C3D8_FormNodalForce, PH_Elem_C3D8_FormBodyForce, PH_Elem_C3D8_FormFacePressure
  PUBLIC :: PH_Elem_C3D8_FormGravity
  PUBLIC :: PH_Elem_C3D8_CollectIPVars, PH_Elem_C3D8_MapToNode, PH_Elem_C3D8_GetExtrapMat
  PUBLIC :: PH_Elem_C3D8_EvalVonMises, PH_Elem_C3D8_EvalPrincStress
  PUBLIC :: PH_Elem_C3D8_EvalStressInvar, PH_Elem_C3D8_EvalStrainInvar, PH_Elem_C3D8_EvalTriaxiality
  PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF, PH_ELEM_CTYPE_MPC_LINEAR
  PUBLIC :: PH_ELEM_GAUSS_PT
  PUBLIC :: PH_ELEM_C3D8_NNODE
  PUBLIC :: PH_ELEM_C3D8_NIP
  PUBLIC :: PH_ELEM_C3D8_NDOF
  PUBLIC :: PH_ELEM_C3D8_NFACE
  PUBLIC :: PH_ELEM_C3D8_FACE_NODES
  PUBLIC :: PH_ELEM_C3D8_VARIANT_STANDARD
  PUBLIC :: PH_ELEM_C3D8_VARIANT_REDUCED
  PUBLIC :: PH_ELEM_C3D8_VARIANT_HYBRID
  PUBLIC :: PH_ELEM_C3D8_VARIANT_INCOMPAT
  PUBLIC :: PH_ELEM_C3D8_VARIANT_MODIFIED
  PUBLIC :: PH_ELEM_C3D8_VARIANT_27PT
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_BODY = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_FACE_P = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_LOAD_GRAV = 3_i4

  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_NNODE = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_NIP   = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_NDOF  = 24_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_NFACE  = 6_i4
  ! Variant indices for unified API (C3D8/C3D8R/C3D8H/C3D8I/C3D8M/C3D8S)
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_VARIANT_STANDARD  = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_VARIANT_REDUCED   = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_VARIANT_HYBRID   = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_VARIANT_INCOMPAT = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_VARIANT_MODIFIED = 5_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_VARIANT_27PT    = 6_i4
  ! 2x2x2 Gauss: 1/sqrt(3), weight 1 per dim -> weight = 1 per IP
  REAL(wp), PARAMETER :: PH_ELEM_GAUSS_PT = 0.577350269189626_wp  ! 1/sqrt(3)
  ! Face topology: face k has nodes PH_ELEM_C3D8_FACE_NODES(1:4, k). Order for outward normal.
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8_FACE_NODES(4, 6) = RESHAPE([ &
    1,2,3,4, 5,8,7,6, 1,2,6,5, 4,3,7,8, 1,4,8,5, 2,6,7,3 ], [4, 6])
  ! C3D8R: hourglass (Flanagan-Belytschko)
  REAL(wp), PARAMETER :: GAMMA8(8, 4) = RESHAPE([ &
    1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp, &
    1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp, &
    1.0_wp, -1.0_wp, -1.0_wp,  1.0_wp, -1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp, &
    1.0_wp,  1.0_wp,  1.0_wp,  1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp, -1.0_wp ], [8, 4])
  REAL(wp), PARAMETER :: HG_COEFF = 0.10_wp
  REAL(wp), PARAMETER :: W1 = 8.0_wp
  ! C3D8S: 3-point Gauss: +/-sqrt(3/5), 0; weights 5/9, 8/9, 5/9
  REAL(wp), PARAMETER :: GP3(3) = [-0.774596669241483_wp, 0.0_wp, 0.774596669241483_wp]
  REAL(wp), PARAMETER :: W3(3)  = [5.0_wp/9.0_wp, 8.0_wp/9.0_wp, 5.0_wp/9.0_wp]

  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for shape function computation
  
  !> @brief Output structure for shape function computation
  TYPE, PUBLIC :: PH_Elem_C3D8_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_ShapeFunc_Arg


  !> @brief Input structure for Jacobian computation
  
  !> @brief Output structure for Jacobian computation
  TYPE, PUBLIC :: PH_Elem_C3D8_Jac_Arg
    REAL(wp) :: detJ  ! Jacobian determinant |J| (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_Jac_Arg


  !> @brief Input structure for B matrix computation
  
  !> @brief Output structure for B matrix computation
  TYPE, PUBLIC :: PH_Elem_C3D8_BMatrix_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_BMatrix_Arg


  !> @brief Input structure for combined Jacobian and B matrix computation
  
  !> @brief Output structure for combined Jacobian and B matrix computation
  TYPE, PUBLIC :: PH_Elem_C3D8_JacB_Arg
    REAL(wp) :: detJ  ! Jacobian determinant (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_JacB_Arg


  !> @brief Input structure for strain computation
  
  !> @brief Output structure for strain computation
  TYPE, PUBLIC :: PH_Elem_C3D8_Strain_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_Strain_Arg


  !> @brief Input structure for stress computation
  
  !> @brief Output structure for stress computation
  TYPE, PUBLIC :: PH_Elem_C3D8_Stress_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_Stress_Arg


  !> @brief Input structure for stiffness matrix computation
  
  !> @brief Output structure for stiffness matrix computation
  TYPE, PUBLIC :: PH_Elem_C3D8_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_StiffMatrix_Arg


  !> @brief Input structure for Total Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Total Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_C3D8_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    INTEGER(i4), OPTIONAL :: variant  ! Element variant (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_NL_TL_Arg


  !> @brief Input structure for Updated Lagrangian geometric nonlinear computation
  
  !> @brief Output structure for Updated Lagrangian geometric nonlinear computation
  TYPE, PUBLIC :: PH_Elem_C3D8_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    INTEGER(i4), OPTIONAL :: variant  ! Element variant (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_NL_UL_Arg


CONTAINS

  SUBROUTINE PH_ELEM_C3D8_BEnhanced(dN_xi, dN_eta, dN_zeta, J_inv, B_enh)
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
  END SUBROUTINE PH_ELEM_C3D8_BEnhanced

  SUBROUTINE PH_ELEM_C3D8_IncompatibleShapeFunc(xi, eta, zeta, N_enh, dN_xi, dN_eta, dN_zeta)
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
  END SUBROUTINE PH_ELEM_C3D8_IncompatibleShapeFunc

  SUBROUTINE PH_ELEM_C3D8_Inv3x3(A, Ainv, detA)
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
  END SUBROUTINE PH_ELEM_C3D8_Inv3x3

  SUBROUTINE PH_ELEM_C3D8_Volume_8pt(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_C3D8_Volume_8pt

  SUBROUTINE PH_El_C3_FormIntForceByVaria(coords, u, E_young, nu, variant, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: R_int(24)
    CALL PH_Elem_C3D8_IntForceByVariant(coords, u, E_young, nu, variant, R_int)
  END SUBROUTINE PH_Elem_C3D8_FormIntForceByVariant

  SUBROUTINE PH_El_C3_FormStiffMatrixByVa(coords, E_young, nu, variant, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: Ke(24, 24)
    CALL PH_Elem_C3D8_StiffMatrixByVariant(coords, E_young, nu, variant, Ke)
  END SUBROUTINE PH_Elem_C3D8_FormStiffMatrixByVariant

  SUBROUTINE PH_El_C3_IntForceByVariant(coords, u, E_young, nu, variant, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: R_int(24)
    IF (variant == PH_ELEM_C3D8_VARIANT_REDUCED) THEN
      CALL PH_Elem_C3D8_IntForceReduced(coords, u, E_young, nu, R_int)
    ELSE IF (variant == PH_ELEM_C3D8_VARIANT_HYBRID) THEN
      CALL PH_Elem_C3D8_IntForceSelective(coords, u, E_young, nu, R_int)
    ELSE IF (variant == PH_ELEM_C3D8_VARIANT_INCOMPAT) THEN
      CALL PH_Elem_C3D8_IntForceIncompatible(coords, u, E_young, nu, R_int)
    ELSE IF (variant == PH_ELEM_C3D8_VARIANT_27PT) THEN
      CALL PH_Elem_C3D8_IntForce27(coords, u, E_young, nu, R_int)
    ELSE
      CALL PH_Elem_C3D8_IntForce(coords, u, E_young, nu, R_int)
    END IF
  END SUBROUTINE PH_Elem_C3D8_IntForceByVariant

  SUBROUTINE PH_El_C3_IntForceIncompatibl(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(24)
    REAL(wp) :: Ke(24, 24)
    CALL PH_Elem_C3D8_StiffMatrixIncompatible(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_C3D8_IntForceIncompatible

  SUBROUTINE PH_El_C3_IntForceSelective(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(24)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: B_vol(24), B_vol_avg(24), B_mod(6, 24)
    REAL(wp) :: strain(6), sigma(6), dV, volume
    INTEGER(i4) :: ip

    R_int = ZERO
    B_vol_avg = ZERO
    volume = ZERO
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      volume = volume + dV
      B_vol(1:24) = (B(1,1:24) + B(2,1:24) + B(3,1:24)) / 3.0_wp
      B_vol_avg(1:24) = B_vol_avg(1:24) + B_vol(1:24) * dV
    END DO
    IF (volume <= 1.0e-20_wp) RETURN
    B_vol_avg(1:24) = B_vol_avg(1:24) / volume

    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      B_vol(1:24) = (B(1,1:24) + B(2,1:24) + B(3,1:24)) / 3.0_wp
      B_mod(1, 1:24) = B(1, 1:24) + (B_vol_avg(1:24) - B_vol(1:24))
      B_mod(2, 1:24) = B(2, 1:24) + (B_vol_avg(1:24) - B_vol(1:24))
      B_mod(3, 1:24) = B(3, 1:24) + (B_vol_avg(1:24) - B_vol(1:24))
      B_mod(4:6, 1:24) = B(4:6, 1:24)
      CALL PH_Elem_C3D8_Strain(B_mod, u, strain)
      CALL PH_Elem_C3D8_Stress(strain, D, sigma)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B_mod), sigma)
    END DO
  END SUBROUTINE PH_Elem_C3D8_IntForceSelective

  SUBROUTINE PH_El_C3_StiffMatrixByVarian(coords, E_young, nu, variant, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    INTEGER(i4), INTENT(IN)  :: variant
    REAL(wp), INTENT(OUT) :: Ke(24, 24)
    IF (variant == PH_ELEM_C3D8_VARIANT_REDUCED) THEN
      CALL PH_Elem_C3D8_StiffMatrixReduced(coords, E_young, nu, Ke)
    ELSE IF (variant == PH_ELEM_C3D8_VARIANT_HYBRID) THEN
      CALL PH_Elem_C3D8_StiffMatrixSelective(coords, E_young, nu, Ke)
    ELSE IF (variant == PH_ELEM_C3D8_VARIANT_INCOMPAT) THEN
      CALL PH_Elem_C3D8_StiffMatrixIncompatible(coords, E_young, nu, Ke)
    ELSE IF (variant == PH_ELEM_C3D8_VARIANT_27PT) THEN
      CALL PH_Elem_C3D8_StiffMatrix27(coords, E_young, nu, Ke)
    ELSE
      CALL PH_Elem_C3D8_StiffMatrix(coords, E_young, nu, Ke)
    END IF
  END SUBROUTINE PH_Elem_C3D8_StiffMatrixByVariant

  SUBROUTINE PH_El_C3_StiffMatrixIncompat(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(24, 24)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: J_inv(3, 3)
    REAL(wp) :: N_enh(3), dN_xi(3), dN_eta(3), dN_zeta(3)
    REAL(wp) :: B_enh(6, 3)
    REAL(wp) :: Ke_uu(24, 24), Ke_ua(24, 3), Ke_aa(3, 3)
    REAL(wp) :: Ke_aa_inv(3, 3), tmp(24, 3), det_aa
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    Ke_uu = ZERO
    Ke_ua = ZERO
    Ke_aa = ZERO
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
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
      CALL PH_ELEM_C3D8_IncompatibleShapeFunc(xi(ip), eta(ip), zeta(ip), N_enh, dN_xi, dN_eta, dN_zeta)
      CALL PH_ELEM_C3D8_BEnhanced(dN_xi, dN_eta, dN_zeta, J_inv, B_enh)
      Ke_uu = Ke_uu + dV * MATMUL(MATMUL(TRANSPOSE(B), D), B)
      Ke_ua = Ke_ua + dV * MATMUL(MATMUL(TRANSPOSE(B), D), B_enh)
      Ke_aa = Ke_aa + dV * MATMUL(MATMUL(TRANSPOSE(B_enh), D), B_enh)
    END DO
    CALL PH_ELEM_C3D8_Inv3x3(Ke_aa, Ke_aa_inv, det_aa)
    IF (ABS(det_aa) <= 1.0e-20_wp) THEN
      Ke = Ke_uu
      RETURN
    END IF
    tmp = MATMUL(Ke_ua, Ke_aa_inv)
    Ke = Ke_uu - MATMUL(tmp, TRANSPOSE(Ke_ua))
  END SUBROUTINE PH_Elem_C3D8_StiffMatrixIncompatible

  SUBROUTINE PH_El_C3_StiffMatrixReduced(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(24, 24)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: volume, mu_hg, L_char, invL2, k_hg
    REAL(wp) :: BTD(24, 6)
    INTEGER(i4) :: i, j, m, a
    Ke = ZERO
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D8_JacB(coords, ZERO, ZERO, ZERO, N, dNdx, J, detJ, B)
    IF (ABS(detJ) > 1.0e-12_wp) THEN
      BTD = MATMUL(TRANSPOSE(B), D)
      Ke = Ke + W1 * detJ * MATMUL(BTD, B)
    END IF
    CALL PH_ELEM_C3D8_Volume_8pt(coords, volume)
    IF (volume <= 1.0e-20_wp) RETURN
    mu_hg = E_young / (2.0_wp * (ONE + nu))
    L_char = volume**(1.0_wp/3.0_wp)
    invL2 = ONE / (L_char * L_char)
    k_hg = HG_COEFF * mu_hg * volume * invL2
    DO m = 1, 4
      DO i = 1, 8
        DO j = 1, 8
          DO a = 1, 3
            Ke(3*(i-1)+a, 3*(j-1)+a) = Ke(3*(i-1)+a, 3*(j-1)+a) + &
              k_hg * GAMMA8(i, m) * GAMMA8(j, m)
          END DO
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_StiffMatrixReduced

  SUBROUTINE PH_El_C3_StiffMatrixSelectiv(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(24, 24)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: B_vol(24), B_vol_avg(24), B_mod(6, 24)
    REAL(wp) :: dV, volume, BTD(24, 6)
    INTEGER(i4) :: ip

    Ke = ZERO
    B_vol_avg = ZERO
    volume = ZERO
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      volume = volume + dV
      B_vol(1:24) = (B(1,1:24) + B(2,1:24) + B(3,1:24)) / 3.0_wp
      B_vol_avg(1:24) = B_vol_avg(1:24) + B_vol(1:24) * dV
    END DO
    IF (volume <= 1.0e-20_wp) RETURN
    B_vol_avg(1:24) = B_vol_avg(1:24) / volume

    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      B_vol(1:24) = (B(1,1:24) + B(2,1:24) + B(3,1:24)) / 3.0_wp
      B_mod(1, 1:24) = B(1, 1:24) + (B_vol_avg(1:24) - B_vol(1:24))
      B_mod(2, 1:24) = B(2, 1:24) + (B_vol_avg(1:24) - B_vol(1:24))
      B_mod(3, 1:24) = B(3, 1:24) + (B_vol_avg(1:24) - B_vol(1:24))
      B_mod(4:6, 1:24) = B(4:6, 1:24)
      BTD = MATMUL(TRANSPOSE(B_mod), D)
      Ke = Ke + dV * MATMUL(BTD, B_mod)
    END DO
  END SUBROUTINE PH_Elem_C3D8_StiffMatrixSelective

  SUBROUTINE PH_El_C3_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(IN)  :: deltaT
    REAL(wp), INTENT(OUT) :: eps_th(6)
    eps_th(1:3) = alpha * deltaT
    eps_th(4:6) = ZERO
  END SUBROUTINE PH_Elem_C3D8_ThermStrainVector

  SUBROUTINE PH_Elem_C3D8_BMatrix(arg)
    TYPE(PH_Elem_C3D8_BMatrix_Arg), INTENT(INOUT) :: arg

    INTEGER(i4) :: i, c

    CALL init_error_status(arg%status)

    arg%B = ZERO
    DO i = 1, 8
      c = 3 * (i - 1) + 1
      arg%B(1, c)     = arg%dNdx(1, i)
      arg%B(2, c+1)   = arg%dNdx(2, i)
      arg%B(3, c+2)   = arg%dNdx(3, i)
      arg%B(4, c)     = arg%dNdx(2, i)
      arg%B(4, c+1)   = arg%dNdx(1, i)
      arg%B(5, c+1)   = arg%dNdx(3, i)
      arg%B(5, c+2)   = arg%dNdx(2, i)
      arg%B(6, c)     = arg%dNdx(3, i)
      arg%B(6, c+2)   = arg%dNdx(1, i)
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_BMatrix

  SUBROUTINE PH_Elem_C3D8_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(24, 24)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: dV, M_scalar
    INTEGER(i4) :: ip, i, j, d

    Me = ZERO
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 8
        DO j = 1, 8
          M_scalar = N(i) * N(j) * dV
          DO d = 1, 3
            Me(3*(i-1)+d, 3*(j-1)+d) = Me(3*(i-1)+d, 3*(j-1)+d) + M_scalar
          END DO
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_ConsMass

  SUBROUTINE PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
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
  END SUBROUTINE PH_Elem_C3D8_ConstMatrix

  SUBROUTINE PH_Elem_C3D8_DefInit()
    !! No-op: C3D8 has fixed topology (8 nodes, 8 IPs).
  END SUBROUTINE PH_Elem_C3D8_DefInit

  SUBROUTINE PH_Elem_C3D8_FormGeomStiff(coords, sigma, Kg)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: Kg(24, 24)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), dNdx(3, 8), J(3, 3), J_inv(3, 3), detJ
    REAL(wp) :: S(3, 3), GtS(24, 3)
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
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL PH_ELEM_C3D8_Inv3x3(J, J_inv, detJ)
      dNdx = MATMUL(J_inv, dNdxi)
      ! GtS(i,k) = (G^T S)(i,k); G(i,:)=dNdx at node_i => GtS(i,k)= sum_j dNdx(j,node_i)*S(j,k)
      GtS = ZERO
      DO i = 1, 24
        node_i = (i + 2) / 3
        DO k = 1, 3
          DO j = 1, 3
            GtS(i, k) = GtS(i, k) + dNdx(j, node_i) * S(j, k)
          END DO
        END DO
      END DO
      DO j = 1, 24
        node_j = (j + 2) / 3
        DO i = 1, 24
          Kg(i, j) = Kg(i, j) + (GtS(i, 1)*dNdx(1, node_j) + GtS(i, 2)*dNdx(2, node_j) + GtS(i, 3)*dNdx(3, node_j)) * detJ * weights(ip)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_FormGeomStiff

  SUBROUTINE PH_Elem_C3D8_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(24)
    CALL PH_Elem_C3D8_IntForce(coords, u, E_young, nu, R_int)
  END SUBROUTINE PH_Elem_C3D8_FormIntForce

  SUBROUTINE PH_Elem_C3D8_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(24, 24)
    CALL PH_Elem_C3D8_StiffMatrix(coords, E_young, nu, Ke)
  END SUBROUTINE PH_Elem_C3D8_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: p(2), w1d(2)
    INTEGER(i4) :: i, j, k, idx

    p(1)  = -PH_ELEM_GAUSS_PT
    p(2)  =  PH_ELEM_GAUSS_PT
    w1d(1)= ONE
    w1d(2)= ONE
    idx = 0
    DO i = 1, 2
      DO j = 1, 2
        DO k = 1, 2
          idx = idx + 1
          xi(idx) = p(i)
          eta(idx) = p(j)
          zeta(idx) = p(k)
          weights(idx) = w1d(i) * w1d(j) * w1d(k)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_GaussPoints

  SUBROUTINE PH_Elem_C3D8_GaussPoints27(xi, eta, zeta, weights)
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
  END SUBROUTINE PH_Elem_C3D8_GaussPoints27

  SUBROUTINE PH_Elem_C3D8_IntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(24)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: strain(6), sigma(6), dV
    INTEGER(i4) :: ip

    R_int = ZERO
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      CALL PH_Elem_C3D8_Strain(B, u, strain)
      CALL PH_Elem_C3D8_Stress(strain, D, sigma)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma)
    END DO
  END SUBROUTINE PH_Elem_C3D8_IntForce

  SUBROUTINE PH_Elem_C3D8_StiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(24, 24)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: BTD(24, 6), dV
    INTEGER(i4) :: ip

    Ke = ZERO
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(B), D)
      Ke = Ke + dV * MATMUL(BTD, B)
    END DO
  END SUBROUTINE PH_Elem_C3D8_StiffMatrix

  SUBROUTINE PH_Elem_C3D8_FormIntForceFromStress(coords, sigma6, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: sigma6(6)
    REAL(wp), INTENT(OUT) :: R_int(24)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24)
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma6)
    END DO
  END SUBROUTINE PH_Elem_C3D8_FormIntForceFromStress

  SUBROUTINE PH_Elem_C3D8_IntForce27(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(24)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: strain(6), sigma(6), dV
    INTEGER(i4) :: ip
    R_int = ZERO
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D8_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      CALL PH_Elem_C3D8_Strain(B, u, strain)
      CALL PH_Elem_C3D8_Stress(strain, D, sigma)
      R_int = R_int + dV * MATMUL(TRANSPOSE(B), sigma)
    END DO
  END SUBROUTINE PH_Elem_C3D8_IntForce27

  SUBROUTINE PH_Elem_C3D8_IntForceReduced(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(24)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: R_int(24)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: strain(6), sigma(6)
    REAL(wp) :: volume, mu_hg, L_char, invL2, k_hg
    REAL(wp) :: q(3)
    INTEGER(i4) :: i, m, a
    R_int = ZERO
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D8_JacB(coords, ZERO, ZERO, ZERO, N, dNdx, J, detJ, B)
    IF (ABS(detJ) > 1.0e-12_wp) THEN
      CALL PH_Elem_C3D8_Strain(B, u, strain)
      CALL PH_Elem_C3D8_Stress(strain, D, sigma)
      R_int = R_int + W1 * detJ * MATMUL(TRANSPOSE(B), sigma)
    END IF
    CALL PH_ELEM_C3D8_Volume_8pt(coords, volume)
    IF (volume <= 1.0e-20_wp) RETURN
    mu_hg = E_young / (2.0_wp * (ONE + nu))
    L_char = volume**(1.0_wp/3.0_wp)
    invL2 = ONE / (L_char * L_char)
    k_hg = HG_COEFF * mu_hg * volume * invL2
    DO m = 1, 4
      q = ZERO
      DO i = 1, 8
        q(1) = q(1) + GAMMA8(i, m) * u(3*(i-1)+1)
        q(2) = q(2) + GAMMA8(i, m) * u(3*(i-1)+2)
        q(3) = q(3) + GAMMA8(i, m) * u(3*(i-1)+3)
      END DO
      DO i = 1, 8
        DO a = 1, 3
          R_int(3*(i-1)+a) = R_int(3*(i-1)+a) + k_hg * GAMMA8(i, m) * q(a)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_IntForceReduced

  SUBROUTINE PH_Elem_C3D8_Jac(arg)
    TYPE(PH_Elem_C3D8_Jac_Arg), INTENT(INOUT) :: arg

    INTEGER(i4) :: i, j, k

    CALL init_error_status(arg%status)

    arg%J = ZERO
    DO j = 1, 3
      DO k = 1, 3
        DO i = 1, 8
          arg%J(j, k) = arg%J(j, k) + arg%dNdxi(k, i) * arg%coords(j, i)
        END DO
      END DO
    END DO
    
    arg%detJ = arg%J(1,1)*(arg%J(2,2)*arg%J(3,3) - arg%J(2,3)*arg%J(3,2)) &
             - arg%J(1,2)*(arg%J(2,1)*arg%J(3,3) - arg%J(2,3)*arg%J(3,1)) &
             + arg%J(1,3)*(arg%J(2,1)*arg%J(3,2) - arg%J(2,2)*arg%J(3,1))
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_Jac

  SUBROUTINE PH_Elem_C3D8_JacB(arg)
    TYPE(PH_Elem_C3D8_JacB_Arg), INTENT(INOUT) :: arg

    TYPE(PH_Elem_C3D8_ShapeFunc_Arg) :: sf
    TYPE(PH_Elem_C3D8_Jac_Arg) :: jac
    TYPE(PH_Elem_C3D8_BMatrix_Arg) :: bm

    REAL(wp) :: dNdxi(3, 8), J_inv(3, 3)
    INTEGER(i4) :: i, j, k

    CALL init_error_status(arg%status)

    ! Step 1: Compute shape functions
    sf%xi = arg%xi
    sf%eta = arg%eta
    sf%zeta = arg%zeta
    CALL PH_Elem_C3D8_ShapeFunc(sf)
    IF (sf%status%status_code /= IF_STATUS_OK) THEN
      arg%status = sf%status
      RETURN
    END IF
    arg%N = sf%N
    dNdxi = sf%dNdxi

    ! Step 2: Compute Jacobian
    jac%dNdxi = dNdxi
    jac%coords = arg%coords
    CALL PH_Elem_C3D8_Jac(jac)
    IF (jac%status%status_code /= IF_STATUS_OK) THEN
      arg%status = jac%status
      RETURN
    END IF
    arg%J = jac%J
    arg%detJ = jac%detJ

    ! Step 3: Compute ?N/?x and B matrix
    IF (ABS(arg%detJ) > 1.0e-12_wp) THEN
      ! J_inv = cofactor(J)^T / detJ
      J_inv(1,1) = (arg%J(2,2)*arg%J(3,3) - arg%J(2,3)*arg%J(3,2)) / arg%detJ
      J_inv(1,2) = -(arg%J(1,2)*arg%J(3,3) - arg%J(1,3)*arg%J(3,2)) / arg%detJ
      J_inv(1,3) = (arg%J(1,2)*arg%J(2,3) - arg%J(1,3)*arg%J(2,2)) / arg%detJ
      J_inv(2,1) = -(arg%J(2,1)*arg%J(3,3) - arg%J(2,3)*arg%J(3,1)) / arg%detJ
      J_inv(2,2) = (arg%J(1,1)*arg%J(3,3) - arg%J(1,3)*arg%J(3,1)) / arg%detJ
      J_inv(2,3) = -(arg%J(1,1)*arg%J(2,3) - arg%J(1,3)*arg%J(2,1)) / arg%detJ
      J_inv(3,1) = (arg%J(2,1)*arg%J(3,2) - arg%J(2,2)*arg%J(3,1)) / arg%detJ
      J_inv(3,2) = -(arg%J(1,1)*arg%J(3,2) - arg%J(1,2)*arg%J(3,1)) / arg%detJ
      J_inv(3,3) = (arg%J(1,1)*arg%J(2,2) - arg%J(1,2)*arg%J(2,1)) / arg%detJ
      
      ! dN_i/dx_j = ?_k J_inv(j,k) ? dN_i/d?_k
      DO i = 1, 8
        DO j = 1, 3
          arg%dNdx(j, i) = ZERO
          DO k = 1, 3
            arg%dNdx(j, i) = arg%dNdx(j, i) + J_inv(j, k) * dNdxi(k, i)
          END DO
        END DO
      END DO
      
      ! Step 4: Compute B matrix
      bm%dNdx = arg%dNdx
      CALL PH_Elem_C3D8_BMatrix(bm)
      IF (bm%status%status_code /= IF_STATUS_OK) THEN
        arg%status = bm%status
        RETURN
      END IF
      arg%B = bm%B
    ELSE
      arg%dNdx = ZERO
      arg%B = ZERO
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Zero or near-zero Jacobian determinant"
      RETURN
    END IF
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_JacB

  SUBROUTINE PH_Elem_C3D8_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(24)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, d

    M_lumped = ZERO
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 8
        DO d = 1, 3
          M_lumped(3*(i-1)+d) = M_lumped(3*(i-1)+d) + N(i) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_LumpMass

  SUBROUTINE PH_Elem_C3D8_LumpMass27(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(24)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, d
    M_lumped = ZERO
    CALL PH_Elem_C3D8_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 8
        DO d = 1, 3
          M_lumped(3*(i-1)+d) = M_lumped(3*(i-1)+d) + N(i) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_LumpMass27

  SUBROUTINE PH_Elem_C3D8_LumpMassReduced(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(24)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: i, d
    M_lumped = ZERO
    CALL PH_Elem_C3D8_ShapeFunc(ZERO, ZERO, ZERO, N, dNdxi)
    CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
    IF (ABS(detJ) > 1.0e-12_wp) THEN
      DO i = 1, 8
        DO d = 1, 3
          M_lumped(3*(i-1)+d) = rho * N(i) * detJ * W1
        END DO
      END DO
    END IF
  END SUBROUTINE PH_Elem_C3D8_LumpMassReduced

  SUBROUTINE PH_Elem_C3D8_NL_TL(arg)
    TYPE(PH_Elem_C3D8_NL_TL_Arg), INTENT(INOUT) :: arg
    
    USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
    USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_TotLag
    IMPLICIT NONE
    
    ! Local variables
    REAL(wp) :: coords_curr(3, 8)              ! Current coordinates
    REAL(wp) :: gp_xi(3), gp_wt                ! Gauss point coordinates and weight
    REAL(wp) :: N(8)                           ! Shape functions at GP
    REAL(wp) :: dN_dxi(8, 3)                   ! ?N/???,?,?)
    REAL(wp) :: J_ref(3, 3)                    ! Jacobian J = ?X/???,?,?)
    REAL(wp) :: J_inv(3, 3)                    ! J???
    REAL(wp) :: det_J                          ! |J|
    REAL(wp) :: dN_dX(8, 3)                    ! ?N/??X,Y,Z) in ref config
    TYPE(RT_LagrCfg) :: cfg                    ! RT layer configuration
    REAL(wp) :: F(3, 3)                        ! Deformation gradient
    REAL(wp) :: E(3, 3)                        ! Green-Lagrange strain
    REAL(wp) :: E_voigt(6)                     ! Strain in Voigt notation
    REAL(wp) :: S(3, 3)                        ! PK2 stress
    REAL(wp) :: K_mat_gp(24, 24)               ! K_mat at one GP
    REAL(wp) :: K_geo_gp(24, 24)               ! K_geo at one GP
    REAL(wp) :: R_gp(24)                       ! Residual at one GP
    TYPE(PH_MatPoint_StressStrain) :: ss_gp        ! Stress-strain at current GP
    TYPE(ErrorStatusType) :: mat_status        ! Mat constitutive status
    INTEGER(i4) :: igp, i, j, variant_use
    INTEGER(i4) :: n_gp                        ! Number of Gauss points
    REAL(wp) :: xi_all(27), eta_all(27), zeta_all(27), weights_all(27)  ! For 27PT variant
    REAL(wp) :: xi_all8(8), eta_all8(8), zeta_all8(8), weights_all8(8)  ! For STANDARD variant
    TYPE(PH_Elem_C3D8_ShapeFunc_Arg) :: sf_shape

    ! Initialize outputs
    CALL init_error_status(arg%status)
    IF (.NOT. ALLOCATED(arg%mat_state)) THEN

    END IF
    arg%mat_state = arg%mat_state
    arg%evo%Ke_mat = ZERO
    arg%evo%Ke_geo = ZERO
    arg%evo%R_int  = ZERO
    
    ! Determine variant (default to STANDARD)
    IF (PRESENT(arg%variant)) THEN
      variant_use = arg%variant
    ELSE
      variant_use = PH_ELEM_C3D8_VARIANT_STANDARD
    END IF
    
    ! Step 1: Compute current coordinates x = X? + u
    DO i = 1, 8
      coords_curr(1, i) = arg%coords_ref(1, i) + arg%lcl%u_elem(3*(i-1) + 1)
      coords_curr(2, i) = arg%coords_ref(2, i) + arg%lcl%u_elem(3*(i-1) + 2)
      coords_curr(3, i) = arg%coords_ref(3, i) + arg%lcl%u_elem(3*(i-1) + 3)
    END DO
    
    ! Step 2: Allocate and fill RT_LagrCfg structure



    cfg%formulation_typ = 1  ! 1 = Total Lagrangian
    
    DO i = 1, 8
      cfg%coords_ref(i, 1:3)  = arg%coords_ref(1:3, i)
      cfg%coords_curr(i, 1:3) = coords_curr(1:3, i)
    END DO
    
    ! Step 3-4: Gauss layout (REDUCED: single center point, weight W1 = 8 on [-1,1]^3)
    IF (variant_use == PH_ELEM_C3D8_VARIANT_REDUCED) THEN
      n_gp = 1
    ELSE IF (variant_use == PH_ELEM_C3D8_VARIANT_27PT) THEN
      n_gp = 27
      CALL PH_Elem_C3D8_GaussPoints27(xi_all, eta_all, zeta_all, weights_all)
    ELSE
      n_gp = PH_ELEM_C3D8_NIP
      CALL PH_Elem_C3D8_GaussPoints(xi_all8, eta_all8, zeta_all8, weights_all8)
    END IF
    
    DO igp = 1, n_gp
      ! 4.1 Gauss point coordinates and weight
      IF (variant_use == PH_ELEM_C3D8_VARIANT_REDUCED) THEN
        gp_xi(1) = ZERO
        gp_xi(2) = ZERO
        gp_xi(3) = ZERO
        gp_wt = W1
      ELSE IF (variant_use == PH_ELEM_C3D8_VARIANT_27PT) THEN
        gp_xi(1) = xi_all(igp)
        gp_xi(2) = eta_all(igp)
        gp_xi(3) = zeta_all(igp)
        gp_wt = weights_all(igp)
      ELSE
        gp_xi(1) = xi_all8(igp)
        gp_xi(2) = eta_all8(igp)
        gp_xi(3) = zeta_all8(igp)
        gp_wt = weights_all8(igp)
      END IF
      
      ! 4.2 Compute shape functions N and derivatives ?N/???,?,?)
      sf_shape%xi = gp_xi(1)
      sf_shape%eta = gp_xi(2)
      sf_shape%zeta = gp_xi(3)
      CALL PH_Elem_C3D8_ShapeFunc(sf_shape)
      IF (sf_shape%status%status_code /= IF_STATUS_OK) THEN
        arg%status = sf_shape%status

        RETURN
      END IF
      N = sf_shape%N
      ! Extract dN_dxi from structured output (transpose: dNdxi(3,8) -> dN_dxi(8,3))
      DO i = 1, 8
        dN_dxi(i, 1) = sf_shape%dNdxi(1, i)
        dN_dxi(i, 2) = sf_shape%dNdxi(2, i)
        dN_dxi(i, 3) = sf_shape%dNdxi(3, i)
      END DO

      ! 4.3 Compute Jacobian J = ?X/???,?,?) at reference config
      J_ref = ZERO
      DO i = 1, 8
        DO j = 1, 3
          J_ref(1, j) = J_ref(1, j) + dN_dxi(i, j) * arg%coords_ref(1, i)
          J_ref(2, j) = J_ref(2, j) + dN_dxi(i, j) * arg%coords_ref(2, i)
          J_ref(3, j) = J_ref(3, j) + dN_dxi(i, j) * arg%coords_ref(3, i)
        END DO
      END DO
      
      ! 4.4 Invert Jacobian to get dN_dX = dN_dxi ? J???
      CALL Invert3x3(J_ref, J_inv, det_J, arg%status)
      IF (arg%status%status_code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      
      DO i = 1, 8
        dN_dX(i, 1:3) = MATMUL(dN_dxi(i, 1:3), J_inv)  ! ?N????X,Y,Z)
      END DO
      
      ! 4.5 Store dN_dX into cfg (convert to RT layout: (n_nodes, 3))
      DO i = 1, 8
        cfg%lcl%dN_dX(i, 1:3) = dN_dX(i, 1:3)
      END DO
      
      ! 4.6 Compute deformation gradient F and Green-Lagrange strain E
      F = ZERO
      DO i = 1, 8
        DO j = 1, 3
          F(1, j) = F(1, j) + coords_curr(1, i) * dN_dX(i, j)  ! ?x/?X
          F(2, j) = F(2, j) + coords_curr(2, i) * dN_dX(i, j)  ! ?y/?Y
          F(3, j) = F(3, j) + coords_curr(3, i) * dN_dX(i, j)  ! ?z/?Z
        END DO
      END DO
      ! Green-Lagrange strain: E = 0.5*(F^T*F - I)
      E = ZERO
      E(1,1) = HALF * (F(1,1)*F(1,1) + F(2,1)*F(2,1) + F(3,1)*F(3,1) - ONE)
      E(2,2) = HALF * (F(1,2)*F(1,2) + F(2,2)*F(2,2) + F(3,2)*F(3,2) - ONE)
      E(3,3) = HALF * (F(1,3)*F(1,3) + F(2,3)*F(2,3) + F(3,3)*F(3,3) - ONE)
      E(1,2) = HALF * (F(1,1)*F(1,2) + F(2,1)*F(2,2) + F(3,1)*F(3,2))
      E(2,1) = E(1,2)
      E(1,3) = HALF * (F(1,1)*F(1,3) + F(2,1)*F(2,3) + F(3,1)*F(3,3))
      E(3,1) = E(1,3)
      E(2,3) = HALF * (F(1,2)*F(1,3) + F(2,2)*F(2,3) + F(3,2)*F(3,3))
      E(3,2) = E(2,3)
      
      ! Convert to Voigt notation: [E11, E22, E33, 2*E12, 2*E23, 2*E13]
      E_voigt(1) = E(1,1)
      E_voigt(2) = E(2,2)
      E_voigt(3) = E(3,3)
      E_voigt(4) = 2.0_wp * E(1,2)  ! Engineering shear strain
      E_voigt(5) = 2.0_wp * E(2,3)
      E_voigt(6) = 2.0_wp * E(1,3)
      
      ! 4.7 Call Mat constitutive model: strain ??stress + tangent
      ss_gp%strain = E_voigt
      ss_gp%strain_inc = E_voigt  ! For TL, strain_inc = E (no history yet)
      CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(igp), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) THEN
        arg%status%status_code = IF_STATUS_ERROR

        RETURN
      END IF
      
      ! 4.8 Convert PK2 stress back to tensor form
      S(1,1) = ss_gp%sigma(1)
      S(2,2) = ss_gp%sigma(2)
      S(3,3) = ss_gp%sigma(3)
      S(1,2) = ss_gp%sigma(4); S(2,1) = S(1,2)
      S(2,3) = ss_gp%sigma(5); S(3,2) = S(2,3)
      S(1,3) = ss_gp%sigma(6); S(3,1) = S(1,3)
      
      ! 4.9 Call RT layer for stiffness assembly (pass computed S and D)
      CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, arg%status, R_gp, ss_gp%tangent)
      IF (arg%status%status_code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      
      ! 4.10 Accumulate contributions (weighted by |J|?w)
      arg%evo%Ke_mat = arg%evo%Ke_mat + K_mat_gp * det_J * gp_wt
      arg%evo%Ke_geo = arg%evo%Ke_geo + K_geo_gp * det_J * gp_wt
      arg%evo%R_int  = arg%evo%R_int  + R_gp * det_J * gp_wt
    END DO
    
    ! Step 5: Cleanup

  CONTAINS
    
    !-----------------------------------------------------------------------------
    ! Helper: REDUCED variant (1-point + hourglass control) for NL_TL
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_ELEM_C3D8_NL_TL_Reduced(coords_ref, coords_curr, u_elem, D, Ke_mat, Ke_geo, R_int, status)
      REAL(wp), INTENT(IN)  :: coords_ref(3, 8), coords_curr(3, 8)
      REAL(wp), INTENT(IN)  :: u_elem(24), D(6, 6)
      REAL(wp), INTENT(OUT) :: Ke_mat(24, 24), Ke_geo(24, 24), R_int(24)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      
      REAL(wp) :: N(8), dN_dxi(8, 3), J_ref(3, 3), J_inv(3, 3), det_J
      REAL(wp) :: dN_dX(8, 3)
      TYPE(RT_LagrCfg) :: cfg
      REAL(wp) :: F(3, 3), E(3, 3), S(3, 3)
      REAL(wp) :: K_mat_gp(24, 24), K_geo_gp(24, 24), R_gp(24)
      REAL(wp) :: volume, mu_hg, L_char, invL2, k_hg
      REAL(wp) :: q(3)
      INTEGER(i4) :: i, j, m, a
      
      Ke_mat = ZERO
      Ke_geo = ZERO
      R_int  = ZERO
      status%code = STATUS_SUCCESS
      
      ! Allocate cfg

      cfg%formulation_typ = 1
      DO i = 1, 8
        cfg%coords_ref(i, 1:3)  = coords_ref(1:3, i)
        cfg%coords_curr(i, 1:3) = coords_curr(1:3, i)
      END DO
      
      ! 1-point integration at center (0,0,0)
      CALL PH_Elem_C3D8_ShapeFunc(ZERO, ZERO, ZERO, N)
      CALL PH_Elem_C3D8_ShapeFuncDeriv(ZERO, ZERO, ZERO, dN_dxi)
      
      ! Jacobian at center
      J_ref = ZERO
      DO i = 1, 8
        DO j = 1, 3
          J_ref(1, j) = J_ref(1, j) + dN_dxi(i, j) * coords_ref(1, i)
          J_ref(2, j) = J_ref(2, j) + dN_dxi(i, j) * coords_ref(2, i)
          J_ref(3, j) = J_ref(3, j) + dN_dxi(i, j) * coords_ref(3, i)
        END DO
      END DO
      CALL Invert3x3(J_ref, J_inv, det_J, status)
      IF (status%code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      
      DO i = 1, 8
        dN_dX(i, 1:3) = MATMUL(dN_dxi(i, 1:3), J_inv)
        cfg%lcl%dN_dX(i, 1:3) = dN_dX(i, 1:3)
      END DO
      
      ! Mat contribution (weight W1 = 8.0)
      CALL PH_RT_Elem_GeomNonlin_TotLag(cfg, F, E, S, K_mat_gp, K_geo_gp, status, R_gp)
      IF (status%code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      Ke_mat = Ke_mat + K_mat_gp * W1 * det_J
      Ke_geo = Ke_geo + K_geo_gp * W1 * det_J
      R_int  = R_int  + R_gp * W1 * det_J
      
      ! Hourglass control (estimate mu from D matrix)
      CALL PH_ELEM_C3D8_Volume_8pt(coords_ref, volume)
      IF (volume > 1.0e-20_wp) THEN
        mu_hg = (D(1,1) + D(2,2) + D(3,3)) / 6.0_wp  ! Approximate shear modulus
        L_char = volume**(1.0_wp/3.0_wp)
        invL2 = ONE / (L_char * L_char)
        k_hg = HG_COEFF * mu_hg * volume * invL2
        
        ! Hourglass stiffness
        DO m = 1, 4
          DO i = 1, 8
            DO j = 1, 8
              DO a = 1, 3
                Ke_mat(3*(i-1)+a, 3*(j-1)+a) = Ke_mat(3*(i-1)+a, 3*(j-1)+a) + &
                  k_hg * GAMMA8(i, m) * GAMMA8(j, m)
              END DO
            END DO
          END DO
        END DO
        
        ! Hourglass force
        DO m = 1, 4
          q = ZERO
          DO i = 1, 8
            q(1) = q(1) + GAMMA8(i, m) * u_elem(3*(i-1)+1)
            q(2) = q(2) + GAMMA8(i, m) * u_elem(3*(i-1)+2)
            q(3) = q(3) + GAMMA8(i, m) * u_elem(3*(i-1)+3)
          END DO
          DO i = 1, 8
            DO a = 1, 3
              R_int(3*(i-1)+a) = R_int(3*(i-1)+a) + k_hg * GAMMA8(i, m) * q(a)
            END DO
          END DO
        END DO
      END IF

    END SUBROUTINE PH_ELEM_C3D8_NL_TL_Reduced
    ! Helper: 3?? matrix inversion
    SUBROUTINE Invert3x3(A, A_inv, det_A, stat)
      REAL(wp), INTENT(IN)  :: A(3,3)
      REAL(wp), INTENT(OUT) :: A_inv(3,3), det_A
      TYPE(ErrorStatusType), INTENT(OUT) :: stat
      REAL(wp) :: cofac(3,3), tol
      
      tol = 1.0e-14_wp
      det_A = A(1,1)*(A(2,2)*A(3,3) - A(2,3)*A(3,2)) &
            - A(1,2)*(A(2,1)*A(3,3) - A(2,3)*A(3,1)) &
            + A(1,3)*(A(2,1)*A(3,2) - A(2,2)*A(3,1))
      
      IF (ABS(det_A) < tol) THEN
        stat%code = IF_STATUS_ERROR
        RETURN
      END IF
      
      cofac(1,1) = A(2,2)*A(3,3) - A(2,3)*A(3,2)
      cofac(1,2) = A(2,3)*A(3,1) - A(2,1)*A(3,3)
      cofac(1,3) = A(2,1)*A(3,2) - A(2,2)*A(3,1)
      cofac(2,1) = A(1,3)*A(3,2) - A(1,2)*A(3,3)
      cofac(2,2) = A(1,1)*A(3,3) - A(1,3)*A(3,1)
      cofac(2,3) = A(1,2)*A(3,1) - A(1,1)*A(3,2)
      cofac(3,1) = A(1,2)*A(2,3) - A(1,3)*A(2,2)
      cofac(3,2) = A(1,3)*A(2,1) - A(1,1)*A(2,3)
      cofac(3,3) = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      
      A_inv = cofac / det_A
      stat%code = STATUS_SUCCESS
    END SUBROUTINE Invert3x3
    
    ! Helper: ?N/???,?,?) derivatives
    SUBROUTINE PH_Elem_C3D8_ShapeFuncDeriv(xi, eta, zeta, dN_dxi)
      REAL(wp), INTENT(IN)  :: xi, eta, zeta
      REAL(wp), INTENT(OUT) :: dN_dxi(8, 3)
      REAL(wp) :: xi_nodes(8), eta_nodes(8), zeta_nodes(8)
      INTEGER(i4) :: i
      
      ! Node coordinates in parent domain [-1,1]??
      xi_nodes   = (/ -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE /)
      eta_nodes  = (/ -ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE /)
      zeta_nodes = (/ -ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE /)
      
      DO i = 1, 8
        dN_dxi(i, 1) = 0.125_wp * xi_nodes(i)   * (ONE + eta_nodes(i)*eta) * (ONE + zeta_nodes(i)*zeta)
        dN_dxi(i, 2) = 0.125_wp * eta_nodes(i)  * (ONE + xi_nodes(i)*xi)   * (ONE + zeta_nodes(i)*zeta)
        dN_dxi(i, 3) = 0.125_wp * zeta_nodes(i) * (ONE + xi_nodes(i)*xi)   * (ONE + eta_nodes(i)*eta)
      END DO
    END SUBROUTINE PH_Elem_C3D8_ShapeFuncDeriv
    
  END SUBROUTINE PH_Elem_C3D8_NL_TL

  SUBROUTINE PH_Elem_C3D8_NL_TL_Legacy(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status, variant)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 8)
    REAL(wp), INTENT(IN)  :: u_elem(24)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(24, 24)
    REAL(wp), INTENT(OUT) :: Ke_geo(24, 24)
    REAL(wp), INTENT(OUT) :: R_int(24)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: variant
    
    TYPE(PH_Elem_C3D8_NL_TL_Arg) :: in

    in%coords_ref = coords_ref
    in%lcl%u_elem = u_elem
    in%mat_prop = mat_prop
    ALLOCATE(in%mat_state(SIZE(mat_state)))
    in%mat_state = mat_state
    IF (PRESENT(variant)) THEN
      in%variant = variant
    END IF
    
    CALL PH_Elem_C3D8_NL_TL(in)

    Ke_mat = in%evo%Ke_mat
    Ke_geo = in%evo%Ke_geo
    R_int = in%evo%R_int
    status = in%status
    mat_state = in%mat_state
  END SUBROUTINE PH_Elem_C3D8_NL_TL_Legacy

  SUBROUTINE PH_Elem_C3D8_NL_UL(arg)
    TYPE(PH_Elem_C3D8_NL_UL_Arg), INTENT(INOUT) :: arg
    USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, IF_STATUS_ERROR
    USE PH_ElemRT_Brg, ONLY: RT_LagrCfg, PH_RT_Elem_GeomNonlin_UpdLag
    IMPLICIT NONE
    
    ! Local variables
    REAL(wp) :: coords_curr(3, 8)              ! Current coordinates
    REAL(wp) :: gp_xi(3), gp_wt                ! Gauss point
    REAL(wp) :: N(8)                           ! Shape functions
    REAL(wp) :: dN_dxi(8, 3)                   ! ?N/???,?,?)
    REAL(wp) :: J_prev(3, 3)                   ! Jacobian at x_n
    REAL(wp) :: J_inv(3, 3)                    ! J???
    REAL(wp) :: det_J                          ! |J|
    REAL(wp) :: dN_dx(8, 3)                    ! ?N/??x,y,z) at x_n
    TYPE(RT_LagrCfg) :: cfg                    ! RT configuration
    REAL(wp) :: F(3, 3)                        ! Deformation gradient
    REAL(wp) :: epsilon(3, 3)                  ! Almansi strain
    REAL(wp) :: epsilon_voigt(6)               ! Strain in Voigt notation
    REAL(wp) :: sigma(3, 3)                    ! Cauchy stress
    REAL(wp) :: b(3, 3), b_inv(3, 3), det_b    ! Left Cauchy-Green and inverse
    REAL(wp) :: K_mat_gp(24, 24)               ! K_mat at GP
    REAL(wp) :: K_geo_gp(24, 24)               ! K_geo at GP
    REAL(wp) :: R_gp(24)                       ! Residual at GP
    TYPE(PH_MatPoint_StressStrain) :: ss_gp        ! Stress-strain at current GP
    TYPE(ErrorStatusType) :: mat_status        ! Mat constitutive status
    INTEGER(i4) :: igp, i, j, variant_use
    INTEGER(i4) :: n_gp
    REAL(wp) :: xi_all(27), eta_all(27), zeta_all(27), weights_all(27)
    REAL(wp) :: xi_all8(8), eta_all8(8), zeta_all8(8), weights_all8(8)
    TYPE(PH_Elem_C3D8_ShapeFunc_Arg) :: sf_shape

    ! Initialize outputs
    CALL init_error_status(arg%status)
    IF (.NOT. ALLOCATED(arg%mat_state)) THEN

    END IF
    arg%mat_state = arg%mat_state
    arg%evo%Ke_mat = ZERO
    arg%evo%Ke_geo = ZERO
    arg%evo%R_int  = ZERO

    ! Determine variant (default to STANDARD)
    IF (PRESENT(arg%variant)) THEN
      variant_use = arg%variant
    ELSE
      variant_use = PH_ELEM_C3D8_VARIANT_STANDARD
    END IF

    ! Step 1: Compute current coordinates x_{n+1} = x_n + ?u
    DO i = 1, 8
      coords_curr(1, i) = arg%coords_prev(1, i) + arg%u_incr(3*(i-1) + 1)
      coords_curr(2, i) = arg%coords_prev(2, i) + arg%u_incr(3*(i-1) + 2)
      coords_curr(3, i) = arg%coords_prev(3, i) + arg%u_incr(3*(i-1) + 3)
    END DO
    
    ! Step 2: Allocate and fill RT_LagrCfg
    ALLOCATE(cfg%coords_prev(8, 3))  ! UL uses coords_prev


    cfg%formulation_typ = 2  ! 2 = Updated Lagrangian
    
    DO i = 1, 8
      cfg%coords_prev(i, 1:3) = arg%coords_prev(1:3, i)
      cfg%coords_curr(i, 1:3) = coords_curr(1:3, i)
    END DO
    
    ! Step 3-4: Gauss layout (REDUCED: single center point, weight W1)
    IF (variant_use == PH_ELEM_C3D8_VARIANT_REDUCED) THEN
      n_gp = 1
    ELSE IF (variant_use == PH_ELEM_C3D8_VARIANT_27PT) THEN
      n_gp = 27
      CALL PH_Elem_C3D8_GaussPoints27(xi_all, eta_all, zeta_all, weights_all)
    ELSE
      n_gp = PH_ELEM_C3D8_NIP
      CALL PH_Elem_C3D8_GaussPoints(xi_all8, eta_all8, zeta_all8, weights_all8)
    END IF
    
    DO igp = 1, n_gp
      IF (variant_use == PH_ELEM_C3D8_VARIANT_REDUCED) THEN
        gp_xi(1) = ZERO
        gp_xi(2) = ZERO
        gp_xi(3) = ZERO
        gp_wt = W1
      ELSE IF (variant_use == PH_ELEM_C3D8_VARIANT_27PT) THEN
        gp_xi(1) = xi_all(igp)
        gp_xi(2) = eta_all(igp)
        gp_xi(3) = zeta_all(igp)
        gp_wt = weights_all(igp)
      ELSE
        gp_xi(1) = xi_all8(igp)
        gp_xi(2) = eta_all8(igp)
        gp_xi(3) = zeta_all8(igp)
        gp_wt = weights_all8(igp)
      END IF
      
      ! 4.2 Shape functions and derivatives
      sf_shape%xi = gp_xi(1)
      sf_shape%eta = gp_xi(2)
      sf_shape%zeta = gp_xi(3)
      CALL PH_Elem_C3D8_ShapeFunc(sf_shape)
      IF (sf_shape%status%status_code /= IF_STATUS_OK) THEN
        arg%status = sf_shape%status

        RETURN
      END IF
      N = sf_shape%N
      DO i = 1, 8
        dN_dxi(i, 1) = sf_shape%dNdxi(1, i)
        dN_dxi(i, 2) = sf_shape%dNdxi(2, i)
        dN_dxi(i, 3) = sf_shape%dNdxi(3, i)
      END DO

      ! 4.3 Jacobian at PREVIOUS config x_n
      J_prev = ZERO
      DO i = 1, 8
        DO j = 1, 3
          J_prev(1, j) = J_prev(1, j) + dN_dxi(i, j) * arg%coords_prev(1, i)
          J_prev(2, j) = J_prev(2, j) + dN_dxi(i, j) * arg%coords_prev(2, i)
          J_prev(3, j) = J_prev(3, j) + dN_dxi(i, j) * arg%coords_prev(3, i)
        END DO
      END DO
      
      ! 4.4 Invert Jacobian to get dN_dx = dN_dxi ? J???
      CALL Invert3x3(J_prev, J_inv, det_J, arg%status)
      IF (arg%status%status_code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      
      DO i = 1, 8
        dN_dx(i, 1:3) = MATMUL(dN_dxi(i, 1:3), J_inv)  ! ?N????x,y,z) at x_n
      END DO
      
      ! 4.5 Store dN_dx into cfg
      DO i = 1, 8
        cfg%dN_dx(i, 1:3) = dN_dx(i, 1:3)
      END DO
      
      ! 4.6 Compute deformation gradient F and Almansi strain epsilon
      F = ZERO
      DO i = 1, 8
        DO j = 1, 3
          F(1, j) = F(1, j) + coords_curr(1, i) * dN_dx(i, j)  ! ?x_{n+1}/?x_n
          F(2, j) = F(2, j) + coords_curr(2, i) * dN_dx(i, j)
          F(3, j) = F(3, j) + coords_curr(3, i) * dN_dx(i, j)
        END DO
      END DO
      ! Almansi strain: e = 0.5?(I - b???, b = F?F^T
      b = MATMUL(F, TRANSPOSE(F))  ! Left Cauchy-Green tensor
      CALL Invert3x3(b, b_inv, det_b, arg%status)
      IF (arg%status%status_code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      epsilon = ZERO
      epsilon(1,1) = HALF * (ONE - b_inv(1,1))
      epsilon(2,2) = HALF * (ONE - b_inv(2,2))
      epsilon(3,3) = HALF * (ONE - b_inv(3,3))
      epsilon(1,2) = -HALF * b_inv(1,2); epsilon(2,1) = epsilon(1,2)
      epsilon(1,3) = -HALF * b_inv(1,3); epsilon(3,1) = epsilon(1,3)
      epsilon(2,3) = -HALF * b_inv(2,3); epsilon(3,2) = epsilon(2,3)
      
      ! Convert to Voigt notation: [e11, e22, e33, 2*e12, 2*e23, 2*e13]
      epsilon_voigt(1) = epsilon(1,1)
      epsilon_voigt(2) = epsilon(2,2)
      epsilon_voigt(3) = epsilon(3,3)
      epsilon_voigt(4) = 2.0_wp * epsilon(1,2)
      epsilon_voigt(5) = 2.0_wp * epsilon(2,3)
      epsilon_voigt(6) = 2.0_wp * epsilon(1,3)
      
      ! 4.7 Call Mat constitutive model: strain ??stress + tangent
      ss_gp%strain = epsilon_voigt
      ss_gp%strain_inc = epsilon_voigt  ! For UL, strain_inc = e (incremental form)
      CALL PH_UpdateStress(arg%mat_prop, arg%mat_state(igp), ss_gp, mat_status)
      IF (mat_status%status_code /= 0) THEN
        arg%status%status_code = IF_STATUS_ERROR

        RETURN
      END IF
      
      ! 4.8 Convert Cauchy stress back to tensor form
      sigma(1,1) = ss_gp%sigma(1)
      sigma(2,2) = ss_gp%sigma(2)
      sigma(3,3) = ss_gp%sigma(3)
      sigma(1,2) = ss_gp%sigma(4); sigma(2,1) = sigma(1,2)
      sigma(2,3) = ss_gp%sigma(5); sigma(3,2) = sigma(2,3)
      sigma(1,3) = ss_gp%sigma(6); sigma(3,1) = sigma(1,3)
      
      ! 4.9 Call RT layer: compute F, e, ?, K_mat, K_geo, R
      CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, arg%status, R_gp, ss_gp%tangent)
      IF (arg%status%status_code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      
      ! 4.10 Accumulate contributions
      arg%evo%Ke_mat = arg%evo%Ke_mat + K_mat_gp * det_J * gp_wt
      arg%evo%Ke_geo = arg%evo%Ke_geo + K_geo_gp * det_J * gp_wt
      arg%evo%R_int  = arg%evo%R_int  + R_gp * det_J * gp_wt
    END DO
    
    ! Step 5: Cleanup

  CONTAINS
    
    !-----------------------------------------------------------------------------
    ! Helper: REDUCED variant (1-point + hourglass control) for NL_UL
    !-----------------------------------------------------------------------------
    SUBROUTINE PH_ELEM_C3D8_NL_UL_Reduced(coords_prev, coords_curr, u_incr, D, Ke_mat, Ke_geo, R_int, status)
      REAL(wp), INTENT(IN)  :: coords_prev(3, 8), coords_curr(3, 8)
      REAL(wp), INTENT(IN)  :: u_incr(24), D(6, 6)
      REAL(wp), INTENT(OUT) :: Ke_mat(24, 24), Ke_geo(24, 24), R_int(24)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      
      REAL(wp) :: N(8), dN_dxi(8, 3), J_prev(3, 3), J_inv(3, 3), det_J
      REAL(wp) :: dN_dx(8, 3)
      TYPE(RT_LagrCfg) :: cfg
      REAL(wp) :: F(3, 3), epsilon(3, 3), sigma(3, 3)
      REAL(wp) :: K_mat_gp(24, 24), K_geo_gp(24, 24), R_gp(24)
      REAL(wp) :: volume, mu_hg, L_char, invL2, k_hg
      REAL(wp) :: q(3)
      INTEGER(i4) :: i, j, m, a
      
      Ke_mat = ZERO
      Ke_geo = ZERO
      R_int  = ZERO
      status%code = STATUS_SUCCESS
      
      ! Allocate cfg

      cfg%formulation_typ = 2
      DO i = 1, 8
        cfg%coords_prev(i, 1:3) = coords_prev(1:3, i)
        cfg%coords_curr(i, 1:3) = coords_curr(1:3, i)
      END DO
      
      ! 1-point integration at center (0,0,0)
      CALL PH_Elem_C3D8_ShapeFunc(ZERO, ZERO, ZERO, N)
      CALL PH_Elem_C3D8_ShapeFuncDeriv(ZERO, ZERO, ZERO, dN_dxi)
      
      ! Jacobian at center (previous config)
      J_prev = ZERO
      DO i = 1, 8
        DO j = 1, 3
          J_prev(1, j) = J_prev(1, j) + dN_dxi(i, j) * coords_prev(1, i)
          J_prev(2, j) = J_prev(2, j) + dN_dxi(i, j) * coords_prev(2, i)
          J_prev(3, j) = J_prev(3, j) + dN_dxi(i, j) * coords_prev(3, i)
        END DO
      END DO
      CALL Invert3x3(J_prev, J_inv, det_J, status)
      IF (status%code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      
      DO i = 1, 8
        dN_dx(i, 1:3) = MATMUL(dN_dxi(i, 1:3), J_inv)
        cfg%dN_dx(i, 1:3) = dN_dx(i, 1:3)
      END DO
      
      ! Mat contribution (weight W1 = 8.0)
      CALL PH_RT_Elem_GeomNonlin_UpdLag(cfg, F, epsilon, sigma, K_mat_gp, K_geo_gp, status, R_gp)
      IF (status%code /= STATUS_SUCCESS) THEN

        RETURN
      END IF
      Ke_mat = Ke_mat + K_mat_gp * W1 * det_J
      Ke_geo = Ke_geo + K_geo_gp * W1 * det_J
      R_int  = R_int  + R_gp * W1 * det_J
      
      ! Hourglass control (estimate mu from D matrix)
      CALL PH_ELEM_C3D8_Volume_8pt(coords_prev, volume)
      IF (volume > 1.0e-20_wp) THEN
        mu_hg = (D(1,1) + D(2,2) + D(3,3)) / 6.0_wp  ! Approximate shear modulus
        L_char = volume**(1.0_wp/3.0_wp)
        invL2 = ONE / (L_char * L_char)
        k_hg = HG_COEFF * mu_hg * volume * invL2
        
        ! Hourglass stiffness
        DO m = 1, 4
          DO i = 1, 8
            DO j = 1, 8
              DO a = 1, 3
                Ke_mat(3*(i-1)+a, 3*(j-1)+a) = Ke_mat(3*(i-1)+a, 3*(j-1)+a) + &
                  k_hg * GAMMA8(i, m) * GAMMA8(j, m)
              END DO
            END DO
          END DO
        END DO
        
        ! Hourglass force
        DO m = 1, 4
          q = ZERO
          DO i = 1, 8
            q(1) = q(1) + GAMMA8(i, m) * u_incr(3*(i-1)+1)
            q(2) = q(2) + GAMMA8(i, m) * u_incr(3*(i-1)+2)
            q(3) = q(3) + GAMMA8(i, m) * u_incr(3*(i-1)+3)
          END DO
          DO i = 1, 8
            DO a = 1, 3
              R_int(3*(i-1)+a) = R_int(3*(i-1)+a) + k_hg * GAMMA8(i, m) * q(a)
            END DO
          END DO
        END DO
      END IF

    END SUBROUTINE PH_ELEM_C3D8_NL_UL_Reduced
    ! Helper: 3?? matrix inversion (same as TL version)
    SUBROUTINE Invert3x3(A, A_inv, det_A, stat)
      REAL(wp), INTENT(IN)  :: A(3,3)
      REAL(wp), INTENT(OUT) :: A_inv(3,3), det_A
      TYPE(ErrorStatusType), INTENT(OUT) :: stat
      REAL(wp) :: cofac(3,3), tol
      
      tol = 1.0e-14_wp
      det_A = A(1,1)*(A(2,2)*A(3,3) - A(2,3)*A(3,2)) &
            - A(1,2)*(A(2,1)*A(3,3) - A(2,3)*A(3,1)) &
            + A(1,3)*(A(2,1)*A(3,2) - A(2,2)*A(3,1))
      
      IF (ABS(det_A) < tol) THEN
        stat%code = IF_STATUS_ERROR
        RETURN
      END IF
      
      cofac(1,1) = A(2,2)*A(3,3) - A(2,3)*A(3,2)
      cofac(1,2) = A(2,3)*A(3,1) - A(2,1)*A(3,3)
      cofac(1,3) = A(2,1)*A(3,2) - A(2,2)*A(3,1)
      cofac(2,1) = A(1,3)*A(3,2) - A(1,2)*A(3,3)
      cofac(2,2) = A(1,1)*A(3,3) - A(1,3)*A(3,1)
      cofac(2,3) = A(1,2)*A(3,1) - A(1,1)*A(3,2)
      cofac(3,1) = A(1,2)*A(2,3) - A(1,3)*A(2,2)
      cofac(3,2) = A(1,3)*A(2,1) - A(1,1)*A(2,3)
      cofac(3,3) = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      
      A_inv = cofac / det_A
      stat%code = STATUS_SUCCESS
    END SUBROUTINE Invert3x3
    
    ! Helper: ?N/???,?,?) derivatives (same as TL version)
    SUBROUTINE PH_Elem_C3D8_ShapeFuncDeriv(xi, eta, zeta, dN_dxi)
      REAL(wp), INTENT(IN)  :: xi, eta, zeta
      REAL(wp), INTENT(OUT) :: dN_dxi(8, 3)
      REAL(wp) :: xi_nodes(8), eta_nodes(8), zeta_nodes(8)
      INTEGER(i4) :: i
      
      xi_nodes   = (/ -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE /)
      eta_nodes  = (/ -ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE /)
      zeta_nodes = (/ -ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE /)
      
      DO i = 1, 8
        dN_dxi(i, 1) = 0.125_wp * xi_nodes(i)   * (ONE + eta_nodes(i)*eta) * (ONE + zeta_nodes(i)*zeta)
        dN_dxi(i, 2) = 0.125_wp * eta_nodes(i)  * (ONE + xi_nodes(i)*xi)   * (ONE + zeta_nodes(i)*zeta)
        dN_dxi(i, 3) = 0.125_wp * zeta_nodes(i) * (ONE + xi_nodes(i)*xi)   * (ONE + eta_nodes(i)*eta)
      END DO
    END SUBROUTINE PH_Elem_C3D8_ShapeFuncDeriv
    
  END SUBROUTINE PH_Elem_C3D8_NL_UL

  SUBROUTINE PH_Elem_C3D8_NL_UL_Legacy(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status, variant)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 8)
    REAL(wp), INTENT(IN)  :: u_incr(24)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(24, 24)
    REAL(wp), INTENT(OUT) :: Ke_geo(24, 24)
    REAL(wp), INTENT(OUT) :: R_int(24)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: variant
    
    TYPE(PH_Elem_C3D8_NL_UL_Arg) :: in
    TYPE(PH_Elem_C3D8_NL_UL_Arg) :: out
    
    in%coords_prev = coords_prev
    in%u_incr = u_incr
    in%mat_prop = mat_prop
    ALLOCATE(in%mat_state(SIZE(mat_state)))
    in%mat_state = mat_state
    IF (PRESENT(variant)) THEN
      in%variant = variant
    END IF
    
    CALL PH_Elem_C3D8_NL_UL(arg)
    
    Ke_mat = out%evo%Ke_mat
    Ke_geo = out%evo%Ke_geo
    R_int = out%evo%R_int
    status = out%status
    mat_state = out%mat_state
  END SUBROUTINE PH_Elem_C3D8_NL_UL_Legacy

  ! ==========================================================================
  ! PH_Elem_C3D8_NL_TL_FromD / PH_Elem_C3D8_NL_UL_FromD
  ! Simplified interface: accepts D matrix directly (isotropic elastic)
  ! ==========================================================================
  SUBROUTINE PH_Elem_C3D8_NL_TL_FromD(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status, variant)
    REAL(wp), INTENT(IN) :: coords_ref(:, :)
    REAL(wp), INTENT(IN) :: u_elem(:)
    REAL(wp), INTENT(IN) :: D(:, :)
    REAL(wp), INTENT(OUT) :: Ke_mat(:, :)
    REAL(wp), INTENT(OUT) :: Ke_geo(:, :)
    REAL(wp), INTENT(OUT) :: R_int(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: variant
    TYPE(MatPropertyDef) :: mat_prop
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)
    REAL(wp) :: mu, lambda, E, nu, props(2)
    INTEGER(i4) :: n_gp, variant_use

    CALL init_error_status(status)
    variant_use = 1_i4
    IF (PRESENT(variant)) variant_use = variant
    mu = D(4, 4)
    lambda = D(1, 2)
    IF (ABS(mu) < 1.0e-12_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_C3D8_NL_TL_FromD: Invalid D matrix (mu=0)"
      RETURN
    END IF
    IF (ABS(lambda + TWO*mu) < 1.0e-12_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_C3D8_NL_TL_FromD: Invalid D matrix"
      RETURN
    END IF
    nu = lambda / (lambda + TWO*mu)
    E = TWO*mu * (ONE + nu)
    props(1) = E
    props(2) = nu
    CALL UF_MatProp_Init(mat_prop, MAT_ID_ELASTIC_ISOTROPIC_101, 2_i4, props, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    mat_prop%mat_category = MAT_CAT_ELASTIC
    mat_prop%mat_name = "Elastic_Isotropic_FromD"
    ALLOCATE(mat_state(8))
    DO n_gp = 1, 8
      mat_state(n_gp)%mat_id = 0_i4
      mat_state(n_gp)%nStatev = 0_i4
      mat_state(n_gp)%temp = ZERO
      mat_state(n_gp)%temp_old = ZERO
      mat_state(n_gp)%time_step = ZERO
      mat_state(n_gp)%total_time = ZERO
      mat_state(n_gp)%is_initialized = .FALSE.
    END DO
    CALL PH_Elem_C3D8_NL_TL_Legacy(coords_ref(1:3, 1:8), u_elem(1:24), mat_prop, mat_state, &
                                   Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status, variant_use)
    IF (ALLOCATED(mat_state)) DEALLOCATE(mat_state)
    IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
  END SUBROUTINE PH_Elem_C3D8_NL_TL_FromD

  SUBROUTINE PH_Elem_C3D8_NL_UL_FromD(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status, variant)
    REAL(wp), INTENT(IN) :: coords_prev(:, :)
    REAL(wp), INTENT(IN) :: u_incr(:)
    REAL(wp), INTENT(IN) :: D(:, :)
    REAL(wp), INTENT(OUT) :: Ke_mat(:, :)
    REAL(wp), INTENT(OUT) :: Ke_geo(:, :)
    REAL(wp), INTENT(OUT) :: R_int(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: variant
    TYPE(MatPropertyDef) :: mat_prop
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)
    REAL(wp) :: mu, lambda, E, nu, props(2)
    INTEGER(i4) :: n_gp, variant_use

    CALL init_error_status(status)
    variant_use = 1_i4
    IF (PRESENT(variant)) variant_use = variant
    mu = D(4, 4)
    lambda = D(1, 2)
    IF (ABS(mu) < 1.0e-12_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_C3D8_NL_UL_FromD: Invalid D matrix (mu=0)"
      RETURN
    END IF
    IF (ABS(lambda + TWO*mu) < 1.0e-12_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_C3D8_NL_UL_FromD: Invalid D matrix"
      RETURN
    END IF
    nu = lambda / (lambda + TWO*mu)
    E = TWO*mu * (ONE + nu)
    props(1) = E
    props(2) = nu
    CALL UF_MatProp_Init(mat_prop, MAT_ID_ELASTIC_ISOTROPIC_101, 2_i4, props, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    mat_prop%mat_category = MAT_CAT_ELASTIC
    mat_prop%mat_name = "Elastic_Isotropic_FromD"
    ALLOCATE(mat_state(8))
    DO n_gp = 1, 8
      mat_state(n_gp)%mat_id = 0_i4
      mat_state(n_gp)%nStatev = 0_i4
      mat_state(n_gp)%temp = ZERO
      mat_state(n_gp)%temp_old = ZERO
      mat_state(n_gp)%time_step = ZERO
      mat_state(n_gp)%total_time = ZERO
      mat_state(n_gp)%is_initialized = .FALSE.
    END DO
    CALL PH_Elem_C3D8_NL_UL_Legacy(coords_prev(1:3, 1:8), u_incr(1:24), mat_prop, mat_state, &
                                  Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status, variant_use)
    IF (ALLOCATED(mat_state)) DEALLOCATE(mat_state)
    IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
  END SUBROUTINE PH_Elem_C3D8_NL_UL_FromD

  SUBROUTINE PH_Elem_C3D8_ShapeFunc(arg)
    TYPE(PH_Elem_C3D8_ShapeFunc_Arg), INTENT(INOUT) :: arg

    REAL(wp) :: xi_p(8), eta_p(8), zeta_p(8)
    INTEGER(i4) :: i

    CALL init_error_status(arg%status)

    ! Node natural coordinates (ABAQUS hex8 order: bottom 1-4, top 5-8)
    xi_p(1:8)   = [-ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE]
    eta_p(1:8)  = [-ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE]
    zeta_p(1:8) = [-ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE]

    DO i = 1, 8
      arg%N(i) = QUARTER * (ONE + xi_p(i)*arg%xi) * (ONE + eta_p(i)*arg%eta) * (ONE + zeta_p(i)*arg%zeta)
      arg%dNdxi(1, i) = QUARTER * xi_p(i)   * (ONE + eta_p(i)*arg%eta) * (ONE + zeta_p(i)*arg%zeta)
      arg%dNdxi(2, i) = QUARTER * (ONE + xi_p(i)*arg%xi) * eta_p(i)    * (ONE + zeta_p(i)*arg%zeta)
      arg%dNdxi(3, i) = QUARTER * (ONE + xi_p(i)*arg%xi) * (ONE + eta_p(i)*arg%eta) * zeta_p(i)
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_ShapeFunc

  SUBROUTINE PH_Elem_C3D8_StiffMatrix_ArgProc(arg)
    TYPE(PH_Elem_C3D8_StiffMatrix_Arg), INTENT(INOUT) :: arg

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    TYPE(PH_Elem_C3D8_JacB_Arg) :: jb
    REAL(wp) :: BTD(24, 6), dV
    INTEGER(i4) :: ip

    CALL init_error_status(arg%status)

    arg%evo%Ke = ZERO
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)

    jb%coords = arg%coords
    DO ip = 1, 8
      jb%xi = xi(ip)
      jb%eta = eta(ip)
      jb%zeta = zeta(ip)
      CALL PH_Elem_C3D8_JacB(jb)
      IF (jb%status%status_code /= IF_STATUS_OK .OR. ABS(jb%detJ) <= 1.0e-12_wp) CYCLE

      dV = jb%detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(jb%B), arg%D_matrix)
      arg%evo%Ke = arg%evo%Ke + dV * MATMUL(BTD, jb%B)
    END DO

    arg%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Elem_C3D8_StiffMatrix_ArgProc

  SUBROUTINE PH_Elem_C3D8_StiffMatrix27(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young
    REAL(wp), INTENT(IN)  :: nu
    REAL(wp), INTENT(OUT) :: Ke(24, 24)
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: BTD(24, 6), dV
    INTEGER(i4) :: ip
    Ke = ZERO
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    CALL PH_Elem_C3D8_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      BTD = MATMUL(TRANSPOSE(B), D)
      Ke = Ke + dV * MATMUL(BTD, B)
    END DO
  END SUBROUTINE PH_Elem_C3D8_StiffMatrix27

  SUBROUTINE PH_Elem_C3D8_Strain(arg)
    TYPE(PH_Elem_C3D8_Strain_Arg), INTENT(INOUT) :: arg
    
    INTEGER(i4) :: i, j
    
    CALL init_error_status(arg%status)
    
    arg%strain = ZERO
    DO i = 1, 6
      DO j = 1, 24
        arg%strain(i) = arg%strain(i) + arg%B(i, j) * arg%u(j)
      END DO
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_Strain

  SUBROUTINE PH_Elem_C3D8_Stress(arg)
    TYPE(PH_Elem_C3D8_Stress_Arg), INTENT(INOUT) :: arg
    
    INTEGER(i4) :: i, j
    
    CALL init_error_status(arg%status)
    
    arg%sigma = ZERO
    DO i = 1, 6
      DO j = 1, 6
        arg%sigma(i) = arg%sigma(i) + arg%D(i, j) * arg%epsilon(j)
      END DO
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_Stress

  SUBROUTINE PH_Elem_C3D8_Volume27(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D8_GaussPoints27(xi, eta, zeta, weights)
    DO ip = 1, 27
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D8_Volume27

  !=============================================================================
  ! SECTION: Volume, centroid, inertia (merged from PH_Elem_C3D8_Sect)
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: centroid(3)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: volume, dV
    INTEGER(i4) :: ip, i, j

    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 3
        DO j = 1, 8
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) THEN
      centroid(1) = centroid(1) / volume
      centroid(2) = centroid(2) / volume
      centroid(3) = centroid(3) / volume
    END IF
  END SUBROUTINE PH_Elem_C3D8_GetCentroid

  SUBROUTINE PH_Elem_C3D8_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(3, 3)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: x(3), r2, dV
    INTEGER(i4) :: ip, i, j, k

    I_out = ZERO
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      dV = rho * detJ * weights(ip)
      x(1) = ZERO
      x(2) = ZERO
      x(3) = ZERO
      DO k = 1, 8
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
  END SUBROUTINE PH_Elem_C3D8_GetInertiaOrig

  SUBROUTINE PH_Elem_C3D8_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: volume

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: ip

    volume = ZERO
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D8_GetVolume

  SUBROUTINE PH_Elem_C3D8_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp), INTENT(OUT) :: mass

    CALL PH_Elem_C3D8_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D8_GetSectProps

  !=============================================================================
  ! CONSTRAINTS: ApplyConstraint, ApplyMPC (merged from PH_Elem_C3D8_Constraints)
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof    ! local dof 1..24
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(24, 24)
    REAL(wp), INTENT(INOUT) :: F_el(24)

    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 24) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_C3D8_ApplyConstraint

  SUBROUTINE PH_Elem_C3D8_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(24)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(24, 24)
    REAL(wp), INTENT(INOUT) :: F_el(24)

    INTEGER(i4) :: i, j
    DO i = 1, 24
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 24
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_ApplyMPC

  !=============================================================================
  ! CONTACT: FormContactContrib, FormContactFaceCtr (merged from PH_Elem_C3D8_Cont)
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(IN)  :: N(8)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(24, 24)
    REAL(wp), INTENT(INOUT) :: F_el(24)

    REAL(wp) :: f_a(3), k_ab
    INTEGER(i4) :: a, b, ia, ib

    DO a = 1, 8
      ia = 3 * (a - 1) + 1
      f_a(1) = penalty * gap * N(a) * n(1)
      f_a(2) = penalty * gap * N(a) * n(2)
      f_a(3) = penalty * gap * N(a) * n(3)
      F_el(ia)   = F_el(ia)   + f_a(1)
      F_el(ia+1) = F_el(ia+1) + f_a(2)
      F_el(ia+2) = F_el(ia+2) + f_a(3)
    END DO

    DO a = 1, 8
      DO b = 1, 8
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
  END SUBROUTINE PH_Elem_C3D8_FormContactContrib

  SUBROUTINE PH_Elem_C3D8_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: gap
    REAL(wp), INTENT(IN)  :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(24, 24)
    REAL(wp), INTENT(INOUT) :: F_el(24)

    REAL(wp) :: xi, eta, zeta, N(8), n(3), dNdxi(3, 8)
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
    CALL PH_Elem_C3D8_ShapeFunc(xi, eta, zeta, N, dNdxi)
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
    CALL PH_Elem_C3D8_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)
  END SUBROUTINE PH_Elem_C3D8_FormContactFaceCtr

  !=============================================================================
  ! LOADS: FormFacePressure, FormBodyForce, FormGravity, FormNodalForce (merged from PH_Elem_C3D8_Loads)
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8_FormFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(24)

    REAL(wp) :: N(8), dNdxi(3, 8)
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
        CALL PH_Elem_C3D8_ShapeFunc(xi, et, zet, N, dNdxi)
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
        CALL PH_Elem_C3D8_ShapeFunc(xi, et, zet, N, dNdxi)
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
        dA = SQRT(SUM(nvec**2))
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
        CALL PH_Elem_C3D8_ShapeFunc(xi, et, zet, N, dNdxi)
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
        CALL PH_Elem_C3D8_ShapeFunc(xi, et, zet, N, dNdxi)
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
        CALL PH_Elem_C3D8_ShapeFunc(xi, et, zet, N, dNdxi)
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
        CALL PH_Elem_C3D8_ShapeFunc(xi, et, zet, N, dNdxi)
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
  END SUBROUTINE PH_Elem_C3D8_FormFacePressure

  SUBROUTINE PH_Elem_C3D8_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(24)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 8
        F_eq(3*(i-1)+1) = F_eq(3*(i-1)+1) + N(i) * bx * detJ * weights(ip)
        F_eq(3*(i-1)+2) = F_eq(3*(i-1)+2) + N(i) * by * detJ * weights(ip)
        F_eq(3*(i-1)+3) = F_eq(3*(i-1)+3) + N(i) * bz * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_FormBodyForce

  SUBROUTINE PH_Elem_C3D8_FormGravity(coords, rho, g_dir, g_mag, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(IN)  :: g_dir(3)
    REAL(wp), INTENT(IN)  :: g_mag
    REAL(wp), INTENT(OUT) :: F_eq(24)
    REAL(wp) :: bx, by, bz
    bx = rho * g_mag * g_dir(1)
    by = rho * g_mag * g_dir(2)
    bz = rho * g_mag * g_dir(3)
    CALL PH_Elem_C3D8_FormBodyForce(coords, bx, by, bz, F_eq)
  END SUBROUTINE PH_Elem_C3D8_FormGravity

  SUBROUTINE PH_Elem_C3D8_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(24)
    REAL(wp) :: rho, g_dir(3), g_mag
    F_eq = ZERO
    IF (load_type == PH_ELEM_LOAD_BODY) THEN
      CALL PH_Elem_C3D8_FormBodyForce(coords, val(1), val(2), val(3), F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D8_FormFacePressure(coords, val(1), face_id, F_eq)
    ELSE IF (load_type == PH_ELEM_LOAD_GRAV .AND. SIZE(val) >= 5) THEN
      rho = val(1)
      g_dir(1) = val(2)
      g_dir(2) = val(3)
      g_dir(3) = val(4)
      g_mag = val(5)
      CALL PH_Elem_C3D8_FormGravity(coords, rho, g_dir, g_mag, F_eq)
    END IF
  END SUBROUTINE PH_Elem_C3D8_FormNodalForce

  !=============================================================================
  ! OUTPUT: CollectIPVars, MapToNode, GetExtrapMat, Eval* (merged from PH_Elem_C3D8_Out)
  !=============================================================================
  SUBROUTINE invert_8x8(A, info)
    REAL(wp), INTENT(INOUT) :: A(8, 8)
    INTEGER(i4), INTENT(OUT) :: info

    REAL(wp) :: B(8, 8)
    INTEGER(i4) :: i, j, k
    REAL(wp) :: fac

    B = A
    A = ZERO
    DO i = 1, 8
      A(i, i) = ONE
    END DO
    info = 0
    DO k = 1, 8
      IF (ABS(B(k, k)) < 1.0e-14_wp) THEN
        info = -1
        RETURN
      END IF
      fac = ONE / B(k, k)
      B(k, :) = B(k, :) * fac
      A(k, :) = A(k, :) * fac
      DO i = 1, 8
        IF (i == k) CYCLE
        fac = B(i, k)
        B(i, :) = B(i, :) - fac * B(k, :)
        A(i, :) = A(i, :) - fac * A(k, :)
      END DO
    END DO
  END SUBROUTINE invert_8x8

  SUBROUTINE PH_Elem_C3D8_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)

    INTEGER(i4) :: ip, nv
    INTEGER(i4), PARAMETER :: PH_ELEM_N_IP = 8
    INTEGER(i4), PARAMETER :: PH_ELEM_nv_def = 13

    nv = PH_ELEM_nv_def
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, PH_ELEM_N_IP)
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
  END SUBROUTINE PH_Elem_C3D8_CollectIPVars

  SUBROUTINE PH_Elem_C3D8_EvalPrincStress(sigma, principal)
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
  END SUBROUTINE PH_Elem_C3D8_EvalPrincStress

  SUBROUTINE PH_Elem_C3D8_EvalStrainInvar(strain, I1e, J2e)
    REAL(wp), INTENT(IN)  :: strain(6)
    REAL(wp), INTENT(OUT) :: I1e, J2e

    REAL(wp) :: em, edev(6)
    I1e = strain(1) + strain(2) + strain(3)
    em = I1e / 3.0_wp
    edev(1:3) = strain(1:3) - em
    edev(4:6) = strain(4:6)
    J2e = HALF * (edev(1)*edev(1) + edev(2)*edev(2) + edev(3)*edev(3)) &
          + edev(4)*edev(4) + edev(5)*edev(5) + edev(6)*edev(6)
  END SUBROUTINE PH_Elem_C3D8_EvalStrainInvar

  SUBROUTINE PH_Elem_C3D8_EvalStressInvar(sigma, I1, J2, J3)
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
  END SUBROUTINE PH_Elem_C3D8_EvalStressInvar

  SUBROUTINE PH_Elem_C3D8_EvalTriaxiality(sigma, triax)
    REAL(wp), INTENT(IN)  :: sigma(6)
    REAL(wp), INTENT(OUT) :: triax

    REAL(wp) :: I1, J2, J3, p, seq
    CALL PH_Elem_C3D8_EvalStressInvar(sigma, I1, J2, J3)
    p = -I1 / 3.0_wp
    seq = SQRT(3.0_wp * MAX(J2, ZERO))
    IF (seq > 1.0e-20_wp) THEN
      triax = p / seq
    ELSE
      triax = ZERO
    END IF
  END SUBROUTINE PH_Elem_C3D8_EvalTriaxiality

  SUBROUTINE PH_Elem_C3D8_EvalVonMises(sigma, seq)
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
  END SUBROUTINE PH_Elem_C3D8_EvalVonMises

  SUBROUTINE PH_Elem_C3D8_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(8, 8)

    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8)
    REAL(wp) :: A(8, 8), AT(8, 8)
    INTEGER(i4) :: ip, i, j
    INTEGER(i4) :: info

    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    A = ZERO
    DO ip = 1, 8
      CALL PH_Elem_C3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      DO i = 1, 8
        A(i, ip) = N(i)
      END DO
    END DO
    AT = TRANSPOSE(A)
    E = AT
    CALL invert_8x8(E, info)
    IF (info /= 0) E = ZERO
  END SUBROUTINE PH_Elem_C3D8_GetExtrapMat

  SUBROUTINE PH_Elem_C3D8_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)

    REAL(wp) :: E(8, 8)
    INTEGER(i4) :: ic, i, j
    INTEGER(i4) :: n_comp

    node_vars = ZERO
    CALL PH_Elem_C3D8_GetExtrapMat(E)
    n_comp = MIN(SIZE(ip_vars, 2), SIZE(node_vars, 2))
    DO ic = 1, n_comp
      DO i = 1, 8
        DO j = 1, 8
          node_vars(i, ic) = node_vars(i, ic) + E(i, j) * ip_vars(j, ic)
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8_MapToNode

  SUBROUTINE PH_Elem_C3D8_NL_TL_Structured(elem_cfg, elem_state, elem_ctx, mat_cfg, status)
    USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_Ctx
    USE MD_Field_Mgr, ONLY: MD_ElemIPData
    USE MD_Mat_BaseDef, ONLY: MD_Mat_Ctx
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_BuildElasticSlot, &
                                    PH_Elem_MatRoute_Elastic3D

    TYPE(PH_Elem_Desc), INTENT(IN) :: elem_cfg
    TYPE(MD_ElemIPData), INTENT(INOUT) :: elem_state
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: elem_ctx
    TYPE(MD_Mat_Ctx), INTENT(IN) :: mat_cfg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_curr(3, 8), coords_ref(3, 8)
    REAL(wp) :: xi_gp(8), eta_gp(8), zeta_gp(8), wt_gp(8)
    REAL(wp) :: dN_dxi(8, 3), dN_dX(8, 3)
    REAL(wp) :: J_ref(3, 3), det_J, J_inv(3, 3)
    REAL(wp) :: F(3, 3), E_voigt(6), S_voigt(6), D_tangent(6, 6)
    REAL(wp) :: dStrain(6), strain_old(6)
    REAL(wp) :: B_u(6, 24), G(9, 24), S_hat(9, 9), Gt_S_hat(24, 9), BTD(24, 6)
    INTEGER(i4) :: i, igp, nsdv
    REAL(wp) :: sdv_old(max(1, elem_state%num_sdv)), sdv_new(max(1, elem_state%num_sdv))
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_mat_ctx
    TYPE(PH_Mat_Slot) :: mat_slot
    
    elem_ctx%evo%Ke_mat = ZERO
    elem_ctx%evo%Ke_geo = ZERO
    elem_ctx%evo%R_int = ZERO
    status%status_code = IF_STATUS_OK
    nsdv = elem_state%num_sdv

    CALL PH_Elem_MatRoute_BuildElasticSlot(elem_cfg%mat_id, rt_mat_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    coords_ref = elem_cfg%coords0(1:3, 1:8)
    
    DO i = 1, 8
      coords_curr(1, i) = coords_ref(1, i) + elem_ctx%lcl%u_elem(3*i-2)
      coords_curr(2, i) = coords_ref(2, i) + elem_ctx%lcl%u_elem(3*i-1)
      coords_curr(3, i) = coords_ref(3, i) + elem_ctx%lcl%u_elem(3*i)
    END DO
    
    CALL PH_Elem_C3D8_GaussPoints(xi_gp, eta_gp, zeta_gp, wt_gp)
    
    DO igp = 1, 8
      CALL PH_Elem_C3D8_ShapeFuncDeriv(xi_gp(igp), eta_gp(igp), zeta_gp(igp), dN_dxi)
      J_ref = ZERO
      DO i = 1, 8
        J_ref(1, 1) = J_ref(1, 1) + dN_dxi(i, 1) * coords_ref(1, i)
        J_ref(1, 2) = J_ref(1, 2) + dN_dxi(i, 1) * coords_ref(2, i)
        J_ref(1, 3) = J_ref(1, 3) + dN_dxi(i, 1) * coords_ref(3, i)
        J_ref(2, 1) = J_ref(2, 1) + dN_dxi(i, 2) * coords_ref(1, i)
        J_ref(2, 2) = J_ref(2, 2) + dN_dxi(i, 2) * coords_ref(2, i)
        J_ref(2, 3) = J_ref(2, 3) + dN_dxi(i, 2) * coords_ref(3, i)
        J_ref(3, 1) = J_ref(3, 1) + dN_dxi(i, 3) * coords_ref(1, i)
        J_ref(3, 2) = J_ref(3, 2) + dN_dxi(i, 3) * coords_ref(2, i)
        J_ref(3, 3) = J_ref(3, 3) + dN_dxi(i, 3) * coords_ref(3, i)
      END DO
      det_J = J_ref(1, 1)*(J_ref(2, 2)*J_ref(3, 3) - J_ref(2, 3)*J_ref(3, 2)) - &
              J_ref(1, 2)*(J_ref(2, 1)*J_ref(3, 3) - J_ref(2, 3)*J_ref(3, 1)) + &
              J_ref(1, 3)*(J_ref(2, 1)*J_ref(3, 2) - J_ref(2, 2)*J_ref(3, 1))
      IF (ABS(det_J) <= 1.0e-14_wp) CYCLE
      
      J_inv(1, 1) = (J_ref(2, 2)*J_ref(3, 3) - J_ref(2, 3)*J_ref(3, 2)) / det_J
      J_inv(1, 2) = (J_ref(1, 3)*J_ref(3, 2) - J_ref(1, 2)*J_ref(3, 3)) / det_J
      J_inv(1, 3) = (J_ref(1, 2)*J_ref(2, 3) - J_ref(1, 3)*J_ref(2, 2)) / det_J
      J_inv(2, 1) = (J_ref(2, 3)*J_ref(3, 1) - J_ref(2, 1)*J_ref(3, 3)) / det_J
      J_inv(2, 2) = (J_ref(1, 1)*J_ref(3, 3) - J_ref(1, 3)*J_ref(3, 1)) / det_J
      J_inv(2, 3) = (J_ref(1, 3)*J_ref(2, 1) - J_ref(1, 1)*J_ref(2, 3)) / det_J
      J_inv(3, 1) = (J_ref(2, 1)*J_ref(3, 2) - J_ref(2, 2)*J_ref(3, 1)) / det_J
      J_inv(3, 2) = (J_ref(1, 2)*J_ref(3, 1) - J_ref(1, 1)*J_ref(3, 2)) / det_J
      J_inv(3, 3) = (J_ref(1, 1)*J_ref(2, 2) - J_ref(1, 2)*J_ref(2, 1)) / det_J
      
      DO i = 1, 8
        dN_dX(i, 1) = dN_dxi(i,1)*J_inv(1,1) + dN_dxi(i,2)*J_inv(2,1) + dN_dxi(i,3)*J_inv(3,1)
        dN_dX(i, 2) = dN_dxi(i,1)*J_inv(1,2) + dN_dxi(i,2)*J_inv(2,2) + dN_dxi(i,3)*J_inv(3,2)
        dN_dX(i, 3) = dN_dxi(i,1)*J_inv(1,3) + dN_dxi(i,2)*J_inv(2,3) + dN_dxi(i,3)*J_inv(3,3)
      END DO
      
      F = ZERO
      DO i = 1, 8
        F(1, 1) = F(1, 1) + coords_curr(1, i) * dN_dX(i, 1)
        F(1, 2) = F(1, 2) + coords_curr(1, i) * dN_dX(i, 2)
        F(1, 3) = F(1, 3) + coords_curr(1, i) * dN_dX(i, 3)
        F(2, 1) = F(2, 1) + coords_curr(2, i) * dN_dX(i, 1)
        F(2, 2) = F(2, 2) + coords_curr(2, i) * dN_dX(i, 2)
        F(2, 3) = F(2, 3) + coords_curr(2, i) * dN_dX(i, 3)
        F(3, 1) = F(3, 1) + coords_curr(3, i) * dN_dX(i, 1)
        F(3, 2) = F(3, 2) + coords_curr(3, i) * dN_dX(i, 2)
        F(3, 3) = F(3, 3) + coords_curr(3, i) * dN_dX(i, 3)
      END DO
      
      E_voigt(1) = HALF * (F(1,1)*F(1,1) + F(2,1)*F(2,1) + F(3,1)*F(3,1) - ONE)
      E_voigt(2) = HALF * (F(1,2)*F(1,2) + F(2,2)*F(2,2) + F(3,2)*F(3,2) - ONE)
      E_voigt(3) = HALF * (F(1,3)*F(1,3) + F(2,3)*F(2,3) + F(3,3)*F(3,3) - ONE)
      E_voigt(4) = F(1,1)*F(1,2) + F(2,1)*F(2,2) + F(3,1)*F(3,2)
      E_voigt(5) = F(1,2)*F(1,3) + F(2,2)*F(2,3) + F(3,2)*F(3,3)
      E_voigt(6) = F(1,1)*F(1,3) + F(2,1)*F(2,3) + F(3,1)*F(3,3)
      
      strain_old = elem_state%strain_old(1:6, igp)
      dStrain = E_voigt - strain_old
      
      IF (nsdv > 0) sdv_old(1:nsdv) = elem_state%sdv_old(1:nsdv, igp)
      
      CALL PH_Elem_MatRoute_Elastic3D(rt_mat_ctx, mat_slot, dStrain, &
                                               elem_state%stress_old(1:6, igp), &
                                               S_voigt, D_tangent, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      IF (nsdv > 0) sdv_new(1:nsdv) = sdv_old(1:nsdv)
      
      elem_state%strain(1:6, igp) = E_voigt
      elem_state%stress(1:6, igp) = S_voigt
      IF (nsdv > 0) elem_state%sdv(1:nsdv, igp) = sdv_new(1:nsdv)
      
      B_u = ZERO
      DO i = 1, 8
        B_u(1, 3*i-2) = F(1,1) * dN_dX(i, 1)
        B_u(1, 3*i-1) = F(2,1) * dN_dX(i, 1)
        B_u(1, 3*i)   = F(3,1) * dN_dX(i, 1)
        
        B_u(2, 3*i-2) = F(1,2) * dN_dX(i, 2)
        B_u(2, 3*i-1) = F(2,2) * dN_dX(i, 2)
        B_u(2, 3*i)   = F(3,2) * dN_dX(i, 2)
        
        B_u(3, 3*i-2) = F(1,3) * dN_dX(i, 3)
        B_u(3, 3*i-1) = F(2,3) * dN_dX(i, 3)
        B_u(3, 3*i)   = F(3,3) * dN_dX(i, 3)
        
        B_u(4, 3*i-2) = F(1,2) * dN_dX(i, 1) + F(1,1) * dN_dX(i, 2)
        B_u(4, 3*i-1) = F(2,2) * dN_dX(i, 1) + F(2,1) * dN_dX(i, 2)
        B_u(4, 3*i)   = F(3,2) * dN_dX(i, 1) + F(3,1) * dN_dX(i, 2)
        
        B_u(5, 3*i-2) = F(1,3) * dN_dX(i, 2) + F(1,2) * dN_dX(i, 3)
        B_u(5, 3*i-1) = F(2,3) * dN_dX(i, 2) + F(2,2) * dN_dX(i, 3)
        B_u(5, 3*i)   = F(3,3) * dN_dX(i, 2) + F(3,2) * dN_dX(i, 3)
        
        B_u(6, 3*i-2) = F(1,3) * dN_dX(i, 1) + F(1,1) * dN_dX(i, 3)
        B_u(6, 3*i-1) = F(2,3) * dN_dX(i, 1) + F(2,1) * dN_dX(i, 3)
        B_u(6, 3*i)   = F(3,3) * dN_dX(i, 1) + F(3,1) * dN_dX(i, 3)
      END DO
      
      G = ZERO
      DO i = 1, 8
        G(1, 3*i-2) = dN_dX(i, 1)
        G(2, 3*i-2) = dN_dX(i, 2)
        G(3, 3*i-2) = dN_dX(i, 3)
        
        G(4, 3*i-1) = dN_dX(i, 1)
        G(5, 3*i-1) = dN_dX(i, 2)
        G(6, 3*i-1) = dN_dX(i, 3)
        
        G(7, 3*i)   = dN_dX(i, 1)
        G(8, 3*i)   = dN_dX(i, 2)
        G(9, 3*i)   = dN_dX(i, 3)
      END DO
      
      S_hat = ZERO
      S_hat(1,1) = S_voigt(1); S_hat(1,2) = S_voigt(4); S_hat(1,3) = S_voigt(6)
      S_hat(2,1) = S_voigt(4); S_hat(2,2) = S_voigt(2); S_hat(2,3) = S_voigt(5)
      S_hat(3,1) = S_voigt(6); S_hat(3,2) = S_voigt(5); S_hat(3,3) = S_voigt(3)
      S_hat(4:6, 4:6) = S_hat(1:3, 1:3)
      S_hat(7:9, 7:9) = S_hat(1:3, 1:3)
      
      BTD = MATMUL(TRANSPOSE(B_u), D_tangent)
      elem_ctx%evo%Ke_mat = elem_ctx%evo%Ke_mat + MATMUL(BTD, B_u) * det_J * wt_gp(igp)
      
      Gt_S_hat = MATMUL(TRANSPOSE(G), S_hat)
      elem_ctx%evo%Ke_geo = elem_ctx%evo%Ke_geo + MATMUL(Gt_S_hat, G) * det_J * wt_gp(igp)
      
      elem_ctx%evo%R_int = elem_ctx%evo%R_int + MATMUL(TRANSPOSE(B_u), S_voigt) * det_J * wt_gp(igp)
    END DO
    
    elem_ctx%evo%Ke = elem_ctx%evo%Ke_mat + elem_ctx%evo%Ke_geo
  END SUBROUTINE PH_Elem_C3D8_NL_TL_Structured

  SUBROUTINE PH_Elem_C3D8_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
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
  END SUBROUTINE PH_Elem_C3D8_Material_Update_Routed

END MODULE PH_Elem_C3D8



