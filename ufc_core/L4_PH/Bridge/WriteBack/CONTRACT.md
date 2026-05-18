# PH_WriteBack Domain Contract

## Domain Overview

- **Layer**: L4_PH (Physical Layer)
- **Domain**: WriteBack
- **Purpose**: Physical computation for writing back nodal/element state to L3_MD containers
- **Theory**: WriteBack is a physical operation that updates mesh State (displacement, velocity, acceleration, stress, strain) based on computed DOF values
- **Responsibility**: Pure physics implementation - NO scheduling, NO IO, NO lifecycle management

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## Architecture Boundaries

### What PH_WriteBack IS:
- ✅ Physical computation for write-back operations
- ✅ Thin wrapper around L3_MD data container APIs
- ✅ Stateless (all state passed through arguments)
- ✅ Deterministic (same input → same output)

### What PH_WriteBack IS NOT:
- ❌ Scheduling logic (when to write back)
- ❌ IO operations (file I/O belongs to L1_IF)
- ❌ Data storage (data belongs to L3_MD)
- ❌ Lifecycle management (Step/Increment control belongs to L5_RT)

---

## Four Chains Integration

### 1. Theory Chain (物理 → 数学 → 离散)
- **Physics**: Continuum mechanics state update
- **Mathematics**: Field interpolation at nodes/elements
- **Discretization**: FE mesh nodal/element State update

### 2. Logic Chain (模型 → 求解 → 输出)
- **Model**: Mesh geometry and material State
- **Solution**: Computed DOF values (disp, vel, accel, stress, strain)
- **Output**: Updated mesh State in L3_MD containers

### 3. Computation Chain (全局 → 单元 → 材料)
- **Global**: Mesh-level write-back coordination
- **Element**: Integration point stress/strain recovery
- **Material**: Constitutive State update (if applicable)

### 4. Data Chain (生命周期管理)
- **Creation**: PH_WriteBack_Desc/State initialization
- **Usage**: Transient during write-back operations
- **Destruction**: Buffer deallocation after write-back complete

---

## TYPE Definitions

### PH_WriteBack_Desc (Category: Desc)

**Purpose**: WriteBack configuration (immutable during analysis)

**Fields**:
```fortran
TYPE :: PH_WriteBack_Desc
  LOGICAL :: write_disp = .TRUE.      ! Output displacement flag
  LOGICAL :: write_vel = .FALSE.      ! Output velocity flag (dynamic only)
  LOGICAL :: write_accel = .FALSE.    ! Acceleration flag (dynamic only)
  LOGICAL :: write_stress = .TRUE.    ! Output stress flag
  LOGICAL :: write_strain = .TRUE.    ! Output strain flag
  INTEGER(i4) :: output_freq = 1_i4   ! Output frequency (every N increments)
  CHARACTER(LEN=256) :: output_dir = "" ! Output directory path
END TYPE
```

**Invariants**:
- At least one output variable must be enabled
- `output_freq` must be positive (> 0)

---

### PH_WriteBack_State (Category: State)

**Purpose**: WriteBack runtime state (buffers, counters)

**Fields**:
```fortran
TYPE :: PH_WriteBack_State
  INTEGER(i4) :: total_nodes = 0_i4         ! Total nodes written
  INTEGER(i4) :: total_elements = 0_i4      ! Total elements written
  INTEGER(i4) :: current_increment = 0_i4   ! Current increment counter
  REAL(wp), ALLOCATABLE :: disp_buffer(:,:) ! Displacement buffer (3, nnodes)
  REAL(wp), ALLOCATABLE :: stress_buffer(:,:) ! Stress buffer (6, nelems)
  REAL(wp), ALLOCATABLE :: strain_buffer(:,:) ! Strain buffer (6, nelems)
END TYPE
```

**Lifecycle**:
1. **Init**: Allocate buffers, reset counters
2. **Reset**: Clear buffers (keep allocation)
3. **Finalize**: Deallocate buffers

---

### PH_WriteBack_Args (Category: Ctx)

**Purpose**: Temporary context for write-back operations

