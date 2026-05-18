# UFC 域改造路线图

> **版本**: v1.0 | 2026-03  
> **依据**: 三步状态机、六层架构、四链贯通、AI-ready 插槽

---

## 一、改造总纲

### 1.1 核心目标

| 目标 | 说明 | 状态 |
|------|------|------|
| **三步索引化** | step_idx/incr_idx 贯穿 L3→L5 | 进行中 |
| **PROC→Runner 注册表** | 替代 28 路 switch | ✓ 已实现 |
| **逐 PROC L4 组装** | PH_L4_Populate 按 step 填充 | ✓ 已实现 |
| **逐 Runner 四链补全** | 理论/逻辑/计算/数据链 | 进行中 |
| **UEL/UMAT 索引化** | 模板纳入 + step_idx/incr_idx 对接 | 进行中 |
| **热路径隔离** | 嵌套+扁平存储 | 进行中 |
| **三级存储** | Level 0/1/2 + 生命周期 | 设计推进中 |
| **数据链路径** | AI-ready 插槽贯通 | 进行中 |
| **双轨共存** | 传统算法 + AI 代理 | 进行中 |
| **三级命名** | 层级--域级--功能 | 部分完成 |

### 1.2 命名规范

- **层级**: L1_IF, L2_NM, L3_MD, L4_PH, L5_RT, L6_AP
- **域级**: Amplitude, Boundary, Section, Material, Mesh, Step, ...
- **功能**: Types, Core, API, Sync, Idx_API, WriteBack, ...

---

## 二、L1_IF 域改造清单

### 2.1 已完成

| 域 | 改造项 | 文件 |
|----|--------|------|
| Base | BaseCtx (L4/L6 用), Init/Cleanup/ClearStatus/IsOK | L1_IF/Base/IF_Base_Ctx.f90 |
| Step | RT_STEP_TYPE_* 与 step_idx 贯通文档化 | IF_Step_Type.f90 |
| Memory | 三级存储 Level 1 文档化 | IF_Mem_Core.f90 |
| Persist | 三级存储 Level 0 文档化 | IF_IO_Persist.f90 |

### 2.2 待办

| 域 | 改造项 | 优先级 |
|----|--------|--------|
| 其余 | 三级命名 IF_<域>_<功能> 一致性检查 | 低 |

---

## 三、L2_NM 域改造清单（排除 ExternalLibs）

### 3.1 已完成

| 域 | 改造项 | 文件 |
|----|--------|------|
| Matrix | 三级存储 Level 2、热路径文档化 | NM_Sparse_Matrix_Core, NM_Assem_Sparse |
| LinAlg | Level 2 冷/热路径文档化 | NM_LinAlg_Domain_Core |
| Solver | 热路径文档化、AI 插槽说明 | NM_Solv_Core |

### 3.2 待办

| 域 | 改造项 | 优先级 |
|----|--------|--------|
| 其余 | UF_* 逐步迁移 NM_*（兼容保留） | 低 |

---

## 四、L3_MD 域改造清单

### 4.1 已完成

| 域 | 改造项 | 文件 |
|----|--------|------|
| Amplitude | State step_idx/incr_idx, WriteBack optional, EvalCtx, Idx_API | MD_Amplitude_*.f90 |
| Boundary | State/Ctx step_idx/incr_idx, WriteBack optional, StructFieldDesc | MD_Ldbc_*.f90, MD_LoadBC_*.f90 |
| Interaction | pair_state step_idx/incr_idx, WriteBack_State optional | MD_Cont_Core.f90 |
| Output | output_state step_idx/incr_idx, WriteBack optional | MD_Out_Core.f90 |
| Section | StructFieldDesc data_type/elem_len | MD_Sect_Core.f90 |
| Material | StructFieldDesc data_type/elem_len | MD_Mat_*.f90 |
| Mesh | StructFieldDesc data_type/elem_len | MD_Mesh_*.f90, MD_Elem_Core.f90 |
| Constraint | StructFieldDesc data_type/elem_len | MD_Constraint_PairDef.f90 |
| Model | StructFieldDesc | MD_Model_Types.f90 |

### 4.2 待办

| 域 | 改造项 | 优先级 |
|----|--------|--------|
| Step | WriteBack 可选 incr_idx（已有 current_increment） | ✓ 已实现 |
| Mesh | MeshState nAssembled + step_idx/incr_idx | ✓ 已实现 |
| Assembly | MD_Assem_Algo 域修复（Init/守卫/ALLOCATE stat、Legacy 金线） | ✓ 已实现 |
| Model | MD_Base_TreeIndex_Core 修复（TreeNodeBase、IndexMgr、IDList） | ✓ 已实现 |

---

## 五、L4_PH 域改造清单

### 5.1 已完成

