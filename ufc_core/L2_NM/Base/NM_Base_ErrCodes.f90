!===============================================================================
! MODULE: NM_Base_ErrCodes
! LAYER:  L2_NM
! DOMAIN: Base
! ROLE:   Def — error code constants for the L2_NM layer
! BRIEF:  Error code definitions for numerical methods layer (3000-3999 band).
!         Separated from NM_Base_Def for single responsibility.
!===============================================================================
MODULE NM_Base_ErrCodes
  USE IF_Prec_Core, ONLY: i4
  IMPLICIT NONE
  PRIVATE
  
  !--------------------------------------------------------------------
  ! Solver base errors (3000-3099)
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_SOLVER_BASE = 3000_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_NOT_CONVERGED = 3001_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_MAX_ITER = 3002_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_SINGULAR = 3003_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_ILL_CONDITIONED = 3004_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_DIVERGED = 3005_i4
  
  !--------------------------------------------------------------------
  ! Linear algebra errors (3100-3199)
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_LINALG_SINGULAR = 3101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_LINALG_RANK_DEF = 3102_i4
  
  !--------------------------------------------------------------------
  ! Iteration errors (3200-3299)
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_ITER_STAGNATION = 3201_i4
  
  !--------------------------------------------------------------------
  ! Time integration errors (3300-3399)
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_TIMEINT_STEP_SMALL = 3301_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ERR_TIMEINT_UNSTABLE = 3303_i4
  
END MODULE NM_Base_ErrCodes
