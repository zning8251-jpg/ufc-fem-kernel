# L3 Material 全量域治理台账

> 状态：ACTIVE | 创建：2026-04-27  
> 范围：`UFC/ufc_core/L3_MD/Material/`  
> 目标：把 L3 Material 收敛为 Desc / State / Validation / Registry / Cold Bridge 真源；禁止继续扩展 L3 本构热路径。

## 1. 治理冻结边界

| 对象 | 当前状态 | 冻结规则 | 后续目标 |
|------|----------|----------|----------|
| `Dispatch/MD_Mat_Lib.f90` | legacy aggregate；public surface 过宽；含 validation、DB、UMAT-like dispatch、stress helpers | 不新增本构求值、应力更新、切线或 SDV 演化 API | 分阶段拆为 Def/Validation/DB/Props/Legacy facade |
| `Registry/MD_MatReg_Algo.f90` | 与 `MD_Mat_Lib` 双向依赖 | 新注册能力优先依赖 `MD_Mat_Def` / `Shared` | 拆出 shared legacy state / metadata，收窄 USE |
| `Bridge/MD_MatRT_Brg.f90` | L3 层本构 dispatch，被 L4 Element 热路径调用 | 不新增调用者；标记为迁移对象 | Element 热路径改为 L5 route ctx + L4 kernel |
| `../Bridge/Bridge_L4/MD_MatLibPH_Brg.f90` | L3->L4 legacy constitutive bridge | `MD_PH_RouteToConstitutive*` 不进新热路径 | 保留冷路径/注册兼容后逐步缩面 |
| `Bridge/MD_Mat_Brg.f90` | UMAT bundle 与 L4 适配边界 | 可保留数据 bundle，不扩展 L3 compute | 后续统一 UMAT/VUMAT 输入输出合同 |

## 2. 11 家族分类真源

本表以 `Analysis/MD_Ana_Comp.f90` 的 `GROUP_MAT_COMPAT(9,11)` 列语义、`mat_family` 取值和当前磁盘目录为准。

| Family | `mat_family` | 当前目录 | Desc | Validation | Registry | Populate / L4 route | 测试 |
|--------|--------------|----------|------|------------|----------|---------------------|------|
| Elastic | 1 | `Elas/` | Partial | Partial | Partial | Minimal closure done | `TEST_Material_L3_L4_Closure.f90` |
| Plastic | 2 | `Plast/` | Partial | Scattered | Partial | Deferred | Deferred |
| Geo | 3 | `Geo/` | Partial | Scattered | Partial | Deferred | Deferred |
| Hyper | 4 | `HyperElas/` | Partial | Scattered | Partial | Deferred | Deferred |
| VE | 5 | `Viscoelas/` | Partial | Scattered | Partial | Deferred | Deferred |
| VP/Creep | 6 | `Creep/` | Partial | Scattered | Partial | Deferred | Deferred |
| Damage | 7 | `Damage/` | Partial | Scattered | Partial | Deferred | Deferred |
| Composite | 8 | `Composite/` | Partial | Scattered | Partial | Deferred | Deferred |
| Heat/Thermal | 9 | `Thermal/` | Partial | Scattered | Partial | Deferred | Deferred |
| Acoustic | 10 | `Acoustic/` | Partial | Scattered | Partial | Deferred | Deferred |
| EM/User | 11 | `User/` | Partial | Scattered | Partial | Deferred | Deferred |

## 3. `MD_Mat_Lib` Public Surface 分组

| 分组 | 代表符号 | 处置 |
|------|----------|------|
| Data / legacy structs | `UF_MaterialDef`, `UF_MaterialDB`, `MatProperties`, `MatPropertyDef`, `MatProps` | 保留 facade；逐步迁到 Def/Domain/Shared 小模块 |
| Validation / populate guards | `MD_Mat_ValidParameters`, `ParameterValidResult`, `MD_Mat_ValidatePropsForPopulate` | 优先拆到 `Shared/MD_Mat_Populate_Validate.f90` 或合并 `MD_Mat_Validation` |
| Registry / metadata | `MD_Mat_RegisterModel`, `MD_Mat_GetRegisteredModels`, `UF_MatProp_*` | 迁向 `Registry/MD_MatReg_Algo.f90` 或 Registry helper |
| DB / book material tables | `MD_MAT_DB_*`, `Mat_Entry` | 后续独立 DB 模块；同时修正非 `wp` 精度 |
| Compute-like legacy | `UF_Mat_Eval_Dispatch`, `MatEval`, `MatComp_Stress`, `ComputeElasticStress`, `MD_MAT_UMAT_*` | 冻结；迁移/替代到 L4 `PH_Mat_*` |
| Shared legacy states | `DmgState`, `FatigueState`, `CreepState`, `PhaseTransformationState` | 已建立 `Shared/MD_Mat_Legacy_State.f90` 作为迁移边界；registry 暂不切换类型来源，避免 legacy UMAT 过程的派生类型身份不一致 |

