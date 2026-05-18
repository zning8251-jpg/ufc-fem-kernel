!===============================================================================
! MODULE:  MD_Asm_Inst
! LAYER:   L3_MD
! DOMAIN:  Assembly
! ROLE:    _Def
! BRIEF:   Instance descriptor (Desc) — Part placement in Assembly.
!          x_global = R * (x_local - p) + p + t.  Abaqus *INSTANCE.
! Pilot:   ufc-layer-l3-l4-l5-pilot.md — 与 **MD_Assembly_Domain%instances** 对齐
!          的 L3 冷 Desc。L3→L5 **实例/面/集** 金线见 **`MD_Assembly_SyncFromLegacy`**
!          + **`MD_Model_Brg`**；**`MD_AssemRT_Brg`** 仅为 **CSR/Triplet 数学转发**（非本域容器）。
!===============================================================================

MODULE MD_Asm_Inst
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Part_Mgr,  ONLY: UF_PartDef, MAX_PART_NAME
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: UF_InstanceDef, MD_ASM_MAX_INSTANCE_NAME

  INTEGER(i4), PARAMETER :: MD_ASM_MAX_INSTANCE_NAME = 80_i4
  !-- backward compat alias
  INTEGER(i4), PARAMETER :: MAX_INSTANCE_NAME = MD_ASM_MAX_INSTANCE_NAME

  !---------------------------------------------------------------------------
  ! TYPE:  UF_InstanceDef
  ! KIND:  Desc
  ! DESC:  Instance descriptor — Part reference + rigid-body transform
  !---------------------------------------------------------------------------
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
    
