# Version_Compatibility_Policy — UFC 版本兼容与废弃策略

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/06_核心架构/Version_Compatibility_Policy.md`  
> **配套文档**：`Error_Propagation_Architecture.md` · `fem-kernel-observability` 技能 · `fem-kernel-api-design` 技能  
> **版本**：v1.0  
> **日期**：2026-04-13  
> **状态**：已定稿（初版）

---

## 一、文档目的

本文档定义 UFC 各层（L1~L6）、各域的**版本兼容性承诺**与**废弃（Deprecation）流程**，
确保：

1. UFC 内核升级不对下游用户造成静默破坏
2. ABAQUS 版本升级（6.14→2020→最新）有可预测的响应窗口
3. 枚举值冻结规则清晰，防止枚举漂移（Enum Drift）
4. TYPE 字段扩展有安全的 ABI 边界

---

## 二、兼容性承诺等级

### 2.1 三级承诺体系

| 等级 | 名称 | 承诺内容 | 适用场景 |
|------|------|---------|---------|
| **🔴 P0** | **稳定承诺** | 永久冻结，跨版本兼容 | TYPE 字段名 / 枚举常量 / API 签名 |
| **🟡 P1** | **版本承诺** | 主版本（X.y.z）内冻结 | 子程序签名 / 错误码 / 行为 |
| **🟢 P2** | **实验承诺** | 小版本（x.Y.z）内冻结 | 新增域 / 新增功能集 / 实验性 API |

### 2.2 P0 稳定承诺（永久冻结）

以下元素**永久冻结**，不得修改、重编号或废弃：

```fortran
! 冻结的枚举常量（不得修改值或重编号）
INTEGER(i4), PARAMETER :: EF_SOLID = 1_i4     ! ❌ 禁止重编号
INTEGER(i4), PARAMETER :: EF_SHELL  = 3_i4     ! ❌ 禁止删除
INTEGER(i4), PARAMETER :: MF_ELASTIC = 1_i4    ! ❌ 禁止修改
INTEGER(i4), PARAMETER :: MF_USER   = 11_i4   ! ❌ 禁止废弃

! 冻结的 TYPE 字段名（不得改名或删除）
TYPE :: PH_Mat_Base_State
  REAL(wp), ALLOCATABLE :: stress(:)  ! ❌ 禁止改名为 s11 / stress_vec
  REAL(wp), ALLOCATABLE :: strain(:)  ! ❌ 禁止改为 epsilon
END TYPE

! 冻结的子程序签名（不得改参数顺序/类型）
SUBROUTINE PH_Mat_UMAT_API(desc, state, algo, ctx, args, status)
  ! ❌ 禁止在 desc 前插入新参数
  ! ❌ 禁止将 status 改为 INTENT(INOUT)
END SUBROUTINE
```

**扩展方式**（P0 字段扩展）：
- ✅ 新增字段加到 TYPE 结构体末尾（向后兼容）
- ✅ 在子程序签名末尾追加可选参数 `OPTIONAL`
- ❌ 不得在现有字段之间插入新字段
- ❌ 不得修改字段类型或 INTENT

### 2.3 P1 版本承诺（主版本冻结）

```fortran
! 在同一主版本内，以下行为冻结：
!
! ✓ 行为冻结示例：
!   - L4_PH/Material 热路径返回 ERROR 时，返回的错误码值固定
!   - ELEM_MAT_COMPAT 矩阵的 .TRUE./.FALSE. 值固定（跨小版本）
!
! ❌ 禁止在同一主版本内：
!   - 修改已有 ERROR_CODE 的值（ERR_L4_PM_401_DIVERGENCE = 4401 不得改为 4402）
!   - 改变子程序的返回值语义（返回值 > 0 的含义不得改变）
```

### 2.4 P2 实验承诺（实验性 API）

```fortran
! 新增功能使用 EXPERIMENTAL 标记
TYPE, PUBLIC :: PH_NewFeature_Desc
  ! 实验性字段（可在小版本间修改）
  REAL(wp) :: experimental_field = 0.0_wp
END TYPE

