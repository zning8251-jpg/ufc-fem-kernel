# UFC 过程级设计推演模板

> **版本**: v1.0 | **日期**: 2026-04-25
> **用途**: 从域级 CONTRACT 推演出每个 f90 模块内部子程序的完整接口签名。
> **关联**: [SKELETON_SPEC.md](SKELETON_SPEC.md) · [Skeleton_Guide.md](UFC_Skeleton_Guide.md) · [中间层总纲 v3（全景套件）](../PPLAN/11_闭环落地专项/05_中间架构层新版总纲_全景套件v3.0.md) · [SIO / Principle #14](../PPLAN/04_技术标准/UFC_Principle14_结构化IO参数传递规范.md)

---

## 一、推演流程总览

```
CONTRACT.md              "域做什么"
   │
   ├─ 1. 四型裁剪          选择 Desc/State/Algo/Ctx 哪些保留
   │
   ├─ 2. 功能集映射         Init/Compute/Query/Mutate/...
   │
   ├─ 3. 算法步骤分解       从理论公式 → 计算步骤列表
   │
   ├─ 4. 子程序设计         每个步骤 → 一个 Subroutine 签名
   │
   ├─ 5. 接口签名确定       INTENT、四型切片、热路径标注
   │
   └─ 6. 文件归属           _Def / _Core / _Brg 分配
```

---

## 二、步骤详解

### 步骤 1: 四型裁剪

根据域的职责确定保留哪些 TYPE。使用 [Skeleton_Guide.md](UFC_Skeleton_Guide.md) 的裁剪决策树：

| 四型 | 保留条件 | 省略条件 |
|------|---------|---------|
| **Desc** | 总是保留 | — |
| **State** | 有跨步/增量演化数据 | 纯只读域 → 合并到 Desc |
| **Algo** | 有算法选择/控制参数 | 固定算法 → 省略 |
| **Ctx** | 热路径临时数组 / 跨层数据传递 | 无临时数据 → 省略 |

### 步骤 2: 功能集映射

将 CONTRACT.md 中的「核心接口（按功能集）」表展开为具体子程序名：

| 功能集 | 命名公式 | 示例 |
|--------|---------|------|
| Init | `{L}_{D}_{F}_Init` | `PH_Mat_Elas_Init` |
| Finalize | `{L}_{D}_{F}_Finalize` | `PH_Mat_Elas_Finalize` |
| Compute | `{L}_{D}_{F}_Compute_{What}` | `PH_Mat_Elas_Compute_Stress` |
| Query | `{L}_{D}_{F}_Get_{What}` | `PH_Mat_Elas_Get_Tangent` |
| Mutate | `{L}_{D}_{F}_Set_{What}` | `PH_Mat_Elas_Set_Props` |
| Validate | `{L}_{D}_{F}_Validate_{What}` | `PH_Mat_Elas_Validate_Props` |
| Bridge | `{L}_{D}_{F}_Brg_{Verb}` | `PH_Mat_Elas_Brg_ToL5` |

### 步骤 3: 算法步骤分解

从理论公式出发，分解为有序步骤：

```
理论公式:  σ = C : ε   (各向同性线弹性)
                ↓
算法步骤:
  S1. 验证参数 (E > 0, -1 < ν < 0.5)
  S2. 计算 Lamé 参数 (λ, G)
  S3. 构造弹性矩阵 D_el (6×6 Voigt)
  S4. 应力更新 σ = D_el · ε
  S5. (可选) 返回一致切线 C_tan = D_el
```

每个步骤对应一个子程序或内联操作。

### 步骤 4: 子程序设计

每个非平凡步骤编写子程序签名：

```fortran
SUBROUTINE PH_Mat_Elas_Validate_Props(nprops, props, status)
  INTEGER(i4), INTENT(IN)  :: nprops
  REAL(wp),    INTENT(IN)  :: props(:)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
END SUBROUTINE

SUBROUTINE PH_Mat_Elas_Build_D_el(E, nu, D_el, status)
  REAL(wp), INTENT(IN)  :: E, nu
  REAL(wp), INTENT(OUT) :: D_el(6,6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
END SUBROUTINE

SUBROUTINE PH_Mat_Elas_Compute_Stress(D_el, strain, stress, status)
  REAL(wp), INTENT(IN)  :: D_el(6,6)
  REAL(wp), INTENT(IN)  :: strain(6)
  REAL(wp), INTENT(OUT) :: stress(6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  ! HOT_PATH: O(36) FLOPS
END SUBROUTINE
```

### 步骤 5: 接口签名规范

| 规则 | 说明 |
|------|------|
| `INTENT(IN)` | 所有只读输入 |
| `INTENT(OUT)` | 纯输出（调用方不假定初始值） |
| `INTENT(INOUT)` | 需要读取并修改的量（如 State 演化） |
| `status` | 总是最后一个参数，`INTENT(OUT)` |
| 四型引用 | 通过 `TYPE(XX_Desc), INTENT(IN)` 等传递，不拆散结构体 |
| 热路径 | 注释 `! HOT_PATH: O(N) FLOPS` 标注复杂度 |
| 冷路径 | 注释 `! COLD_PATH` 标注 |

### 步骤 6: 文件归属

| 内容类型 | 归属文件 |
|---------|---------|
| TYPE 定义 (Desc/State/Algo/Ctx) | `*_Def.f90` |
| 常量、枚举、*_Arg | `*_Def.f90` |
| Init / Finalize | `*_Core.f90` |
| Compute / Query / Mutate | `*_Core.f90` |
| Validate | `*_Core.f90` 或 `*_Def.f90`（简单校验） |
| 跨层桥接 | `*_Brg.f90` |

---

## 三、完整样板：L4_PH / Material / Elas（各向同性线弹性）

### 3.1 理论背景

各向同性线弹性本构关系 (Voigt 记法):

```
σ = D_el · ε

D_el = [λ+2G  λ    λ    0  0  0]
       [λ    λ+2G  λ    0  0  0]
       [λ     λ   λ+2G  0  0  0]
       [0     0    0    G  0  0]
       [0     0    0    0  G  0]
       [0     0    0    0  0  G]

其中:  G = E / (2(1+ν))
       λ = Eν / ((1+ν)(1-2ν))
```

### 3.2 四型裁剪

| 四型 | 决策 | 理由 |
|------|------|------|
| **Desc** | 保留 | 材料参数 E, ν, 密度等 |
| **State** | 省略 | 线弹性无状态演化（无塑性变量） |
| **Algo** | 省略 | 固定算法（Voigt 矩阵乘法），无选择 |
| **Ctx** | 保留（轻量） | 热路径临时工作数组 (D_el, stress_trial) |

### 3.3 算法步骤分解

```
步骤                           复杂度   路径
────────────────────────────── ─────── ──────
S1. ValidateProps               O(1)    COLD
S2. InitFromProps (计算 G,λ,K)  O(1)    COLD
S3. Build_D_el (构造弹性矩阵)   O(36)   HOT
S4. Compute_Stress (σ=D·ε)     O(36)   HOT
S5. Compute_Tangent (C=D_el)    O(36)   HOT
S6. Init_SDV (状态变量初始化)   O(N_SDV) COLD
```

### 3.4 过程清单（完整签名）

#### `PH_Mat_Elas_Def.f90` — TYPE 定义

```fortran
MODULE PH_Mat_Elas_Def
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Elas_Desc
  PUBLIC :: PH_Mat_Elas_Ctx
  PUBLIC :: PH_MAT_ELAS_ISO, PH_MAT_ELAS_ORTHO, PH_MAT_ELAS_ANISO

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_ISO   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_ORTHO = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_ANISO = 3_i4

  TYPE, PUBLIC :: PH_Mat_Elas_Desc
    INTEGER(i4) :: mat_id    = 0_i4
    INTEGER(i4) :: elas_type = PH_MAT_ELAS_ISO
    REAL(wp)    :: E         = 0.0_wp     ! Young's modulus
    REAL(wp)    :: nu        = 0.0_wp     ! Poisson's ratio
    REAL(wp)    :: G         = 0.0_wp     ! Shear modulus (derived)
    REAL(wp)    :: K_bulk    = 0.0_wp     ! Bulk modulus (derived)
    REAL(wp)    :: lambda    = 0.0_wp     ! Lamé first parameter (derived)
    REAL(wp)    :: rho       = 0.0_wp     ! Density (optional)
    LOGICAL     :: is_valid  = .FALSE.
  END TYPE PH_Mat_Elas_Desc

  TYPE, PUBLIC :: PH_Mat_Elas_Ctx
    REAL(wp) :: D_el(6,6)          = 0.0_wp  ! Elastic stiffness matrix
    REAL(wp) :: stress_trial(6)    = 0.0_wp  ! Trial stress work array
    LOGICAL  :: D_el_cached        = .FALSE.
  END TYPE PH_Mat_Elas_Ctx

END MODULE PH_Mat_Elas_Def
```

#### `PH_Mat_Elas_Core.f90` — 域逻辑

```fortran
MODULE PH_Mat_Elas_Core
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Elas_Def, ONLY: PH_Mat_Elas_Desc, PH_Mat_Elas_Ctx, &
                              PH_MAT_ELAS_ISO
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Elas_Validate_Props
  PUBLIC :: PH_Mat_Elas_Init_From_Props
  PUBLIC :: PH_Mat_Elas_Build_D_el
  PUBLIC :: PH_Mat_Elas_Compute_Stress
  PUBLIC :: PH_Mat_Elas_Compute_Tangent
  PUBLIC :: PH_Mat_Elas_Init_SDV

CONTAINS

  !---------------------------------------------------------------------------
  ! S1. ValidateProps — 参数合法性校验
  ! COLD_PATH | O(1)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Validate_Props(nprops, props, status)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (nprops < 2) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Elas]: nprops must be >= 2"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Elas]: E must be > 0"
      RETURN
    END IF

    IF (props(2) <= -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Elas]: nu must be in (-1, 0.5)"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Validate_Props

  !---------------------------------------------------------------------------
  ! S2. InitFromProps — 从参数数组初始化 Desc
  ! COLD_PATH | O(1)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Init_From_Props(desc, nprops, props, status)
    TYPE(PH_Mat_Elas_Desc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL PH_Mat_Elas_Validate_Props(nprops, props, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    desc%E  = props(1)
    desc%nu = props(2)
    IF (nprops >= 3) desc%rho = props(3)

    desc%G      = desc%E / (2.0_wp * (1.0_wp + desc%nu))
    desc%K_bulk = desc%E / (3.0_wp * (1.0_wp - 2.0_wp * desc%nu))
    desc%lambda = desc%E * desc%nu / ((1.0_wp + desc%nu) * &
                  (1.0_wp - 2.0_wp * desc%nu))
    desc%is_valid = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Init_From_Props

  !---------------------------------------------------------------------------
  ! S3. Build_D_el — 构造 6x6 Voigt 弹性刚度矩阵
  ! HOT_PATH | O(36) FLOPS
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Build_D_el(desc, ctx, status)
    TYPE(PH_Mat_Elas_Desc), INTENT(IN)    :: desc
    TYPE(PH_Mat_Elas_Ctx),  INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)    :: status

    REAL(wp) :: lam, G2

    CALL init_error_status(status)

    IF (.NOT. desc%is_valid) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Elas_Build_D_el]: desc not initialized"
      RETURN
    END IF

    lam = desc%lambda
    G2  = 2.0_wp * desc%G

    ctx%D_el = 0.0_wp
    ctx%D_el(1,1) = lam + G2;  ctx%D_el(1,2) = lam;      ctx%D_el(1,3) = lam
    ctx%D_el(2,1) = lam;       ctx%D_el(2,2) = lam + G2;  ctx%D_el(2,3) = lam
    ctx%D_el(3,1) = lam;       ctx%D_el(3,2) = lam;       ctx%D_el(3,3) = lam + G2
    ctx%D_el(4,4) = desc%G
    ctx%D_el(5,5) = desc%G
    ctx%D_el(6,6) = desc%G
    ctx%D_el_cached = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Build_D_el

  !---------------------------------------------------------------------------
  ! S4. Compute_Stress — σ = D_el · ε
  ! HOT_PATH | O(36) FLOPS
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Compute_Stress(ctx, strain, stress, status)
    TYPE(PH_Mat_Elas_Ctx), INTENT(IN)  :: ctx
    REAL(wp),              INTENT(IN)  :: strain(6)
    REAL(wp),              INTENT(OUT) :: stress(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)

    IF (.NOT. ctx%D_el_cached) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Elas_Compute_Stress]: D_el not built"
      RETURN
    END IF

    DO i = 1, 6
      stress(i) = 0.0_wp
      DO j = 1, 6
        stress(i) = stress(i) + ctx%D_el(i,j) * strain(j)
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Compute_Stress

  !---------------------------------------------------------------------------
  ! S5. Compute_Tangent — C_tan = D_el (linear elastic: tangent = stiffness)
  ! HOT_PATH | O(36) FLOPS (copy)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Compute_Tangent(ctx, tangent, status)
    TYPE(PH_Mat_Elas_Ctx), INTENT(IN)  :: ctx
    REAL(wp),              INTENT(OUT) :: tangent(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. ctx%D_el_cached) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Elas_Compute_Tangent]: D_el not built"
      RETURN
    END IF

    tangent = ctx%D_el
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Compute_Tangent

  !---------------------------------------------------------------------------
  ! S6. Init_SDV — 弹性模型无状态变量，空操作
  ! COLD_PATH | O(1)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Init_SDV(nsdv, sdv, status)
    INTEGER(i4), INTENT(OUT) :: nsdv
    REAL(wp),    INTENT(OUT) :: sdv(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    nsdv = 0
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Init_SDV

END MODULE PH_Mat_Elas_Core
```

#### `PH_Mat_Elas_Brg.f90` — 桥接

```fortran
MODULE PH_Mat_Elas_Brg
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Elas_Def,  ONLY: PH_Mat_Elas_Desc
  USE MD_ElaIso,         ONLY: MD_Mat_Iso_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Elas_Brg_FromL3Desc

CONTAINS

  !---------------------------------------------------------------------------
  ! Bridge: L3 Desc → L4 Desc 转换
  ! COLD_PATH
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Brg_FromL3Desc(l3_desc, l4_desc, status)
    TYPE(MD_Mat_Iso_Desc),  INTENT(IN)  :: l3_desc
    TYPE(PH_Mat_Elas_Desc), INTENT(OUT) :: l4_desc
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)

    l4_desc%mat_id  = l3_desc%mat_id
    l4_desc%E       = l3_desc%E
    l4_desc%nu      = l3_desc%nu
    l4_desc%G       = l3_desc%G
    l4_desc%K_bulk  = l3_desc%K
    l4_desc%lambda  = l3_desc%lambda
    l4_desc%rho     = l3_desc%rho
    l4_desc%is_valid = l3_desc%is_initialized

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Brg_FromL3Desc

END MODULE PH_Mat_Elas_Brg
```

### 3.5 设计验证清单

| 检查项 | 状态 |
|--------|------|
| 四型裁剪与 CONTRACT 一致 | OK (Desc+Ctx, 无 State/Algo) |
| 每个过程有 INTENT 声明 | OK |
| 每个过程有 status 参数 | OK |
| 热路径标注 `HOT_PATH` | OK (Build_D_el, Compute_Stress, Compute_Tangent) |
| 冷路径标注 `COLD_PATH` | OK (Validate, Init, Init_SDV) |
| USE 顺序符合 `IF_Prec → IF_Err_Brg → 本域 Def` | OK |
| PRIVATE 默认 + PUBLIC 显式 | OK |
| 无 STOP 调用 | OK |
| Brg 仅在 `_Brg.f90` 中访问其他层 TYPE | OK |
| 命名符合四场景 | OK |

---

## 四、推演流程快速参考（Checklist）

### A. 新域过程级设计

- [ ] 读取本域 `CONTRACT.md`（职责边界、核心接口、四型、十件套映射）
- [ ] 执行四型裁剪决策
- [ ] 列出功能集映射（Init/Compute/Query/...）
- [ ] 从理论/业务逻辑出发，分解算法步骤
- [ ] 为每个步骤编写子程序签名（参数 + INTENT + status）
- [ ] 标注热/冷路径和复杂度
- [ ] 分配到 `_Def.f90` / `_Core.f90` / `_Brg.f90`
- [ ] 检查 USE 依赖（不违反层级规则）
- [ ] 对照设计验证清单

### B. 既有域过程级补充

- [ ] 读取现有 f90 文件和 CONTRACT.md「细粒度子程序清单」
- [ ] 识别缺失的子程序（对比功能集映射）
- [ ] 补充缺失子程序的签名
- [ ] 更新 CONTRACT.md 清单

---

## 五、域类型差异化指导

| 域类型 | 四型重点 | 典型过程 |
|--------|---------|---------|
| **基础设施域** (L1) | 无四型 | Init/Query/Set/Log |
| **数据域** (L3) | Desc 为主 | Validate/InitFromProps/GetSummary |
| **计算域** (L4) | Desc+State+Ctx | Compute/Build/Update/ReturnMap |
| **编排域** (L5) | Ctx 为主 | Dispatch/Loop/Assemble/Solve |
| **桥接域** | Ctx 切片 | FromL3/ToL5/Pack/Unpack |
