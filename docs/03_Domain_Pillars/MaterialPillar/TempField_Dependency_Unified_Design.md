# 温度/场依赖统一方案设计文档

## Week 1 Day 1 设计文档

**设计时间：** 2026-05-03  
**设计人：** Claude Sonnet 4.6  
**目标：** 设计完整的温度/场依赖传递和插值方案，解决所有11个材料族的共性问题

---

## 1. 问题分析

### 1.1 当前问题

**问题描述：**
所有材料族的L3→L4数据传递都只传递`constants(:,1)`（参考值），未传递温度/场依赖的其他列。

**影响范围：**
- Elas材料族 ✅ 确认
- Plast材料族 ✅ 确认
- Hyper材料族 ✅ 确认
- 其他8个材料族 ❓ 预计相同

**根本原因：**
1. L3层的`constants`数组设计为二维：`constants(num_constants, dependencies)`
2. 第1列存储参考值，第2+列存储温度/场依赖数据
3. 但L3→L4传递时只复制了第1列

### 1.2 设计目标

**功能目标：**
- ✅ 支持温度依赖材料（DEPENDENCIES=1）
- ✅ 支持场依赖材料（DEPENDENCIES=2）
- ✅ 支持多点温度/场数据
- ✅ 支持线性插值和样条插值

**性能目标：**
- ✅ 插值开销：O(n) ≤ 1μs（n为温度点数）
- ✅ 内存使用：合理（避免重复存储）
- ✅ 缓存友好（热路径优化）

**架构目标：**
- ✅ 统一接口（所有材料族共享）
- ✅ 易于扩展（支持新的插值方法）
- ✅ 向后兼容（不破坏现有功能）

---

## 2. 架构设计

### 2.1 数据流设计

```
┌─────────────────────────────────────────────────────────────┐
│                    L3_MD (Model Description)                 │
├─────────────────────────────────────────────────────────────┤
│ MD_Mat_XXX_Desc:                                            │
│   INTEGER(i4) :: num_constants                              │
│   INTEGER(i4) :: dependencies  ! 0=none, 1=temp, 2=field   │
│   REAL(wp), ALLOCATABLE :: constants(:,:)                   │
│     ├─ constants(:,1) = 参考值（T=293.15K）                │
│     ├─ constants(:,2) = 第1个温度点的值                    │
│     ├─ constants(:,3) = 第2个温度点的值                    │
│     └─ ...                                                   │
│   REAL(wp), ALLOCATABLE :: temp_points(:)                   │
│     ├─ temp_points(1) = 第1个温度点（K）                   │
│     ├─ temp_points(2) = 第2个温度点（K）                   │
│     └─ ...                                                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
        MD_Mat_XXX_Brg_Populate_L4（新设计）
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    L4_PH (Physics Computation)               │
├─────────────────────────────────────────────────────────────┤
│ PH_Mat_XXX_Desc:                                            │
│   INTEGER(i4) :: num_constants                              │
│   INTEGER(i4) :: dependencies                               │
│   REAL(wp), ALLOCATABLE :: props_table(:,:)                 │
│     ├─ props_table(:,1) = 参考值                           │
│     ├─ props_table(:,2) = 第1个温度点的值                  │
│     └─ ...                                                   │
│   REAL(wp), ALLOCATABLE :: temp_points(:)                   │
│   TYPE(PH_Mat_Interp_Ctx) :: interp_ctx  ! 插值上下文      │
└─────────────────────────────────────────────────────────────┘
                            ↓
        PH_Mat_Interpolate_Props（新函数）
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    运行时插值                                │
├─────────────────────────────────────────────────────────────┤
│ 输入：                                                       │
│   - props_table(:,:)  材料参数表                           │
│   - temp_points(:)    温度点数组                           │
│   - temperature       当前温度                              │
│                                                              │
│ 输出：                                                       │
│   - props_out(:)      插值后的材料参数                     │
│                                                              │
│ 算法：                                                       │
│   - 线性插值（默认）                                        │
│   - 样条插值（可选）                                        │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 TYPE定义设计

#### 2.2.1 L3层增强（MD_Mat_XXX_Desc）

```fortran
! 所有材料族的Desc类型统一增强
TYPE :: MD_Mat_XXX_Desc
  ! ... 现有字段 ...
  
  ! 温度/场依赖增强
  INTEGER(i4) :: num_constants        ! 材料常数数量
  INTEGER(i4) :: dependencies         ! 0=none, 1=temp, 2=field
  INTEGER(i4) :: num_temp_points      ! 温度点数量
  
  REAL(wp), ALLOCATABLE :: constants(:,:)    ! (num_constants, 1+num_temp_points)
  REAL(wp), ALLOCATABLE :: temp_points(:)    ! (num_temp_points)
  REAL(wp), ALLOCATABLE :: field_points(:)   ! (num_field_points) - 未来扩展
  
  ! ... 其他字段 ...
