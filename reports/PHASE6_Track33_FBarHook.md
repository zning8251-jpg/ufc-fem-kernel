# Phase6 Track 3.3 — F-bar / hourglass hook（占位）

- **模块**：[`PH_Elem_FBarHook.f90`](../ufc_core/L4_PH/Element/Solid3D/PH_Elem_FBarHook.f90) — `PH_Elem_FBar_VolRatio_stub`（当前恒为 1，占位）。
- **后续**：在 `PH_Elem_Solid3D_Fbar.f90` 等族内替换为真实 \(J^0/J\) 缩放；并补 **patch test**（单单元体积响应）。
