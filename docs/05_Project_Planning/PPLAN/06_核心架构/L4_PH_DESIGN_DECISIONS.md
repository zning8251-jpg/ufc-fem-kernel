# L4_PH 层设计决策文档

> 状态: CORE | 创建: 2026-04-26 | 版本: v1.1
> 关联: UFC_DOMAIN_PILLAR_ARCHITECTURE.md (域柱架构), L3_MD_DESIGN_DECISIONS.md, L5_RT_DESIGN_DECISIONS.md

## 总论

L4_PH 是 UFC 有限元内核的**物理计算核心**，对应 ABAQUS 的 ELEMLIB/MATLIB/CONTACT。
与 L3_MD（Desc 主导）不同，L4 以**算法过程**为核心产出。

```
L3_MD = Desc 主导 (写一次, 运行时只读)  -->  "数据定义层"
L4_PH = Algo 主导 (热路径, 每IP每迭代)  -->  "物理计算层"
```

## 四型在 L4 的角色转变

| 四型 | L3 角色 | L4 角色 |
|------|--------|--------|
| Desc | 核心产出 (Write-Once) | 冷缓存 (Populate from L3) |
| State | 辅助追踪 | 核心产出 (stress/SDV/energy) |
| Algo | 不常用 | 灵魂 (算法配置与路由) |
| Ctx | 不常用 | 灵魂 (热路径 IP 级工作区) |

---

## L4 过程命名对照表 (Phase x Verb)

### Phase 轴 (L4 视角)

| Phase | 含义 | L4 典型场景 |
|-------|------|-----------|
| Setup | 步初始化阶段 | Init/Populate/Register |
| Step | 步级操作 | 步参数设置、材料预计算 |
| Iteration | NR 迭代内 | Compute_Ke/Fe, Update_Stress, Detect |
| Convergence | 收敛判定/状态提交 | Rollback/Accept/Evaluate |
| Query | 运行时查询 | Get/Interpolate/Project |
| Teardown | 步终了/释放 | Finalize/Cleanup |

### Verb 轴 (L4 视角)

| Verb | 含义 | 命名规范 | 示例 |
|------|------|---------|------|
| Init | 初始化 | `PH_{Domain}_Init` | `PH_Element_Domain_Init` |
| Finalize | 释放 | `PH_{Domain}_Finalize` | `PH_Mat_Domain_Finalize` |
| Populate | L3 数据注入 | `PH_L4_Populate_{Domain}` | `PH_L4_Populate_Material` |
| Register | 注册实体 | `PH_{Domain}_Register*` | `PH_Contact_RegisterPair` |
| Compute | 核心计算 | `PH_{Domain}_Compute_*` | `PH_Elem_Compute_Ke` |
| Update | 状态更新 | `PH_{Domain}_Update_*` | `PH_Mat_Update_StateVars` |
| Assemble | 局部贡献组装 | `PH_{Domain}_Assemble_*` | `PH_LoadBC_Assemble_Fext` |
| Detect | 搜索/检测 | `PH_{Domain}_Detect_*` | `PH_Contact_Detect` |
| Rollback | 迭代回滚 | `PH_{Domain}_Rollback` | `PH_Mat_Rollback` |
| Accept | 收敛接受 | `PH_{Domain}_Accept` | `PH_Mat_Accept` |
| Evaluate | 评估/插值 | `PH_{Domain}_Eval_*` | `PH_LoadBC_Eval_Amplitude` |
| Get | 只读查询 | `PH_{Domain}_Get*` | `PH_Elem_Reg_Get` |
| Interpolate | 场插值 | `PH_{Domain}_Interpolate_*` | `PH_Field_Interpolate_IP` |
| Project | 场投影 | `PH_{Domain}_Project_*` | `PH_Field_Project_Nodal` |
| Validate | 验证 | `PH_{Domain}_Validate` | `PH_Element_Domain_Validate` |

### 不推荐命名 (LEGACY)

| 不推荐 | 推荐替代 | 原因 |
|--------|---------|------|
| `Calc_*` | `Compute_*` | 统一动词 |
| `Build_*` | `Init_*` 或 `Compute_*` | 歧义 |
| `Form*Matrix` | `Compute_Ke` / `Compute_Me` | 统一风格 |
| `*_InOut` | `*_Arg` | SIO 规范 |

---

## 域容器设计

### PH_L4_LayerContainer 结构

