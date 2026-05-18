# UFC 架构设计总纲 — 域级模块规范 v2.0

> **版本**: v2.0（对齐仓库实际目录与命名，替代 v1.0）
> **创建日期**: 2026-04-22
> **最后更新**: 2026-04-22
> **核心使命**: 定义 UFC 六层框架的层级-域级目录结构、功能模块职责、接口规范
> **文档地位**: UFC 项目域级模块设计权威规范
> **适用范围**: UFC 项目全生命周期域级模块设计与实施

---

## 文档元数据


| 属性       | 值                                                                                                                                                                        |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **规范简称** | UFC_DomainModule_v2                                                                                                                                                      |
| **上位文档** | UFC_架构设计总纲_深度整合版_v5.0.md                                                                                                                                                 |
| **相关文档** | `UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md` · `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md` · `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md` |
| **核心公式** | **六层 + 域级 + 功能模块 + 四型 + 功能动词 + 后缀闭集**                                                                                                                                    |
| **版本演进** | v2.0: 对齐仓库实际目录与命名风格，修正接口序列，补全后缀闭集                                                                                                                                        |


---

## 一、设计原则

### 1.1 核心设计哲学

**层级-域级-功能三层抽象**：

- **层级**：系统抽象层次（L1-L6），决定依赖方向与边界
- **域级**：功能领域划分（如 Material、Solver、Mesh），决定模块分组
- **功能**：具体功能实现（如 `PH_Mat_Elas_Ops`、`RT_SolvProc_Algo`）

**命名公式**：

```
MODULE/文件名 = {层缀}_{域缩}_{功能}_{后缀}
TYPE名        = {层缀}_{域缩}_{功能}_{四型后缀}
子程序名      = {层缀}_{域缩}_{功能}_{动词}_{具体}
```

**数据四型统一**（客观分类，硬规则）：

- **Desc**：只读配置（Write-Once，模型定义后冻结）
- **State**：运行时状态（可写，Step/Increment 级）
- **Algo**：算法描述符（偏静态，从 Desc 派生）
- **Ctx**：上下文胶水（每步可变，显式传递）

**过程组织**（功能驱动，不按 C/K/R/D 强制分类）：

- 按功能动词命名（Init/Eval/Populate/Update/Get/...）
- 按计算流程排列（Step 1…n）
- Cval/Kern/Redu/Drv 仅作设计审查透镜，不作为强制标签

### 1.2 单向依赖原则

```
L6_USES(L5)
L5_USES(L4, L3, L2, L1)
L4_USES(L3, L2, L1)
L3_USES(L2, L1)
L2_USES(L1)
L1_USES(无)

! 禁止反向依赖
L3_USES(L4)  ! 禁止
L4_USES(L5)  ! 禁止
```

### 1.3 三条铁律

1. **层缀必填**：所有 MODULE、TYPE、子程序以 `IF_`/`NM_`/`MD_`/`PH_`/`RT_`/`AP_` 开头
2. **PascalCase**：MODULE 名、TYPE 名、子程序名均用 PascalCase
3. **四型后缀仅用于 TYPE**：`_Desc`/`_State`/`_Algo`/`_Ctx` 禁止出现在文件名或 MODULE 名中

---

## 二、层级-域级目录结构（仓库实际）

> 以下目录树基于 `ufc_core/` 实际内容，非规划。

### 2.1 L1_IF — 基础设施层

```
L1_IF/
├── Base/                    # 基础类型和常量
│   ├── AI/                  # AI 相关基础设施
│   ├── Parallel/            # 并行基础设施
│   └── Symbol/              # 符号处理
├── Error/                   # 错误处理 (IF_Err_*)
├── IO/                      # 输入输出
│   └── Checkpoint/          # 检查点管理
├── Log/                     # 日志 (IF_Log_*)
├── Memory/                  # 内存管理 (IF_Mem_*)
├── Monitor/                 # 性能监控 (IF_Mon_*)
├── Precision/               # 数值精度 (IF_Prec_*)
├── Registry/                # 注册表 (IF_Reg_*)
└── IF_L1Layer.f90            # 层入口
```

### 2.2 L2_NM — 数值方法层

