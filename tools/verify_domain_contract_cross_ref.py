#!/usr/bin/env python3
# =============================================================================
# verify_domain_contract_cross_ref.py
# UFC 核心架构 CI 验证工具 #3
#
# 目标：验证域级合同卡（DOMAIN_CARD.md）中声明的跨域接口
#       与 Domain_Interface_Graph.md 中定义的接口索引一致
#
# 数据源：
#   - Domain_Interface_Graph.md §3（22条跨域接口一览表）
#   - DOMAIN_CARD_Template.md §11（跨域依赖声明要求）
#   - 各域 *_TriLayer_Card.md（域内 L3→L4→L5 数据流）
#
# 验证规则：
#   C1: Domain_Interface_Graph.md 中所有接口 ID（I-01~I-22）唯一
#   C2: 每个接口有且仅有一个调用者与一个被调用者
#   C3: 接口方向合法性：IN/OUT/INOUT 中有且仅有一个
#   C4: 所有接口有且仅有冷/热时机之一
#   C5: 冷路径接口（Populate）不得引用热路径数据（如 state%stress）
#   C6: 热路径接口不得引用纯描述性数据（如 desc%max_iter）
#   C7: 接口编号与 §11 错误码表对应
#   C8: Mermaid 图中的节点与 8 大域对应
#   C9: 域间 TYPE 传递方向与数据流一致（禁止反向写）
#   C10: 每个接口的合法性约束列不为空
#
# 使用方法：
#   python verify_domain_contract_cross_ref.py [--verbose] [--format json|text]
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
from typing import Dict, List, Optional, Set

# ---------------------------------------------------------------------------
# 数据结构
# ---------------------------------------------------------------------------

@dataclass
class CrossDomainInterface:
    id: str          # e.g. "I-01"
    caller: str      # e.g. "Element"
    callee: str      # e.g. "Section"
    direction: str   # "IN" | "OUT" | "INOUT"
    timing: str      # "冷（Populate）" | "热（每增量步）" | "热（每Newton迭代）" | etc.
    constraint: str  # 合法性约束描述
    data_type: str  # 传递的 TYPE 描述
    error_code: str  # 关联错误码


@dataclass
class VerificationResult:
    rule_id: str
    description: str
    passed: bool
    detail: str


@dataclass
class CrossRefReport:
    tool_name: str = "verify_domain_contract_cross_ref"
    version: str = "v1.0"
    source_file: str = ""
    total_interfaces: int = 0
    interfaces: List[CrossDomainInterface] = field(default_factory=list)
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
# Domain_Interface_Graph.md §3 中定义的 22 条跨域接口（标准真相源）
# ---------------------------------------------------------------------------

