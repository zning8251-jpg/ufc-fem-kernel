# Design: example-ufc-triad

## Decisions

1. **Decision**: Canonical change packages live under `UFC/plan/changes/<change_id>/`.
   - **Rationale**: Keeps runtime `plan/` bucket unified; avoids a second parallel tree under `ufc_governance/`.

## Open Questions

- None for this sample.

## Alternatives considered

- Storing packages only under `ufc_governance/triad/spec/changes/` — rejected to prevent dual locations (see POLICY.md).
