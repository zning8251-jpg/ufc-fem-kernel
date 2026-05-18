#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC域级功能深度分析工具
功能: 
  1. 扫描域内所有.f90文件的Module及其子程序
  2. 分析子程序职责 (Init/Eval/Get/Set/Build...)
  3. 识别重复/相似功能
  4. 生成重构建议 (合并/拆分/重命名)
版本: 1.0 | 日期: 2026-02-28
"""

import os
import re
import sys
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Set, Tuple
import json

# 子程序职责分类 (依据UFC_NAMING_STANDARD.md)
PROC_CATEGORIES = {
    'Init': ['init', 'initialize', 'setup', 'create', 'alloc'],
    'Destroy': ['destroy', 'cleanup', 'free', 'dealloc', 'finalize', 'clear'],
    'Get': ['get', 'query', 'retrieve', 'fetch', 'find', 'search', 'lookup'],
    'Set': ['set', 'update', 'modify', 'change', 'assign'],
    'Add': ['add', 'insert', 'append', 'register', 'push'],
    'Remove': ['remove', 'delete', 'unregister', 'pop'],
    'Eval': ['eval', 'evaluate', 'compute', 'calculate', 'calc'],
    'Build': ['build', 'construct', 'assemble', 'form'],
    'Apply': ['apply', 'impose', 'enforce'],
    'Valid': ['valid', 'validate', 'check', 'verify'],
    'Parse': ['parse', 'read', 'load'],
    'Write': ['write', 'save', 'dump', 'export'],
    'Convert': ['convert', 'transform', 'map'],
    'Copy': ['copy', 'clone', 'duplicate']
}

class ProcedureInfo:
    """子程序信息"""
    def __init__(self, name: str, proc_type: str, line_start: int, line_end: int):
        self.name = name
        self.proc_type = proc_type  # subroutine or function
        self.line_start = line_start
        self.line_end = line_end
        self.category = self._categorize()
        self.params = []
        self.comment = ""
        
    def _categorize(self) -> str:
        """根据名称推断职责类别"""
        name_lower = self.name.lower()
        for category, keywords in PROC_CATEGORIES.items():
            if any(kw in name_lower for kw in keywords):
                return category
        return 'Other'
    
    def __repr__(self):
        return f"{self.proc_type} {self.name} [{self.category}] (L{self.line_start}-{self.line_end})"


class ModuleInfo:
    """模块信息"""
    def __init__(self, name: str, file_path: Path):
        self.name = name
        self.file_path = file_path
        self.procedures: List[ProcedureInfo] = []
        self.types = []
        self.use_statements = []
        self.public_symbols = []
        self.line_count = 0
        
    def add_procedure(self, proc: ProcedureInfo):
        self.procedures.append(proc)
    
    def get_procs_by_category(self, category: str) -> List[ProcedureInfo]:
        return [p for p in self.procedures if p.category == category]
    
    def __repr__(self):
        return f"Module {self.name}: {len(self.procedures)} procs, {self.line_count} lines"


class DomainFunctionAnalyzer:
    """域级功能深度分析器"""
    
    def __init__(self, ufc_core_dir: str):
        self.ufc_core_dir = Path(ufc_core_dir)
        self.modules: Dict[str, ModuleInfo] = {}
        self.domain_summary = defaultdict(lambda: {
            'modules': [],
            'total_procs': 0,
            'proc_by_category': defaultdict(int),
            'duplicates': [],
            'refactor_suggestions': []
        })
    
    def analyze_file(self, file_path: Path) -> List[ModuleInfo]:
        """深度分析单个.f90文件"""
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            lines = content.split('\n')
        except Exception as e:
            print(f"[ERROR] Cannot read {file_path}: {e}")
            return []
        
        modules = []
        current_module = None
        in_contains = False
        proc_stack = []
        
        for i, line in enumerate(lines, 1):
            line_stripped = line.strip()
            line_lower = line_stripped.lower()
            
            # 检测module声明
            if re.match(r'^\s*module\s+(\w+)', line_lower):
                match = re.match(r'^\s*module\s+(\w+)', line_stripped, re.IGNORECASE)
                if match and match.group(1).lower() != 'procedure':
                    mod_name = match.group(1)
                    current_module = ModuleInfo(mod_name, file_path)
                    modules.append(current_module)
            
            # 检测contains
            elif line_lower.startswith('contains'):
                in_contains = True
            
            # 检测子程序/函数开始
            elif in_contains and current_module:
                sub_match = re.match(r'^\s*(subroutine|function)\s+(\w+)', line_lower)
                if sub_match:
                    proc_type = sub_match.group(1)
                    proc_name = re.match(r'^\s*(?:subroutine|function)\s+(\w+)', line_stripped, re.IGNORECASE).group(1)
                    proc = ProcedureInfo(proc_name, proc_type, i, -1)
                    proc_stack.append(proc)
            
            # 检测子程序/函数结束
            elif proc_stack:
                if re.match(r'^\s*end\s+(subroutine|function)', line_lower):
                    proc = proc_stack.pop()
                    proc.line_end = i
                    current_module.add_procedure(proc)
            
            # 检测module结束
            elif current_module and re.match(r'^\s*end\s+module', line_lower):
                current_module.line_count = i
                current_module = None
                in_contains = False
        
        return modules
    
    def scan_domain(self, layer: str, domain: str) -> Dict:
        """扫描指定域的所有文件"""
        domain_path = self.ufc_core_dir / layer / domain
        if not domain_path.exists():
            print(f"[WARN] Domain path not found: {domain_path}")
            return {}
        
        print(f"\n{'='*70}")
        print(f"[{layer}/{domain}] Analyzing...")
        print(f"{'='*70}")
        
        all_modules = []
        for f90_file in domain_path.rglob('*.f90'):
            modules = self.analyze_file(f90_file)
            all_modules.extend(modules)
            for mod in modules:
                self.modules[mod.name] = mod
        
        # 汇总统计
        summary = self.domain_summary[f"{layer}/{domain}"]
        summary['modules'] = [m.name for m in all_modules]
        
        for mod in all_modules:
            summary['total_procs'] += len(mod.procedures)
            for proc in mod.procedures:
                summary['proc_by_category'][proc.category] += 1
        
        # 识别重复功能
        self._find_duplicates(all_modules, summary)
        
        # 生成重构建议
        self._generate_refactor_suggestions(all_modules, summary)
        
        return summary
    
    def _find_duplicates(self, modules: List[ModuleInfo], summary: Dict):
        """识别重复/相似功能的子程序"""
        proc_by_name = defaultdict(list)
        
        for mod in modules:
            for proc in mod.procedures:
                # 简化名称 (移除前缀后比较)
                simplified = re.sub(r'^(MD_|PH_|RT_|IF_|NM_|AP_)', '', proc.name, flags=re.IGNORECASE)
                proc_by_name[simplified.lower()].append((mod.name, proc.name, proc.category))
        
        # 找出重复项
        for simplified, occurrences in proc_by_name.items():
            if len(occurrences) > 1:
                summary['duplicates'].append({
                    'simplified_name': simplified,
                    'count': len(occurrences),
                    'occurrences': occurrences
                })
    
    def _generate_refactor_suggestions(self, modules: List[ModuleInfo], summary: Dict):
        """生成重构建议"""
        suggestions = []
        
        # 建议1: 合并只有少量过程的模块
        small_modules = [m for m in modules if len(m.procedures) < 3 and len(m.procedures) > 0]
        if len(small_modules) > 1:
            suggestions.append({
                'type': 'MERGE_SMALL_MODULES',
                'reason': f"Found {len(small_modules)} modules with <3 procedures",
                'modules': [m.name for m in small_modules],
                'action': "Consider merging into a single module with proper suffix"
            })
        
        # 建议2: 拆分超大模块 (>1000行或>20个过程)
        large_modules = [m for m in modules if m.line_count > 1000 or len(m.procedures) > 20]
        for m in large_modules:
            suggestions.append({
                'type': 'SPLIT_LARGE_MODULE',
                'reason': f"{m.name}: {m.line_count} lines, {len(m.procedures)} procs",
                'module': m.name,
                'action': "Split by category (Init/Eval/Get/Set/...) into separate modules"
            })
        
        # 建议3: 职责混杂的模块 (同时有Init/Eval/Mgr功能)
        for m in modules:
            categories = set(p.category for p in m.procedures)
            if 'Init' in categories and 'Eval' in categories:
                has_mgr = any(kw in m.name.lower() for kw in ['mgr', 'manager', 'sys', 'system'])
                if not has_mgr:
                    suggestions.append({
                        'type': 'MIXED_RESPONSIBILITY',
                        'reason': f"{m.name} has both Init and Eval procedures",
                        'module': m.name,
                        'categories': list(categories),
                        'action': "Split into *_Init and *_Eval modules, or rename to *_Mgr if managing lifecycle"
                    })
        
        # 建议4: 命名不规范的模块
        for m in modules:
            name = m.name
            # 检查后缀
            has_suffix = any(name.endswith(f'_{sfx}') for sfx in ['Mgr', 'Core', 'Eval', 'Brg', 'API', 'Type', 'Algo'])
            if not has_suffix and len(m.procedures) > 0:
                # 根据职责推荐后缀
                categories = [p.category for p in m.procedures]
                dominant = max(set(categories), key=categories.count) if categories else 'Other'
                
                if dominant == 'Init' and 'Destroy' in categories:
                    suggested_suffix = 'Mgr'
                elif dominant == 'Eval':
                    suggested_suffix = 'Eval' if len(m.procedures) < 5 else 'Core'
                elif dominant == 'Get' or dominant == 'Set':
                    suggested_suffix = 'API'
                elif dominant == 'Build':
                    suggested_suffix = 'Core'
                else:
                    suggested_suffix = 'Core'
                
                suggestions.append({
                    'type': 'MISSING_SUFFIX',
                    'module': name,
                    'dominant_category': dominant,
                    'suggested_suffix': suggested_suffix,
                    'action': f"Rename to {name}_{suggested_suffix}"
                })
        
        summary['refactor_suggestions'] = suggestions
    
    def print_domain_report(self, layer: str, domain: str):
        """打印域分析报告"""
        key = f"{layer}/{domain}"
        summary = self.domain_summary[key]
        
        print(f"\n{'='*70}")
        print(f"Domain Report: {key}")
        print(f"{'='*70}")
        print(f"Modules: {len(summary['modules'])}")
        print(f"Total Procedures: {summary['total_procs']}")
        
        print(f"\nProcedures by Category:")
        for cat, count in sorted(summary['proc_by_category'].items(), key=lambda x: -x[1]):
            print(f"  {cat:15s}: {count:3d}")
        
        if summary['duplicates']:
            print(f"\n⚠️  Potential Duplicates ({len(summary['duplicates'])}):")
            for dup in summary['duplicates'][:5]:  # 只显示前5个
                print(f"  '{dup['simplified_name']}' appears {dup['count']} times:")
                for mod, proc, cat in dup['occurrences']:
                    print(f"    - {mod}.{proc} [{cat}]")
        
        if summary['refactor_suggestions']:
            print(f"\n💡 Refactor Suggestions ({len(summary['refactor_suggestions'])}):")
            for i, sug in enumerate(summary['refactor_suggestions'][:10], 1):  # 只显示前10个
                print(f"  {i}. [{sug['type']}] {sug.get('module', sug.get('modules', ''))}")
                print(f"     Reason: {sug['reason']}")
                print(f"     Action: {sug['action']}")
    
    def export_report(self, output_file: str):
        """导出完整分析报告为JSON"""
        report = {
            'summary': dict(self.domain_summary),
            'modules': {name: {
                'file': str(mod.file_path),
                'procedures': [
                    {
                        'name': p.name,
                        'type': p.proc_type,
                        'category': p.category,
                        'lines': f"{p.line_start}-{p.line_end}"
                    } for p in mod.procedures
                ],
                'line_count': mod.line_count
            } for name, mod in self.modules.items()}
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n[INFO] Full report exported to {output_file}")


def main():
    if len(sys.argv) < 4:
        print("Usage: python domain_function_analyzer.py <ufc_core_dir> <layer> <domain>")
        print("Example: python domain_function_analyzer.py d:/TEST7/UFC/ufc_core L3_MD Mat")
        print("\nOr analyze all domains in a layer:")
        print("       python domain_function_analyzer.py d:/TEST7/UFC/ufc_core L4_PH --all")
        sys.exit(1)
    
    ufc_core_dir = sys.argv[1]
    layer = sys.argv[2]
    domain_or_flag = sys.argv[3]
    
    analyzer = DomainFunctionAnalyzer(ufc_core_dir)
    
    if domain_or_flag == '--all':
        # 分析该层所有域
        from domain_boundary_analyzer import LAYER_DOMAINS
        domains = LAYER_DOMAINS.get(layer, [])
        for domain in domains:
            analyzer.scan_domain(layer, domain)
            analyzer.print_domain_report(layer, domain)
    else:
        # 分析指定域
        domain = domain_or_flag
        analyzer.scan_domain(layer, domain)
        analyzer.print_domain_report(layer, domain)
    
    # 导出完整报告
    output_file = f"./domain_analysis_{layer}_{domain_or_flag}.json"
    analyzer.export_report(output_file)


if __name__ == '__main__':
    main()
