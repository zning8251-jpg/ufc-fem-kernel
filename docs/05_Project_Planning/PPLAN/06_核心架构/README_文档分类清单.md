# PPLAN/06_核心架构 - 文档分类清单

> **路径**: `PPLAN/06_核心架构/`
> **文档数量**: 109 个 MD 文件（含子目录中的 5 个 README + 正交设计子目录）
> **最后更新**: 2026-04-15

---

## 一、文档分类总览

| 类别 | 文件数 | 说明 |
|------|--------|------|
| **架构总纲类** | 8 | 架构设计总纲、脊柱索引、蓝图导航 |
| **类型系统类** | 6 | TYPE系统设计、完整规划、版本策略 |
| **层域拆解类** | 8 | L1-L6 各层完整域级拆解 |
| **四链贯通类** | 3 | Assembly/Element/Mesh 四链贯通设计 |
| **三维坐标类** | 5 | 正交坐标设计、快速参考表 |
| **正交设计类** | 55 | UFC分析类型正交设计方案（含子目录） |
| **ABAQUS映射类** | 4 | ABAQUS子程序与UFC类型映射 |
| **实施报告类** | 4 | 端到端验证、执行报告 |
| **其他** | 5 | 错误传播、Section架构等 |

---

## 二、架构总纲类 (8 个)

| 文件名 | 说明 |
|--------|------|
| `UFC_Architecture_Spine_Index.md` | UFC 架构脊柱索引（设计基因、各章锚点） |
| `UFC_完整架构蓝图_综合导航索引_v1.0.md` | 完整架构蓝图导航索引 |
| `UFC_完整架构体系设计_L1-L6_26域_递归分解_v1.0.md` | L1-L6 26域递归分解 |
| `UFC_层级域级f90文件推断清单_v2.0.md` | 层级域级 f90 文件推断清单（文件名 v2.0，正文已迭代至 v3.0 级） |
| `UFC_完整模块映射索引_336rows_v1.0.md` | 完整模块映射索引 336行 |
| `README_架构完善章程.md` | 架构完善章程说明 |
| `README.md` | 本目录导航 |

---

## 三、类型系统类 (6 个)

| 文件名 | 说明 |
|--------|------|
| `L3MD_Type_System_Design.md` | L3_MD 层 TYPE 系统设计（1,644行） |
| `UFC_Complete_Type_Planning_v1.md` | 完整 TYPE 规划 v1 |
| `UFC_Full_Architecture_FourCategories_Inventory.md` | 四类完整架构清单 |
| `Version_Compatibility_Policy.md` | 版本兼容性策略 |
| `ElemMat_Orthogonal_Design.md` | 单元-材料正交设计 |
| `L3_MD_Nested_Desc_Design.md` | L3_MD 嵌套 Desc 设计 |

---

## 四、层域拆解类 (8 个)

| 文件名 | 说明 |
|--------|------|
| `L1_IF_基础设施层_完整域级拆解_v1.0.md` | L1_IF 层完整域级拆解 |
| `L1_IF_接口工作流补全_v1.0.md` | L1_IF 接口工作流补全 |
| `L2_NM_数值算法层_完整域级拆解_v1.0.md` | L2_NM 层完整域级拆解 |
| `L3_MD_模型数据层_完整域级拆解_v1.0.md` | L3_MD 层完整域级拆解 |
| `L4_PH_物理计算层_完整域级拆解_v1.0.md` | L4_PH 层完整域级拆解 |
| `L5_RT_运行时协调层_完整域级拆解_v1.0.md` | L5_RT 层完整域级拆解 |
| `L6_AP_应用层_完整域级拆解_v1.0.md` | L6_AP 层完整域级拆解 |
| `L6_AP_应用层工作流补全_v1.0.md` | L6_AP 应用层工作流补全 |

---

## 五、四链贯通类 (3 个)

| 文件名 | 说明 |
|--------|------|
| `Assembly_四链贯通设计.md` | Assembly 四链贯通设计 |
| `Element_四链贯通设计.md` | Element 四链贯通设计 |
| `Mesh_四链贯通设计.md` | Mesh 四链贯通设计 |

---

## 六、三维坐标类 (5 个)

| 文件名 | 说明 |
|--------|------|
| `UFC_三维坐标设计_决策总结与执行指南.md` | 三维坐标设计决策与执行 |
| `三维坐标快速参考表_开发工具.md` | 三维坐标快速参考表 |
| `三维坐标设计_交付清单与质量报告.md` | 交付清单与质量报告 |
| `1-based编号改进方案_验收文档.md` | 1-based 编号改进验收文档 |
| `1-based编号改进_快速验收清单.md` | 1-based 编号快速验收清单 |

---

## 七、ABAQUS映射类 (4 个)

