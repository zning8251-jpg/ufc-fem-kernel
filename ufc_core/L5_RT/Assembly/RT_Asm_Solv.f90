!===============================================================================
! MODULE: RT_Asm_Solv
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Solv
! BRIEF:  GOLDEN-LINE production assembly hub -- solver interface & global K/F
!===============================================================================
!
! Partial Pillar: H3 Assembly (AUTHORITY types: RT_Asm_Def.f90)
!
! GOLDEN-LINE NOTE (v4.0): Production global assembly hub.
!   Despite legacy @DEPRECATED header, this remains the authoritative assembly
!   path for static implicit (RT_Asm_GlobalStiffness, RT_Asm_Complete, etc.).
!   RT_Asm_Core.f90 is a thin FACADE with complementary operations.
!
! Computation chain (static implicit NR):
!   L5 RT_Asm_GlobalStiffness / RT_Asm_ComputeTangent
!     -> g_ufc_global%ph_layer%element%Compute_Ke
!   L5 RT_Asm_GlobalLoad -> F_ext (CLOAD, DLOAD/BODY/PRESSURE lumped to nodes where implemented)
!   L5 RT_Asm_ComputeResidual
!     -> F_int from element%Compute_Fe; R = F_ext - F_int
!     -> PH_Element_Compute_Fe_Arg%load_magn_in: only loads consumed in the element
!        weak form that are NOT already in F_ext (see Assembly CONTRACT 5.4).
!   L2/L5 RT_LinearSolver_Solv (K*du = -R)
!
! Status: ACTIVE | GOLDEN-LINE | Last verified: 2026-04-28
!===============================================================================
!===============================================================================
! Module: RT_AsmSolv
! Layer:  L5_RT - Runtime Layer
! Domain: Asm - Assembly
! Purpose: Global assembly (K, F_ext), BC application, contact. _Idx path: BuildStepBCs_Idx,
!   GetLoadsForStep_Idx + nset/elset/surface resolution.
! Theory: F_ext = sum(loads), K_penalty for BC. See RT_ASM_SOLV_IDX_MIGRATION.md.
! Status: PROD | Last verified: 2026-03-11
!
! Contents (A-Z):
!   Types:
!     - [List types in A-Z order]
!   Subroutines:
!     - [List subroutines in A-Z order]
!   Functions:
!     - [List functions in A-Z order]
!
! --- UFC P0 金线：计算链 / 数据链（对齐 PLAN/04_实施路线与任务规�?实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md 三附�?--
! 计算链（静力隐式 NR）：
!   L5 RT_Asm_GlobalStiffness / RT_Asm_ComputeTangent
!     -> g_ufc_global%ph_layer%element%Compute_Ke(PH_Element_Compute_Ke_Arg)
!   L5 RT_Asm_ComputeResidual
!     -> element%Compute_Fe（内力）+ L5 外力/BC
!   L2/L5 RT_LinearSolver_Solv（在 RT_NLSolver_NewtonRaph 内对 K·Δu = -R�?! 数据链：
!   L3 Desc 只读；L4 slot �?PH_L4_Init / Populate 填充；本模块仅在组装循环触碰 L4 TYPE 接口与全局 CSR/向量�?! 禁止：在 L5 手写本构或单�?B/D 矩阵公式（须�?L4）�?!===============================================================================

MODULE RT_Asm_Solv
!> Status: stub (not implemented yet)
!> Theory: (TODO) | Last verified: 2026-02-14
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                          IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE RT_Amp_Mgr, ONLY: RT_Amp_FactorAt
  !--- L3 imports: COLD-OK (step-init / config reads, not in IP hot loop) ---
  USE MD_Model_Lib, ONLY: UF_Model                            ! COLD-OK: model handle
  USE MD_Field_Mgr, ONLY: MD_NodeDisp                        ! COLD-OK: node displacement type
  USE MD_Int_API, ONLY: contact_Assemble_triplets                ! COLD-OK: contact triplets (MD_Int_API)
  USE MD_LBC_Mgr, ONLY: LoadDef, BCDef, LoadBC_DistributeLoad_ToNodes, &  ! COLD-OK: load/BC defs
                            LoadBC_DistributeLoad_ToElements, &
                            LoadBC_DistributeLoad_ToSurface, &
                            LoadBC_ApplyBC_Velocity, &
                            LoadBC_ApplyBC_Acceleration, &
                            LoadBC_ApplyBC_Displacement_GetNodes, &
                            TARGET_NODE, TARGET_NODESET, TARGET_SURFACE, TARGET_ELEMSET, &
                            LOAD_BODY_FORCE, LOAD_GRAVITY
  USE MD_Step_Proc, ONLY: AnalysisStep, StepStateData, PROC_BUCKLE, &  ! COLD-OK: step config
                           UF_StepDef
  USE MD_Step_LegacyLoad_Sync, ONLY: UF_Step_BuildLegacyLoadDefs_FromLdbc  ! COLD-OK: L3->Legacy LoadDef
  USE PH_Cont_Brg, ONLY: PH_Cont_ApplyConstraints_API, PH_Cont_SearchPairs_API, &
                         PH_Cont_DetectPenetration_API, PH_Cont_CalculateGap_API
  USE PH_Cont_Def, ONLY: PH_ContactCtx, PH_Cont_Ctx_Init, PH_Cont_Ctx_Clear
  USE PH_Cont_Def, ONLY: PH_Cont_ApplyConstraints_In, PH_Cont_ApplyConstraints_Out, &
                           PH_Cont_SearchPairs_In, PH_Cont_SearchPairs_Out, &
                           PH_Cont_DetectPenetration_In, PH_Cont_DetectPenetration_Out, &
                           PH_Cont_CalculateGap_In, PH_Cont_CalculateGap_Out
  USE RT_Solv_Sparse, ONLY: RT_TripletList, RT_Triplet_Init, RT_Triplet_Add, &
                               RT_Triplet_Free, RT_CSR_FromTriplet, RT_CSR_FromTripletMerged, &
                               RT_CSR_SpMV, RT_CSR_AddToValue
  USE RT_Solv_Def, ONLY: RT_CSRMatrix, RT_Sol_DofMap, RT_Sol_State
  USE RT_Asm_Tripartite, ONLY: RT_Asm_TripartiteKey, RT_Asm_Tripartite_LinearIndex
  ! P2 _Idx path: BuildStepBCs_Idx, dofMap conversion, penalty BC
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  !--- L3 imports: COLD-OK (Populate-time contact config, not in IP loop) ---
  USE MD_Cont_Mgr, ONLY: MD_ContactPairDef, MD_ContactProperty   ! COLD-OK: contact defs
  USE MD_ContPH_Brg, ONLY: MD_Cont_PH_FillParams_FromMD      ! COLD-OK: populate bridge
  USE PH_Cont_Domain, ONLY: PH_Contact_Params
  USE MD_LBCPH_Brg, ONLY: MD_LoadBC_PH_Brg_BuildStepBCs_Idx   ! COLD-OK: populate bridge
  USE RT_Asm_DofMap, ONLY: RT_Asm_DofMap_GetEqId, RT_Asm_DofMap_Build
  USE PH_BC_Def, ONLY: PH_BC_Cache_Type
  ! P2 _Idx path: RT_Asm_GlobalLoad CLOAD
  !--- L3 imports: COLD-OK (load/BC index queries, step-init time) ---
  USE MD_LBC_Idx, ONLY: MD_LoadBC_GetLoadsForStep_Idx, MD_LoadBC_GetLoad_Idx  ! COLD-OK
  USE MD_LBC_Domain, ONLY: BC_DISPLACEMENT, BC_VELOCITY, BC_ACCELERATION, &   ! COLD-OK: enums
       LOAD_CLOAD, LOAD_DLOAD, LOAD_DSLOAD, LOAD_BODY_FORCE, LOAD_PRESSURE, &
       MD_LBC_GetLoadsForStep_Arg, MD_LBC_GetLoad_Arg
  USE MD_BC_Def, ONLY: BC_FAMILY_DISP, BC_FAMILY_VEL, BC_FAMILY_ACC           ! COLD-OK: enums
  USE MD_Load_Def, ONLY: LOAD_FAMILY_DIST, LOAD_FAMILY_CONC, LOAD_FAMILY_FLUX ! COLD-OK: enums
  USE MD_LBC_Mgr, ONLY: MD_LoadBC_ToLdbcLoadType, MD_LOADBC_LDBC_INVALID          ! COLD-OK
  USE MD_Asm_Mgr, ONLY: MD_SetDef, MD_SurfaceDef, &                      ! COLD-OK: set queries
       MD_Assembly_GetSurfaceByName_Idx, MD_Asm_GetSurfaceByName_Arg, &
       MD_Assembly_GetNodeSetByName_Idx, MD_Asm_GetNodeSetByName_Arg, &
       MD_Assembly_GetElemSetByName_Idx, MD_Asm_GetElemSetByName_Arg
  ! P2 Phase 2: DLOAD/BODY_FORCE - elem connectivity for elset distribution
  !--- L3 imports: HOT-ADJACENT (used in element loop setup, should migrate to L4 Populate) ---
  USE MD_Mesh_API, ONLY: MD_Mesh_GetElemConnect_Idx, MD_Mesh_GetElemConnect_Arg, & ! HOT-ADJACENT
                                  MD_Mesh_GetNodeCoords_Idx, MD_Mesh_GetNodeCoords_Arg, &
                                  MD_Mesh_GetElemSection_Idx, MD_Mesh_GetElemSection_Arg
  USE MD_Sect_Domain, ONLY: MD_Section_GetSection_Idx, MD_Sect_Get_Arg ! HOT-ADJACENT
  USE MD_Elem_Mgr, ONLY: ELEM_T3D2, ELEM_B31, &                                    ! COLD-OK: enums
       ELEM_S4T, ELEM_S8RT, ELEM_B31T, ELEM_C3D8PT, &
       ELEM_C3D4T, ELEM_C3D6T, ELEM_C3D8T, ELEM_C3D10T, ELEM_C3D15T, ELEM_C3D20T, ELEM_C3D27T, &
       ELEM_C3D4P, ELEM_C3D6P, ELEM_C3D8P, ELEM_C3D10P, ELEM_C3D15P, ELEM_C3D20P, ELEM_C3D27P, &
       ELEM_CPE4T, ELEM_CPE8T, ELEM_CPS4T, ELEM_CPS8T, ELEM_CAX4T, ELEM_CAX8T, &
       ELEM_CPE4P, ELEM_CPE8P, ELEM_CAX4P, ELEM_CAX8P
  USE PH_Elem_Def, ONLY: PH_Element_Compute_Ke_Arg, PH_Element_Compute_Fe_Arg
  USE PH_Elem_Reg, ONLY: PH_Elem_Reg_Get, PH_Elem_Reg_Entry
  USE RT_Asm_MassDamp, ONLY: RT_Asm_CSRMass_FromModel, MASS_TYPE_CONSIST
  USE RT_Asm_Args
  USE RT_Asm_Brg, ONLY: RT_Asm_Brg_ElemMatPtIdx
  USE PH_Elem_C3D8, ONLY: PH_Elem_C3D8_GaussPoints, PH_Elem_C3D8_JacB, &
       PH_Elem_C3D8_JacB_In, PH_Elem_C3D8_JacB_Out
  USE PH_Elem_HeatTransfer, ONLY: PH_Elem_HeatTransfer_Kcond, PH_Elem_HeatTransfer_Ccap
  USE RT_Solv_Lin, ONLY: RT_LinearSolver, RT_LinearSolver_Init, RT_LinearSolver_Solv, &
       RT_LinearSolver_Clean
  USE PH_Mat_HistoryAPI, ONLY: PH_Mat_GetCreepStrain_FromStateVars
  USE PH_LBC_GeostaticAlgo, ONLY: PH_Geostatic_GravityForce
  USE PH_Field_Cpl, ONLY: PH_Acoustic_StiffnessContrib, &
       PH_ElectroMag_StiffnessContrib, PH_SSTrans_ConvectiveContrib, &
       PH_Piezo_CouplingContrib
  USE PH_ShapeScalarField, ONLY: PH_ShapeScalarField_GetNumGauss, &
       PH_ShapeScalarField_Eval, PH_ShapeScalarField_Supported
  USE PH_Elem_ShapeMechField, ONLY: PH_ShapeMechanicalField_GetNumGauss, &
       PH_ShapeMechanicalField_Eval, PH_ShapeMechanicalField_Supported
  USE RT_Ldbc_ConstApply, ONLY: RT_Ldbc_ConstApply_All, METHOD_PENALTY, &
       RT_Ldbc_MPCPenalty_AppendTriplets, RT_Ldbc_TiePenalty_AppendTriplets, &
       RT_Ldbc_CplPenalty_AppendTriplets, RT_Ldbc_RigidPenalty_AppendTriplets
  !--- L3 imports: COLD-OK (constraint defs, step-init resolve) ---
  USE MD_Model_Def, ONLY: Model                                               ! COLD-OK
  USE MD_Constr_Def, ONLY: MPCConstraintDef, TieConstraintDef, &           ! COLD-OK
       CplConstraintDef, RigidBodyDef
  USE MD_Constr_Brg, ONLY: MD_TieConstraint_TryResolveSurfaces, &    ! COLD-OK
       MD_CplConstraint_TryResolveSurfaceOrElset, MD_RigidBody_TryResolveFromAssembly

  IMPLICIT NONE
  PRIVATE
  
  ! Public interfaces
  PUBLIC :: RT_Asm_GlobalStiffness
  PUBLIC :: RT_Asm_GlobalLoad
  PUBLIC :: RT_Asm_ApplyBC
  PUBLIC :: RT_Asm_ApplyContact
  PUBLIC :: RT_Asm_ApplyL3Constraints
  PUBLIC :: RT_Asm_Complete
  PUBLIC :: RT_Asm_Cfg  ! RT_Assembly_Config
  PUBLIC :: RT_Asm_ComputeResidual
  PUBLIC :: RT_Asm_ComputeTangent
  PUBLIC :: RT_Asm_AssembleK_M_ForModal
  PUBLIC :: RT_Asm_AssembleHeatMatrices
  PUBLIC :: RT_Asm_AssembleThermalForce
  PUBLIC :: RT_Asm_AssembleElectricMatrices
  PUBLIC :: RT_Asm_AssembleJouleHeat
  PUBLIC :: RT_Asm_CoupledTE_AssembleThermalBranch
  PUBLIC :: RT_Asm_AssembleCreepForce
  PUBLIC :: RT_Asm_AssembleSoilsBlock
  PUBLIC :: RT_Asm_AssembleAcousticMatrices
  PUBLIC :: RT_Asm_AssembleElectroMagMatrices
  PUBLIC :: RT_Asm_AssembleTransportMatrices
  PUBLIC :: RT_Asm_AssemblePiezoCoupling
  PUBLIC :: RT_Asm_AddGeostaticGravity
  ! Phase 3: Index-based hot path overloads (entity_idx, arg, status)
  PUBLIC :: RT_Asm_GlobalStiffness_Idx
  PUBLIC :: RT_Asm_ComputeResidual_Idx
  PUBLIC :: RT_Asm_GlobalStiffness_Arg
  PUBLIC :: RT_Asm_ComputeResidual_Arg

  PRIVATE :: RT_Asm_Solv_KeArg_AttachMatProps, RT_Asm_Solv_KeArg_ClearMatProps
  PRIVATE :: RT_Asm_Solv_FeArg_AttachLoadMagn, RT_Asm_Solv_FeArg_ClearLoadMagn

  !=============================================================================
  ! Assembly Configuration Type
  !=============================================================================
  TYPE, PUBLIC :: RT_Asm_Cfg  ! RT_Assembly_Config
    LOGICAL :: use_parallel = .FALSE.        ! Legacy flag; prefer assembly_mode
    INTEGER(i4) :: assembly_mode = 0_i4      ! 0=SERIAL, 1=OMP_COLORING, 2=OMP_ATOMIC
    LOGICAL :: assemble_stiffness = .TRUE.  ! Assemble K matrix
    LOGICAL :: assemble_load = .TRUE.       ! Assemble F_ext
    LOGICAL :: apply_bc = .TRUE.            ! Apply boundary conditions
    LOGICAL :: apply_contact = .FALSE.      ! Apply contact constraints
    LOGICAL :: apply_l3_constraints = .TRUE. ! Tie/MPC/Cpl/Rigid from L3 constraint_union (penalty, dense patch)
    REAL(wp) :: constraint_penalty = 0.0_wp  ! <=0: use RT_Ldbc default penalty
    LOGICAL :: mpc_penalty_triplet_merge = .TRUE.  ! MPC via triplet merge (large models)
    LOGICAL :: l3_non_mpc_triplet_merge = .TRUE.   ! Tie/Cpl/Rigid penalty via triplet merge
    LOGICAL :: verbose = .FALSE.            ! Verbose output
    INTEGER(i4) :: n_threads = 0_i4         ! 0 = use default
    LOGICAL :: reuse_sparsity = .TRUE.     ! zero values + accumulate into existing CSR
    LOGICAL :: contact_csr_delta_merge = .FALSE.
    INTEGER(i4) :: contact_dense_dof_cap = 0_i4
    LOGICAL :: contact_try_ph_search = .FALSE.
    LOGICAL :: contact_use_triplet_merge = .FALSE.
    INTEGER(i4) :: contact_triplet_merge_max_dof = 0_i4
    ! .TRUE.: LOAD_BODY_FORCE on _Idx path is lumped into F_ext (default, matches legacy).
    ! .FALSE.: skip BODY in RT_Asm_GlobalLoad _Idx; RT_Asm_ComputeResidual injects rho*g into
    !          PH_Element_Compute_Fe_Arg%load_magn_in (do not also call RT_Asm_AddGeostaticGravity).
    LOGICAL :: body_force_lumped_to_fext = .TRUE.
  END TYPE RT_Asm_Cfg
  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: RT_Asm_Solv_Args
  TYPE :: RT_Asm_Solv_Args
  ! Purpose: —�?  ! Theory:
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE RT_Asm_Solv_Args

  ! Phase 3: Arg types for _Idx API (entity_idx, arg, status)
  TYPE, PUBLIC :: RT_Asm_GlobalStiffness_Arg
    TYPE(RT_CSRMatrix) :: K
    TYPE(RT_Asm_Cfg) :: config
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Asm_GlobalStiffness_Arg
  TYPE, PUBLIC :: RT_Asm_ComputeResidual_Arg
    REAL(wp), ALLOCATABLE :: u(:)
    REAL(wp) :: lambda = 1.0_wp
    REAL(wp), ALLOCATABLE :: F_ext(:)
    REAL(wp), ALLOCATABLE :: R(:)
    TYPE(RT_CSRMatrix), POINTER :: K_tangent => NULL()
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Asm_ComputeResidual_Arg

  ! Upper bound for element slice in PH_Element_Compute_Fe_Arg%u / per-element Ke work arrays.
  ! Registry: C3D27P/C3D27T = 108; keep headroom for small growth.
  INTEGER(i4), PARAMETER, PRIVATE :: RT_ASM_MAX_ELEM_DOF = 120_i4

  
