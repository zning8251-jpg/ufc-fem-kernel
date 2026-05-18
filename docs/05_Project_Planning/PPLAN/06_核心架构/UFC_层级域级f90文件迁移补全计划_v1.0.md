# UFC 层级-域级-文件 迁移补全计划

> **任务**: 基于推断清单v2.0,完整确定层级-域级/子域级的最终目录,给出每个功能模块下的f90子程序,完成迁移/补全
> **版本**: v1.0
> **日期**: 2026-04-17
> **状态**: 待执行

---

## 一、执行摘要

### 1.1 核心目标
- ✅ **完整确定**六层架构(L1-L6)的层级-域级/子域级最终目录结构
- ✅ **明确**每个功能模块下的`.f90`文件清单与子程序列表
- ✅ **完成**缺失文件的迁移/补全工作
- ✅ **建立**为下一步任务开展的坚实基础

### 1.2 现状统计

| 层级 | 推断清单文件数 | 实际存在文件数 | 缺失文件数 | 完成度 |
|------|---------------|---------------|-----------|--------|
| **L1_IF** | 50+ | 49 | ~15 | 75% |
| **L2_NM** | 100+ | 103 | ~20 | 80% |
| **L3_MD** | 350+ | 596 | ~50 (需整理) | 85% |
| **L4_PH** | 450+ | 809 | ~100 (需整理) | 78% |
| **L5_RT** | 80+ | 125 | ~25 | 70% |
| **L6_AP** | 30+ | 104 | ~15 | 65% |
| **合计** | **1000+** | **1786** | **~225** | **~77%** |

**注意**: 实际文件数超出推断清单是因为包含了大量单元测试、备份文件、OLD目录等,核心业务文件需进一步筛选。

### 1.3 关键发现

1. **L1_IF层**: AI域/Symbol域/Registry域需补全,Base域需重命名对齐
2. **L2_NM层**: 结构基本完整,需补充LinearSolver/NonlinearSolver域合同卡
3. **L3_MD层**: 文件数量庞大但分散,需整合Analysis/Material/Element域
4. **L4_PH层**: Material域11大族需系统化补全,Element域单元族需对齐
5. **L5_RT层**: Material/OLD目录需清理,Assembly域子程序需补全
6. **L6_AP层**: Input域已基本完整,Output/Job域需补全合同卡

---

## 二、L1_IF — 基础设施层 迁移补全计划

### 2.1 现有文件清单 (49个)

```
L1_IF/
├── AI/                          [1文件 - ⚠️ 需扩展]
│   └── IF_AI_Runtime.f90        (373行)
├── Base/                        [10文件 - ✅ 基本完整]
│   ├── IF_Base_Core.f90         (282行)
│   ├── IF_Base_Ctx.f90          (86行)
│   ├── IF_Base_DP.f90           (5622行 - 过大,需拆分)
│   ├── IF_Base_StructMeta.f90   (4575行 - 过大,需拆分)
│   ├── IF_Base_SymTbl.f90       (2406行)
│   ├── IF_Base_UnstructMeta.f90 (918行)
│   ├── IF_DeviceManager.f90     (814行 - ⚠️ 需重命名为IF_Device_Mgr.f90)
│   ├── IF_Math_Util.f90         (408行)
│   └── IF_Step_Type.f90         (38行 - ⚠️ 需重命名为IF_Step_Types.f90)
├── Error/                       [4文件 - ✅ 完整]
│   ├── IF_Err_API.f90           (310行)
│   ├── IF_Err_Core.f90          (142行)
│   ├── IF_Err_Reg.f90           (415行)
│   └── IF_Err_Type.f90          (390行)
├── IO/                          [11文件 - ✅ 完整]
│   ├── Checkpoint/              [6文件]
│   ├── IF_IO_Core.f90           (174行)
│   ├── IF_IO_File.f90           (737行)
│   ├── IF_IO_Filters.f90        (219行)
│   ├── IF_IO_Log.f90            (114行)
│   ├── IF_IO_Types.f90          (68行)
│   ├── IF_Parser.f90            (205行)
│   └── IF_Writer.f90            (216行)
├── Log/                         [3文件 - ✅ 完整]
│   ├── IF_Log_Core.f90          (192行)
│   ├── IF_Log_Logger.f90        (642行)
│   └── IF_Log_Types.f90         (52行)
├── Memory/                      [8文件 - ✅ 完整]
│   ├── IF_Mem_Chunk.f90         (175行)
│   ├── IF_Mem_Core.f90          (476行)
│   ├── IF_Mem_Mgr.f90           (644行)
│   ├── IF_Mem_Serial.f90        (759行)
│   ├── IF_Mem_ThreadSlab.f90    (314行)
│   ├── IF_Mem_WS.f90            (947行)
│   ├── IF_StructMemPool.f90     (8085行)
│   └── IF_UnstructMemPool.f90   (3182行)
├── Monitor/                     [3文件 - ✅ 完整]
│   ├── IF_Mon_Core.f90          (201行)
│   ├── IF_Monitor_Mgr.f90       (65行)
│   └── IF_Monitor_Types.f90     (97行)
├── Parallel/                    [3文件 - ✅ 完整 + CONTRACT.md]
│   ├── IF_ThreadWS_API.f90      (169行)
│   ├── IF_ThreadWS_Core.f90     (304行)
│   └── IF_ThreadWS_Types.f90    (242行)
├── Precision/                   [2文件 - ✅ 完整]
│   ├── IF_Const.f90             (123行)
│   └── IF_Prec.f90              (136行)
├── Registry/                    [1文件 - ⚠️ 需扩展]
│   └── IF_Reg_Core.f90          (342行)
├── Symbol/                      [1文件 - ⚠️ 需扩展]
│   └── IF_Sym_Core.f90          (198行)
└── IF_L1_LayerContainer_Core.f90 (149行)
```

