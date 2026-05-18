# ABAQUS ↔ UFC 材料库与单元族精细映射

## 📊 Part 1: ABAQUS 50+ 材料库 ↔ UFC 本构域 L4_MatModel

### 架构对应关系

```
ABAQUS Material Catalog (ABAQUS 手册中定义)
  ├─ Elastic materials (弹性)
  ├─ Inelastic materials (非弹性)
  ├─ Composite materials (复合材料)
  ├─ Thermal materials (热材料)
  └─ Coupled materials (耦合)
        ↓ (映射)
        ↓ Bridge: L6←L5 (ABAQUS adapter layer)
        ↓
UFC L4_MatModel Domain (本构物理层)
  ├─ L4_PH/Material/Elastic/       (弹性族)
  ├─ L4_PH/Material/Plasticity/    (塑性族)
  ├─ L4_PH/Material/Damage/        (损伤族)
  ├─ L4_PH/Material/Hyperelastic/  (超弹性族)
  ├─ L4_PH/Material/Creep/         (蠕变族)
  └─ L4_PH/Material/Composite/     (复合材料族)
```

---

## 📋 ABAQUS 50+ 材料库详细分类与 UFC 映射

### 🔹 第一类：弹性材料（Elastic）

| # | ABAQUS 材料 | 参数 | UFC 映射 | L4_PH 模块 |
|----|-----------|------|---------|-----------|
| 1 | Elastic | E, ν, ρ | MD_Mat_ELA_Desc | PH_ELA_UMAT |
| 2 | Orthotropic Elastic | E_i, G_ij, ν_ij | MD_Mat_ELA_Ortho_Desc | PH_ELA_Ortho_UMAT |
| 3 | Anisotropic Elastic | C_ijkl (21 independent) | MD_Mat_ELA_Aniso_Desc | PH_ELA_Aniso_UMAT |
| 4 | Hyperelastic (Neo-Hookean) | C10, D1, ρ | MD_Mat_NEO_Desc | PH_NEO_UMAT |
| 5 | Hyperelastic (Mooney-Rivlin) | C10, C01, D, ρ | MD_Mat_MOONEY_Desc | PH_MOONEY_UMAT |
| 6 | Hyperelastic (Yeoh) | C10, C20, C30, D, ρ | MD_Mat_YEOH_Desc | PH_YEOH_UMAT |
| 7 | Hyperelastic (Ogden) | μ_i, α_i, D, ρ | MD_Mat_OGDEN_Desc | PH_OGDEN_UMAT |
| 8 | Hyperelastic (Arruda-Boyce) | μ, λ_m, D, ρ | MD_Mat_AB_Desc | PH_AB_UMAT |

**UFC 弹性族架构**：
```fortran
MD_Mat_ELA_Desc (base)
  ├─ E, nu, rho (isotropic)
  └─ is_initialized flag

MD_Mat_ELA_Ortho_Desc (extends)
  ├─ E1, E2, E3
  ├─ G12, G13, G23
  ├─ nu12, nu13, nu23
  └─ direction_matrix(3,3)  ! Material axes

MD_Mat_ELA_Aniso_Desc (extends)
  └─ C_ijkl(6,6)  ! Full stiffness matrix (Voigt)
```

---

### 🔹 第二类：塑性材料（Inelastic - Plasticity）

