# UFC (UniFieldCore) — Unified Field Core Architecture

A **field-agnostic, six-layer FEM kernel** designed for large-scale multiphysics PDE assembly and solving. UFC transforms the traditional "solid mechanics calculator" into a **unified PDE engine** capable of covering solid large-deformation, high-Reynolds CFD, high-frequency electromagnetics, and beyond.

## Architecture

```
L6_AP  ─  Application Assembly (input/script/parser/solver/UI)
  │
L5_RT  ─  Runtime (assembly/contact/load/solver coupling/step driver)
  │
L4_PH  ─  Physics (elements/contact/constraints/load BC/material dispatch)
  │
L3_MD  ─  Model Data (material/element/mesh/field/keyword/output/section)
  │
L2_NM  ─  Numerical Methods (matrix/solver/time integration/external libs)
  │
L1_IF  ─  Infrastructure (base/AI/parallel/error/IO/memory/precision/registry)
  │
L0_Global ─ Global Container
```

### Four Pillar Types (all layers)

| Type | Role |
|------|------|
| **Desc** | Immutable data description (parameters, properties) |
| **State** | Mutable runtime state (stress, strain, solution vectors) |
| **Algo** | Stateless pure computation kernels |
| **Ctx**  | Soft-cache for hot-path data (~1 KB per call site) |

### Four Execution Chains

- **Theory Chain** — constitutive laws, PDE formulations
- **Logic Chain** — domain procedure orchestration
- **Computation Chain** — numerical kernels, assembly
- **Data Chain** — structured I/O, serialization, checkpointing

### Key Design Principles

- **Structured I/O**: Unified `*_Arg` bundles with `[IN]/[OUT]` annotations
- **5/6-tuple signatures**: `(desc, state, algo, ctx, [com_ctx], args)` for all core procedures
- **Field registry**: Dynamic field registration, no hardcoded DOF concepts
- **Flat data model**: Physical entities linked by foreign-key IDs, max 3-level type nesting
- **3-LAR execution dictionary**: `{Where}_{When}{What}` naming (e.g., `_Proc_ElmItrEvl`)
- **Auto-diff ready**: Dual-number operator overloading for zero-error tangent stiffness

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `ufc_core/` | Fortran 90 FEM kernel (~1,100 files, 6 layers L0–L6) |
| `ufc_harness/` | Python tooling: naming checker, SIO checker, arch guardian, docs health |
| `ufc_governance/` | Engineering governance: triads, change packages, manifest |
| `skills/` | Agent skills for AI-assisted development |
| `tools/` | Code generation, architecture validation, migration utilities |
| `rules/` | Cursor/Claude rules for naming, syntax, architecture |
| `docs/` | Architecture specs, developer guides, domain pillars (~2,700 files) |
| `config/` | Linter config, naming lexicon, precision migration |
| `scripts/` | CI harness gates and contract checks |
| `tests/` | Test suite |

## Documentation

Start here: [`docs/00-快速导航.md`](docs/00-快速导航.md)

- **Architecture SSOT**: [`docs/01_Architecture_Spec/`](docs/01_Architecture_Spec/)
- **Developer Guide**: [`docs/02_Developer_Guide/`](docs/02_Developer_Guide/)
- **Domain Pillars**: [`docs/03_Domain_Pillars/`](docs/03_Domain_Pillars/)
- **Project Planning (PPLAN)**: [`docs/05_Project_Planning/PPLAN/`](docs/05_Project_Planning/PPLAN/)

## Prerequisites

- Fortran 90+ compiler (GFortran 10+, ifort, ifx)
- Python 3.9+ (for harness tooling)
- Node.js 18+ (for `@fission-ai/openspec` governance CLI, optional)
- CMake 3.20+

## License

**Apache License 2.0** — see [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Intellectual Property Notice

This is a personal open-source project created and maintained independently. For details on intellectual property boundaries between this open-source project and any derivative works (e.g., company-internal implementations based on the architecture specification), see [IP_PROTECTION.md](IP_PROTECTION.md).
