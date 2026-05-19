# Design 片段 — 方法论映射（粘贴到 `plan/changes/<change_id>/design.md`）

> **模板**：复制本节到变更包 `design.md` 的 **Methodology to UFC mapping** 段。  
> **规范**：[`UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md)

---

## Scope

| 项 | 值 |
|----|-----|
| **pillar_id** | P_ / H_ |
| **layers** | L3_MD / L4_PH / L5_RT |
| **domain path** | `ufc_core/...` |
| **wave** | W_ / 波次_ |

---

## Methodology to UFC mapping (normative for this change)

| 方法论项 | 本变更 UFC 落点 | 验收挂钩 |
|----------|-----------------|----------|
| Desc | （TYPE / 文件） | G2, 合同四型表 |
| State | | G2, WriteBack 白名单 |
| Algo | | G2 |
| Ctx | | G2, 热路径零分配 |
| Args | | G3, SIO skill |
| 嵌套/并列/主从 | | CONTRACT 主从表 |
| 空间维 Loc/Glb | | G4, 过程登记表 |
| 时间维 Init/Step/Incr/Iter | | G4 |
| 动作维 Populate/Eval/… | | G4, Populate 金线 |

---

## Decisions

1. **Pilot boundary**：（本 change 文件清单；扩范围须新 change_id）
2. **SSOT**：（域 `CONTRACT.md` 路径）
3. **SIO**：（新/改 `*_Arg`、`*_Proc` 清单）

---

## Acceptance (linked)

| 级别 | 命令/工件 | 通过条件 |
|------|-----------|----------|
| L-形式 | G1–G6 | PR 附件全绿 |
| L-合同 | A4, A7–A11 | `07` 行可勾 |
| L-物理 | （测试命令） | C 列 / audit |

---

## Open Questions

- 

---

## Alternatives considered

- 