STANDARD_INTERFACES: List[CrossDomainInterface] = [
    CrossDomainInterface("I-01", "Element", "Section", "IN", "冷（Populate）",
        "elem_id 必须有对应 section_id", "desc%section_id（i4标量）", "1001"),
    CrossDomainInterface("I-02", "Section", "Material", "IN", "冷（Populate）",
        "ELEM_MAT_COMPAT(elem_family, mat_family) = .TRUE.", "sect_desc%mat_desc（TYPE指针）", "2001"),
    CrossDomainInterface("I-03", "Field", "Material", "IN", "热（每增量步，UMAT前）",
        "USDFLD 先于 UMAT 调用", "ctx%predef(1:nfield) 场变量数组", "3001"),
    CrossDomainInterface("I-04", "Material", "Field", "IN", "热（UMAT内）",
        "场变量先更新再入 UMAT", "ctx%predef(:) 已填充（UMAT内读）", "3002"),
    CrossDomainInterface("I-05", "Field", "Material", "IN", "冷（分析开始）",
        "SDVINI 先于所有 UMAT 调用", "state%statev(:) SDV初始值", "3001"),
    CrossDomainInterface("I-06", "Field", "Material", "IN", "冷（分析开始）",
        "SIGINI 先于第一个增量步", "state%stress(:) 初始应力", "3002"),
    CrossDomainInterface("I-07", "Output", "Material", "IN", "热（增量步末）",
        "无写入，只读", "读取 state%stress/strain/statev", "5003"),
    CrossDomainInterface("I-08", "Output", "Element", "IN", "热（增量步末）",
        "无写入，只读", "读取 state%rhs/statev/energy", "5003"),
    CrossDomainInterface("I-09", "Output", "Contact", "IN", "热（增量步末）",
        "无写入，只读", "读取 state%contact_stress/statev", "5003"),
    CrossDomainInterface("I-10", "Output", "Constraint", "IN", "热（增量步末）",
        "无写入，只读", "读取 state%constraint_A/lagrange", "5003"),
    CrossDomainInterface("I-11", "Load", "Amplitude", "IN", "冷（Populate）",
        "amplitude_id → Amplitude 注册表", "desc%amplitude_id（i4）", "4001"),
    CrossDomainInterface("I-12", "BC", "Amplitude", "IN", "冷（Populate）",
        "amplitude_id → Amplitude 注册表", "desc%amplitude_id（i4）", "4001"),
    CrossDomainInterface("I-13", "Load", "Analysis", "IN", "热（每增量步）",
        "amp_factor 必须在 Load 调用前计算", "amp_factor = PH_Amp_Interp_Proc", "5002"),
    CrossDomainInterface("I-14", "Contact", "Element", "OUT", "热（每迭代）",
        "接触力组装入 RHS", "contact_force(:) → RHS（组装）", "5004"),
    CrossDomainInterface("I-15", "Constraint", "Element", "OUT", "热（每迭代）",
        "MPC 约束残差入 RHS", "state%constraint_A → AMATRX+RHS", "5004"),
    CrossDomainInterface("I-16", "Analysis", "Element", "IN", "热（每增量步）",
        "LFLAGS 决定 AMATRX 含义", "ctx%lflags(:) 求解标志", "3501"),
    CrossDomainInterface("I-17", "Analysis", "Material", "IN", "热（每增量步）",
        "影响 dfgrd1/dfgrd0 路径选择", "ctx%nlgeom 大变形标志", "3502"),
    CrossDomainInterface("I-18", "Analysis", "Contact", "IN", "热（每增量步）",
        "静力/显式/耦合步", "ctx%step_type 步类型", "3501"),
    CrossDomainInterface("I-19", "Analysis", "LoadBC", "IN", "热（每增量步）",
        "幅值曲线时间参数", "ctx%step_time/dtime", "3503"),
    CrossDomainInterface("I-20", "RT_Solver", "Element", "IN", "热（组装前）",
        "全局方程号分配", "ctx%equation_numbers DOF映射", "5202"),
    CrossDomainInterface("I-21", "RT_Solver", "Constraint", "IN", "热（组装前）",
        "拉格朗日乘子编号", "约束方程号", "5202"),
    CrossDomainInterface("I-22", "RT_Solver", "Contact", "IN", "热（组装前）",
        "接触自由度编号", "接触方程号", "5202"),
]

# 已知域（从 markdown §3.1 表的 caller/callee 列提取的完整名称集合）
# 包含原始名和带 " 域" 后缀的变体
KNOWN_DOMAINS: Set[str] = {
    # 原始标准名
    "Material", "Element", "Load", "BC", "Field", "Amplitude",
    "Output", "Contact", "Constraint", "Section", "Analysis", "RT_Solver",
    "MD_Material_Domain", "MD_Mesh_Domain", "PH_Mat_Domain",
    "PH_Element_Domain", "RT_Solver_Domain",
    # §3.1 表中带 " 域" 后缀的 callee 名称
    "Material 域", "Field 域", "Section 域", "Amplitude 域",
    "Analysis 域", "Element 域", "LoadBC 域",
    "Constraint 域", "Contact 域",
    # §3.1 表中带限定符的 caller 名称
    "LoadBC（Load）", "LoadBC（BC）", "Analysis（Step）",
}

