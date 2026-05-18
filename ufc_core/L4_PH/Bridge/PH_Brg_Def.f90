!===============================================================================
! MODULE: PH_Brg_Def
! LAYER:  L4_PH
! DOMAIN: Bridge
! ROLE:   Def
! BRIEF:  Bridge four-type definitions (Desc/State/Algo/Ctx)
!
! Four-Type Mapping (CONTRACT §3.3):
!   Desc  -> N (no standalone; Populate writes to domain slots)
!   State -> Y (PH_Brg_State: runtime statistics, not truth source)
!   Algo  -> Y (PH_Brg_Params: config parameters, not truth source)
!   Ctx   -> Y (PH_Brg_Ctx: cross-layer snapshot, non-hot-path)
!
! Contract: Bridge/CONTRACT.md §3
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE PH_Brg_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Desc类型: Bridge 不持有独立 Desc TYPE (CONTRACT §3.3)
  ! 经 Populate 后视图写入各域 slot，此处仅保留 L3→L4 桥接描述符
  !---------------------------------------------------------------------------

  !> @brief 单元状态更新描述符 (from PH_Brg_L3)
  TYPE, PUBLIC :: PH_Brg_ElemStateUpdate_Desc
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp), ALLOCATABLE :: stress(:,:)  ! (ncomp, nip)
    REAL(wp), ALLOCATABLE :: strain(:,:)  ! (ncomp, nip)
  END TYPE PH_Brg_ElemStateUpdate_Desc

  !> @brief 材料ID描述符 (from PH_Brg_L3)
  TYPE, PUBLIC :: PH_Brg_MatId_Desc
    INTEGER(i4) :: mat_id = 0_i4
  END TYPE PH_Brg_MatId_Desc

  !> @brief 单元ID描述符 (from PH_Brg_L2)
  TYPE, PUBLIC :: PH_Brg_ElemId_Desc
    INTEGER(i4) :: elem_id = 0_i4
    INTEGER(i4) :: elem_type = 0_i4
  END TYPE PH_Brg_ElemId_Desc

  !> @brief WriteBack描述符 (from WriteBack/PH_WB_Mgr)
  TYPE, PUBLIC :: PH_Brg_WriteBack_Desc
    INTEGER(i4) :: wb_id = 0_i4
    CHARACTER(LEN=64) :: target_label = ''
    LOGICAL :: active = .TRUE.
  END TYPE PH_Brg_WriteBack_Desc

  !---------------------------------------------------------------------------
  ! State类型: 运行时统计，不作为真相源
  !---------------------------------------------------------------------------

  !> @brief Bridge域运行时状态
  !! totalCalls, failedCalls, lastErrorCode, totalBridgeTime, gpuTransferTime
  TYPE, PUBLIC :: PH_Brg_State
    INTEGER(i4) :: totalCalls     = 0_i4   ! 累计调用次数
    INTEGER(i4) :: failedCalls    = 0_i4   ! 失败调用次数
    INTEGER(i4) :: lastErrorCode  = 0_i4   ! 最近错误码
    REAL(wp)    :: totalBridgeTime  = 0.0_wp  ! 累计桥接耗时 [s]
    REAL(wp)    :: gpuTransferTime  = 0.0_wp  ! GPU传输耗时 [s]
  END TYPE PH_Brg_State

  !> @brief WriteBack状态 (from WriteBack/PH_WB_Mgr)
  TYPE, PUBLIC :: PH_Brg_WriteBack_State
    INTEGER(i4) :: total_writes = 0_i4
    INTEGER(i4) :: failed_writes = 0_i4
    LOGICAL     :: last_write_ok = .TRUE.
  END TYPE PH_Brg_WriteBack_State

  !> @brief Output状态 (from Output/PH_Out_Mgr)
  TYPE, PUBLIC :: PH_Brg_Output_State
    INTEGER(i4) :: total_outputs = 0_i4
    INTEGER(i4) :: last_output_step = 0_i4
    LOGICAL     :: output_active = .FALSE.
  END TYPE PH_Brg_Output_State

  !---------------------------------------------------------------------------
  ! Algo类型: 配置参数，不作为真相源
  !---------------------------------------------------------------------------

  !> @brief Bridge域算法配置
  !! enableUEL, enableUMAT, enableGPU, enableExternal, gpuDeviceId, gpuAsyncTransfer
  TYPE, PUBLIC :: PH_Brg_Params
    LOGICAL     :: enableUEL      = .FALSE.  ! 启用UEL桥接
    LOGICAL     :: enableUMAT     = .FALSE.  ! 启用UMAT桥接
    LOGICAL     :: enableGPU      = .FALSE.  ! 启用GPU加速
    LOGICAL     :: enableExternal = .FALSE.  ! 启用外部库桥接
    INTEGER(i4) :: gpuDeviceId    = 0_i4     ! GPU设备ID
    LOGICAL     :: gpuAsyncTransfer = .FALSE. ! GPU异步传输
  END TYPE PH_Brg_Params

  !---------------------------------------------------------------------------
  ! Ctx类型: 跨层上下文快照，非热路径
  !---------------------------------------------------------------------------

  !---------------------------------------------------------------------------
  ! TYPE: PH_Brg_Inc_Evo_Ctx
  ! PHASE: Increment | VERB: Evolve
  ! KIND:  Ctx (auxiliary)
  ! DESC:  Increment-phase evolution context - step/increment tracking.
  !        Mirrors PH_Mat_Inc_Evo_Ctx pattern.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Brg_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Brg_Inc_Evo_Ctx

  !> @brief Bridge域跨层上下文
  !! step_idx, incr_idx, nRegisteredLibs, libTypes, libActive, nUEL, nUMAT
  TYPE, PUBLIC :: PH_Brg_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Brg_Inc_Evo_Ctx) :: inc   ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: step_idx        = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4) :: incr_idx        = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4) :: nRegisteredLibs = 0_i4   ! 已注册外部库数
    INTEGER(i4) :: nUEL            = 0_i4   ! UEL元素数
    INTEGER(i4) :: nUMAT           = 0_i4   ! UMAT材料数
  END TYPE PH_Brg_Ctx

END MODULE PH_Brg_Def
