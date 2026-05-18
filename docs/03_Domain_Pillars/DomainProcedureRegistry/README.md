# 全层-域-源码清单（Domain Procedure Registry）

本目录支持 **双轨**：**设计意图（目标态）** 与 **源码快照（现状态）**，用于残缺实现与完整设想不一致时，**以设计目录为主、逆向改造对齐** `ufc_core`。

---

## 双轨工作流（设计真源 → 源码快照 → 逆向对齐）

1. **`design/`（主）**  
   按层/域建立 **`INTENT.md`**（模板见 [`design/_TEMPLATE_INTENT.md`](design/_TEMPLATE_INTENT.md)），写清：问题与目标、四型、目标 `TYPE` 字段、核心过程命名、与 PPLAN/域 `CONTRACT.md` 的引用。  
   **允许领先于当前残缺源码**；不强制与旧推断清单逐字一致。

2. **`generated/`（辅）**  
   由 [`UFC/tools/domain_procedure_registry_scan.py`](../../tools/domain_procedure_registry_scan.py) 从 `ufc_core` **机械生成**：每个 **纳入扫描** 的 `.f90` 对应一篇 Markdown（**命名 — 三段式/四段式/域级** 对照块、`MODULE`、`TYPE` 块摘录、`SUBROUTINE`/`FUNCTION`、`INTERFACE` 轮廓）。  
   **输出路径**：**镜像** `ufc_core` 相对路径、扩展名改为 `.md`（例：`generated/L3_MD/Elem/Solid3D/MD_ElemSld3D_Algo.md`）；与 [PPLAN「目录权威分类」](../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 一致；**stem** 为源码文件名（三段式/四段式见各篇「命名」节）。`Source` 字段保留真实 `ufc_core` 相对路径。  
   用于 diff 与差距分析，**不作为设计真源**。

3. **逆向对齐**  
   以 `design/` + 域合同为验收标准，**分批**改 Fortran：补类型字段、补过程、改名、删死代码；每域闭环后再扩下一域。

---

## 层与 L2 范围

| 层 | `ufc_core` 路径 | `generated/` |
|----|------------------|--------------|
| L1 | `L1_IF/` | 有 |
| **L2** | **`L2_NM/`**（**排除** `ExternalLibs/` 路径段） | 有 |
| L3 | `L3_MD/` | 有 |
| L4 | `L4_PH/` | 有 |
| L5 | `L5_RT/` | 有 |
| L6 | `L6_AP/` | 有 |

**L2 说明**：仅 **`ExternalLibs/`** 不生成逐文件清单（第三方封装聚合）；L2 其余子域（`Base` / `Bridge` / `Matrix` / `Solver` / `TimeInt` 等）**全部纳入**。详见 [`L2_SCOPE.md`](L2_SCOPE.md)。

---

## 权威与边界

| 项目 | 说明 |
|------|------|
| **设计真源** | **`design/` 下 `INTENT.md`**（逐步补全）+ 各域 **`ufc_core/.../CONTRACT.md`** + **`docs/05_Project_Planning/PPLAN/`**。 |
| **现状真源** | **`ufc_core/` 源码**；`generated/` 为其派生物。 |
| **解析局限** | 生成器为 **正则 + 行扫描**；续行、`#include`、复杂泛型等可能误判；长 `TYPE` 体会截断并注明。 |
| **过程算法叙事（REPORTS）** | 八域 **`*_Procedure_Algorithm.md`** 与全景 **`Procedure_Algorithm_L3L4L5_synthesis.md`**：根目录为 **stub**（稳定 URL），长文在 **`REPORTS/archive/`** 同名文件；入口表见 [`REPORTS/Master_Domain_Inventory_Index.md`](../../../REPORTS/Master_Domain_Inventory_Index.md) §2、[`REPORTS/README.md`](../../../REPORTS/README.md) §1。**不**由 `domain_procedure_registry_scan.py` 产出，也**不与** `generated/` 做机器 diff；用于三轴/Pipeline 叙事与评审索引。 |

### 报告侧与 Registry 的对账优先级

发生冲突或叙述漂移时，**从高到低**：各域 **`ufc_core/**/CONTRACT.md`** → 本目录 **`design/*/INTENT.md`**（及 `manifest.json`）→ **`ufc_core/` 源码** + **`generated/`**（及 **`REPORTS/DESIGN_GENERATED_DRIFT.md`** / `domain_procedure_registry_align.py` 输出）→ **`REPORTS/archive/*_Procedure_Algorithm.md`** 等叙事稿。修订叙事稿**不得**反向改写合同或 INTENT；须在合同/Registry 收敛后再回写报告。

---

## 命名与四型规范（人工审阅用）

见 **[CONVENTIONS.md](CONVENTIONS.md)**。

---

## 如何重新生成 `generated/`

在仓库根执行（需 Python 3.9+）：

```bash
python UFC/tools/domain_procedure_registry_scan.py
```

输出：**`generated/`**（勿手改；与 `README.md`、`design/`、`CONVENTIONS.md` 分离）。路径为 **层 / 域级 / stem.md**，见上文「输出路径」。

**层索引**（含 **`L2_NM`**，且不含 `ExternalLibs` 下 `.f90`）：

- [`generated/L1_IF/_LAYER_INDEX.md`](generated/L1_IF/_LAYER_INDEX.md)
- [`generated/L2_NM/_LAYER_INDEX.md`](generated/L2_NM/_LAYER_INDEX.md)
- [`generated/L3_MD/_LAYER_INDEX.md`](generated/L3_MD/_LAYER_INDEX.md)
- [`generated/L4_PH/_LAYER_INDEX.md`](generated/L4_PH/_LAYER_INDEX.md)
- [`generated/L5_RT/_LAYER_INDEX.md`](generated/L5_RT/_LAYER_INDEX.md)
- [`generated/L6_AP/_LAYER_INDEX.md`](generated/L6_AP/_LAYER_INDEX.md)

总表：[`generated/_REGISTRY_STATS.md`](generated/_REGISTRY_STATS.md)

---

## 设计意图入口

- [`design/README.md`](design/README.md)  
- L2 子域索引：[`design/L2_NM/README.md`](design/L2_NM/README.md)

---

**创建日期**：2026-04-20  
**更新**：2026-05-13 — 增补「过程算法叙事（REPORTS）」与对账优先级（stub/archive 与 `generated/` 边界）  
**生成脚本**：[`UFC/tools/domain_procedure_registry_scan.py`](../../tools/domain_procedure_registry_scan.py)
