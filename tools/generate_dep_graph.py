#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC Module USE Dependency Graph Generator
Scans all .f90 files for USE statements and generates:
1. A DOT-format dependency graph
2. A cycle detection report
3. Layer violation report (lower layer using upper layer)
"""
import os
import re
import sys
import glob
from collections import defaultdict

UFC_CORE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ufc_core")

MODULE_RE = re.compile(r'^\s*MODULE\s+(\w+)\s*$', re.IGNORECASE)
USE_RE = re.compile(r'^\s*USE\s+(\w+)', re.IGNORECASE)
END_MODULE_RE = re.compile(r'^\s*END\s+MODULE', re.IGNORECASE)

LAYER_ORDER = {"L1_IF": 1, "L2_NM": 2, "L3_MD": 3, "L4_PH": 4, "L5_RT": 5, "L6_AP": 6}
LAYER_COLORS = {
    "L1_IF": "#E8F5E9",
    "L2_NM": "#E3F2FD",
    "L3_MD": "#FFF3E0",
    "L4_PH": "#FCE4EC",
    "L5_RT": "#F3E5F5",
    "L6_AP": "#E0F7FA",
}


def scan_dependencies(ufc_core):
    """Scan all f90 files and return (module_to_file, module_to_layer, dependencies)."""
    module_to_file = {}
    module_to_layer = {}
    dependencies = defaultdict(set)

    for layer in sorted(os.listdir(ufc_core)):
        layer_path = os.path.join(ufc_core, layer)
        if not os.path.isdir(layer_path) or not layer.startswith("L"):
            continue

        for fpath in glob.glob(os.path.join(layer_path, "**", "*.f90"), recursive=True):
            try:
                with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
                    lines = f.readlines()
            except Exception:
                continue

            current_module = None
            for line in lines:
                stripped = line.strip()
                if stripped.startswith('!'):
                    continue

                m = MODULE_RE.match(stripped)
                if m:
                    current_module = m.group(1)
                    rel = os.path.relpath(fpath, ufc_core).replace("\\", "/")
                    module_to_file[current_module.lower()] = rel
                    module_to_layer[current_module.lower()] = layer
                    continue

                if END_MODULE_RE.match(stripped):
                    current_module = None
                    continue

                m = USE_RE.match(stripped)
                if m and current_module:
                    used_mod = m.group(1).lower()
                    if used_mod != current_module.lower():
                        dependencies[current_module.lower()].add(used_mod)

    return module_to_file, module_to_layer, dependencies


def detect_cycles(dependencies):
    """Detect cycles using DFS."""
    WHITE, GRAY, BLACK = 0, 1, 2
    color = defaultdict(lambda: WHITE)
    cycles = []

    def dfs(node, path):
        color[node] = GRAY
        for dep in dependencies.get(node, set()):
            if dep not in dependencies and dep not in color:
                continue
            if color[dep] == GRAY:
                cycle_start = path.index(dep) if dep in path else -1
                if cycle_start >= 0:
                    cycles.append(path[cycle_start:] + [dep])
            elif color[dep] == WHITE:
                dfs(dep, path + [dep])
        color[node] = BLACK

    for node in dependencies:
        if color[node] == WHITE:
            dfs(node, [node])

    return cycles


def detect_layer_violations(dependencies, module_to_layer):
    """Find cases where a lower layer USEs a higher layer module."""
    violations = []
    for mod, deps in dependencies.items():
        src_layer = module_to_layer.get(mod, "")
        src_order = LAYER_ORDER.get(src_layer, 0)
        for dep in deps:
            dep_layer = module_to_layer.get(dep, "")
            dep_order = LAYER_ORDER.get(dep_layer, 0)
            if src_order > 0 and dep_order > 0 and dep_order > src_order:
                violations.append({
                    "source": mod,
                    "source_layer": src_layer,
                    "target": dep,
                    "target_layer": dep_layer,
                })
    return violations


def generate_dot(dependencies, module_to_layer, output_path):
    """Generate a DOT file for visualization."""
    layer_modules = defaultdict(list)
    for mod, layer in module_to_layer.items():
        layer_modules[layer].append(mod)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('digraph UFC_Dependencies {\n')
        f.write('  rankdir=TB;\n')
        f.write('  node [shape=box, fontsize=8, fontname="Consolas"];\n')
        f.write('  edge [arrowsize=0.5];\n\n')

        for layer in sorted(LAYER_ORDER.keys()):
            mods = layer_modules.get(layer, [])
            if not mods:
                continue
            color = LAYER_COLORS.get(layer, "#FFFFFF")
            f.write(f'  subgraph cluster_{layer} {{\n')
            f.write(f'    label="{layer}";\n')
            f.write(f'    style=filled;\n')
            f.write(f'    fillcolor="{color}";\n')
            for mod in sorted(mods)[:50]:
                f.write(f'    "{mod}";\n')
            if len(mods) > 50:
                f.write(f'    "...{len(mods)-50}_more_{layer}" [style=dashed];\n')
            f.write('  }\n\n')

        edge_count = 0
        for src, deps in dependencies.items():
            if src not in module_to_layer:
                continue
            for dep in deps:
                if dep not in module_to_layer:
                    continue
                src_layer = module_to_layer[src]
                dep_layer = module_to_layer[dep]
                color = "red" if LAYER_ORDER.get(dep_layer, 0) > LAYER_ORDER.get(src_layer, 0) else "gray"
                f.write(f'  "{src}" -> "{dep}" [color={color}];\n')
                edge_count += 1

        f.write('}\n')

    return edge_count


def main():
    print("=" * 72)
    print("UFC Module USE Dependency Analysis")
    print("=" * 72)

    module_to_file, module_to_layer, dependencies = scan_dependencies(UFC_CORE)

    print(f"\nModules found: {len(module_to_file)}")
    print(f"Dependencies: {sum(len(v) for v in dependencies.values())}")

    per_layer = defaultdict(int)
    for mod, layer in module_to_layer.items():
        per_layer[layer] += 1
    for layer in sorted(LAYER_ORDER.keys()):
        print(f"  {layer}: {per_layer.get(layer, 0)} modules")

    print("\n--- Cycle Detection ---")
    cycles = detect_cycles(dependencies)
    if cycles:
        print(f"Found {len(cycles)} potential cycles:")
        for i, cycle in enumerate(cycles[:20]):
            print(f"  C{i+1}: {' → '.join(cycle)}")
    else:
        print("No cycles detected.")

    print("\n--- Layer Violation Detection ---")
    violations = detect_layer_violations(dependencies, module_to_layer)
    if violations:
        print(f"Found {len(violations)} layer violations (lower layer USE upper):")
        for v in violations[:30]:
            print(f"  {v['source']} ({v['source_layer']}) → {v['target']} ({v['target_layer']})")
    else:
        print("No layer violations detected.")

    dot_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           "docs", "PPLAN", "06_核心架构", "UFC_ModuleDependencyGraph.dot")
    edge_count = generate_dot(dependencies, module_to_layer, dot_path)
    print(f"\n--- DOT Graph ---")
    print(f"Generated: {dot_path}")
    print(f"Edges: {edge_count}")

    # Save report
    report_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                              "REPORTS", "dependency_analysis_report.txt")
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("UFC Module USE Dependency Analysis Report\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"Total modules: {len(module_to_file)}\n")
        f.write(f"Total USE edges: {sum(len(v) for v in dependencies.values())}\n\n")

        f.write("Per-layer module counts:\n")
        for layer in sorted(LAYER_ORDER.keys()):
            f.write(f"  {layer}: {per_layer.get(layer, 0)}\n")

        f.write(f"\nCycles: {len(cycles)}\n")
        for i, cycle in enumerate(cycles):
            f.write(f"  C{i+1}: {' -> '.join(cycle)}\n")

        f.write(f"\nLayer violations: {len(violations)}\n")
        for v in violations:
            src_file = module_to_file.get(v['source'], '?')
            tgt_file = module_to_file.get(v['target'], '?')
            f.write(f"  {v['source']} ({v['source_layer']}, {src_file})\n")
            f.write(f"    -> {v['target']} ({v['target_layer']}, {tgt_file})\n")

        f.write(f"\nTop 20 most-depended-on modules:\n")
        dep_count = defaultdict(int)
        for src, deps in dependencies.items():
            for dep in deps:
                dep_count[dep] += 1
        for mod, count in sorted(dep_count.items(), key=lambda x: -x[1])[:20]:
            layer = module_to_layer.get(mod, "external")
            f.write(f"  {mod} ({layer}): {count} dependents\n")

    print(f"Report: {report_path}")
    print("=" * 72)


if __name__ == "__main__":
    main()
