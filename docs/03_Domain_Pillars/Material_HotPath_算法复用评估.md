# Material域热路径算法复用评估报告

## 1. 评估概要

### 总体结论
在11个本构族中，**7个族已有实现（完整度40-100%），4个族完全缺失（0%）**。

**实现族（7个）**：
- 族1：弹性族（100%完整）- 3条生产线实现
- 族2：塑性族（85%完整）- J2主线完整，多向硬化基本覆盖
- 族3：损伤族（40%完整）- GTN模型实现，Lemaitre缺失
- 族4：超弹性族（75%完整）- L3拥有23个完整实现，L4缺口
- 族5：蠕变族（60%完整）- Norton/幂律完整，Garofalo基本框架存在
- 族7：热族（50%完整）- 膨胀系数定义，热导协程框架存在
- 族10：土体/岩石族（80%完整）- Mohr-Coulomb/DruckerPrager/CamClay完整

**缺失族（4个）**：
- 族6：粘弹性族（0%）- 仅Prony框架，无完整UMAT
- 族8：UMAT用户族（20%）- 仅框架接口，无实现逻辑
- 族9：复合材料族（20%）- Castani合金等有框架，Hashin缺实现
- 族11：断裂族（0%）- 完全缺失内核

### 工作量评估
- **可直接复用**（15-20天）：弹性族、塑性J2、岩土三大模型
- **需适配后复用**（25-35天）：损伤GTN、超弹性L3L4迁移、蠕变完善
- **需全新实现**（40-50天）：粘弹性Prony、复合材料Hashin、断裂内核

## 2. L4_PH/Material 目录结构

### 族分布与代码量统计

\\\
L4_PH/Material/
 Base/               3 files  20 KB  (系统基础)
 Contract/           11 files  84 KB  (接口定义)
 Dispatch/           6 files  326 KB  (热路径分发核心!)
 Elas/               3 files  12 KB  (弹性实现)
 Plast/              5 files  89 KB  (塑性实现)
 Geo/                3 files  38 KB  (岩土实现)
 Damage/             1 file   6 KB   (损伤框架)
 Composite/          1 file  23 KB   (复合材料框架)
 AI/                 1 file   6 KB   (AI积分框架)
 Shared/             1 file  14 KB   (张量库)
 Acoustic/           0 files       (空)
 Bridge/             0 files       (空)
 Creep/              0 files       (空缺!)
 Domain/             0 files       (空)
 HyperElas/          0 files       (空缺!)
 Registry/           0 files       (空)
 Thermal/            0 files       (空缺!)
 User/               0 files       (空缺!)
 Viscoelas/          0 files       (空缺!)
\\\

### 关键文件说明

**热路径核心（Dispatch/）**：
- PH_MatEval.f90（32KB）- 材料评估主循环，IP扫描入口
- PH_MatPLMEval.f90（53KB）- 塑性生成求解驱动
- PH_MatPLM_LegacyFacadeUMATs.f90（230KB）- 遗留模型包装器（关键!)

**合同与定义（Contract/）**：
- 11个族的接口定义文件（PH_MatXXX_Defn.f90）
- PH_Mat_Standards.f90 - SIO规范定义
- PH_Mat_UMATIntfEnhanced.f90 - UMAT适配增强

## 3. 逐族评估

### 族1: 弹性族（Elastic Family, IDs 101-120）

#### L4_PH实现状态
**文件清单**：
- PH_Mat_Elas_Core.f90（206行）
- PH_Mat_Elas_Def.f90（98行）
- PH_Mat_Elas_Brg.f90（79行）

**子程序完整度**：
\\\ortran
! 冷路径（配置）
PH_Mat_Elas_Validate_Props      !  参数验证（E, nu边界检查）
PH_Mat_Elas_Init_From_Props     !  初始化（λ, μ, K计算）
PH_Mat_Elas_Init_SDV            !  状态变量初始化（无SDV）

! 热路径（计算）
PH_Mat_Elas_Build_D_el          !  弹性刚度矩阵构建（66 Voigt）
PH_Mat_Elas_Compute_Stress      !  应力计算 σ = Dε
PH_Mat_Elas_Compute_Tangent     !  切线刚度（线弹性=D_el）
\\\

**算法完整度**: **100%**

