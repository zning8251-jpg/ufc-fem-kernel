#!/usr/bin/env python3
"""Tests for agent_task_ops (stdlib only)."""

from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path

HARNESS_ROOT = Path(__file__).resolve().parent.parent
if str(HARNESS_ROOT) not in sys.path:
    sys.path.insert(0, str(HARNESS_ROOT))

import agent_task_ops as ato  # noqa: E402


class TestAgentTaskOps(unittest.TestCase):
    def setUp(self) -> None:
        self._td = tempfile.TemporaryDirectory()
        self.addCleanup(self._td.cleanup)
        os.environ["UFC_PLAN_ROOT"] = self._td.name

    def tearDown(self) -> None:
        os.environ.pop("UFC_PLAN_ROOT", None)

    def test_init_status_validate(self) -> None:
        import argparse

        ns = argparse.Namespace(
            task_action="init",
            session="my-task",
            goal="test goal",
            force=False,
            strict=True,
        )
        self.assertEqual(0, ato.cmd_agent_task(ns))
        p = Path(self._td.name) / "tasks" / "my-task" / "TASK_RUN.md"
        self.assertTrue(p.is_file())
        self.assertIn("test goal", p.read_text(encoding="utf-8"))

        self.assertEqual(0, ato.cmd_agent_task(argparse.Namespace(task_action="status", session="my-task")))
        self.assertEqual(
            0,
            ato.cmd_agent_task(argparse.Namespace(task_action="validate", session="my-task", strict=True)),
        )

    def test_init_refuse_without_force(self) -> None:
        import argparse

        ns = argparse.Namespace(task_action="init", session="x", goal="g", force=False, strict=False)
        self.assertEqual(0, ato.cmd_agent_task(ns))
        self.assertEqual(1, ato.cmd_agent_task(ns))

    def test_list_empty(self) -> None:
        import argparse

        self.assertEqual(0, ato.cmd_agent_task(argparse.Namespace(task_action="list")))


if __name__ == "__main__":
    unittest.main()
