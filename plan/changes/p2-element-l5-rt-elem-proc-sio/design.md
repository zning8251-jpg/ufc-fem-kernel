# Design: p2-element-l5-rt-elem-proc-sio

> **Status**: ACTIVE（2026-05-19）

## 1. 双路径

| 路径 | 入口 | 用途 |
|------|------|------|
| **金线** | `RT_Asm_Solv` → `PH_Element_Compute_Ke_Arg` → `PH_Elem_Domain%Compute_Ke` | 生产刚度装配 |
| **SIO 试验** | `RT_ElemDispatch_Brg` → `Elem_Ke_In` → `PH_ElemKeDispatch%Compute_Ke` | G5 对偶、单测/探针 |

SIO 路径 **不得** 在 L5 Assembly 热循环中替代金线；仅保证类型与填充契约一致，便于后续 `RT_ElemDispatcher` 收敛。

## 2. 字段对照（Ke）

| `PH_Element_Compute_Ke_Arg` | `Elem_Ke_In` | 填充 |
|-----------------------------|--------------|------|
| `elem_idx` | `elem_idx` | `RT_Elem_KeIn_ApplyAsmArg` |
| `l3_elem_idx` | `l3_elem_idx` | 同上 |
| `mat_pt_idx` | `mat_pt_idx` | 同上 |
| `nDof` | `nDof` | 同上 |
| — | `coords` | 指针 → 调用方 `TARGET` 缓存 |
| — | `u` | 指针 → 单元位移（可选） |
| `mat_props_in` | `mat_props_in` | 拷贝（`AttachMatProps` 后） |
| `evo%Ke` | — | 仅金线；SIO 用 `Elem_Ke_Out%Ke` |

## 3. Harness

```text
python tools/verify_rt_elem_ke_in_align.py
python ufc_harness/run_harness.py tst --case p2-element-golden-seam
```
