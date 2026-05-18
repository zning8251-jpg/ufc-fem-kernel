!===============================================================================
! Module: MD_Elem_Types                                          [Template v3.2]
! Layer:  L3_MD — Model Description Layer
! Domain: Element — Universal Base Type Definitions
!
! Purpose:
!   Defines the Desc type for element geometry / topology / property
!   configuration at the MD_ (model-description) layer.
!
!-- Module version header update
!   v3.2 additions: MD_Elem_Base_State, MD_Elem_Base_Algo, MD_Elem_VUEL_State

! v3.2 additions:
!   - Added: Element family enum constants (ELEM_FAMILY_XXX)
!   - Added: VUEL-specific Desc (explicit dynamics: mass scaling, bulk viscosity)
!   - Added: UELMAT-specific Desc (for elements with embedded material computation)
!   - UELMAT is the UEL that internally calls UMAT-like material routines
!
! Type roles:
!   MD_Elem_Base_Desc   – Element identity, topology, property arrays
!                        (concrete, maps directly from ABAQUS UEL arguments)
!   MD_Elem_VUEL_Desc   – Explicit-dynamics-specific element desc
!   MD_Elem_UELMAT_Desc – UEL-with-embedded-material desc
!
! Source: UEL signature parameter mapping (see doc Part VI §UEL fields)
!   NDOFEL  → ndofel     NSVARS  → nsvars     NNODE   → nnode
!   MCRD    → mcrd       JTYPE   → jtype      NPROPS  → nprops
!   PROPS   → props(:)   NPREDF  → npredf     JDLTYP  → jdltyp(:,:)
!   MDLOAD  → mdload     JPROPS  → jprops(:)  NJPROP  → njprop
!   (LFLAGS is runtime context → RT_Common_Ctx)
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!===============================================================================
MODULE MD_Elem_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Base_Desc
  PUBLIC :: MD_Elem_VUEL_Desc
  PUBLIC :: MD_Elem_UELMAT_Desc
  PUBLIC :: MD_Elem_Base_State
  PUBLIC :: MD_Elem_Base_Algo
  PUBLIC :: MD_Elem_VUEL_State

  !-- Element family enum constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_ELEM_FAMILY_UEL    = 1_i4  ! UEL  (Abaqus/Standard)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_ELEM_FAMILY_VUEL   = 2_i4  ! VUEL (Abaqus/Explicit)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_ELEM_FAMILY_UELMAT  ! migrated from ELEM_FAMILY_UELMAT
    ELEM_FAMILY_UELMAT = 3_i4  ! UELMAT (UEL+UMAT embedded)

  !-----------------------------------------------------------------------------
  ! DESC — Element Descriptor (UEL / VUEL base)
  !   Concrete type; no abstract methods required.
  !   Fields map 1-to-1 to ABAQUS UEL call-time parameters that describe
  !   element topology and property data (NOT runtime incremental quantities).
  !
  !   Design note:
  !     - props / jprops / jdltyp are ALLOCATABLE; allocated by the registry
  !       when the element is registered or by the UEL bridge on first call.
  !     - jtype identifies the element formulation family (user-defined codes).
  !     - nsvars is the number of solution-dependent state variables per
  !       integration point; actual storage lives in PH_Elem_Base_State.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Base_Desc
    !-- Degree-of-freedom topology
    INTEGER(i4) :: ndofel = 0   ! NDOFEL   total DOFs for this element
    INTEGER(i4) :: nsvars  = 0  ! NSVARS   no. of state variables (per element);
                                !           actual storage lives in PH_Elem_Base_State%svars
    INTEGER(i4) :: nnode   = 0  ! NNODE    no. of nodes
    INTEGER(i4) :: mcrd    = 3  ! MCRD     max. coordinates per node (2 or 3)
    !-- Element family / type identifier
    INTEGER(i4) :: jtype   = 0  ! JTYPE    element type flag (user-defined)
    INTEGER(i4) :: elem_family = ELEM_FAMILY_UEL  ! ELEM_FAMILY_XXX enum
    !-- Real property array
    INTEGER(i4)              :: nprops = 0   ! NPROPS   length of props(:)
    REAL(wp), ALLOCATABLE    :: props(:)     ! PROPS    real element properties
    !-- Predefined field variables
    INTEGER(i4) :: npredf  = 0  ! NPREDF   no. of predefined field variables
    !-- Distributed load type table
    INTEGER(i4)              :: mdload = 0   ! MDLOAD   no. of dist. load entries
    INTEGER(i4), ALLOCATABLE :: jdltyp(:,:) ! JDLTYP(MDLOAD,*) load type table
    !-- Integer property array
    INTEGER(i4)              :: njprop = 0   ! NJPROP   length of jprops(:)
    INTEGER(i4), ALLOCATABLE :: jprops(:)   ! JPROPS   integer element properties
    INTEGER(i4) :: integ_npts = 0_i4        ! >0 required before PH_*_UEL_API (v4.1 contract)
    !-- Initialization flag
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init   => Elem_Desc_Init
    PROCEDURE :: Reset  => Elem_Desc_Reset
  END TYPE MD_Elem_Base_Desc

  !-----------------------------------------------------------------------------
  ! VUEL-specific Desc (Abaqus/Explicit user element)
  !   VUEL receives: NBLOCK (vectorized), NPREDF, density-related fields
  !   Explicit-specific additions: characteristic length, mass scaling
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_VUEL_Desc
    INTEGER(i4) :: nblock       = 1_i4    ! NBLOCK  vectorization block size
    REAL(wp)    :: mass_scale   = 1.0_wp  ! Mass scaling factor (Explicit)
    REAL(wp)    :: bulk_visc_b1 = 0.06_wp ! Linear bulk viscosity b1
    REAL(wp)    :: bulk_visc_b2 = 1.2_wp  ! Quadratic bulk viscosity b2
    REAL(wp)    :: char_length  = 0.0_wp  ! Characteristic element length [m]
    LOGICAL     :: use_hourglass = .FALSE.! Hourglass control active
    REAL(wp)    :: hg_stiffness  = 0.0_wp ! Hourglass stiffness factor
  END TYPE MD_Elem_VUEL_Desc

  !-----------------------------------------------------------------------------
  ! UELMAT-specific Desc (UEL with embedded material computation)
  !   UELMAT allows calling CALUM/CALMUT to invoke material routines
  !   directly, instead of coding constitutive logic in the UEL itself.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_UELMAT_Desc
    INTEGER(i4) :: n_mat_pts   = 0_i4   ! Number of material integration points
    INTEGER(i4) :: mat_id      = 0_i4   ! Material ID for embedded UMAT call
    LOGICAL     :: use_nlgeom  = .FALSE. ! Nonlinear geometry flag
  END TYPE MD_Elem_UELMAT_Desc

  !-----------------------------------------------------------------------------
  ! MD_Elem_Base_State — Per-element solution-dependent state storage
  !   Carries solution-dependent state variables (STATEV/SDV) and per-element
  !   scalar outputs from the UEL (reaction force resultant, energy, etc.).
  !   NOTE: this is the MD_-layer owner; PH_Elem_Base_State is the computation
  !   scratch view; both reference the same underlying data via pointer in RT.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Base_State
    !-- Solution-dependent state variables (SVARS in UEL arglist)
    REAL(wp), ALLOCATABLE :: svars(:)   ! svars(nsvars) — owned here
    INTEGER(i4) :: nsvars = 0

    !-- Per-element scalar history outputs
    REAL(wp) :: energy_strain   = 0.0_wp  ! Elastic strain energy
    REAL(wp) :: energy_plastic  = 0.0_wp  ! Plastic dissipation
    REAL(wp) :: energy_creep    = 0.0_wp  ! Creep dissipation
    REAL(wp) :: energy_visc     = 0.0_wp  ! Viscous dissipation

    !-- Convergence indicator
    LOGICAL :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Elem_Base_State

  !-----------------------------------------------------------------------------
  ! MD_Elem_Base_Algo — Element-level algorithm configuration (pre-analysis)
  !   Carries flags that control how the element computation is performed.
  !   Per-increment iteration control lives in PH_Elem_Types :: PH_Elem_Base_Algo.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Base_Algo
    !-- Integration rule
    INTEGER(i4) :: integ_scheme  = 1_i4  ! 1=full, 2=reduced, 3=selective
    INTEGER(i4) :: integ_npts    = 0_i4  ! Integration point count (0=auto)

    !-- Geometric nonlinearity
    LOGICAL :: nlgeom = .FALSE.  ! Geometric nonlinearity active

    !-- Hourglass control
    LOGICAL  :: hg_control      = .FALSE.
    REAL(wp) :: hg_stiffness    = 0.0_wp  ! Hourglass stiffness factor

    !-- Shear locking mitigation
    LOGICAL :: use_bbar         = .FALSE.  ! B-bar method (volumetric locking)
    LOGICAL :: use_eas          = .FALSE.  ! Enhanced Assumed Strain
  END TYPE MD_Elem_Base_Algo

  !-----------------------------------------------------------------------------
  ! MD_Elem_VUEL_State — Explicit vectorized element state (Abaqus/Explicit)
  !   Per-element state for VUEL (nblock elements processed together).
  !   Carries internal forces, lumped mass, and characteristic lengths.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_VUEL_State
    !-- Stable time increment (output, per block)
    REAL(wp), ALLOCATABLE :: dt_stable(:)   ! [nblock] stable dt per element

    !-- Internal force resultant norm (diagnostic)
    REAL(wp), ALLOCATABLE :: f_int_norm(:)  ! [nblock]

    !-- Lumped mass array (diagonal, per element DOFs)
    REAL(wp), ALLOCATABLE :: amass(:,:)     ! [nblock, ndofel]

    !-- Characteristic length (per block, output for Courant condition)
    REAL(wp), ALLOCATABLE :: char_length(:) ! [nblock]

    INTEGER(i4) :: nblock = 0
    LOGICAL     :: is_initialized = .FALSE.
  END TYPE MD_Elem_VUEL_State

  !-----------------------------------------------------------------------------
  ! Init: allocate property arrays and mark as initialized
  !-----------------------------------------------------------------------------
  SUBROUTINE Elem_Desc_Init(self, nprops_in, njprop_in, npredf_in, mdload_in, ncols_jdl)
    CLASS(MD_Elem_Base_Desc), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: nprops_in
    INTEGER(i4), INTENT(IN) :: njprop_in
    INTEGER(i4), INTENT(IN) :: npredf_in
    INTEGER(i4), INTENT(IN) :: mdload_in
    INTEGER(i4), INTENT(IN) :: ncols_jdl   ! columns for jdltyp (typically 2)

    self%nprops = nprops_in
    self%njprop = njprop_in
    self%npredf = npredf_in
    self%mdload = mdload_in

    IF (nprops_in > 0) THEN
      IF (.NOT. ALLOCATED(self%props))  ALLOCATE(self%props(nprops_in))
      self%props = 0.0_wp
    END IF

    IF (njprop_in > 0) THEN
      IF (.NOT. ALLOCATED(self%jprops)) ALLOCATE(self%jprops(njprop_in))
      self%jprops = 0_i4
    END IF

    IF (mdload_in > 0 .AND. ncols_jdl > 0) THEN
      IF (.NOT. ALLOCATED(self%jdltyp)) ALLOCATE(self%jdltyp(mdload_in, ncols_jdl))
      self%jdltyp = 0_i4
    END IF

    self%is_initialized = .TRUE.
  END SUBROUTINE Elem_Desc_Init

  !-----------------------------------------------------------------------------
  ! Reset: deallocate arrays and clear flags
  !-----------------------------------------------------------------------------
  SUBROUTINE Elem_Desc_Reset(self)
    CLASS(MD_Elem_Base_Desc), INTENT(INOUT) :: self
    IF (ALLOCATED(self%props))  DEALLOCATE(self%props)
    IF (ALLOCATED(self%jprops)) DEALLOCATE(self%jprops)
    IF (ALLOCATED(self%jdltyp)) DEALLOCATE(self%jdltyp)
    self%nprops = 0
    self%njprop = 0
    self%mdload = 0
    self%npredf = 0
    self%ndofel = 0
    self%nsvars = 0
    self%nnode  = 0
    self%mcrd   = 0   ! reset to 0 (re-set by caller via Init or direct assignment)
    self%jtype  = 0
    self%integ_npts = 0_i4
    self%is_initialized = .FALSE.
  END SUBROUTINE Elem_Desc_Reset

  !-----------------------------------------------------------------------------
  ! MD_Elem_UEL_Desc — UEL user-element description (INP-driven)
  !   *USER ELEMENT, NODES=n, TYPE=Un, COORDINATES=ndim, ...
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_UEL_Desc
    INTEGER(i4)          :: jtype    = 0_i4   ! element type identifier (Un)
    INTEGER(i4)          :: nnode    = 0_i4   ! number of nodes
    INTEGER(i4)          :: ndofel   = 0_i4   ! degrees of freedom per element
    INTEGER(i4)          :: ndim     = 3_i4   ! spatial dimensions
    INTEGER(i4)          :: nsvars   = 0_i4   ! solution-dependent state vars
    INTEGER(i4)          :: nprops   = 0_i4   ! element properties
    REAL(wp), ALLOCATABLE :: props(:)          ! element property array
    LOGICAL              :: large_disp = .FALSE.  ! large displacement
    LOGICAL              :: is_active  = .FALSE.
  END TYPE MD_Elem_UEL_Desc

  !-----------------------------------------------------------------------------
  ! MD_Elem_VUEL_Desc — VUEL vectorised user-element description
  !   *USER ELEMENT with PROPERTIES, NBLOCK support
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_VUEL_Desc
    INTEGER(i4)          :: jtype    = 0_i4
    INTEGER(i4)          :: nnode    = 0_i4
    INTEGER(i4)          :: ndofel   = 0_i4
    INTEGER(i4)          :: ndim     = 3_i4
    INTEGER(i4)          :: nsvars   = 0_i4
    INTEGER(i4)          :: nprops   = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4)          :: nblock_max = 512_i4  ! max vectorisation block
    LOGICAL              :: large_disp = .FALSE.
    LOGICAL              :: is_active  = .FALSE.
  END TYPE MD_Elem_VUEL_Desc

  !-----------------------------------------------------------------------------
  ! MD_Elem_UELMAT_Desc — UELMAT UEL-with-material description
  !   *USER ELEMENT + *USER MATERIAL: element integrates material at each IP
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_UELMAT_Desc
    INTEGER(i4)          :: jtype    = 0_i4
    INTEGER(i4)          :: nnode    = 0_i4
    INTEGER(i4)          :: ndofel   = 0_i4
    INTEGER(i4)          :: ndim     = 3_i4
    INTEGER(i4)          :: n_int_pts = 1_i4  ! number of integration points
    INTEGER(i4)          :: nsvars   = 0_i4
    INTEGER(i4)          :: mat_id   = 0_i4   ! associated material id
    LOGICAL              :: large_disp = .FALSE.
    LOGICAL              :: is_active  = .FALSE.
  END TYPE MD_Elem_UELMAT_Desc

  !=============================================================================
  ! MD_Elem_Domain — Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_Elem_Domain
    TYPE(MD_Elem_Base_Desc), ALLOCATABLE :: desc(:)   ! Elem array [n_elems]
    TYPE(MD_Elem_Base_State), ALLOCATABLE :: state(:) ! State array [n_elems]
    TYPE(MD_Elem_Base_Algo), ALLOCATABLE :: algo(:)   ! Algo array [n_elems]
    INTEGER(i4) :: n_elems     = 0_i4
    INTEGER(i4) :: max_elems   = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen      = .FALSE.
  CONTAINS
    PROCEDURE :: Init      => MD_Elem_Domain_Init
    PROCEDURE :: Finalize  => MD_Elem_Domain_Finalize
    PROCEDURE :: WriteBack => MD_Elem_WriteBack
  END TYPE MD_Elem_Domain

