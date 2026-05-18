# 战术一：AST架构守卫与自动化脚手架 (军法)

> **文档位置**：`docs/05_Project_Planning/PPLAN/13_架构护城河合击战术/01_Tactic_AST_Guardian_代码生成与静态守卫.md`

## 1. 战术意图

“十件套”规范极其严苛，完全依赖开发者的人工自律是不可能的，极易产生“破窗效应”。我们必须用工具链将架构规范转变为**不可逾越的物理限制**。这套战术被称为开发期的“军法”。

## 2. 核心武器一：自动化十件套脚手架 (Domain Scaffolder)

不要让开发者手动新建 `XX_Def.f90`, `XX_Algo.f90`！

**机制设计**：
- 开发一套 Python 脚本 `tools/domain_forge.py`。
- 开发者只需提供一份 `YAML` 文件声明 Domain 的名字、属于哪一层、所需的前置依赖（如依赖 `NM_Tensor`）。
- 脚本一键生成满足 6 层单向依赖规则的 10 个 `.f90` 文件模板，并自动附带 `INTENT(IN)` 等契约卡标记。
- **效果**：从源头上杜绝目录命名混乱、模块名前缀不一致等低级错误。

## 3. 核心武器二：AST 层级依赖守卫 (The AST Guardian)

在每次 `git commit` 或构建期间，使用基于 Fortran AST (抽象语法树) 或正则语法分析的守卫脚本（如扩展现有的 `run_harness.py` 里的 `guardian`）。

**封杀规则 (Zero Tolerance)**：
1. **反向依赖扫描**：如果扫描到 `L3_MD` 的文件中出现了 `USE RT_Solver`，立刻报错并中断构建（高层下沉违规）。
2. **越权调用扫描**：如果发现 `_Algo`（纯算法域）模块中调用了 `_Brg`（门面域）或做了 `ALLOCATE`，立刻中止（纯函数被污染）。
3. **上帝对象检测**：扫描到模块包含超过规定数量的全局 `SAVE` 变量或传参超过 15 个，发出警告（God Object 苗头出现）。

## 4. 落地路径

1. **Phase 1**：强化 `scripts/check_docs_health.py` 到代码层，解析所有的 `USE` 语句并生成依赖有向无环图 (DAG)。
2. **Phase 2**：若 DAG 出现环（Circular Dependency）或逆流（L2 引用 L3），直接报红。
3. **Phase 3**：将这一切固化为 CI 流水线的第一道闸门 (Gatekeeper)。