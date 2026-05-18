# 第 16 件：AI Proxy (AI 代理与批处理执行件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/01_第16件_AI_Proxy批处理执行件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 16 件  
> **目标**：为基于数据驱动/深度学习的有限元计算（AI4S）提供高性能的张量互操作（Zero-Copy）与批处理执行机制（Batched Engine）。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **打破单点循环瓶颈**：传统 FEM 的 `DO i = 1, num_elem` 调用本构的方法，若挂载神经网络会因极高的推断启动延迟（Inference Overhead）而卡死。必须实现 **Batched Execution（批处理执行）**。
2. **打通异构内存壁垒**：Fortran 的数组必须能被 C++/PyTorch 后端无损接管，实现 **Zero-Copy（零拷贝）** 内存互操作，彻底消除内存搬运开销。

### 1.2 架构红线 (Red Lines)
- **禁用 `ALLOCATE` 于热路径**：批处理的 Buffer 必须在 `Init` 阶段预分配，每次推断复用该内存。
- **强制 `BIND(C)`**：所有交予 AI 推理的张量数组必须使用 `TARGET` 和 `BIND(C)` 声明，保证内存连续。
- **严守维度倒置规则**：Fortran 的内存是**列优先 (Column-major)**，C++ 是**行优先 (Row-major)**。若在 Fortran 中打包张量尺寸为 `(Num_Features, Batch_Size)`，传递给 C++ 后将被视作 `(Batch_Size, Num_Features)`，此规则必须在接口卡死！

---

## 2. 核心架构时序与机制

### 2.1 批处理循环机制 (Batched Loop)
AI Proxy 接管了本构计算。时序如下：
1. **[L5_RT 控制流]**：不再对每个单元调用本构。
2. **[Proxy_Pack]**：遍历一批单元（如 10000 个积分点），将其当前应变 $\varepsilon$ 和内部变量提取并存入 `Batch_Buffer_In`。
3. **[Proxy_Invoke]**：调用 C-Interop FFI，将 `Batch_Buffer_In` 的指针（`C_PTR`）传递给 AI 推理引擎（如 LibTorch）。AI 将推断结果（应力 $\sigma$）写入 `Batch_Buffer_Out`。
4. **[Proxy_Unpack]**：遍历同一批单元，从 `Batch_Buffer_Out` 提取结果并回写到 Fortran 的 `_State` 结构中。

---

## 3. 伪代码模板与合同定义

### 3.1 内存规约：Buffer 结构体定义
所有用于与 AI 引擎通信的 Buffer，必须遵循严格的 C 兼容定义。

```fortran
!=============================================================================
! MODULE: RT_AIProxy_Def
! 描述: AI 批处理执行件的数据字典与互操作 Buffer 定义
!=============================================================================
MODULE RT_AIProxy_Def
    USE ISO_C_BINDING
    IMPLICIT NONE
    PRIVATE
    
    ! 公开类型
    PUBLIC :: RT_AIProxy_Buffer

    !> AI 批处理张量缓冲区 (Zero-Copy 核心)
    TYPE, BIND(C) :: RT_AIProxy_Buffer
        ! 数据指针，由于是在 Fortran 端分配，这里使用 C_PTR 用于跨语言传递
        TYPE(C_PTR) :: input_tensor_ptr
        TYPE(C_PTR) :: output_tensor_ptr
        
        ! 维度信息 (注意: 传给 C++ 时，实际看作 shape[batch_size, num_features])
        INTEGER(C_INT) :: num_features
        INTEGER(C_INT) :: batch_size
    END TYPE RT_AIProxy_Buffer

END MODULE RT_AIProxy_Def
```

### 3.2 外函数接口定义 (FFI)
声明 C++ 后端的推理入口。

