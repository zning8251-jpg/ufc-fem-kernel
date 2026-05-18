# Phase6 Track 2.2 — SoA 试点（建议）

## 试点域

- **首选**：[`PH_Mat_Elas_Core.f90`](../ufc_core/L4_PH/Material/Elas/PH_Mat_Elas_Core.f90) — `ALLOCATE` 计数低、接口清晰，便于与 `IF_Mem_Algo` 工作区绑定。
- **备选**：[`PH_Mat_Interp_Core.f90`](../ufc_core/L4_PH/Material/PH_Mat_Interp_Core.f90)（插值核，读多写少）。

## 互操作边界

- **AoS 保留区**：对外 `PUBLIC` 过程签名、`MD_Mat_*` / `MatCtxLegacy` 合同字段不改名；SoA 缓冲仅作 **内部 static / thread workspace**。
- **观测**：在试点 PR 附带 `REPORTS/phase6_soa_pilot_<stem>_notes.md`（前后 `ALLOCATE` 计数差或 instr 采样）。

## 推广矩阵（草案）

| 阶段 | 模块族 | 风险 |
|------|--------|------|
| P0 | Elas 线弹 | 低 |
| P1 | Plast J2 / Hyper Neo | 中 |
| P2 | UMAT / Damage | 高（与 L3 镜像对齐） |