```
L2_NM/
├── Base/                    # 数值基础类型
│   └── BVH/                 # 包围盒层次结构
├── Bridge/                  # 外部库接口
├── ExternalLibs/            # 第三方库封装
├── Matrix/                  # 矩阵运算
├── Solver/                  # 求解器算法
│   ├── Conv/                # 收敛性算法
│   ├── Coupling/            # 耦合求解器
│   ├── LinSolv/             # 线性求解器
│   └── NonlinSolv/          # 非线性求解器
├── TimeInt/                 # 时间积分
└── NM_L2Layer.f90            # 层入口
```

### 2.3 L3_MD — 模型数据层（唯一真相源）

```
L3_MD/
├── Analysis/                # 分析设置
│   ├── Amplitude/           # 幅值曲线
│   ├── Solver/              # 求解器控制
│   └── Step/                # 分析步
├── Assembly/                # 装配体
├── Boundary/                # 边界条件
├── Bridge/                  # 层间桥接
├── Constraint/              # 约束条件
├── Field/                   # 场变量
├── Interaction/             # 交互/接触定义
├── KeyWord/                 # 关键字解析
├── Material/                # 材料数据
│   ├── Base/                # 材料基础类型
│   ├── Bridge/              # 材料桥接
│   ├── Contract/            # 材料契约
│   ├── Dispatch/            # 材料分发
│   ├── Domain/              # 材料域
│   ├── Elas/                # 弹性材料
│   ├── Plast/               # 塑性材料
│   ├── HyperElas/           # 超弹性材料
│   ├── Damage/              # 损伤材料
│   ├── Creep/               # 蠕变材料
│   ├── Viscoelas/           # 粘弹性材料
│   ├── Composite/           # 复合材料
│   ├── Thermal/             # 热材料
│   ├── Acoustic/            # 声学材料
│   ├── Geo/                 # 地质材料
│   ├── User/                # 用户材料
│   ├── Registry/            # 材料注册
│   └── Shared/              # 材料共享
├── Mesh/                    # 网格数据
│   └── Element/             # 单元类型
│       ├── Beam/            # 梁单元
│       ├── Shell/           # 壳单元
│       ├── Solid3D/         # 三维实体单元
│       ├── Solid2D/         # 二维实体单元
│       ├── Truss/           # 桁架单元
│       ├── Cohesive/        # 粘结单元
│       ├── ...              # 其他单元族
│       └── User/            # 用户单元
├── Model/                   # 模型定义
├── Output/                  # 输出配置
├── Part/                    # 零件管理
├── Section/                 # 截面属性
├── WriteBack/               # 结果写回
├── contracts/               # 层内合同聚合
├── MD_L3Layer.f90            # 层入口
└── MD_AnalysisGroupModule.f90  # 分析组
```

### 2.4 L4_PH — 物理计算层

```
L4_PH/
├── Bridge/                  # 层间桥接
│   ├── Output/              # 输出桥接
│   └── WriteBack/           # 写回桥接
├── Constraint/              # 约束计算
├── Contact/                 # 接触算法
│   ├── Core/                # 接触核心
│   ├── Explicit/            # 显式接触
│   ├── Friction/            # 摩擦
│   ├── Search/              # 接触搜索
│   └── Types/               # 接触类型
├── Element/                 # 单元计算
│   ├── Solid3D/             # 三维实体
│   ├── Solid3Dt/            # 三维实体(热耦合)
│   ├── Solid2D/             # 二维实体
│   ├── Shell/               # 壳单元
│   ├── Beam/                # 梁单元
│   ├── Truss/               # 桁架
│   ├── Thermal/             # 热单元
│   ├── Spring/              # 弹簧
│   ├── Cohesive/            # 粘结
│   ├── Membrane/            # 膜
│   ├── Shared/              # 共享算法
│   └── ...                  # 其他族
├── Field/                   # 场变量计算
├── LoadBC/                  # 载荷/边界条件计算
├── Material/                # 材料本构计算
│   ├── Elas/                # 弹性计算
│   ├── Plast/               # 塑性计算
│   ├── HyperElas/           # 超弹性计算
│   ├── Damage/              # 损伤计算
│   ├── ...                  # 同 L3_MD/Material 子域
│   └── Dispatch/            # 材料分发
├── PH_Base.f90              # 层基础
├── PH_L4Layer.f90           # 层入口
├── PH_L4Populate.f90        # Populate 主页
├── PH_L4Idx_Brg.f90         # 索引桥接
├── PH_CrossDomainIface.f90  # 跨域接口
└── PH_AnalysisRouterModule.f90   # 分析路由
```

### 2.5 L5_RT — 运行时协调层

