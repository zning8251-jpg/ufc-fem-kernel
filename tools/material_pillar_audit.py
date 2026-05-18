#!/usr/bin/env python3
"""Generate Material pillar inventory and closure backlog.

The Material pillar spans L3_MD/Material, L4_PH/Material, and L5_RT/Material.
This audit keeps the cross-layer contract visible without requiring a full
Fortran build: it classifies source files by layer, family, role suffix, hot
path / bridge markers, legacy L3 hot-path dependencies, and closure-test
mentions.
"""

from __future__ import annotations

import csv
import importlib.util
import re
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "03_Domain_Pillars" / "MaterialPillar"
TEST_PATH = ROOT / "tests" / "TEST_Material_L3_L4_Closure.f90"
CATALOG_SCRIPT = ROOT / "tools" / "material_mat_catalog.py"

LAYER_ROOTS = {
    "L3_MD": ROOT / "ufc_core" / "L3_MD" / "Material",
    "L4_PH": ROOT / "ufc_core" / "L4_PH" / "Material",
    "L5_RT": ROOT / "ufc_core" / "L5_RT" / "Material",
}

EXTRA_MATERIAL_ANCHORS = {
    "L3_MD": [
        ROOT / "ufc_core" / "L3_MD" / "Bridge" / "Bridge_L4" / "MD_MatLibPH_Brg.f90",
        ROOT / "ufc_core" / "L3_MD" / "MD_L3_Layer.f90",
    ],
    "L4_PH": [
        ROOT / "ufc_core" / "L4_PH" / "Material" / "PH_L4_Populate.f90",
        ROOT / "ufc_core" / "L4_PH" / "Material" / "PH_L4_L3MatContract.f90",
        ROOT / "ufc_core" / "L4_PH" / "Element" / "Shared" / "PH_Elem_MaterialRoute.f90",
    ],
}

HOT_PATH_MARKERS = (
    "RT_Mat_Dispatch",
    "PH_Elem_MatRoute",
    "_Material_Update_Routed",
    "Compute_Ctan",
    "Update_Stress",
    "PH_Mat_Eval",
)

BRIDGE_MARKERS = (
    "_Brg",
    "Bridge",
    "BuildTable",
    "Populate",
    "MakeCtx",
    "WriteBack",
)

LEGACY_HOT_PATH_MARKERS = (
    "USE MD_MatRT_Brg",
    "MD_Mat_Dispatch",
    "MD_PH_RouteToConstitutive",
)

ROLE_HINTS = (
    ("Def", ("_Def", "_Defn", "Contract", "Standards", "UMAT")),
    ("Domain", ("Domain", "Mgr")),
    ("Registry", ("Reg", "Registry")),
    ("Core", ("Core", "Kernel")),
    ("Ops", ("Ops", "Validate", "Validation", "Sync", "PopulateMap")),
    ("Eval", ("Eval", "Dispatch", "Call")),
    ("Bridge", ("Brg", "Bridge")),
    ("Proc", ("Proc",)),
    ("Test", ("Test",)),
)


@dataclass
class MaterialFile:
    layer: str
    rel_path: str
    family: str
    module: str
    role: str
    has_desc: bool
    has_state: bool
    has_algo: bool
    has_ctx: bool
    is_hot_path: bool
    is_bridge: bool
    has_legacy_hot_path: bool
    tested: bool
    note: str


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def source_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def infer_module(text: str, path: Path) -> str:
    match = re.search(r"^\s*MODULE\s+([A-Za-z0-9_]+)", text, re.IGNORECASE | re.MULTILINE)
    return match.group(1) if match else path.stem


def infer_family(layer_root: Path, path: Path) -> str:
    rel_parts = path.relative_to(layer_root).parts
    if len(rel_parts) == 1:
        return "Root"
    return rel_parts[0]


def infer_role(path: Path, text: str) -> str:
    stem = path.stem
    bucket = path.parent.name
    probe = f"{bucket} {stem} {text[:1500]}"
    for role, hints in ROLE_HINTS:
        if any(hint.lower() in probe.lower() for hint in hints):
            return role
    return "Support"


