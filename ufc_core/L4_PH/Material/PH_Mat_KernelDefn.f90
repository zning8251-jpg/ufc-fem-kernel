!===============================================================================
! MODULE: PH_Mat_KernelDefn
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Def — material kernel abstract type + update arg
! BRIEF:  Minimal registry-facing interface for PH_Mat_Core S3/S4 pipeline.
!===============================================================================
MODULE PH_Mat_KernelDefn
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_MAX_NTENS = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_STRESS_STATE_3D = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_STRESS_STATE_CPS = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_STRESS_STATE_CPE = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_STRESS_STATE_CAX = 4_i4

  TYPE, PUBLIC :: PH_Mat_Update_Arg
    INTEGER(i4) :: ntens = 6_i4
    INTEGER(i4) :: mat_model_id = 0_i4
    REAL(wp)    :: dt    = 0.0_wp
    REAL(wp)    :: strain_n(6)  = 0.0_wp
    REAL(wp)    :: dstrain(6)   = 0.0_wp
    REAL(wp)    :: stress_new(6) = 0.0_wp
    REAL(wp)    :: D_tang(6, 6) = 0.0_wp
    REAL(wp), POINTER :: props(:)   => NULL()
    REAL(wp), POINTER :: sdv_n(:)   => NULL()
    REAL(wp), ALLOCATABLE :: sdv_tr(:)
  END TYPE PH_Mat_Update_Arg

  TYPE, ABSTRACT, PUBLIC :: PH_Mat_KernelBase
    INTEGER(i4) :: n_sdv = 0_i4
  CONTAINS
    PROCEDURE(PH_Mat_UpdateStress_Ifc), DEFERRED :: UpdateStress
    PROCEDURE(PH_Mat_ComputeCTM_Ifc), DEFERRED :: ComputeCTM
    PROCEDURE(PH_Mat_InitSDV_Ifc), DEFERRED :: InitSDV
  END TYPE PH_Mat_KernelBase

  ABSTRACT INTERFACE
    SUBROUTINE PH_Mat_UpdateStress_Ifc(this, uarg, istat)
      IMPORT :: PH_Mat_KernelBase, PH_Mat_Update_Arg, i4
      CLASS(PH_Mat_KernelBase),  INTENT(INOUT) :: this
      TYPE(PH_Mat_Update_Arg),   INTENT(INOUT) :: uarg
      INTEGER(i4),               INTENT(OUT)   :: istat
    END SUBROUTINE PH_Mat_UpdateStress_Ifc
    SUBROUTINE PH_Mat_ComputeCTM_Ifc(this, uarg, istat)
      IMPORT :: PH_Mat_KernelBase, PH_Mat_Update_Arg, i4
      CLASS(PH_Mat_KernelBase),  INTENT(INOUT) :: this
      TYPE(PH_Mat_Update_Arg),   INTENT(INOUT) :: uarg
      INTEGER(i4),               INTENT(OUT)   :: istat
    END SUBROUTINE PH_Mat_ComputeCTM_Ifc
    SUBROUTINE PH_Mat_InitSDV_Ifc(this, sdv, nsdv, istat)
      IMPORT :: PH_Mat_KernelBase, wp, i4
      CLASS(PH_Mat_KernelBase), INTENT(INOUT) :: this
      REAL(wp),                 INTENT(INOUT) :: sdv(:)
      INTEGER(i4),              INTENT(IN)    :: nsdv
      INTEGER(i4),              INTENT(OUT)   :: istat
    END SUBROUTINE PH_Mat_InitSDV_Ifc
  END INTERFACE

END MODULE PH_Mat_KernelDefn
