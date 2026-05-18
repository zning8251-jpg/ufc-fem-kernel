#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC Domain Boundary Checker

自动化检查六层架构单向依赖铁律：
- L1_IF → L2_NM → L3_MD → L4_PH → L5_RT → L6_AP
- 禁止反向依赖（L6 → L5 → L4 → L3 → L2 → L1）
- 禁止跨层依赖（如 L1 直接 → L4）

依赖铁律：
  L1_IF:   IF_*
  L2_NM:   NM_*, IF_*
  L3_MD:   MD_*, IF_*, NM_*
  L4_PH:   PH_*, MD_*, IF_*, NM_*
  L5_RT:   RT_*, PH_*, MD_*, IF_*, NM_*
  L6_AP:   AP_*, RT_*, PH_*, MD_*, IF_*, NM_*

用法:
  python domain_boundary_checker.py                          # 检查 ufc_core
  python domain_boundary_checker.py L4_PH/Material          # 检查特定目录
  python domain_boundary_checker.py --json                   # JSON 输出
  python domain_boundary_checker.py --fix                    # 自动修复（部分）
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple, Any
from dataclasses import dataclass, field
from collections import defaultdict


# 六层定义
LAYERS = ['L1_IF', 'L2_NM', 'L3_MD', 'L4_PH', 'L5_RT', 'L6_AP']

# 层前缀映射
LAYER_PREFIXES = {
    'L1_IF': ['IF_'],
    'L2_NM': ['NM_', 'IF_'],
    'L3_MD': ['MD_', 'IF_', 'NM_'],
    'L4_PH': ['PH_', 'MD_', 'IF_', 'NM_'],
    'L5_RT': ['RT_', 'PH_', 'MD_', 'IF_', 'NM_'],
    'L6_AP': ['AP_', 'RT_', 'PH_', 'MD_', 'IF_', 'NM_'],
}

# 层索引（用于比较）
LAYER_INDEX = {layer: i for i, layer in enumerate(LAYERS)}


@dataclass
class Dependency:
    source_layer: str
    source_module: str
    target_module: str
    target_layer: str
    line: int


@dataclass
class Violation:
    layer: str
    module: str
    dependency: Dependency
    violation_type: str  # REVERSE / CROSS_LAYER
    message: str


@dataclass
class CheckResult:
    file: str
    layer: str
    module: str
    dependencies: List[Dependency] = field(default_factory=list)
    violations: List[Violation] = field(default_factory=list)
    passed: bool = True


def get_module_prefix(module_name: str) -> str:
    """从模块名提取前缀（如 MD_Ela_Iso → MD_）"""
    match = re.match(r'([A-Z]+)', module_name)
    return match.group(1) + '_' if match else ''


def get_layer_from_module(module_name: str) -> str:
    """从模块名推断层级"""
    prefix = get_module_prefix(module_name)
    for layer, prefixes in LAYER_PREFIXES.items():
        if any(module_name.startswith(p) for p in prefixes):
            return layer
    return 'UNKNOWN'


def get_allowed_layers(source_layer: str) -> Set[str]:
    """获取源层允许依赖的目标层"""
    return set(LAYER_PREFIXES.get(source_layer, []))


def is_reverse_dependency(source_layer: str, target_layer: str) -> bool:
    """检查是否是反向依赖"""
    if source_layer not in LAYER_INDEX or target_layer not in LAYER_INDEX:
        return False
    return LAYER_INDEX[target_layer] < LAYER_INDEX[source_layer]