def collect_test_symbols() -> set[str]:
    if not TEST_PATH.exists():
        return set()
    text = source_text(TEST_PATH)
    return set(re.findall(r"\b(?:test_|PH_|RT_|MD_)[A-Za-z0-9_]+", text))


def classify(layer: str, layer_root: Path, path: Path, tested_symbols: set[str]) -> MaterialFile:
    text = source_text(path)
    module = infer_module(text, path)
    role = infer_role(path, text)
    has_desc = bool(re.search(r"\bTYPE\b.*(?:Desc|_Desc|PH_Mat_Slot)", text, re.IGNORECASE))
    has_state = "State" in text or "stateVars" in text or "C_tan" in text
    has_algo = "Algo" in text or "Compute" in text or "Eval" in text or "Dispatch" in text
    has_ctx = "Ctx" in text or "Context" in text or "mat_pt_idx" in text
    is_hot_path = any(marker in text for marker in HOT_PATH_MARKERS)
    is_bridge = role == "Bridge" or any(marker in path.stem or marker in text[:3000] for marker in BRIDGE_MARKERS)
    has_legacy_hot_path = any(marker in text for marker in LEGACY_HOT_PATH_MARKERS)
    tested = module in tested_symbols or path.stem in tested_symbols

    notes: list[str] = []
    if layer == "L3_MD" and is_hot_path:
        notes.append("L3 hot-path marker: freeze or migrate")
    if has_legacy_hot_path:
        notes.append("legacy material route dependency")
    if layer == "L5_RT" and (has_desc or has_state):
        notes.append("check thin-router boundary")
    if not tested and layer in {"L4_PH", "L5_RT"} and (is_hot_path or is_bridge):
        notes.append("needs closure-test anchor")

    return MaterialFile(
        layer=layer,
        rel_path=rel(path),
        family=infer_family(layer_root, path) if path.is_relative_to(layer_root) else "CrossLayer",
        module=module,
        role=role,
        has_desc=has_desc,
        has_state=has_state,
        has_algo=has_algo,
        has_ctx=has_ctx,
        is_hot_path=is_hot_path,
        is_bridge=is_bridge,
        has_legacy_hot_path=has_legacy_hot_path,
        tested=tested,
        note="; ".join(notes),
    )


def collect_files() -> list[MaterialFile]:
    tested_symbols = collect_test_symbols()
    rows: list[MaterialFile] = []
    seen: set[Path] = set()
    for layer, layer_root in LAYER_ROOTS.items():
        for path in sorted(layer_root.rglob("*.f90")):
            rows.append(classify(layer, layer_root, path, tested_symbols))
            seen.add(path)
        for path in EXTRA_MATERIAL_ANCHORS.get(layer, []):
            if path.exists() and path not in seen:
                rows.append(classify(layer, layer_root, path, tested_symbols))
                seen.add(path)
    return rows


def write_inventory(rows: list[MaterialFile]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUT_DIR / "material_pillar_inventory.csv"
    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(MaterialFile.__dataclass_fields__.keys()))
        writer.writeheader()
        for row in rows:
            writer.writerow(row.__dict__)


def yes(value: bool) -> str:
    return "Y" if value else "N"


