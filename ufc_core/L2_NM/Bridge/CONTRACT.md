# L2_NM/Bridge 域合同卡

> **版本**: v1.0 | **日期**: 2026-04-25
> **域**: L2_NM/Bridge | **前缀**: `NM_*_Brg`

---

## 一、域职责

L2_NM/Bridge 是外部数值库的隔离层（防腐层），将 MUMPS、SparsePak、AGMG/HSL、cuSPARSE 等外部求解器封装为统一的 UFC 内部接口。

- 所有外部库的 `#ifdef` 宏仅出现在本域内
- 外部库不可用时返回 `NM_ERR_EXTERNAL_NOT_AVAILABLE`
- 上游消费方（NM_Solver）通过 Bridge 适配器调用，不直接 USE 外部库

---

## 二、十件套 v2.0 映射

| 逻辑件 | 落地 | 状态 |
|--------|------|------|
| Contract | 本文 | Active |
| Definition/Schema | `NM_Brg.f90` (NM_ExtLibFlags, NM_BrgConfig_Desc) | Active |
| Desc | NM_BrgConfig_Desc (外部库可用性标志) | Active |
| State | — (无运行时状态) | N/A |
| Algo | — (无算法参数) | N/A |
| Ctx | NM_DirSolve_Arg (直接求解参数束) | Active |
| Kernel | NM_DirMUMPS_Brg, NM_DirSparsePak_Brg, NM_PrecAGMGHSL_Brg, NM_DirSolvDispatcher_Brg | Active |
| Bridge | 本域即 Bridge | — |
| Proc | — (无 _Proc 入口) | N/A |
| Registry | NM_DirSolvDispatcher_Brg (路由) | Active |
| Populate | NM_Brg_Init (检测外部库可用性) | Active |
| Diagnostics | 错误码返回 | Active |
| Test | Deferred |

---

## 三、I/O 与接口

| 接口 | 方向 | 类型 | 说明 |
|------|------|------|------|
| CSR 矩阵 + RHS | IN | NM_DirSolve_Arg | 来自 NM_Solver |
| 解向量 | OUT | NM_DirSolve_Arg | 返回给 NM_Solver |
| 外部库标志 | IN | NM_ExtLibFlags | 启动时检测 |
| 错误状态 | OUT | ErrorStatusType | 每次调用返回 |

---

## 四、四链

| 链 | 说明 |
|----|------|
| 理论链 | 外部库隔离：所有外部求解调用经 Bridge 适配器封装 |
| 逻辑链 | NM_Solver → NM_DirSolvDispatcher_Brg → 具体适配器 (MUMPS/SparsePak/...) |
| 计算链 | CSR 矩阵输入 → 外部库求解 → 解向量输出 |
| 数据链 | Desc(冷,外部库标志) → Ctx(热,NM_DirSolve_Arg) |

---

## 五、域际关系

| 上游 | 关系 | 说明 |
|------|------|------|
| NM_Solver | 消费方 | NM_Solver 调用 Bridge 求解 |

| 下游 | 关系 | 说明 |
|------|------|------|
| L1_IF/Error | 依赖 | 错误类型 |
| L1_IF/Precision | 依赖 | wp/i4 |
| ExternalLibs | 依赖 | 外部库源码 |

---

## 六、SIO / *_Arg（本域偏好）

保留 `NM_DirSolve_Arg`（含矩阵数据 + 求解参数 + 解向量，>=2 字段共同演进）。
不提供仅 status 的薄 Arg。

---

## 七、约束

**硬**: `#ifdef` 宏仅在本域；外部库不可用时不崩溃，返回错误码。
**软**: GPU 适配器 (cuSPARSE) 为后期扩展。

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L2_BRIDGE_xxx`（20200–20299） |
| 严重级 | WARNING（外部库不可用，降级）/ ERROR（求解失败） |
| 传播规则 | 外部库错误码映射为 UFC 统一 `status`；通过 `L1_IF/Error` 返回 |
| 恢复策略 | 外部库不可用时返回 `NM_ERR_EXTERNAL_NOT_AVAILABLE`，不崩溃；求解失败返回错误码由调用方处理 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L2_NM/Solver | S | NM_Solver 通过 Bridge 调用外部求解器 |
| 2 | L2_NM/Matrix | S | 消费 CSR 矩阵类型用于求解 |
| 3 | L5_RT/Assembly | T | 提供稀疏直接求解的合同接口 |
| 4 | L1_IF/Precision | U | 精度定义 `wp`, `i4` |
| 5 | L1_IF/Error | U | 错误类型 ErrorStatusType |
| 6 | ExternalLibs（MUMPS/SparsePak） | E | 外部数值库源码 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| `#ifdef` 宏仅在本域内 | 硬 | Code Review / grep 扫描 | P0 |
| 外部库不可用时不崩溃 | 硬 | 单测 mock | P0 |
| 上游不直接 `USE` 外部库模块 | 硬 | 编译依赖检查 | P0 |
| GPU 适配器（cuSPARSE）为后期扩展 | 软 | — | P2 |

---

