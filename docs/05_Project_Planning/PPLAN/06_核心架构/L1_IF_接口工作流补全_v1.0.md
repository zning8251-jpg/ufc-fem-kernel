# L1_IF 接口工作流补全 v1.0

> **层级**: L1_IF (Infrastructure Layer — 基础设施层)
> **优先级**: ⭐⭐⭐ (P3 启动任务)
> **版本**: v1.0
> **创建日期**: 2026-04-04
> **阶段**: P3 接口工作流补全

---

## 一、L1_IF 层职责重定义

L1_IF 是 UFC 的**基础设施层**，为上层（L2~L6）提供**统一的系统接口、资源管理、错误处理、日志诊断**等基础服务。

### 核心职责
- **系统接口** (IF_Base)：Fortran 标准库、编译器特性、操作系统接口的统一封装
- **精度管理** (IF_Prec)：全局精度常量定义（wp, i4 等），确保跨层数值一致性
- **错误处理** (IF_Err_API)：统一的错误状态码、错误消息、异常传播机制
- **文件 I/O** (IF_IO)：二进制/文本文件读写、缓冲管理、路径处理
- **日志诊断** (IF_Log)：分级日志、性能计时、跟踪输出
- **内存管理** (IF_Memory)：动态分配管理、对象池、泄漏检测
- **系统监控** (IF_Monitor)：资源使用率、性能统计、健康检查

---

## 二、六个域级的接口规范

### 2.1 IF_Base — 系统接口与兼容性

**目标**：统一 Fortran 语言特性、编译器差异、操作系统接口

**关键接口**：
```fortran
!===============================================================================
! MODULE IF_Base — Fortran 标准库与系统接口的统一封装
!===============================================================================

MODULE IF_Base
  IMPLICIT NONE
  PRIVATE

  ! ===== PUBLIC 常量与参数 =====
  PUBLIC :: IF_BASE_VERSION
  PUBLIC :: IF_COMPILER_NAME, IF_OS_NAME, IF_ENDIAN
  PUBLIC :: IF_PATH_SEPARATOR, IF_MAX_PATH_LEN
  
  CHARACTER(len=32), PARAMETER :: IF_BASE_VERSION = "1.0"
  CHARACTER(len=32), PARAMETER :: IF_COMPILER_NAME = "gfortran"
  CHARACTER(len=32), PARAMETER :: IF_OS_NAME = "Windows/Linux/MacOS"
  CHARACTER(len=8), PARAMETER :: IF_ENDIAN = "LITTLE"  ! LITTLE or BIG
  CHARACTER(len=1), PARAMETER :: IF_PATH_SEPARATOR = "/"
  INTEGER, PARAMETER :: IF_MAX_PATH_LEN = 256

  ! ===== PUBLIC 子程序接口 =====
  PUBLIC :: IF_Init_System
  PUBLIC :: IF_Get_Timestamp
  PUBLIC :: IF_Get_Env_Var
  PUBLIC :: IF_Expand_Path
  PUBLIC :: IF_File_Exists
  PUBLIC :: IF_Create_Directory

CONTAINS

  ! 初始化系统接口（在程序启动时调用）
  SUBROUTINE IF_Init_System()
    ! 1. 检测编译器版本与配置
    ! 2. 验证 Fortran 特性支持（F2003/F2008）
    ! 3. 检测系统架构（32/64-bit, endianness）
    ! 4. 初始化操作系统接口
    PRINT *, "IF_Base initialized successfully"
  END SUBROUTINE IF_Init_System

  ! 获取当前时间戳（ISO 8601 格式）
  FUNCTION IF_Get_Timestamp() RESULT(timestamp)
    CHARACTER(len=23) :: timestamp  ! "2026-04-04T20:53:05.000"
    ! 使用 CALL DATE_AND_TIME(...) 构造 ISO 8601 格式
  END FUNCTION IF_Get_Timestamp

  ! 获取环境变量（跨平台）
  FUNCTION IF_Get_Env_Var(var_name) RESULT(var_value)
    CHARACTER(len=*), INTENT(IN) :: var_name
    CHARACTER(len=256) :: var_value
    CALL GET_ENVIRONMENT_VARIABLE(var_name, var_value)
  END FUNCTION IF_Get_Env_Var

  ! 展开文件路径中的环境变量
  SUBROUTINE IF_Expand_Path(input_path, output_path)
    CHARACTER(len=*), INTENT(IN) :: input_path
    CHARACTER(len=*), INTENT(OUT) :: output_path
    ! 示例: "/path/to/${HOME}/file.txt" → "/path/to/C:\Users\username/file.txt"
  END SUBROUTINE IF_Expand_Path

  ! 检查文件是否存在
  LOGICAL FUNCTION IF_File_Exists(file_path)
    CHARACTER(len=*), INTENT(IN) :: file_path
    INQUIRE(FILE=file_path, EXIST=IF_File_Exists)
  END FUNCTION IF_File_Exists

  ! 创建目录（递归）
  SUBROUTINE IF_Create_Directory(dir_path, status)
    CHARACTER(len=*), INTENT(IN) :: dir_path
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    ! 使用 EXECUTE_COMMAND_LINE('mkdir -p ...') 或平台特定调用
  END SUBROUTINE IF_Create_Directory

END MODULE IF_Base
```