```
L5_RT/
├── Assembly/                # 系统装配
├── Bridge/                  # 层间桥接
│   └── Shared/              # 共享桥接
├── Contact/                 # 接触处理
├── Element/                 # 单元计算集成
│   └── Mesh/                # 网格单元集成
├── LoadBC/                  # 载荷应用
├── Logging/                 # 运行日志
├── Material/                # 材料状态更新
├── Output/                  # 结果输出
├── Solver/                  # 求解驱动
│   └── Coupling/            # 耦合求解
├── StepDriver/              # 步进驱动
├── WriteBack/               # 结果写回
├── RT_L5Layer.f90            # 层入口
├── RT_Com_Def.f90            # 公共定义
├── RT_Global_Def.f90         # 全局定义
└── RT_Amp.f90                # 幅值
```

### 2.6 L6_AP — 应用层

```
L6_AP/
├── Bridge/                  # 外部接口桥接
├── Config/                  # 配置管理
├── Input/                   # 输入处理
├── Job/                     # 作业管理
├── Output/                  # 输出管理
├── Registry/                # 算法注册
├── Solver/                  # 求解器选择
├── UI/                      # 用户界面
├── AP_Base_Def.f90          # 基基础定义
├── AP_L6Layer.f90           # 层入口
└── AP_SimData_Def.f90       # 仿真数据定义
```

---

## 三、功能模块设计规范

### 3.1 模块命名格式

```
文件名 = MODULE名.f90
MODULE名 = {层缀}_{域缩}_{功能}_{后缀}
```

**层缀**：`IF_` | `NM_` | `MD_` | `PH_` | `RT_` | `AP_`
**域缩**：与子目录对齐（`Mat`/`Elem`/`Mesh`/`Solv`/`Step`/`Cont`/`Field`/`Load`/`BC`/`WB`/`Out`/...）
**后缀**：A–H 闭集 46 项（见 §3.3），新文件禁止默认 `_Ops`/`_Algo`，必须选精确后缀

**仓库实例**（→ 表示推荐迁移目标）：


| 层   | 当前 MODULE名            | 推荐 MODULE名            | 后缀选择理由          |
| --- | --------------------- | --------------------- | --------------- |
| L1  | `IF_Mem_Chunk_Algo`   | `IF_MemChunk_Pool`    | 内存池→Pool        |
| L1  | `IF_StructFormat_API` | `IF_StructFormat_API` | 对外 ABI→API（已对齐） |
| L3  | `MD_Mesh_Ops`         | `MD_Mesh_Domain`      | 域入口→Domain      |
| L3  | `MD_ElemPopulate_Ops` | `MD_ElemPopulate`     | Populate→Pop    |
| L4  | `PH_ElemContm_Ops`    | `PH_ElemContm_Ops`    | 真正混合→Ops（保留）    |
| L4  | `PH_Field_Cpl`        | `PH_Field_Cpl`        | 跨层桥接→Brg（已对齐）   |
| L5  | `RT_SolvProc_Algo`    | `RT_SolvProc_Proc`    | SIO过程→Proc      |
| L5  | `RT_StepDriver_Brg`   | `RT_StepDriver_Brg`   | 跨层桥接→Brg（已对齐）   |
| L5  | `RT_StepImpl_Algo`    | `RT_Step_Impl`        | 实现专页→Impl       |
| L6  | `AP_SimData_Def`      | `AP_SimData_Def`      | TYPE声明→Def（已对齐） |


### 3.2 TYPE 命名

```
TYPE :: {层缀}_{域缩}_{功能}_{四型后缀}
```

**四型后缀**：`_Desc` | `_State` | `_Algo` | `_Ctx`（**仅用于 TYPE，禁作文件名**）

**仓库实例**：


| TYPE 名               | 拆解                             |
| -------------------- | ------------------------------ |
| `MD_Output_Desc`     | MD + Output + _ + Desc         |
| `MD_Output_State`    | MD + Output + _ + State        |
| `MD_Output_Algo`     | MD + Output + _ + Algo         |
| `MD_Output_Ctx`      | MD + Output + _ + Ctx          |
| `PH_Contm_Args`      | PH + Contm + _ + Args（SIO 参数束） |
| `PH_Elem_Truss_Args` | PH + Elem + Truss + Args       |


### 3.3 后缀闭集（46 项，穷尽仓库实际）

后缀只表达**功能专职**，不表达 ProcKind。完整后缀闭集 46 项（8 组 A-H），详见命名规范 v2.0 §3.2。


