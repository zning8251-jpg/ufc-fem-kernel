# Material 域改造 · 切片 01 任务卡

**路径**: `UFC/REPORTS/Material_Refactor_Slice01_TaskCard.md`  
**日期**: 2026-05-08  

## 1. 权威性与漂移处理

- **唯一权威**: `UFC/ufc_core` 下 Material 相关 **源码** + 各层 **`CONTRACT.md`**（若目录内存在）。  
- **Inventory / P0 地图**: 用于对齐与切片规划；若与代码或 CONTRACT 冲突，**以代码 + CONTRACT 为准**，并在同一轮或下一切片更新 `Material_Domain_Inventory.md` / `Material_P0_FourType_BinaryMap.md`。  
- **本切片已完成**: Inventory v1.1 追平 `PH_Mat_Domain_Core`、`PH_Mat_Core`、`RT_Mat_Core`、`PH_Mat_KernelDefn` 与 Populate/Dispatch 签名。

## 2. 范围边界（刻意不做）

- **不做** 全域「二元结构 + 四型 + SIO」一次落地。  
- **不做** L3 Def/Core/Brg 彻底拆分、L4 Execute 全族完整度补齐（长期项，见多 PR）。  
- **不做** 全工程链接编译；Harness 以 **形式统一 + 单文件/局部 `gfortran -fsyntax-only`** 为后续切片门禁（本切片以文档与清单为主）。

## 3. 本切片 Definition of Done

1. `Material_Domain_Inventory.md` 与当前仓库一致：Ifc 位置、`PH_Mat_Eval_Arg` vs `PH_Mat_Update_Arg`、`RT_Mat_Core` vs 旧 `RT_Mat_Dispatch.f90`、Populate/Dispatch 签名。  
2. `Material_P0_FourType_BinaryMap.md` 为 **UTF-8 可读**，且交叉引用指向 Inventory **章节号**（行号仅作提示，以章节为准）。  
3. 下游切片（02+）在任务卡中重复「第 1 节」权威性条款，避免静默假设 Inventory 已自动同步。

## 4. 建议下一切片（02，待开卡）

- **SIO**: 审计 L5 `RT_Mat_*_Proc` / L4 kernel 边界，统一 `*_Arg` 与五参/六参约定（仅改约定范围内文件）。  
- **或** Elas-only L3/L4 二元边界试点（单族、单 PR）。

---

> **END**
