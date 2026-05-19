# Design: p2-element-pr01-seam-doc

> **Status**: **ACTIVE**（2026-05-19）— 接缝文档 + guardian 基线

## 1. 金线（锁定）

```text
L3 MD_Mesh / MD_Mat Desc
  → PH_L4_Populate_*（冷路径）→ elem_to_mat_map / mat_pt_idx
  → RT_Asm_GlobalStiffness（L5）
       → RT_Asm_Brg_ElemMatPtIdx(iElem)
       → RT_Asm_Solv_KeArg_AttachMatProps(ke_arg)   ! slot_pool props → mat_props_in
       → ph_layer%element%Compute_Ke(ke_arg)       ! L4 金线
  → RT_Asm Triplet/CSR
```

**材料真源**：`g_ufc_global%ph_layer%material%slot_pool(mat_pt_idx)`（与 [`L4_PH/Material/CONTRACT.md`](../../../ufc_core/L4_PH/Material/CONTRACT.md) R2 一致）。

## 2. `PH_Element_Compute_Ke_Arg`（合同 ↔ 实现）

| 字段 | 方向 | L5 填充（`RT_Asm_Solv.f90`） |
|------|------|------------------------------|
| `elem_idx` | IN | 单元循环索引 `iElem` |
| `l3_elem_idx` | IN | 同 `iElem`（L3 对齐） |
| `mat_pt_idx` | IN | `RT_Asm_Brg_ElemMatPtIdx(iElem)` |
| `nDof` | IN | 单元 DOF 数 |
| `mat_props_in` | IN | `RT_Asm_Solv_KeArg_AttachMatProps` 从 `slot_pool` 拷贝 |
| `evo%Ke` | INOUT | L5 预分配；L4 写入 |
| `status` | OUT | `init_error_status` 后检查 |

真源 TYPE：`ufc_core/L4_PH/Element/PH_Elem_Def.f90`（`PH_Element_Compute_Ke_Arg`）。

## 3. 源码锚点（`main` 基线）

| 步骤 | 位置 | 说明 |
|------|------|------|
| Ke 循环 | `RT_Asm_Solv.f90` ~1875–1888 | 填 `ke_arg`、`AttachMatProps`、`%Compute_Ke` |
| 材料附着 | `RT_Asm_Solv.f90` ~3499–3515 | `RT_Asm_Solv_KeArg_AttachMatProps` |
| L4 入口 | `PH_Elem_Domain.f90` | `%Compute_Ke` TBP |
| 材料路由 | `Shared/PH_Elem_MaterialRoute.f90` | IP 级 `mat_pt_idx` / `RT_Mat_Dispatch` |
| Mat 门面 | `Material/Dispatch/PH_MatEval.f90` | C2 薄门面（接缝侧材料 Eval） |

## 4. Populate ↔ `mat_pt_idx`

| 项 | 约定 |
|----|------|
| 冷路径 | `PH_L4_Populate_Element` / `PH_L4_Populate_Material` 写入映射 |
| 热路径 | **禁止** IP 内遍历 L3 网格库；仅 `mat_pt_idx` + slot |
| 缺口登记 | 若 `mat_pt_idx<=0` → `IF_STATUS_INVALID`（族内核与 MaterialRoute） |

## 5. `load_magn_in` vs `F_ext`

与 [`L4_PH/Element/CONTRACT.md`](../../../ufc_core/L4_PH/Element/CONTRACT.md) L157、`L5_RT/Assembly/CONTRACT.md` §5.4 一致：已进入 `F_ext` 的载荷 **不得** 再在单元 `load_magn_in` 重复计入。

## 6. Guardian 接缝基线

见 [`PR01_GUARDIAN_AUDIT.md`](PR01_GUARDIAN_AUDIT.md)。**门控**：锚点文件 **`--fail-on-p0`**；全树 P0 不在本 change 范围。

## 7. 后续 change（本包之后）

| change_id | 依赖本包 |
|-----------|----------|
| `p2-element-material-route-audit` | 是 |
| `p2-element-ke-arg-align` | 是 |
| `p2-element-legacy-contm-retire` | 是 |
