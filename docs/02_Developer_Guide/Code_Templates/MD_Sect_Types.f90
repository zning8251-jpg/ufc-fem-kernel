!===============================================================================
! Module: MD_Sect_Types                                          [Template v3.2]
! Layer:  L3_MD — Model Description Layer
! Domain: Section — Bridge between Element and Material descriptors
!
! Purpose:
!   Defines the Section Desc and Registry types for the Element → Section →
!   Material linkage mechanism.
!
! Design (Section-as-Bridge pattern):
!   ┌──────────────────────────────────────────────────────────┐
!   │  Element (UEL)  →  MD_Sect_Base_Desc  →  MD_Mat_Base_Desc │
!   │  many                    many-to-many              one    │
!   │  elements can share same material via separate sections   │
!   └──────────────────────────────────────────────────────────┘
!
! v3.2: Merged MD_Section_Types.f90 into this module (removed duplicate file):
!   - INP-card detail types: MD_SolidSect_Desc, MD_ShellSect_Desc,
!     MD_BeamSect_Desc, MD_CohSect_Desc
!   - Discriminators MD_SECT_SECT_SOLID … TRUSS (ABAQUS-style card kind; 1–6)
!   - MD_Sect_Domain moved above CONTAINS (syntax fix)
!   - Baseline refresh: comments aligned to IF_Err_Brg structured-status
!     vocabulary (%status_code, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
! v3.1 changes vs legacy Section registry:
!   - Renamed: SectionType         → MD_Sect_Base_Desc
!              SectionRegistryType → MD_Sect_Registry
!   - FIXED  : mat_desc pointer type:
!              TYPE(MD_Mat_Desc_Base), POINTER  (compilation error)
!           →  CLASS(MD_Mat_Base_Desc), POINTER  (Fortran 2003 §7.4.2)
!     Principle ⑫ CLASS FOR ABSTRACT POINTER: any pointer to a
!     POLYMORPHIC (ABSTRACT) base must be declared CLASS, not TYPE.
!   - Updated: USE MD_Mat_Types ONLY: MD_Mat_Base_Desc (new name)
!   - All procedure dummy arguments updated from TYPE → CLASS accordingly.
!   - M1 migrated: FindByName (by-name lookup) added to MD_Sect_Registry
!   - M2 migrated: Validate extended with business-level checks (Shell
!                  thickness, Beam/Truss name, material_ref)
!   - M3 migrated: Init(est) + capacity field added to MD_Sect_Registry
!                  for efficient pre-allocation in large models
!
! section_family (MD_Sect_Base_Desc%section_family): 1–6 with cohesive
!   MD_SECT_SECT_FAM_SOLID … TRUSS plus MD_SECT_SECT_FAM_COHESIVE = 6
! INP card kind (MD_SECT_SECT_*): same numeric idea as old MD_Section_Types
!   but membrane=5, truss=6 — map to section_family when building Base_Desc
!
! Layer dependency:
!   USE IF_Prec      (wp, i4)
!   USE IF_Err_Brg   (ErrorStatusType + standard bridge vocabulary:
!                    init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!   USE MD_Mat_Types (MD_Mat_Base_Desc)   ← must be compiled first
!===============================================================================
MODULE MD_Sect_Types
  USE IF_Prec_Core,     ONLY: wp, i4
  USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mat_Types, ONLY: MD_Mat_Base_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Sect_Base_Desc
  PUBLIC :: MD_Sect_Registry
  PUBLIC :: MD_Sect_Domain
  PUBLIC :: MD_SolidSect_Desc
  PUBLIC :: MD_ShellSect_Desc
  PUBLIC :: MD_BeamSect_Desc
  PUBLIC :: MD_CohSect_Desc

  !-- section_family for MD_Sect_Base_Desc (M2: Validate); includes cohesive
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_FAM_SOLID    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_FAM_SHELL    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_FAM_BEAM     = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_FAM_MEMBRANE = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_FAM_TRUSS    = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_FAM_COHESIVE = 6_i4

  !-- INP / card kind (from former MD_Section_Types.f90; not identical to FAM ids)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_SOLID     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_SHELL     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_BEAM      = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_COHESIVE  = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_MEMBRANE  = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECT_SECT_TRUSS     = 6_i4

  !-----------------------------------------------------------------------------
  ! MD_Sect_Base_Desc — Section Descriptor
  !   Concrete type; holds geometric/numerical section properties plus a
  !   POINTER reference (non-owning) to the associated material descriptor.
  !
  !   KEY FIX (漏洞L2):
  !     mat_desc MUST be CLASS(MD_Mat_Base_Desc) because MD_Mat_Base_Desc is
  !     ABSTRACT.  Using TYPE(MD_Mat_Base_Desc) triggers a Fortran compile error.
  !     (Fortran 2003: objects of ABSTRACT type cannot be instantiated;
  !      polymorphic CLASS pointer is required.)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Base_Desc
    !-- Identification
    INTEGER(i4)       :: section_id   = 0    ! Unique section ID (≥1)
    CHARACTER(LEN=64) :: section_name = ''   ! Human-readable label

    !-- Material reference (bridge)
    INTEGER(i4) :: mat_id = 0   ! Numeric material ID (for lookup)
    !   [L2 fix] CLASS pointer, NOT TYPE pointer, for polymorphic abstract target
    CLASS(MD_Mat_Base_Desc), POINTER :: mat_desc => NULL()

    !-- Geometric / numerical section properties (NOT material parameters)
    REAL(wp) :: thickness   = 0.0_wp        ! Shell / beam thickness   [m]
    REAL(wp) :: orientation(3) = 0.0_wp     ! Fibre direction unit vector
    REAL(wp) :: offset      = 0.0_wp        ! Section offset from reference surface

    !-- Layered / composite
    INTEGER(i4) :: nlayer           = 1     ! Number of layers (composite use)
    INTEGER(i4) :: integ_npts       = 0     ! Integration pts through thickness
    CHARACTER(LEN=16) :: integ_rule = ''    ! e.g. 'GAUSS', 'SIMPS'

    !-- Section family / sub-type (use MD_SECT_SECT_FAM_*; 6=cohesive)
    INTEGER(i4) :: section_family = 0
    INTEGER(i4) :: section_type   = 0   ! Specific sub-type within family

    !-- Initialization guard
    LOGICAL :: is_initialized = .FALSE.

  CONTAINS
    PROCEDURE :: InitBasic      => Sect_InitBasic
    PROCEDURE :: InitComposite  => Sect_InitComposite
    PROCEDURE :: AssociateMat   => Sect_AssociateMaterial
    !-- M2: Validate now returns status + message instead of bare LOGICAL
    PROCEDURE :: Validate       => Sect_Validate
    PROCEDURE :: Nullify        => Sect_NullifyPointer
  END TYPE MD_Sect_Base_Desc

  !-----------------------------------------------------------------------------
  ! MD_Sect_Registry — Manages a collection of section descriptors
  !   Provides AddSection / GetSection / FindByMaterial utilities.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Registry
    TYPE(MD_Sect_Base_Desc), POINTER :: sections(:)
    INTEGER(i4) :: nsections = 0
    INTEGER(i4) :: capacity  = 0   ! M3: pre-allocated capacity (0 = lazy)

  CONTAINS
    !-- M3: Init with capacity pre-allocation
    PROCEDURE :: Init            => Registry_Init
    PROCEDURE :: AddSection      => Registry_AddSection
    PROCEDURE :: GetSectIdx      => Registry_GetSectIdx
    !-- M1: by-name lookup
    PROCEDURE :: FindByName      => Registry_FindByName
    PROCEDURE :: FindByMaterial  => Registry_FindByMaterial
    PROCEDURE :: Clear           => Registry_Clear
  END TYPE MD_Sect_Registry

  !---------------------------------------------------------------------------
  ! MD_Sect_Domain — flat-storage domain container (Layer 2)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Domain
    TYPE(MD_Sect_Base_Desc), ALLOCATABLE :: desc(:)   ! Section array [n_sects]
    INTEGER(i4) :: n_sects     = 0_i4
    INTEGER(i4) :: max_sects   = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen      = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => MD_Sect_Domain_Init
    PROCEDURE :: Finalize => MD_Sect_Domain_Finalize
  END TYPE MD_Sect_Domain

  !---------------------------------------------------------------------------
  ! Per-INP-card detail types (migrated from MD_Section_Types.f90)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_SolidSect_Desc
    CHARACTER(LEN=80) :: sect_name   = ' '
    CHARACTER(LEN=80) :: elset_name  = ' '
    CHARACTER(LEN=80) :: mat_name    = ' '
    INTEGER(i4)       :: n_integ_pts = 0_i4
    LOGICAL           :: plane_stress = .FALSE.
    LOGICAL           :: plane_strain = .FALSE.
    LOGICAL           :: axisym      = .FALSE.
    LOGICAL           :: is_active   = .FALSE.
  END TYPE MD_SolidSect_Desc

  TYPE, PUBLIC :: MD_ShellSect_Desc
    CHARACTER(LEN=80) :: sect_name   = ' '
    CHARACTER(LEN=80) :: elset_name  = ' '
    CHARACTER(LEN=80) :: mat_name   = ' '
    REAL(wp)          :: thickness   = 0.0_wp
    INTEGER(i4)       :: n_sect_pts  = 5_i4
    INTEGER(i4)       :: n_layers    = 1_i4
    REAL(wp)          :: offset      = 0.0_wp
    LOGICAL           :: nlgeom      = .FALSE.
    LOGICAL           :: is_active   = .FALSE.
  END TYPE MD_ShellSect_Desc

  TYPE, PUBLIC :: MD_BeamSect_Desc
    CHARACTER(LEN=80) :: sect_name    = ' '
    CHARACTER(LEN=80) :: elset_name   = ' '
    CHARACTER(LEN=80) :: mat_name     = ' '
    CHARACTER(LEN=16) :: profile_type = 'RECT'
    REAL(wp), ALLOCATABLE :: profile_data(:)
    INTEGER(i4) :: n_profile_data = 0_i4
    REAL(wp)    :: area           = 0.0_wp
    REAL(wp)    :: i11            = 0.0_wp
    REAL(wp)    :: i22            = 0.0_wp
    LOGICAL     :: is_active      = .FALSE.
  END TYPE MD_BeamSect_Desc

  TYPE, PUBLIC :: MD_CohSect_Desc
    CHARACTER(LEN=80) :: sect_name    = ' '
    CHARACTER(LEN=80) :: elset_name   = ' '
    CHARACTER(LEN=80) :: mat_name     = ' '
    REAL(wp)          :: thickness    = 1.0_wp
    INTEGER(i4)       :: response     = 0_i4
    LOGICAL           :: out_of_plane = .FALSE.
    LOGICAL           :: is_active    = .FALSE.
  END TYPE MD_CohSect_Desc

CONTAINS

  !=============================================================================
  ! MD_Sect_Base_Desc procedures
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! InitBasic: set ID, name, family, and clear material pointer
  !-----------------------------------------------------------------------------
  SUBROUTINE Sect_InitBasic(self, id, name, family)
    CLASS(MD_Sect_Base_Desc), INTENT(INOUT) :: self
    INTEGER(i4),       INTENT(IN) :: id
    CHARACTER(LEN=*),  INTENT(IN) :: name
    INTEGER(i4),       INTENT(IN) :: family

    self%section_id     = id
    self%section_name   = TRIM(name)
    self%section_family = family
    self%mat_desc       => NULL()
    self%mat_id         = 0
    self%is_initialized = .TRUE.
  END SUBROUTINE Sect_InitBasic

  !-----------------------------------------------------------------------------
  ! InitComposite: additionally configure layered-section parameters
  !-----------------------------------------------------------------------------
  SUBROUTINE Sect_InitComposite(self, nlayer, thickness, npts, rule)
    CLASS(MD_Sect_Base_Desc), INTENT(INOUT) :: self
    INTEGER(i4),      INTENT(IN) :: nlayer
    REAL(wp),         INTENT(IN) :: thickness
    INTEGER(i4),      INTENT(IN) :: npts
    CHARACTER(LEN=*), INTENT(IN) :: rule

    self%nlayer           = nlayer
    self%thickness        = thickness
    self%integ_npts       = npts
    self%integ_rule       = TRIM(rule)
  END SUBROUTINE Sect_InitComposite

  !-----------------------------------------------------------------------------
  ! AssociateMaterial: attach material descriptor pointer (non-owning)
  !   [L2 fix] Both self and mat_desc_ptr declared CLASS to support polymorphism.
  !-----------------------------------------------------------------------------
  SUBROUTINE Sect_AssociateMaterial(self, mat_desc_ptr)
    CLASS(MD_Sect_Base_Desc),  INTENT(INOUT)        :: self
    CLASS(MD_Mat_Base_Desc),   INTENT(IN), TARGET   :: mat_desc_ptr

    self%mat_desc => mat_desc_ptr
    self%mat_id   =  mat_desc_ptr%mat_id
  END SUBROUTINE Sect_AssociateMaterial

  !-----------------------------------------------------------------------------
  ! Validate: business-level sanity checks  [M2 extended]
  !   Returns via ErrorStatusType so caller gets a descriptive message.
  !   Rules:
  !     1. section_id    > 0
  !     2. mat_id        > 0  AND  mat_desc ASSOCIATED
  !     3. section_family in [MD_SECT_SECT_FAM_SOLID .. MD_SECT_SECT_FAM_COHESIVE]
  !     4. Shell/Membrane/Cohesive require thickness > 0
  !     5. Beam/Truss families require non-empty section_name
  !-----------------------------------------------------------------------------
  SUBROUTINE Sect_Validate(self, st)
    CLASS(MD_Sect_Base_Desc), INTENT(IN)  :: self
    TYPE(ErrorStatusType),    INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (self%section_id <= 0) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "section_id must be >= 1"
      RETURN
    END IF

    IF (self%mat_id <= 0 .OR. .NOT. ASSOCIATED(self%mat_desc)) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "material not associated (mat_id <= 0 or mat_desc not linked)"
      RETURN
    END IF

    IF (self%section_family < MD_SECT_SECT_FAM_SOLID .OR. &
        self%section_family > MD_SECT_SECT_FAM_COHESIVE) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "section_family out of valid range [1..6]"
      RETURN
    END IF

    IF (self%section_family == MD_SECT_SECT_FAM_SHELL .OR. &
        self%section_family == MD_SECT_SECT_FAM_MEMBRANE .OR. &
        self%section_family == MD_SECT_SECT_FAM_COHESIVE) THEN
      IF (self%thickness <= 0.0_wp) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "Shell/Membrane/Cohesive section requires thickness > 0"
        RETURN
      END IF
    END IF

    IF (self%section_family == MD_SECT_SECT_FAM_BEAM .OR. &
        self%section_family == MD_SECT_SECT_FAM_TRUSS) THEN
      IF (LEN_TRIM(self%section_name) == 0) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "Beam/Truss section requires a non-empty section_name"
        RETURN
      END IF
    END IF

    st%status_code = IF_STATUS_OK
  END SUBROUTINE Sect_Validate

  !-----------------------------------------------------------------------------
  ! NullifyPointer: safely nullify the material pointer (e.g. on destruction)
  !-----------------------------------------------------------------------------
  SUBROUTINE Sect_NullifyPointer(self)
    CLASS(MD_Sect_Base_Desc), INTENT(INOUT) :: self
    NULLIFY(self%mat_desc)
  END SUBROUTINE Sect_NullifyPointer

  !=============================================================================
  ! MD_Sect_Registry procedures
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! Init: pre-allocate backing array to avoid repeated reallocation  [M3]
  !   Call before the first AddSection when the expected count is known.
  !   Safe to call multiple times; re-initialises if already allocated.
  !-----------------------------------------------------------------------------
  SUBROUTINE Registry_Init(self, est)
    CLASS(MD_Sect_Registry), INTENT(INOUT) :: self
    INTEGER(i4),             INTENT(IN)    :: est   ! estimated section count

    INTEGER(i4) :: cap
    cap = MAX(16_i4, est)
    IF (ALLOCATED(self%sections)) CALL self%Clear()
    ALLOCATE(self%sections(cap))
    self%capacity  = cap
    self%nsections = 0
  END SUBROUTINE Registry_Init

  !-----------------------------------------------------------------------------
  ! AddSection: append a section; uses capacity doubling when pre-allocated  [M3]
  !-----------------------------------------------------------------------------
  SUBROUTINE Registry_AddSection(self, sect)
    CLASS(MD_Sect_Registry),   INTENT(INOUT) :: self
    TYPE(MD_Sect_Base_Desc),   INTENT(IN)    :: sect

    TYPE(MD_Sect_Base_Desc), POINTER :: tmp(:)
    INTEGER(i4) :: n, new_cap

    n = self%nsections

    IF (self%capacity > 0) THEN
      !-- Pre-allocated path: double capacity when full
      IF (n >= self%capacity) THEN
        new_cap = self%capacity * 2_i4
        ALLOCATE(tmp(new_cap))
        tmp(1:n) = self%sections(1:n)
        CALL MOVE_ALLOC(tmp, self%sections)
        self%capacity = new_cap
      END IF
      self%sections(n+1) = sect
    ELSE
      !-- Lazy path: allocate exactly n+1 each time (original behaviour)
      ALLOCATE(tmp(n+1))
      IF (n > 0) tmp(1:n) = self%sections(1:n)
      tmp(n+1) = sect
      CALL MOVE_ALLOC(tmp, self%sections)
    END IF

    self%nsections = n + 1
  END SUBROUTINE Registry_AddSection

  !-----------------------------------------------------------------------------
  ! GetSectIdx: return index of section by ID (0 = not found)
  !   Caller accesses the section via self%sections(idx) directly.
  !   A pointer-returning function is intentionally avoided (Fortran 2003
  !   requires the array component to carry TARGET, which is not allowed in
  !   TYPE definitions).
  !-----------------------------------------------------------------------------
  FUNCTION Registry_GetSectIdx(self, id) RESULT(idx)
    CLASS(MD_Sect_Registry), INTENT(IN) :: self
    INTEGER(i4),             INTENT(IN) :: id
    INTEGER(i4) :: idx

    INTEGER(i4) :: i
    idx = 0
    DO i = 1, self%nsections
      IF (self%sections(i)%section_id == id) THEN
        idx = i
        RETURN
      END IF
    END DO
  END FUNCTION Registry_GetSectIdx

  !-----------------------------------------------------------------------------
  ! FindByName: return index of section matching section_name (0 = not found)  [M1]
  !   Comparison is case-sensitive TRIM match.
  !-----------------------------------------------------------------------------
  FUNCTION Registry_FindByName(self, name) RESULT(idx)
    CLASS(MD_Sect_Registry), INTENT(IN) :: self
    CHARACTER(LEN=*),        INTENT(IN) :: name
    INTEGER(i4) :: idx

    INTEGER(i4) :: i
    idx = 0
    DO i = 1, self%nsections
      IF (TRIM(self%sections(i)%section_name) == TRIM(name)) THEN
        idx = i
        RETURN
      END IF
    END DO
  END FUNCTION Registry_FindByName

  !-----------------------------------------------------------------------------
  ! FindByMaterial: return first section index that references mat_id (0 = none)
  !-----------------------------------------------------------------------------
  FUNCTION Registry_FindByMaterial(self, mat_id) RESULT(idx)
    CLASS(MD_Sect_Registry), INTENT(IN) :: self
    INTEGER(i4),             INTENT(IN) :: mat_id
    INTEGER(i4) :: idx

    INTEGER(i4) :: i
    idx = 0
    DO i = 1, self%nsections
      IF (self%sections(i)%mat_id == mat_id) THEN
        idx = i
        RETURN
      END IF
    END DO
  END FUNCTION Registry_FindByMaterial

  !-----------------------------------------------------------------------------
  ! Clear: deallocate all sections
  !-----------------------------------------------------------------------------
  SUBROUTINE Registry_Clear(self)
    CLASS(MD_Sect_Registry), INTENT(INOUT) :: self
    INTEGER(i4) :: i
    ! Nullify all material pointers before deallocation
    DO i = 1, self%nsections
      CALL self%sections(i)%Nullify()
    END DO
    IF (ALLOCATED(self%sections)) DEALLOCATE(self%sections)
    self%nsections = 0
    self%capacity  = 0
  END SUBROUTINE Registry_Clear

  !=============================================================================
  ! MD_Sect_Domain procedures
  !=============================================================================

  SUBROUTINE MD_Sect_Domain_Init(this, cap_sects, status)
    CLASS(MD_Sect_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: cap_sects
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL MD_Sect_Domain_Finalize(this)
    IF (cap_sects < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Sect_Domain_Init: cap_sects must be >= 1'
      RETURN
    END IF
    ALLOCATE(this%desc(cap_sects))
    this%n_sects     = 0_i4
    this%max_sects   = cap_sects
    this%initialized = .TRUE.
    this%frozen      = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Sect_Domain_Init

  SUBROUTINE MD_Sect_Domain_Finalize(this)
    CLASS(MD_Sect_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%desc)) DEALLOCATE(this%desc)
    this%n_sects     = 0_i4
    this%max_sects   = 0_i4
    this%initialized = .FALSE.
    this%frozen      = .FALSE.
  END SUBROUTINE MD_Sect_Domain_Finalize

END MODULE MD_Sect_Types
