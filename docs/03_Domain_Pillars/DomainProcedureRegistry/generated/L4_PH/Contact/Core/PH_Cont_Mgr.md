# `PH_Cont_Mgr.f90`

- **Source**: `L4_PH/Contact/Core/PH_Cont_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Cont_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_Mgr`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Contact/Core`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Core/PH_Cont_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Cont_SearchArgs` (lines 107–126)

```fortran
  TYPE :: PH_Cont_SearchArgs
    INTEGER(i4) :: search_algorithm  = 0_i4  !! 0= 1=BVH 2=SpatialHash 3=Octree
    INTEGER(i4) :: optimization_level = 0_i4  !! 0= 1= 2= 3=
    INTEGER(i4) :: n_candidates      = 0_i4  ! narrow-phase candidate count
    INTEGER(i4) :: n_contacts        = 0_i4  ! active contact count
    REAL(wp)    :: cell_size         = 1.0_wp  ! uniform cell size (hash)
    REAL(wp)    :: tolerance         = 1.0e-6_wp  ! convergence tolerance
    REAL(wp)    :: bbox_min(3)       = 0.0_wp  ! AABB min corner
    REAL(wp)    :: bbox_max(3)       = 0.0_wp  ! AABB max corner
    ! POINTER
    INTEGER(i4), POINTER :: slave_nodes(:)   => NULL()  ! slave node id list ptr
    INTEGER(i4), POINTER :: master_nodes(:)  => NULL()  ! master node id list ptr
    INTEGER(i4) :: n_slave    = 0_i4  ! slave entity count
    INTEGER(i4) :: n_master   = 0_i4  ! master entity count
    INTEGER(i4), POINTER :: contact_pairs(:,:) => NULL()  !! (2, n_pairs)
    INTEGER(i4) :: n_pairs    = 0_i4  ! contact pair count
    ! POINTER
    REAL(wp), POINTER :: coords(:,:)  => NULL()  !! (3, n_points)
    INTEGER(i4) :: n_points   = 0_i4  ! sample / quadrature point count
  END TYPE PH_Cont_SearchArgs
```

### `PH_Cont_BVHArgs` (lines 132–145)

```fortran
  TYPE :: PH_Cont_BVHArgs
    ! ---- BVH ----
    INTEGER(i4) :: n_objects    = 0_i4  ! spatial-hash object count
    INTEGER(i4) :: max_depth    = 32_i4  !! Octree
    INTEGER(i4) :: root_id      = 0_i4   !! ID
    ! ---- ----
    TYPE(AABB_Type) :: query_aabb            !! AABB
    INTEGER(i4) :: n_collisions  = 0_i4  ! broad-phase collision count
    ! POINTER
    TYPE(BVH_Node_Type), POINTER :: nodes(:) => NULL()   !! BVH ALLOCATABLE POINTER
    TYPE(AABB_Type),     POINTER :: objects_aabb(:) => NULL() !! AABB
    INTEGER(i4), POINTER :: collision_ids(:) => NULL()  !! ID
    INTEGER(i4), POINTER :: work_buf(:)      => NULL()  ! temporary workspace ptr
  END TYPE PH_Cont_BVHArgs
```

### `PH_Cont_SpatialHashArgs` (lines 151–159)

```fortran
  TYPE :: PH_Cont_SpatialHashArgs
    REAL(wp)    :: cell_size          = 1.0_wp  ! uniform cell size (hash)
    INTEGER(i4) :: table_size         = 10007_i4  ! hash table slot count
    INTEGER(i4) :: max_objects_per_cell = 100_i4  ! max objects per hash cell
    REAL(wp)    :: query_position(3)  = 0.0_wp  !! Query
    INTEGER(i4) :: n_nearby           = 0_i4  ! neighbour search result count
    INTEGER(i4), POINTER :: nearby_ids(:) => NULL()  !! ID
    INTEGER(i4), POINTER :: work_buf(:)   => NULL()  ! temporary workspace ptr
  END TYPE PH_Cont_SpatialHashArgs
```

### `PH_Cont_LargeDefArgs` (lines 165–175)

