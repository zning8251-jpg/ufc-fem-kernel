!===============================================================================
! MODULE: PH_Elem_C3D8T
! LAYER:  L4_PH
! DOMAIN: Element/Solid3Dt
! ROLE:   Proc
! BRIEF:  C3D8T unified interface (merged Defn + Sect + Constraints + Cont + Loads + Out)
!===============================================================================
MODULE PH_Elem_C3D8T
!> [CORE] C3D8T element unified interface (merged 6 files)
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatPropertyDef
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE PH_Elem_C3D8, ONLY: &
    PH_Elem_C3D8_ShapeFunc, PH_Elem_C3D8_Jac, PH_Elem_C3D8_BMatrix, &
    PH_Elem_C3D8_ConsMass, PH_Elem_C3D8_LumpMass, PH_Elem_C3D8_ThermStrainVector, &
    PH_Elem_C3D8_GaussPoints, PH_Elem_C3D8_JacB, PH_Elem_C3D8_ConstMatrix, &
    PH_ELEM_C3D8_FACE_NODES, PH_ELEM_GAUSS_PT, &
    PH_Elem_C3D8_FormBodyForce, PH_Elem_C3D8_FormFacePressure, &
    PH_Elem_C3D8_FormGravity, PH_ELEM_LOAD_BODY, PH_ELEM_LOAD_FACE_P, PH_ELEM_LOAD_GRAV
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PARAMETERS
  !=============================================================================
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_NNODE       = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_NIP        = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_NDOF_MECH  = 24_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_NDOF_THERM = 8_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_NDOF_TOTAL = 32_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_FACE_NODES(4, 6) = RESHAPE([ &
    1,2,3,4, 5,8,7,6, 1,2,6,5, 4,3,7,8, 1,4,8,5, 2,6,7,3 ], [4, 6])
  REAL(wp), PARAMETER :: PH_ELEM_C3D8T_GAUSS_PT = 0.577350269189626_wp

  ! Constraint types
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONSTR_MECH_FIXED = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONSTR_MECH_PRESCRIBED = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONSTR_THERM_FIXED = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONSTR_THERM_PRESCRIBED = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONSTR_MIXED = 5_i4

  ! Contact types
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONTACT_NONE = 0_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONTACT_TIED = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONTACT_FRICTIONAL = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONTACT_THERMAL = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONTACT_RADIATION = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_CONTACT_CONVECTION = 5_i4

  ! Load types
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_LOAD_BODY         = PH_ELEM_LOAD_BODY
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_LOAD_FACE_P      = PH_ELEM_LOAD_FACE_P
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_LOAD_GRAV        = PH_ELEM_LOAD_GRAV
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_LOAD_HEAT_SOURCE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_LOAD_THERMAL_FLUX = 5_i4

  ! Section/Material types
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_MATERIAL_ISOTROPIC = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_MATERIAL_ORTHOTROPIC = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_MATERIAL_NONLINEAR = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_MATERIAL_TEMPERATURE_DEPENDENT = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_SECTION_SOLID = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_SECTION_HOLLOW = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_SECTION_LAMINATED = 3_i4

  ! Output types
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_OUTPUT_DISPLACEMENT = 1_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_OUTPUT_STRESS = 2_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_OUTPUT_STRAIN = 3_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_OUTPUT_TEMPERATURE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_OUTPUT_THERMAL_STRESS = 5_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_OUTPUT_VON_MISES = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_OUTPUT_ENERGY = 7_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T_OUTPUT_HEAT_FLUX = 8_i4

  !=============================================================================
  ! TYPES (from Sect, Out)
  !=============================================================================
  TYPE :: PH_ELEM_C3D8T_MaterialProperties
    INTEGER(i4) :: material_type
    REAL(wp) :: density
    REAL(wp) :: young_modulus
    REAL(wp) :: poisson_ratio
    REAL(wp) :: thermal_expansion
    REAL(wp) :: thermal_conductivity
    REAL(wp) :: specific_heat
    REAL(wp) :: reference_temperature
    REAL(wp) :: e_temperature_coefficient
    REAL(wp) :: alpha_temperature_coefficient
    REAL(wp) :: k_temperature_coefficient
    REAL(wp) :: yield_stress
    REAL(wp) :: hardening_modulus
  END TYPE PH_ELEM_C3D8T_MaterialProperties

  TYPE :: PH_ELEM_C3D8T_SectionProperties
    INTEGER(i4) :: section_type
    REAL(wp) :: thickness
    REAL(wp) :: area
    REAL(wp) :: moment_of_inertia(3, 3)
    REAL(wp) :: centroid(3)
    REAL(wp) :: shear_area(3)
  END TYPE PH_ELEM_C3D8T_SectionProperties

  TYPE :: PH_ELEM_C3D8T_OutputData
    REAL(wp) :: nodal_displacements(24)
    REAL(wp) :: nodal_temperatures(8)
    REAL(wp) :: nodal_stresses(6, 8)
    REAL(wp) :: nodal_strains(6, 8)
    REAL(wp) :: von_mises_stress(8)
    REAL(wp) :: thermal_stress(6, 8)
    REAL(wp) :: total_stress(6, 8)
    REAL(wp) :: heat_flux(3, 8)
    REAL(wp) :: element_energy(3)
    REAL(wp) :: integration_points(27, 3)
    REAL(wp) :: point_stresses(6, 27)
    REAL(wp) :: point_temperatures(27)
  END TYPE PH_ELEM_C3D8T_OutputData

  !=============================================================================
  ! PUBLIC
  !=============================================================================
  PUBLIC :: PH_Elem_C3D8T_DefInit
  PUBLIC :: PH_Elem_C3D8T_ThermStrain3D
  PUBLIC :: PH_Elem_C3D8T_FormStiffMatrix
  PUBLIC :: PH_Elem_C3D8T_FormStiffMatrix_MatAware
  PUBLIC :: PH_Elem_C3D8T_FormThermalStiffness
  PUBLIC :: PH_Elem_C3D8T_FormCouplingStiffness
  PUBLIC :: PH_Elem_C3D8T_FormCouplingStiffness_MatAware
  PUBLIC :: PH_Elem_C3D8T_FormIntForce
  PUBLIC :: PH_Elem_C3D8T_FormIntForce_MatAware
  PUBLIC :: PH_Elem_C3D8T_ConsMass
  PUBLIC :: PH_Elem_C3D8T_LumpMass
  PUBLIC :: PH_Elem_C3D8T_ShapeFunc
  PUBLIC :: PH_Elem_C3D8T_Jac
  PUBLIC :: PH_Elem_C3D8T_GaussPoints
  PUBLIC :: PH_Elem_C3D8T_JacB
  PUBLIC :: PH_ELEM_C3D8T_NNODE, PH_ELEM_C3D8T_NIP
  PUBLIC :: PH_ELEM_C3D8T_NDOF_MECH, PH_ELEM_C3D8T_NDOF_THERM, PH_ELEM_C3D8T_NDOF_TOTAL
  PUBLIC :: PH_ELEM_C3D8T_FACE_NODES, PH_ELEM_C3D8T_GAUSS_PT
  PUBLIC :: PH_Elem_C3D8T_GetVolume, PH_Elem_C3D8T_GetSectProps
  PUBLIC :: PH_Elem_C3D8T_GetCentroid, PH_Elem_C3D8T_GetInertiaOrig
  PUBLIC :: PH_Elem_C3D8T_ApplyConstraints
  PUBLIC :: PH_Elem_C3D8T_ApplyPenaltyConstraints
  PUBLIC :: PH_Elem_C3D8T_FormConstraintMatrix
  PUBLIC :: PH_Elem_C3D8T_CheckConstraintCompatibility
  PUBLIC :: PH_Elem_C3D8T_FormContactStiffness
  PUBLIC :: PH_Elem_C3D8T_FormThermalContact
  PUBLIC :: PH_Elem_C3D8T_FormRadiationBoundary
  PUBLIC :: PH_Elem_C3D8T_FormConvectionBoundary
  PUBLIC :: PH_Elem_C3D8T_CalculateContactForces
  PUBLIC :: PH_Elem_C3D8T_FormNodalForce
  PUBLIC :: PH_Elem_C3D8T_FormMechBodyForce
  PUBLIC :: PH_Elem_C3D8T_FormMechFacePressure
  PUBLIC :: PH_Elem_C3D8T_FormMechGravity
  PUBLIC :: PH_Elem_C3D8T_FormThermalBodySource
  PUBLIC :: PH_Elem_C3D8T_FormThermalFaceFlux
  PUBLIC :: PH_ELEM_C3D8T_LOAD_BODY, PH_ELEM_C3D8T_LOAD_FACE_P, PH_ELEM_C3D8T_LOAD_GRAV
  PUBLIC :: PH_ELEM_C3D8T_LOAD_HEAT_SOURCE, PH_ELEM_C3D8T_LOAD_THERMAL_FLUX
  PUBLIC :: PH_Elem_C3D8T_CalculateStressStrain
  PUBLIC :: PH_Elem_C3D8T_CalculateThermalStress
  PUBLIC :: PH_Elem_C3D8T_CalculateVonMisesStress
  PUBLIC :: PH_Elem_C3D8T_CalculateEnergy
  PUBLIC :: PH_Elem_C3D8T_CalculateHeatFlux
  PUBLIC :: PH_Elem_C3D8T_OutputFieldValues
  PUBLIC :: PH_Elem_C3D8T_WriteResultsToFile
  PUBLIC :: PH_Elem_C3D8T_GenerateVisualizationData
  PUBLIC :: PH_Elem_C3D8T_GetMaterialProperties
  PUBLIC :: PH_Elem_C3D8T_GetSectionProperties
  PUBLIC :: PH_Elem_C3D8T_FormElasticityMatrix
  PUBLIC :: PH_Elem_C3D8T_GetThermalProperties
  PUBLIC :: PH_Elem_C3D8T_UpdateTemperatureProperties
  PUBLIC :: PH_Elem_C3D8T_CalculateEffectiveProperties
  PUBLIC :: PH_Elem_C3D8T_Material_Update_Thermo_Routed
  PUBLIC :: PH_ELEM_C3D8T_MaterialProperties
  PUBLIC :: PH_ELEM_C3D8T_SectionProperties
  PUBLIC :: PH_ELEM_C3D8T_OutputData

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

  !=============================================================================
  ! DEFINITION
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8T_FormStiffMatrix_MatAware(coords, mat_prop, mat_state, &
                                                    alpha, k_thermal, T_elem, T_ref, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: alpha, k_thermal, T_ref
    REAL(wp), INTENT(IN)  :: T_elem(8)
    REAL(wp), INTENT(OUT) :: Ke(32, 32)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24)
    REAL(wp) :: dV, D_tangent(6, 6), strain_thermal(6)
    REAL(wp) :: Ke_uu(24, 24), Ke_tt(8, 8), Ke_ut(24, 8)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: ip, i, j

    Ke = ZERO
    Ke_uu = ZERO

    CALL PH_Elem_C3D8T_ThermStrain3D(T_elem, T_ref, alpha, strain_thermal)

    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
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

    Ke(1:24, 1:24) = Ke_uu

    CALL PH_Elem_C3D8T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    Ke(25:32, 25:32) = Ke_tt

    CALL PH_Elem_C3D8T_FormCouplingStiffness_MatAware(coords, D_tangent, alpha, Ke_ut)
    Ke(1:24, 25:32) = Ke_ut
    DO j = 1, 8
      DO i = 1, 24
        Ke(24 + j, i) = Ke_ut(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8T_FormStiffMatrix_MatAware

  SUBROUTINE PH_Elem_C3D8T_FormCouplingStiffness_MatAware(coords, D_tangent, alpha, Ke_ut)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: D_tangent(6, 6)
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(OUT) :: Ke_ut(24, 8)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24)
    REAL(wp) :: beta, dV, B_vol(24)
    INTEGER(i4) :: ip, i

    Ke_ut = ZERO
    IF (ABS(alpha) <= 1.0e-12_wp) RETURN

    beta = D_tangent(1,1) + D_tangent(1,2) + D_tangent(1,3)

    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE

      dV = alpha * beta * detJ * weights(ip)
      B_vol(1:24) = B(1, 1:24) + B(2, 1:24) + B(3, 1:24)

      DO i = 1, 8
        Ke_ut(1:24, i) = Ke_ut(1:24, i) + dV * B_vol(1:24) * N(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8T_FormCouplingStiffness_MatAware

  SUBROUTINE PH_Elem_C3D8T_FormIntForce_MatAware(coords, u, mat_prop, mat_state, &
                                                 alpha, k_thermal, T_elem, T_ref, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(32)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(IN)  :: alpha, k_thermal, T_ref
    REAL(wp), INTENT(IN)  :: T_elem(8)
    REAL(wp), INTENT(OUT) :: R_int(32)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24)
    REAL(wp) :: dV, strain_mech(6), strain_thermal(6), strain_total(6)
    REAL(wp) :: sigma(6), grad_T(3), q_thermal(3)
    REAL(wp) :: Ke_ut(24, 8), D_tangent(6, 6)
    TYPE(PH_MatPoint_StressStrain) :: ss_gp
    TYPE(ErrorStatusType) :: mat_status
    INTEGER(i4) :: ip, i

    R_int = ZERO

    CALL PH_Elem_C3D8T_ThermStrain3D(T_elem, T_ref, alpha, strain_thermal)

    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE

      strain_mech = MATMUL(B, u(1:24))
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

      R_int(1:24) = R_int(1:24) + MATMUL(TRANSPOSE(B), sigma) * dV
    END DO

    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE

      grad_T(1) = DOT_PRODUCT(dNdx(1, :), T_elem)
      grad_T(2) = DOT_PRODUCT(dNdx(2, :), T_elem)
      grad_T(3) = DOT_PRODUCT(dNdx(3, :), T_elem)

      q_thermal = -k_thermal * grad_T

      dV = detJ * weights(ip)

      DO i = 1, 8
        R_int(24 + i) = R_int(24 + i) + ( &
          dNdx(1, i) * q_thermal(1) + &
          dNdx(2, i) * q_thermal(2) + &
          dNdx(3, i) * q_thermal(3) ) * dV
      END DO
    END DO

    CALL PH_Elem_C3D8T_FormCouplingStiffness_MatAware(coords, D_tangent, alpha, Ke_ut)
    R_int(1:24) = R_int(1:24) + MATMUL(Ke_ut, T_elem)
  END SUBROUTINE PH_Elem_C3D8T_FormIntForce_MatAware

  SUBROUTINE PH_Elem_C3D8T_FormCouplingStiffness(coords, E_young, nu, alpha, Ke_ut)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young, nu, alpha
    REAL(wp), INTENT(OUT) :: Ke_ut(24, 8)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24), D(6, 6)
    REAL(wp) :: beta, dV
    REAL(wp) :: B_vol(24)
    INTEGER(i4) :: ip, i
    Ke_ut = ZERO
    IF (ABS(alpha) <= 1.0e-12_wp) RETURN
    CALL PH_Elem_C3D8_ConstMatrix(E_young, nu, D)
    beta = D(1,1) + D(1,2) + D(1,3)
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = alpha * beta * detJ * weights(ip)
      B_vol(1:24) = B(1, 1:24) + B(2, 1:24) + B(3, 1:24)
      DO i = 1, 8
        Ke_ut(1:24, i) = Ke_ut(1:24, i) + dV * B_vol(1:24) * N(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8T_FormCouplingStiffness

  SUBROUTINE PH_Elem_C3D8T_FormStiffMatrix(coords, E_young, nu, alpha, k_thermal, T_ref, Ke)
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(IN)  :: k_thermal
    REAL(wp), INTENT(IN)  :: T_ref
    REAL(wp), INTENT(OUT) :: Ke(32, 32)
    TYPE(MatPropertyDef) :: mat_prop_dummy
    TYPE(PH_MatPoint_State) :: mat_state_dummy(8)
    REAL(wp) :: T_elem(8)
    INTEGER(i4) :: i
    mat_prop_dummy%mat_id = 1
    mat_prop_dummy%num_props = 2
    ALLOCATE(mat_prop_dummy%props(2))
    mat_prop_dummy%props(1) = E_young
    mat_prop_dummy%props(2) = nu
    mat_prop_dummy%num_state_vars = 0
    DO i = 1, 8
      mat_state_dummy(i)%mat_id = 1
      mat_state_dummy(i)%nStatev = 0
      mat_state_dummy(i)%is_initialized = .TRUE.
    END DO
    T_elem = T_ref
    CALL PH_Elem_C3D8T_FormStiffMatrix_MatAware(coords, mat_prop_dummy, mat_state_dummy, &
                                                  alpha, k_thermal, T_elem, T_ref, Ke)
    DEALLOCATE(mat_prop_dummy%props)
  END SUBROUTINE PH_Elem_C3D8T_FormStiffMatrix

  SUBROUTINE PH_Elem_C3D8T_FormThermalStiffness(coords, k_thermal, Ke_tt)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: k_thermal
    REAL(wp), INTENT(OUT) :: Ke_tt(8, 8)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B_dum(6, 24)
    REAL(wp) :: dV
    INTEGER(i4) :: ip
    Ke_tt = ZERO
    IF (k_thermal <= 1.0e-12_wp) RETURN
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B_dum)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = k_thermal * detJ * weights(ip)
      Ke_tt(1:8, 1:8) = Ke_tt(1:8, 1:8) + dV * MATMUL(TRANSPOSE(dNdx), dNdx)
    END DO
  END SUBROUTINE PH_Elem_C3D8T_FormThermalStiffness

  SUBROUTINE PH_Elem_C3D8T_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(32, 32)
    Me = ZERO
    CALL PH_Elem_C3D8_ConsMass(coords, rho, Me(1:24, 1:24))
  END SUBROUTINE PH_Elem_C3D8T_ConsMass

  SUBROUTINE PH_Elem_C3D8T_DefInit()
  END SUBROUTINE PH_Elem_C3D8T_DefInit

  SUBROUTINE PH_Elem_C3D8T_FormIntForce(coords, u, E_young, nu, alpha, k_thermal, T_ref, R_int)
    USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: u(32)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(IN)  :: k_thermal
    REAL(wp), INTENT(IN)  :: T_ref
    REAL(wp), INTENT(OUT) :: R_int(32)
    TYPE(MatPropertyDef) :: mat_prop_dummy
    TYPE(PH_MatPoint_State) :: mat_state_dummy(8)
    REAL(wp) :: T_elem(8)
    INTEGER(i4) :: i

    mat_prop_dummy%mat_id = 1
    mat_prop_dummy%num_props = 2
    ALLOCATE(mat_prop_dummy%props(2))
    mat_prop_dummy%props(1) = E_young
    mat_prop_dummy%props(2) = nu
    mat_prop_dummy%num_state_vars = 0

    DO i = 1, 8
      mat_state_dummy(i)%mat_id = 1
      mat_state_dummy(i)%nStatev = 0
      mat_state_dummy(i)%is_initialized = .TRUE.
    END DO

    T_elem = u(25:32)

    CALL PH_Elem_C3D8T_FormIntForce_MatAware(coords, u, mat_prop_dummy, mat_state_dummy, &
                                               alpha, k_thermal, T_elem, T_ref, R_int)
    DEALLOCATE(mat_prop_dummy%props)
  END SUBROUTINE PH_Elem_C3D8T_FormIntForce

  SUBROUTINE PH_Elem_C3D8T_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(8), eta(8), zeta(8), weights(8)
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)
  END SUBROUTINE PH_Elem_C3D8T_GaussPoints

  SUBROUTINE PH_Elem_C3D8T_Jac(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 8), coords(3, 8)
    REAL(wp), INTENT(OUT) :: J(3, 3), detJ
    CALL PH_Elem_C3D8_Jac(dNdxi, coords, J, detJ)
  END SUBROUTINE PH_Elem_C3D8T_Jac

  SUBROUTINE PH_Elem_C3D8T_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24)
    CALL PH_Elem_C3D8_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)
  END SUBROUTINE PH_Elem_C3D8T_JacB

  SUBROUTINE PH_Elem_C3D8T_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(32)
    M_lumped = ZERO
    CALL PH_Elem_C3D8_LumpMass(coords, rho, M_lumped(1:24))
  END SUBROUTINE PH_Elem_C3D8T_LumpMass

  SUBROUTINE PH_Elem_C3D8T_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(8), dNdxi(3, 8)
    CALL PH_Elem_C3D8_ShapeFunc(xi, eta, zeta, N, dNdxi)
  END SUBROUTINE PH_Elem_C3D8T_ShapeFunc

  SUBROUTINE PH_Elem_C3D8T_ThermStrain3D(T, T_ref, alpha, strain_th)
    REAL(wp), INTENT(IN)  :: T(:)
    REAL(wp), INTENT(IN)  :: T_ref
    REAL(wp), INTENT(IN)  :: alpha
    REAL(wp), INTENT(OUT) :: strain_th(6)
    REAL(wp) :: dT_avg
    INTEGER(i4) :: nNode
    nNode = SIZE(T)
    dT_avg = SUM(T) / REAL(nNode, wp) - T_ref
    strain_th(1:3) = alpha * dT_avg
    strain_th(4:6) = ZERO
  END SUBROUTINE PH_Elem_C3D8T_ThermStrain3D

  !=============================================================================
  ! SECTION
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8T_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: centroid(3)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: volume, dV
    INTEGER(i4) :: ip, i, j
    volume = ZERO
    centroid = ZERO
    CALL PH_Elem_C3D8T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8T_Jac(dNdxi, coords, J, detJ)
      dV = detJ * weights(ip)
      volume = volume + dV
      DO i = 1, 3
        DO j = 1, 8
          centroid(i) = centroid(i) + N(j) * coords(i, j) * dV
        END DO
      END DO
    END DO
    IF (volume > 1.0e-20_wp) centroid = centroid / volume
  END SUBROUTINE PH_Elem_C3D8T_GetCentroid

  SUBROUTINE PH_Elem_C3D8T_GetInertiaOrig(coords, rho, I_out)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: I_out(3, 3)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: x(3), r2, dV
    INTEGER(i4) :: ip, i, j, k
    I_out = ZERO
    CALL PH_Elem_C3D8T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8T_Jac(dNdxi, coords, J, detJ)
      dV = rho * detJ * weights(ip)
      x = ZERO
      DO k = 1, 8
        x = x + N(k) * coords(:, k)
      END DO
      r2 = SUM(x**2)
      DO i = 1, 3
        DO j = 1, 3
          I_out(i, j) = I_out(i, j) - x(i) * x(j) * dV
        END DO
        I_out(i, i) = I_out(i, i) + r2 * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8T_GetInertiaOrig

  SUBROUTINE PH_Elem_C3D8T_GetSectProps(coords, density_in, volume, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: volume, mass
    CALL PH_Elem_C3D8T_GetVolume(coords, volume)
    mass = density_in * volume
  END SUBROUTINE PH_Elem_C3D8T_GetSectProps

  SUBROUTINE PH_Elem_C3D8T_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D8T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8T_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_C3D8T_GetVolume

  !=============================================================================
  ! CONSTRAINTS
  !=============================================================================
  SUBROUTINE ApplyFixedConstraint(K_global, F_global, dof, value, large_stiff)
    REAL(wp), INTENT(INOUT) :: K_global(:, :)
    REAL(wp), INTENT(INOUT) :: F_global(:)
    INTEGER(i4), INTENT(IN) :: dof
    REAL(wp), INTENT(IN) :: value
    REAL(wp), INTENT(IN) :: large_stiff
    INTEGER(i4) :: n_dofs, i
    n_dofs = SIZE(K_global, 1)
    DO i = 1, n_dofs
      K_global(dof, i) = ZERO
      K_global(i, dof) = ZERO
    END DO
    K_global(dof, dof) = large_stiff
    F_global(dof) = large_stiff * value
  END SUBROUTINE ApplyFixedConstraint

  SUBROUTINE PH_Elem_C3D8T_ApplyConstraints(K_global, F_global, constraints, &
                                             dof_indices, prescribed_values)
    REAL(wp), INTENT(INOUT) :: K_global(:, :)
    REAL(wp), INTENT(INOUT) :: F_global(:)
    INTEGER(i4), INTENT(IN) :: constraints(:, :)
    INTEGER(i4), INTENT(OUT) :: dof_indices(:)
    REAL(wp), INTENT(OUT) :: prescribed_values(:)
    INTEGER(i4) :: n_constraints, i, j, global_dof
    REAL(wp) :: large_stiffness
    n_constraints = SIZE(constraints, 1)
    large_stiffness = 1.0e20_wp
    DO i = 1, n_constraints
      SELECT CASE(constraints(i, 1))
        CASE(PH_ELEM_C3D8T_CONSTR_MECH_FIXED)
          DO j = 2, 4
            global_dof = constraints(i, j)
            IF (global_dof > 0) THEN
              CALL ApplyFixedConstraint(K_global, F_global, global_dof, ZERO, large_stiffness)
            END IF
          END DO
        CASE(PH_ELEM_C3D8T_CONSTR_MECH_PRESCRIBED)
          DO j = 2, 4
            global_dof = constraints(i, j)
            IF (global_dof > 0 .AND. j <= SIZE(constraints, 2)) THEN
              CALL ApplyFixedConstraint(K_global, F_global, global_dof, &
                                    constraints(i, j+3), large_stiffness)
            END IF
          END DO
        CASE(PH_ELEM_C3D8T_CONSTR_THERM_FIXED)
          global_dof = constraints(i, 2)
          IF (global_dof > 0) THEN
            CALL ApplyFixedConstraint(K_global, F_global, global_dof, 293.15_wp, large_stiffness)
          END IF
        CASE(PH_ELEM_C3D8T_CONSTR_THERM_PRESCRIBED)
          global_dof = constraints(i, 2)
          IF (global_dof > 0 .AND. SIZE(constraints, 2) >= 3) THEN
            CALL ApplyFixedConstraint(K_global, F_global, global_dof, constraints(i, 3), large_stiffness)
          END IF
        CASE(PH_ELEM_C3D8T_CONSTR_MIXED)
          DO j = 2, 4
            global_dof = constraints(i, j)
            IF (global_dof > 0 .AND. j+4 <= SIZE(constraints, 2)) THEN
              CALL ApplyFixedConstraint(K_global, F_global, global_dof, constraints(i, j+4), large_stiffness)
            END IF
          END DO
          global_dof = constraints(i, 5)
          IF (global_dof > 0 .AND. SIZE(constraints, 2) >= 9) THEN
            CALL ApplyFixedConstraint(K_global, F_global, global_dof, constraints(i, 9), large_stiffness)
          END IF
      END SELECT
    END DO
  END SUBROUTINE PH_Elem_C3D8T_ApplyConstraints

  SUBROUTINE PH_Elem_C3D8T_ApplyPenaltyConstraints(K_global, F_global, constraints, &
                                                 penalty_mech, penalty_thermal)
    REAL(wp), INTENT(INOUT) :: K_global(:, :)
    REAL(wp), INTENT(INOUT) :: F_global(:)
    INTEGER(i4), INTENT(IN) :: constraints(:, :)
    REAL(wp), INTENT(IN) :: penalty_mech
    REAL(wp), INTENT(IN) :: penalty_thermal
    INTEGER(i4) :: n_constraints, i, j, global_dof
    REAL(wp) :: prescribed_value
    n_constraints = SIZE(constraints, 1)
    DO i = 1, n_constraints
      SELECT CASE(constraints(i, 1))
        CASE(PH_ELEM_C3D8T_CONSTR_MECH_FIXED)
          DO j = 2, 4
            global_dof = constraints(i, j)
            IF (global_dof > 0) THEN
              K_global(global_dof, global_dof) = K_global(global_dof, global_dof) + penalty_mech
              F_global(global_dof) = ZERO
            END IF
          END DO
        CASE(PH_ELEM_C3D8T_CONSTR_MECH_PRESCRIBED)
          DO j = 2, 4
            global_dof = constraints(i, j)
            IF (global_dof > 0 .AND. j+3 <= SIZE(constraints, 2)) THEN
              prescribed_value = constraints(i, j+3)
              K_global(global_dof, global_dof) = K_global(global_dof, global_dof) + penalty_mech
              F_global(global_dof) = F_global(global_dof) + penalty_mech * prescribed_value
            END IF
          END DO
        CASE(PH_ELEM_C3D8T_CONSTR_THERM_FIXED)
          global_dof = constraints(i, 2)
          IF (global_dof > 0) THEN
            K_global(global_dof, global_dof) = K_global(global_dof, global_dof) + penalty_thermal
            F_global(global_dof) = penalty_thermal * 293.15_wp
          END IF
        CASE(PH_ELEM_C3D8T_CONSTR_THERM_PRESCRIBED)
          global_dof = constraints(i, 2)
          IF (global_dof > 0 .AND. SIZE(constraints, 2) >= 3) THEN
            prescribed_value = constraints(i, 3)
            K_global(global_dof, global_dof) = K_global(global_dof, global_dof) + penalty_thermal
            F_global(global_dof) = F_global(global_dof) + penalty_thermal * prescribed_value
          END IF
      END SELECT
    END DO
  END SUBROUTINE PH_Elem_C3D8T_ApplyPenaltyConstraints

  SUBROUTINE PH_Elem_C3D8T_FormConstraintMatrix(constraints, C_matrix, rhs_vector)
    INTEGER(i4), INTENT(IN) :: constraints(:, :)
    REAL(wp), INTENT(OUT) :: C_matrix(:, :)
    REAL(wp), INTENT(OUT) :: rhs_vector(:)
    INTEGER(i4) :: n_constraints, n_dofs, i, j, global_dof
    n_constraints = SIZE(constraints, 1)
    n_dofs = SIZE(C_matrix, 1)
    C_matrix = ZERO
    rhs_vector = ZERO
    DO i = 1, n_constraints
      SELECT CASE(constraints(i, 1))
        CASE(PH_ELEM_C3D8T_CONSTR_MECH_FIXED)
          DO j = 2, 4
            global_dof = constraints(i, j)
            IF (global_dof > 0 .AND. i <= SIZE(C_matrix, 2) .AND. i <= SIZE(rhs_vector)) THEN
              C_matrix(global_dof, i) = ONE
              rhs_vector(i) = ZERO
            END IF
          END DO
        CASE(PH_ELEM_C3D8T_CONSTR_MECH_PRESCRIBED)
          DO j = 2, 4
            global_dof = constraints(i, j)
            IF (global_dof > 0 .AND. j+3 <= SIZE(constraints, 2) .AND. &
                i <= SIZE(C_matrix, 2) .AND. i <= SIZE(rhs_vector)) THEN
              C_matrix(global_dof, i) = ONE
              rhs_vector(i) = constraints(i, j+3)
            END IF
          END DO
        CASE(PH_ELEM_C3D8T_CONSTR_THERM_FIXED)
          global_dof = constraints(i, 2)
          IF (global_dof > 0 .AND. i <= SIZE(C_matrix, 2) .AND. i <= SIZE(rhs_vector)) THEN
            C_matrix(global_dof, i) = ONE
            rhs_vector(i) = 293.15_wp
          END IF
        CASE(PH_ELEM_C3D8T_CONSTR_THERM_PRESCRIBED)
          global_dof = constraints(i, 2)
          IF (global_dof > 0 .AND. SIZE(constraints, 2) >= 3 .AND. &
              i <= SIZE(C_matrix, 2) .AND. i <= SIZE(rhs_vector)) THEN
            C_matrix(global_dof, i) = ONE
            rhs_vector(i) = constraints(i, 3)
          END IF
      END SELECT
    END DO
  END SUBROUTINE PH_Elem_C3D8T_FormConstraintMatrix

  FUNCTION PH_Elem_C3D8T_CheckConstraintCompatibility(constraints) RESULT(is_compatible)
    INTEGER(i4), INTENT(IN) :: constraints(:, :)
    LOGICAL :: is_compatible
    INTEGER(i4) :: n_constraints, i, j
    REAL(wp) :: temp_min, temp_max, disp_magnitude
    is_compatible = .TRUE.
    n_constraints = SIZE(constraints, 1)
    DO i = 1, n_constraints
      IF (constraints(i, 1) == PH_ELEM_C3D8T_CONSTR_THERM_PRESCRIBED .AND. SIZE(constraints, 2) >= 3) THEN
        temp_min = 100.0_wp
        temp_max = 2000.0_wp
        IF (constraints(i, 3) < temp_min .OR. constraints(i, 3) > temp_max) THEN
          is_compatible = .FALSE.
          RETURN
        END IF
      END IF
      IF (constraints(i, 1) == PH_ELEM_C3D8T_CONSTR_MECH_PRESCRIBED) THEN
        DO j = 2, 4
          IF (j+3 <= SIZE(constraints, 2)) THEN
            disp_magnitude = ABS(constraints(i, j+3))
            IF (disp_magnitude > 1.0_wp) THEN
              is_compatible = .FALSE.
              RETURN
            END IF
          END IF
        END DO
      END IF
    END DO
  END FUNCTION PH_Elem_C3D8T_CheckConstraintCompatibility

  !=============================================================================
  ! CONTACT (simplified - full implementation in original Cont)
  !=============================================================================
  SUBROUTINE GetFaceNodes(face_id, face_nodes)
    INTEGER(i4), INTENT(IN) :: face_id
    INTEGER(i4), INTENT(OUT) :: face_nodes(4)
    SELECT CASE(face_id)
      CASE(1); face_nodes = [1, 2, 3, 4]
      CASE(2); face_nodes = [5, 8, 7, 6]
      CASE(3); face_nodes = [1, 5, 6, 2]
      CASE(4); face_nodes = [4, 3, 7, 8]
      CASE(5); face_nodes = [1, 4, 8, 5]
      CASE(6); face_nodes = [2, 6, 7, 3]
      CASE DEFAULT; face_nodes = [1, 2, 3, 4]
    END SELECT
  END SUBROUTINE GetFaceNodes

  SUBROUTINE PH_Elem_C3D8T_FormContactStiffness(coords, face_id, contact_type, contact_params, K_contact)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    INTEGER(i4), INTENT(IN) :: face_id
    INTEGER(i4), INTENT(IN) :: contact_type
    REAL(wp), INTENT(IN) :: contact_params(:)
    REAL(wp), INTENT(OUT) :: K_contact(:, :)
    K_contact = ZERO
  END SUBROUTINE PH_Elem_C3D8T_FormContactStiffness

  SUBROUTINE PH_Elem_C3D8T_FormThermalContact(coords, face_id, contact_resistance, K_thermal_contact)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    INTEGER(i4), INTENT(IN) :: face_id
    REAL(wp), INTENT(IN) :: contact_resistance
    REAL(wp), INTENT(OUT) :: K_thermal_contact(:, :)
    K_thermal_contact = ZERO
  END SUBROUTINE PH_Elem_C3D8T_FormThermalContact

  SUBROUTINE PH_Elem_C3D8T_FormConvectionBoundary(coords, face_id, convection_coeff, T_ambient, K_convection, F_convection)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    INTEGER(i4), INTENT(IN) :: face_id
    REAL(wp), INTENT(IN) :: convection_coeff
    REAL(wp), INTENT(IN) :: T_ambient
    REAL(wp), INTENT(OUT) :: K_convection(:, :)
    REAL(wp), INTENT(OUT) :: F_convection(:)
    K_convection = ZERO
    F_convection = ZERO
  END SUBROUTINE PH_Elem_C3D8T_FormConvectionBoundary

  SUBROUTINE PH_Elem_C3D8T_FormRadiationBoundary(coords, face_id, emissivity, stefan_boltzmann, T_ambient, K_radiation, F_radiation)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    INTEGER(i4), INTENT(IN) :: face_id
    REAL(wp), INTENT(IN) :: emissivity
    REAL(wp), INTENT(IN) :: stefan_boltzmann
    REAL(wp), INTENT(IN) :: T_ambient
    REAL(wp), INTENT(OUT) :: K_radiation(:, :)
    REAL(wp), INTENT(OUT) :: F_radiation(:)
    K_radiation = ZERO
    F_radiation = ZERO
  END SUBROUTINE PH_Elem_C3D8T_FormRadiationBoundary

  SUBROUTINE PH_Elem_C3D8T_CalculateContactForces(coords, face_id, contact_type, contact_params, &
                                                   displacements, temperatures, contact_forces, heat_flux)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    INTEGER(i4), INTENT(IN) :: face_id
    INTEGER(i4), INTENT(IN) :: contact_type
    REAL(wp), INTENT(IN) :: contact_params(:)
    REAL(wp), INTENT(IN) :: displacements(24)
    REAL(wp), INTENT(IN) :: temperatures(8)
    REAL(wp), INTENT(OUT) :: contact_forces(24)
    REAL(wp), INTENT(OUT) :: heat_flux(8)
    contact_forces = ZERO
    heat_flux = ZERO
  END SUBROUTINE PH_Elem_C3D8T_CalculateContactForces

  !=============================================================================
  ! LOADS
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8T_FormMechBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(32)
    F_eq = ZERO
    CALL PH_Elem_C3D8_FormBodyForce(coords, bx, by, bz, F_eq(1:24))
  END SUBROUTINE PH_Elem_C3D8T_FormMechBodyForce

  SUBROUTINE PH_Elem_C3D8T_FormMechFacePressure(coords, p, face_id, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: p
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(32)
    F_eq = ZERO
    CALL PH_Elem_C3D8_FormFacePressure(coords, p, face_id, F_eq(1:24))
  END SUBROUTINE PH_Elem_C3D8T_FormMechFacePressure

  SUBROUTINE PH_Elem_C3D8T_FormMechGravity(coords, rho, g_dir, g_mag, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(IN)  :: g_dir(3)
    REAL(wp), INTENT(IN)  :: g_mag
    REAL(wp), INTENT(OUT) :: F_eq(32)
    F_eq = ZERO
    CALL PH_Elem_C3D8_FormGravity(coords, rho, g_dir, g_mag, F_eq(1:24))
  END SUBROUTINE PH_Elem_C3D8T_FormMechGravity

  SUBROUTINE PH_Elem_C3D8T_FormThermalBodySource(coords, Q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: Q
    REAL(wp), INTENT(OUT) :: F_therm(8)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    INTEGER(i4) :: ip, i
    F_therm = ZERO
    CALL PH_Elem_C3D8T_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL PH_Elem_C3D8T_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D8T_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 8
        F_therm(i) = F_therm(i) + N(i) * Q * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_C3D8T_FormThermalBodySource

  SUBROUTINE PH_Elem_C3D8T_FormThermalFaceFlux(coords, face_id, q, F_therm)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(IN)  :: q
    REAL(wp), INTENT(OUT) :: F_therm(8)
    REAL(wp) :: N(8), dNdxi(3, 8)
    REAL(wp) :: dr_dxi(3), dr_deta(3), dA
    REAL(wp) :: xi_f(4), eta_f(4), w_f(4)
    REAL(wp) :: xi, et, zet
    INTEGER(i4) :: nodes(4), ip, i
    F_therm = ZERO
    xi_f(1) = -PH_ELEM_C3D8T_GAUSS_PT
    xi_f(2) = PH_ELEM_C3D8T_GAUSS_PT
    xi_f(3) = -PH_ELEM_C3D8T_GAUSS_PT
    xi_f(4) = PH_ELEM_C3D8T_GAUSS_PT
    eta_f(1) = -PH_ELEM_C3D8T_GAUSS_PT
    eta_f(2) = -PH_ELEM_C3D8T_GAUSS_PT
    eta_f(3) = PH_ELEM_C3D8T_GAUSS_PT
    eta_f(4) = PH_ELEM_C3D8T_GAUSS_PT
    w_f = ONE
    IF (face_id < 1 .OR. face_id > 6) RETURN
    nodes(1:4) = PH_ELEM_C3D8T_FACE_NODES(1:4, face_id)
    SELECT CASE (face_id)
    CASE (1)
      zet = -ONE
      DO ip = 1, 4
        xi = xi_f(ip)
        et = eta_f(ip)
        CALL PH_Elem_C3D8T_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        dA = SQRT(SUM((/ dr_dxi(2)*dr_deta(3)-dr_dxi(3)*dr_deta(2), &
             dr_dxi(3)*dr_deta(1)-dr_dxi(1)*dr_deta(3), &
             dr_dxi(1)*dr_deta(2)-dr_dxi(2)*dr_deta(1) /)**2))
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
        CALL PH_Elem_C3D8T_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(2, nodes(i)) * coords(:, nodes(i))
        END DO
        dA = SQRT(SUM((/ dr_dxi(2)*dr_deta(3)-dr_dxi(3)*dr_deta(2), &
             dr_dxi(3)*dr_deta(1)-dr_dxi(1)*dr_deta(3), &
             dr_dxi(1)*dr_deta(2)-dr_dxi(2)*dr_deta(1) /)**2))
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
        CALL PH_Elem_C3D8T_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(1, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        dA = SQRT(SUM((/ dr_dxi(2)*dr_deta(3)-dr_dxi(3)*dr_deta(2), &
             dr_dxi(3)*dr_deta(1)-dr_dxi(1)*dr_deta(3), &
             dr_dxi(1)*dr_deta(2)-dr_dxi(2)*dr_deta(1) /)**2))
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
        CALL PH_Elem_C3D8T_ShapeFunc(xi, et, zet, N, dNdxi)
        dr_dxi = ZERO
        dr_deta = ZERO
        DO i = 1, 4
          dr_dxi = dr_dxi + dNdxi(2, nodes(i)) * coords(:, nodes(i))
          dr_deta = dr_deta + dNdxi(3, nodes(i)) * coords(:, nodes(i))
        END DO
        dA = SQRT(SUM((/ dr_dxi(2)*dr_deta(3)-dr_dxi(3)*dr_deta(2), &
             dr_dxi(3)*dr_deta(1)-dr_dxi(1)*dr_deta(3), &
             dr_dxi(1)*dr_deta(2)-dr_dxi(2)*dr_deta(1) /)**2))
        IF (dA < 1.0e-15_wp) CYCLE
        DO i = 1, 4
          F_therm(nodes(i)) = F_therm(nodes(i)) + N(nodes(i)) * q * dA * w_f(ip)
        END DO
      END DO
    CASE DEFAULT
    END SELECT
  END SUBROUTINE PH_Elem_C3D8T_FormThermalFaceFlux

  SUBROUTINE PH_Elem_C3D8T_FormNodalForce(load_type, coords, val, face_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp), INTENT(OUT) :: F_eq(32)
    REAL(wp) :: F_mech(24), F_therm(8)
    F_eq = ZERO
    F_mech = ZERO
    F_therm = ZERO
    IF (load_type == PH_ELEM_C3D8T_LOAD_BODY) THEN
      CALL PH_Elem_C3D8_FormBodyForce(coords, val(1), val(2), val(3), F_mech)
    ELSE IF (load_type == PH_ELEM_C3D8T_LOAD_FACE_P .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D8_FormFacePressure(coords, val(1), face_id, F_mech)
    ELSE IF (load_type == PH_ELEM_C3D8T_LOAD_GRAV .AND. SIZE(val) >= 5) THEN
      CALL PH_Elem_C3D8_FormGravity(coords, val(1), val(2:4), val(5), F_mech)
    ELSE IF (load_type == PH_ELEM_C3D8T_LOAD_HEAT_SOURCE .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D8T_FormThermalBodySource(coords, val(1), F_therm)
    ELSE IF (load_type == PH_ELEM_C3D8T_LOAD_THERMAL_FLUX .AND. SIZE(val) >= 1) THEN
      CALL PH_Elem_C3D8T_FormThermalFaceFlux(coords, face_id, val(1), F_therm)
    END IF
    F_eq(1:24) = F_mech
    F_eq(25:32) = F_therm
  END SUBROUTINE PH_Elem_C3D8T_FormNodalForce

  !=============================================================================
  ! SECTION (Material/Section properties - simplified)
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8T_GetMaterialProperties(material_id, temperature, mat_props)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(IN) :: temperature
    TYPE(PH_ELEM_C3D8T_MaterialProperties), INTENT(OUT) :: mat_props
    mat_props%material_type = PH_ELEM_C3D8T_MATERIAL_ISOTROPIC
    mat_props%density = 1000.0_wp
    mat_props%young_modulus = 200.0e9_wp
    mat_props%poisson_ratio = 0.3_wp
    mat_props%thermal_expansion = 10.0e-6_wp
    mat_props%thermal_conductivity = 1.0_wp
    mat_props%specific_heat = 1000.0_wp
    mat_props%reference_temperature = 293.15_wp
  END SUBROUTINE PH_Elem_C3D8T_GetMaterialProperties

  SUBROUTINE PH_Elem_C3D8T_GetSectionProperties(section_id, section_type, section_props)
    INTEGER(i4), INTENT(IN) :: section_id
    INTEGER(i4), INTENT(IN) :: section_type
    TYPE(PH_ELEM_C3D8T_SectionProperties), INTENT(OUT) :: section_props
    section_props%cfg%section_type = PH_ELEM_C3D8T_SECTION_SOLID
    section_props%thickness = 1.0_wp
    section_props%area = 1.0_wp
  END SUBROUTINE PH_Elem_C3D8T_GetSectionProperties

  SUBROUTINE PH_Elem_C3D8T_FormElasticityMatrix(mat_props, D_matrix)
    TYPE(PH_ELEM_C3D8T_MaterialProperties), INTENT(IN) :: mat_props
    REAL(wp), INTENT(OUT) :: D_matrix(6, 6)
    REAL(wp) :: E, nu, lambda, mu
    E = mat_props%young_modulus
    nu = mat_props%poisson_ratio
    lambda = E * nu / ((ONE + nu) * (ONE - 2*nu))
    mu = E / (2.0_wp * (ONE + nu))
    D_matrix = ZERO
    D_matrix(1,1) = lambda + 2*mu
    D_matrix(1,2) = lambda
    D_matrix(1,3) = lambda
    D_matrix(2,1) = lambda
    D_matrix(2,2) = lambda + 2*mu
    D_matrix(2,3) = lambda
    D_matrix(3,1) = lambda
    D_matrix(3,2) = lambda
    D_matrix(3,3) = lambda + 2*mu
    D_matrix(4,4) = mu
    D_matrix(5,5) = mu
    D_matrix(6,6) = mu
  END SUBROUTINE PH_Elem_C3D8T_FormElasticityMatrix

  SUBROUTINE PH_Elem_C3D8T_GetThermalProperties(mat_props, thermal_expansion, thermal_conductivity, specific_heat)
    TYPE(PH_ELEM_C3D8T_MaterialProperties), INTENT(IN) :: mat_props
    REAL(wp), INTENT(OUT) :: thermal_expansion
    REAL(wp), INTENT(OUT) :: thermal_conductivity
    REAL(wp), INTENT(OUT) :: specific_heat
    thermal_expansion = mat_props%thermal_expansion
    thermal_conductivity = mat_props%thermal_conductivity
    specific_heat = mat_props%specific_heat
  END SUBROUTINE PH_Elem_C3D8T_GetThermalProperties

  SUBROUTINE PH_Elem_C3D8T_UpdateTemperatureProperties(mat_props, temperature)
    TYPE(PH_ELEM_C3D8T_MaterialProperties), INTENT(INOUT) :: mat_props
    REAL(wp), INTENT(IN) :: temperature
  END SUBROUTINE PH_Elem_C3D8T_UpdateTemperatureProperties

  SUBROUTINE PH_Elem_C3D8T_CalculateEffectiveProperties(mat_properties, section_props, effective_E, effective_nu, effective_alpha)
    TYPE(PH_ELEM_C3D8T_MaterialProperties), INTENT(IN) :: mat_properties(:)
    TYPE(PH_ELEM_C3D8T_SectionProperties), INTENT(IN) :: section_props
    REAL(wp), INTENT(OUT) :: effective_E
    REAL(wp), INTENT(OUT) :: effective_nu
    REAL(wp), INTENT(OUT) :: effective_alpha
    effective_E = mat_properties(1)%young_modulus
    effective_nu = mat_properties(1)%poisson_ratio
    effective_alpha = mat_properties(1)%thermal_expansion
  END SUBROUTINE PH_Elem_C3D8T_CalculateEffectiveProperties

  !=============================================================================
  ! OUTPUT (nodal extrapolation at parametric nodes; Gauss samples in point_*)
  !=============================================================================
  SUBROUTINE PH_Elem_C3D8T_CalculateStressStrain(coords, D_matrix, displacements, output_data)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    REAL(wp), INTENT(IN) :: D_matrix(6, 6)
    REAL(wp), INTENT(IN) :: displacements(24)
    TYPE(PH_ELEM_C3D8T_OutputData), INTENT(INOUT) :: output_data
    
    REAL(wp) :: xi_n(8), eta_n(8), zeta_n(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24)
    REAL(wp) :: eps(6), sig(6)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    INTEGER(i4) :: n, ip
    
    xi_n   = (/ -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE /)
    eta_n  = (/ -ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE /)
    zeta_n = (/ -ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE /)
    
    output_data%nodal_displacements = displacements
    DO n = 1, 8
      CALL PH_Elem_C3D8T_JacB(coords, xi_n(n), eta_n(n), zeta_n(n), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-14_wp) THEN
        output_data%nodal_strains(:, n) = ZERO
        output_data%nodal_stresses(:, n) = ZERO
      ELSE
        eps = MATMUL(B, displacements)
        sig = MATMUL(D_matrix, eps)
        output_data%nodal_strains(:, n) = eps
        output_data%nodal_stresses(:, n) = sig
      END IF
    END DO
    
    CALL PH_Elem_C3D8T_GaussPoints(xi, eta, zeta, weights)
    output_data%integration_points(1:8, 1) = xi
    output_data%integration_points(1:8, 2) = eta
    output_data%integration_points(1:8, 3) = zeta
    output_data%integration_points(9:27, :) = ZERO
    output_data%point_stresses(:, 9:27) = ZERO
    output_data%point_temperatures = ZERO
    DO ip = 1, 8
      CALL PH_Elem_C3D8T_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-14_wp) THEN
        output_data%point_stresses(:, ip) = ZERO
      ELSE
        eps = MATMUL(B, displacements)
        output_data%point_stresses(:, ip) = MATMUL(D_matrix, eps)
      END IF
    END DO
  END SUBROUTINE PH_Elem_C3D8T_CalculateStressStrain

  SUBROUTINE PH_Elem_C3D8T_CalculateThermalStress(coords, temperatures, thermal_expansion, reference_temperature, output_data, D_matrix)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    REAL(wp), INTENT(IN) :: temperatures(8)
    REAL(wp), INTENT(IN) :: thermal_expansion
    REAL(wp), INTENT(IN) :: reference_temperature
    TYPE(PH_ELEM_C3D8T_OutputData), INTENT(INOUT) :: output_data
    REAL(wp), INTENT(IN), OPTIONAL :: D_matrix(6, 6)
    
    REAL(wp) :: eps_th(6), dT
    INTEGER(i4) :: n
    
    output_data%nodal_temperatures = temperatures
    IF (.NOT. PRESENT(D_matrix)) THEN
      output_data%thermal_stress = ZERO
      output_data%total_stress = output_data%nodal_stresses
      RETURN
    END IF
    
    DO n = 1, 8
      dT = temperatures(n) - reference_temperature
      eps_th = ZERO
      eps_th(1) = thermal_expansion * dT
      eps_th(2) = thermal_expansion * dT
      eps_th(3) = thermal_expansion * dT
      output_data%thermal_stress(:, n) = MATMUL(D_matrix, eps_th)
      output_data%total_stress(:, n) = output_data%nodal_stresses(:, n) - output_data%thermal_stress(:, n)
    END DO
  END SUBROUTINE PH_Elem_C3D8T_CalculateThermalStress

  SUBROUTINE PH_Elem_C3D8T_CalculateVonMisesStress(output_data)
    TYPE(PH_ELEM_C3D8T_OutputData), INTENT(INOUT) :: output_data
    INTEGER(i4) :: n
    REAL(wp) :: s11, s22, s33, s12, s23, s13, vm
    REAL(wp) :: s(6)
    
    DO n = 1, 8
      IF (SUM(ABS(output_data%total_stress(:, n))) > 1.0e-30_wp) THEN
        s = output_data%total_stress(:, n)
      ELSE
        s = output_data%nodal_stresses(:, n)
      END IF
      s11 = s(1); s22 = s(2); s33 = s(3)
      s12 = s(4); s23 = s(5); s13 = s(6)
      vm = SQRT(HALF * ((s11 - s22)**2 + (s22 - s33)**2 + (s33 - s11)**2 &
        + 6.0_wp * (s12**2 + s23**2 + s13**2)))
      output_data%von_mises_stress(n) = vm
    END DO
  END SUBROUTINE PH_Elem_C3D8T_CalculateVonMisesStress

  SUBROUTINE PH_Elem_C3D8T_CalculateEnergy(coords, D_matrix, displacements, temperatures, density, specific_heat, output_data, reference_temperature)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    REAL(wp), INTENT(IN) :: D_matrix(6, 6)
    REAL(wp), INTENT(IN) :: displacements(24)
    REAL(wp), INTENT(IN) :: temperatures(8)
    REAL(wp), INTENT(IN) :: density
    REAL(wp), INTENT(IN) :: specific_heat
    TYPE(PH_ELEM_C3D8T_OutputData), INTENT(INOUT) :: output_data
    REAL(wp), INTENT(IN), OPTIONAL :: reference_temperature
    
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24)
    REAL(wp) :: eps(6), dV, T_gp, U_mech, U_th, T_ref_use
    INTEGER(i4) :: ip
    
    output_data%element_energy = ZERO
    CALL PH_Elem_C3D8T_GaussPoints(xi, eta, zeta, weights)
    U_mech = ZERO
    DO ip = 1, 8
      CALL PH_Elem_C3D8T_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-14_wp) CYCLE
      dV = detJ * weights(ip)
      eps = MATMUL(B, displacements)
      U_mech = U_mech + HALF * dV * DOT_PRODUCT(eps, MATMUL(D_matrix, eps))
    END DO
    output_data%element_energy(1) = U_mech
    
    U_th = ZERO
    IF (PRESENT(reference_temperature)) THEN
      T_ref_use = reference_temperature
      DO ip = 1, 8
        CALL PH_Elem_C3D8T_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
        IF (ABS(detJ) <= 1.0e-14_wp) CYCLE
        dV = detJ * weights(ip)
        T_gp = DOT_PRODUCT(N, temperatures)
        U_th = U_th + HALF * density * specific_heat * dV * (T_gp - T_ref_use)**2
      END DO
    END IF
    output_data%element_energy(2) = U_th
    ! Reserved: coupled / dissipation placeholder
    output_data%element_energy(3) = ZERO
  END SUBROUTINE PH_Elem_C3D8T_CalculateEnergy

  SUBROUTINE PH_Elem_C3D8T_CalculateHeatFlux(coords, temperatures, thermal_conductivity, output_data)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    REAL(wp), INTENT(IN) :: temperatures(8)
    REAL(wp), INTENT(IN) :: thermal_conductivity
    TYPE(PH_ELEM_C3D8T_OutputData), INTENT(INOUT) :: output_data
    
    REAL(wp) :: xi_n(8), eta_n(8), zeta_n(8)
    REAL(wp) :: N(8), dNdx(3, 8), J(3, 3), detJ, B(6, 24)
    REAL(wp) :: gT(3)
    INTEGER(i4) :: n, i
    
    xi_n   = (/ -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE /)
    eta_n  = (/ -ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE /)
    zeta_n = (/ -ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE /)
    
    DO n = 1, 8
      CALL PH_Elem_C3D8T_JacB(coords, xi_n(n), eta_n(n), zeta_n(n), N, dNdx, J, detJ, B)
      gT = ZERO
      DO i = 1, 8
        gT(1) = gT(1) + dNdx(1, i) * temperatures(i)
        gT(2) = gT(2) + dNdx(2, i) * temperatures(i)
        gT(3) = gT(3) + dNdx(3, i) * temperatures(i)
      END DO
      output_data%heat_flux(1, n) = -thermal_conductivity * gT(1)
      output_data%heat_flux(2, n) = -thermal_conductivity * gT(2)
      output_data%heat_flux(3, n) = -thermal_conductivity * gT(3)
    END DO
  END SUBROUTINE PH_Elem_C3D8T_CalculateHeatFlux

  SUBROUTINE PH_Elem_C3D8T_OutputFieldValues(output_data, field_type, output_values)
    TYPE(PH_ELEM_C3D8T_OutputData), INTENT(IN) :: output_data
    INTEGER(i4), INTENT(IN) :: field_type
    REAL(wp), INTENT(OUT) :: output_values(:)
    INTEGER(i4) :: i
    SELECT CASE(field_type)
      CASE(PH_ELEM_C3D8T_OUTPUT_DISPLACEMENT)
        output_values(1:24) = output_data%nodal_displacements
      CASE(PH_ELEM_C3D8T_OUTPUT_TEMPERATURE)
        output_values(1:8) = output_data%nodal_temperatures
      CASE DEFAULT
        output_values = ZERO
    END SELECT
  END SUBROUTINE PH_Elem_C3D8T_OutputFieldValues

  SUBROUTINE PH_Elem_C3D8T_WriteResultsToFile(element_id, output_data, filename)
    INTEGER(i4), INTENT(IN) :: element_id
    TYPE(PH_ELEM_C3D8T_OutputData), INTENT(IN) :: output_data
    CHARACTER(LEN=*), INTENT(IN) :: filename
  END SUBROUTINE PH_Elem_C3D8T_WriteResultsToFile

  SUBROUTINE PH_Elem_C3D8T_GenerateVisualizationData(coords, output_data, vtk_filename)
    REAL(wp), INTENT(IN) :: coords(3, 8)
    TYPE(PH_ELEM_C3D8T_OutputData), INTENT(IN) :: output_data
    CHARACTER(LEN=*), INTENT(IN) :: vtk_filename
  END SUBROUTINE PH_Elem_C3D8T_GenerateVisualizationData

  SUBROUTINE PH_Elem_C3D8T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, &
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

    CALL PH_Elem_MatRoute_ThermoElastic3D(rt_ctx, mat_slot, dStrain_total, &
                                          thermal_strain, stress_old, stress_new, &
                                          D_tangent, status)
  END SUBROUTINE PH_Elem_C3D8T_Material_Update_Thermo_Routed

END MODULE PH_Elem_C3D8T


