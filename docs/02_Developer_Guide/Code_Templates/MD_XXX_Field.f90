!===============================================================================
! Template: MD_Field_XXX.f90                                    [Template v1.0]
! Layer:  L3_MD - Model Description Layer
! Domain: Field / [Family] (e.g., USDFLD / SDVINI / SIGINI / UFIELD)
!
! HOW TO USE:
!   1. Copy to L3_MD/Field/[Family]/
!   2. Rename: MD_Field_[Family]_[Type].f90
!              (e.g., MD_Field_USDFLD_Damage.f90, MD_Field_SDVINI_Plastic.f90)
!   3. Replace XXX_XXX -> [Family]_[Type]  (e.g., USDFLD_Dmg)
!   4. Replace XXX     -> [Type abbrev]    (e.g., Dmg)
!   5. Fill in: field_type_id, nfield, nstatv, initial value layout
!   6. Implement: MD_XXX_Field_ValidateProps, MD_XXX_Field_InitFromProps
!
! Naming Convention (layer prefix rule):
!   Module:    MD_Field_[Family]_[Type]      → MD_Field_USDFLD_Damage
!   Desc type: MD_XXX_Field_Desc             → MD_Field_Dmg_Desc  (MD-owned)
!   Validate:  MD_XXX_Field_ValidateProps    → MD_Field_Dmg_ValidateProps
!   Init:      MD_XXX_Field_InitFromProps    → MD_Field_Dmg_InitFromProps
!
! Design notes (UFC Field domain):
!   - USDFLD:  User solution-dependent field variables (Standard)
!   - VUSDFLD: Vectorised USDFLD (Explicit block)
!   - UFIELD:  User pre-defined field variable distribution
!   - SDVINI:  Initial solution-dependent state variable values
!   - SIGINI:  Initial stress field
!   - MD_Field_Base_Desc carries: field_id, field_type, nfield, nstatv,
!     field_init(:), cmname, is_initialized.
!   - NEVER carry per-increment FIELD values here
!     (those belong in PH_Field_Base_State).
!===============================================================================
MODULE MD_Field_XXX
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Field_Types, ONLY: MD_Field_Base_Desc, &
                            MD_FIELD_FIELD_TYPE_SCALAR, &   ! ← replace if needed
                            MD_FIELD_FIELD_SUBRT_USDFLD     ! ← replace if needed
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public exports: Desc type + two standard MD-layer interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_XXX_Field_Desc            ! L3_MD field descriptor (MD-owned)
  PUBLIC :: MD_XXX_Field_ValidateProps   ! Validate flat props array
  PUBLIC :: MD_XXX_Field_InitFromProps   ! Unpack props -> MD_XXX_Field_Desc

  !-----------------------------------------------------------------------------
  ! Constants — field family invariants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: FIELD_NPROPS_MIN = 1_i4   ! Minimum props count
  INTEGER(i4), PARAMETER :: FIELD_NFIELD_MIN  = 1_i4   ! Minimum field variables
  !
  ! Props layout (document ALL slots for THIS field type):
  !   props(1) = nfield_user   : number of user-defined field variables (int as real)
  !   props(2) = nstatv_user   : number of SDVs managed by this field set
  !   props(3) = field_init(1) : initial value for field variable 1
  !   props(4) = field_init(2) : initial value for field variable 2
  !   ...
  !   props(2+nfield) = field_init(nfield)

  !-----------------------------------------------------------------------------
  ! DESC type: EXTENDS MD_Field_Base_Desc, adds field-family-specific metadata.
  !
  !   MD_Field_Base_Desc provides:
  !     field_id       — field set identifier
  !     field_type     — SCALAR / VECTOR / TENSOR / SDV enum
  !     subrt_type     — USDFLD / VUSDFLD / UFIELD / SDVINI / SIGINI enum
  !     field_name     — human-readable label (CHARACTER(LEN=64))
  !     nfield         — number of field variables
  !     nstatv         — number of solution-dependent state variables
  !     field_init(:)  — initial values for each field variable (ALLOCATABLE)
  !     cmname         — material name (CHARACTER(LEN=80))
  !     is_initialized — .TRUE. after InitFromProps succeeds
  !
  !   Add field-family-specific descriptor fields below.
  !   For USDFLD damage:    add damage_threshold, healing_flag
  !   For SIGINI:           add sig_init(6) (initial stress tensor)
  !   For SDVINI:           add sdv_init_count, sdv_names
  !   For temperature dep:  add T_ref, field_coeff (interpolation)
  !-----------------------------------------------------------------------------
  !> L3 descriptor for [Field Family / Type Name] field variable set.
  TYPE, PUBLIC, EXTENDS(MD_Field_Base_Desc) :: MD_XXX_Field_Desc
    !-- Field family sub-type classification
    INTEGER(i4) :: field_subrt  = MD_FIELD_FIELD_SUBRT_USDFLD  ! ← replace

    !-- GETVRM request flags (which output variables to retrieve)
    LOGICAL :: req_stress  = .FALSE.  ! Retrieve stress tensor (USDFLD)
    LOGICAL :: req_strain  = .FALSE.  ! Retrieve strain tensor (USDFLD)
    LOGICAL :: req_peeq    = .FALSE.  ! Retrieve equiv. plastic strain
    LOGICAL :: req_triax   = .FALSE.  ! Retrieve stress triaxiality

    !-- Field-family-specific parameters (replace with actual parameters)
    !   For USDFLD damage threshold model:
    !     REAL(wp) :: damage_threshold = 0.0_wp
    !     LOGICAL  :: enable_healing   = .FALSE.
    !   For SIGINI initial stress:
    !     REAL(wp) :: sig_init(6)      = 0.0_wp
    !   For SDVINI:
    !     INTEGER(i4) :: sdv_init_count = 0_i4
    REAL(wp)    :: field_param1 = 0.0_wp   ! Field-type-specific parameter [unit]
    REAL(wp)    :: field_param2 = 0.0_wp   ! Field-type-specific parameter [unit]

    !-- Amplitude reference for time-dependent initial fields
    CHARACTER(LEN=64) :: amplitude_name = ''  ! Optional amplitude reference

  END TYPE MD_XXX_Field_Desc

