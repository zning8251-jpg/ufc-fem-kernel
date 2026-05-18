# Phase 4 主线：核心闭环链验收追踪

> **版本**: v1.1 · **日期**: 2026-05-11  
> **顺序**: `StepDriver → Assembly → Element → Material → Solver`  
> **验收表**: [`06_域级落地验收表_CodeReview与里程碑.md`](06_域级落地验收表_CodeReview与里程碑.md)（A / A+ / B / C 四轴：A1–A6、**A7–A11** 扩展、B、C）  
> **子总纲**: [`../子总纲/L5_RT_子总纲.md`](../子总纲/L5_RT_子总纲.md) · [`../子总纲/L4_PH_子总纲.md`](../子总纲/L4_PH_子总纲.md)  
> **主轴与波次（叙事 + PR 声明 + 波次 0↔本表）**: [`../03_实施规划/实施路线/L3_L4_L5_二元结构主轴与波次路线图.md`](../03_实施规划/实施路线/L3_L4_L5_二元结构主轴与波次路线图.md)

---

## 1. 逐域检查清单（CONTRACT → 实现 → A / A+ / B / C）

| 顺序 | 域（路径） | CONTRACT | 实现锚点 | A 合同+十件套 | **A+** 坐标·边界·六参·横切·门禁 | B 命名+依赖 | C 证据 |
|------|------------|----------|----------|---------------|----------------------------------|-------------|--------|
| 1 | `L5_RT/StepDriver` | `CONTRACT.md` | `RT_StepDriver_*`、`RT_Step_*` | ☐ | ☐ | ☐ | ☐ harness/编译 |
| 2 | `L5_RT/Assembly` | `CONTRACT.md` | `RT_Asm_*`、`RT_Assembly_Domain_Core` | ☐ | ☐ | ☐ | ☐ 热路径零 L3 |
| 3 | `L4_PH/Element` | `CONTRACT.md` | `PH_Element_Domain_Core` | ☐ | ☐ | ☐ | ☐ `Compute_Ke` 金线 |
| 4 | `L4_PH/Material` | `CONTRACT.md` | `PH_Mat_Domain_Core` | ☐ | ☐ | ☐ | ☐ slot_pool |
| 5 | `L2_NM/Solver`（经 L5） | `L2_NM/Solver/CONTRACT.md`（若缺则补） | `NM_LinSolv_*` 等 | ☐ | ☐ | ☐ | ☐ 单测/smoke |

**通过定义**：每行 **A、A+、B、C** 全勾选且无硬约束违反（见验收表 §0–§2；**A+** 不适用项须标 N/A 并附理由）。

---

## 2. 与桥接前提的依赖

- 闭环链 **2–4** 依赖 **Phase 4 前提**完成：见 [`Phase4_L3L4桥接_收敛说明.md`](Phase4_L3L4桥接_收敛说明.md)。  
- **WriteBack** 不在上表顺序内，但每个 Incr 收敛后须满足 **白名单写回**（建议在 Assembly/StepDriver 里程碑中追加 C 证据）。

---

## 3. PR 勾选模板（粘贴到 PR 描述）

**主轴声明（层 / 域 / 合同·Bridge·SIO）** — 与 [`L3_L4_L5_二元结构主轴与波次路线图.md`](../03_实施规划/实施路线/L3_L4_L5_二元结构主轴与波次路线图.md) §1 一致：

```
L3/L4/L5 主轴：
- 层：L3_MD / L4_PH / L5_RT（勾选或写无）
- 域：ufc_core/__________
- CONTRACT：改 / 无（理由）__________
- Bridge：改 / 无 __________
- SIO（*_Arg / *_Proc / 五参·六参）：改 / 无 __________
```

**核心闭环链（Phase4）**：
- [ ] StepDriver CONTRACT 与 RT_StepDriver 实现一致
- [ ] Assembly 热路径零 L3 + CONTRACT
- [ ] Element 金线 Compute_Ke + CONTRACT
- [ ] Material slot + CONTRACT
- [ ] Solver（L2）经 L5 适配 + 证据命令：__________
- [ ] 验收表 **A / A+ / B / C**：已勾选 / 链接 __________（**A+** 见验收表 A7–A11）
```

---

## 4. 维护

- 域拆分或重命名时更新 §1 表路径。  
- 里程碑关闭后在本文件 §1 将 ☐ 改为 ☑ 并注明 PR 号。

---

*本文件为「Phase 4 主线」的过程真源；不等同于各域 `CONTRACT.md` 的法律效力。*
