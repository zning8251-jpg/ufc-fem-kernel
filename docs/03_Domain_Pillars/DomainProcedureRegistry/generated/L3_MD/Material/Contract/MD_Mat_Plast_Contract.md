# `MD_Mat_Plast_Contract.f90`

- **Source**: `L3_MD/Material/Contract/MD_Mat_Plast_Contract.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Plast_Contract`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_Contract`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast_Contract`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Contract/MD_Mat_Plast_Contract.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PlastStateVariables` (lines 32–38)

```fortran
    TYPE, PUBLIC :: PlastStateVariables
        REAL(wp) :: eps_p_eqv = 0.0_wp
        REAL(wp), ALLOCATABLE :: eps_p(:, :)
        REAL(wp) :: alpha = 0.0_wp
        REAL(wp) :: kappa = 0.0_wp
        INTEGER(i4) :: n_statev = 0
    END TYPE PlastStateVariables
```

### `PlastHardeningRule` (lines 40–46)

```fortran
    TYPE, PUBLIC :: PlastHardeningRule
        INTEGER(i4) :: hardening_type = 0
        REAL(wp) :: H = 0.0_wp
        REAL(wp) :: sigma_y0 = 0.0_wp
        REAL(wp) :: sigma_y_inf = 0.0_wp
        REAL(wp) :: delta = 0.0_wp
    END TYPE PlastHardeningRule
```

### `PlastFlowRule` (lines 48–51)

```fortran
    TYPE, PUBLIC :: PlastFlowRule
        INTEGER(i4) :: flow_type = 1
        REAL(wp) :: dilation_angle = 0.0_wp
    END TYPE PlastFlowRule
```

### `PlastMatBase` (lines 53–61)

```fortran
    TYPE, PUBLIC :: PlastMatBase
        INTEGER(i4) :: material_id = 0
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: yield_criterion = 0
        TYPE(PlastHardeningRule) :: hardening
        TYPE(PlastFlowRule) :: flow_rule
        REAL(wp), ALLOCATABLE :: props(:)
        INTEGER(i4) :: n_props = 0
    END TYPE PlastMatBase
```

### `ComputeDeviatoricStress_In` (lines 63–65)

```fortran
    TYPE, PUBLIC :: ComputeDeviatoricStress_In
        REAL(wp) :: stress(6)
    END TYPE ComputeDeviatoricStress_In
```

### `ComputeDeviatoricStress_Out` (lines 67–69)

```fortran
    TYPE, PUBLIC :: ComputeDeviatoricStress_Out
        REAL(wp) :: s_dev(6)
    END TYPE ComputeDeviatoricStress_Out
```

### `ComputeFlowDirection_In` (lines 71–74)

```fortran
    TYPE, PUBLIC :: ComputeFlowDirection_In
        REAL(wp) :: stress(6)
        TYPE(PlastMatBase) :: mat
    END TYPE ComputeFlowDirection_In
```

### `ComputeFlowDirection_Out` (lines 76–79)

```fortran
    TYPE, PUBLIC :: ComputeFlowDirection_Out
        REAL(wp) :: flow_direction(6)
        TYPE(ErrorStatusType) :: status
    END TYPE ComputeFlowDirection_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