### 2.2 缺失文件清单 (按优先级)

#### P0 - 必须补全 (Phase 1)

| 文件路径 | 说明 | 推断清单行数 | 优先级 |
|---------|------|------------|--------|
| `AI/IF_AI_Core.f90` | AI推理引擎核心(会话管理/批量推理/设备管理/缓存) | ~800 | 🔴 P0 |
| `AI/IF_AI_API.f90` | AI推理API接口(统一对外,供上层插槽调用) | ~400 | 🔴 P0 |
| `AI/IF_AI_Model_Loader.f90` | 模型加载器(.onnx/.pt格式支持+验证) | ~500 | 🔴 P0 |
| `AI/IF_AI_Tensor_Ops.f90` | 张量运算(MatMul/Conv/激活函数SIMD优化) | ~600 | 🔴 P0 |
| `AI/IF_AI_Preprocess.f90` | 数据预处理+后处理(归一化/特征提取/物理量映射) | ~400 | 🔴 P0 |
| `AI/IF_AI_Types.f90` | TYPE: AI描述符/状态/算法/上下文(统一合并) | ~300 | 🔴 P0 |

#### P1 - 重要补全 (Phase 2)

| 文件路径 | 说明 | 推断清单行数 | 优先级 |
|---------|------|------------|--------|
| `Base/IF_Device_Mgr.f90` | 设备管理器(重命名自IF_DeviceManager.f90) | ~814 | 🟡 P1 |
| `Base/IF_Step_Types.f90` | 分析步类型定义(重命名自IF_Step_Type.f90) | ~38 | 🟡 P1 |
| `Base/IF_Base_API.f90` | Base域统一API接口(新增) | ~150 | 🟡 P1 |
| `Base/IF_Base_Types.f90` | TYPE: Base描述符/状态/算法/上下文(新增) | ~200 | 🟡 P1 |
| `Registry/IF_Reg_Types.f90` | Registry域TYPE定义(新增) | ~150 | 🟡 P1 |
| `Registry/IF_Reg_State.f90` | Registry状态管理(新增) | ~200 | 🟡 P1 |

#### P2 - 扩展补全 (Phase 3)

