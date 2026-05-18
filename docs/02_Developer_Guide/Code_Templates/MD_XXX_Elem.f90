!===============================================================================
! Template: MD_Elem_XXX.f90                                     [Template v1.0]
! Layer:  L3_MD - Model Description Layer
! Domain: Element / [Family] (e.g., CONTI / SHELL / BEAM / TRUSS / ...)
!
! HOW TO USE:
!   1. Copy to L3_MD/Element/[Family]/
!   2. Rename: MD_Elem_[Family]_[Type].f90  (e.g., MD_Elem_CONTI_C3D8.f90)
!   3. Replace XXX_XXX -> [Family]_[Type]   (e.g., CONTI_C3D8)
!   4. Replace XXX     -> [Type abbrev]     (e.g., C3D8)
!   5. Fill in: elem_type_id, integ_npts, n_nodes, n_dof_per_node
!   6. Implement: MD_XXX_Elem_ValidateProps, MD_XXX_Elem_InitFromProps
!
! Naming Convention (layer prefix rule):
!   Module:    MD_Elem_[Family]_[Type]       → MD_Elem_CONTI_C3D8
!   Desc type: MD_XXX_Elem_Desc              → MD_Elem_C3D8_Desc  (MD-owned)
!   Validate:  MD_XXX_Elem_ValidateProps     → MD_Elem_C3D8_ValidateProps
!   Init:      MD_XXX_Elem_InitFromProps     → MD_Elem_C3D8_InitFromProps
!
! Design notes:
!   - MD_Elem_Base_Desc carries: elem_type_id, integ_npts, n_nodes,
!     n_dof_per_node, n_dof_total, is_initialized.
!   - This Desc adds element-family-specific topology and integration
!     parameters (e.g., integration scheme flag, hourglass stabilisation,
!     reduced integration flag, section ID mapping).
!   - Purely static / configuration: set ONCE at model load.
!   - NEVER carry per-increment state here (that belongs in PH_Elem_Base_State).
!===============================================================================
MODULE MD_Elem_XXX
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Elem_Ids,  ONLY: ELEM_TYPE_ID_XXX       ! ← replace with actual type ID
  USE MD_Elem_Types,ONLY: MD_Elem_Base_Desc       ! ← L3_MD element base descriptor
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public exports: Desc type + two standard MD-layer interfaces
  ! Prefix MD_XXX_ signals these subroutines belong to L3_MD layer.
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_XXX_Elem_Desc            ! L3_MD element descriptor type (MD-owned)
  PUBLIC :: MD_XXX_Elem_ValidateProps   ! Validate flat props array (jprops/props)
  PUBLIC :: MD_XXX_Elem_InitFromProps   ! Unpack props -> MD_XXX_Elem_Desc

  !-----------------------------------------------------------------------------
  ! Constants — element-type invariants (topology / integration)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: ELEM_N_NODES_DEFAULT    = 8_i4   ! e.g., 8 for C3D8
  INTEGER(i4), PARAMETER :: ELEM_INTEG_NIP_DEFAULT  = 8_i4   ! default full integration
  INTEGER(i4), PARAMETER :: ELEM_NDOF_PER_NODE      = 3_i4   ! 3 for solid, 6 for shell
  INTEGER(i4), PARAMETER :: ELEM_JPROPS_MIN          = 1_i4   ! min jprops slots (section_id)
  !
  ! jprops layout (document ALL slots for THIS element type):
  !   jprops(1) = section_id  : integer section identifier (required)
  !   jprops(2) = integ_flag  : 0=full, 1=reduced, 2=user-defined
  !   jprops(3) = hourglass   : hourglass stabilisation mode (0=none)
  !   ...
  ! props layout (real element properties, if any):
  !   props(1) = ???    : (example: section thickness for shells [m])
  !   props(2) = ???    : model-specific [unit]
  !   ...
  ! NOTE: document every slot explicitly; no "pass-through" assumptions.

  !-----------------------------------------------------------------------------
  ! DESC type: EXTENDS MD_Elem_Base_Desc, adds element-specific topology.
  !
  !   MD_Elem_Base_Desc provides:
  !     elem_type_id   — element type identifier (JTYPE from ABAQUS)
  !     integ_npts     — number of integration points (>0 required)
  !     n_nodes        — number of nodes (connectivity size)
  !     n_dof_per_node — DOF per node (3=solid, 6=shell/beam)
  !     n_dof_total    — n_nodes * n_dof_per_node
  !     is_initialized — .TRUE. after InitFromProps succeeds
  !
  !   Add element-family-specific descriptor fields below.
  !   For continuum solids: add integ_rule flag, hourglass params.
  !   For shells: add thickness, section_type, laminate_angle.
  !   For beams:  add cross-section geometry, area, I_y, I_z.
  !-----------------------------------------------------------------------------
  !> L3 descriptor for [Element Type Name] element family.
  TYPE, PUBLIC, EXTENDS(MD_Elem_Base_Desc) :: MD_XXX_Elem_Desc
    !-- Section / material linkage
    INTEGER(i4) :: section_id       = 0_i4    ! Section ID (jprops(1))

    !-- Integration rule
    INTEGER(i4) :: integ_rule_flag  = 0_i4    ! 0=full, 1=reduced, 2=user-defined
    REAL(wp)    :: hourglass_coeff  = 0.0_wp  ! Hourglass stabilisation coefficient

    !-- Element-family-specific parameters (replace with actual parameters)
    !   For shells: REAL(wp) :: thickness = 0.0_wp
    !               INTEGER(i4) :: n_section_pts = 5_i4
    !   For beams:  REAL(wp) :: area = 0.0_wp
    !               REAL(wp) :: I_y  = 0.0_wp, I_z = 0.0_wp
    REAL(wp) :: elem_param1 = 0.0_wp   ! Element-type-specific parameter [unit]
    REAL(wp) :: elem_param2 = 0.0_wp   ! Element-type-specific parameter [unit]

    !-- Derived / pre-computed topology constants (populated in InitFromProps)
    !   e.g., n_dof_total = n_nodes * n_dof_per_node (cached for hot-path)
    INTEGER(i4) :: n_dof_elem  = 0_i4  ! Total element DOF = n_nodes * n_dof_per_node

  CONTAINS
    !-- Required by MD_Elem_Base_Desc TBP interface
    PROCEDURE :: ValidateProps => MD_XXX_Elem_ValidateProps_TBP
    PROCEDURE :: InitFromProps => MD_XXX_Elem_InitFromProps_TBP
  END TYPE MD_XXX_Elem_Desc

