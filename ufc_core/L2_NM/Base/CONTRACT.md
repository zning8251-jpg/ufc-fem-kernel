## Base 域级合同卡（L2_NM）

- **层级**：L2_NM
- **域名**：Base / 数值算法基础
- **缩写**：NM_Base (`NM_Base_*`)
- **职责**：提供数值算法通用数据结构、数学工具函数、枚举常量定义；为 L2_NM 各域提供统一的基础设施。
- **四型配置**：
  - **Desc**：向量/矩阵 TYPE、收敛准则枚举、数学常量。
  - **State**：无全局状态（纯函数式）。
  - **Ctx**：无。
  - **Algo**：范数计算、点积、归一化等基础算子。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Constants | pi, euler, tol_default | 数学常量 |
| Norms | Norm_L1, Norm_L2, Norm_Inf | 向量/矩阵范数 |
| Utils | Dot_Product_Fast, Cross_Product | 优化算子 |
| Enums | eConvergenceCriterion, eNormType | 算法枚举 |

- **依赖**：IF_Precision（精度定义）、IF_Error（错误处理）。
- **热路径**：**是** — 范数计算在 Newton-Raphson 迭代中频繁调用。
- **实现锚点**：
  - `NM_Base_Constants.f90` — 数学常量定义
  - `NM_Base_Norms.f90` — 范数计算核心
    ```fortran
    PURE FUNCTION Norm_L2(vec) RESULT(norm)
      REAL(wp), INTENT(IN) :: vec(:)
      REAL(wp) :: norm
      ! 伪代码：norm = SQRT(SUM(vec**2))
      ! 优化：使用 DOT_PRODUCT 避免临时数组
      norm = SQRT(DOT_PRODUCT(vec, vec))
    END FUNCTION Norm_L2
    ```
  - `NM_Base_Utils.f90` — 工具函数
  - `NM_Base_Types.f90` — TYPE 与枚举定义

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L2_BASE_xxx`（20100–20199） |
| 严重级 | WARNING（精度损失）/ ERROR（非法输入维度） |
| 传播规则 | 通过 `L1_IF/Error` 的 `status` 返回；纯函数以返回值 `info` 标识 |
| 恢复策略 | 返回错误码，不 `STOP`；调用方决定是否中止 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L1_IF/Precision | U | 精度定义 `wp`, `i4` 唯一来源 |
| 2 | L1_IF/Base | U | 基础工具（IF_Const 等） |
| 3 | L1_IF/Error | U | 错误类型 ErrorStatusType |
| 4 | L4_PH/* | S(被消费) | 范数/点积在单元计算中使用 |
| 5 | L5_RT/* | S(被消费) | 范数在 Newton-Raphson 收敛判断中使用 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| `USE IF_Prec_Core` 精度统一 | 硬 | 编译 | P0 |
| `PURE` 属性（范数、点积） | 软 | Code Review | P1 |
| 无副作用（无全局状态写入） | 硬 | 编译 + 单测 | P0 |
| 热路径禁止文件 I/O 与动态字符串 | 硬 | Code Review | P0 |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Contract | 本文 `CONTRACT.md` | Active |
| 2 | Definition/Schema | `NM_Base_Types.f90` | TYPE 与枚举定义 |
| 3 | Desc | `eConvergenceCriterion`, `eNormType`, 数学常量 | 不可变描述 |
| 4 | State | — | 纯函数式，无全局状态 |
| 5 | Algo | `Norm_L1`, `Norm_L2`, `Norm_Inf`, `Dot_Product_Fast`, `Cross_Product` | 基础算子 |
| 6 | Ctx | — | 无上下文 |
| 7 | Kernel | `NM_Base_Norms.f90`, `NM_Base_Utils.f90` | 计算核心 |
| 8 | Bridge | — | 本域无桥接需求 |
| 9 | Proc | — | 无 `_Proc` 入口 |
| 10 | Registry | — | 无注册 |
| 11 | Populate | — | 常量在编译期确定 |
| 12 | Diagnostics | `status` / `info` 返回值 | 轻量诊断 |
| 13 | Test | `L2_NM/Tests/` | Deferred |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 数值分析基础工具：向量范数（L1/L2/Inf）、点积、叉积的数学定义与精度约定 |
| 逻辑链 | `L1_IF/Prec` → `NM_Base_Types`（TYPE/枚举） → `NM_Base_Norms` / `NM_Base_Utils`（算子） → 上层消费 |
| 计算链 | `DOT_PRODUCT` / `SQRT` 内联优化；热路径无动态分配、无 I/O |
| 数据链 | 无持久状态；纯函数 输入→输出，不写回全局变量 |

---

**版本**：v1.0  
**最后更新**：2026-03-23  
**状态**：✅ 已补全


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `NM_Base.f90` | `NM_Base` | `NM_Base_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `SetVerboseLevel` (TBP,PRV,—); `GetErrorCodeDesc` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `NM_Base_Finalize` (SUB,PRV,Finalize); `NM_Base_Finalize_Proc` (SUB,PRV,Finalize); `NM_Base_Init` (SUB,PRV,Init); `NM_Base_Init_Proc` (SUB,PRV,Init); `NM_Base_SetVerbose` (SUB,PRV,Mutate); `NM_Base_SetVerbose_Proc` (SUB,PRV,Mutate); `NM_Base_GetErrorCodeDesc` (FN,PRV,Query); `NM_Base_GetErrorCodeDesc_Proc` (SUB,PRV,Query); `NM_Base_GetSummary` (SUB,PRV,Query); `NM_Base_GetSummary_Proc` (SUB,PRV,Query) |
| `NM_Base_ErrCodes.f90` | `NM_Base_ErrCodes` | — | — |
| `NM_Base_Norms.f90` | `NM_Base_Norms` | `Norm_L2_Arg`, `Norm_L1_Arg`, `Norm_Inf_Arg`, `Norm_Fro_Arg`, `Normalize_Arg` | `Norm_L2` (FN,PUB,—); `Norm_L2_Proc` (SUB,PRV,—); `Norm_L1` (FN,PUB,—); `Norm_L1_Proc` (SUB,PRV,—); `Norm_Inf` (FN,PUB,—); `Norm_Inf_Proc` (SUB,PRV,—); `Norm_Fro` (FN,PUB,—); `Norm_Fro_Proc` (SUB,PRV,—); `Normalize` (FN,PUB,—); `Normalize_Proc` (SUB,PRV,—) |
| `NM_Base_Utils.f90` | `NM_Base_Utils` | `Dot_Product_Fast_Arg`, `Cross_Product_Arg`, `Triple_Product_Arg`, `Angle_Between_Arg` | `Dot_Product_Fast` (FN,PUB,—); `Dot_Product_Fast_Proc` (SUB,PRV,—); `Cross_Product` (FN,PUB,—); `Cross_Product_Proc` (SUB,PRV,—); `Triple_Product` (FN,PUB,—); `Triple_Product_Proc` (SUB,PRV,—); `Angle_Between` (FN,PUB,—); `Angle_Between_Proc` (SUB,PRV,—) |
| `NM_Base_Def.f90` | — | — | — |
| `NM_Base_Def.f90` | `NM_Base_Def` | `NM_ArcLen_Type`, `NM_LinSolv_Type`, `NM_NLSolv_Type`, `NM_EigenSolv_Type`, `NM_TimeInt_Type`, `NM_Precond_Type`, `NM_NumCtrl_Type` | — |
| `NM_Base_ErrCodes.f90` | `NM_Base_ErrCodes` | — | — |
| `NM_Base_Norms.f90` | `NM_Base_Norms` | `Norm_L2_Arg`, `Norm_L1_Arg`, `Norm_Inf_Arg`, `Norm_Fro_Arg`, `Normalize_Arg` | `Norm_L2` (FN,PUB,—); `Norm_L2_Proc` (SUB,PRV,—); `Norm_L1` (FN,PUB,—); `Norm_L1_Proc` (SUB,PRV,—); `Norm_Inf` (FN,PUB,—); `Norm_Inf_Proc` (SUB,PRV,—); `Norm_Fro` (FN,PUB,—); `Norm_Fro_Proc` (SUB,PRV,—); `Normalize` (FN,PUB,—); `Normalize_Proc` (SUB,PRV,—) |
| `NM_Base_Utils.f90` | `NM_Base_Utils` | `Dot_Product_Fast_Arg`, `Cross_Product_Arg`, `Triple_Product_Arg`, `Angle_Between_Arg` | `Dot_Product_Fast` (FN,PUB,—); `Dot_Product_Fast_Proc` (SUB,PRV,—); `Cross_Product` (FN,PUB,—); `Cross_Product_Proc` (SUB,PRV,—); `Triple_Product` (FN,PUB,—); `Triple_Product_Proc` (SUB,PRV,—); `Angle_Between` (FN,PUB,—); `Angle_Between_Proc` (SUB,PRV,—) |
| `NM_Prec_Convert.f90` | `NM_PrecConvert` | — | `NM_Prec_Convert_Array_DP_to_SP` (SUB,PUB,Bridge); `NM_Prec_Convert_Array_SP_to_DP` (SUB,PUB,Bridge) |
