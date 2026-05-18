# 命名与清单字段约定（Domain Procedure Registry）

本文档供 **人工审阅** `generated/` 与 **`design/` 下 `INTENT.md`** 时对照；**设计真源以 `design/` + 域 `CONTRACT.md` 为准**，残缺源码可被逆向改造对齐。

---

## 0. 双轨命名空间

| 空间 | 用途 |
|------|------|
| **`design/<LAYER>/<Domain>/INTENT.md`** | 目标态四型、字段、过程名、差距表；**允许领先于实现**。 |
| **`design/<LAYER>/<Domain>/manifest.json`** | （可选）**机器可读**域桶内预期 `.f90` 与可选 `MODULE` 名；与 `generated/`、`ufc_core` 由 `UFC/tools/domain_procedure_registry_align.py` 对账；模式见同目录上级的 [`design/manifest.schema.json`](design/manifest.schema.json)。 |
| **`generated/...`** | 从 `ufc_core` 机械抽取的现状；路径 **镜像** `ufc_core` 相对路径、仅扩展名改为 **`.md`**（例：`L3_MD/Elem/Solid3D/MD_ElemSld3D_Algo.md`），与 [PPLAN「目录权威分类」](../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；`Source` 仍指向源码路径；用于 diff。 |

---

## 1. 模块与文件（六层前缀）

| 层 | 典型 `MODULE` 前缀 | 文件命名习惯 |
|----|-------------------|--------------|
| L1 | `IF_*` | `IF_<Area>_<Role>.f90`（如 `IF_Err_Brg`） |
| L2 | `NM_*` | `NM_<Area>_<Role>.f90`；数值子域（矩阵 / 求解 / 时间积分等）；**`ExternalLibs/` 不参与 Registry 生成** |
| L3 | `MD_*` | `MD_<Domain>_<Role>.f90`；`Def` / `Algo` / `Brg` / `Idx` / `Sync` 等后缀与合同一致 |
| L4 | `PH_*` | `PH_<Domain>_*.f90` |
| L5 | `RT_*` | `RT_<Domain>_*.f90` |
| L6 | `AP_*` | `AP_<Domain>_*.f90` |

**同一层级内**：`MODULE` 名与主文件名（去 `.f90`）**建议一致**，便于 `USE` 与文档交叉检索。

### 1.1 主线名（三段式，默认）

**逻辑名**（文档 / `design/` / 口头对齐）：

`{Layer}_{Domain}_{Feature}`

- **`{Layer}_`**：`IF_` / `NM_` / `MD_` / `PH_` / `RT_` / `AP_`（层前缀）。  
- **`{Domain}_`**：该层下的 **域或子域** 占一个槽位；若目录有多层，**用子域缩写合并进这一段**，避免叠成 `Layer_Domain_Subdomain_Feature` 四段语义。  
- **`{Feature}`**：功能模块名，**段内推荐 PascalCase 单团**（如 `StructMeta`），段间用 **下划线** 分隔（例：`IF_Base_StructMeta`）。

> 默认 **不写** `_Def` / `_Ops` 等第四段：能用一个编译单元说清楚、且体量适中，就用主线名。

### 1.2 四段式（与三段混用）：何时加后缀

在 **同一功能主线** 上，当 **单个 `.f90` 过长**（经验阈值 **约 ≥5000 行**）或 **必须用拆文件打破 `USE` 环 / 分离类型与过程** 时，在主线名后增加 **第四段 — 角色后缀**。

**完整 MODULE 角色后缀闭集、职责表与选用策略**以 **[`UFC/docs/UFC_命名与数据结构规范.md`](../UFC_命名与数据结构规范.md) §3.2** 为权威（含 `_Mgr` `_Core` `_Solv` `_Defn` … 与本文 `_Def` `_Types` … 的 **合并闭集**）。

下表为 **L3 域内拆分** 最常用的 **子集**（其余角色见权威节）：

| 后缀 | 典型职责 |
|------|----------|
| `_Def` | 类型、常量、轻量 `TYPE` 绑定；Desc/State 真相源倾向 |
| `_Types` | 纯类型/枚举聚合（与 `_Def` 二选一惯例，勿同功能再拆第三文件） |
| `_Ops` | **模块**过程/运算主体（**推荐**）；与 TYPE 四型后缀 **`_Algo` 解耦**，见 [`UFC_命名与数据结构规范.md`](../UFC_命名与数据结构规范.md) §3.2 |
| `_Algo` | **仅遗留 MODULE 名**；新代码勿新增，迁移为 `_Ops` |
| `_Proc` | 过程密集、与 **`_Ops`** 互斥于**同一主线**（二选一，避免 `_Ops` + `_Proc` 双拆除非行数仍失控） |
| `_Brg` | 跨层 / L6 API / Bridge |
| `_Idx` | 依赖全局容器或索引入口的薄 API |
| `_Sync` | Legacy→域 等同步编排（若域内确有此角色） |

命名形态：`**{Layer}_{Domain}_{Feature}_{Role}**`（四段），其中 **`{Layer}_{Domain}_{Feature}` 与三段主线保持一致**，保证检索与「主线」一致。

### 1.3 防碎化：文件不能过小

后缀拆分是为了 **可读 + 依赖 + 体量**，不是为了 **一过程一文件**。

- **避免**：极短文件（例如仅 **几十～百余行**、只放一两个无环依赖的 `TYPE`）单独成 `MODULE`，会导致 **模块数量爆炸**、`USE` 面扩散、构建与审查成本上升。  
- **倾向**：同一主线内，若干紧密耦合的类型/过程 **先留在同一 `.f90`**，直到 **行数或环依赖** 迫使拆分。  
- **合并优先**：若拆出的子文件长期低于 **约 300～500 行** 且无独立复用价值，考虑 **并回** 相邻 `_Def` / **`_Ops`** 之一。

---

## 2. 四型（Desc / State / Algo / Ctx）

| 四型 | 命名倾向 | 说明 |
|------|-----------|------|
| Desc | `*_Desc`、`*_Def`（特化 Desc） | 建模期写入、求解期只读 |
| State | `*_State`、`*_Sta` | 步内/缓存可变 |
| Algo | **`TYPE`** 名用 `*_Algo`（四型之一）；**`MODULE` 过程体** 用 **`…_Ops`**，见总规范 §3.2 | 默认算法参数在 **TYPE** 侧；**模块**侧勿再新起 `…_Algo` |
| Ctx | `*_Ctx` | 瞬态上下文；可不进长期容器 |

**类型绑定**：`PROCEDURE :: Init => xxx_Init` 等，`generated` 清单会单独列出 **绑定行**。

### 2.1 过程参数打包 TYPE：`*_In` / `*_Out` 或合并 + `! [IN]` / `! [OUT]`

- **分拆模式**：`*_In`、`*_Out` 两个 `TYPE` — 适合强分离、生命周期不同。  
- **合并模式（可选）**：**单一** `TYPE` 容纳全部分量，**不**再使用 `_In`/`_Out` 后缀；用成员行尾 **`! [IN]`**、**`! [OUT]`**、**`! [INOUT]`** 标注（与 Principle #14 的 `[IN]`/`[OUT]` 叙述一致）。若与同模块 **同名过程** 可能冲突，合并 TYPE **须** 加 **`_Arg` / `_Params` / `_Bundle`** 等后缀（**非**四型 `_Algo`）。  
- **真源**：以域 **`CONTRACT.md`** + **`INTENT.md`** 选用模式 A 或 B；详见 [`UFC_命名与数据结构规范.md` §2.1](../UFC_命名与数据结构规范.md)（「结构化过程参数 TYPE」小节）。

---

## 3. 过程命名（精炼）

- **域入口**：`MD_<Domain>_Domain_<Verb>` 或 `<Type>_<Verb>`（与现有 `MD_Amplitude_Domain_Init` 一致）。  
- **跨层 Idx**：`MD_<Domain>_*_Idx`（依赖 `g_ufc_global` 时在合同声明）。  
- **SIO**：`*_Arg` + `Apply_*_Arg`（Principle #14）；避免仅包 `status` 的薄 `Arg`。  
  - **合并 In/Out 场**时，可将 **单一** 派生类型作为 `*_Arg` 的载体，字段向以 **注释 `[IN]`/`[OUT]`** + CONTRACT 为准（见 §2.1 与总规范 §2.1）。  
- **UF / legacy**：保留 `UF_*`、`ampdb_*` 等历史名时，在域 **CONTRACT** 中标为遗留真源，新 API 不复制第三种前缀体系。

---

## 4. `generated/*.md` 内区块含义

| 区块 | 内容 |
|------|------|
| **MODULE** | 解析到的 `MODULE` 名（未找到则写 `*(none)*`）。 |
| **TYPE blocks** | `TYPE`…`END TYPE` 之间 **源码行摘录**（含 `PROCEDURE`）；过长块会截断并注明。 |
| **Module procedures** | 文件内 **`SUBROUTINE` / `FUNCTION`** 的首行签名（不含续行展开）。 |
| **INTERFACE** | `INTERFACE` … `END INTERFACE` 块标题行（若可识别）。 |

---

## 5. 与「推断清单」的关系

`docs/05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md` 等为 **规划推断**；`generated/` 为 **实现快照**。当与 **`design/` 中 `INTENT.md`** 或域 **CONTRACT** 冲突时：**以 `design/` + CONTRACT 为验收方向**，再改源码与（必要时）推断文档。

## 6. 逆向对齐（残缺实现）

- **不**用残缺代码反推设计；先在 `design/` 写清目标，再改 `ufc_core`。  
- 改名 / 拆模块 **单独 PR**，与「补算法」变更可分开审阅。

---

## 7. 六层范围：减少遗留 ``*_Algo.f90``（MODULE）与 ``generated/``

**目标态**（与 [`UFC_命名与数据结构规范.md`](../UFC_命名与数据结构规范.md) §3.2 一致）：

- **MODULE / 编译单元文件名**：过程体用 **`…_Ops`**（或合同约定的其它角色后缀如 `_Brg` / `_Proc`），**不再新增** ``MODULE …_Algo`` 作为过程体容器。  
- **四型 TYPE**：仍可、且应当使用 **`*_Algo`** 表示 Algo 型，**不得**被全仓库文本替换误伤。

**范围**可覆盖 **L1_IF～L6_AP** 全层及 **`ufc_core` 下各域桶子树**；与 **Registry** 的关系：

1. **物理改名 / 改 ``MODULE`` 名** 后，**不要**手改 ``generated/*.md``；执行 ``python UFC/tools/domain_procedure_registry_scan.py`` 重新镜像。  
2. **验收对账**：为涉及域桶维护或自举 ``design/<Layer>/<域级>/manifest.json``，再跑 ``domain_procedure_registry_align.py``。全六层域桶可一次性 **生成初稿**：``python UFC/tools/bootstrap_design_domain_intents.py``（缺 ``INTENT.md`` 则创建；**刷新**各域 ``manifest.json``），再 **scan → align**。  
3. **执行粒度**：按 **域桶或更小子目录** 分批（每批独立 PR），每批顺序建议：**INTENT / CONTRACT** → **迁移** → **scan → align** → **构建**。禁止无清单的一次性全树盲改（当前仓库内仍有大量历史 ``*_Algo.f90``，需分波消化）。

**自动化工具**（机械重命名 + 安全范围内的 ``USE`` / ``MODULE`` / ``END MODULE`` / 引号内模块名字面量修补）：

- 通用：``python UFC/tools/migrate_ufc_module_algo_to_ops.py --under <ufc_core 相对路径> [--stem-prefix PH_] [--apply]``  
- 特例（L4 Element 已迁毕）：``python UFC/tools/migrate_l4_ph_element_algo_to_ops.py``（内部固定 ``--under L4_PH/Element`` 且 ``--stem-prefix PH_``）。

**域级「拆分 / 搬迁」**（目录结构变化）与单纯 ``_Algo``→``_Ops`` **不同**：须走 PPLAN / 变更记录，同步 **CMake**、**manifest**、**本文档 §2 全图** 与映射骨架类文档；**不要**仅靠重命名脚本完成域拆分。

**附录：现状量级（粗估，随仓库变化）**

- 可在仓库根用文件枚举统计 ``UFC/ufc_core/**/*_Algo.f90`` 数量，作为排期输入；全量收敛是**多年度/多 PR** 工程，而非单次提交。
