# ABAQUS_Subroutine_UFC_TYPE_Mapping — ABAQUS 用户子程序接口参数→UFC TYPE 成员名对照表
<!-- v1.0 | 2026-04-13 | UFC 六层架构核心文档 -->
<!-- 归属：UFC/docs/05_Project_Planning/PPLAN/06_核心架构/ -->
<!-- 权威性：所有 Adapter 层（ABAQUS 接口→UFC 内核）的参数 pack/unpack 必须以本表为基准 -->

**版本**：v1.0
**日期**：2026-04-13
**状态**：已定稿（初版）

---

## 一、设计目标与使用规则

### 1.1 目标

建立 ABAQUS 用户子程序参数名（扁平数组风格）与 UFC 内部 TYPE 成员名（结构化风格）之间的**权威双向映射**，用于：

1. **Adapter 层编写**：在 ABAQUS 标准接口（UEL/UMAT/DLOAD 等）入口处 pack → UFC TYPE
2. **参数名一致性**：UFC 内核 TYPE 成员名直接映射 ABAQUS 参数名，提升可读性
3. **新域扩展参考**：扩展新的用户子程序时，查本表确定 UFC TYPE 中应设的成员名

### 1.2 使用规则

```
规则 1：Adapter 层（接口入口）是唯一合法的 pack/unpack 点
  ✅ Adapter 入口：ABAQUS 扁平数组 → UFC TYPE 结构体
  ✅ Adapter 出口：UFC TYPE 结构体 → ABAQUS 扁平数组
  ❌ 内核层（PH_xxx_Core）：不得直接接触 ABAQUS 原始数组

规则 2：成员名映射原则
  - ABAQUS 参数名小写化 → UFC TYPE 成员名
  - 数组参数：ABAQUS 原名小写 → 成员名（如 STRESS(NTENS) → state%stress(1:ntens)）
  - 整数控制参数：原名小写 → 成员名（如 NTENS → algo%ntens）
  - 时间参数：TIME(1)/TIME(2) → ctx%step_time / ctx%total_time

规则 3：只读参数 → Desc 或 Algo 成员；读写参数 → State 成员；增量驱动 → Ctx 成员
```

### 1.3 子程序分组总览

| 分组 | 子程序数 | 主要子程序 | 对应 UFC 域 |
|------|:-------:|----------|-----------|
| §2 材料本构（Material）| 15 | UMAT/VUMAT/UMATHT/CREEP/UHARD... | Material 域 |
| §3 用户单元（Element）| 3 | UEL/VUEL/UELMAT | Element 域 |
| §4 载荷分布（Load）| 9 | DLOAD/VDLOAD/CLOAD/FILM/HETVAL... | Load 域 |
| §5 边界条件（BC）| 6 | DISP/VDISP/UTEMP/UPSD... | BC 域 |
| §6 接触摩擦（Contact）| 8 | UINTER/VUINTER/UFRIC/VFRIC/GAPCON... | Contact 域 |
| §7 约束（Constraint）| 4 | MPC/UMESHMOTION/RSURFU/URDFIL | Constraint 域 |
| §8 场变量（Field）| 5 | USDFLD/VUSDFLD/UFIELD/SDVINI/SIGINI | Field 域 |
| §9 分析控制（Analysis）| 4 | UAMP/VUAMP/UEXTERNALDB/UVARM | Analysis 域 |
| **合计** | **54** | | |

---

## 二、材料本构子程序（Material）

### 2.1 UMAT — 用户材料（隐式求解器）

**调用时机**：每个增量步、每个材料积分点（Newton-Raphson 迭代内）

**ABAQUS 接口签名**：
```fortran
SUBROUTINE UMAT(STRESS, STATEV, DDSDDE, SSE, SPD, SCD, RPL, DDSDDT,  &
                DRPLDE, DRPLDT, STRAN, DSTRAN, TIME, DTIME, TEMP,      &
                DTEMP, PREDEF, DPRED, CMNAME, NDI, NSHR, NTENS, NSTATV, &
                PROPS, NPROPS, COORDS, DROT, PNEWDT, CELENT, DFGRD0,    &
                DFGRD1, NOEL, NPT, LAYER, KSPT, KSTEP, KINC)
```

**参数→TYPE 成员名映射表**：

