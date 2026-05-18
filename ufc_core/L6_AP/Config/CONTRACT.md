## Config 域级合同卡（L6_AP）

- **层级**：L6_AP
- **域名**：Config / 配置管理
- **缩写**：AP_Config (`AP_Config_*`)
- **职责**：提供配置文件解析、参数验证、默认值管理；支持 YAML/JSON/XML格式与命令行参数覆盖。
- **四型配置**：
  - **Desc**：配置项 TYPE、参数表结构、验证规则。
  - **State**：当前配置状态、已加载文件列表。
  - **Ctx**：无。
  - **Algo**：递归解析、类型转换、约束检查。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Parse | Load_YAML, Load_JSON, Load_XML | 多格式解析 |
| Query | Get_Int, Get_Real, Get_String, Get_Bool | 类型化查询 |
| Validate | Validate_Schema, Check_Range | 参数验证 |
| Override | Apply_CLI_Override, Set_Runtime | 运行时覆盖 |

- **依赖**：IF_IO（文件读写）、IF_Error（错误处理）。
- **热路径**：**否** — 配置仅在初始化阶段加载。
- **实现锚点**：
  - `AP_Config_Types.f90` — 配置 TYPE 定义
    ```fortran
    TYPE :: ConfigEntry
      CHARACTER(:), ALLOCATABLE :: key
      INTEGER(i4) :: value_type  ! 1=INT, 2=REAL, 3=STRING, 4=BOOL
      CHARACTER(:), ALLOCATABLE :: value_str
      INTEGER(i8) :: value_int
      REAL(wp) :: value_real
      LOGICAL :: value_bool
    END TYPE ConfigEntry
    
    TYPE :: ConfigManager
      TYPE(ConfigEntry), ALLOCATABLE :: entries(:)
      INTEGER(i4) :: count = 0_i4
      CHARACTER(:), ALLOCATABLE :: config_file_path
      LOGICAL :: is_loaded = .FALSE.
    END TYPE ConfigManager
    ```
  - `AP_Config_Parse.f90` — 配置解析
    ```fortran
    SUBROUTINE Load_YAML(config, file_path, iostat)
      TYPE(ConfigManager), INTENT(INOUT) :: config
      CHARACTER(len=*), INTENT(IN) :: file_path
      INTEGER(i4), INTENT(OUT) :: iostat
      
      ! 伪代码：
      ! 1. 打开文件，逐行读取
      ! 2. 识别 key: value 模式
      ! 3. 根据 value 格式推断类型
      ! 4. 存入 entries 数组
      
      OPEN(unit=10, file=file_path, status='old', iostat=iostat)
      IF (iostat /= 0) RETURN
      
      DO WHILE (.TRUE.)
        READ(10, '(A)', iostat=iostat) line
        IF (iostat /= 0) EXIT
        
        ! 跳过注释和空行
        IF (line(1:1) == '#' .OR. TRIM(line) == '') CYCLE
        
        ! 解析 key: value
        colon_pos = INDEX(line, ':')
        IF (colon_pos > 0) THEN
          key = TRIM(line(1:colon_pos-1))
          value = TRIM(line(colon_pos+1:))
          
          ! 类型推断
          CALL Infer_Type_And_Store(config, key, value)
        END IF
      END DO
      
      CLOSE(10)
      config%is_loaded = .TRUE.
    END SUBROUTINE Load_YAML
    
    FUNCTION Get_Real(config, key, default) RESULT(value)
      TYPE(ConfigManager), INTENT(IN) :: config
      CHARACTER(len=*), INTENT(IN) :: key
      REAL(wp), INTENT(IN), OPTIONAL :: default
      REAL(wp) :: value
      
      ! 伪代码：查找 key 并转换为 REAL
      ! idx = find_entry(config, key)
      ! IF (idx > 0) THEN
      !   SELECT CASE (config%entries(idx)%value_type)
      !     CASE (1); value = REAL(config%entries(idx)%value_int, wp)
      !     CASE (2); value = config%entries(idx)%value_real
      !     CASE (3); READ(config%entries(idx)%value_str, *) value
      !   END SELECT
      ! ELSE IF (PRESENT(default)) THEN
      !   value = default
      ! ELSE
      !   CALL Error_Throw("Key not found: " // key)
      ! END IF
      
      idx = find_entry(config, key)
      IF (idx > 0) THEN
        value = config%entries(idx)%value_real
      ELSE IF (PRESENT(default)) THEN
        value = default
      ELSE
        value = 0.0_wp  ! 或抛出错误
      END IF
    END FUNCTION Get_Real
    ```
  - `AP_Config_Validate.f90` — 参数验证
    ```fortran
    SUBROUTINE Validate_Range(config, key, min_val, max_val)
      ! 伪代码：检查数值是否在范围内
      ! val = Get_Real(config, key)
      ! IF (val < min_val .OR. val > max_val) THEN
      !   CALL Error_Throw(key // " out of range [" // &
      !                    TRIM(str(min_val)) // ", " // &
      !                    TRIM(str(max_val)) // "]")
      ! END IF
    END SUBROUTINE Validate_Range
    ```

---


### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L6_CONFIG_xxx`（60200–60299） |
| 严重级 | Warning / Error（配置缺失为 Warning，解析失败为 Error） |
| 传播规则 | 解析/验证错误附加 Config 上下文后传播至调用方（Job/Solver） |
| 恢复策略 | 缺失键使用默认值 + Warning；类型不匹配或范围越界返回 Error |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L6_AP/Job | T(合同) | Job 域正式消费 Config 提供的作业配置参数 |
| 2 | L6_AP/Solver | T(合同) | Solver 域正式消费 Config 提供的求解器选项 |
| 3 | L5_RT/StepDriver | B(桥接) | 通过 config bridge 向 StepDriver 传递步控制参数 |
| 4 | L1_IF | U(USE) | Fortran USE 基础设施模块（IF_Prec_Core, IF_IO, IF_Error） |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 配置键名唯一性 | 硬约束 | 加载时断言检查 | CI |
| 类型化查询返回正确类型 | 硬约束 | 单元测试 | CI |
| YAML/JSON/XML 格式解析通过标准测试集 | 硬约束 | 集成测试 | PR 合入 |
| CLI 覆盖优先级高于文件配置 | 软约束 | 集成测试 | Nightly |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc | ConfigEntry | 配置项 TYPE、参数表结构 |
| 2 | State | ConfigManager | 已加载状态、文件路径、条目计数 |
| 3 | Algo | Parse/Validate | 递归解析、类型转换、约束检查 |
| 4 | Ctx | 无 | Config 无运行时上下文 |
| 5 | Arg (SIO) | 无 | 初始化阶段，不需要 *_Arg |
| 6 | Proc | AP_Config_Parse/Validate.f90 | 解析与验证过程 |
| 7 | Test | Config 单元测试 | 多格式解析 + 查询正确性 |
| 8 | CONTRACT | 本文件 | 域级合同卡 |
| 9 | Config | 自身 | 配置管理即为本域职责 |
| 10 | Error | ERR_L6_CONFIG_xxx | 60200–60299 |
| 11 | Domain | AP_Config 域 | L6_AP/Config/ |
| 12 | Registry | 无 | 不注册为服务 |
| 13 | Doc | 本合同 + 代码注释 | 配置格式说明 |

---

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 配置规范定义→参数约束→求解器/步控制参数映射 |
| **逻辑链** | 文件/CLI 输入→Config 解析→Job/Solver/StepDriver 消费 |
| **计算链** | 无直接计算；配置值影响 L5 求解器参数选择 |
| **数据链** | ConfigEntry 生命周期：Load→Query→Override→Finalize |

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
| `AP_Cfg.f90` | `AP_Cfg` | `AP_Config_State`, `AP_Config_Ctrl`, `AP_Config_LoadConfig_Arg`, `AP_Config_SetResourceLimit_Arg`, `AP_Config_RegisterModelConfig_Arg`, `AP_Config_GetSummary_Arg`, `AP_Config_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `LoadConfig` (TBP,PRV,—); `SetResourceLimit` (TBP,PRV,—); `RegisterModelConfig` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `AP_Config_Domain_Finalize` (SUB,PRV,Finalize); `AP_Config_Domain_Init` (SUB,PRV,Init); `AP_Config_Domain_LoadConfig` (SUB,PRV,Parse); `AP_Config_LoadConfig_Impl` (SUB,PRV,Parse); `AP_Config_Domain_SetResourceLimit` (SUB,PRV,Mutate); `AP_Config_SetResourceLimit_Impl` (SUB,PRV,Mutate); `AP_Config_Domain_RegisterModelConfig` (SUB,PRV,—); `AP_Config_RegisterModelConfig_Impl` (SUB,PRV,—); `AP_Config_Domain_GetSummary` (SUB,PRV,Query); `AP_Config_GetSummary_Impl` (SUB,PRV,Query) |
| `AP_Cfg_Domain.f90` | `AP_CfgDomain` | `AP_Config_State`, `AP_Config_Ctrl`, `AP_Config_LoadConfig_Arg`, `AP_Config_SetResourceLimit_Arg`, `AP_Config_RegisterModelConfig_Arg`, `AP_Config_GetSummary_Arg`, `AP_Config_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `LoadConfig` (TBP,PRV,—); `SetResourceLimit` (TBP,PRV,—); `RegisterModelConfig` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `AP_Config_Domain_Finalize` (SUB,PRV,Finalize); `AP_Config_Domain_Init` (SUB,PRV,Init); `AP_Config_Domain_LoadConfig` (SUB,PRV,Parse); `AP_Config_LoadConfig_Impl` (SUB,PRV,Parse); `AP_Config_Domain_SetResourceLimit` (SUB,PRV,Mutate); `AP_Config_SetResourceLimit_Impl` (SUB,PRV,Mutate); `AP_Config_Domain_RegisterModelConfig` (SUB,PRV,—); `AP_Config_RegisterModelConfig_Impl` (SUB,PRV,—); `AP_Config_Domain_GetSummary` (SUB,PRV,Query); `AP_Config_GetSummary_Impl` (SUB,PRV,Query) |
