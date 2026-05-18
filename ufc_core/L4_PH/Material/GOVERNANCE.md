# L4 Material 同步治理台账

> 状态：ACTIVE | 创建：2026-04-27  
> 范围：`UFC/ufc_core/L4_PH/Material/`  
> 目标：稳定 L4 Material 作为本构热路径落点，为后续 `MD_MatRT_Brg` 迁移到 L5 route ctx + L4 kernel 提供清晰目标。

## 1. 当前磁盘真源

| 分组 | 当前路径 | 角色 |
|------|----------|------|
| Domain container | `PH_Mat_Domain_Core.f90` | `PH_Mat_Domain`、slot pool、`PH_Mat_Ctx/State`、Idx API；不放族内本构算法 |
| Root kernel facade | `PH_Mat_Core.f90` | 现有 Material core/facade 兼容入口，后续按调用面收窄 |
| Base | `Base/PH_Mat_BaseDefn.f90`、`Base/PH_Mat_Dispatch.f90`、`Base/PH_Mat_Reg.f90` | base definition、legacy dispatch、kernel registry |
| Contract | `Contract/*.f90` | 本构点 State/StressStrain、Props 布局、UMAT 上下文、Spcl 接口、UMAT 桥接 |
| Dispatch | `Dispatch/*.f90` | eval facade、PLM dispatch、legacy UMAT facade |
| Elastic | `Elas/*.f90` | 弹性 definition/core/bridge |
| Plastic | `Plast/*.f90` | J2、Hill、Chaboche、Barlat、Crystal 等 |
| Geo | `Geo/*.f90` | Mohr-Coulomb、Drucker-Prager、Cam-Clay |
| Damage | `Damage/*.f90` | Gurson 等损伤模型 |
| Composite | `Composite/*.f90` | Castani / composite 相关模型 |
| AI | `AI/PH_AI_MatInteg.f90` | 可选 AI material integration slot |

`docs/03_Domain_Pillars/DomainProcedureRegistry/design/L4_PH/Material/manifest.json` 已按当前 36 个 `.f90` 源文件重建；旧 compact/camelCase 路径仅作历史参考。

## 2. 分工冻结规则

| 对象 | 允许 | 禁止 / 暂缓 |
|------|------|-------------|
| `PH_Mat_Domain_Core` | slot 生命周期、Idx API、`PH_Mat_Ctx/State/Slot`、`PH_MAT_*` 枚举 | 新增本构算法、返回映射、UMAT wrapper |
| `PH_L4_Populate_Material` | 冷路径读取 L3 `MD_Mat_Desc`，写入 L4 slot props/state 初值 | IP 热路径回读 L3 |
| `Base/PH_Mat_Reg` | kernel registration / lookup 兼容层 | 保存 L3 Desc 真源 |
| `Dispatch/PH_MatEval*` | 族内核调用 facade 和 legacy dispatch 收敛点 | 继续扩大对 L3 `MD_Mat_Lib` 的热路径依赖 |
| `Elas/Plast/Geo/Damage/Composite` | 本构 kernel、状态更新、切线与应力计算 | 直接调用 L3 `MD_MatRT_Brg` |

## 3. L3/L4/L5 金线

```text
L3 MD_Mat_Desc
  -> PH_L4_Populate_Material
  -> PH_Mat_Domain%slot_pool(mat_pt_idx)%ctx/state
  -> RT_Mat_Brg_BuildTable_FromMaterial
  -> RT_Mat_Dispatch_Ctx
  -> L4 PH_Mat_* kernel
```

