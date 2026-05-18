# Phase6 Track 2.3 — `RT_Step_Ctx` 指针化（设计落地）

## 现状真源

[`RT_Step_Ctx`](../ufc_core/L5_RT/StepDriver/RT_Step_Def.f90) 已含：

- `TYPE(RT_Step_Inc_Evo_Ctx) :: inc`
- `TYPE(RT_Step_Itr_Com_Ctx) :: itr`
- `REAL(wp), POINTER :: work_vec(:)` — **已预留** scratch 向量别名位

## 推进步骤

1. **审计**：列出 `RT_Step_Core` / `RT_Step_Exec` 中仍按值拷贝的大数组；优先改为 `work_vec` 子区间或 `RT_Inc_Ctx%u_saved` 指针。
2. **L3→L4**：在装配完成态将 `MD_Model` 大容器的 **只读切片** 以 `POINTER` 传入 `RT_Asm_Complete` 上下文（与 SIO 合同对齐后再改签名）。
3. **验收**：Guardian `DEP-001` + 动力学/静力学各 1 条最小用例无回归。

本文件为 **Track 2.3** 执行卡；代码改动按子 PR 提交。