| ABAQUS 参数 | 方向 | 维度 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|------|---------|-------|------|
| `STRESS` | [IN/OUT] | `(NTENS)` | `MD_Mat_Base_State` | `state%stress(1:ntens)` | 柯西应力张量（Voigt 表示）|
| `STATEV` | [IN/OUT] | `(NSTATV)` | `MD_Mat_Base_State` | `state%statev(1:nstatv)` | 解依赖状态变量（SDV）|
| `DDSDDE` | [OUT] | `(NTENS,NTENS)` | `MD_Mat_Base_State` | `state%ddsdde(1:ntens,1:ntens)` | 一致切线刚度（Consistent Tangent）|
| `SSE` | [IN/OUT] | 标量 | `MD_Mat_Base_State` | `state%sse` | 比弹性应变能 |
| `SPD` | [IN/OUT] | 标量 | `MD_Mat_Base_State` | `state%spd` | 比塑性耗散功 |
| `SCD` | [IN/OUT] | 标量 | `MD_Mat_Base_State` | `state%scd` | 比蠕变耗散功 |
| `RPL` | [IN/OUT] | 标量 | `MD_Mat_Base_State` | `state%rpl` | 体积热生成率（热-力耦合）|
| `DDSDDT` | [OUT] | `(NTENS)` | `MD_Mat_Base_State` | `state%ddsddt(1:ntens)` | 应力对温度的变化率 |
| `DRPLDE` | [OUT] | `(NTENS)` | `MD_Mat_Base_State` | `state%drplde(1:ntens)` | RPL 对应变的变化率 |
| `DRPLDT` | [OUT] | 标量 | `MD_Mat_Base_State` | `state%drpldt` | RPL 对温度的变化率 |
| `STRAN` | [IN] | `(NTENS)` | `PH_Mat_Base_Ctx` | `ctx%stran(1:ntens)` | 步末总应变（参考构型）|
| `DSTRAN` | [IN] | `(NTENS)` | `PH_Mat_Base_Ctx` | `ctx%dstran(1:ntens)` | 应变增量（本步）|
| `TIME(1)` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%step_time` | 步内当前时间 |
| `TIME(2)` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%total_time` | 总分析时间 |
| `DTIME` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%dtime` | 时间增量 Δt |
| `TEMP` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%temp` | 步末温度 |
| `DTEMP` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%dtemp` | 温度增量 |
| `PREDEF` | [IN] | `(NPREDF)` | `PH_Mat_Base_Ctx` | `ctx%predef(1:npredf)` | 预定义场变量值 |
| `DPRED` | [IN] | `(NPREDF)` | `PH_Mat_Base_Ctx` | `ctx%dpred(1:npredf)` | 预定义场增量 |
| `CMNAME` | [IN] | `CHAR*80` | `MD_Mat_Base_Desc` | `desc%model_name` | 材料名称（*MATERIAL NAME=）|
| `NDI` | [IN] | 标量 | `PH_Mat_Base_Algo` | `algo%ndi` | 正应力分量数（3D=3）|
| `NSHR` | [IN] | 标量 | `PH_Mat_Base_Algo` | `algo%nshr` | 剪应力分量数（3D=3）|
| `NTENS` | [IN] | 标量 | `PH_Mat_Base_Algo` | `algo%ntens` | 应力/应变分量总数（NDI+NSHR）|
| `NSTATV` | [IN] | 标量 | `PH_Mat_Base_Algo` | `algo%nstatv` | 状态变量个数 |
| `PROPS` | [IN] | `(NPROPS)` | `MD_Mat_Base_Desc` | `desc%props(1:nprops)` | 材料参数数组（*MATERIAL 下的数值）|
| `NPROPS` | [IN] | 标量 | `MD_Mat_Base_Desc` | `desc%nprops` | 材料参数个数 |
| `COORDS` | [IN] | `(3)` | `PH_Mat_Base_Ctx` | `ctx%coords(1:3)` | 积分点当前坐标 |
| `DROT` | [IN] | `(3,3)` | `PH_Mat_Base_Ctx` | `ctx%drot(1:3,1:3)` | 刚体旋转增量矩阵 |
| `PNEWDT` | [OUT] | 标量 | `MD_Mat_Base_State` | `state%pnewdt` | 建议时间步缩减因子（<1 触发缩步）|
| `CELENT` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%celent` | 单元特征长度 |
| `DFGRD0` | [IN] | `(3,3)` | `PH_Mat_Base_Ctx` | `ctx%dfgrd0(1:3,1:3)` | 步初变形梯度 F₀ |
| `DFGRD1` | [IN] | `(3,3)` | `PH_Mat_Base_Ctx` | `ctx%dfgrd1(1:3,1:3)` | 步末变形梯度 F₁ |
| `NOEL` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%elem_id` | 单元编号 |
| `NPT` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%gauss_pt` | 积分点编号（单元内局部）|
| `LAYER` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%layer` | 截面层号（复合截面用）|
| `KSPT` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%kspt` | 厚度方向积分点号 |
| `KSTEP` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%kstep` | 分析步号 |
| `KINC` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%kinc` | 增量步号 |

**Adapter pack 代码示例**：
```fortran
SUBROUTINE UMAT(STRESS, STATEV, DDSDDE, SSE, SPD, SCD, RPL, DDSDDT,  &
                DRPLDE, DRPLDT, STRAN, DSTRAN, TIME, DTIME, TEMP,      &
                DTEMP, PREDEF, DPRED, CMNAME, NDI, NSHR, NTENS, NSTATV, &
                PROPS, NPROPS, COORDS, DROT, PNEWDT, CELENT, DFGRD0,    &
                DFGRD1, NOEL, NPT, LAYER, KSPT, KSTEP, KINC)
  !-- [Adapter 层] ABAQUS 扁平数组 → UFC TYPE 结构体（pack）
  TYPE(MD_Mat_Base_Desc)  :: desc
  TYPE(MD_Mat_Base_State) :: state
  TYPE(PH_Mat_Base_Algo)  :: algo
  TYPE(PH_Mat_Base_Ctx)   :: ctx

  ! [IN] Desc（只读，模型参数）
  desc%model_name       = CMNAME
  desc%props(1:NPROPS)  = PROPS(1:NPROPS)
  desc%nprops           = NPROPS

  ! [IN] Algo（求解控制参数，迭代内只读）
  algo%ndi   = NDI
  algo%nshr  = NSHR
  algo%ntens = NTENS
  algo%nstatv= NSTATV

  ! [IN/OUT] State（增量内读写，输出应力/SDV/切线）
  state%stress(1:NTENS)            = STRESS(1:NTENS)
  state%statev(1:NSTATV)           = STATEV(1:NSTATV)
  state%sse = SSE;  state%spd = SPD;  state%scd = SCD

  ! [IN] Ctx（增量驱动上下文）
  ctx%stran(1:NTENS)  = STRAN(1:NTENS)
  ctx%dstran(1:NTENS) = DSTRAN(1:NTENS)
  ctx%step_time       = TIME(1)
  ctx%total_time      = TIME(2)
  ctx%dtime           = DTIME
  ctx%temp            = TEMP
  ctx%dtemp           = DTEMP
  ctx%dfgrd0(1:3,1:3) = DFGRD0(1:3,1:3)
  ctx%dfgrd1(1:3,1:3) = DFGRD1(1:3,1:3)
  ctx%elem_id = NOEL;  ctx%gauss_pt = NPT
  ctx%kstep   = KSTEP; ctx%kinc     = KINC

  !-- 调用 UFC 内核（不接触 ABAQUS 原始数组）
  CALL PH_Mat_Core_Proc(desc, state, algo, ctx, args)

  !-- [OUT] UFC TYPE → ABAQUS 扁平数组（unpack）
  STRESS(1:NTENS)              = state%stress(1:NTENS)
  STATEV(1:NSTATV)             = state%statev(1:NSTATV)
  DDSDDE(1:NTENS,1:NTENS)      = state%ddsdde(1:NTENS,1:NTENS)
  SSE = state%sse;  SPD = state%spd;  SCD = state%scd
  PNEWDT = state%pnewdt
END SUBROUTINE UMAT
```