| 分组  | 后缀           | 含义                  | 仓库实例                                     |
| --- | ------------ | ------------------- | ---------------------------------------- |
| A   | **Def**      | TYPE/ENUM 纯声明       | `IF_Log_Def`、`MD_Mesh_Def`、`RT_WB_Def`   |
| A   | **Ctx**      | 纯上下文 TYPE 定义（遗留文件名） | `RT_Step_Ctx`、`PH_Cont_Ctx`              |
| B   | **Ops**      | **后备后缀**：确实混合       | `PH_Cont_Ops`（保留）                        |
| B   | **Eval**     | 评估/计算入口             | `PH_Mat_Eval`（待迁移）                       |
| B   | **Impl**     | 实现专页                | `RT_Step_Impl`、`RT_WB_Impl`              |
| B   | **Exec**     | 执行专页                | `RT_Step_Exec`                           |
| B   | **Proc**     | SIO 过程单元            | `RT_Solv_Proc`、`RT_WB_Proc`              |
| B   | **Util**     | 工具函数集               | `RT_Asm_Util`                            |
| C   | **Map**      | 语义映射                | `MD_Elem_InpMap`、`MD_KW_Map`             |
| C   | **Reg**      | 静态注册表               | `MD_Elem_Reg`、`MD_KWReg`                 |
| C   | **Dsp**      | 动态分派                | `PH_Elem_Dsp`（待迁移）                       |
| C   | **Facade**   | 门面/薄封装              | `PH_Elem_StructFac`（待迁移）                 |
| C   | **Idx**      | 索引图式                | `PH_L4Idx_Brg`、`MD_LBC_Idx`              |
| C   | **Lib**      | 库函数集                | `MD_Model_Lib`、`MD_Sect_Lib`             |
| D   | **Crd**      | 协调器（多物理场）           | `RT_MF_Coord`                            |
| D   | **Conv**     | 收敛判定                | `RT_Solv_CheckRes`                       |
| E   | **Brg**      | 跨层桥接                | `PH_Field_Cpl`、`RT_StepDriver_Brg`       |
| E   | **Contract** | 合同/契约检查             | `PH_L4L3Mat_Contract`（待迁移）               |
| E   | **Iface**    | 跨域接口                | `PH_Domain_Intf`（待迁移）                    |
| F   | **Mgr**      | 门面管理器               | `MD_Mesh_Mgr`（待迁移）、`IF_UnstructFile_Mgr` |
| F   | **Domain**   | 域入口薄门面              | `MD_Mesh_Domain`（待迁移）、`AP_RegDomain`     |
| F   | **Sync**     | 双域/双缓冲镜像            | `MD_Mesh_Sync`（待迁移）、`MD_Step_Sync`       |
| F   | **Search**   | 搜索算法专页              | `PH_Cont_Search`（待迁移）                    |
| F   | **Pool**     | 内存/资源池              | `RT_MemPool_Core`                        |
| G   | **Parse**    | 输入解析/词法分析           | `MD_KW_Parser`、`IF_Parser`               |
| G   | **Build**    | 构建/生成               | `MD_Model_Build`                         |
| G   | **Writer**   | 输出写入器               | `RT_Writer_ODB`                          |
| G   | **Persist**  | 持久化/序列化             | `IF_IO_Persist`                          |
| H   | **Thermo**   | 热力学耦合               | `PH_Cont_ThermoMech`（待迁移）                |
| H   | **Friction** | 摩擦算法                | `PH_Cont_Friction`（待迁移）                  |
| H   | **Wear**     | 磨损演化                | `PH_Cont_WearEvol`（待迁移）                  |
| H   | **Shape**    | 形函数/场成形             | `PH_Elem_ShapeFunc`（待迁移）                 |


**禁止作新建文件后缀**：`_Desc`/`_State`/`_Algo`/`_Ctx`（保留给 TYPE）
`**_Ops`/`_Algo` 降级为后备**：新文件禁止默认使用，必须先查精确后缀决策表（见命名规范 v2.0 §3.4）；存量不强制改名，重构时顺便迁移
**新增后缀**：RFC + 表增行 + naming_checker 白名单；软上限 50 项

### 3.4 标准模块接口模板

**功能动词可选集**（非强制五步）：