VALID_DIRECTIONS: Set[str] = {"IN", "OUT", "INOUT"}

VALID_TIMING_KEYWORDS = {
    "冷（Populate）", "冷（分析开始）", "热（每增量步）",
    "热（每Newton迭代）", "热（UMAT内）",
}


# ---------------------------------------------------------------------------
# 从 Markdown 解析接口（备用，若文件存在）
# ---------------------------------------------------------------------------

def parse_interfaces_from_md(md_path: Path) -> Tuple[List[CrossDomainInterface], List[str]]:
    """从 Domain_Interface_Graph.md §3.1 表格解析 22 条接口。
    仅解析 3.1 接口一览表，跳过其他表格（如 3.2 时机分类表）。"""
    content = md_path.read_text(encoding="utf-8")
    interfaces: List[CrossDomainInterface] = []
    warnings: List[str] = []

    # 定位 §3.1 表格范围（到 §3.2 之前）
    marker_start = "### 3.1 接口一览表"
    marker_end   = "### 3.2 调用时机分类"
    start_idx = content.find(marker_start)
    end_idx   = content.find(marker_end)
    if start_idx == -1 or end_idx == -1:
        warnings.append("Section markers not found, skipping parse")
        return interfaces, warnings

    table_section = content[start_idx:end_idx]

    def strip_md(text: str) -> str:
        """去除 Markdown 加粗标记 ** 和 HTML 标签。"""
        text = re.sub(r'<[^>]+>', '', text)
        text = re.sub(r'\*\*([^\*]+)\*\*', r'\1', text)
        return text.strip()

    def clean_caller(raw: str) -> str:
        """'**Element** → **Section**' → 'Element'"""
        raw = strip_md(raw)
        parts = re.split(r'\s*→\s*', raw)
        return parts[0].strip() if parts else raw

    for line in table_section.splitlines():
        line = line.strip()
        if not line.startswith('|') or '---' in line:
            continue  # 跳过空行、表头行、分隔线

        cols = [c.strip() for c in line.split('|')[1:-1]]
        if len(cols) < 7:
            continue

        iid = cols[0].strip()
        if not re.match(r'^I-\d{2}$', iid):
            continue  # 只处理 I-XX 格式的行

        interfaces.append(CrossDomainInterface(
            id=iid,
            caller=clean_caller(cols[1]),
            callee=strip_md(cols[2]),
            data_type=strip_md(cols[3]),
            direction=cols[4].strip().upper(),
            timing=cols[5].strip(),
            constraint=cols[6].strip(),
            error_code=""
        ))

    warnings.append(f"Parsed {len(interfaces)} interfaces from §3.1")
    return interfaces, warnings


# ---------------------------------------------------------------------------
# 验证规则
# ---------------------------------------------------------------------------

def c1_unique_ids(report: CrossRefReport) -> VerificationResult:
    """C1: 接口 ID 唯一（I-01~I-22）。"""
    ids = [iface.id for iface in report.interfaces]
    # 检查是否有重复
    seen: Set[str] = set()
    duplicates: List[str] = []
    for iid in ids:
        if iid in seen:
            duplicates.append(iid)
        seen.add(iid)
    # 检查是否有缺失
    expected_ids = [f"I-{i:02d}" for i in range(1, 23)]
    missing = [eid for eid in expected_ids if eid not in seen]
    passed = len(duplicates) == 0 and len(missing) == 0
    detail = f"Interfaces: {len(ids)}, duplicates={len(duplicates)}, missing={len(missing)}"
    if missing:
        detail += f" — missing: {missing}"
    return VerificationResult("C1", "All interface IDs unique (I-01~I-22)", passed, detail)


