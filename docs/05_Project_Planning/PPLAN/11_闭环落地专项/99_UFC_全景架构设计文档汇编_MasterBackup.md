# UFC (UniFieldCore) 架构决策文档全集汇编 (ADR 01-26 Master Backup)

> **文档治理声明**：本文档将前期探讨的所有架构决策记录（Architecture Decision Records, ADR 01-26）进行归档、分类与合成，作为 UFC 知识库的最终备份与防丢失基线。

## 第一卷：哲学总纲与数据基石 (ADR 01-10, 16, 21)
### 1. 命名与文件隔离
*   **极简三段式**：`[Prefix]_[Domain]_[Suffix].f90` (如 `MD_Mat_Core.f90`)。
*   **四大类型后缀限制**：`Desc, State, Ctx, Algo` 仅用于 TYPE 定义，绝不允许作为 `.f90` 后缀。所有数据结构集中于 `_Def.f90`。
*   **职责绝对隔离**：`_Def` (数据合同), `_Core` (无状态纯计算), `_Proc` (带状态业务流), `_Brg` (防腐层桥接)。

### 2. 扁平化数据真源与三级内存
*   **化解 6 层嵌套**：放弃 ABAQUS 逻辑层面的深层嵌套，采用 **外键 ID (mat_id, sec_id) + 平行内存池**。主辅 TYPE 嵌套深度死锁在 3 层以内。
*   **三级内存架构**：磁盘外存 $\to$ DDR 全局大内存池 (`g_ufc_global`) $\to$ CPU 软缓存 (`Ctx` 和 `Args` 小结构体)。

### 3. SIO 结构化 IO (Principle #14)
*   **5/6 参铁律**：核心子程序签名强制为 `(desc, state, algo, ctx, [com_ctx], args)`。彻底消灭几十个参数的面条代码。

---

## 第二卷：执行引擎与运转时钟 (ADR 11-15)
### 1. 时空动三维正交坐标系
彻底消灭传统“时间×动作”双轴导致的维度坍缩：
*   **空间轴 (Where)**：Global (全局), Region (区域), Elem (单元), Point (积分点), Face (面域)。
*   **时相轴 (When)**：Step/Inc $\times$ Init/Predict/Iter/Commit/Rollback/Finalize。
*   **动作轴 (What)**：Populate (捞取), Evaluate (测算), Assemble (组装), Map (映射), Export (输出)。

### 2. 3-LAR 三字母压缩命名法
*   子程序名称必须应用压缩：`Init $\to$ Ini`, `Iter $\to$ Itr`, `Commit $\to$ Cmt`, `Evaluate $\to$ Evl`, `Assemble $\to$ Asm`。
*   **签名示例**：`MD_Mat_Proc_PtItrEvl` (材料域_流程_积分点_迭代中_测算)。

---

## 第三卷：非线性防线与多场路由 (ADR 17-20, 22-26)
### 1. 宏观矩阵路由
*   **司令部**：`[物理场] × [求解器] × [耦合形式]`。
*   **后勤部**：`[单元 L4] × [截面 Section] × [材料 L3]` (截面作为阻抗匹配器，防 3D 暴力量纲嵌入)。

### 2. 极限非线性防线 (超越商业软件)
*   **自动微分 (AD)**：双数 (Dual) 算符重载，自动生成零误差切线刚度 $D_{ep}$。
*   **Line Search & B-bar**：线搜索防过冲发散，B-bar 解绑不可压金属/橡胶体积锁死。
*   **热切换 & 增广拉格朗日**：对称矩阵 $\to$ 非对称矩阵热切换；拉格朗日平滑替代罚函数解决接触震荡。
*   **L2_NM 外挂战略**：坚决不自研底层解方程代码！单机接驳 MKL PARDISO，超大规模接驳 PETSc + AMG 代数多重网格。

### 3. PDE 大统一基座 (FEM 替代 CFD)
*   **场无关数据容器**：动态场注册表 `FieldManager`，支持速度、压力、温度等多场混合注册（支持不等阶插值解决 LBB 鞍点）。
*   **DG / CIP 框架**：启用 `Face` 域，支持激波捕捉的间断伽辽金面积分与连续内罚。
*   **算子注入 (Operator Injection)**：底层算标准 Galerkin，组装前动态注入 SUPG / GLS 稳定化算子治愈对流震荡。
*   **算子分裂 (Fractional Step)**：将 CFD 的巨大鞍点矩阵拆分为动量步（不对称）+ 压力泊松步（AMG绝对对称正定），极速收敛。