CONTAINS

  SUBROUTINE RT_Asm_ApplyBC(model, step, time, dofMap, K, F, dof_mask, config, status)
    !! Apply boundary conditions to system ( Model LoadBCalgorithm)
    !! Apply boundary conditions
    !! Step 1:  inputparam
    !! Step 2:  BCDef
    !! Step 3:  BC Model 
    !! Step 4:  displacementboundary condition?LoadBC_ApplyBC_Displacement
    !! Step 5:  velocityboundary condition?LoadBC_ApplyBC_Velocity
    !! Step 6:  velocityboundary condition?LoadBC_ApplyBC_Acceleration
    !! Step 7:  DOF 
    !! Step 8: returnstatus
    
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    REAL(wp), INTENT(IN) :: time
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K
    REAL(wp), INTENT(INOUT) :: F(:)
    INTEGER(i4), INTENT(INOUT), OPTIONAL :: dof_mask(:)
    TYPE(RT_Asm_Cfg), INTENT(IN), OPTIONAL :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(RT_Asm_Cfg) :: cfg
    TYPE(BCDef) :: bc
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: nDOF, iBC, nBCs, nConstrained, i
    ! P2 _Idx path
    INTEGER(i4) :: step_idx, eq_id, p, p_start, p_end
    INTEGER(i4) :: n_bcs
    REAL(wp) :: penalty, presc_val
    LOGICAL :: found
    TYPE(PH_BC_Cache_Type), ALLOCATABLE :: ph_bc_cache(:)
    
    CALL init_error_status(status)
    
    ! Step 1:  inputparam
    nDOF = dofMap%nTotalEq
    IF (nDOF /= SIZE(F)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_ApplyBC: Size mismatch'
      RETURN
    END IF
    
    IF (PRESENT(config)) THEN
      cfg = config
    ELSE
      cfg = RT_Asm_Cfg()
    END IF
    
    ! P2 _Idx path: when g_ufc_global ready and loadbc initialized, use BuildStepBCs_Idx
    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%desc%loadbc%initialized .AND. &
        g_ufc_global%md_layer%desc%step%initialized) THEN
      step_idx = g_ufc_global%md_layer%desc%step%current_step_idx
      IF (step_idx >= 1_i4) THEN
        CALL init_error_status(local_status)
        CALL MD_LoadBC_PH_Brg_BuildStepBCs_Idx(step_idx, time, ph_bc_cache, n_bcs, local_status)
        IF (local_status%status_code == IF_STATUS_OK .AND. n_bcs > 0_i4 .AND. ALLOCATED(ph_bc_cache)) THEN
          ! Convert ph_bc_cache to dof_indices + prescribed_values, apply penalty
          nConstrained = 0_i4
          penalty = 1.0e12_wp
          DO i = 1, n_bcs
            eq_id = RT_Asm_DofMap_GetEqId(dofMap, ph_bc_cache(i)%nodeId, ph_bc_cache(i)%dof)
            IF (eq_id > 0_i4 .AND. eq_id <= nDOF) THEN
              presc_val = ph_bc_cache(i)%value * ph_bc_cache(i)%amp_factor
              ! Penalty: K(eq,eq) += penalty, F(eq) = penalty * presc_val
              IF (ALLOCATED(K%rowPtr) .AND. ALLOCATED(K%colInd) .AND. ALLOCATED(K%values)) THEN
                p_start = K%rowPtr(eq_id)
                p_end = K%rowPtr(eq_id + 1) - 1
                found = .FALSE.
                DO p = p_start, p_end
                  IF (K%colInd(p) == eq_id) THEN
                    K%values(p) = K%values(p) + penalty
                    F(eq_id) = F(eq_id) + penalty * presc_val
                    found = .TRUE.
                    EXIT
                  END IF
                END DO
                IF (.NOT. found) F(eq_id) = F(eq_id) + penalty * presc_val
              ELSE
                F(eq_id) = F(eq_id) + penalty * presc_val
              END IF
              nConstrained = nConstrained + 1_i4
            END IF
          END DO
          IF (ALLOCATED(ph_bc_cache)) DEALLOCATE(ph_bc_cache)
          status%status_code = IF_STATUS_OK
          WRITE(status%message, '(A,I0,A)') &
            'Boundary conditions applied (_Idx): ', nConstrained, ' constrained DOFs'
          RETURN
        END IF
        IF (ALLOCATED(ph_bc_cache)) DEALLOCATE(ph_bc_cache)
      END IF
    END IF
    
    ! Step 2:  BCDef (Legacy path)
    nConstrained = 0_i4
    IF (ASSOCIATED(step%bcDefs)) THEN
      nBCs = SIZE(step%bcDefs)
      
      DO iBC = 1, nBCs
        bc = step%bcDefs(iBC)
        
        ! checkBCwhetheractive time 
        IF (.NOT. bc%active) CYCLE  ! isActive ??active
        IF (time < bc%startTime .OR. time > bc%endTime) CYCLE
        
        ! Step 3-6:  BC Model 
        SELECT CASE (bc%bcType)
        CASE (BC_DISPLACEMENT)
          ! P0: Apply displacement BC via penalty (K(eq,eq)+=penalty, F(eq)=penalty*value)
          CALL RT_Asm_ApplyBC_Displacement_Penalty(bc, model, time, dofMap, K, F, &
               dof_mask, penalty, local_status)
          
        CASE (BC_VELOCITY)
          IF (g_ufc_global%IsReady()) THEN
            CALL LoadBC_ApplyBC_Velocity(bc, model, time, F, dof_mask, local_status, &
                 g_ufc_global%md_layer)
          ELSE
            CALL LoadBC_ApplyBC_Velocity(bc, model, time, F, dof_mask, local_status)
          END IF
          
        CASE (BC_ACCELERATION)
          IF (g_ufc_global%IsReady()) THEN
            CALL LoadBC_ApplyBC_Acceleration(bc, model, time, F, dof_mask, local_status, &
                 g_ufc_global%md_layer)
          ELSE
            CALL LoadBC_ApplyBC_Acceleration(bc, model, time, F, dof_mask, local_status)
          END IF
          
        CASE DEFAULT
          local_status%status_code = IF_STATUS_INVALID
          WRITE(local_status%message, '(A,I0)') 'Unknown BC type: ', bc%bcType
        END SELECT
        
        ! check status
        IF (local_status%status_code /= IF_STATUS_OK) THEN
          status = local_status
          RETURN
        END IF
        
        nConstrained = nConstrained + 1_i4
      END DO
    END IF
    
    ! Step 7:  DOF
    IF (PRESENT(dof_mask)) THEN
      nConstrained = COUNT(dof_mask == 0_i4)
    END IF
    
    ! Step 8: returnstatus
    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,I0,A)') &
      'Boundary conditions applied: ', nConstrained, ' constrained DOFs'
    
  END SUBROUTINE RT_Asm_ApplyBC

  !-----------------------------------------------------------------------------
  ! RT_Asm_ApplyBC_Displacement_Penalty: Apply displacement BC via penalty method
  ! Theory: K(eq,eq) += penalty, F(eq) = penalty * u_prescribed
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_ApplyBC_Displacement_Penalty(bc, model, time, dofMap, K, F, &
       dof_mask, penalty, status)
    TYPE(BCDef), INTENT(IN) :: bc
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(IN) :: time
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K
    REAL(wp), INTENT(INOUT) :: F(:)
    INTEGER(i4), INTENT(INOUT), OPTIONAL :: dof_mask(:)
    REAL(wp), INTENT(IN) :: penalty
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4), ALLOCATABLE :: nodeIds(:), dofs(:)
    REAL(wp), ALLOCATABLE :: values(:)
    INTEGER(i4) :: nOut, i, eq_id, p, p_start, p_end
    LOGICAL :: found

    IF (g_ufc_global%IsReady()) THEN
      CALL LoadBC_ApplyBC_Displacement_GetNodes(bc, model, time, nodeIds, dofs, &
           values, nOut, status, g_ufc_global%md_layer)
    ELSE
      CALL LoadBC_ApplyBC_Displacement_GetNodes(bc, model, time, nodeIds, dofs, &
           values, nOut, status)
    END IF
    IF (status%status_code /= IF_STATUS_OK .OR. nOut <= 0_i4) RETURN

    DO i = 1_i4, nOut
      eq_id = RT_Asm_DofMap_GetEqId(dofMap, nodeIds(i), dofs(i))
      IF (eq_id <= 0_i4 .OR. eq_id > SIZE(F)) CYCLE

      F(eq_id) = F(eq_id) + penalty * values(i)

      IF (ALLOCATED(K%rowPtr) .AND. ALLOCATED(K%colInd) .AND. ALLOCATED(K%values)) THEN
        p_start = K%rowPtr(eq_id)
        p_end = K%rowPtr(eq_id + 1) - 1
        found = .FALSE.
        DO p = p_start, p_end
          IF (K%colInd(p) == eq_id) THEN
            K%values(p) = K%values(p) + penalty
            found = .TRUE.
            EXIT
          END IF
        END DO
        ! If diagonal missing in CSR, F already has penalty*value; K would need structural add
      END IF

      IF (PRESENT(dof_mask)) THEN
        IF (eq_id >= 1_i4 .AND. eq_id <= SIZE(dof_mask)) dof_mask(eq_id) = 0_i4
      END IF
    END DO

    IF (ALLOCATED(nodeIds)) DEALLOCATE(nodeIds)
    IF (ALLOCATED(dofs)) DEALLOCATE(dofs)
    IF (ALLOCATED(values)) DEALLOCATE(values)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_ApplyBC_Displacement_Penalty

  SUBROUTINE RT_Asm_ApplyContact(model, step, state, K, F, config, status, dofMap, l3_csr_reanalyze_required)
    !! Apply contact via L3 interaction domain -> MD_Cont_PH_FillParams_FromMD -> PH_Cont_Ctx / PH_Cont_ApplyConstraints.
    !!
    !! CSR write-back (see cfg%contact_csr_delta_merge) when using dense PH path:
    !!   .FALSE. (default): for each stored (i,j) in CSR, K(i,j) := K_dense(i,j) (contact cannot introduce new sparsity).
    !!   .TRUE.: snapshot K_dense after CSR import as K0; after PH edits, RT_CSR_AddToValue(K,i,j, K_dense(i,j)-K0(i,j)).
    !!
    !! Triplet path (cfg%contact_use_triplet_merge): contact_Assemble_triplets on top of exported K triplets;
    !! RT_CSR_FromTripletMerged �?allows new fill-in; sets l3_csr_reanalyze_required = .TRUE. on success.
    !!
    !! Search: cfg%contact_try_ph_search uses md_layer%assembly%global_coords (3,nn) + state%du_inc mapped via dofMap.
    
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    TYPE(StepStateData), INTENT(IN) :: state
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(RT_Asm_Cfg), INTENT(IN), OPTIONAL :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap
    LOGICAL, INTENT(OUT), OPTIONAL :: l3_csr_reanalyze_required
    
    TYPE(RT_Asm_Cfg) :: cfg
    TYPE(PH_ContactCtx) :: ctx
    TYPE(PH_Cont_ApplyConstraints_In) :: constraints_in
    TYPE(PH_Cont_ApplyConstraints_Out) :: constraints_out
    TYPE(PH_Cont_SearchPairs_In) :: search_in
    TYPE(PH_Cont_SearchPairs_Out) :: search_out
    TYPE(PH_Contact_Params) :: ph_params
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: nContact, iContact, nActive, nDOF
    REAL(wp), ALLOCATABLE :: K_dense(:,:)
    REAL(wp), ALLOCATABLE :: K0(:,:)
    INTEGER(i4) :: i, j, row_start, row_end, col_idx
    REAL(wp) :: dkc
    REAL(wp), ALLOCATABLE, TARGET :: cont_xn(:,:)
    REAL(wp), ALLOCATABLE, TARGET :: cont_ud(:,:)
    INTEGER(i4) :: nn_s, nid, c, ierr_ct, ierr_asm, cap_tl, ieq, nn_map
    TYPE(RT_TripletList) :: tl_contact
    TYPE(MD_NodeDisp), ALLOCATABLE :: nodeStates(:)
    LOGICAL :: search_ready, use_triplet_merge
    
    CALL init_error_status(status)
    IF (PRESENT(l3_csr_reanalyze_required)) l3_csr_reanalyze_required = .FALSE.
    
    ! Step 1: Input parameter validation (Domain only, legacy model%interactions removed)
    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%interaction%initialized) THEN
      status%status_code = IF_STATUS_OK
      status%message = 'No contact interactions defined'
      RETURN
    END IF
    IF (g_ufc_global%md_layer%desc%interaction%n_pairs <= 0_i4) THEN
      status%status_code = IF_STATUS_OK
      status%message = 'No contact interactions defined'
      RETURN
    END IF
    
    IF (PRESENT(config)) THEN
      cfg = config
    ELSE
      cfg = RT_Asm_Cfg()
    END IF
    
    IF (.NOT. cfg%apply_contact) THEN
      status%status_code = IF_STATUS_OK
      status%message = 'Contact application disabled in config'
      RETURN
    END IF
    
    nDOF = SIZE(F)
    IF (K%nRows /= nDOF .OR. K%nCols /= nDOF) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_ApplyContact: Matrix size mismatch'
      RETURN
    END IF

    IF (cfg%contact_dense_dof_cap > 0_i4 .AND. nDOF > cfg%contact_dense_dof_cap) THEN
      status%status_code = IF_STATUS_OK
      WRITE(status%message, '(A,I0,A,I0,A)') &
        'RT_Asm_ApplyContact: skipped (nDOF=', nDOF, ' > contact_dense_dof_cap=', cfg%contact_dense_dof_cap, ')'
      RETURN
    END IF

    IF (cfg%contact_use_triplet_merge .AND. .NOT. PRESENT(dofMap)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_ApplyContact: contact_use_triplet_merge requires dofMap'
      RETURN
    END IF

    use_triplet_merge = cfg%contact_use_triplet_merge
    IF (use_triplet_merge) THEN
      IF (cfg%contact_triplet_merge_max_dof > 0_i4 .AND. nDOF > cfg%contact_triplet_merge_max_dof) THEN
        use_triplet_merge = .FALSE.
      ELSE IF (.NOT. ALLOCATED(dofMap%nodeToEqStart)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'RT_Asm_ApplyContact: triplet-merge needs allocated dofMap%nodeToEqStart'
        RETURN
      END IF
    END IF

    search_ready = .FALSE.
    NULLIFY(search_in%node_coords)
    NULLIFY(search_in%node_displacements)
    IF (cfg%contact_try_ph_search .AND. g_ufc_global%IsReady() .AND. &
        g_ufc_global%md_layer%desc%assembly%initialized .AND. &
        ALLOCATED(g_ufc_global%md_layer%desc%assembly%global_coords) .AND. &
        g_ufc_global%md_layer%desc%assembly%total_nodes > 0_i4) THEN
      nn_s = g_ufc_global%md_layer%desc%assembly%total_nodes
      ALLOCATE(cont_xn(3, nn_s), cont_ud(3, nn_s))
      cont_xn(:, 1:nn_s) = g_ufc_global%md_layer%desc%assembly%global_coords(:, 1:nn_s)
      cont_ud = 0.0_wp
      IF (PRESENT(dofMap)) THEN
        IF (ALLOCATED(dofMap%nodeToEqStart)) THEN
          nn_map = MIN(nn_s, SIZE(dofMap%nodeToEqStart))
          DO nid = 1, nn_map
            DO c = 1, 3
              ieq = RT_Asm_DofMap_GetEqId(dofMap, nid, c)
              IF (ALLOCATED(state%du_inc) .AND. ieq >= 1 .AND. ieq <= SIZE(state%du_inc)) THEN
                cont_ud(c, nid) = state%du_inc(ieq)
              END IF
            END DO
          END DO
        END IF
      END IF
      search_in%node_coords => cont_xn
      search_in%node_displacements => cont_ud
      search_ready = .TRUE.
    END IF

    IF (use_triplet_merge) THEN
      IF (cfg%contact_try_ph_search .AND. search_ready) THEN
        IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%desc%step%initialized) THEN
          CALL PH_Cont_Ctx_Init(ctx, 0, 0, 0, 1.0e6_wp, 0.3_wp, local_status, &
              step_idx=g_ufc_global%md_layer%desc%step%current_step_idx, &
              incr_idx=g_ufc_global%md_layer%desc%step%current_incr_idx)
        ELSE
          CALL PH_Cont_Ctx_Init(ctx, 0, 0, 0, 1.0e6_wp, 0.3_wp, local_status)
        END IF
        IF (local_status%status_code == IF_STATUS_OK) &
            CALL PH_Cont_SearchPairs_API(ctx, search_in, search_out)
        CALL PH_Cont_Ctx_Clear(ctx)
        CALL init_error_status(local_status)
      END IF
      cap_tl = K%nnz + MIN(nDOF * nDOF, 64_i4 * MAX(1_i4, nDOF)) + 1024_i4
      CALL RT_Triplet_Init(tl_contact, cap_tl)
      IF (K%init .AND. ALLOCATED(K%rowPtr) .AND. ALLOCATED(K%colInd) .AND. ALLOCATED(K%values)) THEN
        DO i = 1, nDOF
          row_end = K%rowPtr(i + 1) - 1
          DO j = K%rowPtr(i), row_end
            col_idx = K%colInd(j)
            IF (col_idx >= 1_i4 .AND. col_idx <= nDOF) CALL RT_Triplet_Add(tl_contact, i, col_idx, K%values(j))
          END DO
        END DO
      END IF
      nn_map = SIZE(dofMap%nodeToEqStart)
      ALLOCATE(nodeStates(nn_map))
      DO nid = 1, nn_map
        nodeStates(nid)%cfg%id = nid
        nodeStates(nid)%u_curr = 0.0_wp
        DO c = 1, 3
          ieq = RT_Asm_DofMap_GetEqId(dofMap, nid, c)
          IF (ALLOCATED(state%du_inc) .AND. ieq >= 1 .AND. ieq <= SIZE(state%du_inc)) THEN
            nodeStates(nid)%u_curr(c) = state%du_inc(ieq)
          END IF
        END DO
      END DO
      ierr_asm = 0_i4
      CALL contact_Assemble_triplets(model, dofMap, nodeStates, tl_contact, F, ierr_asm)
      IF (ierr_asm /= 0_i4) THEN
        CALL RT_Triplet_Free(tl_contact)
        DEALLOCATE(nodeStates)
        IF (ALLOCATED(cont_xn)) THEN
          NULLIFY(search_in%node_coords, search_in%node_displacements)
          DEALLOCATE(cont_xn, cont_ud)
        END IF
        status%status_code = IF_STATUS_ERROR
        WRITE (status%message, '(A,I0)') 'RT_Asm_ApplyContact: contact_Assemble_triplets ierr=', ierr_asm
        RETURN
      END IF
      CALL RT_CSR_FromTripletMerged(tl_contact, nDOF, nDOF, K, ierr_ct)
      CALL RT_Triplet_Free(tl_contact)
      DEALLOCATE(nodeStates)
      IF (ALLOCATED(cont_xn)) THEN
        NULLIFY(search_in%node_coords, search_in%node_displacements)
        DEALLOCATE(cont_xn, cont_ud)
      END IF
      IF (ierr_ct /= 0_i4) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE (status%message, '(A,I0)') 'RT_Asm_ApplyContact: RT_CSR_FromTripletMerged failed ierr=', ierr_ct
        RETURN
      END IF
      IF (PRESENT(l3_csr_reanalyze_required)) l3_csr_reanalyze_required = .TRUE.
      status%status_code = IF_STATUS_OK
      status%message = 'RT_Asm_ApplyContact: triplet-merge path (l3_csr_reanalyze_required)'
      RETURN
    END IF
    
    ! Step 2: Initialize contact context (step_idx/incr_idx from md_layer for three-step indexing)
    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%desc%step%initialized) THEN
      CALL PH_Cont_Ctx_Init(ctx, 0, 0, 0, 1.0e6_wp, 0.3_wp, local_status, &
                            step_idx=g_ufc_global%md_layer%desc%step%current_step_idx, &
                            incr_idx=g_ufc_global%md_layer%desc%step%current_incr_idx)
    ELSE
      CALL PH_Cont_Ctx_Init(ctx, 0, 0, 0, 1.0e6_wp, 0.3_wp, local_status)
    END IF
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      status = local_status
      IF (ALLOCATED(cont_xn)) THEN
        NULLIFY(search_in%node_coords, search_in%node_displacements)
        DEALLOCATE(cont_xn, cont_ud)
      END IF
      RETURN
    END IF
    
    ! Dense workspace for PH_Cont_ApplyConstraints (toy kernel uses small DOF blocks; full model needs triplet path later)
    ALLOCATE(K_dense(nDOF, nDOF))
    K_dense = 0.0_wp
    
    DO i = 1, nDOF
      row_start = K%rowPtr(i)
      row_end = K%rowPtr(i+1) - 1
      DO j = row_start, row_end
        col_idx = K%colInd(j)
        IF (col_idx > 0 .AND. col_idx <= nDOF) THEN
          K_dense(i, col_idx) = K%values(j)
        END IF
      END DO
    END DO

    IF (cfg%contact_csr_delta_merge) THEN
      ALLOCATE(K0(nDOF, nDOF))
      K0 = K_dense
    END IF
    
    ! Step 3-5: Process contact pairs (Domain only)
    nContact = g_ufc_global%md_layer%desc%interaction%n_pairs
    nActive = 0_i4
    
    DO iContact = 1, nContact
      ph_params = PH_Contact_Params()
      ! Get contact pair data from g_ufc_global%md_layer%desc%interaction%pairs(iContact)
      BLOCK
        TYPE(MD_ContactPairDef) :: pair_def
        TYPE(MD_ContactProperty) :: prop
        TYPE(MD_Asm_GetSurfaceByName_Arg) :: surf_arg
        REAL(wp) :: penalty, friction
        INTEGER(i4) :: ip, master_id, slave_id
        IF (ALLOCATED(g_ufc_global%md_layer%desc%interaction%pairs) .AND. &
            iContact <= SIZE(g_ufc_global%md_layer%desc%interaction%pairs)) THEN
          pair_def = g_ufc_global%md_layer%desc%interaction%pairs(iContact)
          penalty = 1.0e6_wp
          friction = 0.3_wp
          master_id = iContact
          slave_id = iContact
          IF (ALLOCATED(g_ufc_global%md_layer%desc%interaction%props)) THEN
            DO ip = 1, SIZE(g_ufc_global%md_layer%desc%interaction%props)
              IF (TRIM(g_ufc_global%md_layer%desc%interaction%props(ip)%name) == TRIM(pair_def%prop_name)) THEN
                prop = g_ufc_global%md_layer%desc%interaction%props(ip)
                CALL MD_Cont_PH_FillParams_FromMD(prop, ph_params, local_status, pair_def=pair_def)
                IF (local_status%status_code == IF_STATUS_OK) THEN
                  penalty = MAX(1.0e4_wp, ph_params%phys%penaltyNormal)
                  friction = ph_params%phys%frictionCoeff
                ELSE
                  CALL init_error_status(local_status)
                  penalty = MAX(1.0e4_wp, prop%pressure_overclosure%penalty_stiffness)
                  friction = prop%friction%mu_static
                  IF (friction <= 0.0_wp) friction = prop%friction%mu_kinetic
                END IF
                EXIT
              END IF
            END DO
          END IF
          IF (g_ufc_global%md_layer%desc%assembly%initialized .AND. &
              g_ufc_global%md_layer%desc%assembly%n_surfaces > 0_i4) THEN
            CALL MD_Assembly_GetSurfaceByName_Idx(TRIM(pair_def%master_surface), surf_arg, local_status)
            IF (surf_arg%found .AND. surf_arg%def%surf_id > 0_i4) master_id = surf_arg%def%surf_id
            CALL MD_Assembly_GetSurfaceByName_Idx(TRIM(pair_def%slave_surface), surf_arg, local_status)
            IF (surf_arg%found .AND. surf_arg%def%surf_id > 0_i4) slave_id = surf_arg%def%surf_id
            CALL init_error_status(local_status)
          END IF
          IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%desc%step%initialized) THEN
            CALL PH_Cont_Ctx_Init(ctx, iContact, slave_id, master_id, penalty, friction, local_status, &
                                  step_idx=g_ufc_global%md_layer%desc%step%current_step_idx, &
                                  incr_idx=g_ufc_global%md_layer%desc%step%current_incr_idx)
          ELSE
            CALL PH_Cont_Ctx_Init(ctx, iContact, slave_id, master_id, penalty, friction, local_status)
          END IF
          IF (local_status%status_code /= IF_STATUS_OK) CYCLE
          ctx%tolerance = MAX(1.0e-12_wp, ph_params%ctrl%contactTol)
          IF (cfg%contact_try_ph_search .AND. search_ready) THEN
            CALL PH_Cont_SearchPairs_API(ctx, search_in, search_out)
          END IF
        END IF
      END BLOCK
      constraints_in%stiffness_matrix => K_dense
      constraints_in%force_vector => F
      CALL PH_Cont_ApplyConstraints_API(ctx, constraints_in, constraints_out)
      
      IF (constraints_out%status%status_code /= IF_STATUS_OK) THEN
        status = constraints_out%status
        DEALLOCATE(K_dense)
        IF (ALLOCATED(K0)) DEALLOCATE(K0)
        CALL PH_Cont_Ctx_Clear(ctx)
        IF (ALLOCATED(cont_xn)) THEN
          NULLIFY(search_in%node_coords, search_in%node_displacements)
          DEALLOCATE(cont_xn, cont_ud)
        END IF
        RETURN
      END IF
      
      ! Count active contacts (simplified check)
      IF (ctx%contact_state == 1) THEN
        nActive = nActive + 1_i4
      END IF
    END DO
    
    ! Step 6: CSR write-back (pattern-limited unless separate triplet+reanalyze path)
    IF (cfg%contact_csr_delta_merge .AND. ALLOCATED(K0)) THEN
      DO i = 1, nDOF
        row_start = K%rowPtr(i)
        row_end = K%rowPtr(i+1) - 1
        DO j = row_start, row_end
          col_idx = K%colInd(j)
          IF (col_idx > 0 .AND. col_idx <= nDOF) THEN
            dkc = K_dense(i, col_idx) - K0(i, col_idx)
            IF (dkc /= 0.0_wp) CALL RT_CSR_AddToValue(K, i, col_idx, dkc)
          END IF
        END DO
      END DO
      DEALLOCATE(K0)
    ELSE
      DO i = 1, nDOF
        row_start = K%rowPtr(i)
        row_end = K%rowPtr(i+1) - 1
        DO j = row_start, row_end
          col_idx = K%colInd(j)
          IF (col_idx > 0 .AND. col_idx <= nDOF) THEN
            K%values(j) = K_dense(i, col_idx)
          END IF
        END DO
      END DO
    END IF
    
    DEALLOCATE(K_dense)
    CALL PH_Cont_Ctx_Clear(ctx)

    IF (ALLOCATED(cont_xn)) THEN
      NULLIFY(search_in%node_coords, search_in%node_displacements)
      DEALLOCATE(cont_xn, cont_ud)
    END IF
    
    ! Step 7-8: Return status
    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,I0,A,I0,A)') &
      'Contact applied: ', nActive, ' active / ', nContact, ' total pairs'
    
  END SUBROUTINE RT_Asm_ApplyContact

  !-----------------------------------------------------------------------------
  ! RT_Asm_MPCPenalty_MergeIntoCSR: κ·A^T·A and F += -κ·A^T·b via triplet export
  ! of current K + MPC terms, sort/merge, RT_CSR_FromTripletMerged (fills CSR).
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_MPCPenalty_MergeIntoCSR(K, F, mpc_list, n_mpc, kappa, ndofpn, status, dof_map)
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(MPCConstraintDef), INTENT(IN) :: mpc_list(:)
    INTEGER(i4), INTENT(IN) :: n_mpc
    REAL(wp), INTENT(IN) :: kappa
    INTEGER(i4), INTENT(IN) :: ndofpn
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dof_map

    TYPE(RT_TripletList) :: tl
    INTEGER(i4) :: nDOF, row, p, p_end, col_idx
    INTEGER(i4) :: ierr, cap, n_add, im, nt_loc
    TYPE(ErrorStatusType) :: st_mpc

    CALL init_error_status(status)
    nDOF = SIZE(F)
    IF (n_mpc < 1_i4) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (K%nRows /= nDOF .OR. K%nCols /= nDOF) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_MPCPenalty_MergeIntoCSR: K/F size mismatch'
      RETURN
    END IF

    n_add = 0_i4
    DO im = 1, MIN(n_mpc, SIZE(mpc_list))
      nt_loc = mpc_list(im)%n_terms
      IF (nt_loc > 0_i4) n_add = n_add + nt_loc * nt_loc
    END DO
    cap = MAX(128_i4, K%nnz + n_add + 64_i4)
    CALL RT_Triplet_Init(tl, cap)

    IF (K%init .AND. ALLOCATED(K%rowPtr) .AND. ALLOCATED(K%colInd) .AND. ALLOCATED(K%values)) THEN
      DO row = 1, nDOF
        p_end = K%rowPtr(row + 1) - 1
        DO p = K%rowPtr(row), p_end
          col_idx = K%colInd(p)
          IF (col_idx >= 1_i4 .AND. col_idx <= nDOF) &
            CALL RT_Triplet_Add(tl, row, col_idx, K%values(p))
        END DO
      END DO
    END IF

    CALL init_error_status(st_mpc)
    IF (PRESENT(dof_map)) THEN
      CALL RT_Ldbc_MPCPenalty_AppendTriplets(tl, F, mpc_list, n_mpc, kappa, ndofpn, nDOF, st_mpc, dof_map)
    ELSE
      CALL RT_Ldbc_MPCPenalty_AppendTriplets(tl, F, mpc_list, n_mpc, kappa, ndofpn, nDOF, st_mpc)
    END IF
    IF (st_mpc%status_code /= IF_STATUS_OK) THEN
      CALL RT_Triplet_Free(tl)
      status = st_mpc
      RETURN
    END IF

    CALL RT_CSR_FromTripletMerged(tl, nDOF, nDOF, K, ierr)
    CALL RT_Triplet_Free(tl)
    IF (ierr /= 0_i4) THEN
      status%status_code = IF_STATUS_ERROR
      WRITE (status%message, '(A,I0)') 'RT_CSR_FromTripletMerged failed ierr=', ierr
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_MPCPenalty_MergeIntoCSR

  !-----------------------------------------------------------------------------
  ! RT_Asm_ApplyL3Constraints: penalty assembly from md_layer%constraint_union
  ! MPC: optional triplet merge. Tie/Cpl/Rigid: default triplet merge (cfg%l3_non_mpc_triplet_merge)
  ! so penalty fill is not dropped by old CSR pattern; optional dense fallback.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_ApplyL3Constraints(K, F, cfg, status, dofMap, l3_csr_reanalyze_required)
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(RT_Asm_Cfg), INTENT(IN) :: cfg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap
    LOGICAL, INTENT(OUT), OPTIONAL :: l3_csr_reanalyze_required

    TYPE(Model) :: mdl
    REAL(wp), ALLOCATABLE :: K_dense(:,:)
    INTEGER(i4) :: nDOF, i, j, row_start, row_end, col_idx
    INTEGER(i4) :: nt, nm, nc, nr
    INTEGER(i4) :: ndofpn, im, nt_loc, ierr, cap, n_add, it2, ic2, ir2
    TYPE(ErrorStatusType) :: st_loc, st_mpc, st_trip
    LOGICAL :: has_any
    LOGICAL :: sparse_mpc
    LOGICAL :: want_non_mpc_triplet
    REAL(wp) :: kappa_loc
    TYPE(RT_TripletList) :: tl

    CALL init_error_status(status)
    IF (PRESENT(l3_csr_reanalyze_required)) l3_csr_reanalyze_required = .FALSE.

    IF (.NOT. cfg%apply_l3_constraints) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%constraint%initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    nt = 0_i4
    nm = 0_i4
    nc = 0_i4
    nr = 0_i4
    ASSOCIATE (cu => g_ufc_global%md_layer%constraint%constraint_union)
      IF (ALLOCATED(cu%tie) .AND. cu%n_tie > 0_i4) &
        nt = MIN(cu%n_tie, SIZE(cu%tie))
      IF (ALLOCATED(cu%mpc) .AND. cu%n_mpc > 0_i4) &
        nm = MIN(cu%n_mpc, SIZE(cu%mpc))
      IF (ALLOCATED(cu%cpl) .AND. cu%n_cpl > 0_i4) &
        nc = MIN(cu%n_cpl, SIZE(cu%cpl))
      IF (ALLOCATED(cu%rigid) .AND. cu%n_rigid > 0_i4) &
        nr = MIN(cu%n_rigid, SIZE(cu%rigid))
      has_any = (nt > 0_i4 .OR. nm > 0_i4 .OR. nc > 0_i4 .OR. nr > 0_i4)

      IF (has_any) THEN
        DO it2 = 1, nt
          CALL MD_TieConstraint_TryResolveSurfaces(cu%tie(it2), st_loc)
        END DO
        DO ic2 = 1, nc
          CALL MD_CplConstraint_TryResolveSurfaceOrElset(cu%cpl(ic2), st_loc)
        END DO
        DO ir2 = 1, nr
          CALL MD_RigidBody_TryResolveFromAssembly(cu%rigid(ir2), st_loc)
        END DO
      END IF
    END ASSOCIATE

    IF (.NOT. has_any) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    nDOF = SIZE(F)
    IF (K%nRows /= nDOF .OR. K%nCols /= nDOF) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_ApplyL3Constraints: K/F size mismatch'
      RETURN
    END IF

    ndofpn = 3_i4
    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%desc%mesh%initialized .AND. &
        g_ufc_global%md_layer%desc%mesh%raw_data%spatial_dim >= 2_i4) &
      ndofpn = g_ufc_global%md_layer%desc%mesh%raw_data%spatial_dim

    kappa_loc = 1.0e10_wp
    IF (cfg%constraint_penalty > 0.0_wp) kappa_loc = cfg%constraint_penalty

    sparse_mpc = cfg%mpc_penalty_triplet_merge .AND. nm > 0_i4
    want_non_mpc_triplet = cfg%l3_non_mpc_triplet_merge .AND. (nt > 0_i4 .OR. nc > 0_i4 .OR. nr > 0_i4)

    IF (sparse_mpc) THEN
      CALL init_error_status(st_mpc)
      ASSOCIATE (cu => g_ufc_global%md_layer%constraint%constraint_union)
        IF (PRESENT(dofMap)) THEN
          CALL RT_Asm_MPCPenalty_MergeIntoCSR(K, F, cu%mpc, nm, kappa_loc, ndofpn, st_mpc, dof_map=dofMap)
        ELSE
          CALL RT_Asm_MPCPenalty_MergeIntoCSR(K, F, cu%mpc, nm, kappa_loc, ndofpn, st_mpc)
        END IF
      END ASSOCIATE
      IF (st_mpc%status_code /= IF_STATUS_OK) THEN
        status = st_mpc
        RETURN
      END IF
    END IF

    IF (want_non_mpc_triplet) THEN
      n_add = 0_i4
      IF (.NOT. sparse_mpc .AND. nm > 0_i4) THEN
        IF (ALLOCATED(g_ufc_global%md_layer%constraint%constraint_union%mpc)) THEN
          DO im = 1, MIN(nm, SIZE(g_ufc_global%md_layer%constraint%constraint_union%mpc))
            nt_loc = g_ufc_global%md_layer%constraint%constraint_union%mpc(im)%n_terms
            IF (nt_loc > 0_i4) n_add = n_add + nt_loc * nt_loc
          END DO
        END IF
      END IF
      cap = MAX(256_i4, K%nnz + n_add + 4096_i4)
      ASSOCIATE (cu => g_ufc_global%md_layer%constraint%constraint_union)
        DO it2 = 1, nt
          cap = cap + MAX(64_i4, cu%tie(it2)%n_pairs * 24_i4)
        END DO
        cap = cap + nc * 512_i4 + nr * 512_i4
      END ASSOCIATE

      CALL RT_Triplet_Init(tl, cap)
      IF (K%init .AND. ALLOCATED(K%rowPtr) .AND. ALLOCATED(K%colInd) .AND. ALLOCATED(K%values)) THEN
        DO i = 1, nDOF
          row_end = K%rowPtr(i + 1) - 1
          DO j = K%rowPtr(i), row_end
            col_idx = K%colInd(j)
            IF (col_idx >= 1_i4 .AND. col_idx <= nDOF) CALL RT_Triplet_Add(tl, i, col_idx, K%values(j))
          END DO
        END DO
      END IF

      CALL init_error_status(st_trip)
      ASSOCIATE (cu => g_ufc_global%md_layer%constraint%constraint_union)
        IF (.NOT. sparse_mpc .AND. nm > 0_i4) THEN
          IF (PRESENT(dofMap)) THEN
            CALL RT_Ldbc_MPCPenalty_AppendTriplets(tl, F, cu%mpc, nm, kappa_loc, ndofpn, nDOF, st_trip, dofMap)
          ELSE
            CALL RT_Ldbc_MPCPenalty_AppendTriplets(tl, F, cu%mpc, nm, kappa_loc, ndofpn, nDOF, st_trip)
          END IF
          IF (st_trip%status_code /= IF_STATUS_OK) THEN
            CALL RT_Triplet_Free(tl)
            status = st_trip
            RETURN
          END IF
        END IF

        DO it2 = 1, nt
          IF (PRESENT(dofMap)) THEN
            CALL RT_Ldbc_TiePenalty_AppendTriplets(cu%tie(it2), tl, kappa_loc, ndofpn, nDOF, st_trip, dofMap)
          ELSE
            CALL RT_Ldbc_TiePenalty_AppendTriplets(cu%tie(it2), tl, kappa_loc, ndofpn, nDOF, st_trip)
          END IF
          IF (st_trip%status_code /= IF_STATUS_OK) THEN
            CALL RT_Triplet_Free(tl)
            status = st_trip
            RETURN
          END IF
        END DO

        DO ic2 = 1, nc
          IF (PRESENT(dofMap)) THEN
            CALL RT_Ldbc_CplPenalty_AppendTriplets(cu%cpl(ic2), tl, kappa_loc, ndofpn, nDOF, st_trip, dofMap)
          ELSE
            CALL RT_Ldbc_CplPenalty_AppendTriplets(cu%cpl(ic2), tl, kappa_loc, ndofpn, nDOF, st_trip)
          END IF
          IF (st_trip%status_code /= IF_STATUS_OK) THEN
            CALL RT_Triplet_Free(tl)
            status = st_trip
            RETURN
          END IF
        END DO

        DO ir2 = 1, nr
          IF (PRESENT(dofMap)) THEN
            CALL RT_Ldbc_RigidPenalty_AppendTriplets(cu%rigid(ir2), tl, kappa_loc, ndofpn, nDOF, st_trip, dofMap)
          ELSE
            CALL RT_Ldbc_RigidPenalty_AppendTriplets(cu%rigid(ir2), tl, kappa_loc, ndofpn, nDOF, st_trip)
          END IF
          IF (st_trip%status_code /= IF_STATUS_OK) THEN
            CALL RT_Triplet_Free(tl)
            status = st_trip
            RETURN
          END IF
        END DO
      END ASSOCIATE

      CALL RT_CSR_FromTripletMerged(tl, nDOF, nDOF, K, ierr)
      CALL RT_Triplet_Free(tl)
      IF (ierr /= 0_i4) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE (status%message, '(A,I0)') 'RT_Asm_ApplyL3Constraints: RT_CSR_FromTripletMerged ierr=', ierr
        RETURN
      END IF
      IF (PRESENT(l3_csr_reanalyze_required)) l3_csr_reanalyze_required = .TRUE.
      status%status_code = IF_STATUS_OK
      status%message = 'L3 constraints: Tie/Cpl/Rigid (+MPC if needed) merged via triplets; reanalyze sparse factors'
      RETURN
    END IF

    IF (nt == 0_i4 .AND. nc == 0_i4 .AND. nr == 0_i4) THEN
      IF (sparse_mpc .OR. nm == 0_i4) THEN
        IF (sparse_mpc .AND. PRESENT(l3_csr_reanalyze_required)) l3_csr_reanalyze_required = .TRUE.
        status%status_code = IF_STATUS_OK
        status%message = 'L3 MPC penalty applied via triplet merge (CSR)'
        RETURN
      END IF
    END IF

    ALLOCATE(K_dense(nDOF, nDOF))
    K_dense = 0.0_wp
    DO i = 1, nDOF
      row_start = K%rowPtr(i)
      row_end = K%rowPtr(i + 1) - 1
      DO j = row_start, row_end
        col_idx = K%colInd(j)
        IF (col_idx > 0 .AND. col_idx <= nDOF) K_dense(i, col_idx) = K%values(j)
      END DO
    END DO

    CALL init_error_status(st_loc)
    ASSOCIATE (cu => g_ufc_global%md_layer%constraint%constraint_union)
      IF (cfg%constraint_penalty > 0.0_wp) THEN
        IF (nt > 0_i4) CALL RT_Ldbc_ConstApply_All(mdl, K_dense, F, METHOD_PENALTY, &
            cfg%constraint_penalty, st_loc, tie_list=cu%tie(1:nt), ndof_per_node=ndofpn)
        IF (st_loc%status_code == IF_STATUS_OK .AND. nm > 0_i4 .AND. .NOT. sparse_mpc) &
          CALL RT_Ldbc_ConstApply_All(mdl, K_dense, F, METHOD_PENALTY, cfg%constraint_penalty, st_loc, &
            mpc_list=cu%mpc(1:nm), ndof_per_node=ndofpn)
        IF (st_loc%status_code == IF_STATUS_OK .AND. nc > 0_i4) &
          CALL RT_Ldbc_ConstApply_All(mdl, K_dense, F, METHOD_PENALTY, cfg%constraint_penalty, st_loc, &
            coupling_list=cu%cpl(1:nc), ndof_per_node=ndofpn)
        IF (st_loc%status_code == IF_STATUS_OK .AND. nr > 0_i4) &
          CALL RT_Ldbc_ConstApply_All(mdl, K_dense, F, METHOD_PENALTY, cfg%constraint_penalty, st_loc, &
            rigid_list=cu%rigid(1:nr), ndof_per_node=ndofpn)
      ELSE
        IF (nt > 0_i4) CALL RT_Ldbc_ConstApply_All(mdl, K_dense, F, METHOD_PENALTY, st_loc, &
            tie_list=cu%tie(1:nt), ndof_per_node=ndofpn)
        IF (st_loc%status_code == IF_STATUS_OK .AND. nm > 0_i4 .AND. .NOT. sparse_mpc) &
          CALL RT_Ldbc_ConstApply_All(mdl, K_dense, F, METHOD_PENALTY, st_loc, &
            mpc_list=cu%mpc(1:nm), ndof_per_node=ndofpn)
        IF (st_loc%status_code == IF_STATUS_OK .AND. nc > 0_i4) &
          CALL RT_Ldbc_ConstApply_All(mdl, K_dense, F, METHOD_PENALTY, st_loc, &
            coupling_list=cu%cpl(1:nc), ndof_per_node=ndofpn)
        IF (st_loc%status_code == IF_STATUS_OK .AND. nr > 0_i4) &
          CALL RT_Ldbc_ConstApply_All(mdl, K_dense, F, METHOD_PENALTY, st_loc, &
            rigid_list=cu%rigid(1:nr), ndof_per_node=ndofpn)
      END IF
    END ASSOCIATE

    IF (st_loc%status_code /= IF_STATUS_OK) THEN
      status = st_loc
      DEALLOCATE(K_dense)
      RETURN
    END IF

    DO i = 1, nDOF
      row_start = K%rowPtr(i)
      row_end = K%rowPtr(i + 1) - 1
      DO j = row_start, row_end
        col_idx = K%colInd(j)
        IF (col_idx > 0 .AND. col_idx <= nDOF) K%values(j) = K_dense(i, col_idx)
      END DO
    END DO
    DEALLOCATE(K_dense)

    status%status_code = IF_STATUS_OK
    status%message = 'L3 constraints applied (dense fallback path for Tie/Cpl/Rigid)'
  END SUBROUTINE RT_Asm_ApplyL3Constraints

  SUBROUTINE RT_Asm_Complete(model, step, state, time, dofMap, &
                                   K, F_ext, dof_mask, config, status, l3_csr_reanalyze_required)
    !! Complete assembly pipeline ( 
    !!  ?K + F_ext + BC + Contact
    !! Step 1:  inputparam
    !! Step 2:  stiffnessmatrixK
    !! Step 3:  loadvectorF_ext
    !! Step 4:  boundary condition
    !! Step 5:  contact force
    !! Step 6: check matrix vector 
    !! Step 7:  
    !! Step 8: returnstatus
    
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    TYPE(StepStateData), INTENT(IN) :: state
    REAL(wp), INTENT(IN) :: time
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K
    REAL(wp), INTENT(INOUT) :: F_ext(:)
    INTEGER(i4), INTENT(INOUT), OPTIONAL :: dof_mask(:)
    TYPE(RT_Asm_Cfg), INTENT(IN), OPTIONAL :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(OUT), OPTIONAL :: l3_csr_reanalyze_required
    
    TYPE(RT_Asm_Cfg) :: cfg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: nDOF
    CHARACTER(LEN=256) :: msg
    LOGICAL :: l3_re, l3_ct
    TYPE(RT_Asm_TripartiteKey) :: trip_key
    INTEGER(i4) :: trip_lin
    
    CALL init_error_status(status)
    l3_re = .FALSE.
    l3_ct = .FALSE.
    IF (PRESENT(l3_csr_reanalyze_required)) l3_csr_reanalyze_required = .FALSE.
    
    ! Step 1:  inputparam
    nDOF = dofMap%nTotalEq
    IF (nDOF <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_Complete: Invalid DOF count'
      RETURN
    END IF
    
    IF (PRESENT(config)) THEN
      cfg = config
    ELSE
      cfg = RT_Asm_Cfg()
    END IF

    ! Phase6 §3.2: tripartite linear index (dispatch table hook; COLD in Complete)
    trip_key%elem_stem_id = 1_i4
    trip_key%section_rule_id = 1_i4
    trip_key%material_leaf_id = 1_i4
    trip_lin = RT_Asm_Tripartite_LinearIndex(trip_key, 1_i4, 1_i4)
    IF (trip_lin /= 1_i4) THEN
      CONTINUE
    END IF
    
    ! Step 2:  stiffnessmatrix
    IF (cfg%assemble_stiffness) THEN
      CALL RT_Asm_GlobalStiffness(model, step, state, dofMap, K, cfg, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
      END IF
    END IF
    
    ! Step 3:  loadvector
    IF (cfg%assemble_load) THEN
      CALL RT_Asm_GlobalLoad(model, step, time, dofMap, F_ext, cfg, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
      END IF
    END IF
    
    ! Step 4:  boundary condition
    IF (cfg%apply_bc) THEN
      CALL RT_Asm_ApplyBC(model, step, time, dofMap, K, F_ext, dof_mask, cfg, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
      END IF
    END IF

    IF (cfg%apply_l3_constraints) THEN
      CALL RT_Asm_ApplyL3Constraints(K, F_ext, cfg, local_status, dofMap=dofMap, &
          l3_csr_reanalyze_required=l3_re)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
      END IF
      IF (PRESENT(l3_csr_reanalyze_required)) l3_csr_reanalyze_required = l3_re
    END IF
    
    ! Step 5:  contact 
    IF (cfg%apply_contact) THEN
      CALL RT_Asm_ApplyContact(model, step, state, K, F_ext, cfg, local_status, dofMap=dofMap, &
          l3_csr_reanalyze_required=l3_ct)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
      END IF
      IF (PRESENT(l3_csr_reanalyze_required)) l3_csr_reanalyze_required = l3_csr_reanalyze_required .OR. l3_ct
    END IF
    
    ! Step 6: check ??
    IF (K%nnz <= 0_i4 .AND. cfg%assemble_stiffness) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'RT_Asm_Complete: Empty stiffness matrix'
      RETURN
    END IF
    
    ! Step 7-8:  
    status%status_code = IF_STATUS_OK
    WRITE(msg, '(A,I0,A,I0,A)') &
      'Assembly complete: ', nDOF, ' DOFs, ', K%nnz, ' non-zeros'
    status%message = TRIM(msg)
    
    IF (cfg%verbose) THEN
      PRINT '(A)', TRIM(status%message)
    END IF
    
  END SUBROUTINE RT_Asm_Complete

  SUBROUTINE RT_Asm_ComputeResidual(model, step, state, dofMap, u, lambda, &
                                         F_ext, R, status, K_tangent, asm_config)
    !! Compute residual R = F_ext - F_int(u) at current displacement u.
    !! F_ext must already include assembled external loads (RT_Asm_GlobalLoad, gravity, etc.).
    !! F_int from PH_Element_Compute_Fe: keep load_magn_in zero for BODY/DLOAD already in F_ext.
    !! asm_config%body_force_lumped_to_fext=.FALSE.: BODY skipped in GlobalLoad _Idx; rho*g in load_magn_in.
    !! Prefer real F_int from PH_Element_Compute_Fe when PH path available;
    !! else fallback to F_int = K_tangent * u when K_tangent present.
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    TYPE(StepStateData), INTENT(IN) :: state
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    REAL(wp), INTENT(IN) :: u(:)
    REAL(wp), INTENT(IN) :: lambda
    REAL(wp), INTENT(IN) :: F_ext(:)
    REAL(wp), INTENT(OUT) :: R(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(RT_CSRMatrix), INTENT(IN), OPTIONAL :: K_tangent
    TYPE(RT_Asm_Cfg), INTENT(IN), OPTIONAL :: asm_config
    
    INTEGER(i4) :: nDOF, nElems, iElem, jDOF, npe, n_dof, eq_id
    INTEGER(i4) :: spatial_dim, elem_typ_reg
    TYPE(PH_Elem_Reg_Entry), POINTER :: ep_reg_fe
    REAL(wp), ALLOCATABLE :: F_int(:)
    LOGICAL :: use_ph
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(PH_Element_Compute_Fe_Arg) :: fe_arg
    TYPE(ErrorStatusType) :: mesh_st
    TYPE(RT_Asm_Cfg) :: fe_asm_cfg
    
    CALL init_error_status(status)
    nDOF = dofMap%nTotalEq
    IF (nDOF <= 0_i4 .OR. SIZE(u) /= nDOF .OR. SIZE(F_ext) /= nDOF .OR. SIZE(R) /= nDOF) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_ComputeResidual: Size mismatch'
      RETURN
    END IF
    
    R = F_ext
    IF (PRESENT(asm_config)) THEN
      fe_asm_cfg = asm_config
    ELSE
      fe_asm_cfg = RT_Asm_Cfg()
    END IF
    use_ph = g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%desc%mesh%initialized .AND. &
             g_ufc_global%ph_layer%element%is_initialized
    
    IF (use_ph) THEN
      ALLOCATE(F_int(nDOF))
      F_int = 0.0_wp
      nElems = g_ufc_global%ph_layer%element%n_elements
      IF (nElems <= 0_i4) nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)

      !$OMP PARALLEL DO DEFAULT(NONE) &
      !$OMP   SHARED(nElems, nDOF, dofMap, u, step, g_ufc_global, fe_asm_cfg) &
      !$OMP   PRIVATE(iElem, arg_conn, mesh_st, npe, spatial_dim, n_dof, &
      !$OMP           elem_typ_reg, ep_reg_fe, fe_arg, jDOF, eq_id) &
      !$OMP   REDUCTION(+:F_int) &
      !$OMP   SCHEDULE(DYNAMIC, 64)
      DO iElem = 1, nElems
        CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
        npe = arg_conn%npe
        spatial_dim = 3_i4
        IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_ndim_cache) .AND. &
            iElem <= SIZE(g_ufc_global%ph_layer%element%elem_ndim_cache)) THEN
          spatial_dim = g_ufc_global%ph_layer%element%elem_ndim_cache(iElem)
          IF (spatial_dim < 2_i4) spatial_dim = 3_i4
        END IF
        n_dof = npe * spatial_dim
        elem_typ_reg = 0_i4
        NULLIFY(ep_reg_fe)
        IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
            iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) THEN
          elem_typ_reg = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
          ep_reg_fe => PH_Elem_Reg_Get(elem_typ_reg)
          IF (ASSOCIATED(ep_reg_fe) .AND. ep_reg_fe%pop%n_dof > 0_i4) n_dof = ep_reg_fe%pop%n_dof
        END IF
        IF (n_dof < 1_i4 .OR. n_dof > RT_ASM_MAX_ELEM_DOF) CYCLE
        CALL init_error_status(fe_arg%status)
        fe_arg%l3_elem_idx = iElem
        fe_arg%mat_pt_idx = RT_Asm_Brg_ElemMatPtIdx(iElem)
        fe_arg%nDof = n_dof
        fe_arg%u = 0.0_wp
        DO jDOF = 1, n_dof
          eq_id = RT_Asm_Solv_LocalJToEqId(dofMap, arg_conn%connect, npe, elem_typ_reg, n_dof, jDOF)
          IF (eq_id > 0_i4 .AND. eq_id <= nDOF) fe_arg%u(jDOF) = u(eq_id)
        END DO
        IF (.NOT. ALLOCATED(fe_arg%Fe) .OR. SIZE(fe_arg%Fe) < n_dof) THEN
          IF (ALLOCATED(fe_arg%Fe)) DEALLOCATE(fe_arg%Fe)
          ALLOCATE(fe_arg%Fe(n_dof))
        END IF
        CALL RT_Asm_Solv_FeArg_AttachLoadMagn(fe_arg, step, spatial_dim, iElem, fe_asm_cfg)
        CALL g_ufc_global%ph_layer%element%Compute_Fe(fe_arg)
        CALL RT_Asm_Solv_FeArg_ClearLoadMagn(fe_arg)
        IF (fe_arg%status%status_code /= IF_STATUS_OK) CYCLE
        DO jDOF = 1, n_dof
          eq_id = RT_Asm_Solv_LocalJToEqId(dofMap, arg_conn%connect, npe, elem_typ_reg, n_dof, jDOF)
          IF (eq_id > 0_i4 .AND. eq_id <= nDOF) F_int(eq_id) = F_int(eq_id) + fe_arg%Fe(jDOF)
        END DO
      END DO
      !$OMP END PARALLEL DO

      R = F_ext - F_int
      DEALLOCATE(F_int)
    ELSE IF (PRESENT(K_tangent)) THEN
      IF (K_tangent%nnz > 0_i4 .AND. K_tangent%nRows == nDOF) THEN
        ALLOCATE(F_int(nDOF))
        CALL RT_CSR_SpMV(K_tangent, u, F_int)
        R = F_ext - F_int
        DEALLOCATE(F_int)
      END IF
    END IF
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_ComputeResidual

  SUBROUTINE RT_Asm_ComputeTangent(model, step, state, dofMap, u, K, config, status)
    !! Assemble tangent stiffness K at current displacement u.
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    TYPE(StepStateData), INTENT(IN) :: state
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    REAL(wp), INTENT(IN) :: u(:)
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K
    TYPE(RT_Asm_Cfg), INTENT(IN), OPTIONAL :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    CALL RT_Asm_GlobalStiffness(model, step, state, dofMap, K, config, status)
  END SUBROUTINE RT_Asm_ComputeTangent

  SUBROUTINE RT_Asm_GlobalLoad(model, step, time, dofMap, F_ext, config, status)
    !! Assemble global load vector from all load definitions
    !!  loadvector ??Model LoadBCalgorithm
    !! Step 1:  inputparam?model, step, dofMap
    !! Step 2: initloadvectorF_ext = 0
    !! Step 3:  LoadDef??Model 
    !! Step 4:  load?LoadBC_DistributeLoad_ToNodes
    !! Step 5:  load?LoadBC_DistributeLoad_ToElements
    !! Step 6:  load?LoadBC_DistributeLoad_ToSurface
    !! Step 7: checkloadvector ??
    !! Step 8: returnstatus
    
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    REAL(wp), INTENT(IN) :: time
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    REAL(wp), INTENT(INOUT) :: F_ext(:)
    TYPE(RT_Asm_Cfg), INTENT(IN), OPTIONAL :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(RT_Asm_Cfg) :: cfg
    TYPE(LoadDef) :: load
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: nDOF, iLoad, nLoads, s_step
    TYPE(LoadDef), ALLOCATABLE, TARGET :: auto_legacy_ld(:)
    TYPE(LoadDef), POINTER :: ld_work(:)
    REAL(wp) :: load_norm
    ! P2 _Idx path
    INTEGER(i4) :: step_idx, load_idx, i, j, dof, node_id, eq_id, n_cload_applied
    INTEGER(i4) :: lt_ldbc
    INTEGER(i4) :: ie, npe, k, elem_id, iface, nface, nfn, fn_local(4)
    REAL(wp) :: amp_factor, mag, load_per_node
    LOGICAL :: need_legacy_fallback, handled
    TYPE(MD_LBC_GetLoadsForStep_Arg) :: step_arg
    TYPE(MD_LBC_GetLoad_Arg) :: load_arg
    TYPE(MD_Asm_GetNodeSetByName_Arg) :: nset_arg
    TYPE(MD_Asm_GetElemSetByName_Arg) :: elset_arg
    TYPE(MD_Asm_GetSurfaceByName_Arg) :: surf_arg
    TYPE(MD_Mesh_GetElemConnect_Arg) :: conn_arg
    
    CALL init_error_status(status)
    NULLIFY(ld_work)
    nLoads = 0_i4

    ! Step 1:  inputparam
    nDOF = dofMap%nTotalEq
    IF (nDOF /= SIZE(F_ext)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_GlobalLoad: Size mismatch'
      RETURN
    END IF
    
    IF (PRESENT(config)) THEN
      cfg = config
    ELSE
      cfg = RT_Asm_Cfg()
    END IF
    
    ! Step 2: initloadvector
    F_ext = 0.0_wp
    ! _Idx path below lumps DLOAD/BODY_FORCE/PRESSURE onto nodes where nset/elset/surf apply.
    ! Same physical load must not be re-injected via PH_Element_Compute_Fe_Arg%load_magn_in
    ! in RT_Asm_ComputeResidual (double-count in R = F_ext - F_int).

    ! P2 _Idx path: CLOAD + DLOAD/BODY_FORCE from Domain when g_ufc_global ready
    IF (cfg%assemble_load .AND. g_ufc_global%IsReady() .AND. &
        g_ufc_global%md_layer%desc%loadbc%initialized .AND. &
        g_ufc_global%md_layer%desc%step%initialized .AND. &
        g_ufc_global%md_layer%desc%assembly%initialized .AND. &
        g_ufc_global%md_layer%desc%mesh%initialized) THEN
      step_idx = g_ufc_global%md_layer%desc%step%current_step_idx
      IF (step_idx >= 1_i4) THEN
        CALL init_error_status(local_status)
        step_arg%n_found = 0_i4
        IF (ALLOCATED(step_arg%load_indices)) DEALLOCATE(step_arg%load_indices)
        CALL MD_LoadBC_GetLoadsForStep_Idx(step_idx, step_arg, local_status)
        IF (local_status%status_code == IF_STATUS_OK .AND. step_arg%n_found > 0_i4) THEN
          n_cload_applied = 0_i4
          need_legacy_fallback = .FALSE.
          DO i = 1, step_arg%n_found
            load_idx = step_arg%load_indices(i)
            CALL MD_LoadBC_GetLoad_Idx(load_idx, load_arg, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
              need_legacy_fallback = .TRUE.
              CYCLE
            END IF
            ! Amplitude (L5 unified entry: domain EvalAtTime with fallback)
            CALL RT_Amp_FactorAt(load_arg%desc%amp_ref, time, amp_factor)
            mag = load_arg%desc%magnitude * amp_factor
            dof = MAX(1_i4, load_arg%desc%dof)
            handled = .FALSE.
            lt_ldbc = MD_LoadBC_ToLdbcLoadType(load_arg%desc%load_type)
            IF (lt_ldbc == MD_LOADBC_LDBC_INVALID) THEN
              IF (load_arg%desc%load_type >= 1_i4 .AND. load_arg%desc%load_type <= 8_i4) THEN
                lt_ldbc = load_arg%desc%load_type
              ELSE
                lt_ldbc = LOAD_CLOAD
              END IF
            END IF
            ! CLOAD: node_id direct or target_set (nset)
            IF (lt_ldbc == LOAD_CLOAD) THEN
              IF (load_arg%desc%node_id > 0_i4) THEN
                eq_id = RT_Asm_DofMap_GetEqId(dofMap, load_arg%desc%node_id, dof)
                IF (eq_id > 0_i4 .AND. eq_id <= nDOF) THEN
                  F_ext(eq_id) = F_ext(eq_id) + mag
                  n_cload_applied = n_cload_applied + 1_i4
                END IF
                handled = .TRUE.
              ELSE IF (LEN_TRIM(load_arg%desc%target_set) > 0) THEN
                CALL MD_Assembly_GetNodeSetByName_Idx(TRIM(load_arg%desc%target_set), nset_arg, local_status)
                IF (nset_arg%found .AND. ALLOCATED(nset_arg%def%members)) THEN
                  DO j = 1, SIZE(nset_arg%def%members)
                    node_id = nset_arg%def%members(j)
                    eq_id = RT_Asm_DofMap_GetEqId(dofMap, node_id, dof)
                    IF (eq_id > 0_i4 .AND. eq_id <= nDOF) THEN
                      F_ext(eq_id) = F_ext(eq_id) + mag
                      n_cload_applied = n_cload_applied + 1_i4
                    END IF
                  END DO
                  handled = .TRUE.
                END IF
              END IF
            ! DLOAD / DSLOAD / BODY_FORCE / explicit PRESSURE: target_set as nset, elset, or surface
            ELSE IF ((lt_ldbc == LOAD_DLOAD .OR. lt_ldbc == LOAD_DSLOAD .OR. &
                      lt_ldbc == LOAD_BODY_FORCE .OR. lt_ldbc == LOAD_PRESSURE) .AND. &
                     LEN_TRIM(load_arg%desc%target_set) > 0) THEN
              IF (lt_ldbc == LOAD_BODY_FORCE .AND. .NOT. cfg%body_force_lumped_to_fext) THEN
                handled = .TRUE.
              ELSE
              ! Try nset first (distributed to nodes)
              CALL MD_Assembly_GetNodeSetByName_Idx(TRIM(load_arg%desc%target_set), nset_arg, local_status)
              IF (nset_arg%found .AND. ALLOCATED(nset_arg%def%members)) THEN
                npe = SIZE(nset_arg%def%members)
                IF (npe > 0_i4) THEN
                  load_per_node = mag / REAL(npe, wp)
                  DO j = 1, npe
                    node_id = nset_arg%def%members(j)
                    IF (node_id <= 0_i4) CYCLE
                    eq_id = RT_Asm_DofMap_GetEqId(dofMap, node_id, dof)
                    IF (eq_id > 0_i4 .AND. eq_id <= nDOF) THEN
                      F_ext(eq_id) = F_ext(eq_id) + load_per_node
                      n_cload_applied = n_cload_applied + 1_i4
                    END IF
                  END DO
                  handled = .TRUE.
                END IF
              END IF
              ! Try elset if nset not found
              IF (.NOT. handled) THEN
                CALL MD_Assembly_GetElemSetByName_Idx(TRIM(load_arg%desc%target_set), elset_arg, local_status)
                IF (elset_arg%found .AND. ALLOCATED(elset_arg%def%members)) THEN
                  DO ie = 1, SIZE(elset_arg%def%members)
                    elem_id = elset_arg%def%members(ie)
                    IF (elem_id <= 0_i4) CYCLE
                    CALL MD_Mesh_GetElemConnect_Idx(elem_id, conn_arg, local_status)
                    IF (local_status%status_code /= IF_STATUS_OK .OR. conn_arg%npe <= 0) CYCLE
                    npe = conn_arg%npe
                    load_per_node = mag / REAL(npe, wp)
                    DO k = 1, npe
                      node_id = INT(conn_arg%connect(k), i4)
                      IF (node_id <= 0_i4) CYCLE
                      eq_id = RT_Asm_DofMap_GetEqId(dofMap, node_id, dof)
                      IF (eq_id > 0_i4 .AND. eq_id <= nDOF) THEN
                        F_ext(eq_id) = F_ext(eq_id) + load_per_node
                        n_cload_applied = n_cload_applied + 1_i4
                      END IF
                    END DO
                  END DO
                  handled = .TRUE.
                END IF
              END IF
              ! Try surface (DLOAD / DSLOAD / explicit PRESSURE) if elset not found
              IF (.NOT. handled .AND. (lt_ldbc == LOAD_DLOAD .OR. lt_ldbc == LOAD_DSLOAD .OR. &
                                       lt_ldbc == LOAD_PRESSURE)) THEN
                CALL MD_Assembly_GetSurfaceByName_Idx(TRIM(load_arg%desc%target_set), surf_arg, local_status)
                IF (surf_arg%found .AND. surf_arg%def%n_faces > 0_i4 .AND. &
                    ALLOCATED(surf_arg%def%elem_ids) .AND. ALLOCATED(surf_arg%def%face_ids)) THEN
                  nface = MIN(surf_arg%def%n_faces, SIZE(surf_arg%def%elem_ids), SIZE(surf_arg%def%face_ids))
                  DO iface = 1, nface
                    elem_id = surf_arg%def%elem_ids(iface)
                    IF (elem_id <= 0_i4) CYCLE
                    CALL MD_Mesh_GetElemConnect_Idx(elem_id, conn_arg, local_status)
                    IF (local_status%status_code /= IF_STATUS_OK .OR. conn_arg%npe <= 0) CYCLE
                    ! C3D8 face local nodes: face 1=(1,2,3,4), 2=(5,8,7,6), 3=(1,2,6,5), 4=(4,3,7,8), 5=(1,4,8,5), 6=(2,6,7,3)
                    k = surf_arg%def%face_ids(iface)
                    IF (k >= 1_i4 .AND. k <= 6_i4 .AND. conn_arg%npe >= 8_i4) THEN
                      SELECT CASE (k)
                      CASE (1); fn_local = (/ 1,2,3,4 /)
                      CASE (2); fn_local = (/ 5,8,7,6 /)
                      CASE (3); fn_local = (/ 1,2,6,5 /)
                      CASE (4); fn_local = (/ 4,3,7,8 /)
                      CASE (5); fn_local = (/ 1,4,8,5 /)
                      CASE (6); fn_local = (/ 2,6,7,3 /)
                      CASE DEFAULT; fn_local = (/ 1,2,3,4 /)
                      END SELECT
                      nfn = 4_i4
                      load_per_node = mag / REAL(nfn, wp)
                      DO j = 1, nfn
                        node_id = INT(conn_arg%connect(fn_local(j)), i4)
                        IF (node_id <= 0_i4) CYCLE
                        eq_id = RT_Asm_DofMap_GetEqId(dofMap, node_id, dof)
                        IF (eq_id > 0_i4 .AND. eq_id <= nDOF) THEN
                          F_ext(eq_id) = F_ext(eq_id) + load_per_node
                          n_cload_applied = n_cload_applied + 1_i4
                        END IF
                      END DO
                      handled = .TRUE.
                    END IF
                  END DO
                END IF
              END IF
              END IF
            END IF
            IF (.NOT. handled) need_legacy_fallback = .TRUE.
          END DO
          IF (ALLOCATED(step_arg%load_indices)) DEALLOCATE(step_arg%load_indices)
          load_norm = SQRT(SUM(F_ext**2))
          status%status_code = IF_STATUS_OK
          IF (need_legacy_fallback) THEN
            WRITE(status%message, '(A,I0,A,ES12.5,A)') &
              'Load vector (_Idx): ', n_cload_applied, ' applied, norm = ', load_norm, &
              '; some loads skipped (single source: Domain only)'
          ELSE
            WRITE(status%message, '(A,I0,A,ES12.5)') &
              'Load vector (_Idx): ', n_cload_applied, ' applied, norm = ', load_norm
          END IF
          ! Load vector: _Idx and Domain fallback to Legacy path
          RETURN
        END IF
        IF (ALLOCATED(step_arg%load_indices)) DEALLOCATE(step_arg%load_indices)
      END IF
    END IF
    
    ! Step 3:  LoadDef (Legacy path) — explicit UF_Step_AttachLoadDefs(step, arr(:)) or auto-build from L3 loadbc
    ! P4 vertical slice: MD_LoadBC_SyncFromLegacy → L3 LoadDef (nested cfg/tgt/val/stp + flat mirror) →
    !    UF_Step_BuildLegacyLoadDefs_FromLdbc (Step module) → RT_Asm_GlobalLoad cold path (sync/router/L5).
    IF (ASSOCIATED(step%loadDefs)) THEN
      ld_work => step%loadDefs
    ELSE IF (g_ufc_global%IsReady()) THEN
      s_step = step%step_number
      IF (s_step < 1_i4 .AND. g_ufc_global%md_layer%desc%step%initialized) &
          s_step = g_ufc_global%md_layer%desc%step%current_step_idx
      IF (s_step < 1_i4) s_step = 1_i4
      CALL init_error_status(local_status)
      CALL UF_Step_BuildLegacyLoadDefs_FromLdbc(g_ufc_global%md_layer%desc%loadbc, model, &
          s_step, auto_legacy_ld, local_status)
      IF (local_status%status_code == IF_STATUS_OK .AND. ALLOCATED(auto_legacy_ld) &
          .AND. SIZE(auto_legacy_ld) > 0_i4) THEN
        ld_work => auto_legacy_ld
      END IF
    END IF

    IF (ASSOCIATED(ld_work)) THEN
      nLoads = SIZE(ld_work)

      DO iLoad = 1, nLoads
        load = ld_work(iLoad)
        
        ! checkloadwhetheractive time 
        IF (.NOT. load%isActive) CYCLE
        IF (time < load%startTime .OR. time > load%endTime) CYCLE
        IF (.NOT. cfg%body_force_lumped_to_fext) THEN
          IF (load%loadType == LOAD_BODY_FORCE .OR. load%loadType == LOAD_GRAVITY) CYCLE
        END IF
        
        ! Step 4-6:  load Model (set id in arg 3; amplitude uses md_layer when global ready)
        SELECT CASE (load%targetType)
        CASE (TARGET_NODE, TARGET_NODESET)
          IF (g_ufc_global%IsReady()) THEN
            CALL LoadBC_DistributeLoad_ToNodes(load, model, load%targetId, time, F_ext, &
                 local_status, g_ufc_global%md_layer)
          ELSE
            CALL LoadBC_DistributeLoad_ToNodes(load, model, load%targetId, time, F_ext, &
                 local_status)
          END IF
          
        CASE (TARGET_ELEMSET)
          IF (g_ufc_global%IsReady()) THEN
            CALL LoadBC_DistributeLoad_ToElements(load, model, load%targetId, time, F_ext, &
                 local_status, g_ufc_global%md_layer)
          ELSE
            CALL LoadBC_DistributeLoad_ToElements(load, model, load%targetId, time, F_ext, &
                 local_status)
          END IF
          
        CASE (TARGET_SURFACE)
          IF (g_ufc_global%IsReady()) THEN
            CALL LoadBC_DistributeLoad_ToSurface(load, model, load%targetId, time, F_ext, &
                 local_status, g_ufc_global%md_layer)
          ELSE
            CALL LoadBC_DistributeLoad_ToSurface(load, model, load%targetId, time, F_ext, &
                 local_status)
          END IF
          
        CASE DEFAULT
          local_status%status_code = IF_STATUS_INVALID
          WRITE(local_status%message, '(A,I0)') &
            'Unknown load target type: ', load%targetType
        END SELECT
        
        ! check status
        IF (local_status%status_code /= IF_STATUS_OK) THEN
          status = local_status
          RETURN
        END IF
      END DO
    END IF

    IF (ALLOCATED(auto_legacy_ld)) DEALLOCATE(auto_legacy_ld)
    
    ! Step 7: checkloadvector ??
    load_norm = SQRT(SUM(F_ext**2))
    
    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,ES12.5,A,I0)') &
      'Load vector assembled: norm = ', load_norm, ', ', nLoads, ' loads'
    
  END SUBROUTINE RT_Asm_GlobalLoad

  SUBROUTINE RT_Asm_GlobalStiffness(model, step, state, dofMap, K, config, status)
    !! Assemble global stiffness matrix from element contributions
    !!  stiffnessmatrix 
    !! Step 1:  inputparam?model, step, dofMap
    !! Step 2: initTriplet init
    !! Step 3:  element?computationelementstiffnessmatrixKe
    !! Step 4:  Ke Triplet 
    !! Step 5:  Triplet CSR matrix
    !! Step 6: checkmatrix 
    !! Step 7: cleanupTriplet 
    !! Step 8: returnstatus
    
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    TYPE(StepStateData), INTENT(IN) :: state
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K
    TYPE(RT_Asm_Cfg), INTENT(IN), OPTIONAL :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(RT_Asm_Cfg) :: cfg
    TYPE(RT_TripletList) :: K_triplets
    INTEGER(i4) :: nDOF, nElems, estNnz
    INTEGER(i4) :: iElem, iDOF, jDOF, npe, n_dof
    INTEGER(i4) :: spatial_dim, elem_typ_reg
    INTEGER(i4) :: trip_lin, trip_dispatch
    TYPE(RT_Asm_TripartiteKey) :: trip_key
    REAL(wp), ALLOCATABLE :: Ke(:,:)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(PH_Element_Compute_Ke_Arg) :: ke_arg
    TYPE(ErrorStatusType) :: mesh_st
    TYPE(PH_Elem_Reg_Entry), POINTER :: ep_reg_ke
    LOGICAL :: use_ph
    
    CALL init_error_status(status)
    
    ! Step 1:  inputparam
    IF (.NOT. ASSOCIATED(model%mesh)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_GlobalStiffness: Model mesh not initialized'
      RETURN
    END IF
    
    nDOF = dofMap%nTotalEq
    IF (nDOF <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_GlobalStiffness: Invalid DOF count'
      RETURN
    END IF
    
    ! get 
    IF (PRESENT(config)) THEN
      cfg = config
    ELSE
      cfg = RT_Asm_Cfg()
    END IF
    
    use_ph = g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%desc%mesh%initialized .AND. &
             g_ufc_global%ph_layer%element%is_initialized
    IF (use_ph) THEN
      nElems = g_ufc_global%ph_layer%element%n_elements
      IF (nElems <= 0_i4) nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    ELSE IF (ASSOCIATED(model%mesh)) THEN
      nElems = model%mesh%nElems
    ELSE
      nElems = 0_i4
    END IF

    ! Phase6 §3.2: tripartite dispatch table hook (COLD, before element loop).
    trip_key%elem_stem_id = 1_i4
    trip_key%section_rule_id = 1_i4
    trip_key%material_leaf_id = 1_i4
    trip_lin = RT_Asm_Tripartite_LinearIndex(trip_key, 1_i4, 1_i4)
    trip_dispatch = trip_lin
    IF (trip_dispatch < 1_i4) trip_dispatch = 1_i4
    
    ! I-03: SparsityPattern reuse path (skip Triplet->CSR when topology unchanged)
    IF (cfg%reuse_sparsity .AND. K%init .AND. ALLOCATED(K%values) .AND. &
        K%nRows == nDOF .AND. K%nCols == nDOF .AND. use_ph .AND. nElems > 0_i4) THEN
      K%values(:) = 0.0_wp

      !$OMP PARALLEL DO DEFAULT(NONE) &
      !$OMP   SHARED(nElems, nDOF, dofMap, K, g_ufc_global) &
      !$OMP   PRIVATE(iElem, arg_conn, mesh_st, npe, spatial_dim, n_dof, &
      !$OMP           elem_typ_reg, ep_reg_ke, ke_arg, Ke, elem_dofs, &
      !$OMP           iDOF, jDOF) &
      !$OMP   SCHEDULE(DYNAMIC, 64)
      DO iElem = 1, nElems
        CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
        npe = arg_conn%npe
        spatial_dim = 3_i4
        IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_ndim_cache) .AND. &
            iElem <= SIZE(g_ufc_global%ph_layer%element%elem_ndim_cache)) THEN
          spatial_dim = g_ufc_global%ph_layer%element%elem_ndim_cache(iElem)
          IF (spatial_dim < 2_i4) spatial_dim = 3_i4
        END IF
        n_dof = npe * spatial_dim
        elem_typ_reg = 0_i4
        NULLIFY(ep_reg_ke)
        IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
            iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) THEN
          elem_typ_reg = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
          ep_reg_ke => PH_Elem_Reg_Get(elem_typ_reg)
          IF (ASSOCIATED(ep_reg_ke) .AND. ep_reg_ke%pop%n_dof > 0_i4) n_dof = ep_reg_ke%pop%n_dof
        END IF
        IF (n_dof < 1_i4 .OR. n_dof > RT_ASM_MAX_ELEM_DOF) CYCLE
        ALLOCATE(elem_dofs(n_dof), Ke(n_dof, n_dof))
        elem_dofs = 0_i4
        DO jDOF = 1, n_dof
          elem_dofs(jDOF) = RT_Asm_Solv_LocalJToEqId(dofMap, arg_conn%connect, npe, elem_typ_reg, n_dof, jDOF)
        END DO
        ke_arg%elem_idx = iElem
        ke_arg%l3_elem_idx = iElem
        ke_arg%mat_pt_idx = RT_Asm_Brg_ElemMatPtIdx(iElem)
        ke_arg%nDof = n_dof
        IF (ASSOCIATED(ke_arg%evo%Ke)) DEALLOCATE(ke_arg%evo%Ke)
        ALLOCATE(ke_arg%evo%Ke(n_dof, n_dof))
        CALL RT_Asm_Solv_KeArg_AttachMatProps(ke_arg)
        CALL init_error_status(ke_arg%status)
        CALL g_ufc_global%ph_layer%element%Compute_Ke(ke_arg)
        CALL RT_Asm_Solv_KeArg_ClearMatProps(ke_arg)
        IF (ke_arg%status%status_code /= IF_STATUS_OK) THEN
          DEALLOCATE(elem_dofs, Ke)
          CYCLE
        END IF
        Ke(1:n_dof, 1:n_dof) = ke_arg%evo%Ke(1:n_dof, 1:n_dof)
        ! Scatter Ke to CSR values with ATOMIC protection
        CALL RT_Asm_ScatterKe_CSR_Atomic(K, Ke, elem_dofs, n_dof)
        DEALLOCATE(elem_dofs, Ke)
      END DO
      !$OMP END PARALLEL DO

      status%status_code = IF_STATUS_OK
      WRITE(status%message, '(A,I0,A,I0,A)') &
        'Stiffness matrix assembled (reuse+OMP): ', nDOF, ' DOFs, ', K%nnz, ' non-zeros'
      RETURN
    END IF
    
    ! Step 2: initTriplet (full build path)
    estNnz = MAX(1_i4, nElems * 80_i4)
    CALL RT_Triplet_Init(K_triplets, estNnz)
    
    ! Step 3-4:  element 
    ! IMPORTANT: Set ElemFlags for NLGEOM/TL/UL mode from step configuration
    ! This enables geometric nonlinearity  in element calculations
    
    ! L4 path: PH_Element_Compute_Ke per element; scatter Ke to triplets
    DO iElem = 1, nElems
      IF (use_ph) THEN
        CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
        npe = arg_conn%npe
        ! [HOT-003] spatial_dim from elem_ndim_cache (Populate), zero L3 access
        spatial_dim = 3_i4
        IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_ndim_cache) .AND. &
            iElem <= SIZE(g_ufc_global%ph_layer%element%elem_ndim_cache)) THEN
          spatial_dim = g_ufc_global%ph_layer%element%elem_ndim_cache(iElem)
          IF (spatial_dim < 2_i4) spatial_dim = 3_i4
        END IF
        n_dof = npe * spatial_dim
        elem_typ_reg = 0_i4
        NULLIFY(ep_reg_ke)
        IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
            iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) THEN
          elem_typ_reg = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
          ep_reg_ke => PH_Elem_Reg_Get(elem_typ_reg)
          IF (ASSOCIATED(ep_reg_ke) .AND. ep_reg_ke%pop%n_dof > 0_i4) n_dof = ep_reg_ke%pop%n_dof
        END IF
        IF (n_dof < 1_i4 .OR. n_dof > RT_ASM_MAX_ELEM_DOF) CYCLE
        ALLOCATE(elem_dofs(n_dof), Ke(n_dof, n_dof))
        elem_dofs = 0_i4
        DO jDOF = 1, n_dof
          elem_dofs(jDOF) = RT_Asm_Solv_LocalJToEqId(dofMap, arg_conn%connect, npe, elem_typ_reg, n_dof, jDOF)
        END DO
        ke_arg%elem_idx = iElem
        ke_arg%l3_elem_idx = iElem
        ke_arg%mat_pt_idx = RT_Asm_Brg_ElemMatPtIdx(iElem)
        ke_arg%nDof = n_dof
        IF (ASSOCIATED(ke_arg%evo%Ke)) DEALLOCATE(ke_arg%evo%Ke)
        ALLOCATE(ke_arg%evo%Ke(n_dof, n_dof))
        CALL RT_Asm_Solv_KeArg_AttachMatProps(ke_arg)
        CALL init_error_status(ke_arg%status)
        CALL g_ufc_global%ph_layer%element%Compute_Ke(ke_arg)
        CALL RT_Asm_Solv_KeArg_ClearMatProps(ke_arg)
        IF (ke_arg%status%status_code /= IF_STATUS_OK) THEN
          DEALLOCATE(elem_dofs, Ke)
          CYCLE
        END IF
        Ke(1:n_dof, 1:n_dof) = ke_arg%evo%Ke(1:n_dof, 1:n_dof)
        DO iDOF = 1, n_dof
          DO jDOF = 1, n_dof
            IF (elem_dofs(iDOF) > 0_i4 .AND. elem_dofs(jDOF) > 0_i4 .AND. &
                ABS(Ke(iDOF, jDOF)) > 1.0e-15_wp) &
              CALL RT_Triplet_Add(K_triplets, elem_dofs(iDOF), elem_dofs(jDOF), Ke(iDOF, jDOF))
          END DO
        END DO
        DEALLOCATE(elem_dofs, Ke)
      END IF
    END DO
    
    ! Step 5:  Triplet CSR 
    CALL RT_CSR_FromTriplet(K_triplets, nDOF, nDOF, K)
    
    ! Step 6: checkmatrix 
    IF (K%nnz <= 0_i4) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'RT_Asm_GlobalStiffness: Empty stiffness matrix'
    ELSE
      status%status_code = IF_STATUS_OK
      WRITE(status%message, '(A,I0,A,I0)') &
        'Stiffness matrix assembled: ', nDOF, ' DOFs, ', K%nnz, ' non-zeros'
    END IF
    
    ! Step 7: cleanup
    CALL RT_Triplet_Free(K_triplets)
    
  END SUBROUTINE RT_Asm_GlobalStiffness

  !-----------------------------------------------------------------------------
  ! RT_Asm_GlobalStiffness_Idx: Phase 3 index-based overload (step_idx, arg, status)
  ! Target: resolve model/step/state/dofMap from g_ufc_global%rt_layer when bridge ready.
  ! Current: stub returns IF_STATUS_INVALID; use pointer-based RT_Asm_GlobalStiffness.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_GlobalStiffness_Idx(step_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: step_idx
    TYPE(RT_Asm_GlobalStiffness_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    arg%status = status
    IF (step_idx < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_GlobalStiffness_Idx: step_idx must be >= 1'
      RETURN
    END IF
    ! Stub: index-based bridge from md_layer to UF_Model not yet implemented.
    ! Callers should use RT_Asm_GlobalStiffness(model, step, state, dofMap, K, config, status).
    status%status_code = IF_STATUS_INVALID
    status%message = 'RT_Asm_GlobalStiffness_Idx: use pointer-based RT_Asm_GlobalStiffness; _Idx bridge pending'
  END SUBROUTINE RT_Asm_GlobalStiffness_Idx

  !-----------------------------------------------------------------------------
  ! RT_Asm_ComputeResidual_Idx: Phase 3 index-based overload (step_idx, arg, status)
  ! Target: resolve from rt_layer; hot path zero L3.
  ! Current: stub; use pointer-based RT_Asm_ComputeResidual.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_ComputeResidual_Idx(step_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: step_idx
    TYPE(RT_Asm_ComputeResidual_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    arg%status = status
    IF (step_idx < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_ComputeResidual_Idx: step_idx must be >= 1'
      RETURN
    END IF
    status%status_code = IF_STATUS_INVALID
    status%message = 'RT_Asm_ComputeResidual_Idx: use pointer-based RT_Asm_ComputeResidual; _Idx bridge pending'
  END SUBROUTINE RT_Asm_ComputeResidual_Idx

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleK_M_ForModal: Assemble K and M for modal extraction
  ! P0: When g_ufc_global ready, assembles via RT_Asm_GlobalStiffness + RT_Asm_CSRMass_FromModel
  !     Otherwise returns placeholder (diag K, diag M)
  ! Phase 3: Optional Kg_dense for PROC_BUCKLE: geometric stiffness K_σ.
  !  When present and step%procedure==PROC_BUCKLE: Kg = -0.01*K (placeholder until
  !  L4_PH prestress assembly); real K_σ = �?G^T·σ₀·G dV from base state later.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleK_M_ForModal(model, step, K_dense, M_dense, nDOF, status, Kg_dense)
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    REAL(wp), INTENT(OUT), ALLOCATABLE :: K_dense(:,:), M_dense(:,:)
    INTEGER(i4), INTENT(OUT) :: nDOF
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), INTENT(OUT), ALLOCATABLE, OPTIONAL :: Kg_dense(:,:)

    TYPE(RT_Sol_DofMap) :: dofMap
    TYPE(RT_CSRMatrix) :: K_csr, M_csr
    TYPE(StepStateData) :: state
    INTEGER(i4) :: i, p, p_start, p_end, col
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(status)
    nDOF = 0_i4

    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%desc%mesh%initialized) THEN
      CALL RT_Asm_DofMap_Build(model, dofMap)
      IF (dofMap%nTotalEq <= 0_i4) GOTO 100
      ! nNodes/nElems from L4 cache when available (HOT-003)
      nDOF = dofMap%nTotalEq
      K_csr%init = .FALSE.
      M_csr%init = .FALSE.
      CALL RT_Asm_GlobalStiffness(model, step, state, dofMap, K_csr, RT_Asm_Cfg(), st)
      IF (st%status_code /= IF_STATUS_OK) GOTO 100
      CALL RT_Asm_CSRMass_FromModel(model, nDOF, MASS_TYPE_CONSIST, M_csr, st)
      IF (st%status_code /= IF_STATUS_OK) GOTO 100

      ALLOCATE(K_dense(nDOF, nDOF), M_dense(nDOF, nDOF))
      K_dense = 0.0_wp
      M_dense = 0.0_wp
      IF (ALLOCATED(K_csr%rowPtr) .AND. ALLOCATED(K_csr%colInd) .AND. ALLOCATED(K_csr%values)) THEN
        DO i = 1, nDOF
          p_start = K_csr%rowPtr(i)
          p_end = K_csr%rowPtr(i + 1) - 1
          DO p = p_start, p_end
            col = K_csr%colInd(p)
            IF (col >= 1_i4 .AND. col <= nDOF) K_dense(i, col) = K_dense(i, col) + K_csr%values(p)
          END DO
        END DO
      END IF
      IF (ALLOCATED(M_csr%rowPtr) .AND. ALLOCATED(M_csr%colInd) .AND. ALLOCATED(M_csr%values)) THEN
        DO i = 1, nDOF
          p_start = M_csr%rowPtr(i)
          p_end = M_csr%rowPtr(i + 1) - 1
          DO p = p_start, p_end
            col = M_csr%colInd(p)
            IF (col >= 1_i4 .AND. col <= nDOF) M_dense(i, col) = M_dense(i, col) + M_csr%values(p)
          END DO
        END DO
      END IF
      ! Phase 3: Kg_dense for PROC_BUCKLE (K_σ geometric stiffness)
      IF (PRESENT(Kg_dense) .AND. step%procedure == PROC_BUCKLE) THEN
        IF (ALLOCATED(Kg_dense)) DEALLOCATE(Kg_dense)
        ALLOCATE(Kg_dense(nDOF, nDOF))
        Kg_dense = -0.01_wp * K_dense
      END IF
      IF (ALLOCATED(K_csr%values)) DEALLOCATE(K_csr%values)
      IF (ALLOCATED(K_csr%colInd)) DEALLOCATE(K_csr%colInd)
      IF (ALLOCATED(K_csr%rowPtr)) DEALLOCATE(K_csr%rowPtr)
      IF (ALLOCATED(M_csr%values)) DEALLOCATE(M_csr%values)
      IF (ALLOCATED(M_csr%colInd)) DEALLOCATE(M_csr%colInd)
      IF (ALLOCATED(M_csr%rowPtr)) DEALLOCATE(M_csr%rowPtr)
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

100 CONTINUE
    ! Placeholder when context not ready
    nDOF = 100_i4
    ALLOCATE(K_dense(nDOF, nDOF), M_dense(nDOF, nDOF))
    K_dense = 0.0_wp
    M_dense = 0.0_wp
    DO i = 1, nDOF
      K_dense(i, i) = 1.0e6_wp
      M_dense(i, i) = 1.0_wp
    END DO
    IF (PRESENT(Kg_dense) .AND. step%procedure == PROC_BUCKLE) THEN
      IF (ALLOCATED(Kg_dense)) DEALLOCATE(Kg_dense)
      ALLOCATE(Kg_dense(nDOF, nDOF))
      Kg_dense = -0.01_wp * K_dense
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleK_M_ForModal

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleHeatMatrices: Assemble K_cond, C_cap, Q_total for heat transfer
  !   Thermal DOF: 1 per node (nDOF = nNodes). Multi-element: C3D4, C3D8, C3D10.
  !   K_cond = integral B^T*k*B dV, C_cap = integral rho*cp*N^T*N dV
  !   Phase 3: k_thermal, rho_cp from material slot (props(1)=k, props(2)=rho_cp)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleHeatMatrices(model, K_cond, C_cap, Q_total, nDOF, status)
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(OUT), ALLOCATABLE :: K_cond(:,:), C_cap(:,:), Q_total(:)
    INTEGER(i4), INTENT(OUT) :: nDOF
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNodes, nElems, iElem, ip, i, j, mat_pt_idx, n_ip, elem_type
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetElemSection_Arg) :: arg_sect_elem
    TYPE(MD_Sect_Get_Arg) :: arg_sect
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    REAL(wp) :: coords(3, 27), N(27), dNdx(3, 27), detJ, weight
    REAL(wp) :: K_e(27, 27), C_e(27, 27), K_e_ip(27, 27), C_e_ip(27, 27)
    INTEGER(i4) :: npe, node_ids(27), eq_ids(27)
    REAL(wp) :: k_thermal, rho_cp, section_area
    TYPE(ErrorStatusType) :: mesh_st
    LOGICAL :: use_cache

    CALL init_error_status(status)
    nDOF = 0_i4

    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%mesh%initialized) GOTO 100

    IF (g_ufc_global%ph_layer%element%is_initialized .AND. g_ufc_global%ph_layer%element%n_elements > 0_i4) THEN
      nNodes = g_ufc_global%ph_layer%element%pop%n_nodes
      nElems = g_ufc_global%ph_layer%element%n_elements
    ELSE
      nNodes = INT(g_ufc_global%md_layer%desc%mesh%desc%nNodes, i4)
      nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    END IF
    IF (nNodes <= 0_i4) GOTO 100

    use_cache = g_ufc_global%ph_layer%element%coords_cached .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_npe_cache)

    nDOF = nNodes
    ALLOCATE(K_cond(nDOF, nDOF), C_cap(nDOF, nDOF), Q_total(nDOF))
    K_cond = 0.0_wp
    C_cap = 0.0_wp
    Q_total = 0.0_wp

    k_thermal = 1.0_wp
    rho_cp = 1.0e6_wp

    DO iElem = 1, nElems
      CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
      IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
      npe = arg_conn%npe
      IF (npe < 1_i4 .OR. npe > 27_i4) CYCLE

      elem_type = 0_i4
      IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) &
        elem_type = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
      IF (ALLOCATED(g_ufc_global%md_layer%desc%mesh%raw_data%element_types) .AND. elem_type == 0_i4 .AND. &
          iElem <= SIZE(g_ufc_global%md_layer%desc%mesh%raw_data%element_types)) &
        elem_type = g_ufc_global%md_layer%desc%mesh%raw_data%element_types(iElem)

      n_ip = RT_Asm_ShapeScalarField_GetNumGauss(elem_type, npe)
      IF (n_ip <= 0_i4) CYCLE

      node_ids(1:27) = 0_i4
      node_ids(1:npe) = INT(arg_conn%connect(1:npe), i4)

      coords = 0.0_wp
      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 3)) THEN
        coords(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2))) = &
          g_ufc_global%ph_layer%element%elem_coords_cache(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2)), iElem)
      ELSE
        DO i = 1, npe
          CALL MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, mesh_st)
          IF (mesh_st%status_code == IF_STATUS_OK .AND. ALLOCATED(arg_coords%coords)) &
            coords(1:MIN(3, SIZE(arg_coords%coords)), i) = arg_coords%coords(1:MIN(3, SIZE(arg_coords%coords)))
        END DO
      END IF

      IF (use_cache .AND. ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_to_mat_map)) THEN
        mat_pt_idx = g_ufc_global%ph_layer%element%elem_to_mat_map(iElem)
        IF (mat_pt_idx >= 1_i4 .AND. mat_pt_idx <= g_ufc_global%ph_layer%material%pool_count) THEN
          IF (ALLOCATED(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) .AND. &
              SIZE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) >= 2_i4) THEN
            k_thermal = g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(1)
            rho_cp = g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(2)
            IF (k_thermal < 1.0e-6_wp .OR. k_thermal > 1.0e4_wp .OR. rho_cp < 1.0e2_wp .OR. rho_cp > 1.0e8_wp) THEN
              k_thermal = 1.0_wp
              rho_cp = 1.0e6_wp
            END IF
          END IF
        END IF
      END IF

      eq_ids(1:27) = 0_i4
      eq_ids(1:npe) = node_ids(1:npe)
      DO i = 1, npe
        IF (eq_ids(i) < 1_i4 .OR. eq_ids(i) > nDOF) eq_ids(i) = 0_i4
      END DO

      ! 1D (T3D2/B31): get section area for heat conduction K = k*A/L
      section_area = 1.0_wp
      IF (elem_type == ELEM_T3D2 .OR. elem_type == ELEM_B31) THEN
        arg_sect_elem%section_idx = 0_i4
        CALL MD_Mesh_GetElemSection_Idx(iElem, arg_sect_elem, mesh_st)
        IF (mesh_st%status_code == IF_STATUS_OK .AND. arg_sect_elem%section_idx > 0_i4) THEN
          CALL MD_Section_GetSection_Idx(g_ufc_global%md_layer%desc%section, arg_sect_elem%section_idx, &
               arg_sect, mesh_st)
          IF (mesh_st%status_code == IF_STATUS_OK .AND. arg_sect%desc%area > 1.0e-12_wp) &
            section_area = arg_sect%desc%area
        END IF
      END IF

      K_e(1:npe, 1:npe) = 0.0_wp
      C_e(1:npe, 1:npe) = 0.0_wp
      DO ip = 1, n_ip
        CALL PH_ShapeScalarField_Eval(elem_type, coords, npe, ip, N, dNdx, detJ, weight, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. ABS(detJ) <= 1.0e-12_wp) CYCLE
        IF (elem_type == ELEM_T3D2 .OR. elem_type == ELEM_B31) weight = weight * section_area
        CALL PH_Elem_HeatTransfer_Kcond(dNdx, k_thermal, detJ, weight, npe, K_e_ip(1:npe,1:npe), mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK) CYCLE
        K_e(1:npe, 1:npe) = K_e(1:npe, 1:npe) + K_e_ip(1:npe, 1:npe)
        CALL PH_Elem_HeatTransfer_Ccap(N, rho_cp, detJ, weight, npe, C_e_ip(1:npe,1:npe), .FALSE., mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK) CYCLE
        C_e(1:npe, 1:npe) = C_e(1:npe, 1:npe) + C_e_ip(1:npe, 1:npe)
      END DO

      DO i = 1, npe
        DO j = 1, npe
          IF (eq_ids(i) > 0_i4 .AND. eq_ids(j) > 0_i4 .AND. ABS(K_e(i,j)) > 1.0e-15_wp) &
            K_cond(eq_ids(i), eq_ids(j)) = K_cond(eq_ids(i), eq_ids(j)) + K_e(i,j)
          IF (eq_ids(i) > 0_i4 .AND. eq_ids(j) > 0_i4 .AND. ABS(C_e(i,j)) > 1.0e-15_wp) &
            C_cap(eq_ids(i), eq_ids(j)) = C_cap(eq_ids(i), eq_ids(j)) + C_e(i,j)
        END DO
      END DO
    END DO

    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,I0,A)') 'Heat matrices assembled: ', nDOF, ' DOFs'
    RETURN

