# 第 7 件：Main Core (主计算核心件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/08_第7件_MainCore_主计算核心件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 7 件  
> **目标**：打造极致性能、纯粹且无副作用的数学计算引擎（热路径）。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **纯数学无副作用 (Pure Function)**：输入四型，输出结果。不读取硬盘，不发送网络包，不做不可控内存分配。
2. **极限向量化 (Extreme Vectorization)**：内存连续，循环体内部不含分支阻塞（`IF/ELSE`），确保编译器能完美开启 SIMD/AVX 指令级并行。

### 1.2 架构红线 (Red Lines)
- **禁止 `ALLOCATE`**：在热路径主核心中，绝对禁止内存分配。所有工作矩阵必须由 `_Ctx` 提供。
- **禁止系统 IO**：绝对禁止 `PRINT *` 或 `WRITE`，即使是报错。所有异常只能通过 `status` 返回码抛出。
- **禁止 L3 对象侵入**：主计算不能依赖 L3 模块，入参必须是平整过的 L4 级标量或数组。

---

## 2. 核心架构时序与机制

主核心是被调用的“齿轮”：
1. **[L5_RT_Solv]** 发起调用。
2. 传参：`desc` (只读), `state` (待更新), `algo` (策略参数), `ctx` (工作空间)。
3. **[SIMD Loop]**：执行紧凑的高斯积分点循环或本构状态机。
4. 写回 `state` 与 `ctx%jacobian`。
5. 返回 `status = 0` (成功)。

---

## 3. 伪代码模板与合同定义

```fortran
!=============================================================================
! MODULE: PH_ElemC3D8
! 描述: C3D8 单元主计算核心
! 注意: 模块名即为功能名，不再携带 _Ops 或 _Algo 后缀。
!=============================================================================
MODULE PH_ElemC3D8
    USE PH_Elem_Def
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: PH_Elem_C3D8_Eval

CONTAINS

    !> C3D8 单元评估核 (纯数学计算过程)
    SUBROUTINE PH_Elem_C3D8_Eval(desc, state, algo, ctx, args, status)
        TYPE(PH_Elem_Desc),  INTENT(IN)    :: desc
        TYPE(PH_Elem_State), INTENT(INOUT) :: state
        TYPE(PH_Elem_Algo),  INTENT(IN)    :: algo
        TYPE(PH_Elem_Ctx),   INTENT(INOUT) :: ctx
        ! TYPE(PH_Elem_Arg) 是可选的，这里用不到可省略或传通用 args
        INTEGER, INTENT(OUT) :: status
        
        INTEGER :: i, j

        ! 1. 提取预分配上下文 (无 ALLOCATE)
        ! B矩阵和刚度矩阵复用 Ctx 内存
        ctx%local_stiffness = 0.0d0
        ctx%local_residual  = 0.0d0
        
        ! 2. 紧凑高斯点循环 (SIMD Friendly)
        ! 此处避免使用复杂的 IF 分支
        DO i = 1, 8  ! 8节点
            ! 纯粹的数学推导：形函数计算, 雅可比行列式
            ! ctx%b_matrix = ...
            ! ... 计算应力/应变 ...
            ! 状态更新
            ! state%stress = ...
        END DO

        ! 3. 结果冒泡
        ! 如果中间发生本构奇异，使用错误码返回
        ! IF (detJ <= 0.0d0) THEN
        !     status = 401 ! ERROR_NEGATIVE_JACOBIAN
        !     RETURN
        ! END IF
        
        status = 0
    END SUBROUTINE PH_Elem_C3D8_Eval

END MODULE PH_ElemC3D8
```

---

## 4. 合同检验点 (Checklist)
1. 检查此文件内是否出现了任何 `ALLOCATE` 或 `DEALLOCATE` 关键字？
2. 检查此文件内是否包含 `PRINT *` 或 `WRITE(6, *)`？（如有，必须清理）。
3. 检查循环内是否有极其深度的对象解引用（如 `desc%parent%section%mat%prop1`）？如果超过两层，说明 Populate 阶段没有将其彻底拍扁。