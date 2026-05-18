!===============================================================================
! MODULE: MD_Mat_Eval_Types
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Shared Types
! BRIEF:  Shared evaluation context and algorithm types for material dispatch.
!         Extracted from PH_MatPLMEval to break L3_MD -> L4_PH dependency cycle.
!===============================================================================
MODULE MD_Mat_Eval_Types
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MatEval_Ctx
  PUBLIC :: MatAlgo_Algo
  PUBLIC :: MAT_ALGO_DEFAULT
  PUBLIC :: MD_MATCTX_MAX_STATEV

  INTEGER(i4), PARAMETER :: MD_MATCTX_MAX_STATEV = 50_i4

  TYPE :: MatEval_Cfg
    INTEGER(i4) :: ndim = 0
  END TYPE MatEval_Cfg

  TYPE :: MatEval_Ctx
    INTEGER(i4) :: ndi = 0, nshr = 0, ntens = 0, nstatv = 0
    TYPE(MatEval_Cfg) :: cfg
    REAL(wp) :: stress(6) = 0.0_wp
    REAL(wp) :: stran(6) = 0.0_wp
    REAL(wp) :: dstran(6) = 0.0_wp
    REAL(wp) :: statev(MD_MATCTX_MAX_STATEV) = 0.0_wp
    REAL(wp) :: ddsdde(6,6) = 0.0_wp
    REAL(wp) :: sse = 0.0_wp
    REAL(wp) :: spd = 0.0_wp
    REAL(wp) :: scd = 0.0_wp
    REAL(wp) :: rpl = 0.0_wp
    REAL(wp) :: drpldt = 0.0_wp
    REAL(wp) :: time(2) = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE MatEval_Ctx

  TYPE :: MatAlgo_Algo
    INTEGER(i4) :: kstep = 0, kinc = 0
  END TYPE MatAlgo_Algo

  TYPE(MatAlgo_Algo), PARAMETER :: MAT_ALGO_DEFAULT = MatAlgo_Algo(kstep=0, kinc=0)

END MODULE MD_Mat_Eval_Types
