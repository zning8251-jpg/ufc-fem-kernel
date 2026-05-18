# Section_ElemMat_Compat_Matrix — 单元-截面-材料正交合法性矩阵
<!-- v1.0 | 2026-04-13 | UFC 六层架构核心文档 -->
<!-- 归属：UFC/docs/05_Project_Planning/PPLAN/06_核心架构/ -->
<!-- 配套文档：ABAQUS_Section_Architecture.md · ElemMat_Orthogonal_Design.md -->

**版本**：v1.0
**日期**：2026-04-13
**状态**：已定稿（初版）

---

## 一、设计目标与核心原则

### 1.1 问题描述

UFC 实现 14 大单元族（245 种标准单元）× 11 材料族（74 种标准材料），若两两组合将产生 **2695 对**（245×11，或 154 对族级）的组合空间。绝大多数组合物理上无意义或不被支持（如声学单元+J2塑性材料），必须在编译时建立合法性约束。

**设计目标**：以**零运行时开销**的编译期常量矩阵，消灭非法组合，避免运行时静默错误。

### 1.2 核心架构决策

```
单元 (Element) ──▶ 截面 (Section) ──▶ 材料 (Material)
     ↑                  ↑                   ↑
   族级压缩            唯一路由键           族级压缩
  (14族→10功能族)     (SECTION_ID)         (11族→11族)
                          ↓
                   ELEM_MAT_COMPAT(E_FAM, M_FAM)
                   （编译期 LOGICAL 常量矩阵）
```

**三条铁律**：
1. **单元与材料禁止直接耦合**：所有 Element→Material 绑定必须经由 Section（截面）
2. **合法性检查在 Populate 冷路径**：运行时热路径不做任何合法性判断
3. **稀疏矩阵压缩**：14 种单元族压缩为 10 种"计算功能族"，11 种材料族保持不变

---

## 二、单元族压缩（14→10 计算功能族）

### 2.1 原始 14 大族 → 计算功能族映射

| 计算功能族 ID | 功能族名称 | 包含原始单元族 | ABAQUS 典型单元 | DOF 类型 |
|:-----------:|----------|--------------|--------------|---------|
| **EF_SOLID** | 3D 实体族 | 族06（C3D系列）| C3D4/C3D8/C3D20 | u（位移）|
| **EF_SOLID2D** | 2D 实体族 | 族05（CPE/CPS/CAX）| CPE4/CPS4/CAX4 | u |
| **EF_SHELL** | 壳体族 | 族04（S/SC系列）| S3/S4/S4R/SC8R | u+θ |
| **EF_BEAM** | 梁族 | 族02（B系列）| B21/B31/B32/B33 | u+θ |
| **EF_TRUSS** | 桁架/杆族 | 族01（T系列）| T2D2/T3D2/T3D3 | u |
| **EF_MEMBRANE** | 膜族 | 族03（M3D系列）| M3D3/M3D4 | u |
| **EF_THERMAL** | 热传导族 | 族10（DC系列）+ 族11（热-力耦合）| DC3D4/DC3D8/C3D8T | T（温度）|
| **EF_ACOUSTIC** | 声学族 | 族09（AC系列）| AC3D4/AC3D8 | P（声压）|
| **EF_SPECIAL** | 特殊/连接族 | 族07（弹簧/阻尼/质量）| SPRING1/DASHPOT2/MASS | u/θ |
| **EF_POROUS** | 孔隙渗流族 | 族12（孔隙P系列）| C3D8P/CPE4P | u+P_w |
| **EF_ELECTROMAGNETIC** | 电磁族 | 族13（EM系列）| EMC3D4/EMC3D8 | E/B |
| **EF_USER** | 用户扩展族 | 族14（U系列）| U1-U5/UEL_SOLID | 用户定义 |

> 注：族08（分布参数）归并入最相近的族（如 PIPE_FLUID→EF_SPECIAL），族11（热-力耦合）归并入 EF_THERMAL。

**Fortran 枚举定义**：

