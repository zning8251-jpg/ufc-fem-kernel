!===============================================================================
! MODULE: MD_Mat_Registry
! LAYER:  L3_MD
! DOMAIN: Material / Registry
! ROLE:   Core - Unified Material Registry
! BRIEF:  Unified material registry for all 11 material families.
!         Replaces individual family-level registries.
!
! PURPOSE:
!   Solve the common problem: each material family has its own registry
!   This module provides a unified registry for all material families
!
! DESIGN:
!   - Polymorphic storage (use base class pointer)
!   - Hash table for O(1) lookup (future optimization)
!   - Thread-safe operations (future optimization)
!   - Support for all 11 material families
!
! CREATED: 2026-05-03 (Week 2 Day 1)
!===============================================================================
MODULE MD_Mat_Registry
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Registry entry TYPE
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Registry_Entry
    INTEGER(i4) :: mat_id                    ! Material ID (unique)
    INTEGER(i4) :: family_type               ! Family type (ELASTIC/PLASTIC/etc.)
    INTEGER(i4) :: sub_type                  ! Sub-type within family
    CLASS(MD_Mat_Desc), POINTER :: desc      ! Polymorphic pointer to descriptor
    LOGICAL :: is_active                     ! Entry is active
  END TYPE MD_Mat_Registry_Entry

  !-----------------------------------------------------------------------------
  ! Global registry
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MAT_REGISTRY_MAX_MATERIALS = 10000
  TYPE(MD_Mat_Registry_Entry), ALLOCATABLE, SAVE :: global_registry(:)
  INTEGER(i4), SAVE :: num_registered = 0
  LOGICAL, SAVE :: registry_initialized = .FALSE.

  !-----------------------------------------------------------------------------
  ! Public interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Registry_Init
  PUBLIC :: MD_Mat_Registry_Finalize
  PUBLIC :: MD_Mat_Registry_Register
  PUBLIC :: MD_Mat_Registry_Lookup
  PUBLIC :: MD_Mat_Registry_Remove
  PUBLIC :: MD_Mat_Registry_Get_Count
  PUBLIC :: MD_Mat_Registry_Access_Desc

CONTAINS

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Init
  ! Initialize the global material registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Init(status)
    ! [OUT] status - Error status
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (registry_initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Allocate registry
    ALLOCATE(global_registry(MD_MAT_REGISTRY_MAX_MATERIALS))

    ! Initialize entries
    global_registry(:)%mat_id = -1
    global_registry(:)%family_type = -1
    global_registry(:)%sub_type = -1
    global_registry(:)%is_active = .FALSE.
    NULLIFY(global_registry(:)%desc)

    num_registered = 0
    registry_initialized = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Registry_Init

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Finalize
  ! Finalize the global material registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Finalize(status)
    ! [OUT] status - Error status
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    IF (.NOT. registry_initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Nullify all pointers
    DO i = 1, MD_MAT_REGISTRY_MAX_MATERIALS
      IF (global_registry(i)%is_active) THEN
        NULLIFY(global_registry(i)%desc)
      END IF
    END DO

    ! Deallocate registry
    DEALLOCATE(global_registry)

    num_registered = 0
    registry_initialized = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Registry_Finalize

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Register
  ! Register a material in the global registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Register(mat_id, family_type, sub_type, &
                                       desc, status)
    ! [IN]  mat_id      - Material ID (unique)
    ! [IN]  family_type - Family type
    ! [IN]  sub_type    - Sub-type within family
    ! [IN]  desc        - Material descriptor (polymorphic)
    ! [OUT] status      - Error status
    INTEGER(i4), INTENT(IN) :: mat_id
    INTEGER(i4), INTENT(IN) :: family_type
    INTEGER(i4), INTENT(IN) :: sub_type
    CLASS(MD_Mat_Desc), TARGET, INTENT(IN) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: slot

    CALL init_error_status(status)

    ! Check initialization
    IF (.NOT. registry_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Registry not initialized"
      RETURN
    END IF

    ! Check if mat_id already exists
    CALL MD_Mat_Registry_Lookup(mat_id, slot, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Material ID already registered"
      RETURN
    END IF

    ! Find empty slot
    DO slot = 1, MD_MAT_REGISTRY_MAX_MATERIALS
      IF (.NOT. global_registry(slot)%is_active) THEN
        EXIT
      END IF
    END DO

    IF (slot > MD_MAT_REGISTRY_MAX_MATERIALS) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Registry full"
      RETURN
    END IF

    ! Register material
    global_registry(slot)%mat_id = mat_id
    global_registry(slot)%family_type = family_type
    global_registry(slot)%sub_type = sub_type
    global_registry(slot)%desc => desc
    global_registry(slot)%is_active = .TRUE.

    num_registered = num_registered + 1

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Registry_Register

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Lookup
  ! Lookup a material in the global registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Lookup(mat_id, slot, status)
    ! [IN]  mat_id - Material ID
    ! [OUT] slot   - Registry slot (if found)
    ! [OUT] status - Error status
    INTEGER(i4), INTENT(IN) :: mat_id
    INTEGER(i4), INTENT(OUT) :: slot
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Check initialization
    IF (.NOT. registry_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Registry not initialized"
      RETURN
    END IF

    ! Linear search (TODO: use hash table for O(1))
    DO i = 1, MD_MAT_REGISTRY_MAX_MATERIALS
      IF (global_registry(i)%is_active .AND. &
          global_registry(i)%mat_id == mat_id) THEN
        slot = i
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    ! Not found
    slot = -1
    status%status_code = IF_STATUS_INVALID
    status%message = "Material not found"
  END SUBROUTINE MD_Mat_Registry_Lookup

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Remove
  ! Remove a material from the global registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Remove(mat_id, status)
    ! [IN]  mat_id - Material ID
    ! [OUT] status - Error status
    INTEGER(i4), INTENT(IN) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: slot

    CALL init_error_status(status)

    ! Lookup material
    CALL MD_Mat_Registry_Lookup(mat_id, slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Remove material
    global_registry(slot)%mat_id = -1
    global_registry(slot)%family_type = -1
    global_registry(slot)%sub_type = -1
    NULLIFY(global_registry(slot)%desc)
    global_registry(slot)%is_active = .FALSE.

    num_registered = num_registered - 1

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Registry_Remove

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Get_Count
  ! Get the number of registered materials
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Get_Count(count)
    ! [OUT] count - Number of registered materials
    INTEGER(i4), INTENT(OUT) :: count

    count = num_registered
  END SUBROUTINE MD_Mat_Registry_Get_Count

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Access_Desc — return pointer to registered descriptor by mat_id
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Access_Desc(mat_id, dptr, status)
    INTEGER(i4), INTENT(IN) :: mat_id
    CLASS(MD_Mat_Desc), POINTER, INTENT(OUT) :: dptr
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: slot

    CALL init_error_status(status)
    NULLIFY(dptr)
    CALL MD_Mat_Registry_Lookup(mat_id, slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    IF (slot < 1 .OR. slot > MD_MAT_REGISTRY_MAX_MATERIALS) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Mat_Registry_Access_Desc: bad slot"
      RETURN
    END IF
    IF (.NOT. global_registry(slot)%is_active) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Mat_Registry_Access_Desc: inactive slot"
      RETURN
    END IF
    dptr => global_registry(slot)%desc
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Registry_Access_Desc

END MODULE MD_Mat_Registry
