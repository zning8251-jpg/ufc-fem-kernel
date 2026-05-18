# Abaqus 关键词 → UFC 架构映射总报告

**路径**: UFC/REPORTS/Keyword_to_UFC_Architecture_Mapping.md
**版本**: v1.1 | **日期**: 2026-05-05
**性质**: KEYWORD.pdf 77 个关键字到 UFC 六层架构的映射总结
**互链**: 命名规范 REPORT_Naming_Unified_Spec.md | 域级清单 Master_Domain_Inventory_Index.md

---

## 1. 映射总览

`mermaid
graph LR
    INP[Abaqus INP] --> Lex[Lexer/Scanner]
    Lex --> Parse[Parser KW_Registry]
    Parse --> L3[L3_MD Desc TYPEs]
    L3 --> L4[L4_PH Slots]
    L4 --> L5[L5_RT Dispatch]
    
    style L3 fill:#e1f5fe
    style L4 fill:#fff3e0
    style L5 fill:#e8f5e9
`

## 2. 分类覆盖

| UFC 域柱 | 对应关键字数 | P0 | P1 | P2 | 模块 |
|----------|------------|----|----|----|------|
| Material | >60 | 0 | 15 | 7 | MD_Mat_Def |
| Element | >30 | 0 | 8 | 2 | MD_Elem_Def |
| Section | 17 | 0 | 4 | 0 | MD_Sect_Def |
| Contact | >25 | 0 | 5 | 2 | MD_Cont_Def |
| LoadBC | >20 | 0 | 7 | 0 | MD_Ldbc_Def |
| Output | 5 | 0 | 5 | 0 | MD_Out_Def |
| Analysis | >15 | 2 | 8 | 3 | MD_Step_Mgr |
| Mesh | >10 | 0 | 4 | 2 | MD_Mesh_Def |
| Amplitude | 11 | 1 | 0 | 3 | MD_Amp_Def |
| Constraint | >10 | 0 | 2 | 0 | MD_Constr_Def |
| **总计** | **~200+** | **8** | **52** | **17** | |

## 3. Cold Path 集成点

| 阶段 | 模块 | 说明 |
|------|------|------|
| L3 Keyword Registration | MD_KW_Reg.f90 / MD_KW_Reg_Ext.f90 | 关键字+参数+数据行注册 |
| L3 Parsing | MD_KW_Abaqus.f90 | INP 顶级解析器 |
| L3->L4 Populate | MD_*PH_Brg.f90 | 各域桥接灌槽 |

## 4. 下一步

| 优先级 | 任务 | 域 |
|--------|------|-----|
| P0 | 关键字解析器与 L3 Desc 完整对接 | 全部域 |
| P1 | 多域联合关键字测试 | Cross-domain |
| P2 | P2 关键字按需扩展（试验数据, 特殊） | Material |

---

> **END** — Keyword-to-UFC Mapping Report v1.1