```fortran
!===============================================================================
! 单元计算功能族枚举（UFC 内部，12族）
! 文件建议位置：UFC/ufc_core/L3_MD/Mesh/MD_Elem_Family_Enum.f90
!===============================================================================
MODULE MD_Elem_Family_Enum_Mod
  USE IF_Precision, ONLY: i4
  IMPLICIT NONE

  INTEGER(i4), PARAMETER :: N_ELEM_FAMILY = 12_i4  ! 单元族总数

  INTEGER(i4), PARAMETER :: &
    EF_SOLID         =  1_i4, &   ! 3D 实体 (C3D系列)
    EF_SOLID2D       =  2_i4, &   ! 2D 实体 (CPE/CPS/CAX)
    EF_SHELL         =  3_i4, &   ! 壳体 (S/SC系列)
    EF_BEAM          =  4_i4, &   ! 梁 (B系列)
    EF_TRUSS         =  5_i4, &   ! 桁架/杆 (T系列)
    EF_MEMBRANE      =  6_i4, &   ! 膜 (M3D系列)
    EF_THERMAL       =  7_i4, &   ! 热传导+热-力耦合 (DC/耦合T系列)
    EF_ACOUSTIC      =  8_i4, &   ! 声学 (AC系列)
    EF_SPECIAL       =  9_i4, &   ! 弹簧/阻尼/质量/连接器
    EF_POROUS        = 10_i4, &   ! 孔隙渗流 (P系列)
    EF_ELECTROMAGNETIC=11_i4, &   ! 电磁 (EM系列)
    EF_USER          = 12_i4      ! 用户自定义 (UEL)

  !-- 原始 elem_type → 计算功能族 的映射函数（见 Get_ElemFamily_Proc）
  !-- 族01(Truss) → EF_TRUSS
  !-- 族02(Beam)  → EF_BEAM
  !-- 族03(Mem)   → EF_MEMBRANE
  !-- 族04(Shell) → EF_SHELL
  !-- 族05(2DSld) → EF_SOLID2D
  !-- 族06(3DSld) → EF_SOLID
  !-- 族07(Spcl)  → EF_SPECIAL
  !-- 族08(Dist)  → EF_SPECIAL（合并）
  !-- 族09(Acou)  → EF_ACOUSTIC
  !-- 族10(Heat)  → EF_THERMAL
  !-- 族11(CplT)  → EF_THERMAL（合并）
  !-- 族12(Poro)  → EF_POROUS
  !-- 族13(EM)    → EF_ELECTROMAGNETIC
  !-- 族14(User)  → EF_USER

END MODULE MD_Elem_Family_Enum_Mod
```

---

## 三、材料族枚举（11 族，保持不变）

### 3.1 UFC 材料族定义

| 材料族 ID | 族名称（T1缩写）| 典型模型 | mat_id 范围 | 主要 ABAQUS 关键字 |
|:--------:|--------------|---------|------------|------------------|
| **MF_ELASTIC** | ELA（小应变弹性）| 线弹性/正交/各向异性 | 101-106 | `*ELASTIC` |
| **MF_PLASTIC** | PLM（金属塑性）| J2/Hill/JohnsonCook | 201-220 | `*PLASTIC` |
| **MF_GEOTECH** | PLG（岩土塑性）| DP/MCC/CAP/混凝土 | 202-215,701 | `*DRUCKER PRAGER` |
| **MF_HYPERELAS** | HYP（超弹性）| MR/Ogden/NeoHookean | 301-310 | `*HYPERELASTIC` |
| **MF_VISCOELAS** | VSC（粘弹蠕变）| Prony/蠕变/粘塑性 | 107,401-408 | `*VISCOELASTIC` |
| **MF_DAMAGE** | DMG（损伤断裂）| 韧性损伤/低周疲劳 | 501-509 | `*DAMAGE INITIATION` |
| **MF_COMPOSITE** | CMP（复合材料）| 层合板/界面损伤 | 112,214,502,507,508 | `*COMPOSITE SECTION` |
| **MF_THERMAL** | MPH-热（传热/膨胀）| 导热/热膨胀/热电 | 601-607 | `*CONDUCTIVITY` |
| **MF_POROUS** | POR（多孔/泡沫）| Gurson/GTN/泡沫压溃 | 205,212 | `*POROUS METAL PLASTICITY` |
| **MF_SPECIAL** | SPU（特殊材料）| EOS/流体/电磁/阻尼 | 702-707 | `*EOS` |
| **MF_USER** | USR（用户扩展）| UMAT/VUMAT | 708 | `*USER MATERIAL` |

