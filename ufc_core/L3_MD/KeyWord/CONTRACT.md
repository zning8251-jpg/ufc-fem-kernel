# KeyWord 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: KeyWord (关键字解析与注册)  
**Abbreviation**: KW (`MD_KW_*`, `MD_KeyWord_*`, `MD_Inp_*`)  
**Version**: v3.3  
**Updated**: 2026-05-07  
**Status**: ✅ ACTIVE

### 命名与缩写（Keyword）

域内保留 **混合** 历史 stem（`MD_KeyWord_*`、`MD_Inp_*`、`MD_KWAP_*` 等）。**新增**面向关键字解析/注册的 **`MODULE` / `.f90` 文件名** 优先 **`MD_KW_*`**；在标识符中部表达「关键字」语义时，使用压缩前缀 **`KW_`**（避免再引入全拼 `KeyWord_`），与既有 `KW_*` TYPE 前缀一致。

---

## 1. 域职责定义

### 核心职责
INP 关键字解析与注册的唯一 Desc 映射（KW→Desc）：Lexer 词法分析、Parser 语法分析、AST 构建、语义映射（Mapper）、关键字注册（Registry）、覆盖率审计。

### 职责边界
| 做什么 | 不做什么 |
|--------|----------|
| 关键字词法/语法分析（Lexer/Parser） | 不做单元计算/本构求值（L4/L5） |
| AST 构建与语义映射 | 不做物理方程求解 |
| 关键字注册表维护（P0/P1/P2 分级） | 不持有域对象（仅调用目标域 API 写入） |
| 覆盖率审计与报告 | 不修改网格/材料/截面数据（仅分派写入） |
| INP 文件解析入口 | 不做运行时步进控制 |

### SIO / `*_Arg`（本域偏好）
不强制每个过程使用 `*_Arg`。层间边界与 L5 `_Proc` 仍以全仓库 SIO 硬约束为准。

---

## 2. 四类 TYPE 清单

### 四型裁剪决策
- **Desc**: Y — 注册表描述、关键字条目、元数据
- **State**: Y — 解析进度量（current_keyword, error_count）
- **Algo**: Y — 解析策略（strict_mode, case_sensitive, error_limit）
- **Ctx**: Y — 解析运行时句柄（parse_stage, ast_root_id）

### 2.1 Desc 类型（不可变模型定义）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_KeyWord_Desc` | `MD_KeyWord_Def` | n_registered, entries(:) | 注册表描述 |
| `KWKeywordDef` | `MD_KeyWord_Domain` | kw_name, kw_category | 旧关键字条目 |
| `KW_MetadataType` | `MD_KW_Def` | 关键字元数据 | 注册元信息 |
| `KW_TokenType` | `MD_KW_Def` | type, value, line_num, col_num | Token 定义 |
| `KW_ParamDefType` | `MD_KW_Def` | name, param_type, required, default_value | 参数定义 |
| `KW_ASTNodeType` | `MD_KW_Def` | keyword, params(:), data(:), children(:) | AST 节点 |

### 2.2 State 类型（可变运行时状态）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_KeyWord_State` | `MD_KeyWord_Def` | current_keyword, current_line, error_count | 解析进度量 |
| `KW_LexerStateType` | `MD_KW_Def` | line_num, token_buf | Lexer 状态 |
| `KW_ParserStateType` | `MD_KW_Def` | ast_root, parse_stack | Parser 状态 |
| `KW_ParseState` | `MD_KeyWord_Domain` | 解析状态标志 | 域容器解析状态 |

### 2.3 Algo 类型（算法配置）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_KeyWord_Algo` | `MD_KeyWord_Def` | strict_mode, case_sensitive, error_limit | 解析策略 |
| `KWAlgo` | `MD_KeyWord_Domain` | 解析算法配置 | 域级算法参数 |

