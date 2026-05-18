# `L4_PH` / `Element` 设计意图（域桶）

> **域桶**：`ufc_core/L4_PH/Element/`（含 Acoustic、Beam、Shell、Solid2D/3D、Shared 等子域）。  
> **验收向**：本 INTENT + 子域 [`CONTRACT.md`](../../../../../ufc_core/L4_PH/Element/CONTRACT.md) + [`CONVENTIONS.md`](../../../CONVENTIONS.md) §1.1–§1.2。

## 1. 问题与目标

- **问题**：遗留 **`MODULE PH_*_Algo`** 与四型中 **`TYPE …_Algo`** 同名易混；与「过程体用 `_Ops`」总规范不一致。
- **目标**：`Element/` 子树内 **编译单元（MODULE）** 统一为 **`PH_*_Ops`**；旧数字尾巴模块已迁移为无数字后缀；**四型** 仍保留 **`TYPE …_Algo`**（如 `TYPE(PH_ElemDomain_Algo)`）。
- **工具**：`UFC/tools/migrate_l4_ph_element_algo_to_ops.py`（`--dry-run` / `--apply`，固定 `L4_PH/Element` + `PH_` 前缀）；其它域桶请用通用驱动 `UFC/tools/migrate_ufc_module_algo_to_ops.py`（`--under`、`--stem-prefix`、`--apply`）。

## 2. 与 `Mesh` / L3 绑定

- `L3_MD/Element/Elem/MD_Elem_PHBinding.f90` 中 **`module_name = "PH_…_Ops"`** 与 L4 模块名一致（字符串字面量已由迁移脚本与人工校对对齐）。

## 3. 与 `generated/` / 推断清单

- 跑 `python UFC/tools/domain_procedure_registry_scan.py` 后，`generated/L4_PH/Element/...` **镜像**源码树。  
- 推断清单中 **`PH_*_Algo`** 若表示 **四型数据语义**，仍以 **TYPE 名** 为准；**MODULE 实现名** 以本域 **`PH_*_Ops`** 为准。

## 4. 参考

- [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md)  
- [`UFC_命名与数据结构规范.md`](../../../../UFC_命名与数据结构规范.md) §3.2  
- 姊妹域桶：[`../L3_MD/Mesh/INTENT.md`](../../L3_MD/Mesh/INTENT.md)

## 5. L3/L4/L5 域柱同步锚点

**分类**：全柱主计算域（L3 Mesh/Element 真源、L4 Element 局部物理核、L5 Assembly 归约）。

| 层 | 角色 | 目标模块 | 说明 |
|----|------|----------|------|
| L3_MD | Mesh/Element 拓扑真源 | `MD_Mesh_Def`, `MD_Mesh_API`, `MD_Mesh_Domain`, `MD_Elem_*` | 节点、单元、连通、单元族元数据；求解期只读 |
| L4_PH | 单元局部核 | `PH_ElemDomain_Ops`, `PH_ElemContm_Ops`, `PH_Elem_Reg`, family `PH_Elem*` | `Compute_Ke/Fe/BMatrix` 与族内核，高斯积分和形函数 |
| L5_RT | 全局装配消费 | `RT_Asm_Solv`, `RT_Asm_DofMap`, `RT_Asm_Proc` | 单元循环、DoF 映射、Triplet/CSR 汇总 |

**跨层主链**：`MD_Mesh/Element Desc -> PH_L4_Populate_Element -> elem cache / elem_to_mat_map -> PH_Element_Compute_Ke/Fe -> RT_Asm Triplet/CSR`。

**硬约束**：
- L4 Element 不持久化模型树，不做全局 CSR 装配。
- Element 热路径应优先读 Populate cache；允许单点 fallback，但不得在 IP 内层遍历 L3 网格库。
- L5 Assembly 是 Ke/Fe 的归约位置，禁止绕过 L4 金线入口自行重算单元物理核。