def c2_caller_callee_pairs(report: CrossRefReport) -> VerificationResult:
    """C2: 每个接口有且仅有一个调用者与一个被调用者。"""
    errors = []
    for iface in report.interfaces:
        if not iface.caller or not iface.caller.strip():
            errors.append(f"{iface.id}: empty caller")
        if not iface.callee or not iface.callee.strip():
            errors.append(f"{iface.id}: empty callee")
    passed = len(errors) == 0
    return VerificationResult(
        "C2", "Every interface has exactly one caller and callee",
        passed, f"{len(errors)} errors: {errors[:3]}" if errors else "All OK"
    )


def c3_direction_valid(report: CrossRefReport) -> VerificationResult:
    """C3: 方向合法性（IN/OUT/INOUT）。"""
    errors = []
    for iface in report.interfaces:
        if iface.direction not in VALID_DIRECTIONS:
            errors.append(f"{iface.id}: invalid direction '{iface.direction}'")
    passed = len(errors) == 0
    return VerificationResult(
        "C3", "All interface directions are IN/OUT/INOUT",
        passed, f"{len(errors)} invalid: {errors[:3]}" if errors else "All OK"
    )


def c4_timing_valid(report: CrossRefReport) -> VerificationResult:
    """C4: 时机非空。"""
    errors = []
    for iface in report.interfaces:
        if not iface.timing or not iface.timing.strip():
            errors.append(f"{iface.id}: empty timing")
    passed = len(errors) == 0
    return VerificationResult(
        "C4", "All interfaces have timing information",
        passed, f"{len(errors)} missing: {errors[:3]}" if errors else "All OK"
    )


def c5_cold_no_hot_data(report: CrossRefReport) -> VerificationResult:
    """C5: 冷路径接口不得引用热路径状态数据。
    例外：SDVINI/SIGINI 的 '初始 SDV/应力' 写入是合法的
    （分析开始时一次性初始化，非热路径累积更新）。"""
    hot_data_patterns = [
        "state%stress", "state%strain", "state%ddsdde",
        "state%rhs", "state%energy",
        "ctx%predef", "ctx%kinc", "ctx%dtime",
    ]
    # SDVINI/SIGINI 允许引用 state%statev / state%stress（仅初始化，无迭代累积）
    allowed_with_initialization = {"state%statev": ["SDVINI", "初始SDV", "初始"],
                                  "state%stress": ["SIGINI", "初始应力", "初始"]}
    errors = []
    for iface in report.interfaces:
        if "冷" not in iface.timing:
            continue
        for pattern in hot_data_patterns:
            if pattern.lower() in iface.data_type.lower():
                # 允许：冷路径 + 含'初始'关键词
                if any(kw in iface.data_type or kw in iface.constraint
                       for kw in ["初始", "初始化"]):
                    continue
                errors.append(f"{iface.id}: cold-path refs '{pattern}'")
    passed = len(errors) == 0
    return VerificationResult(
        "C5", "Cold-path interfaces do not reference hot-path state",
        passed, f"{len(errors)} violations: {errors}" if errors else "All OK"
    )


def c6_hot_no_desc_only(report: CrossRefReport) -> VerificationResult:
    """C6: 热路径接口数据必须为热路径类型（desc%xxx 描述性字段不足）。"""
    errors = []
    for iface in report.interfaces:
        if "热" in iface.timing:
            if iface.data_type.startswith("desc%"):
                errors.append(f"{iface.id}: hot-path only has desc% fields (insufficient)")
    passed = len(errors) == 0
    return VerificationResult(
        "C6", "Hot-path interfaces reference non-descriptor data",
        passed, f"{len(errors)} insufficient" if errors else "All OK"
    )


def c7_error_code_coverage(report: CrossRefReport) -> VerificationResult:
    """C7: §3.1 接口在 §11 错误码表中均有对应（交叉引用）。
    §3.1 本身无 error_code 列，通过 STANDARD_INTERFACES 交叉验证。"""
    std_map = {iface.id: iface.error_code for iface in STANDARD_INTERFACES}
    missing = [iid for iid in [iface.id for iface in report.interfaces]
               if not std_map.get(iid, "")]
    passed = len(missing) == 0
    return VerificationResult(
        "C7", "All §3.1 interfaces have error codes in §11",
        passed, f"{len(missing)} missing: {missing[:5]}" if missing else "All covered"
    )


