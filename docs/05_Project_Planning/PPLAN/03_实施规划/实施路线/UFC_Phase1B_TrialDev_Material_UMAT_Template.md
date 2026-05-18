# UFC Phase 1 B阶段 — 材料域三层UMAT模板与试开发决策

**版本**: v1.0  
**日期**: 2026-03-28  
**阶段**: Phase 1 B（N0 防守加固后的四链可运行验证）  
**性质**: 试开发（快速验证、轻量交付、问题暴露为主）

---

## 1. 背景与问题

### 1.1 问题来源

Phase 1 B 阶段启动前，围绕 Material 域 UMAT 通道澄清了以下三个关键疑问：

1. **USR目录三文件的定位**：`L4_PH/Material/USR/` 的三个文件是否是 74 种本构都需要的模板？
2. **标准推广范式**：内置本构应遵循什么统一的文件/接口范式？
3. **三层模板差异性**：L3_MD、L4_PH、L5_RT 材料域是否共用同一种 UMAT 模板？

### 1.2 背景现状（代码核查结论）

| 文件 | 行数 | 发现 |
|------|------|------|
| `PH_Mat_Reg_Core.f90` | 631 | 第 620–623 行：708 用 `UMAT_ElasticIso` 占位，nprops=0, nstatev=0 |
| `PH_Mat_Compute_UMAT.f90` | 395 | J2 算法已实现（四链完整），但从未被注册激活 |
| `PH_Mat_USR_Umat.f90` | 57 | `PH_Mat_USR_Umat_Register` 已写好，但从未被调用 |
| `PH_UserSub_UMAT.f90` | 153 | ABAQUS UMAT 接口入口，USR 通道专属 |
| `PH_L4_Populate_Core.f90` | 830 | 顶部 G1 技术债注释：全局容器强依赖 |
| `PH_Mat_ELA_Isotropic.f90` | 179 | 标准二合一范式基准（UpdateStress + UMAT Wrapper）|
| `MD_Mat_ELA_Isotropic.f90` | 95 | L3 标准 Desc 范式基准 |
| `RT_Mat_Core.f90` | 3736 | L5 统一调度，`RT_Mat_ContmIntegIp` 中 select case 路由 |

---

## 2. 三个关键疑问的解答

### 2.1 USR目录三文件的定位

**结论**：USR 目录是专为「外部 ABAQUS-style UMAT 接入」设计的专用通道，74 种内置本构**不需要**这三个文件。

| 文件 | 职责 | 适用范围 |
|------|------|---------|
| `PH_Mat_Compute_UMAT.f90` | J2 算法主体（UpdateStress + ReturnMap + 切线模量）| USR 通道示范实现 |
| `PH_Mat_USR_Umat.f90` | mat_id=708 注册模块（`PH_Mat_USR_Umat_Register`）| USR 通道注册入口 |
| `PH_UserSub_UMAT.f90` | ABAQUS UMAT 接口入口（外部子程序签名对接）| 外部用户调用桥接 |

**内置本构范式**（以 `PH_Mat_ELA_Isotropic.f90` 为基准）：
- 一文件 = `XXX_UpdateStress(in, out)`（纯算法，MatPoint 范式）+ `UMAT_XXX_Yyy(ctx, status)`（ctx 薄包裹）
- 注册集中在 `PH_Mat_Reg_InitAll`，通过 `PH_Mat_Reg_Add` 统一注册

### 2.2 子域目录无需调整

| 层 | 子域目录现状 | 结论 |
|----|-------------|------|
| L3_MD/Material | ELA/PLM/HYP/VSC/DMG/CMP/SPU/POR + USR/Shared | 已完整，无需新增 |
| L4_PH/Material | ELA/PLM/HYP/VSC/DMG/CMP/SPU/POR + USR/Shared/Registry | 已完整，无需新增 |
| L5_RT/Material | 单文件 `RT_Mat_Core.f90` | 正确设计，无需拆分 |

### 2.3 三层材料域模板完全不同

三层职责正交，模板结构如下：

