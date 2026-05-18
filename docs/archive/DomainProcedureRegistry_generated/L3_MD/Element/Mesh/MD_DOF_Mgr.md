# `MD_DOF_Mgr.f90`

- **Source**: `L3_MD/Element/Mesh/MD_DOF_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_DOF_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_DOF_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_DOF`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_DOF_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_DOFLabelMapType` (lines 67–70)

```fortran
  type, public :: UF_DOFLabelMapType
    integer(i4) :: maxSlots = 0_i4
    integer(i4), allocatable :: label_of_slot(:)
  end type UF_DOFLabelMapType
```

### `MD_DOFMap` (lines 153–167)

```fortran
  type, public :: MD_DOFMap
    integer(i4) :: nNode = 0_i4
    integer(i4) :: maxDpn = 0_i4
    integer(i4), pointer :: ndof(:) => null()
    integer(i4), pointer :: eq(:,:) => null()
    logical :: initialized = .false.
  contains
    procedure :: Init => MD_DOFMap_Init
    procedure :: Free => MD_DOFMap_Free
    procedure :: SetNdof
    procedure :: MakeEq
    procedure :: GetEq
    procedure :: NodeRng
    procedure :: NEq
  end type MD_DOFMap
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_DOFDesc_Init` | 225 | `SUBROUTINE MD_DOFDesc_Init(this)` |
| SUBROUTINE | `MD_DOFDesc_Configure` | 232 | `SUBROUTINE MD_DOFDesc_Configure(this, dofId, name, numNodes, numTotalDOF, numFreeDOF, numFixedDOF)` |
| SUBROUTINE | `MD_DOFDesc_RegLayout` | 244 | `SUBROUTINE MD_DOFDesc_RegLayout(this)` |
| SUBROUTINE | `MD_DOFDesc_Ensure` | 280 | `SUBROUTINE MD_DOFDesc_Ensure(this)` |
| SUBROUTINE | `MD_DOFSta_Init` | 289 | `SUBROUTINE MD_DOFSta_Init(this, n)` |
| SUBROUTINE | `MD_DOFSta_RegLayout` | 298 | `SUBROUTINE MD_DOFSta_RegLayout(this)` |
| SUBROUTINE | `MD_DOFSta_Ensure` | 321 | `SUBROUTINE MD_DOFSta_Ensure(this)` |
| SUBROUTINE | `MD_DOFCtx_Init` | 330 | `SUBROUTINE MD_DOFCtx_Init(this)` |
| SUBROUTINE | `MD_DOFCtx_Configure` | 337 | `SUBROUTINE MD_DOFCtx_Configure(this, dofId)` |
| SUBROUTINE | `MD_DOFCtx_RegLayout` | 343 | `SUBROUTINE MD_DOFCtx_RegLayout(this)` |
| SUBROUTINE | `MD_DOFCtx_Ensure` | 358 | `SUBROUTINE MD_DOFCtx_Ensure(this)` |
| SUBROUTINE | `MD_NodalDOFDesc_Init` | 367 | `SUBROUTINE MD_NodalDOFDesc_Init(this)` |
| SUBROUTINE | `MD_NodalDOFDesc_Configure` | 374 | `SUBROUTINE MD_NodalDOFDesc_Configure(this, id, numDOF)` |
| SUBROUTINE | `MD_NodalDOFDesc_RegLayout` | 381 | `SUBROUTINE MD_NodalDOFDesc_RegLayout(this)` |
| SUBROUTINE | `MD_NodalDOFDesc_Ensure` | 400 | `SUBROUTINE MD_NodalDOFDesc_Ensure(this)` |
| SUBROUTINE | `MD_NodalDOFSta_Init` | 409 | `SUBROUTINE MD_NodalDOFSta_Init(this, n)` |
| SUBROUTINE | `MD_NodalDOFSta_RegLayout` | 418 | `SUBROUTINE MD_NodalDOFSta_RegLayout(this)` |
| SUBROUTINE | `MD_NodalDOFSta_Ensure` | 449 | `SUBROUTINE MD_NodalDOFSta_Ensure(this)` |
| SUBROUTINE | `MD_NodalDOF_Setup` | 462 | `subroutine MD_NodalDOF_Setup(this, node_id, nDof)` |
| SUBROUTINE | `Activate` | 486 | `subroutine Activate(this, dof)` |
| SUBROUTINE | `Fix` | 507 | `subroutine Fix(this, dof)` |
| SUBROUTINE | `Prescribe` | 526 | `subroutine Prescribe(this, dof, value)` |
| FUNCTION | `GetEqn` | 546 | `function GetEqn(this, dof) result(eqn)` |
| FUNCTION | `IsFree` | 564 | `function IsFree(this, dof) result(is_free)` |
| FUNCTION | `GetStatus` | 582 | `function GetStatus(this, dof) result(status_val)` |
| FUNCTION | `GetPrescribedValue` | 600 | `function GetPrescribedValue(this, dof) result(value)` |
| FUNCTION | `GetReaction` | 618 | `function GetReaction(this, dof) result(reaction)` |
| SUBROUTINE | `SetReaction` | 636 | `subroutine SetReaction(this, dof, reaction)` |
| SUBROUTINE | `MD_DOF_Setup` | 654 | `subroutine MD_DOF_Setup(this, nNodes, dof_per_node)` |
| SUBROUTINE | `MD_DOF_Free` | 684 | `subroutine MD_DOF_Free(this)` |
| SUBROUTINE | `ActivateDOFs` | 708 | `subroutine ActivateDOFs(this, node_id, dof_list, nDof)` |
| SUBROUTINE | `FixDOF` | 734 | `subroutine FixDOF(this, node_id, dof)` |
| SUBROUTINE | `PrescribeDOF` | 756 | `subroutine PrescribeDOF(this, node_id, dof, value)` |
| SUBROUTINE | `NumberEquations` | 779 | `subroutine NumberEquations(this)` |
| FUNCTION | `GetNodalDOF` | 849 | `function GetNodalDOF(this, node_id) result(nodal_dof_ptr)` |
| SUBROUTINE | `GetElementDOFs` | 867 | `subroutine GetElementDOFs(this, node_ids, dof_labels, eqn_numbers)` |
| SUBROUTINE | `AssembleVector` | 895 | `subroutine AssembleVector(this, node_id, dof_label, value, vector)` |
| SUBROUTINE | `ScatterSolution` | 924 | `subroutine ScatterSolution(this, solution)` |
| FUNCTION | `GetDisplacement` | 945 | `function GetDisplacement(this, eqn) result(value)` |
| SUBROUTINE | `SetDisplacement` | 963 | `subroutine SetDisplacement(this, eqn, value)` |
| FUNCTION | `GetVelocity` | 982 | `function GetVelocity(this, eqn) result(value)` |
| SUBROUTINE | `SetVelocity` | 1000 | `subroutine SetVelocity(this, eqn, value)` |
| FUNCTION | `GetAcceleration` | 1019 | `function GetAcceleration(this, eqn) result(value)` |
| SUBROUTINE | `SetAcceleration` | 1037 | `subroutine SetAcceleration(this, eqn, value)` |
| FUNCTION | `GetDOFValue` | 1056 | `function GetDOFValue(this, node_id, dof_label) result(value)` |
| SUBROUTINE | `SetDOFValue` | 1083 | `subroutine SetDOFValue(this, node_id, dof_label, value)` |
| FUNCTION | `GetDOFStatus` | 1118 | `function GetDOFStatus(this, node_id, dof_label) result(status_val)` |
| SUBROUTINE | `MD_DOFMap_Init` | 1139 | `subroutine MD_DOFMap_Init(this, nNode, maxDpn)` |
| SUBROUTINE | `MD_DOFMap_Free` | 1166 | `subroutine MD_DOFMap_Free(this)` |
| SUBROUTINE | `SetNdof` | 1181 | `subroutine SetNdof(this, node, nd)` |
| SUBROUTINE | `MakeEq` | 1210 | `subroutine MakeEq(this, eq0)` |
| FUNCTION | `GetEq` | 1240 | `function GetEq(this, node, slot) result(eq)` |
| SUBROUTINE | `NodeRng` | 1262 | `subroutine NodeRng(this, node, e1, e2)` |
| FUNCTION | `NEq` | 1296 | `function NEq(this) result(n_eq)` |
| SUBROUTINE | `InitLabelMap` | 1312 | `subroutine InitLabelMap(this, num_slots, status)` |
| SUBROUTINE | `RegisterLabel` | 1341 | `subroutine RegisterLabel(this, label, slot, status)` |
| SUBROUTINE | `GetSlotFromLabel` | 1395 | `subroutine GetSlotFromLabel(this, label, slot, status)` |
| SUBROUTINE | `GetLabelFromSlot` | 1432 | `subroutine GetLabelFromSlot(this, slot, label_out, status)` |
| FUNCTION | `HasLabel` | 1465 | `function HasLabel(this, label) result(has_label)` |
| FUNCTION | `GetNumLabels` | 1485 | `function GetNumLabels(this) result(num_labels)` |
| SUBROUTINE | `ActivateByLabel` | 1507 | `subroutine ActivateByLabel(this, node_id, label_list, num_labels, status)` |
| SUBROUTINE | `FixByLabel` | 1559 | `subroutine FixByLabel(this, node_id, label, status)` |
| SUBROUTINE | `PrescribeByLabel` | 1608 | `subroutine PrescribeByLabel(this, node_id, label, value, status)` |
| FUNCTION | `GetEqnByLabel` | 1658 | `function GetEqnByLabel(this, node_id, label) result(eqn)` |
| FUNCTION | `IsFreeByLabel` | 1695 | `function IsFreeByLabel(this, node_id, label) result(is_free)` |
| FUNCTION | `GetDOFValueByLabel` | 1733 | `function GetDOFValueByLabel(this, node_id, label, value_type) result(value)` |
| SUBROUTINE | `SetDOFValueByLabel` | 1777 | `subroutine SetDOFValueByLabel(this, node_id, label, value_type, value, status)` |
| SUBROUTINE | `UF_DOFLabelMap_Init` | 1847 | `subroutine UF_DOFLabelMap_Init(map, maxSlots)` |
| SUBROUTINE | `UF_DOFLabelMap_Register` | 1861 | `subroutine UF_DOFLabelMap_Register(map, label, slot, ierr)` |
| SUBROUTINE | `UF_DOFLabelMap_GetSlot` | 1890 | `subroutine UF_DOFLabelMap_GetSlot(map, label, slot)` |
| SUBROUTINE | `UF_DOFLabelMap_GetLabel` | 1906 | `subroutine UF_DOFLabelMap_GetLabel(map, slot, labelOut)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
