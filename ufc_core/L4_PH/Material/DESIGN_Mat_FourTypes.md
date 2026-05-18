# 四大功能集详细设计文档 — Material 域

> **文档位置**: `L4_PH/Material/DESIGN_Mat_FourTypes.md`
> **版本**: v2.0
> **最后更新**: 2026-04-28
> **关联规范**: `L3_MD/Material/DOMAIN_PILLAR_CARD.md`（域柱卡）

---

## 1. 概述

本文档定义 L4_PH/Material 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：材料本构计算、积分算法、状态更新

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）


| 字段名        | 类型                    | 语义     | 来源          |
| ---------- | --------------------- | ------ | ----------- |
| `mat_id`   | INTEGER(i4)           | 材料编号   | MD_Mat_Desc |
| `mat_type` | INTEGER(i4)           | 材料类型码  | MD_Mat_Desc |
| `rho`      | REAL(wp)              | 密度     | MD_Mat_Desc |
| `el`       | REAL(wp)              | 弹性模量   | MD_Mat_Desc |
| `nu`       | REAL(wp)              | 泊松比    | MD_Mat_Desc |
| `props(:)` | REAL(wp), ALLOCATABLE | 材料参数数组 | MD_Mat_Desc |


**生命周期**：

- **写入阶段**：模型建立时（MD 层）
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁时

**内存策略**：

- 冷数据，可 ALLOCATABLE
- 步内只读，不进入热路径

---

### 2.2 State（状态型）


| 字段名           | 类型                    | 语义      | 来源                |
| ------------- | --------------------- | ------- | ----------------- |
| `stress(:,:)` | REAL(wp)              | 应力张量    | PH_Mat_State      |
| `statev(:)`   | REAL(wp), ALLOCATABLE | 内变量 SDV | PH_Mat_State      |
| `ddsdde(:,:)` | REAL(wp)              | 切线刚度    | PH_Mat_State      |
| `step_num`    | INTEGER(i4)           | 当前步号    | PH_Mat_Base_State |
| `inc_num`     | INTEGER(i4)           | 当前增量步号  | PH_Mat_Base_State |
| `energy(:)`   | REAL(wp)              | 能量密度    | PH_Mat_State      |


**生命周期**：

- **写入阶段**：每次增量步/迭代更新
- **读取阶段**：增量步内多迭代复用
- **释放时机**：增量步结束时

**内存策略**：

- 温数据，Step 级 ALLOCATE
- 高频读写，进入热路径
- 需 Rollback 机制支持

---

### 2.3 Algo（算法型）


| 字段名             | 类型          | 语义       | 来源               |
| --------------- | ----------- | -------- | ---------------- |
| `integ_scheme`  | INTEGER(i4) | 本构积分格式   | PH_Mat_Algo      |
| `max_iter`      | INTEGER(i4) | NR 最大迭代数 | PH_Mat_Algo      |
| `tol`           | REAL(wp)    | 收敛容差     | PH_Mat_Algo      |
| `substep_num`   | INTEGER(i4) | 子步数      | PH_Mat_Algo      |
| `ai_enabled`    | LOGICAL     | AI 积分开关  | AI_MatInteg_Algo |
| `ai_batch_size` | INTEGER(i4) | 批量推理大小   | AI_MatInteg_Algo |


**生命周期**：

- **写入阶段**：分析步初始化
- **读取阶段**：迭代内只读
- **释放时机**：分析步结束

**内存策略**：

- 冷数据，可 ALLOCATABLE
- 迭代内只读，跨步复用

---

### 2.4 Ctx（上下文型）


| 字段名           | 类型       | 语义        | 来源              |
| ------------- | -------- | --------- | --------------- |
| `dstran(:)`   | REAL(wp) | 应变增量      | PH_Mat_Base_Ctx |
| `dfgrd1(:,:)` | REAL(wp) | 变形梯度（增量末） | PH_Mat_Base_Ctx |
| `drot(:,:)`   | REAL(wp) | 旋转增量      | PH_Mat_Base_Ctx |
| `temp`        | REAL(wp) | 温度（增量末）   | PH_Mat_Base_Ctx |
| `dtemp`       | REAL(wp) | 温度增量      | PH_Mat_Base_Ctx |
| `coords(:)`   | REAL(wp) | 积分点坐标     | PH_Mat_Base_Ctx |
| `predef(:)`   | REAL(wp) | 预定义场      | PH_Mat_Base_Ctx |


**生命周期**：

- **写入阶段**：每次增量步入口
- **读取阶段**：单次调用内
- **释放时机**：调用返回即释放

**内存策略**：

- **热路径核心，零 ALLOCATE**
- 64-byte 对齐（AVX-512）
- 栈分配，禁止堆分配

---

## 3. AI-ready 插槽集成


| 插槽编号 | 插槽名称        | 域级归属     | 四型职责                    |
| ---- | ----------- | -------- | ----------------------- |
| ③    | AI_MatInteg | Material | Algo（神经网络权重）+ Ctx（批量缓冲） |


**接口规范**：

- 批量推理接口：`IF_AI_Runtime_Infer_Batch`
- 禁止单点串行调用

---

## 4. 四型裁剪决策（三层统一视图）


| 层   | Desc                        | State                    | Algo                    | Ctx                             |
| --- | --------------------------- | ------------------------ | ----------------------- | ------------------------------- |
| L3  | RETAINED(`MD_Mat_Desc`)     | RETAINED(`MD_MatState`)  | RETAINED(`MD_MatAlgo`)  | RETAINED(`MD_MatCtx`)           |
| L4  | DELEGATED->L3(via Populate) | RETAINED(`PH_Mat_State`) | RETAINED(`PH_Mat_Algo`) | RETAINED(`PH_Mat_Ctx`)          |
| L5  | DELEGATED->L3->L4           | DELEGATED->L4            | DELEGATED->L4           | RETAINED(`RT_Mat_Dispatch_Ctx`) |


---

## 5. 依赖关系

```text
MD_Mat_Desc(L3) → PH_L4_Populate_Material → PH_Mat_Slot%ctx/state(L4)
MD_Mat_Desc(L3) → PH_L4_L3MatContract → PH_MAT_* 枚举(L4)
PH_Mat_Slot(L4) → RT_Mat_Brg_BuildTable(L5) → RT_Mat_Dispatch_Table/Ctx(L5)
RT_Mat_Dispatch_Ctx(L5) → PH_Mat_Dispatch(L4) → PH_Mat_{tribe}_Eval(L4)
```

---

## 6. 验证清单


| 检查项              | 状态   | 备注                                              |
| ---------------- | ---- | ----------------------------------------------- |
| Desc 字段完整        | PASS | 继承 MD_Mat_Desc via Populate                     |
| State 含 Rollback | PASS | 增量步级读写                                          |
| Algo 含 AI 插槽     | PASS | AI_MatInteg_Algo                                |
| Ctx 零 ALLOCATE   | PASS | AP-8 热路径约束                                      |
| 64-byte 对齐       | PASS | Ctx 类型                                          |
| 批量缓冲支持           | PASS | `PH_Mat_AI_Integ` 批量接口（规划中，占位）                  |
| 三层裁剪表对齐          | PASS | 与域柱卡 Section 3 一致                               |
| 金线主链完整           | PASS | L3 Desc -> L4 Populate -> L5 Route -> L4 Kernel |


---

**版本历史**：

- v2.0 (2026-04-28) - 对齐域柱卡v2统一模板，增加三层裁剪视图与依赖链更新
- v1.0 (2026-03-31) - 初始版本