**Fields**:
```fortran
TYPE :: PH_WriteBack_Args
  INTEGER(i4) :: node_idx = 0_i4          ! Node index
  INTEGER(i4) :: elem_idx = 0_i4          ! Element index
  INTEGER(i4) :: ip_idx = 0_i4            ! Integration point index
  REAL(wp) :: disp(3) = 0.0_wp            ! Displacement vector
  REAL(wp) :: vel(3) = 0.0_wp             ! Velocity vector
  REAL(wp) :: accel(3) = 0.0_wp           ! Acceleration vector
  REAL(wp) :: stress(6) = 0.0_wp          ! Stress tensor (Voigt)
  REAL(wp) :: strain(6) = 0.0_wp          ! Strain tensor (Voigt)
  TYPE(ErrorStatusType) :: status         ! Error status
END TYPE
```

**Usage**: Transient (stack-allocated, no dynamic memory)

---

## Public API

### Node Write-Back Operations

#### PH_WriteBack_NodeDisp
```fortran
SUBROUTINE PH_WriteBack_NodeDisp(node_idx, disp, status)
  INTEGER(i4), INTENT(IN) :: node_idx
  REAL(wp), INTENT(IN) :: disp(3)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
```
- **Precondition**: `node_idx` valid (1 <= node_idx <= nnodes)
- **Postcondition**: Nodal displacement updated in L3_MD container
- **Error Handling**: Invalid node index → STATUS_INVALID

#### PH_WriteBack_NodeVel
```fortran
SUBROUTINE PH_WriteBack_NodeVel(node_idx, vel, status)
  INTEGER(i4), INTENT(IN) :: node_idx
  REAL(wp), INTENT(IN) :: vel(3)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
```
- **Precondition**: `node_idx` valid
- **Postcondition**: Nodal velocity updated in L3_MD container

#### PH_WriteBack_NodeAccel
```fortran
SUBROUTINE PH_WriteBack_NodeAccel(node_idx, accel, status)
  INTEGER(i4), INTENT(IN) :: node_idx
  REAL(wp), INTENT(IN) :: accel(3)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
```
- **Precondition**: `node_idx` valid
- **Postcondition**: Nodal acceleration updated in L3_MD container

---

### Element Write-Back Operations

#### PH_WriteBack_ElemStress
```fortran
SUBROUTINE PH_WriteBack_ElemStress(elem_idx, ip_idx, stress, status)
  INTEGER(i4), INTENT(IN) :: elem_idx, ip_idx
  REAL(wp), INTENT(IN) :: stress(6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
```
- **Precondition**: `elem_idx` valid, `ip_idx` valid (1 <= ip_idx <= nip)
- **Postcondition**: Element stress updated in L3_MD container
- **Stress Format**: Voigt notation [σ_xx, σ_yy, σ_zz, σ_xy, σ_yz, σ_xz]

#### PH_WriteBack_ElemStrain
```fortran
SUBROUTINE PH_WriteBack_ElemStrain(elem_idx, ip_idx, strain, status)
  INTEGER(i4), INTENT(IN) :: elem_idx, ip_idx
  REAL(wp), INTENT(IN) :: strain(6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
```
- **Precondition**: `elem_idx` valid, `ip_idx` valid
- **Postcondition**: Element strain updated in L3_MD container
- **Strain Format**: Voigt notation [ε_xx, ε_yy, ε_zz, γ_xy, γ_yz, γ_xz]

---

## Dependencies

### Upward Dependencies (L4_PH → L3_MD)
```fortran
USE MD_Mesh_Proc, ONLY: MD_Mesh_NodePos, MD_Mesh_NodeDisp, ...
USE MD_WriteBack_API, ONLY: MD_WB_Mesh_NodeDisp, MD_WB_Mesh_ElemStress, ...
```

### Internal Dependencies (within L4_PH)
```fortran
! None (PH_WriteBack is leaf domain)
```

### Downward Dependencies (none - L4_PH does not call L5_RT)
```fortran
! No dependencies on L5_RT or higher layers
```

---

## Implementation Status

| Module | Status | Lines | Last Verified |
|--------|--------|-------|---------------|
| PH_WriteBack_Core.f90 | CORE | 270 | 2026-03-30 |
| PH_WriteBack_API.f90 | CORE | 107 | 2026-03-30 |
| PH_WriteBack_Init.f90 | CORE | 73 | 2026-03-30 |
| **Total** | **CORE** | **450** | **2026-03-30** |

---

## Migration Guide (for RT_WriteBack refactoring)

### Current State (L5_RT violation):
```fortran
! L5_RT/RT_WriteBack_Domain_Core.f90 (WRONG - contains physics)
CALL MD_WB_Mesh_NodeDisp(node_idx, disp, status)
CALL MD_WB_Mesh_ElemStress(elem_idx, ip_idx, stress, status)
```

