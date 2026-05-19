# Change: p2-element-legacy-contm-g6w3 (plan)

## Why

G6-W2 已将 `USE MD_*` 收到 `Legacy/PH_Elem_Contm_Brg.f90`；**`PH_ElemContm_Ops.f90`**（~4k 行）仍为 L4 `Element/` 根目录实现体且大量 `USE MD_*`，阻碍 P2-G6 全绿与柱级 S7。

## What Changes (planned waves)

| 阶段 | 目标 |
|------|------|
| **G6-W3a** | 物理迁移：`PH_ElemContm_Ops.f90` → `Element/Legacy/`；构建/依赖路径更新 |
| **G6-W3b** | 削减 Ops 内 `USE MD_*`：改 `UF_*` / `PH_Elem_*` 族类型；保留 `Calc_Continuum*` 回退 |
| **G6-W3c** | Guardian：`L4_PH/Element/`（除 Legacy）零 `USE MD_*` 门控 |

## What NOT

- 删除 `Calc_Continuum*` 回退（仍服务 `Solid*_Def` 与 Bridge 温路径）
- 改动 `RT_Asm_Solv` 金线

## Preconditions

- `p2-element-legacy-contm-retire` G6-W0–W2 已合（#23）
- `verify_element_golden_path_no_contm` + `verify_element_contm_legacy_boundary` 绿

## Links

- [`LEGACY_CONTM_BOUNDARY.md`](../../../ufc_core/L4_PH/Element/Legacy/LEGACY_CONTM_BOUNDARY.md)
- [`p2-element-legacy-contm-retire`](../p2-element-legacy-contm-retire/design.md)
