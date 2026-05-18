!===============================================================================
! MODULE:   MD_Ana_Comp
! LAYER:    L3_MD
! SUBDOMAIN Analysis · **Compat**（域缩 **Ana**；**主聚合 Desc**：**`MD_Ana_Comp_Group_Desc`**）
! ROLE:      _Impl — **(Solver × Coupling × Physics)** 三维相容 + **PROC_* → 三元组/组** 映射
! BRIEF:    **静态** 相容矩阵 **`g_compat`**、**`GROUP_*_COMPAT`** 与 **`MD_Ana_Comp_*` / `MD_Ana_Comp_Group_Desc`** 聚合 **Desc**
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**数据结构 · 枚举轴 + 嵌套 Desc + 二维 LOGICAL 表** + **过程算法 · Init/Check/Map/Validate**；
!   **Analysis 子域注册桥** 在 **`MD_Ana_Brg`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + Args + 主/辅 + 嵌套 · 并列 · 主从）
!
!       **TYPE 命名（层前缀 + 域缩 + 语义段 + 四型后缀）**
!       — 层前缀：**`MD_`** | **`PH_`** | **`RT_`**。  
!       — **本柱域缩**：**`MD_Ana_Comp_*`** — **Cfg / Stp / Pop** 三语义段（**嵌套** 于聚合 **`MD_Ana_Comp_Group_Desc`**）。  
!       — **`MD_Ana_Comp_Group_Desc`**：**主 Desc 容器**（**曾用名**：**`AnalysisGroupDesc`**）— **`cfg`**
!         （**`MD_Ana_Comp_Cfg_Proc_Desc`** · PROC 侧辅求解需求）、**`stp`**（**`MD_Ana_Comp_Stp_Triple_Desc`** · **`RT_SOLVER_*` × `AC_CPL_*` × `AC_PHYS_*`**）、
!         **`pop`**（**`MD_Ana_Comp_Pop_Group_Desc`** · **G1–G9** **Populate** 物理解算分组）。  
!       — **`AC_*` 枚举**：**并列 INTEGER PARAMETER** — **D2** 耦合策略、**D3** 物理场、**G1–G9** 物理组、材料族 /
!         单元类 **维度标签**（**非** 四型 TYPE 本体）。  
!       — **`GROUP_MAT_COMPAT` / `GROUP_ELEM_COMPAT`**：**并列** 二维 **PARAMETER** 真值表（**组 × 材料族 / 单元类**）。  
!       — **模块态**：**`g_compat`** / **`g_initialized`** — 三维 **Solver×Cpl×Phys** **Algo 快照**（**`Init`** 填充）。  
!       — **Args（+1）**：**`Validate*`** / **`FullCheck`** 使用 **显式形参** + **`ErrorStatusType`**；**无** **`*_Arg`** 四型包。
!
!   [2] 过程算法（空间维 · 时间维 · 动作维）
!       — **时间维**：**`MD_Ana_Comp_Init`** — **COLD** 填 **`g_compat`**；**`CheckTriple` / `Validate*`** — **无** 物理时间积分
!         （**纯组合判定**）。  
!       — **空间维**：**`CheckGroupMat` / `CheckGroupElem`** / **`GROUP_*_COMPAT`** — **离散材料族 / 单元类** 轴（**非** 节点坐标）。  
!       — **动作维**：**`ProcToGroup` / `PhysToGroup`** — **Map**；**`ValidateStep` / `ValidateGroup*` / `FullCheck`** — **Validate**
!         + **`ErrorStatusType`** 包装。
!
! **依赖**：**`IF_Prec_Core`**, **`IF_Err_Brg`**, **`RT_SolverType_Def`**（**`RT_SOLVER_*`**, **`RT_SOLVER_COUNT`**）。  
! **非依赖**：**不** `USE` **`MD_Ana_Brg`**（**Brg** 单向调用 **Comp.Init**）。
!
!===============================================================================
! Pilot: ufc-layer-l3-l4-l5-pilot.md — **Cfg+Stp+Pop** 嵌套 **`MD_Ana_Comp_Group_Desc`**
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Analysis | Role:Compat | FuncSet:Init,Validate,Map | HotPath:No
!>>> UFC_L3_CONTRACT | Analysis/CONTRACT.md（交叉索引 Step/Solv/Cpl 合同卡）