**Fortran 枚举定义**：

```fortran
!===============================================================================
! 材料族枚举（UFC 内部，11族）
! 文件建议位置：UFC/ufc_core/L3_MD/Material/MD_Mat_Family_Enum.f90
!===============================================================================
MODULE MD_Mat_Family_Enum_Mod
  USE IF_Precision, ONLY: i4
  IMPLICIT NONE

  INTEGER(i4), PARAMETER :: N_MAT_FAMILY = 11_i4  ! 材料族总数

  INTEGER(i4), PARAMETER :: &
    MF_ELASTIC       =  1_i4, &   ! ELA: 小应变弹性
    MF_PLASTIC       =  2_i4, &   ! PLM: 金属塑性（率无关/率相关）
    MF_GEOTECH       =  3_i4, &   ! PLG: 岩土与水泥基塑性
    MF_HYPERELAS     =  4_i4, &   ! HYP: 超弹性（有限变形）
    MF_VISCOELAS     =  5_i4, &   ! VSC: 粘弹与蠕变
    MF_DAMAGE        =  6_i4, &   ! DMG: 体损伤与断裂
    MF_COMPOSITE     =  7_i4, &   ! CMP: 复合材料与界面
    MF_THERMAL       =  8_i4, &   ! MPH-热: 热传导/热膨胀/多场
    MF_POROUS        =  9_i4, &   ! POR: 孔洞/多孔/泡沫材料
    MF_SPECIAL       = 10_i4, &   ! SPU: 特殊/非标准材料（EOS/流体）
    MF_USER          = 11_i4      ! USR: 用户自定义材料（UMAT/VUMAT）

END MODULE MD_Mat_Family_Enum_Mod
```

---

## 四、核心正交合法性矩阵（ELEM_MAT_COMPAT）

### 4.1 矩阵说明

- **行**：12 种单元计算功能族（EF_*），行号 = EF_* 值
- **列**：11 种材料族（MF_*），列号 = MF_* 值
- **值**：`.TRUE.` = 合法组合；`.FALSE.` = 非法组合（在 Populate 阶段报错）

### 4.2 合法性矩阵（可读版）

```
                     MF_ MF_ MF_ MF_ MF_ MF_ MF_ MF_ MF_ MF_ MF_
                     ELA PLA GEO HYP VIS DMG CMP THM POR SPU USR
                      1   2   3   4   5   6   7   8   9  10  11
EF_SOLID3D    (1)  [  T   T   T   T   T   T   T   F   T   T   T  ]
EF_SOLID2D    (2)  [  T   T   T   T   T   T   T   F   T   T   T  ]
EF_SHELL      (3)  [  T   T   F   T   T   T   T   F   F   F   T  ]
EF_BEAM       (4)  [  T   T   F   F   T   F   F   F   F   F   T  ]
EF_TRUSS      (5)  [  T   T   F   F   F   F   F   F   F   F   T  ]
EF_MEMBRANE   (6)  [  T   T   F   T   T   T   T   F   F   F   T  ]
EF_THERMAL    (7)  [  F   F   F   F   F   F   F   T   F   F   T  ]
EF_ACOUSTIC   (8)  [  F   F   F   F   F   F   F   F   F   T   T  ]
EF_SPECIAL    (9)  [  T   F   F   F   T   F   F   F   F   T   T  ]
EF_POROUS    (10)  [  T   T   T   F   T   T   F   F   T   F   T  ]
EF_EM        (11)  [  F   F   F   F   F   F   F   F   F   T   T  ]
EF_USER      (12)  [  T   T   T   T   T   T   T   T   T   T   T  ]

图例：T = 合法（.TRUE.）  F = 非法（.FALSE.）
```

