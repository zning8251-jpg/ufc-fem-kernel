#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scan UFC/ufc_core Fortran sources and emit per-file Markdown registries under
UFC/docs/03_Domain_Pillars/DomainProcedureRegistry/generated/

**输出路径**：`UFC/docs/03_Domain_Pillars/DomainProcedureRegistry/generated/<与 ufc_core 相同的相对路径，扩展名改为 .md>`
- 例：`ufc_core/L3_MD/Element/Elem/Solid3D/MD_Elem_Sld3D.f90` →
  `generated/L3_MD/Element/Elem/Solid3D/MD_Elem_Sld3D.md`
- 与 [`UFC_ufc_core_目录权威分类.md`](../docs/05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) **层 → 域桶 → 子域** 物理树一致；**不再**将整棵子树压平到「首段域桶」单文件夹。
- **stem**：与 `.f90` 主文件名相同；三段式/四段式见各篇「命名」节与 [CONVENTIONS.md](../docs/03_Domain_Pillars/DomainProcedureRegistry/CONVENTIONS.md)。
- **Source** 元数据仍写真实 `ufc_core` 相对路径，便于跳转源码。

Layers: L1_IF, L2_NM, L3_MD, L4_PH, L5_RT, L6_AP

Path filter: any source under a path segment named **ExternalLibs** is skipped
(L2 外部封装 / 第三方接口聚合域；不生成逐文件清单)。

