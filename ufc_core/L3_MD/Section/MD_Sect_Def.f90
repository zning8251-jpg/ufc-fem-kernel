!===============================================================================
! MODULE:  MD_Sect_Def
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Def
! BRIEF:   Section type definitions — Desc + State + Algo + Ctx + Arg bundles.
!          9 families x 17 type codes. L3-only SSOT for section definitions.
!===============================================================================
MODULE MD_Sect_Def
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_SOLID     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_SHELL     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_BEAM      = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_MEMBRANE  = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_TRUSS     = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_COHESIVE  = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_GASKET    = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_ACOUSTIC  = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_CONNECTOR = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_FAM_COUNT     = 9_i4

  !---------------------------------------------------------------------------
  ! Legacy section_kind codes (flat MD_Sect_Desc / domain validation & sync)
  ! 17 section type codes across 9 families
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_SOLID_3D        = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_SHELL           = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_SHELL_COMPOSITE = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_MEMBRANE        = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_SURFACE_SHELL   = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_THERMAL_SHELL   = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_ACOUSTIC_SHELL  = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_BEAM_EULER      = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_BEAM_TIMOSHENKO = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_TRUSS           = 10_i4
  ! --- Extended section types (Cohesive/Gasket/Acoustic/Connector) ---
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_COHESIVE        = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_GASKET          = 12_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_GASKET_THIN     = 13_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_ACOUSTIC_SOLID  = 14_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_CONNECTOR       = 15_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_SOLID_2D        = 16_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_BEAM_GENERAL    = 17_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_TYPE_MIN        = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_TYPE_MAX        = 30_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SECT_TYPE_COUNT      = 17_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SECTION_MAX      = 256_i4

  !---------------------------------------------------------------------------
  TYPE(MD_Sect_Desc)
  ! KIND:  Desc
  ! DESC:  Section descriptor — merged from MD_Sect_Desc + MD_Sect_Desc (G9)
  !        L3-only SSOT; TBP: InitBasic/InitComposite/AssociateMat/Validate/Nullify
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Desc
    INTEGER(i4)       :: section_id   = 0
    CHARACTER(LEN=64) :: section_name = ''
    INTEGER(i4) :: mat_id = 0
    CLASS(MD_Mat_Desc), POINTER :: mat_desc => NULL()
    REAL(wp) :: thickness   = 0.0_wp
    REAL(wp) :: orientation(3) = 0.0_wp
    REAL(wp) :: offset      = 0.0_wp
    INTEGER(i4) :: nlayer           = 1
    INTEGER(i4) :: integ_npts       = 0
    CHARACTER(LEN=16) :: integ_rule = ''
    INTEGER(i4) :: section_family = 0
    INTEGER(i4) :: section_type   = 0
    LOGICAL :: is_initialized = .FALSE.
    !--- Fields absorbed from legacy MD_Sect_Desc (G9) ---
    REAL(wp)          :: area             = 1.0_wp
    LOGICAL           :: valid            = .FALSE.
  CONTAINS
    PROCEDURE :: InitBasic      => Sect_InitBasic
    PROCEDURE :: InitComposite  => Sect_InitComposite
    PROCEDURE :: AssociateMat   => Sect_AssociateMaterial
    PROCEDURE :: Validate       => Sect_Validate
    PROCEDURE :: Nullify        => Sect_NullifyPointer
  END TYPE MD_Sect_Desc

  TYPE, PUBLIC :: MD_Sect_Registry
    TYPE(MD_Sect_Desc), ALLOCATABLE :: sections(:)
    INTEGER(i4) :: nsections = 0
    INTEGER(i4) :: capacity  = 0
  CONTAINS
    PROCEDURE :: Init            => Registry_Init
    PROCEDURE :: AddSection      => Registry_AddSection
    PROCEDURE :: GetSectIdx      => Registry_GetSectIdx
    PROCEDURE :: FindByName      => Registry_FindByName
    PROCEDURE :: FindByMaterial  => Registry_FindByMaterial
    PROCEDURE :: Clear           => Registry_Clear
  END TYPE MD_Sect_Registry

  !---------------------------------------------------------------------------
  ! Legacy flat descriptors (Phase B domain / sync)
  !---------------------------------------------------------------------------
  PUBLIC :: MD_Section_GetSection_Idx, MD_Section_GetSectionByName_Idx

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_State
  ! KIND:  State
  ! DESC:  Section domain state — active count and total area tracking
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_State
    INTEGER(i4) :: active_sections    = 0_i4
    INTEGER(i4) :: total_sections     = 0_i4
    REAL(wp)    :: total_section_area = 0.0_wp
  END TYPE MD_Sect_State

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_Ctx
  ! KIND:  Ctx
  ! DESC:  Section context — current section index
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Ctx
    INTEGER(i4) :: current_section_idx = 0_i4
  END TYPE MD_Sect_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_Algo
  ! KIND:  Algo
  ! DESC:  Section algorithm descriptor — default integration rule
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Algo
    INTEGER(i4) :: default_integration_rule = 0_i4
  END TYPE MD_Sect_Algo

  !--- Legacy MD_Sect_Desc removed (G9): fields absorbed into MD_Sect_Desc ---

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_Catalog_Desc
  ! KIND:  Desc
  ! DESC:  Fixed-capacity section registry (Core path; cold L3)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Catalog_Desc
    TYPE(MD_Sect_Desc) :: sections(MD_SECTION_MAX)
    INTEGER(i4)       :: n_sections = 0_i4
  END TYPE MD_Sect_Catalog_Desc

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_Add_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for section addition
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Add_Arg
    TYPE(MD_Sect_Desc)     :: desc
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Sect_Add_Arg

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_Validate_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for section validation
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Validate_Arg
    INTEGER(i4)           :: idx = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Sect_Validate_Arg

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_GetSummary_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for section summary retrieval
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Sect_GetSummary_Arg

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_Get_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for single-section retrieval
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Get_Arg
    TYPE(MD_Sect_Desc) :: desc
  END TYPE MD_Sect_Get_Arg

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_GetByName_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for section retrieval by name
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_GetByName_Arg
    INTEGER(i4)       :: section_idx = 0_i4
    LOGICAL             :: found       = .FALSE.
    TYPE(MD_Sect_Desc)   :: desc
  END TYPE MD_Sect_GetByName_Arg

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Sect_Domain
  ! KIND:  Desc
  ! DESC:  Section domain container — aggregates desc_array + algo + lifecycle
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Sect_Domain
    TYPE(MD_Sect_Desc), ALLOCATABLE :: desc_array(:)
    INTEGER(i4)                    :: n_sections = 0_i4
    INTEGER(i4)                    :: capacity   = 0_i4
    TYPE(MD_Sect_Algo)              :: algo
    LOGICAL                        :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: Add
    PROCEDURE :: Get
    PROCEDURE :: GetByName
    PROCEDURE :: Validate
    PROCEDURE :: GetSummary
  END TYPE MD_Sect_Domain

