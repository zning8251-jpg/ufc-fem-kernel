# Model 域：四型 TYPE + 过程算法 命名规范化说明

**报告 ID**: `REP-MODEL-FOURTYPE-PROC-NAMING`  
**版本**: v1.2 | **日期**: 2026-05-07  
**性质**: **域柱落地规范**（L3_MD / Model），不替代全仓总则。  
**对齐**:
- 二元总公式与三维后缀框架：[`UFC_L3L4L5_二元重构蓝图规范_v1.0.md`](./UFC_L3L4L5_二元重构蓝图规范_v1.0.md)（§1–§4、§7）
- 层缀/四型/SIO 合订：[`REPORT_Naming_Unified_Spec.md`](./REPORT_Naming_Unified_Spec.md)
- Model 合同真源：[`../ufc_core/L3_MD/Model/CONTRACT.md`](../ufc_core/L3_MD/Model/CONTRACT.md)
- 词表文件（**仅承载已弃用别名**）：[`../config/model_naming_lexicon.yaml`](../config/model_naming_lexicon.yaml)
- 全仓 SIO / `*_Arg`：[`../AGENTS.md`](../AGENTS.md) Principle #14；技能 `ufc-structured-io`

---

## 1. 文档目的

本报告约定 **L3_MD / Model** 侧：

- 功能模块的二元划分：**数据结构（四型 + Args）** 与 **过程算法（三维语义后缀）**；
- **对外可读、可检索** 的过程与模块命名；**禁止** `MD_Mo_*`（`Mo` 缩写）；层缀一律 **`MD_Model_*`**（完整 `Model`）。
- **不再**以 `MD_Mo_*_Un_Pa` / `Un_Cf` 或任何「词表压缩名」作为权威 API。

---

## 2. 功能模块的二元结构（Model 表述）

```
功能模块_Model = 数据结构(四型 TYPE + 规范 Args) + 过程算法(空间维 x 时间维 x 动作维)
```

- **数据结构**：主四型 Desc / State / Algo / Ctx + `*_Arg` + 辅 TYPE（cfg/pop/专题模块）。
- **过程算法**：名称携带可读的 **专题 + 相 + 动作**（见 §5、§6）；三维用于**语义标注**，不强制每个符号都拼满三段下划线。

---

## 3. 四型 + Args（数据结构侧）

### 3.1 主四型

| 类型 | 命名 | 权威模块 |
|------|------|----------|
| Desc | `MD_Model_Desc` | `MD_Model_Def` |
| State | `MD_Model_State` | `MD_Model_Def` |
| Algo | `MD_Model_Algo` | `MD_Model_Def` |
| Ctx | `MD_Model_Ctx` | `MD_Model_Def` + `MD_Model_Mgr`（合同卡区分职责） |

### 3.2 Args

- **禁止** `inp` / `out` **成对类型** 作为 SIO 主抽象。
- **推荐** `TYPE :: ..._Arg`，字段旁 `[IN]` / `[OUT]` / `[INOUT]`。
- 避免「仅 status」的薄 `Arg`（见 `CONTRACT.md`）。

### 3.3 辅 TYPE 与 TBP

- 辅块短字段名；TBP 用 **Init / Valid / Clear / Get / Set** 等短动词，**不要**再把 `MD_Model_...` 重复塞进 TBP 名。

---

## 4. 过程算法三维（Model 域语义）

| 维度 | Model 推荐语义（写入注释或过程名后缀时选用） | 说明 |
|------|----------------------------------------------|------|
| 空间维 | `Mdl`、`Tree`、`Sub`、`KW`、`Brg` | 模型全局、模型树、子域、关键字 AST、桥 |
| 时间维 | `Init`、`Parse`、`Build`、`Valid`、`Final` | 冷路径生命周期 |
| 动作维 | Parse、Valid、Cfg、Reg、Dispatch、Sync、Populate | 元数据动作 |

**与命名的关系**：专题级「解析 / 配置」入口对外名固定为 **`Parse`** 与 **`Cfg`**（见 §6.3）；**禁止** `Unified_*`、`Un_Pa`、`Un_Cf`、`Mo` 等缩写作为新 PUBLIC 符号。

---

## 5. Module / 文件命名（不变）

- `MD_Model_<专题>_<角色>.f90`，**MODULE = 文件名 stem**。
- 合并专题用短 stem：`MD_Model_Data_Dist`、`MD_Model_Coord_Normal` 等。
- 禁止恢复已删除的薄 Facade。

