# UFC 测试用例模板

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: UFC 测试用例编写规范  
> **上级参考**: UFC_TEST_STRATEGY.md（测试策略）

---

## 📋 文档说明

本文档提供 UFC 项目各类测试用例的标准模板，包括：

- 单元测试用例模板
- 集成测试用例模板
- 数值验证用例模板
- 性能测试用例模板

---

## 目录

1. [单元测试用例模板](#1-单元测试用例模板)
2. [集成测试用例模板](#2-集成测试用例模板)
3. [数值验证用例模板](#3-数值验证用例模板)
4. [性能测试用例模板](#4-性能测试用例模板)
5. [测试用例检查清单](#5-测试用例检查清单)

---

## 1. 单元测试用例模板

### 1.1 基础模板

**文件命名**: `test_<Layer>_<Domain>_<Function>.f90`

```fortran
!===============================================================================
! Test: <Layer>_<Domain>_<Function>
! Purpose: <测试目的描述>
!===============================================================================
PROGRAM test_<Layer>_<Domain>_<Function>
  USE <Layer>_<Domain>_Core, ONLY: <Type>_Type, <Function>_Init
  USE IF_Prec, ONLY: wp, i4, i8
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  
  IMPLICIT NONE
  
  TYPE(<Type>_Type) :: obj
  TYPE(ErrorStatusType) :: status
  
  ! Test initialization
  CALL <Function>_Init(obj, <params>, status)
  
  ! Assertions
  IF (.NOT. obj%initialized) THEN
    WRITE(*,'(A)') 'FAIL: Object not initialized'
    STOP 1
  END IF
  
  IF (status%status_code /= STATUS_OK) THEN
    WRITE(*,'(A)') 'FAIL: '//TRIM(status%error_message)
    STOP 1
  END IF
  
  WRITE(*,'(A)') 'PASS: Test passed'
END PROGRAM
```

### 1.2 pFUnit 模板

```fortran
!===============================================================================
! Test: <Layer>_<Domain>_<Function>
! Purpose: <测试目的描述>
!===============================================================================
MODULE test_<Layer>_<Domain>_<Function>
  USE <Layer>_<Domain>_Core, ONLY: <Type>_Type, <Function>_Init
  USE IF_Prec, ONLY: wp, i4, i8
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  
  IMPLICIT NONE
  
CONTAINS
  
  @test
  SUBROUTINE test_init()
    TYPE(<Type>_Type) :: obj
    TYPE(ErrorStatusType) :: status
    
    CALL <Function>_Init(obj, <params>, status)
    
    @assertTrue(obj%initialized)
    @assertEqual(STATUS_OK, status%status_code)
  END SUBROUTINE
  
  @test
  SUBROUTINE test_functionality()
    TYPE(<Type>_Type) :: obj
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: result, expected
    
    CALL <Function>_Init(obj, <params>, status)
    
    ! Test functionality
    result = obj%Compute(<input>)
    expected = <expected_value>
    
    @assertEqual(expected, result, tolerance=1.0e-6_wp)
  END SUBROUTINE
  
END MODULE
```

### 1.3 完整示例

**文件**: `tests/L1_IF/test_IF_Mem_PoolMgr_Init.f90`

```fortran
!===============================================================================
! Test: IF_Mem_PoolMgr_Init
! Purpose: Test memory pool manager initialization
!===============================================================================
MODULE test_IF_Mem_PoolMgr_Init
  USE IF_Mem_PoolMgr, ONLY: IF_Mem_PoolMgr_Type
  USE IF_Prec, ONLY: i8
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  
  IMPLICIT NONE
  
CONTAINS
  
  @test
  SUBROUTINE test_init_success()
    TYPE(IF_Mem_PoolMgr_Type) :: pool_mgr
    TYPE(ErrorStatusType) :: status
    
    CALL pool_mgr%Init(16_i8*1024_i8*1024_i8*1024_i8, status)
    
    @assertTrue(pool_mgr%initialized)
    @assertEqual(STATUS_OK, status%status_code)
    @assertEqual(16_i8*1024_i8*1024_i8*1024_i8, pool_mgr%totalMemory)
  END SUBROUTINE
  
  @test
  SUBROUTINE test_init_zero_memory()
    TYPE(IF_Mem_PoolMgr_Type) :: pool_mgr
    TYPE(ErrorStatusType) :: status
    
    CALL pool_mgr%Init(0_i8, status)
    
    @assertFalse(status%status_code == STATUS_OK)
  END SUBROUTINE
  
END MODULE
```

---

## 2. 集成测试用例模板

### 2.1 跨层集成测试模板

**文件命名**: `test_<Layer1>_<Layer2>_integration.f90`

```fortran
!===============================================================================
! Test: <Layer1>_<Layer2>_Integration
! Purpose: Test integration between <Layer1> and <Layer2>
!===============================================================================
PROGRAM test_<Layer1>_<Layer2>_integration
  USE <Layer1>_<Domain1>_Core, ONLY: <Type1>_Type
  USE <Layer2>_<Domain2>_Core, ONLY: <Type2>_Type
  USE IF_Prec, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  
  IMPLICIT NONE
  
  TYPE(<Type1>_Type) :: obj1
  TYPE(<Type2>_Type) :: obj2
  TYPE(ErrorStatusType) :: status
  
  ! Step 1: Initialize Layer1 object
  CALL obj1%Init(<params1>, status)
  IF (status%status_code /= STATUS_OK) THEN
    WRITE(*,'(A)') 'FAIL: Layer1 initialization failed'
    STOP 1
  END IF
  
  ! Step 2: Pass data to Layer2
  CALL obj2%Process(obj1, status)
  IF (status%status_code /= STATUS_OK) THEN
    WRITE(*,'(A)') 'FAIL: Layer2 processing failed'
    STOP 1
  END IF
  
  ! Step 3: Verify results
  IF (.NOT. VerifyResults(obj2)) THEN
    WRITE(*,'(A)') 'FAIL: Results verification failed'
    STOP 1
  END IF
  
  WRITE(*,'(A)') 'PASS: Integration test passed'
  
CONTAINS
  
  FUNCTION VerifyResults(obj) RESULT(isValid)
    TYPE(<Type2>_Type), INTENT(IN) :: obj
    LOGICAL :: isValid
    
    ! Verification logic
    isValid = .TRUE.
  END FUNCTION
  
END PROGRAM
```

### 2.2 完整示例

**文件**: `tests/Integration/test_L3_MD_L4_PH_integration.f90`

```fortran
!===============================================================================
! Test: L3_MD_L4_PH_Integration
! Purpose: Test material definition (L3_MD) → material evaluation (L4_PH)
!===============================================================================
PROGRAM test_L3_MD_L4_PH_integration
  USE MD_Material, ONLY: MD_Material_Desc_Type, MAT_TYPE_ELASTIC
  USE PH_Mat, ONLY: PH_Mat_Evaluate
  USE IF_Prec, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  
  IMPLICIT NONE
  
  TYPE(MD_Material_Desc_Type) :: material
  TYPE(PH_Mat_State_Type) :: state
  TYPE(ErrorStatusType) :: status
  REAL(wp) :: strain(6), stress(6), ddsdde(6,6)
  REAL(wp) :: E, nu, expected_stress(6)
  
  ! Step 1: Initialize material (L3_MD)
  E = 200.0e9_wp
  nu = 0.3_wp
  CALL material%Init('Steel', MAT_TYPE_ELASTIC, E, nu, 7850.0_wp, status)
  IF (status%status_code /= STATUS_OK) THEN
    WRITE(*,'(A)') 'FAIL: Material initialization failed'
    STOP 1
  END IF
  
  ! Step 2: Evaluate material (L4_PH)
  strain = [1.0e-3_wp, 0.0_wp, 0.0_wp, 0.0_wp, 0.0_wp, 0.0_wp]
  CALL PH_Mat_Evaluate(material, strain, stress, ddsdde, state, status)
  IF (status%status_code /= STATUS_OK) THEN
    WRITE(*,'(A)') 'FAIL: Material evaluation failed'
    STOP 1
  END IF
  
  ! Step 3: Verify results
  expected_stress(1) = E * strain(1)  ! σ₁₁ = E·ε₁₁
  IF (ABS(stress(1) - expected_stress(1)) > 1.0e6_wp) THEN
    WRITE(*,'(A,F12.2,A,F12.2)') 'FAIL: Stress mismatch. Expected: ', &
      expected_stress(1), ', Got: ', stress(1)
    STOP 1
  END IF
  
  WRITE(*,'(A)') 'PASS: L3_MD → L4_PH integration test passed'
END PROGRAM
```

---

## 3. 数值验证用例模板

### 3.1 Patch Test 模板

```fortran
!===============================================================================
! Test: Patch Test
! Purpose: Verify element can reproduce constant strain field exactly
!===============================================================================
PROGRAM test_patch_test
  USE PH_Elem, ONLY: PH_Elem_ComputeStiffness
  USE MD_Material, ONLY: MD_Material_Desc_Type, MAT_TYPE_ELASTIC
  USE IF_Prec, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  
  IMPLICIT NONE
  
  TYPE(MD_Material_Desc_Type) :: material
  TYPE(ErrorStatusType) :: status
  REAL(wp) :: coords(8, 3), Ke(24, 24)
  REAL(wp) :: u(24), f(24), f_expected(24)
  REAL(wp) :: error, tolerance = 1.0e-10_wp
  
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
  
  ! Compute stiffness matrix
  CALL PH_Elem_ComputeStiffness(ELEM_TYPE_C3D8, coords, material, Ke, status)
  
  ! Apply constant strain field: u = [x, y, z, ...]
  u(1:8) = coords(:,1)   ! x-displacements
  u(9:16) = coords(:,2)  ! y-displacements
  u(17:24) = coords(:,3) ! z-displacements
  
  ! Compute force: f = K·u
  f = MATMUL(Ke, u)
  
  ! Expected force (for constant strain, should be zero for interior nodes)
  f_expected = 0.0_wp
  
  ! Check error
  error = MAXVAL(ABS(f - f_expected))
  
  IF (error > tolerance) THEN
    WRITE(*,'(A,E12.4,A,E12.4)') 'FAIL: Patch test failed. Error: ', &
      error, ', Tolerance: ', tolerance
    STOP 1
  END IF
  
  WRITE(*,'(A)') 'PASS: Patch test passed'
END PROGRAM
```

### 3.2 收敛性测试模板

```fortran
!===============================================================================
! Test: Convergence Test
! Purpose: Verify solution converges with mesh refinement
!===============================================================================
PROGRAM test_convergence
  USE RT_Solver, ONLY: RT_Solver_Type
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  
  TYPE(RT_Solver_Type) :: solver
  TYPE(ErrorStatusType) :: status
  INTEGER(i4) :: n_refinements = 4
  REAL(wp), ALLOCATABLE :: errors(:), h(:)
  REAL(wp) :: convergence_rate, expected_rate = 2.0_wp
  REAL(wp) :: tolerance = 0.2_wp
  
  ALLOCATE(errors(n_refinements), h(n_refinements))
  
  ! Refine mesh and compute error
  DO i = 1, n_refinements
    h(i) = 1.0_wp / (2**i)
    CALL solve_problem(solver, h(i), errors(i), status)
    IF (status%status_code /= STATUS_OK) THEN
      WRITE(*,'(A)') 'FAIL: Solve failed'
      STOP 1
    END IF
  END DO
  
  ! Compute convergence rate: error ∝ h^p
  convergence_rate = LOG(errors(1)/errors(n_refinements)) / &
                     LOG(h(1)/h(n_refinements))
  
  ! Verify convergence rate
  IF (ABS(convergence_rate - expected_rate) > tolerance) THEN
    WRITE(*,'(A,F6.2,A,F6.2)') 'FAIL: Convergence rate = ', &
      convergence_rate, ', expected ≈ ', expected_rate
    STOP 1
  END IF
  
  WRITE(*,'(A,F6.2)') 'PASS: Convergence test passed, rate = ', convergence_rate
  
CONTAINS
  
  SUBROUTINE solve_problem(solver, h, error, status)
    TYPE(RT_Solver_Type), INTENT(INOUT) :: solver
    REAL(wp), INTENT(IN) :: h
    REAL(wp), INTENT(OUT) :: error
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    
    ! Solve problem with mesh size h
    ! Compute error against reference solution
    error = 0.0_wp  ! Placeholder
  END SUBROUTINE
  
END PROGRAM
```

---

## 4. 性能测试用例模板

### 4.1 基准测试模板

```fortran
!===============================================================================
! Test: Performance Benchmark
! Purpose: Measure performance of <function>
!===============================================================================
PROGRAM test_performance_<function>
  USE <Module>, ONLY: <Function>
  USE IF_Prec, ONLY: wp, i8
  USE IF_Err_API, ONLY: ErrorStatusType
  
  IMPLICIT NONE
  
  INTEGER(i8) :: start_time, end_time, elapsed_time
  INTEGER(i4) :: n_iterations = 10000
  REAL(wp) :: avg_time, target_time = 1000.0_wp  ! Target: < 1000 ns
  
  ! Benchmark
  CALL SYSTEM_CLOCK(start_time)
  
  DO i = 1, n_iterations
    CALL <Function>(<params>, status)
  END DO
  
  CALL SYSTEM_CLOCK(end_time)
  elapsed_time = end_time - start_time
  avg_time = REAL(elapsed_time, wp) / REAL(n_iterations, wp)
  
  WRITE(*,'(A,F10.2,A)') 'Average time per call: ', avg_time, ' ns'
  
  ! Check performance target
  IF (avg_time > target_time) THEN
    WRITE(*,'(A,F10.2,A,F10.2)') 'WARNING: Performance below target. ', &
      avg_time, ' ns > ', target_time, ' ns'
  ELSE
    WRITE(*,'(A)') 'PASS: Performance target met'
  END IF
  
END PROGRAM
```

### 4.2 并行效率测试模板

```fortran
!===============================================================================
! Test: Parallel Efficiency
! Purpose: Measure parallel efficiency of <function>
!===============================================================================
PROGRAM test_parallel_efficiency
  USE OMP_LIB
  USE IF_Prec, ONLY: wp, i4
  
  IMPLICIT NONE
  
  INTEGER(i4) :: n_threads, max_threads = 8
  REAL(wp), ALLOCATABLE :: elapsed_time(:)
  REAL(wp) :: speedup, efficiency
  REAL(wp) :: target_efficiency = 0.7_wp  ! Target: > 70%
  
  ALLOCATE(elapsed_time(max_threads))
  
  ! Test with different thread counts
  DO n_threads = 1, max_threads
    CALL OMP_SET_NUM_THREADS(n_threads)
    
    CALL SYSTEM_CLOCK(start_time)
    !$OMP PARALLEL DO
    DO i = 1, n_elements
      CALL compute_element(i)
    END DO
    !$OMP END PARALLEL DO
    CALL SYSTEM_CLOCK(end_time)
    
    elapsed_time(n_threads) = REAL(end_time - start_time, wp)
  END DO
  
  ! Compute speedup and efficiency
  speedup = elapsed_time(1) / elapsed_time(max_threads)
  efficiency = speedup / max_threads
  
  WRITE(*,'(A,F6.2)') 'Speedup: ', speedup
  WRITE(*,'(A,F6.2)') 'Efficiency: ', efficiency
  
  ! Check efficiency target
  IF (efficiency < target_efficiency) THEN
    WRITE(*,'(A,F6.2,A,F6.2)') 'WARNING: Efficiency below target. ', &
      efficiency, ' < ', target_efficiency
  ELSE
    WRITE(*,'(A)') 'PASS: Parallel efficiency target met'
  END IF
  
END PROGRAM
```

---

## 5. 测试用例检查清单

### 5.1 测试用例质量检查

**必须包含**:

- 清晰的测试名称
- 测试目的说明
- 前置条件（Setup）
- 测试步骤（Steps）
- 预期结果（Expected Results）
- 验收标准（Acceptance Criteria）
- 清理代码（Teardown）

### 5.2 测试用例命名检查

**命名规范**:

- 文件命名: `test_<Layer>_<Domain>_<Function>.f90`
- 程序命名: `test_<Layer>_<Domain>_<Function>`
- 测试子程序命名: `test_<specific_test>`

### 5.3 测试用例内容检查

**代码质量**:

- 使用 `IMPLICIT NONE`
- 使用 `ErrorStatusType` 进行错误处理
- 使用 `IF_Prec` 定义精度类型
- 包含适当的断言
- 包含清理代码（Finalize）

**文档质量**:

- 注释说明测试目的
- 注释说明测试步骤
- 注释说明验收标准
- 注释使用英文（禁止中文）

### 5.4 测试用例执行检查

**可执行性**:

- 可以独立编译
- 可以独立运行
- 不依赖外部文件（或文件路径正确）
- 输出清晰的 PASS/FAIL 信息

---

## 附录

### A.1 测试用例模板速查


| 测试类型     | 模板文件                            | 使用场景      |
| -------- | ------------------------------- | --------- |
| **单元测试** | `test_unit_template.f90`        | 测试单个函数/模块 |
| **集成测试** | `test_integration_template.f90` | 测试模块间交互   |
| **数值验证** | `test_numerical_template.f90`   | 验证数值精度    |
| **性能测试** | `test_performance_template.f90` | 测量性能指标    |


### A.2 相关文档

- `UFC_TEST_STRATEGY.md` - 测试策略
- `UFC_BENCHMARK_SUITE.md` - 标准测试问题库
- `UFC_API_REFERENCE.md` - API 参考手册

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队