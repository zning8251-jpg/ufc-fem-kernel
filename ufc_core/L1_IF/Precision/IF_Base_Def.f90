!===============================================================================
! MODULE: IF_Base_Def
! LAYER:  L1_IF
! DOMAIN: Precision
! ROLE:   _Def
! BRIEF:  Basic mathematical constants and numerical tolerances.
!===============================================================================
!
! Theory:  Provides fundamental constants (PI, E, basic numbers) and tolerance
!          values used throughout the codebase. Advanced physical constants and
!          unit conversion are provided in L4_PH layer.
!
! Contents (A-Z):
!   IF_Const_DegToRad  [P2] Convert degrees to radians
!   IF_Const_Get_E     [P2] Get Euler's number (E)
!   IF_Const_Get_PI    [P2] Get PI constant
!   IF_Const_RadToDeg  [P2] Convert radians to degrees
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Base_Def
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PRECISION ALIAS (L4_PH compatibility; same as IF_Prec%dp)
    ! ==========================================================================
    INTEGER, PARAMETER, PUBLIC :: DP = SELECTED_REAL_KIND(15, 307)

    ! ==========================================================================
    ! LOGICAL CONSTANTS
    ! ==========================================================================
    LOGICAL, PARAMETER, PUBLIC :: TRUE  = .TRUE.
    LOGICAL, PARAMETER, PUBLIC :: FALSE = .FALSE.

    ! ==========================================================================
    ! BASIC NUMERIC CONSTANTS
    ! ==========================================================================
    REAL(wp), PARAMETER, PUBLIC :: ZERO = 0.0_wp
    REAL(wp), PARAMETER, PUBLIC :: ONE = 1.0_wp
    REAL(wp), PARAMETER, PUBLIC :: TWO = 2.0_wp
    REAL(wp), PARAMETER, PUBLIC :: THREE = 3.0_wp
    REAL(wp), PARAMETER, PUBLIC :: FOUR = 4.0_wp
    REAL(wp), PARAMETER, PUBLIC :: FIVE = 5.0_wp
    REAL(wp), PARAMETER, PUBLIC :: SIX = 6.0_wp
    REAL(wp), PARAMETER, PUBLIC :: SEVEN = 7.0_wp
    REAL(wp), PARAMETER, PUBLIC :: EIGHT = 8.0_wp
    REAL(wp), PARAMETER, PUBLIC :: NINE = 9.0_wp
    REAL(wp), PARAMETER, PUBLIC :: TEN = 10.0_wp
    
    ! ==========================================================================
    ! FRACTIONAL CONSTANTS
    ! ==========================================================================
    REAL(wp), PARAMETER, PUBLIC :: HALF = 0.5_wp
    REAL(wp), PARAMETER, PUBLIC :: THIRD = 1.0_wp / 3.0_wp
    REAL(wp), PARAMETER, PUBLIC :: QUARTER = 0.25_wp
    REAL(wp), PARAMETER, PUBLIC :: SIXTH = 1.0_wp / 6.0_wp
    REAL(wp), PARAMETER, PUBLIC :: EIGHTH = 0.125_wp
    REAL(wp), PARAMETER, PUBLIC :: TWELFTH = 1.0_wp / 12.0_wp
    
    ! ==========================================================================
    ! MATHEMATICAL CONSTANTS (20+ digits precision)
    ! ==========================================================================
    REAL(wp), PARAMETER, PUBLIC :: PI = 3.14159265358979323846_wp
    REAL(wp), PARAMETER, PUBLIC :: TWO_PI = 6.28318530717958647692_wp
    REAL(wp), PARAMETER, PUBLIC :: PI_OVER_TWO = 1.57079632679489661923_wp
    REAL(wp), PARAMETER, PUBLIC :: PI_OVER_FOUR = 0.78539816339744830962_wp
    REAL(wp), PARAMETER, PUBLIC :: E = 2.71828182845904523536_wp
    REAL(wp), PARAMETER, PUBLIC :: SQRT_TWO = 1.41421356237309504880_wp
    REAL(wp), PARAMETER, PUBLIC :: SQRT_THREE = 1.73205080756887729353_wp
    REAL(wp), PARAMETER, PUBLIC :: SQRT_PI = 1.77245385090551602730_wp
    REAL(wp), PARAMETER, PUBLIC :: DEG_TO_RAD = PI / 180.0_wp
    REAL(wp), PARAMETER, PUBLIC :: RAD_TO_DEG = 180.0_wp / PI
    
    ! ==========================================================================
    ! NUMERICAL TOLERANCES (convergence criteria)
    ! ==========================================================================
    REAL(wp), PARAMETER, PUBLIC :: TINY = 1.0e-30_wp
    REAL(wp), PARAMETER, PUBLIC :: EPS  = EPSILON(1.0_wp)
    REAL(wp), PARAMETER, PUBLIC :: SMALL = 1.0e-10_wp
    REAL(wp), PARAMETER, PUBLIC :: SMALL_VAL = SMALL                ! Alias for NM_Eigen etc.
    REAL(wp), PARAMETER, PUBLIC :: LARGE_VAL = 1.0e30_wp           ! Large value for scaling/checks
    REAL(wp), PARAMETER, PUBLIC :: TOLERANCE = 1.0e-6_wp           ! Default tolerance
    REAL(wp), PARAMETER, PUBLIC :: LARGE_TOLERANCE = 1.0e-3_wp     ! Relaxed tolerance
    REAL(wp), PARAMETER, PUBLIC :: STRICT_TOLERANCE = 1.0e-12_wp   ! Tight tolerance
    
    ! ==========================================================================
    ! PUBLIC INTERFACE
    ! ==========================================================================
    PUBLIC :: IF_Const_DegToRad
    PUBLIC :: IF_Const_Get_E
    PUBLIC :: IF_Const_Get_PI
    PUBLIC :: IF_Const_RadToDeg

CONTAINS

    !> @brief Convert degrees to radians
    !! @param[in] deg Angle in degrees
    !! @return Angle in radians
    REAL(wp) FUNCTION IF_Const_DegToRad(deg) RESULT(rad)
        REAL(wp), INTENT(IN) :: deg
        rad = deg * DEG_TO_RAD
    END FUNCTION IF_Const_DegToRad

    !> @brief Get E (Euler's number) constant
    !! @return E value
    REAL(wp) FUNCTION IF_Const_Get_E() RESULT(e_val)
        e_val = E
    END FUNCTION IF_Const_Get_E

    !> @brief Get PI constant
    !! @return PI value
    REAL(wp) FUNCTION IF_Const_Get_PI() RESULT(pi_val)
        pi_val = PI
    END FUNCTION IF_Const_Get_PI

    !> @brief Convert radians to degrees
    !! @param[in] rad Angle in radians
    !! @return Angle in degrees
    REAL(wp) FUNCTION IF_Const_RadToDeg(rad) RESULT(deg)
        REAL(wp), INTENT(IN) :: rad
        deg = rad * RAD_TO_DEG
    END FUNCTION IF_Const_RadToDeg

END MODULE IF_Base_Def
