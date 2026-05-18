!===============================================================================
! MODULE:  RT_BC_Impl_Def
! LAYER:   L5_RT
! DOMAIN:  BC
! ROLE:    Impl_Def
! BRIEF:   Implementation-layer types for BC.
!===============================================================================
MODULE RT_BC_Impl_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: init_error_status
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: RT_BC_Impl_Desc
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
    INTEGER(i4) :: n_bcs = 0_i4
    INTEGER(i4) :: amp_id = 0_i4
    LOGICAL :: is_active = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => BddI
    PROCEDURE, PASS :: Clean => BddC
  END TYPE

  TYPE, PUBLIC :: RT_BC_Impl_State
    INTEGER(i4) :: num_ips = 0_i4
    INTEGER(i4) :: total_cutbacks = 0_i4
    INTEGER(i4) :: total_iterations = 0_i4
    LOGICAL :: state_committed = .FALSE.
    LOGICAL :: bc_applied = .FALSE.
    LOGICAL :: cutback_active = .FALSE.
    REAL(wp) :: current_amp = 1.0_wp
    REAL(wp) :: accumulated_work = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init => BdsI
    PROCEDURE, PASS :: Clean => BdsC
  END TYPE

  TYPE, PUBLIC :: RT_BC_Impl_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4
    INTEGER(i4) :: max_cutbacks = 10_i4
    LOGICAL :: auto_cutback_enabled = .TRUE.
    REAL(wp) :: cutback_factor = 0.5_wp
    REAL(wp) :: load_convergence_tol = 1.0e-6_wp
  CONTAINS
    PROCEDURE, PASS :: Init => BdaI
  END TYPE

  TYPE, PUBLIC :: RT_BC_Impl_Ctx
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_incr = 0_i4
    INTEGER(i4) :: current_iter = 0_i4
    INTEGER(i4) :: analysis_type = 1_i4
    LOGICAL :: nlgeom = .FALSE.
    REAL(wp) :: time_increment = 0.0_wp
    REAL(wp) :: step_time = 0.0_wp
    REAL(wp) :: total_time = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init => BdcI
    PROCEDURE, PASS :: Clean => BdcC
  END TYPE

CONTAINS

  SUBROUTINE BddI(this, mat_id, l4_slot)
    CLASS(RT_BC_Impl_Desc), INTENT(OUT) :: this
    INTEGER(i4), INTENT(IN) :: mat_id, l4_slot
    this%mat_id = mat_id
    this%l4_slot_index = l4_slot
    this%is_active = .TRUE.
    this%n_bcs = 0
    this%amp_id = 0
  END SUBROUTINE

  SUBROUTINE BddC(this)
    CLASS(RT_BC_Impl_Desc), INTENT(INOUT) :: this
    this%is_active = .FALSE.
    this%n_bcs = 0
    this%amp_id = 0
  END SUBROUTINE

  SUBROUTINE BdsI(this, num_ips)
    CLASS(RT_BC_Impl_State), INTENT(OUT) :: this
    INTEGER(i4), INTENT(IN) :: num_ips
    this%num_ips = num_ips
    this%state_committed = .FALSE.
    this%bc_applied = .FALSE.
    this%cutback_active = .FALSE.
    this%total_cutbacks = 0
    this%total_iterations = 0
    this%current_amp = 1.0_wp
    this%accumulated_work = 0.0_wp
  END SUBROUTINE

  SUBROUTINE BdsC(this)
    CLASS(RT_BC_Impl_State), INTENT(INOUT) :: this
    this%num_ips = 0
    this%state_committed = .FALSE.
    this%bc_applied = .FALSE.
    this%cutback_active = .FALSE.
    this%total_cutbacks = 0
    this%total_iterations = 0
    this%current_amp = 1.0_wp
    this%accumulated_work = 0.0_wp
  END SUBROUTINE

  SUBROUTINE BdaI(this)
    CLASS(RT_BC_Impl_Algo), INTENT(OUT) :: this
    this%dispatch_strategy = 0
    this%auto_cutback_enabled = .TRUE.
    this%max_cutbacks = 10
    this%cutback_factor = 0.5_wp
    this%load_convergence_tol = 1.0e-6_wp
  END SUBROUTINE

  SUBROUTINE BdcI(this)
    CLASS(RT_BC_Impl_Ctx), INTENT(OUT) :: this
    this%current_step = 0
    this%current_incr = 0
    this%current_iter = 0
    this%analysis_type = 1
    this%nlgeom = .FALSE.
    this%time_increment = 0.0_wp
    this%step_time = 0.0_wp
    this%total_time = 0.0_wp
  END SUBROUTINE

  SUBROUTINE BdcC(this)
    CLASS(RT_BC_Impl_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE

END MODULE RT_BC_Impl_Def
