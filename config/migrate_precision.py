#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC Precision Declaration Migrator
==================================
批量迁移 Fortran 源文件的精度声明到 UFC 标准格式

功能:
- 将 `USE ISO_FORTRAN_ENV` 替换为 `USE IF_Prec, ONLY: wp, i4`
- 将 `REAL(REAL64)` / `REAL(dp)` 替换为 `REAL(wp)`
- 删除自定义的 KIND 参数定义

用法:
    python migrate_precision.py <file1.f90> [file2.f90 ...]
    
或批量处理整个目录:
    python migrate_precision.py --dir UFC/ufc_core/L4_PH
"""

import sys
import re
from pathlib import Path
import argparse


def migrate_content(content):
    """迁移文件内容到 UFC 标准精度格式"""
    original = content
    
    # 替换模式列表
    replacements = [
        # 1. 替换 ISO_FORTRAN_ENV 的各种形式
        (r'USE\s*,?\s*INTRINSIC\s*::\s*ISO_FORTRAN_ENV\s*,\s*ONLY:\s*wp\s*=>\s*REAL64',
         'USE IF_Prec, ONLY: wp, i4'),
        (r'USE\s*ISO_FORTRAN_ENV\s*,\s*ONLY:\s*wp\s*=>\s*REAL64',
         'USE IF_Prec, ONLY: wp, i4'),
        (r'USE\s*ISO_FORTRAN_ENV\s*,\s*ONLY:\s*REAL64,\s*INT32,\s*INT64',
         'USE IF_Prec, ONLY: wp, i4'),
        (r'USE\s*,?\s*INTRINSIC\s*::\s*ISO_FORTRAN_ENV\s*,\s*ONLY:\s*INT64',
         '! USE IF_Prec, ONLY: i4  # INT64 已弃用，使用 i4'),
        (r'USE\s*ISO_FORTRAN_ENV',
         'USE IF_Prec, ONLY: wp, i4'),
        
        # 2. 替换 REAL64/dp/sp 为 wp
        (r'\bREAL\s*\(\s*REAL64\s*\)', 'REAL(wp)'),
        (r'\bREAL\s*\(\s*dp\s*\)', 'REAL(wp)'),
        (r'\bREAL\s*\(\s*sp\s*\)', 'REAL(sp)'),
        (r'\bREAL\s*\(\s*qp\s*\)', 'REAL(qp)'),
        
        # 3. 替换字面量后缀
        (r'\b(\d+\.\d*)_REAL64\b', r'\1_wp'),
        (r'\b(\d+\.\d*)_REAL32\b', r'\1_sp'),
        (r'\b(\d+\.\d*)_dp\b', r'\1_wp'),
        (r'\b(\d+\.\d*)_sp\b', r'\1_sp'),
        
        # 4. 替换 INTEGER 类型
        (r'\bINTEGER\s*\(\s*INT32\s*\)', 'INTEGER(i4)'),
        (r'\bINTEGER\s*\(\s*INT64\s*\)', 'INTEGER(i8)'),
    ]
    
    modified = content
    for pattern, replacement in replacements:
        modified = re.sub(pattern, replacement, modified, flags=re.IGNORECASE)
    
    return modified, modified != original


def migrate_file(file_path, dry_run=False):
    """迁移单个文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return False, f"无法读取文件：{e}"
    
    new_content, changed = migrate_content(content)
    
    if not changed:
        return True, "无需修改（已符合规范）"
    
    if dry_run:
        return True, f"需要修改（预览模式）"
    
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True, "✓ 已迁移"
    except Exception as e:
        return False, f"写入失败：{e}"


def find_fortran_files(directory):
    """递归查找目录下所有 .f90 文件"""
    dir_path = Path(directory)
    if not dir_path.exists():
        return []
    
    files = list(dir_path.rglob('*.f90')) + list(dir_path.rglob('*.F90'))
    return sorted(files)


def main():
    parser = argparse.ArgumentParser(description='UFC 精度声明迁移工具')
    parser.add_argument('files', nargs='*', help='要迁移的 .f90 文件')
    parser.add_argument('--dir', '-d', help='要迁移的目录（递归查找所有 .f90）')
    parser.add_argument('--dry-run', '-n', action='store_true', 
                       help='预览模式，不实际修改文件')
    
    args = parser.parse_args()
    
    # 收集文件
    files = []
    if args.files:
        files.extend([Path(f) for f in args.files if Path(f).exists()])
    if args.dir:
        files.extend(find_fortran_files(args.dir))
    
    if not files:
        print("❌ 错误：未指定文件或目录")
        print("用法：python migrate_precision.py <file1.f90> [--dir directory] [-n]")
        sys.exit(1)
    
    # 去重
    files = list(set(files))
    
    print("=" * 70)
    print("UFC 精度声明迁移工具")
    print("=" * 70)
    
    if args.dry_run:
        print("🔍 预览模式（不会实际修改文件）")
    print(f"准备处理 {len(files)} 个文件...\n")
    
    success_count = 0
    modified_count = 0
    
    for file_path in files:
        success, message = migrate_file(file_path, dry_run=args.dry_run)
        
        if success:
            success_count += 1
            if "需要修改" in message or "✓" in message:
                modified_count += 1
                status = "📝" if args.dry_run else "✓"
                print(f"{status} {file_path}: {message}")
        else:
            print(f"❌ {file_path}: {message}")
    
    # 总结
    print("\n" + "=" * 70)
    if args.dry_run:
        print(f"预览完成：{modified_count}/{len(files)} 个文件需要修改")
        print("\n执行实际迁移:")
        print(f"  python migrate_precision.py {' '.join(str(f) for f in files[:5])}{'...' if len(files) > 5 else ''}")
    else:
        print(f"迁移完成：{modified_count}/{len(files)} 个文件已修改")
        print(f"成功：{success_count}/{len(files)}")
    print("=" * 70)
    
    sys.exit(0 if success_count == len(files) else 1)


if __name__ == '__main__':
    main()