CONTAINS

  SUBROUTINE MD_Elem_Domain_Init(this, cap_elems, status)
    CLASS(MD_Elem_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: cap_elems
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL MD_Elem_Domain_Finalize(this)
    IF (cap_elems < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Elem_Domain_Init: cap_elems must be >= 1'
      RETURN
    END IF
    ALLOCATE(this%desc(cap_elems))
    ALLOCATE(this%state(cap_elems))
    ALLOCATE(this%algo(cap_elems))
    this%n_elems     = 0_i4
    this%max_elems   = cap_elems
    this%initialized = .TRUE.
    this%frozen      = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Elem_Domain_Init

  SUBROUTINE MD_Elem_Domain_Finalize(this)
    CLASS(MD_Elem_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%desc))  DEALLOCATE(this%desc)
    IF (ALLOCATED(this%state)) DEALLOCATE(this%state)
    IF (ALLOCATED(this%algo))  DEALLOCATE(this%algo)
    this%n_elems     = 0_i4
    this%max_elems   = 0_i4
    this%initialized = .FALSE.
    this%frozen      = .FALSE.
  END SUBROUTINE MD_Elem_Domain_Finalize

  SUBROUTINE MD_Elem_WriteBack(this, elem_id, new_state, status)
    CLASS(MD_Elem_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: elem_id
    TYPE(MD_Elem_Base_State), INTENT(IN) :: new_state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. elem_id < 1_i4 .OR. elem_id > this%n_elems) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') 'MD_Elem_WriteBack: invalid elem_id=', elem_id
      RETURN
    END IF
    this%state(elem_id) = new_state
    status%status_code  = IF_STATUS_OK
  END SUBROUTINE MD_Elem_WriteBack

END MODULE MD_Elem_Types
