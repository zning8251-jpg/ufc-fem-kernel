# ElemMat_Orthogonal_Design — 完整族级正交设计方案
<!-- v1.0 | 2026-04-13 | UFC 六层架构核心文档 -->
<!-- 归属：UFC/docs/05_Project_Planning/PPLAN/06_核心架构/ -->
<!-- 配套文档：Section_ElemMat_Compat_Matrix.md · ABAQUS_Section_Architecture.md -->

**版本**：v1.0  
**日期**：2026-04-13  
**状态**：已定稿（初版）

---

## 总览

本文件是族级正交设计的完整参考方案，在 `Section_ElemMat_Compat_Matrix.md`
（核心合法性矩阵）的基础上扩展，提供：

1. **12 单元计算功能族** 完整 Fortran 枚举模块（含原始 14 大族→计算功能族映射函数）
2. **11 材料主族** 完整 Fortran 枚举模块（含 74 叶 mat_id→材料族映射函数）
3. **族级×功能集** 正交矩阵（Ke/Fe/Me/BC/Contact/Pore/EM 等 8 大功能集）
4. **截面类型族** 与单元/材料族的三维正交视图
5. **统一枚举汇总模块**（一次 USE 获取全部枚举常量）
6. **扩展策略**（新增单元族/材料族的完整步骤）

---

## 一、单元计算功能族完整枚举方案

### 1.1 设计背景：14→12 族压缩

UFC L3_MD 解析阶段识别 ABAQUS 原始 14 大族（按结构力学意义分类），
但在 L4_PH 计算阶段，部分族的**计算公式完全相同**，可合并为更小的**计算功能族**，
从而减少 L4_PH 分支路径、简化合法性矩阵。

| 压缩操作 | 原始族 | 并入计算功能族 | 理由 |
|--------|--------|-------------|------|
| 合并 | 族08（分布参数单元，管道流体）| `EF_SPECIAL` | DOF 模式与连接器一致 |
| 合并 | 族11（热-力耦合，如 C3D8T）| `EF_THERMAL` | 热 DOF 计算公式复用 DC 热族 |
| 保留 | 族01~07, 09, 10, 12, 13, 14 | 各自独立 | 计算公式或 DOF 有实质差异 |

> **注**：L3_MD 内部仍保留 14 大族原始 `elem_cat`（族码），仅在传递给
> L4_PH 时通过 `Get_ElemFamily_Proc` 转换为 12 族计算功能族 ID。

### 1.2 完整枚举模块（MD_Elem_Family_Enum_Mod）

```fortran
!===============================================================================
! MD_Elem_Family_Enum_Mod — 单元计算功能族枚举
! 文件：UFC/ufc_core/L3_MD/Mesh/MD_Elem_Family_Enum.f90
! 状态：编译期常量，不可运行时修改
! 关联：Section_ElemMat_Compat_Matrix.md §二
!===============================================================================
MODULE MD_Elem_Family_Enum_Mod
  USE IF_Precision, ONLY: i4
  IMPLICIT NONE
  PUBLIC

  !-- 计算功能族总数（扩展时同步修改，并在 ELEM_MAT_COMPAT 矩阵追加行）
  INTEGER(i4), PARAMETER :: N_ELEM_FAMILY = 12_i4

  !-- 单元计算功能族枚举（值 = 矩阵行号）
  INTEGER(i4), PARAMETER :: &
    EF_SOLID          =  1_i4, &  ! 3D 实体族  (C3D4/C3D8/C3D20/C3D10/C3D15)
    EF_SOLID2D        =  2_i4, &  ! 2D 实体族  (CPE/CPS/CAX 系列)
    EF_SHELL          =  3_i4, &  ! 壳体族     (S3/S4/S4R/SC8R/STRI65)
    EF_BEAM           =  4_i4, &  ! 梁族       (B21/B31/B32/B33/PIPE)
    EF_TRUSS          =  5_i4, &  ! 桁架/杆族  (T2D2/T3D2/T3D3)
    EF_MEMBRANE       =  6_i4, &  ! 膜族       (M3D3/M3D4/M3D8/M3D9)
    EF_THERMAL        =  7_i4, &  ! 热传导族   (DC2D/DC3D + C3D8T 耦合)
    EF_ACOUSTIC       =  8_i4, &  ! 声学族     (AC2D/AC3D 系列)
    EF_SPECIAL        =  9_i4, &  ! 特殊/连接族 (SPRING/DASHPOT/MASS/CONN/PIPE)
    EF_POROUS         = 10_i4, &  ! 孔隙渗流族  (C3D8P/CPE4P/C3D8RP)
    EF_ELECTROMAGNETIC= 11_i4, &  ! 电磁族     (EMC3D4/EMC3D8)
    EF_USER           = 12_i4     ! 用户扩展族  (UEL 接口，任意 DOF)

  !-- 原始 14 大族分类码（L3_MD 内部，不暴露给 L4_PH）
  !   ABAQUS elem_cat 分类（按结构力学意义）：
  INTEGER(i4), PARAMETER :: &
    EC_TRUSS          =  1_i4, &  ! 族01：桁架/杆
    EC_BEAM           =  2_i4, &  ! 族02：梁
    EC_MEMBRANE       =  3_i4, &  ! 族03：膜
    EC_SHELL          =  4_i4, &  ! 族04：壳体
    EC_SOLID2D        =  5_i4, &  ! 族05：2D 实体（平面应变/应力/轴对称）
    EC_SOLID3D        =  6_i4, &  ! 族06：3D 实体
    EC_SPECIAL        =  7_i4, &  ! 族07：弹簧/阻尼/质量/连接器
    EC_DIST_PARAM     =  8_i4, &  ! 族08：分布参数（管道流体等）→ 合并入 EF_SPECIAL
    EC_ACOUSTIC       =  9_i4, &  ! 族09：声学
    EC_HEAT           = 10_i4, &  ! 族10：纯热传导（DC 系列）
    EC_COUPLED_THERM  = 11_i4, &  ! 族11：热-力耦合（如 C3D8T）→ 合并入 EF_THERMAL
    EC_POROUS         = 12_i4, &  ! 族12：孔隙渗流
    EC_EM             = 13_i4, &  ! 族13：电磁
    EC_USER           = 14_i4     ! 族14：用户单元（UEL）

END MODULE MD_Elem_Family_Enum_Mod
```