CONTAINS

    !---------------------------------------------------------------------------
    ! FUNCTION:  uf_part_def_node_count
    ! PHASE:     Query
    ! PURPOSE:   Effective node count on UF_PartDef (num_nodes / nNodes / SIZE)
    !---------------------------------------------------------------------------
    PURE INTEGER(i4) FUNCTION uf_part_def_node_count(part) RESULT(n)
      TYPE(UF_PartDef), INTENT(IN) :: part
      n = 0_i4
      IF (part%num_nodes > 0_i4) THEN
        n = part%num_nodes
      ELSE IF (part%nNodes > 0_i4) THEN
        n = part%nNodes
      END IF
      IF (n == 0_i4 .AND. ALLOCATED(part%nodes)) n = INT(SIZE(part%nodes), KIND=i4)
    END FUNCTION uf_part_def_node_count

    !---------------------------------------------------------------------------
    ! SUBROUTINE: instance_init
    ! PHASE:      Init
    ! PURPOSE:    Initialize instance with name and parent part reference
    !---------------------------------------------------------------------------
    SUBROUTINE instance_init(this, name, part_name)
        CLASS(UF_InstanceDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        CHARACTER(LEN=*), INTENT(IN) :: part_name
        INTEGER(i4) :: i
        
        this%name = TRIM(name)
        this%part_name = TRIM(part_name)
        this%cfg%id = 0_i4
        this%translation = 0.0_wp

        ! Initialize rotation matrix to identity
        this%rotation_matrix = 0.0_wp
        DO i = 1, 3
            this%rotation_matrix(i,i) = 1.0_wp
        END DO
        
        this%rotation_axis = 0.0_wp
        this%rotation_axis(3) = 1.0_wp  ! Default Z-axis
        this%rotation_angle = 0.0_wp
        this%rotation_point = 0.0_wp
        
        this%node_offset = 0
        this%elem_offset = 0
        this%dof_offset = 0
        this%is_dependent = .FALSE.
        this%is_suppressed = .FALSE.
    END SUBROUTINE instance_init

    !---------------------------------------------------------------------------
    ! SUBROUTINE: instance_bind_part
    ! PHASE:      Init
    ! PURPOSE:    Bind instance to resolved UF_PartDef (name + id)
    !---------------------------------------------------------------------------
    SUBROUTINE instance_bind_part(this, part)
        CLASS(UF_InstanceDef), INTENT(INOUT) :: this
        TYPE(UF_PartDef), TARGET, INTENT(IN) :: part

        this%part_name = TRIM(part%name)
        this%part_id   = part%cfg%id
    END SUBROUTINE instance_bind_part
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: instance_set_translation
    ! PHASE:      Mutate
    ! PURPOSE:    Set translation vector (tx, ty, optional tz)
    !---------------------------------------------------------------------------
    SUBROUTINE instance_set_translation(this, tx, ty, tz)
        CLASS(UF_InstanceDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: tx, ty
        REAL(wp), INTENT(IN), OPTIONAL :: tz
        
        this%translation(1) = tx
        this%translation(2) = ty
        IF (PRESENT(tz)) THEN
            this%translation(3) = tz
        ELSE
            this%translation(3) = 0.0_wp
        END IF
        
    END SUBROUTINE instance_set_translation
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: instance_set_rotation
    ! PHASE:      Mutate
    ! PURPOSE:    Set rotation via axis-angle; builds Rodrigues rotation matrix
    !---------------------------------------------------------------------------
    SUBROUTINE instance_set_rotation(this, point, axis, angle)
        CLASS(UF_InstanceDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: point(3)    ! Point on rotation axis
        REAL(wp), INTENT(IN) :: axis(3)     ! Rotation axis direction
        REAL(wp), INTENT(IN) :: angle       ! Rotation angle in degrees
        REAL(wp) :: c, s, t, axis_norm(3), norm
        REAL(wp) :: angle_rad

        this%rotation_point = point

        ! Normalize axis (degenerate → +Z); store **unit** axis in this%rotation_axis
        norm = SQRT(axis(1)**2 + axis(2)**2 + axis(3)**2)
        IF (norm < 1.0E-14_wp) THEN
            axis_norm = (/ 0.0_wp, 0.0_wp, 1.0_wp /)
        ELSE
            axis_norm = axis / norm
        END IF
        this%rotation_axis = axis_norm

        angle_rad = angle * (4.0_wp * ATAN(1.0_wp) / 180.0_wp)
        this%rotation_angle = angle_rad

        ! Build rotation matrix (Rodrigues' formula)
        c = COS(angle_rad)
        s = SIN(angle_rad)
        t = 1.0_wp - c
        
        this%rotation_matrix(1,1) = t*axis_norm(1)*axis_norm(1) + c
        this%rotation_matrix(1,2) = t*axis_norm(1)*axis_norm(2) - s*axis_norm(3)
        this%rotation_matrix(1,3) = t*axis_norm(1)*axis_norm(3) + s*axis_norm(2)
        
        this%rotation_matrix(2,1) = t*axis_norm(1)*axis_norm(2) + s*axis_norm(3)
        this%rotation_matrix(2,2) = t*axis_norm(2)*axis_norm(2) + c
        this%rotation_matrix(2,3) = t*axis_norm(2)*axis_norm(3) - s*axis_norm(1)
        
        this%rotation_matrix(3,1) = t*axis_norm(1)*axis_norm(3) - s*axis_norm(2)
        this%rotation_matrix(3,2) = t*axis_norm(2)*axis_norm(3) + s*axis_norm(1)
        this%rotation_matrix(3,3) = t*axis_norm(3)*axis_norm(3) + c
        
    END SUBROUTINE instance_set_rotation

    !---------------------------------------------------------------------------
    ! SUBROUTINE: instance_set_rotation_from_points
    ! PHASE:      Mutate
    ! PURPOSE:    Set rotation from two points defining axis + angle (degrees)
    !---------------------------------------------------------------------------
    SUBROUTINE instance_set_rotation_from_points(this, p1, p2, angle)
        CLASS(UF_InstanceDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: p1(3)
        REAL(wp), INTENT(IN) :: p2(3)
        REAL(wp), INTENT(IN) :: angle
        REAL(wp) :: axis(3)

        axis = p2 - p1
        CALL this%set_rotation(p1, axis, angle)
    END SUBROUTINE instance_set_rotation_from_points
    
    !---------------------------------------------------------------------------
    ! FUNCTION:   instance_transform_point
    ! PHASE:      Query
    ! PURPOSE:    Transform local coords to global via rotation + translation
    !---------------------------------------------------------------------------
    FUNCTION instance_transform_point(this, local_coords) RESULT(global_coords)
        CLASS(UF_InstanceDef), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: local_coords(3)
        REAL(wp) :: global_coords(3)
        REAL(wp) :: temp(3)
        
        ! First translate to rotation point, rotate, then translate back and add translation
        temp = local_coords - this%rotation_point
        global_coords = MATMUL(this%rotation_matrix, temp)
        global_coords = global_coords + this%rotation_point + this%translation
        
    END FUNCTION instance_transform_point
    
    !---------------------------------------------------------------------------
    ! FUNCTION:   instance_get_global_node_id
    ! PHASE:      Query
    ! PURPOSE:    Map part-local node ID to global assembly node ID
    !---------------------------------------------------------------------------
    FUNCTION instance_get_global_node_id(this, local_id) RESULT(global_id)
        CLASS(UF_InstanceDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: local_id
        INTEGER(i4) :: global_id

        ! local_id: 1-based index in part-local ordering (UF assembly pass); invalid → -1
        IF (local_id < 1_i4) THEN
          global_id = -1_i4
        ELSE
          global_id = local_id + this%node_offset
        END IF

    END FUNCTION instance_get_global_node_id
    
    !---------------------------------------------------------------------------
    ! FUNCTION:   instance_get_global_elem_id
    ! PHASE:      Query
    ! PURPOSE:    Map part-local element ID to global assembly element ID
    !---------------------------------------------------------------------------
    FUNCTION instance_get_global_elem_id(this, local_id) RESULT(global_id)
        CLASS(UF_InstanceDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: local_id
        INTEGER(i4) :: global_id

        IF (local_id < 1_i4) THEN
          global_id = -1_i4
        ELSE
          global_id = local_id + this%elem_offset
        END IF

    END FUNCTION instance_get_global_elem_id
    
    !---------------------------------------------------------------------------
    ! FUNCTION:   instance_get_node_coords
    ! PHASE:      Query
    ! PURPOSE:    Get node coords in global system (optional part binding)
    !---------------------------------------------------------------------------
    FUNCTION instance_get_node_coords(this, local_node_idx, part) RESULT(coords)
        CLASS(UF_InstanceDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: local_node_idx
        TYPE(UF_PartDef), INTENT(IN), OPTIONAL, TARGET :: part
        REAL(wp) :: coords(3)
        INTEGER(i4) :: n

        coords = 0.0_wp
        IF (.NOT. PRESENT(part)) RETURN
        IF (.NOT. ALLOCATED(part%nodes)) RETURN
        IF (this%part_id > 0_i4 .AND. part%cfg%id > 0_i4) THEN
          IF (this%part_id /= part%cfg%id) RETURN
        END IF
        n = uf_part_def_node_count(part)
        IF (n < 1_i4) RETURN
        IF (local_node_idx < 1_i4 .OR. local_node_idx > n) RETURN
        coords = this%transform_point(part%nodes(local_node_idx)%coords)
    END FUNCTION instance_get_node_coords

    !---------------------------------------------------------------------------
    ! FUNCTION:   instance_get_local_node_index
    ! PHASE:      Query
    ! PURPOSE:    Reverse-lookup: global node_id -> part-local index
    !---------------------------------------------------------------------------
    FUNCTION instance_get_local_node_index(this, node_id, part) RESULT(local_node_idx)
        CLASS(UF_InstanceDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: node_id
        TYPE(UF_PartDef), INTENT(IN), OPTIONAL, TARGET :: part
        INTEGER(i4) :: local_node_idx
        INTEGER(i4) :: i, n

        local_node_idx = 0_i4
        IF (.NOT. PRESENT(part)) RETURN
        IF (.NOT. ALLOCATED(part%nodes)) RETURN
        IF (this%part_id > 0_i4 .AND. part%cfg%id > 0_i4) THEN
          IF (this%part_id /= part%cfg%id) RETURN
        END IF
        n = uf_part_def_node_count(part)
        DO i = 1, n
          IF (part%nodes(i)%cfg%id == node_id) THEN
            local_node_idx = i
            RETURN
          END IF
        END DO
    END FUNCTION instance_get_local_node_index
    
END MODULE MD_Asm_Inst