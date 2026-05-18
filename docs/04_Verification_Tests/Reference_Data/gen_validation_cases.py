#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC UEL/UMAT 验证用例生成脚本

从 elem_meta.csv 与 mat_meta.csv 生成验证矩阵用例清单。
输出: validation_cases.csv, validation_cases.md

用法:
  python gen_validation_cases.py
  或
  python gen_validation_cases.py --output-dir PLAN
"""

import csv
import argparse
from pathlib import Path

# 力学单元族 (family_id) - 可配力学材料
MECH_FAMILIES = {1, 2, 3, 4, 5, 6, 7}  # C3D, CPE, CPS, CAX, S, B, T
# 膜 M2D/M3D 在 family_id=8 但可配力学材料，需按 name 前缀判断
MEMBRANE_PREFIXES = ("M2D", "M3D", "MAX")

# 力学材料 mat_id 百位
MECH_MAT_CLASSES = (1, 2, 3, 4, 5, 7)  # 101-113, 201-220, 301-310, 401-408, 501-509, 701-707
# 排除纯热/电/声学 (601-607 中 601 热传导、607 声学 等为标量场)
EXCLUDE_MAT_RANGES = [(606, 606), (607, 607)]  # MassDiffusion, AcousticMedium


def load_elem_meta(path: Path) -> list[dict]:
    rows = []
    with open(path, encoding="utf-8") as f:
        for r in csv.DictReader(f):
            r["elem_type_id"] = int(r["elem_type_id"])
            r["family_id"] = int(r["family_id"])
            r["n_nodes"] = int(r["n_nodes"])
            rows.append(r)
    return rows


def load_mat_meta(path: Path) -> list[dict]:
    rows = []
    with open(path, encoding="utf-8") as f:
        for r in csv.DictReader(f):
            r["mat_id"] = int(r["mat_id"])
            r["num_props"] = int(r["num_props"])
            r["nStatev"] = int(r["nStatev"])
            rows.append(r)
    return rows


def is_mech_elem(e: dict) -> bool:
    fid = e["family_id"]
    if fid in MECH_FAMILIES:
        return True
    if fid == 8 and any(e["name"].startswith(p) for p in MEMBRANE_PREFIXES):
        return True
    return False


def is_mech_mat(m: dict) -> bool:
    mid = m["mat_id"]
    cls = mid // 100
    if cls not in MECH_MAT_CLASSES:
        return False
    for lo, hi in EXCLUDE_MAT_RANGES:
        if lo <= mid <= hi:
            return False
    return True


def main():
    ap = argparse.ArgumentParser(description="Generate UFC validation test case list")
    ap.add_argument("--output-dir", default=None, help="Output directory (default: same as script)")
    args = ap.parse_args()

    script_dir = Path(__file__).resolve().parent
    data_dir = script_dir
    out_dir = Path(args.output_dir) if args.output_dir else script_dir

    elem_path = data_dir / "elem_meta.csv"
    mat_path = data_dir / "mat_meta.csv"
    if not elem_path.exists() or not mat_path.exists():
        print(f"Error: {elem_path} or {mat_path} not found")
        return 1

    elems = load_elem_meta(elem_path)
    mats = load_mat_meta(mat_path)

    mech_elems = [e for e in elems if is_mech_elem(e)]
    mech_mats = [m for m in mats if is_mech_mat(m)]

    # 高优先级: 文档指定的组合
    high_priority = [
        ("C3D8", 101, "Patch Test、单轴拉伸"),
        ("C3D8", 201, "单轴拉伸、NAFEMS"),
        ("CPE4", 101, "Patch Test、平面应变"),
        ("CAX4", 101, "轴对称"),
        ("C3D8", 301, "超弹性"),
    ]
    # 中优先级
    mid_priority = [
        ("C3D8R", 101, "减缩积分"),
        ("CPE3", 101, "常应变三角形"),
        ("S4R", 101, "壳单元"),
        ("M3D4", 101, "膜单元"),
    ]

    cases = []
    seen = set()

    def add(elem_name: str, mat_id: int, priority: str, note: str):
        key = (elem_name, mat_id)
        if key not in seen:
            seen.add(key)
            cases.append({"elem_name": elem_name, "mat_id": mat_id, "priority": priority, "note": note})

    for en, mid, note in high_priority:
        add(en, mid, "high", note)
    for en, mid, note in mid_priority:
        add(en, mid, "mid", note)

    # 扩展: 所有力学单元 × 真实 UMAT (101-103, 201-202, 301-304, 401)
    real_umat_ids = {101, 102, 103, 201, 202, 301, 302, 303, 304, 401}
    for e in mech_elems:
        for m in mech_mats:
            if m["mat_id"] in real_umat_ids:
                add(e["name"], m["mat_id"], "low", "")

    # 去重并排序
    cases_sorted = sorted(cases, key=lambda c: ({"high": 0, "mid": 1, "low": 2}[c["priority"]], c["elem_name"], c["mat_id"]))

    # 写 CSV
    csv_path = out_dir / "validation_cases.csv"
    with open(csv_path, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["elem_name", "mat_id", "priority", "note"])
        w.writeheader()
        w.writerows(cases_sorted)
    print(f"Wrote {csv_path} ({len(cases_sorted)} cases)")

    # 写 MD
    md_path = out_dir / "validation_cases.md"
    mat_names = {m["mat_id"]: m["name"] for m in mats}
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("# UFC 验证用例清单（自动生成）\n\n")
        f.write("> 来源: gen_validation_cases.py from elem_meta.csv, mat_meta.csv\n\n")
        f.write("## 高优先级\n\n| 单元 | 材料 | 用例 |\n|------|------|------|\n")
        for c in cases_sorted:
            if c["priority"] == "high":
                f.write(f"| {c['elem_name']} | {mat_names.get(c['mat_id'], str(c['mat_id']))} | {c['note']} |\n")
        f.write("\n## 中优先级\n\n| 单元 | 材料 | 用例 |\n|------|------|------|\n")
        for c in cases_sorted:
            if c["priority"] == "mid":
                f.write(f"| {c['elem_name']} | {mat_names.get(c['mat_id'], str(c['mat_id']))} | {c['note']} |\n")
        f.write("\n## 低优先级（力学单元 × 真实 UMAT）\n\n")
        low = [c for c in cases_sorted if c["priority"] == "low"]
        f.write(f"共 {len(low)} 组。详见 validation_cases.csv。\n")
    print(f"Wrote {md_path}")

    return 0


if __name__ == "__main__":
    exit(main())