! 实验性子程序签名带 _EXP 后缀
SUBROUTINE PH_NewFeature_EXP_API(desc, state, algo, ctx, args, status) &
    BIND(C, name="ph_newfeature_exp")
  ! 实现中检查版本兼容性
  IF (ufc_version_major < 5) THEN
    CALL UFC_Error_Raise(ERR_L6_AP_601_UNSUPPORTED_API, "PH_NewFeature_EXP_API", &
        "Requires UFC v5.0+", ctx, status)
    RETURN
  END IF
END SUBROUTINE
```

---

## 三、枚举冻结规则

### 3.1 枚举值不可逆变更

> **铁律**：枚举常量一旦发布，**值不可修改**，**编号不可重排**。
> 如需变更，必须走 Deprecation 流程。

| 操作 | 是否允许 | 说明 |
|------|---------|------|
| 给已有枚举加新常量 | ✅ 允许 | 追加到末尾，不改变现有值 |
| 删除已有枚举常量 | ❌ 禁止 | 走 Deprecation 标记为废弃 |
| 修改枚举常量的值 | ❌ 禁止 | 即使修正错误也不得直接修改 |
| 重编号枚举常量 | ❌ 禁止 | 会破坏 ABI 和持久化文件格式 |
| 修改枚举常量名 | ❌ 禁止 | 走重命名 Deprecation 流程 |

### 3.2 枚举扩展规范

```fortran
!===============================================================================
! 示例：新增 EF_ELECTROMAGNETIC（11）到 EF_USER（12）之间
! 正确方式：在末尾追加，不插入中间
!===============================================================================
INTEGER(i4), PARAMETER :: &
  EF_SOLID          =  1_i4, &
  EF_SOLID2D        =  2_i4, &
  EF_SHELL          =  3_i4, &
  EF_BEAM           =  4_i4, &
  EF_TRUSS          =  5_i4, &
  EF_MEMBRANE       =  6_i4, &
  EF_THERMAL        =  7_i4, &
  EF_ACOUSTIC       =  8_i4, &
  EF_SPECIAL        =  9_i4, &
  EF_POROUS         = 10_i4, &
  EF_ELECTROMAGNETIC= 11_i4, &  ! ✅ 追加，不插入
  EF_USER           = 12_i4      ! ✅ 编号不变
```

### 3.3 枚举废弃（Deprecation）流程

当枚举常量需要废弃时：

```fortran
! Step 1：标记为 DEPRECATED（值保持不变）
INTEGER(i4), PARAMETER :: &
  EF_DEPRECATED_FOAM = 9_i4   ! DEPRECATED in UFC v4.0, use EF_POROUS(10)
  ! 仍可使用，但编译器发出警告

! Step 2：在 DEPRECATED 标记的小版本文档中记录
! 文档：Version_Compatibility_Policy.md §5.1 枚举废弃清单

! Step 3：下一个主版本中删除
! INTEGER(i4), PARAMETER :: EF_DEPRECATED_FOAM = 9_i4  -- 已删除
```

---

## 四、TYPE 字段扩展规范

### 4.1 TYPE 版本化

```fortran
! 每个重要 TYPE 携带版本字段
TYPE :: PH_Mat_Base_Desc
  INTEGER(i4) :: type_version = 1_i4   ! 版本号，初始化时设置
  INTEGER(i4) :: mat_id = 0_i4         ! P0 稳定字段
  CHARACTER(len=64) :: model_name = ""  ! P0 稳定字段
  ! --- v2 新增字段（向后兼容）---
  INTEGER(i4) :: stabilization_flag = 0_i4  ! P2 新字段
  ! --- v3 新增字段（向后兼容）---
  REAL(wp)    :: numerical_damping = 0.0_wp ! P2 新字段