def write_summary(rows: list[MaterialFile]) -> None:
    by_layer = Counter(row.layer for row in rows)
    by_role = Counter(row.role for row in rows)
    legacy = [row for row in rows if row.has_legacy_hot_path]
    untested_hot = [row for row in rows if (row.is_hot_path or row.is_bridge) and not row.tested]

    lines = [
        "# Material Pillar Audit Summary",
        "",
        "Generated by `tools/material_pillar_audit.py`.",
        "",
        "## Counts",
        "",
        "| Metric | Count |",
        "|--------|------:|",
        f"| Inventory rows | {len(rows)} |",
        f"| L3_MD rows | {by_layer['L3_MD']} |",
        f"| L4_PH rows | {by_layer['L4_PH']} |",
        f"| L5_RT rows | {by_layer['L5_RT']} |",
        f"| Legacy hot-path dependency rows | {len(legacy)} |",
        f"| Untested hot/bridge rows | {len(untested_hot)} |",
        "",
        "## Role Distribution",
        "",
        "| Role | Count |",
        "|------|------:|",
    ]
    for role, count in sorted(by_role.items()):
        lines.append(f"| `{role}` | {count} |")
    lines.extend(
        [
            "",
            "## Cross-Layer Closure State",
            "",
            "| Layer | Boundary decision | Current closure action |",
            "|-------|-------------------|------------------------|",
            "| L3_MD | Desc/validation/registry SSOT | Freeze compute-like `MD_Mat_Lib` surface and split validation/metadata gradually |",
            "| L4_PH | Populate, slot, IP state, kernels | Harden `PH_Mat_Slot` and route all hot paths through L4 kernels |",
            "| L5_RT | Thin router only | Validate table/ctx/writeback with populated L4 slots; no Desc or IP state copies |",
            "",
            "## Notes",
            "",
            "- `material_pillar_inventory.csv` is the detailed source of truth for file roles and audit flags.",
            "- Legacy hot-path rows require migration or explicit cold-path quarantine.",
            "- Untested hot/bridge rows should gain exact closure-test anchors before family rollout is marked complete.",
        ]
    )
    (OUT_DIR / "material_pillar_summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_backlog(rows: list[MaterialFile]) -> None:
    legacy = [row for row in rows if row.has_legacy_hot_path]
    untested_hot = [row for row in rows if (row.is_hot_path or row.is_bridge) and not row.tested]
    l3_compute = [row for row in rows if row.layer == "L3_MD" and row.is_hot_path]

    lines = [
        "# Material Pillar Backlog",
        "",
        "Generated by `tools/material_pillar_audit.py`.",
        "",
        "## L3 Compute-Like / Hot-Path Quarantine",
        "",
        "| File | Role | Note |",
        "|------|------|------|",
    ]
    for row in l3_compute:
        lines.append(f"| `{row.rel_path}` | `{row.role}` | {row.note or 'review L3 boundary'} |")

    lines.extend(["", "## Legacy Material Route Dependencies", "", "| File | Layer | Note |", "|------|-------|------|"])
    for row in legacy:
        lines.append(f"| `{row.rel_path}` | `{row.layer}` | {row.note or 'migrate away from legacy route'} |")

    lines.extend(["", "## Hot / Bridge Rows Needing Test Anchors", "", "| File | Layer | Role | Note |", "|------|-------|------|------|"])
    for row in untested_hot[:120]:
        lines.append(f"| `{row.rel_path}` | `{row.layer}` | `{row.role}` | {row.note or 'add closure-test anchor'} |")
    if len(untested_hot) > 120:
        lines.append(f"| ... | ... | ... | {len(untested_hot) - 120} more rows in CSV |")

    (OUT_DIR / "material_pillar_backlog.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    rows = collect_files()
    write_inventory(rows)
    write_summary(rows)
    write_backlog(rows)
    print(f"wrote {OUT_DIR / 'material_pillar_inventory.csv'}")
    print(f"wrote {OUT_DIR / 'material_pillar_summary.md'}")
    print(f"wrote {OUT_DIR / 'material_pillar_backlog.md'}")
    print(f"rows={len(rows)}")

    if CATALOG_SCRIPT.exists():
        spec = importlib.util.spec_from_file_location("material_mat_catalog", CATALOG_SCRIPT)
        if spec and spec.loader:
            mod = importlib.util.module_from_spec(spec)
            sys.modules["material_mat_catalog"] = mod
            spec.loader.exec_module(mod)
            mod.main()
        else:
            print(f"skip mat catalog: could not load {CATALOG_SCRIPT}")
    else:
        print(f"skip mat catalog: missing {CATALOG_SCRIPT}")


if __name__ == "__main__":
    main()
