---
name: ufc-naming-checker
description: "UFC Fortran 命名规范可执行技能：按场景（MODULE、四型+Args、TBP 短名、公开/私有过程、变量/常量、Bridge/LoadBC 词表）在写码前加载规则，写码后跑 Harness naming。触发：命名、naming、TBP、Desc/State/Algo/Ctx、Layer_Domain_VerbObj、ufc-naming.mdc。"
---

# UFC 命名规范（全过程）

**真源**：[`rules/ufc-naming.mdc`](../../rules/ufc-naming.mdc)；展开表见 [`REPORTS/UFC_命名清单与规范化表.md`](../../REPORTS/UFC_命名清单与规范化表.md)（若存在）。**程序性强制**：改 `ufc_core/**/*.f90` 后必须跑 `python ufc_harness/run_harness.py naming <path>`（或 CI 等价）。

---

## 何时加载本技能

| 时机 | 说明 |
|------|------|
| 开写/改任意 `ufc_core` 内 `.f90` 之前 | 先读本技能 + `ufc-naming.mdc`，避免返工 |
| 每批文件提交前 | 再跑 `naming` 于本批**最小公共父路径**（如某域目录） |
| 与 L3L5 二元结构改造并行时 | 与 `ufc-structured-io`、`fem-kernel-architecture` 同开；四型/Args 命名见下表「场景 B」 |

---

## 场景 A — `MODULE` 与文件前缀

- **规则**：`Layer_Domain_Role`，全名 **≤3 段**；与层前缀一致（`PH_`、`RT_`、`MD_` 等）。见 `ufc-naming.mdc` 层前缀表。
- **自检**：新文件/新模块名是否在 `L4_PH/Material`（例）域内且不超段数。

---

## 场景 B — 四型 `TYPE` 与 `*_Arg`（主/辅、嵌套/并列/主从）

- **类型名**：`Layer_Domain_Desc|State|Algo|Ctx`（如 `PH_Mat_Desc`）；辅型/Impl 等按合同与 `ufc-naming.mdc` TBP 节区分 `Impl_*`。
- **`*_Arg`**：与 Principle #14 一致；**Arg 类型名**仍须满足层域角色与长度习惯；与「主从」关系一致时，**主**承载入口 API 名在 `Layer_Domain_VerbObj` 表下命名。
- **嵌套/并列**：嵌套类型不引入 4 段以上模块名；并列类型各守自身 `Desc/State/...` 后缀，不在名字里堆业务长句。

---

## 场景 C — `TYPE` 绑定过程（TBP）短名

- **绑定名**（`PROCEDURE ::` 左侧）：**短动词** — `Init`、`Valid`、`ValidateProps` 等；禁止把完整 TYPE 名当绑定名。
- **实现名**：单模块单 TYPE 可无 `=>`；多 TYPE 用 `Desc_Init`、`State_Clean`、`Algo_*`、`Ctx_*` 等模式（见规则中材料族与多型示例）。
- **工具**：批量材料 Def 对齐可参考 `UFC/tools/tbp_mat_def_short_impl.py`（规则内引用）。

---

## 场景 D — 公开 / 私有 **子程序**（非 TBP）

- **公开**：`Layer_Domain_VerbObj`，建议 ≤28 字符。
- **私有**：`domain_verb` / `verb_obj`，≤24 字符。
- **与「空间/时间/动作」叙事**：过程名表达 **Verb+Obj**（如 `Eval`、`Populate`、`CommitState`），不要把整段物理语义写进名字；物理维度放在 **注释 / CONTRACT / spec**，名字保持工程动词对象结构。

---

## 场景 E — 变量、形参、常量

- **形参/局部**：`desc_suffix` 风格，≤20 字符（见规则表）。
- **常量**：`UPPER_SNAKE_CASE`。
- **避免**：与层前缀冲突的模糊缩写；LoadBC 词表违规（`LBC` 语义见规则）。

---

## 场景 F — Bridge、LoadBC、INTERFACE 导出

- Bridge 缩短名规则、`INTERFACE` 映射公开名、LoadBC `PH_LoadBC_*` vs 存量 `PH_Ldbc_*` — 一律按 `ufc-naming.mdc` **Bridge 命名** 与 **LoadBC 命名字汇** 小节执行。

---

## Harness（必跑）

```bash
cd UFC
python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material
# 或窄到单文件所在目录
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/PH_Mat_Def.f90
```

等价入口：`python UFC/ufc_harness/uhc.py code naming_checker`（见 [`AGENTS.md`](../../AGENTS.md) Harness 表）。

---

## 与 L3L5 Playbook 的关系

全进程须与 [`PLAYBOOK_L3L5_BINARY_TRIVIUM_ROLLOUT.md`](../../ufc_governance/triad/flow/PLAYBOOK_L3L5_BINARY_TRIVIUM_ROLLOUT.md) 中 **skills 顺序** 叠加：在 `fem-kernel-architecture` / `ufc-structured-io` 之后、`fem-kernel-data-contract` 之前或并行 **`npx openskills read ufc-naming-checker`**，保证「结构 + SIO + **命名**」同时在线。
