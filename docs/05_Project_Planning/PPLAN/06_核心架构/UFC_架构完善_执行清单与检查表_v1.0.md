# UFC 架构完善 — 执行清单与检查表 v1.0

> **文档位置**: `docs/05_Project_Planning/PPLAN/06_核心架构/`  
> **创建日期**: 2026-04-04  
> **配对文档**: [UFC_后分析类型扩充_架构完善总章程_v1.0.md](UFC_后分析类型扩充_架构完善总章程_v1.0.md)  
> **用途**: 阶段性执行跟踪、验收标准核清、问题排查速查表  

---

## 🗂️ 第一部分：五大阶段执行清单

### 阶段 I：L3_MD Analysis_Group 域完善（目标周期：1.5 周）

#### I-01: 补全 PROC_ID 映射表(1-91)

**任务描述**：
- 当前：`L3_MD_Analysis_Group_Module.f90` 仅覆盖 PROC 1-51
- 需求：扩展至 PROC 1-91（完整 ABAQUS PROC 集合）

**执行清单**：
```
□ 1.1 收集 PROC 52-91 的约束矩阵位置
    └─ 参考: 02_核心映射表/ABAQUS_PROC_到_Group_ID_完整映射.md
    └─ 工具: Excel 矩阵表(当前已有)
    └─ 验收: 所有 91 个 PROC 都有对应行

□ 1.2 实现 PROC 52-91 的 SELECT CASE 分支
    └─ 位置: L3_MD_Analysis_Group_Module.f90 > group_from_proc_id()
    └─ 工作量: ~40 行 Fortran
    └─ 验收: gfortran -std=f2003 -fsyntax-only 无错

□ 1.3 补充单元测试
    └─ 新建: Tests/unit/test_MD_Analysis_Group_PROC_52_91.f90
    └─ 测试用例: 每个 PROC 一个 + 边界 PROC(91)
    └─ 验收率: ≥98% (允许 1 个已知跳过)

□ 1.4 更新映射文档
    └─ 修订: 03_实现指导/L3_MD_Group_DESC_类型定义_实现.md
    └─ 添加: PROC 52-91 的具体示例
```

**验收标准**：
- ✅ 91 个 PROC 都有正确的 (Solver, Coupling, Physics) 映射
- ✅ 所有映射遵守约束矩阵规则
- ✅ 编译 0 errors, ≤2 warnings
- ✅ 单元测试通过率 ≥98%

**关键代码片段**：
```fortran
! group_from_proc_id() 中添加
CASE (52:60)    ! Coupled thermal-structural
  ! ...
CASE (61:70)    ! CFD procedures
  ! ...
CASE (71:91)    ! 特殊和稀有 procedures
  ! ...
```

---

#### I-02: 设计多求解器标记体系

**任务描述**：
- 当前：已支持 `requires_auxiliary_solver` 和 `auxiliary_solver_id` 两个字段
- 需求：确定支持的多求解器组合规则（如 FSI、THM、EMF）

**执行清单**：
```
□ 2.1 列出所有支持的多求解器耦合类型
    └─ 检查清单:
       ├─ FSI (FluidStruct): Standard + CFD
       ├─ THM (Thermal-Structural): Thermal + Standard  
       ├─ EMF (ElectroMagnetic Field): EM + others
       ├─ 其他多场: 列出定义
    └─ 来源: v5.0 总纲 §3 + ABAQUS 手册

□ 2.2 在 MD_Analysis_Group_DESC 中补充字段
    └─ 可选新增:
       LOGICAL :: requires_auxiliary_solver_2nd  ! 第 2 辅助求解器
       INTEGER :: auxiliary_solver_id_2nd
    └─ 验证: 是否需要支持 2+ 个辅助求解器

□ 2.3 编写规则引擎
    └─ 函数: MD_Analysis_Identify_Auxiliary_Solvers(group_desc, aux_list)
    └─ 输入: analysis_group_desc
    └─ 输出: auxiliary_solvers(:) -- 需激活的辅助求解器列表
    └─ 工作量: ~80 行
    └─ 验收: 所有多场耦合情况都能正确识别

□ 2.4 编写多求解器规则文档
    └─ 新建: 01_顶层设计/多求解器耦合规则表.md
    └─ 内容:
       - FSI 组合何时触发 + 激活顺序
       - THM 组合 + 能量稳定条件
       - EMF 组合 + 电磁场约束
```