### 1.3 原始族→计算功能族映射函数（Get_ElemFamily_Proc）

```fortran
!===============================================================================
! MD_Elem_GetFamily_Mod — 原始单元族码 → 计算功能族 ID 的映射
! 文件：UFC/ufc_core/L3_MD/Mesh/MD_Elem_GetFamily.f90
! 调用时机：Populate 冷路径（解析 *ELEMENT 关键字后立即调用）
! 热路径禁止：本子程序含 SELECT CASE，热路径只用缓存的 elem_family
!===============================================================================
MODULE MD_Elem_GetFamily_Mod
  USE IF_Precision,           ONLY: i4
  USE MD_Elem_Family_Enum_Mod, ONLY: &
    EF_SOLID, EF_SOLID2D, EF_SHELL, EF_BEAM, EF_TRUSS, EF_MEMBRANE,   &
    EF_THERMAL, EF_ACOUSTIC, EF_SPECIAL, EF_POROUS, EF_ELECTROMAGNETIC, EF_USER, &
    EC_TRUSS, EC_BEAM, EC_MEMBRANE, EC_SHELL, EC_SOLID2D, EC_SOLID3D,  &
    EC_SPECIAL, EC_DIST_PARAM, EC_ACOUSTIC, EC_HEAT, EC_COUPLED_THERM, &
    EC_POROUS, EC_EM, EC_USER
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Elem_GetFamily_Proc

CONTAINS

  !-- 将 14 大族原始分类码 → 12 计算功能族 ID
  !   [IN]  elem_cat  : 原始族码（EC_* 常量）
  !   [OUT] elem_fam  : 计算功能族（EF_* 常量）
  !   [OUT] ierr      : 0=成功, 1001=未知族码
  PURE SUBROUTINE MD_Elem_GetFamily_Proc(elem_cat, elem_fam, ierr)
    INTEGER(i4), INTENT(IN)  :: elem_cat  ![IN]  原始 14 大族分类码
    INTEGER(i4), INTENT(OUT) :: elem_fam  ![OUT] 12 计算功能族
    INTEGER(i4), INTENT(OUT) :: ierr      ![OUT] 错误码

    ierr = 0_i4

    SELECT CASE (elem_cat)
      CASE (EC_TRUSS)        ; elem_fam = EF_TRUSS
      CASE (EC_BEAM)         ; elem_fam = EF_BEAM
      CASE (EC_MEMBRANE)     ; elem_fam = EF_MEMBRANE
      CASE (EC_SHELL)        ; elem_fam = EF_SHELL
      CASE (EC_SOLID2D)      ; elem_fam = EF_SOLID2D
      CASE (EC_SOLID3D)      ; elem_fam = EF_SOLID
      CASE (EC_SPECIAL)      ; elem_fam = EF_SPECIAL
      CASE (EC_DIST_PARAM)   ; elem_fam = EF_SPECIAL      ! 族08 合并入 EF_SPECIAL
      CASE (EC_ACOUSTIC)     ; elem_fam = EF_ACOUSTIC
      CASE (EC_HEAT)         ; elem_fam = EF_THERMAL
      CASE (EC_COUPLED_THERM); elem_fam = EF_THERMAL      ! 族11 合并入 EF_THERMAL
      CASE (EC_POROUS)       ; elem_fam = EF_POROUS
      CASE (EC_EM)           ; elem_fam = EF_ELECTROMAGNETIC
      CASE (EC_USER)         ; elem_fam = EF_USER
      CASE DEFAULT
        elem_fam = 0_i4
        ierr     = 1001_i4  ! 未知族码
    END SELECT

  END SUBROUTINE MD_Elem_GetFamily_Proc

END MODULE MD_Elem_GetFamily_Mod
```

---

## 二、材料族完整枚举方案

### 2.1 设计背景：11 主族（T1）与 74 叶（T3）

UFC 材料分类体系采用三层分类（T1/T2/T3），与正交设计相关的是：

- **T1 主族**（11个）：决定合法性矩阵的列；与 `MF_*` 枚举一一对应
- **T3 叶（mat_id）**：74个具体材料 ID；通过映射函数归属到 T1 主族

> **注意**：`MAT_TAXONOMY.md` 中 T1 主族名为 `ELA/PLM/PLG/HYP/VSC/DMG/CMP/MPH/POR/SPU/USR`，
> 在正交合法性矩阵中对应 `MF_ELASTIC/MF_PLASTIC/MF_GEOTECH/MF_HYPERELAS/MF_VISCOELAS/
> MF_DAMAGE/MF_COMPOSITE/MF_THERMAL/MF_POROUS/MF_SPECIAL/MF_USER`（MPH→MF_THERMAL 并入）。

**MPH 特殊处理说明**：74 叶中 `MPH`（多物理场）共 11 叶（mat_id 108-111, 601-607），
在合法性矩阵中归入 `MF_THERMAL`（热传导族）列，因为它们的单元兼容性与纯热材料相同。

### 2.2 完整材料族枚举模块（MD_Mat_Family_Enum_Mod）