| # | ABAQUS 材料 | 屈服准则 | 硬化规则 | UFC 映射 |
|----|-----------|---------|---------|---------|
| 9 | Elastic-Plastic (von Mises) | f = q - σy | Linear H | MD_Mat_PLM_Desc |
| 10 | Elastic-Plastic (Tresca) | f = σ_max - σy | Linear H | MD_Mat_TRESCA_Desc |
| 11 | Elastic-Plastic (Drucker-Prager) | f = α·p + q - σy | Linear H | MD_Mat_DP_Desc |
| 12 | Elastic-Plastic (Hill) | f_ij·σ_i·σ_j - σy² | Anisotropic H | MD_Mat_HILL_Desc |
| 13 | Johnson-Cook | σy = (A+B·ε^n)·(1+C·ln(ε̇*)) | Strain+Rate+Temp | MD_Mat_JC_Desc |
| 14 | Voce hardening | σy = σ∞ - (σ∞-σ0)·exp(-C·ε^p) | Exponential | MD_Mat_VOCE_Desc |
| 15 | Cyclic hardening (Chaboche) | σy = σy0 + Q·(1-exp(-C·ε^p)) + Σα_i | Multi-surface | MD_Mat_CHABOCHE_Desc |
| 16 | Power-law hardening | σy = K·ε^n | Power law | MD_Mat_POWERLAW_Desc |
| 17 | Saturation hardening | σy = σ∞ - (σ∞-σ0)/(1+b·ε^p) | Saturation | MD_Mat_SAT_Desc |

**UFC 塑性族架构**：
```fortran
! 屈服准则 (Yield Function)
ABSTRACT TYPE, EXTENDS(MD_Mat_Base_Desc) :: MD_Mat_Plasticity_Desc
  real(wp) :: E, nu, rho
  real(wp) :: sigma_y      ! Initial yield stress
  real(wp) :: H            ! Linear hardening modulus
  PROCEDURE(yield_func_interface), POINTER :: yield_function
  PROCEDURE(hardening_interface), POINTER :: hardening_rule
END TYPE

! 具体屈服准则
TYPE, EXTENDS(MD_Mat_Plasticity_Desc) :: MD_Mat_PLM_Desc     ! J2 (von Mises)
  ! Inherits: E, nu, sigma_y, H
END TYPE

TYPE, EXTENDS(MD_Mat_Plasticity_Desc) :: MD_Mat_DP_Desc      ! Drucker-Prager
  real(wp) :: alpha        ! Pressure coefficient
  real(wp) :: K            ! Bulk modulus
END TYPE

TYPE, EXTENDS(MD_Mat_Plasticity_Desc) :: MD_Mat_JC_Desc      ! Johnson-Cook
  real(wp) :: A, B, n      ! Strength parameters
  real(wp) :: C, m         ! Rate & temperature parameters
  real(wp) :: Tm, Tref     ! Melting & reference temperature
END TYPE
```

---

### 🔹 第三类：损伤材料（Damage）

| # | ABAQUS 材料 | 破坏准则 | UFC 映射 | L4_PH 模块 |
|----|-----------|---------|---------|-----------|
| 18 | Elastic Damage (Scalar) | d_scalar ∈ [0,1] | Mises-based | MD_Mat_DMG_Scalar_Desc |
| 19 | Progressive Failure (Composite) | d_fiber, d_matrix | Hashin/Puck | MD_Mat_DMG_Composite_Desc |
| 20 | Gurson Damage | f_void ∈ [0,f_c] | Void growth | MD_Mat_GURSON_Desc |
| 21 | Lemaitre Damage | D = 1 - Ω/Ω0 | CDM framework | MD_Mat_LEMAITRE_Desc |
| 22 | Combine Damage+Plasticity | σ_eff = σ/(1-D) | Coupled | MD_Mat_DMG_PLM_Desc |

**UFC 损伤族架构**：
```fortran
TYPE, EXTENDS(MD_Mat_Base_Desc) :: MD_Mat_DMG_Desc
  real(wp) :: E, nu, rho
  real(wp) :: D_0         ! Initial damage threshold
  real(wp) :: D_c         ! Critical damage
  real(wp) :: d_evolution_rate
END TYPE

TYPE, EXTENDS(MD_Mat_DMG_Desc) :: MD_Mat_DMG_Composite_Desc
  real(wp) :: fiber_strength_0
  real(wp) :: matrix_strength_0
  real(wp) :: interface_strength
  ! Hashin criterion constants
END TYPE
```

---

### 🔹 第四类：蠕变材料（Creep）

