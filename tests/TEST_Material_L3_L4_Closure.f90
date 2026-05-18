!===============================================================================
! Module:  TEST_Material_L3_L4_Closure
! Layer:   Tests
! Domain:  Material
! Purpose: Minimal closure test for the P1 Material pillar.
!          Covers L3 material registration and L4 Populate slot reachability.
!
! Status: ACTIVE | P1 MATERIAL CLOSURE | Last verified: 2026-04-27
!===============================================================================
MODULE TEST_Material_L3_L4_Closure
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MAT_CATEGORY_EL, MD_MAT_CATEGORY_PL, &
                        MD_MAT_CATEGORY_DA, MD_MAT_CATEGORY_HY, MD_MAT_CATEGORY_VI, &
                        MD_MAT_CATEGORY_CR, MD_MAT_CATEGORY_CO, MD_MAT_CATEGORY_US, &
                        MD_MAT_CATEGORY_GEOMAT, MD_MAT_CATEGORY_COMPOSITE, &
                        MD_MAT_CATEGORY_MULTIPHYS
  USE PH_Mat_Def, ONLY: PH_Mat_Domain, PH_MAT_ELASTIC, &
                                     PH_MAT_ELASTO_PLASTIC, PH_MAT_HYPERELASTIC, &
                                     PH_MAT_VISCOELASTIC, PH_MAT_CREEP, &
                                     PH_MAT_DAMAGE, PH_MAT_GEOTECH, PH_MAT_COMPOSITE, &
                                     PH_MAT_THERMAL, PH_MAT_USER, PH_MAT_USER_UMAT, &
                                     PH_MAT_ACOUSTIC, PH_MAT_USER_VUMAT, &
                                     PH_Mat_Slot
  USE PH_L4_Populate, ONLY: PH_L4_Populate_Material
  USE PH_L4_L3MatContract, ONLY: PH_MapL3MatTypeToL4, PH_MapL3ClassToDefaultMatId, &
                                 MAT_ID_PLASTIC_DEFAULT, MAT_ID_GEOTECH_DEFAULT, &
                                 MAT_ID_COMPOSITE_DEFAULT, MAT_ID_THERMAL_DEFAULT
  USE RT_Mat_Def, ONLY: RT_Mat_Dispatch_Table, RT_Mat_Dispatch_Ctx, &
                        RT_MAT_ROUTE_OK
  USE RT_Mat_Core, ONLY: RT_Mat_Init_Table
  USE RT_Mat_Brg, ONLY: RT_Mat_Brg_BuildTable_FromMaterial, &
                        RT_Mat_Brg_MakeCtx
  USE PH_Elem_CPE3, ONLY: PH_Elem_CPE3_Material_Update_Routed
  USE PH_Elem_CPE4, ONLY: PH_Elem_CPE4_Material_Update_Routed
  USE PH_Elem_CPE6, ONLY: PH_Elem_CPE6_Material_Update_Routed
  USE PH_Elem_CPE8, ONLY: PH_Elem_CPE8_Material_Update_Routed
  USE PH_Elem_CPS3, ONLY: PH_Elem_CPS3_Material_Update_Routed
  USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_Material_Update_Routed
  USE PH_Elem_CPS6, ONLY: PH_Elem_CPS6_Material_Update_Routed
  USE PH_Elem_CPS8, ONLY: PH_Elem_CPS8_Material_Update_Routed
  USE PH_Elem_CAX3, ONLY: PH_Elem_CAX3_Material_Update_Routed
  USE PH_Elem_CAX4, ONLY: PH_Elem_CAX4_Material_Update_Routed
  USE PH_Elem_CAX6, ONLY: PH_Elem_CAX6_Material_Update_Routed
  USE PH_Elem_CAX8, ONLY: PH_Elem_CAX8_Material_Update_Routed
  USE PH_Elem_C3D4, ONLY: PH_Elem_C3D4_Material_Update_Routed
  USE PH_Elem_C3D5, ONLY: PH_Elem_C3D5_Material_Update_Routed
  USE PH_Elem_C3D6, ONLY: PH_Elem_C3D6_Material_Update_Routed
  USE PH_Elem_C3D8, ONLY: PH_Elem_C3D8_Material_Update_Routed
  USE PH_Elem_C3D8EAS, ONLY: PH_Elem_C3D8_EAS_Material_Update_Routed
  USE PH_Elem_C3D8FBar, ONLY: PH_Elem_C3D8_FBar_Material_Update_Routed
  USE PH_Elem_C3D10, ONLY: PH_Elem_C3D10_Material_Update_Routed
  USE PH_Elem_C3D13, ONLY: PH_Elem_C3D13_Material_Update_Routed
  USE PH_Elem_C3D15, ONLY: PH_Elem_C3D15_Material_Update_Routed
  USE PH_Elem_C3D20, ONLY: PH_Elem_C3D20_Material_Update_Routed
  USE PH_Elem_C3D27, ONLY: PH_Elem_C3D27_Material_Update_Routed
  USE PH_Elem_T2D2, ONLY: PH_Elem_T2D2_Material_Update_Routed
  USE PH_Elem_T3D2, ONLY: PH_Elem_T3D2_Material_Update_Routed
  USE PH_Elem_T3D3, ONLY: PH_Elem_T3D3_Material_Update_Routed
  USE PH_Elem_SPRING1, ONLY: PH_Elem_SPRING1_Material_Update_Routed
  USE PH_Elem_SPRING2, ONLY: PH_Elem_SPRING2_Material_Update_Routed
  USE PH_Elem_Pipe, ONLY: PH_Elem_PIPE21_Material_Update_Routed, &
                         PH_Elem_PIPE22_Material_Update_Routed
  USE PH_Elem_DASHPOT1, ONLY: PH_Elem_DASHPOT1_Material_Update_Routed
  USE PH_Elem_DASHPOT2, ONLY: PH_Elem_DASHPOT2_Material_Update_Routed
  USE PH_Elem_Mass, ONLY: PH_Elem_Mass_Material_Update_Routed
  USE PH_Elem_BeamDefn, ONLY: PH_Elem_Beam_Material_Update_Routed
  USE PH_Elem_AcousticDefn, ONLY: PH_Elem_Acoustic_Material_Update_Routed
  USE PH_Elem_CohesiveDefn, ONLY: PH_Elem_Cohesive_Material_Update_Routed
  USE PH_Elem_GasketDefn, ONLY: PH_Elem_Gasket_Material_Update_Routed
  USE PH_Elem_Infinite, ONLY: PH_Elem_Infinite_Material_Update_Decay_Routed
  USE PH_Elem_Porous, ONLY: PH_Elem_Porous_Material_Update_TwoPhase_Routed
  USE PH_Elem_Membrane, ONLY: PH_Elem_M3D9R_Material_Update_Routed
  USE PH_Elem_S3, ONLY: PH_Elem_S3_Material_Update_Membrane_Routed
  USE PH_Elem_S4, ONLY: PH_Elem_S4_Material_Update_Membrane_Routed
  USE PH_Elem_S4T, ONLY: PH_Elem_S4T_Material_Update_Membrane_Routed, &
                         PH_Elem_S4T_Material_Update_Thermal_Routed
  USE PH_Elem_S6, ONLY: PH_Elem_S6_Material_Update_Membrane_Routed
  USE PH_Elem_S8, ONLY: PH_Elem_S8_Material_Update_Membrane_Routed
  USE PH_Elem_S8RT, ONLY: PH_Elem_S8RT_Material_Update_Membrane_Routed, &
                          PH_Elem_S8RT_Material_Update_Thermal_Routed
  USE PH_Elem_S9, ONLY: PH_Elem_S9_Material_Update_Membrane_Routed
  USE PH_Elem_DS3, ONLY: PH_Elem_DS3_Material_Update_Thermal_Routed
  USE PH_Elem_DS4, ONLY: PH_Elem_DS4_Material_Update_Thermal_Routed
  USE PH_Elem_DS6, ONLY: PH_Elem_DS6_Material_Update_Thermal_Routed
  USE PH_Elem_DS8, ONLY: PH_Elem_DS8_Material_Update_Thermal_Routed
  USE PH_Elem_CPE3T, ONLY: PH_Elem_CPE3T_Material_Update_Thermo_Routed
  USE PH_Elem_CPE4T, ONLY: PH_Elem_CPE4T_Material_Update_Thermo_Routed
  USE PH_Elem_CPE6T, ONLY: PH_Elem_CPE6T_Material_Update_Thermo_Routed
  USE PH_Elem_CPE8T, ONLY: PH_Elem_CPE8T_Material_Update_Thermo_Routed
  USE PH_Elem_CPS3T, ONLY: PH_Elem_CPS3T_Material_Update_Thermo_Routed
  USE PH_Elem_CPS4T, ONLY: PH_Elem_CPS4T_Material_Update_Thermo_Routed
  USE PH_Elem_CPS6T, ONLY: PH_Elem_CPS6T_Material_Update_Thermo_Routed
  USE PH_Elem_CPS8T, ONLY: PH_Elem_CPS8T_Material_Update_Thermo_Routed
  USE PH_Elem_CAX3T, ONLY: PH_Elem_CAX3T_Material_Update_Thermo_Routed
  USE PH_Elem_CAX4T, ONLY: PH_Elem_CAX4T_Material_Update_Thermo_Routed
  USE PH_Elem_CAX6T, ONLY: PH_Elem_CAX6T_Material_Update_Thermo_Routed
  USE PH_Elem_CAX8T, ONLY: PH_Elem_CAX8T_Material_Update_Thermo_Routed
  USE PH_Elem_C3D4T, ONLY: PH_Elem_C3D4T_Material_Update_Thermo_Routed
  USE PH_Elem_C3D6T, ONLY: PH_Elem_C3D6T_Material_Update_Thermo_Routed
  USE PH_Elem_C3D8T, ONLY: PH_Elem_C3D8T_Material_Update_Thermo_Routed
  USE PH_Elem_C3D10T, ONLY: PH_Elem_C3D10T_Material_Update_Thermo_Routed
  USE PH_Elem_C3D15T, ONLY: PH_Elem_C3D15T_Material_Update_Thermo_Routed
  USE PH_Elem_C3D20T, ONLY: PH_Elem_C3D20T_Material_Update_Thermo_Routed
  USE PH_Elem_C3D27T, ONLY: PH_Elem_C3D27T_Material_Update_Thermo_Routed
  USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_AcousticFluid, &
                                  PH_Elem_MatRoute_BeamElasticConstants, &
                                  PH_Elem_MatRoute_CohesiveLinear, &
                                  PH_Elem_MatRoute_DashpotScalar, &
                                  PH_Elem_MatRoute_ElasticUniaxial, &
                                  PH_Elem_MatRoute_GasketLinear, &
                                  PH_Elem_MatRoute_InfiniteDecay, &
                                  PH_Elem_MatRoute_MassScalar, &
                                  PH_Elem_MatRoute_PorousTwoPhase, &
                                  PH_Elem_MatRoute_ThermoElastic3D, &
                                  PH_Elem_MatRoute_ThermoElasticAxisymmetric, &
                                  PH_Elem_MatRoute_ThermoElasticPlaneStrain, &
                                  PH_Elem_MatRoute_ThermoElasticPlaneStress, &
                                  PH_Elem_MatRoute_ThermalConductivityScalar
  USE MD_Ana_Comp, ONLY: AC_N_MAT_FAM, AC_GROUP_STRUCTURAL, AC_GROUP_THERMAL, &
                         AC_GROUP_ACOUSTIC, AC_GROUP_EM, MD_Ana_Comp_CheckGroupMat
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Material_L3_L4_Closure_Test

  REAL(wp), PARAMETER :: TOL = 1.0E-10_wp

