# UFC UMAT props/statev 布局文档（73 种）

**版本**: 1.2  
**日期**: 2026-03-19  
**状态**: Phase D | Material 算法规范化

### 与 Registry 同步（维护说明）

- **代码权威**：`L4_PH/Material/Registry/PH_Mat_Reg_Core.f90` 中 `PH_Mat_Reg_Add` 的 `num_props`、`nStatev`、`props_schema=` 为布局主源；本文档用于人读与评审。
- **自动核对**（严格 `props_schema` 逗号分段数 = `num_props`，跳过含 `slot`/`reserved` 等占位项）：
  ```text
  python scripts/check_mat_props_schema.py
  ```
- 若增删材料型号，**先改 Reg 与实现**，再更新本表对应行。

---

## 一、概述

本文档定义 7 大类、73 种 mat_id 的 `props` 与 `statev` 布局，供 `Build_UMAT_Context_From_Mat` 与各 UMAT 实现参考。

- **props**: 材料参数数组，由 `MatProperties%props` 或 `Map_To_*_Params` 填充
- **statev**: 状态变量数组，与 `MatState_Generic` 或 Defn 的 `state_inout` 序列化兼容

### 实现状态说明

| 状态 | 含义 |
|------|------|
| **FULL** | 完整本构实现，与理论一致 |
| **STUB** | 有简化实现，切线或部分算法待补全 |
| **PLACEHOLDER** | 占位实现（如 sigma=sigma_old），本构待实现 |

---

## 二、弹性 (101-112, 301-310)

### 2.1 线弹性 101-112

| mat_id | 名称 | num_props | nStatev | props 布局 | statev 布局 |
|--------|------|-----------|---------|------------|-------------|
| 101 | ElasticIso | 2 | 0 | E, nu | — |
| 102 | OrthoElastic | 9 | 0 | D11,D22,D33,D12,D13,D23,G12,G13,G23 | — |
| 103 | ElasticTransIso | 5 | 0 | E1,E2,nu12,G12,G23 | — |
| 104 | ElasticAniso | 21 | 0 | 6×6 对称矩阵 | — |
| 105 | PorousElastic | 4 | 0 | E,nu,porosity,k | — |
| 106 | LowElastic | 2 | 0 | E,nu | — |
| 108 | ThermoElastic | 4 | 0 | E,nu,alpha,T_ref | — |
| 109 | PiezoElastic | 10 | 0 | E,nu,d31,d33,e33,... | — |
| 110 | ThermoElecElastic | 12 | 0 | E,nu,alpha,kappa,... | — |
| 111 | PoroElastic | 6 | 0 | E,nu,k_perm,M,... | — |
| 112 | LaminatedElastic | 9 | 0 | 同 OrthoElastic | — |

### 2.2 超弹性 301-310

| mat_id | 名称 | num_props | nStatev | props 布局 | statev 布局 |
|--------|------|-----------|---------|------------|-------------|
| 301 | MooneyRivlin | 7 | 9 | C10,C01,D1,... | 见 §十.4 |
| 302 | Ogden | 4 | 9 | mu1,alpha1,D1,N | 见 §十.5 |
| 303 | NeoHookean | 2 | 9 | C10,D1 | 见 §十.6 |
| 304 | Yeoh | 4 | 9 | C10,C20,C30,D1 | 见 §十.7 |
| 305 | ArrudaBoyce | 4 | 9 | mu,lambda_m,D1,N | 见 §十.8 |
| 306 | Marlow | 2 | 0 | W_uniaxial,D1 | — |
| 307 | Polynomial | 6 | 0 | C10,C01,C20,C11,C02,D1 | — |
| 308 | ReducedPolynomial | 4 | 0 | C10,C20,C30,D1 | — |
| 309 | HyperStressSoft（Reg: STUB） | 4 | 2 | C10,C01,D1,r | damage,lambda_max |
| 310 | HyperPermanentDef | 5 | 4 | C10,D1,... | 永久变形相关 |

---

## 三、塑性 (201-220)