```fortran
!===============================================================================
! MD_Mat_Family_Enum_Mod — 材料主族（T1）枚举
! 文件：UFC/ufc_core/L3_MD/Material/MD_Mat_Family_Enum.f90
! 状态：编译期常量，不可运行时修改
! 关联：MAT_TAXONOMY.md §2，Section_ElemMat_Compat_Matrix.md §三
!===============================================================================
MODULE MD_Mat_Family_Enum_Mod
  USE IF_Precision, ONLY: i4
  IMPLICIT NONE
  PUBLIC

  !-- 材料主族总数（扩展时同步修改，并在 ELEM_MAT_COMPAT 矩阵追加列）
  INTEGER(i4), PARAMETER :: N_MAT_FAMILY = 11_i4

  !-- 材料主族枚举（值 = 矩阵列号）
  !   与 MAT_TAXONOMY T1 代码的对应关系见括号
  INTEGER(i4), PARAMETER :: &
    MF_ELASTIC        =  1_i4, &  ! ELA：小应变弹性（6叶：101-106,112部分）
    MF_PLASTIC        =  2_i4, &  ! PLM：金属塑性率无关/率相关（9叶）
    MF_GEOTECH        =  3_i4, &  ! PLG：岩土与水泥基塑性（9叶含701）
    MF_HYPERELAS      =  4_i4, &  ! HYP：超弹性有限变形（10叶：301-310）
    MF_VISCOELAS      =  5_i4, &  ! VSC：粘弹与蠕变（9叶：107,401-408）
    MF_DAMAGE         =  6_i4, &  ! DMG：体损伤与断裂（6叶：501,503-506,509）
    MF_COMPOSITE      =  7_i4, &  ! CMP：复合材料与界面（5叶：112,214,502,507,508）
    MF_THERMAL        =  8_i4, &  ! MPH/THM：热传导/热膨胀/多物理场（11叶：108-111,601-607）
    MF_POROUS         =  9_i4, &  ! POR：孔洞与泡沫（2叶：205,212）
    MF_SPECIAL        = 10_i4, &  ! SPU：特殊材料/EOS/流体/电磁（6叶：702-707）
    MF_USER           = 11_i4     ! USR：用户扩展/UMAT（1叶：708）

  !-- T1 主族代号字符串（长度固定 8，便于日志输出）
  CHARACTER(LEN=8), PARAMETER :: MAT_FAMILY_NAMES(N_MAT_FAMILY) = [ &
    'ELA     ', 'PLM     ', 'PLG     ', 'HYP     ', 'VSC     ', &
    'DMG     ', 'CMP     ', 'MPH/THM ', 'POR     ', 'SPU     ', 'USR     ' ]

END MODULE MD_Mat_Family_Enum_Mod
```

### 2.3 74 叶 mat_id → 材料族映射函数（Get_MatFamily_Proc）

```fortran
!===============================================================================
! MD_Mat_GetFamily_Mod — mat_id → 材料主族（MF_*）映射
! 文件：UFC/ufc_core/L3_MD/Material/MD_Mat_GetFamily.f90
! 调用时机：Populate 冷路径（*MATERIAL 关键字解析后调用）
! 依据：MAT_LEAF_INDEX_74.md Primary T1 归属
! 热路径禁止：本子程序含 IF-ELSE 链，热路径只用缓存的 mat_family
!===============================================================================
MODULE MD_Mat_GetFamily_Mod
  USE IF_Precision,         ONLY: i4
  USE MD_Mat_Family_Enum_Mod, ONLY: &
    MF_ELASTIC, MF_PLASTIC, MF_GEOTECH, MF_HYPERELAS, MF_VISCOELAS, &
    MF_DAMAGE, MF_COMPOSITE, MF_THERMAL, MF_POROUS, MF_SPECIAL, MF_USER
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_GetFamily_Proc

CONTAINS

  !-- mat_id → MF_* 主族映射（基于 MAT_LEAF_INDEX_74.md Primary T1）
  !   [IN]  mat_id   : 材料 ID（见 MD_Mat_Ids.f90）
  !   [OUT] mat_fam  : 材料主族（MF_* 常量）
  !   [OUT] ierr     : 0=成功, 1002=未知 mat_id
  PURE SUBROUTINE MD_Mat_GetFamily_Proc(mat_id, mat_fam, ierr)
    INTEGER(i4), INTENT(IN)  :: mat_id   ![IN]  74 叶材料 ID
    INTEGER(i4), INTENT(OUT) :: mat_fam  ![OUT] 材料主族（MF_*）
    INTEGER(i4), INTENT(OUT) :: ierr     ![OUT] 错误码

    ierr = 0_i4

    !-- ELA 族（6叶）：mat_id 101-106
    IF (mat_id >= 101_i4 .AND. mat_id <= 106_i4) THEN
      mat_fam = MF_ELASTIC

    !-- VSC 基础（1叶）：mat_id 107（ViscoElasticBase，历史 ID 在 ELA 区段）
    ELSE IF (mat_id == 107_i4) THEN
      mat_fam = MF_VISCOELAS

    !-- MPH/THM 族（4叶在 100 段）：mat_id 108-111
    ELSE IF (mat_id >= 108_i4 .AND. mat_id <= 111_i4) THEN
      mat_fam = MF_THERMAL

    !-- CMP 族（1叶在 100 段）：mat_id 112（LaminatedElastic）
    ELSE IF (mat_id == 112_i4) THEN
      mat_fam = MF_COMPOSITE

    !-- PLM 族（部分）：mat_id 201, 204, 206, 213, 216-220
    ELSE IF (mat_id == 201_i4 .OR. mat_id == 204_i4 .OR. mat_id == 206_i4 .OR. &
             mat_id == 213_i4 .OR. (mat_id >= 216_i4 .AND. mat_id <= 220_i4)) THEN
      mat_fam = MF_PLASTIC

    !-- PLG 族：mat_id 202, 203, 207-211, 215
    ELSE IF (mat_id == 202_i4 .OR. mat_id == 203_i4 .OR. &
             (mat_id >= 207_i4 .AND. mat_id <= 211_i4) .OR. mat_id == 215_i4) THEN
      mat_fam = MF_GEOTECH

    !-- POR 族（2叶）：mat_id 205（Gurson/GTN）, 212（CrushableFoam）
    ELSE IF (mat_id == 205_i4 .OR. mat_id == 212_i4) THEN
      mat_fam = MF_POROUS

    !-- CMP 族（1叶在 200 段）：mat_id 214（FabricPlast）
    ELSE IF (mat_id == 214_i4) THEN
      mat_fam = MF_COMPOSITE

    !-- HYP 族（10叶）：mat_id 301-310
    ELSE IF (mat_id >= 301_i4 .AND. mat_id <= 310_i4) THEN
      mat_fam = MF_HYPERELAS

    !-- VSC 族（8叶）：mat_id 401-408
    ELSE IF (mat_id >= 401_i4 .AND. mat_id <= 408_i4) THEN
      mat_fam = MF_VISCOELAS

    !-- DMG 族（4叶）：mat_id 501, 503-506, 509
    ELSE IF (mat_id == 501_i4 .OR. (mat_id >= 503_i4 .AND. mat_id <= 506_i4) .OR. &
             mat_id == 509_i4) THEN
      mat_fam = MF_DAMAGE

    !-- CMP 族（3叶在 500 段）：mat_id 502, 507, 508
    ELSE IF (mat_id == 502_i4 .OR. mat_id == 507_i4 .OR. mat_id == 508_i4) THEN
      mat_fam = MF_COMPOSITE

    !-- MPH/THM 族（7叶）：mat_id 601-607
    ELSE IF (mat_id >= 601_i4 .AND. mat_id <= 607_i4) THEN
      mat_fam = MF_THERMAL

    !-- PLG 族（1叶在 700 段）：mat_id 701（SoilMechanics）
    ELSE IF (mat_id == 701_i4) THEN
      mat_fam = MF_GEOTECH

    !-- SPU 族（6叶）：mat_id 702-707
    ELSE IF (mat_id >= 702_i4 .AND. mat_id <= 707_i4) THEN
      mat_fam = MF_SPECIAL

    !-- USR 族（1叶）：mat_id 708（UMAT/VUMAT 桥接）
    ELSE IF (mat_id == 708_i4) THEN
      mat_fam = MF_USER

    !-- 未知 mat_id
    ELSE
      mat_fam = 0_i4
      ierr    = 1002_i4
    END IF

  END SUBROUTINE MD_Mat_GetFamily_Proc

END MODULE MD_Mat_GetFamily_Mod
```

