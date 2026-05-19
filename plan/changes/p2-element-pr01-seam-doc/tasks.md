# Tasks: p2-element-pr01-seam-doc

> **Phase**: S4 文档波次（PR01 接缝）

## 0. 闸门

- [x] P1 S7 签收（`P1_MATERIAL_S7_SIGNOFF.md`）
- [ ] `change-package validate --strict`

## 1. 文档

- [x] 1.1 `design.md` 金线 + `PH_Element_Compute_Ke_Arg` 表 + 行锚点
- [x] 1.2 `PR01_GUARDIAN_AUDIT.md` 锚点 guardian 基线
- [x] 1.3 链接 PR01 模板与 `contract-l4-element`

## 2. Guardian（接缝三路径）

- [x] 2.1 `PH_Elem_Def` / `PH_Elem_Domain` / `RT_Asm_Solv` / `PH_MatEval` P0=0
- [ ] 2.2 `PH_Elem_MaterialRoute` P0 销项 → `p2-element-material-route-audit`

## 3. 交付

- [ ] PR → `main`
- [ ] `P2_ELEMENT_GAP_SNAPSHOT` 增 PR01 行
- [ ] 归档 `plan/tasks/p2-element-pr01-seam-doc/`