100 CONTINUE
    nDOF = 100_i4
    ALLOCATE(K_cond(nDOF, nDOF), C_cap(nDOF, nDOF), Q_total(nDOF))
    K_cond = 0.0_wp
    C_cap = 0.0_wp
    Q_total = 0.0_wp
    DO i = 1, nDOF
      K_cond(i, i) = 1.0_wp
      C_cap(i, i) = 1.0_wp
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleHeatMatrices

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleThermalForce: F_th = �?B^T·D·α·ΔT·m dV
  !   Isotropic: ε_th = α·(T-T_ref)·[1,1,1,0,0,0]^T, σ_th = D·ε_th
  !   C3D8 only; E/nu/alpha placeholder (E=2e11, nu=0.3, alpha=1.2e-5)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleThermalForce(model, T, dofMap, F_th, status, T_ref, alpha)
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(IN) :: T(:)
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    REAL(wp), INTENT(INOUT) :: F_th(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), INTENT(IN), OPTIONAL :: T_ref
    REAL(wp), INTENT(IN), OPTIONAL :: alpha

    INTEGER(i4) :: nNodes, nElems, iElem, ip, i, j, npe, mat_pt_idx
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    TYPE(PH_Elem_C3D8_JacB_In) :: in_jacb
    TYPE(PH_Elem_C3D8_JacB_Out) :: out_jacb
    REAL(wp) :: coords(3, 8), xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: N(8), B(6, 24), detJ
    REAL(wp) :: T_ref_val, alpha_val, dT_ip
    REAL(wp) :: E_mod, nu_poi, lam, mu, sigma_th(6)
    REAL(wp) :: F_e(24)
    INTEGER(i4) :: node_ids(8), elem_dofs(24), jDOF, iNode, iDOF
    TYPE(ErrorStatusType) :: mesh_st
    LOGICAL :: use_cache

    CALL init_error_status(status)
    T_ref_val = 293.15_wp
    IF (PRESENT(T_ref)) T_ref_val = T_ref
    alpha_val = 1.2e-5_wp
    IF (PRESENT(alpha)) alpha_val = alpha

    E_mod = 2.0e11_wp
    nu_poi = 0.3_wp
    use_cache = g_ufc_global%ph_layer%element%coords_cached .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map)
    sigma_th(4:6) = 0.0_wp

    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%mesh%initialized) RETURN
    IF (SIZE(F_th) < dofMap%nTotalEq) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_AssembleThermalForce: F_th size < nTotalEq'
      RETURN
    END IF

    ! [HOT-003] nNodes/nElems from L4 cache when available
    IF (g_ufc_global%ph_layer%element%is_initialized .AND. g_ufc_global%ph_layer%element%n_elements > 0_i4) THEN
      nNodes = g_ufc_global%ph_layer%element%pop%n_nodes
      nElems = g_ufc_global%ph_layer%element%n_elements
    ELSE
      nNodes = INT(g_ufc_global%md_layer%desc%mesh%desc%nNodes, i4)
      nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    END IF
    IF (SIZE(T) < nNodes .OR. nElems <= 0_i4) RETURN

    F_th = 0.0_wp
    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)

    DO iElem = 1, nElems
      CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
      IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
      npe = arg_conn%npe
      IF (npe /= 8_i4) CYCLE

      node_ids(1:8) = INT(arg_conn%connect(1:8), i4)
      coords = 0.0_wp
      DO i = 1, 8
        CALL MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, mesh_st)
        IF (mesh_st%status_code == IF_STATUS_OK .AND. ALLOCATED(arg_coords%coords)) THEN
          coords(1:MIN(3, SIZE(arg_coords%coords)), i) = arg_coords%coords(1:MIN(3, SIZE(arg_coords%coords)))
        END IF
      END DO

      elem_dofs = 0_i4
      DO iNode = 1, 8
        DO iDOF = 1, 3
          jDOF = (iNode - 1) * 3 + iDOF
          elem_dofs(jDOF) = RT_Asm_DofMap_GetEqId(dofMap, node_ids(iNode), iDOF)
        END DO
      END DO

      ! Phase 3: E, nu, alpha from material slot when available (props(1)=E, props(2)=nu, props(3)=alpha)
      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_to_mat_map)) THEN
        mat_pt_idx = g_ufc_global%ph_layer%element%elem_to_mat_map(iElem)
        IF (mat_pt_idx >= 1_i4 .AND. mat_pt_idx <= g_ufc_global%ph_layer%material%pool_count) THEN
          IF (ALLOCATED(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props)) THEN
            IF (SIZE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) >= 2_i4) THEN
              E_mod = g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(1)
              nu_poi = g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(2)
              IF (E_mod < 1.0e6_wp .OR. E_mod > 1.0e12_wp .OR. nu_poi < 0.0_wp .OR. nu_poi >= 0.5_wp) THEN
                E_mod = 2.0e11_wp
                nu_poi = 0.3_wp
              END IF
            END IF
            IF (.NOT. PRESENT(alpha) .AND. SIZE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) >= 3_i4) THEN
              alpha_val = g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(3)
              IF (alpha_val < 1.0e-8_wp .OR. alpha_val > 1.0e-2_wp) alpha_val = 1.2e-5_wp
            END IF
          END IF
        END IF
      END IF
      lam = E_mod * nu_poi / ((1.0_wp + nu_poi) * (1.0_wp - 2.0_wp * nu_poi))
      mu = E_mod / (2.0_wp * (1.0_wp + nu_poi))

      F_e = 0.0_wp
      DO ip = 1, 8
        in_jacb%coords = coords
        in_jacb%xi = xi(ip)
        in_jacb%eta = eta(ip)
        in_jacb%zeta = zeta(ip)
        CALL PH_Elem_C3D8_JacB(in_jacb, out_jacb)
        IF (out_jacb%status%status_code /= IF_STATUS_OK .OR. ABS(out_jacb%detJ) <= 1.0e-12_wp) CYCLE
        N = out_jacb%N
        B = out_jacb%B
        detJ = out_jacb%detJ
        dT_ip = 0.0_wp
        DO i = 1, 8
          IF (node_ids(i) >= 1_i4 .AND. node_ids(i) <= nNodes) &
            dT_ip = dT_ip + N(i) * (T(node_ids(i)) - T_ref_val)
        END DO
        sigma_th(1:3) = alpha_val * dT_ip * (lam + 2.0_wp * mu)
        DO j = 1, 24
          F_e(j) = F_e(j) + (B(1,j)*sigma_th(1) + B(2,j)*sigma_th(2) + B(3,j)*sigma_th(3) + &
                   B(4,j)*sigma_th(4) + B(5,j)*sigma_th(5) + B(6,j)*sigma_th(6)) * detJ * weights(ip)
        END DO
      END DO

      DO j = 1, 24
        IF (elem_dofs(j) > 0_i4 .AND. elem_dofs(j) <= SIZE(F_th)) &
          F_th(elem_dofs(j)) = F_th(elem_dofs(j)) + F_e(j)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleThermalForce

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleElectricMatrices: K_elec = �?(dN/dx)^T·σ_e·(dN/dx) dV
  !   Electric DOF: 1 per node (nDOF = nNodes). Multi-element via RT_AsmShapeScalarField.
  !   Reuses PH_Elem_HeatTransfer_Kcond with k=sigma_e.
  !   sigma_e from material slot (props(1)); Q_elec from j_body when present.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleElectricMatrices(model, K_elec, Q_elec, nDOF, status, j_body)
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(OUT), ALLOCATABLE :: K_elec(:,:), Q_elec(:)
    INTEGER(i4), INTENT(OUT) :: nDOF
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), INTENT(IN), OPTIONAL :: j_body

    INTEGER(i4) :: nNodes, nElems, iElem, ip, i, j, mat_pt_idx, n_ip, elem_type
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    REAL(wp) :: coords(3, 27), N(27), dNdx(3, 27), detJ, weight
    REAL(wp) :: K_e(27, 27), K_e_ip(27, 27), Q_e(27)
    INTEGER(i4) :: npe, node_ids(27), eq_ids(27)
    REAL(wp) :: sigma_e, j_val
    TYPE(ErrorStatusType) :: mesh_st
    LOGICAL :: use_cache, assemble_Q

    CALL init_error_status(status)
    nDOF = 0_i4
    j_val = 0.0_wp
    IF (PRESENT(j_body)) j_val = j_body
    assemble_Q = (ABS(j_val) > 1.0e-20_wp)

    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%mesh%initialized) GOTO 100

    IF (g_ufc_global%ph_layer%element%is_initialized .AND. g_ufc_global%ph_layer%element%n_elements > 0_i4) THEN
      nNodes = g_ufc_global%ph_layer%element%pop%n_nodes
      nElems = g_ufc_global%ph_layer%element%n_elements
    ELSE
      nNodes = INT(g_ufc_global%md_layer%desc%mesh%desc%nNodes, i4)
      nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    END IF
    IF (nNodes <= 0_i4) GOTO 100

    nDOF = nNodes
    ALLOCATE(K_elec(nDOF, nDOF), Q_elec(nDOF))
    K_elec = 0.0_wp
    Q_elec = 0.0_wp

    sigma_e = 1.0e6_wp
    use_cache = g_ufc_global%ph_layer%element%coords_cached .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map)

    DO iElem = 1, nElems
      CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
      IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
      npe = arg_conn%npe
      IF (npe < 1_i4 .OR. npe > 27_i4) CYCLE

      elem_type = 0_i4
      IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) &
        elem_type = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
      IF (ALLOCATED(g_ufc_global%md_layer%desc%mesh%raw_data%element_types) .AND. elem_type == 0_i4 .AND. &
          iElem <= SIZE(g_ufc_global%md_layer%desc%mesh%raw_data%element_types)) &
        elem_type = g_ufc_global%md_layer%desc%mesh%raw_data%element_types(iElem)

      n_ip = RT_Asm_ShapeScalarField_GetNumGauss(elem_type, npe)
      IF (n_ip <= 0_i4) CYCLE

      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_to_mat_map)) THEN
        mat_pt_idx = g_ufc_global%ph_layer%element%elem_to_mat_map(iElem)
        IF (mat_pt_idx >= 1_i4 .AND. mat_pt_idx <= g_ufc_global%ph_layer%material%pool_count) THEN
          IF (ALLOCATED(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) .AND. &
              SIZE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) >= 1_i4) THEN
            sigma_e = g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(1)
            IF (sigma_e < 1.0e-6_wp .OR. sigma_e > 1.0e8_wp) sigma_e = 1.0e6_wp
          END IF
        END IF
      END IF

      node_ids(1:27) = 0_i4
      node_ids(1:npe) = INT(arg_conn%connect(1:npe), i4)

      coords = 0.0_wp
      IF (use_cache .AND. ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 3)) THEN
        coords(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2))) = &
          g_ufc_global%ph_layer%element%elem_coords_cache(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2)), iElem)
      ELSE
        DO i = 1, npe
          CALL MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, mesh_st)
          IF (mesh_st%status_code == IF_STATUS_OK .AND. ALLOCATED(arg_coords%coords)) &
            coords(1:MIN(3, SIZE(arg_coords%coords)), i) = arg_coords%coords(1:MIN(3, SIZE(arg_coords%coords)))
        END DO
      END IF

      eq_ids(1:27) = node_ids(1:27)
      DO i = 1, npe
        IF (eq_ids(i) < 1_i4 .OR. eq_ids(i) > nDOF) eq_ids(i) = 0_i4
      END DO

      K_e(1:npe, 1:npe) = 0.0_wp
      Q_e(1:npe) = 0.0_wp
      DO ip = 1, n_ip
        CALL PH_ShapeScalarField_Eval(elem_type, coords, npe, ip, N, dNdx, detJ, weight, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. ABS(detJ) <= 1.0e-12_wp) CYCLE
        CALL PH_Elem_HeatTransfer_Kcond(dNdx, sigma_e, detJ, weight, npe, K_e_ip(1:npe,1:npe), mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK) CYCLE
        K_e(1:npe, 1:npe) = K_e(1:npe, 1:npe) + K_e_ip(1:npe, 1:npe)
        IF (assemble_Q) THEN
          DO i = 1, npe
            Q_e(i) = Q_e(i) + N(i) * j_val * detJ * weight
          END DO
        END IF
      END DO

      DO i = 1, npe
        DO j = 1, npe
          IF (eq_ids(i) > 0_i4 .AND. eq_ids(j) > 0_i4 .AND. ABS(K_e(i,j)) > 1.0e-15_wp) &
            K_elec(eq_ids(i), eq_ids(j)) = K_elec(eq_ids(i), eq_ids(j)) + K_e(i,j)
        END DO
        IF (assemble_Q .AND. eq_ids(i) > 0_i4 .AND. eq_ids(i) <= nDOF) &
          Q_elec(eq_ids(i)) = Q_elec(eq_ids(i)) + Q_e(i)
      END DO
    END DO

    status%status_code = IF_STATUS_OK
    RETURN