**验收标准**：
- ✅ 支持的多求解器类型明确列出 (≥3 种)
- ✅ 规则引擎准确率 100%
- ✅ 规则文档清晰、可被 L4/L5 开发者理解

---

#### I-03: 实现 1-based ↔ 0-based 转换工厂

**任务描述**：
- 当前：已有 `MD_Analysis_Group_DESC` 同时保存 1-based 和 0-based
- 需求：统一、高效、无冗余的转换接口

**执行清单**：
```
□ 3.1 设计转换工厂接口
    └─ 函数签名:
       FUNCTION MD_Analysis_Factory_From_1Based(solver, coupling, physics) RESULT(group)
       FUNCTION MD_Analysis_Factory_From_0Based(s_idx, c_idx, p_idx) RESULT(group)
    └─ 单向转换: 给定 1-based → 自动计算 0-based（无冗余字段赋值）

□ 3.2 实现正向转换 (1-based → 0-based)
    └─ 位置: L3_MD_Analysis_Group_Module.f90 中新增函数
    └─ 逻辑:
       group%solver_idx = solver_1based - 1
       group%coupling_idx = coupling_1based - 1
       group%physics_idx = physics_1based - 1
    └─ 工作量: ~30 行

□ 3.3 实现逆向转换 (0-based → 1-based)
    └─ 逆向验证: group_1based = group_0based + 1
    └─ 工作量: ~20 行

□ 3.4 编写工厂单元测试
    └─ 新建: Tests/unit/test_MD_Analysis_Factory.f90
    └─ 测试集合:
       ├─ 边界: (1,1,1), (5,4,12)
       ├─ 中间: (2,3,7)
       ├─ 无效: (0,0,0), (6,5,13)
    └─ 验收率: 100%

□ 3.5 文档转换规则
    └─ 修订: 01_顶层设计/UFC_正交维度_Solver_Coupling_Physics_定义.md
    └─ 添加"1-based vs 0-based" 转换速查表
```

**验收标准**：
- ✅ 转换工厂函数正确性 100%
- ✅ 无冗余字段赋值（紧凑实现）
- ✅ 单元测试覆盖率 100%（所有有效/边界情况）
- ✅ 文档中 1-based 和 0-based 的映射关系清晰

---

#### I-04: 约束矩阵缓存层

**任务描述**：
- 当前：每次验证都调用 `get_compatibility_matrix()` 返回完整矩阵
- 需求：缓存矩阵以避免重复计算，提升路由性能

**执行清单**：
```
□ 4.1 设计缓存数据结构
    └─ 结构体: MD_Analysis_Compatibility_Cache
       TYPE :: MD_Analysis_Compatibility_Cache
         INTEGER :: matrix(0:4, 0:3, 0:11)
         LOGICAL :: is_valid
         INTEGER :: reference_count  ! 调用计数
       END TYPE

□ 4.2 实现缓存初始化
    └─ 函数: MD_Analysis_Cache_Init()
    └─ 时机: 程序启动时、或模型初始化时 (仅一次)
    └─ 工作量: ~20 行
    └─ 验收: is_valid = .TRUE. 且矩阵正确

□ 4.3 实现缓存查询接口
    └─ 函数: MD_Analysis_Cache_Query(s_idx, c_idx, p_idx) RESULT(is_valid)
    └─ 逻辑: 返回矩阵(s_idx, c_idx, p_idx) 的值（0 或 1）
    └─ 性能目标: <10ns/call (cache hit)

□ 4.4 编写性能基准测试
    └─ 新建: Tests/benchmark/bench_Analysis_Cache.f90
    └─ 测试场景:
       ├─ 10M 次随机查询 (cache hit)
       ├─ 与直接调用 get_compatibility_matrix() 对比
    └─ 验收: 缓存版本快至少 2 倍

□ 4.5 集成到路由流程
    └─ 修改: L4_PH_Analysis_Router_Module.f90
    └─ 将 CALL validate_group_combination() 改为 CALL MD_Analysis_Cache_Query()
```

