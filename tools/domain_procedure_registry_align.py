#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Bidirectional alignment: design/ (manifest + INTENT) ↔ ufc_core ↔ generated/

- **design/** holds curated `manifest.json` per domain bucket (see
  `UFC/docs/03_Domain_Pillars/DomainProcedureRegistry/design/manifest.schema.json`).
- **generated/** is produced by `domain_procedure_registry_scan.py` from code.
- This tool writes a drift report to **`UFC/REPORTS/DESIGN_GENERATED_DRIFT.md`** by default (`--out` overrides).

Usage:
  python UFC/tools/domain_procedure_registry_align.py
  python UFC/tools/domain_procedure_registry_align.py --bootstrap \\
      UFC/docs/03_Domain_Pillars/DomainProcedureRegistry/design/L2_NM/Matrix/manifest.json

Exit code: 0 if no drift, 1 if any issue (CI-friendly).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

UFC_ROOT = Path(__file__).resolve().parents[1]
REGISTRY_DOC_ROOT = UFC_ROOT / "docs" / "03_Domain_Pillars" / "DomainProcedureRegistry"
DESIGN_ROOT = REGISTRY_DOC_ROOT / "design"
GENERATED_ROOT = REGISTRY_DOC_ROOT / "generated"
# Machine drift report: keep under REPORTS/ (Harness 报告桶)，避免污染 `docs/` 真源树
DRIFT_OUT = UFC_ROOT / "REPORTS" / "DESIGN_GENERATED_DRIFT.md"
UFC_CORE = UFC_ROOT / "ufc_core"
LAYERS = ("L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP")

MODULE_RE = re.compile(r"^\s*MODULE\s+(\w+)\s*(?:!.*)?$", re.IGNORECASE)
SKIP_PATH_SEGMENTS: tuple[str, ...] = ("ExternalLibs",)


def source_skipped(rel_posix: str) -> bool:
    return any(p in Path(rel_posix).parts for p in SKIP_PATH_SEGMENTS)


def read_module_name(f90: Path) -> str | None:
    try:
        text = f90.read_text(encoding="utf-8-sig", errors="replace")
    except OSError:
        return None
    for ln in text.splitlines():
        s = ln.strip()
        if not s or s.startswith("!"):
            continue
        m = MODULE_RE.match(ln)
        if m:
            return m.group(1)
    return None


def discover_manifests() -> list[Path]:
    if not DESIGN_ROOT.is_dir():
        return []
    return sorted(DESIGN_ROOT.rglob("manifest.json"))


def load_manifest(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def bootstrap_manifest(target: Path) -> int:
    """
    Write manifest.json from current ufc_core tree.
    target must be like .../design/L2_NM/Matrix/manifest.json
    """
    target = Path(target).resolve()
    rel = target.relative_to(DESIGN_ROOT.resolve())
    parts = rel.parts
    if len(parts) < 3 or parts[-1] != "manifest.json":
        print("Bootstrap target must be design/<LAYER>/<Domain>/manifest.json", file=sys.stderr)
        return 2
    layer, domain_bucket = parts[0], parts[1]
    if layer not in LAYERS:
        print("Unknown layer:", layer, file=sys.stderr)
        return 2
    src_dir = UFC_CORE / layer / domain_bucket
    if not src_dir.is_dir():
        print("No source dir:", src_dir, file=sys.stderr)
        return 2
    modules: list[dict] = []
    for fp in sorted(src_dir.rglob("*.f90")):
        rel_src = fp.relative_to(UFC_CORE).as_posix()
        if source_skipped(rel_src):
            continue
        stem = fp.stem
        mod = read_module_name(fp)
        # 片段 / 集成单元等可能无 MODULE；不纳入 manifest，避免与 stem/MODULE 规则冲突。
        if mod is None:
            continue
        entry: dict = {"source_rel": rel_src, "stem": stem}
        if mod != stem:
            entry["module"] = mod
        modules.append(entry)
    doc = {
        "layer": layer,
        "domain_bucket": domain_bucket,
        "intent_doc": "INTENT.md",
        "infer_list_anchor": "docs/05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md",
        "modules": modules,
    }
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        json.dumps(doc, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print("Wrote", target, "entries", len(modules))
    return 0


def expected_registry_md_from_source(source_rel: str, stem: str) -> Path:
    """与 `domain_procedure_registry_scan.py` 一致：镜像 `ufc_core` 相对路径，`.f90`→`.md`。"""
    pp = Path(source_rel).parts
    if len(pp) <= 2:
        layer = pp[0] if pp else ""
        return GENERATED_ROOT / layer / "_root" / f"{stem}.md"
    return GENERATED_ROOT / Path(source_rel).with_suffix(".md")


def align_one(manifest_path: Path) -> list[str]:
    issues: list[str] = []
    data = load_manifest(manifest_path)
    layer = data["layer"]
    domain_bucket = data["domain_bucket"]
    modules = data["modules"]
    seen_sources: set[str] = set()

    for i, mod in enumerate(modules):
        src_rel = mod["source_rel"]
        if src_rel in seen_sources:
            issues.append(f"{manifest_path}: duplicate source_rel `{src_rel}`")
        seen_sources.add(src_rel)
        stem = mod.get("stem") or Path(src_rel).stem
        expected_mod = mod.get("module")
        fp = UFC_CORE / Path(src_rel)
        if not fp.is_file():
            issues.append(f"{manifest_path}: missing source `{src_rel}` (entry {i})")
            continue
        actual_stem = fp.stem
        if actual_stem != stem:
            issues.append(
                f"{manifest_path}: stem mismatch entry `{stem}` vs file `{actual_stem}` for `{src_rel}`"
            )
        actual_module = read_module_name(fp)
        if actual_module is None:
            issues.append(
                f"{manifest_path}: no MODULE line in `{src_rel}` "
                "(remove entry or restore MODULE; include-only .f90 不纳入 manifest)"
            )
        elif expected_mod is not None and actual_module != expected_mod:
            issues.append(
                f"{manifest_path}: MODULE mismatch `{src_rel}` expected `{expected_mod}` got `{actual_module}`"
            )
        elif expected_mod is None and actual_module != actual_stem:
            issues.append(
                f"{manifest_path}: stem≠MODULE `{src_rel}` stem=`{actual_stem}` MODULE=`{actual_module}` "
                "(set `module` in manifest if intentional)"
            )
        gen_md = expected_registry_md_from_source(src_rel, actual_stem)
        if not gen_md.is_file():
            issues.append(f"missing generated `{gen_md.relative_to(UFC_ROOT).as_posix()}` for `{src_rel}`")

    # Extra files under domain bucket not listed in manifest (recursive; skip ExternalLibs)
    src_dir = UFC_CORE / layer / domain_bucket
    if src_dir.is_dir():
        listed = {Path(m["source_rel"]).as_posix() for m in modules}
        for fp in sorted(src_dir.rglob("*.f90")):
            rel = fp.relative_to(UFC_CORE).as_posix()
            if source_skipped(rel):
                continue
            if read_module_name(fp) is None:
                continue
            if rel not in listed:
                issues.append(
                    f"{manifest_path}: **extra** ufc_core file not in manifest: `{rel}` "
                    "(add to manifest or move file)"
                )
    return issues


def main() -> int:
    ap = argparse.ArgumentParser(description="Align design manifests with ufc_core and generated/")
    ap.add_argument(
        "--bootstrap",
        metavar="PATH",
        help="Write manifest.json from ufc_core scan (path design/<L>/<D>/manifest.json)",
    )
    ap.add_argument(
        "--out",
        default=str(DRIFT_OUT),
        help="Drift report markdown path",
    )
    args = ap.parse_args()
    if args.bootstrap:
        return bootstrap_manifest(Path(args.bootstrap))

    manifests = discover_manifests()
    all_issues: list[str] = []
    no_manifest_note: str | None = None
    if not manifests:
        no_manifest_note = (
            "尚未发现 `design/**/manifest.json`：在域目录下添加 manifest，或对目标路径使用 "
            "`--bootstrap` 从 `ufc_core` 生成初稿。"
        )

    for mp in manifests:
        try:
            all_issues.extend(align_one(mp))
        except (json.JSONDecodeError, KeyError) as e:
            all_issues.append(f"{mp}: invalid manifest: {e}")

    out_path = Path(args.out)
    utc = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    lines = [
        "# DESIGN ↔ generated / ufc_core 漂移报告",
        "",
        f"- **Generated (UTC)**: {utc}",
        "- **真源**: `UFC/docs/03_Domain_Pillars/DomainProcedureRegistry/design/**/manifest.json`",
        "- **对照**: `ufc_core/` 与 `docs/03_Domain_Pillars/DomainProcedureRegistry/generated/`",
        "- **默认输出**: `UFC/REPORTS/DESIGN_GENERATED_DRIFT.md`（可用 `--out` 覆盖）",
        "- **工具**: `python UFC/tools/domain_procedure_registry_align.py`",
        "",
        "## 结果",
        "",
    ]
    if no_manifest_note:
        lines.append(f"**说明**：{no_manifest_note}")
        lines.append("")
    if not all_issues:
        lines.append("**OK**：未发现漂移。")
        code = 0
    else:
        lines.append(f"**共 {len(all_issues)} 条**（修复后重新运行扫描与对齐）。")
        lines.append("")
        for item in all_issues:
            lines.append(f"- {item}")
        code = 1
    lines.append("")
    lines.append("## 工作流提示")
    lines.append("")
    lines.append(
        "1. 在 `design/<LAYER>/<Domain>/` 维护 `manifest.json`（可用 `--bootstrap` 生成初稿后手工删改）。\n"
        "2. `python UFC/tools/domain_procedure_registry_scan.py` 更新 `generated/`。\n"
        "3. 再运行本工具；CI 可对 exit code 门禁。\n"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print("Wrote", out_path)
    for item in all_issues:
        print(item)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
