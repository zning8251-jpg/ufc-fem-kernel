# 四大功能集详细设计文档 — Material 域（模型层）

> **文档位置**: `L3_MD/Material/DESIGN_MatMD_FourTypes.md`
> **版本**: v1.0
> **最后更新**: 2026-03-31
> **关联规范**: [@00-域级划分规范.md](UFC/docs/六层架构拆分/00-总纲/00-域级划分规范.md)

---

## 1. 概述

本文档定义 L3_MD/Material 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：材料定义、材料模型描述、参数管理、UMAT 接口

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `id` | INTEGER(i4) | 材料 ID | MD_Mat_Desc |
| `materialType` | CHARACTER(LEN=32) | 材料类型 | MD_Mat_Desc |
| `props(:)` | REAL(wp), ALLOCATABLE | 材料参数数组 | MD_Mat_Desc |
| `nprops` | INTEGER(i4) | 参数数量 | MD_Mat_Desc |

**生命周期**：
- **写入阶段**：模型建立时（INPUT 解析）
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁时

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 步内只读，不进入热路径

---

### 2.2 State（状态型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `id` | INTEGER(i4) | 状态 ID | MD_MatState |
| `nIntPoints` | INTEGER(i4) | 积分点数 | MD_MatState |
| `stress(6)` | REAL(wp) | 应力张量 | MD_Mat_Base_State |
| `strain(6)` | REAL(wp) | 应变张量 | MD_Mat_Base_State |
| `statev(:)` | REAL(wp), ALLOCATABLE | 状态变量 | MD_MatState |

**生命周期**：
- **写入阶段**：每次增量步更新（由 L4_PH 回写）
- **读取阶段**：增量步内复用
- **释放时机**：增量步结束

**内存策略**：
- 温数据，Step 级 ALLOCATE

---

### 2.3 Algo（算法型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `method` | INTEGER(i4) | 积分方法 | MD_MatAlgo |
| `maxIter` | INTEGER(i4) | 最大迭代数 | MD_MatAlgo |
| `use_consistent_tangent` | LOGICAL | 一致切线开关 | MD_MatAlgo |
| `integration_scheme` | INTEGER(i4) | 积分格式 | MD_Mat_Base_Algo |

**积分方法枚举**：
- 1 = 隐式 (Implicit)
- 2 = 显式 (Explicit)
- 3 = 中点 (Midpoint)

**生命周期**：
- **写入阶段**：模型建立时
- **读取阶段**：迭代内只读
- **释放时机**：分析步结束

**内存策略**：
- 冷数据，可 ALLOCATABLE

---

### 2.4 Ctx（上下文型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `id` | INTEGER(i4) | 上下文 ID | MD_MatCtx |
| `ndir` | INTEGER(i4) | 法向分量数 | MD_MatCtx |
| `nshr` | INTEGER(i4) | 剪切分量数 | MD_MatCtx |
| `ntens` | INTEGER(i4) | 张量分量总数 | MD_MatCtx |
| `temp` | REAL(wp) | 温度 | MD_MatCtx |
| `dtime` | REAL(wp) | 时间增量 | MD_MatCtx |

**生命周期**：
- **写入阶段**：每次本构调用入口
- **读取阶段**：单次调用内
- **释放时机**：调用返回

**内存策略**：
- 热路径上下文，栈分配
- 64-byte 对齐

---

## 3. 依赖关系

```
MD_Model (L3) → MD_Mat_Desc (L3) → MD_MatState (L3)
MD_MatAlgo (L3) → MD_MatCtx (L3)
L4_PH/Material (L4) → L3_MD/Material (L3)  [材料计算]
L4_PH/Material (L4) → MD_Mat_Desc (L3)  [Desc 镜像]
```

---

## 4. 与 L4_PH/Material 的关系

| L3_MD | L4_PH | 说明 |
|-------|-------|------|
| MD_Mat_Desc | PH_Mat_Desc | 真相源 → 槽位镜像 |
| MD_MatState | PH_Mat_State | L4 更新 → 回写 L3 |
| MD_MatAlgo | PH_Mat_Algo | 静态配置 |
| MD_MatCtx | PH_Mat_Ctx | 临时上下文 |

---

## 5. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 含材料参数 | ✅ | ID/类型/props |
| State 含应力应变 | ✅ | 6 分量 |
| Algo 含积分方法 | ✅ | 隐式/显式/中点 |
| Ctx 含张量维度 | ✅ | ndir/nshr/ntens |
| UMAT 接口兼容 | ✅ | props/nprops |

---

**版本历史**：
- v1.0 (2026-03-31) - 初始版本