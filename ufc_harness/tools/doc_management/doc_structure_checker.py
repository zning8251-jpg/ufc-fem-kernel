#!/usr/bin/env python3
"""
UFC 文档结构检查器
功能: 验证 PLAN 目录是否符合标准结构（目录列表来自 config/harness_config.json）。
"""

import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

_UFC_HARNESS = Path(__file__).resolve().parents[2]
if str(_UFC_HARNESS) not in sys.path:
    sys.path.insert(0, str(_UFC_HARNESS))

import harness_paths  # noqa: E402


class DocStructureChecker:
    """文档结构检查器"""

    def __init__(self, root_path: str, cfg: Optional[Dict[str, Any]] = None):
        self.root_path = Path(root_path)
        self.cfg = cfg if cfg is not None else harness_paths.load_harness_config()
        self.required_dirs: List[str] = harness_paths.plan_required_dirs(self.cfg)
        self.max_root_files: int = harness_paths.plan_thresholds(self.cfg)["max_root_files"]
        self.issues: List[Dict[str, Any]] = []
        self.stats: Dict[str, Any] = {}

    def check_structure(self) -> Dict[str, Any]:
        """执行结构检查"""
        self._check_required_dirs()
        self._check_file_count()
        self._check_readme()
        self._check_duplicate_names()

        return {
            "is_valid": len(self.issues) == 0,
            "issues": self.issues,
            "stats": self.stats,
            "required_dirs_source": "harness_config.json doc_structure.required_dirs",
        }

    def _check_required_dirs(self) -> None:
        """检查必需目录"""
        for dir_name in self.required_dirs:
            dir_path = self.root_path / dir_name
            if not dir_path.exists():
                self.issues.append({
                    "type": "missing_directory",
                    "expected": dir_name,
                    "severity": "high",
                })
            else:
                file_count = len(list(dir_path.rglob("*.md")))
                self.stats[dir_name] = file_count

    def _check_file_count(self) -> None:
        """检查根目录文件数量"""
        root_files = list(self.root_path.glob("*.md"))
        if len(root_files) > self.max_root_files:
            self.issues.append({
                "type": "too_many_root_files",
                "expected": f"<={self.max_root_files}",
                "actual": len(root_files),
                "severity": "medium",
            })
        self.stats["root_files"] = len(root_files)

    def _check_readme(self) -> None:
        """检查 README.md"""
        readme_path = self.root_path / "README.md"
        if not readme_path.exists():
            self.issues.append({
                "type": "missing_readme",
                "severity": "high",
            })

    def _check_duplicate_names(self) -> None:
        """检查重名文件（各子目录可有独立 README.md，故跳过该文件名）。"""
        all_files: Dict[str, Path] = {}
        for md_file in self.root_path.rglob("*.md"):
            name = md_file.name
            if name == "README.md":
                continue
            if name in all_files:
                self.issues.append({
                    "type": "duplicate_filename",
                    "file": name,
                    "locations": [str(all_files[name]), str(md_file)],
                })
            else:
                all_files[name] = md_file


def main() -> None:
    """主函数"""
    if len(sys.argv) < 2:
        plan_path = str(harness_paths.default_plan_dir())
    else:
        plan_path = sys.argv[1]

    checker = DocStructureChecker(plan_path)
    result = checker.check_structure()

    print(json.dumps(result, indent=2, ensure_ascii=False))

    sys.exit(0 if result["is_valid"] else 1)


if __name__ == "__main__":
    main()