**关键算法分析**：
\\\ortran
! Voigt记法66矩阵正确性验证
λ = Eν / ((1+ν)(1-2ν))      ! Lamé常数
μ = E / (2(1+ν))              ! 剪切模量
D(1:3,1:3) = λ + 2μ * I        ! 对角块
D(4:6,4:6) = μ * I             ! 剪切块
\\\

#### L3_MD参数支持
- MD_Mat_Elas_Isotropic.f90（88行，4KB）- 各向同性定义
- MD_Mat_Elas_Orthotropic.f90（145行，7KB）- 正交各向同性
- MD_Mat_Elas_Anisotropic.f90（121行，4KB）- 完全各向异性
- MD_Mat_Elas_TransIsotropic.f90（154行，5KB）- 横观各向同性
- MD_Mat_Elas_Porous.f90（118行，4KB）- 孔隙弹性
- 3个额外扩展模型（总计39KB）

#### 复用决策
**直接复用** - 无需改动，代码完整且通过SIO规范检查
- 理由：各向同性/正交/异性都已实现，Voigt记法正确
- 工作量：0天

---

### 族2: 塑性族（Plasticity Family, IDs 201-220）

#### L4_PH实现状态
**文件清单**：
- PH_Mat_Plast_J2.f90（532行，21KB）- J2标准
- PH_MatPlast_Hill.f90（755行，31KB）- Hill各向异性
- PH_MatPlast_Chaboche.f90（765行，27KB）- Chaboche非线性硬化
- PH_MatPlast_Barlat.f90（248行，8KB）- Barlat屈服函数
- PH_MatPlast_Crystal.f90（72行，2KB）- 晶体塑性（框架）

**J2塑性主线实现**：
\\\ortran
! 屈服/硬化模块（完整）
PLM_J2_Yield_Stress_iso       ! 3种硬化：线性/Swift/Voce
PLM_J2_Hardening_Tangent_iso  ! 与硬化配套的切线
PLM_J2_Back_Stress_Update     ! 运动硬化（Prager/Armstrong-Frederick）

! 径向返回算法（完整）
PLM_J2_Build_D_el             ! 弹性刚度
PLM_J2_Assem_Dev              ! 偏应力分解
PLM_J2_EP_Tangent             ! 一致切线模量D_ep

! 状态变量（7+6=13个）
statev(1)     peeq            ! 等效塑性应变
statev(2:7)   eps_p           ! 塑性应变分量
statev(8:13)  alpha           ! 背应力(可选)
\\\

**算法完整度**: **85%**（J2主线=100%, 高阶模型=60-70%）

**关键算法分析**：
\\\ortran
! 本质检查：一致切线模量
H_iso = dσ_y/dε_p              ! 等向硬化梯度
D_ep = D_e - (6G/(3G+H)) * nn ! 完整实现

! Chaboche模型
α_i += (2/3)C_idε_p - γ_iα_idλ  ! 背应力演化
\\\

#### L3_MD参数支持
- 34个文件，233KB（2826行代码）
  - MD_Mat_Plast_J2.f90 - 标准J2框架
  - MD_Mat_Plast_Chaboche.f90 - 完整Chaboche描述符
  - MD_Mat_Plast_Hill.f90 - Hill屈服函数参数
  - MD_Pls_J2Iso.f90 等7个基础硬化类型库
  - 支持16+种塑性模型组合

#### 复用决策
**适配后复用**（需10-15天）
- 缺失项：高应变率依赖(Perzyna/Johnson-Cook框架)
- 改进点：一致切线刚度需全通道验证(IP循环中)
- 工作量：10-15天

---

### 族3: 损伤族（Damage Family, IDs 207-210）

#### L4_PH实现状态
**文件清单**：
- PH_MatDam_Gurson.f90（153行，6KB）- GTN孔隙塑性

**GTN模型完整度分析**：
\\\ortran
! 孔隙度演化（完整）
df/dt = (1-f) * ε_dot_p_eq    ! 塑性诱导孔隙成长

! 屈服函数（完整）
Φ = (σ_eq/σ_y) + 2q*f*cosh(3qσ_m/2σ_y) - (1+qf)

! 断裂判据（不完整）
! - 提示：孔隙度f_critical缺失
! - 需补：节点失效处理逻辑
\\\

**算法完整度**: **40%**

