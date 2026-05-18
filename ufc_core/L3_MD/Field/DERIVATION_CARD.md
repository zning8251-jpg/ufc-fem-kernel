# Field 域推演卡

## A. CONTRACT 输入

Field 的合同输入来自三条边界：

- `L3_MD` 是 Field 定义真源。
- `L4_PH` 负责温度、孔压、浓度计算与通用场操作。
- `L5_RT` 只消费 Field 结果，不复制 Field Desc。

## B. 意图归纳

Field 域必须回答三类问题：

1. 模型中有哪些场变量，初值是什么，以何种分布作用于哪些节点/单元/IP/集合。
2. L4 计算场变量时需要哪些物理参数、时间积分参数和 IO bundle。
3. L5 哪些调度/输出模块读取 Field 结果。

## C. 四型裁剪

| 层级 | Desc | State | Algo | Ctx |
|---|---|---|---|---|
| L3 | `MD_Field_Desc`, `MD_FieldEntry`, `MD_FieldRegionRef`, `MD_FieldInitCond` | `MD_Field_State`, `MD_FieldMgr_Type` | 不设 | `MD_Field_Ctx` |
| L4 | `PH_Field_Desc`, field-specific Desc | `PH_Field_State` | `PH_Field_Algo`, field-specific Algo | `PH_Field_Ctx` |
| L5 | 不设 Field 真源 | 消费 Assembly/Solver/Output 状态 | 调度算法归各自域 | 调度上下文归各自域 |

## D. 算法锚定

| 功能 | 模块 | 五要素步骤 |
|---|---|---|
| L3 Field 注册 | `MD_Field_Mgr` | Validate capacity -> assign slot -> fill semantic entry -> mark valid -> return status |
| L3 初始条件设置 | `MD_Field_Mgr` | Locate field -> copy `MD_FieldInitCond` -> sync legacy scalar alias -> return status |
| L3 Field 查询 | `MD_Field_Mgr` | Scan registry -> match id/name -> copy entry -> return status |
| Generic interpolation | `PH_Field_Ops` | Load shape values -> accumulate nodal/IP values -> store ctx -> status |
| Gradient/invariants | `PH_Field_Ops` | Load field/stress -> compute gradient or invariants -> store ctx -> status |
| Temperature | `PH_Field_ComputeTemp` | Check input -> allocate output -> assemble/advance template -> output temperature/flux |
| Pore pressure | `PH_Field_ComputePore` | Check input -> allocate output -> Darcy/storativity template -> output pressure/velocity |
| Concentration | `PH_Field_ComputeConc` | Check input -> allocate output -> diffusion/reaction template -> output concentration/flux |
| Shape support | `PH_Field_ShapeFunc` | Evaluate shape functions -> compute Jacobian/gradient -> return support Arg |
| Multiphysics coupling | `PH_Field_Cpl` | Read Field gradient/state contribution -> add element-level coupling terms |

## E. 过程绑定

| 过程 | 当前载体 | 结果 |
|---|---|---|
| `MD_Field_Domain_Init` / `Finalize` | `MD_Field_Mgr.f90` | 从旧 `MD_Field_Core` 合并 |
| `MD_Field_Define` / `Set_Initial` | `MD_Field_Mgr.f90` | 从旧 `MD_Field_Core` 合并 |
| `MD_Field_Set_InitCond` | `MD_Field_Mgr.f90` | Phase B 新增完整初始条件绑定 |
| `MD_Field_Get_By_ID` / `Get_By_Name` / `Get_Count` | `MD_Field_Mgr.f90` | 从旧 `MD_Field_Core` 合并 |
| `PH_Field_Interpolate_To_IP` / `Extrapolate_To_Nodes` / `Average_At_Nodes` | `PH_Field_Ops.f90` | 保留为 Generic Ops |
| `PH_Field_Compute_Temperature_*` | `PH_Field_ComputeTemp.f90` | 依赖 `PH_Temperature_*` TYPE |
| `PH_Field_Compute_PorePressure_*` | `PH_Field_ComputePore.f90` | 依赖 `PH_PorePressure_*` TYPE |
| `PH_Field_Compute_Concentration_*` | `PH_Field_ComputeConc.f90` | 依赖 `PH_Concentration_*` TYPE |
| `PH_Field_GetShapeFunctions` / `PH_Field_GetShapeFunctionGradient` | `PH_Field_ShapeFunc.f90` | 形函数支持，不再使用 `_Brg` |
| `PH_*_Contrib` | `PH_Field_Cpl.f90` | 多物理耦合贡献，不缩写为 `MPC` |
