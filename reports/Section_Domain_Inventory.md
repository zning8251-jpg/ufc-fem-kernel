# Section 域功能模块清单 (Domain Module Inventory)

**路径**: UFC/REPORTS/Section_Domain_Inventory.md
**对齐规范**: REPORT_Naming_Unified_Spec.md (域缩=Sect, 正交维)
**源文档**: Section_L3L4L5_four_type_synthesis.md, Section_Procedure_Algorithm.md

---

## 1. 域简述

| 属性 | 值 |
|------|-----|
| **域柱类型** | 正交维半柱 (H2) |
| **域缩** | Sect |
| **L4** | 嵌入 PH_Elem_* (方案B) |
| **功能** | 截面属性定义(厚度/取向/层合), M-S-E 联合键 |

## 2. 四型结构总览

`mermaid
graph LR
    subgraph L3_MD[L3_MD - SSOT]
        MD_Sect_Desc["MD_Sect_Desc<br/>9族 x 17类型<br/>5 TBP"]
        MD_Sect_Ctx["MD_Sect_Ctx<br/>current_section_idx"]
        MD_Sect_Algo["MD_Sect_Algo<br/>default_integration"]
    end
    subgraph L4_PH[L4_PH - 嵌入 Element]
        PH_Elem_Desc["PH_Elem_Desc<br/>sect thickness/orient"]
    end
    subgraph L5_RT[L5_RT - 门面]
        RT_Elem_Sect["RT_Elem_Sect<br/>探针/查询"]
        RT_Sec_Algo["RT_Sec_Algo<br/>Stp_Ctl(M-S-E兼容)"]
    end
    L3_MD -->|Populate| L4_PH
`

## 3. 功能模块清单

| 文件 | 模块角色 | 模块名 | 关键子程序 | 状态 |
|------|---------|--------|-----------|------|
| MD_Sect_Def.f90 | Def | MD_Sect_Def | 9族x17类型, 5 TBP | EXIST |
| MD_Sect_Domain.f90 | Def | MD_Sect_Domain | 域容器, Registry | EXIST |
| MD_Sect_Mgr.f90 | Mgr | MD_Sect_Mgr | Add/Validate/Get | EXIST |
| MD_Sect_Brg.f90 | Brg | MD_Sect_Brg | L3->L4 桥, StressState | EXIST |
| MD_SectCompat.f90 | Svc | MD_SectCompat | ValidateTriple(M-S-E) | EXIST |

## 4. TODO / 缺口（实际代码审计 2026-05-05）

| 项 | 优先级 | 状态 | 说明 |
|----|--------|------|------|
| 方案B承载(L4嵌入Element) | P0 | **DONE** | `RT_Elem_UEL_API`(28) 通过 `TYPE(MD_Sect_Registry)` 桥接 Section；`RT_Elem_Sect.f90` 实现完整的 L3→L5 截面 Populate + 查询 |
| 域缩统一 `Sect` | P1 | **UNDONE** | L3_MD/Section/ 代码使用 `MD_Sect_` 前缀(CONTRACT.md 中已是 Sect)；L5_RT/Section/ 使用 `RT_Sec_` 前缀(命名不统一: `RT_Sec_Def` vs 预期 `RT_Sect_Def`) |
| MD_Sect_Desc | P1 | ✅DONE (代码中不存在 Base) | MD_Sect_Def.f90 代码本身已用 MD_Sect_Desc (MD_Sect_Desc 在代码库不存在) |
| L5 Sect Algo 补全 | P2 | **UNDONE** | `RT_Sec_Aux_Def.f90` 仅 Aux_Def，无独立 Stp_Ctl_Algo |

---

> **END** — Section Domain Inventory v1.0