END TYPE
```

### 4.2 字段向后兼容规则

```fortran
! 读取旧版本文件（type_version=1）时的兼容处理
SUBROUTINE PH_Mat_Desc_Deserialize(stream, desc, status)
  TYPE(ByteStream), INTENT(IN)    :: stream
  TYPE(PH_Mat_Base_Desc), INTENT(OUT) :: desc
  TYPE(ErrorStatusType), INTENT(OUT)  :: status

  CALL ByteStream_Read_Integer(stream, desc%mat_id)     ! v1 字段
  CALL ByteStream_Read_String(stream, desc%model_name)  ! v1 字段

  IF (stream%version >= 2) THEN
    CALL ByteStream_Read_Integer(stream, desc%stabilization_flag) ! v2
  ELSE
    desc%stabilization_flag = 0_i4  ! 默认值
  END IF

  IF (stream%version >= 3) THEN
    CALL ByteStream_Read_Real(stream, desc%numerical_damping) ! v3
  ELSE
    desc%numerical_damping = 0.0_wp  ! 默认值
  END IF

  status%ok = .TRUE.
END SUBROUTINE
```

### 4.3 热路径 TYPE 扩展禁止

> **铁律**：热路径（每增量步/迭代）中使用的 TYPE 结构体，
> **不得**在运行时动态扩展字段。扩展仅在 Populate 冷路径允许。

```fortran
! ❌ 热路径禁止：
TYPE :: PH_Mat_Base_State
  ! ...
  REAL(wp), ALLOCATABLE :: stress(:)
  REAL(wp), ALLOCATABLE :: extra_field(:)  ! ❌ 运行时扩展的字段（热路径）
END TYPE

! ✅ 正确：在 Populate 时 ALLOCATE，在热路径中不改变 SIZE
TYPE :: PH_Mat_Base_State
  REAL(wp), ALLOCATABLE :: stress(:)
  REAL(wp), ALLOCATABLE :: extra_field(:)  ! ✅ 在 Populate 时分配大小
END TYPE
```

---

## 五、ABAQUS 版本变更响应策略

### 5.1 ABAQUS 版本兼容性矩阵

| UFC 版本 | 兼容 ABAQUS 版本 | 说明 |
|---------|-----------------|------|
| UFC v3.x | ABAQUS 6.14, 2016, 2017 | 旧版参数表 |
| UFC v4.x | ABAQUS 2018, 2019, 2020 | 中间过渡版 |
| UFC v5.x | ABAQUS 2021, 2022, 2023 | 当前稳定版 |
| UFC v6.x | ABAQUS 2024, 2025, 2026 | 规划支持 |

### 5.2 ABAQUS 用户子程序变更响应流程

```
ABAQUS 发布新版本
  ↓
检查影响范围（影响分析）
  ├─ 影响的 UFC 域：Material / Element / Load / Contact / Field
  ├─ 影响程度：新增参数 / 废弃参数 / 行为变更
  └─ 紧急程度：CRITICAL / HIGH / MEDIUM / LOW
  ↓
三阶段响应窗口
  ├─ 阶段1（30天内）：发布 UFC 技术通知（不修改代码）
  ├─ 阶段2（90天内）：发布兼容性补丁（版本承诺内）
  └─ 阶段3（下一主版本）：正式支持/废弃旧版本
  ↓
变更记录到 CHANGELOG + 版本兼容矩阵（本文档 §5.1）
```

### 5.3 ABAQUS 常见变更类型

| 变更类型 | 影响 | 响应策略 |
|---------|------|---------|
| **新增参数**（如 UMAT 新增 `PROPS` 数组大小）| 低 | 在 Adapter 层忽略，警告日志 |
| **废弃参数**（如某个 VUMAT 参数不再使用）| 低 | 在 Adapter 层填默认值，继续传递 |
| **新增子程序**（如新 ABAQUS 版本新增 UANLYSEL）| 中 | 评估是否需要对应 UFC 域 |
| **参数含义变更**（如 NTENS 的值在特定条件下改变）| 高 | 在 Adapter 层特殊处理 |
| **行为不兼容**（如显式求解器行为变化）| 极高 | 单独版本分支处理 |

### 5.4 Adapter 层版本协商

```fortran
! 在 Adapter 入口处协商 ABAQUS 版本
SUBROUTINE PH_Mat_UMAT_Adapter(...)
  USE ABAQUS_Version_Compat, ONLY: ABAQUS_Version_Get, ABAQUS_Version_Is_GE

  INTEGER(i4) :: abaqus_ver
  CALL ABAQUS_Version_Get(abaqus_ver)

  ! 版本特定参数处理
  IF (abaqus_ver >= ABAQUS_2022) THEN
    ! ABAQUS 2022+: 使用扩展的 PROPS 数组
    CALL PH_Mat_UMAT_API_2022(...)
  ELSE IF (abaqus_ver >= ABAQUS_2018) THEN
    ! ABAQUS 2018-2021: 标准 PROPS 数组
    CALL PH_Mat_UMAT_API_2018(...)
  ELSE
    ! 旧版本：发出警告但继续
    CALL UFC_Log_Write(LVL_WARN, "PH_Mat_UMAT_Adapter", &
        "ABAQUS version may have reduced functionality")
    CALL PH_Mat_UMAT_API_2018(...)
  END IF
