# UFC与Abaqus命名对齐方案

## 概述
本文档定义UFC与Abaqus命名对齐方案，确保具体模型/单元命名与Abaqus保持一致，同时遵循UFC的域级命名风格。

## 一、材料模型命名对齐

### 1.1 超弹性材料（Hyperelastic）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| MD_HypNeoHookean_Algo.f90 | Neo-Hookean | MD_Hyp_NeoHookean.f90 | 三段式命名 |
| MD_HypMooneyRivlin_Algo.f90 | Mooney-Rivlin | MD_Hyp_MooneyRivlin.f90 | 三段式命名 |
| MD_HypOgdn2_Algo.f90 | Ogden (2-term) | MD_Hyp_Ogden2.f90 | 三段式命名 |
| MD_HypOgdn3_Algo.f90 | Ogden (3-term) | MD_Hyp_Ogden3.f90 | 三段式命名 |
| MD_HypYeoh_Algo.f90 | Yeoh | MD_Hyp_Yeoh.f90 | 三段式命名 |
| MD_HypAB_Algo.f90 | Arruda-Boyce | MD_Hyp_ArrudaBoyce.f90 | 三段式命名 |
| MD_HypGent_Algo.f90 | Gent | MD_Hyp_Gent.f90 | 三段式命名 |
| MD_HypVdW_Algo.f90 | Van der Waals | MD_Hyp_VanDerWaals.f90 | 三段式命名 |
| MD_HypMarlow_Algo.f90 | Marlow | MD_Hyp_Marlow.f90 | 三段式命名 |
| MD_HypMoon2_Algo.f90 | Mooney-Rivlin (2-term) | MD_Hyp_MooneyRivlin2.f90 | 三段式命名 |
| MD_HypMoon5_Algo.f90 | Mooney-Rivlin (5-term) | MD_Hyp_MooneyRivlin5.f90 | 三段式命名 |
| MD_HypFoam_Algo.f90 | Hyperfoam | MD_Hyp_Hyperfoam.f90 | 三段式命名 |

### 1.2 弹性材料（Elastic）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | Linear Elastic | MD_Elas_Linear.f90 | 新增 |
| - | Orthotropic | MD_Elas_Orthotropic.f90 | 新增 |
| - | Anisotropic | MD_Elas_Anisotropic.f90 | 新增 |

### 1.3 塑性材料（Plastic）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | Isotropic Hardening | MD_Plast_IsoHard.f90 | 新增 |
| - | Kinematic Hardening | MD_Plast_KinHard.f90 | 新增 |
| - | Combined Hardening | MD_Plast_CombHard.f90 | 新增 |

### 1.4 泡沫材料（Foam）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | Crushable Foam | MD_Foam_Crushable.f90 | 新增 |
| - | Low Density Foam | MD_Foam_LowDensity.f90 | 新增 |
| - | Viscous Foam | MD_Foam_Viscous.f90 | 新增 |

### 1.5 复合材料（Composite）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | Laminate | MD_Comp_Laminate.f90 | 新增 |
| - | Woven Composite | MD_Comp_Woven.f90 | 新增 |
| - | Short Fiber | MD_Comp_ShortFiber.f90 | 新增 |

### 1.6 混凝土材料（Concrete）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | Concrete | MD_Conc_Concrete.f90 | 新增 |
| - | Reinforced Concrete | MD_Conc_Reinforced.f90 | 新增 |
| - | Masonry | MD_Conc_Masonry.f90 | 新增 |

## 二、单元类型命名对齐

### 2.1 实体单元（Solid）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| PH_ElemC3D4_Ops.f90 | C3D4 | PH_Element_C3D4.f90 | 三段式命名 |
| PH_ElemC3D8_Ops.f90 | C3D8 | PH_Element_C3D8.f90 | 三段式命名 |
| PH_ElemC3D8EAS_Ops.f90 | C3D8EAS | PH_Element_C3D8EAS.f90 | 三段式命名 |
| PH_ElemC3D8FBar_Ops.f90 | C3D8FBar | PH_Element_C3D8FBar.f90 | 三段式命名 |
| PH_ElemC3D10_Ops.f90 | C3D10 | PH_Element_C3D10.f90 | 三段式命名 |
| PH_ElemC3D20_Ops.f90 | C3D20 | PH_Element_C3D20.f90 | 三段式命名 |
| PH_ElemC3D27_Ops.f90 | C3D27 | PH_Element_C3D27.f90 | 三段式命名 |

### 2.2 壳单元（Shell）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | S3 | PH_Element_S3.f90 | 新增 |
| - | S4 | PH_Element_S4.f90 | 新增 |
| - | S4R | PH_Element_S4R.f90 | 新增 |
| - | S8 | PH_Element_S8.f90 | 新增 |
| - | S9R | PH_Element_S9R.f90 | 新增 |
| - | STRI3 | PH_Element_STRI3.f90 | 新增 |
| - | STRI65 | PH_Element_STRI65.f90 | 新增 |
| - | SC8R | PH_Element_SC8R.f90 | 新增 |

### 2.3 梁单元（Beam）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | B21 | PH_Element_B21.f90 | 新增 |
| - | B22 | PH_Element_B22.f90 | 新增 |
| - | B31 | PH_Element_B31.f90 | 新增 |
| - | B32 | PH_Element_B32.f90 | 新增 |
| - | B31H | PH_Element_B31H.f90 | 新增 |
| - | PIPE31 | PH_Element_PIPE31.f90 | 新增 |
| - | PIPE32 | PH_Element_PIPE32.f90 | 新增 |

