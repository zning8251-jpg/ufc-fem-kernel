# L4_PH/Output Domain Contract

## Domain Purpose

**L4_PH/Output** 负责输出相关的**纯物理计算**，包括：
- 坐标变换（全局坐标系 ↔ 局部坐标系）
- 张量变换（Voigt 记号 ↔ 完整张量）
- 场变量插值（单元积分点 → 节点）
- 分量提取（标量/向量/张量）

**职责边界**：
- ✅ **纯计算逻辑**：无 IO 操作、无内存分配、无状态管理
- ✅ **薄适配器模式**：PH_Output_API 作为 L5_RT 的唯一路由接口
- ✅ **理论链贯通**：连续介质力学张量变换理论

**不包含**：
- ❌ VTK/HDF5/ODB 文件写入（L1_IF/IO 基础设施）
- ❌ 输出调度与格式选择（L5_RT/Output 运行时调度）
- ❌ 数据生命周期管理（L3_MD/Output 模型数据）

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## Public Types

### PH_Output_Params (Desc - 配置型)

```fortran
TYPE :: PH_Output_Params
  INTEGER(i4) :: format_type       ! PH_OUTPUT_VTK/HDF5/ODB/BINARY
  INTEGER(i4) :: n_components      ! 场分量数量 (1=标量，3=向量，6=张量)
  INTEGER(i4) :: tensor_rank       ! 张量阶数 (0/1/2)
  LOGICAL     :: write_binary      ! 是否二进制输出
  CHARACTER(LEN=256) :: field_name ! 场变量名称
  CHARACTER(LEN=256) :: units      ! 物理单位
END TYPE
```

**不变量**：
- `format_type ∈ {1, 2, 3, 4}`
- `n_components ∈ {1, 3, 6, 9}`
- `tensor_rank ∈ {0, 1, 2}`

---

### PH_Output_State (State - 状态型)

```fortran
TYPE :: PH_Output_State
  INTEGER(i4) :: n_nodes              ! 节点数量
  INTEGER(i4) :: n_elements           ! 单元数量
  REAL(wp), ALLOCATABLE :: nodal_coords(:,:)    ! [3 × n_nodes]
  REAL(wp), ALLOCATABLE :: elem_connect(:,:)    ! [n_nodes_per_elem × n_elems]
  REAL(wp), ALLOCATABLE :: field_data(:,:)      ! [n_components × n_points]
  REAL(wp) :: time_value              ! 时间值
  INTEGER(i4) :: step_number          ! 分析步编号
END TYPE
```

**生命周期**：
- 每个输出帧（Frame）创建一次
- 输出完成后销毁
- 不跨分析步持久化

---

## Constants

### Output Format Type
```fortran
INTEGER(i4), PARAMETER :: PH_OUTPUT_VTK    = 1_i4
INTEGER(i4), PARAMETER :: PH_OUTPUT_HDF5   = 2_i4
INTEGER(i4), PARAMETER :: PH_OUTPUT_ODB    = 3_i4
INTEGER(i4), PARAMETER :: PH_OUTPUT_BINARY = 4_i4
```

### Voigt Notation Indices
```fortran
INTEGER(i4), PARAMETER :: PH_VOIGT_XX = 1_i4  ! σ_xx
INTEGER(i4), PARAMETER :: PH_VOIGT_YY = 2_i4  ! σ_yy
INTEGER(i4), PARAMETER :: PH_VOIGT_ZZ = 3_i4  ! σ_zz
INTEGER(i4), PARAMETER :: PH_VOIGT_XY = 4_i4  ! σ_xy
INTEGER(i4), PARAMETER :: PH_VOIGT_YZ = 5_i4  ! σ_yz
INTEGER(i4), PARAMETER :: PH_VOIGT_ZX = 6_i4  ! σ_zx
```

---

## Public API

### 1. Coordinate Transformation

```fortran
SUBROUTINE PH_Output_TransformCoords( &
  coords_global,      ! IN: [3 × n] Global coordinates
  rotation_matrix,    ! IN: [3 × 3] Rotation matrix
  coords_local,       ! OUT: [3 × n] Local coordinates
  status              ! OUT: Error status
)
```

**理论公式**：
```
x_local = R · x_global
```

**使用场景**：
- 各向异性材料的局部坐标系输出
- 梁/壳单元的截面应力输出

