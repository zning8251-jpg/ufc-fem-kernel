# TBP 实现名分阶段治理 + LoadBC 域命名字汇

**版本**: v1.0 | **日期**: 2026-05-07  
**性质**: 执行清单与字汇裁决（与 `UFC/rules/ufc-naming.mdc`、蓝图 §6 配套）。

---

## 一、LoadBC / LBC / 代码前缀（历史 `PH_Ldbc_*`）：含义与全局统一

### 1.1 `LBC` 三个字母在本仓库指什么？

**`LBC` = LoadBC（合并域）**：**载荷（Load）与边界条件（BC）在同一域柱内建模、解析、分发**，不是「仅 Load」也不是「仅 BC」。  
与 Abaqus INP 中 `*STEP` 下既有 loads 又有 boundary 的**步级施加语义**一致。

- **Load**：集中力/分布力/体载荷/热流等。  
- **BC**：位移/速度/温度等约束。  
- **LoadBC**：L3 模型树 / L4 物理缓存 / L5 装配施加路径上的**统一域**（目录 `LoadBC/`、`MD_LBC_*`、`RT_LoadBC_*` 等）。

### 1.2 文档与注释（人类可读）

| 写法 | 结论 |
|------|------|
| **LoadBC** | **权威域名压缩**（`Domain_Compression_Canon.md`、命名合订 §1.1「域缩」）：文档 / 任务卡 / 架构说明默认 **LoadBC**；**禁止**再用 **`Ldbc`** 作为柱级缩写给新概念命名。存量 Fortran `PH_Ldbc_*` 等为历史模块前缀，语义=L4 LoadBC；新代码优先 **`PH_LoadBC_*`**，勿发明 `LdBC` / `LDbc` 等混排。 |
| **LBC** | 仅作**表内缩写**，首次须注解「LBC（LoadBC）」。 |

### 1.3 代码符号（Fortran 前缀）——存量与目标

| 层 | 现状主前缀 | 含义 | 新代码建议 |
|----|------------|------|------------|
| L3 | `MD_LBC_*` / 目录 `LoadBC/` | LoadBC 合并域权威 | **保持 `MD_LBC_*`**（与段数、既有合同一致）；不在此层引入 `MD_LoadBC_` 与 `MD_LBC_` 双轨。 |
| L4 | `PH_Ldbc_*` 为主 | 历史缩写 | **新 MODULE/TYPE 优先 `PH_LoadBC_*`**；存量 `PH_Ldbc_*` **P2 起**按域柱迁移脚本分批改名（与 `PH_Load_Def` 等并存策略见域 CONTRACT）。 |
| L5 | `RT_LoadBC_*` | 已用全称 | **保持 `RT_LoadBC_*`**。 |

**结论（全局统一口径）**：

1. **语义上**：只有 **Load**、**BC**、**LoadBC（合并）** 三种说法；**没有第四种「LBC 单指其一」**。  
2. **书面**：默认 **LoadBC**；缩写 **LBC** 仅等于 **LoadBC**，且首次需注释全称。  
3. **符号**：**不**追求把全仓库立刻改成同一串字符；**追求「柱级文档统一 LoadBC、Fortran 一层一种主前缀、不再新增含 `Ldbc` 的混拼变体」**；L4 向 `PH_LoadBC_*` 渐进。

---

## 二、TYPE 内 `PROCEDURE`（TBP）实现名——分类分阶段开展

按**风险 / 形态同质性**分六批；每批内先合同与脚本，再改代码，最后跑 `naming_checker` + 全量编译。

| 阶段 | 范围 | 形态 | 手段 | 状态（2026-05-07） |
|------|------|------|------|-------------------|
| **P0** | 材料 `*_Mat_*_Def.f90`（L3/L4/L5） | `<Stem>_<Role>_<Verb>` | `UFC/tools/tbp_mat_def_short_impl.py` | **已落地** |
| **P1** | LoadBC 路由小模块（`RT_LoadBC_*`、`RT_LoadBC_Impl_*`、`PH_Elem_Mass2` 类四型） | 同 P0 | 手改 + 已部分落地 | **部分已落地** |
| **P2** | L4 `PH_Ldbc_*` → `PH_LoadBC_*` | 模块/TYPE 前缀 | 迁移脚本 + `USE`/`CONTRACT` 同步 | **待办**（与域柱 P2 绑定） |
| **P3** | `MD_Model_*`（`norm_*`、`VariableProperties_*`） | 小写/专名 | 每子域定 `{角色}_{动词}` 词表后脚本 | **待办** |
| **P4** | `MD_LBC_Container` / `LoadBCTree_*` / `LBCAlgo_*` | 多 TYPE 混排 | 专用脚本或分文件 | **待办** |
| **P5** | `MD_KW` / `KeyWord` / MemPool / HashTable | 非四型动词 | 仅 TBP 右侧；不动 Lexer API | **待办** |
| **P6** | `MD_Base_*` / `MD_Base_ObjModel` / 合同巨型 `*_Contract.f90` | 异质 | 最后；或生成器侧统一 | **待办** |

**门禁**：每阶段结束 — `python UFC/ufc_harness/uhc.py code naming_checker UFC/ufc_core`（或子路径）+ 项目既有编译/ harness。

---

## 三、与技能/规则的链接

- 总则：`UFC/rules/ufc-naming.mdc`（TBP + LoadBC 字汇）。  
- 蓝图：`UFC/REPORTS/UFC_L3L4L5_二元重构蓝图规范_v1.0.md` §6。  
- 技能：`ufc-naming-checker`（`UFC/docs/02_Developer_Guide/Agent_Skills/ufc-naming-checker/SKILL.md`）。
- Base / Boundary 目录与 LoadBC 文档索引：`UFC/REPORTS/Base_Boundary_LoadBC_FourType_Algorithm_Unified_Index.md`。
