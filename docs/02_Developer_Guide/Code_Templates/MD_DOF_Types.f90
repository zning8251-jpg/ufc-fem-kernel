!==============================================================================!
! MODULE MD_DOF_Types
! Layer  : L3_MD  (What / model description)
! Domain : DOF  –  degree-of-freedom layout and equation numbering
!
! Four TYPE kinds:
!   MD_DOF_Desc           – DOF active/inactive mask and physical meaning
!   MD_DOF_Algo           – assembly algorithm parameters (solver dof ordering)
!   MD_EqnNum_State       – equation numbering state (run-time, but read-only post-setup)
!   MD_ConstrainedDOF_Desc– description of prescribed / constrained DOF sets
!==============================================================================!
MODULE MD_DOF_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! DOF type code constants (Abaqus active DOF labels)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_UX      = 1_i4   ! displacement x  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_UY      = 2_i4   ! displacement y  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_UZ      = 3_i4   ! displacement z  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_UR1     = 4_i4   ! rotation 1  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_UR2     = 5_i4   ! rotation 2  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_UR3     = 6_i4   ! rotation 3  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_TEMP    = 11_i4  ! temperature  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_PORE    = 8_i4   ! pore pressure  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_ACOUSTIC= 8_i4   ! acoustic pressure (same slot)  ! migrated

  ! Equation ordering strategy
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_ORD_NATURAL  = 1_i4  ! node/dof natural order  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_ORD_RCM      = 2_i4  ! reverse Cuthill-McKee  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_ORD_AMD      = 3_i4  ! approximate minimum degree  ! migrated

  ! ------------------------------------------------------------------ !
  ! MD_DOF_Desc
  !   Describes which DOF are active for a given element type / physics.
  !   Also records the physical meaning of each DOF slot.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_DOF_Desc
    INTEGER(i4)           :: ndof_per_node = 0_i4    ! number of DOF per node
    INTEGER(i4)           :: ndof_total    = 0_i4    ! total active DOF
    LOGICAL,  ALLOCATABLE :: active(:)               ! [ndof_per_node] active flags
    INTEGER(i4), ALLOCATABLE :: dof_label(:)         ! [ndof_per_node] DOF type codes
    CHARACTER(LEN=8), ALLOCATABLE :: dof_name(:)     ! human-readable label
    LOGICAL               :: has_rotation  = .FALSE.
    LOGICAL               :: has_thermal   = .FALSE.
    LOGICAL               :: has_pore      = .FALSE.
    LOGICAL               :: is_active     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_DOF_Desc

  ! ------------------------------------------------------------------ !
  ! MD_DOF_Algo
  !   Algorithm parameters for DOF assembly and equation ordering.
  !   Read from *CONTROLS keyword or solver defaults.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_DOF_Algo
    INTEGER(i4) :: ordering_method   = DOF_ORD_RCM  ! equation numbering strategy
    LOGICAL     :: renumber_per_step = .FALSE.        ! re-renumber at each step start
    LOGICAL     :: separate_physics  = .FALSE.        ! segregate thermal/mech DOF
    INTEGER(i4) :: wavefront_target  = 0_i4           ! target wavefront (0 = auto)
    LOGICAL     :: use_superelements = .FALSE.        ! substructure condensation
    TYPE(ErrorStatusType) :: status
  END TYPE MD_DOF_Algo

  ! ------------------------------------------------------------------ !
  ! MD_EqnNum_State
  !   Equation numbering state produced by the DOF-assembly pass.
  !   Populated once at analysis start (or after mesh change) and then
  !   treated as read-only by all other domains.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_EqnNum_State
    INTEGER(i4)           :: neqns         = 0_i4   ! total active equations
    INTEGER(i4)           :: neqns_struct  = 0_i4   ! structural DOF count
    INTEGER(i4)           :: neqns_thermal = 0_i4   ! thermal DOF count
    INTEGER(i4)           :: bandwidth     = 0_i4   ! half-bandwidth after ordering
    INTEGER(i4)           :: wavefront     = 0_i4   ! actual wavefront
    INTEGER(i4), ALLOCATABLE :: id(:,:)             ! [ndof_per_node, n_nodes] eqn IDs
    LOGICAL               :: is_built      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_EqnNum_State

  ! ------------------------------------------------------------------ !
  ! MD_ConstrainedDOF_Desc
  !   Describes a set of prescribed / constrained DOF (from *BOUNDARY,
  !   *MPC, *EQUATION keywords).  Used in BC assembly to build the
  !   constraint matrix.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: MD_ConstrainedDOF_Desc
    CHARACTER(LEN=80)     :: set_name       = ' '   ! node set name
    INTEGER(i4)           :: n_constrained  = 0_i4  ! number of constrained nodes
    INTEGER(i4), ALLOCATABLE :: node_ids(:)          ! [n_constrained]
    INTEGER(i4), ALLOCATABLE :: dof_codes(:)         ! [n_constrained] DOF codes
    REAL(wp),    ALLOCATABLE :: magnitudes(:)         ! [n_constrained] prescribed values
    LOGICAL               :: amplitude_driven= .FALSE.! magnitude scaled by amplitude
    CHARACTER(LEN=80)     :: amplitude_name = ' '
    LOGICAL               :: is_active      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_ConstrainedDOF_Desc

END MODULE MD_DOF_Types
