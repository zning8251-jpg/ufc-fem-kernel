# UFC L3/L4/L5 Cross-Layer Data Flow v1

> **Version**: 1.0 | **Date**: 2026-05-06
> **Purpose**: Define data injection, algorithm flow binding, vertical slice + horizontal expansion for all 8 domain pillars
> **Aligns with**: UFC_L3L4L5_二元重构蓝图规范_v1.0, UFC_Naming_Standard_v3.0, all L3/L4/L5 CONTRACT.md files

---

## 1. Data Flow Architecture Overview

### 1.1 General Flow Pattern

Each domain pillar follows this 3-layer pipeline:

```
L3_MD  (Model Data)    --[Populate]--> L4_PH (Physics)    --[Dispatch]--> L5_RT (Runtime)
   |                           |                            |
   Desc (read-only config)     Desc (L3 data + PH extras)   Desc (L4 wrappers + routing table)
   State (model-level)         State (physics state)        State (runtime state buffer)
   Algo (algorithm ctrl)       Algo (evaluation params)     Algo (dispatch strategy)
   Ctx (model context)         Ctx (evaluation context)     Ctx (runtime context)
```

### 1.2 Layer Responsibility Boundaries

| Responsibility | L3_MD | L4_PH | L5_RT |
|---|---|---|---|
| **SSOT (Single Source of Truth)** | Yes — all model config | No — receives populated data | No — receives dispatch wrappers |
| **Physics Computation** | No | Yes — kernel implementations | No — dispatches to L4 |
| **Runtime Orchestration** | No | No | Yes — step/increment/iteration loops |
| **Cross-Layer Bridge** | Bridge subdirectories (`Bridge_L4/`, `Bridge_L5/`) | Bridge via `PH_*_Brg` | Bridge via `RT_*_Brg` |
| **SIO Arg Bundles** | At L5 boundary only | At L3-L4 boundary | At dispatch boundary |
| **Data Temperature** | Cold (write-once, read-many) | Warm (per-step/incr updates) | Hot (per-iteration stack) |

### 1.3 Data Injection Modes

