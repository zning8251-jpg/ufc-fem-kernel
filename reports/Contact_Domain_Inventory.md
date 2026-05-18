# Contact/Interaction 域功能模块清单 (Domain Module Inventory)

**路径**: UFC/REPORTS/Contact_Domain_Inventory.md
**对齐规范**: REPORT_Naming_Unified_Spec.md (域缩=Cont, 层缀=MD/PH/RT)
**源文档**: Contact_L3L4L5_four_type_synthesis.md, Contact_Procedure_Algorithm.md, Procedure_Pointer_Inventory.md

---

## 1. 域简述

| 属性 | 值 |
|------|-----|
| **域柱类型** | 全贯通域柱 (P3) |
| **域缩** | Cont |
| **层覆盖** | L3_MD (模型定义), L4_PH (物理核), L5_RT (运行时编排) |
| **功能** | 接触搜索、检测、法向/切向力计算、接触刚度、摩擦模型 |
| **源手册** | Abaqus ANALYSIS_5 (Prescribed Conditions/Constraints/Interactions) |

## 2. 四型结构总览

`mermaid
graph TB
    subgraph L3_MD[L3_MD - SSOT]
        MD_Cont_Desc["MD_Cont_Desc<br/>接触对定义<br/>摩擦模型参数<br/>搜索参数"]
    end
    subgraph L4_PH[L4_PH - Hot Path]
        PH_Cont_Domain["PH_Cont_Domain<br/>四型域容器"]
        PH_Cont_Desc["PH_Cont_Desc + 3辅<br/>Constr(惩罚)<br/>Friction(模型/系数)<br/>Search(算法/参数)"]
        PH_Cont_State["PH_Cont_State + 6辅<br/>Geometry / Force<br/>Stiffness / Friction<br/>Convergence / Itr_Quick"]
        PH_Cont_Algo["PH_Cont_Algo + 3辅<br/>Constr / Friction<br/>Stp_Method<br/>search_strategy PTR"]
        PH_Cont_Ctx["PH_Cont_Ctx + 3辅<br/>Lcl_Pos(从/主坐标)<br/>Lcl_Normal(法向)<br/>Lcl_Stiff(K_contact 24x24)"]
    end
    subgraph L5_RT[L5_RT - Golden Line]
        RT_Cont_Solv["RT_Cont_Solv<br/>搜索->检测->力->刚度"]
        RT_Contact_Desc["RT_Contact_Desc<br/>DELEGATED->L3索引"]
        RT_Contact_State["RT_Contact_State<br/>pair_active / status<br/>Uzawa_lambda"]
    end
    L3_MD -->|Populate| L4_PH
    L4_PH --> L5_RT
`

## 3. 功能模块清单

| 文件 | 模块角色 | 模块名 | 关键子程序 | 接口 | 状态 |
|------|---------|--------|-----------|------|------|
| MD_Cont_Def.f90 | Def | MD_Cont_Def | CreateContactPair, SetFriction | MD_Cont_Desc | EXIST |
| MD_Cont_PH_Brg.f90 | Brg | MD_Cont_PH_Brg | FillParams_FromMD | — | EXIST |
| PH_Cont_Def.f90 | Def | PH_Cont_Def | Domain: desc/state/algo/ctx | PH_Cont_* TYPE | EXIST |
| PH_Cont_AlgorithmFramework.f90 | Proc | PH_Cont_AlgoFramework | Search->Detect->Force->Stiffness | — | EXIST |
| PH_Cont_Search_BVH.f90 | Svc | PH_Cont_Search_BVH | BuildBVH, QueryBVH | BIND search_strategy PTR | EXIST |
| PH_Cont_Detect.f90 | Proc | PH_Cont_Detect | ComputeGap, ComputeNormal | — | EXIST |
| PH_Cont_Force.f90 | Proc | PH_Cont_Force | NormalForce, TangentForce | — | EXIST |
| PH_Cont_Stiffness.f90 | Proc | PH_Cont_Stiffness | NormalStiff, TangentStiff | — | EXIST |
| PH_Cont_Friction_Coulomb.f90 | Proc | PH_Cont_Friction | CoulombFriction | — | EXIST |
| PH_Cont_Detect_Arg.f90 | Arg | PH_Cont_Detect_Arg | — | PH_Cont_Detect_Arg | EXIST |
| PH_Cont_Enforce_Arg.f90 | Arg | PH_Cont_Enforce_Arg | — | PH_Cont_Enforce_Arg | EXIST |
| RT_Cont_Solv.f90 | Mgr | RT_Cont_Solv | SolveContact, UzawaLoop | — | EXIST |
| RT_Contact_Brg.f90 | Brg | RT_Contact_Brg | FromL3, MakeCtx | — | EXIST |

