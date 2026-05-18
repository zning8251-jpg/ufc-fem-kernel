# Output 域功能模块清单 (Domain Module Inventory)

**路径**: UFC/REPORTS/Output_Domain_Inventory.md
**对齐规范**: REPORT_Naming_Unified_Spec.md (域缩=Out, 层缀=RT, 无L4独立域)
**源文档**: Output_L3L4L5_four_type_synthesis.md, Output_Procedure_Algorithm.md

---

## 1. 域简述

| 属性 | 值 |
|------|-----|
| **域柱类型** | 半贯通域柱 (P5) |
| **域缩** | Out |
| **层覆盖** | L3_MD (注册/请求), L5_RT (运行时) |
| **L4** | 无独立域 — 消费层(L4物理核经Brg提供数据) |
| **功能** | 场输出/历史输出定义、触发、缓冲、写出 |

## 2. 四型结构总览

`mermaid
graph TB
    subgraph L3_MD[L3_MD - SSOT]
        MD_Out_Def["MD_Out_Def<br/>Registry<br/>FieldOut_Desc<br/>HistOut_Desc"]
    end
    subgraph L5_RT[L5_RT - Golden Line]
        RT_Out_Mgr["RT_Out_Mgr<br/>双State: Field + Hist"]
        RT_Out_Desc["RT_Out_Desc<br/>PTR->L3 Registry"]
        RT_Out_State["RT_Out_FieldState<br/>RT_Out_HistState<br/>辅: Frame/Buffer/Trigger"]
        RT_Out_Algo["RT_Out_Algo<br/>Stp_Ctl / Itr_Algo"]
        RT_Out_Ctx["RT_Out_Ctx<br/>step/incr/time + flags"]
    end
    L3_MD -->|PTR引用| L5_RT
`

## 3. 功能模块清单

| 文件 | 模块角色 | 模块名 | 关键子程序 | 状态 |
|------|---------|--------|-----------|------|
| MD_Out_Def.f90 | Def | MD_Out_Def | RegisterField, RegisterHist | EXIST |
| RT_Out_Def.f90 | Def | RT_Out_Def | RT_Out_Desc, Ctx, Algo | EXIST |
| RT_Out_FieldState.f90 | State | RT_Out_FieldState | CheckTrigger, AddFrame | EXIST |
| RT_Out_HistState.f90 | State | RT_Out_HistState | AddPoint, Buffer | EXIST |
| RT_Out_Frame.f90 | State | RT_Out_Frame | Pack, Flush | EXIST |
| RT_Out_Buffer.f90 | State | RT_Out_Buffer | Push, Pop, Flush | EXIST |
| RT_Out_Mgr.f90 | Mgr | RT_Out_Mgr | StepEnd, IncEnd | EXIST |

## 4. TODO（实际代码审计 2026-05-05）

| 项 | 优先级 | 状态 | 说明 |
|----|--------|------|------|
| `RT_Out_Stp_Ctl_Algo` | P0 | **DONE** | `RT_Out_Def.f90`(41) 已 USE `RT_Out_Aux_Def` 的 `RT_Out_Stp_Ctl_Algo/Itr_Algo` |
| `RT_Out_Itr_Algo` | P1 | **DONE** | `RT_Out_Aux_Def` 已定义 Itr_Algo；buffer frame/point 机制在 `RT_Out_Def.f90`(114-149) 已实现 |
| UVARM/VUVARM 用户钩子 | P0 | **UNDONE** | `PH_Out_Def.f90`(18) 注释提及 UVARM/VUVARM/URDFIL/UHISTR/USDFLD，但无实际桥实现；`RT_Brg_Def.f90`(20) 提到 `RT_Analy_Bridge_Ctx` 涉及 UVARM 但未找到具体桥接 |
| 去 `Base` 后缀 (R-09) | P1 | **UNDONE** | `RT_Out_Def.f90`(76) 仍公开 `RT_Out_Desc`（R-09 违规） |
| 写回/Output 步序协调 | P2 | **UNDONE** | RT_Out_Impl 与 RT_WB_{Brg,Impl} 步末写序无合同约束 |

---

> **END** — Output Domain Inventory v1.0
