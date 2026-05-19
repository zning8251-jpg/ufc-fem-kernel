# Tasks: p2-element-legacy-contm-retire

## G6-W0（本 PR）

- [x] `LEGACY_CONTM_BOUNDARY.md`
- [x] `verify_element_golden_path_no_contm.py`
- [x] harness profile `p2-element-golden-seam`
- [x] `GOVERNANCE.md` / `CONTRACT.md` 交叉链接
- [x] `P2_ELEMENT_GAP_SNAPSHOT` G6 分阶段
- [ ] PR → `main`

## G6-W1（本 MR 续）

- [x] `PH_Elem_Sld3D_Def`：C3D8/C3D4/… → `PH_Elem_Contm_Calc3D`；C3D8R/C3D20R 专用路由
- [x] `Calc_Continuum3D`：`in_struct` / `mat_models` 修复
- [ ] `PH_Elem_Sld2D_Def` / `Solid*Dt` 对称（后续）

## G6-W2（后续）

- [ ] Contm 门面化 / Bridge 收敛；guardian 全 `Element/` DEP 审计
