# UMAT 参数 ↔ UFC 类型 · 尺度与后缀（短版索引）

**主文档（讨论已合订）**：请阅读 **`Material_L3L4L5_four_type_UMAT_discussion_synthesis.md`**  
路径：`UFC/REPORTS/Material_L3L4L5_four_type_UMAT_discussion_synthesis.md`  

**跨域柱模板（材料外推广）**：**`Pillar_L3L4L5_CrossLayer_Design_Template.md`**（L3/L4/L5 不变量、冷/热阶段、Element/Contact/LoadBC/Output/WriteBack 映射表）；材料合订本 **§13** 为索引入口。  

**单元 / UEL 对偶草稿**：**`Element_L3L4L5_four_type_UEL_discussion_synthesis.md`**（与材料 **§14** 交叉维护；扁平 UEL→四型 + 全局短签名策略）。

该合订本包含：

- L3 / L4 / L5 职责与澄清（含「L5 不是四型 Algo 主角」）
- 功能 = 四型 + Args + 主辅嵌套 + 过程（材料域解读）
- UMAT 在求解链路中的位置、与 `PH_Mat_Execute_Flow` 的对应
- 内置本构与用户 UMAT 统一性结论
- 对 Q1 / Q2 的正式答复
- 实施侧注记（Dispatch 可选 `material_dom`、SDV 双写、Populate、J2 试点等）
- **附录 A–E**：原「参数对照表 + S/T 尺度 + 动作后缀 + 一行记忆」
- **§8 / §10–§14 / 附录 F**：族级四型与 User 路径、**不推荐双四型**、**`PH_MAT_USER`**、**§8.4**、**§10.7–§10.14**、**§11**、**§12**、**§13** → **`Pillar_L3L4L5_CrossLayer_Design_Template.md`**、**§14** UEL/单元域柱与 `RT_Elem_UEL` 现状、附录 F

本文件仅作 **索引**，避免与合订本双处维护；若外链曾指向本文件名，请改指向合订本。
