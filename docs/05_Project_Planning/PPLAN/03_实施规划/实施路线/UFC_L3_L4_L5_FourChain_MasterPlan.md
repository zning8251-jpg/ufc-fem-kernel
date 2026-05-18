# UFC L3↔L4↔L5 四链总图与落地清单

**版本**: 0.1  
**日期**: 2026-03-19  
**目标**: 将模型数据（L3）→ 物理计算（L4）→ 运行时求解（L5）在 **材料 / 单元 / 载荷边界 / 接触** 四条垂直链上，按 **理论链 / 逻辑链 / 计算链 / 数据链** 逐项闭合。

---

## 1. 总目标映射

| # | 用户目标 | 四链要点 | 权威入口（代码） |
|---|----------|----------|------------------|
| 1 | L3 材料 ↔ L4 材料，L5 调用 | Reg：`PH_Mat_Reg_*`；ctx：`PH_UMAT_Context`；桥：`MD_MatLib_PH_Brg`；调度：`PH_Mat_Dispatch_UMAT_ByMatId` | `PH_Mat_Reg_Core.f90`, `PH_Mat_Unified_Dispatch.f90`, `PH_Mat_Domain_Core.f90`, `RT_Brg_PH_Mat.f90` |
| 2 | L3 单元 ↔ L4 单元，UEL→UMAT | 网格 `ELEM_*` → `PH_Elem_Reg_*` → `PH_Element_Domain_Core`；用户元 `PH_Elem_UEL_Core` + `RT_UEL_API` | `MD_Elem_Core.f90`, `PH_Elem_Reg_Core.f90`, `PH_Element_Domain_Core.f90`, `MD_Elem_PH_Brg.f90` |
| 3 | L3 载荷边界 ↔ L4，L5 施加 | L3 描述 → `MD_LoadBC_PH_Brg` → `PH_*_Cache` → `RT_Ldbc_*` / `RT_Asm_*` | `MD_LoadBC_DomainTypes.f90`, `MD_LoadBC_PH_Brg.f90`, `RT_Ldbc_Apply_Core.f90`, `RT_Asm_Solv.f90` |
| 4 | L3 接触 ↔ L4，L5 装配 | L3 `MD_ContactProperty_Type` / pair → **`MD_Cont_PH_FillParams_FromMD`** → `PH_Contact_Params` → `PH_Cont_Domain` → `MD_Cont_RT_Brg` | `MD_Cont_PH_Brg.f90`, `PH_Cont_Domain.f90`, `MD_Cont_RT_Brg.f90`, `RT_Contact_Domain_Core.f90` |

---

## 2. 完成度自检（滚动更新）

- [x] 材料：Registry + `props_schema` 脚本；**统一调度桩** `PH_Mat_Dispatch_UMAT_ByMatId`
- [x] 单元：`Compute_Ke` / `Compute_Fe` 增加 **C3D4**、**C3D10**（10 节点四面体）、**CPS4**（`elem_type_cache` 150–171 与 **CPE4** 区分）；C3D8/CPE4 保留
- [x] 载荷：`RT_Asm_Solv` BC 分支使用 **`MD_LoadBC_DomainTypes` 具名常量**（与魔法数 1/2/3 对齐）  
- [x] 载荷：`MD_LoadBC_Map` — `MD_LoadBC_ToLdbcLoadType` / 反向映射（见 `UFC_LoadBC_Enum_Mapping.md`）
- [x] 接触：**L3→L4 桥** `MD_Cont_PH_Brg` + 字段契约文档
- [ ] 全量 73 本构 / 191 单元 / 全部载荷关键字：按迭代继续绑定
- [ ] 回归算例：见 `docs/verification/` 与 `tests/harness/`

---

## 3. 相关文档

- [UFC_Chain_Rollout_Material_Element_LoadBC_Contact.md](UFC_Chain_Rollout_Material_Element_LoadBC_Contact.md)  
- `Material_Constitutive_Unified_Design.md`（历史计划稿，当前工作区未收录）
- [UFC_Ldbc_Layer_Map.md](../../07_设计文档/UFC_Ldbc_Layer_Map.md)  
- [UFC_LoadBC_Enum_Mapping.md](../../07_设计文档/UFC_LoadBC_Enum_Mapping.md)（含 `MD_LoadBC_Map.f90`）  
- [UFC_Contact_Field_Contract.md](../../07_设计文档/UFC_Contact_Field_Contract.md)  
- `MD_LoadBC_Load_Parse_TODO.md`（历史 TODO，当前工作区未收录）  
- `UFC_Verification_Backlog.md`、`UFC_PatchTest_Procedure.md`（当前工作区未收录）