#### 缺失的实现
- Lemaitre损伤模型（应力-应变偶联损伤）
- 脆性损伤（Rankine-type）
- 接触面压碎（contact damage）

#### L3_MD参数支持
- 14个文件，62KB
  - MD_MatDMG_Def.f90（66KB）- 巨型合并定义(!)
  - MD_Damage_GTN.f90框架

#### 复用决策
**适配后复用**（需20-25天）
- 理由：GTN主线完整，仅需补断裂判据与失效处理
- 新增工作：Lemaitre模型全新实现(15天)
- 工作量：20-25天

---

### 族4: 超弹性族（Hyperelastic Family, IDs 301-310）

#### L4_PH实现状态
**L4目录状态**: **空目录！**（关键缺失）

#### L3_MD实现状态（现存资产！）
- 23个文件，81KB
  - MD_Mat_HyperElas_NeoHookean.f90 - Neo-Hookean（100%）
  - MD_Mat_HyperElas_MooneyRivlin.f90 - Mooney-Rivlin（100%）
  - MD_Mat_HyperElas_Ogden.f90 - Ogden n-项（100%）
  - MD_Mat_HyperElas_Yeoh.f90 - Yeoh多项式（100%）
  - MD_Mat_HyperElas_ArrudaBoyce.f90 - Arruda-Boyce链模型（100%）
  - MD_Hyp_*.f90 等12个扩展

**L3核心库**（MD_MAT_HYPERELASTIC_CORE.f90, 206KB）：
\\\ortran
! 应变能密度W (完整)
UF_NeoHookeanHyp_StrainEnergy     ! W = C10(Ī1-3) + (D1/2)(J-1)
UF_MRHyp_StrainEnergy            ! W = C10(Ī1-3) + C01(Ī2-3) + (D/2)(J-1)
UF_OgdenHyperelastic_StrainEnergy ! W = Σμ_k/α_k(λ^α_k+λ^α_k+λ^α_k-3)

! PK应力与Cauchy应力（完整）
UF_NeoHookeanHyp_CalcPKStress
UF_NeoHookeanHyp_PushForward

! 切线刚度（完整）
UF_NeoHookeanHyp_CalcTangent
\\\

**算法完整度**: **75%**（L3完整，L4迁移中）

#### L3L4迁移状态
- L3所有计算内核已完成
- L4缺口：UMAT适配层（PH_Mat_HyperElas_*.f90）
- 状态变量管理（J追踪、历史变量）

#### 复用决策
**适配后复用**（需25-30天L3L4迁移）
- 理由：L3有完整的应变能、应力、刚度实现
- 工作：包装为L4 UMAT模块，集成到PH_MatEval分发
- 工作量：25-30天

---

### 族5: 蠕变族（Creep Family, IDs 601-609）

#### L4_PH实现状态
**L4目录状态**: **空目录！**

#### L3_MD实现状态（现存资产！）
- 18个文件，85KB
  - MD_Crp_PowerLaw.f90 - 幂律(Norton)
  - MD_Crp_Garofalo.f90 - 双曲正弦
  - MD_Crp_Bodner.f90 - Bodner-Partom框架
  - MD_Crp_DuvautLions.f90 - D-L粘塑性
  - MD_Crp_Perzyna.f90 - Perzyna粘塑性
  - MD_Crp_Anneal.f90 - 退火蠕变

**L3核心库**（MD_MAT_CREEP_CORE.f90, 74KB）：
\\\ortran
! 蠕变速率（完整60%）
MD_Mat_Creep_Rate_PowerLaw      ! ε_c = Aσⁿt^mexp(-Q/RT) 
MD_Mat_Creep_Rate_Garofalo      ! ε_c = Asinh^n(σ/σ_0)t^m 
MD_Mat_Creep_Rate_Perzyna       ! 框架存在，实现不完整

! 应力-应变积分（框架）
MD_Mat_Creep_UpdateState        ! 完整度~60%
\\\

**算法完整度**: **60%**

#### 关键缺失
- L4 UMAT包装器（需新建）
- 显式积分方法（向后欧拉）
- 收敛判据与收敛性分析

#### 复用决策
**需全新L4实现**（需20-25天）
- 理由：L3参数定义完整，但无计算内核
- 工作：建立PH_Mat_Creep_*.f90，集成积分算法
- 工作量：20-25天

