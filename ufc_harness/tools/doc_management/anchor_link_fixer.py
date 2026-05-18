#!/usr/bin/env python3
"""
UFC 锚点链接自动修复器
功能: 修复文档中的锚点链接问题
"""

import os
import re
import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Set


class AnchorLinkFixer:
    """锚点链接修复器"""
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.fixed_count = 0
        self.skipped_count = 0
    
    def extract_anchors(self, file_path: Path) -> Dict[str, str]:
        """从文件中提取所有标题锚点"""
        anchors = {}
        
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
        except:
            return anchors
        
        # 匹配 Markdown 标题 (# 到 ######)
        # 格式: ## 1. 快速开始 或 ## 快速开始
        pattern = r'^(#{1,6})\s+(.+?)\s*$'
        
        for match in re.finditer(pattern, content, re.MULTILINE):
            level = len(match.group(1))
            title = match.group(2).strip()
            
            # 生成锚点 (标准格式: #标题)
            anchor = self._title_to_anchor(title)
            anchors[anchor] = title
            
            # 也添加数字格式的锚点
            if re.match(r'^\d+\.', title):
                # 处理 "1. 快速开始" 格式
                num_anchor = "#" + title.split('.')[0] + "-" + self._title_to_anchor(title.split('.', 1)[1].strip())
                anchors[num_anchor] = title
        
        return anchors
    
    def _title_to_anchor(self, title: str) -> str:
        """将标题转换为锚点格式"""
        # 移除 emoji 和特殊字符
        title = re.sub(r'[^\w\s\-]', '', title)
        # 转为小写
        title = title.lower()
        # 空格替换为连字符
        title = re.sub(r'\s+', '-', title)
        return "#" + title
    
    def find_anchor_references(self, file_path: Path) -> List[Tuple[str, str, str]]:
        """查找文件中的锚点引用"""
        references = []
        
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
        except:
            return references
        
        # 匹配目录中的锚点引用 [text](#anchor)
        # 常见格式: #1-快速开始, #2-开发环境配置 等
        pattern = r'\[([^\]]+)\]\((#\d+-[^\)]+)\)'
        
        for match in re.finditer(pattern, content):
            text = match.group(1)
            anchor = match.group(2)
            references.append((text, anchor, match.start()))
        
        return references
    
    def fix_file(self, file_path: Path, dry_run: bool = True) -> Dict:
        """修复单个文件的锚点链接"""
        anchors = self.extract_anchors(file_path)
        references = self.find_anchor_references(file_path)
        
        if not references:
            return {"success": True, "fixed": 0, "skipped": 0}
        
        # 读取原始内容
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
        except Exception as e:
            return {"success": False, "error": str(e)}
        
        # 创建修复映射
        fixed_refs = []
        
        for text, anchor, pos in references:
            # 检查是否有对应的锚点
            # 尝试多种可能的目标锚点格式
            
            # 尝试格式1: #快速开始 (去掉数字)
            anchor_base = anchor.split('-', 1)[1] if '-' in anchor else ""
            candidate1 = "#" + anchor_base
            
            # 尝试格式2: #1.-快速开始 (带点和空格)
            num = re.search(r'#(\d+)-', anchor)
            if num:
                anchor_num = num.group(1)
                # 查找匹配的标题 (如 "1. 快速开始")
                for a, t in anchors.items():
                    if t.startswith(anchor_num + "."):
                        candidate2 = a
                        break
                else:
                    candidate2 = None
            else:
                candidate2 = None
            
            # 找到合适的修复目标
            fix_target = None
            if candidate1 in anchors:
                fix_target = candidate1
            elif candidate2 and candidate2 in anchors:
                fix_target = candidate2
            
            if fix_target:
                fixed_refs.append({
                    "original": anchor,
                    "fixed": fix_target,
                    "text": text
                })
            else:
                # 找不到匹配的锚点
                pass
        
        if dry_run:
            return {
                "success": True,
                "file": str(file_path.relative_to(self.root_path)),
                "fixed": len(fixed_refs),
                "candidates": fixed_refs[:5]
            }
        else:
            # 执行实际修复
            new_content = content
            for ref in fixed_refs:
                new_content = new_content.replace(f"({ref['original']})", f"({ref['fixed']})")
            
            if new_content != content:
                file_path.write_text(new_content, encoding='utf-8')
            
            return {
                "success": True,
                "file": str(file_path.relative_to(self.root_path)),
                "fixed": len(fixed_refs)
            }
    
    def fix_all(self, dry_run: bool = True) -> Dict:
        """修复所有文件"""
        results = []
        
        # 扫描所有 Markdown 文件 (排除归档目录)
        for md_file in self.root_path.rglob("*.md"):
            # 排除归档目录
            skip = False
            for excl in ["archive", "99_归档库", ".codebuddy"]:
                if excl in md_file.parts:
                    skip = True
                    break
            if skip:
                continue
            
            result = self.fix_file(md_file, dry_run)
            results.append(result)
        
        return {
            "total_files": len(results),
            "files_with_fixes": sum(1 for r in results if r.get('fixed', 0) > 0),
            "total_fixed": sum(r.get('fixed', 0) for r in results),
            "results": results
        }


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='UFC 锚点链接修复器')
    parser.add_argument('path', nargs='?', default=r'd:\TEST7\UFC\PLAN', help='目标路径')
    parser.add_argument('--apply', action='store_true', help='执行修复 (默认只显示)')
    parser.add_argument('--json', action='store_true', help='JSON 输出')
    
    args = parser.parse_args()
    
    fixer = AnchorLinkFixer(args.path)
    result = fixer.fix_all(dry_run=not args.apply)
    
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"=== 锚点链接修复 {'(预览)' if not args.apply else '(已修复)'} ===")
        print(f"检查文件: {result['total_files']}")
        print(f"有问题的文件: {result['files_with_fixes']}")
        print(f"可修复链接: {result['total_fixed']}")
        
        if not args.apply:
            print("\n预览前5个文件:")
            for r in result['results'][:5]:
                if r.get('fixed', 0) > 0:
                    print(f"  [{r['file']}] {r['fixed']} 处可修复")
                    for c in r.get('candidates', [])[:2]:
                        print(f"    {c['original']} -> {c['fixed']}")
    
    sys.exit(0)


if __name__ == "__main__":
    main()