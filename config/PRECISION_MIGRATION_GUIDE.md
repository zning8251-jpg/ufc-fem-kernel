# UFC 精度声明规范实施指南

## 📋 概述

UFC 项目已统一使用 `IF_Prec` 模块进行精度管理，取代原有的 `ISO_FORTRAN_ENV` 和自定义 KIND 参数。

## ✅ 标准格式

所有 Fortran 源文件**必须**使用以下精度声明：

```fortran
MODULE Your_Module_Name
    USE IF_Prec, ONLY: wp, i4  ! ✅ 唯一标准方式
    IMPLICIT NONE
    
    ! 所有实数类型使用 wp (working precision)
    REAL(wp) :: value, array(:), matrix(:, :)
    INTEGER(i4) :: count, indices(:)
END MODULE
```

## ❌ 禁止的做法

```fortran
! ❌ 禁止使用 ISO_FORTRAN_ENV
USE ISO_FORTRAN_ENV, ONLY: wp => REAL64
USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: wp => REAL64

! ❌ 禁止自定义 KIND 参数
INTEGER, PARAMETER :: dp = SELECTED_REAL_KIND(15, 307)
REAL(dp) :: value

! ❌ 禁止省略精度声明
REAL :: value  ! 未指定精度
```

## 🛠️ 自动化工具

### 1. 精度检查器 (`check_precision.py`)

检查文件是否符合 UFC 精度规范：

```bash
# 检查单个文件
python config/check_precision.py file.f90

# 检查多个文件
python config/check_precision.py file1.f90 file2.f90 file3.f90
```

**输出示例：**
```
======================================================================
UFC 精度声明检查器
======================================================================
检查 3 个 Fortran 源文件...

❌ some_file.f90
----------------------------------------------------------------------
   行 28: ❌ 禁止使用 ISO_FORTRAN_ENV，请改用 USE IF_Prec, ONLY: wp, i4
      内容：USE ISO_FORTRAN_ENV, ONLY: wp => REAL64
   ⚠️  缺少：USE IF_Prec, ONLY: wp, i4

======================================================================
❌ 检查失败！1/3 个文件存在违规
======================================================================
```

### 2. 迁移工具 (`migrate_precision.py`)

批量迁移旧文件到 UFC 标准格式：

```bash
# 预览模式（不实际修改）
python config/migrate_precision.py --dir UFC/ufc_core/L4_PH -n

# 实际迁移整个目录
python config/migrate_precision.py --dir UFC/ufc_core/L4_PH

# 迁移单个文件
python config/migrate_precision.py file1.f90 file2.f90
```

**输出示例：**
```
======================================================================
UFC 精度声明迁移工具
======================================================================
准备处理 50 个文件...

✓ ufc_core\L4_PH\Element\BEAM\PH_Elem_B31_Core.f90: ✓ 已迁移
✓ ufc_core\L4_PH\Element\BEAM\PH_Elem_B31_EAS_Core.f90: ✓ 已迁移

======================================================================
迁移完成：2/50 个文件已修改
成功：50/50
======================================================================
```

## 🔗 Pre-commit Hook

精度检查已集成到 pre-commit hook，提交时自动检查：

```bash
# 安装 pre-commit
pip install pre-commit
pre-commit install

# 手动运行检查
pre-commit run --all-files
```

**配置位置：** `UFC/config/.pre-commit-config.yaml`

## 📊 替换对照表

| 旧格式 | 新格式 |
|--------|--------|
| `USE ISO_FORTRAN_ENV, ONLY: wp => REAL64` | `USE IF_Prec, ONLY: wp, i4` |
| `USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: wp => REAL64` | `USE IF_Prec, ONLY: wp, i4` |
| `REAL(REAL64)` | `REAL(wp)` |
| `REAL(dp)` | `REAL(wp)` |
| `INTEGER(INT32)` | `INTEGER(i4)` |
| `1.0_REAL64` | `1.0_wp` |
| `0.125_dp` | `0.125_wp` |

## 🎯 优势

- **项目一致性**：统一使用 `IF_Prec` 模块定义的 `wp` (working precision)
- **可维护性**：通过修改 `IF_Prec.f90` 可全局切换单/双精度编译
- **简化代码**：无需在每个文件中重复定义 KIND 参数
- **域级规范**：BEAM/SHELL/SOLID 等所有域统一遵循此规范

## 📁 相关文件

- **精度模块**: `UFC/ufc_core/L1_IF/Precision/IF_Prec.f90`
- **规范文档**: `.cursor/rules/ufc-fortran-syntax.mdc`
- **检查脚本**: `UFC/config/check_precision.py`
- **迁移脚本**: `UFC/config/migrate_precision.py`
- **Pre-commit 配置**: `UFC/config/.pre-commit-config.yaml`

## 🔍 快速查找需要迁移的文件

```bash
# 使用 grep 查找使用 ISO_FORTRAN_ENV 的文件
grep -r "USE.*ISO_FORTRAN_ENV" UFC/ufc_core --include="*.f90"

# 或使用检查工具预览
python config/check_precision.py $(find UFC/ufc_core -name "*.f90")
```

## 📝 实施步骤

1. **检查现有文件**
   ```bash
   python config/check_precision.py $(find UFC/ufc_core -name "*.f90")
   ```

2. **预览迁移结果**
   ```bash
   python config/migrate_precision.py --dir UFC/ufc_core -n
   ```

3. **执行批量迁移**
   ```bash
   python config/migrate_precision.py --dir UFC/ufc_core
   ```

4. **验证迁移结果**
   ```bash
   python config/check_precision.py $(find UFC/ufc_core -name "*.f90")
   ```

5. **启用 pre-commit hook**
   ```bash
   pre-commit install
   ```

## ⚠️ 注意事项

- 迁移工具会自动备份原文件（建议先使用 `-n` 预览模式）
- 某些特殊文件（如 UEL/UMAT模板）可能需要手动调整
- 迁移后应重新编译并运行测试确保功能正常

---

**最后更新**: 2026-04-02  
**维护者**: UFC Team
