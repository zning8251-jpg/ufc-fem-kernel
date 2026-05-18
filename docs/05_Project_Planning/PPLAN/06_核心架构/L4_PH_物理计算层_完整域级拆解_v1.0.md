# L4_PH 物理计算层 — 完整域级拆解 v1.0

> **层级**: L4_PH (Physical Computation Layer)  
> **版本**: v1.0  
> **层级职责**: 本构模型、单元计算、接触计算、输出写入  
> **域级总数**: 8 个  
> **子域总数**: 19 个  
> **功能模块总数**: 108+ 个  
> **命名前缀**: `PH_` (Physical)

---

## 📋 L4_PH 层拓扑结构

```
L4_PH (物理计算层)
│
├─ Material — 本构模型计算（11 族 50+ 种）
├─ Element — 单元刚度/质量/内力计算
├─ Contact — 接触力与摩擦
├─ LoadBC — 载荷与边界条件施加
├─ Constraint — 约束条件处理
├─ Output — 结果输出写入
├─ Bridge — 与 L5_RT 连接
└─ WriteBack — 结果回写
```

---

## 🎯 一、八个域级完整拆解

### 1.1 域级 1: **Material** — 本构模型计算

**职责**: 11 族 50+ 种本构模型的应力-应变计算

**子域** (6 个):
- **Elastic** — 3 种弹性本构
- **Plastic** — 12 种塑性本构
- **HyperElastic** — 10 种超弹性
- **Advanced** — 20+ 种高级本构 (粘弹性/蠕变/损伤等)
- **Thermal** — 5 种热本构
- **DimAdapter** — 维度适配器 (3D↔2D↔1D)

**功能模块** (50+ 个):
```
PH_Mat_Desc.f90           — 本构参数表
PH_Mat_Umat.f90           — UMAT 主入口
PH_Mat_Vumat.f90          — VUMAT 主入口
PH_Mat_Elastic_Iso.f90    — 各向同性弹性本构
PH_Mat_Plastic_J2Iso.f90  — J2 等向强化
... (40+ 个本构模块)
PH_Util_DimAdapter.f90    — 维度适配 (新增)
PH_Mat_Ctx.f90            — 本构上下文
```

### 1.2 域级 2: **Element** — 单元计算

**职责**: 单元刚度、质量、内力计算

**子域** (3 个):
- **Stiffness** — 刚度矩阵计算
- **Mass** — 质量矩阵计算
- **Force** — 内力向量计算

**功能模块** (36+ 个):
```
PH_Elem_Desc.f90          — 单元元数据
PH_Elem_C3D8_Stiff.f90    — 8 节点六面体刚度
PH_Elem_C3D4_Stiff.f90    — 4 节点四面体刚度
PH_Elem_C3D8_Mass.f90     — 8 节点六面体质量
... (30+ 个单元计算模块)
PH_Elem_Ctx.f90           — 单元上下文
```

### 1.3 域级 3: **Contact** — 接触计算

**职责**: 接触力、摩擦力、接触检测

**子域** (3 个):
- **Detection** — 接触对检测
- **Force** — 接触力计算
- **Friction** — 摩擦力计算

**功能模块** (6 个):
```
PH_Cont_Desc.f90          — 接触定义
PH_Cont_Detection.f90     — 接触检测
PH_Cont_Force.f90         — 接触力
PH_Cont_Friction_Coulomb.f90 — Coulomb 摩擦
PH_Cont_Friction_Shear.f90 — 剪切摩擦
PH_Cont_Ctx.f90           — 接触上下文
```

### 1.4 域级 4: **LoadBC** — 载荷与边界条件

**职责**: 点载荷、分布载荷、边界条件施加

**子域** (3 个):
- **Concentrated** — 集中载荷
- **Distributed** — 分布载荷
- **Thermal** — 热载荷

