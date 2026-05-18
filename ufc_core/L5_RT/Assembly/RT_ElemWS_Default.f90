!===============================================================================
! MODULE: RT_ElemWS_Default
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Util (workspace)
! BRIEF:  Default element workspace allocators -- StructWS / MultiFieldWS
!===============================================================================
MODULE RT_ElemWS_Default
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Default_StructWS
  PUBLIC :: RT_Default_MultiFieldWS

CONTAINS

  SUBROUTINE RT_Default_StructWS(nDOF, Ke, Re, Me, Ce, B)
    INTEGER(i4), INTENT(IN) :: nDOF
    REAL(wp), POINTER, INTENT(OUT) :: Ke(:,:), Re(:)
    REAL(wp), POINTER, INTENT(OUT) :: Me(:,:), Ce(:,:)
    REAL(wp), POINTER, INTENT(OUT) :: B(:,:)

    ALLOCATE(Ke(nDOF, nDOF))
    ALLOCATE(Re(nDOF))
    ALLOCATE(Me(nDOF, nDOF))
    ALLOCATE(Ce(nDOF, nDOF))
    ALLOCATE(B(6, nDOF))

    Ke = 0.0_wp
    Re = 0.0_wp
    Me = 0.0_wp
    Ce = 0.0_wp
    B  = 0.0_wp

  END SUBROUTINE RT_Default_StructWS

  SUBROUTINE RT_Default_MultiFieldWS(nDOF, Ke, Re, Me, Ce)
    INTEGER(i4), INTENT(IN) :: nDOF
    REAL(wp), POINTER, INTENT(OUT) :: Ke(:,:), Re(:)
    REAL(wp), POINTER, INTENT(OUT) :: Me(:,:), Ce(:,:)

    ALLOCATE(Ke(nDOF, nDOF))
    ALLOCATE(Re(nDOF))
    ALLOCATE(Me(nDOF, nDOF))
    ALLOCATE(Ce(nDOF, nDOF))

    Ke = 0.0_wp
    Re = 0.0_wp
    Me = 0.0_wp
    Ce = 0.0_wp

  END SUBROUTINE RT_Default_MultiFieldWS

END MODULE RT_ElemWS_Default