---

### 2. Tensor Transformation

```fortran
SUBROUTINE PH_Output_TransformTensor( &
  tensor_voigt,   ! IN/OUT: [6] Voigt notation
  tensor_full,    ! IN/OUT: [3 × 3] Full tensor
  direction,      ! IN: 'VOIGT_TO_FULL' or 'FULL_TO_VOIGT'
  status          ! OUT: Error status
)
```

**理论公式**：
- Voigt → Full:
  ```
  [σ] = [σ_xx  σ_xy  σ_xz]
        [σ_xy  σ_yy  σ_yz]
        [σ_xz  σ_yz  σ_zz]
  ```
- Full → Voigt:
  ```
  {σ} = {σ_xx, σ_yy, σ_zz, σ_xy, σ_yz, σ_zx}
  ```

**使用场景**：
- ABAQUS UEL 接口（Voigt 记号）
- 张量不变量计算（Full 张量）

---

### 3. Field Interpolation

```fortran
SUBROUTINE PH_Output_InterpolateField( &
  nodal_values,      ! IN: [n_nodes × n_comp] Nodal values
  shape_funcs,       ! IN: [n_nodes] Shape functions
  interpolated_value ! OUT: [n_comp] Interpolated value
)
```

**理论公式**：
```
φ(ξ) = Σᵢ Nᵢ(ξ) φᵢ
```

**使用场景**：
- 积分点应力→节点应力外推
- 单元中心场变量计算

---

### 4. Scalar Extraction

```fortran
SUBROUTINE PH_Output_GetScalar( &
  field_data,     ! IN: [n_points × n_comp] Field data
  component_idx,  ! IN: Component index (1-based)
  scalar_value,   ! OUT: [n_points] Scalar values
  status          ! OUT: Error status
)
```

**使用场景**：
- 提取 Mises 等效应力（单分量）
- 提取位移幅值

---

### 5. Vector Extraction

```fortran
SUBROUTINE PH_Output_GetVector( &
  field_data,     ! IN: [n_points × 3] Field data
  vector_values,  ! OUT: [3 × n_points] Vector values
  status          ! OUT: Error status
)
```

**使用场景**：
- 位移场可视化（3 分量）
- 速度/加速度场输出

---

### 6. Tensor Extraction

```fortran
SUBROUTINE PH_Output_GetTensor( &
  field_data,     ! IN: [n_points × 6] Voigt notation
  tensor_values,  ! OUT: [3 × 3 × n_points] Full tensor
  notation,       ! IN: 'VOIGT' or 'FULL'
  status          ! OUT: Error status
)
```

**使用场景**：
- 应力/应变张量可视化
- 主应力计算

---

## Dependencies

### External (L1/L2/L3)
```fortran
USE IF_Prec_Core,    ONLY: wp, i4        ! L1: Precision types
USE IF_Err_API, ONLY: ErrorStatusType ! L1: Error handling
```

### Internal (L4 Domains)
- **None** (纯计算模块，无域间依赖)

---

## Usage Example

```fortran
PROGRAM example_ph_output
  USE IF_Prec_Core, ONLY: wp
  USE IF_Err_API, ONLY: ErrorStatusType
  USE PH_Output_API, ONLY: PH_Output_TransformTensor
  
  IMPLICIT NONE
  REAL(wp) :: stress_voigt(6), stress_tensor(3, 3)
  TYPE(ErrorStatusType) :: status
  
  ! Voigt notation (from ABAQUS UEL)
  stress_voigt = [100.0_wp, 50.0_wp, 25.0_wp, 10.0_wp, 5.0_wp, 8.0_wp]
  
  ! Convert to full tensor
  CALL PH_Output_TransformTensor(stress_voigt, stress_tensor, &
                                 'VOIGT_TO_FULL', status)
  
  ! Result:
  ! stress_tensor = [100,  10,   8]
  !                 [ 10,  50,   5]
  !                 [  8,   5,  25]
END PROGRAM
```

---

## Verification

### Unit Tests Required

1. **PH_Output_TransformCoords**:
   - 恒等变换（R = I）
   - 90° 旋转
   - 任意角度旋转

2. **PH_Output_TransformTensor**:
   - Voigt → Full → Voigt 往返验证
   - 对称性检查（σ_ij = σ_ji）