```fortran
!=============================================================================
! MODULE: RT_AIProxy_Brg
! 描述: C-Interop 桥接接口
!=============================================================================
MODULE RT_AIProxy_Brg
    USE ISO_C_BINDING
    IMPLICIT NONE
    PRIVATE
    
    PUBLIC :: Invoke_AI_Inference_CPP
    
    INTERFACE
        ! 对应的 C++ 函数: 
        ! extern "C" int Invoke_AI_Inference_CPP(double* in_tensor, double* out_tensor, int features, int batch);
        FUNCTION Invoke_AI_Inference_CPP(in_ptr, out_ptr, num_feats, batch_size) BIND(C, NAME="Invoke_AI_Inference_CPP")
            IMPORT :: C_PTR, C_INT
            TYPE(C_PTR), VALUE :: in_ptr
            TYPE(C_PTR), VALUE :: out_ptr
            INTEGER(C_INT), VALUE :: num_feats
            INTEGER(C_INT), VALUE :: batch_size
            INTEGER(C_INT) :: Invoke_AI_Inference_CPP  ! 返回错误码
        END FUNCTION Invoke_AI_Inference_CPP
    END INTERFACE

END MODULE RT_AIProxy_Brg
```

### 3.3 核心实现：Pack -> Invoke -> Unpack
主控流。展示了如何做列优先的内存填充。

```fortran
!=============================================================================
! MODULE: RT_AIProxy_Batch
! 描述: 批处理执行件主控模块
!=============================================================================
MODULE RT_AIProxy_Batch
    USE ISO_C_BINDING
    USE RT_AIProxy_Def
    USE RT_AIProxy_Brg
    ! USE L4_PH_... (引入物理状态类型)
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: RT_AI_Batched_Execution

CONTAINS

    !> 执行一次满 Batch 的 AI 推理
    SUBROUTINE RT_AI_Batched_Execution(elem_states, num_elems, status)
        ! 假设 elem_states 是 L4 传来的状态数组
        ! ...
        INTEGER, INTENT(OUT) :: status
        
        ! 内部工作张量 (需在 Ctx 中长期分配，这里仅为示意)
        REAL(C_DOUBLE), ALLOCATABLE, TARGET :: local_in(:,:)   ! (Features, Batch)
        REAL(C_DOUBLE), ALLOCATABLE, TARGET :: local_out(:,:)  ! (Features, Batch)
        INTEGER :: i_elem, err_code
        
        ! 1. Pack 阶段 (将离散单元状态打包成连续矩阵)
        ! 注意: 内部循环是 Features, 外部是 Batch，保证 Fortran 列优先的内存连续存取
        DO i_elem = 1, num_elems
            local_in(1, i_elem) = elem_states(i_elem)%strain_xx
            local_in(2, i_elem) = elem_states(i_elem)%strain_yy
            local_in(3, i_elem) = elem_states(i_elem)%strain_xy
            ! ... 提取内部变量 ...
        END DO
        
        ! 2. Invoke 阶段 (零拷贝调用 C++ 推理)
        err_code = Invoke_AI_Inference_CPP( &
            C_LOC(local_in), C_LOC(local_out), &
            SIZE(local_in, 1, KIND=C_INT), SIZE(local_in, 2, KIND=C_INT) &
        )
        
        IF (err_code /= 0) THEN
            status = err_code
            RETURN
        END IF
        
        ! 3. Unpack 阶段 (将推理出的应力/雅可比分散写回)
        DO i_elem = 1, num_elems
            elem_states(i_elem)%stress_xx = local_out(1, i_elem)
            elem_states(i_elem)%stress_yy = local_out(2, i_elem)
            elem_states(i_elem)%stress_xy = local_out(3, i_elem)
            ! ... 更新其他状态 ...
        END DO
        
        status = 0
    END SUBROUTINE RT_AI_Batched_Execution

END MODULE RT_AIProxy_Batch
```

---

## 4. 合同检验点 (Checklist)
1. 检查所有的传入 C++ 的数组是否挂载了 `TARGET` 属性并使用 `C_LOC()` 取指针。
2. 检查多维数组在 Pack 时，是否将 `batch_index` 放在数组的最右侧维度（Fortran 列优先要求）。
3. 检查 C++ 端的 `LibTorch/TensorRT` 包装器代码，是否使用了 `torch::from_blob` 接收 `double*`，且其传入的 sizes 数组顺序必须为 `{batch_size, num_features}` 以抵消 Fortran 的倒置。
4. 确认 `local_in` 和 `local_out` 内存是在 `Ctx` 级别预先 `ALLOCATE` 好的，决不能在 `RT_AI_Batched_Execution` 内分配。