CONTAINS

  SUBROUTINE Sect_InitBasic(self, id, name, family)
    CLASS(MD_Sect_Desc), INTENT(INOUT) :: self
    INTEGER(i4),              INTENT(IN)    :: id
    CHARACTER(LEN=*),         INTENT(IN)    :: name
    INTEGER(i4),              INTENT(IN)    :: family

    self%section_id     = id
    self%section_name   = TRIM(name)
    self%section_family = family
    self%mat_desc       => NULL()
    self%mat_id         = 0
    self%is_initialized = .TRUE.
  END SUBROUTINE Sect_InitBasic

  SUBROUTINE Sect_InitComposite(self, nlayer, thickness, npts, rule)
    CLASS(MD_Sect_Desc), INTENT(INOUT) :: self
    INTEGER(i4),              INTENT(IN)    :: nlayer
    REAL(wp),                 INTENT(IN)    :: thickness
    INTEGER(i4),              INTENT(IN)    :: npts
    CHARACTER(LEN=*),         INTENT(IN)    :: rule

    self%nlayer     = nlayer
    self%thickness  = thickness
    self%integ_npts = npts
    self%integ_rule = TRIM(rule)
  END SUBROUTINE Sect_InitComposite

  SUBROUTINE Sect_AssociateMaterial(self, mat_desc_ptr)
    CLASS(MD_Sect_Desc), INTENT(INOUT)      :: self
    CLASS(MD_Mat_Desc),  INTENT(IN), TARGET :: mat_desc_ptr

    self%mat_desc => mat_desc_ptr
    self%mat_id   =  mat_desc_ptr%cfg%matId
  END SUBROUTINE Sect_AssociateMaterial

  SUBROUTINE Sect_Validate(self, st)
    CLASS(MD_Sect_Desc), INTENT(IN)  :: self
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

    IF (self%section_family < SECT_FAM_SOLID .OR. &
        self%section_family > SECT_FAM_CONNECTOR) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "section_family out of valid range [1..9]"
      RETURN
    END IF

    IF (self%section_family == SECT_FAM_SHELL .OR. &
        self%section_family == SECT_FAM_MEMBRANE) THEN
      IF (self%thickness <= 0.0_wp) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "Shell/Membrane section requires thickness > 0"
        RETURN
      END IF
    END IF

    IF (self%section_family == SECT_FAM_BEAM .OR. &
        self%section_family == SECT_FAM_TRUSS) THEN
      IF (LEN_TRIM(self%section_name) == 0) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "Beam/Truss section requires a non-empty section_name"
        RETURN
      END IF
    END IF

    st%status_code = IF_STATUS_OK
  END SUBROUTINE Sect_Validate

  SUBROUTINE Sect_NullifyPointer(self)
    CLASS(MD_Sect_Desc), INTENT(INOUT) :: self
    NULLIFY(self%mat_desc)
  END SUBROUTINE Sect_NullifyPointer

  SUBROUTINE Registry_Init(self, est)
    CLASS(MD_Sect_Registry), INTENT(INOUT) :: self
    INTEGER(i4),             INTENT(IN)    :: est

    INTEGER(i4) :: cap
    cap = MAX(16_i4, est)
    IF (ALLOCATED(self%sections)) CALL self%Clear()
    ALLOCATE(self%sections(cap))
    self%capacity  = cap
    self%nsections = 0
  END SUBROUTINE Registry_Init

  SUBROUTINE Registry_AddSection(self, sect)
    CLASS(MD_Sect_Registry), INTENT(INOUT) :: self
    TYPE(MD_Sect_Desc), INTENT(IN)    :: sect

    TYPE(MD_Sect_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, new_cap

    n = self%nsections

    IF (self%capacity > 0) THEN
      IF (n >= self%capacity) THEN
        new_cap = self%capacity * 2_i4
        ALLOCATE(tmp(new_cap))
        tmp(1:n) = self%sections(1:n)
        CALL MOVE_ALLOC(tmp, self%sections)
        self%capacity = new_cap
      END IF
      self%sections(n+1) = sect
    ELSE
      ALLOCATE(tmp(n+1))
      IF (n > 0) tmp(1:n) = self%sections(1:n)
      tmp(n+1) = sect
      CALL MOVE_ALLOC(tmp, self%sections)
    END IF

    self%nsections = n + 1
  END SUBROUTINE Registry_AddSection

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

  SUBROUTINE Registry_Clear(self)
    CLASS(MD_Sect_Registry), INTENT(INOUT) :: self
    INTEGER(i4) :: i
    DO i = 1, self%nsections
      CALL self%sections(i)%Nullify()
    END DO
    IF (ALLOCATED(self%sections)) DEALLOCATE(self%sections)
    self%nsections = 0
    self%capacity  = 0
  END SUBROUTINE Registry_Clear

  SUBROUTINE Add(this, arg)
    CLASS(MD_Sect_Domain),        INTENT(INOUT) :: this
    TYPE(MD_Sect_Add_Arg), INTENT(INOUT) :: arg
    CALL MD_Section_AddSection_Impl(this, arg%desc, arg%status)
  END SUBROUTINE Add

  SUBROUTINE MD_Section_AddSection_Impl(this, desc, status)
    CLASS(MD_Sect_Domain), INTENT(INOUT) :: this
    TYPE(MD_Sect_Desc),        INTENT(IN)    :: desc
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    TYPE(MD_Sect_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: new_cap

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Sect_Domain not initialized"
      RETURN
    END IF

    IF (this%n_sections >= this%capacity) THEN
      new_cap = MAX(16_i4, this%capacity * 2_i4)
      ALLOCATE(tmp(new_cap))
      IF (this%n_sections > 0) tmp(1:this%n_sections) = this%desc_array(1:this%n_sections)
      CALL MOVE_ALLOC(tmp, this%desc_array)
      this%capacity = new_cap
    END IF

    this%n_sections = this%n_sections + 1_i4
    this%desc_array(this%n_sections) = desc
    this%desc_array(this%n_sections)%section_id = this%n_sections
    this%desc_array(this%n_sections)%valid = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Section_AddSection_Impl

  SUBROUTINE Finalize(this)
    CLASS(MD_Sect_Domain), INTENT(INOUT) :: this

    IF (ALLOCATED(this%desc_array)) DEALLOCATE(this%desc_array)
    this%n_sections  = 0_i4
    this%capacity    = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  SUBROUTINE Get(this, idx, desc, status)
    CLASS(MD_Sect_Domain), INTENT(IN)  :: this
    INTEGER(i4),              INTENT(IN)  :: idx
    TYPE(MD_Sect_Desc),        INTENT(OUT) :: desc
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_sections) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    desc = this%desc_array(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Get

  SUBROUTINE GetByName(this, name, desc, status)
    CLASS(MD_Sect_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),         INTENT(IN)  :: name
    TYPE(MD_Sect_Desc),        INTENT(OUT) :: desc
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO i = 1, this%n_sections
      IF (TRIM(this%desc_array(i)%name) == TRIM(name)) THEN
        desc = this%desc_array(i)
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
    status%message = "Section not found: " // TRIM(name)
  END SUBROUTINE GetByName

  SUBROUTINE Init(this, est_sections, status)
    CLASS(MD_Sect_Domain), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: est_sections
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    this%capacity = MAX(16_i4, est_sections)
    ALLOCATE(this%desc_array(this%capacity))
    this%n_sections  = 0_i4
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  SUBROUTINE Validate(this, arg)
    CLASS(MD_Sect_Domain),             INTENT(IN)    :: this
    TYPE(MD_Sect_Validate_Arg), INTENT(INOUT) :: arg
    CALL MD_Section_ValidateSection_Impl(this, arg%idx, arg%status)
  END SUBROUTINE Validate

  SUBROUTINE MD_Section_ValidateSection_Impl(this, idx, status)
    CLASS(MD_Sect_Domain), INTENT(IN)  :: this
    INTEGER(i4),              INTENT(IN)  :: idx
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: st

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_sections) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Section index out of range"
      RETURN
    END IF

    ASSOCIATE (s => this%desc_array(idx))
      st = s%section_type
      IF (st < SECT_TYPE_MIN .OR. st > SECT_TYPE_MAX) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "section_type out of valid range [1..30]"
        RETURN
      END IF

      IF (s%material_ref < 1) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "material_ref not set for section"
        RETURN
      END IF

      IF (st == SECT_SHELL .OR. st == SECT_SHELL_COMPOSITE .OR. &
          st == SECT_MEMBRANE .OR. st == SECT_SURFACE_SHELL .OR. &
          st == SECT_THERMAL_SHELL .OR. st == SECT_ACOUSTIC_SHELL) THEN
        IF (s%thickness <= 0.0_wp) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "Shell/membrane section requires thickness > 0"
          RETURN
        END IF
      END IF

      IF (st == SECT_BEAM_EULER .OR. st == SECT_BEAM_TIMOSHENKO .OR. &
          st == SECT_TRUSS) THEN
        IF (LEN_TRIM(s%name) == 0) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "Beam/truss section requires a name"
          RETURN
        END IF
      END IF
    END ASSOCIATE

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Section_ValidateSection_Impl

  SUBROUTINE GetSummary(this, arg)
    CLASS(MD_Sect_Domain),         INTENT(IN)    :: this
    TYPE(MD_Sect_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL MD_Section_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE GetSummary

  SUBROUTINE MD_Section_GetSummary_Impl(this, summary, status)
    CLASS(MD_Sect_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),       INTENT(OUT) :: summary
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Sect_Domain not initialized"
      RETURN
    END IF

    WRITE (summary, '(A,I0,A,I0,A,I0)') &
      "Section Summary: Sections=", this%n_sections, &
      ", Capacity=", this%capacity, &
      ", Integration=", this%algo%default_integration_rule

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Section_GetSummary_Impl

  SUBROUTINE MD_Section_GetSection_Idx(dom, section_idx, arg, status)
    TYPE(MD_Sect_Domain),          INTENT(IN)    :: dom
    INTEGER(i4),                      INTENT(IN)    :: section_idx
    TYPE(MD_Sect_Get_Arg),  INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),            INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. dom%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Section domain not initialized"
      RETURN
    END IF
    IF (section_idx < 1_i4 .OR. section_idx > dom%n_sections) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    arg%desc = dom%desc_array(section_idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Section_GetSection_Idx

  SUBROUTINE MD_Section_GetSectionByName_Idx(dom, name, arg, status)
    TYPE(MD_Sect_Domain),               INTENT(IN)    :: dom
    CHARACTER(LEN=*),                      INTENT(IN)    :: name
    TYPE(MD_Sect_GetByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),                 INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    arg%section_idx = 0_i4
    arg%found = .FALSE.
    IF (.NOT. dom%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Section domain not initialized"
      RETURN
    END IF
    DO i = 1, dom%n_sections
      IF (TRIM(dom%desc_array(i)%name) == TRIM(name)) THEN
        arg%found = .TRUE.
        arg%section_idx = i
        arg%desc = dom%desc_array(i)
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_INVALID
    status%message = "Section not found: " // TRIM(name)
  END SUBROUTINE MD_Section_GetSectionByName_Idx

END MODULE MD_Sect_Def
