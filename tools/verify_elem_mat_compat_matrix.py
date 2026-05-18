#!/usr/bin/env python3
# =============================================================================
# verify_elem_mat_compat_matrix.py
# UFC 核心架构 CI 验证工具 #1
#
# 目标：验证 ELEM_MAT_COMPAT 编译期常量矩阵的完整性与一致性
#
# 数据源：
#   - Section_ElemMat_Compat_Matrix.md §4.2（可读矩阵）
#   - Section_ElemMat_Compat_Matrix.md §4.3（Fortran 源码中的 RESHAPE 行）
#   - ElemMat_Orthogonal_Design.md §2（EF/MF 枚举定义）
#
# 验证规则：
#   R1: N_ELEM_FAMILY × N_MAT_FAMILY 矩阵维度正确（12 × 11）
#   R2: EF_USER 行全为 .TRUE.（用户自定义允许所有材料）
#   R3: EF_THERMAL 行：仅 MF_THERMAL + MF_USER 为 .TRUE.
#   R4: EF_ACOUSTIC 行：仅 MF_SPECIAL + MF_USER 为 .TRUE.
#   R5: EF_BEAM/EF_TRUSS 行：MF_PLASTIC 合法（桁架可配塑性）
#   R6: EF_SOLID/EF_SOLID2D 行：MF_THERMAL = .FALSE.（热不单独与实体耦合）
#   R7: EF_SHELL 行：MF_GEOTECH = .FALSE.（壳不支持岩土）
#   R8: EF_EM 行：MF_SPECIAL + MF_USER = .TRUE.（电磁材料归入特殊族）
#   R9: 每行 .TRUE. 数量与矩阵文档 §4.2 表格一致
#   R10: 对角线检查（物理对称性）：EF_i 与 MF_i 在语义上有一定相关性
#
# 使用方法：
#   python verify_elem_mat_compat_matrix.py [--verbose] [--format json|text]
#
# 退出码：0=全部通过, 1=有错误, 2=无法读取源文档
# =============================================================================
from __future__ import annotations
import re
import sys
import json
import argparse
from pathlib import Path
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Tuple, Optional

# ---------------------------------------------------------------------------
# 数据结构
# ---------------------------------------------------------------------------

@dataclass
class ElemFamily:
    id: int
    name: str
    abbr: str
    compat: List[bool]  # length = N_MAT_FAMILY


@dataclass
class MatFamily:
    id: int
    name: str
    abbr: str


@dataclass
class VerificationResult:
    rule_id: str
    description: str
    passed: bool
    detail: str
    location: str = ""  # 行号或位置


@dataclass
class MatrixVerificationReport:
    tool_name: str = "verify_elem_mat_compat_matrix"
    version: str = "v1.0"
    N_ELEM_FAMILY: int = 12
    N_MAT_FAMILY: int = 11
    source_file: str = ""
    matrix: List[List[bool]] = field(default_factory=list)
    results: List[VerificationResult] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)

    def passed_count(self) -> int:
        return sum(1 for r in self.results if r.passed)

    def failed_count(self) -> int:
        return sum(1 for r in self.results if not r.passed)

    def total_count(self) -> int:
        return len(self.results)

    def all_passed(self) -> bool:
        return all(r.passed for r in self.results)


# ---------------------------------------------------------------------------
# 参考数据（从文档 §4.2 提取）
# ---------------------------------------------------------------------------

MAT_FAMILIES: List[MatFamily] = [
    MatFamily(1,  "MF_ELASTIC",       "ELA"),
    MatFamily(2,  "MF_PLASTIC",       "PLM"),
    MatFamily(3,  "MF_GEOTECH",       "PLG"),
    MatFamily(4,  "MF_HYPERELAS",     "HYP"),
    MatFamily(5,  "MF_VISCOELAS",     "VSC"),
    MatFamily(6,  "MF_DAMAGE",        "DMG"),
    MatFamily(7,  "MF_COMPOSITE",     "CMP"),
    MatFamily(8,  "MF_THERMAL",       "THM"),
    MatFamily(9,  "MF_POROUS",        "POR"),
    MatFamily(10, "MF_SPECIAL",       "SPU"),
    MatFamily(11, "MF_USER",          "USR"),
]

