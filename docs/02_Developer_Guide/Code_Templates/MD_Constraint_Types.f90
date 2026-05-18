!===============================================================================
! Module: MD_Constraint_Types                                    [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Constraint — Universal Base Type Definitions
!
! Purpose:
!   Defines the Desc / State / Algo three-type system for constraint
!   computation at the MD_ (model-description) layer.
!
!   Abaqus subroutines covered:
!     - MPC   / UMPC   : Multi-point constraint (Standard)
!     - UMESHMOTION    : User mesh motion / ALE adaptive meshing
!     - ORIENT         : User-defined material orientation
!
!   Design notes:
!     - MPC defines kinematic relationships between DOFs at different nodes
!     - UMESHMOTION controls adaptive mesh motion in ALE analyses
!     - ORIENT provides orientation tensor for anisotropic materials/elements
!
! Type roles:
!   MD_Constr_Base_Desc  – Constraint parameters (loaded from INP)
!   MD_Constr_Base_State – Constraint state (reaction forces, slip)
!   MD_Constr_Base_Algo  – Algorithm configuration
!   MD_Constr_MPC_Desc   – MPC/UMPC-specific parameters
!   MD_Constr_Orient_Desc – ORIENT-specific parameters
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_Constraint_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Constr_Base_Desc
  PUBLIC :: MD_Constr_Base_State
  PUBLIC :: MD_Constr_Base_Algo
  PUBLIC :: MD_Constr_MPC_Desc
  PUBLIC :: MD_Constr_Orient_Desc

  !-- Constraint type enum
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_CONSTR_TYPE_MPC        = 1_i4  ! MPC/UMPC  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_CONSTR_TYPE_MESHMOTION = 2_i4  ! UMESHMOTION  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_CONSTR_TYPE_ORIENT     = 3_i4  ! ORIENT  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_CONSTR_TYPE_TIE        = 4_i4  ! Tie constraint  ! migrated

  !-- MPC type enum
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MPC_MPC_TYPE_LINEAR   = 1_i4  ! Linear combination  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MPC_MPC_TYPE_NONLINEAR = 2_i4 ! Nonlinear user-defined  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MPC_MPC_TYPE_RIGID     = 3_i4 ! Rigid body MPC  ! migrated

  !-----------------------------------------------------------------------------
  ! DESC — Constraint Descriptor (base, all constraint types)
  !    Concrete type; parameters loaded from INP.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_Base_Desc
    !-- Identity & metadata
    INTEGER(i4)       :: constr_id   = 0_i4   ! Constraint set ID
    INTEGER(i4)       :: constr_type = CONSTR_TYPE_MPC  ! Type enum
    CHARACTER(LEN=64) :: constr_name = ''     ! Human-readable label
    LOGICAL           :: is_initialized = .FALSE.
    !-- Node set configuration
    INTEGER(i4) :: n_nodes      = 0_i4  ! Number of nodes in constraint
    INTEGER(i4) :: n_dof        = 0_i4  ! Number of constrained DOFs
    !-- User properties
    INTEGER(i4) :: nprops       = 0_i4  ! Number of real properties
    REAL(wp), ALLOCATABLE :: props(:)   ! User properties array
  CONTAINS
    PROCEDURE :: Init  => Constr_Desc_Init
    PROCEDURE :: Reset => Constr_Desc_Reset
  END TYPE MD_Constr_Base_Desc

  !-----------------------------------------------------------------------------
  ! STATE — Constraint State at Increment Start
  !    Reaction forces and enforcement history.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_Base_State
    !-- Reaction force history
    REAL(wp), ALLOCATABLE :: react_force(:)  ! Reaction forces [N] per constrained DOF
    REAL(wp)              :: work_done = 0.0_wp  ! Work done by constraint [J]
    !-- Convergence bookkeeping
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Constr_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Analysis-Phase Configuration
  !    Constraint enforcement method selection.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_Base_Algo
    !-- Enforcement method
    INTEGER(i4) :: method       = 1_i4   ! 1=Lagrange, 2=penalty, 3=direct
    REAL(wp)    :: penalty_stiff = 1.0e6_wp ! Penalty stiffness [N/m]
    !-- Linearization
    LOGICAL     :: use_linearize = .TRUE. ! Linearize nonlinear MPC
    !-- Output
    LOGICAL :: print_debug = .FALSE.
  END TYPE MD_Constr_Base_Algo

  !-----------------------------------------------------------------------------
  ! MPC/UMPC-specific Desc
  !   MPC: kinematic constraint between master and slave nodes
  !   UMPC interface: CSLIP(DOF,NCPT), A(NDOFL,NCPT), ADOF(NDOFL)
  !   KEY fields:
  !     n_terms : number of nodes linked in this MPC
  !     dof_list: DOF indices for each node
  !     coeff_A : coefficient matrix A (linear combination)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_MPC_Desc
    INTEGER(i4) :: mpc_type      = MPC_TYPE_LINEAR ! MPC type enum
    INTEGER(i4) :: n_terms       = 2_i4  ! Terms in MPC equation
    INTEGER(i4) :: n_dof_per_node= 3_i4  ! DOFs per node (typically 3 or 6)
    INTEGER(i4), ALLOCATABLE :: node_ids(:)  ! Node IDs for each term
    INTEGER(i4), ALLOCATABLE :: dof_ids(:)   ! DOF indices for each term
    REAL(wp),    ALLOCATABLE :: coeff_A(:)   ! Coefficients in linear MPC
    REAL(wp)    :: const_b       = 0.0_wp    ! Constant term b in: A*u = b
  END TYPE MD_Constr_MPC_Desc

  !-----------------------------------------------------------------------------
  ! ORIENT-specific Desc
  !   ORIENT: user-defined local orientation for materials/elements
  !   Called for each material point with COORDS
  !   Returns: T (3x3 direction cosines) or angles
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_Orient_Desc
    INTEGER(i4) :: orient_type   = 1_i4      ! 1=angles, 2=direction cosines
    REAL(wp)    :: euler_angles(3) = 0.0_wp  ! Euler angles [deg]: ψ, φ, θ
    REAL(wp)    :: dir_cos(3,3)  = 0.0_wp    ! Direction cosines T(3,3)
    LOGICAL     :: is_field_dep  = .FALSE.   ! Orientation is field-dependent
  END TYPE MD_Constr_Orient_Desc

CONTAINS

  SUBROUTINE Constr_Desc_Init(self)
    CLASS(MD_Constr_Base_Desc), INTENT(INOUT) :: self
    IF (self%nprops > 0 .AND. .NOT. ALLOCATED(self%props)) THEN
      ALLOCATE(self%props(self%nprops))
      self%props = 0.0_wp
    END IF
    self%is_initialized = .TRUE.
  END SUBROUTINE Constr_Desc_Init

  SUBROUTINE Constr_Desc_Reset(self)
    CLASS(MD_Constr_Base_Desc), INTENT(INOUT) :: self
    IF (ALLOCATED(self%props)) DEALLOCATE(self%props)
    self%constr_id   = 0
    self%constr_type = CONSTR_TYPE_MPC
    self%n_nodes     = 0
    self%n_dof       = 0
    self%nprops      = 0
    self%is_initialized = .FALSE.
  END SUBROUTINE Constr_Desc_Reset

  !-----------------------------------------------------------------------------
  ! MD_Constr_UMPC_Desc — UMPC user-MPC description (*MPC, TYPE=Un)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_UMPC_Desc
    INTEGER(i4) :: jtype    = 0_i4  ! MPC type integer (from *MPC, TYPE=)
    INTEGER(i4) :: n        = 0_i4  ! number of nodes involved
    LOGICAL     :: linear   = .TRUE.  ! linear MPC constraint
    LOGICAL     :: is_active= .FALSE.
  END TYPE MD_Constr_UMPC_Desc

  !-----------------------------------------------------------------------------
  ! MD_Constr_UMESHMOTION_Desc — UMESHMOTION ALE mesh motion description
  !   *ALE ADAPTIVE MESH CONSTRAINT
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_UMESHMOTION_Desc
    CHARACTER(LEN=80) :: set_name   = ' '  ! node/element set
    INTEGER(i4)       :: nprops     = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4)       :: n_ale_sweeps = 10_i4
    LOGICAL           :: is_active  = .FALSE.
  END TYPE MD_Constr_UMESHMOTION_Desc

  !-----------------------------------------------------------------------------
  ! MD_Constr_UPATH_Desc — UPATH contact path description
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Constr_UPATH_Desc
    CHARACTER(LEN=80) :: path_name = ' '
    INTEGER(i4)       :: n_pts     = 0_i4
    REAL(wp)          :: ds_max    = 0.0_wp
    LOGICAL           :: is_active = .FALSE.
  END TYPE MD_Constr_UPATH_Desc

  !=============================================================================
  ! MD_Constraint_Domain — Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_Constraint_Domain
    TYPE(MD_Constr_Tie_Desc),      ALLOCATABLE :: ties(:)        ! [n_ties]
    TYPE(MD_Constr_Coupling_Desc), ALLOCATABLE :: couplings(:)   ! [n_couplings]
    TYPE(MD_Constr_MPC_Desc),      ALLOCATABLE :: mpcs(:)        ! [n_mpcs]
    INTEGER(i4) :: n_ties        = 0_i4
    INTEGER(i4) :: n_couplings   = 0_i4
    INTEGER(i4) :: n_mpcs        = 0_i4
    INTEGER(i4) :: max_constraints = 0_i4
    LOGICAL     :: initialized   = .FALSE.
    LOGICAL     :: frozen        = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
  END TYPE MD_Constraint_Domain

