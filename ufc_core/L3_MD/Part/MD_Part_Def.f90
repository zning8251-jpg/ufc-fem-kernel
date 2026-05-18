!===============================================================================
! MODULE:  MD_Part_Def
! LAYER:   L3_MD
! DOMAIN:  Part
! ROLE:    _Def
! BRIEF:   Part domain type definitions — Desc + State + Arg bundles.
!          Algo/Ctx omitted (simple registry, no algorithm or cross-context).
!===============================================================================
MODULE MD_Part_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Constants
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_PART_MAX      = 256
  INTEGER(i4), PARAMETER, PUBLIC :: MD_PART_NAME_LEN = 64
  ! Legacy alias (CHARACTER(LEN=*) declarations use MAX_PART_NAME)
  INTEGER(i4), PARAMETER, PUBLIC :: MAX_PART_NAME    = MD_PART_NAME_LEN

  !---------------------------------------------------------------------------
  ! Legacy UF_* types (builder / MD_Model_Lib / Sync — cfg mirrors assign-on-add)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: UF_PartCfg
    INTEGER(i4) :: id   = 0_i4
    INTEGER(i4) :: ndim = 3_i4
  END TYPE UF_PartCfg

  TYPE, PUBLIC :: UF_PartDef
    CHARACTER(LEN=MD_PART_NAME_LEN) :: name = ""
    TYPE(UF_PartCfg)               :: cfg
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4) :: nElems = 0_i4
  END TYPE UF_PartDef

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Part_Entry_Desc
  ! KIND:  Desc
  ! DESC:  Single part entry — read-only definition record
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Part_Entry_Desc
    INTEGER(i4)                     :: id         = 0        ! [in] part ID
    CHARACTER(LEN=MD_PART_NAME_LEN) :: name       = ""       ! [in] part name
    INTEGER(i4)                     :: section_id = 0        ! [in] bound section ID
    LOGICAL                         :: valid      = .FALSE.  ! [in] entry validity
  END TYPE MD_Part_Entry_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Part_Desc
  ! KIND:  Desc
  ! DESC:  Part collection descriptor — flat array of entry records
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Part_Desc
    TYPE(MD_Part_Entry_Desc) :: parts(MD_PART_MAX)           ! [in] part entries
    INTEGER(i4)              :: n_parts = 0                  ! [in] count of entries
  END TYPE MD_Part_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Part_State
  ! KIND:  State
  ! DESC:  Part domain runtime state — assignment and validation tracking
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Part_State
    LOGICAL     :: sections_assigned = .FALSE.               ! [inout] all parts have sections
    LOGICAL     :: materials_bound   = .FALSE.               ! [inout] all sections have materials
    LOGICAL     :: validated         = .FALSE.               ! [inout] domain passed validation
    INTEGER(i4) :: n_unassigned      = 0                     ! [out]   count of unassigned parts
  END TYPE MD_Part_State


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Part_Domain
  ! KIND:  Desc
  ! DESC:  Domain container — aggregates Desc + State with lifecycle
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Part_Domain
    TYPE(MD_Part_Desc)  :: desc                              ! [inout] part definitions
    TYPE(MD_Part_State) :: state                             ! [inout] runtime state
    INTEGER(i4)         :: n_parts     = 0                   ! [inout] active part count
    LOGICAL             :: initialized = .FALSE.             ! [inout] lifecycle flag
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: GetSummary
  END TYPE MD_Part_Domain


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Part_Get_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for single-part retrieval by index
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Part_Get_Arg
    TYPE(MD_Part_Entry_Desc) :: desc                         ! [out] retrieved part entry
  END TYPE MD_Part_Get_Arg


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Part_GetByName_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for part retrieval by name
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Part_GetByName_Arg
    TYPE(MD_Part_Entry_Desc) :: desc                         ! [out] retrieved part entry
    INTEGER(i4)              :: part_idx = 0                 ! [out] matched index
    LOGICAL                  :: found    = .FALSE.           ! [out] whether name was found
  END TYPE MD_Part_GetByName_Arg

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: Init (TBP for MD_Part_Domain)
  ! PHASE:      P0
  ! PURPOSE:    Initialize domain container — reset all entries and state
  !---------------------------------------------------------------------------
  SUBROUTINE Init(this, capacity, status)
    CLASS(MD_Part_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: capacity
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    this%desc%n_parts = 0
    DO i = 1, MD_PART_MAX
      this%desc%parts(i)%id         = 0
      this%desc%parts(i)%name       = ""
      this%desc%parts(i)%section_id = 0
      this%desc%parts(i)%valid      = .FALSE.
    END DO

    this%state%sections_assigned = .FALSE.
    this%state%materials_bound   = .FALSE.
    this%state%validated         = .FALSE.
    this%state%n_unassigned      = 0
    this%n_parts     = 0
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  !---------------------------------------------------------------------------
  ! SUBROUTINE: Finalize (TBP for MD_Part_Domain)
  ! PHASE:      P0
  ! PURPOSE:    Tear down domain container — reset counts and flags
  !---------------------------------------------------------------------------
  SUBROUTINE Finalize(this)
    CLASS(MD_Part_Domain), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN
    this%desc%n_parts    = 0
    this%n_parts         = 0
    this%state%validated = .FALSE.
    this%initialized     = .FALSE.
  END SUBROUTINE Finalize

  !---------------------------------------------------------------------------
  ! SUBROUTINE: GetSummary (TBP for MD_Part_Domain)
  ! PHASE:      P0
  ! PURPOSE:    Build human-readable summary string for diagnostics
  !---------------------------------------------------------------------------
  SUBROUTINE GetSummary(this, summary, status)
    CLASS(MD_Part_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      summary = "Part domain: not initialized"
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    WRITE(summary, '(A,I0,A,L1)') &
      "Part domain: n_parts=", this%desc%n_parts, &
      ", validated=", this%state%validated
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetSummary

END MODULE MD_Part_Def
