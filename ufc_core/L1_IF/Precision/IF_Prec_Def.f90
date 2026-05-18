!===============================================================================
! MODULE: IF_Prec_Def
! LAYER:  L1_IF
! DOMAIN: Precision
! ROLE:   _Def
! BRIEF:  Desc TYPE for the Precision domain (four-type paradigm).
!===============================================================================
MODULE IF_Prec_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! TYPE: IF_Prec_Desc  [Desc]
  ! Immutable precision configuration descriptor.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Prec_Desc
    INTEGER(i4) :: wp_bytes  = 8       ! working precision bytes
    LOGICAL     :: is_double = .TRUE.
  END TYPE IF_Prec_Desc

  ! [LEGACY] backward compatibility alias
  TYPE, PUBLIC :: IF_Precision_Desc
    INTEGER(i4) :: wp_bytes  = 8
    LOGICAL     :: is_double = .TRUE.
  END TYPE IF_Precision_Desc

END MODULE IF_Prec_Def