**验收标准**：
- ✅ 缓存初始化成功、矩阵正确
- ✅ 查询性能达到 <10ns/call
- ✅ 无缓存一致性问题（model 不变情况下）
- ✅ 基准测试表明性能提升 ≥2 倍

---

#### I-05: 编写 Analysis 域完整设计文档

**任务描述**：
- 当前：有分散的快速参考表，缺乏系统的设计文档
- 需求：150 行左右的完整设计文档，供 L4/L5 开发者参考

**执行清单**：
```
□ 5.1 起草文档大纲
    └─ 结构:
       1. 域职责与核心概念 (20 行)
       2. TYPE 系统与四大功能集 (40 行)
       3. PROC 映射与约束矩阵 (30 行)
       4. 使用示例 + 错误处理 (30 行)
       5. 性能考虑与缓存策略 (20 行)

□ 5.2 编写初稿
    └─ 位置: 03_实现指导/L3_MD_Analysis_Domain_Complete_Design.md
    └─ 目标读者: L4_PH 和 L5_RT 的开发者
    └─ 包含:
       - MD_Analysis_Group_DESC 完整定义
       - 每个关键函数的用途 + 示例
       - 常见错误排查

□ 5.3 审查与修订
    └─ 审查人员: 架构师 + 1 名 L4 开发者
    └─ 反馈周期: 2-3 天
    └─ 修订后定稿

□ 5.4 编写快速参考卡
    └─ 新建: 04_快速参考/L3_Analysis_Domain_Quickstart.md
    └─ 格式: 一张 A4 纸能打印的快速查询表
```

**验收标准**：
- ✅ 文档行数 130-160 行
- ✅ 所有公开函数都有 API 说明
- ✅ 至少 3 个完整使用示例
- ✅ 错误处理规则明确说明
- ✅ 审查通过、无重大语法错误

---

### 阶段 II 执行清单（快速参考）

#### II-01~II-05: L4_PH Analysis_Router 与 Analysis 域联动

**关键检查项**：
```
□ II-01: route_analysis_group() 补全
    ├─ 覆盖所有 50 个有效坐标组合
    ├─ 编译 0 errors
    └─ 单元测试 ≥90%

□ II-02: 处理器启用分发
    ├─ Material 处理器启用规则明确
    ├─ Element 处理器启用规则明确
    ├─ Contact 处理器启用规则明确（涉及求解器类型）
    └─ 多求解器情况下激活顺序正确

□ II-03: L4 ↔ L3 约束矩阵验证接口
    ├─ 调用 MD_Analysis_Cache_Query()
    ├─ 每次路由时执行（性能 <100ns）
    └─ 非法组合立即返回错误

□ II-04: 热路径隔离：Populate 时预填充
    ├─ Analysis_Group 相关的 C_tan 预算进 slot_pool
    ├─ props(1:2) = [E, nu] 预填充
    ├─ 热路径中无额外 ALLOCATE
    └─ 性能目标: Compute_Ke <500 cycles

□ II-05: 文档
    ├─ 120 行设计文档
    ├─ 实现框架 + 接口契约 + 案例
    └─ 审查通过
```

---

### 阶段 III~V 执行清单（快速参考）

**III: L5_RT 求解器路由工厂完善**
```
□ III-01: RT_AnalysisType 升级
    ├─ 与 L3 MD_Analysis_Group 完全对标
    ├─ 5×4×12 映射闭环
    └─ 编译 0 errors

□ III-02: RT_Analysis_Factory 工厂模式
    ├─ 根据 (Solver, Coupling, Physics) 创建求解器
    ├─ 支持所有 8 种 RT_SolverType
    └─ 单元测试覆盖 ≥85%

□ III-03: RT_MF_Coordinator 多场耦合协调器 ⭐ 最高风险
    ├─ 支持 FSI/THM/EMF
    ├─ 子步回退机制
    ├─ 能量稳定性检查
    └─ 至少 3 个案例验证

□ III-04: RT_StepDriver 升级
    ├─ 显式调用 L4_PH_Analysis_Router
    ├─ 传递 Analysis_Group_DESC
    └─ 多求解器情况下正确路由

□ III-05: 文档
    ├─ 180 行设计文档
    ├─ 三步状态机 + 路由算法
    └─ 审查通过
```