---

### 2.2 IF_Prec — 精度管理与数值常量

**目标**：定义全局精度常量，保证数值一致性

**接口规范**：
```fortran
!===============================================================================
! MODULE IF_Prec — 精度常量与数值参数全局定义
!===============================================================================

MODULE IF_Prec
  IMPLICIT NONE
  PRIVATE

  ! ===== PUBLIC 精度参数 =====
  PUBLIC :: wp, i4, i8, c8
  
  ! 双精度浮点数 (REAL*8)
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)
  
  ! 32-bit 整数
  INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)
  
  ! 64-bit 整数
  INTEGER, PARAMETER :: i8 = SELECTED_INT_KIND(18)
  
  ! 复数双精度
  INTEGER, PARAMETER :: c8 = SELECTED_REAL_KIND(15, 307)

  ! ===== PUBLIC 数学常数 =====
  PUBLIC :: PI, E, EULER_GAMMA
  
  REAL(wp), PARAMETER :: PI = 3.1415926535897932384626433832795_wp
  REAL(wp), PARAMETER :: E = 2.7182818284590452353602874713527_wp
  REAL(wp), PARAMETER :: EULER_GAMMA = 0.5772156649015328606065120900824_wp

  ! ===== PUBLIC 数值阈值 =====
  PUBLIC :: EPSILON_WP, TINY_WP, HUGE_WP
  PUBLIC :: ZERO_TOL, UNIT_TOL, INFINITY
  
  REAL(wp), PARAMETER :: EPSILON_WP = EPSILON(1.0_wp)  ! ~2.2e-16
  REAL(wp), PARAMETER :: TINY_WP = TINY(1.0_wp)         ! ~2.2e-308
  REAL(wp), PARAMETER :: HUGE_WP = HUGE(1.0_wp)         ! ~1.8e+308
  
  REAL(wp), PARAMETER :: ZERO_TOL = 1.0e-14_wp    ! 零值容限
  REAL(wp), PARAMETER :: UNIT_TOL = 1.0e-12_wp    ! 单位容限
  REAL(wp), PARAMETER :: INFINITY = HUGE_WP * 0.1_wp

END MODULE IF_Prec
```

---

### 2.3 IF_Err_API — 错误处理与状态码

**目标**：统一的错误处理机制，支持链式错误传播

