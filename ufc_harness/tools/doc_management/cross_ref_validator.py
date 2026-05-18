#!/usr/bin/env python3
"""
UFC 文档交叉引用验证器
功能: 验证 Markdown 文件中的内部链接是否有效
"""

import json
import re
import sys
from pathlib import Path

_UFC_HARNESS = Path(__file__).resolve().parents[2]
if str(_UFC_HARNESS) not in sys.path:
    sys.path.insert(0, str(_UFC_HARNESS))

import harness_paths  # noqa: E402
from typing import Dict, List, Tuple, Set


class CrossRefValidator:
    """交叉引用验证器"""
    
    # 排除目录 (不验证这些目录的链接)
    EXCLUDE_DIRS = [
        "archive",
        "99_归档库",
        ".codebuddy"
    ]
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.all_files: Set[Path] = set()
        self.issues: List[Dict] = []
    
    def scan_files(self):
        """扫描所有 Markdown 文件"""
        for md_file in self.root_path.rglob("*.md"):
            # 排除指定目录
            skip = False
            for excl_dir in self.EXCLUDE_DIRS:
                if excl_dir in md_file.parts:
                    skip = True
                    break
            if not skip:
                self.all_files.add(md_file)
        print(f"扫描到 {len(self.all_files)} 个 Markdown 文件")
    
    def validate_all(self) -> Dict:
        """验证所有文件的交叉引用"""
        self.scan_files()
        
        for md_file in self.all_files:
            self._validate_file(md_file)
        
        return {
            "total_files": len(self.all_files),
            "total_issues": len(self.issues),
            "issues": self.issues
        }
    
    def _validate_file(self, file_path: Path):
        """验证单个文件"""
        try:
            content = file_path.read_text(encoding='utf-8')
        except Exception as e:
            self.issues.append({
                "file": str(file_path.relative_to(self.root_path)),
                "type": "read_error",
                "message": str(e)
            })
            return
        
        # 查找所有链接
        links = self._extract_links(content)
        
        for link in links:
            self._validate_link(file_path, link)
    
    def _extract_links(self, content: str) -> List[Tuple[str, str, str]]:
        """提取所有链接"""
        links = []
        
        # Markdown 链接 [text](link)
        for match in re.finditer(r'\[([^\]]+)\]\(([^\)]+)\)', content):
            text, link = match.groups()
            if not link.startswith(('http://', 'https://', 'mailto:')):
                links.append(('md', link, text))
        
        # @引用
        for match in re.finditer(r'@(\w+)', content):
            doc_name = match.group(1)
            links.append(('ref', doc_name, doc_name))
        
        return links
    
    def _validate_link(self, source_file: Path, link: Tuple):
        """验证单个链接"""
        link_type, link_path, link_text = link
        
        if link_type == 'md':
            # 相对路径链接
            if link_path.startswith('/'):
                # 绝对路径
                target = self.root_path / link_path.lstrip('/')
            else:
                # 相对路径
                target = (source_file.parent / link_path).resolve()
            
            if not target.exists():
                self.issues.append({
                    "file": str(source_file.relative_to(self.root_path)),
                    "type": "broken_link",
                    "link": link_path,
                    "text": link_text
                })
        
        elif link_type == 'ref':
            # @引用 - 查找同名文件
            found = False
            for f in self.all_files:
                if f.stem == link_path or f.name.startswith(link_path):
                    found = True
                    break
            
            if not found:
                self.issues.append({
                    "file": str(source_file.relative_to(self.root_path)),
                    "type": "broken_ref",
                    "ref": link_path
                })


def main():
    """主函数"""
    if len(sys.argv) < 2:
        plan_path = str(harness_paths.default_plan_dir())
    else:
        plan_path = sys.argv[1]
    
    validator = CrossRefValidator(plan_path)
    result = validator.validate_all()
    
    print(json.dumps(result, indent=2, ensure_ascii=False))
    sys.exit(0 if result["total_issues"] == 0 else 1)


if __name__ == "__main__":
    main()