| 层 | 职责定位 | 模板结构 | 每种本构文件数 |
|----|---------|----------|--------------|
| L3_MD | 「材料是什么」（存储/验证/解包）| Desc TYPE + ValidateProps + InitFromProps | 1 个文件 |
| L4_PH | 「材料怎么算」（本构算法/应力更新）| UpdateStress（纯算法）+ UMAT_XXX（ctx Wrapper）| 1 个文件 |
| L5_RT | 「材料何时调用」（调度/积分点循环）| `select case(props%class_id)` 路由（无需新建文件）| 0 个新文件 |

---

## 3. 标准模板

### 3.1 L4_PH 标准本构模板

**基准范式文件**：[PH_Mat_ELA_Isotropic.f90](../../../ufc_core/L4_PH/Material/ELA/PH_Mat_ELA_Isotropic.f90)

```fortran
!===============================================================
! MODULE PH_Mat_XXX_Yyy
! 用途：[本构名称]（[理论说明]）
! 范式：L4_PH 标准二合一（UpdateStress + UMAT Wrapper）
!===============================================================
MODULE PH_Mat_XXX_Yyy
  USE UFC_Precision,            ONLY: wp, i4
  USE PH_Mat_Core_Types,        ONLY: MatPoint_In, MatPoint_Out
  USE PH_Mat_Core_UMAT_Adapter, ONLY: Unpack_From_UMAT_Context, &
                                       Pack_To_UMAT_Context
  USE PH_UMAT_Types,            ONLY: PH_UMAT_Context
  USE UFC_Error_Core,           ONLY: ErrorStatusType, STATUS_OK
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: XXX_Yyy_InitStateVars  ! 可选：初始化内变量
  PUBLIC :: XXX_Yyy_UpdateStress   ! 纯算法（MatPoint 范式）
  PUBLIC :: UMAT_XXX_Yyy           ! ctx Wrapper（注册兼容）

CONTAINS

  SUBROUTINE XXX_Yyy_InitStateVars(nstatev, statev)
    INTEGER(i4), INTENT(IN)    :: nstatev
    REAL(wp),    INTENT(INOUT) :: statev(nstatev)
    statev = 0.0_wp
  END SUBROUTINE XXX_Yyy_InitStateVars

  SUBROUTINE XXX_Yyy_UpdateStress(in, out)
    TYPE(MatPoint_In),  INTENT(IN)  :: in
    TYPE(MatPoint_Out), INTENT(OUT) :: out
    ! 理论依据：[引用：教材/论文]
    ! TODO: 填充本构算法（应力更新 + 切线模量）
    out%status%status_code = STATUS_OK
  END SUBROUTINE XXX_Yyy_UpdateStress

  SUBROUTINE UMAT_XXX_Yyy(ctx, status)
    TYPE(PH_UMAT_Context), INTENT(INOUT)        :: ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(MatPoint_In)  :: in
    TYPE(MatPoint_Out) :: out
    CALL Unpack_From_UMAT_Context(ctx, in)
    CALL XXX_Yyy_UpdateStress(in, out)
    IF (out%status%status_code == STATUS_OK) THEN
      CALL Pack_To_UMAT_Context(out, ctx)
    END IF
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE UMAT_XXX_Yyy

END MODULE PH_Mat_XXX_Yyy
```

**注册方式**（在 `PH_Mat_Reg_InitAll` 中追加）：
```fortran
USE PH_Mat_XXX_Yyy, ONLY: UMAT_XXX_Yyy, XXX_Yyy_InitStateVars
! ...
CALL PH_Mat_Reg_Add(NNN_i4, "ModelName", N_i4, M_i4, UMAT_XXX_Yyy, &
     init_proc=XXX_Yyy_InitStateVars, &
     props_schema="p1,p2,...", status=st)
```

### 3.2 L3_MD 标准 Desc 模板

**基准范式文件**：`L3_MD/Material/ELA/MD_Mat_ELA_Isotropic.f90`