---

### 2.2 VUMAT — 用户材料（显式求解器）

**ABAQUS 接口签名**：
```fortran
SUBROUTINE VUMAT(NBLOCK, NDIR, NSHR, NSTATEV, NFIELDV, NPROPS, LANNEAL,  &
                 STEPTIME, TOTALTIME, DT, CMNAME, COORDMP, CHARLENGTH,     &
                 PROPS, DENSITY, STRAININC, RELSPININC, TEMPOLD, STRETCHOLD, &
                 DEFGRADOLD, FIELDOLD, STRESSOLD, STATEOLD, ENERDENS_INELASTIC, &
                 ENERDENS_ELASTIC, TEMPNEW, STRETCHNEW, DEFGRADNEW, FIELDNEW, &
                 STRESSNEW, STATENEW, ENERDENS_INELASTIC_NEW, ENERDENS_ELASTIC_NEW)
```

| ABAQUS 参数 | 方向 | 维度 | UFC TYPE | 成员名 |
|------------|:----:|------|---------|-------|
| `NBLOCK` | [IN] | 标量 | `PH_Mat_Base_Algo` | `algo%nblock` |
| `NDIR` | [IN] | 标量 | `PH_Mat_Base_Algo` | `algo%ndi` |
| `NSHR` | [IN] | 标量 | `PH_Mat_Base_Algo` | `algo%nshr` |
| `NSTATEV` | [IN] | 标量 | `PH_Mat_Base_Algo` | `algo%nstatv` |
| `NPROPS` | [IN] | 标量 | `MD_Mat_Base_Desc` | `desc%nprops` |
| `DT` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%dtime` |
| `STEPTIME` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%step_time` |
| `TOTALTIME` | [IN] | 标量 | `PH_Mat_Base_Ctx` | `ctx%total_time` |
| `PROPS` | [IN] | `(NPROPS)` | `MD_Mat_Base_Desc` | `desc%props(1:nprops)` |
| `STRAININC` | [IN] | `(NBLOCK,NTENS)` | `PH_Mat_Base_Ctx` | `ctx%dstran(1:ntens)` |
| `DEFGRADOLD` | [IN] | `(NBLOCK,9)` | `PH_Mat_Base_Ctx` | `ctx%dfgrd0(1:3,1:3)` |
| `DEFGRADNEW` | [IN] | `(NBLOCK,9)` | `PH_Mat_Base_Ctx` | `ctx%dfgrd1(1:3,1:3)` |
| `TEMPOLD` | [IN] | `(NBLOCK)` | `PH_Mat_Base_Ctx` | `ctx%temp` |
| `TEMPNEW` | [IN] | `(NBLOCK)` | `PH_Mat_Base_Ctx` | `ctx%temp_new` |
| `STRESSOLD` | [IN] | `(NBLOCK,NTENS)` | `MD_Mat_Base_State` | `state%stress(1:ntens)` |
| `STATENEW` | [OUT] | `(NBLOCK,NSTATEV)` | `MD_Mat_Base_State` | `state%statev(1:nstatv)` |
| `STRESSNEW` | [OUT] | `(NBLOCK,NTENS)` | `MD_Mat_Base_State` | `state%stress(1:ntens)` |
| `DENSITY` | [IN] | `(NBLOCK)` | `MD_Mat_Base_Desc` | `desc%density` |
| `CHARLENGTH` | [IN] | `(NBLOCK)` | `PH_Mat_Base_Ctx` | `ctx%celent` |
| `COORDMP` | [IN] | `(NBLOCK,3)` | `PH_Mat_Base_Ctx` | `ctx%coords(1:3)` |

---