**接口规范**：
```fortran
!===============================================================================
! MODULE IF_Err_API — 错误状态码与异常处理
!===============================================================================

MODULE IF_Err_API
  USE IF_Prec, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  ! ===== PUBLIC 状态码常量 =====
  PUBLIC :: STATUS_OK, STATUS_ERROR, STATUS_WARNING
  PUBLIC :: STATUS_NOT_IMPLEMENTED, STATUS_INVALID_INPUT
  PUBLIC :: STATUS_ALLOCATION_FAILED, STATUS_IO_ERROR
  
  INTEGER(i4), PARAMETER :: STATUS_OK = 0_i4
  INTEGER(i4), PARAMETER :: STATUS_ERROR = -1_i4
  INTEGER(i4), PARAMETER :: STATUS_WARNING = 1_i4
  INTEGER(i4), PARAMETER :: STATUS_NOT_IMPLEMENTED = -100_i4
  INTEGER(i4), PARAMETER :: STATUS_INVALID_INPUT = -200_i4
  INTEGER(i4), PARAMETER :: STATUS_ALLOCATION_FAILED = -300_i4
  INTEGER(i4), PARAMETER :: STATUS_IO_ERROR = -400_i4

  ! ===== PUBLIC 错误类型定义 =====
  PUBLIC :: ErrorStatusType
  
  TYPE, PUBLIC :: ErrorStatusType
    INTEGER(i4) :: status_code = STATUS_OK
    CHARACTER(len=512) :: message = ""
    CHARACTER(len=256) :: source_file = ""
    INTEGER(i4) :: source_line = 0_i4
    TYPE(ErrorStatusType), POINTER :: nested_error => NULL()  ! 链式错误追踪
  END TYPE ErrorStatusType

  ! ===== PUBLIC 子程序接口 =====
  PUBLIC :: Init_Error_Status
  PUBLIC :: Set_Error
  PUBLIC :: Append_Error
  PUBLIC :: Print_Error_Chain
  PUBLIC :: Is_Error

CONTAINS

  ! 初始化错误状态
  SUBROUTINE Init_Error_Status(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    status%status_code = STATUS_OK
    status%message = ""
    status%source_file = ""
    status%source_line = 0_i4
    IF (ASSOCIATED(status%nested_error)) DEALLOCATE(status%nested_error)
  END SUBROUTINE Init_Error_Status

  ! 设置错误信息（包含文件与行号）
  SUBROUTINE Set_Error(status, code, message, file, line)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN) :: code
    CHARACTER(len=*), INTENT(IN) :: message
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: file
    INTEGER(i4), INTENT(IN), OPTIONAL :: line
    
    status%status_code = code
    status%message = TRIM(message)
    IF (PRESENT(file)) status%source_file = TRIM(file)
    IF (PRESENT(line)) status%source_line = line
  END SUBROUTINE Set_Error

  ! 追加嵌套错误（用于错误链传播）
  SUBROUTINE Append_Error(status, nested_status)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    TYPE(ErrorStatusType), INTENT(IN) :: nested_status
    
    IF (.NOT. ASSOCIATED(status%nested_error)) THEN
      ALLOCATE(status%nested_error)
    END IF
    status%nested_error = nested_status
  END SUBROUTINE Append_Error

  ! 打印完整的错误链
  SUBROUTINE Print_Error_Chain(status, unit)
    TYPE(ErrorStatusType), INTENT(IN) :: status
    INTEGER, INTENT(IN), OPTIONAL :: unit
    INTEGER :: u, depth
    TYPE(ErrorStatusType), POINTER :: err
    
    u = 6  ! 默认 STDOUT
    IF (PRESENT(unit)) u = unit
    
    depth = 0
    err => status
    DO
      WRITE(u,'(A,I0,A,I0,A)') "Error #", depth, " [Code=", err%status_code, "]"
      WRITE(u,'(A)') TRIM(err%message)
      IF (LEN_TRIM(err%source_file) > 0) THEN
        WRITE(u,'(A,A,A,I0)') "  at ", TRIM(err%source_file), ":", err%source_line
      END IF
      
      IF (.NOT. ASSOCIATED(err%nested_error)) EXIT
      err => err%nested_error
      depth = depth + 1
    END DO
  END SUBROUTINE Print_Error_Chain

  ! 判断是否发生错误
  LOGICAL FUNCTION Is_Error(status)
    TYPE(ErrorStatusType), INTENT(IN) :: status
    Is_Error = (status%status_code /= STATUS_OK)
  END FUNCTION Is_Error

END MODULE IF_Err_API
```