### 4.3 合法性矩阵（Fortran 编译期常量）

```fortran
!===============================================================================
! ELEM_MAT_COMPAT — 单元族-材料族正交合法性矩阵（编译期常量）
! 文件建议位置：UFC/ufc_core/L3_MD/Section/MD_Sect_Compat_Const.f90
! 约束：零运行时开销；仅在 Populate 冷路径调用
!===============================================================================
MODULE MD_Sect_Compat_Const_Mod
  USE IF_Precision,           ONLY: i4
  USE MD_Elem_Family_Enum_Mod, ONLY: N_ELEM_FAMILY
  USE MD_Mat_Family_Enum_Mod,  ONLY: N_MAT_FAMILY
  IMPLICIT NONE

  !-- 正交合法性矩阵：ELEM_MAT_COMPAT(elem_family, mat_family)
  !   .TRUE.  → 此（单元族, 材料族）组合合法，可构成截面
  !   .FALSE. → 非法组合，Populate 阶段报致命错误
  !
  !-- 行（1~12）：EF_SOLID/EF_SOLID2D/EF_SHELL/EF_BEAM/EF_TRUSS/EF_MEMBRANE/
  !               EF_THERMAL/EF_ACOUSTIC/EF_SPECIAL/EF_POROUS/EF_EM/EF_USER
  !-- 列（1~11）：MF_ELASTIC/MF_PLASTIC/MF_GEOTECH/MF_HYPERELAS/MF_VISCOELAS/
  !               MF_DAMAGE/MF_COMPOSITE/MF_THERMAL/MF_POROUS/MF_SPECIAL/MF_USER

  LOGICAL, PARAMETER :: ELEM_MAT_COMPAT(N_ELEM_FAMILY, N_MAT_FAMILY) = RESHAPE( [&
    !            MF_ELA MF_PLA MF_GEO MF_HYP MF_VIS MF_DMG MF_CMP MF_THM MF_POR MF_SPU MF_USR
    !-- EF_SOLID (1):
    .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  &
    !-- EF_SOLID2D (2):
    .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  &
    !-- EF_SHELL (3):
    .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .FALSE., .FALSE., .FALSE., .TRUE.,  &
    !-- EF_BEAM (4):
    .TRUE.,  .TRUE.,  .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  &
    !-- EF_TRUSS (5):
    .TRUE.,  .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  &
    !-- EF_MEMBRANE (6):
    .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .FALSE., .FALSE., .FALSE., .TRUE.,  &
    !-- EF_THERMAL (7):
    .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  &
    !-- EF_ACOUSTIC (8):
    .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .TRUE.,  &
    !-- EF_SPECIAL (9):
    .TRUE.,  .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .TRUE.,  &
    !-- EF_POROUS (10):
    .TRUE.,  .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  .TRUE.,  .FALSE., .FALSE., .TRUE.,  .FALSE., .TRUE.,  &
    !-- EF_EM (11):
    .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .TRUE.,  &
    !-- EF_USER (12):
    .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.   &
  ], SHAPE=[N_ELEM_FAMILY, N_MAT_FAMILY] )

END MODULE MD_Sect_Compat_Const_Mod
```

### 4.4 矩阵有效对数统计

| 单元族 | 合法材料族数（共11族）| 合法率 |
|--------|:-------------------:|:------:|
| EF_SOLID（3D实体）| 10 | 91% |
| EF_SOLID2D（2D实体）| 10 | 91% |
| EF_SHELL（壳体）| 8 | 73% |
| EF_BEAM（梁）| 5 | 45% |
| EF_TRUSS（桁架）| 3 | 27% |
| EF_MEMBRANE（膜）| 7 | 64% |
| EF_THERMAL（热传导）| 2 | 18% |
| EF_ACOUSTIC（声学）| 2 | 18% |
| EF_SPECIAL（特殊）| 4 | 36% |
| EF_POROUS（孔隙渗流）| 6 | 55% |
| EF_EM（电磁）| 2 | 18% |
| EF_USER（用户）| 11 | 100% |
| **合计有效对** | **70 / 132（族级）** | **53%** |

