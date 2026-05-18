# 04. L5_RT_Assembly_Solver (CSR组装与求解) 闭环落地设计与十件套固化

## 1. 业务职责与边界

本专项属于运行时闭环的最后一步（同时也是单次增量迭代循环的最底层收尾）。
`L5_RT_Asm`（全局装配）与 `L5_RT_Solv`（线性代数求解器）是紧密协同工作的兄弟域：
- **RT_Asm 域**的职责是高效、安全地收集所有物理单元返回的局部刚度矩阵 ($K_e$) 与残余力向量 ($R_{int}$)，并拓扑映射组装为**压缩稀疏行 (CSR, Compressed Sparse Row)** 格式的全局刚度矩阵。
- **RT_Solv 域**的职责是接管装配完毕的代数方程组 $K \cdot \delta U = R$，通过直接法（如 MKL PARDISO）或迭代法（如 GMRES, PCG），求出高精度的未知数 $\delta U$，返回给顶层分析步驱动。

---

## 2. 域级合同卡 (Domain Contract)

这两个域分别暴露给 `StepDriver` 一个统一门面操作接口。

### 装配域合同卡 (`RT_Asm.f90`（旧称 `RT_Asm_Algo.f90`）):
```yaml
# 域级合同卡：L5_RT_Asm
Interface: RT_Asm_AddElemStiff_Structured
Description: 将单元级别的局部刚度矩阵组装到全局 CSR 刚度矩阵中（支持并发策略）。
Inputs:
  - asm_in (RT_Asm_AddElemStiff_In, IN)   : 包含局部刚度矩阵 `K_element` 以及其全局自由度映射数组 `elem_dof`。
  - asm_out (RT_Asm_AddElemStiff_Out, OUT): 输出最新的全局状态（通常仅携带状态码）。由于 Fortran 传引用机制，实际操作直接修改全局单例的 CSR。
```

### 求解域合同卡 (`RT_Solv_Brg.f90`):
```yaml
# 域级合同卡：L5_RT_Solv
Interface: RT_Solv_Bridge_Unified
Description: 对黑盒求解器发起线性方程组求解调用。
Inputs:
  - K_csr (RT_CSRMatrix, IN)     : 已装配完成的全局对称/非对称稀疏矩阵（使用行指针与列索引数组）。
  - RHS (REAL Array, IN)         : 右端项（载荷与内力的残差向量 f_residual）。
  - x0 (REAL Array, IN, OPTIONAL): 用于 Krylov 迭代求解器的初始猜测解。
Outputs:
  - x (REAL Array, OUT)          : 方程组的解向量（全局位移增量 dU_global）。
  - status (ErrorStatusType, OUT): 求解器错误状态（如矩阵奇异、因式分解失败）。
```

---

## 3. 十件套 (Ten-Piece Set) 物理固化映射

该区域的十件套主要涉及全局数据结构的统筹，位于 `ufc_core/L5_RT/Asm/` 与 `ufc_core/L5_RT/Solver/`（共用 `RT_Shared_Def`）：

| 模块名 | 对应十件套 | 核心内容 / 属性列表 |
|---|---|---|
| `RT_Shared_Def.f90` | _Def | 统一定义 `RT_CSRMatrix` 类型：`val`, `col_ind`, `row_ptr`。以及自由度锁定（边界条件）相关的标记常量。 |
| `RT_Asm_Desc.f90` | _Desc | 全局方程组的拓扑映射图（Sparsity Pattern）缓存。 |
| `RT_Solv_State.f90` | _State | 求解器引擎状态（如已解析的符号分解、矩阵预处理条件数估算等）。 |
| `RT_Asm_Ctx.f90` | _Ctx | (通常并入 StepCtx) 组装缓冲区，对于多线程组装，定义基于图着色（Coloring）或无锁原子操作（Atomic）的缓冲区。 |
| `RT_Asm.f90`（旧称 `RT_Asm_Algo.f90`） | _Algo | `RT_Asm_AddElemStiff_Structured` 等纯组装逻辑，负责按 `elem_dof` 将 $K_e(i, j)$ 正确填入 `val` 数组中。 |
| `RT_Solv_Brg.f90` | _Brg | **本域防腐门面**。承接求解放法分发，调用如 `RT_Solv_Direct_Pardiso`。 |
| `RT_Solv_Reg.f90` | _Reg | 支持的底层求解器库清单（如 `SOLVER_DIRECT_MKL`, `SOLVER_ITERATIVE_GMRES`）。 |
| `RT_Solv_Err.f90` | _Err | 异常如 `ERR_MATRIX_IS_SINGULAR`, `ERR_SOLVER_OUT_OF_MEMORY`。 |
| `RT_Shared_Util.f90` | _Util | 稀疏矩阵转换工具，如 CSR 与 COO 格式之间的相互转换，或将 CSR 导出为 Matrix Market 文件以供 Python 验证。 |
| `RT_Asm_Test.f90` | _Test | 伪造 4 个单元构成的小型 2x2 网格，手动调用组装接口，核对 CSR 数组的内部排列是否精准无误。 |

---

## 4. 核心逻辑流转 (Algorithm Flow)

### 组装逻辑：
1. **拓扑初始化阶段 (Symbolic Factorization Phase)**：
   - 在开始时间步进之前，分析网格的节点连接性，预先确定 CSR 的行指针（`row_ptr`）与列索引（`col_ind`）。
   - 这避免了在牛顿迭代中动态分配内存的高昂开销。
2. **数值组装阶段 (Numeric Assembly Phase)**：
   - 每次牛顿迭代都会在 `StepDriver` 中将 `val` 和全局残余力 `f_residual` 清零。
   - `RT_Asm` 接收单元传来的 $K_e$ 及对应的全局自由度映射数组 `elem_dof`（如单元局部自由度索引 $1 \dots 24$ 映射到全局的 $[12, 13, 14 \dots]$）。
   - 对每一个 $K_e(i, j)$，根据映射查找 CSR 中对应的位置并执行累加：`K_csr%val(pos) = K_csr%val(pos) + Ke(i, j)`。

### 求解逻辑：
1. **调用分发**：`RT_Solv_Bridge_Unified` 收到求解请求，判断矩阵性质（对称正定 vs 非对称）。在极端塑性变形与强软化阶段，由于非结合流动法则或大变形引起，系统矩阵往往是非对称的。
2. **求解执行**：
   - 如果使用直接求解器（Direct Solver），如 PARDISO，则执行 LU 或 LDL^T 数值分解，接着进行前向-后向替换（Forward-Backward Substitution）求出 $x$。
3. **返回结果**：
   - 返回解向量 $dU\_global$，`StepDriver` 根据此解更新全局位移场。

---

## 5. 待执行动作清单 (Action Items)

- [ ] 补全 `RT_Asm_AddElemStiff_Structured` 内部在多线程 (OpenMP) 环境下的并发写入保护机制（原子加法或 Graph Coloring）。
- [ ] 构建针对非对称稀疏矩阵的测试沙盒，保障软化引起的大变形 Jacobian 能够被求解器正确消耗。
- [ ] 完成边界条件（Dirichlet BC）在装配阶段的惩罚法（Penalty）或者对角线置 1 法（Zero-row-and-column）的具体实现。