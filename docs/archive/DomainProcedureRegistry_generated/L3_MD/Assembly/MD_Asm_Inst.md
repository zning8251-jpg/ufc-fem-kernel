# `MD_Asm_Inst.f90`

- **Source**: `L3_MD/Assembly/MD_Asm_Inst.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Asm_Inst`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Asm_Inst`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Asm_Inst`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Assembly/MD_Asm_Inst.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_InstanceDef` (lines 30–68)

```fortran
  TYPE :: UF_InstanceDef
        CHARACTER(LEN=MD_ASM_MAX_INSTANCE_NAME) :: name = ""
        INTEGER(i4) :: id = 0
        
        ! Reference to parent Part
        CHARACTER(LEN=MAX_PART_NAME) :: part_name = ""
        INTEGER(i4) :: part_id = 0    !! Slot / id in UF_PartDef list (see instance_bind_part)
        
        ! Transformation from Part to Assembly coordinate system
        REAL(wp) :: translation(3) = 0.0_wp       ! Translation vector
        REAL(wp) :: rotation_matrix(3,3) = 0.0_wp ! Rotation matrix
        REAL(wp) :: rotation_axis(3) = 0.0_wp     ! Rotation axis (for axis-angle)
        REAL(wp) :: rotation_angle = 0.0_wp       ! Rotation angle (radians)
        REAL(wp) :: rotation_point(3) = 0.0_wp    ! Point on rotation axis
        
        ! Global numbering offsets (assigned during Assembly)
        INTEGER(i4) :: node_offset = 0            ! Offset for global node IDs
        INTEGER(i4) :: elem_offset = 0            ! Offset for global element IDs
        INTEGER(i4) :: dof_offset = 0             ! Offset for global DOF numbers
        
        ! Status flags
        LOGICAL :: is_dependent = .FALSE.         ! True if part of dependent instance
        LOGICAL :: is_suppressed = .FALSE.        ! True if instance is suppressed

        ! get_node_coords / get_local_node_index: optional 3rd arg TYPE(UF_PartDef) (or pointer
        ! actual to TARGET dummy). Omit part → zeros / 0; pass bound part for real geometry.
        
    CONTAINS
        PROCEDURE :: init => instance_init
        PROCEDURE :: bind_part => instance_bind_part
        PROCEDURE :: set_translation => instance_set_translation
        PROCEDURE :: set_rotation => instance_set_rotation
        PROCEDURE :: set_rotation_from_points => instance_set_rotation_from_points
        PROCEDURE :: transform_point => instance_transform_point
        PROCEDURE :: get_global_node_id => instance_get_global_node_id
        PROCEDURE :: get_global_elem_id => instance_get_global_elem_id
        PROCEDURE :: get_node_coords => instance_get_node_coords
        PROCEDURE :: get_local_node_index => instance_get_local_node_index
    END TYPE UF_InstanceDef
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `instance_init` | 93 | `SUBROUTINE instance_init(this, name, part_name)` |
| SUBROUTINE | `instance_bind_part` | 127 | `SUBROUTINE instance_bind_part(this, part)` |
| SUBROUTINE | `instance_set_translation` | 140 | `SUBROUTINE instance_set_translation(this, tx, ty, tz)` |
| SUBROUTINE | `instance_set_rotation` | 160 | `SUBROUTINE instance_set_rotation(this, point, axis, angle)` |
| SUBROUTINE | `instance_set_rotation_from_points` | 206 | `SUBROUTINE instance_set_rotation_from_points(this, p1, p2, angle)` |
| FUNCTION | `instance_transform_point` | 222 | `FUNCTION instance_transform_point(this, local_coords) RESULT(global_coords)` |
| FUNCTION | `instance_get_global_node_id` | 240 | `FUNCTION instance_get_global_node_id(this, local_id) RESULT(global_id)` |
| FUNCTION | `instance_get_global_elem_id` | 259 | `FUNCTION instance_get_global_elem_id(this, local_id) RESULT(global_id)` |
| FUNCTION | `instance_get_node_coords` | 277 | `FUNCTION instance_get_node_coords(this, local_node_idx, part) RESULT(coords)` |
| FUNCTION | `instance_get_local_node_index` | 301 | `FUNCTION instance_get_local_node_index(this, node_id, part) RESULT(local_node_idx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
