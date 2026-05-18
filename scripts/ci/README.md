# UFC `scripts/ci` — local checks and CI alignment

This directory holds small Python helpers used by automation or developers. **Documentation structure and Fortran SSOT gates** are owned by `ufc_harness/run_harness.py` (see `ufc_harness/README.md`).

## Harness doc / SSOT gates (recommended)

Run from the **UFC repository root** (the directory that contains `ufc_core/`, `docs/`, `ufc_harness/`, `design_plan/`). Use forward slashes in examples; they work on Windows, Linux, and macOS shells.

### Full bundle: `plan-checks` (CI default)

Runs, in order: `doc-structure` → `cross-ref` → `reports-root-guard` → `code-templates-ssot`. Any step with a non-zero exit code fails the command.

```bash
cd UFC
python ufc_harness/run_harness.py plan-checks
```

### Minimum SSOT only

If `cross_ref` is temporarily noisy (broken links under `design_plan/`), CI can be narrowed to SSOT only until links are fixed:

```bash
cd UFC
python ufc_harness/run_harness.py code-templates-ssot
```

### Alternative bundle (no `cross-ref`)

```bash
cd UFC
python ufc_harness/run_harness.py doc-structure
python ufc_harness/run_harness.py reports-root-guard
python ufc_harness/run_harness.py code-templates-ssot
```

## Exit code semantics (harness)

| Exit code | Meaning |
|-----------|---------|
| **0** | All invoked checks passed. |
| **1** | At least one check reported failures (e.g. SSOT violations, doc-structure issues, bad links, REPORTS root markdown over limit). |
| **2** | Harness or tool misconfiguration (e.g. required script missing under `ufc_harness/tools/` or `UFC/tools/`). |

`code-templates-ssot --warn-only` prints violations but exits **0** (for gradual CI rollout only).

## GitHub Actions

The **UFC CI** workflow (`.github/workflows/ufc-ci.yml` at the parent monorepo root when applicable) includes a **Harness doc / SSOT** job that runs `plan-checks` with the working directory set to the UFC tree (`cd UFC` when the checkout layout is `…/UFC/…`). The same job installs **`UFC/package.json`** (devDependency `@fission-ai/openspec`), runs **`npx openspec --version`**, then **`python scripts/ci/check_change_packages_strict.py --ufc-root UFC`** so every `plan/changes/<id>/` directory that contains `proposal.md` is validated with **`change-package validate --strict`**.

## Change packages (strict, CI-aligned)

From monorepo root (directory that contains both `UFC/` and `scripts/ci/`):

```bash
python scripts/ci/check_change_packages_strict.py --ufc-root UFC
```

Equivalent for the golden sample only (from `UFC/`):

```bash
cd UFC
python ufc_harness/run_harness.py change-package validate --change-id example-ufc-triad --strict
```

## OpenSpec npm CLI (optional fallback)

Installed under **`UFC/package.json`** (`npm ci` / `npm install` in `UFC/`). Typical use when you adopt upstream OpenSpec change layout:

```bash
cd UFC
npx openspec --help
# e.g. npx openspec validate <change-id>   # when openspec/ tree exists per OpenSpec docs
```

Primary validation in-repo remains **`ufc_harness` `change-package validate`** (aligned with `plan/changes/` layout documented in `ufc_governance/`).

## Scripts in this folder

| Script | Role |
|--------|------|
| `check_harness_gates.py` | Legacy / supplemental static checks on `ufc_core` (contracts, ISO_FORTRAN_ENV, hot-path ALLOCATE, etc.). Invoked with `ufc_core` path; exit **1** on hard-gate failure. |
| `check_contracts.py` | CONTRACT.md presence and light structure checks per domain. |

For the canonical **Harness** entrypoints (`doc-structure`, `plan-checks`, `guardian`, `naming`, …), use `python ufc_harness/run_harness.py …` from the UFC root as above.
