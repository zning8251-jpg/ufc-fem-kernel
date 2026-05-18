#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC域边界分析工具
用途: 分析六层架构中各域的职责边界、接口依赖、命名合规性
版本: 1.0 | 日期: 2026-02-28
"""

import os
import re
import sys
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Set, Tuple
import csv

# 六层架构域定义 (依据UFC_NAMING_STANDARD.md)
LAYER_DOMAINS = {
    'L1_IF': ['Prec', 'Err', 'Mem', 'IO', 'Log', 'Math', 'Timer', 'Ctx', 'Dev', 'Meta', 'Platform'],
    'L2_NM': ['Brg', 'Ctx', 'Eigen', 'Integ', 'LinAlg', 'Mtx', 'Solv', 'TimeInt', 'Vec', 'Geom', 'NumInt', 'Recovery', 'Shape'],
    'L3_MD': ['Amplitude', 'Const', 'Contact', 'Ctx', 'Geom', 'Inst', 'KW', 'KeyWord', 'Ldbc', 'Mat', 'Mesh', 'Out', 'Parser', 'Part', 'Sect', 'Sets', 'Step', 'Utils', 'Brg', 'Builder'],
    'L4_PH': ['BC', 'Constr', 'Cont', 'Contact', 'Coupling', 'Ctx', 'Elem', 'Load', 'Mat', 'Math', 'TimeInt', 'Brg'],
    'L5_RT': ['Asm', 'Brg', 'Contact', 'Coupling', 'Ctx', 'Elem', 'Field', 'Incr', 'Iter', 'Job', 'Ldbc', 'Mat', 'Mesh', 'Out', 'Solv', 'State'],
    'L6_AP': ['Brg', 'Ctx', 'Flow', 'Inp', 'Out', 'Solv', 'UI']
}

# 层前缀映射
LAYER_PREFIX = {
    'L1_IF': 'IF_',
    'L2_NM': 'NM_',
    'L3_MD': 'MD_',
    'L4_PH': 'PH_',
    'L5_RT': 'RT_',
    'L6_AP': 'AP_'
}

# 角色后缀白名单
ROLE_SUFFIXES = ['Mgr', 'Core', 'Eval', 'Brg', 'API', 'Type', 'Init', 'Parse', 'Valid', 'Reg', 'Defn', 'Assem', 'Util', 'Ctrl', 'Apply', 'Solv', 'Integ']

# 四型后缀
FOUR_TYPES = ['Desc', 'State', 'Algo', 'Ctx']


class DomainBoundaryAnalyzer:
    def __init__(self, ufc_core_dir: str):
        self.ufc_core_dir = Path(ufc_core_dir)
        self.modules = {}  # {module_name: ModuleInfo}
        self.types = {}    # {type_name: TypeInfo}
        self.violations = defaultdict(list)
        
    def scan_layer(self, layer: str) -> Dict:
        """扫描指定层的所有.f90文件"""
        layer_path = self.ufc_core_dir / layer
        if not layer_path.exists():
            print(f"[WARN] Layer directory not found: {layer_path}")
            return {}
        
        results = {
            'files': [],
            'modules': [],
            'types': [],
            'procedures': [],
            'use_statements': []
        }
        
        for f90_file in layer_path.rglob('*.f90'):
            file_info = self.analyze_file(f90_file, layer)
            results['files'].append(f90_file.relative_to(self.ufc_core_dir))
            results['modules'].extend(file_info['modules'])
            results['types'].extend(file_info['types'])
            results['procedures'].extend(file_info['procedures'])
            results['use_statements'].extend(file_info['use_statements'])
        
        return results
    
    def analyze_file(self, file_path: Path, layer: str) -> Dict:
        """分析单个.f90文件"""
        info = {
            'modules': [],
            'types': [],
            'procedures': [],
            'use_statements': []
        }
        
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
        except Exception as e:
            print(f"[ERROR] Cannot read {file_path}: {e}")
            return info
        
        # 提取模块名
        modules = re.findall(r'^\s*module\s+(\w+)', content, re.MULTILINE | re.IGNORECASE)
        for mod in modules:
            if mod.lower() not in ['procedure']:  # 排除关键字
                info['modules'].append({
                    'name': mod,
                    'file': file_path.name,
                    'layer': layer
                })
        
        # 提取TYPE定义
        types = re.findall(r'^\s*type\s*(?:::)?\s*(\w+)', content, re.MULTILINE | re.IGNORECASE)
        for typ in types:
            if not typ.lower() in ['type', 'character', 'integer', 'real', 'logical']:
                info['types'].append({
                    'name': typ,
                    'file': file_path.name,
                    'layer': layer
                })
        
        # 提取子程序
        procs = re.findall(r'^\s*(?:subroutine|function)\s+(\w+)', content, re.MULTILINE | re.IGNORECASE)
        info['procedures'].extend([{'name': p, 'file': file_path.name} for p in procs])
        
        # 提取USE语句
        uses = re.findall(r'^\s*use\s+(\w+)', content, re.MULTILINE | re.IGNORECASE)
        info['use_statements'].extend([{'module': u, 'file': file_path.name, 'layer': layer} for u in uses])
        
        return info
    
    def check_naming_compliance(self, layer: str, results: Dict) -> List:
        """检查命名规范合规性"""
        violations = []
        expected_prefix = LAYER_PREFIX.get(layer, '')
        
        # 检查模块名
        for mod_info in results['modules']:
            mod_name = mod_info['name']
            issues = []
            
            # 检查1: 前缀是否正确
            if not mod_name.startswith(expected_prefix):
                issues.append(f"Missing or wrong prefix (expect {expected_prefix})")
            
            # 检查2: 是否含角色后缀
            has_suffix = any(mod_name.endswith(f'_{suffix}') for suffix in ROLE_SUFFIXES)
            has_four_type = any(mod_name.endswith(f'_{typ}') for typ in FOUR_TYPES)
            if not has_suffix and not has_four_type:
                issues.append("Missing role suffix or four-type suffix")
            
            # 检查3: 长度
            if len(mod_name) > 32:
                issues.append(f"Too long ({len(mod_name)} chars > 32)")
            
            if issues:
                violations.append({
                    'type': 'Module',
                    'name': mod_name,
                    'file': mod_info['file'],
                    'layer': layer,
                    'issues': '; '.join(issues)
                })
        
        # 检查TYPE名
        for typ_info in results['types']:
            typ_name = typ_info['name']
            issues = []
            
            # 检查: TYPE应使用四型后缀
            has_four_type = any(typ_name.endswith(f'_{t}') for t in FOUR_TYPES)
            if not has_four_type and not typ_name.endswith('Type'):
                issues.append("TYPE should use four-type suffix (_Desc/_State/_Algo/_Ctx)")
            
            # 检查: 长度
            if len(typ_name) > 32:
                issues.append(f"Too long ({len(typ_name)} chars > 32)")
            
            if issues:
                violations.append({
                    'type': 'TYPE',
                    'name': typ_name,
                    'file': typ_info['file'],
                    'layer': layer,
                    'issues': '; '.join(issues)
                })
        
        return violations
    
    def check_cross_layer_use(self, layer: str, results: Dict) -> List:
        """检查跨层USE违规"""
        violations = []
        layer_idx = list(LAYER_PREFIX.keys()).index(layer)
        
        for use_info in results['use_statements']:
            used_mod = use_info['module']
            
            # 检查是否USE了上层模块 (违规)
            for upper_layer_idx in range(layer_idx + 1, len(LAYER_PREFIX)):
                upper_prefix = LAYER_PREFIX[list(LAYER_PREFIX.keys())[upper_layer_idx]]
                if used_mod.startswith(upper_prefix):
                    violations.append({
                        'type': 'Cross-layer USE (upward)',
                        'file': use_info['file'],
                        'layer': layer,
                        'used_module': used_mod,
                        'issue': f"{layer} should not USE {list(LAYER_PREFIX.keys())[upper_layer_idx]}"
                    })
        
        return violations
    
    def analyze_domain_responsibility(self, layer: str, domain: str, results: Dict) -> Dict:
        """分析域职责 (模块数、类型数、核心功能)"""
        domain_files = [m for m in results['modules'] if domain in m['name']]
        domain_types = [t for t in results['types'] if domain in t['name']]
        
        # 统计四型覆盖
        four_type_coverage = {
            'Desc': sum(1 for t in domain_types if '_Desc' in t['name']),
            'State': sum(1 for t in domain_types if '_State' in t['name']),
            'Algo': sum(1 for t in domain_types if '_Algo' in t['name']),
            'Ctx': sum(1 for t in domain_types if '_Ctx' in t['name'])
        }
        
        return {
            'layer': layer,
            'domain': domain,
            'module_count': len(domain_files),
            'type_count': len(domain_types),
            'four_type_coverage': four_type_coverage,
            'modules': [m['name'] for m in domain_files]
        }
    
    def generate_report(self, output_dir: str):
        """生成分析报告"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        print("\n" + "="*70)
        print("UFC Domain Boundary Analysis Report")
        print("="*70)
        
        all_violations = []
        all_domain_stats = []
        
        for layer in LAYER_PREFIX.keys():
            print(f"\n[{layer}] Scanning...")
            results = self.scan_layer(layer)
            
            if not results['files']:
                print(f"  No files found in {layer}")
                continue
            
            print(f"  Files: {len(results['files'])}, Modules: {len(results['modules'])}, Types: {len(results['types'])}")
            
            # 命名合规检查
            naming_violations = self.check_naming_compliance(layer, results)
            all_violations.extend(naming_violations)
            if naming_violations:
                print(f"  [WARN] Naming violations: {len(naming_violations)}")
            
            # 跨层USE检查
            cross_layer_violations = self.check_cross_layer_use(layer, results)
            all_violations.extend(cross_layer_violations)
            if cross_layer_violations:
                print(f"  [WARN] Cross-layer USE violations: {len(cross_layer_violations)}")
            
            # 域职责分析
            for domain in LAYER_DOMAINS.get(layer, []):
                domain_stat = self.analyze_domain_responsibility(layer, domain, results)
                all_domain_stats.append(domain_stat)
        
        # 输出CSV报告
        self.write_violations_csv(all_violations, output_path / 'naming_violations.csv')
        self.write_domain_stats_csv(all_domain_stats, output_path / 'domain_statistics.csv')
        
        print("\n" + "="*70)
        print(f"[SUMMARY]")
        print(f"  Total violations: {len(all_violations)}")
        print(f"  Output directory: {output_path.resolve()}")
        print("="*70)
    
    def write_violations_csv(self, violations: List[Dict], output_file: Path):
        """输出违规清单CSV"""
        if not violations:
            print(f"[INFO] No violations found, skip writing {output_file}")
            return
        
        with open(output_file, 'w', newline='', encoding='utf-8-sig') as f:
            writer = csv.DictWriter(f, fieldnames=['type', 'name', 'file', 'layer', 'issues', 'used_module', 'issue'])
            writer.writeheader()
            for v in violations:
                writer.writerow({
                    'type': v.get('type', ''),
                    'name': v.get('name', ''),
                    'file': v.get('file', ''),
                    'layer': v.get('layer', ''),
                    'issues': v.get('issues', ''),
                    'used_module': v.get('used_module', ''),
                    'issue': v.get('issue', '')
                })
        print(f"[INFO] Violations written to {output_file}")
    
    def write_domain_stats_csv(self, stats: List[Dict], output_file: Path):
        """输出域统计CSV"""
        with open(output_file, 'w', newline='', encoding='utf-8-sig') as f:
            writer = csv.DictWriter(f, fieldnames=['layer', 'domain', 'module_count', 'type_count', 'Desc', 'State', 'Algo', 'Ctx', 'modules'])
            writer.writeheader()
            for s in stats:
                cov = s['four_type_coverage']
                writer.writerow({
                    'layer': s['layer'],
                    'domain': s['domain'],
                    'module_count': s['module_count'],
                    'type_count': s['type_count'],
                    'Desc': cov['Desc'],
                    'State': cov['State'],
                    'Algo': cov['Algo'],
                    'Ctx': cov['Ctx'],
                    'modules': '; '.join(s['modules'])
                })
        print(f"[INFO] Domain statistics written to {output_file}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python domain_boundary_analyzer.py <ufc_core_dir> [output_dir]")
        print("Example: python domain_boundary_analyzer.py d:/TEST7/UFC/ufc_core ./analysis_output")
        sys.exit(1)
    
    ufc_core_dir = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else './domain_analysis_output'
    
    analyzer = DomainBoundaryAnalyzer(ufc_core_dir)
    analyzer.generate_report(output_dir)


if __name__ == '__main__':
    main()
