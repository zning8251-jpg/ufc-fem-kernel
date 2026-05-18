#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Create missing ``design/<LAYER>/<Domain>/INTENT.md`` and (re)bootstrap
``manifest.json`` for every **domain bucket** under ``UFC/ufc_core/<Layer>/``
that contains at least one ``*.f90`` (skipping ``ExternalLibs`` paths).

Does **not** overwrite existing ``INTENT.md``. Always refreshes ``manifest.json``
via the same logic as ``domain_procedure_registry_align.py --bootstrap``.

Usage (from repo root):

  python UFC/tools/bootstrap_design_domain_intents.py
  python UFC/tools/bootstrap_design_domain_intents.py --dry-run

Then:

  python UFC/tools/domain_procedure_registry_scan.py
  python UFC/tools/domain_procedure_registry_align.py
"""
from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path

UFC_ROOT = Path(__file__).resolve().parents[1]
UFC_CORE = UFC_ROOT / "ufc_core"
DESIGN_ROOT = UFC_ROOT / "docs" / "03_Domain_Pillars" / "DomainProcedureRegistry" / "design"
LAYERS = ("L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP")

SKIP_DOMAIN_NAMES = frozenset(
    {
        "ExternalLibs",
        "__pycache__",
        "build",
        "CMakeFiles",
        ".git",
    }
)


def _load_align():
    p = Path(__file__).resolve().parent / "domain_procedure_registry_align.py"
    spec = importlib.util.spec_from_file_location("domain_procedure_registry_align", p)
    if spec is None or spec.loader is None:
        raise RuntimeError("Cannot load domain_procedure_registry_align")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def f90_count_under(domain_dir: Path, align) -> int:
    n = 0
    if not domain_dir.is_dir():
        return 0
    for fp in domain_dir.rglob("*.f90"):
        rel = fp.relative_to(UFC_CORE).as_posix()
        if align.source_skipped(rel):
            continue
        n += 1
    return n


def intent_markdown(layer: str, domain: str, *, has_contract: bool) -> str:
    contract_line = ""
    if has_contract:
        contract_line = (
            f"- 域合同：[`CONTRACT.md`](../../../../../ufc_core/{layer}/{domain}/CONTRACT.md)\n"
        )
    return f"""# `{layer}` / `{domain}` 设计意图（域桶）

> **域桶**：`ufc_core/{layer}/{domain}/`（含子域目录）。  
> **验收向**：本 INTENT + [`CONVENTIONS.md`](../../../CONVENTIONS.md) + 域内 `CONTRACT.md`（若存在）+ `manifest.json` ↔ `align.py`。

## 1. 问题与目标

- **职责**：本目录为 **六层架构** 中 `{layer}` 之下的一级 **域桶**；子目录为子域，**`manifest.json`** 仍按 **整桶递归** 与 `ufc_core` / `generated/` 对账。
- **过程体命名**：目标 MODULE 与主文件名以 **`_Ops` / `_Brg` / `_Def` / …** 角色后缀为主；遗留 ``*_Algo.f90`` 仅作迁移对象，参见 [CONVENTIONS.md §7](../../../CONVENTIONS.md)。

## 2. PR 边界与物理拆分

- **每波 PR**：单 **域桶**（本目录）或单 **子域子树**（在提交说明与 PPLAN 中点名路径）+ **构建通过**；与算法/物理补全尽量 **拆 PR**。
- **域级物理拆分 / 目录搬迁**：走 **PPLAN / 变更记录**；若与 `_Ops` 收敛交叉，**先冻结目录与 CMake，再改模块名与 `manifest`**（见 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) §1、§9.1）。

## 3. 与 Registry

- **`manifest.json`**：机器可读清单；初稿由本工具 + ``align.py --bootstrap`` 生成，**允许**人工删改与 `module` 例外字段。  
- **工作流**：`domain_procedure_registry_scan.py` → `domain_procedure_registry_align.py`；漂移报告：`REPORTS/DESIGN_GENERATED_DRIFT.md`（`domain_procedure_registry_align.py` 生成）。

## 4. 与现状差距（维护时填写）

| 条目 | `generated/` / 源码现状 | 目标（本 INTENT） | 优先级 |
|------|-------------------------|-------------------|--------|
| （可选） | | | |

## 5. 参考

{contract_line}- [`manifest.schema.json`](../../manifest.schema.json)  
- 推断清单（叙述密度参考）：[`UFC_层级域级f90文件推断清单_v2.0.md`](../../../../PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md)  
- 设计目录说明：[`design/README.md`](../../README.md)  
"""


def discover_domain_buckets(align) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    for layer in LAYERS:
        root = UFC_CORE / layer
        if not root.is_dir():
            continue
        for child in sorted(root.iterdir()):
            if not child.is_dir():
                continue
            name = child.name
            if name in SKIP_DOMAIN_NAMES:
                continue
            if f90_count_under(child, align) == 0:
                continue
            out.append((layer, name))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Print actions only; do not write files",
    )
    args = ap.parse_args()
    align = _load_align()
    pairs = discover_domain_buckets(align)
    created_intent = 0
    bootstrapped = 0
    for layer, domain in pairs:
        ddir = DESIGN_ROOT / layer / domain
        manifest_path = ddir / "manifest.json"
        intent_path = ddir / "INTENT.md"
        ufc_domain = UFC_CORE / layer / domain
        has_contract = (ufc_domain / "CONTRACT.md").is_file()
        if args.dry_run:
            print(f"Would ensure: {intent_path} + {manifest_path}  (ufc: {ufc_domain})")
            continue
        ddir.mkdir(parents=True, exist_ok=True)
        if not intent_path.is_file():
            intent_path.write_text(
                intent_markdown(layer, domain, has_contract=has_contract),
                encoding="utf-8",
                newline="\n",
            )
            created_intent += 1
        code = align.bootstrap_manifest(manifest_path)
        if code != 0:
            return code
        bootstrapped += 1
    if args.dry_run:
        print(f"Dry run: {len(pairs)} domain buckets.")
        return 0
    print(
        f"Done: {bootstrapped} manifests bootstrapped; "
        f"{created_intent} new INTENT.md (existing INTENT.md left unchanged)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