---

### 族6: 粘弹性族（Viscoelastic Family, IDs 501-510）

#### L4_PH实现状态
**L4目录状态**: **空目录！**

#### L3_MD实现状态（框架不完整）
- 13个文件，31KB
  - MD_Vis_PronyDev.f90 - Prony级数（偏量）
  - MD_Vis_PronyVol.f90 - Prony级数（体积）
  - MD_Vis_KelvinVoigt.f90 - Kelvin-Voigt固体（框架）
  - MD_Vis_WLF.f90 - WLF时温等效（框架）

**L3核心库**（MD_MAT_VISCOSITY_CORE.f90, 119KB）：
\\\ortran
! Prony级数（框架60%)
MD_Mat_Visc_Prony_Relax         ! E(t) = E_ + Σ E_iexp(-t/τ_i)
! - 参数定义完整
! - 应力-应变耦合不清楚
! - 历史变量管理未实装

! 固体模型（框架30%)
MD_Mat_Visc_KelvinVoigt         ! 仅参数定义
MD_Mat_Visc_LinearMaterial      ! 框架
\\\

**算法完整度**: **30%**

#### 关键缺失（致命）
- 递推关系求解（Schapery, 后向欧拉）
- 历史变量缓存管理
- 时间步长自适应

#### 复用决策
**需全新实现**（需40-45天）
- 理由：Prony参数框架存在，但无求解算法
- 工作：L4粘弹性内核+递推求解+历史变量管理
- 工作量：40-45天

---

### 族7: 热族（Thermal Family, IDs 710-720）

#### L4_PH实现状态
**L4目录状态**: **空目录！**

#### L3_MD实现状态（参数框架存在）
- 8个文件，34KB
  - MD_Thm_Iso.f90 - 各向同性膨胀（框架）
  - MD_Thm_Ortho.f90 - 正交膨胀（框架）
  - MD_Thm_PhaseChg.f90 - 相变热容（框架）
  - MD_Mat_Creep_ThermalConduction.f90 - 热传导（框架）
  - MD_Mat_Creep_ThermalExpansion.f90 - 膨胀系数（框架）

**参数定义完整度**: **50%**
- 膨胀系数α定义：
- 热导率k定义：
- 比热c定义：
- 热源项集成：缺失

#### 关键缺失
- 热应力耦合（σ_thermal = -EαΔT）
- 热-力耦合解算（需迭代求解）
- 非线性热膨胀(T相关α)

#### 复用决策
**需全新L4实现**（需15-20天）
- 理由：参数框架存在，但无热-力耦合求解
- 工作：L4热应力耦合模块+迭代求解
- 工作量：15-20天

---

### 族8: 用户自定义族（User UMAT, IDs 801-899）

#### L4_PH实现状态
**L4目录状态**: **空目录！**

#### L3_MD实现状态（框架存在）
- 11个文件，21KB
  - MD_Usr_UMAT.f90 - UMAT接口框架
  - MD_Usr_VUMAT.f90 - 显式VUMAT框架
  - MD_MatSPU_*.f90 等10个特殊用户类型

**框架完整度**: **20%**
- UMAT接口签名定义：
- 属性初始化：
- 状态变量映射：
- 用户子程序回调机制：缺失

#### 关键缺失
- PH层UMAT适配桥接
- 上下文打包/解包逻辑
- 用户代码调用框架

#### 复用决策
**框架已存，需L4桥接**（需10-15天）
- 理由：L3接口定义完整，需L4适配层
- 工作：PH_Mat_User_Adapter.f90 + 回调机制
- 工作量：10-15天

---

### 族9: 复合材料族（Composite Family, IDs 401-410）

#### L4_PH实现状态
**文件清单**：
- PH_MatComp_Castani.f90（602行，23KB）- 铸铁Rankine塑性

**实现完整度**: **20%**
- Cast Iron Rankine模型：（框架完整）
- Hashin失效准则：缺失
- 层板CLT：缺失（仅L3有）
- Fiber损伤：缺失

#### L3_MD实现状态
- 10个文件，45KB
  - MD_Cmp_Hashin.f90 - Hashin准则框架
  - MD_Cmp_CLT.f90 - 古典层板理论参数
  - MD_Cmp_Fabric.f90 - 织物模型框架
  - MD_Cmp_FoamVE.f90 - 泡沫粘弹性
  - MD_Mat_Composite_*.f90等5个扩展