| Mode | Direction | Trigger | Example |
|------|-----------|---------|---------|
| Static Populate | L3 -> L4 Desc | Init | Material properties, section data |
| Dynamic Sync | L3 <-> L4/5 State | Step/Incr boundary | Stress update, state variables |
| Demand Eval | L4 -> L5 -> L4 | Integration point | Eval via dispatcher callback |
| Bridge FromL3 | L3 -> L5 Desc | Step setup | Populate from Bridge_L5/* |
| Bridge ToL4 | L5 -> L4 Desc | Dispatch | Route Args to PH kernel |

### 1.4 Algorithm Binding Patterns

| Pattern | Description | Used By |
|---------|-------------|---------|
| Golden Line (Direct) | L5 dispatcher calls L4 kernel directly with typed Arg bundle | Material, Element, Contact |
| Bridge (Indirect) | L5_Proc defines SIO abstract interface, L4_Brg implements it | Contact (search dispatch), LoadBC |
| Hybrid | Direct dispatch for hot path, bridge for cold path | Output, WriteBack |
| Half-Pillar | L3->L5 direct, no L4 intermediate | Solver, Step, Section |

### 1.5 SIO / `*_Arg` Usage Rules

Per Principle #14 and `ufc-structured-io` skill:
- **Hard SIO**: Layer boundaries (L3<->L4, L4<->L5), L5 `_Proc` modules, Harness
- **Pragmatic**: L3 internal domains keep `*_Arg` only when >=2 fields co-evolve, or consumed by Harness/cross-layer
- **No thin wrappers**: Do not create `*_Arg` wrapping only `status` — use direct `(..., status)` signature
- **INTENT convention**: Desc/INTENT(IN), State/INTENT(INOUT), Algo/INTENT(IN), Ctx/INTENT(INOUT), Arg/INTENT(INOUT)

---

## 2. P1: Material Domain

### 2.1 Data Flow Chain

```
L3_MD Material/
  | MD_Mat_Elas_Def.f90  ── MODULE: MD_Mat_Elas_Def
  |   MD_Mat_Elas_Desc          (E, nu, props[], family_id)
  |   MD_Mat_Elas_State         (stress[], strain[], statev[])
  |   MD_Mat_Elas_Algo          (integration_scheme, constitutive_ptr)
  |   MD_Mat_Elas_Ctx           (temperature, field_values)
  |   PH_Mat_Elas_Eval_Arg      (dstrain, dtime => stress_new, ddsdde, statev)
  |
  | [Populate] via Bridge/Bridge_L4/... or PH_L4_Populate_Material
  v
L4_PH Material/
  | PH_Mat_Elas_Def.f90  ── MODULE: PH_Mat_Elas_Def
  |   PH_Mat_Elas_Desc          (E, nu, props[], material_id)
  |   PH_Mat_Elas_State         (stress[], strain[], statev[])
  |   PH_Mat_Elas_Algo          (integration_scheme, constitutive_ptr)
  |   PH_Mat_Elas_Ctx           (time_inc, dstrain[], temperature)
  |
  | PH_Mat_Elas_Core.f90  ── MODULE: PH_Mat_Elas_Core
  |   [Eval] PH_Mat_Elas_IP_Incr_Eval(desc, state, algo, ctx, args, status)
  |     args = PH_Mat_Elas_Eval_Arg {dstrain, dtime => stress_new, ddsdde, statev}
  |
  | PH_Mat_Algo.f90  ── MODULE: PH_Mat_Algo
  |   TYPE(PH_Mat_Algo) with constitutive_ptr (procedure pointer)
  |   PH_Mat_Execute_Flow_S1(desc, state, algo, ctx, args, status)    ! Pre-processing
  |   PH_Mat_Execute_Flow_S2(desc, state, algo, ctx, args, status)    ! Kinematics
  |   PH_Mat_Execute_Flow_S3(desc, state, algo, ctx, args, status)    ! Constitutive eval
  |   PH_Mat_Execute_Flow_S4(desc, state, algo, ctx, args, status)    ! Post-processing
  v
L5_RT Material/
  | RT_Mat_Elas_Def.f90  ── MODULE: RT_Mat_Elas_Def
  |   RT_Mat_Elas_Desc          (mat_id, l3_slot, l4_desc_ptr)
  |   RT_Mat_Elas_State         (state_buffer, current_slot)
  |   RT_Mat_Elas_Algo          (family_id, dispatch_table)
  |   RT_Mat_Elas_Ctx           (current_ip, current_elem, scratch)
  |
  | RT_Mat_Elas_Dispatch_Arg    (ip_idx, elem_idx => stress, ddsdde, ...)
  | RT_Mat_Plast_Route_Entry    (procedure pointer for plasticity families)
  | RT_Mat_Hyper_Route_Entry    (procedure pointer for hyperelastic families)
  | RT_Mat_User_Route_Entry     (procedure pointer for UMAT families)
  |
  | RT_Mat_Dispatch.f90  ── MODULE: RT_Mat_Dispatch
  |   RT_Mat_Dispatch_Stress(desc, state, algo, ctx, args, status)
  |   RT_Mat_Dispatch_Tangent(desc, state, algo, ctx, args, status)
  |
  | [Dispatch] RT_Mat_Elas_Dispatch_Run(desc, state, algo, ctx, args, status)
  |   Internal flow:
  |     1. Resolve family_id from desc
  |     2. Lookup dispatch_table[family_id]
  |     3. Call PH_Mat_{family}_IP_Incr_Eval via procedure pointer
  |     4. Write back to args%stress, args%ddsdde
```

### 2.2 SIO Arg Types

| Layer | Arg Type | Module | Key Fields |
|-------|----------|--------|------------|
| L3->L4 | `PH_Mat_Elas_Eval_Arg` | `MD_Mat_Elas_Def` | `dstrain(6)`, `dtime`, `stress_new(6)` [OUT], `ddsdde(6,6)` [OUT], `statev(:)` [INOUT] |
| L4 | `PH_Mat_Elas_Init_Arg` | `PH_Mat_Elas_Def` | `props(:)`, `nprops`, `nstatv`, `status` |
| L4 | `PH_Mat_Elas_GetCtx_Arg` | `PH_Mat_Elas_Def` | `temperature`, `field_values(:)`, `status` |
| L4 | `PH_Mat_Elas_SetState_Arg` | `PH_Mat_Elas_Def` | `stress(6)`, `strain(6)`, `statev(:)`, `status` |
| L5 | `RT_Mat_Dispatch_Arg` | `RT_Mat_Elas_Def` | `ip_idx`, `elem_idx`, `stress(6)` [OUT], `ddsdde(6,6)` [OUT], `statev(:)` [INOUT], `status` |
| L5 | `RT_Mat_Plast_Dispatch_Arg` | `RT_Mat_Plast_Def` | family-specific plastic params |
| L5 | `RT_Mat_Hyper_Dispatch_Arg` | `RT_Mat_Hyper_Def` | family-specific hyperelastic params |

Note: L5 uses 4 family dispatch Arg types for plastic/hyperelastic/user/general routing (the "dispatch quadrant").

### 2.3 Key Procedures

| Layer | Procedure | Signature Skeleton |
|-------|-----------|-------------------|
| L3 | `MD_Mat_Elas_Desc_Init` | `(desc, status)` |
| L3 | `MD_Mat_Elas_Core_Populate` | `(desc, args, status)` |
| L4 | `PH_Mat_Elas_IP_Incr_Eval` | `(desc, state, algo, ctx, args, status)` |
| L4 | `PH_Mat_Elas_IP_Incr_Update` | `(desc, state, algo, ctx, args, status)` |
| L4 | `PH_Mat_Execute_Flow_S1` | `(desc, state, algo, ctx, args, status)` — pre-processing |
| L4 | `PH_Mat_Execute_Flow_S2` | `(desc, state, algo, ctx, args, status)` — kinematics |
| L4 | `PH_Mat_Execute_Flow_S3` | `(desc, state, algo, ctx, args, status)` — constitutive |
| L4 | `PH_Mat_Execute_Flow_S4` | `(desc, state, algo, ctx, args, status)` — post-processing |
| L4 | `PH_L4_Populate_Material` | `(md_layer, ph_layer, status)` — bulk populate |
| L5 | `RT_Mat_Dispatch_Stress` | `(desc, state, algo, ctx, args, status)` |
| L5 | `RT_Mat_Dispatch_Tangent` | `(desc, state, algo, ctx, args, status)` |

### 2.4 Golden Line / Bridge Mechanism

- **Golden Line (Direct)**: `RT_Mat_Dispatch_Stress` -> procedure pointer table -> `PH_Mat_{family}_IP_Incr_Eval`. The dispatch table (`RT_Mat_Elas_Algo%dispatch_table`) holds family-specific procedure pointers populated during registration.
- **Populate**: `PH_L4_Populate_Material` iterates L3 material descriptors, creates L4 copies with added physics-layer fields (material_id, integration context).
- **Family registration**: Each material family (elas, plast, hyper, user/UMAT) registers its dispatch entry into `RT_Mat_Elas_Algo%dispatch_table` at init time.

---

## 3. P2: Element Domain

### 3.1 Data Flow Chain

```
L3_MD Elem/
  | MD_Elem_Def.f90  ── MODULE: MD_Elem_Def  (canonical)
  |   MD_Elem_Desc          (cfg_id, cfg_topo, cfg_geom, pop_flag)
  |     cfg_id:    id, elem_type_id, family_id, sect_id, mat_id
  |     cfg_topo:  n_nodes, n_dof, dof_per_node, ndim, n_ip
  |     cfg_geom:  geom_kind, thickness
  |     pop_flag:  has_mass, has_damp, has_thermal, nlgeom
  |   MD_Elem_State         (total_elements, active_elements, total_mass)
  |   MD_Elem_Algo          (stp: ip_scheme, hourglass, eas/fbar; dyn: damping, rayleigh)
  |   MD_Elem_Ctx           (model_id, part_id, assembly_id, n_instances)
  |
  | 12 family-specific Desc types (Solid3D, Shell, Beam, Truss, etc.)
  | 6 family-specific Algo types (Solid3D, Shell, Beam, Truss, Cohesive, Mass)
  |
  | [Populate] MD_Elem_Populate.f90 → Bridge_L4/ or PH_L4_Populate_Elem
  v
L4_PH Element/
  | PH_Elem_Def.f90  ── MODULE: PH_Elem_Def
  |   PH_Elem_Desc          (cfg: type, formulation, n_dof, n_ip; pop: mat_id)
  |   PH_Elem_State         (stp: element_status; itr: iteration_state)
  |   PH_Elem_Algo          (stp: integration, nlgeom; dyn: integrator_ptr)  ← PROCEDURE POINTER
  |   PH_Elem_Ctx           (inc: step_time, dt; itr: iteration; lcl: gp_data; evo: history)
  |
  | PH_Elem_Core.f90  ── MODULE: PH_Elem_Core
  |   PH_Elem_Core_Ke_Arg   (elem_id, gp_coords, props => ke_matrix, fe_vector)
  |   PH_Elem_Core_Fe_Arg   (elem_id, gp_data => internal_force)
  |   PH_Element_Compute_Ke_Arg  (golden line — unified stiffness eval bundle)
  |   + 15+ additional SIO Arg types for NL_TL/NL_UL/Contact/Constraint variants
  |
  | [Compute] PH_Elem_Compute_Ke(desc, state, algo, ctx, args, status)
  |   Internal: calls integrator via PH_Elem_Algo%integrator_ptr
  v
L5_RT Element/
  | RT_Elem_Def.f90  ── MODULE: RT_Elem_Def
  |   RT_Elem_Desc          (base fields + L5 extras: runtime_id, dispatch_id, ...)
  |   RT_Elem_State         (runtime info cache)
  |   RT_Elem_Algo          (router table)
  |   RT_Elem_Ctx           (hot-path scratch)
  |
  | RT_Elem_Proc.f90  ── MODULE: RT_Elem_Proc
  |   7 SIO interfaces for the dispatch quadrant
  |   RT_Elem_Router_Entry  (procedure pointer: family-router dispatch entry)
  |
  | [Dispatch] RT_Elem_Dispatch_Run(desc, state, algo, ctx, args, status)
  |   1. Resolve elem family from desc%cfg_id
  |   2. Lookup router table
  |   3. Call PH_Elem_{family}_Compute via procedure pointer
  |   4. Return assembled ke/fe in args
```

### 3.2 SIO Arg Types

| Arg Type | Module | Purpose | Key Fields |
|----------|--------|---------|------------|
| `PH_Elem_Core_Ke_Arg` | `PH_Elem_Core` | Stiffness matrix eval | `elem_id`, `gp_coords(3,*)`, `props(:)`, `ke_matrix(:,:)` [OUT], `fe_vector(:)` [OUT] |
| `PH_Elem_Core_Fe_Arg` | `PH_Elem_Core` | Internal force eval | `elem_id`, `gp_data`, `fe_internal(:)` [OUT] |
| `PH_Element_Compute_Ke_Arg` | `PH_Elem_Core` | Golden-line unified | `desc`, `state`, `algo`, `ctx`, `ke(:,:)` [OUT], `fe(:)` [OUT], `status` |
| `PH_Elem_Core_Mass_Arg` | `PH_Elem_Core` | Mass matrix eval | `me(:,:)` [OUT] |
| `PH_Elem_Core_NL_TL_Arg` | `PH_Elem_Core` | Total Lagrangian NL | NL-specific fields |
| `PH_Elem_Core_NL_UL_Arg` | `PH_Elem_Core` | Updated Lagrangian NL | UL-specific fields |
| `PH_Elem_Core_JacB_Arg` | `PH_Elem_Core` | Jacobian (B-matrix) | `B_mat(:,:)` [OUT] |
| `PH_Elem_Core_Contact_Arg` | `PH_Elem_Core` | Contact contribution | Contact-specific fields |
| `PH_Elem_Core_Constraint_Arg` | `PH_Elem_Core` | Constraint contribution | Constraint-specific fields |
| `RT_Elem_Dispatch_Arg` | `RT_Elem_Def` | L5 dispatch bundle | `elem_id`, `family`, `ke(:,:)` [OUT], `fe(:)` [OUT], `status` |

### 3.3 Key Procedures

| Layer | Procedure | Signature Skeleton |
|-------|-----------|-------------------|
| L3 | `MD_Elem_Config_Init` | `(desc, config, status)` |
| L4 | `PH_Elem_Compute_Ke` | `(desc, state, algo, ctx, args, status)` |
| L4 | `PH_Elem_Compute_Fe` | `(desc, state, algo, ctx, args, status)` |
| L4 | `PH_Elem_Compute_Mass` | `(desc, state, algo, ctx, args, status)` |
| L4 | `PH_Elem_Core_Init` | `(desc, state, algo, ctx, status)` |
| L4 | `PH_L4_Populate_Elem` | `(md_layer, ph_layer, status)` |
| L5 | `RT_Elem_Dispatch_Run` | `(desc, state, algo, ctx, args, status)` |
| L5 | `RT_Elem_Dispatcher_Register` | `(algo, family_id, proc_ptr, status)` |

### 3.4 Golden Line / Bridge Mechanism

- **Golden Line (Direct)**: `RT_Elem_Dispatch_Run` → `RT_Elem_Router_Entry` procedure pointer → `PH_Elem_{family}_Compute_*`. The router is populated at init via `RT_Elem_Dispatcher_Register`.
- **Integrator pointer**: `PH_Elem_Algo%integrator_ptr` is a procedure pointer to the family-specific integration scheme (e.g., `PH_Elem_Solid3D_Integrate`, `PH_Elem_Shell_Integrate`), bound during Populate.
- **Populate path**: `MD_Elem_Populate` or `PH_L4_Populate_Elem` copies L3 element config into L4 `PH_Elem_Desc`, resolves material/section references, and binds the integrator procedure pointer.

---

## 4. P3: Contact/Interaction Domain

### 4.1 Data Flow Chain

```
L3_MD Interaction/
  | MD_Int_Def.f90        ── MODULE: MD_Int_Def  (AUTHORITY four-type)
  |   MD_Int_Desc              (cfg_id, cfg_container, cfg_api, output_format)
  |   MD_Int_State             (is_active, contact_status, contact_area, itr_whitelist)
  |   MD_Int_Algo              (algorithm_type, stp_penalty, stp_conv, stp_fricdamp)
  |   MD_Int_Ctx               (lcl_io, lcl_work)
  |
  | MD_Int_Types.f90       ── MODULE: MD_Int_Types
  |   MD_Int_ContNode_State    (global_id, local_id, state, gap, penetration, forces)
  |   MD_Int_Pair_Desc         (pair_name, surfaces, contact_type)
  |   MD_Int_SurfInt_Desc      (interaction_name, normal/tangent_behavior)
  |   MD_Int_Surface_Desc      (id, n_nodes, n_segments, coords, segments)
  |   6 SIO Arg types for penalty/Lagrange/geometry/friction
  |
  | [Bridge] Bridge/Bridge_L4/MD_ContPH_Brg.f90  ── MODULE: MD_ContPH_Brg
  |   MD_Cont_PH_FillParams_FromMD(desc, ph_desc, status)
  | [Bridge] Bridge/Bridge_L5/MD_ContRT_Brg.f90  ── MODULE: MD_ContRT_Brg
  |   MD_RT_Cont_TripletAdd, MD_RT_Cont_GetEqId
  | [Bridge] Bridge/Bridge_L5/MD_Int_ContactArgs.f90  ── MODULE: MD_Int_ContactArgs
  |   6 Arg types for L3→L5 contact assembly
  v
L4_PH Contact/
  | PH_Cont_Def.f90       ── MODULE: PH_Cont_Def  (AUTHORITY four-type)
  |   PH_Cont_Desc             (constr: method, penalty; friction: model; search: algo)
  |   PH_Cont_Algo             (constr: iter/tol; friction: rate/config; search_strategy PTR)
  |   PH_Cont_State            (contact_state, geometry, force, stiffness, friction, convergence)
  |   PH_Cont_Ctx              (lcl_pos, lcl_normal, lcl_stiff)
  |   ~30 SIO Arg types for force/stiffness/friction/search/eval
  |
  | PH_Cont_Core.f90      ── MODULE: PH_Cont_Core
  |   PH_Contact_Core_Init(desc, state, algo, ctx, status)
  |   PH_Contact_Compute_Gap(desc, state, ctx, status)
  |   PH_Contact_Compute_Normal_Force(desc, state, status)
  |   PH_Contact_Compute_Friction_Force(desc, state, status)
  |   PH_Contact_Compute_Stiffness(desc, state, ctx, status)
  |
  | Core/PH_Cont_Brg.f90  ── MODULE: PH_Cont_Brg  (unstructured + structured API wrappers)
  | Search/PH_Cont_Search.f90  ── MODULE: PH_Cont_Search
  |   Spatial hash, bounding box, BVH query, broad/narrow phase
  |
  | [Eval] contact kernels called via L5 dispatch
  v
L5_RT Contact/
  | RT_Cont_Def.f90       ── MODULE: RT_Cont_Def  (AUTHORITY four-type + constants)
  |   RT_Contact_Desc          (n_contact_pairs, surfaces, friction, search_tol)
  |   RT_Contact_State         (pair_active, pair_status, forces, penetration, AugLag lambda_n)
  |   RT_Contact_Algo          (discretization, enforcement, friction, search, AugLag params)
  |   RT_Contact_Ctx           (current_pair, gap, normal, tangent, scratch arrays)
  |   RT_Cont_Dispatch_Arg     (desc, state, algo, ctx, search_tol, forces [OUT], status)
  |
  | RT_Cont_Core.f90      ── MODULE: RT_Cont_Core  (four-type facade + lifecycle + registry)
  |   RT_Contact_Core_Init(desc, state, algo, ctx, status)
  |   RT_Contact_Search(desc, state, algo, status)
  |   RT_Contact_Evaluate_Pairs(desc, state, algo, ctx, status)
  |   RT_Contact_Assemble_K(desc, state, ctx, status)
  |   RT_Contact_Assemble_F(desc, state, ctx, status)
  |
  | RT_Cont_Solv.f90      ── MODULE: RT_Cont_Solv  (GOLDEN-LINE SIO interfaces)
  |   RT_Cont_Search           (search dispatch → L4 PH_ContSearch)
  |   RT_Cont_ComputeForce     (force dispatch → L4 PH_Cont_*)
  |   RT_Cont_Assemble         (assembly → global K/F)
  |
  | RT_Cont_Brg.f90       ── MODULE: RT_Cont_Brg
  |   RT_Contact_Brg_FromL3(desc, l3_layer, status)
  |   RT_Contact_Brg_ToL4(desc, ph_layer, status)
  |   RT_Contact_Brg_WriteBack(state, l3_layer, status)
  |
  | RT_Cont_AugLagSolv.f90 ── MODULE: RT_Cont_AugLagSolv
  |   RT_Cont_AugLag_Solve, RT_Cont_AugLag_UpdateLambda, RT_Cont_AugLag_CheckConv
  |   RT_Cont_AugLag_In/Out Arg types
```

### 4.2 Cross-Layer Type Wrapping

| L3 Type | L4 Type | L5 Type | Wrapping Pattern |
|---------|---------|---------|-----------------|
| `MD_Int_Desc` | `PH_Cont_Desc` | `RT_Contact_Desc` | L3 → Populate → L4 (adds physics fields). L4 → wrap → L5 (adds routing). |
| `MD_Int_State` | `PH_Cont_State` | `RT_Contact_State` | L3 SSOT for contact config; L4 owns physics state; L5 owns runtime state (pair active, uzawa). |
| `MD_Int_Algo` | `PH_Cont_Algo` | `RT_Contact_Algo` | L3 algorithm type; L4 adds search_strategy procedure pointer; L5 adds enforcement/policy. |
| `MD_Int_Ctx` | `PH_Cont_Ctx` | `RT_Contact_Ctx` | L3 context; L4 adds local evaluation geometry; L5 adds hot-path scratch and buffer attachments. |
| `MD_Int_Surface_Desc` | `PH_Contact_Surface_Desc` | (embedded in `RT_Contact_Desc`) | Surface geometry passed through via Bridge pointer. |
| `MD_Int_Pair_Desc` | `PH_Contact_Pair_Desc` | `RT_Cont_PairDef` internal | Pair definition lifted through Populate. |

### 4.3 SIO Arg Types

| Arg Type | Layer | Purpose | Key Fields |
|----------|-------|---------|------------|
| `PH_Cont_Eval_Arg` | L4 | Unified eval | `desc`, `state`, `algo`, `ctx`, `gap`, `force`, `stiffness`, `status` |
| `PH_Cont_PenaltyForce_Arg` | L4 | Penalty force | `penetration`, `penalty_n`, `force_n` [OUT], `status` |
| `PH_Cont_PenaltyStiffness_Arg` | L4 | Penalty stiffness | `penalty_n`, `normal(3)`, `K_contact(:,:)` [OUT] |
| `PH_Cont_SearchPairs_Arg` | L4 | Search dispatch | `search_tolerance`, `candidates(:)` [OUT], `status` |
| `PH_Cont_SearchStrategy_Arg` | L4 | Search strategy | `algorithm`, `params`, `status` |
| `MD_IC_ContactAddK_Arg` | L3 Bridge | Add stiffness to triplet | `elem_id`, `K_local(:,:)`, `triplet_list` [INOUT] |
| `MD_IC_ContactAddForce_Arg` | L3 Bridge | Add force to triplet | `elem_id`, `F_local(:)`, `triplet_list` [INOUT] |
| `RT_Cont_Dispatch_Arg` | L5 | L5 dispatch bundle | `desc`, `state`, `algo`, `ctx`, `search_tolerance`, `current_time`, `contact_forces(:,:)` [ALLOC OUT], `status` |
| `RT_Cont_AugLag_In` | L5 | Uzawa outer iteration | `lambda_n(:)`, `gap(:)`, `rho_aug`, `tol_aug`, `status` |
| `RT_Cont_AugLag_Out` | L5 | Uzawa outer iteration | `lambda_trial(:)` [OUT], `converged` [OUT] |

### 4.4 Golden Line / Bridge Mechanism

- **Golden Line (Direct — Contact Solver)**: `RT_Cont_Solv` provides SIO interfaces `RT_Cont_Search`, `RT_Cont_ComputeForce`, `RT_Cont_Assemble` that dispatch directly to L4 kernels (`PH_ContSearch`, `PH_Contact_Compute_*`). This is the production hot path.
- **Bridge (Populate)**: `RT_Contact_Brg_FromL3` reads L3 Interaction Desc and populates `RT_Contact_Desc`. `RT_Contact_Brg_ToL4` creates L4 contact descriptors from L5 routing table.
- **Bridge (WriteBack)**: `RT_Contact_Brg_WriteBack` returns runtime contact state (forces, penetration, status) to L3 for solver convergence checking.
- **Augmented Lagrange (Uzawa)**: `RT_Cont_AugLagSolv` manages the Uzawa outer iteration at L5 — lambda trial/commit/rollback state machine with `RT_Contact_State%lambda_n` (committed) and `lambda_trial` (working).

---

## 5. P4: LoadBC Domain

### 5.1 Data Flow Chain

```
L3_MD LoadBC/
  | MD_LBC_Def.f90       ── MODULE: MD_LBC_Def  (AUTHORITY consolidated four-type)
  |   MD_Load_Desc             (load_id, load_family, magnitude, scale_factor, amplitude)
  |   MD_BC_Desc               (bc_id, bc_family, node_set_id, dof_start/end, magnitude)
  |   MD_Load_State            (accumulated, last_magnitude, work_done)
  |   MD_BC_State              (accumulated, last_value)
  |   MD_BC_Algo               (apply_mode 1=direct/2=penalty/3=Lagrange, penalty_factor)
  |   MD_LBC_Algo              (default_amp_type, ramp_mode, auto_scale)
  |   MD_LBC_Ctx               (current_load_id, current_bc_id, operation_type)
  |   MD_LoadBC_Domain         (loads(:), bcs(:), n_loads, n_bcs, algo, ctx)
  |
  | 8 LOAD_FAMILY constants, 6 BC_FAMILY constants
  |
  | [Populate] PH_LoadBC_NestedToFlat flattens L3→L4
  v
L4_PH LoadBC/
  | PH_LoadBC_Def.f90    ── MODULE: PH_LoadBC_Def  (AUTHORITY four-type)
  |   PH_LoadBC_Desc           (load_type, ndof, nn, dof_dir, value, amp_factor, pressure)
  |   PH_LoadBC_State          (loads_applied, bcs_applied, n_active_loads/bcs)
  |   PH_LoadBC_Algo           (stp_ctl: PH_Ldbc_Stp_Ctl_Algo, bc_method, penalty_param)
  |   PH_LoadBC_Ctx            (Fe(192), N_shape(27), normal(3), body_force(3), eps_th(6))
  |
  | PH_Ldbc_Aux_Def.f90  ── MODULE: PH_Ldbc_Aux_Def
  |   PH_Ldbc_Stp_Ctl_Algo     (bc_method, penalty_param, lagrange_tol, quad_order, ...)
  |
  | PH_LoadBC_Core.f90   ── MODULE: PH_LoadBC_Core
  |   PH_LoadBC_Concentrated_Force(Fe, node, dof, magnitude, status)
  |   PH_LoadBC_Distributed_Load(Fe, element, pressure, status)
  |   PH_LoadBC_Pressure_Load(Fe, pressure, normal, area, status)
  |   PH_LoadBC_Body_Force(Fe, density, g_vec, volume, status)
  |   PH_LoadBC_Apply_Dirichlet(K, F, dof, value, method, status)
  |
  | PH_Ldbc_Mgr.f90       ── MODULE: PH_Ldbc_Mgr
  |   PH_Ldbc_Ctx, BCM_Apply_Dense/Sparse/Penalty/Elimination/Lagrange
  |
  | PH_Ldbc_Brg.f90       ── MODULE: PH_Ldbc_Brg  (unified public API)
  |   PH_Ldbc_Apply (generic interface: dense/scalar)
  |   PH_Ldbc_Apply_Neumann_FromDesc
  |   PH_Ldbc_Apply_Penalty_CSR_FromDesc
  v
L5_RT LoadBC/
  | RT_LoadBC_Impl.f90   ── MODULE: RT_LoadBC_Impl
  |   RT_LoadBC_Init_Impl(desc, state, algo, ctx, status)
  |   RT_LoadBC_Update_Impl(desc, state, algo, ctx, status)
  |   RT_LoadBC_ApplyLoads_Impl(desc, state, algo, ctx, status)
  |   RT_LoadBC_ApplyBCs_Impl(desc, state, algo, ctx, status)
  |   RT_LoadBC_ComputeReactions_Impl(desc, state, algo, ctx, status)
  |   RT_LoadBC_CheckConvergence_Impl(desc, state, algo, ctx, status)
  |
  | RT_LoadBC_Brg.f90    ── MODULE: RT_LoadBC_Brg
  |   RT_LoadBC_Brg_FromL3(desc, l3_layer, status)
  |   RT_LoadBC_Brg_ToL4(desc, ph_layer, status)
  |   RT_LoadBC_Brg_WriteBack(state, l3_layer, status)
  |   RT_LoadBC_Brg_RouteLoadType(load_type, status)
  |
  | RT_LoadBC_ReactionForce.f90  ── MODULE: RT_LoadBC_ReactionForce
  |   RT_BC_Apply_Constraints(K, F, bc_desc, status)  — applies constraints to global system
  |   RT_BC_Compute_Reactions(K, U, F, reactions, status)
  |   RT_BC_Process_Element_Reactions(...)
  |
  | NOTE: RT_LoadBC_Def.f90 is referenced in CONTRACT.md but MISSING from file system.
  |       RT_LoadBC_Desc/State/Algo/Ctx types are USE'd but need a canonical _Def module.
  |       See L5_RT/LoadBC/CONTRACT.md for the declared type specification.
```

### 5.2 SIO Arg Types

| Arg Type | Layer | Module | Purpose |
|----------|-------|--------|---------|
| `PH_Ldbc_Init_Arg` | L4 | `PH_Load_Def` / `PH_Ldbc_Load_Def` | Load/BC domain init |
| `PH_Ldbc_SetGravity_Arg` | L4 | same | Gravity load config |
| `PH_Ldbc_ApplyLoads_Arg` | L4 | same | Apply all loads via bridge |
| `PH_Ldbc_AssembleCLoad_Arg` | L4 | `PH_Ldbc_Load_Mgr` | Concentrated load assembly |
| `PH_Ldbc_ApplyBody_*_Arg` | L4 | same | Body force application |
| `PH_Ldbc_ApplyConcentrated_*_Arg` | L4 | same | Concentrated force |
| `PH_Ldbc_ApplyDistributed_*_Arg` | L4 | same | Distributed load |
| `PH_Ldbc_ApplyPressure_*_Arg` | L4 | same | Pressure load |
| `PH_Ldbc_ApplyThermal_*_Arg` | L4 | same | Thermal load |
| `RT_BC_Apply_In` | L5 | `RT_LoadBC_ReactionForce` | BC application input |
| `RT_BC_Reaction_Out` | L5 | `RT_LoadBC_ReactionForce` | Reaction force output |

### 5.3 Key Procedures

| Layer | Procedure | Signature Skeleton |
|-------|-----------|-------------------|
| L3 | `LoadBC_Domain_Init` | `(domain, status)` |
| L3 | `LoadBC_Domain_AddLoad` | `(domain, load_desc, status)` |
| L3 | `LoadBC_Domain_AddBC` | `(domain, bc_desc, status)` |
| L4 | `PH_Ldbc_Apply` | `(desc, state, algo, ctx, K, F, status)` — generic bridge |
| L4 | `PH_LoadBC_Concentrated_Force` | `(Fe, node, dof, magnitude, status)` |
| L4 | `PH_LoadBC_Pressure_Load` | `(Fe, pressure, normal, area, status)` |
| L4 | `PH_LoadBC_Apply_Dirichlet` | `(K, F, dof, value, method, status)` |
| L4 | `PH_LoadBC_NestedToFlat` | `(md_layer, flat_arrays, status)` — L3→L4 flatten |
| L4 | `PH_LoadBC_FlatToNested` | `(flat_arrays, md_layer, status)` — L4→L3 writeback |
| L5 | `RT_LoadBC_ApplyLoads_Impl` | `(desc, state, algo, ctx, status)` |
| L5 | `RT_LoadBC_ApplyBCs_Impl` | `(desc, state, algo, ctx, K, F, status)` |
| L5 | `RT_BC_Apply_Constraints` | `(K, F, bc_desc, status)` — global system application |

### 5.4 Golden Line / Bridge Mechanism

- **Bridge (Populate)**: `PH_LoadBC_NestedToFlat` reads L3 `MD_LoadBC_Domain` (nested types with loads/bcs) and flattens into L4 flat arrays. `PH_LoadBC_FlatToNested` reverses for writeback.
- **Bridge (Apply)**: `PH_Ldbc_Brg` provides the unified `PH_Ldbc_Apply` generic interface with dispatch to dense/scalar/CSR variants.
- **L5 Implementation**: `RT_LoadBC_Impl` calls `PH_Ldbc_Brg` routines which in turn call `PH_LoadBC_Core` kernels. `RT_BC_Apply_Constraints` modifies the global K/F matrices at the solver level.
- **File gap**: `RT_LoadBC_Def.f90` (the AUTHORITY four-type module) is missing; must be created from the type specification in `L5_RT/LoadBC/CONTRACT.md`.

---

## 6. P5: Output Domain

### 6.1 Data Flow Chain

```
L3_MD Output/
  | MD_Out_Def.f90       ── MODULE: MD_Out_Def  (AUTHORITY, SIO-REFACTORED)
  |   OutDesc, OutSta, OutCtx       (base 3-type extending DescBase/StateBase/CtxBase)
  |   FldOutDesc, HistOutDesc       (field/history output request descriptors)
  |   MD_Out_Desc = TYPE(OutDesc), POINTER :: inner    (canonical wrapper)
  |   MD_Out_State = TYPE(OutSta), POINTER :: inner
  |   MD_Out_Ctx   = TYPE(OutCtx), POINTER :: inner
  |   MD_Out_Arg                       (desc, state, ctx, field_data:, n_frames_written, status)
  |   OutVarDesc, FldOutReq, HistOutReq  (variable registry types + request types)
  |   OutField, OutFrame, RT_StepHistCfg (frame and history types)
  |   77+ constants for location/frequency/region/variable/format/rank
  |
  | MD_Out_API.f90       ── MODULE: MD_Out_API  (domain facade)
  |   MD_Output_Domain TBP: Init, Finalize, AddRequest, GetRequest, IsOutputDue, WriteBack
  |
  | MD_Out_Parse.f90     ── MODULE: MD_Out_Parse  (keyword parsing)
  | MD_Out_VarReg.f90    ── MODULE: MD_Out_VarReg  (variable registry)
  |
  | [Populate] MD_Out_Def contains 25+ RT_Out_* procedures mixed in (legacy cross-layer)
  v
L4_PH Output/            ── Thin layer: physics transforms only
  | PH_Out_Def.f90       ── MODULE: PH_Out_Def  (AUTHORITY four-type)
  |   PH_Out_Desc             (output_format, n_field_vars, n_history_vars, write_frequency)
  |   PH_Out_State            (last_write_step, last_write_inc, frame_count, buffer_dirty)
  |   PH_Out_Algo             (transform_method, interpolation_order, extrapolation_limit)
  |   PH_Out_Ctx              (current_frame_id, current_step_id, current_inc_id, is_triggered)
  |   PH_Out_Arg              (desc, state, algo, ctx, n_values, buffer(:), status)
  |
  | PH_Out_Core.f90      ── MODULE: PH_Out_Core  (core implementation)
  |   PH_Output_TransformCoords(global_coords, rotation_matrix, local_coords, status)
  |   PH_Output_TransformTensor(tensor_voigt, tensor_full, direction, status)
  |   PH_Output_InterpolateField(nodal_values, shape_funcs, interpolated_value)
  |   PH_Output_GetScalar(field_data, component_idx, scalar_value, status)
  |   PH_Output_GetVector(field_data, vector(3), status)
  |   PH_Output_GetTensor(field_data, tensor(3,3) or tensor(6), status)
  |
  | PH_Out_Brg.f90       ── MODULE: PH_Out_Brg  (bridge API)
  v
L5_RT Output/
  | RT_Out_Def.f90       ── MODULE: RT_Out_Def  (AUTHORITY four-type + Args)
  |   RT_Out_Desc              (runtime_id, output_label, md_req ptrs, output_format, is_active)
  |   RT_Out_FieldState        (n_frames_written/current_step/max, time_last/next_due)
  |   RT_Out_HistState         (n_points_written, data_buffer, buffer_active)
  |   RT_Out_Algo              (alias wrapping RT_Out main type with stp_ctl + itr_algo)
  |   RT_Out_Ctx               (step_id, incr_id, iter_id, time, force flags)
  |   RT_Out_Init_Arg          (desc, field_state, hist_state, ctx, output_type, max_buffer, status)
  |   RT_Out_Write_Arg         (desc, field_state, hist_state, ctx, field_values, hist_values, status)
  |   RT_Out_Frame             (full frame data: coords, displ, stress, strain, energy, statev)
  |   RT_Out_Buffer            (capacity, size, head, tail, is_full, needs_flush)
  |
  | RT_Out_Aux_Def.f90   ── MODULE: RT_Out_Aux_Def
  |   RT_Out_Stp_Ctl_Algo      (field_freq_incr, field_freq_time, trigger_type, ...)
  |   RT_Out_Itr_Algo          (use_buffer, buffer_size, flush_frequency, compress, ...)
  |
  | RT_Out_Mgr.f90       ── MODULE: RT_Out_Mgr  (GOLDEN-LINE production manager)
  |   RT_Out_Mgr_Init, RT_Out_Mgr_WriteField, RT_Out_Mgr_WriteHistory
  |
  | RT_Out_Proc.f90      ── MODULE: RT_Out_Proc  (SIO procedure unit)
  |   5 abstract interfaces: Init/Collect/Write/CheckFreq/Finalize each with _In/_Out structures
  |
  | RT_Out_Brg.f90       ── MODULE: RT_Out_Brg  (bridge: FromL3/ToL4/CollectResults)
  | RT_Out_Impl.f90      ── MODULE: RT_Out_Impl  (implementation logic)
  | RT_Out_Restart.f90   ── MODULE: RT_OutRestart  (restart save/restore)
  | RT_Writer_HDF5.f90   ── MODULE: RT_WriterHDF5  (HDF5 writer)
  | RT_Writer_ODB.f90    ── MODULE: RT_WriterODB  (ODB writer)

L6_AP Output/             ── Post-processing layer
  | AP_Out_Domain.f90, AP_Out_Def.f90, AP_Out_Core.f90, AP_Out_Fmt.f90
  | AP_Out_PostProcDataAnal.f90, AP_Out_PostProcVisual.f90
  | AP_OutRT_Brg.f90  ── MODULE: AP_OutRT_Brg  (L5→L6 bridge)
```

### 6.2 Cross-Layer Type Wrapping

| L3 Type | L4 Type | L5 Type | Wrapping Notes |
|---------|---------|---------|----------------|
| `OutDesc` → `MD_Out_Desc` | `PH_Out_Desc` | `RT_Out_Desc` | L3 SSOT for output requests. L4 adds format/transform config. L5 adds runtime state (pointers to L3 registry). |
| `OutSta` → `MD_Out_State` | `PH_Out_State` | `RT_Out_FieldState` + `RT_Out_HistState` | L5 splits into field/history state for detailed tracking. |
| (no L3 Algo) | `PH_Out_Algo` | `RT_Out_Algo` (alias) | Output has no L3 Algo. L4 adds transform strategy. L5 wraps with step/iteration control. |
| `OutCtx` → `MD_Out_Ctx` | `PH_Out_Ctx` | `RT_Out_Ctx` | L5 context is most detailed with frame/time/trigger state. |

### 6.3 Key Procedures

| Layer | Procedure | Signature Skeleton |
|-------|-----------|-------------------|
| L3 | `MD_Output_Domain%AddRequest` | `(this, request, status)` |
| L3 | `MD_Output_Domain%IsOutputDue` | `(this, step, incr, time, due) -> LOGICAL` |
| L4 | `PH_Output_TransformCoords` | `(coords_g, rot_mat, coords_l, status)` |
| L4 | `PH_Output_TransformTensor` | `(tensor_v, tensor_f, direction, status)` |
| L4 | `PH_Output_InterpolateField` | `(nodal_vals, N, ip_val, status)` |
| L5 | `RT_Out_Mgr_Init` | `(desc, field_state, hist_state, ctx, status)` |
| L5 | `RT_Out_Mgr_WriteField` | `(ctx, frame_data, status)` |
| L5 | `RT_Out_Mgr_WriteHistory` | `(ctx, hist_data, status)` |
| L5 | `RT_Out_Brg_FromL3` | `(rt_desc, l3_layer, status)` |
| L5 | `RT_Out_Brg_ToL4` | `(rt_desc, ph_layer, status)` |
| L5 | `RT_Out_Brg_CollectResults` | `(ph_layer, field_data, hist_data, status)` |

### 6.4 Golden Line / Bridge Mechanism

- **Golden Line (Mgr)**: `RT_Out_Mgr` is the production manager — it checks trigger conditions (`RT_Out_Ctx%is_triggered`), collects field/history data from L4 via `PH_Output_*` transforms, and writes to file via `RT_Writer_HDF5` / `RT_Writer_ODB`.
- **Bridge (Populate)**: `RT_Out_Brg_FromL3` reads L3 `MD_Output_Domain` (output requests, variable registry) and populates `RT_Out_Desc`. `RT_Out_Brg_ToL4` creates L4 output descriptors for coordinate transform setups.
- **Physics transforms at L4**: Pure computation (no I/O) — coordinate transform, tensor rotation, IP-to-node interpolation, Voigt notation conversion. These are the only L4 responsibilities for Output.
- **L5 owns all I/O and triggering**: File open/close, buffer management, format selection, frequency checks, parallel I/O coordination.
- **L6 handles post-processing**: Visualization, data analysis, report generation — downstream of the simulation.

---

## 7. P6: WriteBack Domain

### 7.1 Data Flow Chain

```
L3_MD WriteBack/
  | MD_WB_Def.f90       ── MODULE: MD_WB_Def  (AUTHORITY 3-type: Desc/State/Ctx, NO Algo)
  |   MD_WriteBack_Entry        (field_path, domain_name, field_name, domain_id)
  |   MD_WriteBack_Target       (domain_id, entity_idx, field_slot)
  |   MD_WBMapEntry             (source_field_id, target_field_id, map_type)
  |   MD_WriteBack_Desc         (n_maps, maps(128))
  |   MD_WriteBack_State        (active, n_completed, n_failed, current_step)
  |   MD_WriteBack_Ctx          (step_idx, incr_idx, in_progress)
  |   11 domain ID constants (STEP=1..SECTION=11)
  |   MD_WB_MAX_MAPS = 128
  |
  | MD_WB_Core.f90      ── MODULE: MD_WB_Core
  |   Init, Finalize, Register_Map, Get_Map, Get_Count, Validate, Execute
  |
  | MD_WB_Brg.f90       ── MODULE: MD_WB_Brg  (L5→L3 dispatch bridge)
  |   MD_WB_SetContainer, WB_Guard + domain dispatch:
  |     MD_WB_Step, MD_WB_Amplitude, MD_WB_LoadBC, MD_WB_Mesh
  |     MD_WB_Mesh_NodePos, MD_WB_Mesh_NodeDisp, MD_WB_Mesh_NodeVel, MD_WB_Mesh_NodeAcc
  |     MD_WB_Mesh_ElemStress, MD_WB_Model, MD_WB_Interaction, MD_WB_Output
  |
  | [Populate] via PH_WB_Brg
  v
L4_PH WriteBack/          ── Thin layer: format preparation
  | PH_WB_Def.f90       ── MODULE: PH_WB_Def  (AUTHORITY four-type + Arg)
  |   PH_WB_Desc              (write_disp=T, write_vel=F, write_stress=T, output_freq=1)
  |   PH_WB_State             (total_nodes_written, total_elems_written, disp_buffer, stress_buffer)
  |   PH_WB_Algo              (format_id, validate_checksum, compress_buffer, compression_tol)
  |   PH_WB_Ctx               (current_step_id, current_inc_id, buffer_head, buffer_tail)
  |   PH_WB_Arg               (desc, state, algo, ctx, n_values, buffer(:), status)
  |
  | PH_WB_Core.f90      ── MODULE: PH_WB_Core  (format preparation engine)
  v
L5_RT WriteBack/
  | RT_WB_Def.f90       ── MODULE: RT_WB_Def  (AUTHORITY four-type + sub-Algo)
  |   RT_WB_Desc              (runtime_id, wb_label, write_frequency, 7 output flags, scope)
  |   RT_WB_ProgressState     (last_write_step/incr, total_writes, n_nodes/elements_written)
  |   RT_WB_BufferState       (node/elem/gp_buffer_size, buffer_needs_flush, flush_threshold)
  |   RT_WB_State             (TYPE(RT_WB_ProgressState) :: progress) — canonical wrapper
  |   RT_WB_Algo              (stp_ctl + itr_algo + 12 legacy flat fields)
  |   RT_WB_Ctx               (u/v/a/stress/strain/rf_buffer ptrs, current_elem/gp, buffer_needs_flush)
  |   RT_WB_TransformCtx      (rot_matrix, inv_rot_matrix, coord_sys_type, transformation_active)
  |   5 target constants, 6 field constants, 3 write frequency constants
  |
  | RT_WB_Aux_Def.f90   ── MODULE: RT_WB_Aux_Def
  |   RT_WB_Stp_Ctl_Algo      (write_trigger, trigger_at_step_end, checkpoint, validate, suppress)
  |   RT_WB_Itr_Algo          (use_node/elem_buffering, buffer_capacity, compress, audit)
  |
  | RT_WB_Domain.f90   ── MODULE: RT_WB_Domain  (GOLDEN-LINE)
  |   RT_WriteBack_Domain TBP:
  |     WriteState, SaveCheckpoint, LoadCheckpoint, RollbackToCheckpoint
  |     ValidateWriteBack, AuditWriteBack
  |   Direct subroutines: NodePos, NodeDisp, ElemStress, ElemStrain, GPStateVar
  |     (single and Batch variants)
  |
  | RT_WB_Proc.f90      ── MODULE: RT_WB_Proc  (SIO procedure unit)
  |   RT_WB_Init_Arg          (desc, ctx, output_type, max_buffer, status)
  |   RT_WB_NodePos_Arg       (node_id, coords(3), status)
  |   RT_WB_NodeDisp_Arg      (node_id, displacement(3), status)
  |   RT_WB_ElemStress_Arg    (elem_id, gp_stress(:,:), status)
  |   RT_WB_Checkpoint_Arg    (checkpoint_data, status)
  |   RT_WB_Write_Arg         (field_data, n_saved, bytes_written, status)
  |
  | RT_WB_Brg.f90      ── MODULE: RT_WB_Brg  (bridge: FromL5/ToL4/ToL3)
  | RT_WB_Impl.f90      ── MODULE: RT_WB_Impl  (implementation logic)
  | RT_WB_Core.f90      ── MODULE: RT_WB_Core  (LEGACY facade)
```

### 7.2 Key Procedures

| Layer | Procedure | Signature Skeleton |
|-------|-----------|-------------------|
| L3 | `MD_WB_Core_Register_Map` | `(map_entry, status)` |
| L3 | `MD_WB_Core_Execute` | `(writeback_id, src_data, dst_data, status)` |
| L4 | `PH_WriteBack_NodeDisp` | `(ph_state, node_id, disp(3), status)` |
| L4 | `PH_WriteBack_ElemStress` | `(ph_state, elem_id, gp_stress(:,:), status)` |
| L5 | `RT_WriteBack_Domain%WriteState` | `(this, ctx, status)` |
| L5 | `RT_WriteBack_Domain%SaveCheckpoint` | `(this, checkpoint_id, status)` |
| L5 | `RT_WriteBack_Domain%RollbackToCheckpoint` | `(this, checkpoint_id, status)` |
| L5 | `RT_WriteBack_NodePos` | `(desc, state, algo, ctx, node_id, coords, status)` |
| L5 | `RT_WriteBack_ElemStress_Batch` | `(desc, state, algo, ctx, elem_ids(:), stress_data(:,:,:), status)` |

### 7.3 Golden Line / Bridge Mechanism

- **Golden Line (Domain)**: `RT_WB_Domain` provides the production WriteBack domain with `RT_WriteBack_Domain` TBP. Direct subroutines like `RT_WriteBack_NodePos` and `RT_WriteBack_ElemStress` are the hot path for field-by-field writeback during the analysis loop.
- **Bridge (Dispatch)**: `RT_WB_Brg_FromL5` routes WriteBack decisions to L4 `PH_WB_Core` format preparation and then to L3 `MD_WB_Brg` which dispatches to domain-specific writeback procedures (`MD_WB_Mesh_NodeDisp`, `MD_WB_Mesh_ElemStress`, etc.).
- **Checkpoint/Rollback**: `RT_WriteBack_Domain` supports save/load/rollback of writeback checkpoints, enabling cutback recovery in the nonlinear solver loop.

---

## 8. H1: Analysis/Solver/Step Domain (Half-Pillar)

### 8.1 Data Flow Chain

```
L3_MD Analysis/
  | Solver/
  |   MD_Solv_Def.f90   ── MODULE: MD_Solv_Def
  |     MD_Solver_Desc        (cfg: config_id; itr: max_iter, tols, line_search; stp: stabilize)
  |     MD_Solver_Algo        (itr: iter + cutback params)
  |     MD_Solver_State       (stp: cfg_state; itr: convergence_state)
  |     MD_Solver_Ctx         (itr: iter_context; work_vec, rhs pointers)
  |     MD_Solv_Cfg_Init_Desc, MD_Solv_Itr_Com_Desc, MD_Solv_Stp_Ctl_Desc
  |
  |   MD_Solv_Mgr.f90   ── MODULE: MD_Solv_Mgr
  |     MD_Solver_Domain       (configs(:), n_configs, TBP: Init/AddConfig/GetConfig)
  |     MD_Solver_AddConfig_Arg    (desc, config_id [OUT], status)
  |     MD_Solver_GetConfig_Arg    (config_id, desc [OUT], status)
  |     MD_Solver_GetConfigForStep_Arg (step_idx, desc [OUT], status)
  |
  |   MD_Solv_Sync.f90   ── MODULE: MD_Solv_Sync
  |     MD_Solver_SyncFromStep(md_layer, status)  — MAIN API, no *_Arg wrapper
  |
  | Step/
  |   MD_Step_Def.f90    ── MODULE: MD_Step_Def
  |     MD_Step_State        (inc: time/increment; stp: active/complete/converged)
  |     MD_Step_Ctx          (inc: step_time, total_time, dt; itr: iteration, Newmark params)
  |
  |   MD_Step_Mgr.f90    ── MODULE: MD_Step_Mgr
  |     MD_Step_Desc         (name, step_number, procedure, nlgeom, time_period, loads, bcs, solver)
  |     StepAlgo             (inc_ctrl: UF_IncrementControl; sol_ctrl; dyn: UF_DynamicParams)
  |     MD_Step_Domain       (steps(:), n_steps, current_step_idx, current_incr_idx, total_time)
  |     MD_Step_Get_Arg, MD_Step_GetByName_Arg, MD_Step_WriteBack_Arg
  |
  |   MD_Step_Proc.f90   ── MODULE: MD_Step_Proc  (~2000 lines)
  |     PROC_* enums, UF_SolutionControl, UF_IncrementControl, UF_DynamicParams, UF_RiksControl
  |
  |   MD_Step_Sync.f90   ── MODULE: MD_Step_Sync
  |     MD_Step_SyncFromLegacy(model_def, md_layer, status)

  --- L3 config flows to L5 directly (half-pillar: no L4 PH for Solver/Step) ---

L5_RT Solver/
  | RT_Solv_Def.f90     ── MODULE: RT_Solv_Def  (AUTHORITY four-type)
  |   RT_Solv_Cfg_Desc       (runtime_id, solver_label, md_linear/md_nr POINTERS, n_dofs)
  |   RT_Solv_Desc           (cfg + itr cache)
  |   RT_Solv_NRState        (stp: cutback count; itr: NR iteration state, flags, norms)
  |   RT_Solv_LinearState    (stp: factorization; itr: Krylov iteration)
  |   RT_Solv_Algo           (nr_max_iter, cutbacks, tangent_strategy, linear solver method, tols)
  |   RT_Solv_Ctx            (stp: step/incr/time context; itr: iteration context)
  |   RT_Solv_ConvergenceCtx (convergence evaluation with norms)
  |   RT_Solv_Solve_Arg      (desc, state, algo, K, F, U, tolerances, convergence)
  |
  | RT_Solv_Proc.f90    ── MODULE: RT_Solv_Proc  (SIO interfaces)
  |   RT_Solv_Init_In/Out, RT_Solv_Equilibrium_In/Out, RT_Solv_Linear_In/Out
  |   RT_Solv_Convergence_In/Out, RT_Solv_Cutback_In/Out + abstract interfaces
  |
  | RT_Solv_Mgr.f90     ── MODULE: RT_Solv_Mgr  (production, ~7707 lines)
  |   RT_SolverSys_SolveNonlin, UF_NewtonRaphson, RT_SolIterMgr_RunAll
  |
  | RT_Solv_Nonlin.f90  ── MODULE: ???  (golden-line nonlinear solver)
  | RT_Solv_Lin.f90, RT_Solv_Sparse.f90, RT_Solv_TimeInt.f90
  | RT_Asm_DofMapUtils.f90
  |
  | RT_Solv_Brg.f90     ── MODULE: RT_Solv_Brg  (bridge to L2_NM)
  |   RT_ConvertCSR_FromNumCore, RT_ConvertCSR_ToNumCore
  |   RT_LinearSolver_Direct/Iterative/Unified/AGMG/SparsePak
  |   RT_Solv_Bridge_Unified, RT_Solv_Bridge_Opt

L5_RT StepDriver/
  | RT_Step_Def.f90     ── MODULE: RT_Step_Def  (AUTHORITY four-type + state machine constants)
  |   RT_StepDriver_Desc      (step_idx, step_id, category, solver_config_id, time_cfg, name)
  |   RT_StepDriver_State     (current_step_idx, increment, iteration, time, load_factor, converged)
  |   RT_StepDriver_Algo      (tol + strat)
  |   RT_Step_Desc/State/Algo/Ctx (sub-level four-type for inc/itr management)
  |   RT_Step_Drive_Arg       (desc, state, algo, ctx, step_time, n_increments, results)
  |   RT_Step_Incr_Arg        (desc, state, ctx, time_increment, incr_number, incr results)
  |   Step machine: RT_STEP_IDLE->RUNNING->CONVERGED->CUTBACK->FAILED->COMPLETED
  |   Increment machine: RT_INC_* (6 states)
  |   Iteration machine: RT_ITER_* (8 states)
  |
  | RT_Step_Exec.f90    ── MODULE: ???  (golden-line step execution)
  | RT_Step_NR_Core.f90 ── MODULE: ???  (NR core step driver)
  | RT_Step_Impl.f90    ── MODULE: ???  (implementation)
  |
  | RT_Step_Brg.f90     ── MODULE: RT_Step_Brg
  |   RT_StepDriver_Run   — master step execution with OMP parallel element compute,
  |                          assembly via RT_Asm_AddElemStiff_Structured,
  |                          solve via RT_Solv_Bridge_Unified
```

### 8.2 Key Procedures

| Layer | Procedure | Signature Skeleton |
|-------|-----------|-------------------|
| L3 | `MD_Solver_SyncFromStep` | `(md_layer, status)` — MAIN API, no *_Arg |
| L3 | `MD_Solver_Domain%AddConfig` | `(this, desc, status)` |
| L3 | `MD_Step_Domain%Advance` | `(this, status)` |
| L5 | `RT_StepDriver_Run` | `(desc, state, algo, ctx, status)` — master timeline |
| L5 | `RT_SolverSys_SolveNonlin` | `(desc, state, algo, ctx, K, F, U, status)` |
| L5 | `UF_NewtonRaphson` | `(K, F, U, params, status)` — production NR loop |
| L5 | `RT_SolIterMgr_RunAll` | `(solver_mgr, step_ctx, status)` |

### 8.3 Bridge Mechanism

- **L3→L5 Bridge**: `MD_Solver_SyncFromStep` reads step control from `MD_Step_Domain` (via `UF_SolutionControl`) and populates `MD_Solver_Domain` configs. L5 reads `MD_Solver_Domain` via `MD_Solver_Brg_GetConfigForStep`.
- **L5→L2 Bridge**: `RT_Solv_Brg` converts CSR matrices to/from the L2_NM numerical solver layer format (`RT_ConvertCSR_FromNumCore`, `RT_ConvertCSR_ToNumCore`), dispatches to direct/iterative linear solvers (MUMPS, AGMG, SparsePak), and maps results back.
- **Step→Assembly Integration**: `RT_Step_Brg%RT_StepDriver_Run` orchestrates the full step loop — increment advance, element evaluation (via `PH_Elem_Compute`), global assembly (via `RT_Asm_AddElemStiff_Structured`), system solve (via `RT_Solv_Bridge_Unified`), convergence check, and cutback management.

---

## 9. H2: Section Domain (Half-Pillar)

### 9.1 Data Flow Chain

```
L3_MD Section/            ── SSOT for all section data
  | MD_Sect_Def.f90      ── MODULE: MD_Sect_Def  (AUTHORITY full four-type)
  |   MD_Sect_Desc           (section_id, section_name, mat_id, mat_desc PTR,
  |                           thickness, orientation, offset, nlayer, integ_npts,
  |                           integ_rule, section_family, section_type, area)
  |   MD_Sect_State          (active_sections, total_sections, total_section_area)
  |   MD_Sect_Algo           (default_integration_rule)
  |   MD_Sect_Ctx            (current_section_idx)
  |   MD_Sect_Registry       (sections(:), nsections, TBP: Init/AddSection/FindByName/...)
  |   MD_Sect_Domain         (desc_array(:), n_sections, TBP: Init/Add/Get/GetSummary)
  |   5 SIO Arg types: MD_Sect_Add/Validate/GetSummary/Get/GetByName_Arg
  |   9 family constants (SOLID=1..CONNECTOR=9)
  |   17 type code constants (SOLID_3D=1..BEAM_GENERAL=17)
  |
  | MD_Sect_Compat.f90   ── MODULE: MD_Sect_Compat
  |   M-S-E orthogonal compatibility matrices: 9x11 (Section×Material), 9x12 (Section×Element)
  |
  | MD_Sect_Brg.f90      ── MODULE: MD_Sect_Brg  (L3→L4 validation + stress state derivation)
  |
  | [Populate] Section data embedded into PH_Elem_* via PH_Elem Populate path
  | L4_PH has NO independent Section directory (方案B: Section is L3-only SSOT)

L5_RT Section/            ── Algo-only (Desc/State/Ctx delegated to L3)
  | RT_Sect_Def.f90      ── MODULE: RT_Sect_Def
  |   RT_Sect_Algo           (stp_ctl: RT_Sect_Stp_Ctl_Algo)
  |
  | RT_Sect_Aux_Def.f90  ── MODULE: RT_Sect_Aux_Def
  |   RT_Sect_Stp_Ctl_Algo  (compat_check_mode: STRICT/RELAXED/SKIP,
  |                          validate_on_populate, integration_rule_override,
  |                          allow_integration_conflict, allow_missing_material,
  |                          missing_section_policy: ERROR/DEFAULT/SKIP,
  |                          section_cache_enabled, force_repopulate, suppress_compat_check)

  | [Consumed by] RT_Elem_Sect — Element domain at L5 reads section config from L3 via Bridge
```

### 9.2 Key Procedures

| Layer | Procedure | Signature Skeleton |
|-------|-----------|-------------------|
| L3 | `MD_Sect_Domain%Add` | `(this, section_desc, status)` |
| L3 | `MD_Sect_Domain%GetByName` | `(this, name, desc [OUT], found [OUT], status)` |
| L3 | `MD_Sect_Desc%Validate` | `(this, status)` |
| L3 | `MD_Sect_Brg_ToElem` | `(sect_desc, elem_desc, status)` — embed section into element desc |
| L5 | `RT_Sect_Stp_Ctl_Algo%Init` | `(this, compat_mode, validate_flag, status)` |

### 9.3 Wrapping / Delegation Pattern

- **L3 SSOT**: All section geometry, material association, integration rule, and orientation data lives at L3 only.
- **L4 Embedding**: Section parameters are embedded into `PH_Elem_*` types during Populate (`MD_Sect_Brg_ToElem`). L4_PH has no separate Section directory.
- **L5 Algo-only**: L5 holds only the section algorithm policy (`RT_Sect_Stp_Ctl_Algo`) — how to handle compatibility checks, missing sections, integration rule conflicts, and caching. The actual section data is accessed from L3 via pointer/reference through the Element domain Bridge.
- **Consumption path**: `RT_Elem_Sect` and `RT_Elem_Dispatch_Run` access section data by reading L3 `MD_Sect_Desc` via the pre-populated Bridge pointers in `RT_Elem_Desc`.

---

## 10. S1-S8: Layer-Only Domains

### 10.1 Overview

The layer-only (S-series) domains exist primarily in one or two layers. They provide supporting infrastructure for the P-domain pillars.

| Code | Domain | Layer(s) | File Count | Four-Type? |
|------|--------|----------|------------|------------|
| S1 | Assembly | L3_MD + L5_RT | ~25 | Yes (both layers) |
| S2 | Mesh | L3_MD (L5 thin) | ~45 | Partial (Desc/State) |
| S3 | Bridge | All 6 layers | ~42 | Partial (at L3, 11 ctx types at L5) |
| S4 | Model | L3_MD | ~22 | Yes (full four-type) |
| S5 | KeyWord | L3_MD | ~18 | Yes (full four-type) |
| S6 | Field | L3_MD + L4_PH | ~11 | Yes (both layers) |
| S7 | Constraint | L3_MD + L4_PH | ~20 | Yes (L3 only) |
| S8 | Part | L3_MD | ~8 | Partial (Desc/State only) |

### 10.2 S1: Assembly Domain

```
L3_MD Assembly/           ── Model assembly (instance, set, constraint, interaction containers)
  | MD_Asm_Mgr.f90       ── MODULE: MD_Asm_Mgr
  |   MD_Assembly_Domain     (instances(:), node_sets(:), elem_sets(:), surfaces(:),
  |                           MD_ConstraintUnion, MD_InteractionUnion,
  |                           MD_Asm_Algo: tie_tol, max_iters, mpc_penalty;
  |                           MD_Asm_State: active_constraints, violations;
  |                           MD_Asm_Ctx: current_inst, transform_cache)
  |   19+ TBP: Init/Finalize/AddInstance/AddNodeSet/AddElemSet/AddSurface/AddConstraint/...
  |
  | MD_Asm_Inst.f90      ── MODULE: MD_Asm_Inst
  |   UF_InstanceDef         (part_ref, translation, rotation via Rodrigues, node/elem/dof offsets)
  |
  | L3→L5 flow:
  |   Populate via Bridge_L5/MD_AssemRT_Brg.f90

L5_RT Assembly/           ── Runtime sparse assembly engine
  | RT_Asm_Def.f90       ── MODULE: RT_Asm_Def  (four-type + Arg)
  |   RT_Asm_Desc            (assemble flags, elem/node ranges, constrained_dofs)
  |   RT_Asm_State           (current_elem, assembled_elements, K/M/C/f matrix POINTERs)
  |   RT_Asm_Algo            (assembly_method, sparse_format, parallel_strategy)
  |   RT_Asm_Ctx             (fixed-size elem stack: ke(24,24), me, ce, fe, gp data, shape funcs)
  |   RT_Asm_Arg             (dof_map, n_total_eq, n_elem_assembled, bc_dofs/values)
  |
  | RT_Asm_Domain.f90   ── MODULE: RT_Asm_Domain
  |   RT_Assembly_Domain     (RT_Assembly_State: CSR rowPtr/colIdx/values, F_global, eqNum;
  |                           RT_Assembly_Ctrl: renum RCM/AMD/METIS, mode SERIAL/OMP/MPI)
  |
  | RT_Asm_Solv.f90     ── Production assembly hub
  | RT_Asm_Global.f90   ── Unified sparse assembly with legacy CSR_Matrix
  | RT_Asm_DofMap.f90   ── DOF mapping
  | RT_Asm_Shape*.f90   ── Shape function files (Beam/Shell/Membrane/Mech2D/ScalarField)
  |
  | Flow: RT_Step_Brg calls RT_Asm_BuildGlobSys_Sparse which:
  |   1. For each element: calls PH_Elem_Compute_Ke via RT_Elem_Dispatch_Run
  |   2. Scatters elem_ke into global K (RT_Asm_ScatterElemToGlobal)
  |   3. Applies BCs (via RT_LoadBC_Brg)
  |   4. Calls solver (via RT_Solv_Bridge_Unified)
```

### 10.3 S2: Mesh Domain

```
L3_MD Mesh/               ── Single source of truth for mesh geometry and topology
  | MD_Mesh_Def.f90      ── MODULE: MD_Mesh_Def
  |   MD_Mesh_Desc           (n_nodes, n_elements, ndim, coords, conn, elem_type, adjacency CSR)
  |   MD_Mesh_State          (loaded flags, modification_gen, kinematic flags)
  |   MD_Mesh_NodeDesc, MD_Mesh_ElemDesc, MD_Mesh_FaceDesc, MD_Mesh_NodeSetEntry
  |   MD_Mesh_Get_Node_Arg
  |
  | MD_Mesh_NodeDef.f90  ── MODULE: MD_Mesh_NodeDef
  |   MD_Node_Type (DescBase ext): id, coords, dof_map, bc flags/values, loads, temperature, mass
  |   MD_Node_State (StateBase ext): displacement/velocity/acceleration, reaction, history + Newmark Update
  |
  | MD_Mesh_Domain.f90  ── MODULE: MD_Mesh_Domain
  |   MD_Mesh_Domain         (desc, node_desc, elem_desc, global_num dof map,
  |                           state, node_state, elem_state, algo, raw_data)
  |   TBP: Init/GetNodeCoords/GetElemConnect/GetDofMap/WriteBack_NodePos/Disp/Vel/Acc
  |
  | Elem/           (see P2 Element — MD_Elem_Def, 12 family subdirs)

L5_RT Element/Mesh/       ── Thin runtime mesh access layer
  | RT_Mesh_Def.f90, RT_Mesh_Impl.f90, RT_Mesh_Proc.f90, RT_Mesh_Sys.f90
```

### 10.4 S3: Bridge Domain

```
Cross-layer bridge orchestration — 42 files across all 6 layers.

  | L3_MD Bridge/:
  |   MD_Brg_Def.f90          (MD_Brg_Desc/State — basic 2-type)
  |   Bridge_L4/ (6 files):   MatLibPH_Brg, ElemPH_Brg, LBCPH_Brg, GeomPH_Brg,
  |                           ConstraintPH_Brg, ContPH_Brg
  |   Bridge_L5/ (14 files):  Mesh_Brg, Model_Brg, AssemRT_Brg, ElemRT_Brg, ModelRT_Brg,
  |                           LBCRT_Brg, KWRT_Brg, ContRT_Brg, Out_Brg, Int_Brg,
  |                           UIRT_Brg, UniFldRT_Brg, Int_ContactArgs  (6 Arg types)
  |
  | L4_PH Bridge/:
  |   PH_Brg_L3.f90, PH_Brg_L2.f90, PH_Brg_Def.f90, PH_Brg_Domain.f90
  |   WriteBack/ (3 files), Output/ (2 files)
  |
  | L5_RT Bridge/:
  |   RT_Brg_Def.f90:         11 bridge context types:
  |     RT_Mat_Bridge_Ctx, RT_Elem_Bridge_Ctx, RT_Load_Bridge_Ctx,
  |     RT_BC_Bridge_Ctx, RT_Contact_Bridge_Ctx, RT_Fric_Bridge_Ctx,
  |     RT_Constr_Bridge_Ctx, RT_Field_Bridge_Ctx, RT_Analy_Bridge_Ctx,
  |     RT_Mesh_Bridge_Ctx, RT_Step_Bridge_Ctx
  |     Each with aux (stp/lcl) sub-types + deprecated flat mirror fields
  |   RT_Brg_Mgr.f90, Shared/RT_Shared_Def.f90
  |
  | L2_NM Bridge/:        NM_DirMUMPS_Brg, NM_DirSolvDispatcher_Brg, etc.
  | L6_AP Bridge/:        AP_Brg_L3, AP_Brg_L4, AP_Brg_L5, AP_Mat_Brg, AP_StorageCfg_Brg
```

### 10.5 S4: Model Domain

```
L3_MD Model/              ── Top-level model container (22 files)
  | MD_Model_Def.f90     ── MODULE: MD_Model_Def  (four-type)
  |   MD_Model_Desc          (name, ndim, part_ids(256), step_ids(100))
  |   MD_Model_State         (parsed, populated, validated flags, warnings, errors)
  |   MD_Model_Algo          (renumber_strategy, partition_method, auto_contact)
  |   MD_Model_Ctx           (parse_unit, source_file, strict_mode)
  |
  | MD_Model_Core.f90    ── MODULE: MD_Model_Core
  |   Init, Finalize, SetName, GetNDim, RegisterPart, RegisterStep, Validate
  |
  | MD_Base_ObjModel.f90 ── MODULE: ???  (~4358 lines foundation)
  |   Abstract bases: BaseDesc/Algo/Ctx/State → DescBase/AlgoBase/CtxBase/StateBase
  |   Serialization: TreeSerializer/Deserializer
  |   Model system: UF_Model, UF_Part, UF_Instance, UF_Assem
  |   DOF system: DofMap, DofLabMap, DofSys
  |   Field system: UF_FldDesc, UF_FldHdl, UF_FldSys, UF_UFField
```

### 10.6 S5: KeyWord Domain

```
L3_MD KeyWord/            ── Keyword parsing and AST management (18 files)
  | MD_KeyWord_Def.f90   ── MODULE: MD_KeyWord_Def  (canonical four-type)
  |   MD_KW_Desc             (n_registered, n_keywords, entries(512))
  |   MD_KW_State            (current keyword/line/col, error/warning counts, keywords_parsed)
  |   MD_KW_Algo             (strict_mode, case_sensitive, error/warning limits, recursive_parse)
  |   MD_KW_Ctx              (parse_stage, ast_root_id, file_unit, in_step/part_block)
  |
  | MD_KW_Def.f90        ── MODULE: MD_KW_Def  (extended definitions)
  |   Token types (10), KW categories (13), Parameter types (6)
  |   KW_TokenType, KW_ParamDefType, KW_ParamValueType, KW_MetadataType
  |   KW_DataLineType, KW_ASTNodeType, KW_LexerStateType, KW_ParserStateType
  |
  | MD_KW_Lexer.f90      ── Lexer
  | MD_KW_Parser.f90     ── Parser
  | MD_KW_Reg.f90        ── Keyword registry
  | MD_KW_Abaqus.f90     ── ABAQUS keyword definitions
  | MD_KeyWord_ParserRecursive.f90  ── Recursive parser
```

### 10.7 S6: Field Domain

```
L3_MD Field/              ── Field variable registry (3-type: Desc/State/Ctx, no Algo)
  | MD_Field_Def.f90     ── MODULE: MD_Field_Def
  |   MD_Field_Desc          (fields(64) with id, name, field_type, n_comp, entity, region)
  |   MD_Field_State         (allocated, initialized, n_allocated)
  |   MD_Field_Ctx           (current_step, current_incr, current_time)
  |   MD_FieldEntry, MD_FieldRegionRef, MD_FieldInitCond
  |   8 field types, 5 entity kinds, 5 distribution kinds

L4_PH Field/              ── Field interpolation and physics computation (4-type)
  | PH_Field_Def.f90     ── MODULE: PH_Field_Def
  |   PH_Field_Desc          (nn, nip, ndim, n_comp)
  |   PH_Field_Ctx           (shape funcs, dNdx, E_mat, IP/nodal values, stress invariants)
  |   PH_Field_State         (allocated, values_set, n_dof_active)
  |   PH_Field_Algo          (time: integration, lumped; ctrl: extrapolation, tolerance)
  |   PH_Field_Domain        (desc + state + algo + ctx container)
  |   Physics IO bundles: PH_Temperature_Def, PH_PorePressure_Def, PH_Concentration_Def
  |
  | PH_Field_ShapeFunc.f90, PH_Field_GaussQuadrature.f90, PH_Field_Ops.f90
  | PH_Field_Interpolate.f90, PH_Field_ComputeTemp.f90, PH_Field_ComputePore.f90
```

### 10.8 S7: Constraint Domain

```
L3_MD Constraint/         ── Constraint definitions (full four-type + 5 Desc types)
  | MD_Constr_Def.f90    ── MODULE: MD_Constr_Def  (AUTHORITY)
  |   TieConstraintDef       (tie_id, surfaces, position_tolerance, adjust)
  |   MPCConstraintDef       (mpc_type: GENERAL/BEAM/LINK/PIN, n_terms, node/dof/coeff)
  |   CplConstraintDef       (coupling_type: KINEMATIC/DISTRIBUTING, ref_node, dof flags)
  |   RigidBodyDef           (rbe_kind: RBE2/RBE3, ref_node, element_set)
  |   EmbeddedRegionDef      (host_surface, embedded_set, host_coeffs)
  |   MD_ConstraintUnion     (tie/mpc/cpl/rigid/embedded arrays + counts)
  |   MD_Constraint_State    (assembled, n_active, n_suppressed)
  |   MD_Constraint_Algo     (enforcement: Transform/Lagrange/Penalty, penalty, tolerance)
  |   MD_Constraint_Ctx      (current_constraint_id, operation_type, validation_pending)
  |   5 categories, 4 MPC sub-types, 2 coupling types, 2 RBE kinds, 7 DOF bitmask

L4_PH Constraint/         ── Physical enforcement implementations
  | PH_Constr_Def.f90, PH_Constr_Core.f90, PH_Constr_Domain.f90
  | Tie:      PH_Constr_Tie.f90 / PH_ConstrTie_Def.f90 / PH_ConstrTie_Brg.f90
  | MPC:      PH_Constr_MPC.f90 / PH_ConstrMPC_Def.f90 / PH_ConstrMPC_Brg.f90
  | Embedded: PH_Constr_Embedded.f90 / PH_ConstrEmbedded_Def.f90 / PH_ConstrEmbedded_Brg.f90
  | Periodic: PH_Constr_Period.f90 / PH_ConstrPeriod_Def.f90 / PH_ConstrPeriod_Brg.f90
```

### 10.9 S8: Part Domain

```
L3_MD Part/               ── Part registry and section binding (Desc/State, 8 files)
  | MD_Part_Def.f90      ── MODULE: MD_Part_Def
  |   MD_Part_Entry_Desc     (id, name(64), section_id, valid)
  |   MD_Part_Desc           (parts(256) fixed array, n_parts)
  |   MD_Part_State          (sections_assigned, materials_bound, validated, n_unassigned)
  |   MD_Part_Domain TBP:    Init, Finalize, GetSummary
  |   UF_PartDef legacy:     name, cfg(id, ndim), nNodes, nElems
  |
  | MD_Part_Core.f90     ── MODULE: MD_Part_Core
  |   Init/Finalize/Add/Get_By_ID/Get_By_Name/Assign_Section/Validate/Clone
  |
  | MD_Sets_Def.f90, MD_Sets_Mgr.f90   (UF_NodeSet, UF_ElemSet, UF_Surface)
```

---

## 11. Cross-Domain Integration

### 11.1 Analysis Loop (Master Timeline)

```
RT_StepDriver_Run (RT_Step_Brg.f90)
  |
  +-- For each step:
  |     RT_Step_Drive (iterate increments)
  |       |
  |       +-- RT_Solv_Nonlin (RT_Solv_Mgr / UF_NewtonRaphson)
  |       |     |
  |       |     +-- Pre-processing:
  |       |     |     PH_L4_Populate_Material      (L3→L4 material data)
  |       |     |     RT_Contact_Brg_ToL4           (L5→L4 contact setup)
  |       |     |     RT_LoadBC_Brg_ToL4            (L5→L4 load BC setup)
  |       |     |
  |       |     +-- Newton iteration loop:
  |       |     |     For each element (OMP parallel):
  |       |     |       RT_Elem_Dispatch_Run       (→ PH_Elem_Compute_Ke/Fe)
  |       |     |       For each integration point:
  |       |     |         RT_Mat_Dispatch_Stress    (→ PH_Mat_IP_Incr_Eval)
  |       |     |
  |       |     |     RT_Asm_BuildGlobSys_Sparse   (element scatter → global K/F)
  |       |     |     RT_Cont_Assemble              (contact contributions)
  |       |     |     RT_BC_Apply_Constraints       (apply Dirichlet BCs)
  |       |     |     RT_Solv_Bridge_Unified        (solve K·ΔU = F)
  |       |     |     Convergence check:
  |       |     |       RT_Solv_ConvergenceCtx%Evaluate
  |       |     |       If not converged: next iteration
  |       |     |       If cutback needed: RT_Step_Algo%Cutback
  |       |     |
  |       |     +-- Post-increment:
  |       |           PH_Output_Write               (output frame if due)
  |       |           PH_WriteBack_Dispatch         (writeback results)
  |       |
  |       +-- RT_Cont_AugLag_Solve (Uzawa outer loop, if AugLag)
  |       +-- RT_Step_CheckCompletion
```

### 11.2 Data Consistency Rules

| Rule | Description | Violation Check |
|------|-------------|-----------------|
| DC-1 | **L3 is SSOT for model data**: L4/L5 must never bypass L3 for config. All Desc types originate at L3 and are populated down. | Audit: L4/L5 Desc init must read from L3, not from hardcoded values. |
| DC-2 | **L4 owns physics computation**: L4 is the single layer where constitutive, element, contact, load, and constraint physics kernels execute. L5 dispatches but never computes. | Grep: L5 should call PH_*/call L4 procs, never compute stress/KE independently. |
| DC-3 | **L5 owns runtime orchestration**: Solver/Step/Assembly loops, convergence control, cutback management, and parallel dispatch all stay at L5. | Audit: Only L5 modules should manage step/increment/iteration state machines. |
| DC-4 | **SIO at layer boundaries**: All cross-layer calls use `*_Arg` bundles — L3→L4 (Populate), L5→L4 (Dispatch), L5→L3 (WriteBack). | Lint: Cross-layer SUBROUTINE calls without `*_Arg` parameter detected. |
| DC-5 | **No layered type leaking**: L4 types not used in L3; L5 types not used in L4. Desc/State/Algo/Ctx types are layer-prefixed. | Compiler: L3 file importing `PH_*` detected (DEP-001). |
| DC-6 | **Populate at epoch boundaries**: Bulk cross-layer data transfer occurs only at step/init boundaries, never during the hot iteration loop. | Design: Populate routines called from `RT_Step_Brg` at step start, not from iteration. |
| DC-7 | **Cold data never mutates at runtime**: Desc types are write-once. State types carry runtime mutation. Algo types are semantically static with procedure pointers. | Audit: No write-to-Desc after `Init` phase. Desc passed as `INTENT(IN)`. |
| DC-8 | **Ctx is stack-scoped**: Ctx types carry hot-path temporaries and are re-initialized per compute call. No Ctx field persists across iterations without explicit State migration. | Design: Ctx is `INTENT(INOUT)` but semantically per-call scratch. |
| DC-9 | **Golden line for hot path, Bridge for cold path**: Direct procedure pointer dispatch for IP-level eval (Material, Element). Bridge/wrapper for init/populate/writeback. | Grep: L5 dispatch uses `PROCEDURE POINTER` for hot path (golden line), not Bridge. |
| DC-10 | **Depth-2 auxiliary TYPE nesting**: Auxiliary types within Desc/State/Algo/Ctx are nested at most 2 levels deep (Phase→Verb pattern). | Lint: Depth >2 on auxiliary TYPE nesting detected. |

