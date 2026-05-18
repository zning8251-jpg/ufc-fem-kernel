#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC 文档健康检查工具

功能:
1. 检测重复文档（基于文件名相似度，默认排除 docs/archive/ 降低误报）
2. 验证仓库内 Markdown 相对链接（.md），支持锚点、URL 编码（%20）、指向 archive/
3. 识别过时文档（超过 3 个月未更新）
4. 生成健康检查报告

使用方法:
    python check_docs_health.py [docs_directory] [--include-archive-in-heuristics]

示例:
    python UFC/tools/check_docs_health.py UFC/docs
    python UFC/tools/check_docs_health.py UFC/docs --include-archive-in-heuristics
    python UFC/tools/check_docs_health.py UFC/docs --skip-links-from-archive
"""

import argparse
import os
import sys
from pathlib import Path
from datetime import datetime, timedelta
from collections import defaultdict
from urllib.parse import unquote
import re


def read_md_relaxed(path: Path) -> str:
    """Read Markdown as UTF-8; on failure try GB18030 (legacy Windows saves)."""
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        raw = path.read_bytes()
        try:
            return raw.decode("gb18030")
        except Exception:
            return raw.decode("utf-8", errors="replace")


class DocsHealthChecker:
    def __init__(
        self,
        docs_root: str,
        include_archive_in_heuristics: bool = False,
        skip_links_from_archive: bool = False,
    ):
        self.docs_root = Path(docs_root).resolve()
        self.include_archive_in_heuristics = include_archive_in_heuristics
        self.skip_links_from_archive = skip_links_from_archive
        self.all_md_files = []  # 整棵 docs 树（含 archive），用于链接目标解析
        self.heuristic_md_files = []  # 重复/过期/孤立启发式用的子集
        self.duplicate_groups = []
        self.outdated_docs = []
        self.broken_links = []  # list of dict: source, target, resolved
        self.isolated_docs = []

    def scan_all_markdown_files(self):
        """扫描 Markdown：全量用于断链；默认排除顶层 archive/ 参与启发式。"""
        print(f"🔍 扫描目录：{self.docs_root}")
        self.all_md_files = []
        self.heuristic_md_files = []
        for md_file in self.docs_root.rglob("*.md"):
            self.all_md_files.append(md_file)
            try:
                rel = md_file.relative_to(self.docs_root)
            except ValueError:
                rel = Path(md_file.name)
            _arch_roots = ("archive", "archive_20260418")
            skip_heuristic = (
                not self.include_archive_in_heuristics
                and rel.parts
                and rel.parts[0] in _arch_roots
            )
            if not skip_heuristic:
                self.heuristic_md_files.append(md_file)

        print(
            f"✅ 发现 {len(self.all_md_files)} 个 Markdown 文件"
            f"（启发式扫描 {len(self.heuristic_md_files)} 个，"
            f"{'含' if self.include_archive_in_heuristics else '不含'} docs/archive/）\n"
        )
        return self
    
    def detect_duplicates(self):
        """检测重复文档（基于文件名模式）"""
        print("🔍 检测重复文档...")
        
        # 按文件名分组
        name_pattern_groups = defaultdict(list)
        for md_file in self.heuristic_md_files:
            # 提取核心名称（去除版本号、后缀等）
            name = md_file.stem
            # 标准化：移除版本标识
            normalized_name = re.sub(r'_v\d+.*$', '', name, flags=re.IGNORECASE)
            normalized_name = re.sub(r'_完整.*$', '', normalized_name, flags=re.IGNORECASE)
            normalized_name = re.sub(r'_权威.*$', '', normalized_name, flags=re.IGNORECASE)
            
            name_pattern_groups[normalized_name.lower()].append(md_file)
        
        # 找出重复组
        _trivial_dup_names = frozenset(
            {
                "readme",
                "skill",
                "intent",
                "_layer_index",
                "readme_文档分类清单",
            }
        )
        for name, files in name_pattern_groups.items():
            if len(files) > 1:
                if name in _trivial_dup_names:
                    continue
                # 排除合理的配对（如 X.md 和 X_域级审查报告.md）
                if not any("域级审查" in f.stem or "域级建模" in f.stem for f in files):
                    self.duplicate_groups.append(files)
        
        if self.duplicate_groups:
            print(f"⚠️  发现 {len(self.duplicate_groups)} 组重复文档:")
            for i, group in enumerate(self.duplicate_groups, 1):
                print(f"\n  第{i}组重复:")
                for f in group:
                    print(f"    - {f.relative_to(self.docs_root)}")
        else:
            print("✅ 未发现重复文档")
        print()
        
        return self
    
    def detect_outdated_docs(self, months_threshold=3):
        """检测过时文档（超过 N 个月未更新）"""
        print(f"🔍 检测过时文档（>{months_threshold}个月未更新）...")
        
        cutoff_date = datetime.now() - timedelta(days=months_threshold * 30)
        
        for md_file in self.heuristic_md_files:
            mtime = datetime.fromtimestamp(md_file.stat().st_mtime)
            if mtime < cutoff_date:
                # 检查是否是临时/草稿文档
                if any(keyword in md_file.name for keyword in ["临时", "草稿", "v0.", "draft"]):
                    self.outdated_docs.append((md_file, mtime))
        
        if self.outdated_docs:
            print(f"⚠️  发现 {len(self.outdated_docs)} 份过期临时文档:")
            for f, mtime in sorted(self.outdated_docs, key=lambda x: x[1]):
                print(f"    - {f.relative_to(self.docs_root)} (最后更新：{mtime.date()})")
        else:
            print("✅ 无过期临时文档")
        print()
        
        return self
    
    def verify_references(self):
        """验证 docs 树内指向 .md 的相对链接（跳过 http(s)/mailto、仓库外路径）。"""
        print("🔍 验证文档引用完整性（仓库内 .md 链接）...")

        existing_paths = {f.resolve() for f in self.all_md_files}
        link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")

        for md_file in self.all_md_files:
            if self.skip_links_from_archive:
                try:
                    rel = md_file.relative_to(self.docs_root)
                    if rel.parts and rel.parts[0] in (
                        "archive",
                        "archive_20260418",
                    ):
                        continue
                except ValueError:
                    pass
            try:
                content = read_md_relaxed(md_file)
            except OSError as e:
                print(f"  ⚠️  读取失败：{md_file} - {e}")
                continue

            for raw in link_re.findall(content):
                target = raw.strip()
                if target.startswith("<") and target.endswith(">"):
                    target = target[1:-1].strip()
                target = target.split("#", 1)[0].strip()
                if not target or target.lower().startswith(
                    ("http://", "https://", "mailto:")
                ):
                    continue
                if not target.endswith(".md"):
                    continue

                target = unquote(target)
                if os.path.isabs(target):
                    abs_path = Path(target)
                else:
                    abs_path = (md_file.parent / target).resolve()

                try:
                    abs_path.relative_to(self.docs_root)
                except ValueError:
                    continue

                if abs_path in existing_paths:
                    continue
                if abs_path.is_file():
                    continue

                self.broken_links.append(
                    {
                        "source": str(md_file.relative_to(self.docs_root)),
                        "target": raw.strip(),
                        "resolved": str(abs_path),
                    }
                )

        if self.broken_links:
            print(f"⚠️  发现 {len(self.broken_links)} 个失效 .md 链接:")
            for item in self.broken_links[:30]:
                print(f"    - {item['source']} -> {item['target']}")
                print(f"      （解析为 {item['resolved']}）")
            if len(self.broken_links) > 30:
                print(f"    ... 还有 {len(self.broken_links) - 30} 个")
        else:
            print("✅ 仓库内 .md 链接均解析到现有文件")
        print()

        return self

    def find_isolated_docs(self):
        """查找孤立文档（无其他文档引用）"""
        print("🔍 查找孤立文档...")

        link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
        referenced_set = set()
        for md_file in self.all_md_files:
            try:
                content = read_md_relaxed(md_file)
                for raw in link_re.findall(content):
                    target = raw.strip()
                    if target.startswith("<") and target.endswith(">"):
                        target = target[1:-1].strip()
                    target = unquote(target.split("#", 1)[0].strip())
                    if not target.endswith(".md"):
                        continue
                    if target.lower().startswith(("http://", "https://", "mailto:")):
                        continue
                    if os.path.isabs(target):
                        abs_path = Path(target).resolve()
                    else:
                        abs_path = (md_file.parent / target).resolve()
                    try:
                        abs_path.relative_to(self.docs_root)
                    except ValueError:
                        continue
                    referenced_set.add(str(abs_path))
            except OSError:
                pass

        for md_file in self.heuristic_md_files:
            abs_path = str(md_file.resolve())
            if abs_path not in referenced_set:
                # 排除重要文档
                if md_file.name in ["README.md", "index.md"]:
                    continue
                # 排除根目录下的导航文档
                if md_file.parent == self.docs_root:
                    continue
                self.isolated_docs.append(md_file)
        
        if self.isolated_docs:
            print(f"⚠️  发现 {len(self.isolated_docs)} 份孤立文档:")
            for f in sorted(self.isolated_docs)[:10]:  # 只显示前 10 个
                print(f"    - {f.relative_to(self.docs_root)}")
            if len(self.isolated_docs) > 10:
                print(f"    ... 还有 {len(self.isolated_docs) - 10} 份")
        else:
            print("✅ 无孤立文档")
        print()
        
        return self
    
    def generate_report(self, output_file=None):
        """生成健康检查报告"""
        report_lines = [
            "# UFC 文档健康检查报告",
            f"\n**检查时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"**检查范围**: {self.docs_root}",
            f"**文档总数**: {len(self.all_md_files)}",
            "\n## 📊 检查结果汇总",
            "",
            f"- 🔴 重复文档组数：{len(self.duplicate_groups)}",
            f"- 🟡 过期临时文档：{len(self.outdated_docs)}",
            f"- 🟠 失效 .md 链接：{len(self.broken_links)}",
            f"- ⚪ 孤立文档：{len(self.isolated_docs)}",
        ]
        
        if self.duplicate_groups:
            report_lines.append("\n## 🔴 重复文档详情")
            for i, group in enumerate(self.duplicate_groups, 1):
                report_lines.append(f"\n### 第{i}组")
                for f in group:
                    rel_path = f.relative_to(self.docs_root)
                    size_kb = f.stat().st_size / 1024
                    report_lines.append(f"- `{rel_path}` ({size_kb:.1f}KB)")
        
        if self.outdated_docs:
            report_lines.append("\n## 🟡 过期临时文档")
            for f, mtime in sorted(self.outdated_docs, key=lambda x: x[1]):
                rel_path = f.relative_to(self.docs_root)
                days_old = (datetime.now() - mtime).days
                report_lines.append(f"- `{rel_path}` ({days_old}天未更新)")

        if self.broken_links:
            report_lines.append("\n## 🟠 失效 .md 链接（节选）")
            for item in self.broken_links[:50]:
                report_lines.append(
                    f"- `{item['source']}` → `{item['target']}` → `{item['resolved']}`"
                )
            if len(self.broken_links) > 50:
                report_lines.append(f"- ... 共 {len(self.broken_links)} 条")

        report = "\n".join(report_lines)
        
        if output_file:
            output_path = Path(output_file)
            output_path.write_text(report, encoding='utf-8')
            print(f"📄 报告已保存至：{output_path}")
        else:
            print(report)
        
        return report


def main():
    # Windows 控制台默认 GBK 时，emoji 会导致 UnicodeEncodeError
    if sys.platform == "win32":
        try:
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, OSError):
            pass

    parser = argparse.ArgumentParser(description="UFC docs 健康检查")
    parser.add_argument(
        "docs_root",
        nargs="?",
        default=str(Path(__file__).resolve().parent.parent / "docs"),
        help="文档根目录（默认 UFC/docs）",
    )
    parser.add_argument(
        "--include-archive-in-heuristics",
        action="store_true",
        help="重复/过期/孤立启发式也包含 docs/archive/（默认排除以降低噪声）",
    )
    parser.add_argument(
        "--skip-links-from-archive",
        action="store_true",
        help="不扫描 docs/archive/、docs/archive_20260418/ 内 .md 的出站链接（历史稿断链多时可先用此项看「活跃文档」）",
    )
    parser.add_argument(
        "--output",
        "-o",
        metavar="FILE",
        help="将 Markdown 报告写入路径（UTF-8）",
    )
    args = parser.parse_args()
    docs_root = args.docs_root

    if not os.path.isdir(docs_root):
        print(f"❌ 错误：目录不存在 - {docs_root}")
        sys.exit(1)

    checker = DocsHealthChecker(
        docs_root,
        include_archive_in_heuristics=args.include_archive_in_heuristics,
        skip_links_from_archive=args.skip_links_from_archive,
    )
    (
        checker.scan_all_markdown_files()
        .detect_duplicates()
        .detect_outdated_docs()
        .verify_references()
        .find_isolated_docs()
        .generate_report(output_file=args.output)
    )

    has_issues = (
        checker.duplicate_groups
        or checker.outdated_docs
        or checker.broken_links
        or checker.isolated_docs
    )
    sys.exit(1 if has_issues else 0)


if __name__ == "__main__":
    main()
