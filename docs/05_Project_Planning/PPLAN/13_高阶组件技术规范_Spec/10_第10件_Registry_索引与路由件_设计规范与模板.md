# 第 10 件：Registry (索引与路由件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/10_第10件_Registry_索引与路由件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 10 件  
> **目标**：实现物理单元、材料本构、关键字体系的注册机制，通过 $O(1)$ 或 $O(\log N)$ 路由实现解耦，避免大量的 IF-ELSE 污染主控流。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **开闭原则 (Open-Closed Principle)**：当新增一个单元类型（如新写了 `C3D20`）时，只需要在注册表中加一行映射，绝不需要修改上层循环的框架。
2. **正交拆分**：将多维度的判断（如隐式/显式、热/力物理场）降维并路由到准确的执行算子上。

### 1.2 架构红线 (Red Lines)
- **禁止计算**：路由件 (`_Reg` 或 `_Idx`) 内绝对禁止写数学公式。
- **纯粹调度**：它是“总机接线员”，只能查表、映射常数 ID，然后返回代理子程序的 `PROCEDURE POINTER` 或者返回路由 ID。

---

## 2. 核心架构时序与机制

1. **[注册阶段 - Init]**：在程序启动时，各个物理组件向 `_Reg` 提交自己的 ID、类型描述符以及函数指针。
2. **[查询阶段 - Populate/Step]**：解析器遇到关键字 `*ELEMENT, TYPE=C3D8`，通过 `_Reg` 查询字符串字典，获得整数 ID `101`。
3. **[路由分发 - Step]**：在主求解循环或 `_Proc` 中，根据提取到的 ID `101`，用 `SELECT CASE` 快速路由跳转。

---

## 3. 伪代码模板与合同定义

```fortran
!=============================================================================
! MODULE: PH_ElemReg
! 描述: 单元域类型路由与注册件
!=============================================================================
MODULE PH_ElemReg
    USE PH_Elem_Def
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: PH_ElemReg_Get_ID
    PUBLIC :: PH_ElemReg_Get_Dofs

CONTAINS

    !> 字符串到整数 ID 的映射 (O(logN) 或字典查询)
    FUNCTION PH_ElemReg_Get_ID(elem_name) RESULT(elem_id)
        CHARACTER(LEN=*), INTENT(IN) :: elem_name
        INTEGER :: elem_id

        SELECT CASE (TRIM(ADJUSTL(elem_name)))
            CASE ('C3D8')
                elem_id = ELEM_TYPE_C3D8
            CASE ('CPE4')
                elem_id = ELEM_TYPE_CPE4
            CASE DEFAULT
                elem_id = -1
        END SELECT
    END FUNCTION PH_ElemReg_Get_ID
    
    !> 属性查询机制 (元数据中心)
    FUNCTION PH_ElemReg_Get_Dofs(elem_id) RESULT(num_dofs)
        INTEGER, INTENT(IN) :: elem_id
        INTEGER :: num_dofs

        SELECT CASE (elem_id)
            CASE (ELEM_TYPE_C3D8)
                num_dofs = 24  ! 8节点 x 3个自由度
            CASE (ELEM_TYPE_CPE4)
                num_dofs = 8   ! 4节点 x 2个自由度
            CASE DEFAULT
                num_dofs = 0
        END SELECT
    END FUNCTION PH_ElemReg_Get_Dofs

END MODULE PH_ElemReg
```

---

## 4. 合同检验点 (Checklist)
1. 检查是否存在将长字符串判别（`IF elem_name == 'C3D8'`）直接写在热路径大循环里的情况？（必须改为先查表获得整数 ID，热路径只判断整数）。
2. `_Reg.f90` 内是否保持了干净的字典属性，没有任何物理属性（如坐标、刚度）的具体定义与计算？