!=======================================================================
! Module: RT_State_Types                                  [Template v1.0]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Cross-domain runtime state containers
!
! Purpose:
!   Per-domain runtime State types that aggregate all active per-subroutine
!   State objects across one analysis increment.  These are owned by the
!   runtime scheduler and survive between increments (unlike Ctx, which is
!   call-scoped).
!
!   Nine domains match RT_Domain_Types.f90 one-to-one:
!     Mat / Elem / Load / BC / Contact / Fric / Constr / Field / Analy
!
! Naming convention:
!   RT_<Domain>_State   — aggregate runtime state for a domain
!=======================================================================
MODULE RT_State_Types
  USE IF_Prec_Core
  USE IF_Err_Brg,  ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !=====================================================================
  ! RT_Mat_State — runtime material state aggregator
  !   Tracks which materials are active, their last pnewdt, and
  !   whether the material pass converged in the last increment.
  !=====================================================================
  TYPE, PUBLIC :: RT_Mat_State
    INTEGER(i4) :: n_active    = 0_i4      ! number of active UMAT/VUMAT materials
    INTEGER(i4) :: n_converged = 0_i4      ! number that converged
    REAL(wp)    :: pnewdt_min  = 1.0_wp    ! minimum pnewdt across all mat calls
    INTEGER(i4) :: n_cutbacks  = 0_i4      ! total cutbacks in this increment
    LOGICAL     :: all_converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mat_State

  !=====================================================================
  ! RT_Elem_State — runtime element state aggregator
  !=====================================================================
  TYPE, PUBLIC :: RT_Elem_State
    INTEGER(i4) :: n_active     = 0_i4
    INTEGER(i4) :: n_converged  = 0_i4
    REAL(wp)    :: pnewdt_min   = 1.0_wp
    REAL(wp)    :: dt_stable    = HUGE(1.0_wp)  ! minimum stable time step (explicit)
    INTEGER(i4) :: n_locking    = 0_i4          ! locking flags raised
    LOGICAL     :: all_converged= .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Elem_State

  !=====================================================================
  ! RT_Load_State — runtime load state aggregator
  !=====================================================================
  TYPE, PUBLIC :: RT_Load_State
    INTEGER(i4) :: n_active       = 0_i4
    REAL(wp)    :: total_force_norm = 0.0_wp   ! |F_ext| norm
    REAL(wp)    :: total_flux_norm  = 0.0_wp   ! thermal flux norm
    LOGICAL     :: follower_load   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Load_State

  !=====================================================================
  ! RT_BC_State — runtime boundary condition state aggregator
  !=====================================================================
  TYPE, PUBLIC :: RT_BC_State
    INTEGER(i4) :: n_active         = 0_i4
    INTEGER(i4) :: n_disp_dofs      = 0_i4   ! prescribed displacement DOFs
    INTEGER(i4) :: n_temp_nodes     = 0_i4   ! prescribed temperature nodes
    REAL(wp)    :: max_prescribed   = 0.0_wp  ! max prescribed magnitude
    TYPE(ErrorStatusType) :: status
  END TYPE RT_BC_State

  !=====================================================================
  ! RT_Contact_State — runtime contact state aggregator
  !=====================================================================
  TYPE, PUBLIC :: RT_Contact_State
    INTEGER(i4) :: n_active        = 0_i4
    INTEGER(i4) :: n_contact_pairs = 0_i4   ! active contact pairs
    INTEGER(i4) :: n_slip_nodes    = 0_i4   ! slipping nodes
    REAL(wp)    :: contact_force_norm = 0.0_wp
    LOGICAL     :: any_new_contact = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Contact_State

  !=====================================================================
  ! RT_Fric_State — runtime friction state aggregator
  !=====================================================================
  TYPE, PUBLIC :: RT_Fric_State
    INTEGER(i4) :: n_active       = 0_i4
    INTEGER(i4) :: n_stick        = 0_i4  ! stick nodes
    INTEGER(i4) :: n_slip         = 0_i4  ! slip nodes
    REAL(wp)    :: max_slip_incr  = 0.0_wp
    REAL(wp)    :: fric_work      = 0.0_wp  ! frictional dissipation
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Fric_State

  !=====================================================================
  ! RT_Constr_State — runtime constraint state aggregator
  !=====================================================================
  TYPE, PUBLIC :: RT_Constr_State
    INTEGER(i4) :: n_active        = 0_i4
    INTEGER(i4) :: n_mpc_equations = 0_i4
    REAL(wp)    :: constr_residual = 0.0_wp  ! constraint violation norm
    LOGICAL     :: all_satisfied   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Constr_State

  !=====================================================================
  ! RT_Field_State — runtime predefined field state aggregator
  !=====================================================================
  TYPE, PUBLIC :: RT_Field_State
    INTEGER(i4) :: n_active     = 0_i4
    INTEGER(i4) :: n_sdv_fields = 0_i4   ! SDVINI fields initialised
    INTEGER(i4) :: n_sig_fields = 0_i4   ! SIGINI stress fields applied
    REAL(wp)    :: pnewdt_min   = 1.0_wp  ! from USDFLD
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Field_State

  !=====================================================================
  ! RT_Analy_State — runtime analysis utility state aggregator
  !=====================================================================
  TYPE, PUBLIC :: RT_Analy_State
    INTEGER(i4) :: n_active        = 0_i4
    INTEGER(i4) :: lop_last        = 0_i4   ! last LOP value (UEXTERNALDB)
    LOGICAL     :: amp_evaluated   = .FALSE.
    LOGICAL     :: uvarm_evaluated = .FALSE.
    REAL(wp)    :: uvarm_max_val   = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Analy_State

  ! ----------------------------------------------------------------
  !> @type RT_Global_Agg_State
  !> @brief 全局聚合状态（每增量步沿所有域汇总，State类）
  !>
  !> 将各域运行时状态聚合为单一须传给L5_RT上层控制器的全局快照。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: RT_Global_Agg_State
    TYPE(RT_Mat_State)     :: mat
    TYPE(RT_Elem_State)    :: elem
    TYPE(RT_Load_State)    :: load
    TYPE(RT_BC_State)      :: bc
    TYPE(RT_Contact_State) :: contact
    TYPE(RT_Fric_State)    :: fric
    TYPE(RT_Constr_State)  :: constr
    TYPE(RT_Field_State)   :: field
    TYPE(RT_Analy_State)   :: analy
    INTEGER(i4)            :: step_id      = 0_i4   ! 当前步号
    INTEGER(i4)            :: inc_id       = 0_i4   ! 当前增量步号
    INTEGER(i4)            :: nr_iter      = 0_i4   ! Newton迭代次数
    REAL(wp)               :: total_time   = 0.0_wp ! 总时间
    REAL(wp)               :: step_time    = 0.0_wp ! 当前步时间
    LOGICAL                :: converged    = .FALSE. ! 当前增量已收敛
    TYPE(ErrorStatusType)  :: status
  END TYPE RT_Global_Agg_State

END MODULE RT_State_Types