---

### 2.4 IF_IO — 文件 I/O 与数据交换

**目标**：统一的文件读写接口，支持二进制与文本格式

**关键接口**：
```fortran
!===============================================================================
! MODULE IF_IO — 文件 I/O、格式转换、数据序列化
!===============================================================================

MODULE IF_IO
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK, STATUS_IO_ERROR
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: IF_Open_File, IF_Close_File, IF_Read_Line, IF_Write_Line
  PUBLIC :: IF_Parse_CSV, IF_Write_HDF5_Array
  PUBLIC :: IF_Serialize_TYPE, IF_Deserialize_TYPE

  ! ===== 数据格式枚举 =====
  PUBLIC :: IF_FORMAT_BINARY, IF_FORMAT_TEXT, IF_FORMAT_HDF5
  
  INTEGER(i4), PARAMETER :: IF_FORMAT_BINARY = 1_i4
  INTEGER(i4), PARAMETER :: IF_FORMAT_TEXT = 2_i4
  INTEGER(i4), PARAMETER :: IF_FORMAT_HDF5 = 3_i4

CONTAINS

  ! 打开文件（统一接口）
  SUBROUTINE IF_Open_File(file_path, file_unit, mode, status)
    CHARACTER(len=*), INTENT(IN) :: file_path
    INTEGER, INTENT(OUT) :: file_unit
    CHARACTER(len=*), INTENT(IN) :: mode  ! "READ", "WRITE", "APPEND"
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), ACTION=TRIM(mode), &
         IOSTAT=status%status_code, IOMSG=status%message)
    IF (status%status_code /= 0) THEN
      status%status_code = STATUS_IO_ERROR
      status%message = "Failed to open file: " // TRIM(file_path)
    END IF
  END SUBROUTINE IF_Open_File

  ! 关闭文件
  SUBROUTINE IF_Close_File(file_unit, status)
    INTEGER, INTENT(IN) :: file_unit
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CLOSE(UNIT=file_unit, IOSTAT=status%status_code, IOMSG=status%message)
  END SUBROUTINE IF_Close_File

  ! 读取一行文本
  SUBROUTINE IF_Read_Line(file_unit, line, status)
    INTEGER, INTENT(IN) :: file_unit
    CHARACTER(len=:), ALLOCATABLE, INTENT(OUT) :: line
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=1024) :: buffer
    READ(UNIT=file_unit, FMT='(A)', IOSTAT=status%status_code) buffer
    IF (status%status_code /= 0 .AND. status%status_code /= -1) THEN
      status%status_code = STATUS_IO_ERROR
      status%message = "Read error"
    END IF
    ALLOCATE(CHARACTER(len=LEN_TRIM(buffer)) :: line)
    line = TRIM(buffer)
  END SUBROUTINE IF_Read_Line

  ! 写入一行文本
  SUBROUTINE IF_Write_Line(file_unit, line, status)
    INTEGER, INTENT(IN) :: file_unit
    CHARACTER(len=*), INTENT(IN) :: line
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    WRITE(UNIT=file_unit, FMT='(A)') TRIM(line)
    status%status_code = STATUS_OK
  END SUBROUTINE IF_Write_Line

  ! CSV 解析 (占位符)
  SUBROUTINE IF_Parse_CSV(file_path, data, status)
    CHARACTER(len=*), INTENT(IN) :: file_path
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: data(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    ! 实现: 读取 CSV 文件，转换为二维数组
  END SUBROUTINE IF_Parse_CSV

  ! HDF5 写入 (占位符，需要链接 HDF5 库)
  SUBROUTINE IF_Write_HDF5_Array(file_path, dataset_name, array, status)
    CHARACTER(len=*), INTENT(IN) :: file_path, dataset_name
    REAL(wp), INTENT(IN) :: array(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    ! 实现: 将数组写入 HDF5 文件
  END SUBROUTINE IF_Write_HDF5_Array

  ! 序列化 Fortran 类型 (占位符)
  SUBROUTINE IF_Serialize_TYPE(obj, buffer, status)
    CLASS(*), INTENT(IN) :: obj
    CHARACTER(len=:), ALLOCATABLE, INTENT(OUT) :: buffer
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    ! 实现: 使用反射或 TRANSFER 将类型序列化
  END SUBROUTINE IF_Serialize_TYPE

  ! 反序列化 Fortran 类型 (占位符)
  SUBROUTINE IF_Deserialize_TYPE(buffer, obj, status)
    CHARACTER(len=*), INTENT(IN) :: buffer
    CLASS(*), INTENT(OUT) :: obj
    TYPE(ErrorStatusType), INTENT(OUT) :: status
  END SUBROUTINE IF_Deserialize_TYPE

END MODULE IF_IO
```

