# Spec: l4-material-binary-trivium

## ADDED Requirements

### Requirement: Material domain respects four-type + Args data side

Material feature modules MUST expose stable **Desc / State / Algo / Ctx** roles consistent with [`ufc_core/L4_PH/Material/CONTRACT.md`](../../../../../ufc_core/L4_PH/Material/CONTRACT.md). Boundary procedures MUST use unified `*_Arg` per Principle #14 (no new `inp`/`out` pairs for new code).

#### Scenario: Dispatch entry uses contract-consistent types

**WHEN** code paths in `PH_Mat_Dispatch` or equivalent registry dispatch material evaluation  
**THEN** arguments MUST follow approved `*_Arg` bundles for the called core  
**AND** MUST NOT introduce forbidden cross-layer `USE` patterns caught by Guardian P0 for this path

### Requirement: Space / time / action dimensions are testable

**Space** concerns (e.g. spatial operator hooks in Material cores) MUST be documented in module header or CONTRACT cross-links where they affect external behavior. **Time** concerns (stateful increments) MUST keep State carriers coherent across calls. **Action** concerns (outputs to RT / writes) MUST respect Bridge and hot-path rules.

#### Scenario: Populate path stays Guardian-clean

**WHEN** `PH_L4_Populate` (or successor) wires Material Desc/State/Algo/Ctx for a step  
**THEN** the resulting `USE` graph for edited files MUST pass `guardian … --fail-on-p0` for the scoped Material path

#### Scenario: Naming gate for edited Material Fortran

**WHEN** any `ufc_core/L4_PH/Material/**/*.f90` file is modified under this change  
**THEN** `naming` checker MUST report no new hard violations for that path
