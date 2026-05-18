! FK_IF_Base_Desc.f90
! L1_Infra — Base Descriptor pattern (template)
!
! Architectural pattern:
!   - Desc types are IMMUTABLE after construction
!   - They carry configuration/parameters (never runtime state)
!   - Each domain at each layer defines its own Desc TYPE
!   - Desc is one of the Four Pillar Types: Desc, State, Algo, Ctx

MODULE FK_IF_Base_Desc
  USE FK_IF_Base_DP, ONLY: I4, WP

  IMPLICIT NONE
  PRIVATE

  !══════════════════════════════════════════════════════
  ! PUBLIC TYPES
  !══════════════════════════════════════════════════════
  PUBLIC :: FK_IF_Base_Desc_Type

  !══════════════════════════════════════════════════════
  ! TYPE: Base Descriptor (immutable configuration)
  !══════════════════════════════════════════════════════
  TYPE :: FK_IF_Base_Desc_Type
    ! Identification
    CHARACTER(len=64) :: name = ''

    ! Precision configuration (set once, never changed)
    INTEGER(I4) :: wp_kind = WP

    ! Debug/verbose flags
    LOGICAL :: verbose = .FALSE.
  END TYPE FK_IF_Base_Desc_Type

END MODULE FK_IF_Base_Desc
