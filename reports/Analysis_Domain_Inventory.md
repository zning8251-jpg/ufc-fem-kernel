# Analysis 域功能模块清单 (Domain Module Inventory)

**路径**: UFC/REPORTS/Analysis_Domain_Inventory.md
**对齐规范**: REPORT_Naming_Unified_Spec.md (复合半柱: Step/Solv/Amp/Cpl)
**源文档**: Analysis_L3L4L5_four_type_synthesis.md, Analysis_Procedure_Algorithm.md

---

## 1. 域简述

| 属性 | 值 |
|------|-----|
| **域柱类型** | 复合半贯通域柱 (H1) |
| **子域** | Step(步), Amplitude(幅值), Solver(求解器), Coupling(耦合) |
| **L4** | 无独立域 — 消费式调用物理核 |
| **功能** | 步驱动、幅值插值、NR求解、场耦合、时间积分 |

## 2. 四型结构总览

`mermaid
graph TB
    subgraph L3_MD[L3_MD - SSOT]
        MD_Step_Mgr["MD_Step_Mgr<br/>步定义"]
        MD_Amp_Desc["MD_Amp_Desc<br/>11类型统一"]
        MD_Solver_Desc["MD_Solver_Desc<br/>NR/线性求解器"]
        MD_Cpl_Desc["MD_Cpl_Desc<br/>耦合定义"]
    end
    subgraph L5_RT[L5_RT - Golden Line]
        RT_StepDriver["RT_StepDriver<br/>三步状态机"]
        RT_Solv_Mgr["RT_Solv_Mgr<br/>K.x=f 金线"]
        RT_Step_State["RT_Step_State<br/>Step/Inc/Iter"]
        RT_Solv_NRState["RT_Solv_NRState<br/>TBP: Init/Reset/Update"]
    end
    L3_MD -->|Brg| L5_RT
`

## 3. 功能模块清单

| 子域 | 文件 | 角色 | 关键子程序 | 状态 |
|------|------|------|-----------|------|
| Step | MD_Step_Def.f90 | Def | CreateStep, SetParams | EXIST |
| Step | RT_StepDriver.f90 | Mgr | RunStep, RunInc, RunItr | EXIST |
| Step | RT_Step_Brg.f90 | Brg | FromL3_Populate | EXIST |
| Amp | MD_Amp_Def.f90 | Def | 11类型 Desc | EXIST |
| Amp | MD_Amp_Svc.f90 | Svc | GetFactor, EvalAtTime | EXIST |
| Solver | MD_Solver_Def.f90 | Def | Solver_Desc, NR_Algo | EXIST |
| Solver | RT_Solv_Mgr.f90 | Mgr | Solve, NRStep | EXIST |
| Solver | RT_Solv_NRState.f90 | State | Init/Reset/UpdateNorms TBP | EXIST |
| Cpl | MD_Cpl_Def.f90 | Def | PairDef, Ctl | EXIST |

## 4. 算法流程图

`mermaid
stateDiagram-v2
    [*] --> StepInit: RT_STEP_RUNNING
    StepInit --> IncPredict: RT_INC_PREDICTING
    IncPredict --> ItrAssemble: RT_ITER_ASSEMBLING
    ItrAssemble --> ItrSolve: RT_ITER_SOLVING
    ItrSolve --> ItrUpdate: RT_ITER_UPDATING
    ItrUpdate --> ItrCheck: RT_ITER_CHECKING
    ItrCheck --> IncConverged: converged
    ItrCheck --> IncPredict: cutback
    IncConverged --> StepEnd: RT_STEP_COMPLETED
    StepEnd --> [*]
`

## 5. TODO / 缺口（实际代码审计 2026-05-05）

| 项 | 优先级 | 状态 | 说明 |
|----|--------|------|------|
| Step 状态机状态枚举 | P0 | **DONE** | `RT_STEP_RUNNING/INCREMENT/ITER...` 等状态在 Step 驱动中定义 |
| Solver 骨架 | P0 | **DONE** | `MD_Solver_Def.f90` + `RT_Solv_Mgr.f90` + `RT_Solv_NRState.f90` 实装，含 Init/Reset/UpdateNorms TBP |
| Amplitude 11 类型 | P0 | **DONE** | `MD_Amp_Def.f90` + `MD_Amp_Svc.f90`(GetFactor/EvalAtTime) 实现 |
| Coupling 定义 | P1 | **UNDONE** | `MD_Cpl_Def.f90` 存在但范围未知(只 1 文件)，需确认场耦合覆盖度 |
| Step/Amp/Solver L5 对接集成 | P0 | **50%** | 有独立 Def/Brg/Driver 文件，但 `RT_StepDriver` → `MD_Amp_Svc` → `RT_Solv_Mgr` 金线集成度未验证 |
| 去 `Base` 后缀 (R-09) | P1 | **UNDONE** | `RT_Solv_Def.f90`(235) 仍公开 `RT_Solv_Desc`（R-09 违规） |

---

> **END** — Analysis Domain Inventory v1.1
