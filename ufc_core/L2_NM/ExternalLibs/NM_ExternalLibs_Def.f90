! LEGACY: External third-party library - exempt from UFC naming/style conventions
!===============================================================================
! Module:  NM_ExternalLibs_Def
! Layer:   L2_NM - Numerical Methods Layer
! Domain:  ExternalLibs
! Purpose: Descriptor for external library availability (BLAS/LAPACK).
!
! Type catalogue (1 TYPE):
!   NM_ExtLibs_Desc — Flags indicating BLAS/LAPACK availability
!
! Status: FOUR-TYPE | Last verified: 2026-04-25
!===============================================================================
MODULE NM_ExternalLibs_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: NM_ExtLibs_Desc

  TYPE :: NM_ExtLibs_Desc
    LOGICAL :: blas_available   = .TRUE.
    LOGICAL :: lapack_available = .TRUE.
  END TYPE NM_ExtLibs_Desc

END MODULE NM_ExternalLibs_Def
