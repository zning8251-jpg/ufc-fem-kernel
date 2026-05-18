# UFC Harness Engineering - Phase 1: 文档管理工具集

> **实施阶段**: Week 1-2  
> **技术选型**: Python 脚本混合  
> **目标**: PLAN 目录结构自动校验、交叉引用验证、冗余检测

> **与实现同步（2026-03）**：权威用法与目录以 **[`../../../ufc_harness/README.md`](../../../ufc_harness/README.md)**、**[`../../../ufc_harness/config/harness_config.json`](../../../ufc_harness/config/harness_config.json)** 为准；下文 Phase 1 初稿中的示例代码可能与当前脚本实现不一致，以仓库内 `.py` 文件为准。

---

## 1.1 工具清单

| 工具名称 | 功能说明 | 输入 | 输出 |
|----------|----------|------|------|
| **doc_structure_checker.py** | 检查 PLAN 目录结构（`required_dirs` 来自 `harness_config.json`） | PLAN/ | JSON：结构报告 + 问题列表 |
| **cross_ref_validator.py** | 验证文档交叉引用 | *.md | JSON：链接检查报告 |
| **redundancy_detector.py** | 检测冗余文档 | PLAN/ | JSON：冗余列表 |
| **naming_checker.py**（`tools/code_development/`） | Fortran 命名规范扫描 | `ufc_core`/文件 | 文本或 JSON 报告 |
| **run_harness.py** | 统一入口：`plan-checks`、`doc-structure`、`build` 透传等 | — | 见 `ufc_harness/README.md` |

以下条目**尚未**在 `ufc_harness/tools/` 落地，勿在 CI 中假设存在：**naming_convention_validator.py**（Markdown）、**doc_quality_scorer.py**。

---

## 1.2 目录结构（现行）

```
UFC/ufc_harness/
├── harness_paths.py          # 解析 UFC 根、PLAN、加载 harness_config.json
├── run_harness.py            # 推荐统一入口
├── uhc.py                    # 按类别转发到 tools/
├── README.md
├── config/
│   └── harness_config.json
└── tools/
    ├── doc_management/       # doc_structure_checker, cross_ref_validator, redundancy_detector, analyze_*, anchor_link_fixer
    ├── code_development/     # module_scaffold, naming_checker, build_trigger
    ├── algo_mapping/         # algo_tracing, contract_linker
    └── arch_validation/      # arch_consistency
```

（规划中的 `memory/`、`logs/`、`naming_rules.json` 等可由后续 Phase 增补。）

---

## 1.3 核心工具实现

### 1.3.1 doc_structure_checker.py

```python
#!/usr/bin/env python3
"""
UFC 文档结构检查器
功能: 验证 PLAN 目录是否符合标准结构
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Tuple

class DocStructureChecker:
    """文档结构检查器"""
    
    # 标准目录结构 (基于 v4.0 重构)
    REQUIRED_DIRS = [
        "00_导航与元信息",
        "01_架构总纲与设计哲学",
        "02_域级建模与实施清单",
        "03_技术规范与标准",
        "04_实施路线与任务规划",
        "05_技术标准与参考",
        "06_实施指南",
        "07_理论参考",
        "99_归档库"
    ]
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.issues = []
        self.stats = {}
    
    def check_structure(self) -> Dict:
        """执行结构检查"""
        self._check_required_dirs()
        self._check_file_count()
        self._check_readme()
        self._check_duplicate_names()
        
        return {
            "is_valid": len(self.issues) == 0,
            "issues": self.issues,
            "stats": self.stats
        }
    
    def _check_required_dirs(self):
        """检查必需目录"""
        for dir_name in self.REQUIRED_DIRS:
            dir_path = self.root_path / dir_name
            if not dir_path.exists():
                self.issues.append({
                    "type": "missing_directory",
                    "expected": dir_name,
                    "severity": "high"
                })
            else:
                # 统计文件数量
                file_count = len(list(dir_path.rglob("*.md")))
                self.stats[dir_name] = file_count
    
    def _check_file_count(self):
        """检查根目录文件数量"""
        root_files = list(self.root_path.glob("*.md"))
        if len(root_files) > 25:
            self.issues.append({
                "type": "too_many_root_files",
                "expected": "<=25",
                "actual": len(root_files),
                "severity": "medium"
            })
        self.stats["root_files"] = len(root_files)
    
    def _check_readme(self):
        """检查 README.md"""
        readme_path = self.root_path / "README.md"
        if not readme_path.exists():
            self.issues.append({
                "type": "missing_readme",
                "severity": "high"
            })
    
    def _check_duplicate_names(self):
        """检查重名文件"""
        all_files = {}
        for md_file in self.root_path.rglob("*.md"):
            name = md_file.name
            if name in all_files:
                self.issues.append({
                    "type": "duplicate_filename",
                    "file": name,
                    "locations": [str(all_files[name]), str(md_file)]
                })
            else:
                all_files[name] = md_file


def main():
    """主函数"""
    import sys
    
    if len(sys.argv) < 2:
        plan_path = r"d:\TEST7\UFC\PLAN"
    else:
        plan_path = sys.argv[1]
    
    checker = DocStructureChecker(plan_path)
    result = checker.check_structure()
    
    # 输出 JSON 格式结果
    print(json.dumps(result, indent=2, ensure_ascii=False))
    
    # 返回状态码
    sys.exit(0 if result["is_valid"] else 1)


if __name__ == "__main__":
    main()
```

