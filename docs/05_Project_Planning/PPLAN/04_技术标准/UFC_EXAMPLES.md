# UFC 示例代码库文档

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: UFC 示例代码库  
> **上级参考**: UFC_DEVELOPER_GUIDE.md（开发者指南）

---

## 📋 文档说明

本文档提供 UFC 项目示例代码库的完整参考，包括：

- 完整示例列表
- 每个示例的说明
- 如何运行示例
- 示例代码位置
- 示例分类（基础/中级/高级）

---

## 目录

1. [基础示例](#1-基础示例)
2. [中级示例](#2-中级示例)
3. [高级示例](#3-高级示例)
4. [示例运行指南](#4-示例运行指南)
5. [示例贡献指南](#5-示例贡献指南)

---

## 1. 基础示例

### 1.1 Hello World

**文件**: `examples/basic/hello_world.f90`  
**难度**: ⭐ 基础  
**说明**: 最简单的 UFC 程序

**代码**:

```fortran
PROGRAM hello_world
  USE IF_Prec, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  
  IMPLICIT NONE
  
  TYPE(ErrorStatusType) :: status
  
  WRITE(*,'(A)') 'Hello, UFC!'
  
  IF (status%status_code == STATUS_OK) THEN
    WRITE(*,'(A)') 'Program completed successfully'
  END IF
END PROGRAM
```

**运行方法**:

```bash
gfortran -o hello_world examples/basic/hello_world.f90
./hello_world
```

---

### 1.2 材料定义示例

**文件**: `examples/basic/material_definition.f90`  
**难度**: ⭐ 基础  
**说明**: 定义材料属性

**代码**:

```fortran
PROGRAM material_definition
  USE MD_Material, ONLY: MD_Material_Desc_Type, MAT_TYPE_ELASTIC
  USE IF_Prec, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  
  TYPE(MD_Material_Desc_Type) :: material
  TYPE(ErrorStatusType) :: status
  
  ! Initialize material (Steel: E=200GPa, nu=0.3)
  CALL material%Init('Steel', MAT_TYPE_ELASTIC, &
                    200.0e9_wp, 0.3_wp, 7850.0_wp, status)
  
  IF (status%status_code == STATUS_OK) THEN
    WRITE(*,'(A,F12.2,A)') 'Material initialized: E = ', &
      material%young_modulus, ' Pa'
  END IF
END PROGRAM
```

---

### 1.3 内存分配示例

**文件**: `examples/basic/memory_allocation.f90`  
**难度**: ⭐ 基础  
**说明**: 使用内存池管理器分配内存

**代码**:

```fortran
PROGRAM memory_allocation
  USE IF_Mem_PoolMgr, ONLY: IF_Mem_PoolMgr_Type, DATA_TYPE_DP
  USE IF_Prec, ONLY: i8
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  
  TYPE(IF_Mem_PoolMgr_Type) :: pool_mgr
  TYPE(ErrorStatusType) :: status
  TYPE(C_PTR) :: ptr
  REAL(wp), POINTER :: arr(:)
  
  ! Initialize memory pool manager (1GB)
  CALL pool_mgr%Init(1_i8*1024_i8*1024_i8*1024_i8, status)
  
  ! Allocate array via ABAQUS path
  ptr = pool_mgr%AllocByPath( &
      "mdb.models['Model-1'].parts['Part-1'].mesh.nodes", &
      "coordinates", [1000, 3], DATA_TYPE_DP, status)
  
  IF (C_ASSOCIATED(ptr)) THEN
    CALL C_F_POINTER(ptr, arr, [1000, 3])
    WRITE(*,'(A)') 'Memory allocated successfully'
  END IF
END PROGRAM
```

---

## 2. 中级示例

### 2.1 单元刚度矩阵计算

**文件**: `examples/intermediate/element_stiffness.f90`  
**难度**: ⭐⭐ 中级  
**说明**: 计算 C3D8 单元刚度矩阵

**代码**:

```fortran
PROGRAM element_stiffness
  USE MD_Material, ONLY: MD_Material_Desc_Type, MAT_TYPE_ELASTIC
  USE PH_Elem, ONLY: PH_Elem_ComputeStiffness, ELEM_TYPE_C3D8
  USE IF_Prec, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  
  TYPE(MD_Material_Desc_Type) :: material
  TYPE(ErrorStatusType) :: status
  REAL(wp) :: coords(8, 3), Ke(24, 24)
  
  ! Initialize material
  CALL material%Init('Steel', MAT_TYPE_ELASTIC, &
                    200.0e9_wp, 0.3_wp, 7850.0_wp, status)
  
  ! Define unit cube coordinates
  coords = reshape([ &
    0.0_wp, 0.0_wp, 0.0_wp, &
    1.0_wp, 0.0_wp, 0.0_wp, &
    1.0_wp, 1.0_wp, 0.0_wp, &
    0.0_wp, 1.0_wp, 0.0_wp, &
    0.0_wp, 0.0_wp, 1.0_wp, &
    1.0_wp, 0.0_wp, 1.0_wp, &
    1.0_wp, 1.0_wp, 1.0_wp, &
    0.0_wp, 1.0_wp, 1.0_wp &
  ], [8, 3])
  
  ! Compute element stiffness matrix
  CALL PH_Elem_ComputeStiffness(ELEM_TYPE_C3D8, coords, material, Ke, status)
  
  IF (status%status_code == STATUS_OK) THEN
    WRITE(*,'(A)') 'Element stiffness matrix computed successfully'
    WRITE(*,'(A,E12.4)') 'Max value: ', MAXVAL(ABS(Ke))
  END IF
END PROGRAM
```

---

### 2.2 材料本构评估

**文件**: `examples/intermediate/material_evaluation.f90`  
**难度**: ⭐⭐ 中级  
**说明**: 评估材料本构关系（应力-应变）

**代码**:

```fortran
PROGRAM material_evaluation
  USE MD_Material, ONLY: MD_Material_Desc_Type, MAT_TYPE_ELASTIC
  USE PH_Mat, ONLY: PH_Mat_Evaluate
  USE IF_Prec, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  
  TYPE(MD_Material_Desc_Type) :: material
  TYPE(PH_Mat_State_Type) :: state
  TYPE(ErrorStatusType) :: status
  REAL(wp) :: strain(6), stress(6), ddsdde(6,6)
  
  ! Initialize material
  CALL material%Init('Steel', MAT_TYPE_ELASTIC, &
                    200.0e9_wp, 0.3_wp, 7850.0_wp, status)
  
  ! Uniaxial strain
  strain = [1.0e-3_wp, 0.0_wp, 0.0_wp, 0.0_wp, 0.0_wp, 0.0_wp]
  
  ! Evaluate material
  CALL PH_Mat_Evaluate(material, strain, stress, ddsdde, state, status)
  
  IF (status%status_code == STATUS_OK) THEN
    WRITE(*,'(A,F12.2,A)') 'Stress: ', stress(1), ' Pa'
    WRITE(*,'(A,F12.2,A)') 'Expected: ', 200.0e9_wp * 1.0e-3_wp, ' Pa'
  END IF
END PROGRAM
```

---

### 2.3 线性求解器示例

**文件**: `examples/intermediate/linear_solver.f90`  
**难度**: ⭐⭐ 中级  
**说明**: 求解线性方程组

**代码**:

```fortran
PROGRAM linear_solver
  USE NM_LinearSolver, ONLY: NM_LinearSolver_Type, SOLVER_LU
  USE NM_Matrix, ONLY: NM_CSRMatrix_Type
  USE IF_Prec, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  
  TYPE(NM_LinearSolver_Type) :: solver
  TYPE(NM_CSRMatrix_Type) :: A
  REAL(wp) :: b(100), x(100)
  TYPE(ErrorStatusType) :: status
  
  ! Initialize solver
  CALL solver%Init(SOLVER_LU, status)
  
  ! Setup matrix A and vector b
  ! ... (省略矩阵设置代码) ...
  
  ! Solve A·x = b
  CALL solver%Solve(A, b, x, status)
  
  IF (status%status_code == STATUS_OK) THEN
    WRITE(*,'(A)') 'Linear system solved successfully'
    WRITE(*,'(A,F12.6)') 'Solution norm: ', NORM2(x)
  END IF
END PROGRAM
```

---

## 3. 高级示例

### 3.1 完整求解流程

**文件**: `examples/advanced/full_solve.f90`  
**难度**: ⭐⭐⭐ 高级  
**说明**: 完整的有限元求解流程

**代码**:

```fortran
PROGRAM full_solve
  USE AP_Input, ONLY: AP_ParseINP
  USE RT_Solver, ONLY: RT_Solver_Type
  USE AP_Output, ONLY: AP_Output_WriteODB
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  
  TYPE(RT_Solver_Type) :: solver
  TYPE(ErrorStatusType) :: status
  CHARACTER(len=256) :: inp_file, odb_file
  
  ! Step 1: Parse input file
  inp_file = 'examples/data/cantilever_beam.inp'
  CALL AP_ParseINP(inp_file, status)
  IF (status%status_code /= STATUS_OK) THEN
    WRITE(*,'(A)') 'ERROR: Input parsing failed'
    STOP 1
  END IF
  
  ! Step 2: Initialize solver
  CALL solver%Init(status)
  IF (status%status_code /= STATUS_OK) THEN
    WRITE(*,'(A)') 'ERROR: Solver initialization failed'
    STOP 1
  END IF
  
  ! Step 3: Solve
  CALL solver%SolveStep(step_desc, model_ctx, status)
  IF (status%status_code /= STATUS_OK) THEN
    WRITE(*,'(A)') 'ERROR: Solve failed'
    STOP 1
  END IF
  
  ! Step 4: Write output
  odb_file = 'output/cantilever_beam.odb'
  CALL AP_Output_WriteODB(odb_file, results, status)
  
  WRITE(*,'(A)') 'Solve completed successfully'
END PROGRAM
```

---

### 3.2 并行计算示例

**文件**: `examples/advanced/parallel_compute.f90`  
**难度**: ⭐⭐⭐ 高级  
**说明**: OpenMP 并行单元计算

**代码**:

```fortran
PROGRAM parallel_compute
  USE OMP_LIB
  USE PH_Elem, ONLY: PH_Elem_ComputeStiffness
  USE IF_Prec, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  
  INTEGER(i4) :: n_elements = 10000
  INTEGER(i4) :: i_elem
  TYPE(ErrorStatusType) :: status
  
  !$OMP PARALLEL DO PRIVATE(i_elem, status)
  DO i_elem = 1, n_elements
    ! Compute element stiffness
    CALL PH_Elem_ComputeStiffness(elem_type, coords(i_elem), &
                                  material, Ke(i_elem), status)
  END DO
  !$OMP END PARALLEL DO
  
  WRITE(*,'(A,I0,A)') 'Computed ', n_elements, ' elements in parallel'
END PROGRAM
```

---

## 4. 示例运行指南

### 4.1 编译示例

**单个示例**:

```bash
cd examples/basic
gfortran -o hello_world hello_world.f90 -I../../ufc_core/L1_IF
./hello_world
```

**所有示例**:

```bash
cd examples
make all
```

### 4.2 运行示例

**基础示例**:

```bash
./examples/basic/hello_world
./examples/basic/material_definition
./examples/basic/memory_allocation
```

**中级示例**:

```bash
./examples/intermediate/element_stiffness
./examples/intermediate/material_evaluation
./examples/intermediate/linear_solver
```

**高级示例**:

```bash
./examples/advanced/full_solve examples/data/cantilever_beam.inp
./examples/advanced/parallel_compute
```

---

## 5. 示例贡献指南

### 5.1 示例要求

**必须包含**:

- 清晰的注释说明
- 错误处理（使用 `ErrorStatusType`）
- 使用 UFC 命名规范
- 可独立编译运行

### 5.2 示例提交流程

1. 创建示例文件（遵循命名规范）
2. 添加注释和文档
3. 测试示例可运行
4. 提交 Pull Request

---

## 附录

### A.1 示例列表


| 示例          | 文件                                     | 难度  | 说明        |
| ----------- | -------------------------------------- | --- | --------- |
| Hello World | `basic/hello_world.f90`                | ⭐   | 最简单的程序    |
| 材料定义        | `basic/material_definition.f90`        | ⭐   | 定义材料属性    |
| 内存分配        | `basic/memory_allocation.f90`          | ⭐   | 使用内存池     |
| 单元刚度        | `intermediate/element_stiffness.f90`   | ⭐⭐  | 计算单元刚度    |
| 材料评估        | `intermediate/material_evaluation.f90` | ⭐⭐  | 评估材料本构    |
| 线性求解        | `intermediate/linear_solver.f90`       | ⭐⭐  | 求解线性方程组   |
| 完整求解        | `advanced/full_solve.f90`              | ⭐⭐⭐ | 完整求解流程    |
| 并行计算        | `advanced/parallel_compute.f90`        | ⭐⭐⭐ | OpenMP 并行 |


### A.2 相关文档

- `UFC_DEVELOPER_GUIDE.md` - 开发者指南
- `UFC_API_REFERENCE.md` - API 参考手册
- `UFC_TEST_STRATEGY.md` - 测试策略

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队