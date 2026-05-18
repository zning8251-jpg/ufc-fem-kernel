# Element 域功能模块清单 (Domain Module Inventory)

**路径**: UFC/REPORTS/Element_Domain_Inventory.md
**对齐规范**: REPORT_Naming_Unified_Spec.md (域缩=Elem, 层缀=MD/PH/RT)
**源文档**: Element_L3L4L5_four_type_UEL_discussion_synthesis.md, Element_Procedure_Algorithm.md, Procedure_Pointer_Inventory.md

---

## 1. 域简述

| 属性 | 值 |
|------|-----|
| **域柱类型** | 全贯通域柱 (P2) |
| **域缩** | Elem |
| **层覆盖** | L3_MD (模型定义), L4_PH (物理内核), L5_RT (运行时编排) |
| **功能** | 单元类型定义、形函数、积分、Ke/Re计算、UEL封装 |
| **源手册** | Abaqus ANALYSIS_1 (Elements Part I) + USER.pdf (UEL/VUEL) |

## 2. 四型结构总览

`mermaid
graph TB
    subgraph L3_MD[L3_MD - Model Definition (SSOT)]
        MD_Elem_Desc["MD_Elem_Desc<br/>族 Desc: Solid3D/Shell/Beam/...<br/>UEL Desc: jtype/nprops/props"]
        MD_Elem_State["MD_Elem_State<br/>轻量标志<br/>initialized, stiffness_built"]
        MD_Elem_Algo["MD_Elem_Algo<br/>积分阶数/沙漏控制<br/>nlgeom 开关"]
        MD_Elem_Ctx["MD_Elem_Ctx<br/>配置查询"]
    end
    subgraph L4_PH[L4_PH - Physics Kernel (Hot Path)]
        PH_Elem_Domain["PH_Elem_Domain<br/>四型域容器"]
        PH_Elem_Desc["PH_Elem_Desc + 辅<br/>Cfg_Init(族/维度)"]
        PH_Elem_State["PH_Elem_State + 辅<br/>Lcl_Comp(收敛标志)"]
        PH_Elem_Algo["PH_Elem_Algo + 辅<br/>Stp_Ctl / Stp_Ctl_Dyn<br/>integrator PTR"]
        PH_Elem_Ctx["PH_Elem_Ctx + 辅<br/>Itr_Asm(当前IP/Jacobian)<br/>Lcl_Comp(u/du/形函数)<br/>Lcl_Evo(Ke/Re)"]
    end
    subgraph L5_RT[L5_RT - Runtime Orchestration]
        RT_Elem_Dispatcher["RT_Elem_Dispatcher<br/>族级路由"]
        RT_Elem_UEL_API["RT_Elem_UEL_API<br/>UEL-A / UEL-B"]
    end
    L3_MD -->|Populate| L4_PH
    L4_PH -->|Dispatch| L5_RT
`

## 3. 功能模块清单

### 3.1 L3_MD (模型定义层)

| 文件 | 模块角色 | 模块名 | 关键子程序 | 接口 | 状态 |
|------|---------|--------|-----------|------|------|
| MD_Elem_Def.f90 | Def | MD_Elem_Def | CreateElemDesc, GetNDims | — | EXIST |
| MD_Elem_Reg.f90 | Reg | MD_Elem_Registry | RegisterFamily(22族), Lookup | — | EXIST |
| MD_Elem_Solid3D_Def.f90 | Def | MD_Elem_Solid3D_Def | SetSolid3DProps | EXTENDS MD_Elem_Desc | EXIST |
| MD_Elem_Shell_Def.f90 | Def | MD_Elem_Shell_Def | SetShellProps | EXTENDS MD_Elem_Desc | EXIST |
| MD_Elem_Beam_Def.f90 | Def | MD_Elem_Beam_Def | SetBeamProps | EXTENDS MD_Elem_Desc | EXIST |
| MD_Elem_Truss_Def.f90 | Def | MD_Elem_Truss_Def | SetTrussProps | EXTENDS MD_Elem_Desc | EXIST |
| MD_Elem_Mass_Def.f90 | Def | MD_Elem_Mass_Def | SetMassProps | EXTENDS MD_Elem_Desc | EXIST |
| MD_Elem_UEL_Def.f90 | Def | MD_Elem_UEL_Def | SetUELParams(jtype,nprops) | EXTENDS MD_Elem_Desc | EXIST |
| MD_ElemPH_Brg.f90 | Brg | MD_ElemPH_Brg | PopulateL4, FillFromDesc | — | EXIST |