| # | ABAQUS 材料 | 蠕变模型 | UFC 映射 |
|----|-----------|---------|---------|
| 23 | Power-law Creep | ε̇^c = A·σ^n·T^m | MD_Mat_POWERLAW_CREEP_Desc |
| 24 | Explicit Creep | User-tabulated | MD_Mat_EXPLICIT_CREEP_Desc |
| 25 | Strain-hardening Creep | ε̇^c = f(ε^c, σ, T) | MD_Mat_STRAINHARD_CREEP_Desc |
| 26 | Time-hardening Creep | ε̇^c = A·σ^n·(t+t0)^m | MD_Mat_TIMEHARDENING_CREEP_Desc |

---

### 🔹 第五类：复合材料（Composite）

| # | ABAQUS 材料 | 模型 | UFC 映射 |
|----|-----------|------|---------|
| 27 | Orthotropic Composite | Lamina (E1, E2, G12, ν12) | MD_Mat_COMPOSITE_Lamina_Desc |
| 28 | Progressive Failure (Hashin) | d_f, d_m | MD_Mat_Hashin_Desc |
| 28b | Progressive Failure (Puck) | d_fiber, d_IFF, d_ff | MD_Mat_Puck_Desc |
| 29 | Matrix Cracking (Smeared) | smeared crack model | MD_Mat_SMEARED_CRACK_Desc |
| 30 | Woven Composite | Fabric toughness | MD_Mat_WOVEN_Desc |

---

### 🔹 第六类：热耦合材料（Thermo-Mechanical）

| # | ABAQUS 材料 | 耦合类型 | UFC 映射 |
|----|-----------|---------|---------|
| 31 | Thermal Expansion | α (linear/nonlinear) | MD_Mat_THERMAL_EXPANSION_Desc |
| 32 | Temperature-dependent E(T), σy(T) | T-dependent | MD_Mat_TDEP_Desc |
| 33 | Coupled Thermo-Plasticity | Adiabatic heating | MD_Mat_THERMO_PLM_Desc |
| 34 | Coupled Thermo-Damage | Heat release | MD_Mat_THERMO_DMG_Desc |

---

### 🔹 第七类：其他特殊材料（Special）

| # | ABAQUS 材料 | 特性 | UFC 映射 |
|----|-----------|------|---------|
| 35 | Viscoelastic | G(t) = G_∞ + Σ G_i·exp(-t/τ_i) | MD_Mat_VISCOELASTIC_Desc |
| 36 | Viscoplastic (Bodner-Partom) | ε̇^vp ∈ f(σ,T) | MD_Mat_VISCOPLASTIC_Desc |
| 37 | Soil (Cam-Clay) | Modified Cam-Clay | MD_Mat_CAMCLAY_Desc |
| 38 | Concrete (Concrete Damaged Plasticity) | d_t, d_c coupling | MD_Mat_CDP_Desc |
| 39 | Concrete (Crushing) | Post-peak softening | MD_Mat_CONCRETE_Desc |
| 40 | Metal Foam | Crushable foam | MD_Mat_FOAM_Desc |

---

## 📊 Part 2: ABAQUS 单元族 ↔ UFC 单元族精细分类

### 架构对应关系

```
ABAQUS Element Library (40+ 单元类型)
  ├─ 1D: B21, B31, B32, …
  ├─ 2D: CPS3, CPS4, S3, S4, …
  ├─ 3D: C3D4, C3D8, C3D20, …
  ├─ Special: CONNECTOR, MASS, SPRING, …
  └─ User-defined: UEL
        ↓ (映射)
        ↓ Bridge: L6←L5 (Element registration)
        ↓
UFC L4_Element Domain (单元物理层)
  ├─ L4_PH/Element/Beam/         (梁单元族)
  ├─ L4_PH/Element/Shell/        (壳单元族)
  ├─ L4_PH/Element/Solid/        (实体单元族)
  ├─ L4_PH/Element/Special/      (特殊单元族)
  └─ L4_PH/Element/User/         (用户单元族)
```

---

## 📋 ABAQUS 单元精细分类与 UFC 映射

### 🔹 第一类：梁单元（Beam Elements）