```fortran
!===============================================================
! MODULE MD_Mat_XXX_Yyy
! 用途：[本构名称] 的材料描述层（Desc）
! 注意：不得执行任何本构计算；只存储、验证、解包
!===============================================================
MODULE MD_Mat_XXX_Yyy
  USE UFC_Precision,  ONLY: wp, i4
  USE MD_Mat_Core,    ONLY: MD_Mat_Desc
  USE UFC_Error_Core, ONLY: ErrorStatusType, STATUS_OK, STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: XXX_Yyy_MatDesc
  PUBLIC :: UF_XXX_Yyy_L3_ValidateProps
  PUBLIC :: UF_XXX_Yyy_L3_InitFromProps

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: XXX_Yyy_MatDesc
    REAL(wp) :: param1 = 0.0_wp     ! props(1): [物理含义, 单位]
    REAL(wp) :: param2 = 0.0_wp     ! props(2): [物理含义, 单位]
    LOGICAL  :: is_initialized = .FALSE.
  END TYPE XXX_Yyy_MatDesc

CONTAINS

  SUBROUTINE UF_XXX_Yyy_L3_ValidateProps(nprops, props, st)
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    st%status_code = STATUS_OK
    IF (nprops < 2_i4) THEN
      st%status_code = STATUS_ERROR
      st%message = "XXX_Yyy: 需要至少 2 个参数"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_ERROR
      st%message = "XXX_Yyy: param1 必须 > 0"
      RETURN
    END IF
  END SUBROUTINE UF_XXX_Yyy_L3_ValidateProps

  SUBROUTINE UF_XXX_Yyy_L3_InitFromProps(desc, nprops, props, st)
    TYPE(XXX_Yyy_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL UF_XXX_Yyy_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN
    desc%param1         = props(1)
    desc%param2         = props(2)
    desc%is_initialized = .TRUE.
  END SUBROUTINE UF_XXX_Yyy_L3_InitFromProps

END MODULE MD_Mat_XXX_Yyy
```

### 3.3 L5_RT 扩展方式（不新建文件）

在 `RT_Mat_Core.f90` 的 `RT_Mat_ContmIntegIp` 中 `select case` 追加路由分支：

```fortran
select case (props%class_id)
case (1)   ! 弹性 (ELA) — statev 不需要路由
  continue
case (2)   ! 弹塑性 J2 (PLM)
  mp%alpha_n    = ipState_in%stateV(UF_MAT_STATEV_J2_EQPS_IDX)
  mp%eps_p_n(1:6) = ipState_in%stateV(...)
! case (NNN)  ← 新本构：若 statev 结构不同才追加
case default
  ! 通用 statev 路由
end select
```

**规则**：若新本构 statev 结构与已有 case 相同 → 零改动；若不同 → 追加新 case；禁止新建独立文件。

---

## 4. 三级优先级执行序列

### SC-1：激活 mat_id=708 的 J2 算法（**最高优先**）

- **问题**：708 用 `UMAT_ElasticIso` 占位（nprops=0, nstatev=0），J2 算法已就绪但未接入
- **落地文件**：`UFC/ufc_core/L4_PH/Material/Registry/PH_Mat_Reg_Core.f90`
- **具体改动**：
  - 在 `PH_Mat_Reg_InitAll` USE 块追加：`USE PH_Mat_Compute_UMAT, ONLY: PH_UMAT_J2_Wrapper`
  - 第 622 行替换占位符为：
    ```fortran
    CALL PH_Mat_Reg_Add(708_i4, "USR_UMAT_J2", 4_i4, 7_i4, PH_UMAT_J2_Wrapper, &
         props_schema="E,nu,sigma_y0,H", status=st)
    ```
- **参考**：`PH_Mat_USR_Umat.f90` 中 `PH_Mat_USR_Umat_Register` 已有完整注册逻辑可参考
- **nprops=4**：E, nu, sigma_y0（初始屈服应力）, H（硬化模量）
- **nstatev=7**：6 个塑性应变分量 + 1 个等效塑性应变

### SC-2：新建 test_UMAT_J2.f90 骨架（四链可运行验证）

- **落地文件**：`UFC/tests/L4_PH/Material/test_UMAT_J2.f90`（新建）
- **验证序列**：
  1. 弹性加载（低于屈服应力）→ 验证线弹性响应
  2. 屈服点到达 → 验证等效应力 = sigma_y0
  3. 塑性回映（return mapping）→ 验证塑性应变累积
  4. 卸载 → 验证弹性卸载路径
