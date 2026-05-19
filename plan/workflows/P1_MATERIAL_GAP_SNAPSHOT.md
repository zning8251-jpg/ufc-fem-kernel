# P1 Material — 差距快照（Registry + Guardian）

> **更新**：2026-05-19 · **消费方**：wave3–wave5 · post-wave5 backlog

---

## 1. Registry

| 项 | 值 |
|----|-----|
| 命令 | `python UFC/tools/domain_procedure_registry_scan.py` |
| 输出 | `docs/03_Domain_Pillars/DomainProcedureRegistry/generated/`（**1067** 篇 `.md`） |
| 索引 | `generated/_REGISTRY_STATS.md` |

**P1 三层合同（G1）**：

| 层 | CONTRACT |
|----|----------|
| L3 | `ufc_core/L3_MD/Material/CONTRACT.md` |
| L4 | `ufc_core/L4_PH/Material/CONTRACT.md` |
| L5 | `ufc_core/L5_RT/Material/CONTRACT.md` |

---

## 2. Guardian 基线

### 2.1 `Plast/`

| 子树 | P0 | 备注 |
|------|-----|------|
| J2 脊索（wave3） | 0 | **merged** #1 |
| Hill / Barlat（wave5 PR-A） | 0 | **merged** #3 |
| Crystal（mat_id 266） | 0 | **W1b 1-slip Schmid**（W1a deprecated） |
| 全域 `--fail-on-p0` | P2 only | **P0/P1 cleared** — **merged** #7 |

### 2.2 `Dispatch/`

| 项 | 状态 |
|----|------|
| `guardian Dispatch --fail-on-p0` | 0 — **merged** #2 |
| `PH_MatEval` C2 按族迁出 | **merged** #9 + #10；门面 ~80 行 |

---

## 3. 波次台账

| change_id | 范围 | 状态 |
|-----------|------|------|
| `p1-material-wave3-plast-loc` | Plast J2 | **merged** #1 |
| `p1-material-wave4-dispatch-flow` | Dispatch SIO | **merged** #2 |
| `p1-material-wave5-plast-nonj2` | Hill/Barlat/Crystal Arg | **merged** #3 + #6 |
| `p1-material-wave5-mateval-arg` | PH_MatEval 文档 | **merged** #5 |
| `p1-material-plast-guardian-debt` | Plast P0/P1 + Chaboche Arg | **merged** #7 |
| `p1-material-orthotropic-eval-fix` | ortho Eval Arg | **merged** #8 |
| `p1-material-c2-mateval-split` | MatEval → family PointEval | **merged** #9 + #10 |

---

## 4. post-wave5 + W2 + NAME（2026-05-19）

| change_id / PR | 状态 |
|----------------|------|
| `p1-material-crystal-w2-multislip` #14+#16 | **merged** — W2a + W2-REF-01 harness |
| `p1-material-plast-name-debt` #17–#19 | **merged** — `guardian Plast` **P2=0** |
| P1 S7 签收 | [`P1_MATERIAL_S7_SIGNOFF.md`](P1_MATERIAL_S7_SIGNOFF.md) |

### 4.1 Plast guardian（签收基线）

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast
# 2026-05-19 post-#19: P0=0, P2=0
```

---

## 5. Roll-forward（P1 柱后）

1. ~~P1 S7 签收~~（2026-05-19）
2. **P2** [`p2-element-pr01-seam-doc`](../changes/p2-element-pr01-seam-doc/) — PR01 接缝（与 P1 槽位衔接）
3. W2 可选：一致塑性切线 `ddsdde`；Registry 266 收紧

*维护：合并后追加 `（PR #___ / 日期）`。*
