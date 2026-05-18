# L3_MD Bridge 模块真值表（BRIDGE_INDEX）

> **真源**：`UFC/ufc_core/L3_MD/Bridge/Bridge_L4/*.f90`、`Bridge_L5/*.f90` 及 `Analysis/Solver/MD_Solv.f90`（求解器桥并入域）。  
> **维护规则**：新增或重命名桥模块须 **先更新本表**，再改 [`CONTRACT.md`](CONTRACT.md) / L4 合同中的路径与 `MODULE` 名。  
> **更新**：2026-04-25（文件名与 `MODULE` 与仓库一致；废弃文档中的下划线旧名）

---

## 1. L3→L4（`Bridge/Bridge_L4/`）

| `MODULE`（`USE` 名） | 源文件 | 职责摘要 |
|----------------------|--------|----------|
| `MD_MatLibPH_Brg` | `Bridge_L4/MD_MatLibPH_Brg.f90` | 材料 → PH slot / 路由（**热路径 LEGACY**，以 Populate 金线为准） |
| `MD_ElemPH_Brg` | `Bridge_L4/MD_ElemPH_Brg.f90` | 单元 Desc → PH |
| `MD_LBCPH_Brg` | `Bridge_L4/MD_LBCPH_Brg.f90` | 载荷/BC → PH（过程名仍多为 `MD_LoadBC_PH_Brg_*`，见模块内 `PUBLIC`） |
| `MD_GeomPH_Brg` | `Bridge_L4/MD_GeomPH_Brg.f90` | 几何 → PH ElemCtx |
| `MD_ContPH_Brg` | `Bridge_L4/MD_ContPH_Brg.f90` | 接触参数 → PH |
| `MD_ConstraintPH_Brg` | `Bridge_L4/MD_ConstraintPH_Brg.f90` | 约束 → PH |

**已废弃的文档/口语旧名（勿写入新合同路径）**：`MD_MatLib_PH_Brg`、`MD_Elem_PH_Brg`、`MD_LoadBC_PH_Brg`、`MD_Geom_PH_Brg`、`MD_Cont_PH_Brg`（下划线分段）— 对应上表 **无下划线** 的 `MODULE` 与 **`MD_*PH_Brg.f90`** 文件名。

---

## 2. L3→L5（`Bridge/Bridge_L5/`）

| `MODULE`（`USE` 名） | 源文件 | 职责摘要 |
|----------------------|--------|----------|
| `MD_AssemRT_Brg` | `Bridge_L5/MD_AssemRT_Brg.f90` | 装配 → RT |
| `MD_ContRT_Brg` | `Bridge_L5/MD_ContRT_Brg.f90` | 接触 → RT |
| `MD_ElemRT_Brg` | `Bridge_L5/MD_ElemRT_Brg.f90` | 单元 → RT |
| `MD_Int_Brg` | `Bridge_L5/MD_Int_Brg.f90` | Interaction / 耦合 → RT |
| `MD_KWRT_Brg` | `Bridge_L5/MD_KWRT_Brg.f90` | 关键字 → RT |
| `MD_LBCRT_Brg` | `Bridge_L5/MD_LBCRT_Brg.f90` | 载荷/BC → RT |
| `MD_Mesh_Brg` | `Bridge_L5/MD_Mesh_Brg.f90` | 网格 → RT (ID 映射 + 结构初始化) |
| `MD_Model_Brg` | `Bridge_L5/MD_Model_Brg.f90` | 模型 → RT |
| `MD_ModelRT_Brg` | `Bridge_L5/MD_ModelRT_Brg.f90` | 模型运行时 → RT |
| `MD_Out_Brg` | `Bridge_L5/MD_Out_Brg.f90` | 输出 → RT |
| `MD_UIRT_Brg` | `Bridge_L5/MD_UIRT_Brg.f90` | UI → RT |
| `MD_UniFldRT_Brg` | `Bridge_L5/MD_UniFldRT_Brg.f90` | 统一场 → RT |

**已废弃的文档旧名**：`MD_Assem_RT_Brg`、`MD_Interaction_RT_Brg`、`MD_KW_RT_Brg`、`MD_LoadBC_RT_Brg`、`MD_Model_RT_Brg`、`MD_UI_RT_Brg`、`MD_UniFld_RT_Brg` 等 — 与上表 **紧凑 `MODULE` 名** 及磁盘 **`MD_*RT_Brg.f90`** 不一致处，以本表为准。

---

## 3. 求解器桥（不在 `Bridge_L5/` 目录）

| `MODULE` | 源文件（相对 `L3_MD/`） | 说明 |
|----------|-------------------------|------|
| `MD_Solv_Mgr` | `Analysis/Solver/MD_Solv_Mgr.f90` | 求解器配置域；**`MD_Solver_Brg_*`** 等选路过程（原独立 `MD_Solv_Brg.f90` 已删除/并入） |

---

## 4. 相对路径前缀（合同引用）

- 自 `ufc_core` 根：`L3_MD/Bridge/…`  
- 自 `L3_MD/Bridge/`：`Bridge_L4/…`、`Bridge_L5/…`

---

---

## 5. 域内分散 Bridge 文件（非集中式，参考记录）