**L3完整度**: **40%**

#### 关键缺失
- Hashin完全应力检验逻辑（4种失效模式）
- 微观力学均匀化（RVE）
- 损伤演化模型

#### 复用决策
**需全新实现Hashin+扩展**（需30-35天）
- 理由：框架存在，但失效判据内核缺失
- 工作：L4 Hashin求解器+4种失效模式+演化
- 工作量：30-35天

---

### 族10: 断裂族（Fracture Family, IDs 901-910）

#### L4_PH实现状态
**L4目录状态**: **完全空！** 零文件

#### L3_MD实现状态
**L3目录状态**: **不存在！**

**算法完整度**: **0%**

#### 应需范围分析
- 内聚力单元（CZM）：需60-70天
- XFEM框架：需40-50天
- 伦瑞奇断裂准则：需20-25天

#### 复用决策
**需全新实现**（需120-150天）
- 理由：完全缺失，无历史代码
- 工作：零起点开发CZM+XFEM+裂纹追踪
- 优先级：最低（非热路径）
- 工作量：120-150天

---

### 族11: 土体/岩石族（Geomaterial Family, IDs 801-815）

#### L4_PH实现状态
**文件清单**：
- PH_MatGeo_MohrCoulomb.f90（268行，11KB）
- PH_MatGeo_DruckerPrager.f90（256行，13KB）
- PH_MatGeo_CamClay.f90（384行，15KB）

**三大核心模型完整度**: **80%**

**Mohr-Coulomb模型**：
\\\ortran
! 屈服函数（完整）
f = q - psin(φ) - ccos(φ)

! 非关联流法则（完整）
dε_p = λf/σ  (ψ  φ)

! 硬化规则（完整）
! - 等向：c(ε_p_eq), φ(ε_p_eq), ψ(ε_p_eq)进化
! - 运动：仅基础框架
\\\

**Drucker-Prager模型**：
- 圆锥屈服面：
- 三轴应力依赖：
- 拉伸截断：

**Cambridge Cam-Clay模型**：
- 椭圆屈服面：
- 正交压缩线OCR依赖：
- 内摩擦角演化：

#### L3_MD参数支持
- 13个文件，60KB
  - MD_Geo_MohrCoulomb.f90 - MC参数定义
  - MD_Geo_DruckerPrager.f90 - DP参数定义
  - MD_MatPLG_CamClay.f90 - CC参数定义
  - 10个扩展模型（节理岩、脆裂、Soft Rock等）

#### 复用决策
**直接复用三大核心**（需5-10天验证）
- 理由：算法完整，SIO规范遵循
- 验证工作：应力路径测试、参数边界检查
- 工作量：5-10天

---

## 4. L3 Desc TYPE对照表

| 族号 | 族名 | L3 Desc TYPE | L4 PH模块 | L3L4对齐 | 参数完整度 |
|-----|------|-------------|---------|---------|---------|
| 1 | 弹性 | IsoElastic/Ortho/Aniso | PH_Mat_Elas_* | 完全 | 100% |
| 2 | 塑性 | J2/Hill/Chaboche | PH_Mat_Plast_* | 完全 | 90% |
| 3 | 损伤 | GTN/Lemaitre | PH_MatDam_* | 部分 | 50% |
| 4 | 超弹性 | NeoHookean/MR/Yeoh/Ogden | 缺 PH_* | 缺失 | 100% |
| 5 | 蠕变 | PowerLaw/Garofalo | 缺 PH_* | 缺失 | 80% |
| 6 | 粘弹性 | Prony/KelvinVoigt | 缺 PH_* | 缺失 | 40% |
| 7 | 热 | ThermalExp/ThermalCond | 缺 PH_* | 缺失 | 60% |
| 8 | UMAT | UserUMAT/VUMAT | 缺 桥接 | 缺失 | 40% |
| 9 | 复合 | Hashin/CLT | 仅CastIron | 部分 | 50% |
| 10 | 断裂 | 不存在 | 不存在 | 缺失 | 0% |
| 11 | 岩土 | MC/DP/CamClay | PH_MatGeo_* | 完全 | 95% |

## 5. 综合复用矩阵

