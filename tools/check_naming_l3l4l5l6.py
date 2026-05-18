#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC L3/L4/L5/L6 命名规范检查工具
检查模块命名、类型命名、子程序命名是否符合规范

长词根 ↔ 缩写表：``UFC/tools/naming_lexicon.py`` 中 ``LONG_NAME_ABBREV``（单一真源）。
"""
from pathlib import Path
import re
import argparse
from typing import List, Tuple, Dict

from naming_lexicon import LONG_NAME_ABBREV

# 层级前缀规范
LAYER_PREFIXES = {
    'L3_MD': 'MD_',
    'L4_PH': 'PH_',
    'L5_RT': 'RT_',
    'L6_AP': 'AP_',
}

# 域级缩写规范
DOMAIN_ABBREV = {
    'L3_MD': {
        'Material': 'Mat',
        'Output': 'Out',
        'Constraint': 'Const',
        'Instance': 'Inst',
        'Assembly': 'Assem',
        'Amplitude': 'Amp',
        'Boundary': 'BC',
        'Load': 'Ldbc',
        'Geometry': 'Geom',
        'Section': 'Sect',
        'Keyword': 'KW',
    },
    'L4_PH': {
        'Material': 'Mat',
        'Contact': 'Cont',
        'Coupling': 'Cpl',
        'Constraint': 'Constr',
        'Boundary': 'BC',
        'Mathematical': 'Math',
    },
    'L5_RT': {
        'Constraint': 'Constr',
        'Coupling': 'Cpl',
        'TimeStep': 'Time',
        'Assembly': 'Asm',
        'Increment': 'Incr',
        'Iteration': 'Iter',
    },
    'L6_AP': {
        'Output': 'Out',
        'Input': 'Inp',
        'Parser': 'Parse',
        'Material': 'Mat',
    },
}

# 模块后缀白名单
MODULE_SUFFIXES = [
    '_Core', '_Mgr', '_API', '_Type', '_Types', '_Init', '_Parse',
    '_Valid', '_Brg', '_Eval', '_Reg', '_Defn', '_Ctx', '_State',
    '_Ctrl', '_Util', '_Algo', '_Def', '_Cfg', '_Desc', '_Drv',
    '_Intf', '_Sys', '_Found', '_Adv', '_Spcl', '_High', '_Low',
]

# 禁止的后缀
FORBIDDEN_SUFFIXES = [
    '_Implementation', '_Definition', '_Manager', '_Controller',
    '_Interface', '_MathematicalFoundations', '_Complete',
]

def get_layer_from_path(path: Path) -> str:
    """从路径获取层级"""
    path_str = str(path)
    for layer in ['L3_MD', 'L4_PH', 'L5_RT', 'L6_AP']:
        if f'/{layer}/' in path_str or f'\\{layer}\\' in path_str:
            return layer
    return None


def check_module_name(module_name: str, path: Path) -> List[str]:
    """检查模块命名"""
    violations = []
    layer = get_layer_from_path(path)
    
    if not layer:
        return violations
    
    expected_prefix = LAYER_PREFIXES[layer]
    
    # 检查前缀
    if not module_name.startswith(expected_prefix):
        violations.append(
            f"Prefix: module '{module_name}' should start with '{expected_prefix}'"
        )
    
    # 检查禁止的后缀
    for suffix in FORBIDDEN_SUFFIXES:
        if module_name.endswith(suffix):
            violations.append(
                f"Suffix: module '{module_name}' uses forbidden suffix '{suffix}'"
            )
    
    # 检查长命名
    for long_name, abbrev in LONG_NAME_ABBREV.items():
        if long_name in module_name and abbrev not in module_name:
            # 排除已经正确缩写的情况
            if long_name != abbrev:  # 避免误报
                violations.append(
                    f"Abbrev: consider '{long_name}' -> '{abbrev}' in '{module_name}'"
                )
    
    # 检查域级缩写
    if layer in DOMAIN_ABBREV:
        for long_domain, abbrev in DOMAIN_ABBREV[layer].items():
            # 检查第二段（域级）是否使用了长命名
            parts = module_name.split('_')
            if len(parts) >= 2:
                if parts[1] == long_domain:
                    violations.append(
                        f"Domain: '{long_domain}' should be abbreviated to '{abbrev}' in '{module_name}'"
                    )
    
    return violations


def check_filename(filename: str, path: Path) -> List[str]:
    """检查文件命名"""
    violations = []
    stem = Path(filename).stem
    
    # 检查文件长度
    if len(stem) > 32:
        violations.append(f"Length: filename '{stem}' exceeds 32 chars")
    
    return violations


def validate_file(path: Path) -> Dict:
    """验证单个文件"""
    violations = []
    
    try:
        text = path.read_text(encoding='utf-8', errors='replace')
    except Exception as e:
        return {"path": str(path), "error": str(e), "violations": []}
    
    # 提取模块名
    module_name = None
    for line in text.splitlines():
        match = re.match(r'^\s*MODULE\s+(\w+)', line.strip(), re.I)
        if match:
            module_name = match.group(1)
            break
    
    if module_name:
        violations.extend(check_module_name(module_name, path))
    
    violations.extend(check_filename(path.name, path))
    
    return {"path": str(path), "module": module_name, "violations": violations}


def main():
    ap = argparse.ArgumentParser(description="UFC L3/L4/L5/L6 naming convention checker")
    ap.add_argument("paths", nargs="*", default=None, help="Files or dirs to check")
    ap.add_argument("--layer", choices=['L3_MD', 'L4_PH', 'L5_RT', 'L6_AP'], 
                    help="Check specific layer only")
    ap.add_argument("-q", "--quiet", action="store_true", help="Only show summary")
    args = ap.parse_args()
    
    root = Path(__file__).resolve().parent.parent
    paths = args.paths if args.paths else [str(root)]
    
    all_files = []
    for p in paths:
        path = Path(p)
        if path.is_file() and path.suffix.lower() == ".f90":
            all_files.append(path)
        elif path.is_dir():
            all_files.extend(path.rglob("*.f90"))
    
    # 过滤层级
    if args.layer:
        all_files = [f for f in all_files if args.layer in str(f)]
    
    # 只检查 L3-L6
    all_files = [f for f in all_files if any(layer in str(f) for layer in ['L3_MD', 'L4_PH', 'L5_RT', 'L6_AP'])]
    
    by_file = []
    total_violations = 0
    by_type = {'prefix': 0, 'suffix': 0, 'abbrev': 0, 'domain': 0, 'length': 0}
    
    for f in sorted(set(all_files)):
        res = validate_file(f)
        by_file.append(res)
        total_violations += len(res.get("violations", []))
        
        # 统计违规类型
        for v in res.get("violations", []):
            if "Prefix" in v:
                by_type['prefix'] += 1
            elif "Suffix" in v:
                by_type['suffix'] += 1
            elif "Abbrev" in v:
                by_type['abbrev'] += 1
            elif "Domain" in v:
                by_type['domain'] += 1
            elif "Length" in v:
                by_type['length'] += 1
    
    if not args.quiet:
        for res in by_file:
            if res.get("violations"):
                print(f"\n{res['path']}")
                if res.get("module"):
                    print(f"  Module: {res['module']}")
                for v in res["violations"][:10]:  # 只显示前 10 个
                    print(f"  - {v}")
                if len(res["violations"]) > 10:
                    print(f"  ... and {len(res['violations']) - 10} more")
    
    print(f"\n{'='*60}")
    print(f"Summary")
    print(f"{'='*60}")
    print(f"Files checked: {len(by_file)}")
    print(f"Files with violations: {len([r for r in by_file if r.get('violations')])}")
    print(f"Total violations: {total_violations}")
    print(f"\nBy type:")
    print(f"  Prefix violations: {by_type['prefix']}")
    print(f"  Suffix violations: {by_type['suffix']}")
    print(f"  Abbrev suggestions: {by_type['abbrev']}")
    print(f"  Domain violations: {by_type['domain']}")
    print(f"  Length violations: {by_type['length']}")
    
    return 1 if total_violations else 0


if __name__ == "__main__":
    exit(main())
