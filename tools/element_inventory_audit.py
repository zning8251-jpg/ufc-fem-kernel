#!/usr/bin/env python3
"""Generate UFC element inventory and material-route reconciliation tables.

This tool intentionally separates two facts:

* The PPLAN target is 377 element variants.
* The current L4 registry contains fewer concrete rows.

Rows that do not yet have authoritative element names are emitted as
UNRESOLVED_TARGET_SLOT so the 377 accounting gap remains visible instead of
being hidden behind family-level route coverage.
"""

from __future__ import annotations

import csv
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


TARGET_COUNT = 377

ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = ROOT / "ufc_core" / "L4_PH" / "Element" / "PH_Elem_Reg.f90"
ELEMENT_ROOT = ROOT / "ufc_core" / "L4_PH" / "Element"
L3_MESH_PATH = ROOT / "ufc_core" / "L3_MD" / "Mesh" / "MD_Elem_Mgr.f90"
TEST_PATH = ROOT / "tests" / "TEST_Material_L3_L4_Closure.f90"
OUT_DIR = ROOT / "docs" / "ElementInventory"

NON_ELEMENT_STEM_SUFFIXES = (
    "ALGOS",
    "API",
    "ASM",
    "BASE",
    "CORE",
    "DEF",
    "DEFN",
    "DEFINITION",
    "DISPATCH",
    "DOMAIN",
    "DOMAINCORE",
    "FORCEASM",
    "FUNCS",
    "GOVERNANCE",
    "HEATTRANSFER",
    "KERNEL",
    "MATERIALROUTE",
    "MASSDISPATCH",
    "MTX",
    "OUTDISPATCH",
    "PARAMS",
    "REG",
    "SHAPE",
    "SHAPES",
    "STIFFNESS",
    "STRESSKERNEL",
    "STRAINKERNEL",
    "UTIL",
    "UTILS",
)

NON_ELEMENT_NAME_FRAGMENTS = (
    "CONT",
    "DYNAMICS",
    "FACADE",
    "MITC",
    "NLGEOM",
    "PLASTICITY",
    "SHAPE",
    "SOLV",
    "STABILITY",
    "SUITE",
)

NON_ELEMENT_EXACT_NAMES = {
    "ACOUSTIC",
    "ACOUSTICTRANSIENT",
    "B31EAS",
    "B31FBAR",
    "B31NL",
    "B31PIPE",
    "B31TL",
    "B31TNL",
    "B31TP",
    "B31TS",
    "B31UL",
    "B32NL",
    "B32P",
    "B32S",
    "B32T",
    "B33NL",
    "B33P",
    "B33S",
    "B33T",
    "BEAM",
    "COHESIVE",
    "ELEMENT",
    "ELEM",
    "GASKET",
    "INFINITE",
    "MASS2",
    "PIPE",
    "RIGID",
    "SHELL",
    "SPRING",
    "THERM",
    "THERMAL",
}


@dataclass
class RegistryRow:
    elem_const: str
    name: str
    n_nodes: str
    n_ip: str
    n_dof: str
    registry_family: str
    base_elem_type: str
    source_line: int


def split_args(arg_text: str) -> list[str]:
    args: list[str] = []
    current: list[str] = []
    in_string = False
    quote = ""
    depth = 0

    for char in arg_text:
        if char in ("'", '"'):
            if in_string and char == quote:
                in_string = False
            elif not in_string:
                in_string = True
                quote = char
        elif not in_string:
            if char == "(":
                depth += 1
            elif char == ")":
                depth = max(0, depth - 1)
            elif char == "," and depth == 0:
                args.append("".join(current).strip())
                current = []
                continue
        current.append(char)

    if current:
        args.append("".join(current).strip())
    return args


