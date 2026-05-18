# UFC 域级功能模块主索引 (Master Domain Inventory Index)

**报告 ID**: REP-MASTER-INVENTORY
**版本**: v1.3 | **日期**: 2026-05-13
**性质**: 域级功能模块清单的统一入口，链接 8 份域级 Inventory + 命名规范合订 + 关键字参数目录
**核心公式**: 完整功能模块 = 数据结构(四型TYPE:Desc/State/Algo/Ctx + Args) + 过程算法(空间维度 + 时间维度 + 动作维度)

**SSOT 与快照**：规程级真源以 `docs/03_Domain_Pillars/DomainProcedureRegistry/README.md`（逐文件 Registry + **对账优先级**）、`docs/03_Domain_Pillars/DomainProcedureRegistry/design/` 下 `INTENT.md` 及各域 `ufc_core/**/CONTRACT.md` 为准。本索引为报告侧快照；**冲突时**按 Registry README「对账优先级」裁决（叙事稿不反向覆盖合同 / INTENT）。更新本页时请同步 **日期** 字段。去重总策略见 [`SSOT_AND_DEDUP_POLICY.md`](SSOT_AND_DEDUP_POLICY.md)。

---

## 1. 域柱分类

### 1.1 全贯通域柱 (Full Pillar: L3+L4+L5)

| 域柱 | 域缩 | L3 目录 | L4 目录 | L5 目录 | 类型 |
|------|------|---------|---------|---------|------|
| Material | Mat | L3_MD/Material/ | L4_PH/Material/ | L5_RT/Material/ | P1 |
| Element | Elem | L3_MD/Element/Elem/ | L4_PH/Element/ | L5_RT/Element/ | P2 |
| Contact | Cont | L3_MD/Interaction/ | L4_PH/Contact/ | L5_RT/Contact/ | P3 |
| LoadBC | LoadBC | L3_MD/Boundary/, L3_MD/LoadBC/ | L4_PH/LoadBC/ | L5_RT/LoadBC/ | P4 |

### 1.2 半贯通域柱 (Half Pillar: L3+L5)

| 域柱 | 域缩 | L3 目录 | L5 目录 | 类型 |
|------|------|---------|---------|------|
| Output | Out | L3_MD/Output/ | L5_RT/Output/ | P5 |
| WriteBack | WB | L3_MD/WriteBack/ | L5_RT/WriteBack/ | P6 |

### 1.3 复合/正交半柱

| 域柱 | 域缩 | 子域 | 说明 | 类型 |
|------|------|------|------|------|
| Analysis | Step/Solv | Step, Amplitude, Solver, Coupling | L5 三步状态机, L4 无独立域 | H1 |
| Section | Sect | 截面属性 | 正交维, L4 嵌入 Elem | H2 |

---

## 2. 文档互链表

