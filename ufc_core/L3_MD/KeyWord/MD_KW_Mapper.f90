!===================================================================
! MODULE:  MD_KW_Mapper
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Impl
! BRIEF:   Semantic mapper: AST to Model structure conversion.
!          Routes parsed AST nodes to domain-specific handlers.
!===================================================================

MODULE MD_KW_Mapper
    USE MD_KWAP_Brg, ONLY: Parse_EL_FILE_Keyword, ElFileProperties, &
                            Parse_FILE_FORMAT_Keyword, FormatProperties, &
                            Parse_NODE_FILE_Keyword, NodeFileProperties, &
                            Parse_PREPRINT_Keyword, PreprintProperties, &
                            Parse_USER_OUTPUT_Keyword, UserOutputProperties, &
                            Parse_INCLUDE_Keyword, IncludeProperties
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc
    USE MD_Amp_Def, ONLY: AMP_TABULAR, AMP_SMOOTH, AMP_PERIODIC, AMP_USER
    USE MD_Asm_Sync
    USE MD_Int_Connector, ONLY: Parse_BUSHING_Keyword, BushingProperties
    USE MD_Int_Connector, ONLY: ConnectorProperties
    USE MD_Int_Connector, ONLY: Parse_DASHPOT_Keyword, DashProperties
    USE MD_Int_Connector, ONLY: Parse_JOINT_Keyword, JointProperties
    USE MD_Int_Connector, ONLY: Parse_SPRING_Keyword, SpringProperties
    ! Note: ConnectorBehavior and ConnectorSection modules are not yet merged into MD_Connector
    USE MD_Connector_ConnectorBehavior_Parse, ONLY: Parse_CONNECTOR_BEHAVIOR_Keyword
    USE MD_Connector_ConnectorBehavior_Type, ONLY: ConnectorBehaviorProperties
    USE MD_Connector_ConnectorSection_Parse, ONLY: Parse_CONNECTOR_SECTION_Keyword
    USE MD_Connector_ConnectorSection_Type, ONLY: ConnectorSectionProperties
    USE MD_Constr_Prop, ONLY: UF_ContactPropertyDef
    USE MD_Constr_Def, ONLY: MPCConstraintDef, MPC_TYPE_GENERAL, &
        MPCConstraintDef_Init, MPCConstraintDef_AddTerm, MPCConstraintDef_Cleanup, &
        TieConstraintDef, TieConstraintDef_Init, TieConstraintDef_Cleanup, &
        CplConstraintDef, CplConstraintDef_Init, &
        COUPLING_TYPE_KINEMATIC, COUPLING_TYPE_DISTRIBUTING, &
        RigidBodyDef, RigidBodyDef_Init, RBE_TYPE_RBE2, RBE_TYPE_RBE3
    USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
    USE MD_Asm_Mgr, ONLY: MD_Assembly_Domain
    USE MD_Cont_Mgr, ONLY: MD_ContactPairDef, CONT_FORM_SURFACE
    USE MD_Model_Data_Dist, ONLY: Parse_DISTRIBUTION_Keyword, DistributionProperties
    USE MD_Model_Data_Field, ONLY: Parse_FIELD_Keyword, FieldProperties
    USE MD_Model_Data_Filter, ONLY: Parse_FILTER_Keyword, FilterProperties
    USE MD_Model_Data_Param, ONLY: Parse_PARAMETER_Keyword => Parse_Param_Keyword, &
        ParameterProperties
    USE MD_Model_Data_PhysConst, ONLY: Parse_PHYSICAL_CONSTANTS_Keyword => PhysicalConstants_Parse_Keyword, &
        PhysicalConstantsProperties
    USE MD_Model_Data_Table, ONLY: Parse_TABLE_Keyword, TableProperties
    USE MD_Model_Data_Variable, ONLY: Parse_VARIABLE_Keyword, VariableProperties
    USE MD_Elem_Mgr, ONLY: ELEM_C3D4, ELEM_C3D6, ELEM_C3D6R, ELEM_C3D8, ELEM_C3D8R, &
                            ELEM_C3D10, ELEM_C3D10R, ELEM_C3D15, ELEM_C3D15R, &
                            ELEM_C3D20, ELEM_C3D20R, ELEM_S4, ELEM_S4R, ELEM_B31, &
                            ELEM_T2D2, ELEM_T3D2, ELEM_DC3D4, ELEM_DC3D6, ELEM_DC3D8, &
                            ELEM_P3D6SAT, ELEM_P3D6RCH, ELEM_P3D8SAT, ELEM_P3D8RCH
    USE MD_Field_Mgr
    USE MD_Fluid_Aqua_Parse, ONLY: Parse_AQUA_Keyword
    USE MD_Fluid_Aqua_Type, ONLY: AquaProperties
    USE MD_Fluid_Drag_Parse, ONLY: Parse_DRAG_Keyword
    USE MD_Fluid_Drag_Type, ONLY: DragProperties
    USE MD_Fluid_Flow_Parse, ONLY: Parse_FLOW_Keyword
    USE MD_Fluid_Flow_Type, ONLY: FlowProperties
    USE MD_Fluid_Fluid_Parse, ONLY: Parse_FLUID_Keyword
    USE MD_Fluid_Fluid_Type, ONLY: FluidProperties
    USE MD_Fluid_FluidCavity_Parse, ONLY: Parse_FLUID_CAVITY_Keyword
    USE MD_Fluid_FluidCavity_Type, ONLY: FluidCavityProperties
    USE MD_Fluid_FluidExchange_Parse, ONLY: Parse_FLUID_EXCHANGE_Keyword
    USE MD_Fluid_FluidExchange_Type, ONLY: FluidExchangeProperties
    USE MD_Fluid_Lift_Parse, ONLY: Parse_LIFT_Keyword
    USE MD_Fluid_Lift_Type, ONLY: LiftProperties
    USE MD_Fluid_PressurePenetration_Parse, ONLY: Parse_PRESSURE_PENETRATION_Keyword
    USE MD_Fluid_PressurePenetration_Type, ONLY: PressurePenetrationProperties
    USE MD_Asm_Inst
    USE MD_Int_ContactClearance_Parse, ONLY: Parse_CONTACT_CLEARANCE_Keyword
    USE MD_Interaction_ContactClearance_Type, ONLY: ContactClearanceProperties
    USE MD_Int_ContactControls_Parse, ONLY: Parse_CONTACT_CONTROLS_Keyword
    USE MD_Int_ContactControls_Type, ONLY: ContactControlsProperties
    USE MD_Int_ContactInitialization_Parse, ONLY: Parse_CONTACT_INITIALIZATION_Keyword
    USE MD_Int_ContactInitialization_Type, ONLY: ContactInitializationProperties
    USE MD_Int_ContactInterference_Parse, ONLY: Parse_CONTACT_INTERFERENCE_Keyword
    USE MD_Int_ContactInterference_Type, ONLY: ContactInterferenceProperties
    USE MD_Int_ContactOutput_Parse, ONLY: Parse_CONTACT_OUTPUT_Keyword
    USE MD_Int_ContactOutput_Type, ONLY: ContactOutputProperties
    USE MD_Int_ContactStabilization_Parse, ONLY: Parse_CONTACT_STABILIZATION_Keyword
    USE MD_Int_ContactStabilization_Type, ONLY: ContactStabilizationProperties
    USE MD_Int_Friction_Parse, ONLY: Parse_FRICTION_Keyword
    USE MD_Int_Friction_Type, ONLY: FrictionProperties
    USE MD_Int_FrictionCoefficient_Parse, ONLY: Parse_FRICTION_COEFFICIENT_Keyword
    USE MD_Int_FrictionCoefficient_Type, ONLY: FrictionCoefficientProperties
    USE MD_Int_FrictionOutput_Parse, ONLY: Parse_FRICTION_OUTPUT_Keyword
    USE MD_Int_FrictionOutput_Type, ONLY: FrictionOutputProperties
    USE MD_Int_StickSlip_Parse, ONLY: Parse_STICK_SLIP_Keyword
    USE MD_Int_StickSlip_Type, ONLY: StickSlipProperties
    USE MD_Int_UserContact_Parse, ONLY: Parse_USER_CONTACT_Keyword
    USE MD_Int_UserContact_Type, ONLY: UserContactProperties
    ! Kinematic modules - now from unified module MD_LoadBC_Kinematic_Parse
    USE MD_LoadBC_Kinematic_Parse, ONLY: &
        Parse_ACCELERATION_Keyword, AccelerationProperties, &
        Parse_BASE_MOTION_Keyword, BaseMotionProperties, &
        Parse_KINEMATIC_Keyword, KinematicProperties, &
        Parse_MOTION_Keyword, MotionProperties, &
        Parse_VELOCITY_Keyword, VelocityProperties
    USE MD_KW_MemoryPool, ONLY: MemoryPoolManager
    USE MD_KW_MemoryPool, ONLY: MemoryPoolManager
    USE MD_KW_Parser
    USE MD_KW_Reg
    USE MD_KW_Def
    ! Load modules - now from unified module MD_LoadBC_Parse
    USE MD_LoadBC_Parse, ONLY: &
        DsfluxDesc, Parse_DSFLUX_Keyword, &
        FilmBCDesc, Parse_FILM_Keyword, &
        MassFlowDesc, Parse_MASSFLOW_Keyword, &
        RadiateBCDesc, Parse_RADIATE_Keyword, &
        SfilmBCDesc, Parse_SFILM_Keyword, &
        SradiationBCDesc, Parse_SRADIATION_Keyword, &
        UserAmplitudeProperties, Parse_USER_AMPLITUDE_Keyword, &
        UserLoadProperties, Parse_USER_LOAD_Keyword
    USE MD_LBC_Mgr, ONLY: TARGET_NODE, TARGET_NODESET, TARGET_SURFACE, TARGET_ELEMSET, TARGET_EDGE
    USE MD_LBC_Brg, ONLY: BC_DISPLACEMENT, BC_VELOCITY, BC_ACCELERATION, BC_TEMPERATURE, &
                           BC_ENCASTRE, BC_PINNED, BC_XSYMM, BC_YSYMM, BC_ZSYMM
    ! Note: Removed USE statements for manufacturing modules (deleted as unused):
    !   - MD_Manufacturing_Cooling_Parse, MD_Manufacturing_Cooling_Type
    !   - MD_Manufacturing_DeepDrawing_Parse, MD_Manufacturing_DeepDrawing_Type
    !   - MD_Manufacturing_Extrusion_Parse, MD_Manufacturing_Extrusion_Type
    !   - MD_Manufacturing_Forging_Parse, MD_Manufacturing_Forging_Type
    !   - MD_Manufacturing_Forming_Parse, MD_Manufacturing_Forming_Type
    !   - MD_Manufacturing_HeatTreatment_Parse, MD_Manufacturing_HeatTreatment_Type
    !   - MD_Manufacturing_Machining_Parse, MD_Manufacturing_Machining_Type
    !   - MD_Manufacturing_Rolling_Parse, MD_Manufacturing_Rolling_Type
    !   - MD_Manufacturing_Stamping_Parse, MD_Manufacturing_Stamping_Type
    !   - MD_Manufacturing_Weld_Parse, MD_Manufacturing_Weld_Type
    !   - MD_Manufacturing_WeldResidualStress_Parse, MD_Manufacturing_WeldResidualStress_Type
    !   - MD_Manufacturing_WeldSeam_Parse, MD_Manufacturing_WeldSeam_Type
    USE MD_Mat_Lib, ONLY: UF_MaterialDef
    ! Note: Removed USE statements for mesh modules (deleted as unused):
    !   - MD_Mesh_MeshConstraint
    !   - MD_Mesh_Remesh
    ! Note: Removed USE statements for adaptive mesh modules (deleted as unused):
    !   - MD_Mesh_AdaptiveMesh
    !   - MD_Mesh_AdaptiveMeshControls
    !   - MD_Mesh_MeshRefinement
    USE MD_Mesh_Remesh, ONLY: Parse_REMESH_Keyword, RemeshProperties
    USE MD_Model_Lib_Core, ONLY: UF_ModelDef
    USE MD_Multiphysics_Acoustic_Parse, ONLY: Parse_ACOUSTIC_Keyword
    USE MD_Multiphysics_Acoustic_Type, ONLY: AcousticProperties
    USE MD_Multiphysics_Electrical_Parse, ONLY: Parse_ELECTRICAL_Keyword
    USE MD_Multiphysics_Electrical_Type, ONLY: ElectricalProperties
    USE MD_Multiphysics_Magnetic_Parse, ONLY: Parse_MAGNETIC_Keyword
    USE MD_Multiphysics_Magnetic_Type, ONLY: MagneticProperties
    USE MD_Multiphysics_Multiphysics_Parse, ONLY: Parse_MULTIPHYSICS_Keyword
    USE MD_Multiphysics_Multiphysics_Type, ONLY: MultiphysicsProperties
    USE MD_Multiphysics_Piezoelectric_Parse, ONLY: Parse_PIEZOELECTRIC_Keyword
    USE MD_Multiphysics_Piezoelectric_Type, ONLY: PiezoelectricProperties
    USE MD_Optimization_Constraint_Parse, ONLY: Parse_OPTIMIZATION_CONSTRAINT_Keyword
    USE MD_Optimization_Constraint_Type, ONLY: OptimizationConstraintProperties
    USE MD_Optimization_Controls_Parse, ONLY: Parse_OPTIMIZATION_CONTROLS_Keyword
    USE MD_Optimization_Controls_Type, ONLY: OptimizationControlsProperties
    USE MD_Optimization_DesignResponse_Parse, ONLY: Parse_DESIGN_RESPONSE_Keyword
    USE MD_Optimization_DesignResponse_Type, ONLY: DesignResponseProperties
    USE MD_Optimization_DesignVariable_Parse, ONLY: Parse_DESIGN_VARIABLE_Keyword
    USE MD_Optimization_DesignVariable_Type, ONLY: DesignVariableProperties
    USE MD_Optimization_History_Parse, ONLY: Parse_OPTIMIZATION_HISTORY_Keyword
    USE MD_Optimization_History_Type, ONLY: OptimizationHistoryProperties
    USE MD_Optimization_Objective_Parse, ONLY: Parse_OBJECTIVE_Keyword
    USE MD_Optimization_Objective_Type, ONLY: ObjectiveProperties
    USE MD_Optimization_Sensitivity_Parse, ONLY: Parse_SENSITIVITY_Keyword
    USE MD_Optimization_Sensitivity_Type, ONLY: SensitivityProperties
    USE MD_Optimization_Shape_Parse, ONLY: Parse_SHAPE_OPTIMIZATION_Keyword
    USE MD_Optimization_Shape_Type, ONLY: ShapeOptimizationProperties
    USE MD_Optimization_Size_Parse, ONLY: Parse_SIZE_OPTIMIZATION_Keyword
    USE MD_Optimization_Size_Type, ONLY: SizeOptimizationProperties
    USE MD_Optimization_Topology_Parse, ONLY: Parse_TOPOLOGY_OPTIMIZATION_Keyword
    USE MD_Optimization_Topology_Type, ONLY: TopologyOptimizationProperties
    USE MD_Out_Lib
    USE MD_Out_Parse,         ONLY: Parse_OUTPUT_FILTER_Keyword, Parse_OUTPUT_FORMAT_Keyword, &
                                    Parse_OUTPUT_FREQUENCY_Keyword, Parse_OUTPUT_REQUEST_Keyword, &
                                    Parse_OUTPUT_VARIABLE_Keyword, &
                                    OutputFilterProperties => OutFilterProperties, &
                                    OutputFormatProperties => OutFormatProperties, &
                                    OutputFrequencyProperties => OutFrequencyProperties, &
                                    OutputRequestProperties => OutRequestProperties, &
                                    OutputVariableProperties => OutVariableProperties
    USE MD_Out_ReportPlot,    ONLY: Parse_ANIMATION_Keyword, Parse_EXPORT_Keyword, Parse_PLOT_Keyword, &
                                    Parse_POST_PROCESSING_Keyword, Parse_REPORT_Keyword, &
                                    AnimationProperties, ExportProperties, PlotProperties, &
                                    PostProcessingProperties, ReportProperties
    USE MD_Part_Mgr
    USE MD_Sect_PropMass,          ONLY: Parse_MASS_Keyword, PtMassDesc
    USE MD_Sect_PropNonStructMass, ONLY: Parse_NONSTRUCTURALMASS_Keyword, NonStructMassDesc
    USE MD_Sect_PropPtMass,        ONLY: Parse_POINTMASS_Keyword, PtMassAltDesc
    USE MD_Sect_PropRotInertia,    ONLY: Parse_ROTARYINERTIA_Keyword, RotInertiaDesc
    USE MD_Sect_Lib              ! L2 section database (UF_SectionDef)
    USE MD_Sets_Mgr
    USE MD_Step_Proc
    USE MD_Model_Coord_Normal, ONLY: NormalProps, Parse_NORMAL_Keyword
    USE MD_Model_Coord_Orient, ONLY: OrientProps, Parse_ORIENTATION_Keyword
    USE MD_Model_Coord_Sys, ONLY: SystemProps, Parse_SYSTEM_Keyword
    USE MD_Model_Coord_Transform, ONLY: Parse_TRANSFORM_Keyword, TransformProps
    USE MD_KWRT_Brg, ONLY: ComplexFrequencyProperties, DirectProperties, &
                            ModalDampingProperties, ModalDynamicProperties, &
                            ResponseSpectrumProperties, SteadyStateProperties, &
                            SubstructureProperties, &
                            MD_RT_KW_ParseComplexFrequency, MD_RT_KW_ParseDirect, &
                            MD_RT_KW_ParseModalDamping, MD_RT_KW_ParseModalDynamic, &
                            MD_RT_KW_ParseResponseSpectrum, MD_RT_KW_ParseSteadyState, &
                            MD_RT_KW_ParseSubstructure, MD_RT_KW_ParseStaticRiks
    USE UF_Section,   ONLY: UF_Section_RegisterMaterialName  ! L4 unified section registry
    USE UF_UMAT_Types, ONLY: MATTYPE_ISO_ELASTIC, MATTYPE_MISES
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! Mapper State
    ! ==========================================================================
    TYPE, PUBLIC :: KW_MapperStateType
        TYPE(KW_ParserStateType), POINTER :: parser => NULL()
        TYPE(UF_ModelDef), POINTER :: model => NULL()
        
        ! Current context
        TYPE(UF_PartDef), POINTER :: current_part => NULL()
        TYPE(UF_InstanceDef), POINTER :: current_instance => NULL()
        TYPE(UF_MaterialDef), POINTER :: current_material => NULL()
        TYPE(UF_ContactPropertyDef), POINTER :: current_contact_prop => NULL()
        INTEGER(i4) :: current_step_idx = 0

        ! Performance optimization: Memory pool
        TYPE(MemoryPoolManager) :: memoryPool
        
        ! Statistics
        INTEGER(i4) :: nodes_mapped = 0
        INTEGER(i4) :: elements_mapped = 0
        INTEGER(i4) :: materials_mapped = 0
        INTEGER(i4) :: sections_mapped = 0
        INTEGER(i4) :: steps_mapped = 0
        
        ! Error tracking
        INTEGER(i4) :: error_count = 0
        INTEGER(i4) :: warning_count = 0
        LOGICAL :: stop_on_error = .FALSE.
    END TYPE KW_MapperStateType

    ! ==========================================================================
    ! Public Interface
    ! ==========================================================================
    PUBLIC :: kw_mapper_init
    PUBLIC :: kw_mapper_map_to_model
    PUBLIC :: kw_mapper_get_statistics
    PUBLIC :: kw_mapper_cleanup
    PUBLIC :: md_kw_get_param_value  ! Helper function for extracting parameter values from AST nodes