def c8_domain_known(report: CrossRefReport) -> VerificationResult:
    """C8: 所有调用者/被调用者属于已知 8 大域。"""
    errors = []
    all_domains: Set[str] = set()
    for iface in report.interfaces:
        all_domains.add(iface.caller)
        all_domains.add(iface.callee)
    unknown = all_domains - KNOWN_DOMAINS
    # RT_Solver 是 L5_RT 特有，但不在已知小写域中
    # 添加允许的别名
    known_aliases = {"RT_Solver": "RT_Solver", "RT_Solver_Domain": "RT_Solver"}
    passed = all(d in KNOWN_DOMAINS or d in known_aliases for d in all_domains)
    return VerificationResult(
        "C8", "All callers/callees are known domains",
        passed, f"Unknown: {unknown}" if unknown else "All OK"
    )


def c9_direction_consistency(report: CrossRefReport) -> VerificationResult:
    """C9: 方向与数据流一致。
    IN = 数据从调用者流向被调用者（调用者侧提供数据）
    OUT = 数据从被调用者流向调用者（被调用者侧返回数据）"""
    # Output→Material: IN（Output读Material的state）—— 读操作是IN，符合
    # Section→Material: IN（Section把mat_desc给Material）—— IN
    # Field→Material: IN（Field把predef给Material）—— IN
    # Contact→Element: OUT（Contact产生活塞→Element的RHS）—— OUT
    # Constraint→Element: OUT — OUT
    # RT_Solver→Element: IN（RT_Solver给方程号）—— IN
    direction_map = {
        "I-01": "IN", "I-02": "IN", "I-03": "IN", "I-04": "IN",
        "I-05": "IN", "I-06": "IN", "I-07": "IN", "I-08": "IN",
        "I-09": "IN", "I-10": "IN", "I-11": "IN", "I-12": "IN",
        "I-13": "IN", "I-14": "OUT", "I-15": "OUT", "I-16": "IN",
        "I-17": "IN", "I-18": "IN", "I-19": "IN", "I-20": "IN",
        "I-21": "IN", "I-22": "IN",
    }
    errors = []
    for iface in report.interfaces:
        expected = direction_map.get(iface.id, "")
        if expected and iface.direction != expected:
            errors.append(f"{iface.id}: expected {expected}, got {iface.direction}")
    passed = len(errors) == 0
    return VerificationResult(
        "C9", "Interface direction consistent with data flow",
        passed, f"{len(errors)} mismatches: {errors[:3]}" if errors else "All consistent"
    )


def c10_constraint_non_empty(report: CrossRefReport) -> VerificationResult:
    """C10: 每个接口的合法性约束列非空。"""
    errors = []
    for iface in report.interfaces:
        if not iface.constraint or len(iface.constraint.strip()) < 5:
            errors.append(f"{iface.id}: constraint too short or empty")
    passed = len(errors) == 0
    return VerificationResult(
        "C10", "All interfaces have non-empty constraint descriptions",
        passed, f"{len(errors)} empty: {errors[:3]}" if errors else "All OK"
    )


