# L4 Element 同步治理台账

> 状态：ACTIVE | 创建：2026-04-28  
> 范围：`UFC/ufc_core/L4_PH/Element/`  
> 目标：稳定 L4 Element 作为单元物理计算热路径落点，维护形函数/积分/刚度/内力/质量计算核心，支撑 Material-Section-Element 正交迁移。

## 1. 域级守门人（Domain Guardian）

| 角色 | 说明 |
|------|------|
| **守门人** | Element 域 Owner（需指定） |
| **审查范围** | `L4_PH/Element/` 下所有 `.f90` 及子目录、`CONTRACT.md` / `DESIGN_Elem_FourTypes.md` |
| **审查触发** | 热路径文件变更、新增族计算内核、Shared 工具链变更、四型 TYPE 变更 |
| **合同冻结版本** | CONTRACT.md 当前版本为权威基线，变更须递增版本号 |

## 2. 文件冻结/活跃状态表

### 2.1 核心 .f90 文件

| 文件 | 模块 | 状态 | 职责 | 冻结/热路径 |
|------|------|------|------|-------------|
| `PH_Elem_Def.f90` | `PH_Elem_Def` | **active** | L4 单元 TYPE 定义（四型） | TYPE 字段变更须同步 L3 Populate + L5 Dispatch |
| `PH_Elem_Ctx.f90` | `PH_Elem_Ctx` | **active** | PH_Elem_Base_Ctx 上下文 TYPE | 热路径核心；Ctx 零 ALLOCATE |
| `PH_Elem_Core.f90` | `PH_Elem_Core` | **active** | 单元计算核心入口 | **热路径**；新增入口须走审查 |
| `PH_Elem_Domain.f90` | `PH_Elem_Domain` | **active** | 单元域容器 | 金线入口 Compute_Ke/Compute_Fe |
| `PH_Elem_Reg.f90` | `PH_Elem_Reg` | **active** | L4 单元族注册表 | 新增族须走族新增流程（§5） |
| `PH_ElemContm_Ops.f90` | `PH_ElemContm_Ops` | **active** | 连续体单元通用操作 | **热路径核心**；变更须性能回归 |
| `PH_ElemDomain_Ops.f90` | `PH_ElemDomain_Ops` | **active** | 单元域级操作 | — |
| `PH_Elem_ShapeFunc.f90` | `PH_Elem_ShapeFunc` | **active** | 形函数求值 | **热路径**；数值精度变更须回归 |
| `PH_Elem_GaussInt.f90` | `PH_Elem_GaussInt` | **active** | 高斯积分 | **热路径** |
| `PH_Elem_Nlgeom.f90` | `PH_Elem_Nlgeom` | **active** | 非线性几何 | **热路径** |
| `PH_NLGeomEval.f90` | `PH_NLGeomEval` | **active** | NLGeom 求值（大变形） | **热路径**；78KB 大文件，变更须谨慎 |
| `PH_Elem_Mass2.f90` | `PH_Elem_Mass2` | **active** | 质量矩阵计算 | **热路径** |
| `PH_ElemKeDispatch.f90` | `PH_ElemKeDispatch` | **active** | 刚度矩阵分派 | **热路径** |
| `PH_ElemFeDispatch.f90` | `PH_ElemFeDispatch` | **active** | 内力分派 | **热路径** |
| `PH_Elem_MassDispatch.f90` | `PH_Elem_MassDispatch` | **active** | 质量矩阵分派 | — |
| `PH_Elem_OutDispatch.f90` | `PH_Elem_OutDispatch` | **active** | 输出分派 | — |
| `PH_Elem_CalcWrapper.f90` | `PH_Elem_CalcWrapper` | **active** | 计算包装器 | — |
| `PH_Elem_ComplexStiff.f90` | `PH_Elem_ComplexStiff` | **active** | 复刚度 | — |
| `PH_Elem_dRdTheta.f90` | `PH_Elem_dRdTheta` | **active** | dR/dTheta 可微分接口 | AI/AD 敏感 |
| `PH_Elem_StructuralFacade.f90` | `PH_Elem_StructuralFacade` | **deprecated** | 薄门面，评估裁剪 | 若无消费者可删除 |
| `PH_Elem_Eval.f90` | `PH_Elem_Eval` | **active** | 单元求值 | — |
| `PH_Elem_ShapeMechField.f90` | `PH_Elem_ShapeMechField` | **active** | 力学场形函数 | **热路径** |
| `PH_ShapeScalarField.f90` | `PH_ShapeScalarField` | **active** | 标量场形函数 | — |
| `PH_Physical_Def.f90` | `PH_Physical_Def` | **active** | 物理层基础定义 | — |
| `PH_Mat_hTensor.f90` | — | **deprecated** | 属 Material 域，位置待迁 | 不在 Element 目录新增依赖 |
| `PH_Base_ErrCode.f90` | — | **active** | 错误码定义 | — |
| `PH_Elem_Contm.f90` | `PH_Elem_Contm` | **legacy** | Legacy 连续体门面（USE MD_*） | **G6 冻结**；边界见 `Legacy/LEGACY_CONTM_BOUNDARY.md` |
| `Legacy/LEGACY_CONTM_BOUNDARY.md` | — | **active** | G6 隔离 SSOT + W0/W1/W2 | `verify_element_golden_path_no_contm.py` |