`CPE4`、`CPS4`、`C3D8` 已作为第一批示范线替换 `MD_MatRT_Brg::MD_Mat_Dispatch`。纯机械 continuum helper 已覆盖 `CPE3/CPE4/CPE6/CPE8`、`CPS3/CPS4/CPS6/CPS8`、`CAX3/CAX4/CAX6/CAX8` 与 `C3D4/C3D5/C3D6/C3D8/C3D8EAS/C3D8FBar/C3D10/C3D13/C3D15/C3D20/C3D27`；Truss/Pipe/Spring/Dashpot/Mass 已覆盖各自 1D 或 scalar route；Beam 已覆盖 `E/nu` constants route；Acoustic 已覆盖 `density/bulk_modulus/sound_speed` route；Porous 已覆盖 two-phase 参数 route；Cohesive/Gasket 已覆盖 interface-law route；Infinite 已覆盖 decay route；Thermal shell 族已覆盖 `DS3/DS4/DS6/DS8` scalar conductivity helper；Membrane/Shell membrane subpath 已覆盖 `M3D9R/S4/S8/S9/S4T/S8RT` plane-stress helper 与 `S3/S6` 当前 CPE-based helper，统一走 `RT_Mat_Dispatch_Ctx -> PH_Mat_Slot` 后按族进入专用 helper。结构化单元入口要求 `elem_cfg%mat_id` 承接 Populate 后的真实 `mat_pt_idx`，并通过 `PH_Mat_GetCtx_Idx`（及 `PH_Mat_GetCtx_Arg`）读取 L4 material slot ctx；仍为 legacy `mat_prop/mat_state` 签名的 `NL_TL/NL_UL` 不在 IP 循环中新增 L3 回扫。

## 4. 覆盖矩阵

| Family | L4 当前落点 | Manifest | Contract | Closure test |
|--------|-------------|----------|----------|--------------|
| Elastic | `Elas/` + `PH_Mat_Domain_Core` | Synced | Synced | Minimal |
| Plastic | `Plast/` + `Dispatch/PH_MatPLM*` | Synced | Synced | Deferred |
| Geo | `Geo/` | Synced | Synced | Deferred |
| Hyper | `Hyper/` | Synced | Synced | Deferred |
| VE / Creep | `Creep/`, `Viscoelas/` | Synced | Synced | Deferred |
| Damage | `Damage/` | Synced | Synced | Deferred |
| Composite | `Composite/` | Synced | Synced | Deferred |
| Thermal | `Thermal/` | Synced | Synced | Deferred |
| Acoustic | `Acoustic/` | N/A | Deferred | Deferred |
| EM/User | `Contract/PH_Mat_UMAT_Def.f90`, `PH_Mat_UMAT_Brg.f90` | Synced | Partial | Deferred |

## 5. 材料域后续计划（单元覆盖后）

单元族 route 覆盖完成后，后续重心回到 Material 域自身，按以下顺序推进：

1. **Slot contract hardening**：冻结 `PH_Mat_Ctx/State/Slot` 的最小稳定字段、`matModel` 枚举和 `props/state` 版本语义；为 acoustic/porous/interface/scalar route 增加明确 family tag，避免所有非弹性标量继续伪装成 `PH_MAT_ELASTIC`。
2. **Populate material map**：梳理 `PH_L4_Populate_Material` 从 L3 `MD_Mat_Desc` 到 L4 slot 的字段映射，补齐 acoustic、thermal、porous、cohesive/gasket、mass/dashpot/spring 等非 bulk-elastic 族的冷路径落点。
3. **Kernel facade convergence**：收敛 `PH_Mat_Core`、`Base/PH_Mat_Dispatch`、`Dispatch/PH_MatEval*` 的 legacy 调用面，明确哪些模型直接进入 `Elas/Plast/Geo/Damage/Composite` kernel，哪些保持 UMAT/扩展接口。
4. **Closure tests by material family**：把当前 Element helper 级测试扩展为 Material family 测试矩阵：elastic、thermal、acoustic、porous、interface、scalar connector/inertia、UMAT，每族至少覆盖 slot 构造、route ctx、正负例。
5. **L5 material table**：在 L5 侧固化 `RT_Mat_Dispatch_Ctx -> PH_Mat_Domain%slot_pool(mat_pt_idx)` 的表构建与错误传播，禁止 L5 保存 L3 Desc 或在 IP 热路径回扫 L3。
6. **State update migration**：对有状态材料（plastic/damage/creep/visco/porous）建立 `state_old/state_new` 的 L4 slot 更新协议，再逐步替换 legacy `mat_state/statev` 热路径。

## 6. 后续 hot-path 入口