---

### 2.5 IF_Log — 日志诊断与性能计时

**目标**：分级日志、性能统计、调试追踪

**接口规范**：
```fortran
!===============================================================================
! MODULE IF_Log — 日志管理与性能计时
!===============================================================================

MODULE IF_Log
  USE IF_Prec, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: IF_LOG_DEBUG, IF_LOG_INFO, IF_LOG_WARNING, IF_LOG_ERROR
  PUBLIC :: IF_Log_Message, IF_Timer_Start, IF_Timer_Stop, IF_Timer_Report
  
  INTEGER(i4), PARAMETER :: IF_LOG_DEBUG = 0_i4
  INTEGER(i4), PARAMETER :: IF_LOG_INFO = 1_i4
  INTEGER(i4), PARAMETER :: IF_LOG_WARNING = 2_i4
  INTEGER(i4), PARAMETER :: IF_LOG_ERROR = 3_i4
  
  INTEGER(i4) :: Global_Log_Level = IF_LOG_INFO  ! 全局日志级别
  
  ! ===== 计时器类型 =====
  PUBLIC :: TimerType
  
  TYPE :: TimerType
    CHARACTER(len=64) :: name = ""
    REAL(wp) :: total_time = 0.0_wp
    REAL(wp) :: start_time = 0.0_wp
    INTEGER(i4) :: call_count = 0_i4
    LOGICAL :: running = .FALSE.
  END TYPE TimerType

CONTAINS

  ! 输出日志消息（带时间戳和级别）
  SUBROUTINE IF_Log_Message(level, message, unit)
    INTEGER(i4), INTENT(IN) :: level
    CHARACTER(len=*), INTENT(IN) :: message
    INTEGER, INTENT(IN), OPTIONAL :: unit
    
    CHARACTER(len=32) :: level_str
    INTEGER :: u
    
    IF (level < Global_Log_Level) RETURN
    
    u = 6  ! 默认 STDOUT
    IF (PRESENT(unit)) u = unit
    
    SELECT CASE (level)
    CASE (IF_LOG_DEBUG)
      level_str = "[DEBUG]"
    CASE (IF_LOG_INFO)
      level_str = "[INFO]"
    CASE (IF_LOG_WARNING)
      level_str = "[WARN]"
    CASE (IF_LOG_ERROR)
      level_str = "[ERROR]"
    CASE DEFAULT
      level_str = "[UNKNOWN]"
    END SELECT
    
    WRITE(u,'(A,1X,A)') TRIM(level_str), TRIM(message)
  END SUBROUTINE IF_Log_Message

  ! 计时器开始
  SUBROUTINE IF_Timer_Start(timer)
    TYPE(TimerType), INTENT(INOUT) :: timer
    CALL CPU_TIME(timer%start_time)
    timer%running = .TRUE.
  END SUBROUTINE IF_Timer_Start

  ! 计时器停止
  SUBROUTINE IF_Timer_Stop(timer)
    TYPE(TimerType), INTENT(INOUT) :: timer
    REAL(wp) :: elapsed
    
    IF (.NOT. timer%running) RETURN
    CALL CPU_TIME(elapsed)
    timer%total_time = timer%total_time + (elapsed - timer%start_time)
    timer%call_count = timer%call_count + 1_i4
    timer%running = .FALSE.
  END SUBROUTINE IF_Timer_Stop

  ! 计时器报告
  SUBROUTINE IF_Timer_Report(timer, unit)
    TYPE(TimerType), INTENT(IN) :: timer
    INTEGER, INTENT(IN), OPTIONAL :: unit
    INTEGER :: u
    REAL(wp) :: avg_time
    
    u = 6
    IF (PRESENT(unit)) u = unit
    
    IF (timer%call_count == 0_i4) THEN
      WRITE(u,'(A,A)') "Timer '", TRIM(timer%name), "' has not been called"
      RETURN
    END IF
    
    avg_time = timer%total_time / REAL(timer%call_count, wp)
    WRITE(u,'(A,A,A,F10.6,A,I0,A,F10.6)') &
      "Timer '", TRIM(timer%name), "': total=", timer%total_time, &
      "s, calls=", timer%call_count, ", avg=", avg_time, "s"
  END SUBROUTINE IF_Timer_Report

END MODULE IF_Log
```