| 动词                 | 含义      | 仓库实例                                                                             |
| ------------------ | ------- | -------------------------------------------------------------------------------- |
| **Init**           | 初始化     | `MD_L3_Init`、`PH_L4_Init`、`PH_BC_Ctx_Init`                                       |
| **Finalize**       | 终结/清理   | `MD_L3_Finalize`、`PH_L4_Finalize`、`PH_LoadBC_Domain_Finalize`                    |
| **Populate**       | 灌入/填充   | `PH_Mat_Populate`、`PH_Elem_Populate`、`PH_LoadBC_Populate`                        |
| **Eval**           | 评估/计算   | `PH_Mat_Elas_Eval`、`RT_Asm_ShapeScalarField_Eval`、`PH_ShapeMechanicalField_Eval` |
| **Compute**        | 计算（偏具体） | `PH_PoreField_Compute`、`PH_TempField_Compute`                                    |
| **Update**         | 更新      | `PH_Mat_Elas_Update`                                                             |
| **Get/Set**        | 查询/设置   | `MD_Node_GetCoords`/`MD_Node_SetCoords`                                          |
| **Validate**       | 校验      | `MD_Bind_Validate`                                                               |
| **Check**          | 检查/守恒验证 | `PH_MomentumConservation_Check`、`RT_Solv_CheckRes`                               |
| **Freeze**         | 冻结      | `MD_L3_Freeze`                                                                   |
| **Bind**           | 绑定      | `MD_Domains_Bind`                                                                |
| **Sync**           | 同步      | `MD_L3_SyncModelCounts`、`MD_Step_Sync`                                           |
| **Create/Destroy** | 创建/销毁   | `MD_Node_Create`/`MD_Node_Destroy`                                               |
| **Alloc/Dealloc**  | 分配/释放   | （L1/L5 内存管理预留）                                                                   |
| **Register**       | 注册      | `MD_Elem_Solid3D_Register`、`MD_Elem_Beam_Register`                               |
| **Map**            | 映射      | `PH_Elem_AC3D20_Map`                                                             |
| **Parse**          | 解析      | `MD_KW_Parser`、`IF_Parser`                                                       |
| **Build**          | 构建      | `MD_Model_Build`                                                                 |
| **Assemble**       | 装配      | `RT_Cont_Assemble`                                                               |
| **Solve**          | 求解      | `RT_Cont_AugLag_Solve`                                                           |
| **Run**            | 运行/执行   | `RT_Elem_Dispatcher_Run`、`RT_StepDriver_Run`、`RT_MF_Coordinator_Run`             |
| **Drive**          | 驱动      | `RT_StepDriver_Brg`                                                              |
| **Dispatch**       | 分派      | `PH_Elem_Dsp`                                                                    |
| **Apply**          | 应用/修正   | `PH_ObjCorrect_Apply`                                                            |
| **Reset**          | 重置      | `PH_LoadBC_IncrBegin_Reset`                                                      |
| **Clear**          | 清空      | `PH_BC_Ctx_Clear`、`PH_Load_Ctx_Clear`、`PH_Mass_Result_Clear`                     |
| **Copy**           | 拷贝      | （预留）                                                                             |
| **Read/Write**     | 读/写     | `RT_Writer_ODB`、`IF_IO_Persist`                                                  |
| **Save/Load**      | 保存/加载   | `IF_IO_Backup`                                                                   |
| **Print**          | 打印      | `PH_Mass_Result_Print`                                                           |
| **Log**            | 日志      | `PH_UnregElemTypes_Log`                                                          |
| **Convert**        | 转换      | （预留）                                                                             |
| **Project**        | 投影      | （预留）                                                                             |
| **Interpolate**    | 插值      | （预留）                                                                             |
| **Integrate**      | 积分      | （预留）                                                                             |
| **Step**           | 步进      | （RT_Step 预留）                                                                     |
| **WriteBack**      | 回写      | （RT_WB 预留）                                                                       |
| **Output**         | 输出      | （RT_Output 预留）                                                                   |


**标准子程序签名**（四型平级传递）：

```fortran
SUBROUTINE PH_Mat_Elas_Eval(desc, state, algo, ctx, status)
  TYPE(PH_Mat_Elas_Desc),  INTENT(IN)    :: desc    ! 只读配置
  TYPE(PH_Mat_Elas_State), INTENT(INOUT) :: state   ! 可写状态
  TYPE(PH_Mat_Elas_Algo),  INTENT(IN)    :: algo    ! 算法描述
  TYPE(PH_Mat_Elas_Ctx),   INTENT(IN)    :: ctx     ! 上下文
  INTEGER,                  INTENT(OUT)   :: status  ! 状态码
END SUBROUTINE
```

