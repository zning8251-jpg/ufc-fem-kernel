# Tasks: p2-element-legacy-contm-g6w3

## G6-W3a（迁移）

- [x] `git mv` `PH_ElemContm_Ops.f90` → `Legacy/PH_ElemContm_Ops.f90`
- [x] 更新 `LEGACY_CONTM_BOUNDARY.md` 与 `verify_element_contm_legacy_boundary.py` allowlist
- [ ] PR → `main`

## G6-W3b（去 MD_*）

- [ ] 审计 Ops `USE MD_*` 清单（按子程序簇）
- [ ] 优先：`Calc_Continuum2D_UF` / `Calc_Continuum3D` 路径 UF 化
- [ ] 保留 `Solid*_Def` 回退签名不变

## G6-W3c（门控）

- [ ] `tools/verify_l4_element_no_md_use.py`
- [ ] harness profile 或并入 `p2-element-golden-seam`
- [ ] `P2_ELEMENT_GAP_SNAPSHOT` G6 状态更新
