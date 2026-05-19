# P1 Material — 柱级 S7 签收（2026-05-19）

> **change_id 收尾**：post-wave5 #7–#13 · crystal W2 #14–#16 · NAME #17–#19  
> **形式对齐真源**：[`UFC_L345_形式对齐域级检查表_P1-P6.md`](../../docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md) § P1

---

## G1–G6 签收表

| # | 检查行 | 结果 | 证据（PR / 路径） |
|---|--------|------|-------------------|
| P1-G1 | L3 合同四型 + 族矩阵 | **绿** | `L3_MD/Material/CONTRACT.md`；Populate 金线 wave4 #2 |
| P1-G2 | L3/L4 四型 Def | **绿** | `MD_Mat_Plast_Def` · `PH_Mat_Elas_Def` · `PH_Mat_Plast_Def` |
| P1-G3 | L4 塑性 SIO | **绿** | `PH_Mat_Plast_Eval.f90`（`PH_Mat_Plast_Eval_IP_Incr` #19） |
| P1-G4 | 塑性过程名 | **绿** | `guardian Plast` **P2=0**（#17–#19 NAME）；Crystal W2a #14 |
| P1-G5 | L5 路由 DEF | **绿** | `RT_Mat_Def` / `RT_Mat_Plast_Def` / `RT_Mat_Elas_Def` |
| P1-G6 | 旧 inp/out | **黄** | `deprecated/` 与 CONTRACT 遗留节登记；不阻塞 P1 柱叙事 |

**柱级结论**：P1 Material **S7 签收** — 生产热路径（Dispatch 门面、Plast 脊索、Crystal W1b/W2a）已交付；G6 遗留随 deprecated 专项关闭。

---

## Harness 闸门（签收日）

| 命令 | 结果 |
|------|------|
| `guardian Plast/` | P0=0，P2=0 |
| `guardian PH_Mat_Plast_Crystal_Core.f90` | P0=0 |
| `tools/verify_crystal_w2_ref01.py` | PASS |
| `change-package validate`（W2 / NAME / crystal-impl） | OK |

---

## 归档

| task_id | 位置 |
|---------|------|
| `p1-material-plast-name-debt` | `plan/archive/p1-material-plast-name-debt/` |
| `p1-material-crystal-w2-multislip` | `plan/archive/p1-material-crystal-w2-multislip/` |
