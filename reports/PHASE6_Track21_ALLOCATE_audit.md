# Phase6 Track 2.1 — ALLOCATE 审计（L4_PH / Material + Element）

生成方式：`rg "ALLOCATE\\s*\\(" ufc_core/L4_PH/Material --glob "*.f90" -c` 与 Element 同理（2026-05-15 快照）。

## 摘要

| 域 | 约计文件数（含 ALLOCATE 命中） | 说明 |
|----|-------------------------------|------|
| `L4_PH/Material` | 26+ | 热点：`PH_Mat_UMAT_Def.f90`、`PH_Mat_UMAT_Brg.f90`、`PH_L4_Populate.f90`、`PH_MatPLMEval.f90` |
| `L4_PH/Element` | 60+ | 热点：`PH_Elem_Core.f90`、`PH_UEL_Def.f90`、`PH_Elem_ShapeFunc.f90`、`PH_Elem_AcousticTransientSolv.f90` |

## 零分配改造顺序（建议）

1. **Populate / Dispatch 边界**（`PH_L4_Populate.f90`、`PH_MatPLMEval.f90`）：改为 `IF_Mem_Algo` scratch 或调用方预分配工作区，避免在热循环内 `ALLOCATE`。
2. **UMAT 边界**（`PH_Mat_UMAT_*`）：与材料合同对齐后分批替换。
3. **单元形函数/核**（`PH_Elem_Core`、`PH_Elem_ShapeFunc*`）：最后动（调用面最广）。

## 下一轨

见 [PHASE6_Track22_SoA_Pilot.md](PHASE6_Track22_SoA_Pilot.md)。
