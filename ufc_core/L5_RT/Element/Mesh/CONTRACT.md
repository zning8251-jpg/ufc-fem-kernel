## Mesh 域级合同卡 (L5_RT)

- **层级**: L5_RT  
- **域名**: Mesh / 运行时网格操作辅助核  
- **缩写**: Mesh (`RT_Mesh_Sys`)  
- **职责**: 实现**运行时**网格操作辅助：节点/单元索引重映射、局部细化/粗化、网格光顺、与 Assembly 协调 DoF 映射。**不对应** HYPLAS MESH(网格真相源在 L3)。  
- **非职责**: 不存储网格拓扑真相源 (L3 `MD_Mesh_*`);不定义初始网格 (L6 AP/Input);不包含仅桥接层使用的辅助类型。  

- **与 L3/L4 关系**:  
  - L3 `MD_Mesh_*`: 网格真相源 → L5 `RT_Mesh_Sys` 仅操作运行时副本  
  - L4 `PH_Elem_*`: 形函数/Jacobian → L5 网格操作调用  
  - **热路径零 L3**: 网格操作仅在初始化/自适应阶段，不直读 L3。  

- **四型配置**（典型）：  
  - **Desc**: 网格副本引用、细化标记列表、光顺参数。  
  - **State**: 当前网格质量指标、已细化单元计数、DoF 变化量。  
  - **Ctx**: 网格操作上下文、内存池、并行分区信息。  
  - **Algo**: 细化策略 (h/p/r 方法)、光顺算法 (Laplacian/optimization)。  

- **核心接口**（按功能集）：  

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| System | `RT_Mesh_Sys` | 网格系统主接口 (初始化/清理/验证) |

*注：Phys_ContmMesh 已移除（仅 L3 桥接层使用，无 L5 调用链路）*

- **依赖**: L1 `IF_*`、L3 `MD_Mesh_*` (只读引用)、L4 `PH_Elem_*` (形函数)。  
- **下游**: Assembly (DoF 映射更新)、Output (变形网格输出)。  
- **热路径**: **否** — 仅在自适应/初始化阶段调用。  

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

*维护注记：新增网格操作算法时在「核心接口」补一行。*


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `RT_Mesh_Impl.f90` | `RT_MeshImpl` | — | `RT_Mesh_Impl_Init` (SUB,PRV,Init); `RT_Mesh_Impl_Clean` (SUB,PRV,—); `RT_Mesh_Impl_Numbering` (SUB,PRV,—); `RT_Mesh_Impl_UpdateCoords` (SUB,PRV,Compute); `RT_Mesh_Impl_GetState` (SUB,PRV,Query); `RT_Mesh_Impl_Assembly` (SUB,PRV,—); `InitializeCoordsFromMD` (SUB,PRV,—); `FindNodeIndex` (FN,PRV,—) |
| `RT_Mesh_Proc.f90` | `RT_MeshProc` | `RT_Mesh_Init_In`, `RT_Mesh_Init_Out`, `RT_Mesh_Clean_In`, `RT_Mesh_Clean_Out`, `RT_Mesh_Numbering_In`, `RT_Mesh_Numbering_Out`, `RT_Mesh_UpdateCoords_In`, `RT_Mesh_UpdateCoords_Out`, `RT_Mesh_GetState_In`, `RT_Mesh_GetState_Out`, `RT_Mesh_Assembly_In`, `RT_Mesh_Assembly_Out` | `RT_Mesh_Init` (SUB,PUB,Init); `RT_Mesh_Clean` (SUB,PUB,—); `RT_Mesh_Numbering` (SUB,PUB,—); `RT_Mesh_UpdateCoords` (SUB,PUB,Compute); `RT_Mesh_GetState` (SUB,PUB,Query); `RT_Mesh_Assembly` (SUB,PUB,—) |
| `RT_Mesh_Sys.f90` | `RT_MeshSys` | `RT_Mesh_Cfg` | `Init` (TBP,PRV,—); `Valid` (TBP,PRV,—); `RT_Mesh_MgrInit` (SUB,PRV,—); `RT_Mesh_MgrClean` (SUB,PRV,—); `RT_Mesh_MgrReg` (SUB,PRV,—); `RT_Mesh_MgrGetStat` (SUB,PRV,—); `RT_Mesh_CfgInit` (SUB,PRV,—); `RT_Mesh_CfgValid` (FN,PRV,—); `RT_Mesh_SysInitType` (SUB,PRV,—); `RT_Mesh_SysCleanType` (SUB,PRV,—); `RT_Mesh_SysRegVarsType` (SUB,PRV,—); `RT_Mesh_SysInitElemsType` (SUB,PRV,—); `RT_Mesh_SysInitMatsType` (SUB,PRV,—); `RT_Mesh_SysInitSectsType` (SUB,PRV,—); `RT_Mesh_SysCompElemType` (SUB,PRV,—); `RT_Mesh_SysGetElemCntType` (FN,PRV,—); `RT_Mesh_SysGetNodeCntType` (FN,PRV,—); `RT_Mesh_SysGetBrgType` (FN,PRV,—); `RT_Mesh_SysGetStatType` (FN,PRV,—); `RT_MeshSys_Init` (SUB,PRV,Init); `RT_MeshSys_Clean` (SUB,PRV,—); `RT_MeshSys_RegModel` (SUB,PRV,—); `RT_Mesh_SysGetStat` (SUB,PUB,—); `RT_MeshSys_Valid` (FN,PRV,Validate); `RT_Mesh_Init` (SUB,PUB,Init); `RT_Mesh_Clean` (SUB,PUB,—); `RT_Mesh_RegVars` (SUB,PUB,—); `RT_Mesh_InitElems` (SUB,PUB,Init); `RT_Mesh_InitMats` (SUB,PUB,Init); `RT_Mesh_InitSects` (SUB,PUB,Init); `RT_Mesh_CompElem` (SUB,PUB,—); `RT_Mesh_GetElemCnt` (FN,PUB,Query); `RT_Mesh_GetNodeCnt` (FN,PUB,Query); `RT_Mesh_GetBrg` (FN,PUB,Query) |
| `RT_Mesh_Def.f90` | `RT_Mesh_Def` | `RT_Mesh_Base_Desc`, `RT_Mesh_Base_State`, `RT_Mesh_Base_Algo`, `RT_Mesh_Base_Ctx`, `RT_Mesh_NodeState`, `RT_Mesh_ElementState`, `RT_Mesh_NumberingAlgo`, `RT_Mesh_AssemblyCtx` | — |