**IV: 四型拆分与跨层契约**
```
□ IV-01: L3_MD 全域审计
    ├─ 审计所有 15 个域级
    ├─ 找出缺失的 Desc/State/Algo/Ctx
    └─ 输出改造优先级表

□ IV-02~03: L3_MD 各域四型拆分
    ├─ 第 1 批 (4 域): Material/Mesh/Model/Analysis
    ├─ 第 2 批 (11 域): 其余
    ├─ 每个 MODULE 都有 _Desc/_State/_Algo/_Ctx 后缀
    └─ 命名规范 100% 一致

□ IV-04: L4_PH/L5_RT 四型对齐
    ├─ 热路径 Ctx 零 ALLOCATE
    ├─ Algo 与 Analysis 类型绑定
    └─ 编译 0 errors, ≤2 warnings

□ IV-05~06: 跨层契约文档
    ├─ L3-L4 契约 v2.0 (200 行)
    ├─ L4-L5 契约 (180 行)
    └─ 审查通过
```

**V: AI-ready 与最终验收**
```
□ V-01: AI 插槽基础设施
    ├─ 7 个插槽的 L*/Domain 归属明确
    ├─ 四型职责明确
    └─ 文档 70 行

□ V-02: L3_MD 插槽预留
    ├─ MD_Analysis_Group 中预留 AI 字段
    ├─ 类型正确但全置 0（不激活）
    └─ 编译通过

□ V-03: E2E 集成测试
    ├─ L3→L4→L5 完整链路
    ├─ 50 个有效坐标都有测试
    ├─ 多求解器情况也覆盖
    └─ 测试覆盖率 ≥85%

□ V-04: 性能基准测试
    ├─ 路由分发 <100ns/call
    ├─ Populate <1μs
    └─ 热路径 Compute_Ke <500 cycles

□ V-05: 文档齐全
    ├─ 新增/改造模块都有 CONTRACT.md
    ├─ 更新 v5.0 总纲 § 新增章节
    ├─ 所有设计文档都有审查记录
    └─ 无悬空链接
```

---

## 🔍 第二部分：验收标准与检查项

### A. 代码质量验收

#### A1. 编译检查
```bash
# 检查项 A1-1: 语法正确性
gfortran -std=f2003 -fsyntax-only \
  L3_MD/L3_MD_Analysis_Group_Module.f90 \
  L4_PH/L4_PH_Analysis_Router_Module.f90 \
  L5_RT/L5_RT_Analysis_*.f90
# 验收标准: 0 errors, ≤2 warnings

# 检查项 A1-2: 反向依赖
python UFC/scripts/check_layer_dependency.py
# 验收标准: L3 无反向依赖，L4↔L5 单向

# 检查项 A1-3: 全量编译
cd UFC/build && cmake .. && make -j4
# 验收标准: 编译成功，无新增 error
```

#### A2. 单元测试
```bash
# 检查项 A2-1: L3_MD Analysis 测试
ctest -R "test_MD_Analysis_*" -V
# 验收标准: ≥98% 测试通过

# 检查项 A2-2: L4_PH Analysis 测试
ctest -R "test_PH_Analysis_*" -V
# 验收标准: ≥90% 测试通过

# 检查项 A2-3: L5_RT Analysis 测试
ctest -R "test_RT_Analysis_*" -V
# 验收标准: ≥85% 测试通过
```

#### A3. 性能基准测试
```bash
# 检查项 A3-1: 路由分发性能
./bench_Analysis_Dispatch
# 验收标准: <100ns/call (avg)

# 检查项 A3-2: Populate 性能
./bench_Analysis_Populate
# 验收标准: <1μs (avg)

# 检查项 A3-3: 热路径性能
./bench_Compute_Ke_Hotpath
# 验收标准: <500 cycles (C3D8 弹性)
```

---

### B. 架构一致性验收