| 文件路径 | 说明 | 推断清单行数 | 优先级 |
|---------|------|------------|--------|
| `Symbol/IF_Sym_Stress.f90` | 应力符号族(新增) | ~300 | 🟢 P2 |
| `Symbol/IF_Sym_Strain.f90` | 应变符号族(新增) | ~300 | 🟢 P2 |
| `Symbol/IF_Sym_Stiffness.f90` | 刚度符号族(新增) | ~350 | 🟢 P2 |
| `Symbol/IF_Sym_API.f90` | Symbol域统一API(新增) | ~200 | 🟢 P2 |
| `Symbol/IF_Sym_Types.f90` | Symbol域TYPE定义(新增) | ~250 | 🟢 P2 |

### 2.3 迁移任务清单

| 任务ID | 任务描述 | 源文件 | 目标文件 | 操作类型 | 优先级 |
|--------|---------|--------|---------|---------|--------|
| T-L1-001 | 重命名设备管理器 | `Base/IF_DeviceManager.f90` | `Base/IF_Device_Mgr.f90` | 重命名 | P1 |
| T-L1-002 | 重命名分析步类型 | `Base/IF_Step_Type.f90` | `Base/IF_Step_Types.f90` | 重命名 | P1 |
| T-L1-003 | 拆分IF_Base_DP.f90 | `Base/IF_Base_DP.f90` (5622行) | `Base/IF_Base_DP.f90` + `IF_Base_Consts.f90` | 拆分 | P1 |
| T-L1-004 | 拆分IF_Base_StructMeta.f90 | `Base/IF_Base_StructMeta.f90` (4575行) | `StructSchema/StructQuery/StructValidate` | 拆分 | P2 |

### 2.4 合同卡状态

| 域 | CONTRACT.md存在? | 状态 | 需补全 |
|---|-----------------|------|--------|
| AI | ❌ 缺失 | 🔴 需创建 | ✅ |
| Base | ❌ 缺失 | 🔴 需创建 | ✅ |
| Error | ❌ 缺失 | 🔴 需创建 | ✅ |
| IO | ❌ 缺失 | 🔴 需创建 | ✅ |
| Log | ❌ 缺失 | 🔴 需创建 | ✅ |
| Memory | ❌ 缺失 | 🔴 需创建 | ✅ |
| Monitor | ❌ 缺失 | 🔴 需创建 | ✅ |
| Parallel | ✅ 存在 | 🟢 完整 | ❌ |
| Precision | ❌ 缺失 | 🔴 需创建 | ✅ |
| Registry | ❌ 缺失 | 🔴 需创建 | ✅ |
| Symbol | ❌ 缺失 | 🔴 需创建 | ✅ |

---

## 三、L2_NM — 数值算法层 迁移补全计划

### 3.1 现有文件清单 (103个)

```
L2_NM/
├── Base/                        [7文件 + CONTRACT.md - ✅ 完整]
│   ├── NM_Base_Core.f90         (162行)
│   ├── NM_Types.f90             (166行)
│   ├── NM_Base_Norms.f90        (91行)
│   ├── NM_Base_Utils.f90        (67行)
│   ├── NM_Precision_Convert.f90 (72行)
│   ├── NM_Base_Constants.f90    (31行)
│   └── NM_Base_ErrCodes.f90     (39行)
├── Matrix/                      [10文件 - ✅ 完整]
│   ├── NM_Matrix_Types.f90      (293行)
│   ├── NM_Matrix_Core.f90       (1528行)
│   ├── NM_Matrix_Math.f90       (477行)
│   ├── NM_Matrix_Factorization.f90 (350行)
│   ├── NM_Matrix_Inversion.f90  (203行)
│   ├── NM_Matrix_MatMul.f90     (274行)
│   ├── NM_Sparse_Matrix_Core.f90 (1131行)
│   ├── NM_Assem_Sparse.f90      (220行)
│   ├── NM_LinAlg_Dense_Core.f90 (740行)
│   ├── NM_LinAlg_Domain_Core.f90 (194行)
│   └── NM_Vec_Core.f90          (408行)
├── Solver/                      [40+文件 - ✅ 完整但需整理]
│   ├── LinSolv/                 [20+文件]
│   ├── NonlinSolv/              [5文件]
│   ├── Conv/                    [6文件]
│   ├── Coupling/                [6文件]
│   ├── AI/                      [3文件]
│   └── 其他                     [5文件]
├── TimeInt/                     [11文件 - ✅ 完整]
│   ├── NM_TimeInt_Core.f90      (227行)
│   ├── NM_TimeInt_Newmark.f90   (357行)
│   ├── NM_TimeInt_HHT.f90       (335行)
│   ├── NM_TimeInt_RK.f90        (325行)
│   └── 其他                     [7文件]
├── Bridge/                      [5文件 - ✅ 完整]
│   ├── NM_Brg_Core.f90          (191行)
│   ├── NM_Direct_MUMPS_Brg.f90  (679行)
│   └── 其他                     [3文件]
├── ExternalLibs/                [11文件 - ✅ 完整]
│   ├── ModuleBlas.f90           (15380行)
│   ├── ModuleLapack.f90         (30206行)
│   └── 其他                     [9文件]
└── BVH/                         [3文件 - ⚠️ 需评估是否归属L2]
    ├── NM_BVH_API.f90           (212行)
    ├── NM_BVH_Core.f90          (170行)
    └── NM_BVH_Types.f90         (307行)
```