| 候选 | 当前 legacy 调用 | 建议 |
|------|------------------|------|
| `L4_PH/Element/Solid2D/PH_Elem_CPE4.f90` | 已替换为 `PH_Elem_CPE4_Material_Update_Routed` | plane strain；已接 `elem_cfg%mat_id -> mat_pt_idx -> L4 slot ctx` |
| `L4_PH/Element/Solid2D/PH_Elem_CPS4.f90` | 已替换为 `PH_Elem_CPS4_Material_Update_Routed` | plane stress；独立 3x3 plane-stress tangent |
| `L4_PH/Element/Solid3D/PH_Elem_C3D8.f90` | 已替换为 `PH_Elem_C3D8_Material_Update_Routed` | 3D 6 分量 stress/tangent |
| `L4_PH/Element/Solid2D/PH_Elem_CPE3.f90` / `PH_Elem_CPS3.f90` | 已补齐 `PH_Elem_*_Material_Update_Routed` | CPE3=plane strain；CPS3=plane stress；用于下一步结构化入口接线 |
| `L4_PH/Element/Solid2D/PH_Elem_CPE6.f90` / `CPE8` / `CPS6` / `CPS8` | 已补齐 `PH_Elem_*_Material_Update_Routed` | 高阶纯 Solid2D helper；CPE=plane strain，CPS=plane stress |
| `L4_PH/Element/Solid2D/PH_Elem_CAX3.f90` / `CAX4` / `CAX6` / `CAX8` | 已补齐 `PH_Elem_*_Material_Update_Routed` | 轴对称 `[rr, zz, tt, rz]` helper；独立 4x4 tangent |
| `L4_PH/Element/Solid3D/PH_Elem_C3D4.f90` / `C3D6` / `C3D10` | 已补齐 `PH_Elem_*_Material_Update_Routed` | 3D 6 分量 routed helper；legacy `NL_*` 签名待后续改为 `elem_cfg%mat_id` 调用面 |
| `L4_PH/Element/Solid3D/PH_Elem_C3D5.f90` / `C3D13` / `C3D15` / `C3D20` / `C3D27` | 已补齐 `PH_Elem_*_Material_Update_Routed` | 3D 6 分量 routed helper；高阶路径仍待结构化 NL 调用面接线 |
| `L4_PH/Element/Solid3D/PH_Elem_C3D8EAS.f90` / `C3D8FBar` | 已补齐 `PH_Elem_*_Material_Update_Routed` | C3D8 变体共享 6 分量 material route |

## 7. Material-Section-Element 正交迁移

当前首批示范替换了 `CPE4/CPS4/C3D8` 的结构化材料热路径调用，不宣称完成所有单元族的全局 Section 映射。继续推广时必须保持三维正交入口：

```text
Element / IP
  -> Section assignment
  -> Material id / mat_pt_idx
  -> RT_Mat_Dispatch_Ctx
  -> PH_Mat_Domain%slot_pool(mat_pt_idx)
  -> PH_Mat_* kernel
```

推广顺序：