MODULE MD_Ana_Comp
  USE IF_Prec_Core, ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
      IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_SolverType_Def, ONLY: RT_SOLVER_UNKNOWN, RT_SOLVER_IMPLICIT, &
      RT_SOLVER_EXPLICIT, RT_SOLVER_CFD, RT_SOLVER_EMF, RT_SOLVER_THM, &
      RT_SOLVER_PMF, RT_SOLVER_DIF, RT_SOLVER_CPL, RT_SOLVER_COUNT
  IMPLICIT NONE
  PRIVATE

  !-- **枚举轴**（D2/D3/G）+ **二维相容表** + **`MD_Ana_Comp_Group_Desc`** 嵌套三辅段 + **`g_compat`** 模块态

  !=====================================================================
  ! **D2** — **耦合策略** 枚举（**动作维 · 离散标签**；与 **`g_compat`** 维 **2** 对齐 **1..`AC_N_CPL`**）
  !=====================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: AC_CPL_NONE       = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_CPL_ONEWAY     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_CPL_STAGGERED  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_CPL_MONOLITHIC = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_N_CPL          = 4_i4

  !=====================================================================
  ! **D3** — **物理场** 枚举（**动作维 · 离散标签**；**`AC_PHYS_*`** 与 **`RT_SOLVER_*`** 正交组合）
  !=====================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_STRUCTURE      = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_THERMAL        = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_FREQUENCY      = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_ACOUSTIC       = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_EM             = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_FLUID          = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_THERMAL_STRUCT = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_ELECTRO_STRUCT = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_FLUID_STRUCT   = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_FLUID_THERMAL  = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_MULTIFIELD     = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_PHYS_SPECIAL        = 12_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_N_PHYS              = 12_i4

  !=====================================================================
  ! **G1–G9** — **物理组**（**Populate / 材料-单元** 交叉链；**空间维**：离散 **组 ID** 非网格坐标）
  !=====================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: AC_GROUP_STRUCTURAL  = 1_i4  ! G1
  INTEGER(i4), PARAMETER, PUBLIC :: AC_GROUP_THERMAL     = 2_i4  ! G2
  INTEGER(i4), PARAMETER, PUBLIC :: AC_GROUP_FREQUENCY   = 3_i4  ! G3
  INTEGER(i4), PARAMETER, PUBLIC :: AC_GROUP_ACOUSTIC    = 4_i4  ! G4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_GROUP_EM          = 5_i4  ! G5
  INTEGER(i4), PARAMETER, PUBLIC :: AC_GROUP_THERM_MECH  = 6_i4  ! G6
  INTEGER(i4), PARAMETER, PUBLIC :: AC_GROUP_MULTIFIELD  = 7_i4  ! G7
  INTEGER(i4), PARAMETER, PUBLIC :: AC_GROUP_GEOTECH     = 8_i4  ! G8
  INTEGER(i4), PARAMETER, PUBLIC :: AC_GROUP_SPECIAL     = 9_i4  ! G9
  INTEGER(i4), PARAMETER, PUBLIC :: AC_N_GROUP           = 9_i4

  INTEGER(i4), PARAMETER, PUBLIC :: AC_N_MAT_FAM         = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AC_N_ELEM_CAT        = 9_i4

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Ana_Comp_Cfg_Proc_Desc
  ! KIND:   Desc（辅 · **Cfg** — **嵌套** 于 **`MD_Ana_Comp_Group_Desc%cfg`**）
  ! ROLE:   **`PROC_*`** 侧 **辅求解 / 需求** 标志（**`needs_aux`**, **`aux_solver`**）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Ana_Comp_Cfg_Proc_Desc
    INTEGER(i4) :: proc_id    = 0_i4
    LOGICAL     :: needs_aux  = .FALSE.
    INTEGER(i4) :: aux_solver = 0_i4
  END TYPE MD_Ana_Comp_Cfg_Proc_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Ana_Comp_Stp_Triple_Desc
  ! KIND:   Desc（辅 · **Stp** — **嵌套** 于 **`MD_Ana_Comp_Group_Desc%stp`**）
  ! ROLE:   **(solver, coupling, physics)** 离散三元 — **并列** 索引 **`RT_SOLVER_*` / `AC_CPL_*` / `AC_PHYS_*`**
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Ana_Comp_Stp_Triple_Desc
    INTEGER(i4) :: solver   = 0_i4   ! RT_SOLVER_* (1-8)
    INTEGER(i4) :: coupling = 0_i4   ! AC_CPL_* (1-4)
    INTEGER(i4) :: physics  = 0_i4   ! AC_PHYS_* (1-12)
  END TYPE MD_Ana_Comp_Stp_Triple_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Ana_Comp_Pop_Group_Desc
  ! KIND:   Desc（辅 · **Pop** — **嵌套** 于 **`MD_Ana_Comp_Group_Desc%pop`**）
  ! ROLE:   **G1–G9** **Populate** 物理解算分组 ID（**`AC_GROUP_*`**）
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Ana_Comp_Pop_Group_Desc
    INTEGER(i4) :: group = 0_i4      ! AC_GROUP_* (1-9, G1-G9)
  END TYPE MD_Ana_Comp_Pop_Group_Desc

  !---------------------------------------------------------------------------
  ! TYPE:   MD_Ana_Comp_Group_Desc
  ! KIND:   Desc（主 · **聚合** — **嵌套** **`cfg` + `stp` + `pop`** 三辅段）
  ! DESC:   **`PROC_*` → (solver,coupling,physics) 三元 + 派生 G + Cfg 辅求解需求**
  ! NOTE:   **曾用名 `AnalysisGroupDesc`**（已移除）；**辅段** 均为 **`MD_Ana_Comp_*`**。
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Ana_Comp_Group_Desc
    TYPE(MD_Ana_Comp_Cfg_Proc_Desc)  :: cfg
    TYPE(MD_Ana_Comp_Stp_Triple_Desc) :: stp
    TYPE(MD_Ana_Comp_Pop_Group_Desc)  :: pop
  END TYPE MD_Ana_Comp_Group_Desc

  !=====================================================================
  ! **`GROUP_MAT_COMPAT(9,11)`** — **空间维 · 离散** 组×材料族（**列主 RESHAPE**；**动作维 · Query** 只读）
  !=====================================================================
  LOGICAL, PARAMETER, PUBLIC :: GROUP_MAT_COMPAT(AC_N_GROUP, AC_N_MAT_FAM) = RESHAPE( (/ &
  ! Col 1: Elastic (G1..G9)
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 2: Plastic
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 3: Geo
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 4: Hyper
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 5: VE
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 6: VP/Creep
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 7: Damage
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 8: Composite
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 9: Heat/Thermal
    .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  &
  ! Col 10: Acoustic
    .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .FALSE., .TRUE.,  &
  ! Col 11: EM/User
    .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .TRUE.,  .FALSE., .TRUE.   &
  /), SHAPE = (/ AC_N_GROUP, AC_N_MAT_FAM /))

  !=====================================================================
  ! **`GROUP_ELEM_COMPAT(9,9)`** — **空间维 · 离散** 组×单元类（C3D/CPS/…/EM；**动作维 · Query** 只读）
  !=====================================================================
  LOGICAL, PARAMETER, PUBLIC :: GROUP_ELEM_COMPAT(AC_N_GROUP, AC_N_ELEM_CAT) = RESHAPE( (/ &
  ! Col 1: C3D (G1..G9)
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 2: CPS
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 3: CAX
    .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  &
  ! Col 4: S (Shell)
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  &
  ! Col 5: B (Beam)
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  &
  ! Col 6: T (Truss)
    .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  &
  ! Col 7: DC (Thermal elements)
    .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  &
  ! Col 8: AC (Acoustic elements)
    .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .TRUE.,  .FALSE., .TRUE.,  &
  ! Col 9: EM (Electromagnetic elements)
    .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .TRUE.,  .FALSE., .TRUE.   &
  /), SHAPE = (/ AC_N_GROUP, AC_N_ELEM_CAT /))

  !---------------------------------------------------------------------------
  ! **PUBLIC API** — **Init / Check / Map / Validate**（**过程算法**；无 **`*_Arg`** 包）
  !---------------------------------------------------------------------------
  PUBLIC :: MD_Ana_Comp_Cfg_Proc_Desc, MD_Ana_Comp_Stp_Triple_Desc, &
            MD_Ana_Comp_Pop_Group_Desc, MD_Ana_Comp_Group_Desc
  PUBLIC :: MD_Ana_Comp_Init
  PUBLIC :: MD_Ana_Comp_CheckTriple
  PUBLIC :: MD_Ana_Comp_CheckGroupMat
  PUBLIC :: MD_Ana_Comp_CheckGroupElem
  PUBLIC :: MD_Ana_Comp_PhysToGroup
  PUBLIC :: MD_Ana_Comp_ProcToGroup
  PUBLIC :: MD_Ana_Comp_ValidateStep
  PUBLIC :: MD_Ana_Comp_ValidateGroupMat
  PUBLIC :: MD_Ana_Comp_ValidateGroupElem
  PUBLIC :: MD_Ana_Comp_FullCheck

  !---------------------------------------------------------------------------
  ! **模块态** — **`g_compat(solver,cpl,phys)`**（**Algo 快照**）+ **`g_initialized`**
  !---------------------------------------------------------------------------
  LOGICAL, SAVE :: g_compat(RT_SOLVER_COUNT, AC_N_CPL, AC_N_PHYS)
  LOGICAL, SAVE :: g_initialized = .FALSE.

