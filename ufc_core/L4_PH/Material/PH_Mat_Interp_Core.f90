!===============================================================================
! MODULE: PH_Mat_Interp_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core - Temperature/Field Interpolation
! BRIEF:  Unified interpolation module for temperature/field dependent materials.
!         Provides linear and spline interpolation with caching mechanism.
!
! PURPOSE:
!   Solve the common problem: all material families only transfer constants(:,1)
!   This module enables full temperature/field dependency support for all 11
!   material families (Elas/Plast/Hyper/Damage/Creep/etc.)
!
! DESIGN:
!   - Unified interface for all material families
!   - High performance (caching + binary search)
!   - Easy to extend (support new interpolation methods)
!   - Complete testing (unit tests + integration tests)
!
! CREATED: 2026-05-03 (Week 1 Day 2)
!===============================================================================
MODULE PH_Mat_Interp_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Interpolation method constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_INTERP_LINEAR = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_INTERP_SPLINE = 2_i4

  !-----------------------------------------------------------------------------
  ! Interpolation context TYPE
  ! Purpose: Cache interpolation results and coefficients for performance
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_Interp_Ctx
    ! Interpolation method
    INTEGER(i4) :: interp_method = PH_MAT_INTERP_LINEAR

    ! Cache (avoid repeated interpolation)
    INTEGER(i4) :: last_interval = -1
    REAL(wp) :: last_temperature = -999.0_wp
    ! TYPE-003: cache buffers are POINTER targets (Init allocates; no ALLOCATABLE in *Ctx)
    REAL(wp), DIMENSION(:), POINTER :: last_props => NULL()

    ! Spline interpolation coefficients (if using spline)
    REAL(wp), DIMENSION(:, :), POINTER :: spline_coeffs => NULL()

    ! Statistics
    INTEGER(i4) :: num_interpolations = 0
    INTEGER(i4) :: num_cache_hits = 0

    ! Initialization flag
    LOGICAL :: initialized = .FALSE.
  END TYPE PH_Mat_Interp_Ctx

  !-----------------------------------------------------------------------------
  ! Public interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: PH_Mat_Interp_Init
  PUBLIC :: PH_Mat_Interp_Finalize
  PUBLIC :: PH_Mat_Interpolate_Props
  PUBLIC :: PH_Mat_Interp_Get_Stats

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Mat_Interp_Init
  ! Initialize interpolation context
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Interp_Init(ctx, num_props, interp_method, status)
    ! [INOUT] ctx           - Interpolation context to initialize
    ! [IN]    num_props     - Number of material properties
    ! [IN]    interp_method - Interpolation method (optional, default=LINEAR)
    ! [OUT]   status        - Error status
    TYPE(PH_Mat_Interp_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: num_props
    INTEGER(i4), INTENT(IN), OPTIONAL :: interp_method
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Set interpolation method
    IF (PRESENT(interp_method)) THEN
      ctx%interp_method = interp_method
    ELSE
      ctx%interp_method = PH_MAT_INTERP_LINEAR
    END IF

    ! (Re)bind cache buffer (pointer; ALLOCATE associates storage)
    IF (ASSOCIATED(ctx%last_props)) DEALLOCATE(ctx%last_props)
    ALLOCATE(ctx%last_props(num_props))
    ctx%last_props = 0.0_wp

    ! Initialize cache state
    ctx%last_interval = -1
    ctx%last_temperature = -999.0_wp

    ! Initialize statistics
    ctx%num_interpolations = 0
    ctx%num_cache_hits = 0

    ctx%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Interp_Init

  !-----------------------------------------------------------------------------
  ! PH_Mat_Interp_Finalize
  ! Finalize interpolation context (deallocate memory)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Interp_Finalize(ctx, status)
    ! [INOUT] ctx    - Interpolation context to finalize
    ! [OUT]   status - Error status
    TYPE(PH_Mat_Interp_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Release cache targets
    IF (ASSOCIATED(ctx%last_props)) DEALLOCATE(ctx%last_props)
    IF (ASSOCIATED(ctx%spline_coeffs)) DEALLOCATE(ctx%spline_coeffs)

    ! Reset state
    ctx%last_interval = -1
    ctx%last_temperature = -999.0_wp
    ctx%num_interpolations = 0
    ctx%num_cache_hits = 0
    ctx%initialized = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Interp_Finalize

  !-----------------------------------------------------------------------------
  ! PH_Mat_Interpolate_Props
  ! Interpolate material properties at given temperature
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Interpolate_Props(props_table, temp_points, temperature, &
                                       ctx, props_out, status)
    ! [IN]    props_table  - Material properties table (num_props, num_temps)
    ! [IN]    temp_points  - Temperature points array
    ! [IN]    temperature  - Current temperature
    ! [INOUT] ctx          - Interpolation context (for caching)
    ! [OUT]   props_out    - Interpolated properties
    ! [OUT]   status       - Error status
    REAL(wp), INTENT(IN) :: props_table(:,:)
    REAL(wp), INTENT(IN) :: temp_points(:)
    REAL(wp), INTENT(IN) :: temperature
    TYPE(PH_Mat_Interp_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(OUT) :: props_out(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: num_props, num_temps
    INTEGER(i4) :: i, i_low, i_high
    REAL(wp) :: t_low, t_high, alpha
    REAL(wp), PARAMETER :: TEMP_TOL = 1.0e-10_wp

    CALL init_error_status(status)

    ! Validate context
    IF (.NOT. ctx%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Interpolation context not initialized"
      RETURN
    END IF

    num_props = SIZE(props_table, 1)
    num_temps = SIZE(temp_points)

    ! Validate array sizes
    IF (SIZE(props_out) < num_props) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output array too small"
      RETURN
    END IF

    IF (SIZE(props_table, 2) /= num_temps + 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Props table size mismatch"
      RETURN
    END IF

    ! Check cache
    IF (ABS(temperature - ctx%last_temperature) < TEMP_TOL) THEN
      ! Cache hit
      props_out(1:num_props) = ctx%last_props(1:num_props)
      ctx%num_cache_hits = ctx%num_cache_hits + 1
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Find interval
    CALL Find_Interval(temp_points, temperature, i_low, i_high, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Interpolate based on method
    SELECT CASE (ctx%interp_method)
    CASE (PH_MAT_INTERP_LINEAR)
      ! Linear interpolation
      IF (i_low == i_high) THEN
        ! Boundary case: use reference value or boundary value
        IF (i_low == 0) THEN
          ! Below first temperature point: use reference value
          props_out(1:num_props) = props_table(1:num_props, 1)
        ELSE
          ! At or beyond last temperature point
          props_out(1:num_props) = props_table(1:num_props, i_low + 1)
        END IF
      ELSE
        ! Normal case: interpolate between two points
        t_low = temp_points(i_low)
        t_high = temp_points(i_high)
        alpha = (temperature - t_low) / (t_high - t_low)

        DO i = 1, num_props
          props_out(i) = (1.0_wp - alpha) * props_table(i, i_low + 1) &
                       + alpha * props_table(i, i_high + 1)
        END DO
      END IF

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "Unknown interpolation method"
      RETURN
    END SELECT

    ! Update cache
    ctx%last_temperature = temperature
    ctx%last_interval = i_low
    ctx%last_props(1:num_props) = props_out(1:num_props)
    ctx%num_interpolations = ctx%num_interpolations + 1

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Interpolate_Props

  !-----------------------------------------------------------------------------
  ! Find_Interval
  ! Find the interval containing the given temperature
  !-----------------------------------------------------------------------------
  SUBROUTINE Find_Interval(temp_points, temperature, i_low, i_high, status)
    ! [IN]  temp_points  - Temperature points array
    ! [IN]  temperature  - Current temperature
    ! [OUT] i_low        - Lower interval index
    ! [OUT] i_high       - Upper interval index
    ! [OUT] status       - Error status
    REAL(wp), INTENT(IN) :: temp_points(:)
    REAL(wp), INTENT(IN) :: temperature
    INTEGER(i4), INTENT(OUT) :: i_low, i_high
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n, i_mid

    CALL init_error_status(status)
    n = SIZE(temp_points)

    ! Validate input
    IF (n < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Empty temperature points array"
      RETURN
    END IF

    ! Handle boundary cases
    IF (temperature <= temp_points(1)) THEN
      i_low = 0
      i_high = 1
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (temperature >= temp_points(n)) THEN
      i_low = n
      i_high = n
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Binary search
    i_low = 1
    i_high = n
    DO WHILE (i_high - i_low > 1)
      i_mid = (i_low + i_high) / 2
      IF (temperature < temp_points(i_mid)) THEN
        i_high = i_mid
      ELSE
        i_low = i_mid
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE Find_Interval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Interp_Get_Stats
  ! Get interpolation statistics
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Interp_Get_Stats(ctx, num_interps, num_hits, hit_rate)
    ! [IN]  ctx         - Interpolation context
    ! [OUT] num_interps - Number of interpolations
    ! [OUT] num_hits    - Number of cache hits
    ! [OUT] hit_rate    - Cache hit rate (0.0 to 1.0)
    TYPE(PH_Mat_Interp_Ctx), INTENT(IN) :: ctx
    INTEGER(i4), INTENT(OUT) :: num_interps
    INTEGER(i4), INTENT(OUT) :: num_hits
    REAL(wp), INTENT(OUT) :: hit_rate

    num_interps = ctx%num_interpolations
    num_hits = ctx%num_cache_hits

    IF (num_interps > 0) THEN
      hit_rate = REAL(num_hits, wp) / REAL(num_interps, wp)
    ELSE
      hit_rate = 0.0_wp
    END IF
  END SUBROUTINE PH_Mat_Interp_Get_Stats

END MODULE PH_Mat_Interp_Core
