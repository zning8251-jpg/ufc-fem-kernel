#!/usr/bin/env python3
"""
UFC 算法追踪器
功能: 追踪算法从设计到实现的映射关系
"""

import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Set, Tuple

_UFC_HARNESS = Path(__file__).resolve().parents[2]
if str(_UFC_HARNESS) not in sys.path:
    sys.path.insert(0, str(_UFC_HARNESS))

import harness_paths  # noqa: E402


class AlgoTracingTool:
    """算法追踪工具"""
    
    # UFC 层级
    LAYERS = ["L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP"]
    
    # 算法关键词映射
    ALGO_KEYWORDS = {
        "求解器": ["Newton", "ArcLength", "LineSearch", "Lanczos", "Arnoldi", "Subspace"],
        "单元": ["Element", "Beam", "Shell", "Truss", "Continuum", "Contact"],
        "材料": ["Elastic", "Plastic", "Visco", "HyperElas", "Damage", "Creep"],
        "线性代数": ["LU", "QR", "Cholesky", "CG", "GMRES", "BiCGStab"],
        "时间积分": ["Explicit", "Implicit", "Newmark", "HHT", "BDF"]
    }
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.ufc_core = self.root_path / "ufc_core"
        self.plan = self.root_path / "PLAN"
        self.algo_map = defaultdict(list)
    
    def scan_algorithms(self) -> Dict:
        """扫描所有算法实现"""
        
        # 扫描 ufc_core 中的算法模块
        if self.ufc_core.exists():
            for layer in self.ufc_core.iterdir():
                if not layer.is_dir():
                    continue
                if layer.name not in self.LAYERS:
                    continue
                
                # 扫描该层级下的所有 .f90 文件
                for f90_file in layer.rglob("*_Core.f90"):
                    algo_info = self._analyze_f90_file(f90_file, layer.name)
                    if algo_info:
                        self.algo_map[layer.name].append(algo_info)
        
        return {
            "total_algorithms": sum(len(v) for v in self.algo_map.values()),
            "by_layer": {k: len(v) for k, v in self.algo_map.items()}
        }
    
    def _analyze_f90_file(self, file_path: Path, layer: str) -> Dict:
        """分析 Fortran 文件中的算法信息"""
        
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
        except:
            return None
        
        # 提取模块名
        module_match = re.search(r'module\s+(\w+)', content)
        module_name = module_match.group(1) if module_match else file_path.stem
        
        # 提取 TYPE 定义
        types = re.findall(r'type\s*::\s*(\w+)', content)
        
        # 提取子程序
        subroutines = re.findall(r'subroutine\s+(\w+)', content)
        
        # 提取函数
        functions = re.findall(r'function\s+(\w+)', content)
        
        # 识别算法类别
        algo_category = None
        for category, keywords in self.ALGO_KEYWORDS.items():
            for kw in keywords:
                if kw.lower() in module_name.lower():
                    algo_category = category
                    break
            if algo_category:
                break
        
        return {
            "module": module_name,
            "file": str(file_path.relative_to(self.root_path)),
            "layer": layer,
            "category": algo_category,
            "types": types[:5],  # 限制数量
            "subroutines": subroutines[:5],
            "functions": functions[:5],
            "lines": len(content.split('\n'))
        }
    
    def generate_algo_map(self) -> Dict:
        """生成算法图谱"""
        self.scan_algorithms()
        
        # 扫描 PLAN 中的算法设计文档
        algo_docs = []
        if self.plan.exists():
            for doc in self.plan.rglob("*.md"):
                try:
                    content = doc.read_text(encoding='utf-8', errors='ignore')
                    # 检查是否包含算法相关关键词
                    for category, keywords in self.ALGO_KEYWORDS.items():
                        for kw in keywords:
                            if kw.lower() in content.lower():
                                algo_docs.append({
                                    "doc": str(doc.relative_to(self.plan)),
                                    "category": category
                                })
                                break
                except:
                    pass
        
        return {
            "algorithm_implementations": self.algo_map,
            "algorithm_docs": algo_docs[:20],  # 限制数量
            "total_implementations": sum(len(v) for v in self.algo_map.values()),
            "total_docs": len(algo_docs)
        }
    
    def generate_report(self) -> str:
        """生成文本报告"""
        result = self.generate_algo_map()
        
        lines = [
            "=" * 60,
            "UFC 算法落地图谱",
            "=" * 60,
            f"算法实现总数: {result['total_implementations']}",
            f"算法设计文档: {result['total_docs']}",
            "",
            "按层级分布:"
        ]
        
        for layer in self.LAYERS:
            count = len(self.algo_map.get(layer, []))
            if count > 0:
                lines.append(f"  {layer}: {count} 个实现")
                for algo in self.algo_map.get(layer, [])[:3]:
                    lines.append(f"    - {algo['module']} ({algo.get('category', 'N/A')})")
        
        lines.append("")
        lines.append("=" * 60)
        
        return "\n".join(lines)


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='UFC 算法追踪器')
    parser.add_argument(
        'path',
        nargs='?',
        default=None,
        help='UFC 根目录（默认：ufc_harness 的父目录）',
    )
    parser.add_argument('--json', action='store_true', help='JSON 输出')
    parser.add_argument('--output', '-o', help='输出文件')
    
    args = parser.parse_args()
    root = args.path or str(harness_paths.ufc_root())
    tool = AlgoTracingTool(root)
    
    if args.json:
        result = tool.generate_algo_map()
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        report = tool.generate_report()
        print(report)
        
        if args.output:
            Path(args.output).write_text(report, encoding='utf-8')


if __name__ == "__main__":
    main()