## 4. Lib ↔ Registry 循环

当前循环：

```text
MD_Mat_Lib
  -> USE MD_MatReg_Algo
MD_MatReg_Algo
  -> USE MD_Mat_Lib, ONLY: DmgState, FatigueState, CreepState, PhaseTransformationState, MD_MAT_UMAT_*
```

治理顺序：

1. 已抽出 shared legacy state type 目标模块 `Shared/MD_Mat_Legacy_State.f90`。
2. `MD_MatReg_Algo` 继续从 `MD_Mat_Lib` 读取 state types，直到匹配的 `MD_MAT_UMAT_*` legacy procedures 同步迁出；这是为了避免 Fortran 派生类型身份不一致。
3. 下一批迁移 `MD_MAT_UMAT_*` registry procedures 后，再把 registry 的 state type import 切到 shared 模块，让 `MD_Mat_Lib` 退化为兼容 facade。

## 5. Hot Path 违规清单

| 调用者 | 当前调用 | 目标 |
|--------|----------|------|
| `L4_PH/Element/Solid2D/PH_Elem_CPE4.f90` | `USE MD_MatRT_Brg`, `CALL MD_Mat_Dispatch` | L5 route ctx + L4 `PH_Mat_*` |
| `L4_PH/Element/Solid2D/PH_Elem_CPS4.f90` | `USE MD_MatRT_Brg`, `CALL MD_Mat_Dispatch` | L5 route ctx + L4 `PH_Mat_*` |
| `L4_PH/Element/Solid3D/PH_Elem_C3D8.f90` | `USE MD_MatRT_Brg`, `CALL MD_Mat_Dispatch` | L5 route ctx + L4 `PH_Mat_*` |

## 6. 验收门槛

- Material manifest 对账以当前磁盘路径为准。
- L3 Material 新增代码不得新增应力/切线/SDV 演化过程。
- L4/L5 热路径新增调用不得 `USE MD_MatRT_Brg` 或 `MD_PH_RouteToConstitutive*`。
- 每个家族推进时至少证明 Desc / Validation / Registry / Populate / Route 的一条最小链。
- 当前测试已在 `TEST_Material_L3_L4_Closure.f90` 增加 11-family governance matrix reachability，验证 `AC_N_MAT_FAM == 11` 以及结构/热/声/电磁代表列可达。

## 7. 本轮验证记录

| 检查 | 结果 | 说明 |
|------|------|------|
| `ReadLints` | PASS | 本轮编辑文件未发现 IDE linter 诊断 |
| `git diff --check` | PASS | Material 治理相关路径无 whitespace error |
| registry scan/align | PARTIAL | 已生成 registry 与 drift 报告；`L3_MD/Material` 未再出现在 drift 输出中，剩余 drift 主要在其它层/域与 `L4_PH/Material` |
| `gfortran -std=f2003 -fsyntax-only` | BLOCKED | 环境缺少 `if_prec_core.mod`，新模块语法检查停在依赖 `.mod` 读取阶段 |

## 8. Material 贯通域柱审计入口

当前 Material 贯通域柱以可重复工具生成清单，不再只靠手工表格维护：

| Artifact | 说明 |
|----------|------|
| `tools/material_pillar_audit.py` | 扫描 L3/L4/L5 Material 相关 `.f90`，标注层、族、角色、四型痕迹、热路径、桥接、legacy 依赖与测试锚点 |
| `docs/03_Domain_Pillars/MaterialPillar/material_pillar_inventory.csv` | 逐文件 inventory；当前覆盖 L3_MD/L4_PH/L5_RT 以及 L3->L4 Populate/Bridge 等跨层锚点 |
| `docs/03_Domain_Pillars/MaterialPillar/material_pillar_summary.md` | 统计摘要；当前扫描 243 行，L3=201、L4=39、L5=3 |
| `docs/03_Domain_Pillars/MaterialPillar/material_pillar_backlog.md` | 后续 backlog；`MD_MatRT_Brg` 与 `MD_MatLibPH_Brg` 继续作为 legacy hot-path quarantine |

治理顺序保持不变：先冻结 `MD_Mat_Lib` compute-like surface，再拆 validation/metadata，最后解除 Lib ↔ Registry 循环。新增 Material 功能必须先能落入 inventory 的 Def/Domain/Registry/Core/Ops/Eval/Bridge/Proc 分类，再进入实现。
