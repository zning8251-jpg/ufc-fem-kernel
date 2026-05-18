# `MD_Elem_Reg.f90`

- **Source**: `L3_MD/Element/Elem/MD_Elem_Reg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Elem_Reg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Elem_Reg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Elem`
- **第四段角色（四段式）**: `_Reg`
- **源码子路径（层下目录，不含文件名）**: `Element/Elem`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Elem/MD_Elem_Reg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Elem_Reg_Init` | 148 | `SUBROUTINE MD_Elem_Reg_Init(status)` |
| SUBROUTINE | `MD_Elem_Reg_Register` | 168 | `SUBROUTINE MD_Elem_Reg_Register(desc, status)` |
| FUNCTION | `MD_Elem_Reg_LookupById` | 198 | `FUNCTION MD_Elem_Reg_LookupById(elem_type_id, status) RESULT(desc_out)` |
| FUNCTION | `MD_Elem_Reg_LookupByFamily` | 227 | `FUNCTION MD_Elem_Reg_LookupByFamily(family_id, status) RESULT(desc_out)` |
| FUNCTION | `MD_Elem_Reg_Validate` | 256 | `FUNCTION MD_Elem_Reg_Validate(desc, status) RESULT(is_valid)` |
| SUBROUTINE | `MD_Elem_Reg_Finalize` | 301 | `SUBROUTINE MD_Elem_Reg_Finalize(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterAll` | 316 | `SUBROUTINE MD_Elem_Reg_RegisterAll(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterSolid3D` | 344 | `SUBROUTINE MD_Elem_Reg_RegisterSolid3D(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterShell` | 373 | `SUBROUTINE MD_Elem_Reg_RegisterShell(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterBeam` | 403 | `SUBROUTINE MD_Elem_Reg_RegisterBeam(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterTruss` | 423 | `SUBROUTINE MD_Elem_Reg_RegisterTruss(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterSolid2D` | 442 | `SUBROUTINE MD_Elem_Reg_RegisterSolid2D(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterInfinite` | 470 | `SUBROUTINE MD_Elem_Reg_RegisterInfinite(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterCohesive` | 480 | `SUBROUTINE MD_Elem_Reg_RegisterCohesive(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterSpring` | 490 | `SUBROUTINE MD_Elem_Reg_RegisterSpring(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterDashpot` | 500 | `SUBROUTINE MD_Elem_Reg_RegisterDashpot(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterMass` | 510 | `SUBROUTINE MD_Elem_Reg_RegisterMass(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterGasket` | 520 | `SUBROUTINE MD_Elem_Reg_RegisterGasket(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterSurface` | 530 | `SUBROUTINE MD_Elem_Reg_RegisterSurface(status)` |
| SUBROUTINE | `MD_Elem_Reg_RegisterFamily` | 540 | `SUBROUTINE MD_Elem_Reg_RegisterFamily(group_id, status)` |
| FUNCTION | `MD_Elem_Reg_GetFamilyDesc` | 571 | `FUNCTION MD_Elem_Reg_GetFamilyDesc(group_id, status) RESULT(desc_out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