| 域 | 改造项 | 文件 |
|----|--------|------|
| Populate | stepId 贯通 Material/LoadBC/Constraint/Coupling/Contact | PH_L4_Populate_Core.f90 |
| UMAT | PH_UMAT_Context 含 kstep/kinc（ABAQUS 兼容） | PH_UserSub_UMAT.f90 |
| **UMAT 单轨** | Defn_Invoke_UMAT 全面切换；Plast/HyperElas/Visc/Creep/Therm/Spcl 六类 Defn 均走 UMAT | PH_Mat_Defn_UMAT_Bridge, PH_Mat_TypeToId_Map, PH_Mat_*_Defn.f90 |
| **UMAT 单轨** | mat_type↔mat_id 全量映射（7 大类 73 种）；Build_UMAT_Context_From_Mat | PH_Mat_TypeToId_Map.f90, PH_Mat_Defn_UMAT_Bridge.f90 |

### 5.2 待办

| 域 | 改造项 | 优先级 |
|----|--------|--------|
| Populate | stepId=step_idx 文档化（兼容保留 stepId 参数名） | ✓ 已实现 |
| UMAT | 文档化 kstep/kinc 与 step_idx/incr_idx 对应 | ✓ 已实现 |
| Element | ElemCtx 增加 step_idx/incr_idx | ✓ 已实现 |
| LoadBC | PH_Ldbc_Ctx step_idx/incr_idx | ✓ 已实现 |

---

## 六、L5_RT 域改造清单

### 6.1 已完成

| 域 | 改造项 | 文件 |
|----|--------|------|
| PROC→Runner | Reg_Add/Reg_Get 注册表 | RT_StepRunner_Reg.f90 |
| LoadBC Ctx | MD_LoadBC_Ctx step_idx/incr_idx, AI 插槽占位 | RT_Ldbc_Apply_Core.f90 |
| AI 插槽 | StepController, ConvergencePredictor 契约 | docs/AI_Slot_Contract.md |
| UEL 模板 | MyUEL_Template 索引化注释 | MyUEL_Template.f90 |

### 6.2 待办

| 域 | 改造项 | 优先级 |
|----|--------|--------|
| WriteBack | L5 调用 MD_WB_* 时传递 step_idx/incr_idx（API 已支持 optional） | ✓ 已实现 |
| Runner | 各 Runner Init 填充 step_idx/incr_idx 到 Ctx | ✓ 已实现 |
| UEL | ElemCtx 传入 step_idx/incr_idx（BuildElementContext 填充） | ✓ 已实现 |
| Solver | Newton 迭代内 AI_ConvPredictor 调用 + 早退 | ✓ 已实现 |

**注**: MD_WB_Step 已传递 step_idx、current_inc；MD_WB_LoadBC/Amplitude/Output/Interaction 已支持 optional step_idx/incr_idx。Runner 填充：RT_StepDrv_Domain InitIncrement 同步 current_incr_idx 到 md_layer%step；MD_LoadBC_Ctx_Bind 自动从 md_layer%step 读取 step_idx/incr_idx。

---

## 七、三级存储 (Level 0/1/2)

| Level | 用途 | 生命周期 | 状态 |
|-------|------|----------|------|
| **Level 0** | 外部持久化（文件/DB/HDF5） | Job 级 | 规划中 |
| **Level 1** | 内存池（slot_pool、elem_coords_cache） | Step/Incr 级 | 部分落地 |
| **Level 2** | 热路径缓存（CSR、扁平数组） | Incr/Iter 级 | 进行中 |

- **Level 1**：PH_L4_Populate 填充 Material/Element 到 slot_pool、elem_coords_cache；PH_Nested_Flat_API 提供 Nested→Flat 接口。
- **Level 2**：RT_CSRMatrix、AssemMgr 等热路径数据结构；嵌套 Desc→扁平 values 转换。
- **Level 0**：Restart、Checkpoint、Output 持久化；待与 WriteBack 契约对齐。

---

## 八、热路径 (嵌套+扁平存储)

- **PH_Nested_Flat_API**：`PH_Nested_To_Flat_Material`、`PH_Nested_To_Flat_Element`、`PH_Flat_To_Nested_State`。
- **冷路径**：Step Init 时 Nested→Flat 拷贝 L3 Desc 到 L4 缓存。
- **热路径**：Incr/Iter 内仅访问 L4 扁平缓存，避免 L3 树遍历。
- **WriteBack**：Increment End 经 MD_WB_* / RT_WriteBack_* 回写 L4→L3 State（白名单）。

---

## 九、数据链路径 (L3→L5)

```
L3_MD (State)          L4_PH (Ctx)           L5_RT (Ctx/Apply)
─────────────────────────────────────────────────────────────
amp_state%step_idx  →  (EvalCtx)          →  Amplitude Eval
amp_state%incr_idx

load_state%step_idx →  PH_Ldbc (stepId)   →  RT_Ldbc_Apply_Ctx
load_state%incr_idx

pair_state%step_idx →  PH_Contact         →  RT_Cont_*
pair_state%incr_idx

output_state%step_idx → PH_Output          →  RT_Out_*
output_state%incr_idx
```

---

## 十、AI-ready 插槽

- **AI_StepController**: Increment 收敛后建议 new_dt
- **AI_ConvPredictor**: Iteration 内预测收敛、早退
- **注入路径**: StepDriverContext → RT_StepDriver_ApplyAISlots → cfg → Runner/Newton