### 11.3 Cross-Domain Coupling Map

| Consumer \ Provider | Mat | Elem | Cont | LoadBC | Out | WB | Solv | Step | Sect | Asm | Mesh |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Mat** | — | Mat→Sect | — | — | — | — | — | — | Mat↔Sect | — | — |
| **Elem** | Elem→Mat | — | — | — | — | — | — | — | Elem↔Sect | — | Elem↔Mesh |
| **Cont** | — | Cont→Elem | — | — | — | — | — | — | — | Cont→Asm | Cont→Mesh |
| **LoadBC** | — | LoadBC→Elem | — | — | — | — | — | — | — | LoadBC→Asm | — |
| **Output** | Out→Mat | Out→Elem | — | — | — | — | — | Out→Step | — | — | Out→Mesh |
| **WriteBack** | WB→Mat | WB→Elem | — | WB→LoadBC | — | — | WB→Step | WB→Step | — | — | WB→Mesh |
| **Solver** | — | — | Solv→Cont | Solv→LoadBC | — | — | — | Solv↔Step | — | Solv→Asm | — |
| **Step** | Step→Mat | Step→Elem | Step→Cont | Step→LoadBC | Step→Out | Step→WB | Step↔Solv | — | Step→Sect | Step→Asm | — |
| **Assembly** | — | Asm→Elem | Asm→Cont | Asm→LoadBC | — | — | — | — | — | — | Asm→Mesh |

