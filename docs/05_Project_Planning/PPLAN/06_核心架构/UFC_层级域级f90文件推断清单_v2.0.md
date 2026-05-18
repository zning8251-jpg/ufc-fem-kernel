# UFC 层级-域-子域-f90 文件推断清单 v3.0

> **任务**: 从现有 UFC 架构文档反向推断各域级最小完备 f90 文件清单
> **版本**: v3.0（TYPE 统一合并策略 + 层级-域级-功能目录完整规范）
> **日期**: 2026-04-12
> **总文件数**: 336+ 个（Phase 4 执行后约 370+）

---

## 一、六层架构总览

| 层级 | 域数 | 子域数 | f90 文件数 | 命名前缀 | 职责 |
|------|------|--------|-----------|----------|------|
| **L1_IF** | 11 | 1 | 50+ | `IF_` | 基础设施 |
| **L2_NM** | 7 | 6 | 100+ | `NM_` | 数值算法 |
| **L3_MD** | 15 | 8 | 350+ | `MD_` | 模型数据 |
| **L4_PH** | 9 | 14 | **450+** | `PH_` | 物理计算 |
| **L5_RT** | 13 | 0 | 80+ | `RT_` | 运行时协调 |
| **L6_AP** | 8 | 0 | 30+ | `AP_` | 应用层 |
| **合计** | **63+** | **29+** | **1000+** | | |

---

## 二、L1_IF — 基础设施层

```text
L1_IF/
├── AI/                                 [⭐ AI运行时 - Phase 3扩展]
│                                      【设计意图】
│                                      • 定位：UFC 数据中台的 AI 能力底座，提供硬件无关、模型格式无关、精度可配置的 AI 运行时服务
│                                      • 职责：ONNX Runtime 统一封装，为上层 6 个 AI 插槽（①~⑥）提供标准化推理接口
│                                      • 边界：仅负责 NN 推理路径，不涉及 AI 算法逻辑；禁止上层直接调用底层引擎 API
│                                      • 依赖：L1_IF 最底层，不 USE 任何上层模块
│                                      
│                                      【核心功能】
│                                      • 模型加载/卸载：ONNX 模型加载、会话管理、热更新
│                                      • 推理执行：单样本推理（调试）+ 批量推理（热路径 SIMD/GPU 加速）
│                                      • 设备管理：CPU/GPU 切换、64-byte 内存对齐（AVX-512）
│                                      • 张量运算：MatMul/Conv/激活函数（内部优化）
│                                      • 数据预处理/后处理：归一化/标准化、特征提取、AI 输出映射到物理量
│                                      • 错误映射：ONNX Runtime C API → UFC ErrorStatusType 100% 覆盖
│                                      
│                                      【服务对象】
│                                      • ① AI_StepCtr（L5_RT 切步控制器）
│                                      • ② AI_ConvPredict（L5_RT 收敛预测器）
│                                      • ③ AI_MatInteg（L4_PH 本构代理）
│                                      • ④ AI_ContactLaw（L4_PH 接触律代理）
│                                      • ⑤ AI_Preconditioner（L2_NM 学习型预条件）
│                                      • ⑥ AI_SparseSolver（L2_NM 稀疏求解加速）
│
│   ├── IF_AI_Core.f90                 → AI 推理引擎核心（含会话管理/批量推理/设备管理/缓存）
│   ├── IF_AI_API.f90                  → AI 推理 API 接口（统一对外，供上层插槽调用）
│   ├── IF_AI_Model_Loader.f90         → 模型加载器（.onnx/.pt 格式支持+验证）
│   ├── IF_AI_Tensor_Ops.f90           → 张量运算（MatMul/Conv/激活函数 SIMD 优化）
│   ├── IF_AI_Preprocess.f90           → 数据预处理+后处理（归一化/特征提取/物理量映射）
│   └── IF_AI_Types.f90                → TYPE: AI 描述符/状态/算法/上下文（统一合并）
│
├── Base/                               [基础设施核心]
│                                      【设计意图】
│                                      • 定位：UFC 全栈运行所依赖的底层通用能力底座，是其他所有域的依赖基石
│                                      • 职责：精度定义、数学工具、设备管理、符号表、元数据管理、分析步类型
│                                      • 边界：纯基础设施，零业务逻辑；进程级生命周期（Job Init → Job Finalize）
│                                      • 依赖：L1_IF 最底层，所有上层模块都依赖 Base，但 Base 不依赖任何上层
│                                      
│                                      【核心功能】
│                                      • 精度定义：wp/i4/i8 等精度类型统一定义（合并精度类型+常量）
│                                      • 物理常量：π、E、重力加速度等常量集中管理
│                                      • 数学工具：safe_divide、向量/矩阵运算、数值稳定函数
│                                      • 设备管理：CPU/GPU/MPI/OMP 能力检测与资源管理
│                                      • 符号表：名称→ID 注册表（Part/Material/Section 等 8 种符号类型）
│                                      • 元数据管理：结构化+非结构化元数据 schema 定义与查询
│                                      • 分析步类型：Step 类型枚举（Static/Dynamic/Heat 等 8 种）
│                                      
│                                      【服务对象】
│                                      • 全层所有模块：精度定义（wp/i4）是 UFC 基础依赖
│                                      • L2_NM/L4_PH/L5_RT：设备能力查询（CPU/GPU/MPI）
│                                      • L3_MD/L6_AP：符号表注册/查询（Part/Material/Section）
│                                      • L3_MD/L6_AP：元数据管理（结构化/非结构化 schema）
│
│   ├── IF_Base_Core.f90               → 核心基础设施（设备能力检测）
│   │                                      【子程序清单】
│   │                                      • IF_Base_Init(InOut status) → 初始化Base域
│   │                                      • IF_Base_Finalize(InOut status) → 释放Base域资源
│   │                                      • IF_Base_GetDeviceCaps(Out caps) → 查询设备能力(CPU/GPU/MPI/OMP)
│   │                                      • IF_Base_CheckHardware(Out hw_info) → 硬件检测(核心数/内存/SIMD)
│   │                                      【接口契约】
│   │                                      • 前置条件: IF_Prec已初始化,wp/i4精度类型已定义
│   │                                      • 后置条件: 设备能力标志已填充,可被上层查询
│   │                                      • 线程安全: 是(进程级单次初始化)
│   │                                      • 错误处理: 返回ErrorStatusType,不抛出异常
│   ├── IF_Base_API.f90                → Base 域统一 API 接口（新增）
│   │                                      【子程序清单】
│   │                                      • IF_Base_GetVersion(Out version_str) → 获取Base域版本号
│   │                                      • IF_Base_GetSummary(Out summary) → 获取Base域配置摘要
│   │                                      • IF_Base_SetVerbose(In verbose_level) → 设置详细级别
│   │                                      【接口契约】
│   │                                      • 调用时机: 调试/诊断时调用,热路径禁止调用
│   │                                      • 返回格式: version_str='L1_IF.Base.v3.0'
│   │                                      • 线程安全: 是(只读接口)
│   ├── IF_Base_DP.f90                 → 精度定义+物理常量+安全工具函数（合并）
│   │                                      【子程序清单】
│   │                                      • IF_Base_GetPi(Out pi_val) → 获取π常量(wp精度)
│   │                                      • IF_Base_GetEuler(Out e_val) → 获取e常量(wp精度)
│   │                                      • IF_Base_SafeDivide(In numerator, In denominator, Out result) → 安全除法(防除零)
│   │                                      • IF_Base_Clamp(In value, In min_val, In max_val, Out clamped) → 数值钳位
│   │                                      【接口契约】
│   │                                      • 精度保证: 所有常量20+位十进制精度(wp=REAL64或REAL128)
│   │                                      • 安全除法: denominator<EPS时,result=HUGE(1.0_wp),返回WARNING
│   │                                      • 线程安全: 是(纯函数,无副作用)
│   ├── IF_Math_Util.f90               → 数学工具函数（向量/矩阵/数值稳定）
│   │                                      【子程序清单】
│   │                                      • IF_Math_VecNorm2(In vec, Out norm) → 向量L2范数
│   │                                      • IF_Math_VecDot(In vec1, In vec2, Out dot) → 向量点积
│   │                                      • IF_Math_VecCross3D(In v1, In v2, Out cross) → 3D向量叉积
│   │                                      • IF_Math_MatFrobenius(In mat, Out fro_norm) → 矩阵Frobenius范数
│   │                                      • IF_Math_IsNaN(In val, Out is_nan) → NaN检测
│   │                                      • IF_Math_IsInf(In val, Out is_inf) → Inf检测
│   │                                      • IF_Math_IsFinite(In val, Out is_finite) → 有限性检查
│   │                                      【接口契约】
│   │                                      • 纯函数: 所有函数声明为PURE,支持SIMD优化
│   │                                      • 数值稳定: 使用Kahan求和算法防止精度损失
│   │                                      • 线程安全: 是(无共享状态)
│   ├── IF_Device_Mgr.f90              → 设备管理器（重命名自 IF_DeviceManager.f90）
│   │                                      【子程序清单】
│   │                                      • IF_Device_Init(Out status) → 初始化设备管理器
│   │                                      • IF_Device_Finalize(Out status) → 释放设备资源
│   │                                      • IF_Device_GetGPUCount(Out count) → 查询GPU数量
│   │                                      • IF_Device_GetGPUMem(Out mem_mb) → 查询GPU显存(MB)
│   │                                      • IF_Device_IsMPIEnabled(Out enabled) → 检查MPI是否启用
│   │                                      • IF_Device_IsOMPEnabled(Out enabled) → 检查OpenMP是否启用
│   │                                      • IF_Device_GetNumThreads(Out nthreads) → 获取线程数
│   │                                      • IF_Device_SetNumThreads(In nthreads) → 设置线程数
│   │                                      【接口契约】
│   │                                      • 设备检测: 初始化时自动检测CPU/GPU/MPI/OMP能力
│   │                                      • GPU支持: 通过CUDA API查询(需编译时-DWITH_CUDA)
│   │                                      • 线程安全: 是(互斥锁保护)
│   │                                      • 错误处理: 设备不可用时返回WARNING而非FATAL
│   ├── IF_Step_Types.f90              → 分析步类型定义（重命名自 IF_Step_Type.f90）
│   │                                      【子程序清单】
│   │                                      • IF_Step_GetTypeName(In step_type, Out name) → 获取分析步名称
│   │                                      • IF_Step_IsStatic(In step_type, Out is_static) → 检查是否静力分析
│   │                                      • IF_Step_IsDynamic(In step_type, Out is_dynamic) → 检查是否动力分析
│   │                                      【接口契约】
│   │                                      • 枚举值: STEP_STATIC=1, STEP_DYNAMIC=2, STEP_HEAT=3, STEP_FREQUENCY=4...
│   │                                      • 纯查询: 无状态修改,支持编译时优化
│   │                                      • 线程安全: 是(只读接口)
│   ├── IF_Base_SymTbl.f90             → 符号表管理（2,406 行，单独保留）
│   │                                      【子程序清单】
│   │                                      • IF_SymTbl_Init(Out status) → 初始化符号表
│   │                                      • IF_SymTbl_Finalize(Out status) → 释放符号表
│   │                                      • IF_SymTbl_Register(In name, In sym_type, Out sym_id, Out status) → 注册符号
│   │                                      • IF_SymTbl_Lookup(In name, Out sym_id, Out found) → 查询符号ID
│   │                                      • IF_SymTbl_GetName(In sym_id, Out name, Out found) → 根据ID获取名称
│   │                                      • IF_SymTbl_IsDuplicate(In name, Out is_dup) → 检查符号重复
│   │                                      • IF_SymTbl_GetCount(In sym_type, Out count) → 获取某类符号数量
│   │                                      • IF_SymTbl_Clear(Out status) → 清空符号表
│   │                                      • IF_SymTbl_Print(Out status) → 打印符号表统计
│   │                                      【接口契约】
│   │                                      • 符号类型: SYM_PART/SYM_MATERIAL/SYM_SECTION/SYM_MESH/SYM_NODE/SYM_ELEM/SYM_SET/SYM_SURF (8种)
│   │                                      • 哈希表: 开链法,负载因子<0.75,自动扩容
│   │                                      • 唯一性: 同类型符号名称必须唯一,重复注册返回ERROR
│   │                                      • 线程安全: 是(读写锁保护)
│   │                                      • 容量限制: 默认100,000符号,可配置
│   ├── IF_Base_StructMeta.f90         → 结构化元数据（4,575 行，需进一步拆分）
│   │                                      【子程序清单】
│   │                                      • IF_StructMeta_Init(Out status) → 初始化结构化元数据管理器
│   │                                      • IF_StructMeta_Finalize(Out status) → 释放结构化元数据
│   │                                      • IF_StructMeta_RegisterSchema(In schema_name, In fields, In nfields, Out status) → 注册Schema
│   │                                      • IF_StructMeta_AddField(In schema_name, In field_name, In field_type, Out status) → 添加字段
│   │                                      • IF_StructMeta_GetField(In schema_name, In field_name, Out field_info, Out found) → 查询字段
│   │                                      • IF_StructMeta_ValidateInstance(In schema_name, In instance, Out is_valid, Out errors) → 验证实例
│   │                                      • IF_StructMeta_GetSchemaNames(Out names, Out count) → 获取所有Schema名称
│   │                                      • IF_StructMeta_GetFieldCount(In schema_name, Out count) → 获取字段数量
│   │                                      【接口契约】
│   │                                      • Schema定义: 名称+字段列表(名称/类型/必填/默认值)
│   │                                      • 字段类型: INT/REAL/CHAR/BOOL/ARRAY/REFERENCE(跨域引用)
│   │                                      • 验证规则: 必填字段检查/类型检查/范围检查/引用完整性检查
│   │                                      • 线程安全: 是(写时复制,COW)
│   │                                      • 拆分规划: P1拆分为StructSchema/StructQuery/StructValidate (各~1,500行)
│   ├── IF_Base_UnstructMeta.f90       → 非结构化元数据（918 行，保持现状）
│   │                                      【子程序清单】
│   │                                      • IF_UnstructMeta_Init(Out status) → 初始化非结构化元数据
│   │                                      • IF_UnstructMeta_Finalize(Out status) → 释放非结构化元数据
│   │                                      • IF_UnstructMeta_SetValue(In key, In value, Out status) → 设置键值对
│   │                                      • IF_UnstructMeta_GetValue(In key, Out value, Out found) → 获取键值对
│   │                                      • IF_UnstructMeta_DeleteKey(In key, Out found) → 删除键
│   │                                      • IF_UnstructMeta_GetAllKeys(Out keys, Out count) → 获取所有键
│   │                                      • IF_UnstructMeta_ComputeChecksum(Out checksum) → 计算CRC32校验和
│   │                                      【接口契约】
│   │                                      • 存储格式: 键值对(CHAR键,CHAR值),支持JSON/XML序列化
│   │                                      • 键命名: 域_类别_名称(如'Material.elastic_modulus')
│   │                                      • 线程安全: 是(并发哈希表)
│   │                                      • 校验和: CRC32算法,用于变更检测
│   │                                      • 拆分规划: P1拆分为UnstructSchema/UnstructOps/UnstructValidate
│   └── IF_Base_Types.f90              → TYPE: Base 描述符/状态/算法/上下文（新增，统一合并）
│
│                                      【新旧命名映射关系】
│                                      • IF_DeviceManager.f90 → IF_Device_Mgr.f90（Manager → _Mgr 缩写规范）
│                                      • IF_Step_Type.f90 → IF_Step_Types.f90（单数→复数，与其他域对齐）
│                                      • IF_Base_Ctx.f90 → 合并到 IF_Base_Types.f90（Ctx TYPE）
│                                      • 新增 IF_Base_API.f90（统一对外接口）
│                                      • 新增 IF_Base_Types.f90（四类 TYPE 统一合并）
│                                      
│                                      【架构决策说明】
│                                      • 符号表管理：单独保留 IF_Base_SymTbl.f90（2,406 行），不合并到 Core
│                                        原因：① 职责独立（变量注册/查询/版本控制）② 全层高频引用 ③ 合并后 Core 过长（2,660 行）
│                                      • 元数据管理：保持结构化/非结构化拆分（职责分离）
│                                      • IF_Base_StructMeta.f90（4,575 行）需后续拆分为 3 个子模块：
│                                        - IF_Base_StructSchema.f90（Schema 定义、字段注册，~1,500 行，P1）
│                                        - IF_Base_StructQuery.f90（查询接口、路径解析，~1,500 行，P1）
│                                        - IF_Base_StructValidate.f90（验证逻辑、类型检查，~1,500 行，P2）
│                                      • IF_Base_UnstructMeta.f90（918 行）需后续拆分为 3 个子模块：
│                                        - IF_Base_UnstructSchema.f90（Schema 定义、TYPE 定义、常量注册，~150 行，P1）
│                                        - IF_Base_UnstructOps.f90（核心操作 CRUD，~500 行，P1）
│                                        - IF_Base_UnstructValidate.f90（验证逻辑、CRC32 校验，~270 行，P2）
│
├── Error/                              [错误处理]
│                                      【设计意图】
│                                      • 定位：UFC 全栈错误处理与日志基础设施，统一的错误状态管理和日志记录中心
│                                      • 职责：ErrorStatusType 定义、6 层错误码注册、错误传播模型、基础日志输出
│                                      • 边界：仅负责错误状态和基础日志；复杂日志轮转/国际化由 Log 域处理
│                                      • 依赖：L1_IF 最底层，不 USE 任何上层模块
│                                      
│                                      【核心功能】
│                                      • 错误状态管理：ErrorStatusType 定义、初始化、设置、清除、检查
│                                      • 错误码体系：6 层区间分配（L1:1000-1999...）、38 个预定义错误码
│                                      • 错误严重程度：5 级（INFO/WARNING/ERROR/CRITICAL/FATAL）
│                                      • 错误分类：8 种（OK/INVALID/MEM/IO/MATH/ALLOC/BOUNDS/USER）
│                                      • 错误栈管理：全局错误栈（最大 1024 条）、线程安全
│                                      • 错误统计：错误/警告/致命错误计数、最后错误码
│                                      • 基础日志：5 级日志输出、日志级别控制、控制台开关
│                                      • 兼容性接口：UF 旧版错误处理接口兼容（uf_set_error）
│
│   ├── IF_Err_Type.f90                → TYPE 定义（ErrorStatusType/LogEntry/GlobalErrorStack 等 9 个 TYPE）
│   │                                      【类型定义】
│   │                                      • ErrorStatusType: error_code(0), severity(0), category(0), message(''), context(''), stack_depth(0)
│   │                                      • LogEntry: timestamp, level, module, line, message
│   │                                      • GlobalErrorStack: entries(1024), top_index(0), lock
│   │                                      • ErrorStats: error_count, warning_count, fatal_count, last_error_code
│   │                                      【接口契约】
│   │                                      • 错误码区间: L1:1000-1999, L2:2000-2999, L3:3000-3999, L4:4000-4999, L5:5000-5999, L6:6000-6999
│   │                                      • 严重程度: INFO=0, WARNING=1, ERROR=2, CRITICAL=3, FATAL=4
│   │                                      • 错误分类: OK=0, INVALID=1, MEM=2, IO=3, MATH=4, ALLOC=5, BOUNDS=6, USER=7
│   │                                      • 线程安全: 是(原子操作+互斥锁)
│   ├── IF_Err_API.f90                 → 核心 API 接口（14 个子程序：init/error_set/log_*/uf_set_error 等）
│   │                                      【子程序清单】
│   │                                      • IF_Err_Init(Out status) → 初始化错误管理系统
│   │                                      • IF_Err_Finalize(Out status) → 释放错误管理系统
│   │                                      • IF_Err_Set(InOut status, In code, In severity, In category, In message) → 设置错误状态
│   │                                      • IF_Err_Clear(InOut status) → 清除错误状态
│   │                                      • IF_Err_IsError(In status, Out is_error) → 检查是否错误
│   │                                      • IF_Err_IsFatal(In status, Out is_fatal) → 检查是否致命错误
│   │                                      • IF_Err_GetCode(In status, Out code) → 获取错误码
│   │                                      • IF_Err_GetMessage(In status, Out message) → 获取错误消息
│   │                                      • IF_Err_PushStack(In status) → 推入错误栈
│   │                                      • IF_Err_PopStack(Out status) → 弹出错误栈
│   │                                      • IF_Err_LogError(In status, In module, In line) → 记录错误日志
│   │                                      • IF_Err_LogWarning(In message, In module) → 记录警告日志
│   │                                      • IF_Err_GetStats(Out stats) → 获取错误统计
│   │                                      • IF_UF_SetError(In code, In message) → UF旧版兼容接口
│   │                                      【接口契约】
│   │                                      • 错误传播: 跨层零拷贝传递(指针传递ErrorStatusType)
│   │                                      • 错误栈: 最大1024条,超出时覆盖最旧条目
│   │                                      • 线程安全: 是(OpenMP临界区保护)
│   │                                      • 日志集成: 自动调用IF_Log_Warning/Error
│   ├── IF_Err_Core.f90                → 错误域容器（3 个子程序：Init/Finalize/GetStats + 错误统计）
│   │                                      【子程序清单】
│   │                                      • IF_Err_Domain_Init(InOut this, Out status) → 初始化错误域
│   │                                      • IF_Err_Domain_Finalize(InOut this, Out status) → 释放错误域
│   │                                      • IF_Err_Domain_GetStats(In this, Out stats) → 获取域级统计
│   │                                      【接口契约】
│   │                                      • 域容器: 封装全局错误栈,提供TBP方法
│   │                                      • 幂等初始化: 重复调用先Finalize再Init
│   │                                      • 线程安全: 是
│   ├── IF_Err_Reg.f90                 → 错误码注册（9 个子程序：6 层区间 + 38 个预定义错误码）
│   │                                      【子程序清单】
│   │                                      • IF_Err_Reg_Init(Out status) → 初始化错误码注册表
│   │                                      • IF_Err_Reg_RegisterLayer(In layer_id, In start_code, In end_code) → 注册层区间
│   │                                      • IF_Err_Reg_RegisterCode(In code, In severity, In category, In description) → 注册错误码
│   │                                      • IF_Err_Reg_GetDescription(In code, Out description) → 获取错误码描述
│   │                                      • IF_Err_Reg_ValidateCode(In code, Out is_valid) → 验证错误码有效性
│   │                                      • IF_Err_Reg_GetLayerRange(In layer_id, Out start, Out end) → 获取层区间
│   │                                      • IF_Err_Reg_PrintRegistry(Out status) → 打印错误码注册表
│   │                                      • IF_Err_Reg_RegisterL1Codes(Out status) → 注册L1层错误码(1000-1999)
│   │                                      • IF_Err_Reg_RegisterAllLayers(Out status) → 注册6层所有错误码
│   │                                      【接口契约】
│   │                                      • 预定义错误码: 38个(OK/INVALID_PARAM/MEM_ALLOC_FAIL/IO_FILE_NOT_FOUND等)
│   │                                      • 唯一性: 错误码必须全局唯一,重复注册返回ERROR
│   │                                      • 线程安全: 是(初始化时注册,运行时只读)
│   └── CONTRACT.md                    → 接口契约文档
│
├── IO/                                 [输入输出]
│                                      【设计意图】
│                                      • 定位：UFC 全栈输入输出基础设施，统一的文件操作、数据解析、结果写入和检查点管理
│                                      • 职责：文件操作抽象、ABAQUS inp 解析、VTK/HDF5/CSV 写入、检查点持久化
│                                      • 边界：仅负责 IO 操作；复杂业务逻辑由 L6_AP 处理
│                                      • 依赖：L1_IF 层，依赖 IF_Err_API（错误处理）、IF_Prec（精度定义）
│                                      
│                                      【核心功能】
│                                      • 文件句柄管理：文件打开/关闭、读写模式、文本/二进制格式、文件定位（15 个子程序）
│                                      • 文件操作：文件存在检查、大小、删除、复制、目录创建
│                                      • 关键字解析：ABAQUS inp 关键字解析、选项提取、注释跳过
│                                      • 数据解析：节点行解析、单元行解析、坐标/连接关系提取
│                                      • 结果写入：VTK/HDF5/CSV 格式输出
│                                      • 数据过滤：字段选择、范围过滤、格式转换
│                                      • 检查点持久化：检查点注册、读/写、版本管理（7 个子程序）
│                                      • 备份管理：自动备份、备份恢复、版本控制
│                                      • IO 日志：5 级日志输出（DEBUG/INFO/WARNING/ERROR/FATAL）
│
│   ├── IF_IO_Core.f90                 → IO 域容器（5 个子程序：Init/Finalize/OpenFile/CloseFile/GetHandle）
│   │                                      【子程序清单】
│   │                                      • IF_IO_Domain_Init(InOut this, Out status) → 初始化IO域
│   │                                      • IF_IO_Domain_Finalize(InOut this, Out status) → 释放IO域
│   │                                      • IF_IO_OpenFile(In filename, In mode, Out unit, Out status) → 打开文件
│   │                                      • IF_IO_CloseFile(In unit, Out status) → 关闭文件
│   │                                      • IF_IO_GetHandle(In unit, Out handle_info) → 获取文件句柄信息
│   │                                      【接口契约】
│   │                                      • 文件模式: 'READ'/'WRITE'/'APPEND'/'BINARY'
│   │                                      • 句柄管理: 最大100个并发文件句柄
│   │                                      • 错误处理: 文件不存在返回ERROR,不抛出异常
│   │                                      • 线程安全: 是(句柄表互斥锁)
│   ├── IF_IO_API.f90                  → IO 统一 API 接口（新增）
│   │                                      【子程序清单】
│   │                                      • IF_IO_GetVersion(Out version) → 获取IO域版本
│   │                                      • IF_IO_GetSummary(Out summary) → 获取IO域配置摘要
│   │                                      • IF_IO_SetDefaultDir(In dir_path) → 设置默认目录
│   │                                      • IF_IO_GetDefaultDir(Out dir_path) → 获取默认目录
│   │                                      【接口契约】
│   │                                      • 版本格式: 'L1_IF.IO.v3.0'
│   │                                      • 目录路径: 绝对路径或相对路径(相对于工作目录)
│   │                                      • 线程安全: 是(只读接口)
│   ├── IF_IO_File.f90                 → 文件操作核心（15 个子程序：Open/Close/Read/Write/Exists 等）
│   │                                      【子程序清单】
│   │                                      • IF_IO_File_Open(In filename, In mode, In form, Out unit, Out status) → 打开文件
│   │                                      • IF_IO_File_Close(In unit, Out status) → 关闭文件
│   │                                      • IF_IO_File_ReadLine(In unit, Out line, Out status) → 读取一行
│   │                                      • IF_IO_File_WriteLine(In unit, In line, Out status) → 写入一行
│   │                                      • IF_IO_File_ReadBinary(In unit, Out buffer, In size, Out status) → 读取二进制
│   │                                      • IF_IO_File_WriteBinary(In unit, In buffer, In size, Out status) → 写入二进制
│   │                                      • IF_IO_File_Exists(In filename, Out exists) → 检查文件存在
│   │                                      • IF_IO_File_GetSize(In filename, Out size_bytes) → 获取文件大小
│   │                                      • IF_IO_File_Delete(In filename, Out status) → 删除文件
│   │                                      • IF_IO_File_Copy(In src, In dst, Out status) → 复制文件
│   │                                      • IF_IO_File_CreateDir(In dir_path, Out status) → 创建目录
│   │                                      • IF_IO_File_Rewind(In unit, Out status) → 文件定位到开头
│   │                                      • IF_IO_File_Pos(In unit, Out pos) → 获取当前位置
│   │                                      • IF_IO_File_Seek(In unit, In offset, In origin, Out status) → 文件定位
│   │                                      • IF_IO_File_IsEOF(In unit, Out is_eof) → 检查文件结束
│   │                                      【接口契约】
│   │                                      • 文件模式: 'READ'/'WRITE'/'APPEND'/'BINARY'
│   │                                      • 文件格式: 'FORMATTED'/'UNFORMATTED'
│   │                                      • 定位原点: 'BEGIN'/'CURRENT'/'END'
│   │                                      • 线程安全: 是(文件句柄互斥锁)
│   ├── IF_IO_Types.f90                → TYPE 定义（IF_IO_Cfg_Type 等）
│   ├── IF_Parser.f90                  → 数据解析器（4 个子程序：ReadKeyword/ParseNodeLine/ParseElemLine）
│   │                                      【子程序清单】
│   │                                      • IF_Parser_ReadKeyword(In line, Out keyword, Out options) → 读取ABAQUS关键字
│   │                                      • IF_Parser_SkipComment(In line, Out clean_line) → 跳过注释行
│   │                                      • IF_Parser_ParseNodeLine(In line, Out node_id, Out coords) → 解析节点行
│   │                                      • IF_Parser_ParseElemLine(In line, Out elem_id, Out connectivity) → 解析单元行
│   │                                      【接口契约】
│   │                                      • 关键字格式: *KEYWORD,OPTION1=VALUE1,OPTION2=VALUE2
│   │                                      • 节点格式: NODE_ID,X,Y,Z(可选)
│   │                                      • 单元格式: ELEM_ID,NODE1,NODE2,NODE3,...
│   │                                      • 错误处理: 格式错误返回ERROR,记录日志
│   ├── IF_Writer.f90                  → 结果写入器（3 个子程序：WriteVTK/WriteHDF5/WriteCSV）
│   │                                      【子程序清单】
│   │                                      • IF_Writer_WriteVTK(In filename, In nodes, In elems, In field_data, Out status) → 写入VTK
│   │                                      • IF_Writer_WriteHDF5(In filename, In dataset, In data, Out status) → 写入HDF5
│   │                                      • IF_Writer_WriteCSV(In filename, In headers, In data_matrix, Out status) → 写入CSV
│   │                                      【接口契约】
│   │                                      • VTK格式: UnstructuredGrid,支持点数据/单元数据
│   │                                      • HDF5格式: 数据集+属性,支持分块压缩
│   │                                      • CSV格式: 逗号分隔,首行表头
│   │                                      • 错误处理: 写入失败返回ERROR
│   ├── IF_IO_Filters.f90              → 数据过滤器
│   ├── IF_IO_Log.f90                  → IO 日志（7 个子程序：Init/Shutdown/Debug/Info/Warning/Error/Fatal）
│   │                                      【子程序清单】
│   │                                      • IF_IO_Log_Init(Out status) → 初始化IO日志
│   │                                      • IF_IO_Log_Shutdown(Out status) → 关闭IO日志
│   │                                      • IF_IO_Log_Debug(In message) → 记录DEBUG日志
│   │                                      • IF_IO_Log_Info(In message) → 记录INFO日志
│   │                                      • IF_IO_Log_Warning(In message) → 记录WARNING日志
│   │                                      • IF_IO_Log_Error(In message) → 记录ERROR日志
│   │                                      • IF_IO_Log_Fatal(In message) → 记录FATAL日志
│   │                                      【接口契约】
│   │                                      • 日志级别: TRACE=0,DEBUG=1,INFO=2,WARNING=3,ERROR=4,FATAL=5
│   │                                      • 自动上下文: 时间戳+模块名+行号
│   │                                      • 线程安全: 是(异步缓冲区)
│   ├── CONTRACT.md                    → 接口契约文档
│   └── Checkpoint/                    [检查点子域]
│       ├── IF_IO_Backup.f90           → 备份管理（714 行）
│       ├── IF_IO_Persist.f90          → 持久化管理（361 行，7 个子程序）
│       ├── IF_IO_StructCore.f90       → 结构化核心管理器（~1,200 行，15 个子程序：Init/Open/Close/Read/Write）
│       ├── IF_IO_StructCache.f90      → 结构化缓存管理（~1,000 行，10 个子程序：Preload/Evict/Clear/Stats）
│       ├── IF_IO_StructOps.f90        → 结构化高级操作（~1,500 行，18 个子程序：Encrypt/Compress/Shard/Migrate）
│       ├── IF_IO_StructUtils.f90      → 结构化工具函数（~800 行，20 个子程序：Path/Format/Metadata）
│       ├── IF_IO_UnstructCore.f90     → 非结构化核心管理器（~1,000 行，12 个子程序：Init/Read/Write/Load）
│       ├── IF_IO_UnstructSerial.f90   → 非结构化序列化器（~1,500 行，22 个子程序：Serialize/Deserialize）
│       ├── IF_IO_UnstructPayload.f90  → 非结构化载荷写入（~1,200 行，24 个子程序：WriteBinary/WriteText）
│       ├── IF_IO_UnstructReg.f90      → 非结构化注册管理（~600 行，14 个子程序：Register/Chunk/Cache）
│       ├── IF_StructFormatAdapters.f90→ 结构化格式适配器（重命名自 UF_，816 行）
│       └── IF_UnstructFormatAdapters.f90→ 非结构化格式适配器（重命名自 UF_，222 行）
│
│                                      【架构决策说明】
│                                      • 命名规范：Checkpoint 子目录下 UF_ 前缀文件已重命名为 IF_ 前缀
│                                      • 代码拆分：IF_IO_StructFile.f90（5,334 行）已拆分为 4 个子模块（Core/Cache/Ops/Utils）
│                                      • 代码拆分：UF_UnstructFileManager.f90（4,259 行）已拆分为 4 个子模块（Core/Serial/Payload/Reg）
│                                      • API 统一：新增 IF_IO_API.f90 作为 IO 域统一对外接口
│                                      • 命名优化：统一使用 _Core/_Cache/_Ops/_Utils/_Serial/_Payload/_Reg 后缀
│
├── Log/                                [日志]
│                                      【设计意图】
│                                      • 定位：UFC 全栈日志基础设施，统一的日志记录、格式化、缓冲和多目标输出中心
│                                      • 职责：分级日志（TRACE/DEBUG/INFO/WARNING/ERROR/FATAL）、日志缓冲、文件输出、控制台输出、日志统计
│                                      • 边界：仅负责日志记录和输出；复杂日志轮转/国际化/异步日志由上层处理
│                                      • 依赖：L1_IF 最底层，依赖 IF_Err_API（错误处理）、IF_Err_Type（日志级别常量）、IF_Prec（精度定义）
│                                      
│                                      【核心功能】
│                                      • 日志级别管理：6 级日志（TRACE=0/DEBUG=1/INFO=2/WARNING=3/ERROR=4/FATAL=5）、最小级别过滤
│                                      • 多目标输出：控制台（STDOUT）、文件、双输出、纯缓冲（4 种输出模式）
│                                      • 日志缓冲：内存缓冲区（默认 1,000 条）、批量写入、自动刷新
│                                      • 日志格式化：时间戳、模块名、行号、日志级别、消息内容
│                                      • 日志统计：总日志数、各级别计数（TRACE/DEBUG/INFO/WARN/ERROR/FATAL）
│                                      • 文件日志：文件路径配置、追加模式、文件句柄管理
│                                      • 域级封装：IF_Log_Domain 容器、Init/Finalize、6 级日志方法
│                                      • 全局 API：IF_Log_Init/Trace/Debug/Info/Warning/Error/Fatal/Flush/GetStats
│
│   ├── IF_Log_Core.f90                → Log 域容器（193 行，9 个子程序：Init/Finalize/6 级日志方法/Flush）
│   │                                      【子程序清单】
│   │                                      • IF_Log_Domain_Init(InOut this, Out status) → 初始化日志域
│   │                                      • IF_Log_Domain_Finalize(InOut this, Out status) → 释放日志域
│   │                                      • IF_Log_Trace(In message, In module, In line) → 记录TRACE日志
│   │                                      • IF_Log_Debug(In message, In module, In line) → 记录DEBUG日志
│   │                                      • IF_Log_Info(In message, In module, In line) → 记录INFO日志
│   │                                      • IF_Log_Warning(In message, In module, In line) → 记录WARNING日志
│   │                                      • IF_Log_Error(In message, In module, In line) → 记录ERROR日志
│   │                                      • IF_Log_Fatal(In message, In module, In line) → 记录FATAL日志
│   │                                      • IF_Log_Flush(InOut this, Out status) → 刷新日志缓冲区
│   │                                      【接口契约】
│   │                                      • 日志级别: TRACE=0,DEBUG=1,INFO=2,WARNING=3,ERROR=4,FATAL=5
│   │                                      • 异步缓冲: 批量写入,减少IO开销
│   │                                      • 线程安全: 是(缓冲区互斥锁)
│   │                                      • 自动上下文: 时间戳+线程ID+模块名+行号
│   ├── IF_Log_Logger.f90              → 日志记录器核心（642 行，24 个子程序：IF_Logger/缓冲/格式化/统计/全局 API）
│   │                                      【子程序清单】
│   │                                      • IF_Logger_Init(In config, Out logger, Out status) → 初始化记录器
│   │                                      • IF_Logger_Finalize(InOut logger, Out status) → 释放记录器
│   │                                      • IF_Logger_Log(InOut logger, In level, In message, In module, In line) → 记录日志
│   │                                      • IF_Logger_SetLevel(InOut logger, In level, Out status) → 设置日志级别
│   │                                      • IF_Logger_AddSink(InOut logger, In sink, Out status) → 添加输出目标
│   │                                      • IF_Logger_RemoveSink(InOut logger, In sink_name, Out status) → 移除输出目标
│   │                                      • IF_Logger_Flush(InOut logger, Out status) → 刷新所有输出
│   │                                      • IF_Logger_GetStats(In logger, Out stats) → 获取日志统计
│   │                                      • IF_Log_Init(Out status) → 全局日志初始化
│   │                                      • IF_Log_Trace(In msg) → 全局TRACE
│   │                                      • IF_Log_Debug(In msg) → 全局DEBUG
│   │                                      • IF_Log_Info(In msg) → 全局INFO
│   │                                      【接口契约】
│   │                                      • 多目标: Console/File/Network三种输出
│   │                                      • 格式化: 时间戳+级别+模块+行号+消息
│   │                                      • 过滤: 按模块/级别多维过滤
│   │                                      • 线程安全: 是
│   ├── IF_Log_Types.f90               → 日志类型定义（53 行，日志级别常量、处理器目标常量）
│   │                                      【类型定义】
│   │                                      • LogLevel: TRACE=0,DEBUG=1,INFO=2,WARNING=3,ERROR=4,FATAL=5
│   │                                      • LogSinkTarget: SINK_CONSOLE=1,SINK_FILE=2,SINK_NETWORK=3,SINK_NULL=4
│   │                                      • LogFormat: 格式标志位(F_TIMESTAMP|F_LEVEL|F_MODULE|F_LINE)
│   │                                      • LogEntry: timestamp,level,module,line,message,thread_id
│   │                                      【接口契约】
│   │                                      • 纯常量: 所有类型为PARAMETER,无运行时开销
│   │                                      • 线程安全: 是
│   └── CONTRACT.md                    → 接口契约文档（33 行）
│
│                                      【架构决策说明】
│                                      • 代码量合理：总计 828 行，所有文件均 < 2,000 行阈值
│                                      • 模块内聚优秀：职责清晰（Core=容器/Logger=实现/Types=常量）
│                                      • 命名规范：统一 IF_ 前缀，符合三级命名体系
│                                      • SIO 规范：提供结构化接口（IF_Logger_Init_In/Out）
│
├── Memory/                             [内存管理]
│                                      【设计意图】
│                                      • 定位：UFC 全栈内存管理基础设施，统一的内存池、Arena 分配器、工作空间和序列化中心
│                                      • 职责：命名内存池（Arena 模式）、工作空间管理、结构化/非结构化内存池、内存序列化、线程 Slab
│                                      • 边界：仅负责内存分配/释放/池管理；复杂对象生命周期由 L3_MD 处理
│                                      • 依赖：L1_IF 最底层，依赖 IF_Err_API（错误处理）、IF_Prec（精度定义）
│                                      
│                                      【核心功能】
│                                      • 命名内存池：Arena 分配器（HWM 模式）、O(1) 分配/重置、零碎片化（8 个子程序）
│                                      • 内存管理器：统一分配/释放接口、域管理、统计报告（28 个子程序）
│                                      • 内存块管理：块分配/释放、块注册/查询、设备内存同步（8 个子程序）
│                                      • 内存序列化：序列化/反序列化、字节拷贝、格式转换（24 个子程序）
│                                      • 线程 Slab：线程局部内存板、无锁分配、线程安全（11 个子程序）
│                                      • 工作空间（WS）：Workspace CRUD、求解器持久缓冲、复用机制、统计（44 个子程序）
│                                      • 结构化内存池：结构体/类/数组分配、统一内存、设备同步（86 个子程序）⚠️
│                                      • 非结构化内存池：链表/图/哈希表分配、动态扩展（45 个子程序）⚠️
│
│   ├── IF_Mem_Core.f90                → 内存池核心（425 行，8 个子程序：CreatePool/AllocFromPool/ResetPool/PrintReport）
│   │                                      【子程序清单】
│   │                                      • IF_Mem_Arena_CreatePool(In pool_name, In max_bytes, Out pool_handle, Out status) → 创建命名内存池
│   │                                      • IF_Mem_Arena_AllocFromPool(In pool_handle, In nbytes, Out ptr, Out status) → 从池分配
│   │                                      • IF_Mem_Arena_ResetPool(In pool_handle, Out status) → 重置池(HWM模式)
│   │                                      • IF_Mem_Arena_DestroyPool(In pool_handle, Out status) → 销毁池
│   │                                      • IF_Mem_Arena_PrintReport(In pool_handle, Out status) → 打印池统计
│   │                                      • IF_Mem_Arena_GetStats(In pool_handle, Out alloc_count, Out total_bytes, Out peak_bytes) → 获取统计
│   │                                      • IF_Mem_Arena_CheckIntegrity(In pool_handle, Out is_valid, Out status) → 完整性检查
│   │                                      【接口契约】
│   │                                      • 分配模式: O(1)分配/重置,零碎片化
│   │                                      • HWM追踪: 自动记录峰值使用量
│   │                                      • 线程安全: 是(原子计数器+互斥锁)
│   │                                      • 热路径保障: 零ALLOCATE(AP-8规范)
│   ├── IF_Mem_Mgr.f90                 → 内存管理器（612 行，28 个子程序：Alloc/Free/Stats/Report）
│   │                                      【子程序清单】
│   │                                      • IF_Mem_Alloc(In size, Out ptr, Out status) → 统一分配
│   │                                      • IF_Mem_Free(In ptr, Out status) → 统一释放
│   │                                      • IF_Mem_Realloc(In old_ptr, In new_size, Out new_ptr, Out status) → 重分配
│   │                                      • IF_Mem_AllocArray(In size, In n, Out ptr, Out status) → 数组分配
│   │                                      • IF_Mem_FreeArray(In ptr, Out status) → 数组释放
│   │                                      • IF_Mem_GetTotalStats(Out total_alloc, Out total_free, Out peak_usage) → 全局统计
│   │                                      • IF_Mem_PrintReport(Out status) → 打印全局报告
│   │                                      • IF_Mem_RegisterDomain(In domain_name, Out domain_id, Out status) → 注册域
│   │                                      • IF_Mem_UnregisterDomain(In domain_id, Out status) → 注销域
│   │                                      • IF_Mem_GetDomainStats(In domain_id, Out alloc_bytes, Out alloc_count) → 域统计
│   │                                      【接口契约】
│   │                                      • 域隔离: 每个域独立统计,支持泄漏检测
│   │                                      • 泄漏检测: 初始化时记录,Finalize时报告未释放
│   │                                      • 线程安全: 是(域表互斥锁)
│   │                                      • 错误处理: 分配失败返回ERROR
│   ├── IF_Mem_Chunk.f90               → 内存块管理（163 行，8 个子程序：Alloc/Free/Register/Query）
│   │                                      【子程序清单】
│   │                                      • IF_Mem_Chunk_Alloc(In size, Out chunk_id, Out status) → 分配内存块
│   │                                      • IF_Mem_Chunk_Free(In chunk_id, Out status) → 释放内存块
│   │                                      • IF_Mem_Chunk_Register(In chunk_id, In tag, Out status) → 注册块
│   │                                      • IF_Mem_Chunk_Query(In chunk_id, Out size, Out tag, Out found) → 查询块
│   │                                      • IF_Mem_Chunk_GetPtr(In chunk_id, Out ptr, Out status) → 获取块指针
│   │                                      • IF_Mem_Chunk_Resize(In chunk_id, In new_size, Out status) → 调整块大小
│   │                                      • IF_Mem_Chunk_SyncToDevice(In chunk_id, Out status) → 同步到设备
│   │                                      • IF_Mem_Chunk_SyncFromDevice(In chunk_id, Out status) → 从设备同步
│   │                                      【接口契约】
│   │                                      • 块ID: 全局唯一整数,O(1)查找
│   │                                      • 设备同步: CUDA-aware,支持GPU内存管理
│   │                                      • 线程安全: 是
│   ├── IF_Mem_Serial.f90              → 内存序列化（756 行，24 个子程序：Serialize/Deserialize/ByteCopy）
│   │                                      【子程序清单】
│   │                                      • IF_Mem_Serial_Serialize(In obj, Out buffer, Out nbytes, Out status) → 序列化对象
│   │                                      • IF_Mem_Serial_Deserialize(In buffer, In nbytes, Out obj, Out status) → 反序列化
│   │                                      • IF_Mem_Serial_ByteCopy(In src, Out dst, In nbytes, Out status) → 字节拷贝
│   │                                      • IF_Mem_Serial_Pack(In obj, Out packed_size, Out status) → 打包对象
│   │                                      • IF_Mem_Serial_Unpack(In buffer, Out obj, Out status) → 解包对象
│   │                                      • IF_Mem_Serial_ComputeChecksum(In buffer, In nbytes, Out checksum) → 计算校验和
│   │                                      • IF_Mem_Serial_VerifyChecksum(In buffer, In nbytes, In expected, Out is_valid) → 校验校验和
│   │                                      【接口契约】
│   │                                      • 格式: 二进制序列化,平台无关(endian转换)
│   │                                      • 版本头: 支持多版本兼容
│   │                                      • 校验和: CRC32/MD5可选
│   │                                      • 线程安全: 是(序列化上下文互斥)
│   ├── IF_Mem_ThreadSlab.f90          → 线程 Slab（291 行，11 个子程序：ThreadAlloc/ThreadFree）
│   │                                      【子程序清单】
│   │                                      • IF_Mem_ThreadSlab_Init(In slab_size, Out status) → 初始化线程Slab
│   │                                      • IF_Mem_ThreadSlab_Finalize(Out status) → 释放线程Slab
│   │                                      • IF_Mem_ThreadSlab_Alloc(In thread_id, In size, Out ptr, Out status) → 线程局部分配
│   │                                      • IF_Mem_ThreadSlab_Free(In thread_id, In ptr, Out status) → 线程局部释放
│   │                                      • IF_Mem_ThreadSlab_GetStats(In thread_id, Out alloc_count, Out total_bytes) → 线程统计
│   │                                      • IF_Mem_ThreadSlab_ClearThread(In thread_id, Out status) → 清除线程局部内存
│   │                                      • IF_Mem_ThreadSlab_GetGlobalStats(Out total_threads, Out total_bytes) → 全局统计
│   │                                      【接口契约】
│   │                                      • 无锁分配: 线程局部内存,无竞争
│   │                                      • 自动回收: 线程结束时自动清理
│   │                                      • 线程安全: 是(线程局部存储)
│   ├── IF_Mem_WS.f90                  → 工作空间管理（940 行，44 个子程序：WS_Create/Destroy/Get/Resize/Reuse）
│   │                                      【子程序清单】
│   │                                      • IF_WS_Create(In ws_name, In max_size, Out ws_handle, Out status) → 创建工作空间
│   │                                      • IF_WS_Destroy(In ws_handle, Out status) → 销毁工作空间
│   │                                      • IF_WS_Get(In ws_handle, In required_size, Out ptr, Out status) → 获取工作空间
│   │                                      • IF_WS_Resize(In ws_handle, In new_size, Out status) → 调整工作空间
│   │                                      • IF_WS_Reuse(In ws_handle, Out status) → 重用工作空间(清零)
│   │                                      • IF_WS_GetStats(In ws_handle, Out current_size, Out peak_size, Out alloc_count) → 获取统计
│   │                                      • IF_WS_PrintReport(In ws_handle, Out status) → 打印报告
│   │                                      • IF_WS_RegisterPersistent(In name, In size, Out handle, Out status) → 注册持久工作空间
│   │                                      • IF_WS_GetPersistent(In name, Out handle, Out found) → 获取持久工作空间
│   │                                      【接口契约】
│   │                                      • 复用机制: 工作空间在迭代间复用,减少分配开销
│   │                                      • 持久化: 跨Increment持久的工作空间
│   │                                      • 线程安全: 是(工作空间表互斥锁)
│   │                                      • 求解器优化: Solver域专用持久缓冲
│   ├── IF_StructMemPool.f90           → 结构化内存池（7,568 行，86 个子程序，⚠️ 需拆分为 5-6 个子模块）
│   ├── IF_UnstructMemPool.f90         → 非结构化内存池（2,651 行，45 个子程序，⚠️ 需拆分为 3-4 个子模块）
│   └── CONTRACT.md                    → 接口契约文档（101 行）
│
│                                      【架构决策说明】
│                                      • 代码拆分：IF_StructMemPool.f90（7,568 行）需紧急拆分为 6 个子模块
│                                        - IF_Mem_StructCore.f90（~1,200 行）：核心管理器（init/destroy/create_pool/dealloc/lock/unlock/evict_lru/sort_lru）
│                                        - IF_Mem_StructAlloc.f90（~2,200 行）：分配器（alloc_dp/int/char 1D-4D、alloc_struct/class/array、allocate_unified_memory、initialize_*_memory）
│                                        - IF_Mem_StructQuery.f90（~1,200 行）：查询接口（get_*_ptr 24 个、query_struct_mem_block、get_struct_mem_pool_stats）
│                                        - IF_Mem_StructDevice.f90（~1,000 行）：设备内存（smem_map_block_to_device、smem_sync_block、smem_get_device_buffer、check_struct_block_device_mem）
│                                        - IF_Mem_StructSerial.f90（~800 行）：序列化/元数据（register_struct/class_def、add_struct/class_member、finalize_struct/class_def、verify_*_layout）
│                                        - IF_Mem_StructUtils.f90（~1,168 行）：工具函数（calculate_struct_size、compute_member_size、get_*_string、INT_TO_STR、get_timestamp、find_free_block）
│                                      • 代码拆分：IF_UnstructMemPool.f90（2,651 行）需拆分为 4 个子模块
│                                        - IF_Mem_UnstructCore.f90（~600 行）：核心管理器（init/destroy/create_pool/dealloc）
│                                        - IF_Mem_UnstructAlloc.f90（~1,000 行）：分配器（链表/图/哈希表/跳表/队列/邻接表分配）
│                                        - IF_Mem_UnstructQuery.f90（~600 行）：查询接口（get_*_ptr、query_unstruct_mem_block、get_unstruct_mem_pool_stats）
│                                        - IF_Mem_UnstructUtils.f90（~451 行）：工具函数（calculate_size、find_free_block、工具函数）
│                                      • 命名规范：IF_Mem_WS.f90（940 行）接近阈值，建议后续优化
│                                      • 热路径保障：Arena 模式确保热路径零 ALLOCATE（O(1) 分配/重置）
│
├── Monitor/                            [监控]
│                                      【设计意图】
│                                      • 定位：UFC 全栈运行时监控与可观测性基础设施，统一的性能计数、指标收集和追踪中心
│                                      • 职责：性能计数器、指标收集、追踪 Span、四链监控（理论/逻辑/计算/数据）
│                                      • 边界：仅负责监控数据收集和统计；复杂性能分析由上层工具处理
│                                      • 依赖：L1_IF 最底层，依赖 IF_Err_API（错误处理）、IF_Monitor_Types（类型定义）
│                                      
│                                      【核心功能】
│                                      • 域容器管理：IF_Monitor_Domain 初始化/释放、全局实例访问（3 个子程序）
│                                      • 指标收集：命名指标记录、定时器/计数器统计（CollectMetrics）
│                                      • 追踪记录：数据链路追踪、校验和验证、导出追踪数据（RecordTrace/ExportTrace）
│                                      • Span 管理：追踪 Span 开始/结束、Span ID 生成（StartSpan/EndSpan）
│                                      • 四链监控：理论链/逻辑链/计算链/数据链监控记录与报告（ChainMonitor_*）
│                                      • 日志统计：错误/警告/信息/调试计数、各域时间统计（LogState）
│                                      • 性能指标：定时器值、计数器值、命名指标数组（MetricsState）
│                                      • 监控配置：日志级别、输出目标、时间戳、指标/追踪开关（MonitorDesc）
│
│   ├── IF_Mon_Core.f90                → 监控核心（202 行，13 个子程序：Init/Finalize/CollectMetrics/RecordTrace/Span/ChainMonitor）
│   │                                      【子程序清单】
│   │                                      • IF_Mon_Domain_Init(InOut this, Out status) → 初始化监控域
│   │                                      • IF_Mon_Domain_Finalize(InOut this, Out status) → 释放监控域
│   │                                      • IF_Mon_CollectMetrics(InOut this, In metric_name, In value, Out status) → 收集指标
│   │                                      • IF_Mon_RecordTrace(InOut this, In trace_name, In data, Out status) → 记录追踪
│   │                                      • IF_Mon_StartSpan(InOut this, In span_name, Out span_id, Out status) → 开始Span
│   │                                      • IF_Mon_EndSpan(InOut this, In span_id, Out status) → 结束Span
│   │                                      • IF_Mon_ChainMonitor_Theory(InOut this, In chain_name, In data, Out status) → 理论链监控
│   │                                      • IF_Mon_ChainMonitor_Logic(InOut this, In chain_name, In data, Out status) → 逻辑链监控
│   │                                      • IF_Mon_ChainMonitor_Compute(InOut this, In chain_name, In data, Out status) → 计算链监控
│   │                                      • IF_Mon_ChainMonitor_Data(InOut this, In chain_name, In data, Out status) → 数据链监控
│   │                                      • IF_Mon_GetMetrics(In this, Out metrics_state) → 获取指标状态
│   │                                      • IF_Mon_GetTraces(In this, Out traces) → 获取追踪数据
│   │                                      【接口契约】
│   │                                      • 四链监控: 理论/逻辑/计算/数据链独立追踪
│   │                                      • Span嵌套: 支持层级Span,用于性能剖析
│   │                                      • 线程安全: 是(原子计数器)
│   ├── IF_Monitor_Mgr.f90             → 监控管理器（58 行，2 个子程序：Mgr_Init/Mgr_Finalize）
│   │                                      【子程序清单】
│   │                                      • IF_Monitor_Mgr_Init(Out status) → 初始化监控管理器
│   │                                      • IF_Monitor_Mgr_Finalize(Out status) → 释放监控管理器
│   │                                      【接口契约】
│   │                                      • 单例模式: 全局唯一监控管理器
│   │                                      • 线程安全: 是
│   ├── IF_Monitor_Types.f90           → 监控类型定义（98 行，5 个 TYPE：MonitorDesc/MonitorCtx/MonitorState/LogState/MetricsState/TraceState）
│   │                                      【类型定义】
│   │                                      • MonitorDesc: name,enabled,output_target,log_level,metrics_enabled,tracing_enabled
│   │                                      • MonitorCtx: timer_state,counter_state,metric_values,nested_spans
│   │                                      • MonitorState: is_initialized,total_metrics,active_spans
│   │                                      • LogState: log_counts(6),last_log_level,last_module
│   │                                      • MetricsState: metric_names,metric_values,timestamps
│   │                                      • TraceState: trace_ids,trace_names,durations,parent_spans
│   │                                      【接口契约】
│   │                                      • 状态管理: 监控上下文封装
│   │                                      • 线程安全: 是(原子操作)
│   └── CONTRACT.md                    → 接口契约文档（101 行）
│
│                                      【架构决策说明】
│                                      • 代码量合理：总计 358 行，所有文件均 < 2,000 行阈值
│                                      • 模块内聚优秀：职责清晰（Core=核心逻辑/Mgr=管理器/Types=类型定义）
│                                      • 命名规范：统一 IF_ 前缀，符合三级命名体系
│                                      • 四链监控：支持理论/逻辑/计算/数据链独立监控与报告
│
├── Parallel/                           [⭐ 并行计算]
│                                      【设计意图】
│                                      • 定位：UFC 全栈并行计算基础设施，统一的线程工作空间管理和并行原语封装中心
│                                      • 职责：线程工作空间管理、并行原语封装（原子操作/临界区）、OpenMP 集成、数据归约
│                                      • 边界：仅负责线程级并行管理；复杂 MPI 分布式并行由上层处理
│                                      • 依赖：L1_IF 最底层，依赖 IF_Mem_Mgr（内存池）、IF_Err_API（错误处理）、IF_Prec（精度定义）
│                                      
│                                      【核心功能】
│                                      • 线程工作空间管理：全局池→线程切片→局部数组三级层次、预分配策略、线程 ID 管理（13 个子程序）
│                                      • 并行原语封装：原子加法（实型/整型）、临界区保护、线程安全同步（4 个子程序）
│                                      • OpenMP 集成：PARALLEL DO 自动线程同步、ATOMICS 原子操作封装、CRITICAL 临界区管理
│                                      • 数组访问：线程私有数组获取（Real/Int/Logical 1D/2D）、数组注册/查询（9 个子程序）
│                                      • 数据归约：局部数组聚合到全局数组、并行结果汇总（AggregateReal1D）
│                                      • 动态分配：局部数组动态分配/释放、内存池集成（2 个子程序）
│                                      • 线程上下文：设置/获取当前线程 ID、线程状态管理（2 个子程序）
│                                      • 类型系统：ThreadWorkspace/ThreadWS/ThreadWS_ArrayInfo 类型定义、TBP 方法绑定（7 个 TBP）
│
│   ├── IF_ThreadWS_Core.f90           → 线程工作空间核心（305 行，11 个子程序：Init/Destroy/GetLocalArray/Atomic/Critical/Aggregate）
│   │                                      【子程序清单】
│   │                                      • IF_ThreadWS_Init(In num_threads, In max_local_size, Out status) → 初始化线程WS
│   │                                      • IF_ThreadWS_Finalize(Out status) → 释放线程WS
│   │                                      • IF_ThreadWS_GetLocalArray_Real1D(In thread_id, In array_name, Out array_ptr, Out status) → 获取局部实数数组
│   │                                      • IF_ThreadWS_GetLocalArray_Int1D(In thread_id, In array_name, Out array_ptr, Out status) → 获取局部整数数组
│   │                                      • IF_ThreadWS_AtomicAdd_Real(InOut target, In value, Out old_value) → 原子加法(实数)
│   │                                      • IF_ThreadWS_AtomicAdd_Int(InOut target, In value, Out old_value) → 原子加法(整数)
│   │                                      • IF_ThreadWS_Critical_Begin(InOut this) → 临界区开始
│   │                                      • IF_ThreadWS_Critical_End(InOut this) → 临界区结束
│   │                                      • IF_ThreadWS_Aggregate_Real1D(In array_name, Out global_array, Out status) → 聚合实数数组(支持ADD/MAX/MIN)
│   │                                      • IF_ThreadWS_RegisterArray(In array_name, In size, In data_type, Out status) → 注册命名数组到所有线程
│   │                                      • IF_ThreadWS_ResetAll(InOut thread_ws, Out status) → 清零所有线程工作区(每迭代前调用)
│   │                                      【接口契约】
│   │                                      • 三级层次: Global Pool → Thread Slice → Local Arrays
│   │                                      • 预分配: Init时预分配所有线程局部数组
│   │                                      • 线程安全: 是(原子操作+临界区)
│   │                                      • SMP贯通(v4.0): GetLocalArray/AggregateReal1D由STUB补全为实际实现
│   ├── IF_ThreadWS_API.f90            → 线程工作空间 API（168 行，2 个子程序：AllocLocal/FreeLocal）
│   │                                      【子程序清单】
│   │                                      • IF_ThreadWS_AllocLocal(In size, In data_type, Out ptr, Out status) → 分配线程局部内存
│   │                                      • IF_ThreadWS_FreeLocal(In ptr, Out status) → 释放线程局部内存
│   │                                      【接口契约】
│   │                                      • 便捷API: 封装底层Core接口
│   │                                      • 线程安全: 是
│   ├── IF_ThreadWS_Types.f90          → 线程类型定义（243 行，3 个 TYPE + 7 个 TBP 方法绑定）
│   │                                      【类型定义】
│   │                                      • ThreadWorkspace: num_threads,max_local_bytes,is_initialized,thread_slices
│   │                                      • ThreadWS: global_pool,local_arrays,atomic_counters
│   │                                      • ThreadWS_ArrayInfo: name,size,data_type,offset,is_allocated
│   │                                      【TBP方法】
│   │                                      • Init(nthreads,max_local_size) → 初始化线程WS
│   │                                      • Finalize() → 释放线程WS
│   │                                      • GetReal1D/GetReal2D/GetInt1D/GetInt2D → 获取线程局部数组切片 (v4.0实现)
│   │                                      • GetLocalArray(thread_id,array_name) → 获取局部数组
│   │                                      • AtomicAdd(target,value) → 原子加法
│   │                                      • CriticalBegin() → 临界区开始
│   │                                      • CriticalEnd() → 临界区结束
│   │                                      • Aggregate(array_name,global_array) → 结果聚合
│   │                                      【接口契约】
│   │                                      • 类型封装: 线程WS抽象
│   │                                      • 线程安全: 是
│   │                                      • SMP贯通(v4.0): Get*1D/2D由STUB补全为数组切片拷贝
│   └── CONTRACT.md                    → 接口契约文档（509 行）
│
│                                      【架构决策说明】
│                                      • 代码量合理：总计 716 行，所有文件均 < 2,000 行阈值
│                                      • 模块内聚优秀：职责清晰（Core=核心逻辑/API=薄适配器/Types=类型定义）
│                                      • 命名规范：统一 IF_ 前缀，符合三级命名体系
│                                      • 三级层次：Global Pool → Thread Slice → Local Arrays
│                                      • 预分配策略：避免运行时动态内存开销，热路径零 ALLOCATE
│                                      • OpenMP 集成：自动线程同步，支持 PARALLEL DO/ATOMIC/CRITICAL
│
├── Precision/                          [⭐ 精度管理]
│                                      【设计意图】
│                                      • 定位：UFC 全栈精度与常量基础设施，统一的精度定义、数值稳定性检查和数学常量中心
│                                      • 职责：精度类型定义（sp/dp/qp/wp）、数值稳定性检查（NaN/Inf/Overflow/Underflow）、数学常量、数值容差
│                                      • 边界：仅提供基础数学常量和精度检查；复杂物理常量由 L4_PH 层提供
│                                      • 依赖：L1_IF 最底层，无其他依赖（被全栈所有层依赖）
│                                      
│                                      【核心功能】
│                                      • 精度类型定义：单精度（sp）、双精度（dp）、四精度（qp）、工作精度（wp）、整型（i4/i8）（5 个 KIND）
│                                      • 数值稳定性检查：NaN 检测、Inf 检测、有限性检查、溢出/下溢检查（6 个函数）
│                                      • 综合稳定性验证：一次性检查 NaN/Inf/Overflow/Underflow、返回错误状态（1 个子程序）
│                                      • 数学常量：PI/E/SQRT_TWO/SQRT_THREE 等 14 个高精度常量（20+ 位精度）
│                                      • 数值容差：TINY/EPS/SMALL/TOLERANCE/LARGE_TOLERANCE/STRICT_TOLERANCE（6 个容差级别）
│                                      • 基础数值常量：ZERO~TEN 整数常量、HALF/THIRD/QUARTER 等分数常量（15 个常量）
│                                      • 角度转换：度转弧度（DegToRad）、弧度转度（RadToDeg）（2 个函数）
│                                      • 常量访问器：Get_PI/Get_E 函数接口（2 个函数）
│
│   ├── IF_Prec.f90                    → 精度定义与稳定性检查（136 行，7 个子程序：IsNaN/IsInf/IsFinite/CheckOverflow/CheckUnderflow/CheckStability）
│   │                                      【子程序清单】
│   │                                      • IF_Prec_IsNaN(In val, Out is_nan) → NaN检测
│   │                                      • IF_Prec_IsInf(In val, Out is_inf) → Inf检测
│   │                                      • IF_Prec_IsFinite(In val, Out is_finite) → 有限性检查
│   │                                      • IF_Prec_CheckOverflow(In val, Out is_overflow) → 溢出检查
│   │                                      • IF_Prec_CheckUnderflow(In val, Out is_underflow) → 下溢检查
│   │                                      • IF_Prec_CheckStability(In val, Out is_stable, Out status) → 综合稳定性检查
│   │                                      • IF_Prec_GetDefaultWP(Out wp_val) → 获取默认工作精度kind
│   │                                      【接口契约】
│   │                                      • IEEE标准: 使用IEEE_ARITHMETIC模块
│   │                                      • 纯函数: 所有检测函数为PURE
│   │                                      • 线程安全: 是
│   ├── IF_Const.f90                   → 数学常量与容差（124 行，4 个函数：DegToRad/RadToDeg/Get_PI/Get_E + 40+ 个常量）
│   │                                      【子程序清单】
│   │                                      • IF_Const_DegToRad(In deg, Out rad) → 度转弧度
│   │                                      • IF_Const_RadToDeg(In rad, Out deg) → 弧度转度
│   │                                      • IF_Const_Get_PI(Out pi_val) → 获取π
│   │                                      • IF_Const_Get_E(Out e_val) → 获取e
│   │                                      【常量定义】
│   │                                      • 数学常量: PI=3.141592653589793...,E=2.718281828459045...,SQRT2=1.41421356237...
│   │                                      • 容差: EPS=TINY(1.0_wp)*1000,TOLERANCE=1.0E-10_wp,STRICT_TOL=1.0E-14_wp
│   │                                      • 整数常量: ZERO=0,ONE=1,TWO=2,...,TEN=10
│   │                                      • 分数常量: HALF=0.5,THIRD=0.333...,QUARTER=0.25,...
│   │                                      【接口契约】
│   │                                      • 20+位精度: 所有数学常量wp精度(20+位有效数字)
│   │                                      • 纯常量: PARAMETER声明,无运行时开销
│   │                                      • 线程安全: 是
│   └── CONTRACT.md                    → 接口契约文档（108 行）
│
│                                      【架构决策说明】
│                                      • 代码量极精简：总计 260 行，所有文件均远低于 2,000 行阈值
│                                      • 模块内聚优秀：职责清晰（Prec=精度检查/Const=常量定义）
│                                      • 命名规范：统一 IF_ 前缀，符合三级命名体系
│                                      • 全栈依赖基石：L1_IF 最底层，被全栈所有层依赖（无反向依赖）
│                                      • IEEE 标准：使用 IEEE_ARITHMETIC 内置模块确保跨平台一致性
│                                      • 高精度常量：所有数学常量提供 20+ 位精度（wp 类型）
│
├── Registry/                           [⭐ 注册表]
│                                      【设计意图】
│                                      • 定位：UFC 全栈模型注册表与治理基础设施，统一的模型注册、版本控制、退化检测和审计中心
│                                      • 职责：模型注册/注销、版本管理（语义化版本/回滚）、性能退化检测、审计日志、基准测试
│                                      • 边界：仅负责模型注册与治理；复杂对象生命周期由 L3_MD 处理
│                                      • 依赖：L1_IF 最底层，依赖 IF_Err_API（错误处理）、IF_Prec（精度定义）
│                                      
│                                      【核心功能】
│                                      • 模型注册：模型注册/注销、名称/类型/基准分数记录（RegisterModel/UnregisterModel）
│                                      • 版本管理：语义化版本控制、版本历史追踪、版本回滚（IncrementModelVersion/RollbackModelVersion/GetModelHistory）
│                                      • 性能监控：基准测试、退化检测、阈值比较（BenchmarkModel/CheckModelDegradation）
│                                      • 审计日志：操作记录、版本变更追踪、审计查询与报告导出（ModelAuditLog/QueryAuditLog/ExportAuditReport）
│                                      • 告警机制：性能退化告警、消息通知（AlertDegradation）
│                                      • 治理初始化：全局注册表初始化/释放（Governance_Init/Governance_Finalize）
│                                      • 查询接口：按名称查询模型注册表（QueryModelRegistry）
│                                      • 类型系统：ModelRegistry/ModelEntry/AuditLogEntry 类型定义（3 个 TYPE）
│
│   ├── IF_Reg_Core.f90                → 注册表核心（343 行，14 个子程序：Register/Unregister/Version/Degradation/Audit/Governance）
│   │                                      【子程序清单】
│   │                                      • IF_Reg_Init(Out status) → 初始化注册表
│   │                                      • IF_Reg_Finalize(Out status) → 释放注册表
│   │                                      • IF_Reg_RegisterModel(In model_name, In model_type, In base_score, Out model_id, Out status) → 注册模型
│   │                                      • IF_Reg_UnregisterModel(In model_id, Out status) → 注销模型
│   │                                      • IF_Reg_GetModel(In model_id, Out model_entry, Out found) → 获取模型
│   │                                      • IF_Reg_IncrementVersion(In model_id, Out new_version, Out status) → 增加版本
│   │                                      • IF_Reg_RollbackVersion(In model_id, In target_version, Out status) → 回滚版本
│   │                                      • IF_Reg_GetHistory(In model_id, Out history, Out count) → 获取版本历史
│   │                                      • IF_Reg_BenchmarkModel(In model_id, In benchmark_data, Out score, Out status) → 基准测试
│   │                                      • IF_Reg_CheckDegradation(In model_id, Out is_degraded, Out status) → 检查退化
│   │                                      • IF_Reg_LogAudit(In model_id, In operation, In details, Out status) → 审计日志
│   │                                      • IF_Reg_Governance_Init(Out status) → 治理初始化
│   │                                      • IF_Reg_Governance_Finalize(Out status) → 治理释放
│   │                                      • IF_Reg_QueryModels(In filter, Out model_list, Out count) → 查询模型
│   │                                      【接口契约】
│   │                                      • 容量限制: 1000模型/10000审计/100版本历史
│   │                                      • 语义版本: X.Y.Z格式
│   │                                      • 线程安全: 是(读写锁)
│   └── CONTRACT.md                    → 接口契约文档（112 行）
│
│                                      【架构决策说明】
│                                      • 代码量合理：总计 343 行，所有文件均 < 2,000 行阈值
│                                      • 模块内聚优秀：单文件实现所有注册表功能，职责清晰
│                                      • 命名规范：统一 IF_ 前缀，符合三级命名体系
│                                      • 容量限制：最多 1,000 个模型、10,000 条审计记录、100 个版本历史
│                                      • 语义化版本：采用 X.Y.Z 格式（如 1.0.0）
│                                      • 审计完整性：每次操作记录 old_version/new_version/performance_delta
│
├── Symbol/                             [⭐ FEM符号表]
│                                      【设计意图】
│                                      • 定位：UFC 全栈 FEM 常量统一符号表，跨层级的 BC/Load/Contact/DOF 常量定义中心
│                                      • 职责：边界条件常量、约束类型、DOF 索引、载荷类型、接触公式、幅值插值、热路径预分配尺寸
│                                      • 边界：仅提供编译时常量（PARAMETER）；复杂符号推理由上层处理
│                                      • 依赖：L1_IF 最底层，依赖 IF_Prec（精度定义）
│                                      
│                                      【核心功能】
│                                      • BC 族常量：位移/速度/加速度/电势/温度/质量流量（MD_BC_FIELD_* 6 个常量）
│                                      • 约束类型常量：固定/指定位移/对称/反对称/周期性（RT_BC_CONSTRAIN_* 5 个常量）
│                                      • BC 映射：BC 场到约束类型的编译时映射数组（BC_FIELD_TO_CONSTRAIN 6 元素数组）
│                                      • DOF 索引常量：UX/UY/UZ/RX/RY/RZ/TEMP（7 个 DOF 常量）
│                                      • 载荷类型常量：集中力/压力/温度/体力（RT_LOAD_* 4 个常量）
│                                      • 幅值插值常量：线性/样条/阶跃/表格（RT_AMP_INTERP_* 4 个常量）
│                                      • 接触公式常量：罚函数/拉格朗日/增强拉格朗日（RT_CONTACT_FORM_* 3 个常量）
│                                      • 接触状态常量：开放/闭合/滑动/粘着（RT_PAIR_* 4 个常量）
│                                      • 摩擦模型常量：无摩擦/库仑摩擦/粘性摩擦（RT_FRICTION_* 3 个常量）
│                                      • 热路径预分配尺寸：最大接触对/积分点/单元节点/单元 DOF/全局 DOF（5 个常量）
│                                      • 向后兼容别名：旧版常量别名（BC_FAMILY_*/BC_*/LOAD_*/AMP_* 13 个别名，v2.0 移除）
│
│   ├── UFC_FEM_Symbols.f90            → FEM 符号表（198 行，1 个子程序：Init + 50+ 个常量）⚠️ 需重命名为 IF_Sym_Core.f90
│   │                                      【子程序清单】
│   │                                      • UFC_FEM_Symbols_Init(Out status) → 初始化符号表(保留向后兼容)
│   │                                      【常量定义】
│   │                                      • BC族: MD_BC_FIELD_DISP=1,MD_BC_FIELD_VELOCITY=2,MD_BC_FIELD_ACCELERATION=3...
│   │                                      • 约束类型: RT_BC_CONSTRAIN_FIXED=1,RT_BC_CONSTRAIN_DISP=2,RT_BC_CONSTRAIN_SYMM=3...
│   │                                      • DOF索引: RT_DOF_UX=1,RT_DOF_UY=2,RT_DOF_UZ=3,RT_DOF_RX=4...
│   │                                      • 载荷类型: RT_LOAD_CONCENTRATED=1,RT_LOAD_PRESSURE=2,RT_LOAD_TEMPERATURE=3...
│   │                                      • 幅值插值: RT_AMP_INTERP_LINEAR=1,RT_AMP_INTERP_SMOOTH=2,RT_AMP_INTERP_STEP=3...
│   │                                      • 接触公式: RT_CONTACT_FORM_PENALTY=1,RT_CONTACT_FORM_LAGRANGE=2...
│   │                                      • 热路径尺寸: MAX_CONTACT_PAIRS=10000,MAX_INT_POINTS=100...
│   │                                      【接口契约】
│   │                                      • 编译时常量: PARAMETER声明,零运行时开销
│   │                                      • 跨层映射: BC_FIELD_TO_CONSTRAIN数组实现MD→RT编译时映射
│   │                                      • v2.0弃用: 13个别名将移除
│   │                                      【⚠️ 重命名要求】
│   │                                      • 目标文件名: IF_Sym_Core.f90 (非标准IF_Symbol_Core.f90)
│   │                                      • 原因: UFC_FEM_Symbols迁移的正式授权特例命名
│
│                                      【架构决策说明】
│                                      • 代码量极精简：总计 198 行，远低于 2,000 行阈值
│                                      • 模块内聚优秀：单文件实现所有 FEM 常量定义
│                                      • 命名规范：⚠️ 文件使用 UFC_ 前缀，需重命名为 IF_Sym_Core.f90 符合 L1_IF 规范
│                                      • 编译时常量：所有常量使用 PARAMETER，零运行时开销
│                                      • 跨层映射：BC_FIELD_TO_CONSTRAIN 数组实现 MD 层到 RT 层的编译时映射
│                                      • 向后兼容：提供 13 个旧版别名，计划在 v2.0 移除
│
└── LayerContainer/                     [⭐ L1层容器]
│                                      【设计意图】
│                                      • 定位：UFC L1_IF 层聚合容器，统一的 7 个基础设施域实例管理和生命周期控制中心
│                                      • 职责：域容器聚合、依赖顺序初始化、逆序释放、全局访问入口
│                                      • 边界：仅负责域容器聚合和生命周期管理；具体域功能由各域自己实现
│                                      • 依赖：L1_IF 最顶层，依赖所有 7 个域（Error/Log/Monitor/Memory/IO/Persist/Base/Registry）
│                                      
│                                      【核心功能】
│                                      • 域容器聚合：7 个域容器实例聚合（Error/Log/Monitor/IO/Memory/Persist/Base）
│                                      • 依赖顺序初始化：按依赖拓扑序初始化（1-Error 2-Log 2a-Monitor 3-Memory 4-IO 5-Persist 6-Base 7-Registry）
│                                      • 逆序释放：严格按初始化逆序释放（7-Registry 6-Base 5-Persist 4-IO 3-Memory 2a-Monitor 2-Log 1-Error）
│                                      • 全局访问入口：UFC_GlobalContainer.if_layer 字段访问
│                                      • 监控指针管理：Monitor 域使用全局实例指针（g_if_monitor_domain）
│                                      • 初始化参数：线程数（nThreads）、工作目录（workDir）
│                                      • 状态管理：initialized 标志、幂等初始化（重复调用先 Finalize）
│
│   ├── IF_L1_LayerContainer_Core.f90  → L1层容器核心（150 行，2 个子程序：Init/Finalize + 1 个 TYPE）
│   │                                      【子程序清单】
│   │                                      • IF_L1_Init(In nThreads, In workDir, Out status) → L1层初始化
│   │                                      • IF_L1_Finalize(Out status) → L1层释放
│   │                                      • IF_L1_GetVersion(Out version) → 获取版本
│   │                                      • IF_L1_GetSummary(Out summary) → 获取摘要
│   │                                      【接口契约】
│   │                                      • 初始化顺序: 1-Error 2-Log 2a-Monitor 3-Memory 4-IO 5-Persist 6-Base 7-Registry
│   │                                      • 释放顺序: 严格逆序(7-Registry 6-Base 5-Persist 4-IO 3-Memory 2a-Monitor 2-Log 1-Error)
│   │                                      • 幂等初始化: 重复调用先Finalize再Init
│   │                                      • 线程安全: 是(互斥锁保护)
│   │                                      • 全局访问: UFC_GlobalContainer%if_layer字段
│
│                                      【架构决策说明】
│                                      • 代码量极精简：总计 150 行，远低于 2,000 行阈值
│                                      • 模块内聚优秀：单文件实现所有域容器聚合和生命周期管理
│                                      • 命名规范：统一 IF_ 前缀，符合三级命名体系
│                                      • 依赖顺序：严格按依赖拓扑序初始化，逆序释放（Finalize 依赖逆序释放约束）
│                                      • 7 个域：Error/Log/Monitor/IO/Memory/Persist/Base/Registry（Precision 和 Symbol 为纯常量，不纳入容器）
│                                      • Monitor 特殊处理：使用全局实例指针而非独立容器实例

└── [✅ Config 域评估结论: 不归入 L1_IF]
│                                      【设计意图评估】
│                                      • 原假设：L1_IF 层提供配置文件解析基础设施（INI/XML/JSON/YAML）
│                                      • 实际情况：L6_AP 层已实现完整 Config 域（AP_Cfg_Core.f90、AP_Config_Domain_Core.f90）
│                                      • 职责分离：L6_AP 负责应用层配置管理（AI 开关/资源限制/治理配置）
│                                      • L1_IF 定位：仅提供基础键值对读取（归入 Base 域）
│                                      
│                                      【决策依据】
│                                      • L6_AP Config 域已实现：配置加载、资源限制、AI 模型注册、审计日志（2 个文件，472 行）
│                                      • L1_IF 无需重复实现：复杂配置解析由 L6_AP 处理，L1_IF 仅提供简单 I/O
│                                      • 依赖倒置：L6_AP Config 依赖 L1_IF（IF_Prec/IF_Err_API），而非相反
│                                      • 架构清晰：L1_IF 负责基础设施，L6_AP 负责应用配置
│                                      
│                                      【L1_IF Base 域已包含配置能力】
│                                      • IF_DeviceManager.f90：设备配置常量（Device Configuration Constants）
│                                      • IF_Base_SymTbl.f90：符号表配置（Core Configuration Constants）
│                                      • 简单键值对读取：通过 L1_IF IO 域实现（IF_IO_Core.f90）
│                                      
│                                      【最终决策】
│                                      ❌ L1_IF 不独立 Config 域
│                                      ✅ L6_AP Config 域已覆盖应用层配置需求
│                                      ✅ L1_IF Base 域提供基础配置常量
│                                      ✅ L1_IF IO 域提供简单文件读取能力
│
│                                      【L6_AP Config 域参考】
│                                      • AP_Cfg_Core.f90（196 行）：配置加载/资源限制/AI 模型注册
│                                      • AP_Config_Domain_Core.f90（196 行）：配置域容器
│                                      • CONTRACT.md（122 行）：接口契约
│                                      • 核心功能：配置解析、AI 开关、资源限制、治理配置、审计日志
│                                      • 配置层级：Global Config → Job Config → Step Config
│                                      • AI 配置：AI 开关/模型选择/资源分配（GPU/内存）
```

**L1_IF 统计**: 11 域 | 1 层容器 | 50+ 文件 | TYPE策略: **统一合并 `_Types.f90`（按需 USE）**

### L1_IF 域级完备性评估

| 域 | 当前文件数 | 完备性 | Phase 3-4 规划 |
|---|-----------|--------|----------------|
| **AI** | 1 | ⚠️ 待扩展 | **Phase 3**: 扩展推理引擎、模型加载、张量运算 (5+文件) |
| **Base** | 10 | ✅ 完整 | 保持现状 |
| **Error** | 7 | ✅ 完整 | 保持现状 |
| **IO** | 13 | ✅ 完整 | 保持现状 |
| **Log** | 6 | ✅ 完整 | 保持现状 |
| **Memory** | 10 | ✅ 完整 | **Phase 4**: 补充字符串/结构体/变长对象分配支持 |
| **Monitor** | 5 | ✅ 完整 | **Phase 3**: 补充高精度计时子域 (3文件) |
| **Parallel** | 5 | ✅ 完整 | 保持现状 (WS=Workspace工作空间) |
| **Precision** | 2 | ✅ 完整 | **Phase 2**: 已合并 IF_Prec + IF_Prec_Types |
| **Registry** | 2 | ⚠️ 偏少 | **Phase 3**: 补充 State/Algo 类型 (2文件) |
| **Symbol** | 1 | ⚠️ 待扩展 | **Phase 3**: 扩展应力/应变/刚度符号族 (5+文件), **已统一IF_前缀** |
| **LayerContainer** | 1 | ✅ 完整 | 保持现状 (职责单一) |
| **Config** (候选) | 0 | ❌ 缺失 | **Phase 4评估**: 全局配置解析 (INI/XML/JSON) |

**评估结论**:
- ✅ **短期 (Phase 2)**: 补充 Precision/Types, Registry/State+Algo, Symbol扩展
- ⏳ **中期 (Phase 3)**: AI域扩展、Monitor计时子域、Registry完善
- 🔍 **长期 (Phase 4)**: 评估Config域必要性（若L6_AP配置需求复杂则独立，否则归入Base）

---

## 三、L2_NM — 数值算法层

```text
L2_NM/
├── Base/                                 [基础算法]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层基础算法基础设施，统一的数值计算工具、类型定义和求解器配置中心
│                                      • 职责：数值工具函数（点积/叉积/范数）、精度转换、求解器配置类型（线性/非线性/特征值/时间积分/预条件）、错误码、常量定义
│                                      • 边界：仅提供基础数值算法和配置类型；复杂求解器实现由 Solver/LinearSolver/NonlinearSolver 等域处理
│                                      • 依赖：L2_NM 最底层，依赖 L1_IF（IF_Prec/IF_Err_API），被 L2_NM 所有其他域依赖
│                                      
│                                      【核心功能】
│                                      • 域容器管理：NM_Base_Domain 初始化/释放、详细级别设置、错误码描述、摘要查询（5 个子程序）
│                                      • 向量范数计算：L1/L2/无穷范数、矩阵 Frobenius 范数、向量归一化（5 个纯函数）
│                                      • 向量工具函数：快速点积、3D 叉积、三重积、向量夹角计算（4 个纯函数）
│                                      • 精度转换：DP→SP/SP→DP 数组转换、内存分配/释放（2 个子程序）
│                                      • 求解器配置类型：线性求解器（Direct/CG/GMRES/BiCGSTAB）、非线性求解器（NR/ModNR/Quasi/ArcLength）、特征值求解器（Lanczos/Arnoldi/Subspace）、时间积分（Newmark/HHT/CentralDiff/BackwardEuler）、预条件子（None/Diag/ILU0/ILUT/AMG）
│                                      • 根控制容器：NM_NumCtrl_Type 聚合所有求解器配置（LinSolv/NLSolv/EigenSolv/TimeInt/Precond）
│                                      • 错误码定义：11 个数值方法错误码（不收敛/奇异/病态/发散/迭代停滞等）
│                                      • 常量定义：求解器类型常量（线性/非线性/特征值/预条件/时间积分）
│                                      • 类型系统：7 个 TYPE（ArcLen/LinSolv/NLSolv/EigenSolv/TimeInt/Precond/NumCtrl）
│
│   ├── NM_Base_Core.f90                → 域容器核心（163 行，5 个子程序：Init/Finalize/SetVerbose/GetErrorCodeDesc/GetSummary）
│   │                                      【子程序清单】
│   │                                      • NM_Base_Init(InOut this, In verbose_level, Out status) → 初始化Base域
│   │                                      • NM_Base_Finalize(InOut this, Out status) → 释放Base域
│   │                                      • NM_Base_SetVerbose(InOut this, In verbose_level, Out status) → 设置详细级别
│   │                                      • NM_Base_GetErrorCodeDesc(In this, In error_code, Out description) → 获取错误码描述
│   │                                      • NM_Base_GetSummary(In this, Out summary) → 获取域摘要
│   │                                      【接口契约】
│   │                                      • 前置条件: IF_Prec已初始化,IF_Err_API可用
│   │                                      • 后置条件: 所有数值工具已就绪
│   │                                      • 线程安全: 是(域容器级别)
│   │                                      • 错误处理: 返回ErrorStatusType
│   ├── NM_Types.f90                    → 类型定义（167 行，7 个 TYPE + 17 个求解器类型常量）
│   │                                      【类型定义】
│   │                                      • NM_LinSolv_Desc: solver_type,precond_type,max_iter,tolerance
│   │                                      • NM_NLSolv_Desc: method,max_iter,tolerance,line_search_enabled
│   │                                      • NM_EigenSolv_Desc: algorithm,max_iter,tolerance,nev
│   │                                      • NM_TimeInt_Desc: scheme,dt_initial,dt_min,dt_max
│   │                                      • NM_Precond_Desc: precond_type,drop_tolerance,fill_factor
│   │                                      • NM_ArcLen_Desc: arc_length_method,load_factor_initial,limit_load_factor
│   │                                      • NM_NumCtrl_Type: 根控制容器,聚合所有求解器配置
│   │                                      【常量定义】
│   │                                      • 求解器类型: NM_LINEAR=1,NM_NONLINEAR=2,NM_EIGEN=3,NM_TIMEINT=4
│   │                                      • 线性求解器: NM_DIRECT_LU=1,NM_DIRECT_CHOLESKY=2,NM_ITER_CG=3...
│   │                                      • 非线性方法: NM_NEWTON=1,NM_MODIFIED_NEWTON=2,NM_QUASI_NEWTON=3...
│   │                                      【接口契约】
│   │                                      • 配置集中: NM_NumCtrl_Type被UF_SimData_Type引用
│   │                                      • 线程安全: 是
│   ├── NM_Base_Norms.f90               → 范数计算（92 行，5 个纯函数：Norm_L1/L2/Inf/Fro/Normalize）
│   │                                      【子程序清单】
│   │                                      • NM_Norm_L1(In vec, In n, Out norm) → L1范数 Σ|vi|
│   │                                      • NM_Norm_L2(In vec, In n, Out norm) → L2范数 sqrt(Σvi²)
│   │                                      • NM_Norm_Inf(In vec, In n, Out norm) → 无穷范数 max|vi|
│   │                                      • NM_Norm_Frobenius(In mat, In m, In n, Out norm) → Frobenius范数
│   │                                      • NM_Normalize(InOut vec, In n, Out norm) → 向量归一化
│   │                                      【接口契约】
│   │                                      • 纯函数: PURE声明,零副作用,支持SIMD优化
│   │                                      • BLAS封装: 底层调用DNRM2/DASUM
│   │                                      • 线程安全: 是(无共享状态)
│   ├── NM_Base_Utils.f90               → 工具函数（68 行，4 个纯函数：DotProduct/CrossProduct/TripleProduct/AngleBetween）
│   │                                      【子程序清单】
│   │                                      • NM_DotProduct(In v1, In v2, In n, Out dot) → 向量点积 Σvivi
│   │                                      • NM_CrossProduct(In v1, In v2, Out cross) → 3D向量叉积 v1×v2
│   │                                      • NM_TripleProduct(In v1, In v2, In v3, Out triple) → 三重积 v1·(v2×v3)
│   │                                      • NM_AngleBetween(In v1, In v2, Out angle_rad) → 向量夹角(弧度)
│   │                                      【接口契约】
│   │                                      • 纯函数: PURE声明,零副作用
│   │                                      • BLAS封装: 底层调用DDOT
│   │                                      • 数值稳定: 使用atan2防止NaN
│   │                                      • 线程安全: 是
│   ├── NM_Precision_Convert.f90        → 精度转换（73 行，2 个子程序：DP_to_SP/SP_to_DP）
│   │                                      【子程序清单】
│   │                                      • NM_DP_to_SP_Array(In n, In dp_array, Out sp_array, Out status) → DP→SP数组转换
│   │                                      • NM_SP_to_DP_Array(In n, In sp_array, Out dp_array, Out status) → SP→DP数组转换
│   │                                      【接口契约】
│   │                                      • 内存管理: 自动ALLOCATE/FDEALLOCATE
│   │                                      • 精度损失: SP转换可能损失精度,需警告
│   │                                      • 线程安全: 是
│   ├── NM_Base_Constants.f90           → 常量定义（31 行，0 个子程序，17 个常量）
│   ├── NM_Base_ErrCodes.f90            → 错误码（39 行，0 个子程序，11 个错误码）
│   └── CONTRACT.md                     → 接口契约文档（37 行）
│
│                                      【架构决策说明】
│                                      • 代码量合理：总计 633 行，远低于 2,000 行阈值
│                                      • 模块内聚优秀：按职责拆分 7 个文件（域容器/类型/范数/工具/精度/常量/错误码）
│                                      • 命名规范：统一 NM_ 前缀，符合三级命名体系
│                                      • 纯函数优化：Norms/Utils 模块全部使用 PURE FUNCTION，零副作用，支持热路径调用
│                                      • 求解器配置集中：NM_NumCtrl_Type 作为根控制容器，被 UF_SimData_Type 引用
│                                      • 向后兼容：保留 3 个已废弃的特征值求解器常量（NM_EIGEN_*），迁移到 NM_Eigensolver_Types
│                                      • 类型与逻辑分离：NM_Types.f90 仅包含纯数据类型，NM_Base_Core.f90 包含生命周期管理
│
├── Matrix/                               [矩阵运算]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层矩阵运算基础设施，统一的稠密/稀疏矩阵管理、线性代数算法和装配中心
│                                      • 职责：矩阵类型定义（Dense/CSR/CSC）、矩阵运算（乘法/求逆/分解）、稀疏矩阵装配、LAPACK 封装、向量运算、图排序算法
│                                      • 边界：仅提供矩阵运算和线性代数算法；复杂求解器实现由 Solver/LinearSolver 域处理
│                                      • 依赖：L2_NM 核心域，依赖 Base 域（NM_Base_Norms/NM_Base_Utils），被 Solver/Assembly 域依赖
│                                      
│                                      【核心功能】
│                                      • 矩阵类型定义：3 个 TYPE（DenseMatrix/SparseMatrix_CSR/SparseMatrix_CSC）+ 索引/值分离架构（NM_Matrix_Index/NM_Matrix_Values/NM_Matrix）
│                                      • 稠密矩阵运算：矩阵乘法（DGEMM）、加法、稀疏 CSR 乘法、SpMV 转置（6 个子程序）
│                                      • 矩阵数学运算：Cholesky/LU/QR 分解、特征值/特征向量、条件数、3x3 专用优化（7 个子程序）
│                                      • 矩阵分解：LU/Cholesky/QR 分解与求解、行列式计算（7 个子程序）
│                                      • 矩阵求逆：LU 求逆、Cholesky 求逆、Gauss-Jordan 求逆（3 个子程序）
│                                      • 稠密线性代数：Cholesky/QR/SVD/特征值分解、矩阵指数/对数/幕/平方根、条件数、秩估计、广义特征值（18 个子程序）
│                                      • 稀疏矩阵核心：CSR/COO/CSC 转换、SpMV 优化、图排序（AMD/ND/RCM）、图着色、带宽/轮廓分析、装配（27 个子程序）
│                                      • 向量运算：BLAS Level 1 封装（Dot/Axpy/Nrm2/Scal/Copy/Swap/Add/Sub/Mul/Div/Normalize 等）（24 个函数/子程序）
│                                      • 稀疏装配：Triplet/CSR 装配、单元矩阵批量装配、带宽分析、RCM 重排序（10 个子程序）
│                                      • LAPACK 封装：特征值求解/求逆/线性求解/LU 分解/SVD（5 个子程序）
│                                      • 线性代数域容器：NM_LinAlg_Domain_Algo 初始化/释放/格式设置/矩阵向量乘法（4 个子程序）
│
│   ├── NM_Matrix_Types.f90             → 类型定义（293 行，3 个 TYPE + 3 个初始化子程序 + 5 个 TBP）
│   │                                      【类型定义】
│   │                                      • DenseMatrix: m,n,data,is_symmetric,is_allocated
│   │                                      • SparseMatrix_CSR: m,n,nnz,row_ptr,col_ind,values,is_allocated
│   │                                      • SparseMatrix_CSC: m,n,nnz,col_ptr,row_ind,values,is_allocated
│   │                                      【子程序清单】
│   │                                      • DenseMatrix_Init(In m, In n, Out mat, Out status) → 初始化稠密矩阵
│   │                                      • CSRMatrix_Init(In m, In nnz, Out mat, Out status) → 初始化CSR矩阵
│   │                                      • CSCMatrix_Init(In m, In nnz, Out mat, Out status) → 初始化CSC矩阵
│   │                                      【TBP方法】
│   │                                      • Init(m,n) → 矩阵初始化
│   │                                      • Destroy() → 矩阵销毁
│   │                                      • IsAllocated() → 检查是否已分配
│   │                                      • GetDim(m,n) → 获取维度
│   │                                      • SetSymmetric(flag) → 设置对称标志
│   │                                      【接口契约】
│   │                                      • 索引/值分离: Matrix_Index(结构)+Matrix_Values(数据)
│   │                                      • 线程安全: 否(矩阵操作非线程安全)
│   ├── NM_Matrix_Core.f90              → 矩阵核心（1,529 行，索引/值分离架构 + CSR/COO 操作）
│   │                                      【子程序清单】
│   │                                      • NM_Matrix_Create_Dense(In m, In n, Out mat, Out status) → 创建稠密矩阵
│   │                                      • NM_Matrix_Create_CSR(In m, In nnz, Out mat, Out status) → 创建CSR矩阵
│   │                                      • NM_Matrix_Destroy(InOut mat, Out status) → 销毁矩阵
│   │                                      • NM_Matrix_SetValue(InOut mat, In i, In j, In value, Out status) → 设置元素值
│   │                                      • NM_Matrix_GetValue(In mat, In i, In j, Out value, Out status) → 获取元素值
│   │                                      • NM_Matrix_AddValue(InOut mat, In i, In j, In value, Out status) → 累加元素值
│   │                                      • NM_Matrix_Print(In mat, In format, Out status) → 打印矩阵
│   │                                      • NM_Matrix_Copy(In src, Out dst, Out status) → 矩阵拷贝
│   │                                      • NM_Matrix_Zero(InOut mat, Out status) → 矩阵清零
│   │                                      • NM_Matrix_Scale(InOut mat, In scalar, Out status) → 矩阵缩放
│   │                                      • NM_CSR_FromCOO(In n, In nnz, In rows, In cols, In vals, Out csr, Out status) → COO→CSR转换
│   │                                      • NM_COO_FromCSR(In csr, Out n, Out nnz, Out rows, Out cols, Out vals, Out status) → CSR→COO转换
│   │                                      【接口契约】
│   │                                      • 索引/值分离: NM_Matrix_Index(结构)+NM_Matrix_Values(数据)
│   │                                      • 1基索引: Fortran风格,1-based indexing
│   │                                      • 线程安全: 否
│   ├── NM_Matrix_MatMul.f90            → 矩阵乘法（273 行，6 个子程序：DGEMM/Dense/Sparse/SpMV）
│   │                                      【子程序清单】
│   │                                      • NM_MatMul_DGEMM(In alpha, In A, In B, In beta, In C, Out D, Out status) → 稠密矩阵乘法
│   │                                      • NM_MatMul_Dense(In A, In B, Out C, Out status) → 稠密×稠密
│   │                                      • NM_MatMul_Sparse_CSR(In A_csr, In B, Out C, Out status) → CSR×稠密
│   │                                      • NM_SpMV_CSR(In A_csr, In x, Out y, Out status) → CSR矩阵-向量乘
│   │                                      • NM_SpMV_CSR_Transpose(In A_csr, In x, Out y, Out status) → CSRᵀ×向量
│   │                                      • NM_SpMV_CSR_Symmetric(In A_csr, In x, Out y, Out status) → 对称SpMV
│   │                                      【接口契约】
│   │                                      • BLAS调用: 底层调用DGEMM/DSPMV
│   │                                      • 优化SpMV: CSR专用,缓存友好实现
│   │                                      • 线程安全: 否
│   ├── NM_Matrix_Math.f90              → 矩阵数学（473 行，7 个子程序：分解/特征值/条件数/3x3 优化）
│   │                                      【子程序清单】
│   │                                      • NM_Math_Cholesky(In A, Out L, Out status) → Cholesky分解 A=LLᵀ
│   │                                      • NM_Math_LU(In A, Out L, Out U, Out status) → LU分解 A=LU
│   │                                      • NM_Math_QR(In A, Out Q, Out R, Out status) → QR分解 A=QR
│   │                                      • NM_Math_Eigenvalues(In A, Out eigenvalues, Out status) → 特征值计算
│   │                                      • NM_Math_Eigenvectors(In A, Out eigenvalues, Out eigenvectors, Out status) → 特征向量
│   │                                      • NM_Math_ConditionNumber(In A, Out cond, Out status) → 条件数计算
│   │                                      • NM_Math_Mtx_Eigenvalues_3x3(In A, Out evals, Out status) → 3×3矩阵特征值优化
│   │                                      【接口契约】
│   │                                      • LAPACK封装: DPOSV/DGESV/DGEEV
│   │                                      • 3×3优化: 解析公式,避免LAPACK调用
│   │                                      • 线程安全: 否
│   ├── NM_Matrix_Factorization.f90     → 矩阵分解（348 行，7 个子程序：LU/Cholesky/QR/行列式）
│   ├── NM_Matrix_Inversion.f90         → 矩阵求逆（203 行，3 个子程序：LU/Cholesky/Gauss-Jordan）
│   ├── NM_Sparse_Matrix_Core.f90       → 稀疏矩阵核心（1,099 行，27 个子程序：转换/SpMV/排序/装配）
│   ├── NM_Vec_Core.f90                 → 向量运算（378 行，24 个函数/子程序：BLAS Level 1 封装）
│   │                                      【子程序清单】
│   │                                      • NM_Vec_Copy(In n, In x, Out y, Out status) → 向量拷贝 y=x
│   │                                      • NM_Vec_Scale(In n, In alpha, InOut x, Out status) → 向量缩放 x=αx
│   │                                      • NM_Vec_Axpy(In n, In alpha, In x, InOut y, Out status) → y=αx+y
│   │                                      • NM_Vec_Dot(In n, In x, In y, Out dot, Out status) → 点积 x·y
│   │                                      • NM_Vec_Nrm2(In n, In x, Out nrm, Out status) → L2范数
│   │                                      • NM_Vec_Nrm1(In n, In x, Out nrm, Out status) → L1范数
│   │                                      • NM_Vec_Asum(In n, In x, Out asum, Out status) → 绝对值和
│   │                                      • NM_Vec_Swap(In n, InOut x, InOut y, Out status) → 交换 x↔y
│   │                                      • NM_Vec_Add(In n, In x, In y, Out z, Out status) → z=x+y
│   │                                      • NM_Vec_Sub(In n, In x, In y, Out z, Out status) → z=x-y
│   │                                      • NM_Vec_Mul(In n, In x, In y, Out z, Out status) → z=x·y(元素乘)
│   │                                      • NM_Vec_Div(In n, In x, In y, Out z, Out status) → z=x/y(元素除)
│   │                                      • NM_Vec_Normalize(In n, InOut x, Out nrm, Out status) → 归一化
│   │                                      • NM_Vec_Abs(In n, In x, Out y, Out status) → y=|x|
│   │                                      • NM_Vec_Sqrt(In n, In x, Out y, Out status) → y=√x
│   │                                      【接口契约】
│   │                                      • BLAS Level 1: 全部封装Fortran BLAS DDOT/DNRM2/DAXPY等
│   │                                      • 纯函数: 多数为无副作用
│   │                                      • 线程安全: 否(共享BLAS内部状态)
│   ├── NM_LinAlg_Dense_Core.f90        → 稠密线性代数（717 行，18 个子程序：Cholesky/QR/SVD/特征值/矩阵函数）
│   ├── NM_Assem_Sparse.f90             → 稀疏装配（206 行，10 个子程序：Triplet/CSR 装配/带宽分析）
│   ├── NM_LAPACK_Wrappers.f90          → LAPACK 封装（382 行，5 个子程序：EigenSolve/Inverse/LinearSolve/LU/SVD）
│   ├── NM_LinAlg_Domain_Core.f90       → 线性代数域容器（167 行，4 个子程序：Init/Finalize/SetFormat/MatVec）
│   │                                      【子程序清单】
│   │                                      • NM_LinAlg_Init(InOut this, Out status) → 初始化线性代数域
│   │                                      • NM_LinAlg_Finalize(InOut this, Out status) → 释放线性代数域
│   │                                      • NM_LinAlg_SetFormat(InOut this, In format_type, Out status) → 设置矩阵格式
│   │                                      • NM_LinAlg_MatVec(In this, In A, In x, Out y, Out status) → 矩阵-向量乘
│   │                                      【接口契约】
│   │                                      • 域容器: 封装所有线性代数能力
│   │                                      • 格式切换: Dense/CSR/CSC格式支持
│   │                                      • 线程安全: 否
│   ├── CONTRACT.md                     → 接口契约文档（48 行）
│   └── DESIGN_Matrix_FourTypes.md      → 四型设计文档（126 行）
│
│                                      【架构决策说明】
│                                      • 代码量较大：总计 5,961 行，但按职责清晰拆分为 12 个文件
│                                      • 模块内聚优秀：按职责拆分（类型/核心/乘法/数学/分解/求逆/稀疏/向量/稠密线性代数/装配/LAPACK/域容器）
│                                      • 命名规范：统一 NM_ 前缀，符合三级命名体系
│                                      • 索引/值分离架构：NM_Matrix_Index（结构）+ NM_Matrix_Values（数据），支持高效装配
│                                      • 3x3 专用优化：NM_Math_Mtx_Eigenvalues_3x3 针对小矩阵专用优化
│                                      • 图排序算法：AMD（Approximate Minimum Degree）/ND（Nested Dissection）/RCM（Reverse Cuthill-McKee）
│                                      • 图着色算法：距离-2 着色（Distance-2 Coloring），支持 Jacobian 模式自动微分
│                                      • LAPACK 集成：BIND(C) 直接调用 LAPACK，零封装开销
│                                      • BLAS Level 1 封装：NM_Vec_Core 提供 24 个向量运算函数/子程序
│                                      • 向后兼容：保留 UF_CSRMatrix/UF_COOEntry 旧版类型
│
├── Solver/                               [求解器]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层求解器基础设施，统一的直接/迭代求解器、预条件子、SVD 和伴随求解中心
│                                      • 职责：直接求解器（LU/Cholesky）、迭代求解器（GMRES/CG/BiCGSTAB）、预条件子（Jacobi/ILU0/SSOR）、SVD 分解、伴随求解、CSR 转置
│                                      • 边界：仅提供求解器算法；复杂求解策略（非线性/时间积分）由 NonlinSolv/TimeInt 域处理
│                                      • 依赖：L2_NM 核心域，依赖 Matrix 域（稀疏矩阵/向量运算），被 Assembly/Solver 域依赖
│                                      
│                                      【核心功能】
│                                      • 求解器类型定义：LinearSolver/IterativeSolver/Preconditioner/SVDParams 类型（266 行）
│                                      • 直接求解器：LU 分解求解（DGETRF/DGETRS）、Cholesky 分解求解（DPOTRF/DPOTRS）（6 个子程序）
│                                      • 迭代求解器：GMRES/CG/BiCGSTAB 求解、收敛检查、Givens 旋转、上三角求解（6 个子程序/函数）
│                                      • 预条件子：Jacobi/ILU0/SSOR 预条件子构造与应用、ILU0 分解、预条件子释放（7 个子程序）
│                                      • SVD 求解：完整/瘦/部分 SVD 分解、条件数计算、秩估计、伪逆计算（5 个子程序/函数）
│                                      • 伴随求解：GMRES 伴随求解、CG 伴随求解、伴随变量计算、稀疏矩阵向量乘法（4 个子程序）
│                                      • CSR 转置：CSR 矩阵转置、原位转置、对称化（3 个子程序）
│                                      • 子目录：LinSolv/（25 个文件）、NonlinSolv/（6 个文件）、Conv/（6 个文件）、AI/（3 个文件）、Coupling/（1 个文件）
│
│   ├── NM_Solver_Types.f90             → 求解器类型（266 行，4 个 TYPE + 7 个 TBP 方法）
│   │                                      【类型定义】
│   │                                      • LinearSolver: solver_type,max_iter,tolerance,precond_type,stats
│   │                                      • IterativeSolver: krylov_dim,restart_dim,conv_criterion,residual_history
│   │                                      • Preconditioner: precond_type,drop_tolerance,fill_factor,levels
│   │                                      • SVDParams: nu,nv, jobz,tolerances
│   │                                      【TBP方法】
│   │                                      • Init(params) → 求解器初始化
│   │                                      • Setup(A) → 矩阵设置
│   │                                      • Solve(b,x) → 执行求解
│   │                                      • Finalize() → 释放资源
│   │                                      • GetStats(stats) → 获取统计
│   │                                      • Reset() → 重置状态
│   │                                      • SetTolerance(tol) → 设置容差
│   │                                      【接口契约】
│   │                                      • 统一接口: 所有求解器遵循相同TYPE接口
│   │                                      • 线程安全: 否
│   ├── NM_Solver_Direct.f90            → 直接求解器（164 行，6 个子程序：LU/Cholesky/LAPACK BIND(C)）
│   │                                      【子程序清单】
│   │                                      • NM_Direct_LU_Solve(In A, In b, Out x, Out status) → LU分解求解 Ax=b
│   │                                      • NM_Direct_LU_Factorize(In A, Out factors, Out status) → LU分解
│   │                                      • NM_Direct_LU_Solve_Factored(In factors, In b, Out x, Out status) → 使用已有分解求解
│   │                                      • NM_Direct_Cholesky_Solve(In A, In b, Out x, Out status) → Cholesky求解(SPD)
│   │                                      • NM_Direct_Cholesky_Factorize(In A, Out factors, Out status) → Cholesky分解
│   │                                      • NM_Direct_Cholesky_Solve_Factored(In factors, In b, Out x, Out status) → 使用Cholesky分解求解
│   │                                      【接口契约】
│   │                                      • LAPACK调用: DGETRF(分解)/DGETRS(求解)/DPOTRF(Chol)/DPOTRS(Chol求解)
│   │                                      • BIND(C): 直接调用,零封装开销
│   │                                      • 线程安全: 否
│   ├── NM_Solver_Iterative.f90         → 迭代求解器（348 行，6 个子程序/函数：GMRES/CG/BiCGSTAB/收敛检查）
│   │                                      【子程序清单】
│   │                                      • NM_Iter_GMRES(In A, In b, In precon, In max_iter, In tol, Out x, Out stats, Out status) → GMRES求解
│   │                                      • NM_Iter_CG(In A, In b, In precon, In max_iter, In tol, Out x, Out stats, Out status) → CG求解(SPD)
│   │                                      • NM_Iter_BiCGSTAB(In A, In b, In precon, In max_iter, In tol, Out x, Out stats, Out status) → BiCGSTAB求解
│   │                                      • NM_Iter_CheckConvergence(In r_norm, In b_norm, In tol, Out converged) → 收敛检查
│   │                                      • NM_Iter_ApplyPrecon(In precon, In r, Out z, Out status) → 应用预条件子
│   │                                      • NM_Iter_GivensRotation(In h1, In h2, Out c, Out s, Out status) → Givens旋转
│   │                                      【接口契约】
│   │                                      • Krylov子空间: GMRES/CG/BiCGSTAB三种方法
│   │                                      • 预条件支持: 外部预条件子接口
│   │                                      • 收敛历史: 返回残差历史数组
│   ├── NM_Solver_Precond.f90           → 预条件子（167 行，7 个子程序：Jacobi/ILU0/SSOR 构造/应用）
│   │                                      【子程序清单】
│   │                                      • NM_Prec_Jacobi_Build(In A, Out precon, Out status) → Jacobi预条件子构造 M=diag(A)
│   │                                      • NM_Prec_Jacobi_Apply(In precon, In r, Out z, Out status) → Jacobi应用 z=M⁻¹r
│   │                                      • NM_Prec_ILU0_Build(In A, Out precon, Out status) → ILU(0)构造
│   │                                      • NM_Prec_ILU0_Apply(In precon, In r, Out z, Out status) → ILU(0)应用
│   │                                      • NM_Prec_SSOR_Build(In A, In omega, Out precon, Out status) → SSOR构造
│   │                                      • NM_Prec_SSOR_Apply(In precon, In r, Out z, Out status) → SSOR应用
│   │                                      • NM_Prec_Destroy(InOut precon, Out status) → 预条件子销毁
│   │                                      【接口契约】
│   │                                      • 三种预条件: Jacobi(对角)/ILU0(不完全LU)/SSOR(对称SOR)
│   │                                      • 格式无关: 适用于Dense/CSR格式
│   │                                      • 线程安全: 否
│   ├── NM_Solver_SVD_Core.f90          → SVD 求解（315 行，5 个子程序/函数：完整/瘦/部分 SVD/条件数/秩）
│   │                                      【子程序清单】
│   │                                      • NM_SVD_Full(In A, Out U, Out S, Out VT, Out status) → 完整SVD A=U·S·VT
│   │                                      • NM_SVD_Thin(In A, Out U, Out S, Out VT, Out status) → 瘦SVD(m>n时)
│   │                                      • NM_SVD_Partial(In A, In k, Out U, Out S, Out VT, Out status) → 部分SVD(仅前k个)
│   │                                      • NM_SVD_ConditionNumber(In A, Out cond, Out status) → 条件数 cond=S_max/S_min
│   │                                      • NM_SVD_Rank(In S, In tol, Out rank, Out status) → 秩估计
│   │                                      【接口契约】
│   │                                      • LAPACK调用: DGESVD(完整)/DGESDD(分治)
│   │                                      • Lanczos: 部分SVD使用Lanczos迭代
│   │                                      • 线程安全: 否
│   ├── GMRES_Solve_Transpose.f90       → 伴随求解（418 行，4 个子程序：GMRES/CG 伴随/伴随变量/SpMV）
│   ├── NM_SpMV_CSR_Transpose.f90       → CSR 转置（266 行，3 个子程序：转置/原位转置/对称化）
│   ├── LinSolv/                        → 线性求解器子目录（25 个文件）
│   ├── NonlinSolv/                     → 非线性求解器子目录（6 个文件）
│   ├── Conv/                           → 收敛控制子目录（6 个文件）
│   ├── AI/                             → AI 求解器子目录（3 个文件）
│   ├── Coupling/                       → 耦合求解器子目录（1 个文件）
│   ├── Parallel/                       → 并行求解器子目录（0 个文件，待开发）
│   ├── CONTRACT.md                     → 接口契约文档（57 行）
│   ├── CONTRACT_SVD.md                 → SVD 接口契约（66 行）
│   └── DESIGN_Solver_FourTypes.md      → 四型设计文档（122 行）
│
│                                      【架构决策说明】
│                                      • 代码量较大：总计 2,633 行（不含子目录），按职责清晰拆分为 7 个文件 + 5 个子目录
│                                      • 模块内聚优秀：按职责拆分（类型/直接/迭代/预条件/SVD/伴随/转置）
│                                      • 命名规范：统一 NM_ 前缀，符合三级命名体系
│                                      • LAPACK 集成：BIND(C) 直接调用 LAPACK（DGETRF/DGETRS/DPOTRF/DPOTRS），零封装开销
│                                      • 预条件子完整：Jacobi（对角）/ILU0（不完全 LU）/SSOR（对称 SOR）三种预条件子
│                                      • 迭代求解器完整：GMRES（广义最小残差）/CG（共轭梯度）/BiCGSTAB（双共轭梯度稳定）
│                                      • SVD 分解完整：完整 SVD/瘦 SVD/部分 SVD（Lanczos），支持条件数和秩估计
│                                      • 伴随求解支持：GMRES/CG 伴随求解，支持灵敏度分析和优化
│                                      • 子目录丰富：LinSolv（25 文件）/NonlinSolv（6 文件）/Conv（6 文件）/AI（3 文件）/Coupling（1 文件）
│   │
│   ├── LinSolv/                         [线性求解子域]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层线性求解器子域，统一的直接法/迭代法/预条件子/复数求解/稀疏接口中心
│                                      • 职责：直接求解器（LU/Cholesky/Multifrontal）、迭代求解器（CG/GMRES/BiCGSTAB/高级迭代）、预条件子（ILU/SSOR/AMG/多层AMG）、复数求解器、稀疏求解器接口
│                                      • 边界：仅提供线性方程组求解算法；非线性求解由 NonlinSolv 域处理
│                                      • 依赖：L2_NM Solver 核心子域，依赖 Matrix 域（稀疏矩阵），被 Assembly/Solver 域依赖
│                                      
│                                      【核心功能】
│                                      • 求解器核心容器：NM_Solv_Core 初始化和配置（5 个子程序）
│                                      • 求解器配置：自动配置、内存估计、预条件子推荐、SPD 检查、物理问题优化配置（11 个子程序/函数）
│                                      • 直接求解器：LU/Cholesky/Multifrontal 分解与求解（34 个子程序/函数）
│                                      • 迭代求解器：CG/GMRES/BiCGSTAB/高级迭代（ICCG/PCG/AGMG）（24 个子程序）
│                                      • 预条件子：Jacobi/ILU0/ILUT/SSOR/AMG/多层AMG/Block Jacobi/Block ILU0（40 个子程序）
│                                      • 复数求解器：复数矩阵分解与求解（4 个子程序）
│                                      • 稀疏求解器接口：CSR 矩阵向量乘法、CG 求解、统一求解接口（7 个子程序）
│                                      • 封装层（旧版）：UF_LinearSolver/UF_Preconditioner/UF_IterSolver/UF_DirectSolver/UF_AMG_Interface/UF_SparsePakWrapper（6 个文件，待迁移）
│                                      • 内存池：MemPool/MatPool 专用内存池（16 个子程序）
│
│   ├── NM_Solv_Core.f90                → 求解器核心容器（255 行，5 个子程序：Init/Finalize/SetLin/SetNonlin/GetSummary）
│   ├── NM_LinSolv_Config_Core.f90      → 求解器配置（505 行，11 个子程序/函数：AutoConfigure/MemoryEstimate/Recommend/CheckSPD）
│   ├── NM_LinSolv_Direct_Core.f90      → 直接求解核心（505 行，11 个子程序：统一直接求解接口）
│   ├── NM_LinSolv_Direct_LU_Core.f90   → LU 分解求解（769 行，10 个子程序/函数：LU 分解/求解/行列式）
│   ├── NM_LinSolv_Direct_Cholesky_Core.f90 → Cholesky 分解（657 行，9 个子程序/函数：Cholesky 分解/求解/3x3 优化）
│   ├── NM_LinSolv_Direct_Multifrontal_Core.f90 → 多波前法（595 行，9 个子程序：多波前分解/求解/符号分析）
│   ├── NM_LinSolv_Iter_Core.f90        → 迭代求解核心（497 行，9 个子程序/函数：统一迭代求解接口/收敛检查）
│   ├── NM_LinSolv_Iter_CG_Core.f90     → CG 求解（359 行，4 个子程序：CG/PCG/ICCG 求解）
│   ├── NM_LinSolv_Iter_GMRES_Core.f90  → GMRES 求解（642 行，7 个子程序：GMRES/重启GMRES/Givens 旋转）
│   ├── NM_LinSolv_Iter_BiCGSTAB_Core.f90 → BiCGSTAB 求解（537 行，6 个子程序：BiCGSTAB 求解/收敛检查）
│   ├── NM_LinSolv_Iter_Adv_Core.f90    → 高级迭代（576 行，7 个子程序：QMR/TFQMR/CR/BiCGSTAB(l)）
│   ├── NM_LinSolv_Prec_Core.f90        → 预条件子核心（471 行，9 个子程序/函数：预条件子构造/应用/统一接口）
│   ├── NM_LinSolv_Prec_ILU_Core.f90    → ILU 预条件子（615 行，8 个子程序：ILU0/ILUT/ILUTP 分解/应用）
│   ├── NM_LinSolv_Prec_SSOR_Core.f90   → SSOR 预条件子（528 行，6 个子程序：SSOR 构造/应用/最优 omega）
│   ├── NM_LinSolv_Prec_AMG_Core.f90    → AMG 预条件子（900 行，10 个子程序：AMG 设置/粗化/插值/光滑）
│   ├── NM_LinSolv_Prec_AMG_Multilevel_Core.f90 → 多层 AMG（806 行，8 个子程序：多层 AMG 设置/循环/粗化）
│   ├── NM_ComplexLinearSolver.f90      → 复数求解器（108 行，4 个子程序：复数初始化/分解/求解/释放）
│   ├── NM_Sparse_Solver_Interface.f90  → 稀疏求解器接口（322 行，7 个子程序：统一稀疏求解/CG 求解/SpMV）
│   ├── UF_LinearSolver.f90             → 线性求解器封装（旧版，1,343 行，20 个子程序/函数，待迁移）
│   ├── UF_Preconditioner.f90           → 预条件子封装（旧版，1,574 行，22 个子程序，待迁移）
│   ├── UF_IterSolver.f90               → 迭代求解器封装（旧版，854 行，6 个子程序，待迁移）
│   ├── UF_DirectSolver.f90             → 直接求解器封装（旧版，563 行，10 个子程序，待迁移）
│   ├── UF_AMG_Interface.f90            → AMG 接口封装（旧版，451 行，6 个子程序，待迁移）
│   ├── UF_SparsePakWrapper.f90         → SparsePak 封装（旧版，896 行，18 个子程序/函数，待迁移）
│   ├── UF_MemoryPool.f90               → 内存池封装（旧版，241 行，16 个子程序，待迁移）
│
│                                      【架构决策说明】
│                                      • 代码量超大：总计 13,198 行（25 个文件），按职责清晰拆分为 17 个核心文件 + 6 个封装层（待迁移）
│                                      • 模块内聚优秀：按职责拆分（配置/直接/迭代/预条件/复数/接口/封装）
│                                      • 命名规范：统一 NM_ 前缀（核心文件）+ UF_ 前缀（旧版封装层，待迁移）
│                                      • 直接求解器完整：LU/Cholesky/Multifrontal（多波前法）
│                                      • 迭代求解器完整：CG/PCG/ICCG/GMRES/BiCGSTAB/QMR/TFQMR/CR/AGMG
│                                      • 预条件子完整：Jacobi/ILU0/ILUT/ILUTP/SSOR/AMG/多层AMG/Block Jacobi/Block ILU0
│                                      • 复数求解器支持：复数矩阵分解与求解（电磁/声学问题）
│                                      • 旧版封装层：6 个 UF_ 前缀文件（5,379 行），需迁移至 NM_ 前缀
│   │
│   ├── NonlinSolv/                      [非线性求解子域]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层非线性求解器子域，统一的 Newton/TrustRegion/ArcLength/QuasiNewton/Continuation 非线性求解中心
│                                      • 职责：Newton-Raphson 求解、TrustRegion 信任域求解、ArcLength 弧长法（Crisfield/Riks）、QuasiNewton 拟 Newton 族（BFGS/DFP/SR1/LBFGS）、Continuation 延拓法（自然延拓/伪弧长/Homotopy）
│                                      • 边界：仅提供非线性方程组求解算法；线性求解依赖 LinSolv 域
│                                      • 依赖：L2_NM Solver 核心子域，依赖 LinSolv 域（线性求解），被 Assembly/Solver 域依赖
│                                      
│                                      【核心功能】
│                                      • Newton-Raphson 求解：标准 Newton/Modified Newton/BFGS/LBFGS、线搜索、收敛检查、切线刚度计算（23 个子程序）
│                                      • TrustRegion 信任域：Dogleg/Cauchy 步、自适应半径、SPD 系统求解（9 个子程序）
│                                      • ArcLength 弧长法：Crisfield/Riks 弧长、自适应步长、约束方程、路径跟踪（10 个子程序）
│                                      • QuasiNewton 拟 Newton 族：BFGS/DFP/SR1/Broyden/LBFGS 更新、线搜索、两步递归（20 个子程序/函数）
│                                      • Continuation 延拓法：自然延拓/伪弧长/Homotopy、切线预测器/Newton 校正器、自适应步长（20 个子程序/函数）
│                                      • 封装层（旧版）：UF_NonlinSolv（旧版封装，待迁移）（11 个子程序）
│
│   ├── NM_Nonlinear_Newton_Core.f90    → Newton-Raphson 求解（802 行，23 个子程序：标准/Modified/BFGS/LBFGS/线搜索/收敛）
│   ├── NM_Nonlinear_TrustRegion_Core.f90 → TrustRegion 信任域（318 行，9 个子程序：Dogleg/Cauchy/自适应半径/SPD 求解）
│   ├── NM_Nonlinear_ArcLength_Core.f90 → ArcLength 弧长法（366 行，10 个子程序：Crisfield/Riks/自适应步长/路径跟踪）
│   ├── NM_QuasiNewton_Family_Core.f90  → QuasiNewton 拟 Newton 族（711 行，20 个子程序/函数：BFGS/DFP/SR1/Broyden/LBFGS）
│   ├── NM_Continuation_Method_Core.f90 → Continuation 延拓法（682 行，20 个子程序/函数：自然/伪弧长/Homotopy/预测/校正）
│   ├── UF_NonlinSolv.f90               → 非线性求解封装（旧版，816 行，11 个子程序，待迁移）
│
│                                      【架构决策说明】
│                                      • 代码量适中：总计 3,695 行（6 个文件），按算法类型清晰拆分
│                                      • 模块内聚优秀：按算法类型拆分（Newton/TrustRegion/ArcLength/QuasiNewton/Continuation）
│                                      • 命名规范：统一 NM_ 前缀（核心文件）+ UF_ 前缀（旧版封装层，待迁移）
│                                      • Newton 法完整：标准 Newton/Modified Newton/BFGS/LBFGS/线搜索/收敛检查
│                                      • TrustRegion 完整：Dogleg/Cauchy 步/自适应半径/SPD 系统求解
│                                      • ArcLength 完整：Crisfield/Riks 弧长/自适应步长/路径跟踪
│                                      • QuasiNewton 完整：BFGS/DFP/SR1/Broyden/LBFGS 更新公式
│                                      • Continuation 完整：自然延拓/伪弧长/Homotopy/切线预测器/Newton 校正器
│                                      • 旧版封装层：1 个 UF_ 文件（816 行），需迁移至 NM_ 前缀
│   │
│   ├── Conv/                            [收敛加速子域]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层收敛加速子域，统一的线搜索/多重网格/迭代求解/Krylov扩展/收敛加速中心
│                                      • 职责：线搜索（Armijo/Wolfe/Strong Wolfe/Backtracking）、多重网格（V 循环/W 循环/AMG/GMG）、迭代求解（GMRES/BiCGSTAB/TFQMR/IDR）、Krylov 扩展（重启/增强/偏转）、收敛加速（Aitken/Epsilon/Shanks/Richardson）
│                                      • 边界：仅提供收敛加速算法；基础求解器由 Solver/LinSolv 域处理
│                                      • 依赖：L2_NM Solver 核心子域，依赖 LinSolv 域（预条件子），被 NonlinSolv/Solver 域依赖
│                                      
│                                      【核心功能】
│                                      • 线搜索：Armijo/Wolfe/Strong Wolfe/Backtracking/Cubic/Quadratic/Golden Section（21 个子程序/函数）
│                                      • 多重网格：V 循环/W 循环、AMG/GMG 层次构建、Prolongation/Restriction、光滑器（Jacobi/Gauss-Seidel/SOR）（15 个子程序）
│                                      • 迭代求解：GMRES/重启 GMRES/BiCGSTAB/BiCGSTAB-L/TFQMR/IDR、收敛检查、残差计算（11 个子程序/函数）
│                                      • 预条件子：ILU/IC/Jacobi/SSOR/SPAI/AMG 设置与应用、条件数估计（16 个子程序/函数）
│                                      • Krylov 扩展：自适应重启 GMRES/增强 GMRES/偏转 GMRES、Krylov 子空间构建、Ritz 对计算（14 个子程序）
│                                      • 收敛加速：Aitken Δ²/Epsilon 算法/Shanks 变换/Richardson 外推、向量加速（18 个子程序/函数）
│
│   ├── NM_Conv_LS_Core.f90             → 线搜索（669 行，21 个子程序/函数：Armijo/Wolfe/Strong Wolfe/Backtracking/Cubic/Quadratic/Golden Section）
│   ├── NM_Conv_MG_Core.f90             → 多重网格（508 行，15 个子程序：V/W 循环/AMG/GMG/Prolongation/Restriction/光滑器）
│   ├── NM_Conv_Iter_Solv_Core.f90      → 迭代求解（422 行，11 个子程序/函数：GMRES/BiCGSTAB/TFQMR/IDR/收敛检查）
│   ├── NM_Conv_Iter_Prec_Core.f90      → 迭代预条件（460 行，16 个子程序/函数：ILU/IC/Jacobi/SSOR/SPAI/AMG/条件数）
│   ├── NM_Conv_Krylov_Ext_Core.f90     → Krylov 扩展（484 行，14 个子程序：自适应重启/增强/偏转 GMRES/Ritz 对）
│   ├── NM_Conv_Accel_Core.f90          → 收敛加速（558 行，18 个子程序/函数：Aitken/Epsilon/Shanks/Richardson）
│
│                                      【架构决策说明】
│                                      • 代码量适中：总计 3,101 行（6 个文件），按算法类型清晰拆分
│                                      • 模块内聚优秀：按算法类型拆分（线搜索/多重网格/迭代求解/预条件/Krylov/加速）
│                                      • 命名规范：统一 NM_Conv_ 前缀，符合三级命名体系
│                                      • 线搜索完整：Armijo/Wolfe/Strong Wolfe/Backtracking/Cubic/Quadratic/Golden Section
│                                      • 多重网格完整：V/W 循环/AMG/GMG/Prolongation/Restriction/Jacobi/Gauss-Seidel/SOR 光滑器
│                                      • 迭代求解完整：GMRES/重启 GMRES/BiCGSTAB/BiCGSTAB-L/TFQMR/IDR
│                                      • Krylov 扩展创新：自适应重启/增强 GMRES/偏转 GMRES/Ritz 对计算
│   │
│   ├── Coupling/                        [耦合求解]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层多物理场耦合求解子域，统一的流固耦合/热固耦合/电固耦合/单体/交错求解中心
│                                      • 职责：流固耦合（FSI）、热固耦合（Thermal-Structural）、电固耦合（Electro-Mechanical）、单体求解（Monolithic）、交错求解（Staggered）、数据传递、预测器、自适应时间步
│                                      • 边界：仅提供多物理场耦合算法；单场求解由 Solver/LinSolv 域处理
│                                      • 依赖：L2_NM Solver 核心子域，依赖 NonlinSolv/LinSolv 域，被 Assembly/Physics 域依赖
│                                      
│                                      【核心功能】
│                                      • 流固耦合（FSI）：流体求解/结构求解/流体固力计算、交错求解（8 个子程序/函数）
│                                      • 热固耦合：温度场求解/结构求解/热应变计算、耦合求解（4 个子程序/函数）
│                                      • 电固耦合：静电求解/结构求解/压电应力计算、耦合求解（4 个子程序/函数）
│                                      • 单体求解（Monolithic）：单体组装、直接求解/迭代求解/Schur 补求解、块预条件子（6 个子程序）
│                                      • 交错求解（Staggered）：标准/改进/预测校正/子循环交错求解、数据传递（20+ 个子程序）
│                                      • 预测器：零阶/常数/线性/二次预测器、状态预测（5 个子程序）
│                                      • 自适应时间步：时间步控制/子循环设置/下一步时间步估计（4 个子程序/函数）
│                                      • 接口管理：接口创建/界面通量计算、数据传递（3 个子程序）
│
│   ├── NM_Coupling_Core.f90            → 耦合求解核心（1,968 行，50+ 个子程序/函数：FSI/热固/电固/单体/交错/预测器/自适应时间步）
│                                      ⚠️ 注意：该文件 1,968 行，接近 2,000 行阈值，建议按耦合类型拆分为多个文件
│
│                                      【架构决策说明】
│                                      • 代码量超大：1,968 行（1 个文件），建议拆分为 5-6 个文件（FSI/热固/电固/单体/交错/预测器）
│                                      • 模块内聚待优化：当前单文件实现所有耦合算法，需按耦合类型拆分
│                                      • 命名规范：统一 NM_Coupling_ 前缀，符合三级命名体系
│                                      • 耦合算法完整：FSI/热固/电固/单体/交错/预测器/自适应时间步
│                                      • 交错求解完整：标准/改进/预测校正/子循环 4 种交错策略
│                                      • 预测器完整：零阶/常数/线性/二次 4 种预测器
│                                      • ⚠️ 需拆分：建议拆分为 NM_Coupling_FSI_Core.f90 / NM_Coupling_ThermalStruct_Core.f90 / NM_Coupling_ElectroMech_Core.f90 / NM_Coupling_Monolithic_Core.f90 / NM_Coupling_Staggered_Core.f90 / NM_Coupling_Predictor_Core.f90
│   │
│   └── AI/                              [⭐ AI求解]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层 AI 增强求解子域，AI 就绪的预条件子/伴随求解/稀疏求解优化中心
│                                      • 职责：AI 预条件子（GNN 图神经网络加速 GMRES/CG）、伴随求解（离散伴随法灵敏度分析/拓扑优化）、AI 稀疏求解优化（神经网络代理模型预测最优 Krylov 参数）
│                                      • 边界：仅提供 AI 增强算法插槽；经典求解器由 LinSolv/NonlinSolv/Conv 域处理
│                                      • 依赖：L2_NM Solver 核心子域，依赖 LinSolv 域（预条件子接口），被 Optimization/Topology 域依赖
│                                      
│                                      【核心功能】
│                                      • AI 预条件子：ILU(0)/SA-AMG/AI-GNN 三种预条件子模式、GNN 权重管理、多重网格层次结构、性能监控（4 个子程序/函数）
│                                      • AI 伴随求解：直接法（PARDISO/MUMPS）/迭代法（GMRES/CG）/AI 代理模型、转置求解（Kᵀ·λ = b）、灵敏度计算（4 个子程序/函数）
│                                      • AI 稀疏求解优化：AI 预测最优 Krylov 参数（重启维度/容差/预条件子设置）、矩阵特征分析、收敛率预测（4 个子程序/函数）
│                                      
│                                      【当前状态】⚠️ AI P0 占位符（TYPE 定义 + STUB 子程序，无实际实现）
│                                      • NM_AI_Precond_Algo：预条件子插槽，支持 ILU(0)/SA-AMG/AI-GNN（144 行）
│                                      • NM_AI_Adjoint_Algo：伴随求解插槽，支持直接/迭代/AI 代理（159 行）
│                                      • NM_AI_SparseSolver_Algo：稀疏求解优化插槽，支持 AI 参数预测（151 行）
│                                      • 实现时机：AI P1-B（预条件子）→ AI P2-B（稀疏求解）→ AI P3（伴随求解）

   ├── NM_AI_Precond_Algo.f90             → AI 预条件子（144 行，4 个子程序/函数：Init/Finalize/Apply + TYPE 定义，支持 ILU(0)/SA-AMG/AI-GNN）
   ├── NM_AI_Adjoint_Algo.f90             → AI 伴随求解（159 行，4 个子程序/函数：Init/Finalize/Solve + TYPE 定义，支持直接/迭代/AI 代理）
   ├── NM_AI_SparseSolver_Algo.f90        → AI 稀疏求解优化（151 行，4 个子程序/函数：Init/Finalize/Optimize + TYPE 定义，支持 AI 参数预测）

                                      【架构决策说明】
                                      • 代码量精简：总计 454 行（3 个文件），按 AI 功能类型清晰拆分
                                      • 模块内聚优秀：按 AI 算法类型拆分（预条件子/伴随求解/稀疏求解优化）
                                      • 命名规范：统一 NM_AI_ 前缀，符合三级命名体系
                                      • AI P0 占位符：当前仅 TYPE 定义 + STUB 子程序，无实际 AI 实现
                                      • 热路径约束：遵守 AP-8 规范（Ctx 中零 ALLOCATE，冷数据 Write-Once）
                                      • 离线场景：伴随求解仅限离线灵敏度分析，禁止激活于常规仿真主循环
                                      • 未来扩展：
                                        - AI P1-B：实现 GNN 图神经网络预条件子
                                        - AI P2-B：实现 AI 稀疏求解参数优化
                                        - AI P3：实现离散伴随法 + AI 代理模型
                                      • 数学公式：
                                        - 伴随方程：Kᵀ·λ = ∂J/∂u
                                        - 灵敏度：dJ/dθ = -λᵀ·(∂R/∂θ)
                                        - 预条件：M⁻¹·v（AI-GNN 学习最优预条件子）
│
├── TimeInt/                              [时间积分]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层时间积分域，统一的瞬态动力学时间离散/自适应步长/事件检测中心
│                                      • 职责：Newmark-β 积分、HHT-α 积分（数值耗散）、Runge-Kutta 积分（显式/自适应）、自适应时间步控制（PI/PID/预测控制）、事件检测（接触/分离/屈曲/零交叉）
│                                      • 边界：仅提供时间积分算法；单步求解由 LinSolv 域处理，物理计算由 L4_PH 域处理
│                                      • 依赖：L2_NM LinSolv 域（线性求解器），被 L5_RT Step 域依赖（每个 Increment 调用）
│                                      
│                                      【核心功能】
│                                      • 时间积分格式：Newmark-β（隐式/显式）、HHT-α（数值耗散控制）、Runge-Kutta（RK4/自适应步长）、Generalized-α（17 个子程序/函数）
│                                      • 自适应时间步：PI 控制/PID 控制/预测控制/自适应增益控制、误差估计、步长限制、策略优化（24 个子程序/函数）
│                                      • 事件检测：接触事件/分离事件/屈曲事件/零交叉检测、事件时间定位、步长建议（17 个子程序/函数）
│                                      • 步长控制器：PI/PID/预测/自适应增益 4 种控制策略、事件处理、平滑步长变化（14 个子程序/函数）
│                                      • 类型定义：NewmarkIntegrator/HHTIntegrator/RKIntegrator 三种积分器 TYPE（13 个子程序/函数）
│                                      • 线性求解集成：稠密 LU 分解（LAPACK 封装）、有效刚度矩阵求解（3 个子程序）
│                                      • 梁单元专用：BEAM 单元时间积分专用实现（Init/Predict/Correct/Advance）（9 个子程序/函数）
│
│   ├── NM_TimeInt_Core.f90              → 时间积分核心域容器（227 行，2 个子程序：Init/Finalize + 域容器 TYPE）
│   │                                      【子程序清单】
│   │                                      • NM_TimeInt_Init(InOut this, In scheme_type, In dt, Out status) → 初始化时间积分器
│   │                                      • NM_TimeInt_Finalize(InOut this, Out status) → 释放时间积分器
│   │                                      【接口契约】
│   │                                      • 域容器: 封装Newmark/HHT/RK等所有积分器
│   │                                      • scheme_type: NEWMARK=1,HHT=2,RUNGE_KUTTA=3,GEN_ALPHA=4
│   │                                      • 线程安全: 否
│   ├── NM_TimeInt_Types.f90             → 积分器类型定义（464 行，13 个子程序/函数：Newmark/HHT/RK 创建/初始化/销毁）
│   │                                      【类型定义】
│   │                                      • NewmarkIntegrator: beta,gamma,dt,u_pred,v_pred,a_pred,u_corr,v_corr,a_corr
│   │                                      • HHTIntegrator: alpha,beta,gamma,dt,u_n,v_n,a_n,u_n1,v_n1,a_n1
│   │                                      • RKIntegrator: num_stages,a_coef,b_coef,c_coef,u_stage,weights
│   │                                      【子程序清单】
│   │                                      • NM_Newmark_Create(Out integrator, Out status) → 创建Newmark积分器
│   │                                      • NM_Newmark_Init(In beta, In gamma, In dt, Out integrator, Out status) → 初始化Newmark
│   │                                      • NM_Newmark_Destroy(InOut integrator, Out status) → 销毁Newmark
│   │                                      • NM_HHT_Create(Out integrator, Out status) → 创建HHT积分器
│   │                                      • NM_HHT_Init(In alpha, In dt, Out integrator, Out status) → 初始化HHT
│   │                                      • NM_HHT_Destroy(InOut integrator, Out status) → 销毁HHT
│   │                                      • NM_RK_Create(In num_stages, Out integrator, Out status) → 创建RK积分器
│   │                                      • NM_RK_Init(In coefficients, Out integrator, Out status) → 初始化RK
│   │                                      • NM_RK_Destroy(InOut integrator, Out status) → 销毁RK
│   │                                      【接口契约】
│   │                                      • Newmark参数: beta∈[0,0.5],gamma∈[0,1],隐式通常beta=0.25,gamma=0.5
│   │                                      • HHT参数: alpha∈[-1/3,0],隐式alpha=-1/3
│   │                                      • RK系数: Butcher表(A,B,C)
│   │                                      • 线程安全: 否
│   ├── NM_TimeInt_Scheme_Core.f90       → 时间积分格式核心（764 行，17 个子程序/函数：Newmark/HHT/GenAlpha 初始化/单步/系数计算）
│   ├── NM_TimeInt_Newmark.f90           → Newmark-β 积分（357 行，6 个子程序：Predict/Correct/Solve/Update/Explicit/Implicit）
│   │                                      【子程序清单】
│   │                                      • NM_Newmark_Predict(In integrator, Out u_pred, Out v_pred, Out a_pred) → 预测步
│   │                                      • NM_Newmark_Correct(In integrator, In a_new, Out u_corr, Out v_corr, Out a_corr) → 校正步
│   │                                      • NM_Newmark_Solve(In integrator, In K_eff, In f_eff, Out u_new, Out status) → 有效刚度求解
│   │                                      • NM_Newmark_Update(In integrator, In u_new, Out u, Out v, Out a, Out status) → 更新位移/速度/加速度
│   │                                      • NM_Newmark_Explicit(In integrator, In M, In f_ext, Out a, Out status) → 显式Newmark
│   │                                      • NM_Newmark_Implicit(In integrator, In K, In M, In C, In f_ext, Out u_new, Out status) → 隐式Newmark
│   │                                      【算法公式】
│   │                                      • 预测: uₙ₊₁=uₙ+dt·vₙ+dt²/2·(1-2β)·aₙ
│   │                                      • 校正: uₙ₊₁=uₙ+dt·vₙ+dt²·[β·aₙ₊₁+(0.5-β)·aₙ]
│   │                                      • 更新: vₙ₊₁=vₙ+dt·[(1-γ)·aₙ+γ·aₙ₊₁]
│   │                                      【接口契约】
│   │                                      • 条件稳定: 显式需dt<dt_critical
│   │                                      • 隐式无条件稳定: beta≥0.25,gamma=0.5
│   ├── NM_TimeInt_HHT.f90               → HHT-α 积分（335 行，7 个子程序：Integrate/Predict/Correct/Equilibrium/Update/EffectiveForce/EffectiveStiffness）
│   │                                      【子程序清单】
│   │                                      • NM_HHT_Integrate(In integrator, In M, In C, In K, In f_ext, In dt, Out u_new, Out v_new, Out a_new, Out status) → 单步积分
│   │                                      • NM_HHT_Predict(In integrator, Out u_pred, Out v_pred) → 预测
│   │                                      • NM_HHT_Correct(In integrator, In u_corr, Out u, Out v, Out a) → 校正
│   │                                      • NM_HHT_Equilibrium(In integrator, In u, In v, In a, Out residual, Out status) → 平衡方程残差
│   │                                      • NM_HHT_Update(In integrator, In a_new, Out u, Out v, Out a) → 状态更新
│   │                                      • NM_HHT_EffectiveForce(In integrator, In M, In C, In K, In f_ext, In u_old, In v_old, In a_old, Out f_eff) → 有效载荷
│   │                                      • NM_HHT_EffectiveStiffness(In integrator, In K, Out K_eff) → 有效刚度
│   │                                      【算法公式】
│   │                                      • 残差: rₙ₊₁=α·K·uₙ₊₁+K·uₙ+α·M·aₙ₊₁+M·aₙ+α·C·vₙ₊₁+C·vₙ-α·fₙ₊₁-fₙ=0
│   │                                      • 数值阻尼: 通过α参数控制高频阻尼
│   │                                      【接口契约】
│   │                                      • 数值阻尼: HHT-α提供可控数值耗散
│   │                                      • 参数范围: α∈[-1/3,0],β=(1-α)²/4,γ=(1-2α)/2
│   ├── NM_TimeInt_RK.f90                → Runge-Kutta 积分（325 行，6 个子程序：RK4/Stage/Update/AdaptiveStep + dydt 接口）
│   │                                      【子程序清单】
│   │                                      • NM_RK4_Step(In integrator, In dydt_func, In t, In y, In dt, Out y_new, Out status) → RK4单步
│   │                                      • NM_RK_ComputeStages(In integrator, In dydt_func, In t, In y, In dt, Out y_stage) → 计算各阶段值
│   │                                      • NM_RK_UpdateSolution(In integrator, In y_stage, Out y_new) → 更新解
│   │                                      • NM_RK_AdaptiveStep(In integrator, In dydt_func, In t, In y, In dt, In tol, Out y_new, Out dt_next, Out status) → 自适应步长
│   │                                      • NM_RK_EstimateError(In integrator, In y_low, In y_high, Out error) → 误差估计
│   │                                      • NM_RK_dydt_Interface(In t, In y, Out dydt, Out status) → dy/dt接口(用户定义)
│   │                                      【算法公式】
│   │                                      • RK4: k₁=h·f(t,y),k₂=h·f(t+h/2,y+k₁/2),k₃=h·f(t+h/2,y+k₂/2),k₄=h·f(t+h,y+k₃)
│   │                                      • 更新: yₙ₊₁=yₙ+(k₁+2k₂+2k₃+k₄)/6
│   │                                      【接口契约】
│   │                                      • 显式方法: 适用于非刚性系统
│   │                                      • 自适应: 内嵌误差估计(如Dormand-Prince)
│   ├── NM_Adaptive_TimeStep_Core.f90    → 自适应时间步核心（1,388 行，24 个子程序/函数：PI/PID/预测控制/误差估计/步长限制/策略优化）
│   ├── NM_TimeStep_Controller_Core.f90  → 步长控制器（755 行，14 个子程序/函数：PI/PID/预测/自适应增益/事件处理/平滑）
│   ├── NM_TimeInt_Adapt_Core.f90        → 自适应积分核心（666 行，13 个子程序/函数：Newmark/HHT/GenAlpha 自适应单步）
│   ├── NM_TS_Event_Det_Core.f90         → 事件检测（688 行，17 个子程序/函数：接触/分离/屈曲/零交叉/事件时间定位）
│   ├── NM_TimeInt_Linsolv.f90           → 线性求解集成（57 行，3 个子程序：LAPACK DGETRF/DGETRS 封装 + 稠密 LU 求解）
│   └── L2_NM_TimeInt_BEAM.f90           → 梁单元时间积分（696 行，9 个子程序/函数：Init/UpdateConstants/Predict/Correct/Advance）
│
│                                      【架构决策说明】
│                                      • 代码量分布合理：总计 6,722 行（12 个文件），按功能职责清晰拆分
│                                      • 模块内聚优秀：按算法类型拆分（Newmark/HHT/RK/自适应/事件检测/控制器）
│                                      • 命名规范：统一 NM_TimeInt_ 前缀，符合三级命名体系
│                                      • 理论链完整：Newmark-β/HHT-α/Generalized-α/Runge-Kutta 四大时间积分格式
│                                      • 自适应控制完整：PI/PID/预测/自适应增益 4 种控制策略
│                                      • 事件检测完整：接触/分离/屈曲/零交叉 4 类事件检测
│                                      • 线性求解集成：LAPACK 稠密 LU 分解（DGETRF/DGETRS）
│                                      • 梁单元专用：L2_NM_TimeInt_BEAM.f90 专用实现（696 行）
│                                      • ⚠️ 超大文件：NM_Adaptive_TimeStep_Core.f90（1,388 行），接近 1,500 行阈值，建议评估是否需拆分
│                                      • 缺失文件：原文档标注 NM_TimeInt_API.f90，实际不存在（可能已合并至 NM_TimeInt_Core.f90）
│
├── BVH/                                  [⭐ 层次包围盒]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层 BVH（层次包围盒）空间加速结构域，统一的空间查询/碰撞检测/最近邻搜索中心
│                                      • 职责：BVH 树构建（Median Split/SAH/Equal Area）、射线查询、最近邻搜索、BVH 重建、空间索引优化
│                                      • 边界：仅提供空间加速结构算法；接触检测由 L4_PH Contact 域处理，碰撞响应由 L5_RT 域处理
│                                      • 依赖：L2_NM 基础数值库，被 L4_PH Contact/Assembly 域依赖（接触检测加速）
│                                      
│                                      【核心功能】
│                                      • BVH 树构建：Median Split（中值分割）、SAH（表面积启发式）、Equal Area（等面积分割）（7 个子程序/函数）
│                                      • 空间查询：射线-包围盒相交查询、最近邻搜索、遍历栈管理（5 个子程序/函数）
│                                      • 类型定义：BVH_Node（包围盒节点）、BVH_Tree（树结构）、BVH_QueryResult（查询结果）、BVH_TraversalStack（遍历栈）（17 个子程序/函数）
│                                      • API 封装：简化接口（BVH_Create/BVH_Build/BVH_RayCast/BVH_FindNearest）、策略选择、别名导出（10 个子程序/函数）
│                                      • BVH 重建：几何变化后的树重建、统计信息更新（2 个子程序）
│                                      
│                                      【当前状态】⚠️ 核心算法 STUB 占位符（NM_BVH_Core.f90 中 Build/Query 为 STUB，NM_BVH_Types.f90 中类型方法已实现）
│                                      • NM_BVH_Core.f90：核心算法框架，Build/Query 为 STUB（171 行，7 个子程序）
│                                      • NM_BVH_API.f90：简化 API 封装层，类型/策略别名导出（213 行，10 个子程序/函数）
│                                      • NM_BVH_Types.f90：类型定义 + 类型方法（已实现）（308 行，17 个子程序/函数）

   ├── NM_BVH_Types.f90                 → BVH 类型定义（308 行，17 个子程序/函数：BVH_Node/BVH_Tree/BVH_QueryResult/BVH_TraversalStack + 类型方法）
   ├── NM_BVH_Core.f90                  → BVH 核心算法（171 行，7 个子程序：BuildMedian/BuildSAH/QueryRay/QueryNearest/Rebuild/UpdateStats）⚠️ STUB
   └── NM_BVH_API.f90                   → BVH API 封装（213 行，10 个子程序/函数：Create/Destroy/Build/RayCast/FindNearest/IsBuilt + 别名）

                                      【架构决策说明】
                                      • 代码量精简：总计 692 行（3 个文件），按职责清晰拆分（类型/核心/API）
                                      • 模块内聚优秀：类型定义/核心算法/API 封装三层分离
                                      • 命名规范：统一 NM_BVH_ 前缀，符合三级命名体系
                                      • 类型方法已实现：BVH_Node（Volume/SurfaceArea/Overlaps/ContainsPoint）、BVH_Tree（Initialize/Destroy/GetBoundingBox/IsBuilt）、BVH_TraversalStack（Push/Pop/IsEmpty/Destroy）
                                      • ⚠️ 核心算法 STUB：NM_BVH_Build/NM_BVH_BuildMedian/NM_BVH_BuildSAH/NM_BVH_QueryRay/NM_BVH_QueryNearest 为 STUB 占位符
                                      • API 封装层：提供简化接口（BVH_Create/BVH_Build/BVH_RayCast/BVH_FindNearest），支持策略字符串选择（'MEDIAN'/'SAH'/'EQUAL_AREA'）
                                      • 性能指标：构建 O(n log n)（Median）/ O(n log² n)（SAH），查询 O(log n) 平均情况
                                      • 分裂策略：Median Split（快速）、SAH（最优）、Equal Area（均衡）
                                      • 遍历栈：BVH_TraversalStack 支持迭代式树遍历，避免递归深度限制
│
├── ExternalLibs/                         [外部库封装]
│                                      【设计意图】
│                                      • 定位：UFC L2_NM 层外部数学库封装域，统一的 BLAS/LAPACK/迭代求解器/稀疏矩阵库/AGMG 多重网格接口中心
│                                      • 职责：BLAS 基本线性代数子程序、LAPACK 线性方程组/特征值求解、迭代求解器（GMRES/CG/BiCGSTAB）、预条件子（ILU/ILUT/ILUTP）、稀疏矩阵操作、AGMG 代数多重网格
│                                      • 边界：仅提供第三方库封装接口；算法实现由 LinSolv/NonlinSolv 域处理
│                                      • 依赖：第三方库（BLAS/LAPACK/HSL/AGMG），被 L2_NM Solver 域依赖
│                                      
│                                      【核心功能】
│                                      • BLAS 库：矩阵-向量乘法、矩阵-矩阵乘法、稀疏矩阵操作、掩码操作（15,380 行，~200+ 个子程序）
│                                      • LAPACK 库：线性方程组求解（LU/QR/LQ/Cholesky）、特征值问题（对称/非对称）、奇异值分解（30,206 行，~300+ 个子程序）
│                                      • 迭代求解器：GMRES/FGMRES/CG/BiCGSTAB/DBCG/QGMRES/FOM、预处理迭代器（12 个子程序）
│                                      • 预条件子：ILU(0)/ILUD/ILUT/ILUTP/ILUK/ILUDP、MILU(0)、LU 求解（10 个子程序）
│                                      • 稀疏矩阵库：SparsePak 稀疏矩阵构建/排序/重编号/块操作、RCM 排序（~50 个子程序）
│                                      • AGMG 多重网格：HSL MI20 AMG 预条件子、坐标/CSR/CSC 格式支持、C 接口封装（~25 个子程序）
│                                      
│                                      【⚠️ 超大文件警告】
│                                      • ModuleLapack.f90：30,206 行（0.8MB），~300+ 个子程序，LAPACK 完整封装
│                                      • ModuleBlas.f90：15,380 行（0.5MB），~200+ 个子程序，BLAS 完整封装
│                                      • SparsePakModule.f90：3,862 行（0.1MB），~50 个子程序
│                                      • agmg_03_ddeps90.f90：17,804 行（0.6MB），AGMG 核心实现
│                                      • agmg_04_hsl_mi20d.f90：5,495 行（0.2MB），HSL MI20 AMG 预条件子
│                                      • 总计：11 个文件，75,759 行（1.8MB），~600+ 个子程序
│
│   ├── ModuleBlas.f90                   → BLAS 库封装（15,380 行，0.5MB，~200+ 个子程序：amux/amub/amudia/aplb/addblk 等）
│   ├── ModuleLapack.f90                 → LAPACK 库封装（30,206 行，0.8MB，~300+ 个子程序：DGBSV/DGEQRF/DGEEV/DGESV 等）
│   ├── ModuleIters.f90                  → 迭代求解器（3,466 行，0.1MB，12 个子程序：gmres/fgmres/cg/bcgstab/dbcg/qgmres/fom 等）
│   ├── ModuleItsol.f90                  → 预条件子（2,163 行，0.1MB，10 个子程序：ilu0/ilud/ilut/ilutp/iluk/milu0/lusol 等）
│   ├── SparsePakModule.f90              → SparsePak 稀疏矩阵（3,862 行，0.1MB，~50 个子程序：addcom/addrcm/addrhs/adj_set 等）
│   ├── agmg_01_common90.f90             → AGMG 公共模块（1,157 行，0.04MB，9 个子程序：zb01_resize/write_to_file/read_from_file 等）
│   ├── agmg_02_ddeps.f90                → AGMG 依赖模块（1,407 行，0.04MB，7 个子程序：MC71AD/MI21AD/MI24AD/MI26AD 等）
│   ├── agmg_03_ddeps90.f90              → AGMG 核心实现（17,804 行，0.6MB，HSL ZD11/ZB01/MC65 等）
│   ├── agmg_04_hsl_mi20d.f90            → HSL MI20 AMG 预条件子（5,495 行，0.2MB，mi20_setup/mi20_precondition/mi20_solve 等）
│   └── agmg_05_hsl_mi20d_ciface.f90     → HSL MI20 C 接口（476 行，0.02MB，14 个子程序：mi20_setup_d/mi20_solve_d/mi20_precondition_d 等）
│
│                                      【架构决策说明】
│                                      • 第三方库封装：BLAS/LAPACK/HSL/AGMG 完整封装，提供统一接口
│                                      • ⚠️ 超大文件：ModuleLapack.f90（30,206 行）/ModuleBlas.f90（15,380 行）/agmg_03_ddeps90.f90（17,804 行）
│                                      • 命名规范：第三方库保留原名（ModuleBlas/ModuleLapack），UFC 封装使用 NM_ 前缀
│                                      • 迭代求解器完整：GMRES/FGMRES/CG/BiCGSTAB/DBCG/QGMRES/FOM（7 种）
│                                      • 预条件子完整：ILU(0)/ILUD/ILUT/ILUTP/ILUK/ILUDP/MILU(0)（7 种）
│                                      • AGMG 多重网格：HSL MI20 AMG 预条件子，支持 CSR/CSC/Coordinate 格式
│                                      • C 接口封装：agmg_05_hsl_mi20d_ciface.f90 提供 BIND(C) 接口
│                                      • 建议评估：超大文件是否需拆分（如按 LAPACK 功能模块拆分）
│
├── Bridge/                               [桥接层]
│   ├── NM_Brg_Core.f90                  → 桥接核心
│   │                                      【子程序清单】
│   │                                      • NM_Bridge_Init(InOut this, Out status) → 初始化桥接域
│   │                                      • NM_Bridge_Finalize(InOut this, Out status) → 释放桥接域
│   │                                      • NM_Bridge_CheckLibrary(In lib_name, Out available, Out version, Out status) → 检查库可用性
│   │                                      • NM_Bridge_GetLibStatus(In this, Out lib_status, Out status) → 获取库状态
│   │                                      • NM_Bridge_GetSummary(In this, Out summary, Out status) → 获取摘要
│   │                                      【类型定义】
│   │                                      • NM_ExtLibFlags: hasMUMPS,hasLAPACK,hasCuSPARSE,hasAGMG,hasSparsePak
│   │                                      • NM_Bridge_Domain: extLibs,initialized
│   │                                      【接口契约】
│   │                                      • 外部库检测: 通过编译时宏或运行时探测
│   │                                      • #ifdef隔离: 仅限本域内部使用
│   │                                      • 线程安全: 否
│   ├── NM_Direct_Solver_Dispatcher_Brg.f90 → 直接求解分发
│   │                                      【子程序清单】
│   │                                      • NM_Brg_Dispatch_Solver(In matrix_format, In sym_type, Out solver_type, Out status) → 分发求解器类型
│   │                                      • NM_Brg_Select_Direct(In matrix, Out solver_handle, Out status) → 选择直接求解器
│   │                                      【接口契约】
│   │                                      • 格式路由: CSR→MUMPS/SparsePak, Dense→LAPACK
│   │                                      • 对称优化: SPD矩阵优先Cholesky
│   ├── NM_Direct_MUMPS_Brg.f90          → MUMPS桥接
│   │                                      【子程序清单】
│   │                                      • NM_MUMPS_Init(Out mumps_ctx, Out status) → 初始化MUMPS上下文
│   │                                      • NM_MUMPS_Setup_FromCSR(In mumps_ctx, In csr_matrix, Out status) → CSR→MUMPS格式
│   │                                      • NM_MUMPS_Analyze(In mumps_ctx, Out status) → 符号分析
│   │                                      • NM_MUMPS_Factorize(In mumps_ctx, Out status) → 数值分解
│   │                                      • NM_MUMPS_Solve(In mumps_ctx, In rhs, Out solution, Out status) → 前代回代求解
│   │                                      • NM_MUMPS_GetInfo(In mumps_ctx, Out info, Out status) → 获取求解信息
│   │                                      • NM_MUMPS_Finalize(InOut mumps_ctx, Out status) → 释放MUMPS资源
│   │                                      • NM_DirectSolver_SyncThreads(InOut params, In n_omp_threads) → 同步OpenMP线程数到求解器参数
│   │                                      【接口契约】
│   │                                      • 并行支持: MPI多波前求解 + OpenMP多线程(ICNTL(16))
│   │                                      • 稀疏矩阵: CSR格式输入,MUMPS内部转换为COO
│   │                                      • 编译开关: -DWITH_MUMPS
│   │                                      • SMP贯通(v4.0): ICNTL(16)线程数从AP_Solver_Ctrl同步
│   ├── NM_Direct_SparsePak_Brg.f90      → SparsePak桥接
│   │                                      【子程序清单】
│   │                                      • NM_SparsePak_Solv(In n, In nnz, In row_ptr, In col_ind, In values, In rhs, Out solution, Out status) → 一次性求解
│   │                                      • NM_SparsePak_Symbolic(In n, In nnz, In row_ptr, In col_ind, Out sym_factors, Out status) → 符号分解
│   │                                      • NM_SparsePak_Numeric(In sym_factors, In values, Out num_factors, Out status) → 数值分解
│   │                                      • NM_SparsePak_Solv_Factored(In num_factors, In rhs, Out solution, Out status) → 使用已有分解求解
│   │                                      • NM_SparsePak_Cleanup(Out status) → 释放资源
│   │                                      【接口契约】
│   │                                      • Cholesky求解: 仅适用于SPD矩阵
│   │                                      • 两步求解: Symbolic→Numeric→Solve模式
│   │                                      • 编译开关: -DWITH_SPARSEPAK
│   ├── NM_Prec_AGMG_HSL_Brg.f90         → AGMG/HSL桥接
│   │                                      【子程序清单】
│   │                                      • NM_AMG_HSL_Setup(In matrix, In nlevels, Out precon, Out status) → 构建AMG预条件子
│   │                                      • NM_AMG_HSL_Apply(In precon, In rhs, Out solution, Out status) → 应用预条件 y=M⁻¹·x
│   │                                      • NM_AMG_HSL_Solv(In A, In b, In nlevels, Out x, Out status) → AMG+Krylov求解
│   │                                      • NM_AMG_HSL_Destroy(InOut precon, Out status) → 销毁AMG预条件子
│   │                                      • NM_AMG_HSL_SetDefaults(In precon, Out status) → 设置默认参数
│   │                                      • NM_AMG_HSL_GetStats(In precon, Out niter, Out residual, Out status) → 获取AMG统计
│   │                                      【接口契约】
│   │                                      • 代数多重网格: HSL MI20 AMG实现
│   │                                      • 格式支持: CSR/COO/CSC
│   │                                      • C接口: agmg_05_hsl_mi20d_ciface封装
│   │                                      • 编译开关: -DWITH_HSL
│   │                                      【子程序清单】
│   │                                      • NM_SparsePak_Solv(In n, In nnz, In row_ptr, In col_ind, In values, In rhs, Out solution, Out status) → 一次性求解
│   │                                      • NM_SparsePak_Symbolic(In n, In nnz, In row_ptr, In col_ind, Out sym_factors, Out status) → 符号分解
│   │                                      • NM_SparsePak_Numeric(In sym_factors, In values, Out num_factors, Out status) → 数值分解
│   │                                      • NM_SparsePak_Solv_Factored(In num_factors, In rhs, Out solution, Out status) → 使用已有分解求解
│   │                                      • NM_SparsePak_Cleanup(Out status) → 释放资源
│   │                                      【接口契约】
│   │                                      • Cholesky求解: 仅适用于SPD矩阵
│   │                                      • 两步求解: Symbolic→Numeric→Solve模式
│   │                                      • 编译开关: -DWITH_SPARSEPAK
│   └── NM_Prec_AGMG_HSL_Brg.f90         → AGMG/HSL桥接
│
│   └── NM_L2_LayerContainer_Core.f90    → L2层容器核心
│   │                                      【子程序清单】
│   │                                      • NM_L2_Init(In config, Out status) → L2层初始化
│   │                                      • NM_L2_Finalize(Out status) → L2层释放
│   │                                      【类型定义】
│   │                                      • NM_L2_LayerContainer: base,linAlg,solver,eigen,timeInt,bridge,initialized
│   │                                      【接口契约】
│   │                                      • 初始化顺序: 1-base 2-linAlg 3-solver 4-eigen 5-timeInt 6-bridge
│   │                                      • 释放顺序: 严格逆序(6-bridge 5-timeInt 4-eigen 3-solver 2-linAlg 1-base)
│   │                                      • 幂等初始化: 支持重复调用
│   │                                      • 线程安全: 否
```

**L2_NM 统计**: 7 域 | 6 子域 | 100+ 文件 | TYPE策略: **统一合并 `_Types.f90`（按需 USE）**

---

## 四、L3_MD — 模型数据层

```text
L3_MD/
├── Analysis/                             [分析步]
│   ├── MD_Analysis_Core.f90             → 分析步核心
│   │                                         【子程序清单】
│   │                                         • MD_Analysis_Group_Init(InOut group, Out status) → 初始化分析组
│   │                                         • MD_Analysis_Group_AddStep(InOut group, In step_desc, Out step_id, Out status) → 添加分析步
│   │                                         • MD_Analysis_Group_GetStep(In group, In step_id, Out step_desc, Out status) → 获取步描述
│   │                                         • MD_Analysis_Group_GetCurrentStep(In group, Out step_desc, Out status) → 获取当前步
│   │                                         【类型定义】
│   │                                         • MD_Analysis_Group_Type: steps(:), n_steps, current_idx
│   │                                         • MD_Analysis_Context_Type: time_current, time_total, dtime
│   │                                         【接口契约】
│   │                                         • 前置: md_layer已初始化,IF_Err_API可用
│   │                                         • 后置: steps数组已扩展,步号唯一递增
│   │                                         • 线程安全: 否(L5串行访问)
│   │
│   ├── MD_Analysis_API.f90              → 分析步API
│   │                                         【子程序清单】
│   │                                         • MD_Analysis_SetProcedure(InOut step, In proc_type, Out status) → 设置分析类型
│   │                                         • MD_Analysis_GetProcedure(In step, Out proc_type, Out status) → 获取分析类型
│   │                                         • MD_Analysis_SetTimeControl(InOut step, In dt0, In dt_min, In dt_max, Out status) → 设置时间控制
│   │                                         • MD_Analysis_BindLoadBC(InOut step, In load_ids, In bc_ids, Out status) → 绑定载荷边界
│   │                                         【接口契约】
│   │                                         • proc_type: PROC_STATIC/PROC_DYNAMIC_IMPLICIT/PROC_DYNAMIC_EXPLICIT等
│   │                                         • 错误码: L3:3001-3099
│   │
│   ├── Amplitude/                       [幅值子域]
│   │                                         【设计意图】
│   │                                         提供载荷/边界条件的时间依赖缩放因子A(t)计算,支持表格型、光滑阶跃、
│   │                                         周期型、衰减型、调制型、用户自定义等12种幅值类型。
│   │                                         理论链: ABAQUS Analysis User's Guide §34.1
│   │                                         逻辑链: L5_RT/L4_PH → MD_Amplitude_Core → amplitude_evaluate
│   │                                         数据链: 域容器g_ufc_global%model_data%amp,Desc只读,State按调用更新
│   │                                         计算链: 表格型线性插值/光滑阶跃C2三次样条/周期正弦/衰减指数
│   │
│   │   ├── MD_Amplitude_Core.f90        → 幅值核心 (948行)
│   │                                         【子程序清单】
│   │                                         • amplitude_init(In max_amps, Out status) → 初始化幅值域
│   │                                         • amplitude_clear(Out status) → 清空所有幅值
│   │                                         • amplitude_add_point(In amp_idx, In t, In a, Out status) → 添加数据点
│   │                                         • amplitude_set_tabular(In amp_idx, In t_vals, In a_vals, Out status) → 设置表格型
│   │                                         • amplitude_set_smooth_step(In amp_idx, In t1, In t2, In a1, In a2, Out status) → 设置光滑阶跃
│   │                                         • amplitude_set_periodic(In amp_idx, In freq, In amp, In phase, Out status) → 设置周期型
│   │                                         • amplitude_set_ramp(In amp_idx, In t_end, Out status) → 设置斜坡型
│   │                                         • amplitude_set_modulated(In amp_idx, In carrier_amp, In mod_freq, In mod_depth, Out status) → 设置调制型
│   │                                         • amplitude_set_user_sub(In amp_idx, In user_func, Out status) → 设置用户子程序
│   │                                         • amplitude_evaluate(In amp_idx, In time, Out value, Out status) → 计算A(t)
│   │                                         • ampdb_init(In capacity, Out status) → 初始化幅值数据库
│   │                                         • ampdb_add_amplitude(In name, In amp_type, Out amp_idx, Out status) → 添加幅值到数据库
│   │                                         • ampdb_evaluate(In amp_name, In time, Out value, Out status) → 按名计算A(t)
│   │                                         • ampdb_find_by_name(In amp_name, Out amp_idx, Out found, Out status) → 按名查找
│   │                                         • ampdb_get_amplitude(In amp_idx, Out amp_def, Out status) → 获取幅值定义
│   │                                         • ampdb_clear(Out status) → 清空数据库
│   │                                         • MD_Amplitude_Domain_Init(InOut this, In capacity, Out status) → 域初始化
│   │                                         • MD_Amplitude_Domain_AddAmplitude(InOut this, In desc, Out amp_id, Out status) → 添加幅值
│   │                                         • MD_Amplitude_Domain_GetAmplitude(InOut this, In amp_id, Out desc, Out status) → 获取幅值
│   │                                         • MD_Amplitude_Domain_GetFactor(InOut this, In time, Out factor, Out status) → 获取缩放因子
│   │                                         【类型定义】
│   │                                         • MD_Amp_Slot_Desc: amp_id, amp_name, amp_type, time_data(:), value_data(:), n_points
│   │                                         • MD_Amp_Slot_Ctx: amplitudes(:), n_amplitudes, capacity
│   │                                         • MD_Amplitude_Eval_Desc: amp_name, amp_type, props(:)
│   │                                         • MD_Amplitude_Eval_State: current_time, amp_value
│   │                                         • MD_Amplitude_Eval_Ctx: instance_name, coords
│   │                                         • AmpAlgo: interpolation_method
│   │                                         【接口契约】
│   │                                         • 幅值类型: TABULAR/SMOOTH/PERIODIC/MODULATED/DECAY/RAMP/USER等(1-11)
│   │                                         • 前置: MD_Amplitude_Domain已初始化
│   │                                         • 后置: amplitude_evaluate返回A(t),amp_value已更新
│   │                                         • 线程安全: 否(单实例L3)
│   │                                         • 错误码: L3:3101-3199
│   │
│   │   ├── MD_Amplitude_API.f90         → 幅值API (144行)
│   │                                         【子程序清单】
│   │                                         • MD_Amp_FromExt(In desc_amp, InOut md_amplitude, Out status) → Desc→UF转换
│   │                                         • MD_Amp_FromExt_Def(In desc_amp, InOut md_ampdef, Out status) → 单幅值转换
│   │                                         • MD_Amp_FromExt_DB(In desc_amp, InOut md_ampdb, Out status) → 添加到数据库
│   │                                         【接口契约】
│   │                                         • desc_amp: MD_Amp_Ext_Desc类型,含amp_type/time_points/amplitude_value等
│   │                                         • 前置: desc_amp已填充,md_ampdef/md_ampdb已初始化
│   │                                         • 后置: md_ampdef/md_ampdb已更新
│   │
│   │   ├── MD_Amplitude_Types.f90       → 类型定义 (492行)
│   │                                         【类型定义】
│   │                                         • MD_Amp_Tabular_Desc: amp_name, n_points, t_vals(:), a_vals(:), interp_method
│   │                                         • MD_Amp_User_Desc: amp_name, use_vuamp, nprops, props(:), nsvars
│   │                                         • MD_Amp_Periodic_Desc: amp_name, n_terms, omega, t0, a0, a_coeff(:), b_coeff(:)
│   │                                         • MD_Amp_Modulated_Desc: amp_name, carrier_amp_name, envelope_amp_name, scale_carrier, scale_envelope
│   │                                         • MD_Amp_Desc: name, amp_id, amp_type, time_data(:), value_data(:), n_points, smooth, omega, decay_*(衰减参数), mod_*(调制参数), tabular_extrapolate, ramp_t_end
│   │                                         • MD_Amp_State: currentValue, currentTime, currentIndex, step_idx, incr_idx
│   │                                         • MD_Amplitude_Domain: amplitudes(:), n_amplitudes, capacity, amp_state(:), algo, initialized
│   │                                         【常量定义】
│   │                                         • AMP_TABULAR=1, AMP_SMOOTH=2, AMP_PERIODIC=3, AMP_MODULATED=4, AMP_DECAY=5, AMP_RAMP=6
│   │                                         • AMP_SOLUTION_DEPENDENT=7, AMP_ACTUATOR=8, AMP_SPECTRUM=9, AMP_USER=10, AMP_PSD=11
│   │                                         • INTERP_LINEAR=1, INTERP_SMOOTH=2
│   │
│   │   ├── MD_Amplitude_Idx_API.f90     → 索引API (64行)
│   │                                         【子程序清单】
│   │                                         • MD_Amplitude_GetAmplitude_Idx(In amp_idx, InOut arg, Out status) → 按索引获取幅值
│   │                                         • MD_Amplitude_EvalAtTime_Idx(In amp_idx, In time, Out value, Out status, In step_idx, In incr_idx) → 按索引计算A(t)
│   │                                         【接口契约】
│   │                                         • 使用g_ufc_global%md_layer%amplitude_layer%amplitude
│   │                                         • step_idx/incr_idx: 三步索引(L3-L5)
│   │
│   │   └── MD_Amplitude_Sync.f90        → 同步 (106行)
│   │                                         【子程序清单】
│   │                                         • MD_Amplitude_SyncFromLegacy(In model_def, InOut md_layer, Out status) → 同步Legacy数据
│   │                                         • MD_Amplitude_ResolveName(In md_layer, In amp_name, Out amp_idx, Out status) → 名称解析
│   │                                         【接口契约】
│   │                                         • Legacy: UF_ModelDef%amplitudes → New: md_layer%amplitude
│   │                                         • 必须在MD_LoadBC_SyncFromLegacy之前调用
│   │
│   ├── Solver/                          [求解器子域]
│   │                                         【设计意图】
│   │                                         提供Newton-Raphson迭代求解器的收敛控制参数管理,支持残差/位移/能量收敛判据、
│   │                                         线搜索、稳定性控制等算法参数配置。
│   │                                         理论链: Newton-Raphson: K_t·Δu = -r(u), ||r||/||f_ext||<eps_res
│   │                                         逻辑链: L3_MD Step存储solver_config_id → MD_Solver_Domain存储configs(:)
│   │                                         数据链: MD_Solver_Desc(Write-Once), MD_Solver_State(Runtime)
│   │                                         计算链: 迭代控制+收敛检查+回退策略
│   │
│   │   ├── MD_Solv_Core.f90             → 求解器核心 (191行)
│   │                                         【子程序清单】
│   │                                         • MD_Solv_Init(InOut this, In initial_capacity, Out status) → 初始化域
│   │                                         • MD_Solv_Finalize(InOut this) → 释放域
│   │                                         • MD_Solv_AddCfg(InOut this, In desc, Out config_id, Out status) → 添加求解器配置
│   │                                         • MD_Solv_GetCfg(InOut this, In config_id, Out desc, Out status) → 获取配置
│   │                                         • MD_Solv_GetSummary(InOut this, Out arg, Out status) → 获取摘要
│   │                                         【类型定义】
│   │                                         • MD_Solver_Domain: configs(:), n_configs, capacity, initialized
│   │                                         • MD_Solver_AddConfig_Arg: desc(IN), config_id(OUT), status
│   │                                         • MD_Solver_GetConfig_Arg: config_id(IN), desc(OUT), status
│   │                                         • MD_Solver_GetSummary_Arg: summary(OUT), status
│   │                                         【接口契约】
│   │                                         • 前置: initial_capacity>0
│   │                                         • 后置: configs数组已扩展,config_id唯一
│   │                                         • 线程安全: 否
│   │
│   │   ├── MD_Solver_Types.f90          → 类型定义 (140行)
│   │                                         【类型定义】
│   │                                         • MD_Solver_Desc: config_id, max_iterations, residual_tol, correction_tol, energy_tol, check_residual, check_correction, check_energy, line_search, line_search_tol, stabilize, stabilize_factor, stabilize_energy_fraction, step_ref
│   │                                         • MD_Solver_Algo: max_iterations, residual_tol, correction_tol, energy_tol, check_residual, check_correction, check_energy, line_search, line_search_tol, max_cutbacks, cutback_factor
│   │                                         • MD_Solver_State: current_config_idx, total_iterations, max_iterations_reached, last_residual_norm, last_correction_norm, converged, failed_steps
│   │                                         • MD_Solver_Ctx: current_residual_norm, ...
│   │
│   │   └── MD_Solver_Sync.f90           → 同步 (97行)
│   │                                         【子程序清单】
│   │                                         • SolCtrl_To_SolverDesc(In sol_ctrl, In step_ref, Out desc) → 转换求解器参数
│   │                                         • MD_Solver_SyncFromStep(InOut md_layer, Out status) → 同步Step→Solver域
│   │                                         【接口契约】
│   │                                         • Legacy: Step%algo%sol_ctrl → New: solver domain + step%solver_config_id
│   │                                         • 必须在MD_Step_SyncFromLegacy之后调用
│   │
│   └── Step/                            [分析步子域]
│   │                                         【设计意图】
│   │                                         提供分析步的完整生命周期管理,包括步定义、增量控制、求解器参数、动态积分参数。
│   │                                         支持32种分析步类型(STATIC/DYNAMIC/MODAL/HEAT_TRANSFER/COUPLED等)。
│   │                                         理论链: Newton-Raphson迭代/Newmark时间积分/HHT-α/H Rayleigh阻尼
│   │                                         逻辑链: L6_AP解析*STEP → MD_Step_Domain_AddStep → [L3 frozen] → L4_PH读取 → L5_RT计算
│   │                                         数据链: MD_Step_Desc(Write-Once), MD_Step_State(WriteBack白名单), StepAlgo
│   │                                         计算链: Init→AddStep→GetCurrentStep→WriteBack→AdvanceStep
│   │
│       ├── MD_Step_Core.f90             → 步核心 (741行)
│       │                                         【子程序清单】
│       │                                         • MD_Step_Domain_Init(InOut this, In max_steps, Out status) → 初始化步域
│       │                                         • MD_Step_Domain_Finalize(InOut this, Out status) → 释放步域
│       │                                         • MD_Step_Domain_AddStep(InOut this, In desc, Out step_id, Out status) → 添加分析步
│       │                                         • MD_Step_Domain_GetStep(InOut this, In step_id, Out desc, Out status) → 获取步描述
│       │                                         • MD_Step_Domain_GetCurrentStep(InOut this, Out desc, Out status) → 获取当前步
│       │                                         • MD_Step_Domain_AdvanceStep(InOut this, Out status) → 推进到下一步
│       │                                         • MD_Step_WriteBack(InOut this, In step_id, In current_time, In current_increment, In is_complete, Out status) → 回写状态
│       │                                         【类型定义】
│       │                                         • MD_Step_Domain: steps(:), step_state(:), step_ctx(:), n_steps, capacity, current_step_idx
│       │                                         • MD_Step_Desc: name, step_number, procedure, nlgeom, time_period, start_time, perturbation, load_ids(:), bc_ids(:), pair_ids(:), output_ids(:), solver_config_id, algo
│       │                                         • StepAlgo: inc_ctrl, sol_ctrl, dyn
│       │                                         【接口契约】
│       │                                         • WriteBack白名单: current_time/current_increment/is_complete
│       │                                         • 冻结字段: procedure/nlgeom/time_period/start_time/perturbation/algo
│       │                                         • 错误码: L3:3201-3299
│       │
│       ├── MD_Step_Types.f90            → 类型定义 (279行)
│       │                                         【类型定义】
│       │                                         • MD_Step_State: current_time, current_increment, total_increments, is_active, is_complete, is_converged, newton_iterations, cutback_count, accumulated_time
│       │                                         • MD_Step_Ctx: step_time, total_time, time_increment, increment_number, iteration_number, analysis_type, nlgeom, first_increment, last_increment, newmark_gamma, newmark_beta, hht_alpha
│       │
│       ├── MD_Step_Proc.f90             → 处理 (1313行)
│       │                                         【子程序清单】
│       │                                         • UF_StepDef_Init(InOut step_def, In name, In procedure, Out status) → 初始化步定义
│       │                                         • UF_StepDef_SetTime(InOut step_def, In time_period, In start_time, Out status) → 设置时间参数
│       │                                         • UF_StepDef_SetNLGeom(InOut step_def, In nlgeom_flag, Out status) → 设置几何非线性
│       │                                         • UF_StepDef_AddLoad(InOut step_def, In load_id, Out status) → 添加载荷引用
│       │                                         • UF_StepDef_AddBC(InOut step_def, In bc_id, Out status) → 添加边界条件引用
│       │                                         • UF_StepDef_AddOutput(InOut step_def, In output_id, Out status) → 添加输出请求
│       │                                         • UF_StepManager_Init(InOut mgr, In max_steps, Out status) → 初始化管理器
│       │                                         • UF_StepManager_AddStep(InOut mgr, In step_def, Out step_id, Out status) → 添加步
│       │                                         • UF_StepManager_GetStep(In mgr, In step_id, Out step_def, Out status) → 获取步
│       │                                         • UF_StepManager_GetStepByName(In mgr, In name, Out step_def, Out status) → 按名获取
│       │                                         【常量定义】
│       │                                         • PROC_STATIC=1, PROC_STATIC_RIKS=2, PROC_STATIC_PERTURBATION=3, PROC_VISCO=4
│       │                                         • PROC_DYNAMIC_IMPLICIT=10, PROC_DYNAMIC_EXPLICIT=11, PROC_DYNAMIC_SUBSPACE=12
│       │                                         • PROC_MODAL=13, PROC_MODAL_DYNAMIC=14, PROC_FREQUENCY=20
│       │                                         • PROC_STEADY_STATE=30, PROC_HEAT_TRANSFER=31, PROC_COUPLED_TES=42
│       │                                         • NLGEOM_OFF=0, NLGEOM_ON=1
│       │                                         【接口契约】
│       │                                         • procedure: 1-69范围,按组分类(A-G)
│       │                                         • nlgeom: 0=小变形,1=大变形
│       │
│       └── MD_Step_Sync.f90             → 同步 (94行)
│                                               【子程序清单】
│                                               • MD_Step_SyncFromLegacy(In model_def, InOut md_layer, Out status) → 同步Legacy数据
│                                               【接口契约】
│                                               • Legacy: UF_ModelDef%step_mgr → New: md_layer%step
│                                               • 必须在LoadBC_Sync/Output_Sync/Interaction_Sync之前调用
│
├── Material/                             [材料]
│   ├── MD_Mat_Core.f90                  → 材料核心
│   │                                         【子程序清单】
│   │                                         • MD_Mat_Domain_Init(InOut domain, In capacity, Out status) → 初始化材料域
│   │                                         • MD_Mat_Domain_AddMaterial(InOut domain, In mat_desc, Out mat_id, Out status) → 添加材料
│   │                                         • MD_Mat_Domain_GetMaterial(In domain, In mat_id, Out mat_desc, Out status) → 获取材料
│   │                                         • MD_Mat_Domain_GetMaterialByName(In domain, In name, Out mat_desc, Out status) → 按名获取
│   │                                         • MD_Mat_Domain_Validate(In domain, In mat_id, Out valid, Out status) → 校验材料
│   │                                         【类型定义】
│   │                                         • MD_Mat_Domain: materials(:), n_materials, category_index(:), initialized
│   │                                         【接口契约】
│   │                                         • 前置: capacity>0
│   │                                         • 错误码: L3:4001-4099
│   │
│   ├── MD_Mat_API.f90                   → 材料API
│   │                                         【子程序清单】
│   │                                         • MD_Mat_CreateDesc(In mat_type, Out mat_desc, Out status) → 创建材料描述符
│   │                                         • MD_Mat_RegisterMaterial(InOut domain, In mat_desc, Out mat_id, Out status) → 注册材料
│   │                                         • MD_Mat_ValidateProps(In mat_type, In nprops, In props, Out status) → 校验参数
│   │                                         【接口契约】
│   │                                         • mat_type: MAT_ELASTIC/MAT_PLASTIC/MAT_HYPERELASTIC等
│   │
│   ├── MD_Mat_Types.f90                 → 类型定义 (合并)
│   │                                         【类型定义】
│   │                                         • MD_Mat_Desc: mat_id, mat_name, mat_type, nprops, props(:), is_initialized
│   │                                         • MD_MatSta: statev(:), nstatev, sync_status
│   │                                         • MD_MatCtx: temperature, dtime, nstep, nincr
│   │                                         • MD_MatAlgo: integration_scheme, tangent_type
│   │                                         【常量定义】
│   │                                         • MAT_ELASTIC=1, MAT_PLASTIC=2, MAT_HYPERELASTIC=3, MAT_VISCOELASTIC=4
│   │                                         • MAT_CREEP=5, MAT_DAMAGE=6, MAT_COMPOSITE=7, MAT_THERMAL=8
│   │                                         • MAT_GEOLOGICAL=9, MAT_ACOUSTIC=10, MAT_USER=11
│   │
│   ├── MD_Mat_Sync.f90                  → 同步
│   │                                         【子程序清单】
│   │                                         • MD_Mat_SyncFromLegacy(In model_def, InOut domain, Out status) → 同步Legacy数据
│   │
│   │
│   ├── Elas/                            [弹性材料子域 - 保留]
│   │                                         【设计意图】
│   │                                         提供线弹性本构模型(各向同性/正交各向异性/横向各向同性/各向异性)的
│   │                                         参数定义与校验,支持E/nu/lambda/mu/K五种弹性常数。
│   │                                         理论链: Hooke定律 σ=C:ε, 各向同性σ=λtr(ε)I+2με
│   │                                         逻辑链: L6_AP解析*ELASTIC → MD_Mat_ELA_* → MD_Mat_Domain
│   │                                         数据链: IsoElastic_MatDesc/OrthoElastic_MatDesc等Desc类型
│   │                                         计算链: InitFromProps→ValidateProps→ComputeLame
│   │
│   │   ├── MD_Mat_ELA_Isotropic.f90    → 各向同性弹性 (84行)
│   │                                         【子程序清单】
│   │                                         • UF_IsoElas_L3_ValidateProps(In nprops, In props, Out st) → 校验参数
│   │                                         • UF_IsoElas_L3_InitFromProps(Out desc, In nprops, In props, Out st) → 从参数初始化
│   │                                         【类型定义】
│   │                                         • IsoElastic_MatDesc(E, nu, lambda, mu, K, is_initialized)
│   │                                         【接口契约】
│   │                                         • props(1)=E, props(2)=nu, nProps_min=2
│   │
│   │   ├── MD_Mat_ELA_Orthotropic.f90   → 正交各向异性弹性
│   │   ├── MD_Mat_ELA_TransIsotropic.f90 → 横向各向同性弹性
│   │   ├── MD_Mat_ELA_Anisotropic.f90   → 各向异性弹性
│   │   ├── MD_Mat_ELA_Hypoelastic.f90    → 次弹性
│   │   └── MD_Mat_ELA_Porous.f90        → 多孔弹性
│   │                                         【废弃: Elastic/ (3 files) → 已合并至Elas/】
│   │
│   ├── Plast/                           [塑性材料子域 - 保留]
│   │                                         【设计意图】
│   │                                         提供J2/Mises、Chaboche、Hill、Crystal等塑性本构模型的参数定义、
│   │                                         屈服准则、硬化规律、流动法则的完整建模。
│   │                                         理论链: Von Mises σ_eq=√(3J2), 流动法则 df=∂f/∂σ dλ
│   │                                         逻辑链: L4_PH调用MD_Mat_PLM_* → L5_RT积分
│   │                                         数据链: VM_MatDesc/VM_MatState/VM_MatCtx/VM_MatAlgo四类TYPE
│   │                                         计算链: YieldCheck→FlowDirection→HardeningUpdate→ConsistentTangent
│   │
│   │   ├── MD_Mat_PLM_J2.f90            → J2等向硬化塑性 (404行)
│   │                                         【子程序清单】
│   │                                         • VM_MatDesc_InitFromProps(Out desc, In nprops, In props, Out st) → 初始化描述符
│   │                                         • VM_MatDesc_Valid(In desc, Out valid, Out st) → 校验描述符
│   │                                         • VM_MatState_InitFromInputs(Out state, In ntens, Out nprops, Out st) → 初始化状态
│   │                                         • VM_MatState_SyncToStateV(In state, Out statev, Out st) → 同步至状态变量
│   │                                         • VM_MatState_SyncFromStateV(InOut state, In statev, Out st) → 从状态变量同步
│   │                                         • VM_MatCtx_InitFromInputs(Out ctx, In ntens, In temp, In dtime, Out st) → 初始化上下文
│   │                                         【类型定义】
│   │                                         • VM_MatDesc(E, nu, sigma_y0, H, lambda, mu, K, hardening_type)
│   │                                         • VM_MatState(eps_p_eqv, eps_p(:), alpha(:), kappa)
│   │                                         • VM_MatCtx(ndir, nshr, ntens, temp, dtime, kstep, kinc)
│   │                                         【常量定义】
│   │                                         • MD_MAT_VM_PROP_E=1, MD_MAT_VM_PROP_NU=2, MD_MAT_VM_PROP_SY0=3, MD_MAT_VM_PROP_H=4
│   │
│   │   ├── MD_Mat_PLM_Chaboche.f90     → Chaboche随动硬化
│   │   ├── MD_Mat_PLM_Hill.f90         → Hill 48屈服准则
│   │   ├── MD_Mat_PLM_Crystal.f90      → 晶体塑性
│   │   ├── MD_Mat_PLM_JohnsonCook.f90  → Johnson-Cook
│   │   ├── MD_Mat_PLM_Barlat.f90       → Barlat Yld2000
│   │   ├── MD_Mat_PLM_CastIron.f90     → 铸铁塑性
│   │   ├── MD_Mat_PLM_Ceramic.f90      → 陶瓷塑性
│   │   ├── MD_Mat_PLM_RateDep.f90      → 率相关塑性
│   │   ├── MD_Mat_PLM_Viscoplastic.f90  → 粘塑性
│   │   ├── MD_Mat_PLM_ThermoVisc.f90   → 热粘塑性
│   │   ├── MD_Mat_PLM_BiVisc.f90        → 双粘塑性
│   │   ├── MD_Mat_PLM_ViscDmgEM.f90     → 粘塑性与电磁损伤
│   │   ├── MD_Mat_PLM_Za.f90           → Zafferri模型
│   │   ├── MD_Mat_PLM_Nano.f90         → 纳米塑性
│   │   ├── MD_Mat_PLM_Deformation.f90  → 变形塑性
│   │   ├── MD_Mat_PLM_MixedHard.f90     → 混合硬化
│   │   ├── MD_Mat_PLM_SwiftVoce.f90    → Swift-Voce硬化
│   │   ├── MD_Mat_PLM_ORNL.f90         → ORNL模型
│   │   ├── MD_Mat_PLM_Fgm.f90          → 功能梯度材料
│   │   ├── MD_Mat_PLM_Temm.f90         → TEMM模型
│   │   ├── MD_Mat_PLM_TwoLayer.f90     → 双层蠕变
│   │   ├── MD_Mat_PLM_SmartMat.f90     → 智能材料
│   │                                         【废弃: Plastic/ (11 files) → 已合并至Plast/】
│   │
│   ├── HyperElas/                       [超弹性材料子域 - 保留]
│   │                                         【设计意图】
│   │                                         提供Neo-Hookean/Mooney-Rivlin/Ogden/Yeoh等橡胶类超弹性本构的
│   │                                         应变能函数W(I1,I2,I3)定义与主伸长λ分析。
│   │                                         理论链: W=ΣCij(I1-3)^i(I2-3)^j+ΣDik(J-1)^2i, I1/I2/I3为应变不变量
│   │                                         逻辑链: L4_PH调用MD_Mat_HYP_* → 主伸长计算 → PK2应力
│   │                                         数据链: NeoHookean_MatDesc/MooneyRivlin_MatDesc等
│   │                                         计算链: ComputeInvariants→StrainEnergyDensity→PK2Stress→ConsistentTangent
│   │
│   │   ├── MD_Mat_HYP_NeoHookean.f90   → Neo-Hookean (87行)
│   │                                         【子程序清单】
│   │                                         • UF_NeoHookean_L3_ValidateProps(In nprops, In props, Out st) → 校验参数
│   │                                         • UF_NeoHookean_L3_InitFromProps(Out desc, In nprops, In props, Out st) → 初始化
│   │                                         【类型定义】
│   │                                         • NeoHookean_MatDesc(C10, D1, is_incompressible)
│   │                                         【接口契约】
│   │                                         • props(1)=C10, props(2)=D1, nProps_min=2
│   │
│   │   ├── MD_Mat_HYP_MooneyRivlin.f90 → Mooney-Rivlin
│   │   ├── MD_Mat_HYP_Ogden.f90         → Ogden (N阶)
│   │   ├── MD_Mat_HYP_Yeoh.f90         → Yeoh
│   │   ├── MD_Mat_HYP_Marlow.f90        → Marlow
│   │   ├── MD_Mat_HYP_ArrudaBoyce.f90  → Arruda-Boyce
│   │   ├── MD_Mat_HYP_Polynomial.f90    → 多项式形式
│   │   ├── MD_Mat_HYP_ReducedPolynomial.f90 → 简化多项式
│   │   ├── MD_Mat_HYP_PermanentSet.f90 → 永久变形
│   │   ├── MD_Mat_HYP_StressSoftening.f90 → 应力软化
│   │                                         【废弃: HyperElastic/ (13 files) → 已合并至HyperElas/】
│   │
│   ├── Viscoelas/                       [粘弹性材料子域 - 保留]
│   │                                         【设计意图】
│   │                                         提供Prony级数/Maxwell/Kelvin-Voigt等粘弹性本构的时间相关响应建模, 
│   │                                         支持松弛模量G(t)和蠕变柔量J(t)的标准线性固体(SLS)表示。
│   │                                         理论链: σ(t)=∫₀ᵗ G(t-τ) dε/dτ dτ, G(t)=G∞+ΣGi exp(-t/ρi)
│   │                                         逻辑链: L4_PH调用MD_Mat_VSC_* → 卷积积分
│   │                                         数据链: LinearVisco_MatDesc/NonlinearVisco_MatDesc
│   │                                         计算链: ComputePronyWeights→ConvolutionIntegral→EffectiveStress
│   │
│   │   ├── MD_Mat_VSC_LinearVisco.f90   → 线性粘弹性 (40行)
│   │                                         【子程序清单】
│   │                                         • UF_LinearVisco_L3_ValidateProps(In nprops, In props, Out st) → 校验参数
│   │                                         • UF_LinearVisco_L3_InitPlaceholder(Out st) → 占位符初始化
│   │                                         【类型定义】
│   │                                         • LinearVisco_MatDesc(reserved)
│   │
│   │   ├── MD_Mat_VSC_NonlinearVisco.f90 → 非线性粘弹性
│   │   ├── MD_Mat_VSC_Perzyna.f90       → Perzyna粘塑性
│   │   ├── MD_Mat_VSC_Creep.f90         → 蠕变粘弹性
│   │   ├── MD_Mat_VSC_RateDepCreep.f90  → 率相关蠕变
│   │   ├── MD_Mat_VSC_Swelling.f90       → 溶胀粘弹性
│   │   ├── MD_Mat_VSC_ThermoVisco.f90   → 热粘弹性
│   │   ├── MD_Mat_VSC_ViscoBase.f90     → 粘弹性基类
│   │   ├── MD_Mat_VSC_ViscoElastPlast.f90 → 粘弹塑性
│   │                                         【废弃: Viscoelastic/ (4 files) → 已合并至Viscoelas/】
│   │
│   ├── Creep/                           [蠕变材料子域]
│   │                                         【设计意图】
│   │                                         提供PowerLaw/Bairstow/Duvaut-Lions等蠕变本构的时间硬化/应变硬化建模, 
│   │                                         支持金属高温蠕变的 Norton-Bailey 法则。
│   │                                         理论链: ε̇c=A σⁿ exp(-Q/RT) t^m, 三段蠕变(初始/稳态/加速)
│   │                                         逻辑链: L4_PH调用MD_Crp_* → 蠕变应变增量计算
│   │                                         计算链: ComputeCreepStrainRate→TimeHardening→StrainHardening
│   │
│   │   ├── MD_Crp_PowerLaw.f90          → 幂律蠕变
│   │   ├── MD_Crp_Perzyna.f90          → Perzyna蠕变
│   │   ├── MD_Crp_Bairstow.f90         → Bairstow蠕变
│   │   ├── MD_Crp_Garofalo.f90         → Garofalo蠕变
│   │   ├── MD_Crp_DuvautLions.f90      → Duvaut-Lions
│   │   ├── MD_Crp_Anneal.f90           → 退火蠕变
│   │   ├── MD_Crp_TwoLayer.f90         → 双层蠕变
│   │   ├── MD_Crp_UserDef.f90          → 用户定义蠕变
│   │   └── MD_Mat_MPH_*.f90            → 多孔介质(5 files)
│   │
│   ├── Damage/                          [损伤材料子域]
│   │                                         【设计意图】
│   │                                         提供CDP/Brittle/Ductile/Fatigue等损伤本构的等效应力/损伤因子D建模, 
│   │                                         支持脆性断裂与延性破坏的耦合分析。
│   │                                         理论链: σ̃=σ/(1-D), D∈[0,1], Ḋ=f(σ,ε,κ)
│   │                                         逻辑链: L4_PH调用MD_Dmg_* → 有效应力计算 → 损伤演化
│   │                                         计算链: ComputeEquivalentStress→DamageInitiation→DamageEvolution→EffectiveStress
│   │
│   │   ├── MD_Dmg_CDP.f90              → 混凝土损伤塑性(CDP)
│   │   ├── MD_Dmg_Brittle.f90          → 脆性损伤
│   │   ├── MD_Dmg_Ductile.f90          → 延性损伤
│   │   ├── MD_Mat_DMG_*.f90            → 高级损伤模型(8 files)
│   │   └── MD_Mat_DMG_LowCycleFatigue.f90 → 低周疲劳
│   │
│   ├── Geo/                             [地质材料子域 - 保留]
│   │                                         【设计意图】
│   │                                         提供Drucker-Prager/Mohr-Coulomb/Cam-Clay等地质材料的非线性屈服建模, 
│   │                                         支持岩土工程的剪切破坏与体积屈服分析。
│   │                                         理论链: f=αI1+√J2-k=0 (DP), τ=c-σ_n tanφ (MC)
│   │                                         逻辑链: L4_PH调用MD_Mat_PLG_* → 地质材料积分
│   │                                         计算链: ComputeP q→StressInvariants→YieldFunction→PlasticPotential→FlowDirection
│   │
│   │   ├── MD_Mat_PLG_DruckerPrager.f90 → Drucker-Prager
│   │   ├── MD_Mat_PLG_MohrCoulomb.f90   → Mohr-Coulomb
│   │   ├── MD_Mat_PLG_CamClay.f90       → Cam-Clay
│   │   ├── MD_Mat_PLG_Cap.f90           → Cap模型
│   │   ├── MD_Mat_PLG_ConcreteDamage.f90 → 混凝土损伤
│   │   ├── MD_Mat_PLG_Joint.f90         → 节理
│   │   ├── MD_Mat_PLG_SmearedCrack.f90  → 弥散裂缝
│   │   ├── MD_Mat_PLG_BrittleCrack.f90  → 脆性裂缝
│   │   ├── MD_Mat_PLG_SoftRock.f90      → 软岩
│   │   ├── MD_Mat_PLG_Soil.f90          → 土体
│   │   └── MD_Mat_PLG_Geotech.f90       → 地质工程
│   │                                         【废弃: Geomaterial/ (2 files) → 已合并至Geo/】
│   │
│   ├── Composite/                       [复合材料子域]
│   │                                         【设计意图】
│   │                                         提供层合板/夹杂物/微观力学的等效性质计算,支持连续纤维/短纤维/颗粒增强复合材料的分析。
│   │                                         理论链: 混合率 σc=Σ Vi σi, Chamis公式 E1/E2/G12预测
│   │                                         计算链: RuleOfMixtures→HalpinTsai→Micromechanics
│   │
│   │   ├── MD_CMP_Laminate.f90          → 层合板
│   │   ├── MD_CMP_Inclusion.f90        → 夹杂物
│   │   └── ... (8 more files)
│   │
│   ├── Thermal/                         [热材料子域]
│   │                                         【设计意图】
│   │                                         提供热传导/热容/热膨胀等热力耦合参数定义。
│   │                                         理论链: Fourier定律 q=-k∇T, 热容 C=ρcp
│   │
│   │   ├── MD_Thm_Conductivity.f90      → 热传导
│   │   ├── MD_Thm_SpecificHeat.f90     → 比热容
│   │   └── ... (6 more files)
│   │
│   ├── Acoustic/                        [声学材料子域]
│   │                                         【设计意图】
│   │                                         提供声波传播介质的压力-体积模量关系建模。
│   │                                         理论链: p=-K∇·u, 声速 c=√(K/ρ)
│   │
│   │   └── MD_Aco_*.f90 (4 files)
│   │
│   ├── Cohesive/                       [内聚力材料子域 - L4_PH同步]
│   │                                         【设计意图】
│   │                                         提供粘接界面/胶层/裂缝尖端的内聚力模型,支持牵引-分离定律。
│   │                                         理论链: σ=K·δ, 断裂准则 G≥Gc
│   │                                         逻辑链: L4_PH调用MD_Coh_* → 界面应力 → 断裂判断
│   │                                         计算链: ComputeTraction→DamageInitiation→SofteningEvolution
│   │
│   │   ├── MD_Coh_TractionSep.f90          → 牵引-分离定律
│   │   ├── MD_Coh_PowerLaw.f90            → 幂律混合模式
│   │   └── MD_Coh_BK.f90                  → BK混合模式
│   │
│   ├── User/                            [用户材料子域 - 保留]
│   │                                         【设计意图】
│   │                                         提供UMAT/VUMAT用户自定义材料接口,支持任意本构模型的二次开发。
│   │                                         逻辑链: L4_PH调用MD_Usr_UMAT/VUMAT → 用户实现
│   │                                         数据链: MD_Usr_UMAT_State/MD_Usr_VUMAT_State
│   │
│   │   ├── MD_Usr_UMAT.f90             → 用户材料子程序
│   │   ├── MD_Usr_VUMAT.f90            → 用户显式材料子程序
│   │   ├── MD_Mat_SPU_*.f90            → 特殊用途材料(6 files)
│   │                                         【废弃: MD_Usr_Ext1.f90, MD_Usr_Ext2.f90 → 与UMAT/VUMAT功能重复,须删除】
│   │                                         【废弃: UserDefined/ (4 files) → 已合并至User/】
│   │
│   ├── Base/                            [材料基础子域]
│   │                                         【设计意图】
│   │                                         提供材料域的基础类型、注册表、验证核心等公共基础设施。
│   │
│   │   ├── MD_Mat_Ids.f90              → 材料ID常量定义
│   │   ├── MD_Mat_Types_Base.f90       → 基础TYPE定义
│   │   └── MD_Mat_Registry.f90         → 材料注册表
│   │
│   ├── Shared/                          [共享材料子域]
│   │                                         【设计意图】
│   │                                         提供跨材料类型共享的验证/计算核心(Prony/Elastic验证等)。
│   │
│   │   └── MD_Mat_Shared_*.f90 (18 files)
│   │
│   ├── CONTRACT.md                      → 契约文档
│   └── DESIGN_MatMD_FourTypes.md        → 四型设计
│
│
├── Element/                              [⭐ 核心域: 12大族245种单元(含变体377)]
│   ├── MD_Elem_Core.f90                 → 单元核心
│   ├── MD_Elem_API.f90                  → 单元API
│   ├── MD_Elem_Types.f90                → 类型定义 (合并)
│   ├── MD_Elem_Domain.f90               → 单元域
│   ├── MD_Elem_Populate.f90             → 数据填充
│   ├── MD_Elem_Validate.f90             → 验证
│   ├── MD_Elem_Registry.f90            → 单元注册表
│   ├── MD_Elem_Sync.f90                 → 同步
│   │
│   ├── Solid3D/                         [1️⃣ 3D实体子域: 18种]
│   │   ├── MD_Elem_Solid3D_Core.f90    → 3D实体核心
│   │   ├── MD_Elem_Solid3D_Types.f90   → 3D实体类型 (合并)
│   │   ├── MD_Elem_C3D8.f90            → C3D8 (8节点线性)
│   │   ├── MD_Elem_C3D8R.f90           → C3D8R (缩减积分)
│   │   ├── MD_Elem_C3D8I.f90           → C3D8I (非协调模式)
│   │   ├── MD_Elem_C3D8RH.f90          → C3D8RH (杂交)
│   │   ├── MD_Elem_C3D20.f90           → C3D20 (20节点二次)
│   │   ├── MD_Elem_C3D20R.f90          → C3D20R (缩减积分)
│   │   ├── MD_Elem_C3D4.f90             → C3D4 (4节点四面体)
│   │   ├── MD_Elem_C3D10.f90            → C3D10 (10节点四面体)
│   │   ├── MD_Elem_C3D10M.f90           → C3D10M (修正)
│   │   ├── MD_Elem_C3D6.f90             → C3D6 (6节点楔形)
│   │   ├── MD_Elem_C3D15.f90            → C3D15 (15节点楔形)
│   │   ├── MD_Elem_C3D8T.f90            → C3D8T (温度)
│   │   ├── MD_Elem_C3D20T.f90           → C3D20T (温度)
│   │   ├── MD_Elem_C3D8P.f90            → C3D8P (孔隙压力)
│   │   ├── MD_Elem_C3D20P.f90           → C3D20P (孔隙压力)
│   │   ├── MD_Elem_C3D8E.f90            → C3D8E (压电)
│   │   └── MD_Elem_C3D20E.f90           → C3D20E (压电)
│   │
│   ├── Shell/                           [2️⃣ 壳单元子域: 24种]
│   │   ├── MD_Elem_Shell_Core.f90      → 壳核心
│   │   ├── MD_Elem_Shell_Types.f90     → 壳类型 (合并)
│   │   ├── MD_Elem_S3.f90               → S3 (3节点线性)
│   │   ├── MD_Elem_S4.f90               → S4 (4节点线性)
│   │   ├── MD_Elem_S4R.f90              → S4R (缩减积分)
│   │   ├── MD_Elem_S4R5.f90              → S4R5 (5自由度)
│   │   ├── MD_Elem_S8R.f90              → S8R (8节点二次)
│   │   ├── MD_Elem_S8R5.f90             → S8R5 (5自由度)
│   │   ├── MD_Elem_S9R5.f90             → S9R5 (9节点)
│   │   ├── MD_Elem_STRI3.f90            → STRI3 (3节点薄膜)
│   │   ├── MD_Elem_STRI65.f90           → STRI65 (6节点)
│   │   ├── MD_Elem_S3R.f90              → S3R (3节点缩减)
│   │   ├── MD_Elem_S4RS.f90             → S4RS (小应变)
│   │   ├── MD_Elem_S4RSW.f90            → S4RSW (大应变)
│   │   ├── MD_Elem_S3T.f90              → S3T (温度)
│   │   ├── MD_Elem_S4T.f90              → S4T (温度)
│   │   ├── MD_Elem_S8RT.f90             → S8RT (温度)
│   │   ├── MD_Elem_S3P.f90              → S3P (孔隙压力)
│   │   ├── MD_Elem_S4P.f90              → S4P (孔隙压力)
│   │   ├── MD_Elem_S8RP.f90             → S8RP (孔隙压力)
│   │   ├── MD_Elem_S3E.f90              → S3E (压电)
│   │   ├── MD_Elem_S4E.f90              → S4E (压电)
│   │   ├── MD_Elem_S8RE.f90             → S8RE (压电)
│   │   ├── MD_Elem_SC8R.f90             → SC8R (连续壳)
│   │   ├── MD_Elem_M3D3.f90             → M3D3 (膜)
│   │   └── MD_Elem_M3D4R.f90            → M3D4R (膜)
│   │
│   ├── Beam/                            [3️⃣ 梁单元子域: 16种]
│   │   ├── MD_Elem_Beam_Core.f90        → 梁核心
│   │   ├── MD_Elem_Beam_Types.f90       → 梁类型 (合并)
│   │   ├── MD_Elem_B31.f90              → B31 (2节点线性)
│   │   ├── MD_Elem_B31R.f90             → B31R (缩减积分)
│   │   ├── MD_Elem_B32.f90              → B32 (3节点二次)
│   │   ├── MD_Elem_B32R.f90             → B32R (缩减积分)
│   │   ├── MD_Elem_B33.f90              → B33 (3节点三次)
│   │   ├── MD_Elem_B31OS.f90            → B31OS (开口截面)
│   │   ├── MD_Elem_B32OS.f90            → B32OS (开口截面)
│   │   ├── MD_Elem_B31T.f90             → B31T (温度)
│   │   ├── MD_Elem_B32T.f90             → B32T (温度)
│   │   ├── MD_Elem_B31P.f90             → B31P (孔隙压力)
│   │   ├── MD_Elem_B32P.f90             → B32P (孔隙压力)
│   │   ├── MD_Elem_PIPE31.f90           → PIPE31 (管道)
│   │   ├── MD_Elem_PIPE32.f90           → PIPE32 (管道)
│   │   ├── MD_Elem_B31H.f90             → B31H (杂交)
│   │   └── MD_Elem_B32H.f90             → B32H (杂交)
│   │
│   ├── Truss/                          [4️⃣ 桁架子域: 6种]
│   │   ├── MD_Elem_Truss_Core.f90       → 桁架核心
│   │   ├── MD_Elem_Truss_Types.f90      → 桁架类型 (合并)
│   │   ├── MD_Elem_T2D2.f90             → T2D2 (2D 2节点)
│   │   ├── MD_Elem_T2D3.f90             → T2D3 (2D 3节点)
│   │   ├── MD_Elem_T3D2.f90             → T3D2 (3D 2节点)
│   │   ├── MD_Elem_T3D3.f90             → T3D3 (3D 3节点)
│   │   └── MD_Elem_T2D2H.f90            → T2D2H (杂交)
│   │
│   ├── Solid2D/                         [5️⃣ 2D实体子域: 18种]
│   │   ├── MD_Elem_Solid2D_Core.f90     → 2D实体核心
│   │   ├── MD_Elem_Solid2D_Types.f90     → 2D实体类型 (合并)
│   │   ├── MD_Elem_CPE3.f90             → CPE3 (平面应变)
│   │   ├── MD_Elem_CPE4.f90             → CPE4 (平面应变)
│   │   ├── MD_Elem_CPE4R.f90            → CPE4R (缩减积分)
│   │   ├── MD_Elem_CPE6M.f90            → CPE6M (修正)
│   │   ├── MD_Elem_CPS3.f90             → CPS3 (平面应力)
│   │   ├── MD_Elem_CPS4.f90             → CPS4 (平面应力)
│   │   ├── MD_Elem_CPS4R.f90            → CPS4R (缩减积分)
│   │   ├── MD_Elem_CPS6M.f90            → CPS6M (修正)
│   │   ├── MD_Elem_CAX3.f90             → CAX3 (轴对称)
│   │   ├── MD_Elem_CAX4.f90             → CAX4 (轴对称)
│   │   ├── MD_Elem_CAX4R.f90            → CAX4R (缩减积分)
│   │   ├── MD_Elem_CAX6M.f90            → CAX6M (修正)
│   │   ├── MD_Elem_CPE3T.f90            → CPE3T (温度)
│   │   ├── MD_Elem_CPE4T.f90            → CPE4T (温度)
│   │   ├── MD_Elem_CPS3T.f90            → CPS3T (温度)
│   │   ├── MD_Elem_CPS4T.f90            → CPS4T (温度)
│   │   ├── MD_Elem_CAX3T.f90            → CAX3T (温度)
│   │   └── MD_Elem_CAX4T.f90            → CAX4T (温度)
│   │
│   ├── Infinite/                       [6️⃣ 无限元子域: 8种]
│   │   ├── MD_Elem_Infinite_Core.f90    → 无限元核心
│   │   ├── MD_Elem_Infinite_Types.f90   → 无限元类型 (合并)
│   │   ├── MD_Elem_CIN2D3.f90           → CIN2D3 (2D 3节点)
│   │   ├── MD_Elem_CIN2D4.f90           → CIN2D4 (2D 4节点)
│   │   ├── MD_Elem_CINAX3.f90           → CINAX3 (轴对称)
│   │   ├── MD_Elem_CINAX4.f90           → CINAX4 (轴对称)
│   │   ├── MD_Elem_CIN3D6.f90           → CIN3D6 (3D 6节点)
│   │   ├── MD_Elem_CIN3D8.f90           → CIN3D8 (3D 8节点)
│   │   ├── MD_Elem_CINPE4.f90           → CINPE4 (平面应变)
│   │   └── MD_Elem_CIN3D8T.f90          → CIN3D8T (温度)
│   │
│   ├── Cohesive/                       [7️⃣ 内聚力单元子域: 12种]
│   │   ├── MD_Elem_Cohesive_Core.f90    → 内聚力核心
│   │   ├── MD_Elem_Cohesive_Types.f90   → 内聚力类型 (合并)
│   │   ├── MD_Elem_COH2D3.f90           → COH2D3 (2D 3节点)
│   │   ├── MD_Elem_COH2D4.f90           → COH2D4 (2D 4节点)
│   │   ├── MD_Elem_COHAX3.f90           → COHAX3 (轴对称)
│   │   ├── MD_Elem_COHAX4.f90           → COHAX4 (轴对称)
│   │   ├── MD_Elem_COH3D6.f90           → COH3D6 (3D 6节点)
│   │   ├── MD_Elem_COH3D8.f90           → COH3D8 (3D 8节点)
│   │   ├── MD_Elem_COH2D4T.f90          → COH2D4T (温度)
│   │   ├── MD_Elem_COH3D8T.f90          → COH3D8T (温度)
│   │   ├── MD_Elem_COH2D4P.f90          → COH2D4P (孔隙压力)
│   │   ├── MD_Elem_COH3D8P.f90          → COH3D8P (孔隙压力)
│   │   ├── MD_Elem_COH2D4E.f90          → COH2D4E (压电)
│   │   └── MD_Elem_COH3D8E.f90          → COH3D8E (压电)
│   │
│   ├── Spring/                         [8️⃣ 弹簧子域: 4种]
│   │   ├── MD_Elem_Spring_Core.f90      → 弹簧核心
│   │   ├── MD_Elem_Spring_Types.f90     → 弹簧类型 (合并)
│   │   ├── MD_Elem_SPRING1.f90          → SPRING1 (单节点)
│   │   ├── MD_Elem_SPRING2.f90          → SPRING2 (双节点)
│   │   └── MD_Elem_SPRINGA.f90          → SPRINGA (轴向)
│   │
│   ├── Dashpot/                        [9️⃣ 阻尼器子域: 2种]
│   │   ├── MD_Elem_Dashpot_Core.f90     → 阻尼器核心
│   │   ├── MD_Elem_Dashpot_Types.f90    → 阻尼器类型 (合并)
│   │   ├── MD_Elem_DASHPOT1.f90         → DASHPOT1 (单节点)
│   │   └── MD_Elem_DASHPOT2.f90         → DASHPOT2 (双节点)
│   │
│   ├── Mass/                           [🔟 质量单元子域: 2种]
│   │   ├── MD_Elem_Mass_Core.f90        → 质量核心
│   │   ├── MD_Elem_Mass_Types.f90       → 质量类型 (合并)
│   │   ├── MD_Elem_MASS.f90             → MASS (集中质量)
│   │   └── MD_Elem_MASS2D.f90           → MASS2D (2D质量)
│   │
│   ├── Gasket/                        [1️⃣1️⃣ 垫片子域: 6种]
│   │   ├── MD_Elem_Gasket_Core.f90      → 垫片核心
│   │   ├── MD_Elem_Gasket_Types.f90     → 垫片类型 (合并)
│   │   ├── MD_Elem_GS6.f90              → GS6 (6节点)
│   │   ├── MD_Elem_GS8.f90              → GS8 (8节点)
│   │   ├── MD_Elem_GS6T.f90             → GS6T (温度)
│   │   ├── MD_Elem_GS8T.f90             → GS8T (温度)
│   │   ├── MD_Elem_GK6.f90              → GK6 (轴对称)
│   │   └── MD_Elem_GK8.f90              → GK8 (轴对称)
│   │
│   └── Surface/                       [1️⃣2️⃣ 表面效应子域: 8种]
│       ├── MD_Elem_Surface_Core.f90     → 表面核心
│       ├── MD_Elem_Surface_Types.f90    → 表面类型 (合并)
│       ├── MD_Elem_SF2D3.f90            → SF2D3 (2D 3节点)
│       ├── MD_Elem_SF2D4.f90            → SF2D4 (2D 4节点)
│       ├── MD_Elem_SF3D3.f90            → SF3D3 (3D 3节点)
│       ├── MD_Elem_SF3D4.f90            → SF3D4 (3D 4节点)
│       ├── MD_Elem_SF3D6.f90            → SF3D6 (3D 6节点)
│       ├── MD_Elem_SF3D8.f90            → SF3D8 (3D 8节点)
│       ├── MD_Elem_SFM3D3.f90           → SFM3D3 (膜)
│       └── MD_Elem_SFM3D4.f90           → SFM3D4 (膜)
│   │
│   │                                         【设计意图】
│   │                                         L3_MD层Element域负责单元参数的注册与管理，作为L4_PH层物理计算的冷路径数据源。
│   │                                         每个单元族对应独立的子域目录，实现单元参数的Desc/State/Algo/Ctx四型分离。
│   │                                         理论链: ABAQUS单元关键字 → MD_Elem_*_Desc → PH_Elem_*_Core计算
│   │                                         逻辑链: INPUT解析 → MD_Element_Registry → L4_PH单元分发
│   │                                         数据链: MD_Elem_*_Desc(MD) → PH_Elem_*_State(PH)
│   │
│   │   │                                         【L3_MD ↔ L4_PH 单元绑定映射表】
│   │   │                                         ─────────────────────────────────────────────
│   │   │                                         L3_MD子域          L4_PH子域          单元数 绑定常量
│   │   │                                         ─────────────────────────────────────────────
│   │   │                                         MD_Elem_Solid3D   PH_Elem_SLD3D       18   BIND_SOLID3D
│   │   │                                         MD_Elem_Shell      PH_Elem_SHELL       24   BIND_SHELL
│   │   │                                         MD_Elem_Beam       PH_Elem_BEAM        16   BIND_BEAM
│   │   │                                         MD_Elem_Truss      PH_Elem_TRUSS       6    BIND_TRUSS
│   │   │                                         MD_Elem_Solid2D    PH_Elem_SLD2D       18   BIND_SOLID2D
│   │   │                                         MD_Elem_Infinite   PH_Elem_INFINITE    8    BIND_INFINITE
│   │   │                                         MD_Elem_Cohesive   PH_Elem_SPECIAL    12   BIND_COHESIVE
│   │   │                                         MD_Elem_Spring     PH_Elem_SPRING     4    BIND_SPRING
│   │   │                                         MD_Elem_Dashpot    PH_Elem_DASHPOT    2    BIND_DASHPOT
│   │   │                                         MD_Elem_Mass       PH_Elem_SPECIAL    2    BIND_MASS
│   │   │                                         MD_Elem_Gasket     PH_Elem_SPECIAL    6    BIND_GASKET
│   │   │                                         MD_Elem_Surface    (载荷施加)         8    BIND_SURFACE
│   │   │                                         ─────────────────────────────────────────────
│   │   │                                         合计:              12族              124
│   │   │
│   │   │                                         【数据流契约】
│   │   │                                         L3_MD(Cold) ──→ L4_PH(Hot)
│   │   │                                         MD_Elem_XXX_Desc ──→ PH_Elem_XXX_Ctx
│   │   │                                         MD_Elem_XXX_Algo(TYPE四型) ──→ PH_Elem_XXX_State(计算结果回写)
│   │   │                                         *L3 族 MODULE 实现名：`MD_Elem*_*_Ops`，见 `UFC/docs/03_Domain_Pillars/DomainProcedureRegistry/design/L3_MD/Mesh/INTENT.md`*
│   │   │
│
├── Mesh/                                 [网格]
│   │                                      设计意图：L3_MD层"拓扑真相源"
│   │                                      核心职责：节点/单元/DOF映射/表面定义
│   │                                      对标ABAQUS：mdb.models[].parts[].nodes/elements/nsets/elsets/surfaces
│   │                                      四链贯通：理论(离散化)→逻辑(L6→Init→冻结→L4/L5查询)→计算(O(1)查询)→数据(Desc冻结/State回写)
│   │
│   ├── MD_Mesh_Domain_Core.f90          → 域容器总控 (909行)
│   │   │                                  【TYPE定义】
│   │   │                                  MeshAlgo          - 算法参数(积分阶数/几何非线性)
│   │   │                                  MD_Mesh_Domain    - 统一域容器(10字段+12过程绑定)
│   │   │                                  8个Arg类型        - Phase 2参数容器
│   │   │
│   │   │                                  【生命周期子程序】
│   │   │                                  MD_Mesh_Domain_Init            → 初始化域容器(nNodes/nElems/spatialDim)
│   │   │                                  MD_Mesh_Domain_Finalize        → 释放资源(node_desc/elem_desc/node_state/elem_state/raw_data)
│   │   │
│   │   │                                  【只读查询子程序】(L4/L5热路径)
│   │   │                                  MD_Mesh_Domain_GetNodeCoords   → O(1)获取节点坐标(调用raw_data%GetNodeCoords)
│   │   │                                  MD_Mesh_Domain_GetElemConnect  → O(1)获取单元连接(调用raw_data%GetElementConnectivity)
│   │   │                                  MD_Mesh_Domain_GetElemSection  → O(1)获取截面引用(返回section_ref)
│   │   │                                  MD_Mesh_Domain_GetDofMap       → O(1)获取DOF映射(返回dofStartIndex+nDof)
│   │   │                                  MD_Mesh_Domain_GetSurfaceByName→ O(nSurfaces)按名查表面(Interaction用)
│   │   │                                  MD_Mesh_Domain_GetNodeByName   → O(nNodes)按名查节点(L6解析用)
│   │   │                                  MD_Mesh_Domain_GetSummary      → 获取域摘要信息
│   │   │
│   │   │                                  【WriteBack白名单子程序】(L5→L3单向)
│   │   │                                  MD_Mesh_WriteBack_NodePos      → 回写节点坐标(node_state%currentCoords)
│   │   │                                  MD_Mesh_WriteBack_NodeDisp     → 回写位移(node_state%disp)
│   │   │                                  MD_Mesh_WriteBack_NodeVel      → 回写速度(node_state%vel)
│   │   │                                  MD_Mesh_WriteBack_NodeAcc      → 回写加速度(node_state%acc)
│   │   │                                  MD_Mesh_WriteBack_ElemStress   → 回写积分点应力(elem_state%ipStates%sigma)
│   │   │                                  MD_Mesh_WriteBack_State        → 回写状态标记(state%nAssembled)
│   │   │
│   │   │                                  【独立索引API】(Phase 2，无容器调用)
│   │   │                                  MD_Mesh_GetNodeCoords_Idx      → (node_idx, arg, status) via g_ufc_global
│   │   │                                  MD_Mesh_GetElemConnect_Idx     → (elem_idx, arg, status) via g_ufc_global
│   │   │                                  MD_Mesh_GetDofMap_Idx          → (node_idx, arg, status) via g_ufc_global
│   │   │                                  MD_Mesh_GetElemSection_Idx     → (elem_idx, arg, status) via g_ufc_global
│   │   │                                  MD_Mesh_WriteBack_NodePos_Idx  → (node_idx, arg, status) 白名单校验
│   │   │                                  MD_Mesh_GetSurfaceByName_Idx   → (name, arg, status) via g_ufc_global
│   │   │                                  MD_Mesh_GetNodeByName_Idx      → (name, arg, status) via g_ufc_global
│   │   │                                  MD_Mesh_WriteBack_ElemStress_Idx→ (elem_idx, arg, status) ip_idx校验
│   │
│   ├── MD_Mesh_Core.f90                 → 向后兼容层 (4346行)
│   │   │                                  职责：包装新模块接口，保留遗留代码兼容性
│   │   │                                  导入：MD_Mesh_Data/MD_Mesh_Node/MD_Mesh_Elem/MD_Mesh_Mgr/MD_Mesh_GlobalNum/MD_Mesh_API
│   │   │                                  包含：NodeGlobalMapEntry/ElemGlobalMapEntry/MeshGlobalNum重复定义(待清理)
│   │   │                                  状态：Phase B过渡期，Phase C清理后将废弃
│   │
│   ├── MD_Mesh_API.f90                  → 只读API接口 (192行)
│   │   │                                  【查询函数】
│   │   │                                  MD_Mesh_IsAvailable            → 检查网格可用性(g_ufc_global%IsReady + mesh%initialized)
│   │   │                                  MD_Mesh_GetNumElements         → 获取单元总数(raw_data%nElems)
│   │   │                                  MD_Mesh_GetNumNodes            → 获取节点总数(raw_data%nNodes)
│   │   │                                  MD_Mesh_GetElementFamily       → 获取单元族(TODO待实现)
│   │   │                                  MD_Mesh_GetElementDimension    → 获取空间维度(raw_data%spatial_dim)
│   │   │
│   │   │                                  【查询子程序】
│   │   │                                  MD_Mesh_GetElementConnectivity → 委托给mesh%GetElemConnect
│   │   │                                  MD_Mesh_GetNodeCoords          → 委托给mesh%GetNodeCoords(3坐标适配)
│   │   │
│   │   │                                  【转换函数】
│   │   │                                  Mesh_FromDesc                  → Desc_Mesh→MeshManager转换
│   │   │                                  Mesh_FromDesc_Data             → Desc_Mesh→MeshData转换(坐标/连接/类型)
│   │   │
│   │   │                                  【TYPE定义】
│   │   │                                  Desc_Mesh                      → API层网格描述(nNodes/nElems/dimension/coords/conn/types)
│   │
│   ├── MD_Mesh_Data.f90                 → 数据存储层 (~500行)
│   │   │                                  【TYPE定义】
│   │   │                                  MeshData        - 原始数据存储(node_coords/element_connect/element_types/elem_section_ref)
│   │   │                                  MeshDesc        - 网格描述(mesh_id/name/nNodes/nElems/spatial_dim/elem_family)
│   │   │                                  MeshState       - 网格状态(isActive/nAssembled)
│   │   │                                  MeshCtx         - 网格上下文(mesh_id/assembly_id/instance_id)
│   │   │
│   │   │                                  【核心子程序】
│   │   │                                  MeshData%Init                  → 分配存储(nNodes/nElems/spatialDim/maxNodesPerElem)
│   │   │                                  MeshData%Clean                 → 释放所有ALLOCATABLE数组
│   │   │                                  MeshData%GetNodeCoords         → O(1)返回node_coords(:,local_id)
│   │   │                                  MeshData%GetElementConnectivity→ O(1)返回element_connect(:,elem_id)
│   │   │                                  MeshData%AddNode               → 添加节点(coords/global_id)
│   │   │                                  MeshData%AddElement            → 添加单元(connect/elem_type/section_ref)
│   │
│   ├── MD_Mesh_Elem.f90                 → 单元网格 (~300行)
│   │   │                                  【TYPE定义】
│   │   │                                  MeshElemDesc    - 单元描述(elem_id/elem_type/npe/connectivity(:))
│   │   │                                  MeshElemState   - 单元状态(failed/suggest_cutback/requires_reasse/stableDt)
│   │   │
│   │   │                                  【常量定义】
│   │   │                                  MD_MESH_MAX_NODES_PER_ELEM = 27  → 最大节点数(支持C3D27)
│   │   │                                  MD_MESH_ELEMENT_TYPE_*       → 单元类型枚举(CP/C3/S4/S8/B2/B3等)
│   │
│   ├── MD_Mesh_Node.f90                 → 节点网格 (~200行)
│   │   │                                  【TYPE定义】
│   │   │                                  MeshNodeDesc    - 节点描述(global_node_id/coords(3))
│   │   │                                  MeshNodeState   - 节点状态(currentCoords(3)/disp(3)/vel(3)/acc(3))
│   │
│   ├── MD_Mesh_Mgr.f90                  → 全局管理器 (~100行)
│   │   │                                  【TYPE定义】
│   │   │                                  MeshManager     - 管理器(init/mesh:MeshData)
│   │   │
│   │   │                                  【全局实例】
│   │   │                                  g_mesh_manager  → MeshManager全局实例(待迁移到g_ufc_global)
│   │
│   ├── MD_Mesh_Sync.f90                 → 跨域同步 (~200行)
│   │   │                                  【核心子程序】
│   │   │                                  MD_Mesh_SyncFromLegacy       → 从Legacy模型定义同步到MD层
│   │   │
│   │   │                                  【同步逻辑】
│   │   │                                  1. 从model_def提取节点/单元数据
│   │   │                                  2. 调用MD_Mesh_Domain_Init初始化
│   │   │                                  3. 填充raw_data%node_coords/element_connect
│   │   │                                  4. 标记mesh%initialized = .TRUE.
│   │
│   ├── MD_Mesh_GlobalNum.f90            → 全局编号系统 (~500行)
│   │   │                                  【TYPE定义】
│   │   │                                  NodeGlobalMapEntry - 节点映射(globalNodeId/partIndex/instanceIndex/localNodeId/dofStartIndex/nDof)
│   │   │                                  ElemGlobalMapEntry - 单元映射(globalElemId/partIndex/instanceIndex/localElemId/connGlobalNodes(:))
│   │   │                                  MeshGlobalNum      - 编号系统(nGlobalNodes/nGlobalElems/nTotalEq/nodeMap(:)/elemMap(:)/dof_sys)
│   │   │
│   │   │                                  【核心子程序】
│   │   │                                  GlobalNum_Build              → 从UF_Model构建全局编号(多实例支持)
│   │   │                                  GlobalNum_BuildFromFlat      → 从扁平数据构建编号(无Model依赖)
│   │   │                                  GlobalNum_GetDofIndices      → 获取单元DOF索引数组(用于装配)
│   │   │
│   │   │                                  【算法逻辑】
│   │   │                                  GlobalNum_BuildFromFlat:
│   │   │                                    1. 分配nodeMap(nNodes) + elemMap(nElems)
│   │   │                                    2. 节点映射：dofStartIndex = nDofPerNode*(i-1)+1
│   │   │                                    3. 单元映射：connGlobalNodes从connectivity提取
│   │   │                                    4. nTotalEq = nDofPerNode * nNodes
│   │
│   ├── MD_Mesh_Types.f90                → 类型定义 (~60行)
│   │   │                                  职责：四大类TYPE定义(合并版)
│   │   │                                  注：实际TYPE已分散到Data/Node/Elem/GlobalNum模块
│   │
│   ├── DOF/                             [DOF子域] (自由度管理)
│   │   │                                  设计意图：管理节点自由度标签/状态/方程编号
│   │   │                                  核心TYPE：MD_DOFDesc/MD_DOFSta/MD_DOFCtx/MD_NodalDOFDesc/MD_NodalDOFSta/MD_DOFMap
│   │   │
│   │   ├── MD_DOF_Core.f90              → DOF核心 (1928行)
│   │   │   │                              【常量定义】
│   │   │   │                              MD_MESH_MAX_DOF_PER_NOD = 16     → 每节点最大DOF数
│   │   │   │                              MD_MESH_DOF_INACTIVE/FREE/FIXED/PRESCRIBED/SLAVE/LAGRANGE → DOF状态枚举
│   │   │   │                              MD_MESH_DOF_LBL_U1~U6/T1/P1     → DOF标签(位移/温度/压力)
│   │   │   │
│   │   │   │                              【TYPE定义】
│   │   │   │                              MD_DOFDesc        - DOF描述(dofId/numNodes/numTotalDOF/numFreeDOF/numFixedDOF)
│   │   │   │                              MD_DOFSta         - DOF状态(dofId/currentEqn/bcStatus)
│   │   │   │                              MD_DOFCtx         - DOF上下文(dofCtxId/assemblyId)
│   │   │   │                              MD_NodalDOFDesc   - 节点DOF描述(nodeId/dofLabels(16))
│   │   │   │                              MD_NodalDOFSta    - 节点DOF状态(dofStatus(16)/values(16)/equationNumbers(16))
│   │   │   │                              MD_DOFMap         - DOF映射表(全局方程编号系统)
│   │   │   │                              UF_DOFLabelMapType- 标签映射(maxSlots/label_of_slot(:))
│   │   │   │
│   │   │   │                              【核心子程序】
│   │   │   │                              MD_DOFDesc_Init              → 初始化DOF描述(DataPlatform注册)
│   │   │   │                              MD_DOFDesc_Configure         → 配置DOF参数(nNodes/dofPerNode)
│   │   │   │                              UF_DOFLabelMap_Init          → 初始化标签映射表
│   │   │   │                              UF_DOFLabelMap_Register      → 注册DOF标签(用户标签→内部槽位)
│   │   │   │                              UF_DOFLabelMap_GetSlot       → 获取槽位索引(标签→slot)
│   │   │   │                              UF_DOFLabelMap_GetLabel      → 获取标签(slot→标签反向查询)
│   │   │
│   │   ├── MD_DOF_Mgr.f90               → DOF管理器 (14.4KB)
│   │   │   │                              【核心子程序】
│   │   │   │                              MD_DOF_System_Init           → DOF系统初始化
│   │   │   │                              MD_DOF_System_Finalize       → DOF系统释放
│   │   │   │                              MD_DOF_BuildGlobalMap        → 构建全局DOF映射表
│   │   │   │                              MD_DOF_ApplyBC               → 应用边界条件(修改dofStatus)
│   │   │   │                              MD_DOF_GetEquationNumber     → 获取方程编号(自由DOF计数)
│   │   │   │                              MD_DOF_GetFreeDOFCount       → 获取自由DOF总数
│   │   │
│   │   └── MD_DOF_API.f90               → DOF API (待创建)
│   │       │                              规划：只读查询接口封装
│   │
│   └── Node/                            [节点子域] (节点高级操作)
│       │                                  设计意图：节点创建/变换/统计/校验
│       │                                  核心TYPE：MD_Node_Type/MD_Node_State
│       │
│       └── MD_Node.f90                  → 节点操作 (713行)
│           │                              【TYPE定义】
│           │                              MD_Node_Type   - 节点类型(id/name/coords(3)/spatialDim/nDof/dofMap(16)/dofOffset
│           │                                               bc_applied(16)/bc_values(16)/load_values(16)
│           │                                               mass/temperature/pressure
│           │                                               nElems/element_list(:)/tags(:))
│           │                              MD_Node_State  - 节点状态(EXTENDS StateBase)
│           │
│           │                              【生命周期子程序】
│           │                              MD_Node_Create               → 创建节点(分配ID+初始化)
│           │                              MD_Node_Destroy              → 销毁节点(释放element_list/tags)
│           │
│           │                              【坐标操作子程序】
│           │                              MD_Node_SetCoords            → 设置节点坐标(coords(3))
│           │                              MD_Node_GetCoords            → 获取节点坐标(返回coords(3))
│           │                              MD_Node_Transform            → 坐标变换(局部→全局坐标系)
│           │                              MD_Node_GetDistance          → 计算节点间距离(返回标量)
│           │
│           │                              【DOF操作子程序】
│           │                              MD_Node_SetDOF               → 设置节点DOF(nDof/dofMap/bc_flags)
│           │                              MD_Node_GetDOF               → 获取节点DOF(返回dofMap/nDof)
│           │
│           │                              【查询校验子程序】
│           │                              MD_Node_GetStatistics        → 获取统计信息(nElems/nDOF/hasBC/hasLoad)
│           │                              MD_Node_Valid                → 校验节点有效性(coords合法/DOF范围/element_list非空)
│
├── Assembly/                             [装配]
│   │                                      设计意图：L3_MD层"根装配真相源"
│   │                                      核心职责：实例管理/节点集/单元集/表面定义/约束定义
│   │                                      对标ABAQUS：mdb.models[name].rootAssembly
│   │                                      四链贯通：理论(装配变换)→逻辑(L6解析→Add*填充→Validate→L5查询)→计算(O(1)查询)→数据(Desc冻结/无WriteBack)
│   │                                      关键特性：纯静态定义(无WriteBack)/part_ref跨域校验/约束主从面校验
│   │
│   ├── MD_Assem_Algo.f90                → 域容器总控（行数随演进；见源码）
│   │   │                                  【TYPE定义】
│   │   │                                  MD_Instance_Desc   - 实例描述(name/inst_id/part_ref/translation(3)/rotation(3,3)/dependent)
│   │   │                                  MD_SetDef          - 集合定义(name/set_id/members(:)/n_members/is_internal)
│   │   │                                  MD_SurfaceDef      - 表面定义(name/surf_id/elem_ids(:)/face_ids(:)/n_faces)
│   │   │                                  MD_ConstraintDef   - 约束定义(name/constraint_id/constraint_type/master_surface/slave_surface/tolerance/adjust)
│   │   │                                  AssemblyAlgo       - 算法参数(default_tie_tolerance/mpc_penalty_factor等6字段)
│   │   │                                  AssemblyState      - 运行时状态(active_constraints/max_constraint_error等7字段)
│   │   │                                  AssemblyCtx        - 上下文(current_inst_id/transform_cached/cached_translation等6字段)
│   │   │                                  9个Arg类型         - Phase 2参数容器
│   │   │
│   │   │                                  【域容器TYPE】
│   │   │                                  MD_Assembly_Domain - 统一域容器(10过程绑定)
│   │   │                                    ├─ instances(:)      → MD_Instance_Desc数组
│   │   │                                    ├─ node_sets(:)      → MD_SetDef数组
│   │   │                                    ├─ elem_sets(:)      → MD_SetDef数组
│   │   │                                    ├─ surfaces(:)       → MD_SurfaceDef数组
│   │   │                                    ├─ constraints(:)    → MD_ConstraintDef数组
│   │   │                                    ├─ constraint_union  → MD_ConstraintUnion(联合类型)
│   │   │                                    ├─ interaction_union → MD_InteractionUnion(联合类型)
│   │   │                                    └─ n_*/algo/state/ctx/initialized
│   │   │
│   │   │                                  【生命周期子程序】
│   │   │                                  MD_Assembly_Domain_Init          → 初始化域容器(ALLOCATE数组)
│   │   │                                  MD_Assembly_Domain_Finalize      → 释放资源(DEALLOCATE所有数组)
│   │   │
│   │   │                                  【Add*建模期子程序】(L6_AP解析调用)
│   │   │                                  MD_Assembly_Domain_AddInstance   → 添加实例(desc含part_ref/translation/rotation)
│   │   │                                  MD_Assembly_Domain_AddNodeSet    → 添加节点集(name/members(:))
│   │   │                                  MD_Assembly_Domain_AddElemSet    → 添加单元集(name/members(:))
│   │   │                                  MD_Assembly_Domain_AddSurface    → 添加表面(name/elem_ids/face_ids)
│   │   │                                  MD_Assembly_Domain_AddConstraint → 添加通用约束(constraint_type/master/slave)
│   │   │                                  MD_Assembly_Domain_AddTieConstraint    → 添加Tie约束(主从面绑定)
│   │   │                                  MD_Assembly_Domain_AddMPCConstraint    → 添加MPC约束(多点约束方程)
│   │   │                                  MD_Assembly_Domain_AddCouplingConstraint → 添加Coupling约束(耦合)
│   │   │                                  MD_Assembly_Domain_AddRigidConstraint  → 添加Rigid约束(刚体)
│   │   │                                  MD_Assembly_Domain_AddContactPair      → 添加接触对(Interaction)
│   │   │
│   │   │                                  【Get*只读查询子程序】(L5_RT调用)
│   │   │                                  MD_Assembly_Domain_GetInstance         → 按索引获取实例
│   │   │                                  MD_Assembly_Domain_GetNodeSet          → 按索引获取节点集
│   │   │                                  MD_Assembly_Domain_GetNodeSetByName    → 按名称获取节点集(O(n))
│   │   │                                  MD_Assembly_Domain_GetElemSet          → 按索引获取单元集
│   │   │                                  MD_Assembly_Domain_GetElemSetByName    → 按名称获取单元集(O(n))
│   │   │                                  MD_Assembly_Domain_GetSurface          → 按索引获取表面
│   │   │                                  MD_Assembly_Domain_GetSurfaceByName    → 按名称获取表面(O(n))
│   │   │                                  MD_Assembly_Domain_GetConstraint       → 按索引获取约束
│   │   │                                  MD_Assembly_Domain_GetConstraintByName → 按名称获取约束(O(n))
│   │   │                                  MD_Assembly_Domain_GetTieConstraint    → 获取Tie约束
│   │   │                                  MD_Assembly_Domain_GetMPCConstraint    → 获取MPC约束
│   │   │                                  MD_Assembly_Domain_GetCouplingConstraint→ 获取Coupling约束
│   │   │                                  MD_Assembly_Domain_GetRigidConstraint  → 获取Rigid约束
│   │   │                                  MD_Assembly_Domain_GetContactPair      → 获取接触对
│   │   │                                  MD_Assembly_Domain_GetSummary          → 获取域摘要信息
│   │   │
│   │   │                                  【独立索引API】(Phase 2，无容器调用)
│   │   │                                  MD_Assembly_GetInstance_Idx            → (inst_idx, arg, status) via g_ufc_global
│   │   │                                  MD_Assembly_GetNodeSet_Idx             → (set_idx, arg, status)
│   │   │                                  MD_Assembly_GetElemSet_Idx             → (set_idx, arg, status)
│   │   │                                  MD_Assembly_GetSurface_Idx             → (surf_idx, arg, status)
│   │   │                                  MD_Assembly_GetSurfaceByName_Idx       → (name, arg, status)
│   │   │                                  MD_Assembly_GetNodeSetByName_Idx       → (name, arg, status)
│   │   │                                  MD_Assembly_GetElemSetByName_Idx       → (name, arg, status)
│   │   │
│   │   │                                  【资源释放子程序】
│   │   │                                  MD_Assembly_Domain_ReleaseConstraintUnion  → 释放约束联合类型
│   │   │                                  MD_Assembly_Domain_ReleaseInteractionUnion → 释放交互联合类型
│   │
│   ├── MD_Assem_Domain.f90              → 域重导出 (1.4KB)
│   │   │                                  职责：向后兼容，RE-EXPORT MD_Assem_Algo所有符号
│   │   │                                  内容：USE MD_Assem_Algo + PUBLIC列表
│   │   │                                  状态：薄门面；规范源 MD_Assem_Algo
│   │
│   ├── MD_Assem_Legacy.f90              → Legacy UF + Sync（原 Lib+Sync）
│   │   │                                  【TYPE定义】
│   │   │                                  UF_AssemblyDef     - 装配定义(name/instances(:)/node_sets(:)/elem_sets(:)/surfaces(:)
│   │   │                                                     constraints(:)/total_nodes/total_elements/total_dofs
│   │   │                                                     global_coords(:,:)/global_conn(:,:)/global_elem_type(:))
│   │   │                                  UF_Constraint      - 约束定义(name/constraint_type/master_surface/slave_surface
│   │   │                                                     position_tolerance/mpc_nodes(:)/mpc_dofs(:)/mpc_coeffs(:))
│   │   │
│   │   │                                  【Arg类型】
│   │   │                                  MD_Assembly_AddInstance_Arg  → AddInstance参数容器
│   │   │                                  MD_Asm_GetInstance_Arg  → GetInstance参数容器
│   │   │                                  MD_Asm_GetSummary_Arg   → GetSummary参数容器
│   │   │
│   │   │                                  【常量定义】
│   │   │                                  MAX_ASSEMBLY_NAME = 80       → 最大装配名
│   │   │                                  MAX_INSTANCES = 10000        → 最大实例数
│   │   │                                  MAX_ASSEMBLY_SETS = 5000     → 最大集合数
│   │   │                                  CONSTRAINT_TIE/COUPLING/MPC/RIGID_BODY/EMBEDDED/TRANSFORM等9种约束枚举
│   │   │
│   │   │                                  【过程绑定】(UF_AssemblyDef%*)
│   │   │                                  assembly_init                → 初始化装配
│   │   │                                  assembly_add_instance        → 添加实例
│   │   │                                  assembly_add_node_set        → 添加节点集
│   │   │                                  assembly_add_elem_set        → 添加单元集
│   │   │                                  assembly_add_surface         → 添加表面
│   │   │                                  assembly_add_constraint      → 添加约束
│   │   │                                  assembly_find_instance       → 查找实例(按名)
│   │   │                                  assembly_get_instance        → 获取实例(按索引)
│   │   │                                  assembly_find_node_set       → 查找节点集(按名)
│   │   │                                  assembly_assemble            → 执行装配(构建全局编号)
│   │   │                                  assembly_append_instance_sets→ 追加实例集合到装配级
│   │   │                                  assembly_get_node_coords     → 获取全局节点坐标
│   │   │                                  assembly_release_global_arrays→ 释放全局数组
│   │   │                                  assembly_clear               → 清空装配
│   │   │                                  assembly_get_summary         → 获取摘要
│   │
│   ├── MD_Assembly_Sync.f90             → Legacy同步 (12.0KB)
│   │   │                                  【核心子程序】
│   │   │                                  MD_Assembly_SyncFromLegacy（`MODULE MD_Assem_Legacy`）→ 从Legacy同步到Domain
│   │   │
│   │   │                                  【同步逻辑】
│   │   │                                  1. UF_InstanceDef → MD_Instance_Desc(part_ref=part_id)
│   │   │                                  2. UF_NodeSet → MD_SetDef
│   │   │                                  3. UF_ElemSet → MD_SetDef
│   │   │                                  4. UF_Surface → MD_SurfaceDef
│   │   │                                  5. UF_Constraint → MD_ConstraintDef
│   │   │                                  6. 调用MD_Assembly_Domain_Init初始化
│   │   │                                  7. 填充instances(:)/node_sets(:)/elem_sets(:)/surfaces(:)/constraints(:)
│   │   │                                  8. 标记assembly%initialized = .TRUE.
│   │
│   ├── MD_Instance_Algo.f90             → 实例核心（行数见源码）
│   │   │                                  【TYPE定义】
│   │   │                                  UF_InstanceDef     - 实例定义(name/id/part_name/part_id
│   │   │                                                     translation(3)/rotation_matrix(3,3)
│   │   │                                                     rotation_axis(3)/rotation_angle/rotation_point(3)
│   │   │                                                     node_offset/elem_offset/dof_offset
│   │   │                                                     is_dependent/is_suppressed)
│   │   │
│   │   │                                  【常量定义】
│   │   │                                  MAX_INSTANCE_NAME = 80       → 最大实例名
│   │   │
│   │   │                                  【过程绑定】(UF_InstanceDef%*)
│   │   │                                  instance_init                → 初始化实例(name/part_name/rotation_matrix=I)
│   │   │                                  instance_bind_part           → 绑定Part(part_name→part_id)
│   │   │                                  instance_set_translation     → 设置平移(tx,ty,tz)
│   │   │                                  instance_set_rotation        → 设置旋转(Rodrigues公式,axis-angle→3x3矩阵)
│   │   │                                  instance_set_rotation_from_points→ 两点定义旋转轴
│   │   │                                  instance_transform_point     → 坐标变换(x_global = R·(x_local-p)+p+t)
│   │   │                                  instance_get_global_node_id  → 全局节点ID(local_id+node_offset)
│   │   │                                  instance_get_global_elem_id  → 全局单元ID(local_id+elem_offset)
│   │   │                                  instance_get_node_coords     → 获取全局坐标(TODO:需PartDef)
│   │   │                                  instance_get_local_node_index→ 反向查询(TODO:需PartDef)
│   │   │
│   │   │                                  【变换算法】
│   │   │                                  Rodrigues旋转公式:
│   │   │                                    R = cos(θ)I + sin(θ)[k]× + (1-cos(θ))k⊗k
│   │   │                                    x_global = R·(x_local - p) + p + t
│   │
│   ├── MD_Assem_Types.f90               → 类型定义 (已融合到MD_Assem_Algo)
│   │   │                                  状态：已删除，TYPE定义合并到MD_Assem_Algo
│   │
│   ├── Instance/                        [实例子域] (已融合)
│   │   │                                  状态：MD_Instance_Algo.f90已提升至Assembly根目录
│   │   │                                  注：原Instance/子目录已不存在
│   │
│   ├── CONTRACT.md                      → 契约文档
│   │   │                                  核心内容：
│   │   │                                  - 职责：实例/集合/表面/约束Desc管理
│   │   │                                  - 不负责：Part/Mesh/Section/Material(对应域负责)
│   │   │                                  - 无WriteBack(纯静态定义)
│   │   │                                  - 跨域校验：part_ref∈[1,part%n_parts]
│   │   │                                  - 约束校验：master_surface/slave_surface∈assembly%surfaces
│   │   │
│   └── DESIGN_Assembly_FourTypes.md     → 四型设计文档
│       │                                  核心内容：
│       │                                  - Desc: instance_id/instance_type/part_ids(:)/n_elements/n_nodes
│       │                                  - State: element_count/node_count/dof_count/is_assembled
│       │                                  - Algo: default_tie_tolerance/auto_adjust等
│       │                                  - Ctx: current_inst_id/transform_cached等
│
├── Boundary/                             [边界条件]
│   ├── MD_LoadBC_Core.f90               → 载荷BC核心
│   ├── MD_LoadBC_API.f90                → API接口
│   ├── MD_LoadBC_Types.f90              → 类型定义 (合并)
│   ├── MD_LoadBC_DomainTypes.f90        → 域类型
│   ├── MD_LoadBC_Idx.f90                → 索引
│   ├── MD_LoadBC_Sync.f90               → 同步
│   ├── CONTRACT.md                      → 契约
│   └── DESIGN_BC_FourTypes.md           → 四型设计
│
│   【设计意图】
│   管理有限元模型的边界条件(BC)、载荷(Load)和初始条件(IC)，
│   作为L3_MD层的物理边界定义中枢。核心职责：
│   1. Dirichlet/Neumann/Robin三类BC定义
│   2. 集中力/分布力/体力/压力/热载荷等9种载荷类型
│   3. 时间依赖幅值曲线A(t)与Step激活机制
│   4. DOF级别精确控制（U1-U6/T1/P1）
│   5. 多工况切换支持
│
│   【四链贯通说明】
│   - 理论链: BC u(t)=u₀·A(t) → MD_BC_Desc%value/amp_ref
│            Load F(t)=F₀·A(t) → MD_Load_Desc%magnitude/amp_ref
│            幅值插值A(t) → MD_Amp_Slot_Ctx
│   - 逻辑链: L6解析→AddBC/AddLoad→Step激活→冻结→L4/L5查询/施加
│   - 计算链: O(1)查询（GetBC/GetLoad/GetLoadsForStep）
│             幅值查询O(log n) → 二分查找AmplitudeDB
│             载荷施加O(n_dof) → 直接写入F向量
│   - 数据链: Desc(冻结) → State(回写currentValue/isActive)
│             → Algo(幅值缓存/区域缓存) → Ctx(瞬态F向量/时间)
│
│   【MD_LoadBC_Core.f90】(5684行，核心模块)
│   ├─ TYPE定义 (16个):
│   │  ├─ LoadDef              → 载荷定义(Desc)[id/name/loadType/targetType/magnitude/amplitudeId]
│   │  │   └─ 过程绑定: Init/Valid/Clear
│   │  ├─ BCDef                → BC定义(Desc)[id/name/bcType/targetType/value/amplitudeId]
│   │  │   └─ 过程绑定: Init/Valid/Clear
│   │  ├─ LoadDef_Init_In      → 载荷初始化输入(Desc)
│   │  ├─ LoadDef_Init_Out     → 载荷初始化输出(State)
│   │  ├─ BCDef_Init_In        → BC初始化输入(Desc)
│   │  ├─ BCDef_Init_Out       → BC初始化输出(State)
│   │  ├─ MD_LdbcDesc          → LoadBC描述(Desc)[EXTENDS(DescBase)]
│   │  │   └─ 过程绑定: RegLayout/Ensure/Init/Destroy/GetName
│   │  ├─ LoadBCTree           → LoadBC树(Desc)[EXTENDS(MD_LdbcDesc)]
│   │  │   └─ 过程绑定: GetID/GetName/GetType/GetParentID/GetByPath/GetFullPath
│   │  │                     InitTree/DestroyTree/RebuildIndex/ValidateTree
│   │  │                     Serialize/Deserialize/BeginBatch/EndBatch
│   │  ├─ MD_LdbcSta           → LoadBC状态(State)[EXTENDS(StateBase)]
│   │  │   └─ 过程绑定: RegLayout/Ensure/Init/Destroy
│   │  ├─ MD_LdbcCtx           → LoadBC上下文(Ctx)[EXTENDS(CtxBase)]
│   │  │   └─ 过程绑定: RegLayout/Ensure/Init
│   │  ├─ MD_LdbcAlgo          → LoadBC算法(Algo)[EXTENDS(AlgoBase)]
│   │  │   └─ 过程绑定: RegLayout/Ensure/Init
│   │  ├─ MD_LoadBC_Desc       → LoadBC域描述容器(Desc)
│   │  ├─ MD_LoadBC_State      → LoadBC域状态容器(State)
│   │  ├─ MD_LoadBC_Algo       → LoadBC域算法容器(Algo)
│   │  │   └─ 过程绑定: Init/Reset/Finalize/SyncFromStep/SyncFromTree
│   │  │                     GetActiveLoadsForStep/GetRegionNodes/GetAmplitudeFactor
│   │  │                     GetDofIndices/WriteBack
│   │  ├─ MD_LoadBC_Ctx        → LoadBC域上下文(Ctx)
│   │  ├─ MD_LoadBC_Runtime_Domain → LoadBC运行时域容器
│   │  ├─ MD_LoadBC_TableDesc  → 载荷表描述容器(Desc)
│   │  ├─ MD_LoadBC_TableSta   → 载荷表状态容器(State)
│   │  ├─ MD_LoadBC_TableAlgo  → 载荷表算法容器(Algo)
│   │  │   └─ 过程绑定: Init/Reset/Finalize/SyncFromStep
│   │  │                     GetActiveLoadsForStep/GetRegionNodes/GetAmplitudeFactor
│   │  │                     WriteBack/ApplyToForce
│   │  └─ MD_LoadBC_TableCtx   → 载荷表上下文(Ctx)
│   ├─ 常量定义:
│   │  ├─ Target Type (5): TARGET_NODE(1)/TARGET_NODESET(2)/TARGET_SURFACE(3)/
│   │  │                  TARGET_ELEMSET(4)/TARGET_EDGE(5)
│   │  ├─ Load Type (9): LOAD_CONCENTRAT(1)/LOAD_DISTRIBUTE(2)/LOAD_PRESSURE(3)/
│   │  │                LOAD_BODY_FORCE(4)/LOAD_GRAVITY(5)/LOAD_CENTRIFUGA(6)/
│   │  │                LOAD_CORIOLIS(7)/LOAD_THERMAL(8)/LOAD_EDGE_DISTR(9)
│   │  └─ BC Type (12): BC_DISPLACEMENT(1)/BC_VELOCITY(2)/BC_ACCELERATION(3)/
│   │                  BC_FIXED(4)/BC_SYMMETRY(5)/BC_NEUMANN(6)/BC_ROBIN(7)/
│   │                  BC_PERIODIC(8)/BC_CONTACT(9)/BC_ROTATION(10)/
│   │                  BC_TEMPERATURE(11)/BC_PRESSURE(12)
│   ├─ 核心子程序 (50+):
│   │  ├─ LoadDef_Init_Structured(in,out,status)       → 载荷结构化初始化
│   │  ├─ BCDef_Init_Structured(in,out,status)         → BC结构化初始化
│   │  ├─ MD_LoadBC_Table_Init(nLoads,nBCs,status)     → 载荷表初始化
│   │  ├─ MD_LoadBC_Table_Reset()                      → 载荷表重置
│   │  ├─ MD_LoadBC_Table_Finalize()                   → 载荷表释放
│   │  ├─ MD_LoadBC_Table_SyncFromStep(stepId,status)  → 从Step同步激活状态
│   │  ├─ ApplyLoad_FollowerForce(nodeId,magnitude,direction,F,status) → 从随力施加
│   │  ├─ ApplyLoad_PressureFollowing(surfId,pressure,F,status)        → 随压力施加
│   │  ├─ ApplyLoad_BodyForce(elemId,density,gravity,F,status)         → 体力施加
│   │  ├─ LoadBC_ApplyBC_Displacement_GetNodes(bcDef,nodes,dofs,status) → 获取位移BC节点
│   │  ├─ LoadBC_ApplyBC_Velocity(nodeId,velocity,F,status)            → 速度BC施加
│   │  ├─ LoadBC_ApplyBC_Acceleration(nodeId,acceleration,F,status)    → 加速度BC施加
│   │  ├─ LoadBC_DistributeLoad_ToNodes(loadId,magnitude,F,status)     → 节点载荷分配
│   │  ├─ LoadBC_DistributeLoad_ToElements(loadId,magnitude,F,status)  → 单元载荷分配
│   │  └─ LoadBC_DistributeLoad_ToSurface(loadId,pressure,F,status)    → 表面载荷分配
│   └─ 全局变量:
│      └─ g_md_loadbc_domain:MD_LoadBC_Runtime_Domain → LoadBC运行时全局域
│
│   【MD_LoadBC_API.f90】(927行，API接口)
│   ├─ UF_* API类型 (6个，供L6_AP层调用):
│   │  ├─ UF_BCDef          → BC API定义[name/bc_type/target_set/dof/value/amp_ref/step_ref]
│   │  ├─ UF_CLoadDef       → 集中力API定义[name/target_set/dof/magnitude/amp_ref]
│   │  ├─ UF_DLoadDef       → 分布力API定义[name/target_set/dof/magnitude/amp_ref]
│   │  ├─ UF_BodyForceDef   → 体力API定义[name/target_set/magnitude/amp_ref]
│   │  ├─ UF_ThermalLoadDef → 热载荷API定义[name/target_set/magnitude/amp_ref]
│   │  └─ UF_LoadBCManager  → LoadBC管理器API[loads(:)/bcs(:)/n_loads/n_bcs]
│   ├─ 常量定义:
│   │  ├─ BC Types (14): BC_DISPLACEMENT(1)/BC_VELOCITY(2)/BC_ACCELERATION(3)/
│   │  │                BC_TEMPERATURE(11)/BC_PORE_PRESSURE(12)/BC_ELECTRIC_POTENTIAL(21)/
│   │  │                BC_ENCASTRE(101)/BC_PINNED(102)/BC_XSYMM(103)/BC_YSYMM(104)/
│   │  │                BC_ZSYMM(105)/BC_XASYMM(106)/BC_YASYMM(107)/BC_ZASYMM(108)
│   │  └─ Load Types (10): LOAD_CLOAD(1)/LOAD_DLOAD(2)/LOAD_PRESSURE(3)/
│   │                     LOAD_BODY_FORCE(4)/LOAD_GRAVITY(5)/LOAD_CENTRIFUGAL(6)/
│   │                     LOAD_TEMPERATURE(7)/LOAD_TRACTION(20)/LOAD_CORIOLIS(21)/
│   │                     LOAD_CFLUX(22)/LOAD_DFLUX(23)/LOAD_SFILM(24)/LOAD_SRADIATE(25)
│   └─ 转换函数:
│      ├─ UF_BCDef_To_MD_BC_Desc(uf_bc,md_bc,status)           → UF→MD BC转换
│      ├─ UF_CLoadDef_To_MD_Load_Desc(uf_load,md_load,status)  → UF→MD 集中力转换
│      ├─ UF_DLoadDef_To_MD_Load_Desc(uf_load,md_load,status)  → UF→MD 分布力转换
│      └─ UF_BodyForceDef_To_MD_Load_Desc(uf_load,md_load,status) → UF→MD 体力转换
│
│   【MD_LoadBC_DomainTypes.f90】(551行，域类型)
│   ├─ TYPE定义 (10个):
│   │  ├─ LoadBCAlgo         → 载荷BC算法[default_amp_type/ramp_mode/auto_scale/scale_factor]
│   │  ├─ LoadBCCtx          → 载荷BC上下文[current_load_id/current_bc_id/current_ic_id]
│   │  ├─ MD_Load_Desc       → 载荷描述[name/load_id/load_type/target_set/dof/magnitude]
│   │  ├─ MD_Load_State      → 载荷状态[currentLoadScale/isActive/step_idx/incr_idx]
│   │  ├─ MD_BC_Desc         → BC描述[name/bc_id/bc_type/target_set/dof/value]
│   │  ├─ MD_BC_State        → BC状态[currentValue/isActive/step_idx/incr_idx]
│   │  ├─ MD_IC_Desc         → 初始条件描述[name/ic_id/ic_type/target_set/dof/value/values(6)]
│   │  ├─ MD_LoadBC_Domain   → LoadBC域容器[loads(:)/bcs(:)/initial_conds(:)/n_loads/n_bcs/n_ics]
│   │  │   └─ 过程绑定(14): Init/Finalize/AddLoad/AddBC/AddInitialCondition
│   │  │                    GetLoadsForStep/GetBCsForStep/GetLoad/GetBC/GetInitialCondition
│   │  │                    GetICsByType/GetLoadByName/GetBCByName/WriteBack/GetSummary
│   │  └─ Arg类型 (8个):
│   │     ├─ MD_LBC_GetSummary_Arg         → 获取摘要Arg
│   │     ├─ MD_LBC_GetLoadsForStep_Arg    → 获取Step载荷Arg
│   │     ├─ MD_LBC_GetBCsForStep_Arg      → 获取Step BC Arg
│   │     ├─ MD_LBC_GetBC_Arg              → 获取BC Arg
│   │     ├─ MD_LBC_GetLoad_Arg            → 获取载荷Arg
│   │     ├─ MD_LBC_GetLoadByName_Arg      → 按名获取载荷Arg
│   │     ├─ MD_LBC_GetBCByName_Arg        → 按名获取BC Arg
│   │     └─ MD_LBC_WriteBack_Arg             → WriteBack Arg
│   └─ 类型枚举:
│      ├─ LOAD Types (8): CLOAD(1)/DLOAD(2)/DSLOAD(3)/BODY_FORCE(4)/GRAVITY(5)/
│      │                 CENTRIFUGAL(6)/TEMPERATURE(7)/PRESSURE(8)
│      ├─ BC Types (8): DISPLACEMENT(1)/VELOCITY(2)/ACCELERATION(3)/SYMMETRY(4)/
│      │               ANTISYMMETRY(5)/ENCASTRE(6)/PINNED(7)/SYMMETRY_AXIS(8)
│      └─ IC Types (8): TEMPERATURE(1)/VELOCITY(2)/STRESS(3)/DISPLACEMENT(4)/
│                       FIELD(5)/PRESSURE(6)/SATURATION(7)/VOID_RATIO(8)
│
│   【MD_LoadBC_Idx.f90】(171行，独立索引API)
│   ├─ 设计模式: 指针绑定机制（打破循环依赖）
│   │  └─ ldbc_idx_dom:POINTER → MD_LoadBC_Domain
│   ├─ 生命周期:
│   │  ├─ MD_LoadBC_Idx_Bind(dom)         → 绑定域容器
│   │  └─ MD_LoadBC_Idx_Reset()           → 重置指针
│   └─ 索引查询 (6个，无容器调用):
│      ├─ MD_LoadBC_GetLoadsForStep_Idx(step_idx,arg,status) → 获取Step载荷索引
│      ├─ MD_LoadBC_GetBCsForStep_Idx(step_idx,arg,status)   → 获取Step BC索引
│      ├─ MD_LoadBC_GetBC_Idx(bc_idx,arg,status)             → 按索引获取BC
│      ├─ MD_LoadBC_GetLoad_Idx(load_idx,arg,status)         → 按索引获取载荷
│      ├─ MD_LoadBC_GetLoadByName_Idx(name,arg,status)       → 按名获取载荷索引
│      └─ MD_LoadBC_GetBCByName_Idx(name,arg,status)         → 按名获取BC索引
│
│   【MD_LoadBC_Sync.f90】(Legacy同步，待重构)
│   └─ 设计意图: 从Legacy UF_BCDef/UF_CLoadDef/UF_DLoadDef/UF_BodyForceDef
│               转换到MD_BC_Desc/MD_Load_Desc
│
│   【MD_BC_Types.f90】(6.0KB，BC类型定义)
│   ├─ MD_BC_Base_Desc   → BC基础描述(Desc)
│   ├─ MD_BC_Base_State  → BC基础状态(State)
│   ├─ MD_BC_Base_Algo   → BC基础算法(Algo)
│   ├─ MD_BC_Base_Ctx    → BC基础上下文(Ctx)
│   ├─ MD_BC_UPOT_Desc   → 电势BC描述
│   ├─ MD_BC_UTEMP_Desc  → 温度BC描述
│   ├─ MD_BC_UMASFL_Desc → 质量流BC描述
│   ├─ MD_BC_DISP_Desc   → 位移BC描述
│   └─ MD_BC_Disp_Desc   → 位移BC描述(别名)
│
│   【MD_Load_Types.f90】(10.9KB，载荷类型定义)
│   ├─ MD_Load_Base_Desc   → 载荷基础描述(Desc)
│   ├─ MD_Load_Base_State  → 载荷基础状态(State)
│   ├─ MD_Load_Base_Algo   → 载荷基础算法(Algo)
│   ├─ MD_Load_Base_Ctx    → 载荷基础上下文(Ctx)
│   ├─ MD_Load_DFLUX_Desc  → 热通量载荷描述
│   ├─ MD_Load_FILM_Desc   → 膜冷却载荷描述
│   ├─ MD_Load_HETVAL_Desc → 内热载荷描述
│   ├─ MD_Load_UWAVE_Desc  → 波浪载荷描述
│   ├─ MD_Load_DLOAD_Desc  → 分布载荷描述
│   ├─ MD_Load_Dist_Desc   → 分布载荷描述(别名)
│   ├─ MD_LoadBC_State     → LoadBC统一状态
│   ├─ MD_LoadBC_Algo      → LoadBC统一算法
│   └─ MD_LoadBC_Ctx       → LoadBC统一上下文
│
│   【WriteBack白名单】(L5→L3单向更新)
│   ✅ 允许:
│     - MD_LoadBC_WriteBack → state%currentValue(:)
│                           → state%currentTime(:)
│                           → state%isActive(:)
│                           → load_state%currentLoadScale
│                           → bc_state%currentValue
│   ❌ 禁止:
│     - desc%nLoadBCs/nLoads/nBCs/nICs
│     - desc%loadBCId(:)/name(:)/loadBCType(:)
│     - desc%region(:)/value(:)/direction(:,:)
│     - algo%idToIndexMap(:)
│
│   【幅值曲线依赖】
│   ├─ MD_Amp_Slot_Ctx     → 幅值数据库（外部依赖）
│   ├─ Amp_GetFactor(ampId,time) → 获取幅值因子A(t)
│   └─ 幅值类型: TABULAR/RAMP/SMOOTH_STEP/PERIODIC/EQUALLY_SPACED
│
│   【约束类型体系】
│   ├─ Dirichlet BC (5):
│   │  ├─ BC_DISPLACEMENT → 位移约束 u=u₀
│   │  ├─ BC_VELOCITY     → 速度约束 v=v₀
│   │  ├─ BC_ACCELERATION → 加速度约束 a=a₀
│   │  ├─ BC_TEMPERATURE  → 温度约束 T=T₀
│   │  └─ BC_PRESSURE     → 压力约束 p=p₀
│   ├─ Neumann BC (3):
│   │  ├─ BC_NEUMANN      → 自然边界条件(牵引力)
│   │  ├─ BC_ROBIN        → 混合边界条件(对流)
│   │  └─ BC_CONTACT      → 接触边界条件
│   ├─ 对称/反对称 (6):
│   │  ├─ BC_SYMMETRY     → 对称边界
│   │  ├─ BC_ENCASTRE     → 全约束
│   │  ├─ BC_PINNED       → 铰接约束
│   │  ├─ BC_XSYMM/YSYMM/ZSYMM → X/Y/Z对称
│   │  └─ BC_XASYMM/YASYMM/ZASYMM → X/Y/Z反对称
│   └─ 高级约束 (2):
│      ├─ BC_PERIODIC     → 周期性边界条件
│      └─ BC_ROTATION     → 旋转边界条件
│
│   【载荷类型体系】
│   ├─ 集中载荷 (2):
│   │  ├─ LOAD_CLOAD      → 集中力 F
│   │  └─ LOAD_CONCENTRAT → 集中载荷
│   ├─ 分布载荷 (4):
│   │  ├─ LOAD_DLOAD      → 分布力
│   │  ├─ LOAD_PRESSURE   → 压力 p
│   │  ├─ LOAD_DISTRIBUTE → 分布载荷
│   │  └─ LOAD_EDGE_DISTR → 边缘分布
│   ├─ 体积载荷 (4):
│   │  ├─ LOAD_BODY_FORCE → 体力 b
│   │  ├─ LOAD_GRAVITY    → 重力 g
│   │  ├─ LOAD_CENTRIFUGA → 离心力 ω²r
│   │  └─ LOAD_CORIOLIS   → 科里奥利力 2ω×v
│   ├─ 热载荷 (3):
│   │  ├─ LOAD_THERMAL    → 热载荷
│   │  ├─ LOAD_TEMPERATURE→ 温度载荷
│   │  └─ LOAD_DFLUX      → 热通量
│   └─ 特殊载荷 (3):
│      ├─ LOAD_SFILM      → 膜冷却
│      ├─ LOAD_SRADIATE   → 辐射
│      └─ LOAD_HETVAL     → 内热源
│
│   【跨域依赖矩阵】(9个调用方)
│   ├─ L4_PH/LoadBC/PH_Ldbc_Apply.f90          → BC/载荷施加
│   ├─ L5_RT/LoadBC/RT_Ldbc_Apply_Core.f90     → 运行时BC/载荷施加
│   ├─ L5_RT/Solver/RT_Solver_Assemble.f90     → 刚度矩阵组装(BC处理)
│   ├─ L6_AP/BC_API.f90                        → BC API调用
│   ├─ L6_AP/Load_API.f90                      → 载荷API调用
│   ├─ L3_MD/Mesh/MD_Mesh_Core.f90             → 节点/单元查询
│   ├─ L3_MD/Amplitude/MD_Amplitude_Core.f90   → 幅值曲线查询
│   ├─ L3_MD/Step/MD_Step_Core.f90             → Step激活查询
│   └─ L1_IF/Memory/IF_Mem_Mgr.f90             → 内存分配
│
├── Constraint/                           [约束]
│   ├── MD_Const_Core.f90                → 约束核心
│   ├── MD_Const_API.f90                 → 约束API (已删除-零调用)
│   ├── MD_Constraint_Types.f90         → 类型定义 (合并)
│   ├── MD_Constraint_PairDef.f90       → 配对定义
│   ├── MD_Constraint_PropDB.f90        → 属性数据库
│   ├── MD_Constraint_SurfBridge.f90    → 表面桥接
│   ├── MD_Constraint_Sync.f90          → 同步
│   └── CONTRACT.md                      → 契约
│
│   【设计意图】
│   定义有限元模型的约束类型（约束方程、绑定、耦合、刚体），作为L3_MD层的
│   约束定义中枢，**纯Desc层**（无WriteBack）。核心职责：
│   1. Tie约束: u_slave = u_master（表面绑定）
│   2. MPC约束: Σ(coeff_i × u_i) = 0（多点约束）
│   3. Coupling约束: u_ref = Σ(w_i × u_i)（运动/分布耦合）
│   4. Rigid Body约束: 刚体运动学
│   5. 接触对定义、嵌入单元、壳-固耦合、循环对称
│   6. L5罚函数组装表面名→节点ID解析
│
│   【四链贯通说明】
│   - 理论链: Tie(u_slave=u_master) / MPC(Σc_i·u_i=0) / Coupling(加权求和) / Rigid(u_slave=u_master+θ×r)
│   - 逻辑链: L6解析→AddConstraint(Tie/MPC/Coupling/Rigid)→冻结→L4注册→L5施加
│   - 计算链: O(1)查询（GetConstraint）/ 动态数组扩容（×2策略）
│             表面→节点解析: 最近邻或排序下标1:1
│   - 数据链: Desc(纯冻结) → State(无) → Algo(ConstraintAlgo) → Ctx(瞬态)
│   - 无WriteBack设计（L3 Constraint纯Desc）
│
│   【MD_Const_Core.f90】(735行，域容器核心)
│   ├─ 常量定义:
│   │  └─ MD_CONSTRAINT_MAX_CONSTRAINTS = 10000
│   ├─ TYPE定义 (6个):
│   │  ├─ ConstraintAlgo   → 算法参数(Algo)[default_enforcement/penalty/tolerance/max_aug_lag_iter]
│   │  ├─ ConstraintCtx    → 瞬态上下文(Ctx)[current_constraint_id/operation_type/validation_pending]
│   │  ├─ MD_Constraint_Domain → 域容器
│   │  │   └─ 过程绑定(12): Init/Finalize/AddTieConstraint/AddMPCConstraint
│   │  │                     AddCouplingConstraint/AddRigidConstraint
│   │  │                     GetTieConstraint/GetMPCConstraint/GetCouplingConstraint/GetRigidConstraint
│   │  │                     ValidateAllConstraints/SyncFromUnion/GetSummary
│   │  ├─ MD_Constraint_GetTieConstraint_Arg   → Tie查询Arg
│   │  ├─ MD_Constraint_GetMPCConstraint_Arg    → MPC查询Arg
│   │  ├─ MD_Constraint_GetCouplingConstraint_Arg → 耦合查询Arg
│   │  ├─ MD_Constraint_GetRigidConstraint_Arg → 刚体查询Arg
│   │  └─ MD_Constraint_GetSummary_Arg          → 摘要Arg
│   └─ 子程序 (12个TBP实现):
│      ├─ MD_Constraint_Domain_Init             → 初始化(设置algo默认值/n_*=0)
│      ├─ MD_Constraint_Domain_Finalize          → 释放(DEALLOCATE所有约束数组)
│      ├─ MD_Constraint_Domain_AddTieConstraint  → 添加Tie约束(×2动态扩容+MOVE_ALLOC)
│      └─ ...(其他Add/Get/Validate/Sync实现)
│
│   【MD_Constraint_Types.f90】(1220行，完整类型定义)
│   ├─ 约束类型常量 (4类):
│   │  ├─ CONSTRAINT_TIE(4) / CONSTRAINT_MPC(1) / CONSTRAINT_COUPLING(5) / CONSTRAINT_RIGID(7)
│   │  ├─ MPC_TYPE: BEAM(1)/LINK(2)/PIN(3)/RIGID(4)/GENERAL(5)/TIE(6)/SLIDER(7)
│   │  ├─ RBE_TYPE: RBE2(1) / RBE3(2)
│   │  └─ COUPLING_TYPE: KINEMATIC(1)/DISTRIBUTING(2)/STRUCTURAL(3)
│   ├─ DOF标志位 (6个):
│   │  └─ DOF_UX(1)/DOF_UY(2)/DOF_UZ(4)/DOF_RX(8)/DOF_RY(16)/DOF_RZ(32)/DOF_ALL(63)
│   ├─ 模板基类型 (4类):
│   │  ├─ MD_Constr_Base_Desc  → 约束基础描述(constr_id/constr_type/constr_name)
│   │  ├─ MD_Constr_Base_State → 约束基础状态(react_force/work_done/converged/iterations)
│   │  ├─ MD_Constr_Base_Algo  → 约束基础算法(method/penalty_stiff/use_linearize)
│   │  └─ MD_Constr_Base_Ctx   → 约束基础上下文(current_constraint_idx/iteration_count/current_error)
│   ├─ 约束类型定义 (4大类):
│   │  ├─ TieConstraintDef → Tie约束[slave_surface/master_surface/adjust/no_rotation/
│   │  │                       position_tolerance/slave_nodes(:)/master_nodes(:)/n_pairs]
│   │  │   └─ 过程绑定: Init/Valid/Cleanup
│   │  ├─ CplConstraintDef → 耦合约束[ref_node/ref_node_set/surface_name/coupling_type/
│   │  │                       constrain_dof(6)/coupled_nodes(:)/weights(:)/n_coupled]
│   │  │   └─ 过程绑定: Init/Valid/Cleanup/SetDOFs
│   │  ├─ MPCConstraintDef → MPC约束[mpc_type/mpc_type_name/node_ids(:)/dof_ids(:)/
│   │  │                      coefficients(:)/n_terms/equation_rhs]
│   │  │   └─ 过程绑定: Init/Valid/Cleanup/AddTerm
│   │  └─ RigidBodyDef → 刚体约束[rbe_kind/ref_node/element_set/tied_nodes(:)/n_tied/
│   │                       tied_weights(:)/pin_nset/tie_nset/isothermal]
│   │      └─ 过程绑定: Init/Valid/Cleanup
│   ├─ 统一存储容器:
│   │  └─ MD_ConstraintUnion → 合并存储[tie_constraints/mpc_constraints/cpl_constraints/
│   │                           rigid_constraints/n_tie/n_mpc/n_cpl/n_rigid/n_total/validated]
│   ├─ Legacy类型 (5个):
│   │  ├─ MD_Tie_Desc      → Tie描述(兼容)[tie_id/master_surface/slave_surface/position_tolerance]
│   │  ├─ MPC_Term         → MPC项[node_id/dof/coef]
│   │  ├─ MD_MPC_Desc      → MPC描述[mpc_id/mpc_type/terms(:)/rhs]
│   │  ├─ MD_RBE2_Desc     → RBE2描述[master_node/slave_nodes(:)/dof_components]
│   │  └─ MD_RBE3_Desc     → RBE3描述[master_node/master_dofs/slave_nodes(:)/weights(:)]
│   └─ 全局域类型 (3个):
│      ├─ MD_Constraint_State  → 域状态[active_constraints/max_constraint_error/total_constraint_energy]
│      ├─ MD_Constraint_Algo   → 域算法[tie_tolerance/mpc_tolerance/penalty_factor]
│      └─ MD_Constraint_Ctx    → 域上下文[current_constraint_idx/iteration_count/current_error]
│
│   【MD_Constraint_PairDef.f90】(591行，接触对定义)
│   ├─ 约束类型常量 (8个):
│   │  ├─ CONTACT(1)/EMBEDDED(2)/TRANSFORM(3)/CLEARANCE(4)/SHELL_SOLID(5)/
│   │  │  CYCLIC_SYM(6)/TIE(7)/COUPLING(8)
│   │  └─ CONTACT_FORMULATION: FINITE_SLIDING(1)/SMALL_SLIDING(2)/NODE_TO_SURF(3)
│   ├─ TYPE定义 (6个):
│   │  ├─ ContPairDef → 接触对[constraint_type/name/master_surface/slave_surface/
│   │  │                 interaction_property/Formul/adjust_initially/position_tolerance/
│   │  │                 tied/sliding_allowed/contact_tracking/smooth/props(10)]
│   │  ├─ EmbeddedElementDef → 嵌入单元[constraint_type/embedded_region/host_region/
│   │  │                        weight_tolerance/geometric_tolerance]
│   │  ├─ TransformDef → 坐标变换[constraint_type/node_set/csys_type]
│   │  ├─ ClearanceDef → 间隙定义[constraint_type/contact_pair_name/clearance_value]
│   │  ├─ ShellToSolidCouplingDef → 壳-固耦合[constraint_type/shell_surface/solid_surface]
│   │  └─ CyclicSymmetryDef → 循环对称[constraint_type/first_surface/second_surface/
│   │                          repetitive_sectors]
│   └─ 子程序 (3个):
│      ├─ UF_ContactPair_ComputeGap(slave_pts,master_pts,gap,status) → 计算间隙g=(x_s-x_m)·n
│      ├─ UF_ContactPair_CheckContact(gap,tolerance,is_in_contact,status) → 接触检查
│      └─ UF_ContactPair_GetStatistics(cpdef,stats,status) → 获取统计信息
│
│   【MD_Constraint_PropDB.f90】(185行，接触属性数据库)
│   ├─ TYPE定义 (2个):
│   │  ├─ UF_ContactPropertyDef → 属性定义[name/id/mu_s/mu_k/penalty_scale/
│   │  │                           penalty_n/penalty_t/adjust]
│   │  │   └─ mu_s: 静摩擦系数, mu_k: 动摩擦系数
│   │  │   └─ penalty_n: 法向罚刚度κ_n, penalty_t: 切向罚刚度κ_t
│   │  └─ UF_ContactPropertyDB → 属性数据库
│   │      └─ 过程绑定(6): init/add_property/find_by_name/find_by_id/get_property/clear
│   └─ 子程序实现:
│      ├─ cpdb_init(capacity) → 分配props(capacity)，默认16
│      ├─ cpdb_add_property(prop) → ×2动态扩容
│      ├─ cpdb_find_by_name(name) → 线性搜索，返回索引或-1
│      └─ cpdb_get_property(idx) → 返回属性指针
│
│   【MD_Constraint_SurfBridge.f90】(434行，表面名→节点ID桥接)
│   ├─ 设计模式: 表面名→节点列表解析（供L5罚函数组装使用）
│   ├─ 常量: MD_SURF_BRIDGE_MAX_NODES = 8192
│   ├─ 导出过程 (3个):
│   │  ├─ MD_TieConstraint_TryResolveSurfaces → Tie主从面→节点解析
│   │  ├─ MD_CplConstraint_TryResolveSurfaceOrElset → 耦合面/集→节点解析
│   │  └─ MD_RigidBody_TryResolveFromAssembly → 刚体从Assembly解析
│   └─ 内部子程序 (4个):
│      ├─ push_unique(list,n,nid,overflow) → 节点去重
│      ├─ sort_nodes(a,n) → 节点排序
│      ├─ MD_SurfaceDef_CollectNodes(elem_ids,n_faces,nodes,nn,status) → 表面→节点收集
│      └─ MD_ElemSet_CollectNodes(member_elems,n_mem,nodes,nn,status) → 单元集→节点收集
│
│   【MD_Constraint_Sync.f90】(67行，Legacy同步)
│   └─ 导出过程 (1个):
│      └─ MD_Constraint_SyncFromLegacy(md_layer,status)
│          → assembly%constraint_union → md_layer%constraint
│          → 调用SyncFromUnion后ReleaseConstraintUnion
│
│   【约束类型体系】
│   ├─ Tie约束 (4):
│   │  ├─ 理论: u_slave = u_master（表面绑定）
│   │  ├─ 参数: slave_surface/master_surface/adjust/no_rotation/position_tolerance
│   │  └─ 施加: 最近邻配对（mesh就绪）或排序下标1:1
│   ├─ MPC约束 (7种类型):
│   │  ├─ 理论: Σ(coeff_i × u_dof(i)) = equation_rhs
│   │  ├─ 类型: BEAM/LINK/PIN/RIGID/GENERAL/TIE/SLIDER
│   │  └─ 参数: node_ids(:)/dof_ids(:)/coefficients(:)/n_terms/equation_rhs
│   ├─ Coupling约束 (3种类型):
│   │  ├─ 理论: u_ref = Σ(w_i × u_i)（运动/分布/结构耦合）
│   │  ├─ KINEMATIC: 运动耦合（完全约束）
│   │  ├─ DISTRIBUTING: 分布耦合（加权平均）
│   │  └─ STRUCTURAL: 结构耦合
│   ├─ Rigid Body约束 (2种类型):
│   │  ├─ RBE2: 运动刚体（完全约束）
│   │  └─ RBE3: 分布刚体（加权插值）
│   ├─ 接触对 (8个子类型):
│   │  ├─ CONTACT: 表面-表面/节点-表面/有限滑移/小滑移
│   │  ├─ EMBEDDED: 嵌入单元
│   │  ├─ TRANSFORM: 坐标变换
│   │  ├─ CLEARANCE: 间隙定义
│   │  ├─ SHELL_SOLID: 壳-固耦合
│   │  └─ CYCLIC_SYM: 循环对称
│   └─ 接触属性:
│      ├─ 静摩擦系数μ_s / 动摩擦系数μ_k
│      ├─ 法向罚刚度κ_n / 切向罚刚度κ_t
│      └─ 初始间隙调整adjust
│
│   【WriteBack白名单】
│   ❌ 完全禁止WriteBack（L3 Constraint纯Desc）
│   └─ 所有字段冻结后只读，状态由L4/L5管理
│
│   【跨域依赖矩阵】(6个调用方)
│   ├─ L4_PH/PH_Constraint_*.f90              → 约束注册与Populate
│   ├─ L5_RT/RT_Asm_Solv.f90                  → 约束组装(RT_Asm_ApplyL3Constraints)
│   ├─ L5_RT/RT_Solv_Sparse_Core.f90          → CSR矩阵构建(RT_CSR_FromTripletMerged)
│   ├─ L6_AP/AP_Inp_Const.f90                 → 约束命令解析
│   ├─ L6_AP/MD_KW_Mapper.f90                → 关键字映射(Equation/Tie/Coupling)
│   └─ L3_MD/Mesh/MD_Mesh_*.f90              → 节点/单元查询
│
│   【L5组装设计要点】
│   ├─ 执行位置: RT_Asm_Complete中BC之后、Contact之前
│   ├─ MPC处理: 默认mpc_penalty_triplet_merge=.TRUE.
│   ├─ 非MPC处理: 默认l3_non_mpc_triplet_merge=.TRUE.（防止罚项落在原稀疏模式外）
│   ├─ 符号分析: triplet合并后需重新因子分解
│   └─ RBE3权重: tied_weights(:)可选，未给则调用PH_Constr_RBE3_CalcWeights
│
├── Interaction/                          [相互作用]
│   ├── MD_Interaction_Core.f90          → 相互作用核心
│   ├── MD_Interaction_API.f90           → 相互作用API (已删除-零调用)
│   ├── MD_Interaction_Types.f90         → 类型定义 (合并)
│   ├── MD_Interaction_Ctx.f90           → 上下文
│   ├── MD_Interaction_Mgr.f90           → 管理器
│   ├── MD_Interaction_ContactArgs.f90   → 接触参数
│   ├── MD_Interaction_Mapper.f90        → 映射器
│   ├── MD_Interaction_Parser.f90        → 解析器
│   ├── MD_Interaction_Sync.f90          → 同步
│   │
│   ├── Contact/                         [接触子域]
│   │   ├── MD_Cont_Core.f90             → 接触核心
│   │   └── MD_Cont_Types.f90            → 接触类型
│   │
│   ├── Connector/                       [连接器子域]
│   │   └── MD_Connector.f90             → 连接器
│   │
│   ├── HashTable/                       [哈希表子域]
│   │   └── MD_HashTable.f90             → 哈希表
│   │
│   └── Utility/                         [工具子域]
│       └── UT_MD_*.f90 (4 files)        → 工具
│   │
│   └── CONTRACT.md                      → 契约
│
│   【设计意图】
│   定义有限元模型的接触与相互作用行为，作为L3_MD层的接触定义中枢。
│   核心职责：
│   1. 接触对定义（主从面、罚参数、摩擦系数）
│   2. 表面相互作用（法向/切向行为）
│   3. 摩擦模型（库仑/粘性/罚函数/指数衰减）
│   4. 接触搜索算法（BucketGrid/BVH/暴力）
│   5. 约束施加方法（罚函数/拉格朗日乘数/增强拉格朗日）
│   6. 连接器定义（弹簧/铰链/阻尼器/Bushing）
│
│   【四链贯通说明】
│   - 理论链: KKT条件(g≥0,λ≥0,λ·g=0) / 罚函数F_n=κ·max(0,-g) / 库仑摩擦|τ|≤μ·σ_n
│   - 逻辑链: L6解析→AddPair→冻结→L4搜索检测→L5罚矩阵装配
│   - 计算链: 搜索O(n log n)/O(n²) / 间隙计算O(1) / 力装配O(n_contact)
│   - 数据链: Desc(冻结) → State(回写contact_pressure/contact_area)
│             → Algo(算法控制) → Ctx(pairId/interactionId/surfaceIds)
│
│   【MD_Interaction_Core.f90】(6020行，核心模块)
│   ├─ 常量定义 (30+):
│   │  ├─ Contact Type (4): NODE_TO(1)/SURFACE(2)/SELF_CO(3)/GENERAL(4)
│   │  ├─ Contact State (5): SEPARATE(10)/STICKING(20)/SLIDING(30)/INVALID(-1)/INITIAL(0)
│   │  ├─ Enforcement (4): PENALTY(1)/LAGRANG(2)/AUG_LAG(3)/DIRECT(4)
│   │  ├─ Friction Model (7): NONE(0)/COULOMB(1)/STICK(2)/VELOCITY(3)/PRESSURE(4)/EXPONENTIAL(5)/USER(99)
│   │  ├─ Sliding Type (2): SMALL(1)/FINITE(2)
│   │  ├─ Normal Behavior (4): HARD(1)/EXPONENT(2)/LINEAR(3)/TABULAR(4)
│   │  └─ Coordinate (4): AXISYMMET(0)/PLANE_STR(1)/PLANE_STRESS(2)/3D_GENERAL(3)
│   ├─ TYPE定义 (15个):
│   │  ├─ ContNode        → 接触节点状态(State)[global_id/state/coords(3)/gap/penetration/normal(3)/force_n/force_t(3)]
│   │  ├─ ContAlgoCtrl    → 算法控制(Algo)[algorithm_type/friction_model/penalty_stiffne/friction_coeffi/tolerance_gap]
│   │  ├─ ContForceRes    → 力结果(State)[normal_forces(:)/tangent_forces(:,:)/lagrange_multip(:)/nActiveCont]
│   │  ├─ ContAlgoDesc    → 算法描述(Desc)[name/method/frictionModel/searchAlgo/searchRadius/stabFactor]
│   │  ├─ UF_ContactAlgoDesc → 算法描述(别名)
│   │  ├─ ContContext     → 上下文(Ctx)[pairId/interactionId/slaveSurfId/masterSurfId/time/lambda]
│   │  ├─ ContSegment     → 接触线段[nodes(4)/normal(3)/tangent(3)/centroid(3)]
│   │  ├─ ContCandidate   → 候选接触[slave_node/master_segment/distance]
│   │  ├─ ContSurface     → 接触表面[nodes(:)/segments(:)/coords(:,:)/bbox(6)]
│   │  ├─ ContPair        → 接触对[master_surface/slave_surface/contact_nodes(:)/n_contacts]
│   │  ├─ ContPairDef     → 接触对定义(Desc)[master_surf/slave_surf/contact_type/enforcement_met/penalty_n/penalty_t]
│   │  ├─ FrictionParams  → 摩擦参数[mu_static/mu_kinetic/velocity_dependence/pressure_dependence]
│   │  ├─ BucketGrid      → 桶网格搜索[cell_size(:)/n_cells/cells(:)]
│   │  ├─ BVHTree         → 包围盒层次树[roots(:)/n_nodes/nodes(:)]
│   │  └─ MD_ContactPairDef → 接触对定义(兼容版)
│   ├─ 子程序 (100+，核心功能):
│   │  ├─ 几何计算:
│   │  │  ├─ md_cont_cross_product(a,b,cross) → 叉积计算
│   │  │  ├─ Cont_ComputeSegmentNormal(seg,normal) → 计算面法向量
│   │  │  ├─ Cont_ComputeGap(node,segment,gap,xi) → 计算间隙g=(x_s-x_m)·n
│   │  │  └─ Cont_ProjectNodeToSegment(node,seg,xi,gap) → 节点投影到面
│   │  ├─ 搜索算法:
│   │  │  ├─ Cont_BuildBucketGrid(surface,grid) → 构建桶网格
│   │  │  ├─ Cont_QueryBucketGrid(grid,node,candidates) → 查询桶网格
│   │  │  ├─ Cont_BuildBVHTree(surface,tree) → 构建BVH树
│   │  │  └─ Cont_QueryBVHTree(tree,node,candidates) → 查询BVH树
│   │  ├─ 接触检测:
│   │  │  ├─ Cont_DetectContact(pair,nodes,search_tol) → 接触检测
│   │  │  ├─ Cont_UpdateGeometry(surface,disp) → 更新表面坐标
│   │  │  └─ Cont_UpdateState(nodes,gap_tol) → 更新接触状态
│   │  ├─ 力计算:
│   │  │  ├─ Cont_ApplyPenaltyMethod(node,penalty_k,F,RHS) → 罚函数法
│   │  │  ├─ Cont_ApplyLagrangeMultiplier(node,lambda,F,RHS) → 拉格朗日乘数
│   │  │  ├─ Cont_ApplyAugmentedLagrangian(node,lambda,penalty_k) → 增强拉格朗日
│   │  │  └─ Cont_ApplyFriction(node,mu,F_t) → 库仑摩擦
│   │  ├─ 刚度装配:
│   │  │  ├─ Cont_AssembleStiffness(pair,K_CSR) → 装配接触刚度到CSR
│   │  │  └─ Cont_AssembleTripletMerge(pair,triplets) → triplet合并
│   │  └─ 工具:
│   │     ├─ Cont_GetContactStats(pair,total_f,max_pen,n_active) → 获取统计
│   │     └─ Cont_CleanupContact(pair) → 清理接触
│
│   【MD_Interaction_Types.f90】(335行，类型定义)
│   ├─ 类型枚举:
│   │  ├─ CONTACT_TYPE: S2S(1)/P2S(2)/E2E(3)/SELF(4)
│   │  ├─ FRICTION: COULOMB(1)/VISCOUS(2)/PENALTY(3)
│   │  └─ ALGORITHM: PENALTY(1)/LAGRANGE(2)/AUGMENTED_LAGRANGE(3)
│   ├─ 四型定义:
│   │  ├─ MD_Interaction_Desc   → 描述(Desc)[interaction_name/contact_type/slave_surface/master_surface/
│   │  │                          num_contact_pairs/contact_pairs(:)/surface_interactions(:)/friction_models(:)]
│   │  ├─ MD_Interaction_State  → 状态(State)[is_active/contact_status/contact_pressure/contact_area]
│   │  ├─ MD_Interaction_Algo   → 算法(Algo)[algorithm_type/penalty_stiffness/convergence_tolerance]
│   │  └─ MD_Interaction_Ctx    → 上下文(Ctx)[contact_ctx_id/work_arrays]
│   ├─ 辅助类型 (3个):
│   │  ├─ ContactPairType      → 接触对[pair_name/pair_id/slave_surface/master_surface/contact_type]
│   │  ├─ SurfaceInteractionType → 表面交互[interaction_name/normal_behavior/tangent_behavior]
│   │  └─ FrictionModelType    → 摩擦模型[friction_name/model_type/static_coeff/kinetic_coeff]
│   └─ 验证函数:
│      ├─ IsValidContactPair(pair) → 验证接触对
│      ├─ IsValidSurfaceInteraction(interaction) → 验证表面交互
│      └─ IsValidFrictionModel(model) → 验证摩擦模型
│
│   【MD_Interaction_Mgr.f90】(1043行，管理器)
│   ├─ 生命周期管理:
│   │  ├─ contact_Mgr_init(dim,n_surfaces,n_pairs,status) → 初始化接触管理器
│   │  └─ contact_Mgr_cleanup() → 清理
│   ├─ 表面/对操作:
│   │  ├─ contact_add_surface(surf_id,node_ids,coords,is_master,status) → 添加表面
│   │  └─ contact_add_pair(pair_id,master_surf,slave_surf,status) → 添加接触对
│   ├─ 映射与更新:
│   │  ├─ contact_setup_dof_mapping(dof_map,ndof) → 设置DOF映射
│   │  ├─ contact_update_geometry(disp) → 更新几何
│   │  └─ contact_global_search() → 全局搜索
│   ├─ 装配与计算:
│   │  ├─ contact_Assem_csr(row_ptr,col_idx,values,rhs) → 装配到CSR
│   │  ├─ contact_assemble_csr_with_damping(damping_ratio,velocity) → 装配+阻尼
│   │  └─ contact_update_state() → 更新状态
│   └─ 工具:
│      ├─ contact_get_Stats(total_f,max_pen,n_active) → 获取统计
│      ├─ contact_set_method(enforcement_met) → 设置方法
│      └─ contact_set_damping(damping_ratio) → 设置阻尼
│
│   【MD_Interaction_Ctx.f90】(3090行，上下文类型）
│   ├─ 模块集合 (8个):
│   │  ├─ MD_Interaction_ContClearance_Type → 间隙属性
│   │  ├─ MD_Interaction_ContactControls_Type → 控制属性
│   │  ├─ MD_Interaction_ContactOutput_Type → 输出属性
│   │  ├─ MD_Interaction_ContactStabilization_Type → 稳定化
│   │  ├─ MD_Interaction_ContactTracking_Type → 跟踪
│   │  ├─ MD_Interaction_ContactPrint_Type → 打印
│   │  ├─ MD_Interaction_ContactDamping_Type → 阻尼
│   │  └─ MD_Interaction_ContactExtrapolation_Type → 外推
│   └─ 每个模块包含: Init/Valid/Clear过程绑定
│
│   【MD_Interaction_Parser.f90】(427行，解析器)
│   ├─ 解析函数 (4个):
│   │  ├─ MD_Parse_ContactPair(lines,n_lines,desc,status) → 解析*CONTACT PAIR
│   │  ├─ MD_Parse_SurfaceInteraction(lines,n_lines,desc,status) → 解析*SURFACE INTERACTION
│   │  ├─ MD_Parse_Friction(lines,n_lines,model,status) → 解析*FRICTION
│   │  └─ MD_Parse_InteractionVariables(lines,n_lines,status) → 解析变量
│   └─ 工具函数 (2个):
│      ├─ Extract_Parameter_Value(line,param_name,value) → KEY=VALUE提取
│      └─ Convert_To_Upper(str) → 大写转换
│
│   【MD_Interaction_Mapper.f90】(348行，映射器)
│   ├─ 验证函数 (2个):
│   │  ├─ MD_Validate_ContactPair(pair,surfaces,n_surfaces) → 验证接触对
│   │  └─ MD_Validate_SurfaceInteraction(interaction,pairs,n_pairs) → 验证交互
│   ├─ 映射引擎 (2个):
│   │  ├─ MD_Map_InteractionToMesh(desc,status) → 映射到网格
│   │  └─ MD_Build_InteractionMapping(desc,status) → 构建映射
│   └─ 工具函数 (2个):
│      ├─ MD_Get_SurfaceNodeCount(surface_name) → 获取表面节点数
│      └─ MD_Get_SurfaceElementCount(surface_name) → 获取表面单元数
│
│   【MD_Connector.f90】(604行，连接器)
│   ├─ 连接器类型 (5个):
│   │  ├─ SpringProperties → 弹簧[name/dof/stiffness/damping/nonlinear]
│   │  ├─ JointProperties → 铰链[name/jointType/rotationStiffness/translationStiffness]
│   │  ├─ DashProperties → 阻尼器[name/dof/dampingCoefficient]
│   │  ├─ BushingProperties → Bushing[name/stiffness(6)/damping(6)]
│   │  └─ ConnectorProperties → 通用连接器[name/connectorType/sectionName/behaviorName]
│   └─ 每个类型包含: Init/Valid/Clear过程绑定
│
│   【MD_Interaction_Sync.f90】(157行，同步)
│   └─ MD_Interaction_SyncFromLegacy(model_def,md_layer,status) → Legacy→Domain同步
│      ├─ 1) Sync contact properties (model_def%contact_db%props)
│      ├─ 2) Sync pairs (assembly%interaction_union%contact_pairs)
│      └─ 3) Sync step pair_ids
│
│   【Utility子域】(4个工具文件)
│   ├─ UT_MD_HashTable.f90 (16.4KB) → 哈希表实现
│   ├─ UT_MD_Interaction_Integration.f90 (12.3KB) → 积分工具
│   ├─ UT_MD_Interaction_Mapper.f90 (15.5KB) → 映射工具
│   └─ UT_MD_Interaction_Parser.f90 (16.3KB) → 解析工具
│
│   【约束施加方法体系】
│   ├─ Penalty Method: F_n = κ·max(0,-g)
│   │  └─ 优点: 简单高效 / 缺点: 罚参数敏感
│   ├─ Lagrange Multiplier: F_n = λ, 增广系统
│   │  └─ 优点: 精确满足 / 缺点: 增加DOF
│   ├─ Augmented Lagrangian: L_ρ = Π + λ^T·g + ρ/2·||max(0,g+λ/ρ)||²
│   │  └─ 优点: 兼顾两者 / 缺点: 需迭代
│   └─ Direct Method: 直接消除自由度
│      └─ 优点: 精确 / 缺点: 破坏稀疏性
│
│   【摩擦模型体系】
│   ├─ Coulomb Friction: |τ| ≤ μ·σ_n
│   │  ├─ Static: μ_s (静摩擦)
│   │  └─ Kinetic: μ_k (动摩擦)
│   ├─ Velocity-Dependent: μ(v) = μ_k + (μ_s-μ_k)·exp(-v/v_c)
│   ├─ Pressure-Dependent: μ(p) = μ_0 + α·p
│   ├─ Exponential Decay: 指数衰减模型
│   └─ User-Defined: 用户自定义(VUMAT接口)
│
│   【接触搜索算法】
│   ├─ Bucket Grid: 空间网格划分，O(n)查询
│   ├─ BVH Tree: 包围盒层次树，O(n log n)构建
│   └─ Brute Force: 暴力搜索，O(n²)仅小模型
│
│   【WriteBack白名单】(L5→L3单向更新)
│   ✅ 允许:
│     - State%contact_pressure(:) → 接触压力
│     - State%contact_area(:) → 接触面积
│     - State%contact_status(:) → 接触/分离状态
│   ❌ 禁止:
│     - Desc%contact_pairs(:) → 接触对定义
│     - Desc%slave_surface/master_surface → 表面名
│     - Algo%penalty_stiffness → 罚刚度
│
│   【跨域依赖矩阵】(8个调用方)
│   ├─ L4_PH/Contact/PH_Contact_*.f90        → 接触评估
│   ├─ L5_RT/RT_Asm_Solv.f90                → 接触装配(RT_Asm_ApplyContact)
│   ├─ L5_RT/RT_Solv_Sparse_Core.f90        → CSR构建(RT_CSR_FromTripletMerged)
│   ├─ L6_AP/Input/Command/AP_Inp_Cont.f90  → 接触命令解析
│   ├─ L6_AP/MD_KW_Mapper.f90              → 关键字映射(CONTACT PAIR/FRICTION)
│   ├─ L3_MD/Mesh/MD_Mesh_*.f90            → 节点/单元查询
│   ├─ L3_MD/Assembly/MD_Assem_*.f90       → 表面解析
│   └─ L3_MD/Constraint/MD_Constraint_*.f90 → 约束属性数据库
│
│   【L5装配设计要点】
│   ├─ 执行位置: BC之后、L3约束之后
│   ├─ 装配策略: 默认contact_use_triplet_merge=.TRUE.
│   ├─ 搜索优化: 可选contact_try_ph_search（利用md_layer%assembly%global_coords）
│   ├─ 稠密回退: contact_triplet_merge_max_dof超限回退
│   └─ 符号分析: triplet合并后需重新因子分解(l3_csr_reanalyze_required)
│
├── KeyWord/                              [关键字]
│   ├── MD_KW_Core.f90                   → 关键字核心
│   ├── MD_KW_API.f90                    → 关键字API (已删除-零调用)
│   ├── MD_KW_Types.f90                  → 类型定义 (合并)
│   ├── MD_KW_Parser.f90                 → KW解析器
│   ├── MD_KW_Dispatch.f90               → KW分发
│   ├── MD_KW_Mapper.f90                 → KW映射器
│   ├── MD_KW_Registry.f90               → KW注册表
│   ├── MD_KW_Lexer.f90                  → KW词法分析
│   ├── MD_KW_Abaqus.f90                 → Abaqus关键字
│   ├── MD_KW_MemPool.f90                → KW内存池
│   ├── MD_KW_Validator.f90              → 验证器
│   │
│   ├── InputParser/                     [输入解析子域]
│   │   ├── MD_Inp_Parse.f90             → INP解析
│   │   └── MD_KeyWord_Parser_Recursive.f90 → 递归解析器
│   │
│   └── Bridge/                          [桥接子域]
│       └── MD_KW_AP_Brg.f90             → AP桥接
│   │
│   └── CONTRACT.md                      → 契约
│
│   【设计意图】
│   构建Abaqus INP文件的关键字解析系统，作为L3_MD层的INP输入解析中枢。
│   核心职责：
│   1. 词法分析（Lexer）：INP文件→Token流
│   2. 语法分析（Parser）：Token流→AST抽象语法树
│   3. 语义映射（Mapper）：AST→L3_MD域对象
│   4. 关键字注册（Registry）：300+关键字元数据管理
│   5. 覆盖率审计（Coverage）：P0/P1/P2优先级覆盖追踪
│   6. 递归解析（Recursive Parser）：嵌套关键字处理
│
│   【四链贯通说明】
│   - 理论链: INP格式规范(*KEYWORD/参数/数据行) → Lexer → Parser → AST → Mapper
│   - 逻辑链: 文件读取→词法分析→语法分析→AST构建→语义映射→域对象写入
│   - 计算链: Lexer O(n_lines) / Parser O(n_tokens) / Mapper O(n_nodes) / Registry O(1)哈希查找
│   - 数据链: 文件→Token流→AST节点→域容器(Desc/State/Algo/Ctx)
│
│   【MD_KW_Types.f90】(386行，类型定义)
│   ├─ 常量定义 (15+):
│   │  ├─ String Length: MAX_NAME_LEN(64)/MAX_VALUE_LEN(256)/MAX_LINE_LEN(8192)/MAX_PARAMS(32)
│   │  ├─ Token Types (9): EOF(0)/KEYWORD(1)/PARAM_NAME(2)/PARAM_VALUE(3)/DATA(4)/COMMENT(5)/
│   │  │                 COMMA(6)/EQUALS(7)/NEWLINE(8)/CONTINUATION(9)/INVALID(-1)
│   │  └─ Keyword Categories (13): MODEL(1)/PART(2)/MESH(3)/MATERIAL(4)/SECTION(5)/
│   │                             CONSTRAINT(6)/LOAD(7)/CONTACT(8)/STEP(9)/OUTPUT(10)/
│   │                             AMPLITUDE(11)/SPECIAL(12)/END(13)/OTHER(99)
│   ├─ TYPE定义 (6个):
│   │  ├─ KW_TokenType        → 词法单元[token_type/value/line_num/col_num/is_quoted]
│   │  ├─ KW_ParamDefType     → 参数定义[name/param_type/is_required/default_value/enum_values]
│   │  ├─ KW_ParamValueType   → 参数值[name/value/int_value/real_value/is_set]
│   │  ├─ KW_MetadataType     → 关键字元数据[keyword_name/category/keyword_level/params(:)/
│   │  │                        has_data_lines/min_data_lines/max_data_lines/requires_end]
│   │  ├─ KW_DataLineType     → 数据行[values(:)/n_cols/line_num]
│   │  └─ KW_ASTNodeType      → AST节点[node_id/keyword_name/parent_id/children_ids(:)/
│   │                            params(:)/data_lines(:)/line_num]
│   └─ 状态类型 (2个):
│      ├─ KW_LexerStateType   → 词法状态[file_unit/filename/line_buffer/current_line/at_eof]
│      └─ KW_ParserStateType  → 解析状态[lexer/nodes(:)/node_count/error_count/stop_on_error]
│
│   【MD_KW_Core.f90】(2434行，核心模块）
│   ├─ 覆盖率审计 (4个函数):
│   │  ├─ KW_Audit_P0_Must(covered_kws,report,status) → P0必须覆盖审计(24个关键字)
│   │  ├─ KW_Audit_P1_Important(covered_kws,report,status) → P1重要覆盖审计(12个关键字)
│   │  ├─ KW_Audit_P2_Optional(covered_kws,report,status) → P2可选覆盖审计
│   │  └─ KW_Generate_Report(report,status) → 生成覆盖率报告
│   ├─ TYPE定义 (2个):
│   │  ├─ KW_Coverage_Report → 覆盖率报告[n_p0_total/n_p0_covered/p0_coverage/p0_missing(:)]
│   │  └─ KW_Priority_Check → 优先级检查[keyword/priority/is_covered/notes]
│   └─ 优先级常量:
│      └─ PRIORITY_P0(0)/PRIORITY_P1(1)/PRIORITY_P2(2)
│
│   【MD_KW_Lexer.f90】(469行，词法分析）
│   ├─ 接口 (8个):
│   │  ├─ kw_lexer_init(state) → 初始化词法分析器
│   │  ├─ kw_lexer_open_file(state,filename,success) → 打开INP文件
│   │  ├─ kw_lexer_close(state) → 关闭文件
│   │  ├─ kw_lexer_next_token(state,token) → 获取下一个Token
│   │  ├─ kw_lexer_peek_token(state,token) → 预读Token（不消耗）
│   │  ├─ kw_lexer_push_back(state,token) → 回退Token
│   │  ├─ kw_lexer_get_line_num(state) → 获取当前行号
│   │  └─ kw_lexer_at_eof(state) → 检查文件结束
│   └─ 内部子程序 (3个):
│      ├─ read_next_line(state,success) → 读取下一行（处理续行）
│      ├─ tokenize_line(state,token) → 行级分词
│      └─ skip_whitespace(state) → 跳过空白
│
│   【MD_KW_Parser.f90】(721行，语法分析）
│   ├─ 接口 (7个):
│   │  ├─ kw_parser_init(state,max_nodes) → 初始化解析器
│   │  ├─ kw_parser_parse_file(state,filename,success) → 解析整个INP文件
│   │  ├─ kw_parser_get_ast(state,ast) → 获取AST
│   │  ├─ kw_parser_get_node(state,node_id,node) → 按ID获取节点
│   │  ├─ kw_parser_get_root_nodes(state,roots) → 获取根节点
│   │  ├─ kw_parser_get_errors(state,errors) → 获取错误列表
│   │  └─ kw_parser_find_nodes_by_keyword(state,kw_name,nodes) → 按关键字查找节点
│   └─ 内部子程序 (4个):
│      ├─ parse_keyword(state,keyword_token) → 解析关键字
│      ├─ parse_parameters(state,node) → 解析参数
│      ├─ parse_data_lines(state,node) → 解析数据行
│      └─ add_error(state,line_num,msg) → 添加错误
│
│   【MD_KW_Registry.f90】(2903行，关键字注册表）
│   ├─ TYPE定义 (1个):
│   │  └─ MD_KW_Registry_Type → 注册表[EXTENDS(BaseRegistry)]
│   │      └─ keywords(:)/hash_table(:)/max_keywords(512)/hash_table_size(1024)
│   ├─ 注册表接口 (10个):
│   │  ├─ Initialize(max_capacity,status) → 初始化注册表
│   │  ├─ Cleanup() → 清理
│   │  ├─ Register(metadata,status) → 注册关键字
│   │  ├─ Unregister(keyword_name,status) → 注销关键字
│   │  ├─ Lookup(keyword_name,metadata,status) → 查找关键字
│   │  ├─ Exists(keyword_name) → 检查是否存在
│   │  ├─ GetRegisteredCount() → 获取已注册数量
│   │  ├─ ListRegistered(keywords,n,status) → 列出所有关键字
│   │  ├─ kw_registry_add_param(keyword_name,param_def,status) → 添加参数定义
│   │  └─ kw_registry_set_data_spec(keyword_name,data_spec,status) → 设置数据行规范
│   ├─ 预注册函数 (10个):
│   │  ├─ register_model_keywords(registry) → 注册模型关键字(HEADING/PREPRINT等)
│   │  ├─ register_mesh_keywords(registry) → 注册网格关键字(NODE/ELEMENT/NSET/ELSET)
│   │  ├─ register_part_keywords(registry) → 注册Part关键字(PART/INSTANCE/END PART)
│   │  ├─ register_material_keywords(registry) → 注册材料关键字(MATERIAL/ELASTIC/PLASTIC等)
│   │  ├─ register_section_keywords(registry) → 注册截面关键字(SOLID SECTION/SHELL SECTION)
│   │  ├─ register_constraint_keywords(registry) → 注册约束关键字(BOUNDARY/TIE/MPC)
│   │  ├─ register_load_keywords(registry) → 注册载荷关键字(CLOAD/DLOAD/DSLOAD)
│   │  ├─ register_contact_keywords(registry) → 注册接触关键字(CONTACT PAIR/SURFACE INTERACTION)
│   │  ├─ register_step_keywords(registry) → 注册Step关键字(STEP/STATIC/DYNAMIC)
│   │  └─ register_output_keywords(registry) → 注册输出关键字(FIELD OUTPUT/HISTORY OUTPUT)
│   └─ 哈希函数:
│      └─ hash_string(str) → djb2算法哈希（大小写不敏感）
│
│   【MD_KW_Mapper.f90】(8962行，语义映射引擎）
│   ├─ 设计模式: AST节点→L3_MD域对象（300+映射函数）
│   ├─ 核心映射 (按域分类，300+函数):
│   │  ├─ 模型映射: map_node/map_element/map_nset/map_elset
│   │  ├─ 材料映射: map_material/map_elastic/map_plastic/map_density
│   │  ├─ 截面映射: map_solid_section/map_shell_section/map_beam_section
│   │  ├─ 约束映射: map_boundary/map_tie/map_mpc/map_coupling
│   │  ├─ 载荷映射: map_cload/map_dload/map_dsload/map_gravity
│   │  ├─ 接触映射: map_contact_pair/map_surface_interaction/map_friction
│   │  ├─ Step映射: map_step/map_static/map_dynamic/map_heat_transfer
│   │  ├─ 输出映射: map_field_output/map_history_output/map_node_output
│   │  └─ 特殊映射: map_amplitude/map_orientation/map_include
│   └─ 跨域依赖 (100+USE语句):
│      ├─ MD_Constraint_Types → MPC/Tie/Coupling/RigidBody
│      ├─ MD_Interaction_Contact* → ContactPair/ContactProperty/Friction
│      ├─ MD_LoadBC_Core/API → BC/Load类型常量
│      ├─ MD_Assem_Legacy → Assembly域
│      └─ MD_Elem_Core → 单元类型常量
│
│   【MD_KeyWord_Parser_Recursive.f90】(40.7KB，递归解析器）
│   └─ 设计意图: 处理嵌套关键字结构（如PART→ELEMENT→END PART→INSTANCE→END INSTANCE）
│      ├─ 递归下降解析：支持任意深度嵌套
│      ├─ 作用域管理：parent_id/children_ids层次追踪
│      └─ 错误恢复：单点失败不中断全局解析
│
│   【MD_KW_Dispatch.f90】(13.3KB，分发器）
│   └─ 设计意图: 根据关键字类型分发到对应Mapper函数
│      ├─ 关键字→函数指针映射表
│      └─ 动态分发（支持插件扩展）
│
│   【MD_KW_Abaqus.f90】(9.8KB，Abaqus关键字库）
│   └─ 设计意图: Abaqus 2020-2025版本关键字字典
│      └─ 300+关键字名称/类别/优先级定义
│
│   【MD_KW_MemPool.f90】(11.6KB，内存池）
│   └─ 设计意图: AST节点内存池管理（减少ALLOCATE/DEALLOCATE开销）
│      ├─ MemoryPoolManager → 内存池管理器
│      └─ 批量分配/释放策略
│
│   【MD_KW_Validator.f90】(7.7KB，验证器）
│   └─ 设计意图: INP文件语义验证
│      ├─ 关键字嵌套合法性检查
│      ├─ 参数类型/范围验证
│      └─ 跨域引用验证（如材料名存在性）
│
│   【MD_Inp_Parse.f90】(44.1KB，INP解析入口）
│   └─ 设计意图: INP文件解析主入口
│      ├─ 文件读取→Lexer→Parser→Mapper→域写入
│      └─ 错误汇总报告
│
│   【MD_KW_AP_Brg.f90】(3.1KB，AP桥接）
│   └─ 设计意图: L6_AP→L3_MD关键字解析桥接
│      ├─ Parse_*_Keyword → 解析L6传入的关键字
│      └─ *Properties → 属性结构体
│
│   【关键字分类体系】(13类)
│   ├─ MODEL (1): *HEADING, *PREPRINT
│   ├─ PART (2): *PART, *INSTANCE, *END PART, *END INSTANCE
│   ├─ MESH (4): *NODE, *ELEMENT, *NSET, *ELSET
│   ├─ MATERIAL (10+): *MATERIAL, *ELASTIC, *PLASTIC, *DENSITY等
│   ├─ SECTION (3): *SOLID SECTION, *SHELL SECTION, *BEAM SECTION
│   ├─ CONSTRAINT (5): *BOUNDARY, *TIE, *MPC, *COUPLING, *RIGID BODY
│   ├─ LOAD (5): *CLOAD, *DLOAD, *DSLOAD, *GRAVITY, *CENTRIFUGAL
│   ├─ CONTACT (2): *CONTACT PAIR, *SURFACE INTERACTION, *FRICTION
│   ├─ STEP (5): *STEP, *STATIC, *DYNAMIC, *HEAT TRANSFER, *END STEP
│   ├─ OUTPUT (3): *FIELD OUTPUT, *HISTORY OUTPUT, *NODE OUTPUT
│   ├─ AMPLITUDE (1): *AMPLITUDE
│   ├─ SPECIAL (2): *INCLUDE, *PARAMETER
│   └─ END (4): *END PART, *END INSTANCE, *END STEP, *END ASSEMBLY
│
│   【P0/P1/P2优先级体系】
│   ├─ P0 Must-Have (24个):
│   │  ├─ *NODE, *ELEMENT, *STEP, *STATIC
│   │  ├─ *BOUNDARY, *CLOAD, *DLOAD
│   │  ├─ *MATERIAL, *ELASTIC, *PLASTIC
│   │  ├─ *SURFACE, *CONTACT PAIR, *SURFACE INTERACT
│   │  ├─ *FIELD OUTPUT, *HISTORY OUTPUT
│   │  ├─ *SOLID SECTION, *SHELL SECTION
│   │  └─ *NSET, *ELSET, *PART, *END PART, *ASSEMBLY, *INSTANCE, *END INSTANCE
│   ├─ P1 Important (12个):
│   │  ├─ *COUPLING, *TIE, *MPC
│   │  ├─ *INITIAL CONDITIONS, *PREDEFINED FIELD, *AMPLITUDE
│   │  └─ *DYNAMIC, *HEAT TRANSFER, *BEAM SECTION, *RESTART, *ORIENTATION, *DENSITY
│   └─ P2 Optional (剩余):
│      └─ 高级功能/特殊用途关键字
│
│   【解析流程】
│   文件读取 → Lexer(词法分析) → Token流 → Parser(语法分析) → AST → 
│   Mapper(语义映射) → L3_MD域对象 → WriteBack → 覆盖率审计
│
│   【跨域依赖矩阵】(8个调用方)
│   ├─ L6_AP/MD_KW_Mapper.f90              → 语义映射引擎
│   ├─ L6_AP/Input/Command/AP_Inp_*.f90    → 各域命令解析
│   ├─ L3_MD/Mesh/MD_Mesh_*.f90            → 节点/单元写入
│   ├─ L3_MD/Material/MD_Mat_*.f90         → 材料参数写入
│   ├─ L3_MD/Constraint/MD_Const_*.f90     → 约束定义写入
│   ├─ L3_MD/Interaction/MD_Interaction_*.f90 → 接触定义写入
│   ├─ L3_MD/Boundary/MD_LoadBC_*.f90      → 载荷/BC写入
│   └─ L3_MD/Output/MD_Out_*.f90           → 输出请求写入
│
│   【覆盖率统计口径】
│   ├─ P0覆盖: 24/24 (100%) 必须实现
│   ├─ P1覆盖: 12/12 (100%) 重要实现
│   └─ P2覆盖: 根据项目需求可选实现
│
├── Field/                                [场变量]
│   ├── MD_Field_Types.f90               → 场类型 (合并)
│   └── DESIGN_Field_FourTypes.md        → 四大功能集设计
│   │
│   └── CONTRACT.md                      → 契约 (待创建)
│
│   【设计意图】
│   定义L3_MD层的Predefined Field Variables（预定义场变量），作为多物理场分析的初始条件中枢。
│   核心职责：
│   1. 温度场 (Temperature): 热分析初始条件T(x,y,z,t)
│   2. 孔压场 (Pore Pressure): 固结分析初始条件p(x,y,z)
│   3. 浓度场 (Concentration): 扩散分析初始条件c(x,y,z,t)
│   4. 位移/速度场 (Displacement/Velocity): 动力分析初始条件
│   5. 分布类型: 均匀/梯度/表格/解析函数
│   6. 跨域协作: L3_MD定义→L4_PH演化→L5_RT输出
│
│   【四链贯通说明】
│   - 理论链: 场变量定义(Desc)→场演化(State)→插值算法(Algo)→上下文(Ctx)
│   - 逻辑链: INP解析(*INITIAL CONDITIONS)→L3_MD定义→L4_PH计算→L5_RT输出
│   - 计算链: 温度场 O(n_nodes)/孔压场 O(n_nodes)/浓度场 O(n_nodes)/位移场 O(1)
│   - 数据链: L3_MD/Field_Desc(冷数据)→L4_PH/Field_State(热数据)→L5_RT/Field_Output
│
│   【MD_Field_Types.f90】(481行，类型定义）
│   ├─ 常量定义 (13+):
│   │  ├─ 场类型 (6): TEMPERATURE(1)/PORE_PRESSURE(2)/CONCENTRATION(3)/
│   │  │              DISPLACEMENT(4)/VELOCITY(5)/ACCELERATION(6)
│   │  ├─ 分布类型 (4): UNIFORM(1)/GRADIENT(2)/TABLE(3)/ANALYTICAL(4)
│   │  └─ 参考构型 (2): CURRENT(0)/INITIAL(1)
│   ├─ 四大基类TYPE (3个):
│   │  ├─ MD_Field_Base_Desc → 场描述基类[field_id/field_type/field_name/
│   │  │                       distribution_type/is_initialized]
│   │  ├─ MD_Field_Base_State → 场状态基类[values(:)/gradients(:,:)/
│   │  │                      is_defined/n_points]
│   │  └─ MD_Field_Base_Algo → 场算法基类[interpolation_method/use_gradient/extrapolation]
│   ├─ 扩展Desc TYPE (4个):
│   │  ├─ MD_Field_Temperature_Desc → 温度场
│   │  │  ├─ uniform_temp: 均匀温度(默认293.15K)
│   │  │  ├─ reference_temp/grad_x/grad_y/grad_z: 梯度场参数
│   │  │  ├─ table_coords(:,:)/table_values(:): 表格场数据
│   │  │  ├─ analytical_func: 解析函数名
│   │  │  ├─ is_time_dependent: 时间相关标记
│   │  │  └─ start_step/end_step: 激活步范围
│   │  ├─ MD_Field_PorePressure_Desc → 孔压场
│   │  │  ├─ uniform_pressure: 均匀孔压[Pa]
│   │  │  ├─ use_hydrostatic: 静水压力标记
│   │  │  ├─ fluid_density/gravity_magnitude/water_level: 静水参数
│   │  │  └─ table_coords(:,:)/table_values(:): 表格场数据
│   │  ├─ MD_Field_Concentration_Desc → 浓度场
│   │  │  ├─ uniform_conc: 均匀浓度[mol/m³]
│   │  │  ├─ reference_conc/grad_x/grad_y/grad_z: 梯度参数
│   │  │  └─ diffusivity: 扩散系数[m²/s]
│   │  └─ MD_Field_Displacement_Desc → 位移/速度/加速度场
│   │     ├─ init_disp_x/y/z: 初始位移[m]
│   │     ├─ init_velo_x/y/z: 初始速度[m/s]
│   │     ├─ init_accel_x/y/z: 初始加速度[m/s²]
│   │     ├─ omega_x/y/z: 角速度[rad/s]
│   │     └─ node_set: 节点集名称
│   ├─ 域管理TYPE (2个):
│   │  ├─ MD_FieldUnion → 统一场存储[temperature_fields(:)/porepressure_fields(:)/
│   │  │                 concentration_fields(:)/displacement_fields(:)]
│   │  └─ MD_Field_Domain → 域管理器[fields:MD_FieldUnion/initialized]
│   └─ 子程序明细 (11个):
│      ├─ Field_Temp_Validate(self,status) → 温度场验证
│      ├─ Field_Temp_Init(self,name,temp,status) → 温度场初始化
│      ├─ Field_PP_Validate(self,status) → 孔压场验证
│      ├─ Field_PP_Init(self,name,pressure,status) → 孔压场初始化
│      ├─ Field_Conc_Validate(self,status) → 浓度场验证
│      ├─ Field_Conc_Init(self,name,conc,status) → 浓度场初始化
│      ├─ Field_Disp_Validate(self,status) → 位移场验证
│      ├─ Field_Disp_Init(self,name,disp,status) → 位移场初始化
│      ├─ MD_Field_Domain_Init(self,est_fields,status) → 域初始化
│      ├─ MD_Field_Domain_AddField(self,field,status) → 添加场
│      └─ MD_Field_Domain_Finalize(self) → 域销毁
│
│   【DESIGN_Field_FourTypes.md】(160行，四大功能集设计文档）
│   ├─ Desc (冷数据，Write-Once):
│   │  ├─ 字段: field_id/field_type/initial_value/field_label
│   │  ├─ 生命周期: 模型建立时写入→计算全过程只读→模型销毁时释放
│   │  └─ 内存策略: 可ALLOCATABLE，不进入热路径
│   ├─ State (温数据，Step级更新):
│   │  ├─ 字段: values(:)/gradients(:,:)/previous_values(:)
│   │  ├─ 生命周期: 每次增量步更新→增量步内复用→增量步结束时释放
│   │  └─ 内存策略: Step级ALLOCATE，高频读写，进入热路径
│   ├─ Algo (冷数据，跨步复用):
│   │  ├─ 字段: interpolation_method/use_gradient/extrapolation
│   │  ├─ 插值方法: Linear(1)/Quadratic(2)/Lagrangian(3)/Hermite(4)
│   │  └─ 内存策略: 可ALLOCATABLE，跨步复用
│   └─ Ctx (热路径上下文，栈分配):
│      ├─ 字段: coord_system/time_current/integration_point
│      └─ 内存策略: 64-byte对齐，单次调用内使用
│
│   【场类型体系】(6种)
│   ├─ 温度场 (Temperature): 热分析/热-力耦合初始条件
│   ├─ 孔压场 (Pore Pressure): 固结分析/流-固耦合初始条件
│   ├─ 浓度场 (Concentration): 扩散分析/化学耦合初始条件
│   ├─ 位移场 (Displacement): 动力分析/初始应力状态
│   ├─ 速度场 (Velocity): 动力分析/冲击载荷
│   └─ 加速度场 (Acceleration): 动力分析/地震载荷
│
│   【分布类型体系】(4种)
│   ├─ UNIFORM: 均匀分布(全模型统一值)
│   ├─ GRADIENT: 梯度分布(T=T0+grad_x*x+grad_y*y+grad_z*z)
│   ├─ TABLE: 表格分布(坐标-值映射表)
│   └─ ANALYTICAL: 解析函数(用户自定义函数)
│
│   【跨层协作关系】
│   ├─ L3_MD/Field (Desc) → L4_PH/Field (State/Algo): 初始条件传递
│   ├─ L4_PH/Field (演化) → L5_RT/Output (FieldState): 场输出触发
│   └─ L6_AP/Command (AP_Inp_Predef.f90): *INITIAL CONDITIONS解析
│
│   【L4_PH层Field域已实现】
│   ├─ PH_Field_Def.f90: PH_Temperature_State/PH_PorePressure_State/
│   │                      PH_Concentration_State(状态TYPE)
│   ├─ PH_Field_Compute_Temperature_Explicit/Implicit: 温度场显式/隐式计算
│   ├─ PH_Field_Compute_PorePressure_Explicit/Implicit: 孔压场计算
│   └─ PH_Field_Compute_Concentration_Explicit/Implicit: 浓度场计算
│
│   【跨域依赖矩阵】(6个调用方)
│   ├─ L6_AP/Input/Command/AP_Inp_Predef.f90 → *INITIAL CONDITIONS解析
│   ├─ L4_PH/Field/PH_Field_Def.f90 → 场演化状态管理
│   ├─ L4_PH/Material/PH_Mat_MPH_PoreFlow.f90 → 渗流场耦合
│   ├─ L5_RT/Output/RT_Out_Types.f90 → FieldState输出触发
│   ├─ L3_MD/Mesh/MD_Mesh_*.f90 → 节点坐标引用
│   └─ L3_MD/Material/MD_Mat_*.f90 → 热物性参数引用
│
│   【WriteBack白名单机制】
│   ├─ L3_MD→L4_PH: field_id/field_type/distribution_type(只读)
│   ├─ L4_PH→L3_MD: values(:)/gradients(:,:)(步末回写)
│   └─ L5_RT→L3_MD: 不直接回写，通过Output域间接写入
│
├── Output/                               [输出]
│   ├── MD_Out_Core.f90                  → 输出核心
│   ├── MD_Out_Types.f90                 → 输出类型 (合并)
│   ├── MD_Out_Ctx_Core.f90              → 上下文核心
│   ├── MD_Out_Parse.f90                 → 输出解析器
│   ├── MD_Out_Mapper.f90                → 输出映射器 (已删除)
│   ├── MD_Out_Sync.f90                  → 输出同步
│   ├── MD_Out_Mgr.f90                   → 输出管理器
│   ├── MD_Out_Lib.f90                   → 输出库
│   ├── MD_Out_Var_Reg.f90               → 变量注册
│   ├── MD_Out_Field_Export.f90          → 场导出
│   ├── MD_Out_ReportPlot.f90            → 报告绘图
│   ├── MD_UniFld_Core.f90               → 统一场核心
│   ├── MD_UniFld_Ops.f90                → 统一场操作
│   │
│   ├── Bridge/                          [桥接子域]
│   │   └── MD_Out_DP_Brg.f90            → DP桥接
│   │
│   └── Utility/                         [工具子域]
│       ├── UT_MD_Output_Integration.f90 → 集成测试
│       ├── UT_MD_Output_Mapper.f90      → 映射器测试
│       └── UT_MD_Output_Parser.f90      → 解析器测试
│   │
│   └── CONTRACT.md                      → 契约
│
│   【设计意图】
│   定义L3_MD层的Output Request Schema（输出请求元数据），作为仿真结果输出的配置中枢。
│   核心职责：
│   1. 场输出定义 (Field Output): 空间分布场(应力/应变/位移/温度)
│   2. 历史输出定义 (History Output): 时间历程数据(u(t)/σ(t)/E(t))
│   3. 接触输出定义 (Contact Output): 接触力/穿透量/滑移状态
│   4. 能量输出定义 (Energy Output): 动能/内能/塑性耗散
│   5. 输出频率控制: 增量步/时间间隔/时间标记/模态
│   6. 统一场系统 (UniFld): 多物理场耦合框架(10种场类型)
│   7. 跨域协作: L3_MD定义→L5_RT执行→L6_AP写入(不执行I/O)
│
│   【四链贯通说明】
│   - 理论链: ABAQUS *OUTPUT语法→Desc定义→L5_RT读取→L5_RT WriteBack
│   - 逻辑链: INP解析(*FIELD OUTPUT/*HISTORY OUTPUT)→L3_MD注册→L5_RT GetRequestsForStep→L5_RT执行→WriteBack
│   - 计算链: 无实际计算(纯元数据容器)，I/O执行在L5_RT/L6_AP
│   - 数据链: MD_OutputRequest_Desc(Write-Once)→MD_Output_State(WriteBack)→L5_RT读取
│
│   【MD_Out_Core.f90】(569行，输出域核心容器）
│   ├─ 常量定义 (8个):
│   │  ├─ 请求类型 (4): OUT_FIELD(1)/OUT_HISTORY(2)/OUT_CONTACT(3)/OUT_ENERGY(4)
│   │  └─ 输出格式 (4): FMT_ODB(1)/FMT_VTK(2)/FMT_HDF5(3)/FMT_CSV(4)
│   ├─ TYPE定义 (5个):
│   │  ├─ OutputAlgo → 算法参数[default_format/compression_level/parallel_io]
│   │  ├─ MD_OutputRequest_Desc → Write-Once输出请求[name/request_id/request_type/
│   │  │   variables(32)/n_variables/target_set/frequency/time_interval/
│   │  │   format/step_ref]
│   │  ├─ MD_Output_State → WriteBack状态[lastWrittenInc/lastWrittenTime/
│   │  │   totalFrames/step_idx/incr_idx]
│   │  ├─ MD_Output_Domain → 域容器[requests(:)/n_requests/capacity/
│   │  │   output_state/algo/initialized]
│   │  └─ Arg类型 (3个): MD_Output_GetSummary_Arg/MD_Output_GetRequest_Arg/
│   │                    MD_Output_GetRequestByName_Arg
│   └─ 子程序明细 (9个):
│      ├─ MD_Output_Domain_Init(this,est_requests,status) → 域初始化
│      ├─ MD_Output_Domain_Finalize(this) → 域销毁
│      ├─ MD_Output_Domain_AddRequest(this,desc,status) → 添加输出请求
│      ├─ MD_Output_Domain_GetRequest(this,idx,desc,status) → 按索引获取
│      ├─ MD_Output_Domain_GetRequestsForStep(this,step_idx,requests,n,status) → 按步获取
│      ├─ MD_Output_Domain_IsOutputDue(this,curr_incr,curr_time,due) → 触发检查
│      ├─ MD_Output_Domain_GetRequestByName(this,name,arg) → 按名称获取
│      ├─ MD_Output_Domain_GetSummary(this,arg) → 获取摘要
│      └─ MD_Output_WriteBack(this,lastInc,lastTime,frames) → WriteBack(白名单)
│
│   【MD_Out_Types.f90】(517行，输出类型定义）
│   ├─ 常量定义 (16+):
│   │  ├─ 频率模式 (4): OUT_FREQ_EVERY_INCR(1)/OUT_FREQ_INTERVAL(2)/
│   │  │               OUT_FREQ_TIMEPOINTS(3)/OUT_FREQ_MODES(4)
│   │  └─ 变量类别 (9): OUT_VAR_DISPLACEMENT(1)/OUT_VAR_VELOCITY(2)/
│   │                 OUT_VAR_ACCELERATION(3)/OUT_VAR_STRESS(4)/OUT_VAR_STRAIN(5)/
│   │                 OUT_VAR_FORCE(6)/OUT_VAR_ENERGY(7)/OUT_VAR_TEMPERATURE(8)/OUT_VAR_CONTACT(9)
│   ├─ TYPE定义 (8个):
│   │  ├─ MD_OutFrequency_Type → 频率配置[freq_mode/interval/time_interval/
│   │  │   time_points(:)/nModes/last_incr_only]
│   │  ├─ MD_OutVariable_Type → 变量定义[name/category/description/
│   │  │   output_invariants/output_components/nComponents/component_names(:)]
│   │  ├─ MD_FieldOut_Type → 场输出[id/name/stepId/region/frequency/
│   │  │   variables(:)/file_path/format]
│   │  ├─ MD_HistOut_Type → 历史输出[id/name/stepId/hist_type/region/
│   │  │   frequency/variables(:)/file_path/format/append_mode]
│   │  ├─ MD_RestartOut_Type → 重启输出[enabled/stepId/frequency/
│   │  │   file_path/max_num_restart_files/overlay_mode]
│   │  └─ MD_OutCtrl_Type → 输出控制器[nFieldOuts/nHistOuts/
│   │      field_outs(:)/hist_outs(:)]
│   └─ 子程序明细 (6个):
│      ├─ MD_OutCtrl_Init(ctrl,max_field,max_hist,status) → 控制器初始化
│      ├─ MD_OutCtrl_Free(ctrl) → 控制器释放
│      ├─ MD_OutCtrl_AddFieldOut(ctrl,field_out,status) → 添加场输出
│      ├─ MD_OutCtrl_AddHistOut(ctrl,hist_out,status) → 添加历史输出
│      ├─ MD_OutCtrl_GetFieldOutsForStep(ctrl,step_id,field_outs,n,status) → 获取场输出
│      └─ MD_OutCtrl_GetHistOutsForStep(ctrl,step_id,hist_outs,n,status) → 获取历史输出
│
│   【MD_Out_Ctx_Core.f90】(1420行，输出上下文核心）
│   ├─ 常量定义 (37+):
│   │  ├─ 输出位置 (5): OUT_LOC_NODE(1)/OUT_LOC_ELEM_IN(2)/OUT_LOC_ELEM_CENTROID(3)/
│   │  │              OUT_LOC_ELEM_SURFACE(4)/OUT_LOC_GLOBAL(5)
│   │  ├─ 频率类型 (3): OUT_FREQ_INCREMENT(1)/OUT_FREQ_TIME_INTERVAL(2)/OUT_FREQ_TIME_MARKS(3)
│   │  ├─ 区域类型 (4): OUT_REGION_ALL(0)/OUT_REGION_NSET(1)/OUT_REGION_ELSET(2)/OUT_REGION_SURF(3)
│   │  ├─ 变量ID (20+): OUT_VAR_U(1)/OUT_VAR_V(2)/OUT_VAR_A(3)/OUT_VAR_RF(4)/
│   │  │              OUT_VAR_S(11)/OUT_VAR_E(12)/OUT_VAR_PE(13)/OUT_VAR_PEEQ(15)/
│   │  │              OUT_VAR_MISES(16)/OUT_VAR_TEMP(6)/OUT_VAR_POR(17)/OUT_VAR_HFL(18)/
│   │  │              OUT_VAR_ALLIE(21)/OUT_VAR_ALLKE(22)/OUT_VAR_ALLPD(23)/OUT_VAR_ALLSE(24)
│   │  ├─ 输出格式 (5): OUT_FMT_VTK(1)/OUT_FMT_HDF5(2)/OUT_FMT_CSV(3)/OUT_FMT_ODB(4)/OUT_FMT_TXT(5)
│   │  └─ 张量阶数 (3): OUT_RANK_SCALAR(0)/OUT_RANK_VECTOR(1)/OUT_RANK_TENSOR(2)
│   ├─ TYPE定义 (8个):
│   │  ├─ OutDesc → 输出描述符[EXTENDS(DescBase)]
│   │  ├─ OutSta → 输出状态[EXTENDS(StateBase)]
│   │  ├─ OutCtx → 输出上下文[EXTENDS(CtxBase)]
│   │  ├─ FldOutDesc → 场输出描述符[EXTENDS(DescBase)]
│   │  ├─ HistOutDesc → 历史输出描述符[EXTENDS(DescBase)]
│   │  ├─ OutVarDesc → 变量描述符[var_id/var_name/location/rank/n_components]
│   │  ├─ FldOutReq → 场输出请求[name/region_name/region_type/position/frequency/
│   │  │   variables(:)/step_id/is_active]
│   │  └─ HistOutReq → 历史输出请求[name/region_name/region_type/frequency/
│   │       variables(:)/step_id/is_active]
│   └─ 子程序明细 (20+个):
│      ├─ OutDesc_Init/Valid/RegLayout/Ensure → 描述符生命周期
│      ├─ OutSta_Init/RegLayout/Ensure → 状态生命周期
│      ├─ OutCtx_Init/RegLayout/Ensure → 上下文生命周期
│      ├─ FieldOutDesc_Init/Valid/RegLayout/Ensure → 场输出描述符
│      ├─ HistoryOutDesc_Init/Valid/RegLayout/Ensure → 历史输出描述符
│      ├─ FldOutReq_Init/AddVariable/ShouldOutput/Clear → 场输出请求
│      └─ HistOutReq_Init/AddVariable/ShouldOutput/Clear → 历史输出请求
│
│   【MD_UniFld_Core.f90】(5005行，统一场核心引擎）
│   ├─ 设计意图: 多物理场耦合框架，支持10种场类型统一建模
│   ├─ 场类型枚举 (10+):
│   │  ├─ MD_FIELD_DISPLACEMENT(1) → 位移场u∈ℝ^n_dof
│   │  ├─ MD_FIELD_TEMPERATURE(2) → 温度场T∈ℝ
│   │  ├─ MD_FIELD_PRESSURE(3) → 压力场p∈ℝ
│   │  ├─ MD_FIELD_ELECTRIC(4) → 电势场φ_e∈ℝ
│   │  ├─ MD_FIELD_MAGNETIC(5) → 磁场势φ_m∈ℝ
│   │  ├─ MD_FIELD_CHEMICAL(6) → 化学势μ∈ℝ
│   │  ├─ MD_FIELD_ROTATION(7) → 旋转场
│   │  ├─ MD_FIELD_QUANTUM(8) → 量子场
│   │  ├─ MD_FIELD_GRAVITATIONAL(9) → 引力场
│   │  └─ MD_FIELD_BIOLOGICAL(10) → 生物场
│   ├─ 系统类型 (3): MD_SYS_FIRST_ORDER(1)/MD_SYS_SECOND_ORDER(2)/MD_SYS_MIXED(3)
│   ├─ 耦合类型 (4): MD_CPL_NONE(0)/MD_CPL_ONE_WAY(1)/MD_CPL_TWO_WAY(2)/MD_CPL_FULL(3)
│   ├─ TYPE定义 (15+个):
│   │  ├─ MD_FieldType → 场类型枚举
│   │  ├─ MD_FieldState → 场状态[values(:)/velocities(:)/accelerations(:)/history(:,:,:)]
│   │  ├─ MD_FieldDesc → 场描述[field_id/field_type/n_dofs/order]
│   │  ├─ MD_FieldManager → 场管理器[fields(:)/n_fields/couplings(:,:)]
│   │  ├─ MD_FieldCoupling → 场耦合[src_field/tgt_field/coupling_type/coeff_matrix]
│   │  ├─ MD_StructFld/MD_ThermalFld/MD_FluidFld → 结构/热/流体场
│   │  └─ MD_FldEq/MD_UniFldSys/MD_UniFldMgr → 场方程/系统/管理器
│   ├─ 内核函数 (10+个):
│   │  ├─ ContIpKernel/DiffIpKernel → 连续/扩散积分点内核
│   │  ├─ ComputeKinematics/KineEval → 运动学计算
│   │  ├─ UF_ContTh_MakeCoeffsFromContext → 热力学系数
│   │  ├─ UF_ContPoro_MakeCoeffsFromContext → 孔隙力学系数
│   │  └─ UF_ContTHM_EvalMaterial → THM耦合材料评估
│   └─ 子程序明细 (30+个):
│      ├─ MD_CreateStructFld/MD_CreateThermalFld/MD_CreateFluidFld → 创建场
│      ├─ MD_CreateElectroMagFld/MD_CreateChemicalFld → 创建电磁/化学场
│      └─ StructMatRes/StructGetSectionDesc/StructIntegrateIp → 结构材料响应
│
│   【MD_Out_Parse.f90】(44.6KB，输出关键字解析）
│   └─ 设计意图: 解析Abaqus INP输出关键字(*OUTPUT/*FIELD OUTPUT/*HISTORY OUTPUT)
│      ├─ Parse_OUTPUT_Keyword → 解析*OUTPUT关键字
│      ├─ Parse_NODE_OUTPUT_Keyword → 解析*NODE OUTPUT
│      ├─ Parse_ELEMENT_OUTPUT_Keyword → 解析*ELEMENT OUTPUT
│      └─ Parse_HISTORY_OUTPUT_Keyword → 解析*HISTORY OUTPUT
│
│   【MD_Out_Var_Reg.f90】(284行，变量注册表）
│   ├─ TYPE: OutVarRegistry[vars(100)/num_vars/init]
│   ├─ 注册变量 (20+):
│   │  ├─ 结构变量: U/V/A/RF/CF(节点)/S/E/PE/EE/PEEQ/MISES(积分点)
│   │  ├─ 热学变量: TEMP(节点)/HFL(积分点)
│   │  ├─ 孔隙变量: POR(节点)/VFL(积分点)
│   │  ├─ 化学变量: CONC(节点)
│   │  └─ 能量变量: ALLIE/ALLKE/ALLPD/ALLSE(全局，仅历史输出)
│   └─ 子程序 (6个): OutVarReg_Init/GetVarDesc/GetVarName/IsValidVar/GetVarLocation/GetVarRank
│
│   【MD_Out_Lib.f90】(656行，输出库-遗留兼容）
│   ├─ TYPE定义 (8个):
│   │  ├─ UF_OutputVar → 输出变量描述符
│   │  ├─ UF_FieldOutputDef → 场输出定义(遗留)
│   │  ├─ UF_HistoryOutputDef → 历史输出定义(遗留)
│   │  ├─ UF_HistoryOutputState → 历史状态存储
│   │  └─ UF_OutputManager → 输出管理器
│   └─ 子程序 (8+个):
│      ├─ field_init/field_add_variable/field_set_frequency/field_should_output → 场输出
│      ├─ history_def_init/history_state_init/history_state_record_point → 历史输出
│      └─ outmgr_init/outmgr_add_field/outmgr_add_history → 管理器
│
│   【MD_Out_Field_Export.f90】(24.7KB，场导出）
│   └─ 设计意图: 场变量导出配置(不执行实际I/O)
│      ├─ 场导出请求定义
│      └─ 与L5_RT FieldState对接
│
│   【MD_Out_ReportPlot.f90】(29.6KB，报告绘图）
│   └─ 设计意图: 报告/绘图输出配置(KW层使用)
│      ├─ 报告生成配置
│      └─ 绘图参数定义
│
│   【MD_Out_Mgr.f90】(4.8KB，管理器外观）
│   └─ 设计意图: L6/L5使用的输出管理外观模式
│      └─ 封装MD_Output_Domain操作
│
│   【MD_Output_Sync.f90】(12.4KB，Legacy→Domain同步）
│   └─ 设计意图: 遗留类型(MD_FieldOut_Type/MD_HistOut_Type)到Domain类型同步
│      ├─ MD_OutputRequest_Desc_To_MD_FieldOut_Type
│      └─ MD_OutputRequest_Desc_To_MD_HistOut_Type
│
│   【MD_UniFld_Ops.f90】(45.9KB，统一场操作）
│   └─ 设计意图: L6使用的统一场操作接口
│      ├─ 场插值/外推
│      └─ 场耦合计算
│
│   【Utility子域】(3个测试文件)
│   ├─ UT_MD_Output_Integration.f90 (21.0KB) → 集成测试
│   ├─ UT_MD_Output_Mapper.f90 (16.3KB) → 映射器测试
│   └─ UT_MD_Output_Parser.f90 (15.6KB) → 解析器测试
│
│   【输出变量体系】(20+个Abaqus兼容变量)
│   ├─ 节点变量 (5): U(位移)/V(速度)/A(加速度)/RF(反力)/CF(集中力)
│   ├─ 积分点变量 (10): S(应力)/E(总应变)/PE(塑性应变)/EE(弹性应变)/
│   │                  PEEQ(等效塑性应变)/MISES(von Mises应力)/
│   │                  TEMP(温度)/HFL(热流)/POR(孔压)/VFL(渗流速度)
│   └─ 全局变量 (4): ALLIE(内能)/ALLKE(动能)/ALLPD(塑性耗散)/ALLSE(应变能)
│
│   【输出频率控制体系】(4种)
│   ├─ EVERY_INCR: 每N个增量步输出
│   ├─ INTERVAL: 时间间隔Δt输出
│   ├─ TIMEPOINTS: 指定时间点t_i输出
│   └─ MODES: 特征值分析模态输出
│
│   【输出格式体系】(5种)
│   ├─ ODB: Abaqus输出数据库
│   ├─ VTK: Visualization Toolkit(ParaView)
│   ├─ HDF5: 分层数据格式
│   ├─ CSV: 逗号分隔文本
│   └─ TXT: 纯文本
│
│   【WriteBack白名单机制】
│   ├─ L5_RT→L3_MD允许回写字段:
│   │  ├─ output_state%lastWrittenInc (最后输出增量步)
│   │  ├─ output_state%lastWrittenTime (最后输出时间)
│   │  └─ output_state%totalFrames (总输出帧数)
│   └─ L3_MD→L5_RT只读: requests(:)/n_requests/capacity
│
│   【跨域依赖矩阵】(8个调用方)
│   ├─ L6_AP/Input/Command/AP_Inp_*.f90 → *OUTPUT关键字解析
│   ├─ L5_RT/Output/RT_Out_*.f90 → 输出执行引擎
│   ├─ L5_RT/Field/RT_Field_*.f90 → 场数据读取
│   ├─ L4_PH/Element/PH_Elem_*.f90 → 单元输出变量
│   ├─ L3_MD/Step/MD_Step_*.f90 → Step引用
│   ├─ L3_MD/Mesh/MD_Mesh_*.f90 → 节点/单元集引用
│   ├─ L3_MD/Field/MD_Field_*.f90 → 场变量引用
│   └─ L3_MD/Interaction/MD_Interaction_*.f90 → 接触输出引用
│
│   【L5_RT层Output域已实现】
│   ├─ RT_Out_Types.f90: RT_Out_FieldState/RT_Out_HistState(输出状态TYPE)
│   ├─ RT_Out_FieldState_CheckTrigger: 输出触发检查
│   └─ RT_Out_Write: 实际I/O执行
│
├── Model/                                [模型]
│   ├── MD_Model_Core.f90                → 模型核心
│   ├── MD_Model_Domain_Core.f90         → 域核心
│   ├── MD_Model_Types.f90               → 模型类型 (合并)
│   ├── MD_Model_Lib.f90                 → 模型库
│   ├── MD_Model_Data_Core.f90           → 数据核心
│   ├── MD_Model_Tree.f90                → 模型树
│   ├── MD_Model_Access.f90              → 模型访问
│   ├── MD_Model_CoordSys_Core.f90       → 坐标系
│   ├── MD_ModelBuilder_Core.f90         → 模型构建器
│   │
│   └── Base/                            [基础子域]
│       ├── MD_Base_ObjModel_Core.f90    → 对象模型核心
│       ├── MD_Base_Types_Core.f90       → 基础类型
│       ├── MD_Base_TreeIndex_Core.f90   → 树索引
│       ├── MD_Base_MathUtils_Core.f90   → 数学工具
│       ├── MD_Base_IOSerial_Mgr.f90     → IO序列化
│       ├── MD_Base_DataMod_Mgr.f90      → 数据模块管理
│       ├── MD_Base_FieldVar_Mgr.f90     → 场变量管理
│       ├── MD_Base_ElemLib_Core.f90     → 单元库
│       └── MD_Base_Enums_Core.f90       → 枚举
│   │
│   └── UF_ModelTypes.f90                → 模型类型 (兼容层)
│   └── MD_Kinematics_Types.f90          → 运动学类型
│   └── MD_Types.f90                     → Ctx类型
│   │
│   └── CONTRACT.md                      → 契约
│
│   【设计意图】
│   作为L3_MD层的顶级模型容器和元数据中枢，Model域提供整个有限元模型的单真相源(Single Source of Truth)。
│   核心职责：
│   1. 模型级Desc定义：模型名称/维数/分析类型/子域计数
│   2. 模型树结构：层次化组织Part/Assembly/Material/Step等子域
│   3. 基础对象模型：四大TYPE基类(DescBase/StateBase/AlgoBase/CtxBase)
│   4. 数据域管理：Table/Parameter/FieldVariable/Distribution/Filter/PhysicalConstants
│   5. 坐标系系统：局部坐标系/全局坐标系/坐标变换
│   6. 模型构建器：从INP解析到模型组装的流水线
│   7. 跨域协作：向上对接L6_AP解析，向下支撑L4_PH/L5_RT求解
│
│   【四链贯通说明】
│   - 理论链: ABAQUS mdb.models['name']→MD_Model_Desc(纯描述性容器，无控制方程)
│   - 逻辑链: L6_AP解析→AddModel/Init→L5_RT GetModelInfo(只读)→L5_RT WriteBack(isBuilt标记)
│   - 计算链: ValidateModel(检查model_name/spatial_dim/analysis_type一致性)
│   - 数据链: g_ufc_global%md_layer%model→MD_Model_Desc(Write-Once)→ModelState(WriteBack白名单)
│
│   【MD_Model_Core.f90】(577行，模型域核心容器）
│   ├─ 常量定义 (6个):
│   │  └─ 分析类型: MD_MODEL_ANALYSIS_STATIC(1)/DYNAMIC_IMPLICIT(2)/DYNAMIC_EXPLICIT(3)/
│   │              EIGENVALUE(4)/HEAT_TRANSFER(5)/COUPLED_TEMP(6)
│   ├─ TYPE定义 (3个):
│   │  ├─ MD_Model_Desc → Write-Once模型元数据[model_name/spatial_dim/analysis_type/
│   │  │   n_parts/n_steps/n_materials/n_sections/n_loadbcs/n_amplitudes/n_interactions/n_outputs]
│   │  ├─ MD_Model_Domain → 域容器[desc/isBuilt/build_timestamp/initialized]
│   │  └─ MD_Model_Ctx → 统一上下文[EXTENDS(BaseCtx), sta/model/desc/state/globalState/ctx/algo/tws(:)]
│   └─ 子程序明细 (11个):
│      ├─ MD_Model_Domain_Init(this,status) → 域初始化
│      ├─ MD_Model_Domain_Finalize(this) → 域销毁
│      ├─ MD_Model_Domain_SetDesc(this,desc,status) → 设置描述符
│      ├─ MD_Model_Domain_GetInfo(this,desc,status) → 获取模型信息
│      ├─ MD_Model_Domain_GetRequestsForStep(this,step_idx,requests,n,status) → 按步获取
│      ├─ MD_Model_Domain_IsOutputDue(this,curr_incr,curr_time,due) → 触发检查
│      ├─ MD_Model_Domain_GetRequestByName(this,name,arg) → 按名称获取
│      ├─ MD_Model_Domain_GetSummary(this,arg) → 获取摘要
│      ├─ MD_Model_WriteBack(this,isBuilt,timestamp) → WriteBack(白名单)
│      ├─ MD_Model_ValidateModel(this,status) → 一致性验证
│      └─ MD_Model_Ctx方法 (11个): Init/Destroy/Reset/GetStatus/SetStatus/ClearStatus/IsOK/IsError/Bind/Valid/GetModel/GetDesc/GetState/GetGlobalState/GetAlgo
│
│   【MD_Model_Domain_Core.f90】(22.5KB，域核心）
│   └─ 与MD_Model_Core.f90合并，提供域级操作接口
│
│   【MD_Model_Types.f90】(722行，模型类型定义）
│   ├─ TYPE定义 (8个):
│   │  ├─ ModelDesc → 模型描述[EXTENDS(DescBase), id/name/description/dimensionality/
│   │  │   timePeriod/nParts/nAssemblies/nMaterials/nSections/nSteps/nNodes/nElements/
│   │  │   nDOFs/nLoads/nBCs/nInteractions/analysisType/meshType/ElemType/solverType]
│   │  ├─ ModelState → 模型状态[EXTENDS(StateBase), id/currentStep/currentInc/currentIter/
│   │  │   currentTime/timeStep/nStepsTotal/nStepsCompleted/nIncsTotal/nIncsConverged/
│   │  │   totalNewtonIter/maxNewtonIter/totalLinearIter/maxLinearIter/lastResNorm/
│   │  │   lastDispNorm/lastEnergyRatio/totalstrainener/totalkineticene/totalexternalwo/
│   │  │   totalplasticdis/totalDamageDiss/isInitialized/isRunning/isCompleted/isConverged]
│   │  ├─ GlobalState → 全局状态[EXTENDS(StateBase), nDOFs/nNodes/nElements/currentTime/
│   │  │   totalTime/totalstrainener/totalkineticene/totalexternalwo/id/incId/iterId/
│   │  │   linearIter/time_curr/dTime/residNorm/dispNorm/stepFactor/converged/nlConvergedFlag]
│   │  ├─ ModelAlgo → 模型算法[EXTENDS(AlgoBase), solverType/maxIter/tolerance/
│   │  │   useconsistentta/nlMethod(1=Newton/2=Modified/3=Quasi)/nlTolRes/nlTolDisp/nlTolEnergy]
│   │  ├─ ModelCtx → 模型上下文[EXTENDS(CtxBase), id]
│   │  ├─ AnalysisCtx → 分析上下文[EXTENDS(CtxBase), id]
│   │  ├─ JobDesc → 作业描述[EXTENDS(DescBase), id/name]
│   │  ├─ Model → 模型聚合[desc/state/assembly/parts(:)/interactions(:)]
│   │  └─ Job → 作业聚合[desc/state]
│   └─ 子程序明细 (20+个):
│      ├─ ModelDesc_Init/RegLayout/Ensure → 描述符生命周期
│      ├─ ModelState_Init/RegLayout/Ensure → 状态生命周期
│      ├─ GlobalState_Init/RegLayout/Ensure → 全局状态生命周期
│      ├─ ModelAlgo_Init/RegLayout/Ensure → 算法生命周期
│      ├─ ModelCtx_Init/RegLayout/Ensure → 上下文生命周期
│      ├─ AnalysisCtx_Init/RegLayout/Ensure → 分析上下文生命周期
│      └─ JobDesc_Init/RegLayout/Ensure → 作业描述生命周期
│
│   【MD_Model_Lib.f90】(3140行，模型库-遗留兼容）
│   ├─ TYPE定义 (10+个):
│   │  ├─ UF_ModelDef → 遗留模型定义
│   │  ├─ Desc_Model → API模型描述[model_id/name/description/dimension]
│   │  ├─ UF_ModelVarContext → 模型变量上下文
│   │  ├─ Context_Model_State → 模型状态上下文
│   │  ├─ Context_Model → 模型上下文
│   │  └─ Arg类型 (4个): MD_Model_Init_In/Out, MD_Model_AddPart_In/Out,
│   │                    MD_Model_AddMaterial_In/Out, MD_Model_ApplyBC_In/Out,
│   │                    MD_Model_ApplyLoads_In/Out
│   ├─ 常量定义 (10+):
│   │  ├─ Job状态: UF_JOB_STATUS_U(未启动)/S(成功)/N(不收敛)/E(输入错误)
│   │  ├─ Step类型: UF_StepType_Static/ImplicitDynamic/ExplicitDynamic/Modal
│   │  └─ 变量位置: UF_MV_LOC_Node/Eleme/Globa/Step/Incre/Conta
│   └─ 子程序明细 (20+个):
│      ├─ model_initialize/model_add_part/model_get_part → Part管理
│      ├─ model_add_material/model_get_material → 材料管理
│      ├─ model_add_section/model_get_section → 截面管理
│      ├─ model_add_amplitude/model_get_amplitude → 幅值管理
│      ├─ model_apply_boundary_conditions → 边界条件应用
│      ├─ model_apply_structural_loads → 结构载荷应用
│      ├─ model_prepare_analysis → 分析准备
│      ├─ MD_Model_Valid/Compare/GetStatistics/CheckConsistency → 验证工具
│      └─ MD_Theory_Unified_Query/Describe/GetNumModules/QueryByIndex/ExportList → 理论查询
│
│   【MD_Model_Data_Core.f90】(2596行，数据域核心）
│   ├─ 设计意图: 聚合21个MD_Model_Data_*子模块，管理Table/Parameter/FieldVariable/Distribution/Filter/PhysicalConstants
│   ├─ TYPE定义 (10+个):
│   │  ├─ TableEntry → 表格条目[independentVars(:)/dependentVar]
│   │  ├─ TableProperties → 表格属性[EXTENDS(DescBase), name/numIndependentVars/numEntries/entries(:)]
│   │  ├─ TablePropertiesManager → 表格管理器[numTables/tables(:)]
│   │  ├─ ParameterProperties → 参数属性
│   │  ├─ FieldVariableProperties → 场变量属性
│   │  ├─ DistributionProperties → 分布属性
│   │  ├─ FilterProperties → 过滤器属性
│   │  └─ PhysicalConstantsProperties → 物理常数属性
│   └─ 子程序明细 (50+个):
│      ├─ TableProperties_Init/Valid/Clear/AddEntry/Interpolate → 表格操作
│      ├─ TablePropertiesManager_Add/Find/Clear → 表格管理器
│      ├─ ParameterProperties_Init/Valid → 参数操作
│      ├─ FieldVariableProperties_Init/Valid → 场变量操作
│      ├─ DistributionProperties_Init/Valid → 分布操作
│      ├─ FilterProperties_Init/Valid → 过滤器操作
│      └─ PhysicalConstantsProperties_Init/Valid → 物理常数操作
│
│   【MD_Model_Tree.f90】(1639行，模型树结构）
│   ├─ 设计意图: 层次化组织模型子域，支持路径访问和树遍历
│   ├─ TYPE定义 (1个):
│   │  └─ ModelTree → 模型树[EXTENDS(ModelDesc,Serializable), node_id/parent_id/
│   │      is_active/is_visible/parts/assemblies/materials/sections/meshes/amplitudes/
│      loadbcs/interactions/steps/container_regis(:)/index_mgr/lazy_index_*/batch_mgr/
│      path_resolver/supports_nestin/max_nesting_dep/tree_initialize]
│   └─ 子程序明细 (10+个):
│      ├─ Build_NameIndex/Build_PathIndex/Build_TypeIndex → 索引构建
│      ├─ RebuildIndex → 重建索引
│      ├─ MD_ModelTree_DFS_Traverse → 深度优先遍历
│      ├─ MD_ModelTree_BFS_Traverse → 广度优先遍历
│      ├─ MD_ModelTree_QueryOptimize → 查询优化
│      ├─ MD_ModelTree_BuildIndex → 构建索引
│      ├─ MD_ModelTree_FindByPath → 按路径查找
│      └─ MD_ModelTree_FindByType → 按类型查找
│
│   【MD_Model_Access.f90】(8.5KB，模型访问API）
│   └─ 设计意图: L4使用的模型访问接口
│      └─ 封装MD_Model_Domain操作
│
│   【MD_Model_CoordSys_Core.f90】(98.0KB，坐标系系统）
│   ├─ 设计意图: 局部坐标系/全局坐标系/坐标变换管理
│   ├─ 坐标系类型: 直角坐标系/柱坐标系/球坐标系/用户自定义
│   └─ 子程序明细 (30+个): 坐标系创建/变换矩阵/点变换/向量变换
│
│   【MD_ModelBuilder_Core.f90】(12.6KB，模型构建器）
│   └─ 设计意图: 从INP解析到模型组装的流水线
│      ├─ 解析INP关键字→创建Part/Material/Step
│      └─ 组装ModelTree
│
│   【MD_Base_ObjModel_Core.f90】(4477行，基础对象模型核心）
│   ├─ 设计意图: 四大TYPE基类+序列化+容器+场系统+DOF系统
│   ├─ 四大基类TYPE (4个):
│   │  ├─ BaseDesc → 抽象描述基类[name/init/status]
│   │  ├─ BaseAlgo → 抽象算法基类[typeName/varName/category/init]
│   │  ├─ BaseCtx → 抽象上下文基类[status/init]
│   │  └─ BaseState → 抽象状态基类[init]
│   ├─ 扩展基类TYPE (4个):
│   │  ├─ DescBase → 描述扩展[EXTENDS(BaseDesc)]
│   │  ├─ AlgoBase → 算法扩展[EXTENDS(BaseAlgo)]
│   │  ├─ CtxBase → 上下文扩展[EXTENDS(BaseCtx)]
│   │  └─ StateBase → 状态扩展[EXTENDS(BaseState)]
│   ├─ 序列化TYPE (2个):
│   │  ├─ TreeSerializer → 树序列化器[format/indent_level/file_open]
│   │  └─ TreeDeserializer → 树反序列化器
│   ├─ 管理TYPE (3个):
│   │  ├─ BaseManager → 对象管理器
│   │  ├─ BaseRegistry → 类型注册表
│   │  └─ ObjContainer → 对象容器(哈希表)
│   ├─ 场系统TYPE (4个):
│   │  ├─ UF_FldDesc → 场描述符
│   │  ├─ UF_FldHdl → 场句柄
│   │  ├─ UF_FldSys → 场系统
│   │  └─ UF_UFField → 统一场
│   ├─ DOF系统TYPE (3个):
│   │  ├─ DofMap → DOF映射
│   │  ├─ DofLabMap → DOF标签映射
│   │  └─ DofSys → DOF系统
│   ├─ 模型系统TYPE (8个):
│   │  ├─ UF_Model/UF_Description/UF_Part/UF_Instance/UF_Assem → 模型层次
│   │  ├─ UF_Node/UF_Element → 网格实体
│   │  ├─ UF_NodeSet/UF_ElemSet/UF_SurfSet → 集合
│   │  └─ UF_ModelDesc/UF_NodeHdl/UF_ElemHdl/UF_SetHdl/UF_SurfHdl → 描述符/句柄
│   ├─ 材料TYPE (5个):
│   │  └─ MatCtx/MatCtxLegacy/MatStepCtx/MatProps/MatRes/MatResExt/IPState/EvalResult
│   └─ 子程序明细 (80+个):
│      ├─ 基类操作: BaseDesc/AlgoBase/CtxBase/StateBase的Init/Destroy/Serialize/Deserialize
│      ├─ 序列化: TreeSerializer_Init/Open/Write*/BeginObject/EndObject/Close/Destroy
│      ├─ 容器: ObjContainer_Add/Find/GetByID/GetByName/GetByIndex/Delete/Clear
│      ├─ 场系统: UF_FldSys_RegisterField/CreateField/GetField/UpdateField/DestroyField
│      ├─ DOF系统: DofSys_BuildDOF/MapDOF/GetDOFIndex
│      ├─ 集合: NodeSet_FromIds/Union/Intersect/Subtract/Is_Node_In_Set
│      └─ 工具: ToUpper/ToLower/SortInt/UniqueInt/HashString/String_Equals_CI/TrimAll
│
│   【MD_Base_Types_Core.f90】(22.9KB，基础类型）
│   └─ 基础类型定义(与MD_Base_ObjModel_Core互补)
│
│   【MD_Base_TreeIndex_Core.f90】(82.0KB，树索引核心）
│   ├─ 设计意图: 树结构索引管理，支持高效查询
│   ├─ TYPE: IndexMgr/LazyIndexMgr/BatchOpMgr/PathResolver/TreeNodeBase
│   └─ 子程序 (20+个): 索引构建/查询/优化/批量操作
│
│   【MD_Base_MathUtils_Core.f90】(91.8KB，数学工具）
│   └─ 数学工具函数库(矩阵运算/向量运算/数值计算)
│
│   【MD_Base_IOSerial_Mgr.f90】(93.3KB，IO序列化）
│   └─ IO序列化管理器(支持JSON/Binary/XML/HDF5格式)
│
│   【MD_Base_DataMod_Mgr.f90】(72.6KB，数据模块管理）
│   └─ 数据模块生命周期管理
│
│   【MD_Base_FieldVar_Mgr.f90】(41.2KB，场变量管理）
│   └─ 场变量注册/查询/更新管理
│
│   【MD_Base_ElemLib_Core.f90】(21.4KB，单元库）
│   └─ 单元库基础接口(UF_GetGaussPoints/UF_GetShapeFunctions/UF_ComputeJacobian)
│
│   【MD_Base_Enums_Core.f90】(18.4KB，枚举）
│   └─ 全局枚举定义(变量位置/Job状态/Step类型等)
│
│   【MD_Types.f90】(23.4KB，Ctx类型）
│   └─ 上下文类型定义
│
│   【MD_Kinematics_Types.f90】(3.7KB，运动学类型）
│   └─ 运动学类型定义(应变/变形梯度/B矩阵)
│
│   【UF_ModelTypes.f90】(1.4KB，兼容层）
│   └─ 遗留类型兼容层
│
│   【WriteBack白名单机制】
│   ├─ L5_RT→L3_MD允许回写字段:
│   │  ├─ isBuilt (模型构建完成标记)
│   │  └─ build_timestamp (构建时间戳)
│   └─ L3_MD→L5_RT只读: desc(model_name/spatial_dim/analysis_type/子域计数)
│
│   【跨域依赖矩阵】(10个调用方)
│   ├─ L6_AP/Input/Command/AP_Inp_*.f90 → *MODEL/*PART解析
│   ├─ L5_RT/Solver/RT_Solv_*.f90 → 模型信息读取
│   ├─ L5_RT/Assembly/RT_Assem_*.f90 → 装配体引用
│   ├─ L4_PH/Element/PH_Elem_*.f90 → 单元模型引用
│   ├─ L4_PH/Material/PH_Mat_*.f90 → 材料模型引用
│   ├─ L3_MD/Part/MD_Part_*.f90 → Part域
│   ├─ L3_MD/Mesh/MD_Mesh_*.f90 → Mesh域
│   ├─ L3_MD/Step/MD_Step_*.f90 → Step域
│   ├─ L3_MD/Assembly/MD_Assem_*.f90 → Assembly域
│   └─ L3_MD/Material/MD_Mat_*.f90 → Material域
│
│   【模型树层次结构】
│   ModelTree (根)
│   ├── Parts (ObjContainer)
│   ├── Assemblies (ObjContainer)
│   ├── Materials (ObjContainer)
│   ├── Sections (ObjContainer)
│   ├── Meshes (ObjContainer)
│   ├── Amplitudes (ObjContainer)
│   ├── LoadBCs (ObjContainer)
│   ├── Interactions (ObjContainer)
│   └── Steps (ObjContainer)
│
│   【四链贯通体系】
│   ├─ Desc (Write-Once): model_name/spatial_dim/analysis_type/子域计数
│   ├─ State (WriteBack): isBuilt/build_timestamp/currentStep/currentTime/收敛指标
│   ├─ Algo (跨步复用): solverType/maxIter/tolerance/nlMethod
│   └─ Ctx (热路径上下文): step/time/iter/conv_status
│
├── Part/                                 [部件] - L3_MD层部件/集合/几何元数据域
│   │
│   │   【设计意图】
│   │   Part域作为L3_MD层的“部件与集合元数据注册中心”，承担7个核心职责：
│   │   ① 部件描述管理(MD_Part_Desc)：部件ID、名称、空间维度、节点数、单元数等描述性元数据
│   │   ② 集合管理(MD_Sets_*)：节点集合、单元集合、表面集合的定义与查询
│   │   ③ 几何类型注册(MD_Geom_Types)：几何实体类型定义（为网格划分提供几何基础）
│   │   ④ 部件状态监控(MD_Part_State)：激活部件数、总节点数、总单元数、网格大小等
│   │   ⑤ 部件算法配置(MD_Part_Algo)：网格生成算法、默认网格尺寸、最大迭代次数等
│   │   ⑥ 部件上下文管理(MD_Part_Ctx)：当前处理部件索引、当前节点数、当前单元数等
│   │   ⑦ Legacy数据同步(MD_Part_Sync)：从Legacy_Part向MD_Part_Domain迁移同步
│   │
│   │   【功能范围】
│   │   • 部件操作：部件创建/查询/统计/同步
│   │   • 集合管理：集合创建/查询/成员管理/类型分类
│   │   • 几何类型：几何实体类型定义（点/线/面/体）
│   │   • 状态监控：部件激活状态、网格规模统计
│   │   • 网格算法：自动网格生成、网格尺寸控制
│   │   • 数据同步：Legacy数据迁移、域容器同步
│   │   • 跨域协作：为Mesh/Section/LoadBC/Constraint提供命名与分类基础
│   │   • 热路径：否（建模期操作，非求解热路径）
│   │
│   │   【核心f90文件】
│   │   ① MD_Part_Core.f90（91行）
│   │      - 2个子程序：MD_Part_GetPart_Idx, MD_Part_GetPartByName_Idx
│   │   ② MD_Part_Types.f90（253行）
│   │      - 4个TYPE：MD_Part_Desc/MD_Part_State/MD_Part_Algo/MD_Part_Ctx
│   │      - 1个域容器：MD_Part_Domain（6个绑定过程）
│   │      - 3个Arg：MD_Part_GetSummary_Arg/MD_Part_Get_Arg/MD_Part_GetByName_Arg
│   │      - 6个绑定过程：Init/Finalize/AddPart/GetPart/GetPartByName/GetSummary
│   │   ③ MD_Part_Sync.f90（177行）
│   │      - 1个子程序：MD_Part_Sync_FromLegacy
│   │   ④ MD_Sets_Core.f90（约350行）
│   │      - Sets核心操作（集合创建/查询/成员管理）
│   │   ⑤ MD_Sets_Ctx.f90（约1800行）
│   │      - Sets上下文管理（集合类型/查询接口/成员管理）
│   │   ⑥ MD_Geom_Types.f90（约130行）
│   │      - 几何类型定义（点/线/面/体几何实体）
│   │
│   │   【子程序详细清单】
│   │
│   │   **MD_Part_Core.f90** (91行)
│   │   ├─ MD_Part_GetPart_Idx(part_idx, arg, status)
│   │   │    功能：通过索引获取部件（使用g_ufc_global）
│   │   ├─ MD_Part_GetPartByName_Idx(name, arg, status)
│   │   │    功能：通过名称获取部件索引
│   │
│   │   **MD_Part_Types.f90** (253行)
│   │   ├─ TYPE MD_Part_Desc
│   │   │    字段：name/part_id/spatial_dim/mesh_ref/section_ref/n_nodes/n_elems
│   │   ├─ TYPE MD_Part_State
│   │   │    字段：active_parts/total_nodes/total_elems/total_mesh_size_mb/part_initialized
│   │   ├─ TYPE MD_Part_Algo
│   │   │    字段：auto_mesh_generation/mesh_algorithm/mesh_size_default/max_mesh_iterations
│   │   ├─ TYPE MD_Part_Ctx
│   │   │    字段：current_part_idx/current_node_count/current_elem_count
│   │   ├─ TYPE MD_Part_Domain
│   │   │    字段：parts(:)/n_parts/capacity/state/algo/ctx/initialized
│   │   │    ├─ Init(this, status)
│   │   │    ├─ Finalize(this)
│   │   │    ├─ AddPart(this, desc, status)
│   │   │    ├─ GetPart(this, part_idx, desc, status)
│   │   │    ├─ GetPartByName(this, part_name, desc, found, status)
│   │   │    └─ GetSummary(this, arg)
│   │   ├─ TYPE MD_Part_GetSummary_Arg
│   │   │    字段：summary/status
│   │   ├─ TYPE MD_Part_Get_Arg
│   │   │    字段：desc
│   │   └─ TYPE MD_Part_GetByName_Arg
│   │        字段：part_idx/found
│   │
│   │   **MD_Part_Sync.f90** (177行)
│   │   ├─ MD_Part_Sync_FromLegacy(dom, legacy_part, status)
│   │   │    功能：从Legacy_Part同步到MD_Part_Domain
│   │
│   │   **MD_Sets_Core.f90** (约350行)
│   │   ├─ Sets核心操作
│   │   │    - 集合创建/查询/成员管理
│   │   │    - 节点集合/单元集合/表面集合
│   │
│   │   **MD_Sets_Ctx.f90** (约1800行)
│   │   ├─ Sets上下文管理
│   │   │    - 集合类型定义
│   │   │    - 查询接口
│   │   │    - 成员管理
│   │   │    - 集合操作算法
│   │
│   │   **MD_Geom_Types.f90** (约130行)
│   │   ├─ 几何类型定义
│   │   │    - 点/线/面/体几何实体
│   │   │    - 为网格划分提供几何基础
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory)：部件定义→集合定义→几何定义→网格划分
│   │   • 逻辑链(Logic)：Part域容器→Set域操作→Geom类型注册→Mesh域引用
│   │   • 计算链(Computation)：部件统计→集合查询→几何处理→网格生成
│   │   • 数据链(Data)：MD_Part_Desc/MD_Part_State/MD_Part_Algo/MD_Part_Ctx四型贯通
│   │
│   │   【WriteBack白名单机制】
│   │   • 仅更新：state%active_parts/state%total_nodes/state%total_elems
│   │   • 禁止写入：desc(只读)/algo配置(建模期设置)
│   │   • 线程安全：无（L3_MD层无并发需求）
│   │
│   │   【跨域依赖矩阵】
│   │   • Mesh域：引用Part的mesh_ref，获取部件级网格划分
│   │   • Section域：引用Part的section_ref，获取部件截面分配
│   │   • LoadBC域：通过Set集合施加载荷和边界条件
│   │   • Constraint域：通过Set集合定义约束
│   │   • Contact域：通过Set集合定义接触面
│   │   • Model域：聚合Part域容器
│   │
│   │   【调用方统计】
│   │   • 主要调用方：Mesh/Section/LoadBC/Constraint/Contact/Model（6个域）
│   │   • 热路径调用：否（建模期操作）
│   │
│   │   【已删除模块】
│   │   • ~~MD_Inst_Mgr.f90~~ (58KB)：零调用的Instance Manager
│   │   • ~~MD_Sets_Mgr.f90~~ (53KB)：零调用的Sets Manager
│   │   • ~~MD_Part_Mgr.f90~~ (37KB)：零调用的Part Manager
│   │   • ~~MD_Sets_API.f90~~ (5KB)：零调用的API封装层
│   │   • ~~MD_Part_API.f90~~ (3KB)：零调用的API封装层
│   │
│   │   【覆盖率统计】
│   │   • 核心文件：6个（Core/Types/Sync/Sets_Core/Sets_Ctx/Geom_Types）
│   │   • TYPE定义：11个（4个Part+1个Domain+3个Arg+3个Sets/Geom）
│   │   • 子程序总数：约15个
│   │   • 合同对齐：Part/CONTRACT.md已验证
│   │
│   ├── MD_Part_Core.f90                 → 部件核心(91行, 2个子程序)
│   ├── MD_Part_Types.f90                → 部件类型(253行, 4个TYPE, 6个绑定过程)
│   ├── MD_Part_Sync.f90                 → Legacy同步(177行, 1个子程序)
│   ├── MD_Sets_Core.f90                 → 集合核心(约350行)
│   ├── MD_Sets_Ctx.f90                  → 集合上下文(约1800行)
│   └── MD_Geom_Types.f90                → 几何类型(约130行)
│
├── Section/                              [截面] - L3_MD层截面/属性/材料绑定域
│   │
│   │   【设计意图】
│   │   Section域作为L3_MD层的“截面属性与材料绑定中枢”，承担7个核心职责：
│   │   ① 截面描述管理(MD_Sect_Desc/MD_SectDesc)：截面ID、名称、类型、厚度、材料引用等
│   │   ② 截面类型注册：Solid/Shell/Beam/Membrane/Truss/Cohesive等7+截面族
│   │   ③ 材料桥接(MD_Sect_Base_Desc)：通过polymorphic指针关联材料描述，实现截面-材料解耦
│   │   ④ 几何属性计算：面积A、惯性矩Iyy/Izz/Iyz、扭转常数J、剪切修正因子等
│   │   ⑤ 积分规则配置：高斯点数、积分规则类型、缩减积分控制、沙漏控制等
│   │   ⑥ 附加属性管理：质量(Mass)、非结构质量(NonStructMass)、点质量(PtMass)、转动惯量(RotInertia)
│   │   ⑦ Legacy数据同步(MD_Section_Sync)：从UF_ModelDef%section_db向MD_Section_Domain迁移
│   │
│   │   【功能范围】
│   │   • 截面操作：截面创建/查询/注册/验证/统计
│   │   • 材料桥接：截面-材料双向绑定、polymorphic材料指针
│   │   • 几何计算：梁截面属性计算（面积/惯性矩/扭转常数）
│   │   • 积分控制：高斯积分点配置、缩减积分、沙漏控制
│   │   • 附加属性：质量/非结构质量/点质量/转动惯量
│   │   • 数据同步：Legacy数据迁移、域容器同步
│   │   • 跨域协作：为Element域提供截面属性、为Material域提供引用绑定
│   │   • 热路径：否（建模期操作，但L4_PH层Element Populate消费截面数据）
│   │
│   │   【核心f90文件】
│   │   ① MD_Sect_Core.f90（2554行，106.9KB）
│   │      - 核心截面管理（MatDesc/SectTypeEntry/8个TYPE+20+子程序）
│   │      - 统一查询接口：UF_Section_GetDescriptor/UF_Section_RegisterFull
│   │      - 材料名称注册：UF_Section_RegMatName/UF_Section_GetMaterialName
│   │      - 截面类型注册：UF_SectionTypeReg_InitDefaults/UF_Section_RegisterAType
│   │   ② MD_Sect_Types.f90（587行，21.4KB）
│   │      - 5个TYPE：MD_Sect_Base_Desc/MD_Sect_Registry/MD_SectDesc/MD_Section_Desc/MD_Section_Domain
│   │      - 7个Arg：MD_Sect_Add_Arg/MD_Sect_Validate_Arg/MD_Sect_GetSummary_Arg/MD_Sect_Get_Arg/MD_Sect_GetByName_Arg
│   │      - 域容器：MD_Section_Domain（7个绑定过程）
│   │      - 截面类型码：SECT_FAM_SOLID/SHELL/BEAM/MEMBRANE/TRUSS
│   │   ③ MD_Sect_Lib.f90（407行，15.9KB）
│   │      - 2个TYPE：UF_SectionDef/UF_SectionDBType
│   │      - 9个绑定过程：init/set_solid/set_shell/set_beam_rect/set_beam_circular/set_beam_general/set_membrane/set_truss/compute_beam_props
│   │      - 截面数据库管理：init/add_section/find_by_name/find_by_elset/get_section/clear
│   │   ④ MD_Section_Sync.f90（204行，7.9KB）
│   │      - 2个子程序：MD_Section_SyncFromLegacy/MD_Section_PopulateLegacyFromDomain
│   │      - Legacy↔Domain双向同步
│   │   ⑤ MD_Sect_Domain.f90（31行，1.4KB）
│   │      - 仅重导出MD_Sect_Types（兼容性封装）
│   │   ⑥ MD_Prop_Mass.f90（约400行，15.7KB）
│   │      - 质量属性管理
│   │   ⑦ MD_Prop_NonStructMass.f90（约450行，18.4KB）
│   │      - 非结构质量属性
│   │   ⑧ MD_Prop_PtMass.f90（约400行，15.8KB）
│   │      - 点质量属性
│   │   ⑨ MD_Prop_RotInertia.f90（约550行，21.6KB）
│   │      - 转动惯量属性（KW层使用）
│   │
│   │   【子程序详细清单】
│   │
│   │   **MD_Sect_Core.f90** (2554行)
│   │   ├─ TYPE MatDesc
│   │   │    字段：type/cmname/Formul/section_id/element_family/dim/ndi/nshr/ntens/nprops/props(200)/atype/valid
│   │   ├─ TYPE SectTypeEntry
│   │   │    字段：family/dim/elemPrefix/atype
│   │   ├─ TYPE SectDesc (EXTENDS DescBase)
│   │   │    字段：id/name/sectionType
│   │   │    ├─ RegLayout()
│   │   │    ├─ Ensure()
│   │   │    └─ Init()
│   │   ├─ TYPE SectSta (EXTENDS StateBase)
│   │   │    字段：id/isActive
│   │   │    ├─ RegLayout()
│   │   │    ├─ Ensure()
│   │   │    └─ Init()
│   │   ├─ TYPE SectCtx (EXTENDS CtxBase)
│   │   │    字段：id
│   │   │    ├─ RegLayout()
│   │   │    ├─ Ensure()
│   │   │    └─ Init()
│   │   ├─ TYPE SectAssignDesc (EXTENDS DescBase)
│   │   │    字段：id/secId/region
│   │   │    ├─ RegLayout()
│   │   │    ├─ Ensure()
│   │   │    └─ Init()
│   │   ├─ TYPE SolidSectDesc (EXTENDS DescBase)
│   │   │    字段：id/name/materialName
│   │   │    ├─ RegLayout()/Ensure()/Init()/Valid()
│   │   ├─ TYPE ShellSectDesc (EXTENDS DescBase)
│   │   │    字段：id/name/materialName/thickness
│   │   │    ├─ RegLayout()/Ensure()/Init()/Valid()
│   │   ├─ 统一查询接口
│   │   │    ├─ UF_Section_GetDescriptor()
│   │   │    ├─ UF_Section_RegisterFull()
│   │   ├─ Legacy兼容接口
│   │   │    ├─ UF_Section_Init()
│   │   │    ├─ UF_Section_Reg()
│   │   │    ├─ UF_Section_RegisterBatch()
│   │   │    ├─ UF_Section_GetMaterial()
│   │   │    ├─ UF_Section_GetFormulation()
│   │   │    ├─ UF_SECTION_GETC()
│   │   │    ├─ UF_Section_GetSectionID()
│   │   │    ├─ UF_Section_GetProps()
│   │   │    ├─ UF_Section_AddSection()
│   │   │    ├─ UF_Section_Clear()
│   │   │    ├─ UF_Section_IsInitialized()
│   │   │    └─ UF_Section_GetCount()
│   │   ├─ 材料名称注册
│   │   │    ├─ UF_Section_RegMatName()
│   │   │    ├─ UF_Section_GetMaterialName()
│   │   │    └─ UF_Section_GetMaterialType()
│   │   └─ 截面类型注册
│   │        ├─ UF_SectionTypeReg_InitDefaults()
│   │        ├─ UF_Section_RegisterAType()
│   │        ├─ UF_Section_SuggestATypeFromName()
│   │        └─ UF_Section_SuggestATypeFromFamilyDim()
│   │
│   │   **MD_Sect_Types.f90** (587行)
│   │   ├─ TYPE MD_Sect_Base_Desc
│   │   │    字段：section_id/section_name/mat_id/mat_desc=>NULL()/thickness/orientation(3)/offset/nlayer/integ_npts/integ_rule/section_family/section_type/is_initialized
│   │   │    ├─ InitBasic()
│   │   │    ├─ InitComposite()
│   │   │    ├─ AssociateMaterial()
│   │   │    ├─ Validate()
│   │   │    └─ NullifyPointer()
│   │   ├─ TYPE MD_Sect_Registry
│   │   │    字段：sections(:)/nsections/capacity
│   │   │    ├─ Init()
│   │   │    ├─ AddSection()
│   │   │    ├─ GetSectIdx()
│   │   │    ├─ FindByName()
│   │   │    ├─ FindByMaterial()
│   │   │    └─ Clear()
│   │   ├─ TYPE MD_Section_State
│   │   │    字段：active_sections/total_sections/total_section_area
│   │   ├─ TYPE MD_Section_Ctx
│   │   │    字段：current_section_idx
│   │   ├─ TYPE SectionAlgo
│   │   │    字段：default_integration_rule
│   │   ├─ TYPE MD_SectDesc
│   │   │    字段：name/section_id/section_type/thickness/area/n_integration_pts/material_ref/orientation(3)/n_layers
│   │   ├─ TYPE MD_Section_Desc
│   │   │    字段：name/section_id/section_type/thickness/n_integration_pts/material_ref/orientation(3)/n_layers
│   │   ├─ TYPE MD_Section_Domain
│   │   │    字段：desc_array(:)/n_sections/capacity/algo/initialized
│   │   │    ├─ Init()
│   │   │    ├─ Finalize()
│   │   │    ├─ AddSection()
│   │   │    ├─ GetSection()
│   │   │    ├─ GetSectionByName()
│   │   │    ├─ ValidateSection()
│   │   │    └─ GetSummary()
│   │   └─ 5个Arg类型
│   │        ├─ MD_Sect_Add_Arg
│   │        ├─ MD_Sect_Validate_Arg
│   │        ├─ MD_Sect_GetSummary_Arg
│   │        ├─ MD_Sect_Get_Arg
│   │        └─ MD_Sect_GetByName_Arg
│   │
│   │   **MD_Sect_Lib.f90** (407行)
│   │   ├─ TYPE UF_SectionDef
│   │   │    字段：name/id/section_type/material_name/material_id/elset_name/orientation_name/thickness/shell_thickness/num_integration_points/shell_formulation/offset_ratio/reduced_integration/beam_formulation/xsec_type/xsec_dims(10)/area/Iyy/Izz/Iyz/J/shear_factor_y/shear_factor_z/membrane_thickness/truss_area/cohesive_thickness/response_type/num_gauss_points/hourglass_control/hourglass_stiffness
│   │   │    ├─ init()
│   │   │    ├─ set_solid()
│   │   │    ├─ set_shell()
│   │   │    ├─ set_beam_rect()
│   │   │    ├─ set_beam_circular()
│   │   │    ├─ set_beam_general()
│   │   │    ├─ set_membrane()
│   │   │    ├─ set_truss()
│   │   │    └─ compute_beam_props()
│   │   └─ TYPE UF_SectionDBType
│   │        字段：num_sections/sections(:)
│   │        ├─ init()
│   │        ├─ add_section()
│   │        ├─ find_by_name()
│   │        ├─ find_by_elset()
│   │        ├─ get_section()
│   │        └─ clear()
│   │
│   │   **MD_Section_Sync.f90** (204行)
│   │   ├─ MD_Section_SyncFromLegacy(model_def, md_layer, status)
│   │   │    功能：从UF_ModelDef%section_db同步到MD_Section_Domain
│   │   ├─ MD_Section_PopulateLegacyFromDomain(md_layer, model_def, status)
│   │   │    功能：从MD_Section_Domain反向填充到Legacy
│   │   └─ UF_SectionDef_To_MD_SectDesc(legacy_def, mat_ref, sect_desc)
│   │        功能：Legacy截面描述转换为MD格式
│   │
│   │   **MD_Prop_*.f90** (4个属性文件，约1800行)
│   │   ├─ MD_Prop_Mass.f90 (15.7KB)
│   │   │    - 质量属性管理
│   │   ├─ MD_Prop_NonStructMass.f90 (18.4KB)
│   │   │    - 非结构质量属性
│   │   ├─ MD_Prop_PtMass.f90 (15.8KB)
│   │   │    - 点质量属性
│   │   └─ MD_Prop_RotInertia.f90 (21.6KB)
│   │        - 转动惯量属性（KW层使用）
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory)：截面定义→材料绑定→几何属性→积分规则→Element消费
│   │   • 逻辑链(Logic)：Section域容器→Mat引用→Mesh单元集→L4_PH Element Populate
│   │   • 计算链(Computation)：梁截面属性计算→面积/惯性矩/扭转常数→高斯积分点配置
│   │   • 数据链(Data)：MD_Sect_Desc/MD_Section_State/SectionAlgo/MD_Section_Ctx四型贯通
│   │
│   │   【WriteBack白名单机制】
│   │   • 仅更新：state%active_sections/state%total_sections/state%total_section_area
│   │   • 禁止写入：desc(只读)/algo配置(建模期设置)
│   │   • 线程安全：无（L3_MD层无并发需求）
│   │
│   │   【跨域依赖矩阵】
│   │   • Element域：消费截面属性（厚度/面积/惯性矩/材料引用）
│   │   • Material域：通过mat_desc指针双向绑定
│   │   • Mesh域：通过elset_name引用单元集合
│   │   • Part域：引用Part的section_ref，获取部件截面分配
│   │   • KeyWord域：Prop_RotInertia被KW层使用
│   │   • Model域：聚合Section域容器
│   │
│   │   【调用方统计】
│   │   • 主要调用方：Element/Material/Mesh/Part/KeyWord/Model（6个域）
│   │   • 热路径调用：否（建模期操作，但L4_PH消费截面数据）
│   │
│   │   【已删除模块】
│   │   • ~~MD_Sect_Mgr.f90~~ (58KB)：零调用的Manager
│   │   • ~~MD_Section_API.f90~~ (6KB)：零调用的API封装层
│   │
│   │   【覆盖率统计】
│   │   • 核心文件：9个（Core/Types/Lib/Sync/Domain+4个Prop）
│   │   • TYPE定义：20+个（MatDesc/SectTypeEntry/8个Desc+2个Registry+5个Arg+2个Lib）
│   │   • 子程序总数：50+个
│   │   • 合同对齐：Section/CONTRACT.md已验证
│   │
│   ├── MD_Sect_Core.f90                 → 截面核心(2554行, 20+子程序)
│   ├── MD_Sect_Types.f90                → 截面类型(587行, 15+TYPE, 7个绑定过程)
│   ├── MD_Sect_Lib.f90                  → 截面库(407行, 2个TYPE, 15个绑定过程)
│   ├── MD_Section_Sync.f90              → Legacy同步(204行, 3个子程序)
│   ├── MD_Sect_Domain.f90               → 域容器(31行, 重导出)
│   ├── MD_Prop_Mass.f90                 → 质量属性(15.7KB)
│   ├── MD_Prop_NonStructMass.f90        → 非结构质量(18.4KB)
│   ├── MD_Prop_PtMass.f90               → 点质量(15.8KB)
│   └── MD_Prop_RotInertia.f90           → 转动惯量(21.6KB)
│
├── WriteBack/                            [回写] - L3_MD层L5→L3白名单写回域
│   │
│   │   【设计意图】
│   │   WriteBack域作为L3_MD层的“L5→L3白名单写回网关”，承担7个核心职责：
│   │   ① 白名单管理(MD_WriteBack_Entry)：定义允许回写到L3的域与字段列表
│   │   ② 写回网关(MD_WB_*)：统一L5→L3写回接口，强制白名单校验
│   │   ③ 域分类注册：11个域分类ID(Step/Amplitude/LoadBC/Mesh/Model/Interaction/Output/Assembly/Constraint/Material/Section)
│   │   ④ 写回路由：通过MD_L3_LayerContainer路由到各目标域的WriteBack方法
│   │   ⑤ 统计监控：写回尝试次数/允许次数/拒绝次数统计
│   │   ⑥ 安全校验：字段级白名单校验+锁需求标识+日志记录
│   │   ⑦ Legacy兼容：Init_WriteBack_WhiteList/Is_WriteBack_Allowed/Finalize_WriteBack_WhiteList
│   │
│   │   【功能范围】
│   │   • 白名单管理：白名单初始化/字段注册/允许性校验/统计汇总
│   │   • 写回路由：Step/Amplitude/LoadBC/Mesh/Model/Interaction/Output域写回
│   │   • 网格写回：节点坐标/位移/速度/加速度/单元应力
│   │   • 安全机制：白名单强制校验+拒绝日志+统计追踪
│   │   • 容器绑定：MD_L3_LayerContainer指针绑定（单真相源）
│   │   • 生命周期：初始化→使用→Finalize（含统计报告）
│   │   • 热路径：否（步末/检查点操作，非求解热路径）
│   │
│   │   【核心f90文件】
│   │   ① MD_WriteBack_API.f90（412行，18.1KB）
│   │      - 写回API网关（13个MD_WB_* facade子程序）
│   │      - 容器绑定：MD_WB_SetContainer
│   │      - 生命周期：Init_WriteBack_API/Finalize_WriteBack_API
│   │      - 白名单守卫：WB_Guard（域+字段双重校验）
│   │   ② MD_WriteBack_Mgr.f90（168行，7.8KB）
│   │      - 白名单管理器（Init/Register/IsAllowed/Finalize）
│   │      - 16个预设白名单字段（Mesh 6个/Step 4个/LoadBC 2个/Amplitude 1个/Interaction 2个/Output 1个/Model 1个）
│   │      - 统计变量：g_writeback_attempts/allowed/denied
│   │   ③ MD_WriteBack_Domain_Core.f90（173行，7.2KB）
│   │      - 扁平域存储：MD_WriteBack_WhiteListDomain
│   │      - 5个绑定过程：Init/Finalize/AddEntry/IsAllowed/GetSummary
│   │      - Arg类型：MD_WriteBack_AddEntry_Arg/MD_WriteBack_GetSummary_Arg
│   │   ④ MD_WriteBack_Types.f90（59行，3.0KB）
│   │      - 2个TYPE：MD_WriteBack_Entry/MD_WriteBack_Target
│   │      - 11个域分类常量：WB_DOMAIN_STEP/AMPLITUDE/LOADBC/MESH/MODEL/INTERACTION/OUTPUT/ASSEMBLY/CONSTRAINT/MATERIAL/SECTION
│   │
│   │   【子程序详细清单】
│   │
│   │   **MD_WriteBack_Types.f90** (59行)
│   │   ├─ 域分类常量
│   │   │    WB_DOMAIN_STEP = 1
│   │   │    WB_DOMAIN_AMPLITUDE = 2
│   │   │    WB_DOMAIN_LOADBC = 3
│   │   │    WB_DOMAIN_MESH = 4
│   │   │    WB_DOMAIN_MODEL = 5
│   │   │    WB_DOMAIN_INTERACTION = 6
│   │   │    WB_DOMAIN_OUTPUT = 7
│   │   │    WB_DOMAIN_ASSEMBLY = 8
│   │   │    WB_DOMAIN_CONSTRAINT = 9
│   │   │    WB_DOMAIN_MATERIAL = 10
│   │   │    WB_DOMAIN_SECTION = 11
│   │   ├─ TYPE MD_WriteBack_Entry
│   │   │    字段：field_path/domain_name/field_name/domain_id/is_active/requires_lock
│   │   └─ TYPE MD_WriteBack_Target
│   │        字段：domain_id/entity_idx/field_slot
│   │
│   │   **MD_WriteBack_Domain_Core.f90** (173行)
│   │   ├─ TYPE MD_WriteBack_WhiteListDomain
│   │   │    字段：entries(:)/n_entries/capacity/initialized
│   │   │    ├─ Init(this, initial_capacity, status)
│   │   │    ├─ Finalize(this)
│   │   │    ├─ AddEntry(this, domain_name, field_name, domain_id, is_active, requires_lock, status)
│   │   │    ├─ IsAllowed(this, domain_name, field_name) → is_allowed
│   │   │    └─ GetSummary(this, arg)
│   │   ├─ TYPE MD_WriteBack_AddEntry_Arg
│   │   │    字段：domain_name/field_name/domain_id/is_active/requires_lock/status
│   │   └─ TYPE MD_WriteBack_GetSummary_Arg
│   │        字段：summary/status
│   │
│   │   **MD_WriteBack_Mgr.f90** (168行)
│   │   ├─ Init_WriteBack_WhiteList(status)
│   │   │    功能：初始化白名单（注册16个预设字段）
│   │   │    ├─ Mesh域：currentDOF/node_coordinate/currentNodeDisp/elem_ip_stress/currentNodeVel/currentNodeAcc
│   │   │    ├─ Step域：currentTime/currentStepInc/currentStepIter/is_complete
│   │   │    ├─ LoadBC域：currentLoadScale/currentBCValue
│   │   │    ├─ Amplitude域：currentValue
│   │   │    ├─ Interaction域：isActive/currentContactStatus
│   │   │    ├─ Output域：lastWrittenInc
│   │   │    └─ Model域：isBuilt
│   │   ├─ Register_WriteBack_Field(domain_name, field_name, is_active, requires_lock, status)
│   │   │    功能：注册写回字段（域名称→域ID映射）
│   │   ├─ Is_WriteBack_Allowed(domain_name, field_name) → is_allowed
│   │   │    功能：校验写回是否允许（含统计计数+拒绝日志）
│   │   └─ Finalize_WriteBack_WhiteList()
│   │        功能：Finalize白名单（输出统计报告）
│   │
│   │   **MD_WriteBack_API.f90** (412行)
│   │   ├─ Init_WriteBack_API(status)
│   │   │    功能：初始化WriteBack API+重置统计
│   │   ├─ Finalize_WriteBack_API()
│   │   │    功能：Finalize API（输出统计+释放白名单）
│   │   ├─ MD_WB_SetContainer(container, status)
│   │   │    功能：绑定L3容器指针（必须在使用前调用）
│   │   ├─ WB_Guard(domain_name, field_name, status)
│   │   │    功能：白名单守卫（域+字段双重校验+统计）
│   │   ├─ MD_WB_Step(step_idx, currentTime, currentInc, is_complete, status)
│   │   │    功能：Step域写回（时间/增量步/迭代步/完成标志）
│   │   ├─ MD_WB_Amplitude(idx, currentValue, currentTime, currentIndex, status)
│   │   │    功能：Amplitude域写回（幅值曲线当前值）
│   │   ├─ MD_WB_LoadBC(load_idx, bc_idx, currentLoadScale, currentBCValue, status)
│   │   │    功能：LoadBC域写回（载荷/边界条件当前值）
│   │   ├─ MD_WB_Mesh(currentDOF, status)
│   │   │    功能：Mesh域写回（节点DOF）
│   │   ├─ MD_WB_Mesh_NodePos(node_idx, x, y, z, status)
│   │   │    功能：Mesh节点坐标写回
│   │   ├─ MD_WB_Mesh_NodeDisp(node_idx, ux, uy, uz, status)
│   │   │    功能：Mesh节点位移写回
│   │   ├─ MD_WB_Mesh_NodeVel(node_idx, vx, vy, vz, status)
│   │   │    功能：Mesh节点速度写回
│   │   ├─ MD_WB_Mesh_NodeAcc(node_idx, ax, ay, az, status)
│   │   │    功能：Mesh节点加速度写回
│   │   ├─ MD_WB_Mesh_ElemStress(elem_idx, stress(:), status)
│   │   │    功能：Mesh单元应力写回（积分点应力）
│   │   ├─ MD_WB_Model(isBuilt, build_timestamp, status)
│   │   │    功能：Model域写回（构建标志/时间戳）
│   │   ├─ MD_WB_Interaction(pair_idx, contactStatus, isActive, status)
│   │   │    功能：Interaction域写回（接触状态/激活标志）
│   │   └─ MD_WB_Output(lastWrittenInc, lastWrittenTime, totalFrames, status)
│   │        功能：Output域写回（输出增量步/时间/帧数）
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory)：白名单定义→字段注册→写回校验→域路由→L3状态更新
│   │   • 逻辑链(Logic)：L5调用MD_WB_*→WB_Guard校验→IsAllowed检查→domain%WriteBack→L3状态
│   │   • 计算链(Computation)：步末汇总→白名单过滤→域级写回→统计计数
│   │   • 数据链(Data)：MD_WriteBack_Entry/MD_WriteBack_Target/WhiteListDomain四型贯通
│   │
│   │   【WriteBack白名单机制】
│   │   • 白名单字段：16个预设字段（Mesh 6个/Step 4个/LoadBC 2个/其他4个）
│   │   • 校验规则：域名称+字段名称双重校验
│   │   • 锁需求：requires_lock标识（Mesh/Interaction需要锁）
│   │   • 拒绝日志：IF_Log_Warning记录所有拒绝尝试
│   │   • 统计追踪：attempts/allowed/denied三个计数器
│   │   • 错误码：STATUS_WRITEBACK_DENIED = 11
│   │
│   │   【跨域依赖矩阵】
│   │   • L5_RT层：所有L5求解器通过MD_WB_*写回L3状态
│   │   • Mesh域：节点坐标/位移/速度/加速度/单元应力写回
│   │   • Step域：时间/增量步/迭代步/完成标志写回
│   │   • LoadBC域：载荷缩放因子/边界条件值写回
│   │   • Amplitude域：幅值曲线当前值写回
│   │   • Interaction域：接触状态/激活标志写回
│   │   • Output域：输出增量步/时间/帧数写回
│   │   • Model域：构建标志/时间戳写回
│   │
│   │   【调用方统计】
│   │   • 主要调用方：L5_RT层所有求解器（通过MD_WB_* facade）
│   │   • 热路径调用：否（步末/检查点操作）
│   │
│   │   【已删除模块】
│   │   • ~~MD_WriteBack.f90~~ (8KB)：零调用的模块（功能重复）
│   │
│   │   【覆盖率统计】
│   │   • 核心文件：4个（API/Mgr/Domain_Core/Types）
│   │   • TYPE定义：4个（Entry/Target/WhiteListDomain/2个Arg）
│   │   • 子程序总数：25+个
│   │   • 白名单字段：16个预设字段
│   │   • 合同对齐：WriteBack/CONTRACT.md已验证
│   │
│   ├── MD_WriteBack_API.f90               → 写回API(412行, 13个MD_WB_* facade)
│   ├── MD_WriteBack_Mgr.f90               → 白名单管理(168行, 4个子程序)
│   ├── MD_WriteBack_Domain_Core.f90       → 域核心(173行, 5个绑定过程)
│   └── MD_WriteBack_Types.f90             → 类型定义(59行, 2个TYPE, 11个域常量)
│
├── Bridge/                               [桥接层] - L3_MD层跨层桥接域（L3↔L4/L5）
│   │
│   │   【设计意图】
│   │   Bridge域作为L3_MD层的“跨层桥接中枢”，承担7个核心职责：
│   │   ① L3→L4桥接(Bridge_L4)：将L3_MD的模型数据桥接到L4_PH物理层（材料/单元/接触/载荷/约束/几何）
│   │   ② L3→L5桥接(Bridge_L5)：将L3_MD的模型数据桥接到L5_RT运行时层（模型/装配/网格/输出/求解器等）
│   │   ③ 数据转换：L3的Desc/State类型转换为L4/L5的Ctx/Args类型
│   │   ④ 路由分发：根据材料类型/单元类型/接触类型路由到对应的L4/L5处理函数
│   │   ⑤ 接口封装：隔离L3_MD与L4/L5的直接依赖，通过Bridge模块解耦
│   │   ⑥ ID映射：Model ID与Runtime ID的双向映射（节点/单元/材料/截面）
│   │   ⑦ 数据平台绑定：将UF_ModelDef绑定到L1 DataPlatform，注册场变量
│   │
│   │   【功能范围】
│   │   • L4桥接：材料本构路由/单元计算桥接/接触桥接/载荷BC桥接/约束桥接/几何桥接
│   │   • L5桥接：模型桥接/装配桥接/网格桥接/接触桥接/相互作用桥接/载荷BC桥接/输出桥接/求解器桥接/UI桥接/统一场桥接/关键字桥接
│   │   • 数据转换：L3 Desc→L4 Ctx/L5 RT类型转换
│   │   • ID映射：Model ID↔Runtime ID映射表
│   │   • 路由分发：材料类型路由/单元类型路由/接触类型路由
│   │   • 接口封装：统一桥接接口，隔离层间直接依赖
│   │   • 热路径：是（单元计算/材料本构在热路径中）
│   │
│   │   【核心f90文件】
│   │   Bridge_L4/ (6个文件，79.1KB)
│   │   ① MD_MatLib_PH_Brg.f90（379行，16.7KB）- 材料库桥接
│   │   ② MD_Elem_PH_Brg.f90（273行，13.8KB）- 单元桥接
│   │   ③ MD_LoadBC_PH_Brg.f90（约600行，22.8KB）- 载荷BC桥接
│   │   ④ MD_Geom_PH_Brg.f90（约300行，10.5KB）- 几何桥接
│   │   ⑤ MD_Constraint_PH_Brg.f90（约250行，10.1KB）- 约束桥接
│   │   ⑥ MD_Cont_PH_Brg.f90（约150行，5.2KB）- 接触桥接
│   │
│   │   Bridge_L5/ (13个文件，189.7KB)
│   │   ① MD_Model_Brg.f90（992行，47.1KB）- 模型桥接（DataPlatform+Contact）
│   │   ② MD_Interaction_Brg.f90（约1200行，46.0KB）- 相互作用桥接
│   │   ③ MD_Mesh_Brg.f90（460行，14.8KB）- 网格桥接
│   │   ④ MD_Out_Brg.f90（约400行，13.9KB）- 输出桥接
│   │   ⑤ MD_KW_RT_Brg.f90（约350行，12.8KB）- 关键字桥接
│   │   ⑥ MD_Assem_RT_Brg.f90（约200行，7.8KB）- 装配桥接
│   │   ⑦ MD_LoadBC_RT_Brg.f90（约200行，7.7KB）- 载荷BC桥接
│   │   ⑧ MD_Elem_RT_Brg.f90（约180行，7.0KB）- 单元桥接
│   │   ⑨ MD_Cont_RT_Brg.f90（约130行，4.8KB）- 接触桥接
│   │   ⑩ MD_Model_RT_Brg.f90（约130行，4.9KB）- 模型RT桥接
│   │   ⑪ MD_Solver_Brg.f90（约120行，4.4KB）- 求解器桥接
│   │   ⑫ MD_UniFld_RT_Brg.f90（约100行，3.4KB）- 统一场桥接
│   │   ⑬ MD_UI_RT_Brg.f90（约70行，2.4KB）- UI桥接
│   │
│   │   【子程序详细清单】
│   │
│   │   **Bridge_L4/**
│   │
│   │   **MD_MatLib_PH_Brg.f90** (379行)
│   │   ├─ MD_PH_GetMaterialType(mat_def) → mat_type
│   │   │    功能：从材料定义获取材料类型（ELASTIC/PLASTIC/VISCOELASTIC/HYPERELASTIC）
│   │   ├─ MD_PH_GetMaterialType_FromDesc(mat_desc) → mat_type
│   │   │    功能：从MD_Mat_Desc获取材料类型
│   │   ├─ MD_PH_RouteToConstitutive(mat_def, mat_ctx, status)
│   │   │    功能：路由到本构评估器（L4_PH）
│   │   ├─ MD_PH_RouteToConstitutive_Idx(mat_idx, mat_ctx, status)
│   │   │    功能：通过索引路由到本构评估器
│   │   └─ MD_PH_TransferModelDef(modelDef, status)
│   │        功能：传输模型定义到L4_PH
│   │
│   │   **MD_Elem_PH_Brg.f90** (273行)
│   │   ├─ MD_PH_Elem_GetElemCtx_Idx(elem_idx, arg, status)
│   │   │    功能：通过索引获取单元上下文
│   │   ├─ MD_PH_Elem_CalcContinuum2D(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
│   │   │    功能：2D连续体单元计算
│   │   ├─ MD_PH_Elem_CalcContinuum3D(...)
│   │   │    功能：3D连续体单元计算
│   │   ├─ MD_PH_Elem_CalcPoro(...)
│   │   │    功能：孔隙单元计算
│   │   ├─ MD_PH_Elem_CalcPoroSaturated(...)
│   │   │    功能：饱和孔隙单元计算
│   │   ├─ MD_PH_Elem_CalcPoroTwoPhase(...)
│   │   │    功能：两相孔隙单元计算
│   │   ├─ MD_PH_Elem_CalcThermal(...)
│   │   │    功能：热单元计算
│   │   ├─ MD_PH_Elem_CalcThm(...)
│   │   │    功能：THM耦合单元计算
│   │   └─ MD_PH_Elem_CalcTHM(...)
│   │        功能：完全THM耦合单元计算
│   │
│   │   **MD_LoadBC_PH_Brg.f90** (约600行)
│   │   ├─ 载荷BC桥接子程序（约15个）
│   │   │    - 载荷施加桥接
│   │   │    - 边界条件桥接
│   │   │    - 幅值曲线评估桥接
│   │
│   │   **MD_Geom_PH_Brg.f90** (约300行)
│   │   ├─ MD_PH_Geom_FillElemCtx_Idx(elem_idx, arg)
│   │   │    功能：填充单元几何上下文
│   │   ├─ 几何变换子程序（约8个）
│   │   │    - 坐标变换
│   │   │    - 雅可比矩阵计算
│   │   │    - 形函数梯度
│   │
│   │   **MD_Constraint_PH_Brg.f90** (约250行)
│   │   ├─ 约束桥接子程序（约6个）
│   │   │    - Tie约束桥接
│   │   │    - MPC约束桥接
│   │   │    - 刚性约束桥接
│   │
│   │   **MD_Cont_PH_Brg.f90** (约150行)
│   │   ├─ 接触桥接子程序（约4个）
│   │   │    - 接触对初始化
│   │   │    - 接触面构建
│   │
│   │   **Bridge_L5/**
│   │
│   │   **MD_Model_Brg.f90** (992行)
│   │   ├─ UF_BindModelRuntime_ToDataPlatform(modelDef, mv_ctx, ierr)
│   │   │    功能：绑定模型运行时到数据平台
│   │   ├─ UF_BuildContMesh_FromUFModel(modelDef, contMesh, status)
│   │   │    功能：从UFModel构建连续体网格
│   │   ├─ UF_BuildStepBC_ForNewCore(step, loadbc_step, status)
│   │   │    功能：构建步边界条件
│   │   ├─ UF_BuildStepLoad_ForNewCore(step, loadbc_step, status)
│   │   │    功能：构建步载荷
│   │   ├─ UF_ProjectSectionsToModelCtx(modelDef, modelCtx, status)
│   │   │    功能：投影截面到模型上下文
│   │   ├─ UF_register_model_in_dataplatform(modelDef, ierr)
│   │   │    功能：在数据平台注册模型
│   │   ├─ UF_UpdateStepLoadAmplitudes_ForNewCore(step, status)
│   │   │    功能：更新步载荷幅值
│   │   ├─ UF_BuildContact_FromUFModel(modelDef, contactPairs, status)
│   │   │    功能：从UFModel构建接触
│   │   ├─ UF_BuildContactPairDef_FromDB(pairDef, contactPropDB, status)
│   │   │    功能：从数据库构建接触对定义
│   │   ├─ UF_BuildContactSurface_FromNodeSet(nodeSet, surface, status)
│   │   │    功能：从节点集构建接触面
│   │   └─ UF_FillSurfaceDofMap_FromDOFMgr(dofMgr, surfaceDofMap, status)
│   │        功能：从DOF管理器填充表面DOF映射
│   │
│   │   **MD_Mesh_Brg.f90** (460行)
│   │   ├─ RT_Mesh_BrgInit(status)
│   │   │    功能：初始化网格桥接
│   │   ├─ RT_Mesh_BrgClean()
│   │   │    功能：清理网格桥接
│   │   ├─ RT_Mesh_BrgMapElemId(modelId, runtimeId)
│   │   │    功能：映射单元ID
│   │   ├─ RT_Mesh_BrgMapMatId(modelId, runtimeId)
│   │   │    功能：映射材料ID
│   │   ├─ RT_Mesh_BrgMapSectId(modelId, runtimeId)
│   │   │    功能：映射截面ID
│   │   ├─ RT_Mesh_BrgMapNodeId(modelId, runtimeId)
│   │   │    功能：映射节点ID
│   │   ├─ RT_Mesh_BrgGetElemCnt() → count
│   │   │    功能：获取单元计数
│   │   ├─ RT_Mesh_BrgGetNodeCnt() → count
│   │   │    功能：获取节点计数
│   │   ├─ RT_Mesh_BrgInitMats(status)
│   │   │    功能：初始化材料
│   │   ├─ RT_Mesh_BrgInitElems(status)
│   │   │    功能：初始化单元
│   │   ├─ RT_Mesh_BrgInitSects(status)
│   │   │    功能：初始化截面
│   │   ├─ RT_Mesh_Brg_GetNodeCoords_Idx(node_idx, arg)
│   │   │    功能：通过索引获取节点坐标
│   │   └─ RT_Mesh_Brg_GetElemConnect_Idx(elem_idx, arg)
│   │        功能：通过索引获取单元连接
│   │
│   │   **其他Bridge_L5文件** (约2000行)
│   │   ├─ MD_Interaction_Brg.f90 (46.0KB)
│   │   │    - 相互作用桥接（约30个子程序）
│   │   ├─ MD_Out_Brg.f90 (13.9KB)
│   │   │    - 输出桥接（约10个子程序）
│   │   ├─ MD_KW_RT_Brg.f90 (12.8KB)
│   │   │    - 关键字桥接（约8个子程序）
│   │   ├─ MD_Assem_RT_Brg.f90 (7.8KB)
│   │   │    - 装配桥接（约6个子程序）
│   │   ├─ MD_LoadBC_RT_Brg.f90 (7.7KB)
│   │   │    - 载荷BC桥接（约6个子程序）
│   │   ├─ MD_Elem_RT_Brg.f90 (7.0KB)
│   │   │    - 单元RT桥接（约5个子程序）
│   │   ├─ MD_Cont_RT_Brg.f90 (4.8KB)
│   │   │    - 接触RT桥接（约4个子程序）
│   │   ├─ MD_Model_RT_Brg.f90 (4.9KB)
│   │   │    - 模型RT桥接（约4个子程序）
│   │   ├─ MD_Solver_Brg.f90 (4.4KB)
│   │   │    - 求解器桥接（约3个子程序）
│   │   ├─ MD_UniFld_RT_Brg.f90 (3.4KB)
│   │   │    - 统一场桥接（约3个子程序）
│   │   └─ MD_UI_RT_Brg.f90 (2.4KB)
│   │        - UI桥接（约2个子程序）
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory)：L3模型定义→桥接转换→L4/L5物理/运行时处理
│   │   • 逻辑链(Logic)：L3调用Bridge→路由分发→L4/L5函数调用→结果返回
│   │   • 计算链(Computation)：材料本构评估/单元刚度计算/接触检测/载荷施加
│   │   • 数据链(Data)：L3 Desc→L4 Ctx/L5 RT类型转换，ID映射表
│   │
│   │   【桥接模式说明】
│   │   • L3→L4桥接：L3_MD调用L4_PH本构/单元计算函数（热路径）
│   │   • L3→L5桥接：L3_MD向L5_RT传递模型数据/接收运行时状态
│   │   • 接口封装：Bridge模块隔离L3与L4/L5的直接依赖
│   │   • 类型转换：L3的Desc/State类型转换为L4/L5的Ctx/Args类型
│   │   • ID映射：Model ID与Runtime ID双向映射（节点/单元/材料/截面）
│   │
│   │   【跨域依赖矩阵】
│   │   • L4_PH层：Material/Element/Contact/LoadBC/Constraint/Geometry域
│   │   • L5_RT层：Model/Assembly/Mesh/Contact/Interaction/LoadBC/Output/Solver/UI/UniFld/KeyWord域
│   │   • L1_IF层：DataPlatform（数据注册/场变量管理）
│   │
│   │   【调用方统计】
│   │   • 主要调用方：L3_MD所有域（通过Bridge访问L4/L5）
│   │   • 热路径调用：是（单元计算/材料本构在热路径中）
│   │
│   │   【覆盖率统计】
│   │   • 核心文件：19个（Bridge_L4 6个 + Bridge_L5 13个）
│   │   • 子程序总数：100+个
│   │   • 桥接域：L4 6个域 + L5 13个域
│   │
│   ├── Bridge_L4/                       [L4桥接] (6个文件, 79.1KB)
│   │   ├── MD_MatLib_PH_Brg.f90         → 材料库桥接(379行, 5个子程序)
│   │   ├── MD_Elem_PH_Brg.f90           → 单元桥接(273行, 10个子程序)
│   │   ├── MD_LoadBC_PH_Brg.f90         → 载荷BC桥接(约600行, 15个子程序)
│   │   ├── MD_Geom_PH_Brg.f90           → 几何桥接(约300行, 9个子程序)
│   │   ├── MD_Constraint_PH_Brg.f90     → 约束桥接(约250行, 6个子程序)
│   │   └── MD_Cont_PH_Brg.f90           → 接触桥接(约150行, 4个子程序)
│   │
│   └── Bridge_L5/                       [L5桥接] (13个文件, 189.7KB)
│       ├── MD_Model_Brg.f90             → 模型桥接(992行, 10个子程序)
│       ├── MD_Interaction_Brg.f90       → 相互作用桥接(约1200行, 30个子程序)
│       ├── MD_Mesh_Brg.f90              → 网格桥接(460行, 13个子程序)
│       ├── MD_Out_Brg.f90               → 输出桥接(约400行, 10个子程序)
│       ├── MD_KW_RT_Brg.f90             → 关键字桥接(约350行, 8个子程序)
│       ├── MD_Assem_RT_Brg.f90          → 装配桥接(约200行, 6个子程序)
│       ├── MD_LoadBC_RT_Brg.f90         → 载荷BC桥接(约200行, 6个子程序)
│       ├── MD_Elem_RT_Brg.f90           → 单元桥接(约180行, 5个子程序)
│       ├── MD_Cont_RT_Brg.f90           → 接触桥接(约130行, 4个子程序)
│       ├── MD_Model_RT_Brg.f90          → 模型RT桥接(约130行, 4个子程序)
│       ├── MD_Solver_Brg.f90            → 求解器桥接(约120行, 3个子程序)
│       ├── MD_UniFld_RT_Brg.f90         → 统一场桥接(约100行, 3个子程序)
│       └── MD_UI_RT_Brg.f90             → UI桥接(约70行, 2个子程序)
│
├── L3_MD_Analysis_Group_Module.f90      → 分析组模块(264行) - PROC→Group映射+三维正交坐标系统
│   │   │
│   │   │   【设计意图】
│   │   │   L3_MD_Analysis_Group_Module作为L3_MD层的“分析类型三维正交坐标系统”，承担5个核心职责：
│   │   │   ① PROC→Group映射：将91个PROC编号映射到三维正交坐标(Solver×Coupling×Physics)
│   │   │   ② 分析类型描述(MD_Analysis_Group_DESC)：完整描述分析类型的求解器/耦合策略/物理场
│   │   │   ③ 兼容性矩阵：定义分析类型之间的兼容性关系
│   │   │   ④ 1-based/0-based双轨制：外部API用1-based（用户可见），内部计算用0-based（矩阵访问）
│   │   │   ⑤ 多求解器耦合标记：标识是否需要辅助求解器
│   │   │
│   │   │   【功能范围】
│   │   │   • 求解器分类：5类(SOLVER_STANDARD/EXPLICIT/ACOUSTIC/EM/CFD)
│   │   │   • 耦合策略：4类(COUPLING_ONESHOT/ONEWAY/WEAK/STRONG)
│   │   │   • 物理场分类：12类(STRUCTURE/THERMAL/FREQUENCY/ACOUSTIC/EM/FLUID/THERMALSTRUCT/ELECTROSTRUCT/FLUIDSTRUCT/FLUIDTHERMAL/MULTIFIELD/SPECIAL)
│   │   │   • PROC映射：PROC 1-91到Group_ID的映射表
│   │   │   • 兼容性校验：validate_group_combination/get_compatibility_matrix
│   │   │   • Group_ID计算：solver*100 + coupling*10 + physics
│   │   │
│   │   │   【子程序详细清单】
│   │   │
│   │   │   **L3_MD_Analysis_Group_Module.f90** (264行)
│   │   │   ├─ TYPE MD_Analysis_Group_DESC
│   │   │   │    字段：solver_1based/coupling_1based/physics_1based（1-based）
│   │   │   │          solver_idx/coupling_idx/physics_idx（0-based）
│   │   │   │          group_id_3d/proc_id_origin
│   │   │   │          n_compatible_coupling/compatible_couplings(1:4)
│   │   │   │          requires_auxiliary_solver/auxiliary_solver_id
│   │   │   │          description
│   │   │   ├─ group_from_proc_id(proc_id) → group
│   │   │   │    功能：根据PROC编号创建Group_DESC（支持PROC 1-91）
│   │   │   ├─ validate_group_combination(group1, group2) → is_valid
│   │   │   │    功能：校验两个分析类型的兼容性
│   │   │   └─ get_compatibility_matrix() → matrix
│   │   │        功能：获取兼容性矩阵
│   │   │
│   │   │   【跨域依赖矩阵】
│   │   │   • Step域：通过PROC编号确定分析步类型
│   │   │   • Solver域：通过求解器类型路由到对应求解器
│   │   │   • Model域：聚合分析组信息
│   │   │
│   │   │   【覆盖率统计】
│   │   │   • 核心文件：1个
│   │   │   • TYPE定义：1个（MD_Analysis_Group_DESC）
│   │   │   • 子程序总数：3个
│   │   │   • PROC支持：91个（当前实现关键PROC映射）
│   │
│   ├── MD_L3_LayerContainer_Core.f90        → L3层容器(1535行) - 14域聚合+跨域绑定+生命周期管理
│   │   │
│   │   │   【设计意图】
│   │   │   MD_L3_LayerContainer_Core作为L3_MD层的“顶级域容器和聚合中枢”，承担7个核心职责：
│   │   │   ① 14域聚合：聚合所有14个域容器（Model/Part/Assembly/Constraint/Mesh/Section/Material/Amplitude/LoadBC/Interaction/Step/Solver/Output/WriteBack）
│   │   │   ② 跨域绑定(MD_L3_DomainAssoc)：显式绑定相关域（Part↔Assembly/Mesh↔Section/Material↔Section等）
│   │   │   ③ 生命周期管理：Init（1→14顺序）/Finalize（14→1逆序）/Freeze（冻结模型）
│   │   │   ④ 模型验证：ValidateModel/ValidateAllRefs/ValidateBindings（校验跨域引用完整性）
│   │   │   ⑤ 增量校验缓存：checksum机制+per-domain validated标志，避免重复校验
│   │   │   ⑥ 域计数同步：SyncModelCounts（同步各域的对象计数到Model域）
│   │   │   ⑦ 三层嵌套：UFC_GlobalContainer → MD_L3_LayerContainer → MD_<Domain>_Domain
│   │   │
│   │   │   【功能范围】
│   │   │   • 域容器聚合：14个域容器的统一访问点
│   │   │   • 跨域绑定：Part↔Assembly/Assembly↔Mesh/Section↔Material/Section↔Mesh/Mesh↔Element/Step↔LoadBC/LoadBC↔Amplitude/Interaction↔Mesh
│   │   │   • 生命周期：Init→BindDomains→ValidateBindings→Freeze→Finalize
│   │   │   • 模型验证：ValidateModel（整体验证）/ValidateAllRefs（引用验证）
│   │   │   • 增量校验：checksum缓存+per-domain validated标志
│   │   │   • 计数同步：SyncModelCounts（同步各域计数到Model域）
│   │   │   • 冻结机制：Freeze（l3Frozen标志，防止建模后修改）
│   │   │
│   │   │   【子程序详细清单】
│   │   │
│   │   │   **MD_L3_LayerContainer_Core.f90** (1535行)
│   │   │   ├─ TYPE MD_L3_DomainAssoc
│   │   │   │    字段：part_to_assembly_idx/assembly_has_parts
│   │   │   │          assembly_to_mesh_idx/mesh_n_instances
│   │   │   │          section_count/material_ref_count/section_to_elemset_count
│   │   │   │          step_loadbc_count/step_interaction_count
│   │   │   │          loadbc_amplitude_refs
│   │   │   │          interaction_pair_count/interaction_surf_validated
│   │   │   │          is_bound/binding_validated
│   │   │   │          validation_cached/cache_checksum/cached_error_count/cached_errors(:)
│   │   │   │          domain_checksum_section/material/interaction/constraint/element/ic
│   │   │   │          section_validated/material_validated/interaction_validated/constraint_validated/element_validated/ic_validated
│   │   │   ├─ TYPE MD_L3_LayerContainer
│   │   │   │    字段：model/part/assembly/constraint/mesh/section/material/amplitude/loadbc/interaction/step/solver/output/writeback
│   │   │   │          assoc（跨域绑定）
│   │   │   │          initialized/l3Frozen
│   │   │   │    ├─ Init(this, status)
│   │   │   │    │    功能：初始化14个域容器（1→14顺序）
│   │   │   │    ├─ Finalize(this)
│   │   │   │    │    功能：Finalize14个域容器（14→1逆序，LIFO）
│   │   │   │    ├─ Freeze(this, status)
│   │   │   │    │    功能：冻结模型（l3Frozen=.TRUE.，防止修改）
│   │   │   │    ├─ BindDomains(this, status)
│   │   │   │    │    功能：建立跨域绑定关系
│   │   │   │    ├─ ValidateBindings(this, errors, error_count)
│   │   │   │    │    功能：校验跨域绑定完整性
│   │   │   │    ├─ SyncModelCounts(this, status)
│   │   │   │    │    功能：同步各域计数到Model域
│   │   │   │    └─ ValidateModel(this, status)
│   │   │   │         功能：验证模型完整性（调用ValidateAllRefs）
│   │   │   ├─ MD_L3_ValidateAllRefs(container, errors, error_count)
│   │   │   │    功能：验证所有跨域引用完整性
│   │   │   │    ├─ 校验Section→Material引用
│   │   │   │    ├─ 校验Section→Mesh引用
│   │   │   │    ├─ 校验Interaction→Mesh表面引用
│   │   │   │    ├─ 校验LoadBC→Amplitude引用
│   │   │   │    ├─ 校验Step→LoadBC/Interaction引用
│   │   │   │    └─ 校验Constraint→Mesh引用
│   │   │
│   │   │   【四链贯通说明】
│   │   │   • 理论链(Theory)：域容器聚合→跨域绑定→模型验证→冻结→Finalize
│   │   │   • 逻辑链(Logic)：Init→BindDomains→ValidateBindings→SyncModelCounts→Freeze→Finalize
│   │   │   • 计算链(Computation)：域初始化→绑定建立→引用校验→计数同步
│   │   │   • 数据链(Data)：14个域容器+MD_L3_DomainAssoc跨域绑定结构
│   │   │
│   │   │   【跨域依赖矩阵】
│   │   │   • 14个域容器：Model/Part/Assembly/Constraint/Mesh/Section/Material/Amplitude/LoadBC/Interaction/Step/Solver/Output/WriteBack
│   │   │   • 上层调用：UFC_GlobalContainer（持有md_layer指针）
│   │   │   • 下层调用：L4_PH/L5_RT通过g_ufc_global%md_layer%<domain>访问
│   │   │
│   │   │   【覆盖率统计】
│   │   │   • 核心文件：1个
│   │   │   • TYPE定义：2个（MD_L3_DomainAssoc/MD_L3_LayerContainer）
│   │   │   • 子程序总数：8个（Init/Finalize/Freeze/BindDomains/ValidateBindings/SyncModelCounts/ValidateModel/ValidateAllRefs）
│   │   │   • 域容器数：14个
│   │   │   • 跨域绑定：8个关联关系
│   │
│   └── UFC_HashSet_Utility.f90              → 哈希集工具(158行) - O(1)字符串快速查找
│       │
│       │   【设计意图】
│       │   UFC_HashSet_Utility作为L3_MD层的“哈希集工具库”，承担4个核心职责：
│       │   ① O(1)字符串查找：提供平均O(1)时间复杂度的字符串成员资格测试
│       │   ② 哈希链表实现：采用djb2哈希算法+链地址法解决冲突
│       │   ③ 校验加速：用于跨域引用校验中的快速集合成员检查
│       │   ④ 内存管理：支持动态初始化/插入/销毁
│       │
│       │   【功能范围】
│       │   • 哈希集初始化：HashSet_Init（指定容量）
│       │   • 哈希集插入：HashSet_Insert（自动去重）
│       │   • 哈希集查找：HashSet_Contains（O(1)平均复杂度）
│       │   • 哈希集销毁：HashSet_Destroy（释放所有节点）
│       │   • 哈希算法：djb2算法（适合字符串）
│       │
│       │   【子程序详细清单】
│       │
│       │   **UFC_HashSet_Utility.f90** (158行)
│       │   ├─ TYPE HashNode
│       │   │    字段：key（字符串）/next（链表指针）
│       │   ├─ TYPE HashSetType
│       │   │    字段：buckets(:)/num_buckets/size/initialized
│       │   │    ├─ Insert(this, key)
│       │   │    │    功能：插入键值（自动去重）
│       │   │    ├─ Contains(this, key) → found
│       │   │    │    功能：检查键是否存在（O(1)平均）
│       │   │    ├─ Size(this) → size
│       │   │    │    功能：获取集合大小
│       │   │    └─ Destroy(this)
│       │   │         功能：销毁哈希集（释放所有节点）
│       │   ├─ Hash_String(key) → hash_val
│       │   │    功能：djb2哈希算法（字符串→哈希值）
│       │   ├─ HashSet_Init(this, capacity)
│       │   │    功能：初始化哈希集（指定桶数量）
│       │   ├─ HashSet_Insert(this, key)
│       │   │    功能：插入键值（自动去重+链地址法）
│       │   ├─ HashSet_Contains(this, key) → found
│       │   │    功能：检查键是否存在（O(1)平均复杂度）
│       │   ├─ HashSet_Size(this) → size
│       │   │    功能：获取集合大小
│       │   └─ HashSet_Destroy(this)
│       │        功能：销毁哈希集（释放所有内存）
│       │
│       │   【跨域依赖矩阵】
│       │   • MD_L3_LayerContainer_Core：用于跨域引用校验中的快速集合查找
│       │   • ValidateAllRefs：用于校验引用完整性时的去重检查
│       │
│       │   【覆盖率统计】
│       │   • 核心文件：1个
│       │   • TYPE定义：2个（HashNode/HashSetType）
│       │   • 子程序总数：6个（Hash_String/Init/Insert/Contains/Size/Destroy）
│       │   • 时间复杂度：O(1)平均查找/插入
```

**L3_MD 统计**: 15 域 | 8 子域 | 350+ 文件 | TYPE策略: **统一合并 `_Types.f90`（按需 USE）**

---

## 五、L4_PH — 物理计算层

```text
L4_PH/
├── Material/                             [⭐ 核心域: 11大族54种材料 - L4_PH层本构计算热路径]
│   │
│   │   【设计意图】
│   │   Material域作为L4_PH层的“本构计算热路径核心”，承担7个核心职责：
│   │   ① 本构计算(Compute_Ctan)：给定应变/变形增量，计算应力、一致切线C_tan、更新内变量SDV
│   │   ② 11大材料族支持：Elastic/HyperElas/Plastic/Geotech/PorousFoam/Damage/Composite/Visc/Coupling/Special/UMAT
│   │   ③ Slot池管理(PH_Mat_Slot)：积分点级材料状态管理(mat_pt_idx索引)
│   │   ④ 注册与分发(PH_Mat_Reg)：mat_id→本构实现的注册与路由
│   │   ⑤ UMAT支持：用户材料子程序接口(UMAT/VUMAT/HETVAL)
│   │   ⑥ Populate消费：从L3_MD读取Desc→填充slot%ctx%props（冷路径）
│   │   ⑦ 热路径零L3：禁止步内反复MD_Mat_Get*扫库，须读slot props
│   │
│   │   【功能范围】
│   │   • 本构计算：弹性/塑性/超弹性/粘弹性/蠕变/损伤/地质/复合/多场耦合/特殊/UMAT
│   │   • 一致切线：C_tan计算（应力-应变关系的线性化）
│   │   • 内变量更新：SDV(State Dependent Variables)管理
│   │   • 增量控制：IncrBegin（增量开始）/Rollback（Newton失败恢复）
│   │   • 子步控制：Params控制塑性/粘塑稳定性
│   │   • 注册分发：mat_id→Compute_Proc路由
│   │   • 热路径：是（与Element同属NR/动力学IP循环）
│   │
│   │   【核心f90文件】
│   │   核心容器(4个)
│   │   ① PH_Mat_Domain_Core.f90（约2000行）- 材料域容器
│   │   ② PH_Mat_Ctx.f90（约300行）- 材料上下文
│   │   ③ PH_Mat_Reg_Core.f90（约800行）- 材料注册表
│   │   ④ PH_Mat_Eval.f90（约1500行）- 显式Eval族
│   │
│   │   横切工具(5个)
│   │   ⑤ PH_Mat_Utils.f90（约400行）- 材料工具
│   │   ⑥ PH_Mat_HashTable.f90（约300行）- 材料哈希表
│   │   ⑦ PH_Mat_Dispatch.f90（约350行）- 材料分发器
│   │   ⑧ PH_Mat_Standards.f90（约200行）- 材料标准
│   │   ⑨ PH_MatConstit_Type.f90（约150行）- 本构类型
│   │
│   │   Shared横切(3个)
│   │   ⑩ PH_Mat_Unified_Dispatch.f90（约500行）- 统一分发
│   │   ⑪ PH_Mat_ParamMapping.f90（约300行）- 参数映射
│   │   ⑫ PH_Mat_Defn_UMAT_Bridge.f90（约400行）- UMAT桥接
│   │   ⑬ PH_Mat_Core_UMAT_Adapter.f90（约350行）- UMAT适配器
│   │
│   │   USR用户材料(3个)
│   │   ⑭ PH_UserSub_UMAT.f90（约600行）- UMAT接口
│   │   ⑮ PH_UserSub_VUMAT.f90（约500行）- VUMAT接口
│   │   ⑯ PH_UserSub_HETVAL.f90（约300行）- HETVAL热生成
│   │
│   │   11大材料族（按合同卡定义）
│   │   ① Elastic/ (ELA族, 6种) - PH_Mat_Elas_Core.f90等
│   │   ② HyperElas/ (HYP族, 8种) - PH_Mat_Hyper_Core.f90等
│   │   ③ Plastic/ (PLM族, 8种) - PH_Mat_Plast_Core.f90等
│   │   ④ Geotech/ (PLG族, 6种) - PH_Mat_Geo_Core.f90等
│   │   ⑤ PorousFoam/ (POR族, 4种) - PH_Mat_Porous_Core.f90等
│   │   ⑥ Damage/ (DMG族, 6种) - PH_Mat_Damage_Core.f90等
│   │   ⑦ Composite/ (CMP族, 5种) - PH_Mat_Comp_Core.f90等
│   │   ⑧ Visc/ (VSC族, 5种) - PH_Mat_Visco_Core.f90等
│   │   ⑨ Coupling/ (MPH族, 4种) - PH_Mat_Coupling_Core.f90等
│   │   ⑩ Special/ (SPU族, 3种) - PH_Mat_Special_Core.f90等
│   │   ⑪ UMAT/ (USR族) - 用户材料
│   │
│   │   【子程序详细清单】
│   │
│   │   **PH_Mat_Domain_Core.f90** (约2000行)
│   │   ├─ TYPE PH_Mat_Slot
│   │   │    字段：matModel/props(:)/matId/mat_pt_idx/initialized
│   │   ├─ TYPE PH_Mat_State
│   │   │    字段：stress(:)/C_tan(:,:)/stateVars(:)/stateVars_n(:)/converged
│   │   ├─ TYPE PH_Mat_Ctx
│   │   │    字段：matModel/props(:)/matId/nProps/nStatev
│   │   ├─ TYPE PH_Mat_Params
│   │   │    字段：nSubsteps/finiteStrain/thermalCoupling/viscous
│   │   ├─ TYPE PH_Mat_Domain
│   │   │    字段：slot_pool(:)/n_slots/capacity/initialized
│   │   │    ├─ Init(this, max_slots, status)
│   │   │    │    功能：初始化Slot池（PH_MAT_MAX_POOL限制）
│   │   │    ├─ Finalize(this)
│   │   │    │    功能：FinalizeSlot池
│   │   │    ├─ RegisterMaterialModel(this, mat_id, mat_type, status)
│   │   │    │    功能：注册本构模型元数据
│   │   │    ├─ Compute_Ctan(this, mat_pt_idx, strain_inc, stress_out, C_tan_out, status)
│   │   │    │    功能：热路径-计算一致切线+应力更新
│   │   │    ├─ Update_StateVars(this, mat_pt_idx, status)
│   │   │    │    功能：收敛步更新内变量(stateVars_n→stateVars)
│   │   │    ├─ IncrBegin(this, mat_pt_idx, status)
│   │   │    │    功能：增量开始（备份stateVars→stateVars_n）
│   │   │    ├─ Rollback(this, mat_pt_idx, status)
│   │   │    │    功能：Newton失败恢复（stateVars_n→stateVars）
│   │   │    └─ GetSummary(this, summary, status)
│   │   │         功能：诊断信息
│   │   ├─ PH_Mat_AllocSlot_Idx(mat_pt_idx, status)
│   │   │    功能：分配Slot（返回mat_pt_idx）
│   │   ├─ PH_Mat_GetCtx_Idx(mat_pt_idx, ctx, status)
│   │   │    功能：获取材料上下文
│   │   ├─ PH_Mat_SetState_Idx(mat_pt_idx, state, status)
│   │   │    功能：设置材料状态
│   │   └─ PH_Mat_Compute_Ctan_Arg/Update_StateVars_Arg等
│   │        功能：Arg类型（携带ErrorStatusType）
│   │
│   │   **PH_Mat_Reg_Core.f90** (约800行)
│   │   ├─ TYPE PH_Mat_Reg_Entry
│   │   │    字段：mat_id/category/integration_family/impl_status/nProps/nStatev/Compute_Proc
│   │   ├─ PH_Mat_Reg_InitAll()
│   │   │    功能：初始化注册表（注册54种材料）
│   │   ├─ PH_Mat_Reg_Get(mat_id) → entry
│   │   │    功能：获取材料注册条目
│   │   ├─ PH_Mat_Reg_Add(mat_id, entry, status)
│   │   │    功能：添加材料注册（UMAT动态注册）
│   │   └─ PH_Mat_Reg_Clear()
│   │        功能：清空注册表
│   │
│   │   **PH_Mat_Ctx.f90** (约300行)
│   │   ├─ TYPE PH_Mat_Ctx
│   │   │    字段：matModel/props(:)/matId/nProps/nStatev
│   │   ├─ PH_MAT_* 枚举
│   │   │    MAT_ELASTIC=1/MAT_PLASTIC=2/MAT_HYPERELASTIC=3/MAT_VISCOELASTIC=4等
│   │   └─ PH_Mat_Ctx_Init/Finalize
│   │        功能：上下文初始化/Finalize
│   │
│   │   **PH_Mat_Eval.f90** (约1500行)
│   │   ├─ PH_Mat_Eval_Elastic(...) - 弹性Eval
│   │   ├─ PH_Mat_Eval_Plastic(...) - 塑性Eval
│   │   ├─ PH_Mat_Eval_HyperElastic(...) - 超弹性Eval
│   │   ├─ PH_Mat_Eval_Viscoelastic(...) - 粘弹性Eval
│   │   ├─ PH_Mat_Eval_Creep(...) - 蠕变Eval
│   │   ├─ PH_Mat_Eval_Damage(...) - 损伤Eval
│   │   └─ 其他族Eval
│   │        功能：族内核可调用的求值入口
│   │
│   │   **PH_Mat_Utils.f90** (约400行)
│   │   ├─ 材料工具函数（约15个）
│   │   │    - 张量操作（Voigt记号转换）
│   │   │    - 不变量计算（I1/J2/J3等）
│   │   │    - 矩阵操作（对称矩阵压缩）
│   │
│   │   **PH_Mat_HashTable.f90** (约300行)
│   │   ├─ 材料哈希表（快速查找mat_id）
│   │   │    - Hash_Insert/Hash_Lookup/Hash_Delete
│   │
│   │   **PH_Mat_Dispatch.f90** (约350行)
│   │   ├─ 材料分发器（matModel→Compute_Proc路由）
│   │   │    - Dispatch_Compute_Ctan/Dispatch_Update_StateVars
│   │
│   │   **11大材料族核心文件** (约10000行)
│   │   ├─ Elastic/ (ELA, 6种)
│   │   │    PH_Mat_Elas_Core.f90 - 弹性核心
│   │   │    PH_Mat_Elas_Iso.f90 - 各向同性弹性
│   │   │    PH_Mat_Elas_Ortho.f90 - 正交弹性
│   │   │    PH_Mat_Elas_Anisotropic.f90 - 各向异性弹性
│   │   │    PH_Mat_Elas_Cubic.f90 - 立方对称弹性
│   │   │    PH_Mat_Elas_TransIso.f90 - 横观各向同性
│   │   │    PH_Mat_Elas_AxiIsotropic.f90 - 轴对称各向同性
│   │   ├─ HyperElas/ (HYP, 8种)
│   │   │    PH_Mat_Hyper_Core.f90 - 超弹性核心
│   │   │    PH_Mat_Hyper_NeoHookean.f90 - Neo-Hookean
│   │   │    PH_Mat_Hyper_MooneyRivlin.f90 - Mooney-Rivlin
│   │   │    PH_Mat_Hyper_Ogden.f90 - Ogden
│   │   │    PH_Mat_Hyper_Yeoh.f90 - Yeoh
│   │   │    PH_Mat_Hyper_Polynomial.f90 - 多项式
│   │   │    PH_Mat_Hyper_ReducedPoly.f90 - 缩减多项式
│   │   │    PH_Mat_Hyper_ArrudaBoyce.f90 - Arruda-Boyce
│   │   ├─ Plastic/ (PLM, 8种)
│   │   │    PH_Mat_Plast_Core.f90 - 塑性核心
│   │   │    PH_Mat_Plast_J2Iso.f90 - J2等向强化
│   │   │    PH_Mat_Plast_J2Kin.f90 - J2随动强化
│   │   │    PH_Mat_Plast_J2Mix.f90 - J2混合强化
│   │   │    PH_Mat_Plast_Hill.f90 - Hill'48
│   │   │    PH_Mat_Plast_Chaboche.f90 - Chaboche随动硬化
│   │   │    PH_Mat_Plast_Crystal.f90 - 晶体塑性
│   │   │    PH_Mat_Plast_Barlat.f90 - Barlat Yld2000
│   │   ├─ Geotech/ (PLG, 6种)
│   │   │    PH_Mat_Geo_Core.f90 - 地质核心
│   │   │    PH_Mat_Geo_DruckerPrager.f90 - Drucker-Prager
│   │   │    PH_Mat_Geo_MohrCoulomb.f90 - Mohr-Coulomb
│   │   │    PH_Mat_Geo_CamClay.f90 - 剑桥模型(MCC)
│   │   │    PH_Mat_Geo_ModCamClay.f90 - 修正剑桥
│   │   │    PH_Mat_Geo_HoekBrown.f90 - Hoek-Brown
│   │   │    PH_Mat_Geo_BartonBandis.f90 - Barton-Bandis
│   │   ├─ PorousFoam/ (POR, 4种)
│   │   │    PH_Mat_Porous_Core.f90 - 多孔核心
│   │   │    PH_Mat_Porous_Gurson.f90 - Gurson-Tvergaard
│   │   │    PH_Mat_Porous_Foam.f90 - 泡沫
│   │   │    PH_Mat_Porous_Crushable.f90 - 可压碎泡沫
│   │   ├─ Damage/ (DMG, 6种)
│   │   │    PH_Mat_Damage_Core.f90 - 损伤核心
│   │   │    PH_Mat_Damage_Ductile.f90 - 延性损伤
│   │   │    PH_Mat_Damage_Shear.f90 - 剪切损伤
│   │   │    PH_Mat_Damage_JohnsonCook.f90 - Johnson-Cook
│   │   │    PH_Mat_Damage_XFEM.f90 - XFEM损伤
│   │   │    PH_Mat_Damage_MK.f90 - MK损伤
│   │   ├─ Composite/ (CMP, 5种)
│   │   │    PH_Mat_Comp_Core.f90 - 复合核心
│   │   │    PH_Mat_Comp_Lamina.f90 - 单层板
│   │   │    PH_Mat_Comp_Hashin.f90 - Hashin损伤
│   │   │    PH_Mat_Comp_Puck.f90 - Puck准则
│   │   │    PH_Mat_Comp_LaRC.f90 - LaRC准则
│   │   ├─ Visc/ (VSC, 5种)
│   │   │    PH_Mat_Visco_Core.f90 - 粘弹性核心
│   │   │    PH_Mat_Visco_Linear.f90 - 线性粘弹性
│   │   │    PH_Mat_Visco_Prony.f90 - Prony级数
│   │   │    PH_Mat_Visco_GenMaxwell.f90 - 广义Maxwell
│   │   │    PH_Mat_Creep_PowerLaw.f90 - 幂律蠕变
│   │   ├─ Coupling/ (MPH, 4种)
│   │   │    PH_Mat_Coupling_Core.f90 - 多场耦合核心
│   │   │    PH_Mat_Coupling_Thermal.f90 - 热-力耦合
│   │   │    PH_Mat_Coupling_Poro.f90 - 流-固耦合
│   │   │    PH_Mat_Coupling_Piezo.f90 - 压电耦合
│   │   ├─ Special/ (SPU, 3种)
│   │   │    PH_Mat_Special_Core.f90 - 特殊核心
│   │   │    PH_Mat_Special_Damping.f90 - 阻尼
│   │   │    PH_Mat_Special_EOS.f90 - 状态方程
│   │   └─ UMAT/ (USR)
│   │        PH_UserSub_UMAT.f90 - UMAT接口
│   │        PH_UserSub_VUMAT.f90 - VUMAT接口
│   │        PH_UserSub_HETVAL.f90 - HETVAL热生成
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory)：本构关系σ=f(ε,props)→一致线性化C_tan=∂σ/∂ε→内变量更新
│   │   • 逻辑链(Logic)：L3 Populate→slot%ctx%props→Compute_Ctan→Element IP循环
│   │   • 计算链(Computation)：应变增量→本构Eval→应力更新→C_tan计算→SDV更新
│   │   • 数据链(Data)：PH_Mat_Slot/State/Ctx/Params四型贯通
│   │
│   │   【热路径规范】
│   │   • 热路径零L3：禁止步内反复MD_Mat_Get*扫库
│   │   • 必须读slot props：slot_pool(mat_pt_idx)%ctx%props
│   │   • Populate写入：props仅由PH_L4_Populate_Material写入（冷路径）
│   │   • 子步控制：Params%nSubsteps控制塑性/粘塑稳定性
│   │   • TP-8反模式：热路径内禁止ALLOCATE（须Init阶段预分配）
│   │
│   │   【跨域依赖矩阵】
│   │   • L3_MD/Material：提供Desc/props/material_ref
│   │   • L3_MD/Section：截面引用材料ID→mat_pt_idx映射
│   │   • L4_PH/Element：IP循环调用Compute_Ctan
│   │   • L5_RT：编排驱动（RT_Contm_Struct_Mat/RT_Elem_*）
│   │
│   │   【覆盖率统计】
│   │   • 核心文件：50+个（容器4个+工具8个+11族38个）
│   │   • TYPE定义：10+个（Slot/State/Ctx/Params/Domain/Reg_Entry等）
│   │   • 子程序总数：200+个
│   │   • 材料族：11大族54种标准材料
│   │   • 合同对齐：Material/CONTRACT.md已验证
│   │
│   ├── PH_Mat_Domain_Core.f90      → 材料域容器(约2000行, 8个TYPE绑定)
│   ├── PH_Mat_Ctx.f90                   → 材料上下文(约300行, PH_MAT枚举)
│   ├── PH_Mat_Reg_Core.f90              → 注册表(约800行, 4个子程序)
│   ├── PH_Mat_Eval.f90                  → Eval族(约1500行, 7个Eval)
│   ├── PH_Mat_Utils.f90                 → 工具(约400行, 15个工具函数)
│   ├── PH_Mat_HashTable.f90             → 哈希表(约300行)
│   ├── PH_Mat_Dispatch.f90              → 分发器(约350行)
│   ├── PH_Mat_Standards.f90             → 标准(约200行)
│   ├── PH_MatConstit_Type.f90           → 本构类型(约150行)
│   ├── PH_Mat_Unified_Dispatch.f90      → 统一分发(约500行)
│   ├── PH_Mat_ParamMapping.f90          → 参数映射(约300行)
│   ├── PH_Mat_Defn_UMAT_Bridge.f90      → UMAT桥接(约400行)
│   ├── PH_Mat_Core_UMAT_Adapter.f90     → UMAT适配器(约350行)
│   ├── PH_UserSub_UMAT.f90              → UMAT接口(约600行)
│   ├── PH_UserSub_VUMAT.f90             → VUMAT接口(约500行)
│   ├── PH_UserSub_HETVAL.f90            → HETVAL(约300行)
│   │
│   ├── Elastic/                         [ELA族, 6种]
│   │   ├── PH_Mat_Elas_Core.f90         → 弹性核心
│   │   ├── PH_Mat_Elas_Iso.f90          → 各向同性
│   │   ├── PH_Mat_Elas_Ortho.f90        → 正交
│   │   ├── PH_Mat_Elas_Anisotropic.f90  → 各向异性
│   │   ├── PH_Mat_Elas_Cubic.f90        → 立方对称
│   │   ├── PH_Mat_Elas_TransIso.f90     → 横观各向同性
│   │   └── PH_Mat_Elas_AxiIsotropic.f90 → 轴对称各向同性
│   │
│   ├── HyperElas/                       [HYP族, 8种]
│   │   ├── PH_Mat_Hyper_Core.f90        → 超弹性核心
│   │   ├── PH_Mat_Hyper_NeoHookean.f90  → Neo-Hookean
│   │   ├── PH_Mat_Hyper_MooneyRivlin.f90→ Mooney-Rivlin
│   │   ├── PH_Mat_Hyper_Ogden.f90       → Ogden
│   │   ├── PH_Mat_Hyper_Yeoh.f90        → Yeoh
│   │   ├── PH_Mat_Hyper_Polynomial.f90  → 多项式
│   │   ├── PH_Mat_Hyper_ReducedPoly.f90 → 缩减多项式
│   │   └── PH_Mat_Hyper_ArrudaBoyce.f90 → Arruda-Boyce
│   │
│   ├── Plastic/                         [PLM族, 8种]
│   │   ├── PH_Mat_Plast_Core.f90        → 塑性核心
│   │   ├── PH_Mat_Plast_J2Iso.f90       → J2等向强化
│   │   ├── PH_Mat_Plast_J2Kin.f90       → J2随动强化
│   │   ├── PH_Mat_Plast_J2Mix.f90       → J2混合强化
│   │   ├── PH_Mat_Plast_Hill.f90        → Hill'48
│   │   ├── PH_Mat_Plast_Chaboche.f90    → Chaboche
│   │   ├── PH_Mat_Plast_Crystal.f90     → 晶体塑性
│   │   └── PH_Mat_Plast_Barlat.f90      → Barlat Yld2000
│   │
│   ├── Geotech/                         [PLG族, 6种]
│   │   ├── PH_Mat_Geo_Core.f90          → 地质核心
│   │   ├── PH_Mat_Geo_DruckerPrager.f90 → Drucker-Prager
│   │   ├── PH_Mat_Geo_MohrCoulomb.f90   → Mohr-Coulomb
│   │   ├── PH_Mat_Geo_CamClay.f90       → 剑桥模型
│   │   ├── PH_Mat_Geo_ModCamClay.f90    → 修正剑桥
│   │   ├── PH_Mat_Geo_HoekBrown.f90     → Hoek-Brown
│   │   └── PH_Mat_Geo_BartonBandis.f90  → Barton-Bandis
│   │
│   ├── PorousFoam/                      [POR族, 4种]
│   │   ├── PH_Mat_Porous_Core.f90       → 多孔核心
│   │   ├── PH_Mat_Porous_Gurson.f90     → Gurson-Tvergaard
│   │   ├── PH_Mat_Porous_Foam.f90       → 泡沫
│   │   └── PH_Mat_Porous_Crushable.f90  → 可压碎泡沫
│   │
│   ├── Damage/                          [DMG族, 6种]
│   │   ├── PH_Mat_Damage_Core.f90       → 损伤核心
│   │   ├── PH_Mat_Damage_Ductile.f90    → 延性损伤
│   │   ├── PH_Mat_Damage_Shear.f90      → 剪切损伤
│   │   ├── PH_Mat_Damage_JohnsonCook.f90→ Johnson-Cook
│   │   ├── PH_Mat_Damage_XFEM.f90       → XFEM
│   │   └── PH_Mat_Damage_MK.f90         → MK损伤
│   │
│   ├── Composite/                       [CMP族, 5种]
│   │   ├── PH_Mat_Comp_Core.f90         → 复合核心
│   │   ├── PH_Mat_Comp_Lamina.f90       → 单层板
│   │   ├── PH_Mat_Comp_Hashin.f90       → Hashin
│   │   ├── PH_Mat_Comp_Puck.f90         → Puck
│   │   └── PH_Mat_Comp_LaRC.f90         → LaRC
│   │
│   ├── Visc/                            [VSC族, 5种]
│   │   ├── PH_Mat_Visco_Core.f90        → 粘弹性核心
│   │   ├── PH_Mat_Visco_Linear.f90      → 线性粘弹性
│   │   ├── PH_Mat_Visco_Prony.f90       → Prony级数
│   │   ├── PH_Mat_Visco_GenMaxwell.f90  → 广义Maxwell
│   │   └── PH_Mat_Creep_PowerLaw.f90    → 幂律蠕变
│   │
│   ├── Coupling/                        [MPH族, 4种]
│   │   ├── PH_Mat_Coupling_Core.f90     → 多场耦合核心
│   │   ├── PH_Mat_Coupling_Thermal.f90  → 热-力耦合
│   │   ├── PH_Mat_Coupling_Poro.f90     → 流-固耦合
│   │   └── PH_Mat_Coupling_Piezo.f90    → 压电耦合
│   │
│   ├── Special/                         [SPU族, 3种]
│   │   ├── PH_Mat_Special_Core.f90      → 特殊核心
│   │   ├── PH_Mat_Special_Damping.f90   → 阻尼
│   │   └── PH_Mat_Special_EOS.f90       → 状态方程
│   │
│   └── UMAT/                            [USR族]
│       ├── PH_UserSub_UMAT.f90          → UMAT接口
│       ├── PH_UserSub_VUMAT.f90         → VUMAT接口
│       └── PH_UserSub_HETVAL.f90        → HETVAL热生成
│
├── Element/                              [⭐ 核心域: 12大族245种单元(含变体377) - L4_PH层单元数值离散热路径]
│   │
│   │   【设计意图】
│   │   Element域作为L4_PH层的"单元数值离散核心",承担6个核心职责:
│   │   ① 形函数计算(Shape Functions): 各单元类型的形函数N(ξ,η,ζ)及其导数
│   │   ② Jacobian变换: 自然坐标→物理坐标的映射,体积微元dΩ计算
│   │   ③ B矩阵计算: 应变-位移矩阵B=∂N/∂x,将节点位移映射为应变
│   │   ④ 高斯积分: Ke=∫B^T·D·B·dΩ, Fe=∫B^T·σ·dΩ的高斯数值积分
│   │   ⑤ 12大单元族支持: Solid3D/Solid2D/Shell/Beam/Truss/Infinite/Cohesive/Spring/Dashpot/Mass/Gasket/Surface
│   │   ⑥ 单元注册表: elem_type→元数据(n_nodes/n_ip/n_dof/family_id)注册与路由
│   │
│   │   【功能范围】
│   │   • 刚度矩阵: Ke=∫B^T·C_tan·B·dΩ (热路径金线入口Compute_Ke)
│   │   • 内力向量: Fe=∫B^T·σ·dΩ (热路径金线入口Compute_Fe)
│   │   • 质量矩阵: Me=∫ρ·N^T·N·dΩ (显式动力学)
│   │   • B矩阵: 应变-位移矩阵计算
│   │   • 形函数: 各单元类型的形函数及其导数
│   │   • Jacobian: 坐标变换与体积微元
│   │   • 高斯积分: 积分点坐标/权重,高斯循环
│   │   • 沙漏控制: 缩减积分单元的沙漏稳定化
│   │   • 非线性几何: 大变形/有限应变(UL/TL格式)
│   │   • 单元族分发: elem_type→具体实现的注册与路由
│   │   • 热路径: 是(与Material同属NR/动力学IP循环)
│   │
│   │   【核心f90文件】
│   │   核心容器(4个)
│   │   ① PH_Element_Domain_Core.f90 (约164行) - 单元域容器(金线入口)
│   │   ② PH_Element_Domain.f90 (约200行) - 单元域类型定义
│   │   ③ PH_Elem_Reg_Core.f90 (约800行) - 单元注册表
│   │   ④ PH_Elem_Types.f90 (约300行) - 单元类型定义
│   │
│   │   分发路由(4个)
│   │   ⑤ PH_Element_Ke_Dispatch.f90 (约300行) - 刚度矩阵分发
│   │   ⑥ PH_Element_Fe_Dispatch.f90 (约250行) - 内力向量分发
│   │   ⑦ PH_Element_Mass_Dispatch.f90 (约200行) - 质量矩阵分发
│   │   ⑧ PH_Element_Out_Dispatch.f90 (约150行) - 输出采集分发
│   │
│   │   Shared工具链(22个)
│   │   ⑨ PH_Elem_ShapeFunc.f90 (约600行) - 形函数核心
│   │   ⑩ PH_Elem_Jacobian.f90 (约350行) - Jacobian变换
│   │   ⑪ PH_Elem_BMtx.f90 (约500行) - B矩阵计算
│   │   ⑫ PH_Elem_IntegPts.f90 (约400行) - 高斯积分点
│   │   ⑬ PH_Elem_Utils.f90 (约400行) - 单元工具
│   │   ⑭ PH_Elem_Common_Util.f90 (约500行) - 通用工具
│   │   ⑮ PH_Elem_Quality.f90 (约1500行) - 单元质量检查
│   │   ⑯ PH_Elem_Material_Integration.f90 (约200行) - 材料集成
│   │   ⑰ PH_Elem_Mtx.f90 (约550行) - 矩阵操作
│   │   ⑱ PH_Physics_Utils.f90 (约800行) - 物理工具
│   │   ⑲ PH_Elem_JacobianB_Utils.f90 (约700行) - Jacobian/B矩阵工具
│   │   ⑳ PH_Elem_Diff_Utils.f90 (约250行) - 微分工具
│   │   ㉑ PH_Elem_Comp.f90 (约550行) - 单元计算
│   │   ㉒ PH_Shell_NLGeom_Core.f90 (约400行) - 壳非线性几何
│   │   ㉓ PH_Elem_BC_Kernel.f90 (约100行) - 边界条件核
│   │   ㉔ PH_Elem_Load_Kernel.f90 (约100行) - 载荷核
│   │   ㉕ PH_Elem_Out_Kernel.f90 (约120行) - 输出核
│   │   ㉖ PH_Elem_Orient_RT_Brg.f90 (约20行) - 方向桥接
│   │   ㉗ PH_Elem_RT_Brg.f90 (约200行) - 运行桥接
│   │   ㉘ PH_Elem_Dispatch_C3D8.f90 (约200行) - C3D8分发
│   │   ㉙ PH_Elem_Dispatch_Reg.f90 (约200行) - 分发注册
│   │
│   │   计算核心(4个)
│   │   ㉚ PH_Elem_Contm_Core.f90 (约3500行) - 连续体核心(历史遗留)
│   │   ㉛ PH_Elem_Contm.f90 (约300行) - 连续体门面
│   │   ㉜ PH_Elem_GaussInt.f90 (约250行) - 高斯积分
│   │   ㉝ PH_NLGeom_Eval.f90 (约2000行) - 非线性几何评估
│   │
│   │   辅助模块(6个)
│   │   ㉞ PH_Elem_Ctx.f90 (约550行) - 单元上下文
│   │   ㉟ PH_Elem_ComplexStiff.f90 (约100行) - 复刚度
│   │   ㊱ PH_Elem_Calc_Wrapper.f90 (约400行) - 计算包装器
│   │   ㊲ PH_Mass_Core.f90 (约500行) - 质量核心
│   │   ㊳ PH_Math_Tensor.f90 (约350行) - 张量数学
│   │   ㊴ PH_Physical_Constants.f90 (约400行) - 物理常数
│   │   ㊵ PH_ShapeMechanicalField.f90 (约400行) - 力学场形函数
│   │   ㊶ PH_ShapeScalarField.f90 (约600行) - 标量场形函数
│   │   ㊷ PH_Element_Structural_Facade.f90 (约70行) - 结构门面
│   │   ㊸ PH_Err_Code.f90 (约70行) - 错误代码
│   │
│   │   12大单元族目录 (按实际代码)
│   │   ① SLD3D/ (3D实体, 18种) - PH_ELEM_C3D8/C3D8R/C3D20等
│   │   ② SLD2D/ (2D实体, 16种) - PH_ELEM_CPE4/CPS4/CAX4等
│   │   ③ SLD2DT/ (2D温度, 13种) - PH_ELEM_CPE4T/CPS4T等
│   │   ④ SLD3DT/ (3D温度, 8种) - PH_ELEM_C3D8T/C3D20T等
│   │   ⑤ SHELL/ (壳单元, 24种) - PH_ELEM_S4/S4R/S8R等
│   │   ⑥ BEAM/ (梁单元, 33种) - PH_ELEM_B31/B32/B33等
│   │   ⑦ TRUSS/ (桁架, 6种) - PH_ELEM_T2D2/T3D2等
│   │   ⑧ SPRING/ (弹簧, 4种) - PH_ELEM_SPRING1/SPRING2等
│   │   ⑨ DASHPOT/ (阻尼器, 2种) - PH_ELEM_DASHPOT1/DASHPOT2
│   │   ⑩ POROUS/ (多孔/流固, 20种) - PH_ELEM_C3D8P等
│   │   ⑪ ACOUSTIC/ (声学, 12种) - PH_ELEM_AC3D8等
│   │   ⑫ THERMAL/ (热传导, 5种) - PH_ELEM_DC3D8等
│   │   ⑬ SPECIAL/ (特殊单元, 12种) - 质量/膜/界面等
│   │   ⑭ INFINITE/ (无限元, 8种) - PH_ELEM_CIN3D8等
│   │   ⑮ MEMBRANE/ (膜单元, 6种)
│   │   ⑯ PIPE/ (管道单元, 4种)
│   │
│   │   【子程序详细清单】
│   │
│   │   **PH_Element_Domain_Core.f90** (约164行)
│   │   ├─ TYPE PH_Elem_Compute_Ke_Args
│   │   │    字段: elem_idx/mat_pt_idx/ndofel/nstrs/ctx/state/Ke(:,:)/status
│   │   ├─ TYPE PH_Elem_Compute_Fe_Args
│   │   │    字段: elem_idx/mat_pt_idx/ndofel/nstrs/ctx/state/integrate_boundary/face_id/edge_id/traction(:)/Fe(:,:)/stress(:,:)/status
│   │   ├─ PH_Elem_ComputeStiffness(args)
│   │   │    功能: 计算单元刚度矩阵Ke=∫B^T·C·B·dΩ
│   │   │    委托: PH_Element_Ke_Dispatch.Compute_Ke
│   │   ├─ PH_Elem_ComputeInternalForce(args)
│   │   │    功能: 计算内力向量Fe=∫B^T·σ·dΩ
│   │   │    委托: PH_Element_Fe_Dispatch.Compute_Fe
│   │   ├─ PH_Element_Ctan6_RotateCt_LabToRThetaZ(R, C_lab, C_rtz)
│   │   │    功能: 切线矩阵坐标系旋转(实验室→柱坐标)
│   │   ├─ PH_Element_StressVoigt6_ToPlane3_124(sigma6, sigma3)
│   │   │    功能: 6维应力→平面3维(124分量)
│   │   └─ PH_Element_StressVoigt6_ToCax4_1325(sigma6, sigma4)
│   │        功能: 6维应力→轴对称4维(1325分量)
│   │
│   │   **PH_Elem_Reg_Core.f90** (约800行)
│   │   ├─ TYPE PH_Elem_Reg_Entry
│   │   │    字段: elem_type/base_elem_type/name(:16)/n_nodes/n_ip/n_dof/family_id/is_registered
│   │   ├─ PH_ELEM_FAMILY_* 枚举
│   │   │    PH_ELEM_FAMILY_C3D=1/PH_ELEM_FAMILY_CPE=2/PH_ELEM_FAMILY_CPS=3/PH_ELEM_FAMILY_CAX=4
│   │   │    PH_ELEM_FAMILY_S=5/PH_ELEM_FAMILY_B=6/PH_ELEM_FAMILY_T=7/PH_ELEM_FAMILY_OTHER=8
│   │   ├─ PH_Elem_Reg_InitAll()
│   │   │    功能: 初始化注册表(注册377种单元)
│   │   ├─ PH_Elem_Reg_Get(elem_type) → entry
│   │   │    功能: 获取单元注册条目
│   │   ├─ PH_Elem_Reg_IsRegistered(elem_type) → logical
│   │   │    功能: 检查单元是否已注册
│   │   ├─ PH_Elem_Reg_Add(elem_type, entry, status)
│   │   │    功能: 添加单元注册(UEL动态注册)
│   │   └─ PH_ELEM_REG_MAX=450
│   │        功能: 注册表容量限制
│   │
│   │   **PH_Element_Ke_Dispatch.f90** (约300行)
│   │   ├─ Compute_Ke(args)
│   │   │    功能: 刚度矩阵计算路由
│   │   │    流程: elem_type→PH_Elem_Reg_Get→族Core→Compute_Ke
│   │   └─ 其他分发函数
│   │
│   │   **PH_Element_Fe_Dispatch.f90** (约250行)
│   │   ├─ Compute_Fe(args)
│   │   │    功能: 内力向量计算路由
│   │   │    流程: elem_type→PH_Elem_Reg_Get→族Core→Compute_Fe
│   │   └─ 其他分发函数
│   │
│   │   **PH_Elem_ShapeFunc.f90** (Shared, 约600行)
│   │   ├─ 形函数核心(约30个子程序)
│   │   │    - ShapeFunc_C3D8(ξ,η,ζ)→N(:)
│   │   │    - ShapeFunc_C3D20(ξ,η,ζ)→N(:)
│   │   │    - ShapeFunc_S4(ξ,η)→N(:)
│   │   │    - ShapeFunc_B31(ξ)→N(:)
│   │   │    - 各单元类型的形函数及其导数
│   │
│   │   **PH_Elem_Jacobian.f90** (Shared, 约350行)
│   │   ├─ Jacobian计算(约15个子程序)
│   │   │    - Compute_Jacobian(coords, dNdξ)→J(:,:)
│   │   │    - Compute_JacobianInv(J)→Jinv(:,:)
│   │   │    - Compute_JacobianDet(J)→detJ
│   │   │    - dNdX = Jinv·dNdξ (链式法则)
│   │
│   │   **PH_Elem_BMtx.f90** (Shared, 约500行)
│   │   ├─ B矩阵计算(约20个子程序)
│   │   │    - Compute_BMatrix_3D(dNdX, n_nodes)→B(:,:)
│   │   │    - Compute_BMatrix_2D(dNdX, n_nodes)→B(:,:)
│   │   │    - Compute_BMatrix_Shell(dNdX, n_nodes)→B(:,:)
│   │   │    - 应变-位移矩阵B的组装
│   │
│   │   **PH_Elem_IntegPts.f90** (Shared, 约400行)
│   │   ├─ 高斯积分点(约15个子程序)
│   │   │    - GaussPts_1D(n)→ξ(:),w(:)
│   │   │    - GaussPts_2D(n)→ξ(:),η(:),w(:)
│   │   │    - GaussPts_3D(n)→ξ(:),η(:),ζ(:),w(:)
│   │   │    - 1-4阶高斯积分点与权重
│   │
│   │   **PH_Elem_Quality.f90** (Shared, 约1500行)
│   │   ├─ 单元质量检查(约40个子程序)
│   │   │    - 雅可比行列式检查(detJ>0)
│   │   │    - 长宽比检查(aspect_ratio)
│   │   │    - 内角检查(internal_angles)
│   │   │    - 扭曲度检查(distortion)
│   │   │    - 翘曲度检查(warping)
│   │
│   │   **PH_Elem_Contm_Core.f90** (约3500行, 历史遗留)
│   │   ├─ 连续体单元计算核心(USE MD_*技术债)
│   │   │    - 约50个子程序(各单元类型的Ke/Fe计算)
│   │   │    - 新热路径优先金线+Populate缓存
│   │
│   │   **PH_NLGeom_Eval.f90** (约2000行)
│   │   ├─ 非线性几何评估(约30个子程序)
│   │   │    - 大变形/有限应变(UL/TL格式)
│   │   │    - 应变度量(Green-Lagrange/Almansi)
│   │   │    - 应力度量(第1/2类Piola-Kirchhoff)
│   │
│   │   **12大单元族核心文件** (约15000行)
│   │   ├─ SLD3D/ (3D实体, 18种)
│   │   │    PH_Elem_C3D8.f90 - C3D8(8节点线性)
│   │   │    PH_Elem_C3D8R.f90 - C3D8R(缩减积分)
│   │   │    PH_Elem_C3D8I.f90 - C3D8I(非协调模式)
│   │   │    PH_Elem_C3D20.f90 - C3D20(20节点二次)
│   │   │    PH_Elem_C3D20R.f90 - C3D20R(缩减积分)
│   │   │    PH_Elem_C3D4.f90 - C3D4(4节点四面体)
│   │   │    PH_Elem_C3D10.f90 - C3D10(10节点四面体)
│   │   │    PH_Elem_C3D6.f90 - C3D6(6节点楔形)
│   │   │    PH_Elem_C3D15.f90 - C3D15(15节点楔形)
│   │   │    PH_Elem_C3D8T.f90 - C3D8T(温度)
│   │   │    PH_Elem_C3D8P.f90 - C3D8P(孔隙压力)
│   │   │    PH_Elem_C3D8E.f90 - C3D8E(压电)
│   │   ├─ SLD2D/ (2D实体, 16种)
│   │   │    PH_Elem_CPE4.f90 - CPE4(平面应变)
│   │   │    PH_Elem_CPE4R.f90 - CPE4R(缩减积分)
│   │   │    PH_Elem_CPS4.f90 - CPS4(平面应力)
│   │   │    PH_Elem_CPS4R.f90 - CPS4R(缩减积分)
│   │   │    PH_Elem_CAX4.f90 - CAX4(轴对称)
│   │   │    PH_Elem_CAX4R.f90 - CAX4R(缩减积分)
│   │   ├─ SHELL/ (壳单元, 24种)
│   │   │    PH_Elem_S4.f90 - S4(4节点线性)
│   │   │    PH_Elem_S4R.f90 - S4R(缩减积分)
│   │   │    PH_Elem_S8R.f90 - S8R(8节点二次)
│   │   │    PH_Elem_S3.f90 - S3(3节点线性)
│   │   │    PH_Elem_S4T.f90 - S4T(温度)
│   │   │    PH_Elem_S4P.f90 - S4P(孔隙压力)
│   │   ├─ BEAM/ (梁单元, 33种)
│   │   │    PH_Elem_B31.f90 - B31(2节点线性)
│   │   │    PH_Elem_B31R.f90 - B31R(缩减积分)
│   │   │    PH_Elem_B32.f90 - B32(3节点二次)
│   │   │    PH_Elem_B32R.f90 - B32R(缩减积分)
│   │   │    PH_Elem_B31T.f90 - B31T(温度)
│   │   │    PH_Elem_PIPE31.f90 - PIPE31(管道)
│   │   ├─ TRUSS/ (桁架, 6种)
│   │   │    PH_Elem_T2D2.f90 - T2D2(2D 2节点)
│   │   │    PH_Elem_T3D2.f90 - T3D2(3D 2节点)
│   │   ├─ SPRING/ (弹簧, 4种)
│   │   │    PH_Elem_SPRING1.f90 - SPRING1(单节点)
│   │   │    PH_Elem_SPRING2.f90 - SPRING2(双节点)
│   │   ├─ DASHPOT/ (阻尼器, 2种)
│   │   │    PH_Elem_DASHPOT1.f90 - DASHPOT1(单节点)
│   │   │    PH_Elem_DASHPOT2.f90 - DASHPOT2(双节点)
│   │   ├─ POROUS/ (多孔/流固, 20种)
│   │   │    PH_Elem_C3D8P.f90 - C3D8P(孔隙压力)
│   │   │    PH_Elem_COH3D8.f90 - COH3D8(内聚力)
│   │   ├─ ACOUSTIC/ (声学, 12种)
│   │   │    PH_Elem_AC3D8.f90 - AC3D8(声学)
│   │   ├─ THERMAL/ (热传导, 5种)
│   │   │    PH_Elem_DC3D8.f90 - DC3D8(热传导)
│   │   ├─ SPECIAL/ (特殊单元, 12种)
│   │   │    PH_Elem_MASS.f90 - MASS(集中质量)
│   │   │    PH_Elem_M3D4R.f90 - M3D4R(膜)
│   │   ├─ INFINITE/ (无限元, 8种)
│   │   │    PH_Elem_CIN3D8.f90 - CIN3D8(3D无限元)
│   │   └─ MEMBRANE/PIPE (膜/管道, 10种)
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory): 弱式K_e=∫B^T·D·B·dΩ, F_e=∫B^T·σ·dΩ(Voigt记号)
│   │   • 逻辑链(Logic): L3 Populate→elem_type_cache→PH_Elem_Reg_Get→族Core→Compute_Ke/Fe
│   │   • 计算链(Computation): 形函数→Jacobian→B矩阵→材料C_tan/σ→高斯积分→Ke/Fe组装
│   │   • 数据链(Data): PH_Elem_Compute_Ke_Args/Compute_Fe_Args金线参数+elem_*_cache
│   │
│   │   【热路径规范】
│   │   • 热路径零L3: 步内禁止直接遍历L3网格库(MD_Mesh_*)
│   │   • 必须读Populate缓存: elem_coords_cache/elem_npe_cache/elem_type_cache
│   │   • 材料C_tan: 来自material%slot_pool(mat_pt_idx)(或弹性预存state%C_tan)
│   │   • use_cache假时允许MD_PH_Geom_FillElemCtx_Idx单点回退
│   │   • 禁止IP内层对网格库做全模型遍历
│   │   • TP-8反模式: 热路径内禁止ALLOCATE(须Init阶段预分配)
│   │
│   │   【跨域依赖矩阵】
│   │   • L3_MD/Mesh: 提供拓扑真相源(elem_type_id/n_nodes/coords)
│   │   • L3_MD/Section: 截面引用材料ID→mat_pt_idx映射
│   │   • L4_PH/Material: IP循环调用Compute_Ctan获取C_tan/σ
│   │   • L5_RT: 组装RT_Asm_GlobalStiffness/RT_Asm_ComputeResidual
│   │
│   │   【覆盖率统计】
│   │   • 核心文件: 80+个(容器4个+分发4个+Shared工具22个+计算核心4个+辅助6个+12族40+个)
│   │   • TYPE定义: 10+个(Compute_Ke_Args/Compute_Fe_Args/Reg_Entry/Base_Ctx/Base_State等)
│   │   • 子程序总数: 300+个(形函数30+Jacobian 15+B矩阵20+积分15+质量40+族计算150+)
│   │   • 单元族: 12大族245种单元(含变体377)
│   │   • 合同对齐: Element/CONTRACT.md已验证
│   │
│   ├── PH_Element_Domain_Core.f90       → 单元域容器(约164行, 金线入口)
│   ├── PH_Element_Domain.f90            → 单元域类型(约200行)
│   ├── PH_Elem_Reg_Core.f90             → 注册表(约800行, 377种单元)
│   ├── PH_Elem_Types.f90                → 类型定义(约300行)
│   ├── PH_Element_Ke_Dispatch.f90       → Ke分发(约300行)
│   ├── PH_Element_Fe_Dispatch.f90       → Fe分发(约250行)
│   ├── PH_Element_Mass_Dispatch.f90     → 质量分发(约200行)
│   ├── PH_Element_Out_Dispatch.f90      → 输出分发(约150行)
│   ├── PH_Elem_Contm_Core.f90           → 连续体核心(约3500行, 历史遗留)
│   ├── PH_Elem_Contm.f90                → 连续体门面(约300行)
│   ├── PH_Elem_Ctx.f90                  → 单元上下文(约550行)
│   ├── PH_Elem_GaussInt.f90             → 高斯积分(约250行)
│   ├── PH_NLGeom_Eval.f90               → 非线性几何(约2000行)
│   ├── PH_Elem_ComplexStiff.f90         → 复刚度(约100行)
│   ├── PH_Elem_Calc_Wrapper.f90         → 计算包装器(约400行)
│   ├── PH_Mass_Core.f90                 → 质量核心(约500行)
│   ├── PH_Math_Tensor.f90               → 张量数学(约350行)
│   ├── PH_Physical_Constants.f90        → 物理常数(约400行)
│   ├── PH_ShapeMechanicalField.f90      → 力学场形函数(约400行)
│   ├── PH_ShapeScalarField.f90          → 标量场形函数(约600行)
│   ├── PH_Element_Structural_Facade.f90 → 结构门面(约70行)
│   ├── PH_Err_Code.f90                  → 错误代码(约70行)
│   │
│   ├── Shared/                          [工具链: 22个]
│   │   ├── PH_Elem_ShapeFunc.f90        → 形函数(约600行, 30个子程序)
│   │   ├── PH_Elem_Jacobian.f90         → Jacobian(约350行, 15个子程序)
│   │   ├── PH_Elem_BMtx.f90             → B矩阵(约500行, 20个子程序)
│   │   ├── PH_Elem_IntegPts.f90         → 积分点(约400行, 15个子程序)
│   │   ├── PH_Elem_Utils.f90            → 单元工具(约400行)
│   │   ├── PH_Elem_Common_Util.f90      → 通用工具(约500行)
│   │   ├── PH_Elem_Quality.f90          → 质量检查(约1500行, 40个子程序)
│   │   ├── PH_Elem_Material_Integration.f90 → 材料集成(约200行)
│   │   ├── PH_Elem_Mtx.f90              → 矩阵操作(约550行)
│   │   ├── PH_Physics_Utils.f90         → 物理工具(约800行)
│   │   ├── PH_Elem_JacobianB_Utils.f90  → Jacobian/B工具(约700行)
│   │   ├── PH_Elem_Diff_Utils.f90       → 微分工具(约250行)
│   │   ├── PH_Elem_Comp.f90             → 单元计算(约550行)
│   │   ├── PH_Shell_NLGeom_Core.f90     → 壳非线性(约400行)
│   │   ├── PH_Elem_BC_Kernel.f90        → 边界条件(约100行)
│   │   ├── PH_Elem_Load_Kernel.f90      → 载荷核(约100行)
│   │   ├── PH_Elem_Out_Kernel.f90       → 输出核(约120行)
│   │   ├── PH_Elem_Orient_RT_Brg.f90    → 方向桥接(约20行)
│   │   ├── PH_Elem_RT_Brg.f90           → 运行桥接(约200行)
│   │   ├── PH_Elem_Dispatch_C3D8.f90    → C3D8分发(约200行)
│   │   └── PH_Elem_Dispatch_Reg.f90     → 分发注册(约200行)
│   │
│   ├── SLD3D/                           [3D实体族: 18种]
│   │   ├── PH_Elem_C3D8.f90             → C3D8(8节点线性)
│   │   ├── PH_Elem_C3D8R.f90            → C3D8R(缩减积分)
│   │   ├── PH_Elem_C3D8I.f90            → C3D8I(非协调)
│   │   ├── PH_Elem_C3D20.f90            → C3D20(20节点二次)
│   │   ├── PH_Elem_C3D20R.f90           → C3D20R(缩减积分)
│   │   ├── PH_Elem_C3D4.f90             → C3D4(4节点四面体)
│   │   ├── PH_Elem_C3D10.f90            → C3D10(10节点四面体)
│   │   ├── PH_Elem_C3D6.f90             → C3D6(6节点楔形)
│   │   ├── PH_Elem_C3D15.f90            → C3D15(15节点楔形)
│   │   └── ... (9种变体)
│   │
│   ├── SLD2D/                           [2D实体族: 16种]
│   │   ├── PH_Elem_CPE4.f90             → CPE4(平面应变)
│   │   ├── PH_Elem_CPE4R.f90            → CPE4R(缩减积分)
│   │   ├── PH_Elem_CPS4.f90             → CPS4(平面应力)
│   │   ├── PH_Elem_CPS4R.f90            → CPS4R(缩减积分)
│   │   ├── PH_Elem_CAX4.f90             → CAX4(轴对称)
│   │   ├── PH_Elem_CAX4R.f90            → CAX4R(缩减积分)
│   │   └── ... (10种)
│   │
│   ├── SLD2DT/                          [2D温度族: 13种]
│   │   ├── PH_Elem_CPE4T.f90            → CPE4T(平面应变温度)
│   │   ├── PH_Elem_CPS4T.f90            → CPS4T(平面应力温度)
│   │   ├── PH_Elem_CAX4T.f90            → CAX4T(轴对称温度)
│   │   └── ... (10种)
│   │
│   ├── SLD3DT/                          [3D温度族: 8种]
│   │   ├── PH_Elem_C3D8T.f90            → C3D8T(3D温度)
│   │   ├── PH_Elem_C3D20T.f90           → C3D20T(3D温度)
│   │   └── ... (6种)
│   │
│   ├── SHELL/                           [壳单元族: 24种]
│   │   ├── PH_Elem_S4.f90               → S4(4节点线性)
│   │   ├── PH_Elem_S4R.f90              → S4R(缩减积分)
│   │   ├── PH_Elem_S8R.f90              → S8R(8节点二次)
│   │   ├── PH_Elem_S3.f90               → S3(3节点线性)
│   │   ├── PH_Elem_S4T.f90              → S4T(温度)
│   │   ├── PH_Elem_S4P.f90              → S4P(孔隙压力)
│   │   └── ... (18种)
│   │
│   ├── BEAM/                            [梁单元族: 33种]
│   │   ├── PH_Elem_B31.f90              → B31(2节点线性)
│   │   ├── PH_Elem_B31R.f90             → B31R(缩减积分)
│   │   ├── PH_Elem_B32.f90              → B32(3节点二次)
│   │   ├── PH_Elem_B32R.f90             → B32R(缩减积分)
│   │   ├── PH_Elem_B31T.f90             → B31T(温度)
│   │   ├── PH_Elem_PIPE31.f90           → PIPE31(管道)
│   │   └── ... (27种)
│   │
│   ├── TRUSS/                           [桁架族: 6种]
│   │   ├── PH_Elem_T2D2.f90             → T2D2(2D 2节点)
│   │   ├── PH_Elem_T3D2.f90             → T3D2(3D 2节点)
│   │   └── ... (4种)
│   │
│   ├── SPRING/                          [弹簧族: 4种]
│   │   ├── PH_Elem_SPRING1.f90          → SPRING1(单节点)
│   │   ├── PH_Elem_SPRING2.f90          → SPRING2(双节点)
│   │   └── ... (2种)
│   │
│   ├── DASHPOT/                         [阻尼器族: 2种]
│   │   ├── PH_Elem_DASHPOT1.f90         → DASHPOT1(单节点)
│   │   └── PH_Elem_DASHPOT2.f90         → DASHPOT2(双节点)
│   │
│   ├── POROUS/                          [多孔/流固族: 20种]
│   │   ├── PH_Elem_C3D8P.f90            → C3D8P(孔隙压力)
│   │   ├── PH_Elem_COH3D8.f90           → COH3D8(内聚力)
│   │   └── ... (18种)
│   │
│   ├── ACOUSTIC/                        [声学族: 12种]
│   │   ├── PH_Elem_AC3D8.f90            → AC3D8(声学)
│   │   └── ... (11种)
│   │
│   ├── Thermal/                         [热传导族: 5种]
│   │   ├── PH_Elem_DC3D8.f90            → DC3D8(热传导)
│   │   └── ... (4种)
│   │
│   ├── SPECIAL/                         [特殊单元族: 12种]
│   │   ├── PH_Elem_MASS.f90             → MASS(集中质量)
│   │   ├── PH_Elem_M3D4R.f90            → M3D4R(膜)
│   │   └── ... (10种)
│   │
│   ├── INFINITE/                        [无限元族: 8种]
│   │   ├── PH_Elem_CIN3D8.f90           → CIN3D8(3D无限元)
│   │   └── ... (7种)
│   │
│   ├── MEMBRANE/                        [膜单元族: 6种]
│   │   └── ... (6种)
│   │
│   └── PIPE/                            [管道单元族: 4种]
│       └── ... (4种)
│
├── Contact/                              [接触计算: 12种接触算法]
│   ├── PH_Cont_Core.f90                 → 接触计算核心
│   ├── PH_Cont_API.f90                  → 接触API
│   ├── PH_Cont_Types.f90                → 类型定义 (合并)
│   ├── PH_Cont_Solver.f90               → 接触求解
│   ├── PH_Cont_Pair.f90                 → 接触对
│   ├── PH_Cont_Integrator.f90           → 接触积分
│   ├── PH_Cont_Mgr.f90                  → 接触管理
│   ├── PH_Cont_Registry.f90             → 接触注册表
│   ├── PH_Cont_Sync.f90                 → 同步
│   │
│   ├── Normal/                          [法向接触子域]
│   │   ├── PH_Cont_Normal_Penalty.f90   → 罚函数法
│   │   ├── PH_Cont_Normal_Lagrange.f90  → 拉格朗日乘子
│   │   └── PH_Cont_Normal_AugLag.f90    → 增广拉格朗日
│   │
│   └── Friction/                        [摩擦子域]
│       ├── PH_Cont_Friction_Coulomb.f90 → Coulomb摩擦
│       ├── PH_Cont_Friction_Rough.f90   → 粗糙摩擦
│       ├── PH_Cont_Friction_Plasticity.f90→ 摩擦塑性
│       └── PH_Cont_Friction_Thermal.f90 → 热摩擦
│
├── LoadBC/                               [载荷与边界: 28种载荷/BC]
│   ├── PH_LoadBC_Core.f90               → 载荷BC核心
│   ├── PH_LoadBC_API.f90                → 载荷BCAPI
│   ├── PH_LoadBC_Types.f90              → 类型定义 (合并)
│   ├── PH_LoadBC_Registry.f90           → 载荷BC注册表
│   ├── PH_LoadBC_Sync.f90               → 同步
│   │
│   ├── Load/                            [载荷子域]
│   │   ├── PH_Load_Conc.f90             → 集中载荷
│   │   ├── PH_Load_Dist.f90             → 分布载荷
│   │   ├── PH_Load_Pressure.f90         → 压力载荷
│   │   ├── PH_Load_Gravity.f90          → 重力载荷
│   │   ├── PH_Load_Centrifugal.f90      → 离心载荷
│   │   ├── PH_Load_Thermal.f90          → 热载荷
│   │   └── PH_Load_BodyForce.f90        → 体力
│   │
│   └── BC/                              [边界条件子域]
│       ├── PH_BC_Fixed.f90              → 固定约束
│       ├── PH_BC_Displacement.f90       → 位移约束
│       ├── PH_BC_Velocity.f90           → 速度约束
│       ├── PH_BC_Acceleration.f90       → 加速度约束
│       ├── PH_BC_Temperature.f90        → 温度约束
│       ├── PH_BC_Symmetry.f90           → 对称约束
│       ├── PH_BC_Encastre.f90           → 完全固定
│       └── PH_BC_Coupling.f90           → 耦合约束
│
├── Constraint/                           [约束: 15种约束类型]
│   ├── PH_Const_Core.f90                → 约束核心
│   ├── PH_Const_API.f90                 → 约束API
│   ├── PH_Const_Types.f90               → 类型定义 (合并)
│   ├── PH_Const_Engine.f90              → 约束引擎
│   ├── PH_Const_Mgr.f90                 → 约束管理
│   ├── PH_Const_Sync.f90                → 同步
│   │
│   ├── MPC/                             [MPC子域]
│   │   └── PH_Const_MPC.f90             → MPC约束
│   │
│   ├── Tie/                             [Tie子域]
│   │   └── PH_Const_Tie.f90             → Tie约束
│   │
│   ├── Coupling/                        [耦合子域]
│   │   ├── PH_Const_Coupling.f90        → 耦合约束
│   │   └── PH_Const_Distrib.f90         → 分布耦合
│   │
│   ├── Equation/                        [方程子域]
│   │   └── PH_Const_Equation.f90        → 方程约束
│   │
│   └── Special/                         [特殊约束子域]
│       ├── PH_Const_Kinematic.f90       → 运动学约束
│       ├── PH_Const_ShellToSolid.f90    → 壳-实体耦合
│       ├── PH_Const_BeamToSolid.f90     → 梁-实体耦合
│       ├── PH_Const_Rigid.f90           → 刚体约束
│       └── PH_Const_Display.f90         → 显示约束
│
├── Output/                               [输出计算]
│   ├── PH_Out_Core.f90                  → 输出核心
│   ├── PH_Out_API.f90                   → 输出API
│   ├── PH_Out_Types.f90                 → 类型定义 (合并)
│   ├── PH_Out_Solver.f90                → 输出求解
│   ├── PH_Out_Sync.f90                  → 输出同步
│   ├── PH_Out_VTK_Export.f90            → VTK导出
│   └── PH_Out_Vis.f90                   → 可视化
│
├── Field/                                [场计算]
│   ├── PH_Field_Ops.f90                → 场计算核心
│   ├── PH_Field_Ops.f90                 → 场计算API
│   ├── PH_Field_Def.f90               → 类型定义 (合并)
│   └── PH_UniFld_Core.f90               → 统一场核心
│
├── Bridge/                               [桥接层]
│   ├── PH_Bridge_L5.f90                 → PH→L5 桥接
│   ├── PH_Bridge_L3.f90                 → PH→L3 桥接
│   └── PH_Mat_L3_Brg.f90                → 材料桥接 (重命名)
│
├── WriteBack/                            [回写]
│   ├── PH_WB_Core.f90                   → 回写核心
│   ├── PH_WB_API.f90                    → 回写API
│   └── PH_Mat_WriteBack.f90             → 材料回写
│
├── L4_PH_LayerContainer_Core.f90        → L4层容器
└── L4_PH_LayerContainer_State.f90       → L4层容器状态
```

**L4_PH 统计**: 9 域 | 14 子域 | 450+ 文件 | TYPE策略: **统一合并 `_Types.f90`（按需 USE）**
├── Material/                             [⭐ 核心域: 11大族54种材料]
│   ├── PH_Mat_Core.f90                  → 材料计算核心
│   ├── PH_Mat_API.f90                   → 材料API
│   ├── PH_Mat_Utils.f90                 → 材料工具
│   ├── PH_Mat_HashTable.f90             → 材料哈希表
│   ├── PH_Mat_L2_LayerContainer_Brg.f90 → L2桥接
│   ├── PH_Mat_Dispatch.f90              → 材料分发器
│   ├── PH_Mat_Registry.f90              → 材料注册表
│   │
│   ├── Elastic/                         [1️⃣ 弹性族: 6种]
│   │   ├── PH_Mat_Elas_Core.f90         → 弹性核心
│   │   ├── PH_Mat_Elas_API.f90          → 弹性API
│   │   ├── PH_Mat_Elas_Iso.f90          → 各向同性弹性
│   │   ├── PH_Mat_Elas_Ortho.f90        → 正交弹性
│   │   ├── PH_Mat_Elas_Cubic.f90        → 立方对称弹性
│   │   ├── PH_Mat_Elas_Anisotropic.f90  → 各向异性弹性
│   │   ├── PH_Mat_Elas_AxiIsotropic.f90 → 轴对称各向同性
│   │   ├── PH_Mat_Elas_TransIso.f90     → 横观各向同性
│   │   ├── PH_Mat_Elas_Engine.f90       → 弹性引擎
│   │   └── PH_Mat_Elas_Types.f90        → 弹性类型
│   │
│   ├── Plastic/                         [2️⃣ 塑性族: 6种]
│   │   ├── PH_Mat_Plast_Core.f90        → 塑性核心
│   │   ├── PH_Mat_Plast_API.f90         → 塑性API
│   │   ├── PH_Mat_Plast_Types.f90       → 塑性类型 (合并)
│   │   ├── PH_Mat_Plast_J2Iso.f90       → J2等向强化
│   │   ├── PH_Mat_Plast_J2Kin.f90       → J2随动强化
│   │   ├── PH_Mat_Plast_J2Mix.f90       → J2混合强化
│   │   ├── PH_Mat_Plast_Hill.f90        → Hill'48
│   │   ├── PH_Mat_Plast_Barlat.f90      → Barlat Yld2000
│   │   ├── PH_Mat_Plast_Chaboche.f90    → Chaboche随动硬化
│   │   ├── PH_Mat_Plast_Crystal.f90     → 晶体塑性
│   │   ├── PH_Mat_Plast_Engine.f90      → 塑性引擎
│   │   └── PH_Mat_Plast_Types.f90       → 塑性类型
│   │                                         【废弃: PH_Mat_Plast_DruckerPrager.f90 → 已迁移至Geo/】
│   │                                         【废弃: PH_Mat_Plast_MohrCoulomb.f90 → 已迁移至Geo/】
│   │                                         【废弃: PH_Mat_Plast_Castani.f90 → 已迁移至Composite/】
│   │                                         【废弃: PH_Mat_Plast_Gurson.f90 → 已迁移至Damage/】
│   │
│   ├── HyperElastic/                    [3️⃣ 超弹性族: 8种]
│   │   ├── PH_Mat_Hyper_Core.f90        → 超弹性核心
│   │   ├── PH_Mat_Hyper_API.f90         → 超弹性API
│   │   ├── PH_Mat_Hyper_NeoHookean.f90  → Neo-Hookean
│   │   ├── PH_Mat_Hyper_MooneyRivlin.f90→ Mooney-Rivlin (2/3/5参)
│   │   ├── PH_Mat_Hyper_Ogden.f90       → Ogden (1-3阶)
│   │   ├── PH_Mat_Hyper_Yeoh.f90        → Yeoh (1-3阶)
│   │   ├── PH_Mat_Hyper_Polynomial.f90  → 多项式 (N=1-6)
│   │   ├── PH_Mat_Hyper_ReducedPoly.f90 → 缩减多项式
│   │   ├── PH_Mat_Hyper_VanDerWaals.f90 → Van der Waals
│   │   ├── PH_Mat_Hyper_ArrudaBoyce.f90 → Arruda-Boyce
│   │   ├── PH_Mat_Hyper_Gent.f90        → Gent
│   │   ├── PH_Mat_Hyper_Ogden_Foam.f90  → Ogden Foam
│   │   ├── PH_Mat_Hyper_Marlow.f90      → Marlow
│   │   └── PH_Mat_Hyper_Types.f90       → 超弹性类型
│   │
│   ├── Viscoelastic/                    [4️⃣ 粘弹性族: 3种]
│   │   ├── PH_Mat_Visco_Core.f90        → 粘弹性核心
│   │   ├── PH_Mat_Visco_API.f90         → 粘弹性API
│   │   ├── PH_Mat_Visco_Linear.f90      → 线性粘弹性
│   │   ├── PH_Mat_Visco_Prony.f90       → Prony级数
│   │   ├── PH_Mat_Visco_GenMaxwell.f90  → 广义Maxwell
│   │   └── PH_Mat_Visco_Types.f90       → 粘弹性类型
│   │
│   ├── Creep/                           [5️⃣ 蠕变族: 5种]
│   │   ├── PH_Mat_Creep_Core.f90        → 蠕变核心
│   │   ├── PH_Mat_Creep_API.f90         → 蠕变API
│   │   ├── PH_Mat_Creep_PowerLaw.f90    → 幂律蠕变
│   │   ├── PH_Mat_Creep_Norton.f90      → Norton
│   │   ├── PH_Mat_Creep_Murray.f90      → Murray
│   │   ├── PH_Mat_Creep_TimeHard.f90    → 时间硬化
│   │   ├── PH_Mat_Creep_StrainHard.f90  → 应变硬化
│   │   └── PH_Mat_Creep_Types.f90       → 蠕变类型
│   │
│   ├── Damage/                          [6️⃣ 损伤族: 6种]
│   │   ├── PH_Mat_Damage_Core.f90       → 损伤核心
│   │   ├── PH_Mat_Damage_API.f90        → 损伤API
│   │   ├── PH_Mat_Damage_Ductile.f90    → 延性损伤
│   │   ├── PH_Mat_Damage_Shear.f90      → 剪切损伤
│   │   ├── PH_Mat_Damage_MK.f90         → MK损伤
│   │   ├── PH_Mat_Damage_JohnsonCook.f90→ Johnson-Cook
│   │   ├── PH_Mat_Damage_XFEM.f90       → XFEM损伤
│   │   ├── PH_Mat_Damage_Gurson.f90     → Gurson-Tvergaard (从Plast迁入)
│   │   └── PH_Mat_Damage_Types.f90      → 损伤类型
│   │
│   ├── Geo/                             [7️⃣ 地质材料族: 6种]
│   │   ├── PH_Mat_Geo_Core.f90          → 地质核心
│   │   ├── PH_Mat_Geo_API.f90           → 地质API
│   │   ├── PH_Mat_Geo_DruckerPrager.f90 → Drucker-Prager
│   │   ├── PH_Mat_Geo_MohrCoulomb.f90   → Mohr-Coulomb
│   │   ├── PH_Mat_Geo_CamClay.f90       → 剑桥模型 (MCC)
│   │   ├── PH_Mat_Geo_ModCamClay.f90    → 修正剑桥
│   │   ├── PH_Mat_Geo_BartonBandis.f90  → Barton-Bandis
│   │   ├── PH_Mat_Geo_HoekBrown.f90     → Hoek-Brown
│   │   └── PH_Mat_Geo_Types.f90         → 地质类型
│   │
│   ├── Composite/                       [8️⃣ 复合材料族: 5种]
│   │   ├── PH_Mat_Comp_Core.f90         → 复合核心
│   │   ├── PH_Mat_Comp_API.f90          → 复合API
│   │   ├── PH_Mat_Comp_Lamina.f90       → 单层板
│   │   ├── PH_Mat_Comp_Hashin.f90       → Hashin损伤
│   │   ├── PH_Mat_Comp_Puck.f90         → Puck准则
│   │   ├── PH_Mat_Comp_LaRC.f90         → LaRC准则
│   │   ├── PH_Mat_Comp_Castani.f90      → Castani (从Plast迁入)
│   │   └── PH_Mat_Comp_Types.f90        → 复合类型
│   │
│   ├── Thermal/                         [9️⃣ 热材料族: 3种]
│   │   ├── PH_Mat_Therm_Core.f90        → 热核心
│   │   ├── PH_Mat_Therm_API.f90         → 热API
│   │   ├── PH_Mat_Therm_Conduction.f90  → 热传导
│   │   ├── PH_Mat_Therm_Expansion.f90   → 热膨胀
│   │   ├── PH_Mat_Therm_Coupled.f90     → 热-力耦合
│   │   └── PH_Mat_Therm_Types.f90       → 热类型
│   │
│   ├── User/                            [🔟 用户材料族: 3种]
│   │   ├── PH_Mat_User_Core.f90         → UMAT核心
│   │   ├── PH_Mat_User_API.f90          → UMAT API
│   │   ├── PH_Mat_User_UMAT.f90         → UMAT接口
│   │   ├── PH_Mat_User_VUMAT.f90        → VUMAT接口
│   │   ├── PH_Mat_User_HETVAL.f90       → HETVAL热生成
│   │   └── PH_Mat_User_Types.f90        → 用户类型
│   │
│   └── Cohesive/                        [1️⃣1️⃣ 内聚力族: 3种]
│       ├── PH_Mat_Cohes_Core.f90        → 内聚力核心
│       ├── PH_Mat_Cohes_API.f90         → 内聚力API
│       ├── PH_Mat_Cohes_TractionSep.f90 → 牵引-分离
│       ├── PH_Mat_Cohes_BK.f90          → BK混合模式
│       ├── PH_Mat_Cohes_PowerLaw.f90    → 幂律混合模式
│       └── PH_Mat_Cohes_Types.f90       → 内聚力类型
│
├── Element/                              [⭐ 核心域: 12大族245种单元(含变体377)]
│   ├── PH_Elem_Core.f90                 → 单元计算核心
│   ├── PH_Elem_API.f90                  → 单元API
│   ├── PH_Elem_Utils.f90                → 单元工具
│   ├── PH_Elem_Types.f90                → 单元类型
│   ├── PH_Elem_HashTable.f90            → 单元哈希表
│   ├── PH_Elem_Domain.f90               → 单元域
│   ├── PH_Elem_L2_LayerContainer_Brg.f90→ L2桥接
│   ├── PH_Elem_Dispatch.f90             → 单元分发器
│   ├── PH_Elem_Registry.f90             → 单元注册表
│   │
│   ├── Solid3D/                         [1️⃣ 3D实体族: 18种]
│   │   ├── PH_Elem_C3D8.f90             → C3D8 (8节点线性)
│   │   ├── PH_Elem_C3D8R.f90            → C3D8R (缩减积分)
│   │   ├── PH_Elem_C3D8I.f90            → C3D8I (非协调模式)
│   │   ├── PH_Elem_C3D8RH.f90           → C3D8RH (杂交)
│   │   ├── PH_Elem_C3D20.f90            → C3D20 (20节点二次)
│   │   ├── PH_Elem_C3D20R.f90           → C3D20R (缩减积分)
│   │   ├── PH_Elem_C3D4.f90             → C3D4 (4节点四面体)
│   │   ├── PH_Elem_C3D10.f90            → C3D10 (10节点四面体)
│   │   ├── PH_Elem_C3D10M.f90           → C3D10M (修正)
│   │   ├── PH_Elem_C3D6.f90             → C3D6 (6节点楔形)
│   │   ├── PH_Elem_C3D15.f90            → C3D15 (15节点楔形)
│   │   ├── PH_Elem_C3D8T.f90            → C3D8T (温度)
│   │   ├── PH_Elem_C3D20T.f90           → C3D20T (温度)
│   │   ├── PH_Elem_C3D8P.f90            → C3D8P (孔隙压力)
│   │   ├── PH_Elem_C3D20P.f90           → C3D20P (孔隙压力)
│   │   ├── PH_Elem_C3D8E.f90            → C3D8E (压电)
│   │   ├── PH_Elem_C3D20E.f90           → C3D20E (压电)
│   │   └── PH_Elem_Solid3D_Types.f90    → 3D实体类型
│   │
│   ├── Shell/                           [2️⃣ 壳单元族: 24种]
│   │   ├── PH_Elem_S3.f90               → S3 (3节点线性)
│   │   ├── PH_Elem_S4.f90               → S4 (4节点线性)
│   │   ├── PH_Elem_S4R.f90              → S4R (缩减积分)
│   │   ├── PH_Elem_S4R5.f90             → S4R5 (5自由度)
│   │   ├── PH_Elem_S8R.f90              → S8R (8节点二次)
│   │   ├── PH_Elem_S8R5.f90             → S8R5 (5自由度)
│   │   ├── PH_Elem_S9R5.f90             → S9R5 (9节点)
│   │   ├── PH_Elem_STRI3.f90            → STRI3 (3节点薄膜)
│   │   ├── PH_Elem_STRI65.f90           → STRI65 (6节点)
│   │   ├── PH_Elem_S3R.f90              → S3R (3节点缩减)
│   │   ├── PH_Elem_S4RS.f90             → S4RS (小应变)
│   │   ├── PH_Elem_S4RSW.f90            → S4RSW (大应变)
│   │   ├── PH_Elem_S3T.f90              → S3T (温度)
│   │   ├── PH_Elem_S4T.f90              → S4T (温度)
│   │   ├── PH_Elem_S8RT.f90             → S8RT (温度)
│   │   ├── PH_Elem_S3P.f90              → S3P (孔隙压力)
│   │   ├── PH_Elem_S4P.f90              → S4P (孔隙压力)
│   │   ├── PH_Elem_S8RP.f90             → S8RP (孔隙压力)
│   │   ├── PH_Elem_S3E.f90              → S3E (压电)
│   │   ├── PH_Elem_S4E.f90              → S4E (压电)
│   │   ├── PH_Elem_S8RE.f90             → S8RE (压电)
│   │   ├── PH_Elem_SC8R.f90             → SC8R (连续壳)
│   │   ├── PH_Elem_M3D3.f90             → M3D3 (膜)
│   │   ├── PH_Elem_M3D4R.f90            → M3D4R (膜)
│   │   └── PH_Elem_Shell_Types.f90      → 壳类型
│   │
│   ├── Beam/                            [3️⃣ 梁单元族: 16种]
│   │   ├── PH_Elem_B31.f90              → B31 (2节点线性)
│   │   ├── PH_Elem_B31R.f90             → B31R (缩减积分)
│   │   ├── PH_Elem_B32.f90              → B32 (3节点二次)
│   │   ├── PH_Elem_B32R.f90             → B32R (缩减积分)
│   │   ├── PH_Elem_B33.f90              → B33 (3节点三次)
│   │   ├── PH_Elem_B31OS.f90            → B31OS (开口截面)
│   │   ├── PH_Elem_B32OS.f90            → B32OS (开口截面)
│   │   ├── PH_Elem_B31T.f90             → B31T (温度)
│   │   ├── PH_Elem_B32T.f90             → B32T (温度)
│   │   ├── PH_Elem_B31P.f90             → B31P (孔隙压力)
│   │   ├── PH_Elem_B32P.f90             → B32P (孔隙压力)
│   │   ├── PH_Elem_PIPE31.f90           → PIPE31 (管道)
│   │   ├── PH_Elem_PIPE32.f90           → PIPE32 (管道)
│   │   ├── PH_Elem_B31H.f90             → B31H (杂交)
│   │   ├── PH_Elem_B32H.f90             → B32H (杂交)
│   │   └── PH_Elem_Beam_Types.f90       → 梁类型
│   │
│   ├── Truss/                           [4️⃣ 桁架族: 6种]
│   │   ├── PH_Elem_T2D2.f90             → T2D2 (2D 2节点)
│   │   ├── PH_Elem_T2D3.f90             → T2D3 (2D 3节点)
│   │   ├── PH_Elem_T3D2.f90             → T3D2 (3D 2节点)
│   │   ├── PH_Elem_T3D3.f90             → T3D3 (3D 3节点)
│   │   ├── PH_Elem_T2D2H.f90            → T2D2H (杂交)
│   │   └── PH_Elem_Truss_Types.f90      → 桁架类型
│   │
│   ├── Solid2D/                         [5️⃣ 2D实体族: 18种]
│   │   ├── PH_Elem_CPE3.f90             → CPE3 (平面应变)
│   │   ├── PH_Elem_CPE4.f90             → CPE4 (平面应变)
│   │   ├── PH_Elem_CPE4R.f90            → CPE4R (缩减积分)
│   │   ├── PH_Elem_CPE6M.f90            → CPE6M (修正)
│   │   ├── PH_Elem_CPS3.f90             → CPS3 (平面应力)
│   │   ├── PH_Elem_CPS4.f90             → CPS4 (平面应力)
│   │   ├── PH_Elem_CPS4R.f90            → CPS4R (缩减积分)
│   │   ├── PH_Elem_CPS6M.f90            → CPS6M (修正)
│   │   ├── PH_Elem_CAX3.f90             → CAX3 (轴对称)
│   │   ├── PH_Elem_CAX4.f90             → CAX4 (轴对称)
│   │   ├── PH_Elem_CAX4R.f90            → CAX4R (缩减积分)
│   │   ├── PH_Elem_CAX6M.f90            → CAX6M (修正)
│   │   ├── PH_Elem_CPE3T.f90            → CPE3T (温度)
│   │   ├── PH_Elem_CPE4T.f90            → CPE4T (温度)
│   │   ├── PH_Elem_CPS3T.f90            → CPS3T (温度)
│   │   ├── PH_Elem_CPS4T.f90            → CPS4T (温度)
│   │   ├── PH_Elem_CAX3T.f90            → CAX3T (温度)
│   │   ├── PH_Elem_CAX4T.f90            → CAX4T (温度)
│   │   └── PH_Elem_Solid2D_Types.f90    → 2D实体类型
│   │
│   ├── Infinite/                        [6️⃣ 无限元族: 8种]
│   │   ├── PH_Elem_CIN2D3.f90           → CIN2D3 (2D 3节点)
│   │   ├── PH_Elem_CIN2D4.f90           → CIN2D4 (2D 4节点)
│   │   ├── PH_Elem_CINAX3.f90           → CINAX3 (轴对称)
│   │   ├── PH_Elem_CINAX4.f90           → CINAX4 (轴对称)
│   │   ├── PH_Elem_CIN3D6.f90           → CIN3D6 (3D 6节点)
│   │   ├── PH_Elem_CIN3D8.f90           → CIN3D8 (3D 8节点)
│   │   ├── PH_Elem_CINPE4.f90           → CINPE4 (平面应变)
│   │   └── PH_Elem_Infinite_Types.f90   → 无限元类型
│   │
│   ├── Cohesive/                        [7️⃣ 内聚力单元族: 12种]
│   │   ├── PH_Elem_COH2D3.f90           → COH2D3 (2D 3节点)
│   │   ├── PH_Elem_COH2D4.f90           → COH2D4 (2D 4节点)
│   │   ├── PH_Elem_COHAX3.f90           → COHAX3 (轴对称)
│   │   ├── PH_Elem_COHAX4.f90           → COHAX4 (轴对称)
│   │   ├── PH_Elem_COH3D6.f90           → COH3D6 (3D 6节点)
│   │   ├── PH_Elem_COH3D8.f90           → COH3D8 (3D 8节点)
│   │   ├── PH_Elem_COH2D4T.f90          → COH2D4T (温度)
│   │   ├── PH_Elem_COH3D8T.f90          → COH3D8T (温度)
│   │   ├── PH_Elem_COH2D4P.f90          → COH2D4P (孔隙压力)
│   │   ├── PH_Elem_COH3D8P.f90          → COH3D8P (孔隙压力)
│   │   ├── PH_Elem_COH2D4E.f90          → COH2D4E (压电)
│   │   └── PH_Elem_Cohesive_Types.f90   → 内聚力类型
│   │
│   ├── Spring/                          [8️⃣ 弹簧族: 4种]
│   │   ├── PH_Elem_SPRING1.f90          → SPRING1 (单节点)
│   │   ├── PH_Elem_SPRING2.f90          → SPRING2 (双节点)
│   │   ├── PH_Elem_SPRINGA.f90          → SPRINGA (轴向)
│   │   └── PH_Elem_Spring_Types.f90     → 弹簧类型
│   │
│   ├── Dashpot/                         [9️⃣ 阻尼器族: 2种]
│   │   ├── PH_Elem_DASHPOT1.f90         → DASHPOT1 (单节点)
│   │   ├── PH_Elem_DASHPOT2.f90         → DASHPOT2 (双节点)
│   │   └── PH_Elem_Dashpot_Types.f90    → 阻尼器类型
│   │
│   ├── Mass/                            [🔟 质量单元族: 2种]
│   │   ├── PH_Elem_MASS.f90             → MASS (集中质量)
│   │   ├── PH_Elem_MASS2D.f90           → MASS2D (2D质量)
│   │   └── PH_Elem_Mass_Types.f90       → 质量类型
│   │
│   ├── Gasket/                          [1️⃣1️⃣ 垫片族: 6种]
│   │   ├── PH_Elem_GS6.f90              → GS6 (6节点)
│   │   ├── PH_Elem_GS8.f90              → GS8 (8节点)
│   │   ├── PH_Elem_GS6T.f90             → GS6T (温度)
│   │   ├── PH_Elem_GS8T.f90             → GS8T (温度)
│   │   ├── PH_Elem_GK6.f90              → GK6 (轴对称)
│   │   └── PH_Elem_Gasket_Types.f90     → 垫片类型
│   │
│   ├── Surface/                         [1️⃣2️⃣ 表面效应族: 8种]
│   │   ├── PH_Elem_SF2D3.f90            → SF2D3 (2D 3节点)
│   │   ├── PH_Elem_SF2D4.f90            → SF2D4 (2D 4节点)
│   │   ├── PH_Elem_SF3D3.f90            → SF3D3 (3D 3节点)
│   │   ├── PH_Elem_SF3D4.f90            → SF3D4 (3D 4节点)
│   │   ├── PH_Elem_SF3D6.f90            → SF3D6 (3D 6节点)
│   │   ├── PH_Elem_SF3D8.f90            → SF3D8 (3D 8节点)
│   │   ├── PH_Elem_SFM3D3.f90           → SFM3D3 (膜)
│   │   └── PH_Elem_Surface_Types.f90    → 表面类型
│   │
│   └── PH_Elem_Explicit/                [显式单元: 32种]
│       ├── PH_Elem_C3D8R_Explicit.f90   → C3D8R显式
│       ├── PH_Elem_C3D10M_Explicit.f90  → C3D10M显式
│       ├── PH_Elem_S4R_Explicit.f90     → S4R显式
│       ├── PH_Elem_B31_Explicit.f90     → B31显式
│       └── ... (28 files)               → 其他显式单元
│
├── Contact/                              [接触计算域: 12种接触算法 - L4_PH层接触力学核热路径]
│   │
│   │   【设计意图】
│   │   Contact域作为L4_PH层的"接触力学核",承担7个核心职责:
│   │   ① 接触检测(Detect): 给定几何与拓扑上下文,计算间隙gap/穿透penetration/法向n
│   │   ② 接触力计算: 法向压力pNormal/切向牵引pTangent/罚函数/增广Lagrange/局部残差与切线
│   │   ③ 摩擦计算: Coulomb摩擦/粗糙摩擦/摩擦塑性/热摩擦/指数摩擦/速度依赖摩擦
│   │   ④ 接触搜索(Search): 空间哈希/BVH树/Octree/边界框/连续接触检测CCD
│   │   ⑤ 约束施加: 罚函数法/拉格朗日乘子/增广拉格朗日法的接触约束施加
│   │   ⑥ 热接触: 接触热传导/热摩擦/温度效应计算
│   │   ⑦ 动力接触: 冲击响应/动态接触/磨损计算
│   │
│   │   【功能范围】
│   │   • 法向非穿透: g_N≥0, p_N≥0, g_N·p_N=0 (KKT条件)
│   │   • 摩擦模型: Coulomb‖t_T‖≤μ·p_N, stick/slip状态判定
│   │   • 罚函数: p_N≈ε_N·⟨-g_N⟩_+ (罚刚度ε_N)
│   │   • 增广Lagrange: L_ρ(u,λ)=Π(u)+λ^T·g(u)+ρ/2·‖max(0,g(u)+λ/ρ)‖^2
│   │   • 间隙计算: g=(x_slave-x_master)·n (slave→master投影)
│   │   • 接触搜索: BVH树构建/查询,空间哈希,Octree,边界框AABB
│   │   • 连续接触: CCD(Continuous Collision Detection)穿透检测
│   │   • 热接触: q=h·(T_slave-T_master) (接触热导率h)
│   │   • 动力接触: 冲击响应F=m·a, 阻尼F_damp=c·v
│   │   • 大变形接触: 有限滑动finiteSliding/法向更新/切向追踪
│   │   • 热路径: 是(NR迭代/显式动力学的接触循环)
│   │
│   │   【核心f90文件】
│   │   核心容器(3个)
│   │   ① PH_Cont_Domain.f90 (约800行) - 接触域容器(Domain金线)
│   │   ② PH_Cont_Core.f90 (约2200行) - 接触算法核心
│   │   ③ PH_Cont_API.f90 (约600行) - 统一API门面
│   │
│   │   上下文与类型(2个)
│   │   ④ PH_Cont_Ctx.f90 (约700行) - 接触上下文(PH_ContactCtx)
│   │   ⑤ PH_Cont_Types.f90 (约400行) - 接触类型定义(In/Out结构化参数)
│   │
│   │   搜索算法(5个)
│   │   ⑥ PH_Cont_Search.f90 (约200行) - 接触搜索主入口
│   │   ⑦ PH_Cont_Search_Advanced.f90 (约1200行) - 高级搜索算法
│   │   ⑧ PH_Cont_BVH_Builder.f90 (约350行) - BVH树构建
│   │   ⑨ PH_Cont_BVH_Query.f90 (约400行) - BVH树查询
│   │   ⑩ PH_Cont_CCD.f90 (约380行) - 连续接触检测
│   │
│   │   摩擦算法(1个)
│   │   ⑪ PH_Cont_Friction.f90 (约380行) - 摩擦计算核心
│   │
│   │   辅助模块(5个)
│   │   ⑫ PH_Cont_CSR.f90 (约600行) - 接触CSR稀疏矩阵
│   │   ⑬ PH_Cont_Search_Core.f90 (已合并至Core) - 搜索核心
│   │   ⑭ PH_Cont_Friction_Core.f90 (已合并至Core) - 摩擦核心
│   │   ⑮ PH_Cont_Constr_Core.f90 (已合并至Core) - 约束核心
│   │   ⑯ PH_Cont_LargeDef_Core.f90 (已合并至Core) - 大变形核心
│   │
│   │   子目录模块(按功能分组)
│   │   • AI/ (1个) - 智能接触算法(机器学习辅助)
│   │   • Explicit/ (1个) - 显式接触算法
│   │   • Self/ (1个) - 自接触算法
│   │   • Thermal/ (2个) - 热接触算法
│   │   • Wear/ (1个) - 磨损计算
│   │
│   │   【子程序详细清单】
│   │
│   │   **PH_Cont_Domain.f90** (约800行)
│   │   ├─ TYPE PH_Contact_Domain
│   │   │    字段: pairs(:)/n_pairs/params/initialized/step_idx/incr_idx
│   │   │    ├─ Init(this, max_pairs, status)
│   │   │    │    功能: 初始化接触域(PH_CONT_DEFAULT_MAX_SLAVE/MAX_MASTER=1024)
│   │   │    ├─ Finalize(this)
│   │   │    │    功能: Finalize接触域
│   │   │    ├─ RegisterContactPair(this, pair_id, master_surf, slave_surf, status)
│   │   │    │    功能: 注册接触对(master/slave面名→surf_id)
│   │   │    ├─ Detect(this, pair_id, coords_slave, coords_master, status)
│   │   │    │    功能: 热路径-接触检测(gap/penetration/normal)
│   │   │    ├─ ComputeForce(this, pair_id, force_out, tangent_out, status)
│   │   │    │    功能: 热路径-接触力计算(罚/AL/Lagrange)
│   │   │    ├─ UpdateState(this, pair_id, status)
│   │   │    │    功能: 更新接触状态(converged→stateVars_n→stateVars)
│   │   │    └─ GetSummary(this, summary, status)
│   │   │         功能: 诊断信息
│   │   ├─ PH_Cont_Detect_Arg
│   │   │    字段: pair_id/slave_nodes(:)/master_nodes(:)/coords_slave(:,:)/coords_master(:,:)/gap/normal/status
│   │   ├─ PH_Cont_ComputeForce_Arg
│   │   │    字段: pair_id/force_out(:,:)/tangent_out(:,:)/contact_stiffness(:,:,:)/status
│   │   └─ PH_CONT_* / PH_CSTAT_* / PH_FRIC_* 枚举
│   │        PH_CONT_PENALTY=1/PH_CONT_LAGRANGE=2/PH_CONT_AUG_LAGRANGE=3
│   │        PH_CSTAT_OPEN=0/PH_CSTAT_CLOSED=1/PH_CSTAT_STICK=2/PH_CSTAT_SLIP=3
│   │        PH_FRIC_COULOMB=1/PH_FRIC_ROUGH=2/PH_FRIC_PLASTIC=3/PH_FRIC_THERMAL=4
│   │
│   │   **PH_Cont_Core.f90** (约2200行)
│   │   ├─ PH_Cont_AlgorithmFramework(In, Out)
│   │   │    功能: 接触算法框架(总控流程)
│   │   ├─ PH_Cont_ConvergenceCheck(In, Out)
│   │   │    功能: 接触收敛性检查
│   │   ├─ PH_Cont_SearchPairs(In, Out)
│   │   │    功能: 接触对搜索(活动集识别)
│   │   ├─ PH_Cont_DetectPenetration(In, Out)
│   │   │    功能: 穿透检测(TP-8反模式:热路径内禁止ALLOCATE)
│   │   ├─ PH_Cont_CalculateGap(In, Out)
│   │   │    功能: 间隙计算g=(x_slave-x_master)·n
│   │   ├─ PH_Cont_ApplyConstraints(In, Out)
│   │   │    功能: 约束施加(罚/AL/Lagrange)
│   │   ├─ PH_Cont_UpdateFriction(In, Out)
│   │   │    功能: 摩擦状态更新(stick/slip)
│   │   ├─ PH_Cont_PenaltyForce(In, Out)
│   │   │    功能: 罚函数力F_n=ε·max(0,-g)·n
│   │   ├─ PH_Cont_PenaltyStiffness(In, Out)
│   │   │    功能: 罚刚度矩阵计算
│   │   ├─ PH_Cont_LagrangeForce(In, Out)
│   │   │    功能: 拉格朗日乘子力
│   │   ├─ PH_Cont_AugLagForce(In, Out)
│   │   │    功能: 增广Lagrange力
│   │   ├─ PH_Cont_AugLagUpdate(In, Out)
│   │   │    功能: 增广Lagrange乘子更新λ←λ+ρ·g
│   │   ├─ PH_Cont_ComputeGap(In, Out)
│   │   │    功能: 计算间隙
│   │   ├─ PH_Cont_ComputeNormal(In, Out)
│   │   │    功能: 计算法向向量
│   │   ├─ PH_Cont_CheckState(In, Out)
│   │   │    功能: 检查接触状态(open/closed/stick/slip)
│   │   ├─ PH_Cont_FindNearestPoint(In, Out)
│   │   │    功能: 寻找slave→master最近投影点
│   │   ├─ PH_Cont_ComputePenetration(In, Out)
│   │   │    功能: 计算穿透深度
│   │   ├─ PH_Cont_CoulombFriction(In, Out)
│   │   │    功能: Coulomb摩擦‖τ‖≤μ·p_N
│   │   ├─ PH_Cont_StickSlip(In, Out)
│   │   │    功能: stick/slip状态判定
│   │   ├─ PH_Cont_ComputeSlip(In, Out)
│   │   │    功能: 计算滑移量
│   │   ├─ PH_Cont_FrictionStiffness(In, Out)
│   │   │    功能: 摩擦切线刚度
│   │   ├─ PH_Cont_ExponentialFriction(In, Out)
│   │   │    功能: 指数摩擦模型
│   │   ├─ PH_Cont_PressureDependentFriction(In, Out)
│   │   │    功能: 压力依赖摩擦
│   │   ├─ PH_Cont_VelocityDependentFriction(In, Out)
│   │   │    功能: 速度依赖摩擦
│   │   ├─ PH_Cont_ComputeTangentVectors(In, Out)
│   │   │    功能: 计算切向向量
│   │   ├─ PH_Cont_ComputeContactForces(In, Out)
│   │   │    功能: 计算接触力(法向+切向)
│   │   ├─ PH_Cont_ApplyImpactResponse(In, Out)
│   │   │    功能: 施加冲击响应F=m·a
│   │   ├─ PH_Cont_ComputeTemperatureEffect(In, Out)
│   │   │    功能: 计算温度效应q=h·(T_s-T_m)
│   │   ├─ PH_Cont_LargeDef_State_Init(In, Out)
│   │   │    功能: 大变形状态初始化
│   │   ├─ PH_Cont_LargeDef_Update_Normal(In, Out)
│   │   │    功能: 大变形法向更新
│   │   ├─ PH_Cont_LargeDef_Update_Gap(In, Out)
│   │   │    功能: 大变形间隙更新
│   │   ├─ PH_Cont_LargeDef_Check_Sliding(In, Out)
│   │   │    功能: 大变形滑动检查
│   │   ├─ PH_Cont_LargeDef_Compute_Tangent(In, Out)
│   │   │    功能: 大变形切向计算
│   │   └─ PH_Cont_LargeDef_Track_Boundary(In, Out)
│   │        功能: 大变形边界追踪
│   │
│   │   **PH_Cont_API.f90** (约600行)
│   │   ├─ PH_Cont_SearchPairs_API(In, Out)
│   │   │    功能: API门面-校验+委托Core
│   │   ├─ PH_Cont_DetectPenetration_API(In, Out)
│   │   │    功能: API门面-穿透检测
│   │   ├─ PH_Cont_ApplyConstraints_API(In, Out)
│   │   │    功能: API门面-约束施加(与RT_Asm_ApplyContact对接)
│   │   └─ 其他API封装(约15个)
│   │        功能: 统一API入口(校验+委托Core)
│   │
│   │   **PH_Cont_Ctx.f90** (约700行)
│   │   ├─ TYPE PH_ContactCtx
│   │   │    字段: master_face_id/slave_node_ids(:)/gap/normal/projection/
│   │   │          x_slave_buf(:,:)/x_master_buf(:,:) (AP-8缓冲)
│   │   ├─ TYPE PH_Cont_Time_Desc
│   │   │    字段: step_idx/incr_idx/time/time_inc
│   │   └─ 上下文初始化/Finalize函数
│   │
│   │   **PH_Cont_Search.f90** (约200行)
│   │   ├─ PH_Cont_Search_Main(In, Out)
│   │   │    功能: 接触搜索主入口
│   │   └─ PH_Cont_Search_Opt(In, Out)
│   │        功能: 优化搜索(5参数)
│   │
│   │   **PH_Cont_Search_Advanced.f90** (约1200行)
│   │   ├─ PH_Cont_Pair_Identify(In, Out)
│   │   │    功能: 接触对识别(8参数)
│   │   ├─ PH_Cont_SpatialHash_Init(In, Out)
│   │   │    功能: 空间哈希初始化
│   │   ├─ PH_Cont_SpatialHash_Insert(In, Out)
│   │   │    功能: 空间哈希插入
│   │   ├─ PH_Cont_SpatialHash_Query(In, Out)
│   │   │    功能: 空间哈希查询
│   │   └─ 其他高级搜索函数(约20个)
│   │
│   │   **PH_Cont_BVH_Builder.f90** (约350行)
│   │   ├─ BVH_Build(In, Out)
│   │   │    功能: BVH树构建(5参数)
│   │   ├─ BVH_Build_Recursive_FromPack(In, Out)
│   │   │    功能: BVH递归构建(从数据包)
│   │   └─ BVH_Build_Desc(In, Out)
│   │        功能: BVH构建描述
│   │
│   │   **PH_Cont_BVH_Query.f90** (约400行)
│   │   ├─ BVH_Query_Collisions(In, Out)
│   │   │    功能: BVH碰撞查询(7参数)
│   │   └─ BVH查询辅助函数(约8个)
│   │
│   │   **PH_Cont_CCD.f90** (约380行)
│   │   ├─ PH_Cont_CCD_Detect(In, Out)
│   │   │    功能: 连续碰撞检测
│   │   └─ CCD辅助函数(约10个)
│   │
│   │   **PH_Cont_Friction.f90** (约380行)
│   │   ├─ PH_Cont_Friction_Core_Algo(In, Out)
│   │   │    功能: 摩擦核心算法
│   │   └─ 摩擦辅助函数(约12个)
│   │
│   │   **PH_Cont_CSR.f90** (约600行)
│   │   ├─ PH_Cont_CSR_Assemble(In, Out)
│   │   │    功能: 接触CSR稀疏矩阵组装
│   │   └─ CSR辅助函数(约15个)
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory): KKT条件(g≥0,λ≥0,λ·g=0)+罚函数/增广Lagrange+Coulomb摩擦‖τ‖≤μ·σ_N
│   │   • 逻辑链(Logic): L3 Cont Desc→Populate→RegisterContactPair→Detect→ComputeForce→L5装配
│   │   • 计算链(Computation): 搜索→活动集→gap/normal→罚/AL力→摩擦→局部残差/切线
│   │   • 数据链(Data): PH_Contact_Params/State/Ctx+PH_Cont_Detect_Arg金线参数
│   │
│   │   【热路径规范】
│   │   • 热路径零L3: 禁止Detect内对全网格做未缓存的L3遍历
│   │   • Populate后优先调用方传入坐标: 减少步内L3依赖(G4)
│   │   • AP-8缓冲: x_slave_buf/x_master_buf防热路径分配爆炸
│   │   • Init冷路径预分配: PH_CONT_DEFAULT_MAX_SLAVE/MAX_MASTER=1024
│   │   • 温路径零ALLOCATE: TP-8反模式(如PH_Cont_DetectPenetration中每接触对分配数组)
│   │   • 正确做法: Init阶段预分配缓冲区,暖路径仅执行写入操作
│   │
│   │   【跨域依赖矩阵】
│   │   • L3_MD/Contact: 提供接触对Desc/摩擦码/CONTACT_ALG_*等
│   │   • L3_MD/Interaction: pairs→RegisterContactPair
│   │   • L3_MD/Assembly: master/slave面名解析→surf_id
│   │   • L5_RT/Contact: RT_Contact_Domain_Core/RT_Cont_Search_Core编排
│   │   • L5_RT/Assembly: RT_Asm_ApplyContact装配接触贡献
│   │   • L4_PH/Element: 接触面节点坐标/形函数
│   │
│   │   【覆盖率统计】
│   │   • 核心文件: 20+个(Domain1个+Core1个+API1个+Ctx1个+Types1个+Search5个+Friction1个+CSR1个+子目录6个)
│   │   • TYPE定义: 15+个(Domain/Params/State/Ctx/Time_Desc/In/Out结构体等)
│   │   • 子程序总数: 150+个(搜索20+检测10+约束10+摩擦15+大变形10+热接触5+动力接触5+工具60+)
│   │   • 接触算法: 12种(罚函数/拉格朗日/增广Lagrange/Coulomb/粗糙/塑性/热/指数/速度依赖/压力依赖/冲击/磨损)
│   │   • 合同对齐: Contact/CONTRACT.md已验证
│   │
│   ├── PH_Cont_Domain.f90               → 接触域容器(约800行, Domain金线)
│   ├── PH_Cont_Core.f90                 → 算法核心(约2200行, 50+子程序)
│   ├── PH_Cont_API.f90                  → API门面(约600行, 15+子程序)
│   ├── PH_Cont_Ctx.f90                  → 上下文(约700行, PH_ContactCtx)
│   ├── PH_Cont_Types.f90                → 类型定义(约400行, In/Out结构体)
│   ├── PH_Cont_Search.f90               → 搜索主入口(约200行)
│   ├── PH_Cont_Search_Advanced.f90      → 高级搜索(约1200行, 20+子程序)
│   ├── PH_Cont_BVH_Builder.f90          → BVH构建(约350行, 3子程序)
│   ├── PH_Cont_BVH_Query.f90            → BVH查询(约400行, 8子程序)
│   ├── PH_Cont_CCD.f90                  → 连续碰撞(约380行, 10子程序)
│   ├── PH_Cont_Friction.f90             → 摩擦核心(约380行, 12子程序)
│   ├── PH_Cont_CSR.f90                  → CSR矩阵(约600行, 15子程序)
│   │
│   ├── Core/                            [核心算法: 4个]
│   │   ├── PH_Cont_API.f90              → API门面(22KB)
│   │   ├── PH_Cont_CSR.f90              → CSR矩阵(24KB)
│   │   ├── PH_Cont_Core.f90             → 算法核心(92KB, 50+子程序)
│   │   └── PH_Cont_Ctx.f90              → 上下文(25KB)
│   │
│   ├── Search/                          [搜索算法: 5个]
│   │   ├── PH_Cont_Search.f90           → 搜索主入口
│   │   ├── PH_Cont_Search_Advanced.f90  → 高级搜索(47KB)
│   │   ├── PH_Cont_BVH_Builder.f90      → BVH构建(13KB)
│   │   ├── PH_Cont_BVH_Query.f90        → BVH查询(16KB)
│   │   └── PH_Cont_CCD.f90              → 连续碰撞(14KB)
│   │
│   ├── Friction/                        [摩擦算法: 1个]
│   │   └── PH_Cont_Friction.f90         → 摩擦核心(14KB)
│   │
│   ├── Thermal/                         [热接触: 2个]
│   │   └── ... (2个热接触文件)
│   │
│   ├── AI/                              [智能接触: 1个]
│   │   └── ... (1个AI辅助接触文件)
│   │
│   ├── Explicit/                        [显式接触: 1个]
│   │   └── ... (1个显式接触文件)
│   │
│   ├── Self/                            [自接触: 1个]
│   │   └── ... (1个自接触文件)
│   │
│   └── Wear/                            [磨损计算: 1个]
│       └── ... (1个磨损计算文件)
│
├── LoadBC/                               [载荷与边界域: 28种载荷/BC - L4_PH层载荷与边界条件数值准备热路径]
│   │
│   │   【设计意图】
│   │   LoadBC域作为L4_PH层的"载荷与边界条件数值准备核心",承担6个核心职责:
│   │   ① 载荷组装(Load Assembly): 集中力/分布载/压力/体力/热载荷/惯性载荷→外载向量F_ext组装
│   │   ② 边界条件施加(BC Application): Dirichlet边界u=ū(t)经消元/罚函数/拉格朗日乘子法写入K/R或CSR
│   │   ③ 幅值插值(Amplitude Evaluation): 时间相关载荷A(t)的幅值因子查询与插值
│   │   ④ 压力面贡献(Pressure Surface): 面高斯积分∫N^T·t·dS(t=p·n,外法向)
│   │   ⑤ 增量控制(Increment Control): 增量开始清零F_ext/F_thermal/F_body(热路径零ALLOCATE)
│   │   ⑥ 特化算法: 地应力K0平衡(Geostatic)/稳态响应(Steady)/谐响应
│   │
│   │   【功能范围】
│   │   • 集中力: F(dof)+=f·A(t) (CLOAD)
│   │   • 分布载: ∫N^T·t·dS (DLOAD/DSLOAD)
│   │   • 压力载荷: ∫p·N^T·n·dS (外法向n,正压向内)
│   │   • 体力: ∫ρ·b·N^T·dΩ (重力/离心力)
│   │   • 热载荷: F_thermal=∫B^T·C·ε_th·dV (ε_th=α·ΔT)
│   │   • 追随力: F(u)=p·n(u)·A(u), K_T=dF/du (非线性几何)
│   │   • 螺栓预紧: BOLT_PRETENSION
│   │   • Dirichlet BC: u_i=ū_i(t) (消元/罚函数/拉格朗日)
│   │   • 罚函数: K_ii+=α_p, F_i+=α_p·ū_i (α_p=1e15~1e30)
│   │   • 拉格朗日乘子: 增广系统[K C^T; C 0]{u;λ}={F;ū}
│   │   • 消元法: 直接修改K/F(稠密/CSR两路)
│   │   • Neumann BC: 自然边界条件(面载/热流)
│   │   • 热路径: 部分为是(Assemble_Fext/压力面贡献)
│   │
│   │   【核心f90文件】
│   │   核心容器(1个)
│   │   ① PH_Ldbc_Core.f90 (约870行) - LoadBC域容器(Domain金线)
│   │
│   │   载荷算法(2个)
│   │   ② PH_Load_Core.f90 (约1250行) - 载荷组装核心
│   │   ③ PH_Load_Types.f90 (约350行) - 载荷类型定义
│   │
│   │   边界条件(3个)
│   │   ④ PH_BC_Core.f90 (约425行) - BC算法核心(罚/拉氏/消元)
│   │   ⑤ PH_BC_Types.f90 (约300行) - BC类型定义
│   │   ⑥ PH_BC_API.f90 (约320行) - BC统一API门面
│   │
│   │   特化算法(2个)
│   │   ⑦ PH_LoadBC_Steady.f90 (约200行) - 稳态/谐响应
│   │   ⑧ PH_Geostatic_Algo.f90 (约150行) - 地应力K0平衡
│   │
│   │   数据转换(2个)
│   │   ⑨ PH_Flat_To_Nested_LoadBC.f90 (约350行) - 扁平→嵌套转换
│   │   ⑩ PH_Nested_To_Flat_LoadBC.f90 (约330行) - 嵌套→扁平转换
│   │
│   │   【子程序详细清单】
│   │
│   │   **PH_Ldbc_Core.f90** (约870行)
│   │   ├─ TYPE PH_LoadBC_Ctx
│   │   │    字段: nActiveLoads/nActiveBCs/nTotalDOF/step_idx/incr_idx/
│   │   │          activeLoadIds(:)/loadTypes(:)/loadMagnitudes(:)/
│   │   │          activeBCIds(:)/bcDOFs(:)/bcValues(:)/
│   │   │          ampRefLoad(:)/ampRefBC(:)/
│   │   │          nPressureSurfaces/pressure_surf_elem_idx(:)/
│   │   │          pressure_surf_face_id(:)/pressure_surf_magnitude(:)
│   │   ├─ TYPE PH_LoadBC_State
│   │   │    字段: F_ext(:)/F_thermal(:)/F_body(:)/reaction(:)/
│   │   │          totalExtWork/maxReaction
│   │   ├─ TYPE PH_LoadBC_Params
│   │   │    字段: bcMethod(PH_BC_ELIMINATION/PENALTY/LAGRANGE)/
│   │   │          penaltyFactor(1e15)/followForce/thermalLoading
│   │   ├─ PH_BC_ELIMINATION=1/PH_BC_PENALTY=2/PH_BC_LAGRANGE=3
│   │   ├─ PH_LOAD_CONCENTRATED=1/PH_LOAD_PRESSURE=2/PH_LOAD_BODY_FORCE=3/
│   │   │  PH_LOAD_GRAVITY=4/PH_LOAD_CENTRIFUGAL=5/PH_LOAD_THERMAL=6/
│   │   │  PH_LOAD_DISTRIBUTED=7/PH_LOAD_BOLT_PRETENSION=8
│   │   ├─ TYPE PH_LoadBC_Domain
│   │   │    字段: ctx/state/params/initialized
│   │   │    ├─ Init(this, nTotalDOF, status)
│   │   │    │    功能: Step级初始化载荷BC域
│   │   │    ├─ Finalize(this)
│   │   │    │    功能: Finalize载荷BC域
│   │   │    ├─ RegisterLoad(this, loadType, dofId, magnitude, ampRef, loadId, status)
│   │   │    │    功能: 注册载荷(集中/分布/压力/体力/热)
│   │   │    ├─ RegisterBC(this, dofId, value, ampRef, bcId, status)
│   │   │    │    功能: 注册边界条件(Dirichlet)
│   │   │    ├─ RegisterPressureSurface(this, elem_idx, face_id, magnitude, status)
│   │   │    │    功能: 注册压力面(C3D8面号1..6)
│   │   │    ├─ GetSummary(this, summary, status)
│   │   │    │    功能: 摘要/诊断信息
│   │   │    ├─ IncrBegin_Reset(this, nTotalDOF, status)
│   │   │    │    功能: 热路径-增量开始清零F_ext/F_thermal/F_body(不ALLOCATE)
│   │   │    ├─ Assemble_Fext(this, status)
│   │   │    │    功能: 热路径-外载与体载/热载组装
│   │   │    ├─ Apply_DirichletBC(this, K, F, status)
│   │   │    │    功能: 稠密矩阵Dirichlet BC施加(消元/罚/拉氏)
│   │   │    ├─ Apply_DirichletBC_CSR(this, CSR_K, F, status)
│   │   │    │    功能: CSR稀疏矩阵Dirichlet BC施加
│   │   │    └─ Eval_Amplitude(this, ampRef, time, factor, status)
│   │   │         功能: 温路径-幅值因子A(t)查询(冷/温路径)
│   │   ├─ PH_LoadBC_RegisterLoad_Arg
│   │   │    字段: loadType/dofId/magnitude/ampRef/loadId(OUT)/status(OUT)
│   │   ├─ PH_LoadBC_RegisterBC_Arg
│   │   │    字段: dofId/value/ampRef/bcId(OUT)/status(OUT)
│   │   ├─ PH_LoadBC_RegisterPressureSurface_Arg
│   │   │    字段: elem_idx/face_id(1..6)/magnitude/status(OUT)
│   │   └─ PH_LoadBC_IncrBegin_Reset_Arg
│   │        字段: nTotalDOF/status(OUT)
│   │
│   │   **PH_Load_Core.f90** (约1250行)
│   │   ├─ TYPE PH_Load_Ctx
│   │   │    字段: integration_method/n_integration_points/use_consistent_load/
│   │   │          account_follower/n_loads_applied/total_load_magnitude/
│   │   │          n_concentrated_loads/n_distributed_loads/n_body_forces
│   │   │    ├─ Init(method, n_points)
│   │   │    ├─ Clear()
│   │   │    ├─ SetIntegMethod(method, n_points)
│   │   │    ├─ GetIntegMethod()
│   │   │    └─ IncrementCount(load_type, magnitude)
│   │   ├─ PH_Load_AssembleLoadVector(F_ext, ctx, status)
│   │   │    功能: 载荷向量组装总入口
│   │   ├─ PH_Load_AssembleCLoad_In/Out (集中力)
│   │   │    功能: F(dof)+=f·A(t)
│   │   ├─ PH_Load_AssembleGravity_In/Out (重力)
│   │   │    功能: F_ext+=∫ρ·g·N^T·dΩ
│   │   ├─ PH_Load_ComputeEquivForce_In/Out (等效力)
│   │   │    功能: 分布载等效力计算
│   │   ├─ PH_Load_ApplyBody_Gravity_In/Out (体力-重力)
│   │   │    功能: 重力体力施加
│   │   ├─ PH_Load_ApplyBody_Centrifugal_In/Out (体力-离心)
│   │   │    功能: 离心体力施加F=ρ·ω²·r
│   │   ├─ PH_Load_ApplyPressure_In/Out (压力)
│   │   │    功能: 压力载荷∫p·N^T·n·dS
│   │   ├─ PH_Load_ApplyDistributed_In/Out (分布载)
│   │   │    功能: 分布载荷∫N^T·t·dS
│   │   ├─ PH_Load_ApplyThermal_In/Out (热载荷)
│   │   │    功能: 热载荷F_thermal=∫B^T·C·α·ΔT·dV
│   │   ├─ PH_Load_ApplyFollower_In/Out (追随力)
│   │   │    功能: 追随力F(u)=p·n(u)·A(u)+切线K_T=dF/du
│   │   ├─ PH_Load_ApplyBoltPretension_In/Out (螺栓预紧)
│   │   │    功能: 螺栓预紧力施加
│   │   └─ 其他载荷函数(约20个)
│   │
│   │   **PH_BC_Core.f90** (约425行)
│   │   ├─ TYPE PH_BC_Ctx
│   │   │    字段: enforcement_method(BC_METHOD_PENALTY/LAGRANGE/ELIMINATION)/
│   │   │          penalty_factor(1e30)/use_reduced_integration/
│   │   │          n_bcs_applied/n_dofs_constrained/
│   │   │          constrained_dofs(:)/prescribed_values(:)
│   │   │    ├─ Init(method, penalty_factor)
│   │   │    ├─ Clear()
│   │   │    ├─ SetMethod(method, penalty_factor)
│   │   │    └─ GetMethod()
│   │   ├─ BC_METHOD_PENALTY=1/BC_METHOD_LAGRANGE=2/BC_METHOD_ELIMINATION=3
│   │   ├─ BC_METHOD_ELIMINATE=3/BC_METHOD_MASTER_SLAVE=4
│   │   ├─ BCM_Apply_Dense(K, F, bc_ctrl, bc_system, status)
│   │   │    功能: 稠密矩阵BC施加(罚/拉氏/消元)
│   │   ├─ BCM_Apply_Sparse(CSR_K, F, bc_ctrl, bc_system, status)
│   │   │    功能: CSR稀疏矩阵BC施加
│   │   ├─ BCM_Penalty_Dense(K, F, dof, value, penalty, status)
│   │   │    功能: 罚函数法稠密K_ii+=α, F_i+=α·ū
│   │   ├─ BCM_Penalty_CSR(CSR_K, F, dof, value, penalty, status)
│   │   │    功能: 罚函数法CSR
│   │   ├─ BCM_Lagrange_Dense(K_aug, F_aug, dof, value, status)
│   │   │    功能: 拉格朗日乘子法稠密增广系统
│   │   ├─ BCM_Lagrange_CSR(CSR_K, F, dof, value, status)
│   │   │    功能: 拉格朗日乘子法CSR
│   │   ├─ BCM_Elimination_Dense(K, F, dof, value, status)
│   │   │    功能: 消元法稠密直接修改K/F
│   │   └─ BCM_Elimination_CSR(CSR_K, F, dof, value, status)
│   │        功能: 消元法CSR
│   │
│   │   **PH_BC_API.f90** (约320行)
│   │   ├─ PH_BC_Apply(K, F, bc_desc, status)
│   │   │    功能: BC统一API入口(稠密/稀疏自动分发)
│   │   ├─ PH_BC_Apply_Neumann_FromDesc(F, bc_desc, status)
│   │   │    功能: Neumann BC施加(自然边界)
│   │   ├─ PH_BC_Apply_Penalty_CSR_FromDesc(CSR_K, F, bc_desc, status)
│   │   │    功能: 罚函数CSR从Desc施加
│   │   └─ 其他API封装(约10个)
│   │
│   │   **PH_Load_Types.f90** (约350行)
│   │   ├─ PH_Load_Cache_Type
│   │   │    字段: load_type/dof_id/magnitude/ampRef/face_id/elem_idx
│   │   ├─ PH_BC_Cache_Type
│   │   │    字段: bc_type/dof_id/value/ampRef/method
│   │   └─ 载荷/BC枚举定义
│   │
│   │   **PH_BC_Types.f90** (约300行)
│   │   ├─ PH_BCCtrl_Type
│   │   │    字段: n_constraints/dof_list(:)/value_list(:)/method
│   │   ├─ PH_BC_System_Type
│   │   │    字段: K(:,:)/F(:)/n_dof
│   │   ├─ PH_BC_SystemAug_Type
│   │   │    字段: K_aug(:,:)/F_aug(:)/n_dof/n_constraints
│   │   └─ BC方法枚举
│   │
│   │   **PH_Geostatic_Algo.f90** (约150行)
│   │   ├─ PH_Geostatic_Init(K, F, K0, gamma, depth, status)
│   │   │    功能: 地应力K0平衡初始化
│   │   └─ PH_Geostatic_Update(K, F, sigma_v, sigma_h, status)
│   │        功能: 地应力更新(σ_h=K0·σ_v)
│   │
│   │   **PH_LoadBC_Steady.f90** (约200行)
│   │   ├─ PH_LoadBC_Steady_Assemble(K, F, steady_loads, status)
│   │   │    功能: 稳态响应载荷组装
│   │   └─ PH_LoadBC_Harmonic_Assemble(K, F, freq, harmonic_loads, status)
│   │        功能: 谐响应载荷组装
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory): 集中力F+=f·A(t)+分布载∫N^T·t·dS+体力∫ρ·b·N^T·dΩ+Dirichlet u=ū(消元/罚/拉氏)
│   │   • 逻辑链(Logic): L3 LoadBC Desc→Populate→RegisterLoad/RegisterBC→Assemble_Fext→Apply_Dirichlet→L5装配
│   │   • 计算链(Computation): 增量清零→载荷组装→压力面贡献→BC施加→外载向量/修改K/R
│   │   • 数据链(Data): PH_LoadBC_Ctx/State/Params+PH_LoadBC_*_Arg金线参数
│   │
│   │   【热路径规范】
│   │   • 热路径零L3: 步内减少USE MD_*(G4:M0审计销项)
│   │   • Populate缓存优先: 活跃载荷/BC列表/幅值句柄/作用目标
│   │   • IncrBegin_Reset: 增量开始就地清零F_ext/F_thermal/F_body(不反复ALLOCATE)
│   │   • 压力面: elem_idx(L3单元序号1-based)/face_id(1..6 C3D8面号)
│   │   • 幅值查询: Eval_Amplitude冷/温路径(非热路径)
│   │
│   │   【跨域依赖矩阵】
│   │   • L3_MD/LoadBC: 提供载荷/BC/IC Desc真相源
│   │   • L3_MD/Amp: 幅值曲线Desc(名字/曲线)
│   │   • L3_MD/Step: 步索引/步活跃载荷/BC
│   │   • L3_MD/Mesh: nNodes/spatial_dim→n_dof_per_node/nTotalDOF
│   │   • L5_RT/LoadBC: RT_Ldbc_Apply_Core编排
│   │   • L5_RT/Assembly: RT_Asm_Ldbc_Apply/RT_Asm_Solv总装
│   │   • L4_PH/Element: 压力面elem_idx/面高斯积分
│   │
│   │   【覆盖率统计】
│   │   • 核心文件: 10个(Domain1个+Load3个+BC3个+特化2个+数据转换2个)
│   │   • TYPE定义: 12+个(Ctx/State/Params/Cache/BC_System/Arg等)
│   │   • 子程序总数: 80+个(Domain10+Load40+BC15+API10+特化5+)
│   │   • 载荷类型: 8种(集中/分布/压力/重力/离心/热/追随/螺栓预紧)
│   │   • BC方法: 3种(消元/罚函数/拉格朗日乘子)
│   │   • 合同对齐: LoadBC/CONTRACT.md已验证
│   │
│   ├── PH_Ldbc_Core.f90                   → 域容器(约870行, Domain金线10个绑定)
│   ├── PH_Load_Core.f90                   → 载荷核心(约1250行, 40+子程序)
│   ├── PH_Load_Types.f90                  → 载荷类型(约350行, Cache_Type)
│   ├── PH_BC_Core.f90                     → BC核心(约425行, 15子程序)
│   ├── PH_BC_Types.f90                    → BC类型(约300行, BC_System)
│   ├── PH_BC_API.f90                      → BC API(约320行, 10+子程序)
│   ├── PH_Geostatic_Algo.f90              → 地应力K0(约150行)
│   ├── PH_LoadBC_Steady.f90               → 稳态/谐响应(约200行)
│   ├── PH_Flat_To_Nested_LoadBC.f90       → 扁平→嵌套(约350行)
│   └── PH_Nested_To_Flat_LoadBC.f90       → 嵌套→扁平(约330行)
│
├── Constraint/                           [约束域: 15种约束类型 - L4_PH层多点约束与运动学耦合核热路径]
│   │
│   │   【设计意图】
│   │   Constraint域作为L4_PH层的"多点约束与运动学耦合核",承担6个核心职责:
│   │   ① MPC约束: 线性约束方程∑A_i·u_i=rhs的多点约束(Multi-Point Constraint)
│   │   ② 刚体约束: RBE2(刚体运动学u_slave=u_master+θ×r)/RBE3(加权分配u_ref=∑w_i·u_i)
│   │   ③ Tie约束: 面-面绑定u_slave=N(ξ_master)·u_master(表面到表面Tie)
│   │   ④ 周期边界: 周期性约束条件(配对节点与坐标变换)
│   │   ⑤ 约束施加: 消元法/变换法/拉格朗日乘子/罚函数/增广拉格朗日5种方法
│   │   ⑥ 局部贡献: 约束方程/拉格朗日乘子/罚函数贡献/局部切线刚度(不做全局CSR组装)
│   │
│   │   【功能范围】
│   │   • MPC: ∑_i A_i·u_i=rhs (线性约束方程,系数A_i/DOF索引/rhs)
│   │   • RBE2: u_slave=u_master+θ_master×r (刚体运动学,从节点=主节点+旋转×距离)
│   │   • RBE3: u_ref=∑w_i·u_i (加权平均,分配耦合,参考节点=权重平均)
│   │   • Tie: u_slave=N(ξ_master)·u_master (表面绑定,从节点=形函数插值主节点)
│   │   • 周期边界: u(x+L)=u(x) (周期性条件,配对节点与变换矩阵)
│   │   • 罚函数: ΔK∝α·C^T·C, ΔF∝α·C^T·g (α=罚刚度1e10)
│   │   • 拉格朗日: 增广系统[K C^T; C 0]{u;λ}={f;g}
│   │   • 消元法: 直接消除约束DOF(优先方法,dofMask标记独立/从属DOF)
│   │   • 变换法: K_red=T^T·K_full·T, f_red=T^T·f_full (变换矩阵T降维)
│   │   • 增广拉格朗日: L_ρ(u,λ)=Π(u)+λ^T·g(u)+ρ/2·‖max(0,g(u)+λ/ρ)‖^2
│   │   • 热路径: 是(与Element/Material同属NR循环)
│   │
│   │   【核心f90文件】
│   │   核心容器(1个)
│   │   ① PH_Constraint_Domain_Core.f90 (约1020行) - 约束域容器(Domain金线)
│   │
│   │   MPC约束(3个)
│   │   ② PH_Constr_MPC_Core.f90 (约230行) - MPC算法核心
│   │   ③ PH_Constr_MPC_API.f90 (约550行) - MPC API门面
│   │   ④ PH_Constr_MPC_Types.f90 (约120行) - MPC类型定义
│   │
│   │   Tie约束(3个)
│   │   ⑤ PH_Constr_Tie_Core.f90 (约230行) - Tie算法核心
│   │   ⑥ PH_Constr_Tie_API.f90 (约520行) - Tie API门面
│   │   ⑦ PH_Constr_Tie_Types.f90 (约130行) - Tie类型定义
│   │
│   │   周期边界(3个)
│   │   ⑧ PH_Constr_Period_Core.f90 (约220行) - 周期边界核心
│   │   ⑨ PH_Constr_Period_API.f90 (约530行) - 周期边界API
│   │   ⑩ PH_Constr_Period_Types.f90 (约100行) - 周期边界类型
│   │
│   │   上下文(1个)
│   │   ⑪ PH_Constr_Ctx.f90 (约450行) - 约束上下文
│   │
│   │   【子程序详细清单】
│   │
│   │   **PH_Constraint_Domain_Core.f90** (约1020行)
│   │   ├─ TYPE PH_Constraint_Ctx
│   │   │    字段: step_idx/incr_idx/nActiveMPC/nActiveRBE/nActiveTie/
│   │   │          activeMPCIds(:)/activeRBEIds(:)/activeTieIds(:)/
│   │   │          mpcCoeffs(:,:)/mpcDofs(:,:)/mpcRHS(:)/
│   │   │          rbeMasterNode(:)/rbeSlaveNodes(:,:)/rbeWeights(:,:)
│   │   ├─ TYPE PH_Constraint_State
│   │   │    字段: lambda_mpc(:)/lambda_tie(:)/g_mpc(:)/g_tie(:)/
│   │   │          isActive(:)/maxViolation
│   │   ├─ TYPE PH_Constraint_Params
│   │   │    字段: enforcementMethod(PH_CONS_ELIMINATION/PENALTY/LAGRANGE/AUGLAG)/
│   │   │          penaltyStiffness(1e10)/constraintTol(1e-8)/maxAugLagIter(10)
│   │   ├─ PH_CONS_ELIMINATION=0/PH_CONS_TRANSFORM=1/PH_CONS_LAGRANGE=2/
│   │   │  PH_CONS_PENALTY=3/PH_CONS_AUGLAG=4
│   │   ├─ PH_CTYPE_MPC=1/PH_CTYPE_RBE2=2/PH_CTYPE_RBE3=3/PH_CTYPE_TIE=4/
│   │   │  PH_CTYPE_COUPLING=5/PH_CTYPE_EMBEDDED=6
│   │   ├─ TYPE PH_Constraint_Domain
│   │   │    字段: ctx/state/params/initialized
│   │   │    ├─ Init(this, nTotalDOF, status)
│   │   │    │    功能: Step级初始化约束域
│   │   │    ├─ Finalize(this)
│   │   │    │    功能: Finalize约束域
│   │   │    ├─ Register(this, constraintType, constraintId, status)
│   │   │    │    功能: 注册约束(MPC/RBE/Tie)
│   │   │    ├─ AddMPCEquation(this, nTerms, coeffs(:), dofs(:), rhs, mpcId, status)
│   │   │    │    功能: 添加MPC方程∑coeffs(j)·u(dofs(j))=rhs
│   │   │    ├─ GetSummary(this, summary, status)
│   │   │    │    功能: 摘要/诊断信息
│   │   │    ├─ Assemble_KauxFaux(this, nTotalDOF, nLambda, penaltyStiff, K_aux, F_aux, status)
│   │   │    │    功能: 温路径-组装辅助刚度K_aux和力F_aux(增广系统贡献)
│   │   │    ├─ Apply_Transformation(this, nDOF_full, nDOF_reduced, T(:,:), K_full, f_full, K_red, f_red, status)
│   │   │    │    功能: 变换法K_red=T^T·K_full·T, f_red=T^T·f_full
│   │   │    ├─ BuildDofMaskFromMPC(this, nTotalDOF, dofMask(:), status)
│   │   │    │    功能: 从MPC构建dofMask(消元法,选|coeff|最大为从属DOF)
│   │   │    ├─ ExtendCSRForMPC(this, CSR_K, nLambda, status)
│   │   │    │    功能: 扩展CSR矩阵为MPC增广系统
│   │   │    ├─ Apply_Elimination_CSR(this, CSR_K, F, dofMask, status)
│   │   │    │    功能: CSR消元法直接修改K/F
│   │   │    └─ Update_Lambda(this, status)
│   │   │         功能: 更新拉格朗日乘子λ←λ+ρ·g(增广拉格朗日)
│   │   ├─ PH_Constr_Register_Arg
│   │   │    字段: constraintType/constraintId/status(OUT)
│   │   ├─ PH_Constr_AddMPCEquation_Arg
│   │   │    字段: nTerms/coeffs(:)/dofs(:)/rhs/mpcId(OUT)/status(OUT)
│   │   ├─ PH_Constr_Assemble_KauxFaux_Arg
│   │   │    字段: nTotalDOF/nLambda/penaltyStiff/K_aux(:,:)/F_aux(:)/status(OUT)
│   │   ├─ PH_Constr_Apply_Transformation_Arg
│   │   │    字段: nDOF_full/nDOF_reduced/T(:,:)/K_full(:,:)/f_full(:)/K_red(:,:)/f_red(:)/status(OUT)
│   │   └─ ph_constr_pick_mpc_dep(私有)
│   │        功能: MPC主元选择(选|coeff|最大项为从属DOF)
│   │
│   │   **PH_Constr_MPC_Core.f90** (约230行)
│   │   ├─ PH_Constr_MPCCore_AssembleMatrix(constraints, num_constraints, C_matrix, rhs)
│   │   │    功能: 组装约束矩阵C和rhs向量
│   │   ├─ PH_Constr_MPCCore_AssemblePenalty(mpc, n_dof_total, kappa, K, R)
│   │   │    功能: 罚函数法K'=K+κ·A^T·A, F'=F+κ·A^T·b
│   │   ├─ PH_Constr_MPCCore_AssembleLagrangeBlock(mpc, n_dof_total, C_row)
│   │   │    功能: 拉格朗日块组装C_row
│   │   ├─ PH_Constr_MPCCore_ComputeViolation(mpc, u, violation)
│   │   │    功能: 计算约束违例g=∑A_i·u_i-rhs
│   │   ├─ PH_Constr_MPCCore_CheckConsistency(mpc, status)
│   │   │    功能: 检查MPC一致性(DOF有效性/系数非零)
│   │   └─ PH_Constr_MPCCore_Opt(mpc, optimized_mpc)
│   │        功能: MPC优化(合并同类项/消除冗余项)
│   │
│   │   **PH_Constr_MPC_API.f90** (约550行)
│   │   ├─ PH_Constr_MPC_Apply(K, F, mpc_ctx, status)
│   │   │    功能: MPC约束施加(罚/拉氏/消元自动分发)
│   │   ├─ PH_Constr_MPC_Assemble_Contribution(mpc, K_contrib, F_contrib, status)
│   │   │    功能: 组装MPC局部贡献
│   │   └─ 其他API封装(约15个)
│   │
│   │   **PH_Constr_MPC_Types.f90** (约120行)
│   │   ├─ TYPE PH_Constr_MPC_Def
│   │   │    字段: n_terms/node_ids(:)/dof_ids(:)/coefficients(:)/rhs_value/is_active
│   │   ├─ TYPE MPC_Constraint
│   │   │    字段: num_terms/terms(:)/rhs_value/is_active
│   │   └─ TYPE MPC_Term
│   │        字段: node_id/dof_id/coefficient
│   │
│   │   **PH_Constr_Tie_Core.f90** (约230行)
│   │   ├─ PH_Constr_TieCore_ComputeGap(tie, u_slave, u_master, gap)
│   │   │    功能: 计算Tie间隙g=u_slave-N(ξ_master)·u_master
│   │   ├─ PH_Constr_TieCore_AssemblePenalty(tie, kappa, K_contrib, F_contrib)
│   │   │    功能: Tie罚函数贡献
│   │   ├─ PH_Constr_TieCore_AssembleLagrange(tie, C_block, g_vec)
│   │   │    功能: Tie拉格朗日块组装
│   │   ├─ PH_Constr_TieCore_CheckContact(tie, tol, is_contact)
│   │   │    功能: 检查Tie接触状态(容差内)
│   │   └─ PH_Constr_TieCore_UpdateMasterProjection(tie, u_master)
│   │        功能: 更新主面投影点ξ_master
│   │
│   │   **PH_Constr_Tie_API.f90** (约520行)
│   │   ├─ PH_Constr_Tie_Apply(K, F, tie_ctx, status)
│   │   │    功能: Tie约束施加
│   │   └─ 其他API封装(约12个)
│   │
│   │   **PH_Constr_Tie_Types.f90** (约130行)
│   │   ├─ TYPE PH_Constr_Tie_Def
│   │   │    字段: slave_surf_id/master_surf_id/tolerance/n_slave_nodes/
│   │   │          slave_node_ids(:)/master_elem_ids(:)/master_xi(:,:)/
│   │   │          shape_funcs(:,:)/is_active
│   │   └─ Tie约束类型定义
│   │
│   │   **PH_Constr_Period_Core.f90** (约220行)
│   │   ├─ PH_Constr_PeriodCore_ComputePair(period, u_plus, u_minus, violation)
│   │   │    功能: 计算周期边界对违例g=u(x+L)-u(x)
│   │   ├─ PH_Constr_PeriodCore_AssemblePenalty(period, kappa, K_contrib, F_contrib)
│   │   │    功能: 周期边界罚函数贡献
│   │   ├─ PH_Constr_PeriodCore_AssembleLagrange(period, C_block)
│   │   │    功能: 周期边界拉格朗日块
│   │   └─ PH_Constr_PeriodCore_ApplyTransform(period, T_matrix)
│   │        功能: 周期边界变换矩阵
│   │
│   │   **PH_Constr_Period_API.f90** (约530行)
│   │   ├─ PH_Constr_Period_Apply(K, F, period_ctx, status)
│   │   │    功能: 周期边界约束施加
│   │   └─ 其他API封装(约12个)
│   │
│   │   **PH_Constr_Period_Types.f90** (约100行)
│   │   ├─ TYPE PH_Constr_Period_Def
│   │   │    字段: n_pairs/plus_node_ids(:)/minus_node_ids(:)/
│   │   │          period_vector(:)/transform_matrix(:,:)/is_active
│   │   └─ 周期边界类型定义
│   │
│   │   **PH_Constr_Ctx.f90** (约450行)
│   │   ├─ 约束上下文管理
│   │   ├─ 步/增量索引同步
│   │   └─ 约束状态跟踪
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory): 线性约束Cu=g+罚ΔK∝αC^TC/拉氏[K C^T; C 0]{u;λ}={f;g}/消元dofMask
│   │   • 逻辑链(Logic): L3 Constraint Desc→Populate→Register→AddMPCEquation→Assemble_KauxFaux→L5装配
│   │   • 计算链(Computation): 约束方程→选择施加方法(消元/罚/拉氏/增广)→局部K/F贡献→增广系统
│   │   • 数据链(Data): PH_Constraint_Ctx/State/Params+PH_Constraint_*_Arg金线参数
│   │
│   │   【热路径规范】
│   │   • 热路径零L3: 步内禁止从L3重解析MPC方程入热路径
│   │   • Populate缓存优先: 约束方程系数/DOF索引/rhs写入PH_Constraint_Ctx
│   │   • MPC主元选择: ph_constr_pick_mpc_dep选|coeff|最大项为从属DOF(消元法)
│   │   • 拉格朗日乘子: Update_Lambda更新λ←λ+ρ·g(增广拉格朗日迭代)
│   │   • 对称性: enforcementMethod与MPC/Tie API一致
│   │
│   │   【跨域依赖矩阵】
│   │   • L3_MD/Constraint: 提供约束Desc(MPC类型/Tie容差/周期向量)
│   │   • L3_MD/Mesh: 节点DOF映射/表面离散
│   │   • L5_RT/Assembly: RT_Asm_ApplyConstraints/RT_Asm_GlobalStiffness总装
│   │   • L4_PH/Element: 约束节点坐标/形函数
│   │
│   │   【覆盖率统计】
│   │   • 核心文件: 11个(Domain1个+MPC3个+Tie3个+Period3个+Ctx1个)
│   │   • TYPE定义: 12+个(Ctx/State/Params/MPC_Def/Tie_Def/Period_Def/Arg等)
│   │   • 子程序总数: 80+个(Domain12+MPC20+Tie18+Period16+API30+)
│   │   • 约束类型: 6种(MPC/RBE2/RBE3/Tie/Coupling/Embedded)
│   │   • 施加方法: 5种(消元/变换/拉格朗日/罚函数/增广拉格朗日)
│   │   • 合同对齐: Constraint/CONTRACT.md已验证
│   │
│   ├── PH_Constraint_Domain_Core.f90      → 域容器(约1020行, Domain金线12个绑定)
│   ├── PH_Constr_MPC_Core.f90             → MPC核心(约230行, 6子程序)
│   ├── PH_Constr_MPC_API.f90              → MPC API(约550行, 15+子程序)
│   ├── PH_Constr_MPC_Types.f90            → MPC类型(约120行, MPC_Def)
│   ├── PH_Constr_Tie_Core.f90             → Tie核心(约230行, 5子程序)
│   ├── PH_Constr_Tie_API.f90              → Tie API(约520行, 12+子程序)
│   ├── PH_Constr_Tie_Types.f90            → Tie类型(约130行, Tie_Def)
│   ├── PH_Constr_Period_Core.f90          → 周期核心(约220行, 4子程序)
│   ├── PH_Constr_Period_API.f90           → 周期API(约530行, 12+子程序)
│   ├── PH_Constr_Period_Types.f90         → 周期类型(约100行, Period_Def)
│   └── PH_Constr_Ctx.f90                  → 上下文(约450行)
│
├── Output/                               [输出计算域: 纯物理计算 - L4_PH层输出数据变换与场变量处理]
│   │
│   │   【设计意图】
│   │   Output域作为L4_PH层的"输出数据物理计算核心",承担5个核心职责:
│   │   ① 坐标变换: 全局坐标系↔局部坐标系的坐标转换x_local=R·x_global
│   │   ② 张量变换: Voigt记号(6分量)↔完整张量(3×3)的相互转换
│   │   ③ 场变量插值: 单元节点值→积分点值的形函数插值φ(ξ)=∑Nᵢ(ξ)·φᵢ
│   │   ④ 分量提取: 从多分量场数据中提取标量/向量/张量分量
│   │   ⑤ 薄适配器: PH_Output_API作为L5_RT的唯一路由接口(无IO/无内存分配/无状态管理)
│   │
│   │   【功能范围】
│   │   • 坐标变换: x_local=R·x_global(各向异性材料/梁壳截面应力输出)
│   │   • Voigt→Full: {σ_xx,σ_yy,σ_zz,σ_xy,σ_yz,σ_zx}→σ_ij（3×3对称张量）
│   │   • Full→Voigt: σ_ij（3×3）→{σ_xx,σ_yy,σ_zz,σ_xy,σ_yz,σ_zx}
│   │   • 场插值: φ(ξ)=∑ᵢNᵢ(ξ)·φᵢ(积分点应力→节点应力外推)
│   │   • 标量提取: 从[n_points×n_comp]提取单分量(如Mises等效应力)
│   │   • 向量提取: 从[n_points×3]提取3分量(位移/速度/加速度场)
│   │   • 张量提取: 从[n_points×6]Voigt→[3×3×n_points]Full(应力/应变张量)
│   │   • 纯计算: 无IO操作/无内存分配/无状态管理(热路径友好)
│   │   • 薄适配器: API层仅委托Core层,无调度逻辑
│   │
│   │   【不包含】
│   │   • ❌ VTK/HDF5/ODB文件写入(L1_IF/IO基础设施)
│   │   • ❌ 输出调度与格式选择(L5_RT/Output运行时调度)
│   │   • ❌ 数据生命周期管理(L3_MD/Output模型数据)
│   │
│   │   【核心f90文件】
│   │   核心计算(1个)
│   │   ① PH_Output_Core.f90 (约355行) - 输出计算核心(6个纯计算子程序)
│   │
│   │   API门面(1个)
│   │   ② PH_Output_API.f90 (约150行) - 统一API(6个API委托Core)
│   │
│   │   【子程序详细清单】
│   │
│   │   **PH_Output_Core.f90** (约355行)
│   │   ├─ TYPE PH_Output_Params (Desc-配置型)
│   │   │    字段: format_type(PH_OUTPUT_VTK/HDF5/ODB/BINARY)/
│   │   │          n_components(1/3/6/9)/tensor_rank(0/1/2)/
│   │   │          write_binary/field_name(:256)/units(:256)
│   │   ├─ TYPE PH_Output_State (State-状态型)
│   │   │    字段: n_nodes/n_elements/nodal_coords(:,:)/elem_connect(:,:)/
│   │   │          field_data(:,:)/time_value/step_number
│   │   ├─ PH_OUTPUT_VTK=1/PH_OUTPUT_HDF5=2/PH_OUTPUT_ODB=3/PH_OUTPUT_BINARY=4
│   │   ├─ PH_VOIGT_XX=1/PH_VOIGT_YY=2/PH_VOIGT_ZZ=3/
│   │   │  PH_VOIGT_XY=4/PH_VOIGT_YZ=5/PH_VOIGT_ZX=6
│   │   ├─ PH_Output_CoordTransform(coords_global(:,:), rotation_matrix(3,3), coords_local(:,:), status)
│   │   │    功能: 坐标变换x_local=R·x_global
│   │   │    理论: x_local = R · x_global (各向异性材料/梁壳截面)
│   │   │    验证: 恒等变换(R=I)/90°旋转/任意角度旋转
│   │   ├─ PH_Output_TensorTransform(tensor_voigt(6), tensor_full(3,3), direction, status)
│   │   │    功能: 张量变换Voigt↔Full
│   │   │    理论: Voigt→Full:[σ_xx,σ_yy,σ_zz,σ_xy,σ_yz,σ_zx]→σ_ij（对称）
│   │   │          Full→Voigt:[σ_ij]→{σ_xx,σ_yy,σ_zz,σ_xy,σ_yz,σ_zx}
│   │   │    验证: Voigt→Full→Voigt往返/对称性检查σ_ij=σ_ji
│   │   ├─ PH_Output_FieldInterpolate(nodal_values(:,:), shape_funcs(:), interpolated_value(:), status)
│   │   │    功能: 场变量插值φ(ξ)=∑Nᵢ(ξ)·φᵢ
│   │   │    理论: 形函数插值(积分点←节点)
│   │   │    验证: 线性形函数/二次形函数/守恒性检查∑Nᵢ=1
│   │   ├─ PH_Output_ExtractScalar(field_data(:,:), component_idx, scalar_value(:), status)
│   │   │    功能: 标量提取(如Mises等效应力)
│   │   │    验证: 边界值检查component_idx范围/维度匹配
│   │   ├─ PH_Output_ExtractVector(field_data(:,:), vector_values(:,:), status)
│   │   │    功能: 向量提取(位移/速度/加速度场3分量)
│   │   │    验证: 维度检查n_comp=3
│   │   └─ PH_Output_ExtractTensor(field_data(:,:), tensor_values(:,:,:), notation, status)
│   │        功能: 张量提取Voigt[6]→Full[3×3×n_points]
│   │        验证: Voigt索引检查/对称性
│   │
│   │   **PH_Output_API.f90** (约150行)
│   │   ├─ PH_Output_TransformCoords(coords_global, rotation_matrix, coords_local, status)
│   │   │    功能: API委托→PH_Output_CoordTransform
│   │   ├─ PH_Output_TransformTensor(tensor_voigt, tensor_full, direction, status)
│   │   │    功能: API委托→PH_Output_TensorTransform
│   │   ├─ PH_Output_InterpolateField(nodal_values, shape_funcs, interpolated_value, status)
│   │   │    功能: API委托→PH_Output_FieldInterpolate
│   │   ├─ PH_Output_GetScalar(field_data, component_idx, scalar_value, status)
│   │   │    功能: API委托→PH_Output_ExtractScalar
│   │   ├─ PH_Output_GetVector(field_data, vector_values, status)
│   │   │    功能: API委托→PH_Output_ExtractVector
│   │   └─ PH_Output_GetTensor(field_data, tensor_values, notation, status)
│   │        功能: API委托→PH_Output_ExtractTensor
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory): 连续介质力学张量变换理论+形函数插值理论
│   │   • 逻辑链(Logic): L4_PH纯计算→L5_RT调度→L1_IF文件写入
│   │   • 计算链(Computation): Voigt↔Full变换/坐标变换/场插值/分量提取
│   │   • 数据链(Data): PH_Output_Params(Desc)+PH_Output_State(State)
│   │
│   │   【热路径规范】
│   │   • 纯计算逻辑: 无IO操作/无内存分配/无状态管理
│   │   • 薄适配器: API层仅委托Core,无额外开销
│   │   • 热路径友好: 可直接在NR循环中调用(如应力输出)
│   │
│   │   【跨域依赖矩阵】
│   │   • L1_IF/IO: 文件句柄管理/二进制/文本IO(由L5_RT调用)
│   │   • L3_MD/Output: 输出配置/场请求/历史请求(Desc真相源)
│   │   • L5_RT/Output: 输出调度/格式选择/Writer路由(唯一调用方)
│   │   • L4_PH/Element: 形函数用于场插值
│   │
│   │   【覆盖率统计】
│   │   • 核心文件: 2个(Core1个+API1个)
│   │   • TYPE定义: 2个(Params/State)
│   │   • 子程序总数: 12个(Core6个+API6个)
│   │   • 计算功能: 6种(坐标变换/张量变换/场插值/标量提取/向量提取/张量提取)
│   │   • 合同对齐: Output/CONTRACT.md已验证
│   │
│   ├── PH_Output_Core.f90                   → 计算核心(约355行, 6子程序+2TYPE)
│   └── PH_Output_API.f90                    → API门面(约150行, 6API委托)
│
├── Field/                                [场计算域: 物理场演化 - L4_PH层多场耦合物理演化计算]
│   │
│   │   【设计意图】
│   │   Field域作为L4_PH层的"物理场演化计算核心",承担3个核心职责:
│   │   ① 温度场演化: 热传导方程求解∂T/∂t=α·∇²T+Q/(ρ·cp)(显式/隐式)
│   │   ② 孔隙压力场演化: 固结方程求解∂p/∂t=(k/s)·∇²p(达西渗流)
│   │   ③ 浓度场演化: 扩散-反应方程求解∂c/∂t=D·∇²c-R·c(菲克扩散+一级反应)
│   │
│   │   【L4_PH层定位】
│   │   • 向上承接L3_MD的场变量Desc(热物性/渗透率/扩散系数配置)
│   │   • 向下支撑L5_RT的多场耦合求解器编排(热-固/流-固/浓度-应力耦合)
│   │   • 与Element域协同: 场变量作为单元状态输入影响本构计算
│   │
│   │   【功能范围】
│   │   • 温度场: 热传导/对流/辐射边界/内热源/热应变耦合
│   │   • 孔隙压力场: 达西渗流/固结/流体压缩性/孔隙率
│   │   • 浓度场: 菲克扩散/一级反应/吸附效应/源汇项
│   │   • 时间积分: 显式Forward-Euler/隐式Backward-Euler
│   │   • 场变量管理: Desc(配置)/Algo(算法)/State(状态)三型分离
│   │   • 统一场接口: PH_Field_Desc/PH_Field_Algo/PH_Field_State捆绑3种场
│   │
│   │   【核心f90文件】
│   │   类型定义与计算(1个)
│   │   ① PH_Field_Def.f90 (约413行) - 场类型定义+显式/隐式计算(6子程序)
│   │
│   │   【子程序详细清单】
│   │
│   │   **PH_Field_Def.f90** (约413行)
│   │   ├─ TYPE PH_Temperature_Desc (Desc-温度场配置)
│   │   │    字段: field_id/field_name(:64)/thermal_conductivity[W/(m·K)]/
│   │   │          heat_capacity[J/(kg·K)]/density[kg/m³]/
│   │   │          heat_generation_rate[W/m³]/bc_type(1=温度/2=热流/3=对流)/
│   │   │          film_coefficient[W/(m²·K)]/ambient_temperature[K]/
│   │   │          reference_temp[K]/initial_temp[K]
│   │   ├─ TYPE PH_PorePressure_Desc (Desc-孔隙压力场配置)
│   │   │    字段: field_id/field_name(:64)/permeability[m/s]/porosity[-]/
│   │   │          compressibility[1/Pa]/storativity[1/m]/
│   │   │          fluid_density[kg/m³]/fluid_bulk_modulus[Pa]/
│   │   │          source_rate[kg/(m³·s)]/initial_pressure[Pa]
│   │   ├─ TYPE PH_Concentration_Desc (Desc-浓度场配置)
│   │   │    字段: field_id/field_name(:64)/diffusivity[m²/s]/porosity[-]/
│   │   │          has_reaction/reaction_rate[1/s]/decay_constant[1/s]/
│   │   │          has_sorption/sorption_coefficient[m³/kg]/
│   │   │          source_concentration[mol/m³]/initial_conc[mol/m³]
│   │   ├─ TYPE PH_Field_Desc (统一场Desc)
│   │   │    字段: field_type(1=Temp/2=PorePressure/3=Conc)/
│   │   │          temperature/porepressure/concentration
│   │   ├─ TYPE PH_Temperature_Algo (Algo-温度场算法)
│   │   │    字段: solver_type(1=显式/2=隐式)/time_integration(1=前向/2=后向)/
│   │   │          tolerance(1e-6)/max_iterations(100)/use_consistent_mass
│   │   ├─ TYPE PH_PorePressure_Algo (Algo-孔隙压力场算法)
│   │   │    字段: solver_type/time_integration/tolerance/max_iterations/
│   │   │          critical_time_step(稳定性临界步长)
│   │   ├─ TYPE PH_Concentration_Algo (Algo-浓度场算法)
│   │   │    字段: solver_type/time_integration/tolerance/max_iterations/
│   │   │          use_mass_lumping(质量集中)
│   │   ├─ TYPE PH_Field_Algo (统一场Algo)
│   │   │    字段: temperature/porepressure/concentration
│   │   ├─ TYPE PH_Temperature_State (State-温度场状态)
│   │   │    字段: temperature(:)[当前]/temperature_n(:)[上一步]/
│   │   │          heat_flux(3,:)[热流向量]/heat_source(:)[体热源]/
│   │   │          total_heat_energy/n_nodes/is_initialized
│   │   ├─ TYPE PH_PorePressure_State (State-孔隙压力场状态)
│   │   │    字段: pressure(:)[当前]/pressure_n(:)[上一步]/
│   │   │          velocity(3,:)[达西速度]/source_term(:)[源项]/
│   │   │          total_flow_rate/n_nodes/is_initialized
│   │   ├─ TYPE PH_Concentration_State (State-浓度场状态)
│   │   │    字段: concentration(:)[当前]/concentration_n(:)[上一步]/
│   │   │          flux(3,:)[扩散通量]/reaction_rate(:)[反应速率]/
│   │   │          total_mass/n_nodes/is_initialized
│   │   ├─ TYPE PH_Field_State (统一场State)
│   │   │    字段: temperature/porepressure/concentration
│   │   ├─ TYPE PH_Temperature_In (输入结构)
│   │   │    字段: coords(3,:)[指针]/temperature(1,:)[指针]/
│   │   │          time_step/time_now
│   │   ├─ TYPE PH_Temperature_Out (输出结构)
│   │   │    字段: temperature(1,:)/heat_flux(3,:)/status
│   │   ├─ TYPE PH_PorePressure_In/Out (孔隙压力输入/输出)
│   │   ├─ TYPE PH_Concentration_In/Out (浓度输入/输出)
│   │   ├─ INTERFACE PH_Field_Compute_Temperature
│   │   │    → PH_Field_Compute_Temperature_Explicit
│   │   │    → PH_Field_Compute_Temperature_Implicit
│   │   ├─ INTERFACE PH_Field_Compute_PorePressure
│   │   │    → PH_Field_Compute_PorePressure_Explicit
│   │   │    → PH_Field_Compute_PorePressure_Implicit
│   │   └─ INTERFACE PH_Field_Compute_Concentration
│   │        → PH_Field_Compute_Concentration_Explicit
│   │        → PH_Field_Compute_Concentration_Implicit
│   │
│   │   【计算子程序明细】
│   │
│   │   **温度场计算**(2个)
│   │   ├─ PH_Field_Compute_Temperature_Explicit(desc, algo, in, out, status)
│   │   │    理论: T^{n+1}=T^n+dt·α·∇²T (Forward-Euler显式)
│   │   │    参数: α=k/(ρ·cp)热扩散系数
│   │   │    状态: 占位符实现(待补全Laplacian离散)
│   │   └─ PH_Field_Compute_Temperature_Implicit(desc, algo, in, out, status)
│   │        理论: 隐式Backward-Euler(待补全线性系统求解)
│   │        状态: 占位符实现
│   │
│   │   **孔隙压力场计算**(2个)
│   │   ├─ PH_Field_Compute_PorePressure_Explicit(desc, algo, in, out, status)
│   │   │    理论: p^{n+1}=p^n+dt·(k/s)·∇²p (达西渗流显式)
│   │   │    参数: k渗透系数/s储水率
│   │   │    状态: 占位符实现
│   │   └─ PH_Field_Compute_PorePressure_Implicit(desc, algo, in, out, status)
│   │        理论: 隐式固结求解(待补全)
│   │        状态: 占位符实现
│   │
│   │   **浓度场计算**(2个)
│   │   ├─ PH_Field_Compute_Concentration_Explicit(desc, algo, in, out, status)
│   │   │    理论: c^{n+1}=c^n+dt·D·∇²c-dt·R·c (扩散+一级反应)
│   │   │    参数: D扩散系数/R反应速率
│   │   │    状态: 占位符实现
│   │   └─ PH_Field_Compute_Concentration_Implicit(desc, algo, in, out, status)
│   │        理论: 隐式扩散-反应求解(待补全)
│   │        状态: 占位符实现
│   │
│   │   【四链贯通说明】
│   │   • 理论链(Theory): 热传导方程/达西渗流/菲克扩散-反应方程
│   │   • 逻辑链(Logic): L3_MD场Desc→L4_PH场计算→L5_RT多场耦合编排
│   │   • 计算链(Computation): 显式Forward-Euler/隐式Backward-Euler
│   │   • 数据链(Data): Desc(配置)/Algo(算法)/State(状态)三型分离
│   │
│   │   【热路径规范】
│   │   • 显式计算: 热路径友好(无迭代,直接更新)
│   │   • 隐式计算: 温路径(需迭代求解线性系统)
│   │   • 占位符警告: 当前6个子程序均为占位符,待补全Laplacian离散与求解器
│   │
│   │   【跨域依赖矩阵】
│   │   • L3_MD/Field: 场变量Desc配置(热物性/渗透率/扩散系数)
│   │   • L5_RT/Coupling: 多场耦合求解器编排(热-固/流-固/浓度-应力)
│   │   • L4_PH/Element: 场变量作为单元状态输入(热应变/渗透力)
│   │   • L4_PH/Material: 温度相关本构(热软化/热膨胀)
│   │
│   │   【覆盖率统计】
│   │   • 核心文件: 1个(Types含类型定义+计算)
│   │   • TYPE定义: 15个(3×Desc+3×Algo+3×State+统一场3个+In/Out6个)
│   │   • 子程序总数: 6个(显式3个+隐式3个,均为占位符)
│   │   • 接口总数: 3个(INTERFACE多态分发)
│   │   • 计算功能: 3种场×2种积分=6种计算路径
│   │   • 完成度: Phase B(占位符实现,待补全PDE离散)
│   │
│   ├── PH_Field_Def.f90                   → 类型定义+计算(约413行, 15TYPE+6子程序+3接口)
│
├── Bridge/                               [桥接层]
│   ├── PH_Brg_Domain_Core.f90           → Bridge域聚合容器(199行, 4TYPE+2Arg+6子程序)
│   │   • 职责: UEL/UMAT/VUMAT/GPU外部库注册槽位管理
│   │   • TYPE: PH_Brg_Ctx(上下文), PH_Brg_State(状态), PH_Brg_Params(参数), PH_Brg_Domain(域聚合)
│   │   • 子程序: Init/Finalize/RegisterLib/GetSummary(含Arg封装版本)
│   │   • 枚举: PH_BRG_UEL/UMAT/VUMAT/GPU/EXTERNAL(5种库类型), MAX_LIBS=32
│   │   • 生命周期: PH_L4_Init最后/PH_L4_Finalize最先
│   │
│   ├── PH_Brg_L3.f90                    → L4↔L3桥接(289行, 8TYPE+8子程序)
│   │   • 职责: 幅值查询、材料响应、节点坐标、单元状态更新
│   │   • TYPE(In/Out): ElementStiffAssembly, UpdateElementState, GetMaterialResponse
│   │   • TYPE(Desc): ElemStateUpdate_Desc, MatId_Desc
│   │   • 子程序: GetMaterialResponse[_Idx], UpdateElementState[_Idx], GetAmplitudeValue_Idx, GetNodeCoords_Idx
│   │   • DEPRECATED(G4): ElementStiffAssembly[_Idx]→迁移至PH_Element_Domain%Compute_Ke
│   │   • 依赖: MD_Mat_Lib, MD_Model_Types, MD_Geom_PH_Brg, MD_Mesh_Core
│   │
│   ├── PH_Brg_L2.f90                    → L4↔L2桥接(282行, 7TYPE+10子程序)
│   │   • 职责: 单元连接性、节点坐标、高斯积分点查询
│   │   • TYPE(In/Out): GetElemConnectivity, GetNodeCoords, GetGaussPoints1D/2D/3D
│   │   • TYPE(Desc): ElemId_Desc
│   │   • 子程序: GetElemConnectivity[_Idx], GetNodeCoords[_Idx], GetGaussPoints1D/2D/3D
│   │   • 依赖: MD_Geom_Types, MD_Mesh_Core, MD_Geom_PH_Brg, NM_NumInt_Gauss_Core
│   │
│   ├── 📝 设计意图
│   │   • 跨层数据转换与适配(L4↔L3/L2薄适配层)
│   │   • UEL/UMAT/GPU注册元数据管理
│   │   • 非职责: 不持有全局CSR(L5), 不做NR主循环(L5), 不替代L3官方MD_*_PH_Brg
│   │
│   ├── 📐 功能范围
│   │   • L4→L3查询: 幅值/材料/几何(冷路径O(n))
│   │   • L4→L2适配: 连接性/高斯点(O(1)或O(n)拷贝)
│   │   • 外部库注册: 最多32个库(UEL/UMAT/VUMAT/GPU)
│   │   • 热路径: ❌ 否(全部Populate/Step-Init冷路径)
│   │
│   ├── 📊 统计: 3文件(770行) | 19TYPE | 24子程序 | 2个DEPRECATED
│
├── WriteBack/                            [回写]
│   ├── PH_WriteBack_Core.f90            → 核心物理计算(288行, 3TYPE+11子程序)
│   │   • 职责: 节点/单元State物理回写(非调度/非IO)
│   │   • TYPE(Desc): PH_WriteBack_Desc(7字段: 输出标志/频率/目录)
│   │   • TYPE(State): PH_WriteBack_State(6字段: 计数器/3缓冲区)
│   │   • TYPE(Ctx): PH_WriteBack_Args(10字段: 索引+物理量向量)
│   │   • 节点回写: NodeDisp/NodeVel/NodeAccel/NodePos(4个)
│   │   • 单元回写: ElemStress/ElemStrain(2个, Voigt记法6分量)
│   │   • 依赖: MD_Mesh_Proc, MD_WriteBack_API
│   │
│   ├── PH_WriteBack_API.f90             → 公共API薄封装(119行, 6子程序)
│   │   • 职责: L5_RT统一入口(直接转发到Core)
│   │   • ApplyNodeDisp/ApplyNodeVel/ApplyNodeAccel/ApplyNodePos
│   │   • ApplyElemStress/ApplyElemStrain
│   │
│   ├── PH_WriteBack_Init.f90            → 生命周期管理(73行, 2子程序)
│   │   • InitDomain(nnodes,nelems): 校验Desc+分配缓冲区
│   │   • FinalizeDomain: 释放State缓冲区
│   │
│   ├── 📝 设计意图: 计算物理State回写(连续介质力学更新→场插值→网格更新)
│   ├── 📐 功能范围: 节点4量(Disp/Vel/Accel/Pos) + 单元2量(Stress/Strain)
│   ├── 📊 统计: 3TYPE(Desc/State/Ctx) | 19子程序 | 6公开API | 0 DEPRECATED
│
├── PH_L4_LayerContainer_Core.f90    → L4层容器(199行, 1TYPE+2子程序)
│   • 职责: Step级6域聚合+生命周期管理(Material/Element/LoadBC/Constraint/Contact/Bridge)
│   • TYPE: PH_L4_LayerContainer(9字段: 6域实例+stepId/stepTime/initialized)
│   • 子程序: PH_L4_Init/Finalize (依赖驱动顺序初始化/逆序销毁)
│   • 依赖: 6域Core + PH_L4_Populate_Core + MD_L3_LayerContainer
│
├── PH_Core.f90                      → 核心TYPE定义(295行, 9TYPE+1子程序)
│   • 职责: 物理控制TYPE聚合(PH_PhysCtrl_Type含7个控制子TYPE)
│   • TYPE: Field/PhysCfg/FieldMgr/ElemAlgCtrl/ConstitCtrl/ConstrCtrl/ContCtrl/CoupleCtrl/PhysCtrl
│   • 子程序: PH_Proc_SelectPath (过程ID→物理路径位掩码)
│
├── PH_L4_Populate_Core.f90          → L3→L4填充(860行, 7子程序)
│   • 职责: Step-Init冷路径L3只读数据→L4暖数据填充
│   • 子程序: Populate_Material/HeatMaterial/Element/LoadBC/Constraint/Contact/Field
│   • 设计: md_src可选注入(支持Mock测试), G1修复fallback路径
```

**L4_PH 统计**: 9 域 | 14 子域 | 450+ 文件（材料54种 + 单元377种 + 其他）

---

## 六、L5_RT — 运行时协调层

```
L5_RT/
├── Assembly/                             [装配]
│   ├── RT_Assembly_Domain_Core.f90      → 域容器(238行, 5TYPE+2Arg+7子程序)
│   │   • 职责: Step/Inc级装配域生命周期管理+CSR稀疏矩阵管理
│   │   • TYPE(Ctx): RT_Assembly_Ctx(2字段: step_idx/incr_idx)
│   │   • TYPE(State): RT_Assembly_State(11字段: nEq/nnz/CSR数组/DoF映射)
│   │   • TYPE(Algo): RT_Assembly_Ctrl(5字段: 重编号方法/装配模式)
│   │   • 子程序: Init/Finalize/SyncStepIncr/BuildPattern/GetSummary
│   │   • 枚举: RT_RENUM_*(RCM/AMD/METIS), RT_ASM_*(Serial/OMP/Atomic/MPI)
│   │
│   ├── RT_Asm_Types.f90                 → 核心TYPE定义(405行, 4TYPE+12子程序)
│   │   • TYPE(Desc): RT_Asm_Desc(12字段: 装配标志/单元范围/约束)
│   │   • TYPE(State): RT_Asm_State(11字段: 进度/范数/矩阵指针)
│   │   • TYPE(Algo): RT_Asm_Algo(8字段: 装配方法/稀疏格式/并行策略)
│   │   • TYPE(Ctx): RT_Asm_Ctx (热路径临时缓冲区,零分配)
│   │   • 常量: ASM_MASS/DAMPING/STIFFNESS/LOADS
│   │
│   ├── RT_Asm_Core.f90                  → 装配核心(1190行, 6In/Out+9子程序)
│   │   • 职责: 单元→全局矩阵装配(K/M/C/F, 热路径)
│   │   • In/Out: AssemStiff/AssemResid/AssemMass (结构化IO)
│   │   • 子程序: RT_Asm_Init/Finalize/AssemStiff/AssemResidual/AssemMass/AssemDamping
│   │   • 🆕 子程序: RT_Asm_AddElemStiff_Atomic(K,Ke,dof,n,st) → ATOMIC模式装配(!$OMP ATOMIC)
│   │   • 🆕 子程序: RT_Asm_AddElemStiff_InPlace(K,Ke,dof,n,st) → Graph-Coloring模式装配(组内无竞态)
│   │   • 🆕 子程序: RT_Asm_ScatterResid_Atomic(R,Re,dof,n,st) → ATOMIC残差散射
│   │   • 流程: TripletList→CSR转换(一次性), 局部→全局DoF映射
│   │
│   ├── RT_Asm_Global.f90                → 全局装配(487行, 8子程序)
│   │   • 职责: 全局系统构建(CSR格式)+BC/载荷施加+几何非线性
│   │   • 子程序: Global_Init/Globalble_NL/Global_ApplyBC_Sparse
│   │   • 子程序: BuildGlobSys_Sparse/AssemElems_Sparse/ApplyBC_Sparse
│   │   • TYPE: CSR_Matrix (Legacy,向后兼容)
│   │
│   ├── RT_Asm_Solv.f90                  → 装配求解器(~150KB, 最大文件)
│   │   • 职责: Assembly Solver核心(装配+求解调度+非线性迭代)
│   │   • RT_Asm_Cfg.assembly_mode: 0=SERIAL,1=OMP_COLORING,2=OMP_ATOMIC 🆕
│   │   • 🆕 子程序: RT_Asm_ScatterKe_CSR_Atomic(K,Ke,dof,n) → CSR ATOMIC散射(!$OMP ATOMIC on values)
│   │   • SMP贯通(v4.0): GlobalStiffness/ComputeResidual !$OMP PARALLEL DO
│   │
│   ├── RT_Asm_DofMap.f90                → DoF映射(31.3KB)
│   │   • 职责: 节点DoF→全局方程编号+RCM/AMD重编号+约束应用
│   │
│   ├── RT_Asm_NLGeom_Eval.f90           → 几何非线性计算(76.4KB)
│   │   • 职责: TL/UL格式位移-应变关系+几何刚度矩阵K_geo
│   │
│   ├── RT_Asm_NLGeom_Dispatch.f90       → 几何非线性调度(65.9KB)
│   │   • 职责: TL/UL路由+过程类型分发(STATIC/NLGEOM/RIKS)
│   │
│   ├── RT_Asm_MassDamp_Core.f90         → 质量阻尼(57.5KB)
│   │   • 职责: 一致/集中质量矩阵+Rayleigh阻尼装配
│   │
│   ├── RT_Asm_Impl.f90                  → 实现细节(15.6KB)
│   │   • 职责: 内部装配辅助+内存管理+并行调度(SERIAL/OMP_ATOMIC/OMP_COLORING)
│   │
│   ├── RT_Asm_Util.f90                  → 工具函数(15.4KB)
│   │   • 职责: 矩阵范数+非零元统计+装配进度报告
│   │
│   ├── RT_Asm_ShapeMechanicalField.f90  → 力学形函数(15.2KB)
│   │   • 职责: 3D实体单元形函数
│   │
│   ├── RT_Asm_ShapeScalarField.f90      → 标量形函数(23.1KB)
│   │   • 职责: 温度/压力场形函数
│   │
│   ├── RT_Asm_ShapeShell.f90            → Shell形函数(8.2KB)
│   │   • 职责: Shell单元形函数
│   │
│   ├── RT_Asm_ShapeMembrane.f90         → Membrane形函数(6.6KB)
│   │   • 职责: Membrane单元形函数
│   │
│   ├── RT_Asm_ShapeMech2D.f90           → 2D形函数(7.6KB)
│   │   • 职责: 平面应力/应变单元形函数
│   │
│   ├── RT_Asm_ShapeBeam.f90             → Beam形函数(3.6KB)
│   │   • 职责: Beam单元形函数
│   │
│   ├── RT_Asm_Proc.f90                  → 过程接口(11.7KB)
│   │   • 职责: PROC_XXX路由+物理路径选择(MECH/THERM/COUPLE)
│   │
│   ├── RT_AsmColor.f90                   → Graph-Coloring并行装配(187行, 1TYPE+2子程序) 🆕
│   │   • 职责: 贪心图着色消除装配竞态(ABAQUS SMP映射)
│   │   • TYPE: RT_AsmColor_Result(color_of/n_colors/color_count/color_start/color_elems)
│   │   • 子程序: RT_AsmColor_Build(In n_elem, In n_dof_per_elem, In elem_dof_table, Out result, Out status) → 构建着色
│   │   • 子程序: build_color_groups(InOut result, In n_elem) → 内部:颜色分组排列
│   │   • 算法: DOF-to-element逆映射 → 贪心着色(最小可用色) → 颜色分组
│   │   • SMP贯通(v4.0): 逐颜色组!$OMP PARALLEL DO,组内DOF无交集
│   │
│   ├── 📝 设计意图: 运行时全局矩阵装配核(单元→全局scatter,热路径零L3)
│   ├── 📐 功能范围: K/M/C/F装配+DoF映射+CSR构建+TL/UL非线性+约束/接触集成+SMP并行(ATOMIC/Graph-Coloring)
│   ├── 📊 统计: 18文件(~545KB) | 12+TYPE | 55+子程序 | 2已删除(NLMat_Eval/Ldbc_Apply) | 🆕 RT_AsmColor.f90
│   ├── ⚠️  推断清单差异: 8规划名称 vs 18实际文件, 使用RT_Asm_*缩写(非RT_Assem_*)
│
├── Bridge/                               [桥接层]
│   ├── RT_Brg_Core.f90                  → 核心容器(122行, 4TYPE+1Arg+5子程序)
│   │   • 职责: 作业级检查点管理+域聚合容器
│   │   • TYPE(Ctx): RT_Bridge_Ctx(2字段: step_idx/incr_idx)
│   │   • TYPE(State): RT_BridgeState_Type (从RT_Global_Ctx导入)
│   │   • TYPE(Algo): RT_BridgeCtrl_Type (从RT_Global_Ctx导入)
│   │   • 子程序: Init/Finalize/SyncStepIncr/GetSummary
│   │   • 检查点: LastCheckpointIncr/LastCheckpointTime
│   │
│   ├── RT_Brg_Types.f90                 → 桥接Ctx定义(327行, 11TYPE+3子程序)
│   │   • 职责: 11种域专用Bridge_Ctx(L3/L4描述符→L5执行引擎)
│   │   • RT_Mat_Bridge_Ctx(11字段): UMAT/VUMAT桥接(mat_id/algo_id/dtime/kstep)
│   │   • RT_Elem_Bridge_Ctx(12字段): UEL/VUEL桥接(elem_id/lflags(5)/nrhs)
│   │   • RT_Load_Bridge_Ctx(11字段): DLOAD/VDLOAD桥接(noel/npt/amplitude)
│   │   • RT_BC_Bridge_Ctx(10字段): DISP/VDISP桥接(node_id/dof_id/doflab)
│   │   • RT_Contact_Bridge_Ctx(11字段): UINTER桥接(surf_id/gap/pressure)
│   │   • RT_Fric_Bridge_Ctx(11字段): FRIC桥接(surf_id/pressure/temp)
│   │   • RT_Constr_Bridge_Ctx(10字段): UMPC桥接(constr_id/nterms/nblock)
│   │   • RT_Field_Bridge_Ctx(11字段): USDFLD桥接(noel/npt/nfield/nstatv)
│   │   • RT_Analy_Bridge_Ctx(14字段): UEXTERNALDB桥接(lop/ampname/nuvarm)
│   │   • RT_Mesh_Bridge_Ctx(7字段): 网格数据(coord/connect/dof_map指针)
│   │   • RT_Step_Bridge_Ctx(9字段): 步配置(step_id/dt_current/dt_min/dt_max)
│   │   • 子程序: RT_Bridge_Init/SetReady/SetDone
│   │   • 状态机: IDLE(0)→READY(1)→DONE(2)/ERROR(3)
│   │
│   ├── 📝 设计意图: 跨层数据中介(非拥有指针传递)+检查点管理
│   ├── 📐 功能范围: 11种Bridge_Ctx+检查点元数据+桥接状态机
│   ├── 📊 统计: 2文件(~17KB) | 15TYPE | 8子程序 | 0 DEPRECATED
│   ├── ⚠️  推断清单差异: 13规划名称 vs 2实际文件, 使用RT_Brg_*缩写(非RT_Bridge_*)
│
├── Contact/                              [接触]
│   ├── RT_Contact_Types.f90             → 四型定义(528行, 4TYPE+17子程序)
│   │   • TYPE(Desc): RT_Contact_Desc(13字段: 主从面ID/摩擦/罚刚度/搜索容差)
│   │   • TYPE(State): RT_Contact_State(20字段: 状态/力/穿透/AugLag双缓冲区)
│   │   • TYPE(Algo): RT_Contact_Algo(13字段: 离散化/约束/摩擦/搜索/AugLag)
│   │   • TYPE(Ctx): RT_Contact_Ctx(15字段: 热路径临时缓冲区,零ALLOCATABLE)
│   │   • 常量: RT_CONT_DISC/ENFORCE/NORMAL/FRICTION/PAIR_* (5类25个)
│   │
│   ├── RT_ContactCore.f90               → 核心管理器(325行, 3内部TYPE+10子程序)
│   │   • 职责: 全局接触管理器(g_cont_mgr)+接触对生命周期
│   │   • 内部TYPE: RT_Cont_SurfDesc/RT_Cont_PairDef/RT_Cont_PairBuf
│   │   • 子程序: Init/Clean/RegVars/RegModel/GetStat/contact_init_from_pair
│   │
│   ├── RT_Cont_Solv.f90                 → 求解器接口(484行, 8In/Out+4子程序)
│   │   • 职责: 结构化IO(Principle#14)+L4_PH路由
│   │   • 接口: RT_Cont_Search/ComputeForce/Assemble/GetStats
│   │   • 输出ID: CFORCE/CPRESS/GAP/CSTATU
│   │
│   ├── RT_Cont_Search_Core.f90          → 搜索路由(1235行, 3TYPE+26子程序)
│   │   • 职责: 三种空间加速结构+两阶段搜索
│   │   • TYPE: RT_Cont_SpatHashGrid/OctreeNode/BVHNode
│   │   • 子程序: Search_SpatHash/Octree/BVH + BroadPhase/NarrowPhase
│   │   • 设计: 薄适配层,所有搜索物理委托L4_PH
│   │
│   ├── RT_Cont_AugLag_Solver.f90        → 增广拉格朗日求解器(265行, 3子程序)
│   │   • 职责: 三层嵌套迭代(Uzawa外循环→NR全局→局部本构)
│   │   • 子程序: AugLag_Solve/UpdateLambda/CheckConv
│   │   • 理论: Simo&Laursen(1992), Wriggers§9.2
│   │
│   ├── RT_Cont_Ctrl.f90                 → 接触控制(10.6KB)
│   │   • 职责: 接触控制参数管理+自适应罚刚度
│   │
│   ├── RT_Cont_Expl.f90                 → 显式接触(25.9KB)
│   │   • 职责: 显式动力学接触算法
│   │
│   ├── 📝 设计意图: 接触系统运行时调度(三层迭代+空间搜索+薄适配L4_PH)
│   ├── 📐 功能范围: 接触对管理+3种离散化×3种约束×5种摩擦+3种空间加速
│   ├── 📊 统计: 7文件(~149KB) | 15+TYPE | 60+子程序 | 2已删除(Unified*)
│   ├── ⚠️  推断清单差异: 8规划名称 vs 7实际文件, RT_ContactCore.f90(非RT_Cont_Core)
│
├── Coupling/                             [⭐ 耦合]
│   ├── RT_MF_Types.f90                  → 四型定义(560行, 6TYPE+4子程序)
│   │   • 职责: 多场耦合四型系统(Desc/State/Algo/Ctx)+辅助TYPE
│   │   • TYPE(Aux): RT_MF_FieldPair_Desc(12字段: src/dst场ID/qty_type/界面ID/缩放因子)
│   │   • TYPE(Aux): RT_MF_InterfaceBuf(7字段: send_buf/recv_buf/W_interp插值权重/recv_prevΔ缓冲)
│   │   • TYPE(Desc): RT_MF_Coupling_Desc(11字段: n_fields/field_ids/coup_matrix/pairs/strategy/subcycle)
│   │   • TYPE(State): RT_MF_Coupling_State(17字段: coup_iter/res_abs_rel_ref/field_converged/pnewdt_min/aitken_omega)
│   │   • TYPE(Algo): RT_MF_Coupling_Algo(14字段: eps_coup_rel/max_iter/relax_factor/interp_method/mono_linsol)
│   │   • TYPE(Ctx): RT_MF_Coupling_Ctx(8字段: time_coup/dtime_field/bufs接口缓冲区/norm_buf/dof_offset)
│   │   • 子程序(State): Init(n_pairs)分配逐对数组/Reset()每增量重置
│   │   • 子程序(Algo): Init()恢复默认参数
│   │   • 子程序(Ctx): Alloc(n_pairs,n_nodes,n_dof)分配缓冲区/Dealloc()释放
│   │   • 枚举: RT_MF_FIELD_*(STR/THM/FLD/DIF/EM/ACO共6场)
│   │   • 枚举: RT_MF_COUP_*(ONEWAY/STAG/PARTITER/MONO共4策略)
│   │   • 枚举: RT_MF_QTY_*(DISP/VEL/STRESS/TEMP/HFLUX等10种通道量)
│   │   • 枚举: RT_MF_INTERP_*(NN/RBF/MLS/C0共4种插值)
│   │   • 枚举: RT_MF_STATE_*(IDLE/ITERATING/CONVERGED/DIVERGED/MAX_ITER)
│   │
│   ├── RT_MF_Coordinator.f90            → 多场协调器(569行, 3公共+8私有子程序)
│   │   • 职责: 顶层耦合策略路由+4种驱动循环+界面交换+收敛检查
│   │   • 公共接口: RT_MF_Coordinator_Init/Run/Finalize
│   │   • 私有策略(4):
│   │     - RT_MF_Oneway_Loop: 单向传递(序贯求解→1次交换→标记收敛)
│   │     - RT_MF_Staggered_Loop: 弱耦合(coup_iter=1,Phase-1 STR↔THM优先)
│   │     - RT_MF_PartIter_Loop: 分区迭代(外循环k=1..max_iter+收敛检查+Aitken)
│   │     - RT_MF_Monolithic_Loop: 单体耦合(块矩阵求解,STUB状态)
│   │   • 私有辅助(4):
│   │     - RT_MF_Solve_SingleField: 场求解路由(STR/THM/FLD/DIF/EM/ACO→StepDriver,STUB)
│   │     - RT_MF_Exchange_Interface: 界面交换(STR→THM塑性热/THM→STR热应变,STUB)
│   │     - RT_MF_ConvCheck_Coupling: 收敛检查(||Φ^k-Φ^{k-1}||/||Φ^1||,L2范数)
│   │     - RT_MF_Aitken_Accelerate: AitkenΔ²加速(STUB,固定使用omega_0)
│   │
│   ├── 📝 设计意图: 多场耦合运行时调度(4策略路由+跨场交换+收敛控制)
│   ├── 📐 功能范围: 6物理场×4耦合策略×10通道量×4插值方法+时间子循环+Aitken加速
│   ├── 📊 统计: 2文件(~51KB) | 6TYPE | 15子程序 | 4策略(STUB:Monolithic/6场路由/Aitken)
│   ├── ⚠️  推断清单差异: 8规划名称 vs 2实际文件, 策略内聚到Coordinator(非独立Strategy文件)
│
├── Element/                              [单元]
│   ├── RT_Elem_Types.f90                → 四型定义(81行, 4TYPE包装PH基类)
│   │   • 职责: RT层四型(Desc/State/Algo/Ctx)包装L4_PH基类+运行时元数据
│   │   • TYPE(Desc): RT_Elem_Desc(4扩展: elem_id/section_id/material_id/instance_id)
│   │   • TYPE(State): RT_Elem_State(3扩展: n_eq/eq_map(:)/is_active)
│   │   • TYPE(Algo): RT_Elem_Algo(3扩展: solver_type/preconditioner/use_nlgeom)
│   │   • TYPE(Ctx): RT_Elem_Ctx(3扩展: node_offset/elem_offset/n_secondary)
│   │
│   ├── RT_Elem_Dispatcher.f90           → 数据驱动路由器(242行, 5子程序)
│   │   • 职责: 注册表驱动单元族分发(无硬编码回退,Unknown=ERROR)
│   │   • 公共接口: Init/Register/Run/GetCount
│   │   • 私有接口: Unregister(动态重配置)
│   │   • 算法: 线性搜索router_table → ASSOCIATED(compute) → 调用内核
│   │
│   ├── RT_Elem_UEL.f90                  → UEL API薄适配(175行, 2子程序)
│   │   • 职责: 7参数标准UEL API+材料类型路由
│   │   • 公共接口: RT_Elem_UEL_API(sect_registry/elem_desc/ph_ctx/ph_state/com_ctx/pnewdt/status)
│   │   • 公共接口: RT_Elem_UEL_Probe(冷路径探测工具)
│   │   • 合同验证: integ_npts>0/jprops(1)存在/section注册/mat_desc关联
│   │   • 材料路由: SELECT TYPE(Elastic/Plastic/Hyperelastic)→PH_UMAT_API
│   │
│   ├── RT_Elem_Sect.f90                 → 截面服务(175行, 4子程序)
│   │   • 职责: L3→L5截面注册表桥接+材料描述符解析
│   │   • 公共接口: Init/GetMatDesc/Populate(深拷贝)/Finalize
│   │   • Populate工作流: 验证L3→初始化L5→逐段拷贝→验证mat_desc→同步元数据
│   │
│   ├── RT_Elem_Proc.f90                 → SIO接口契约(251行, 7抽象接口+8I/O结构体)
│   │   • 职责: 定义六参数签名抽象接口(无实现,委托L4_PH)
│   │   • 抽象接口: Init/ComputeKe/ComputeFe/ComputeMe/ComputeCe/CollectOutput/Finalize
│   │   • I/O结构体: Elem_Init_In/Out/Ke_In/Out/Fe_In/Out/Me_In/Out/Ce_In/Out/Out_In/Out
│   │
│   ├── RT_Elem_Dispatch_Brg.f90         → L4_PH桥接(182行, 4子程序)
│   │   • 职责: SIO→L4_PH Dispatcher参数转换
│   │   • 公共接口: Brg_ComputeKe/Brg_ComputeFe/Brg_ComputeMe/Brg_ComputeCe
│   │   • 路由目标: PH_Element_Ke/Fe/Mass_Dispatch
│   │
│   ├── RT_Element_Kernel_Proc.f90       → 内核总调度(266行, 2TYPE+6子程序)
│   │   • 职责: 单元计算总入口(calc_type路由1-4)+跨层映射
│   │   • TYPE(In): RT_Elem_Kernel_In(17字段: coords/displ/vel/accel/time/dtime/nlgeom)
│   │   • TYPE(Out): RT_Elem_Kernel_Out(8字段: amatrx/rhs/mass/damp/statev/energy)
│   │   • 公共接口: Kernel_Compute(六参数SIO)/Kernel_Init/Kernel_Update
│   │   • 私有辅助: RT_to_PH_Map/PH_to_RT_Update/Kernel_Allocate_Out
│   │
│   ├── RT_Element_Compute_Proc.f90      → Ke/Fe/Me计算调度(246行, 1TYPE+5子程序)
│   │   • 职责: 分项计算调度(设置calc_type→调用Kernel_Compute)
│   │   • TYPE: RT_Elem_Compute_Args(12字段: coords/displ/vel/accel/time/flags)
│   │   • 公共接口: Compute_Ke/Compute_Fe/Compute_Me/Compute_All
│   │   • 私有辅助: Setup_Kernel_In
│   │
│   ├── RT_Element_Assembly_Proc.f90     → 全局装配(320行, 1TYPE+5子程序)
│   │   • 职责: LM数组映射+单元矩阵→全局系统装配
│   │   • TYPE: RT_Elem_Assembly_In(15字段: conn/lm/coords/displ/time/nlgeom)
│   │   • 公共接口: Assemble_Ke/Assemble_Fe/Assemble_Me/Assemble_All
│   │   • 装配逻辑: DO i,j; ii=lm(i); jj=lm(j); IF(ii>0.AND.jj>0) global(ii,jj)+=elem(i,j)
│   │   • 私有辅助: Setup_Compute_Args
│   │
│   ├── RT_Thermal_Mechanical_Coupling.f90 → 热力耦合路由(228行, 1TYPE+3子程序)
│   │   • 职责: 纯路由(无计算)+数据载体
│   │   • TYPE: RT_Thermal_Load(9字段: temperature/ref_temp/thermal_strain/f_thermal)
│   │   • 公共接口: Compute_Strain_Route/Assemble_Force_Route/Update_Stress_Route
│   │   • 路由目标: PH_Thermal_Strain/Stress/Force_Assembly_Kernel
│   │
│   ├── 📝 设计意图: 单元运行时调度(数据驱动路由+UEL适配+跨层映射+薄适配L4_PH)
│   ├── 📐 功能范围: 注册表分发/7参数UEL/截面桥接/SIO契约/Ke/Fe/Me装配/热力耦合路由
│   ├── 📊 统计: 10文件(~90KB) | 17TYPE | 34子程序 | 7抽象接口 | 已删除(Core/Domain)
│   ├── ⚠️  推断清单差异: 6规划名称 vs 10实际文件, 无Core/API/BatchCompute, 采用路由器+桥接模式
│
├── LoadBC/                               [载荷与边界]
│   ├── RT_LoadBC_Types.f90              → 四型定义+生命周期(223行, 4TYPE+4子程序)
│   │   • 职责: 载荷/BC四型(Desc/Ctx/State/Algo)+生命周期管理
│   │   • TYPE(Desc): RT_LoadBC_Desc(15字段: loadbc_id/type/step_scheduling/DOF/amp_id/magnitude)
│   │   • TYPE(Ctx): RT_LoadBC_Ctx(10字段: step/total_time/dt/step/incr/iter/analysis_type/nlgeom)
│   │   • TYPE(Algo): RT_LoadBC_Algo(13字段: cutback/adaptive_time/convergence_tol)
│   │   • TYPE(State): RT_LoadBC_State(5字段: load/bc/cutback标志+total_cutbacks/iterations)
│   │   • 子程序: Init(初始化)/Update(增量步)/CheckConvergence(收敛+cutback决策)/ApplyCutback(荷载截断)
│   │   • 枚举: RT_LOADBC_STATIC/DYNAMIC/THERMAL(1/2/3)
│   │
│   ├── RT_LoadBC_Proc.f90               → SIO六参数接口(298行, 14I/O结构体+8子程序)
│   │   • 职责: SIO接口封装(desc/state/algo/ctx/inp/out,委托Impl或L4_PH)
│   │   • I/O结构体(7对): Init/Update/ApplyLoads/ApplyBCs/ComputeReactions/CheckConvergence/ApplyCutback/Finalize
│   │   • 公共接口(8): 全部六参数签名,Proc层仅做接口委托
│   │   • STUB状态: ApplyLoads/ApplyBCs/ComputeReactions/Finalize(TODO:路由L4_PH)
│   │
│   ├── RT_LoadBC_Impl.f90               → 实现逻辑+L4_PH路由(357行, 8子程序)
│   │   • 职责: 薄适配层实现+L4_PH路由(载荷施加/BC应用/收敛控制/cutback)
│   │   • 公共接口(8): Init_Impl/Update_Impl/ApplyLoads_Impl/ApplyBCs_Impl/ComputeReactions_Impl/CheckConvergence_Impl/ApplyCutback_Impl/Finalize_Impl
│   │   • ApplyLoads_Impl: 路由到PH_Load_ApplyLoads,映射ctrl/nLoads/load_cache/amp_factors
│   │   • ApplyBCs_Impl: 零信任检查(IS_FINITE验证NaN/Inf),n_bcs_applied=SIZE(bc_dofs)
│   │   • CheckConvergence_Impl: converged=(residual_norm<tol),cutback决策(iter_ratio>2.0)
│   │   • ApplyCutback_Impl: dt*=cutback_factor(0.5),检查min_load_increment
│   │
│   ├── RT_BC_Reaction_Force.f90         → BC施加+反力计算(251行, 2TYPE+3子程序)
│   │   • 职责: 边界条件施加(Penalty/Elimination)+反力计算(R=F_ext-F_int)
│   │   • TYPE(In): RT_BC_Apply_In(10字段: bc_id/type/dof/node_ids/bc_values/apply_method)
│   │   • TYPE(Out): RT_BC_Reaction_Out(6字段: reactions/total_rx/ry/rz/energy/computed)
│   │   • 公共接口(3):
│   │     - RT_BC_Apply_Constraints: Penalty(K_ii+=1e20,F_i=K_ii*u)或Elimination(K行/列=0,K_ii=1,F_i=u)
│   │     - RT_BC_Compute_Reactions: 约束DOF反力(STUB:当前f_reaction=f_ext占位)
│   │     - RT_BC_Process_Element_Reactions: 集成RT_Element_Assemble_Fe获取单元残差
│   │
│   ├── 📝 设计意图: 载荷/BC运行时编排(全局RHS施加+边界处置+收敛控制+反力计算)
│   ├── 📐 功能范围: SIO六参数接口/5种约束实现/2种BC方法/自适应时间步/auto_cutback/反力计算
│   ├── 📊 统计: 4文件(~43KB) | 18TYPE | 23子程序 | 8SIO接口 | 已删除(Apply_Core/Apply_Ctx/ConstApply)
│   ├── ⚠️  推断清单差异: 6规划名称 vs 4实际文件, 无Core/API/Registry/Sync, 采用Types+Proc+Impl+Reaction四层分离
│
├── Logging/                              [⭐ 日志]
│   ├── RT_Log_System.f90                → 运行时日志系统(328行, 2TYPE+9子程序)
│   │   • 职责: L5_RT运行时日志API封装，委托IF_Log_Core统一日志管理
│   │   • TYPE(Desc): RT_LogConfig(8字段: log_level/output_target/log_file/append_mode/include_timestamp/include_level/include_module/colorize_output)
│   │   • TYPE(Ctx): RT_Logger(1字段: config配置描述符)
│   │   • 公共接口(9): RT_Log_Init/Debug/Info/Warn/Error/Fatal/Finalize/Unified_Manage/Unified_Cfg
│   │   • 内部辅助(2): map_output_target(映射RT→IF输出目标)/rt_config_to_if_config(配置转换)
│   │   • 日志级别: DEBUG/INFO/WARNING(WARN别名)/ERROR/FATAL/OFF(99)
│   │   • 输出目标: STDOUT(1)/FILE(2)/BUFFER(3)/BOTH(4)
│   │   • 委托模式: 所有日志调用委托g_if_logger(IF_Log_Core全局实例)
│   │   • 配置映射: RT API输出目标(1/2/3/4)→IF_Log_Core输出目标(1/2/4/3)注意3/4不同
│   │
│   ├── 📝 设计意图: 运行时日志API封装层（委托IF_Log_Core统一管理）
│   ├── 📐 功能范围: 5级日志+4种输出目标+统一配置管理+日志级别过滤
│   ├── 📊 统计: 1文件(~14KB) | 2TYPE | 11子程序(9公共+2私有) | 委托模式
│   ├── ⚠️  推断清单差异: 3规划名称 vs 1实际文件, 采用单文件封装设计(非Core+Types+Mgr分离)
│
├── Material/                             [❌ 已废弃-归档到OLD]
│   ├── 📁 OLD/                           [归档目录(15文件)]
│   │   ├── RT_Mat_Core.f90              → 材料核心(3832行, 已废弃)
│   │   ├── RT_Mat_Impl.f90              → 实现逻辑(13KB, 已废弃)
│   │   ├── RT_Mat_Proc.f90              → SIO接口(261行, 已废弃)
│   │   ├── RT_Mat_Types.f90             → 四型定义(345行, 已废弃)
│   │   ├── Base/                        → 基础模块(4文件)
│   │   ├── Bridge/                      → L4_PH桥接(2文件)
│   │   ├── Cache/                       → 缓存管理(3文件)
│   │   ├── Commit/                      → 状态提交(2文件)
│   │   ├── Loop/                        → 积分点循环(2文件)
│   │   └── Util/                        → 工具函数(2文件)
│   │
│   ├── 📝 设计意图: 运行时材料调度(已废弃, 材料计算内聚到Element域)
│   ├── 📐 废弃原因: 材料计算与单元计算强耦合, 独立域导致上下文传递开销
│   ├── 📊 归档统计: 15文件(~300KB) | 已迁移到L5_RT/Element+L4_PH/Material
│   ├── ⚠️  推断清单差异: 7规划名称 vs 0活动文件, 整个域已归档到OLD目录
│
├── Mesh/                                 [⭐ 网格]
│   ├── RT_Mesh_Types.f90                → 四型定义(207行, 8TYPE)
│   │   • 职责: 网格运行时状态管理四型系统(Desc/State/Algo/Ctx)+扩展TYPE
│   │   • TYPE(Desc): RT_Mesh_Base_Desc(7字段: runtime_id/mesh_label/is_active/md_registry引用/cached_nnodes/cached_nelems/cache_valid/status)
│   │   • TYPE(State): RT_Mesh_Base_State(11字段: node_coords/node_displ/node_velocity/node_accel/dof_numbers/total_active_dof/elem_status/node_partition/elem_partition/n_partitions/is_initialized/numbering_complete/status)
│   │   • TYPE(Algo): RT_Mesh_Base_Algo(11字段: numbering_scheme/enforce_contiguous/use_reverse_cuthill_mckee/use_partitioning/target_partitions/partition_strategy/precompute_connectivity/cache_elem_matrices/sparse_storage_format/print_numbering_info/compute_bandwidth/status)
│   │   • TYPE(Ctx): RT_Mesh_Base_Ctx(12字段: curr_step/incr/iter/time/dt/update_coords/update_state/renumber_dofs/rebuild_connectivity/elem_start/end/node_start/end/thread_id/n_threads/status)
│   │   • TYPE(扩展): RT_Mesh_NodeState(12字段: node_id/coords_curr_prev(3)/displ(3)/velocity(3)/accel(3)/dof_ids(6)/eq_nums(6)/ndof/is_constrained/partition_id/status)
│   │   • TYPE(扩展): RT_Mesh_ElementState(8字段: elem_id/elem_type/node_ids数组/ip_weights/volume/volume_ref/status_flag/partition_id/status)
│   │   • TYPE(扩展): RT_Mesh_NumberingAlgo(8字段: base/max_bandwidth/profile_size/fill_ratio/rcm_start_node/use_level_structure/n_constrained_dof/n_free_dof/status)
│   │   • TYPE(扩展): RT_Mesh_AssemblyCtx(9字段: base/row_ptr/col_idx/nnz/elem_matrix/elem_vector/lm/thread_ws/use_atomic_assembly/status)
│   │
│   ├── RT_Mesh_Proc.f90                 → SIO接口封装(224行, 6接口+12I/O结构体)
│   │   • 职责: 网格运行时管理公共接口定义(结构化I/O类型+接口委托)
│   │   • I/O对(6): RT_Mesh_Init/Clean/Numbering/UpdateCoords/GetState/Assembly
│   │   • 接口委托: 所有接口委托RT_Mesh_Impl实现(Proc仅做接口层)
│   │
│   ├── RT_Mesh_Impl.f90                 → 实现逻辑(316行, 6子程序+2辅助)
│   │   • 职责: 网格运行时状态管理+DOF编号+坐标更新+装配逻辑
│   │   • 公共接口(6): RT_Mesh_Impl_Init/Clean/Numbering/UpdateCoords/GetState/Assembly
│   │   • 辅助函数(2): InitializeCoordsFromMD(从MD初始化坐标)/FindNodeIndex(查找节点索引)
│   │   • 全局状态: global_mesh_desc/global_mesh_state/system_initialized模块级SAVE变量
│   │   • STUB状态: Assembly子程序仅占位(TODO: CSR/CSC稀疏装配)
│   │
│   ├── RT_Mesh_Sys.f90                  → 网格系统层(634行, 2TYPE+23子程序)
│   │   • 职责: 系统级网格操作+跨模块协调+统一接口聚合
│   │   • TYPE(2): RT_Mesh_Cfg(配置: autoInitElems/Mats/Sects/enableElemReg/maxElemFam+2TBP)
│   │   • TYPE(3): RT_Mesh_Sys(系统: inited/cfg/stat+11TBP)
│   │   • 全局实例: g_meshSys(RT_Mesh_Sys, SAVE)
│   │   • 系统接口(5): RT_Mesh_SysInit/Clean/RegModel/GetStat/Valid
│   │   • 统一接口(10): RT_Mesh_Init/Clean/RegVars/InitElems/InitMats/InitSects/CompElem/GetElemCnt/GetNodeCnt/GetBrg
│   │   • TBP方法(11): Init/Clean/RegVars/InitElems/InitMats/InitSects/CompElem/GetElemCnt/GetNodeCnt/GetBrg/GetStat
│   │   • 桩模块(4): RT_Mesh_MgrInit/Clean/Reg/GetStat(占位实现)
│   │   • 依赖: RT_Elem_Core(RT_Mat_Core已废弃)/RT_Mesh_Brg/RT_Mesh_Util/RT_Sect
│   │
│   ├── 📝 设计意图: 运行时网格操作辅助(节点/单元索引重映射+DOF编号+坐标更新+装配协调)
│   ├── 📐 功能范围: DOF编号策略(RCM重排序)+网格分区+稀疏格式(CSR/CSC/COO)+坐标更新+状态查询
│   ├── 📊 统计: 4文件(~52KB) | 10TYPE | 31子程序 | 非热路径(仅初始化/自适应阶段)
│   ├── ⚠️  推断清单差异: 6规划名称 vs 4实际文件, 无Core/API/Domain/GlobalNum/Sync, 采用Types+Proc+Impl+Sys四层分离
│
├── Output/                               [⭐ 输出]
│   ├── RT_Out_Types.f90                 → 四型定义(627行, 7TYPE+20方法)
│   │   • 职责: 输出运行时状态管理四型系统(Desc/State/Algo/Ctx)+扩展TYPE
│   │   • TYPE(Desc): RT_Out_Base_Desc(9字段: runtime_id/output_label/md_registry引用/field_req/hist_req/output_format/output_directory/file_prefix/is_active/is_initialized)
│   │   • TYPE(State): RT_Out_FieldState(12字段+3TBP: n_frames_written/time_last_due/inc_interval/buffer_active/suppress_this_inc/write_pending/Init/Reset/CheckTrigger)
│   │   • TYPE(State): RT_Out_HistState(10字段+3TBP: n_points_written/time_interval/data_buffer/buffer_active/Init/Reset/AddPoint)
│   │   • TYPE(Algo): RT_Out_Algo(13字段+2TBP: field_freq_incr/hist_freq_incr/field_freq_time/hist_freq_time/trigger_type/use_field_buffer/compress_output/split_by_step/max_file_size_mb/use_parallel_io/Init/SetFrequency)
│   │   • TYPE(Ctx): RT_Out_Ctx(13字段+2TBP: step_id/incr_id/iter_id/step_time/total_time/time_increment/is_first_incr/is_last_incr/is_step_end/is_analysis_end/force_field_write/force_hist_write/suppress_all_output/Init/Update)
│   │   • TYPE(扩展): RT_Out_Frame(17字段+3TBP: step_id/incr_id/time/dt/n_nodes/n_elements/node_coords(3,n)/node_displ(3,n)/node_velocity(3,n)/node_accel(3,n)/node_temp(n)/node_reaction(6,n)/elem_conn/max_nodes,n_elems/elem_stress(6,n)/elem_strain(6,n)/elem_energy(n)/elem_statev(n_statev,n)/n_field_vars/field_var_names/field_var_data/is_valid/coords_updated/displ_updated/Init/Allocate/Clear)
│   │   • TYPE(扩展): RT_Out_Buffer(8字段+5TBP: capacity/size/head/tail/data/indices/is_full/needs_flush/Init/Push/Pop/Flush/Clear)
│   │   • TYPE(扩展): RT_Out_TriggerCtx(7字段+1函数: trigger_type/curr_incr/curr_time/last_triggered_incr/last_triggered_time/incr_interval/time_interval/ShouldTrigger)
│   │   • 常量: RT_OUT_FMT_*(VTK/HDF5/ODB/ASCII共4格式)+RT_OUT_TRIG_*(INCREMENT/TIME/STEP_END/ANALYSIS_END共4触发)+RT_OUT_POS_*(INTEGRATION_PT/NODE/ELEMENT/WHOLE_MODEL共4位置)
│   │
│   ├── RT_Out_Proc.f90                  → SIO接口封装(312行, 5接口+10I/O结构体)
│   │   • 职责: 输出运行时管理公共接口定义(结构化I/O类型+抽象接口)
│   │   • I/O对(5): RT_Out_Init/Collect/Write/CheckFreq/Finalize
│   │   • 抽象接口: 5组ABSTRACT INTERFACE定义
│   │
│   ├── RT_Out_Impl.f90                  → 实现逻辑(318行, 5子程序+1辅助)
│   │   • 职责: 输出系统初始化+数据收集+频率检查+写入路由+终化清理
│   │   • 公共接口(5): RT_Out_Impl_Init/Collect/CheckFreq/Write/Finalize
│   │   • 辅助函数(1): ITOA(整数转字符串, RT_Out_Impl_Write内含)
│   │   • 委托模式: Write路由到L2_NM Writers(HDF5/ODB/VTK, 当前STUB占位)
│   │
│   ├── RT_Out_Core.f90                  → 输出核心调度(1045行, 4TYPE+10子程序)
│   │   • 职责: 工业化输出系统(高性能数据收集+多格式输出+频率控制+内存池)
│   │   • TYPE(4): RT_Out_Frame/RT_Out_Cfg/RT_Out_State/RT_Out_Buf
│   │   • 公共接口(6): RT_Out_Init/Inc/BuildFrame/WriteFrame/Finalize/ChkFreq
│   │   • 扩展API(1): RT_Out_UnifMgr(统一管理接口)
│   │   • 性能策略: Block I/O批量写入+Memory Pool内存池+Lazy Evaluation懒评估+Stride-1连续访问
│   │   • 常量: MAX_FLD_VARS(50)/MAX_HIST_VARS(100)/BUF_SIZE(1024)
│   │
│   ├── RT_Out_Restart.f90               → 重启文件(303行, 2子程序)
│   │   • 职责: 检查点保存/恢复(二进制序列化/反序列化)
│   │   • 公共接口(2): RT_Out_RestartSave/RT_Out_RestartRestore
│   │   • 文件格式: 二进制流(FORM='UNFORMATTED', ACCESS='STREAM')
│   │   • 文件头: fileVer(4B)+timestamp(4B)+dataSize(4B)
│   │   • 数据段: u/v/a数组(8B*dataSize)+Step状态(20B)+收敛历史(16B)+checksum(4B)
│   │   • 委托: L1_IF/IO(IF_FileHandle)文件操作
│   │
│   ├── RT_Writer_HDF5.f90               → HDF5写入器(247行, 3子程序+1函数)
│   │   • 职责: HDF5格式输出(当前使用二进制流占位, 未集成真实HDF5库)
│   │   • 公共接口(3): RT_Writer_HDF5_Init/WriteFrame/Close
│   │   • 辅助函数(1): RT_Writer_HDF5_IsAvailable(检查库可用性, 返回.FALSE.)
│   │   • HDF5结构: /metadata(step_id/incr_id/time)+/mesh(coordinates/connectivity)+/fields(field_1/field_2/...)+/element_data(stress/strain)
│   │   • STUB状态: 真实HDF5 API已注释(USE hdf5), 当前使用OPEN/WRITE二进制流模拟
│   │
│   ├── RT_Writer_ODB.f90                → ODB写入器(337行, 4子程序+1函数)
│   │   • 职责: ABAQUS ODB格式输出(当前使用二进制流占位, 未集成真实ODB API)
│   │   • 公共接口(4): RT_Writer_ODB_Init/WriteModelInfo/WriteFrame/Close
│   │   • 辅助函数(1): RT_Writer_ODB_IsAvailable(检查库可用性, 返回.FALSE.)
│   │   • ODB文件头: ODB_MAGIC(Z'19700614', 4B)+ODB_VERSION(48, 4B)+flags(4B)+timestamp(8B)
│   │   • ODB结构: /FRAME header+FRAME metadata+NODE coordinates+ELEMENT data+FIELD variables+FRAME end
│   │   • 字段类型: ODB_FIELD_SCALAR(1)/VECTOR(2)/TENSOR(3)
│   │   • STUB状态: 真实ODB API已注释(USE odb_api), 当前使用OPEN/WRITE二进制流模拟
│   │
│   ├── 📝 设计意图: 输出请求→文件全流程(场变量抽取+历史变量记录+检查点保存/恢复)
│   ├── 📐 功能范围: 4输出格式(VTK/HDF5/ODB/ASCII)+4触发策略(增量/时间/步末/分析末)+缓冲I/O+重启检查点
│   ├── 📊 统计: 7文件(~115KB) | 11TYPE | 27子程序 | 部分热路径(场输出在增量步末)
│   ├── ⚠️  推断清单差异: 6规划名称 vs 7实际文件, 无API/Frame/Export/Sync, 采用Types+Proc+Impl+Core+Restart+Writers多层架构
│
├── Solver/                               [⭐ 求解器]
│   ├── RT_Solv_Types.f90                → 运行时四型(541行, 6TYPE)
│   │   • 职责: 求解器运行时四型系统(Desc/State/Algo/Ctx)+收敛评估
│   │   • TYPE(Desc): RT_Solv_Base_Desc(12字段: runtime_id/solver_label/md_linear指针/md_nr指针/md_precond指针/linear_method/nr_strategy/n_dofs_total/n_eqns/is_initialized/is_active/unsymmetric_system)
│   │   • TYPE(State): RT_Solv_NRState(10字段+3TBP: curr_iter/max_iter/residual_norm/energy_norm/displ_norm/nr_status/is_converged/is_diverged/Init/Reset/Update)
│   │   • TYPE(State): RT_Solv_LinearState(10字段+3TBP: n_dofs/method/n_iterations/residual_norm/is_converged/iter_status/alloc_status/Init/Reset/Update)
│   │   • TYPE(Algo): RT_Solv_Algo(15字段: linsol_method/nr_tangent_strategy/linsol_tolerance/linsol_max_iter/nr_tolerance/nr_max_iter/nr_energy_tol/nr_displ_tol/nr_conv_norm_type/linsol_unsymmetric/precond_method/precond_fill_level/cutback_on_divergence/adapt_time_step/status)
│   │   • TYPE(Ctx): RT_Solv_Ctx(10字段: n_dofs/n_elements/n_nodes/step_id/incr_id/curr_time/time_increment/is_first_incr/is_last_incr/is_step_end)
│   │   • TYPE(扩展): RT_Solv_ConvergenceCtx(10字段+1函数: curr_iter/max_iter/residual_norm/energy_norm/displ_norm/initial_residual/tolerance/rel_tolerance/abs_tolerance/IsConverged)
│   │   • 常量: RT_SOLV_NR_*(FULL/MODIFIED/INITIAL共3策略)+RT_SOLV_LINSOL_*(DIRECT/CG/GMRES/BICGSTAB共4方法)+RT_SOLV_NORM_*(L2/LINF/L1共3范数)+RT_SOLV_STATUS_*(6状态码)
│   │
│   ├── RT_Solv_Type.f90                 → 共享类型(177行, 7TYPE+别名)
│   │   • 职责: 求解器共享类型定义(CSR矩阵/DOF映射/配置/状态)+时间积分/非线性求解器高级类型
│   │   • TYPE(核心): RT_CSRMatrix(5字段: nRows/nCols/nnz/col_ptr/row_idx/values)
│   │   • TYPE(扩展): RT_Sol_Cfg(25字段: solver_type/linsol_type/nl_solver_type/time_int_method/dt/min_dt/max_dt/nr_max_iter/nr_tolerance/conv_method/output_freq/parallel_mode/n_threads/energy_check/line_search/arc_length/...) 
│   │   • TYPE(扩展): RT_Sol_State(20字段+3TBP: u/v/a/f_ext/f_int/K_global/residual/n_dofs/n_eqns/n_converged/incr_status/iter_status/total_time/Init/Destroy/Clear)
│   │   • TYPE(扩展): RT_Sol_DofMap(8字段: n_nodes/n_dofs_per_node/n_total_eq/eqToLocal/nodeEqStart/bcEqMask/freeEqMap/n_active_eqs)
│   │   • TYPE(扩展): RT_AdvancedTimeIntegrator(18字段: method/dt/time/step/beta/gamma/alpha/alpha_m/alpha_f/gamma_ga/beta_ga/u_n/v_n/a_n/u_np1/v_np1/a_np1/coeffs)
│   │   • TYPE(扩展): RT_AdvancedNLSol(14字段: method/tol/max_iter/ls_max_iter/ls_tolerance/arc_length_method/arc_length_radius/lambda/dlambda/bfgs_memory_size/convergence_type/line_search_type/n_iterations/is_converged)
│   │   • 类型别名: RT_Solv_Cfg/SolCfg(包装RT_Sol_Cfg)+RT_Solv_DofMap/SolDofMap(包装RT_Sol_DofMap)
│   │   • 委托: RT_Shared_Type(L2_NM)实际定义,本模块仅重导出
│   │   • 常量: RT_EQ_METHOD_*(NE/MO/LB/QU共4平衡方法)+RT_SOL_LINSOL_*(A/AGMG/D/I/S共5线性)+RT_SOL_MAT_*(CSR/DENS共2矩阵)
│   │
│   ├── RT_Solv_Proc.f90                 → SIO接口封装(320行, 5接口+10I/O结构体)
│   │   • 职责: 求解器运行时管理公共接口定义(结构化I/O类型+抽象接口)
│   │   • I/O对(5): RT_Solv_Init/Equilibrium/Linear/Convergence/Cutback
│   │   • 抽象接口: 5组ABSTRACT INTERFACE定义(六参数签名: desc/state/algo/ctx/inp/out)
│   │   • 设计: 遵循UFC Principle #14 v2.0(六参数约定+INTENT禁令+NON_OWNING_PTR注释)
│   │
│   ├── RT_Solv_Impl.f90                 → 实现逻辑(391行, 5子程序)
│   │   • 职责: 求解器运行时操作实现(初始化+平衡迭代+线性求解+收敛评估+时间步回溯)
│   │   • 公共接口(5): RT_Solv_Impl_Init/Equilibrium/Linear/Convergence/Cutback
│   │   • 设计模式: Thin Adapter(薄适配层),L5_RT路由到L2_NM数值求解器
│   │   • 委托: 调用NM_Solver_Core(L2_NM)底层数值算子
│   │
│   ├── RT_Solv_Core.f90                 → 求解器核心(276.8KB, 7787行, 海量接口)
│   │   • 职责: 非线性FEA分析求解器框架统一模块(聚合求解器API/类型/上下文/系统)
│   │   • 公共接口(60+): Bind/CheckConvergence/Clean/Clear/ClearStatus/Cfg/Destroy/Final/GetCurrentInc/GetCurrentIter/GetDofMap/GetElemStates/GetGlobalState/GetIncrement/GetIteration/GetModel/GetNodeStates/GetRes/GetSolver/GetSolverState/GetStatus/GetStep/GetSum/GetTws/Init/InitInc/IsConv/IsError/IsFailure/IsInit/IsOK/IsRunning/IsSuccess/...
│   │   • TYPE(4): RT_Sol_Ctx(Ctx)/RT_Sol_Cfg(Desc)/RT_Sol_State(State)/RT_Sol_DofMap(Ctx)
│   │   • 理论: K_T*du = -R(切线刚度×位移增量 = -残差), A*x = b(线性系统), 时间积分(Newmark/HHT/Central Difference)
│   │   • 依赖: L3_MD(MD_*/MD_IOSystem/MD_Step_Proc)+L2_NM(RT_Asm_Solv/RT_Solv_Sparse)+L1_IF(IF_Err_API/IF_Prec)
│   │   • 热路径: 是(每个增量步/迭代均调用,热路径零L3约束)
│   │
│   ├── RT_Solv_Lin_Core.f90             → 线性求解核心(317行, 10+接口)
│   │   • 职责: 线性方程组求解分发器(直接法/迭代法/预条件)
│   │   • 公共接口(10+): Clean/DisablePrefetching/EnablePrefetching/GetDescriptor/GetStatus/Init/RT_LinearSolver/RT_LinSolStatus/RT_LinearSolver_Solv/RT_Precond_*/RT_PCG_Solv_Block*
│   │   • 线性方法: DIRECT(1)/ITER(2)/MUMPS(3)/PARDISO(4)/AMG(5)/CG(6)/BICGSTAB(7)/GMRES(8)/PCG(9)/SUPERLU(10)
│   │   • 预条件: NONE(0)/JACOBI(1)/GAUSS(2)/ILU(3)/ICC(4)
│   │   • 内存模式: CPU(1)/GPU(2)/HYBRID(3)/ASYNC(4)
│   │   • 理论: Golub & Van Loan Matrix Computations §3 + Intel MKL PARDISO Guide
│   │
│   ├── RT_Solv_Nonlin.f90               → 非线性求解(1137行, Newton-Raphson/Arc-Length/Line Search)
│   │   • 职责: 平衡迭代非线性求解器(Newton-Raphson/Arc-Length Riks/Line Search)
│   │   • 核心算法: RT_NLSolver_NewtonRaph/RT_NLSolver_ArcLen/RT_NLSolver_LineSearch
│   │   • 理论: K_t*du = R(切线刚度×位移增量 = 残差), Arc-Length: ||du||² + ψ·Δλ² = Δs²
│   │   • 逻辑链: StepDriver → RT_Solv_Nonlin → RT_Asm_ComputeResidual/Tangent → RT_LinearSolver_Solv → RT_State_Step_*
│   │   • 计算链: Residual(r=F_ext-F_int) → Tangent(K_t=∂r/∂u) → Newton Solve(K_t·du=r) → Update(u+=du) → Convergence
│   │   • 数据链: Desc(MD_Step/MD_NonlinSolv配置) → Algo(容差/LineSearch参数) → State(u/v/R/迭代计数) → Ctx(局部缓冲区)
│   │   • 层级: ITERATION级别(增量步内循环),非Step/Increment管理
│   │
│   ├── RT_Solv_TimeInt_Core.f90         → 时间积分核心(1376行, 4方法)
│   │   • 职责: 时间积分方法(Newmark-β/HHT-α/Generalized-α/Central Difference)
│   │   • 公共接口: RT_TimeInt_Init/RT_TimeInt_Step/RT_TimeInt_Update/RT_TimeInt_AdaptiveStep/RT_TimeInt_ComputeEnergy
│   │   • TYPE(3): UF_TimeIntState(13字段: u_n/v_n/a_n/u_np1/v_np1/a_np1/t_n/t_np1/dt/dt_prev/step)+UF_TimeIntConfig(11字段)+UF_EnergyState(4字段)
│   │   • 方法常量: METHOD_HHT_ALPH(1)/METHOD_NEWMARK(2)/METHOD_CENTRAL(3)
│   │   • 理论: Newmark(1959) ASCE + Hughes The FEM §9 + ABAQUS Theory §2.4
│   │   • 参数: Newmark(β,γ), HHT-α(α∈[-1/3,0]), Generalized-α(ρ_∞→α_m,α_f)
│   │
│   ├── RT_Solv_Brg.f90                  → L2_NM桥接(960行, PARDISO/MUMPS/LAPACK封装)
│   │   • 职责: 桥接L2_NM数值求解层(PARDISO/MUMPS/LAPACK封装+PCG并行求解+MPI封装)
│   │   • 公共接口(20+): RT_ConvertCSR_From/ToNumCore/RT_UF_CSR_Free/RT_CSR_AnalyzeBandwidth_FromNumCore/RT_Precond_Create/CreateFromCfg/RT_DestroyPreconditioner/RT_LinearSolver_Iterative/Direct/Unified/AGMG/SparsePak/SparsePak_Reuse/RT_Cfg_To_UF_LinSolParams/RT_UF_LinSolResult_To_State/RT_Cfg_To_UF_NLParams/RT_UF_NLResult_To_State/RT_Solv_Bridge_Unified/Opt
│   │   • 委托: UF_LinearSolver(lin_solve/lin_solve_direct/lin_solve_cg/lin_solve_iccg/lin_solve_agmg/lin_solve_sparsepak)
│   │   • 委托: UF_NonlinSolv(NL_TYPE_NEWTON/NL_TYPE_LBFGS/NL_TYPE_MODIFIED_NR)
│   │   • 理论: Intel MKL PARDISO User Guide + MUMPS User Manual §3
│   │
│   ├── RT_Solv_Sparse_Core.f90          → 稀疏矩阵核心(675行, SpMV/分解/求解)
│   │   • 职责: 稀疏CSR矩阵操作(SpMV矩阵向量乘/LU分解/直接求解)
│   │   • 公共接口(15): RT_Triplet_Init/Add/Free/RT_CSR_FromTriplet/FromTripletMerged/RT_CSR_SpMV/AddToValue/RT_BlockCSR_FromTriplet/Free/RT_LU_Setup_FromCSR/Solv/Destroy/RT_LinearSolve_Direct/csr_init_from_coo
│   │   • TYPE(3): RT_LUHandle(3字段: A_L3/LU/isInitd)+RT_BlockCSRMatrix(3字段: nFields/fieldEqCount/blocks)+RT_COOEntry(继承自NM_Assem_Sparse)
│   │   • 理论: Barrett et al. Templates for Iterative Methods + Saad SPARSKIT
│   │   • 相位3: S5.1.2装配阶段写Triplet→转CSR(S5.3.1 BlockCSR支持numcore块结构)
│   │
│   ├── RT_Solv_Cont_Residual.f90        → 接触残差(365行, 接触+全局Newton-Raphson集成)
│   │   • 职责: 接触残差力集成到全局系统残差向量(隐式求解Newton-Raphson迭代)
│   │   • 公共接口(3): RT_Solv_Cont_AssembleGlobalResidual/UpdateContactState/CheckConvergence
│   │   • TYPE(2): RT_ContactData(5字段: slave_node_id/master_node_id/penetration_depth/contact_normal/penalty_stiffness/is_active)+RT_Solver_State(7字段: n_dofs/displacement/velocity/acceleration/reference_coords/row_ptr/col_idx/values)
│   │   • 数学模型: R_total(u) = R_internal(u) + R_contact(u) - R_external(λ)
│   │   • Newton线性化: K_tangent·Δu = -R_total, K_tangent = K_material + K_contact
│   │   • 理论: Wriggers Computational Contact Mechanics §6.1 + ABAQUS Theory §5.1
│   │
│   ├── RT_Solv_ABAQUS_Reg.f90           → ABAQUS注册(247行, 3核心分析类型)
│   │   • 职责: ABAQUS兼容求解器注册表(静态/显式动力/隐式动力)
│   │   • 公共接口(6): GetSolverById/GetSolverByKeyword/GetSolverCount/GetSolverCapabilities/ValidateSolverConfig/PrintSolverRegistry
│   │   • TYPE(1): ABAQUS_SolverRegistryEntry(15字段: solver_id/abaqus_keyword/abaqus_name/category/description/parser_module/unified_parse_proc/is_linear/is_dynamic/supports_nonlinear/supports_contact/supports_parallel/default_algorithm/default_tolerance/default_max_iterations)
│   │   • 注册表(3): STATIC(1,隐式静力,Newton-Raphson)+DYNAMIC EXPLICIT(2,显式动力,Central Difference)+DYNAMIC IMPLICIT(3,隐式动力,Newmark/HHT-α)
│   │   • 精简: 仅保留3种核心分析类型,移除解析器模块,直接调用RT_Solv_Nonlin/RT_DynExpl_Runner/RT_DynImpl_Runner
│   │
│   ├── RT_DofMapUtils.f90               → DOF映射工具(75行, 3函数)
│   │   • 职责: DOF映射查询工具函数(节点ID+局部DOF→全局方程ID映射)
│   │   • 公共接口(3): UF_GetEqId/UF_GetEqIdByDofType/RT_GetEqId
│   │   • STUB状态: 返回0占位,生产环境应查询dofMap%nodeToEq(node_id,dof_local)
│   │   • 使用者: MD_Cont_RT_Brg(RT_GetEqId)+MD_LoadBC_RT_Brg(UF_GetEqId/UF_GetEqIdByDofType)
│   │
│   ├── AI_ConvPredict_Algo.f90          → AI收敛预测(179行, 插槽②STUB)
│   │   • 职责: AI收敛预测算法插槽(Newton迭代收敛预测+自适应阻尼加速)
│   │   • 公共接口(4): AI_ConvPredict_Init/Finalize/Update/Predict
│   │   • TYPE(1): AI_ConvPredict_Type(13字段: predictor_type/tolerance/max_iterations/history_window/res_history(32)/history_index/rnn_hidden_dim/rnn_weights/aitken_relax_factor/use_adaptive_relax/prediction_time/total_predictions/successful_predictions)
│   │   • 预测器类型: 0=Aitken外推, 1=Krylov子空间, 2=AI-RNN神经网络
│   │   • STUB状态: AI P0占位符,待AI P1-A阶段实现真实预测逻辑
│   │   • 设计: 固定大小残差历史数组res_history(32)(符合AP-8约束)
│   │
│   ├── UF_CoreMemPool.f90               → 核心内存池(290行, 求解器热路径内存管理)
│   │   • 职责: 求解器热路径核心内存池(命名槽位分配/释放,避免热路径系统ALLOCATE)
│   │   • 公共接口(6): g_core_mem_pool(单例)/CoreMemPool_AllocDP1D/CoreMemPool_AllocInt1D/CoreMemPool_Dealloc + TBP(Init/AllocDP1D/AllocInt1D/Dealloc/Reset/Finalize)
│   │   • TYPE(2): CMP_Slot_t(5字段: active/kind/key/rptr/iptr)+UF_CoreMemPool_t(5字段+6TBP: initialized/capacity/used/slots/TBP)
│   │   • 容量: CMP_MAX_SLOTS=512命名槽位, CMP_KEY_LEN=64最大键长
│   │   • STUB状态: 当前使用标准ALLOCATE/DEALLOCATE,内存池功能待激活
│   │
│   ├── 📝 设计意图: 三类核心分析求解算法(线性直接/迭代法+非线性Newton-Raphson+时间积分Newmark/HHT/Central Difference),调用L2_NM数值库
│   ├── 📐 功能范围: 线性求解(DIRECT/CG/GMRES/BICGSTAB/PARDISO/MUMPS)+非线性(Newton-Raphson/Arc-Length Riks/Line Search/BFGS)+时间积分(Newmark-β/HHT-α/Generalized-α/Central Difference)+稀疏矩阵(CSR/BlockCSR/LU分解)+接触残差集成+DOF映射+内存池
│   ├── 📊 统计: 15文件(~500KB) | 30TYPE | 120+子程序 | 热路径(每增量步/迭代调用,零L3约束)
│   ├── ⚠️  推断清单差异: 6规划名称 vs 15实际文件, 无API/Linear/Nonlinear/Conv/Sync独立文件, 采用Types+Type+Proc+Impl+Core+Lin_Core+Nonlin+TimeInt_Core+Brg+Sparse_Core+Cont_Residual+ABAQUS_Reg+DofMapUtils+AI_ConvPredict+CoreMemPool多层架构
│   ├── ⚠️  STUB状态: RT_DofMapUtils(DOF映射返回0占位)+AI_ConvPredict_Algo(AI P0插槽待实现)+UF_CoreMemPool(内存池待激活)
│
├── StepDriver/                           [⭐ 步驱动]
│   ├── RT_StepDriver_Types.f90            → 四型定义(426行, 11TYPE)
│   │   • 职责: StepDriver域四大类TYPE(Desc/State/Algo/Ctx)+运行时配置+Hyplas兼容
│   │   • TYPE(Desc): RT_StepDriver_Desc(7字段: step_idx/step_id/category/solver_config_id/time_cfg/name)
│   │   • TYPE(Desc): RT_StepDriver_TimeCfg(6字段: t_start/t_end/dt_init/dt_min/dt_max/target_iter)
│   │   • TYPE(State): RT_StepDriver_State(6字段: current_step_idx/current_increment/current_iteration/current_time/current_load_factor/converged)
│   │   • TYPE(Algo): RT_StepDriver_Algo(6字段: max_iter/tol_residual/tol_displ/energy_tol/line_search/conv_mode)
│   │   • TYPE(Ctx): RT_StepDriver_Ctx(3字段: work_vec指针/temp_scalar/pool_slot)
│   │   • TYPE(扩展): RT_StepDriver_Result(10字段: success/converged/total_increments/total_iterations/total_cutbacks/final_time/final_load_factor/cpu_time/message)
│   │   • TYPE(扩展): RT_StepRuntimeCfg(3字段: time_cfg/algo/category)
│   │   • TYPE(Hyplas): RT_StepDTCtrl(3字段: grow_factor/cutback_factor/strategy)
│   │   • TYPE(Hyplas): RT_ImplicitStepCfg(3字段: time_cfg/nl_cfg/dt_ctrl)
│   │   • TYPE(Hyplas): RT_ExplicitStepCfg(2字段: time_cfg/dt_ctrl)
│   │   • TYPE(动力): RT_DynImpl_TimeCfg(12字段: t_start/t_end/dt_init/dt_min/dt_max/integration_scheme/beta/gamma/alpha/alpha_rayleigh/beta_rayleigh)
│   │   • 常量: STEP_CAT_STD(1)/IMPL(2)/EXPL(3)+INTEG_NEWMARK_BETA(1)/HHT_ALPHA(2)/CENTRAL_DIFF(3)
│   │
│   ├── RT_StepDriver_Ctx.f90              → 上下文快照(222行, 6TYPE+4子程序)
│   │   • 职责: 轻量级上下文快照(热路径零L3迁移核心),替代直接USE MD_*
│   │   • 设计: 冷路径填充快照(指针别名零拷贝),热路径只读快照
│   │   • 数据流: [冷路径]StepInit→RT_StepCtx_Init→[热路径]迭代循环只读ctx%mesh/mat/loadbc
│   │   • TYPE(6): RT_NodeDOFMap(2字段)+RT_MeshSnapshot(4字段+1TBP:Build)+RT_MatDescSnapshot(2字段)+RT_LoadBCDescSnapshot(3字段)+RT_Step_Ctx(6字段+2TBP:Init/Finalize)+RT_Inc_Ctx(6字段+2TBP:Init/Finalize)+RT_Iter_Ctx(5字段)
│   │   • 公共接口(4): RT_Step_Ctx_Init/Finalize+RT_Inc_Ctx_Init/Finalize+RT_MeshSnapshot_Build
│   │
│   ├── RT_StepDriver_WS.f90               → 工作空间(190行, 6TYPE+1子程序)
│   │   • 职责: 运行时工作空间类型定义(所有权Owners+视图Ctx+线程ThreadWS+JobWS)
│   │   • 理论: UFC四链+三步(Step/Inc/Iter),Data Chain=结构体传递
│   │   • TYPE(6): JobMemEstimate(6字段)+JobWS(4字段)+StructWS(6字段)+UelPools(13字段)+ThreadWS(17字段)+Owners(8字段+1TBP:Init+FINAL)+Ctx(3字段)
│   │   • 公共接口(6): JobWS/StructWS/UelPools/ThreadWS/Owners/Ctx
│   │   • Owners: 拥有Model/State/workspaces所有权(每Job一个)
│   │   • Ctx: 非拥有视图,指针指向Owners/Job(无所有权)
│   │   • ThreadWS: 迭代级工作空间(u/R/K等缓冲区+PCG求解器workspace)
│   │
│   ├── RT_StepDriver_Exec.f90             → 驱动执行(792行, 三层状态机+配置域)
│   │   • 职责: 合并RT_StepDriver_Core(执行逻辑)+RT_StepDrv_Domain(状态机),统一Step/Increment/Iteration三层驱动编排
│   │   • 公共接口(9): RT_StepDriver_Execute/RunDynamicExplicit/RunDynamicImplicit/StepDriverContext/StepState/RT_StepDriver_ConfigDomain/StepDriver_Init/Finalize/RunStep/StepStateMachine/GetStepState/RunIncrement/InitIncrement/FinalizeIncrement
│   │   • TYPE(3): RT_StepDriver_Config(10字段)+StepState(9字段)+StepDriverContext(7字段)+RT_StepDriver_ConfigDomain(5字段+6TBP:Init/Finalize/AddConfig/GetConfig/BindStepRefs/GetStepRef)
│   │   • 状态枚举: STEP_STATE_INIT(0)/RUNNING(1)/INCREMENT(2)/ITERATION(3)/DONE(4)/FAILED(5)/ROLLBACK(6)
│   │   • Phase枚举: RT_PHASE_INIT/INCREMENT/CONVERGED/CUTBACK/FAILED/COMPLETED
│   │   • 依赖: MD_Step_Proc(AnalysisStep/StepStateData/MD_TimeIncrementControl/MD_ConvergenceCriteria)+RT_Asm_DofMap+RT_Solv_Lin_Core+RT_Solv_Nonlin+RT_Out_Core+RT_Out_Restart+RT_TimeStep_Control
│   │   • 热路径: 是(每个增量步均调用,热路径零L3约束)
│   │
│   ├── RT_StepDriver_Impl.f90             → 算法实现(436行, 显式/隐式动力+CFL工具)
│   │   • 职责: 合并显式/隐式动力学驱动实现(RT_DynExpl_Run+RT_DynImpl_Run)+CFL稳定性工具
│   │   • 公共接口(5): RT_DynExpl_Run/RT_DynImpl_Run/RT_Dyn_CFL_dt_central_diff/RT_Dyn_Estimate_omega_max_csr_lumped/RT_Dyn_Clamp_dt_cfl_csr
│   │   • 显式动力(Central Difference): v_{n+1/2} = v_{n-1/2} + dt·M^{-1}·F, u_{n+1} = u_n + dt·v_{n+1/2}
│   │   • 隐式动力(Newmark/HHT): M·a_{n+1} + C·v_{n+1} + F_int(u_{n+1}) = F_ext(t_{n+1}), Newton内循环+有效刚度K_eff
│   │   • CFL工具(3): dt_cfl = cfl_safety*2/ω_max(稳定性条件)+ω_max = √(K_max/M_min)(最高频率估计)+dt钳制(dt ≤ dt_cfl)
│   │   • 依赖: MD_Step_Proc(UF_DynamicParams/AnalysisStep/INTEG_NEWMARK_BETA/HHT_ALPHA)+RT_Solv_Type+RT_Asm_Solv+RT_Asm_MassDamp_Core+RT_Solv_Lin_Core+RT_StepDriver_Types
│   │
│   ├── AI_StepCtr_Algo.f90                → AI步长控制(189行, 插槽①STUB)
│   │   • 职责: AI自适应步长控制器(基于解历史预测最优时间增量)
│   │   • 公共接口(4): AI_StepCtr_Init/Finalize/Predict/Update
│   │   • TYPE(1): AI_StepCtr_Type(14字段: controller_type/initial_dtime/min_dtime/max_dtime/target_its/growth_factor/shrink_factor/error_tolerance/history_window/time_history(:)/error_history(:)/its_history(:)/pid_kp/ki/kd/total_steps/rejected_steps/avg_its_per_step)
│   │   • 控制器类型: 0=PID控制器, 1=HR2控制器, 2=AI-PID神经网络
│   │   • STUB状态: AI P0-B占位符,待AI P0-B阶段实现真实预测逻辑
│   │   • 设计: 固定大小历史缓冲区(AP-8合规),支持PID增益配置
│   │
│   ├── 📝 设计意图: 3种核心计算(隐式静力/隐式动力/显式动力)的分析步/增量/迭代状态机+时间增量控制+收敛判断+Runner编排,调用L4数值核与L2求解器,协调Output/WriteBack
│   ├── 📐 功能范围: 三步嵌套(Step/Increment/Iteration)+三种Runner(Static/DynExpl/DynImpl)+配置管理(ConfigDomain)+上下文快照(Ctx)+工作空间(WS)+CFL稳定性+CUTBACK回溯+收敛判断+Output协调+Restart检查点
│   ├── 📊 统计: 6文件(~100KB) | 26TYPE | 30+子程序 | 热路径(每增量步均调用,零L3约束)
│   ├── ⚠️  推断清单差异: 6规划名称 vs 6实际文件, 无Core/API/Sequence/TimeStep_Adapt/Sync独立文件, 采用Types+Ctx+WS+Exec+Impl+AI_StepCtr精简架构, 已删除冗余Core/DynExplicit/Base_Core/StepCtx_Core(合并至Exec/Impl/WS/Ctx)
│   ├── ⚠️  STUB状态: AI_StepCtr_Algo(AI P0-B插槽待实现)
│   ├── 🔧 SMP贯通(v4.0): RT_StepDriver_Brg.f90单元循环!$OMP PARALLEL DO PRIVATE(ctx) SCHEDULE(DYNAMIC,64)
│
├── WriteBack/                            [⭐ 回写]
│   ├── RT_WB_Types.f90                  → 四型定义(571行, 6TYPE+12TBP)
│   │   • 职责: WriteBack域四大类TYPE(Desc/State/Algo/Ctx)+坐标变换上下文
│   │   • TYPE(Desc): RT_WB_Base_Desc(17字段+3TBP: runtime_id/wb_label/write_frequency/write_trigger/write_displacement/write_velocity/write_acceleration/write_stress/write_strain/write_reaction/write_contact_force/output_scope/output_node_ids/output_element_ids/use_local_coords/local_coord_sys_id/is_initialized/is_active/Init/SetOutputFields/SetScope)
│   │   • TYPE(State): RT_WB_ProgressState(13字段+4TBP: last_write_step/last_write_increment/total_writes/current_write_count/n_nodes_written/n_elements_written/n_gp_written/n_total_dofs/last_write_time/write_elapsed/avg_write_time/last_write_successful/n_write_failures/last_error_status/Init/Reset/UpdateProgress/RecordWriteTime)
│   │   • TYPE(State): RT_WB_BufferState(10字段+3TBP: node_buffer_size/elem_buffer_size/gp_buffer_size/node_buffer_cap/elem_buffer_cap/gp_buffer_cap/node_write_count/elem_write_count/gp_write_count/buffer_active/Init/Flush/Clear)
│   │   • TYPE(Algo): RT_WB_Algo(10字段: node_buffer_capacity/elem_buffer_capacity/gp_buffer_capacity/enable_batch_mode/batch_size_threshold/compression_level/checkpoint_compression/parallel_write/async_io_priority/max_write_retries)
│   │   • TYPE(Ctx): RT_WB_Ctx(12字段: step_id/incr_id/iter_id/curr_time/n_nodes/n_elements/n_total_dofs/write_displacement/write_stress/write_strain/use_local_coords/transform_ctx)
│   │   • TYPE(扩展): RT_WB_TransformCtx(8字段+2TBP: coord_sys_id/rotation_matrix(3,3)/translation_vec(3)/scale_factor/is_valid/Init/TransformVector/TransformTensor)
│   │   • 常量: RT_WB_TARGET_*(NODE_COORD/NODE_DISP/ELEM_STRESS/ELEM_STRAIN/NODE_REACT共5目标)+RT_WB_FIELD_*(U/V/A/S/E/RF共6场)+RT_WB_WRITE_*(EVERY_INC/STEP_END/USER_DEFINED共3频率)+RT_WB_SCOPE_*(ALL/SUBSET共2范围)
│   │
│   ├── RT_WB_Proc.f90                   → SIO接口封装(282行, 5接口+10I/O结构体)
│   │   • 职责: WriteBack运行时管理公共接口定义(结构化I/O类型)
│   │   • I/O对(5): RT_WB_Init/NodePos/NodeDisp/ElemStress/Checkpoint
│   │   • 设计: 遵循UFC Principle #14(结构化I/O+INTENT清晰+错误传播+Thin Adapter)
│   │   • 委托: L5_RT路由到L3_MD实际数据写入
│   │
│   ├── RT_WB_Impl.f90                   → 实现逻辑(303行, 5子程序)
│   │   • 职责: WriteBack运行时操作实现(初始化+节点坐标+节点位移+单元应力+检查点)
│   │   • 公共接口(5): RT_WB_Impl_Init/NodePos/NodeDisp/ElemStress/Checkpoint
│   │   • 设计模式: Thin Adapter(薄适配层),L5_RT委托L3_MD实际数据写入
│   │   • 零信任: 坐标写入前验证(ABS(coords) > 1.0e6→ERROR)
│   │   • 批处理: NodeDisp支持batch_mode(批量写入)
│   │   • STUB状态: MD_WB_*调用已注释(placeholder),待L3_MD实现后对接
│   │
│   ├── RT_WriteBack_Domain_Core.f90     → 回写核心(1083行, 20+接口+4TYPE)
│   │   • 职责: L5回写域核心(状态变量回写+检查点保存/恢复/回滚+审计+零信任)
│   │   • 公共接口(20+): WriteBack_Init/Finalize/WriteState/SaveCheckpoint/LoadCheckpoint/RollbackToCheckpoint/ValidateWriteBack/AuditWriteBack+RT_WriteBack_Init_Idx/SaveCheckpoint_Idx/LoadCheckpoint_Idx+RT_WriteBack_NodePos/NodePos_Idx/NodeDisp/NodeDisp_Idx/NodeDisp_Batch/NodeDisp_Batch_Idx/ElemStress/ElemStress_Idx/CurrentTime/CurrentTime_Idx+RT_WB_NodePos_Arg/NodeDisp_Arg/NodeDisp_Batch_Arg/ElemStress_Arg/CurrentTime_Arg+RT_WB_Init_Arg/SaveCheckpoint_Arg+RT_WB_Init_Arg_Standalone/SaveCheckpoint_Idx_Standalone/LoadCheckpoint_Idx_Standalone
│   │   • TYPE(4): CheckpointStatus(9字段: id/step/increment/iteration/time/checksum/valid/filepath/u(:))+WriteBackAuditRecord(7字段: record_id/operation_type/target_step/timestamp/data_checksum/success/description)+WriteBackWhitelistEntry(4字段: target_type/field_name/allow_partial/description)+WriteBackCtx(7字段+RT_WriteBack_Domain(5字段+2TBP: Init/Finalize)+RT_WB_Init_Arg/SaveCheckpoint_Arg/NodePos_Arg/NodeDisp_Arg/NodeDisp_Batch_Arg/ElemStress_Arg/CurrentTime_Arg
│   │   • 架构约束: G3-B FIX(L5 Init禁止调用MD_WB_Set*,md_layer只读)+N1-1(物理计算路由到L4_PH)
│   │   • 零信任: ZeroTrust验证+审计日志(AuditWriteBack)+检查点回滚(RollbackToCheckpoint)
│   │   • 依赖: PH_WriteBack_API(PH_WriteBack_ApplyNodeDisp/ApplyNodePos)+MD_WriteBack_API(MD_WB_Mesh_NodePos/Init_WriteBack_API/Finalize_WriteBack_API)+UFC_GlobalContainer_Core(g_ufc_global)
│   │   • 热路径: 部分(仅增量步末调用,低频)
│   │
│   ├── 📝 设计意图: 计算结果→模型树的回写(应力/应变/SDV映射到单元/节点+反力/能量汇总+与Output协调保存)
│   ├── 📐 功能范围: 5回写目标(节点坐标/位移/单元应力/应变/反力)+6场变量(U/V/A/S/E/RF)+3写频率(每增量/步末/用户定义)+检查点保存/恢复/回滚+零信任验证+审计日志+批处理+坐标变换
│   ├── 📊 统计: 4文件(~90KB) | 10TYPE | 30+子程序 | 部分热路径(仅增量步末调用)
│   ├── ⚠️  推断清单差异: 6规划名称 vs 4实际文件, 无Core/API/Checkpoint/ODB/Sync独立文件, 采用Types+Proc+Impl+Domain_Core精简架构, 功能内聚到Domain_Core(原规划的Core/Checkpoint/ODB/Sync合并)
│   ├── ⚠️  STUB状态: RT_WB_Impl(L3_MD MD_WB_*调用已注释占位)
│
└── RT_L5_LayerContainer_Core.f90        → L5层容器
```

**L5_RT 统计**: 13 域 | 0 子域 | 80+ 文件 | TYPE策略: **统一合并 `_Types.f90`（按需 USE）**

> **v3.0 优化**: 统一合并策略，所有 TYPE 放入 `_Types.f90`，按需 USE，简化架构决策

---

## 七、L6_AP — 应用层

```
L6_AP/
├── Bridge/                               [⭐ 桥接层]
│   ├── AP_Brg_L3.f90                    → L3桥接(354行, Re-Export模式)
│   │   • 职责: L6_AP→L3_MD跨层桥接(P0 Bridge),重新导出L3_MD所有公开接口
│   │   • 设计模式: Re-Export Pattern(避免L6_AP直接依赖L3_MD模块)
│   │   • 桥接域(11个):
│   │     - ModelTree: MD_ModelTree_DFS_Traverse/BFS_Traverse/QueryOptimize/BuildIndex/FindByPath/FindByType
│   │     - ModelCtx: MD_Model_Ctx
│   │     - Step: UF_StepDef/UF_StepManager/StepDesc/StepTree+PROC_*/NLGEOM_*/INTEG_*常量+Structured接口(Init/SetProcedure/SetTime/SetNLGeom/SetIncrement)
│   │     - Material: UF_MaterialDef/MD_Mat_Desc/MatDesc/MaterialDesc+弹性/塑性/超弹性/损伤/复合材料Desc+UMAT接口
│   │     - Section: UF_SectionDef/UF_SectionDBType+SECTION_*/SHELL_*/BEAM_*常量+Structured接口
│   │     - LoadBC: LoadDef/BCDef/UF_BCDef/UF_CLoadDef/UF_DLoadDef/UF_BodyForceDef/UF_ThermalLoadDef+BC_*/DIST_*常量
│   │     - Part: UF_PartDef/UF_Node/UF_Element+Structured接口
│   │     - Assembly: UF_Assem
│   │     - Instance: UF_Instance+Instance_SetTranslation/SetRotation
│   │     - Output: UF_FieldOutputDef/UF_HistoryOutputDef
│   │     - Contact: FrictionParams/ContactDef/ContactPairDef+contact_Mgr_init/add_pair/cleanup
│   │     - Keyword: KW_MetadataType/KW_ASTNodeType+KW_CAT_*/PARAM_TYPE_*常量+registry接口
│   │   • 桥接接口(3):
│   │     - MaterialDesc_Init_Structured_Wrapper: MD_Mat_Desc→UF_MaterialDef适配器包装
│   │     - MD_Mat_Desc_To_UF_MaterialDef: 遗留类型→结构化类型转换
│   │     - UF_MaterialDef_To_MD_Mat_Desc: 结构化类型→遗留类型转换
│   │
│   ├── AP_Brg_L4.f90                    → L4桥接(117行, 5子程序)
│   │   • 职责: L6_AP→L4_PH跨层桥接(P1 Bridge),物理结果查询+输出格式化
│   │   • 公共接口(5):
│   │     - Brg_AP_Get_Physical_Results: 按elem_id查询物理结果(刚度矩阵/残差/力向量)
│   │     - Brg_AP_Get_Physical_Results_FromCtx: 按PH_Elem_Ctx查询物理结果(完整实现)
│   │     - Brg_AP_Format_Output: 输出格式化(STUB占位)
│   │     - Brg_AP_Query_Element_Response: 按elem_id查询单元响应(STUB占位)
│   │     - Brg_AP_Query_Element_Response_FromCtx: 按PH_Elem_Ctx查询单元响应(完整实现)
│   │   • 重新导出类型: PH_Mat_Ctx+PH_Core类型(PH_Field_Type/PH_PhysCfg_Type/PH_FieldMgr_Type等9个控制类型)
│   │   • 数据转换: Ke矩阵二维→一维展开,Re向量直接复制
│   │
│   ├── AP_Brg_L5.f90                    → L5桥接(347行, 8子程序+1全局指针)
│   │   • 职责: L6_AP→L5_RT跨层桥接(P1 Bridge),求解器配置+作业状态+运行时查询
│   │   • 全局状态(1): g_brg_rt_ctx(RT_Drv_Ctx指针,用于StepRunner桥接)
│   │   • 求解器配置(2):
│   │     - Brg_AP_Configure_Solver: 基础接口(STUB占位,委托ToCtx版本)
│   │     - Brg_AP_Configure_Solver_ToCtx: 完整实现(解析solver_cfg字符串→设置RT_Sol_Cfg)
│   │       · 分析类型: static→隐式/dynamic→HHT-α/explicit→显式
│   │       · 求解器类型: iterative→RT_SOL_LINSOL_I/direct→RT_SOL_LINSOL_D/auto→RT_SOL_LINSOL_A
│   │   • 作业注入(2):
│   │     - Brg_AP_SetJobCtx_InContainer: 注入JobCtx到L6容器(g_ufc_global%ap_layer%SetJobCtx)
│   │     - Brg_AP_SetRTDrvCtx: 存储RT_Drv_Ctx到全局指针(供StepRunner使用)
│   │   • StepRunner桥接(1):
│   │     - Brg_AP_StepRunner_RT: 符合UF_Job_StepRunner_Ifc接口,stepIndex=1时调用RT_RunModel_Ctx执行全作业
│   │       · 返回AP_JOB_RT_FULL_JOB_DONE表示作业完成
│   │       · 错误码: -1(未初始化ctx/model/solver或stepIndex!=1)
│   │   • 状态查询(3):
│   │     - Brg_AP_Get_Job_Status: 基础接口(STUB占位)
│   │     - Brg_AP_Get_Job_Status_FromCtx: 从RT_Drv_Ctx查询作业状态码+消息
│   │     - Brg_AP_Query_Runtime_State: 基础接口(STUB占位)
│   │     - Brg_AP_Query_Runtime_State_FromField: 从RT_FieldState_Type查询场变量(u/v/a/T)
│   │   • 重新导出类型: RT_Step_Ctx/RT_Sol_Ctx/RT_Drv_Ctx/RT_RunModel_Ctx+UF_RT_JobStatus/UF_Model
│   │
│   ├── UF_Brg_L6_AP_Mat_Adapter.f90     → 材料适配器(173行, 3子程序)
│   │   • 职责: MD_Mat_Desc(遗留)↔UF_MaterialDef(结构化)双向转换适配器
│   │   • 设计模式: Adapter Pattern(类型兼容性桥接)
│   │   • 公共接口(3):
│   │     - MD_Mat_Desc_To_UF_MaterialDef: 遗留→结构化转换(354行AP_Brg_L3.f90调用)
│   │       · 字段映射: name/id/class_id→name/id/material_type, nStateV→num_statev
│   │       · 属性数组: props[]拷贝(截断保护,超过MAX_MATERIAL_PROPS报错)
│   │       · 弹性参数提取: props[1]=E, props[2]=ν, props[3]=G, props[4]=K, props[5]=density
│   │     - UF_MaterialDef_To_MD_Mat_Desc: 结构化→遗留转换
│   │       · 反向字段映射+动态内存分配(ALLOCATE/DEALLOCATE)
│   │     - MaterialDesc_Init_Structured_Wrapper: 三段式适配器(遗留→结构化→初始化→遗留)
│   │       · 流程: MD_Mat_Desc→UF_MaterialDef→MaterialDef_Init_Structured→MD_Mat_Desc
│   │
│   ├── 📝 设计意图: L6_AP→L3/L4/L5跨层桥接(Re-Export+Adapter+StepRunner模式)
│   ├── 📐 功能范围: 11L3域桥接+5L4物理查询+8L5运行时接口+材料双向适配器
│   ├── 📊 统计: 4文件(~17KB) | 0TYPE | 19子程序 | 全热路径桥接(零计算逻辑)
│   ├── ⚠️  推断清单差异: 2规划名称 vs 4实际文件, 无AP_Bridge_RT/Cfg, 采用L3/L4/L5分层桥接+材料适配器架构
│
├── Config/                               [⭐ 配置]
│   ├── AP_Cfg_Core.f90                  → 配置核心(236行, 2TYPE+4Arg+1Domain+8子程序)
│   │   • 职责: 配置文件解析+AI开关+资源限制+治理配置
│   │   • TYPE(2):
│   │     - AP_Config_State(11字段: configFile/workDir/aiEnabled/aiModelName/aiModelPath/aiConfidenceThreshold/resourceLimitsEnabled/maxCpuTime/maxDiskIO/maxThreads/auditLogging/auditLogPath)
│   │     - AP_Config_Ctrl(3字段: strictValidation/mergeOnLoad/maxVersionHistory)
│   │   • Arg类型(4, Phase B结构化I/O):
│   │     - AP_Config_LoadConfig_Arg: filename(IN)+status(OUT)
│   │     - AP_Config_SetResourceLimit_Arg: maxCpuTime/maxDiskIO/maxThreads(IN)+status(OUT)
│   │     - AP_Config_RegisterModelConfig_Arg: modelName/modelPath(IN)+status(OUT)
│   │     - AP_Config_GetSummary_Arg: summary(OUT)+status(OUT)
│   │   • TYPE(Domain): AP_Config_Domain(state+ctrl+initialized+6TBP)
│   │   • TBP方法(6): Init/Finalize/LoadConfig/SetResourceLimit/RegisterModelConfig/GetSummary
│   │   • 公共接口(4组, Wrapper+Impl双层):
│   │     - LoadConfig: AP_Config_Domain_LoadConfig(Wrapper)→AP_Config_LoadConfig_Impl(实现)
│   │     - SetResourceLimit: AP_Config_Domain_SetResourceLimit(Wrapper)→AP_Config_SetResourceLimit_Impl(实现)
│   │     - RegisterModelConfig: AP_Config_Domain_RegisterModelConfig(Wrapper)→AP_Config_RegisterModelConfig_Impl(实现)
│   │     - GetSummary: AP_Config_Domain_GetSummary(Wrapper)→AP_Config_GetSummary_Impl(实现)
│   │   • 配置层次: Global(系统级)→Job(作业级)→Step(步级)
│   │   • AI配置: AI开关(aiEnabled)+模型选择(aiModelName/Path)+置信度阈值(aiConfidenceThreshold=0.8)
│   │   • 资源限制: CPU时间(maxCpuTime)+磁盘IO(maxDiskIO)+线程数(maxThreads, 0=auto)
│   │   • 治理配置: 审计日志(auditLogging/Path)+严格验证(strictValidation)+版本历史(maxVersionHistory=100)
│   │
│   ├── AP_Config_Domain_Core.f90        → 配置核心(冗余副本, 236行, 与AP_Cfg_Core.f90内容相同)
│   │   • 状态: 冗余文件(模块名AP_Config_Domain_Core vs AP_Cfg_Core, 内容100%相同)
│   │   • 建议: 删除此文件,统一使用AP_Cfg_Core.f90
│   │
│   ├── 📝 设计意图: 应用层统一配置管理(配置加载+AI开关+资源限制+治理审计)
│   ├── 📐 功能范围: 配置文件解析+AI模型注册+资源限制设置+配置摘要生成+审计日志
│   ├── 📊 统计: 2文件(~18KB, 1冗余) | 3TYPE | 8子程序(4Wrapper+4Impl) | 冷路径(仅初始化阶段)
│   ├── ⚠️  推断清单差异: 3规划名称 vs 2实际文件, 无AP_Cfg_Parser/Validator, 采用单一Core文件+Arg结构化I/O模式
│   ├── ⚠️  冗余警告: AP_Config_Domain_Core.f90是AP_Cfg_Core.f90的冗余副本(内容100%相同, 仅模块名不同)
│
├── Input/                                [⭐ 输入]
│   ├── AP_Inp_Types.f90                 → 类型定义(57行, 2TYPE)
│   │   • 职责: Input域数据类型定义(关键字/命令条目+索引树)
│   │   • TYPE(2): ParsedKeywordEntry(5字段: keyword_id/line_number/name/category/has_data)+ParsedCommandEntry(8字段: id/cmd_id/keyword_idx/line/line_number/name/opt/params/param_str)
│   │   • 常量: AP_INPUT_KEYWORD_ID_INVALID/AP_INPUT_CMD_ID_INVALID/AP_INPUT_DOMAIN_KEYWORD/CMD
│   │
│   ├── AP_Inp_Mgr.f90                   → 管理器(103行, 7接口)
│   │   • 职责: Input域集合管理+查询+验证(委托AP_Input_Domain)
│   │   • 公共接口(7): Init/AddKeyword/AddCommand/GetKeyword/GetCmd/GetKeywordCount/GetCmdCount
│   │   • 委托模式: 所有接口委托到AP_Input_Domain%AddParsedKeyword/AddParsedCommand等
│   │
│   ├── Parser/                           [解析器子目录, 7文件]
│   │   ├── AP_Inp_Core.f90              → 解析核心(336行, 3TYPE+9TBP)
│   │   │   • TYPE(3): AP_Input_State(8字段: parseStatus/totalKeywords/parsedKeywords/nParseErrors/nParseWarnings/totalDataLines/currentLine/parseTime)
│   │   │   • TYPE(3): AP_Input_Ctrl(6字段: inputFilePath/jobName/validationLevel/echoInput/strictMode/continueOnError)
│   │   │   • TYPE(Domain): AP_Input_Domain(state+ctrl+parsed_keywords+parsed_commands+n_keywords+n_commands+initialized+9TBP)
│   │   │   • TBP(9): Init/Finalize/ParseKeyword/ValidateSyntax/GetSummary/AddParsedKeyword/AddParsedCommand/GetKeywordById/GetCmdById
│   │   ├── AP_Inp_Domain.f90            → 域实现(336行, 与AP_Inp_Core.f90内容相同, 冗余)
│   │   ├── AP_Inp_KWBrg.f90             → 关键字桥接(518行, 关键字→L3_MD映射)
│   │   ├── AP_Inp_Param.f90             → 参数解析(221行, 参数键值对解析)
│   │   ├── AP_Inp_Parser_Util.f90       → 解析工具(193行, 字符串处理工具)
│   │   ├── AP_Parser_Include.f90        → Include解析(219行, *INCLUDE文件包含)
│   │   └── AP_Parser_Util.f90           → 解析工具(188行, 与AP_Inp_Parser_Util.f90功能重叠)
│   │
│   ├── Command/                          [命令处理器子目录, 51文件]
│   │   ├── AP_Inp_Type.f90              → 命令类型(262行, Cmd/CmdCtx/Proc/CmdList等TYPE)
│   │   ├── AP_Inp_Domain.f90            → 命令域(336行, AP_Cmd_Domain域管理)
│   │   ├── AP_Inp_CmdMgr.f90            → 命令管理器(120行, 命令注册+查找)
│   │   ├── AP_Inp_MemMgr.f90            → 内存管理器(123行, 命令内存池)
│   │   ├── AP_Inp_ConstCore.f90         → 约束核心(615行, *BOUNDARY/*EQUATION/*TIE)
│   │   ├── AP_Inp_Step.f90              → 分析步(523行, *STEP/*STATIC/*DYNAMIC)
│   │   ├── AP_Inp_Mat.f90               → 材料基础(892行, *ELASTIC/*PLASTIC/*DENSITY)
│   │   ├── AP_Inp_MatAdv.f90            → 材料高级(856行, *CREEP/*VISCOELASTIC/*HYPERELASTIC)
│   │   ├── AP_Inp_MatBrittle.f90        → 脆性材料(598行, *BRITTLE CRACKING/FAILURE)
│   │   ├── AP_Inp_MatConc.f90           → 混凝土材料(539行, *CONCRETE DAMAGED PLASTICITY)
│   │   ├── AP_Inp_MatDmg.f90            → 损伤材料(389行, *DAMAGE INITIATION/EVOLUTION)
│   │   ├── AP_Inp_MatFoam.f90           → 泡沫材料(438行, *HYPERFOAM/*DENSIFY)
│   │   ├── AP_Inp_MatGeo.f90            → 地质材料(467行, *MOHR-COULOMB/*DRUCKER-PRAGER)
│   │   ├── AP_Inp_MatGeoAdv.f90        → 地质高级(364行, *CAM-CLAY/*JOINTED ROCK)
│   │   ├── AP_Inp_MatHyper.f90          → 超弹性材料(547行, *MOONEY-RIVLIN/*OGDEN/*ARRUDA-BOYCE)
│   │   ├── AP_Inp_MatPorous.f90         → 多孔材料(671行, *POROUS ELASTIC/*CRUSHABLE FOAM)
│   │   ├── AP_Inp_MatShear.f90          → 剪切材料(447行, *SHEAR FAILURE/*JOHNSON-COOK)
│   │   ├── AP_Inp_MatSpec.f90           → 特殊材料(943行, *USER MATERIAL/*SHAPE MEMORY)
│   │   ├── AP_Inp_MatTherm.f90          → 热材料(734行, *CONDUCTIVITY/*SPECIFIC HEAT/*EXPANSION)
│   │   ├── AP_Inp_Sect.f90              → 截面基础(635行, *SOLID SECTION/*SHELL SECTION/*BEAM SECTION)
│   │   ├── AP_Inp_SectAdv.f90           → 截面高级(407行, *COMPOSITE LAYUP/*GENERAL SECTION)
│   │   ├── AP_Inp_SectFull.f90          → 完整截面(489行, *BEAM GENERAL SECTION)
│   │   ├── AP_Inp_Ldbc.f90              → 载荷边界(2078行, *CLOAD/*DLOAD/*PRESSURE/*BOUNDARY/*TEMPERATURE)
│   │   ├── AP_Inp_LdbcAdv.f90           → 载荷高级(258行, *Dsflux/*Film/*Radiate)
│   │   ├── AP_Inp_Mesh.f90              → 网格(450行, *NODE/*ELEMENT/*NSET/*ELSET)
│   │   ├── AP_Inp_PartAssem.f90         → 部件装配(399行, *PART/*ASSEMBLY/*INSTANCE)
│   │   ├── AP_Inp_Geom.f90              → 几何(593行, *SURFACE/*CURVE/*VERTEX)
│   │   ├── AP_Inp_Interact.f90          → 相互作用(434行, *CONTACT PAIR/*SURFACE INTERACTION)
│   │   ├── AP_Inp_Cont.f90              → 接触(566行, *CONTACT/*CLEARANCE/*TIE)
│   │   ├── AP_Inp_Conn.f90              → 连接(918行, *CONNECTOR/*COUPLING/*MPC)
│   │   ├── AP_Inp_Dyn.f90               → 动力(688行, *DYNAMIC/*FREQUENCY/*MODAL)
│   │   ├── AP_Inp_Init.f90              → 初始条件(493行, *INITIAL CONDITIONS/*TEMPERATURE)
│   │   ├── AP_Inp_InitCore.f90          → 初始核心(389行, *INITIAL STRESS/*STATE)
│   │   ├── AP_Inp_Predef.f90            → 预定义场(382行, *PREDEFINED FIELD)
│   │   ├── AP_Inp_Phys.f90              → 物理场(603行, *COUPLED THERMAL-ELECTRICAL)
│   │   ├── AP_Inp_Field.f90             → 场输出(201行, *FIELD OUTPUT)
│   │   ├── AP_Inp_Output.f90            → 输出(555行, *OUTPUT/*FIELD/*HISTORY)
│   │   ├── AP_Inp_Out.f90               → 输出基础(314行, *NODE PRINT/*EL PRINT)
│   │   ├── AP_Inp_OutAdv.f90            → 输出高级(377行, *CONTACT PRINT/*ENERGY PRINT)
│   │   ├── AP_Inp_OutHigh.f90           → 输出高级(444行, *EL FILE/*NODE FILE)
│   │   ├── AP_Inp_Amp.f90               → 幅值(225行, *AMPLITUDE/*TABULAR/*PERIODIC)
│   │   ├── AP_Inp_Solv.f90              → 求解器(155行, *SOLVER CONTROLS)
│   │   ├── AP_Inp_Spec.f90              → 特殊(182行, *MODEL/*RESTART)
│   │   ├── AP_Inp_SpecAdv.f90           → 特殊高级(317行, *PARAMETER/*SENSITIVITY)
│   │   ├── AP_Inp_ElemSpcl.f90          → 单元特殊(287行, *ELEMENT OUTPUT/*SECTION PRINT)
│   │   ├── AP_Inp_Orient.f90            → 方向(298行, *ORIENTATION/*DISTRIBUTION)
│   │   ├── AP_Inp_Post.f90              → 后处理(404行, *VIEWCUT/*PATH/*XY DATA)
│   │   └── COMMAND_INDEX_FLAT_MIGRATION.md → 迁移文档(185行)
│   │
│   ├── Script/                           [脚本引擎子目录, 17文件]
│   │   ├── AP_Inp_Script.f90            → 脚本门面(348行, Facade模式重新导出所有子模块)
│   │   ├── AP_Inp_Script_API.f90        → 脚本API(672行, 统一API接口)
│   │   ├── AP_Inp_Script_Parser.f90     → 脚本解析(571行, CmdParser/ParseLine/ParseFile/ParseString)
│   │   ├── AP_Inp_Script_Registry.f90   → 脚本注册(347行, CmdReg/Cmd_Init/Cmd_Reg/Cmd_Find)
│   │   ├── AP_Inp_Script_Executor.f90   → 脚本执行(518行, CmdExec/Cmd_ExecList/Cmd_InitStacks)
│   │   ├── AP_Inp_Script_Subst.f90      → 变量替换(324行, Cmd_Subst/Cmd_SetVar/Cmd_GetVar)
│   │   ├── AP_Inp_Script_Valid.f90      → 脚本验证(132行, Cmd_Valid/Cmd_FormatError)
│   │   ├── AP_Inp_Script_Help.f90       → 脚本帮助(135行, Cmd_HelpShow/Cmd_HelpSearch)
│   │   ├── AP_Inp_Script_History.f90    → 历史记录(118行, CmdHistory)
│   │   ├── AP_Inp_Script_Logger.f90     → 脚本日志(194行, CmdLogger/g_logger)
│   │   ├── AP_Inp_Script_Debug.f90      → 脚本调试(148行, CmdDebugger/g_debugger)
│   │   ├── AP_Inp_Script_Alias.f90      → 别名管理(161行, CmdAliasMgr/g_alias_mgr)
│   │   ├── AP_Inp_Script_Label.f90      → 标签管理(131行, CmdLabelMgr/g_label_mgr)
│   │   ├── AP_Inp_Script_UFC.f90        → UFC命令(1223行, UFC专用命令注册)
│   │   ├── AP_Inp_Script_User.f90       → 用户命令(432行, 用户自定义命令)
│   │   ├── AP_Inp_Script_Proc.f90       → 过程处理(410行, 命令执行流程)
│   │   ├── AP_Inp_Script_Include.f90    → 脚本包含(缺失, 由AP_Parser_Include.f90替代)
│   │   └── AP_CMD_CORE_INTERNAL_REFACTOR_PLAN.md → 重构计划(148行)
│   │
│   ├── 📝 设计意图: ABAQUS输入文件解析+命令调度+脚本引擎(关键字解析→命令队列→模型构建)
│   ├── 📐 功能范围: 51命令处理器(Parser/Command)+17脚本引擎(Script)+7解析器(Parser)+2类型/管理器
│   ├── 📊 统计: 77文件(~520KB) | 10TYPE | 200+子程序 | 冷路径(仅预处理阶段)
│   ├── ⚠️  推断清单差异: 4规划名称 vs 77实际文件, 无AP_Inp_Core/Parser/Validator, 采用Parser/Command/Script三子目录架构
│   ├── ⚠️  冗余警告: AP_Inp_Domain.f90(Parser目录)是AP_Inp_Core.f90的冗余副本
│
├── Job/                                  [⭐ 作业]
│   ├── AP_Job_Core.f90                  → 作业核心(1715行, 8TYPE+24Arg+26接口)
│   │   • 职责: 作业级别执行编排(分析步调度+重启/失败策略+结果摘要)
│   │   • TYPE(8): AP_Job_Opts/JobOpts(作业选项)+AP_Job_Summary/JobSummary(作业摘要)+AP_Job_Ctx/JobCtx(作业上下文)+AP_Job_InitDesc_In/Out等24个Arg类型
│   │   • 回调接口(2): AP_Job_StepRunner_Ifc/UF_Job_StepRunner_Ifc(步级执行回调,由L5_RT提供)
│   │   • 结构化I/O(24组Arg): InitDesc/AttachMod/AddStep/BindCtx/SetOpts/PrepEnv/Run/RunNext/SaveChk/LoadChk/TryRestart/HandleFail/Final/BuildSum/QueryStat
│   │   • 公共接口(26+):
│   │     - 生命周期(5): AP_Job_InitDesc/AttachMod/AddStep/BindCtx/Final
│   │     - 执行控制(4): AP_Job_Run(运行全部步)/AP_Job_RunNext(运行下一步)/AP_Job_PrepEnv(准备环境)/AP_Job_SetOpts(设置选项)
│   │     - 检查点(3): AP_Job_SaveChk(保存检查点)/AP_Job_LoadChk(加载检查点)/AP_Job_TryRestart(尝试重启)
│   │     - 错误处理(1): AP_Job_HandleFail(失败处理策略)
│   │     - 查询(2): AP_Job_BuildSum(构建作业摘要)/AP_Job_QueryStat(查询作业状态)
│   │     - 统一接口(7): AP_Job_Unified_OptionsDefault/OptionsValidate/Cfg/Checkpoint/Execute/Query/StatusReport
│   │   • 作业选项: restartEnabled(重启开关)/checkOnly(仅检查)/postOnly(仅后处理)/maxSteps(最大步数)
│   │   • StepRunner返回码: AP_JOB_RT_FULL_JOB_DONE=-2(L5_RT桥接模式,一次调用完成全作业)
│   │
│   ├── AP_Job_Ctx.f90                   → 作业上下文(145行, 1TYPE+5TBP)
│   │   • 职责: 作业执行上下文定义(继承BaseCtx,包含应用配置+模型上下文+步上下文)
│   │   • TYPE(1, 继承BaseCtx): AP_Job_Ctx(app_ctrl/model_ctx/step_ctx/current_step/current_incr/total_steps/is_running/is_completed/success+5TBP)
│   │   • TBP(5): Init(初始化)/Cleanup(清理)/Reset(重置)/Bind(绑定上下文)/Valid(验证有效性)
│   │   • 设计模式: 继承BaseCtx(L6_AP层级标识ctx_level=6)
│   │   • 数据链: L3→L6三级索引(current_step=step_idx, current_incr=incr_idx)
│   │
│   ├── AP_Job_Domain.f90                → 作业域(317行, 3TYPE+6Arg+1Domain+8TBP)
│   │   • 职责: 作业上下文+运行控制+监控+回滚+资源计量
│   │   • TYPE(3):
│   │     - AP_Job_Metrics(9字段: cpuTime/wallTime/memoryUsed/memoryPeak/diskIO/nStepsCompleted/nIncrementsCompleted/nIterationsTotal/nRollbacks)
│   │     - AP_Job_State(7字段: jobId/jobName/status/totalSteps/currentStep/currentIncrIdx/progress+metrics)
│   │     - AP_Job_Ctrl(3字段: maxCpuTime/maxMemory/limitsSet)
│   │   • Arg类型(6): AP_Job_Run_Arg/Pause_Arg/Abort_Arg/RollbackToStep_Arg/RecordResource_Arg/GetSummary_Arg
│   │   • TYPE(Domain): AP_Job_Domain(state+ctrl+initialized+8TBP)
│   │   • TBP(8): Init/Finalize/Run/Pause/Abort/RollbackToStep/RecordResource/GetSummary
│   │   • 作业状态枚举(6): JOB_STATUS_INIT(0)/RUNNING(1)/PAUSED(2)/COMPLETED(3)/FAILED(4)/ABORTED(5)
│   │   • 生命周期: Init→Running→Paused→Running→Completed/Failed→Cleanup
│   │
│   ├── AP_Job_Util.f90                  → 作业工具(429行, 命令+错误码+文件IO)
│   │   • 职责: 统一作业域工具(命令解析+错误码+文件路径操作)
│   │   • 错误码(7000-7999, 应用层):
│   │     - 7000-7099: 作业执行(AP_ERROR_CODE_JOB_EXECUTION_FAILED/INITIALIZATION_FAILED)
│   │     - 7100-7199: 输入错误(AP_ERROR_CODE_INPUT_FILE_NOT_FOUND/PARSE_ERROR)
│   │     - 7200-7299: 输出错误(AP_ERROR_CODE_OUTPUT_WRITE_FAILED/FORMAT_ERROR)
│   │     - 7300-7399: 多物理场(AP_ERROR_CODE_MULTIPHYSICS_COUPLING_FAILED)
│   │     - 7400-7499: 网络错误(AP_ERROR_CODE_NETWORK_CONNECTION_FAILED/TIMEOUT)
│   │   • 命令工具(7): AP_Cmd_ValidateCommand/ParseParameters/ExtractName/ExtractOption/ExtractNumericParams/ExtractStringParams/FormatCommand
│   │   • 文件工具(7): AP_File_ReadLines/WriteLines/GetBasename/GetExtension/JoinPath/NormalizePath/IsAbsolutePath
│   │   • 依赖: AP_Inp_Script(命令注册)+IF_IO_File(文件IO)
│   │
│   ├── 📝 设计意图: 求解作业编排与生命周期管理(步级调度+检查点+重启+失败策略+资源计量)
│   ├── 📐 功能范围: 作业初始化/步序列编排/执行控制/检查点保存恢复/重启策略/失败处理/状态查询/资源计量
│   ├── 📊 统计: 4文件(~96KB) | 13TYPE | 40+子程序 | 冷路径(作业级调度,宏观时间尺度)
│   ├── ⚠️  推断清单差异: 4规划名称 vs 4实际文件, 无AP_Job_Types/Manager/Scheduler, 采用Core+Ctx+Domain+Util架构
│
├── Output/                               [⭐ 输出]
│   ├── AP_Out_Types.f90                 → 类型定义(58行, 2TYPE+ID常量)
│   │   • 职责: Output域数据类型定义(输出请求/帧条目+ID索引)
│   │   • TYPE(2): OutputRequestEntry(11字段: request_id/req_type/name/region/position/frequency/n_vars/variables/variable_str/step_id)+FrameEntry(5字段: frame_id/step_id/inc_id/time/request_id)
│   │   • ID常量(4): AP_OUTPUT_REQUEST_ID_INVALID/AP_OUTPUT_FRAME_ID_INVALID(无效ID)+AP_OUTPUT_REQ_FIELD/AP_OUTPUT_REQ_HISTORY(请求类型)
│   │   • 域ID(2): AP_OUTPUT_DOMAIN_REQUEST/AP_OUTPUT_DOMAIN_FRAME
│   │   • 设计模式: 索引树+扁平域双模式(与L3_MD对齐)
│   │
│   ├── AP_Out_Domain.f90                → 输出域(477行, 2TYPE+3Arg+1Domain+11TBP)
│   │   • 职责: 应用级输出管理(ODB文件写入+结果数据库管理+后处理格式导出+报告生成+结果摘要)
│   │   • TYPE(2): AP_Output_State(8字段: odbFileUnit/msgFileUnit/datFileUnit/staFileUnit/totalFrames/totalWriteBytes/totalWriteTime/odbOpen)+AP_Output_Ctrl(9字段: outputDir/jobName/primaryFormat/writeODB/writeMSG/writeDAT/writeSTA/compressODB)
│   │   • Arg类型(3, Phase B结构化I/O): AP_Output_OpenODB_Arg(2字段)+AP_Output_WriteFrame_Arg(7字段)+AP_Output_GetSummary_Arg(2字段)
│   │   • TYPE(Domain): AP_Output_Domain(state+ctrl+output_requests(:)+frames(:)+n_requests/n_frames/initialized+11TBP)
│   │   • TBP(11): Init/Finalize/OpenODB/WriteFrame/GetSummary/AddOutputRequest/AddFrame/GetRequestById/GetFrameById/GetRequestCount/GetFrameCount
│   │   • 输出格式枚举(5): AP_OUTFMT_ODB(1)/VTK(2)/CSV(3)/HDF5(4)/BINARY(5)
│   │   • 扁平域存储: output_requests(:)+frames(:)动态数组(支持64→128→256...自动扩容)
│   │   • 委托设计: AddOutputRequest/GetRequestById优先委托MD层(g_ufc_global%md_layer%output),MD未就绪时降级到本地存储
│   │   • 数据链: AP_Output_Domain%output_requests→MD_Output_Domain→RT_Out_Cfg(三级链路)
│   │   • 文件句柄管理: ODB/MSG/DAT/STA四文件句柄(ABAQUS标准输出文件)
│   │   • 统计信息: totalFrames/totalWriteBytes/totalWriteTime(输出性能监控)
│   │
│   ├── AP_Out_Format.f90                → 输出格式化(499行, 4Props+4Wrapper+20+子程序)
│   │   • 职责: 统一输出格式关键字解析(FILE_FORMAT/NODE_FILE/EL_FILE/PREPRINT)
│   │   • Props TYPE(4, 继承DescBase): AP_Output_Format_Props(formatType)+AP_Output_NodeFile_Props(fileName)+AP_Output_ElFile_Props(fileName)+AP_Output_Preprint_Props(echo/model)
│   │   • Wrapper TYPE(4): FormatProperties/NodeFileProperties/ElFileProperties/PreprintProperties(包装Props)
│   │   • FILE_FORMAT解析(3+): AP_Output_Format_Init/Valid/Clear/Parse/UnifiedParse/UnifiedCfg+Parse_FILE_FORMAT_Keyword/Valid_FILE_FORMAT_Keyword
│   │   • NODE_FILE解析(3+): AP_Output_NodeFile_Init/Valid/Clear/Parse/UnifiedParse/UnifiedCfg+Parse_NODE_FILE_Keyword/Valid_NODE_FILE_Keyword
│   │   • EL_FILE解析(3+): AP_Output_ElFile_Init/Valid/Clear/Parse/UnifiedParse/UnifiedCfg+Parse_EL_FILE_Keyword/Valid_EL_FILE_Keyword
│   │   • PREPRINT解析(3+): AP_Output_Preprint_Init/Valid/Clear/Parse/UnifiedParse/UnifiedCfg+Parse_PREPRINT_Keyword/Valid_PREPRINT_Keyword
│   │   • 其他(1): Valid_USER_OUTPUT_Keyword(用户输出验证)
│   │   • 依赖: AP_Brg_L3(KW_ASTNodeType)+AP_Output_UserOutput_Type
│   │   • 合并来源: AP_Output_Format+AP_Output_NodeFile+AP_Output_ElFile+AP_Output_Preprint(四合一)
│   │
│   ├── AP_Out_RT_Brg.f90                → L5_RT桥接(283行, 3接口+2转换)
│   │   • 职责: AP_Output_Domain↔RT_Output_Domain桥接(同步输出请求+类型转换)
│   │   • 同步接口(1): AP_Out_SyncToRT(同步output_requests到RT_Out_Cfg,优先MD层,降级AP层)
│   │   • 类型转换(2): AP_Out_EntryToFldReq(OutputRequestEntry→FldOutReq)+AP_Out_EntryToHistReq(OutputRequestEntry→HistOutReq)
│   │   • 变量解析(2): AP_Out_ParseVariableStr(解析"PRESELECT,U,S,PEEQ"→var_ids)+VarNameToId(变量名→ID映射,支持20种变量)
│   │   • 变量映射(20种): U(位移)/S(应力)/E(应变)/PEEQ(等效塑性应变)/RF(反力)/TEMP(温度)/V(速度)/A(加速度)/CF(集中力)/MISES(Mises应力)/PE(塑性应变)/EE(弹性应变)/ALLIE(内能)/ALLKE(动能)/ALLPD(塑性耗散)/ALLSE(应变能)
│   │   • 工具函数(1): ToUpper(字符串大写转换)
│   │   • 依赖: MD_Out_Ctx_Core(FldOutReq/HistOutReq)+RT_Out_Core(RT_Out_Cfg)
│   │   • 设计模式: 双源策略(MD层为单一数据源,AP层为降级备份)
│   │
│   ├── AP_PostProc_DataAnal.f90         → 数据分析(962行, 9TYPE+8接口)
│   │   • 职责: 后处理数据分析(路径提取+历史数据+统计+XY绘图+报告生成+数据导出)
│   │   • 管理器TYPE(1): DataAnalysisManagerType(12字段: odb_file/job_name/database_opened/available_data/num_steps/num_frames/num_field_outputs/num_history_outputs/active_step/active_frame/active_field/paths(:)/history_data(:)/field_statistics/history_statistics/xy_plots(:)/num_xy_plots/analysis_config/analysis_initialized+8TBP)
│   │   • 数据TYPE(6): AvailableDataType(5字段: field_variables/history_variables/step_numbers/step_names/step_times)+PathDataType(9字段: path_name/path_type/num_points/coordinates/distances/values/variable_name/step_number/step_time)+HistoryDataType(7字段: point_name/point_id/point_type/variable_name/num_components/times/values)+StatisticsType(9字段: min_value/max_value/mean_value/std_deviation/variance/median/num_samples/percentiles)+XYPlotType(12字段: plot_title/x_variable/y_variable/legend/num_curves/x_data/y_data/line_styles/colors/show_grid/show_legend)+AnalysisConfigType(配置)
│   │   • 公共接口(8): AP_DataAnalysis_Init(初始化)/LoadResults(加载结果)/ExtractPath(路径提取)/ExtractHistory(历史提取)/CalculateStatistics(统计计算)/PerformXYPlot(XY绘图)/GenerateReport(报告生成)/ExportData(数据导出)
│   │   • 路径分析: 支持多种路径类型(节点连线/空间曲线/自定义路径)
│   │   • 统计分析: 最小值/最大值/均值/标准差/方差/中位数/百分位数
│   │   • XY绘图: 支持多曲线/图例/网格/线型/颜色配置
│   │   • 状态: STUB(未完全实现,含TODO标记)
│   │
│   ├── AP_PostProc_Visual.f90           → 可视化(710行, 9TYPE+8接口)
│   │   • 职责: 后处理可视化(视口管理+场变量绘图+等值线+矢量图+变形图+动画+结果导出)
│   │   • 管理器TYPE(1): VisualizationManagerType(15字段: job_name/odb_file/auto_scale/show_legend/show_axes/color_scheme/deformation_scale/num_viewports/viewports(:)/active_viewport/plot_config/contour_config/vector_config/deformed_config/animation_config/animation_enabled/total_frames/output_format/output_resolution_x/output_resolution_y/output_dpi/visualization_initialized/current_frame+8TBP)
│   │   • 配置TYPE(6): ViewportType(16字段: viewport_id/title/view_center/view_scale/rotation_angles/is_visible/show_mesh/show_deformed/show_field_output/active_field/contour_levels/x_min/x_max/y_min/y_max/z_min/z_max)+PlotConfigType(7字段)+ContourConfigType(7字段)+VectorConfigType(6字段)+DeformedConfigType(6字段)+AnimationConfigType(动画配置)
│   │   • 公共接口(8): AP_Visualization_Init(初始化)/CreateViewport(创建视口)/PlotField(场变量绘图)/PlotContour(等值线绘图)/PlotVector(矢量图)/PlotDeformedShape(变形图)/CreateAnimation(创建动画)/ExportResults(结果导出)
│   │   • 可视化功能: 网格显示/变形显示/场变量输出/等值线分级(默认20级)/矢量缩放/变形缩放(默认1.0)
│   │   • 输出格式: PNG/JPG/SVG(默认PNG,1920x1080,300DPI)
│   │   • 颜色方案: RAINBOW(默认彩虹色)
│   │   • 状态: STUB(未完全实现,含TODO标记)
│   │
│   ├── 📝 设计意图: 计算结果写入+可视化数据导出+后处理分析(ODB/VTK/CSV/HDF5+数据分析+可视化)
│   ├── 📐 功能范围: ODB文件管理/格式关键字解析/L5_RT桥接/路径提取/历史数据分析/统计计算/XY绘图/视口管理/场变量绘图/等值线/矢量图/变形图/动画
│   ├── 📊 统计: 6文件(~118KB) | 24TYPE | 60+子程序 | 冷路径(求解完成后执行,除非每步输出)
│   ├── ⚠️  推断清单差异: 4规划名称 vs 6实际文件, 无AP_Out_Core/Export, 采用Domain+Format+RT_Brg+PostProc(数据分析+可视化)架构
│   ├── ⚠️  状态警告: AP_PostProc_DataAnal.f90/AP_PostProc_Visual.f90为STUB状态(含TODO标记,未完全实现)
│
├── Registry/                             [⭐ 注册表]
│   ├── AP_Reg_Domain.f90                → 模型注册域(210行, 3TYPE+3Arg+1Domain+5TBP)
│   │   • 职责: 模型注册管理+版本控制+性能退化检测+审计日志
│   │   • TYPE(1): AP_Registry_ModelEntry(6字段: modelId[INT64]/modelName/modelType/version/active/lastScore)
│   │   • TYPE(2): AP_Registry_State(3字段: nModels/nAuditLogs/auditEnabled)+AP_Registry_Ctrl(3字段: degradationCheck/degradationThreshold/maxVersionHistory)
│   │   • Arg类型(3, Phase B结构化I/O):
│   │     - AP_Registry_RegisterModel_Arg(4字段): modelName[IN]/modelType[IN]/modelId[INT64,OUT]/status[OUT]
│   │     - AP_Registry_CheckDegradation_Arg(3字段): modelId[INT64,IN]/isDegraded[LOGICAL,OUT]/status[OUT]
│   │     - AP_Registry_GetSummary_Arg(2字段): summary[OUT]/status[OUT]
│   │   • TYPE(Domain): AP_Registry_Domain(state+ctrl+models[256]+initialized+5TBP)
│   │   • TBP(5+Wrapper/Impl双层):
│   │     - Init/Finalize: 生命周期管理
│   │     - RegisterModel: 注册模型(容量限制256,自动生成modelId=1,2,3...)
│   │     - CheckDegradation: 退化检测(基于lastScore<threshold判断)
│   │     - GetSummary: 生成注册表摘要(模型数/审计日志数/退化检测开关/阈值)
│   │   • 容量限制: AP_REG_MAX_MODELS=256(固定数组,非动态扩容)
│   │   • 版本管理: 语义化版本(MAJOR.MINOR.PATCH,默认1.0.0)
│   │   • 退化检测: 基于评分阈值(默认0.1,低于阈值判定为退化)
│   │   • 审计日志: auditEnabled默认开启,nAuditLogs计数
│   │   • 模型生命周期: Register→Train→Validate→Deploy→Monitor→Retire
│   │
│   ├── 📝 设计意图: 应用级模型注册与生命周期管理(模型注册+版本控制+退化检测+审计)
│   ├── 📐 功能范围: 模型注册/版本管理/性能退化检测/审计日志/注册表摘要查询
│   ├── 📊 统计: 1文件(~8KB) | 4TYPE | 5子程序(3Wrapper+3Impl) | 冷路径(仅初始化/监控阶段)
│   ├── ⚠️  推断清单差异: 3规划名称 vs 1实际文件, 无AP_Reg_Material/Element/Solver, 采用单一Domain模式
│   ├── ⚠️  功能缺口: 契约要求服务注册/插件管理/扩展点/对象工厂,实际仅实现模型注册,需后续补全
│
├── Solver/                               [⭐ 求解器]
│   ├── AP_Solv_Domain.f90               → 求解器域(310行, 2TYPE+3Arg+1Domain+5TBP)
│   │   • 职责: 应用级求解器编排(顶层分析作业控制+步序列执行+求解器类型分发+作业生命周期)
│   │   • TYPE(2):
│   │     - AP_Solver_State(10字段: jobPhase/totalSteps/completedSteps/currentStepId/currentIncrIdx/totalJobTime/preProcessTime/solveTime/postProcessTime/peakMemoryMB)
│   │     - AP_Solver_Ctrl(4字段: nOMPThreads/memoryLimitMB/dryRun/dataCheck)
│   │   • Arg类型(3, Phase B结构化I/O):
│   │     - AP_Solver_RunJob_Arg(1字段): status[OUT]
│   │     - AP_Solver_SetOMPThreads_Arg(2字段): nOMP[IN]/status[OUT]
│   │     - AP_Solver_GetSummary_Arg(2字段): summary[OUT]/status[OUT]
│   │   • TYPE(Domain): AP_Solver_Domain(state+ctrl+initialized+5TBP)
│   │   • TBP(5+Wrapper/Impl双层):
│   │     - Init/Finalize: 生命周期管理
│   │     - RunJob: 运行求解作业(委托AP_Job_Core执行,同步作业摘要到求解器状态)
│   │     - SetOMPThreads: 设置OpenMP线程数(0=环境变量默认)
│   │     - GetSummary: 生成求解器摘要(阶段/步数/时间/内存)
│   │   • 作业阶段枚举(6): AP_JOB_NOT_STARTED(0)/PREPROCESS(1)/SOLVING(2)/POSTPROCESS(3)/COMPLETE(4)/FAILED(5)
│   │   • 三阶段生命周期: Pre→Solve→Post(预处理→求解→后处理)
│   │   • 作业集成: 委托AP_Job_Run_Structured执行(通过g_ufc_global%ap_layer%jobCtx)
│   │   • 状态同步: RunJob后调用AP_Job_BuildSum_Structured同步completedSteps/totalSteps/jobPhase
│   │   • ✅ 干运行模式: dryRun=.TRUE.时仅解析不求解(返回"Dry-run mode: parsing completed")
│   │   • ✅ 数据检查: dataCheck=.TRUE.时仅验证模型(返回"Data-check mode: model validation completed")
│   │   • ✅ 时间统计: 三阶段独立计时(preProcessTime/solveTime/postProcessTime)+totalJobTime
│   │   • ⚠️  内存监控: peakMemoryMB占位(0.0_wp),待集成Query_Peak_Memory_MB()
│   │   • 内存限制: memoryLimitMB=0表示无限制(未实现超限告警)
│   │   • 并行控制: nOMPThreads=0表示使用环境变量默认(OMP_NUM_THREADS)
│   │   • SMP贯通(v4.0): SetOMPThreads_Impl中调用omp_set_num_threads(nOMP)
│   │   • 依赖: AP_Job_Core(Job域)+UFC_GlobalContainer_Core(全局容器)+omp_lib
│   │
│   ├── 📝 设计意图: 高层求解器接口+求解流程编排+作业生命周期管理+并行控制+资源监控
│   ├── 📐 功能范围: 作业控制/步序列执行/求解器类型分发/作业生命周期管理/并行控制/内存限制/状态查询/干运行/数据检查/时间统计
│   ├── 📊 统计: 1文件(~12KB) | 3TYPE | 5子程序(3Wrapper+3Impl) | 冷路径(编排层,热路径在L5_RT)
│   ├── ⚠️  推断清单差异: 3规划名称 vs 1实际文件, 无AP_Solv_Main/Types/Config, 采用单一Domain模式
│   ├── ⚠️  功能缺口: 契约要求静力/动力/屈曲/频响分析+工况管理+参数化研究,实际采用委托架构(由Job域+L5_RT处理)
│   ├── ✅ 架构对齐: v2.0(2026-04-13)已对齐实际委托架构,CONTRACT.md已更新
│
└── UI/                                   [⭐ 用户界面]
│   ├── AP_UI_Types.f90                  → 类型定义(54行, 2TYPE+ID常量)
│   │   • 职责: UI域数据类型定义(命令历史/UI树节点+ID索引)
│   │   • TYPE(2): CommandHistoryEntry(6字段: history_id/cmd_id/cmd_line/succeeded/timestamp/line_number)+UITreeNodeEntry(10字段: node_id/parent_id/node_type/name/display_name/is_expanded/is_visible/n_children/child_ids)
│   │   • ID常量(4): AP_UI_HISTORY_ID_INVALID/AP_UI_NODE_ID_INVALID(无效ID)+AP_UI_DOMAIN_HISTORY/AP_UI_DOMAIN_NODE(域ID)
│   │   • 设计模式: 索引树+扁平域双模式(与L3_MD对齐)
│   │
│   ├── AP_UI_Core.f90                   → UI核心(983行, 3TYPE+9Arg+17接口)
│   │   • 职责: 命令行界面(CLI)+进度条显示+控制台I/O抽象(平台无关)
│   │   • TYPE(3): AP_UI_Ctrl_Type(Ctx: UI控制上下文)+AP_UI_Progress_Type(State: 进度条状态)+AP_UI_Command_Type(Desc: 命令描述符)
│   │   • Arg类型(9, Phase B结构化I/O): AP_UI_Init_In/Out+AP_UI_Progress_Init_In/Out+AP_UI_Progress_Update_In/Out+AP_UI_Print_In/Out
│   │   • UI模式(3): UI_MODE_INTERACTIVE(1)/BATCH(2)/SILENT(3)
│   │   • ANSI颜色(8): RED/GREEN/YELLOW/BLUE/MAGENTA/CYAN/WHITE/RESET
│   │   • 公共接口(17):
│   │     - 生命周期(2): AP_UI_Init/AP_UI_Cleanup
│   │     - 打印(5): AP_UI_Print/PrintInfo/PrintWarning/PrintError/PrintSuccess
│   │     - 进度条(3): AP_UI_Progress_Init/Update/Finish
│   │     - 交互(2): AP_UI_ReadLine/AP_UI_Confirm
│   │     - 表格(2): AP_UI_PrintTable/AP_UI_PrintHeader
│   │     - 查询(3): AP_UI_IsInteractive/AP_UI_GetTerminalWidth/AP_UI_GetMode
│   │   • 全局状态(3): g_ui_mode/g_ui_use_color/g_ui_terminal_width(SAVE属性)
│   │
│   ├── AP_UI_Domain.f90                 → UI域(363行, 2TYPE+3Arg+1Domain+8TBP)
│   │   • 职责: 用户界面命令注册与分发(映射用户命令到内部动作+命令行参数解析+交互模式支持)
│   │   • TYPE(2): AP_UI_State(5字段: mode/nRegisteredCmds/nExecutedCmds/nFailedCmds/sessionActive)+AP_UI_Ctrl(5字段: defaultMode/echoCommands/colorOutput/progressBar/historySize)
│   │   • Arg类型(3, Phase B结构化I/O): AP_UI_RegisterCommand_Arg/AP_UI_ExecuteCommand_Arg/AP_UI_GetSummary_Arg
│   │   • TYPE(Domain): AP_UI_Domain(state+ctrl+command_history(:)+ui_tree_nodes(:)+n_history/n_nodes/initialized+8TBP)
│   │   • TBP(8): Init/Finalize/RegisterCommand/ExecuteCommand/GetSummary/AddCommandHistory/AddTreeNode/GetHistoryById/GetNodeById
│   │   • UI模式(3): AP_UI_BATCH(1)/INTERACTIVE(2)/SCRIPT(3)
│   │   • 命令容量: AP_CMD_MAX_REGISTERED=256
│   │   • 扁平域存储: command_history(:)+ui_tree_nodes(:)动态数组
│   │   • 依赖: AP_Inp_Script_API(UF_Cmd_ExecString)
│   │
│   ├── AP_UI_INP.f90                    → INP文件生成(1090行, 1TYPE+9接口)
│   │   • 职责: 生成ABAQUS兼容的.inp文件(从ModelTree生成关键字+数据格式化+输出组织)
│   │   • TYPE(1): INPGenerator(Ctx: model_tree/indent_level/indent_size/add_comments/format_numbers/unit_number+7TBP)
│   │   • INP生成(7): INPGenerator_Generate(总生成)/GeneratePart(部件)/GenerateMat(材料)/GenerateSection(截面)/GenerateStep(步)/GenerateLoadBC(载荷边界)/GenerateInteract(交互)
│   │   • 验证(1): INPGenerator_Valid
│   │   • ABAQUS关键字: *PART/*MATERIAL/*SECTION/*STEP/*BOUNDARY/*LOAD/*OUTPUT
│   │   • 数据格式化: 缩进(indent_level/indent_size)+行继续+数字格式化
│   │   • 输出组织: 按ABAQUS约定排序(部件→材料→截面→装配→步→载荷→输出)
│   │   • 依赖: MD_Model_Tree+MD_Part_Core+MD_Mat_Lib+MD_Sect_Core+MD_Step_Proc+MD_LoadBC_Core+MD_Out_Ctx_Core
│   │
│   ├── AP_UI_JobMgr.f90                 → 作业管理(645行, 2TYPE+10接口)
│   │   • 职责: 作业创建/提交/监控(从模型树生成INP+提交到运行时层+跟踪进度)
│   │   • TYPE(2): UIJob(16字段: job_id/job_name/inp_file/model_file/log_file/result_file/status/progress/current_step/total_steps/current_increment/total_increments/start_time/end_time/model/auto_generate_inp)+RT_JobMgr(6字段: tree_mgr/inp_generator/jobs(:)/num_jobs/next_job_id/init+10TBP)
│   │   • 作业状态(5): JOB_STATUS_PENDING(1)/RUNNING(2)/COMPLETELETE(3)/FAILEDED(4)/CANCELLEDELLED(5)
│   │   • 作业管理(10): Init/CreateJob/SubmitJob/GetJobStatus/CancelJob/GetJobLog/MonitorJob/GetJob/GetJobByName/UpdateJobProgress
│   │   • 作业创建: 从ModelTree创建作业+自动生成INP文件
│   │   • 作业提交: 提交到运行时层(MD_RT_UI_RunJob)+跟踪作业状态
│   │   • 作业监控: 跟踪进度/增量步/步数/完成状态
│   │   • 依赖: AP_UI_INP_Core(INPGenerator)+AP_UI_TreeMgr(TreeMgr)+MD_UI_RT_Brg(运行时桥接)
│   │
│   ├── AP_UI_ModelMgr.f90               → 模型管理(1273行, 4TYPE+11接口)
│   │   • 职责: 模型验证+属性编辑(模型树节点验证+依赖检查+属性表单+字段get/set+表单验证+应用变更)
│   │   • TYPE(4): ValidRes(4字段: is_valid/num_errors/num_warnings/errors/warnings)+ValidMgr(2字段: tree_mgr/init+5TBP)+PropertyField(13字段: field_name/display_name/description/field_type/is_required/is_readonly/default_value/current_value/validation_rule/num_choices/choices)+PropertyForm(5字段: node_type/form_name/form_title/num_fields/fields)+PropertyMgr(3字段: tree_mgr/forms(:)/init+5TBP)
│   │   • 字段类型(6): FIELD_TYPE_TEXT(1)/INT(2)/REAL(3)/BOOL(4)/CHOICE(5)/MULTI(6)
│   │   • 验证管理(5): Init/ValidateModel/ValidateNode/CheckDependencies/GetValidationReport
│   │   • 私有验证(5): ValidatePart/ValidateMaterial/ValidateSection/ValidateStep/ValidateLoadBC
│   │   • 属性管理(5): Init/GetForm/GetFieldValue/SetFieldValue/ValidateForm/ApplyChanges
│   │   • 依赖: VD_Core(ValidState/ValidIssue)+VD_Mgr(ValidMgr_ValidModel)+AP_UI_TreeMgr
│   │   • 合并来源: AP_UI_ValidMgr+AP_UI_PropertyMgr(二合一)
│   │
│   ├── AP_UI_TreeMgr.f90                → 树管理(794行, 2TYPE+11接口)
│   │   • 职责: 模型树管理(树操作+节点创建/删除/重命名/移动+节点路径解析+节点数据访问+树验证)
│   │   • TYPE(2): TreeMgr(2字段: model_tree/init+11TBP)+UITreeNode(11字段: node_id/parent_id/node_type/name/display_name/is_expanded/is_selected/is_visible/child_ids/data_ptr)
│   │   • 树操作(11): Init/CreateNode/DeleteNode/RenameNode/GetNodeData/SetNodeData/GetChildren/MoveNode/GetNodePath/FindNodeByName/ValidateNode
│   │   • 节点类型(10): NODE_TYPE_MODEL/PART/ASSEM/MATER/SECTI/MESH/AMPLI/LOADB/INTER/STEP
│   │   • 树操作理论: 树数据结构+层级组织+路径解析(root/part/material/...)
│   │   • 依赖: MD_Model_Tree+MD_Part_Core+MD_Mat_Lib+MD_Sect_Core+MD_Step_Proc
│   │
│   ├── 📝 设计意图: 命令行界面(CLI)+图形界面(GUI)框架+交互式建模工具+INP文件生成+作业管理+模型验证
│   ├── 📐 功能范围: CLI解析/进度条显示/控制台I/O/命令注册分发/INP生成/作业创建提交监控/模型验证/属性编辑/树管理
│   ├── 📊 统计: 7文件(~189KB) | 17TYPE | 70+子程序 | 冷路径(前后处理阶段)
│   ├── ⚠️  推断清单差异: 3规划名称 vs 7实际文件, 无AP_UI_PreProcess/PostProcess/Interactive, 采用Core+Domain+INP+JobMgr+ModelMgr+TreeMgr架构
│   ├── ⚠️  命名注意: AP_UI_JobMgr/AP_UI_INP/AP_UI_TreeMgr模块名与文件一致,但内部注释标注L3_MD层(历史遗留)
```

**L6_AP 统计**: 8 域 | 0 子域 | 30+ 文件 | TYPE策略: **统一合并 `_Types.f90`（按需 USE）**

> **v3.0 优化**: 统一合并策略，所有 TYPE 放入 `_Types.f90`，按需 USE

---

## 八、域级统计总表

> **v3.0 更新**: TYPE 统一合并策略，简化架构决策，减少文件碎片化

| 层级 | 域 | 子域数 | f90 文件数 | 核心功能 |
|------|---|--------|-----------|----------|
| **L1_IF** | AI | 0 | 1 | AI推理引擎 |
| | Base | 0 | 10 | safe_divide, init_device |
| | Error | 0 | 7 | set_error, is_error |
| | IO | 1 | 13 | read_inp_file, write_odb_frame |
| | Log | 0 | 6 | log_message, flush_log |
| | Memory | 0 | 10 | allocate_array, deallocate |
| | Monitor | 0 | 5 | start_timer, print_report |
| | Parallel | 0 | 5 | 线程工作空间 |
| | Precision | 0 | 2 | 精度定义+类型(合并), 常量 |
| | Registry | 0 | 2 | 注册表管理 |
| | Symbol | 0 | 1 | FEM符号 (IF_前缀) |
| | LayerContainer | 0 | 1 | L1层容器 |
| **小计** | **11** | **1** | **50+** | |
| **L2_NM** | Base | 0 | 6 | 向量运算, 范数计算 |
| | Matrix | 2 | 12 | SpMV, CSR/CSC, 装配 |
| | Solver | 4 | 30+ | LU, GMRES, Newton, AI |
| | TimeInt | 3 | 12 | Newmark, RK4, 自适应 |
| | BVH | 0 | 3 | 层次包围盒 |
| | ExternalLibs | 0 | 11 | BLAS, LAPACK, MKL |
| | Bridge | 0 | 5 | 数据转换 |
| | LayerContainer | 0 | 1 | L2层容器 |
| **小计** | **7** | **6** | **100+** | |
| **L3_MD** | Analysis | 5 | 20+ | Group映射, 约束校验 |
| | Material | 4 | 200+ | 11族本构 (OLD目录) |
| | Element | 3 | 15+ | 3D/2D/1D单元 |
| | Mesh | 3 | 20+ | 拓扑, 自适应, DOF |
| | Assembly | 0 | 8+ | DOF编号, 实例 |
| | Boundary | 0 | 10+ | Fixed, Symmetry, BC |
| | Constraint | 0 | 8+ | MPC, RBE, 配对 |
| | Interaction | 0 | 15+ | Contact, Friction |
| | KeyWord | 0 | 20+ | 关键字解析 |
| | Field | 0 | 3+ | 场变量 |
| | Output | 0 | 20+ | 场/历史输出 |
| | Model | 0 | 25+ | 模型构建, 基础类型 |
| | Part | 0 | 8+ | 部件, 几何, 集合 |
| | Section | 0 | 10+ | 截面, 质量属性 |
| | WriteBack | 0 | 5+ | 回写 |
| | Bridge | 0 | 20+ | L4/L5桥接 |
| | LayerContainer | 0 | 1 | L3层容器 |
| **小计** | **15** | **8** | **350+** | |
| **L4_PH** | Material | 11 | **160+** | 11族54种材料 |
| | Element | 12 | **377+** | 12族245种单元(含变体) |
| | Contact | 0 | 15+ | 12种接触算法 |
| | LoadBC | 0 | 30+ | 28种载荷/BC |
| | Constraint | 0 | 18+ | 15种约束类型 |
| | Output | 0 | 8+ | 场/历史输出, VTK |
| | Field | 0 | 3+ | 场计算 |
| | Bridge | 0 | 5+ | RT转换 |
| | WriteBack | 0 | 3+ | ODB回写 |
| | LayerContainer | 0 | 2 | L4层容器 |
| **小计** | **9** | **14** | **450+** | |
| **L5_RT** | Assembly | 0 | 9+ | DOF管理 |
| | Bridge | 0 | 14+ | L3/L4/L6桥接 |
| | Contact | 0 | 9+ | 搜索, 更新 |
| | Coupling | 0 | 7+ | 多场协调 |
| | Element | 0 | 7+ | 批量计算 |
| | LoadBC | 0 | 7+ | 时间历程 |
| | Logging | 0 | 4+ | 日志管理 |
| | Material | 0 | 8+ | 缓存, 状态更新 |
| | Mesh | 0 | 7+ | 全局编号 |
| | Output | 0 | 7+ | 帧输出 |
| | Solver | 0 | 8+ | 线性/非线性 |
| | StepDriver | 0 | 8+ | 步驱动 |
| | WriteBack | 0 | 7+ | 检查点, ODB |
| | LayerContainer | 0 | 1 | L5层容器 |
| **小计** | **13** | **0** | **80+** | |
| **L6_AP** | Bridge | 0 | 3+ | RT桥接 |
| | Config | 0 | 4+ | 配置解析 |
| | Input | 0 | 6+ | INP解析 |
| | Job | 0 | 5+ | 作业管理 |
| | Output | 0 | 6+ | 格式化, 导出 |
| | Registry | 0 | 4+ | 注册表 |
| | Solver | 0 | 5+ | 主入口 |
| | UI | 0 | 4+ | 前后处理 |
| **小计** | **8** | **0** | **30+** | |
| **总计** | **63+** | **29+** | **1000+** | |

---

## 九、命名规范总结

> **v3.0 更新**: TYPE 统一合并策略 + 完整命名规范定义

### 9.1 三级命名体系

| 层级 | 命名格式 | 说明 | 示例 |
|------|----------|------|------|
| **层级前缀** | `IF_`/`NM_`/`MD_`/`PH_`/`RT_`/`AP_` | 6 层唯一标识 | `IF_Base_Core.f90` |
| **域级标识** | `Base`/`Error`/`Memory`/`Solver`... | 域名称（驼峰） | `IF_Err_Types.f90` |
| **功能后缀** | `_Core`/`_Types`/`_API`/`_Mgr`... | 功能类型标识 | `NM_Solv_Core.f90` |

### 9.2 TYPE 文件组织策略（统一合并）

> **✅ v3.0 决策**: 采用统一合并策略，所有 TYPE 统一放入 `XXX_Types.f90`

#### 9.2.1 统一合并策略

| 层级 | 策略 | TYPE 文件组织 | 文件数影响 | 理由 |
|------|------|--------------|-----------|------|
| **所有层** | ✅ **统一合并** | `XXX_Types.f90`<br>（内部按 4 类 SECTION 组织） | 0 变化 | 简化架构，按需 USE，避免碎片化 |

#### 9.2.2 文件内部组织规范

```fortran
MODULE IF_Err_Types
    IMPLICIT NONE
    PUBLIC
    
    ! ====================
    ! SECTION 1: Desc_Type (不可变配置)
    ! ====================
    TYPE, PUBLIC :: IF_Err_Desc_Type
        INTEGER :: error_code
        CHARACTER(LEN=128) :: module_name
    END TYPE IF_Err_Desc_Type
    
    ! ====================
    ! SECTION 2: State_Type (运行时状态)
    ! ====================
    TYPE, PUBLIC :: IF_Err_State_Type
        INTEGER :: active_count
        LOGICAL :: has_fatal
    END TYPE IF_Err_State_Type
    
    ! ====================
    ! SECTION 3: Algo_Type (算法参数)
    ! ====================
    TYPE, PUBLIC :: IF_Err_Algo_Type
        LOGICAL :: auto_propagate
        INTEGER :: max_depth
    END TYPE IF_Err_Algo_Type
    
    ! ====================
    ! SECTION 4: Ctx_Type (临时上下文)
    ! ====================
    TYPE, PUBLIC :: IF_Err_Ctx_Type
        TYPE(IF_Err_Desc_Type) :: desc
        TYPE(IF_Err_State_Type) :: state
        TYPE(IF_Err_Algo_Type) :: algo
    END TYPE IF_Err_Ctx_Type
    
END MODULE IF_Err_Types
```

#### 9.2.3 按需 USE 示例

```fortran
! ✅ 只需 Desc_Type
USE IF_Err_Types, ONLY: IF_Err_Desc_Type

! ✅ 只需 State + Ctx
USE IF_Err_Types, ONLY: IF_Err_State_Type, IF_Err_Ctx_Type

! ✅ 需要全部 4 类
USE IF_Err_Types
```

#### 9.2.4 优势说明

1. **简化架构决策**：1 种策略 vs v2.5 的 3 种策略
2. **减少碎片化**：-33 文件（避免空文件和强制拆分）
3. **灵活访问**：按需 USE，不强制加载全部 TYPE
4. **符合实际**：不是所有模块都有完整的 4 类 TYPE
5. **性能无损**：Fortran 模块加载是编译期行为，运行时无差异

### 9.3 四型 TYPE 后缀规范

| TYPE 类型 | 后缀 | 用途 | 生命周期 | 示例 |
|----------|------|------|---------|------|
| **Desc_Type** | `_Desc_Type` | 不可变配置描述符 | 初始化后只读 | `IF_Error_Desc_Type` |
| **State_Type** | `_State_Type` | 运行时状态 | 计算过程中更新 | `IF_Error_State_Type` |
| **Algo_Type** | `_Algo_Type` | 算法参数 | 求解器配置期设定 | `RT_Solver_Algo_Type` |
| **Ctx_Type** | `_Ctx_Type` | 临时上下文（热数据） | 单步/单迭代内有效 | `RT_StepDriver_Ctx_Type` |

### 9.4 子程序命名规范

| 子程序类型 | 后缀 | 用途 | 命名格式 | 示例 |
|-----------|------|------|---------|------|
| **核心模块** | `_Core` | 域核心逻辑（含算法子程序） | `Domain_Core` | `IF_Err_Core.f90` |
| **API 接口** | `_API` | 对外接口 | `Domain_API` | `PH_Mat_API.f90` |
| **管理器** | `_Mgr` | 资源管理 | `Domain_Mgr` | `IF_Mem_Mgr.f90` |
| **同步** | `_Sync` | 层间同步 | `Domain_Sync` | `RT_Mat_Sync.f90` |
| **桥接** | `_Brg` | 层间桥接 | `Src_Dst_Brg` | `MD_MatLib_PH_Brg.f90` |
| **注册** | `_Reg` | 注册管理 | `Domain_Reg` | `IF_Err_Reg.f90` |
| **记录器** | `_Logger` | 日志记录 | `Domain_Logger` | `IF_Log_Logger.f90` |

### 9.5 文件组织规范

#### 9.5.1 标准域目录结构

```
L{层级}_{域名}/
├── {域名}_Core.f90              # 域核心（必须）
├── {域名}_Types.f90             # TYPE 定义（或拆分为 4 文件）
├── {域名}_API.f90               # API 接口（可选）
├── {域名}_Mgr.f90               # 管理器（可选）
├── {域名}_Sync.f90              # 同步逻辑（可选）
├── {子域}/                      # 子域目录（可选）
│   ├── {子域}_Core.f90
│   ├── {子域}_Types.f90
│   └── ...
└── Bridge/                      # 桥接层（可选）
    ├── {域名}_L{目标层}_Brg.f90
    └── ...
```

#### 9.5.2 Bridge 文件命名规范

| 桥接方向 | 命名格式 | 示例 | 说明 |
|---------|---------|------|------|
| L3→L4 | `MD_{域名}_PH_Brg.f90` | `MD_MatLib_PH_Brg.f90` | L3 数据推送到 L4 |
| L3→L5 | `MD_{域名}_RT_Brg.f90` | `MD_Model_RT_Brg.f90` | L3 数据推送到 L5 |
| L4→L5 | `PH_Bridge_L5.f90` | `PH_Bridge_L5.f90` | L4 计算结果推送到 L5 |
| L5→L6 | `RT_Bridge_L6.f90` | `RT_Bridge_L6.f90` | L5 运行时状态推送到 L6 |

### 9.6 层级职责与功能边界

| 层级 | 核心职责 | 功能边界 | 禁止行为 |
|------|---------|---------|----------|
| **L1_IF** | 基础设施（内存/IO/错误/日志） | 提供跨层公共服务 | ❌ 不包含业务逻辑 |
| **L2_NM** | 数值算法（矩阵/求解器/时间积分） | 纯数学计算，无物理语义 | ❌ 不依赖 L3+ 层 |
| **L3_MD** | 模型数据（材料/单元/网格/载荷） | 死数据真相源，配置存储 | ❌ 不包含计算逻辑 |
| **L4_PH** | 物理计算（本构/单元刚度/接触） | 物理建模与算法基类 | ❌ 不管理运行时状态 |
| **L5_RT** | 运行时协调（步驱动/装配/求解） | 调度控制与状态管理 | ❌ 不包含物理计算 |
| **L6_AP** | 应用层（输入/输出/作业管理） | 用户接口与流程编排 | ❌ 不直接调用 L4 计算 |

---

## 十、生成规则

### 10.1 最小完备判断标准

1. **功能完整性**: 每个子域必须覆盖其定义的全部功能
2. **四型贯通**: Desc/State/Algo/Ctx 四类 TYPE 必须齐全
3. **接口一致性**: 同类文件使用统一的命名和签名
4. **依赖最小化**: 每个文件只依赖其必需的上一层文件

### 10.2 文件拆分原则

1. **单一职责**: 每个文件只负责一个明确的功能
2. **可独立编译**: 单个 f90 文件可以独立编译
3. **粒度适中**: 避免过大(>1000行)或过小(<100行)的文件

---

**文档版本**: v3.0（TYPE 统一合并策略）
**生成日期**: 2026-04-12
**总文件数**: 336+ 个 f90 文件（Phase 4 执行后约 370+）
**命名规范**: v3.0（三级命名体系 + TYPE 统一合并）

### 📋 v3.0 核心更新

1. **TYPE 文件组织策略：统一合并**
   - ✅ 所有层级：统一合并到 `XXX_Types.f90`
   - ✅ 内部组织：按 4 类 SECTION 分隔（Desc/State/Algo/Ctx）
   - ✅ 访问方式：按需 `USE XXX_Types, ONLY: TYPE名`
   - ✅ 文件数影响：0 变化（-33 文件 vs v2.5）
   - ✅ 优势：简化架构、减少碎片化、灵活访问、符合实际

2. **三级命名体系明确化**
   - 层级前缀：`IF_`/`NM_`/`MD_`/`PH_`/`RT_`/`AP_`
   - 域级标识：`Base`/`Error`/`Memory`/`Solver`...（驼峰）
   - 功能后缀：`_Core`/`_Types`/`_API`/`_Mgr`/`_Sync`/`_Brg`

3. **子程序命名规范精简**
   - 核心模块：`_Core`（内含算法子程序，不独立拆分）
   - API 接口：`_API`
   - 管理器：`_Mgr`
   - 同步：`_Sync`
   - 桥接：`_Brg`
   - 注册：`_Reg`
   - 记录器：`_Logger`
   - ⚠️ **禁止独立子程序文件**：`_Algo_Sub`、`_Util_Sub`、`_Batch_Sub` 等应合并到 `_Core` 或其他功能模块中

4. **层级职责与功能边界定义**
   - L1_IF: 基础设施，禁止包含业务逻辑
   - L2_NM: 数值算法，禁止依赖 L3+ 层
   - L3_MD: 模型数据，禁止包含计算逻辑
   - L4_PH: 物理计算，禁止管理运行时状态
   - L5_RT: 运行时协调，禁止包含物理计算
   - L6_AP: 应用层，禁止直接调用 L4 计算

5. **Bridge 文件命名规范**
   - L3→L4: `MD_{域名}_PH_Brg.f90`
   - L3→L5: `MD_{域名}_RT_Brg.f90`
   - L4→L5: `PH_Bridge_L5.f90`
   - L5→L6: `RT_Bridge_L6.f90`

## 十、生成规则

### 10.1 最小完备判断标准

1. **功能完整性**: 每个子域必须覆盖其定义的全部功能
2. **四型贯通**: Desc/State/Algo/Ctx 四类 TYPE 必须齐全
3. **接口一致性**: 同类文件使用统一的命名和签名
4. **依赖最小化**: 每个文件只依赖其必需的上一层文件

### 10.2 文件拆分原则

1. **单一职责**: 每个文件只负责一个明确的功能
2. **可独立编译**: 单个 f90 文件可以独立编译
3. **粒度适中**: 避免过大(>1000行)或过小(<100行)的文件

---

**文档版本**: v3.0（TYPE 统一合并策略）
**生成日期**: 2026-04-12
**总文件数**: 336+ 个 f90 文件（Phase 4 执行后约 370+）
**命名规范**: v3.0（三级命名体系 + TYPE 统一合并）

### 📋 v3.0 核心更新

1. **TYPE 文件组织策略：统一合并**
   - ✅ 所有层级：统一合并到 `XXX_Types.f90`
   - ✅ 内部组织：按 4 类 SECTION 分隔（Desc/State/Algo/Ctx）
   - ✅ 访问方式：按需 `USE XXX_Types, ONLY: TYPE名`
   - ✅ 文件数影响：0 变化（-33 文件 vs v2.5）
   - ✅ 优势：简化架构、减少碎片化、灵活访问、符合实际

2. **三级命名体系明确化**
   - 层级前缀：`IF_`/`NM_`/`MD_`/`PH_`/`RT_`/`AP_`
   - 域级标识：`Base`/`Error`/`Memory`/`Solver`...（驼峰）
   - 功能后缀：`_Core`/`_Types`/`_API`/`_Mgr`/`_Sync`/`_Brg`

3. **子程序命名规范精简**
   - 核心模块：`_Core`（内含算法子程序，不独立拆分）
   - API 接口：`_API`
   - 管理器：`_Mgr`
   - 同步：`_Sync`
   - 桥接：`_Brg`
   - 注册：`_Reg`
   - 记录器：`_Logger`
   - ⚠️ **禁止独立子程序文件**：`_Algo_Sub`、`_Util_Sub`、`_Batch_Sub` 等应合并到 `_Core` 或其他功能模块中

4. **层级职责与功能边界定义**
   - L1_IF: 基础设施，禁止包含业务逻辑
   - L2_NM: 数值算法，禁止依赖 L3+ 层
   - L3_MD: 模型数据，禁止包含计算逻辑
   - L4_PH: 物理计算，禁止管理运行时状态
   - L5_RT: 运行时协调，禁止包含物理计算
   - L6_AP: 应用层，禁止直接调用 L4 计算

5. **Bridge 文件命名规范**
   - L3→L4: `MD_{域名}_PH_Brg.f90`
   - L3→L5: `MD_{域名}_RT_Brg.f90`
   - L4→L5: `PH_Bridge_L5.f90`
   - L5→L6: `RT_Bridge_L6.f90`

### 📋 v4.0 SMP 并行贯通更新 (2026-04-26)

| 变更类型 | 文件 | 说明 |
|---------|------|------|
| 🆕 新增 | `L0_Global/UFC_GlobalContainer_Core.f90` | 全局容器, Init 中调用 `omp_set_num_threads(nThreads)` |
| 🆕 新增 | `L5_RT/Assembly/RT_AsmColor.f90` | Graph-Coloring 并行装配 (187行, 贪心着色+颜色分组) |
| 修改 | `L1_IF/Base/Parallel/IF_ThreadWS_Def.f90` | GetReal1D/2D/Int1D/2D 由 STUB 补全为实际实现 |
| 修改 | `L1_IF/Base/Parallel/IF_ThreadWS.f90` | GetLocalArray/AggregateReal1D 实现 + RegisterArray/ResetAll 新增 |
| 修改 | `L5_RT/Assembly/RT_Asm.f90` | 新增 AddElemStiff_Atomic/InPlace, ScatterResid_Atomic |
| 修改 | `L5_RT/Assembly/RT_AsmSolv.f90` | Cfg.assembly_mode + ScatterKe_CSR_Atomic + OMP 化 |
| 修改 | `L5_RT/StepDriver/RT_StepDriver_Brg.f90` | 单元循环 `!$OMP PARALLEL DO SCHEDULE(DYNAMIC,64)` |
| 修改 | `L6_AP/Solver/AP_SolvDomain.f90` | SetOMPThreads 调用 `omp_set_num_threads` |
| 修改 | `L2_NM/Bridge/NM_DirMUMPS_Brg.f90` | MUMPS `ICNTL(16)` + `NM_DirectSolver_SyncThreads` |

OpenMP 热路径: `L6(nOMP) → L0(omp_set_num_threads) → L1(ThreadWS) → L5(ElemLoop/Assembly) → L2(MUMPS)`

### ⏭️ 下一步：代码改造

文档已完善，可作为 UFC 架构代码改造的**唯一基准**。改造将按以下顺序执行：
1. L1_IF 层（示范层，50+ 文件）
2. L2_NM 层（100+ 文件）
3. L3_MD 层（350+ 文件）
4. L4_PH 层（450+ 文件）
5. L5_RT 层（80+ 文件）
6. L6_AP 层（30+ 文件）