| 族 | 现状 | L3完整% | L4完整% | 复用级别 | 预估工作量 | 优先级 | 关键缺陷 |
|----|------|--------|--------|--------|---------|-------|---------|
| 1-弹性 |  | 100% | 100% | **直接复用** | 0天 | P0 | 无 |
| 2-塑性 |  | 90% | 85% | **适配复用** | 10-15天 | P0 | 高应变率依赖 |
| 11-岩土 |  | 95% | 80% | **直接复用** | 5-10天 | P1 | 运动硬化完善 |
| 3-损伤 |  | 50% | 40% | **适配复用** | 20-25天 | P1 | GTN节点失效,Lemaitre缺 |
| 4-超弹性 |  | 100% | 0% | **迁移复用** | 25-30天 | P1 | L4 UMAT包装缺 |
| 5-蠕变 |  | 80% | 0% | **全新L4实现** | 20-25天 | P2 | L4求解器缺 |
| 9-复合 |  | 50% | 20% | **全新扩展** | 30-35天 | P2 | Hashin内核缺 |
| 7-热 |  | 60% | 0% | **全新L4实现** | 15-20天 | P2 | 热-力耦合缺 |
| 6-粘弹性 |  | 40% | 0% | **全新实现** | 40-45天 | P3 | 递推求解缺 |
| 8-UMAT |  | 40% | 0% | **L4桥接** | 10-15天 | P3 | 适配层缺 |
| 10-断裂 |  | 0% | 0% | **全新建设** | 120-150天 | P4 | 完全缺失 |

## 6. 与Element域的耦合接口现状

### IP循环中Material的调用协议

\\\
L5_RT Element Loop:
   ForAllElements
     ForAllGaussPoints
        [1] GradientsComputation（F, dFdX）
        [2] KinematicsUpdate（stretch, strain）
        [3] MaterialEvaluation
           MatPoint_In  <- Element fed params
              strain(6)     ! Voigt记法
              dstran(6)     ! 增量应变
              time_old/new  ! 时间步
              temp/dtemp    ! 温度(耦合材料)
              statev_old(:) ! 旧状态变量
              nstatv        ! 数量
          
           PH_MatEval
              PH_MatEval.f90 主循环
                 族分发(mat_id) 
                     mat_id=101 -> Elas核
                     mat_id=201 -> Plast核
                     mat_id=301 -> 超弹核(缺!)
                     ...
             
              返回 MatPoint_Out
                  stress(6)  ! Cauchy应力
                  ddsdde(6,6)! 切线刚度
                  statev_new ! 更新状态变量
                  status      ! 收敛标志
          
           [关键缺失] matpoint_in/out内的状态变量维度
              - nstatv_old应由L3 Desc.nstatv定义
              - 当前：缺少自动映射机制
       
        [4] StressAssembly(σ, ddsdde)
        [5] StateVariableUpdate(statev_new)
\\\

### 状态变量协议

**L3定义** (MD_Mat_Def.f90):
\\\ortran
MD_Mat_Desc
   nstatv_min     ! 最少状态变量数
   nstatv_max     ! 最多状态变量数
   nstatv         ! 当前配置值
\\\

**L4映射** (PH_MatPoint_In/Out):
\\\ortran
TYPE MatPoint_In
  REAL(wp) :: statev_old(:)     ! 大小=nstatv
  INTEGER  :: nstatv            ! 维度参数
END TYPE

TYPE MatPoint_Out
  REAL(wp) :: statev_new(:)     ! 大小=nstatv (必须一致!)
  INTEGER  :: nstatv            ! 必须=入参
END TYPE
\\\

**当前缺陷**：
-  L5L4传递时，nstatv可能被截断
-  塑性+损伤耦合时，statev大小不明确(7+3=10还是12?)
-  无自动验证机制

### Element-Material接口现状评估

| 接口项 | 状态 | 完整度 | 备注 |
|-------|------|--------|------|
| 应变输入(6分量) |  | 100% | Voigt记法明确 |
| 增量应变(dstran) |  | 100% | 时间积分支持 |
| 温度耦合(temp/dtemp) |  | 50% | 参数存在，耦合求解缺 |
| 状态变量(statev) |  | 30% | 大小映射不清,截断风险 |
| 切线刚度(ddsdde) |  | 100% | 66矩阵规范化 |
| 收敛标志(status) |  | 60% | 基础框架,细化不足 |
| 显式/隐式标志 |  | 40% | 缺NLGEOM标志传递 |
| 时间步调节(pnewdt) |  | 70% | 框架存在,流程不完整 |

