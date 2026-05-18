#!/usr/bin/env python3
"""
UFC 冗余文档检测器
功能: 检测 PLAN 目录中的冗余文档
"""

import hashlib
import json
import sys
from pathlib import Path

_UFC_HARNESS = Path(__file__).resolve().parents[2]
if str(_UFC_HARNESS) not in sys.path:
    sys.path.insert(0, str(_UFC_HARNESS))

import harness_paths  # noqa: E402
from typing import Dict, List
from collections import defaultdict


class RedundancyDetector:
    """冗余文档检测器"""
    
    # 临时文件关键词
    TEMP_KEYWORDS = [
        "_temp", "_tmp", "_backup", "_old", "_draft",
        "草稿", "临时", "备份", "旧版"
    ]
    
    # 自动归档关键词
    AUTO_ARCHIVE_KEYWORDS = [
        "_v1", "_v2", "_old", "_deprecated",
        "历史", "废弃", "deprecated"
    ]
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.duplicates: Dict[str, List[Path]] = {}
        self.temp_files: List[Dict] = []
        self.old_versions: List[Dict] = []
    
    def detect(self) -> Dict:
        """执行冗余检测"""
        self._detect_duplicates()
        self._detect_temp_files()
        self._detect_old_versions()
        
        return {
            "duplicates": {k: [str(p) for p in v] for k, v in self.duplicates.items()},
            "temp_files": self.temp_files,
            "old_versions": self.old_versions,
            "total_issues": len(self.temp_files) + len(self.old_versions) + sum(len(v)-1 for v in self.duplicates.values())
        }
    
    def _detect_duplicates(self):
        """检测重复文件 (内容哈希)"""
        file_hashes = defaultdict(list)
        
        for md_file in self.root_path.rglob("*.md"):
            if md_file.name.startswith('.'):
                continue
            
            try:
                content = md_file.read_text(encoding='utf-8')
                # 简单哈希 (取前 1KB)
                hash_val = hashlib.md5(content[:1024].encode()).hexdigest()
                file_hashes[hash_val].append(md_file)
            except:
                continue
        
        # 只保留有多个文件的哈希
        for hash_val, files in file_hashes.items():
            if len(files) > 1:
                self.duplicates[hash_val] = files
    
    def _detect_temp_files(self):
        """检测临时文件"""
        for md_file in self.root_path.rglob("*.md"):
            name_lower = md_file.name.lower()
            
            for keyword in self.TEMP_KEYWORDS:
                if keyword in name_lower:
                    self.temp_files.append({
                        "file": str(md_file.relative_to(self.root_path)),
                        "reason": f"temp_keyword: {keyword}"
                    })
                    break
    
    def _detect_old_versions(self):
        """检测旧版本文件"""
        for md_file in self.root_path.rglob("*.md"):
            name_lower = md_file.name.lower()
            
            for keyword in self.AUTO_ARCHIVE_KEYWORDS:
                if keyword in name_lower:
                    self.old_versions.append({
                        "file": str(md_file.relative_to(self.root_path)),
                        "reason": f"old_version_keyword: {keyword}"
                    })
                    break


def main():
    """主函数"""
    if len(sys.argv) < 2:
        plan_path = str(harness_paths.default_plan_dir())
    else:
        plan_path = sys.argv[1]
    
    detector = RedundancyDetector(plan_path)
    result = detector.detect()
    
    print(json.dumps(result, indent=2, ensure_ascii=False))
    
    # 导出归档建议
    if result["total_issues"] > 0:
        print(f"\n⚠️ 发现 {result['total_issues']} 个可能需要归档/删除的文件")


if __name__ == "__main__":
    main()