```
PH_L4_LayerContainer
  material   :: PH_Mat_Domain    (金线: Compute_Ctan, Update_StateVars)
  element    :: PH_ElemDomain_Algo    (金线: Compute_Ke, Compute_Fe)
  loadbc     :: PH_LoadBC_Domain      (金线: Assemble_Fext, Apply_Dirichlet)
  constraint :: PH_Constraint_Domain  (金线: Compute MPC/Tie/Periodic)
  contact    :: PH_Contact_Domain     (金线: Detect, ComputeForce)
  bridge     :: PH_Brg_Domain         (WriteBack, Output 桥接)
  phase      :: INTEGER(i4)           (生命周期阶段门 v4.0)
```

### 生命周期阶段门

```
PH_L4_PHASE_UNINIT    = 0   -- 未初始化
PH_L4_PHASE_INIT      = 1   -- 域 Init 完成
PH_L4_PHASE_POPULATED = 2   -- L3->L4 Populate 完成
PH_L4_PHASE_READY     = 3   -- 可计算状态
PH_L4_PHASE_COMPUTING = 4   -- NR 迭代中
PH_L4_PHASE_CONVERGED = 5   -- 本增量步收敛
```

---

## 热路径零 L3 规则

| 规则 | 说明 |
|------|------|
| IP 循环内禁止 `USE MD_*` | 所有 L3 数据必须经 Populate 缓存到 L4 slot |
| Element 热路径核: 仅 `PH_*` 导入 | `PH_Elem_Core`, `PH_ElemCalcWrapper` 等 |
| Material 热路径核: 仅 `PH_*` 导入 | `PH_Mat_Elas_Core`, `PH_MatDispatch` 等 |
| Contact 热路径核: 仅 `PH_*` 导入 | `PH_Cont_Core`, `PH_Contact_Core` 等 |
| 允许 `USE MD_*` 的位置 | 仅 Populate 子程序和 Bridge 模块 |

---

## 金线收敛路线图

### Element 金线

```
L5 -> PH_Element_Domain%Compute_Ke(elem_idx, args, status)
   -> PH_Elem_Reg_Get(family_id) -> 族核 (Solid3D/Shell/Beam/...)
   -> 族核%FormStiffMatrix / Compute_Ke_Impl
```

LEGACY 入口 (迁移中):
- `PH_ElemCalcWrapper::PH_Elem_Calc_Ke` -- SIO wrapper, 12族路由
- `PH_ElemKeDispatch::Compute_Ke` -- 简单数组 API

### Material 金线

```
Element IP loop -> PH_Mat_Domain%Compute_Ctan(mat_pt_idx, strain, stress, C_tan, status)
               -> PH_Mat_Reg_Get(mat_id) -> 本构核 (Elastic/Plastic/...)
               -> 本构核%Compute_Stress / Compute_Tangent
```

LEGACY 入口 (迁移中):
- `PH_MatDispatch::PH_Mat_Update_Stress`
- `PH_MatEval::PH_Mat_*_Eval`

---

## 跨域接口清单 (ABSTRACT INTERFACE)

| ID | 方向 | 用途 | 状态 |
|----|------|------|------|
| I-01 | Element->Material | 应力/SDV 读取 | 已定义 |
| I-02 | Contact->Element | 面几何查询 | 已定义 |
| I-03 | Material->Contact | 热物性查询 | 已定义 |
| I-04 | LoadBC->Element | 节点力施加 | 待定义 |
| I-05 | Constraint->Element | MPC 贡献 | 待定义 |
| I-06 | Field->Element | 多物理场耦合项 | 待定义 |
| I-07 | Element->Contact | 面法向/面积 | 待定义 |

---

## L4 算法步归约 (Phase x Verb) 全域矩阵

### Element 域

| Phase\\Verb | Init | Populate | Compute | Update | Validate | Get | Finalize |
|-------------|------|----------|---------|--------|----------|-----|----------|
| Setup | PH_Element_Domain_Init | PH_L4_Populate_Element | - | - | PH_Element_Domain_Validate | - | - |
| Step | - | - | - | - | - | - | - |
| Iteration | - | - | PH_Elem_Calc_Ke/Fe/Me/Ce | - | - | PH_Elem_Reg_Get | - |
| Convergence | - | - | - | - | - | - | - |
| Query | - | - | - | - | - | PH_Elem_GetConfig | - |
| Teardown | - | - | - | - | - | - | PH_Element_Domain_Finalize |

### Material 域