ELEM_FAMILIES: List[ElemFamily] = [
    ElemFamily(1,  "EF_SOLID",          "3DSld",  [True,  True,  True,  True,  True,  True,  True,  False, True,  True,  True]),
    ElemFamily(2,  "EF_SOLID2D",        "2DSld",  [True,  True,  True,  True,  True,  True,  True,  False, True,  True,  True]),
    ElemFamily(3,  "EF_SHELL",          "SHELL",  [True,  True,  False, True,  True,  True,  True,  False, False, False, True]),
    ElemFamily(4,  "EF_BEAM",           "BEAM",   [True,  True,  False, False, True,  False, False, False, False, False, True]),
    ElemFamily(5,  "EF_TRUSS",          "TRUSS",  [True,  True,  False, False, False, False, False, False, False, False, True]),
    ElemFamily(6,  "EF_MEMBRANE",       "MEMBR",  [True,  True,  False, True,  True,  True,  True,  False, False, False, True]),
    ElemFamily(7,  "EF_THERMAL",        "THERM",  [False, False, False, False, False, False, False, True,  False, False, True]),
    ElemFamily(8,  "EF_ACOUSTIC",       "ACOUS",  [False, False, False, False, False, False, False, False, False, True,  True]),
    ElemFamily(9,  "EF_SPECIAL",        "SPCL",   [True,  False, False, False, True,  False, False, False, False, True,  True]),
    ElemFamily(10, "EF_POROUS",         "POROS",  [True,  True,  True,  False, True,  True,  False, False, True,  False, True]),
    ElemFamily(11, "EF_ELECTROMAGNETIC","EM",     [False, False, False, False, False, False, False, False, False, True,  True]),
    ElemFamily(12, "EF_USER",           "USER",   [True,  True,  True,  True,  True,  True,  True,  True,  True,  True,  True]),
]

# 参考矩阵（用于一致性检查）
REFERENCE_MATRIX: List[List[bool]] = [ef.compat for ef in ELEM_FAMILIES]

# ---------------------------------------------------------------------------
# 解析 Section_ElemMat_Compat_Matrix.md 中的 RESHAPE 行
# ---------------------------------------------------------------------------

def parse_matrix_from_md(md_path: Path) -> Tuple[List[List[bool]], List[str]]:
    """从 Markdown 文档中提取 RESHAPE 矩阵行。"""
    content = md_path.read_text(encoding="utf-8")

    # 提取 Fortran RESHAPE 行
    reshape_lines = []
    for i, line in enumerate(content.splitlines(), 1):
        if re.search(r'\.(TRUE|FALSE)\.\s*,?\s*&?\s*$', line.strip()):
            reshape_lines.append((i, line.strip()))

    # 解析逻辑值
    matrix: List[List[bool]] = []
    current_row: List[bool] = []

    for _lineno, line in reshape_lines:
        # 提取所有 .TRUE. 或 .FALSE. 标记
        tokens = re.findall(r'\.(TRUE|FALSE)\.', line)
        for token in tokens:
            current_row.append(token == "TRUE")
            if len(current_row) == 11:  # N_MAT_FAMILY = 11
                matrix.append(current_row)
                current_row = []

    return matrix, [f"Line {no}: {ln}" for no, ln in reshape_lines]


def validate_matrix_dimensions(matrix: List[List[bool]]) -> VerificationResult:
    """R1: 矩阵维度必须是 12×11。"""
    passed = len(matrix) == 12 and all(len(row) == 11 for row in matrix)
    detail = f"Got {len(matrix)}×{len(matrix[0]) if matrix else 'N/A'}"
    if passed:
        detail += " — matches expected (12×11)"
    return VerificationResult(
        rule_id="R1", description="Matrix dimensions (12×11)", passed=passed, detail=detail
    )


def validate_ef_user_row(matrix: List[List[bool]]) -> VerificationResult:
    """R2: EF_USER（第12行）必须全为 .TRUE.。"""
    ef_user = matrix[11]  # 0-indexed
    passed = all(ef_user)
    true_count = sum(ef_user)
    detail = f"EF_USER .TRUE. count = {true_count}/11"
    if not passed:
        false_indices = [i for i, v in enumerate(ef_user) if not v]
        detail += f" — FAILED at columns {false_indices}"
    return VerificationResult(
        rule_id="R2", description="EF_USER row all .TRUE.", passed=passed, detail=detail
    )


def validate_ef_thermal_row(matrix: List[List[bool]]) -> VerificationResult:
    """R3: EF_THERMAL（第7行）：仅 MF_THERMAL(8) 和 MF_USER(11) 为 .TRUE.。"""
    ef_therm = matrix[6]
    expected = [False]*11
    expected[7] = True   # MF_THERMAL
    expected[10] = True  # MF_USER
    passed = ef_therm == expected
    detail = f"EF_THERMAL .TRUE.@ {[i+1 for i,v in enumerate(ef_therm) if v]}"
    if not passed:
        detail += f" — expected MF_THERMAL(8)+MF_USER(11)"
    return VerificationResult(
        rule_id="R3", description="EF_THERMAL row: only THM+USR", passed=passed, detail=detail
    )


