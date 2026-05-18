!===============================================================================
! MODULE: IF_Prec_Core
! LAYER:  L1_IF
! DOMAIN: Precision
! ROLE:   _Core
! BRIEF:  Precision kind parameters and basic numeric stability checks.
!===============================================================================
!
! Theory:  Defines precision types (sp, dp, qp, wp, i4, i8) and provides basic
!          validation functions for NaN, Inf, overflow, and underflow detection.
!
! Contents (A-Z):
!   IF_Prec_Check_Overflow   [P2] Check for overflow condition
!   IF_Prec_Check_Stability  [P2] Comprehensive numeric stability check
!   IF_Prec_Check_Underflow  [P2] Check for underflow condition
!   IF_Prec_IsFinite         [P2] Check if value is finite
!   IF_Prec_IsInf            [P2] Check if value is infinite
!   IF_Prec_IsNaN            [P2] Check if value is NaN
!
! Constants:
!   IF_PREC_WP_EPSILON       Machine epsilon for wp
!   IF_PREC_WP_TINY          Smallest positive number
!   IF_PREC_WP_HUGE          Largest positive number
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Prec_Core
    USE IF_Err_Def, ONLY: IF_Err_Status_State, IF_ERROR_CATEGORY_OK, IF_ERROR_CATEGORY_INVALID, &
                           wp, i4, i8
    USE IF_Err_Brg, ONLY: init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE, INTRINSIC :: IEEE_ARITHMETIC, ONLY: IEEE_IS_NAN, IEEE_IS_FINITE
    IMPLICIT NONE
    PRIVATE
    
    ! ==========================================================================
    ! PRECISION KIND PARAMETERS (wp, i4, i8 re-exported from IF_Err_Def - single source)
    ! ==========================================================================
    INTEGER, PARAMETER, PUBLIC :: sp = SELECTED_REAL_KIND(6, 37)    ! Single precision (~7 digits)
    INTEGER, PARAMETER, PUBLIC :: dp = SELECTED_REAL_KIND(15, 307)  ! Double precision (~15 digits)
    INTEGER, PARAMETER, PUBLIC :: qp = SELECTED_REAL_KIND(33, 4931) ! Quad precision (~33 digits)
    
    ! ==========================================================================
    ! PRECISION VALIDATION CONSTANTS
    ! ==========================================================================
    REAL(wp), PARAMETER, PUBLIC :: WP_EPSILON = EPSILON(1.0_wp)    ! Machine epsilon for wp
    REAL(wp), PARAMETER, PUBLIC :: WP_TINY = TINY(1.0_wp)          ! Smallest positive number
    REAL(wp), PARAMETER, PUBLIC :: WP_HUGE = HUGE(1.0_wp)          ! Largest positive number
    
    ! ==========================================================================
    ! PUBLIC (re-export wp, i4, i8 from IF_Err_Def; sp, dp, qp already PUBLIC above)
    ! ==========================================================================
    PUBLIC :: wp, i4, i8
    PUBLIC :: IF_Prec_Check_Overflow, IF_Prec_Check_Stability, IF_Prec_Check_Underflow
    PUBLIC :: IF_Prec_IsFinite, IF_Prec_IsInf, IF_Prec_IsNaN

CONTAINS

    !> @brief Check if value is NaN (Not a Number)
    !! @param[in] val Input value
    !! @return .TRUE. if value is NaN, .FALSE. otherwise
    LOGICAL FUNCTION IF_Prec_IsNaN(val)
        REAL(wp), INTENT(IN) :: val
        IF_Prec_IsNaN = IEEE_IS_NAN(val)
    END FUNCTION IF_Prec_IsNaN

    !> @brief Check if value is infinite
    !! @param[in] val Input value
    !! @return .TRUE. if value is infinite, .FALSE. otherwise
    LOGICAL FUNCTION IF_Prec_IsInf(val)
        REAL(wp), INTENT(IN) :: val
        IF_Prec_IsInf = (.NOT. IEEE_IS_FINITE(val)) .AND. (.NOT. IEEE_IS_NAN(val))
    END FUNCTION IF_Prec_IsInf

    !> @brief Check if value is finite
    !! @param[in] val Input value
    !! @return .TRUE. if value is finite, .FALSE. otherwise
    LOGICAL FUNCTION IF_Prec_IsFinite(val)
        REAL(wp), INTENT(IN) :: val
        IF_Prec_IsFinite = IEEE_IS_FINITE(val)
    END FUNCTION IF_Prec_IsFinite

    !> @brief Check for overflow condition
    !! @param[in] val Input value
    !! @return .TRUE. if overflow detected, .FALSE. otherwise
    LOGICAL FUNCTION IF_Prec_Check_Overflow(val)
        REAL(wp), INTENT(IN) :: val
        IF_Prec_Check_Overflow = (ABS(val) >= WP_HUGE)
    END FUNCTION IF_Prec_Check_Overflow

    !> @brief Check for underflow condition
    !! @param[in] val Input value
    !! @return .TRUE. if underflow detected, .FALSE. otherwise
    LOGICAL FUNCTION IF_Prec_Check_Underflow(val)
        REAL(wp), INTENT(IN) :: val
        IF_Prec_Check_Underflow = (ABS(val) > 0.0_wp .AND. ABS(val) < WP_TINY)
    END FUNCTION IF_Prec_Check_Underflow

    !> @brief Comprehensive numeric stability check
    !! @param[in] val Input value
    !! @param[out] is_stable .TRUE. if value is stable, .FALSE. otherwise
    !! @param[out] status Error status
    SUBROUTINE IF_Prec_Check_Stability(val, is_stable, status)
        REAL(wp), INTENT(IN) :: val
        LOGICAL, INTENT(OUT) :: is_stable
        TYPE(IF_Err_Status_State), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        is_stable = .TRUE.
        
        ! Check for NaN
        IF (IF_Prec_IsNaN(val)) THEN
            is_stable = .FALSE.
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Prec_Check_Stability: NaN detected'
            RETURN
        END IF
        
        ! Check for Inf
        IF (IF_Prec_IsInf(val)) THEN
            is_stable = .FALSE.
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Prec_Check_Stability: Inf detected'
            RETURN
        END IF
        
        ! Check for overflow
        IF (IF_Prec_Check_Overflow(val)) THEN
            is_stable = .FALSE.
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Prec_Check_Stability: Overflow detected'
            RETURN
        END IF
        
        ! Check for underflow (only if value is non-zero)
        IF (ABS(val) > 0.0_wp .AND. IF_Prec_Check_Underflow(val)) THEN
            ! Underflow is usually acceptable, but log it
            is_stable = .TRUE.  ! Underflow is acceptable
        END IF
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Prec_Check_Stability

END MODULE IF_Prec_Core