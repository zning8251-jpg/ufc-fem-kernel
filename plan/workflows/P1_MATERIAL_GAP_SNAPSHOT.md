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
| Crystal stub（wave5 PR-B） | 0 | Arg 脊索；实装另开 change |
| 全域 `--fail-on-p0` | **>0** | Chaboche + 存量 — **post-wave5 清债** |

### 2.2 `Dispatch/`

| 项 | 状态 |
|----|------|
| `guardian Dispatch --fail-on-p0` | 0 — **merged** #2 |
| `PH_MatEval` 文档化 | PR #5 mateval |

---

## 3. 波次台账

| change_id | 范围 | 状态 |
|-----------|------|------|
| `p1-material-wave3-plast-loc` | Plast J2 | **merged** #1 |
| `p1-material-wave4-dispatch-flow` | Dispatch SIO | **merged** #2 |
| `p1-material-wave5-plast-nonj2` | Hill/Barlat/Crystal Arg | **merged** #3 + #6 |
| `p1-material-wave5-mateval-arg` | PH_MatEval 文档 | **merged** #5 |

---

## 4. Roll-forward

1. ~~wave3–5 合并 + `plan/tasks` 归档~~（2026-05-19 完成）
2. **Plast 清债** · **C2 PH_MatEval** · **Crystal 实装** — 见 [`p1-material-post-wave5-backlog.md`](../backlog/p1-material-post-wave5-backlog.md) §4

*维护：合并后追加 `（PR #___ / 日期）`。*