> 族级有效对 70 对（vs. 理论最大 132 对）；对应具体单元-材料组合约 **40 对**（vs. 245×11=2695 对），组合空间压缩率 **98.5%**。

---

## 五、截面（Section）作为路由枢纽的实现

### 5.1 截面类型体系

截面（Section）在 UFC 中承担三个职责：
1. **绑定**：记录 `elem_family → mat_family` 的具体实例化绑定
2. **约束**：存储单元的几何属性（厚度、方向、积分规则），这些属于截面而非材料
3. **路由**：在热路径中提供零开销的 `mat_desc` 指针访问

```fortran
!===============================================================================
! Section 截面类型（L3_MD 层，Section 域）
! 文件：UFC/ufc_core/L3_MD/Section/MD_Sect_Types.f90
!===============================================================================
TYPE, PUBLIC :: MD_Sect_Base_Desc
  !-- §1 标识
  INTEGER(i4)       :: section_id      = 0_i4   ! 截面唯一 ID
  CHARACTER(LEN=64) :: section_name    = ''      ! 截面名称

  !-- §2 族级分类（路由键）
  INTEGER(i4) :: elem_family   = 0_i4   ! 单元计算功能族（EF_*）
  INTEGER(i4) :: mat_family    = 0_i4   ! 材料族（MF_*）
  INTEGER(i4) :: section_type  = 0_i4   ! 截面几何类型（SECT_SOLID/SHELL/BEAM等）

  !-- §3 材料绑定（Populate 后建立，热路径通过指针零开销访问）
  INTEGER(i4) :: mat_id        = 0_i4   ! 材料 ID（注册表键）
  TYPE(MD_Mat_Base_Desc), POINTER :: mat_desc => NULL()  ! 材料描述符指针

  !-- §4 几何属性（截面独有，不属于材料）
  REAL(wp) :: thickness        = 0.0_wp  ! 壳/梁截面厚度 [m]
  REAL(wp) :: offset           = 0.0_wp  ! 截面偏移量
  REAL(wp) :: orientation(3)   = 0.0_wp  ! 纤维主方向向量

  !-- §5 积分规则
  INTEGER(i4) :: nintegration_pts  = 0_i4   ! 积分点数
  CHARACTER(LEN=16) :: integ_rule  = ''     ! 积分规则（'GAUSS'/'LOBATTO'）

  !-- §6 复合截面（仅 Shell/Beam 多层截面使用）
  INTEGER(i4) :: nlayer        = 1_i4   ! 层数（=1 表示非复合）
  REAL(wp), ALLOCATABLE :: layer_thickness(:)   ! 各层厚度 [nlayer]
  INTEGER(i4), ALLOCATABLE :: layer_mat_id(:)   ! 各层材料 ID [nlayer]
END TYPE MD_Sect_Base_Desc
```

### 5.2 截面类型扩展族

| 截面 TYPE 名 | 对应截面类型 | 典型单元族 | 额外字段 |
|-------------|------------|---------|---------|
| `MD_Sect_Solid_Desc` | 实体截面 | EF_SOLID / EF_SOLID2D | 无额外字段 |
| `MD_Sect_Shell_Desc` | 壳截面 | EF_SHELL | `nlayer`, `layer_thickness`, `layer_orient` |
| `MD_Sect_Beam_Desc` | 梁截面 | EF_BEAM | `cross_section_type`, `A`, `Iy`, `Iz`, `J` |
| `MD_Sect_Membrane_Desc` | 膜截面 | EF_MEMBRANE | `thickness` |
| `MD_Sect_Truss_Desc` | 桁架截面 | EF_TRUSS | `area` |
| `MD_Sect_Thermal_Desc` | 热传导截面 | EF_THERMAL | 无额外字段 |
| `MD_Sect_Acoustic_Desc` | 声学截面 | EF_ACOUSTIC | `rho_fluid` |
| `MD_Sect_Porous_Desc` | 孔隙渗流截面 | EF_POROUS | `porosity`, `permeability` |
| `MD_Sect_User_Desc` | 用户扩展截面 | EF_USER | `user_data(:)` |