END TYPE
```

#### 2.2.2 L4层增强（PH_Mat_XXX_Desc）

```fortran
! 所有材料族的L4 Desc类型统一增强
TYPE :: PH_Mat_XXX_Desc
  ! ... 现有字段 ...
  
  ! 温度/场依赖增强
  INTEGER(i4) :: num_constants
  INTEGER(i4) :: dependencies
  INTEGER(i4) :: num_temp_points
  
  REAL(wp), ALLOCATABLE :: props_table(:,:)  ! (num_constants, 1+num_temp_points)
  REAL(wp), ALLOCATABLE :: temp_points(:)    ! (num_temp_points)
  
  ! 插值上下文（缓存）
  TYPE(PH_Mat_Interp_Ctx) :: interp_ctx
  
  ! ... 其他字段 ...
END TYPE
```

#### 2.2.3 插值上下文（新TYPE）

```fortran
! 插值上下文（用于缓存和优化）
TYPE :: PH_Mat_Interp_Ctx
  ! 插值方法
  INTEGER(i4) :: interp_method        ! 1=linear, 2=spline
  
  ! 缓存（避免重复查找）
  INTEGER(i4) :: last_interval        ! 上次插值的区间索引
  REAL(wp) :: last_temperature        ! 上次插值的温度
  REAL(wp), ALLOCATABLE :: last_props(:)  ! 上次插值的结果
  
  ! 样条插值系数（如果使用样条插值）
  REAL(wp), ALLOCATABLE :: spline_coeffs(:,:)
  
  ! 统计信息
  INTEGER(i4) :: num_interpolations   ! 插值次数
  INTEGER(i4) :: num_cache_hits       ! 缓存命中次数
END TYPE
```

---

## 3. 接口设计

### 3.1 L3→L4数据传递接口

#### 3.1.1 统一的Populate接口

```fortran
!===============================================================================
! SUBROUTINE: MD_Mat_XXX_Brg_Populate_L4
! PURPOSE: Populate L4 material descriptor from L3 descriptor
!          Supports temperature/field dependent materials
!
! ARGUMENTS:
!   l3_desc   [IN]  - L3 material descriptor (source)
!   l4_desc   [OUT] - L4 material descriptor (destination)
!   status    [OUT] - Error status
!===============================================================================
SUBROUTINE MD_Mat_XXX_Brg_Populate_L4(l3_desc, l4_desc, status)
  TYPE(MD_Mat_XXX_Desc), INTENT(IN) :: l3_desc
  TYPE(PH_Mat_XXX_Desc), INTENT(OUT) :: l4_desc
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: i, j
  
  CALL init_error_status(status)
  
  ! Validate L3 descriptor
  IF (.NOT. l3_desc%is_initialized) THEN
    status%status_code = 1
    status%message = "L3 descriptor not initialized"
    RETURN
  END IF
  
  ! Copy basic info
  l4_desc%num_constants = l3_desc%num_constants
  l4_desc%dependencies = l3_desc%dependencies
  l4_desc%num_temp_points = l3_desc%num_temp_points
  
  ! Allocate L4 arrays
  IF (l3_desc%dependencies > 0) THEN
    ! Temperature/field dependent
    ALLOCATE(l4_desc%props_table(l3_desc%num_constants, &
                                  1 + l3_desc%num_temp_points))
    ALLOCATE(l4_desc%temp_points(l3_desc%num_temp_points))
    
    ! Copy full table
    DO j = 1, 1 + l3_desc%num_temp_points
      DO i = 1, l3_desc%num_constants
        l4_desc%props_table(i, j) = l3_desc%constants(i, j)
      END DO
    END DO
    
    ! Copy temperature points
    DO i = 1, l3_desc%num_temp_points
      l4_desc%temp_points(i) = l3_desc%temp_points(i)
    END DO
    
    ! Initialize interpolation context
    CALL PH_Mat_Interp_Init(l4_desc%interp_ctx, &
                            l4_desc%props_table, &
                            l4_desc%temp_points, &
                            status)
  ELSE
    ! No temperature/field dependency
    ALLOCATE(l4_desc%props_table(l3_desc%num_constants, 1))
    
    ! Copy reference values only
    DO i = 1, l3_desc%num_constants
      l4_desc%props_table(i, 1) = l3_desc%constants(i, 1)
    END DO
  END IF
  
  status%status_code = IF_STATUS_OK