100 CONTINUE
    nDOF = 100_i4
    ALLOCATE(K_elec(nDOF, nDOF), Q_elec(nDOF))
    K_elec = 0.0_wp
    Q_elec = 0.0_wp
    DO i = 1, nDOF
      K_elec(i, i) = 1.0_wp
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleElectricMatrices

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleAcousticMatrices: K_ac = �?(1/ρ)·∇N^T·∇N dV, Q_ac
  !   Acoustic DOF: 1 per node (pressure). Multi-element via RT_AsmShapeScalarField.
  !   rho from material props(1); rho_inv=1/rho.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleAcousticMatrices(model, K_ac, Q_ac, nDOF, status)
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(OUT), ALLOCATABLE :: K_ac(:,:), Q_ac(:)
    INTEGER(i4), INTENT(OUT) :: nDOF
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNodes, nElems, iElem, ip, i, j, mat_pt_idx, n_ip, elem_type
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    REAL(wp) :: coords(3, 27), N(27), dNdx(3, 27), detJ, weight
    REAL(wp) :: K_e(27, 27)
    INTEGER(i4) :: npe, node_ids(27), eq_ids(27)
    REAL(wp) :: rho_inv
    TYPE(ErrorStatusType) :: mesh_st
    LOGICAL :: use_cache

    CALL init_error_status(status)
    nDOF = 0_i4
    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%mesh%initialized) GOTO 100

    IF (g_ufc_global%ph_layer%element%is_initialized .AND. g_ufc_global%ph_layer%element%n_elements > 0_i4) THEN
      nNodes = g_ufc_global%ph_layer%element%pop%n_nodes
      nElems = g_ufc_global%ph_layer%element%n_elements
    ELSE
      nNodes = INT(g_ufc_global%md_layer%desc%mesh%desc%nNodes, i4)
      nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    END IF
    IF (nNodes <= 0_i4) GOTO 100

    nDOF = nNodes
    ALLOCATE(K_ac(nDOF, nDOF), Q_ac(nDOF))
    K_ac = 0.0_wp
    Q_ac = 0.0_wp
    rho_inv = 1.0_wp

    use_cache = g_ufc_global%ph_layer%element%coords_cached .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map)

    DO iElem = 1, nElems
      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_to_mat_map)) THEN
        mat_pt_idx = g_ufc_global%ph_layer%element%elem_to_mat_map(iElem)
        IF (mat_pt_idx >= 1_i4 .AND. mat_pt_idx <= g_ufc_global%ph_layer%material%pool_count) THEN
          IF (ALLOCATED(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) .AND. &
              SIZE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) >= 1_i4) THEN
            rho_inv = 1.0_wp / MAX(1.0e-12_wp, g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(1))
          END IF
        END IF
      END IF

      CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
      IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
      npe = arg_conn%npe
      IF (npe < 1_i4 .OR. npe > 27_i4) CYCLE

      elem_type = 0_i4
      IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) &
        elem_type = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
      IF (ALLOCATED(g_ufc_global%md_layer%desc%mesh%raw_data%element_types) .AND. elem_type == 0_i4 .AND. &
          iElem <= SIZE(g_ufc_global%md_layer%desc%mesh%raw_data%element_types)) &
        elem_type = g_ufc_global%md_layer%desc%mesh%raw_data%element_types(iElem)

      n_ip = RT_Asm_ShapeScalarField_GetNumGauss(elem_type, npe)
      IF (n_ip <= 0_i4) CYCLE

      node_ids(1:27) = 0_i4
      node_ids(1:npe) = INT(arg_conn%connect(1:npe), i4)

      coords = 0.0_wp
      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 3)) THEN
        coords(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2))) = &
          g_ufc_global%ph_layer%element%elem_coords_cache(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2)), iElem)
      ELSE
        DO i = 1, npe
          CALL MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, mesh_st)
          IF (mesh_st%status_code == IF_STATUS_OK .AND. ALLOCATED(arg_coords%coords)) &
            coords(1:MIN(3, SIZE(arg_coords%coords)), i) = arg_coords%coords(1:MIN(3, SIZE(arg_coords%coords)))
        END DO
      END IF

      eq_ids(1:27) = node_ids(1:27)
      DO i = 1, npe
        IF (eq_ids(i) < 1_i4 .OR. eq_ids(i) > nDOF) eq_ids(i) = 0_i4
      END DO

      K_e(1:npe, 1:npe) = 0.0_wp
      DO ip = 1, n_ip
        CALL PH_ShapeScalarField_Eval(elem_type, coords, npe, ip, N, dNdx, detJ, weight, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. ABS(detJ) <= 1.0e-12_wp) CYCLE
        CALL PH_Acoustic_StiffnessContrib(dNdx, rho_inv, detJ, weight, npe, K_e(1:npe,1:npe), mesh_st)
      END DO

      DO i = 1, npe
        DO j = 1, npe
          IF (eq_ids(i) > 0_i4 .AND. eq_ids(j) > 0_i4 .AND. ABS(K_e(i,j)) > 1.0e-15_wp) &
            K_ac(eq_ids(i), eq_ids(j)) = K_ac(eq_ids(i), eq_ids(j)) + K_e(i,j)
        END DO
      END DO
    END DO
    status%status_code = IF_STATUS_OK
    RETURN