CONTAINS

  SUBROUTINE Run_Material_L3_L4_Closure_Test(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    INTEGER(i4) :: n_passed
    INTEGER(i4) :: n_failed

    n_passed = 0_i4
    n_failed = 0_i4

    CALL test_elastic_material_populate(n_passed, n_failed)
    CALL test_plastic_material_populate_route(n_passed, n_failed)
    CALL test_material_family_governance_matrix(n_passed, n_failed)
    CALL test_l4_material_governance_contract(n_passed, n_failed)
    CALL test_l4_l3_material_mapping_contract(n_passed, n_failed)
    CALL test_cpe3_material_routed_helper(n_passed, n_failed)
    CALL test_cpe4_material_routed_helper(n_passed, n_failed)
    CALL test_cpe6_material_routed_helper(n_passed, n_failed)
    CALL test_cpe8_material_routed_helper(n_passed, n_failed)
    CALL test_cps3_material_routed_helper(n_passed, n_failed)
    CALL test_cps4_material_routed_helper(n_passed, n_failed)
    CALL test_cps6_material_routed_helper(n_passed, n_failed)
    CALL test_cps8_material_routed_helper(n_passed, n_failed)
    CALL test_cax3_material_routed_helper(n_passed, n_failed)
    CALL test_cax4_material_routed_helper(n_passed, n_failed)
    CALL test_cax6_material_routed_helper(n_passed, n_failed)
    CALL test_cax8_material_routed_helper(n_passed, n_failed)
    CALL test_c3d4_material_routed_helper(n_passed, n_failed)
    CALL test_c3d5_material_routed_helper(n_passed, n_failed)
    CALL test_c3d6_material_routed_helper(n_passed, n_failed)
    CALL test_c3d8_material_routed_helper(n_passed, n_failed)
    CALL test_c3d8_eas_material_routed_helper(n_passed, n_failed)
    CALL test_c3d8_fbar_material_routed_helper(n_passed, n_failed)
    CALL test_c3d10_material_routed_helper(n_passed, n_failed)
    CALL test_c3d13_material_routed_helper(n_passed, n_failed)
    CALL test_c3d15_material_routed_helper(n_passed, n_failed)
    CALL test_c3d20_material_routed_helper(n_passed, n_failed)
    CALL test_c3d27_material_routed_helper(n_passed, n_failed)
    CALL test_uniaxial_route_helper(n_passed, n_failed)
    CALL test_dashpot_scalar_route_helper(n_passed, n_failed)
    CALL test_thermal_conductivity_route_helper(n_passed, n_failed)
    CALL test_mass_scalar_route_helper(n_passed, n_failed)
    CALL test_beam_elastic_constants_route_helper(n_passed, n_failed)
    CALL test_acoustic_fluid_route_helper(n_passed, n_failed)
    CALL test_cohesive_linear_route_helper(n_passed, n_failed)
    CALL test_gasket_linear_route_helper(n_passed, n_failed)
    CALL test_infinite_decay_route_helper(n_passed, n_failed)
    CALL test_porous_twophase_route_helper(n_passed, n_failed)
    CALL test_t2d2_material_routed_helper(n_passed, n_failed)
    CALL test_t3d2_material_routed_helper(n_passed, n_failed)
    CALL test_t3d3_material_routed_helper(n_passed, n_failed)
    CALL test_spring1_material_routed_helper(n_passed, n_failed)
    CALL test_spring2_material_routed_helper(n_passed, n_failed)
    CALL test_pipe21_material_routed_helper(n_passed, n_failed)
    CALL test_pipe22_material_routed_helper(n_passed, n_failed)
    CALL test_dashpot1_material_routed_helper(n_passed, n_failed)
    CALL test_dashpot2_material_routed_helper(n_passed, n_failed)
    CALL test_mass_material_routed_helper(n_passed, n_failed)
    CALL test_beam_material_routed_helper(n_passed, n_failed)
    CALL test_acoustic_material_routed_helper(n_passed, n_failed)
    CALL test_cohesive_material_routed_helper(n_passed, n_failed)
    CALL test_gasket_material_routed_helper(n_passed, n_failed)
    CALL test_infinite_decay_material_routed_helper(n_passed, n_failed)
    CALL test_porous_twophase_material_routed_helper(n_passed, n_failed)
    CALL test_m3d9r_material_routed_helper(n_passed, n_failed)
    CALL test_s3_membrane_material_routed_helper(n_passed, n_failed)
    CALL test_s4_membrane_material_routed_helper(n_passed, n_failed)
    CALL test_s4t_membrane_material_routed_helper(n_passed, n_failed)
    CALL test_s4t_thermal_material_routed_helper(n_passed, n_failed)
    CALL test_s6_membrane_material_routed_helper(n_passed, n_failed)
    CALL test_s8_membrane_material_routed_helper(n_passed, n_failed)
    CALL test_s8rt_membrane_material_routed_helper(n_passed, n_failed)
    CALL test_s8rt_thermal_material_routed_helper(n_passed, n_failed)
    CALL test_s9_membrane_material_routed_helper(n_passed, n_failed)
    CALL test_ds3_material_thermal_routed_helper(n_passed, n_failed)
    CALL test_ds4_material_thermal_routed_helper(n_passed, n_failed)
    CALL test_ds6_material_thermal_routed_helper(n_passed, n_failed)
    CALL test_ds8_material_thermal_routed_helper(n_passed, n_failed)
    CALL test_thermo_plane_strain_route_helper(n_passed, n_failed)
    CALL test_thermo_plane_stress_route_helper(n_passed, n_failed)
    CALL test_thermo_axisym_route_helper(n_passed, n_failed)
    CALL test_thermo_3d_route_helper(n_passed, n_failed)
    CALL test_cpe3t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cpe4t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cpe6t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cpe8t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cps3t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cps4t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cps6t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cps8t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cax3t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cax4t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cax6t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_cax8t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_c3d4t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_c3d6t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_c3d8t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_c3d10t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_c3d15t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_c3d20t_material_thermo_routed_helper(n_passed, n_failed)
    CALL test_c3d27t_material_thermo_routed_helper(n_passed, n_failed)

    all_passed = (n_failed == 0_i4)
    WRITE(*,'(A,I4,A,I4,A)') "[TEST_Material_L3_L4_Closure] ", n_passed, &
                              " passed, ", n_failed, " failed"
  END SUBROUTINE Run_Material_L3_L4_Closure_Test

  SUBROUTINE test_elastic_material_populate(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(MD_L3_LayerContainer) :: md_layer
    TYPE(MD_Mat_Desc), TARGET :: mat_desc
    TYPE(PH_Mat_Domain) :: ph_material
    TYPE(RT_Mat_Dispatch_Table) :: rt_table
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status

    CALL md_layer%material%Init(status)
    IF (.NOT. expect_ok(status, "l3 material init", n_failed)) RETURN

    CALL mat_desc%Init(status)
    IF (.NOT. expect_ok(status, "material desc init", n_failed)) RETURN
    mat_desc%id = 101_i4
    mat_desc%name = "ELASTIC-1"
    mat_desc%class_id = MD_MAT_CATEGORY_EL
    mat_desc%materialType = "ELASTIC"
    mat_desc%behavior = "ISOTROPIC"
    mat_desc%nProps = 2_i4
    ALLOCATE(mat_desc%props(2))
    mat_desc%props(1) = 210.0E9_wp
    mat_desc%props(2) = 0.30_wp

    CALL md_layer%material%Register(mat_desc, 1_i4, status)
    IF (.NOT. expect_ok(status, "l3 material register", n_failed)) RETURN

    CALL ph_material%Init(1_i4, status)
    IF (.NOT. expect_ok(status, "l4 material init", n_failed)) RETURN

    CALL PH_L4_Populate_Material(ph_material, 1_i4, status, md_src=md_layer)
    IF (.NOT. expect_ok(status, "l4 material populate", n_failed)) RETURN

    IF (ph_material%pool_count == 1_i4 .AND. &
        ph_material%slot_pool(1)%desc%cfg%matId == 1_i4 .AND. &
        ph_material%slot_pool(1)%desc%cfg%matModel == PH_MAT_ELASTIC .AND. &
        ALLOCATED(ph_material%slot_pool(1)%desc%props) .AND. &
        ALLOCATED(ph_material%slot_pool(1)%state%comp%C_tan) .AND. &
        ABS(ph_material%slot_pool(1)%desc%props(1) - 210.0E9_wp) < 1.0E3_wp .AND. &
        ABS(ph_material%slot_pool(1)%desc%props(2) - 0.30_wp) < TOL) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: material populate elastic slot contract"
      RETURN
    END IF

    CALL RT_Mat_Init_Table(rt_table, status)
    IF (.NOT. expect_ok(status, "l5 material route table init", n_failed)) RETURN

    CALL RT_Mat_Brg_BuildTable_FromMaterial(rt_table, ph_material, status)
    IF (.NOT. expect_ok(status, "l5 material route build", n_failed)) RETURN

    CALL RT_Mat_Brg_MakeCtx(rt_table, 1_i4, rt_ctx, status)
    IF (.NOT. expect_ok(status, "l5 material make ctx", n_failed)) RETURN

    IF (rt_table%n_entries == 1_i4 .AND. &
        rt_ctx%mat_type == PH_MAT_ELASTIC .AND. &
        rt_ctx%mat_id == 1_i4 .AND. rt_ctx%mat_pt_idx == 1_i4 .AND. &
        rt_ctx%route_status == RT_MAT_ROUTE_OK) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: material l5 route contract"
    END IF
  END SUBROUTINE test_elastic_material_populate

  SUBROUTINE test_plastic_material_populate_route(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(MD_L3_LayerContainer) :: md_layer
    TYPE(MD_Mat_Desc), TARGET :: mat_desc
    TYPE(PH_Mat_Domain) :: ph_material
    TYPE(RT_Mat_Dispatch_Table) :: rt_table
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status

    CALL md_layer%material%Init(status)
    IF (.NOT. expect_ok(status, "l3 plastic material init", n_failed)) RETURN

    CALL mat_desc%Init(status)
    IF (.NOT. expect_ok(status, "plastic material desc init", n_failed)) RETURN
    mat_desc%id = MAT_ID_PLASTIC_DEFAULT
    mat_desc%name = "PLASTIC-J2-1"
    mat_desc%class_id = MD_MAT_CATEGORY_PL
    mat_desc%materialType = "PLASTIC"
    mat_desc%behavior = "J2"
    mat_desc%nProps = 3_i4
    ALLOCATE(mat_desc%props(3))
    mat_desc%props(1) = 250.0E6_wp
    mat_desc%props(2) = 1.0E9_wp
    mat_desc%props(3) = 0.0_wp

    CALL md_layer%material%Register(mat_desc, 1_i4, status)
    IF (.NOT. expect_ok(status, "l3 plastic material register", n_failed)) RETURN

    CALL ph_material%Init(1_i4, status)
    IF (.NOT. expect_ok(status, "l4 plastic material init", n_failed)) RETURN

    CALL PH_L4_Populate_Material(ph_material, 1_i4, status, md_src=md_layer)
    IF (.NOT. expect_ok(status, "l4 plastic material populate", n_failed)) RETURN

    IF (ph_material%pool_count == 1_i4 .AND. &
        ph_material%slot_pool(1)%desc%cfg%matModel == PH_MAT_ELASTO_PLASTIC .AND. &
        ph_material%slot_pool(1)%desc%pop%mat_model_id == MAT_ID_PLASTIC_DEFAULT .AND. &
        ALLOCATED(ph_material%slot_pool(1)%desc%props) .AND. &
        ALLOCATED(ph_material%slot_pool(1)%state%evo%stateVars) .AND. &
        ALLOCATED(ph_material%slot_pool(1)%state%evo%stateVars_n) .AND. &
        ALLOCATED(ph_material%slot_pool(1)%state%comp%stress)) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: plastic material populate slot contract"
      RETURN
    END IF

    CALL RT_Mat_Init_Table(rt_table, status)
    IF (.NOT. expect_ok(status, "l5 plastic route table init", n_failed)) RETURN

    CALL RT_Mat_Brg_BuildTable_FromMaterial(rt_table, ph_material, status)
    IF (.NOT. expect_ok(status, "l5 plastic route build", n_failed)) RETURN

    CALL RT_Mat_Brg_MakeCtx(rt_table, 1_i4, rt_ctx, status)
    IF (.NOT. expect_ok(status, "l5 plastic make ctx", n_failed)) RETURN

    IF (rt_ctx%mat_type == PH_MAT_ELASTO_PLASTIC .AND. &
        rt_ctx%mat_id == 1_i4 .AND. rt_ctx%mat_pt_idx == 1_i4 .AND. &
        rt_ctx%route_status == RT_MAT_ROUTE_OK) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: plastic material l5 route contract"
    END IF
  END SUBROUTINE test_plastic_material_populate_route

  SUBROUTINE test_material_family_governance_matrix(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (AC_N_MAT_FAM == 11_i4 .AND. &
        MD_Ana_Comp_CheckGroupMat(AC_GROUP_STRUCTURAL, 1_i4) .AND. &
        MD_Ana_Comp_CheckGroupMat(AC_GROUP_THERMAL, 9_i4) .AND. &
        MD_Ana_Comp_CheckGroupMat(AC_GROUP_ACOUSTIC, 10_i4) .AND. &
        MD_Ana_Comp_CheckGroupMat(AC_GROUP_EM, 11_i4)) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: material 11-family governance matrix"
    END IF
  END SUBROUTINE test_material_family_governance_matrix

  SUBROUTINE test_l4_material_governance_contract(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (PH_MAT_ELASTIC == 1_i4 .AND. &
        PH_MAT_ELASTO_PLASTIC == 2_i4 .AND. &
        PH_MAT_HYPERELASTIC == 3_i4 .AND. &
        PH_MAT_VISCOELASTIC == 4_i4 .AND. &
        PH_MAT_CREEP == 5_i4 .AND. &
        PH_MAT_DAMAGE == 6_i4 .AND. &
        PH_MAT_USER == 99_i4 .AND. PH_MAT_USER_UMAT == PH_MAT_USER) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l4 material governance enum contract"
    END IF
  END SUBROUTINE test_l4_material_governance_contract

  SUBROUTINE test_l4_l3_material_mapping_contract(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_PL) == PH_MAT_ELASTO_PLASTIC .AND. &
        PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_DA) == PH_MAT_DAMAGE .AND. &
        PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_HY) == PH_MAT_HYPERELASTIC .AND. &
        PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_VI) == PH_MAT_VISCOELASTIC .AND. &
        PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_CR) == PH_MAT_CREEP .AND. &
        PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_CO) == PH_MAT_COMPOSITE .AND. &
        PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_GEOMAT) == PH_MAT_GEOTECH .AND. &
        PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_COMPOSITE) == PH_MAT_COMPOSITE .AND. &
        PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_MULTIPHYS) == PH_MAT_THERMAL .AND. &
        PH_MapL3ClassToDefaultMatId(MD_MAT_CATEGORY_PL) == MAT_ID_PLASTIC_DEFAULT .AND. &
        PH_MapL3ClassToDefaultMatId(MD_MAT_CATEGORY_GEOMAT) == MAT_ID_GEOTECH_DEFAULT .AND. &
        PH_MapL3ClassToDefaultMatId(MD_MAT_CATEGORY_COMPOSITE) == MAT_ID_COMPOSITE_DEFAULT .AND. &
        PH_MapL3ClassToDefaultMatId(MD_MAT_CATEGORY_MULTIPHYS) == MAT_ID_THERMAL_DEFAULT .AND. &
        PH_MapL3MatTypeToL4(MD_MAT_CATEGORY_US) == PH_MAT_USER) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: l3/l4 material mapping contract"
    END IF
  END SUBROUTINE test_l4_l3_material_mapping_contract

  SUBROUTINE test_cpe3_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(6_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPE3_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cpe3 routed material helper", n_failed)) RETURN

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == 6_i4 .AND. &
        mat_slot%desc%cfg%matId == 6_i4 .AND. &
        D_tangent(1,1) > 0.0_wp .AND. &
        D_tangent(3,3) > 0.0_wp .AND. &
        stress_new(1) > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: cpe3 routed material helper contract"
    END IF
  END SUBROUTINE test_cpe3_material_routed_helper

  SUBROUTINE test_cpe4_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    rt_ctx%mat_type = PH_MAT_ELASTIC
    rt_ctx%mat_id = 3_i4
    rt_ctx%mat_pt_idx = 3_i4
    rt_ctx%is_user_sub = .FALSE.

    mat_slot%active = .TRUE.
    mat_slot%desc%cfg%matId = 3_i4
    mat_slot%desc%cfg%matModel = PH_MAT_ELASTIC
    ALLOCATE(mat_slot%desc%props(2))
    mat_slot%desc%props(1) = 210.0E9_wp
    mat_slot%desc%props(2) = 0.30_wp

    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPE4_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cpe4 routed material helper", n_failed)) RETURN

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == 3_i4 .AND. &
        mat_slot%desc%cfg%matId == 3_i4 .AND. &
        D_tangent(1,1) > 0.0_wp .AND. &
        D_tangent(3,3) > 0.0_wp .AND. &
        stress_new(1) > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: cpe4 routed material helper contract"
    END IF
  END SUBROUTINE test_cpe4_material_routed_helper

  SUBROUTINE test_cpe6_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(11_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPE6_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cpe6 routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cpe6", rt_ctx, mat_slot, D_tangent, stress_new, 11_i4, n_passed, n_failed)
  END SUBROUTINE test_cpe6_material_routed_helper

  SUBROUTINE test_cpe8_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(12_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPE8_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cpe8 routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cpe8", rt_ctx, mat_slot, D_tangent, stress_new, 12_i4, n_passed, n_failed)
  END SUBROUTINE test_cpe8_material_routed_helper

  SUBROUTINE test_cps3_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(7_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPS3_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cps3 routed material helper", n_failed)) RETURN

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == 7_i4 .AND. &
        mat_slot%desc%cfg%matId == 7_i4 .AND. &
        D_tangent(1,1) > 0.0_wp .AND. &
        D_tangent(3,3) > 0.0_wp .AND. &
        stress_new(1) > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: cps3 routed material helper contract"
    END IF
  END SUBROUTINE test_cps3_material_routed_helper

  SUBROUTINE test_cps4_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    rt_ctx%mat_type = PH_MAT_ELASTIC
    rt_ctx%mat_id = 4_i4
    rt_ctx%mat_pt_idx = 4_i4
    rt_ctx%is_user_sub = .FALSE.

    mat_slot%active = .TRUE.
    mat_slot%desc%cfg%matId = 4_i4
    mat_slot%desc%cfg%matModel = PH_MAT_ELASTIC
    ALLOCATE(mat_slot%desc%props(2))
    mat_slot%desc%props(1) = 210.0E9_wp
    mat_slot%desc%props(2) = 0.30_wp

    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPS4_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cps4 routed material helper", n_failed)) RETURN

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == 4_i4 .AND. &
        mat_slot%desc%cfg%matId == 4_i4 .AND. &
        D_tangent(1,1) > 0.0_wp .AND. &
        D_tangent(3,3) > 0.0_wp .AND. &
        stress_new(1) > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: cps4 routed material helper contract"
    END IF
  END SUBROUTINE test_cps4_material_routed_helper

  SUBROUTINE test_cps6_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(13_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPS6_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cps6 routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cps6", rt_ctx, mat_slot, D_tangent, stress_new, 13_i4, n_passed, n_failed)
  END SUBROUTINE test_cps6_material_routed_helper

  SUBROUTINE test_cps8_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(14_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPS8_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cps8 routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cps8", rt_ctx, mat_slot, D_tangent, stress_new, 14_i4, n_passed, n_failed)
  END SUBROUTINE test_cps8_material_routed_helper

  SUBROUTINE test_cax3_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(4)
    REAL(wp) :: stress_old(4)
    REAL(wp) :: stress_new(4)
    REAL(wp) :: D_tangent(4, 4)

    CALL init_elastic_route_fixture(18_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    dstrain(3) = 0.5E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CAX3_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cax3 routed material helper", n_failed)) RETURN
    CALL expect_axisym_routed("cax3", rt_ctx, mat_slot, D_tangent, stress_new, 18_i4, n_passed, n_failed)
  END SUBROUTINE test_cax3_material_routed_helper

  SUBROUTINE test_cax4_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(4)
    REAL(wp) :: stress_old(4)
    REAL(wp) :: stress_new(4)
    REAL(wp) :: D_tangent(4, 4)

    CALL init_elastic_route_fixture(19_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    dstrain(3) = 0.5E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CAX4_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cax4 routed material helper", n_failed)) RETURN
    CALL expect_axisym_routed("cax4", rt_ctx, mat_slot, D_tangent, stress_new, 19_i4, n_passed, n_failed)
  END SUBROUTINE test_cax4_material_routed_helper

  SUBROUTINE test_cax6_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(4)
    REAL(wp) :: stress_old(4)
    REAL(wp) :: stress_new(4)
    REAL(wp) :: D_tangent(4, 4)

    CALL init_elastic_route_fixture(20_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    dstrain(3) = 0.5E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CAX6_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cax6 routed material helper", n_failed)) RETURN
    CALL expect_axisym_routed("cax6", rt_ctx, mat_slot, D_tangent, stress_new, 20_i4, n_passed, n_failed)
  END SUBROUTINE test_cax6_material_routed_helper

  SUBROUTINE test_cax8_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(4)
    REAL(wp) :: stress_old(4)
    REAL(wp) :: stress_new(4)
    REAL(wp) :: D_tangent(4, 4)

    CALL init_elastic_route_fixture(21_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    dstrain(3) = 0.5E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CAX8_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "cax8 routed material helper", n_failed)) RETURN
    CALL expect_axisym_routed("cax8", rt_ctx, mat_slot, D_tangent, stress_new, 21_i4, n_passed, n_failed)
  END SUBROUTINE test_cax8_material_routed_helper

  SUBROUTINE test_c3d4_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(8_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D4_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d4 routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d4", rt_ctx, mat_slot, D_tangent, stress_new, 8_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d4_material_routed_helper

  SUBROUTINE test_c3d5_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(15_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D5_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d5 routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d5", rt_ctx, mat_slot, D_tangent, stress_new, 15_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d5_material_routed_helper

  SUBROUTINE test_c3d6_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(9_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D6_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d6 routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d6", rt_ctx, mat_slot, D_tangent, stress_new, 9_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d6_material_routed_helper

  SUBROUTINE test_c3d8_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    rt_ctx%mat_type = PH_MAT_ELASTIC
    rt_ctx%mat_id = 5_i4
    rt_ctx%mat_pt_idx = 5_i4
    rt_ctx%is_user_sub = .FALSE.

    mat_slot%active = .TRUE.
    mat_slot%desc%cfg%matId = 5_i4
    mat_slot%desc%cfg%matModel = PH_MAT_ELASTIC
    ALLOCATE(mat_slot%desc%props(2))
    mat_slot%desc%props(1) = 210.0E9_wp
    mat_slot%desc%props(2) = 0.30_wp

    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D8_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d8 routed material helper", n_failed)) RETURN

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == 5_i4 .AND. &
        mat_slot%desc%cfg%matId == 5_i4 .AND. &
        D_tangent(1,1) > 0.0_wp .AND. &
        D_tangent(4,4) > 0.0_wp .AND. &
        stress_new(1) > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A)') "  FAIL: c3d8 routed material helper contract"
    END IF
  END SUBROUTINE test_c3d8_material_routed_helper

  SUBROUTINE test_c3d8_eas_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(22_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D8_EAS_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                                 stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d8 eas routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d8 eas", rt_ctx, mat_slot, D_tangent, stress_new, 22_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d8_eas_material_routed_helper

  SUBROUTINE test_c3d8_fbar_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(23_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D8_FBar_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                                  stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d8 fbar routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d8 fbar", rt_ctx, mat_slot, D_tangent, stress_new, 23_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d8_fbar_material_routed_helper

  SUBROUTINE test_c3d10_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(10_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D10_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                              stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d10 routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d10", rt_ctx, mat_slot, D_tangent, stress_new, 10_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d10_material_routed_helper

  SUBROUTINE test_c3d13_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(16_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D13_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                              stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d13 routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d13", rt_ctx, mat_slot, D_tangent, stress_new, 16_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d13_material_routed_helper

  SUBROUTINE test_c3d15_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(17_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D15_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                              stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d15 routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d15", rt_ctx, mat_slot, D_tangent, stress_new, 17_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d15_material_routed_helper

  SUBROUTINE test_c3d20_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(24_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D20_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                              stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d20 routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d20", rt_ctx, mat_slot, D_tangent, stress_new, 24_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d20_material_routed_helper

  SUBROUTINE test_c3d27_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(25_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D27_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                              stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d27 routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d27", rt_ctx, mat_slot, D_tangent, stress_new, 25_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d27_material_routed_helper

  SUBROUTINE test_thermo_plane_strain_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3)
    REAL(wp) :: thermal_strain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(26_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_MatRoute_ThermoElasticPlaneStrain(rt_ctx, mat_slot, dstrain_total, &
                                                   thermal_strain, stress_old, stress_new, &
                                                   D_tangent, status)
    IF (.NOT. expect_ok(status, "thermo plane strain route helper", n_failed)) RETURN
    CALL expect_2d_routed("thermo plane strain", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 26_i4, n_passed, n_failed)
  END SUBROUTINE test_thermo_plane_strain_route_helper

  SUBROUTINE test_thermo_plane_stress_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3)
    REAL(wp) :: thermal_strain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(27_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_MatRoute_ThermoElasticPlaneStress(rt_ctx, mat_slot, dstrain_total, &
                                                   thermal_strain, stress_old, stress_new, &
                                                   D_tangent, status)
    IF (.NOT. expect_ok(status, "thermo plane stress route helper", n_failed)) RETURN
    CALL expect_2d_routed("thermo plane stress", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 27_i4, n_passed, n_failed)
  END SUBROUTINE test_thermo_plane_stress_route_helper

  SUBROUTINE test_thermo_axisym_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(4)
    REAL(wp) :: thermal_strain(4)
    REAL(wp) :: stress_old(4)
    REAL(wp) :: stress_new(4)
    REAL(wp) :: D_tangent(4, 4)

    CALL init_elastic_route_fixture(28_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    dstrain_total(3) = 1.5E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    thermal_strain(3) = 0.5E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_MatRoute_ThermoElasticAxisymmetric(rt_ctx, mat_slot, dstrain_total, &
                                                    thermal_strain, stress_old, stress_new, &
                                                    D_tangent, status)
    IF (.NOT. expect_ok(status, "thermo axisymmetric route helper", n_failed)) RETURN
    CALL expect_axisym_routed("thermo axisymmetric", rt_ctx, mat_slot, D_tangent, &
                              stress_new, 28_i4, n_passed, n_failed)
  END SUBROUTINE test_thermo_axisym_route_helper

  SUBROUTINE test_thermo_3d_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(6)
    REAL(wp) :: thermal_strain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(29_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_MatRoute_ThermoElastic3D(rt_ctx, mat_slot, dstrain_total, &
                                          thermal_strain, stress_old, stress_new, &
                                          D_tangent, status)
    IF (.NOT. expect_ok(status, "thermo 3d route helper", n_failed)) RETURN
    CALL expect_3d_routed("thermo 3d", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 29_i4, n_passed, n_failed)
  END SUBROUTINE test_thermo_3d_route_helper

  SUBROUTINE test_cpe4t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3)
    REAL(wp) :: thermal_strain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(30_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPE4T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cpe4t thermo routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cpe4t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 30_i4, n_passed, n_failed)
  END SUBROUTINE test_cpe4t_material_thermo_routed_helper

  SUBROUTINE test_cps4t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3)
    REAL(wp) :: thermal_strain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(31_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPS4T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cps4t thermo routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cps4t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 31_i4, n_passed, n_failed)
  END SUBROUTINE test_cps4t_material_thermo_routed_helper

  SUBROUTINE test_cax4t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(4)
    REAL(wp) :: thermal_strain(4)
    REAL(wp) :: stress_old(4)
    REAL(wp) :: stress_new(4)
    REAL(wp) :: D_tangent(4, 4)

    CALL init_elastic_route_fixture(32_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    dstrain_total(3) = 1.5E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    thermal_strain(3) = 0.5E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CAX4T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cax4t thermo routed material helper", n_failed)) RETURN
    CALL expect_axisym_routed("cax4t thermo", rt_ctx, mat_slot, D_tangent, &
                              stress_new, 32_i4, n_passed, n_failed)
  END SUBROUTINE test_cax4t_material_thermo_routed_helper

  SUBROUTINE test_c3d8t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(6)
    REAL(wp) :: thermal_strain(6)
    REAL(wp) :: stress_old(6)
    REAL(wp) :: stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(33_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D8T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d8t thermo routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d8t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 33_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d8t_material_thermo_routed_helper

  SUBROUTINE test_cpe3t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3), thermal_strain(3), stress_old(3), stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(34_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPE3T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cpe3t thermo routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cpe3t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 34_i4, n_passed, n_failed)
  END SUBROUTINE test_cpe3t_material_thermo_routed_helper

  SUBROUTINE test_cpe6t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3), thermal_strain(3), stress_old(3), stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(35_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPE6T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cpe6t thermo routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cpe6t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 35_i4, n_passed, n_failed)
  END SUBROUTINE test_cpe6t_material_thermo_routed_helper

  SUBROUTINE test_cpe8t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3), thermal_strain(3), stress_old(3), stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(36_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPE8T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cpe8t thermo routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cpe8t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 36_i4, n_passed, n_failed)
  END SUBROUTINE test_cpe8t_material_thermo_routed_helper

  SUBROUTINE test_cps3t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3), thermal_strain(3), stress_old(3), stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(37_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPS3T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cps3t thermo routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cps3t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 37_i4, n_passed, n_failed)
  END SUBROUTINE test_cps3t_material_thermo_routed_helper

  SUBROUTINE test_cps6t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3), thermal_strain(3), stress_old(3), stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(38_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPS6T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cps6t thermo routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cps6t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 38_i4, n_passed, n_failed)
  END SUBROUTINE test_cps6t_material_thermo_routed_helper

  SUBROUTINE test_cps8t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(3), thermal_strain(3), stress_old(3), stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(39_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CPS8T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cps8t thermo routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("cps8t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 39_i4, n_passed, n_failed)
  END SUBROUTINE test_cps8t_material_thermo_routed_helper

  SUBROUTINE test_cax3t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(4), thermal_strain(4), stress_old(4), stress_new(4)
    REAL(wp) :: D_tangent(4, 4)

    CALL init_elastic_route_fixture(40_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    dstrain_total(3) = 1.5E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    thermal_strain(3) = 0.5E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CAX3T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cax3t thermo routed material helper", n_failed)) RETURN
    CALL expect_axisym_routed("cax3t thermo", rt_ctx, mat_slot, D_tangent, &
                              stress_new, 40_i4, n_passed, n_failed)
  END SUBROUTINE test_cax3t_material_thermo_routed_helper

  SUBROUTINE test_cax6t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(4), thermal_strain(4), stress_old(4), stress_new(4)
    REAL(wp) :: D_tangent(4, 4)

    CALL init_elastic_route_fixture(41_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    dstrain_total(3) = 1.5E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    thermal_strain(3) = 0.5E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CAX6T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cax6t thermo routed material helper", n_failed)) RETURN
    CALL expect_axisym_routed("cax6t thermo", rt_ctx, mat_slot, D_tangent, &
                              stress_new, 41_i4, n_passed, n_failed)
  END SUBROUTINE test_cax6t_material_thermo_routed_helper

  SUBROUTINE test_cax8t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(4), thermal_strain(4), stress_old(4), stress_new(4)
    REAL(wp) :: D_tangent(4, 4)

    CALL init_elastic_route_fixture(42_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    dstrain_total(3) = 1.5E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    thermal_strain(3) = 0.5E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_CAX8T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "cax8t thermo routed material helper", n_failed)) RETURN
    CALL expect_axisym_routed("cax8t thermo", rt_ctx, mat_slot, D_tangent, &
                              stress_new, 42_i4, n_passed, n_failed)
  END SUBROUTINE test_cax8t_material_thermo_routed_helper

  SUBROUTINE test_c3d4t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(6), thermal_strain(6), stress_old(6), stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(43_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D4T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d4t thermo routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d4t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 43_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d4t_material_thermo_routed_helper

  SUBROUTINE test_c3d6t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(6), thermal_strain(6), stress_old(6), stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(44_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D6T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                     thermal_strain, stress_old, stress_new, &
                                                     D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d6t thermo routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d6t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 44_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d6t_material_thermo_routed_helper

  SUBROUTINE test_c3d10t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(6), thermal_strain(6), stress_old(6), stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(45_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D10T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                      thermal_strain, stress_old, stress_new, &
                                                      D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d10t thermo routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d10t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 45_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d10t_material_thermo_routed_helper

  SUBROUTINE test_c3d15t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(6), thermal_strain(6), stress_old(6), stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(46_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D15T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                      thermal_strain, stress_old, stress_new, &
                                                      D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d15t thermo routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d15t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 46_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d15t_material_thermo_routed_helper

  SUBROUTINE test_c3d20t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(6), thermal_strain(6), stress_old(6), stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(47_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D20T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                      thermal_strain, stress_old, stress_new, &
                                                      D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d20t thermo routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d20t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 47_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d20t_material_thermo_routed_helper

  SUBROUTINE test_c3d27t_material_thermo_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain_total(6), thermal_strain(6), stress_old(6), stress_new(6)
    REAL(wp) :: D_tangent(6, 6)

    CALL init_elastic_route_fixture(48_i4, rt_ctx, mat_slot)
    dstrain_total = 0.0_wp
    thermal_strain = 0.0_wp
    dstrain_total(1) = 2.0E-6_wp
    thermal_strain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_C3D27T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, dstrain_total, &
                                                      thermal_strain, stress_old, stress_new, &
                                                      D_tangent, status)
    IF (.NOT. expect_ok(status, "c3d27t thermo routed material helper", n_failed)) RETURN
    CALL expect_3d_routed("c3d27t thermo", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 48_i4, n_passed, n_failed)
  END SUBROUTINE test_c3d27t_material_thermo_routed_helper

  SUBROUTINE test_uniaxial_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain
    REAL(wp) :: stress_old
    REAL(wp) :: stress_new
    REAL(wp) :: D_tangent

    CALL init_elastic_route_fixture(49_i4, rt_ctx, mat_slot)
    dstrain = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_MatRoute_ElasticUniaxial(rt_ctx, mat_slot, dstrain, &
                                          stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "uniaxial route helper", n_failed)) RETURN
    CALL expect_1d_routed("uniaxial", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 49_i4, n_passed, n_failed)
  END SUBROUTINE test_uniaxial_route_helper

  SUBROUTINE test_dashpot_scalar_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: rel_velocity
    REAL(wp) :: force_new
    REAL(wp) :: C_tangent

    CALL init_scalar_route_fixture(63_i4, 12.5_wp, rt_ctx, mat_slot)
    rel_velocity = 2.0_wp

    CALL PH_Elem_MatRoute_DashpotScalar(rt_ctx, mat_slot, rel_velocity, &
                                        force_new, C_tangent, status)
    IF (.NOT. expect_ok(status, "dashpot scalar route helper", n_failed)) RETURN
    CALL expect_scalar_damping_routed("dashpot scalar", rt_ctx, mat_slot, &
                                      C_tangent, force_new, 25.0_wp, 63_i4, &
                                      n_passed, n_failed)
  END SUBROUTINE test_dashpot_scalar_route_helper

  SUBROUTINE test_thermal_conductivity_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: temp_gradient
    REAL(wp) :: heat_flux
    REAL(wp) :: K_tangent

    CALL init_scalar_route_fixture(66_i4, 20.0_wp, rt_ctx, mat_slot)
    temp_gradient = 2.0_wp

    CALL PH_Elem_MatRoute_ThermalConductivityScalar(rt_ctx, mat_slot, temp_gradient, &
                                                    heat_flux, K_tangent, status)
    IF (.NOT. expect_ok(status, "thermal conductivity route helper", n_failed)) RETURN
    CALL expect_scalar_thermal_routed("thermal conductivity", rt_ctx, mat_slot, &
                                      K_tangent, heat_flux, -40.0_wp, 66_i4, &
                                      n_passed, n_failed)
  END SUBROUTINE test_thermal_conductivity_route_helper

  SUBROUTINE test_mass_scalar_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: mass_total
    REAL(wp) :: mass_per_node

    CALL init_scalar_route_fixture(71_i4, 12.0_wp, rt_ctx, mat_slot)

    CALL PH_Elem_MatRoute_MassScalar(rt_ctx, mat_slot, 3_i4, &
                                     mass_total, mass_per_node, status)
    IF (.NOT. expect_ok(status, "mass scalar route helper", n_failed)) RETURN
    CALL expect_scalar_mass_routed("mass scalar", rt_ctx, mat_slot, mass_total, &
                                   mass_per_node, 12.0_wp, 4.0_wp, 71_i4, &
                                   n_passed, n_failed)
  END SUBROUTINE test_mass_scalar_route_helper

  SUBROUTINE test_beam_elastic_constants_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: E_young
    REAL(wp) :: nu

    CALL init_elastic_route_fixture(73_i4, rt_ctx, mat_slot)

    CALL PH_Elem_MatRoute_BeamElasticConstants(rt_ctx, mat_slot, E_young, nu, status)
    IF (.NOT. expect_ok(status, "beam elastic constants route helper", n_failed)) RETURN
    CALL expect_beam_constants_routed("beam constants", rt_ctx, mat_slot, E_young, &
                                      nu, 73_i4, n_passed, n_failed)
  END SUBROUTINE test_beam_elastic_constants_route_helper

  SUBROUTINE test_acoustic_fluid_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: density
    REAL(wp) :: bulk_modulus
    REAL(wp) :: sound_speed

    CALL init_scalar_props_route_fixture(74_i4, (/1.25_wp, 156250.0_wp/), rt_ctx, mat_slot)

    CALL PH_Elem_MatRoute_AcousticFluid(rt_ctx, mat_slot, density, bulk_modulus, &
                                        sound_speed, status)
    IF (.NOT. expect_ok(status, "acoustic fluid route helper", n_failed)) RETURN
    CALL expect_acoustic_routed("acoustic fluid", rt_ctx, mat_slot, density, &
                                bulk_modulus, sound_speed, 74_i4, n_passed, n_failed)
  END SUBROUTINE test_acoustic_fluid_route_helper

  SUBROUTINE test_cohesive_linear_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: K_n, K_s, t_n_max, t_s_max, G_Ic, G_IIc

    CALL init_scalar_props_route_fixture(75_i4, (/10.0_wp, 5.0_wp, 3.0_wp, &
                                                2.0_wp, 0.8_wp, 0.6_wp/), &
                                        rt_ctx, mat_slot)

    CALL PH_Elem_MatRoute_CohesiveLinear(rt_ctx, mat_slot, K_n, K_s, &
                                         t_n_max, t_s_max, G_Ic, G_IIc, status)
    IF (.NOT. expect_ok(status, "cohesive linear route helper", n_failed)) RETURN
    CALL expect_cohesive_routed("cohesive linear", rt_ctx, mat_slot, K_n, K_s, &
                                t_n_max, G_Ic, 75_i4, n_passed, n_failed)
  END SUBROUTINE test_cohesive_linear_route_helper

  SUBROUTINE test_gasket_linear_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: K_g
    REAL(wp) :: h_0
    REAL(wp) :: p_max

    CALL init_scalar_props_route_fixture(76_i4, (/9.0_wp, 0.25_wp, 4.0_wp/), &
                                        rt_ctx, mat_slot)

    CALL PH_Elem_MatRoute_GasketLinear(rt_ctx, mat_slot, K_g, h_0, p_max, status)
    IF (.NOT. expect_ok(status, "gasket linear route helper", n_failed)) RETURN
    CALL expect_gasket_routed("gasket linear", rt_ctx, mat_slot, K_g, h_0, &
                              p_max, 76_i4, n_passed, n_failed)
  END SUBROUTINE test_gasket_linear_route_helper

  SUBROUTINE test_infinite_decay_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: decay_rate
    INTEGER(i4) :: decay_type
    REAL(wp) :: decay_power
    REAL(wp) :: reference_dista

    CALL init_scalar_props_route_fixture(77_i4, (/0.75_wp, 2.0_wp, 1.5_wp, 10.0_wp/), &
                                        rt_ctx, mat_slot)

    CALL PH_Elem_MatRoute_InfiniteDecay(rt_ctx, mat_slot, decay_rate, decay_type, &
                                        decay_power, reference_dista, status)
    IF (.NOT. expect_ok(status, "infinite decay route helper", n_failed)) RETURN
    CALL expect_infinite_decay_routed("infinite decay", rt_ctx, mat_slot, decay_rate, &
                                      decay_type, decay_power, reference_dista, &
                                      77_i4, n_passed, n_failed)
  END SUBROUTINE test_infinite_decay_route_helper

  SUBROUTINE test_porous_twophase_route_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: model_flag, alpha_vg, n_vg, phi
    REAL(wp) :: Swr, Snr, n_corey, m_vg, l_mualem

    CALL init_scalar_props_route_fixture(85_i4, (/2.0_wp, 1.2_wp, 2.4_wp, &
                                                0.35_wp, 0.1_wp, 0.05_wp, &
                                                2.0_wp, 0.58_wp, 0.5_wp/), &
                                        rt_ctx, mat_slot)

    CALL PH_Elem_MatRoute_PorousTwoPhase(rt_ctx, mat_slot, model_flag, alpha_vg, &
                                         n_vg, phi, Swr, Snr, n_corey, m_vg, &
                                         l_mualem, status)
    IF (.NOT. expect_ok(status, "porous twophase route helper", n_failed)) RETURN
    CALL expect_porous_twophase_routed("porous twophase", rt_ctx, mat_slot, model_flag, &
                                       alpha_vg, n_vg, phi, 85_i4, n_passed, n_failed)
  END SUBROUTINE test_porous_twophase_route_helper

  SUBROUTINE test_t2d2_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain
    REAL(wp) :: stress_old
    REAL(wp) :: stress_new
    REAL(wp) :: D_tangent

    CALL init_elastic_route_fixture(50_i4, rt_ctx, mat_slot)
    dstrain = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_T2D2_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "t2d2 routed material helper", n_failed)) RETURN
    CALL expect_1d_routed("t2d2", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 50_i4, n_passed, n_failed)
  END SUBROUTINE test_t2d2_material_routed_helper

  SUBROUTINE test_t3d2_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain
    REAL(wp) :: stress_old
    REAL(wp) :: stress_new
    REAL(wp) :: D_tangent

    CALL init_elastic_route_fixture(51_i4, rt_ctx, mat_slot)
    dstrain = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_T3D2_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "t3d2 routed material helper", n_failed)) RETURN
    CALL expect_1d_routed("t3d2", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 51_i4, n_passed, n_failed)
  END SUBROUTINE test_t3d2_material_routed_helper

  SUBROUTINE test_t3d3_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain
    REAL(wp) :: stress_old
    REAL(wp) :: stress_new
    REAL(wp) :: D_tangent

    CALL init_elastic_route_fixture(52_i4, rt_ctx, mat_slot)
    dstrain = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_T3D3_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "t3d3 routed material helper", n_failed)) RETURN
    CALL expect_1d_routed("t3d3", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 52_i4, n_passed, n_failed)
  END SUBROUTINE test_t3d3_material_routed_helper

  SUBROUTINE test_spring1_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain
    REAL(wp) :: stress_old
    REAL(wp) :: stress_new
    REAL(wp) :: D_tangent

    CALL init_elastic_route_fixture(57_i4, rt_ctx, mat_slot)
    dstrain = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_SPRING1_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                                stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "spring1 routed material helper", n_failed)) RETURN
    CALL expect_1d_routed("spring1", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 57_i4, n_passed, n_failed)
  END SUBROUTINE test_spring1_material_routed_helper

  SUBROUTINE test_spring2_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain
    REAL(wp) :: stress_old
    REAL(wp) :: stress_new
    REAL(wp) :: D_tangent

    CALL init_elastic_route_fixture(58_i4, rt_ctx, mat_slot)
    dstrain = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_SPRING2_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                                stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "spring2 routed material helper", n_failed)) RETURN
    CALL expect_1d_routed("spring2", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 58_i4, n_passed, n_failed)
  END SUBROUTINE test_spring2_material_routed_helper

  SUBROUTINE test_pipe21_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain
    REAL(wp) :: stress_old
    REAL(wp) :: stress_new
    REAL(wp) :: D_tangent

    CALL init_elastic_route_fixture(59_i4, rt_ctx, mat_slot)
    dstrain = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_PIPE21_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                               stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "pipe21 routed material helper", n_failed)) RETURN
    CALL expect_1d_routed("pipe21", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 59_i4, n_passed, n_failed)
  END SUBROUTINE test_pipe21_material_routed_helper

  SUBROUTINE test_pipe22_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain
    REAL(wp) :: stress_old
    REAL(wp) :: stress_new
    REAL(wp) :: D_tangent

    CALL init_elastic_route_fixture(60_i4, rt_ctx, mat_slot)
    dstrain = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_PIPE22_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                               stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "pipe22 routed material helper", n_failed)) RETURN
    CALL expect_1d_routed("pipe22", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 60_i4, n_passed, n_failed)
  END SUBROUTINE test_pipe22_material_routed_helper

  SUBROUTINE test_dashpot1_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: rel_velocity
    REAL(wp) :: force_new
    REAL(wp) :: C_tangent

    CALL init_scalar_route_fixture(64_i4, 9.0_wp, rt_ctx, mat_slot)
    rel_velocity = 3.0_wp

    CALL PH_Elem_DASHPOT1_Material_Update_Routed(rt_ctx, mat_slot, rel_velocity, &
                                                 force_new, C_tangent, status)
    IF (.NOT. expect_ok(status, "dashpot1 routed material helper", n_failed)) RETURN
    CALL expect_scalar_damping_routed("dashpot1", rt_ctx, mat_slot, C_tangent, &
                                      force_new, 27.0_wp, 64_i4, n_passed, n_failed)
  END SUBROUTINE test_dashpot1_material_routed_helper

  SUBROUTINE test_dashpot2_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: rel_velocity
    REAL(wp) :: force_new
    REAL(wp) :: C_tangent

    CALL init_scalar_route_fixture(65_i4, 7.0_wp, rt_ctx, mat_slot)
    rel_velocity = 4.0_wp

    CALL PH_Elem_DASHPOT2_Material_Update_Routed(rt_ctx, mat_slot, rel_velocity, &
                                                 force_new, C_tangent, status)
    IF (.NOT. expect_ok(status, "dashpot2 routed material helper", n_failed)) RETURN
    CALL expect_scalar_damping_routed("dashpot2", rt_ctx, mat_slot, C_tangent, &
                                      force_new, 28.0_wp, 65_i4, n_passed, n_failed)
  END SUBROUTINE test_dashpot2_material_routed_helper

  SUBROUTINE test_mass_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: mass_total
    REAL(wp) :: mass_per_node

    CALL init_scalar_route_fixture(72_i4, 8.0_wp, rt_ctx, mat_slot)

    CALL PH_Elem_Mass_Material_Update_Routed(rt_ctx, mat_slot, 2_i4, &
                                             mass_total, mass_per_node, status)
    IF (.NOT. expect_ok(status, "mass routed material helper", n_failed)) RETURN
    CALL expect_scalar_mass_routed("mass", rt_ctx, mat_slot, mass_total, &
                                   mass_per_node, 8.0_wp, 4.0_wp, 72_i4, &
                                   n_passed, n_failed)
  END SUBROUTINE test_mass_material_routed_helper

  SUBROUTINE test_beam_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: E_young
    REAL(wp) :: nu

    CALL init_elastic_route_fixture(78_i4, rt_ctx, mat_slot)

    CALL PH_Elem_Beam_Material_Update_Routed(rt_ctx, mat_slot, E_young, nu, status)
    IF (.NOT. expect_ok(status, "beam routed material helper", n_failed)) RETURN
    CALL expect_beam_constants_routed("beam", rt_ctx, mat_slot, E_young, nu, &
                                      78_i4, n_passed, n_failed)
  END SUBROUTINE test_beam_material_routed_helper

  SUBROUTINE test_acoustic_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: density
    REAL(wp) :: bulk_modulus
    REAL(wp) :: sound_speed

    CALL init_scalar_props_route_fixture(79_i4, (/2.0_wp, 5000.0_wp/), rt_ctx, mat_slot)

    CALL PH_Elem_Acoustic_Material_Update_Routed(rt_ctx, mat_slot, density, &
                                                 bulk_modulus, sound_speed, status)
    IF (.NOT. expect_ok(status, "acoustic routed material helper", n_failed)) RETURN
    CALL expect_acoustic_routed("acoustic", rt_ctx, mat_slot, density, &
                                bulk_modulus, sound_speed, 79_i4, n_passed, n_failed)
  END SUBROUTINE test_acoustic_material_routed_helper

  SUBROUTINE test_cohesive_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: K_n, K_s, t_n_max, t_s_max, G_Ic, G_IIc

    CALL init_scalar_props_route_fixture(80_i4, (/12.0_wp, 6.0_wp, 4.0_wp, &
                                                3.0_wp, 1.0_wp, 0.9_wp/), &
                                        rt_ctx, mat_slot)

    CALL PH_Elem_Cohesive_Material_Update_Routed(rt_ctx, mat_slot, K_n, K_s, &
                                                 t_n_max, t_s_max, G_Ic, G_IIc, status)
    IF (.NOT. expect_ok(status, "cohesive routed material helper", n_failed)) RETURN
    CALL expect_cohesive_routed("cohesive", rt_ctx, mat_slot, K_n, K_s, &
                                t_n_max, G_Ic, 80_i4, n_passed, n_failed)
  END SUBROUTINE test_cohesive_material_routed_helper

  SUBROUTINE test_gasket_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: K_g
    REAL(wp) :: h_0
    REAL(wp) :: p_max

    CALL init_scalar_props_route_fixture(81_i4, (/11.0_wp, 0.5_wp, 5.0_wp/), &
                                        rt_ctx, mat_slot)

    CALL PH_Elem_Gasket_Material_Update_Routed(rt_ctx, mat_slot, K_g, h_0, p_max, status)
    IF (.NOT. expect_ok(status, "gasket routed material helper", n_failed)) RETURN
    CALL expect_gasket_routed("gasket", rt_ctx, mat_slot, K_g, h_0, p_max, &
                              81_i4, n_passed, n_failed)
  END SUBROUTINE test_gasket_material_routed_helper

  SUBROUTINE test_infinite_decay_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: decay_rate
    INTEGER(i4) :: decay_type
    REAL(wp) :: decay_power
    REAL(wp) :: reference_dista

    CALL init_scalar_props_route_fixture(82_i4, (/0.25_wp, 3.0_wp, 2.5_wp, 8.0_wp/), &
                                        rt_ctx, mat_slot)

    CALL PH_Elem_Infinite_Material_Update_Decay_Routed(rt_ctx, mat_slot, decay_rate, &
                                                       decay_type, decay_power, &
                                                       reference_dista, status)
    IF (.NOT. expect_ok(status, "infinite decay routed material helper", n_failed)) RETURN
    CALL expect_infinite_decay_routed("infinite", rt_ctx, mat_slot, decay_rate, &
                                      decay_type, decay_power, reference_dista, &
                                      82_i4, n_passed, n_failed)
  END SUBROUTINE test_infinite_decay_material_routed_helper

  SUBROUTINE test_porous_twophase_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: model_flag, alpha_vg, n_vg, phi
    REAL(wp) :: Swr, Snr, n_corey, m_vg, l_mualem

    CALL init_scalar_props_route_fixture(86_i4, (/1.0_wp, 0.9_wp, 2.2_wp, &
                                                0.4_wp, 0.08_wp, 0.04_wp, &
                                                2.5_wp, 0.55_wp, 0.45_wp/), &
                                        rt_ctx, mat_slot)

    CALL PH_Elem_Porous_Material_Update_TwoPhase_Routed(rt_ctx, mat_slot, model_flag, &
                                                        alpha_vg, n_vg, phi, Swr, Snr, &
                                                        n_corey, m_vg, l_mualem, status)
    IF (.NOT. expect_ok(status, "porous twophase routed material helper", n_failed)) RETURN
    CALL expect_porous_twophase_routed("porous", rt_ctx, mat_slot, model_flag, &
                                       alpha_vg, n_vg, phi, 86_i4, n_passed, n_failed)
  END SUBROUTINE test_porous_twophase_material_routed_helper

  SUBROUTINE test_m3d9r_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(53_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_M3D9R_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &
                                             stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "m3d9r routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("m3d9r membrane", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 53_i4, n_passed, n_failed)
  END SUBROUTINE test_m3d9r_material_routed_helper

  SUBROUTINE test_s3_membrane_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(59_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_S3_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                    stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "s3 cpe membrane routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("s3 cpe membrane", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 59_i4, n_passed, n_failed)
  END SUBROUTINE test_s3_membrane_material_routed_helper

  SUBROUTINE test_s4_membrane_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(54_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_S4_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                    stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "s4 membrane routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("s4 membrane", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 54_i4, n_passed, n_failed)
  END SUBROUTINE test_s4_membrane_material_routed_helper

  SUBROUTINE test_s4t_membrane_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(61_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_S4T_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                     stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "s4t membrane routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("s4t membrane", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 61_i4, n_passed, n_failed)
  END SUBROUTINE test_s4t_membrane_material_routed_helper

  SUBROUTINE test_s4t_thermal_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: temp_gradient
    REAL(wp) :: heat_flux
    REAL(wp) :: K_tangent

    CALL init_scalar_route_fixture(83_i4, 15.0_wp, rt_ctx, mat_slot)
    temp_gradient = 2.0_wp

    CALL PH_Elem_S4T_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
                                                    heat_flux, K_tangent, status)
    IF (.NOT. expect_ok(status, "s4t thermal routed material helper", n_failed)) RETURN
    CALL expect_scalar_thermal_routed("s4t thermal", rt_ctx, mat_slot, K_tangent, &
                                      heat_flux, -30.0_wp, 83_i4, n_passed, n_failed)
  END SUBROUTINE test_s4t_thermal_material_routed_helper

  SUBROUTINE test_s6_membrane_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(60_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_S6_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                    stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "s6 cpe membrane routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("s6 cpe membrane", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 60_i4, n_passed, n_failed)
  END SUBROUTINE test_s6_membrane_material_routed_helper

  SUBROUTINE test_s8_membrane_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(55_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_S8_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                    stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "s8 membrane routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("s8 membrane", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 55_i4, n_passed, n_failed)
  END SUBROUTINE test_s8_membrane_material_routed_helper

  SUBROUTINE test_s8rt_membrane_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(62_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_S8RT_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                      stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "s8rt membrane routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("s8rt membrane", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 62_i4, n_passed, n_failed)
  END SUBROUTINE test_s8rt_membrane_material_routed_helper

  SUBROUTINE test_s8rt_thermal_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: temp_gradient
    REAL(wp) :: heat_flux
    REAL(wp) :: K_tangent

    CALL init_scalar_route_fixture(84_i4, 16.0_wp, rt_ctx, mat_slot)
    temp_gradient = 2.5_wp

    CALL PH_Elem_S8RT_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
                                                     heat_flux, K_tangent, status)
    IF (.NOT. expect_ok(status, "s8rt thermal routed material helper", n_failed)) RETURN
    CALL expect_scalar_thermal_routed("s8rt thermal", rt_ctx, mat_slot, K_tangent, &
                                      heat_flux, -40.0_wp, 84_i4, n_passed, n_failed)
  END SUBROUTINE test_s8rt_thermal_material_routed_helper

  SUBROUTINE test_s9_membrane_material_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dstrain(3)
    REAL(wp) :: stress_old(3)
    REAL(wp) :: stress_new(3)
    REAL(wp) :: D_tangent(3, 3)

    CALL init_elastic_route_fixture(56_i4, rt_ctx, mat_slot)
    dstrain = 0.0_wp
    dstrain(1) = 1.0E-6_wp
    stress_old = 0.0_wp

    CALL PH_Elem_S9_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                    stress_old, stress_new, D_tangent, status)
    IF (.NOT. expect_ok(status, "s9 membrane routed material helper", n_failed)) RETURN
    CALL expect_2d_routed("s9 membrane", rt_ctx, mat_slot, D_tangent, &
                          stress_new, 56_i4, n_passed, n_failed)
  END SUBROUTINE test_s9_membrane_material_routed_helper

  SUBROUTINE test_ds3_material_thermal_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: temp_gradient
    REAL(wp) :: heat_flux
    REAL(wp) :: K_tangent

    CALL init_scalar_route_fixture(67_i4, 11.0_wp, rt_ctx, mat_slot)
    temp_gradient = 3.0_wp

    CALL PH_Elem_DS3_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
                                                    heat_flux, K_tangent, status)
    IF (.NOT. expect_ok(status, "ds3 thermal routed material helper", n_failed)) RETURN
    CALL expect_scalar_thermal_routed("ds3 thermal", rt_ctx, mat_slot, K_tangent, &
                                      heat_flux, -33.0_wp, 67_i4, n_passed, n_failed)
  END SUBROUTINE test_ds3_material_thermal_routed_helper

  SUBROUTINE test_ds4_material_thermal_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: temp_gradient
    REAL(wp) :: heat_flux
    REAL(wp) :: K_tangent

    CALL init_scalar_route_fixture(68_i4, 12.0_wp, rt_ctx, mat_slot)
    temp_gradient = 3.0_wp

    CALL PH_Elem_DS4_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
                                                    heat_flux, K_tangent, status)
    IF (.NOT. expect_ok(status, "ds4 thermal routed material helper", n_failed)) RETURN
    CALL expect_scalar_thermal_routed("ds4 thermal", rt_ctx, mat_slot, K_tangent, &
                                      heat_flux, -36.0_wp, 68_i4, n_passed, n_failed)
  END SUBROUTINE test_ds4_material_thermal_routed_helper

  SUBROUTINE test_ds6_material_thermal_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: temp_gradient
    REAL(wp) :: heat_flux
    REAL(wp) :: K_tangent

    CALL init_scalar_route_fixture(69_i4, 13.0_wp, rt_ctx, mat_slot)
    temp_gradient = 3.0_wp

    CALL PH_Elem_DS6_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
                                                    heat_flux, K_tangent, status)
    IF (.NOT. expect_ok(status, "ds6 thermal routed material helper", n_failed)) RETURN
    CALL expect_scalar_thermal_routed("ds6 thermal", rt_ctx, mat_slot, K_tangent, &
                                      heat_flux, -39.0_wp, 69_i4, n_passed, n_failed)
  END SUBROUTINE test_ds6_material_thermal_routed_helper

  SUBROUTINE test_ds8_material_thermal_routed_helper(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(PH_Mat_Slot) :: mat_slot
    TYPE(RT_Mat_Dispatch_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: temp_gradient
    REAL(wp) :: heat_flux
    REAL(wp) :: K_tangent

    CALL init_scalar_route_fixture(70_i4, 14.0_wp, rt_ctx, mat_slot)
    temp_gradient = 3.0_wp

    CALL PH_Elem_DS8_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
                                                    heat_flux, K_tangent, status)
    IF (.NOT. expect_ok(status, "ds8 thermal routed material helper", n_failed)) RETURN
    CALL expect_scalar_thermal_routed("ds8 thermal", rt_ctx, mat_slot, K_tangent, &
                                      heat_flux, -42.0_wp, 70_i4, n_passed, n_failed)
  END SUBROUTINE test_ds8_material_thermal_routed_helper

  SUBROUTINE init_elastic_route_fixture(mat_pt_idx, rt_ctx, mat_slot)
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(OUT) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(OUT) :: mat_slot

    rt_ctx%mat_type = PH_MAT_ELASTIC
    rt_ctx%mat_id = mat_pt_idx
    rt_ctx%mat_pt_idx = mat_pt_idx
    rt_ctx%is_user_sub = .FALSE.

    mat_slot%active = .TRUE.
    mat_slot%desc%cfg%matId = mat_pt_idx
    mat_slot%desc%cfg%matModel = PH_MAT_ELASTIC
    ALLOCATE(mat_slot%desc%props(2))
    mat_slot%desc%props(1) = 210.0E9_wp
    mat_slot%desc%props(2) = 0.30_wp
  END SUBROUTINE init_elastic_route_fixture

  SUBROUTINE init_scalar_route_fixture(mat_pt_idx, prop_value, rt_ctx, mat_slot)
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    REAL(wp), INTENT(IN) :: prop_value
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(OUT) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(OUT) :: mat_slot

    rt_ctx%mat_type = PH_MAT_ELASTIC
    rt_ctx%mat_id = mat_pt_idx
    rt_ctx%mat_pt_idx = mat_pt_idx
    rt_ctx%is_user_sub = .FALSE.

    mat_slot%active = .TRUE.
    mat_slot%desc%cfg%matId = mat_pt_idx
    mat_slot%desc%cfg%matModel = PH_MAT_ELASTIC
    ALLOCATE(mat_slot%desc%props(1))
    mat_slot%desc%props(1) = prop_value
  END SUBROUTINE init_scalar_route_fixture

  SUBROUTINE init_scalar_props_route_fixture(mat_pt_idx, prop_values, rt_ctx, mat_slot)
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    REAL(wp), INTENT(IN) :: prop_values(:)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(OUT) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(OUT) :: mat_slot

    rt_ctx%mat_type = PH_MAT_ELASTIC
    rt_ctx%mat_id = mat_pt_idx
    rt_ctx%mat_pt_idx = mat_pt_idx
    rt_ctx%is_user_sub = .FALSE.

    mat_slot%active = .TRUE.
    mat_slot%desc%cfg%matId = mat_pt_idx
    mat_slot%desc%cfg%matModel = PH_MAT_ELASTIC
    ALLOCATE(mat_slot%desc%props(SIZE(prop_values)))
    mat_slot%desc%props = prop_values
  END SUBROUTINE init_scalar_props_route_fixture

  SUBROUTINE expect_2d_routed(label, rt_ctx, mat_slot, D_tangent, stress_new, &
                              mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: D_tangent(3, 3)
    REAL(wp), INTENT(IN) :: stress_new(3)
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        D_tangent(1,1) > 0.0_wp .AND. &
        D_tangent(3,3) > 0.0_wp .AND. &
        stress_new(1) > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed material helper contract"
    END IF
  END SUBROUTINE expect_2d_routed

  SUBROUTINE expect_1d_routed(label, rt_ctx, mat_slot, D_tangent, stress_new, &
                             mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: D_tangent
    REAL(wp), INTENT(IN) :: stress_new
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        D_tangent > 0.0_wp .AND. &
        stress_new > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed material helper contract"
    END IF
  END SUBROUTINE expect_1d_routed

  SUBROUTINE expect_scalar_damping_routed(label, rt_ctx, mat_slot, C_tangent, force_new, &
                                          expected_force, mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: C_tangent
    REAL(wp), INTENT(IN) :: force_new
    REAL(wp), INTENT(IN) :: expected_force
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        C_tangent > 0.0_wp .AND. &
        ABS(force_new - expected_force) < 1.0E-9_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed damping helper contract"
    END IF
  END SUBROUTINE expect_scalar_damping_routed

  SUBROUTINE expect_scalar_thermal_routed(label, rt_ctx, mat_slot, K_tangent, heat_flux, &
                                          expected_flux, mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: K_tangent
    REAL(wp), INTENT(IN) :: heat_flux
    REAL(wp), INTENT(IN) :: expected_flux
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        K_tangent > 0.0_wp .AND. &
        ABS(heat_flux - expected_flux) < 1.0E-9_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed thermal helper contract"
    END IF
  END SUBROUTINE expect_scalar_thermal_routed

  SUBROUTINE expect_scalar_mass_routed(label, rt_ctx, mat_slot, mass_total, mass_per_node, &
                                       expected_total, expected_per_node, mat_pt_idx, &
                                       n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: mass_total
    REAL(wp), INTENT(IN) :: mass_per_node
    REAL(wp), INTENT(IN) :: expected_total
    REAL(wp), INTENT(IN) :: expected_per_node
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        ABS(mass_total - expected_total) < 1.0E-9_wp .AND. &
        ABS(mass_per_node - expected_per_node) < 1.0E-9_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed mass helper contract"
    END IF
  END SUBROUTINE expect_scalar_mass_routed

  SUBROUTINE expect_beam_constants_routed(label, rt_ctx, mat_slot, E_young, nu, &
                                          mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: E_young
    REAL(wp), INTENT(IN) :: nu
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        E_young > 0.0_wp .AND. ABS(nu - 0.30_wp) < 1.0E-12_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed beam helper contract"
    END IF
  END SUBROUTINE expect_beam_constants_routed

  SUBROUTINE expect_acoustic_routed(label, rt_ctx, mat_slot, density, bulk_modulus, &
                                    sound_speed, mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: density
    REAL(wp), INTENT(IN) :: bulk_modulus
    REAL(wp), INTENT(IN) :: sound_speed
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        density > 0.0_wp .AND. bulk_modulus > 0.0_wp .AND. &
        ABS(sound_speed - SQRT(bulk_modulus / density)) < 1.0E-9_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed acoustic helper contract"
    END IF
  END SUBROUTINE expect_acoustic_routed

  SUBROUTINE expect_cohesive_routed(label, rt_ctx, mat_slot, K_n, K_s, t_n_max, G_Ic, &
                                    mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: K_n
    REAL(wp), INTENT(IN) :: K_s
    REAL(wp), INTENT(IN) :: t_n_max
    REAL(wp), INTENT(IN) :: G_Ic
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        K_n > 0.0_wp .AND. K_s > 0.0_wp .AND. &
        t_n_max > 0.0_wp .AND. G_Ic > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed cohesive helper contract"
    END IF
  END SUBROUTINE expect_cohesive_routed

  SUBROUTINE expect_gasket_routed(label, rt_ctx, mat_slot, K_g, h_0, p_max, &
                                  mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: K_g
    REAL(wp), INTENT(IN) :: h_0
    REAL(wp), INTENT(IN) :: p_max
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        K_g > 0.0_wp .AND. h_0 > 0.0_wp .AND. p_max > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed gasket helper contract"
    END IF
  END SUBROUTINE expect_gasket_routed

  SUBROUTINE expect_infinite_decay_routed(label, rt_ctx, mat_slot, decay_rate, &
                                          decay_type, decay_power, reference_dista, &
                                          mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: decay_rate
    INTEGER(i4), INTENT(IN) :: decay_type
    REAL(wp), INTENT(IN) :: decay_power
    REAL(wp), INTENT(IN) :: reference_dista
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        decay_rate > 0.0_wp .AND. decay_type >= 1_i4 .AND. decay_type <= 3_i4 .AND. &
        decay_power > 0.0_wp .AND. reference_dista > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed infinite helper contract"
    END IF
  END SUBROUTINE expect_infinite_decay_routed

  SUBROUTINE expect_porous_twophase_routed(label, rt_ctx, mat_slot, model_flag, &
                                           alpha_vg, n_vg, phi, mat_pt_idx, &
                                           n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: model_flag
    REAL(wp), INTENT(IN) :: alpha_vg
    REAL(wp), INTENT(IN) :: n_vg
    REAL(wp), INTENT(IN) :: phi
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        model_flag >= 0.0_wp .AND. alpha_vg > 0.0_wp .AND. &
        n_vg > 1.0_wp .AND. phi > 0.0_wp .AND. phi < 1.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed porous helper contract"
    END IF
  END SUBROUTINE expect_porous_twophase_routed

  SUBROUTINE expect_axisym_routed(label, rt_ctx, mat_slot, D_tangent, stress_new, &
                                  mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: D_tangent(4, 4)
    REAL(wp), INTENT(IN) :: stress_new(4)
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        D_tangent(1,1) > 0.0_wp .AND. &
        D_tangent(3,3) > 0.0_wp .AND. &
        D_tangent(4,4) > 0.0_wp .AND. &
        stress_new(1) > 0.0_wp .AND. &
        stress_new(3) > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed material helper contract"
    END IF
  END SUBROUTINE expect_axisym_routed

  SUBROUTINE expect_3d_routed(label, rt_ctx, mat_slot, D_tangent, stress_new, &
                              mat_pt_idx, n_passed, n_failed)
    CHARACTER(LEN=*), INTENT(IN) :: label
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Mat_Slot), INTENT(IN) :: mat_slot
    REAL(wp), INTENT(IN) :: D_tangent(6, 6)
    REAL(wp), INTENT(IN) :: stress_new(6)
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    IF (rt_ctx%route_status == RT_MAT_ROUTE_OK .AND. &
        rt_ctx%mat_pt_idx == mat_pt_idx .AND. &
        mat_slot%desc%cfg%matId == mat_pt_idx .AND. &
        D_tangent(1,1) > 0.0_wp .AND. &
        D_tangent(4,4) > 0.0_wp .AND. &
        stress_new(1) > 0.0_wp) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A,A)') "  FAIL: ", TRIM(label), " routed material helper contract"
    END IF
  END SUBROUTINE expect_3d_routed

  LOGICAL FUNCTION expect_ok(status, label, n_failed)
    TYPE(ErrorStatusType), INTENT(IN) :: status
    CHARACTER(LEN=*), INTENT(IN) :: label
    INTEGER(i4), INTENT(INOUT) :: n_failed

    expect_ok = (status%status_code == IF_STATUS_OK)
    IF (.NOT. expect_ok) THEN
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A)') "  FAIL: ", TRIM(label)
    END IF
  END FUNCTION expect_ok

END MODULE TEST_Material_L3_L4_Closure
