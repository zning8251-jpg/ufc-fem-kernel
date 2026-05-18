# Extension全家族统一适配架构：UMAT/UEL/ULOAD等通用沙盒设计

## 1. 核心认知：物理上的差异与架构上的大一统
在商业有限元生态中，存在数十种用户自定义子程序（如 UMAT, UEL, ULOAD, UTEMP, DLOAD 等）。
*   **物理层面的差异**：它们的输入输出变量截然不同（UEL 涉及刚度阵与残差，UMAT 涉及应力与应变，ULOAD 涉及坐标与时间）。
*   **架构层面的统一**：对于 UFC 内核而言，它们本质上**全是同一种东西**——即“**带有遗留签名的外部回调黑盒（Legacy Callback Blackbox）**”。

因此，在我们的“全景 17 件套”架构中，所有这些自定义子程序都必须被**统一收编到“第 14 件：Extension 沙盒屏障件”**之下，执行高度统一的设计模式。

## 2. Extension 全家族的“三层统一”沙盒架构

为了兼容这几十种不同的接口而不使内核代码混乱，我们将所有用户子程序的接入统一定义为“**解包-调用-检疫**”的标准三段式流水线（The Sandbox Adapter Pattern）。

### 2.1 第一层统一：解包与降维（Unpack & Flatten）
UFC 内部流转的永远是优雅的四型结构体（`Desc, State, Ctx, Algo`）。针对不同的用户子程序，各自的 `_Ext.f90` 适配器执行标准的解包动作：
*   **UMAT 适配器**：从 `Mat_State` 提取 `strain`, `stress`。
*   **UEL 适配器**：从 `Elem_Desc` 提取 `coords`，从 `Elem_State` 提取 `disp`。
*   **ULOAD 适配器**：从 `Load_Ctx` 提取 `time`, `coords`。

### 2.2 第二层统一：状态盲区（STATEV / PROPS）的统一内存池
无论用户写的是 UMAT 还是 UEL，只要他们需要历史依赖变量，架构均提供统一的内存供给：
*   内核在 `Init` 阶段提供统一的 `STATEV(N_SIZE)` 连续内存。
*   适配器将该数组切片传递给用户子程序，用户自行定义其物理含义。

### 2.3 第三层统一：全球通用的“检疫所”（NaN / Inf Quarantine）
这是最关键的统一设计。无论用户子程序返回的是刚度矩阵 $K$ (UEL)、应力增量 $\Delta \sigma$ (UMAT)，还是面载荷 $q$ (ULOAD)，在它们被重新“打包（Pack）”进 UFC 的四型结构体之前，**必须强制经过统一的检疫函数**。

```fortran
! 所有 Extension 家族强制共享的检疫函数 (属于第12件 Diagnostics)
IF (UFC_Contains_NaN_Or_Inf(user_output_array)) THEN
    CALL UFC_Throw_Error(ERR_USER_SUBROUTINE_NAN, "Detected NaN in User Subroutine Output!")
    ! 立即拦截冒泡，绝对禁止污染 UFC 全局矩阵
END IF
```

## 3. 标准化伪代码骨架 (以 UEL 为例)

通过统一的适配器模式，我们即使接入 54 种 ABAQUS 接口，UFC 的核心（`_Core`）也无需改动一行代码：

```fortran
! UFC L4_PH 核心只需调用我们的沙盒屏障 (Extension件)
SUBROUTINE PH_Elem_USER_Ext(desc, state, algo, ctx, args)
    
    ! 1. [统一解包]: 将 UFC 的结构体转换为 ABAQUS UEL 要求的扁平参数
    coords_flat = desc%coords
    u_flat      = state%disp
    
    ! 2. [统一调用]: 呼叫用户编译的 UEL 黑盒
    CALL UEL(K_MAT, RHS, u_flat, coords_flat, PROPS, STATEV, ...)
    
    ! 3. [统一检疫]: 检查用户算出的刚度和残差是否包含 NaN/Inf
    IF (Check_NaN(K_MAT) .OR. Check_NaN(RHS)) THEN
        CALL Throw_Error(ERR_UEL_NAN)
        RETURN
    END IF
    
    ! 4. [统一打包]: 安全地将其装配回 UFC 的 Ctx 结构体
    ctx%local_stiffness = K_MAT
    ctx%local_residual  = RHS
    
END SUBROUTINE
```

## 4. 结论：插件化生态体系
通过这种**“接口因物理而异，架构因沙盒而同”**的设计，UFC 将 50 多种散乱的用户子程序转化为了“标准的插件体系”。未来我们要支持一种新的用户接口（比如 VUMAT），只需编写一个新的 `_Ext_VUMAT.f90` 适配器即可，内核的扩展性将趋于无限大。