**Legend**: `A→B` = A uses B. `A↔B` = bidirectional coupling. Empty = no direct coupling.

### 11.4 Cold / Warm / Hot Data Classification

| Temperature | Store Policy | Layers | Examples |
|-------------|-------------|--------|----------|
| **Cold** (write-once, read-many) | `INTENT(IN)`, no mutation after Init | L3 (primary), L4·L5 shadows | Material props, element type, section geometry, step config, solver tolerances |
| **Warm** (per-step/per-incr) | `INTENT(INOUT)`, mutated at epoch boundaries | L3·L4·L5 State | Stress state, element state, contact forces, accumulated output |
| **Hot** (per-iteration/per-IP) | Stack-allocated Ctx, re-initialized per call | L4·L5 Ctx | IP coordinates, shape functions, element ke stack, scratch arrays, work vectors |

### 11.5 Stateful / Stateless Split

| Layer | Stateless Module Types | Stateful Module Types |
|-------|----------------------|----------------------|
| L3_MD | Populate, Validate, Query | _Mgr (Domain containers), _State |
| L4_PH | _Core (kernel compute), _Brg, _Eval | _State (physics state), _Mgr |
| L5_RT | _Brg, _Solv (dispatch only) | _Domain (runtime domain), _State, _Mgr, _Impl |

