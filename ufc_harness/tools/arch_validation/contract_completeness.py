#!/usr/bin/env python3
"""
UFC 合同卡完整性验证器
功能: 检查所有域的合同卡是否完整定义，覆盖字段完整性、接口契约一致性、文档同步性
"""

import os
import json
import sys
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple, Any
from collections import defaultdict


class ContractCompletenessChecker:
    """合同卡完整性验证器"""

    # T1 主族白名单
    MATERIAL_T1_WHITELIST = {
        "ELA",
        "HYP",
        "PLM",
        "PLG",
        "POR",
        "DMG",
        "CMP",
        "VSC",
        "MPH",
        "SPU",
        "USR",
    }

    # T2 命名格式：T1_子族
    MATERIAL_T2_PATTERN = re.compile(r"^(ELA|HYP|PLM|PLG|POR|DMG|CMP|VSC|MPH|SPU|USR)_[A-Z0-9][A-Z0-9_]*$")

    # 合同卡标准字段
    REQUIRED_CONTRACT_FIELDS = {
        "domain_name": "域名",
        "layer": "层级 (L1-L6)",
        "responsibility": "职责描述",
        "input_interfaces": "输入接口",
        "output_interfaces": "输出接口",
        "dependencies": "依赖关系",
        "constraints": "约束条件",
        "algorithms": "核心算法"
    }
    
    # 合同卡文件模式
    CONTRACT_FILE_PATTERNS = [
        "*Contract*",
        "*contract*",
        "*_Domain.md",
        "*Domain.md"
    ]
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.plan_dir = self.root_path / "PLAN"
        self.contracts_found = []
        self.domains_found = set()
        self.issues = []
        self.t1_issues = []
        self.t2_issues = []
        self.material_t1t2_gate_path = (
            self.root_path / "docs" / "PPLAN" / "10_材料专项" / "_inv" / "material_t1_t2_gates.md"
        )
        self.material_taxonomy_path = (
            self.root_path / "docs" / "PPLAN" / "10_材料专项" / "_inv" / "MAT_TAXONOMY.md"
        )
        self.material_leaf_index_path = (
            self.root_path / "docs" / "PPLAN" / "10_材料专项" / "_inv" / "MAT_LEAF_INDEX_74.md"
        )
    
    def scan_contracts(self) -> Dict:
        """扫描所有合同卡"""

        if not self.plan_dir.exists():
            return {"contracts_found": 0, "domains_found": 0, "error": f"PLAN directory not found: {self.plan_dir}"}

        # 搜索可能的合同卡文件
        for pattern in self.CONTRACT_FILE_PATTERNS:
            for contract_file in self.plan_dir.rglob(pattern):
                if contract_file.suffix == ".md":
                    contract_info = self._analyze_contract(contract_file)
                    if contract_info:
                        self.contracts_found.append(contract_info)

        # 扫描 L4_PH 目录识别所有域
        l4_ph_dir = self.root_path / "ufc_core" / "L4_PH"
        if l4_ph_dir.exists():
            for domain_dir in l4_ph_dir.iterdir():
                if domain_dir.is_dir() and not domain_dir.name.startswith("_"):
                    self.domains_found.add(domain_dir.name)

        self._load_material_gate_basics()
        return {
            "contracts_found": len(self.contracts_found),
            "domains_found": len(self.domains_found),
        }
    
    def _analyze_contract(self, file_path: Path) -> Dict:
        """分析合同卡内容"""

        try:
            content = file_path.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            return {}

        # 提取标题作为域名
        title_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
        domain_name = title_match.group(1).strip() if title_match else file_path.stem

        # 检查必需字段
        fields_present = {}
        for field_key, field_desc in self.REQUIRED_CONTRACT_FIELDS.items():
            # 使用多种模式匹配字段
            patterns = [
                rf"{field_desc}\s*[:：]",
                rf"\*\*{field_desc}\*\*",
                rf"###\s*{field_desc}",
                rf"##\s*{field_desc}",
            ]

            present = any(re.search(p, content, re.IGNORECASE) for p in patterns)
            fields_present[field_key] = present

        # 统计字段完整度
        filled_count = sum(fields_present.values())
        total_count = len(self.REQUIRED_CONTRACT_FIELDS)
        completeness_score = filled_count / total_count if total_count > 0 else 0

        # 识别关键信息
        layer_match = re.search(r"(L[1-6]|PH|MD|RT|NM)", content)
        algorithms = re.findall(r"[-*]\s*(\w+.*(?:算法|求解器|方法))", content)[:5]

        material_t1 = self._detect_material_t1(file_path, content)
        material_t2 = self._detect_material_t2(file_path, content)

        return {
            "file": str(file_path.relative_to(self.root_path)),
            "domain_name": domain_name,
            "layer": layer_match.group(1) if layer_match else "Unknown",
            "fields_present": fields_present,
            "completeness_score": round(completeness_score * 100, 2),
            "missing_fields": [k for k, v in fields_present.items() if not v],
            "algorithms_identified": algorithms,
            "lines": len(content.split("\n")),
            "material_t1": material_t1,
            "material_t2": material_t2,
        }
    
    def check_coverage(self) -> Dict:
        """检查合同卡覆盖率"""

        coverage = {
            "total_domains": len(self.domains_found),
            "domains_with_contract": set(),
            "domains_without_contract": set(),
            "coverage_rate": 0,
            "material_t1_issues": [],
            "material_t2_issues": [],
        }

        # 从合同卡中提取域名
        contract_domains = set()
        material_contracts = []
        for contract in self.contracts_found:
            domain = contract.get("domain_name", "")
            if domain:
                contract_domains.add(domain)

            if domain in self.domains_found:
                coverage["domains_with_contract"].add(domain)

            if contract.get("material_t1") or contract.get("material_t2"):
                material_contracts.append(contract)

        # 识别缺失的域
        for domain in self.domains_found:
            if domain not in contract_domains:
                coverage["domains_without_contract"].add(domain)

        # 计算覆盖率
        if coverage["total_domains"] > 0:
            coverage["coverage_rate"] = round(
                len(coverage["domains_with_contract"]) / coverage["total_domains"] * 100, 2
            )

        # 材料 T1/T2 联动检查
        self._check_material_t1_t2_gate()
        coverage["material_t1_issues"] = list(self.t1_issues)
        coverage["material_t2_issues"] = list(self.t2_issues)
        return coverage
    
    def validate_interface_consistency(self) -> List[Dict]:
        """验证接口契约一致性"""
        issues = []
        
        # 按域分组合同卡
        domain_contracts = defaultdict(list)
        for contract in self.contracts_found:
            domain_contracts[contract['domain_name']].append(contract)
        
        # 检查同一域的多个合同卡版本
        for domain, contracts in domain_contracts.items():
            if len(contracts) > 1:
                # 比较不同版本的接口定义
                interfaces = [c.get('fields_present', {}).get('input_interfaces', False) 
                             for c in contracts]
                
                if not all(interfaces):
                    issues.append({
                        "type": "interface_inconsistency",
                        "severity": "medium",
                        "domain": domain,
                        "description": f"{len(contracts)} 个合同卡存在接口定义不一致",
                        "files": [c['file'] for c in contracts]
                    })
        
        return issues
    
    def check_field_completeness(self) -> List[Dict]:
        """检查字段完整性"""
        issues = []

        for contract in self.contracts_found:
            missing = contract.get("missing_fields", [])
            score = contract.get("completeness_score", 0)

            if score < 80:  # 完整度低于 80%
                severity = "high" if score < 50 else "medium"
                issues.append({
                    "type": "incomplete_fields",
                    "severity": severity,
                    "domain": contract["domain_name"],
                    "completeness": score,
                    "missing_fields": missing,
                    "file": contract["file"]
                })

        return issues

    def _load_material_gate_basics(self) -> None:
        """加载材料门禁基础文件，用于联动检查。"""
        self._material_gate_content = {}
        for key, path in (
            ("t1_t2_gates", self.material_t1t2_gate_path),
            ("taxonomy", self.material_taxonomy_path),
            ("leaf_index", self.material_leaf_index_path),
        ):
            try:
                self._material_gate_content[key] = path.read_text(encoding="utf-8")
            except Exception:
                self._material_gate_content[key] = ""

    def _ensure_material_gate_content(self) -> None:
        """确保材料门禁内容已加载。"""
        if not hasattr(self, "_material_gate_content"):
            self._load_material_gate_basics()

    def _detect_material_t1(self, file_path: Path, content: str) -> str:
        """检测材料 T1 代码。"""
        gate_text = self._material_gate_content.get("taxonomy", "")
        if "材料域分级与 **11 主族**" not in gate_text:
            return ""

        if "Material" not in str(file_path):
            return ""

        for token in self.MATERIAL_T1_WHITELIST:
            if re.search(rf"\b{token}\b", content):
                return token
        return ""

    def _detect_material_t2(self, file_path: Path, content: str) -> str:
        """检测材料 T2 子族。"""
        if "Material" not in str(file_path):
            return ""

        for match in re.finditer(r"\b([A-Z]{3}_[A-Z0-9][A-Z0-9_]*)\b", content):
            t2 = match.group(1)
            if self.MATERIAL_T2_PATTERN.match(t2):
                return t2
        return ""

    def _check_material_t1_t2_gate(self) -> None:
        """执行材料 T1/T2 门禁检查。"""
        self._ensure_material_gate_content()
        if not self._material_gate_content.get("t1_t2_gates"):
            self.t1_issues.append({
                "type": "material_gate_missing",
                "severity": "high",
                "message": "缺少 material_t1_t2_gates.md",
            })
            return

        for contract in self.contracts_found:
            t1 = contract.get("material_t1", "")
            t2 = contract.get("material_t2", "")
            if t1 and t1 not in self.MATERIAL_T1_WHITELIST:
                self.t1_issues.append({
                    "type": "material_t1_whitelist_violation",
                    "severity": "high",
                    "domain": contract["domain_name"],
                    "value": t1,
                })
            if t2 and not self.MATERIAL_T2_PATTERN.match(t2):
                self.t2_issues.append({
                    "type": "material_t2_naming_violation",
                    "severity": "high",
                    "domain": contract["domain_name"],
                    "value": t2,
                })

        if self._material_gate_content.get("t1_t2_gates"):
            if "新增 T2 的联动更新要求" not in self._material_gate_content["t1_t2_gates"]:
                self.t2_issues.append({
                    "type": "material_t2_linkage_rule_missing",
                    "severity": "high",
                    "message": "门禁文档中缺少新增 T2 联动更新要求",
                })
    
    def generate_report(self) -> str:
        """生成报告"""
        scan_result = self.scan_contracts()
        coverage = self.check_coverage()
        interface_issues = self.validate_interface_consistency()
        field_issues = self.check_field_completeness()

        lines = [
            "=" * 70,
            "UFC 合同卡完整性验证报告",
            "=" * 70,
            "",
            f"发现合同卡：{scan_result['contracts_found']} 份",
            f"识别域数量：{scan_result['domains_found']} 个",
            "",
            "-" * 70,
            "覆盖率统计",
            "-" * 70,
            f"有合同卡的域：{len(coverage['domains_with_contract'])}",
            f"无合同卡的域：{len(coverage['domains_without_contract'])}",
            f"覆盖率：{coverage['coverage_rate']}%",
            "",
            "-" * 70,
            "材料域门禁检查",
            "-" * 70,
            f"T1 白名单问题：{len(coverage['material_t1_issues'])}",
            f"T2 命名/联动问题：{len(coverage['material_t2_issues'])}",
            "",
        ]

        # 高完整度合同卡
        high_quality = [c for c in self.contracts_found if c["completeness_score"] >= 80]
        lines.append(f"高完整度 (≥80%): {len(high_quality)} 份")
        for contract in high_quality[:5]:
            lines.append(f"  ✓ {contract['domain_name']} ({contract['completeness_score']}%)")

        lines.append("")

        # 低完整度合同卡
        low_quality = [c for c in self.contracts_found if c["completeness_score"] < 80]
        lines.append(f"需完善 (<80%): {len(low_quality)} 份")
        for contract in low_quality[:10]:
            missing = contract["missing_fields"][:3]
            lines.append(f"  ⚠ {contract['domain_name']} - 缺失：{', '.join(missing)}")

        lines.append("")

        # 材料门禁问题
        if coverage["material_t1_issues"] or coverage["material_t2_issues"]:
            lines.append("材料域门禁问题:")
            for issue in coverage["material_t1_issues"][:10]:
                lines.append(f"  T1: {issue.get('type')} - {issue.get('message', issue.get('value', ''))}")
            for issue in coverage["material_t2_issues"][:10]:
                lines.append(f"  T2: {issue.get('type')} - {issue.get('message', issue.get('value', ''))}")

        # 缺失合同卡的域
        if coverage["domains_without_contract"]:
            lines.append("")
            lines.append("缺失合同卡的域:")
            for domain in list(coverage["domains_without_contract"])[:10]:
                lines.append(f"  ✗ {domain}")

        lines.append("")
        lines.append(f"发现问题总数：{len(interface_issues) + len(field_issues) + len(coverage['material_t1_issues']) + len(coverage['material_t2_issues'])}")
        lines.append("=" * 70)

        return "\n".join(lines)
    
    def validate_all(self) -> Dict:
        """执行完整验证"""
        return {
            "scan_result": self.scan_contracts(),
            "coverage": self.check_coverage(),
            "interface_issues": self.validate_interface_consistency(),
            "field_issues": self.check_field_completeness(),
            "material_t1_issues": self.t1_issues,
            "material_t2_issues": self.t2_issues,
            "all_contracts": self.contracts_found,
        }


def main():
    """主函数"""
    import argparse

    parser = argparse.ArgumentParser(description="UFC 合同卡完整性验证器")
    parser.add_argument("path", nargs="?", default=r"d:\TEST7\UFC", help="UFC 根目录")
    parser.add_argument("--json", action="store_true", help="JSON 输出")
    parser.add_argument("--output", "-o", help="输出文件")

    args = parser.parse_args()

    checker = ContractCompletenessChecker(args.path)

    if args.json:
        result = checker.validate_all()
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        report = checker.generate_report()
        print(report)

        if args.output:
            Path(args.output).write_text(report, encoding="utf-8")


if __name__ == "__main__":
    main()
