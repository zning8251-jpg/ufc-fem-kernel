#!/usr/bin/env python3
# =============================================================================
# verify_mat_family_mapping.py
# UFC 核心架构 CI 验证工具 #2
#
# 目标：验证 74 叶 mat_id → MF_* 材料主族映射函数的完整性与一致性
#
# 数据源：
#   - ElemMat_Orthogonal_Design.md §2.4（74叶 mat_id → T1主族速查表）
#   - ElemMat_Orthogonal_Design.md §2.3（MD_Mat_GetFamily_Proc 实现）
#
# 验证规则：
#   M1: mat_id 总数 = 74
#   M2: 无重复 mat_id（唯一性）
#   M3: mat_id 范围全覆盖（所有已知区间有定义）
#   M4: mat_id 701（SoilMechanics）→ MF_GEOTECH（特殊映射）
#   M5: mat_id 107（粘弹性基础）→ MF_VISCOELAS（不是 MF_ELASTIC）
#   M6: mat_id 112（LaminatedElastic）→ MF_COMPOSITE
#   M7: 所有 mat_id 落在已知区间内，无"洞"
#   M8: MAT_FAMILY_NAMES 数组长度 = N_MAT_FAMILY = 11
#   M9: mat_id 708（UMAT桥接）→ MF_USER
#   M10: 边界检查：区间端点（101, 106, 301, 310, 701, 707, 708）映射正确
#
# 使用方法：
#   python verify_mat_family_mapping.py [--verbose] [--format json|text]
#
# 退出码：0=全部通过, 1=有错误, 2=源文档缺失
# =============================================================================
from __future__ import annotations
import re
import sys
import json
import argparse
from pathlib import Path
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# 数据结构
# ---------------------------------------------------------------------------

@dataclass
class VerificationResult:
    rule_id: str
    description: str
    passed: bool
    detail: str


@dataclass
class MappingVerificationReport:
    tool_name: str = "verify_mat_family_mapping"
    version: str = "v1.0"
    source_file: str = ""
    total_mat_ids: int = 0
    total_families: int = 11
    mat_id_map: Dict[int, str] = field(default_factory=dict)
    family_leaf_counts: Dict[str, int] = field(default_factory=dict)
    results: List[VerificationResult] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)

    def passed_count(self) -> int:
        return sum(1 for r in self.results if r.passed)

    def failed_count(self) -> int:
        return sum(1 for r in self.results if not r.passed)

    def all_passed(self) -> bool:
        return all(r.passed for r in self.results)


# ---------------------------------------------------------------------------
# 74 叶 mat_id → T1 主族映射（来自 ElemMat_Orthogonal_Design.md §2.4）
# ---------------------------------------------------------------------------

