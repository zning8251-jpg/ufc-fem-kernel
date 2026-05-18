#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC Precision Declaration Checker
=================================
检查 Fortran 源文件的精度声明是否符合 UFC 规范

强制要求:
- 必须使用 `USE IF_Prec, ONLY: wp, i4`
- 禁止使用 `ISO_FORTRAN_ENV`
- 禁止自定义 KIND 参数 (dp, sp 等)

用法:
    python check_precision.py <file1.f90> <file2.f90> ...
    
返回:
    - 0: 所有文件通过检查
    - 1: 存在违规文件
"""

import sys
import re
from pathlib import Path

# 违规模式定义
VIOLATION_PATTERNS = [
    {
        'name': 'ISO_FORTRAN_ENV usage',
        'pattern': r'USE\s+(?:,?\s*INTRINSIC\s*)?::?\s*ISO_FORTRAN_ENV',
        'message': '❌ 禁止使用 ISO_FORTRAN_ENV，请改用 USE IF_Prec, ONLY: wp, i4',
        'severity': 'ERROR'
    },
    {
        'name': 'Custom KIND parameter',
        'pattern': r'INTEGER,\s*PARAMETER\s*::\s*(dp|sp|qp|dp_kind|real64|real32)\s*=',
        'message': '❌ 禁止自定义 KIND 参数，请使用 IF_Prec 模块的 wp',
        'severity': 'ERROR'
    },
    {
        'name': 'REAL without precision',
        'pattern': r'^\s*REAL\s+(?!\(wp\)|\(i4\)|\(sp\)|\(dp\)|\(qp\))\w',
        'message': '❌ REAL 类型必须指定精度 (如 REAL(wp))',
        'severity': 'WARNING',
        'multiline': False
    }
]

# 合规模式
COMPLIANT_PATTERN = r'USE\s+IF_Prec,\s*ONLY:\s*wp(?:\s*,\s*i4)?'


def check_file(file_path):
    """检查单个文件的精度声明"""
    violations = []
    warnings = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
    except Exception as e:
        return {
            'file': file_path,
            'valid': False,
            'error': f"无法读取文件：{e}"
        }
    
    # 检查是否包含合规的 IF_Prec 声明
    has_compliant = bool(re.search(COMPLIANT_PATTERN, content, re.IGNORECASE))
    
    # 逐行检查违规
    for line_num, line in enumerate(lines, 1):
        # 跳过注释行
        if line.strip().startswith('!'):
            continue
            
        for violation in VIOLATION_PATTERNS:
            if re.search(violation['pattern'], line, re.IGNORECASE):
                issue = {
                    'line': line_num,
                    'content': line.strip(),
                    'message': violation['message'],
                    'severity': violation['severity']
                }
                
                if violation['severity'] == 'ERROR':
                    violations.append(issue)
                else:
                    warnings.append(issue)
    
    # 如果没有合规声明但有违规，标记为失败
    if not has_compliant and violations:
        return {
            'file': file_path,
            'valid': False,
            'violations': violations,
            'warnings': warnings,
            'missing_if_prec': True
        }
    
    # 如果没有 IF_Prec 声明但也没有明显违规（可能是旧文件）
    if not has_compliant and not violations:
        # 检查是否有 USE 语句
        if re.search(r'^\s*USE\s+\w+', content, re.MULTILINE | re.IGNORECASE):
            warnings.append({
                'line': 0,
                'content': '',
                'message': '⚠️  建议使用 USE IF_Prec, ONLY: wp, i4 统一精度声明',
                'severity': 'INFO'
            })
    
    return {
        'file': file_path,
        'valid': len(violations) == 0,
        'violations': violations,
        'warnings': warnings,
        'has_if_prec': has_compliant
    }


def main():
    if len(sys.argv) < 2:
        print("❌ 错误：未指定文件")
        print("用法：python check_precision.py <file1.f90> [file2.f90 ...]")
        sys.exit(1)
    
    files = [Path(f) for f in sys.argv[1:] if f.endswith('.f90')]
    
    if not files:
        print("⚠️  没有需要检查的 .f90 文件")
        sys.exit(0)
    
    print("=" * 70)
    print("UFC 精度声明检查器")
    print("=" * 70)
    print(f"检查 {len(files)} 个 Fortran 源文件...\n")
    
    all_valid = True
    results = []
    
    for file_path in files:
        result = check_file(file_path)
        results.append(result)
        
        if not result['valid']:
            all_valid = False
            print(f"\n❌ {file_path}")
            print("-" * 70)
            
            if 'error' in result:
                print(f"   错误：{result['error']}")
                continue
            
            for violation in result.get('violations', []):
                print(f"   行 {violation['line']}: {violation['message']}")
                print(f"      内容：{violation['content']}")
            
            if result.get('missing_if_prec'):
                print(f"   ⚠️  缺少：USE IF_Prec, ONLY: wp, i4")
        
        elif result.get('warnings'):
            print(f"\n⚠️  {file_path} (有警告)")
            for warning in result['warnings']:
                if warning['severity'] == 'INFO':
                    print(f"   建议：{warning['message']}")
    
    # 总结
    print("\n" + "=" * 70)
    valid_count = sum(1 for r in results if r['valid'])
    total_count = len(results)
    
    if all_valid:
        print(f"✅ 全部通过！{valid_count}/{total_count} 个文件符合 UFC 精度规范")
    else:
        failed_count = total_count - valid_count
        print(f"❌ 检查失败！{failed_count}/{total_count} 个文件存在违规")
        print("\n修复建议:")
        print("  1. 将所有 `USE ISO_FORTRAN_ENV` 替换为 `USE IF_Prec, ONLY: wp, i4`")
        print("  2. 删除自定义的 KIND 参数定义 (dp, sp 等)")
        print("  3. 将所有 REAL(dp)/REAL(REAL64) 改为 REAL(wp)")
        print("=" * 70)
        sys.exit(1)
    
    print("=" * 70)
    sys.exit(0)


if __name__ == '__main__':
    main()