END SUBROUTINE
```

---

## 六、废弃（Deprecation）流程

### 6.1 废弃触发条件

| 触发条件 | 优先级 | 废弃周期 |
|---------|--------|---------|
| 发现安全漏洞利用的旧 API | CRITICAL | 立即标记，下一版本删除 |
| 严重架构缺陷，无法安全维护 | HIGH | 1 个主版本 |
| 次要功能重复，可合并 | MEDIUM | 2 个主版本 |
| 优化/重构机会，性能收益 > 20% | LOW | 3 个主版本 |
| 用户明确要求保留 | N/A | 不废弃 |

### 6.2 废弃声明格式

```fortran
! 在需要废弃的符号处添加 DEPRECATED 标记和文档注释
!
! DEPRECATED: PH_Mat_Legacy_API
!   废弃版本：UFC v4.2
!   删除版本：UFC v5.0（计划）
!   替代者：  PH_Mat_UMAT_API
!   原因：    统一签名，废弃分散的 legacy API
!   迁移：    将 USE PH_Mat_Legacy 替换为 USE PH_Mat_UMAT
!
SUBROUTINE PH_Mat_Legacy_API(desc, state, algo, pnewdt, status)
  ...
END SUBROUTINE PH_Mat_Legacy_API
```

### 6.3 废弃清单（示例格式）

| 废弃项 | 废弃版本 | 删除版本 | 替代者 | 状态 |
|--------|---------|---------|--------|------|
| `PH_Mat_Legacy_API` | v4.2 | v5.0（计划）| `PH_Mat_UMAT_API` | DEPRECATED |
| `EF_DEPRECATED_FOAM` | v4.0 | v5.0（计划）| `EF_POROUS` | DEPRECATED |
| `MD_Amplitude_Table_Linear` | v4.5 | v6.0（计划）| `MD_Amplitude_Interpolate` | DEPRECATED |

---

## 七、CI 自动化兼容检查

### 7.1 编译期检查（静态）

| 检查项 | 工具 | 触发时机 |
|--------|------|---------|
| 枚举值未被修改 | `verify_mat_family_mapping.py --check-enum-frozen` | 每次提交前 |
| TYPE 字段顺序正确（无中间插入）| `verify_*.py` 中的 R1 检查 | 每次提交前 |
| 子程序签名无变更 | `gfortran -fsyntax-only` + 接口文件对比 | 每次提交前 |
| 废弃标记符号存在 | `grep_code` 搜索 `DEPRECATED` 注释 | PR 审查时 |

### 7.2 运行时检查

```fortran
! 在关键 TYPE 的初始化中添加运行时版本一致性检查
SUBROUTINE PH_Mat_Base_State_Init(state, status)
  TYPE(PH_Mat_Base_State), INTENT(OUT) :: state
  TYPE(ErrorStatusType), INTENT(OUT)  :: status

  ! 检查编译时与运行时版本匹配
  IF (PH_MAT_BASE_STATE_VERSION /= PH_MAT_BASE_STATE_RUNTIME_VERSION) THEN
    CALL UFC_Error_Raise( &
      ERR_L1_ERR_103_VERSION_MISMATCH, &
      "PH_Mat_Base_State_Init", &
      "Compile-time version does not match runtime version", &
      ctx, status)
    RETURN
  END IF

  status%ok = .TRUE.
