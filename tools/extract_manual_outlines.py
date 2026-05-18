#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Manual/*.pdf 结构化抽取（对齐 .cursor/rules/pdf-processing.mdc：优先 pdfplumber 表格/正文；
  大文件为避免超时，目录与首页用 PyMuPDF，小文件可选 pdfplumber 前若干页）。
输出：UFC/REPORTS/manual_extract_raw.json
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

MANUAL = Path(__file__).resolve().parents[1] / "Manual"
OUT = Path(__file__).resolve().parents[1] / "REPORTS" / "manual_extract_raw.json"


def toc_and_front_fitz(path: Path, front_pages: int) -> dict:
    import fitz

    doc = fitz.open(path)
    toc = doc.get_toc(simple=True) or []
    toc_out = [{"level": int(a), "title": b.strip(), "page_1based": int(c)} for a, b, c in toc]
    texts: list[str] = []
    n = min(doc.page_count, front_pages)
    for i in range(n):
        texts.append(doc.load_page(i).get_text("text") or "")
    doc.close()
    return {"toc": toc_out, "front_text_pages": n, "front_text_joined": "\n".join(texts)[:200000]}


def front_pdfplumber(path: Path, max_pages: int, char_cap: int) -> str:
    import pdfplumber

    parts: list[str] = []
    with pdfplumber.open(path) as pdf:
        n = min(len(pdf.pages), max_pages)
        for i in range(n):
            parts.append(pdf.pages[i].extract_text() or "")
    return "\n".join(parts)[:char_cap]


def main() -> int:
    if not MANUAL.is_dir():
        print(f"ERROR: {MANUAL} not found", file=sys.stderr)
        return 1
    pdfs = sorted(MANUAL.glob("*.pdf"))
    if not pdfs:
        print("ERROR: no PDF", file=sys.stderr)
        return 1

    report: dict = {"manual_dir": str(MANUAL), "pdfs": []}
    for p in pdfs:
        sz = p.stat().st_size
        entry = {"file": p.name, "size_bytes": sz}
        # 大书：仅 fitz 目录 + 15 页正文；小书：fitz + pdfplumber 前 20 页抽样
        entry["fitz"] = toc_and_front_fitz(p, 15 if sz > 15_000_000 else 22)
        try:
            if sz < 18_000_000:
                entry["pdfplumber_sample"] = front_pdfplumber(p, 20, 120000)
        except Exception as e:  # noqa: BLE001
            entry["pdfplumber_sample_error"] = str(e)
        report["pdfs"].append(entry)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(str(OUT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