---

## 12. Appendix: Key File Paths

### 12.1 P1 Material Domain

| Layer | Directory | Authority File |
|-------|-----------|----------------|
| L3 | `ufc_core/L3_MD/Analysis/Material/` | `MD_Mat_Elas_Def.f90` |
| L3 Bridge | `ufc_core/L3_MD/Bridge/Bridge_L4/` | `MD_MatLibPH_Brg.f90` |
| L4 | `ufc_core/L4_PH/Analysis/Material/` | `PH_Mat_Elas_Def.f90`, `PH_Mat_Elas_Core.f90`, `PH_Mat_Algo.f90` |
| L5 | `ufc_core/L5_RT/Analysis/Material/` | `RT_Mat_Elas_Def.f90`, `RT_Mat_Dispatch.f90` |

### 12.2 P2 Element Domain

| Layer | Directory | Authority File |
|-------|-----------|----------------|
| L3 | `ufc_core/L3_MD/Element/Elem/` | `MD_Elem_Def.f90`, 12 family subdirs |
| L4 | `ufc_core/L4_PH/Element/` | `PH_Elem_Def.f90`, `PH_Elem_Core.f90` |
| L5 | `ufc_core/L5_RT/Element/` | `RT_Elem_Def.f90`, `RT_Elem_Proc.f90` |

