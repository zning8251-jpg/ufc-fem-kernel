## Registry 域级合同卡（L6_AP）

- **层级**：L6_AP
- **域名**：Registry / 应用层注册表
- **缩写**：AP_Registry (`AP_Registry_*`)
- **职责**：提供应用级服务注册、插件管理、扩展点发现；支持动态加载求解器模块与后处理插件。
- **四型配置**：
  - **Desc**：服务描述符、插件句柄、扩展点表。
  - **State**：已加载插件列表、服务实例缓存。
  - **Ctx**：无。
  - **Algo**：动态库加载（dlopen/LoadLibrary）、符号查找。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Service | Register_Service, Get_Service | 服务注册与获取 |
| Plugin | Plugin_Load, Plugin_Unload, Plugin_List | 插件管理 |
| Extension | Find_Extension, Invoke_Extension | 扩展点调用 |
| Factory | Create_Object, Destroy_Object | 对象工厂 |

- **依赖**：IF_Registry（基础注册表）、IF_Error（错误处理）。
- **热路径**：**否** — 插件加载在初始化阶段。
- **实现锚点**：
  - `AP_Registry_Types.f90` — 应用注册表 TYPE
    ```fortran
    TYPE :: ServiceDescriptor
      CHARACTER(:), ALLOCATABLE :: service_name
      CHARACTER(:), ALLOCATABLE :: interface_id
      INTEGER(i4) :: version_major
      INTEGER(i4) :: version_minor
      PROCEDURE(Service_Init), NOPASS, POINTER :: init_func
      PROCEDURE(Service_Run), NOPASS, POINTER :: run_func
    END TYPE ServiceDescriptor
    
    TYPE :: PluginHandle
      CHARACTER(:), ALLOCATABLE :: plugin_name
      CHARACTER(:), ALLOCATABLE :: plugin_path
      TYPE(C_PTR) :: lib_handle = C_NULL_PTR  ! dlopen/LoadLibrary 返回
      LOGICAL :: is_loaded = .FALSE.
    END TYPE PluginHandle
    
    TYPE :: ApplicationRegistry
      TYPE(ServiceDescriptor), ALLOCATABLE :: services(:)
      TYPE(PluginHandle), ALLOCATABLE :: plugins(:)
      INTEGER(i4) :: num_services = 0_i4
      INTEGER(i4) :: num_plugins = 0_i4
    END TYPE ApplicationRegistry
    ```
  - `AP_Registry_Plugin.f90` — 插件管理
    ```fortran
    FUNCTION Plugin_Load(reg, plugin_path) RESULT(plugin_id)
      TYPE(ApplicationRegistry), INTENT(INOUT) :: reg
      CHARACTER(len=*), INTENT(IN) :: plugin_path
      INTEGER(i4) :: plugin_id
      
      ! 伪代码：
      ! 1. 使用 dlopen (Linux) 或 LoadLibrary (Windows) 加载动态库
      ! 2. 查找导出函数：plugin_init, plugin_query, plugin_shutdown
      ! 3. 注册到 plugins 数组
      ! 4. 调用 plugin_init 初始化
      
#ifdef _WIN32
      lib_handle = c_dlopen(TRIM(plugin_path)//C_NULL_CHAR, RTLD_LAZY)
#else
      lib_handle = c_dlopen(TRIM(plugin_path)//C_NULL_CHAR, RTLD_NOW)
#endif
      
      IF (.NOT. C_ASSOCIATED(lib_handle)) THEN
        CALL Error_Throw("Failed to load plugin: " // TRIM(plugin_path))
        plugin_id = -1
        RETURN
      END IF
      
      ! 查找导出符号
      init_sym = c_dlsym(lib_handle, 'plugin_init'//C_NULL_CHAR)
      query_sym = c_dlsym(lib_handle, 'plugin_query'//C_NULL_CHAR)
      
      IF (.NOT. C_ASSOCIATED(init_sym) .OR. &
          .NOT. C_ASSOCIATED(query_sym)) THEN
        CALL Error_Throw("Plugin missing required symbols")
        plugin_id = -1
        RETURN
      END IF
      
      ! 扩容并添加
      reg%num_plugins = reg%num_plugins + 1
      idx = reg%num_plugins
      reg%plugins(idx)%lib_handle = lib_handle
      reg%plugins(idx)%plugin_path = plugin_path
      reg%plugins(idx)%is_loaded = .TRUE.
      
      ! 调用初始化
      CALL c_f_procpointer(init_sym, init_ptr)
      status = init_ptr()
      
      plugin_id = idx
    END FUNCTION Plugin_Load
    
    SUBROUTINE Plugin_Unload(reg, plugin_id)
      ! 伪代码：
      ! 1. 调用 plugin_shutdown
      ! 2. dlclose/FreeLibrary
      ! 3. 标记为未加载
      
      IF (plugin_id < 1 .OR. plugin_id > reg%num_plugins) RETURN
      
      plugin => reg%plugins(plugin_id)
      IF (plugin%is_loaded) THEN
        ! 查找并调用 shutdown
        shutdown_sym = c_dlsym(plugin%lib_handle, 'plugin_shutdown')
        IF (C_ASSOCIATED(shutdown_sym)) THEN
          CALL c_f_procpointer(shutdown_sym, shutdown_ptr)
          CALL shutdown_ptr()
        END IF
        
#ifdef _WIN32
        CALL c_dlclose(plugin%lib_handle)
#else
        CALL c_dlclose(plugin%lib_handle)
#endif
        
        plugin%is_loaded = .FALSE.
        plugin%lib_handle = C_NULL_PTR
      END IF
    END SUBROUTINE Plugin_Unload
    ```
  - `AP_Registry_Service.f90` — 服务注册
  - `AP_Registry_Factory.f90` — 对象工厂

