# 第 8 和 11 件：Bridge & Populate (防腐桥与数据灌入件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/03_第8和11件_Bridge_Populate_防腐数据件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 8、11 件  
> **目标**：解决 L3 建模域（复杂树状对象）与 L4/L5 计算域（平铺一维数组）之间的阻抗失配，实现层级间的解耦防腐。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **防腐隔离 (Anti-Corruption)**：绝不允许 L5 求解器直接访问 L3 的用户建模属性（如解析 `Solid_Section%Material%Density`）。必须通过此组件进行解耦。
2. **树状扁平化 (Tree Flattening)**：将 L3 的多态对象提取、平整为一块连续的 `REAL*8` 内存（即 Populated `_Desc`），供高频热路径使用。

### 1.2 架构红线 (Red Lines)
- **时机隔离**：
  - `Populate` 动作必须且只能发生在 `Phase = Init` 时期。禁止在 `Phase = Step` 或 `Iter` 的热循环中解析 L3 属性。
  - `Bridge` 动作发生在热路径中，但只允许做指针切片（Slicing）或句柄（Handle）查找，**绝对禁止**内部出现 `ALLOCATE` 或深拷贝。

---

## 2. 核心架构时序与机制

### 2.1 时序图
1. **[Init 阶段] -> Populate**：L5 调度器呼叫 `Bridge_Populate_Desc`。此组件遍历 L3 树，计算并 `ALLOCATE` 出 `_Desc` 的扁平大数组。L3 树被冻结。
2. **[Step 阶段] -> Bridge_Slice**：进入牛顿迭代。L5 将包含所有单元的 `_Desc` 大数组丢给 Bridge。Bridge 内部不做计算，只用 `start_idx` 和 `end_idx` 提取某一组单元的切片，传给 L4_PH。

---

## 3. 伪代码模板与合同定义

### 3.1 Populate (数据灌入：仅限 Init 时相)
```fortran
!=============================================================================
! MODULE: PH_Elem_Brg (Populate 部分)
!=============================================================================
MODULE PH_Elem_Brg
    ! USE L3_MD... (引入上层建模数据)
    ! USE PH_Elem_Def (引入本层底层 Desc)
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: PH_Elem_Populate_Desc

CONTAINS

    !> 在 Init 阶段，将 L3 的网格/截面树，拍扁并灌入 L4 的只读 Desc 数组
    SUBROUTINE PH_Elem_Populate_Desc(L3_Model_Tree, out_Desc, status)
        ! ...
        ! 1. 统计尺寸，执行生命周期内唯一一次 ALLOCATE
        num_elems = L3_Model_Tree%Get_Total_Elements()
        ALLOCATE(out_Desc%mat_props(MAX_PROPS, num_elems))
        ALLOCATE(out_Desc%node_connect(MAX_NODES, num_elems))

        ! 2. 拍扁数据 (Tree Flattening)
        DO i = 1, num_elems
            ! 解开对象层级，提取纯粹的实数放入连续内存
            out_Desc%mat_props(1, i) = L3_Model_Tree%elem(i)%section%mat%E
            out_Desc%mat_props(2, i) = L3_Model_Tree%elem(i)%section%mat%Nu
            out_Desc%node_connect(:, i) = L3_Model_Tree%elem(i)%nodes(:)
        END DO
        
        out_Desc%is_populated = .TRUE.
        status = 0
    END SUBROUTINE PH_Elem_Populate_Desc

END MODULE PH_Elem_Brg
```

### 3.2 Bridge (热路径桥接防腐)
```fortran
! (接上 MODULE PH_Elem_Brg)
    
    PUBLIC :: PH_Elem_Core_Bridge

    !> 在热循环中，仅作状态切片与参数重组，绝无 ALLOCATE
    SUBROUTINE PH_Elem_Core_Bridge(global_desc, global_state, global_ctx, elem_idx, args, status)
        ! ...
        ! 从全局巨型数组中提取属于当前单元 (或 Batch) 的切片
        TYPE(PH_Elem_Desc_Slice)  :: local_desc
        TYPE(PH_Elem_State_Slice) :: local_state
        
        ! O(1) 的指针切片操作或偏移量传递
        local_desc%props => global_desc%mat_props(:, elem_idx)
        local_state%stress => global_state%stress_list(:, elem_idx)
        
        ! 代理调用实际物理核
        CALL PH_Elem_Core_Eval(local_desc, local_state, global_ctx, args, status)
        
    END SUBROUTINE PH_Elem_Core_Bridge
```

---

## 4. 合同检验点 (Checklist)
1. 检查所有的 `ALLOCATE` 是否都被封闭在了命名含 `Populate` 或仅在 `Init` 阶段调用的逻辑中。
2. 检查 `_Core.f90` (物理核心) 是否完全没有 `USE L3_MD_*` 的代码。L3 依赖必须止步于 `_Brg.f90`。
3. 检查 L4/L5 核心结构中，是否去除了复杂的指针链表，全部替换为了从 Populate 灌入的一维/二维连续浮点数组。