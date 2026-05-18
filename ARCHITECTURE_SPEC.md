# UFC Architecture Specification v1.0 — Clean-Room Reference

> **Purpose**: This document defines the UFC architecture in purely descriptive terms, without including any implementation code. It serves as the legally safe reference for creating independent, clean-room implementations of the UFC architecture. Any organization may use this specification to build their own FEM kernel following the same architectural patterns, without copying the original source code.

---

## 1. Core Vision

A **field-agnostic PDE assembly and solving engine**. Rather than being a traditional "solid mechanics calculator," the architecture treats all physics as instances of field equations assembled and solved through a common infrastructure.

### 1.1 Design Goals

- Single codebase covering solid mechanics, CFD, electromagnetics, and coupled multiphysics
- No hardcoded degree-of-freedom concepts at the framework level
- Extension through registration, not modification of core code
- Industrial-grade nonlinear solving with automatic differentiation support

---

## 2. Six-Layer Architecture

The system is organized into six strictly ordered layers. Each layer may only depend on layers below it (never above).

### Layer Stack

| Layer | Name | Responsibility |
|-------|------|----------------|
| **L0** | Global Container | Single global state container, session lifecycle |
| **L1** | Infrastructure | Base types, precision, error handling, I/O, memory management, logging, monitoring, parallel primitives, register pattern |
| **L2** | Numerical Methods | Linear algebra (matrix types, BLAS/LAPACK wrappers), linear/nonlinear solvers, time integration, convergence checks, external library bridges |
| **L3** | Model Data | Material definitions, element types, mesh, sections, boundary conditions, loads, fields, amplitude curves, analysis procedures, keyword parser, output requests, assembly instructions |
| **L4** | Physics | Element formulations (solid, shell, beam, membrane, thermal, fluid, acoustic, etc.), contact algorithms, constraint enforcement, material law dispatch to integration points |
| **L5** | Runtime | Step driver state machine, solver orchestration, assembly loops, load incrementation, convergence management, contact activation |
| **L6** | Application | Input parsing (keyword/script), job configuration, solver selection, output formatting, user interface |

### 2.1 Dependency Rule

```
L6 → L5 → L4 → L3 → L2 → L1 → L0
```

Any upward dependency (e.g., L3 referencing L4) is forbidden. Cross-layer communication happens through Bridge modules (*_Brg) that are exempt from the strict layer ordering.

---

## 3. Four Pillar Types

Every layer expresses its domain concepts through exactly four type categories:

| Type | Mutability | Purpose |
|------|-----------|---------|
| **Desc** | Immutable | Data description — parameters, properties, configuration. Populated once at initialization. |
| **State** | Mutable | Runtime state — current values of solution fields, stresses, strains, internal variables. |
| **Algo** | Stateless | Pure computation kernels — mathematical operations with no side effects on persistent state. |
| **Ctx** | Mutable (soft cache) | Execution context — a lightweight (~1 KB) bundle of pre-fetched pointers and pre-computed indices assembled before entering hot-path loops. |

### 3.1 File Suffix Convention

Physical files use four suffixes to indicate their role:
- `_Def` — Data definitions (types, parameters, lookup tables)
- `_Core` — Stateless algorithmic kernels
- `_Proc` — Process pipelines (orchestrate Def/Core calls with state transitions)
- `_Brg` — External bridges (cross-layer or external library interfaces)

The four pillar types (Desc/State/Algo/Ctx) appear only as TYPE names within modules, never as file suffixes.

---

## 4. Structured I/O (SIO) — Principle #14

### 4.1 Unified Argument Bundle

All data passed into core procedures uses a single `*_Arg` derived type with explicit `[IN]`/`[OUT]` annotations on each member. There are no separate `inp`/`out` argument pairs.

### 4.2 Signature Pattern

Core subroutines follow a 5-tuple or 6-tuple pattern:

```
(desc, state, algo, ctx, args)           — 5-tuple
(desc, state, algo, ctx, com_ctx, args)  — 6-tuple (with shared runtime context)
```

Where:
- **desc**: Immutable description of what to compute
- **state**: Mutable state to read and update
- **algo**: Stateless algorithm selector/configuration
- **ctx**: Soft-cache context (populated before hot path)
- **com_ctx**: (optional) Shared runtime communication context
- **args**: Unified [IN]/[OUT] argument bundle