### 2.4 74 叶 mat_id→族对照速查表

| T1 主族 | MF_* 常量 | mat_id 范围 | 叶数 | 代表性 mat_id |
|--------|:--------:|------------|:---:|-------------|
| ELA（小应变弹性）| `MF_ELASTIC` | 101-106 | 6 | 101=线弹性 |
| VSC（粘弹蠕变）| `MF_VISCOELAS` | 107, 401-408 | 9 | 403=蠕变 |
| MPH（多物理场）→ THM | `MF_THERMAL` | 108-111, 601-607 | 11 | 601=导热 |
| CMP（复合材料）| `MF_COMPOSITE` | 112, 214, 502, 507, 508 | 5 | 112=层合弹性 |
| PLM（金属塑性）| `MF_PLASTIC` | 201, 204, 206, 213, 216-220 | 9 | 201=J2 |
| PLG（岩土塑性）| `MF_GEOTECH` | 202-203, 207-211, 215, 701 | 9 | 202=DP |
| POR（多孔/泡沫）| `MF_POROUS` | 205, 212 | 2 | 205=Gurson |
| HYP（超弹性）| `MF_HYPERELAS` | 301-310 | 10 | 301=MR |
| DMG（损伤断裂）| `MF_DAMAGE` | 501, 503-506, 509 | 6 | 501=韧性损伤 |
| SPU（特殊材料）| `MF_SPECIAL` | 702-707 | 6 | 702=EOS |
| USR（用户扩展）| `MF_USER` | 708 | 1 | 708=UMAT |
| **合计** | — | — | **74** | — |

---

## 三、族级×功能集正交矩阵

### 3.1 功能集定义

| 功能集 ID | 名称 | 含义 | 对应 L4_PH 过程 |
|:--------:|------|------|---------------|
| **FC_KE** | 刚度矩阵 | 切线/割线刚度矩阵 Ke | `PH_Elem_Ke_Proc` |
| **FC_FE** | 内力向量 | 单元内力向量 Fe | `PH_Elem_Fe_Proc` |
| **FC_ME** | 质量矩阵 | 一致质量 / 集中质量 Me | `PH_Elem_Me_Proc` |
| **FC_CE** | 阻尼矩阵 | Rayleigh/粘性阻尼 Ce | `PH_Elem_Ce_Proc` |
| **FC_TEMP** | 热载荷 | 温度梯度引起的等效节点力 | `PH_Elem_Temp_Proc` |
| **FC_PORE** | 孔压 DOF | 孔隙水压力自由度处理 | `PH_Elem_Pore_Proc` |
| **FC_CONTACT** | 接触 | 接触力与约束 | `PH_Contact_Core_Proc` |
| **FC_EM** | 电磁 | 电磁场 DOF 组装 | `PH_EM_Core_Proc` |

> 注：`FC_CONTACT` 和 `FC_EM` 不属于单元域内部功能，通过跨域调用实现，
> 此处标注是为了说明哪些单元族**支持该物理场的附着**。

### 3.2 单元族×功能集支持矩阵