END SUBROUTINE MD_Mat_XXX_Brg_Populate_L4
```

### 3.2 L4层插值接口

#### 3.2.1 插值函数

```fortran
!===============================================================================
! SUBROUTINE: PH_Mat_Interpolate_Props
! PURPOSE: Interpolate material properties at given temperature
!          Supports linear and spline interpolation
!
! ARGUMENTS:
!   props_table  [IN]  - Material properties table (num_props, num_temps)
!   temp_points  [IN]  - Temperature points array
!   temperature  [IN]  - Current temperature
!   interp_ctx   [INOUT] - Interpolation context (for caching)
!   props_out    [OUT] - Interpolated properties
!   status       [OUT] - Error status
!===============================================================================
SUBROUTINE PH_Mat_Interpolate_Props(props_table, temp_points, temperature, &
                                     interp_ctx, props_out, status)
  REAL(wp), INTENT(IN) :: props_table(:,:)
  REAL(wp), INTENT(IN) :: temp_points(:)
  REAL(wp), INTENT(IN) :: temperature
  TYPE(PH_Mat_Interp_Ctx), INTENT(INOUT) :: interp_ctx
  REAL(wp), INTENT(OUT) :: props_out(:)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: num_props, num_temps
  INTEGER(i4) :: i, i_low, i_high
  REAL(wp) :: t_low, t_high, alpha
  
  CALL init_error_status(status)
  
  num_props = SIZE(props_table, 1)
  num_temps = SIZE(temp_points)
  
  ! Check cache
  IF (ABS(temperature - interp_ctx%last_temperature) < 1.0e-10_wp) THEN
    ! Cache hit
    props_out = interp_ctx%last_props
    interp_ctx%num_cache_hits = interp_ctx%num_cache_hits + 1
    status%status_code = IF_STATUS_OK
    RETURN
  END IF
  
  ! Find interval
  CALL Find_Interval(temp_points, temperature, i_low, i_high, status)
  IF (status%status_code /= IF_STATUS_OK) RETURN
  
  ! Interpolate based on method
  SELECT CASE (interp_ctx%interp_method)
  CASE (1)  ! Linear interpolation
    t_low = temp_points(i_low)
    t_high = temp_points(i_high)
    alpha = (temperature - t_low) / (t_high - t_low)
    
    DO i = 1, num_props
      props_out(i) = (1.0_wp - alpha) * props_table(i, i_low + 1) &
                   + alpha * props_table(i, i_high + 1)
    END DO
    
  CASE (2)  ! Spline interpolation
    CALL Spline_Interpolate(props_table, temp_points, temperature, &
                            interp_ctx%spline_coeffs, props_out, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
  CASE DEFAULT
    status%status_code = IF_STATUS_INVALID
    status%message = "Unknown interpolation method"
    RETURN
  END SELECT
  
  ! Update cache
  interp_ctx%last_temperature = temperature
  interp_ctx%last_props = props_out
  interp_ctx%num_interpolations = interp_ctx%num_interpolations + 1
  
  status%status_code = IF_STATUS_OK
END SUBROUTINE PH_Mat_Interpolate_Props
```

#### 3.2.2 辅助函数

```fortran
!===============================================================================
! SUBROUTINE: Find_Interval
! PURPOSE: Find the interval containing the given temperature
!===============================================================================
SUBROUTINE Find_Interval(temp_points, temperature, i_low, i_high, status)
  REAL(wp), INTENT(IN) :: temp_points(:)
  REAL(wp), INTENT(IN) :: temperature
  INTEGER(i4), INTENT(OUT) :: i_low, i_high
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: n, i
  
  CALL init_error_status(status)
  n = SIZE(temp_points)
  
  ! Handle boundary cases
  IF (temperature <= temp_points(1)) THEN
    i_low = 1
    i_high = 1
    status%status_code = IF_STATUS_OK
    RETURN
  END IF
  
  IF (temperature >= temp_points(n)) THEN
    i_low = n
    i_high = n
    status%status_code = IF_STATUS_OK
    RETURN
  END IF
  
  ! Binary search
  i_low = 1
  i_high = n
  DO WHILE (i_high - i_low > 1)
    i = (i_low + i_high) / 2
    IF (temperature < temp_points(i)) THEN
      i_high = i
    ELSE
      i_low = i
    END IF
  END DO
  
  status%status_code = IF_STATUS_OK
END SUBROUTINE Find_Interval
```

---

## 4. 实现计划

### 4.1 Phase 1：核心基础设施（Day 2-3）

**任务：**
1. 创建`PH_Mat_Interp_Core.f90`模块
   - 实现`PH_Mat_Interp_Ctx` TYPE
   - 实现`PH_Mat_Interp_Init`
   - 实现`PH_Mat_Interpolate_Props`
   - 实现`Find_Interval`辅助函数

2. 创建单元测试
   - 测试线性插值
   - 测试边界情况
   - 测试缓存机制

**交付物：**
- `PH_Mat_Interp_Core.f90`（约200行）
- 单元测试（约100行）

### 4.2 Phase 2：材料族集成（Day 4-5）

**任务：**
1. 修正Elas材料族
   - 更新`MD_Mat_Elas_Brg.f90`
   - 更新`PH_Mat_Elas_Core.f90`
   - 集成测试

2. 修正Plast材料族
   - 更新`MD_Mat_Plast_Brg.f90`
   - 更新`PH_Mat_Plast_Core.f90`
   - 集成测试

3. 修正Hyper材料族
   - 更新`MD_Mat_Hyper_Brg.f90`
   - 更新`PH_Mat_Hyper_Core.f90`
   - 集成测试

**交付物：**
- 3个材料族修正完成
- 集成测试通过

### 4.3 Phase 3：验证和优化（Day 6-7）

**任务：**
1. 功能验证
   - 温度依赖材料测试
   - 场依赖材料测试
   - 多点插值测试

2. 性能测试
   - 插值性能测试
   - 缓存命中率测试
   - 内存使用测试

3. 文档更新
   - 更新架构文档
   - 更新用户指南
   - 创建示例代码

**交付物：**
- 测试报告
- 性能报告
- 更新的文档

---

## 5. 测试策略

### 5.1 单元测试

**测试用例：**
1. 线性插值精度测试
2. 边界情况测试（T < T_min, T > T_max）
3. 缓存机制测试
4. 错误处理测试

### 5.2 集成测试

**测试用例：**
1. Elas材料族温度依赖测试
2. Plast材料族温度依赖测试
3. Hyper材料族温度依赖测试
4. L3→L4→L5完整数据流测试

### 5.3 性能测试

**测试指标：**
- 插值时间：≤ 1μs
- 缓存命中率：≥ 80%
- 内存使用：合理

---

## 6. 向后兼容性

### 6.1 兼容性保证

**原则：**
- 不破坏现有功能
- 支持渐进式迁移
- 提供兼容层

**实现：**
```fortran
! 如果dependencies=0，使用旧的行为
IF (l3_desc%dependencies == 0) THEN
  ! 旧行为：只传递参考值
  DO i = 1, l3_desc%num_constants
    l4_props(i) = l3_desc%constants(i, 1)
  END DO
ELSE
  ! 新行为：传递完整表格
  ! ...
END IF
```

---

## 7. 风险评估

### 7.1 技术风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 插值精度不足 | 低 | 中 | 使用成熟的插值算法 |
| 性能下降 | 低 | 中 | 缓存机制 + 性能测试 |
| 内存使用增加 | 中 | 低 | 只在需要时分配 |

### 7.2 实施风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 工作量估算不准 | 中 | 中 | 预留缓冲时间 |
| 测试发现新问题 | 中 | 中 | 完整的测试覆盖 |

---

## 8. 成功标准

### 8.1 功能标准

- ✅ 支持温度依赖材料（所有材料族）
- ✅ 支持场依赖材料（所有材料族）
- ✅ 线性插值精度 ≤ 1%
- ✅ 所有测试通过

### 8.2 性能标准

- ✅ 插值时间 ≤ 1μs
- ✅ 缓存命中率 ≥ 80%
- ✅ 内存使用合理

### 8.3 质量标准

- ✅ 代码注释完整
- ✅ 单元测试覆盖率 ≥ 80%
- ✅ 文档完整

---

## 9. 下一步行动

### 9.1 立即行动（Day 2）

1. 创建`PH_Mat_Interp_Core.f90`模块
2. 实现核心插值函数
3. 创建单元测试

### 9.2 后续行动（Day 3-7）

4. 修正3个材料族
5. 集成测试
6. 性能优化
7. 文档更新

---

## 10. 附录

### 10.1 ABAQUS温度依赖语法

```
*ELASTIC, TYPE=ISOTROPIC, DEPENDENCIES=1
210000., 0.3, 293.15
200000., 0.3, 373.15
190000., 0.3, 473.15
```

### 10.2 参考文献

1. ABAQUS 6.14 User Manual - Material Definition
2. Numerical Recipes - Interpolation and Extrapolation
3. UFC Architecture Document - Material Pillar

---

**设计完成时间：** 2026-05-03  
**设计版本：** v1.0  
**下一步：** Day 2 - 实现核心插值函数
