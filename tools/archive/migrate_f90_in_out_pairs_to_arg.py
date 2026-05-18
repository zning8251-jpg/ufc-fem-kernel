#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Merge consecutive Fortran TYPE ... _In / TYPE ... _Out pairs into TYPE ... _Arg
and rewrite procedures that use (in, out) dummies with matching *_In / *_Out types.

Heuristic (UFC L4_PH SIO refactor):
  - TYPE, PUBLIC :: <Prefix>_In ... END TYPE <Prefix>_In
    followed by
  - TYPE, PUBLIC :: <Prefix>_Out ... END TYPE <Prefix>_Out
  => single TYPE, PUBLIC :: <Prefix>_Arg with merged fields and ! [IN] / ! [OUT] / ! [INOUT]
  - SUBROUTINE foo(in, out) with TYPE(<Prefix>_In), INTENT(IN) :: in and
    TYPE(<Prefix>_Out), INTENT(OUT) :: out immediately after
    => SUBROUTINE foo(arg) + TYPE(<Prefix>_Arg), INTENT(INOUT) :: arg
    => in% / out% -> arg% inside that subroutine body (to matching END SUBROUTINE)

Duplicate component names in In vs Out become a single component tagged [INOUT].

Does not parse full Fortran; skip files with parse errors (report).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

TYPE_PUBLIC_IN = re.compile(r"^\s*TYPE,\s*PUBLIC\s*::\s*(\w+)_In\s*$", re.I)
TYPE_PUBLIC_OUT = re.compile(r"^\s*TYPE,\s*PUBLIC\s*::\s*(\w+)_Out\s*$", re.I)
END_TYPE = re.compile(r"^\s*END\s+TYPE\s+(\w+)\s*$", re.I)
FIELD_LINE = re.compile(r"^(\s*)(.+?)\s+::\s*(\w+)\s*(!.*)?$")


def strip_continuation(lines: list[str]) -> list[str]:
    return lines


def extract_type_block(lines: list[str], start: int) -> tuple[str, list[str], int]:
    """Return (type_name, inner_lines, index_after_end_type)."""
    m = re.match(r"^\s*TYPE,\s*PUBLIC\s*::\s*(\w+)\s*$", lines[start], re.I)
    if not m:
        raise ValueError("not a TYPE start")
    name = m.group(1)
    inner: list[str] = []
    i = start + 1
    while i < len(lines):
        em = END_TYPE.match(lines[i])
        if em and em.group(1).lower() == name.lower():
            return name, inner, i + 1
        inner.append(lines[i])
        i += 1
    raise ValueError(f"unclosed TYPE {name}")


def parse_fields(inner_lines: list[str]) -> list[tuple[str, str]]:
    """List of (component_name, full_line_without_trailing_comment optional)."""
    fields: list[tuple[str, str]] = []
    for raw in inner_lines:
        line = raw.rstrip()
        if not line.strip() or line.strip().startswith("!"):
            continue
        m = FIELD_LINE.match(line)
        if not m:
            continue
        _indent, decl, comp, trail = m.groups()
        fields.append((comp, line))
    return fields


def merge_field_lines(
    in_fields: list[tuple[str, str]], out_fields: list[tuple[str, str]]
) -> list[str]:
    in_map = dict(in_fields)
    out_map = dict(out_fields)
    names_in = list(in_map.keys())
    merged: list[str] = []
    used_out: set[str] = set()

    def tag_line(line: str, tag: str) -> str:
        line = line.rstrip()
        if "! [" in line:
            return line
        return line + "                   " + tag

    for n in names_in:
        li = in_map[n]
        if n in out_map:
            lo = out_map[n]
            if li.strip() == lo.strip():
                merged.append(tag_line(li, "! [INOUT]"))
            else:
                # Prefer IN declaration shape; mark INOUT
                merged.append(tag_line(li, "! [INOUT]"))
            used_out.add(n)
        else:
            merged.append(tag_line(li, "! [IN]"))

    for n, lo in out_fields:
        if n in used_out:
            continue
        merged.append(tag_line(lo, "! [OUT]"))

    return merged


