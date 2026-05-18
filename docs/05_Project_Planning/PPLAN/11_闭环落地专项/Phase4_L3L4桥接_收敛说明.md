# Phase 4 前提：L3↔L4 双桥接收敛说明

> **版本**: v1.0 · **日期**: 2026-04-25  
> **状态**: ACTIVE（实现与合同对齐的锚点）  
> **关联**: [`L3_MD_L4_PH_联通契约与缺陷分析.md`](../05_实施指南/L3_MD_L4_PH_联通契约与缺陷分析.md) · [`UFC_端到端计算流主链.md`](../06_核心架构/UFC_端到端计算流主链.md)

---

## 1. 问题陈述（历史）

| 缺陷 | 说明 |
|------|------|
| 越权写回 | `PH_Brg_ElementStiffAssembly` 曾直接驱动单元刚度组装并交织 L3 几何桥，违反「Bridge = 无默认热路径计算」 |
| 双桥接 | **L3 推**：`MD_MatLibPH_Brg`（`MD_PH_RouteToConstitutive_*`）与 **L4 拉**：Populate + `PH_BrgL3` 查询并存，职责重叠 |

---

## 2. 收敛目标（计划口径）

1. **Populate 单向**：以 **L4 侧** `PH_L4_*_Populate` 为主，从 L3 **只读**拉取 Desc，填充 `PH_*_Ctx` / slot。  
2. **删除/废弃 L3 侧热路径推路径**：`MD_PH_RouteToConstitutive_Idx` **不得**出现在装配/材料 IP 热路径；模块保留 **LEGACY** 供校验与非热路径迁移期使用（见 `MD_MatLibPH_Brg.f90` 头注释，计划 v2027-Q1 移除）。  
3. **白名单写回**：任何 L3 `State` 更新仅经 **`L5_RT/WriteBack`**。

---

## 3. 实现状态（仓库真源 · 2026-04-25）

| 项 | 状态 | 证据 |
|----|------|------|
| G4 越权组装 | **已封堵** | `PH_BrgL3.f90`：`PH_Brg_ElementStiffAssembly` 返回 `IF_STATUS_INVALID`，提示迁移 `PH_Element_Domain%Compute_Ke` |
| L3 推桥热路径 | **已标注废弃** | `MD_MatLibPH_Brg.f90`：声明 **LEGACY for hot path**；`rg` 无其它 `USE` 调用 `MD_PH_RouteToConstitutive_Idx` |
| L4 只读查询 | **保留** | `PH_Brg_GetMaterialResponse_*`、`PH_Brg_GetNodeCoords_Idx` 等只读辅助 |
| `PH_Brg_UpdateElementState` | **无写 L3 语义** | 当前为占位成功返回；**禁止**在此恢复直写 |

---

## 4. 后续工作（技术债登记）

- [ ] 完全删除 `MD_MatLibPH_Brg` 中热路径 API（迁移窗口结束后）。  
- [ ] Harness：对 `PH_Brg_ElementStiffAssembly` 调用做静态扫描门禁。  
- [ ] 歧义点 B（收敛判断落层）见主链文档 §3。

---

*本页为 Phase 4「前提」验收的文字锚点；与 `L3_MD/Bridge/CONTRACT.md`、`L4_PH/Bridge/CONTRACT.md` 互链。*