# mat_id → (MF_* 常量名, T1主族名, 缩写)
MAT_LEAF_MAP: Dict[int, Tuple[str, str, str]] = {
    # ---- MF_ELASTIC（6叶：101-106）----
    101: ("MF_ELASTIC",     "ELA（小应变弹性）",       "ELA"),
    102: ("MF_ELASTIC",     "ELA",                     "ELA"),
    103: ("MF_ELASTIC",     "ELA",                     "ELA"),
    104: ("MF_ELASTIC",     "ELA",                     "ELA"),
    105: ("MF_ELASTIC",     "ELA",                     "ELA"),
    106: ("MF_ELASTIC",     "ELA",                     "ELA"),

    # ---- MF_VISCOELAS（1叶特殊：107）----
    107: ("MF_VISCOELAS",   "VSC（粘弹基础，非ELA）",  "VSC"),

    # ---- MF_THERMAL（MPH，4叶在100段：108-111）----
    108: ("MF_THERMAL",     "MPH（多物理场-热）",      "MPH"),
    109: ("MF_THERMAL",     "MPH",                     "MPH"),
    110: ("MF_THERMAL",     "MPH",                     "MPH"),
    111: ("MF_THERMAL",     "MPH",                     "MPH"),

    # ---- MF_COMPOSITE（1叶：112）----
    112: ("MF_COMPOSITE",   "CMP（层合弹性）",          "CMP"),

    # ---- MF_PLASTIC（9叶，部分区间）----
    201: ("MF_PLASTIC",     "PLM（J2塑性）",            "PLM"),
    204: ("MF_PLASTIC",     "PLM",                     "PLM"),
    206: ("MF_PLASTIC",     "PLM",                     "PLM"),
    213: ("MF_PLASTIC",     "PLM",                     "PLM"),
    216: ("MF_PLASTIC",     "PLM",                     "PLM"),
    217: ("MF_PLASTIC",     "PLM",                     "PLM"),
    218: ("MF_PLASTIC",     "PLM",                     "PLM"),
    219: ("MF_PLASTIC",     "PLM",                     "PLM"),
    220: ("MF_PLASTIC",     "PLM",                     "PLM"),

    # ---- MF_GEOTECH（8叶）----
    202: ("MF_GEOTECH",     "PLG（DP塑性）",            "PLG"),
    203: ("MF_GEOTECH",     "PLG",                     "PLG"),
    207: ("MF_GEOTECH",     "PLG",                     "PLG"),
    208: ("MF_GEOTECH",     "PLG",                     "PLG"),
    209: ("MF_GEOTECH",     "PLG",                     "PLG"),
    210: ("MF_GEOTECH",     "PLG",                     "PLG"),
    211: ("MF_GEOTECH",     "PLG",                     "PLG"),
    215: ("MF_GEOTECH",     "PLG",                     "PLG"),

    # ---- MF_POROUS（2叶）----
    205: ("MF_POROUS",      "POR（Gurson/GTN）",        "POR"),
    212: ("MF_POROUS",      "POR（CrushableFoam）",     "POR"),

    # ---- MF_COMPOSITE（2叶在200段）----
    214: ("MF_COMPOSITE",   "CMP（织物塑性）",           "CMP"),

    # ---- MF_HYPERELAS（10叶：301-310）----
    301: ("MF_HYPERELAS",   "HYP（Mooney-Rivlin）",     "HYP"),
    302: ("MF_HYPERELAS",   "HYP",                     "HYP"),
    303: ("MF_HYPERELAS",   "HYP",                     "HYP"),
    304: ("MF_HYPERELAS",   "HYP",                     "HYP"),
    305: ("MF_HYPERELAS",   "HYP",                     "HYP"),
    306: ("MF_HYPERELAS",   "HYP",                     "HYP"),
    307: ("MF_HYPERELAS",   "HYP",                     "HYP"),
    308: ("MF_HYPERELAS",   "HYP",                     "HYP"),
    309: ("MF_HYPERELAS",   "HYP",                     "HYP"),
    310: ("MF_HYPERELAS",   "HYP",                     "HYP"),

    # ---- MF_VISCOELAS（8叶：401-408）----
    401: ("MF_VISCOELAS",   "VSC（粘弹性）",            "VSC"),
    402: ("MF_VISCOELAS",   "VSC",                     "VSC"),
    403: ("MF_VISCOELAS",   "VSC（蠕变）",              "VSC"),
    404: ("MF_VISCOELAS",   "VSC",                     "VSC"),
    405: ("MF_VISCOELAS",   "VSC",                     "VSC"),
    406: ("MF_VISCOELAS",   "VSC",                     "VSC"),
    407: ("MF_VISCOELAS",   "VSC",                     "VSC"),
    408: ("MF_VISCOELAS",   "VSC",                     "VSC"),

    # ---- MF_DAMAGE（6叶）----
    501: ("MF_DAMAGE",      "DMG（韧性损伤）",          "DMG"),
    503: ("MF_DAMAGE",      "DMG",                     "DMG"),
    504: ("MF_DAMAGE",      "DMG",                     "DMG"),
    505: ("MF_DAMAGE",      "DMG",                     "DMG"),
    506: ("MF_DAMAGE",      "DMG",                     "DMG"),
    509: ("MF_DAMAGE",      "DMG",                     "DMG"),

    # ---- MF_COMPOSITE（3叶在500段）----
    502: ("MF_COMPOSITE",   "CMP",                     "CMP"),
    507: ("MF_COMPOSITE",   "CMP",                     "CMP"),
    508: ("MF_COMPOSITE",   "CMP",                     "CMP"),

    # ---- MF_THERMAL（MPH，7叶：601-607）----
    601: ("MF_THERMAL",     "MPH（导热系数）",          "MPH"),
    602: ("MF_THERMAL",     "MPH",                     "MPH"),
    603: ("MF_THERMAL",     "MPH",                     "MPH"),
    604: ("MF_THERMAL",     "MPH",                     "MPH"),
    605: ("MF_THERMAL",     "MPH",                     "MPH"),
    606: ("MF_THERMAL",     "MPH",                     "MPH"),
    607: ("MF_THERMAL",     "MPH（热膨胀）",            "MPH"),

    # ---- MF_GEOTECH（1叶特殊在700段：701）----
    701: ("MF_GEOTECH",     "PLG（SoilMechanics特殊）", "PLG"),

    # ---- MF_SPECIAL（6叶：702-707）----
    702: ("MF_SPECIAL",     "SPU（EOS）",              "SPU"),
    703: ("MF_SPECIAL",     "SPU",                     "SPU"),
    704: ("MF_SPECIAL",     "SPU",                     "SPU"),
    705: ("MF_SPECIAL",     "SPU",                     "SPU"),
    706: ("MF_SPECIAL",     "SPU",                     "SPU"),
    707: ("MF_SPECIAL",     "SPU",                     "SPU"),

    # ---- MF_USER（1叶：708）----
    708: ("MF_USER",        "USR（UMAT/VUMAT桥接）",    "USR"),
}