### 2.3 UMATHT — 热传导材料

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|---------|-------|------|
| `U` | [IN/OUT] | `MD_Mat_Base_State` | `state%internal_energy` | 比内能 |
| `DUDT` | [OUT] | `MD_Mat_Base_State` | `state%dudt` | 比内能对温度导数 |
| `FLUX(3)` | [OUT] | `MD_Mat_Base_State` | `state%flux(1:3)` | 热流矢量 |
| `DFDT(3)` | [OUT] | `MD_Mat_Base_State` | `state%dfdt(1:3)` | 热流对温度梯度导数 |
| `DFDG(3,3)` | [OUT] | `MD_Mat_Base_State` | `state%dfdg(1:3,1:3)` | 热流对温度梯度的张量导数 |
| `TEMP` | [IN] | `PH_Mat_Base_Ctx` | `ctx%temp` | 当前温度 |
| `DTEMP` | [IN] | `PH_Mat_Base_Ctx` | `ctx%dtemp` | 温度增量 |
| `DTEMDX(3)` | [IN] | `PH_Mat_Base_Ctx` | `ctx%dtemdx(1:3)` | 温度梯度 |
| `DDTEMDX(3)` | [IN] | `PH_Mat_Base_Ctx` | `ctx%ddtemdx(1:3)` | 温度梯度增量 |
| `TIME(2)` | [IN] | `PH_Mat_Base_Ctx` | `ctx%step_time / ctx%total_time` | 时间 |
| `DTIME` | [IN] | `PH_Mat_Base_Ctx` | `ctx%dtime` | 时间增量 |
| `STATEV` | [IN/OUT] | `MD_Mat_Base_State` | `state%statev(1:nstatv)` | 状态变量 |
| `PROPS` | [IN] | `MD_Mat_Base_Desc` | `desc%props(1:nprops)` | 材料参数 |

---

### 2.4 CREEP — 蠕变本构

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `CREEP(3)` | [OUT] | `MD_Mat_Base_State` | `state%creep_rate(1:3)` |
| `STATEV` | [IN/OUT] | `MD_Mat_Base_State` | `state%statev(1:nstatv)` |
| `PROPS` | [IN] | `MD_Mat_Base_Desc` | `desc%props(1:nprops)` |
| `TIME(2)` | [IN] | `PH_Mat_Base_Ctx` | `ctx%step_time / ctx%total_time` |
| `DTIME` | [IN] | `PH_Mat_Base_Ctx` | `ctx%dtime` |
| `TEMP` | [IN] | `PH_Mat_Base_Ctx` | `ctx%temp` |
| `DTEMP` | [IN] | `PH_Mat_Base_Ctx` | `ctx%dtemp` |
| `SEQV` | [IN] | `PH_Mat_Base_Ctx` | `ctx%seqv` |

---

### 2.5 UHARD — 用户硬化

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `SYIELD` | [OUT] | `MD_Mat_Base_State` | `state%yield_stress` |
| `HARD(3)` | [OUT] | `MD_Mat_Base_State` | `state%hard(1:3)` |
| `STATEV` | [IN] | `MD_Mat_Base_State` | `state%statev(1:nstatv)` |
| `PROPS` | [IN] | `MD_Mat_Base_Desc` | `desc%props(1:nprops)` |
| `TEMP` | [IN] | `PH_Mat_Base_Ctx` | `ctx%temp` |

---

### 2.6 UHYPER — 用户超弹性

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `U(2)` | [OUT] | `MD_Mat_Base_State` | `state%strain_energy_u(1:2)` |
| `UI1(3)` | [OUT] | `MD_Mat_Base_State` | `state%ui1(1:3)` |
| `UI2(6)` | [OUT] | `MD_Mat_Base_State` | `state%ui2(1:6)` |
| `TEMP` | [IN] | `PH_Mat_Base_Ctx` | `ctx%temp` |
| `NOEL` | [IN] | `PH_Mat_Base_Ctx` | `ctx%elem_id` |

---

### 2.7 USDFLD — 用户场变量定义（材料域）

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `FIELD` | [IN/OUT] | `MD_Mat_Base_State` | `state%field(1:nfield)` |
| `STATEV` | [IN/OUT] | `MD_Mat_Base_State` | `state%statev(1:nstatv)` |
| `PROPS` | [IN] | `MD_Mat_Base_Desc` | `desc%props(1:nprops)` |
| `STRESS` | [IN] | `MD_Mat_Base_State` | `state%stress(1:ntens)` |

---

### 2.8 其他材料子程序汇总

| 子程序 | 关键 OUT 参数→State 成员 | 关键 IN 参数→Ctx/Desc 成员 |
|--------|------------------------|--------------------------|
| `UMULLINS` | `state%etha / state%uetha` | `ctx%temp / desc%props` |
| `UCREEPNETWORK` | `state%creep_rate(1:3)` | `ctx%temp / ctx%dtime` |
| `UTRS` | `state%ashift` | `ctx%temp / desc%props` |
| `UHYPEL` | `state%ddsdde(1:6,1:6)` | `ctx%stran(1:6)` |
| `VUHARD` | `state%yield_stress(1:nblock)` | `ctx%temp(1:nblock)` |
| `UEXPAN` | `state%expan(1:ntens)` | `ctx%temp / ctx%dtemp` |
| `UFIELD` | `state%field(1:nfield)` | `ctx%coords(1:3)` |

---

## 三、用户单元子程序（Element）

### 3.1 UEL — 用户单元（隐式求解器）

**ABAQUS 接口签名**：
```fortran
SUBROUTINE UEL(RHS, AMATRX, SVARS, ENERGY, NDOFEL, NRHS, NSVARS,    &
               PROPS, NPROPS, COORDS, MCRD, NNODE, U, DU, V, A,       &
               JTYPE, TIME, DTIME, KSTEP, KINC, JELEM, PARAMS,        &
               NDLOAD, JDLTYP, ADLMAG, PREDEF, NPREDF, LFLAGS,        &
               MLVARX, DDLMAG, MDLOAD, PNEWDT, JPROPS, NJPROP, PERIOD)
```

