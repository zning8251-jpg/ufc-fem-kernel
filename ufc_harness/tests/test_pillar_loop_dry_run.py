#!/usr/bin/env python3
"""Regression tests for pillar-loop report shape (stdlib only; no pytest)."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

# ufc_harness/ -> parent is UFC repo root for sibling imports when run from repo
HARNESS_ROOT = Path(__file__).resolve().parent.parent
if str(HARNESS_ROOT) not in sys.path:
    sys.path.insert(0, str(HARNESS_ROOT))

import pillar_loop as pl  # noqa: E402


class TestPillarLoopReportMarkdown(unittest.TestCase):
    def test_dry_run_report_sections(self) -> None:
        ts = "20200101_000000"
        ufc_root = Path("D:/_pillar_test_root")
        scan = str(ufc_root / "ufc_core")
        pillars: list[dict] = [
            {
                "id": "P1",
                "name_en": "Material",
                "name_zh": "材料",
                "default_scan_subdir": "ufc_core/L3_MAT",
                "path_markers": ["/L3_MAT/"],
            }
        ]
        cfg: dict = {"pillars": pillars, "binary_structure": {"cold": [], "hot": []}}
        md = pl._report_markdown(
            ts,
            ufc_root,
            scan,
            [],
            {},
            pillars,
            cfg,
            dry_run=True,
            cross_cutting=[],
        )
        self.assertIn("# Pillar-loop decision report", md)
        self.assertIn("## Binary structure", md)
        self.assertIn("## Six pillars (P1–P6)", md)
        self.assertIn("## P0 by pillar", md)
        self.assertIn("_Skipped in dry-run._", md)
        self.assertIn("P1", md)


if __name__ == "__main__":
    unittest.main()