### 12.3 P3 Contact/Interaction Domain

| Layer | Directory | Authority File |
|-------|-----------|----------------|
| L3 | `ufc_core/L3_MD/Interaction/` | `MD_Int_Def.f90`, `MD_Int_Types.f90` |
| L3 Bridge | `ufc_core/L3_MD/Bridge/Bridge_L4/` | `MD_ContPH_Brg.f90` |
| L3 Bridge | `ufc_core/L3_MD/Bridge/Bridge_L5/` | `MD_ContRT_Brg.f90`, `MD_Int_ContactArgs.f90` |
| L4 | `ufc_core/L4_PH/Contact/` | `PH_Cont_Def.f90`, `PH_Cont_Core.f90`, `PH_Cont_Search.f90` |
| L5 | `ufc_core/L5_RT/Contact/` | `RT_Cont_Def.f90`, `RT_Cont_Core.f90`, `RT_Cont_Solv.f90`, `RT_Cont_Brg.f90` |

### 12.4 P4 LoadBC Domain

| Layer | Directory | Authority File |
|-------|-----------|----------------|
| L3 | `ufc_core/L3_MD/LoadBC/` | `MD_LBC_Def.f90` |
| L4 | `ufc_core/L4_PH/LoadBC/` | `PH_LoadBC_Def.f90`, `PH_LoadBC_Core.f90`, `PH_Ldbc_Brg.f90` |
| L5 | `ufc_core/L5_RT/LoadBC/` | `RT_LoadBC_Impl.f90`, `RT_LoadBC_Brg.f90` (NOTE: `RT_LoadBC_Def.f90` MISSING — see §5) |