#### B1. 单向依赖验证
| 层级 | 依赖规则 | 检查方法 | 验收标准 |
|------|---------|---------|---------|
| **L1** | 无依赖 | 代码审查 | 100% 遵守 |
| **L2** | L2 → L1 | 代码审查 | 100% 遵守 |
| **L3** | L3 → L2, L1 | 代码审查 | 100% 遵守，无 L4/L5 引用 |
| **L4** | L4 → L3, L2, L1 | 代码审查 + grep | 100% 遵守 |
| **L5** | L5 → L4, L3, L2, L1 | 代码审查 + grep | 100% 遵守 |
| **L6** | L6 → L5 | 代码审查 | 100% 遵守 |

#### B2. 四型拆分规范验证
```bash
# 检查项 B2-1: 命名规范
python UFC/tools/ufc_naming_checker.py UFC/ufc_core --check-fourtype
# 验收标准: 0 违规，所有 *_Desc/*_State/*_Algo/*_Ctx 命名规范

# 检查项 B2-2: 四型完整性
grep -r "TYPE.*_Desc\|_State\|_Algo\|_Ctx" UFC/ufc_core/L3_MD > fourtype_inventory.txt
# 验收标准: Material/Mesh/Model/Analysis 每个都有 4 个 MODULE

# 检查项 B2-3: Ctx 零 ALLOCATE 检查
grep -r "ALLOCATE.*ctx\|ALLOCATE.*Ctx" UFC/ufc_core/L4_PH/Element > /dev/null
# 验收标准: 热路径中无 ALLOCATE
```

#### B3. 跨层契约验证
| 契约 | 检查项 | 验证方法 | 验收标准 |
|------|--------|---------|---------|
| **L3→L4** | Analysis_Group 约束矩阵推送 | 单元测试 | 100% 准确 |
| **L4→L5** | 路由输出消费 | 集成测试 | 100% 对应正确的求解器 |
| **L5→L3** | 回写白名单 | 代码审查 | WB_TARGET 清晰定义 |

---

### C. 文档完整性验收

#### C1. 设计文档清单
| 文档 | 位置 | 行数 | 审查人 | 状态 |
|------|------|------|--------|------|
| I. Analysis 域设计 | 03_实现指导/ | 150 | 架构师 | □ |
| II. L4 Analysis 设计 | 03_实施规划/ | 120 | 架构师 + L4PM | □ |
| III. L5 Analysis 设计 | 03_实施规划/ | 180 | 架构师 + L5PM | □ |
| IV. L3-L4 契约 v2 | 05_实施指南/ | 200 | 架构师 | □ |
| V. L4-L5 契约 | 05_实施指南/ | 180 | 架构师 | □ |
| VI. 四型规范 v2 | 六层架构拆分/ | 150 | 架构师 | □ |
| VII. v5.0 总纲修订 | 01_架构总纲/ | +100 | 架构师 | □ |

#### C2. 代码内文档检查
```bash
# 检查项 C2-1: 函数文档
grep -r "SUBROUTINE\|FUNCTION" UFC/ufc_core/L*_*/\*Analysis\*.f90 | wc -l
# 验收标准: 100% 函数都有对应的设计文档或代码注释

# 检查项 C2-2: 关键算法文档
grep -r "DO iElem\|DO iStep" UFC/ufc_core/L5_RT/*Analysis*.f90
# 验收标准: 关键循环都有算法说明注释

# 检查项 C2-3: 类型定义文档
grep -r "TYPE :: MD_Analysis\|PH_Analysis\|RT_Analysis" UFC/ufc_core/L*/
# 验收标准: 每个 TYPE 都有 Desc 说明
```

---

## 🧪 第三部分：问题排查速查表

### 问题 1: 编译错误「Symbol 'X' not found」

**症状**：
```
Error: Symbol 'solver_1based' not found in module 'md_analysis_group_module'
```

**原因分析**：
| 序号 | 可能原因 | 检查方法 | 解决方案 |
|------|---------|---------|---------|
| 1.1 | 符号未导出（PRIVATE） | 检查 MODULE 中 `PUBLIC :: solver_1based` | 添加 `PUBLIC ::` 声明 |
| 1.2 | 拼写错误 | 对比源代码定义 | 更正拼写 |
| 1.3 | 编译顺序错误 | 查看 CMakeLists.txt | 调整 add_library() 顺序 |