```
功能集支持矩阵
(✅=支持, ❌=不支持, ⚠️=有条件支持)

                   FC_KE FC_FE FC_ME FC_CE FC_TEMP FC_PORE FC_CONTACT FC_EM
EF_SOLID3D   (01)  ✅    ✅    ✅    ✅     ⚠️      ❌      ✅         ❌
EF_SOLID2D   (02)  ✅    ✅    ✅    ✅     ⚠️      ❌      ✅         ❌
EF_SHELL     (03)  ✅    ✅    ✅    ✅     ⚠️      ❌      ✅         ❌
EF_BEAM      (04)  ✅    ✅    ✅    ✅     ❌      ❌      ❌         ❌
EF_TRUSS     (05)  ✅    ✅    ✅    ❌     ❌      ❌      ❌         ❌
EF_MEMBRANE  (06)  ✅    ✅    ✅    ⚠️    ❌      ❌      ✅         ❌
EF_THERMAL   (07)  ✅    ✅    ❌    ❌     ✅      ❌      ❌         ❌
EF_ACOUSTIC  (08)  ✅    ✅    ✅    ✅     ❌      ❌      ❌         ❌
EF_SPECIAL   (09)  ⚠️   ✅    ⚠️   ✅     ❌      ❌      ❌         ❌
EF_POROUS    (10)  ✅    ✅    ✅    ✅     ⚠️      ✅      ❌         ❌
EF_EM        (11)  ✅    ✅    ❌    ❌     ❌      ❌      ❌         ✅
EF_USER      (12)  ✅    ✅    ✅    ✅     ✅      ✅      ✅         ✅
```

**条件说明**：

| 符号 | 含义 | 典型条件 |
|------|------|---------|
| `⚠️ FC_TEMP` | 仅热-力耦合单元支持（如 C3D8T，归入 EF_THERMAL） | 需指定 `COUPLED TEMPERATURE-DISPLACEMENT` |
| `⚠️ FC_CE (EF_MEMBRANE)` | 仅显式分析时的人工阻尼 | `*DAMPING` 属性指定 |
| `⚠️ FC_KE/ME (EF_SPECIAL)` | 弹簧有 Ke，阻尼无；质量单元有 Me | 依赖连接器子类型 |
| `⚠️ FC_TEMP (EF_POROUS)` | 孔隙-热-力三场耦合时需配合热传导 | `*COUPLED PORE FLUID DIFFUSION` |

### 3.3 功能集×材料族联动约束

部分功能集只有在特定材料族才有意义：

| 功能集 | 必需材料族 | 约束说明 |
|--------|---------|---------|
| FC_KE（弹性刚度）| MF_ELASTIC / MF_HYPERELAS（主） | 切线刚度来自本构矩阵 C_tan |
| FC_KE（弹塑性刚度）| MF_PLASTIC / MF_DAMAGE | 需要弹塑性切线，NSTATV≥1 |
| FC_PORE | MF_ELASTIC（孔弹）/ MF_GEOTECH / MF_POROUS | 必须有孔压 DOF |
| FC_TEMP | MF_THERMAL | DC 热单元+热材料 |
| FC_EM | MF_SPECIAL（SPU_EM）| 电磁场方程材料参数 |

---

## 四、截面类型族与单元/材料族三维正交视图

### 4.1 三维正交视图定义

正交设计实际上是一个**三维稀疏张量**：

```
维度 1：单元计算功能族  EF_* （12 级别）
维度 2：材料主族        MF_* （11 级别）
维度 3：截面几何类型    ST_* （9 类型）

合法元素 (EF_i, MF_j, ST_k) = .TRUE. 当且仅当：
  ELEM_MAT_COMPAT(i, j) = .TRUE.   且
  SECT_ELEM_COMPAT(k, i) = .TRUE.
```

### 4.2 截面几何类型枚举

```fortran
!===============================================================================
! MD_Sect_Type_Enum_Mod — 截面几何类型枚举
! 文件：UFC/ufc_core/L3_MD/Section/MD_Sect_Type_Enum.f90
!===============================================================================
MODULE MD_Sect_Type_Enum_Mod
  USE IF_Precision, ONLY: i4
  IMPLICIT NONE
  PUBLIC

  INTEGER(i4), PARAMETER :: N_SECT_TYPE = 9_i4

  INTEGER(i4), PARAMETER :: &
    ST_SOLID       = 1_i4, &  ! 实体截面（无厚度属性）
    ST_SHELL       = 2_i4, &  ! 壳截面（有厚度/层合）
    ST_BEAM        = 3_i4, &  ! 梁截面（A/I 截面属性）
    ST_TRUSS       = 4_i4, &  ! 桁架截面（仅面积 A）
    ST_MEMBRANE    = 5_i4, &  ! 膜截面（有厚度）
    ST_COHESIVE    = 6_i4, &  ! 黏聚截面（界面损伤专用）
    ST_GASKET      = 7_i4, &  ! 垫片截面（接触专用）
    ST_ACOUSTIC    = 8_i4, &  ! 声学截面（无力学属性）
    ST_USER        = 9_i4     ! 用户自定义截面

END MODULE MD_Sect_Type_Enum_Mod
```

### 4.3 截面几何类型 × 单元族相容矩阵（SECT_ELEM_COMPAT）

