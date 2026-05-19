# Tasks: p1-material-wave5-mateval-arg

## 1. Readiness

- [ ] 1.1 Read `CONTRACT.md` + [`p1-material-wave5-mateval-arg/specs/**`](specs/p1-material-wave5-mateval-arg/spec.md)
- [ ] 1.2 `guardian PH_MatEval.f90` 基线 → 记录 rc（预期 P0=0）
- [ ] 1.3 确认与 `p1-material-wave5-plast-nonj2` **无文件重叠**

**In-scope**：`Dispatch/PH_MatEval.f90`；可选 `L4_PH/Material/CONTRACT.md`（Eval 登记表）。

## 2. Implementation

- [ ] 2.1 MOD-001：Purpose / Theory / Status 模块头（对齐 `PH_MatPLMEval` wave4）
- [ ] 2.2 文件头：删除或改写 legacy `Eval_In/Out` 列表；注明 **Arg-only public API**
- [ ] 2.3 PUBLIC 段注释：`! 推荐：PH_Mat_*_Eval(PH_Mat_*_Eval_Arg)` — 类型与过程同名不同义
- [ ] 2.4 （可选）`CONTRACT.md` 增量：Legacy `PH_MatEval` staging 与 C2 迁出指针
- [ ] 2.5 关键 Eval 过程顶行四链（仅 touched：ElasticIso / PlasticVM / PlasticHill 三处代表）

## 3. Harness

- [ ] 3.1 `discipline verify --touch-path PH_MatEval.f90`
- [ ] 3.2 `guardian PH_MatEval.f90 --fail-on-p0`
- [ ] 3.3 `naming PH_MatEval.f90`
- [ ] 3.4 `change-package validate --change-id p1-material-wave5-mateval-arg --strict`
- [ ] 3.5 `closure --skip-plan-checks`（记录 REPORTS 路径）

## 4. Roll-forward

- [ ] 4.1 `PR_BODY.md` + 合并后 archive task
- [ ] 4.2 C2 按族吸收 `PH_MatEval` → `Elas/`/`Plast/`/… — **新 change_id**（超出本包）