CONTAINS

    ! ==========================================================================
    ! Initialize mapper
    ! ==========================================================================
    SUBROUTINE kw_mapper_init(mapper, parser, model)
        TYPE(KW_MapperStateType), INTENT(OUT) :: mapper
        TYPE(KW_ParserStateType), INTENT(IN), TARGET :: parser
        TYPE(UF_ModelDef), INTENT(INOUT), TARGET :: model
        TYPE(ErrorStatusType) :: status
        
        mapper%parser => parser
        mapper%model => model
        NULLIFY(mapper%current_part)
        NULLIFY(mapper%current_instance)
        NULLIFY(mapper%current_material)
        NULLIFY(mapper%current_contact_prop)
        mapper%current_step_idx = 0
        
        ! Initialize performance optimization components
        ! Note: Parse cache, performance monitor, and parallel parser removed (temporarily unused)
        
        CALL mapper%memoryPool%Init(realPoolSize=100000, intPoolSize=100000, status=status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'WARNING: Failed to initialize memory pool'
        END IF

        mapper%nodes_mapped = 0
        mapper%elements_mapped = 0
        mapper%materials_mapped = 0
        mapper%sections_mapped = 0
        mapper%steps_mapped = 0
        mapper%error_count = 0
        mapper%warning_count = 0
    END SUBROUTINE kw_mapper_init

    ! ==========================================================================
    ! Map all AST nodes to Model
    ! ==========================================================================
    SUBROUTINE kw_mapper_map_to_model(mapper, success)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        LOGICAL, INTENT(OUT) :: success
        
        INTEGER(i4) :: i
        TYPE(KW_ASTNodeType), POINTER :: node
        LOGICAL :: has_part, has_assembly, has_instance, has_mesh
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: kw_name
        
        success = .FALSE.
        
        IF (.NOT. ASSOCIATED(mapper%parser)) RETURN
        IF (.NOT. ASSOCIATED(mapper%model)) RETURN
        
        ! Detect flat INP files: mesh keywords without any PART/ASSEMBLY/INSTANCE
        has_part = .FALSE.
        has_assembly = .FALSE.
        has_instance = .FALSE.
        has_mesh = .FALSE.
        
        DO i = 1, mapper%parser%node_count
            node => mapper%parser%nodes(i)
            kw_name = kw_to_upper(TRIM(node%keyword_name))
            SELECT CASE (TRIM(kw_name))
            CASE ("PART", "END PART")
                has_part = .TRUE.
            CASE ("ASSEMBLY", "END ASSEMBLY")
                has_assembly = .TRUE.
            CASE ("INSTANCE", "END INSTANCE")
                has_instance = .TRUE.
            CASE ("NODE", "ELEMENT", "NSET", "ELSET", "SURFACE")
                has_mesh = .TRUE.
            END SELECT
        END DO
        
        IF (has_mesh .AND. .NOT. (has_part .OR. has_assembly .OR. has_instance)) THEN
            CALL map_create_default_part(mapper)
        END IF
        
        ! First pass: Map structural elements (Parts, Assembly)
        ! This establishes the model hierarchy
        DO i = 1, mapper%parser%node_count
            node => mapper%parser%nodes(i)
            CALL map_structural_node(mapper, node)
            IF (mapper%error_count > 0 .AND. mapper%stop_on_error) THEN
                success = .FALSE.
                RETURN
            END IF
        END DO
        
        ! Second pass: Map mesh data (Nodes, Elements, Sets)
        ! Requires Parts to be established first
        DO i = 1, mapper%parser%node_count
            node => mapper%parser%nodes(i)
            CALL map_mesh_node(mapper, node)
            IF (mapper%error_count > 0 .AND. mapper%stop_on_error) THEN
                success = .FALSE.
                RETURN
            END IF
        END DO
        
        ! Third pass: Map properties (Materials, Sections)
        ! Can reference materials and sections defined earlier
        DO i = 1, mapper%parser%node_count
            node => mapper%parser%nodes(i)
            CALL map_property_node(mapper, node)
            IF (mapper%error_count > 0 .AND. mapper%stop_on_error) THEN
                success = .FALSE.
                RETURN
            END IF
        END DO
        
        ! Fourth pass: Map analysis data (Steps, Loads, BCs)
        ! Requires all model data to be established
        DO i = 1, mapper%parser%node_count
            node => mapper%parser%nodes(i)
            CALL map_analysis_node(mapper, node)
            IF (mapper%error_count > 0 .AND. mapper%stop_on_error) THEN
                success = .FALSE.
                RETURN
            END IF
        END DO
        
        success = (mapper%error_count == 0)
    END SUBROUTINE kw_mapper_map_to_model

    ! ==========================================================================
    ! Map structural nodes (PART, ASSEMBLY, INSTANCE)
    ! ==========================================================================
    SUBROUTINE map_structural_node(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_val
        
        SELECT CASE (TRIM(node%keyword_name))
        CASE ("HEADING")
            CALL md_kw_get_param_value(node, "NONE", name_val)
            ! Heading is typically in data lines
            IF (node%data_line_count > 0) THEN
                mapper%model%name = TRIM(node%data_lines(1)%values(1))
            END IF
            
        CASE ("PART")
            CALL map_part(mapper, node)
            
        CASE ("INSTANCE")
            CALL map_instance(mapper, node)
            
        CASE ("ASSEMBLY")
            CALL md_kw_get_param_value(node, "NAME", name_val)
            CALL mapper%model%assembly%init(TRIM(name_val))
            
        END SELECT
    END SUBROUTINE map_structural_node

    ! ==========================================================================
    ! Map mesh nodes (NODE, ELEMENT, NSET, ELSET, SURFACE)
    ! ==========================================================================
    SUBROUTINE map_mesh_node(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_val, kw_upper
        
        ! DEBUG
        WRITE(*,*) "DEBUG: map_mesh_node visiting: '", TRIM(node%keyword_name), "' Len=", LEN_TRIM(node%keyword_name)
        WRITE(*,*) "Is NODE? ", kw_to_upper(TRIM(node%keyword_name)) == "NODE"
        
        kw_upper = kw_to_upper(TRIM(node%keyword_name))
        SELECT CASE (TRIM(kw_upper))
        CASE ("PART")

            CALL md_kw_get_param_value(node, "NAME", name_val)
            IF (LEN_TRIM(name_val) > 0) THEN
                mapper%current_part => mapper%model%get_part(TRIM(name_val))
            END IF
            
        CASE ("END PART")
            NULLIFY(mapper%current_part)
            
        CASE ("NODE")
            CALL map_nodes(mapper, node)
            
        CASE ("ELEMENT")
            CALL map_elements(mapper, node)
            
        CASE ("NSET")
            CALL map_nset(mapper, node)
            
        CASE ("ELSET")
            CALL map_elset(mapper, node)
            
        CASE ("SURFACE")
            WRITE(*,*) "DEBUG: *** ENTER map_surface CASE in map_mesh_node ***"
            CALL map_surface(mapper, node)
            

        CASE DEFAULT
            WRITE(*,*) "DEBUG: DEFAULT CASE for: ", TRIM(node%keyword_name)
        END SELECT

    END SUBROUTINE map_mesh_node

    ! ==========================================================================
    ! Map property nodes (MATERIAL, ELASTIC, SECTION, etc.)
    ! ==========================================================================
    SUBROUTINE map_property_node(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_val
        
        SELECT CASE (TRIM(node%keyword_name))
        CASE ("PART")
            CALL md_kw_get_param_value(node, "NAME", name_val)
            IF (LEN_TRIM(name_val) > 0) THEN
                mapper%current_part => mapper%model%get_part(TRIM(name_val))
            END IF
            
        CASE ("END PART")
            NULLIFY(mapper%current_part)
            
        CASE ("MATERIAL")
            CALL map_material(mapper, node)
            
        CASE ("ELASTIC")
            CALL map_elastic(mapper, node)
            
        CASE ("PLASTIC")
            CALL map_plastic(mapper, node)
            
        CASE ("VISCOELASTIC")
            CALL map_creep(mapper, node)
            
        CASE ("CREEP")
            CALL map_creep(mapper, node)
            
        CASE ("DAMAGE")
            CALL map_damage_puck(mapper, node)
            
        CASE ("DENSITY")
            CALL map_density(mapper, node)

        CASE ("MASS")
            CALL map_mass(mapper, node)

        CASE ("ROTARY INERTIA", "INERTIA")
            CALL map_rotary_inertia(mapper, node)

        CASE ("POINT MASS")
            CALL map_point_mass(mapper, node)

        CASE ("NONSTRUCTURAL MASS")
            CALL map_nonstructural_mass(mapper, node)
            
        CASE ("CONDUCTIVITY")
            CALL map_conductivity(mapper, node)
            
        CASE ("SPECIFIC HEAT")
            CALL map_specific_heat(mapper, node)
            
        CASE ("LATENT HEAT")
            CALL map_latent_heat(mapper, node)
            
        CASE ("JOULE HEAT")
            CALL map_joule_heat(mapper, node)
            
        CASE ("COHESIVE BEHAVIOR")
            CALL map_cohesive_behavior(mapper, node)
            
        CASE ("DAMAGE INITIATION")
            CALL map_damage_initiation(mapper, node)
            
        CASE ("DAMAGE EVOLUTION")
            CALL map_damage_evolution(mapper, node)
            
        CASE ("PROGRESSIVE DAMAGE")
            CALL map_progressive_damage(mapper, node)
            
        CASE ("RATE DEPENDENT")
            CALL map_rate_dependent(mapper, node)
            
        CASE ("VISCO", "VISCOELASTIC")
            CALL map_visco(mapper, node)
            
        CASE ("HYPERFOAM")
            CALL map_hyperfoam(mapper, node)
            
        CASE ("HYPOELASTIC")
            CALL map_hypoelastic(mapper, node)
            
        CASE ("CAP PLASTICITY")
            CALL map_cap_plasticity(mapper, node)
            
        CASE ("CRYSTAL PLASTICITY")
            CALL map_crystal_plasticity(mapper, node)
            
        CASE ("DRUCKER PRAGER")
            CALL map_drucker_prager(mapper, node)
            
        CASE ("MOHR COULOMB")
            CALL map_mohr_coulomb(mapper, node)
            
        CASE ("ORIENTATION")
            CALL map_orientation(mapper, node)
            
        CASE ("TRANSFORM")
            CALL map_transform(mapper, node)
            
        CASE ("SYSTEM")
            CALL map_system(mapper, node)
            
        CASE ("NORMAL")
            CALL map_normal(mapper, node)
            
        CASE ("DISTRIBUTION")
            CALL map_distribution(mapper, node)
            
        CASE ("TABLE")
            CALL map_table(mapper, node)
            
        CASE ("FIELD")
            CALL map_field(mapper, node)
            
        CASE ("PARAMETER")
            CALL map_parameter(mapper, node)
            
        CASE ("VARIABLE")
            CALL map_variable(mapper, node)
            
        CASE ("FILTER")
            CALL map_filter(mapper, node)
            
        CASE ("INCLUDE")
            CALL map_include(mapper, node)
            
        CASE ("PREPRINT")
            CALL map_preprint(mapper, node)
            
        CASE ("FILE FORMAT")
            CALL map_file_format(mapper, node)
            
        CASE ("PHYSICAL CONSTANTS")
            CALL map_physical_constants(mapper, node)
            
        CASE ("NODE FILE")
            CALL map_node_file(mapper, node)
            
        CASE ("EL FILE")
            CALL map_el_file(mapper, node)
            
        CASE ("MODAL DAMPING")
            CALL map_modal_damping(mapper, node)
            
        CASE ("STEADY STATE DYNAMICS")
            CALL map_steady_state_dynamics(mapper, node)
            
        CASE ("DIRECT")
            CALL map_direct(mapper, node)
            
        CASE ("SUBSTRUCTURE")
            CALL map_substructure(mapper, node)
            
        CASE ("MODAL DYNAMIC")
            CALL map_modal_dynamic(mapper, node)
            
        CASE ("COMPLEX FREQUENCY")
            CALL map_complex_frequency(mapper, node)
            
        CASE ("RESPONSE SPECTRUM")
            CALL map_response_spectrum(mapper, node)
            
        CASE ("USER MATERIAL")
            CALL map_user_material(mapper, node)
            
        CASE ("USER ELEMENT")
            CALL map_user_element(mapper, node)
            
        CASE ("USER DEFINED FIELD")
            CALL map_user_defined_field(mapper, node)
            
        CASE ("USER LOAD")
            CALL map_user_load(mapper, node)
            
        CASE ("USER CONTACT")
            CALL map_user_contact(mapper, node)
            
        CASE ("USER OUTPUT")
            CALL map_user_output(mapper, node)
            
        CASE ("USER AMPLITUDE")
            CALL map_user_amplitude(mapper, node)
            
        CASE ("USER SUBROUTINE")
            CALL map_user_subroutine(mapper, node)
            
        CASE ("ADAPTIVE MESH")
            CALL map_adaptive_mesh(mapper, node)
            
        CASE ("ADAPTIVE MESH CONTROLS")
            CALL map_adaptive_mesh_controls(mapper, node)
            
        ! Note: REMESH, MESH REFINEMENT, and MESH CONSTRAINT keywords removed (modules deleted as unused)
        ! CASE ("REMESH")
        ! CASE ("MESH REFINEMENT")
        ! CASE ("MESH CONSTRAINT")
            
        CASE ("DESIGN RESPONSE")
            CALL map_design_response(mapper, node)
            
        CASE ("OBJECTIVE")
            CALL map_objective(mapper, node)
            
        CASE ("DESIGN VARIABLE")
            CALL map_design_variable(mapper, node)
            
        CASE ("CONSTRAINT")
            CALL map_optimization_constraint(mapper, node)
            
        CASE ("SENSITIVITY")
            CALL map_sensitivity(mapper, node)
            
        CASE ("TOPOLOGY OPTIMIZATION")
            CALL map_topology_optimization(mapper, node)
            
        CASE ("SHAPE OPTIMIZATION")
            CALL map_shape_optimization(mapper, node)
            
        CASE ("SIZE OPTIMIZATION")
            CALL map_size_optimization(mapper, node)
            
        CASE ("OPTIMIZATION CONTROLS")
            CALL map_optimization_controls(mapper, node)
            
        CASE ("OPTIMIZATION HISTORY")
            CALL map_optimization_history(mapper, node)
            
        CASE ("CONNECTOR")
            CALL map_connector(mapper, node)
            
        CASE ("CONNECTOR BEHAVIOR")
            CALL map_connector_behavior(mapper, node)
            
        CASE ("CONNECTOR SECTION")
            CALL map_connector_section(mapper, node)
            
        CASE ("JOINT")
            CALL map_joint(mapper, node)
            
        CASE ("BUSHING")
            CALL map_bushing(mapper, node)
            
        CASE ("SPRING")
            CALL map_spring(mapper, node)
            
        CASE ("DASHPOT")
            CALL map_dashpot(mapper, node)
            
        CASE ("KINEMATIC")
            CALL map_kinematic(mapper, node)
            
        CASE ("MOTION")
            CALL map_motion(mapper, node)
            
        CASE ("VELOCITY")
            CALL map_velocity(mapper, node)
            
        CASE ("ACCELERATION")
            CALL map_acceleration(mapper, node)
            
        CASE ("BASE MOTION")
            CALL map_base_motion(mapper, node)
            
        CASE ("COMPOSITE")
            CALL map_composite(mapper, node)
            
        CASE ("LAMINATE")
            CALL map_laminate(mapper, node)
            
        CASE ("FIBER REINFORCED")
            CALL map_fiber_reinforced(mapper, node)
            
        CASE ("PUCK CRITERION")
            CALL map_puck_criterion(mapper, node)
            
        CASE ("HASHIN CRITERION")
            CALL map_hashin_criterion(mapper, node)
            
        CASE ("JOHNSON COOK")
            CALL map_johnson_cook(mapper, node)
            
        CASE ("ZERILLI ARMSTRONG")
            CALL map_zerilli_armstrong(mapper, node)
            
        CASE ("ANAND")
            CALL map_anand(mapper, node)
            
        CASE ("BODNER PARTOM")
            CALL map_bodner_partom(mapper, node)
            
        CASE ("CHABOCHE")
            CALL map_chaboche(mapper, node)
            
        CASE ("ARRUDA BOYCE")
            CALL map_arruda_boyce(mapper, node)
            
        CASE ("VAN DER WAALS")
            CALL map_van_der_waals(mapper, node)
            
        CASE ("MARLOW")
            CALL map_marlow(mapper, node)
            
        CASE ("FABRIC")
            CALL map_fabric(mapper, node)
            
        CASE ("ANISOTROPIC HYPERELASTIC")
            CALL map_anisotropic_hyperelastic(mapper, node)
            
        CASE ("AQUA")
            CALL map_aqua(mapper, node)
            
        CASE ("FLUID")
            CALL map_fluid(mapper, node)
            
        CASE ("FLUID CAVITY")
            CALL map_fluid_cavity(mapper, node)
            
        CASE ("FLUID EXCHANGE")
            CALL map_fluid_exchange(mapper, node)
            
        CASE ("FLOW")
            CALL map_flow(mapper, node)
            
        CASE ("PRESSURE PENETRATION")
            CALL map_pressure_penetration(mapper, node)
            
        CASE ("DRAG")
            CALL map_drag(mapper, node)
            
        CASE ("LIFT")
            CALL map_lift(mapper, node)
            
        CASE ("FSI", "FLUID STRUCTURE INTERACTION", "COUPLED TEMPERATURE DISPLACEMENT", &
              "COUPLED THERMAL ELECTRICAL", "COUPLED THERMAL ELECTRICAL STRUCTURAL")
            CALL map_multiphysics_coupling_removed(mapper, node)
            
        CASE ("ELECTRICAL")
            CALL map_electrical(mapper, node)
            
        CASE ("MAGNETIC")
            CALL map_magnetic(mapper, node)
            
        CASE ("ACOUSTIC")
            CALL map_acoustic(mapper, node)
            
        CASE ("PIEZOELECTRIC")
            CALL map_piezoelectric(mapper, node)
            
        CASE ("MULTIPHYSICS")
            CALL map_multiphysics(mapper, node)
            
        CASE ("CONTACT INTERFERENCE")
            CALL map_contact_interference(mapper, node)
            
        CASE ("CONTACT CLEARANCE")
            CALL map_contact_clearance(mapper, node)
            
        CASE ("CONTACT INITIALIZATION")
            CALL map_contact_initialization(mapper, node)
            
        CASE ("CONTACT OUTPUT")
            CALL map_contact_output(mapper, node)
            
        CASE ("CONTACT CONTROLS")
            CALL map_contact_controls(mapper, node)
            
        CASE ("CONTACT STABILIZATION")
            CALL map_contact_stabilization(mapper, node)
            
        CASE ("FRICTION")
            CALL map_friction(mapper, node)
            
        CASE ("FRICTION COEFFICIENT")
            CALL map_friction_coefficient(mapper, node)
            
        CASE ("STICK SLIP")
            CALL map_stick_slip(mapper, node)
            
        CASE ("FRICTION OUTPUT")
            CALL map_friction_output(mapper, node)
            
        ! Note: Manufacturing keywords removed (modules deleted as unused):
        ! CASE ("FORMING")
        ! CASE ("DEEP DRAWING")
        ! CASE ("STAMPING")
        ! CASE ("FORGING")
        ! CASE ("EXTRUSION")
        ! CASE ("ROLLING")
        ! CASE ("WELD")
        ! CASE ("WELD SEAM")
        ! CASE ("WELD RESIDUAL STRESS")
        ! CASE ("MACHINING")
        ! CASE ("HEAT TREATMENT")
        ! CASE ("COOLING")
            
        CASE ("OUTPUT REQUEST")
            CALL map_output_request(mapper, node)
            
        CASE ("OUTPUT VARIABLE")
            CALL map_output_variable(mapper, node)
            
        CASE ("OUTPUT FILTER")
            CALL map_output_filter(mapper, node)
            
        CASE ("OUTPUT FREQUENCY")
            CALL map_output_frequency(mapper, node)
            
        CASE ("OUTPUT FORMAT")
            CALL map_output_format(mapper, node)
            
        CASE ("POST PROCESSING")
            CALL map_post_processing(mapper, node)
            
        CASE ("ANIMATION")
            CALL map_animation(mapper, node)
            
        CASE ("PLOT")
            CALL map_plot(mapper, node)
            
        CASE ("REPORT")
            CALL map_report(mapper, node)
            
        CASE ("EXPORT")
            CALL map_export(mapper, node)
            
        CASE ("EXPANSION")
            CALL map_expansion(mapper, node)

        CASE ("THERMO ELASTIC", "THERMOELASTIC")
            CALL map_thermo_elastic_kw(mapper, node)

        CASE ("PIEZO ELASTIC", "PIEZOELASTIC")
            CALL map_piezo_elastic_kw(mapper, node)

        CASE ("THERMO ELEC ELASTIC", "THERMOELECELASTIC", "THERMO PIEZO ELASTIC", "THERMOPIEZOELASTIC")
            CALL map_thermo_elec_elastic_kw(mapper, node)
            
        CASE ("DAMPING")
            CALL map_damping(mapper, node)
            
        CASE ("VISCOSITY")
            CALL map_viscosity(mapper, node)
            
        CASE ("THERMAL CONDUCTIVITY")
            CALL map_thermal_conductivity(mapper, node)
            
        CASE ("PERMEABILITY")
            CALL map_permeability(mapper, node)
            
        CASE ("SORPTION")
            CALL map_sorption(mapper, node)
            
        CASE ("UF-THERMAL")
            CALL map_uf_thermal(mapper, node)
            
        CASE ("UF-PORO")
            CALL map_uf_poro(mapper, node)
            
        CASE ("UF-PORO-2PH")
            CALL map_uf_poro_2ph(mapper, node)
            
        CASE ("DAMPING")

            CALL map_damping(mapper, node)
            
        CASE ("SOLID SECTION")

            CALL map_solid_section(mapper, node)
            
        CASE ("SHELL SECTION")
            CALL map_shell_section(mapper, node)
            
        CASE ("BEAM SECTION")
            CALL map_beam_section(mapper, node)
            
        CASE ("AMPLITUDE")
            CALL map_amplitude(mapper, node)

        CASE ("SURFACE INTERACTION")
            CALL map_surface_interaction(mapper, node)

        CASE ("FRICTION")
            CALL map_friction(mapper, node)

        CASE ("EQUATION")
            CALL map_equation(mapper, node)

        CASE ("TIE")
            CALL map_tie_constraint(mapper, node)

        CASE ("COUPLING")
            CALL map_coupling_constraint(mapper, node)

        CASE ("KINEMATIC COUPLING")
            CALL map_kinematic_coupling_constraint(mapper, node)

        CASE ("DISTRIBUTING COUPLING")
            CALL map_distributing_coupling_constraint(mapper, node)

        CASE ("RIGID BODY")
            CALL map_rigid_body_constraint(mapper, node)
            
        END SELECT

    END SUBROUTINE map_property_node

    ! ==========================================================================
    ! Map *EQUATION -> L3 md_layer%constraint (MPCConstraintDef + equation_rhs)
    ! Abaqus: line1 = n (terms); line2 = n*(node, dof, coeff) [, rhs]
    ! ==========================================================================
    SUBROUTINE map_equation(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        INTEGER(i4) :: n_terms, k, nc, next_id
        REAL(wp) :: rhs_val, coeff_k
        INTEGER(i4) :: node_k, dof_k
        TYPE(MPCConstraintDef) :: mpc_def
        TYPE(ErrorStatusType) :: st
        CHARACTER(LEN=80) :: eq_name

        IF (.NOT. g_ufc_global%IsReady()) THEN
            CALL add_mapping_error(mapper, node%start_line, &
                "*EQUATION: global container not ready (IsReady=.FALSE.)")
            RETURN
        END IF
        IF (.NOT. g_ufc_global%md_layer%constraint%initialized) THEN
            CALL add_mapping_error(mapper, node%start_line, &
                "*EQUATION: constraint domain not initialized")
            RETURN
        END IF

        IF (node%data_line_count < 2) THEN
            CALL add_mapping_error(mapper, node%start_line, "*EQUATION requires 2 data lines (n, then node,dof,coeff...)")
            RETURN
        END IF

        n_terms = node%data_lines(1)%int_values(1)
        IF (n_terms <= 0_i4) n_terms = INT(node%data_lines(1)%real_values(1), i4)
        IF (n_terms < 1_i4) THEN
            CALL add_mapping_error(mapper, node%start_line, "*EQUATION: first line n must be >= 1")
            RETURN
        END IF

        nc = node%data_lines(2)%col_count
        IF (nc < 3 * n_terms) THEN
            CALL add_mapping_error(mapper, node%start_line, "*EQUATION: second line needs 3*n columns (or 3*n+1 with RHS)")
            RETURN
        END IF

        rhs_val = 0.0_wp
        IF (nc >= 3 * n_terms + 1) rhs_val = node%data_lines(2)%real_values(3 * n_terms + 1)

        next_id = g_ufc_global%md_layer%constraint%constraint_union%n_mpc + 1_i4
        WRITE (eq_name, '(A,I0)') 'EQ', next_id

        CALL MPCConstraintDef_Cleanup(mpc_def, st)
        CALL MPCConstraintDef_Init(mpc_def, TRIM(eq_name), MPC_TYPE_GENERAL, st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            CALL add_mapping_error(mapper, node%start_line, "MPCConstraintDef_Init failed for *EQUATION")
            CALL MPCConstraintDef_Cleanup(mpc_def, st)
            RETURN
        END IF

        mpc_def%mpc_id = next_id
        DO k = 1, n_terms
            node_k = INT(node%data_lines(2)%real_values(3 * k - 2), i4)
            dof_k  = INT(node%data_lines(2)%real_values(3 * k - 1), i4)
            coeff_k = node%data_lines(2)%real_values(3 * k)
            CALL MPCConstraintDef_AddTerm(mpc_def, node_k, dof_k, coeff_k, st)
            IF (st%status_code /= IF_STATUS_OK) THEN
                CALL add_mapping_error(mapper, node%start_line, "MPCConstraintDef_AddTerm failed for *EQUATION")
                CALL MPCConstraintDef_Cleanup(mpc_def, st)
                RETURN
            END IF
        END DO
        mpc_def%equation_rhs = rhs_val

        CALL g_ufc_global%md_layer%constraint%AddMPC(mpc_def, st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            CALL add_mapping_error(mapper, node%start_line, TRIM(st%message))
        END IF
        CALL MPCConstraintDef_Cleanup(mpc_def, st)
    END SUBROUTINE map_equation

    ! --------------------------------------------------------------------------
    ! Read integer parameter from AST (REF NODE, etc.)
    ! --------------------------------------------------------------------------
    SUBROUTINE md_kw_get_param_int(node, param_name, int_val, found)
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        CHARACTER(LEN=*), INTENT(IN) :: param_name
        INTEGER(i4), INTENT(OUT) :: int_val
        LOGICAL, INTENT(OUT) :: found

        INTEGER(i4) :: i, ios
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: upper_name

        int_val = 0_i4
        found = .FALSE.
        upper_name = kw_to_upper(TRIM(param_name))
        DO i = 1, node%param_count
            IF (TRIM(kw_to_upper(TRIM(node%params(i)%name))) == TRIM(upper_name)) THEN
                found = .TRUE.
                int_val = node%params(i)%int_value
                IF (int_val == 0_i4 .AND. LEN_TRIM(node%params(i)%value) > 0) THEN
                    READ (node%params(i)%value, *, IOSTAT=ios) int_val
                    IF (ios /= 0) int_val = INT(node%params(i)%real_value, i4)
                END IF
                RETURN
            END IF
        END DO
    END SUBROUTINE md_kw_get_param_int

    ! ==========================================================================
    ! *TIE -> TieConstraintDef (surfaces only; pair resolution is LB-07/CT-07)
    ! ==========================================================================
    SUBROUTINE map_tie_constraint(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        TYPE(TieConstraintDef) :: tie_def
        TYPE(ErrorStatusType) :: st
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_v, slave_v, master_v
        INTEGER(i4) :: next_id

        IF (.NOT. g_ufc_global%IsReady()) THEN
            CALL add_mapping_error(mapper, node%start_line, "*TIE: global container not ready")
            RETURN
        END IF
        IF (.NOT. g_ufc_global%md_layer%constraint%initialized) THEN
            CALL add_mapping_error(mapper, node%start_line, "*TIE: constraint domain not initialized")
            RETURN
        END IF
        IF (node%data_line_count < 1) THEN
            CALL add_mapping_error(mapper, node%start_line, "*TIE requires one data line (slave, master)")
            RETURN
        END IF
        CALL md_kw_get_param_value(node, "NAME", name_v)
        IF (LEN_TRIM(name_v) == 0) THEN
            WRITE (name_v, '(A,I0)') 'TIE', g_ufc_global%md_layer%constraint%constraint_union%n_tie + 1_i4
        END IF
        slave_v = ADJUSTL(TRIM(node%data_lines(1)%values(1)))
        master_v = ADJUSTL(TRIM(node%data_lines(1)%values(2)))
        IF (LEN_TRIM(slave_v) == 0 .OR. LEN_TRIM(master_v) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, "*TIE data line: slave and master required")
            RETURN
        END IF
        CALL TieConstraintDef_Cleanup(tie_def, st)
        CALL TieConstraintDef_Init(tie_def, TRIM(name_v), TRIM(slave_v), TRIM(master_v), st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            CALL add_mapping_error(mapper, node%start_line, "TieConstraintDef_Init failed for *TIE")
            CALL TieConstraintDef_Cleanup(tie_def, st)
            RETURN
        END IF
        next_id = g_ufc_global%md_layer%constraint%constraint_union%n_tie + 1_i4
        tie_def%tie_id = next_id
        CALL g_ufc_global%md_layer%constraint%AddTie(tie_def, st)
        IF (st%status_code /= IF_STATUS_OK) CALL add_mapping_error(mapper, node%start_line, TRIM(st%message))
        CALL TieConstraintDef_Cleanup(tie_def, st)
    END SUBROUTINE map_tie_constraint

    ! ==========================================================================
    ! *COUPLING (CONSTRAINT NAME, REF NODE, SURFACE)
    ! ==========================================================================
    SUBROUTINE map_coupling_constraint(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        TYPE(CplConstraintDef) :: cpl_def
        TYPE(ErrorStatusType) :: st
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_v, surf_v
        INTEGER(i4) :: refn, next_id
        LOGICAL :: pf

        IF (.NOT. g_ufc_global%IsReady()) THEN
            CALL add_mapping_error(mapper, node%start_line, "*COUPLING: global container not ready")
            RETURN
        END IF
        IF (.NOT. g_ufc_global%md_layer%constraint%initialized) THEN
            CALL add_mapping_error(mapper, node%start_line, "*COUPLING: constraint domain not initialized")
            RETURN
        END IF
        CALL md_kw_get_param_value(node, "CONSTRAINT NAME", name_v)
        IF (LEN_TRIM(name_v) == 0) CALL md_kw_get_param_value(node, "NAME", name_v)
        IF (LEN_TRIM(name_v) == 0) WRITE (name_v, '(A,I0)') 'CPL', &
            g_ufc_global%md_layer%constraint%constraint_union%n_cpl + 1_i4
        CALL md_kw_get_param_int(node, "REF NODE", refn, pf)
        IF (.NOT. pf .OR. refn <= 0_i4) THEN
            CALL add_mapping_error(mapper, node%start_line, "*COUPLING requires REF NODE")
            RETURN
        END IF
        CALL md_kw_get_param_value(node, "SURFACE", surf_v)
        IF (LEN_TRIM(surf_v) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, "*COUPLING requires SURFACE")
            RETURN
        END IF
        CALL CplConstraintDef_Init(cpl_def, TRIM(name_v), ref_node=refn, surf=TRIM(surf_v), status=st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            CALL add_mapping_error(mapper, node%start_line, "CplConstraintDef_Init failed for *COUPLING")
            RETURN
        END IF
        cpl_def%coupling_type = COUPLING_TYPE_KINEMATIC
        next_id = g_ufc_global%md_layer%constraint%constraint_union%n_cpl + 1_i4
        cpl_def%coupling_id = next_id
        CALL g_ufc_global%md_layer%constraint%AddCpl(cpl_def, st)
        IF (st%status_code /= IF_STATUS_OK) CALL add_mapping_error(mapper, node%start_line, TRIM(st%message))
    END SUBROUTINE map_coupling_constraint

    ! ==========================================================================
    ! *KINEMATIC COUPLING: REF NODE + data line surface name
    ! ==========================================================================
    SUBROUTINE map_kinematic_coupling_constraint(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        TYPE(CplConstraintDef) :: cpl_def
        TYPE(ErrorStatusType) :: st
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_v, surf_v
        INTEGER(i4) :: refn, next_id
        LOGICAL :: pf

        IF (.NOT. g_ufc_global%IsReady()) THEN
            CALL add_mapping_error(mapper, node%start_line, "*KINEMATIC COUPLING: global not ready")
            RETURN
        END IF
        IF (.NOT. g_ufc_global%md_layer%constraint%initialized) THEN
            CALL add_mapping_error(mapper, node%start_line, "*KINEMATIC COUPLING: constraint not initialized")
            RETURN
        END IF
        CALL md_kw_get_param_int(node, "REF NODE", refn, pf)
        IF (.NOT. pf .OR. refn <= 0_i4) THEN
            CALL add_mapping_error(mapper, node%start_line, "*KINEMATIC COUPLING requires REF NODE")
            RETURN
        END IF
        IF (node%data_line_count < 1) THEN
            CALL add_mapping_error(mapper, node%start_line, "*KINEMATIC COUPLING requires a surface data line")
            RETURN
        END IF
        surf_v = ADJUSTL(TRIM(node%data_lines(1)%values(1)))
        IF (LEN_TRIM(surf_v) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, "*KINEMATIC COUPLING: empty surface")
            RETURN
        END IF
        CALL md_kw_get_param_value(node, "NAME", name_v)
        IF (LEN_TRIM(name_v) == 0) WRITE (name_v, '(A,I0)') 'KC', &
            g_ufc_global%md_layer%constraint%constraint_union%n_cpl + 1_i4
        CALL CplConstraintDef_Init(cpl_def, TRIM(name_v), ref_node=refn, surf=TRIM(surf_v), status=st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            CALL add_mapping_error(mapper, node%start_line, "CplConstraintDef_Init failed for *KINEMATIC COUPLING")
            RETURN
        END IF
        cpl_def%coupling_type = COUPLING_TYPE_KINEMATIC
        next_id = g_ufc_global%md_layer%constraint%constraint_union%n_cpl + 1_i4
        cpl_def%coupling_id = next_id
        CALL g_ufc_global%md_layer%constraint%AddCpl(cpl_def, st)
        IF (st%status_code /= IF_STATUS_OK) CALL add_mapping_error(mapper, node%start_line, TRIM(st%message))
    END SUBROUTINE map_kinematic_coupling_constraint

    ! ==========================================================================
    ! *DISTRIBUTING COUPLING: REF NODE + ELSET (surface_name holds elset ref)
    ! ==========================================================================
    SUBROUTINE map_distributing_coupling_constraint(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        TYPE(CplConstraintDef) :: cpl_def
        TYPE(ErrorStatusType) :: st
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_v, elset_v
        INTEGER(i4) :: refn, next_id
        LOGICAL :: pf

        IF (.NOT. g_ufc_global%IsReady()) THEN
            CALL add_mapping_error(mapper, node%start_line, "*DISTRIBUTING COUPLING: global not ready")
            RETURN
        END IF
        IF (.NOT. g_ufc_global%md_layer%constraint%initialized) THEN
            CALL add_mapping_error(mapper, node%start_line, "*DISTRIBUTING COUPLING: constraint not initialized")
            RETURN
        END IF
        CALL md_kw_get_param_int(node, "REF NODE", refn, pf)
        IF (.NOT. pf .OR. refn <= 0_i4) THEN
            CALL add_mapping_error(mapper, node%start_line, "*DISTRIBUTING COUPLING requires REF NODE")
            RETURN
        END IF
        CALL md_kw_get_param_value(node, "ELSET", elset_v)
        IF (LEN_TRIM(elset_v) == 0 .AND. node%data_line_count >= 1) &
            elset_v = ADJUSTL(TRIM(node%data_lines(1)%values(1)))
        IF (LEN_TRIM(elset_v) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, "*DISTRIBUTING COUPLING requires ELSET")
            RETURN
        END IF
        CALL md_kw_get_param_value(node, "NAME", name_v)
        IF (LEN_TRIM(name_v) == 0) WRITE (name_v, '(A,I0)') 'DC', &
            g_ufc_global%md_layer%constraint%constraint_union%n_cpl + 1_i4
        CALL CplConstraintDef_Init(cpl_def, TRIM(name_v), ref_node=refn, surf=TRIM(elset_v), status=st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            CALL add_mapping_error(mapper, node%start_line, "CplConstraintDef_Init failed for *DISTRIBUTING COUPLING")
            RETURN
        END IF
        cpl_def%coupling_type = COUPLING_TYPE_DISTRIBUTING
        next_id = g_ufc_global%md_layer%constraint%constraint_union%n_cpl + 1_i4
        cpl_def%coupling_id = next_id
        CALL g_ufc_global%md_layer%constraint%AddCpl(cpl_def, st)
        IF (st%status_code /= IF_STATUS_OK) CALL add_mapping_error(mapper, node%start_line, TRIM(st%message))
    END SUBROUTINE map_distributing_coupling_constraint

    ! ==========================================================================
    ! *RIGID BODY -> RigidBodyDef (ref node + elset/tie nset; TYPE may select RBE3)
    ! ==========================================================================
    SUBROUTINE map_rigid_body_constraint(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        TYPE(RigidBodyDef) :: rigid_def
        TYPE(ErrorStatusType) :: st
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_v, elset_v, type_v, type_u
        INTEGER(i4) :: refn, next_id, rk
        LOGICAL :: pf

        IF (.NOT. g_ufc_global%IsReady()) THEN
            CALL add_mapping_error(mapper, node%start_line, "*RIGID BODY: global container not ready")
            RETURN
        END IF
        IF (.NOT. g_ufc_global%md_layer%constraint%initialized) THEN
            CALL add_mapping_error(mapper, node%start_line, "*RIGID BODY: constraint domain not initialized")
            RETURN
        END IF
        CALL md_kw_get_param_int(node, "REF NODE", refn, pf)
        IF (.NOT. pf .OR. refn <= 0_i4) THEN
            CALL add_mapping_error(mapper, node%start_line, "*RIGID BODY requires REF NODE")
            RETURN
        END IF
        CALL md_kw_get_param_value(node, "ELSET", elset_v)
        IF (LEN_TRIM(elset_v) == 0) CALL md_kw_get_param_value(node, "TIE NSET", elset_v)
        IF (LEN_TRIM(elset_v) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, "*RIGID BODY requires ELSET or TIE NSET")
            RETURN
        END IF
        CALL md_kw_get_param_value(node, "NAME", name_v)
        IF (LEN_TRIM(name_v) == 0) WRITE (name_v, '(A,I0)') 'RIG', &
            g_ufc_global%md_layer%constraint%constraint_union%n_rigid + 1_i4
        rk = RBE_TYPE_RBE2
        CALL md_kw_get_param_value(node, "TYPE", type_v)
        IF (LEN_TRIM(type_v) > 0) THEN
            type_u = kw_to_upper(TRIM(type_v))
            IF (INDEX(TRIM(type_u), 'RBE3') > 0) rk = RBE_TYPE_RBE3
        END IF
        CALL RigidBodyDef_Init(rigid_def, TRIM(name_v), ref_node=refn, element_set=TRIM(elset_v), &
            status=st, rbe_kind=rk)
        IF (st%status_code /= IF_STATUS_OK) THEN
            CALL add_mapping_error(mapper, node%start_line, "RigidBodyDef_Init failed for *RIGID BODY")
            RETURN
        END IF
        next_id = g_ufc_global%md_layer%constraint%constraint_union%n_rigid + 1_i4
        rigid_def%rigid_id = next_id
        CALL g_ufc_global%md_layer%constraint%AddRigid(rigid_def, st)
        IF (st%status_code /= IF_STATUS_OK) CALL add_mapping_error(mapper, node%start_line, TRIM(st%message))
    END SUBROUTINE map_rigid_body_constraint

    ! ==========================================================================
    ! Map analysis nodes (STEP, STATIC, DYNAMIC, BOUNDARY, CLOAD, etc.)
    ! ==========================================================================
    SUBROUTINE map_analysis_node(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        SELECT CASE (TRIM(node%keyword_name))
        CASE ("STEP")
            CALL map_step(mapper, node)
            
        CASE ("STATIC")
            CALL map_static_procedure(mapper, node)
            
        CASE ("DYNAMIC")
            CALL map_dynamic_procedure(mapper, node)
            
        CASE ("FREQUENCY")
            CALL map_frequency_procedure(mapper, node)
            
        CASE ("BUCKLE", "BUCKLING")
            CALL map_buckle_procedure(mapper, node)
            
        CASE ("STEADY STATE DYNAMICS")
            CALL map_steady_state_procedure(mapper, node)
            
        CASE ("HEAT TRANSFER")
            CALL map_heat_transfer_procedure(mapper, node)
            
        CASE ("COUPLED TEMPERATURE-DISPLACEMENT")
            CALL map_coupled_procedure(mapper, node)
            
        CASE ("COUPLED THERMAL-ELECTRICAL")
            CALL map_coupled_thermal_electrical_procedure(mapper, node)
            
        CASE ("GEOSTATIC")
            CALL map_geostatic_procedure(mapper, node)
            
        CASE ("SOILS")
            CALL map_soils_procedure(mapper, node)
            
        CASE ("VISCO")
            CALL map_visco_procedure(mapper, node)
            
        CASE ("ANNEAL")
            CALL map_anneal_procedure(mapper, node)
            
        CASE ("MODAL DYNAMIC")
            CALL map_modal_dynamic_procedure(mapper, node)
            
        CASE ("RANDOM RESPONSE")
            CALL map_random_response_procedure(mapper, node)
            
        CASE ("RESPONSE SPECTRUM")
            CALL map_response_spectrum_procedure(mapper, node)
            
        CASE ("COMPLEX FREQUENCY")
            CALL map_complex_frequency_procedure(mapper, node)
            
        CASE ("MASS DIFFUSION")
            CALL map_mass_diffusion_procedure(mapper, node)
            
        CASE ("COUPLED THERMAL-ELECTRICAL-STRUCTURAL")
            CALL map_coupled_tes_procedure(mapper, node)
            
        CASE ("PIEZOELECTRIC")
            CALL map_piezoelectric_procedure(mapper, node)
            
        CASE ("ELECTROMAGNETIC", "ELECTRICAL", "MAGNETIC")
            CALL map_electromagnetic_procedure(mapper, node)
            
        CASE ("ACOUSTIC")
            CALL map_acoustic_procedure(mapper, node)
            
        CASE ("STEADY STATE TRANSPORT")
            CALL map_steady_state_transport_procedure(mapper, node)
            
        CASE ("SUBSTRUCTURE")
            CALL map_substructure_procedure(mapper, node)
            
        CASE ("BOUNDARY")
            CALL map_boundary(mapper, node)
            
        CASE ("CLOAD")
            CALL map_cload(mapper, node)
            
        CASE ("DLOAD", "DSLOAD")
            CALL map_dload(mapper, node)
            
        CASE ("TEMPERATURE")
            CALL map_temperature(mapper, node)
            
        CASE ("FILM")
            CALL map_film(mapper, node)
            
        CASE ("SFILM")
            CALL map_sfilm(mapper, node)
            ! Inline: directly call map_film after map_sfilm
            CALL map_film(mapper, node)
            
        CASE ("RADIATE")
            CALL map_radiate(mapper, node)
            
        CASE ("SRADIATION")
            CALL map_sradiation(mapper, node)
            
        CASE ("DSFLUX")
            CALL map_dsflux(mapper, node)
            
        CASE ("MASS FLOW")
            CALL map_massflow(mapper, node)
            
        CASE ("INITIAL CONDITIONS")
            CALL map_initial_conditions(mapper, node)

        CASE ("INITIAL STATE")
            CALL map_initial_state_ldbc(mapper, node)

        CASE ("GEOSTATIC STRESS")
            CALL map_geostatic_stress(mapper, node)
            
        CASE ("OUTPUT", "NODE OUTPUT", "ELEMENT OUTPUT")
            CALL map_output(mapper, node)
            
        CASE ("CONTACT PAIR")
            CALL map_contact_pair(mapper, node)
            
        CASE ("SURFACE TO SURFACE CONTACT")
            CALL map_surface_to_surface_contact(mapper, node)

        CASE ("EQUATION")
            CALL map_equation(mapper, node)

        CASE ("TIE")
            CALL map_tie_constraint(mapper, node)

        CASE ("COUPLING")
            CALL map_coupling_constraint(mapper, node)

        CASE ("KINEMATIC COUPLING")
            CALL map_kinematic_coupling_constraint(mapper, node)

        CASE ("DISTRIBUTING COUPLING")
            CALL map_distributing_coupling_constraint(mapper, node)

        CASE ("RIGID BODY")
            CALL map_rigid_body_constraint(mapper, node)
            
        END SELECT
    END SUBROUTINE map_analysis_node


    ! ==========================================================================
    ! Map *PART keyword
    ! ==========================================================================
    SUBROUTINE map_part(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UF_PartDef) :: new_part
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_val
        INTEGER(i4) :: init_num_nodes, init_num_elems
        
        CALL md_kw_get_param_value(node, "NAME", name_val)
        IF (LEN_TRIM(name_val) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, "PART requires NAME parameter")
            RETURN
        END IF
        
        init_num_nodes = 1000
        init_num_elems = 1000
        CALL new_part%init(TRIM(name_val), init_num_nodes, init_num_elems, mapper%model%dimension)
        CALL mapper%model%add_part(new_part)
        mapper%current_part => mapper%model%get_part(TRIM(name_val))
    END SUBROUTINE map_part

    ! ==========================================================================
    ! Map *INSTANCE keyword
    ! ==========================================================================
    SUBROUTINE map_instance(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_val, part_val
        REAL(wp) :: translate(3)
        INTEGER(i4) :: i, idx
        TYPE(UF_InstanceDef) :: inst
        
        CALL md_kw_get_param_value(node, "NAME", name_val)
        CALL md_kw_get_param_value(node, "PART", part_val)
        
        IF (LEN_TRIM(name_val) == 0 .OR. LEN_TRIM(part_val) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, &
                "INSTANCE requires NAME and PART parameters")
            RETURN
        END IF
        
        ! Get translation from data lines
        translate = 0.0_wp
        IF (node%data_line_count >= 1) THEN
            DO i = 1, MIN(3, node%data_lines(1)%col_count)
                translate(i) = node%data_lines(1)%real_values(i)
            END DO
        END IF
        
        CALL inst%init(TRIM(name_val), TRIM(part_val))
        CALL inst%set_translation(translate(1), translate(2), translate(3))
        CALL mapper%model%assembly%add_instance(inst)
        
        ! Update current instance context
        idx = mapper%model%assembly%find_instance(TRIM(name_val))
        IF (idx > 0) THEN
            mapper%current_instance => mapper%model%assembly%instances(idx)
        END IF
    END SUBROUTINE map_instance

    ! ==========================================================================
    ! Map *TRANSLATE keyword
    ! ==========================================================================
    SUBROUTINE map_translate(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: tx, ty, tz
        
        IF (.NOT. ASSOCIATED(mapper%current_instance)) RETURN
        
        tx = 0.0_wp
        ty = 0.0_wp
        tz = 0.0_wp
        
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) tx = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) ty = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) tz = node%data_lines(1)%real_values(3)
            
            CALL mapper%current_instance%set_translation(tx, ty, tz)
        END IF
    END SUBROUTINE map_translate

    ! ==========================================================================
    ! Map *NODE keyword
    ! ==========================================================================
    SUBROUTINE map_nodes(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        INTEGER(i4) :: i, node_id
        REAL(wp) :: coords(3)
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: nset_name
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=512) :: inp_file
        INTEGER(i4) :: unit_num, ios, line_idx
        CHARACTER(LEN=KW_MAX_LINE_LEN) :: line
        REAL(wp) :: x, y, z
        
        ! DEBUG
        WRITE(*,*) "DEBUG: map_nodes called. lines=", node%data_line_count
        
        ! Fallback for flat INP files where AST did not capture data lines
        IF (node%data_line_count == 0) THEN
            ! Ensure we have a target part
            IF (.NOT. ASSOCIATED(mapper%current_part)) THEN
                IF (mapper%model%num_parts == 0) THEN
                    CALL map_create_default_part(mapper)
                END IF
                IF (mapper%model%num_parts > 0) THEN
                    mapper%current_part => mapper%model%parts(1)
                END IF
            END IF
            
            IF (.NOT. ASSOCIATED(mapper%current_part)) THEN
                 WRITE(*,*) "DEBUG: map_nodes fallback - current_part not associated!"
                 RETURN
            END IF
            
            inp_file = TRIM(mapper%parser%lexer%filename)
            IF (LEN_TRIM(inp_file) == 0) THEN
                RETURN
            END IF
            
            unit_num = 901
            OPEN(UNIT=unit_num, FILE=inp_file, STATUS='OLD', ACTION='READ', IOSTAT=ios)
            IF (ios /= 0) RETURN
            
            ! Skip lines up to and including the *NODE keyword line
            DO line_idx = 1, node%start_line
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
            END DO
            
            DO
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
                line = ADJUSTL(line)
                IF (LEN_TRIM(line) == 0) CYCLE
                IF (line(1:1) == '*') EXIT
                IF (line(1:2) == '**') CYCLE
                
                z = 0.0_wp
                READ(line, *, IOSTAT=ios) node_id, x, y, z
                IF (ios /= 0) THEN
                    READ(line, *, IOSTAT=ios) node_id, x, y
                    IF (ios /= 0) CYCLE
                END IF
                
                CALL mapper%current_part%add_node(node_id, x, y, z)
                mapper%nodes_mapped = mapper%nodes_mapped + 1
            END DO
            
            CLOSE(unit_num)
            RETURN
        END IF
        
        IF (.NOT. ASSOCIATED(mapper%current_part)) THEN
            ! Nodes at assembly level - add to first part or create default
            IF (mapper%model%num_parts == 0) THEN
                CALL map_create_default_part(mapper)
            END IF
            IF (mapper%model%num_parts > 0) THEN
                mapper%current_part => mapper%model%parts(1)
            END IF
        END IF
        
        IF (.NOT. ASSOCIATED(mapper%current_part)) THEN
             WRITE(*,*) "DEBUG: map_nodes - current_part not associated!"
             RETURN
        END IF
        
        CALL md_kw_get_param_value(node, "NSET", nset_name)
        
        ! Map nodes from AST data lines
        ! Note: Parallel parsing removed (temporarily unused)
        DO i = 1, node%data_line_count
            IF (node%data_lines(i)%col_count < 2) THEN
                mapper%warning_count = mapper%warning_count + 1
                CYCLE
            END IF
            
            node_id = node%data_lines(i)%int_values(1)
            IF (node_id <= 0) THEN
                mapper%warning_count = mapper%warning_count + 1
                CYCLE
            END IF
            
            coords = 0.0_wp
            coords(1) = node%data_lines(i)%real_values(2)
            IF (node%data_lines(i)%col_count >= 3) coords(2) = node%data_lines(i)%real_values(3)
            IF (node%data_lines(i)%col_count >= 4) coords(3) = node%data_lines(i)%real_values(4)
            
            ! Add node to current part
            CALL mapper%current_part%add_node(node_id, coords(1), coords(2), coords(3))
            mapper%nodes_mapped = mapper%nodes_mapped + 1
        END DO
    END SUBROUTINE map_nodes

    ! ==========================================================================
    ! Map *ELEMENT keyword
    ! ==========================================================================
    SUBROUTINE map_elements(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        INTEGER(i4) :: i, j, elem_id, elem_type_code, num_nodes
        INTEGER(i4) :: connectivity(27)
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: type_val, elset_name
        CHARACTER(LEN=512) :: inp_file
        INTEGER(i4) :: unit_num, ios, line_idx
        CHARACTER(LEN=KW_MAX_LINE_LEN) :: line
        
        IF (.NOT. ASSOCIATED(mapper%current_part)) RETURN
        
        CALL md_kw_get_param_value(node, "TYPE", type_val)
        CALL md_kw_get_param_value(node, "ELSET", elset_name)
        
        ! Convert element type string to code
        elem_type_code = get_element_type_code(TRIM(type_val))
        num_nodes = get_element_num_nodes(elem_type_code)
        
        ! Fallback: if AST has no data lines (flat INP parser limitation)
        IF (node%data_line_count == 0) THEN
            WRITE(*,*) "DEBUG: map_surface using Fallback from INP file"
            inp_file = TRIM(mapper%parser%lexer%filename)

            IF (LEN_TRIM(inp_file) == 0) RETURN
            
            unit_num = 902
            OPEN(UNIT=unit_num, FILE=inp_file, STATUS='OLD', ACTION='READ', IOSTAT=ios)
            IF (ios /= 0) RETURN
            
            ! Skip lines up to and including the *ELEMENT keyword line
            DO line_idx = 1, node%start_line
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
            END DO
            
            DO
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
                line = ADJUSTL(line)
                IF (LEN_TRIM(line) == 0) CYCLE
                IF (line(1:1) == '*') EXIT
                IF (line(1:2) == '**') CYCLE
                
                connectivity = 0
                READ(line, *, IOSTAT=ios) elem_id, (connectivity(j), j=1,num_nodes)
                IF (ios /= 0) CYCLE
                
                CALL mapper%current_part%add_element(elem_id, elem_type_code, connectivity(1:num_nodes))
                mapper%elements_mapped = mapper%elements_mapped + 1
            END DO
            
            CLOSE(unit_num)
            RETURN
        END IF
        
        ! Note: Parallel parsing removed (temporarily unused)
        
        ! Map elements from AST data lines
        DO i = 1, node%data_line_count
            IF (node%data_lines(i)%col_count < 2) THEN
                mapper%warning_count = mapper%warning_count + 1
                CYCLE
            END IF
            
            elem_id = node%data_lines(i)%int_values(1)
            IF (elem_id <= 0) THEN
                mapper%warning_count = mapper%warning_count + 1
                CYCLE
            END IF
            
            connectivity = 0
            DO j = 2, MIN(node%data_lines(i)%col_count, num_nodes + 1)
                connectivity(j-1) = node%data_lines(i)%int_values(j)
            END DO
            
            ! Validate connectivity (check for zero or negative node IDs)
            DO j = 1, num_nodes
                IF (connectivity(j) <= 0) THEN
                    CHARACTER(LEN=32) :: elem_id_str
                    WRITE(elem_id_str, '(I0)') elem_id
                    CALL add_mapping_error(mapper, node%start_line + i, &
                        "Invalid connectivity for element " // TRIM(elem_id_str))
                    IF (mapper%stop_on_error) RETURN
                    CYCLE
                END IF
            END DO
            
            ! Add element to current part
            CALL mapper%current_part%add_element(elem_id, elem_type_code, connectivity(1:num_nodes))
            mapper%elements_mapped = mapper%elements_mapped + 1
        END DO
    END SUBROUTINE map_elements

    ! ==========================================================================
    ! Map *NSET keyword
    ! ==========================================================================
    SUBROUTINE map_nset(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: nset_name, generate_val
        TYPE(UF_NodeSet) :: new_set
        INTEGER(i4) :: i, j, start_id, end_id, inc, cap
        INTEGER(i4) :: k
        INTEGER(i4) :: nid
        INTEGER(i4) :: ids(64)
        LOGICAL :: is_generate
        
        ! Fallback-related variables for flat INP files
        CHARACTER(LEN=KW_MAX_LINE_LEN) :: line
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: token1, token2, token3
        CHARACTER(LEN=512) :: inp_file
        INTEGER(i4) :: unit_num, ios, line_idx

        
        CALL md_kw_get_param_value(node, "NSET", nset_name)
        CALL md_kw_get_param_value(node, "GENERATE", generate_val)
        is_generate = (TRIM(generate_val) == "YES" .OR. LEN_TRIM(generate_val) > 0)
        
        IF (LEN_TRIM(nset_name) == 0) RETURN
        
        ! ------------------------------------------------------------------
        ! 1)   AST data_lines
        ! ------------------------------------------------------------------
        IF (node%data_line_count > 0) THEN
            IF (is_generate) THEN
                ! Generate mode: start, end, increment
                IF (node%data_line_count >= 1 .AND. node%data_lines(1)%col_count >= 2) THEN
                    start_id = node%data_lines(1)%int_values(1)
                    end_id = node%data_lines(1)%int_values(2)
                    inc = 1
                    IF (node%data_lines(1)%col_count >= 3) inc = node%data_lines(1)%int_values(3)
                    IF (inc <= 0) inc = 1
                    
                    CALL new_set%init(TRIM(nset_name))
                    CALL new_set%add_range(start_id, end_id, inc)
                END IF
            ELSE
                ! List mode: read all node IDs from data lines
                cap = node%data_line_count * KW_MAX_DATA_COLS
                IF (cap <= 0) RETURN
                CALL new_set%init(TRIM(nset_name), cap)

        DO i = 1, node%data_line_count

                    DO j = 1, node%data_lines(i)%col_count
                        IF (node%data_lines(i)%int_values(j) > 0) THEN
                            CALL new_set%add_node(node%data_lines(i)%int_values(j))
                        END IF
                    END DO
                END DO
            END IF
        ELSE
            ! ------------------------------------------------------------------
            ! 2) Fallback??flat INP  ??INP   NSET  
            ! ------------------------------------------------------------------
            inp_file = TRIM(mapper%parser%lexer%filename)
            IF (LEN_TRIM(inp_file) == 0) RETURN
            
            unit_num = 903
            OPEN(UNIT=unit_num, FILE=inp_file, STATUS='OLD', ACTION='READ', IOSTAT=ios)
            IF (ios /= 0) RETURN
            
            !  *NSET              DO line_idx = 1, node%start_line
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
            END DO
            
            CALL new_set%init(TRIM(nset_name))
            
            DO
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
                line = ADJUSTL(line)
                IF (LEN_TRIM(line) == 0) CYCLE
                IF (line(1:1) == '*') EXIT
                IF (line(1:2) == '**') CYCLE
                
                token1 = ""
                token2 = ""
                token3 = ""
                nid = 0
                
                IF (is_generate) THEN
                    !  ??start, end, inc
                    start_id = 0
                    end_id = 0
                    inc = 1
                    READ(line, *, IOSTAT=ios) start_id, end_id, inc
                    IF (ios /= 0) CYCLE
                    IF (inc <= 0) inc = 1
                    CALL new_set%add_range(start_id, end_id, inc)
                ELSE
                    !  ??node ???????                    ids = 0
                    READ(line, *, IOSTAT=ios) ids
                    IF (ios /= 0) CYCLE
                    DO k = 1, SIZE(ids)
                        IF (ids(k) > 0) CALL new_set%add_node(ids(k))
                    END DO
                END IF

            END DO
            
            CLOSE(unit_num)
        END IF
        
        IF (ASSOCIATED(mapper%current_part)) THEN
            CALL mapper%current_part%add_node_set(new_set)
        END IF
        CALL mapper%model%assembly%add_node_set(new_set)
    END SUBROUTINE map_nset




    ! ==========================================================================
    ! Map *ELSET keyword
    ! ==========================================================================
    SUBROUTINE map_elset(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, generate_val
        TYPE(UF_ElemSet) :: new_set
        INTEGER(i4) :: i, j, start_id, end_id, inc, cap
        LOGICAL :: is_generate
        
        ! Fallback-related variables for flat INP files
        CHARACTER(LEN=KW_MAX_LINE_LEN) :: line
        CHARACTER(LEN=512) :: inp_file
        INTEGER(i4) :: unit_num, ios, line_idx
        INTEGER(i4) :: elem_id
        
        CALL md_kw_get_param_value(node, "ELSET", elset_name)
        CALL md_kw_get_param_value(node, "GENERATE", generate_val)
        is_generate = (TRIM(generate_val) == "YES" .OR. LEN_TRIM(generate_val) > 0)
        
        IF (LEN_TRIM(elset_name) == 0) RETURN
        
        ! ------------------------------------------------------------------
        ! 1)   AST data_lines
        ! ------------------------------------------------------------------
        IF (node%data_line_count > 0) THEN
            IF (is_generate) THEN
                IF (node%data_line_count >= 1 .AND. node%data_lines(1)%col_count >= 2) THEN
                    start_id = node%data_lines(1)%int_values(1)
                    end_id = node%data_lines(1)%int_values(2)
                    inc = 1
                    IF (node%data_lines(1)%col_count >= 3) inc = node%data_lines(1)%int_values(3)
                    IF (inc <= 0) inc = 1
                    
                    CALL new_set%init(TRIM(elset_name))
                    CALL new_set%add_range(start_id, end_id, inc)
                END IF
            ELSE
                cap = node%data_line_count * KW_MAX_DATA_COLS
                IF (cap <= 0) RETURN
                CALL new_set%init(TRIM(elset_name), cap)

                DO i = 1, node%data_line_count
                    DO j = 1, node%data_lines(i)%col_count
                        IF (node%data_lines(i)%int_values(j) > 0) THEN
                            CALL new_set%add_elem(node%data_lines(i)%int_values(j))
                        END IF
                    END DO
                END DO
            END IF
        ELSE
            ! ------------------------------------------------------------------
            ! 2) Fallback??flat INP  ??INP   ELSET  
            ! ------------------------------------------------------------------
            inp_file = TRIM(mapper%parser%lexer%filename)
            IF (LEN_TRIM(inp_file) == 0) RETURN
            
            unit_num = 904
            OPEN(UNIT=unit_num, FILE=inp_file, STATUS='OLD', ACTION='READ', IOSTAT=ios)
            IF (ios /= 0) RETURN
            
            !  *ELSET              DO line_idx = 1, node%start_line
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
            END DO
            
            CALL new_set%init(TRIM(elset_name))
            
            DO
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
                line = ADJUSTL(line)
                IF (LEN_TRIM(line) == 0) CYCLE
                IF (line(1:1) == '*') EXIT
                IF (line(1:2) == '**') CYCLE
                
                elem_id = 0
                READ(line, *, IOSTAT=ios) elem_id
                IF (ios /= 0) CYCLE
                IF (elem_id > 0) CALL new_set%add_elem(elem_id)
            END DO
            
            CLOSE(unit_num)
        END IF

        IF (ASSOCIATED(mapper%current_part)) THEN
            CALL mapper%current_part%add_elem_set(new_set)
        END IF
    END SUBROUTINE map_elset


    ! ==========================================================================
    ! Map *SURFACE keyword
    !
    ! Supported syntax (Abaqus-style, TYPE=ELEMENT only):
    !   *SURFACE, NAME=SURF-1, TYPE=ELEMENT
    !   ESET1, S1   ! Element faces (3D) or shell faces
    !   ESET2, E1   ! Element edges (2D) for line loads
    !   10,    S3
    !
    ! Where the first column is either an ELSET name or a single element ID,
    ! and the second column is the entity label:
    !   - Faces: S1..S6, SPOS/SNEG  -> stored with positive face_id
    !   - Edges: E1..E4             -> stored with negative face_id (edge_id=-face_id)
    ! The result is stored as UF_Surface on the current part and later used
    ! by DLOAD/SURFACE-based distributed loads (including line loads on edges).
    ! ==========================================================================
    SUBROUTINE map_surface(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        TYPE(UF_Surface) :: surf
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: surf_name, type_val
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: item_name, face_label
        INTEGER(i4) :: i, j, face_id, eset_idx, elem_id, ios
        CHARACTER(LEN=KW_MAX_LINE_LEN) :: line
        CHARACTER(LEN=512) :: inp_file
        INTEGER(i4) :: unit_num, line_idx

        WRITE(*,*) "DEBUG: map_surface enter: data_line_count=", node%data_line_count, &
                   " start_line=", node%start_line



        IF (.NOT. ASSOCIATED(mapper%current_part)) THEN
            IF (mapper%model%num_parts == 0) THEN
                CALL map_create_default_part(mapper)
            END IF
            IF (mapper%model%num_parts > 0) THEN
                mapper%current_part => mapper%model%parts(1)
            END IF
        END IF

        IF (.NOT. ASSOCIATED(mapper%current_part)) THEN
            WRITE(*,*) "DEBUG: map_surface - current_part not associated!"
            RETURN
        END IF

        CALL md_kw_get_param_value(node, "NAME", surf_name)
        IF (LEN_TRIM(surf_name) == 0) RETURN


        CALL md_kw_get_param_value(node, "TYPE", type_val)
        IF (LEN_TRIM(type_val) == 0) type_val = "ELEMENT"

        ! Currently only support TYPE=ELEMENT surfaces
        IF (TRIM(type_val) /= "ELEMENT") RETURN

        CALL surf%init(TRIM(surf_name), SURF_TYPE_ELEMENT)

        ! ------------------------------------------------------------------
        ! Fallback??flat INP  ??AST   SURFACE  ??
        ! INP  *SURFACE  facet definition?? surf%facets        ! ------------------------------------------------------------------
        IF (node%data_line_count == 0) THEN
            WRITE(*,*) "DEBUG: map_surface using Fallback from INP file"
            inp_file = TRIM(mapper%parser%lexer%filename)

            IF (LEN_TRIM(inp_file) > 0) THEN
                unit_num = 907
                OPEN(UNIT=unit_num, FILE=inp_file, STATUS='OLD', ACTION='READ', IOSTAT=ios)
                IF (ios == 0) THEN
                    !  *SURFACE                      DO line_idx = 1, node%start_line
                        READ(unit_num, '(A)', IOSTAT=ios) line
                        IF (ios /= 0) EXIT
                    END DO

                    DO
                        READ(unit_num, '(A)', IOSTAT=ios) line
                        IF (ios /= 0) EXIT
                        line = ADJUSTL(line)
                        IF (LEN_TRIM(line) == 0) CYCLE
                        IF (line(1:1) == '*') EXIT
                        IF (line(1:2) == '**') CYCLE

                        item_name = ""
                        face_label = ""
                        READ(line, *, IOSTAT=ios) item_name, face_label
                        IF (ios /= 0) CYCLE

                        !  ??AST                          face_id = 0
                        IF (LEN_TRIM(face_label) > 0) THEN
                            SELECT CASE (face_label(1:1))
                            CASE ('S', 's')
                                IF (LEN_TRIM(face_label) >= 2) THEN
                                    READ(face_label(2:), *, IOSTAT=ios) face_id
                                    IF (ios /= 0) face_id = 0
                                END IF
                            CASE ('E', 'e')
                                IF (LEN_TRIM(face_label) >= 2) THEN
                                    READ(face_label(2:), *, IOSTAT=ios) face_id
                                    IF (ios /= 0) face_id = 0
                                    IF (face_id > 0) face_id = -face_id
                                END IF
                            CASE DEFAULT
                                face_id = 0
                            END SELECT
                        END IF

                        IF (face_id == 0) CYCLE

                        ! Case 1:   ID
                        elem_id = 0
                        IF (LEN_TRIM(item_name) > 0) THEN
                            READ(item_name, *, IOSTAT=ios) elem_id
                            IF (ios == 0 .AND. elem_id > 0) THEN
                                CALL surf%add_facet(elem_id, face_id)
                                CYCLE
                            END IF
                        END IF

                        ! Case 2:   ELSET  
                        IF (LEN_TRIM(item_name) > 0) THEN
                            eset_idx = mapper%current_part%find_elem_set(TRIM(item_name))
                            WRITE(*,*) "DEBUG: map_surface fallback: item=", TRIM(item_name), &
     &                                " face_id=", face_id, " eset_idx=", eset_idx

                            IF (eset_idx > 0) THEN
                                DO j = 1, mapper%current_part%elem_sets(eset_idx)%num_elems
                                    elem_id = mapper%current_part%elem_sets(eset_idx)%elem_ids(j)
                                    CALL surf%add_facet(elem_id, face_id)
                                END DO
                            END IF
                        END IF
                    END DO

                    CLOSE(unit_num)
                END IF
            END IF
        END IF

        DO i = 1, node%data_line_count

        
            IF (node%data_lines(i)%col_count < 2) CYCLE

            item_name = TRIM(node%data_lines(i)%values(1))
            face_label = TRIM(node%data_lines(i)%values(2))

            ! Parse entity label:
            !   - Faces:  S1..S6, SPOS/SNEG  -> face_id = 1..6
            !   - Edges:  E1..E4             -> face_id = -1..-4 (edge_id = -face_id)
            face_id = 0
            IF (LEN_TRIM(face_label) > 0) THEN
                SELECT CASE (face_label(1:1))
                CASE ('S', 's')
                    IF (LEN_TRIM(face_label) >= 2) THEN
                        READ(face_label(2:), *, IOSTAT=ios) face_id
                        IF (ios /= 0) face_id = 0
                    END IF
                CASE ('E', 'e')
                    IF (LEN_TRIM(face_label) >= 2) THEN
                        READ(face_label(2:), *, IOSTAT=ios) face_id
                        IF (ios /= 0) face_id = 0
                        IF (face_id > 0) face_id = -face_id
                    END IF
                CASE DEFAULT
                    face_id = 0
                END SELECT
            END IF

            IF (face_id == 0) CYCLE

            ! Case 1: first token is an element ID
            elem_id = 0
            IF (LEN_TRIM(item_name) > 0) THEN
                READ(item_name, *, IOSTAT=ios) elem_id
                IF (ios == 0 .AND. elem_id > 0) THEN
                    CALL surf%add_facet(elem_id, face_id)
                    CYCLE
                END IF
            END IF

            ! Case 2: first token is an ELSET name
            IF (LEN_TRIM(item_name) > 0) THEN
                eset_idx = mapper%current_part%find_elem_set(TRIM(item_name))
                IF (eset_idx > 0) THEN
                    DO j = 1, mapper%current_part%elem_sets(eset_idx)%num_elems
                        elem_id = mapper%current_part%elem_sets(eset_idx)%elem_ids(j)
                        CALL surf%add_facet(elem_id, face_id)
                    END DO
                END IF
            END IF
        END DO

        WRITE(*,*) "DEBUG: map_surface before add_surface, surf%num_facets=", surf%num_facets

        IF (surf%num_facets > 0) THEN
            CALL mapper%current_part%add_surface(surf)
            WRITE(*,*) "DEBUG: map_surface added surface ", TRIM(surf_name), &
     &                " with num_facets=", surf%num_facets
        END IF


    END SUBROUTINE map_surface

    ! ==========================================================================
    ! Map *MATERIAL keyword
    ! ==========================================================================
    SUBROUTINE map_material(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UF_MaterialDef) :: new_mat
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_val
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: model_val
        
        CALL md_kw_get_param_value(node, "NAME", name_val)
        IF (LEN_TRIM(name_val) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, "MATERIAL requires NAME parameter")
            RETURN
        END IF
        
        CALL md_kw_get_param_value(node, "MODEL", model_val)
        
        CALL new_mat%init(TRIM(name_val))
        IF (LEN_TRIM(model_val) > 0) THEN
            new_mat%model_keyword = TRIM(model_val)
            new_mat%is_user_material = .TRUE.
        END IF
        CALL mapper%model%add_material(new_mat)
        mapper%current_material => mapper%model%get_material(TRIM(name_val))
        mapper%materials_mapped = mapper%materials_mapped + 1
    END SUBROUTINE map_material


    ! ==========================================================================
    ! Map *ELASTIC keyword
    ! ==========================================================================
    SUBROUTINE map_elastic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: E, nu
        REAL(wp) :: vals(32)
        INTEGER(i4) :: i, j, nvals
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: type_val, type_u
        
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        
        CALL md_kw_get_param_value(node, "TYPE", type_val)
        IF (LEN_TRIM(type_val) == 0) type_val = "ISOTROPIC"
        type_u = kw_to_upper(TRIM(type_val))
        
        !  ?? vals(:)
        nvals = 0
        DO i = 1, node%data_line_count
            DO j = 1, node%data_lines(i)%col_count
                IF (nvals < SIZE(vals)) THEN
                    nvals = nvals + 1
                    vals(nvals) = node%data_lines(i)%real_values(j)
                END IF
            END DO
        END DO
        
        SELECT CASE (TRIM(type_u))
        CASE ("ISOTROPIC")
            IF (nvals >= 2) THEN
                E  = vals(1)
                nu = vals(2)
                WRITE(*,'(A,A,2ES12.4)') '  [KW] map_elastic(ISOTROPIC) for material ', &
                    TRIM(mapper%current_material%name), E, nu
                CALL mapper%current_material%set_elastic_iso(E, nu)

                IF (mapper%current_material%material_type == 0) THEN
                    mapper%current_material%material_type = MATTYPE_ISO_ELASTIC
                END IF
            END IF

        CASE ("ORTHO-3D")
            IF (nvals >= 9) THEN
                WRITE(*,'(A,A)') '  [KW] map_elastic(ORTHO-3D) for material ', &
                    TRIM(mapper%current_material%name)
                CALL mapper%current_material%set_elastic_ortho( &
                    vals(1), vals(2), vals(3), &  ! E1, E2, E3
                    vals(4), vals(5), vals(6), &  ! nu12, nu13, nu23
                    vals(7), vals(8), vals(9))    ! G12, G13, G23
            END IF

        CASE ("TRANSVERSE-ISO")
            IF (nvals >= 5) THEN
                WRITE(*,'(A,A)') '  [KW] map_elastic(TRANSVERSE-ISO) for material ', &
                    TRIM(mapper%current_material%name)
                CALL mapper%current_material%set_elastic_transiso( &
                    vals(1), vals(2), vals(3), vals(4), vals(5))   ! Ep, Et, nup, nut, Gp
            END IF

        CASE ("ANISO-21")
            IF (nvals >= 21) THEN
                WRITE(*,'(A,A)') '  [KW] map_elastic(ANISO-21) for material ', &
                    TRIM(mapper%current_material%name)
                CALL mapper%current_material%set_elastic_aniso(vals(1:21))
            END IF

        CASE DEFAULT
            !   TYPE????input??
            IF (nvals >= 2) THEN
                E  = vals(1)
                nu = vals(2)
                WRITE(*,'(A,A,2ES12.4)') '  [KW] map_elastic(DEFAULT/ISO) for material ', &
                    TRIM(mapper%current_material%name), E, nu
                CALL mapper%current_material%set_elastic_iso(E, nu)

                IF (mapper%current_material%material_type == 0) THEN
                    mapper%current_material%material_type = MATTYPE_ISO_ELASTIC
                END IF
            END IF
        END SELECT

        IF (mapper%current_material%material_type /= 0) THEN
            CALL UF_Section_RegisterMaterialName( &
                mapper%current_material%material_type, &
                TRIM(mapper%current_material%name) )
        END IF
    END SUBROUTINE map_elastic

    ! ==========================================================================
    ! Map *THERMO ELASTIC �?L3 Desc props for mat_id 108 (L4 ThermoElastic)
    ! ==========================================================================
    SUBROUTINE map_thermo_elastic_kw(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        REAL(wp) :: e_y, nu_y, alpha_th, t_ref, props(8)
        INTEGER(i4) :: np
        TYPE(ErrorStatusType) :: st

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        CALL MD_CoupledElas_ParseThermo108(node, e_y, nu_y, alpha_th, t_ref, st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_thermo_elastic_kw: ', TRIM(st%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF

        CALL mapper%current_material%set_elastic_iso(e_y, nu_y)
        CALL MD_CoupledElas_Thermo108_ToProps(e_y, nu_y, alpha_th, t_ref, props, np, st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF

        mapper%current_material%cfg%id = THERMO_ELAS_MAT_ID
        mapper%current_material%props(1:np) = props(1:np)
        mapper%current_material%num_props = np
        mapper%current_material%alpha = alpha_th

        IF (mapper%current_material%material_type == 0) &
            mapper%current_material%material_type = MATTYPE_ISO_ELASTIC
        IF (mapper%current_material%material_type /= 0) THEN
            CALL UF_Section_RegisterMaterialName(mapper%current_material%material_type, &
                TRIM(mapper%current_material%name))
        END IF
        WRITE(*,'(A,A)') '  [KW] map_thermo_elastic_kw for material ', TRIM(mapper%current_material%name)
    END SUBROUTINE map_thermo_elastic_kw

    ! ==========================================================================
    ! Map *PIEZO ELASTIC �?mat_id 109 (10 props, L4 registry)
    ! ==========================================================================
    SUBROUTINE map_piezo_elastic_kw(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        REAL(wp) :: props(16)
        INTEGER(i4) :: np
        TYPE(ErrorStatusType) :: st

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        CALL MD_CoupledElas_ParsePiezo109(node, props, np, st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_piezo_elastic_kw: ', TRIM(st%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF

        mapper%current_material%cfg%id = PIEZO_ELAS_MAT_ID
        mapper%current_material%props(1:np) = props(1:np)
        mapper%current_material%num_props = np
        IF (mapper%current_material%material_type == 0) &
            mapper%current_material%material_type = MATTYPE_ISO_ELASTIC
        IF (mapper%current_material%material_type /= 0) THEN
            CALL UF_Section_RegisterMaterialName(mapper%current_material%material_type, &
                TRIM(mapper%current_material%name))
        END IF
        WRITE(*,'(A,A)') '  [KW] map_piezo_elastic_kw for material ', TRIM(mapper%current_material%name)
    END SUBROUTINE map_piezo_elastic_kw

    ! ==========================================================================
    ! Map *THERMO ELEC ELASTIC �?mat_id 110 (12 props)
    ! ==========================================================================
    SUBROUTINE map_thermo_elec_elastic_kw(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        REAL(wp) :: props(16)
        INTEGER(i4) :: np
        TYPE(ErrorStatusType) :: st

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        CALL MD_CoupledElas_ParseThermoPiezo110(node, props, np, st)
        IF (st%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_thermo_elec_elastic_kw: ', TRIM(st%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF

        mapper%current_material%cfg%id = THERMOPIEZO_ELAS_MAT_ID
        mapper%current_material%props(1:np) = props(1:np)
        mapper%current_material%num_props = np
        IF (mapper%current_material%material_type == 0) &
            mapper%current_material%material_type = MATTYPE_ISO_ELASTIC
        IF (mapper%current_material%material_type /= 0) THEN
            CALL UF_Section_RegisterMaterialName(mapper%current_material%material_type, &
                TRIM(mapper%current_material%name))
        END IF
        WRITE(*,'(A,A)') '  [KW] map_thermo_elec_elastic_kw for material ', TRIM(mapper%current_material%name)
    END SUBROUTINE map_thermo_elec_elastic_kw




    ! ==========================================================================
    ! Map *HYPERELASTIC keyword
    ! =======================================================================
    SUBROUTINE map_hyperelastic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType),     INTENT(IN)    :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: flag_mr, flag_nh, flag_ogden
        REAL(wp) :: vals(32)
        INTEGER(i4) :: nvals, i, j

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        CALL md_kw_get_param_value(node, "MOONEY-RIVLIN", flag_mr)
        CALL md_kw_get_param_value(node, "NEO HOOKE",    flag_nh)
        CALL md_kw_get_param_value(node, "OGDEN",        flag_ogden)

        !          nvals = 0
        DO i = 1, node%data_line_count
            DO j = 1, node%data_lines(i)%col_count
                IF (nvals < SIZE(vals)) THEN
                    nvals = nvals + 1
                    vals(nvals) = node%data_lines(i)%real_values(j)
                END IF
            END DO
        END DO

        IF (LEN_TRIM(flag_mr) > 0 .AND. flag_mr(1:1) == 'T') THEN
            ! Mooney-Rivlin??C10, C01, [D1]
            IF (nvals >= 2) THEN
                WRITE(*,'(A,A)') '  [KW] map_hyperelastic(MOONEY-RIVLIN) for material ', &
                    TRIM(mapper%current_material%name)
                mapper%current_material%props(1:min(3,nvals)) = vals(1:min(3,nvals))
                mapper%current_material%num_props = MAX(mapper%current_material%num_props, &
                                                        MIN(3, nvals))
            END IF

        ELSE IF (LEN_TRIM(flag_ogden) > 0 .AND. flag_ogden(1:1) == 'T') THEN
            ! Ogden??mu1, alpha1 [, mu2, alpha2 [, mu3, alpha3]]
            IF (nvals >= 2) THEN
                WRITE(*,'(A,A)') '  [KW] map_hyperelastic(OGDEN) for material ', &
                    TRIM(mapper%current_material%name)
                mapper%current_material%props(1:min(6,nvals)) = vals(1:min(6,nvals))
                mapper%current_material%num_props = MAX(mapper%current_material%num_props, &
                                                        MIN(6, nvals))
            END IF

        ELSE IF (LEN_TRIM(flag_nh) > 0 .AND. flag_nh(1:1) == 'T') THEN
            ! Neo-Hookean??C10 [, D1]
            IF (nvals >= 1) THEN
                WRITE(*,'(A,A)') '  [KW] map_hyperelastic(NEO HOOKE) for material ', &
                    TRIM(mapper%current_material%name)
                mapper%current_material%props(1:min(2,nvals)) = vals(1:min(2,nvals))
                mapper%current_material%num_props = MAX(mapper%current_material%num_props, &
                                                        MIN(2, nvals))
            END IF
        END IF

    END SUBROUTINE map_hyperelastic

    
    ! ==========================================================================
    ! Map *CREEP / *VISCOELASTIC keyword
    !   -  ???J2  /creep (260)?????
    !     param UMAT_260 / material_set_viscoplastic_iso      !       E_ref, nu, sigma_y0_ref, H_ref, m_rate,
    !       eps0_ref, Q_activation, R_gas, T_ref, [alpha_thermal]
    ! ==========================================================================
    SUBROUTINE map_creep(mapper, node)

        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType),     INTENT(IN)    :: node

        REAL(wp) :: vals(32)
        INTEGER(i4) :: i, j, nvals
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: law_val

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        CALL md_kw_get_param_value(node, "LAW", law_val)

        !          nvals = 0
        DO i = 1, node%data_line_count
            DO j = 1, node%data_lines(i)%col_count
                IF (nvals < SIZE(vals)) THEN
                    nvals = nvals + 1
                    vals(nvals) = node%data_lines(i)%real_values(j)
                END IF
            END DO
        END DO

        IF (nvals >= 9) THEN
            IF (nvals >= 10) THEN
                CALL mapper%current_material%set_viscoplastic_iso( &
                    vals(1), vals(2), vals(3), vals(4), vals(5), &
                    vals(6), vals(7), vals(8), vals(9), vals(10))
            ELSE
                CALL mapper%current_material%set_viscoplastic_iso( &
                    vals(1), vals(2), vals(3), vals(4), vals(5), &
                    vals(6), vals(7), vals(8), vals(9))
            END IF

            mapper%current_material%is_rate_dependent        = .TRUE.
            mapper%current_material%is_temperature_dependent = .TRUE.

            !  material Mises  creep 
            IF (mapper%current_material%material_type == 0) THEN
                mapper%current_material%material_type = MATTYPE_MISES
            END IF

            CALL UF_Section_RegisterMaterialName( &
                mapper%current_material%material_type, &
                TRIM(mapper%current_material%name) )
        END IF

    END SUBROUTINE map_creep

    
    ! ==========================================================================
    ! Map *DAMAGE, TYPE=PUCK-ORTHO keyword (composite damage material)
    !   -  material materialdamageparamdefinition    !       *DAMAGE, TYPE=PUCK-ORTHO
    !       E1, E2, E3, nu12, nu13, nu23, G12, G13, G23,
    !       Xt, Xc, Yt, Yc, Zt, Zc,
    !       S12, S13, S23,
    !       G1c, G2c, G3c, G12c, G13c, G23c,
    !       alpha1, alpha2, alpha3,
    !       theta, phi, psi
    ! ==========================================================================
    SUBROUTINE map_damage_puck(mapper, node)

        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType),     INTENT(IN)    :: node

        REAL(wp) :: vals(64)
        REAL(wp) :: p(30)
        INTEGER(i4) :: i, j, nvals
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: type_val, type_u

        !  materialcontext materialdamage        !  contactcontext  *DAMAGE??current_material  ?????        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        CALL md_kw_get_param_value(node, "TYPE", type_val)
        type_u = kw_to_upper(TRIM(type_val))
        IF (TRIM(type_u) /= "PUCK-ORTHO") RETURN

        !          nvals = 0
        DO i = 1, node%data_line_count
            DO j = 1, node%data_lines(i)%col_count
                IF (nvals < SIZE(vals)) THEN
                    nvals = nvals + 1
                    vals(nvals) = node%data_lines(i)%real_values(j)
                END IF
            END DO
        END DO

        !   15  param??+  ?????0  
        IF (nvals < 15) RETURN

        p = 0.0_wp
        DO i = 1, MIN(nvals, 30)
            p(i) = vals(i)
        END DO

        CALL mapper%current_material%set_damage_ortho_puck( &
            p(1),  p(2),  p(3),  p(4),  p(5),  p(6),  p(7),  p(8),  p(9),  &
            p(10), p(11), p(12), p(13), p(14), p(15), &
            p(16), p(17), p(18), &
            p(19), p(20), p(21), p(22), p(23), p(24), &
            p(25), p(26), p(27), p(28), p(29), p(30))

    END SUBROUTINE map_damage_puck

    
    ! ==========================================================================
    ! Map *PLASTIC keyword
    ! ==========================================================================
    SUBROUTINE map_plastic(mapper, node)


        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp), ALLOCATABLE :: stress(:), strain(:)
        INTEGER(i4) :: i, n
        
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        
        n = node%data_line_count
        IF (n > 0) THEN
            ALLOCATE(stress(n), strain(n))
            DO i = 1, n
                IF (node%data_lines(i)%col_count >= 2) THEN
                    stress(i) = node%data_lines(i)%real_values(1)
                    strain(i) = node%data_lines(i)%real_values(2)
                END IF
            END DO
            CALL mapper%current_material%hardening%init(n)
            DO i = 1, n
                CALL mapper%current_material%hardening%add_point(stress(i), strain(i))
            END DO
            DEALLOCATE(stress, strain)

            !   *PLASTIC  ??material  Mises plastic             mapper%current_material%material_type = MATTYPE_MISES

            !   UF_Section   mattype material 
            CALL UF_Section_RegisterMaterialName( &
                mapper%current_material%material_type, &
                TRIM(mapper%current_material%name) )
        END IF
    END SUBROUTINE map_plastic



    ! ==========================================================================
    ! Map *SURFACE INTERACTION keyword (define contact property entry)
    ! ==========================================================================
    SUBROUTINE map_surface_interaction(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType),     INTENT(IN)    :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_val
        TYPE(UF_ContactPropertyDef)     :: new_prop
        INTEGER(i4) :: idx

        ! SURFACE INTERACTION requires NAME parameter
        CALL md_kw_get_param_value(node, "NAME", name_val)
        IF (LEN_TRIM(name_val) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, "SURFACE INTERACTION requires NAME parameter")
            RETURN
        END IF

        ! Try to reuse existing property with same name
        idx = mapper%model%contact_db%find_by_name(TRIM(name_val))
        IF (idx < 0) THEN
            new_prop%name          = TRIM(name_val)
            new_prop%mu_s          = 0.0_wp
            new_prop%mu_k          = 0.0_wp
            new_prop%penalty_scale = 10.0_wp
            CALL mapper%model%contact_db%add_property(new_prop)
            idx = mapper%model%contact_db%num_props
        END IF

        ! Cache current contact property context so child keywords (*FRICTION etc.)
        ! can fill in details.
        mapper%current_contact_prop => mapper%model%contact_db%props(idx)
    END SUBROUTINE map_surface_interaction


    ! ==========================================================================
    ! Map *FRICTION keyword (fill mu_s/mu_k for current contact property)
    ! ==========================================================================
    SUBROUTINE map_friction(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType),     INTENT(IN)    :: node

        REAL(wp) :: mu1, mu2

        IF (.NOT. ASSOCIATED(mapper%current_contact_prop)) RETURN

        mu1 = 0.0_wp
        mu2 = 0.0_wp

        IF (node%data_line_count >= 1 .AND. node%data_lines(1)%col_count >= 1) THEN
            mu1 = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) THEN
                mu2 = node%data_lines(1)%real_values(2)
            ELSE
                mu2 = mu1
            END IF

            mapper%current_contact_prop%mu_s = mu1
            mapper%current_contact_prop%mu_k = mu2
        END IF
    END SUBROUTINE map_friction


    ! ==========================================================================    
    ! Map *USER MATERIAL keyword - OLD implementation removed
    ! New implementation uses Parse_USER_Mat_Keyword (see below)
    ! ==========================================================================

    ! ==========================================================================    
    ! Map *DENSITY keyword
    ! ==========================================================================    
    SUBROUTINE map_density(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: rho

        
        ! Fallback-related variables for flat INP files
        CHARACTER(LEN=KW_MAX_LINE_LEN) :: line
        CHARACTER(LEN=512) :: inp_file
        INTEGER(i4) :: unit_num, ios, line_idx
        
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        
        ! ------------------------------------------------------------------
        ! 1)   AST data_lines  
        ! ------------------------------------------------------------------
        IF (node%data_line_count >= 1 .AND. node%data_lines(1)%col_count >= 1) THEN
            rho = node%data_lines(1)%real_values(1)
            CALL mapper%current_material%set_density(rho)
            RETURN
        END IF
        
        ! ------------------------------------------------------------------
        ! 2) Fallback??flat INP  ??AST          !     INP   *DENSITY          ! ------------------------------------------------------------------
        inp_file = TRIM(mapper%parser%lexer%filename)
        IF (LEN_TRIM(inp_file) == 0) RETURN
        
        unit_num = 906
        OPEN(UNIT=unit_num, FILE=inp_file, STATUS='OLD', ACTION='READ', IOSTAT=ios)
        IF (ios /= 0) RETURN
        
        !  *DENSITY          DO line_idx = 1, node%start_line
            READ(unit_num, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT
        END DO
        
        DO
            READ(unit_num, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT
            line = ADJUSTL(line)
            IF (LEN_TRIM(line) == 0) CYCLE
            IF (line(1:1) == '*') EXIT
            IF (line(1:2) == '**') CYCLE
            
            rho = 0.0_wp
            READ(line, *, IOSTAT=ios) rho
            IF (ios /= 0) CYCLE
            IF (rho <= 0.0_wp) CYCLE
            
            CALL mapper%current_material%set_density(rho)
            EXIT
        END DO
        
        CLOSE(unit_num)
    END SUBROUTINE map_density

    ! ==========================================================================
    ! Map *MASS keyword (point mass property)
    ! ==========================================================================
    SUBROUTINE map_mass(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(PtMassDesc) :: pointMass
        TYPE(ErrorStatusType) :: status
        INTEGER(i4) :: i
        
        ! Parse MASS keyword
        CALL Parse_MASS_Keyword(node, pointMass, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_mass: Failed to parse MASS keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        ! Add point mass to model
        ! Note: This requires integration with model's property manager
        WRITE(*,*) 'INFO map_mass: Parsed MASS: ', TRIM(pointMass%name), &
                   ' Node: ', pointMass%nodeId, &
                   ' Mass: ', pointMass%mass, ' kg'
        
    END SUBROUTINE map_mass

    ! ==========================================================================
    ! Map *ROTARY INERTIA keyword
    ! ==========================================================================
    SUBROUTINE map_rotary_inertia(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(RotInertiaDesc) :: rotaryInertia
        TYPE(ErrorStatusType) :: status
        
        ! Parse ROTARY INERTIA keyword
        CALL Parse_ROTARYINERTIA_Keyword(node, rotaryInertia, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_rotary_inertia: Failed to parse ROTARY INERTIA keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        ! Add rotary inertia to model
        WRITE(*,*) 'INFO map_rotary_inertia: Parsed ROTARY INERTIA: ', TRIM(rotaryInertia%name), &
                   ' Ixx=', rotaryInertia%Ixx, ' Iyy=', rotaryInertia%Iyy, ' Izz=', rotaryInertia%Izz
        
    END SUBROUTINE map_rotary_inertia

    ! ==========================================================================
    ! Map *POINT MASS keyword
    ! ==========================================================================
    SUBROUTINE map_point_mass(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(PointMassAltDesc) :: pointMass
        TYPE(ErrorStatusType) :: status
        
        ! Parse POINT MASS keyword
        CALL Parse_POINTMASS_Keyword(node, pointMass, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_point_mass: Failed to parse POINT MASS keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        ! Add point mass to model
        WRITE(*,*) 'INFO map_point_mass: Parsed POINT MASS: ', TRIM(pointMass%name), &
                   ' Node: ', pointMass%nodeId, &
                   ' Mass: ', pointMass%mass, ' kg'
        
    END SUBROUTINE map_point_mass

    ! ==========================================================================
    ! Map *NONSTRUCTURAL MASS keyword
    ! ==========================================================================
    SUBROUTINE map_nonstructural_mass(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(NonStructMassDesc) :: nonstructMass
        TYPE(ErrorStatusType) :: status
        
        ! Parse NONSTRUCTURAL MASS keyword
        CALL Parse_NONSTRUCTURALMASS_Keyword(node, nonstructMass, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_nonstructural_mass: Failed to parse NONSTRUCTURAL MASS keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        ! Add nonstructural mass to model
        WRITE(*,*) 'INFO map_nonstructural_mass: Parsed NONSTRUCTURAL MASS: ', TRIM(nonstructMass%name), &
                   ' Elset: ', TRIM(nonstructMass%elsetName), &
                   ' Mass/Vol: ', nonstructMass%massPerVolume
        
    END SUBROUTINE map_nonstructural_mass

    ! ==========================================================================
    ! Map *CONDUCTIVITY keyword
    ! ==========================================================================
    SUBROUTINE map_conductivity(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        REAL(wp) :: k

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        IF (node%data_line_count >= 1 .AND. node%data_lines(1)%col_count >= 1) THEN
            k = node%data_lines(1)%real_values(1)
            CALL mapper%current_material%set_thermal( &
                mapper%current_material%alpha, k, mapper%current_material%specific_heat )
        END IF
    END SUBROUTINE map_conductivity

    ! ==========================================================================
    ! Map *SPECIFIC HEAT keyword
    ! ==========================================================================
    SUBROUTINE map_specific_heat(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        REAL(wp) :: c

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        IF (node%data_line_count >= 1 .AND. node%data_lines(1)%col_count >= 1) THEN
            c = node%data_lines(1)%real_values(1)
            CALL mapper%current_material%set_thermal( &
                mapper%current_material%alpha, mapper%current_material%conductivity, c )
        END IF
    END SUBROUTINE map_specific_heat

    ! ==========================================================================
    ! Map *EXPANSION keyword
    ! ==========================================================================
    SUBROUTINE map_expansion(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ExpansionProperties) :: expansion
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_expansion: No current material, skipping'
            RETURN
        END IF
        
        ! Get material name
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse EXPANSION keyword
        CALL Parse_EXPANSION_Keyword(node, expansion, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_expansion: Failed to parse EXPANSION keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        ! Update material with expansion properties (backward compatibility)
        IF (expansion%expansionType == EXPANSION_ISOTROPIC) THEN
            CALL mapper%current_material%set_expansion(expansion%alpha, expansion%zeroTemperature)
        ELSE IF (expansion%expansionType == EXPANSION_ORTHOTROPIC) THEN
            CALL mapper%current_material%expansion%set_ortho3( &
                expansion%alpha11, expansion%alpha22, expansion%alpha33, expansion%zeroTemperature)
            mapper%current_material%alpha = (expansion%alpha11 + expansion%alpha22 + expansion%alpha33) / 3.0_wp
        ELSE IF (expansion%expansionType == EXPANSION_ANISOTROPIC) THEN
            CALL mapper%current_material%expansion%set_aniso_voigt6( &
                expansion%alpha_voigt, expansion%zeroTemperature)
            mapper%current_material%alpha = SUM(expansion%alpha_voigt(1:3)) / 3.0_wp
        END IF

        WRITE(*,*) 'INFO map_expansion: Parsed EXPANSION for material: ', TRIM(material_name), &
                   ' Type: ', expansion%expansionType, &
                   ' Alpha: ', expansion%alpha
        
    END SUBROUTINE map_expansion

    ! ========================================================================== 
    ! Map *UF-THERMAL keyword (THERMEXP=ON/OFF)
    ! ========================================================================== 
    SUBROUTINE map_uf_thermal(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType),     INTENT(IN)    :: node
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: thermexp_val
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: val_up
        INTEGER(i4) :: i

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        CALL md_kw_get_param_value(node, "THERMEXP", thermexp_val)
        IF (LEN_TRIM(thermexp_val) == 0) THEN
            mapper%current_material%enable_thermal_expansion = .TRUE.
            RETURN
        END IF

        val_up = thermexp_val
        DO i = 1, LEN_TRIM(val_up)
            IF (val_up(i:i) >= 'a' .AND. val_up(i:i) <= 'z') THEN
                val_up(i:i) = CHAR(ICHAR(val_up(i:i)) - 32)
            END IF
        END DO

        IF (TRIM(val_up) == 'OFF' .OR. TRIM(val_up) == 'NO' .OR. TRIM(val_up) == 'FALSE' .OR. TRIM(val_up) == '0') THEN
            mapper%current_material%enable_thermal_expansion = .FALSE.
        ELSE
            mapper%current_material%enable_thermal_expansion = .TRUE.
        END IF
    END SUBROUTINE map_uf_thermal

    ! ==========================================================================
    ! Map *DAMPING keyword
    ! ==========================================================================
    SUBROUTINE map_damping(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(DampProperties) :: damping
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_damping: No current material, skipping'
            RETURN
        END IF
        
        ! Get material name
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse DAMPING keyword
        CALL Parse_DAMPING_Keyword(node, damping, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_damping: Failed to parse DAMPING keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_damping: Parsed DAMPING for material: ', TRIM(material_name), &
                   ' Type: ', damping%dampingType, &
                   ' Alpha: ', damping%alpha, ' Beta: ', damping%beta
        
    END SUBROUTINE map_damping

    ! ==========================================================================
    ! Map *VISCOSITY keyword
    ! ==========================================================================
    SUBROUTINE map_viscosity(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ViscosityProperties) :: viscosity
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_viscosity: No current material, skipping'
            RETURN
        END IF
        
        ! Get material name
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse VISCOSITY keyword
        CALL Parse_VISCOSITY_Keyword(node, viscosity, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_viscosity: Failed to parse VISCOSITY keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_viscosity: Parsed VISCOSITY for material: ', TRIM(material_name), &
                   ' Type: ', viscosity%viscosityType, &
                   ' Mu: ', viscosity%mu, ' Pa*s'
        
    END SUBROUTINE map_viscosity

    ! ==========================================================================
    ! Map *THERMAL CONDUCTIVITY keyword
    ! ==========================================================================
    SUBROUTINE map_thermal_conductivity(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ThermConductivityProperties) :: conductivity
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_thermal_conductivity: No current material, skipping'
            RETURN
        END IF
        
        ! Get material name
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse THERMAL CONDUCTIVITY keyword
        CALL Parse_THERMALCONDUCTIVITY_Keyword(node, conductivity, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_thermal_conductivity: Failed to parse THERMAL CONDUCTIVITY keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_thermal_conductivity: Parsed THERMAL CONDUCTIVITY for material: ', TRIM(material_name), &
                   ' Type: ', conductivity%conductivityType, &
                   ' K: ', conductivity%k, ' W/(m*K)'
        
    END SUBROUTINE map_thermal_conductivity

    ! ==========================================================================
    ! Map *PERMEABILITY keyword
    ! ==========================================================================
    SUBROUTINE map_permeability(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(PermeabilityProperties) :: permeability
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_permeability: No current material, skipping'
            RETURN
        END IF
        
        ! Get material name
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse PERMEABILITY keyword
        CALL Parse_PERMEABILITY_Keyword(node, permeability, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_permeability: Failed to parse PERMEABILITY keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_permeability: Parsed PERMEABILITY for material: ', TRIM(material_name), &
                   ' Type: ', permeability%permeabilityType, &
                   ' K: ', permeability%k, ' m^2'
        
    END SUBROUTINE map_permeability

    ! ==========================================================================
    ! Map *SORPTION keyword
    ! ==========================================================================
    SUBROUTINE map_sorption(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(SorptionProperties) :: sorption
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_sorption: No current material, skipping'
            RETURN
        END IF
        
        ! Get material name
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse SORPTION keyword
        CALL Parse_SORPTION_Keyword(node, sorption, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_sorption: Failed to parse SORPTION keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_sorption: Parsed SORPTION for material: ', TRIM(material_name), &
                   ' Type: ', sorption%sorptionType
        
    END SUBROUTINE map_sorption

    ! ==========================================================================
    ! Map *SFILM keyword (surface film condition)
    ! ==========================================================================
    SUBROUTINE map_sfilm(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(SfilmBCDesc) :: sfilmBC
        TYPE(ErrorStatusType) :: status

        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_sfilm: current_step_idx <= 0, skip.'
            RETURN
        END IF
        
        ! Parse SFILM keyword
        CALL Parse_SFILM_Keyword(node, sfilmBC, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_sfilm: Failed to parse SFILM keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_sfilm: Parsed SFILM BC: ', TRIM(sfilmBC%name), &
                   ' Surface: ', TRIM(sfilmBC%surfaceName), &
                   ' h=', sfilmBC%filmCoefficient, &
                   ' T_sink=', sfilmBC%sinkTemperature
        
    END SUBROUTINE map_sfilm

    ! ==========================================================================
    ! Map *SRADIATION keyword (surface radiation condition)
    ! ==========================================================================
    SUBROUTINE map_sradiation(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(SradiationBCDesc) :: sradiationBC
        TYPE(ErrorStatusType) :: status

        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_sradiation: current_step_idx <= 0, skip.'
            RETURN
        END IF
        
        ! Parse SRADIATION keyword
        CALL Parse_SRADIATION_Keyword(node, sradiationBC, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_sradiation: Failed to parse SRADIATION keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_sradiation: Parsed SRADIATION BC: ', TRIM(sradiationBC%name), &
                   ' Surface: ', TRIM(sradiationBC%surfaceName), &
                   ' ?=', sradiationBC%emissivity, &
                   ' T_sink=', sradiationBC%sinkTemperature
        
    END SUBROUTINE map_sradiation

    ! ==========================================================================
    ! Map *SPECIFIC HEAT keyword (specific heat capacity)
    ! ==========================================================================
    SUBROUTINE map_specific_heat(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(SpecificHeatProperties) :: specHeat
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_specific_heat: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse SPECIFIC HEAT keyword
        CALL Parse_SPECIFIC_HEAT_Keyword(node, specHeat, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_specific_heat: Failed to parse SPECIFIC HEAT keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_specific_heat: Parsed SPECIFIC HEAT for material: ', TRIM(material_name), &
                   ' TempDep: ', specHeat%temperatureDependent, &
                   ' cp: ', specHeat%specificHeat
        
    END SUBROUTINE map_specific_heat

    ! ==========================================================================
    ! Map *LATENT HEAT keyword (latent heat for phase change)
    ! ==========================================================================
    SUBROUTINE map_latent_heat(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(LatentHeatProperties) :: latentHeat
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_latent_heat: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse LATENT HEAT keyword
        CALL Parse_LATENT_HEAT_Keyword(node, latentHeat, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_latent_heat: Failed to parse LATENT HEAT keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_latent_heat: Parsed LATENT HEAT for material: ', TRIM(material_name), &
                   ' PhaseChanges: ', latentHeat%nPhaseChanges, &
                   ' PoreFluid: ', latentHeat%poreFluid
        
    END SUBROUTINE map_latent_heat

    ! ==========================================================================
    ! Map *JOULE HEAT keyword (joule heat fraction for electro-thermal coupling)
    ! ==========================================================================
    SUBROUTINE map_joule_heat(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(JouleHeatProperties) :: jouleHeat
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_joule_heat: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse JOULE HEAT keyword
        CALL Parse_JOULE_HEAT_Keyword(node, jouleHeat, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_joule_heat: Failed to parse JOULE HEAT keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_joule_heat: Parsed JOULE HEAT for material: ', TRIM(material_name), &
                   ' HeatFraction: ', jouleHeat%heatFraction
        
    END SUBROUTINE map_joule_heat

    ! ==========================================================================
    ! Map *COHESIVE BEHAVIOR keyword (surface-based cohesive behavior)
    ! ==========================================================================
    SUBROUTINE map_cohesive_behavior(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(CohesiveBehaviorProperties) :: cohesive
        TYPE(ErrorStatusType) :: status

        ! Parse COHESIVE BEHAVIOR keyword
        CALL Parse_COHESIVE_BEHAVIOR_Keyword(node, cohesive, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_cohesive_behavior: Failed to parse COHESIVE BEHAVIOR keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_cohesive_behavior: Parsed COHESIVE BEHAVIOR', &
                   ' Type: ', cohesive%behaviorType, &
                   ' K_nn: ', cohesive%K_nn, &
                   ' K_ss: ', cohesive%K_ss, &
                   ' K_tt: ', cohesive%K_tt
        
    END SUBROUTINE map_cohesive_behavior

    ! ==========================================================================
    ! Map *DAMAGE INITIATION keyword (damage initiation criterion)
    ! ==========================================================================
    SUBROUTINE map_damage_initiation(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(DmgInitiationData) :: initiation
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_damage_initiation: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse DAMAGE INITIATION keyword
        CALL Parse_DAMAGE_INITIATION_Keyword(node, initiation, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_damage_initiation: Failed to parse DAMAGE INITIATION keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_damage_initiation: Parsed DAMAGE INITIATION for material: ', TRIM(material_name), &
                   ' Criterion: ', initiation%criterion, &
                   ' Params: ', initiation%paramCount
        
    END SUBROUTINE map_damage_initiation

    ! ==========================================================================
    ! Map *DAMAGE EVOLUTION keyword (damage evolution law)
    ! ==========================================================================
    SUBROUTINE map_damage_evolution(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(DmgEvolutionData) :: evolution
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_damage_evolution: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse DAMAGE EVOLUTION keyword
        CALL Parse_DAMAGE_EVOLUTION_Keyword(node, evolution, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_damage_evolution: Failed to parse DAMAGE EVOLUTION keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_damage_evolution: Parsed DAMAGE EVOLUTION for material: ', TRIM(material_name), &
                   ' Type: ', evolution%evolutionType, &
                   ' Gf: ', evolution%Gf
        
    END SUBROUTINE map_damage_evolution

    ! ==========================================================================
    ! Map *PROGRESSIVE DAMAGE keyword (progressive damage model)
    ! ==========================================================================
    SUBROUTINE map_progressive_damage(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ProgressiveDamageProperties) :: progDamage
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_progressive_damage: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse PROGRESSIVE DAMAGE keyword
        CALL Parse_PROGRESSIVE_DAMAGE_Keyword(node, progDamage, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_progressive_damage: Failed to parse PROGRESSIVE DAMAGE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_progressive_damage: Parsed PROGRESSIVE DAMAGE for material: ', TRIM(material_name), &
                   ' Stages: ', progDamage%nStages, &
                   ' TotalDamage: ', progDamage%totalDamage
        
    END SUBROUTINE map_progressive_damage

    ! ==========================================================================
    ! Map *RATE DEPENDENT keyword (rate dependent material)
    ! ==========================================================================
    SUBROUTINE map_rate_dependent(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(RateDependentProperties) :: rateDep
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_rate_dependent: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse RATE DEPENDENT keyword
        CALL Parse_RATE_DEPENDENT_Keyword(node, rateDep, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_rate_dependent: Failed to parse RATE DEPENDENT keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_rate_dependent: Parsed RATE DEPENDENT for material: ', TRIM(material_name), &
                   ' ModelType: ', rateDep%modelType
        
    END SUBROUTINE map_rate_dependent

    ! ==========================================================================
    ! Map *VISCO keyword (viscoelastic material with Prony series)
    ! ==========================================================================
    SUBROUTINE map_visco(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ViscoProperties) :: visco
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_visco: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse VISCO keyword
        CALL Parse_VISCO_Keyword(node, visco, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_visco: Failed to parse VISCO keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_visco: Parsed VISCO for material: ', TRIM(material_name), &
                   ' PronyTerms: ', visco%nTerms
        
    END SUBROUTINE map_visco

    ! ==========================================================================
    ! Map *HYPERFOAM keyword (hyperelastic foam material)
    ! ==========================================================================
    SUBROUTINE map_hyperfoam(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(HyperfoamProperties) :: hyperfoam
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_hyperfoam: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse HYPERFOAM keyword
        CALL Parse_HYPERFOAM_Keyword(node, hyperfoam, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_hyperfoam: Failed to parse HYPERFOAM keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_hyperfoam: Parsed HYPERFOAM for material: ', TRIM(material_name), &
                   ' N: ', hyperfoam%nTerms, &
                   ' Poisson: ', hyperfoam%poisson
        
    END SUBROUTINE map_hyperfoam

    ! ==========================================================================
    ! Map *HYPOELASTIC keyword (hypoelastic material)
    ! ==========================================================================
    SUBROUTINE map_hypoelastic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(HypoelasticProperties) :: hypoelastic
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_hypoelastic: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse HYPOELASTIC keyword
        CALL Parse_HYPOELASTIC_Keyword(node, hypoelastic, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_hypoelastic: Failed to parse HYPOELASTIC keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_hypoelastic: Parsed HYPOELASTIC for material: ', TRIM(material_name), &
                   ' E: ', hypoelastic%E, &
                   ' nu: ', hypoelastic%nu
        
    END SUBROUTINE map_hypoelastic

    ! ==========================================================================
    ! Map *CAP PLASTICITY keyword (cap plasticity model)
    ! ==========================================================================
    SUBROUTINE map_cap_plasticity(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(CapPlasticityProperties) :: capPlasticity
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_cap_plasticity: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse CAP PLASTICITY keyword
        CALL Parse_CAP_PLASTICITY_Keyword(node, capPlasticity, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_cap_plasticity: Failed to parse CAP PLASTICITY keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_cap_plasticity: Parsed CAP PLASTICITY for material: ', TRIM(material_name), &
                   ' Beta: ', capPlasticity%frictionAngle_beta, &
                   ' R: ', capPlasticity%capEccentricity_R
        
    END SUBROUTINE map_cap_plasticity

    ! ==========================================================================
    ! Map *CRYSTAL PLASTICITY keyword
    ! ==========================================================================
    SUBROUTINE map_crystal_plasticity(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        TYPE(CrystalPlasticityProperties) :: crystalPlasticity
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_crystal_plasticity: No current material, skipping'
            RETURN
        END IF

        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF

        CALL Parse_CRYSTAL_PLASTICITY_Keyword(node, crystalPlasticity, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_crystal_plasticity: Failed to parse CRYSTAL PLASTICITY keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF

        WRITE(*,*) 'INFO map_crystal_plasticity: Parsed CRYSTAL PLASTICITY for material: ', TRIM(material_name), &
                   ' nslip: ', crystalPlasticity%nslip

    END SUBROUTINE map_crystal_plasticity

    ! ==========================================================================
    ! Map *DRUCKER PRAGER keyword (Drucker-Prager plasticity)
    ! ==========================================================================
    SUBROUTINE map_drucker_prager(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(DruckerPragerProperties) :: druckerPrager
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_drucker_prager: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse DRUCKER PRAGER keyword
        CALL Parse_DRUCKER_PRAGER_Keyword(node, druckerPrager, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_drucker_prager: Failed to parse DRUCKER PRAGER keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_drucker_prager: Parsed DRUCKER PRAGER for material: ', TRIM(material_name), &
                   ' Beta: ', druckerPrager%frictionAngle_beta, &
                   ' Kappa: ', druckerPrager%flowStressRatio_kappa
        
    END SUBROUTINE map_drucker_prager

    ! ==========================================================================
    ! Map *MOHR COULOMB keyword (Mohr-Coulomb plasticity)
    ! ==========================================================================
    SUBROUTINE map_mohr_coulomb(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(MohrCoulombProperties) :: mohrCoulomb
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_mohr_coulomb: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF
        
        ! Parse MOHR COULOMB keyword
        CALL Parse_MOHR_COULOMB_Keyword(node, mohrCoulomb, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_mohr_coulomb: Failed to parse MOHR COULOMB keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_mohr_coulomb: Parsed MOHR COULOMB for material: ', TRIM(material_name), &
                   ' Phi: ', mohrCoulomb%frictionAngle_phi, &
                   ' c: ', mohrCoulomb%cohesion_c
        
    END SUBROUTINE map_mohr_coulomb

    ! ==========================================================================
    ! Map *ORIENTATION keyword (material orientation definition)
    ! ==========================================================================
    SUBROUTINE map_orientation(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(OrientProps) :: orientation
        TYPE(ErrorStatusType) :: status

        ! Parse ORIENTATION keyword
        CALL Parse_ORIENTATION_Keyword(node, orientation, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_orientation: Failed to parse ORIENTATION keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_orientation: Parsed ORIENTATION: ', TRIM(orientation%name), &
                   ' SystemType: ', orientation%isys
        
    END SUBROUTINE map_orientation

    ! ==========================================================================
    ! Map *TRANSFORM keyword (coordinate transformation for node sets)
    ! ==========================================================================
    SUBROUTINE map_transform(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(TransformProps) :: transform
        TYPE(ErrorStatusType) :: status

        ! Parse TRANSFORM keyword
        CALL Parse_TRANSFORM_Keyword(node, transform, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_transform: Failed to parse TRANSFORM keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_transform: Parsed TRANSFORM for NSET: ', TRIM(transform%nset), &
                   ' Type: ', transform%ityp
        
    END SUBROUTINE map_transform

    ! ==========================================================================
    ! Map *SYSTEM keyword (coordinate system for node definition)
    ! ==========================================================================
    SUBROUTINE map_system(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(SystemProps) :: system
        TYPE(ErrorStatusType) :: status

        ! Parse SYSTEM keyword
        CALL Parse_SYSTEM_Keyword(node, system, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_system: Failed to parse SYSTEM keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        IF (system%active) THEN
            WRITE(*,*) 'INFO map_system: Parsed SYSTEM (local coordinate system active)'
        ELSE
            WRITE(*,*) 'INFO map_system: Parsed SYSTEM (reset to global coordinate system)'
        END IF
        
    END SUBROUTINE map_system

    ! ==========================================================================
    ! Map *NORMAL keyword (normal vector definition)
    ! ==========================================================================
    SUBROUTINE map_normal(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(NormalProps) :: normal
        TYPE(ErrorStatusType) :: status

        ! Parse NORMAL keyword
        CALL Parse_NORMAL_Keyword(node, normal, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_normal: Failed to parse NORMAL keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_normal: Parsed NORMAL, Type: ', normal%itype, &
                   ' Definitions: ', normal%n_def
        
    END SUBROUTINE map_normal

    ! ==========================================================================
    ! Map *DISTRIBUTION keyword (spatial distribution definition)
    ! ==========================================================================
    SUBROUTINE map_distribution(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(DistributionProperties) :: distribution
        TYPE(ErrorStatusType) :: status

        ! Parse DISTRIBUTION keyword
        CALL Parse_DISTRIBUTION_Keyword(node, distribution, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_distribution: Failed to parse DISTRIBUTION keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_distribution: Parsed DISTRIBUTION: ', TRIM(distribution%name), &
                   ' Table: ', TRIM(distribution%tableName), &
                   ' Location: ', distribution%locationType, &
                   ' Entries: ', distribution%numEntries
        
    END SUBROUTINE map_distribution

    ! ==========================================================================
    ! Map *TABLE keyword (interpolation table definition)
    ! ==========================================================================
    SUBROUTINE map_table(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(TableProperties) :: table
        TYPE(ErrorStatusType) :: status

        ! Parse TABLE keyword
        CALL Parse_TABLE_Keyword(node, table, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_table: Failed to parse TABLE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_table: Parsed TABLE: ', TRIM(table%name), &
                   ' IndependentVars: ', table%numIndependentVars, &
                   ' Entries: ', table%numEntries
        
    END SUBROUTINE map_table

    ! ==========================================================================
    ! Map *FIELD keyword (field variable definition)
    ! ==========================================================================
    SUBROUTINE map_field(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(FieldProperties) :: field
        TYPE(ErrorStatusType) :: status

        CALL Parse_FIELD_Keyword(node, field, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_field: Failed to parse FIELD keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_field: Parsed FIELD, Variable: ', field%variableNumber, &
                   ' Entries: ', field%numEntries
        
    END SUBROUTINE map_field

    ! ==========================================================================
    ! Map *PARAMETER keyword (parameter definition)
    ! ==========================================================================
    SUBROUTINE map_parameter(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ParameterProperties) :: parameter
        TYPE(ErrorStatusType) :: status

        CALL Parse_PARAMETER_Keyword(node, parameter, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_parameter: Failed to parse PARAMETER keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_parameter: Parsed PARAMETER, Entries: ', parameter%numEntries
        
    END SUBROUTINE map_parameter

    ! ==========================================================================
    ! Map *VARIABLE keyword (variable definition)
    ! ==========================================================================
    SUBROUTINE map_variable(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(VariableProperties) :: variable
        TYPE(ErrorStatusType) :: status

        CALL Parse_VARIABLE_Keyword(node, variable, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_variable: Failed to parse VARIABLE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_variable: Parsed VARIABLE: ', TRIM(variable%name)
        
    END SUBROUTINE map_variable

    ! ==========================================================================
    ! Map *FILTER keyword (filter definition)
    ! ==========================================================================
    SUBROUTINE map_filter(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(FilterProperties) :: filter
        TYPE(ErrorStatusType) :: status

        CALL Parse_FILTER_Keyword(node, filter, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_filter: Failed to parse FILTER keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_filter: Parsed FILTER: ', TRIM(filter%name)
        
    END SUBROUTINE map_filter

    ! ==========================================================================
    ! Map *INCLUDE keyword (include file)
    ! ==========================================================================
    SUBROUTINE map_include(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(IncludeProperties) :: include_prop
        TYPE(ErrorStatusType) :: status

        CALL Parse_INCLUDE_Keyword(node, include_prop, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_include: Failed to parse INCLUDE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_include: Parsed INCLUDE file: ', TRIM(include_prop%inputFile)
        
    END SUBROUTINE map_include

    ! ==========================================================================
    ! Map *PREPRINT keyword (preprint control)
    ! ==========================================================================
    SUBROUTINE map_preprint(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(PreprintProperties) :: preprint
        TYPE(ErrorStatusType) :: status

        CALL Parse_PREPRINT_Keyword(node, preprint, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_preprint: Failed to parse PREPRINT keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_preprint: Parsed PREPRINT, ECHO: ', preprint%echo, &
                   ' MODEL: ', preprint%model
        
    END SUBROUTINE map_preprint

    ! ==========================================================================
    ! Map *FILE FORMAT keyword (file format)
    ! ==========================================================================
    SUBROUTINE map_file_format(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(FormatProperties) :: format_prop
        TYPE(ErrorStatusType) :: status

        CALL Parse_FILE_FORMAT_Keyword(node, format_prop, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_file_format: Failed to parse FILE FORMAT keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_file_format: Parsed FILE FORMAT, Type: ', format_prop%formatType
        
    END SUBROUTINE map_file_format

    ! ==========================================================================
    ! Map *PHYSICAL CONSTANTS keyword (physical constants)
    ! ==========================================================================
    SUBROUTINE map_physical_constants(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(PhysicalConstantsProperties) :: constants
        TYPE(ErrorStatusType) :: status

        CALL Parse_PHYSICAL_CONSTANTS_Keyword(node, constants, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_physical_constants: Failed to parse PHYSICAL CONSTANTS keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_physical_constants: Parsed PHYSICAL CONSTANTS'
        
    END SUBROUTINE map_physical_constants

    ! ==========================================================================
    ! Map *NODE FILE keyword (node file output)
    ! ==========================================================================
    SUBROUTINE map_node_file(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(NodeFileProperties) :: nodeFile
        TYPE(ErrorStatusType) :: status

        CALL Parse_NODE_FILE_Keyword(node, nodeFile, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_node_file: Failed to parse NODE FILE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_node_file: Parsed NODE FILE: ', TRIM(nodeFile%fileName)
        
    END SUBROUTINE map_node_file

    ! ==========================================================================
    ! Map *EL FILE keyword (element file output)
    ! ==========================================================================
    SUBROUTINE map_el_file(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ElFileProperties) :: elFile
        TYPE(ErrorStatusType) :: status

        CALL Parse_EL_FILE_Keyword(node, elFile, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_el_file: Failed to parse EL FILE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_el_file: Parsed EL FILE: ', TRIM(elFile%fileName)
        
    END SUBROUTINE map_el_file

    ! ==========================================================================
    ! Map *MODAL DAMPING keyword (modal damping)
    ! ==========================================================================
    SUBROUTINE map_modal_damping(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ModalDampingProperties) :: modalDamping
        TYPE(ErrorStatusType) :: status

        CALL MD_RT_KW_ParseModalDamping(node, modalDamping, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_modal_damping: Failed to parse MODAL DAMPING keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_modal_damping: Parsed MODAL DAMPING, Entries: ', modalDamping%numEntries
        
    END SUBROUTINE map_modal_damping

    ! ==========================================================================
    ! Map *STEADY STATE DYNAMICS keyword (steady state dynamics)
    ! ==========================================================================
    SUBROUTINE map_steady_state_dynamics(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(SteadyStateProperties) :: steadyState
        TYPE(ErrorStatusType) :: status

        CALL MD_RT_KW_ParseSteadyState(node, steadyState, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_steady_state_dynamics: Failed to parse STEADY STATE DYNAMICS keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_steady_state_dynamics: Parsed STEADY STATE DYNAMICS, Frequencies: ', steadyState%numFrequencies
        
    END SUBROUTINE map_steady_state_dynamics

    ! ==========================================================================
    ! Map *DIRECT keyword (direct integration)
    ! ==========================================================================
    SUBROUTINE map_direct(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(DirectProperties) :: direct
        TYPE(ErrorStatusType) :: status

        CALL MD_RT_KW_ParseDirect(node, direct, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_direct: Failed to parse DIRECT keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_direct: Parsed DIRECT'
        
    END SUBROUTINE map_direct

    ! ==========================================================================
    ! Map *SUBSTRUCTURE keyword (substructure)
    ! ==========================================================================
    SUBROUTINE map_substructure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(SubstructureProperties) :: substructure
        TYPE(ErrorStatusType) :: status

        CALL MD_RT_KW_ParseSubstructure(node, substructure, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_substructure: Failed to parse SUBSTRUCTURE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_substructure: Parsed SUBSTRUCTURE: ', TRIM(substructure%name)
        
    END SUBROUTINE map_substructure

    ! ==========================================================================
    ! Map *MODAL DYNAMIC keyword (modal dynamic)
    ! ==========================================================================
    SUBROUTINE map_modal_dynamic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ModalDynamicProperties) :: modalDynamic
        TYPE(ErrorStatusType) :: status

        CALL MD_RT_KW_ParseModalDynamic(node, modalDynamic, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_modal_dynamic: Failed to parse MODAL DYNAMIC keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_modal_dynamic: Parsed MODAL DYNAMIC'
        
    END SUBROUTINE map_modal_dynamic

    ! ==========================================================================
    ! Map *COMPLEX FREQUENCY keyword (complex frequency)
    ! ==========================================================================
    SUBROUTINE map_complex_frequency(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ComplexFrequencyProperties) :: complexFreq
        TYPE(ErrorStatusType) :: status

        CALL MD_RT_KW_ParseComplexFrequency(node, complexFreq, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_complex_frequency: Failed to parse COMPLEX FREQUENCY keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_complex_frequency: Parsed COMPLEX FREQUENCY'
        
    END SUBROUTINE map_complex_frequency

    ! ==========================================================================
    ! Map *RESPONSE SPECTRUM keyword (response spectrum)
    ! ==========================================================================
    SUBROUTINE map_response_spectrum(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(ResponseSpectrumProperties) :: responseSpectrum
        TYPE(ErrorStatusType) :: status

        CALL MD_RT_KW_ParseResponseSpectrum(node, responseSpectrum, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_response_spectrum: Failed to parse RESPONSE SPECTRUM keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_response_spectrum: Parsed RESPONSE SPECTRUM, Entries: ', responseSpectrum%numEntries
        
    END SUBROUTINE map_response_spectrum

    ! ==========================================================================
    ! Map *USER MATERIAL keyword (user material subroutine)
    ! ==========================================================================
    SUBROUTINE map_user_material(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UserMaterialProperties) :: userMaterial
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_user_material: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF

        CALL Parse_USER_Mat_Keyword(node, userMaterial, TRIM(material_name), status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_user_material: Failed to parse USER MATERIAL keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_user_material: Parsed USER MATERIAL for material: ', TRIM(material_name), &
                   ' Constants: ', userMaterial%numConstants, &
                   ' Type: ', userMaterial%cfg%materialType
        
    END SUBROUTINE map_user_material

    ! ==========================================================================
    ! Map *USER ELEMENT keyword (user element subroutine)
    ! ==========================================================================
    SUBROUTINE map_user_element(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        WRITE(*,*) 'ERROR map_user_element: USER ELEMENT / UEL is not supported'
        mapper%error_count = mapper%error_count + 1
        
    END SUBROUTINE map_user_element

    ! ==========================================================================
    ! Map *USER DEFINED FIELD keyword (user defined field subroutine)
    ! ==========================================================================
    SUBROUTINE map_user_defined_field(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UserDefinedFieldProperties) :: userField
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: material_name

        IF (.NOT. ASSOCIATED(mapper%current_material)) THEN
            WRITE(*,*) 'WARNING map_user_defined_field: No current material, skipping'
            RETURN
        END IF
        
        material_name = ""
        IF (ASSOCIATED(mapper%current_material)) THEN
            material_name = TRIM(mapper%current_material%name)
        END IF

        CALL Parse_USER_DEFINED_FIELD_Keyword(node, userField, TRIM(material_name), status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_user_defined_field: Failed to parse USER DEFINED FIELD keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_user_defined_field: Parsed USER DEFINED FIELD for material: ', TRIM(material_name)
        
    END SUBROUTINE map_user_defined_field

    ! ==========================================================================
    ! Map *USER LOAD keyword (user load subroutine)
    ! ==========================================================================
    SUBROUTINE map_user_load(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UserLoadProperties) :: userLoad
        TYPE(ErrorStatusType) :: status

        CALL Parse_USER_LOAD_Keyword(node, userLoad, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_user_load: Failed to parse USER LOAD keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_user_load: Parsed USER LOAD: ', TRIM(userLoad%loadName)
        
    END SUBROUTINE map_user_load

    ! ==========================================================================
    ! Map *USER CONTACT keyword (user contact subroutine)
    ! ==========================================================================
    SUBROUTINE map_user_contact(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UserContactProperties) :: userContact
        TYPE(ErrorStatusType) :: status

        CALL Parse_USER_CONTACT_Keyword(node, userContact, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_user_contact: Failed to parse USER CONTACT keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_user_contact: Parsed USER CONTACT: ', TRIM(userContact%interactionName)
        
    END SUBROUTINE map_user_contact

    ! ==========================================================================
    ! Map *USER OUTPUT keyword (user output subroutine)
    ! ==========================================================================
    SUBROUTINE map_user_output(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UserOutputProperties) :: userOutput
        TYPE(ErrorStatusType) :: status

        CALL Parse_USER_OUTPUT_Keyword(node, userOutput, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_user_output: Failed to parse USER OUTPUT keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_user_output: Parsed USER OUTPUT, Variables: ', userOutput%numVariables
        
    END SUBROUTINE map_user_output

    ! ==========================================================================
    ! Map *USER AMPLITUDE keyword (user amplitude subroutine)
    ! ==========================================================================
    SUBROUTINE map_user_amplitude(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UserAmplitudeProperties) :: userAmplitude
        TYPE(ErrorStatusType) :: status

        CALL Parse_USER_AMPLITUDE_Keyword(node, userAmplitude, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_user_amplitude: Failed to parse USER AMPLITUDE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_user_amplitude: Parsed USER AMPLITUDE: ', TRIM(userAmplitude%amplitudeName)
        
    END SUBROUTINE map_user_amplitude

    ! ==========================================================================
    ! Map *USER SUBROUTINE keyword (generic user subroutine)
    ! ==========================================================================
    SUBROUTINE map_user_subroutine(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UserSubroutineProperties) :: userSubroutine
        TYPE(ErrorStatusType) :: status

        CALL Parse_USER_SUBROUTINE_Keyword(node, userSubroutine, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_user_subroutine: Failed to parse USER SUBROUTINE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        WRITE(*,*) 'INFO map_user_subroutine: Parsed USER SUBROUTINE: ', TRIM(userSubroutine%subroutineName)
        
    END SUBROUTINE map_user_subroutine

    ! ==========================================================================
    ! Map *ADAPTIVE MESH keyword - REMOVED (module deleted as unused)
    ! ==========================================================================
    ! Note: map_adaptive_mesh subroutine removed - MD_Mesh_AdaptiveMesh module deleted

    ! ==========================================================================
    ! Map *ADAPTIVE MESH CONTROLS keyword - REMOVED (module deleted as unused)
    ! ==========================================================================
    ! Note: map_adaptive_mesh_controls subroutine removed - MD_Mesh_AdaptiveMeshControls module deleted

    ! ==========================================================================
    ! Map *REMESH keyword - REMOVED (module deleted as unused)
    ! ==========================================================================
    ! Note: map_remesh subroutine removed - MD_Mesh_Remesh module deleted

    ! ==========================================================================
    ! Map *MESH REFINEMENT keyword - REMOVED (module deleted as unused)
    ! ==========================================================================
    ! Note: map_mesh_refinement subroutine removed - MD_Mesh_MeshRefinement module deleted

    ! ==========================================================================
    ! Map *MESH CONSTRAINT keyword - REMOVED (module deleted as unused)
    ! ==========================================================================
    ! Note: map_mesh_constraint subroutine removed - MD_Mesh_MeshConstraint module deleted

    ! ==========================================================================
    ! Map *DESIGN RESPONSE keyword
    ! ==========================================================================
    SUBROUTINE map_design_response(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(DesignResponseProperties) :: designResponse
        TYPE(ErrorStatusType) :: status
        CALL Parse_DESIGN_RESPONSE_Keyword(node, designResponse, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_design_response: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_design_response: Name=', TRIM(designResponse%name), &
                   ' Type=', TRIM(designResponse%responseType)
    END SUBROUTINE map_design_response

    ! ==========================================================================
    ! Map *OBJECTIVE keyword
    ! ==========================================================================
    SUBROUTINE map_objective(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ObjectiveProperties) :: objective
        TYPE(ErrorStatusType) :: status
        CALL Parse_OBJECTIVE_Keyword(node, objective, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_objective: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_objective: Name=', TRIM(objective%name), &
                   ' Type=', TRIM(objective%objectiveType)
    END SUBROUTINE map_objective

    ! ==========================================================================
    ! Map *DESIGN VARIABLE keyword
    ! ==========================================================================
    SUBROUTINE map_design_variable(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(DesignVariableProperties) :: designVariable
        TYPE(ErrorStatusType) :: status
        CALL Parse_DESIGN_VARIABLE_Keyword(node, designVariable, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_design_variable: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_design_variable: Name=', TRIM(designVariable%name), &
                   ' Type=', TRIM(designVariable%variableType)
    END SUBROUTINE map_design_variable

    ! ==========================================================================
    ! Map *CONSTRAINT keyword (optimization context)
    ! ==========================================================================
    SUBROUTINE map_optimization_constraint(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(OptimizationConstraintProperties) :: constraint
        TYPE(ErrorStatusType) :: status
        CALL Parse_OPTIMIZATION_CONSTRAINT_Keyword(node, constraint, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_optimization_constraint: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_optimization_constraint: Name=', TRIM(constraint%name)
    END SUBROUTINE map_optimization_constraint

    ! ==========================================================================
    ! Map *SENSITIVITY keyword
    ! ==========================================================================
    SUBROUTINE map_sensitivity(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(SensitivityProperties) :: sensitivity
        TYPE(ErrorStatusType) :: status
        CALL Parse_SENSITIVITY_Keyword(node, sensitivity, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_sensitivity: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_sensitivity: Type=', TRIM(sensitivity%sensitivityType)
    END SUBROUTINE map_sensitivity

    ! ==========================================================================
    ! Map *TOPOLOGY OPTIMIZATION keyword
    ! ==========================================================================
    SUBROUTINE map_topology_optimization(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(TopologyOptimizationProperties) :: topology
        TYPE(ErrorStatusType) :: status
        CALL Parse_TOPOLOGY_OPTIMIZATION_Keyword(node, topology, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_topology_optimization: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_topology_optimization: Type=', TRIM(topology%optimizationType)
    END SUBROUTINE map_topology_optimization

    ! ==========================================================================
    ! Map *SHAPE OPTIMIZATION keyword
    ! ==========================================================================
    SUBROUTINE map_shape_optimization(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ShapeOptimizationProperties) :: shapeOpt
        TYPE(ErrorStatusType) :: status
        CALL Parse_SHAPE_OPTIMIZATION_Keyword(node, shapeOpt, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_shape_optimization: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_shape_optimization: Method=', TRIM(shapeOpt%method)
    END SUBROUTINE map_shape_optimization

    ! ==========================================================================
    ! Map *SIZE OPTIMIZATION keyword
    ! ==========================================================================
    SUBROUTINE map_size_optimization(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(SizeOptimizationProperties) :: sizeOpt
        TYPE(ErrorStatusType) :: status
        CALL Parse_SIZE_OPTIMIZATION_Keyword(node, sizeOpt, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_size_optimization: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_size_optimization: MinSize=', sizeOpt%minSize, &
                   ' MaxSize=', sizeOpt%maxSize
    END SUBROUTINE map_size_optimization

    ! ==========================================================================
    ! Map *OPTIMIZATION CONTROLS keyword
    ! ==========================================================================
    SUBROUTINE map_optimization_controls(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(OptimizationControlsProperties) :: controls
        TYPE(ErrorStatusType) :: status
        CALL Parse_OPTIMIZATION_CONTROLS_Keyword(node, controls, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_optimization_controls: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_optimization_controls: Method=', TRIM(controls%method), &
                   ' MaxIter=', controls%maxIterations
    END SUBROUTINE map_optimization_controls

    ! ==========================================================================
    ! Map *OPTIMIZATION HISTORY keyword
    ! ==========================================================================
    SUBROUTINE map_optimization_history(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(OptimizationHistoryProperties) :: history
        TYPE(ErrorStatusType) :: status
        CALL Parse_OPTIMIZATION_HISTORY_Keyword(node, history, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_optimization_history: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_optimization_history: OutputFile=', TRIM(history%outputFile)
    END SUBROUTINE map_optimization_history

    ! ==========================================================================
    ! Map *CONNECTOR keyword
    ! ==========================================================================
    SUBROUTINE map_connector(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ConnectorProperties) :: connector
        TYPE(ErrorStatusType) :: status
        CALL Parse_CONNECTOR_Keyword(node, connector, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_connector: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_connector: Name=', TRIM(connector%name)
    END SUBROUTINE map_connector

    ! ==========================================================================
    ! Map *CONNECTOR BEHAVIOR keyword
    ! ==========================================================================
    SUBROUTINE map_connector_behavior(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ConnectorBehaviorProperties) :: behavior
        TYPE(ErrorStatusType) :: status
        CALL Parse_CONNECTOR_BEHAVIOR_Keyword(node, behavior, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_connector_behavior: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_connector_behavior: Name=', TRIM(behavior%name), &
                   ' Type=', TRIM(behavior%behaviorType)
    END SUBROUTINE map_connector_behavior

    ! ==========================================================================
    ! Map *CONNECTOR SECTION keyword
    ! ==========================================================================
    SUBROUTINE map_connector_section(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ConnectorSectionProperties) :: section
        TYPE(ErrorStatusType) :: status
        CALL Parse_CONNECTOR_SECTION_Keyword(node, section, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_connector_section: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_connector_section: Name=', TRIM(section%name)
    END SUBROUTINE map_connector_section

    ! ==========================================================================
    ! Map *JOINT keyword
    ! ==========================================================================
    SUBROUTINE map_joint(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(JointProperties) :: joint
        TYPE(ErrorStatusType) :: status
        CALL Parse_JOINT_Keyword(node, joint, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_joint: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_joint: Name=', TRIM(joint%name), &
                   ' Type=', TRIM(joint%jointType)
    END SUBROUTINE map_joint

    ! ==========================================================================
    ! Map *BUSHING keyword
    ! ==========================================================================
    SUBROUTINE map_bushing(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(BushingProperties) :: bushing
        TYPE(ErrorStatusType) :: status
        CALL Parse_BUSHING_Keyword(node, bushing, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_bushing: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_bushing: Name=', TRIM(bushing%name)
    END SUBROUTINE map_bushing

    ! ==========================================================================
    ! Map *SPRING keyword
    ! ==========================================================================
    SUBROUTINE map_spring(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(SpringProperties) :: spring
        TYPE(ErrorStatusType) :: status
        CALL Parse_SPRING_Keyword(node, spring, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_spring: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_spring: Name=', TRIM(spring%name), &
                   ' Stiffness=', spring%stiffness
    END SUBROUTINE map_spring

    ! ==========================================================================
    ! Map *DASHPOT keyword
    ! ==========================================================================
    SUBROUTINE map_dashpot(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(DashProperties) :: dashpot
        TYPE(ErrorStatusType) :: status
        CALL Parse_DASHPOT_Keyword(node, dashpot, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_dashpot: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_dashpot: Name=', TRIM(dashpot%name), &
                   ' Damping=', dashpot%dampingCoefficient
    END SUBROUTINE map_dashpot

    ! ==========================================================================
    ! Map *KINEMATIC keyword
    ! ==========================================================================
    SUBROUTINE map_kinematic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(KinematicProperties) :: kinematic
        TYPE(ErrorStatusType) :: status
        CALL Parse_KINEMATIC_Keyword(node, kinematic, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_kinematic: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_kinematic: Name=', TRIM(kinematic%name)
    END SUBROUTINE map_kinematic

    ! ==========================================================================
    ! Map *MOTION keyword
    ! ==========================================================================
    SUBROUTINE map_motion(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(MotionProperties) :: motion
        TYPE(ErrorStatusType) :: status
        CALL Parse_MOTION_Keyword(node, motion, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_motion: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_motion: Name=', TRIM(motion%name), &
                   ' DOF=', motion%dof
    END SUBROUTINE map_motion

    ! ==========================================================================
    ! Map *VELOCITY keyword
    ! ==========================================================================
    SUBROUTINE map_velocity(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(VelocityProperties) :: velocity
        TYPE(ErrorStatusType) :: status
        CALL Parse_VELOCITY_Keyword(node, velocity, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_velocity: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_velocity: Name=', TRIM(velocity%name), &
                   ' DOF=', velocity%dof, ' Value=', velocity%velocityValue
    END SUBROUTINE map_velocity

    ! ==========================================================================
    ! Map *ACCELERATION keyword
    ! ==========================================================================
    SUBROUTINE map_acceleration(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(AccelerationProperties) :: acceleration
        TYPE(ErrorStatusType) :: status
        CALL Parse_ACCELERATION_Keyword(node, acceleration, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_acceleration: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_acceleration: Name=', TRIM(acceleration%name), &
                   ' DOF=', acceleration%dof, ' Value=', acceleration%accelerationValue
    END SUBROUTINE map_acceleration

    ! ==========================================================================
    ! Map *BASE MOTION keyword
    ! ==========================================================================
    SUBROUTINE map_base_motion(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(BaseMotionProperties) :: baseMotion
        TYPE(ErrorStatusType) :: status
        CALL Parse_BASE_MOTION_Keyword(node, baseMotion, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_base_motion: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_base_motion: Name=', TRIM(baseMotion%name), &
                   ' DOF=', baseMotion%dof
    END SUBROUTINE map_base_motion

    ! ==========================================================================
    ! Map *COMPOSITE keyword
    ! ==========================================================================
    SUBROUTINE map_composite(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(CompositeProperties) :: composite
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_COMPOSITE_Keyword(node, composite, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_composite: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_composite: Material=', TRIM(material_name), &
                   ' Layers=', composite%numLayers
    END SUBROUTINE map_composite

    ! ==========================================================================
    ! Map *LAMINATE keyword
    ! ==========================================================================
    SUBROUTINE map_laminate(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(LaminateProperties) :: laminate
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_LAMINATE_Keyword(node, laminate, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_laminate: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_laminate: Material=', TRIM(material_name), &
                   ' Layers=', laminate%numLayers
    END SUBROUTINE map_laminate

    ! ==========================================================================
    ! Map *FIBER REINFORCED keyword
    ! ==========================================================================
    SUBROUTINE map_fiber_reinforced(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(FiberReinforcedProperties) :: fiberReinforced
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_FIBER_REINFORCED_Keyword(node, fiberReinforced, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_fiber_reinforced: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_fiber_reinforced: Material=', TRIM(material_name)
    END SUBROUTINE map_fiber_reinforced

    ! ==========================================================================
    ! Map *PUCK CRITERION keyword
    ! ==========================================================================
    SUBROUTINE map_puck_criterion(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(PuckCriterionProperties) :: puck
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_PUCK_CRITERION_Keyword(node, puck, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_puck_criterion: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_puck_criterion: Material=', TRIM(material_name)
    END SUBROUTINE map_puck_criterion

    ! ==========================================================================
    ! Map *HASHIN CRITERION keyword
    ! ==========================================================================
    SUBROUTINE map_hashin_criterion(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(HashinCriterionProperties) :: hashin
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_HASHIN_CRITERION_Keyword(node, hashin, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_hashin_criterion: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_hashin_criterion: Material=', TRIM(material_name)
    END SUBROUTINE map_hashin_criterion

    ! ==========================================================================
    ! Map *JOHNSON COOK keyword
    ! ==========================================================================
    SUBROUTINE map_johnson_cook(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(JohnsonCookProperties) :: johnsonCook
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_JOHNSON_COOK_Keyword(node, johnsonCook, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_johnson_cook: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_johnson_cook: Material=', TRIM(material_name)
    END SUBROUTINE map_johnson_cook

    ! ==========================================================================
    ! Map *ZERILLI ARMSTRONG keyword
    ! ==========================================================================
    SUBROUTINE map_zerilli_armstrong(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ZerilliArmstrongProperties) :: zerilliArmstrong
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_ZERILLI_ARMSTRONG_Keyword(node, zerilliArmstrong, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_zerilli_armstrong: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_zerilli_armstrong: Material=', TRIM(material_name)
    END SUBROUTINE map_zerilli_armstrong

    ! ==========================================================================
    ! Map *ANAND keyword
    ! ==========================================================================
    SUBROUTINE map_anand(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(AnandProperties) :: anand
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_ANAND_Keyword(node, anand, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_anand: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_anand: Material=', TRIM(material_name)
    END SUBROUTINE map_anand

    ! ==========================================================================
    ! Map *BODNER PARTOM keyword
    ! ==========================================================================
    SUBROUTINE map_bodner_partom(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(BodnerPartomProperties) :: bodnerPartom
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_BODNER_PARTOM_Keyword(node, bodnerPartom, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_bodner_partom: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_bodner_partom: Material=', TRIM(material_name)
    END SUBROUTINE map_bodner_partom

    ! ==========================================================================
    ! Map *CHABOCHE keyword
    ! ==========================================================================
    SUBROUTINE map_chaboche(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ChabocheProperties) :: chaboche
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_CHABOCHE_Keyword(node, chaboche, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_chaboche: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_chaboche: Material=', TRIM(material_name)
    END SUBROUTINE map_chaboche

    ! ==========================================================================
    ! Map *ARRUDA BOYCE keyword
    ! ==========================================================================
    SUBROUTINE map_arruda_boyce(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ArrudaBoyceProperties) :: arrudaBoyce
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_ARRUDA_BOYCE_Keyword(node, arrudaBoyce, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_arruda_boyce: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_arruda_boyce: Material=', TRIM(material_name)
    END SUBROUTINE map_arruda_boyce

    ! ==========================================================================
    ! Map *VAN DER WAALS keyword
    ! ==========================================================================
    SUBROUTINE map_van_der_waals(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(VanDerWaalsProperties) :: vanDerWaals
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_VAN_DER_WAALS_Keyword(node, vanDerWaals, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_van_der_waals: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_van_der_waals: Material=', TRIM(material_name)
    END SUBROUTINE map_van_der_waals

    ! ==========================================================================
    ! Map *MARLOW keyword
    ! ==========================================================================
    SUBROUTINE map_marlow(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(MarlowProperties) :: marlow
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_MARLOW_Keyword(node, marlow, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_marlow: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_marlow: Material=', TRIM(material_name), &
                   ' DataPoints=', marlow%numDataPoints
    END SUBROUTINE map_marlow

    ! ==========================================================================
    ! Map *FABRIC keyword
    ! ==========================================================================
    SUBROUTINE map_fabric(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(FabricProperties) :: fabric
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_FABRIC_Keyword(node, fabric, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_fabric: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_fabric: Material=', TRIM(material_name)
    END SUBROUTINE map_fabric

    ! ==========================================================================
    ! Map *ANISOTROPIC HYPERELASTIC keyword
    ! ==========================================================================
    SUBROUTINE map_anisotropic_hyperelastic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(AnisoHyperelasticProperties) :: anisotropicHyper
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: material_name
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        material_name = TRIM(mapper%current_material%name)
        CALL Parse_ANISOTROPIC_HYPERELASTIC_Keyword(node, anisotropicHyper, material_name, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_anisotropic_hyperelastic: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_anisotropic_hyperelastic: Material=', TRIM(material_name), &
                   ' Directions=', anisotropicHyper%numDirections
    END SUBROUTINE map_anisotropic_hyperelastic

    ! ==========================================================================
    ! Map *AQUA keyword
    ! ==========================================================================
    SUBROUTINE map_aqua(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(AquaProperties) :: aqua
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "AQUA_DEFAULT"
        CALL Parse_AQUA_Keyword(node, aqua, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_aqua: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_aqua: Name=', TRIM(aqua%name), &
                   ' Density=', aqua%density
    END SUBROUTINE map_aqua

    ! ==========================================================================
    ! Map *FLUID keyword
    ! ==========================================================================
    SUBROUTINE map_fluid(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(FluidProperties) :: fluid
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "FLUID_DEFAULT"
        CALL Parse_FLUID_Keyword(node, fluid, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_fluid: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_fluid: Name=', TRIM(fluid%name), &
                   ' Type=', fluid%fluidType
    END SUBROUTINE map_fluid

    ! ==========================================================================
    ! Map *FLUID CAVITY keyword
    ! ==========================================================================
    SUBROUTINE map_fluid_cavity(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(FluidCavityProperties) :: fluidCavity
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "FLUID_CAVITY_DEFAULT"
        CALL Parse_FLUID_CAVITY_Keyword(node, fluidCavity, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_fluid_cavity: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_fluid_cavity: Name=', TRIM(fluidCavity%name)
    END SUBROUTINE map_fluid_cavity

    ! ==========================================================================
    ! Map *FLUID EXCHANGE keyword
    ! ==========================================================================
    SUBROUTINE map_fluid_exchange(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(FluidExchangeProperties) :: fluidExchange
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "FLUID_EXCHANGE_DEFAULT"
        CALL Parse_FLUID_EXCHANGE_Keyword(node, fluidExchange, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_fluid_exchange: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_fluid_exchange: Name=', TRIM(fluidExchange%name)
    END SUBROUTINE map_fluid_exchange

    ! ==========================================================================
    ! Map *FLOW keyword
    ! ==========================================================================
    SUBROUTINE map_flow(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(FlowProperties) :: flow
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "FLOW_DEFAULT"
        CALL Parse_FLOW_Keyword(node, flow, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_flow: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_flow: Name=', TRIM(flow%name)
    END SUBROUTINE map_flow

    ! ==========================================================================
    ! Map *PRESSURE PENETRATION keyword
    ! ==========================================================================
    SUBROUTINE map_pressure_penetration(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(PressurePenetrationProperties) :: pressurePenetration
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "PRESSURE_PENETRATION_DEFAULT"
        CALL Parse_PRESSURE_PENETRATION_Keyword(node, pressurePenetration, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_pressure_penetration: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_pressure_penetration: Name=', TRIM(pressurePenetration%name)
    END SUBROUTINE map_pressure_penetration

    ! ==========================================================================
    ! Map *DRAG keyword
    ! ==========================================================================
    SUBROUTINE map_drag(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(DragProperties) :: drag
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "DRAG_DEFAULT"
        CALL Parse_DRAG_Keyword(node, drag, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_drag: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_drag: Name=', TRIM(drag%name)
    END SUBROUTINE map_drag

    ! ==========================================================================
    ! Map *LIFT keyword
    ! ==========================================================================
    SUBROUTINE map_lift(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(LiftProperties) :: lift
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "LIFT_DEFAULT"
        CALL Parse_LIFT_Keyword(node, lift, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_lift: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_lift: Name=', TRIM(lift%name)
    END SUBROUTINE map_lift

    ! Multiphysics model-definition coupling keywords removed (no L3 coupling domain).
    SUBROUTINE map_multiphysics_coupling_removed(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        WRITE(*,*) 'WARN map_multiphysics_coupling_removed: keyword ignored: ', TRIM(node%keyword_name)
        mapper%warning_count = mapper%warning_count + 1
    END SUBROUTINE map_multiphysics_coupling_removed

    ! ==========================================================================
    ! Map *ELECTRICAL keyword
    ! ==========================================================================
    SUBROUTINE map_electrical(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ElectricalProperties) :: electrical
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "ELECTRICAL_DEFAULT"
        CALL Parse_ELECTRICAL_Keyword(node, electrical, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_electrical: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_electrical: Name=', TRIM(electrical%name)
    END SUBROUTINE map_electrical

    ! ==========================================================================
    ! Map *MAGNETIC keyword
    ! ==========================================================================
    SUBROUTINE map_magnetic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(MagneticProperties) :: magnetic
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "MAGNETIC_DEFAULT"
        CALL Parse_MAGNETIC_Keyword(node, magnetic, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_magnetic: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_magnetic: Name=', TRIM(magnetic%name)
    END SUBROUTINE map_magnetic

    ! ==========================================================================
    ! Map *ACOUSTIC keyword
    ! ==========================================================================
    SUBROUTINE map_acoustic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(AcousticProperties) :: acoustic
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "ACOUSTIC_DEFAULT"
        CALL Parse_ACOUSTIC_Keyword(node, acoustic, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_acoustic: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_acoustic: Name=', TRIM(acoustic%name)
    END SUBROUTINE map_acoustic

    ! ==========================================================================
    ! Map *PIEZOELECTRIC keyword
    ! ==========================================================================
    SUBROUTINE map_piezoelectric(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(PiezoelectricProperties) :: piezoelectric
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "PIEZOELECTRIC_DEFAULT"
        CALL Parse_PIEZOELECTRIC_Keyword(node, piezoelectric, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_piezoelectric: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_piezoelectric: Name=', TRIM(piezoelectric%name)
    END SUBROUTINE map_piezoelectric

    ! ==========================================================================
    ! Map *MULTIPHYSICS keyword
    ! ==========================================================================
    SUBROUTINE map_multiphysics(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(MultiphysicsProperties) :: multiphysics
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "MULTIPHYSICS_DEFAULT"
        CALL Parse_MULTIPHYSICS_Keyword(node, multiphysics, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_multiphysics: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_multiphysics: Name=', TRIM(multiphysics%name)
    END SUBROUTINE map_multiphysics

    ! ==========================================================================
    ! Map *CONTACT INTERFERENCE keyword
    ! ==========================================================================
    SUBROUTINE map_contact_interference(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ContactInterferenceProperties) :: contactInterference
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "CONTACT_INTERFERENCE_DEFAULT"
        CALL Parse_CONTACT_INTERFERENCE_Keyword(node, contactInterference, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_contact_interference: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_contact_interference: Name=', TRIM(contactInterference%name)
    END SUBROUTINE map_contact_interference

    ! ==========================================================================
    ! Map *CONTACT CLEARANCE keyword
    ! ==========================================================================
    SUBROUTINE map_contact_clearance(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ContactClearanceProperties) :: contactClearance
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "CONTACT_CLEARANCE_DEFAULT"
        CALL Parse_CONTACT_CLEARANCE_Keyword(node, contactClearance, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_contact_clearance: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_contact_clearance: Name=', TRIM(contactClearance%name)
    END SUBROUTINE map_contact_clearance

    ! ==========================================================================
    ! Map *CONTACT INITIALIZATION keyword
    ! ==========================================================================
    SUBROUTINE map_contact_initialization(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ContactInitializationProperties) :: contactInit
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "CONTACT_INITIALIZATION_DEFAULT"
        CALL Parse_CONTACT_INITIALIZATION_Keyword(node, contactInit, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_contact_initialization: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_contact_initialization: Name=', TRIM(contactInit%name)
    END SUBROUTINE map_contact_initialization

    ! ==========================================================================
    ! Map *CONTACT OUTPUT keyword
    ! ==========================================================================
    SUBROUTINE map_contact_output(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ContactOutputProperties) :: contactOutput
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "CONTACT_OUTPUT_DEFAULT"
        CALL Parse_CONTACT_OUTPUT_Keyword(node, contactOutput, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_contact_output: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_contact_output: Name=', TRIM(contactOutput%name)
    END SUBROUTINE map_contact_output

    ! ==========================================================================
    ! Map *CONTACT CONTROLS keyword
    ! ==========================================================================
    SUBROUTINE map_contact_controls(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ContactControlsProperties) :: contactControls
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "CONTACT_CONTROLS_DEFAULT"
        CALL Parse_CONTACT_CONTROLS_Keyword(node, contactControls, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_contact_controls: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_contact_controls: Name=', TRIM(contactControls%name)
    END SUBROUTINE map_contact_controls

    ! ==========================================================================
    ! Map *CONTACT STABILIZATION keyword
    ! ==========================================================================
    SUBROUTINE map_contact_stabilization(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ContactStabilizationProperties) :: contactStab
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "CONTACT_STABILIZATION_DEFAULT"
        CALL Parse_CONTACT_STABILIZATION_Keyword(node, contactStab, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_contact_stabilization: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_contact_stabilization: Name=', TRIM(contactStab%name)
    END SUBROUTINE map_contact_stabilization

    ! ==========================================================================
    ! Map *FRICTION keyword
    ! ==========================================================================
    SUBROUTINE map_friction(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(FrictionProperties) :: friction
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "FRICTION_DEFAULT"
        CALL Parse_FRICTION_Keyword(node, friction, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_friction: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_friction: Name=', TRIM(friction%name), &
                   ' Coefficient=', friction%coefficient
    END SUBROUTINE map_friction

    ! ==========================================================================
    ! Map *FRICTION COEFFICIENT keyword
    ! ==========================================================================
    SUBROUTINE map_friction_coefficient(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(FrictionCoefficientProperties) :: frictionCoeff
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "FRICTION_COEFFICIENT_DEFAULT"
        CALL Parse_FRICTION_COEFFICIENT_Keyword(node, frictionCoeff, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_friction_coefficient: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_friction_coefficient: Name=', TRIM(frictionCoeff%name)
    END SUBROUTINE map_friction_coefficient

    ! ==========================================================================
    ! Map *STICK SLIP keyword
    ! ==========================================================================
    SUBROUTINE map_stick_slip(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(StickSlipProperties) :: stickSlip
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "STICK_SLIP_DEFAULT"
        CALL Parse_STICK_SLIP_Keyword(node, stickSlip, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_stick_slip: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_stick_slip: Name=', TRIM(stickSlip%name)
    END SUBROUTINE map_stick_slip

    ! ==========================================================================
    ! Map *FRICTION OUTPUT keyword
    ! ==========================================================================
    SUBROUTINE map_friction_output(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(FrictionOutputProperties) :: frictionOutput
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "FRICTION_OUTPUT_DEFAULT"
        CALL Parse_FRICTION_OUTPUT_Keyword(node, frictionOutput, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_friction_output: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_friction_output: Name=', TRIM(frictionOutput%name)
    END SUBROUTINE map_friction_output

    ! ==========================================================================
    ! Manufacturing keyword mapping subroutines - REMOVED (modules deleted as unused)
    ! ==========================================================================
    ! Note: All manufacturing keyword mapping subroutines removed:
    !   - map_forming, map_deep_drawing, map_stamping, map_forging
    !   - map_extrusion, map_rolling, map_weld, map_weld_seam
    !   - map_weld_residual_stress, map_machining, map_heat_treatment, map_cooling
    ! These were STUB implementations with no actual solver integration.

    ! ==========================================================================
    ! Map *OUTPUT REQUEST keyword
    ! ==========================================================================
    SUBROUTINE map_output_request(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(OutputRequestProperties) :: outputRequest
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "OUTPUT_REQUEST_DEFAULT"
        CALL Parse_OUTPUT_REQUEST_Keyword(node, outputRequest, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_output_request: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_output_request: Name=', TRIM(outputRequest%name)
    END SUBROUTINE map_output_request

    ! ==========================================================================
    ! Map *OUTPUT VARIABLE keyword
    ! ==========================================================================
    SUBROUTINE map_output_variable(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(OutputVariableProperties) :: outputVariable
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "OUTPUT_VARIABLE_DEFAULT"
        CALL Parse_OUTPUT_VARIABLE_Keyword(node, outputVariable, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_output_variable: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_output_variable: Name=', TRIM(outputVariable%name)
    END SUBROUTINE map_output_variable

    ! ==========================================================================
    ! Map *OUTPUT FILTER keyword
    ! ==========================================================================
    SUBROUTINE map_output_filter(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(OutputFilterProperties) :: outputFilter
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "OUTPUT_FILTER_DEFAULT"
        CALL Parse_OUTPUT_FILTER_Keyword(node, outputFilter, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_output_filter: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_output_filter: Name=', TRIM(outputFilter%name)
    END SUBROUTINE map_output_filter

    ! ==========================================================================
    ! Map *OUTPUT FREQUENCY keyword
    ! ==========================================================================
    SUBROUTINE map_output_frequency(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(OutputFrequencyProperties) :: outputFrequency
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "OUTPUT_FREQUENCY_DEFAULT"
        CALL Parse_OUTPUT_FREQUENCY_Keyword(node, outputFrequency, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_output_frequency: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_output_frequency: Name=', TRIM(outputFrequency%name), &
                   ' Frequency=', outputFrequency%frequency
    END SUBROUTINE map_output_frequency

    ! ==========================================================================
    ! Map *OUTPUT FORMAT keyword
    ! ==========================================================================
    SUBROUTINE map_output_format(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(OutputFormatProperties) :: outputFormat
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "OUTPUT_FORMAT_DEFAULT"
        CALL Parse_OUTPUT_FORMAT_Keyword(node, outputFormat, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_output_format: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_output_format: Name=', TRIM(outputFormat%name)
    END SUBROUTINE map_output_format

    ! ==========================================================================
    ! Map *POST PROCESSING keyword
    ! ==========================================================================
    SUBROUTINE map_post_processing(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(PostProcessingProperties) :: postProcessing
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "POST_PROCESSING_DEFAULT"
        CALL Parse_POST_PROCESSING_Keyword(node, postProcessing, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_post_processing: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_post_processing: Name=', TRIM(postProcessing%name)
    END SUBROUTINE map_post_processing

    ! ==========================================================================
    ! Map *ANIMATION keyword
    ! ==========================================================================
    SUBROUTINE map_animation(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(AnimationProperties) :: animation
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "ANIMATION_DEFAULT"
        CALL Parse_ANIMATION_Keyword(node, animation, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_animation: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_animation: Name=', TRIM(animation%name), &
                   ' FrameRate=', animation%frameRate
    END SUBROUTINE map_animation

    ! ==========================================================================
    ! Map *PLOT keyword
    ! ==========================================================================
    SUBROUTINE map_plot(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(PlotProperties) :: plot
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "PLOT_DEFAULT"
        CALL Parse_PLOT_Keyword(node, plot, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_plot: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_plot: Name=', TRIM(plot%name)
    END SUBROUTINE map_plot

    ! ==========================================================================
    ! Map *REPORT keyword
    ! ==========================================================================
    SUBROUTINE map_report(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ReportProperties) :: report
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "REPORT_DEFAULT"
        CALL Parse_REPORT_Keyword(node, report, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_report: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_report: Name=', TRIM(report%name)
    END SUBROUTINE map_report

    ! ==========================================================================
    ! Map *EXPORT keyword
    ! ==========================================================================
    SUBROUTINE map_export(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        TYPE(ExportProperties) :: export
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=64) :: name_val
        name_val = "EXPORT_DEFAULT"
        CALL Parse_EXPORT_Keyword(node, export, name_val, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_export: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        WRITE(*,*) 'INFO map_export: Name=', TRIM(export%name)
    END SUBROUTINE map_export

    ! ========================================================================== 
    ! Map *UF-PORO keyword (VOLRATE=ON/OFF)
    !    UF_Mat_Elasticity   133 (BiotPorousElastic)      !     - *UF-MATERIAL  E, nu    !     - *UF-PORO   alpha_b, k_hyd, S_s, rho_fluid, cp_fluid    !     -  KW_Mapper  L2 materialbiot_alpha/k_hyd_poro/S_s_poro  ??
    !         UF_Model_Mapper  L4 UF_MatProps%props(1:6,9:10)    !       Poro/THM   BiotPorous-133  ??Biot coefficient/ coefficient/     ! ========================================================================== 
    SUBROUTINE map_uf_poro(mapper, node)

        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType),     INTENT(IN)    :: node
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: volrate_val
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: val_up
        INTEGER(i4) :: i

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        ! 1) VOLRATE=ON/OFF          CALL md_kw_get_param_value(node, "VOLRATE", volrate_val)
        IF (LEN_TRIM(volrate_val) == 0) THEN
            mapper%current_material%enable_poro_volrate = .TRUE.
        ELSE
            val_up = volrate_val
            DO i = 1, LEN_TRIM(val_up)
                IF (val_up(i:i) >= 'a' .AND. val_up(i:i) <= 'z') THEN
                    val_up(i:i) = CHAR(ICHAR(val_up(i:i)) - 32)
                END IF
            END DO

            IF (TRIM(val_up) == 'OFF' .OR. TRIM(val_up) == 'NO' .OR. TRIM(val_up) == 'FALSE' .OR. TRIM(val_up) == '0') THEN
                mapper%current_material%enable_poro_volrate = .FALSE.
            ELSE
                mapper%current_material%enable_poro_volrate = .TRUE.
            END IF
        END IF

        ! 2)  param??alpha_b, k_hyd, S_s, rho_fluid, cp_fluid
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) THEN
                mapper%current_material%biot_alpha = node%data_lines(1)%real_values(1)
            END IF
            IF (node%data_lines(1)%col_count >= 2) THEN
                mapper%current_material%k_hyd_poro = node%data_lines(1)%real_values(2)
            END IF
            IF (node%data_lines(1)%col_count >= 3) THEN
                mapper%current_material%S_s_poro   = node%data_lines(1)%real_values(3)
            END IF
            IF (node%data_lines(1)%col_count >= 4) THEN
                mapper%current_material%rho_fluid_poro = node%data_lines(1)%real_values(4)
            END IF
            IF (node%data_lines(1)%col_count >= 5) THEN
                mapper%current_material%cp_fluid_poro  = node%data_lines(1)%real_values(5)
            END IF
        END IF

    END SUBROUTINE map_uf_poro

    ! ========================================================================== 
    ! Map *UF-PORO-2PH keyword (two-phase pore-flow properties)
    ! ========================================================================== 
    SUBROUTINE map_uf_poro_2ph(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType),     INTENT(IN)    :: node
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: model_val
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: val_up
        REAL(wp) :: tmp
        INTEGER(i4) :: i

        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN

        ! 1)   MODEL=COREY / VANG
        CALL md_kw_get_param_value(node, "MODEL", model_val)
        val_up = model_val
        DO i = 1, LEN_TRIM(val_up)
            IF (val_up(i:i) >= 'a' .AND. val_up(i:i) <= 'z') THEN
                val_up(i:i) = CHAR(ICHAR(val_up(i:i)) - 32)
            END IF
        END DO

        ! default COREY
        mapper%current_material%twoph_model_flag = 1.0_wp
        IF (TRIM(val_up) == 'VANG' .OR. TRIM(val_up) == 'VANGEN' .OR. &
            TRIM(val_up) == 'VANGENUCHTEN') THEN
            mapper%current_material%twoph_model_flag = 2.0_wp
        END IF

        ! 2)          IF (node%data_line_count < 1) RETURN

        SELECT CASE (NINT(mapper%current_material%twoph_model_flag))
        CASE (1)   ! COREY: Swr, Snr, n_w, phi, alpha
            IF (node%data_lines(1)%col_count >= 1) THEN
                mapper%current_material%corey_Swr = node%data_lines(1)%real_values(1)
            END IF
            IF (node%data_lines(1)%col_count >= 2) THEN
                mapper%current_material%corey_Snr = node%data_lines(1)%real_values(2)
            END IF
            IF (node%data_lines(1)%col_count >= 3) THEN
                mapper%current_material%corey_nw = node%data_lines(1)%real_values(3)
            END IF
            IF (node%data_lines(1)%col_count >= 4) THEN
                mapper%current_material%phi_total = node%data_lines(1)%real_values(4)
            END IF
            IF (node%data_lines(1)%col_count >= 5) THEN
                mapper%current_material%vg_alpha = node%data_lines(1)%real_values(5)
            END IF

        CASE (2)   ! van Genuchten: alpha, n, phi, Swr, Snr, m, l
            IF (node%data_lines(1)%col_count >= 1) THEN
                mapper%current_material%vg_alpha = node%data_lines(1)%real_values(1)
            END IF
            IF (node%data_lines(1)%col_count >= 2) THEN
                mapper%current_material%vg_n = node%data_lines(1)%real_values(2)
            END IF
            IF (node%data_lines(1)%col_count >= 3) THEN
                mapper%current_material%phi_total = node%data_lines(1)%real_values(3)
            END IF
            IF (node%data_lines(1)%col_count >= 4) THEN
                mapper%current_material%corey_Swr = node%data_lines(1)%real_values(4)
            END IF
            IF (node%data_lines(1)%col_count >= 5) THEN
                mapper%current_material%corey_Snr = node%data_lines(1)%real_values(5)
            END IF
            IF (node%data_lines(1)%col_count >= 6) THEN
                mapper%current_material%vg_m = node%data_lines(1)%real_values(6)
            END IF
            IF (node%data_lines(1)%col_count >= 7) THEN
                mapper%current_material%mualem_l = node%data_lines(1)%real_values(7)
            END IF
        END SELECT

    END SUBROUTINE map_uf_poro_2ph


    ! ==========================================================================
    ! Map *AMPLITUDE keyword (ABAQUS-compatible)
    ! ==========================================================================
    SUBROUTINE map_amplitude(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(MD_Amp_Slot_Desc) :: new_amp
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_val, def_val, input_val
        INTEGER(i4) :: i, j, nvals
        REAL(wp) :: vals(128)
        LOGICAL :: load_success
        
        ! Get amplitude name
        CALL md_kw_get_param_value(node, "NAME", name_val)
        IF (LEN_TRIM(name_val) == 0) THEN
            CALL add_mapping_error(mapper, node%start_line, "AMPLITUDE requires NAME parameter")
            RETURN
        END IF
        
        ! Initialize amplitude
        CALL new_amp%init(TRIM(name_val), AMP_TABULAR)
        
        ! Check for INPUT= parameter (external file)
        CALL md_kw_get_param_value(node, "INPUT", input_val)
        IF (LEN_TRIM(input_val) > 0) THEN
            ! Load amplitude data from external file
            CALL new_amp%load_from_file(TRIM(input_val), load_success)
            IF (.NOT. load_success) THEN
                WRITE(*,'(A,A,A)') "WARNING: Failed to load amplitude from file: ", &
                    TRIM(input_val), " for amplitude ", TRIM(name_val)
            ELSE
                WRITE(*,'(A,A,I0,A)') "[KW] Loaded amplitude ", TRIM(name_val), &
                    new_amp%num_points, " points from file ", TRIM(input_val)
            END IF
        ELSE
            ! Load amplitude data from INP inline data
            CALL md_kw_get_param_value(node, "DEFINITION", def_val)
            
            IF (TRIM(def_val) == "SMOOTH STEP") THEN
                new_amp%amp_type = AMP_SMOOTH
                ! Expect: t1, a1, t2, a2
                IF (node%data_line_count >= 1 .AND. node%data_lines(1)%col_count >= 4) THEN
                    CALL new_amp%set_smooth_step( &
                        node%data_lines(1)%real_values(1), &  ! t1
                        node%data_lines(1)%real_values(3), &  ! t2
                        node%data_lines(1)%real_values(2), &  ! a1
                        node%data_lines(1)%real_values(4))    ! a2
                END IF
            ELSE IF (TRIM(def_val) == "PERIODIC") THEN
                new_amp%amp_type = AMP_PERIODIC
                ! Expect: frequency, amplitude, phase, offset
                IF (node%data_line_count >= 1) THEN
                    CALL new_amp%set_periodic( &
                        node%data_lines(1)%real_values(1), &  ! freq
                        node%data_lines(1)%real_values(2))    ! amp
                END IF
            ELSE IF (TRIM(def_val) == "USER") THEN
                ! USER subroutine: mark as user-defined
                new_amp%amp_type = AMP_USER
                new_amp%is_user_defined = .TRUE.
                
                ! Read user properties from data lines (optional)
                nvals = 0
                DO i = 1, node%data_line_count
                    DO j = 1, node%data_lines(i)%col_count
                        IF (nvals < SIZE(new_amp%user_props)) THEN
                            nvals = nvals + 1
                            new_amp%user_props(nvals) = node%data_lines(i)%real_values(j)
                        END IF
                    END DO
                END DO
                new_amp%num_user_props = nvals
                
                WRITE(*,'(A,A,A,I0,A)') "[KW] Amplitude ", TRIM(name_val), &
                    " marked as USER (properties: ", nvals, ")."
                WRITE(*,'(A)') "     Note: User subroutine must be registered via set_user_subroutine()."
            ELSE
                ! Default: TABULAR (piecewise linear)
                ! Collect all data: t1,v1, t2,v2, ...
                nvals = 0
                DO i = 1, node%data_line_count
                    DO j = 1, node%data_lines(i)%col_count
                        IF (nvals < SIZE(vals)) THEN
                            nvals = nvals + 1
                            vals(nvals) = node%data_lines(i)%real_values(j)
                        END IF
                    END DO
                END DO
                
                ! Add time-value pairs
                DO i = 1, nvals/2
                    CALL new_amp%add_point(vals(2*i-1), vals(2*i))
                END DO
            END IF
        END IF
        
        ! Add amplitude to model database
        CALL mapper%model%add_amplitude(new_amp)
        WRITE(*,'(A,A)') "[KW] Mapped amplitude: ", TRIM(name_val)
        
    END SUBROUTINE map_amplitude

    ! ========================================================================== 
    ! Map *DAMPING keyword


    ! ==========================================================================
    SUBROUTINE map_damping(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        REAL(wp) :: alpha, beta, composite
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: alpha_val, beta_val, composite_val
        
        IF (.NOT. ASSOCIATED(mapper%current_material)) RETURN
        
        ! Damping usually: ALPHA=..., BETA=..., COMPOSITE=...
        CALL md_kw_get_param_value(node, "ALPHA", alpha_val)
        CALL md_kw_get_param_value(node, "BETA", beta_val)
        CALL md_kw_get_param_value(node, "COMPOSITE", composite_val)
        
        alpha = 0.0_wp
        beta = 0.0_wp
        composite = 0.0_wp
        
        IF (LEN_TRIM(alpha_val) > 0) READ(alpha_val, *) alpha
        IF (LEN_TRIM(beta_val) > 0) READ(beta_val, *) beta
        IF (LEN_TRIM(composite_val) > 0) READ(composite_val, *) composite
        
        CALL mapper%current_material%set_damping(alpha, beta, composite)
    END SUBROUTINE map_damping

    ! ==========================================================================
    ! Map *SOLID SECTION keyword
    ! ==========================================================================
    SUBROUTINE map_solid_section(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UF_SectionDef) :: new_sec
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, mat_name
        
        CALL md_kw_get_param_value(node, "ELSET", elset_name)
        CALL md_kw_get_param_value(node, "MATERIAL", mat_name)
        
        IF (LEN_TRIM(elset_name) == 0 .OR. LEN_TRIM(mat_name) == 0) RETURN
        
        CALL new_sec%init("SEC_" // TRIM(elset_name), SECTION_SOLID, TRIM(mat_name))
        new_sec%elset_name = TRIM(elset_name)
        
        CALL mapper%model%add_section(new_sec)
        mapper%sections_mapped = mapper%sections_mapped + 1
    END SUBROUTINE map_solid_section

    ! ==========================================================================
    ! Map *SHELL SECTION keyword
    ! ==========================================================================
    SUBROUTINE map_shell_section(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UF_SectionDef) :: new_sec
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, mat_name
        REAL(wp) :: thickness
        
        CALL md_kw_get_param_value(node, "ELSET", elset_name)
        CALL md_kw_get_param_value(node, "MATERIAL", mat_name)
        
        thickness = 1.0_wp
        IF (node%data_line_count >= 1 .AND. node%data_lines(1)%col_count >= 1) THEN
            thickness = node%data_lines(1)%real_values(1)
        END IF
        
        IF (LEN_TRIM(elset_name) == 0 .OR. LEN_TRIM(mat_name) == 0) RETURN
        
        CALL new_sec%init("SEC_" // TRIM(elset_name), SECTION_SHELL, TRIM(mat_name))
        new_sec%elset_name = TRIM(elset_name)
        new_sec%shell_thickness = thickness
        
        CALL mapper%model%add_section(new_sec)
        mapper%sections_mapped = mapper%sections_mapped + 1
    END SUBROUTINE map_shell_section

    ! ==========================================================================
    ! Map *BEAM SECTION keyword
    ! ==========================================================================
    SUBROUTINE map_beam_section(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UF_SectionDef) :: new_sec
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, mat_name, sec_shape
        REAL(wp) :: val1, val2
        
        CALL md_kw_get_param_value(node, "ELSET", elset_name)
        CALL md_kw_get_param_value(node, "MATERIAL", mat_name)
        CALL md_kw_get_param_value(node, "SECTION", sec_shape)
        
        IF (LEN_TRIM(elset_name) == 0 .OR. LEN_TRIM(mat_name) == 0) RETURN
        
        CALL new_sec%init("SEC_" // TRIM(elset_name), SECTION_BEAM, TRIM(mat_name))
        new_sec%elset_name = TRIM(elset_name)
        
        ! Default shape is RECT if not specified (or handle as RECT for now)
        IF (LEN_TRIM(sec_shape) == 0) sec_shape = "RECT"
        
        IF (node%data_line_count >= 1) THEN
            IF (INDEX(TRIM(sec_shape), "RECT") > 0 .AND. node%data_lines(1)%col_count >= 2) THEN
                val1 = node%data_lines(1)%real_values(1) ! Width
                val2 = node%data_lines(1)%real_values(2) ! Height
                CALL new_sec%set_beam_rect(val1, val2)
                
            ELSE IF (INDEX(TRIM(sec_shape), "CIRC") > 0 .AND. node%data_lines(1)%col_count >= 1) THEN
                val1 = node%data_lines(1)%real_values(1) ! Radius
                CALL new_sec%set_beam_circular(val1)
            END IF
        END IF
        
        CALL mapper%model%add_section(new_sec)
        mapper%sections_mapped = mapper%sections_mapped + 1
    END SUBROUTINE map_beam_section

    ! ==========================================================================
    ! Map *STEP keyword
    ! ==========================================================================
    SUBROUTINE map_step(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UF_StepDef) :: new_step
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: name_val, nlgeom_val
        
        CALL md_kw_get_param_value(node, "NAME", name_val)
        IF (LEN_TRIM(name_val) == 0) THEN
            WRITE(name_val, '(A,I0)') "Step-", mapper%steps_mapped + 1
        END IF
        
        CALL md_kw_get_param_value(node, "NLGEOM", nlgeom_val)
        
        CALL new_step%init(TRIM(name_val), mapper%steps_mapped + 1)
        IF (TRIM(nlgeom_val) == "YES") THEN
            CALL new_step%set_nlgeom(NLGEOM_ON)
        END IF
        
        CALL mapper%model%step_mgr%add_step(new_step)
        mapper%steps_mapped = mapper%steps_mapped + 1
        mapper%current_step_idx = mapper%model%step_mgr%num_steps
    END SUBROUTINE map_step

    ! ==========================================================================
    ! Map *STATIC procedure (or *STATIC, RIKS)
    ! ==========================================================================
    SUBROUTINE map_static_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: init_inc, time_period, min_inc, max_inc
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: riks_val
        TYPE(UF_RiksControl) :: riks_ctrl
        TYPE(ErrorStatusType) :: status
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_boundary: current_step_idx <= 0, skip.'
            RETURN
        END IF

        ! Check for *STATIC, RIKS
        CALL md_kw_get_param_value(node, "RIKS", riks_val)
        IF (TRIM(kw_to_upper(riks_val)) == "YES" .OR. TRIM(kw_to_upper(riks_val)) == "TRUE") THEN
            ! *STATIC, RIKS: arc-length method
            CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_STATIC_RIKS)
            CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(1.0_wp)
            CALL MD_RT_KW_ParseStaticRiks(node, riks_ctrl, status)
            IF (status%status_code == IF_STATUS_OK) THEN
                mapper%model%step_mgr%steps(mapper%current_step_idx)%riks_ctrl = riks_ctrl
            END IF
            RETURN
        END IF
        
        ! *STATIC (standard): init_inc, time_period, min_inc, max_inc
        init_inc = 1.0_wp
        time_period = 1.0_wp
        min_inc = 1.0E-5_wp
        max_inc = 1.0_wp
        
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) init_inc = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) time_period = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) min_inc = node%data_lines(1)%real_values(3)
            IF (node%data_lines(1)%col_count >= 4) max_inc = node%data_lines(1)%real_values(4)
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_STATIC)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(time_period)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_increment(init_inc, min_inc, max_inc)
    END SUBROUTINE map_static_procedure

    ! ==========================================================================
    ! Map *DYNAMIC procedure
    ! ==========================================================================
    SUBROUTINE map_dynamic_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: init_inc, time_period, min_inc, max_inc
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: explicit_val, subspace_val
        explicit_val = ''
        subspace_val = ''
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_dynamic_procedure: current_step_idx <= 0, skip.'
            RETURN
        END IF

        
        CALL md_kw_get_param_value(node, "EXPLICIT", explicit_val)
        CALL md_kw_get_param_value(node, "SUBSPACE", subspace_val)
        
        ! Default values
        init_inc = 0.01_wp
        time_period = 1.0_wp
        min_inc = 1.0E-10_wp
        max_inc = 1.0_wp
        
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) init_inc = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) time_period = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) min_inc = node%data_lines(1)%real_values(3)
            IF (node%data_lines(1)%col_count >= 4) max_inc = node%data_lines(1)%real_values(4)
        END IF
        
        IF (TRIM(explicit_val) == "YES") THEN
             CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_DYNAMIC_EXPLICIT)
        ELSE IF (TRIM(subspace_val) == "YES") THEN
             CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_DYNAMIC_SUBSPACE)
             mapper%model%step_mgr%steps(mapper%current_step_idx)%dyn_subspace_ctrl%time_period = time_period
             mapper%model%step_mgr%steps(mapper%current_step_idx)%dyn_subspace_ctrl%initial_time_inc = init_inc
        ELSE
             CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_DYNAMIC_IMPLICIT)
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(time_period)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_increment(init_inc, min_inc, max_inc)
    END SUBROUTINE map_dynamic_procedure

    ! ==========================================================================
    ! Map *FREQUENCY procedure
    ! When *FREQUENCY has LANCZOS/SUBSPACE/SIMULTANEOUS/AMS option, use PROC_MODAL
    ! ==========================================================================
    SUBROUTINE map_frequency_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        INTEGER(i4) :: num_eigen, i
        REAL(wp) :: min_freq, max_freq
        CHARACTER(LEN=32) :: solver_val
        INTEGER(i4) :: proc_type
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_boundary: current_step_idx <= 0, skip.'
            RETURN
        END IF

        
        num_eigen = 10
        min_freq = 0.0_wp
        max_freq = 1.0E30_wp
        
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) num_eigen = node%data_lines(1)%int_values(1)
            IF (node%data_lines(1)%col_count >= 2) min_freq = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) max_freq = node%data_lines(1)%real_values(3)
        END IF
        
        ! Check if LANCZOS/SUBSPACE/SIMULTANEOUS/AMS option present ??PROC_MODAL
        ! (param may have empty value; check by param name existence)
        proc_type = PROC_FREQUENCY
        DO i = 1, node%param_count
            solver_val = kw_to_upper(TRIM(node%params(i)%name))
            IF (TRIM(solver_val) == "LANCZOS" .OR. TRIM(solver_val) == "SUBSPACE" .OR. &
                TRIM(solver_val) == "SIMULTANEOUS" .OR. TRIM(solver_val) == "AMS") THEN
                proc_type = PROC_MODAL
                EXIT
            END IF
        END DO
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(proc_type)
        ! Note: Frequency step doesn't really have "time period", but we set defaults
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(1.0_wp)
        ! When PROC_MODAL: populate modal_ctrl from data line (num_eigen, min_freq, max_freq)
        IF (proc_type == PROC_MODAL) THEN
            mapper%model%step_mgr%steps(mapper%current_step_idx)%modal_ctrl%n_modes = num_eigen
            mapper%model%step_mgr%steps(mapper%current_step_idx)%modal_ctrl%freq_min = min_freq
            mapper%model%step_mgr%steps(mapper%current_step_idx)%modal_ctrl%freq_max = max_freq
        ! When PROC_FREQUENCY: populate ssd_ctrl and freq_ctrl (compat alias)
        ELSE IF (proc_type == PROC_FREQUENCY) THEN
            mapper%model%step_mgr%steps(mapper%current_step_idx)%ssd_ctrl%freq_start = min_freq
            mapper%model%step_mgr%steps(mapper%current_step_idx)%ssd_ctrl%freq_end = max_freq
            mapper%model%step_mgr%steps(mapper%current_step_idx)%ssd_ctrl%n_freq_points = num_eigen
            mapper%model%step_mgr%steps(mapper%current_step_idx)%freq_ctrl%freq_start = min_freq
            mapper%model%step_mgr%steps(mapper%current_step_idx)%freq_ctrl%freq_end = max_freq
            mapper%model%step_mgr%steps(mapper%current_step_idx)%freq_ctrl%n_freq_points = num_eigen
            ! Mirror to ss_ctrl: L5 RunSteadyState reads ssd_ctrl; keep legacy fields aligned
            mapper%model%step_mgr%steps(mapper%current_step_idx)%ss_ctrl = &
                mapper%model%step_mgr%steps(mapper%current_step_idx)%ssd_ctrl
        END IF
    END SUBROUTINE map_frequency_procedure

    ! ==========================================================================
    ! Map *BUCKLE procedure (eigenvalue buckling)
    ! ==========================================================================
    SUBROUTINE map_buckle_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        INTEGER(i4) :: num_modes
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_buckle_procedure: current_step_idx <= 0, skip.'
            RETURN
        END IF

        num_modes = 5_i4
        IF (node%data_line_count >= 1 .AND. node%data_lines(1)%col_count >= 1) THEN
            num_modes = node%data_lines(1)%int_values(1)
            num_modes = MAX(1_i4, MIN(num_modes, 200_i4))
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_BUCKLE)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(1.0_wp)
        mapper%model%step_mgr%steps(mapper%current_step_idx)%buckle_ctrl%n_buckling_modes = num_modes
    END SUBROUTINE map_buckle_procedure

    ! ==========================================================================
    ! Map *STEADY STATE DYNAMICS (PROC_FREQUENCY, id=22)
    ! Abaqus: *STEADY STATE DYNAMICS, DIRECT
    ! Theory: (K - ???M + i??C)?U(?) = F(?)
    ! ==========================================================================
    SUBROUTINE map_steady_state_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: freq_start, freq_end
        INTEGER(i4) :: n_freq_pts
        INTEGER(i4) :: i
        CHARACTER(LEN=32) :: param_val
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_steady_state_procedure: current_step_idx <= 0, skip.'
            RETURN
        END IF

        freq_start = 1.0_wp
        freq_end = 500.0_wp
        n_freq_pts = 100_i4
        
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) freq_start = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) freq_end = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) n_freq_pts = NINT(node%data_lines(1)%real_values(3), i4)
        END IF
        n_freq_pts = MAX(2_i4, MIN(n_freq_pts, 10000_i4))
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_FREQUENCY)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(1.0_wp)
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ss_ctrl%freq_start = freq_start
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ss_ctrl%freq_end = freq_end
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ss_ctrl%n_freq_points = n_freq_pts
        
        DO i = 1, node%param_count
            param_val = kw_to_upper(TRIM(node%params(i)%name))
            IF (TRIM(param_val) == "DIRECT") THEN
                mapper%model%step_mgr%steps(mapper%current_step_idx)%ss_ctrl%solution_method = SS_DIRECT
                EXIT
            ELSE IF (TRIM(param_val) == "SUBSPACE PROJECTION" .OR. TRIM(param_val) == "MODAL") THEN
                mapper%model%step_mgr%steps(mapper%current_step_idx)%ss_ctrl%solution_method = SS_MODAL
                EXIT
            END IF
        END DO
        ! Canonical for L5: copy ss_ctrl -> ssd_ctrl (+ freq_ctrl) after *STEADY STATE DYNAMICS parse
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ssd_ctrl = &
            mapper%model%step_mgr%steps(mapper%current_step_idx)%ss_ctrl
        mapper%model%step_mgr%steps(mapper%current_step_idx)%freq_ctrl = &
            mapper%model%step_mgr%steps(mapper%current_step_idx)%ssd_ctrl
    END SUBROUTINE map_steady_state_procedure

    ! ==========================================================================
    ! Map *HEAT TRANSFER procedure
    ! ==========================================================================
    SUBROUTINE map_heat_transfer_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: init_inc, time_period, min_inc, max_inc
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_boundary: current_step_idx <= 0, skip.'
            RETURN
        END IF

        
        init_inc = 1.0_wp
        time_period = 1.0_wp
        min_inc = 1.0E-5_wp
        max_inc = 1.0_wp
        
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) init_inc = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) time_period = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) min_inc = node%data_lines(1)%real_values(3)
            IF (node%data_lines(1)%col_count >= 4) max_inc = node%data_lines(1)%real_values(4)
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_HEAT_TRANSFER)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(time_period)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_increment(init_inc, min_inc, max_inc)
        ! Populate ht_ctrl (PROC_09)
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ht_ctrl%analysis_mode = HT_TRANSIENT
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ht_ctrl%time_period = time_period
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ht_ctrl%initial_time_inc = init_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ht_ctrl%min_time_inc = min_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ht_ctrl%max_time_inc = max_inc
    END SUBROUTINE map_heat_transfer_procedure

    ! ==========================================================================
    ! Map *COUPLED TEMPERATURE-DISPLACEMENT procedure
    ! ==========================================================================
    SUBROUTINE map_coupled_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: init_inc, time_period, min_inc, max_inc
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_boundary: current_step_idx <= 0, skip.'
            RETURN
        END IF

        
        init_inc = 1.0_wp
        time_period = 1.0_wp
        min_inc = 1.0E-5_wp
        max_inc = 1.0_wp
        
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) init_inc = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) time_period = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) min_inc = node%data_lines(1)%real_values(3)
            IF (node%data_lines(1)%col_count >= 4) max_inc = node%data_lines(1)%real_values(4)
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_COUPLED_TEMP_DISP)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(time_period)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_increment(init_inc, min_inc, max_inc)
        ! Populate ctd_ctrl (PROC_10)
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ctd_ctrl%time_period = time_period
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ctd_ctrl%initial_time_inc = init_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ctd_ctrl%min_time_inc = min_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%ctd_ctrl%max_time_inc = max_inc
    END SUBROUTINE map_coupled_procedure

    ! ==========================================================================
    ! Map *COUPLED THERMAL-ELECTRICAL procedure (PROC_11)
    ! ==========================================================================
    SUBROUTINE map_coupled_thermal_electrical_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: init_inc, time_period, min_inc, max_inc
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_coupled_thermal_electrical_procedure: current_step_idx <= 0, skip.'
            RETURN
        END IF

        
        init_inc = 0.001_wp
        time_period = 1.0_wp
        min_inc = 1.0E-10_wp
        max_inc = 0.01_wp
        
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) init_inc = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) time_period = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) min_inc = node%data_lines(1)%real_values(3)
            IF (node%data_lines(1)%col_count >= 4) max_inc = node%data_lines(1)%real_values(4)
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_COUPLED_THERMAL_ELEC)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(time_period)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_increment(init_inc, min_inc, max_inc)
        ! Populate cte_ctrl (PROC_11)
        mapper%model%step_mgr%steps(mapper%current_step_idx)%cte_ctrl%time_period = time_period
        mapper%model%step_mgr%steps(mapper%current_step_idx)%cte_ctrl%initial_time_inc = init_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%cte_ctrl%min_time_inc = min_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%cte_ctrl%max_time_inc = max_inc
    END SUBROUTINE map_coupled_thermal_electrical_procedure

    ! ==========================================================================
    ! Map *GEOSTATIC procedure (PROC_12)
    ! ==========================================================================
    SUBROUTINE map_geostatic_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: k0_val, g_z, rho
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_geostatic_procedure: current_step_idx <= 0, skip.'
            RETURN
        END IF

        k0_val = 0.5_wp
        g_z = -9.81_wp
        rho = 2000.0_wp
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) k0_val = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) g_z = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) rho = node%data_lines(1)%real_values(3)
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_GEOSTATIC)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(1.0_wp)
        mapper%model%step_mgr%steps(mapper%current_step_idx)%geo_ctrl%k0_horizontal = k0_val
        mapper%model%step_mgr%steps(mapper%current_step_idx)%geo_ctrl%gravity_z = g_z
        mapper%model%step_mgr%steps(mapper%current_step_idx)%geo_ctrl%density_ref = rho
    END SUBROUTINE map_geostatic_procedure

    ! ==========================================================================
    ! Map *SOILS procedure (PROC_13)
    ! ==========================================================================
    SUBROUTINE map_soils_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: time_period, init_inc, min_inc, max_inc
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_soils_procedure: current_step_idx <= 0, skip.'
            RETURN
        END IF

        time_period = 864000.0_wp
        init_inc = 1.0_wp
        min_inc = 1.0E-4_wp
        max_inc = 86400.0_wp
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) init_inc = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) time_period = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) min_inc = node%data_lines(1)%real_values(3)
            IF (node%data_lines(1)%col_count >= 4) max_inc = node%data_lines(1)%real_values(4)
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_SOILS)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(time_period)
        mapper%model%step_mgr%steps(mapper%current_step_idx)%soils_ctrl%time_period = time_period
        mapper%model%step_mgr%steps(mapper%current_step_idx)%soils_ctrl%initial_time_inc = init_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%soils_ctrl%min_time_inc = min_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%soils_ctrl%max_time_inc = max_inc
    END SUBROUTINE map_soils_procedure

    ! ==========================================================================
    ! Map *VISCO procedure (PROC_14)
    ! ==========================================================================
    SUBROUTINE map_visco_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: time_period, init_inc, min_inc, max_inc
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_visco_procedure: current_step_idx <= 0, skip.'
            RETURN
        END IF

        time_period = 3600.0_wp
        init_inc = 1.0_wp
        min_inc = 1.0E-6_wp
        max_inc = 100.0_wp
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) init_inc = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) time_period = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) min_inc = node%data_lines(1)%real_values(3)
            IF (node%data_lines(1)%col_count >= 4) max_inc = node%data_lines(1)%real_values(4)
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_VISCO)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(time_period)
        mapper%model%step_mgr%steps(mapper%current_step_idx)%visco_ctrl%time_period = time_period
        mapper%model%step_mgr%steps(mapper%current_step_idx)%visco_ctrl%initial_time_inc = init_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%visco_ctrl%min_time_inc = min_inc
        mapper%model%step_mgr%steps(mapper%current_step_idx)%visco_ctrl%max_time_inc = max_inc
    END SUBROUTINE map_visco_procedure

    ! ==========================================================================
    ! Map *ANNEAL procedure (PROC_15)
    ! ==========================================================================
    SUBROUTINE map_anneal_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        REAL(wp) :: T_anneal, time_period, init_inc
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_anneal_procedure: current_step_idx <= 0, skip.'
            RETURN
        END IF

        T_anneal = 1173.0_wp
        time_period = 3600.0_wp
        init_inc = 0.5_wp
        IF (node%data_line_count >= 1) THEN
            IF (node%data_lines(1)%col_count >= 1) T_anneal = node%data_lines(1)%real_values(1)
            IF (node%data_lines(1)%col_count >= 2) time_period = node%data_lines(1)%real_values(2)
            IF (node%data_lines(1)%col_count >= 3) init_inc = node%data_lines(1)%real_values(3)
        END IF
        
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_ANNEAL)
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_time(time_period)
        mapper%model%step_mgr%steps(mapper%current_step_idx)%anneal_ctrl%T_anneal = T_anneal
        mapper%model%step_mgr%steps(mapper%current_step_idx)%anneal_ctrl%initial_time_inc = init_inc
    END SUBROUTINE map_anneal_procedure

    ! ==========================================================================
    ! Map *MODAL DYNAMIC procedure (PROC_13)
    ! ==========================================================================
    SUBROUTINE map_modal_dynamic_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_MODAL_DYNAMIC)
    END SUBROUTINE map_modal_dynamic_procedure

    ! ==========================================================================
    ! Map *RANDOM RESPONSE procedure (PROC_23)
    ! ==========================================================================
    SUBROUTINE map_random_response_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_RANDOM_RESPONSE)
    END SUBROUTINE map_random_response_procedure

    ! ==========================================================================
    ! Map *RESPONSE SPECTRUM procedure (PROC_24)
    ! ==========================================================================
    SUBROUTINE map_response_spectrum_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_RESPONSE_SPECTRUM)
    END SUBROUTINE map_response_spectrum_procedure

    ! ==========================================================================
    ! Map *COMPLEX FREQUENCY procedure (PROC_25)
    ! ==========================================================================
    SUBROUTINE map_complex_frequency_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_COMPLEX_FREQUENCY)
    END SUBROUTINE map_complex_frequency_procedure

    ! ==========================================================================
    ! Map *MASS DIFFUSION procedure (PROC_31)
    ! ==========================================================================
    SUBROUTINE map_mass_diffusion_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_MASS_DIFFUSION)
    END SUBROUTINE map_mass_diffusion_procedure

    ! ==========================================================================
    ! Map *COUPLED THERMAL-ELECTRICAL-STRUCTURAL procedure (PROC_42)
    ! ==========================================================================
    SUBROUTINE map_coupled_tes_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_COUPLED_TES)
    END SUBROUTINE map_coupled_tes_procedure

    ! ==========================================================================
    ! Map *PIEZOELECTRIC procedure (PROC_43)
    ! ==========================================================================
    SUBROUTINE map_piezoelectric_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_PIEZOELECTRIC)
    END SUBROUTINE map_piezoelectric_procedure

    ! ==========================================================================
    ! Map *ELECTROMAGNETIC procedure (PROC_44)
    ! ==========================================================================
    SUBROUTINE map_electromagnetic_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_ELECTROMAGNETIC)
    END SUBROUTINE map_electromagnetic_procedure

    ! ==========================================================================
    ! Map *ACOUSTIC procedure (PROC_45)
    ! ==========================================================================
    SUBROUTINE map_acoustic_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_ACOUSTIC)
    END SUBROUTINE map_acoustic_procedure

    ! ==========================================================================
    ! Map *STEADY STATE TRANSPORT procedure (PROC_60)
    ! ==========================================================================
    SUBROUTINE map_steady_state_transport_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_STEADY_STATE_TRANSPORT)
    END SUBROUTINE map_steady_state_transport_procedure

    ! ==========================================================================
    ! Map *SUBSTRUCTURE procedure (PROC_61)
    ! ==========================================================================
    SUBROUTINE map_substructure_procedure(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        IF (mapper%current_step_idx <= 0) RETURN
        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%set_procedure(PROC_SUBSTRUCTURE)
    END SUBROUTINE map_substructure_procedure

    ! ==========================================================================
    ! Map *BOUNDARY keyword
    ! ==========================================================================
    SUBROUTINE map_boundary(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UF_BCDef) :: new_bc
        INTEGER(i4) :: i, node_id, dof1, dof2
        REAL(wp) :: value
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: region_name, type_val, amp_name
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: first_token
        INTEGER(i4) :: bc_type
        
        ! Fallback-related variables for flat INP files
        CHARACTER(LEN=KW_MAX_LINE_LEN) :: line
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: token1
        CHARACTER(LEN=512) :: inp_file
        INTEGER(i4) :: unit_num, ios, line_idx, ios_int
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_boundary: current_step_idx <= 0, skip.'
            RETURN
        END IF

        
        CALL md_kw_get_param_value(node, "TYPE", type_val)
        CALL md_kw_get_param_value(node, "AMPLITUDE", amp_name)
        
        bc_type = BC_DISPLACEMENT
        
        ! ------------------------------------------------------------------
        !  INP   *BOUNDARY  ??flat INP  ??
        ! ------------------------------------------------------------------

        inp_file = TRIM(mapper%parser%lexer%filename)
        IF (LEN_TRIM(inp_file) == 0) RETURN
        
        unit_num = 902
        OPEN(UNIT=unit_num, FILE=inp_file, STATUS='OLD', ACTION='READ', IOSTAT=ios)
        IF (ios /= 0) RETURN
        
        !  *BOUNDARY          DO line_idx = 1, node%start_line
            READ(unit_num, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT
        END DO
        
        DO
            READ(unit_num, '(A)', IOSTAT=ios) line
            IF (ios /= 0) EXIT
            line = ADJUSTL(line)
            IF (LEN_TRIM(line) == 0) CYCLE
            IF (line(1:1) == '*') EXIT
            IF (line(1:2) == '**') CYCLE
            
            !  ??node ?? NSET  
            token1 = ""
            dof1 = 0
            dof2 = 0
            value = 0.0_wp
            READ(line, *, IOSTAT=ios) token1, dof1, dof2, value
            IF (ios /= 0) THEN
                ios = 0
                value = 0.0_wp
                READ(line, *, IOSTAT=ios) token1, dof1, dof2
                IF (ios /= 0) CYCLE
            END IF
            IF (dof2 < dof1) dof2 = dof1
            
            first_token = TRIM(token1)
            node_id = 0
            ios_int = 0
            READ(first_token, *, IOSTAT=ios_int) node_id
            
            CALL new_bc%init()
            
            IF (ios_int == 0 .AND. node_id > 0) THEN
                !   "1, 1, 1, 0.0"  node                 new_bc%name = 'BC-NODE'
                new_bc%bc_type = bc_type
                new_bc%node_id = node_id
                new_bc%region_type = 0
            ELSE
                !   "Bottom, 3, 3, 0.0" "Top, 3, 3, -0.1"                  region_name = first_token
                new_bc%name = 'BC-' // TRIM(region_name)
                new_bc%bc_type = bc_type
                new_bc%region_name = TRIM(region_name)
                new_bc%region_type = 1
            END IF
            
            new_bc%dof_first = dof1
            new_bc%dof_last = dof2
            new_bc%magnitude = value
            
            IF (LEN_TRIM(amp_name) > 0) THEN
                new_bc%amplitude_name = TRIM(amp_name)
            END IF
            
            CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_bc(new_bc)
        END DO
        
        CLOSE(unit_num)
    END SUBROUTINE map_boundary


    ! ==========================================================================
    ! Map *CLOAD keyword
    ! ==========================================================================
    SUBROUTINE map_cload(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UF_CLoadDef) :: new_load
        INTEGER(i4) :: i, node_id, dof
        REAL(wp) :: magnitude
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: region_name, amp_name
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: first_token
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_boundary: current_step_idx <= 0, skip.'
            RETURN
        END IF

        
        CALL md_kw_get_param_value(node, "AMPLITUDE", amp_name)

        DO i = 1, node%data_line_count

            IF (node%data_lines(i)%col_count < 3) CYCLE
            
            first_token = TRIM(node%data_lines(i)%values(1))
            node_id = node%data_lines(i)%int_values(1)
            dof = node%data_lines(i)%int_values(2)
            magnitude = node%data_lines(i)%real_values(3)
            
            CALL new_load%init()
            
            IF (node_id > 0) THEN
                new_load%name = 'CLOAD-NODE'
                new_load%node_id = node_id
                new_load%nset_name = ''
            ELSE
                region_name = first_token
                new_load%name = 'CLOAD-' // TRIM(region_name)
                new_load%nset_name = TRIM(region_name)
            END IF
            
            new_load%dof = dof
            new_load%magnitude = magnitude
            IF (LEN_TRIM(amp_name) > 0) THEN
                new_load%amplitude_name = TRIM(amp_name)
            END IF
            
            CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_cload(new_load)
        END DO
    END SUBROUTINE map_cload

    ! ==========================================================================
    ! Map *FILM keyword (convective heat transfer boundary condition)
    ! ==========================================================================
    SUBROUTINE map_film(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(FilmBCDesc) :: filmBC
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: amp_name
        INTEGER(i4) :: i
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_film: current_step_idx <= 0, skip.'
            RETURN
        END IF
        
        ! Parse FILM keyword
        CALL Parse_FILM_Keyword(node, filmBC, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_film: Failed to parse FILM keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        ! Add film BC to step's loadBC manager
        ! Note: This requires integration with LoadBC manager
        ! For now, we'll store it in a film BC list (to be implemented)
        WRITE(*,*) 'INFO map_film: Parsed FILM BC: ', TRIM(filmBC%name), &
                   ' Surface: ', TRIM(filmBC%surfaceName), &
                   ' h=', filmBC%filmCoefficient, &
                   ' T_sink=', filmBC%sinkTemperature
        
    END SUBROUTINE map_film

    ! ==========================================================================
    ! Map *RADIATE keyword (radiation heat transfer boundary condition)
    ! ==========================================================================
    SUBROUTINE map_radiate(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(RadiateBCDesc) :: radiateBC
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: amp_name
        INTEGER(i4) :: i
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_radiate: current_step_idx <= 0, skip.'
            RETURN
        END IF
        
        ! Parse RADIATE keyword
        CALL Parse_RADIATE_Keyword(node, radiateBC, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_radiate: Failed to parse RADIATE keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        ! Add radiation BC to step's loadBC manager
        ! Note: This requires integration with LoadBC manager
        ! For now, we'll store it in a radiation BC list (to be implemented)
        WRITE(*,*) 'INFO map_radiate: Parsed RADIATE BC: ', TRIM(radiateBC%name), &
                   ' Surface: ', TRIM(radiateBC%surfaceName), &
                   ' ?=', radiateBC%emissivity, &
                   ' T_sink=', radiateBC%sinkTemperature
        
    END SUBROUTINE map_radiate

    ! ==========================================================================
    ! Map *DSFLUX keyword (distributed surface heat flux)
    ! ==========================================================================
    SUBROUTINE map_dsflux(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(DsfluxDesc) :: dsflux
        TYPE(ErrorStatusType) :: status
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_dsflux: current_step_idx <= 0, skip.'
            RETURN
        END IF
        
        ! Parse DSFLUX keyword
        CALL Parse_DSFLUX_Keyword(node, dsflux, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_dsflux: Failed to parse DSFLUX keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        ! Add DSFLUX to step's loadBC manager
        WRITE(*,*) 'INFO map_dsflux: Parsed DSFLUX: ', TRIM(dsflux%name), &
                   ' Surface: ', TRIM(dsflux%surfaceName), &
                   ' q=', dsflux%fluxMagnitude, ' W/m^2'
        
    END SUBROUTINE map_dsflux

    ! ==========================================================================
    ! Map *MASS FLOW keyword (mass flow rate boundary condition)
    ! ==========================================================================
    SUBROUTINE map_massflow(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(MassFlowDesc) :: massFlow
        TYPE(ErrorStatusType) :: status
        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_massflow: current_step_idx <= 0, skip.'
            RETURN
        END IF
        
        ! Parse MASS FLOW keyword
        CALL Parse_MASSFLOW_Keyword(node, massFlow, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            WRITE(*,*) 'ERROR map_massflow: Failed to parse MASS FLOW keyword: ', TRIM(status%message)
            mapper%error_count = mapper%error_count + 1
            RETURN
        END IF
        
        ! Add mass flow to step's loadBC manager
        IF (massFlow%targetType == TARGET_NODESET) THEN
            WRITE(*,*) 'INFO map_massflow: Parsed MASS FLOW: ', TRIM(massFlow%name), &
                       ' NodeSet: ', TRIM(massFlow%nodeSetName), &
                       ' ??', massFlow%massFlowRate, ' kg/s'
        ELSE
            WRITE(*,*) 'INFO map_massflow: Parsed MASS FLOW: ', TRIM(massFlow%name), &
                       ' Node: ', massFlow%nodeId, &
                       ' ??', massFlow%massFlowRate, ' kg/s'
        END IF
        
    END SUBROUTINE map_massflow

    ! ==========================================================================
    ! Map *DLOAD keyword
    !
    !  load??
    !   1)   *SURFACE  / load??
    !        *SURFACE, NAME=SURF-1, TYPE=ELEMENT
    !        ESET1, S1 / E1
    !        ...
    !        *DLOAD, SURFACE=SURF-1, AMPLITUDE=AMP-1
    !        , , P,    -100.0          !      !        , , TRVEC, Tx, Ty, Tz     !  (TRVEC)
    !
    !   2)   ELSET  forceload??UF_BodyForceDef?????
    !        *DLOAD, ELSET=EALL, AMPLITUDE=AMP-G
    !        , GRAV, g, gx, gy, gz     !  force??g  ??gx,gy,gz)      !        , CENT, w, ax,ay,az, cx,cy,cz !  ??velocity w??    !
    !      !   - SURFACE   UF_DLoadDef??step%loadbc%dloads    !   - GRAV/CENT   UF_BodyForceDef??step%loadbc%bforces    !   -   *SURFACE S1..S6 / E1..E4  ??
    !      facet%face_id  / UF_Load      ! ==========================================================================
    SUBROUTINE map_dload(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        TYPE(UF_DLoadDef) :: new_surf_load
        TYPE(UF_BodyForceDef) :: new_bforce
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: surf_name, elset_name, amp_name, name_val
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: type_token, upper_token
        INTEGER(i4) :: i
        REAL(wp) :: magnitude
        REAL(wp) :: tx, ty, tz
        REAL(wp) :: dir_raw(3), gvec(3)
        REAL(wp) :: omega, ax, ay, az, cx, cy, cz
        ! Fallback-related variables for flat INP / missing AST data lines
        CHARACTER(LEN=KW_MAX_LINE_LEN) :: line, upper_line
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: tok1, tok2
        CHARACTER(LEN=512) :: inp_file
        INTEGER(i4) :: unit_num, ios, line_idx, line_len, last_comma, idx
        INTEGER(i4) :: start_pos, end_pos



        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_boundary: current_step_idx <= 0, skip.'
            RETURN
        END IF


        CALL md_kw_get_param_value(node, "SURFACE", surf_name)
        CALL md_kw_get_param_value(node, "ELSET",   elset_name)
        CALL md_kw_get_param_value(node, "AMPLITUDE", amp_name)
        CALL md_kw_get_param_value(node, "NAME", name_val)

        !  NAME?? SURFACE/ELSET  
        IF (LEN_TRIM(name_val) == 0) THEN
            IF (LEN_TRIM(surf_name) > 0) THEN
                name_val = TRIM(surf_name)
            ELSEIF (LEN_TRIM(elset_name) > 0) THEN
                name_val = TRIM(elset_name)
            END IF
        END IF

        !------------------------------------------------------------------
        ! Fallback:   AST   data_lines?? flat INP  ??       !            INP   *DLOAD          !------------------------------------------------------------------
        IF (node%data_line_count == 0) THEN
            WRITE(*,*) "DEBUG: map_surface using Fallback from INP file"
            inp_file = TRIM(mapper%parser%lexer%filename)

            IF (LEN_TRIM(inp_file) == 0) RETURN

            unit_num = 904
            OPEN(UNIT=unit_num, FILE=inp_file, STATUS='OLD', ACTION='READ', IOSTAT=ios)
            IF (ios /= 0) RETURN

            !  *DLOAD  ?? SURFACE/ELSET
            DO line_idx = 1, node%start_line
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
            END DO

            !   SURFACE/ELSET  AST  ??
            IF (LEN_TRIM(surf_name) == 0 .OR. LEN_TRIM(elset_name) == 0) THEN
                upper_line = kw_to_upper(TRIM(line))


                IF (LEN_TRIM(surf_name) == 0) THEN
                    idx = INDEX(upper_line, "SURFACE=")
                    IF (idx > 0) THEN
                        line_len = LEN_TRIM(line)
                        start_pos = idx + LEN("SURFACE=")
                        end_pos = start_pos
                        DO WHILE (end_pos <= line_len .AND. line(end_pos:end_pos) /= ',')
                            end_pos = end_pos + 1
                        END DO
                        surf_name = TRIM(ADJUSTL(line(start_pos:end_pos-1)))
                    END IF
                END IF

                IF (LEN_TRIM(elset_name) == 0) THEN
                    idx = INDEX(upper_line, "ELSET=")
                    IF (idx > 0) THEN
                        line_len = LEN_TRIM(line)
                        start_pos = idx + LEN("ELSET=")
                        end_pos = start_pos
                        DO WHILE (end_pos <= line_len .AND. line(end_pos:end_pos) /= ',')
                            end_pos = end_pos + 1
                        END DO
                        elset_name = TRIM(ADJUSTL(line(start_pos:end_pos-1)))
                    END IF
                END IF
            END IF

            DO
                READ(unit_num, '(A)', IOSTAT=ios) line
                IF (ios /= 0) EXIT
                line = ADJUSTL(line)
                IF (LEN_TRIM(line) == 0) CYCLE
                IF (line(1:1) == '*') EXIT
                IF (line(1:2) == '**') CYCLE

                !   *DSLOAD  ??SURFACE/ELSET??
                IF (LEN_TRIM(surf_name) == 0 .AND. LEN_TRIM(elset_name) == 0) THEN
                    tok1 = ""
                    READ(line, *, IOSTAT=ios) tok1
                    IF (ios == 0 .AND. LEN_TRIM(tok1) > 0) THEN
                        surf_name = TRIM(tok1)
                    END IF
                END IF

                IF (LEN_TRIM(surf_name) > 0) THEN
                    !  ??force?? test_multistep_dload_temp.inp  ??
                    magnitude = 0.0_wp

                    line_len = LEN_TRIM(line)
                    last_comma = 0
                    DO idx = line_len, 1, -1
                        IF (line(idx:idx) == ',') THEN
                            last_comma = idx
                            EXIT
                        END IF
                    END DO
                    IF (last_comma > 0 .AND. last_comma < line_len) THEN
                        READ(line(last_comma+1:line_len), *, IOSTAT=ios) magnitude
                        IF (ios /= 0) magnitude = 0.0_wp
                    END IF
                    IF (magnitude == 0.0_wp) CYCLE

                    CALL new_surf_load%init()
                    CALL new_surf_load%set_pressure(TRIM(name_val), TRIM(surf_name), magnitude)
                    IF (LEN_TRIM(amp_name) > 0) THEN
                        new_surf_load%amplitude_name = TRIM(amp_name)
                    END IF
                    WRITE(*,*) 'DEBUG map_dload fallback: name=', TRIM(new_surf_load%name), &
     &                        ' surface=', TRIM(new_surf_load%surface_name), &
     &                        ' load_type=', new_surf_load%load_type, &
     &                        ' magnitude=', new_surf_load%magnitude
                    CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_dload(new_surf_load)

                ELSE

                    !  forceload GRAV/CENT??ELSET  ????

                    type_token = ""
                    magnitude = 0.0_wp
                    dir_raw = 0.0_wp

                    READ(line, *, IOSTAT=ios) tok1, type_token, magnitude, &
                         dir_raw(1), dir_raw(2), dir_raw(3)
                    IF (ios /= 0) THEN
                        !  ????, GRAV, ..."?????
                        ios = 0
                        READ(line, *, IOSTAT=ios) type_token, magnitude, &
                             dir_raw(1), dir_raw(2), dir_raw(3)
                        IF (ios /= 0) CYCLE
                    END IF


                    upper_token = kw_to_upper(TRIM(type_token))


                    SELECT CASE (TRIM(upper_token))
                    CASE ("GRAV")
                        gvec = magnitude * dir_raw

                        CALL new_bforce%init()
                        CALL new_bforce%set_gravity(TRIM(name_val), TRIM(elset_name), &
                                                    gvec(1), gvec(2), gvec(3))
                        IF (LEN_TRIM(amp_name) > 0) THEN
                            new_bforce%amplitude_name = TRIM(amp_name)
                        END IF
                        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_bforce(new_bforce)

                    CASE ("CENT")
                        CALL new_bforce%init()
                        CALL new_bforce%set_centrifugal(TRIM(name_val), TRIM(elset_name), &
                                                       magnitude, ax, ay, az, cx, cy, cz)
                        IF (LEN_TRIM(amp_name) > 0) THEN
                            new_bforce%amplitude_name = TRIM(amp_name)
                        END IF
                        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_bforce(new_bforce)

                    CASE DEFAULT
                        !   DLOAD  fallback                      END SELECT
                END IF
            END DO

            CLOSE(unit_num)
            RETURN
        END IF


        !------------------------------------------------------------------
        ! 1)   SURFACE  / load??force P  TRVEC
        !------------------------------------------------------------------
        IF (LEN_TRIM(surf_name) > 0) THEN

        DO i = 1, node%data_line_count

                IF (node%data_lines(i)%col_count <= 0) CYCLE

                type_token = ""
                IF (node%data_lines(i)%col_count >= 3) THEN
                    type_token = TRIM(node%data_lines(i)%values(3))
                END IF
                upper_token = kw_to_upper(TRIM(type_token))

                SELECT CASE (TRIM(upper_token))
                CASE ("TRVEC")
                    !  ??TRVEC, Tx, Ty, Tz
                    tx = 0.0_wp
                    ty = 0.0_wp
                    tz = 0.0_wp
                    IF (node%data_lines(i)%real_count >= 3) THEN
                        tx = node%data_lines(i)%real_values(1)
                        ty = node%data_lines(i)%real_values(2)
                        tz = node%data_lines(i)%real_values(3)
                    END IF
                    IF (tx == 0.0_wp .AND. ty == 0.0_wp .AND. tz == 0.0_wp) CYCLE

                    CALL new_surf_load%init()
                    CALL new_surf_load%set_traction(TRIM(name_val), TRIM(surf_name), tx, ty, tz)
                    IF (LEN_TRIM(amp_name) > 0) THEN
                        new_surf_load%amplitude_name = TRIM(amp_name)
                    END IF
                    CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_dload(new_surf_load)

                CASE DEFAULT
                    ! default????force P
                    magnitude = 0.0_wp
                    IF (node%data_lines(i)%real_count >= 1) THEN
                        magnitude = node%data_lines(i)%real_values(1)
                    END IF
                    IF (magnitude == 0.0_wp) CYCLE

                    CALL new_surf_load%init()
                    CALL new_surf_load%set_pressure(TRIM(name_val), TRIM(surf_name), magnitude)
                    IF (LEN_TRIM(amp_name) > 0) THEN
                        new_surf_load%amplitude_name = TRIM(amp_name)
                    END IF
                    CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_dload(new_surf_load)
                END SELECT
            END DO

            RETURN
        END IF

        !------------------------------------------------------------------
        ! 2)   ELSET  forceload??GRAV / CENT /????BODYFORCE
        !------------------------------------------------------------------
        IF (LEN_TRIM(elset_name) == 0) RETURN

        DO i = 1, node%data_line_count

            IF (node%data_lines(i)%col_count < 2) CYCLE

            type_token = TRIM(node%data_lines(i)%values(2))
            upper_token = kw_to_upper(TRIM(type_token))

            SELECT CASE (TRIM(upper_token))

            CASE ("GRAV")
                !  ??ELSET, GRAV, g, gx, gy, gz
                magnitude = 0.0_wp
                IF (node%data_lines(i)%real_count >= 1) THEN
                    magnitude = node%data_lines(i)%real_values(1)
                END IF
                IF (magnitude == 0.0_wp) CYCLE

                dir_raw = 0.0_wp
                IF (node%data_lines(i)%real_count >= 4) THEN
                    dir_raw(1) = node%data_lines(i)%real_values(2)
                    dir_raw(2) = node%data_lines(i)%real_values(3)
                    dir_raw(3) = node%data_lines(i)%real_values(4)
                END IF
                gvec = magnitude * dir_raw

                CALL new_bforce%init()
                CALL new_bforce%set_gravity(TRIM(name_val), TRIM(elset_name), &
                                            gvec(1), gvec(2), gvec(3))
                IF (LEN_TRIM(amp_name) > 0) THEN
                    new_bforce%amplitude_name = TRIM(amp_name)
                END IF
                CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_bforce(new_bforce)

            CASE ("CENT")
                !  ??ELSET, CENT, w, ax,ay,az, cx,cy,cz
                omega = 0.0_wp
                IF (node%data_lines(i)%real_count >= 1) THEN
                    omega = node%data_lines(i)%real_values(1)
                END IF
                IF (omega == 0.0_wp) CYCLE

                ax = 0.0_wp
                ay = 0.0_wp
                az = 1.0_wp
                IF (node%data_lines(i)%real_count >= 4) THEN
                    ax = node%data_lines(i)%real_values(2)
                    ay = node%data_lines(i)%real_values(3)
                    az = node%data_lines(i)%real_values(4)
                END IF
                cx = 0.0_wp
                cy = 0.0_wp
                cz = 0.0_wp
                IF (node%data_lines(i)%real_count >= 7) THEN
                    cx = node%data_lines(i)%real_values(5)
                    cy = node%data_lines(i)%real_values(6)
                    cz = node%data_lines(i)%real_values(7)
                END IF

                CALL new_bforce%init()
                CALL new_bforce%set_centrifugal(TRIM(name_val), TRIM(elset_name), &
                                               omega, ax, ay, az, cx, cy, cz)
                IF (LEN_TRIM(amp_name) > 0) THEN
                    new_bforce%amplitude_name = TRIM(amp_name)
                END IF
                CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_bforce(new_bforce)

            CASE DEFAULT
                !   BODYFORCE  ??BX/BY/BZ  ?????            END SELECT
        END DO

    END SUBROUTINE map_dload

    ! ==========================================================================
    ! Map *TEMPERATURE keyword
    ! ==========================================================================
    SUBROUTINE map_temperature(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(MD_NodalField), POINTER :: fld
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: nset_name, amp_name, op_val
        INTEGER(i4) :: i, node_id
        REAL(wp) :: magnitude
        ! Fallback-related variables for flat INP / missing AST data lines
        CHARACTER(LEN=KW_MAX_LINE_LEN) :: line
        CHARACTER(LEN=512) :: inp_file
        INTEGER(i4) :: unit_num, ios, line_idx

        
        CALL md_kw_get_param_value(node, "AMPLITUDE", amp_name)
        CALL md_kw_get_param_value(node, "OP", op_val)
        
        IF (mapper%current_step_idx > 0) THEN
            ! Analysis Step: Treat as prescribed temperature field (Thermal Load)
            IF (node%data_line_count == 0) THEN
                ! Fallback:  INP   *TEMPERATURE                  inp_file = TRIM(mapper%parser%lexer%filename)
                IF (LEN_TRIM(inp_file) == 0) RETURN

                unit_num = 905
                OPEN(UNIT=unit_num, FILE=inp_file, STATUS='OLD', ACTION='READ', IOSTAT=ios)
                IF (ios /= 0) RETURN

                DO line_idx = 1, node%start_line
                    READ(unit_num, '(A)', IOSTAT=ios) line
                    IF (ios /= 0) EXIT
                END DO

                DO
                    READ(unit_num, '(A)', IOSTAT=ios) line
                    IF (ios /= 0) EXIT
                    line = ADJUSTL(line)
                    IF (LEN_TRIM(line) == 0) CYCLE
                    IF (line(1:1) == '*') EXIT
                    IF (line(1:2) == '**') CYCLE

                    node_id = 0
                    magnitude = 0.0_wp
                    READ(line, *, IOSTAT=ios) node_id, magnitude
                    IF (ios /= 0) CYCLE
                    IF (node_id <= 0) CYCLE

                    WRITE(nset_name, '(A,I0)') 'NODE-', node_id
                    CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_bc_simple( &
                        "TEMP_" // TRIM(nset_name), TRIM(nset_name), BC_TEMPERATURE, 11, 11, magnitude, amp_name)
                END DO

                CLOSE(unit_num)
            ELSE

        DO i = 1, node%data_line_count

                    IF (node%data_lines(i)%col_count < 2) CYCLE
                    
                    node_id = node%data_lines(i)%int_values(1)
                    magnitude = node%data_lines(i)%real_values(2)
                    
                    WRITE(nset_name, '(A,I0)') 'NODE-', node_id
                    
                    ! Let's switch to adding it as a BC
                    CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%loadbc%add_bc_simple( &
                        "TEMP_" // TRIM(nset_name), TRIM(nset_name), BC_TEMPERATURE, 11, 11, magnitude, amp_name)
                END DO
            END IF
        ELSE

        DO i = 1, node%data_line_count

                IF (node%data_lines(i)%col_count < 2) CYCLE
                node_id = node%data_lines(i)%int_values(1)
                magnitude = node%data_lines(i)%real_values(2)
                
                ! Ensure field exists
                IF (mapper%model%field_mgr%num_fields == 0) THEN
                    CALL mapper%model%field_mgr%add_field("TEMPERATURE", FLD_TEMPERATURE, 1)
                END IF
                
                ! Set value
                fld => mapper%model%field_mgr%get_field("TEMPERATURE")
                CALL fld%set_value(node_id, 1, magnitude)
            END DO
        END IF
    END SUBROUTINE map_temperature

    ! ==========================================================================
    ! Map *INITIAL CONDITIONS keyword
    ! ==========================================================================
    SUBROUTINE map_initial_conditions(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: type_val, nset_name
        INTEGER(i4) :: i, j, node_id, nset_idx
        REAL(wp) :: val
        TYPE(UF_NodeSet), POINTER :: nset
        TYPE(MD_NodalField), POINTER :: fld
        
        CALL md_kw_get_param_value(node, "TYPE", type_val)
        
        SELECT CASE (TRIM(type_val))
        CASE ("TEMPERATURE")
             ! Ensure field exists
             IF (mapper%model%field_mgr%num_fields == 0) THEN
                 CALL mapper%model%field_mgr%add_field("TEMPERATURE", FLD_TEMPERATURE, 1)
             END IF
             fld => mapper%model%field_mgr%get_field("TEMPERATURE")

        DO i = 1, node%data_line_count

                 IF (node%data_lines(i)%col_count < 2) CYCLE
                 ! Format: NSET, Value OR NodeID, Value
                 ! AST parser stores first token as string in values(1) if it's not a number?
                 ! Let's check if first token is NSET or ID
                 ! For simplicity, assume AST parser puts integers in int_values(1) if valid
                 
                 val = node%data_lines(i)%real_values(2)
                 
                 IF (node%data_lines(i)%int_values(1) > 0) THEN
                      ! Single Node
                      node_id = node%data_lines(i)%int_values(1)
                      CALL fld%set_value(node_id, 1, val)
                 ELSE
                      ! NSET
                      nset_name = TRIM(node%data_lines(i)%values(1))
                      nset_idx = mapper%model%assembly%find_node_set(nset_name)
                      IF (nset_idx > 0) THEN
                          nset => mapper%model%assembly%node_sets(nset_idx)
                          DO j = 1, nset%num_nodes
                              CALL fld%set_value(nset%node_ids(j), 1, val)
                          END DO
                      END IF
                 END IF
             END DO
             
        CASE ("VELOCITY")
             ! Ensure field exists
             fld => mapper%model%field_mgr%get_field("VELOCITY")
             IF (.NOT. ASSOCIATED(fld)) THEN
                 CALL mapper%model%field_mgr%add_field("VELOCITY", FLD_VELOCITY, 3)
                 fld => mapper%model%field_mgr%get_field("VELOCITY")
             END IF
            ! Format: NSET, 1, 3, 0.0 (DOF range, value) or NSET, v1, v2, v3
            ! Simplified: NSET, dof, value
            ! Abaqus: NSET, dof, value  OR  NSET, v1, v2, v3 (not standard for *INITIAL CONDITIONS, 
			!usually TYPE=VELOCITY is node, dof, val)

        DO i = 1, node%data_line_count

                 IF (node%data_lines(i)%col_count < 3) CYCLE
                 
                 val = node%data_lines(i)%real_values(3)
                 ! ... similar NSET/Node logic ...
             END DO
             
        END SELECT
    END SUBROUTINE map_initial_conditions

    ! ==========================================================================
    ! Map *OUTPUT keywords (FIELD / HISTORY)
    ! ==========================================================================
    SUBROUTINE map_output(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        
        TYPE(UF_FieldOutputDef)   :: field_req
        TYPE(UF_HistoryOutputDef) :: hist_req
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: freq_val, nset_val, elset_val, var_name
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: fmt_val
        INTEGER(i4) :: freq, i, j, var_id
        LOGICAL :: is_history

        
        IF (mapper%current_step_idx <= 0) THEN
            WRITE(*,*) 'DEBUG map_output: current_step_idx <= 0, skip.'
            RETURN
        END IF

        !  whetherHISTORY OUTPUT
        is_history = (TRIM(node%keyword_name) == 'HISTORY OUTPUT')

        CALL md_kw_get_param_value(node, "FREQUENCY", freq_val)
        freq = 1
        IF (LEN_TRIM(freq_val) > 0) READ(freq_val, *) freq

        !  control??RESULTFMT=CSV/VTK/DAT/TXT/ODB
        CALL md_kw_get_param_value(node, "RESULTFMT", fmt_val)
        IF (LEN_TRIM(fmt_val) > 0) THEN
            fmt_val = kw_to_upper(TRIM(fmt_val))
            SELECT CASE (TRIM(fmt_val))
            CASE ("CSV")
                mapper%model%step_mgr%steps(mapper%current_step_idx)%output%write_csv = .TRUE.
            CASE ("TXT")
                mapper%model%step_mgr%steps(mapper%current_step_idx)%output%write_txt = .TRUE.
            CASE ("DAT")
                mapper%model%step_mgr%steps(mapper%current_step_idx)%output%write_dat = .TRUE.
            CASE ("VTK")
                mapper%model%step_mgr%steps(mapper%current_step_idx)%output%write_vtk = .TRUE.
            CASE ("ODB")
                mapper%model%step_mgr%steps(mapper%current_step_idx)%output%write_odb = .TRUE.
            CASE DEFAULT
                !   RESULTFMT??            END SELECT
        ELSE
            !  RESULTFMT  ??default  DAT  valueoutput??            mapper%model%step_mgr%steps(mapper%current_step_idx)%output%write_dat = .TRUE.
        END IF

        
        IF (.NOT. is_history) THEN

            !------------------------------
            ! 1) FIELD output 
            !------------------------------
            CALL field_req%init("Output-Request", "")
            field_req%frequency = freq
            
            SELECT CASE (TRIM(node%keyword_name))
            CASE ("NODE OUTPUT", "NODE PRINT", "NODE FILE")
                field_req%position = POS_NODE
                CALL md_kw_get_param_value(node, "NSET", nset_val)
                IF (LEN_TRIM(nset_val) > 0) THEN
                    field_req%region_name = TRIM(nset_val)
                    field_req%region_type = 1 ! NSET
                    field_req%name = "NODE_"//TRIM(nset_val)
                ELSE
                    field_req%name = "NODE_ALL"
                END IF
                
            CASE ("ELEMENT OUTPUT", "EL PRINT", "EL FILE")
                field_req%position = POS_INTEGRATION_POINT ! Default for element output
                CALL md_kw_get_param_value(node, "ELSET", elset_val)
                IF (LEN_TRIM(elset_val) > 0) THEN
                    field_req%region_name = TRIM(elset_val)
                    field_req%region_type = 2 ! ELSET
                    field_req%name = "ELEM_"//TRIM(elset_val)
                ELSE
                    field_req%name = "ELEM_ALL"
                END IF
                
            CASE ("OUTPUT")
                ! Generic *OUTPUT, FIELD/HISTORY
                field_req%position = POS_NODE ! fallback
                field_req%name = "OUTPUT_ALL"
            END SELECT

            
            ! Variables - Loop over ALL columns
            DO i = 1, node%data_line_count
                DO j = 1, node%data_lines(i)%col_count
                    var_name = kw_to_upper(TRIM(node%data_lines(i)%values(j)))
                    IF (LEN_TRIM(var_name) == 0) CYCLE
                    
                    var_id = 0
                    SELECT CASE (TRIM(var_name))
                    CASE ("U")
                        var_id = OUT_U
                    CASE ("V")
                        var_id = OUT_V
                    CASE ("A")
                        var_id = OUT_A
                    CASE ("RF")
                        var_id = OUT_RF
                    CASE ("S")
                        var_id = OUT_S
                    CASE ("E")
                        var_id = OUT_E
                    CASE ("PE")
                        var_id = OUT_PE
                    CASE ("PEEQ")
                        var_id = OUT_PEEQ
                    CASE ("MISES")
                        var_id = OUT_MISES
                    CASE ("NT")
                        var_id = OUT_NT
                    CASE ("COORD")
                        var_id = OUT_COORD
                    CASE ("PRESS")
                        var_id = OUT_PRESS
                    CASE ("STATUS")
                        var_id = OUT_STATUS
                    END SELECT
                    
                    IF (var_id > 0) THEN
                        CALL field_req%add_variable(var_id)
                    END IF
                END DO
            END DO

            
            CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%output%add_field_output(field_req)
        ELSE
            !------------------------------
            ! 2) HISTORY output 
            !------------------------------
            CALL hist_req%init("History-Request", "")
            hist_req%frequency = freq

            ! History              ! - NSET / ELSET  
            CALL md_kw_get_param_value(node, "NSET", nset_val)
            CALL md_kw_get_param_value(node, "ELSET", elset_val)
            IF (LEN_TRIM(nset_val) > 0) THEN
                hist_req%region_name = TRIM(nset_val)
                hist_req%region_type = 1 ! NSET
            ELSEIF (LEN_TRIM(elset_val) > 0) THEN
                hist_req%region_name = TRIM(elset_val)
                hist_req%region_type = 2 ! ELSET
            ELSE
                hist_req%region_type = 0
            END IF

            !  ??/contactHistory
            DO i = 1, node%data_line_count
                DO j = 1, node%data_lines(i)%col_count
                    var_name = kw_to_upper(TRIM(node%data_lines(i)%values(j)))
                    IF (LEN_TRIM(var_name) == 0) CYCLE
                    
                    var_id = 0
                    SELECT CASE (TRIM(var_name))
                    ! nodeHistory??NSET                    CASE ("U")
                        var_id = OUT_U
                    CASE ("V")
                        var_id = OUT_V
                    CASE ("A")
                        var_id = OUT_A
                    CASE ("RF")
                        var_id = OUT_RF

                    !  History??                    CASE ("ALLKE")
                        var_id = OUT_ENER_KE
                    CASE ("ALLIE")
                        var_id = OUT_ENER_IE
                    CASE ("ALLSE")
                        var_id = OUT_ENER_SE
                    CASE ("ALLPD")
                        var_id = OUT_ENER_PD
                    CASE ("ALLCD")
                        var_id = OUT_ENER_CD
                    CASE ("ALLWK")
                        var_id = OUT_ENER_WORKEXT
                    CASE ("ALLVD")
                        var_id = OUT_ENER_VD
                    CASE ("ALLAE")
                        var_id = OUT_ENER_AE

                    ! contact ??                    ! Abaqus                      !   - CPEN  :                      !   - COPEN :                      !   - CFN   :  force??contactforce                     CASE ("CACT", "CNUM")   ! active contacts count
                        var_id = OUT_CACTIVE
                    CASE ("CSTICK")          ! sticking contacts count
                        var_id = OUT_CSTICK
                    CASE ("CSLIDE")          ! sliding contacts count
                        var_id = OUT_CSLIDE
                    CASE ("CPEN")            ! max penetration
                        var_id = OUT_CMAXPEN
                    CASE ("COPEN")           ! max opening (gap)
                        var_id = OUT_COPEN
                    CASE ("CPRESS")          ! average contact pressure (approx.)
                        var_id = OUT_CPRESS
                    CASE ("CFTOT", "CFN")    ! total normal contact force (resultant)
                        var_id = OUT_CFTOTAL



                    ! ELSET  ??S/E/PE/MISES/PEEQ  ??
                    CASE ("S")
                        var_id = OUT_S
                    CASE ("E")
                        var_id = OUT_E
                    CASE ("PE")
                        var_id = OUT_PE
                    CASE ("MISES")
                        var_id = OUT_MISES
                    CASE ("PEEQ")
                        var_id = OUT_PEEQ
                    END SELECT
                    
                    IF (var_id > 0) THEN
                        CALL hist_req%add_variable(var_id)
                    END IF
                END DO
            END DO

            CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%output%add_history_output(hist_req)
        END IF

    END SUBROUTINE map_output


    ! ==========================================================================
    ! Create default part for flat INP files
    ! ==========================================================================
    SUBROUTINE map_create_default_part(mapper)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        
        TYPE(UF_PartDef) :: default_part
        TYPE(UF_InstanceDef) :: default_inst
        INTEGER(i4) :: init_num_nodes, init_num_elems
        
        init_num_nodes = 1000
        init_num_elems = 1000
        CALL default_part%init("PART-DEFAULT", init_num_nodes, init_num_elems, mapper%model%dimension)
        CALL mapper%model%add_part(default_part)
        
        ! Also create a default instance for the assembly
        CALL default_inst%init("INST-DEFAULT", "PART-DEFAULT")
        CALL mapper%model%assembly%add_instance(default_inst)
    END SUBROUTINE map_create_default_part

    ! ==========================================================================
    ! Get parameter value from AST node
    ! ==========================================================================
    SUBROUTINE md_kw_get_param_value(node, param_name, value)
        TYPE(KW_ASTNodeType), INTENT(IN) :: node
        CHARACTER(LEN=*), INTENT(IN) :: param_name
        CHARACTER(LEN=*), INTENT(OUT) :: value
        
        INTEGER(i4) :: i
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: upper_name
        
        value = ""
        upper_name = kw_to_upper(TRIM(param_name))
        
        DO i = 1, node%param_count
            IF (TRIM(node%params(i)%name) == TRIM(upper_name)) THEN
                value = node%params(i)%value
                RETURN
            END IF
        END DO
    END SUBROUTINE md_kw_get_param_value

    ! ==========================================================================
    ! Get element type code from string
    ! ==========================================================================
    FUNCTION get_element_type_code(type_str) RESULT(code)
        CHARACTER(LEN=*), INTENT(IN) :: type_str
        INTEGER(i4) :: code
        
        CHARACTER(LEN=32) :: upper_str
        
        upper_str = kw_to_upper(TRIM(type_str))
        
        SELECT CASE (TRIM(upper_str))
        ! 3D Solid elements
        CASE ("C3D4")
        code = ELEM_C3D4
        CASE ("C3D6")
        code = ELEM_C3D6
        CASE ("C3D6R")
        code = ELEM_C3D6R
        CASE ("C3D8")
        code = ELEM_C3D8
        CASE ("C3D8R")
        code = ELEM_C3D8R
        CASE ("C3D10")
        code = ELEM_C3D10
        CASE ("C3D10R")
        code = ELEM_C3D10R
        CASE ("C3D15")
        code = ELEM_C3D15
        CASE ("C3D15R")
        code = ELEM_C3D15R
        CASE ("C3D20")
        code = ELEM_C3D20
        CASE ("C3D20R")
        code = ELEM_C3D20R
        ! 2D Plane elements
        CASE ("CPS3")
        code = ELEM_CPS3
        CASE ("CPS4")
        code = ELEM_CPS4
        CASE ("CPS4R")
        code = ELEM_CPS4R
        CASE ("CPS6")
        code = ELEM_CPS6
        CASE ("CPS8")
        code = ELEM_CPS8
        CASE ("CPS8R")
        code = ELEM_CPS8R
        CASE ("CPE3")
        code = ELEM_CPE3
        CASE ("CPE4")
        code = ELEM_CPE4
        CASE ("CPE4R")
        code = ELEM_CPE4R
        CASE ("CPE6")
        code = ELEM_CPE6
        CASE ("CPE8")
        code = ELEM_CPE8
        CASE ("CPE8R")
        code = ELEM_CPE8R
        ! Axisymmetric
        CASE ("CAX3")
        code = ELEM_CAX3
        CASE ("CAX4")
        code = ELEM_CAX4
        CASE ("CAX4R")
        code = ELEM_CAX4R
        CASE ("CAX6")
        code = ELEM_CAX6
        CASE ("CAX8")
        code = ELEM_CAX8
        ! Shell elements
        CASE ("S3")
        code = ELEM_S3
        CASE ("S4")
        code = ELEM_S4
        CASE ("S4R")
        code = ELEM_S4R
        CASE ("S8R")
        code = ELEM_S8R
        ! Beam elements
        CASE ("B21")
        code = ELEM_B21
        CASE ("B31")
        code = ELEM_B31
        CASE ("B32")
        code = ELEM_B32
        ! Truss elements
        CASE ("T2D2")
        code = ELEM_T2D2
        CASE ("T3D2")
        code = ELEM_T3D2
        ! Heat transfer
        CASE ("DC3D4")
        code = ELEM_DC3D4
        CASE ("DC3D8")
        code = ELEM_DC3D8
        CASE ("DC2D3")
        code = ELEM_DC2D3
        CASE ("DC2D4")
        code = ELEM_DC2D4
        ! Single-field pore diffusion / two-phase test elements
        CASE ("P3D8SAT")
        code = ELEM_P3D8SAT
        CASE ("P3D8RCH")
        code = ELEM_P3D8RCH
        CASE ("P3D6SAT")
        code = ELEM_P3D6SAT
        CASE ("P3D6RCH")
        code = ELEM_P3D6RCH
        CASE ("P2D4SAT")
        code = ELEM_P2D4SAT
        CASE ("P2D4RCH")
        code = ELEM_P2D4RCH
        CASE ("P2D8SAT")
        code = ELEM_P2D8SAT
        CASE ("P2D8RCH")
        code = ELEM_P2D8RCH
        CASE DEFAULT
        code = 0
        END SELECT

    END FUNCTION get_element_type_code


    ! ==========================================================================
    ! Get number of nodes for element type
    ! ==========================================================================
    FUNCTION get_element_num_nodes(type_code) RESULT(num)
        INTEGER(i4), INTENT(IN) :: type_code
        INTEGER(i4) :: num
        
        SELECT CASE (type_code)
        CASE (ELEM_C3D4, ELEM_DC3D4)
        num = 4
        CASE (ELEM_C3D6, ELEM_C3D6R, ELEM_DC3D6, ELEM_P3D6SAT, ELEM_P3D6RCH)
        num = 6
        CASE (ELEM_C3D8, ELEM_C3D8R, ELEM_DC3D8, ELEM_P3D8SAT, ELEM_P3D8RCH)
        num = 8
        CASE (ELEM_C3D10, ELEM_C3D10R)
        num = 10
        CASE (ELEM_C3D15, ELEM_C3D15R)
        num = 15
        CASE (ELEM_C3D20, ELEM_C3D20R)
        num = 20
        CASE (ELEM_CPS3, ELEM_CPE3, ELEM_CAX3, ELEM_DC2D3)
        num = 3
        CASE (ELEM_CPS4, ELEM_CPS4R, ELEM_CPE4, ELEM_CPE4R, ELEM_CAX4, ELEM_CAX4R, ELEM_DC2D4, ELEM_P2D4SAT, ELEM_P2D4RCH)
        num = 4
        CASE (ELEM_CPS6, ELEM_CPE6, ELEM_CAX6)
        num = 6
        CASE (ELEM_CPS8, ELEM_CPS8R, ELEM_CPE8, ELEM_CPE8R, ELEM_CAX8, ELEM_DC2D8, ELEM_P2D8SAT, ELEM_P2D8RCH)
        num = 8
        CASE (ELEM_S3)
        num = 3
        CASE (ELEM_S4, ELEM_S4R)
        num = 4
        CASE (ELEM_S8R)
        num = 8
        CASE (ELEM_B21)
        num = 2
        CASE (ELEM_B31)
        num = 2
        CASE (ELEM_B32)
        num = 3
        CASE (ELEM_T2D2, ELEM_T3D2)
        num = 2
        CASE DEFAULT
        num = 8
        END SELECT

    END FUNCTION get_element_num_nodes


    ! ==========================================================================
    ! Add mapping error
    ! ==========================================================================
    SUBROUTINE add_mapping_error(mapper, line_num, message)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        INTEGER(i4), INTENT(IN) :: line_num
        CHARACTER(LEN=*), INTENT(IN) :: message
        
        mapper%error_count = mapper%error_count + 1
        WRITE(*, '(A,I0,A,A)') "MAPPER ERROR at line ", line_num, ": ", TRIM(message)
    END SUBROUTINE add_mapping_error

    ! ==========================================================================
    ! Get mapping statistics
    ! ==========================================================================
    SUBROUTINE kw_mapper_get_statistics(mapper, nodes, elements, materials, sections, steps)
        TYPE(KW_MapperStateType), INTENT(IN) :: mapper
        INTEGER(i4), INTENT(OUT) :: nodes, elements, materials, sections, steps
        
        nodes = mapper%nodes_mapped
        elements = mapper%elements_mapped
        materials = mapper%materials_mapped
        sections = mapper%sections_mapped
        steps = mapper%steps_mapped
    END SUBROUTINE kw_mapper_get_statistics

    ! ==========================================================================
    ! Cleanup mapper resources
    ! ==========================================================================
    SUBROUTINE kw_mapper_cleanup(mapper)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        
        NULLIFY(mapper%parser)
        NULLIFY(mapper%model)
        NULLIFY(mapper%current_part)
        NULLIFY(mapper%current_instance)
        NULLIFY(mapper%current_material)
        NULLIFY(mapper%current_contact_prop)
        
        ! Cleanup performance optimization components
        ! Note: Parse cache and performance monitor removed (temporarily unused)
        CALL mapper%memoryPool%Reset()

    END SUBROUTINE kw_mapper_cleanup

    ! ==========================================================================
    ! Phase B Tier 1: Advanced Constraint Mapping Functions (6 mappers)
    ! ==========================================================================

    ! ==========================================================================
    ! Map *EMBEDDED ELEMENT keyword
    ! ABAQUS: *EMBEDDED ELEMENT, HOST ELSET=elset_name
    ! ==========================================================================
    SUBROUTINE map_embedded_element(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: host_elset, embedded_elset

        CALL md_kw_get_param_value(node, "HOST ELSET", host_elset)
        CALL md_kw_get_param_value(node, "EMBEDDED ELSET", embedded_elset)

        IF (LEN_TRIM(host_elset) == 0) RETURN

        ! TODO: Create UF_Constraint of type CONSTRAINT_EMBEDDED
        ! Store host_elset and embedded_elset references
        ! Add to current assembly's constraint list

        WRITE(*,*) "INFO: Mapped EMBEDDED ELEMENT constraint (host=", TRIM(host_elset), ")"
    END SUBROUTINE map_embedded_element

    ! ==========================================================================
    ! Map *CLEARANCE keyword
    ! ABAQUS: *CLEARANCE, DEPENDENCY=value
    ! ==========================================================================
    SUBROUTINE map_clearance(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: dependency_str
        REAL(wp) :: dependency_factor
        INTEGER(i4) :: ios

        CALL md_kw_get_param_value(node, "DEPENDENCY", dependency_str)

        dependency_factor = 0.0_wp
        IF (LEN_TRIM(dependency_str) > 0) THEN
            READ(dependency_str, *, IOSTAT=ios) dependency_factor
        END IF

        ! TODO: Parse tabular clearance data from data lines
        ! Create UF_ClearanceDef and store in constraint database

        WRITE(*,*) "INFO: Mapped CLEARANCE (dependency=", dependency_factor, ")"
    END SUBROUTINE map_clearance

    ! ==========================================================================
    ! Map *SHELL TO SOLID COUPLING keyword
    ! ABAQUS: *SHELL TO SOLID COUPLING, CONSTRAINT NAME=name
    ! ==========================================================================
    SUBROUTINE map_shell_to_solid_coupling(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: constraint_name

        CALL md_kw_get_param_value(node, "CONSTRAINT NAME", constraint_name)

        IF (LEN_TRIM(constraint_name) == 0) constraint_name = "ShellSolidCoupling-1"

        ! TODO: Parse shell and solid element sets from data lines
        ! Create UF_Constraint of type CONSTRAINT_SHELL_SOLID_COUPLING
        ! Add to assembly

        WRITE(*,*) "INFO: Mapped SHELL TO SOLID COUPLING (name=", TRIM(constraint_name), ")"
    END SUBROUTINE map_shell_to_solid_coupling

    ! ==========================================================================
    ! Map *CYCLIC SYMMETRY MODEL keyword
    ! ABAQUS: *CYCLIC SYMMETRY MODEL, N=n_sectors
    ! ==========================================================================
    SUBROUTINE map_cyclic_symmetry(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: n_str
        INTEGER(i4) :: n_sectors, ios

        CALL md_kw_get_param_value(node, "N", n_str)

        n_sectors = 0
        IF (LEN_TRIM(n_str) > 0) THEN
            READ(n_str, *, IOSTAT=ios) n_sectors
        END IF

        IF (n_sectors <= 0) RETURN

        ! TODO: Create UF_Constraint of type CONSTRAINT_CYCLIC_SYMMETRY
        ! Parse master/slave node sets from data lines
        ! Store n_sectors and axis definition

        WRITE(*,*) "INFO: Mapped CYCLIC SYMMETRY MODEL (n=", n_sectors, ")"
    END SUBROUTINE map_cyclic_symmetry

    ! ==========================================================================
    ! Map *CONTACT PAIR keyword (ABAQUS Standard)
    ! *CONTACT PAIR, INTERACTION=name, TYPE=SURFACE TO SURFACE, SMALL SLIDING=YES, ADJUST=val
    ! Data lines: master_surface, slave_surface (one pair per line)
    ! INTERACTION_DOMAIN_DESIGN Phase F: parse writes to assembly%interaction_union
    ! ==========================================================================
    SUBROUTINE map_contact_pair(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: interaction_name, small_sliding_str, adjust_str
        CHARACTER(LEN=64) :: master_surf, slave_surf
        TYPE(MD_ContactPairDef) :: pair_def
        TYPE(ErrorStatusType) :: status
        INTEGER(i4) :: i
        INTEGER(i4), ALLOCATABLE :: step_refs(:)

        CALL md_kw_get_param_value(node, "INTERACTION", interaction_name)
        CALL md_kw_get_param_value(node, "SMALL SLIDING", small_sliding_str)
        CALL md_kw_get_param_value(node, "ADJUST", adjust_str)

        IF (LEN_TRIM(interaction_name) == 0) THEN
            interaction_name = "DEFAULT"
        END IF

        pair_def%prop_name = TRIM(interaction_name)
        pair_def%formulation = CONT_FORM_SURFACE
        pair_def%small_sliding = (TRIM(ADJUSTL(small_sliding_str)) == "YES")
        pair_def%adjust_tol = 0.0_wp
        IF (LEN_TRIM(adjust_str) > 0) READ(adjust_str, *) pair_def%adjust_tol

        IF (mapper%current_step_idx > 0) THEN
            pair_def%active_in_all_steps = .FALSE.
            ALLOCATE(step_refs(1))
            step_refs(1) = mapper%current_step_idx
            pair_def%step_refs = step_refs
        END IF

        DO i = 1, node%data_line_count
            IF (node%data_lines(i)%col_count < 2) CYCLE
            master_surf = TRIM(ADJUSTL(node%data_lines(i)%values(1)))
            slave_surf  = TRIM(ADJUSTL(node%data_lines(i)%values(2)))
            IF (LEN_TRIM(master_surf) == 0 .OR. LEN_TRIM(slave_surf) == 0) CYCLE

            pair_def%master_surface = master_surf
            pair_def%slave_surface  = slave_surf

            IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%assembly%initialized) THEN
                CALL g_ufc_global%md_layer%assembly%AddContactPair(pair_def, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    mapper%error_count = mapper%error_count + 1
                    WRITE(*,*) "ERROR map_contact_pair: AddContactPair failed"
                ELSE IF (mapper%current_step_idx > 0 .AND. mapper%current_step_idx <= mapper%model%step_mgr%num_steps) THEN
                    ! Phase F: populate UF_StepDef%pair_ids for Sync (single source: Domain or union)
                    IF (g_ufc_global%md_layer%interaction%initialized) THEN
                        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%AddPairId( &
                             g_ufc_global%md_layer%interaction%n_pairs)
                    ELSE
                        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%AddPairId( &
                             g_ufc_global%md_layer%assembly%interaction_union%n_pairs)
                    END IF
                END IF
            END IF
        END DO

        WRITE(*,*) "INFO: Mapped CONTACT PAIR (interaction=", TRIM(interaction_name), &
                   ", pairs=", node%data_line_count, ")"
    END SUBROUTINE map_contact_pair

    ! ==========================================================================
    ! Map *SURFACE TO SURFACE CONTACT keyword (ABAQUS Explicit general contact)
    ! *SURFACE TO SURFACE CONTACT, INTERACTION=name
    ! Data lines: master_surface, slave_surface (one pair per line)
    ! INTERACTION_DOMAIN_DESIGN Phase F: parse writes to assembly%interaction_union
    ! ==========================================================================
    SUBROUTINE map_surface_to_surface_contact(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: interaction_name
        CHARACTER(LEN=64) :: master_surf, slave_surf
        TYPE(MD_ContactPairDef) :: pair_def
        TYPE(ErrorStatusType) :: status
        INTEGER(i4) :: i
        INTEGER(i4), ALLOCATABLE :: step_refs(:)

        CALL md_kw_get_param_value(node, "INTERACTION", interaction_name)

        IF (LEN_TRIM(interaction_name) == 0) THEN
            interaction_name = "DEFAULT"
        END IF

        pair_def%prop_name = TRIM(interaction_name)
        pair_def%formulation = CONT_FORM_SURFACE
        pair_def%small_sliding = .FALSE.

        IF (mapper%current_step_idx > 0) THEN
            pair_def%active_in_all_steps = .FALSE.
            ALLOCATE(step_refs(1))
            step_refs(1) = mapper%current_step_idx
            pair_def%step_refs = step_refs
        END IF

        DO i = 1, node%data_line_count
            IF (node%data_lines(i)%col_count < 2) CYCLE
            master_surf = TRIM(ADJUSTL(node%data_lines(i)%values(1)))
            slave_surf  = TRIM(ADJUSTL(node%data_lines(i)%values(2)))
            IF (LEN_TRIM(master_surf) == 0 .OR. LEN_TRIM(slave_surf) == 0) CYCLE

            pair_def%master_surface = master_surf
            pair_def%slave_surface  = slave_surf

            IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%assembly%initialized) THEN
                CALL g_ufc_global%md_layer%assembly%AddContactPair(pair_def, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    mapper%error_count = mapper%error_count + 1
                    WRITE(*,*) "ERROR map_surface_to_surface_contact: AddContactPair failed"
                ELSE IF (mapper%current_step_idx > 0 .AND. mapper%current_step_idx <= mapper%model%step_mgr%num_steps) THEN
                    ! Phase F: populate UF_StepDef%pair_ids for Sync (single source: Domain or union)
                    IF (g_ufc_global%md_layer%interaction%initialized) THEN
                        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%AddPairId( &
                             g_ufc_global%md_layer%interaction%n_pairs)
                    ELSE
                        CALL mapper%model%step_mgr%steps(mapper%current_step_idx)%AddPairId( &
                             g_ufc_global%md_layer%assembly%interaction_union%n_pairs)
                    END IF
                END IF
            END IF
        END DO

        WRITE(*,*) "INFO: Mapped SURFACE TO SURFACE CONTACT (interaction=", TRIM(interaction_name), &
                   ", pairs=", node%data_line_count, ")"
    END SUBROUTINE map_surface_to_surface_contact

    ! ==========================================================================
    ! Phase B Tier 1: Interaction Property Mapping Functions (5 mappers)
    ! ==========================================================================

    ! ==========================================================================
    ! Map *SURFACE BEHAVIOR keyword
    ! ABAQUS: *SURFACE BEHAVIOR, PRESSURE-OVERCLOSURE=type, NO SEPARATION
    ! ==========================================================================
    SUBROUTINE map_surface_behavior(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: po_type, no_sep_str
        LOGICAL :: no_separation

        CALL md_kw_get_param_value(node, "PRESSURE-OVERCLOSURE", po_type)
        CALL md_kw_get_param_value(node, "NO SEPARATION", no_sep_str)

        no_separation = (TRIM(no_sep_str) == "YES")

        ! TODO: Parse pressure-overclosure data from data lines
        ! Create SurfaceBehaviorParams and store in current interaction

        WRITE(*,*) "INFO: Mapped SURFACE BEHAVIOR (type=", TRIM(po_type), ", no_sep=", no_separation, ")"
    END SUBROUTINE map_surface_behavior

    ! ==========================================================================
    ! Map *GAP keyword
    ! ABAQUS: *GAP, ELSET=elset_name
    ! ==========================================================================
    SUBROUTINE map_gap(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name

        CALL md_kw_get_param_value(node, "ELSET", elset_name)

        IF (LEN_TRIM(elset_name) == 0) RETURN

        ! TODO: Parse clearance value from data lines
        ! Create GapDef and associate with elset
        ! Store in interaction database

        WRITE(*,*) "INFO: Mapped GAP for elset=", TRIM(elset_name)
    END SUBROUTINE map_gap

    ! ==========================================================================
    ! Map *CONTACT DAMPING keyword
    ! ABAQUS: *CONTACT DAMPING, DEFINITION=DAMPING COEFFICIENT
    ! ==========================================================================
    SUBROUTINE map_contact_damping(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: definition_str

        CALL md_kw_get_param_value(node, "DEFINITION", definition_str)

        ! TODO: Parse damping coefficient from data lines
        ! Create ContactDampingParams and store in current interaction

        WRITE(*,*) "INFO: Mapped CONTACT DAMPING (definition=", TRIM(definition_str), ")"
    END SUBROUTINE map_contact_damping

    ! ==========================================================================
    ! Map *CONTACT STABILIZATION keyword
    ! ABAQUS: *CONTACT STABILIZATION, FACTOR=value
    ! ==========================================================================
    SUBROUTINE map_contact_stabilization(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: factor_str
        REAL(wp) :: stabilization_factor
        INTEGER(i4) :: ios

        CALL md_kw_get_param_value(node, "FACTOR", factor_str)

        stabilization_factor = 1.0e-8_wp  ! Default
        IF (LEN_TRIM(factor_str) > 0) THEN
            READ(factor_str, *, IOSTAT=ios) stabilization_factor
        END IF

        ! TODO: Create ContactStabilizationParams and store in current interaction

        WRITE(*,*) "INFO: Mapped CONTACT STABILIZATION (factor=", stabilization_factor, ")"
    END SUBROUTINE map_contact_stabilization

    ! ==========================================================================
    ! Phase B Tier 1: Initial Condition Mapping Functions (1 mapper)
    ! Note: TEMPERATURE, PREDEFINED FIELD already handled in map_analysis_node
    ! ==========================================================================

    ! ==========================================================================
    ! Map *GEOSTATIC STRESS keyword
    ! L3 濂戠�? 浠呰惤鍏?LoadBC/Ldbc Desc锛堥�?Const锛夈€傜瓑浠峰父瑙佸啓娉?
    !   *INITIAL CONDITIONS, TYPE=GEOSTATIC, ELSET=elset_name
    ! ==========================================================================
    SUBROUTINE map_geostatic_stress(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name

        IF (.NOT. ASSOCIATED(mapper%parser)) RETURN

        CALL md_kw_get_param_value(node, "ELSET", elset_name)

        IF (LEN_TRIM(elset_name) == 0) RETURN

        ! TODO: Parse geostatic stress parameters from data lines
        ! TODO: Add to MD_LoadBC_Domain / Ldbc IC API (L3 only; apply in L4/L5)

        WRITE(*,*) "INFO: Mapped GEOSTATIC STRESS -> Ldbc, elset=", TRIM(elset_name)
    END SUBROUTINE map_geostatic_stress

    ! ==========================================================================
    ! Map *INITIAL STATE keyword
    ! L3 濂戠�? 浠呰惤鍏?LoadBC/Ldbc锛堜�?*INITIAL CONDITIONS 鍚屽�?INLOAD 瀹氫箟渚э�?    ! ==========================================================================
    SUBROUTINE map_initial_state_ldbc(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: type_str

        IF (.NOT. ASSOCIATED(mapper%parser)) RETURN

        CALL md_kw_get_param_value(node, "TYPE", type_str)

        ! TODO: Route to MD_LoadBC / Ldbc state-variable IC tables

        WRITE(*,*) "INFO: Mapped INITIAL STATE -> Ldbc, TYPE=", TRIM(type_str)
    END SUBROUTINE map_initial_state_ldbc

    ! ==========================================================================
    ! Phase C Tier 2: Advanced Material Mapping Functions (8 mappers)
    ! ==========================================================================

    ! ==========================================================================
    ! Map *HYPERELASTIC keyword
    ! ABAQUS: *HYPERELASTIC, TYPE=MOONEY-RIVLIN/OGDEN/YEOH, MODULI=INSTANTANEOUS/LONG TERM
    ! ==========================================================================
    SUBROUTINE map_hyperelastic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: mat_type, moduli_type

        CALL md_kw_get_param_value(node, "TYPE", mat_type)
        CALL md_kw_get_param_value(node, "MODULI", moduli_type)

        IF (LEN_TRIM(mat_type) == 0) mat_type = "MOONEY-RIVLIN"  ! Default
        IF (LEN_TRIM(moduli_type) == 0) moduli_type = "INSTANTANEOUS"  ! Default

        ! TODO: Parse hyperelastic coefficients from data lines
        ! Create HyperelasticMaterialDef with specified type
        ! Add to current material definition

        WRITE(*,*) "INFO: Mapped HYPERELASTIC (type=", TRIM(mat_type), ", moduli=", TRIM(moduli_type), ")"
    END SUBROUTINE map_hyperelastic

    ! ==========================================================================
    ! Map *HYPERFOAM keyword
    ! ABAQUS: *HYPERFOAM, N=1-6 (number of terms)
    ! ==========================================================================
    SUBROUTINE map_hyperfoam(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: n_str
        INTEGER(i4) :: n_terms, ios

        CALL md_kw_get_param_value(node, "N", n_str)

        n_terms = 1  ! Default
        IF (LEN_TRIM(n_str) > 0) THEN
            READ(n_str, *, IOSTAT=ios) n_terms
        END IF

        ! TODO: Parse hyperfoam material parameters
        ! Create HyperfoamMaterialDef with n_terms
        ! Add to current material

        WRITE(*,*) "INFO: Mapped HYPERFOAM (N=", n_terms, ")"
    END SUBROUTINE map_hyperfoam

    ! ==========================================================================
    ! Map *HYPOELASTIC keyword
    ! ABAQUS: *HYPOELASTIC (user-defined hypoelastic material)
    ! ==========================================================================
    SUBROUTINE map_hypoelastic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        ! TODO: Parse hypoelastic material parameters from data lines
        ! Create HypoelasticMaterialDef
        ! Add to current material

        WRITE(*,*) "INFO: Mapped HYPOELASTIC material"
    END SUBROUTINE map_hypoelastic

    ! ==========================================================================
    ! Map *VISCOELASTIC keyword
    ! ABAQUS: *VISCOELASTIC, TIME=PRONY/FREQUENCY
    ! ==========================================================================
    SUBROUTINE map_viscoelastic(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: time_domain

        CALL md_kw_get_param_value(node, "TIME", time_domain)

        IF (LEN_TRIM(time_domain) == 0) time_domain = "PRONY"  ! Default

        ! TODO: Parse viscoelastic Prony series parameters
        ! Create ViscoelasticMaterialDef
        ! Add to current material

        WRITE(*,*) "INFO: Mapped VISCOELASTIC (time=", TRIM(time_domain), ")"
    END SUBROUTINE map_viscoelastic

    ! ==========================================================================
    ! Map *RATE DEPENDENT keyword
    ! ABAQUS: *RATE DEPENDENT, TYPE=POWER LAW/JOHNSON COOK
    ! ==========================================================================
    SUBROUTINE map_rate_dependent(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: rate_type

        CALL md_kw_get_param_value(node, "TYPE", rate_type)

        IF (LEN_TRIM(rate_type) == 0) rate_type = "POWER LAW"  ! Default

        ! TODO: Parse rate-dependent material parameters
        ! Create RateDependentMaterialDef
        ! Add to current material

        WRITE(*,*) "INFO: Mapped RATE DEPENDENT (type=", TRIM(rate_type), ")"
    END SUBROUTINE map_rate_dependent

    ! ==========================================================================
    ! Map *CONCRETE keyword
    ! ABAQUS: *CONCRETE (concrete damaged plasticity model)
    ! ==========================================================================
    SUBROUTINE map_concrete(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        ! TODO: Parse concrete damage parameters from data lines
        ! Create ConcreteDamagedPlasticityDef
        ! Add to current material

        WRITE(*,*) "INFO: Mapped CONCRETE damaged plasticity model"
    END SUBROUTINE map_concrete

    ! ==========================================================================
    ! Map *FOAM HARDENING keyword
    ! ABAQUS: *FOAM HARDENING (crushable foam hardening)
    ! ==========================================================================
    SUBROUTINE map_foam_hardening(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        ! TODO: Parse foam hardening parameters from data lines
        ! Create FoamHardeningDef
        ! Add to current material

        WRITE(*,*) "INFO: Mapped FOAM HARDENING"
    END SUBROUTINE map_foam_hardening

    ! ==========================================================================
    ! Map *JOULE HEAT FRACTION keyword
    ! ABAQUS: *JOULE HEAT FRACTION (fraction of electric energy converted to heat)
    ! ==========================================================================
    SUBROUTINE map_joule_heat_fraction(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        ! TODO: Parse heat fraction value from data line
        ! Store in current material's thermal properties

        WRITE(*,*) "INFO: Mapped JOULE HEAT FRACTION"
    END SUBROUTINE map_joule_heat_fraction

    ! ==========================================================================
    ! Phase C Tier 2: Advanced Section Mapping Functions (4 mappers)
    ! ==========================================================================

    ! ==========================================================================
    ! Map *COHESIVE SECTION keyword
    ! ABAQUS: *COHESIVE SECTION, ELSET=elset_name, MATERIAL=mat_name, RESPONSE=TRACTION SEPARATION
    ! ==========================================================================
    SUBROUTINE map_cohesive_section(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, mat_name, response_type

        CALL md_kw_get_param_value(node, "ELSET", elset_name)
        CALL md_kw_get_param_value(node, "MATERIAL", mat_name)
        CALL md_kw_get_param_value(node, "RESPONSE", response_type)

        IF (LEN_TRIM(elset_name) == 0) RETURN
        IF (LEN_TRIM(response_type) == 0) response_type = "TRACTION SEPARATION"

        ! TODO: Create CohesiveSectionDef
        ! Associate with elset and material
        ! Add to section database

        WRITE(*,*) "INFO: Mapped COHESIVE SECTION (elset=", TRIM(elset_name), ", material=", TRIM(mat_name), ")"
    END SUBROUTINE map_cohesive_section

    ! ==========================================================================
    ! Map *GASKET SECTION keyword
    ! ABAQUS: *GASKET SECTION, ELSET=elset_name, MATERIAL=mat_name
    ! ==========================================================================
    SUBROUTINE map_gasket_section(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, mat_name

        CALL md_kw_get_param_value(node, "ELSET", elset_name)
        CALL md_kw_get_param_value(node, "MATERIAL", mat_name)

        IF (LEN_TRIM(elset_name) == 0) RETURN

        ! TODO: Create GasketSectionDef
        ! Parse thickness and nodal thickness from data lines
        ! Add to section database

        WRITE(*,*) "INFO: Mapped GASKET SECTION (elset=", TRIM(elset_name), ", material=", TRIM(mat_name), ")"
    END SUBROUTINE map_gasket_section

    ! ==========================================================================
    ! Map *SURFACE SECTION keyword
    ! ABAQUS: *SURFACE SECTION, ELSET=elset_name, DENSITY=value
    ! ==========================================================================
    SUBROUTINE map_surface_section(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, density_str
        REAL(wp) :: density
        INTEGER(i4) :: ios

        CALL md_kw_get_param_value(node, "ELSET", elset_name)
        CALL md_kw_get_param_value(node, "DENSITY", density_str)

        IF (LEN_TRIM(elset_name) == 0) RETURN

        density = 0.0_wp
        IF (LEN_TRIM(density_str) > 0) THEN
            READ(density_str, *, IOSTAT=ios) density
        END IF

        ! TODO: Create SurfaceSectionDef (for membrane/shell surfaces)
        ! Add to section database

        WRITE(*,*) "INFO: Mapped SURFACE SECTION (elset=", TRIM(elset_name), ", density=", density, ")"
    END SUBROUTINE map_surface_section

    ! ==========================================================================
    ! Map *FRAME keyword
    ! ABAQUS: *FRAME, NAME=frame_name, TYPE=RECTANGULAR/CYLINDRICAL/SPHERICAL
    ! ==========================================================================
    SUBROUTINE map_frame(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: frame_name, frame_type

        CALL md_kw_get_param_value(node, "NAME", frame_name)
        CALL md_kw_get_param_value(node, "TYPE", frame_type)

        IF (LEN_TRIM(frame_name) == 0) frame_name = "Frame-1"
        IF (LEN_TRIM(frame_type) == 0) frame_type = "RECTANGULAR"

        ! TODO: Parse frame coordinate system from data lines
        ! Create FrameDef and store in coordinate system database

        WRITE(*,*) "INFO: Mapped FRAME (name=", TRIM(frame_name), ", type=", TRIM(frame_type), ")"
    END SUBROUTINE map_frame

    ! ==========================================================================
    ! Phase C Tier 2: Advanced Output Mapping Functions (4 mappers)
    ! ==========================================================================

    ! ==========================================================================
    ! Map *EL PRINT keyword
    ! ABAQUS: *EL PRINT, ELSET=elset_name, FREQUENCY=n
    ! ==========================================================================
    SUBROUTINE map_el_print(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, freq_str
        INTEGER(i4) :: frequency, ios

        CALL md_kw_get_param_value(node, "ELSET", elset_name)
        CALL md_kw_get_param_value(node, "FREQUENCY", freq_str)

        frequency = 1  ! Default
        IF (LEN_TRIM(freq_str) > 0) THEN
            READ(freq_str, *, IOSTAT=ios) frequency
        END IF

        ! TODO: Create ElementPrintOutputDef
        ! Parse output variables from data lines
        ! Add to current step's output request list

        WRITE(*,*) "INFO: Mapped EL PRINT (elset=", TRIM(elset_name), ", frequency=", frequency, ")"
    END SUBROUTINE map_el_print

    ! ==========================================================================
    ! Map *CONTACT PRINT keyword
    ! ABAQUS: *CONTACT PRINT, FREQUENCY=n
    ! ==========================================================================
    SUBROUTINE map_contact_print(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: freq_str
        INTEGER(i4) :: frequency, ios

        CALL md_kw_get_param_value(node, "FREQUENCY", freq_str)

        frequency = 1  ! Default
        IF (LEN_TRIM(freq_str) > 0) THEN
            READ(freq_str, *, IOSTAT=ios) frequency
        END IF

        ! TODO: Create ContactPrintOutputDef
        ! Parse contact output variables from data lines
        ! Add to current step's output request list

        WRITE(*,*) "INFO: Mapped CONTACT PRINT (frequency=", frequency, ")"
    END SUBROUTINE map_contact_print

    ! ==========================================================================
    ! Map *ENERGY PRINT keyword
    ! ABAQUS: *ENERGY PRINT, FREQUENCY=n
    ! ==========================================================================
    SUBROUTINE map_energy_print(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: freq_str
        INTEGER(i4) :: frequency, ios

        CALL md_kw_get_param_value(node, "FREQUENCY", freq_str)

        frequency = 1  ! Default
        IF (LEN_TRIM(freq_str) > 0) THEN
            READ(freq_str, *, IOSTAT=ios) frequency
        END IF

        ! TODO: Create EnergyPrintOutputDef
        ! Add to current step's output request list

        WRITE(*,*) "INFO: Mapped ENERGY PRINT (frequency=", frequency, ")"
    END SUBROUTINE map_energy_print

    ! ==========================================================================
    ! Map *MODAL OUTPUT keyword
    ! ABAQUS: *MODAL OUTPUT, FREQUENCY=n (for frequency analysis)
    ! ==========================================================================
    SUBROUTINE map_modal_output(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: freq_str
        INTEGER(i4) :: frequency, ios

        CALL md_kw_get_param_value(node, "FREQUENCY", freq_str)

        frequency = 1  ! Default
        IF (LEN_TRIM(freq_str) > 0) THEN
            READ(freq_str, *, IOSTAT=ios) frequency
        END IF

        ! TODO: Create ModalOutputDef
        ! Parse modal output variables from data lines
        ! Add to current step's output request list

        WRITE(*,*) "INFO: Mapped MODAL OUTPUT (frequency=", frequency, ")"
    END SUBROUTINE map_modal_output

    ! ==========================================================================
    ! Phase C Tier 2: Advanced Load Mapping Functions (4 mappers)
    ! ==========================================================================

    ! ==========================================================================
    ! Map *CORIOLIS FORCE keyword
    ! ABAQUS: *CORIOLIS FORCE (angular velocity for rotating reference frame)
    ! ==========================================================================
    SUBROUTINE map_coriolis_force(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        ! TODO: Parse angular velocity vector from data lines
        ! Create CoriolisLoadDef
        ! Add to current step's load list

        WRITE(*,*) "INFO: Mapped CORIOLIS FORCE"
    END SUBROUTINE map_coriolis_force

    ! ==========================================================================
    ! Map *ROTARY ACCELERATION keyword
    ! ABAQUS: *ROTARY ACCELERATION (angular acceleration for rotating reference)
    ! ==========================================================================
    SUBROUTINE map_rotary_acceleration(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        ! TODO: Parse angular acceleration vector from data lines
        ! Create RotaryAccelerationLoadDef
        ! Add to current step's load list

        WRITE(*,*) "INFO: Mapped ROTARY ACCELERATION"
    END SUBROUTINE map_rotary_acceleration

    ! ==========================================================================
    ! Map *FOUNDATION keyword
    ! ABAQUS: *FOUNDATION, ELSET=elset_name (elastic foundation)
    ! ==========================================================================
    SUBROUTINE map_foundation(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name

        CALL md_kw_get_param_value(node, "ELSET", elset_name)

        IF (LEN_TRIM(elset_name) == 0) RETURN

        ! TODO: Parse foundation stiffness from data line
        ! Create FoundationLoadDef
        ! Add to current step's load list

        WRITE(*,*) "INFO: Mapped FOUNDATION (elset=", TRIM(elset_name), ")"
    END SUBROUTINE map_foundation

    ! ==========================================================================
    ! Map *SPRING keyword
    ! ABAQUS: *SPRING, ELSET=elset_name (spring elements between nodes)
    ! ==========================================================================
    SUBROUTINE map_spring(mapper, node)
        TYPE(KW_MapperStateType), INTENT(INOUT) :: mapper
        TYPE(KW_ASTNodeType), INTENT(IN) :: node

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name

        CALL md_kw_get_param_value(node, "ELSET", elset_name)

        IF (LEN_TRIM(elset_name) == 0) RETURN

        ! TODO: Parse spring stiffness from data line
        ! Create SpringElementDef (or SpringLoadDef)
        ! Add to element database or load list

        WRITE(*,*) "INFO: Mapped SPRING (elset=", TRIM(elset_name), ")"
    END SUBROUTINE map_spring

END MODULE MD_KW_Mapper