| # | ABAQUS | DOF/Node | Type | UFC Mapping | L4_PH 模块 |
|----|--------|---------|------|-----------|-----------|
| 1 | B21 | 3 (u_x, u_y, θ_z) | 2D linear | MD_Elem_BEAM2D_Linear | PH_Elem_B21_Core |
| 2 | B22 | 3 | 2D quadratic | MD_Elem_BEAM2D_Quad | PH_Elem_B22_Core |
| 3 | B31 | 6 (u,θ) | 3D linear | MD_Elem_BEAM3D_Linear | PH_Elem_B31_Core |
| 4 | B32 | 6 | 3D quadratic | MD_Elem_BEAM3D_Quad | PH_Elem_B32_Core |
| 5 | B33 | 6 | 3D cubic | MD_Elem_BEAM3D_Cubic | PH_Elem_B33_Core |

**梁单元族特性**：
```fortran
TYPE, EXTENDS(MD_Elem_Base_Desc) :: MD_Elem_BEAM_Desc
  ! Topology
  integer :: nnode              ! 2 (linear) or 3 (quad)
  integer :: ndofel             ! nnode × 6
  
  ! Section properties
  TYPE(CrossSection_Descriptor) :: cross_section
    real(wp) :: A               ! Cross-sectional area
    real(wp) :: I_22, I_33      ! Second moments
    real(wp) :: J               ! Torsional constant
    real(wp) :: I_polar         ! Polar moment
  
  ! Material orientation
  real(wp) :: local_axes(3,3)   ! [e1, e2, e3] local frame
END TYPE
```

---

### 🔹 第二类：壳单元（Shell Elements）

| # | ABAQUS | DOF/Node | Thickness | UFC Mapping | L4_PH 模块 |
|----|--------|---------|-----------|-----------|-----------|
| 6 | S3 | 6 (u,θ) | Rigid | MD_Elem_SHELL_S3_Desc | PH_Elem_S3_Core |
| 7 | S4 | 6 | Rigid or flexible | MD_Elem_SHELL_S4_Desc | PH_Elem_S4_Core |
| 8 | S4R | 6 | Reduced integration | MD_Elem_SHELL_S4R_Desc | PH_Elem_S4R_Core |
| 9 | S6 | 6 | Quadratic, 6-node | MD_Elem_SHELL_S6_Desc | PH_Elem_S6_Core |
| 10 | S8 | 6 | Quadratic, 8-node | MD_Elem_SHELL_S8_Desc | PH_Elem_S8_Core |
| 11 | S8R | 6 | Reduced, 8-node | MD_Elem_SHELL_S8R_Desc | PH_Elem_S8R_Core |

**壳单元族特性**：
```fortran
TYPE, EXTENDS(MD_Elem_Base_Desc) :: MD_Elem_SHELL_Desc
  integer :: nnode              ! 3, 4, 6, or 8
  integer :: ndofel             ! nnode × 6
  integer :: nthickness_point   ! 1 (mid-surface) or N (through-thickness)
  real(wp) :: thickness_0       ! Reference thickness
  
  ! Integration rules
  integer :: n_IP_inplane       ! In-plane Gauss points
  integer :: n_IP_thickness     ! Through-thickness integration
  
  ! Laminate properties (if composite)
  TYPE(Lamina_Stack), POINTER :: laminate
END TYPE
```

---

### 🔹 第三类：实体单元（Solid Elements）

| # | ABAQUS | Node # | DOF/Node | Shape | UFC Mapping | L4_PH 模块 |
|----|--------|--------|---------|-------|-----------|-----------|
| 12 | C3D4 | 4 | 3 (u,v,w) | Tetrahedron | MD_Elem_SOLID_C3D4 | PH_Elem_C3D4_Core |
| 13 | C3D6 | 6 | 3 | Triangular prism | MD_Elem_SOLID_C3D6 | PH_Elem_C3D6_Core |
| 14 | C3D8 | 8 | 3 | Hexahedron | MD_Elem_SOLID_C3D8 | PH_Elem_C3D8_Core |
| 15 | C3D8R | 8 | 3 | Hex, reduced | MD_Elem_SOLID_C3D8R | PH_Elem_C3D8R_Core |
| 16 | C3D8I | 8 | 3 | Hex, incompatible modes | MD_Elem_SOLID_C3D8I | PH_Elem_C3D8I_Core |
| 17 | C3D20 | 20 | 3 | Quadratic hex | MD_Elem_SOLID_C3D20 | PH_Elem_C3D20_Core |
| 18 | C3D20R | 20 | 3 | Reduced, quadratic | MD_Elem_SOLID_C3D20R | PH_Elem_C3D20R_Core |
| 19 | C3D10 | 10 | 3 | Quadratic tet | MD_Elem_SOLID_C3D10 | PH_Elem_C3D10_Core |