def merge_type_sections(text: str) -> tuple[str, list[tuple[str, str, str]]]:
    """
    Returns new_text, list of (prefix, old_in_name, old_out_name) for renames.
    old_in_name = prefix + '_In', etc.
    """
    lines = text.splitlines(keepends=True)
    out_lines: list[str] = []
    renames: list[tuple[str, str, str]] = []
    i = 0
    while i < len(lines):
        mi = TYPE_PUBLIC_IN.match(lines[i])
        if not mi:
            out_lines.append(lines[i])
            i += 1
            continue
        prefix = mi.group(1)
        try:
            in_name, in_inner, j = extract_type_block(lines, i)
        except ValueError:
            out_lines.append(lines[i])
            i += 1
            continue
        if in_name != f"{prefix}_In":
            out_lines.append(lines[i])
            i += 1
            continue
        if j >= len(lines):
            out_lines.extend(lines[i:j])
            i = j
            continue
        j2 = j
        while j2 < len(lines) and (
            not lines[j2].strip()
            or lines[j2].strip().startswith("!")
        ):
            j2 += 1
        if j2 >= len(lines):
            out_lines.extend(lines[i:j])
            i = j
            continue
        mo = TYPE_PUBLIC_OUT.match(lines[j2])
        if not mo or mo.group(1) != prefix:
            out_lines.extend(lines[i:j])
            i = j
            continue
        try:
            out_name, out_inner, k = extract_type_block(lines, j2)
        except ValueError:
            out_lines.extend(lines[i:j])
            i = j
            continue
        if out_name != f"{prefix}_Out":
            out_lines.extend(lines[i:j])
            i = j
            continue

        in_fields = parse_fields(in_inner)
        out_fields = parse_fields(out_inner)
        merged_inner = merge_field_lines(in_fields, out_fields)
        arg_name = f"{prefix}_Arg"
        renames.append((prefix, in_name, out_name))

        out_lines.extend(lines[j:j2])
        out_lines.append(f"  TYPE, PUBLIC :: {arg_name}\n")
        for ml in merged_inner:
            if not ml.endswith("\n"):
                ml = ml + "\n"
            out_lines.append("    " + ml.lstrip() if ml.strip() else ml)
        out_lines.append(f"  END TYPE {arg_name}\n")
        out_lines.append("\n")
        i = k

    return "".join(out_lines), renames


def transform_subroutines(text: str, prefixes: list[str]) -> str:
    pref_set = set(prefixes)
    lines = text.splitlines(keepends=True)
    out: list[str] = []
    i = 0
    sub_start = re.compile(
        r"^\s*SUBROUTINE\s+(\w+)\s*\(\s*in\s*,\s*out\s*\)\s*$", re.I
    )
    sub_start_sfx = re.compile(
        r"^\s*SUBROUTINE\s+(\w+)\s*\(\s*in_(\w+)\s*,\s*out_(\w+)\s*\)\s*$",
        re.I,
    )
    type_in = re.compile(
        r"^\s*TYPE\s*\(\s*(\w+)_In\s*\)\s*,\s*INTENT\s*\(\s*IN\s*\)\s*::\s*in\s*$", re.I
    )
    type_out = re.compile(
        r"^\s*TYPE\s*\(\s*(\w+)_Out\s*\)\s*,\s*INTENT\s*\(\s*OUT\s*\)\s*::\s*out\s*$", re.I
    )
    type_in_sfx = re.compile(
        r"^\s*TYPE\s*\(\s*(\w+)_In\s*\)\s*,\s*INTENT\s*\(\s*IN\s*\)\s*::\s*in_(\w+)\s*$",
        re.I,
    )
    type_out_sfx = re.compile(
        r"^\s*TYPE\s*\(\s*(\w+)_Out\s*\)\s*,\s*INTENT\s*\(\s*OUT\s*\)\s*::\s*out_(\w+)\s*$",
        re.I,
    )

    def emit_transformed(
        sub_name: str,
        pref: str,
        indent: str,
        dummy_in: str,
        dummy_out: str,
        new_dummy: str,
        start_i: int,
    ) -> tuple[str, int]:
        body: list[str] = []
        j = start_i
        while j < len(lines):
            em = re.match(r"^\s*END\s+SUBROUTINE\s+(\w+)\s*$", lines[j], re.I)
            if em and em.group(1).lower() == sub_name.lower():
                blob = "".join(body)
                blob = blob.replace(dummy_in + "%", new_dummy + "%")
                blob = blob.replace(dummy_out + "%", new_dummy + "%")
                return blob + lines[j], j + 1
            body.append(lines[j])
            j += 1
        return "".join(body), start_i

    while i < len(lines):
        m = sub_start.match(lines[i])
        ms = sub_start_sfx.match(lines[i])
        if m and i + 2 < len(lines):
            mi = type_in.match(lines[i + 1])
            mo = type_out.match(lines[i + 2])
            if mi and mo and mi.group(1) == mo.group(1):
                pref = mi.group(1)
                if pref in pref_set:
                    sub_name = m.group(1)
                    indent = lines[i + 1][: len(lines[i + 1]) - len(lines[i + 1].lstrip())]
                    out.append(re.sub(r"\(\s*in\s*,\s*out\s*\)", "(arg)", lines[i], flags=re.I))
                    out.append(f"{indent}TYPE({pref}_Arg), INTENT(INOUT) :: arg\n")
                    i += 3
                    blob, i = emit_transformed(sub_name, pref, indent, "in", "out", "arg", i)
                    out.append(blob)
                    continue
        if ms and i + 2 < len(lines):
            sfx = ms.group(2)
            if ms.group(2) != ms.group(3):
                out.append(lines[i])
                i += 1
                continue
            mi = type_in_sfx.match(lines[i + 1])
            mo = type_out_sfx.match(lines[i + 2])
            if mi and mo and mi.group(1) == mo.group(1) and mi.group(2) == sfx:
                pref = mi.group(1)
                if pref in pref_set:
                    sub_name = ms.group(1)
                    indent = lines[i + 1][: len(lines[i + 1]) - len(lines[i + 1].lstrip())]
                    din, dout = f"in_{sfx}", f"out_{sfx}"
                    anew = f"arg_{sfx}"
                    sig = re.sub(
                        rf"\(\s*{re.escape(din)}\s*,\s*{re.escape(dout)}\s*\)",
                        f"({anew})",
                        lines[i],
                        flags=re.I,
                    )
                    out.append(sig)
                    out.append(f"{indent}TYPE({pref}_Arg), INTENT(INOUT) :: {anew}\n")
                    i += 3
                    blob, i = emit_transformed(sub_name, pref, indent, din, dout, anew, i)
                    out.append(blob)
                    continue
        out.append(lines[i])
        i += 1
    return "".join(out)