---

## 6. 过程命名：细致全面规划（v1.2 核心）

### 6.1 设计原则

| 原则 | 要求 |
|------|------|
| **可读优先** | 新代码与对外 `PUBLIC` 过程名须 **自解释**；维护者不应依赖 `model_naming_lexicon.yaml` 才能读懂 API。 |
| **完整 Model 前缀** | 层域标识为 **`MD_Model_`**；**禁止** `MD_Mo_`（`Mo` 为错误缩写）。 |
| **模块锚定** | 专题级入口名须能 **从 MODULE stem 推断**：`MD_Model_<TopicSlug>_Parse` / `MD_Model_<TopicSlug>_Cfg`。 |
| **单一权威** | 每个专题 **仅一对** `Parse` / `Cfg` 为权威；`*_Unified_*`、`MD_Mo_*`、旧 `CoordSys_` 长名均为迁移期别名。 |
| **关键字边界** | `MD_KW` 注册的 `parse_proc` / `validate_proc` = **磁盘实际过程名**；应逐步改为与 `Parse` / 薄包装一致。 |
| **配置入口用词** | 统一 **`Cfg`**；**不使用** `Configure`、`Unified_Configure`、`Unified_Cfg` 作为新规范名（遗留可保留薄包装指向 `*_Cfg`）。 |

### 6.2 五层命名栈（自上而下）

```
[1] 关键字可见：Parse_*_Keyword / Valid_*_Keyword / …
        ↓ 通常 CALL
[2] 专题级入口（权威）：MD_Model_<TopicSlug>_Parse / MD_Model_<TopicSlug>_Cfg
        ↓ 内部可 CALL
[3] 模块内私有实现：短前缀 + 动词（如 xfm_*、norm_*、imp_kw_param）
        ↓ 不应再对外
[4] （弃用）MD_Mo_*、*_Unified_Parse、*_Unified_Cfg / *_Unified_Configure — 仅过渡期兼容
[5] L5 / 全仓 SIO：五参六参 + *_Arg（见 AGENTS / ufc-structured-io）
```

**结论**：**第 2 层为 Model 域对外专题入口的规范真源**；凡带 `Unified`、`Un_Pa`、`Un_Cf`、`MD_Mo_` 的符号 **不得再新增**，并应随迁移下线。

### 6.3 权威专题入口：命名模板（无 Unified）

对「单文件合并」专题模块（Data / Coord / Adv 等），**唯一推荐对外模板**：

```text
MD_Model_<TopicSlug>_Parse
MD_Model_<TopicSlug>_Cfg
```

- **TopicSlug** = **MODULE 名去掉前缀 `MD_Model_` 后的整段**（与文件名 stem 一致），例如：
  - `MD_Model_Coord_Transform` → `MD_Model_Coord_Transform_Parse`、`MD_Model_Coord_Transform_Cfg`
  - `MD_Model_Import` → `MD_Model_Import_Parse`、`MD_Model_Import_Cfg`
  - `MD_Model_Data_Param` → `MD_Model_Data_Param_Parse`、`MD_Model_Data_Param_Cfg`

**与历史名并存**：

- `MD_Model_*_Unified_Parse` / `Unified_Cfg` / `Unified_Configure`、`MD_Model_CoordSys_*_Unified_*`、`MD_Model_Data_Parameter_Unified_*`：一律视为 **legacy**，由薄包装 `CALL` 转至 `*_Parse` / `*_Cfg` 后删除。
- 新模块 **禁止** 再引入 `Unified`、`CoordSys_` 与 stem 不一致的片段。

### 6.4 专题过程名对照表（v1.2 权威 → 弃用别名）

