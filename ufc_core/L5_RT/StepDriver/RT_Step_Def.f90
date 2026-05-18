!===============================================================================
! MODULE: RT_Step_Def
! LAYER:  L5_RT
! DOMAIN: StepDriver
! ROLE:   Def �?Four-type system (Desc/State/Algo/Ctx) + constants
! BRIEF:  AUTHORITY type definitions for StepDriver domain.
!
! Four-TYPE Architecture:
!   RT_Step_Desc   �?Immutable step config (time range, limits)
!   RT_Step_State  �?Mutable runtime state (cutback count, current time)
!   RT_Step_Algo   �?Algorithm config (adaptive dt strategy)
!   RT_Step_Ctx    �?Hot-path increment/iteration context
!
! Constants: RT_STEP_*, RT_INC_*, RT_ITER_*, STEP_CAT_*, RT_PHASE_*,
!            RT_STEPDRV_*, INTEG_*, STEP_STATE_*
!
! Status: ACTIVE | AUTHORITY | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Step_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Step_Proc, ONLY: MD_NonlinSolv
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Desc ??????�?  !=============================================================================
  TYPE, PUBLIC :: RT_StepDriver_TimeCfg
    REAL(wp)    :: t_start     = 0.0_wp
    REAL(wp)    :: t_end       = 1.0_wp
    REAL(wp)    :: dt_init     = 0.1_wp
    REAL(wp)    :: dt_min      = 1.0e-12_wp
    REAL(wp)    :: dt_max      = 1.0e+30_wp
    INTEGER(i4) :: target_iter = 6_i4
  END TYPE RT_StepDriver_TimeCfg

  TYPE, PUBLIC :: RT_StepDriver_Cfg_Tol
    REAL(wp) :: tol_residual = 1.0e-5_wp
    REAL(wp) :: tol_displ    = 1.0e-3_wp
    REAL(wp) :: energy_tol   = 1.0e-4_wp
  END TYPE RT_StepDriver_Cfg_Tol

  TYPE, PUBLIC :: RT_StepDriver_Cfg_Strat
    INTEGER(i4) :: max_iter    = 16_i4
    LOGICAL     :: line_search = .FALSE.
    INTEGER(i4) :: conv_mode   = 1_i4
    INTEGER(i4) :: target_iter = 6_i4
  END TYPE RT_StepDriver_Cfg_Strat

  TYPE, PUBLIC :: RT_StepDriver_Algo
    TYPE(RT_StepDriver_Cfg_Tol)   :: tol
    TYPE(RT_StepDriver_Cfg_Strat) :: strat
  END TYPE RT_StepDriver_Algo

  TYPE, PUBLIC :: RT_StepDriver_Desc
    INTEGER(i4)                 :: step_idx         = 0_i4
    INTEGER(i4)                 :: step_id          = 0_i4
    INTEGER(i4)                 :: category         = 1_i4
    INTEGER(i4)                 :: solver_config_id = 0_i4
    TYPE(RT_StepDriver_TimeCfg) :: time_cfg
    CHARACTER(LEN=64)           :: name             = ""
  END TYPE RT_StepDriver_Desc

  !=============================================================================
  ! State ????????
  !=============================================================================
  TYPE, PUBLIC :: RT_StepDriver_State
    INTEGER(i4) :: current_step_idx      = 0_i4
    INTEGER(i4) :: current_increment     = 0_i4
    INTEGER(i4) :: current_iteration     = 0_i4
    REAL(wp)    :: current_time          = 0.0_wp
    REAL(wp)    :: current_load_factor   = 0.0_wp
    LOGICAL     :: converged             = .FALSE.
  END TYPE RT_StepDriver_State

  !=============================================================================
  ! Three-level state machine constants (Step / Increment / Iteration)
  !=============================================================================
  ! Level 1: Step states
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_IDLE      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_RUNNING   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_CONVERGED = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_CUTBACK   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_FAILED    = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_COMPLETED = 5_i4

  ! Level 2: Increment states
  INTEGER(i4), PARAMETER, PUBLIC :: RT_INC_IDLE       = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_INC_PREDICTING = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_INC_ITERATING  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_INC_CONVERGED  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_INC_CUTBACK    = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_INC_FAILED     = 5_i4

  ! Level 3: Iteration states
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ITER_NOT_STARTED = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ITER_ASSEMBLING  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ITER_SOLVING     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ITER_UPDATING    = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ITER_CHECKING    = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ITER_CONVERGED   = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ITER_CONTINUING  = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ITER_DIVERGED    = 7_i4

  !=============================================================================
  ! Step machine four-type (H4a) � pilot ?TYPE: inc / stp / itr
  !=============================================================================
  TYPE, PUBLIC :: RT_Step_Inc_Evo_Desc
    REAL(wp)    :: time_start    = 0.0_wp
    REAL(wp)    :: time_end      = 1.0_wp
    REAL(wp)    :: dt_init       = 0.1_wp
    REAL(wp)    :: dt_min        = 1.0e-12_wp
    REAL(wp)    :: dt_max        = 1.0e+30_wp
    INTEGER(i4) :: max_inc       = 1000_i4
    INTEGER(i4) :: max_cutbacks  = 10_i4
  END TYPE RT_Step_Inc_Evo_Desc

  TYPE, PUBLIC :: RT_Step_Itr_Com_Desc
    INTEGER(i4) :: nr_max_iter   = 16_i4
    REAL(wp)    :: nr_tol        = 1.0e-6_wp
  END TYPE RT_Step_Itr_Com_Desc

  TYPE, PUBLIC :: RT_Step_Desc
    TYPE(RT_Step_Inc_Evo_Desc) :: inc
    TYPE(RT_Step_Itr_Com_Desc) :: itr
  END TYPE RT_Step_Desc

  TYPE, PUBLIC :: RT_Step_Inc_Evo_State
    INTEGER(i4) :: inc_num        = 0_i4
    REAL(wp)    :: time_current   = 0.0_wp
    REAL(wp)    :: dt             = 0.1_wp
    INTEGER(i4) :: total_incs     = 0_i4
  END TYPE RT_Step_Inc_Evo_State

  TYPE, PUBLIC :: RT_Step_Stp_Ctl_State
    INTEGER(i4) :: step_status    = 0_i4   ! RT_STEP_* constant
    INTEGER(i4) :: n_cutbacks     = 0_i4
    INTEGER(i4) :: total_iters    = 0_i4
    REAL(wp)    :: total_cpu_time = 0.0_wp
  END TYPE RT_Step_Stp_Ctl_State

  TYPE, PUBLIC :: RT_Step_State
    TYPE(RT_Step_Inc_Evo_State) :: inc
    TYPE(RT_Step_Stp_Ctl_State) :: stp
  END TYPE RT_Step_State

  TYPE, PUBLIC :: RT_Step_Stp_Ctl_Algo
    LOGICAL     :: auto_dt          = .TRUE.
    INTEGER(i4) :: target_iters     = 6_i4
    REAL(wp)    :: growth_threshold = 0.8_wp
    REAL(wp)    :: growth_factor    = 1.25_wp
    REAL(wp)    :: cutback_factor   = 0.5_wp
  END TYPE RT_Step_Stp_Ctl_Algo

  TYPE, PUBLIC :: RT_Step_Algo
    TYPE(RT_Step_Stp_Ctl_Algo) :: stp
  END TYPE RT_Step_Algo

  TYPE, PUBLIC :: RT_Step_Inc_Evo_Ctx
    INTEGER(i4) :: inc_status        = 0_i4   ! RT_INC_* constant
    REAL(wp)    :: dt_trial          = 0.0_wp
    REAL(wp)    :: time_at_inc_start = 0.0_wp
    LOGICAL     :: inc_converged     = .FALSE.
  END TYPE RT_Step_Inc_Evo_Ctx

  TYPE, PUBLIC :: RT_Step_Itr_Ctrl
    INTEGER(i4) :: iter_status   = 0_i4   ! RT_ITER_* constant
    INTEGER(i4) :: inc_iters     = 0_i4
    INTEGER(i4) :: inc_iters_max = 0_i4
  END TYPE RT_Step_Itr_Ctrl

  TYPE, PUBLIC :: RT_Step_Itr_Residual
    REAL(wp) :: res_norm_0    = 0.0_wp
    REAL(wp) :: res_norm      = 0.0_wp
    REAL(wp) :: res_norm_prev = 0.0_wp
  END TYPE RT_Step_Itr_Residual

  TYPE, PUBLIC :: RT_Step_Itr_Metrics
    REAL(wp) :: disp_norm = 0.0_wp
    REAL(wp) :: conv_rate = 0.0_wp
    REAL(wp) :: pnewdt    = 1.0_wp
  END TYPE RT_Step_Itr_Metrics

  TYPE, PUBLIC :: RT_Step_Itr_Com_Ctx
    TYPE(RT_Step_Itr_Ctrl)     :: ctrl
    TYPE(RT_Step_Itr_Residual) :: residual
    TYPE(RT_Step_Itr_Metrics)  :: metrics
  END TYPE RT_Step_Itr_Com_Ctx

  ! Phase6 §2.3: prefer POINTER/work_vec scratch over value-copied large buffers in Step hot path.
  TYPE, PUBLIC :: RT_Step_Ctx
    TYPE(RT_Step_Inc_Evo_Ctx) :: inc
    TYPE(RT_Step_Itr_Com_Ctx) :: itr
    REAL(wp), POINTER :: work_vec(:) => NULL()
    REAL(wp)          :: temp_scalar = 0.0_wp
    INTEGER(i4)       :: pool_slot   = 0_i4
  END TYPE RT_Step_Ctx

  TYPE, PUBLIC :: RT_Inc_State
    INTEGER(i4) :: status       = 0_i4   ! RT_INC_* constant
    INTEGER(i4) :: inc_num      = 0_i4
    REAL(wp)    :: dt_trial     = 0.0_wp
    LOGICAL     :: converged    = .FALSE.
  END TYPE RT_Inc_State

  TYPE, PUBLIC :: RT_Iter_State
    INTEGER(i4) :: status       = 0_i4   ! RT_ITER_* constant
    INTEGER(i4) :: iter_num     = 0_i4
    REAL(wp)    :: res_norm     = 0.0_wp
    REAL(wp)    :: disp_norm    = 0.0_wp
    LOGICAL     :: converged    = .FALSE.
  END TYPE RT_Iter_State

  !=============================================================================
  ! RT_Inc_Ctx / RT_Iter_Ctx: sub-level hot-path context
  !=============================================================================
  TYPE, PUBLIC :: RT_Inc_Ctx
    REAL(wp)    :: dt_trial          = 0.0_wp
    REAL(wp)    :: time_at_start     = 0.0_wp
    LOGICAL     :: converged         = .FALSE.
    REAL(wp), POINTER :: u_saved(:)  => NULL()
  END TYPE RT_Inc_Ctx

  TYPE, PUBLIC :: RT_Iter_Ctx
    INTEGER(i4) :: iter_count        = 0_i4
    REAL(wp)    :: res_norm_0        = 0.0_wp
    REAL(wp)    :: res_norm          = 0.0_wp
    REAL(wp)    :: res_norm_prev     = 0.0_wp
    REAL(wp)    :: disp_norm         = 0.0_wp
    REAL(wp)    :: conv_rate         = 0.0_wp
    REAL(wp)    :: pnewdt            = 1.0_wp
  END TYPE RT_Iter_Ctx

  !=============================================================================
  ! (legacy RT_Step_Ctx flat block removed � use RT_Step_Ctx%inc / %itr)
  !=============================================================================

  !=============================================================================
  ! ????????????�?  !=============================================================================
  TYPE, PUBLIC :: RT_StepDriver_Result
    LOGICAL            :: success            = .FALSE.
    LOGICAL            :: converged          = .FALSE.
    INTEGER(i4)        :: total_increments   = 0_i4
    INTEGER(i4)        :: total_iterations   = 0_i4
    INTEGER(i4)        :: total_cutbacks     = 0_i4
    REAL(wp)           :: final_time         = 0.0_wp
    REAL(wp)           :: final_load_factor  = 0.0_wp
    REAL(wp)           :: cpu_time           = 0.0_wp
    CHARACTER(LEN=512) :: message            = ''
  END TYPE RT_StepDriver_Result

  !=============================================================================
  ! ??????????�?  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_CAT_STD  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_CAT_IMPL = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_CAT_EXPL = 3_i4

  TYPE, PUBLIC :: RT_StepRuntimeCfg
    TYPE(RT_StepDriver_TimeCfg) :: time_cfg
    TYPE(RT_StepDriver_Algo)    :: algo
    INTEGER(i4)                 :: category = STEP_CAT_STD
  END TYPE RT_StepRuntimeCfg

  !=============================================================================
  ! Hyplas ??????????
  !=============================================================================
  TYPE, PUBLIC :: RT_StepDTCtrl
    REAL(wp)    :: grow_factor      = 1.1_wp
    REAL(wp)    :: cutback_factor   = 0.5_wp
    INTEGER(i4) :: strategy         = 1_i4
  END TYPE RT_StepDTCtrl

  TYPE, PUBLIC :: RT_ImplicitStepTimeCfg
    REAL(wp) :: t_start    = 0.0_wp
    REAL(wp) :: t_end      = 1.0_wp
    REAL(wp) :: dt_init    = 0.01_wp
    REAL(wp) :: dt_min     = 1.0e-12_wp
    REAL(wp) :: dt_max     = 1.0_wp
  END TYPE RT_ImplicitStepTimeCfg

  TYPE, PUBLIC :: RT_ExplicitStepTimeCfg
    REAL(wp) :: t_start    = 0.0_wp
    REAL(wp) :: t_end      = 1.0_wp
    REAL(wp) :: dt_init    = 0.01_wp
    REAL(wp) :: dt_min     = 1.0e-12_wp
    REAL(wp) :: dt_max     = 1.0_wp
    LOGICAL  :: auto_dt    = .FALSE.
  END TYPE RT_ExplicitStepTimeCfg

  TYPE, PUBLIC :: RT_ImplicitStepCfg
    TYPE(RT_ImplicitStepTimeCfg) :: time_cfg
    TYPE(MD_NonlinSolv)          :: nl_cfg
    TYPE(RT_StepDTCtrl)          :: dt_ctrl
  END TYPE RT_ImplicitStepCfg

  TYPE, PUBLIC :: RT_ExplicitStepCfg
    TYPE(RT_ExplicitStepTimeCfg) :: time_cfg
    TYPE(RT_StepDTCtrl)          :: dt_ctrl
  END TYPE RT_ExplicitStepCfg

  !=============================================================================
  ! ????????Newmark-? / HHT-?�?  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: INTEG_NEWMARK_BETA = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: INTEG_HHT_ALPHA    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: INTEG_CENTRAL_DIFF = 3_i4

  TYPE, PUBLIC :: RT_DynImpl_TimeCfg
    REAL(wp) :: t_start       = 0.0_wp
    REAL(wp) :: t_end         = 1.0_wp
    REAL(wp) :: dt_init       = 0.01_wp
    REAL(wp) :: dt_min        = 1.0e-12_wp
    REAL(wp) :: dt_max        = 1.0_wp
    INTEGER(i4) :: integration_scheme = INTEG_NEWMARK_BETA
    REAL(wp) :: beta          = 0.25_wp    ! Newmark ? (default: average acceleration)
    REAL(wp) :: gamma         = 0.5_wp     ! Newmark ? (default: average acceleration)
    REAL(wp) :: alpha         = 0.0_wp     ! HHT ? parameter (default: 0, no numerical damping)
    REAL(wp) :: alpha_rayleigh = 0.0_wp    ! Rayleigh damping: C = ?�M + ?�K
    REAL(wp) :: beta_rayleigh  = 0.0_wp    ! Rayleigh damping coefficient
  END TYPE RT_DynImpl_TimeCfg

  TYPE, PUBLIC :: RT_DynImpl_State
    INTEGER(i4) :: current_increment = 0_i4
    REAL(wp)    :: current_time      = 0.0_wp
    REAL(wp), POINTER :: displacement(:) => NULL()  ! u_{n+1}
    REAL(wp), POINTER :: velocity(:)     => NULL()  ! v_{n+1}
    REAL(wp), POINTER :: acceleration(:) => NULL()  ! a_{n+1}
    LOGICAL     :: converged           = .FALSE.
  END TYPE RT_DynImpl_State

  TYPE, PUBLIC :: RT_DynImpl_Ctx
    REAL(wp), POINTER :: u_n(:)        => NULL()  ! u at previous step
    REAL(wp), POINTER :: v_n(:)        => NULL()  ! v at previous step
    REAL(wp), POINTER :: a_n(:)        => NULL()  ! a at previous step
    REAL(wp), POINTER :: F_ext(:)      => NULL()  ! External force vector
    REAL(wp), POINTER :: F_int(:)      => NULL()  ! Internal force vector
    REAL(wp), POINTER :: M_dense(:,:)  => NULL()  ! Mass matrix (dense)
    REAL(wp), POINTER :: K_dense(:,:)  => NULL()  ! Stiffness matrix (dense)
    REAL(wp), POINTER :: K_eff(:,:)    => NULL()  ! Effective tangent matrix
    REAL(wp), POINTER :: work1(:)      => NULL()  ! Workspace vectors
    REAL(wp), POINTER :: work2(:)      => NULL()
    REAL(wp)          :: c1            = 0.0_wp   ! Integration constants
    REAL(wp)          :: cg            = 0.0_wp
    REAL(wp)          :: inv_beta_dt   = 0.0_wp
    REAL(wp)          :: half_over_beta_m1 = 0.0_wp
    INTEGER(i4)       :: newton_iter   = 0_i4     ! Newton iteration counter
    LOGICAL           :: use_hht       = .FALSE.  ! HHT-? flag
  END TYPE RT_DynImpl_Ctx

  !=============================================================================
  ! ????????Central Difference�?  !=============================================================================
  TYPE, PUBLIC :: RT_DynExpl_TimeCfg
    REAL(wp) :: t_start       = 0.0_wp
    REAL(wp) :: t_end         = 1.0_wp
    REAL(wp) :: dt_init       = 1.0e-4_wp   ! ??????
    REAL(wp) :: dt_min        = 1.0e-12_wp
    REAL(wp) :: dt_max        = 1.0e-3_wp
    LOGICAL  :: auto_dt       = .FALSE.    ! CFL ????�?    REAL(wp) :: cfl_safety    = 0.9_wp    ! CFL ????
    REAL(wp) :: omega_max    = 0.0_wp    ! ???????????
  END TYPE RT_DynExpl_TimeCfg

  TYPE, PUBLIC :: RT_DynExpl_State
    INTEGER(i4) :: current_increment = 0_i4
    REAL(wp)    :: current_time      = 0.0_wp
    REAL(wp), POINTER :: displacement(:) => NULL()  ! u_{n+1}
    REAL(wp), POINTER :: velocity_half(:) => NULL()  ! v_{n+1/2}
    LOGICAL     :: converged           = .FALSE.
  END TYPE RT_DynExpl_State

  TYPE, PUBLIC :: RT_DynExpl_Ctx
    REAL(wp), POINTER :: v_n_half(:)   => NULL()  ! v_{n-1/2}
    REAL(wp), POINTER :: F_ext(:)      => NULL()  ! External force vector
    REAL(wp), POINTER :: R(:)         => NULL()  ! Residual: F_ext - F_int
    REAL(wp), ALLOCATABLE :: M_diag(:)  => NULL()  ! Lumped mass diagonal
    REAL(wp), POINTER :: work1(:)     => NULL()  ! Workspace vectors
    REAL(wp), POINTER :: work2(:)     => NULL()
    REAL(wp)          :: dt_effective   = 0.0_wp  ! ????????
    INTEGER(i4)       :: newton_iter   = 0_i4
    LOGICAL           :: cfl_clamp     = .FALSE.  ! CFL ????
  END TYPE RT_DynExpl_Ctx

  !=============================================================================
  ! ??????????????
  !=============================================================================
  TYPE, PUBLIC :: RT_DynExpl_Runner
    INTEGER(i4)           :: n_node      = 0_i4
    INTEGER(i4)           :: n_dof       = 0_i4
    INTEGER(i4)           :: n_ip        = 0_i4
    INTEGER(i4)           :: load_type   = 0_i4
    INTEGER(i4)           :: ctype       = 0_i4
    INTEGER(i4)           :: idof        = 0_i4
    INTEGER(i4)           :: face_id     = 0_i4
    REAL(wp)              :: xi          = 0.0_wp
    REAL(wp)              :: eta         = 0.0_wp
    REAL(wp)              :: zeta        = 0.0_wp
    REAL(wp)              :: penalty     = 0.0_wp
    REAL(wp)              :: val         = 0.0_wp
    REAL(wp)              :: tol         = 1.0e-12_wp
    REAL(wp), POINTER     :: coords(:,:) => NULL()
    REAL(wp), POINTER     :: u_elem(:)   => NULL()
    REAL(wp), POINTER     :: D(:,:)      => NULL()
    REAL(wp), POINTER     :: Ke(:,:)     => NULL()
    REAL(wp), POINTER     :: F_eq(:)     => NULL()
    REAL(wp), POINTER     :: state(:)    => NULL()
    REAL(wp), POINTER     :: stress(:)   => NULL()
    REAL(wp), POINTER     :: strain(:)   => NULL()
    REAL(wp), POINTER     :: F_def(:,:)  => NULL()
    REAL(wp), POINTER     :: R_int(:)    => NULL()
  END TYPE RT_DynExpl_Runner

  !=============================================================================
  ! ??????????????
  !=============================================================================
  TYPE, PUBLIC :: RT_DynImpl_Runner
    INTEGER(i4)           :: n_node      = 0_i4
    INTEGER(i4)           :: n_dof       = 0_i4
    INTEGER(i4)           :: n_ip        = 0_i4
    INTEGER(i4)           :: load_type   = 0_i4
    INTEGER(i4)           :: ctype       = 0_i4
    INTEGER(i4)           :: idof        = 0_i4
    INTEGER(i4)           :: face_id     = 0_i4
    REAL(wp)              :: xi          = 0.0_wp
    REAL(wp)              :: eta         = 0.0_wp
    REAL(wp)              :: zeta        = 0.0_wp
    REAL(wp)              :: penalty     = 0.0_wp
    REAL(wp)              :: val         = 0.0_wp
    REAL(wp)              :: tol         = 1.0e-12_wp
    REAL(wp), POINTER     :: coords(:,:) => NULL()
    REAL(wp), POINTER     :: u_elem(:)   => NULL()
    REAL(wp), POINTER     :: D(:,:)      => NULL()
    REAL(wp), POINTER     :: Ke(:,:)     => NULL()
    REAL(wp), POINTER     :: F_eq(:)     => NULL()
    REAL(wp), POINTER     :: state(:)    => NULL()
    REAL(wp), POINTER     :: stress(:)   => NULL()
    REAL(wp), POINTER     :: strain(:)   => NULL()
    REAL(wp), POINTER     :: F_def(:,:)  => NULL()
    REAL(wp), POINTER     :: R_int(:)    => NULL()
  END TYPE RT_DynImpl_Runner

  !=============================================================================
  ! Phase ????�?  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PHASE_INIT       = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PHASE_INCREMENT   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PHASE_CONVERGED   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PHASE_CUTBACK     = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PHASE_COMPLETED   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PHASE_FAILED      = 5_i4

  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_INIT      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_RUNNING    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_INCREMENT  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_ITERATION  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_DONE       = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_FAILED    = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_ROLLBACK  = 6_i4

  !=============================================================================
  ! Job ????�?  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEPDRV_CONTROL_AUTO    = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEPDRV_CONTROL_MANUAL  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEPDRV_SEQ_LINEAR      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEPDRV_SEQ_COUPLED     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEPDRV_SEQ_SEQUENTIAL  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEPDRV_CRIT_RESIDUAL   = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEPDRV_CRIT_DISPL      = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEPDRV_CRIT_ENERGY     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEPDRV_CRIT_MIXED      = 3_i4

  !=============================================================================
  ! Job �?Desc �?  !=============================================================================
  TYPE, PUBLIC :: RT_StepDrv_Desc
    CHARACTER(len=64) :: job_name               = ""
    INTEGER(i4)       :: n_steps                = 0
    INTEGER(i4), POINTER :: step_types(:)       => NULL()
    REAL(wp), POINTER    :: step_times(:)       => NULL()
    REAL(wp)          :: default_initial_dt     = 0.1_wp
    REAL(wp)          :: default_min_dt         = 1.0e-12_wp
    REAL(wp)          :: default_max_dt         = 1.0e30_wp
    INTEGER(i4)       :: default_max_increments = 100_i4
    INTEGER(i4)       :: default_max_iterations = 15_i4
    REAL(wp)          :: default_tolerance      = 1.0e-6_wp
    INTEGER(i4), POINTER :: material_ids(:)     => NULL()
    INTEGER(i4), POINTER :: element_ids(:)      => NULL()
    INTEGER(i4), POINTER :: load_ids(:)         => NULL()
    INTEGER(i4), POINTER :: bc_ids(:)           => NULL()
  END TYPE RT_StepDrv_Desc

  !=============================================================================
  ! Job �?State �?  !=============================================================================
  TYPE, PUBLIC :: RT_StepDrv_State
    INTEGER(i4)       :: current_step         = 0_i4
    INTEGER(i4)       :: current_increment    = 0_i4
    INTEGER(i4)       :: current_iteration    = 0_i4
    REAL(wp)          :: current_time         = 0.0_wp
    REAL(wp)          :: current_dt           = 0.1_wp
    REAL(wp)          :: total_time_completed = 0.0_wp
    LOGICAL           :: step_converged       = .FALSE.
    LOGICAL           :: inc_converged        = .FALSE.
    LOGICAL           :: iter_converged       = .FALSE.
    LOGICAL           :: job_converged        = .FALSE.
    LOGICAL           :: job_failed           = .FALSE.
    LOGICAL           :: cutback_active       = .FALSE.
    INTEGER(i4)       :: total_cutbacks       = 0_i4
    TYPE(RT_Step_State)  :: step_state
    TYPE(RT_Inc_State)   :: inc_state
    TYPE(RT_Iter_State)  :: iter_state
  CONTAINS
    PROCEDURE :: Reset
  END TYPE RT_StepDrv_State

  !=============================================================================
  ! Job �?Algo �?  !=============================================================================
  TYPE, PUBLIC :: RT_StepDrv_Algo
    INTEGER(i4) :: job_control_method     = RT_STEPDRV_CONTROL_AUTO
    INTEGER(i4) :: step_sequence_strategy = RT_STEPDRV_SEQ_LINEAR
    REAL(wp)    :: dt_increase_factor     = 1.25_wp
    REAL(wp)    :: dt_decrease_factor     = 0.5_wp
    INTEGER(i4) :: optimal_iterations     = 5_i4
    INTEGER(i4) :: max_cutbacks           = 10_i4
    REAL(wp)    :: cutback_threshold      = 1.5_wp
    INTEGER(i4) :: convergence_criterion  = RT_STEPDRV_CRIT_MIXED
    REAL(wp)    :: residual_tolerance     = 1.0e-6_wp
    REAL(wp)    :: displacement_tolerance = 1.0e-8_wp
    REAL(wp)    :: energy_tolerance       = 1.0e-12_wp
    LOGICAL     :: use_line_search        = .TRUE.
    REAL(wp)    :: line_search_tol        = 0.8_wp
    INTEGER(i4) :: max_line_search        = 5_i4
  END TYPE RT_StepDrv_Algo

  !=============================================================================
  ! Job �?Ctx �?  !=============================================================================
  TYPE, PUBLIC :: RT_StepDrv_Ctx
    TYPE(RT_Step_Ctx)  :: step_ctx
    TYPE(RT_Inc_Ctx)   :: inc_ctx
    TYPE(RT_Iter_Ctx)  :: iter_ctx
    REAL(wp), POINTER :: u_global(:)           => NULL()
    REAL(wp), POINTER :: v_global(:)           => NULL()
    REAL(wp), POINTER :: a_global(:)           => NULL()
    REAL(wp), POINTER :: u_current(:)          => NULL()
    REAL(wp), POINTER :: u_previous(:)         => NULL()
    REAL(wp), POINTER :: u_increment(:)        => NULL()
    REAL(wp), POINTER :: f_external(:)         => NULL()
    REAL(wp), POINTER :: f_internal(:)         => NULL()
    REAL(wp), POINTER :: f_residual(:)         => NULL()
    REAL(wp), POINTER :: work1(:)              => NULL()
    REAL(wp), POINTER :: work2(:)              => NULL()
    REAL(wp), POINTER :: work3(:)              => NULL()
    REAL(wp)          :: temp_norm_1           = 0.0_wp
    REAL(wp)          :: temp_norm_2           = 0.0_wp
    REAL(wp)          :: temp_energy           = 0.0_wp
    REAL(wp)          :: temp_power            = 0.0_wp
  END TYPE RT_StepDrv_Ctx

  PUBLIC :: RT_StepDriver_TimeCfg
  PUBLIC :: RT_StepDriver_Desc, RT_StepDriver_State, RT_StepDriver_Algo, RT_Step_Ctx
  PUBLIC :: RT_StepDriver_Result
  PUBLIC :: RT_Step_Inc_Evo_Desc, RT_Step_Itr_Com_Desc
  PUBLIC :: RT_Step_Inc_Evo_State, RT_Step_Stp_Ctl_State
  PUBLIC :: RT_Step_Stp_Ctl_Algo
  PUBLIC :: RT_Step_Inc_Evo_Ctx, RT_Step_Itr_Com_Ctx
  PUBLIC :: RT_Step_Desc, RT_Step_State, RT_Step_Algo
  PUBLIC :: RT_Inc_State, RT_Iter_State
  PUBLIC :: RT_Inc_Ctx, RT_Iter_Ctx
  PUBLIC :: RT_STEP_IDLE, RT_STEP_RUNNING, RT_STEP_CONVERGED, RT_STEP_CUTBACK, &
            RT_STEP_FAILED, RT_STEP_COMPLETED
  PUBLIC :: RT_INC_IDLE, RT_INC_PREDICTING, RT_INC_ITERATING, RT_INC_CONVERGED, &
            RT_INC_CUTBACK, RT_INC_FAILED
  PUBLIC :: RT_ITER_NOT_STARTED, RT_ITER_ASSEMBLING, RT_ITER_SOLVING, &
            RT_ITER_UPDATING, RT_ITER_CHECKING, RT_ITER_CONVERGED, &
            RT_ITER_CONTINUING, RT_ITER_DIVERGED
  PUBLIC :: STEP_CAT_STD, STEP_CAT_IMPL, STEP_CAT_EXPL
  PUBLIC :: RT_StepRuntimeCfg
  PUBLIC :: RT_StepDTCtrl, RT_ImplicitStepTimeCfg, RT_ExplicitStepTimeCfg
  PUBLIC :: RT_ImplicitStepCfg, RT_ExplicitStepCfg
  PUBLIC :: INTEG_NEWMARK_BETA, INTEG_HHT_ALPHA, INTEG_CENTRAL_DIFF
  PUBLIC :: RT_DynImpl_TimeCfg, RT_DynImpl_State, RT_DynImpl_Ctx
  PUBLIC :: RT_DynExpl_TimeCfg, RT_DynExpl_State, RT_DynExpl_Ctx
  PUBLIC :: RT_DynExpl_Runner
  PUBLIC :: RT_DynImpl_Runner
  PUBLIC :: RT_PHASE_INIT, RT_PHASE_INCREMENT, RT_PHASE_CONVERGED, &
       RT_PHASE_CUTBACK, RT_PHASE_COMPLETED, RT_PHASE_FAILED
  PUBLIC :: STEP_STATE_INIT, STEP_STATE_RUNNING, STEP_STATE_INCREMENT, &
       STEP_STATE_ITERATION, STEP_STATE_DONE, STEP_STATE_FAILED, STEP_STATE_ROLLBACK
  PUBLIC :: RT_STEPDRV_CONTROL_AUTO, RT_STEPDRV_CONTROL_MANUAL
  PUBLIC :: RT_STEPDRV_SEQ_LINEAR, RT_STEPDRV_SEQ_COUPLED, RT_STEPDRV_SEQ_SEQUENTIAL
  PUBLIC :: RT_STEPDRV_CRIT_RESIDUAL, RT_STEPDRV_CRIT_DISPL, RT_STEPDRV_CRIT_ENERGY, &
            RT_STEPDRV_CRIT_MIXED
  PUBLIC :: RT_StepDrv_Desc, RT_StepDrv_State, RT_StepDrv_Algo, RT_StepDrv_Ctx
  PUBLIC :: RT_Step_Drive_Arg, RT_Step_Incr_Arg

