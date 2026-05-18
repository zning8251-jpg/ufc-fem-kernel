#!/usr/bin/env python3
"""Tests for agent_harness_ops (stdlib only)."""

from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

HARNESS_ROOT = Path(__file__).resolve().parent.parent
if str(HARNESS_ROOT) not in sys.path:
    sys.path.insert(0, str(HARNESS_ROOT))

import agent_harness_ops as aho  # noqa: E402


class TestAgentHarnessOps(unittest.TestCase):
    def setUp(self) -> None:
        self._td = tempfile.TemporaryDirectory()
        self.addCleanup(self._td.cleanup)
        os.environ["UFC_AGENT_REPORTS_DIR"] = self._td.name

    def tearDown(self) -> None:
        os.environ.pop("UFC_AGENT_REPORTS_DIR", None)

    def test_bundle_writes_markdown(self) -> None:
        import argparse

        ns = argparse.Namespace(task="unit-test", json_sidecar=False)
        rc = aho.cmd_agent_bundle(ns)
        self.assertEqual(rc, 0)
        reports = Path(self._td.name)
        mds = list(reports.glob("agent_context_bundle_*.md"))
        self.assertEqual(len(mds), 1)
        text = mds[0].read_text(encoding="utf-8")
        self.assertIn("UFC closed loop", text)
        self.assertIn("unit-test", text)

    def test_checkpoint_roundtrip(self) -> None:
        import argparse

        self.assertEqual(
            0,
            aho.cmd_agent_checkpoint(
                argparse.Namespace(
                    action="init", session="t1", goal="g", label=None, harness_cmd=None, rc=None, note=None
                )
            ),
        )
        self.assertEqual(
            0,
            aho.cmd_agent_checkpoint(
                argparse.Namespace(
                    action="append",
                    session="t1",
                    goal=None,
                    label="guardian",
                    harness_cmd="python ufc_harness/run_harness.py guardian",
                    rc=1,
                    note="fail",
                )
            ),
        )
        sp = Path(self._td.name) / "agent_session_t1.json"
        doc = json.loads(sp.read_text(encoding="utf-8"))
        self.assertEqual(doc["goal"], "g")
        self.assertEqual(len(doc["steps"]), 1)
        self.assertEqual(doc["steps"][0]["exit_code"], 1)

    def test_trace_log(self) -> None:
        import argparse

        ns = argparse.Namespace(
            action="log",
            kind="closure",
            cmd="closure",
            rc=0,
            ms=100,
            session="t1",
            note=None,
            lines=20,
        )
        self.assertEqual(0, aho.cmd_agent_trace(ns))
        tpath = Path(self._td.name) / "agent_harness_trace.jsonl"
        line = tpath.read_text(encoding="utf-8").strip()
        rec = json.loads(line)
        self.assertEqual(rec["kind"], "closure")
        self.assertEqual(rec["exit_code"], 0)

    def test_slow_loop_writes(self) -> None:
        import argparse

        ns = argparse.Namespace(from_report=None)
        rc = aho.cmd_agent_slow_loop(ns)
        self.assertEqual(rc, 0)
        outs = list(Path(self._td.name).glob("agent_slow_loop_*.md"))
        self.assertEqual(len(outs), 1)
        self.assertIn("慢思考", outs[0].read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
