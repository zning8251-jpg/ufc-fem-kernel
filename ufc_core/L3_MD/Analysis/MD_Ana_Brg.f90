!===============================================================================
! MODULE:   MD_Ana_Brg
! LAYER:    L3_MD
! SUBDOMAIN Analysis（域缩 **Ana** / **聚合桥** — Step·Amp·Solv·Cpl 等子域编排入口）
! ROLE:      _Brg — **子域名注册表** + **`MD_Ana_Brg_InitCompat`** 冷入口（转发 **`MD_Ana_Comp_Init`**）
! BRIEF:    Harness / L6 侧 **Analysis 域** 级聚合：**Register / Lookup / Iterate / Finalize** 子域名字表
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**数据结构 · 轻量注册态 + Pop 名表** + **过程算法 · 冷路径编排**；
!   **(Solver×Coupling×Physics) 相容真源** 在 **`MD_Ana_Comp`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + Args + 主/辅 + 嵌套 · 并列 · 主从）
!
!       **TYPE 命名（层前缀 + 域缩 + 语义段）**
!       — 层前缀：**`MD_`**（L3_MD）| **`PH_`**（L4_PH）| **`RT_`**（L5_RT）。  
!       — **本柱域缩**：**`MD_Ana_*`** — **Ana** = **Analysis** 聚合半柱（**非** 单步 **Step** 四型柱）。  
!       — **`MD_Ana_Brg_Pop_Registry`**：**Pop** 语义 — **并列** 子域名字槽 **`names(:)`**（**`MAX_ANA_SUBDOMAINS`**）。  
!       — **`MD_Ana_Brg_Cfg_State`**：**Cfg/State 混合片段** — **`n_registered` / `initialized`**（**SAVE** 模块态
!         **`g_ana_st`** **主从** 于 **`g_ana_reg`**）。  
!       — **无** 独立 **`Desc/State/Algo/Ctx`** 四型柱；**无** **`*_Arg`** 包（过程以 **标量 + `ErrorStatusType`** 表达）。
!
!   [2] 过程算法（空间维 · 时间维 · 动作维）
!       — **时间维**：**`InitCompat` / `Finalize`** — **COLD**；**无** 步内时间推进。  
!       — **空间维**：**无** 网格 / DoF；子域名为 **逻辑分区标签** 非几何实体。  
!       — **动作维**：**`Register` / `Lookup` / `Iterate`** — **Init / Mutate / Query** 名字表；**`InitCompat`**
!         — **编排** 子域注册并调用 **`MD_Ana_Comp_Init`**。
!
! **依赖**：**`IF_Prec_Core`**, **`IF_Err_Brg`**, **`MD_Ana_Comp`**（**`MD_Ana_Comp_Init`** **ONLY** — 防 **Comp ⇄ Brg** 胖依赖）。
!
!===============================================================================
! Pilot: ufc-layer-l3-l4-l5-pilot.md — Analysis 聚合桥 (COLD)
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Analysis | Role:Brg | FuncSet:Register,Lookup | HotPath:No
!>>> UFC_L3_CONTRACT | Analysis/CONTRACT.md（若单列；否则见 Step/Solv/Cpl 合同卡）

MODULE MD_Ana_Brg
  USE IF_Prec_Core, ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
      IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Ana_Comp, ONLY: MD_Ana_Comp_Init
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Ana_Brg_InitCompat
  PUBLIC :: MD_Ana_Brg_Register
  PUBLIC :: MD_Ana_Brg_Lookup
  PUBLIC :: MD_Ana_Brg_Iterate
  PUBLIC :: MD_Ana_Brg_Finalize

  !---------------------------------------------------------------------------
  ! **SAVE 模块态**：**`g_ana_reg`**（Pop 名表）+ **`g_ana_st`**（注册计数 / 初始化旗标）
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MAX_ANA_SUBDOMAINS = 8_i4

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Ana_Brg_Pop_Registry
  ! KIND:   Desc（辅 · **Pop** 子域名字表 — **并列** 槽位）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Ana_Brg_Pop_Registry
    CHARACTER(LEN=32) :: names(MAX_ANA_SUBDOMAINS) = ""
  END TYPE MD_Ana_Brg_Pop_Registry

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Ana_Brg_Cfg_State
  ! KIND:   State（辅 · 注册 **元数据** — **主从** 于 **`g_ana_reg`**）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Ana_Brg_Cfg_State
    INTEGER(i4) :: n_registered = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  END TYPE MD_Ana_Brg_Cfg_State

  TYPE(MD_Ana_Brg_Pop_Registry), SAVE :: g_ana_reg
  TYPE(MD_Ana_Brg_Cfg_State),   SAVE :: g_ana_st

  PUBLIC :: MAX_ANA_SUBDOMAINS
  PUBLIC :: MD_Ana_Brg_Pop_Registry, MD_Ana_Brg_Cfg_State