def parse_registry() -> list[RegistryRow]:
    rows: list[RegistryRow] = []
    pattern = re.compile(r"CALL\s+PH_Elem_Reg_Add\((.*)\)", re.IGNORECASE)
    pending = ""
    start_line = 0
    for line_no, raw_line in enumerate(REGISTRY_PATH.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.split("!", 1)[0].rstrip()
        if not pending and "PH_Elem_Reg_Add(" not in line:
            continue
        if not pending:
            start_line = line_no
        pending = f"{pending} {line.rstrip('&').strip()}".strip()
        if ")" not in pending:
            continue

        match = pattern.search(pending)
        pending = ""
        if not match:
            continue
        args = split_args(match.group(1))
        if len(args) < 6:
            continue
        base_match = re.search(r"base_elem_type\s*=\s*([A-Za-z0-9_]+)", match.group(1), re.IGNORECASE)
        rows.append(
            RegistryRow(
                elem_const=args[0],
                name=args[1].strip().strip('"').strip("'"),
                n_nodes=args[2],
                n_ip=args[3],
                n_dof=args[4],
                registry_family=args[5],
                base_elem_type=base_match.group(1) if base_match else "",
                source_line=start_line,
            )
        )
    return rows


def normalize_key(value: str) -> str:
    return re.sub(r"[^A-Z0-9]", "", value.upper())


def infer_main_family(name: str) -> str:
    upper = name.upper()
    if upper.startswith("C3D"):
        return "SOLID_3D"
    if upper.startswith(("CPE", "CPS", "CAX", "CPEG")):
        return "SOLID_2D"
    if upper.startswith(("STRI", "SC", "SAX", "S")):
        return "SHELL"
    if upper.startswith(("M3D", "M2D", "MAX")):
        return "MEMBRANE"
    if upper.startswith(("B", "PIPE")):
        return "BEAM"
    if upper.startswith("T"):
        return "TRUSS"
    if upper.startswith("COH"):
        return "COHESIVE"
    if upper.startswith(("CIN", "INF", "INFINITE")):
        return "INFINITE"
    if upper.startswith("AC"):
        return "ACOUSTIC"
    if upper.startswith(("GK", "GASKET")):
        return "GASKET"
    if upper.startswith(("CONN", "SPRING", "DASHPOT")):
        return "CONNECTOR"
    if upper.startswith("MASS") or upper == "ROTARYI" or upper.startswith("R"):
        return "MASS_INERTIA_RIGID"
    if upper.startswith(("DC", "DS")):
        return "THERMAL"
    if upper.startswith("P"):
        return "POROUS"
    return "OTHER"


def iter_f90_files() -> Iterable[Path]:
    return ELEMENT_ROOT.rglob("*.f90")


def collect_module_keys() -> set[str]:
    keys: set[str] = set()
    for path in iter_f90_files():
        stem = path.stem
        if stem.startswith("PH_Elem_"):
            name = stem.removeprefix("PH_Elem_")
            if is_element_candidate_name(name):
                keys.add(normalize_key(name))
    return keys


def is_element_candidate_name(name: str) -> bool:
    upper = normalize_key(name)
    if not upper:
        return False
    if upper in NON_ELEMENT_EXACT_NAMES:
        return False
    if any(fragment in upper for fragment in NON_ELEMENT_NAME_FRAGMENTS):
        return False
    if any(upper.endswith(suffix) for suffix in NON_ELEMENT_STEM_SUFFIXES):
        return False
    if upper in {"CONTM", "POROUS"}:
        return False
    return bool(
        re.match(
            r"^(C3D|CPE|CPS|CAX|CPEG|S|SC|SAX|STRI|M3D|M2D|MAX|B|T[23]D|"
            r"PIPE|DC|DS|AC|ACAX|COH|GK|GASKET|R[23A]|CONN|SPRING|DASHPOT|"
            r"MASS|ROTARYI|P[23]D|CIN|INF|INFINITE)",
            upper,
        )
    )


def collect_l3_mesh_candidates() -> dict[str, set[str]]:
    candidates: dict[str, set[str]] = {}
    if not L3_MESH_PATH.exists():
        return candidates
    pattern = re.compile(r"\bMD_MESH_ELEM_([A-Z0-9]+)\s*=", re.IGNORECASE)
    for line in L3_MESH_PATH.read_text(encoding="utf-8", errors="ignore").splitlines():
        match = pattern.search(line)
        if not match:
            continue
        name = match.group(1).upper()
        if name == "USER":
            continue
        if is_element_candidate_name(name):
            candidates.setdefault(name, set()).add("L3_MD_Mesh_constant")
    return candidates


def collect_l4_file_candidates() -> dict[str, set[str]]:
    candidates: dict[str, set[str]] = {}
    for path in iter_f90_files():
        stem = path.stem
        if not stem.startswith("PH_Elem_"):
            continue
        name = stem.removeprefix("PH_Elem_")
        if is_element_candidate_name(name):
            candidates.setdefault(normalize_key(name), set()).add("L4_Element_file")
    return candidates


def collect_route_wrapper_candidates(exact_route_keys: set[str]) -> dict[str, set[str]]:
    candidates: dict[str, set[str]] = {}
    for name in exact_route_keys:
        if is_element_candidate_name(name):
            candidates.setdefault(name, set()).add("route_wrapper")
    return candidates


def collect_discovered_candidates(
    registered_names: set[str],
    exact_route_keys: set[str],
) -> list[tuple[str, str]]:
    discovered: dict[str, set[str]] = {}
    for source in (collect_l3_mesh_candidates(), collect_l4_file_candidates(), collect_route_wrapper_candidates(exact_route_keys)):
        for name, sources in source.items():
            discovered.setdefault(name, set()).update(sources)

    rows: list[tuple[str, str]] = []
    for name in sorted(discovered):
        if normalize_key(name) in registered_names:
            continue
        rows.append((name, "+".join(sorted(discovered[name]))))
    return rows


def collect_route_wrappers() -> tuple[set[str], set[str]]:
    exact_keys: set[str] = set()
    family_keys: set[str] = set()
    pattern = re.compile(
        r"\b(?:PUBLIC\s*::\s*)?(PH_Elem_[A-Za-z0-9_]*Material_Update[A-Za-z0-9_]*Routed)\b",
        re.IGNORECASE,
    )
    for path in iter_f90_files():
        text = path.read_text(encoding="utf-8", errors="ignore")
        for wrapper in pattern.findall(text):
            element_part = wrapper.removeprefix("PH_Elem_").split("_Material", 1)[0]
            key = normalize_key(element_part)
            if key in {"BEAM", "ACOUSTIC", "COHESIVE", "GASKET", "INFINITE", "POROUS", "MASS"}:
                family_keys.add(key)
            else:
                exact_keys.add(key)
    return exact_keys, family_keys


def collect_tested_route_keys() -> set[str]:
    if not TEST_PATH.exists():
        return set()
    text = TEST_PATH.read_text(encoding="utf-8", errors="ignore")
    keys: set[str] = set()
    pattern = re.compile(r"\bPH_Elem_([A-Za-z0-9_]+)_Material_Update[A-Za-z0-9_]*Routed\b")
    for element_part in pattern.findall(text):
        keys.add(normalize_key(element_part))
    return keys


def classify_route(
    row: RegistryRow,
    exact_route_keys: set[str],
    family_route_keys: set[str],
    tested_keys: set[str],
) -> tuple[str, str]:
    name = row.name.upper()
    key = normalize_key(name)
    main_family = infer_main_family(name)

    if name.startswith("R") or name in {"ROTARYI", "CONN2D2", "CONN3D2"}:
        return "NON_MATERIAL", "constraint/inertia/connector metadata path"
    if key in exact_route_keys:
        return "ROUTED_PER_ELEMENT", "exact routed wrapper found"
    if key in tested_keys:
        return "ROUTED_PER_ELEMENT", "exact routed wrapper exercised in closure test"
    if row.base_elem_type:
        return "FAMILY_ROUTE", f"alias/base route via {row.base_elem_type}"
    if main_family == "BEAM" and "BEAM" in family_route_keys:
        return "FAMILY_ROUTE", "beam family E/nu wrapper"
    if main_family == "ACOUSTIC" and "ACOUSTIC" in family_route_keys:
        return "FAMILY_ROUTE", "acoustic fluid family wrapper"
    if main_family == "COHESIVE" and "COHESIVE" in family_route_keys:
        return "FAMILY_ROUTE", "cohesive interface family wrapper"
    if main_family == "GASKET" and "GASKET" in family_route_keys:
        return "FAMILY_ROUTE", "gasket interface family wrapper"
    if main_family == "INFINITE" and "INFINITE" in family_route_keys:
        return "FAMILY_ROUTE", "infinite decay family wrapper"
    if main_family == "POROUS" and "POROUS" in family_route_keys:
        return "FAMILY_ROUTE", "porous two-phase family wrapper"
    if name == "MASS" and "MASS" in family_route_keys:
        return "ROUTED_PER_ELEMENT", "mass scalar wrapper"
    if main_family in {"SOLID_3D", "SOLID_2D", "SHELL", "MEMBRANE", "TRUSS"}:
        return "PARTIAL", "family helper exists, row-level routed wrapper not proven"
    if main_family == "THERMAL":
        return "FAMILY_ROUTE", "thermal transfer topology accepted via scalar conductivity family route"
    if main_family == "CONNECTOR":
        return "NOT_ROUTED", "connector scalar route not proven for this row"
    return "NOT_ROUTED", "no routed wrapper detected"


def classify_candidate_route(
    name: str,
    exact_route_keys: set[str],
    family_route_keys: set[str],
    tested_keys: set[str],
) -> tuple[str, str]:
    upper = name.upper()
    key = normalize_key(name)
    main_family = infer_main_family(name)

    if upper.startswith("R") or upper in {"ROTARYI", "CONN2D2", "CONN3D2"}:
        return "NON_MATERIAL", "unregistered candidate on metadata path"
    if key in exact_route_keys:
        return "ROUTED_PER_ELEMENT", "exact routed wrapper exists but registry row is missing"
    if key in tested_keys:
        return "ROUTED_PER_ELEMENT", "closure test references wrapper but registry row is missing"
    if main_family == "BEAM" and "BEAM" in family_route_keys:
        return "FAMILY_ROUTE", "beam family wrapper exists; registry row is missing"
    if main_family == "ACOUSTIC" and "ACOUSTIC" in family_route_keys:
        return "FAMILY_ROUTE", "acoustic family wrapper exists; registry row is missing"
    if main_family == "COHESIVE" and "COHESIVE" in family_route_keys:
        return "FAMILY_ROUTE", "cohesive family wrapper exists; registry row is missing"
    if main_family == "GASKET" and "GASKET" in family_route_keys:
        return "FAMILY_ROUTE", "gasket family wrapper exists; registry row is missing"
    if main_family == "INFINITE" and "INFINITE" in family_route_keys:
        return "FAMILY_ROUTE", "infinite family wrapper exists; registry row is missing"
    if main_family == "POROUS" and "POROUS" in family_route_keys:
        return "FAMILY_ROUTE", "porous family wrapper exists; registry row is missing"
    if main_family in {"SOLID_3D", "SOLID_2D", "SHELL", "MEMBRANE", "TRUSS"}:
        return "PARTIAL", "family helper likely exists; registry row is missing"
    return "NOT_ROUTED", "unregistered candidate lacks routed wrapper evidence"


def registry_action_for_registered(row: RegistryRow) -> str:
    if row.base_elem_type:
        return "KEEP_ALIAS_TO_BASE"
    return "KEEP_REGISTERED"


def registry_action_for_candidate(route_status: str) -> str:
    if route_status == "ROUTED_PER_ELEMENT":
        return "ADD_REGISTRY_ROW"
    if route_status in {"FAMILY_ROUTE", "PARTIAL"}:
        return "REVIEW_ADD_OR_ALIAS"
    if route_status == "NON_MATERIAL":
        return "REVIEW_NON_MATERIAL"
    return "REVIEW_DEFER_OR_NON_UFC_SCOPE"


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def build_rows() -> tuple[list[dict[str, object]], list[dict[str, object]], Counter]:
    registry_rows = parse_registry()
    module_keys = collect_module_keys()
    exact_route_keys, family_route_keys = collect_route_wrappers()
    tested_keys = collect_tested_route_keys()
    registered_names = {normalize_key(row.name) for row in registry_rows}
    discovered_candidates = collect_discovered_candidates(registered_names, exact_route_keys)

    target_rows: list[dict[str, object]] = []
    crosswalk_rows: list[dict[str, object]] = []

    for idx, row in enumerate(registry_rows, start=1):
        key = normalize_key(row.name)
        main_family = infer_main_family(row.name)
        route_status, route_note = classify_route(row, exact_route_keys, family_route_keys, tested_keys)
        has_module = key in module_keys or main_family in {"BEAM", "ACOUSTIC", "COHESIVE", "GASKET", "POROUS", "INFINITE"}
        has_route_wrapper = route_status in {"ROUTED_PER_ELEMENT", "FAMILY_ROUTE", "PARTIAL"}
        has_structured_hot_path = row.name.upper() in {"CPE4", "CPS4", "C3D8"}
        has_test = key in tested_keys
        has_family_test = route_status == "FAMILY_ROUTE"

        record = {
            "target_index": idx,
            "target_name": row.name,
            "target_source": "current_L4_registry",
            "target_resolution": "KNOWN_REGISTERED",
            "discovery_sources": "",
            "main_family": main_family,
            "variant_kind": infer_variant_kind(row.name),
            "registry_status": "REGISTERED",
            "registry_action": registry_action_for_registered(row),
            "registry_name": row.name,
            "elem_const": row.elem_const,
            "registry_family": row.registry_family,
            "n_nodes": row.n_nodes,
            "n_ip": row.n_ip,
            "n_dof": row.n_dof,
            "base_elem_type": row.base_elem_type,
            "has_module": bool_text(has_module),
            "route_status": route_status,
            "route_note": route_note,
            "has_route_wrapper": bool_text(has_route_wrapper),
            "has_structured_hot_path": bool_text(has_structured_hot_path),
            "has_test": bool_text(has_test),
            "has_family_test": bool_text(has_family_test),
            "source_line": row.source_line,
        }
        target_rows.append(record)
        crosswalk_rows.append(record)

    next_index = len(registry_rows) + 1
    max_discovered = max(0, TARGET_COUNT - len(registry_rows))
    for name, sources in discovered_candidates[:max_discovered]:
        key = normalize_key(name)
        main_family = infer_main_family(name)
        route_status, route_note = classify_candidate_route(name, exact_route_keys, family_route_keys, tested_keys)
        has_module = "L4_Element_file" in sources
        has_route_wrapper = route_status in {"ROUTED_PER_ELEMENT", "FAMILY_ROUTE", "PARTIAL"}
        has_test = key in tested_keys
        record = {
            "target_index": next_index,
            "target_name": name,
            "target_source": "repo_discovered_candidate",
            "target_resolution": "DISCOVERED_UNREGISTERED_CANDIDATE",
            "discovery_sources": sources,
            "main_family": main_family,
            "variant_kind": infer_variant_kind(name),
            "registry_status": "UNREGISTERED_DISCOVERED",
            "registry_action": registry_action_for_candidate(route_status),
            "registry_name": "",
            "elem_const": "",
            "registry_family": "",
            "n_nodes": "",
            "n_ip": "",
            "n_dof": "",
            "base_elem_type": "",
            "has_module": bool_text(has_module),
            "route_status": route_status,
            "route_note": route_note,
            "has_route_wrapper": bool_text(has_route_wrapper),
            "has_structured_hot_path": "NO",
            "has_test": bool_text(has_test),
            "has_family_test": bool_text(route_status == "FAMILY_ROUTE"),
            "source_line": "",
        }
        target_rows.append(record)
        crosswalk_rows.append(record)
        next_index += 1

    for idx in range(next_index, TARGET_COUNT + 1):
        name = f"UNRESOLVED_TARGET_SLOT_{idx:03d}"
        record = {
            "target_index": idx,
            "target_name": name,
            "target_source": "PPLAN_aggregate_gap",
            "target_resolution": "UNRESOLVED_TARGET_SLOT",
            "discovery_sources": "",
            "main_family": "UNRESOLVED",
            "variant_kind": "UNRESOLVED",
            "registry_status": "UNREGISTERED_TARGET_GAP",
            "registry_action": "IMPORT_AUTHORITATIVE_TARGET_NAME",
            "registry_name": "",
            "elem_const": "",
            "registry_family": "",
            "n_nodes": "",
            "n_ip": "",
            "n_dof": "",
            "base_elem_type": "",
            "has_module": "NO",
            "route_status": "UNREGISTERED_TARGET_GAP",
            "route_note": "377 target slot has no authoritative element name in current repo",
            "has_route_wrapper": "NO",
            "has_structured_hot_path": "NO",
            "has_test": "NO",
            "has_family_test": "NO",
            "source_line": "",
        }
        target_rows.append(record)
        crosswalk_rows.append(record)

    summary = Counter(str(row["route_status"]) for row in crosswalk_rows)
    summary["REGISTERED_ROWS"] = len(registry_rows)
    summary["DISCOVERED_UNREGISTERED_ROWS"] = sum(
        1 for row in crosswalk_rows if row["registry_status"] == "UNREGISTERED_DISCOVERED"
    )
    summary["TARGET_ROWS"] = TARGET_COUNT
    summary["UNRESOLVED_TARGET_SLOTS"] = sum(
        1 for row in crosswalk_rows if row["registry_status"] == "UNREGISTERED_TARGET_GAP"
    )
    return target_rows, crosswalk_rows, summary


def infer_variant_kind(name: str) -> str:
    upper = name.upper()
    if upper.startswith("R") or upper in {"ROTARYI", "CONN2D2", "CONN3D2"}:
        return "NON_MATERIAL"
    if re.match(r"^B[0-9]+T", upper):
        return "THERMO_MECHANICAL"
    if upper.startswith("B") and upper.endswith(("NL", "P", "S")):
        return "BEAM_SPECIAL_VARIANT"
    if upper.endswith("P") or "SAT" in upper or "RCH" in upper:
        return "POROUS_OR_PORE_PRESSURE"
    if upper.endswith(("R", "R5", "RS")):
        return "REDUCED_OR_SPECIAL_INTEGRATION"
    if upper.endswith("H"):
        return "HYBRID"
    if upper.endswith("I"):
        return "INCOMPATIBLE_MODE"
    if upper.endswith("T"):
        return "THERMO_MECHANICAL"
    if upper.startswith(("AC", "COH", "GK")):
        return "SPECIAL_PHYSICS"
    return "BASE"


def bool_text(value: bool) -> str:
    return "YES" if value else "NO"


def write_summary(path: Path, summary: Counter, crosswalk_rows: list[dict[str, object]]) -> None:
    family_counts = Counter(str(row["main_family"]) for row in crosswalk_rows)
    route_counts = Counter(str(row["route_status"]) for row in crosswalk_rows)

    lines = [
        "# Element Inventory Audit Summary",
        "",
        "Generated by `tools/element_inventory_audit.py`.",
        "",
        "## Counts",
        "",
        "| Metric | Count |",
        "|--------|------:|",
        f"| Target accounting rows | {summary['TARGET_ROWS']} |",
        f"| Current registered rows | {summary['REGISTERED_ROWS']} |",
        f"| Repo-discovered unregistered candidates | {summary['DISCOVERED_UNREGISTERED_ROWS']} |",
        f"| Unresolved target slots | {summary['UNRESOLVED_TARGET_SLOTS']} |",
        "",
        "## Route Status",
        "",
        "| Route status | Count |",
        "|--------------|------:|",
    ]
    for status, count in sorted(route_counts.items()):
        lines.append(f"| `{status}` | {count} |")

    lines.extend(["", "## Main Family", "", "| Main family | Count |", "|-------------|------:|"])
    for family, count in sorted(family_counts.items()):
        lines.append(f"| `{family}` | {count} |")

    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- `UNRESOLVED_TARGET_SLOT_*` rows are accounting placeholders, not invented element names.",
            "- `DISCOVERED_UNREGISTERED_CANDIDATE` rows come from L3 mesh constants or L4 element filenames and need registry acceptance/rejection.",
            "- Replace unresolved rows only after an authoritative 377-item source is imported.",
            "- `FAMILY_ROUTE` means a helper/wrapper exists at family level; it is not the same as a fully audited per-element hot path.",
            "- `NON_MATERIAL` is a valid closure state for rigid, inertia, and connector metadata paths.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def write_backlog(path: Path, crosswalk_rows: list[dict[str, object]]) -> None:
    discovered = [row for row in crosswalk_rows if row["registry_status"] == "UNREGISTERED_DISCOVERED"]
    not_routed = [
        row
        for row in crosswalk_rows
        if row["registry_status"] == "REGISTERED" and row["route_status"] == "NOT_ROUTED"
    ]
    partial = [
        row
        for row in crosswalk_rows
        if row["registry_status"] == "REGISTERED" and row["route_status"] == "PARTIAL"
    ]

    lines = [
        "# Element Registry Backlog",
        "",
        "Generated by `tools/element_inventory_audit.py`.",
        "",
        "## Discovered Unregistered Candidates",
        "",
        "| Candidate | Family | Route status | Registry action | Sources | Note |",
        "|-----------|--------|--------------|-----------------|---------|------|",
    ]
    for row in discovered:
        lines.append(
            f"| `{row['target_name']}` | `{row['main_family']}` | `{row['route_status']}` | "
            f"`{row['registry_action']}` | `{row['discovery_sources']}` | {row['route_note']} |"
        )

    lines.extend(
        [
            "",
            "## Registered But Not Routed",
            "",
            "| Element | Family | Registry action | Note |",
            "|---------|--------|-----------------|------|",
        ]
    )
    for row in not_routed:
        lines.append(
            f"| `{row['target_name']}` | `{row['main_family']}` | `{row['registry_action']}` | {row['route_note']} |"
        )

    lines.extend(
        [
            "",
            "## Registered Partial Route",
            "",
            "| Element | Family | Registry action | Note |",
            "|---------|--------|-----------------|------|",
        ]
    )
    for row in partial:
        lines.append(
            f"| `{row['target_name']}` | `{row['main_family']}` | `{row['registry_action']}` | {row['route_note']} |"
        )

    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    target_rows, crosswalk_rows, summary = build_rows()
    fields = list(crosswalk_rows[0].keys())

    write_csv(OUT_DIR / "element_target_377.csv", target_rows, fields)
    write_csv(OUT_DIR / "element_registry_route_crosswalk.csv", crosswalk_rows, fields)
    write_summary(OUT_DIR / "element_inventory_summary.md", summary, crosswalk_rows)
    write_backlog(OUT_DIR / "element_registry_backlog.md", crosswalk_rows)

    print(f"wrote {OUT_DIR / 'element_target_377.csv'}")
    print(f"wrote {OUT_DIR / 'element_registry_route_crosswalk.csv'}")
    print(f"wrote {OUT_DIR / 'element_inventory_summary.md'}")
    print(f"wrote {OUT_DIR / 'element_registry_backlog.md'}")
    print(f"registered={summary['REGISTERED_ROWS']} target={summary['TARGET_ROWS']} unresolved={summary['UNRESOLVED_TARGET_SLOTS']}")


if __name__ == "__main__":
    main()
