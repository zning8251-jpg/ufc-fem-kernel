# L3_L4_L5 Material 域主辅 TYPE 嵌套重构计划

## 产品概述

对 UFC 内核的 `L3_MD`（模型数据层）、`L4_PH`（物理计算层）、`L5_RT`（运行时解算层）进行核心数据结构重构，实施“主 TYPE + 辅 TYPE”的多级嵌套架构（2-3层），以彻底解决原主 TYPE 过度扁平、字段归属不清的问题。

## 核心需求

- **垂直切片改造**：严格遵守《全域铺开执行计划》，**首批仅针对 P1 Material（材料域）**进行 L3→L4→L5 的完整垂直切片改造，待其完全跑通后再推进至 P2 Element 及其他域。
- **双轴体系对齐**：按照“6时相×8动词”（如 `Cfg`, `Pop`, `Stp`, `Inc`, `Itr`, `Lcl`）对原主 TYPE 中的平铺字段进行精准分组，提取为辅 TYPE。
- **四步走实施**：必须遵循“数据结构先行”的硬性约束：纯 TYPE 定义 → Init/Populate 初始化路径 → 算法热路径 → 去废弃字段与合同对齐。
- **语法与性能约束**：`_Def.f90` 强制使用 F2003 标准，嵌套深度 ≤ 3 层，热路径下的 L5 Bridge 辅 TYPE **禁止使用 ALLOCATABLE**。

## 架构设计

### 系统架构

- **核心数据模型**：采用 `Layer_Domain_四型(Desc/Ctx/State/Algo)` 作为主 TYPE，嵌套 `Layer_Domain_Phase_Verb_四型` 作为辅 TYPE。
- **双规范保障**：通过 `%cfg%matId` 等嵌套提供“语义索引”，同时保持 `MD_Mat_Domain%desc_array(:)` 等一维数组实现“扁平域存储”以确保连续内存访问性能。
- **数据流映射单向性**：L3 辅 TYPE (`MD_Mat_Desc.cfg`) → L4 辅 TYPE (`PH_Mat_Desc.cfg`) → L5 Bridge 辅 TYPE (`RT_Mat_Bridge_Ctx.stp/lcl`)。

### 核心目录结构与变更文件（P1 Material 切片）

```text
ufc_core/
├── L3_MD/Material/
│   ├── Contract/MD_Mat_Def.f90         # [修改] 引入 L3 辅 TYPE 分组（如 MD_Mat_Cfg_Init_Desc）
│   ├── Base/MD_Mat_BaseDef.f90         # [修改] Base 层数据结构对齐
│   └── Domain/MD_MatDomain_Def.f90     # [修改] Domain 容器访问路径适配
├── L4_PH/Material/
│   ├── PH_Mat_Aux_Def.f90              # [新增] 定义 Material 域核心辅 TYPE (F2003)
│   ├── PH_Mat_Domain_Core.f90     # [修改] 主 TYPE 迁入辅 TYPE，旧字段标记 DEPRECATED
│   ├── PH_Mat_Def.f90                  # [修改] re-export 导出新辅 TYPE
│   └── PH_Mat_Core.f90                 # [修改] 算法热路径读写切换为辅 TYPE
└── L5_RT/
    ├── Bridge/RT_Brg_Def.f90           # [修改] 材料 Bridge 辅 TYPE 按时相重组 (禁用 ALLOCATABLE)
    └── Material/RT_Mat_Core.f90        # [修改] L5 解算热路径适配桥接字段
```

## Agent Extensions

- **ufc-domain-pillar-closure**
  - Purpose: 指导贯通域柱闭环固化，确保 L3/L4/L5 垂直切片的数据契约同步与改版规则一致
  - Expected outcome: 成功完成 P1 Material 域的四链贯通闭环改造
- **fem-kernel-data-contract**
  - Purpose: 校验层间（特别是 Populate 和 Bridge 时相）的数据拷贝与序列化映射是否安全
  - Expected outcome: L3 到 L4 及 L4 到 L5 的辅 TYPE 嵌套字段实现精确的数据流传递
- **ufc-naming-checker**
  - Purpose: 对重构后的主 TYPE、辅 TYPE 及过程名执行自动化命名合规检查 (LINT-TYPE-001~005)
  - Expected outcome: 零警告通过 `{Layer}_{Domain}_{Phase}_{Verb}_{四型}` 等命名拦截规则

## 任务清单 (Task List)

1. **w1-step1-l4-type**: 创建 `PH_Mat_Aux_Def.f90` 并重构 L4 物理层材料主辅 TYPE 定义
2. **w1-step1-l3-type**: 重构 L3_MD 侧 `MD_Mat_Def.f90` 引入对应辅 TYPE 嵌套保留弃用字段
3. **w1-step1-l5-brg**: 重构 L5_RT Bridge 时相的辅 TYPE 剔除动态分配以确保热路径安全
4. **w1-step2-init**: 修改 L3/L4 初始化与 Bridge Populate 路径填充辅 TYPE 字段
5. **w1-step3-algo**: 重构 `PH_Mat_Core` 等算法热路径以通过嵌套路径读写数据
6. **w1-step4-cleanup**: 使用 `ufc-domain-pillar-closure` 技能清理 DEPRECATED 字段并更新合同
7. **w1-step4-verify**: 使用 `ufc-naming-checker` 技能校验命名合规并执行线弹性基线回归测试
