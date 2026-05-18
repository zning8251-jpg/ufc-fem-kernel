# `RT_Asm_MassDamp.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_MassDamp.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Asm_MassDamp`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_MassDamp`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm_MassDamp`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_MassDamp.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `GaussParams` (lines 74–79)

```fortran
  TYPE, PUBLIC :: GaussParams
    !! Helper TYPE for numerical integration parameters
    INTEGER(i4) :: n_gp = 0_i4
    REAL(wp), ALLOCATABLE :: weights(:)
    REAL(wp), ALLOCATABLE :: coords(:, :)
  END TYPE GaussParams
```

### `RT_MassConfig` (lines 99–114)

```fortran
  type, public :: RT_MassConfig
    !! Configuration for mass matrix assembly
    
    integer(i4) :: mass_type = MASS_TYPE_CONSIST
    integer(i4) :: lump_method = LUMP_METH_ROWSUM
    
    logical :: use_hciz_lump = .false.        ! use_hciz_lumping
    real(wp) :: mass_scaling = 1.0_wp
    
    logical :: incl_rot_inert = .false.       ! incl_rot_inert
    real(wp) :: mass_prop_damp = 0.0_wp      ! mass_proportional_damping
    
  contains
    procedure, public :: Init => RT_MassConfig_Init
    procedure, public :: Valid => RT_MassConfig_Valid
  end type RT_MassConfig
```

### `RT_DampingConfig` (lines 119–141)

```fortran
  type, public :: RT_DampingConfig
    !! Configuration for damping matrix assembly
    
    integer(i4) :: damping_type = DAMP_NONE
    
    ! Rayleigh damping: C = alpha*M + beta*K
    real(wp) :: alpha_mass = 0.0_wp
    real(wp) :: beta_stiffness = 0.0_wp
    
    ! Modal damping
    integer(i4) :: n_modes = 0_i4
    real(wp), allocatable :: modal_damping_ratios(:)
    real(wp), allocatable :: modal_frequencies(:)
    
    ! Structural damping
    real(wp) :: struct_damp_fac = 0.0_wp     ! struct_damp_fac
    
  contains
    procedure, public :: Init => RT_DampingConfig_Init
    procedure, public :: Valid => RT_DampingConfig_Valid
    procedure, public :: SetRayleigh => RT_DampingConfig_SetRayleigh
    procedure, public :: SetModal => RT_DampingConfig_SetModal
  end type RT_DampingConfig
```

### `RT_MassMatrix` (lines 146–173)

```fortran
  type, public :: RT_MassMatrix
    !! Mass matrix container
    
    integer(i4) :: n_dofs = 0_i4
    integer(i4) :: mass_type = MASS_TYPE_CONSIST
    
    ! Consistent mass (sparse)
    real(wp), allocatable :: M_consistent(:,:)
    
    ! Lumped mass (diagonal)
    real(wp), allocatable :: M_lumped(:)
    
    ! Mass matrix statistics
    real(wp) :: total_mass = 0.0_wp
    real(wp) :: max_mass_value = 0.0_wp
    real(wp) :: min_mass_value = 0.0_wp
    
    logical :: assembled = .false.
    
  contains
    procedure, public :: Init => RT_MassMatrix_Init
    procedure, public :: Assemble => RT_MassMatrix_Assem
    procedure, public :: Lump => RT_MassMatrix_Lump
    procedure, public :: Scale => RT_MassMatrix_Scale
    procedure, public :: GetTotalMass => RT_MassMatrix_GetTotal
    procedure, public :: Print => RT_MassMatrix_Print
    procedure, public :: Cleanup => RT_MassMatrix_Clean
  end type RT_MassMatrix
```

### `RT_DampingMatrix` (lines 178–198)