| mat_id | 名称 | 实现状态 | num_props | nStatev | props 布局 | statev 布局 |
|--------|------|----------|-----------|---------|------------|-------------|
| 201 | PlasticJ2 | FULL | 4 | 7 | E,nu,sigma_y0,H | 见 §十.1 |
| 202 | PlasticDP | FULL | 5 | 8 | E,nu,phi,cohesion,psi | 见 §十.2 |
| 203 | PlasticRateDep | FULL | 5 | 7 | E,nu,sigma_y0,m,C | 同 J2 |
| 204 | JohnsonCook | FULL | 9 | 10 | E,nu,A,B,n,C,m,T_ref,T_melt | 塑性应变、温度等 |
| 205 | PorousMetalPlast | STUB | 13 | 8 | E,nu,sy0,...,f0 | 见 §十.3 |
| 206 | CastIronPlast | FULL | 5 | 6 | E,nu,sigma_t,sigma_c,... | — |
| 207 | ConcreteDamagePlast | STUB | 12 | 10 | E,nu,fc,ft,psi,... | 损伤、塑性 |
| 208 | ConcreteSmearedCrack | FULL | 8 | 6 | E,nu,ft,Gf,... | — |
| 209 | ConcreteBrittleCrack | FULL | 6 | 4 | E,nu,ft,Gf,... | — |
| 210 | CapPlasticity | FULL | 8 | 8 | E,nu,phi,c,pt_cap,at_cap,R_cap,beta_cap | — |
| 211 | MohrCoulomb | FULL | 5 | 7 | E,nu,phi,c,psi | — |
| 212 | CrushableFoamPlast | STUB | 5 | 4 | E,nu,sy0,eps_dens,mu_crush | — |
| 213 | HyperElastPlast | STUB | 6 | 8 | C10,C01,sy0,H,eta_visc,K_bulk | — |
| 214 | FabricPlast | FULL | 10 | 6 | E1,E2,nu12,G12,sy1,sy2,tau12,H1,H2,H12 | — |
| 215 | JointMatPlast | FULL | 7 | 5 | kn,ks,phi_deg,JRC,JCS,sig_t,res_fac | — |
| 216 | BilayerViscoplast | FULL | 8 | 14 | E,nu,eta1,eta2,sy1,sy2,H1,H2 | — |
| 217 | ORNLConstitutive | STUB | 10 | 12 | A1,Q1,n1,A2,Q2,n2,H_iso,slot9,slot10 | — |
| 218 | DeformationPlast | STUB | 5 | 6 | E,nu,sy0,H,beta_N | — |
| 219 | CyclicPlast | STUB | 7 | 10 | E,nu,sy0,Qinf,b,C,gamma | Chaboche 类（实现演进中） |
| 220 | HillPlasticity | FULL | 7 | 8 | E,nu,sy0,R0,R45,R90,H_iso | — |

---

## 四、粘弹性 (401-408)

| mat_id | 名称 | 实现状态 | num_props | nStatev | props 布局 | statev 布局 |
|--------|------|----------|-----------|---------|------------|-------------|
| 401 | LinearViscoElastic | PLACEHOLDER | 3 | 0 | E,nu,tau | — (Phase2: Prony 历史) |
| 402 | NonlinearViscoElast | FULL | 5 | 6 | E,nu,tau1,tau2,... | 粘弹性历史 |
| 403 | Creep | FULL | 4 | 4 | E,nu,A,n | 蠕变应变 |
| 404 | Swelling | 3 | 2 | E,nu,swell_coef | — |
| 405 | Viscoplastic | 6 | 8 | E,nu,sigma_y0,K,n,... | — |
| 406 | RateDepCreep | 5 | 6 | E,nu,A,n,m | — |
| 407 | ThermoViscoElast | 6 | 6 | E,nu,tau,alpha,... | — |
| 408 | ViscoElastPlastCoup | 8 | 10 | 粘弹塑性耦合参数 | — |

---

## 五、损伤 (501-509)

| mat_id | 名称 | num_props | nStatev | props 布局 | statev 布局 |
|--------|------|-----------|---------|------------|-------------|
| 501 | DuctileMetalDamage | 6 | 8 | E,nu,sigma_y0,... | 损伤、塑性 |
| 502 | FiberCompositeDamage | 10 | 12 | E1,E2,G12,nu12,... | 层间损伤 |
| 503 | LowCycleFatigueDamage | 5 | 6 | E,nu,Nf,b,c | 疲劳损伤 |
| 504 | ProgressiveFailure | 8 | 10 | — | — |
| 505 | BrittleFracture | 4 | 4 | E,nu,Gf,ft | — |
| 506 | FatigueCrackGrowth | 6 | 8 | — | — |
| 507 | InterfaceDamage | 5 | 6 | — | — |
| 508 | InterlaminarDelam | 7 | 8 | — | — |
| 509 | DynamicFailure | 6 | 6 | — | — |

---

## 六、多场耦合 (601-607)

| mat_id | 名称 | 实现状态 | num_props | nStatev | props 布局 | statev 布局 |
|--------|------|----------|-----------|---------|------------|-------------|
| 601 | ThermalConduction | PLACEHOLDER | 2 | 0 | k,rho_cp | — |
| 602 | ThermalExpansion | FULL | 4 | 0 | E,nu,alpha,T_ref | — |
| 603 | ThermoElecCoupling | PLACEHOLDER | 8 | 0 | kappa,sigma_elec,... | — |
| 604 | PiezoCoupling | FULL | 10 | 0 | d31,d33,e33,... | — |
| 605 | PoreFluidFlow | PLACEHOLDER | 6 | 4 | k_perm,... | — |
| 606 | MassDiffusion | PLACEHOLDER | 3 | 2 | D,c0,... | — |
| 607 | AcousticMedium | PLACEHOLDER | 2 | 0 | rho,c_sound | — |

---

## 七、岩土与流体 (701-703)