```fortran
  TYPE :: PH_Cont_LargeDefArgs
    ! ---- ----
    REAL(wp) :: X_slave(3)   = 0.0_wp  ! slave surface coords ptr
    REAL(wp) :: X_master(3)  = 0.0_wp  ! master surface coords ptr
    REAL(wp) :: u_slave(3)   = 0.0_wp  ! slave displacement ptr
    REAL(wp) :: u_master(3)  = 0.0_wp  ! master displacement ptr
    ! ---- ----
    REAL(wp), POINTER :: surface_coords(:,:) => NULL()  !! (3, n_surf_nodes)
    INTEGER(i4) :: n_surface_nodes = 0_i4  ! nodes on surface patch
    INTEGER(i4) :: closest_node_id = 0_i4  !! ID
  END TYPE PH_Cont_LargeDefArgs
```

### `AABB_Type` (lines 180–185)

```fortran
  TYPE, PUBLIC :: AABB_Type
      REAL(wp) :: min_coords(3) = ZERO
      REAL(wp) :: max_coords(3) = ZERO
      REAL(wp) :: center(3) = ZERO
      REAL(wp) :: extents(3) = ZERO
  END TYPE AABB_Type
```

### `BVH_Node_Type` (lines 186–192)

```fortran
  TYPE, PUBLIC :: BVH_Node_Type
      TYPE(AABB_Type) :: bbox
      INTEGER(i4) :: left_child = -1
      INTEGER(i4) :: right_child = -1
      INTEGER(i4) :: object_id = -1
      LOGICAL :: is_leaf = .FALSE.
  END TYPE BVH_Node_Type
```

### `BVH_Build_Desc` (lines 193–200)

```fortran
  TYPE, PUBLIC :: BVH_Build_Desc
      INTEGER(i4) :: n_objects = 0
      INTEGER(i4) :: start_idx = 0
      INTEGER(i4) :: end_idx = 0
      INTEGER(i4) :: max_nodes = 0
      INTEGER(i4) :: node_id = -1
      INTEGER(i4) :: node_count = 0
  END TYPE BVH_Build_Desc
```

### `Octree_Node_Type` (lines 201–208)

```fortran
  TYPE, PUBLIC :: Octree_Node_Type
      TYPE(AABB_Type) :: bbox
      INTEGER(i4) :: children(8) = -1
      INTEGER(i4), ALLOCATABLE :: object_ids(:)
      INTEGER(i4) :: n_objects = 0
      INTEGER(i4) :: depth = 0
      LOGICAL :: is_leaf = .TRUE.
  END TYPE Octree_Node_Type
```

### `SpatialHash_Type` (lines 209–215)

```fortran
  TYPE, PUBLIC :: SpatialHash_Type
      REAL(wp) :: cell_size = 1.0_wp
      INTEGER(i4) :: table_size = 10007
      INTEGER(i4), ALLOCATABLE :: hash_table(:,:)
      INTEGER(i4), ALLOCATABLE :: cell_counts(:)
      INTEGER(i4) :: max_objects_per_cell = 100
  END TYPE SpatialHash_Type
```

### `PH_Cont_LD_Ref_Geom` (lines 221–228)

```fortran
  TYPE, PUBLIC :: PH_Cont_LD_Ref_Geom
      REAL(wp) :: X_slave_ref(3) = ZERO
      REAL(wp) :: X_master_ref(3) = ZERO
      REAL(wp) :: normal_ref(3) = [ZERO, ZERO, ONE]
      REAL(wp) :: tangent1(3) = [ONE, ZERO, ZERO]
      REAL(wp) :: tangent2(3) = [ZERO, ONE, ZERO]
      REAL(wp) :: gap_ref = ZERO
  END TYPE PH_Cont_LD_Ref_Geom
```

### `PH_Cont_LD_Curr_Geom` (lines 230–237)

```fortran
  TYPE, PUBLIC :: PH_Cont_LD_Curr_Geom
      REAL(wp) :: x_slave(3) = ZERO
      REAL(wp) :: x_master(3) = ZERO
      REAL(wp) :: u_slave(3) = ZERO
      REAL(wp) :: u_master(3) = ZERO
      REAL(wp) :: normal_curr(3) = [ZERO, ZERO, ONE]
      REAL(wp) :: gap_curr = ZERO
  END TYPE PH_Cont_LD_Curr_Geom
```

### `PH_Cont_LD_DeformGrad` (lines 239–242)

```fortran
  TYPE, PUBLIC :: PH_Cont_LD_DeformGrad
      REAL(wp) :: F_slave(3,3) = ZERO
      REAL(wp) :: F_master(3,3) = ZERO
  END TYPE PH_Cont_LD_DeformGrad
```

