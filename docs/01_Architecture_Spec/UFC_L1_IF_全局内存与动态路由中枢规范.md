# UFC L1_IF 基础设施层核心规范：全局内存池与动态路由中枢

> **核心哲学 (The Prime Directive)**:
> 本规范定义了 UFC 架构的两大“物理大动脉”。
> 所有的底层模板（标准件）必须基于这种**“完美的理想状态”**来设计，旧代码只是参考。如果旧代码不符合本规范，必须被切割、重塑，经历多次迭代逼近本标准，绝不允许标准向旧代码妥协！

---

## 枢纽一：全局预分配内存池 (Global Memory Pool & Slice Injection)

### 1. 痛点与破局
在传统的旧代码中，每个单元或材料往往自己去 `ALLOCATE` 历史变量，或者使用庞大而不可控的 `COMMON` 块。这不仅导致严重的内存碎片，更直接杀死了多线程并行与 GPU 移植的可能。

### 2. UFC 完美标准设计 (The Ideal Design)
我们采用 **“L1 统管分配，L3/L4 切片引用”** 的终极模式。

* **[规则 1] 绝对零分配 (Zero-Allocation Hot Path)**:
  `L3_MD` 和 `L4_PH` 的 `_Proc` 和 `_Core` 中，**绝对禁止**出现任何 `ALLOCATE` 或 `DEALLOCATE` 语句。
* **[规则 2] AOSOA 预分配 (Array of Structs / Struct of Arrays)**:
  在 `Init`（0增量步）阶段，`L1_IF_Memory` 会根据网格读取模块传来的单元总数、积分点总数，一次性分配一块连续的巨型内存块（Global State Array）。
* **[规则 3] 内存切片注入 (Slice Injection)**:
  当 `L5_RT` 发起积分点遍历时，`L5_RT` 会从全局内存池中切出一段指针（`POINTER => Global_Array(offset : offset+length)`），通过 SIO `_Arg` 接口投递给 `L4_PH`。`L4_PH` 认为自己在使用局部的 `_State`，但实际上它在**直接覆写全局连续内存池的某一个切片**。

### 3. 在工单中的体现
在编写模块的 `Feature_Manifest.md` 时，所有 `_State` 中的变量必须显式声明为 `POINTER`。它们不拥有物理内存，只是一根指向 L1_IF 内存池的针。

---

## 枢纽二：面向扩展的动态路由中枢 (Dynamic Registry & Dispatch Hub)

### 1. 痛点与破局
旧的有限元代码中，`L5_RT` 组装刚度时，往往写成了长达数千行的 `SELECT CASE (Element_Type)`。每加一种新单元，就要修改核心控制流，严重违背“开闭原则 (Open-Closed Principle)”。

### 2. UFC 完美标准设计 (The Ideal Design)
我们采用基于 **Fortran 2003 过程指针 (Procedure Pointer) 的动态注册表**。

* **[规则 1] 标准抽象接口 (Abstract Interface)**:
  在 `L1_IF_Registry` 中定义绝对统一的函数签名规范。例如：
  `ABSTRACT INTERFACE` 
  `  SUBROUTINE I_Element_PtItrEvl(desc, state, algo, ctx, arg)`
* **[规则 2] 模块自举报到 (Self-Registration)**:
  `L4_PH_Elem_CPS4` 在被加载时，必须主动向 `L1_IF_Registry` 注册自己：
  `CALL Register_Element(id=42, name='CPS4', eval_ptr=PH_Elem_CPS4_PtItrEvl)`
* **[规则 3] 无分支的分发 (Branchless Dispatch)**:
  在 `L5_RT` 的热路径中，不再有 `IF/ELSE`。它只需要根据当前单元 ID 拿到函数指针，直接调用：
  `CALL element_registry(elem_id)%eval_ptr(desc, state, algo, ctx, arg)`

### 3. 在工单中的体现
在开发标准件时，`_Proc.f90` 的签名**必须 100% 严丝合缝地对齐** `L1_IF_Registry` 规定的抽象接口。如果旧代码的参数对不上，必须在 `_Def.f90` 和 `_Proc.f90` 里强行进行参数映射，用标准件的壳包住旧代码，再通过多次重构逼近 0 误差。

---
> **执行纲领**：
> 无论旧资产有多么扭曲，我们要建的 `ufc_templates` 永远代表这套 L1 内存池与注册表的**最完美投影**。我们要用这个完美的模具，像锻造钢铁一样，把旧代码一点点砸进这个标准里。