### 2.2 族计算内核子目录

| 子目录 | 状态 | 内核数 | 说明 |
|--------|------|--------|------|
| `Solid2D/` | **active** | 13 | CPE/CPS/CAX 族：已完成 Material route |
| `Solid2Dt/` | **active** | 13 | 热耦合 2D 族 |
| `Solid3D/` | **active** | 12 | C3D 族：已完成 Material route |
| `Solid3Dt/` | **active** | 8 | 热耦合 3D 族 |
| `Shell/` | **active** | 14 | 壳单元族 |
| `Beam/` | **active** | 34 | 梁单元族（最大） |
| `Truss/` | **active** | 4 | 桁架族：已完成 axial route |
| `Spring/` | **active** | 3 | 弹簧族：已完成 scalar stiffness route |
| `Dashpot/` | **active** | 3 | 阻尼器族：已完成 scalar damping route |
| `Mass/` | **active** | 0 | 质量族（空目录） |
| `Pipe/` | **active** | 1 | 管单元族：已完成 uniaxial route |
| `Acoustic/` | **active** | 12 | 声学族：已完成 fluid route |
| `Porous/` | **active** | 20 | 多孔介质族：已完成 two-phase route |
| `Membrane/` | **active** | 2 | 膜单元族 |
| `Infinite/` | **active** | 1 | 无限元族：已完成 decay route |
| `Thermal/` | **active** | 5 | 热传导族 |
| `Special/` | **active** | 12 | 特殊单元族 |
| `Shared/` | **active** | 23 | 族间共享工具 |
| `Cohesive/` | **active** | 0 | 黏聚族（空目录） |
| `Gasket/` | **active** | 0 | 垫片族（空目录） |
| `Surface/` | **active** | 0 | 表面族（空目录） |
| `User/` | **active** | 0 | 用户单元族（空目录） |

## 3. 热路径文件变更特殊审查要求

以下文件属于 Element 热路径核心，变更须满足额外要求：

| 热路径文件 | 特殊审查要求 |
|------------|-------------|
| `PH_ElemContm_Ops.f90` (141KB) | 性能回归基线对比；禁止新增 ALLOCATE；变更须守门人 + 性能 Owner 双审 |
| `PH_NLGeomEval.f90` (78KB) | 大变形数值精度回归；变更须附 NLGeom 测试结果 |
| `PH_Elem_ShapeFunc.f90` (35KB) | 形函数数值精度；变更须附精度验证 |
| `PH_ElemKeDispatch.f90` | 刚度分派路由变更须同步 CONTRACT |
| `PH_ElemFeDispatch.f90` | 内力分派路由变更须同步 CONTRACT |
| `PH_Elem_Core.f90` | Compute_Ke/Compute_Fe 签名变更须同步 L5 |
| 各族 `PH_Elem_*_Material_Update_Routed` | Material route 变更须同步 L4 Material CONTRACT |

**通用热路径规则**：
- **禁止** IP 循环内 `USE L3_MD` 模块（三附规则）
- **禁止** 热路径新增 `ALLOCATE`（Ctx 栈分配）
- 变更须通过性能回归检查（§6）