> 决策 (v4.0, 议题6): Bridge 文件长期归各域内管理。以下为各域已有的分散式 Bridge 文件，
> 不在集中式目录中但属于 L3 Bridge 体系。

| 域 | 源文件（相对 `L3_MD/`） | 模块名 | 目标层 | 状态 |
|----|------------------------|--------|--------|------|
| Part | `Part/MD_Part_Brg.f90` | `MD_Part_Brg` | 待定 | SKELETON |
| Model | `Model/MD_Model_Brg.f90` | `MD_Model_DomBrg` | 域内 | SKELETON (已重命名消除冲突) |
| Assembly | ~~`Assembly/MD_Asm_Brg.f90`~~ | ~~`MD_Asm_Brg`~~ | — | DELETED（空壳，桥接由 `Bridge_L5/MD_AssemRT_Brg` 承担） |
| Interaction | `Interaction/MD_Interaction_Brg.f90` | `MD_Interaction_Brg` | 待定 | SKELETON |
| Analysis | `Analysis/MD_Ana_Brg.f90` | `MD_Ana_Brg` | L6/Harness | ACTIVE |
| Field | ~~`Field/MD_Field_Brg.f90`~~ | ~~`MD_Field_Brg`~~ | — | **DELETED** (空骨架；Field 真源由 `MD_Field_Def/Mgr` 承担，L4 计算由 `PH_Field_*` 承担) |
| Constraint | ~~`Constraint/MD_Constr_Brg.f90`~~ | ~~`MD_Constr_Brg`~~ | — | **DELETED** (空骨架, 0 过程/消费者; L3→L4 由 `Bridge_L4/MD_ConstraintPH_Brg.f90` 承担) |
| Section | `Section/MD_Section_Brg.f90` | `MD_Section_Brg` | L4 | ACTIVE (M-S-E 兼容性) |
| Analysis | `Analysis/MD_Ana_Comp.f90` | `MD_Ana_Comp` | L4 | ACTIVE (含 Brg 验证过程) |
| KeyWord | `KeyWord/MD_KWAP_Brg.f90` | `MD_KWAP_Brg` | L6 | ACTIVE (L3→L6 重导出) |
| Boundary | `Boundary/MD_LBC_Brg.f90` | `MD_LBC_Brg` | L6 | ACTIVE (UF 类型) |
| Material | `Material/Bridge/MD_Mat_Brg.f90` | `MD_Mat_Brg` | API | ACTIVE (域 API 门面) |
| Material | `Material/Bridge/MD_Mat_Brg.f90` | `MD_Mat_Brg` | L4 | ACTIVE (PH 本构) |
| Material | `Material/Bridge/MD_MatRT_Brg.f90` | `MD_MatRT_Brg` | L5 | ACTIVE (高斯点调度) |
| Mesh | `Mesh/MD_Mesh_API.f90` | `MD_Mesh_API` | 查询 | ACTIVE |
| Output | `Output/MD_OutDP_Brg.f90` | `MD_OutDP_Brg` | L1 DP | ACTIVE |
| WriteBack | `WriteBack/MD_WB_Brg.f90` | `MD_WB_Brg` | L5→L3 | ACTIVE (反向回写) |

---

---

## 6. 命名异常记录

> 更新: 2026-04-26 (已修正)

无当前命名异常。历史异常 `RT_Mesh_Brg` 已确认为文档漂移——实际 MODULE 一直是 `MD_Mesh_Brg`，本表及 CONTRACT 已修正。

---

## 7. Bridge 域分类说明 (Partial Pillar v2.0)

Bridge **不再**视为独立的"半贯通柱"，而重新分类为**基础设施域 (Infrastructure Domain)**。

**理由**: Bridge 是跨层数据传递机制，不承载物理/数值语义，不具备 Desc/State/Algo/Ctx 四型结构。

**分类**: 基础设施域 — 与 L1_IF 的 SymTbl/DP/MemPool 同级。

**职责**: 
- 跨层数据格式转换 (L3→L4 Populate, L3→L5 Populate)
- 域间数据路由 (桥接模块)
- 向后兼容适配 (Legacy bridge)

**约束**:
- Bridge 模块的 `MODULE` 前缀应与**源层**一致 (如 L3 侧 Bridge 用 `MD_*`)
- `RT_Mesh_Brg` 为已知例外，不做重命名

## 8. H6 Coupling Bridge (v2.1)

`RT_MF_Brg.f90` (位于 `L5_RT/Solver/Coupling/`) 是 Coupling 域柱的 L3→L5 Populate Bridge:

| 过程 | 方向 | 说明 |
|------|------|------|
| `RT_MF_Brg_Populate` | L3→L5 | MD_Cpl_Desc → RT_MF_Coupling_Desc/Algo |
| `RT_MF_Brg_SyncState` | L3→L5 | 步转换时判断是否为耦合步 |

**注意**: 此 Bridge 文件位于 L5 侧 (`RT_MF_Brg`)，非 L3 Bridge 目录。因其职责是"将 L3 数据填入 L5 类型"，归属于 L5 Coupling 域。

---

*本文件为 **`BRIDGE_INDEX.md`** 权威索引；与 [`CONTRACT.md`](CONTRACT.md) §二、§六互链。*