def replace_public_in_out(text: str) -> str:
    def repl(m: re.Match[str]) -> str:
        indent = m.group(1)
        parts = m.group(2).split(",")
        new_parts: list[str] = []
        i = 0
        while i < len(parts):
            a = parts[i].strip()
            if i + 1 < len(parts):
                b = parts[i + 1].strip()
                if a.endswith("_In") and b.endswith("_Out") and a[: -len("_In")] == b[: -len("_Out")]:
                    new_parts.append(a[: -len("_In")] + "_Arg")
                    i += 2
                    continue
            new_parts.append(a)
            i += 1
        return indent + "PUBLIC :: " + ", ".join(new_parts)

    return re.sub(
        r"^(\s*)PUBLIC\s*::\s*(.+)$",
        repl,
        text,
        flags=re.MULTILINE,
    )


def replace_use_only_types(text: str) -> str:
    """PH_Elem_C3D8_ShapeFunc_In, & -> PH_Elem_C3D8_ShapeFunc_Arg (drop duplicate)."""
    lines = text.splitlines(keepends=True)
    out: list[str] = []
    for line in lines:
        if "ONLY:" not in line.upper() and "only:" not in line:
            out.append(line)
            continue
        # split ONLY list
        m = re.search(r"ONLY\s*:\s*(.+)$", line, re.I)
        if not m:
            out.append(line)
            continue
        head = line[: m.start(1)]
        lst = m.group(1)
        items = [x.strip() for x in lst.split(",")]
        seen_arg: set[str] = set()
        new_items: list[str] = []
        i = 0
        while i < len(items):
            it = items[i]
            if it.endswith("_In") and i + 1 < len(items):
                nxt = items[i + 1]
                if nxt.endswith("_Out") and it[:-3] == nxt[:-4]:
                    arg = it[:-3] + "Arg"
                    if arg not in seen_arg:
                        new_items.append(arg)
                        seen_arg.add(arg)
                    i += 2
                    continue
            if it.endswith("_Arg") and it in seen_arg:
                i += 1
                continue
            new_items.append(it)
            i += 1
        out.append(head + ", ".join(new_items) + "\n")
    return "".join(out)


def replace_type_refs(text: str) -> str:
    """TYPE(Prefix_In) -> TYPE(Prefix_Arg), TYPE(Prefix_Out) -> TYPE(Prefix_Arg)"""
    text = re.sub(
        r"TYPE\s*\(\s*(\w+)_In\s*\)",
        lambda m: f"TYPE({m.group(1)}_Arg)",
        text,
        flags=re.I,
    )
    text = re.sub(
        r"TYPE\s*\(\s*(\w+)_Out\s*\)",
        lambda m: f"TYPE({m.group(1)}_Arg)",
        text,
        flags=re.I,
    )
    return text