- **参考值来源**：`PH_Mat_Compute_UMAT.f90` 中 J2 理论（Simo & Hughes §3.6）

### N1-1：消化 G1 技术债（全局容器强依赖）

- **问题**：`PH_L4_Populate_Core.f90` 顶部 G1 注释标注的全局容器强依赖（fallback 静默失败）
- **落地文件**：`UFC/ufc_core/L4_PH/PH_L4_Populate_Core.f90`
- **改动**：全局 fallback 路径追加 `log_warn`，不再静默失败
- **不改**：全局容器依赖结构（N1 完整改造为参数注入，属于后续阶段）

### SB-1：横向扩展（第二种本构注册）

- 参照 §3.1 标准模板，以等向硬化 J2 为第二个完整实现
- 新建 `PH_Mat_PLM_J2Iso.f90`（PLM 子域，等向硬化 J2 弹塑性）
- 注册：mat_id=201，nprops=4（E, nu, sigma_y0, H），nstatev=7

---

## 5. USR 目录 vs 标准目录分工边界（强制规则）

```
L4_PH/Material/
├── ELA/        ← 内置弹性本构（标准二合一范式）
├── PLM/        ← 内置塑性本构（标准二合一范式）
├── HYP/        ← 内置超弹性本构
├── ...         ← 其他子域（共 10 个）
├── USR/        ← 专用通道：外部 ABAQUS-style UMAT 接入 ONLY
│   ├── PH_Mat_Compute_UMAT.f90   ← J2 算法（USR 通道示范）
│   ├── PH_Mat_USR_Umat.f90       ← 708 注册模块
│   └── PH_UserSub_UMAT.f90       ← ABAQUS UMAT 接口入口
├── Shared/     ← 跨本构共享工具
└── Registry/   ← PH_Mat_Reg_Core.f90（集中注册表）
```

**强制规则**：
- 新增内置本构 → 放对应子域（ELA/PLM/…），遵循 §3.1 标准模板
- 接入外部用户 UMAT → 仅修改 USR/ 通道
- **禁止**向 USR/ 混入内置本构实现
- **禁止**在标准子域文件中使用 USR/ 内的具体算法

---

## 6. 三层工作量对比

| 任务类型 | L3_MD | L4_PH | L5_RT |
|---------|-------|-------|-------|
| 新增一种内置本构 | 新建 1 个 `MD_Mat_XXX.f90` | 新建 1 个 `PH_Mat_XXX.f90` + 注册 1 行 | 追加 1 个 case 分支（或零改动）|
| 接入外部 UMAT | 不需要 | 修改 USR/ 通道 | 不需要 |
| 修改调度逻辑 | 不涉及 | 不涉及 | 只改 `RT_Mat_Core.f90` 1 处 |

---

## 7. 待执行状态（2026-03-28）

| 编号 | 任务 | 状态 | 落地文件 |
|------|------|------|---------|
| SC-1 | 激活 708 J2 算法注册 | **待执行** | `PH_Mat_Reg_Core.f90` 第 622 行 |
| SC-2 | 新建 test_UMAT_J2.f90 骨架 | **待执行** | `tests/L4_PH/Material/test_UMAT_J2.f90` |
| N1-1 | G1 技术债 fallback log_warn | **待执行** | `PH_L4_Populate_Core.f90` |
| SB-1 | 第二种本构注册（J2 等向硬化）| **待排期** | `PLM/PH_Mat_PLM_J2Iso.f90` + 注册 |

---

**文档版本**: v1.0  
**创建日期**: 2026-03-28  
**关联文档**:
- [L4_PH_Material 域级建模文档.md](../../02_域级建模/L4_PH_Material%20域级建模文档.md) — §8 Phase 1 B决策
- [L3_MD_Material 域级建模文档.md](../../02_域级建模/L3_MD_Material%20域级建模文档.md) — §12 Desc模板规范
- [UFC_L3_L4_L5_FourChain_MasterPlan.md](UFC_L3_L4_L5_FourChain_MasterPlan.md) — 四链总图