### 5.3 合法性检查子程序（Populate 冷路径）

```fortran
!===============================================================================
! MD_Sect_Check_Compat_Proc — 截面合法性检查（冷路径，Populate 后调用）
! 职责：验证 elem_family × mat_family 组合是否在 ELEM_MAT_COMPAT 矩阵中合法
!===============================================================================
SUBROUTINE MD_Sect_Check_Compat_Proc(sect_desc, error_code)
  USE MD_Sect_Compat_Const_Mod, ONLY: ELEM_MAT_COMPAT
  USE MD_Elem_Family_Enum_Mod,  ONLY: N_ELEM_FAMILY
  USE MD_Mat_Family_Enum_Mod,   ONLY: N_MAT_FAMILY
  IMPLICIT NONE

  TYPE(MD_Sect_Base_Desc), INTENT(IN)  :: sect_desc    ![IN]  截面描述符
  INTEGER(i4),             INTENT(OUT) :: error_code   ![OUT] 0=合法, 非0=错误码

  INTEGER(i4) :: ef, mf

  error_code = 0_i4
  ef = sect_desc%elem_family
  mf = sect_desc%mat_family

  !-- 范围检查
  IF (ef < 1_i4 .OR. ef > N_ELEM_FAMILY) THEN
    error_code = 1001_i4  ! 非法单元族 ID
    RETURN
  END IF
  IF (mf < 1_i4 .OR. mf > N_MAT_FAMILY) THEN
    error_code = 1002_i4  ! 非法材料族 ID
    RETURN
  END IF

  !-- 正交矩阵查表（编译期常量，零运行时开销）
  IF (.NOT. ELEM_MAT_COMPAT(ef, mf)) THEN
    error_code = 2001_i4  ! 非法单元-材料组合
    RETURN
  END IF

  !-- 材料指针关联检查
  IF (.NOT. ASSOCIATED(sect_desc%mat_desc)) THEN
    error_code = 3001_i4  ! 材料描述符指针未关联
    RETURN
  END IF

END SUBROUTINE MD_Sect_Check_Compat_Proc
```

---

## 六、各合法组合的约束细则

### 6.1 EF_SOLID（3D 实体）× 材料族

| 材料族 | 合法？ | 约束细则 | 典型 ABAQUS 场景 |
|--------|:------:|---------|----------------|
| MF_ELASTIC | ✅ | ntens=6，无约束 | C3D8R + *ELASTIC |
| MF_PLASTIC | ✅ | ntens=6，需 NSTATV≥1（等效塑性应变）| C3D8R + *PLASTIC |
| MF_GEOTECH | ✅ | ntens=6，岩土单元需 pore pressure DOF（C3D8P）| C3D8R + *DRUCKER PRAGER |
| MF_HYPERELAS | ✅ | 有限变形，需 TL/UL 公式，dfgrd1 有效 | C3D8H + *HYPERELASTIC |
| MF_VISCOELAS | ✅ | ntens=6，Prony 级数需频率/时间参数 | C3D8R + *VISCOELASTIC |
| MF_DAMAGE | ✅ | ntens=6，损伤初始化时需额外 NSTATV | C3D8R + *DAMAGE INITIATION |
| MF_COMPOSITE | ✅ | 仅限各向异性弹性层合，需逐层 mat_id | C3D8R（复合叠层分析）|
| MF_THERMAL | ❌ | C3D8 无温度 DOF（应用热传导用 DC3D8）| — |
| MF_POROUS | ✅ | 需孔压 DOF（C3D8P/C3D8RP），ntens=6 | C3D8P + Porous Elastic |
| MF_SPECIAL | ✅ | EOS 等特殊本构（冲击/流体静力学）| C3D8R + *EOS（VUMAT 路径）|
| MF_USER | ✅ | 所有参数用户自定义，PROPS 完全灵活 | C3D8R + *USER MATERIAL |

### 6.2 EF_SHELL（壳体）× 材料族

