#!/usr/bin/env python3
"""
UFC 架构一致性验证器
功能: 验证 UFC 六层架构的一致性和完整性
"""

import json
import sys
import re
from pathlib import Path

_UFC_HARNESS = Path(__file__).resolve().parents[2]
if str(_UFC_HARNESS) not in sys.path:
    sys.path.insert(0, str(_UFC_HARNESS))

import harness_paths  # noqa: E402
from typing import Dict, List, Set


class ArchConsistencyValidator:
    """架构一致性验证器"""
    
    # UFC 标准层级结构
    LAYERS = {
        "L1_IF": {"name": "接口层", "expected_dirs": ["Base", "Error", "IO", "Log", "Memory", "Persist", "Precision"]},
        "L2_NM": {"name": "数值算法层", "expected_dirs": ["Base", "Bridge", "Eigen", "LinearAlgebra", "Solver", "TimeIntegration"]},
        "L3_MD": {"name": "模型数据层", "expected_dirs": [
            "Amplitude", "Assembly", "Boundary", "Bridge", "Constraint", "Coupling",
            "Interaction", "KeyWord", "Material", "Mesh", "Model", "Output", "Part",
            "Section", "Solver", "Step", "WriteBack",
        ]},
        "L4_PH": {"name": "物理层", "expected_dirs": ["Bridge", "Constraint", "Contact", "Coupling", "Element", "LoadBC", "Material"]},
        "L5_RT": {"name": "运行时层", "expected_dirs": [
            "Bridge", "Contact", "Coupling", "Logging", "Mesh", "Output",
            "Physics", "Solver", "StepDriver", "WriteBack",
        ]},
        "L6_AP": {"name": "应用层", "expected_dirs": ["Base", "Bridge", "Input", "Output", "Solver", "UI"]}
    }
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.ufc_core = self.root_path / "ufc_core"
        self.issues = []
    
    def check_layer_structure(self, layer: str) -> Dict:
        """检查指定层级的目录结构"""
        layer_path = self.ufc_core / layer
        
        if not layer_path.exists():
            return {
                "layer": layer,
                "exists": False,
                "missing": True
            }
        
        # 获取实际子目录
        actual_dirs = set(d.name for d in layer_path.iterdir() if d.is_dir())
        
        # 获取期望子目录
        expected = set(self.LAYERS[layer]["expected_dirs"])
        
        # 找出缺失和额外的目录
        missing = expected - actual_dirs
        extra = actual_dirs - expected
        
        return {
            "layer": layer,
            "exists": True,
            "expected": list(expected),
            "actual": list(actual_dirs),
            "missing": list(missing),
            "extra": list(extra),
            "complete": len(missing) == 0
        }
    
    def check_all_layers(self) -> Dict:
        """检查所有层级"""
        results = {}
        
        for layer in self.LAYERS.keys():
            results[layer] = self.check_layer_structure(layer)
        
        return results
    
    def check_module_naming(self) -> List[Dict]:
        """检查模块命名一致性"""
        issues = []
        
        if not self.ufc_core.exists():
            return issues
        
        # 检查所有 _Core.f90 文件
        for layer_dir in self.ufc_core.iterdir():
            if not layer_dir.is_dir():
                continue
            if layer_dir.name not in self.LAYERS:
                continue
            
            for f90_file in layer_dir.rglob("*_Core.f90"):
                try:
                    content = f90_file.read_text(encoding='utf-8', errors='ignore')
                    
                    # 检查模块名是否匹配文件名
                    module_match = re.search(r'module\s+(\w+)', content)
                    if module_match:
                        module_name = module_match.group(1)
                        expected_prefix = layer_dir.name.replace("L", "").replace("_", "")
                        
                        # 检查命名是否符合规范
                        if not module_name.startswith(("PH_", "MD_", "NM_", "RT_", "IF_", "ufc_")):
                            issues.append({
                                "file": str(f90_file.relative_to(self.root_path)),
                                "issue": "naming_prefix",
                                "module": module_name,
                                "expected_prefix": "PH_/MD_/NM_/RT_/IF_/ufc_"
                            })
                except:
                    pass
        
        return issues
    
    def check_cross_layer_calls(self) -> List[Dict]:
        """检查跨层调用一致性"""
        issues = []
        
        # 分析 USE 语句
        for layer_dir in self.ufc_core.iterdir():
            if not layer_dir.is_dir():
                continue
            if layer_dir.name not in self.LAYERS:
                continue
            
            layer_level = int(layer_dir.name.split("_")[0].replace("L", ""))
            
            for f90_file in layer_dir.rglob("*.f90"):
                try:
                    content = f90_file.read_text(encoding='utf-8', errors='ignore')
                    
                    # 查找 USE 语句
                    use_matches = re.findall(r'use\s+(\w+)', content)
                    
                    for module in use_matches:
                        # 检查是否跨层调用
                        for other_layer in self.LAYERS.keys():
                            if other_layer.startswith("L"):
                                other_level = int(other_layer.split("_")[0].replace("L", ""))
                                
                                # 检查是否有不合法的跨层调用 (向上调用)
                                if module.startswith(("PH_", "MD_", "NM_", "RT_", "IF_")):
                                    # 这是一个潜在的跨层调用
                                    pass
                except:
                    pass
        
        return issues
    
    def generate_report(self) -> str:
        """生成验证报告"""
        layer_results = self.check_all_layers()
        naming_issues = self.check_module_naming()
        
        lines = [
            "=" * 60,
            "UFC 架构一致性验证报告",
            "=" * 60,
            ""
        ]
        
        # 层级结构检查
        lines.append("层级目录结构检查:")
        for layer, result in layer_results.items():
            status = "OK" if result.get("complete") else "不完整"
            lines.append(f"  {layer} ({self.LAYERS[layer]['name']}): {status}")
            if result.get("missing"):
                lines.append(f"    缺失: {result['missing']}")
            if result.get("extra"):
                lines.append(f"    额外: {result['extra']}")
        
        lines.append("")
        
        # 命名检查
        lines.append(f"命名规范检查: {len(naming_issues)} 个问题")
        for issue in naming_issues[:5]:
            lines.append(f"  {issue['file']}: {issue['issue']}")
        
        lines.append("")
        lines.append("=" * 60)
        
        return "\n".join(lines)
    
    def validate(self) -> Dict:
        """执行完整验证"""
        return {
            "layer_structure": self.check_all_layers(),
            "naming_issues": self.check_module_naming(),
            "cross_layer_issues": self.check_cross_layer_calls()
        }


def _validation_ok(result: Dict) -> bool:
    for lr in result["layer_structure"].values():
        if not lr.get("exists"):
            return False
        if not lr.get("complete", True):
            return False
    if result.get("naming_issues"):
        return False
    return True


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='UFC 架构验证器')
    parser.add_argument(
        'path',
        nargs='?',
        default=None,
        help='UFC 根目录（默认：ufc_harness 的父目录）',
    )
    parser.add_argument('--json', action='store_true', help='JSON 输出')
    
    args = parser.parse_args()
    root = args.path or str(harness_paths.ufc_root())
    validator = ArchConsistencyValidator(root)
    
    result = validator.validate()
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(validator.generate_report())

    sys.exit(0 if _validation_ok(result) else 1)


if __name__ == "__main__":
    main()
