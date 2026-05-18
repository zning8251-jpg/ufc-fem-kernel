!======================================================================
! MODULE:  MD_Int_Mapper
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Maps parsed contact config to mesh topology.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_Mapper
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE MD_Int_Def, ONLY: MD_Interaction_Desc, ContactPairType, SurfaceInteractionType
  IMPLICIT NONE
  PRIVATE

  !-------------------------------------------------------
  ! 公开接口
  !-------------------------------------------------------
  PUBLIC :: MD_Validate_ContactPair
  PUBLIC :: MD_Validate_SurfaceInteraction
  PUBLIC :: MD_Allocate_InteractionArrays
  PUBLIC :: MD_Map_InteractionToMesh
  PUBLIC :: MD_Build_InteractionMapping
  PUBLIC :: MD_Get_SurfaceNodeCount
  PUBLIC :: MD_Get_SurfaceElementCount

  !-------------------------------------------------------
  ! 内部支撑 TYPE
  !-------------------------------------------------------
  
  ! 表面集合类型
  TYPE, PUBLIC :: SurfaceSetType
    CHARACTER(len=64) :: surface_name
    INTEGER(i4) :: surface_id = 0
    INTEGER(i4) :: node_count = 0
    INTEGER(i4) :: element_count = 0
    INTEGER(i4), ALLOCATABLE :: node_indices(:)
    INTEGER(i4), ALLOCATABLE :: element_indices(:)
  END TYPE SurfaceSetType

  ! 接触映射结果类型
  TYPE, PUBLIC :: InteractionMappingType
    INTEGER(i4) :: pair_id = 0
    CHARACTER(len=64) :: pair_name
    INTEGER(i4) :: slave_node_count = 0
    INTEGER(i4) :: master_node_count = 0
    INTEGER(i4), ALLOCATABLE :: slave_nodes(:)
    INTEGER(i4), ALLOCATABLE :: master_nodes(:)
    LOGICAL :: is_valid = .FALSE.
  END TYPE InteractionMappingType

