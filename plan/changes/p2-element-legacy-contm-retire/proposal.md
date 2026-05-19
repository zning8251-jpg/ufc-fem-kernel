# Change: p2-element-legacy-contm-retire

## Why

P2 **G6 红**：`PH_Elem_Contm` / `PH_ElemContm_Ops` 含 `USE MD_*`，与柱级「热路径零 L3」冲突。全量删除不现实；须 **隔离 + 分阶段销项**，且 **不阻塞** 已交付的 PR01 金线（#21）。

## What Changes (wave G6-W0)

| 交付物 | 说明 |
|--------|------|
| `Element/Legacy/LEGACY_CONTM_BOUNDARY.md` | 金线 vs legacy 调用边界、G6-W0/W1/W2 |
| `tools/verify_element_golden_path_no_contm.py` | 金线锚点静态门控 |
| harness profile `p2-element-golden-seam` | CI/本地可复验 |
| plan 包 + `P2_ELEMENT_GAP_SNAPSHOT` G6 分阶段 | 不宣称 P2 S7 |

## What NOT

- 删除 `PH_Elem_Contm` / 重写 `PH_ElemContm_Ops`（→ G6-W2）
- `Solid*_Def` 全面脱离 `Calc_Continuum*`（→ G6-W1）
- `RT_Elem_Proc` SIO（→ `p2-element-l5-rt-elem-proc-sio`）

## Preconditions

- #21 merged：`material-route-audit` + `ke-arg-align`
- PR01 金线文档：`plan/changes/p2-element-pr01-seam-doc/`

## Links

- [`contract-l4-element`](../contract-l4-element/design.md) §4
- [`P2_ELEMENT_GAP_SNAPSHOT.md`](../../workflows/P2_ELEMENT_GAP_SNAPSHOT.md)