### 12.5 P5 Output Domain

| Layer | Directory | Authority File |
|-------|-----------|----------------|
| L3 | `ufc_core/L3_MD/Output/` | `MD_Out_Def.f90`, `MD_Out_API.f90` |
| L4 | `ufc_core/L4_PH/Output/` | `PH_Out_Def.f90`, `PH_Out_Core.f90`, `PH_Out_Brg.f90` |
| L5 | `ufc_core/L5_RT/Output/` | `RT_Out_Def.f90`, `RT_Out_Mgr.f90`, `RT_Out_Proc.f90`, `RT_Out_Brg.f90` |
| L6 | `ufc_core/L6_AP/Output/` | `AP_Out_Def.f90`, `AP_OutRT_Brg.f90` |

### 12.6 P6 WriteBack Domain

| Layer | Directory | Authority File |
|-------|-----------|----------------|
| L3 | `ufc_core/L3_MD/WriteBack/` | `MD_WB_Def.f90`, `MD_WB_Core.f90`, `MD_WB_Brg.f90` |
| L4 | `ufc_core/L4_PH/WriteBack/` | `PH_WB_Def.f90`, `PH_WB_Core.f90` |
| L5 | `ufc_core/L5_RT/WriteBack/` | `RT_WB_Def.f90`, `RT_WB_Domain.f90`, `RT_WB_Proc.f90`, `RT_WB_Brg.f90` |