### `PH_Cont_LD_ContactState` (lines 244–248)

```fortran
  TYPE, PUBLIC :: PH_Cont_LD_ContactState
      INTEGER(i4) :: state = 0
      INTEGER(i4) :: state_prev = 0
      LOGICAL :: just_transitioned = .FALSE.
  END TYPE PH_Cont_LD_ContactState
```

### `PH_Cont_LD_Slip` (lines 250–255)

```fortran
  TYPE, PUBLIC :: PH_Cont_LD_Slip
      REAL(wp) :: slip_increment(3) = ZERO
      REAL(wp) :: accumulated_slip(3) = ZERO
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: slip_tolerance = 1.0e-9_wp
  END TYPE PH_Cont_LD_Slip
```

### `PH_Cont_LD_Force` (lines 257–260)

```fortran
  TYPE, PUBLIC :: PH_Cont_LD_Force
      REAL(wp) :: normal_force = ZERO
      REAL(wp) :: friction_force(3) = ZERO
  END TYPE PH_Cont_LD_Force
```

### `PH_Cont_LargeDef_State_Type` (lines 262–270)

```fortran
  TYPE, PUBLIC :: PH_Cont_LargeDef_State_Type
      TYPE(PH_Cont_LD_Ref_Geom)      :: ref
      TYPE(PH_Cont_LD_Curr_Geom)     :: curr
      TYPE(PH_Cont_LD_DeformGrad)    :: F
      TYPE(PH_Cont_LD_ContactState)  :: contact
      TYPE(PH_Cont_LD_Slip)          :: slip
      TYPE(PH_Cont_LD_Force)         :: force
      ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Cont_LargeDef_State_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Cont_AlgorithmFramework` | 282 | `SUBROUTINE PH_Cont_AlgorithmFramework(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_ConvergenceCheck` | 317 | `SUBROUTINE PH_Cont_ConvergenceCheck(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_SearchPairs` | 344 | `SUBROUTINE PH_Cont_SearchPairs(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_DetectPenetration` | 389 | `SUBROUTINE PH_Cont_DetectPenetration(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_CalculateGap` | 435 | `SUBROUTINE PH_Cont_CalculateGap(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_ApplyConstraints` | 465 | `SUBROUTINE PH_Cont_ApplyConstraints(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_UpdateFriction` | 514 | `SUBROUTINE PH_Cont_UpdateFriction(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_CheckConvergence` | 555 | `SUBROUTINE PH_Cont_CheckConvergence(ctx, out)` |