---

### 2.6 IF_Memory & IF_Monitor — 内存与监控接口

**目标**：动态内存管理、资源监控

*（占位符，详见后续交付）*

```fortran
! IF_Memory: 对象池、内存分配追踪、泄漏检测
! IF_Monitor: CPU 使用率、内存占用、性能计数器
```

---

## 三、L1_IF 工作流（从应用启动到运行时）

### 初始化流程（在 L6_AP 入口处调用）

```fortran
PROGRAM UFC_Main
  USE IF_Base, ONLY: IF_Init_System
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  USE IF_Log, ONLY: IF_Log_Message, IF_LOG_INFO
  IMPLICIT NONE
  
  TYPE(ErrorStatusType) :: status
  
  ! ===== L1_IF 初始化 =====
  CALL IF_Init_System()
  CALL IF_Log_Message(IF_LOG_INFO, "UFC initialized")
  
  ! ===== 上层应用逻辑 (L2~L5) =====
  ! ...
  
END PROGRAM UFC_Main
```

### 错误传播链示例

```fortran
SUBROUTINE L5_Solver_Execute(...)
  TYPE(ErrorStatusType) :: status, l4_status
  
  ! 调用 L4 物理层
  CALL L4_Compute_Residual(status=l4_status)
  
  IF (l4_status%status_code /= STATUS_OK) THEN
    ! 链式传播错误
    CALL Append_Error(status, l4_status)
    CALL Print_Error_Chain(status)  ! 打印完整错误链
    RETURN
  END IF
END SUBROUTINE L5_Solver_Execute
```

---

## 四、L1_IF 与上层接口契约

| 上层 | 依赖的 L1 接口 | 用途 |
|------|---|---|
| **L2_NM** | IF_Prec, IF_Err_API, IF_Log | 精度一致性、错误返回、性能计时 |
| **L3_MD** | IF_Prec, IF_Err_API, IF_IO | 数据验证、文件读写 |
| **L4_PH** | IF_Prec, IF_Err_API, IF_Log | 物理计算精度、性能统计 |
| **L5_RT** | IF_Prec, IF_Err_API, IF_Log, IF_Memory | 运行时管理、动态内存 |
| **L6_AP** | IF_Base, IF_IO, IF_Log, IF_Monitor | 系统初始化、用户交互、诊断输出 |

---

## 五、后续工作

- [ ] 完成 IF_Memory、IF_Monitor 模块设计
- [ ] 编写 L1_IF 单元测试（编译器兼容性验证）
- [ ] 集成 CMake 构建系统（L1_IF 为基础库）
- [ ] 同步更新 @templates 中的 L1_IF 模板

---

**交付日期**: 2026-04-04  
**版本**: v1.0 初稿  
**后续审查**: P3 Task B/C/D 完成后进行跨层集成验证
