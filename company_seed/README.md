# F-Kernel — Clean-Room FEM Kernel Seed

> **This is a Clean-Room seed project.** It implements a six-layer FEM kernel architecture based on the publicly available [UFC Architecture Specification](../ARCHITECTURE_SPEC.md). It contains **no code** from the UFC project — only architectural patterns expressed as templates.

## Purpose

This seed provides a starting point for building a company-internal FEM kernel that follows the UFC architecture pattern while maintaining complete code independence. Use this to:

1. Bootstrap a new kernel project with the correct layered structure
2. Implement each layer step-by-step following the architecture spec
3. Ensure clean IP boundaries with the open-source UFC project

## Architecture

```
L6_App  ── Application Assembly (input/script/parser/solver/UI)
  ↑
L5_RT   ── Runtime (assembly/contact/load/solver coupling/step driver)
  ↑
L4_PH   ── Physics (elements/contact/constraints/load BC/material dispatch)
  ↑
L3_MD   ── Model Data (material/element/mesh/field/keyword/output/section)
  ↑
L2_NM   ── Numerical Methods (matrix/solver/time integration/external libs)
  ↑
L1_IF   ── Infrastructure (base/types/precision/error/IO/memory)
  ↑
L0_Global ── Global Container
```

## Project Structure

```
kernel/
  src/
    L0_Global/   — Global container, session lifecycle
    L1_Infra/    — Base types, precision, error, I/O, memory, registry
    L2_Numeric/  — Matrix types, solvers, time integration, convergence
    L3_Model/    — Material, element definitions, mesh, sections, BC
    L4_Physics/  — Element formulations, contact, constraint enforcement
    L5_Runtime/  — Step driver, solver orchestration, assembly loops
    L6_App/      — Input parsing, job config, solver selection, output
  include/       — Public API headers
harness/         — Automated verification tooling
governance/      — Engineering discipline framework
tools/           — Code generation and analysis utilities
tests/           — Unit, integration, and verification tests
docs/            — Internal documentation
config/          — Build and lint configuration
```

## Getting Started

See the architecture specification at `../ARCHITECTURE_SPEC.md` for the complete design description.

### Build Order

1. L0_Global — Global container
2. L1_Infra — Base types, precision, error, memory, registry
3. L2_Numeric — Matrix types, BLAS/LAPACK wrappers, solver interfaces
4. L3_Model — Material Desc types, mesh data structures
5. L4_Physics — Single element type, single material evaluation
6. L5_Runtime — Static linear solver loop
7. L6_App — Minimal keyword parser, single-step job runner
8. Iterate — Nonlinear solver, more elements, materials, contact, etc.

## IP Boundary

This seed and any code built from it constitute an **independent, clean-room implementation** of the architecture described in the public UFC Architecture Specification. No UFC source code has been or should be copied into this project.

See the parent project's [IP_PROTECTION.md](../IP_PROTECTION.md) for the full IP boundary documentation.