```fortran
!-- SECT_ELEM_COMPAT(sect_type, elem_family)
!   行：ST_* (9种截面类型)；列：EF_* (12种单元族)
!   .TRUE. = 截面类型与单元族的几何属性相容

LOGICAL, PARAMETER :: SECT_ELEM_COMPAT(N_SECT_TYPE, N_ELEM_FAMILY) = RESHAPE( [&
  !             EF_ EF_ EF_ EF_ EF_ EF_ EF_ EF_ EF_ EF_ EF_ EF_
  !             SLD S2D SHL BEM TRS MEM THM ACU SPL POR EM  USR
  !-- ST_SOLID:
  .T., .T., .F., .F., .F., .F., .T., .T., .F., .T., .T., .T., &
  !-- ST_SHELL:
  .F., .F., .T., .F., .F., .F., .F., .F., .F., .F., .F., .T., &
  !-- ST_BEAM:
  .F., .F., .F., .T., .F., .F., .F., .F., .F., .F., .F., .T., &
  !-- ST_TRUSS:
  .F., .F., .F., .F., .T., .F., .F., .F., .F., .F., .F., .T., &
  !-- ST_MEMBRANE:
  .F., .F., .F., .F., .F., .T., .F., .F., .F., .F., .F., .T., &
  !-- ST_COHESIVE:
  .F., .F., .T., .F., .F., .F., .F., .F., .F., .F., .F., .T., &
  !-- ST_GASKET:
  .F., .F., .F., .F., .F., .F., .F., .F., .T., .F., .F., .T., &
  !-- ST_ACOUSTIC:
  .F., .F., .F., .F., .F., .F., .F., .T., .F., .F., .F., .T., &
  !-- ST_USER:
  .T., .T., .T., .T., .T., .T., .T., .T., .T., .T., .T., .T.  &
], SHAPE=[N_SECT_TYPE, N_ELEM_FAMILY] )
```

**矩阵可读版**（行=截面类型，列=单元族，T=相容，F=不相容）：

```
截面×单元相容矩阵（SECT_ELEM_COMPAT）

              EF_SLD EF_S2D EF_SHL EF_BEM EF_TRS EF_MEM EF_THM EF_ACU EF_SPL EF_POR EF_EM  EF_USR
ST_SOLID (1)    T      T      F      F      F      F      T      T      F      T      T      T
ST_SHELL (2)    F      F      T      F      F      F      F      F      F      F      F      T
ST_BEAM  (3)    F      F      F      T      F      F      F      F      F      F      F      T
ST_TRUSS (4)    F      F      F      F      T      F      F      F      F      F      F      T
ST_MEMB  (5)    F      F      F      F      F      T      F      F      F      F      F      T
ST_COHE  (6)    F      F      T      F      F      F      F      F      F      F      F      T
ST_GASK  (7)    F      F      F      F      F      F      F      F      T      F      F      T
ST_ACOU  (8)    F      F      F      F      F      F      F      T      F      F      F      T
ST_USER  (9)    T      T      T      T      T      T      T      T      T      T      T      T
```

### 4.4 三维合法性综合检查

```fortran
!===============================================================================
! MD_Sect_Check_Full_Proc — 三维正交合法性检查（冷路径）
! 检查 (截面类型, 单元族, 材料族) 三重组合的合法性
! 文件：UFC/ufc_core/L3_MD/Section/MD_Sect_CheckFull.f90
!===============================================================================
SUBROUTINE MD_Sect_Check_Full_Proc(sect_type, elem_family, mat_family, error_code)
  USE MD_Sect_Compat_Const_Mod, ONLY: ELEM_MAT_COMPAT
  USE MD_Sect_Type_Enum_Mod,    ONLY: N_SECT_TYPE, SECT_ELEM_COMPAT
  USE MD_Elem_Family_Enum_Mod,  ONLY: N_ELEM_FAMILY
  USE MD_Mat_Family_Enum_Mod,   ONLY: N_MAT_FAMILY
  IMPLICIT NONE

  INTEGER(i4), INTENT(IN)  :: sect_type    ![IN]  截面几何类型（ST_*）
  INTEGER(i4), INTENT(IN)  :: elem_family  ![IN]  单元计算功能族（EF_*）
  INTEGER(i4), INTENT(IN)  :: mat_family   ![OUT] 材料主族（MF_*）
  INTEGER(i4), INTENT(OUT) :: error_code   ![OUT] 0=合法；非0=错误码

  error_code = 0_i4

  !-- §1 范围检查
  IF (sect_type   < 1_i4 .OR. sect_type   > N_SECT_TYPE  ) THEN
    error_code = 1003_i4 ; RETURN  ! 非法截面类型
  END IF
  IF (elem_family < 1_i4 .OR. elem_family > N_ELEM_FAMILY) THEN
    error_code = 1001_i4 ; RETURN  ! 非法单元族
  END IF
  IF (mat_family  < 1_i4 .OR. mat_family  > N_MAT_FAMILY ) THEN
    error_code = 1002_i4 ; RETURN  ! 非法材料族
  END IF

  !-- §2 截面类型与单元族相容检查（二维矩阵）
  IF (.NOT. SECT_ELEM_COMPAT(sect_type, elem_family)) THEN
    error_code = 2002_i4 ; RETURN  ! 截面类型与单元族不相容
  END IF

  !-- §3 单元族与材料族相容检查（二维矩阵）
  IF (.NOT. ELEM_MAT_COMPAT(elem_family, mat_family)) THEN
    error_code = 2001_i4 ; RETURN  ! 单元族与材料族不相容
  END IF

END SUBROUTINE MD_Sect_Check_Full_Proc
```

---

## 五、统一枚举汇总模块

### 5.1 设计目标

提供单一 `USE` 入口，使 L3/L4/L5 各层只需引用一个模块即可获得全部枚举常量，
避免分散 `USE` 导致的遗漏与版本不一致。