CONTAINS

  SUBROUTINE StepDrv_State_Reset(this)
    CLASS(RT_StepDrv_State), INTENT(INOUT) :: this
    this%current_step = 0_i4
    this%current_increment = 0_i4
    this%current_iteration = 0_i4
    this%current_time = 0.0_wp
    this%current_dt = 0.1_wp
    this%total_time_completed = 0.0_wp
    this%step_converged = .FALSE.
    this%inc_converged = .FALSE.
    this%iter_converged = .FALSE.
    this%job_converged = .FALSE.
    this%job_failed = .FALSE.
    this%cutback_active = .FALSE.
    this%total_cutbacks = 0_i4
  END SUBROUTINE StepDrv_State_Reset

!===============================================================================
! SIO unified Arg types for StepDriver domain
!===============================================================================
TYPE, PUBLIC :: RT_Step_Drive_Arg
  ! [IN] step driver state
  TYPE(RT_Step_Desc) :: desc              ! [IN]  step descriptor
  TYPE(RT_Step_State) :: state            ! [INOUT] step state
  TYPE(RT_Step_Algo) :: algo             ! [IN]  algorithm params
  TYPE(RT_Step_Ctx) :: ctx               ! [INOUT] step context

  ! [IN] step parameters
  REAL(wp) :: step_time                  ! [IN]  total step time
  INTEGER(i4) :: n_increments            ! [IN]  target increments

  ! [OUT] step results
  LOGICAL :: step_completed              ! [OUT] step completed flag
  REAL(wp) :: final_time                 ! [OUT] actual final time
  INTEGER(i4) :: status_code             ! [OUT] step status
  CHARACTER(len=256) :: message          ! [OUT] status message
END TYPE RT_Step_Drive_Arg

TYPE, PUBLIC :: RT_Step_Incr_Arg
  ! [IN] increment state
  TYPE(RT_Step_Desc) :: desc              ! [IN]  step descriptor
  TYPE(RT_Step_State) :: state            ! [INOUT] step state
  TYPE(RT_Step_Ctx) :: ctx               ! [INOUT] step context

  ! [IN] increment parameters
  REAL(wp) :: time_increment            ! [IN]  time increment size
  INTEGER(i4) :: incr_number            ! [IN]  increment number

  ! [OUT] increment results
  LOGICAL :: accepted                    ! [OUT] increment accepted
  REAL(wp) :: suggested_dt              ! [OUT] suggested next dt
  INTEGER(i4) :: status_code             ! [OUT] increment status
  CHARACTER(len=256) :: message          ! [OUT] status message
END TYPE RT_Step_Incr_Arg

END MODULE RT_Step_Def