| 材料族 | 合法？ | 约束细则 |
|--------|:------:|---------|
| MF_ELASTIC | ✅ | ntens=5/6（S4/S4R；STRI 平片壳 ntens=6）|
| MF_PLASTIC | ✅ | 薄壳要求 nlgeom=ON（大变形），σ_33=0 约束 |
| MF_GEOTECH | ❌ | 岩土材料不适用于壳体（无体积计算）|
| MF_HYPERELAS | ✅ | 膜主导的大变形壳（橡胶薄板）|
| MF_VISCOELAS | ✅ | 热塑性壳体的粘弹效应 |
| MF_DAMAGE | ✅ | 纤维增强壳/金属壳的渐进破坏 |
| MF_COMPOSITE | ✅ | 层合板首选（逐层材料 + 各层厚度/方向）|
| MF_THERMAL | ❌ | 壳体热传导用 S4T（归入 EF_THERMAL 处理）|
| MF_POROUS | ❌ | 壳体无孔压 DOF |
| MF_SPECIAL | ❌ | EOS 等不适用于壳体 |
| MF_USER | ✅ | UMAT/VUMAT 支持用户壳体本构 |

### 6.3 EF_BEAM（梁）× 材料族

| 材料族 | 合法？ | 约束细则 |
|--------|:------:|---------|
| MF_ELASTIC | ✅ | ntens=1（轴向）或 1-6（3D 梁含弯矩/扭矩）|
| MF_PLASTIC | ✅ | 梁截面塑性铰，需截面力-力矩本构 |
| MF_GEOTECH | ❌ | 岩土本构不适用于梁（无体积变形）|
| MF_HYPERELAS | ❌ | 梁单元不支持有限变形超弹性 |
| MF_VISCOELAS | ✅ | 粘弹性梁（蠕变等）|
| MF_DAMAGE | ❌ | 梁破坏通过截面力-力矩初始化，不适用体损伤模型 |
| MF_COMPOSITE | ❌ | 层合梁截面用 BEAM SECTION，非 COMPOSITE 本构 |
| MF_THERMAL | ❌ | 热梁用 B31T（归入 EF_THERMAL）|
| MF_POROUS | ❌ | 梁无孔压 DOF |
| MF_SPECIAL | ❌ | 梁不支持 EOS 等特殊材料 |
| MF_USER | ✅ | 用户梁本构（通过 UMAT 定义截面力-力矩关系）|

### 6.4 EF_THERMAL（热传导）× 材料族

| 材料族 | 合法？ | 约束细则 |
|--------|:------:|---------|
| MF_THERMAL | ✅ | 唯一合法的纯热材料族，提供导热系数/比热容 |
| MF_USER | ✅ | 通过 UMATHT 实现用户热传导本构 |
| 其余所有族 | ❌ | 热传导单元只有温度 DOF，不支持力学本构 |

### 6.5 EF_ACOUSTIC（声学）× 材料族

| 材料族 | 合法？ | 约束细则 |
|--------|:------:|---------|
| MF_SPECIAL | ✅ | 声学介质（`*ACOUSTIC MEDIUM`），提供体积模量和密度 |
| MF_USER | ✅ | 用户声学介质 |
| 其余所有族 | ❌ | 声学单元只有声压 DOF |

---

## 七、Section 注册表设计

### 7.1 注册表结构

```fortran
!===============================================================================
! Section 注册表（L3_MD 层，全局唯一）
! 文件：UFC/ufc_core/L3_MD/Section/MD_Sect_Registry.f90
!===============================================================================
TYPE, PUBLIC :: MD_Sect_Registry
  !-- 截面槽位（Populate 后只读）
  TYPE(MD_Sect_Base_Desc), ALLOCATABLE :: sections(:)  ! [nsections]
  INTEGER(i4) :: nsections = 0_i4

  !-- 快速查表：elem_id → section_id 的映射（稀疏数组）
  INTEGER(i4), ALLOCATABLE :: elem_to_sect(:)          ! [n_elements]

CONTAINS
  PROCEDURE :: Register   => MD_Sect_Registry_Register_Proc
  PROCEDURE :: GetBySectId => MD_Sect_Registry_Get_Proc
  PROCEDURE :: GetByElemId => MD_Sect_Registry_GetByElem_Proc
END TYPE MD_Sect_Registry
```