| SUBROUTINE | `PH_Cont_AlgorithmFramework_Impl_Structured` | 585 | `SUBROUTINE PH_Cont_AlgorithmFramework_Impl_Structured(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_AlgorithmFramework_Impl` | 704 | `SUBROUTINE PH_Cont_AlgorithmFramework_Impl(ctx, gap, normal_vector, &` |
| SUBROUTINE | `PH_Cont_Penetration_Algo` | 742 | `SUBROUTINE PH_Cont_Penetration_Algo(ctx, slave_coords, master_coords, &` |
| SUBROUTINE | `PH_Cont_Friction_Algo` | 805 | `SUBROUTINE PH_Cont_Friction_Algo(ctx, slip_velocity, slip_magnitude, dt, status)` |
| SUBROUTINE | `PH_Cont_Thermal_Contact` | 873 | `SUBROUTINE PH_Cont_Thermal_Contact(ctx, temperature_slave, temperature_master, &` |
| SUBROUTINE | `PH_Cont_Dynamic_Contact` | 923 | `SUBROUTINE PH_Cont_Dynamic_Contact(ctx, relative_velocity, contact_area, dt, status)` |
| SUBROUTINE | `PH_Cont_ComputeTangentVectors_Structured` | 979 | `SUBROUTINE PH_Cont_ComputeTangentVectors_Structured(in, out)` |
| SUBROUTINE | `PH_Cont_ComputeTangentVectors` | 1015 | `SUBROUTINE PH_Cont_ComputeTangentVectors(normal, tangent1, tangent2, status)` |
| FUNCTION | `PH_Cont_CrossProduct3` | 1037 | `FUNCTION PH_Cont_CrossProduct3(a, b) RESULT(c)` |
| SUBROUTINE | `PH_Cont_AdaptPenaltyParameter` | 1047 | `SUBROUTINE PH_Cont_AdaptPenaltyParameter(ctx, status)` |
| SUBROUTINE | `PH_Cont_ComputeContactForces_Structured` | 1087 | `SUBROUTINE PH_Cont_ComputeContactForces_Structured(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_ComputeContactForces` | 1123 | `SUBROUTINE PH_Cont_ComputeContactForces(ctx, slip_velocity, slip_magnitude, &` |
| SUBROUTINE | `PH_Cont_ComputeContactStiffness` | 1149 | `SUBROUTINE PH_Cont_ComputeContactStiffness(ctx, status)` |
| FUNCTION | `DELTA` | 1191 | `FUNCTION DELTA(i,j) RESULT(d)` |
| SUBROUTINE | `PH_Cont_UpdateConvergenceInfo` | 1203 | `SUBROUTINE PH_Cont_UpdateConvergenceInfo(ctx, status)` |
| SUBROUTINE | `PH_Cont_PerformQualityControl` | 1234 | `SUBROUTINE PH_Cont_PerformQualityControl(ctx, status)` |
| SUBROUTINE | `PH_Cont_ApplyImpactResponse_Structured` | 1271 | `SUBROUTINE PH_Cont_ApplyImpactResponse_Structured(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_ApplyImpactResponse` | 1296 | `SUBROUTINE PH_Cont_ApplyImpactResponse(ctx, impact_energy, status)` |
| SUBROUTINE | `PH_Cont_ComputeTemperatureEffect_Structured` | 1322 | `SUBROUTINE PH_Cont_ComputeTemperatureEffect_Structured(in, out)` |
| FUNCTION | `PH_Cont_ComputeTemperatureEffect` | 1345 | `FUNCTION PH_Cont_ComputeTemperatureEffect(temperature, status) RESULT(effect_factor)` |
| SUBROUTINE | `PH_Cont_AugLagForce` | 1378 | `SUBROUTINE PH_Cont_AugLagForce(in, out)` |
| SUBROUTINE | `PH_Cont_AugLagUpdate` | 1390 | `SUBROUTINE PH_Cont_AugLagUpdate(in, out)` |
| SUBROUTINE | `PH_Cont_LagrangeForce` | 1402 | `SUBROUTINE PH_Cont_LagrangeForce(in, out)` |
| SUBROUTINE | `PH_Cont_PenaltyForce` | 1410 | `SUBROUTINE PH_Cont_PenaltyForce(in, out)` |
| SUBROUTINE | `PH_Cont_PenaltyStiffness` | 1422 | `SUBROUTINE PH_Cont_PenaltyStiffness(in, out)` |
| SUBROUTINE | `PH_Cont_ComputeGap` | 1438 | `SUBROUTINE PH_Cont_ComputeGap(in, out)` |
| SUBROUTINE | `PH_Cont_ComputeNormal` | 1446 | `SUBROUTINE PH_Cont_ComputeNormal(in, out)` |
| SUBROUTINE | `PH_Cont_CheckState` | 1467 | `SUBROUTINE PH_Cont_CheckState(in, out)` |
| SUBROUTINE | `PH_Cont_FindNearestPoint` | 1473 | `SUBROUTINE PH_Cont_FindNearestPoint(in, out)` |
| SUBROUTINE | `PH_Cont_ComputePenetration` | 1497 | `SUBROUTINE PH_Cont_ComputePenetration(in, out)` |
| SUBROUTINE | `PH_Cont_Search_Opt` | 1507 | `SUBROUTINE PH_Cont_Search_Opt(search_algorithm, n_candidates, n_contacts, optimization_level, status)` |
| SUBROUTINE | `PH_Cont_Pair_Identify` | 1521 | `SUBROUTINE PH_Cont_Pair_Identify(slave_nodes, master_nodes, n_slave, n_master, tolerance, &` |
| SUBROUTINE | `PH_Cont_SpatialHash` | 1544 | `SUBROUTINE PH_Cont_SpatialHash(coords, n_points, cell_size, hash_table, status)` |
| SUBROUTINE | `PH_Cont_BoundingBox` | 1561 | `SUBROUTINE PH_Cont_BoundingBox(coords, n_points, bbox_min, bbox_max, status)` |
| SUBROUTINE | `AABB_Init` | 1579 | `SUBROUTINE AABB_Init(aabb, points, n_points, status)` |
| SUBROUTINE | `AABB_Expand` | 1602 | `SUBROUTINE AABB_Expand(aabb, other, status)` |
| SUBROUTINE | `BVH_Build_Recursive` | 1622 | `RECURSIVE SUBROUTINE BVH_Build_Recursive(nodes, objects_aabb, n_objects, start_idx, end_idx, &` |
| SUBROUTINE | `BVH_Build_Recursive_FromPack` | 1662 | `SUBROUTINE BVH_Build_Recursive_FromPack(nodes, objects_aabb, desc, status)` |
| SUBROUTINE | `BVH_Build` | 1671 | `SUBROUTINE BVH_Build(nodes, objects_aabb, n_objects, root_id, status)` |
| SUBROUTINE | `BVH_Query_Recursive` | 1698 | `RECURSIVE SUBROUTINE BVH_Query_Recursive(nodes, node_id, query_aabb, collision_ids, &` |
| SUBROUTINE | `BVH_Query_Collisions` | 1726 | `SUBROUTINE BVH_Query_Collisions(nodes, root_id, query_aabb, collision_ids, n_collisions, status, work_buf)` |
| SUBROUTINE | `SpatialHash_Init` | 1762 | `SUBROUTINE SpatialHash_Init(hash, cell_size, table_size, max_objects_per_cell, status)` |
| SUBROUTINE | `SpatialHash_Insert` | 1778 | `SUBROUTINE SpatialHash_Insert(hash, object_id, position, status)` |
| SUBROUTINE | `SpatialHash_Query` | 1797 | `SUBROUTINE SpatialHash_Query(hash, query_position, nearby_ids, n_nearby, status, work_buf)` |
| SUBROUTINE | `Octree_Build` | 1825 | `SUBROUTINE Octree_Build(nodes, objects_aabb, n_objects, max_depth, root_id, status)` |
| SUBROUTINE | `Octree_Query` | 1840 | `SUBROUTINE Octree_Query(nodes, root_id, query_aabb, result_ids, n_results, status)` |
| SUBROUTINE | `PH_Cont_ComputeSlip` | 1855 | `SUBROUTINE PH_Cont_ComputeSlip(in, out)` |
| SUBROUTINE | `PH_Cont_CoulombFriction` | 1861 | `SUBROUTINE PH_Cont_CoulombFriction(in, out)` |
| SUBROUTINE | `PH_Cont_ExponentialFriction` | 1877 | `SUBROUTINE PH_Cont_ExponentialFriction(in, out)` |
| SUBROUTINE | `PH_Cont_FrictionStiffness` | 1900 | `SUBROUTINE PH_Cont_FrictionStiffness(in, out)` |
| SUBROUTINE | `PH_Cont_PressureDependentFriction` | 1913 | `SUBROUTINE PH_Cont_PressureDependentFriction(in, out)` |
| SUBROUTINE | `PH_Cont_StickSlip` | 1930 | `SUBROUTINE PH_Cont_StickSlip(in, accumulated_slip, out)` |
| SUBROUTINE | `PH_Cont_VelocityDependentFriction` | 1967 | `SUBROUTINE PH_Cont_VelocityDependentFriction(in, out)` |
| SUBROUTINE | `PH_Cont_LargeDef_State_Init` | 1999 | `SUBROUTINE PH_Cont_LargeDef_State_Init(state, X_slave, X_master, u_slave, u_master, status)` |
| SUBROUTINE | `PH_Cont_LargeDef_Update_Normal` | 2031 | `SUBROUTINE PH_Cont_LargeDef_Update_Normal(state, F_master, status)` |
| SUBROUTINE | `PH_Cont_LargeDef_Update_Gap` | 2053 | `SUBROUTINE PH_Cont_LargeDef_Update_Gap(state, status)` |
| SUBROUTINE | `PH_Cont_LargeDef_Check_Sliding` | 2078 | `SUBROUTINE PH_Cont_LargeDef_Check_Sliding(state, u_slave_incr, u_master_incr, status)` |
| SUBROUTINE | `PH_Cont_LargeDef_Compute_Tangent` | 2104 | `SUBROUTINE PH_Cont_LargeDef_Compute_Tangent(state, penalty, K_contact, status)` |
| SUBROUTINE | `PH_Cont_LargeDef_Track_Boundary` | 2135 | `SUBROUTINE PH_Cont_LargeDef_Track_Boundary(state, surface_coords, n_surface_nodes, closest_node_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