**SIO 参数束形态**（L5 `_Proc` 签名）：

```fortran
TYPE :: PH_Contm_Args
  ! [IN]  字段
  ! [OUT] 字段
END TYPE

SUBROUTINE PH_ElemContm_Eval(args, status)
  TYPE(PH_Contm_Args), INTENT(INOUT) :: args
  INTEGER,             INTENT(OUT)   :: status
END SUBROUTINE
```

---

## 四、典型模块示例

### 4.1 L4_PH/Material/Elas — 弹性材料本构

```
L4_PH/Material/Elas/
├── PH_Mat_Elas_Def.f90         # TYPE 定义
│   TYPE :: PH_Mat_Elas_Desc    #   只读配置: E, nu, G, K, rho
│   TYPE :: PH_Mat_Elas_State   #   运行时状态: stress, ddsdde, statev
│   TYPE :: PH_Mat_Elas_Algo    #   算法描述: ndi, nshr, ntens
│   TYPE :: PH_Mat_Elas_Ctx     #   上下文: time, temp, dtime, IP
├── PH_Mat_Elas_Eval.f90        # 本构评估（Eval→计算入口）
├── PH_Mat_Elas_Impl.f90        # 状态更新实现（Impl→实现专页）
├── CONTRACT.md                 # 模块契约
└── (测试文件)
```

> ⚠️ 仓库中当前为 `PH_Mat_Elas_Ops.f90`（混合后缀），按新规范拆为 `_Eval` + `_Impl`。
> 存量不强制改名，重构时迁移。

### 4.2 L5_RT/StepDriver — 步进驱动

```
L5_RT/StepDriver/
├── RT_Step_Def.f90             # TYPE 定义
├── RT_StepDriver_Brg.f90       # 跨层桥接（Brg→已对齐）
├── RT_Step_Impl.f90            # 步进实现（Impl→实现专页）
├── RT_Step_Exec.f90            # 步进执行（Exec→执行专页）
├── RT_Step_Wsp.f90             # 工作区（Wsp→Workspace）
└── RT_Step_Ctx.f90             # 步进上下文（⚠️ 遗留，新文件用 _Def 内定义 TYPE）
```

> ⚠️ 仓库中当前为 `RT_StepImpl_Algo`/`RT_StepExec_Algo`/`RT_StepWS_Algo`，
> 按新规范 `Impl`/`Exec`/`Wsp` 直接作后缀，不再拖 `_Algo`。

### 4.3 L1_IF/Memory — 内存管理

```
L1_IF/Memory/
├── IF_Mem_Mgr.f90              # 内存管理器（Mgr→门面管理器）
├── IF_MemChunk_Pool.f90        # Chunk 内存池（Pool→资源池）
├── IF_Mem_Serial.f90           # 串行分配
├── IF_Mem_ThreadSlab.f90       # 线程 Slab
├── IF_Mem_Wsp.f90              # Workspace（Wsp→工作区）
├── IF_StructMemPool.f90        # 结构化内存池
└── IF_UnstructMemPool.f90      # 非结构化内存池
```

> ⚠️ 仓库中当前全部以 `_Algo` 结尾（如 `IF_Mem_Mgr_Algo`），
> 按新规范：Mgr/Pool/Wsp 直接作后缀，不再拖 `_Algo`。

---

## 五、层间数据契约

### 5.1 数据流方向

```
L3_MD (真相源) → L4_PH (计算) → L5_RT (协调) → L6_AP (应用)
         ↑              ↑              ↑
         └── Bridge ────┘── Bridge ──┘
```

- **L3 → L4**：通过 Populate（`PH_L4_Populate_Material` 等）
- **L4 → L5**：通过 Bridge（如 `RT_StepDriver_Brg`）
- **L5 → L3**：通过 WriteBack（`RT_WB_`*）

### 5.2 关键约束

- **Desc 只读**：任何层禁止运行时修改 Desc 字段
- **State 可写**：L4 写局部 State（应力）；L5 写全局 State（残差/刚度）
- **Algo 偏静态**：从 Desc 派生，运行时不轻易改
- **Ctx 每步可变**：步进控制修改 Ctx

### 5.3 错误处理

使用仓库已有 `IF_Err_`* 体系，**禁止**重新定义 ErrorStatusType。