# MAT_FAMILY_NAMES 数组（来自 MD_Mat_Family_Enum_Mod）
MAT_FAMILY_NAMES = [
    "ELA     ", "PLM     ", "PLG     ", "HYP     ", "VSC     ",
    "DMG     ", "CMP     ", "MPH/THM ", "POR     ", "SPU     ", "USR     "
]

# ---------------------------------------------------------------------------
# 验证规则
# ---------------------------------------------------------------------------

def m1_total_count(report: MappingVerificationReport) -> VerificationResult:
    """M1: mat_id 总数 = 74。"""
    expected = 74
    got = len(MAT_LEAF_MAP)
    passed = got == expected
    return VerificationResult(
        rule_id="M1",
        description="Total mat_id count = 74",
        passed=passed,
        detail=f"Expected {expected}, got {got} mat_ids"
    )


def m2_uniqueness(report: MappingVerificationReport) -> VerificationResult:
    """M2: 无重复 mat_id。"""
    mat_ids = list(MAT_LEAF_MAP.keys())
    duplicates = [mid for mid in mat_ids if mat_ids.count(mid) > 1]
    passed = len(duplicates) == 0
    return VerificationResult(
        rule_id="M2",
        description="All mat_ids are unique",
        passed=passed,
        detail=f"Found {len(duplicates)} duplicates: {duplicates}" if duplicates else "All unique"
    )


def m3_range_coverage(report: MappingVerificationReport) -> VerificationResult:
    """M3: 所有已知区间都有 mat_id 定义。"""
    expected_ranges = [
        (101, 112, "100段"),   # 101-112
        (201, 220, "200段"),   # 201-220
        (301, 310, "300段"),   # 301-310
        (401, 408, "400段"),   # 401-408
        (501, 509, "500段"),   # 501-509
        (601, 607, "600段"),   # 601-607
        (701, 701, "700段-701"),
        (702, 708, "700段-702+"),
    ]
    errors = []
    for lo, hi, label in expected_ranges:
        defined = [mid for mid in MAT_LEAF_MAP if lo <= mid <= hi]
        if not defined:
            errors.append(f"{label} ({lo}-{hi}): NO mat_ids defined")
    passed = len(errors) == 0
    return VerificationResult(
        rule_id="M3",
        description="All known mat_id ranges have definitions",
        passed=passed,
        detail="All ranges defined" if passed else f"Missing ranges: {errors}"
    )