CONTAINS

  !-----------------------------------------------------------------------------
  !> MD_XXX_Elem_ValidateProps
  !>   Validates the flat jprops/props arrays for [Element Type Name].
  !>   Called by L4_PH (via MD_XXX_Elem_InitFromProps) before populating Desc.
  !>   Returns structured status with %status_code = IF_STATUS_INVALID on any
  !>   constraint violation.
  !>
  !>   njprops — number of integer element properties (from INP *UEL PROPERTY)
  !>   jprops  — integer property array (section_id, flags, ...)
  !>   nprops  — number of real element properties (optional)
  !>   props   — real property array (thickness, etc.)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Elem_ValidateProps(njprops, jprops, nprops, props, st)
    INTEGER(i4),           INTENT(IN)  :: njprops      ! Number of integer props
    INTEGER(i4),           INTENT(IN)  :: jprops(:)    ! Integer props (jprops)
    INTEGER(i4),           INTENT(IN)  :: nprops       ! Number of real props
    REAL(wp),              INTENT(IN)  :: props(:)     ! Real props (props)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)

    !-- Minimum jprops count (must have section_id at jprops(1))
    IF (njprops < ELEM_JPROPS_MIN) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Elem]: need >= ELEM_JPROPS_MIN jprops"
      RETURN
    END IF

    !-- section_id must be positive
    IF (jprops(1) < 1) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Elem]: jprops(1) (section_id) must be >= 1"
      RETURN
    END IF

    !-- integ_rule_flag (jprops(2)) range check if present
    IF (njprops >= 2) THEN
      IF (jprops(2) < 0 .OR. jprops(2) > 2) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Elem]: jprops(2) (integ_rule_flag) must be 0, 1, or 2"
        RETURN
      END IF
    END IF

    !-- Real props physical constraints (model-specific — replace with actual)
    !   e.g., for shell thickness: props(1) > 0.0_wp
    IF (nprops >= 1) THEN
      IF (props(1) < 0.0_wp) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Elem]: props(1) (elem_param1) must be >= 0"
        RETURN
      END IF
    END IF

    !-- TODO: add further element-type-specific constraints here

    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Elem_ValidateProps

  !-----------------------------------------------------------------------------
  !> MD_XXX_Elem_InitFromProps
  !>   Unpacks jprops/props into MD_XXX_Elem_Desc.
  !>   Computes all derived topology constants (n_dof_elem, etc.).
  !>   Called ONCE at model load (or first call to UEL if lazy-init).
  !>
  !>   desc  — output Desc (populated by this subroutine)
  !>   njprops, jprops — integer property array (section_id, flags)
  !>   nprops, props   — real property array (thickness, etc.)
  !>   st    — structured status object (%status_code == IF_STATUS_OK on success)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Elem_InitFromProps(desc, njprops, jprops, nprops, props, st)
    TYPE(MD_XXX_Elem_Desc), INTENT(OUT) :: desc
    INTEGER(i4),            INTENT(IN)  :: njprops
    INTEGER(i4),            INTENT(IN)  :: jprops(:)
    INTEGER(i4),            INTENT(IN)  :: nprops
    REAL(wp),               INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT) :: st

    CALL init_error_status(st)

    !-- Step 1: validate before unpacking
    CALL MD_XXX_Elem_ValidateProps(njprops, jprops, nprops, props, st)
    IF (st%status_code /= IF_STATUS_OK) RETURN

    !-- Step 2: populate base fields (inherited from MD_Elem_Base_Desc)
    desc%elem_type_id   = ELEM_TYPE_ID_XXX
    desc%n_nodes        = ELEM_N_NODES_DEFAULT
    desc%n_dof_per_node = ELEM_NDOF_PER_NODE
    desc%integ_npts     = ELEM_INTEG_NIP_DEFAULT

    !-- Step 3: unpack integer props (jprops)
    desc%section_id      = jprops(1)
    IF (njprops >= 2) THEN
      desc%integ_rule_flag = jprops(2)
    ELSE
      desc%integ_rule_flag = 0_i4    ! default: full integration
    END IF
    IF (njprops >= 3) THEN
      !-- hourglass mode stored as integer -> cast
      !  desc%hourglass_mode = jprops(3)  ! (add if needed)
    END IF

    !-- Step 4: unpack real props (props)
    IF (nprops >= 1) desc%elem_param1 = props(1)
    IF (nprops >= 2) desc%elem_param2 = props(2)
    !-- TODO: unpack further model-specific props slots

    !-- Step 5: set integration NIP based on integ_rule_flag
    SELECT CASE (desc%integ_rule_flag)
      CASE (0)    ! Full integration
        desc%integ_npts = ELEM_INTEG_NIP_DEFAULT
      CASE (1)    ! Reduced integration (1 IP for C3D8R, etc.)
        desc%integ_npts = 1_i4
      CASE (2)    ! User-defined: use default (caller must override)
        desc%integ_npts = ELEM_INTEG_NIP_DEFAULT
      CASE DEFAULT
        desc%integ_npts = ELEM_INTEG_NIP_DEFAULT
    END SELECT

    !-- Step 6: compute derived topology constants
    desc%n_dof_elem = desc%n_nodes * desc%n_dof_per_node

    !-- Step 7: mark initialized
    desc%is_initialized = .TRUE.
    st%status_code      = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Elem_InitFromProps


END MODULE MD_Elem_XXX

!===============================================================================
! USAGE NOTES — MD_XXX_Elem_Desc instantiation example
!
!   USE MD_Elem_C3D8, ONLY: MD_Elem_C3D8_Desc, MD_Elem_C3D8_InitFromProps
!   TYPE(MD_Elem_C3D8_Desc) :: elem_desc
!   TYPE(ErrorStatusType)   :: st
!
!   !-- From ABAQUS UEL arguments:
!   CALL MD_Elem_C3D8_InitFromProps(elem_desc, njprops, jprops, nprops, props, st)
!   IF (st%status_code /= IF_STATUS_OK) ERROR STOP '[UEL]: Bad element props'
!
!   !-- OR from UFC registry (model load time):
!   elem_desc = elem_registry%get(ELEM_TYPE_ID_C3D8)
!
!   !-- Pass to L4_PH element kernel:
!   CALL PH_C3D8_UEL_API(sect_registry, elem_desc, PH_Elem_Ctx, ...)
!===============================================================================
