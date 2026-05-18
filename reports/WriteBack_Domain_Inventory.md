# WriteBack 域功能模块清单 (Domain Module Inventory)

**路径**: UFC/REPORTS/WriteBack_Domain_Inventory.md
**对齐规范**: REPORT_Naming_Unified_Spec.md (域缩=WB, 层缀=MD/RT)
**源文档**: WriteBack_L3L4L5_four_type_synthesis.md, WriteBack_Procedure_Algorithm.md

---

## 1. 域简述

| 属性 | 值 |
|------|-----|
| **域柱类型** | 半贯通域柱 (P6) |
| **域缩** | WB |
| **层覆盖** | L3_MD (白名单/映射), L5_RT (运行时) |
| **方向** | L5 -> L3 (反向于其它域柱) |
| **功能** | 步末将运行态数据写回L3模型定义层 |

## 2. 四型结构总览

`mermaid
graph LR
    subgraph L3_MD[L3_MD - SSOT]
        MD_WB_Desc["MD_WB_Desc<br/>白名单 + WB_DOMAIN_11 常量"]
    end
    subgraph L5_RT[L5_RT - Golden Line]
        RT_WB_Domain["RT_WB_Domain<br/>9 TBP"]
        RT_WB_Desc["RT_WB_Desc<br/>frequency/trigger/scope"]
        RT_WB_State["RT_WB_ProgressState<br/>RT_WB_BufferState<br/>辅: CheckpointStatus"]
        RT_WB_Algo["RT_WB_Algo<br/>Stp_Ctl / Itr_Algo"]
        RT_WB_Ctx["RT_WB_Ctx<br/>全POINTER预分配"]
    end
    L5_RT -->|WB-01唯一写回路径| L3_MD
`

## 3. 功能模块清单

| 文件 | 模块角色 | 模块名 | 关键子程序 | 状态 |
|------|---------|--------|-----------|------|
| MD_WB_Def.f90 | Def | MD_WB_Def | WB_DOMAIN_11 常量, 白名单 | EXIST |
| MD_WB_Brg.f90 | Brg | MD_WB_Brg | WB_Guard, 11域分派 | EXIST |
| RT_WB_Def.f90 | Def | RT_WB_Def | RT_WB_* TYPE | EXIST |
| RT_WB_Domain.f90 | Mgr | RT_WB_Domain | 9 TBP: Init/Set/WriteBack | EXIST |
| RT_WB_Impl.f90 | Proc | RT_WB_Impl | 编排, 审计 | EXIST |

## 4. TODO（实际代码审计 2026-05-05）

| 项 | 优先级 | 状态 | 说明 |
|----|--------|------|------|
| WB_Guard 白名单校验 | P0 | **DONE** | `MD_WB_Brg.f90`(126-162) 实现 `WB_Guard(domain, field, status)`，用于 12 个写回路径 |
| Checkpoint 审计 | P1 | **DONE** | `RT_WB_Impl.f90`(237-292) 实现 `RT_WB_Impl_Checkpoint`，含 save/load/error 三种模式(但 `READ/WRITE` 语句被注释掉) |
| UEXTERNALDB 对偶 | P0 | **UNDONE** | `RT_Com_Def.f90` 无 UEXTERNALDB 桥；`RT_Brg_Def.f90`(20) 提及但无实装 |
| 去 `Base` 后缀 (R-09) | P1 | **UNDONE** | `RT_WB_Def.f90`(32-101) 仍公开 `RT_WB_Desc`（R-09 违规） |
| Checkpoint I/O 实装 | P0 | **30%** | `RT_WB_Impl_Checkpoint` 框架完整但 `READ`/`WRITE` 语句为注释状态(254-264)，未实际读写文件 |

---

> **END** — WriteBack Domain Inventory v1.0