### 3.2 L4_PH (物理内核层)

| 文件 | 模块角色 | 模块名 | 关键子程序 | 接口 | 状态 |
|------|---------|--------|-----------|------|------|
| PH_Elem_Def.f90 | Def | PH_Elem_Def | Domain: desc/state/algo/ctx | PH_Elem_* TYPE | EXIST |
| PH_Elem_Integrator_Ifc.f90 | Ifc | PH_Elem_Integrator_Ifc | — | ABSTRACT INTERFACE | EXIST |
| PH_Elem_Domain_Mgr.f90 | Mgr | PH_Elem_Domain_Mgr | InitDomain, AllocState | — | EXIST |
| PH_Elem_Core_Arg.f90 | Arg | PH_Elem_Core_Arg | — | PH_Elem_Core_Arg TYPE | EXIST |
| PH_Elem_Solid3D_Integrate.f90 | Proc | PH_Elem_Solid3D_Integrate | Ke/Re 计算 | BIND integrator PTR | EXIST |
| PH_Elem_Shell_Integrate.f90 | Proc | PH_Elem_Shell_Integrate | Ke/Re 计算 | BIND integrator PTR | EXIST |
| PH_Elem_Beam_Integrate.f90 | Proc | PH_Elem_Beam_Integrate | Ke/Re 计算 | BIND integrator PTR | EXIST |
| PH_Elem_MaterialRoute.f90 | Proc | PH_Elem_MaterialRoute | Material路由(IP环) | — | EXIST |
| PH_Elem_ShapeFunc_Library.f90 | Svc | PH_Elem_ShapeFunc | EvalShape, EvalGradShape | — | EXIST |
| PH_UEL_Def.f90 | Def | PH_UEL_Def | UEL Context, UEL Hook | PH_UEL_Context | ACTIVE |

### 3.3 L5_RT (运行时层)

| 文件 | 模块角色 | 模块名 | 关键子程序 | 接口 | 状态 |
|------|---------|--------|-----------|------|------|
| RT_Elem_Def.f90 | Def | RT_Elem_Def | RT_Elem_Algo | — | EXIST |
| RT_Elem_Dispatcher.f90 | Mgr | RT_Elem_Dispatcher | DispatchByFamily | — | EXIST |
| RT_Elem_Brg.f90 | Brg | RT_Elem_Brg | MakeCtx | — | EXIST |

## 4. 关键子程序签名

### 4.1 积分器抽象接口

`ortran
ABSTRACT INTERFACE
  SUBROUTINE PH_Elem_Integrator_Ifc(desc, state, algo, ctx, args)
    USE IF_Prec, ONLY: wp
    IMPORT :: PH_Elem_Desc, PH_Elem_State, PH_Elem_Algo, PH_Elem_Ctx, PH_Elem_Core_Arg
    TYPE(PH_Elem_Desc),    INTENT(IN)    :: desc
    TYPE(PH_Elem_State),   INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo),    INTENT(IN)    :: algo
    TYPE(PH_Elem_Ctx),     INTENT(IN)    :: ctx
    TYPE(PH_Elem_Core_Arg),INTENT(INOUT) :: args
  END SUBROUTINE
END INTERFACE
`

### 4.2 UEL 钩子签名

`ortran
SUBROUTINE UEL(rhs, amatrx, svars, energy, ndofel, nrhs, nsvars, &
    props, nprops, coords, mcrd, nnode, u, du, v, a, jtype, time, dtime, &
    kstep, kinc, jelem, params, ndload, jdltyp, adlmag, predef, npredef, &
    lflags, mlvarx, ddlmag, mdload, pnewdt, jprops, njprop, period)
  ! UFC 封装: PH_UEL_Context (ABI_Flat)
END SUBROUTINE
`