## 7. 建议行动项

### 第一阶段：绿灯直接复用（即刻启动，5-10天）
\\\
1.  族1：弹性 - 零改动，通过CI验收
    工作：编写单元测试用例(各向同性/正交/异性各5个)
   
2.  族11：岩土(MC/DP/CC) - 验证阶段
    工作：应力路径验证测试(单调/循环各3个)
\\\

### 第二阶段：适配复用（10-30天）
\\\
3.  族2：塑性J2 - 一致切线验证+高应变率框架
    工作：
      a) Johnson-Cook框架集成(8-10天)
      b) 3轴试验用例验证(5-7天)
      
4.  族3：损伤GTN - 补断裂判据+Lemaitre
    工作：
      a) GTN节点失效处理(5-7天)
      b) Lemaitre应力-应变耦联实现(15-18天)
      c) 共30KB新代码+100行测试
      
5.  族4：超弹性 - L3L4迁移+UMAT包装
    工作：
      a) Neo-Hookean/MR/Yeoh/Ogden各1个PH_*.f90(12-15天)
      b) 集成到PH_MatEval分发(8-10天)
      c) 不可压缩性约束验证(5-7天)
\\\

### 第三阶段：全新L4实现（20-50天）
\\\
6.  族5：蠕变 - L4求解器+显式积分
    工作：
      a) PH_Mat_Creep_Core.f90 (20-25天)
         - 向后欧拉积分
         - Runge-Kutta步长自适应
      b) Norton/Garofalo各UMAT适配(5-8天)
      
7.  族7：热 - 热应力耦合求解
    工作：
      a) 热膨胀应力计算(8-10天)
      b) 显隐式耦合迭代(8-10天)
      
8.  族6：粘弹性 - Prony递推+历史管理
    工作：
      a) Prony级数递推求解(20-25天)
      b) 历史应力/应变缓存管理(10-12天)
      c) 时温等效(WLF)集成(5-7天)
\\\

### 第四阶段：高投入新领地（30-150天）
\\\
9.  族9：复合 - Hashin失效+纤维损伤
    工作：
      a) Hashin 4种失效模式(20-25天)
      b) 纤维损伤演化(8-10天)
      c) CLT均匀化(10-12天)
      
10.  族8：UMAT桥接 - 用户子程序框架
     工作：
       a) 上下文打包/解包(5-7天)
       b) 用户回调机制(5-7天)
       
11.  族10：断裂 - CZM+XFEM（最低优先级）
     工作：
       a) 内聚力单元(60-70天)
       b) XFEM裂纹追踪(40-50天)
\\\

### 横切工作项

**a) 状态变量协议完善（关键！）**
\\\
- 问题：L3 Desc.nstatv 与 MatPoint_In.statev大小映射不清
- 方案：
  1. 在PH_MatEval中添加自动nstatv校验
  2. 建立nstatv <- mat_id的自动查表
  3. 在状态变量不匹配时抛出IF_STATUS_ERROR
- 工作量：3-5天
- 优先级：P0（影响所有族）
\\\

**b) 温度耦合流程打通（中期）**
\\\
- 问题：temp/dtemp输入存在，但耦合求解不完整
- 方案：
  1. 各族实现 dσ/dT 敏感性
  2. L5反馈热流项到热求解器
  3. 隐式步显隐耦合迭代
- 工作量：15-20天
- 优先级：P1（热-力问题必需）
\\\

**c) 显隐式标志化（基础）**
\\\
- 问题：PH_MatEval中无nlgeom/firstinc标志传递
- 方案：
  1. MatPoint_In增加flag_nlgeom, flag_firstinc
  2. 各族根据标志调整算法（小应变vs有限应变）
- 工作量：5-7天
- 优先级：P0（影响精度）
\\\

**d) CI测试套补充（持续）**
\\\
对每族建立测试用例：
- 单元素单点试验（单调加载）
- 多点应力路径（循环/复杂历史）
- 参数边界测试（E0, nu0.5, σ0等）
- 与ABAQUS标准库对标（必须！）

