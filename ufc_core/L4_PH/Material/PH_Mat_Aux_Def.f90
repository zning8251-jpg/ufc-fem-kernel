! F2003
MODULE PH_Mat_Aux_Def

  USE IF_Prec, ONLY: i4, wp
  USE PH_Mat_Enum, ONLY: PH_MAT_UNKNOWN
  IMPLICIT NONE

  PRIVATE
  PUBLIC :: PH_Mat_Cfg_Init_Desc
  PUBLIC :: PH_Mat_Pop_Vld_Desc
  PUBLIC :: PH_Mat_Inc_Evo_Ctx
  PUBLIC :: PH_Mat_Lcl_Comp_Ctx
  PUBLIC :: PH_Mat_Lcl_Comp_State
  PUBLIC :: PH_Mat_Lcl_Evo_State
  PUBLIC :: PH_Mat_Stp_Ctl_Algo
  PUBLIC :: PH_Mat_Lcl_Comp_ArgIn
  PUBLIC :: PH_Mat_Lcl_Comp_ArgOut
  PUBLIC :: PH_Mat_Krnl_Ctx
  PUBLIC :: PH_Mat_Krnl_Algo
  PUBLIC :: PH_Mat_Slot_PhaseIdx

  ! ---- PH_Mat_Desc 辅TYPE ----
  ! [Phase:Cfg|Verb:Init]
  TYPE, PUBLIC :: PH_Mat_Cfg_Init_Desc
    INTEGER(i4) :: matId    = 0_i4            ! 全局材料ID
    INTEGER(i4) :: matModel = PH_MAT_UNKNOWN  ! 族enum
  END TYPE PH_Mat_Cfg_Init_Desc

  ! [Phase:Pop|Verb:Vld]
  TYPE, PUBLIC :: PH_Mat_Pop_Vld_Desc
    INTEGER(i4) :: mat_model_id = 0_i4        ! 离散模型ID (101..1102)
  END TYPE PH_Mat_Pop_Vld_Desc

  ! ---- PH_Mat_Ctx 辅TYPE ----
  ! [Phase:Inc|Verb:Evo]
  TYPE, PUBLIC :: PH_Mat_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4   ! 当前步
    INTEGER(i4) :: incr_idx = 0_i4   ! 当前增量
    REAL(wp)    :: dt       = 0.0_wp ! 时间增量
  END TYPE PH_Mat_Inc_Evo_Ctx

  ! [Phase:Lcl|Verb:Comp]
  TYPE, PUBLIC :: PH_Mat_Lcl_Comp_Ctx
    REAL(wp) :: temperature = 0.0_wp  ! 温度 [K]
    REAL(wp) :: strain_rate = 0.0_wp  ! 等效应变速率 [1/s]
    REAL(wp) :: dstrain(6) = 0.0_wp    ! 应变增量 Voigt（Populate/Element 写入）
  END TYPE PH_Mat_Lcl_Comp_Ctx

  ! ---- PH_Mat_State 辅TYPE ----
  ! [Phase:Lcl|Verb:Comp]
  TYPE, PUBLIC :: PH_Mat_Lcl_Comp_State
    REAL(wp), ALLOCATABLE :: C_tan(:,:)   ! 算法切线 [ntens x ntens]
    REAL(wp), ALLOCATABLE :: stress(:)    ! 当前应力 (Voigt)
  END TYPE PH_Mat_Lcl_Comp_State

  ! [Phase:Lcl|Verb:Evo]
  TYPE, PUBLIC :: PH_Mat_Lcl_Evo_State
    REAL(wp), ALLOCATABLE :: stateVars(:)    ! SDVs at n+1
    REAL(wp), ALLOCATABLE :: stateVars_n(:)  ! SDVs at n (converged)
  END TYPE PH_Mat_Lcl_Evo_State

  ! ---- PH_Mat_Algo 辅TYPE ----
  ! [Phase:Stp|Verb:Ctl]
  TYPE, PUBLIC :: PH_Mat_Stp_Ctl_Algo
    REAL(wp)    :: tol_yield    = 1.0e-6_wp ! 屈服容差
    REAL(wp)    :: tol_residual = 1.0e-8_wp ! NR残差容差
    INTEGER(i4) :: max_iter     = 20_i4     ! 最大局部NR迭代
    INTEGER(i4) :: integ_scheme = 1_i4      ! 1=BE, 2=MP
  END TYPE PH_Mat_Stp_Ctl_Algo

  ! ---- PH_Mat_Eval_Arg 按时相拆分 ----
  ! [Phase:Lcl|Verb:Comp] 输入
  TYPE, PUBLIC :: PH_Mat_Lcl_Comp_ArgIn
    INTEGER(i4) :: nprops  = 0_i4
    INTEGER(i4) :: ntens   = 6_i4
    INTEGER(i4) :: nsdv    = 0_i4
    REAL(wp), ALLOCATABLE :: strain(:)      ! 总应变
    REAL(wp), ALLOCATABLE :: d_strain(:)    ! 应变增量
  END TYPE PH_Mat_Lcl_Comp_ArgIn

  ! [Phase:Lcl|Verb:Comp] 输出
  TYPE, PUBLIC :: PH_Mat_Lcl_Comp_ArgOut
    REAL(wp), ALLOCATABLE :: stress_new(:)  ! 更新应力
    REAL(wp), ALLOCATABLE :: tangent(:,:)   ! 切线模量
  END TYPE PH_Mat_Lcl_Comp_ArgOut

  ! ---- PH_Mat_Krnl_Ctx (kernel callback context, formerly PH_Mat_Base_Ctx) ----
  TYPE, PUBLIC :: PH_Mat_Krnl_Ctx
    REAL(wp) :: dstran(6) = 0.0_wp
  END TYPE PH_Mat_Krnl_Ctx

  ! ---- PH_Mat_Krnl_Algo (kernel callback parameters, formerly PH_Mat_Base_Algo) ----
  TYPE, PUBLIC :: PH_Mat_Krnl_Algo
    INTEGER(i4) :: max_iter   = 100_i4
    REAL(wp)    :: tolerance  = 1.0e-8_wp
    REAL(wp)    :: abs_tol    = 1.0e-12_wp
    REAL(wp)    :: pnewdt_min = 0.1_wp
    REAL(wp)    :: pnewdt_max = 1.5_wp
    LOGICAL     :: auto_cut   = .TRUE.
    LOGICAL     :: line_search = .FALSE.
  END TYPE PH_Mat_Krnl_Algo

  ! ---- PH_Mat_Slot 相位标记（语义/诊断；无热路径 ALLOCATABLE）----
  TYPE, PUBLIC :: PH_Mat_Slot_PhaseIdx
    LOGICAL :: cfg_ready = .FALSE.
    LOGICAL :: pop_ready = .FALSE.
    LOGICAL :: stp_ready = .FALSE.
    LOGICAL :: lcl_ready = .FALSE.
  END TYPE PH_Mat_Slot_PhaseIdx

END MODULE PH_Mat_Aux_Def

