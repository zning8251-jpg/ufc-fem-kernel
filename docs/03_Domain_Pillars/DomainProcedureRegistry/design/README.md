# 设计意图目录（`design/`）— 真源优先

本目录与 **`generated/`** 并列：

| 目录 | 角色 |
|------|------|
| **`design/`** | **目标态**：按层 → 域 →（可选）功能集，描述 **应有** 的四型、`TYPE` 字段意图、核心 `SUBROUTINE`/`FUNCTION` 与命名；**允许领先于残缺源码**。 |
| **`generated/`** | **现状态**：由脚本从 `ufc_core` **机械抽取** 的 TYPE/过程清单；**目录布局镜像** `ufc_core` 相对路径（`.f90`→`.md`）；**不**自动代表设计完备。 |

**过程算法八域叙事（REPORTS）**：[`Material_Procedure_Algorithm.md`](../../../../REPORTS/Material_Procedure_Algorithm.md) 等 **根 stub**（正文在 [`REPORTS/archive/`](../../../../REPORTS/archive/)）与 [`Procedure_Algorithm_L3L4L5_synthesis.md`](../../../../REPORTS/Procedure_Algorithm_L3L4L5_synthesis.md) 为 **人读索引**，与 `INTENT.md` / `manifest.json` **无自动同步**；对账规则见 [Registry 根 `README.md` 权威表 §「过程算法叙事」与「对账优先级」](../README.md)。

---

## 主路径：推断清单 ↔ `generated/` 双向对齐（`design` 真源）

与 [`docs/05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md`](../../../05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md)（下称 **推断清单**）一致：**推断清单**给出域级「设计意图 + 子程序清单 + 接口契约」的 **信息密度与叙述结构**；本仓库以 **`design/`** 为可执行真源，把其中可机器校验的部分落到 **`manifest.json`**，再与 **`ufc_core`**、**`generated/`** 做 **双向对齐**。

| 方向 | 含义 |
|------|------|
| **design → 实现** | `manifest.json` 列出该域桶下 **应有的** `.f90`（及可选 `MODULE` 名）；对齐工具报告缺文件、多余文件、`stem`/`MODULE` 不一致、缺 Registry 页。 |
| **实现 → design** | 初稿可用 `python UFC/tools/domain_procedure_registry_align.py --bootstrap design/<LAYER>/<Domain>/manifest.json` 从 `ufc_core` 生成，再由人 **删减、标注 `module` 例外、对齐推断清单**；**不以残缺代码反写设计**，最终以 `INTENT.md` + 域 `CONTRACT.md` 为准。 |

**机器可读契约**：[`manifest.schema.json`](manifest.schema.json)。**对齐工具**：`UFC/tools/domain_procedure_registry_align.py`（默认输出 [`../../../../REPORTS/DESIGN_GENERATED_DRIFT.md`](../../../../REPORTS/DESIGN_GENERATED_DRIFT.md)，可用 `--out` 覆盖；exit code 供 CI 门禁）。

**命名口径**：文档与 `manifest` 中的 **逻辑主线** 与 [CONVENTIONS.md](../CONVENTIONS.md) §1.1 **三段式**一致；物理 `stem` 与第四段角色后缀见 §1.2；**建议** `MODULE` 名与主文件名 `stem` 一致，例外须在 `manifest` 中显式写 `"module"`。

---

## 工作流（逆向对齐 + 机器漂移）

1. **在 `design/<LAYER>/<Domain>/` 下** 建立或补全 `INTENT.md`（可用 [`_TEMPLATE_INTENT.md`](_TEMPLATE_INTENT.md) 复制），并维护同目录 **`manifest.json`**（可 `--bootstrap` 后编辑）。  
2. **跑生成器** 更新 `generated/`：`python UFC/tools/domain_procedure_registry_scan.py`。  
3. **跑对齐**：`python UFC/tools/domain_procedure_registry_align.py`，查看 `REPORTS/DESIGN_GENERATED_DRIFT.md` 与终端输出。  
4. **做差距表（人读）**：`INTENT.md` §5 与推断清单、Registry、源码交叉审阅 — 缺过程 / 缺字段 / 命名漂移。  
5. **改源码**：以 `design/`、域 `CONTRACT.md`、PPLAN 为准，**分批 PR** 对齐实现。  

源码若与想象差距大，**不以残缺实现反推设计**；以 **`design/` + PPLAN + 域合同** 收敛后再改代码。

---

## 层级子目录

按 **`L1_IF` / `L2_NM` / `L3_MD` / `L4_PH` / `L5_RT` / `L6_AP`** 与 `ufc_core` 顶层一致建子文件夹；域级子目录可与源码树同名，便于交叉链接。

**批量补齐（与 `align.py` 对账）**：在仓库根执行  
`python UFC/tools/bootstrap_design_domain_intents.py`  
可为每个「含至少一个 `*.f90` 的一级域桶」生成缺失的 **`INTENT.md`**，并用与 **`align.py --bootstrap`** 相同的规则刷新 **`manifest.json`**（**跳过** `ExternalLibs` 路径；**跳过**源码树中 **无 `MODULE` 行** 的 `.f90`，以免与 stem/MODULE 规则冲突）。随后务必：  
`python UFC/tools/domain_procedure_registry_scan.py` → `python UFC/tools/domain_procedure_registry_align.py`。

**PR 边界（建议）**：单 **域桶** 或单 **子域子树** + **构建通过**；域级 **物理目录拆分** 单独走 **PPLAN**，与 `_Ops` 收敛交叉时 **先定目录与 CMake，再改模块名与 manifest**（见 [`UFC_ufc_core_目录权威分类.md`](../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) §9.1）。

另见 **L2 索引说明**（[`L2_NM/README.md`](L2_NM/README.md)）与模板 [`_TEMPLATE_INTENT.md`](_TEMPLATE_INTENT.md)。