### 7.2 调用流程（Populate 冷路径）

```
关键字解析阶段（冷路径）：
  1. 解析 *SOLID SECTION / *SHELL SECTION / *BEAM SECTION 关键字
       ↓
  2. 创建 MD_Sect_Base_Desc（填写 section_id, elem_family, mat_family）
       ↓
  3. 调用 MD_Sect_Check_Compat_Proc（查 ELEM_MAT_COMPAT 矩阵）
       ↓ 非法？→ 致命错误（报告非法组合详情）
       ↓ 合法？继续
  4. 关联 mat_desc 指针（通过 mat_id 查材料注册表）
       ↓
  5. 注册截面到 MD_Sect_Registry
       ↓
  6. 建立 elem_id → section_id 映射

热路径（每增量步，每积分点）：
  1. sect_ptr = registry%GetByElemId(elem_id)   ! O(1) 数组查表
  2. mat_desc => sect_ptr%mat_desc              ! 零拷贝指针解引用
  3. CALL PH_Mat_Core_Proc(mat_desc, ...)       ! 直接进入材料计算
```

---

## 八、扩展策略

### 8.1 添加新单元族（扩展步骤）

1. 在 `MD_Elem_Family_Enum_Mod` 添加新 `EF_NEWTYPE` 常量，更新 `N_ELEM_FAMILY`
2. 在 `ELEM_MAT_COMPAT` 矩阵追加新行（11 个 `.TRUE./.FALSE.` 值）
3. 在 `Get_ElemFamily_Proc` 中添加原始族→新功能族的映射
4. 可选：新建 `MD_Sect_NewType_Desc` 截面子类型

### 8.2 添加新材料族（扩展步骤）

1. 在 `MD_Mat_Family_Enum_Mod` 添加新 `MF_NEWMAT` 常量，更新 `N_MAT_FAMILY`
2. 在 `ELEM_MAT_COMPAT` 矩阵追加新列（12 个 `.TRUE./.FALSE.` 值）
3. 在 `MD_Mat_XXX_Desc` 中实现新材料族的 TYPE
4. 向材料注册表添加新 mat_id 区段

### 8.3 禁止的反模式

| 反模式 | 危害 | 正确做法 |
|--------|------|---------|
| 在热路径调用合法性检查 | 每增量步矩阵查表开销累积 | 仅在 Populate 冷路径检查一次 |
| 在 UEL 内部直接访问 mat_family | 破坏截面枢纽角色 | 通过 `sect_desc%mat_desc` 指针访问 |
| 硬编码"C3D8R+弹性"的特殊路径 | 破坏正交扩展性 | 统一走 EF_SOLID + MF_ELASTIC 路径 |
| 把截面厚度存入材料 Desc | 混淆截面和材料职责 | 厚度在 `MD_Sect_Shell_Desc%thickness` |

---

## 九、与其他文档的关系

| 文档 | 关系描述 |
|------|---------|
| `ABAQUS_Section_Architecture.md` | 本文件是其 Section 架构的完整实现规范，提供 Fortran 代码 |
| `ElemMat_Orthogonal_Design.md` | 本文件是正交设计的核心矩阵；`ElemMat_Orthogonal_Design.md` 提供族级枚举的完整方案 |
| `ABAQUS_AnalysisType_PreciseMapping.md` | 提供 Group×材料族矩阵（分析类型维度），与本矩阵正交 |
| `UFC_4D_Orthogonal_Matrix_Data.md` | 提供四维正交（单元×材料×分析×求解器）的完整视图 |
| `MD_Sect_Types.f90`（templates）| 本矩阵的类型定义已部分实现于此模板中 |

---

<!-- 版本历史 -->
<!-- v1.0 (2026-04-13) 初始版本，覆盖12族×11族完整矩阵，含合法性检查子程序 -->
