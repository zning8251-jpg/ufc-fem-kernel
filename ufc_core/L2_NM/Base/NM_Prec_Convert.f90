!===============================================================================
! MODULE: NM_Prec_Convert
! LAYER:  L2_NM
! DOMAIN: Base
! ROLE:   Proc — precision conversion utilities
! BRIEF:  Array precision conversion DP↔SP for numerical methods.
!
! Status: CORE
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_Prec_Convert
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK
    USE IF_Prec_Core, ONLY: wp, sp, dp, i4
    IMPLICIT NONE
    PRIVATE
    
    ! ==========================================================================
    ! PUBLIC INTERFACE
    ! ==========================================================================
    PUBLIC :: NM_Prec_Convert_Array_DP_to_SP
    PUBLIC :: NM_Prec_Convert_Array_SP_to_DP

CONTAINS

    !> @brief Convert double precision array to single precision
    !! @param[in] arr_dp Input double precision array
    !! @param[out] arr_sp Output single precision array (allocatable)
    !! @param[out] status Error status
    SUBROUTINE NM_Prec_Convert_Array_DP_to_SP(arr_dp, arr_sp, status)
        REAL(dp), INTENT(IN) :: arr_dp(:)
        REAL(sp), INTENT(OUT), ALLOCATABLE :: arr_sp(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: n
        
        CALL init_error_status(status)
        
        n = SIZE(arr_dp)
        IF (ALLOCATED(arr_sp)) DEALLOCATE(arr_sp)
        ALLOCATE(arr_sp(n))
        
        arr_sp = REAL(arr_dp, KIND=sp)
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE NM_Prec_Convert_Array_DP_to_SP

    !> @brief Convert single precision array to double precision
    !! @param[in] arr_sp Input single precision array
    !! @param[out] arr_dp Output double precision array (allocatable)
    !! @param[out] status Error status
    SUBROUTINE NM_Prec_Convert_Array_SP_to_DP(arr_sp, arr_dp, status)
        REAL(sp), INTENT(IN) :: arr_sp(:)
        REAL(dp), INTENT(OUT), ALLOCATABLE :: arr_dp(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: n
        
        CALL init_error_status(status)
        
        n = SIZE(arr_sp)
        IF (ALLOCATED(arr_dp)) DEALLOCATE(arr_dp)
        ALLOCATE(arr_dp(n))
        
        arr_dp = REAL(arr_sp, KIND=dp)
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE NM_Prec_Convert_Array_SP_to_DP

END MODULE NM_Prec_Convert