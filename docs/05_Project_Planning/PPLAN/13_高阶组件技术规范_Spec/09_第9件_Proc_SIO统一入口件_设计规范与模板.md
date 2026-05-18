# 第 9 件：Proc (SIO 统一入口件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/09_第9件_Proc_SIO统一入口件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 9 件  
> **目标**：强制实施“结构化 IO（SIO）”，收敛子程序长长的参数列表，固化五参/六参标准防腐面。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **终结参数爆炸**：传统 Fortran 子程序动辄 20~30 个参数，扩展困难。`_Proc` 强制将所有输入输出裹挟进 `_Arg` 与四型参数中。
2. **统一门面调度**：作为 L5/L6 或 Harness 工具呼叫物理子域的唯一官方门面。

### 1.2 架构红线 (Red Lines)
- **严格五参/六参**：`_Proc` 的所有公有 `SUBROUTINE` 签名只能是：
  - 5参：`(desc, state, algo, ctx, args)`
  - 6参：`(desc, state, algo, ctx, rt_ctx, args)` （包含全局 L5 运行时上下文）。
- **强制使用 `[IN] / [OUT]` 注释**：在 `_Arg` 的类型定义中，必须紧跟 `![IN]` 或 `![OUT]` 注释，声明数据的流向逻辑。

---

## 2. 核心架构时序与机制

1. **[L5 调用者]** 实例化 `XX_Arg` 变量，填入必要的 `[IN]` 控制参数。
2. **[Caller -> Proc]** 调用 `XX_Proc_Execute(desc, state, algo, ctx, arg)`。
3. **[Proc 路由]** `_Proc` 模块解开 `Arg` 检查控制字，如果是计算任务，将其透传给底层的 `Main Core`。如果是其他请求（如查询状态），则分发给对应的 `_Reg` 或辅助程序。
4. **[Proc -> Caller]** `_Proc` 将计算结果打包回 `Arg` 的 `[OUT]` 字段并带回给调用者。

---

## 3. 伪代码模板与合同定义

```fortran
!=============================================================================
! MODULE: PH_Mat_Proc
! 描述: 材料域的结构化 IO 标准门面与入口
!=============================================================================
MODULE PH_Mat_Proc
    USE PH_Mat_Def     ! 包含四型
    USE PH_MatElastic  ! 具体实现核
    USE PH_MatPlastic  ! 具体实现核
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: PH_Mat_Arg
    PUBLIC :: PH_Mat_Proc_Eval

    !> SIO 的核心：Args 参数束定义
    TYPE :: PH_Mat_Arg
        INTEGER :: req_type      ![IN]  请求类型 (1=积分, 2=仅取模量)
        REAL*8  :: dt            ![IN]  时间增量
        INTEGER :: mat_type_id   ![IN]  路由判据 (例如 1=弹性, 2=塑性)
        
        INTEGER :: status_code   ![OUT] 状态返回码
        REAL*8  :: total_energy  ![OUT] 顺带返回的总应变能
    END TYPE PH_Mat_Arg

CONTAINS

    !> 标准 SIO 六参入口
    SUBROUTINE PH_Mat_Proc_Eval(desc, state, algo, ctx, rt_ctx, args)
        TYPE(PH_Mat_Desc),  INTENT(IN)    :: desc
        TYPE(PH_Mat_State), INTENT(INOUT) :: state
        TYPE(PH_Mat_Algo),  INTENT(IN)    :: algo
        TYPE(PH_Mat_Ctx),   INTENT(INOUT) :: ctx
        TYPE(RT_Com_Ctx),   INTENT(IN)    :: rt_ctx   ! L5全局上下文
        TYPE(PH_Mat_Arg),   INTENT(INOUT) :: args     ! IN/OUT 包裹体
        
        ! 内部状态缓冲
        INTEGER :: local_status

        ! 代理路由到真正的 Core
        SELECT CASE (args%mat_type_id)
            CASE (1)
                CALL PH_Mat_Elastic_Eval(desc, state, algo, ctx, local_status)
            CASE (2)
                CALL PH_Mat_Plastic_Eval(desc, state, algo, ctx, local_status)
            CASE DEFAULT
                local_status = -1 ! ERROR_UNKNOWN_MAT
        END SELECT
        
        ! 装填输出 Arg
        args%status_code = local_status
        ! args%total_energy = ...
        
    END SUBROUTINE PH_Mat_Proc_Eval

END MODULE PH_Mat_Proc
```

---

## 4. 合同检验点 (Checklist)
1. 检查入口函数是否存在超过 6 个位置参数的签名？（严禁出现 `arg1, arg2, arg3...`）。
2. 检查 `XX_Arg` 的定义中，是否每个字段都在同行的注释中显式标注了 `![IN]`、`![OUT]` 或是 `![INOUT]`？
3. 弃用验证：是否已经彻底去除了老旧的 `xxx_inp` 和 `xxx_out` 成对结构体传参模式？