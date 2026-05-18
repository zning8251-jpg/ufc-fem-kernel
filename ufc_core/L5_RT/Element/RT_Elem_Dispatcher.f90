!===============================================================================
! MODULE: RT_Elem_Dispatcher
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Ctrl — Pure registry-driven dispatcher for element families
! BRIEF:  Routes family_id → L4 PH kernel via RT_Elem_Dispatch_Table.
!         L5 does NOT hold physics — only dispatch table and routing context.
! **W2**：**`family_id` → `RT_Elem_Dispatch_Table` → L4**；无本构；与 **`RT_Elem_Def`** / **`PH_Elem_Core`** 族入口一致。
!===============================================================================
MODULE RT_Elem_Dispatcher
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR
  USE RT_Elem_Def, ONLY: RT_Elem_Ctx, RT_Elem_State, &
                          RT_Elem_Router_Entry, &
                          RT_Elem_Compute_Proc, &
                          RT_Elem_Dispatch_Table
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Elem_Dispatcher_Init
  PUBLIC :: RT_Elem_Dispatcher_Run
  PUBLIC :: RT_Elem_Dispatcher_Register
  PUBLIC :: RT_Elem_Dispatcher_GetCount
  PUBLIC :: RT_Elem_Dispatcher_Unregister

  !-- Standard L4 Element Family IDs (aligned with PH_ElemReg_Algo)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ELEM_FAMILY_SOLID3D  = 1_i4  ! 3D solid elements
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ELEM_FAMILY_SOLID2D  = 2_i4  ! 2D plane stress/strain
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ELEM_FAMILY_SHELL    = 3_i4  ! Shell elements
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ELEM_FAMILY_BEAM     = 4_i4  ! Beam elements
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ELEM_FAMILY_SPECIAL  = 5_i4  ! Special (spring/dash/mass)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ELEM_FAMILY_ACOUSTIC = 6_i4  ! Acoustic elements
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ELEM_N_STD_FAMILIES  = 6_i4  ! Count of standard families
  