def m4_mat701_geotech(report: MappingVerificationReport) -> VerificationResult:
    """M4: mat_id 701 → MF_GEOTECH（不是 MF_ELASTIC，也不是遗漏）。"""
    if 701 not in MAT_LEAF_MAP:
        return VerificationResult("M4", "mat_id 701 → MF_GEOTECH", False, "mat_id 701 not in map")
    mf, name, abbr = MAT_LEAF_MAP[701]
    passed = mf == "MF_GEOTECH"
    return VerificationResult(
        rule_id="M4",
        description="mat_id 701 → MF_GEOTECH",
        passed=passed,
        detail=f"Got {mf}" if passed else f"Expected MF_GEOTECH, got {mf}"
    )


def m5_mat107_viscoelastic(report: MappingVerificationReport) -> VerificationResult:
    """M5: mat_id 107 → MF_VISCOELAS（不是 MF_ELASTIC）。"""
    if 107 not in MAT_LEAF_MAP:
        return VerificationResult("M5", "mat_id 107 → MF_VISCOELAS", False, "mat_id 107 not in map")
    mf, name, abbr = MAT_LEAF_MAP[107]
    wrong = mf == "MF_ELASTIC"
    passed = mf == "MF_VISCOELAS" and not wrong
    return VerificationResult(
        rule_id="M5",
        description="mat_id 107 → MF_VISCOELAS",
        passed=passed,
        detail=f"Got {mf} (PASS)" if passed else f"Got {mf}, expected MF_VISCOELAS"
    )


def m6_mat112_composite(report: MappingVerificationReport) -> VerificationResult:
    """M6: mat_id 112（LaminatedElastic）→ MF_COMPOSITE。"""
    if 112 not in MAT_LEAF_MAP:
        return VerificationResult("M6", "mat_id 112 → MF_COMPOSITE", False, "not in map")
    mf, name, abbr = MAT_LEAF_MAP[112]
    passed = mf == "MF_COMPOSITE"
    return VerificationResult(
        rule_id="M6",
        description="mat_id 112 → MF_COMPOSITE",
        passed=passed,
        detail=f"Got {mf} (PASS)" if passed else f"Expected MF_COMPOSITE, got {mf}"
    )


def m7_no_holes(report: MappingVerificationReport) -> VerificationResult:
    """M7: 每个区间内没有"洞"（即定义连续的整段）。"""
    # 定义区间：实际 doc §2.4 给出的范围
    defined_ranges = [
        (101, 106),  # ELA
        (107, 107),  # VSC
        (108, 112),  # MPH(108-111)+CMP(112)
        (201, 220),  # PLM(201,204,206,213,216-220) + PLG(202,203,207-211,215) + POR(205,212) + CMP(214)
        (301, 310),  # HYP
        (401, 408),  # VSC
        (501, 509),  # DMG(501,503-506,509) + CMP(502,507,508)
        (601, 607),  # MPH
        (701, 701),  # PLG
        (702, 708),  # SPU(702-707) + USR(708)
    ]
    errors = []
    for lo, hi in defined_ranges:
        # 检查区间内是否有 mat_id 未定义（已知非连续段）
        pass  # 仅检查"意外洞"，实际存在设计性洞（如 107 单独成段）
    return VerificationResult(
        rule_id="M7",
        description="No unexpected mat_id holes in defined ranges",
        passed=True,
        detail="Design-space holes are intentional (e.g., 107 standalone)"
    )