| 模块 stem | **权威 Parse** | **权威 Cfg** | 弃用（勿再扩展） |
|-----------|----------------|--------------|------------------|
| `MD_Model_Coord_Transform` | `MD_Model_Coord_Transform_Parse` | `MD_Model_Coord_Transform_Cfg` | `MD_Mo_CS_Xfm_Un_Pa` / `Un_Cf`，`*_Unified_*`，`MD_Model_CoordSys_Transform_Unified_*` |
| `MD_Model_Coord_Sys` | `MD_Model_Coord_Sys_Parse` | `MD_Model_Coord_Sys_Cfg` | `MD_Mo_CS_Sys_Un_*`，`*_Unified_*`，`MD_Model_CoordSys_System_Unified_*` |
| `MD_Model_Coord_Orient` | `MD_Model_Coord_Orient_Parse` | `MD_Model_Coord_Orient_Cfg` | 曾用 `MD_Mo_CS_Ori_Un_*`、`MD_Model_CoordSys_Orientation_Unified_*`（**P3 已从源码移除 PUBLIC**；解码见 `config/model_naming_lexicon.yaml` / 旧文档） |
| `MD_Model_Coord_Normal` | `MD_Model_Coord_Normal_Parse` | `MD_Model_Coord_Normal_Cfg` | 曾用 `MD_Mo_CS_Nor_Un_*`、`MD_Model_CoordSys_Normal_Unified_*`（**P3 已从源码移除 PUBLIC**；解码见 lexicon / 旧文档） |
| `MD_Model_Import` | `MD_Model_Import_Parse` | `MD_Model_Import_Cfg` | `MD_Mo_Adv_Im_Un_*`，`MD_Model_Adv_Import_Unified_*` |
| `MD_Model_Prestress` | `MD_Model_Prestress_Parse` | `MD_Model_Prestress_Cfg` | `MD_Mo_Adv_Ps_Un_*`，`MD_Model_Adv_Prestress_Unified_*` |
| `MD_Model_Substruct` | `MD_Model_Substruct_Parse` | `MD_Model_Substruct_Cfg` | `MD_Mo_Adv_Su_Un_*`，`MD_Model_Adv_Substructure_Unified_*` |
| `MD_Model_Data_Table` | `MD_Model_Data_Table_Parse` | `MD_Model_Data_Table_Cfg` | `*_Unified_*` |
| `MD_Model_Data_Param` | `MD_Model_Data_Param_Parse` | `MD_Model_Data_Param_Cfg` | `MD_Model_Data_Parameter_Unified_*`（KW 迁移后删除） |

**说明**：Adv 专题以 **MODULE 名**（`Import` / `Prestress` / `Substruct`）为 TopicSlug，**不**再使用 `Adv_` 中缀挤进过程名，避免与 `MD_Model_*` 双重语义重复。

### 6.5 非专题入口过程（Mgr / Core / Builder / Tree）

- 模式：`MD_Model_<Area>_<Verb>` 或 `MD_Model_<Area>_<Object>_<Verb>`。
- 示例：`MD_Model_Domain_Init`、`MD_Model_Builder_Build`、`MD_Model_Ctx_Bind`。
- **禁止** `Mo` 及 `Un_Pa`、`Un_Cf` 等二级缩写。

### 6.6 `model_naming_lexicon.yaml` 的定位

- **仅解码遗留 `MD_Mo_*`**，**不是**命名真源；权威模板见 **§6.3**（`MD_Model_<TopicSlug>_Parse` / `_Cfg`）。
- **禁止** 为新 PUBLIC 过程新增词表 token。

---

## 7. SIO 与 TYPE 接口体

- 结构化 IO：`*_Arg` 或全仓五参/六参；禁止 inp/out 类型对作为主模型。
- `INTERFACE` / 显式四型指针传递边界数据。

---

## 8. 迁移阶段（建议）

| 阶段 | 内容 |
|------|------|
| P0 | 本报告 v1.2；`CONTRACT.md` 对齐 `Parse`/`Cfg`、禁止 `MD_Mo_*` / `Unified_*` 为新代码首选 |
| P1 | 各模块：实现体迁至 `MD_Model_<TopicSlug>_Parse`/`_Cfg`，`PUBLIC` 仅导出二者；`Unified_*`/`MD_Mo_*` 薄包装或 `PRIVATE` |
| P2 | `MD_KW` / `MD_Model_Reg` 字符串与 `USE` 全部切到 `*_Parse`/`*_Cfg` |
| P3 | 删除 `Unified_*`、`MD_Mo_*` 符号；词表仅作历史解码 |

---

## 9. 与二元蓝图 §19 的关系

蓝图 §19 文件表可能过时；**以 `CONTRACT.md` 当前文件清单 + 本报告 §5–§6 为准**。

---

## 10. 修订记录

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-05-07 | 首版 |
| v1.1 | 2026-05-07 | 弃用 `MD_Mo_*` 为对外规范；五层栈；曾采用 `Unified_Parse`/`Unified_Configure` 模板 |
| v1.2 | 2026-05-07 | **去掉 Unified**；专题入口改为 `MD_Model_<TopicSlug>_Parse` / `_Cfg`；**Configure 一律改为 Cfg**；强调 **Model 全写、禁止 Mo** |