### 4.3 ShapeFunc 签名

`ortran
SUBROUTINE PH_EvalShapeFunc(elem_type, xi, N, dN_dxi, stat)
  INTEGER,          INTENT(IN)  :: elem_type
  REAL(wp),         INTENT(IN)  :: xi(:)
  REAL(wp),         INTENT(OUT) :: N(:)
  REAL(wp),         INTENT(OUT) :: dN_dxi(:,:)
  INTEGER,          INTENT(OUT) :: stat
END SUBROUTINE
`

## 5. 算法流程图 (S0-S4 Pipeline)

`mermaid
sequenceDiagram
    participant L3 as L3_MD (SSOT)
    participant L4 as L4_PH (Domain)
    participant L5 as L5_RT (Dispatcher)
    participant Mat as Material Domain
    
    Note over L3,Mat: 冷路径
    L3->>L4: S1 Populate Element
    L4->>L4: Bind integrator PTR
    L4->>L4: Attach Section info
    
    Note over L3,Mat: 热路径 (每单元调用)
    L5->>L4: S3 Dispatch (Elem Loop)
    L4->>L4: Fetch u/du from global
    L4->>L4: ShapeFunc Eval
    L4->>L4: B-matrix, J, det_J
    loop IP Loop
        L4->>Mat: IP本构调用
        Mat-->>L4: stress, C_tan
        L4->>L4: Ke, Re 积分
    end
    L4->>L5: Return assembled Ke/Re
`

## 6. 三维度过程算法

| 维度 | 描述 | UFC 映射 |
|------|------|----------|
| **空间** | 22 族单元拓扑 | 1D/2D/3D 形函数、B阵、Gauss积分 |
| **时间** | 全域增量/迭代 | 每 Newton 迭代调用一次 integrator |
| **动作** | Ke/Re 管线 | ShapeFunc -> B-matrix -> Gauss积分 -> 材料路由 -> 装配 |

## 7. TODO / 缺口（实际代码审计 2026-05-05）

| 项 | 优先级 | 状态 | 说明 |
|----|--------|------|------|
| UEL-A/UEL-B 完整实装 | P0 | **DONE** | `PH_UEL_Def.f90`(27-188) 实现完整 UEL 7-arg context；`RT_Elem_UEL.f90`(28-155) 实现标准 UEL API + sect_registry 集成 |
| L3 去 Base 后缀 | P1 | **DONE** | `MD_Elem_UEL_Def.f90` 明确禁止 Base_Desc；L3 Element 已无 `Base` 后缀 |
| RHS/AMATRX 落位 | P0 | **DONE** | `PH_UEL_Context%rhs(:,:)/amatrx(:,:)` 已定义，UEL API 输出就绪 |
| M-S-E 联合键 | P0 | **DONE** | `RT_Elem_UEL_API`(28) 用 `TYPE(MD_Sect_Registry)` 桥接 Section；`RT_Elem_Sect.f90`(90-91) 实现 L3→L5 Populate |
| 22 族 integrator 完整度 | P0 | **30%** | `PH_ElemKeDispatch.f90`、`PH_Elem_Core.f90`、`PH_Elem_Eval.f90`、`PH_Elem_CalcWrapper.f90` 有集成骨架，但仅 Solid3D/Shell/Beam 族有独立 Execute 模块；无 PH_Elem_*_Integrate.f90 命名规范文件 |
| UEL Context 非-Def 四型对齐 | P0 | **50%** | `PH_UEL_Context`(27) 是 ABI_Flat，有 W2 注释警告 ≠ PH_Elem_Ctx；但 align 代码未写死 |
| L3 Elem 族扩展命名规范化 | P1 | **UNDONE** | L3 Element 族文件 (Solid3D/Shell/Beam/Truss/Mass/UEL) 文件名不一致 (MD_Elem_Solid3D vs MD_Elem_Truss vs MD_Elem_UEL) |

---

> **END** — Element Domain Inventory v1.0