```fortran
!===============================================================================
! MD_FamEnum_All_Mod — 族级枚举统一汇总模块（便捷 USE 入口）
! 文件：UFC/ufc_core/L3_MD/MD_FamEnum_All.f90
! 用法：USE MD_FamEnum_All_Mod（一行获得全部 EF_* / MF_* / ST_* 常量）
! 注意：不含 ELEM_MAT_COMPAT 矩阵（矩阵体积较大，仅在需要时引用）
!===============================================================================
MODULE MD_FamEnum_All_Mod
  USE MD_Elem_Family_Enum_Mod, ONLY: &
    N_ELEM_FAMILY,                                                           &
    EF_SOLID, EF_SOLID2D, EF_SHELL, EF_BEAM, EF_TRUSS, EF_MEMBRANE,        &
    EF_THERMAL, EF_ACOUSTIC, EF_SPECIAL, EF_POROUS, EF_ELECTROMAGNETIC,     &
    EF_USER,                                                                 &
    EC_TRUSS, EC_BEAM, EC_MEMBRANE, EC_SHELL, EC_SOLID2D, EC_SOLID3D,       &
    EC_SPECIAL, EC_DIST_PARAM, EC_ACOUSTIC, EC_HEAT, EC_COUPLED_THERM,      &
    EC_POROUS, EC_EM, EC_USER

  USE MD_Mat_Family_Enum_Mod, ONLY: &
    N_MAT_FAMILY,                                                            &
    MF_ELASTIC, MF_PLASTIC, MF_GEOTECH, MF_HYPERELAS, MF_VISCOELAS,        &
    MF_DAMAGE, MF_COMPOSITE, MF_THERMAL, MF_POROUS, MF_SPECIAL, MF_USER,   &
    MAT_FAMILY_NAMES

  USE MD_Sect_Type_Enum_Mod, ONLY: &
    N_SECT_TYPE,                                                             &
    ST_SOLID, ST_SHELL, ST_BEAM, ST_TRUSS, ST_MEMBRANE,                     &
    ST_COHESIVE, ST_GASKET, ST_ACOUSTIC, ST_USER

  IMPLICIT NONE
  PUBLIC
  !-- 本模块只做 re-export，无额外定义

END MODULE MD_FamEnum_All_Mod
```

### 5.2 各层推荐引用方式

| 层 | 推荐方式 | 说明 |
|----|---------|------|
| L3_MD（解析/Populate）| `USE MD_FamEnum_All_Mod` | 需要 14→12 族转换的场合另加 `MD_Elem_GetFamily_Mod` |
| L4_PH（计算内核）| `USE MD_FamEnum_All_Mod, ONLY: EF_*, MF_*` | 热路径只用缓存族 ID，不调用映射函数 |
| L5_RT（运行时路由）| `USE MD_FamEnum_All_Mod, ONLY: EF_*, MF_*` | 路由表索引只需枚举值 |
| 合法性检查（冷路径）| `USE MD_Sect_Compat_Const_Mod` + `USE MD_FamEnum_All_Mod` | 两者配合使用 |
| 映射函数（冷路径）| `USE MD_Elem_GetFamily_Mod` / `USE MD_Mat_GetFamily_Mod` | 仅在 Populate 中调用 |

---

## 六、文件部署位置汇总

| 模块名 | 建议文件路径 | 职责 |
|--------|------------|------|
| `MD_Elem_Family_Enum_Mod` | `UFC/ufc_core/L3_MD/Mesh/MD_Elem_Family_Enum.f90` | 12族枚举+14族原始码 |
| `MD_Elem_GetFamily_Mod` | `UFC/ufc_core/L3_MD/Mesh/MD_Elem_GetFamily.f90` | 14→12族映射函数 |
| `MD_Mat_Family_Enum_Mod` | `UFC/ufc_core/L3_MD/Material/MD_Mat_Family_Enum.f90` | 11族枚举 |
| `MD_Mat_GetFamily_Mod` | `UFC/ufc_core/L3_MD/Material/MD_Mat_GetFamily.f90` | 74叶mat_id→族映射 |
| `MD_Sect_Type_Enum_Mod` | `UFC/ufc_core/L3_MD/Section/MD_Sect_Type_Enum.f90` | 截面几何类型枚举 |
| `MD_Sect_Compat_Const_Mod` | `UFC/ufc_core/L3_MD/Section/MD_Sect_Compat_Const.f90` | 12×11合法性矩阵 |
| `MD_Sect_Check_Full_Proc` | `UFC/ufc_core/L3_MD/Section/MD_Sect_CheckFull.f90` | 三维合法性检查 |
| `MD_FamEnum_All_Mod` | `UFC/ufc_core/L3_MD/MD_FamEnum_All.f90` | 汇总 re-export |

**模块依赖关系**：

```
MD_FamEnum_All_Mod
  ├── MD_Elem_Family_Enum_Mod   (无上游依赖)
  ├── MD_Mat_Family_Enum_Mod    (无上游依赖)
  └── MD_Sect_Type_Enum_Mod     (无上游依赖)

MD_Elem_GetFamily_Mod
  └── MD_Elem_Family_Enum_Mod

MD_Mat_GetFamily_Mod
  └── MD_Mat_Family_Enum_Mod

MD_Sect_Compat_Const_Mod
  ├── MD_Elem_Family_Enum_Mod   (获取 N_ELEM_FAMILY)
  └── MD_Mat_Family_Enum_Mod    (获取 N_MAT_FAMILY)

MD_Sect_Check_Full_Proc
  ├── MD_Sect_Compat_Const_Mod  (ELEM_MAT_COMPAT)
  ├── MD_Sect_Type_Enum_Mod     (SECT_ELEM_COMPAT)
  ├── MD_Elem_Family_Enum_Mod   (N_ELEM_FAMILY)
  └── MD_Mat_Family_Enum_Mod    (N_MAT_FAMILY)
```

---

## 七、扩展策略（正交设计演化规则）

### 7.1 添加新单元族（扩展 EF_* 枚举）

**必须同步修改的文件**（按顺序）：

