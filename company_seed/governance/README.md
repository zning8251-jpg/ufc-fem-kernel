# F-Kernel Governance

## Triad Model

Based on the governance pattern described in the [UFC Architecture Specification](../../ARCHITECTURE_SPEC.md), Section 9.

### Three Rings

1. **Spec Ring**: Change packages (proposal → design → specification → tasks)
2. **Flow Ring**: Playbooks for feature development, rollouts, and skill routing
3. **Discipline Ring**: Manifest of required checks + automated verification gates

### Directory Layout

```
governance/
├── triad/
│   ├── spec/         — Change package templates
│   ├── flow/         — Playbooks (feature, rollout, routing)
│   └── discipline/   — Manifest and tier maps
└── library/          — Reference documents (constitution, statutes)
```

This governance system is an independent implementation of the publicly documented UFC governance pattern. No governance documents or templates have been copied from the UFC project.
