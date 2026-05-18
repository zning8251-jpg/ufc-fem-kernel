# UFC 功能模块全景清单与模板库规划 (Master Feature Registry)

> **核心原则**：
> 1. `ufc_core` 中有多少个子目录/功能模块，`ufc_templates` 中就必须对等建立多少个**带有专属 Feature_Manifest.md 的功能目录**。
> 2. 它们互不冲突，高度正交。

## 1. 真实目录层级映射全览 (基于 `ufc_core` 探明)

### L1_IF (基础设施层)
* **域 (Domain)**: `Base`, `Error`, `IO`, `Log`, `Memory`, `Monitor`, `Precision`, `Registry`
* **功能模块级 (Sub-domain/Feature)**: `AI`, `Parallel`, `Symbol`, `Checkpoint`...

### L2_NM (核心数学层)
* **域 (Domain)**: `Base`, `Bridge`, `Matrix`, `Solver`
* **功能模块级 (Sub-domain/Feature)**: `BVH`, `Conv`, `Coupling`, `Direct`, `Iterative`...

### L3_MD (数据模型与物理本构层 - 唯一真源)
* **域 (Domain)**: `Bridge`, `Contact`, `Damage`, `Elas`, `EoS`, `HyperElas`, `Plast`, `Registry`, `Viscoelas`
* **功能模块级 (Sub-domain/Feature)**: `MohrCoulomb`, `DruckerPrager`, `J2`, `GTN`, `User`...

### L4_PH (物理计算与空间离散层)
* **域 (Domain)**: `Element`, `Material` (驱动器与映射)
* **功能模块级 (Sub-domain/Feature - Element族)**: `Acoustic`, `Beam`, `Cohesive`, `Dashpot`, `Membrane`, `Shell`, `Solid2D`, `Solid3D`, `Spring`, `Truss`, `User`...

### L5_RT (运行调度层)
* **域 (Domain)**: `Assembly`, `Bridge`, `Contact`, `Element`, `LoadBC`, `Logging`, `Material`, `Output`, `Solver`, `StepDriver`, `WriteBack`
* **功能模块级 (Sub-domain/Feature)**: `Mesh`, `Coupling`...

### L6_AP (应用流层)
* **域 (Domain)**: `Bridge`, `Config`, `Input`, `Job`, `Output`, `Registry`, `Solver`, `UI`
* **功能模块级 (Sub-domain/Feature)**: `Command`, `Parser`, `Script`...

---

## 2. 功能模块级别工单 (Manifest) 生产策略

正如您所说：“有多少个子程序/模块，就应该有多少张规格书工单。”
在 UFC 这个拥有几百个单元、几十种材料的庞大架构中，这被称为**“表驱动的架构演化”**。

在接下来的模板库 (`ufc_templates`) 搭建中，我们将执行以下步骤：
1. **清空旧物**：移除之前建立的混淆视听的临时 `CPS4` 和 `VonMises`。
2. **完全对齐真实目录树**：使用脚本，将 `ufc_templates` 的目录树**100% 同步**为上面扫描出的 `ufc_core` 目录结构。
3. **入驻工单**：在每一个末端功能模块文件夹中（例如 `ufc_templates/L4_PH/Element/Solid2D/`），放置一张**完全独立、绝对不冲突**的专属《Feature_Manifest.md》。

您随时可以在这里对成百上千张工单进行审阅、合并或修改。
只要工单无误，机床就可以瞬间压制出该目录下对应的所有 `.f90` 代码。