### 2.4 Ctx 类型（调用时上下文）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_KeyWord_Ctx` | `MD_KeyWord_Def` | parse_stage, ast_root_id | 解析运行时句柄 |
| `KWCtx` | `MD_KeyWord_Domain` | 域操作上下文 | 域容器 Ctx |
| `KW_MapperStateType` | `MD_KW_Mapper` | 映射状态 | Mapper 上下文 |

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|---------|-----------|------|
| `MD_KW_Def.f90` | `MD_KW_Def` | `_Def` | Token/Param/AST 底层类型、kw_category_name、kw_init_* | ACTIVE |
| `MD_KeyWord_Def.f90` | `MD_KeyWord_Def` | `_Def` | 四型 TYPE 定义 (Desc/State/Algo/Ctx) | **AUTHORITY** |
| `MD_KW_Core.f90` | `MD_KW_Core` | `_Core` | Init/Register/Parse/Query 核心 | ACTIVE |
| `MD_KeyWord_Domain.f90` | `MD_KeyWord_Domain` | Domain | 域容器+TBPs: Init/Finalize/RegisterKeyword/Parse/GetKeyword/AuditCoverage | ACTIVE |
| `MD_KW.f90` | `MD_KW_Coverage_Type`, `MD_KW_Reg_Type`, `MD_KW_Mapper_Type`, `MD_KW_Extension_Type`, **`MD_KW`（门面）** | — | 多段模块 + 统一门面 `MD_KW`：覆盖率/注册表类型 + 自 `MD_KW_Def` 再导出 `KW_ASTNodeType` 等供 `MD_KWRT_Brg` | ACTIVE |
| `MD_KW_Lexer.f90` | `MD_KW_Lexer` | `_Lexer` | kw_lexer_init/next_token/peek_token/push_back/at_eof | ACTIVE |
| `MD_KW_Parser.f90` | `MD_KW_Parser` | `_Parser` | kw_parser_init/parse_file/get_ast/get_errors/cleanup | ACTIVE |
| `MD_KW_Mapper.f90` | `MD_KW_Mapper` | `_Mapper` | kw_mapper_init/map_to_model + 160+ map_* 语义映射过程 | ACTIVE |
| `MD_KW_Dispatch.f90` | `MD_KW_Dispatch` | `_Dispatch` | MD_KW_Dispatch_Info/GetDomain/GetTypeStr | ACTIVE |
| `MD_KW_Reg.f90` | `MD_KW_Reg` | `_Reg` | MD_KW_Registry_Type + register_*_keywords (23 组) | ACTIVE |
| `MD_KW_Abaqus.f90` | `MD_KW_Abaqus` | — | kw_init_keyword_system/parse_inp_file/map_ast_to_model | ACTIVE |
| `MD_KW_MemPool.f90` | `MD_KW_MemPool` | — | RealMemoryPool/IntMemoryPool: Init/Allocate/Reset/GetStats | ACTIVE |
| `MD_Inp_Parse.f90` | `MD_Inp_Parse` | — | parse_inp_file + parser_get_coords/conn/bc_dofs/loads | ACTIVE |
| `MD_KeyWord_ParserRecursive.f90` | `MD_KeyWord_ParserRecursive` | — | MD_Parse_KeyWord_Block/Validate_KeyWord_Tree/Map_KeyWord_Tree_To_Model | ACTIVE |
| `MD_KeyWordParser_Def.f90` | `MD_KeyWordParser_Def` | `_Def` | KeyWord_Node_Type/ParsingRule_Type/ParamSpec_Type | ACTIVE |
| `MD_KeyWord_Validator.f90` | `MD_KeyWord_Validator` | — | MD_Is_Valid_Keyword/Validate_Required_Params/Validate_Parameter_Values | ACTIVE |
| `MD_KWAP_Brg.f90` | `MD_KWAP_Brg` | `_Brg` | L3→L6 AP 桥 | ACTIVE |
| `MD_KW_Reg_Ext.f90` | `MD_KW_Reg_Ext` | `_Mgr` | 扩展注册：~60个补充关键字（KEYWORD.pdf审计） | NEW |

---

## 4. 对外接口（公开 API）

### Lexer/Parser
| 接口 | 功能 | 参数 |
|------|------|------|
| `kw_lexer_init` | 初始化 Lexer | lexer_state, status |
| `kw_lexer_next_token` | 获取下一 Token | token, status |
| `kw_parser_init` | 初始化 Parser | parser_state, status |
| `kw_parser_parse_file` | 解析 AST | ast_root, status |
| `parse_inp_file` | INP 文件解析入口 | filename, model, status |

### 注册与映射
| 接口 | 功能 | 参数 |
|------|------|------|
| `KW_Registry_InitGlobal` | 全局注册表初始化 | status |
| `KW_Registry_RegisterAllKeywords` | 注册全部关键字 | — |
| `KW_Registry_FindKeyword` / `FindKeywordFast` | 查找关键字 | name, metadata |
| `kw_mapper_init` | 初始化 Mapper | status |
| `kw_mapper_map_to_model` | 语义映射 AST→模型树 | ast, model, status |

### 覆盖率审计
| 接口 | 功能 | 参数 |
|------|------|------|
| `KW_Audit_P0_Must` | P0 覆盖率审计 | report |
| `KW_Audit_P1_Important` | P1 覆盖率审计 | report |
| `KW_Generate_Report` | 生成覆盖率报告 | report, status |

---

## 5. 跨层数据流

### 解析流程
```
INP 文件 → Lexer(词法分析) → Token 流 → Parser(语法分析) → AST
  → Mapper(语义映射) → L3_MD 各域 API (Add*/Set*/Register*)
  → WriteBack → 覆盖率审计
```

