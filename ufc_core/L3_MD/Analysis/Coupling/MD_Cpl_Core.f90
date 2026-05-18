!===============================================================================
! MODULE:   MD_Cpl_Core
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Coupling（域缩 **Cpl**）
! ROLE:     _Core — **`MD_Cpl_Desc`** 编排 / 校验 / 查询（TYPE 真源 **`MD_Cpl_Def`**）
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**过程算法**；**数据结构**在 **`MD_Cpl_Def`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + Args + 主/辅 / 嵌套·并列·主从）—— **真源：`MD_Cpl_Def`**
!       以下与 **`MD_Cpl_Def`** 头 **[1]「数据结构」** **1:1 对表**（本 **`_Core`** 仅 **消费** TYPE；定义不回指 **`_Core`**）。
!
!       **A. 主四型（`MD_Cpl_*`）— 在 `MD_Cpl_Def` 中的嵌套 / 并列名 → 本 `_Core` 访问根**
!       — **Desc `MD_Cpl_Desc`**：`n_pairs` + **`pairs(1:MD_COUP_MAX_PAIRS)`**（元素 **`TYPE(MD_Coup_PairDef)`**，
!         **并列**）+ **`ctl`**（**`TYPE(MD_Cpl_Stp_Ctl_Desc)`**，**嵌套**）。**`Init` / `Finalize` / `AddPair` /
!         `Validate` / `GetConfig` / `GetPair` / `GetSummary`** 主路径读写 **`desc%...`**。
!       — **State `MD_Cpl_State`**：**`inc`** → **`MD_Cpl_Inc_Evo_State`**；**`stp`** → **`MD_Cpl_Stp_Ctl_State`**
!         （均 **嵌套**）。本 **`_Core`** **不** 改 **`MD_Cpl_State`**（Populate / RT 消费）。
!       — **Algo `MD_Cpl_Algo`**：**`stp`** → **`MD_Cpl_Stp_Ctl_Algo`**（**嵌套**）。本 **`_Core`** **不** 改 **`MD_Cpl_Algo`**。
!       — **Ctx `MD_Cpl_Ctx`**：**`brg`** → **`MD_Cpl_Pop_Brg_Ctx`**（**嵌套**）。本 **`_Core`** **不** 改 **`MD_Cpl_Ctx`**。
!
!       **B. 辅 TYPE / 子语义段（`MD_Coup_*` 与 `MD_Cpl_*` 嵌套段）**
!       — **`MD_Coup_PairDef`**：单通道辅 **Desc**；经 **`MD_Cpl_Desc%pairs(i)`** 由 **`AddPair` / `Validate` /
!         `GetPair`** 使用（字段含 **`src_field_id` / `dst_field_id` / `interface_surf_id`** 等）。
!       — **`MD_Cpl_Stp_Ctl_Desc`**：仅经 **`MD_Cpl_Desc%ctl`**；**`Init` / `Finalize` / `GetConfig` / `GetSummary` /
!         `Validate`** 触碰 **`strategy` / `is_configured` / 容差与迭代上限** 等。
!
!       **C. `MD_COUP_*` PARAMETER（字段 ID / 策略 / `MAX_PAIRS`）**
!       — **定义** 在 **`MD_Cpl_Def`**；本 **`_Core`** **USE** 消费（并与 L5 **`RT_MF_*`** 常量 **镜像对表**）。
!       — **命名辨析**：**`Coup`** = **cou**pling **p**air（**辅对**通道），**不是**英文 *Coupling* 一词的简单
!         **全大写缩写 CPL**；**`MD_COUP_*`** 与柱 **`MD_Cpl_*`** **刻意不同拼写**，避免 Fortran **大小写不敏感**
!         下把常量前缀 **`MD_CPL_...`** 与类型前缀 **`MD_Cpl_...`** **误判为同一 `CPL` 前缀 family**。**不建议**用 **`CPL`**
!         **整体替换** **`COUP`/`Coup`**（除非立项做 **L3↔L5↔文档** 全仓库重命名与追溯表）。
!
!       **D. Args（+1）**
!       — 各 **`MD_Cpl_*_Proc`**：**显式** **`desc` / `pair` / 标量 OUT + `ErrorStatusType`（`status`）**；**无**
!         本域嵌套 **`*_Arg`** 四型包（合同 / Principle #14）。
!
!       **E. TYPE 口诀（全柱一致）**
!       — **`MD_ | PH_ | RT_<域缩>_<语义段>_(Desc|State|Algo|Ctx)`**；本柱域缩 **Cpl**；辅对 **`MD_Coup_*`** 见 **B**。
!
!   [2] 过程算法（三维度）
!       — **时间维**：**`MD_Cpl_*_Proc`** 均为建模期 **COLD_PATH**（无步内时间推进）；**`Validate`**
!           置 **`ctl%is_configured`** 与步序语义衔接见合同。
!       — **空间维**：**`MD_Coup_PairDef%interface_surf_id`** 等字段在本模块 **仅一致性占位**，
!           **无** 网格积分 / 面几何计算（归载荷·网格域）。
!       — **动作维**：**`MD_Cpl_Init_Proc` / `MD_Cpl_Finalize_Proc`**（重置）；**`MD_Cpl_AddPair_Proc`**（**Mutate**）；
!           **`MD_Cpl_Validate_Proc`**（**Validate**）；**`MD_Cpl_GetConfig_Proc` / `MD_Cpl_GetPair_Proc` / `MD_Cpl_GetSummary_Proc`**（**Query**）。
!
!   **过程命名**：**`MD_Cpl_<Verb>_Proc`** — 与 **`MD_Cpl_*`** TYPE **同柱前缀**（域缩 **Cpl**）。
!   **`USE MD_Cpl_Core, ONLY: MD_Cpl_Init_Proc, …`**（按需列举）。
!
! **依赖**：**`MD_Cpl_Def`**（**`MD_Cpl_Desc`**、**`MD_Coup_PairDef`**、常量）；**`IF_Prec_Core`**、**`IF_Err_Brg`**。
! **非依赖**：**不** `USE` L4_PH / L5_RT / **`g_ufc_global`**。
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Coupling | Role:Core | FuncSet:Init,Finalize,Mutate,Validate,Get
!>>> UFC_L3_CONTRACT | Analysis/Coupling/CONTRACT.md

