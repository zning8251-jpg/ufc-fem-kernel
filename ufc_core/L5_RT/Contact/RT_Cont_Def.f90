!===============================================================================
! MODULE: RT_Cont_Def
! LAYER:  L5_RT
! DOMAIN: Contact
! ROLE:   Def ?? AUTHORITY four-type definitions
! BRIEF:  Desc/State/Algo/Ctx + RT_CONT_* constants for Contact domain.
!===============================================================================
!
! Four-Type System:
!   RT_Contact_Desc   ?? cold pair configuration (write-once per step)
!   RT_Contact_State  ?? runtime state (per-iteration, hot-path RW)
!   RT_Contact_Algo   ?? algorithm parameters (cold, step-level cache)
!   RT_Contact_Ctx    ?? hot-path transient buffer (stack / pre-allocated)
!
! Constant Naming:
!   RT_CONT_DISC_*       discretization method
!   RT_CONT_ENFORCE_*    constraint enforcement method
!   RT_CONT_NORMAL_*     normal contact law
!   RT_CONT_FRICTION_*   friction model
!   RT_CONT_PAIR_*       pair status
!
! Status: ACTIVE | AUTHORITY | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Cont_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Public types ?? four-type system
  !=============================================================================
  PUBLIC :: RT_Contact_Desc
  PUBLIC :: RT_Contact_State
  PUBLIC :: RT_Contact_Algo
  PUBLIC :: RT_Contact_Ctx
  PUBLIC :: RT_Cont_Dispatch_Arg

  !=============================================================================
  ! Constants ?? aligned with template naming (RT_CONT_* prefix)
  !=============================================================================

  !-- Discretization method
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_DISC_NODE_TO_SURF = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_DISC_SURF_TO_SURF = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_DISC_MORTAR       = 2_i4

  !-- Constraint enforcement
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_ENFORCE_PENALTY      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_ENFORCE_LAGRANGE     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_ENFORCE_AUG_LAGRANGE = 2_i4

  !-- Normal contact law
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_NORMAL_HARD        = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_NORMAL_SOFT        = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_NORMAL_EXPONENTIAL = 2_i4

  !-- Friction model
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_FRICTION_NONE    = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_FRICTION_COULOMB = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_FRICTION_ROUGH   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_FRICTION_VISCOUS = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_FRICTION_USER    = 4_i4

  !-- Pair status
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_PAIR_OPEN     = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_PAIR_CLOSED   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_PAIR_SLIDING  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONT_PAIR_STICKING = 3_i4

  !-- Backward-compatible aliases (deprecated ?? use RT_CONT_* names)
  INTEGER(i4), PARAMETER, PUBLIC :: CONTACT_DISC_NODE_TO_SURF   = RT_CONT_DISC_NODE_TO_SURF
  INTEGER(i4), PARAMETER, PUBLIC :: CONTACT_DISC_SURF_TO_SURF   = RT_CONT_DISC_SURF_TO_SURF
  INTEGER(i4), PARAMETER, PUBLIC :: CONTACT_DISC_MORTAR         = RT_CONT_DISC_MORTAR
  INTEGER(i4), PARAMETER, PUBLIC :: CONTACT_CONSTRAINT_PENALTY      = RT_CONT_ENFORCE_PENALTY
  INTEGER(i4), PARAMETER, PUBLIC :: CONTACT_CONSTRAINT_LAGRANGE     = RT_CONT_ENFORCE_LAGRANGE
  INTEGER(i4), PARAMETER, PUBLIC :: CONTACT_CONSTRAINT_AUG_LAGRANGE = RT_CONT_ENFORCE_AUG_LAGRANGE
  INTEGER(i4), PARAMETER, PUBLIC :: FRICTION_NONE    = RT_CONT_FRICTION_NONE
  INTEGER(i4), PARAMETER, PUBLIC :: FRICTION_COULOMB = RT_CONT_FRICTION_COULOMB
  INTEGER(i4), PARAMETER, PUBLIC :: PAIR_OPEN     = RT_CONT_PAIR_OPEN
  INTEGER(i4), PARAMETER, PUBLIC :: PAIR_CLOSED   = RT_CONT_PAIR_CLOSED
  INTEGER(i4), PARAMETER, PUBLIC :: PAIR_SLIDING  = RT_CONT_PAIR_SLIDING
  INTEGER(i4), PARAMETER, PUBLIC :: PAIR_STICKING = RT_CONT_PAIR_STICKING
  
  !-----------------------------------------------------------------------------
  ! RT_Contact_Desc ?? Contact pair configuration (cold, read-only per step)
  ! Desc: stores model meta-info; write-once per step, read-many.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_Desc
    !-- Identity
    INTEGER(i4)       :: n_contact_pairs = 0_i4
    CHARACTER(LEN=64) :: contact_name    = ''
    LOGICAL           :: is_initialized  = .FALSE.

    !-- Contact pair surface IDs
    INTEGER(i4), POINTER :: master_surf_ids(:) => NULL()
    INTEGER(i4), POINTER :: slave_surf_ids(:)  => NULL()

    !-- Per-pair type and friction model (RT_CONT_* constants)
    INTEGER(i4), POINTER :: contact_types(:)   => NULL()
    INTEGER(i4), POINTER :: friction_models(:) => NULL()

    !-- Contact parameters
    REAL(wp), POINTER :: friction_coeffs(:)   => NULL()
    REAL(wp), POINTER :: penalty_stiffness(:) => NULL()
    REAL(wp), POINTER :: clearance(:)         => NULL()

    !-- Search tolerances
    REAL(wp) :: global_search_tol  = 1.0e-6_wp
    REAL(wp) :: local_search_tol   = 1.0e-8_wp
    REAL(wp) :: search_radius_factor = 1.1_wp

    !-- Initial adjustment
    LOGICAL  :: adjust_slave_nodes = .FALSE.
    REAL(wp) :: adjust_tolerance   = 1.0e-6_wp

  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: AddPair
    PROCEDURE :: SetFriction
    PROCEDURE :: Finalize
  END TYPE RT_Contact_Desc

  !-----------------------------------------------------------------------------
  ! RT_Contact_State ?? Contact runtime state (warm, per-iteration)
  ! State: stores dynamic computation results; hot-path read/write.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_State
    !-- Pair status (RT_CONT_PAIR_* constants)
    LOGICAL,     POINTER :: pair_active(:) => NULL()
    INTEGER(i4), POINTER :: pair_status(:) => NULL()
    INTEGER(i4) :: n_active_pairs = 0_i4
    INTEGER(i4) :: n_open_pairs   = 0_i4
    INTEGER(i4) :: n_closed_pairs = 0_i4

    !-- Global contact force
    REAL(wp), POINTER :: f_contact(:) => NULL()
    REAL(wp) :: total_contact_force = 0.0_wp
    REAL(wp) :: max_contact_force   = 0.0_wp

    !-- Gap / penetration statistics
    REAL(wp), POINTER :: penetration(:) => NULL()
    REAL(wp) :: max_penetration = 0.0_wp
    REAL(wp) :: avg_penetration = 0.0_wp
    REAL(wp) :: max_gap         = 0.0_wp

    !-- Friction state
    REAL(wp), POINTER :: friction_force(:) => NULL()
    LOGICAL,  POINTER :: is_sticking(:)    => NULL()
    INTEGER(i4) :: n_sticking = 0_i4
    INTEGER(i4) :: n_sliding  = 0_i4

    !-- Energy bookkeeping
    REAL(wp) :: contact_energy = 0.0_wp

    !-- Convergence
    LOGICAL           :: converged  = .FALSE.
    INTEGER(i4)       :: iterations = 0_i4
    TYPE(ErrorStatusType) :: status

    !-- Augmented Lagrange state (active only when enforcement_method == RT_CONT_ENFORCE_AUG_LAGRANGE)
    !   Double-buffer: lambda_n holds committed multipliers; lambda_trial holds trial values
    !   during the current Uzawa outer iteration.
    REAL(wp), POINTER :: lambda_n(:)     => NULL()  !< Committed Lagrange multipliers [n_pairs]
    REAL(wp), POINTER :: lambda_trial(:) => NULL()  !< Trial Lagrange multipliers    [n_pairs]
    INTEGER(i4)       :: uzawa_iter      = 0_i4     !< Current Uzawa outer-iteration counter
    LOGICAL           :: uzawa_converged = .FALSE.  !< .TRUE. when ||delta_lambda|| < tol_aug

  CONTAINS
    PROCEDURE :: Reset
    PROCEDURE :: UpdateStatus
    PROCEDURE :: AggregateStatistics
    PROCEDURE :: AugLagInit
    PROCEDURE :: AugLagCommit
    PROCEDURE :: AugLagRollback
  END TYPE RT_Contact_State

  !-----------------------------------------------------------------------------
  ! RT_Contact_Algo ?? Contact algorithm parameters (cold, Step-level cache)
  ! Algo: solver params, read-only within iteration.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_Algo
    !-- Discretization (RT_CONT_DISC_* constants)
    INTEGER(i4) :: discretization_method = RT_CONT_DISC_NODE_TO_SURF

    !-- Constraint enforcement (RT_CONT_ENFORCE_* constants)
    INTEGER(i4) :: enforcement_method    = RT_CONT_ENFORCE_PENALTY
    REAL(wp)    :: penalty_scale_factor  = 1.0_wp
    REAL(wp)    :: lagrange_init         = 0.0_wp

    !-- Friction (RT_CONT_FRICTION_* constants)
    INTEGER(i4) :: friction_model        = RT_CONT_FRICTION_COULOMB
    REAL(wp)    :: friction_decay_coeff  = 0.0_wp
    REAL(wp)    :: slip_tolerance        = 1.0e-8_wp

    !-- Search strategy
    INTEGER(i4) :: search_frequency  = 10_i4  ! Rebuild BVH every N increments
    LOGICAL     :: use_global_search = .TRUE.
    LOGICAL     :: use_adaptive_rebuild = .TRUE.

    !-- Contact damping
    LOGICAL  :: use_damping   = .FALSE.
    REAL(wp) :: damping_factor = 0.05_wp

    !-- Augmented Lagrange (Uzawa outer-iteration) parameters
    !   Only used when enforcement_method == RT_CONT_ENFORCE_AUG_LAGRANGE
    INTEGER(i4) :: n_aug_max = 5_i4         !< Max Uzawa outer iterations
    REAL(wp)    :: rho_aug   = 1.0_wp       !< Augmentation penalty  rho (lambda update scale)
    REAL(wp)    :: tol_aug   = 1.0e-6_wp    !< Uzawa convergence: ||delta_lambda||_inf < tol_aug

  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SelectEnforcement
    PROCEDURE :: ConfigureFriction
    PROCEDURE :: ConfigureSearch
    PROCEDURE :: ConfigureAugLag
  END TYPE RT_Contact_Algo

  !-----------------------------------------------------------------------------
  ! RT_Contact_Ctx ?? Hot-path context (no ALLOCATABLE; stack or pre-allocated)
  ! Ctx: transient buffer for cross-layer variable passing.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_Ctx
    !-- Current pair index
    INTEGER(i4) :: current_pair_idx = 0_i4

    !-- Temporary geometry (stack scalars)
    REAL(wp) :: gap_distance      = 0.0_wp
    REAL(wp) :: penetration_depth = 0.0_wp
    REAL(wp) :: contact_pressure  = 0.0_wp

    !-- Local frame (stack arrays ?? size fixed)
    REAL(wp) :: normal_vector(3)    = 0.0_wp
    REAL(wp) :: tangent_vector(3,2) = 0.0_wp
    REAL(wp) :: slip_direction(3)   = 0.0_wp

    !-- Closest-point projection
    REAL(wp) :: closest_pt(3) = 0.0_wp
    REAL(wp) :: gp_xi   = 0.0_wp
    REAL(wp) :: gp_eta  = 0.0_wp

    !-- Shape function scratch (N_master / N_slave up to 4 nodes)
    REAL(wp) :: shape_master(4) = 0.0_wp
    REAL(wp) :: shape_slave(4)  = 0.0_wp

    !-- Node/element indices
    INTEGER(i4) :: master_node_id  = 0_i4
    INTEGER(i4) :: slave_node_id   = 0_i4
    INTEGER(i4) :: contact_elem_id = 0_i4

    !-- Work pointers (must be attached before use; NO ALLOCATABLE here)
    REAL(wp), POINTER :: temp_force(:) => NULL()
    REAL(wp), POINTER :: temp_disp(:)  => NULL()

  CONTAINS
    PROCEDURE :: AttachBuffers
    PROCEDURE :: ClearTemporaries
    PROCEDURE :: Detach
  END TYPE RT_Contact_Ctx

  !-----------------------------------------------------------------------------
  ! SIO Arg type: RT_Cont_Dispatch_Arg
  ! Unified argument bundle for Contact domain dispatch (Brg / Core entry points).
  !-----------------------------------------------------------------------------

  !> @brief Unified argument bundle for contact domain dispatch.
  TYPE, PUBLIC :: RT_Cont_Dispatch_Arg
    ! [IN] contact state
    TYPE(RT_Contact_Desc) :: desc             ! [IN]  contact descriptor
    TYPE(RT_Contact_State) :: state           ! [INOUT] contact state
    TYPE(RT_Contact_Algo) :: algo             ! [IN]  algorithm params
    TYPE(RT_Contact_Ctx) :: ctx               ! [INOUT] contact context

    ! [IN] search parameters
    REAL(wp) :: search_tolerance              ! [IN]  gap tolerance
    REAL(wp) :: current_time                  ! [IN]  current time

    ! [OUT] contact results
    REAL(wp), ALLOCATABLE :: contact_forces(:,:) ! [OUT] contact forces
    INTEGER(i4) :: n_contact_pairs            ! [OUT] number of active pairs
    INTEGER(i4) :: status_code                ! [OUT] contact status
    CHARACTER(len=256) :: message             ! [OUT] status message
  END TYPE RT_Cont_Dispatch_Arg