### 3.2 缺失文件清单

#### P1 - 重要补全

| 文件路径 | 说明 | 推断清单行数 | 优先级 |
|---------|------|------------|--------|
| `Solver/LinearSolver/CONTRACT.md` | LinearSolver域合同卡 | ~200 | 🟡 P1 |
| `Solver/NonlinearSolver/CONTRACT.md` | NonlinearSolver域合同卡 | ~200 | 🟡 P1 |
| `Matrix/CONTRACT.md` | Matrix域合同卡 | ~150 | 🟡 P1 |
| `TimeInt/CONTRACT.md` | TimeInt域合同卡 | ~150 | 🟡 P1 |

---

## 四、L3_MD — 模型数据层 迁移补全计划

### 4.1 现有文件清单 (596个 - 需整合)

**说明**: L3_MD文件数量庞大,包含大量业务文件、测试文件、桥接文件等,需系统化整合。

#### 核心域文件统计

| 域 | 文件数 | 状态 | 说明 |
|---|--------|------|------|
| Analysis/ | 12 | ✅ 完整 | Amplitude/Solver/Step子域 |
| Assembly/ | 5 | ✅ 完整 | 装配域 |
| Boundary/ | 6 | ✅ 完整 | 载荷边界条件 |
| Bridge/ | 18 | ✅ 完整 | Bridge_L4/Bridge_L5 |
| Constraint/ | 6 | ✅ 完整 | 约束处理 |
| Element/ | 15 | ✅ 完整 | 单元定义 |
| Field/ | 1 | ⚠️ 偏少 | 场变量 |
| Interaction/ | 16 | ✅ 完整 | 接触相互作用 |
| KeyWord/ | 15 | ✅ 完整 | 关键字解析 |
| Material/ | 200+ | 🔴 需整理 | 材料定义(含Contract/Base等子目录) |
| Mesh/ | 18 | ✅ 完整 | 网格管理 |
| Model/ | 22 | ✅ 完整 | 模型树 |
| Part/ | 7 | ✅ 完整 | 部件管理 |
| Section/ | 10 | ✅ 完整 | 截面属性 |
| WriteBack/ | 5 | ✅ 完整 | 状态回写 |

### 4.2 缺失文件清单

#### P1 - 重要补全

| 文件路径 | 说明 | 推断清单行数 | 优先级 |
|---------|------|------------|--------|
| `Analysis/CONTRACT.md` | Analysis域合同卡 | ~200 | 🟡 P1 |
| `Material/CONTRACT.md` | Material域合同卡 | ~300 | 🟡 P1 |
| `Element/CONTRACT.md` | Element域合同卡 | ~250 | 🟡 P1 |
| `Interaction/CONTRACT.md` | Interaction域合同卡 | ~250 | 🟡 P1 |
| `KeyWord/CONTRACT.md` | KeyWord域合同卡 | ~200 | 🟡 P1 |
| `Mesh/CONTRACT.md` | Mesh域合同卡 | ~200 | 🟡 P1 |
| `Model/CONTRACT.md` | Model域合同卡 | ~200 | 🟡 P1 |

---

## 五、L4_PH — 物理计算层 迁移补全计划

### 5.1 现有文件清单 (809个 - 需系统化整理)

