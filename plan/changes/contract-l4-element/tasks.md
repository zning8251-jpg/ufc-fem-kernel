# Tasks: contract-l4-element

> **Phase**: S1–S3（plan / contract）

## 0. 闸门

- [x] `PILLAR_ROLLOUT_ROADMAP` 登记 P2 `contract-l4-element`
- [x] `change-package validate --strict`
- [x] S2 快照 `P2_ELEMENT_GAP_SNAPSHOT.md` 落盘

## 1. S1 — 合同审计

- [x] 1.1 完成 `design.md` §2 五项勾选（见 `S1_AUDIT_20260519.md`）
- [ ] 1.2 L3 `Element/Mesh/CONTRACT.md` 与 L4 §Populate 无矛盾
- [ ] 1.3 Material R2 ↔ Element 材料路由交叉引用

## 2. S2 — 差距快照

- [x] 2.1 创建 `plan/workflows/P2_ELEMENT_GAP_SNAPSHOT.md`（P2-G1–G6）
- [ ] 2.2 链接 `UFC_L345_形式对齐域级检查表` P2 节

## 3. S3 — change 包（本目录）

- [x] 3.1 `proposal.md` / `design.md` / `tasks.md`
- [x] 3.2 `specs/contract-l4-element/spec.md`
- [x] 3.3 `plan/tasks/contract-l4-element/TASK_RUN.md`

## 4. 交付（本 change 范围止于此）

- [x] PR：`docs(plan): contract-l4-element S1–S3` → `main`（#15）
- [ ] 归档 TASK_RUN；在 `L3L4L5_MASTER_PLAN` C3 行标 **S3 done**

## 5. 后续（out of scope）

- [ ] 开 `p2-element-pr01-seam-doc` 实现波次
- [ ] P2 柱 S7 全绿（依赖多个实现 MR）
