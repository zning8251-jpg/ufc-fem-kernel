!===============================================================================
! MODULE: RT_Elem_Sect
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Util — Section registry and material resolution bridge
! BRIEF:  P0 Init/Populate + P1 GetMatDesc for section ↔ material mapping.
! **W2**：**截面→材料** 解析桥；取 **`MD_Sect_*`** / **`MD_Mat_*`** 与单元 **`mat_id`** 金线一致（衔接 **W1**）。
!===============================================================================
MODULE RT_Elem_Sect
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_Sect_Def, ONLY: MD_Sect_Registry, MD_Sect_Desc
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Elem_Sect_Init
  PUBLIC :: RT_Elem_Sect_GetMatDesc
  PUBLIC :: RT_Elem_Sect_Populate
  PUBLIC :: RT_Elem_Sect_Finalize
  
CONTAINS
  !=============================================================================
  ! Initialize section registry
  !=============================================================================
  SUBROUTINE RT_Elem_Sect_Init(registry, max_sections, status)
    TYPE(MD_Sect_Registry), INTENT(INOUT) :: registry
    INTEGER(i4), INTENT(IN) :: max_sections
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (max_sections <= 0_i4) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='RT_Elem_Sect_Init: max_sections must be > 0')
      RETURN
    END IF
    
    CALL registry%Init(max_sections)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Elem_Sect_Init
  
  !=============================================================================
  ! Get material descriptor by section ID
  !=============================================================================
  FUNCTION RT_Elem_Sect_GetMatDesc(registry, sect_id, status) RESULT(mat_desc)
    TYPE(MD_Sect_Registry), INTENT(IN) :: registry
    INTEGER(i4), INTENT(IN) :: sect_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CLASS(MD_Mat_Desc), POINTER :: mat_desc => NULL()
    
    INTEGER(i4) :: sect_idx
    
    CALL init_error_status(status)
    mat_desc => NULL()
    
    ! Lookup section index
    sect_idx = registry%GetSectIdx(sect_id)
    IF (sect_idx == 0_i4) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='RT_Elem_Sect_GetMatDesc: section_id not found')
      RETURN
    END IF
    
    ! Get material descriptor pointer
    mat_desc => registry%sections(sect_idx)%mat_desc
    IF (.NOT. ASSOCIATED(mat_desc)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='RT_Elem_Sect_GetMatDesc: mat_desc not associated')
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
  END FUNCTION RT_Elem_Sect_GetMatDesc
  
  !=============================================================================
  ! Populate section registry from L3_MD container (L3→L5 bridge)
  !=============================================================================
  SUBROUTINE RT_Elem_Sect_Populate(registry, l3_registry, status)
    !! Implementation: Complete L3_MD → L5_RT data bridge
    !! 
    !! Workflow:
    !!   1. Query L3 registry for section count
    !!   2. Initialize L5 registry with same capacity
    !!   3. Deep copy each section descriptor
    !!   4. Validate all material associations
    !!   5. Return populated registry
    
    TYPE(MD_Sect_Registry), INTENT(IN) :: l3_registry
    TYPE(MD_Sect_Registry), INTENT(INOUT) :: registry
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n_sect, capacity
    TYPE(MD_Sect_Desc), POINTER :: src_sect => NULL()
    
    CALL init_error_status(status)
    
    ! 1. Validate L3 registry
    IF (.NOT. ALLOCATED(l3_registry%sections)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='RT_Elem_Sect_Populate: L3 registry sections not allocated')
      RETURN
    END IF
    
    ! 2. Get section count from L3
    n_sect = l3_registry%nsections
    capacity = l3_registry%capacity
    
    IF (n_sect <= 0_i4) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='RT_Elem_Sect_Populate: L3 registry has no sections')
      RETURN
    END IF
    
    ! 3. Initialize L5 registry with same capacity
    IF (.NOT. ALLOCATED(registry%sections)) THEN
      CALL registry%Init(capacity)
    END IF
    
    ! 4. Copy sections from L3 to L5
    DO i = 1, n_sect
      ! Get pointer to L3 section
      src_sect => l3_registry%sections(i)
      
      ! Add to L5 registry
      CALL registry%AddSection(src_sect, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        status%message = 'RT_Elem_Sect_Populate: Failed to add section '//&
                        TRIM(ADJUSTL(ITOCHAR(i)))//': '//TRIM(status%message)
        RETURN
      END IF
      
      ! Verify association
      IF (.NOT. ASSOCIATED(registry%sections(i)%mat_desc)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='RT_Elem_Sect_Populate: Section '//&
                    TRIM(ADJUSTL(ITOCHAR(i)))//' mat_desc not associated')
        RETURN
      END IF
    END DO
    
    ! 5. Sync metadata
    registry%nsections = n_sect
    
    status%status_code = IF_STATUS_OK
    status%message = 'RT_Elem_Sect_Populate: Successfully populated '//&
                    TRIM(ADJUSTL(ITOCHAR(n_sect)))//' sections'
    
  END SUBROUTINE RT_Elem_Sect_Populate
  
  !=============================================================================
  ! Finalize section registry (cleanup resources)
  !=============================================================================
  SUBROUTINE RT_Elem_Sect_Finalize(registry, status)
    TYPE(MD_Sect_Registry), INTENT(INOUT) :: registry
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    CALL registry%Clear()
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Elem_Sect_Finalize
  
END MODULE RT_Elem_Sect