100 CONTINUE
    nDOF = 100_i4
    ALLOCATE(K_ac(nDOF, nDOF), Q_ac(nDOF))
    K_ac = 0.0_wp
    Q_ac = 0.0_wp
    DO i = 1, nDOF
      K_ac(i, i) = 1.0_wp
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleAcousticMatrices

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleElectroMagMatrices: K_curl = �?(1/μ)·∇N^T·∇N dV, J_s
  !   Eddy current steady: K_curl·A = J_s. 1 DOF/node. Multi-element via RT_AsmShapeScalarField.
  !   mu from material props(1); mu_inv=1/mu.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleElectroMagMatrices(model, K_curl, J_s, nDOF, status)
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(OUT), ALLOCATABLE :: K_curl(:,:), J_s(:)
    INTEGER(i4), INTENT(OUT) :: nDOF
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNodes, nElems, iElem, ip, i, j, mat_pt_idx, n_ip, elem_type
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    REAL(wp) :: coords(3, 27), N(27), dNdx(3, 27), detJ, weight
    REAL(wp) :: K_e(27, 27)
    INTEGER(i4) :: npe, node_ids(27), eq_ids(27)
    REAL(wp) :: mu_inv
    TYPE(ErrorStatusType) :: mesh_st
    LOGICAL :: use_cache

    CALL init_error_status(status)
    nDOF = 0_i4
    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%mesh%initialized) GOTO 100

    IF (g_ufc_global%ph_layer%element%is_initialized .AND. g_ufc_global%ph_layer%element%n_elements > 0_i4) THEN
      nNodes = g_ufc_global%ph_layer%element%pop%n_nodes
      nElems = g_ufc_global%ph_layer%element%n_elements
    ELSE
      nNodes = INT(g_ufc_global%md_layer%desc%mesh%desc%nNodes, i4)
      nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    END IF
    IF (nNodes <= 0_i4) GOTO 100

    nDOF = nNodes
    ALLOCATE(K_curl(nDOF, nDOF), J_s(nDOF))
    K_curl = 0.0_wp
    J_s = 0.0_wp
    mu_inv = 1.0e6_wp

    use_cache = g_ufc_global%ph_layer%element%coords_cached .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map)

    DO iElem = 1, nElems
      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_to_mat_map)) THEN
        mat_pt_idx = g_ufc_global%ph_layer%element%elem_to_mat_map(iElem)
        IF (mat_pt_idx >= 1_i4 .AND. mat_pt_idx <= g_ufc_global%ph_layer%material%pool_count) THEN
          IF (ALLOCATED(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) .AND. &
              SIZE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) >= 1_i4) THEN
            mu_inv = 1.0_wp / MAX(1.0e-12_wp, g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(1))
          END IF
        END IF
      END IF

      CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
      IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
      npe = arg_conn%npe
      IF (npe < 1_i4 .OR. npe > 27_i4) CYCLE

      elem_type = 0_i4
      IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) &
        elem_type = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
      IF (ALLOCATED(g_ufc_global%md_layer%desc%mesh%raw_data%element_types) .AND. elem_type == 0_i4 .AND. &
          iElem <= SIZE(g_ufc_global%md_layer%desc%mesh%raw_data%element_types)) &
        elem_type = g_ufc_global%md_layer%desc%mesh%raw_data%element_types(iElem)

      n_ip = RT_Asm_ShapeScalarField_GetNumGauss(elem_type, npe)
      IF (n_ip <= 0_i4) CYCLE

      node_ids(1:27) = 0_i4
      node_ids(1:npe) = INT(arg_conn%connect(1:npe), i4)

      coords = 0.0_wp
      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 3)) THEN
        coords(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2))) = &
          g_ufc_global%ph_layer%element%elem_coords_cache(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2)), iElem)
      ELSE
        DO i = 1, npe
          CALL MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, mesh_st)
          IF (mesh_st%status_code == IF_STATUS_OK .AND. ALLOCATED(arg_coords%coords)) &
            coords(1:MIN(3, SIZE(arg_coords%coords)), i) = arg_coords%coords(1:MIN(3, SIZE(arg_coords%coords)))
        END DO
      END IF

      eq_ids(1:27) = node_ids(1:27)
      DO i = 1, npe
        IF (eq_ids(i) < 1_i4 .OR. eq_ids(i) > nDOF) eq_ids(i) = 0_i4
      END DO

      K_e(1:npe, 1:npe) = 0.0_wp
      DO ip = 1, n_ip
        CALL PH_ShapeScalarField_Eval(elem_type, coords, npe, ip, N, dNdx, detJ, weight, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. ABS(detJ) <= 1.0e-12_wp) CYCLE
        CALL PH_ElectroMag_StiffnessContrib(dNdx, mu_inv, detJ, weight, npe, K_e(1:npe,1:npe), mesh_st)
      END DO

      DO i = 1, npe
        DO j = 1, npe
          IF (eq_ids(i) > 0_i4 .AND. eq_ids(j) > 0_i4 .AND. ABS(K_e(i,j)) > 1.0e-15_wp) &
            K_curl(eq_ids(i), eq_ids(j)) = K_curl(eq_ids(i), eq_ids(j)) + K_e(i,j)
        END DO
      END DO
    END DO
    status%status_code = IF_STATUS_OK
    RETURN