```fortran
  type, public :: RT_DampingMatrix
    !! Damping matrix container
    
    integer(i4) :: n_dofs = 0_i4
    integer(i4) :: damping_type = DAMP_NONE
    
    ! Damping matrix (sparse)
    real(wp), allocatable :: C(:,:)
    
    ! Modal damping (diagonal in modal space)
    real(wp), allocatable :: C_modal(:)
    
    logical :: assembled = .false.
    
  contains
    procedure, public :: Init => RT_DampingMatrix_Init
    procedure, public :: AssembleRayleigh => RT_DampingMatrix_Rayleigh
    procedure, public :: AssembleModal => RT_DampingMatrix_Modal
    procedure, public :: Print => RT_DampingMatrix_Print
    procedure, public :: Cleanup => RT_DampingMatrix_Clean
  end type RT_DampingMatrix
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_MassConfig_Init` | 206 | `subroutine RT_MassConfig_Init(this, mass_type, lump_method)` |
| SUBROUTINE | `RT_MassConfig_Valid` | 223 | `subroutine RT_MassConfig_Valid(this, status)` |
| SUBROUTINE | `RT_DampingConfig_Init` | 249 | `subroutine RT_DampingConfig_Init(this, damping_type)` |
| SUBROUTINE | `RT_DampingConfig_Valid` | 263 | `subroutine RT_DampingConfig_Valid(this, status)` |
| SUBROUTINE | `RT_DampingConfig_SetRayleigh` | 287 | `subroutine RT_DampingConfig_SetRayleigh(this, alpha, beta, status)` |
| SUBROUTINE | `RT_DampingConfig_SetModal` | 302 | `subroutine RT_DampingConfig_SetModal(this, n_modes, ratios, frequencies, status)` |
| SUBROUTINE | `RT_MassMatrix_Init` | 331 | `subroutine RT_MassMatrix_Init(this, n_dofs, mass_type, status)` |
| SUBROUTINE | `RT_MassMatrix_Assem` | 367 | `subroutine RT_MassMatrix_Assem(this, elem_mass, elem_dofs, status)` |
| SUBROUTINE | `RT_MassMatrix_Lump` | 402 | `subroutine RT_MassMatrix_Lump(this, lump_method, status)` |
| SUBROUTINE | `RT_MassMatrix_Scale` | 474 | `subroutine RT_MassMatrix_Scale(this, scale_factor, status)` |
| FUNCTION | `RT_MassMatrix_GetTotal` | 493 | `function RT_MassMatrix_GetTotal(this) result(total_mass)` |
| SUBROUTINE | `RT_MassMatrix_Print` | 513 | `subroutine RT_MassMatrix_Print(this, status)` |
| SUBROUTINE | `RT_MassMatrix_Clean` | 529 | `subroutine RT_MassMatrix_Clean(this)` |
| SUBROUTINE | `RT_DampingMatrix_Init` | 543 | `subroutine RT_DampingMatrix_Init(this, n_dofs, damping_type, status)` |
| SUBROUTINE | `RT_DampingMatrix_Rayleigh` | 565 | `subroutine RT_DampingMatrix_Rayleigh(this, alpha, beta, M, K, status)` |
| SUBROUTINE | `RT_DampingMatrix_Modal` | 593 | `subroutine RT_DampingMatrix_Modal(this, n_modes, zeta, omega, status)` |
| SUBROUTINE | `RT_DampingMatrix_Print` | 618 | `subroutine RT_DampingMatrix_Print(this, status)` |
| SUBROUTINE | `RT_DampingMatrix_Clean` | 633 | `subroutine RT_DampingMatrix_Clean(this)` |
| SUBROUTINE | `RT_Asm_Mass_Assem_Consist` | 651 | `subroutine RT_Asm_Mass_Assem_Consist(mass_matrix, coords, density, gauss_params, &` |
| SUBROUTINE | `RT_Asm_Mass_Assem_Lump` | 787 | `subroutine RT_Asm_Mass_Assem_Lump(mass_matrix, coords, density, lump_method, &` |
| SUBROUTINE | `RT_Asm_Damp_Assem_Rayleigh` | 930 | `subroutine RT_Asm_Damp_Assem_Rayleigh(damping_matrix, mass_matrix, stiff_matrix, &` |
| SUBROUTINE | `RT_Asm_Damp_Assem_Modal` | 1056 | `subroutine RT_Asm_Damp_Assem_Modal(damping_matrix, xi, omega, status)` |
| SUBROUTINE | `RT_Asm_Ma_Un_Assem` | 1107 | `subroutine RT_Asm_Ma_Un_Assem(mass_config, damping_config, &` |
| SUBROUTINE | `RT_Asm_MassDamp_Unified_Cfg` | 1214 | `subroutine RT_Asm_MassDamp_Unified_Cfg(mass_type, lump_method, &` |
| SUBROUTINE | `RT_Asm_CSRMassCons` | 1312 | `SUBROUTINE RT_Asm_CSRMassCons(model, nDOF, M_csr, error)` |
| SUBROUTINE | `RT_Asm_CSRMassLump` | 1435 | `SUBROUTINE RT_Asm_CSRMassLump(model, nDOF, M_csr, error)` |
| SUBROUTINE | `RT_Asm_CSRMass_FromModel` | 1542 | `SUBROUTINE RT_Asm_CSRMass_FromModel(model, nDOF, mass_type, M_csr, error)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