#### 核心域文件统计

| 域 | 文件数 | 状态 | 说明 |
|---|--------|------|------|
| Material/ | 200+ | 🔴 需整理 | 11大材料族(含OLD/BACKUP目录) |
| Element/ | 300+ | 🔴 需整理 | 完整单元族(BEAM/SHELL/SOLID/ACOUSTIC等) |
| Contact/ | 15 | ✅ 完整 | 接触算法(Core/Search/Friction等) |
| LoadBC/ | 10 | ✅ 完整 | 载荷边界条件物理计算 |
| Field/ | 7 | ✅ 完整 | 场变量计算 |
| Constraint/ | 12 | ✅ 完整 | 约束处理(MPC/Tie/Periodic) |
| WriteBack/ | 4 | ✅ 完整 | 状态回写 |
| Bridge/ | 4 | ✅ 完整 | 跨层桥接 |

### 5.2 Material域11大族补全清单

#### 推断清单要求的55个文件 vs 实际存在

| 材料族 | 推断清单文件 | 实际存在 | 缺失 | 状态 |
|-------|------------|---------|------|------|
| **Elastic (ELA, 6种)** | 7 | ? | ? | 🔍 待确认 |
| **HyperElas (HYP, 8种)** | 9 | ? | ? | 🔍 待确认 |
| **Plastic (PLM, 8种)** | 9 | ? | ? | 🔍 待确认 |
| **Geotech (PLG, 6种)** | 7 | ? | ? | 🔍 待确认 |
| **PorousFoam (POR, 4种)** | 5 | ? | ? | 🔍 待确认 |
| **Damage (DMG, 6种)** | 7 | ? | ? | 🔍 待确认 |
| **Composite (CMP, 5种)** | 6 | ? | ? | 🔍 待确认 |
| **Visc (VSC, 5种)** | 6 | ? | ? | 🔍 待确认 |
| **Coupling (MPH, 4种)** | 5 | ? | ? | 🔍 待确认 |
| **Special (SPU, 3种)** | 4 | ? | ? | 🔍 待确认 |
| **UMAT (USR族)** | 4 | ? | ? | 🔍 待确认 |

**核心容器文件**:
- ✅ `PH_Mat_Domain_Core.f90` (存在,需确认位置)
- ✅ `PH_Mat_Ctx.f90` (存在)
- ✅ `PH_Mat_Reg_Core.f90` (存在)
- ✅ `PH_Mat_Eval.f90` (存在)

---

## 六、L5_RT — 运行时协调层 迁移补全计划

### 6.1 现有文件清单 (125个 - 含OLD目录需清理)

#### 核心域文件统计

| 域 | 文件数 | 状态 | 说明 |
|---|--------|------|------|
| Assembly/ | 18 | ✅ 完整 | 全局矩阵装配 |
| Bridge/ | 2 | ✅ 完整 | 跨层桥接 |
| Contact/ | 7 | ✅ 完整 | 接触运行时调度 |
| Coupling/ | 2 | ✅ 完整 | 多场耦合 |
| Element/ | 11 | ✅ 完整 | 单元运行时 |
| LoadBC/ | 4 | ✅ 完整 | 载荷边界条件 |
| Material/OLD/ | 20+ | 🔴 需清理 | 旧版材料运行时(应删除或归档) |
| Mesh/ | 5 | ✅ 完整 | 网格运行时 |
| Output/ | 7 | ✅ 完整 | 输出系统 |
| Solver/ | 15 | ✅ 完整 | 求解器调度 |
| StepDriver/ | 8 | ✅ 完整 | 步骤驱动器 |
| WriteBack/ | 5 | ✅ 完整 | 状态回写 |

### 6.2 缺失文件清单

#### P0 - 必须清理

| 任务 | 说明 | 优先级 |
|------|------|--------|
| 清理Material/OLD/ | 删除或归档旧版材料运行时目录 | 🔴 P0 |
| 清理Material_BACKUP_20260416/ | 删除备份目录(已无用途) | 🔴 P0 |

#### P1 - 重要补全