class DomainBoundaryChecker:
    """六层架构依赖铁律检查器"""

    # 已知合法的跨域依赖（桥接模块）
    KNOWN_BRIDGES = {
        # L3 ↔ L4 Bridge
        ('L3_MD', 'L4_PH'): ['MD_PH_Bridge', 'MD_PH_Mat_Bridge', 'MD_Phy_Bridge'],
        # L4 ↔ L5 Bridge
        ('L4_PH', 'L5_RT'): ['PH_RT_Bridge', 'PH_RT_Mat_Bridge', 'PH_RT_Ldbc_Bridge'],
        # L5 ↔ L6 Bridge
        ('L5_RT', 'L6_AP'): ['RT_AP_Bridge', 'RT_AP_Solver_Bridge'],
    }

    def __init__(self, root_path: Path = None):
        self.root_path = root_path
        self.results: List[CheckResult] = []
        self.all_violations: List[Violation] = []

    def check_file(self, file_path: Path) -> CheckResult:
        """检查单个文件"""
        result = CheckResult(file=str(file_path), layer='UNKNOWN', module='')

        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            lines = content.split('\n')
        except Exception as e:
            result.violations.append(Violation(
                'UNKNOWN', '', None, 'ERROR', f"无法读取文件: {e}"
            ))
            result.passed = False
            return result

        # 提取模块名
        module_match = re.search(r'MODULE\s+(\w+)', content, re.IGNORECASE)
        if not module_match:
            return result

        module_name = module_match.group(1)
        result.module = module_name
        result.layer = get_layer_from_module(module_name)

        # 提取 USE 语句
        use_pattern = r'^\s*USE\s+(\w+)'
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue

            use_match = re.match(use_pattern, stripped, re.IGNORECASE)
            if use_match:
                used_module = use_match.group(1)
                target_layer = get_layer_from_module(used_module)

                dep = Dependency(
                    source_layer=result.layer,
                    source_module=module_name,
                    target_module=used_module,
                    target_layer=target_layer,
                    line=i
                )
                result.dependencies.append(dep)

                # 检查违规
                violation = self._check_dependency(dep, file_path)
                if violation:
                    result.violations.append(violation)
                    result.passed = False

        return result

    def _check_dependency(self, dep: Dependency, file_path: Path) -> Violation:
        """检查依赖是否违规"""
        src_idx = LAYER_INDEX.get(dep.source_layer, -1)
        tgt_idx = LAYER_INDEX.get(dep.target_layer, -1)

        # 未知层级不报错（可能是外部库）
        if src_idx == -1 or tgt_idx == -1:
            return None

        # 检查是否在已知桥接列表中
        for (bridge_src, bridge_tgt), modules in self.KNOWN_BRIDGES.items():
            if (dep.source_layer == bridge_src and dep.target_layer == bridge_tgt and
                    any(dep.target_module.startswith(m.replace('_', '')) for m in modules)):
                return None

        # 检查反向依赖
        if tgt_idx < src_idx:
            return Violation(
                layer=dep.source_layer,
                module=dep.source_module,
                dependency=dep,
                violation_type='REVERSE',
                message=f"反向依赖: {dep.source_module} (L{src_idx+1}) → "
                        f"{dep.target_module} (L{tgt_idx+1})，违反单向依赖铁律"
            )

        # 检查是否在允许列表中
        allowed = get_allowed_layers(dep.source_layer)
        if allowed and not any(dep.target_module.startswith(p[:-1]) for p in allowed):
            # 不是直接相邻层的反向，但可能是跨层
            if tgt_idx > src_idx + 1:
                return Violation(
                    layer=dep.source_layer,
                    module=dep.source_module,
                    dependency=dep,
                    violation_type='CROSS_LAYER',
                    message=f"跨层依赖: {dep.source_module} (L{src_idx+1}) → "
                            f"{dep.target_module} (L{tgt_idx+1})，跳过中间层"
                )

        return None

    def check_directory(self, dir_path: Path) -> List[CheckResult]:
        """检查目录下所有 .f90 文件"""
        results = []
        for f90_file in dir_path.rglob("*.f90"):
            result = self.check_file(f90_file)
            results.append(result)
            self.results.append(result)
            self.all_violations.extend(result.violations)
        return results

    def generate_report(self, results: List[CheckResult], json_output: bool = False) -> str:
        """生成检查报告"""
        reverse_violations = [v for v in self.all_violations if v.violation_type == 'REVERSE']
        cross_violations = [v for v in self.all_violations if v.violation_type == 'CROSS_LAYER']

        if json_output:
            data = {
                "total_files": len(results),
                "files_with_violations": sum(1 for r in results if not r.passed),
                "total_violations": len(self.all_violations),
                "reverse_violations": len(reverse_violations),
                "cross_layer_violations": len(cross_violations),
                "violations": [
                    {
                        "layer": v.layer,
                        "module": v.module,
                        "type": v.violation_type,
                        "message": v.message,
                        "line": v.dependency.line if v.dependency else 0,
                        "source": f"{v.dependency.source_module}" if v.dependency else "",
                        "target": f"{v.dependency.target_module}" if v.dependency else "",
                    }
                    for v in self.all_violations
                ]
            }
            return json.dumps(data, indent=2, ensure_ascii=False)

        # 文本报告
        lines = [
            "=" * 70,
            "UFC Domain Boundary Checker - 六层依赖铁律检查报告",
            "=" * 70,
            f"检查文件数: {len(results)}",
            f"违规文件数: {sum(1 for r in results if not r.passed)}",
            f"反向依赖: {len(reverse_violations)}",
            f"跨层依赖: {len(cross_violations)}",
            "",
        ]

        # 按层分组显示
        by_layer = defaultdict(list)
        for v in self.all_violations:
            by_layer[v.layer].append(v)

        for layer in LAYERS:
            if layer in by_layer:
                lines.append(f"\n--- {layer} ---")
                for v in by_layer[layer]:
                    lines.append(f"  {v.module} → {v.dependency.target_module} ({v.violation_type})")
                    lines.append(f"    {v.message}")

        # 依赖统计
        lines.append("\n" + "=" * 70)
        lines.append("各层依赖统计:")
        dep_counts = defaultdict(int)
        for r in results:
            dep_counts[r.layer] += len(r.dependencies)
        for layer in LAYERS:
            if dep_counts[layer]:
                lines.append(f"  {layer}: {dep_counts[layer]} 个依赖")

        lines.append("=" * 70)

        # 铁律说明
        lines.append("\n允许依赖关系:")
        for i, layer in enumerate(LAYERS):
            allowed = get_allowed_layers(layer)
            prefixes_str = ', '.join(sorted(set(p[:-1] for p in allowed if p != 'IF_')))
            lines.append(f"  {layer} → {prefixes_str}")

        lines.append("\n" + "=" * 70)
        return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description='UFC Domain Boundary Checker - 六层依赖铁律检查'
    )
    parser.add_argument('path', nargs='?', help='检查路径（文件或目录）')
    parser.add_argument('--json', action='store_true', help='JSON 输出')
    parser.add_argument('--fix', action='store_true', help='尝试自动修复')
    parser.add_argument('--ufc-root', default='../../ufc_core', help='UFC 根目录')

    args = parser.parse_args()

    # 确定路径
    if args.path:
        check_path = Path(args.path)
    else:
        ufc_root = Path(__file__).parent.parent.parent / 'ufc_core'
        check_path = ufc_root if ufc_root.exists() else Path('.')

    checker = DomainBoundaryChecker()

    if check_path.is_file():
        results = [checker.check_file(check_path)]
    else:
        results = checker.check_directory(check_path)

    print(checker.generate_report(results, json_output=args.json))

    # 退出码
    failed = sum(1 for r in results if not r.passed)
    sys.exit(1 if failed > 0 else 0)


if __name__ == '__main__':
    main()
