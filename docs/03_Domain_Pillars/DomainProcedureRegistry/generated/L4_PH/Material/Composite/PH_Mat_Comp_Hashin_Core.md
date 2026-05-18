# `PH_Mat_Comp_Hashin_Core.f90`

- **Source**: `L4_PH/Material/Composite/PH_Mat_Comp_Hashin_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Comp_Hashin_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Comp_Hashin_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Comp_Hashin`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Composite`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Composite/PH_Mat_Comp_Hashin_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Comp_Props` (lines 75–96)

```fortran
  TYPE, PUBLIC :: PH_Comp_Props
    !-- Elastic (orthotropic ply)
    REAL(wp) :: E1     = 0.0_wp   ! Longitudinal modulus (fiber dir) [Pa]
    REAL(wp) :: E2     = 0.0_wp   ! Transverse modulus [Pa]
    REAL(wp) :: nu12   = 0.0_wp   ! Major Poisson's ratio [-]
    REAL(wp) :: G12    = 0.0_wp   ! In-plane shear modulus [Pa]
    !-- Strength
    REAL(wp) :: X_T    = 0.0_wp   ! Fiber tensile strength [Pa]
    REAL(wp) :: X_C    = 0.0_wp   ! Fiber compressive strength [Pa]
    REAL(wp) :: Y_T    = 0.0_wp   ! Matrix tensile strength [Pa]
    REAL(wp) :: Y_C    = 0.0_wp   ! Matrix compressive strength [Pa]
    REAL(wp) :: S_L    = 0.0_wp   ! Longitudinal shear strength [Pa]
    REAL(wp) :: S_T    = 0.0_wp   ! Transverse shear strength [Pa]
    !-- Tsai-Wu interaction coefficient
    REAL(wp) :: F12_star = -0.5_wp ! Normalized interaction [-1,1]
    !-- Damage evolution (fracture energy regularization)
    REAL(wp) :: Gf_ft  = 0.0_wp   ! Fracture energy, fiber tension [J/m²]
    REAL(wp) :: Gf_fc  = 0.0_wp   ! Fracture energy, fiber compression [J/m²]
    REAL(wp) :: Gf_mt  = 0.0_wp   ! Fracture energy, matrix tension [J/m²]
    REAL(wp) :: Gf_mc  = 0.0_wp   ! Fracture energy, matrix compression [J/m²]
    REAL(wp) :: l_char = 1.0_wp   ! Characteristic element length [m]
  END TYPE PH_Comp_Props
```

### `PH_Comp_State` (lines 101–116)

```fortran
  TYPE, PUBLIC :: PH_Comp_State
    REAL(wp) :: stress(6)    = 0.0_wp   ! Stress (Voigt, 3D or plane stress) [Pa]
    REAL(wp) :: C_tan(6,6)   = 0.0_wp   ! Algorithmic tangent [Pa]
    !-- Damage variables [0,1]
    REAL(wp) :: D_ft         = 0.0_wp   ! Fiber tension damage
    REAL(wp) :: D_fc         = 0.0_wp   ! Fiber compression damage
    REAL(wp) :: D_mt         = 0.0_wp   ! Matrix tension damage
    REAL(wp) :: D_mc         = 0.0_wp   ! Matrix compression damage
    REAL(wp) :: D_s          = 0.0_wp   ! Shear damage (derived)
    !-- Failure indicators (Hashin)
    REAL(wp) :: f_hashin(4)  = 0.0_wp   ! Failure indices [FT, FC, MT, MC]
    !-- Tsai-Wu
    REAL(wp) :: f_tsaiwu     = 0.0_wp   ! Tsai-Wu failure index
    !-- Flags
    LOGICAL  :: failed       = .FALSE.  ! Any mode fully damaged
  END TYPE PH_Comp_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Comp_Validate_Params` | 123 | `SUBROUTINE PH_Mat_Comp_Validate_Params(props, ierr)` |
| SUBROUTINE | `PH_Mat_Comp_Init` | 156 | `SUBROUTINE PH_Mat_Comp_Init(props, state, ierr)` |
| SUBROUTINE | `PH_Mat_Comp_Hashin_Check` | 194 | `SUBROUTINE PH_Mat_Comp_Hashin_Check(props, stress, f_hashin, ierr)` |
| SUBROUTINE | `PH_Mat_Comp_TsaiWu_Check` | 242 | `SUBROUTINE PH_Mat_Comp_TsaiWu_Check(props, stress, f_tw, ierr)` |
| SUBROUTINE | `PH_Mat_Comp_Compute_Stress` | 283 | `SUBROUTINE PH_Mat_Comp_Compute_Stress(props, strain, state, stress, ierr)` |
| SUBROUTINE | `PH_Mat_Comp_Compute_Tangent` | 388 | `SUBROUTINE PH_Mat_Comp_Compute_Tangent(props, state, C_tangent, ierr)` |
| SUBROUTINE | `PH_Mat_Comp_Update_State` | 426 | `SUBROUTINE PH_Mat_Comp_Update_State(props, stress, C_tangent, state, ierr)` |
| SUBROUTINE | `update_damage_mode` | 446 | `SUBROUTINE update_damage_mode(f_fail, D_mode, Gf, sigma_0, E_mod, l_char)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