100 CONTINUE
    nDOF = 100_i4
    ALLOCATE(K_curl(nDOF, nDOF), J_s(nDOF))
    K_curl = 0.0_wp
    J_s = 0.0_wp
    DO i = 1, nDOF
      K_curl(i, i) = 1.0_wp
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleElectroMagMatrices

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleTransportMatrices: K_trans = K_diff + K_conv, Q
  !   K_diff from heat (D·∇N^T·∇N); K_conv from v·∇u. v=(0,0,0) default.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleTransportMatrices(model, K_trans, Q, nDOF, status, v_transport)
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(OUT), ALLOCATABLE :: K_trans(:,:), Q(:)
    INTEGER(i4), INTENT(OUT) :: nDOF
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), INTENT(IN), OPTIONAL :: v_transport(3)

    REAL(wp), ALLOCATABLE :: K_diff(:,:), C_dummy(:,:)
    REAL(wp) :: v(3)
    INTEGER(i4) :: nNodes, nElems, iElem, ip, i, j, mat_pt_idx, n_ip, elem_type
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    REAL(wp) :: coords(3, 27), N(27), dNdx(3, 27), detJ, weight
    REAL(wp) :: K_conv_e(27, 27)
    INTEGER(i4) :: npe, node_ids(27), eq_ids(27)
    REAL(wp) :: k_diff
    TYPE(ErrorStatusType) :: mesh_st
    LOGICAL :: use_cache, add_conv

    CALL init_error_status(status)
    nDOF = 0_i4
    v = 0.0_wp
    IF (PRESENT(v_transport)) v = v_transport
    add_conv = (ABS(v(1)) + ABS(v(2)) + ABS(v(3)) > 1.0e-20_wp)

    CALL RT_Asm_AssembleHeatMatrices(model, K_trans, C_dummy, Q, nDOF, status)
    IF (status%status_code /= IF_STATUS_OK .OR. .NOT. ALLOCATED(K_trans)) RETURN

    IF (.NOT. add_conv) RETURN

    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%mesh%initialized) RETURN
    IF (g_ufc_global%ph_layer%element%is_initialized .AND. g_ufc_global%ph_layer%element%n_elements > 0_i4) THEN
      nNodes = g_ufc_global%ph_layer%element%pop%n_nodes
      nElems = g_ufc_global%ph_layer%element%n_elements
    ELSE
      nNodes = INT(g_ufc_global%md_layer%desc%mesh%desc%nNodes, i4)
      nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    END IF
    k_diff = 1.0_wp
    use_cache = g_ufc_global%ph_layer%element%coords_cached .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map)

    DO iElem = 1, nElems
      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_to_mat_map)) THEN
        mat_pt_idx = g_ufc_global%ph_layer%element%elem_to_mat_map(iElem)
        IF (mat_pt_idx >= 1_i4 .AND. mat_pt_idx <= g_ufc_global%ph_layer%material%pool_count) THEN
          IF (ALLOCATED(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) .AND. &
              SIZE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) >= 1_i4) THEN
            k_diff = g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(1)
          END IF
        END IF
      END IF

      CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
      IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
      npe = arg_conn%npe
      IF (npe < 1_i4 .OR. npe > 27_i4) CYCLE

      elem_type = 0_i4
      IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) &
        elem_type = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
      IF (ALLOCATED(g_ufc_global%md_layer%desc%mesh%raw_data%element_types) .AND. elem_type == 0_i4 .AND. &
          iElem <= SIZE(g_ufc_global%md_layer%desc%mesh%raw_data%element_types)) &
        elem_type = g_ufc_global%md_layer%desc%mesh%raw_data%element_types(iElem)

      n_ip = RT_Asm_ShapeScalarField_GetNumGauss(elem_type, npe)
      IF (n_ip <= 0_i4) CYCLE

      node_ids(1:27) = 0_i4
      node_ids(1:npe) = INT(arg_conn%connect(1:npe), i4)

      coords = 0.0_wp
      IF (use_cache .AND. ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 3)) THEN
        coords(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2))) = &
          g_ufc_global%ph_layer%element%elem_coords_cache(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2)), iElem)
      ELSE
        DO i = 1, npe
          CALL MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, mesh_st)
          IF (mesh_st%status_code == IF_STATUS_OK .AND. ALLOCATED(arg_coords%coords)) &
            coords(1:MIN(3, SIZE(arg_coords%coords)), i) = arg_coords%coords(1:MIN(3, SIZE(arg_coords%coords)))
        END DO
      END IF

      eq_ids(1:27) = node_ids(1:27)
      DO i = 1, npe
        IF (eq_ids(i) < 1_i4 .OR. eq_ids(i) > nDOF) eq_ids(i) = 0_i4
      END DO

      K_conv_e(1:npe, 1:npe) = 0.0_wp
      DO ip = 1, n_ip
        CALL PH_ShapeScalarField_Eval(elem_type, coords, npe, ip, N, dNdx, detJ, weight, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. ABS(detJ) <= 1.0e-12_wp) CYCLE
        CALL PH_SSTrans_ConvectiveContrib(N, dNdx, v, detJ, weight, npe, K_conv_e(1:npe,1:npe), mesh_st)
      END DO

      DO i = 1, npe
        DO j = 1, npe
          IF (eq_ids(i) > 0_i4 .AND. eq_ids(j) > 0_i4 .AND. ABS(K_conv_e(i,j)) > 1.0e-15_wp) &
            K_trans(eq_ids(i), eq_ids(j)) = K_trans(eq_ids(i), eq_ids(j)) + K_conv_e(i,j)
        END DO
      END DO
    END DO
    IF (ALLOCATED(C_dummy)) DEALLOCATE(C_dummy)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleTransportMatrices

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssemblePiezoCoupling: K_ue = �?B_u^T·d·B_phi dV
  !   Mech DOF: 3/node (dofMap); Elec DOF: 1/node.
  !   Multi-element via RT_AsmShapeMechanicalField (C3D4, C3D6, C3D8, C3D10, C3D15, C3D20).
  !   d_piezo(6,3) from material props or default; B_u from JacB, B_phi = dNdx.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssemblePiezoCoupling(model, n_u, n_phi, K_ue, status)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: n_u, n_phi
    REAL(wp), INTENT(OUT), ALLOCATABLE :: K_ue(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(RT_Sol_DofMap) :: dofMap
    INTEGER(i4) :: nNodes, nElems, iElem, ip, i, j, mat_pt_idx, n_ip, elem_type
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    REAL(wp) :: coords(3, 27), N(27), dNdx(3, 27), B_u(6, 60), d_piezo(6, 3)
    REAL(wp), ALLOCATABLE :: K_ue_e(:,:)
    REAL(wp) :: detJ, weight
    INTEGER(i4) :: npe, node_ids(27), mech_eq(60), elec_eq(27)
    TYPE(ErrorStatusType) :: mesh_st
    LOGICAL :: use_cache

    CALL init_error_status(status)
    IF (n_u <= 0_i4 .OR. n_phi <= 0_i4) RETURN
    ALLOCATE(K_ue(n_u, n_phi))
    K_ue = 0.0_wp

    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%mesh%initialized) RETURN
    CALL RT_Asm_DofMap_Build(model, dofMap)
    IF (dofMap%nTotalEq /= n_u) RETURN

    IF (g_ufc_global%ph_layer%element%is_initialized .AND. g_ufc_global%ph_layer%element%n_elements > 0_i4) THEN
      nNodes = g_ufc_global%ph_layer%element%pop%n_nodes
      nElems = g_ufc_global%ph_layer%element%n_elements
    ELSE
      nNodes = INT(g_ufc_global%md_layer%desc%mesh%desc%nNodes, i4)
      nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    END IF
    IF (nNodes <= 0_i4 .OR. nElems <= 0_i4 .OR. n_phi /= nNodes) RETURN

    d_piezo = 0.0_wp
    d_piezo(1, 1) = 1.0_wp
    d_piezo(2, 2) = 1.0_wp
    d_piezo(3, 3) = 1.0_wp
    use_cache = g_ufc_global%ph_layer%element%coords_cached .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map)

    DO iElem = 1, nElems
      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_to_mat_map)) THEN
        mat_pt_idx = g_ufc_global%ph_layer%element%elem_to_mat_map(iElem)
        IF (mat_pt_idx >= 1_i4 .AND. mat_pt_idx <= g_ufc_global%ph_layer%material%pool_count) THEN
          IF (ALLOCATED(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) .AND. &
              SIZE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props) >= 18_i4) THEN
            d_piezo(1:6, 1:3) = RESHAPE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%desc%props(1:18), [6, 3])
          END IF
        END IF
      END IF

      CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
      IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
      npe = arg_conn%npe
      IF (npe < 4_i4 .OR. npe > 20_i4) CYCLE

      elem_type = 0_i4
      IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) &
        elem_type = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
      IF (ALLOCATED(g_ufc_global%md_layer%desc%mesh%raw_data%element_types) .AND. elem_type == 0_i4 .AND. &
          iElem <= SIZE(g_ufc_global%md_layer%desc%mesh%raw_data%element_types)) &
        elem_type = g_ufc_global%md_layer%desc%mesh%raw_data%element_types(iElem)

      n_ip = RT_Asm_ShapeMechanicalField_GetNumGauss(elem_type, npe)
      IF (n_ip <= 0_i4) CYCLE

      node_ids(1:27) = 0_i4
      node_ids(1:npe) = INT(arg_conn%connect(1:npe), i4)
      DO i = 1, 3 * npe
        mech_eq(i) = RT_Asm_DofMap_GetEqId(dofMap, node_ids((i - 1) / 3 + 1), MOD(i - 1, 3) + 1)
      END DO
      elec_eq(1:npe) = node_ids(1:npe)
      DO i = 1, npe
        IF (elec_eq(i) < 1_i4 .OR. elec_eq(i) > n_phi) elec_eq(i) = 0_i4
      END DO

      coords = 0.0_wp
      IF (use_cache .AND. ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 3)) THEN
        coords(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2))) = &
          g_ufc_global%ph_layer%element%elem_coords_cache(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2)), iElem)
      ELSE
        DO i = 1, npe
          CALL MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, mesh_st)
          IF (mesh_st%status_code == IF_STATUS_OK .AND. ALLOCATED(arg_coords%coords)) &
            coords(1:MIN(3, SIZE(arg_coords%coords)), i) = arg_coords%coords(1:MIN(3, SIZE(arg_coords%coords)))
        END DO
      END IF

      ALLOCATE(K_ue_e(3 * npe, npe))
      K_ue_e = 0.0_wp
      DO ip = 1, n_ip
        CALL PH_ShapeMechanicalField_Eval(elem_type, coords, npe, ip, N, dNdx, B_u, detJ, weight, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. ABS(detJ) <= 1.0e-12_wp) CYCLE
        CALL PH_Piezo_CouplingContrib(B_u(1:6, 1:3*npe), dNdx(1:3, 1:npe), d_piezo, detJ, weight, K_ue_e, mesh_st)
      END DO

      DO i = 1, 3 * npe
        DO j = 1, npe
          IF (mech_eq(i) > 0_i4 .AND. mech_eq(i) <= n_u .AND. elec_eq(j) > 0_i4 .AND. elec_eq(j) <= n_phi .AND. &
              ABS(K_ue_e(i, j)) > 1.0e-15_wp) &
            K_ue(mech_eq(i), elec_eq(j)) = K_ue(mech_eq(i), elec_eq(j)) + K_ue_e(i, j)
        END DO
      END DO
      DEALLOCATE(K_ue_e)
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssemblePiezoCoupling

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleJouleHeat: Joule heat branch (multiphysics TE kernel removed; Q_joule unchanged).
  !   Multi-element via RT_AsmShapeScalarField.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleJouleHeat(model, phi, Q_joule, nDOF, status)
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(IN) :: phi(:)
    REAL(wp), INTENT(INOUT) :: Q_joule(:)
    INTEGER(i4), INTENT(IN) :: nDOF
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nElems, iElem, ip, i, n_ip, elem_type
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    REAL(wp) :: coords(3, 27), N(27), dNdx(3, 27), detJ, weight
    REAL(wp) :: Q_ip(27)
    INTEGER(i4) :: npe, node_ids(27), eq_ids(27)
    TYPE(ErrorStatusType) :: mesh_st
    LOGICAL :: use_cache

    CALL init_error_status(status)
    IF (SIZE(phi) < nDOF .OR. SIZE(Q_joule) < nDOF) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_AssembleJouleHeat: array size mismatch'
      RETURN
    END IF

    Q_joule = 0.0_wp
    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%mesh%initialized) RETURN

    IF (g_ufc_global%ph_layer%element%is_initialized .AND. g_ufc_global%ph_layer%element%n_elements > 0_i4) THEN
      nElems = g_ufc_global%ph_layer%element%n_elements
    ELSE
      nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    END IF
    IF (nElems <= 0_i4) RETURN

    use_cache = g_ufc_global%ph_layer%element%coords_cached .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_coords_cache) .AND. &
         ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map)

    DO iElem = 1, nElems
      CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
      IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
      npe = arg_conn%npe
      IF (npe < 1_i4 .OR. npe > 27_i4) CYCLE

      elem_type = 0_i4
      IF (ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) &
        elem_type = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
      IF (ALLOCATED(g_ufc_global%md_layer%desc%mesh%raw_data%element_types) .AND. elem_type == 0_i4 .AND. &
          iElem <= SIZE(g_ufc_global%md_layer%desc%mesh%raw_data%element_types)) &
        elem_type = g_ufc_global%md_layer%desc%mesh%raw_data%element_types(iElem)

      n_ip = RT_Asm_ShapeScalarField_GetNumGauss(elem_type, npe)
      IF (n_ip <= 0_i4) CYCLE

      node_ids(1:27) = 0_i4
      node_ids(1:npe) = INT(arg_conn%connect(1:npe), i4)

      coords = 0.0_wp
      IF (use_cache .AND. iElem <= SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 3)) THEN
        coords(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2))) = &
          g_ufc_global%ph_layer%element%elem_coords_cache(1:3, 1:MIN(npe, SIZE(g_ufc_global%ph_layer%element%elem_coords_cache, 2)), iElem)
      ELSE
        DO i = 1, npe
          CALL MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, mesh_st)
          IF (mesh_st%status_code == IF_STATUS_OK .AND. ALLOCATED(arg_coords%coords)) &
            coords(1:MIN(3, SIZE(arg_coords%coords)), i) = arg_coords%coords(1:MIN(3, SIZE(arg_coords%coords)))
        END DO
      END IF

      eq_ids(1:27) = node_ids(1:27)
      DO i = 1, npe
        IF (eq_ids(i) < 1_i4 .OR. eq_ids(i) > nDOF) eq_ids(i) = 0_i4
      END DO

      Q_ip(1:n_ip) = 0.0_wp

      DO ip = 1, n_ip
        CALL PH_ShapeScalarField_Eval(elem_type, coords, npe, ip, N, dNdx, detJ, weight, mesh_st)
        IF (mesh_st%status_code /= IF_STATUS_OK .OR. ABS(detJ) <= 1.0e-12_wp) CYCLE
        DO i = 1, npe
          IF (eq_ids(i) > 0_i4) &
            Q_joule(eq_ids(i)) = Q_joule(eq_ids(i)) + N(i) * Q_ip(ip) * detJ * weight
        END DO
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleJouleHeat

  !-----------------------------------------------------------------------------
  ! RT_Asm_CoupledTE_AssembleThermalBranch
  ! Electric: K_elec·φ=Q_elec (optional solve) -> thermal: K_cond,C,Q_th then
  ! Q_th += Q_joule(φ). Used by RT_CTE_Run (PROC_COUPLED_THERMAL_ELEC).
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_CoupledTE_AssembleThermalBranch(model, phi_io, solve_electric, &
      nDOF_elec_out, K_cond, C_cap, Q_total, nDOF_heat, status)
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(INOUT) :: phi_io(:)
    LOGICAL, INTENT(IN) :: solve_electric
    INTEGER(i4), INTENT(OUT) :: nDOF_elec_out
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: K_cond(:,:), C_cap(:,:), Q_total(:)
    INTEGER(i4), INTENT(OUT) :: nDOF_heat
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), ALLOCATABLE :: K_elec(:,:), Q_elec(:), Q_joule(:)
    INTEGER(i4) :: nDOF_elec
    TYPE(RT_LinearSolver) :: linear_solver
    TYPE(ErrorStatusType) :: lst

    CALL init_error_status(status)
    nDOF_elec_out = 0_i4
    nDOF_heat = 0_i4

    IF (solve_electric) THEN
      CALL RT_Asm_AssembleElectricMatrices(model, K_elec, Q_elec, nDOF_elec, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      nDOF_elec_out = nDOF_elec
      IF (ALLOCATED(K_elec) .AND. nDOF_elec > 0_i4 .AND. SIZE(phi_io) >= nDOF_elec) THEN
        CALL RT_LinearSolver_Init(linear_solver, method=2_i4, maxIter=5000_i4, &
             tolerance=1.0e-8_wp, status=lst)
        IF (lst%status_code == IF_STATUS_OK) THEN
          CALL RT_LinearSolver_Solv(linear_solver, K_elec, Q_elec, phi_io(1:nDOF_elec), lst)
          CALL RT_LinearSolver_Clean(linear_solver, lst)
        END IF
      END IF
      IF (ALLOCATED(K_elec)) DEALLOCATE(K_elec)
      IF (ALLOCATED(Q_elec)) DEALLOCATE(Q_elec)
    END IF

    CALL RT_Asm_AssembleHeatMatrices(model, K_cond, C_cap, Q_total, nDOF_heat, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (ALLOCATED(Q_total) .AND. nDOF_heat > 0_i4 .AND. SIZE(phi_io) >= nDOF_heat) THEN
      ALLOCATE(Q_joule(nDOF_heat))
      Q_joule = 0.0_wp
      CALL RT_Asm_AssembleJouleHeat(model, phi_io, Q_joule, nDOF_heat, lst)
      IF (lst%status_code == IF_STATUS_OK) Q_total(1:nDOF_heat) = Q_total(1:nDOF_heat) + Q_joule(1:nDOF_heat)
      DEALLOCATE(Q_joule)
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_CoupledTE_AssembleThermalBranch

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleCreepForce: F_cr = �?B^T·σ(ε_cr) dV
  !   Norton: Δε_cr = A·σ^n·t^m·Δt; σ_cr from D·ε_cr
  !   Placeholder: ε_cr=0 -> F_cr=0; structure ready for DataPlatform VISCO_creep_strain
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleCreepForce(model, step, state, dofMap, u, F_cr, status)
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    TYPE(StepStateData), INTENT(IN) :: state
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    REAL(wp), INTENT(IN) :: u(:)
    REAL(wp), INTENT(INOUT) :: F_cr(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNodes, nElems, iElem, ip, i, j, npe, mat_pt_idx
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    TYPE(PH_Elem_C3D8_JacB_In) :: in_jacb
    TYPE(PH_Elem_C3D8_JacB_Out) :: out_jacb
    REAL(wp) :: coords(3, 8), xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: B(6, 24), detJ
    REAL(wp) :: sigma_cr(6), D(6, 6), eps_cr(6)
    REAL(wp) :: F_e(24)
    INTEGER(i4) :: node_ids(8), elem_dofs(24), jDOF, iNode, iDOF
    REAL(wp) :: E_mod, nu_poi, lam, mu
    TYPE(ErrorStatusType) :: mesh_st, cr_st

    CALL init_error_status(status)
    IF (SIZE(F_cr) < dofMap%nTotalEq) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_AssembleCreepForce: F_cr size < nTotalEq'
      RETURN
    END IF

    F_cr = 0.0_wp
    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%desc%mesh%initialized) RETURN

    ! [HOT-003] nNodes/nElems from L4 cache when available
    IF (g_ufc_global%ph_layer%element%is_initialized .AND. g_ufc_global%ph_layer%element%n_elements > 0_i4) THEN
      nNodes = g_ufc_global%ph_layer%element%pop%n_nodes
      nElems = g_ufc_global%ph_layer%element%n_elements
    ELSE
      nNodes = INT(g_ufc_global%md_layer%desc%mesh%desc%nNodes, i4)
      nElems = INT(g_ufc_global%md_layer%desc%mesh%raw_data%nElems, i4)
    END IF
    IF (nElems <= 0_i4) RETURN

    E_mod = 2.0e11_wp
    nu_poi = 0.3_wp
    lam = E_mod * nu_poi / ((1.0_wp + nu_poi) * (1.0_wp - 2.0_wp * nu_poi))
    mu = E_mod / (2.0_wp * (1.0_wp + nu_poi))
    D = 0.0_wp
    D(1,1) = lam + 2.0_wp*mu; D(2,2) = lam + 2.0_wp*mu; D(3,3) = lam + 2.0_wp*mu
    D(1,2) = lam; D(1,3) = lam; D(2,1) = lam; D(2,3) = lam; D(3,1) = lam; D(3,2) = lam
    D(4,4) = mu; D(5,5) = mu; D(6,6) = mu

    CALL PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)

    DO iElem = 1, nElems
      eps_cr = 0.0_wp
      IF (g_ufc_global%ph_layer%element%is_initialized .AND. ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map) .AND. &
          iElem <= SIZE(g_ufc_global%ph_layer%element%elem_to_mat_map)) THEN
        mat_pt_idx = g_ufc_global%ph_layer%element%elem_to_mat_map(iElem)
        IF (mat_pt_idx > 0_i4 .AND. g_ufc_global%ph_layer%material%initialized .AND. &
            ALLOCATED(g_ufc_global%ph_layer%material%slot_pool) .AND. &
            mat_pt_idx <= SIZE(g_ufc_global%ph_layer%material%slot_pool)) THEN
          IF (ALLOCATED(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%state%stateVars) .AND. &
              SIZE(g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%state%stateVars) >= 6_i4) THEN
            CALL PH_Mat_GetCreepStrain_FromStateVars( &
                g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)%state%stateVars, eps_cr, cr_st)
          END IF
        END IF
      END IF

      CALL MD_Mesh_GetElemConnect_Idx(iElem, arg_conn, mesh_st)
      IF (mesh_st%status_code /= IF_STATUS_OK .OR. arg_conn%npe <= 0) CYCLE
      npe = arg_conn%npe
      IF (npe /= 8_i4) CYCLE

      node_ids(1:8) = INT(arg_conn%connect(1:8), i4)
      coords = 0.0_wp
      DO i = 1, 8
        CALL MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, mesh_st)
        IF (mesh_st%status_code == IF_STATUS_OK .AND. ALLOCATED(arg_coords%coords)) THEN
          coords(1:MIN(3, SIZE(arg_coords%coords)), i) = arg_coords%coords(1:MIN(3, SIZE(arg_coords%coords)))
        END IF
      END DO

      elem_dofs = 0_i4
      DO iNode = 1, 8
        DO iDOF = 1, 3
          jDOF = (iNode - 1) * 3 + iDOF
          elem_dofs(jDOF) = RT_Asm_DofMap_GetEqId(dofMap, node_ids(iNode), iDOF)
        END DO
      END DO

      sigma_cr = MATMUL(D, eps_cr)
      F_e = 0.0_wp
      DO ip = 1, 8
        in_jacb%coords = coords
        in_jacb%xi = xi(ip)
        in_jacb%eta = eta(ip)
        in_jacb%zeta = zeta(ip)
        CALL PH_Elem_C3D8_JacB(in_jacb, out_jacb)
        IF (out_jacb%status%status_code /= IF_STATUS_OK .OR. ABS(out_jacb%detJ) <= 1.0e-12_wp) CYCLE
        B = out_jacb%B
        detJ = out_jacb%detJ
        DO j = 1, 24
          F_e(j) = F_e(j) + (B(1,j)*sigma_cr(1) + B(2,j)*sigma_cr(2) + B(3,j)*sigma_cr(3) + &
                   B(4,j)*sigma_cr(4) + B(5,j)*sigma_cr(5) + B(6,j)*sigma_cr(6)) * detJ * weights(ip)
        END DO
      END DO

      DO j = 1, 24
        IF (elem_dofs(j) > 0_i4 .AND. elem_dofs(j) <= SIZE(F_cr)) &
          F_cr(elem_dofs(j)) = F_cr(elem_dofs(j)) + F_e(j)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_AssembleCreepForce

  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleSoilsBlock: [K L; L^T -S]{u;p} block for Biot u-p coupling
  !   C3D8P: Kuu, Kpp, Kup from PH_Soils_C3D8P_FormBlockStiffness (L4_PH)
  !   When dofMap supports u-p (eqFieldId/fieldEqCount for pore DOF): assemble L/S/H
  !   Current: K_uu from GlobalStiffness; L/S/H placeholder (dofMap u-p pending)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssembleSoilsBlock(model, step, state, dofMap, K_uu, F_u, status)
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(AnalysisStep), INTENT(IN) :: step
    TYPE(StepStateData), INTENT(IN) :: state
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K_uu
    REAL(wp), INTENT(INOUT) :: F_u(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (SIZE(F_u) < dofMap%nTotalEq) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Asm_AssembleSoilsBlock: F_u size < nTotalEq'
      RETURN
    END IF
    K_uu%init = .FALSE.
    CALL RT_Asm_GlobalStiffness(model, step, state, dofMap, K_uu, RT_Asm_Cfg(), status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL RT_Asm_GlobalLoad(model, step, 0.0_wp, dofMap, F_u, RT_Asm_Cfg(), status)
    ! L, S, H, F_p: placeholder (dofMap u-p extension pending)
  END SUBROUTINE RT_Asm_AssembleSoilsBlock

  !-----------------------------------------------------------------------------
  ! RT_Asm_AddGeostaticGravity: Add F_grav = �?N^T·ρ·g dΩ to F_ext
  !   Phase 3: PROC_12 geostatic assembly. Uses PH_Geostatic_GravityForce (skeleton).
  !   F_ext += F_grav; rho, g_vec from step%geo_ctrl.
  !   Mutually exclusive with RT_Asm_Cfg%body_force_lumped_to_fext=.FALSE. (element rho*g path).
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AddGeostaticGravity(step, F_ext, status)
    TYPE(AnalysisStep), INTENT(IN) :: step
    REAL(wp), INTENT(INOUT) :: F_ext(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: g_vec(3)
    REAL(wp), ALLOCATABLE :: F_grav(:)
    INTEGER(i4) :: n_dof

    CALL init_error_status(status)
    n_dof = SIZE(F_ext)
    IF (n_dof <= 0_i4) RETURN
    ALLOCATE(F_grav(n_dof))
    g_vec(1) = 0.0_wp
    g_vec(2) = 0.0_wp
    g_vec(3) = step%geo_ctrl%gravity_z
    CALL PH_Geostatic_GravityForce(step%geo_ctrl%density_ref, g_vec, n_dof, F_grav, status)
    IF (status%status_code == IF_STATUS_OK) F_ext(1:n_dof) = F_ext(1:n_dof) + F_grav(1:n_dof)
    DEALLOCATE(F_grav)
  END SUBROUTINE RT_Asm_AddGeostaticGravity

  !---------------------------------------------------------------------------
  ! Map element local dof index j (L4 / PH_Element ordering) to global equation.
  ! Blocked layouts match PH cores: C3D8T (u|T), CPE4T (u|T), S4T (24 mech + 4 T),
  ! C3D8PT (u|p|T), B31T (12 mech + 2 T), etc.  Default: uniform n_dof/npe per node.
  ! B21T (8 dof, 2 nodes): 4 dof/node (plane mech + T) uses DEFAULT when no explicit CASE.
  !---------------------------------------------------------------------------
  FUNCTION RT_Asm_Solv_LocalJToEqId(dofMap, connect, npe, elem_typ, n_dof, jDOF) RESULT(eq_id)
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    INTEGER(i8), INTENT(IN) :: connect(:)
    INTEGER(i4), INTENT(IN) :: npe, elem_typ, n_dof, jDOF
    INTEGER(i4) :: eq_id

    INTEGER(i4) :: iNode, local_dof, ndpn, n_mech
    INTEGER(i4) :: nid

    eq_id = 0_i4
    IF (jDOF < 1_i4 .OR. jDOF > n_dof .OR. npe < 1_i4) RETURN

    SELECT CASE (elem_typ)
    CASE (ELEM_S4T)
      IF (jDOF <= 24_i4) THEN
        iNode = (jDOF - 1_i4) / 6_i4 + 1_i4
        local_dof = MOD(jDOF - 1_i4, 6_i4) + 1_i4
      ELSE
        iNode = jDOF - 24_i4
        local_dof = 7_i4
      END IF
    CASE (ELEM_S8RT)
      IF (jDOF <= 48_i4) THEN
        iNode = (jDOF - 1_i4) / 6_i4 + 1_i4
        local_dof = MOD(jDOF - 1_i4, 6_i4) + 1_i4
      ELSE
        iNode = jDOF - 48_i4
        local_dof = 7_i4
      END IF
    CASE (ELEM_B31T)
      IF (jDOF <= 6_i4) THEN
        iNode = 1_i4
        local_dof = jDOF
      ELSE IF (jDOF <= 12_i4) THEN
        iNode = 2_i4
        local_dof = jDOF - 6_i4
      ELSE IF (jDOF == 13_i4) THEN
        iNode = 1_i4
        local_dof = 7_i4
      ELSE
        iNode = 2_i4
        local_dof = 7_i4
      END IF
    CASE (ELEM_C3D8PT)
      IF (jDOF <= 24_i4) THEN
        iNode = (jDOF - 1_i4) / 3_i4 + 1_i4
        local_dof = MOD(jDOF - 1_i4, 3_i4) + 1_i4
      ELSE IF (jDOF <= 32_i4) THEN
        iNode = jDOF - 24_i4
        local_dof = 4_i4
      ELSE
        iNode = jDOF - 32_i4
        local_dof = 5_i4
      END IF
    CASE (ELEM_C3D4T, ELEM_C3D6T, ELEM_C3D8T, ELEM_C3D10T, ELEM_C3D15T, ELEM_C3D20T, ELEM_C3D27T)
      n_mech = 3_i4 * npe
      IF (jDOF <= n_mech) THEN
        iNode = (jDOF - 1_i4) / 3_i4 + 1_i4
        local_dof = MOD(jDOF - 1_i4, 3_i4) + 1_i4
      ELSE IF (jDOF <= n_dof) THEN
        iNode = jDOF - n_mech
        local_dof = 4_i4
      ELSE
        RETURN
      END IF
    CASE (ELEM_C3D4P, ELEM_C3D6P, ELEM_C3D8P, ELEM_C3D10P, ELEM_C3D15P, ELEM_C3D20P, ELEM_C3D27P)
      n_mech = 3_i4 * npe
      IF (jDOF <= n_mech) THEN
        iNode = (jDOF - 1_i4) / 3_i4 + 1_i4
        local_dof = MOD(jDOF - 1_i4, 3_i4) + 1_i4
      ELSE IF (jDOF <= n_dof) THEN
        iNode = jDOF - n_mech
        local_dof = 4_i4
      ELSE
        RETURN
      END IF
    CASE (ELEM_CPE4T, ELEM_CPE8T, ELEM_CPS4T, ELEM_CPS8T, ELEM_CAX4T, ELEM_CAX8T)
      n_mech = 2_i4 * npe
      IF (jDOF <= n_mech) THEN
        iNode = (jDOF - 1_i4) / 2_i4 + 1_i4
        local_dof = MOD(jDOF - 1_i4, 2_i4) + 1_i4
      ELSE IF (jDOF <= n_dof) THEN
        iNode = jDOF - n_mech
        local_dof = 3_i4
      ELSE
        RETURN
      END IF
    CASE (ELEM_CPE4P, ELEM_CPE8P, ELEM_CAX4P, ELEM_CAX8P)
      n_mech = 2_i4 * npe
      IF (jDOF <= n_mech) THEN
        iNode = (jDOF - 1_i4) / 2_i4 + 1_i4
        local_dof = MOD(jDOF - 1_i4, 2_i4) + 1_i4
      ELSE IF (jDOF <= n_dof) THEN
        iNode = jDOF - n_mech
        local_dof = 3_i4
      ELSE
        RETURN
      END IF
    CASE DEFAULT
      IF (MOD(n_dof, npe) /= 0_i4) RETURN
      ndpn = n_dof / npe
      iNode = (jDOF - 1_i4) / ndpn + 1_i4
      local_dof = MOD(jDOF - 1_i4, ndpn) + 1_i4
    END SELECT

    IF (iNode < 1_i4 .OR. iNode > npe) RETURN
    IF (iNode > INT(SIZE(connect), i4)) RETURN
    nid = INT(connect(iNode), i4)
    eq_id = RT_Asm_DofMap_GetEqId(dofMap, nid, local_dof)
  END FUNCTION RT_Asm_Solv_LocalJToEqId

  !====================================================================
  ! RT_Asm_ScatterKe_CSR_Atomic
  !   Scatter element Ke into CSR K%values using ATOMIC updates.
  !   Safe to call from inside !$OMP PARALLEL DO.
  !====================================================================
  SUBROUTINE RT_Asm_ScatterKe_CSR_Atomic(K, Ke, elem_dofs, n_dof)
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: K
    REAL(wp), INTENT(IN) :: Ke(:,:)
    INTEGER(i4), INTENT(IN) :: elem_dofs(:)
    INTEGER(i4), INTENT(IN) :: n_dof

    INTEGER(i4) :: ii, jj, row, col, kk, start_k, end_k

    DO jj = 1, n_dof
      col = elem_dofs(jj)
      IF (col < 1_i4 .OR. col > K%nCols) CYCLE
      DO ii = 1, n_dof
        row = elem_dofs(ii)
        IF (row < 1_i4 .OR. row > K%nRows) CYCLE
        IF (ABS(Ke(ii, jj)) <= 1.0e-15_wp) CYCLE
        start_k = K%rowPtr(row)
        end_k = K%rowPtr(row + 1) - 1
        DO kk = start_k, end_k
          IF (K%colInd(kk) == col) THEN
            !$OMP ATOMIC
            K%values(kk) = K%values(kk) + Ke(ii, jj)
            EXIT
          END IF
        END DO
      END DO
    END DO
  END SUBROUTINE RT_Asm_ScatterKe_CSR_Atomic

  !---------------------------------------------------------------------------
  ! Copy material slot props into ke_arg%mat_props_in (TARGET) for L4 Eval_Ke
  ! without PH_Elem_Domain USE-ing g_ufc_global (breaks USE cycle with L0 global).
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Solv_KeArg_AttachMatProps(ke_arg)
    TYPE(PH_Element_Compute_Ke_Arg), INTENT(INOUT) :: ke_arg
    INTEGER(i4) :: kidx, np

    IF (ALLOCATED(ke_arg%mat_props_in)) DEALLOCATE(ke_arg%mat_props_in)
    kidx = ke_arg%mat_pt_idx
    IF (.NOT. g_ufc_global%IsReady()) RETURN
    IF (.NOT. g_ufc_global%ph_layer%material%initialized) RETURN
    IF (.NOT. ALLOCATED(g_ufc_global%ph_layer%material%slot_pool)) RETURN
    IF (kidx < 1_i4) RETURN
    IF (kidx > INT(SIZE(g_ufc_global%ph_layer%material%slot_pool), KIND=i4)) RETURN
    IF (.NOT. ALLOCATED(g_ufc_global%ph_layer%material%slot_pool(kidx)%desc%props)) RETURN
    np = INT(SIZE(g_ufc_global%ph_layer%material%slot_pool(kidx)%desc%props), KIND=i4)
    IF (np < 1_i4) RETURN
    ALLOCATE(ke_arg%mat_props_in(np))
    ke_arg%mat_props_in = g_ufc_global%ph_layer%material%slot_pool(kidx)%desc%props
  END SUBROUTINE RT_Asm_Solv_KeArg_AttachMatProps

  SUBROUTINE RT_Asm_Solv_KeArg_ClearMatProps(ke_arg)
    TYPE(PH_Element_Compute_Ke_Arg), INTENT(INOUT) :: ke_arg
    IF (ALLOCATED(ke_arg%mat_props_in)) DEALLOCATE(ke_arg%mat_props_in)
  END SUBROUTINE RT_Asm_Solv_KeArg_ClearMatProps

  !---------------------------------------------------------------------------
  ! Fe 金线：load_case 来自 step；load_magn_in 预分配为空间维数、初值 0。
  ! 仅当载荷只进单元弱式、不进 RT_Asm_GlobalLoad 的 F_ext 时，才在此按 iElem/L3 填非零；
  ! 与 PH_Elem_Eval_Fe / Load_Kernel 对齐（见 L5 Assembly CONTRACT 5.4）。
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Solv_FeArg_AttachLoadMagn(fe_arg, step, spatial_dim, iElem, asm_cfg)
    TYPE(PH_Element_Compute_Fe_Arg), INTENT(INOUT) :: fe_arg
    CLASS(UF_StepDef), INTENT(IN) :: step
    INTEGER(i4), INTENT(IN) :: spatial_dim
    INTEGER(i4), INTENT(IN) :: iElem
    TYPE(RT_Asm_Cfg), INTENT(IN) :: asm_cfg

    INTEGER(i4) :: nd
    INTEGER(i4) :: et_dbg
    REAL(wp) :: rho_g

    et_dbg = 0_i4
    IF (g_ufc_global%IsReady() .AND. iElem >= 1_i4 .AND. &
        ALLOCATED(g_ufc_global%ph_layer%element%elem_type_cache) .AND. &
        iElem <= SIZE(g_ufc_global%ph_layer%element%elem_type_cache)) THEN
      et_dbg = g_ufc_global%ph_layer%element%elem_type_cache(iElem)
    END IF
    ! et_dbg reserved for per-element DLOAD/BODY scaling (no effect until wired)
    fe_arg%load_case = MAX(1_i4, step%step_number) + 0_i4 * et_dbg
    IF (ALLOCATED(fe_arg%load_magn_in)) DEALLOCATE(fe_arg%load_magn_in)
    nd = spatial_dim
    IF (nd < 2_i4) nd = 3_i4
    IF (nd > 3_i4) nd = 3_i4
    ALLOCATE(fe_arg%load_magn_in(nd))
    fe_arg%load_magn_in = 0.0_wp
    IF (.NOT. asm_cfg%body_force_lumped_to_fext) THEN
      rho_g = step%geo_ctrl%density_ref * step%geo_ctrl%gravity_z
      IF (nd >= 3_i4) THEN
        fe_arg%load_magn_in(3) = rho_g
      ELSE
        fe_arg%load_magn_in(2) = rho_g
      END IF
    END IF
  END SUBROUTINE RT_Asm_Solv_FeArg_AttachLoadMagn

  SUBROUTINE RT_Asm_Solv_FeArg_ClearLoadMagn(fe_arg)
    TYPE(PH_Element_Compute_Fe_Arg), INTENT(INOUT) :: fe_arg
    IF (ALLOCATED(fe_arg%load_magn_in)) DEALLOCATE(fe_arg%load_magn_in)
  END SUBROUTINE RT_Asm_Solv_FeArg_ClearLoadMagn

END MODULE RT_Asm_Solv