## Precision 域级合同卡（L1_IF）

- **层级**：L1_IF
- **域名**：Precision / 数值精度与类型定义
- **缩写**：IF_Precision (`IF_Precision_*`)
- **职责**：定义全局数值精度（wp/i4/i8）、复数类型、物理常量；提供类型转换与精度查询接口。
- **四型配置**：
  - **Desc**：精度参数常量、复数 TYPE、物理常量结构。
  - **State**：无（纯编译时常量）。
  - **Ctx**：无。
  - **Algo**：类型转换、精度提升/降低。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Types | wp, sp, dp, i4, i8 | 精度别名定义 |
| Complex | cmplx_wp, Conjg_Fast | 复数运算 |
| Constants | pi, euler, gravity | 物理/数学常量 |
| Convert | Real_To_Double, Int_To_Real | 类型转换 |

- **依赖**：无（最底层基础）。
- **热路径**：**是** — 所有数值计算都依赖本域定义。
- **实现锚点**：
  - `IF_Precision_Params.f90` — 精度参数定义
    ```fortran
    MODULE IF_Precision_Params
      IMPLICIT NONE
      
      ! 浮点精度
      INTEGER, PARAMETER :: sp = KIND(1.0E0)    ! 单精度 (32-bit)
      INTEGER, PARAMETER :: dp = KIND(1.0D0)    ! 双精度 (64-bit)
      INTEGER, PARAMETER :: wp = dp             ! 工作精度（默认双精度）
      
      ! 整数精度
      INTEGER, PARAMETER :: i1 = SELECTED_INT_KIND(2)   ! 8-bit
      INTEGER, PARAMETER :: i2 = SELECTED_INT_KIND(4)   ! 16-bit
      INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)   ! 32-bit
      INTEGER, PARAMETER :: i8 = SELECTED_INT_KIND(18)  ! 64-bit
      
      ! 复数类型
      INTEGER, PARAMETER :: csp = KIND((1.0E0, 1.0E0))  ! 单精度复数
      INTEGER, PARAMETER :: cdp = KIND((1.0D0, 1.0D0))  ! 双精度复数
      INTEGER, PARAMETER :: cwp = cdp                   ! 工作复数精度
    END MODULE IF_Precision_Params
    ```
  - `IF_Precision_Constants.f90` — 物理/数学常量
    ```fortran
    MODULE IF_Precision_Constants
      USE IF_Precision_Params
      IMPLICIT NONE
      
      ! 数学常量（使用高精度字面量）
      REAL(wp), PARAMETER :: pi = 3.14159265358979323846_wp
      REAL(wp), PARAMETER :: two_pi = 2.0_wp * pi
      REAL(wp), PARAMETER :: half_pi = 0.5_wp * pi
      REAL(wp), PARAMETER :: euler = 2.71828182845904523536_wp
      
      ! 物理常量（SI 单位制）
      REAL(wp), PARAMETER :: gravity = 9.80665_wp       ! 重力加速度 m/s^2
      REAL(wp), PARAMETER :: young_steel = 210.0E9_wp   ! 钢杨氏模量 Pa
      REAL(wp), PARAMETER :: poisson_steel = 0.30_wp    ! 钢泊松比
      REAL(wp), PARAMETER :: density_steel = 7850.0_wp  ! 钢密度 kg/m^3
      
      ! 容差默认值
      REAL(wp), PARAMETER :: tol_default = 1.0E-8_wp
      REAL(wp), PARAMETER :: tol_loose = 1.0E-6_wp
      REAL(wp), PARAMETER :: tol_tight = 1.0E-12_wp
    END MODULE IF_Precision_Constants
    ```
  - `IF_Precision_Utils.f90` — 工具函数
    ```fortran
    PURE FUNCTION Real_To_Double(r) RESULT(d)
      REAL(sp), INTENT(IN) :: r
      REAL(dp) :: d
      ! 伪代码：单精度转双精度（零开销转换）
      d = REAL(r, dp)
    END FUNCTION Real_To_Double
    
    PURE FUNCTION Double_To_Real(d) RESULT(r)
      REAL(dp), INTENT(IN) :: d
      REAL(sp) :: r
      ! 伪代码：双精度转单精度（可能损失精度）
      r = REAL(d, sp)
    END FUNCTION Double_To_Real
    
    PURE FUNCTION Conjg_Fast(z) RESULT(zc)
      COMPLEX(wp), INTENT(IN) :: z
      COMPLEX(wp) :: zc
      ! 伪代码：复共轭（内建 CONJG 封装）
      zc = CONJG(z)
    END FUNCTION Conjg_Fast
    
    ! 使用示例：stride-1 访问模式
    SUBROUTINE Scale_Array(arr, factor)
      REAL(wp), INTENT(INOUT) :: arr(:)  ! stride-1 连续数组
      REAL(wp), INTENT(IN) :: factor
      INTEGER(i4) :: i
      
      ! 优化：DO CONCURRENT 自动向量化
      DO CONCURRENT (i = 1:SIZE(arr))
        arr(i) = arr(i) * factor
      END DO
      
      ! 或使用数组语法（编译器优化为 BLAS DSCAL）
      ! arr = arr * factor
    END SUBROUTINE Scale_Array
    ```

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**版本**：v1.0  
**最后更新**：2026-03-23  
**状态**：✅ 已补全

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L1_PRECISION_xxx` (10700–10799) — 极少触发 |
| 严重级 | WARNING: 精度降低(单/双切换); ERROR: 无; FATAL: 无 |
| 传播规则 | 编译时常量——运行时几乎无错误 |
| 恢复策略 | N/A（编译时确定） |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L1_IF/* | U(USE) | 同层所有域 USE 精度定义 |
| R2 | L2_NM/* | U(USE) | 数值方法层 USE 精度定义 |
| R3 | L3_MD/* | U(USE) | 模型数据层 USE 精度定义 |
| R4 | L4_PH/* | U(USE) | 有限元组件层 USE 精度定义 |
| R5 | L5_RT/* | U(USE) | 运行时层 USE 精度定义 |
| R6 | L6_AP/* | U(USE) | 应用层 USE 精度定义 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 全栈统一使用 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 不得向上依赖 (L2–L6) | 硬 | Code Review | — |
| 禁止使用 `ISO_FORTRAN_ENV` 替代 | 硬 | Harness | H-PREC-01 |
| 禁止自定义 KIND 参数 | 硬 | Harness | H-PREC-02 |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | wp/sp/dp/i4/i8 精度参数 | 编译时常量 |
| 2 | State 定义 | N/A | 无运行时状态 |
| 3 | Algo 定义 | Real_To_Double / Conjg_Fast | 类型转换工具 |
| 4 | Ctx 定义 | N/A | 无上下文 |
| 5 | Init/Finalize | N/A | 编译时模块无生命周期 |
| 6 | Query | N/A | 常量直接 USE 访问 |
| 7 | Validate | N/A | 编译器类型检查 |
| 8 | Populate | N/A | L1 无 Populate 链 |
| 9 | Bridge | N/A | 最底层无桥接 |
| 10 | WriteBack | N/A | 基础设施不回写 |
| 11 | Parse | N/A | 不涉及关键字解析 |
| 12 | Compute | Scale_Array 等 | 数组工具(可热路径) |
| 13 | Error | N/A | 编译时——极少运行时错误 |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | IEEE 754 浮点标准——wp 默认双精度 |
| 逻辑链 | IF_Prec_Core 为全栈唯一精度入口，禁止自定义 KIND |
| 计算链 | 常量在编译时内联——零运行时开销 |
| 数据链 | wp/i4 决定全栈 REAL/INTEGER 存储布局 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_Base_Def.f90` | `IF_Base_Def` | — | `IF_Const_DegToRad` (FN,PUB,—); `IF_Const_Get_E` (FN,PUB,Query); `IF_Const_Get_PI` (FN,PUB,Query); `IF_Const_RadToDeg` (FN,PUB,—) |
| `IF_Prec_Core.f90` | `IF_Prec_Core` | — | `IF_Prec_IsNaN` (FN,PUB,Query); `IF_Prec_IsInf` (FN,PUB,Query); `IF_Prec_IsFinite` (FN,PUB,Query); `IF_Prec_Check_Overflow` (FN,PUB,Validate); `IF_Prec_Check_Underflow` (FN,PUB,Validate); `IF_Prec_Check_Stability` (SUB,PUB,Validate) |