| 文档 | 路径 | 内容 | 关系 |
|------|------|------|------|
| **命名规范合订** | REPORT_Naming_Unified_Spec.md | S0-S4场景, 域缩, 层缀, 四型命名 | 根 **stub** → [全文](archive/REPORT_Naming_Unified_Spec.md) |
| **域名压缩权威表** | Domain_Compression_Canon.md | `ufc_core`（不含 ExternalLibs）各域 `DomainAbbr`；三段/四段文件名第二段真源 | 与合订 §1 互链 |
| **命名原规范(旧)** | REPORT_Naming_Quad_OnePager_FiveScenes.md | 报告ID, S0-S4定义 | -> 新规范 |
| **四型设计规格** | FourKind_MasterAux_Nesting_Design_Spec.md | R-01到R-13, 主/辅四型 | 根 **stub** → [全文](archive/FourKind_MasterAux_Nesting_Design_Spec.md) |
| **一页填槽** | OnePager_FourKind_MasterAux_Nesting.md | 主/辅四型填槽表 | 填槽参考 |
| **关键字目录** | Keyword_Parameter_Catalog.md | 77关键字+69参数 P0/P1/P2 | 冷路径输入 |
| **映射总报告** | Keyword_to_UFC_Architecture_Mapping.md | KEYWORD.pdf->UFC架构 | 映射总结 |
| **Abaqus映射** | Abaqus_Analysis_Manual_to_UFC_Architecture_Mapping.md | 5册分析手册->UFC | 顶层映射 |
| **过程算法全景** | Procedure_Algorithm_L3L4L5_synthesis.md | 三维度x八域 | 根 **stub** → [archive 全文](archive/Procedure_Algorithm_L3L4L5_synthesis.md) |
| **材料域过程算法** | Material_Procedure_Algorithm.md | `REP-MAT-PROCEDURE`；三轴+S-Pipeline+constitutive PTR | 根 **stub** → [archive 全文](archive/Material_Procedure_Algorithm.md)；与全景、四型合订、Material Inventory 互链 |
| **单元域过程算法** | Element_Procedure_Algorithm.md | `REP-ELEM-PROCEDURE`；三轴+integrator/UEL 管线 | 根 **stub** → [archive 全文](archive/Element_Procedure_Algorithm.md)；与全景、UEL 合订、Element Inventory 互链 |
| **截面域过程算法** | Section_Procedure_Algorithm.md | `REP-SECT-PROCEDURE`；L3 正交维三轴 | 根 **stub** → [archive 全文](archive/Section_Procedure_Algorithm.md)；与全景、截面四型合订、Section Inventory 互链 |
| **接触域过程算法** | Contact_Procedure_Algorithm.md | `REP-CONT-PROCEDURE`；Search/Uzawa 等 L3–L5 过程 | 根 **stub** → [archive 全文](archive/Contact_Procedure_Algorithm.md)；与全景、接触四型合订、Contact Inventory 互链 |
| **LoadBC 域过程算法** | LoadBC_Procedure_Algorithm.md | `REP-LOADBC-PROCEDURE`；施加与 PH 控制过程 | 根 **stub** → [archive 全文](archive/LoadBC_Procedure_Algorithm.md)；与全景、LoadBC 四型合订、LoadBC Inventory 互链 |
| **输出域过程算法** | Output_Procedure_Algorithm.md | `REP-OUT-PROCEDURE`；Frame/Buffer/Trigger 管线 | 根 **stub** → [archive 全文](archive/Output_Procedure_Algorithm.md)；与全景、Output 四型合订、Output Inventory 互链 |
| **写回域过程算法** | WriteBack_Procedure_Algorithm.md | `REP-WB-PROCEDURE`；WB_Guard 与分派 | 根 **stub** → [archive 全文](archive/WriteBack_Procedure_Algorithm.md)；与全景、WriteBack 四型合订、WriteBack Inventory 互链 |
| **分析步域过程算法** | Analysis_Procedure_Algorithm.md | `REP-ANALYSIS-PROCEDURE`；Step/Solver/Coupling 四子域过程 | 根 **stub** → [archive 全文](archive/Analysis_Procedure_Algorithm.md)；与全景、Analysis 四型合订、Analysis Inventory 互链 |
| **逐文件过程 Registry** | [DomainProcedureRegistry/README.md](../docs/03_Domain_Pillars/DomainProcedureRegistry/README.md) | `design/` + `generated/` 双轨；与 `ufc_core` 镜像 | 与八域过程算法叙事 **互补**；对账优先级见该 README |
| **过程指针清单** | Procedure_Pointer_Inventory.md | PTR全景 (4处) | 接口参考 |
| **域柱模板** | Pillar_L3L4L5_CrossLayer_Design_Template.md | 跨层设计模板 | 根 **stub** → [全文](archive/Pillar_L3L4L5_CrossLayer_Design_Template.md) |
| **Base / Boundary / LoadBC 文档统一索引** | Base_Boundary_LoadBC_FourType_Algorithm_Unified_Index.md | Base 基础设施、L3 `Boundary/` 与 P4 LoadBC 四型+算法文档一张表；Boundary 不独立成柱 | 与 LoadBC 行、命名 LoadBC 对照 |
| **用户子程序映射** | Abaqus_UserSubroutine_UFC_Map.md | UMAT/UEL->UFC | 子程序参考 |
| **AI 七层链路与 UFC 对齐** | AI_SevenLayer_Stack_UFC_Mechanism_and_Optimization.md | Prompt→Context→Skills→MCP→Agent→Harness→Loop；道法术器；PPLAN/`ufc_harness` 核对；Loop 与 FEM 数值循环区分 | 工程协作 / Agent 链路口径 |
| **七层工作流实操指南** | UFC_SevenLayer_Workflow_Guide.md | 参数化任务卡模板、域编排顺序表、Context 截取清单、Agent 指令序列、Harness 门禁角色、Loop 节奏设计 | 根 **stub** → [全文](archive/UFC_SevenLayer_Workflow_Guide.md) |