| 文件名 | 说明 |
|--------|------|
| `Abaqus_User_Subroutine_Mapping_to_UFC.md` | ABAQUS 用户子程序到 UFC 的映射（41KB） |
| `Abaqus_UFC_全域映射矩阵.md` | Abaqus-UFC 全域映射矩阵 |
| `ABAQUS_Subroutine_UFC_TYPE_Mapping.md` | ABAQUS 子程序 UFC TYPE 映射 |
| `ABAQUS_Section_Architecture.md` | ABAQUS Section 架构 |

---

## 八、实施报告类 (4 个)

| 文件名 | 说明 |
|--------|------|
| `P3_端到端集成验证_完整工作流_v1.0.md` | P3 端到端集成验证工作流 |
| `0-based_to_1-based_EXECUTION_REPORT.md` | 0-based 到 1-based 执行报告 |
| `01_正交设计_AnalysisType_Group_开发实现报告.md` | 正交设计开发实现报告 |
| `01_正交设计_AnalysisType_Group_重构完成报告.md` | 正交设计重构完成报告 |

---

## 九、其他文档 (5 个)

| 文件名 | 说明 |
|--------|------|
| `Error_Propagation_Architecture.md` | 错误传播架构（30KB） |
| `Section_ElemMat_Compat_Matrix.md` | Section-ElemMat 兼容矩阵 |
| `UFC_UMAT_Props_Statev_Layout.md` | UMAT 属性 Statev 布局 |
| `UFC_Element_Material_Extension_Principles.md` | 单元材料扩展原则 |
| `UFC_后分析类型扩充_架构完善总章程_v1.0.md` | 后分析类型扩充章程 |

---

## 十、正交设计子目录

**路径**: `PPLAN/06_核心架构/UFC分析类型正交设计方案/`

### 10.1 域级设计文档（清理后）

| 文件名 | 说明 |
|--------|------|
| `L4_PH_LoadBC_域级设计文档.md` | L4_PH LoadBC 域级设计 |
| `L5_RT_Solver_域级设计文档.md` | L5_RT Solver 域级设计 |
| `L5_RT_Material_域级设计文档.md` | L5_RT Material 域级设计 |
| `L2_NM_Matrix_域级设计文档.md` | L2_NM Matrix 域级设计 |

### 10.2 其他域级设计文档

| 层级 | 文档数 | 说明 |
|------|--------|------|
| L1_IF | 6 | Base/Error/IO/Log/Memory/Monitor |
| L2_NM | 4 | Base/Solver/TimeInt (+ Matrix) |
| L3_MD | 13 | Analysis/Assembly/Boundary/Bridge/Constraint等 |
| L4_PH | 9 | Bridge/Constraint/Contact/Element等 (+ LoadBC) |
| L5_RT | 11 | Analysis/Assembly/Contact/Element等 (+ Solver/Material) |
| L6_AP | 5 | Command/GUI/Input/Output/Solver |
| 其他 | 2 | `phase5_核心域级交付总结_v1.0.md`, `00_完整性检查...md` |

### 10.3 01_正交设计_AnalysisType_Group 子目录

**路径**: `PPLAN/06_核心架构/01_正交设计_AnalysisType_Group/`

| 子目录 | 文件数 | 内容 |
|--------|--------|------|
| `01_顶层设计/` | 1 | 维度定义与设计原理 |
| `02_核心映射表/` | 1 | PROC映射与约束矩阵 |
| `03_实现指导/` | 1 | Fortran实现框架 |
| `04_快速参考/` | 1 | 速查表 |
| `05_决策文档/` | 1 | 设计决策记录 ADR |

---

## 十一、快速导航

| 类别 | 入口文档 |
|------|----------|
| 架构总纲 | [UFC_Architecture_Spine_Index.md](UFC_Architecture_Spine_Index.md) |
| TYPE系统 | [L3MD_Type_System_Design.md](L3MD_Type_System_Design.md) |
| ABAQUS映射 | [Abaqus_User_Subroutine_Mapping_to_UFC.md](Abaqus_User_Subroutine_Mapping_to_UFC.md) |
| 四链贯通 | [Assembly_四链贯通设计.md](Assembly_四链贯通设计.md) |
| 三维坐标 | [UFC_三维坐标设计_决策总结与执行指南.md](UFC_三维坐标设计_决策总结与执行指南.md) |
| 域级设计 | [UFC分析类型正交设计方案/](UFC分析类型正交设计方案/) |
| 实施报告 | [P3_端到端集成验证_完整工作流_v1.0.md](P3_端到端集成验证_完整工作流_v1.0.md) |

---

## 十二、相关目录

| 目录 | 内容 |
|------|------|
| `PPLAN/02_域级建模/` | 域级建模文档（建模/审查/合同卡） |
| `PPLAN/07_设计文档/` | 域级设计文档（LoadBC/Element/Contact） |
| `六层架构拆分/00-总纲/` | 域级划分规范、命名标准 |
| `templates/` | Fortran 代码模板 |

---

*最后更新: 2026-04-15*