| ABAQUS 参数 | 方向 | 维度 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|------|---------|-------|------|
| `RHS` | [OUT] | `(MLVARX,NRHS)` | `PH_Elem_Base_State` | `state%rhs(1:ndofel,1:nrhs)` | 残差向量 |
| `AMATRX` | [OUT] | `(NDOFEL,NDOFEL)` | `PH_Elem_Base_State` | `state%amatrx(1:ndofel,1:ndofel)` | 单元矩阵（刚度/质量/阻尼）|
| `SVARS` | [IN/OUT] | `(NSVARS)` | `PH_Elem_Base_State` | `state%svars(1:nsvars)` | 单元状态变量 |
| `ENERGY` | [IN/OUT] | `(8)` | `PH_Elem_Base_State` | `state%energy(1:8)` | 能量数组 |
| `NDOFEL` | [IN] | 标量 | `MD_Elem_Base_Desc` | `desc%ndofel` | 单元总自由度数 |
| `NSVARS` | [IN] | 标量 | `MD_Elem_Base_Desc` | `desc%nsvars` | 状态变量数 |
| `PROPS` | [IN] | `(NPROPS)` | `MD_Elem_Base_Desc` | `desc%props(1:nprops)` | 单元属性数组 |
| `NPROPS` | [IN] | 标量 | `MD_Elem_Base_Desc` | `desc%nprops` | 属性数 |
| `COORDS` | [IN] | `(MCRD,NNODE)` | `PH_Elem_Base_Ctx` | `ctx%coords(1:mcrd,1:nnode)` | 节点坐标 |
| `MCRD` | [IN] | 标量 | `MD_Elem_Base_Desc` | `desc%mcrd` | 坐标维度 |
| `NNODE` | [IN] | 标量 | `MD_Elem_Base_Desc` | `desc%nnode` | 节点数 |
| `U` | [IN] | `(MLVARX)` | `PH_Elem_Base_Ctx` | `ctx%u(1:ndofel)` | 当前位移 |
| `DU` | [IN] | `(MLVARX,NRHS)` | `PH_Elem_Base_Ctx` | `ctx%du(1:ndofel,1:nrhs)` | 位移增量 |
| `V` | [IN] | `(NDOFEL)` | `PH_Elem_Base_Ctx` | `ctx%v(1:ndofel)` | 速度 |
| `A` | [IN] | `(NDOFEL)` | `PH_Elem_Base_Ctx` | `ctx%a(1:ndofel)` | 加速度 |
| `JTYPE` | [IN] | 标量 | `MD_Elem_Base_Desc` | `desc%elem_type` | 单元类型标识 |
| `TIME(2)` | [IN] | — | `PH_Elem_Base_Ctx` | `ctx%step_time / ctx%total_time` | 时间 |
| `DTIME` | [IN] | 标量 | `PH_Elem_Base_Ctx` | `ctx%dtime` | 时间增量 |
| `KSTEP` | [IN] | 标量 | `PH_Elem_Base_Ctx` | `ctx%kstep` | 分析步号 |
| `KINC` | [IN] | 标量 | `PH_Elem_Base_Ctx` | `ctx%kinc` | 增量步号 |
| `JELEM` | [IN] | 标量 | `PH_Elem_Base_Ctx` | `ctx%elem_id` | 单元号 |
| `LFLAGS` | [IN] | `(MLVARX)` | `PH_Elem_Base_Ctx` | `ctx%lflags(1:mlvarx)` | 求解标志数组 |
| `PNEWDT` | [OUT] | 标量 | `PH_Elem_Base_State` | `state%pnewdt` | 建议步长缩减因子 |
| `JPROPS` | [IN] | `(NJPROP)` | `MD_Elem_Base_Desc` | `desc%jprops(1:njprop)` | 整型属性数组 |

---

### 3.2 VUEL — 用户单元（显式求解器）

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `RHS` | [OUT] | `PH_Elem_Base_State` | `state%rhs(1:ndofel,1:nrhs)` |
| `SVARS` | [IN/OUT] | `PH_Elem_Base_State` | `state%svars(1:nsvars)` |
| `ENERGY` | [IN/OUT] | `PH_Elem_Base_State` | `state%energy(1:8)` |
| `COORDS` | [IN] | `PH_Elem_Base_Ctx` | `ctx%coords(1:mcrd,1:nnode)` |
| `U` | [IN] | `PH_Elem_Base_Ctx` | `ctx%u(1:ndofel)` |
| `DU` | [IN] | `PH_Elem_Base_Ctx` | `ctx%du(1:ndofel,1:nrhs)` |
| `DTIME` | [IN] | `PH_Elem_Base_Ctx` | `ctx%dtime` |
| `JELEM` | [IN] | `PH_Elem_Base_Ctx` | `ctx%elem_id` |

---

## 四、载荷分布子程序（Load）

### 4.1 DLOAD — 分布载荷

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|---------|-------|------|
| `F` | [OUT] | `PH_Load_Base_State` | `state%load_value` | 载荷强度（标量）|
| `COORDS(3)` | [IN] | `PH_Load_Base_Ctx` | `ctx%coords(1:3)` | 积分点坐标 |
| `TIME(2)` | [IN] | `PH_Load_Base_Ctx` | `ctx%step_time / ctx%total_time` | 时间 |
| `DTIME` | [IN] | `PH_Load_Base_Ctx` | `ctx%dtime` | 时间增量 |
| `KSTEP` | [IN] | `PH_Load_Base_Ctx` | `ctx%kstep` | 步号 |
| `KINC` | [IN] | `PH_Load_Base_Ctx` | `ctx%kinc` | 增量步号 |
| `NOEL` | [IN] | `PH_Load_Base_Ctx` | `ctx%elem_id` | 单元号 |
| `NPT` | [IN] | `PH_Load_Base_Ctx` | `ctx%gauss_pt` | 积分点号 |
| `LAYER` | [IN] | `PH_Load_Base_Ctx` | `ctx%layer` | 层号 |
| `KSPT` | [IN] | `PH_Load_Base_Ctx` | `ctx%kspt` | 厚度积分点 |
| `JLTYP` | [IN] | `MD_Load_Base_Desc` | `desc%load_type` | 载荷类型码 |
| `TEMP` | [IN] | `PH_Load_Base_Ctx` | `ctx%temp` | 温度 |
| `PROPS` | [IN] | `MD_Load_Base_Desc` | `desc%props(1:nprops)` | 载荷参数 |