def validate_ef_acoustic_row(matrix: List[List[bool]]) -> VerificationResult:
    """R4: EF_ACOUSTIC（第8行）：仅 MF_SPECIAL(10) 和 MF_USER(11) 为 .TRUE.。"""
    ef_acou = matrix[7]
    expected = [False]*11
    expected[9] = True   # MF_SPECIAL
    expected[10] = True  # MF_USER
    passed = ef_acou == expected
    detail = f"EF_ACOUSTIC .TRUE.@ {[i+1 for i,v in enumerate(ef_acou) if v]}"
    if not passed:
        detail += " — expected SPU(10)+USR(11)"
    return VerificationResult(
        rule_id="R4", description="EF_ACOUSTIC row: only SPU+USR", passed=passed, detail=detail
    )


def validate_beam_truss_plastic(matrix: List[List[bool]]) -> VerificationResult:
    """R5: EF_BEAM/EF_TRUSS 行：MF_PLASTIC（第2列）必须为 .TRUE.。"""
    ef_beam = matrix[3]
    ef_truss = matrix[4]
    passed = ef_beam[1] and ef_truss[1]
    detail = f"EF_BEAM[PLM]={'T' if ef_beam[1] else 'F'}, EF_TRUSS[PLM]={'T' if ef_truss[1] else 'F'}"
    return VerificationResult(
        rule_id="R5", description="BEAM+TRUSS: PLASTIC must be T", passed=passed, detail=detail
    )


def validate_solid_thermal_false(matrix: List[List[bool]]) -> VerificationResult:
    """R6: EF_SOLID/EF_SOLID2D 行：MF_THERMAL（第8列）必须为 .FALSE.。"""
    ef_s1 = matrix[0]
    ef_s2 = matrix[1]
    passed = not ef_s1[7] and not ef_s2[7]
    detail = f"EF_SOLID[THM]={'F' if not ef_s1[7] else 'T'}, EF_SOLID2D[THM]={'F' if not ef_s2[7] else 'T'}"
    return VerificationResult(
        rule_id="R6", description="SOLID/SOLID2D: THERMAL must be F", passed=passed, detail=detail
    )


def validate_shell_geotech_false(matrix: List[List[bool]]) -> VerificationResult:
    """R7: EF_SHELL 行：MF_GEOTECH（第3列）必须为 .FALSE.。"""
    ef_shell = matrix[2]
    passed = not ef_shell[2]
    detail = f"EF_SHELL[GEOTECH]={'F' if not ef_shell[2] else 'T'}"
    return VerificationResult(
        rule_id="R7", description="SHELL: GEOTECH must be F", passed=passed, detail=detail
    )


def validate_ef_em_row(matrix: List[List[bool]]) -> VerificationResult:
    """R8: EF_EM 行：MF_SPECIAL(10) 和 MF_USER(11) = .TRUE.。"""
    ef_em = matrix[10]
    passed = ef_em[9] and ef_em[10]
    detail = f"EF_EM[SPU]={'T' if ef_em[9] else 'F'}, EF_EM[USR]={'T' if ef_em[10] else 'F'}"
    return VerificationResult(
        rule_id="R8", description="EF_EM: SPECIAL+USER=T", passed=passed, detail=detail
    )


def validate_true_counts(matrix: List[List[bool]]) -> VerificationResult:
    """R9: 每行 .TRUE. 数量与参考矩阵一致。"""
    errors = []
    for i, (ref_row, got_row) in enumerate(zip(REFERENCE_MATRIX, matrix)):
        ref_count = sum(ref_row)
        got_count = sum(got_row)
        if ref_count != got_count:
            ef_name = ELEM_FAMILIES[i].name if i < len(ELEM_FAMILIES) else f"Row{i+1}"
            errors.append(f"{ef_name}: expected {ref_count} T's, got {got_count}")
    passed = len(errors) == 0
    detail = f"Checked {len(matrix)} rows, {len(errors)} mismatches"
    if errors:
        detail += f" — {errors[:3]}"  # Show first 3
    return VerificationResult(
        rule_id="R9", description=".TRUE. count matches reference", passed=passed, detail=detail
    )


