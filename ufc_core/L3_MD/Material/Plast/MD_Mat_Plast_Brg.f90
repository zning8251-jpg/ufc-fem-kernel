!===============================================================================
! MODULE: MD_Mat_Plast_Brg
! LAYER:  L3_MD
! DOMAIN: Material / Plast
! ROLE:   Brg (Bridge)
! BRIEF:  Bridge module for L3_MD → L4_PH data transfer (plastic materials).
!         Implements the adapter pattern for cross-layer communication.
!         Follows UFC architecture principle: single-direction dependency (L3→L4)
!
!         Design principle:
!         - L3_MD is the single source of truth (SSOT)
!         - L4_PH reads from L3 via this bridge, never writes back
!         - Zero-copy design where possible (use pointers)
!         - Validate data before transfer
!===============================================================================
MODULE MD_Mat_Plast_Brg
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Mat_Plast_Def, ONLY: MD_Mat_Plast_Desc, &
                               MD_Mat_Plast_State, &
                               MD_Mat_Plast_Algo, &
                               MD_Mat_Plast_Ctx
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_PLASTIC
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Plast_Brg_Populate_L4
  PUBLIC :: MD_Mat_Plast_Brg_Get_Props
  PUBLIC :: MD_Mat_Plast_Brg_Get_Elastic_Params
  PUBLIC :: MD_Mat_Plast_Brg_Validate_For_L4

CONTAINS

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Brg_Populate_L4
  ! Populate L4 material slot from L3 descriptor
  ! ENHANCED: Now supports temperature/field dependent materials (Week 1 Day 4)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Brg_Populate_L4(l3_desc, l4_props, l4_temps, &
                                           l4_nprops, l4_ntemps, status)
    ! [IN]  l3_desc   - L3 material descriptor (source)
    ! [OUT] l4_props  - L4 properties table (num_props, 1+num_temps)
    ! [OUT] l4_temps  - L4 temperature points array
    ! [OUT] l4_nprops - Number of material properties
    ! [OUT] l4_ntemps - Number of temperature points
    ! [OUT] status    - Error status
    TYPE(MD_Mat_Plast_Desc), INTENT(IN) :: l3_desc
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: l4_props(:,:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: l4_temps(:)
    INTEGER(i4), INTENT(OUT) :: l4_nprops
    INTEGER(i4), INTENT(OUT) :: l4_ntemps
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)

    ! Validate L3 descriptor before transfer
    CALL MD_Mat_Plast_Brg_Validate_For_L4(l3_desc, status)
    IF (status%status_code /= 0) RETURN

    ! Get dimensions
    l4_nprops = 2 + l3_desc%num_constants  ! E, nu + plastic constants
    l4_ntemps = l3_desc%num_temp_points

    IF (l3_desc%dependencies > 0 .AND. l4_ntemps > 0) THEN
      ! Temperature/field dependent material
      ! Allocate L4 arrays for full table
      ALLOCATE(l4_props(l4_nprops, 1 + l4_ntemps))
      ALLOCATE(l4_temps(l4_ntemps))

      ! Copy elastic properties (same for all temperatures)
      DO j = 1, 1 + l4_ntemps
        l4_props(1, j) = l3_desc%E
        l4_props(2, j) = l3_desc%nu
      END DO

      ! Copy full plastic constants table
      DO j = 1, 1 + l4_ntemps
        DO i = 1, l3_desc%num_constants
          l4_props(2 + i, j) = l3_desc%constants(i, j)
        END DO
      END DO

      ! Copy temperature points
      DO i = 1, l4_ntemps
        l4_temps(i) = l3_desc%temp_points(i)
      END DO
    ELSE
      ! No temperature/field dependency
      ! Allocate L4 arrays for reference values only
      ALLOCATE(l4_props(l4_nprops, 1))

      ! Copy elastic properties
      l4_props(1, 1) = l3_desc%E
      l4_props(2, 1) = l3_desc%nu

      ! Copy plastic constants (reference values only)
      DO i = 1, l3_desc%num_constants
        l4_props(2 + i, 1) = l3_desc%constants(i, 1)
      END DO

      l4_ntemps = 0
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Plast_Brg_Populate_L4

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Brg_Get_Props
  ! Get material properties array from L3 descriptor
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Brg_Get_Props(l3_desc, props, nprops, status)
    TYPE(MD_Mat_Plast_Desc), INTENT(IN) :: l3_desc
    REAL(wp), INTENT(OUT) :: props(:)
    INTEGER(i4), INTENT(OUT) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Validate
    IF (.NOT. l3_desc%is_initialized) THEN
      status%status_code = 1
      status%message = "L3 descriptor not initialized"
      nprops = 0
      RETURN
    END IF

    ! Check array size
    IF (SIZE(props) < l3_desc%num_constants) THEN
      status%status_code = 2
      status%message = "Output array too small"
      nprops = 0
      RETURN
    END IF

    ! Copy properties
    nprops = l3_desc%num_constants
    DO i = 1, nprops
      props(i) = l3_desc%constants(i, 1)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Plast_Brg_Get_Props

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Brg_Get_Elastic_Params
  ! Get elastic parameters from L3 descriptor
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Brg_Get_Elastic_Params(l3_desc, E, nu, G, K, status)
    TYPE(MD_Mat_Plast_Desc), INTENT(IN) :: l3_desc
    REAL(wp), INTENT(OUT) :: E, nu, G, K
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Validate
    IF (.NOT. l3_desc%is_initialized) THEN
      status%status_code = 1
      status%message = "L3 descriptor not initialized"
      E = 0.0_wp
      nu = 0.0_wp
      G = 0.0_wp
      K = 0.0_wp
      RETURN
    END IF

    ! Copy elastic parameters
    E = l3_desc%E
    nu = l3_desc%nu
    G = l3_desc%G
    K = l3_desc%K

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Plast_Brg_Get_Elastic_Params

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Brg_Validate_For_L4
  ! Validate L3 descriptor before transferring to L4
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Brg_Validate_For_L4(l3_desc, status)
    TYPE(MD_Mat_Plast_Desc), INTENT(IN) :: l3_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Check initialization
    IF (.NOT. l3_desc%is_initialized) THEN
      status%status_code = 1
      status%message = "L3 descriptor not initialized"
      RETURN
    END IF

    ! Check family type
    IF (l3_desc%family_type /= MD_MAT_FAMILY_PLASTIC) THEN
      status%status_code = 2
      status%message = "Invalid family type for plastic material"
      RETURN
    END IF

    ! Check sub-type range
    IF (l3_desc%sub_type < 201 .OR. l3_desc%sub_type > 219) THEN
      status%status_code = 3
      status%message = "Invalid sub-type for plastic material"
      RETURN
    END IF

    ! Check material constants allocation
    IF (.NOT. ALLOCATED(l3_desc%constants)) THEN
      status%status_code = 4
      status%message = "Material constants not allocated"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Plast_Brg_Validate_For_L4

END MODULE MD_Mat_Plast_Brg