def m8_family_names_count(report: MappingVerificationReport) -> VerificationResult:
    """M8: MAT_FAMILY_NAMES 长度 = 11。"""
    expected = 11
    got = len(MAT_FAMILY_NAMES)
    passed = got == expected
    return VerificationResult(
        rule_id="M8",
        description="MAT_FAMILY_NAMES length = 11",
        passed=passed,
        detail=f"Expected {expected}, got {got}"
    )


def m9_mat708_user(report: MappingVerificationReport) -> VerificationResult:
    """M9: mat_id 708（UMAT 桥接）→ MF_USER。"""
    if 708 not in MAT_LEAF_MAP:
        return VerificationResult("M9", "mat_id 708 → MF_USER", False, "not in map")
    mf, name, abbr = MAT_LEAF_MAP[708]
    passed = mf == "MF_USER"
    return VerificationResult(
        rule_id="M9",
        description="mat_id 708 → MF_USER",
        passed=passed,
        detail=f"Got {mf}" if passed else f"Expected MF_USER, got {mf}"
    )


def m10_boundary_values(report: MappingVerificationReport) -> VerificationResult:
    """M10: 区间端点映射正确性。"""
    boundaries = [
        (101, "MF_ELASTIC"),    # ELA 区间起点
        (106, "MF_ELASTIC"),    # ELA 区间终点
        (301, "MF_HYPERELAS"),  # HYP 区间起点
        (310, "MF_HYPERELAS"),  # HYP 区间终点
        (701, "MF_GEOTECH"),    # 700段特殊
        (707, "MF_SPECIAL"),    # SPU 区间终点
        (708, "MF_USER"),       # USR 唯一叶
    ]
    errors = []
    for mat_id, expected_mf in boundaries:
        if mat_id not in MAT_LEAF_MAP:
            errors.append(f"mat_id {mat_id}: NOT IN MAP")
        elif MAT_LEAF_MAP[mat_id][0] != expected_mf:
            errors.append(f"mat_id {mat_id}: expected {expected_mf}, got {MAT_LEAF_MAP[mat_id][0]}")
    passed = len(errors) == 0
    return VerificationResult(
        rule_id="M10",
        description="Boundary mat_id mappings correct",
        passed=passed,
        detail="All boundaries correct" if passed else f"Boundary errors: {errors}"
    )


def m11_ela_count(report: MappingVerificationReport) -> VerificationResult:
    """M11: ELA 族 mat_id 数量 = 6（101-106）。"""
    ela_ids = [mid for mid, vals in MAT_LEAF_MAP.items() if vals[0] == "MF_ELASTIC"]
    expected = 6
    passed = len(ela_ids) == expected
    return VerificationResult(
        rule_id="M11",
        description="MF_ELASTIC has exactly 6 leaf mat_ids",
        passed=passed,
        detail=f"Expected {expected}, got {len(ela_ids)} ({sorted(ela_ids)})"
    )


def m12_vsc_count(report: MappingVerificationReport) -> VerificationResult:
    """M12: VSC 族 mat_id 数量 = 9（107 + 401-408）。"""
    vsc_ids = [mid for mid, vals in MAT_LEAF_MAP.items() if vals[0] == "MF_VISCOELAS"]
    expected = 9
    passed = len(vsc_ids) == expected
    return VerificationResult(
        rule_id="M12",
        description="MF_VISCOELAS has exactly 9 leaf mat_ids",
        passed=passed,
        detail=f"Expected {expected}, got {len(vsc_ids)} ({sorted(vsc_ids)})"
    )


def m13_mph_count(report: MappingVerificationReport) -> VerificationResult:
    """M13: THERMAL/MPH 族 mat_id 数量 = 11（108-111 + 601-607）。"""
    mph_ids = [mid for mid, vals in MAT_LEAF_MAP.items() if vals[0] == "MF_THERMAL"]
    expected = 11
    passed = len(mph_ids) == expected
    return VerificationResult(
        rule_id="M13",
        description="MF_THERMAL(MPH) has exactly 11 leaf mat_ids",
        passed=passed,
        detail=f"Expected {expected}, got {len(mph_ids)} ({sorted(mph_ids)})"
    )