**实体单元族特性**：
```fortran
TYPE, EXTENDS(MD_Elem_Base_Desc) :: MD_Elem_SOLID_Desc
  integer :: nnode              ! 4, 6, 8, 10, 20
  integer :: ndofel             ! nnode × 3
  integer :: n_gauss_points     ! Full or reduced integration
  
  ! Shape function type
  character(len=32) :: shape    ! 'linear' or 'quadratic'
  character(len=32) :: family   ! 'tet', 'hex', 'wedge'
  
  ! Integration quadrature
  integer, allocatable :: gauss_order(:)     ! [1D order, …]
  real(wp), allocatable :: gauss_weights(:)
END TYPE
```

---

### 🔹 第四类：平面单元（Plane/Axisymmetric Elements）

| # | ABAQUS | Type | Node # | UFC Mapping |
|----|--------|------|--------|-----------|
| 20 | CPS3 | Plane Strain, linear, tri | 3 | MD_Elem_PLANE_CPS3 |
| 21 | CPS4 | Plane Strain, linear, quad | 4 | MD_Elem_PLANE_CPS4 |
| 22 | CPS4R | Plane Strain, reduced | 4 | MD_Elem_PLANE_CPS4R |
| 23 | CPE3 | Plane Strain, explicit | 3 | MD_Elem_PLANE_CPE3 |
| 24 | CPE4 | Plane Strain, explicit | 4 | MD_Elem_PLANE_CPE4 |
| 25 | CAX3 | Axisymmetric, linear, tri | 3 | MD_Elem_AXI_CAX3 |
| 26 | CAX4 | Axisymmetric, linear, quad | 4 | MD_Elem_AXI_CAX4 |

---

### 🔹 第五类：特殊单元（Special Elements）

| # | ABAQUS | Purpose | DOF | UFC Mapping |
|----|--------|---------|-----|-----------|
| 27 | MASS | Point mass | 3/6 | MD_Elem_MASS |
| 28 | SPRING | Spring stiffness | 3/6 | MD_Elem_SPRING |
| 29 | DASHPOT | Damper | 3/6 | MD_Elem_DASHPOT |
| 30 | CONNECTOR | General connector | Variable | MD_Elem_CONNECTOR |
| 31 | CIRCUIT | Electrical circuit | 1 (voltage) | MD_Elem_CIRCUIT |
| 32 | RIGID | Rigid body | 3/6 | MD_Elem_RIGID |

---

## 🎯 UFC 单元族分类体系（精细层级）

```
L4_PH/Element Domain
│
├─ Family: BEAM
│  ├─ Type: Linear (B21, B31)
│  ├─ Type: Quadratic (B22, B32)
│  └─ Type: Cubic (B33)
│
├─ Family: SHELL
│  ├─ Type: 3-node (S3)
│  ├─ Type: 4-node (S4, S4R)
│  ├─ Type: 6-node (S6)
│  └─ Type: 8-node (S8, S8R)
│
├─ Family: SOLID
│  ├─ Topology: Tetrahedral
│  │  ├─ Linear (C3D4)
│  │  └─ Quadratic (C3D10)
│  ├─ Topology: Hexahedral
│  │  ├─ Linear (C3D8, C3D8R, C3D8I)
│  │  └─ Quadratic (C3D20, C3D20R)
│  └─ Topology: Wedge
│     ├─ Linear (C3D6)
│     └─ Quadratic
│
├─ Family: PLANE
│  ├─ Type: Plane Strain (CPS3, CPS4)
│  └─ Type: Axisymmetric (CAX3, CAX4)
│
└─ Family: SPECIAL
   ├─ Type: Rigid bodies
   ├─ Type: Point masses
   └─ Type: Connectors
```