---

## 3. 域级 Inventory 索引

| 域柱 | Inventory 文档 | 模块数 | 子程序数 | 流程图 | 结构图 | TODO 实况 |
|------|---------------|--------|---------|--------|--------|-----------|
| **Material** | Material_Domain_Inventory.md | 12 | 5 | S0-S4 Pipeline | L3/L4/L5四型 | **P0**:L4 Execute 40%；P1:去Base um；**重评估** |
| **Element** | Element_Domain_Inventory.md | 15 | 4 | Ke/Re Pipeline | L3/L4/L5四型 | **P0**:22族Integrator 30%；**其余已关闭** |
| **Contact** | Contact_Domain_Inventory.md | 11 | 4 | Search->Detect->Force | L3/L4/L5四型 | **P0**:辅State+BVH距离；P1:Base去+Stp_Ctl |
| **LoadBC** | LoadBC_Domain_Inventory.md | 9 | 2 | Assemble->Apply | L3/L4/L5四型 | **P0**:Stp_Ctl done；P1:DLOAD钩子+去Base |
| **Output** | Output_Domain_Inventory.md | 7 | 0 | Frame->Buffer->Writer | L3/L5(无L4) | **P0**:Stp/Itr done；P1:UVARM钩子+去Base |
| **WriteBack** | WriteBack_Domain_Inventory.md | 5 | 0 | WB_Guard->11域分派 | L3/L5(反向) | **P0**:WB_Guard done；P1:UEXTERNALDB+Chkpt I/O |
| **Analysis** | Analysis_Domain_Inventory.md | 8 | 0 | 三步状态机 | L3/L5(无L4) | **P0**:Solver骨架done; P1:Coupling+去Base |
| **Section** | Section_Domain_Inventory.md | 5 | 0 | M-S-E桥接 | L3->L4嵌入 | **P0**:方案B done；P1:去Base+域缩统一 |

**补充（材料域）**：四类 TYPE × 二元模块 × L3/L4/L5 的 P0 只读对照表见 [Material_P0_FourType_BinaryMap.md](Material_P0_FourType_BinaryMap.md)；切片 01 任务卡与 2026-05 二元改造 sprint 全文见 [`archive/README.md`](archive/README.md)（含 `Material_Refactor_Slice01_TaskCard.md` 等）。

---

## 4. 命名规范速查

| 规则 | 内容 | 详细文档 |
|------|------|---------|
| 域缩 | Mat/Elem/Cont/LoadBC/Out/WB/Sect/Constr/KW | §1.1 |
| 层缀 | MD_/PH_/RT_ | §1.2 |
| 四型 | Desc/State/Algo/Ctx | §2 |
| 五场景 | S0(定义)/S1(Populate)/S2(局部)/S3(Dispatch)/S4(Execute) | §4 |
| *_Arg | {层}{域}_{动词语义}_Arg | §5 |
| 去Base | 基类不缀Base | R-09 |

---

## 5. 跨域编排流程图 (Step -> Inc -> Iter -> Solve)