Limitations: line-oriented heuristics (not a full Fortran parser). Nested TYPE,
line continuations, INCLUDE, and CPP may confuse blocks; flagged in output.
"""
from __future__ import annotations

import hashlib
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

# Repo root: .../UFC when script lives at UFC/tools/
UFC_ROOT = Path(__file__).resolve().parents[1]
UFC_CORE = UFC_ROOT / "ufc_core"
OUT_ROOT = (
    UFC_ROOT
    / "docs"
    / "03_Domain_Pillars"
    / "DomainProcedureRegistry"
    / "generated"
)

LAYERS = ("L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP")

# 文件名 stem 末段若为 MODULE 角色后缀（闭集子集），则解析为「逻辑主线 + 第四段」；
# 与 DomainProcedureRegistry/CONVENTIONS.md、UFC_命名与数据结构规范 §3.2 对齐（启发式，非语法判定）。
STEM_FIRST_SEGMENTS: frozenset[str] = frozenset(
    {"if", "md", "ph", "rt", "ap", "nm", "kw", "ufc", "uf"}
)
STEM_ROLE_SUFFIXES: frozenset[str] = frozenset(
    {
        "def",
        "types",
        "type",
        "ops",
        "algo",
        "proc",
        "core",
        "eval",
        "solv",
        "integ",
        "assem",
        "apply",
        "brg",
        "api",
        "idx",
        "sync",
        "mgr",
        "ctrl",
        "parse",
        "valid",
        "reg",
        "defn",
        "init",
        "util",
        "ctx",
        "state",
        "desc",
        "uf",
        "wrapper",
        "module",
        "intf",
        "idx_api",
        "pairdef",
        "propdb",
        "surfbridge",
        "lib",
        "ids",
        "base",
        "bridge",
        "cfg",
        "drv",
        "sys",
        "found",
        "spcl",
        "high",
        "low",
    }
)

# Path segments to skip (any .f90 whose path contains this directory name).
SKIP_PATH_SEGMENTS: tuple[str, ...] = ("ExternalLibs",)


def skip_source_path(rel_posix: str) -> bool:
    parts = Path(rel_posix).parts
    return any(p in SKIP_PATH_SEGMENTS for p in parts)


def stem_domain_path_under_layer(rel_posix: str) -> str:
    """`L1_IF/Base/AI/x.f90` → `Base/AI`（不含层前缀与文件名）。"""
    pp = Path(rel_posix).parts
    if len(pp) <= 2:
        return ""
    return "/".join(pp[1:-1])


def allocate_registry_md_rel(layer: str, rel_src: str, used: set[str]) -> str:
    """
    分配 `generated` 下相对路径（POSIX）：镜像 `ufc_core` 相对路径，仅扩展名改为 `.md`。

    层直下无子目录的 `.f90`（极少见）→ `<Layer>/_root/<stem>.md`，避免把 `.md` 直接写在层目录下。
    若仍冲突（不应发生），退回源码路径哈希后缀。
    """
    pp = Path(rel_src).parts
    stem = Path(rel_src).stem
    if not pp or pp[0] != layer:
        base_rel = f"_orphan/{stem}.md"
    elif len(pp) <= 2:
        base_rel = f"{layer}/_root/{stem}.md"
    else:
        base_rel = Path(rel_src).with_suffix(".md").as_posix()
    if base_rel not in used:
        used.add(base_rel)
        return base_rel
    digest = hashlib.sha1(rel_src.encode("utf-8", errors="replace")).hexdigest()[:8]
    cand = f"{Path(base_rel).with_suffix('').as_posix()}__{digest}.md"
    k = 2
    while cand in used:
        cand = f"{Path(base_rel).with_suffix('').as_posix()}__{digest}_{k}.md"
        k += 1
    used.add(cand)
    return cand


def split_mainline_and_role(stem: str) -> tuple[str, str | None]:
    """
    按 stem 末段是否在角色闭集内，拆成「逻辑主线 + 第四段」。
    首段须为层前缀缩写（IF/MD/…）；否则不拆，避免误判第三方风格名。
    """
    parts = stem.split("_")
    if len(parts) < 2 or parts[0].lower() not in STEM_FIRST_SEGMENTS:
        return stem, None
    if len(parts) >= 3 and parts[-1].lower() in STEM_ROLE_SUFFIXES:
        return "_".join(parts[:-1]), parts[-1]
    return stem, None


def _md_links_from_registry_path(registry_md_rel: str) -> tuple[str, str]:
    """自 `generated/` 下某 `.md` 的相对路径（含文件名）计算到 CONVENTIONS / UFC_命名 的链接。"""
    n = len(Path(registry_md_rel).parts)
    base = "../" * n
    return f"{base}CONVENTIONS.md", f"{base}../UFC_命名与数据结构规范.md"


def naming_rubric_section(rel_src: str, registry_md_rel: str) -> str:
    """Registry 内「三段式 / 四段式 + 域级」说明块。"""
    stem = Path(rel_src).stem
    parts = stem.split("_")
    mainline, role = split_mainline_and_role(stem)
    domain_path = stem_domain_path_under_layer(rel_src)
    link_conv, link_std = _md_links_from_registry_path(registry_md_rel)
    n = len(Path(registry_md_rel).parts)
    link_class = ("../" * n) + "../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md"
    pat = f"`{parts[0]}_{{Domain+Feature}}`" if parts else "`{Layer}_{Domain}_{Feature}`"
    lines: list[str] = [
        "## 命名 — 三段式 / 四段式（对照规范）",
        "",
        f"与 [CONVENTIONS.md]({link_conv}) §1.1–§1.2、[UFC_命名与数据结构规范.md]({link_std}) §3 一致"
        "（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：",
        "",
        f"- **stem**: `{stem}`",
        f"- **逻辑主线（默认三段式 {pat}）**: `{mainline}`",
    ]
    if role is not None:
        algo_note = ""
        if role.lower() == "algo":
            algo_note = (
                " *（若本文件表示 **MODULE** 过程集合：规范推荐新代码用 **`_Ops`**；"
                "若仅为 **TYPE** 四型之一则保留 `_Algo` 语义，见 CONVENTIONS §2。）*"
            )
        lines.append(f"- **第四段角色（四段式）**: `_{role}`{algo_note}")
    else:
        lines.append(
            "- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*"
        )
    dom_disp = domain_path if domain_path else "*(层直下，无中间子目录)*"
    lines.append(f"- **源码子路径（层下目录，不含文件名）**: `{dom_disp}`")
    lines.append(
        f"- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/{registry_md_rel}` "
        f"— *与 [`UFC_ufc_core_目录权威分类.md`]({link_class}) 物理树一致；"
        "三段式/四段式解析见上*"
    )
    lines.append("")
    return "\n".join(lines)

# TYPE definition start: TYPE [, attributes] :: name  (not TYPE( for declaration)
TYPE_DEF_RE = re.compile(
    r"^\s*TYPE\s*(?:,\s*[^(:!]+)*\s*::\s*(\w+)\s*(?:!.*)?$",
    re.IGNORECASE,
)
# Declaration using TYPE( kind ) :: x
TYPE_PAREN_RE = re.compile(r"^\s*TYPE\s*\(", re.IGNORECASE)

END_TYPE_RE = re.compile(r"^\s*END\s+TYPE\s*(\w+)\s*$", re.IGNORECASE)
END_TYPE_BARE_RE = re.compile(r"^\s*END\s+TYPE\s*$", re.IGNORECASE)

MODULE_RE = re.compile(r"^\s*MODULE\s+(\w+)\s*(?:!.*)?$", re.IGNORECASE)
END_MODULE_RE = re.compile(r"^\s*END\s+MODULE\s*(\w+)\s*$", re.IGNORECASE)

SUBFUN_RE = re.compile(
    r"^\s*(?:(?:RECURSIVE|PURE|ELEMENTAL)\s+){0,3}(SUBROUTINE|FUNCTION)\s+(\w+)\b",
    re.IGNORECASE,
)

INTERFACE_START = re.compile(r"^\s*INTERFACE\b", re.IGNORECASE)
INTERFACE_END = re.compile(r"^\s*END\s+INTERFACE\b", re.IGNORECASE)

MAX_TYPE_BODY_LINES = 220


def _strip_inline_comment(line: str) -> str:
    """Remove trailing Fortran comment when not in string (best-effort)."""
    if "!" not in line:
        return line.rstrip()
    out = []
    in_sq = False
    in_dq = False
    i = 0
    while i < len(line):
        c = line[i]
        if c == "'" and not in_dq:
            in_sq = not in_sq
        elif c == '"' and not in_sq:
            in_dq = not in_dq
        elif c == "!" and not in_sq and not in_dq:
            break
        out.append(c)
        i += 1
    return "".join(out).rstrip()


def find_module_name(lines: list[str]) -> str | None:
    for ln in lines:
        s = ln.strip()
        if not s or s.startswith("!"):
            continue
        m = MODULE_RE.match(ln)
        if m:
            return m.group(1)
    return None


def find_type_blocks(lines: list[str]) -> list[tuple[str, int, int, list[str]]]:
    """
    Return list of (type_name, start_line_1based, end_line_1based, body_lines).
    Uses stack for nested TYPE ... END TYPE.
    """
    blocks: list[tuple[str, int, int, list[str]]] = []
    stack: list[tuple[str, int]] = []  # (name, start_idx 0-based)

    for idx, raw in enumerate(lines):
        line = raw.rstrip("\n")
        if TYPE_PAREN_RE.match(line):
            continue
        m = TYPE_DEF_RE.match(line)
        if m:
            stack.append((m.group(1), idx))
            continue
        if stack:
            em = END_TYPE_RE.match(line)
            if em:
                name = em.group(1)
                if stack[-1][0].lower() != name.lower():
                    # Mismatch: pop until matching name or pop one (best-effort)
                    while len(stack) > 1 and stack[-1][0].lower() != name.lower():
                        stack.pop()
                if stack and stack[-1][0].lower() == name.lower():
                    start_name, start_idx = stack.pop()
                    body = lines[start_idx : idx + 1]
                    blocks.append(
                        (start_name, start_idx + 1, idx + 1, body)
                    )
                continue
            if END_TYPE_BARE_RE.match(line):
                start_name, start_idx = stack.pop()
                body = lines[start_idx : idx + 1]
                blocks.append((start_name, start_idx + 1, idx + 1, body))
                continue

    return blocks


def line_in_any_block(line_no_1: int, ranges: list[tuple[int, int]]) -> bool:
    for a, b in ranges:
        if a <= line_no_1 <= b:
            return True
    return False


def find_procedures(lines: list[str], type_ranges: list[tuple[int, int]]):
    """Return (module_level, type_bound) lists of (kind, name, line_no, sig_line)."""
    mod_level: list[tuple[str, str, int, str]] = []
    type_bound: list[tuple[str, str, int, str]] = []
    for i, raw in enumerate(lines, start=1):
        ln = raw.rstrip("\n")
        if ln.strip().startswith("!"):
            continue
        m = SUBFUN_RE.match(ln)
        if not m:
            continue
        kind, name = m.group(1).upper(), m.group(2)
        sig = _strip_inline_comment(ln).strip()
        if line_in_any_block(i, type_ranges):
            type_bound.append((kind, name, i, sig))
        else:
            mod_level.append((kind, name, i, sig))
    return mod_level, type_bound


def find_interface_blocks(lines: list[str]) -> list[tuple[int, int, str]]:
    """Return (start_line, end_line, first_line_text) for each INTERFACE..END INTERFACE."""
    out: list[tuple[int, int, str]] = []
    depth = 0
    start = 0
    head = ""
    for i, raw in enumerate(lines, start=1):
        ln = raw.rstrip("\n")
        if INTERFACE_START.match(ln) and depth == 0:
            depth = 1
            start = i
            head = _strip_inline_comment(ln).strip()
            continue
        if depth:
            if INTERFACE_START.match(ln):
                depth += 1
            elif INTERFACE_END.match(ln):
                depth -= 1
                if depth == 0:
                    out.append((start, i, head))
    return out


def emit_file_md(
    rel_src: str,
    registry_md_rel: str,
    lines: list[str],
    module: str | None,
    types: list[tuple[str, int, int, list[str]]],
    mod_procs,
    type_procs,
    interfaces,
) -> str:
    type_ranges = [(a, b) for _, a, b, _ in types]
    parts: list[str] = []
    parts.append(f"# `{Path(rel_src).name}`")
    parts.append("")
    parts.append(f"- **Source**: `{rel_src}`")
    parts.append(f"- **Generated (UTC)**: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}")
    parts.append(f"- **MODULE (heuristic)**: `{module or '*(none)*'}`")
    parts.append("")
    parts.append("> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.")
    parts.append("")
    parts.append(naming_rubric_section(rel_src, registry_md_rel))
    parts.append("## TYPE blocks")
    parts.append("")
    if not types:
        parts.append("*(no TYPE definition blocks detected)*")
        parts.append("")
    for name, a, b, body in types:
        parts.append(f"### `{name}` (lines {a}–{b})")
        parts.append("")
        bl = body
        truncated = False
        if len(bl) > MAX_TYPE_BODY_LINES:
            bl = bl[:MAX_TYPE_BODY_LINES]
            truncated = True
        parts.append("```fortran")
        parts.extend(s.rstrip("\n") for s in bl)
        parts.append("```")
        if truncated:
            parts.append("")
            parts.append(f"> Truncated: body > {MAX_TYPE_BODY_LINES} lines; see source file.")
        parts.append("")

    parts.append("## Module-level procedures (`SUBROUTINE` / `FUNCTION`)")
    parts.append("")
    if not mod_procs:
        parts.append("*(none detected outside TYPE bodies)*")
    else:
        parts.append("| Kind | Name | Line | Signature (first line) |")
        parts.append("|------|------|------|-------------------------|")
        for kind, name, ln, sig in mod_procs:
            sig_esc = sig.replace("|", "\\|")
            parts.append(f"| {kind} | `{name}` | {ln} | `{sig_esc}` |")
    parts.append("")

    parts.append("## Procedures detected inside TYPE bodies")
    parts.append("")
    if not type_procs:
        parts.append("*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*")
    else:
        parts.append("| Kind | Name | Line | Signature (first line) |")
        parts.append("|------|------|------|-------------------------|")
        for kind, name, ln, sig in type_procs:
            sig_esc = sig.replace("|", "\\|")
            parts.append(f"| {kind} | `{name}` | {ln} | `{sig_esc}` |")
    parts.append("")

    parts.append("## INTERFACE blocks (outline)")
    parts.append("")
    if not interfaces:
        parts.append("*(none)*")
    else:
        parts.append("| Lines | Header |")
        parts.append("|-------|--------|")
        for a, b, h in interfaces:
            he = h.replace("|", "\\|")
            parts.append(f"| {a}–{b} | `{he}` |")
    parts.append("")

    return "\n".join(parts)


def main() -> int:
    if not UFC_CORE.is_dir():
        print("ufc_core not found:", UFC_CORE, file=sys.stderr)
        return 1

    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    # 全量重写：避免旧「镜像源码树」目录残留
    if OUT_ROOT.is_dir():
        for ch in sorted(OUT_ROOT.iterdir(), key=lambda p: str(p), reverse=True):
            if ch.is_dir():
                shutil.rmtree(ch, ignore_errors=True)
            elif ch.is_file():
                ch.unlink(missing_ok=True)

    stats: dict[str, int] = {}
    all_written: list[tuple[str, Path]] = []

    for layer in LAYERS:
        base = UFC_CORE / layer
        if not base.is_dir():
            print("skip missing layer", base)
            continue
        f90s_all = sorted(base.rglob("*.f90"))
        f90s = [
            fp
            for fp in f90s_all
            if not skip_source_path(fp.relative_to(UFC_CORE).as_posix())
        ]
        stats[layer] = len(f90s)
        used_registry: set[str] = set()
        for fp in f90s:
            rel = fp.relative_to(UFC_CORE).as_posix()
            text = fp.read_text(encoding="utf-8", errors="replace")
            raw_lines = text.splitlines()
            # Normalize: keep original for TYPE bodies; use splitlines without \r
            mod = find_module_name(raw_lines)
            types = find_type_blocks(raw_lines)
            type_ranges = [(a, b) for _, a, b, _ in types]
            mod_procs, type_procs = find_procedures(raw_lines, type_ranges)
            interfaces = find_interface_blocks(raw_lines)
            reg_rel = allocate_registry_md_rel(layer, rel, used_registry)
            md = emit_file_md(rel, reg_rel, raw_lines, mod, types, mod_procs, type_procs, interfaces)
            out_path = OUT_ROOT / Path(reg_rel)
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_text(md, encoding="utf-8", newline="\n")
            all_written.append((layer, out_path))

        # per-layer index（按域级 = 源码层下首段子目录分组）
        layer_dir = OUT_ROOT / layer
        layer_dir.mkdir(parents=True, exist_ok=True)
        buckets: dict[str, list[str]] = {}
        for _ly, outp in all_written:
            if _ly != layer:
                continue
            reg_posix = outp.relative_to(OUT_ROOT).as_posix()
            pp = Path(reg_posix).parts
            bucket = pp[1] if len(pp) >= 2 else "_root"
            buckets.setdefault(bucket, []).append(reg_posix)

        idx_lines = [
            f"# 层级索引：`{layer}`（Registry）",
            "",
            f"- **`.f90` 文件数**: {len(f90s)}",
            "",
            "> **命名 / 布局**：`generated/<层>/…/<stem>.md` — **目录树镜像** `ufc_core/<层>/…/*.f90`（仅扩展名改为 `.md`）；"
            "按 **域桶**（层下首段目录名）分组索引。**stem**=源码文件名；三段式/四段式见各篇首节。"
            "**源码路径**见各篇 `Source`。权威约定见 [CONVENTIONS.md](../CONVENTIONS.md) §0、[UFC_命名与数据结构规范.md](../../UFC_命名与数据结构规范.md) §3。",
            "",
        ]
        for b in sorted(buckets):
            idx_lines.append(f"## 域级 `{b}`（`ufc_core/{layer}/{b}/…` 一级子目录）")
            idx_lines.append("")
            for reg_posix in sorted(buckets[b]):
                name = Path(reg_posix).name
                parts_md = Path(reg_posix).parts
                link = Path(*parts_md[1:]).as_posix() if len(parts_md) > 1 else name
                idx_lines.append(f"- [{name}]({link})")
            idx_lines.append("")
        (layer_dir / "_LAYER_INDEX.md").write_text(
            "\n".join(idx_lines), encoding="utf-8", newline="\n"
        )

    # Root stats
    root_lines = [
        "# Registry generation stats",
        "",
        f"- **Output root**: `UFC/docs/03_Domain_Pillars/DomainProcedureRegistry/generated/`",
        f"- **Generated (UTC)**: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
        f"- **Path skip**: path segment(s) `{', '.join(SKIP_PATH_SEGMENTS)}` — matching `.f90` files are **not** emitted.",
        "",
        "**命名 / 布局**：`generated` **镜像** `ufc_core` 相对路径（`.f90`→`.md`）；层索引按 **域桶**（路径首段）分组。"
        "各篇含「三段式 / 四段式」说明。见 [CONVENTIONS.md](../CONVENTIONS.md) §0。",
        "",
        "## File counts by layer",
        "",
        "| Layer | .f90 files |",
        "|-------|------------|",
    ]
    total = 0
    for ly in LAYERS:
        c = stats.get(ly, 0)
        total += c
        root_lines.append(f"| `{ly}` | {c} |")
    root_lines.append(f"| **Total** | **{total}** |")
    root_lines.append("")
    (OUT_ROOT / "_REGISTRY_STATS.md").write_text(
        "\n".join(root_lines), encoding="utf-8", newline="\n"
    )

    print("Wrote", len(all_written), "markdown files under", OUT_ROOT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
