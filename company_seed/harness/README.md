# F-Kernel Harness

## Purpose

Automated verification tooling for the F-Kernel codebase. The harness runs architectural checks, naming validation, and documentation health scans.

## Planned Tools

| Tool | Purpose |
|------|---------|
| `arch_guardian` | Layer dependency checker (DEP rules) |
| `naming_checker` | Fortran naming convention validator |
| `sio_checker` | Structured I/O signature validator |
| `doc_health` | Documentation cross-reference consistency |

## Usage

```bash
python harness/run_harness.py guardian
python harness/run_harness.py naming
python harness/run_harness.py sio
```

## Relationship to UFC

This harness implements the same architectural verification concepts described in the [UFC Architecture Specification](../../ARCHITECTURE_SPEC.md), Section 9.2. It is an independent, clean-room implementation — no code has been copied from the UFC project.
