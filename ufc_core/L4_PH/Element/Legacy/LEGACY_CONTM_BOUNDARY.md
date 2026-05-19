# Legacy continuum (`PH_Elem_Contm`) — quarantine boundary

> **Status**: ACTIVE (2026-05-19) · change_id: `p2-element-legacy-contm-retire`  
> **G6**: P2 门闩红项 — 本目录/模块为 **冻结区**，不扩展；生产 Ke/Fe **不得**依赖此处。

## Production golden path (allowed for new work)

```text
RT_Asm_GlobalStiffness / RT_Asm_ComputeResidual  (L5_RT/Assembly/RT_Asm_Solv.f90)
  → RT_Asm_Brg_ElemMatPtIdx
  → RT_Asm_Solv_KeArg_AttachMatProps
  → PH_Elem_Domain%Compute_Ke / %Compute_Fe
  → PH_Elem_Eval_Ke / PH_ElemKeDispatch
  → family kernels + PH_Elem_MaterialRoute (mat_pt_idx, slot_pool)
```

**Static gate**: `tools/verify_element_golden_path_no_contm.py` — 金线锚点文件不得 `USE` / 调用 `PH_Elem_Contm` / `Calc_Continuum*`.

## Legacy cold / bridge path (frozen)

| Caller | Role |
|--------|------|
| `L3_MD/Bridge/Bridge_L4/MD_ElemPH_Brg.f90` | L3→L4 温路径桥接 |
| `L4_PH/Element/Solid2D/PH_Elem_Sld2D_Def.f90` | `Calc_Continuum2D` 回退 |
| `L4_PH/Element/Solid3D/PH_Elem_Sld3D_Def.f90` | `Calc_Continuum3D` 回退 |
| `Solid2Dt` / `Solid3Dt` | 热-力 `Calc_Continuum*_Thermal` 回退 |
| `PH_Elem_Contm.f90` | 薄 re-export（无 `USE MD_*`） |
| `Legacy/PH_Elem_Contm_Brg.f90` | MD↔UF 映射 + `CompPoro/Thm/THM`（G6-W2 隔离） |
| `Legacy/PH_ElemContm_Ops.f90` | Legacy 计算实现体（`USE MD_*`；G6-W3a 物理迁入） |

新单元族实现：**禁止**新增对 `Calc_Continuum*` 的调用；优先 `PH_Elem_Reg` + `PH_Elem_Eval_*` + MaterialRoute。

## G6 销项分阶段

| 阶段 | 目标 | 状态 |
|------|------|------|
| **G6-W0** | 金线无 Contm 依赖（本文件 + verifier） | **已交付**（#22） |
| **G6-W1** | `Sld3D/2D/2Dt/3Dt` 显式路由；`Compute_Ke_C3D8/C3D4` → 族刚度核 | **已交付**（G6-W1b） |
| **G6-W2** | `PH_Elem_Contm_Brg` 隔离 `USE MD_*`；`MD_ElemPH_Brg`→Ops/Brg；`verify_element_contm_legacy_boundary.py` | **已交付**（#23） |
| **G6-W3a** | `PH_ElemContm_Ops` 物理迁入 `Legacy/` | **已交付**（G6-W3a PR） |
| **G6-W3b/c** | 削减 Ops `USE MD_*` + guardian 门控 | **计划中** — `plan/changes/p2-element-legacy-contm-g6w3/` |

**不宣称 P2 柱 S7**，直至 G3–G6 全绿（见 `P2_ELEMENT_GAP_SNAPSHOT.md`）。
