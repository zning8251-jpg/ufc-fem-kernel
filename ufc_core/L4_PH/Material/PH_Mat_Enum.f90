!===============================================================================
! MODULE: PH_Mat_Enum
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Def — 11-family slot markers (PH_MAT_*) for Populate / L5 routing
! BRIEF:  Numeric SSOT aligned with governance tests (PH_MAT_ELASTIC=1 …).
!         Distinct from discrete model IDs MAT_* in MD_Mat_Ids / PH_Mat_Reg.
!===============================================================================
MODULE PH_Mat_Enum
  USE IF_Prec_Core, ONLY: i4
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_UNKNOWN         = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELASTIC         = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELASTO_PLASTIC  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_HYPERELASTIC   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_VISCOELASTIC  = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CREEP          = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_DAMAGE         = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_GEOTECH        = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_COMPOSITE      = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_THERMAL        = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ACOUSTIC       = 10_i4
  ! User-defined implicit (99); canonical name PH_MAT_USER ("UMAT" redundant with "USER")
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_USER            = 99_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_USER_UMAT     = PH_MAT_USER
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_USER_VUMAT     = 100_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_MAX_POOL       = 1024_i4

END MODULE PH_Mat_Enum