| Phase\\Verb | Init | Populate | Compute | Update | Rollback | Accept | Get | Finalize |
|-------------|------|----------|---------|--------|----------|--------|-----|----------|
| Setup | PH_Mat_Domain_Init | PH_L4_Populate_Material | - | - | - | - | - | - |
| Step | - | - | - | - | - | - | - | - |
| Iteration | - | - | Compute_Ctan | Update_StateVars | Rollback | - | - | - |
| Convergence | - | - | - | - | - | Accept | - | - |
| Query | - | - | - | - | - | - | PH_Mat_Reg_Get | - |
| Teardown | - | - | - | - | - | - | - | PH_Mat_Domain_Finalize |

### Contact 域

| Phase\\Verb | Init | Populate | Detect | Compute | Update | Get | Finalize |
|-------------|------|----------|--------|---------|--------|-----|----------|
| Setup | PH_Contact_Domain_Init | PH_L4_Populate_Contact | - | - | - | - | - |
| Step | - | - | - | - | - | - | - |
| Iteration | - | - | PH_Contact_Detect | PH_Contact_Compute_* | PH_Contact_Update | - | - |
| Query | - | - | - | - | - | PH_Cont_API_Get* | - |
| Teardown | - | - | - | - | - | - | PH_Contact_Domain_Finalize |

### LoadBC 域

| Phase\\Verb | Init | Populate | Compute | Assemble | Evaluate | Finalize |
|-------------|------|----------|---------|----------|----------|----------|
| Setup | PH_LoadBC_Domain_Init | PH_L4_Populate_LoadBC | - | - | - | - |
| Step | - | - | - | - | PH_LoadBC_Eval_Amplitude | - |
| Iteration | - | - | PH_Load_Compute_* | PH_LoadBC_Assemble_Fext | - | - |
| Teardown | - | - | - | - | - | PH_LoadBC_Domain_Finalize |

### Constraint 域

| Phase\\Verb | Init | Populate | Register | Compute | Assemble | Finalize |
|-------------|------|----------|----------|---------|----------|----------|
| Setup | PH_Constraint_Domain_Init | PH_L4_Populate_Constraint | Register | - | - | - |
| Iteration | - | - | - | PH_Constr_*_Compute | PH_Constr_Assemble | - |
| Teardown | - | - | - | - | - | PH_Constraint_Domain_Finalize |

### Field 域

| Phase\\Verb | Init | Populate | Compute | Interpolate | Project | Finalize |
|-------------|------|----------|---------|-------------|---------|----------|
| Setup | PH_Field_Domain_Init | PH_L4_Populate_Field | - | - | - | - |
| Step | - | - | PH_Field_Evolve_* | - | - | - |
| Iteration | - | - | PH_Field_Compute_* | PH_Field_Interpolate_IP | - | - |
| Query | - | - | - | - | PH_Field_Project_Nodal | - |
| Teardown | - | - | - | - | - | PH_Field_Domain_Finalize |

---

## 实施文件清单

| Phase | 文件 | 变更 |
|-------|------|------|
| 0 | `Element/PH_Elem_Def.f90` | 补全 PH_Elem_Base_{Desc,State,Algo,Ctx} 四型 |
| 0 | `Element/PH_ElemCalcWrapper.f90` | 修复 USE 导入; 标记 GOLDEN-LINE |
| 0 | 6 域 CONTRACT.md | 四型裁剪决策 (v4.0) 补全 |
| 0 | `docs/L4_PH_DESIGN_DECISIONS.md` | 本文档 |
| 1 | `PH_L4Layer.f90` | PH_L4_PHASE_* 枚举 + MarkPopulated/MarkReady/GetPhase |
| 2 | `Element/PH_ElemKeDispatch.f90` | 标记 LEGACY |
| 2 | `Element/PH_ElemFeDispatch.f90` | 标记 LEGACY |
| 2 | `Material/Dispatch/PH_MatEval.f90` | 标记 LEGACY |
| 2 | `Material/Dispatch/PH_MatPLMEval.f90` | 标记 LEGACY |
| 3 | `PH_CrossDomainInterfaces.f90` | 重写: 修复 I-01~I-03 骨架 BUG + 新增 I-04~I-07 |
| 3 | `Field/PH_Field_Def.f90` | 补全 PH_Field_Algo TYPE + PH_Field_Domain 容器 |
| 4 | `docs/L4_PH_DESIGN_DECISIONS.md` | 全域 Phase x Verb 矩阵 + 命名规范 |