### Target State (thin adapter pattern):
```fortran
! L5_RT/RT_WriteBack_Domain_Core.f90 (CORRECT - thin routing)
USE PH_WriteBack_API, ONLY: PH_WriteBack_ApplyNodeDisp, PH_WriteBack_ApplyElemStress

CALL PH_WriteBack_ApplyNodeDisp(node_idx, disp, status)
CALL PH_WriteBack_ApplyElemStress(elem_idx, ip_idx, stress, status)
```

### Migration Steps:
1. Create PH_WriteBack domain (✅ DONE)
2. Update RT_WriteBack to route through PH_WriteBack_API
3. Remove direct MD_WriteBack_API calls from L5_RT
4. Verify L5_RT contains only scheduling logic (no physics)

---

## Testing Strategy

### Unit Tests (Phase 3)
- Test node write-back with known displacement values
- Test element stress/strain recovery
- Test error handling (invalid indices)

### Integration Tests (Phase 4)
- Test full Step-Increment-Iteration cycle
- Test multi-physics coupling (thermo-mechanical)
- Test parallel scaling (OpenMP/MPI)

### Verification Tests (Phase 5)
- Patch test verification (constant stress state)
- Benchmark against ABAQUS reference solutions

---

## Related Documents

- [UFC Architecture Overview](../../../docs/05_Project_Planning/PPLAN/README.md)
- [L4_PH Layer Specification](../PH_L4_LayerContainer_Core.f90)
- [L3_MD WriteBack API](../../L3_MD/WriteBack/MD_WriteBack_API.f90)
- [L5_RT Responsibility Boundary](../../L5_RT/RT_Core.f90)


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `PH_WB.f90` | `PH_WB` | `PH_WriteBack_Desc` | `Init` (TBP,PRV,—); `Validate` (TBP,PRV,—); `PH_WriteBack_Desc_Init` (SUB,PRV,Init); `PH_WriteBack_Desc_Validate` (FN,PRV,Validate); `PH_WriteBack_State_Init` (SUB,PRV,Init); `PH_WriteBack_State_Finalize` (SUB,PRV,Finalize); `PH_WriteBack_State_Reset` (SUB,PRV,Mutate); `PH_WriteBack_NodeDisp` (SUB,PUB,IO); `PH_WriteBack_NodeVel` (SUB,PUB,IO); `PH_WriteBack_NodePos` (SUB,PUB,IO); `PH_WriteBack_NodeAccel` (SUB,PUB,IO); `PH_WriteBack_ElemStress` (SUB,PUB,IO); `PH_WriteBack_ElemStrain` (SUB,PUB,IO) |
| `PH_WB_Init.f90` | `PH_WBInit` | — | `PH_WriteBack_InitDomain` (SUB,PUB,Init); `PH_WriteBack_FinalizeDomain` (SUB,PUB,Finalize) |
| `PH_WB_Brg.f90` | `PH_WB_Brg` | — | `PH_WriteBack_ApplyNodeDisp` (SUB,PUB,IO); `PH_WriteBack_ApplyNodeVel` (SUB,PUB,IO); `PH_WriteBack_ApplyNodeAccel` (SUB,PUB,IO); `PH_WriteBack_ApplyNodePos` (SUB,PUB,IO); `PH_WriteBack_ApplyElemStress` (SUB,PUB,IO); `PH_WriteBack_ApplyElemStrain` (SUB,PUB,IO) |

---

## Domain Pillar v2.0 Update (2026-04-26)

### P6 WriteBack 域柱 L4 层对齐

| 角色 | 模块 | 状态 |
|------|------|------|
| **AUTHORITY** (L4 物理写回) | `PH_WB.f90` | ACTIVE |
| Bridge API | `PH_WB_Brg.f90` | ACTIVE |
| 域初始化 | `PH_WB_Init.f90` | ACTIVE |

### 命名修正

- CONTRACT 原引用 `PH_WriteBack_Core.f90` -> 实际为 `PH_WB.f90`
- CONTRACT 原引用 `PH_WriteBack_API.f90` -> 实际为 `PH_WB_Brg.f90`
- `PH_WB_Brg` header 原引用 `PH_WB_Algo` -> 实际为 `PH_WB`

### 跨层依赖

- L3: `MD_WriteBack_Def` (AUTHORITY for WB map registry)
- L5: `RT_WB_Def` (AUTHORITY for runtime WB types)