END MODULE RT_Cont_Def

!===============================================================================
! MODULE: RT_Cont_Types_Impl
! LAYER:  L5_RT
! DOMAIN: Contact
! ROLE:   Impl
! BRIEF:  Bound procedure implementations for Contact four-type system.
!===============================================================================
MODULE RT_Cont_Types_Impl
  USE IF_Prec_Core,         ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Cont_Def
  IMPLICIT NONE
  PRIVATE

CONTAINS

  ! ---------------------------------------------------------------------------
  ! RT_Contact_Desc procedures
  ! ---------------------------------------------------------------------------
  SUBROUTINE RT_Cont_Desc_Init(self)
    CLASS(RT_Contact_Desc), INTENT(INOUT) :: self
    self%is_initialized = .TRUE.
  END SUBROUTINE RT_Cont_Desc_Init

  SUBROUTINE RT_Cont_Desc_AddPair(self, master_id, slave_id, contact_type)
    CLASS(RT_Contact_Desc), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN)           :: master_id, slave_id
    INTEGER(i4), INTENT(IN), OPTIONAL :: contact_type
    self%n_contact_pairs = self%n_contact_pairs + 1_i4
  END SUBROUTINE RT_Cont_Desc_AddPair

  SUBROUTINE RT_Cont_Desc_SetFriction(self, pair_idx, mu, friction_model)
    CLASS(RT_Contact_Desc), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN)           :: pair_idx
    REAL(wp),    INTENT(IN)           :: mu
    INTEGER(i4), INTENT(IN), OPTIONAL :: friction_model
    ! Implementation: set friction_coeffs(pair_idx) = mu; set model flag
  END SUBROUTINE RT_Cont_Desc_SetFriction

  SUBROUTINE RT_Cont_Desc_Finalize(self)
    CLASS(RT_Contact_Desc), INTENT(INOUT) :: self
    IF (ASSOCIATED(self%master_surf_ids))  DEALLOCATE(self%master_surf_ids)
    IF (ASSOCIATED(self%slave_surf_ids))   DEALLOCATE(self%slave_surf_ids)
    IF (ASSOCIATED(self%contact_types))    DEALLOCATE(self%contact_types)
    IF (ASSOCIATED(self%friction_models))  DEALLOCATE(self%friction_models)
    IF (ASSOCIATED(self%friction_coeffs))  DEALLOCATE(self%friction_coeffs)
    IF (ASSOCIATED(self%penalty_stiffness)) DEALLOCATE(self%penalty_stiffness)
    IF (ASSOCIATED(self%clearance))        DEALLOCATE(self%clearance)
    self%is_initialized = .FALSE.
  END SUBROUTINE RT_Cont_Desc_Finalize

  ! ---------------------------------------------------------------------------
  ! RT_Contact_State procedures
  ! ---------------------------------------------------------------------------
  SUBROUTINE RT_Cont_State_Reset(self)
    CLASS(RT_Contact_State), INTENT(INOUT) :: self
    IF (ASSOCIATED(self%pair_active))  self%pair_active  = .FALSE.
    IF (ASSOCIATED(self%pair_status))  self%pair_status  = RT_CONT_PAIR_OPEN
    IF (ASSOCIATED(self%f_contact))    self%f_contact    = 0.0_wp
    IF (ASSOCIATED(self%penetration))  self%penetration  = 0.0_wp
    IF (ASSOCIATED(self%friction_force)) self%friction_force = 0.0_wp
    IF (ASSOCIATED(self%is_sticking))  self%is_sticking  = .FALSE.
    self%n_active_pairs  = 0_i4
    self%n_open_pairs    = 0_i4
    self%n_closed_pairs  = 0_i4
    self%n_sticking      = 0_i4
    self%n_sliding       = 0_i4
    self%total_contact_force = 0.0_wp
    self%max_contact_force   = 0.0_wp
    self%max_penetration     = 0.0_wp
    self%avg_penetration     = 0.0_wp
    self%max_gap             = 0.0_wp
    self%contact_energy      = 0.0_wp
    self%converged           = .FALSE.
    self%iterations          = 0_i4
    !-- AugLag state reset (lambda pointers retained; counters zeroed)
    self%uzawa_iter      = 0_i4
    self%uzawa_converged = .FALSE.
    CALL init_error_status(self%status)
  END SUBROUTINE RT_Cont_State_Reset

  SUBROUTINE RT_Cont_State_UpdateStatus(self)
    CLASS(RT_Contact_State), INTENT(INOUT) :: self
    ! Compute n_open / n_closed from pair_status
    INTEGER(i4) :: i
    self%n_open_pairs   = 0_i4
    self%n_closed_pairs = 0_i4
    IF (.NOT. ASSOCIATED(self%pair_status)) RETURN
    DO i = 1, SIZE(self%pair_status)
      IF (self%pair_status(i) == RT_CONT_PAIR_OPEN) THEN
        self%n_open_pairs = self%n_open_pairs + 1_i4
      ELSE
        self%n_closed_pairs = self%n_closed_pairs + 1_i4
      END IF
    END DO
  END SUBROUTINE RT_Cont_State_UpdateStatus

  SUBROUTINE RT_Cont_State_AggregateStats(self)
    CLASS(RT_Contact_State), INTENT(INOUT) :: self
    INTEGER(i4) :: i, n
    REAL(wp) :: sum_pen
    IF (.NOT. ASSOCIATED(self%penetration)) RETURN
    n = SIZE(self%penetration)
    IF (n == 0) RETURN
    self%max_penetration = MAXVAL(self%penetration)
    sum_pen = 0.0_wp
    DO i = 1, n
      sum_pen = sum_pen + self%penetration(i)
    END DO
    self%avg_penetration = sum_pen / REAL(n, wp)
  END SUBROUTINE RT_Cont_State_AggregateStats

  ! ---------------------------------------------------------------------------
  ! RT_Contact_Algo procedures
  ! ---------------------------------------------------------------------------
  SUBROUTINE RT_Cont_Algo_Init(self)
    CLASS(RT_Contact_Algo), INTENT(INOUT) :: self
    self%discretization_method = RT_CONT_DISC_NODE_TO_SURF
    self%enforcement_method    = RT_CONT_ENFORCE_PENALTY
    self%penalty_scale_factor  = 1.0_wp
    self%lagrange_init         = 0.0_wp
    self%friction_model        = RT_CONT_FRICTION_COULOMB
    self%friction_decay_coeff  = 0.0_wp
    self%slip_tolerance        = 1.0e-8_wp
    self%search_frequency      = 10_i4
    self%use_global_search     = .TRUE.
    self%use_adaptive_rebuild  = .TRUE.
    self%use_damping           = .FALSE.
    self%damping_factor        = 0.05_wp
    !-- AugLag defaults (Uzawa outer-iteration)
    self%n_aug_max = 5_i4
    self%rho_aug   = 1.0_wp
    self%tol_aug   = 1.0e-6_wp
  END SUBROUTINE RT_Cont_Algo_Init

  SUBROUTINE RT_Cont_Algo_SelectEnforcement(self, method)
    CLASS(RT_Contact_Algo), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: method
    self%enforcement_method = method
  END SUBROUTINE RT_Cont_Algo_SelectEnforcement

  SUBROUTINE RT_Cont_Algo_ConfigureFriction(self, model, decay, slip_tol)
    CLASS(RT_Contact_Algo), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN)           :: model
    REAL(wp),    INTENT(IN), OPTIONAL :: decay, slip_tol
    self%friction_model = model
    IF (PRESENT(decay))    self%friction_decay_coeff = decay
    IF (PRESENT(slip_tol)) self%slip_tolerance       = slip_tol
  END SUBROUTINE RT_Cont_Algo_ConfigureFriction

  SUBROUTINE RT_Cont_Algo_ConfigureSearch(self, freq, use_global, adaptive)
    CLASS(RT_Contact_Algo), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN)           :: freq
    LOGICAL,     INTENT(IN), OPTIONAL :: use_global, adaptive
    self%search_frequency = freq
    IF (PRESENT(use_global)) self%use_global_search    = use_global
    IF (PRESENT(adaptive))   self%use_adaptive_rebuild = adaptive
  END SUBROUTINE RT_Cont_Algo_ConfigureSearch

  !> Configure Augmented Lagrange / Uzawa outer-iteration parameters.
  !> Call after SelectEnforcement(RT_CONT_ENFORCE_AUG_LAGRANGE).
  SUBROUTINE RT_Cont_Algo_ConfigureAugLag(self, n_max, rho, tol)
    CLASS(RT_Contact_Algo), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_max  !< Max Uzawa iterations (default 5)
    REAL(wp),    INTENT(IN), OPTIONAL :: rho    !< Augmentation penalty rho (default 1.0)
    REAL(wp),    INTENT(IN), OPTIONAL :: tol    !< Convergence tolerance (default 1e-6)
    IF (PRESENT(n_max)) self%n_aug_max = n_max
    IF (PRESENT(rho))   self%rho_aug   = rho
    IF (PRESENT(tol))   self%tol_aug   = tol
  END SUBROUTINE RT_Cont_Algo_ConfigureAugLag

  ! ---------------------------------------------------------------------------
  ! RT_Contact_Ctx procedures
  ! ---------------------------------------------------------------------------
  SUBROUTINE RT_Cont_Ctx_AttachBuffers(self, force_buf, disp_buf)
    CLASS(RT_Contact_Ctx), INTENT(INOUT) :: self
    REAL(wp), TARGET, INTENT(IN) :: force_buf(:), disp_buf(:)
    self%temp_force => force_buf
    self%temp_disp  => disp_buf
  END SUBROUTINE RT_Cont_Ctx_AttachBuffers

  SUBROUTINE RT_Cont_Ctx_ClearTemporaries(self)
    CLASS(RT_Contact_Ctx), INTENT(INOUT) :: self
    self%gap_distance      = 0.0_wp
    self%penetration_depth = 0.0_wp
    self%contact_pressure  = 0.0_wp
    self%normal_vector     = 0.0_wp
    self%tangent_vector    = 0.0_wp
    self%slip_direction    = 0.0_wp
    self%closest_pt        = 0.0_wp
    self%gp_xi             = 0.0_wp
    self%gp_eta            = 0.0_wp
    self%shape_master      = 0.0_wp
    self%shape_slave       = 0.0_wp
    self%master_node_id    = 0_i4
    self%slave_node_id     = 0_i4
    self%contact_elem_id   = 0_i4
    self%current_pair_idx  = 0_i4
  END SUBROUTINE RT_Cont_Ctx_ClearTemporaries

  SUBROUTINE RT_Cont_Ctx_Detach(self)
    CLASS(RT_Contact_Ctx), INTENT(INOUT) :: self
    NULLIFY(self%temp_force)
    NULLIFY(self%temp_disp)
  END SUBROUTINE RT_Cont_Ctx_Detach

  ! ---------------------------------------------------------------------------
  ! RT_Contact_State AugLag helper procedures
  ! ---------------------------------------------------------------------------

  !> Allocate / initialise Augmented Lagrange multiplier buffers.
  !> Must be called once after the number of contact pairs is known.
  SUBROUTINE RT_Cont_State_AugLagInit(self, n_pairs, lambda_init)
    CLASS(RT_Contact_State), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN)           :: n_pairs      !< Total number of contact pairs
    REAL(wp),    INTENT(IN), OPTIONAL :: lambda_init  !< Uniform initial multiplier (default 0)
    REAL(wp) :: lam0
    lam0 = 0.0_wp
    IF (PRESENT(lambda_init)) lam0 = lambda_init
    !-- Allocate lambda_n (committed)
    IF (.NOT. ASSOCIATED(self%lambda_n)) THEN
      ALLOCATE(self%lambda_n(n_pairs))
    ELSE IF (SIZE(self%lambda_n) /= n_pairs) THEN
      DEALLOCATE(self%lambda_n)
      ALLOCATE(self%lambda_n(n_pairs))
    END IF
    self%lambda_n = lam0
    !-- Allocate lambda_trial (working copy)
    IF (.NOT. ASSOCIATED(self%lambda_trial)) THEN
      ALLOCATE(self%lambda_trial(n_pairs))
    ELSE IF (SIZE(self%lambda_trial) /= n_pairs) THEN
      DEALLOCATE(self%lambda_trial)
      ALLOCATE(self%lambda_trial(n_pairs))
    END IF
    self%lambda_trial = lam0
    self%uzawa_iter      = 0_i4
    self%uzawa_converged = .FALSE.
  END SUBROUTINE RT_Cont_State_AugLagInit

  !> Commit Uzawa update: lambda_n <- lambda_trial.
  !> Called after global NR converges within one Uzawa iteration.
  !> Returns delta_lambda_norm (infinity norm) for convergence check.
  SUBROUTINE RT_Cont_State_AugLagCommit(self, delta_norm)
    CLASS(RT_Contact_State), INTENT(INOUT) :: self
    REAL(wp), INTENT(OUT) :: delta_norm  !< ||lambda_trial - lambda_n||_inf
    INTEGER(i4) :: i, n
    delta_norm = 0.0_wp
    IF (.NOT. ASSOCIATED(self%lambda_n) .OR. .NOT. ASSOCIATED(self%lambda_trial)) RETURN
    n = SIZE(self%lambda_n)
    DO i = 1, n
      delta_norm = MAX(delta_norm, ABS(self%lambda_trial(i) - self%lambda_n(i)))
    END DO
    !-- Commit: copy trial -> committed
    self%lambda_n = self%lambda_trial
    self%uzawa_iter = self%uzawa_iter + 1_i4
  END SUBROUTINE RT_Cont_State_AugLagCommit

  !> Rollback Uzawa trial: lambda_trial <- lambda_n (discard failed trial).
  !> Called if global NR diverges during an Uzawa iteration.
  SUBROUTINE RT_Cont_State_AugLagRollback(self)
    CLASS(RT_Contact_State), INTENT(INOUT) :: self
    IF (.NOT. ASSOCIATED(self%lambda_n) .OR. .NOT. ASSOCIATED(self%lambda_trial)) RETURN
    self%lambda_trial = self%lambda_n
  END SUBROUTINE RT_Cont_State_AugLagRollback

END MODULE RT_Cont_Types_Impl