### 4.3 Populate-HotPath Separation

1. **Populate phase**: Ctx and Args are assembled from large memory pools into compact bundles
2. **Hot-path phase**: _Core procedures consume only the compact bundles, avoiding pointer chasing through large data structures

---

## 5. Execution Dictionary (3-LAR)

The execution naming follows a three-axis coordinate system:

### 5.1 X-Axis: Spatial Scope (Where)

| Code | Meaning |
|------|---------|
| `Glb` | Global (entire model) |
| `Reg` | Region (subset of model) |
| `Elm` | Element (single element) |
| `Pt`  | Integration point (single Gauss point) |
| `Fac` | Face (element boundary — for DG-FEM) |

### 5.2 Y-Axis: Temporal Phase (When)

**Macro scale:**
| Code | Meaning |
|------|---------|
| `Stp` | Step (analysis step) |
| `Inc` | Increment (load/time increment) |

**Micro scale:**
| Code | Meaning |
|------|---------|
| `Ini` | Initial (setup at start) |
| `Prd` | Predictor (trial state) |
| `Itr` | Iteration (within Newton loop) |
| `Cmt` | Commit (accept converged state) |
| `Rbk` | Rollback (reject failed iteration) |

### 5.3 Z-Axis: Action (What)

| Code | Meaning |
|------|---------|
| `Pop` | Populate (gather data into context) |
| `Evl` | Evaluate (core computation) |
| `Asm` | Assemble (into global matrix/vector) |
| `Map` | Map (field projection/transfer) |
| `Exp` | Export (output to files) |

### 5.4 Naming Pattern

```
{Prefix}_{Domain}_{Where}{When}{What}
```

Example: `_Proc_ElmItrEvl` = Element-level, iteration-phase, evaluate procedure.

---

## 6. Data Architecture

### 6.1 Flat Data Model (L3)

Physical entities (parts, materials, sections, elements, nodes) are stored in parallel memory pools linked by foreign-key IDs. There is no deep physical nesting — type nesting depth is capped at 3 levels.

### 6.2 Field Registry

Degrees of freedom are not hardcoded. At initialization, the application registers fields dynamically:
- Field name (e.g., "Velocity", "Displacement", "Temperature", "Pressure")
- Tensor rank (SCALAR, VECTOR, TENSOR2, TENSOR4)
- Interpolation order
- Element family compatibility

This enables native support for mixed formulations (Taylor-Hood, Raviart-Thomas) and LBB-stable saddle-point problems.

### 6.3 Memory Strategy

- **Pool allocation**: Large contiguous memory pools with structure-of-arrays layout
- **Soft caching**: Pre-fetched 1 KB Ctx bundles eliminate pointer chasing in hot loops
- **No global mutable state** below L5: data flows through arguments, not global variables

---

## 7. Numerical Infrastructure

### 7.1 Solver Matrix

| Problem Class | Strategy |
|--------------|----------|
| Small-medium, ill-conditioned | Direct sparse (PARDISO, MUMPS) |
| Large, positive-definite | Krylov + AMG preconditioner (PETSc + Hypre/BoomerAMG) |
| Saddle-point (CFD) | Fractional step: momentum (non-symmetric Krylov) + pressure Poisson (symmetric AMG) |

### 7.2 Automatic Differentiation

- Classical constitutive models: hand-coded tangent stiffness
- New/experimental models: dual-number operator overloading for automatic exact tangent computation
- Hybrid mode: both approaches coexist; selection per material

### 7.3 Nonlinear Safeguards

- **Line search**: Prevents overshoot in large-deformation steps
- **B-bar method**: Resolves volumetric locking in near-incompressible materials
- **Augmented Lagrange**: Smooth contact enforcement (alternative to pure penalty)
- **Matrix thermal probe**: Detects stability loss and auto-switches from symmetric-static to non-symmetric/transient solver

---

## 8. Extension Points

### 8.1 User Material (UMAT-like)

- Register material name and properties via keyword
- Implement a standard interface receiving strain increment, state variables, and returning stress and tangent
- Bridge module dispatches to user implementation