## 4. 变更审查规则

| 变更类型 | 审查要求 | 审查人 |
|----------|----------|--------|
| 四型 TYPE 字段变更 | **强制审查** — 须同步 L3 Populate + L5 Dispatch | 守门人 + L3/L5 Owner |
| 热路径文件变更 | **强制审查** — 须满足 §3 特殊要求 | 守门人 + 性能 Owner |
| `Shared/` 工具链变更 | **强制审查** — 影响多族内核 | 守门人 |
| 族内核新增/修改 | 常规审查 — 须确认注册表已更新 | 守门人 |
| `CONTRACT.md` 变更 | **强制审查** — 须递增版本号 | 守门人 |
| `PH_Elem_Contm.f90` legacy 路径 | **禁止扩展** — 技术债冻结 | 守门人 |

## 5. 族计算内核新增流程（New Family Kernel Checklist）

- [ ] 1. 确认 L3 侧族注册已完成（`MD_Elem_Reg` 已注册）
- [ ] 2. 在对应族子目录下创建 `PH_Elem_{FamilyName}_{Type}.f90`
- [ ] 3. 实现族内核：形函数 + 积分 + Ke/Fe 计算
- [ ] 4. 在 `PH_Elem_Reg.f90` 中注册 L4 族内核
- [ ] 5. 在 `PH_ElemKeDispatch.f90` / `PH_ElemFeDispatch.f90` 中新增分派条目
- [ ] 6. 实现 Material route helper（`PH_Elem_{Type}_Material_Update_Routed`）
- [ ] 7. 同步更新 `CONTRACT.md` 文件清单与族覆盖矩阵
- [ ] 8. 新增或扩展闭环测试
- [ ] 9. 运行性能回归基线
- [ ] 10. 更新本治理台账（§2 文件状态表）

## 6. 性能回归检查规则

| 检查项 | 基线 | 阈值 | 触发条件 |
|--------|------|------|----------|
| Compute_Ke 单元耗时 | 当前基线 | 退化 ≤5% | 热路径文件变更 |
| Compute_Fe 单元耗时 | 当前基线 | 退化 ≤5% | 热路径文件变更 |
| NLGeom 大变形精度 | 参考解 | 误差 ≤1e-10 | NLGeomEval 变更 |
| 形函数精度 | 参考解 | 误差 ≤1e-12 | ShapeFunc 变更 |
| Material route 正确性 | 已有 closure test | PASS | 族 route helper 变更 |

## 7. 清旧资产处置

| 资产 | 当前状态 | 处置策略 |
|------|----------|----------|
| `PH_Elem_Contm.f90` | legacy；USE MD_* 技术债 | 冻结不扩展；新热路径走金线 + Populate 缓存 |
| `PH_Elem_StructuralFacade.f90` | deprecated；薄门面 | 评估消费者后裁剪 |
| `PH_Mat_hTensor.f90` | 位置错误；属 Material 域 | 迁移到 `L4_PH/Material/` |
| 空族子目录（Cohesive/Gasket/Mass/Surface/User） | 已创建但无内核 | 保留；待族内核开发时补充 |

## 8. 验收门槛

- L4 Element 新增热路径不得在 IP 循环内 `USE L3_MD` 模块。
- 新增族内核须完成族新增 checklist 全部步骤。
- 热路径变更须通过性能回归检查。
- Material route helper 须与 L4 Material CONTRACT 的 slot 合同一致。
- CONTRACT.md 变更须递增版本号并更新日期。

## 9. 验证记录

| 检查 | 结果 | 说明 |
|------|------|------|
| 文件清单对账 | PASS | 27 个核心 .f90 + 22 个族子目录与 CONTRACT/DOMAIN_PILLAR_CARD 一致 |
| 热路径 L3 依赖扫描 | PARTIAL | `PH_Elem_Contm.f90` 仍有 `USE MD_*`，已标记为 legacy 冻结 |
| Material route 覆盖 | PASS | Solid2D/Solid3D/Truss/Pipe/Spring/Dashpot/Mass/Beam/Acoustic/Porous/Cohesive/Gasket/Infinite/Thermal/Membrane 已建立 routed helper |
| CONTRACT 一致性 | PASS | CONTRACT.md 存在且与实现一致 |