---

### 4.2 FILM — 对流换热（膜系数）

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `H` | [OUT] | `PH_Load_Base_State` | `state%film_h` |
| `SINK` | [OUT] | `PH_Load_Base_State` | `state%film_sink` |
| `COORDS(3)` | [IN] | `PH_Load_Base_Ctx` | `ctx%coords(1:3)` |
| `TIME(2)` | [IN] | `PH_Load_Base_Ctx` | `ctx%step_time / ctx%total_time` |
| `TEMP` | [IN] | `PH_Load_Base_Ctx` | `ctx%temp` |
| `JLTYP` | [IN] | `MD_Load_Base_Desc` | `desc%load_type` |

---

### 4.3 HETVAL — 热生成

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `FLUX(2)` | [OUT] | `PH_Load_Base_State` | `state%heat_flux(1:2)` |
| `TIME(2)` | [IN] | `PH_Load_Base_Ctx` | `ctx%step_time / ctx%total_time` |
| `DTIME` | [IN] | `PH_Load_Base_Ctx` | `ctx%dtime` |
| `TEMP` | [IN] | `PH_Load_Base_Ctx` | `ctx%temp` |
| `DTEMP` | [IN] | `PH_Load_Base_Ctx` | `ctx%dtemp` |
| `STATEV` | [IN/OUT] | `MD_Mat_Base_State` | `state%statev(1:nstatv)` |

---

## 五、边界条件子程序（BC）

### 5.1 DISP — 规定位移/转角边界

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|---------|-------|------|
| `U` | [OUT] | `PH_BC_Base_State` | `state%bc_value` | 规定位移值 |
| `KSTEP` | [IN] | `PH_BC_Base_Ctx` | `ctx%kstep` | 步号 |
| `KINC` | [IN] | `PH_BC_Base_Ctx` | `ctx%kinc` | 增量步号 |
| `TIME(2)` | [IN] | `PH_BC_Base_Ctx` | `ctx%step_time / ctx%total_time` | 时间 |
| `NODE` | [IN] | `PH_BC_Base_Ctx` | `ctx%node_id` | 节点号 |
| `NOEL` | [IN] | `PH_BC_Base_Ctx` | `ctx%elem_id` | 单元号（接触面BC） |
| `JDOF` | [IN] | `PH_BC_Base_Ctx` | `ctx%dof_number` | 自由度编号 |
| `COORDS(3)` | [IN] | `PH_BC_Base_Ctx` | `ctx%coords(1:3)` | 节点坐标 |

---

### 5.2 UTEMP — 规定温度边界

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `TEMP` | [OUT] | `PH_BC_Base_State` | `state%bc_value` |
| `TIME(2)` | [IN] | `PH_BC_Base_Ctx` | `ctx%step_time / ctx%total_time` |
| `NODE` | [IN] | `PH_BC_Base_Ctx` | `ctx%node_id` |
| `COORDS(3)` | [IN] | `PH_BC_Base_Ctx` | `ctx%coords(1:3)` |

---

## 六、接触摩擦子程序（Contact）

### 6.1 UINTER — 用户接触本构（隐式）

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|---------|-------|------|
| `STRESS(2)` | [IN/OUT] | `PH_Cont_Base_State` | `state%contact_stress(1:2)` | 接触应力（法向/切向）|
| `DDSDDR(2,2)` | [OUT] | `PH_Cont_Base_State` | `state%ddsddr(1:2,1:2)` | 接触切线刚度 |
| `SLDIR(3)` | [OUT] | `PH_Cont_Base_State` | `state%slip_dir(1:3)` | 滑移方向向量 |
| `STATEV` | [IN/OUT] | `PH_Cont_Base_State` | `state%statev(1:nstatv)` | 接触状态变量 |
| `GAP` | [IN] | `PH_Cont_Base_Ctx` | `ctx%gap` | 接触间隙（负值=穿透）|
| `SLIP` | [IN] | `PH_Cont_Base_Ctx` | `ctx%slip` | 相对滑移量 |
| `PROPS` | [IN] | `MD_Cont_Base_Desc` | `desc%props(1:nprops)` | 接触属性 |
| `COORDS(3)` | [IN] | `PH_Cont_Base_Ctx` | `ctx%coords(1:3)` | 接触点坐标 |
| `TEMP` | [IN] | `PH_Cont_Base_Ctx` | `ctx%temp` | 温度 |
| `KSTEP` | [IN] | `PH_Cont_Base_Ctx` | `ctx%kstep` | 步号 |
| `KINC` | [IN] | `PH_Cont_Base_Ctx` | `ctx%kinc` | 增量步号 |

---

### 6.2 UFRIC — 用户摩擦

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `FRICTDDSDDR(2,2)` | [OUT] | `PH_Cont_Base_State` | `state%fric_ddsddr(1:2,1:2)` |
| `TAUEQV` | [OUT] | `PH_Cont_Base_State` | `state%fric_tau_eqv` |
| `SLIP(2)` | [IN] | `PH_Cont_Base_Ctx` | `ctx%slip(1:2)` |
| `PRESS` | [IN] | `PH_Cont_Base_Ctx` | `ctx%contact_press` |
| `TEMP` | [IN] | `PH_Cont_Base_Ctx` | `ctx%temp` |
| `PROPS` | [IN] | `MD_Cont_Base_Desc` | `desc%props(1:nprops)` |

