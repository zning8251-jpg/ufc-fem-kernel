#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC 目录 vs 矩阵审计工具
对比 ufc_core/ 物理目录与 UFC_全层全域权威清单矩阵.md 中的登记信息。
输出：域/子域差异、f90 计数偏差、CONTRACT.md 覆盖状态。
"""
import os
import sys
import glob
from collections import defaultdict

UFC_CORE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ufc_core")

MATRIX_DOMAINS = {
    "L1_IF": {
        "Base":      {"subdomains": ["AI", "Parallel", "Symbol"], "f90_declared": 25},
        "Error":     {"subdomains": [],                           "f90_declared": 5},
        "IO":        {"subdomains": ["Checkpoint"],               "f90_declared": 13},
        "Log":       {"subdomains": [],                           "f90_declared": 3},
        "Memory":    {"subdomains": [],                           "f90_declared": 8},
        "Monitor":   {"subdomains": [],                           "f90_declared": 4},
        "Precision": {"subdomains": [],                           "f90_declared": 2},
        "Registry":  {"subdomains": [],                           "f90_declared": 3},
    },
    "L2_NM": {
        "Base":         {"subdomains": ["BVH"],                                          "f90_declared": 13},
        "Bridge":       {"subdomains": [],                                               "f90_declared": 5},
        "ExternalLibs": {"subdomains": [],                                               "f90_declared": 10},
        "Matrix":       {"subdomains": [],                                               "f90_declared": 12},
        "Solver":       {"subdomains": ["AI","Conv","Coupling","LinSolv","NonlinSolv","Parallel"], "f90_declared": 53},
        "TimeInt":      {"subdomains": [],                                               "f90_declared": 12},
    },
    "L3_MD": {
        "Analysis":    {"subdomains": ["Amplitude","Solver","Step"], "f90_declared": 11},
        "Assembly":    {"subdomains": [],                           "f90_declared": 4},
        "Boundary":    {"subdomains": [],                           "f90_declared": 6},
        "Bridge":      {"subdomains": ["Bridge_L4","Bridge_L5"],    "f90_declared": 19},
        "Constraint":  {"subdomains": [],                           "f90_declared": 6},
        "Field":       {"subdomains": [],                           "f90_declared": 1},
        "Interaction": {"subdomains": [],                           "f90_declared": 15},
        "KeyWord":     {"subdomains": [],                           "f90_declared": 16},
        "Material":    {"subdomains": ["Acoustic","Base","Bridge","Composite","Concrete","Contract",
                                       "Creep","Damage","Dispatch","Domain","Elas","Foam","Geo",
                                       "HyperElas","Plast","Registry","Shared","Thermal","User","Viscoelas"],
                        "f90_declared": 198},
        "Mesh":        {"subdomains": ["Element"],                  "f90_declared": 35},
        "Model":       {"subdomains": [],                           "f90_declared": 21},
        "Output":      {"subdomains": [],                           "f90_declared": 19},
        "Part":        {"subdomains": [],                           "f90_declared": 6},
        "Section":     {"subdomains": [],                           "f90_declared": 9},
        "WriteBack":   {"subdomains": [],                           "f90_declared": 4},
    },
    "L4_PH": {
        "Bridge":     {"subdomains": ["Output","WriteBack"],                                                  "f90_declared": 8},
        "Constraint": {"subdomains": [],                                                                      "f90_declared": 11},
        "Contact":    {"subdomains": ["AI","Core","Domain","Explicit","Friction","Search","Self","Thermal","Types","Wear"], "f90_declared": 18},
        "Element":    {"subdomains": ["Acoustic","Beam","Cohesive","Dashpot","Gasket","Infinite","Mass",
                                      "Membrane","Pipe","Porous","Shared","Shell","Solid2D","Solid2Dt",
                                      "Solid3D","Solid3Dt","Special","Spring","Surface","Thermal","Truss","User"],
                       "f90_declared": 201},
        "Field":      {"subdomains": [],                                                                      "f90_declared": 8},
        "LoadBC":     {"subdomains": [],                                                                      "f90_declared": 9},
        "Material":   {"subdomains": ["Acoustic","Base","Bridge","Composite","Contract","Creep","Damage",
                                      "Dispatch","Domain","Elas","Geo","HyperElas","Plast","Registry",
                                      "Shared","Thermal","User","Viscoelas"],
                       "f90_declared": 30},
    },
    "L5_RT": {
        "Assembly":   {"subdomains": [],         "f90_declared": 18},
        "Bridge":     {"subdomains": ["Shared"], "f90_declared": 3},
        "Contact":    {"subdomains": [],         "f90_declared": 7},
        "Element":    {"subdomains": ["Mesh"],   "f90_declared": 14},
        "LoadBC":     {"subdomains": [],         "f90_declared": 4},
        "Logging":    {"subdomains": [],         "f90_declared": 1},
        "Material":   {"subdomains": [],         "f90_declared": 0},
        "Output":     {"subdomains": [],         "f90_declared": 7},
        "Solver":     {"subdomains": ["Coupling"], "f90_declared": 17},
        "StepDriver": {"subdomains": [],         "f90_declared": 7},
        "WriteBack":  {"subdomains": [],         "f90_declared": 4},
    },
    "L6_AP": {
        "Bridge":   {"subdomains": [],                           "f90_declared": 4},
        "Config":   {"subdomains": [],                           "f90_declared": 2},
        "Input":    {"subdomains": ["Command","Parser","Script"],"f90_declared": 35},
        "Job":      {"subdomains": [],                           "f90_declared": 4},
        "Output":   {"subdomains": [],                           "f90_declared": 6},
        "Registry": {"subdomains": [],                           "f90_declared": 1},
        "Solver":   {"subdomains": [],                           "f90_declared": 1},
        "UI":       {"subdomains": [],                           "f90_declared": 7},
    },
}

SKIP_DIRS = {"contracts", "Tests", "tests", "__pycache__", ".git"}


def get_physical_domains(ufc_core_path):
    """Scan ufc_core directory and return {layer: {domain: {subdomains: [...], f90_count: N, has_contract: bool}}}"""
    result = {}
    for layer in sorted(os.listdir(ufc_core_path)):
        layer_path = os.path.join(ufc_core_path, layer)
        if not os.path.isdir(layer_path) or not layer.startswith("L"):
            continue
        result[layer] = {}
        for domain in sorted(os.listdir(layer_path)):
            domain_path = os.path.join(layer_path, domain)
            if not os.path.isdir(domain_path) or domain in SKIP_DIRS:
                continue
            f90_files = glob.glob(os.path.join(domain_path, "**", "*.f90"), recursive=True)
            has_contract = os.path.exists(os.path.join(domain_path, "CONTRACT.md"))
            subdirs = []
            for item in sorted(os.listdir(domain_path)):
                item_path = os.path.join(domain_path, item)
                if os.path.isdir(item_path) and item not in SKIP_DIRS and not item.startswith("."):
                    subdirs.append(item)
            result[layer][domain] = {
                "subdomains": subdirs,
                "f90_count": len(f90_files),
                "has_contract": has_contract,
            }
    return result


def audit(ufc_core_path):
    physical = get_physical_domains(ufc_core_path)
    issues = []
    stats = {"layers": 0, "domains_physical": 0, "domains_matrix": 0,
             "f90_match": 0, "f90_mismatch": 0, "contract_missing": 0}

    all_layers = sorted(set(list(MATRIX_DOMAINS.keys()) + list(physical.keys())))
    for layer in all_layers:
        stats["layers"] += 1
        m_domains = MATRIX_DOMAINS.get(layer, {})
        p_domains = physical.get(layer, {})

        if layer not in MATRIX_DOMAINS:
            issues.append(f"[DIR_ONLY]  Layer {layer} exists on disk but NOT in matrix")
            continue
        if layer not in physical:
            issues.append(f"[MATRIX_ONLY]  Layer {layer} in matrix but NOT on disk")
            continue

        all_domains = sorted(set(list(m_domains.keys()) + list(p_domains.keys())))
        for domain in all_domains:
            if domain in p_domains:
                stats["domains_physical"] += 1
            if domain in m_domains:
                stats["domains_matrix"] += 1

            if domain not in m_domains:
                issues.append(f"[DIR_ONLY]  {layer}/{domain} exists on disk but NOT in matrix (f90={p_domains[domain]['f90_count']})")
                continue
            if domain not in p_domains:
                issues.append(f"[MATRIX_ONLY]  {layer}/{domain} in matrix but NOT on disk")
                continue

            p = p_domains[domain]
            m = m_domains[domain]

            if not p["has_contract"]:
                issues.append(f"[NO_CONTRACT]  {layer}/{domain} — CONTRACT.md missing")
                stats["contract_missing"] += 1

            declared = m["f90_declared"]
            actual = p["f90_count"]
            if declared != actual:
                delta = actual - declared
                sign = f"+{delta}" if delta > 0 else str(delta)
                issues.append(f"[F90_COUNT]  {layer}/{domain} — matrix={declared}, actual={actual} ({sign})")
                stats["f90_mismatch"] += 1
            else:
                stats["f90_match"] += 1

            m_subs = set(m["subdomains"])
            p_subs = set(p["subdomains"])
            for s in sorted(p_subs - m_subs):
                issues.append(f"[SUBDIR_ONLY]  {layer}/{domain}/{s} — exists on disk but NOT listed in matrix")
            for s in sorted(m_subs - p_subs):
                issues.append(f"[MATRIX_SUB_ONLY]  {layer}/{domain}/{s} — in matrix but NOT on disk")

    return issues, stats


def main():
    path = UFC_CORE
    if not os.path.isdir(path):
        print(f"ERROR: {path} not found")
        sys.exit(1)

    issues, stats = audit(path)

    print("=" * 72)
    print("UFC 目录 vs 矩阵审计报告")
    print("=" * 72)
    print(f"\n层数: {stats['layers']}")
    print(f"物理域数: {stats['domains_physical']}")
    print(f"矩阵域数: {stats['domains_matrix']}")
    print(f"f90 计数匹配: {stats['f90_match']}")
    print(f"f90 计数偏差: {stats['f90_mismatch']}")
    print(f"缺少 CONTRACT.md: {stats['contract_missing']}")
    print(f"\n共发现 {len(issues)} 个差异项:")
    print("-" * 72)

    categories = defaultdict(list)
    for issue in issues:
        tag = issue.split("]")[0] + "]"
        categories[tag].append(issue)

    for tag in sorted(categories.keys()):
        print(f"\n### {tag} ({len(categories[tag])} 项)")
        for item in categories[tag]:
            print(f"  {item}")

    print("\n" + "=" * 72)
    if not issues:
        print("PASS: 目录与矩阵完全对齐")
    else:
        print(f"AUDIT COMPLETE: {len(issues)} issues found")
    print("=" * 72)


if __name__ == "__main__":
    main()