def collapse_double_arg_declarations(text: str) -> str:
    """
    TYPE(P)_Arg :: in_foo / TYPE(P)_Arg :: out_foo  -> TYPE(P)_Arg :: arg_foo
    when foo matches suffix after in_/out_.
    """
    lines = text.splitlines(keepends=True)
    i = 0
    out: list[str] = []
    pat = re.compile(
        r"^\s*TYPE\s*\(\s*(\w+)_Arg\s*\)\s*::\s*in_(\w+)\s*$",
        re.I,
    )
    pat2 = re.compile(
        r"^\s*TYPE\s*\(\s*(\w+)_Arg\s*\)\s*::\s*out_(\w+)\s*$",
        re.I,
    )
    while i < len(lines):
        m1 = pat.match(lines[i])
        if m1 and i + 1 < len(lines):
            m2 = pat2.match(lines[i + 1])
            if m2 and m1.group(1) == m2.group(1) and m1.group(2) == m2.group(2):
                pref = m1.group(1)
                sfx = m1.group(2)
                indent = lines[i][: len(lines[i]) - len(lines[i].lstrip())]
                out.append(f"{indent}TYPE({pref}_Arg) :: arg_{sfx}\n")
                old_in = f"in_{sfx}%"
                old_out = f"out_{sfx}%"
                new_a = f"arg_{sfx}%"
                # scan forward until blank line after declarations? simplistic: replace in rest of file
                # defer: global replace old_in/old_out after this block
                i += 2
                continue
        out.append(lines[i])
        i += 1
    text = "".join(out)
    # second pass: rename in_suffix% / out_suffix% for known suffixes from collapsed pairs
    for m in re.finditer(
        r"TYPE\s*\(\s*(\w+)_Arg\s*\)\s*::\s*arg_(\w+)",
        text,
        flags=re.I,
    ):
        pref, sfx = m.group(1), m.group(2)
        text = text.replace(f"in_{sfx}%", f"arg_{sfx}%")
        text = text.replace(f"out_{sfx}%", f"arg_{sfx}%")
    return text


def replace_calls_inout_to_arg(text: str) -> str:
    """CALL foo(in, out) / CALL foo(in_x, out_x) -> single arg dummy."""
    text = re.sub(
        r"CALL\s+(\w+)\s*\(\s*in\s*,\s*out\s*\)",
        r"CALL \1(arg)",
        text,
        flags=re.I,
    )
    text = re.sub(
        r"CALL\s+(\w+)\s*\(\s*in_(\w+)\s*,\s*out_\2\s*\)",
        r"CALL \1(arg_\2)",
        text,
        flags=re.I,
    )
    return text


def process_file(path: Path, apply: bool) -> list[str]:
    raw = path.read_text(encoding="utf-8-sig", errors="replace")
    issues: list[str] = []
    text, renames = merge_type_sections(raw)
    if not renames:
        return [f"{path}: no _In/_Out pairs found"]
    prefixes = [p for p, _a, _b in renames]
    text = transform_subroutines(text, prefixes)
    text = replace_calls_inout_to_arg(text)
    text = collapse_double_arg_declarations(text)
    text = replace_type_refs(text)
    text = replace_public_in_out(text)
    text = replace_use_only_types(text)
    if text != raw:
        if apply:
            path.write_text(text, encoding="utf-8", newline="\n")
        issues.append(f"{path}: merged {len(renames)} pair(s)" + (" APPLY" if apply else " dry-run"))
    else:
        issues.append(f"{path}: unchanged")
    return issues


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--under", type=Path, help="Root directory to scan for .f90")
    ap.add_argument("--file", type=Path, help="Single .f90 file to process")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    all_issues: list[str] = []
    if args.file:
        fp = args.file.resolve()
        if not fp.is_file():
            print("Not a file:", fp, file=sys.stderr)
            return 2
        all_issues.extend(process_file(fp, args.apply))
    else:
        if not args.under:
            print("Need --under or --file", file=sys.stderr)
            return 2
        root: Path = args.under
        if not root.is_dir():
            print("Not a directory:", root, file=sys.stderr)
            return 2
        for fp in sorted(root.rglob("*.f90")):
            if "ExternalLibs" in fp.parts:
                continue
            txt = fp.read_text(encoding="utf-8-sig", errors="replace")
            if not re.search(r"TYPE,\s*PUBLIC\s*::\s*\w+_In\b", txt):
                continue
            all_issues.extend(process_file(fp, args.apply))
    for line in all_issues:
        print(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