---

### 6.3 GAPCON — 接触导热

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `GCON(3)` | [OUT] | `PH_Cont_Base_State` | `state%gap_conductance(1:3)` |
| `DGDTEMP(2,3)` | [OUT] | `PH_Cont_Base_State` | `state%dgdtemp(1:2,1:3)` |
| `GAP` | [IN] | `PH_Cont_Base_Ctx` | `ctx%gap` |
| `TEMP(2)` | [IN] | `PH_Cont_Base_Ctx` | `ctx%temp_pair(1:2)` |
| `PROPS` | [IN] | `MD_Cont_Base_Desc` | `desc%props(1:nprops)` |

---

## 七、约束子程序（Constraint）

### 7.1 MPC — 多点约束

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|---------|-------|------|
| `UE` | [IN/OUT] | `PH_Cons_Base_State` | `state%ue(1:n)` | 约束/驱动自由度集 |
| `A` | [OUT] | `PH_Cons_Base_State` | `state%constraint_A` | 约束方程矩阵 |
| `JDOF` | [IN] | `PH_Cons_Base_Ctx` | `ctx%jdof` | 约束自由度号 |
| `MDOF` | [IN] | `PH_Cons_Base_Ctx` | `ctx%mdof` | 主/驱动自由度号 |
| `N` | [IN] | `PH_Cons_Base_Algo` | `algo%n_dof` | 约束方程数 |
| `KSTEP` | [IN] | `PH_Cons_Base_Ctx` | `ctx%kstep` | 步号 |
| `KINC` | [IN] | `PH_Cons_Base_Ctx` | `ctx%kinc` | 增量步号 |
| `TIME(2)` | [IN] | `PH_Cons_Base_Ctx` | `ctx%step_time / ctx%total_time` | 时间 |
| `NODE` | [IN] | `PH_Cons_Base_Ctx` | `ctx%node_id` | 约束节点号 |

---

### 7.2 UMESHMOTION — 用户网格移动（自适应网格）

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `UREF(3)` | [IN/OUT] | `PH_Cons_Base_State` | `state%mesh_disp(1:3)` |
| `COORDS(3)` | [IN] | `PH_Cons_Base_Ctx` | `ctx%coords(1:3)` |
| `TIME(2)` | [IN] | `PH_Cons_Base_Ctx` | `ctx%step_time / ctx%total_time` |
| `DTIME` | [IN] | `PH_Cons_Base_Ctx` | `ctx%dtime` |

---

## 八、场变量子程序（Field）

### 8.1 SDVINI — 状态变量初始化

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|---------|-------|------|
| `STATEV` | [OUT] | `MD_Mat_Base_State` | `state%statev(1:nstatv)` | 初始状态变量值 |
| `COORDS(3)` | [IN] | `PH_Field_Base_Ctx` | `ctx%coords(1:3)` | 材料点坐标 |
| `NSTATV` | [IN] | `PH_Mat_Base_Algo` | `algo%nstatv` | 状态变量数 |
| `NCRDS` | [IN] | `PH_Field_Base_Ctx` | `ctx%ncrds` | 坐标维度 |
| `NOEL` | [IN] | `PH_Field_Base_Ctx` | `ctx%elem_id` | 单元号 |
| `NPT` | [IN] | `PH_Field_Base_Ctx` | `ctx%gauss_pt` | 积分点号 |
| `LAYER` | [IN] | `PH_Field_Base_Ctx` | `ctx%layer` | 层号 |
| `KSPT` | [IN] | `PH_Field_Base_Ctx` | `ctx%kspt` | 厚度积分点 |

---

### 8.2 SIGINI — 初始应力场

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 |
|------------|:----:|---------|-------|
| `SIGMA(6)` | [OUT] | `MD_Mat_Base_State` | `state%stress(1:ntens)` |
| `COORDS(3)` | [IN] | `PH_Field_Base_Ctx` | `ctx%coords(1:3)` |
| `NTENS` | [IN] | `PH_Mat_Base_Algo` | `algo%ntens` |
| `NOEL` | [IN] | `PH_Field_Base_Ctx` | `ctx%elem_id` |
| `NPT` | [IN] | `PH_Field_Base_Ctx` | `ctx%gauss_pt` |

---

## 九、分析控制子程序（Analysis）

### 9.1 UAMP — 幅值曲线（隐式）

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|---------|-------|------|
| `AMPVAL` | [OUT] | `PH_Amp_Base_State` | `state%amp_value` | 幅值输出值 |
| `AMPDER` | [OUT] | `PH_Amp_Base_State` | `state%amp_deriv` | 幅值对时间的导数 |
| `AMPDBLT` | [OUT] | `PH_Amp_Base_State` | `state%amp_dblderiv` | 幅值对时间的二阶导 |
| `TIME` | [IN] | `PH_Amp_Base_Ctx` | `ctx%total_time` | 总分析时间 |
| `DTIME` | [IN] | `PH_Amp_Base_Ctx` | `ctx%dtime` | 时间增量 |
| `KSTEP` | [IN] | `PH_Amp_Base_Ctx` | `ctx%kstep` | 步号 |
| `KINC` | [IN] | `PH_Amp_Base_Ctx` | `ctx%kinc` | 增量步号 |
| `NSVARS` | [IN] | `MD_Amp_Base_Desc` | `desc%nsvars` | 状态变量数 |
| `SVARS` | [IN/OUT] | `PH_Amp_Base_State` | `state%statev(1:nsvars)` | 幅值状态变量 |

