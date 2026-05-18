## Registry 域级合同卡（L1_IF）

- **层级**：L1_IF
- **域名**：Registry / 注册表与对象管理
- **缩写**：IF_Registry (`IF_Registry_*`)
- **职责**：提供对象注册、查找、生命周期管理机制；支持基于名称/ID 的对象索引与依赖注入。
- **四型配置**：
  - **Desc**：注册表项 TYPE、对象句柄、索引结构（哈希表/平衡树）。
  - **State**：当前注册对象计数、索引缓存。
  - **Ctx**：无。
  - **Algo**：哈希函数、二分查找、引用计数。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Register | Register_Object, Register_Type | 对象/类型注册 |
| Lookup | Lookup_By_Name, Lookup_By_ID | 名称/ID 查询 |
| Lifecycle | Create_Instance, Destroy_Instance | 实例生命周期 |
| Iterate | Iterate_All, Filter_By_Type | 遍历与过滤 |

- **依赖**：IF_Error（错误处理）、IF_Precision（数据类型）。
- **热路径**：**否** — 注册表操作主要在初始化阶段。
- **实现锚点**：
  - `IF_Registry_Types.f90` — 注册表 TYPE 定义
    ```fortran
    TYPE :: RegistryEntry
      CHARACTER(:), ALLOCATABLE :: name     ! 对象名称
      INTEGER(i4) :: obj_id                 ! 唯一 ID
      INTEGER(i4) :: type_id                ! 类型 ID
      INTEGER(i4) :: ref_count = 0_i4       ! 引用计数
      CLASS(*), ALLOCATABLE :: object       ! 多态对象
    END TYPE RegistryEntry
    
    TYPE :: ObjectRegistry
      TYPE(RegistryEntry), ALLOCATABLE :: entries(:)
      INTEGER(i4) :: count = 0_i4
      INTEGER(i4) :: capacity = 100_i4
      TYPE(HashTable), POINTER :: hash_index => NULL()  ! 名称->ID 映射
    END TYPE ObjectRegistry
    ```
  - `IF_Registry_Core.f90` — 核心操作
    ```fortran
    SUBROUTINE Register_Object(reg, name, obj, obj_id)
      TYPE(ObjectRegistry), INTENT(INOUT) :: reg
      CHARACTER(len=*), INTENT(IN) :: name
      CLASS(*), INTENT(IN) :: obj
      INTEGER(i4), INTENT(OUT) :: obj_id
      
      ! 伪代码：
      ! 1. 检查名称是否已存在（哈希查找 O(1)）
      ! 2. 若容量不足，扩容数组（倍增策略）
      ! 3. 插入新条目
      ! 4. 更新哈希索引
      
      IF (hash_has_key(reg%hash_index, name)) THEN
        CALL Error_Throw("Object already exists: " // name)
        RETURN
      END IF
      
      IF (reg%count >= reg%capacity) THEN
        CALL Registry_Expand(reg)  ! 扩容：capacity = capacity * 2
      END IF
      
      reg%count = reg%count + 1
      idx = reg%count
      
      ALLOCATE(reg%entries(idx)%object, SOURCE=obj)
      reg%entries(idx)%name = name
      reg%entries(idx)%obj_id = generate_unique_id()
      reg%entries(idx)%ref_count = 1_i4
      
      CALL hash_insert(reg%hash_index, name, idx)
      obj_id = reg%entries(idx)%obj_id
    END SUBROUTINE Register_Object
    
    FUNCTION Lookup_By_Name(reg, name) RESULT(obj_ptr)
      TYPE(ObjectRegistry), INTENT(IN) :: reg
      CHARACTER(len=*), INTENT(IN) :: name
      CLASS(*), POINTER :: obj_ptr
      
      ! 伪代码：哈希查找 O(1)
      ! idx = hash_lookup(reg%hash_index, name)
      ! IF (idx > 0) obj_ptr => reg%entries(idx)%object
      
      idx = hash_lookup(reg%hash_index, name)
      IF (idx > 0) THEN
        reg%entries(idx)%ref_count = reg%entries(idx)%ref_count + 1
        obj_ptr => reg%entries(idx)%object
      ELSE
        NULLIFY(obj_ptr)
      END IF
    END FUNCTION Lookup_By_Name
    
    SUBROUTINE Destroy_Instance(reg, obj_id)
      TYPE(ObjectRegistry), INTENT(INOUT) :: reg
      INTEGER(i4), INTENT(IN) :: obj_id
      
      ! 伪代码：引用计数归零时释放
      ! DO i = 1, reg%count
      !   IF (reg%entries(i)%obj_id == obj_id) THEN
      !     reg%entries(i)%ref_count = reg%entries(i)%ref_count - 1
      !     IF (reg%entries(i)%ref_count <= 0) THEN
      !       DEALLOCATE(reg%entries(i)%object)
      !       CALL remove_entry(reg, i)
      !     END IF
      !     EXIT
      !   END IF
      ! END DO
    END SUBROUTINE Destroy_Instance
    ```
  - `IF_Registry_Hash.f90` — 哈希索引实现

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**版本**：v1.1  
**最后更新**：2026-04-17  
**状态**：✅ 已补全

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L1_REGISTRY_xxx` (10800–10899) |
| 严重级 | WARNING: 重复注册(覆盖); ERROR: 查找失败/容量耗尽; FATAL: 无 |
| 传播规则 | 经 `status` 参数返回；不自行 STOP |
| 恢复策略 | WARNING：日志 + 覆盖旧条目; ERROR：上报调用者 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L6_AP/Registry | T(合同) | 应用层注册组件到全局注册表 |
| R2 | L5_RT/* | S(消费) | 运行时层查询注册表 |
| R3 | L4_PH/* | S(消费) | 有限元组件层查询注册表 |
| R4 | L1_IF/Error | U(USE) | 错误码定义 |
| R5 | L1_IF/Base | U(USE) | 基础类型 |
| R6 | L1_IF/Precision | U(USE) | 数据精度 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 不得向上依赖 (L2–L6) | 硬 | Code Review | — |
| 对象名称须全局唯一 | 硬 | Harness | H-REG-01 |
| 注册操作须在初始化阶段完成 | 软 | Code Review | — |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | RegistryEntry / ObjectRegistry TYPE | 注册表结构描述 |
| 2 | State 定义 | 对象计数 / 索引缓存 | 运行时注册状态 |
| 3 | Algo 定义 | 哈希函数 / 二分查找 / 引用计数 | 索引算法 |
| 4 | Ctx 定义 | N/A | 无上下文 |
| 5 | Init/Finalize | Registry_Init / Registry_Finalize | 注册表生命周期 |
| 6 | Query | Lookup_By_Name / Lookup_By_ID | 名称/ID 查询 |
| 7 | Validate | 名称唯一性 / 引用计数校验 | 内嵌 |
| 8 | Populate | N/A | L1 无 Populate 链 |
| 9 | Bridge | N/A | 最底层无桥接 |
| 10 | WriteBack | N/A | 基础设施不回写 |
| 11 | Parse | N/A | 不涉及关键字解析 |
| 12 | Compute | N/A | 非计算域 |
| 13 | Error | status 参数返回 | 见错误处理 |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 无理论背景——对象注册与依赖注入基础设施 |
| 逻辑链 | Register → Lookup → Destroy 生命周期，哈希索引 O(1) 查找 |
| 计算链 | 注册操作在初始化阶段——非热路径 |
| 数据链 | RegistryEntry 链 + HashTable 索引，引用计数管理生命周期 |

---

## 补全记录 (v1.1 - 2026-04-17)

### 新增文件

| 文件 | 职责 | 行数 | 状态 |
|------|------|------|------|
| IF_Reg_Types.f90 | Registry域TYPE定义(组件/求解器/插件注册表) | 202 | ✅ 新增 |
| IF_Reg_State.f90 | 注册表状态管理/性能统计/健康监控 | 382 | ✅ 新增 |

### 新增TYPE定义

| TYPE名称 | 种类 | 职责 |
|----------|------|------|
| IF_Reg_Component_Desc | Desc | 组件注册表描述符 |
| IF_Reg_Solver_Desc | Desc | 求解器注册表描述符 |
| IF_Reg_Plugin_Desc | Desc | 插件注册表描述符 |
| IF_Reg_Registry_State | State | 注册表运行时状态 |

### 新增API接口 (IF_Reg_State.f90)

| 接口名称 | 功能 | 参数 |
|----------|------|------|
| IF_Reg_State_Init | 初始化注册表状态 | status |
| IF_Reg_State_GetRegistryStatus | 获取注册表完整状态 | state, status |
| IF_Reg_State_GetComponentCount | 获取组件数量 | comp_type, count, status |
| IF_Reg_State_GetSolverCount | 获取求解器数量 | solver_type, count, status |
| IF_Reg_State_GetPluginCount | 获取插件数量 | plugin_type, count, status |
| IF_Reg_State_GetCacheStats | 获取缓存统计 | n_queries, n_hits, n_misses, hit_rate, status |
| IF_Reg_State_CheckComponentHealth | 检查组件健康状态 | is_healthy, n_degraded, status |
| IF_Reg_State_ClearCache | 清空缓存 | status |
| IF_Reg_State_PrintSummary | 打印注册表摘要 | status |

**总计**: Registry域3个文件,927行代码


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_Reg.f90` | `IF_Reg` | `ModelEntry`, `AuditLogEntry`, `ModelRegistry` | `Governance_Init` (SUB,PUB,Init); `Governance_Finalize` (SUB,PUB,Finalize); `RegisterModel` (FN,PUB,—); `UnregisterModel` (SUB,PUB,—); `QueryModelRegistry` (FN,PUB,—); `IncrementModelVersion` (SUB,PUB,—); `RollbackModelVersion` (SUB,PUB,—); `GetModelHistory` (SUB,PUB,—); `CheckModelDegradation` (FN,PUB,—); `BenchmarkModel` (SUB,PUB,—); `AlertDegradation` (SUB,PUB,—); `ModelAuditLog` (SUB,PUB,—); `QueryAuditLog` (SUB,PUB,—); `ExportAuditReport` (SUB,PUB,—) |
| `IF_Reg_Ctx.f90` | `IF_Reg_Ctx` | — | `IF_Reg_State_Init` (SUB,PUB,Init); `IF_Reg_State_GetRegistryStatus` (SUB,PUB,Query); `IF_Reg_State_GetComponentCount` (SUB,PUB,Query); `IF_Reg_State_GetSolverCount` (SUB,PUB,Query); `IF_Reg_State_GetPluginCount` (SUB,PUB,Query); `IF_Reg_State_GetCacheStats` (SUB,PUB,Query); `IF_Reg_State_CheckComponentHealth` (SUB,PUB,Validate); `IF_Reg_State_ClearCache` (SUB,PUB,Mutate); `IF_Reg_State_PrintSummary` (SUB,PUB,IO) |
| `IF_Reg_Def.f90` | `IF_Reg_Def` | `IF_Reg_Component_Desc`, `IF_Reg_Solver_Desc`, `IF_Reg_Plugin_Desc`, `IF_Reg_Registry_State` | `IF_Reg_Types_Init` (SUB,PUB,Init) |