CONTAINS

  SUBROUTINE Init(this, cap_constraints, status)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                 INTENT(IN)    :: cap_constraints
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    IF (cap_constraints < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Constraint_Domain%Init: cap_constraints must be >= 1'
      RETURN
    END IF
    ALLOCATE(this%ties(cap_constraints/3+1))
    ALLOCATE(this%couplings(cap_constraints/3+1))
    ALLOCATE(this%mpcs(cap_constraints/3+1))
    this%n_ties        = 0_i4
    this%n_couplings   = 0_i4
    this%n_mpcs        = 0_i4
    this%max_constraints = cap_constraints
    this%initialized   = .TRUE.
    this%frozen        = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  SUBROUTINE Finalize(this)
    CLASS(MD_Constraint_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%ties))       DEALLOCATE(this%ties)
    IF (ALLOCATED(this%couplings))  DEALLOCATE(this%couplings)
    IF (ALLOCATED(this%mpcs))       DEALLOCATE(this%mpcs)
    this%n_ties        = 0_i4
    this%n_couplings   = 0_i4
    this%n_mpcs        = 0_i4
    this%max_constraints = 0_i4
    this%initialized   = .FALSE.
    this%frozen        = .FALSE.
  END SUBROUTINE Finalize

END MODULE MD_Constraint_Types
