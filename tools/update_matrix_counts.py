#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Update f90 counts in UFC_全层全域权威清单矩阵.md to match actual directory counts.
"""
import os
import re
import glob

UFC_CORE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ufc_core")
MATRIX_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                          "docs", "PPLAN", "06_核心架构", "UFC_全层全域权威清单矩阵.md")


def count_f90(path):
    return len(glob.glob(os.path.join(path, "**", "*.f90"), recursive=True))


def main():
    with open(MATRIX_PATH, 'r', encoding='utf-8') as f:
        content = f.read()

    updates = {}
    for layer in sorted(os.listdir(UFC_CORE)):
        layer_path = os.path.join(UFC_CORE, layer)
        if not os.path.isdir(layer_path) or not layer.startswith("L"):
            continue
        for domain in sorted(os.listdir(layer_path)):
            domain_path = os.path.join(layer_path, domain)
            if not os.path.isdir(domain_path):
                continue
            actual = count_f90(domain_path)
            updates[f"{layer}/{domain}"] = actual

    layer_totals = {}
    for key, count in updates.items():
        layer = key.split("/")[0]
        layer_totals[layer] = layer_totals.get(layer, 0) + count

    lines = content.split('\n')
    new_lines = []
    changed = 0

    for line in lines:
        if '|' in line and line.strip().startswith('|'):
            parts = line.split('|')
            if len(parts) >= 7:
                domain_cell = parts[1].strip().replace('**', '').strip()
                f90_cell = parts[5].strip()
                if f90_cell.isdigit():
                    old_count = int(f90_cell)
                    for key, new_count in updates.items():
                        dom_name = key.split('/')[-1]
                        if dom_name == domain_cell:
                            if old_count != new_count:
                                parts[5] = f" {new_count} "
                                line = '|'.join(parts)
                                changed += 1
                            break
        new_lines.append(line)

    grand_total = sum(layer_totals.values())
    content_new = '\n'.join(new_lines)

    for layer, total in layer_totals.items():
        old_total_pattern = rf'(共\s*)\d+(\s*f90)'
        content_new = re.sub(old_total_pattern, rf'\g<1>{total}\2', content_new, count=1)

    content_new = re.sub(r'\*\*~\d+\*\*\s*\(含层根\)', f'**~{grand_total}** (含层根)', content_new)

    with open(MATRIX_PATH, 'w', encoding='utf-8') as f:
        f.write(content_new)

    print(f"Updated {changed} f90 counts in matrix")
    print(f"Layer totals: {layer_totals}")
    print(f"Grand total: {grand_total}")


if __name__ == "__main__":
    main()