`mermaid
sequenceDiagram
    participant Step as RT_StepDriver
    participant Solv as RT_Solv_Mgr
    participant Asm as Assembly
    participant Mat as Material
    participant Elem as Element
    participant Cont as Contact
    participant LoadBC as LoadBC
    participant Out as Output
    participant WB as WriteBack
    
    Note over Step,WB: Step Init
    Step->>Solv: Init NR System
    Step->>Asm: Populate (S1)
    Asm->>Mat: Populate Material
    Asm->>Elem: Populate Element (with Sect)
    Asm->>Cont: Populate Contact
    Asm->>LoadBC: Populate LoadBC
    
    Note over Step,WB: Increment Loop
    Step->>Solv: Predict Inc
    
    Note over Step,WB: Newton Iteration
    loop NR Iteration
        Solv->>Asm: Assemble K/F
        Asm->>Elem: Compute Ke/Re (S4)
        Elem->>Mat: Stress Update (constitutive PTR)
        Mat-->>Elem: stress/C_tan
        Elem-->>Asm: Ke/Re
        Asm->>Cont: Contact Force/Stiffness
        Cont-->>Asm: K_contact/F_contact
        Asm->>LoadBC: Assemble Fext
        LoadBC-->>Asm: F_ext
        Asm-->>Solv: Global K/F
        Solv->>Solv: Solve K.x = f
        Solv->>Step: Check Convergence
    end
    
    Note over Step,WB: Step End
    Step->>Out: Write Output
    Step->>WB: WriteBack to L3
    Out-->>Step: Done
    WB-->>Step: Done
`

---

## 6. 域合同文件索引

| 域柱 | L3 CONTRACT | L4 CONTRACT | L5 CONTRACT |
|------|-------------|-------------|-------------|
| Material | L3_MD/Material/CONTRACT.md | L4_PH/Material/CONTRACT.md | L5_RT/Material/CONTRACT.md |
| Element | L3_MD/Element/Elem/CONTRACT.md | L4_PH/Element/CONTRACT.md | L5_RT/Element/CONTRACT.md |
| Contact | L3_MD/Interaction/CONTRACT.md | L4_PH/Contact/CONTRACT.md(?) | — |
| LoadBC | L3_MD/LoadBC/CONTRACT.md | L4_PH/LoadBC/CONTRACT.md | — |
| Output | — | — | L5_RT/Output/CONTRACT.md |
| WriteBack | — | — | L5_RT/WriteBack/CONTRACT.md |
| Section | L3_MD/Section/CONTRACT.md | — | L5_RT/Section/CONTRACT.md |
| Analysis | L3_MD/Analysis/CONTRACT.md | — | — |
| KeyWord | L3_MD/KeyWord/CONTRACT.md | — | — |

---

## 7. 缺口综合分析（实际代码审计 2026-05-05）

### 7.1 已关闭项（Inventory 列为 DONE）

| 域 | 项 | 来源 |
|----|-----|------|
| Material | 11 family 全标记 | L5_RT 13 族 _Def + L4 12 族标记 |
| Material | DualWrite 实装 | `PH_Mat_State_DualWrite_*` 已实现 |
| Material | UMAT 对偶表 | 25+ UF_*_UMAT wrappers 已集成 |
| Element | UEL-A/UEL-B 完整实装 | `PH_UEL_Def.f90` + `RT_Elem_UEL.f90` 完成 |
| Element | RHS/AMATRX 落位 | `PH_UEL_Context%rhs/amatrx` 已定义 |
| Element | M-S-E 联合键 | `RT_Elem_UEL_API` 用 `MD_Sect_Registry` 桥接 |
| Element | L3 去 Base 后缀 | 已无 `Base` 后缀 |
| LoadBC | Stp_Ctl_Algo | `PH_Ldbc_Stp_Ctl_Algo`（存量）；目标 **`PH_LoadBC_Stp_Ctl_Algo`** 与 Canon `LoadBC` 前缀对齐 |
| Output | Stp_Ctl_Algo / Itr_Algo | `RT_Out_Aux_Def` 已定义 |
| WriteBack | WB_Guard | `MD_WB_Brg.f90` 已实现，12 路径校验 |
| WriteBack | Checkpoint | `RT_WB_Impl_Checkpoint` 框架完整 |
| Contact | 6 辅 State 类型 | `PH_Cont_Def.f90` 定义字段群组 |
| Contact | FRIC/UINTER/GAPCON 类型 | 类型已定义 |
| Contact | NTS 投影核心 | NR 迭代+自然坐标求解完整 |
| Section | 方案B(L4嵌入Element) | `RT_Elem_UEL_API` + `RT_Elem_Sect.f90` 已实现 |
| **All 5域** | **R-09 去 Base 后缀（6 处）** | **本会话完成: Cont/Out/WB/Solv 重命名, Mat/Sect 已清理** |
| **WriteBack** | **Checkpoint I/O 实装** | **本会话完成: 取消注释+二进制 READ/WRITE 实现** |
| **LoadBC** | **命名演进** | **文档域缩 LoadBC**；Fortran 存量 `PH_Ldbc_*` → 渐进 **`PH_LoadBC_*`**（见 TBP 字汇 P2） |