**快速修复**：
```fortran
! 在 L3_MD_Analysis_Group_Module 中添加
PUBLIC :: MD_Analysis_Group_DESC
PUBLIC :: SOLVER_STANDARD, SOLVER_EXPLICIT, ...
PUBLIC :: group_from_proc_id
```

---

### 问题 2: 约束矩阵查询失败「Invalid Group」

**症状**：
```
ERROR: Invalid Group combination
  Solver=4, Coupling=3, Physics=7
```

**原因分析**：
| 序号 | 可能原因 | 检查方法 | 解决方案 |
|------|---------|---------|---------|
| 2.1 | 组合确实非法 | 查 02_核心映射表 中的约束矩阵 | 修改输入参数 |
| 2.2 | 索引计算错误 | 检查 1-based → 0-based 转换 | 验证: idx = val - 1 |
| 2.3 | 缓存未初始化 | 检查 MD_Analysis_Cache_Init() | 在 main 中调用初始化 |

**快速修复**：
```fortran
! 确保缓存已初始化
CALL MD_Analysis_Cache_Init()

! 检查 0-based 索引范围
IF (s_idx < 0 .OR. s_idx > 4) THEN
  PRINT *, "ERROR: solver_idx out of range", s_idx
END IF
```

---

### 问题 3: 多求解器协调失败「Auxiliary Solver Creation Failed」

**症状**：
```
ERROR: RT_MF_Coordinator could not create auxiliary solver
```

**原因分析**：
| 序号 | 可能原因 | 检查方法 | 解决方案 |
|------|---------|---------|---------|
| 3.1 | 辅助求解器 ID 不合法 | 检查 auxiliary_solver_id 值范围 | 仅支持 1-5 |
| 3.2 | 协调器未实现 | 检查 RT_MF_Coordinator 源代码 | 补充实现对应求解器类型 |
| 3.3 | 约束不支持多求解器 | 查 I-02 的多求解器规则表 | 验证该组合是否允许多求解器 |

**快速修复**：
```fortran
! 在 check_auxiliary_solver_requirement() 中添加检查
IF (group%auxiliary_solver_id < 1 .OR. group%auxiliary_solver_id > 5) THEN
  PRINT *, "ERROR: Invalid auxiliary solver ID", group%auxiliary_solver_id
  error_code = ERROR_INVALID_SOLVER
END IF
```

---

### 问题 4: 性能下降「Routing Dispatch >100ns」

**症状**：
```
Benchmark: route_analysis_group() = 250ns/call (expected: <100ns)
```

**原因分析**：
| 序号 | 可能原因 | 检查方法 | 解决方案 |
|------|---------|---------|---------|
| 4.1 | 缓存未命中 | 检查 cache hit rate | 预先初始化缓存 |
| 4.2 | 多余的验证调用 | 检查 validate_group_combination() 调用次数 | 改用缓存版本 |
| 4.3 | ALLOCATE 在热路径 | grep "ALLOCATE" 热路径代码 | 移至初始化阶段 |
| 4.4 | 编译优化级别低 | 检查 CMakeLists.txt `-O3` | 启用 `-O3 -march=native` |

**快速修复**：
```bash
# CMakeLists.txt 中
set(CMAKE_Fortran_FLAGS_RELEASE "-O3 -march=native -flto")

# 预填充缓存
CALL MD_Analysis_Cache_Init()  ! 在 main 中做一次
```

---

### 问题 5: 单元测试失败「Test Failed: Expected 1-based, Got 0-based」

**症状**：
```
FAILED test_MD_Analysis_1based_vs_0based
  Expected: solver_1based = 3
  Got:      solver_1based = 0
```

**原因分析**：
| 序号 | 可能原因 | 检查方法 | 解决方案 |
|------|---------|---------|---------|
| 5.1 | 转换公式错误 | 验证: group_1based = group_0based + 1 | 检查 ±1 方向 |
| 5.2 | 映射表缺陷 | 查 group_from_proc_id() 返回值 | 手动验证该 PROC 的映射 |
| 5.3 | 测试用例错误 | 对比预期值与 02_核心映射表 | 修正测试数据 |

