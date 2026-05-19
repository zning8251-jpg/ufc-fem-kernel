# Change: p2-element-l5-rt-elem-proc-sio

## Why

P2 **G5 黄**：`RT_Elem_Proc` 定义 SIO `Elem_Ke_In/Out`，但字段与生产金线 `PH_Element_Compute_Ke_Arg`（`RT_Asm_Solv`）不对齐；`RT_ElemDispatch_Brg` 曾误用 `ke_in%u` 作材料参数。须 **文档化 + 类型对齐 + 桥接填充**，且不改变 `RT_Asm_Solv` 主路径。

## What Changes

| 交付物 | 说明 |
|--------|------|
| `Elem_Ke_In` 扩展 | `elem_idx` / `l3_elem_idx` / `mat_pt_idx` / `nDof` / `mat_props_in` |
| `RT_Elem_KeIn_ApplyAsmArg` | 从 `PH_Element_Compute_Ke_Arg` 填充 SIO 包 |
| `RT_Elem_Brg_ComputeKe` | 使用 `mat_props_in` 调用 `Compute_Ke` |
| `L5_RT/Element/CONTRACT.md` § SIO | 字段对照表 |
| `tools/verify_rt_elem_ke_in_align.py` | 静态字段门控 |

## What NOT

- 替换 `RT_Asm_Solv` 金线装配循环
- 实现完整 `RT_ElemDispatcher` 生产路由（仍骨架）

## Preconditions

- #21 `ke-arg-align`、#23 legacy-contm、#24 shell Ke 已合 `main`

## Links

- [`contract-l4-element`](../contract-l4-element/design.md) §4
- [`L4_PH/Element/CONTRACT.md`](../../../ufc_core/L4_PH/Element/CONTRACT.md) `PH_Element_Compute_Ke_Arg` 表
