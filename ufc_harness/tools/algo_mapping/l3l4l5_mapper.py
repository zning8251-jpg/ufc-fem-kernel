#!/usr/bin/env python3
"""
UFC 层级打通映射器
功能: 追踪 L3_MD → L4_PH → L5_RT 的调用链和接口一致性
"""

import os
import json
import sys
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple
from collections import defaultdict


class L3L4L5Mapper:
    """层级打通映射器"""
    
    # UFC 层级定义
    LAYERS = {
        "L3_MD": {"name": "模型数据层", "prefix": "MD_"},
        "L4_PH": {"name": "物理层", "prefix": "PH_"},
        "L5_RT": {"name": "运行时层", "prefix": "RT_"}
    }
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.ufc_core = self.root_path / "ufc_core"
        self.domain_map = defaultdict(dict)
    
    def scan_domains(self) -> Dict:
        """扫描所有域级模块"""
        
        for layer_name in self.LAYERS.keys():
            layer_dir = self.ufc_core / layer_name
            
            if not layer_dir.exists():
                continue
            
            # 扫描该层级的所有子目录 (域)
            for domain_dir in layer_dir.iterdir():
                if not domain_dir.is_dir():
                    continue
                
                domain_name = domain_dir.name
                
                # 扫描 Core.f90 文件
                for f90_file in domain_dir.rglob("*Core.f90"):
                    module_info = self._analyze_f90(f90_file, layer_name, domain_name)
                    if module_info:
                        self.domain_map[domain_name][layer_name] = module_info
        
        return {
            "total_domains": len(self.domain_map),
            "by_layer": {
                layer: sum(1 for d in self.domain_map.values() if layer in d)
                for layer in self.LAYERS.keys()
            }
        }
    
    def _analyze_f90(self, file_path: Path, layer: str, domain: str) -> Dict:
        """分析 Fortran 文件中的接口信息"""
        
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
        except:
            return {}
        
        # 提取模块名
        module_match = re.search(r'module\s+(\w+)', content)
        module_name = module_match.group(1) if module_match else file_path.stem
        
        # 提取 TYPE 定义
        types = re.findall(r'type\s*::\s*(\w+)', content)
        
        # 提取 PUBLIC导出的过程
        public_procs = []
        for match in re.finditer(r'procedure\s*,\s*public\s*::\s*(\w+)', content):
            public_procs.append(match.group(1))
        
        # 提取子程序
        subroutines = re.findall(r'subroutine\s+(\w+)', content)
        
        # 提取函数
        functions = re.findall(r'function\s+(\w+)', content)
        
        # 检查是否有 USE 语句引用其他层级
        use_refs = []
        for match in re.finditer(r'use\s+(\w+)', content):
            used_module = match.group(1)
            if any(layer in used_module for layer in ["L3_", "L4_", "L5_"]):
                use_refs.append(used_module)
        
        return {
            "module": module_name,
            "file": str(file_path.relative_to(self.root_path)),
            "domain": domain,
            "types": types[:5],
            "public_procedures": public_procs[:10],
            "subroutines": subroutines[:10],
            "functions": functions[:10],
            "cross_layer_refs": use_refs[:5],
            "lines": len(content.split('\n'))
        }
    
    def check_domain_coverage(self) -> Dict:
        """检查域的跨层覆盖情况"""
        coverage = {}
        
        for domain, layers in self.domain_map.items():
            has_l3 = "L3_MD" in layers
            has_l4 = "L4_PH" in layers
            has_l5 = "L5_RT" in layers
            
            coverage[domain] = {
                "complete": has_l3 and has_l4 and has_l5,
                "layers_present": list(layers.keys()),
                "missing_layers": [
                    l for l in ["L3_MD", "L4_PH", "L5_RT"] 
                    if l not in layers
                ]
            }
        
        return coverage
    
    def analyze_cross_layer_calls(self) -> List[Dict]:
        """分析跨层调用关系"""
        call_chains = []
        
        for domain, layers in self.domain_map.items():
            # 检查 L4 是否引用 L3
            if "L4_PH" in layers and "L3_MD" in layers:
                l4_info = layers["L4_PH"]
                l3_module = layers["L3_MD"]["module"]
                
                # 检查 L4 的 USE 语句
                cross_refs = l4_info.get("cross_layer_refs", [])
                if any(l3_module.lower() in ref.lower() for ref in cross_refs):
                    call_chains.append({
                        "domain": domain,
                        "chain": "L3_MD → L4_PH",
                        "modules": [l3_module, l4_info["module"]]
                    })
            
            # 检查 L5 是否引用 L4
            if "L5_RT" in layers and "L4_PH" in layers:
                l5_info = layers["L5_RT"]
                l4_module = layers["L4_PH"]["module"]
                
                # 检查 L5 的 USE 语句
                cross_refs = l5_info.get("cross_layer_refs", [])
                if any(l4_module.lower() in ref.lower() for ref in cross_refs):
                    call_chains.append({
                        "domain": domain,
                        "chain": "L4_PH → L5_RT",
                        "modules": [l4_module, l5_info["module"]]
                    })
        
        return call_chains
    
    def generate_report(self) -> str:
        """生成报告"""
        scan_result = self.scan_domains()
        coverage = self.check_domain_coverage()
        call_chains = self.analyze_cross_layer_calls()
        
        lines = [
            "=" * 60,
            "UFC 层级打通映射报告 (L3→L4→L5)",
            "=" * 60,
            f"总域数: {scan_result['total_domains']}",
            "",
            "按层级分布:",
            f"  L3_MD: {scan_result['by_layer']['L3_MD']} 个域",
            f"  L4_PH: {scan_result['by_layer']['L4_PH']} 个域",
            f"  L5_RT: {scan_result['by_layer']['L5_RT']} 个域",
            ""
        ]
        
        # 完整覆盖的域
        complete_domains = [d for d, c in coverage.items() if c['complete']]
        lines.append(f"完整覆盖 (L3+L4+L5): {len(complete_domains)} 个域")
        for domain in complete_domains[:10]:
            lines.append(f"  ✓ {domain}")
        
        lines.append("")
        
        # 缺失层级的域
        incomplete_domains = [d for d, c in coverage.items() if not c['complete']]
        lines.append(f"部分覆盖: {len(incomplete_domains)} 个域")
        for domain in incomplete_domains[:10]:
            missing = coverage[domain]['missing_layers']
            lines.append(f"  ⚠ {domain} - 缺失: {', '.join(missing)}")
        
        lines.append("")
        lines.append(f"跨层调用链: {len(call_chains)} 条")
        for chain in call_chains[:10]:
            lines.append(f"  {chain['domain']}: {chain['chain']}")
        
        lines.append("")
        lines.append("=" * 60)
        
        return "\n".join(lines)
    
    def map_all(self) -> Dict:
        """执行完整映射"""
        return {
            "scan_result": self.scan_domains(),
            "coverage": self.check_domain_coverage(),
            "call_chains": self.analyze_cross_layer_calls(),
            "domain_details": dict(self.domain_map)
        }


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='UFC 层级打通映射器')
    parser.add_argument('path', nargs='?', default=r'd:\TEST7\UFC', help='UFC 根目录')
    parser.add_argument('--json', action='store_true', help='JSON 输出')
    parser.add_argument('--output', '-o', help='输出文件')
    
    args = parser.parse_args()
    
    mapper = L3L4L5Mapper(args.path)
    
    if args.json:
        result = mapper.map_all()
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        report = mapper.generate_report()
        print(report)
        
        if args.output:
            Path(args.output).write_text(report, encoding='utf-8')


if __name__ == "__main__":
    main()
