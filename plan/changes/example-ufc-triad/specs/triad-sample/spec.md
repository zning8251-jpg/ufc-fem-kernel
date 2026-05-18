# Spec: ufc-governance-triad-sample

## ADDED Requirements

### Requirement: Change package discoverability

Humans and agents MUST be able to locate the triad documentation from the repository root within 3 hops (`README` / `AGENTS` / `ufc_governance`).

#### Scenario: Validate harness accepts golden sample

**WHEN** the validator runs against `change_id` `example-ufc-triad`
**THEN** the directory MUST contain `proposal.md`, `design.md`, `tasks.md`, and at least one `specs/**/spec.md`
**AND** the spec file MUST contain scenario-style keywords for traceability