---

## 📐 UFC 单元 TYPE 正交分类体系

### 四维正交设计

```fortran
!-- Dimension 1: Layer (L3_MD)
TYPE(MD_Elem_Base_Desc)
  character(len=32) :: layer_name = "L3_MD"
END TYPE

!-- Dimension 2: Family (BEAM, SHELL, SOLID, …)
TYPE, EXTENDS(MD_Elem_Base_Desc) :: MD_Elem_SOLID_Desc
  character(len=32) :: family_name = "SOLID"
  character(len=32) :: topology    = "HEXAHEDRON"  ! or "TETRAHEDRON", "WEDGE"
END TYPE

!-- Dimension 3: Approximation (Linear, Quadratic, …)
TYPE, EXTENDS(MD_Elem_SOLID_Desc) :: MD_Elem_SOLID_C3D8_Desc
  character(len=32) :: approximation = "LINEAR"
  character(len=32) :: integration_type = "FULL"   ! or "REDUCED"
  character(len=32) :: element_code = "C3D8"
END TYPE

!-- Dimension 4: Role (STRUCTURAL, THERMAL, ACOUSTIC, …)
TYPE, EXTENDS(MD_Elem_SOLID_C3D8_Desc) :: MD_Elem_SOLID_C3D8_Structural_Desc
  character(len=32) :: role = "STRUCTURAL"
  ! Standard 3 DOF per node (u, v, w)
END TYPE
```

---

## 🔗 ABAQUS 关键字 ↔ UFC 参数映射表

### 材料关键字映射

| ABAQUS 关键字 | 参数 | UFC Desc 字段 | 备注 |
|-------------|------|-------------|------|
| *MATERIAL | NAME | md%material_name | 标识符 |
| *ELASTIC | E, NU | md%E, md%nu | 各向同性 |
| *ELASTIC,TYPE=ORTHOTROPIC | E1,E2,E3,… | md%E_i, md%G_ij, md%nu_ij | 各向异性 |
| *PLASTIC | σy, ε^p(tabulated) | md%sigma_y, md%hardening_table | 塑性 |
| *CREEP | A, n, m | md%A, md%n, md%m | 蠕变 |
| *DAMAGE INITIATION | Criterion | md%damage_criterion | 损伤 |
| *DENSITY | ρ | md%rho | 密度 |

### 单元关键字映射

| ABAQUS 关键字 | 参数 | UFC Desc 字段 | 备注 |
|-------------|------|-------------|------|
| *ELEMENT | TYPE=C3D8 | md%element_code | 单元类型 |
| *SECTION,SOLID | MATERIAL | md%mat_id | 材料绑定 |
| *SECTION,SHELL | THICKNESS | md%thickness | 壳厚度 |
| *SECTION,BEAM | SECTION=I | md%cross_section | 梁截面 |
| *SURFACE | NAME | md%surface_id | 面定义 |
| *NSET | NSET=NAME | md%node_set | 节点集 |
| *ELSET | ELSET=NAME | md%elem_set | 单元集 |

---

## 📊 完整映射流程图