| 文件路径 | 说明 | 推断清单行数 | 优先级 |
|---------|------|------------|--------|
| `Assembly/CONTRACT.md` | Assembly域合同卡 | ~200 | 🟡 P1 |
| `Contact/CONTRACT.md` | Contact域合同卡 | ~200 | 🟡 P1 |
| `Solver/CONTRACT.md` | ✅ 已存在 | - | 🟢 完整 |
| `StepDriver/CONTRACT.md` | ✅ 已存在 | - | 🟢 完整 |

---

## 七、L6_AP — 应用层 迁移补全计划

### 7.1 现有文件清单 (104个)

#### 核心域文件统计

| 域 | 文件数 | 状态 | 说明 |
|---|--------|------|------|
| Input/ | 70+ | ✅ 完整 | Command/Parser/Script子域 |
| Output/ | 7 | ✅ 完整 | 输出格式化/后处理 |
| Job/ | 5 | ✅ 完整 | 作业管理 |
| Config/ | 2 | ✅ 完整 | 配置管理 |
| Registry/ | 1 | ✅ 完整 | 注册表 |
| Solver/ | 1 | ✅ 完整 | 求解器配置 |
| UI/ | 8 | ✅ 完整 | 用户界面 |
| Bridge/ | 4 | ✅ 完整 | 跨层桥接 |

### 7.2 缺失文件清单

#### P1 - 重要补全

| 文件路径 | 说明 | 推断清单行数 | 优先级 |
|---------|------|------------|--------|
| `Input/CONTRACT.md` | Input域合同卡 | ~200 | 🟡 P1 |
| `Output/CONTRACT.md` | Output域合同卡 | ~200 | 🟡 P1 |
| `Job/CONTRACT.md` | Job域合同卡 | ~150 | 🟡 P1 |
| `Config/CONTRACT.md` | Config域合同卡 | ~150 | 🟡 P1 |

---

## 八、执行计划与优先级

### 8.1 Phase 1 - 核心补全 (1-2周)

**目标**: 补全L1_IF层AI域/Symbol域/Registry域,清理L5_RT层OLD目录

| 任务ID | 任务描述 | 预计工时 | 负责人 | 状态 |
|--------|---------|---------|--------|------|
| P1-T001 | 补全L1_IF/AI域6个文件 | 3天 | - | ⏳ 待开始 |
| P1-T002 | 补全L1_IF/Symbol域5个文件 | 2天 | - | ⏳ 待开始 |
| P1-T003 | 补全L1_IF/Registry域2个文件 | 1天 | - | ⏳ 待开始 |
| P1-T004 | 重命名L1_IF/Base域2个文件 | 0.5天 | - | ⏳ 待开始 |
| P1-T005 | 清理L5_RT/Material/OLD/目录 | 0.5天 | - | ⏳ 待开始 |
| P1-T006 | 清理L5_RT/Material_BACKUP_20260416/目录 | 0.5天 | - | ⏳ 待开始 |

### 8.2 Phase 2 - 合同卡创建 (1周)

**目标**: 为所有域级创建CONTRACT.md合同卡文档

| 任务ID | 任务描述 | 预计工时 | 负责人 | 状态 |
|--------|---------|---------|--------|------|
| P2-T001 | 创建L1_IF层11个域合同卡 | 2天 | - | ⏳ 待开始 |
| P2-T002 | 创建L2_NM层7个域合同卡 | 1.5天 | - | ⏳ 待开始 |
| P2-T003 | 创建L3_MD层15个域合同卡 | 2天 | - | ⏳ 待开始 |
| P2-T004 | 创建L4_PH层9个域合同卡 | 1.5天 | - | ⏳ 待开始 |
| P2-T005 | 创建L5_RT层13个域合同卡 | 1.5天 | - | ⏳ 待开始 |
| P2-T006 | 创建L6_AP层8个域合同卡 | 1天 | - | ⏳ 待开始 |

### 8.3 Phase 3 - Material域系统化 (2-3周)

**目标**: 补全L4_PH/Material域11大族55个文件