CONTAINS

  !=======================================================================
  ! **Section 1 — Core**（**时间维 · COLD** 填 **`g_compat`**；**动作维 · Query** 查 **`CheckTriple`**）
  ! **空间维**：三元索引轴（**非** 节点几何）
  !=======================================================================

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_Init**
  ! **时间维 · COLD** | **动作维 · Mutate** — 写入 **`g_compat`** 并置 **`g_initialized`**
  !--------------------------------------------------------------------
  SUBROUTINE MD_Ana_Comp_Init()

    g_compat = .FALSE.

    !-- Solver 1: IMPLICIT (Standard) --
    g_compat(1, 1, AC_PHYS_STRUCTURE)  = .TRUE.
    g_compat(1, 1, AC_PHYS_FREQUENCY)  = .TRUE.
    g_compat(1, 1, AC_PHYS_SPECIAL)    = .TRUE.
    g_compat(1, 2, AC_PHYS_STRUCTURE)  = .TRUE.
    g_compat(1, 3, AC_PHYS_STRUCTURE)      = .TRUE.
    g_compat(1, 3, AC_PHYS_THERMAL)        = .TRUE.
    g_compat(1, 3, AC_PHYS_THERMAL_STRUCT) = .TRUE.
    g_compat(1, 3, AC_PHYS_ELECTRO_STRUCT) = .TRUE.
    g_compat(1, 3, AC_PHYS_MULTIFIELD)     = .TRUE.
    g_compat(1, 3, AC_PHYS_SPECIAL)        = .TRUE.
    g_compat(1, 4, AC_PHYS_STRUCTURE)      = .TRUE.
    g_compat(1, 4, AC_PHYS_THERMAL_STRUCT) = .TRUE.
    g_compat(1, 4, AC_PHYS_ELECTRO_STRUCT) = .TRUE.
    g_compat(1, 4, AC_PHYS_MULTIFIELD)     = .TRUE.
    g_compat(1, 4, AC_PHYS_SPECIAL)        = .TRUE.

    !-- Solver 2: EXPLICIT --
    g_compat(2, 1, AC_PHYS_STRUCTURE)  = .TRUE.

    !-- Solver 3: CFD --
    g_compat(3, 1, AC_PHYS_FLUID)         = .TRUE.
    g_compat(3, 1, AC_PHYS_SPECIAL)       = .TRUE.
    g_compat(3, 3, AC_PHYS_FLUID)         = .TRUE.
    g_compat(3, 3, AC_PHYS_FLUID_THERMAL) = .TRUE.
    g_compat(3, 4, AC_PHYS_FLUID)         = .TRUE.
    g_compat(3, 4, AC_PHYS_FLUID_STRUCT)  = .TRUE.

    !-- Solver 4: EMF --
    g_compat(4, 1, AC_PHYS_EM)  = .TRUE.

    !-- Solver 5: THM (pure thermal) --
    g_compat(5, 1, AC_PHYS_THERMAL) = .TRUE.
    g_compat(5, 1, AC_PHYS_SPECIAL) = .TRUE.

    !-- Solver 6: PMF (pore mechanics) --
    g_compat(6, 1, AC_PHYS_STRUCTURE) = .TRUE.
    g_compat(6, 3, AC_PHYS_STRUCTURE) = .TRUE.

    !-- Solver 7: DIF (mass diffusion) --
    g_compat(7, 1, AC_PHYS_SPECIAL)  = .TRUE.

    !-- Solver 8: CPL (multi-field coordinator) --
    g_compat(8, 3, AC_PHYS_MULTIFIELD)     = .TRUE.
    g_compat(8, 4, AC_PHYS_MULTIFIELD)     = .TRUE.
    g_compat(8, 3, AC_PHYS_THERMAL_STRUCT) = .TRUE.
    g_compat(8, 4, AC_PHYS_THERMAL_STRUCT) = .TRUE.
    g_compat(8, 3, AC_PHYS_FLUID_STRUCT)   = .TRUE.
    g_compat(8, 4, AC_PHYS_FLUID_STRUCT)   = .TRUE.
    g_compat(8, 3, AC_PHYS_FLUID_THERMAL)  = .TRUE.
    g_compat(8, 3, AC_PHYS_ELECTRO_STRUCT) = .TRUE.
    g_compat(8, 4, AC_PHYS_ELECTRO_STRUCT) = .TRUE.

    g_initialized = .TRUE.

  END SUBROUTINE MD_Ana_Comp_Init

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_CheckTriple**
  ! **时间维 · N/A** | **空间维 · 索引轴** | **动作维 · Query** — **`g_compat`**；**status**：0 OK，1 非法，-1 越界，-2 未 Init
  !--------------------------------------------------------------------
  SUBROUTINE MD_Ana_Comp_CheckTriple(solver, coupling, physics, status)
    INTEGER(i4), INTENT(IN)  :: solver, coupling, physics
    INTEGER(i4), INTENT(OUT) :: status

    status = 0_i4

    IF (.NOT. g_initialized) THEN
      status = -2_i4
      RETURN
    END IF

    IF (solver < 1_i4 .OR. solver > RT_SOLVER_COUNT .OR. &
        coupling < 1_i4 .OR. coupling > AC_N_CPL .OR. &
        physics < 1_i4 .OR. physics > AC_N_PHYS) THEN
      status = -1_i4
      RETURN
    END IF

    IF (.NOT. g_compat(solver, coupling, physics)) THEN
      status = 1_i4
    END IF

  END SUBROUTINE MD_Ana_Comp_CheckTriple

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_CheckGroupMat**（PURE）
  ! **空间维 · 离散** | **动作维 · Query** — **`GROUP_MAT_COMPAT(group, mat_fam)`**
  !--------------------------------------------------------------------
  PURE FUNCTION MD_Ana_Comp_CheckGroupMat(group, mat_fam) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: group, mat_fam
    LOGICAL :: ok
    ok = .FALSE.
    IF (group < 1_i4 .OR. group > AC_N_GROUP) RETURN
    IF (mat_fam < 1_i4 .OR. mat_fam > AC_N_MAT_FAM) RETURN
    ok = GROUP_MAT_COMPAT(group, mat_fam)
  END FUNCTION MD_Ana_Comp_CheckGroupMat

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_CheckGroupElem**（PURE）
  ! **空间维 · 离散** | **动作维 · Query** — **`GROUP_ELEM_COMPAT(group, elem_cat)`**
  !--------------------------------------------------------------------
  PURE FUNCTION MD_Ana_Comp_CheckGroupElem(group, elem_cat) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: group, elem_cat
    LOGICAL :: ok
    ok = .FALSE.
    IF (group < 1_i4 .OR. group > AC_N_GROUP) RETURN
    IF (elem_cat < 1_i4 .OR. elem_cat > AC_N_ELEM_CAT) RETURN
    ok = GROUP_ELEM_COMPAT(group, elem_cat)
  END FUNCTION MD_Ana_Comp_CheckGroupElem

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_PhysToGroup**（PURE）
  ! **动作维 · Map** — **(solver, coupling, physics) → `AC_GROUP_*`**（**时间/网格 N/A**）
  !--------------------------------------------------------------------
  PURE FUNCTION MD_Ana_Comp_PhysToGroup(solver, coupling, physics) RESULT(group)
    INTEGER(i4), INTENT(IN) :: solver, coupling, physics
    INTEGER(i4) :: group

    group = AC_GROUP_SPECIAL

    SELECT CASE (physics)
    CASE (AC_PHYS_STRUCTURE)
      IF (solver == RT_SOLVER_PMF) THEN
        group = AC_GROUP_GEOTECH
      ELSE
        group = AC_GROUP_STRUCTURAL
      END IF
    CASE (AC_PHYS_THERMAL)
      group = AC_GROUP_THERMAL
    CASE (AC_PHYS_FREQUENCY)
      group = AC_GROUP_FREQUENCY
    CASE (AC_PHYS_ACOUSTIC)
      group = AC_GROUP_ACOUSTIC
    CASE (AC_PHYS_EM)
      group = AC_GROUP_EM
    CASE (AC_PHYS_FLUID)
      group = AC_GROUP_SPECIAL
    CASE (AC_PHYS_THERMAL_STRUCT)
      group = AC_GROUP_THERM_MECH
    CASE (AC_PHYS_ELECTRO_STRUCT, AC_PHYS_FLUID_STRUCT, &
          AC_PHYS_FLUID_THERMAL, AC_PHYS_MULTIFIELD)
      group = AC_GROUP_MULTIFIELD
    CASE (AC_PHYS_SPECIAL)
      group = AC_GROUP_SPECIAL
    CASE DEFAULT
      group = AC_GROUP_SPECIAL
    END SELECT
  END FUNCTION MD_Ana_Comp_PhysToGroup

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_ProcToGroup**
  ! **动作维 · Map** — **`PROC_*` (`proc_id`) → `MD_Ana_Comp_Group_Desc`**（**`cfg`/`stp`/`pop`**）；**时间维 · N/A**
  !--------------------------------------------------------------------
  SUBROUTINE MD_Ana_Comp_ProcToGroup(proc_id, desc)
    INTEGER(i4), INTENT(IN) :: proc_id
    TYPE(MD_Ana_Comp_Group_Desc), INTENT(OUT) :: desc

    desc%cfg%proc_id   = proc_id
    desc%cfg%needs_aux = .FALSE.
    desc%cfg%aux_solver = 0_i4

    SELECT CASE (proc_id)
    !-- Group A: Static & Quasi-Static --
    CASE (1, 3)  ! STATIC, STATIC_PERTURBATION
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_STRUCTURE
    CASE (2)     ! STATIC_RIKS
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_STRUCTURE
    CASE (4)     ! VISCO
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_STRUCTURE

    !-- Group B: Dynamic --
    CASE (10, 12, 13) ! DYNAMIC_IMPLICIT, SUBSPACE, MODAL_DYNAMIC
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_STRUCTURE
    CASE (11)    ! DYNAMIC_EXPLICIT
      desc%stp%solver   = RT_SOLVER_EXPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_STRUCTURE
    CASE (14)    ! DYNAMIC_CTD_EXPLICIT
      desc%stp%solver   = RT_SOLVER_EXPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_THERMAL_STRUCT
    CASE (15)    ! ANNEAL
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_SPECIAL

    !-- Group C: Frequency & Modal --
    CASE (20, 21, 25) ! MODAL, BUCKLE, COMPLEX_FREQUENCY
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_FREQUENCY
    CASE (22, 23, 24) ! FREQUENCY/SSD, RANDOM_RESPONSE, RESPONSE_SPECTRUM
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_FREQUENCY

    !-- Group D: Heat & Diffusion --
    CASE (30)    ! HEAT_TRANSFER
      desc%stp%solver   = RT_SOLVER_THM
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_THERMAL
    CASE (31)    ! MASS_DIFFUSION
      desc%stp%solver   = RT_SOLVER_DIF
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_SPECIAL

    !-- Group E: Coupled Multi-Physics --
    CASE (40)    ! COUPLED_TEMP_DISP
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_STAGGERED
      desc%stp%physics  = AC_PHYS_THERMAL_STRUCT
    CASE (41)    ! COUPLED_THERMAL_ELEC
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_STAGGERED
      desc%stp%physics  = AC_PHYS_ELECTRO_STRUCT
    CASE (42)    ! COUPLED_TES (3-field)
      desc%stp%solver   = RT_SOLVER_CPL
      desc%stp%coupling = AC_CPL_MONOLITHIC
      desc%stp%physics  = AC_PHYS_MULTIFIELD
    CASE (43)    ! PIEZOELECTRIC
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_MONOLITHIC
      desc%stp%physics  = AC_PHYS_ELECTRO_STRUCT
    CASE (44)    ! ELECTROMAGNETIC
      desc%stp%solver   = RT_SOLVER_EMF
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_EM
    CASE (45)    ! ACOUSTIC
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_ACOUSTIC

    !-- Group F: Geotechnical --
    CASE (50)    ! GEOSTATIC
      desc%stp%solver   = RT_SOLVER_PMF
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_STRUCTURE
    CASE (51)    ! SOILS/CONSOLIDATION
      desc%stp%solver   = RT_SOLVER_PMF
      desc%stp%coupling = AC_CPL_STAGGERED
      desc%stp%physics  = AC_PHYS_STRUCTURE

    !-- Group G: Special --
    CASE (60)    ! STEADY_STATE_TRANSPORT
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_SPECIAL
    CASE (61)    ! SUBSTRUCTURE
      desc%stp%solver   = RT_SOLVER_IMPLICIT
      desc%stp%coupling = AC_CPL_NONE
      desc%stp%physics  = AC_PHYS_SPECIAL

    CASE DEFAULT
      desc%stp%solver   = RT_SOLVER_UNKNOWN
      desc%stp%coupling = 0_i4
      desc%stp%physics  = 0_i4
      desc%pop%group    = 0_i4
      RETURN
    END SELECT

    desc%pop%group = MD_Ana_Comp_PhysToGroup(desc%stp%solver, desc%stp%coupling, desc%stp%physics)

    IF (desc%stp%solver == RT_SOLVER_CFD .AND. &
        desc%stp%physics == AC_PHYS_FLUID_STRUCT) THEN
      desc%cfg%needs_aux = .TRUE.
      desc%cfg%aux_solver = RT_SOLVER_IMPLICIT
    END IF

  END SUBROUTINE MD_Ana_Comp_ProcToGroup

  !=======================================================================
  ! **Section 2 — Bridge**（**`ErrorStatusType`** 包装 **Validate***；**动作维 · Validate**）
  ! **时间维**：**N/A**（组合判定）；**空间维**：**`ValidateGroup*`** 消费 **材料族 / 单元类** 离散 ID
  !=======================================================================

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_ValidateStep**
  ! **动作维 · Validate** — **`ProcToGroup` + `CheckTriple`**；**compat_status**：0 OK，1 非法三元，-1 未知 PROC，-2 未 Init
  !--------------------------------------------------------------------
  SUBROUTINE MD_Ana_Comp_ValidateStep(proc_id, compat_status, &
                                       group_desc, status)
    INTEGER(i4), INTENT(IN)  :: proc_id
    INTEGER(i4), INTENT(OUT) :: compat_status
    TYPE(MD_Ana_Comp_Group_Desc), INTENT(OUT) :: group_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    CALL MD_Ana_Comp_ProcToGroup(proc_id, group_desc)

    IF (group_desc%stp%solver == 0_i4) THEN
      compat_status = -1_i4
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    CALL MD_Ana_Comp_CheckTriple(group_desc%stp%solver, &
                                  group_desc%stp%coupling, &
                                  group_desc%stp%physics, &
                                  compat_status)

    IF (compat_status /= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF

  END SUBROUTINE MD_Ana_Comp_ValidateStep

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_ValidateGroupMat**
  ! **空间维 · 离散（材料族）** | **动作维 · Validate** — **`CheckGroupMat(pop%group, mat_fam)`** + **`ErrorStatusType`**
  !--------------------------------------------------------------------
  SUBROUTINE MD_Ana_Comp_ValidateGroupMat(proc_id, mat_fam, is_ok, status)
    INTEGER(i4), INTENT(IN) :: proc_id, mat_fam
    LOGICAL, INTENT(OUT)    :: is_ok
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MD_Ana_Comp_Group_Desc) :: desc

    CALL init_error_status(status)

    CALL MD_Ana_Comp_ProcToGroup(proc_id, desc)
    IF (desc%stp%solver == 0_i4) THEN
      is_ok = .FALSE.
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    is_ok = MD_Ana_Comp_CheckGroupMat(desc%pop%group, mat_fam)
    IF (.NOT. is_ok) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF

  END SUBROUTINE MD_Ana_Comp_ValidateGroupMat

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_ValidateGroupElem**
  ! **空间维 · 离散（单元类）** | **动作维 · Validate** — **`CheckGroupElem(pop%group, elem_cat)`** + **`ErrorStatusType`**
  !--------------------------------------------------------------------
  SUBROUTINE MD_Ana_Comp_ValidateGroupElem(proc_id, elem_cat, is_ok, status)
    INTEGER(i4), INTENT(IN) :: proc_id, elem_cat
    LOGICAL, INTENT(OUT)    :: is_ok
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MD_Ana_Comp_Group_Desc) :: desc

    CALL init_error_status(status)

    CALL MD_Ana_Comp_ProcToGroup(proc_id, desc)
    IF (desc%stp%solver == 0_i4) THEN
      is_ok = .FALSE.
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    is_ok = MD_Ana_Comp_CheckGroupElem(desc%pop%group, elem_cat)
    IF (.NOT. is_ok) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF

  END SUBROUTINE MD_Ana_Comp_ValidateGroupElem

  !--------------------------------------------------------------------
  ! **MD_Ana_Comp_FullCheck**
  ! **动作维 · Validate** — **PROC + 三元 + 组×材料 + 组×单元**；**compat_status**：0 OK；1 三元；2 组-材料；3 组-单元；4 双否；-1 未知 PROC；-2 未 Init
  !--------------------------------------------------------------------
  SUBROUTINE MD_Ana_Comp_FullCheck(proc_id, mat_fam, elem_cat, &
                                    compat_status, group_desc, status)
    INTEGER(i4), INTENT(IN)  :: proc_id
    INTEGER(i4), INTENT(IN)  :: mat_fam
    INTEGER(i4), INTENT(IN)  :: elem_cat
    INTEGER(i4), INTENT(OUT) :: compat_status
    TYPE(MD_Ana_Comp_Group_Desc), INTENT(OUT) :: group_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: triple_status
    LOGICAL :: mat_ok, elem_ok

    CALL init_error_status(status)
    compat_status = 0_i4

    CALL MD_Ana_Comp_ProcToGroup(proc_id, group_desc)
    IF (group_desc%stp%solver == 0_i4) THEN
      compat_status = -1_i4
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    CALL MD_Ana_Comp_CheckTriple(group_desc%stp%solver, &
                                  group_desc%stp%coupling, &
                                  group_desc%stp%physics, &
                                  triple_status)
    IF (triple_status /= 0_i4) THEN
      compat_status = triple_status
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    mat_ok  = MD_Ana_Comp_CheckGroupMat(group_desc%pop%group, mat_fam)
    elem_ok = MD_Ana_Comp_CheckGroupElem(group_desc%pop%group, elem_cat)

    IF (.NOT. mat_ok .AND. .NOT. elem_ok) THEN
      compat_status = 4_i4
    ELSE IF (.NOT. mat_ok) THEN
      compat_status = 2_i4
    ELSE IF (.NOT. elem_ok) THEN
      compat_status = 3_i4
    ELSE
      compat_status = 0_i4
    END IF

    IF (compat_status /= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF

  END SUBROUTINE MD_Ana_Comp_FullCheck

END MODULE MD_Ana_Comp