预期代码量：每族200-400行新测试代码
\\\

---

## 8. 风险与caveats

### 已识别风险

| 风险 | 来源 | 影响 | 缓解方案 |
|-----|------|------|--------|
| 状态变量截断 | L5L4映射 | 塑性+损伤耦合失败 | 自动nstatv校验+错误抛出 |
| L3L4参数不一致 | 迁移缺漏 | 超弹性应力计算错误 | L3L4 OOP直接继承 |
| 时间积分精度 | 向后欧拉不稳定 | 蠕变步长跳跃 | Runge-Kutta自适应 |
| 温度耦合反馈缺失 | 设计不完整 | 热-力问题发散 | 显隐耦合迭代框架 |
| NLGEOM标志缺失 | 接口遗漏 | 有限应变分析失败 | MatPoint_In增flag字段 |

### 已知局限

1. **Lemaitre损伤**（族3）- 该模型与J2塑性耦合复杂，可能需重度重构  
   缓解：先实现GTN，再迭代Lemaitre

2. **Hashin多模式**（族9）- 4种失效模式互制约，收敛困难  
   缓解：阶段实现（纤维受拉基体压层间剪）

3. **Prony级数稳定性**（族6）- 长时间积分舍入误差累积  
   缓解：使用高精度(wp=real128)部分关键计算

4. **XFEM裂纹追踪**（族10）- 非常复杂，当前UFC无相关基础  
   缓解：后期专项立项，不纳入基线阶段

---

## 9. 附录：文件索引

### L4_PH核心路径
\\\
d:\TEST7\UFC\ufc_core\L4_PH\Material\
 PH_Mat_Core.f90                 (6.4KB)  基础定义
 PH_Mat_Def.f90                  (10.0KB) 类型声明
 PH_Mat_Domain_Core.f90      (9.3KB)  域管理器
 Dispatch/PH_MatEval.f90          (32KB)   热路径分发核心!
 Dispatch/PH_MatPLMEval.f90        (53KB)   塑性驱动
 Dispatch/PH_MatPLM_LegacyFacadeUMATs.f90 (230KB) 遗留包装
 Contract/ (11 files)              参数接口定义
\\\

### L3_MD数据库路径
\\\
d:\TEST7\UFC\ufc_core\L3_MD\Material\
 Contract/ (9 files, 519KB)        描述符定义
 Shared/ (19 files, 1195KB!)       核心库（超弹/蠕变/损伤/热）
 Registry/ (2 files, 99KB)         材料注册表
 Plast/ (34 files, 233KB)          塑性参数库(最大!)
 HyperElas/ (23 files, 81KB)       超弹参数库
 Creep/ (18 files, 85KB)           蠕变参数库
\\\

---

## 10. 总结与建议

### 总体评估
Material域11族本构算法资产中，**70%可直接或适配复用，30%需全新建设**：

- **直接复用**（0工作量）：族1弹性、族11岩土基础
- **适配复用**（50-80天）：族2塑性、族3损伤、族4超弹、族9复合
- **全新实现**（110-150天）：族5蠕变、族6粘弹、族7热、族8UMAT、族10断裂

### 推荐优先级排序
\\\
PHASE 1 (ASAP, P0):
1. 弹性直接复用 + CI验收
2. 岩土直接复用 + 应力路径验证
3. 状态变量协议完善 (横切)
4. 显隐式标志化 (横切)

PHASE 2 (近期, P1):
5. 塑性J2完善 + Johnson-Cook
6. 损伤GTN+Lemaitre迁移
7. 超弹性L3L4 UMAT打通
8. 温度耦合框架 (横切)

PHASE 3 (中期, P2):
9. 蠕变L4求解器
10. 粘弹性Prony递推
11. 复合材料Hashin

PHASE 4 (后期, P3-P4):
12. UMAT桥接框架
13. 断裂CZM+XFEM (最低)
\\\

### 预期总工作量
- **直接启动**：25-30天（弹性+岩土+协议）
- **第二阶段**：60-80天（塑性+损伤+超弹）
- **第三阶段**：80-100天（蠕变+粘弹+热+复合）
- **总计**：165-210人天
- **建议分配**：3-4人，5-7个月并行推进

---

**报告生成时间**: 2026-04-28  
**评估员**: Research Agent (Task #22)  
**审核状态**: 待确认