CONTAINS

  !-----------------------------------------------------------------------------
  !> MD_XXX_Field_ValidateProps
  !>   Validates the flat props array for [Field Family / Type].
  !>   Returns structured status with %status_code = IF_STATUS_INVALID on any
  !>   constraint violation.
  !>
  !>   nprops  — number of real properties
  !>   props   — real properties array
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Field_ValidateProps(nprops, props, st)
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    INTEGER(i4) :: nfield_declared

    CALL init_error_status(st)

    !-- Minimum count check
    IF (nprops < FIELD_NPROPS_MIN) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Field]: need >= FIELD_NPROPS_MIN props"
      RETURN
    END IF

    !-- nfield (props(1)) must be a positive integer value
    IF (nprops >= 1) THEN
      nfield_declared = INT(props(1), i4)
      IF (nfield_declared < FIELD_NFIELD_MIN) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Field]: props(1) (nfield) must be >= 1"
        RETURN
      END IF
      !-- Check sufficient slots for initial values
      IF (nprops < 2 + nfield_declared - 1) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Field]: insufficient props for initial field values"
        RETURN
      END IF
    END IF

    !-- TODO: add further field-type-specific validation here

    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Field_ValidateProps

  !-----------------------------------------------------------------------------
  !> MD_XXX_Field_InitFromProps
  !>   Unpacks nprops/props into MD_XXX_Field_Desc.
  !>   Called ONCE at model load or at first USDFLD/SDVINI call.
  !>
  !>   desc   — output Desc (populated by this subroutine)
  !>   nprops — number of real properties
  !>   props  — real property array
  !>   st     — structured status object (%status_code == IF_STATUS_OK on success)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Field_InitFromProps(desc, nprops, props, st)
    TYPE(MD_XXX_Field_Desc), INTENT(OUT) :: desc
    INTEGER(i4),             INTENT(IN)  :: nprops
    REAL(wp),                INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT) :: st

    INTEGER(i4) :: i, nfield_alloc

    CALL init_error_status(st)

    !-- Step 1: validate before unpacking
    CALL MD_XXX_Field_ValidateProps(nprops, props, st)
    IF (st%status_code /= IF_STATUS_OK) RETURN

    !-- Step 2: populate base fields (inherited from MD_Field_Base_Desc)
    desc%field_type  = MD_FIELD_FIELD_TYPE_SCALAR   ! ← replace with actual type
    desc%subrt_type  = MD_FIELD_FIELD_SUBRT_USDFLD  ! ← replace with actual subrt
    desc%field_subrt = MD_FIELD_FIELD_SUBRT_USDFLD

    !-- Step 3: unpack field count and SDV count
    desc%nfield = INT(props(1), i4)
    IF (nprops >= 2) THEN
      desc%nstatv = INT(props(2), i4)
    ELSE
      desc%nstatv = 0_i4
    END IF

    !-- Step 4: unpack field-specific parameters
    IF (nprops >= 3) desc%field_param1 = props(3)
    IF (nprops >= 4) desc%field_param2 = props(4)
    !-- TODO: unpack further field-family-specific props slots

    !-- Step 5: unpack initial field values (props(2+nfield) onward)
    nfield_alloc = desc%nfield
    IF (nfield_alloc > 0) THEN
      IF (.NOT. ALLOCATED(desc%field_init)) ALLOCATE(desc%field_init(nfield_alloc))
      DO i = 1, nfield_alloc
        IF (2 + i <= nprops) THEN
          desc%field_init(i) = props(2 + i)
        ELSE
          desc%field_init(i) = 0.0_wp   ! default to zero if not specified
        END IF
      END DO
    END IF

    !-- Step 6: set GETVRM request flags (defaults; caller may override)
    desc%req_stress = .FALSE.
    desc%req_strain = .FALSE.
    desc%req_peeq   = .FALSE.
    desc%req_triax  = .FALSE.
    !-- TODO: wire flags from props or configuration

    !-- Step 7: allocate base props array
    desc%nprops = nprops
    IF (.NOT. ALLOCATED(desc%props)) ALLOCATE(desc%props(nprops))
    desc%props(1:nprops) = props(1:nprops)

    !-- Step 8: mark initialized
    desc%is_initialized = .TRUE.
    st%status_code      = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Field_InitFromProps

END MODULE MD_Field_XXX
