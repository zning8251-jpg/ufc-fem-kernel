!===============================================================================
! MODULE: AP_Brg_L3
! LAYER:  L6_AP
! DOMAIN: Bridge
! ROLE:   Brg — L6→L3 bridge
! BRIEF:  Re-export L3_MD public types/procedures for L6_AP consumption.
!===============================================================================
! Pattern: USE + re-export (no CONTAINS logic; pure dependency routing)
!===============================================================================

MODULE AP_Brg_L3
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Import L3_MD modules (all domains needed by L6_AP)
  !=============================================================================
  
  ! Model Tree and Context
  USE MD_Model_Tree, ONLY: ModelTree, &
                           MD_ModelTree_DFS_Traverse, MD_ModelTree_BFS_Traverse, &
                           MD_ModelTree_QueryOptimize, MD_ModelTree_BuildIndex, &
                           MD_ModelTree_FindByPath, MD_ModelTree_FindByType
  
  USE MD_Model_Mgr, ONLY: MD_Model_Ctx
  
  ! Step Core
  USE MD_Step_Proc, ONLY: UF_StepDef, UF_StepManager, StepDesc, StepTree, &
                          PROC_STATIC, PROC_STATIC_RIKS, PROC_DYNAMIC_IMPLICIT, &
                          PROC_DYNAMIC_EXPLICIT, PROC_MODAL, PROC_FREQUENCY, &
                          PROC_BUCKLE, PROC_HEAT_TRANSFER, PROC_COUPLED_TEMP_DISP, &
                          NLGEOM_OFF, NLGEOM_ON, &
                          INTEG_NEWMARK_BETA, INTEG_HHT_ALPHA, INTEG_CENTRAL_DIFF, &
                          UF_IncrementControl, UF_SolutionControl, &
                          Step_Init_Structured, Step_SetProcedure_Structured, &
                          Step_SetTime_Structured, Step_SetNLGeom_Structured, &
                          Step_SetIncrement_Structured, &
                          Step_Init_In, Step_Init_Out, Step_SetProcedure_In, &
                          Step_SetProcedure_Out, Step_SetTime_In, Step_SetTime_Out, &
                          Step_SetNLGeom_In, Step_SetNLGeom_Out, &
                          Step_SetIncrement_In, Step_SetIncrement_Out, Step_SetNLGeom_Structured, &
                          Step_SetIncrement_Structured
  
  ! Material Core (single merged USE)
  USE MD_Mat_Lib, ONLY: UF_MaterialDef, UF_MaterialDB, &
                         MaterialDef_Init_In, MaterialDef_SetElasticIso_In, &
                         MaterialDef_SetPlasticMises_In, MaterialDef_SetDamping_In, &
                         MaterialDef_SetExpansion_In, MaterialDef_SetElasticOrtho_In, &
                         MaterialDef_SetElasticTransIso_In, MaterialDef_SetElasticAniso_In, &
                         MaterialDef_Init_Structured, MaterialDef_SetElasticIso_Structured, &
                         MaterialDef_SetPlasticMises_Structured, MaterialDef_SetDamping_Structured, &
                         MaterialDef_SetExpansion_Structured, MaterialDef_SetElasticOrtho_Structured, &
                         MaterialDef_SetElasticTransIso_Structured, MaterialDef_SetElasticAniso_Structured
  
  ! Material Unified (single merged USE)
  USE MD_Mat_Lib, ONLY: MD_Mat_Desc, MatDesc, MaterialDesc, MatTree, &
                            MD_MatSta, MD_MatCtx, MD_MatModel, MD_MatModelDesc, &
                            MD_MatAlgo, MD_MatPointSta, &
                            MD_ElasticMatDesc, MD_PlasticMatDesc, &
                            MD_HyperElasticMatDesc, MD_DamageMatDesc, &
                            MD_PronyMatDesc, MD_CompositeMatDesc, &
                            MD_Material_Ctx, MatCtxLegacy, MatRes, MatFlags, &
                            MatProps, UMAT_Intf, UMAT_Input, UMAT_Output, &
                            UF_MatProp_Init, MAT_CAT_ELASTIC, &
                            MAT_ID_ISO_ELASTIC
  
  ! Section Core
  USE MD_Sect_Mgr, ONLY: UF_SectionDef, UF_SectionDBType, &
                           SECTION_SOLID, SECTION_SHELL, SECTION_BEAM, &
                           SECTION_MEMBRANE, SECTION_TRUSS, SECTION_COHESIVE, &
                           SECTION_GASKET, &
                           SectionDef_Init_In, SectionDef_Init_Out, &
                           SectionDef_SetSolid_In, SectionDef_SetShell_In, &
                           SectionDef_SetBeamRect_In, SectionDef_SetBeamCircular_In, &
                           SectionDef_SetBeamGeneral_In, SectionDef_SetMembrane_In, &
                           SectionDef_SetTruss_In, SectionDB_Init_In, &
                           SectionDef_Op_Out, SectionDB_Op_Out, &
                           SectionDef_Init_Structured, SectionDef_SetSolid_Structured, &
                           SectionDef_SetShell_Structured, SectionDef_SetBeamRect_Structured, &
                           SectionDef_SetBeamCircular_Structured, SectionDef_SetBeamGeneral_Structured, &
                           SectionDef_SetMembrane_Structured, SectionDef_SetTruss_Structured, &
                           SectionDB_Init_Structured
  
  ! Load/BC Core (internal types from BC/MD_LBC.f90)
  USE MD_LBC_Mgr, ONLY: LoadDef, BCDef, &
                          LoadDef_Init_Structured, BCDef_Init_Structured, &
                          LoadDef_Init_In, LoadDef_Init_Out, &
                          BCDef_Init_In, BCDef_Init_Out, &
                          MD_LdbcDesc, LoadBCTree
  
  ! LoadBC API (UF_* types for L6_AP layer from MD_LBC_Brg.f90)
  USE MD_LBC_Brg, ONLY: UF_BCDef, UF_CLoadDef, UF_DLoadDef, UF_BodyForceDef, &
                          UF_ThermalLoadDef, UF_LoadBCManager, &
                          BC_DISPLACEMENT, BC_VELOCITY, BC_ACCELERATION, BC_TEMPERATURE, &
                          BC_ENCASTRE, BC_PINNED, BC_XSYMM, BC_YSYMM, BC_ZSYMM, &
                          BC_XASYMM, BC_YASYMM, BC_ZASYMM, &
                          DIST_UNIFORM, DIST_USER, DIST_ANALYTICAL, &
                          MAX_LOADBC_NAME, MAX_LOADS_PER_STEP, MAX_BCS_PER_STEP
  
  ! Part Core
  USE MD_Part_Mgr, ONLY: UF_PartDef, UF_Node, UF_Element, &
                          Part_Init_In, Part_Init_Out, Part_AddNode_In, Part_AddNode_Out, &
                          Part_Init_Structured, Part_AddNode_Structured
  
  ! Instance Core
  USE MD_Asm_Inst, ONLY: UF_Instance, Instance_SetTranslation, &
                              Instance_SetRotation
  
  ! Output Core (MD_Output_Core deprecated -> MD_Out)
  USE MD_Out_Lib, ONLY: UF_FieldOutputDef, UF_HistoryOutputDef
  
  ! Contact Core
  USE MD_Int_API, ONLY: FrictionParams, ContactDef, ContactPairDef
  
  ! Unified Field Operations
  USE MD_Out_UniFldOps, ONLY: MD_InitialCondition, CreateInitialCondition, &
                           ApplyInitialCondition
  
  ! Base Tree Index API
  USE MD_Base_TreeIndex_API, ONLY: TreeNodeBase, NODE_TYPE_NODE, &
                                    NODE_TYPE_ELEME
  
  ! Amplitude Core (types/time enums: UF_Def; AMP_*: MD_Amp_Def)
  USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc, MD_Amp_Slot_Ctx, TIME_STEP, TIME_TOTAL
  USE MD_Amp_Def, ONLY: AMP_TABULAR, AMP_PERIODIC, AMP_MODULATED, &
      AMP_DECAY, AMP_USER, AMP_SMOOTH
  
  ! Contact Manager
  USE MD_Int_Mgr, ONLY: contact_Mgr_init, contact_add_pair, contact_Mgr_cleanup
  
  ! Field State Core
  USE MD_Field_Mgr, ONLY: FieldState, FieldState_AddInitialCondition, &
                                 FieldState_AddPredefinedField
  
  ! Keyword Registry
  USE MD_KW_Reg, ONLY: kw_registry_init, kw_registry_get_count, &
                            kw_registry_get_all, kw_registry_find, kw_is_initialized
  
  ! Keyword Types
  USE MD_KW_Def, ONLY: KW_MetadataType, KW_MAX_NAME_LEN, KW_MAX_DESC_LEN, &
                         KW_MAX_PARAMS, KW_CAT_MODEL, KW_CAT_PART, KW_CAT_MESH, &
                         KW_CAT_MATERIAL, KW_CAT_SECTION, KW_CAT_CONSTRAINT, &
                         KW_CAT_LOAD, KW_CAT_CONTACT, KW_CAT_STEP, KW_CAT_OUTPUT, &
                         KW_CAT_AMPLITUDE, KW_CAT_SPECIAL, KW_CAT_END, &
                         PARAM_TYPE_STRING, PARAM_TYPE_INTEGER, PARAM_TYPE_REAL, &
                         PARAM_TYPE_ENUM, PARAM_TYPE_LOGICAL, PARAM_TYPE_NAME_REF, &
                         KW_ASTNodeType, KW_MAX_VALUE_LEN
  
  ! Base Object Model Core
  USE MD_Base_ObjModel, ONLY: DescBase, UF_Assem
  
  ! UI Tree Manager
  USE AP_UI_TreeMgr, ONLY: TreeMgr, &
                             TreeMgr_CreateNode, TreeMgr_DeleteNode, TreeMgr_RenameNode, &
                             TreeMgr_GetNodeData, TreeMgr_SetNodeData, TreeMgr_GetChildren, &
                             TreeMgr_MoveNode, TreeMgr_GetNodePath, TreeMgr_FindNodeByName
  ! Note: NODE_TYPE_PART, NODE_TYPE_MATER, NODE_TYPE_STEP are from MD_BaseTreeIndex
  USE MD_Base_TreeIndex, ONLY: NODE_TYPE_PART, NODE_TYPE_MATER, NODE_TYPE_STEP
  
  ! Material Adapter (for MaterialDesc compatibility)
  USE AP_Mat_Brg, ONLY: MaterialDesc_Init_Structured_Wrapper, &
                                      MD_Mat_Desc_To_UF_MaterialDef, &
                                      UF_MaterialDef_To_MD_Mat_Desc

  !=============================================================================
  ! Re-export all public interfaces (Re-export Pattern)
  !=============================================================================
  
  ! Model Tree
  PUBLIC :: ModelTree, &
            MD_ModelTree_DFS_Traverse, MD_ModelTree_BFS_Traverse, &
            MD_ModelTree_QueryOptimize, MD_ModelTree_BuildIndex, &
            MD_ModelTree_FindByPath, MD_ModelTree_FindByType
  
  ! Model Context
  PUBLIC :: MD_Model_Ctx
  
  ! Step Core
  PUBLIC :: UF_StepDef, UF_StepManager, StepDesc, StepTree, &
            PROC_STATIC, PROC_STATIC_RIKS, PROC_DYNAMIC_IMPLICIT, &
            PROC_DYNAMIC_EXPLICIT, PROC_MODAL, PROC_FREQUENCY, &
            PROC_BUCKLE, PROC_HEAT_TRANSFER, PROC_COUPLED_TEMP_DISP, &
            NLGEOM_OFF, NLGEOM_ON, &
            INTEG_NEWMARK_BETA, INTEG_HHT_ALPHA, INTEG_CENTRAL_DIFF, &
            UF_IncrementControl, UF_SolutionControl, &
            Step_Init_Structured, Step_SetProcedure_Structured, &
            Step_SetTime_Structured, Step_SetNLGeom_Structured, &
            Step_SetIncrement_Structured, &
            Step_Init_In, Step_Init_Out, Step_SetProcedure_In, &
            Step_SetProcedure_Out, Step_SetTime_In, Step_SetTime_Out, &
            Step_SetNLGeom_In, Step_SetNLGeom_Out, &
            Step_SetIncrement_In, Step_SetIncrement_Out
  
  ! Material Core (structured interfaces)
  PUBLIC :: UF_MaterialDef, MaterialDef_Init_Structured, &
            MaterialDef_SetElasticIso_Structured, &
            MaterialDef_SetElasticOrtho_Structured, &
            MaterialDef_SetElasticTransIso_Structured, &
            MaterialDef_SetElasticAniso_Structured, &
            MaterialDef_SetPlasticMises_Structured, &
            MaterialDef_SetDamping_Structured, &
            MaterialDef_SetExpansion_Structured, &
            MaterialDef_Init_In, MaterialDef_SetElasticIso_In, &
            MaterialDef_SetElasticOrtho_In, &
            MaterialDef_SetElasticTransIso_In, &
            MaterialDef_SetElasticAniso_In, &
            MaterialDef_SetPlasticMises_In, &
            MaterialDef_SetDamping_In, MaterialDef_SetExpansion_In
  
  ! Material Unified (MaterialDesc is likely an alias or compatible type)
  PUBLIC :: MD_Mat_Desc, MatDesc, MaterialDesc, &
            MD_MatSta, MD_MatCtx, MD_MatModel, MD_MatModelDesc, &
            MD_MatAlgo, MD_MatPointSta, &
            MD_ElasticMatDesc, MD_PlasticMatDesc, &
            MD_HyperElasticMatDesc, MD_DamageMatDesc, &
            MD_PronyMatDesc, MD_CompositeMatDesc, &
            MD_Material_Ctx, MatCtxLegacy, MatRes, MatFlags, &
            MatProps, UMAT_Intf, UMAT_Input, UMAT_Output, &
            UF_MatProp_Init, MAT_CAT_ELASTIC, &
            MAT_ID_ISO_ELASTIC
  
  ! Material Tree
  PUBLIC :: MatTree
  
  ! Section Core
  PUBLIC :: UF_SectionDef, UF_SectionDBType, &
            SECTION_SOLID, SECTION_SHELL, SECTION_BEAM, &
            SECTION_MEMBRANE, SECTION_TRUSS, SECTION_COHESIVE, &
            SECTION_GASKET, SHELL_KIRCHHOFF, SHELL_MINDLIN, &
            BEAM_EULER, BEAM_TIMOSHENKO, &
            SectionDef_Init_Structured, SectionDef_SetSolid_Structured, &
            SectionDef_SetShell_Structured, SectionDef_SetBeamRect_Structured, &
            SectionDef_SetBeamCircular_Structured, &
            SectionDef_SetBeamGeneral_Structured, &
            SectionDef_SetMembrane_Structured, &
            SectionDef_SetTruss_Structured, SectionDB_Init_Structured, &
            SectionDef_Init_In, SectionDef_SetSolid_In, &
            SectionDef_SetShell_In, SectionDef_SetBeamRect_In, &
            SectionDef_SetBeamCircular_In, SectionDef_SetBeamGeneral_In, &
            SectionDef_SetMembrane_In, SectionDef_SetTruss_In, &
            SectionDB_Init_In, SectionDef_Op_Out, SectionDB_Op_Out
  
  ! Load/BC Core (internal types)
  PUBLIC :: LoadDef, BCDef, &
            LoadDef_Init_Structured, BCDef_Init_Structured, &
            LoadDef_Init_In, LoadDef_Init_Out, &
            BCDef_Init_In, BCDef_Init_Out, &
            MD_LdbcDesc, LoadBCTree
  
  ! LoadBC API (UF_* types for L6_AP layer)
  PUBLIC :: UF_BCDef, UF_CLoadDef, UF_DLoadDef, UF_BodyForceDef, &
            UF_ThermalLoadDef, UF_LoadBCManager, &
            BC_DISPLACEMENT, BC_VELOCITY, BC_ACCELERATION, BC_TEMPERATURE, &
            BC_ENCASTRE, BC_PINNED, BC_XSYMM, BC_YSYMM, BC_ZSYMM, &
            BC_XASYMM, BC_YASYMM, BC_ZASYMM, &
            DIST_UNIFORM, DIST_USER, DIST_ANALYTICAL, &
            MAX_LOADBC_NAME, MAX_LOADS_PER_STEP, MAX_BCS_PER_STEP
  
  ! Part Core
  PUBLIC :: UF_PartDef, UF_Node, UF_Element, &
            Part_Init_Structured, Part_AddNode_Structured, &
            Part_Init_In, Part_Init_Out, &
            Part_AddNode_In, Part_AddNode_Out
  
  ! Assembly Core
  PUBLIC :: UF_Assem
  
  ! Instance Core
  PUBLIC :: UF_Instance, Instance_SetTranslation, &
            Instance_SetRotation
  
  ! Output Core
  PUBLIC :: UF_FieldOutputDef, UF_HistoryOutputDef
  
  ! Contact Core
  PUBLIC :: FrictionParams, ContactDef, ContactPairDef
  
  ! Unified Field Operations
  PUBLIC :: MD_InitialCondition, CreateInitialCondition, &
            ApplyInitialCondition
  
  ! Base Tree Index API
  PUBLIC :: TreeNodeBase, NODE_TYPE_NODE, &
            NODE_TYPE_ELEME
  
  ! Amplitude Core
  PUBLIC :: MD_Amp_Slot_Desc, MD_Amp_Slot_Ctx, &
            AMP_TABULAR, AMP_PERIODIC, AMP_MODULATED, &
            AMP_DECAY, AMP_USER, AMP_SMOOTH, TIME_STEP, TIME_TOTAL
  
  ! Contact Manager
  PUBLIC :: contact_Mgr_init, contact_add_pair, contact_Mgr_cleanup
  
  ! Field State Core
  PUBLIC :: FieldState, FieldState_AddInitialCondition, &
            FieldState_AddPredefinedField
  
  ! Keyword Registry
  PUBLIC :: kw_registry_init, kw_registry_get_count, &
            kw_registry_get_all, kw_registry_find, kw_is_initialized
  
  ! Keyword Types
  PUBLIC :: KW_MetadataType, KW_MAX_NAME_LEN, KW_MAX_DESC_LEN, &
            KW_MAX_PARAMS, KW_CAT_MODEL, KW_CAT_PART, KW_CAT_MESH, &
            KW_CAT_MATERIAL, KW_CAT_SECTION, KW_CAT_CONSTRAINT, &
            KW_CAT_LOAD, KW_CAT_CONTACT, KW_CAT_STEP, KW_CAT_OUTPUT, &
            KW_CAT_AMPLITUDE, KW_CAT_MACRO, KW_CAT_END, &
            KW_ASTNodeType, KW_MAX_VALUE_LEN, &
            KW_CAT_SPECIAL, PARAM_TYPE_STRING, &
            PARAM_TYPE_INTEGER, PARAM_TYPE_REAL, &
            PARAM_TYPE_ENUM, PARAM_TYPE_LOGICAL, &
            PARAM_TYPE_NAME_REF
  
  ! Base Object Model Core
  PUBLIC :: DescBase
  
  ! UI Tree Manager
  PUBLIC :: TreeMgr, &
            TreeMgr_CreateNode, TreeMgr_DeleteNode, TreeMgr_RenameNode, &
            TreeMgr_GetNodeData, TreeMgr_SetNodeData, TreeMgr_GetChildren, &
            TreeMgr_MoveNode, TreeMgr_GetNodePath, TreeMgr_FindNodeByName, &
            NODE_TYPE_PART, NODE_TYPE_MATER, NODE_TYPE_STEP
  
  ! Material Adapter (for MaterialDesc compatibility)
  PUBLIC :: MaterialDesc_Init_Structured_Wrapper, &
            MD_Mat_Desc_To_UF_MaterialDef, &
            UF_MaterialDef_To_MD_Mat_Desc

END MODULE AP_Brg_L3