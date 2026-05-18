# UFC 代码迁移指南

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: 从旧代码迁移到新架构  
> **上级参考**: UFC_架构设计总纲_六层四类四链三步三级两图一体.md（v2.0）

---

## 📋 文档说明

本文档提供从旧代码迁移到新架构的完整指南，包括：

- 迁移步骤
- 命名规范迁移（旧前缀 → 新前缀）
- 数据结构迁移（旧 TYPE → 新 TYPE）
- 接口迁移（旧接口 → 新接口）
- 常见迁移问题与解决方案

---

## 目录

1. [迁移概述](#1-迁移概述)
2. [命名规范迁移](#2-命名规范迁移)
3. [数据结构迁移](#3-数据结构迁移)
4. [接口迁移](#4-接口迁移)
5. [迁移工具](#5-迁移工具)
6. [常见问题](#6-常见问题)
7. [迁移检查清单](#7-迁移检查清单)

---

## 1. 迁移概述

### 1.1 迁移目标

**从**: 旧代码（非规范命名、分散结构）  
**到**: 新架构（UFC 规范、六层架构、容器化）

### 1.2 迁移范围

**需要迁移的内容**:

- 模块命名（旧前缀 → 新前缀）
- TYPE 定义（旧类型 → 新类型）
- 子程序命名（旧接口 → 新接口）
- 文件组织（旧目录 → 新目录）
- 依赖关系（旧依赖 → 新依赖）

### 1.3 迁移策略

**渐进式迁移**:

1. **Phase 1**: 命名规范迁移（1-2 个月）
2. **Phase 2**: 数据结构迁移（2-3 个月）
3. **Phase 3**: 接口迁移（3-4 个月）
4. **Phase 4**: 容器化集成（4-6 个月）

---

## 2. 命名规范迁移

### 2.1 前缀迁移表


| 旧前缀   | 新前缀                                                            | 示例                            |
| ----- | -------------------------------------------------------------- | ----------------------------- |
| `UF`_ | `IF_` (L1) / `MD_` (L3) / `PH_` (L4) / `RT_` (L5) / `AP_` (L6) | `UF_Material` → `MD_Material` |
| `VD_` | `MD_` (L3_MD)                                                  | `VD_Part` → `MD_Part`         |
| `CF`_ | `PH_` (L4_PH)                                                  | `CF_Element` → `PH_Elem`      |
| `PP`_ | `RT_` (L5_RT)                                                  | `PP_Solver` → `RT_Solver`     |


### 2.2 模块命名迁移

**旧命名**:

```fortran
MODULE UF_Material_Lib
  ! ...
END MODULE
```

**新命名**:

```fortran
MODULE MD_Material_Core
  ! ...
END MODULE
```

**迁移步骤**:

1. 确定模块所属层级（L1-L6）
2. 确定模块所属域级（Material, Mesh, Elem等）
3. 选择后缀（`_Core`, `_API`, `_Type`）
4. 重命名模块
5. 更新所有 `USE` 语句

### 2.3 TYPE 命名迁移

**旧命名**:

```fortran
TYPE :: MaterialType
  REAL(8) :: E
  REAL(8) :: nu
END TYPE
```

**新命名**:

```fortran
TYPE :: MD_Material_Desc_Type
  REAL(wp) :: young_modulus
  REAL(wp) :: poisson_ratio
END TYPE
```

**迁移规则**:

1. 添加层级前缀（`MD_`）
2. 添加域级前缀（`Material`）
3. 添加功能后缀（`_Desc`, `_State`, `_Algo`, `_Ctx`）
4. 添加 `_Type` 后缀
5. 使用 `wp` 而非 `REAL(8)`

---

## 3. 数据结构迁移

### 3.1 精度类型迁移

**旧代码**:

```fortran
REAL(8) :: stress
INTEGER(4) :: n_nodes
```

**新代码**:

```fortran
USE IF_Prec, ONLY: wp, i4

REAL(wp) :: stress
INTEGER(i4) :: n_nodes
```

**迁移工具**:

```bash
# 自动替换
sed -i 's/REAL(8)/REAL(wp)/g' *.f90
sed -i 's/INTEGER(4)/INTEGER(i4)/g' *.f90
```

### 3.2 TYPE 字段迁移

**旧代码**:

```fortran
TYPE :: MaterialType
  CHARACTER(LEN=32) :: name
  REAL(8) :: E
  REAL(8) :: nu
END TYPE
```

**新代码**:

```fortran
TYPE :: MD_Material_Desc_Type
  CHARACTER(len=64) :: name = ''
  REAL(wp) :: young_modulus = 0.0_wp
  REAL(wp) :: poisson_ratio = 0.0_wp
  LOGICAL :: initialized = .FALSE.
CONTAINS
  PROCEDURE :: Init => MD_Material_Desc_Init
  PROCEDURE :: Finalize => MD_Material_Desc_Finalize
END TYPE
```

**迁移步骤**:

1. 重命名字段（`E` → `young_modulus`）
2. 添加默认值
3. 添加 `initialized` 标志
4. 添加 `CONTAINS` 部分（Init/Finalize）

---

## 4. 接口迁移

### 4.1 子程序命名迁移

**旧接口**:

```fortran
SUBROUTINE InitMaterial(mat, name, E, nu)
  TYPE(MaterialType), INTENT(INOUT) :: mat
  CHARACTER(LEN=*), INTENT(IN) :: name
  REAL(8), INTENT(IN) :: E, nu
END SUBROUTINE
```

**新接口**:

```fortran
SUBROUTINE MD_Material_Desc_Init(this, name, young_modulus, poisson_ratio, status)
  CLASS(MD_Material_Desc_Type), INTENT(INOUT) :: this
  CHARACTER(len=*), INTENT(IN) :: name
  REAL(wp), INTENT(IN) :: young_modulus, poisson_ratio
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
END SUBROUTINE
```

**迁移规则**:

1. 使用四段式命名：`Layer_Domain_Function_Suffix`
2. 第一个参数改为 `this`（类型绑定过程）
3. 添加 `status` 参数（错误处理）
4. 使用 `CLASS` 而非 `TYPE`（类型绑定）

### 4.2 错误处理迁移

**旧代码**:

```fortran
SUBROUTINE ComputeStress(strain, stress)
  REAL(8), INTENT(IN) :: strain(6)
  REAL(8), INTENT(OUT) :: stress(6)
  
  IF (strain(1) < 0) THEN
    WRITE(*,*) 'Error: Negative strain'
    RETURN
  END IF
  
  stress = E * strain
END SUBROUTINE
```

**新代码**:

```fortran
SUBROUTINE PH_Mat_Evaluate(material_desc, strain, stress, ddsdde, state, status)
  TYPE(MD_Material_Desc_Type), INTENT(IN) :: material_desc
  REAL(wp), INTENT(IN) :: strain(6)
  REAL(wp), INTENT(OUT) :: stress(6)
  REAL(wp), INTENT(OUT) :: ddsdde(6,6)
  TYPE(PH_Mat_State_Type), INTENT(INOUT) :: state
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
  
  IF (strain(1) < 0) THEN
    CALL UFC_Error_Raise(status, PH_ERR_INVALID_STRAIN, &
      'PH_Mat: Negative strain detected')
    RETURN
  END IF
  
  stress = material_desc%young_modulus * strain
END SUBROUTINE
```

**迁移规则**:

1. 使用 `ErrorStatusType` 而非 `WRITE(*,*)`
2. 使用 `UFC_Error_Raise` 设置错误
3. 使用错误码常量
4. 错误消息格式：`"<模块>: <原因>"`

---

## 5. 迁移工具

### 5.1 自动迁移脚本

**脚本**: `tools/migrate_naming.py`

**功能**:

- 自动替换模块名
- 自动替换 TYPE 名
- 自动替换子程序名
- 自动更新 `USE` 语句

**使用方法**:

```bash
python tools/migrate_naming.py --path ufc_core/ --dry-run
python tools/migrate_naming.py --path ufc_core/ --apply
```

### 5.2 迁移映射文件

**文件**: `tools/migration_map.json`

**格式**:

```json
{
  "modules": {
    "UF_Material_Lib": "MD_Material_Core",
    "VD_Part": "MD_Part_Core"
  },
  "types": {
    "MaterialType": "MD_Material_Desc_Type",
    "PartType": "MD_Part_Desc_Type"
  },
  "procedures": {
    "InitMaterial": "MD_Material_Desc_Init",
    "CreatePart": "MD_Part_Desc_Init"
  }
}
```

---

## 6. 常见问题

### Q1: 如何确定模块所属层级？

**答案**: 根据模块职责判断

- **L1_IF**: 基础设施（精度、错误、内存、日志）
- **L2_NM**: 数值算法（求解器、时间积分、矩阵）
- **L3_MD**: 模型数据（材料、网格、部件）
- **L4_PH**: 物理计算（单元、材料本构、接触）
- **L5_RT**: 运行时（求解器调度、Step控制）
- **L6_AP**: 应用层（输入解析、输出、Job管理）

### Q2: 如何迁移全局变量？

**答案**: 使用全局容器

**旧代码**:

```fortran
REAL(8), SAVE :: global_stress(1000)
```

**新代码**:

```fortran
USE UF_GlobalContainer_Core, ONLY: g_ufc_global

! 访问全局数据
g_ufc_global%l5_rt%global_state%stress
```

### Q3: 如何迁移旧的文件 I/O？

**答案**: 使用 L1_IF IO 模块

**旧代码**:

```fortran
OPEN(UNIT=10, FILE='data.dat')
READ(10, *) value
CLOSE(10)
```

**新代码**:

```fortran
USE IF_IO_Core, ONLY: IF_Reader_Type

TYPE(IF_Reader_Type) :: reader
CALL reader%Open('data.dat', status)
CALL reader%Read(value, status)
CALL reader%Close(status)
```

---

## 7. 迁移检查清单

### 7.1 命名规范检查

- 所有模块使用新前缀（`IF_`, `MD_`, `PH_`, `RT_`, `AP_`）
- 所有 TYPE 使用四段式命名
- 所有子程序使用四段式命名
- 所有常量使用 `Layer_Domain_CONSTANT_NAME` 格式

### 7.2 数据结构检查

- 所有 `REAL(8)` 替换为 `REAL(wp)`
- 所有 `INTEGER(4)` 替换为 `INTEGER(i4)`
- 所有 TYPE 添加 `initialized` 标志
- 所有 TYPE 添加 `CONTAINS` 部分（Init/Finalize）

### 7.3 接口检查

- 所有子程序添加 `status` 参数
- 所有错误处理使用 `ErrorStatusType`
- 所有类型绑定过程使用 `this` 参数
- 所有 `USE` 语句更新为新模块名

### 7.4 功能检查

- 编译通过（零错误）
- 单元测试通过
- 集成测试通过
- 性能无退化（< 5%）

---

## 附录

### A.1 迁移工具速查


| 工具                      | 用途      | 状态     |
| ----------------------- | ------- | ------ |
| `migrate_naming.py`     | 自动命名迁移  | 🟡 待实现 |
| `migrate_types.py`      | TYPE 迁移 | 🟡 待实现 |
| `migrate_interfaces.py` | 接口迁移    | 🟡 待实现 |


### A.2 相关文档

- `UFC_NAMING_STANDARD.md` - 命名规范
- `UFC_架构设计总纲_六层四类四链三步三级两图一体.md` - 架构总纲
- `UFC_DEVELOPER_GUIDE.md` - 开发者指南

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队