3. **PH_Output_FieldInterpolate**:
   - 线性形函数验证
   - 二次形函数验证
   - 守恒性检查（ΣNᵢ = 1）

4. **PH_Output_Get***:
   - 边界值检查（component_idx 范围）
   - 维度匹配验证

---

## Architecture Compliance

### L5_RT Routing Example

```fortran
MODULE RT_Out_VTK_Core
  USE PH_Output_API, ONLY: PH_Output_TransformTensor, &
                           PH_Output_GetVector, PH_Output_GetTensor
  
  SUBROUTINE RT_Out_WriteVTK_Stress(this, elem_idx, stress_voigt)
    ! L5_RT: Scheduling (file handle, format selection)
    type(RT_Out_VTK), intent(inout) :: this
    integer(i4), intent(in) :: elem_idx
    real(wp), intent(in) :: stress_voigt(6)
    
    real(wp) :: stress_tensor(3, 3)
    type(ErrorStatusType) :: status
    
    ! ROUTE TO L4_PH: Tensor transformation
    CALL PH_Output_TransformTensor(stress_voigt, stress_tensor, &
                                   'VOIGT_TO_FULL', status)
    
    ! L5_RT: Write to file (using L1_IF/IO)
    CALL this%file%WriteTensor(stress_tensor)
  END SUBROUTINE
END MODULE
```

### Dependency Validation

```bash
# Check: L4_PH/Output should NOT depend on L5_RT
grep -r "USE RT_" UFC/ufc_core/L4_PH/Output/
# Expected: No matches

# Check: L4_PH/Output should NOT have IO operations
grep -r "OPEN\|WRITE\|CLOSE" UFC/ufc_core/L4_PH/Output/*.f90
# Expected: No matches (except comments)
```

---

## Version History

| Version | Date | Changes | Verified By |
|---------|------|---------|-------------|
| 1.0 | 2026-03-30 | Initial contract (PH_Output_Core + PH_Output_API) | AI Agent |

---

## Cross-References

- **L1_IF/IO**: File handle management, binary/text I/O
- **L3_MD/Output**: Output configuration, field requests, history requests
- **L5_RT/Output**: Output scheduling, format selection, Writer routing
- **L4_PH/Element**: Shape functions for field interpolation
- **ABAQUS UEL**: Voigt notation standard (6 components)

---

**Contract Status**: ✅ Complete (N1-2 delivered)  
**Last Updated**: 2026-03-30  
**Next Review**: After Phase 2 Solver Integration


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `PH_Out.f90` | `PH_Out` | `PH_Output_Params`, `PH_Output_State` | `PH_Output_CoordTransform` (SUB,PUB,IO); `PH_Output_TensorTransform` (SUB,PUB,IO); `PH_Output_FieldInterpolate` (SUB,PUB,IO); `PH_Output_ExtractScalar` (SUB,PUB,IO); `PH_Output_ExtractVector` (SUB,PUB,IO); `PH_Output_ExtractTensor` (SUB,PUB,IO) |
| `PH_Out_Brg.f90` | `PH_Out_Brg` | — | `PH_Output_TransformCoords` (SUB,PUB,Bridge); `PH_Output_TransformTensor` (SUB,PUB,Bridge); `PH_Output_InterpolateField` (SUB,PUB,IO); `PH_Output_GetScalar` (SUB,PUB,Query); `PH_Output_GetVector` (SUB,PUB,Query); `PH_Output_GetTensor` (SUB,PUB,Query) |

---

## Domain Pillar v2.0 Update (2026-04-26)

### P5 Output 域柱 L4 层对齐

| 角色 | 模块 | 状态 |
|------|------|------|
| **AUTHORITY** (L4 物理变换) | `PH_Out.f90` | ACTIVE |
| Bridge API | `PH_Out_Brg.f90` | ACTIVE |

### 命名修正

- CONTRACT 原引用 `PH_Output_API` -> 实际模块为 `PH_Out` / `PH_Out_Brg`
- `PH_Out_Brg` header 原引用 `PH_Out_Algo` -> 实际为 `PH_Out`

### 跨层依赖

- L3: `MD_Output_Def` (AUTHORITY for output request schema)
- L5: `RT_Out_Def` (AUTHORITY for runtime output types)