CONTAINS

  !---------------------------------------------------------------------------
  ! **MD_Ana_Brg_InitCompat**
  ! **时间维 · COLD** | **动作维 · Init** — 转发 **`MD_Ana_Comp_Init`** + 预注册 **Step/Amplitude/Solver/Coupling**
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Ana_Brg_InitCompat(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    CALL MD_Ana_Comp_Init()
    ! Register known subdomains
    g_ana_st%n_registered = 0_i4
    CALL MD_Ana_Brg_Register("Step", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL MD_Ana_Brg_Register("Amplitude", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL MD_Ana_Brg_Register("Solver", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL MD_Ana_Brg_Register("Coupling", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    g_ana_st%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Ana_Brg_InitCompat

  !---------------------------------------------------------------------------
  ! **MD_Ana_Brg_Register**
  ! **时间维 · COLD** | **动作维 · Mutate** — 子域名字入 **`g_ana_reg`**（**`MAX_ANA_SUBDOMAINS`** 上限）
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Ana_Brg_Register(name, status)
    CHARACTER(LEN=*),     INTENT(IN)  :: name
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (g_ana_st%n_registered >= MAX_ANA_SUBDOMAINS) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[MD_Ana_Brg_Register]: max subdomains exceeded"
      RETURN
    END IF
    g_ana_st%n_registered = g_ana_st%n_registered + 1_i4
    g_ana_reg%names(g_ana_st%n_registered) = name
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Ana_Brg_Register

  !---------------------------------------------------------------------------
  ! **MD_Ana_Brg_Lookup**
  ! **空间维 · N/A** | **动作维 · Query** — 按名返 **1..n** 索引；未命中 **`idx=0`** + **`IF_STATUS_INVALID`**
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Ana_Brg_Lookup(name, idx, status)
    CHARACTER(LEN=*),     INTENT(IN)  :: name
    INTEGER(i4),          INTENT(OUT) :: idx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    idx = 0_i4
    DO i = 1, g_ana_st%n_registered
      IF (TRIM(g_ana_reg%names(i)) == TRIM(name)) THEN
        idx = i
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_INVALID
    status%message = "[MD_Ana_Brg_Lookup]: subdomain not found: " // TRIM(name)
  END SUBROUTINE MD_Ana_Brg_Lookup

  !---------------------------------------------------------------------------
  ! **MD_Ana_Brg_Iterate**
  ! **时间维 · COLD** | **动作维 · Query** — 导出已注册子域名前缀 **`names(1:n_count)`**
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Ana_Brg_Iterate(names, n_count, status)
    CHARACTER(LEN=32),    INTENT(OUT) :: names(:)
    INTEGER(i4),          INTENT(OUT) :: n_count
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, max_out

    CALL init_error_status(status)
    n_count = g_ana_st%n_registered
    max_out = MIN(SIZE(names), g_ana_st%n_registered)
    DO i = 1, max_out
      names(i) = g_ana_reg%names(i)
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Ana_Brg_Iterate

  !---------------------------------------------------------------------------
  ! **MD_Ana_Brg_Finalize**
  ! **时间维 · COLD** | **动作维 · Finalize** — 清空 **`g_ana_reg` / `g_ana_st`**
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Ana_Brg_Finalize(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    g_ana_st%n_registered = 0_i4
    g_ana_reg%names = ""
    g_ana_st%initialized = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Ana_Brg_Finalize

END MODULE MD_Ana_Brg
