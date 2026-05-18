# UFC Tools Index

UFC 仓库可复用工具脚本。一次性迁移/修复脚本已归档至 `archive/`。

## 活跃工具

### CI 门禁（Harness 调用）

| 工具 | 用途 | Harness 入口 |
|------|------|-------------|
| `arch_guardian.py` | 层间 USE 依赖守卫（DEP-001/GLB-001 等） | `run_harness.py guardian` |
| `check_naming_l3l4l5l6.py` | 模块/TYPE/过程名命名规范检查 | `uhc.py code naming_checker` |
| `check_docs_health.py` | 文档链接有效性检查 | `run_harness.py doc-structure` |
| `scan_code_templates_ssot.py` | **开发者指南 + 域柱 Fortran 围栏真源扫描**：`Code_Templates`（`.f90`+`.md`）、`docs/02_Developer_Guide` 其余（`.md`，排除 `Code_Templates/`）、`docs/03_Domain_Pillars`（`.md`） | `run_harness.py code-templates-ssot`（`plan-checks` 已串联） |
| `verify_phase6_track12_contract.py` | Phase6 **Track 1.2** 静态检查（弧长 WARN / tol_scale 字段存在） | 手工 / CI 可选 |
| `verify_phase6_track13_api.py` | Phase6 **Track 1.3** 静态检查（`MD_MatState_Snapshot` / `RestoreInto`） | 手工 / CI 可选 |
| `gen_ph_element_stem_stub.py` | Phase6 **Track 3.4** 单元 stem 外壳生成器占位（`--stem` / `--json` / `--out-dir`） | 手工 |

### 契约与兼容性

| 工具 | 用途 |
|------|------|
| `verify_domain_contract_cross_ref.py` | 域级 CONTRACT.md 交叉引用验证 |
| `verify_elem_mat_compat_matrix.py` | 单元-材料兼容矩阵验证 |
| `verify_mat_leaf_index_74.py` | 材料叶子索引验证 |
| `check_structured_params.py` | 结构化参数检查 |

### 代码生成

| 工具 | 用途 |
|------|------|
| `gen_umat_adapter.py` | UMAT/VUMAT 适配器生成 |
| `gen_md_mat_def.py` | MD 材料定义模块生成 |
| `generate_skeletons.py` | 层-域-功能骨架代码生成 |
| `gen_mat_leaf74_modules.py` | 材料叶子模块生成 |

### 扫描与分析

| 工具 | 用途 |
|------|------|
| `domain_procedure_registry_scan.py` | 域过程注册表扫描 |
| `domain_procedure_registry_align.py` | 域过程注册表对齐；**默认**写 `REPORTS/DESIGN_GENERATED_DRIFT.md`（`--out` 可覆盖） |
| `domain_boundary_analyzer.py` | 域边界分析 |
| `domain_function_analyzer.py` | 域函数分析 |
| `naming_lexicon.py` | **命名词表真源**：`LONG_NAME_ABBREV`（模块长词根）+ `verbose_token_hints()`（局部标识符扫描）；被 `check_naming_l3l4l5l6.py` / `scan_verbose_identifiers.py` 导入 |
| `scan_verbose_identifiers.py` | **反冗长标识符**：冗长英文词根 + 长度（启发式）；默认报告、`--substr-only` / `--fail-on N` 见 `rules/ufc-naming.mdc` |
| `element_inventory_audit.py` | 单元目录清册审计 |
| `material_pillar_audit.py` | 材料柱审计 |
| `naming_baseline_scan.py` | 命名基线扫描 |

### 文档与报告

| 工具 | 用途 |
|------|------|
| `assemble_panorama_reader.py` | 生成全景架构汇编阅读版 |
| `audit_directory_vs_matrix.py` | 目录结构 vs 设计矩阵对照 |
| `build_inventory.py` | 构建文件清册 |
| `count_f90_layer_line_stats.py` | Fortran 代码行统计 |
| `generate_dep_graph.py` | 依赖图生成 |

### 入口

| 工具 | 用途 |
|------|------|
| `run_guardian.py` | arch_guardian 的薄包装入口 |

## 归档目录

`archive/` 存放一次性迁移/修复/批量改名脚本（含 `migrate_*`、`rename_*`、`fix_*`、`sprint*`、`template_phase*`、`type_sync*` 等 35 个文件）。历史参考用途，不再活跃使用。