### 8.2 User Element (UEL-like)

- Register element type, node count, DOF layout
- Implement stiffness, mass, and residual computation interfaces
- Compatible with the field registry for arbitrary DOF types

### 8.3 Operator Injection

- Standard Galerkin assembly runs first
- Stabilization operators (SUPG, GLS, VMS) are injected at pre-assembly hook points
- Hook chain: `before_assemble → standard_galerkin → inject_stabilization → after_assemble`

---

## 9. Governance System

### 9.1 Triad Model

Three parallel rings for engineering discipline:

1. **Spec Ring**: Change packages (proposal → design → spec → tasks)
2. **Flow Ring**: Playbooks defining how work is executed (feature, rollout, skill routing)
3. **Discipline Ring**: Manifest + automated verification gates

### 9.2 Architecture Guardian

Automated checks encoded in the harness verify:
- **DEP-001**: Layer dependency direction (no upward references)
- **GLB-001**: Element kernels must not access global container
- Additional rules for naming, data contracts, and structural patterns

---

## 10. Module Naming Convention

### 10.1 Pattern

```
{LayerPrefix}_{Domain}_{Role}
```

- **LayerPrefix**: Two-letter layer identifier (IF, NM, MD, PH, RT, AP)
- **Domain**: Domain within layer (e.g., Base, Mat, Elem, Solv, KW, LoadBC)
- **Role**: Module role (Def, Core, Proc, Brg, Mgr, Reg, Lib)

### 10.2 Constraints

- Maximum 3 segments total
- Public procedures: prefixed with Layer_Domain (e.g., `RT_Step_Init`)
- Private procedures: unprefixed short names
- CONSTANTS and PARAMETERs: UPPER_SNAKE_CASE
- Variables: ≤ 20 characters
- Compression lexicon preferred: Mgr (Manager), Solv (Solver), Brg (Bridge), Cfg (Configuration), Asm (Assembly)

---

## 11. Testing & Verification Architecture

### 11.1 Test Hierarchy

1. **Unit tests**: Single module/function, mocked dependencies at injection boundaries
2. **Integration tests**: Layer pairs connected through bridges
3. **End-to-end tests**: Full analysis workflows
4. **Verification tests**: Patch tests, NAFEMS benchmarks, Abaqus reference comparisons

### 11.2 Verification Checklist

- Patch test (constant strain)
- Cantilever beam (geometric nonlinear)
- Cook's membrane (mixed formulation)
- NAFEMS benchmark problems (LE1-LE11, NL1-NL5)
- Thermo-mechanical coupled benchmarks

---

## Appendix A: Comparison with Traditional FEM Codes

| Aspect | Traditional (e.g., Abaqus UMAT interface) | UFC Architecture |
|--------|------------------------------------------|------------------|
| DOF model | Hardcoded (u,v,w displacement) | Dynamic field registry |
| Data nesting | 6+ levels deep physical containment | Flat memory pools, FK-linked, max 3 levels |
| Material interface | Stress/state array convention | Typed Desc/State/Algo/Ctx bundles |
| Solver coupling | Monolithic or file-based co-simulation | In-memory fractional-step with solver matrix |
| Extension model | Fortran subroutines with implicit contracts | Registered plugins with explicit typed interfaces |
| Execution model | Implicit time/space nesting in code structure | Explicit 3-LAR (Where/When/What) execution dictionary |

---

## Appendix B: Derived Implementation Roadmap

For a clean-room implementation, the recommended build order is:

1. **L1_IF** — Base types, precision, error, memory pool, registry pattern
2. **L2_NM** — Matrix types, BLAS/LAPACK wrappers, linear solver interfaces
3. **L3_MD** — Material Desc types, simple elastic material, mesh data structures
4. **L4_PH** — Single element type (linear hex), single material evaluation
5. **L5_RT** — Static linear solver loop
6. **L6_AP** — Minimal keyword parser, single-step job runner
7. **Iterate**: Add nonlinear solver, more elements, more materials, contact, etc.

---

*This specification describes an architecture pattern. It contains no implementation code and may be freely used as a reference for independent implementations under any license terms the implementer chooses.*
