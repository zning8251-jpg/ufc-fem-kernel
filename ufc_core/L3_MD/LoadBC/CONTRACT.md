# LoadBC（LoadBC）域级合同卡（L3_MD）

- **层级**：L3_MD
- **域名**：Load / Boundary / IC — **模型定义层**
- **缩写**：Load（纯载荷）、BC（纯边界条件）
- **目录**：`ufc_core/L3_MD/LoadBC/`
- **职责**：载荷、边界、初值的 **Desc**（类型、幅值引用、作用集等）；**不在 L3 做施加算法**（施加在 L4 `PH_Ldbc` / L5）。
- **四型配置**：
  - **Desc**：`MD_Load_Desc`（`MD_Load_Def.f90`）、`MD_BC_Desc`（`MD_BC_Def.f90`）
  - **State**：`MD_Load_State` / `MD_BC_State`
  - **Algo**：`MD_Load_Algo` / `MD_BC_Algo`
  - **Ctx**：`MD_Load_Ctx` / `MD_BC_Ctx`

### 来源说明（Phase 3 重构）

本域在 Phase 3 重构中从 `L3_MD/Boundary/` 剥离为独立域。详见：
- `L3_MD/Boundary/`：旧位置，文件标记 `! DEPRECATED`，为向后兼容保留
- `L3_MD/LoadBC/`：新位置

2026-05-08 进一步严格拆分为 Load/BC 两柱：
- `MD_LoadBC_Def.f90`（DEPRECATED）→ `MD_Load_Def.f90` + `MD_BC_Def.f90`

### 核心模块

| 模块 | 角色 |
|------|------|
| `MD_Load_Def.f90` | 纯 Load 四型（`MD_Load_Desc`/`State`/`Algo`/`Ctx` + `MD_Load_Domain`） |
| `MD_BC_Def.f90` | 纯 BC 四型（`MD_BC_Desc`/`State`/`Algo`/`Ctx` + `MD_BC_Domain`） |
| `MD_LoadBC_Def.f90` | **DEPRECATED** — 旧混合四型（引用应迁至 Load/BC 两柱） |
| `MD_LBC_Def.f90` | **DEPRECATED** — 旧编号版（引用应迁至 Load/BC 两柱） |

### 域缩命名

遵循命名规范 v2.0（R-10）：
- 模块前缀：`MD_Load_*` / `MD_BC_*`
- 四型名：`MD_Load_Desc` / `MD_BC_Desc` / `MD_Load_Algo` / `MD_BC_Ctx`（R-09：无 `Base`）

### Cross-references

- **域柱**: P4 LoadBC（贯通柱 L3/L4/L5）
- **L4 合同**: `L4_PH/LoadBC/CONTRACT.md`
- **L5 合同**: `L5_RT/LoadBC/CONTRACT.md` (v2.0)
- **旧位置 Boundary 合同**: `L3_MD/Boundary/CONTRACT.md`
- **过程算法叙事（根 stub）**：[`LoadBC_Procedure_Algorithm.md`](../../../REPORTS/LoadBC_Procedure_Algorithm.md) → [`archive/LoadBC_Procedure_Algorithm.md`](../../../REPORTS/archive/LoadBC_Procedure_Algorithm.md)；[Registry 对账说明](../../../docs/03_Domain_Pillars/DomainProcedureRegistry/README.md)