| 任务ID | 任务描述 | 预计工时 | 负责人 | 状态 |
|--------|---------|---------|--------|------|
| P3-T001 | 补全Elastic族(6种材料) | 2天 | - | ⏳ 待开始 |
| P3-T002 | 补全HyperElas族(8种材料) | 2天 | - | ⏳ 待开始 |
| P3-T003 | 补全Plastic族(8种材料) | 2天 | - | ⏳ 待开始 |
| P3-T004 | 补全Geotech族(6种材料) | 2天 | - | ⏳ 待开始 |
| P3-T005 | 补全PorousFoam族(4种材料) | 1.5天 | - | ⏳ 待开始 |
| P3-T006 | 补全Damage族(6种材料) | 2天 | - | ⏳ 待开始 |
| P3-T007 | 补全Composite族(5种材料) | 2天 | - | ⏳ 待开始 |
| P3-T008 | 补全Visc族(5种材料) | 2天 | - | ⏳ 待开始 |
| P3-T009 | 补全Coupling族(4种材料) | 1.5天 | - | ⏳ 待开始 |
| P3-T010 | 补全Special族(3种材料) | 1天 | - | ⏳ 待开始 |
| P3-T011 | 补全UMAT族(用户材料) | 2天 | - | ⏳ 待开始 |

### 8.4 Phase 4 - Element域对齐 (2-3周)

**目标**: 补全L4_PH/Element域完整单元族

| 任务ID | 任务描述 | 预计工时 | 负责人 | 状态 |
|--------|---------|---------|--------|------|
| P4-T001 | BEAM单元族完整性检查与补全 | 2天 | - | ⏳ 待开始 |
| P4-T002 | SHELL单元族完整性检查与补全 | 2天 | - | ⏳ 待开始 |
| P4-T003 | SOLID2D单元族完整性检查与补全 | 1.5天 | - | ⏳ 待开始 |
| P4-T004 | SOLID3D单元族完整性检查与补全 | 2天 | - | ⏳ 待开始 |
| P4-T005 | ACOUSTIC单元族完整性检查与补全 | 1.5天 | - | ⏳ 待开始 |
| P4-T006 | 特殊单元族(SPRING/DASHPOT/MASS等)补全 | 2天 | - | ⏳ 待开始 |

### 8.5 Phase 5 - 最终验证与文档生成 (1周)

**目标**: 生成最终层级-域级-文件完整映射清单,验证命名规范

| 任务ID | 任务描述 | 预计工时 | 负责人 | 状态 |
|--------|---------|---------|--------|------|
| P5-T001 | 生成最终映射清单(Markdown) | 1天 | - | ⏳ 待开始 |
| P5-T002 | 验证所有f90文件命名规范 | 1天 | - | ⏳ 待开始 |
| P5-T003 | 编写迁移补全总结报告 | 1天 | - | ⏳ 待开始 |
| P5-T004 | 代码审查与质量检查 | 1天 | - | ⏳ 待开始 |

---

## 九、命名规范验证清单

### 9.1 三级命名体系

| 层级 | 前缀 | 域缩写 | 示例 |
|------|------|--------|------|
| L1_IF | `IF_` | Base/Err/IO/Mem/Mon/Par/Prec/Reg/Sym | `IF_Base_Core.f90` |
| L2_NM | `NM_` | Base/Mtx/Solv/TInt/Brg | `NM_Base_Core.f90` |
| L3_MD | `MD_` | Mat/Elem/Mesh/Step/Bound | `MD_Mat_Core.f90` |
| L4_PH | `PH_` | Mat/Elem/Cont/Load/Fld | `PH_Mat_Core.f90` |
| L5_RT | `RT_` | Asm/Cont/Elem/Solv/Step | `RT_Asm_Core.f90` |
| L6_AP | `AP_` | Inp/Out/Job/Cfg/UI | `AP_Inp_Core.f90` |

### 9.2 待重命名文件清单

| 当前名称 | 标准名称 | 原因 |
|---------|---------|------|
| `IF_DeviceManager.f90` | `IF_Device_Mgr.f90` | Manager→_Mgr缩写规范 |
| `IF_Step_Type.f90` | `IF_Step_Types.f90` | 单数→复数,与其他域对齐 |

---

## 十、风险与依赖

### 10.1 技术风险

