# UFC 层级-域-功能-子程序 速查（v1.1：六层+四类+四链+三步+三级+两图+一体）

- **机制总览 / 热路径 / Populate**：`docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md`（四链 + 数据结构拆解 + 头注释口径）
- **L4/L5 波次与主轴**：`docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_二元结构主轴与波次路线图.md`
- **头注释+Chains 示例**: `UFC/ufc_core/L5_RT/Solv/RT_Solv_Nonlin_Core.f90` + `RT_Solv_Nonlin_Core_Chains.md`
- **容器与命名真源**：`docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md`；`docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md`
- **检查清单**：`docs/03_Domain_Pillars/Layer_Architecture_Splits/03-实施路线/04-05-执行检查清单.md`

## 模板必含（一次性做完）

- **四链**: 理论链 + 逻辑链 + 计算链 + 数据链（头注释 + 可选 Mermaid）
- **数据结构拆解**: 容器路径、Desc/State/Algo/Ctx 存放方式与嵌套
- **Contents**: Module 头部 Types（A-Z）、Subroutines（A-Z）列举表

## 四元组

- **Layer**: L3_MD | L4_PH | L5_RT | L6_AP
- **Domain**: BC, Step, Solv, Mat, Elem, Cont, Asm, Job, ...
- **Feature**: 驼峰，如 Dirichlet, Static, Nonlin, Hex8, Penalty
- **Subroutine/Module**: 如 RT_Solv_Nonlin_Core（可选）

## 一句话触发示例

- 「用 UFC 模板为 L4_PH BC Dirichlet 生成并实施」
- 「ufc gen L5_RT Step Static」
- 「按 UFC 规则生成 L3_MD Mat Elastic 模板并直接实施」
- 「用 UFC 模板为 L3_MD Amp Eval 生成并实施」（已实施：MD_Amplitude_Core + MD_Amplitude_Core_Chains.md）
- 「针对 Brg，用 UFC 模板为 L3_MD Amp Eval 生成并实施」（已实施：MD_ModelDataPlatform_Brg 头注释 + Amp Eval 逻辑链 + MD_ModelDataPlatform_Brg_Chains.md）