---

### 1.3.2 cross_ref_validator.py

```python
#!/usr/bin/env python3
"""
UFC 文档交叉引用验证器
功能: 验证 Markdown 文件中的内部链接是否有效
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Tuple, Set


class CrossRefValidator:
    """交叉引用验证器"""
    
    # 支持的链接模式
    LINK_PATTERNS = [
        r'\[([^\]]+)\]\(([^\)]+)\)',  # [text](link)
        r'@(\w+)',                     # @document
    ]
    
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.all_files: Set[Path] = set()
        self.issues: List[Dict] = []
    
    def scan_files(self):
        """扫描所有 Markdown 文件"""
        for md_file in self.root_path.rglob("*.md"):
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
    
    def _extract_links(self, content: str) -> List[Tuple[str, str]]:
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
    import sys
    
    if len(sys.argv) < 2:
        plan_path = r"d:\TEST7\UFC\PLAN"
    else:
        plan_path = sys.argv[1]
    
    validator = CrossRefValidator(plan_path)
    result = validator.validate_all()
    
    print(json.dumps(result, indent=2, ensure_ascii=False))
    sys.exit(0 if result["total_issues"] == 0 else 1)


if __name__ == "__main__":
    main()
```

---

### 1.3.3 redundancy_detector.py

```python
#!/usr/bin/env python3
"""
UFC 冗余文档检测器
功能: 检测 PLAN 目录中的冗余文档
"""

import os
import hashlib
import json
from pathlib import Path
from typing import Dict, List, Set
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
    import sys
    
    if len(sys.argv) < 2:
        plan_path = r"d:\TEST7\UFC\PLAN"
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
```

---

## 1.4 配置文件

### 1.4.1 harness_config.json

```json
{
    "version": "1.0.0",
    "project": "UFC Harness Engineering",
    "root_path": "d:\\TEST7\\UFC",
    "modules": {
        "doc_management": {
            "enabled": true,
            "tools": [
                "doc_structure_checker.py",
                "cross_ref_validator.py",
                "naming_convention_validator.py",
                "redundancy_detector.py",
                "doc_quality_scorer.py"
            ]
        },
        "code_development": {
            "enabled": true,
            "tools": [
                "module_scaffold.py",
                "naming_checker.py",
                "build_trigger.py"
            ]
        },
        "algo_mapping": {
            "enabled": true,
            "tools": [
                "algo_tracing.py",
                "contract_linker.py",
                "l3l4l5_mapper.py"
            ]
        },
        "arch_validation": {
            "enabled": true,
            "tools": [
                "arch_consistency.py",
                "contract_completeness.py"
            ]
        }
    },
    "thresholds": {
        "max_root_files": 25,
        "max_files_per_dir": 50,
        "min_doc_quality_score": 0.6
    }
}
```

---

## 1.5 CI/CD 集成

### 1.5.1 GitHub Actions 工作流 (可选)

```yaml
# .github/workflows/harness-doc-check.yml
name: UFC Harness - Document Check

on:
  push:
    paths:
      - 'PLAN/**'
  pull_request:
    paths:
      - 'PLAN/**'

jobs:
  doc-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Structure Checker
        run: python ufc_harness/tools/doc_management/doc_structure_checker.py ./PLAN
      
      - name: Run Cross-Ref Validator
        run: python ufc_harness/tools/doc_management/cross_ref_validator.py ./PLAN
      
      - name: Run Redundancy Detector
        run: python ufc_harness/tools/doc_management/redundancy_detector.py ./PLAN
```

---

## 1.6 执行命令

```powershell
# 本地运行
cd d:\TEST7\UFC\ufc_harness\tools\doc_management

# 1. 检查文档结构
python doc_structure_checker.py d:\TEST7\UFC\PLAN

# 2. 验证交叉引用
python cross_ref_validator.py d:\TEST7\UFC\PLAN

# 3. 检测冗余文档
python redundancy_detector.py d:\TEST7\UFC\PLAN
```

---

*Phase 1 完成标志：所有工具可运行并输出结构化报告*

---

等待确认后，我将：
1. 创建完整的工具目录结构
2. 实现全部 5 个文档管理工具
3. 配置 CI/CD 集成

**请确认是否开始执行？**