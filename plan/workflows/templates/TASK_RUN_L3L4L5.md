# TASK_RUN — `<task_id>`

> **模板**：[`plan/workflows/templates/TASK_RUN_L3L4L5.md`](TASK_RUN_L3L4L5.md)  
> **规范**：[`UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md)  
> **生成**：`python ufc_harness/run_harness.py agent-task init --session <task_id> --goal "…"` 后合并本节。

---

## Meta

| 字段 | 值 |
|------|-----|
| **task_id** | `<task_id>` |
| **pillar_id** | `P1` / `P2` / … / `H1`（仅一个） |
| **wave** | `W0` / `波次0` / `波次1` / `波次2` |
| **change_id** | `plan/changes/<change_id>/` 或 `N/A` |
| **owner** | |
| **created** | YYYY-MM-DD |

---

## Goal（可验收一句话）

（例：完成 P1 Material 柱 S5 L4 Dispatch 与 `PH_Mat_Def` 四型对齐，并通过 G1–G6。）

---

## References（上下文 — 换会话先读此处）

| # | 路径 | 用途 |
|---|------|------|
| 1 | `ufc_core/L3_MD/<Domain>/CONTRACT.md` | L3 合同 SSOT |
| 2 | `ufc_core/L4_PH/<Domain>/CONTRACT.md` | L4 合同 |
| 3 | `ufc_core/L5_RT/<Domain>/CONTRACT.md` | L5 合同 |
| 4 | `docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md` §P? | G1–G6 |
| 5 | `plan/changes/<change_id>/design.md` | 方法论映射 |
| 6 | `docs/03_Domain_Pillars/DomainProcedureRegistry/generated/...` | 现状快照 |

---

## 七步工序子任务

| Step | 名称 | state | 证据（路径 / rc） |
|------|------|-------|-------------------|
| S1 | 设计锚定 | pending | |
| S2 | 现状快照 | pending | |
| S3 | 差距与计划 | pending | |
| S4 | L3 数据面 | pending | |
| S5 | L4 计算面 | pending | |
| S6 | L5 编排面 | pending | |
| S7 | 验收闭环 | pending | |

**state**：`pending` | `in_progress` | `done` | `blocked`

---

## G1–G6 结果（S7 填写）

| 检查项 | 结果 | 证据 |
|--------|------|------|
| G1 | | |
| G2 | | |
| G3 | | |
| G4 | | |
| G5 | | |
| G6 | | |

---

## PR 主轴声明（复制到 PR 描述）

- **层**：L3_MD / L4_PH / L5_RT（勾选）
- **域**：`ufc_core/...`
- **合同**：改 / 不改（理由）
- **Bridge**：改 / 无
- **SIO**：改 / 无（Principle #14 说明）

---

## Harness Log

```text
# 每批 touched 后追加
python ufc_harness/run_harness.py discipline verify --touch-path ...
python ufc_harness/run_harness.py guardian ufc_core/... --fail-on-p0
python ufc_harness/run_harness.py naming ufc_core/...
# rc=0 日期
```

---

## Next action（只写一步）

（例：完成 S2 — 跑 registry scan 并填差距表前 10 行。）

---

## Handoff notes

| 自 Step | 至 Step | 交接人 | 日期 | 阻塞项 |
|---------|---------|--------|------|--------|
| | | | | |

---

## Log（3–5 行/子任务摘要）

- YYYY-MM-DD：
