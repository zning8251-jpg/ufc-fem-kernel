!===============================================================================
! MODULE:   MD_Amp_Idx
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Amplitude（域缩 **Amp**）
! ROLE:     _Idx — 全局索引 API（`g_ufc_global` → 域 TBP / SIO）
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：门面模块，**不**在本 MODULE 内再声明四型）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + *_Arg + 主/辅 / 嵌套·并列·主从）
!       — **本文件**：无新增 `TYPE`；四型与 SIO **主从**关系为
!           **AUTHORITY**：`MD_Amp_Domain`（`MD_Amp_Def`）内 **Desc / State / Algo**
!           **Ctx**：未在本域单列 TYPE；运行时上下文由 **`g_ufc_global%md_layer`**
!           与可选 **`step_idx` / `incr_idx`** 承担（与 L5 WriteBack 数据链对齐）。
!       — **SIO（Args）**：**`MD_Amp_Get_Arg`**（Get 路径）、**`MD_Amp_EvalAtTime_Arg`**
!           由 **`MD_Amp_Def`** 定义；本模块过程参数为 **标量 + `status`** 或
!           **`MD_Amp_Get_Arg`**，属 **Harness 友好** 薄封装，**不**嵌套四型入参。
!       — **命名模板（跨层参考）**：
!           `MD_ | PH_ | RT_<域缩>_<Role>_Desc | State | Algo | Ctx`
!           本柱域缩 **Amp**；`_Idx` 仅作 **角色后缀**（索引门面），**不等于** FourKind。
!
!   [2] 过程算法（三维度）
!       — **时间维**：**`MD_Amp_EvalAtTime_Idx`** — 以标量 **`time`** 查询 **A(t)**；
!           可选在 **`IF_STATUS_OK`** 后调用 **`dom%WriteBack`**，携带 **`step_idx` /
!           `incr_idx`** 供步/增量追溯。
!       — **空间维**：幅值为 **全局标量因子**，无单元/高斯点；与载荷域网格积分
!           **正交**（索引 API 不引入空间离散）。
!       — **动作维**：**`MD_Amp_GetAmplitude_Idx`** — **读** 描述经 **`MD_Amp_Apply_Get_Arg`**
!           委托域 TBP；**`MD_Amp_EvalAtTime_Idx`** — **算** + 条件 **写回**（与
!           **Amplitude/CONTRACT.md** 对 Idx 路径约定一致：**EvalAtTime** 与 **WriteBack**
!           显式分相）。
!
! **依赖**：`MD_Amp_Def`（`*_Arg` / Apply）、`UFC_GlobalContainer_Core`（`g_ufc_global`）。
! **数据路径**：`g_ufc_global%md_layer%amplitude` → **`CLASS(MD_Amp_Domain)`**。
!===============================================================================

MODULE MD_Amp_Idx
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Amp_Def, ONLY: MD_Amp_Get_Arg, MD_Amp_Apply_Get_Arg
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Amp_GetAmplitude_Idx
  PUBLIC :: MD_Amp_EvalAtTime_Idx

CONTAINS

  !===========================================================================
  ! MD_Amp_GetAmplitude_Idx — 按索引 **读** 单条幅值（Query / 动作维）
  !   时间维：无（静态 Desc 快照）；空间维：无；动作维：Get → **`MD_Amp_Apply_Get_Arg`**
  !===========================================================================
  SUBROUTINE MD_Amp_GetAmplitude_Idx(amp_idx, arg, status)
    INTEGER(i4),              INTENT(IN)    :: amp_idx
    TYPE(MD_Amp_Get_Arg),     INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL MD_Amp_Apply_Get_Arg(g_ufc_global%md_layer%amplitude, amp_idx, arg)
    status = arg%status
  END SUBROUTINE MD_Amp_GetAmplitude_Idx

  !===========================================================================
  ! MD_Amp_EvalAtTime_Idx — 按索引 **算** A(t)（时间维）；可选 **写回**（动作维）
  !   [Data chain] `step_idx` / `incr_idx` → **`dom%WriteBack`** → L5 追溯
  !===========================================================================
  SUBROUTINE MD_Amp_EvalAtTime_Idx(amp_idx, time, value, status, step_idx, incr_idx)
    INTEGER(i4),              INTENT(IN)    :: amp_idx
    REAL(wp),                 INTENT(IN)    :: time
    REAL(wp),                 INTENT(OUT)   :: value
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status
    INTEGER(i4),              INTENT(IN), OPTIONAL :: step_idx, incr_idx
    TYPE(ErrorStatusType) :: wb_status

    ASSOCIATE (dom => g_ufc_global%md_layer%amplitude)
      CALL dom%EvalAtTime(amp_idx, time, value, status)
      IF (status%status_code == IF_STATUS_OK) THEN
        IF (PRESENT(step_idx) .AND. PRESENT(incr_idx)) THEN
          CALL dom%WriteBack(amp_idx, value, time, 1_i4, step_idx=step_idx, incr_idx=incr_idx, &
              status=wb_status)
        ELSE IF (PRESENT(step_idx)) THEN
          CALL dom%WriteBack(amp_idx, value, time, 1_i4, step_idx=step_idx, status=wb_status)
        ELSE IF (PRESENT(incr_idx)) THEN
          CALL dom%WriteBack(amp_idx, value, time, 1_i4, incr_idx=incr_idx, status=wb_status)
        END IF
      END IF
    END ASSOCIATE
  END SUBROUTINE MD_Amp_EvalAtTime_Idx

END MODULE MD_Amp_Idx