MODULE MD_Cpl_Core
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
        IF_STATUS_OK, IF_STATUS_INVALID
    USE MD_Cpl_Def, ONLY: MD_Cpl_Desc, MD_Coup_PairDef, &
        MD_COUP_MAX_PAIRS, MD_COUP_STRAT_STAG
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: MD_Cpl_Init_Proc
    PUBLIC :: MD_Cpl_Finalize_Proc
    PUBLIC :: MD_Cpl_AddPair_Proc
    PUBLIC :: MD_Cpl_Validate_Proc
    PUBLIC :: MD_Cpl_GetConfig_Proc
    PUBLIC :: MD_Cpl_GetPair_Proc
    PUBLIC :: MD_Cpl_GetSummary_Proc

CONTAINS

    !===========================================================================
    ! [P] `CONTAINS` — **`MD_Cpl_*_Proc`**（**Init** / **Finalize** / **AddPair** / **Validate** / **Get***）
    !===========================================================================

    !===========================================================================
    ! **`MD_Cpl_Init_Proc`** — 重置 **`MD_Cpl_Desc`** 为建模空态（动作维 · COLD_PATH）
    !===========================================================================
    SUBROUTINE MD_Cpl_Init_Proc(desc, status)
        TYPE(MD_Cpl_Desc), INTENT(INOUT) :: desc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: ip

        CALL init_error_status(status)

        desc%n_pairs = 0_i4
        desc%ctl%strategy = MD_COUP_STRAT_STAG
        desc%ctl%interp_method = 0_i4
        desc%ctl%max_coupling_iter = 10_i4
        desc%ctl%coupling_tol = 1.0E-4_wp
        desc%ctl%is_configured = .FALSE.

        DO ip = 1, MD_COUP_MAX_PAIRS
            desc%pairs(ip)%pair_id = 0_i4
            desc%pairs(ip)%src_field_id = 0_i4
            desc%pairs(ip)%dst_field_id = 0_i4
            desc%pairs(ip)%qty_type = 0_i4
            desc%pairs(ip)%interface_surf_id = 0_i4
            desc%pairs(ip)%scale_factor = 1.0_wp
            desc%pairs(ip)%is_active = .TRUE.
            desc%pairs(ip)%label = ''
            desc%pairs(ip)%keyword_source = ''
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Cpl_Init_Proc

    !===========================================================================
    ! **`MD_Cpl_Finalize_Proc`** — 释放 / 清空描述符负载（动作维 · Teardown）
    !===========================================================================
    SUBROUTINE MD_Cpl_Finalize_Proc(desc, status)
        TYPE(MD_Cpl_Desc), INTENT(INOUT) :: desc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: ip

        CALL init_error_status(status)

        desc%n_pairs = 0_i4
        desc%ctl%strategy = MD_COUP_STRAT_STAG
        desc%ctl%interp_method = 0_i4
        desc%ctl%max_coupling_iter = 10_i4
        desc%ctl%coupling_tol = 1.0E-4_wp
        desc%ctl%is_configured = .FALSE.

        DO ip = 1, MD_COUP_MAX_PAIRS
            desc%pairs(ip)%pair_id = 0_i4
            desc%pairs(ip)%src_field_id = 0_i4
            desc%pairs(ip)%dst_field_id = 0_i4
            desc%pairs(ip)%qty_type = 0_i4
            desc%pairs(ip)%interface_surf_id = 0_i4
            desc%pairs(ip)%scale_factor = 1.0_wp
            desc%pairs(ip)%is_active = .TRUE.
            desc%pairs(ip)%label = ''
            desc%pairs(ip)%keyword_source = ''
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Cpl_Finalize_Proc

    !===========================================================================
    ! **`MD_Cpl_AddPair_Proc`** — 注册新耦合通道（动作维 · **Mutate**）
    !===========================================================================
    SUBROUTINE MD_Cpl_AddPair_Proc(desc, pair, status)
        TYPE(MD_Cpl_Desc), INTENT(INOUT) :: desc
        TYPE(MD_Coup_PairDef), INTENT(IN) :: pair
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (desc%n_pairs >= MD_COUP_MAX_PAIRS) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Cpl_AddPair_Proc: max pairs exceeded"
            RETURN
        END IF

        IF (pair%src_field_id <= 0_i4 .OR. pair%dst_field_id <= 0_i4) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Cpl_AddPair_Proc: invalid field IDs"
            RETURN
        END IF

        IF (pair%src_field_id == pair%dst_field_id) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Cpl_AddPair_Proc: self-coupling not allowed"
            RETURN
        END IF

        desc%n_pairs = desc%n_pairs + 1_i4
        desc%pairs(desc%n_pairs) = pair
        desc%pairs(desc%n_pairs)%pair_id = desc%n_pairs

        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Cpl_AddPair_Proc

    !===========================================================================
    ! **`MD_Cpl_Validate_Proc`** — 校验已配置通道（动作维 · **Validate**）
    !===========================================================================
    SUBROUTINE MD_Cpl_Validate_Proc(desc, status)
        TYPE(MD_Cpl_Desc), INTENT(INOUT) :: desc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: ip

        CALL init_error_status(status)

        IF (desc%n_pairs <= 0_i4) THEN
            desc%ctl%is_configured = .FALSE.
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        DO ip = 1, desc%n_pairs
            IF (desc%pairs(ip)%src_field_id <= 0_i4 .OR. &
                desc%pairs(ip)%dst_field_id <= 0_i4) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "MD_Cpl_Validate_Proc: pair has invalid field ID"
                RETURN
            END IF
            IF (desc%pairs(ip)%src_field_id == desc%pairs(ip)%dst_field_id) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "MD_Cpl_Validate_Proc: self-coupling detected"
                RETURN
            END IF
        END DO

        desc%ctl%is_configured = .TRUE.
        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Cpl_Validate_Proc

    !===========================================================================
    ! **`MD_Cpl_GetConfig_Proc`** — 只读查询全局控制（动作维 · **Query**）
    !===========================================================================
    SUBROUTINE MD_Cpl_GetConfig_Proc(desc, n_pairs, strategy, is_configured, status)
        TYPE(MD_Cpl_Desc), INTENT(IN) :: desc
        INTEGER(i4), INTENT(OUT) :: n_pairs
        INTEGER(i4), INTENT(OUT) :: strategy
        LOGICAL, INTENT(OUT) :: is_configured
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        n_pairs = desc%n_pairs
        strategy = desc%ctl%strategy
        is_configured = desc%ctl%is_configured

        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Cpl_GetConfig_Proc

    !===========================================================================
    ! **`MD_Cpl_GetPair_Proc`** — 按下标取单 **`MD_Coup_PairDef`**（动作维 · **Query**）
    !===========================================================================
    SUBROUTINE MD_Cpl_GetPair_Proc(desc, pair_idx, pair, status)
        TYPE(MD_Cpl_Desc), INTENT(IN) :: desc
        INTEGER(i4), INTENT(IN) :: pair_idx
        TYPE(MD_Coup_PairDef), INTENT(OUT) :: pair
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (pair_idx < 1_i4 .OR. pair_idx > desc%n_pairs) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Cpl_GetPair_Proc: index out of range"
            RETURN
        END IF

        pair = desc%pairs(pair_idx)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Cpl_GetPair_Proc

    !===========================================================================
    ! **`MD_Cpl_GetSummary_Proc`** — 配置摘要（动作维 · **Query**）
    !===========================================================================
    SUBROUTINE MD_Cpl_GetSummary_Proc(desc, n_pairs, n_active, strategy, &
        is_configured, status)
        TYPE(MD_Cpl_Desc), INTENT(IN) :: desc
        INTEGER(i4), INTENT(OUT) :: n_pairs
        INTEGER(i4), INTENT(OUT) :: n_active
        INTEGER(i4), INTENT(OUT) :: strategy
        LOGICAL, INTENT(OUT) :: is_configured
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: ip

        CALL init_error_status(status)

        n_pairs = desc%n_pairs
        strategy = desc%ctl%strategy
        is_configured = desc%ctl%is_configured
        n_active = 0_i4

        DO ip = 1, desc%n_pairs
            IF (desc%pairs(ip)%is_active) THEN
                n_active = n_active + 1_i4
            END IF
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Cpl_GetSummary_Proc

END MODULE MD_Cpl_Core