详见 `docs/AI_Slot_Contract.md`。

---

## 十一、逐域逐文件改造进度

### L1_IF (43 个 .f90)

- [x] IF_Base_Ctx (BaseCtx for L4/L6; 自 IF_Ctx_Core 迁入 Base)
- [x] IF_Step_Type (step_idx 贯通文档化)
- [x] IF_Mem_Core (三级存储 Level 1 文档化)
- [x] IF_IO_Persist (三级存储 Level 0 文档化)
- [ ] 其余按需（三级命名一致性）

### L2_NM (68 个 .f90，排除 ExternalLibs)

- [x] NM_Sparse_Matrix_Core (三级存储 Level 2、热路径文档化)
- [x] NM_Assem_Sparse (Level 2、热路径隔离文档化)
- [x] NM_LinAlg_Domain_Core (Level 2 冷/热路径)
- [x] NM_Solv_Core (热路径、AI 插槽说明)
- [ ] 其余按需（UF_* 迁移 NM_* 低优先级）

### L3_MD (188 个 .f90)

- [x] Amplitude (3)
- [x] Boundary (9)
- [x] Interaction (4)
- [x] Output (多)
- [x] Section (多)
- [x] Material (多)
- [x] Mesh (多)
- [x] Constraint (多)
- [x] Model (多)
- [x] Assembly (MD_Assem_Algo / MD_Assem_Legacy 金线与健壮性)
- [ ] Step (可选)
- [ ] 其余域按需

### L4_PH (352 个 .f90)

- [x] PH_L4_Populate_Core
- [x] PH_UserSub_UMAT
- [x] PH_Element_Domain_Core (PH_Element_Ctx step_idx/incr_idx)
- [x] PH_Ldbc_Core (PH_LoadBC_Ctx 已有 step_idx/incr_idx)
- [x] PH_Constraint_Domain_Core (PH_Constraint_Ctx step_idx/incr_idx, Init optional incr_idx)
- [x] PH_Cont_Domain (PH_Contact_Ctx step_idx/incr_idx, Init optional incr_idx)
- [x] PH_Coupling_Domain_Core (PH_Coupling_Ctx step_idx/incr_idx, Init optional incr_idx)
- [x] PH_Mat_Domain_Core (PH_Mat_Ctx/Domain step_idx/incr_idx, Init optional incr_idx, UMAT kstep/kinc)
- [x] PH_Brg_Domain_Core (PH_Brg_Ctx step_idx/incr_idx, Init optional incr_idx)
- [ ] 其余按需

### L5_RT (187 个 .f90)

- [x] RT_StepRunner_Reg
- [x] RT_Ldbc_Apply_Core (Ctx + AI 占位)
- [x] RT_WriteBack_Domain_Core (MD_WB_Step 已传递 step_idx/current_inc)
- [x] 各 Runner (Ctx 填充：step_idx/incr_idx 同步)
- [x] RT_Contact_Domain_Core (RT_Contact_Ctx step_idx/incr_idx, Init optional, SyncStepIncr)
- [x] RT_Asm_ApplyContact (PH_Cont_Ctx_Init step_idx/incr_idx 传递)
- [x] PH_Cont_Ctx_Init (optional step_idx/incr_idx)
- [x] RT_Output_Domain_Core (RT_Output_Ctx step_idx/incr_idx, Init optional, SyncStepIncr, ScheduleWrite_Arg)
- [x] RT_Coupling_Domain_Core (CouplingCtx step_idx/incr_idx, Eval_Arg/Eval_Idx incr_idx)
- [x] RT_Assembly_Domain_Core (RT_Assembly_Ctx step_idx/incr_idx, Init optional, SyncStepIncr)
- [x] RT_Element_Domain_Core (RT_Element_Ctx step_idx/incr_idx, Init optional, SyncStepIncr)
- [x] RT_Solver_Domain_Core (RT_Solver_Ctx step_idx/incr_idx, Init optional, SyncStepIncr)
- [x] RT_Step_Domain_Core (current_incr_idx, Init optional incr_idx, SyncStepIncr)
- [x] RT_Brg_Core (RT_Bridge_Ctx step_idx/incr_idx, Init optional, SyncStepIncr)
- [x] RT_Logging_Domain_Core (RT_Logging_Ctx step_idx/incr_idx, Init optional, SyncStepIncr)
- [ ] 其余按需

### L6_AP (104 个 .f90)

- [x] AP_Job_Ctx (current_step/current_incr, Init optional step_idx/incr_idx)
- [x] AP_Job_Domain (AP_Job_State currentIncrIdx, RollbackToStep stepId=step_idx)
- [x] AP_Solver_Domain (AP_Solver_State currentIncrIdx)
- [x] AP_Output_Domain (WriteFrame_Arg step_id/inc_id = step_idx/incr_idx 文档化)
- [ ] 其余按需（JobCtx/AP_Brg_L5 为全量 RunJob，无逐 incr 同步）