| 风险项 | 影响 | 缓解措施 |
|--------|------|---------|
| IF_Base_DP.f90过大(5622行) | 编译慢/维护困难 | Phase 1拆分为精度定义+常量+工具函数 |
| IF_Base_StructMeta.f90过大(4575行) | 编译慢/维护困难 | Phase 2拆分为Schema/Query/Validate |
| L4_PH/Material域文件分散 | 难以定位/重复定义 | Phase 3系统化整理11大族 |
| L5_RT/Material/OLD/目录 | 混淆/编译冲突 | Phase 1立即清理 |

### 10.2 依赖关系

```
Phase 1 (核心补全)
  ↓
Phase 2 (合同卡创建)
  ↓
Phase 3 (Material域系统化) ← 依赖Phase 2合同卡
  ↓
Phase 4 (Element域对齐) ← 依赖Phase 3材料域
  ↓
Phase 5 (最终验证与文档生成)
```

---

## 十一、交付物清单

### 11.1 Phase 1-4交付物

- ✅ 补全的`.f90`源文件(~225个)
- ✅ 重命名的`.f90`源文件(2个)
- ✅ 拆分的`.f90`源文件(3个)
- ✅ 创建的`CONTRACT.md`文档(63个)
- ✅ 清理的OLD/BACKUP目录(2个)

### 11.2 Phase 5交付物

- 📄 `UFC_层级-域级-文件完整映射清单_v3.0.md`
- 📄 `UFC_命名规范验证报告.md`
- 📄 `UFC_迁移补全总结报告.md`

---

## 十二、下一步行动

### 12.1 立即执行 (今天)

1. ✅ **审查本计划** - 确认任务范围与优先级
2. ⏳ **启动Phase 1** - 开始L1_IF/AI域补全
3. ⏳ **创建任务分支** - `git checkout -b feature/migration-completion`

### 12.2 本周内完成

1. ⏳ **完成Phase 1** - L1_IF核心补全+L5_RT清理
2. ⏳ **启动Phase 2** - 开始合同卡创建

### 12.3 本月内完成

1. ⏳ **完成Phase 2-4** - 合同卡+Material域+Element域
2. ⏳ **完成Phase 5** - 最终验证与文档生成

---

## 附录A: 推断清单与实际目录对比详细表

(此表将在执行Phase 5时生成完整版本)

## 附录B: CONTRACT.md模板

```markdown
# [Domain] 域合同卡

> **层级**: L[1-6]_[Layer]
> **域**: [Domain_Name]
> **版本**: v1.0
> **状态**: Draft/Active/Stable

---

## 一、基本信息

- **域名**: [Domain]
- **层级**: L[X]_[Layer]
- **父域**: [Parent Domain]
- **子域**: [Sub-domains]
- **状态**: Draft
- **一句话职责**: [职责描述]

## 二、职责边界

### 本域负责
- [职责1]
- [职责2]

### 本域不负责
- [非职责1]
- [非职责2]

## 三、四类TYPE映射

| TYPE | 是否必需 | 生命周期 | 所有权 | 跨层传递 |
|------|---------|---------|--------|---------|
| Desc | ✅ | 初始化后只读 | 本域 | 允许 |
| State | ✅ | 运行时更新 | 本域 | 禁止 |
| Algo | ✅ | 初始化后只读 | 本域 | 允许 |
| Ctx | ✅ | 调用级 | 调用方 | 允许 |

## 四、四链映射

- **理论链**: [理论依据]
- **逻辑链**: [逻辑关系]
- **计算链**: [计算流程]
- **数据链**: [数据生命周期]

## 五、核心接口

### 对外API
- [API1]
- [API2]

### 对内实现
- [内部函数1]
- [内部函数2]

## 六、错误码

| 错误码 | 说明 | 处理策略 |
|--------|------|---------|
| L[X]:[XXXX] | [错误描述] | [处理策略] |

## 七、依赖关系

### 依赖的下层域
- L[X-1]_[Domain1]
- L[X-1]_[Domain2]

### 被上层依赖
- L[X+1]_[Domain3]
- L[X+1]_[Domain4]

## 八、测试策略

- **单元测试**: [测试范围]
- **集成测试**: [测试范围]
- **性能测试**: [测试范围]

---

**最后更新**: YYYY-MM-DD
**审查人**: [Name]
**批准人**: [Name]
```

---

**文档结束**