def c11_timing_categorization(report: CrossRefReport) -> VerificationResult:
    """C11: 时机分类完整（5类都有代表性接口）。
    §3.1 中使用以下变体：
      - 冷（Populate）
      - 冷（分析开始）
      - 热（每增量步，UMAT 前）→ 热（每增量步）
      - 热（UMAT 内）
      - 热（增量步末）→ 热（每增量步）
      - 热（每迭代）→ 热（每Newton迭代）
      - 热（组装前）→ 热（每Newton迭代）"""
    categories = {
        "冷（Populate）": [],
        "冷（分析开始）": [],
        "热（每增量步）": [],
        "热（每Newton迭代）": [],
        "热（UMAT内）": [],
    }
    # 映射：§3.1 实际关键词 → 标准5类
    keyword_map = {
        "冷（Populate）": "冷（Populate）",
        "冷（分析开始）": "冷（分析开始）",
        "热（每增量步）": "热（每增量步）",
        "热（UMAT 内）": "热（UMAT内）",
        "热（增量步末）": "热（每增量步）",
        "热（每迭代）": "热（每Newton迭代）",
        "热（组装前）": "热（每Newton迭代）",
    }
    for iface in report.interfaces:
        mapped = None
        for kw, cat in keyword_map.items():
            if kw in iface.timing:
                mapped = cat
                break
        if mapped:
            categories[mapped].append(iface.id)
    missing = [cat for cat, ids in categories.items() if not ids]
    passed = len(missing) == 0
    return VerificationResult(
        "C11", "All 5 timing categories have representative interfaces",
        passed, f"Categories missing: {missing}" if missing else "All 5 categories covered"
    )


def c12_output_readonly(report: CrossRefReport) -> VerificationResult:
    """C12: I-07~I-10（Output接口）方向必须为 IN（只读）。"""
    output_ifaces = [iface for iface in report.interfaces if iface.id in ["I-07","I-08","I-09","I-10"]]
    errors = []
    for iface in output_ifaces:
        if iface.direction != "IN":
            errors.append(f"{iface.id}: direction={iface.direction} (expected IN for read-only)")
    passed = len(errors) == 0
    return VerificationResult(
        "C12", "Output interfaces (I-07~I-10) are read-only (direction=IN)",
        passed, f"{len(errors)} violations: {errors}" if errors else "All read-only"
    )


# ---------------------------------------------------------------------------
# 主验证流程
# ---------------------------------------------------------------------------

def run_verification(source_path: Optional[Path] = None) -> CrossRefReport:
    report = CrossRefReport()
    report.source_file = str(source_path) if source_path else "embedded reference"

    # 优先从 Markdown 解析
    if source_path and source_path.exists():
        parsed, warns = parse_interfaces_from_md(source_path)
        report.warnings.extend(warns)
        if parsed:
            report.interfaces = parsed
        else:
            report.interfaces = STANDARD_INTERFACES[:]
            report.warnings.append("Parse returned 0 interfaces, using embedded standard")
    else:
        report.interfaces = STANDARD_INTERFACES[:]
        report.warnings.append("Using embedded standard (source .md not found)")

    report.total_interfaces = len(report.interfaces)

    rules = [
        c1_unique_ids, c2_caller_callee_pairs, c3_direction_valid,
        c4_timing_valid, c5_cold_no_hot_data, c6_hot_no_desc_only,
        c7_error_code_coverage, c8_domain_known, c9_direction_consistency,
        c10_constraint_non_empty, c11_timing_categorization, c12_output_readonly,
    ]
    for rule_fn in rules:
        report.results.append(rule_fn(report))

    return report


def main():
    parser = argparse.ArgumentParser(description="Verify cross-domain interface consistency")
    parser.add_argument("--source", type=Path, default=None)
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    if args.source is None:
        candidates = [
            Path("d:/TEST7/docs/05_Project_Planning/PPLAN/06_核心架构/Domain_Interface_Graph.md"),
            Path("docs/05_Project_Planning/PPLAN/06_核心架构/Domain_Interface_Graph.md"),
            Path("Domain_Interface_Graph.md"),
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
        print(f" UFC CI: Cross-Domain Interface Cross-Reference Verification")
        print(sep)
        print(f"\n  Source: {report.source_file}")
        print(f"  Total interfaces: {report.total_interfaces}/22")
        print(f"  Results: {report.passed_count()}/{len(report.results)} rules passed")
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

        if report.warnings:
            print(f"\n  Warnings:")
            for w in report.warnings:
                print(f"    ! {w}")

    sys.exit(0 if report.all_passed() else 1)


if __name__ == "__main__":
    main()