### 2.4 膜单元（Membrane）

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | M3D3 | PH_Element_M3D3.f90 | 新增 |
| - | M3D4 | PH_Element_M3D4.f90 | 新增 |
| - | M3D4R | PH_Element_M3D4R.f90 | 新增 |
| - | M3D6 | PH_Element_M3D6.f90 | 新增 |

## 三、求解器命名对齐

### 3.1 动力求解器

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| RT_SolvImpl_Algo.f90 | Implicit Dynamic | RT_Solv_ImplDyn.f90 | 三段式命名 |
| RT_SolvNonlin_Algo.f90 | Nonlinear Solver | RT_Solv_Nonlin.f90 | 三段式命名 |
| - | Explicit Dynamic | RT_Solv_ExplDyn.f90 | 新增 |

### 3.2 模态求解器

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | Frequency | RT_Solv_Freq.f90 | 新增 |
| - | Modal | RT_Solv_Modal.f90 | 新增 |
| - | Complex Eigenvalue | RT_Solv_ComplexEigen.f90 | 新增 |

### 3.3 特征值求解器

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | Eigenvalue Extraction | RT_Solv_Eigen.f90 | 新增 |
| - | Lanczos | RT_Solv_Lanczos.f90 | 新增 |
| - | Subspace | RT_Solv_Subspace.f90 | 新增 |

## 四、载荷和约束命名对齐

### 4.1 载荷类型

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | Concentrated Load | PH_Load_Concentrated.f90 | 新增 |
| - | Distributed Load | PH_Load_Distributed.f90 | 新增 |
| - | Pressure Load | PH_Load_Pressure.f90 | 新增 |
| - | Gravity Load | PH_Load_Gravity.f90 | 新增 |
| - | Centrifugal Load | PH_Load_Centrifugal.f90 | 新增 |
| - | Thermal Load | PH_Load_Thermal.f90 | 新增 |
| - | Fluid Load | PH_Load_Fluid.f90 | 新增 |
| - | Inertia Load | PH_Load_Inertia.f90 | 新增 |
| - | Follower Load | PH_Load_Follower.f90 | 新增 |

### 4.2 约束类型

| UFC当前命名 | Abaqus命名 | 对齐后命名 | 说明 |
|------------|-----------|-----------|------|
| - | Displacement BC | PH_BC_Displacement.f90 | 新增 |
| - | Rotation BC | PH_BC_Rotation.f90 | 新增 |
| - | Velocity BC | PH_BC_Velocity.f90 | 新增 |
| - | Acceleration BC | PH_BC_Acceleration.f90 | 新增 |
| - | Temperature BC | PH_BC_Temperature.f90 | 新增 |
| - | Electric BC | PH_BC_Electric.f90 | 新增 |
| - | Magnetic BC | PH_BC_Magnetic.f90 | 新增 |
| - | Equation BC | PH_BC_Equation.f90 | 新增 |
| - | Tie Constraint | PH_BC_Tie.f90 | 新增 |
| - | Coupling Constraint | PH_BC_Coupling.f90 | 新增 |
| - | MPC | PH_BC_MPC.f90 | 新增 |
| - | Rigid Body | PH_BC_RigidBody.f90 | 新增 |

## 五、命名规范对齐原则

### 5.1 域级命名
- 保持UFC现有的域级命名风格（Material, Element, Solver等）
- 域名使用驼峰命名法（CamelCase）
- 域名首字母大写

### 5.2 模型/单元命名
- 具体模型/单元命名与Abaqus完全对齐
- 使用Abaqus的标准命名（如C3D8, S4, NeoHookean等）
- 保持大小写一致（Abaqus使用首字母大写）

### 5.3 文件命名
- 算法文件：[域前缀]_[域级]_[功能].f90（三段式命名）
- 示例：MD_Hyp_NeoHookean.f90, PH_Element_C3D8.f90
- 域前缀：MD (Material), PH (Physics/Element), RT (Runtime/Solver)

### 5.4 参数命名
- 遵循UFC命名规范文档
- 使用驼峰命名法
- 参数名具有描述性

## 六、实施计划

### 6.1 第一阶段：材料模型命名对齐
- 重命名现有超弹性材料文件
- 补充缺失的材料模型
- 更新Material域结构

### 6.2 第二阶段：单元类型命名对齐
- 新增Shell、Beam、Membrane单元
- 确保单元命名与Abaqus一致
- 更新Element域结构

### 6.3 第三阶段：求解器命名对齐
- 重命名现有求解器文件
- 新增动态、模态、特征值求解器
- 更新Solver域结构

### 6.4 第四阶段：载荷和约束命名对齐
- 新增完整的载荷类型
- 新增完整的约束类型
- 更新LoadBC域结构

### 6.5 第五阶段：文档更新
- 更新命名规范文档
- 更新算法实现文档
- 创建命名映射表

## 七、验证计划

### 7.1 命名一致性检查
- 验证所有文件命名符合规范
- 验证域级命名一致性
- 验证Abaqus命名对齐

### 7.2 接口一致性检查
- 验证所有接口符合规范
- 验证参数命名一致性
- 验证数据结构一致性

### 7.3 文档一致性检查
- 验证文档与代码一致
- 验证命名规范文档更新
- 验证算法文档更新

## 八、参考文献

- Abaqus Analysis User's Manual
- Abaqus Keywords Reference Manual
- UFC命名规范参考文档
- UFC算法实现参考文档