---

## 六、遗留问题与演进计划

### 6.1 已知遗留


| 遗留                                              | 位置                                    | 说明                            |
| ----------------------------------------------- | ------------------------------------- | ----------------------------- |
| `_Ctx` 作文件后缀                                    | `RT_Step_Ctx.f90`、`RT_Global_Ctx.f90` | 违反"四型后缀禁作文件名"规则；存量不强制改名，新文件遵守 |
| `_Algo` 后缀泛化                                    | L1/L5 大量 `_Algo` 后缀                   | 存量保留；新增优先选更精确后缀               |
| `MD_FieldState_Ops.f90` 在 L4 目录                 | `UFC/ufc_core/L4_PH/Element/`         | 文件归属与命名均异常；待迁移                |
| 数字尾巴                                            | `MD_Mesh_API`、`RT_Solv_Def`           | 遗留兼容；新代码不用                    |
| `RT_Global_Ctx` MODULE 名为 `RT_Global_Ctx_Types` | `L5_RT/RT_Global_Ctx.f90`             | MODULE 名与文件名不一致；待修正           |


### 6.2 后缀迁移指南（从 `_Algo`/`_Ctx`）


| 若文件主要做…               | 新后缀优先选                       |
| --------------------- | ---------------------------- |
| KW/卡片字段→语义模型树         | **Map**                      |
| 只做名字/符号→内部 ID         | **Sym**                      |
| 选求解器/本构分支/分析路径        | **Strat**                    |
| 解一次代数迭代/牛顿内核          | **Solv**                     |
| 控制时间步长、载荷增量           | **Step**                     |
| 静态材料/单元/插件注册表         | **Reg**                      |
| vtable/函数指针运行时解析      | **Dsp**                      |
| 全局装配阶段机/管线            | **Asm**                      |
| 平坦 K+=Ke、无阶段语义        | **Glb**                      |
| 仅单元/IP 局部算子           | **Loc**                      |
| scratch、缓冲池、workspace | **Wsp**                      |
| MPI/设备/线程拓扑           | **Env**                      |
| 快照袋（计数、阶段 ID）         | **Run**                      |
| 步进控制流                 | **Step**                     |
| 仅薄 TYPE 合拍 + accessor | **Glu** 或 **Def**            |
| 专填 L4 Populate        | **Pop**                      |
| 专写回结果                 | **Wb**                       |
| 泛跨层适配                 | **Brg**                      |
| 仍难归类                  | **Ops** / **Proc** / **Orc** |


---

## 七、验收清单

### 7.1 目录结构

- 层级目录存在且命名正确（L1_IF … L6_AP）
- 域级目录存在且命名正确
- 子域目录存在且命名正确

### 7.2 模块命名

- MODULE 名以层缀开头
- MODULE 名与文件名一致
- 后缀使用 A–H 闭集，新文件禁止 `_Ops`/`_Algo` 默认后缀
- 无 `_Desc`/`_State`/`_Algo`/`_Ctx` 作文件后缀（新文件）
- 无数字尾巴 `*_*1`（新文件）
- 推荐迁移表中已标注的旧名→新名对应关系

### 7.3 TYPE 命名

- TYPE 名以层缀开头
- 四型后缀正确（`_Desc`/`_State`/`_Algo`/`_Ctx`）
- 四型 TYPE 定义在 `_Def.f90` 中

### 7.4 接口命名

- 子程序名以层缀开头
- 功能动词在可选集中（或新增已登记）
- 参数签名使用四型平级传递
- 每个哑参显式声明 INTENT

### 7.5 依赖关系

- 无循环依赖
- 无反向依赖
- 跨层通过 Bridge/Populate/WriteBack

---

## 八、参考文档


| 文档        | 路径                                          | 用途   |
| --------- | ------------------------------------------- | ---- |
| 架构总纲 v5.0 | `PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md`    | 上位设计 |
| 后缀闭集 v1.8 | `PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md`     | 后缀定义 |
| 命名规范 v2.0 | `REPORTS/UFC_命名规范与接口标准_v2.0.md`             | 命名标准 |
| 目录权威分类    | `PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md`      | 目录结构 |
| ABAQUS 映射 | `PPLAN/06_核心架构/UFC_ABAQUS核心子集_UFC层域映射骨架.md` | 功能映射 |


---

*最后更新：2026-04-22*
*文档版本：v2.0*