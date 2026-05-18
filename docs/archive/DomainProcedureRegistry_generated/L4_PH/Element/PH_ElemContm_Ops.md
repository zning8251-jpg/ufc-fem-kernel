# `PH_ElemContm_Ops.f90`

- **Source**: `L4_PH/Element/PH_ElemContm_Ops.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_ElemContm_Ops`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ElemContm_Ops`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ElemContm`
- **第四段角色（四段式）**: `_Ops`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_ElemContm_Ops.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Contm_Calc3D_Arg` (lines 80–88)

```fortran
  TYPE, PUBLIC :: PH_Elem_Contm_Calc3D_Arg
    TYPE(UF_ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(UF_ElemFormul) :: formul  ! Formulation parameters (Algo)                   ! [IN]
    TYPE(UF_ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(ElemState) :: state_in  ! Input element state (State)                   ! [IN]
    TYPE(ElemState) :: state_out  ! Output element state (State)                   ! [OUT]
    TYPE(UF_ElemFlags) :: flags  ! Element flags and status (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_Contm_Calc3D_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `PH_Contm_NNodes_Base` | 101 | `PURE FUNCTION PH_Contm_NNodes_Base(et) RESULT(n)` |
| SUBROUTINE | `PH_Contm_UF_Formul_to_ElemFormul` | 108 | `PURE SUBROUTINE PH_Contm_UF_Formul_to_ElemFormul(uf, ef)` |
| SUBROUTINE | `PH_Contm_ElemFormul_to_UF` | 124 | `PURE SUBROUTINE PH_Contm_ElemFormul_to_UF(ef, uf)` |
| SUBROUTINE | `PH_Contm_Promote_to_UF_Therm3D` | 138 | `SUBROUTINE PH_Contm_Promote_to_UF_Therm3D(et, fm, cx, et_uf, fm_uf, cx_uf)` |
| SUBROUTINE | `PH_Contm_ElemFlags_copy_UF_to_base` | 151 | `PURE SUBROUTINE PH_Contm_ElemFlags_copy_UF_to_base(dst, src)` |
| SUBROUTINE | `Calc_C3D20R` | 163 | `subroutine Calc_C3D20R(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_C3D8R` | 186 | `subroutine Calc_C3D8R(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_Continuum` | 303 | `subroutine Calc_Continuum(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_Continuum2D_UF` | 322 | `subroutine Calc_Continuum2D_UF(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_Continuum2D_elem` | 369 | `subroutine Calc_Continuum2D_elem(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_Continuum2D_Thermal` | 419 | `subroutine Calc_Continuum2D_Thermal(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Therm_IpKernel` | 641 | `subroutine Therm_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)` |
| SUBROUTINE | `Calc_Continuum2D_THM` | 739 | `subroutine Calc_Continuum2D_THM(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `THM2D_IpKernel` | 977 | `subroutine THM2D_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)` |
| SUBROUTINE | `Calc_Continuum3D` | 1214 | `SUBROUTINE Calc_Continuum3D(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_Continuum3D_Reduced` | 1249 | `subroutine Calc_Continuum3D_Reduced(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_Continuum3D_Thermal` | 1276 | `subroutine Calc_Continuum3D_Thermal(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Therm_IpKernel` | 1504 | `subroutine Therm_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)` |
| SUBROUTINE | `Calc_Continuum3D_THM` | 1600 | `subroutine Calc_Continuum3D_THM(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `THM3D_IpKernel` | 1843 | `subroutine THM3D_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)` |
| SUBROUTINE | `Calc_Continuum_Base` | 2079 | `subroutine Calc_Continuum_Base(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Continuum_IpKernel` | 2227 | `subroutine Continuum_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)` |
| SUBROUTINE | `Calc_Continuum_MatProps` | 2310 | `subroutine Calc_Continuum_MatProps(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_Continuum_Poro` | 2334 | `subroutine Calc_Continuum_Poro(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Poro_IpKernel` | 2542 | `subroutine Poro_IpKernel(ip, sf, dN_dx_ip, dVol_ip, radius_ip)` |
| SUBROUTINE | `Poro_Hpp_BBar_FirstPass` | 2684 | `subroutine Poro_Hpp_BBar_FirstPass(ip, sf, dN_dx_ip, dVol_ip, radius_ip)` |
| SUBROUTINE | `Poro_Hpp_BBar_SecondPass` | 2699 | `subroutine Poro_Hpp_BBar_SecondPass(ip, sf, dN_dx_ip, dVol_ip, radius_ip)` |
| SUBROUTINE | `Calc_Continuum_Thermal` | 2732 | `subroutine Calc_Continuum_Thermal(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_Continuum_THM` | 2760 | `subroutine Calc_Continuum_THM(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `Calc_ElementVolume_Hex` | 2788 | `subroutine Calc_ElementVolume_Hex(coords, volume, status)` |
| FUNCTION | `Estimate_ElementVolume` | 2847 | `function Estimate_ElementVolume(coords) result(volume)` |
| SUBROUTINE | `PH_Elem_Contm_Calc3D` | 2869 | `SUBROUTINE PH_Elem_Contm_Calc3D(arg)` |
| SUBROUTINE | `PH_Elem_Contm_Calc3D_Structured` | 2964 | `SUBROUTINE PH_Elem_Contm_Calc3D_Structured(arg)` |
| SUBROUTINE | `UF_Co_ApplyHourglass2D` | 2972 | `subroutine UF_Co_ApplyHourglass2D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)` |
| SUBROUTINE | `UF_Co_ApplyHourglass2D` | 3127 | `subroutine UF_Co_ApplyHourglass2D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)` |
| SUBROUTINE | `UF_Co_ApplyHourglass3D` | 3282 | `subroutine UF_Co_ApplyHourglass3D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)` |
| SUBROUTINE | `UF_Co_ApplyHourglass3D` | 3435 | `subroutine UF_Co_ApplyHourglass3D(ElemType, Formul, Ctx, nNode, nDOF, totalVol, props, D, Ke, Re)` |
| SUBROUTINE | `UF_Continuum_AllocWork` | 3588 | `subroutine UF_Continuum_AllocWork(nDOF, Ke, Re, Me, Ce, B)` |
| SUBROUTINE | `UF_Continuum_ApplyHourglass` | 3601 | `subroutine UF_Continuum_ApplyHourglass(ElemType, Formul, Ctx, nNode, nDim, nDOF, isAxisym, totalVol, props, D, Ke, Re)` |
| SUBROUTINE | `UF_Continuum_EstimateStblDt` | 3621 | `subroutine UF_Continuum_EstimateStblDt(elemName, nDim, isAxisym, totalVol, props, stableDt)` |
| SUBROUTINE | `UF_Continuum_WriteBackState` | 3661 | `subroutine UF_Continuum_WriteBackState(state_out, Ke, Re, Me, Ce, nDOF)` |
| SUBROUTINE | `UF_Embed_StructBlock` | 3676 | `subroutine UF_Embed_StructBlock(nNode, ndpn_struct, ndpn_total, &` |
| SUBROUTINE | `UF_Init_Continuum` | 3740 | `subroutine UF_Init_Continuum(Element, name)` |
| SUBROUTINE | `UF_Init_Continuum2D` | 3762 | `subroutine UF_Init_Continuum2D(Element, name)` |
| SUBROUTINE | `UF_Init_Continuum3D` | 3841 | `subroutine UF_Init_Continuum3D(Element, name)` |
| SUBROUTINE | `UF_Init_Continuum_Poro` | 3940 | `subroutine UF_Init_Continuum_Poro(Element, name)` |
| SUBROUTINE | `UF_Init_Continuum_Thermal` | 3972 | `subroutine UF_Init_Continuum_Thermal(Element, name)` |
| SUBROUTINE | `UF_Init_Continuum_THM` | 4003 | `subroutine UF_Init_Continuum_THM(Element, name)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 92–95 | `INTERFACE Calc_Continuum2D` |