**快速修复**：
```fortran
! 确认 1-based 范围: [1, 5] × [1, 4] × [1, 12]
ASSERT(group%solver_1based >= 1 .AND. group%solver_1based <= 5)

! 确认 0-based 范围: [0, 4] × [0, 3] × [0, 11]
ASSERT(group%solver_idx >= 0 .AND. group%solver_idx <= 4)
```

---

### 问题 6: 跨层调用链断裂「L4 Cannot Access L3 Data」

**症状**：
```
Error: L4_PH cannot access L3_MD Analysis_Group
```

**原因分析**：
| 序号 | 可能原因 | 检查方法 | 解决方案 |
|------|---------|---------|---------|
| 6.1 | Bridge 缺失 | 检查 L3_MD 是否导出 Bridge 函数 | 补充 Bridge 实现 |
| 6.2 | L4 缺乏参数 | 检查函数签名中是否包含 group_desc | 补充参数传递 |
| 6.3 | 模块依赖循环 | 用 grep 检查循环引用 | 重新设计依赖图 |

**快速修复**：
```fortran
! 在 L4 路由函数中添加参数
SUBROUTINE route_analysis_group(group_desc, ...)  ! 添加 group_desc
  TYPE(MD_Analysis_Group_DESC), INTENT(IN) :: group_desc
  ! ... 使用 group_desc 中的信息
END SUBROUTINE

! 确认 L3 中暴露了 Bridge 函数
USE L3_MD_Analysis_Group_Module, ONLY: MD_Analysis_Group_DESC
CALL group_init(...)  ! 调用 L3 的初始化或工厂函数
```

---

### 问题 7: 回写状态不一致「WriteBack Corrupted L3 State」

**症状**：
```
ERROR: L3_MD state corrupted after L5 WriteBack
  Expected: displacement(1:3) = [1.0, 2.0, 3.0]
  Got:      displacement(1:3) = [X, X, X]
```

**原因分析**：
| 序号 | 可能原因 | 检查方法 | 解决方案 |
|------|---------|---------|---------|
| 7.1 | WB_TARGET 白名单缺失 | 查 L5 WriteBack 代码 | 补充 Analysis_Group 对应的 WB_TARGET |
| 7.2 | 数据格式转换错误 | 检查 L5→L3 的数据映射 | 验证字节序和精度 |
| 7.3 | 并发写入冲突 | 检查多线程情况 | 添加互斥锁或串行化 |

**快速修复**：
```fortran
! 在 L5_RT 中定义 WB_TARGET
SELECT CASE (analysis_group_desc%physics_1based)
CASE (1)  ! Structure
  wb_target = ['Displacement', 'Stress', 'Strain']
CASE (2)  ! Thermal
  wb_target = ['Temperature', 'HeatFlux']
CASE (9)  ! FluidStruct
  wb_target = ['Displacement', 'Pressure']
END SELECT
```

---

## 📋 第四部分：检查表打印版

### 每周检查表

**第 1-2 周（I 阶段）**
```
□ 周一: I-01 PROC 映射启动
  ├─ 收集 PROC 52-91 规则
  └─ 分配工作：3 人 × 2 天

□ 周二-周三: I-02 多求解器标记系统设计
  ├─ 设计评审
  └─ 编码实现

□ 周四-周五: I-03 转换工厂 + I-04 缓存层
  ├─ 代码完成
  ├─ 单元测试
  └─ 集成测试启动

□ 下周一: I-05 文档编写
  ├─ 初稿完成
  └─ 审查反馈
```

**第 3-4 周（II 阶段）**
```
□ 周一-周二: II-01~II-02 L4 路由完善
  ├─ II-01 route_analysis_group() 补全
  └─ II-02 处理器启用分发

□ 周三: II-03~II-04 优化
  ├─ 约束验证接口
  └─ 热路径预填充

□ 周四-周五: 测试 + 文档
  ├─ II-05 设计文档
  └─ M2 里程碑验收
```

---

**最后更新**: 2026-04-04  
**下一次更新**: 执行过程中每周一更新进度
