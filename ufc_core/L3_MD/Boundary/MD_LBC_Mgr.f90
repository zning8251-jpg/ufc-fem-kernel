!===============================================================================
! MODULE:  MD_LBC_Mgr
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Mgr
! BRIEF:   Thin re-export entry point for Load/BC subsystem.
!          Delegates to 7 sub-modules: Load_Mgr, BC_Mgr, LBC_Query,
!          LBC_Helper, LBC_Core, LBC_Container, LBC_Apply.
! PILOT:   ufc-layer-l3-l4-l5-pilot.md P4 (LoadBC) — L3 Boundary/ first vertical
!          slice; keep Desc/Populate/Bridge/L4/L5 in lockstep per wave (no TYPE-only).
!          Set lookup API: Ldbc_Find* in MD_LBC_Query (naming aligned with Ldbc_FlatMap_*).
!===============================================================================

MODULE MD_LBC_Mgr

    !=================================================================
    ! Sub-module 1: MD_Load_Mgr — Target/Load constants + LoadDef
    !=================================================================
    USE MD_Load_Mgr, ONLY: &
        TARGET_NODE, TARGET_NODESET, TARGET_SURFACE, TARGET_ELEMSET, TARGET_EDGE, &
        LOAD_CONCENTRAT, LOAD_DISTRIBUTE, LOAD_PRESSURE, LOAD_BODY_FORCE, &
        LOAD_GRAVITY, LOAD_CENTRIFUGA, LOAD_CORIOLIS, LOAD_THERMAL, LOAD_EDGE_DISTR, &
        LoadDef, LoadDef_Init_In, LoadDef_Init_Out, &
        LoadDef_Init_Structured

    !=================================================================
    ! Sub-module 2: MD_BC_Mgr — BC constants + BCDef
    !=================================================================
    USE MD_BC_Mgr, ONLY: &
        BC_DISPLACEMENT, BC_VELOCITY, BC_ACCELERATION, BC_FIXED, BC_SYMMETRY, &
        BC_NEUMANN, BC_ROBIN, BC_PERIODIC, BC_CONTACT, BC_ROTATION, &
        BC_TEMPERATURE, BC_PRESSURE, &
        BCDef, BCDef_Init_In, BCDef_Init_Out, &
        BCDef_Init_Structured

    !=================================================================
    ! Sub-module 3: MD_LBC_Query — Flat-map queries + set lookups
    !=================================================================
    USE MD_LBC_Query, ONLY: &
        Ldbc_FlatMap_NodeSet, Ldbc_FlatMap_ElemSet, Ldbc_FlatMap_SurfSet, &
        Ldbc_FindElementIndexById, &
        Ldbc_GetSurfaceElemFaceArrays, &
        Ldbc_GetNodeSetNodes, &
        Ldbc_GetElemSetElements, &
        Ldbc_GetElementNodes, &
        Ldbc_GetFaceNodes, &
        Ldbc_NodeCoordsForMeshIndex, &
        Ldbc_FindNodeSetId, &
        Ldbc_FindSurfaceSetId, &
        Ldbc_FindElementSetId

    !=================================================================
    ! Sub-module 4: MD_LBC_Helper — Geometry helpers
    !=================================================================
    USE MD_LBC_Helper, ONLY: &
        MD_LoadBC_Helper_ComputeFaceNormalArea, &
        MD_LoadBC_Helper_AddNodalVectorForce

    !=================================================================
    ! Sub-module 5: MD_LBC_Core — Mapping, sync, conversion, amplitude
    !=================================================================
    USE MD_LBC_Core, ONLY: &
        MD_LOADBC_LDBC_INVALID, &
        MD_LoadBC_ToLdbcLoadType, &
        MD_LdbcTo_LoadBCCoreLoadType, &
        MD_LoadBC_SyncFromLegacy, &
        UF_BCDef_To_MD_BC_Desc, &
        UF_CLoadDef_To_MD_Load_Desc, &
        UF_DLoadDef_To_MD_Load_Desc, &
        UF_BodyForceDef_To_MD_Load_Desc, &
        md_lbc_amp_from_uf

    !=================================================================
    ! Sub-module 6: MD_LBC_Container — Types + domain lifecycle
    !=================================================================
    USE MD_LBC_Container, ONLY: &
        ! Desc/State/Ctx/Algo base types
        MD_LdbcDesc, LoadBCTree, MD_LdbcSta, MD_LdbcCtx, MD_LdbcAlgo, &
        ! Domain container types
        MD_LoadBC_Desc, MD_LoadBC_State, MD_LoadBC_Algo, MD_LoadBC_Ctx, &
        MD_LoadBC_Runtime_Domain, &
        ! Table container types
        MD_LoadBC_TableDesc, MD_LoadBC_TableSta, MD_LoadBC_TableAlgo, &
        MD_LoadBC_TableCtx, MD_LoadBC_TableDomain, &
        ! Global domain instances
        g_md_loadbc_domain, g_md_loadbc_table, &
        ! Additional descriptor types
        MD_LoadDesc, MD_BndDesc, MD_ConcForceDesc, MD_DistLoadDesc, &
        MD_DispBCDesc, MD_VelBCDesc, MD_BodyForceDesc, &
        LoadB, StepDef, &
        MD_NeumBCDesc, MD_RobinBCDesc, MD_PerBCDesc, &
        ! Domain lifecycle
        MD_LoadBC_Domain_Init, MD_LoadBC_Domain_Reset, &
        MD_LoadBC_Domain_Finalize, MD_LoadBC_Domain_SyncFromStep, &
        ! Table lifecycle
        MD_LoadBC_Table_Init, MD_LoadBC_Table_Reset, &
        MD_LoadBC_Table_Finalize, MD_LoadBC_Table_SyncFromStep

    !=================================================================
    ! Sub-module 7: MD_LBC_Apply — Load distribution + BC application
    !=================================================================
    USE MD_LBC_Apply, ONLY: &
        ! Load distribution
        LoadBC_DistributeLoad_ToNodes, &
        LoadBC_DistributeLoad_ToElements, &
        LoadBC_DistributeLoad_ToSurface, &
        ! BC application
        LoadBC_ApplyBC_Velocity, &
        LoadBC_ApplyBC_Acceleration, &
        LoadBC_ApplyBC_Displacement_GetNodes, &
        ! Follower/pressure/body force
        ApplyLoad_FollowerForce, &
        ApplyLoad_PressureFollowing, &
        ApplyLoad_BodyForce, &
        ! Extended UF API
        UF_DisplacementBC_GetStatistics, UF_DisplacementBC_ApplyAtTime, &
        UF_VelocityBC_GetStatistics, UF_AccelerationBC_GetStatistics, &
        UF_ConcentratedLoad_GetStatistics, UF_ConcentratedLoad_ApplyAtTime, &
        UF_DistributedLoad_GetStatistics, UF_DistributedLoad_ComputeNodalForces, &
        UF_InitialDisplacement_GetStatistics, UF_InitialVelocity_GetStatistics, &
        UF_InitialTemperature_GetStatistics

    IMPLICIT NONE

    ! All symbols imported above are PUBLIC by default (no PRIVATE).
    ! Downstream "USE MD_LBC_Mgr" sees every original PUBLIC symbol.

END MODULE MD_LBC_Mgr
