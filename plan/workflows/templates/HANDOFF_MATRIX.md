# S1–S7 交接矩阵（域柱改造）

> **用法**：每完成一个 Step，由 **Outgoing** 填「交出」列，**Incoming** 填「接收」列并签字（或 PR Reviewer）。  
> **规范**：[`UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md) §4、§6。

**任务**：`task_id` = _______________　**域柱**：P__ / H__　**change_id**：_______________

---

## S1 → S2（设计锚定 → 现状快照）

| 项 | 交出（S1 完成） | 接收（S2 开始） |
|----|-----------------|-----------------|
| **合同** | `CONTRACT.md` 四型表+三轴表已更新 | 已读三层 CONTRACT |
| **裁剪** | DELEGATED/RETAINED 与蓝图一致 | 扫描范围 = 合同文件清单 |
| **阻塞** | 无未决开放问题 | 若有 OQ，已写入 `design.md` |

Outgoing: ______ 日期: ______　Incoming: ______ 日期: ______

---

## S2 → S3（快照 → 差距与计划）

| 项 | 交出 | 接收 |
|----|------|------|
| **generated/** | scan 时间戳 + `_REGISTRY_STATS` | 已打开本域镜像 md |
| **差距表** | Top N stem + G1–G6 预判 | 已写入 `change_id` tasks.md |
| **TASK_RUN** | S2 = done | S3 = in_progress |

Outgoing: ______　Incoming: ______

---

## S3 → S4（计划 → L3 数据面）

| 项 | 交出 | 接收 |
|----|------|------|
| **change 包** | `change-package validate` rc=0 | 仅改 tasks.md §L3 文件 |
| **范围** | 无 L4/L5 实现混入本 MR | `USE` 无 L4/L5 |
| **TASK_RUN** | References 完整 | S4 = in_progress |

Outgoing: ______　Incoming: ______

---

## S4 → S5（L3 → L4）

| 项 | 交出 | 接收 |
|----|------|------|
| **L3** | Def/Reg/Brg touched 门禁绿 | Populate 入口与 L3 合同一致 |
| **Bridge** | `BRIDGE_INDEX` 已更新（若改 Bridge） | 无第二 Populate 路径 |
| **证据** | G2/G5 行号 | S5 = in_progress |

Outgoing: ______　Incoming: ______

---

## S5 → S6（L4 → L5）

| 项 | 交出 | 接收 |
|----|------|------|
| **L4** | Core/Eval/Dispatch 接口冻结 | L5 只编排不重复本构 |
| **热路径** | Ctx 零 ALLOCATE 已审查 | Guardian HOT 无新 P0 |
| **Args** | Eval 入口 `*_Arg` 或合同例外 | SIO 与 A9 一致 |

Outgoing: ______　Incoming: ______

---

## S6 → S7（L5 → 验收）

| 项 | 交出 | 接收 |
|----|------|------|
| **L5** | `*_Proc` 与六参/书签文档化 | WriteBack 白名单未扩 |
| **全层** | touched 路径 discipline+guardian+naming 绿 | 准备 G1–G6 表 |
| **PR** | 五元声明草稿 | S7 = in_progress |

Outgoing: ______　Incoming: ______

---

## S7 → 归档（验收 → 下一柱）

| 项 | 交出 | 接收 |
|----|------|------|
| **G1–G6** | 全绿 PR 附件 | 已合并 |
| **07** | 对应域行 ☑ + PR# | Maintainer 确认 |
| **TASK_RUN** | 全 Step done | 迁入 `plan/archive/` 或开新 task_id |
| **change** | 可归档至 `plan/changes/archive/` | 新柱新 change_id |

Outgoing: ______　Incoming: ______

---

## 偏离 / 回退

| 条件 | 回退到 | 动作 |
|------|--------|------|
| Guardian P0 无法在本 MR 修复 | S3 | 缩 scope 或拆 change_id |
| 合同与实现冲突 | S1 | CONTRACT PR 先行 |
| 夹带第二域柱 | S3 | 拆 PR + 重置 TASK_RUN pillar_id |