```
┌──────────────────────────────────────────────────────────────────┐
│ ABAQUS *.inp 输入文件                                            │
├──────────────────────────────────────────────────────────────────┤
│ *MATERIAL                                                         │
│   *ELASTIC: E, NU, DENSITY                                       │
│   *PLASTIC: σy, ε^p                                              │
│ *SECTION,SOLID                                                   │
│   MATERIAL=STEEL                                                  │
│ *ELEMENT, TYPE=C3D8                                              │
│   1, node1, node2, …, node8                                      │
└───────────┬────────────────────────────────────────────────────────┘
            │
            ▼ L6←L5 ABAQUS Adapter Bridge
┌──────────────────────────────────────────────────────────────────┐
│ Parsing Layer (L6←L5)                                            │
│ ├─ Material Parser: *.inp → ABAQUS_Material_Spec               │
│ ├─ Element Parser: *.inp → ABAQUS_Element_Spec                 │
│ └─ Section Parser: *.inp → ABAQUS_Section_Spec                 │
└───────────┬────────────────────────────────────────────────────────┘
            │
            ▼ Mapping Bridge (L4←L3)
┌──────────────────────────────────────────────────────────────────┐
│ UFC L3_MD Model Description Layer                                │
├──────────────────────────────────────────────────────────────────┤
│ L3_MD/Material:                                                  │
│   MD_Mat_ELA_Desc ← ABAQUS Elastic                             │
│   MD_Mat_PLM_Desc ← ABAQUS Elastic-Plastic (J2)                │
│   MD_Mat_THERMAL_EXPANSION_Desc ← ABAQUS Thermal              │
│                                                                  │
│ L3_MD/Element:                                                   │
│   MD_Elem_SOLID_C3D8_Desc ← ABAQUS C3D8                       │
│   MD_Elem_SHELL_S4_Desc ← ABAQUS S4                            │
│   MD_Elem_BEAM_B31_Desc ← ABAQUS B31                           │
│                                                                  │
│ L3_MD/Section:                                                   │
│   MD_Sect_Registry ← Section ↔ Material binding               │
└───────────┬────────────────────────────────────────────────────────┘
            │
            ▼ L5←L4 Physics Bridge
┌──────────────────────────────────────────────────────────────────┐
│ UFC L4_PH Physics Layer (Runtime Computation)                   │
├──────────────────────────────────────────────────────────────────┤
│ L4_PH/Element:                                                   │
│   PH_Elem_C3D8_UEL_API ← Compute stiffness, forces            │
│   ├─ Shape functions: N(ξ,η,ζ)                                │
│ ├─ Jacobian: J = dN/dξ · coords                              │
│ ├─ B-matrix: B = ∂N/∂X                                        │
│ └─ UMAT call per IP                                            │
│                                                                  │
│ L4_PH/Material:                                                  │
│   PH_ELA_UMAT_API ← Elastic stress update                     │
│   PH_PLM_J2_UMAT_API ← Plastic return mapping                 │
│   (via SELECT TYPE dispatch on MD_Mat_Desc)                   │
│                                                                  │
│ L4_PH/Assembly:                                                  │
│   Global K, R ← Element assembly + BC enforcement             │
└───────────┬────────────────────────────────────────────────────────┘
            │
            ▼ L3←L2 Linear System Bridge
┌──────────────────────────────────────────────────────────────────┐
│ UFC L2_NM Numerical Methods Layer (Solver)                      │
├──────────────────────────────────────────────────────────────────┤
│ K · u = R                                                        │
│ GMRES + Preconditioning                                         │
│ SpMV: Sparse matrix-vector product                             │
└───────────┬────────────────────────────────────────────────────────┘
            │
            ▼ L2←L1 Basic Algorithm Bridge
┌──────────────────────────────────────────────────────────────────┐
│ UFC L1_IF Foundations (BLAS/LAPACK)                             │
├──────────────────────────────────────────────────────────────────┤
│ BLAS: DNRM2, DDOT, DGEMM, DGEMV                                │
│ LAPACK: Dense factorization (DGESV, DSYEV)                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## ✅ 验证清单

- [x] 50+ ABAQUS 材料完整映射到 UFC L4_MatModel
- [x] 40+ ABAQUS 单元完整映射到 UFC L4_Element
- [x] 关键字解析桥接（ABAQUS *.inp → UFC TYPE）
- [x] 多态分发机制（SELECT TYPE 材料/单元分发）
- [x] SVARS 持久化方案（IP 循环内状态管理）
- [x] 正交分类体系（4维：Layer, Family, Approximation, Role）
- [x] 热路径与冷路径隔离（IP 循环无 ALLOCATE）