---

### 9.2 UEXTERNALDB — 外部数据库接口

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|---------|-------|------|
| `LOP` | [IN] | `RT_Analysis_Ctx` | `ctx%db_operation` | 操作码（0=开始,1=步开始,2=步结束,3=结束）|
| `LRESTART` | [IN] | `RT_Analysis_Ctx` | `ctx%is_restart` | 是否重启分析 |
| `TIME(2)` | [IN] | `RT_Analysis_Ctx` | `ctx%step_time / ctx%total_time` | 时间 |
| `DTIME` | [IN] | `RT_Analysis_Ctx` | `ctx%dtime` | 时间增量 |
| `KSTEP` | [IN] | `RT_Analysis_Ctx` | `ctx%kstep` | 步号 |
| `KINC` | [IN] | `RT_Analysis_Ctx` | `ctx%kinc` | 增量步号 |

---

### 9.3 UVARM — 用户输出变量

| ABAQUS 参数 | 方向 | UFC TYPE | 成员名 | 描述 |
|------------|:----:|---------|-------|------|
| `UVAR(NUVARM)` | [OUT] | `RT_Output_Ctx` | `ctx%uvar(1:nuvarm)` | 用户定义输出变量数组 |
| `NUVARM` | [IN] | `RT_Output_Ctx` | `ctx%nuvarm` | 输出变量数 |
| `STRESS(6)` | [IN] | `MD_Mat_Base_State` | `state%stress(1:ntens)` | 应力 |
| `STATEV` | [IN] | `MD_Mat_Base_State` | `state%statev(1:nstatv)` | 状态变量 |
| `COORDS(3)` | [IN] | `PH_Mat_Base_Ctx` | `ctx%coords(1:3)` | 积分点坐标 |
| `TEMP` | [IN] | `PH_Mat_Base_Ctx` | `ctx%temp` | 温度 |
| `NOEL` | [IN] | `PH_Mat_Base_Ctx` | `ctx%elem_id` | 单元号 |
| `NPT` | [IN] | `PH_Mat_Base_Ctx` | `ctx%gauss_pt` | 积分点号 |

---

## 十、全局参数名映射速查表

### 10.1 高频参数（跨子程序通用）

| ABAQUS 原始参数名 | 说明 | UFC Desc 成员 | UFC State 成员 | UFC Ctx 成员 |
|----------------|-----|-------------|--------------|------------|
| `PROPS(NPROPS)` | 材料/单元参数数组 | `desc%props(1:nprops)` | — | — |
| `NPROPS` | 参数数量 | `desc%nprops` | — | — |
| `STATEV(NSTATV)` | 状态变量数组 | — | `state%statev(1:nstatv)` | — |
| `NSTATV` | 状态变量数量 | — | — | `algo%nstatv` |
| `STRESS(NTENS)` | 应力 Voigt 向量 | — | `state%stress(1:ntens)` | — |
| `DDSDDE(NTENS,NTENS)` | 切线刚度矩阵 | — | `state%ddsdde(1:ntens,1:ntens)` | — |
| `NTENS` | 应力分量总数 | — | — | `algo%ntens` |
| `NDI` | 正应力分量数 | — | — | `algo%ndi` |
| `NSHR` | 剪应力分量数 | — | — | `algo%nshr` |
| `DSTRAN(NTENS)` | 应变增量 | — | — | `ctx%dstran(1:ntens)` |
| `DFGRD1(3,3)` | 步末变形梯度 F₁ | — | — | `ctx%dfgrd1(1:3,1:3)` |
| `DFGRD0(3,3)` | 步初变形梯度 F₀ | — | — | `ctx%dfgrd0(1:3,1:3)` |
| `TIME(1)` | 步内当前时间 | — | — | `ctx%step_time` |
| `TIME(2)` | 总分析时间 | — | — | `ctx%total_time` |
| `DTIME` | 时间增量 | — | — | `ctx%dtime` |
| `TEMP` | 当前温度 | — | — | `ctx%temp` |
| `DTEMP` | 温度增量 | — | — | `ctx%dtemp` |
| `COORDS(3)` | 材料点/积分点坐标 | — | — | `ctx%coords(1:3)` |
| `NOEL` / `JELEM` | 单元号 | — | — | `ctx%elem_id` |
| `NPT` | 积分点号 | — | — | `ctx%gauss_pt` |
| `KSTEP` | 分析步号 | — | — | `ctx%kstep` |
| `KINC` | 增量步号 | — | — | `ctx%kinc` |
| `LAYER` | 截面层号 | — | — | `ctx%layer` |
| `KSPT` | 厚度方向积分点 | — | — | `ctx%kspt` |
| `PNEWDT` | 建议步长缩减因子 | — | `state%pnewdt` | — |
| `CMNAME` | 材料/单元名称 | `desc%model_name` | — | — |

### 10.2 参数归类规则（快速判断）

```
参数归类决策树：
  IF 参数在分析前就确定（材料常数/几何参数）→ Desc 成员
  ELSE IF 参数在热路径更新（应力/SDV/刚度）   → State 成员
  ELSE IF 参数控制求解算法（NTENS/迭代参数）   → Algo 成员
  ELSE IF 参数每增量步变化（应变增量/温度/时间）→ Ctx 成员
```

---

<!-- 版本历史 -->
<!-- v1.0 (2026-04-13) 初始版本，覆盖54个用户子程序的完整参数映射 -->