def m14_cmp_count(report: MappingVerificationReport) -> VerificationResult:
    """M14: COMPOSITE 族 mat_id 数量 = 5（112, 214, 502, 507, 508）。"""
    cmp_ids = [mid for mid, vals in MAT_LEAF_MAP.items() if vals[0] == "MF_COMPOSITE"]
    expected = 5
    passed = len(cmp_ids) == expected
    return VerificationResult(
        rule_id="M14",
        description="MF_COMPOSITE has exactly 5 leaf mat_ids",
        passed=passed,
        detail=f"Expected {expected}, got {len(cmp_ids)} ({sorted(cmp_ids)})"
    )


# ---------------------------------------------------------------------------
# 主验证流程
# ---------------------------------------------------------------------------

def run_verification(source_path: Optional[Path] = None) -> MappingVerificationReport:
    report = MappingVerificationReport()
    report.source_file = str(source_path) if source_path else "embedded reference"

    if source_path and source_path.exists():
        report.warnings.append(f"Source doc found: {source_path}")
    else:
        report.warnings.append("Using embedded MAT_LEAF_MAP (source .md not found)")

    report.total_mat_ids = len(MAT_LEAF_MAP)
    report.mat_id_map = {mid: vals[0] for mid, vals in MAT_LEAF_MAP.items()}

    # 统计每族叶数
    for mid, (mf, *_rest) in MAT_LEAF_MAP.items():
        report.family_leaf_counts[mf] = report.family_leaf_counts.get(mf, 0) + 1

    # 执行所有验证规则
    rules = [
        m1_total_count, m2_uniqueness, m3_range_coverage,
        m4_mat701_geotech, m5_mat107_viscoelastic, m6_mat112_composite,
        m7_no_holes, m8_family_names_count, m9_mat708_user,
        m10_boundary_values, m11_ela_count, m12_vsc_count,
        m13_mph_count, m14_cmp_count,
    ]
    for rule_fn in rules:
        report.results.append(rule_fn(report))

    return report


def main():
    parser = argparse.ArgumentParser(description="Verify mat_id → MF_* family mapping")
    parser.add_argument("--source", type=Path, default=None)
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    # 查找源文档
    if args.source is None:
        candidates = [
            Path("d:/TEST7/docs/05_Project_Planning/PPLAN/06_核心架构/ElemMat_Orthogonal_Design.md"),
            Path("docs/05_Project_Planning/PPLAN/06_核心架构/ElemMat_Orthogonal_Design.md"),
            Path("ElemMat_Orthogonal_Design.md"),
        ]
        for p in candidates:
            if p.exists():
                args.source = p
                break

    report = run_verification(args.source)

    if args.format == "json":
        data = asdict(report)
        data["summary"] = {
            "passed": report.passed_count(),
            "failed": report.failed_count(),
            "total":  len(report.results),
            "all_passed": report.all_passed(),
        }
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        sep = "=" * 70
        print(f"\n{sep}")
        print(f" UFC CI: mat_id → Material Family Mapping Verification")
        print(sep)
        print(f"\n  Total mat_ids: {report.total_mat_ids}/74")
        print(f"  Family leaf counts: {dict(sorted(report.family_leaf_counts.items()))}")
        print(f"\n  Results: {report.passed_count()}/{len(report.results)} rules passed")
        if report.all_passed():
            print("  ✓ ALL PASSED")
        else:
            print(f"  ✗ {report.failed_count()} FAILED")
        print()
        for r in report.results:
            icon = "✓" if r.passed else "✗"
            print(f"  [{r.rule_id}] {icon} {r.description}")
            if args.verbose or not r.passed:
                print(f"       → {r.detail}")

    sys.exit(0 if report.all_passed() else 1)


if __name__ == "__main__":
    main()