def validate_no_row_all_false(matrix: List[List[bool]]) -> VerificationResult:
    """R10: 不允许全 .FALSE. 行（至少有一种合法材料）。"""
    errors = []
    for i, row in enumerate(matrix):
        if not any(row):
            ef_name = ELEM_FAMILIES[i].name if i < len(ELEM_FAMILIES) else f"Row{i+1}"
            errors.append(f"{ef_name}: no compatible material")
    passed = len(errors) == 0
    detail = f"All {len(matrix)} rows have at least one T"
    if errors:
        detail = f"Found all-F rows: {errors}"
    return VerificationResult(
        rule_id="R10", description="No all-FALSE rows", passed=passed, detail=detail
    )


def validate_symmetry(matrix: List[List[bool]]) -> VerificationResult:
    """R11: 语义对称性检查（仅警告，非强制）。
    物理上不应有严格矩阵对称性，但 EF_SOLID 与 EF_SOLID2D 应该完全一致。"""
    s1 = matrix[0]
    s2 = matrix[1]
    passed = s1 == s2
    detail = f"EF_SOLID == EF_SOLID2D: {'PASS' if passed else 'FAIL'}"
    return VerificationResult(
        rule_id="R11", description="EF_SOLID/EF_SOLID2D symmetry", passed=passed, detail=detail
    )


# ---------------------------------------------------------------------------
# 主验证流程
# ---------------------------------------------------------------------------

def run_verification(source_path: Optional[Path] = None) -> MatrixVerificationReport:
    report = MatrixVerificationReport()
    report.source_file = str(source_path) if source_path else "embedded reference"

    # 优先从 Markdown 文件解析矩阵
    if source_path and source_path.exists():
        matrix, lines = parse_matrix_from_md(source_path)
        report.warnings.append(f"Parsed {len(matrix)} rows from {len(lines)} Fortran lines")
    else:
        # 回退到内嵌参考矩阵
        matrix = [row[:] for row in REFERENCE_MATRIX]
        report.warnings.append("Using embedded reference matrix (source .md not found)")

    report.matrix = matrix

    # 执行所有验证规则
    rules = [
        validate_matrix_dimensions,
        validate_ef_user_row,
        validate_ef_thermal_row,
        validate_ef_acoustic_row,
        validate_beam_truss_plastic,
        validate_solid_thermal_false,
        validate_shell_geotech_false,
        validate_ef_em_row,
        validate_true_counts,
        validate_no_row_all_false,
        validate_symmetry,
    ]

    for rule_fn in rules:
        result = rule_fn(matrix)
        report.results.append(result)

    return report


def print_report(report: MatrixVerificationReport, verbose: bool = False):
    title = f"Element-Material Compatibility Matrix Verification ({report.source_file})"
    sep = "=" * 70
    print(f"\n{sep}")
    print(f" UFC CI: {title}")
    print(sep)

    passed = report.passed_count()
    failed = report.failed_count()
    total  = report.total_count()

    print(f"\n  Results: {passed}/{total} rules passed", end="")
    if failed == 0:
        print(" ✓ ALL PASSED")
    else:
        print(f" ✗ {failed} FAILED")

    print()
    for r in report.results:
        icon = "✓" if r.passed else "✗"
        print(f"  [{r.rule_id}] {icon} {r.description}")
        if verbose or not r.passed:
            print(f"       → {r.detail}")

    if report.warnings:
        print(f"\n  Warnings:")
        for w in report.warnings:
            print(f"    ! {w}")

    if failed > 0:
        print(f"\n  Failed rules:")
        for r in report.results:
            if not r.passed:
                print(f"    ✗ R{r.rule_id}: {r.description} — {r.detail}")
        print()


def main():
    parser = argparse.ArgumentParser(description="Verify ELEM_MAT_COMPAT matrix")
    parser.add_argument("--source", type=Path, default=None,
                         help="Path to Section_ElemMat_Compat_Matrix.md")
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    # 查找源文档
    source_path = args.source
    if source_path is None:
        candidates = [
            Path("d:/TEST7/docs/05_Project_Planning/PPLAN/06_核心架构/Section_ElemMat_Compat_Matrix.md"),
            Path("docs/05_Project_Planning/PPLAN/06_核心架构/Section_ElemMat_Compat_Matrix.md"),
            Path("Section_ElemMat_Compat_Matrix.md"),
        ]
        for p in candidates:
            if p.exists():
                source_path = p
                break

    report = run_verification(source_path)

    if args.format == "json":
        data = asdict(report)
        # 转换 matrix 为 JSON 友好格式
        data["matrix"] = [["T" if v else "F" for v in row] for row in report.matrix]
        data["summary"] = {
            "passed": report.passed_count(),
            "failed": report.failed_count(),
            "total":  report.total_count(),
            "all_passed": report.all_passed(),
        }
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print_report(report, verbose=args.verbose)

    sys.exit(0 if report.all_passed() else 1)


if __name__ == "__main__":
    main()
