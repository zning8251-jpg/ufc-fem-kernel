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
- [x] `PH_Elem_Sld2D_Def` / `Solid*Dt` 显式路由（G6-W1b）
- [x] `Compute_Ke_C3D8` / `C3D4` → 族 `FormStiffMatrix`；补 `PH_Elem_C3D8_StiffMatrix(coords)`
- [x] `Compute_Ke_CPE4/CPS4/CAX4/CPE8/CPS8/CAX8` → 族 `StiffMatrix` / `FormStiffMatrix`
- [ ] PR → `main`（`feat/p2-element-legacy-contm-g6w1b` / #23）

## G6-W2

- [x] `Legacy/PH_Elem_Contm_Brg.f90` — MD↔UF 映射与 `CompPoro/Thm/THM`
- [x] `PH_Elem_Contm.f90` 薄 facade（无 `USE MD_*`）
- [x] `MD_ElemPH_Brg` → `PH_ElemContm_Ops` + `PH_Elem_Contm_Brg`
- [x] `tools/verify_element_contm_legacy_boundary.py` + harness `p2-element-golden-seam`
- [x] PR → `main`（#23）

## G6-W3（计划）

见 [`plan/changes/p2-element-legacy-contm-g6w3/`](../p2-element-legacy-contm-g6w3/tasks.md)