## 4. 关键子程序签名

### 4.1 search_strategy Procedure Pointer

`ortran
ABSTRACT INTERFACE
  SUBROUTINE ContactSearchStrategy_Ifc(slave_coords, master_faces, &
      search_radius, contact_pairs, stat)
    IMPORT :: wp
    REAL(wp),         INTENT(IN)  :: slave_coords(:,:)
    INTEGER,          INTENT(IN)  :: master_faces(:,:)
    REAL(wp),         INTENT(IN)  :: search_radius
    INTEGER,          INTENT(OUT) :: contact_pairs(:,:)
    INTEGER,          INTENT(OUT) :: stat
  END SUBROUTINE
END INTERFACE
`

### 4.2 Detect 签名

`ortran
SUBROUTINE PH_Cont_Detect_Proc(desc, state, algo, ctx, args)
  TYPE(PH_Cont_Desc),     INTENT(IN)    :: desc
  TYPE(PH_Cont_State),    INTENT(INOUT) :: state
  TYPE(PH_Cont_Algo),     INTENT(IN)    :: algo
  TYPE(PH_Cont_Ctx),      INTENT(INOUT) :: ctx
  TYPE(PH_Cont_Detect_Arg),INTENT(INOUT):: args
END SUBROUTINE
`

## 5. 算法流程图

`mermaid
sequenceDiagram
    participant L5 as L5_RT (RT_Cont_Solv)
    participant L4 as L4_PH (AlgorithmFramework)
    participant L3 as L3_MD (SSOT)
    
    Note over L5,L3: 冷路径
    L3->>L4: S1 Populate Contact
    
    Note over L5,L3: 热路径 (每 Newton 迭代)
    L5->>L4: S3 Dispatch Contact
    L4->>L4: Search (BVH/CCD)
    L4->>L4: Detect (gap/normal)
    L4->>L4: Force (normal/tangent)
    L4->>L4: Stiffness (K_contact)
    L4-->>L5: Return assembled K/F
`

## 6. TODO / 缺口（实际代码审计 2026-05-05）

| 项 | 优先级 | 状态 | 说明 |
|----|--------|------|------|
| PH_Cont_State 基础 | P0 | **DONE** | `PH_Cont_Def.f90`(600-608) 定义了 `PH_Cont_State`、`PH_Cont_StateCheck_Arg`(895-899) 及 `PH_Cont_Mgr.f90` 含检查逻辑 |
| 6 辅 State 字段 | P0 | **30%** | `PH_Cont_Def` 定义了 Geometry/Force/Stiffness/Friction/Convergence(600-676) 组字段，但辅 TYPE 结构尚未拆分；PH_Cont_State 仍为单 TYPE |
| FRIC/UINTER/GAPCON/GAPUNIT 类型 | P0 | **DONE** | `PH_Cont_Def.f90`(61-70) 定义 `PH_Contact_UINTER_Ctx/State`、`PH_Contact_GAPCON_Ctx`、`PH_Contact_VUINTER_Ctx` 等类型 |
| FRIC/UINTER 完整对偶(ABI 桥) | P1 | **UNDONE** | 类型已定义但无对应 USER 子程序桥实例 |
| PH_Cont_Stp_Ctl_Algo | P1 | **UNDONE** | `L4_PH/Contact/` 中 `PH_Cont_Algo` 已定义(不带 Stp_Ctl 子结构)，但未拆出 `stp_ctl` 辅模块；LoadBC 已有 `PH_Ldbc_Stp_Ctl_Algo` 可参考 |
| PH_Cont_Ctx/State 遗留 | P1 | **UNDONE** | `PH_Contact_InterfaceCtx`(338)/`PH_Contact_InterfaceState`(616) 仍为 PUBLIC，违反 R-09(去Base)；需迁移至 `PH_Cont_Ctx/State` |
| BVH 精确距离计算 | P0 | **UNDONE** | `PH_Cont_Core`/`PH_Cont_Mgr` 实现 NTS 投影框架，但精确距离计算未完成(CPA: CONTRACT.md 标记 0%) |
| NTS 投影核心 | P0 | **DONE** | NR 迭代+自然坐标求解完整 |

---

> **END** — Contact Domain Inventory v1.0