END SUBROUTINE
```

### 7.3 自动化验证脚本（CI 集成）

```bash
#!/bin/bash
# UFC/compat_check.sh — 版本兼容检查 CI 脚本
# 在每次 PR 提交时自动运行

set -e

echo "=== UFC Version Compatibility Check ==="

echo "[1/5] Checking enum frozen values..."
python tools/verify_mat_family_mapping.py --check-enum-frozen || exit 1

echo "[2/5] Checking ELEM_MAT_COMPAT matrix..."
python tools/verify_elem_mat_compat_matrix.py || exit 1

echo "[3/5] Checking domain cross-reference..."
python tools/verify_domain_contract_cross_ref.py || exit 1

echo "[4/5] Checking for forbidden deprecated symbols..."
grep -r "DEPRECATED" UFC/ufc_core/L*_*/contracts/*.f90 && echo "Found DEPRECATED symbols - ensure migration path exists"

echo "[5/5] Checking Fortran syntax..."
find UFC/ufc_core -name "*.f90" -exec gfortran -fsyntax-only -std=f2003 {} + || exit 1

echo "=== All compatibility checks passed ==="
```

---

## 八、版本号语义规范（Semantic Versioning）

UFC 版本号遵循 `Major.Minor.Patch`：

```
UFC v5.3.2
│  │  └── Patch（错误修复，不改变行为）
│  └────── Minor（新增功能，向后兼容）
└────────── Major（破坏性变更，需显式迁移）
```

| 版本增量 | 变更类型 | 兼容性保证 |
|---------|---------|-----------|
| Patch | 错误修复、文档更新 | 完全兼容 |
| Minor | 新增 TYPE 字段/枚举常量/子程序 | 向后兼容（P0/P1 字段冻结）|
| Major | 删除/重命名/重编号 | 不兼容，需迁移指南 |

---

## 九、实施检查清单

### 9.1 新增枚举常量前

| # | 检查项 | 责任人 |
|---|--------|-------|
| 1 | 确认枚举追加到末尾（不插入中间）| 开发者 |
| 2 | 确认枚举值与文档 §3.1 对齐 | 架构师 |
| 3 | 在 `verify_mat_family_mapping.py` 中更新 MAT_LEAF_MAP | 开发者 |
| 4 | 更新 `N_ELEM_FAMILY` / `N_MAT_FAMILY` 参数（如有）| 开发者 |
| 5 | 在 CHANGELOG 中记录新增 | 文档管理员 |

### 9.2 新增 TYPE 字段前

| # | 检查项 | 责任人 |
|---|--------|-------|
| 1 | 确认新字段追加到 TYPE 结构体末尾 | 开发者 |
| 2 | 确认新字段有默认值（用于旧版本初始化）| 开发者 |
| 3 | 更新 deserialize/serialize 过程（向后兼容）| 开发者 |
| 4 | 在 TYPE 版本字段中增加主版本号 | 开发者 |
| 5 | 在本文档 §4 中记录变更 | 文档管理员 |

### 9.3 ABAQUS 版本响应前

| # | 检查项 | 责任人 |
|---|--------|-------|
| 1 | 确认变更类型（新增/废弃/行为变更）| 架构师 |
| 2 | 填写三阶段响应窗口（§5.2）| 架构师 |
| 3 | 在 `gen_umat_adapter.py` 中更新受影响 adapter | 开发者 |
| 4 | 在 CI 中添加版本特定测试用例 | 测试工程师 |
| 5 | 更新本文档 §5.1 兼容性矩阵 | 文档管理员 |

---

**版本历史**：

| 版本 | 日期 | 修改内容 |
|------|------|---------|
| v1.0 | 2026-04-13 | 初始版本，定义三级兼容性承诺、枚举冻结规则、ABAQUS 版本响应流程、废弃流程、CI 自动化检查 |