### 十件套 v2.0 映射（标准化）

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Contract | 本文 `CONTRACT.md` | Active |
| 2 | Definition/Schema | `NM_Brg.f90`（NM_ExtLibFlags, NM_BrgConfig_Desc） | Active |
| 3 | Desc | `NM_BrgConfig_Desc`（外部库可用性标志） | 冷路径，启动时检测 |
| 4 | State | — | 无运行时状态 |
| 5 | Algo | — | 无自主算法，纯转发 |
| 6 | Ctx | `NM_DirSolve_Arg`（矩阵+RHS+解向量） | 热路径参数束 |
| 7 | Kernel | `NM_DirMUMPS_Brg`, `NM_DirSparsePak_Brg`, `NM_PrecAGMGHSL_Brg` | 外部库适配器 |
| 8 | Bridge | 本域即 Bridge | — |
| 9 | Proc | — | 无 `_Proc` 入口 |
| 10 | Registry | `NM_DirSolvDispatcher_Brg`（路由分发） | Active |
| 11 | Populate | `NM_Brg_Init`（检测外部库可用性） | Active |
| 12 | Diagnostics | 错误码返回 | Active |
| 13 | Test | Deferred | — |

---

*最后更新: 2026-04-25*

---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `NM_Brg.f90` | `NM_Brg` | `NM_ExtLibFlags`, `NM_Bridge_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `CheckLibrary` (TBP,PRV,—); `GetLibraryStatus` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `NM_Brg_Finalize` (SUB,PRV,Finalize); `NM_Brg_Init` (SUB,PRV,Init); `NM_Bridge_Domain_CheckLibrary` (SUB,PRV,Validate); `NM_Brg_GetLibStatus` (SUB,PRV,Query); `NM_Brg_GetSummary` (SUB,PRV,Query) |
| `NM_DirMUMPS_Brg.f90` | `NM_DirMUMPS_Brg` | `NM_MUMPS_Context`, `NM_SuperLU_Context`, `NM_DirectSolver_Params` | `dmumps_c` (SUB,PRV,—); `dgstrf_c` (FN,PRV,—); `dgstrs_c` (FN,PRV,—); `NM_MUMPS_Init` (SUB,PUB,Init); `NM_MUMPS_Setup_FromCSR` (SUB,PUB,Init); `NM_MUMPS_Analyze` (SUB,PUB,—); `NM_MUMPS_Factorize` (SUB,PUB,—); `NM_MUMPS_Solv` (SUB,PUB,—); `NM_MUMPS_Finalize` (SUB,PUB,Finalize); `NM_SuperLU_Init` (SUB,PUB,Init); `NM_SuperLU_Factorize` (SUB,PUB,—); `NM_SuperLU_Solv` (SUB,PUB,—); `NM_SuperLU_Finalize` (SUB,PUB,Finalize); `CSR_to_COO` (SUB,PRV,—) |
| `NM_DirSolvDispatcher_Brg.f90` | `NM_DirSolvDispatcher_Brg` | — | `NM_Direct_Solv_SparsePak` (SUB,PUB,—) |
| `NM_DirSparsePak_Brg.f90` | `NM_DirSparsePak_Brg` | `NM_SparsePak_Handle` | `NM_SparsePak_Solv` (SUB,PUB,—); `NM_SparsePak_Symbolic` (SUB,PUB,—); `NM_SparsePak_Numeric` (SUB,PUB,—); `NM_SparsePak_Solv_Factored` (SUB,PUB,—); `NM_SparsePak_Cleanup` (SUB,PUB,Finalize) |
| `NM_PrecAGMGHSL_Brg.f90` | `NM_PrecAGMGHSL_Brg` | `NM_AMG_HSL_Handle`, `NM_AMG_HSL_Control`, `NM_AMG_HSL_Info` | `NM_AMG_HSL_Setup` (SUB,PUB,Init); `NM_AMG_HSL_Apply` (SUB,PUB,—); `NM_AMG_HSL_Solv` (SUB,PUB,—); `NM_AMG_HSL_Destroy` (SUB,PUB,Finalize); `NM_AMG_HSL_SetDefaults` (SUB,PUB,Mutate) |


---

### SMP 求解器线程同步 (v4.0, 2026-04-26)

| 变更 | 文件 | 说明 |
|------|------|------|
| MUMPS ICNTL(16) | NM_DirMUMPS_Brg.f90 | NM_MUMPS_Init 中当 params%num_threads > 1 时设置 icntl(16) |
| NM_DirectSolver_SyncThreads (新增) | NM_DirMUMPS_Brg.f90 | 从运行时配置同步线程数到求解器参数, 供 Init 前调用 |

**线程数传递路径**:
`
L6 AP_Solver_Ctrl.nOMPThreads
  -> L0 UFC_Global_Init (omp_set_num_threads)
  -> L2 NM_DirectSolver_SyncThreads(params, nOMPThreads)
  -> MUMPS ICNTL(16) = nOMPThreads
`

**设计文档**: [UFC/docs/05_Project_Planning/PPLAN/06_核心架构/UFC_SMP_PARALLEL_DESIGN.md](../../../docs/05_Project_Planning/PPLAN/06_核心架构/UFC_SMP_PARALLEL_DESIGN.md)