### 7.2 待关闭项

| 域 | 项 | 优先级 | 状态 |
|----|-----|--------|------|
| Material | L4 11 family Execute 实装度 | **P0** | 40%, L5 13族全但 L4 PH_Mat_Core 仅~7族 |
| Element | 22 族 integrator 实装度 | **P0** | 30%, 仅 3 族有独立 Execute 模块 |
| Contact | 6 辅 State 拆分 | **P0** | 30%, 单 TYPE 未拆辅 |
| Contact | BVH 精确距离计算 | **P0** | 0%, 投影框架完成 |
| Output | UVARM/VUVARM 用户钩子 | **P0** | 注释提及但无桥实现 |
| WriteBack | UEXTERNALDB 对偶 | **P0** | 无桥实现, Checkpoint I/O 30% 被注释 |
| Material/5域 | R-09 去 Base 后缀 | **P1** | Mat/Output/WB/Analysis/Section 约 6 处未处理 |
| All | 用户子程序桥(6处) | **P1** | DLOAD/ULOAD/UVARM/UEXTERNALDB/FRIC/UINTER 无实装桥 |
| 3域 | 命名统一 | **P1-P2** | Sect(Sec_), LoadBC(LBC/Load/BC), Elem族 |
| All | 金线集成验证 | **P0** | 各域独立文件齐全但跨域 Step→Inc→Iter 集成度待验证 |

---

## 8. 五场景分布总表

| 场景 | Module | 作用域 |
|------|--------|--------|
| **S0: 定义与注册** | MD_*_Def, MD_*_Reg | L3 全域柱 |
| **S1: Populate** | PH_L4_Populate_*, MD_*PH_Brg | L3->L4 冷路径 |
| **S2: 局部上下文** | PH_*_Update_args, *%lcl* | L4 热准备 |
| **S3: Dispatch** | RT_*_Dispatch, RT_*_Brg | L5 路由 |
| **S4: Execute** | PH_*_Execute*, PH_UMAT_*, PH_UEL_* | L4 物理核 |
| **W: WriteBack** | MD_WB_Brg, RT_WB_Domain | L5->L3 写回 |

---

## 9. 文件清单

### 9.1 本批次新增文档

| 文件 | 大小(估计) |
|------|-----------|
| REPORT_Naming_Unified_Spec.md | ~8KB（根 stub；长文见 `archive/REPORT_Naming_Unified_Spec.md`） |
| Material_Domain_Inventory.md | ~6KB |
| Element_Domain_Inventory.md | ~6KB |
| Contact_Domain_Inventory.md | ~5KB |
| LoadBC_Domain_Inventory.md | ~4KB |
| Output_Domain_Inventory.md | ~3KB |
| WriteBack_Domain_Inventory.md | ~3KB |
| Analysis_Domain_Inventory.md | ~4KB |
| Section_Domain_Inventory.md | ~3KB |
| **Master_Domain_Inventory_Index.md** | **本文** |

### 9.2 已有 REPORTS 文档 (25+ 份)

详见 REPORT_Naming_Quad_OnePager_FiveScenes.md §1 文档族表 + Keyword_Parameter_Catalog.md、Keyword_to_UFC_Architecture_Mapping.md 等。

---

> **END** — Master Domain Inventory Index v1.0
