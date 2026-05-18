# UFC 算法步规约总索引

> **版本**: v1.0 | **日期**: 2026-04-26
>
> **定位**: 全层全域算法步规约 (Algorithm Step Protocol) 的统一入口。
>
> **关联**:
> - 方法论模板: [ALGORITHM_STEP_PROTOCOL.md](../../templates/ALGORITHM_STEP_PROTOCOL.md)
> - 推演卡总索引: [DERIVATION_CARD_INDEX.md](DERIVATION_CARD_INDEX.md)
> - 跨域数据流: [ASP_CROSS_DOMAIN_FLOW.md](ASP_CROSS_DOMAIN_FLOW.md)

---

## 文件清单

### 方法论与基础设施

| 文件 | 内容 | 说明 |
|------|------|------|
| [ALGORITHM_STEP_PROTOCOL.md](../../templates/ALGORITHM_STEP_PROTOCOL.md) | 方法论模板 | 三原则、推导流程、五要素格式、闭合性验证 |
| [ASP_CROSS_DOMAIN_FLOW.md](ASP_CROSS_DOMAIN_FLOW.md) | 全栈跨域数据流图 | L6→L3→L4→L5→L3 端到端追踪 (v1.1: 含存储层) |
| [ASP_STORAGE_CROSS_CUT.md](ASP_STORAGE_CROSS_CUT.md) | **三级存储横切面** | **19 步存储算法规约 + 15 项闭合矩阵** 🆕 |
| [THREE_TIER_STORAGE.md](THREE_TIER_STORAGE.md) | **三级存储架构设计** | **10 池正交矩阵 + Spill/Reload + 持久化** 🆕 |
|| [L1_IF_INTEGRATION.md](L1_IF_INTEGRATION.md) | **L1_IF 基础设施融合** | **8 维度: 容器/SymTbl/错误链/线程安全/监控/Checkpoint/配置/AI** |

### 黄金样板（三种域类型详细范例）

| 文件 | 域 | 类型 | 过程数 | 闭合数据项 |
|------|-----|------|--------|-----------|
| [ASP_GOLDEN_PH_Mat_Elas.md](ASP_GOLDEN_PH_Mat_Elas.md) | L4_PH/Material/Elas | 计算域 | 7 (含 Bridge) | 12 |
| [ASP_GOLDEN_RT_StepDriver.md](ASP_GOLDEN_RT_StepDriver.md) | L5_RT/StepDriver | 编排域 | 14 | 15 |
| [ASP_GOLDEN_MD_Model.md](ASP_GOLDEN_MD_Model.md) | L3_MD/Model | 数据域 | 10 | 8 |

### 按层算法步规约

| 文件 | 层 | 域数 | 过程总数 |
|------|-----|------|---------|
| [ASP_L1_IF.md](ASP_L1_IF.md) | L1_IF 基础设施层 | 8 (+StorageMgr) | ~72 |
| [ASP_L2_NM.md](ASP_L2_NM.md) | L2_NM 数值方法层 | 5 | ~47 |
| [ASP_L3_MD.md](ASP_L3_MD.md) | L3_MD 模型描述层 | 15 | ~114 |
| [ASP_L4_PH.md](ASP_L4_PH.md) | L4_PH 物理层 | 7 | ~53 |
| [ASP_L5_RT.md](ASP_L5_RT.md) | L5_RT 运行时层 | 10 | ~86 |
| [ASP_L6_AP.md](ASP_L6_AP.md) | L6_AP 应用层 | 8 | ~60 |

---

## 统计摘要

| 指标 | 数值 |
|------|------|
| 总层数 | 6 |
| 总域数 | 53 (+1 StorageMgr 横切) |
| 总过程数 | ~420 (+19 存储步) |
| 黄金样板 | 3（计算/编排/数据） |
| 跨域闭合数据项 | 28（20 核心 + 8 存储层, ASP_CROSS_DOMAIN_FLOW v1.1 验证） |
| 独立规约文件 | 13（3 黄金 + 6 层级 + 1 跨域 + 1 存储横切 + 1 存储架构 + 1 基础设施融合） |

---

## 域类型 → 算法步模式对照

| 域类型 | 代表样板 | 典型步模式 | HOT_PATH? |
|--------|---------|-----------|-----------|
| **计算域** | PH_Mat_Elas | Populate → Config(Validate+Init) → Local(Build+Compute) | ✓ 热 |
| **编排域** | RT_StepDriver | Config(Init) → Populate → Step{Inc{Iter(NR)}} | ✓ 热 |
| **数据域** | MD_Model | Init → CRUD(Add/Set/Get) → Validate → Finalize | ✗ 冷 |
| **桥接域** | L3_MD/Bridge | 读源 → 映射 → 写目标 | ✗ 冷 |
| **观测域** | L5_RT/Logging | 事件触发 → 格式化 → 输出 | ✗ 冷 |
| **工具域** | L2_NM/Base | 纯函数(IN→OUT), 无状态 | 取决于调用者 |
| **分发域** | L4_PH/Material | SELECT CASE → 族内核调用 | ✓ 热 |
| **横切域** | L1/StorageMgr | Init→Alloc→Spill/Reload→Finalize (全 Phase) | 部分热(Alloc) |

---

## 使用指南

### 新域开发流程

```
1. 确定域类型（参照上表）
2. 从 DERIVATION_CARD 获取过程清单
3. 选择对应黄金样板作为模式参考
4. 按 ALGORITHM_STEP_PROTOCOL 模板展开五要素
5. 填写闭合性验证矩阵
6. 与 ASP_CROSS_DOMAIN_FLOW 对照跨域数据
7. 编写 Fortran 实现
```

### 代码审查检查项

- [ ] 每个过程的 [IN]/[OUT] 是否与 ASP 声明一致
- [ ] 跨域数据是否通过 Bridge/Populate 而非直读
- [ ] 热路径过程是否标注了 Phase 注释
- [ ] 闭合性矩阵无悬空项
- [ ] 前置/后置条件是否有对应的运行时检查或测试

### 测试生成

每个 Step 的前置/后置条件可直接转化为测试断言：

```fortran
! 来自 ASP_GOLDEN_PH_Mat_Elas Step 1 后置保证
CALL PH_Mat_Elas_Validate_Props(2, [210.0e3_wp, 0.3_wp], status)
CALL assert_equal(status, 0, "valid props should pass")

CALL PH_Mat_Elas_Validate_Props(2, [-1.0_wp, 0.3_wp], status)
CALL assert_not_equal(status, 0, "negative E should fail")
```