### 12.7 H1 Analysis/Solver/Step Domain

| Layer | Directory | Authority File |
|-------|-----------|----------------|
| L3 Solver | `ufc_core/L3_MD/Analysis/Solver/` | `MD_Solv_Def.f90`, `MD_Solv_Mgr.f90`, `MD_Solv_Sync.f90` |
| L3 Step | `ufc_core/L3_MD/Analysis/Step/` | `MD_Step_Def.f90`, `MD_Step_Mgr.f90`, `MD_Step_Proc.f90` |
| L5 Solver | `ufc_core/L5_RT/Solver/` | `RT_Solv_Def.f90`, `RT_Solv_Mgr.f90`, `RT_Solv_Brg.f90` |
| L5 Step | `ufc_core/L5_RT/StepDriver/` | `RT_Step_Def.f90`, `RT_Step_Exec.f90`, `RT_Step_Brg.f90` |

### 12.8 H2 Section Domain

| Layer | Directory | Authority File |
|-------|-----------|----------------|
| L3 | `ufc_core/L3_MD/Section/` | `MD_Sect_Def.f90`, `MD_Sect_Core.f90`, `MD_Sect_Compat.f90` |
| L5 | `ufc_core/L5_RT/Section/` | `RT_Sect_Def.f90`, `RT_Sect_Aux_Def.f90` |

### 12.9 Layer-Only Domains

| Code | Domain | Directory | Authority File |
|------|--------|-----------|----------------|
| S1 | Assembly | `L3_MD/Assembly/`, `L5_RT/Assembly/` | `MD_Asm_Mgr.f90`, `RT_Asm_Def.f90`, `RT_Asm_Domain.f90` |
| S2 | Mesh | `L3_MD/Element/Mesh/`, `L5_RT/Element/Mesh/` | `MD_Mesh_Def.f90`, `MD_Mesh_Domain.f90` |
| S3 | Bridge | All layers' `Bridge/` dirs | `RT_Brg_Def.f90` (11 ctx types), `MD_Brg_Def.f90` |
| S4 | Model | `L3_MD/Model/` | `MD_Model_Def.f90`, `MD_Base_ObjModel.f90` |
| S5 | KeyWord | `L3_MD/KeyWord/` | `MD_KeyWord_Def.f90`, `MD_KW_Def.f90` |
| S6 | Field | `L3_MD/Field/`, `L4_PH/Field/` | `MD_Field_Def.f90`, `PH_Field_Def.f90` |
| S7 | Constraint | `L3_MD/Constraint/`, `L4_PH/Constraint/` | `MD_Constr_Def.f90`, `PH_Constr_Def.f90` |
| S8 | Part | `L3_MD/Part/` | `MD_Part_Def.f90` |

---

## 13. Appendix: Architecture Invariants

The following invariants **must not be violated** during code evolution:

1. **DEP-001**: L3_MD must not `USE` `PH_`/`RT_`/`AP_` modules (Bridge directories and `*_Brg.f90` files are the only exception).
2. **GLB-001**: L4_PH Element core kernels must not `USE` `UFC_GlobalContainer_Core` — data enters via Populate/Ctx injection.
3. **T4-001**: All four-type TYPE names must end with `_Desc`/`_State`/`_Algo`/`_Ctx`. Auxiliary types use Phase+Verb nested pattern.
4. **SIO-001**: All cross-layer calls use `*_Arg` bundles except single-field calls (where only `status` would be wrapped).
5. **HOT-001**: Hot-path procedures (Material IP eval, Element GP eval) use direct procedure pointer dispatch, not Bridge wrappers.
6. **NAME-001**: Module names match file names; layer prefix is mandatory on all PUBLIC symbols.
7. **DC-001**: L3 writes Desc once. L4/L5 never mutate L3 Desc at runtime.

---

*End of document. All 8 domain pillars defined with exact data flow chains, SIO Arg types, key procedure signatures, injection paths, and cross-layer integration rules.*

*冷归档全文：`UFC/REPORTS/archive/UFC_L3L4L5_CrossLayer_DataFlow_v1.md`。入口 stub：`UFC/REPORTS/UFC_L3L4L5_CrossLayer_DataFlow_v1.md`。*