CONTAINS
  !=============================================================================
  ! Initialize router table with standard element families
  !=============================================================================
  SUBROUTINE RT_Elem_Dispatcher_Init(router_table, max_families, status)
    TYPE(RT_Elem_Router_Entry), ALLOCATABLE, INTENT(OUT) :: router_table(:)
    INTEGER(i4), INTENT(IN) :: max_families
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    CALL init_error_status(status)
    
    IF (max_families <= 0_i4) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'RT_Elem_Dispatcher_Init: max_families must be > 0'
      RETURN
    END IF
    
    ALLOCATE(router_table(max_families))
    DO i = 1, max_families
      router_table(i)%cfg%family_id = 0_i4
      NULLIFY(router_table(i)%compute)
    END DO
    
    ! Register standard element families (routing to L4_PH kernels)
    ! Family IDs aligned with PH_ElemReg_Algo definitions:
    !   1=Solid3D, 2=Solid2D, 3=Shell, 4=Beam, 5=Special, 6=Acoustic
    ! Compute procedure pointers are set to NULL and must be attached
    ! during Populate phase via RT_Elem_Dispatcher_Register.
    DO i = 1, MIN(RT_ELEM_N_STD_FAMILIES, max_families)
      router_table(i)%cfg%family_id = i
    END DO
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Elem_Dispatcher_Init
  
  SUBROUTINE RT_Elem_Dispatcher_Run(state, ctx, router_table, status)
    TYPE(RT_Elem_State),  INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx),    INTENT(IN)    :: ctx
    TYPE(RT_Elem_Router_Entry), INTENT(IN) :: router_table(:)
    TYPE(ErrorStatusType), INTENT(OUT)  :: status

    INTEGER(i4) :: i, n_families, elem_family
    LOGICAL :: found
    CHARACTER(LEN=32) :: buf

    CALL init_error_status(status)

    elem_family = ctx%base%itr%current_elem
    found = .FALSE.
    n_families = SIZE(router_table)

    DO i = 1, n_families
      IF (router_table(i)%cfg%family_id == elem_family) THEN
        IF (ASSOCIATED(router_table(i)%compute)) THEN
          CALL router_table(i)%compute(state, ctx, status)
          found = .TRUE.
          EXIT
        ELSE
          WRITE(buf, '(I0)') elem_family
          CALL init_error_status(status, IF_STATUS_ERROR, &
               message='RT_Elem_Dispatcher_Run: Kernel not associated, family='// &
               TRIM(buf))
          RETURN
        END IF
      END IF
    END DO

    IF (.NOT. found) THEN
      WRITE(buf, '(I0)') elem_family
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='RT_Elem_Dispatcher_Run: Unregistered family='//TRIM(buf))
      RETURN
    END IF

  END SUBROUTINE RT_Elem_Dispatcher_Run
  
  !=============================================================================
  ! Register custom compute procedure for user-defined element family
  !=============================================================================
  SUBROUTINE RT_Elem_Dispatcher_Register(router_table, family_id, compute_proc, status)
    TYPE(RT_Elem_Router_Entry), ALLOCATABLE, INTENT(INOUT) :: router_table(:)
    INTEGER(i4), INTENT(IN) :: family_id
    PROCEDURE(RT_Elem_Compute_Proc) :: compute_proc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n, new_size
    TYPE(RT_Elem_Router_Entry), ALLOCATABLE :: tmp(:)
    
    CALL init_error_status(status)
    
    ! Check if already registered
    IF (ALLOCATED(router_table)) THEN
      DO i = 1, SIZE(router_table)
        IF (router_table(i)%cfg%family_id == family_id) THEN
          router_table(i)%compute => compute_proc
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END DO
    END IF
    
    ! Add new entry
    n = 0
    IF (ALLOCATED(router_table)) n = SIZE(router_table)
    new_size = n + 1
    
    ALLOCATE(tmp(new_size))
    IF (n > 0) tmp(1:n) = router_table(:)
    
    tmp(new_size)%cfg%family_id = family_id
    tmp(new_size)%compute => compute_proc
    
    IF (ALLOCATED(router_table)) DEALLOCATE(router_table)
    ALLOCATE(router_table(new_size))
    router_table = tmp
    
    DEALLOCATE(tmp)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Elem_Dispatcher_Register
  
  !=============================================================================
  ! Get number of registered families
  !=============================================================================
  FUNCTION RT_Elem_Dispatcher_GetCount(router_table) RESULT(count)
    TYPE(RT_Elem_Router_Entry), INTENT(IN) :: router_table(:)
    INTEGER(i4) :: count
    count = SIZE(router_table)
  END FUNCTION RT_Elem_Dispatcher_GetCount
  
  !=============================================================================
  ! Unregister element family (cleanup / dynamic reconfiguration)
  !=============================================================================
  SUBROUTINE RT_Elem_Dispatcher_Unregister(router_table, family_id, status)
    TYPE(RT_Elem_Router_Entry), ALLOCATABLE, INTENT(INOUT) :: router_table(:)
    INTEGER(i4), INTENT(IN) :: family_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, j, n, new_size
    TYPE(RT_Elem_Router_Entry), ALLOCATABLE :: tmp(:)
    
    CALL init_error_status(status)
    
    IF (.NOT. ALLOCATED(router_table)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='RT_Elem_Dispatcher_Unregister: router_table not allocated')
      RETURN
    END IF
    
    ! Find family to remove
    DO i = 1, SIZE(router_table)
      IF (router_table(i)%cfg%family_id == family_id) THEN
        ! Found - create new table without this entry
        n = SIZE(router_table)
        new_size = n - 1
        
        IF (new_size <= 0) THEN
          DEALLOCATE(router_table)
        ELSE
          ALLOCATE(tmp(new_size))
          j = 0
          DO i = 1, n
            IF (router_table(i)%cfg%family_id /= family_id) THEN
              j = j + 1
              tmp(j) = router_table(i)
            END IF
          END DO
          
          DEALLOCATE(router_table)
          ALLOCATE(router_table(new_size))
          router_table = tmp
          DEALLOCATE(tmp)
        END IF
        
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO
    
    ! Not found
    status%status_code = IF_STATUS_ERROR
    status%message = 'RT_Elem_Dispatcher_Unregister: Family not found'
  END SUBROUTINE RT_Elem_Dispatcher_Unregister
  
END MODULE RT_Elem_Dispatcher