```
步骤 1: MD_Elem_Family_Enum.f90
  - 添加 EF_NEWTYPE = N_ELEM_FAMILY + 1 常量
  - 将 N_ELEM_FAMILY 从 12 改为 13
  - 添加对应原始族 EC_* 常量（如有）

步骤 2: MD_Sect_Compat_Const.f90
  - 在 ELEM_MAT_COMPAT RESHAPE 数组末尾追加 1 行（11 个 .T./.F. 值）
  - SHAPE=[13, 11]

步骤 3: MD_Sect_CheckFull.f90（若 SECT_ELEM_COMPAT 也在此）
  - 在 SECT_ELEM_COMPAT 追加 1 列（9 个 .T./.F. 值）
  - SHAPE=[9, 13]

步骤 4: MD_Elem_GetFamily.f90
  - 在 SELECT CASE 中添加新 CASE 分支

步骤 5: MD_FamEnum_All.f90
  - 在 USE MD_Elem_Family_Enum_Mod ONLY 列表中添加 EF_NEWTYPE

步骤 6: Section_ElemMat_Compat_Matrix.md（本文档配套）
  - 更新矩阵可读版和统计表

步骤 7（可选）: MD_Sect_NewType_Desc
  - 若新单元族有特殊截面几何属性，新建截面子类型 TYPE
```

### 7.2 添加新材料族（扩展 MF_* 枚举）

**必须同步修改的文件**（按顺序）：

```
步骤 1: MD_Mat_Family_Enum.f90
  - 添加 MF_NEWMAT = N_MAT_FAMILY + 1 常量
  - 将 N_MAT_FAMILY 从 11 改为 12
  - 在 MAT_FAMILY_NAMES 数组中追加名称字符串

步骤 2: MD_Sect_Compat_Const.f90
  - 在 ELEM_MAT_COMPAT RESHAPE 数组每行末尾追加 1 个 .T./.F. 值（共 12 行）
  - SHAPE=[12, 12]

步骤 3: MD_Mat_GetFamily.f90
  - 在 IF-ELSE 链中添加新 mat_id 范围分支

步骤 4: MD_FamEnum_All.f90
  - 在 USE MD_Mat_Family_Enum_Mod ONLY 列表中添加 MF_NEWMAT

步骤 5: MAT_LEAF_INDEX_74.md + MAT_TAXONOMY.md
  - 若有新 mat_id，在索引表中登记

步骤 6: Section_ElemMat_Compat_Matrix.md（配套更新）
  - 更新矩阵可读版和统计表
```

### 7.3 扩展禁止模式（Anti-Pattern 清单）

| # | 禁止操作 | 危害 | 正确做法 |
|---|---------|------|---------|
| A1 | 在热路径调用 `Get_ElemFamily_Proc` | 每积分点 SELECT CASE 开销 | Populate 时缓存 `elem_family` 到 `MD_Sect_Base_Desc` |
| A2 | 在热路径调用 `Get_MatFamily_Proc` | 同上，IF-ELSE 链开销 | Populate 时缓存 `mat_family` 到 `MD_Mat_Base_Desc` |
| A3 | 直接比较 mat_id 范围（如 `mat_id > 200 .AND. mat_id < 300`）| 脆弱，mat_id 重排后失效 | 用缓存的 `mat_family` 做比较 |
| A4 | 绕过 Section 直接建立 Element→Material 指针 | 破坏截面枢纽，合法性无法保证 | 所有绑定通过 `MD_Sect_Registry` |
| A5 | `N_ELEM_FAMILY` / `N_MAT_FAMILY` 硬编码数字 | 扩展时漏改 SHAPE | 始终用 `SHAPE=[N_ELEM_FAMILY, N_MAT_FAMILY]` |
| A6 | 在 `ELEM_MAT_COMPAT` 外单独维护合法性逻辑 | 双重真相源，易不一致 | 合法性判断唯一入口：`ELEM_MAT_COMPAT` + `SECT_ELEM_COMPAT` |
| A7 | 将 MPH（多物理场）族单独映射为 `MF_MPH` | 与现有 11 族矩阵不兼容 | MPH 归入 `MF_THERMAL`，通过 mat_id 范围区分 |

---

## 八、与配套文档的关系

| 文档 | 关系 |
|------|------|
| [`Section_ElemMat_Compat_Matrix.md`](Section_ElemMat_Compat_Matrix.md) | **本文件** 是其枚举方案的扩展；合法性矩阵核心定义在该文件 |
| [`ABAQUS_Section_Architecture.md`](ABAQUS_Section_Architecture.md) | 提供截面关键字架构；本文件为其提供 Fortran 枚举对应 |
| [`ABAQUS_Subroutine_UFC_TYPE_Mapping.md`](ABAQUS_Subroutine_UFC_TYPE_Mapping.md) | 子程序参数映射；mat_family 在 UMAT 的 CMNAME 路由中使用 |
| [`MAT_TAXONOMY.md`](../10_材料专项/_inv/MAT_TAXONOMY.md) | T1/T2/T3 三级分类的权威来源；`MF_*` 枚举与 T1 一一对应 |
| [`MAT_LEAF_INDEX_74.md`](../10_材料专项/_inv/MAT_T1_SPEC/MAT_LEAF_INDEX_74.md) | 74 叶 mat_id 与 Primary T1 的权威索引；`Get_MatFamily_Proc` 的数据来源 |
| [`单元域 L3-L4-L5 三层架构设计方案.md`](../03_实施规划/单元域改造/单元域 L3-L4-L5 三层架构设计方案.md) | 14 大族 265 种单元的详细定义；`EC_*` 原始族码的来源 |
| [`DOMAIN_CARD_Template.md`](../../templates/DOMAIN_CARD_Template.md) | 域级合同卡模板；Section 域合同卡应引用本文件的枚举常量 |

---

<!-- 版本历史 -->
<!-- v1.0 (2026-04-13) 初始版本 -->
<!-- 覆盖：12族枚举模块、74叶映射函数、族级×功能集矩阵、三维正交视图、汇总模块、扩展策略 -->