### 关键字分类覆盖

| 级别 | 数量 | 示例 | 覆盖要求 |
|------|------|------|---------|
| P0 | 24 | *MODEL, *PART, *NODE, *ELEMENT, *MATERIAL, *STEP, *BOUNDARY, *CLOAD, *RIGID BODY, *INITIAL CONDITIONS, *CONNECTOR MOTION 等 | 100% 必须 |
| P1 | 35 | *ELASTIC, *PLASTIC, *DENSITY, *SOLID SECTION, *SHELL SECTION, *TIE, *DRUCKER PRAGER, *MOHR COULOMB, *HEAT TRANSFER, *GRAVITY, *SHELL GENERAL SECTION 等 | 100% 重要 |
| P2 | ~120 | 高级/特殊用途关键字：*CONTOUR INTEGRAL, *CAVITY DEFINITION, *MULLINS EFFECT, *GASKET BEHAVIOR 等 | 按需 |

### 关键字分类常量（`KW_CAT_*`）
`MODEL=1`, `PART=2`, `MESH=3`, `MATERIAL=4`, `SECTION=5`, `CONSTRAINT=6`, `LOAD=7`, `CONTACT=8`, `STEP=9`, `OUTPUT=10`, `AMPLITUDE=11`, `SPECIAL=12`, `END=13`, `OTHER=99`

### Field 初始条件对接锚点
`*INITIAL CONDITIONS, TYPE=TEMPERATURE` 等语义映射收敛在 `MD_KW_Mapper.f90::map_initial_conditions`。推荐路径：解析后调用 `MD_Field_Define` + `MD_Field_Set_InitCond`。

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Element/Mesh | T(合同) | *NODE/*ELEMENT 解析 → Mesh Desc |
| R2 | L3_MD/Material | T(合同) | *MATERIAL/*ELASTIC 解析 → Material Desc |
| R3 | L3_MD/Boundary | T(合同) | *BOUNDARY/*CLOAD/*DLOAD 解析 → Boundary Desc |
| R4 | L3_MD/Interaction | T(合同) | *CONTACT PAIR 等 → Interaction Desc |
| R5 | L3_MD/Output | T(合同) | *OUTPUT 解析 → Output Desc |
| R6 | L3_MD/Analysis/Step | T(合同) | *STEP 解析 → Step Desc |
| R7 | L3_MD/Section | T(合同) | *SECTION 解析 → Section Desc |
| R8 | L3_MD/Constraint | T(合同) | *EQUATION/*TIE/*COUPLING → Constraint Desc |
| R9 | L6_AP/Input | B(桥接) | AP_Inp_* 调用 KW 解析 |
| R10 | L1_IF/Error | U(USE) | 错误码定义 |

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L3_KEYWORD_xxx` (30800–30899) |
| 严重级 | WARNING: 未识别关键字(跳过); ERROR: 语法错误(参数缺失/类型不匹配); FATAL: 无 |
| 传播规则 | Lexer/Parser 错误经 `status` 返回；累计到 `error_count`；不自行 STOP |
| 恢复策略 | WARNING：日志+跳过当前关键字块；ERROR：中止解析并上报，含行号/列号 |

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | ABAQUS 关键字语法树→Lexer/Parser→AST→Desc 映射 |
| **逻辑链** | INP→KeyWord Parse→Model 树闭环→各域 API |
| **计算链** | 无（L3 仅解析，不执行计算） |
| **数据链** | INP 文件→Token 流→AST→L3 域对象→WriteBack |

---

## 7. 验收标准

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| P0 24 个核心关键字 100% 覆盖 | 硬 | Coverage 审计 | — |
| 解析结果须调用目标域 API 写入，禁止绕过 | 硬 | Code Review | — |
| Lexer/Parser 错误必须包含行号/列号 | 硬 | 单元测试 | — |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| P1 12 个关键字覆盖 | 软 | Coverage 审计 | — |
| 新增关键字须更新 P0/P1/P2 分类表 | 软 | Code Review | — |

---

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 早期 | 初始简版合同卡 |
| v2.0 | 2026-04-17 | 扩充为标准格式 |
| v3.0 | 2026-04-28 | 标准化为 7 章节格式 |
| v3.1 | 2026-04-30 | 删除重复 `MD_KeyWord.f90`；AST/Token 等经 `MD_KW.f90` 门面 `MD_KW` 再导出；功能模块表与真实 MODULE 名对齐 |
| v3.2 | 2026-05-05 | KEYWORD.pdf 审计 → 新增 `MD_KW_Reg_Ext.f90` (60补齐关键字)；更新 P0/P1/P2 分类表；集成至 `kw_init_keyword_system` |