| mat_id | 名称 | 实现状态 | num_props | nStatev | props 布局 | statev 布局 |
|--------|------|----------|-----------|---------|------------|-------------|
| 701 | SoilMechanics | PLACEHOLDER | 8 | 10 | E,nu,c,phi,... | — |
| 702 | EquationOfState | PLACEHOLDER | 6 | 4 | rho0,c0,gamma,... | — |
| 703 | HydrostaticFluid | PLACEHOLDER | 2 | 0 | rho,K | — |

---

## 八、辅助与用户 (704-708)

| mat_id | 名称 | 实现状态 | num_props | nStatev | props 布局 | statev 布局 |
|--------|------|----------|-----------|---------|------------|-------------|
| 704 | Electromagnetic | PLACEHOLDER | 8 | 4 | mu_r,epsilon_r,... | — |
| 705 | Damping | FULL | 4 | 2 | alpha,beta,... | — |
| 706 | MassPoint | FULL | 1 | 0 | mass | — |
| 707 | ConnectorMaterial | FULL | 6 | 4 | stiffness,... | — |
| 708 | UMAT | PLACEHOLDER | 0 | 0 | 用户自定义 | 用户自定义 |

---

## 九、state_inout 与 statev 序列化约定

Defn 的 `state_inout` 类型为 `TYPE(*), OPTIONAL`。与 UMAT `statev` 的约定：

1. **有 statev 的 mat_id**：`state_inout` 若为 `REAL(wp), ALLOCATABLE` 或 `REAL(wp), POINTER`，则按 `statev(1:nstatv)` 顺序读写
2. **无 statev 的 mat_id**：`state_inout` 可省略或为空
3. **Build_UMAT_Context_From_Mat**：从 `MatProperties` 或外部 state 提取/填充 `ctx%statev`

---

## 十、statev 详细布局（Phase 4 InitStateVars 对接材料）

以下材料已实现 `XXX_InitStateVars` 并注册至 `PH_Mat_Reg_Core`，`PH_Mat_InitializeStateVars` 会按 mat_id 调用以填充材料相关初值。

### 10.1 J2 塑性 (mat_id 201, nStatev=7)

| Slot | 含义 | 初值 |
|------|------|------|
| 1 | equiv_plastic_strain | 0 |
| 2-7 | strain_plastic(1:6) | 0 |

### 10.2 Drucker-Prager (mat_id 202, nStatev=8)

| Slot | 含义 | 初值 |
|------|------|------|
| 1 | equiv_plastic_strain | 0 |
| 2 | volumetric_plastic_strain | 0 |
| 3-8 | strain_plastic(1:6) | 0 |

### 10.3 Gurson/GTN (mat_id 205, nStatev=8)

| Slot | 含义 | 初值 |
|------|------|------|
| 1 | void_fraction | f_0 (props(13)) |
| 2 | equiv_plastic_strain | 0 |
| 3-8 | strain_plastic(1:6) | 0 |

### 10.4 Mooney-Rivlin (mat_id 301, nStatev=9)

| Slot | 含义 | 初值 |
|------|------|------|
| 1-3 | F(1,1), F(2,2), F(3,3) | 1 |
| 4-6 | F(1,2), F(2,3), F(1,3) | 0 |
| 7 | J_volume_ratio | 1 |
| 8 | I1_bar | 3 |
| 9 | strain_energy | 0 |

### 10.5 Ogden (mat_id 302, nStatev=9)

| Slot | 含义 | 初值 |
|------|------|------|
| 1-6 | 同上 (deformation gradient) | 同上 |
| 7 | J_volume_ratio | 1 |
| 8 | principal_stretch(1) | 1 |
| 9 | strain_energy | 0 |

### 10.6 Neo-Hookean (mat_id 303, nStatev=9)

布局同 §10.4，statev(8)=I1_bar=3。

### 10.7 Yeoh (mat_id 304, nStatev=9)

布局同 §10.4。

### 10.8 Arruda-Boyce (mat_id 305, nStatev=9)

| Slot | 含义 | 初值 |
|------|------|------|
| 1-6 | F 对角+非对角 | 同上 |
| 7 | J_volume_ratio | 1 |
| 8 | lambda_chain | 1 |
| 9 | strain_energy | 0 |

---

## 十一、props/statev 一致性检查

实现与文档一致性检查建议：

1. **Registry 与文档**：`PH_Mat_Reg_Core` 中 `num_props`、`nStatev` 应与本文档表格一致
2. **关键材料**：JohnsonCook(204) num_props=9，Creep(403) num_props=4，RateDep(203) num_props=5
3. **占位材料**：701-704、601、603、605-607 标注为 PLACEHOLDER，实现为 sigma=sigma_old

---

## 十二、参考

- `UFC_74_Material_Classification_Final.md`
- [PH_Mat_Reg_Core.f90](../../../ufc_core/L4_PH/Material/OLD/Registry/PH_Mat_Reg_Core.f90) — num_props, nStatev, InitStateVars_Proc 注册
- `material_core_umat_范式设计` — MatPoint 范式与 InitStateVars 对接