1. `CPE4`：elastic plane strain，已完成 routed helper，并要求真实 `mat_pt_idx`。
2. `CPS4`：elastic plane stress，已完成 routed helper 和独立切线映射。
3. `C3D8`：3D solid，已完成 routed helper，覆盖完整 6 分量应力/切线。
4. `CPE3/CPS3`：已补齐 routed helper，下一步将 legacy NL 调用面迁入 `elem_cfg%mat_id` 结构化入口。
5. `C3D4/C3D6/C3D10`：已补齐 6 分量 routed helper，下一步将 legacy `mat_prop/mat_state` 签名迁入 Section/Element map。
6. `CPE6/CPE8/CPS6/CPS8` 与 `C3D5/C3D13/C3D15`：已补齐 routed helper，作为 helper-only 批次等待结构化入口统一接线。
7. `CAX3/CAX4/CAX6/CAX8`：已补齐 axisymmetric routed helper，采用 `[rr, zz, tt, rz]` 与 4x4 tangent。
8. `C3D20/C3D27/C3D8EAS/C3D8FBar`：已补齐 6 分量 routed helper，下一步进入结构化高阶调用面验收。
9. `*T`：shared thermo-elastic helper 已锁定 `dstrain_total - thermal_strain` 的 mechanical route 边界，覆盖 3D、plane strain、plane stress 与 axisymmetric；`Solid2Dt` 的 `CPE/CPS/CAX` 与 `Solid3Dt` 的 `C3D` 同族 wrappers 已接入；`S4T/S8RT` 已接入机械膜子路径与 thermal conductivity routed helper，完整壳热-力耦合仍需专用合同。
10. `Truss`：`T2D2/T3D2/T3D3` 已接入 1D axial routed helper；面积、长度、方向余弦仍归 Element/Section，material route 只返回 axial stress 与 `E` tangent。
11. `Pipe`：`PIPE21/PIPE22` 已接入 uniaxial routed helper；当前合同只覆盖复用 Truss axial 路径的材料更新，管截面、压力载荷与复杂管梁行为仍归 Pipe/Beam 专用路径。
12. `Spring`：`SPRING1/SPRING2` 已接入 scalar stiffness routed helper；`D_tangent` 表示等效弹簧刚度。
13. `Dashpot`：`DASHPOT1/DASHPOT2` 已接入 scalar damping routed helper；`C_tangent` 表示等效阻尼系数，速度投影与符号仍归 Element。
14. `Mass`：`MASS` 已接入 scalar mass routed helper；`mass_per_node=m/n_node` 表示节点均分质量，DOF 展开、转动惯量与非结构质量仍归 Mass/Inertia 专用路径。
15. `Beam`：`B*` 已接入 elastic constants routed helper；material route 只返回 `E/nu`，截面几何和 resultants 仍归 Beam Element/Section。
16. `Acoustic`：`AC*` 已接入 acoustic fluid routed helper；material route 返回 `density/bulk_modulus/sound_speed`，阻抗/PML/耦合仍归 Acoustic Element。
17. `Porous`：已接入 two-phase 参数 routed helper；saturated Biot 系数与结构-孔压耦合仍归 `UF_RT_Poro_MakeCoeffsFromContext` 与 Porous Element。
18. `Cohesive/Gasket`：已接入 interface-law routed helper；Cohesive 返回 `K_n/K_s` 与可选强度/断裂能，Gasket 返回 `K_g/h_0/p_max`。
19. `Infinite`：已接入 decay routed helper；无限元映射和 isotropic D 仍归 Infinite 专用路径。
20. `Thermal shell DS*`：`DS3/DS4/DS6/DS8` 已接入 scalar conductivity routed helper；`K_tangent` 表示导热系数，表面 metric、热容与边界热流仍归 Element/Section。
21. `Membrane/Shell membrane`：`M3D9R/S4/S8/S9/S4T/S8RT` 已接入 plane-stress routed helper；`S3/S6` 已按当前 CPE-based membrane 子路径接入；当前仓库无独立 `S5` 模块；厚度、层合、弯曲与横向剪切仍归 Element/Section 专用路径。
22. 剩余 `Rigid/RotaryInertia` 等族按合同优先推进；`Rigid/RotaryInertia` 不复用 bulk elastic route 作为临时 shim。

### 7.1 回到 Material 域后的推进计划

`ElementInventory` 对账已完成当前仓库可发现候选的收口：registry 为 225 行，未注册源码候选为 0，剩余 152 行仍需权威 377 清单补名。Material 域后续不再凭空扩 registry，而是按已注册行推进 row-level route 验收。

1. **P0：注册行验收优先于新增命名**。以 `docs/ElementInventory/element_registry_route_crosswalk.csv` 为入口，先处理已注册 `PARTIAL`/`NOT_ROUTED` 行；未命名 152 slots 只作为 accounting gap 保留。
2. **P1：Porous / coupled continuum**。`C3D8PT`、`CPE/CPS/CAX*P` 已进入 registry；下一步补 exact closure tests，明确 two-phase 参数 route 与位移-孔压/热耦合自由度的边界。
3. **P2：Thermal transfer rows**。`DC*` 当前为 registered `NOT_ROUTED`，需决定接 scalar conductivity route，还是作为纯热传导非本构路径单独闭环。
4. **P3：Family-route 行固化**。Beam、Acoustic、Cohesive、Membrane/Shell 等保留 family route 语义时，必须在合同和测试中写明“材料只返回参数，截面/几何/resultant 归 Element/Section”。

### 7.2 Material 贯通域柱批次

本域后续执行以 `tools/material_pillar_audit.py` 为治理入口：

