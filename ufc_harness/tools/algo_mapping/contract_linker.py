#!/usr/bin/env python3
"""
UFC 合同卡关联器
功能: 将合同卡定义与代码实现关联
"""

import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set

_UFC_HARNESS = Path(__file__).resolve().parents[2]
if str(_UFC_HARNESS) not in sys.path:
    sys.path.insert(0, str(_UFC_HARNESS))

import harness_paths  # noqa: E402


class ContractLinker:
    """合同卡关联器"""
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.ufc_core = self.root_path / "ufc_core"
        self.plan = self.root_path / "PLAN"
    
    def find_contracts(self) -> List[Dict]:
        """查找所有合同卡文档"""
        contracts = []
        
        if not self.plan.exists():
            return contracts
        
        # 搜索合同卡文件
        for doc in self.plan.rglob("*合同卡*.md"):
            contracts.append({
                "file": str(doc.relative_to(self.plan)),
                "name": doc.stem
            })
        
        # 搜索 contracts 目录
        contracts_dir = self.plan / "02_域级建模与实施清单"
        if contracts_dir.exists():
            for doc in contracts_dir.rglob("*contract*.md"):
                contracts.append({
                    "file": str(doc.relative_to(self.plan)),
                    "name": doc.stem
                })
        
        return contracts
    
    def find_impl_files(self, domain: str) -> List[Dict]:
        """查找对应的实现文件"""
        impls = []
        
        if not self.ufc_core.exists():
            return impls
        
        # 在各层级中搜索
        for layer_dir in self.ufc_core.iterdir():
            if not layer_dir.is_dir():
                continue
            
            # 搜索包含 domain 关键字的文件
            for f90_file in layer_dir.rglob("*Core.f90"):
                if domain.lower() in f90_file.name.lower():
                    impls.append({
                        "file": str(f90_file.relative_to(self.root_path)),
                        "module": f90_file.stem,
                        "layer": layer_dir.name
                    })
        
        return impls
    
    def generate_link_map(self) -> Dict:
        """生成合同卡到实现的映射"""
        contracts = self.find_contracts()
        
        # 分析每个合同卡关联的实现
        links = []
        for contract in contracts:
            # 提取域名
            domain_match = re.search(r'[Ll][0-9]_[Pp][Hh]?_?(\w+)', contract['name'])
            if domain_match:
                domain = domain_match.group(1)
            else:
                domain = contract['name'].split('_')[0] if '_' in contract['name'] else contract['name']
            
            # 查找对应实现
            impls = self.find_impl_files(domain)
            
            links.append({
                "contract": contract,
                "domain": domain,
                "implementations": impls[:5]
            })
        
        return {
            "total_contracts": len(contracts),
            "linked": sum(1 for l in links if l['implementations']),
            "unlinked": sum(1 for l in links if not l['implementations']),
            "links": links[:20]
        }
    
    def generate_report(self) -> str:
        """生成报告"""
        result = self.generate_link_map()
        
        lines = [
            "=" * 60,
            "UFC 合同卡关联映射",
            "=" * 60,
            f"合同卡总数: {result['total_contracts']}",
            f"已关联: {result['linked']}",
            f"未关联: {result['unlinked']}",
            "",
            "关联详情 (前10):"
        ]
        
        for link in result['links'][:10]:
            lines.append(f"\n[{link['contract']['name']}]")
            lines.append(f"  域名: {link['domain']}")
            if link['implementations']:
                for impl in link['implementations'][:3]:
                    lines.append(f"  -> {impl['module']} ({impl['layer']})")
            else:
                lines.append("  -> 未找到实现")
        
        lines.append("")
        lines.append("=" * 60)
        
        return "\n".join(lines)


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='UFC 合同卡关联器')
    parser.add_argument(
        'path',
        nargs='?',
        default=None,
        help='UFC 根目录（默认：ufc_harness 的父目录）',
    )
    parser.add_argument('--json', action='store_true', help='JSON 输出')
    
    args = parser.parse_args()
    root = args.path or str(harness_paths.ufc_root())
    linker = ContractLinker(root)
    
    if args.json:
        result = linker.generate_link_map()
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        report = linker.generate_report()
        print(report)


if __name__ == "__main__":
    main()