---


### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L6_REGISTRY_xxx`（60600–60699） |
| 严重级 | Warning / Error（重复注册为 Warning，符号查找失败为 Error） |
| 传播规则 | 注册/加载错误附加服务名/插件路径上下文后传播至调用方 |
| 恢复策略 | 插件加载失败跳过 + Warning；必需服务缺失返回 Error |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L6_AP/Job | S(消费) | Job 域消费 Registry 提供的服务实例 |
| 2 | L6_AP/Config | S(消费) | 消费 Config 提供的插件路径与加载选项 |
| 3 | L3_MD/KeyWord | T(合同) | 关键字注册表正式合同（KW registry） |
| 4 | L1_IF | U(USE) | Fortran USE 基础设施模块（IF_Prec_Core, IF_Error, IF_Registry） |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 服务名全局唯一 | 硬约束 | 注册时断言检查 | CI |
| 插件导出符号集合完整（init/query/shutdown） | 硬约束 | 加载时检查 + 单元测试 | CI |
| 服务版本兼容性（major.minor） | 硬约束 | 注册时版本比对 | PR 合入 |
| 动态库平台兼容（Linux/Windows） | 软约束 | 跨平台 CI | Nightly |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc | ServiceDescriptor / PluginHandle | 服务与插件描述 |
| 2 | State | ApplicationRegistry | 已注册服务/已加载插件列表 |
| 3 | Algo | dlopen/LoadLibrary + 符号查找 | 动态库加载与符号解析 |
| 4 | Ctx | 无 | 初始化阶段全局单例 |
| 5 | Arg (SIO) | 无 | 注册阶段不需要 *_Arg |
| 6 | Proc | AP_Registry_Plugin/Service/Factory.f90 | 注册管理过程模块 |
| 7 | Test | Registry 单元测试 | 注册/查找/卸载正确性 |
| 8 | CONTRACT | 本文件 | 域级合同卡 |
| 9 | Config | 无（消费 AP_Config） | 插件路径来自 Config 域 |
| 10 | Error | ERR_L6_REGISTRY_xxx | 60600–60699 |
| 11 | Domain | AP_Registry 域 | L6_AP/Registry/ |
| 12 | Registry | 自身 | 注册表管理即为本域职责 |
| 13 | Doc | 本合同 + 插件规范 | 插件接口与扩展点说明 |

---

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 服务定位器模式→插件架构→扩展点发现与调用 |
| **逻辑链** | Plugin_Load→符号查找→init 调用→Register_Service→Get_Service 消费 |
| **计算链** | 无直接计算；Registry 仅管理服务/插件生命周期 |
| **数据链** | PluginHandle 生命周期：Load→Init→Query→Shutdown→Unload |

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**版本**：v1.0  
**最后更新**：2026-03-23  
**状态**：✅ 已补全


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `AP_Reg_Domain.f90` | `AP_RegDomain` | `AP_Registry_ModelEntry`, `AP_Registry_State`, `AP_Registry_Ctrl`, `AP_Registry_RegisterModel_Arg`, `AP_Registry_CheckDegradation_Arg`, `AP_Registry_GetSummary_Arg`, `AP_Registry_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `RegisterModel` (TBP,PRV,—); `CheckDegradation` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `AP_Registry_Domain_Finalize` (SUB,PRV,Finalize); `AP_Registry_Domain_Init` (SUB,PRV,Init); `AP_Registry_Domain_RegisterModel` (SUB,PRV,—); `AP_Registry_RegisterModel_Impl` (SUB,PRV,—); `AP_Registry_Domain_CheckDegradation` (SUB,PRV,Validate); `AP_Registry_CheckDegradation_Impl` (SUB,PRV,Validate); `AP_Registry_Domain_GetSummary` (SUB,PRV,Query); `AP_Registry_GetSummary_Impl` (SUB,PRV,Query) |