| 批次 | 目标 | 当前落点 |
|------|------|----------|
| A. Inventory | 建立 L3/L4/L5 Material 文件清单与角色分类 | `docs/03_Domain_Pillars/MaterialPillar/material_pillar_inventory.csv` |
| B. Contract Freeze | L3 SSOT、L4 compute、L5 thin router 三层合同一致 | `CONTRACT.md` / `DOMAIN_PILLAR_CARD.md` / `L5_RT/Material/CONTRACT.md` |
| C. Populate/Slot | 11-family `PH_MAT_*` slot marker 与 `mat_model_id` 分离 | `PH_Mat_Domain_Core.f90` / `PH_L4_L3MatContract.f90` |
| D. L5 Dispatch | 从 L4 slot 构建 route table，并验证 ctx/writeback 与 Elastic3D response smoke | `RT_Mat_Brg.f90` / `tests/L5_RT/RT_Mat_Test.f90` |
| E. Family Rollout | 每族一个代表模型先闭环，再扩模型覆盖 | `TEST_Material_L3_L4_Closure.f90` 与后续族测试 |

当前第一轮不批量重命名 Material 目录，不新增 L3 compute API；`MD_MatRT_Brg` 与 `MD_MatLibPH_Brg` 保持 quarantine，直到对应热路径完全由 `RT_Mat_Dispatch_Ctx -> PH_Mat_Slot -> PH_Mat_*` 替代。

### 7.3 P1.1 小闭环决议

| 项 | 决议 | 落点 |
|----|------|------|
| 测试入口 | 增加 aggregate runner，统一跑 L3/L4 closure 与 L5 route tests | `tests/TEST_Material_Pillar_Runner.f90` |
| L5 Elastic dispatch | 先验证 `RT_Mat_Dispatch_Ctx`，再通过 L4 Element shared route helper 计算 Elastic3D response smoke | `tests/L5_RT/RT_Mat_Test.f90` |
| `DC*` thermal rows | 当前仓库无独立 `PH_Elem_DC*.f90` 模块；对账中作为 scalar conductivity family route 收口，不声明 per-element wrapper | `tools/element_inventory_audit.py` |
| Plastic/J2 route | 已补 `MD_MAT_CATEGORY_PL -> PH_MAT_ELASTO_PLASTIC -> RT_Mat_Dispatch_Ctx` populated-slot route 测试；真实 J2 kernel dispatch 留到 PLM legacy quarantine 后推进 | `TEST_Material_L3_L4_Closure.f90` |

## 8. 验收记录

本阶段验收目标：

- L4 Material manifest 不再报告自身旧路径漂移。
- L4 合同明确当前真实路径和分工。
- `TEST_Material_L3_L4_Closure.f90` 覆盖 L4 `PH_MAT_*` enum / slot 落点基本可达。
- 不迁移大规模 Element hot-path，只记录下一步入口。

| 检查 | 结果 | 说明 |
|------|------|------|
| `ReadLints` | PASS | 本阶段编辑文件未发现 IDE linter 诊断 |
| `git diff --check` | PASS | L4 Material 治理相关路径无 whitespace error |
| registry scan/align | PASS for L4 Material | 已生成 registry 与 drift 报告；`L4_PH/Material` 未出现在 drift 输出中 |
| `gfortran -std=f2003 -fsyntax-only` | BLOCKED | 环境缺少 `if_prec_core.mod`，语法检查停在依赖 `.mod` 读取阶段 |

### CPE4-first 验证记录（hot-path 小闭环）

| 检查 | 结果 | 说明 |
|------|------|------|
| Legacy import scan | PASS | `PH_Elem_CPE4.f90` 已无 `MD_MatRT_Brg` / `MD_Mat_Dispatch` 引用 |
| `ReadLints` | PASS | CPE4、测试与合同文档未发现 IDE linter 诊断 |
| `git diff --check` | PASS | CPE4 hot-path 迁移相关路径无 whitespace error |
| registry scan/align | PARTIAL | 已重新生成 registry 与 drift 报告；剩余 drift 为既有跨域问题 |
| `gfortran -std=f2003 -fsyntax-only` | BLOCKED | 环境缺少 `if_base_def.mod` / `if_prec_core.mod`，语法检查停在依赖 `.mod` 读取阶段 |