**功能模块** (6 个):
```
PH_Load_Desc.f90          — 载荷定义
PH_Load_Conc.f90          — 集中载荷
PH_Load_Dist.f90          — 分布载荷
PH_Load_Thermal.f90       — 热载荷
PH_Load_TimeHistory.f90   — 时间历程载荷
PH_Load_Ctx.f90           — 载荷上下文
```

### 1.5 域级 5: **Constraint** — 约束条件处理

**职责**: MPC、RBE、耦合约束处理

**子域** (2 个):
- **MPC** — 多点约束处理
- **RBE** — 刚体单元处理

**功能模块** (4 个):
```
PH_Const_Desc.f90         — 约束定义
PH_Const_MPC.f90          — MPC 处理
PH_Const_RBE.f90          — RBE 处理
PH_Const_Ctx.f90          — 约束上下文
```

### 1.6 域级 6: **Output** — 结果输出

**职责**: 应力/应变/位移输出、ODB 写入

**子域** (2 个):
- **FieldOutput** — 场变量输出
- **HistoryOutput** — 历史输出

**功能模块** (4 个):
```
PH_Out_Desc.f90           — 输出配置
PH_Out_Field.f90          — 场输出计算
PH_Out_History.f90        — 历史输出
PH_Out_Ctx.f90            — 输出上下文
```

### 1.7 域级 7: **Bridge** — 与 L5_RT 连接

**职责**: 物理计算 → 运行时的数据映射

**功能模块** (2 个):
```
PH_Bridge_L5.f90          — PH→RT 数据转换
PH_Bridge_Ctx.f90         — 桥接上下文
```

### 1.8 域级 8: **WriteBack** — 结果回写

**职责**: 计算结果持久化、检查点保存

**功能模块** (2 个):
```
PH_WB_ODB.f90             — ODB 回写
PH_WB_Ctx.f90             — 回写上下文
```

---

## 📊 二、L4_PH 层模块统计

| 序号 | 域级 | 子域数 | 模块数 | 关键功能 | 优先级 |
|------|------|--------|--------|----------|--------|
| 1 | Material | 6 | 50+ | 本构模型计算 | ⭐⭐⭐ |
| 2 | Element | 3 | 36+ | 单元计算 | ⭐⭐⭐ |
| 3 | Contact | 3 | 6 | 接触/摩擦 | ⭐⭐ |
| 4 | LoadBC | 3 | 6 | 载荷施加 | ⭐⭐ |
| 5 | Constraint | 2 | 4 | 约束处理 | ⭐⭐ |
| 6 | Output | 2 | 4 | 结果输出 | ⭐⭐ |
| 7 | Bridge | 0 | 2 | 层间连接 | ⭐⭐ |
| 8 | WriteBack | 0 | 2 | 结果回写 | ⭐⭐ |
| **合计** | | **19** | **108+** | | |

---

## 🔗 三、命名规范

**层前缀**: `PH_`

**子域前缀**:
- Material → PH_Mat_* / PH_Util_DimAdapter（新增）
- Element → PH_Elem_*
- Contact → PH_Cont_*
- LoadBC → PH_Load_*
- Constraint → PH_Const_*
- Output → PH_Out_*
- Bridge → PH_Bridge_*
- WriteBack → PH_WB_*

**特殊约束**:
1. Material 50+ 模块按族分组存储，每族一个子目录
2. Element 36+ 模块需支持不同维度 (3D/2D/1D) 的自动适配
3. PH_Util_DimAdapter 是新增模块，用于 3D→2D/1D 的应力/应变转换
4. UMAT/VUMAT 主入口必须调用 Bridge 进行数据格式转换

---

## ✅ 交付清单

- ✅ 8 个域级、19 个子域、108+ 个模块的完整设计
- ✅ Material 域级包含 DimAdapter 新增模块
- ✅ 命名规范统一
- ✅ 与 L3_MD、L5_RT 的接口定义

**下一步**: 阶段 2.5 — L5_RT 层完整拆解
