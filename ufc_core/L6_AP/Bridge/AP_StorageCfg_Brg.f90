!===============================================================================
! MODULE: AP_StorageCfg_Brg
! LAYER:  L6_AP
! DOMAIN: Bridge
! ROLE:   Brg — Config→StorageMgr injection
! BRIEF:  Inject storage configuration from L6 AP_Config to L1 StorageMgr.
!===============================================================================
! Logic chain: L6 Job Init -> AP_StorageCfg_Inject -> reads AP_Config keys
!              -> populates StorageCfgBundle -> future: L1_StorageMgr_Configure
!===============================================================================
MODULE AP_StorageCfg_Brg
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Config_Def,  ONLY: AP_Config_State
  USE AP_Config_Core, ONLY: AP_Config_Get_Int, AP_Config_Get_Real
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: StorageCfgBundle
  PUBLIC :: AP_StorageCfg_Inject

  TYPE :: StorageCfgBundle
    INTEGER(i4) :: pool_size_mb     = 256_i4
    REAL(wp)    :: spill_threshold  = 0.85_wp
    INTEGER(i4) :: lru_window       = 64_i4
    INTEGER(i4) :: checkpoint_interval = 0_i4
  END TYPE StorageCfgBundle

CONTAINS

  SUBROUTINE AP_StorageCfg_Inject(cfg_state, bundle, status)
    TYPE(AP_Config_State), INTENT(IN)  :: cfg_state
    TYPE(StorageCfgBundle), INTENT(OUT) :: bundle
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: tmp_st
    INTEGER(i4) :: ival
    REAL(wp)    :: rval

    CALL init_error_status(status)

    ! Defaults
    bundle%pool_size_mb       = 256_i4
    bundle%spill_threshold    = 0.85_wp
    bundle%lru_window         = 64_i4
    bundle%checkpoint_interval = 0_i4

    ! Override from AP_Config if keys exist
    CALL AP_Config_Get_Int(cfg_state, "STORAGE:POOL_SIZE_MB", ival, tmp_st)
    IF (tmp_st%status_code == IF_STATUS_OK) bundle%pool_size_mb = ival

    CALL AP_Config_Get_Real(cfg_state, "STORAGE:SPILL_THRESHOLD", rval, tmp_st)
    IF (tmp_st%status_code == IF_STATUS_OK) bundle%spill_threshold = rval

    CALL AP_Config_Get_Int(cfg_state, "STORAGE:LRU_WINDOW", ival, tmp_st)
    IF (tmp_st%status_code == IF_STATUS_OK) bundle%lru_window = ival

    CALL AP_Config_Get_Int(cfg_state, "STORAGE:CHECKPOINT_INTERVAL", ival, tmp_st)
    IF (tmp_st%status_code == IF_STATUS_OK) bundle%checkpoint_interval = ival

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_StorageCfg_Inject

END MODULE AP_StorageCfg_Brg
