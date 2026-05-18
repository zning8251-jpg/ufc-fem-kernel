# UFC 开发者指南

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: UFC 项目开发者  
> **上级参考**: UFC_架构设计总纲_六层四类四链三步三级两图一体.md（v2.0）

---

## 📋 文档说明

本文档为 UFC 项目开发者提供完整的开发指南，包括：

- 开发环境搭建
- 代码组织结构
- 如何添加新功能
- 调试技巧
- 常见问题 FAQ
- 贡献指南

---

## 目录

1. [快速开始](#1-快速开始)
2. [开发环境配置](#2-开发环境配置)
3. [代码组织结构](#3-代码组织结构)
4. [添加新功能指南](#4-添加新功能指南)
5. [调试与测试](#5-调试与测试)
6. [代码审查流程](#6-代码审查流程)
7. [常见问题 FAQ](#7-常见问题-faq)
8. [贡献指南](#8-贡献指南)

---

## 1. 快速开始

### 1.1 克隆代码库

```bash
git clone <repository_url>
cd UFC
```

### 1.2 编译项目

```bash
# 使用 CMake（推荐）
mkdir build && cd build
cmake ..
make -j4

# 或使用 Makefile
make -f Makefile
```

### 1.3 运行示例

```bash
# 运行基础示例
./bin/ufc_solver examples/simple_beam.inp

# 运行测试套件
make test
```

---

## 2. 开发环境配置

### 2.1 编译器要求

**推荐编译器**:

- **GNU Fortran (gfortran)**: >= 9.0
- **Intel Fortran (ifort)**: >= 19.0
- **PGI Fortran (pgfortran)**: >= 20.0

**验证编译器**:

```bash
gfortran --version
# 或
ifort --version
```

### 2.2 依赖库

**必需依赖**:

- **BLAS/LAPACK**: 线性代数库
- **OpenMP**: 并行计算支持（可选但推荐）

**安装依赖（Ubuntu/Debian）**:

```bash
sudo apt-get install libblas-dev liblapack-dev libopenmpi-dev
```

**安装依赖（macOS）**:

```bash
brew install openblas lapack openmpi
```

### 2.3 IDE 配置

**推荐 IDE**:

- **Visual Studio Code** + Fortran 扩展
- **Intel Parallel Studio XE**（Windows/Linux）
- **Code::Blocks**（跨平台）

**VS Code 配置**:

```json
{
  "fortran.linter.compiler": "gfortran",
  "fortran.linter.includePaths": [
    "UFC/ufc_core/L1_IF",
    "UFC/ufc_core/L2_NM",
    "UFC/ufc_core/L3_MD",
    "UFC/ufc_core/L4_PH",
    "UFC/ufc_core/L5_RT",
    "UFC/ufc_core/L6_AP"
  ]
}
```

### 2.4 工具链安装

**Python 工具**（用于代码检查）:

```bash
pip install -r requirements.txt
```

**工具列表**:

- `check_naming_standard.py` - 命名规范检查
- `verify_layer_dependency.py` - 层级依赖检查
- `verify_type_categories.py` - TYPE 分类检查
- `check_comments.py` - 注释质量检查

---

## 3. 代码组织结构

### 3.1 目录结构

```
UFC/
├── ufc_core/              # 核心代码
│   ├── L1_IF/            # 基础设施层
│   │   ├── Precision/    # 精度定义
│   │   ├── Error/        # 错误处理
│   │   ├── Memory/       # 内存管理
│   │   ├── Log/          # 日志系统
│   │   ├── IO/           # 文件 I/O
│   │   └── Base/         # 基础工具
│   ├── L2_NM/            # 数值计算层
│   │   ├── Solver/       # 线性求解器
│   │   ├── TimeInt/      # 时间积分
│   │   ├── Eigen/        # 特征值求解
│   │   └── Matrix/       # 矩阵运算
│   ├── L3_MD/            # 模型数据层
│   │   ├── Material/     # 材料定义
│   │   ├── Mesh/         # 网格管理
│   │   ├── Part/         # 部件定义
│   │   └── ...
│   ├── L4_PH/            # 物理层
│   │   ├── Elem/         # 单元计算
│   │   ├── Mat/          # 材料本构
│   │   ├── Contact/      # 接触算法
│   │   └── ...
│   ├── L5_RT/            # 运行时层
│   │   ├── Solver/       # 求解器调度
│   │   ├── Step/         # 分析步控制
│   │   └── ...
│   └── L6_AP/            # 应用层
│       ├── Input/        # 输入解析
│       ├── Output/       # 输出管理
│       └── ...
├── PLAN/                 # 架构设计文档
├── tests/                # 测试代码
├── examples/             # 示例代码
├── tools/                # 工具脚本
└── docs/                 # 文档
```

### 3.2 模块命名规范

**模块命名**: `Layer_Domain_Core` 或 `Layer_Domain_API`

**示例**:

- `IF_Prec` - L1_IF 精度模块
- `MD_Material_Core` - L3_MD 材料核心模块
- `PH_Elem_API` - L4_PH 单元 API 模块

### 3.3 文件命名规范

**文件命名**: `Layer_Domain_Function_Suffix.f90`

**后缀约定**:

- `_Core.f90` - 核心实现
- `_API.f90` - 公共接口
- `_Brg.f90` - 跨层桥接
- `_Type.f90` - 类型定义
- `_Ctx.f90` - 上下文类型

**示例**:

- `IF_Mem_PoolMgr_Core.f90` - 内存池管理器核心
- `MD_Material_API.f90` - 材料公共接口
- `RT_MatLib_Brg.f90` - L5→L3 材料库桥接

---

## 4. 添加新功能指南

### 4.1 添加新域级（Domain）

#### 步骤 1: 创建域级目录

```bash
mkdir -p UFC/ufc_core/L3_MD/NewDomain
```

#### 步骤 2: 创建核心模块

**文件**: `L3_MD/NewDomain/MD_NewDomain_Core.f90`

```fortran
!===============================================================================
! Module: MD_NewDomain_Core
! Layer:  L3_MD - Model Data Layer
! Domain: NewDomain
! Purpose: 新域级核心实现
!===============================================================================
MODULE MD_NewDomain_Core
  USE IF_Prec, ONLY: wp, i4, i8
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: MD_NewDomain_Desc_Type
  PUBLIC :: MD_NewDomain_Desc_Init
  PUBLIC :: MD_NewDomain_Desc_Finalize
  
  ! ==========================================================
  ! 域级描述类型（Desc）
  ! ==========================================================
  TYPE, PUBLIC :: MD_NewDomain_Desc_Type
    CHARACTER(len=64) :: name = ''
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => MD_NewDomain_Desc_Init
    PROCEDURE :: Finalize => MD_NewDomain_Desc_Finalize
  END TYPE MD_NewDomain_Desc_Type
  
CONTAINS
  
  SUBROUTINE MD_NewDomain_Desc_Init(this, name, status)
    CLASS(MD_NewDomain_Desc_Type), INTENT(INOUT) :: this
    CHARACTER(len=*), INTENT(IN) :: name
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    
    this%name = name(1:MIN(64, LEN(name)))
    this%initialized = .TRUE.
  END SUBROUTINE
  
  SUBROUTINE MD_NewDomain_Desc_Finalize(this, status)
    CLASS(MD_NewDomain_Desc_Type), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    
    this%initialized = .FALSE.
  END SUBROUTINE
  
END MODULE MD_NewDomain_Core
```

#### 步骤 3: 创建域级容器

**文件**: `L3_MD/NewDomain/MD_NewDomain_Domain.f90`

```fortran
MODULE MD_NewDomain_Domain
  USE MD_NewDomain_Core, ONLY: MD_NewDomain_Desc_Type
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: MD_NewDomain_Domain_Type
  
  TYPE, PUBLIC :: MD_NewDomain_Domain_Type
    TYPE(MD_NewDomain_Desc_Type), ALLOCATABLE :: items(:)
    INTEGER(i4) :: nItems = 0_i4
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => MD_NewDomain_Domain_Init
    PROCEDURE :: Register => MD_NewDomain_Domain_Register
    PROCEDURE :: Finalize => MD_NewDomain_Domain_Finalize
  END TYPE MD_NewDomain_Domain_Type
  
CONTAINS
  
  SUBROUTINE MD_NewDomain_Domain_Init(this, status)
    CLASS(MD_NewDomain_Domain_Type), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    
    this%initialized = .TRUE.
  END SUBROUTINE
  
  SUBROUTINE MD_NewDomain_Domain_Register(this, desc, status)
    CLASS(MD_NewDomain_Domain_Type), INTENT(INOUT) :: this
    TYPE(MD_NewDomain_Desc_Type), INTENT(IN) :: desc
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    
    ! 实现注册逻辑
  END SUBROUTINE
  
END MODULE MD_NewDomain_Domain
```

#### 步骤 4: 集成到层级容器

**更新**: `L3_MD/L3_MD_LayerContainer.f90`

```fortran
TYPE, PUBLIC :: L3_MD_LayerContainer_Type
  ! ... 现有域级 ...
  TYPE(MD_NewDomain_Domain_Type) :: new_domain  ! 新增域级
END TYPE
```

#### 步骤 5: 更新文档

- 更新 `UFC_L3_MD_架构设计规范.md`
- 更新 `UFC_L3_MD_层级全景图.md`
- 更新 `UFC_API_REFERENCE.md`

---

### 4.2 添加新算法

#### 步骤 1: 确定算法位置

- **数值算法** → `L2_NM/`
- **物理算法** → `L4_PH/`
- **求解算法** → `L5_RT/`

#### 步骤 2: 创建算法模块

**示例**: 添加新的线性求解器

**文件**: `L2_NM/Solver/NM_GMRES_Core.f90`

```fortran
MODULE NM_GMRES_Core
  USE IF_Prec, ONLY: wp, i4, i8
  USE IF_Err_API, ONLY: ErrorStatusType
  USE NM_Matrix, ONLY: NM_CSRMatrix_Type
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: NM_GMRES_Solve
  
  SUBROUTINE NM_GMRES_Solve(A, b, x, max_iter, tolerance, status)
    TYPE(NM_CSRMatrix_Type), INTENT(IN) :: A
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(IN) :: max_iter
    REAL(wp), INTENT(IN) :: tolerance
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    
    ! GMRES 算法实现
  END SUBROUTINE
  
END MODULE NM_GMRES_Core
```

#### 步骤 3: 添加单元测试

**文件**: `tests/L2_NM/test_gmres.f90`

```fortran
PROGRAM test_gmres
  USE NM_GMRES_Core, ONLY: NM_GMRES_Solve
  USE IF_Prec, ONLY: wp
  
  ! 测试代码
END PROGRAM
```

---

### 4.3 添加新单元类型

#### 步骤 1: 创建单元模块

**文件**: `L4_PH/Elem/PH_Elem_C3D20_Core.f90`

```fortran
MODULE PH_Elem_C3D20_Core
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType
  USE MD_Material, ONLY: MD_Material_Desc_Type
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_Elem_C3D20_ComputeStiffness
  
  SUBROUTINE PH_Elem_C3D20_ComputeStiffness(coords, material, Ke, status)
    REAL(wp), INTENT(IN) :: coords(20, 3)  ! 20节点坐标
    TYPE(MD_Material_Desc_Type), INTENT(IN) :: material
    REAL(wp), INTENT(OUT) :: Ke(60, 60)    ! 60 DOF
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    
    ! C3D20 单元刚度矩阵计算
  END SUBROUTINE
  
END MODULE PH_Elem_C3D20_Core
```

#### 步骤 2: 注册到单元工厂

**更新**: `L4_PH/Elem/PH_Elem_Factory.f90`

```fortran
SELECT CASE(elem_type)
CASE(ELEM_TYPE_C3D8)
  CALL PH_Elem_C3D8_ComputeStiffness(...)
CASE(ELEM_TYPE_C3D20)
  CALL PH_Elem_C3D20_ComputeStiffness(...)  ! 新增
CASE DEFAULT
  CALL UFC_Error_Raise(status, PH_ERR_UNKNOWN_ELEMENT, ...)
END SELECT
```

---

## 5. 调试与测试

### 5.1 编译选项

**Debug 模式**:

```bash
cmake -DCMAKE_BUILD_TYPE=Debug ..
make
```

**Release 模式**:

```bash
cmake -DCMAKE_BUILD_TYPE=Release ..
make
```

### 5.2 调试工具

**GDB 调试**:

```bash
gdb ./bin/ufc_solver
(gdb) break MD_Material_Desc_Init
(gdb) run examples/test.inp
(gdb) print material%name
```

**Valgrind 内存检查**:

```bash
valgrind --leak-check=full ./bin/ufc_solver examples/test.inp
```

### 5.3 日志调试

**启用调试日志**:

```fortran
USE IF_Log, ONLY: Logger_Type, LOG_LEVEL_DEBUG

TYPE(Logger_Type) :: logger
logger%min_level = LOG_LEVEL_DEBUG

CALL logger%Log(LOG_LEVEL_DEBUG, '调试信息', 'MyModule', 123)
```

### 5.4 单元测试

**运行单元测试**:

```bash
make test
# 或
ctest
```

**编写单元测试**（使用 pFUnit）:

```fortran
@test
subroutine test_material_init()
  use MD_Material, only: MD_Material_Desc_Type
  use IF_Err_API, only: ErrorStatusType
  
  type(MD_Material_Desc_Type) :: material
  type(ErrorStatusType) :: status
  
  call material%Init('Steel', MAT_TYPE_ELASTIC, &
                    200.0e9_wp, 0.3_wp, 7850.0_wp, status)
  
  @assertTrue(material%initialized)
  @assertEqual('Steel', material%name)
end subroutine
```

---

## 6. 代码审查流程

### 6.1 提交前检查

**运行代码检查工具**:

```bash
# 命名规范检查
python tools/check_naming_standard.py

# 层级依赖检查
python tools/verify_layer_dependency.py

# TYPE 分类检查
python tools/verify_type_categories.py

# 注释质量检查
python tools/check_comments.py
```

### 6.2 代码审查清单

**架构合规性**:

- 遵循六层架构依赖规则
- 使用正确的命名规范（四段式）
- TYPE 分类正确（Desc/State/Algo/Ctx）
- 错误处理使用 `ErrorStatusType`

**代码质量**:

- 无编译警告
- 单元测试通过
- 代码注释完整（英文）
- 无内存泄漏（Valgrind 检查）

**文档更新**:

- 更新 API 参考手册
- 更新架构设计文档（如需要）
- 更新示例代码（如需要）

### 6.3 Pull Request 流程

1. **创建分支**: `git checkout -b feature/new-feature`
2. **提交代码**: `git commit -m "Add new feature"`
3. **推送分支**: `git push origin feature/new-feature`
4. **创建 PR**: 在 GitHub/GitLab 创建 Pull Request
5. **代码审查**: 等待审查意见
6. **修改并合并**: 根据审查意见修改后合并

---

## 7. 常见问题 FAQ

### Q1: 编译错误 "Module not found"

**问题**: `Error: Can't open module file 'IF_Prec.mod'`

**解决方案**:

1. 检查模块路径是否正确
2. 确保 `IF_Prec.f90` 已编译
3. 检查 `USE` 语句是否正确

```fortran
! 正确
USE IF_Prec, ONLY: wp, i4, i8

! 错误
USE IF_Precision  ! 模块名错误
```

---

### Q2: 循环依赖错误

**问题**: `Error: Circular dependency detected`

**解决方案**:

- 检查模块间的 `USE` 关系
- 使用前向声明或接口模块
- 重构代码，消除循环依赖

**示例**:

```fortran
! 错误：循环依赖
! Module A USE Module B
! Module B USE Module A

! 正确：使用接口模块
! Module A_Interface（仅类型定义）
! Module A USE A_Interface
! Module B USE A_Interface
```

---

### Q3: 精度不一致错误

**问题**: 数值结果不正确，可能是精度问题

**解决方案**:

- 确保所有模块使用 `USE IF_Prec`
- 不要直接使用 `REAL(8)` 或 `REAL*8`
- 统一使用 `REAL(wp)`

```fortran
! 错误
REAL(8) :: stress

! 正确
USE IF_Prec, ONLY: wp
REAL(wp) :: stress
```

---

### Q4: 内存泄漏

**问题**: Valgrind 报告内存泄漏

**解决方案**:

1. 检查所有 `ALLOCATE` 是否有对应的 `DEALLOCATE`
2. 使用内存池管理器（`IF_Mem_PoolMgr`）
3. 确保 `Finalize` 过程正确释放内存

```fortran
! 正确示例
SUBROUTINE MySubroutine()
  REAL(wp), ALLOCATABLE :: arr(:)
  
  ALLOCATE(arr(100))
  ! ... 使用 arr ...
  DEALLOCATE(arr)  ! 必须释放
END SUBROUTINE
```

---

### Q5: 跨层访问错误

**问题**: L4 层直接访问 L3 层模块

**解决方案**:

- 使用 Bridge 模块进行跨层访问
- 遵循单向依赖规则（L4 → L3 → L2 → L1）

```fortran
! 错误：L4 直接 USE L3
USE MD_Material  ! 违反依赖规则

! 正确：通过 Bridge
USE PH_MatLib_Brg  ! L4→L3 Bridge
```

---

## 8. 贡献指南

### 8.1 贡献流程

1. **Fork 代码库**
2. **创建功能分支**: `git checkout -b feature/amazing-feature`
3. **提交更改**: `git commit -m "Add amazing feature"`
4. **推送分支**: `git push origin feature/amazing-feature`
5. **创建 Pull Request**

### 8.2 代码规范

**必须遵循**:

- UFC 命名规范（四段式）
- 六层架构依赖规则
- 错误处理规范（`ErrorStatusType`）
- 注释规范（英文，禁止中文）

**参考文档**:

- `UFC_NAMING_STANDARD.md`
- `UFC_架构设计总纲_六层四类四链三步三级两图一体.md`

### 8.3 测试要求

**必须包含**:

- 单元测试（覆盖率 > 80%）
- 集成测试（如适用）
- 性能测试（如适用）

### 8.4 文档要求

**必须更新**:

- API 参考手册（如添加新接口）
- 架构设计文档（如添加新域级）
- 示例代码（如添加新功能）

---

## 附录

### A.1 快速参考

**常用命令**:

```bash
# 编译
make

# 测试
make test

# 清理
make clean

# 代码检查
python tools/check_naming_standard.py
```

### A.2 相关文档

- `UFC_API_REFERENCE.md` - API 参考手册
- `UFC_TEST_STRATEGY.md` - 测试策略
- `UFC_架构设计总纲_六层四类四链三步三级两图一体.md` - 架构总纲

### A.3 联系方式

- **问题反馈**: GitHub Issues
- **讨论**: GitHub Discussions
- **邮件**: [待填]

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队