CONTAINS

  !===============================================================================
  ! 函数：验证接触对有效性
  !===============================================================================
  LOGICAL FUNCTION MD_Validate_ContactPair(pair, surfaces, num_surfaces) RESULT(valid)
    TYPE(ContactPairType), INTENT(IN) :: pair
    TYPE(SurfaceSetType), INTENT(IN) :: surfaces(:)
    INTEGER(i4), INTENT(IN) :: num_surfaces
    
    INTEGER(i4) :: i
    LOGICAL :: slave_found, master_found

    valid = .FALSE.
    slave_found = .FALSE.
    master_found = .FALSE.

    ! 检查从表面是否存在
    DO i = 1, num_surfaces
      IF (TRIM(surfaces(i)%surface_name) == TRIM(pair%slave_surface)) THEN
        slave_found = .TRUE.
      END IF
      IF (TRIM(surfaces(i)%surface_name) == TRIM(pair%master_surface)) THEN
        master_found = .TRUE.
      END IF
    END DO

    ! 两个表面都必须存在
    IF (.NOT. (slave_found .AND. master_found)) RETURN

    ! 基本验证
    IF (LEN_TRIM(pair%pair_name) == 0) RETURN
    IF (pair%contact_type < 1 .OR. pair%contact_type > 4) RETURN

    valid = .TRUE.

  END FUNCTION MD_Validate_ContactPair

  !===============================================================================
  ! 函数：验证表面相互作用有效性
  !===============================================================================
  LOGICAL FUNCTION MD_Validate_SurfaceInteraction(interaction, pairs, num_pairs) RESULT(valid)
    TYPE(SurfaceInteractionType), INTENT(IN) :: interaction
    TYPE(ContactPairType), INTENT(IN) :: pairs(:)
    INTEGER(i4), INTENT(IN) :: num_pairs
    
    INTEGER(i4) :: i
    LOGICAL :: pair_found

    valid = .FALSE.
    pair_found = .FALSE.

    ! 检查配对的接触对是否存在
    DO i = 1, num_pairs
      IF (TRIM(pairs(i)%pair_name) == TRIM(interaction%paired_surfaces)) THEN
        pair_found = .TRUE.
        EXIT
      END IF
    END DO

    IF (.NOT. pair_found) RETURN

    ! 基本验证
    IF (LEN_TRIM(interaction%interaction_name) == 0) RETURN
    IF (LEN_TRIM(interaction%normal_behavior) == 0) RETURN

    valid = .TRUE.

  END FUNCTION MD_Validate_SurfaceInteraction

  !===============================================================================
  ! 子程序：分配交互数组
  !===============================================================================
  SUBROUTINE MD_Allocate_InteractionArrays(desc, num_nodes, num_elements, status)
    TYPE(MD_Interaction_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: num_nodes, num_elements
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! 在 Mapper 中仅验证描述符有效性
    ! 实际的节点数组映射在 MD_Map_InteractionToMesh 中完成
    status%status_code = 0

    IF (desc%num_contact_pairs == 0) THEN
      status%status_code = 1
      RETURN
    END IF

  END SUBROUTINE MD_Allocate_InteractionArrays

  !===============================================================================
  ! 函数：获取表面节点计数
  !===============================================================================
  INTEGER(i4) FUNCTION MD_Get_SurfaceNodeCount(surface_name, surfaces, num_surfaces) RESULT(count)
    CHARACTER(len=*), INTENT(IN) :: surface_name
    TYPE(SurfaceSetType), INTENT(IN) :: surfaces(:)
    INTEGER(i4), INTENT(IN) :: num_surfaces
    
    INTEGER(i4) :: i

    count = 0

    DO i = 1, num_surfaces
      IF (TRIM(surfaces(i)%surface_name) == TRIM(surface_name)) THEN
        count = surfaces(i)%node_count
        RETURN
      END IF
    END DO

  END FUNCTION MD_Get_SurfaceNodeCount

  !===============================================================================
  ! 函数：获取表面单元计数
  !===============================================================================
  INTEGER(i4) FUNCTION MD_Get_SurfaceElementCount(surface_name, surfaces, num_surfaces) RESULT(count)
    CHARACTER(len=*), INTENT(IN) :: surface_name
    TYPE(SurfaceSetType), INTENT(IN) :: surfaces(:)
    INTEGER(i4), INTENT(IN) :: num_surfaces
    
    INTEGER(i4) :: i

    count = 0

    DO i = 1, num_surfaces
      IF (TRIM(surfaces(i)%surface_name) == TRIM(surface_name)) THEN
        count = surfaces(i)%element_count
        RETURN
      END IF
    END DO

  END FUNCTION MD_Get_SurfaceElementCount

  !===============================================================================
  ! 子程序：主映射引擎
  !===============================================================================
  SUBROUTINE MD_Map_InteractionToMesh(desc, contact_type, surfaces, num_surfaces, status)
    TYPE(MD_Interaction_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: contact_type
    TYPE(SurfaceSetType), INTENT(IN) :: surfaces(:)
    INTEGER(i4), INTENT(IN) :: num_surfaces
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, pair_idx, slave_idx, master_idx
    INTEGER(i4) :: slave_count, master_count

    status%status_code = 0

    ! 处理每个接触对
    DO pair_idx = 1, desc%num_contact_pairs
      ! 查找从表面和主表面的索引
      slave_idx = 0
      master_idx = 0

      DO i = 1, num_surfaces
        IF (TRIM(surfaces(i)%surface_name) == TRIM(desc%contact_pairs(pair_idx)%slave_surface)) THEN
          slave_idx = i
        END IF
        IF (TRIM(surfaces(i)%surface_name) == TRIM(desc%contact_pairs(pair_idx)%master_surface)) THEN
          master_idx = i
        END IF
      END DO

      ! 检查表面是否找到
      IF (slave_idx == 0 .OR. master_idx == 0) THEN
        status%status_code = 1
        RETURN
      END IF

      ! 根据接触类型执行验证
      SELECT CASE (contact_type)
      CASE (CONTACT_TYPE_S2S)
        ! Surface-to-Surface：验证两个表面都有节点
        slave_count = surfaces(slave_idx)%node_count
        master_count = surfaces(master_idx)%node_count
        IF (slave_count == 0 .OR. master_count == 0) THEN
          status%status_code = 1
          RETURN
        END IF

      CASE (CONTACT_TYPE_P2S)
        ! Point-to-Surface：验证两个表面都有节点
        slave_count = surfaces(slave_idx)%node_count
        master_count = surfaces(master_idx)%node_count
        IF (slave_count == 0 .OR. master_count == 0) THEN
          status%status_code = 1
          RETURN
        END IF

      END SELECT

    END DO

  END SUBROUTINE MD_Map_InteractionToMesh

  !===============================================================================
  ! 子程序：构建完整交互映射
  !===============================================================================
  SUBROUTINE MD_Build_InteractionMapping(desc, contact_pairs, num_pairs, &
                                         surfaces, num_surfaces, mappings, status)
    TYPE(MD_Interaction_Desc), INTENT(IN) :: desc
    TYPE(ContactPairType), INTENT(IN) :: contact_pairs(:)
    INTEGER(i4), INTENT(IN) :: num_pairs
    TYPE(SurfaceSetType), INTENT(IN) :: surfaces(:)
    INTEGER(i4), INTENT(IN) :: num_surfaces
    TYPE(InteractionMappingType), INTENT(OUT) :: mappings(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, slave_idx, master_idx, map_idx
    INTEGER(i4) :: slave_count, master_count

    status%status_code = 0
    map_idx = 0

    ! 为每个接触对构建映射
    DO i = 1, num_pairs
      map_idx = map_idx + 1

      IF (map_idx > SIZE(mappings)) THEN
        status%status_code = 1
        RETURN
      END IF

      ! 初始化映射结构
      mappings(map_idx)%pair_id = contact_pairs(i)%pair_id
      mappings(map_idx)%pair_name = contact_pairs(i)%pair_name

      ! 查找表面
      slave_idx = 0
      master_idx = 0

      DO j = 1, num_surfaces
        IF (TRIM(surfaces(j)%surface_name) == TRIM(contact_pairs(i)%slave_surface)) THEN
          slave_idx = j
        END IF
        IF (TRIM(surfaces(j)%surface_name) == TRIM(contact_pairs(i)%master_surface)) THEN
          master_idx = j
        END IF
      END DO

      ! 验证表面存在
      IF (slave_idx == 0 .OR. master_idx == 0) THEN
        mappings(map_idx)%is_valid = .FALSE.
        status%status_code = 1
        CYCLE
      END IF

      ! 分配和填充节点索引
      slave_count = surfaces(slave_idx)%node_count
      master_count = surfaces(master_idx)%node_count

      IF (.NOT. ALLOCATED(mappings(map_idx)%slave_nodes)) THEN
        ALLOCATE(mappings(map_idx)%slave_nodes(slave_count), STAT=status%status_code)
        IF (status%status_code /= 0) RETURN
      END IF

      IF (.NOT. ALLOCATED(mappings(map_idx)%master_nodes)) THEN
        ALLOCATE(mappings(map_idx)%master_nodes(master_count), STAT=status%status_code)
        IF (status%status_code /= 0) RETURN
      END IF

      ! 复制节点索引
      DO j = 1, slave_count
        IF (ALLOCATED(surfaces(slave_idx)%node_indices)) THEN
          mappings(map_idx)%slave_nodes(j) = surfaces(slave_idx)%node_indices(j)
        END IF
      END DO

      DO j = 1, master_count
        IF (ALLOCATED(surfaces(master_idx)%node_indices)) THEN
          mappings(map_idx)%master_nodes(j) = surfaces(master_idx)%node_indices(j)
        END IF
      END DO

      ! 设置计数和有效标志
      mappings(map_idx)%slave_node_count = slave_count
      mappings(map_idx)%master_node_count = master_count
      mappings(map_idx)%is_valid = .TRUE.

    END DO

  END SUBROUTINE MD_Build_InteractionMapping

END MODULE MD_Int_Mapper