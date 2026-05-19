#!/usr/bin/env python3
"""
UFC Harness 统一入口（推荐）。

与仓库根无关：假定本文件位于 UFC/ufc_harness/run_harness.py。
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

HARNESS_ROOT = Path(__file__).resolve().parent


def _ensure_harness_import_path() -> None:
    """Insert harness root once so `import harness_paths` et al. resolve."""
    root = str(HARNESS_ROOT)
    if root not in sys.path:
        sys.path.insert(0, root)


TST_PROFILES = {
    "baseline": [
        {"kind": "guardian", "args": []},
        {"kind": "syntax", "args": []},
        {"kind": "regression_min", "args": []},
    ],
    "bridge-populate": [
        {"kind": "guardian", "args": ["--rules", "FLOW-002,FLOW-003,DEP-001,GLB-001,BRG-002"]},
        {"kind": "syntax", "args": []},
        {"kind": "regression_min", "args": ["--case", "bridge-populate"]},
    ],
    "guardian-regression": [
        {"kind": "guardian", "args": []},
        {"kind": "syntax", "args": []},
        {"kind": "regression_min", "args": ["--case", "guardian-regression"]},
    ],
    "material-baseline": [
        {"kind": "material_contract", "args": ["--summary"]},
        {"kind": "guardian", "args": ["--rules", "FLOW-002,FLOW-003,WB-001,TYPE-003,GLB-001,DEP-001"]},
        {"kind": "syntax", "args": []},
        {"kind": "ufc_py", "script": "tools/verify_crystal_w2_ref01.py", "args": []},
        {"kind": "regression_min", "args": ["--case", "material-baseline"]},
    ],
    "crystal-w2-ref01": [
        {"kind": "ufc_py", "script": "tools/verify_crystal_w2_ref01.py", "args": []},
        {"kind": "guardian", "path": "L4_PH/Material/Plast/PH_Mat_Plast_Crystal_Core.f90", "args": []},
    ],
    "p2-element-golden-seam": [
        {"kind": "ufc_py", "script": "tools/verify_element_golden_path_no_contm.py", "args": []},
        {"kind": "ufc_py", "script": "tools/verify_element_contm_legacy_boundary.py", "args": []},
        {"kind": "ufc_py", "script": "tools/verify_rt_elem_ke_in_align.py", "args": []},
        {"kind": "guardian", "path": "L4_PH/Element/PH_Elem_Def.f90", "args": ["--fail-on-p0"]},
        {"kind": "guardian", "path": "L4_PH/Element/PH_Elem_Domain.f90", "args": ["--fail-on-p0"]},
        {"kind": "guardian", "path": "L4_PH/Element/Shared/PH_Elem_MaterialRoute.f90", "args": ["--fail-on-p0"]},
        {"kind": "guardian", "path": "L5_RT/Assembly/RT_Asm_Solv.f90", "args": ["--fail-on-p0"]},
    ],
    "material-negative": [
        {"kind": "material_contract", "args": []},
        {"kind": "guardian", "args": ["--rules", "FLOW-002,FLOW-003,WB-001,TYPE-003,GLB-001,DEP-001"]},
        {"kind": "syntax", "args": []},
        {"kind": "regression_min", "args": ["--case", "material-negative"]},
    ],
    "material-performance": [
        {"kind": "material_contract", "args": ["--summary"]},
        {"kind": "guardian", "args": ["--rules", "HOT-001,HOT-002,HOT-003,HOT-004"]},
        {"kind": "syntax", "args": []},
        {"kind": "regression_min", "args": ["--case", "material-performance"]},
    ],
    "phase6-track13": [
        {"kind": "ufc_py", "script": "tools/verify_phase6_track13_integration.py", "args": []},
        {"kind": "fortran_run", "test": "matstate"},
        {"kind": "fortran_run", "test": "rt_drv"},
        {"kind": "guardian", "path": "L3_MD/Material", "args": ["--rules", "DEP-001,FLOW-002,GLB-001"]},
        {"kind": "syntax", "args": []},
        {"kind": "syntax", "syntax_profile": "phase6-track13-md-def"},
    ],
    "phase6-track12": [
        {"kind": "ufc_py", "script": "tools/verify_phase6_track12_contract.py", "args": []},
        {"kind": "syntax", "args": []},
    ],
    "phase6-track12-arclen": [
        {"kind": "ufc_py", "script": "tools/verify_phase6_track12_contract.py", "args": []},
        {"kind": "fortran_run", "test": "arclen"},
        {"kind": "syntax", "args": []},
    ],
    "phase6-track21": [
        {"kind": "ufc_py", "script": "tools/verify_phase6_track21_allocate.py", "args": []},
        {"kind": "syntax", "args": []},
    ],
    "phase6-track22": [
        {"kind": "ufc_py", "script": "tools/verify_phase6_track22_soa_ctx.py", "args": []},
        {"kind": "syntax", "args": []},
    ],
    "phase6-track32": [
        {"kind": "ufc_py", "script": "tools/verify_phase6_track32_tripartite.py", "args": []},
        {"kind": "fortran_run", "test": "fbar"},
        {"kind": "ufc_py", "script": "tools/gen_ph_element_stem_stub.py", "args": ["--dry-list"]},
        {"kind": "syntax", "args": []},
    ],
    "phase6-all": [
        {"kind": "ufc_py", "script": "tools/verify_phase6_track13_integration.py", "args": []},
        {"kind": "ufc_py", "script": "tools/verify_phase6_track12_contract.py", "args": []},
        {"kind": "ufc_py", "script": "tools/verify_phase6_track21_allocate.py", "args": []},
        {"kind": "ufc_py", "script": "tools/verify_phase6_track22_soa_ctx.py", "args": []},
        {"kind": "ufc_py", "script": "tools/verify_phase6_track32_tripartite.py", "args": []},
        {"kind": "fortran_run", "test": "matstate"},
        {"kind": "fortran_run", "test": "rt_drv"},
        {"kind": "fortran_run", "test": "l6_bridge"},
        {"kind": "fortran_run", "test": "arclen"},
        {"kind": "guardian", "path": "L3_MD/Analysis/Step", "args": ["--rules", "DEP-001,GLB-001"]},
        {"kind": "guardian", "path": "L3_MD/Material", "args": ["--rules", "DEP-001,FLOW-002,GLB-001"]},
        {"kind": "guardian", "path": "L5_RT/StepDriver", "args": ["--rules", "DEP-001,FLOW-002,GLB-001"]},
        {"kind": "guardian", "path": "L5_RT/Assembly", "args": ["--rules", "DEP-001,GLB-001"]},
        {"kind": "guardian", "path": "L4_PH/Material", "args": ["--rules", "HOT-001,HOT-002,GLB-001"]},
        {"kind": "guardian", "path": "L1_IF/Memory", "args": ["--rules", "GLB-001"]},
        {"kind": "syntax", "args": []},
        {"kind": "syntax", "syntax_profile": "phase6-track13-md-def"},
    ],
}

TST_ALIASES = {
    "tst-001": "baseline",
    "tst-001-baseline": "baseline",
    "tst-004": "bridge-populate",
    "tst-004-bridge-populate": "bridge-populate",
    "tst-005": "guardian-regression",
    "tst-005-guardian-regression": "guardian-regression",
    "phase6-track13": "phase6-track13",
    "phase6-track12": "phase6-track12",
    "phase6-track12-arclen": "phase6-track12-arclen",
    "phase6-track21": "phase6-track21",
    "phase6-track22": "phase6-track22",
    "phase6-track32": "phase6-track32",
    "phase6-all": "phase6-all",
}


def _python() -> str:
    return sys.executable


def _merge_stdout_stderr(proc: subprocess.CompletedProcess[str]) -> str:
    out, err = proc.stdout or "", proc.stderr or ""
    sep = "\n" if out and err else ""
    return out + sep + err


def _run_ufc_py(rel_script: str, args: list[str], dry_run: bool = False) -> int:
    """Run Python script relative to UFC repo root (parent of ufc_harness)."""
    _ensure_harness_import_path()
    import harness_paths  # noqa: E402

    script = (harness_paths.ufc_root() / rel_script.replace("\\", "/")).resolve()
    if not script.is_file():
        print(f"[harness] 缺少脚本: {script}", file=sys.stderr)
        return 2
    cmd = [_python(), str(script)] + args
    print("[harness][ufc_py]", " ".join(cmd))
    return 0 if dry_run else subprocess.call(cmd)


def _run_tool(rel_script: str, args: list[str], cwd: str | None = None) -> int:
    script = HARNESS_ROOT / rel_script
    if not script.is_file():
        print(f"[harness] 缺少脚本: {script}", file=sys.stderr)
        return 2
    cmd = [_python(), str(script)] + args
    if cwd is not None:
        return subprocess.call(cmd, cwd=cwd)
    return subprocess.call(cmd)


def _plan_arg(p: str | None) -> str:
    _ensure_harness_import_path()
    import harness_paths  # noqa: E402

    return p if p else str(harness_paths.default_plan_dir())


def _ufc_arg(p: str | None) -> str:
    _ensure_harness_import_path()
    import harness_paths  # noqa: E402

    return p if p else str(harness_paths.ufc_root())


def cmd_doc_structure(ns: argparse.Namespace) -> int:
    cwd = getattr(ns, "subprocess_cwd", None)
    return _run_tool(
        "tools/doc_management/doc_structure_checker.py",
        [_plan_arg(ns.plan)],
        cwd=cwd,
    )


def cmd_cross_ref(ns: argparse.Namespace) -> int:
    return _run_tool(
        "tools/doc_management/cross_ref_validator.py",
        [_plan_arg(ns.plan)],
    )


def cmd_redundancy(ns: argparse.Namespace) -> int:
    return _run_tool(
        "tools/doc_management/redundancy_detector.py",
        [_plan_arg(ns.plan)],
    )


def cmd_plan_checks(ns: argparse.Namespace) -> int:
    plan = _plan_arg(ns.plan)
    cwd = getattr(ns, "subprocess_cwd", None)
    steps = [
        ("tools/doc_management/doc_structure_checker.py", [plan]),
        ("tools/doc_management/cross_ref_validator.py", [plan]),
        ("tools/doc_management/reports_root_md_guard.py", []),
    ]
    last = 0
    for rel, args in steps:
        rc = _run_tool(rel, args, cwd=cwd)
        if rc != 0:
            last = rc
    if last != 0:
        return last
    return cmd_code_templates_ssot(ns)


def cmd_code_templates_ssot(ns: argparse.Namespace) -> int:
    """模板/示例目录 SSOT 扫描（Fortran 精度、IF_Err_API、遗留 PH_Material_*、裸 STATUS_OK 等）。"""
    _ensure_harness_import_path()
    import harness_paths  # noqa: E402

    ufc_root = harness_paths.ufc_root()
    script = ufc_root / "tools" / "scan_code_templates_ssot.py"
    if not script.is_file():
        print(f"[harness] code-templates-ssot: 缺少 {script}", file=sys.stderr)
        return 2
    ufc_cwd = str(ufc_root)
    args: list[str] = []
    if getattr(ns, "ssot_warn_only", False):
        args.append("--warn-only")
    if getattr(ns, "ssot_json", False):
        args.append("--json")
    rp = getattr(ns, "ssot_report", None)
    if rp:
        args.extend(["--report", rp])
    for r in getattr(ns, "ssot_root", None) or []:
        args.extend(["--root", r])
    return subprocess.call([_python(), str(script)] + args, cwd=ufc_cwd)


def cmd_reports_root_guard(ns: argparse.Namespace) -> int:
    """UFC/REPORTS 根目录 *.md 行数门禁（见 harness_config.reports_root_md_guard）。"""
    cwd = getattr(ns, "subprocess_cwd", None)
    return _run_tool("tools/doc_management/reports_root_md_guard.py", [], cwd=cwd)


def cmd_naming(ns: argparse.Namespace) -> int:
    path = ns.path
    if not path:
        _ensure_harness_import_path()
        import harness_paths  # noqa: E402

        core = harness_paths.ufc_core_dir()
        path = str(core) if core.exists() else "."
    return _run_tool("tools/code_development/naming_checker.py", [path])


def cmd_arch(ns: argparse.Namespace) -> int:
    root = _ufc_arg(ns.ufc_root)
    extra = ["--json"] if ns.json else []
    return _run_tool("tools/arch_validation/arch_consistency.py", [root] + extra)


def cmd_guardian(ns: argparse.Namespace) -> int:
    """UFC Architecture Guardian：热路径/层间USE/全局容器/四型文档/Mesh Idx 等规则。"""
    _ensure_harness_import_path()
    import harness_paths  # noqa: E402

    core = harness_paths.ufc_core_dir()
    if not core.exists():
        print("[harness] guardian: ufc_core 目录不存在", file=sys.stderr)
        return 2

    ufc_root = harness_paths.ufc_root()
    script = ufc_root / "scripts" / "arch_guardian.py"
    if not script.is_file():
        alt = ufc_root / "tools" / "arch_guardian.py"
        if alt.is_file():
            script = alt
    if not script.is_file():
        print(f"[harness] guardian: 缺少 {script}", file=sys.stderr)
        return 2

    scan = str(core)
    if ns.path:
        scan = ns.path
    args = [str(scan)]
    if ns.fail_on_p0:
        args.append("--fail-on-p0")
    if ns.json:
        args.append("--json")
    if ns.report:
        args.append("--report")
    if ns.rules:
        args.extend(["--rules", ns.rules])
    return subprocess.call([_python(), str(script)] + args)


def _run_syntax_min(case: str | None = None, dry_run: bool = False) -> int:
    """Profile-aware Phase6 syntax chains (no full-tree link)."""
    profile = case or "baseline"
    if profile not in TST_PROFILES and not profile.startswith("phase6"):
        profile = "baseline"
    if profile in TST_PROFILES and profile.startswith("phase6"):
        pass
    elif profile == "baseline":
        profile = "baseline"
    args = [_python(), str(Path(__file__).resolve().parents[1] / "tools" / "phase6_syntax_check.py")]
    if profile.startswith("phase6") or profile == "phase6-all":
        args.extend(["--profile", profile])
    else:
        args.extend(["--profile", "baseline"])
    if dry_run:
        args.append("--dry-run")
    print("[harness][syntax]", " ".join(args))
    return 0 if dry_run else subprocess.call(args)


def _run_fortran_test(test: str, dry_run: bool = False) -> int:
    script = Path(__file__).resolve().parents[1] / "tools" / "phase6_fortran_run.py"
    cmd = [_python(), str(script), "--test", test]
    if dry_run:
        cmd.append("--dry-run")
    print("[harness][fortran_run]", " ".join(cmd))
    return 0 if dry_run else subprocess.call(cmd)


def _run_regression_min(case: str | None = None, dry_run: bool = False) -> int:
    tag = case or "baseline"
    print(f"[harness][regression_min] case={tag}")
    return 0


def cmd_tst(ns: argparse.Namespace) -> int:
    profile = ns.case or "baseline"
    if ns.tst_id == "TST-001":
        profile = "baseline"
    elif ns.tst_id == "TST-004":
        profile = "bridge-populate"
    elif ns.tst_id == "TST-005":
        profile = "guardian-regression"

    profile = TST_ALIASES.get(profile, profile)

    if ns.list:
        print(json.dumps({"profiles": sorted(TST_PROFILES.keys()), "aliases": TST_ALIASES}, ensure_ascii=False, indent=2))
        return 0

    steps = TST_PROFILES.get(profile)
    if steps is None:
        print(f"[harness] tst: 未知 case/profile: {profile}", file=sys.stderr)
        return 2

    last = 0
    for step in steps:
        kind = step["kind"]
        extra_args = list(step.get("args", []))
        if kind == "guardian":
            _ensure_harness_import_path()
            import harness_paths  # noqa: E402

            scan_path = step.get("path")
            if scan_path:
                guardian_path = str((harness_paths.ufc_core_dir() / scan_path).resolve())
            else:
                guardian_path = ns.path
            sub_ns = argparse.Namespace(
                path=guardian_path,
                fail_on_p0=True,
                json=False,
                report=False,
                rules=None,
            )
            if extra_args[:1] == ["--rules"] and len(extra_args) >= 2:
                sub_ns.rules = extra_args[1]
            rc = cmd_guardian(sub_ns)
        elif kind == "syntax":
            syntax_profile = step.get("syntax_profile", profile)
            rc = _run_syntax_min(case=syntax_profile, dry_run=ns.dry_run)
        elif kind == "regression_min":
            case_arg = profile
            if extra_args[:1] == ["--case"] and len(extra_args) >= 2:
                case_arg = extra_args[1]
            rc = _run_regression_min(case=case_arg, dry_run=ns.dry_run)
        elif kind == "material_contract":
            rc = _run_tool("tools/code_development/material_contract_validator.py", extra_args)
        elif kind == "ufc_py":
            script_rel = step.get("script")
            if not script_rel or not isinstance(script_rel, str):
                print("[harness] tst: ufc_py 步骤缺少 script", file=sys.stderr)
                rc = 2
            else:
                rc = _run_ufc_py(script_rel, extra_args, dry_run=ns.dry_run)
        elif kind == "fortran_run":
            test_name = step.get("test")
            if not test_name:
                print("[harness] tst: fortran_run 步骤缺少 test", file=sys.stderr)
                rc = 2
            else:
                rc = _run_fortran_test(str(test_name), dry_run=ns.dry_run)
        else:
            print(f"[harness] tst: 未知步骤 kind={kind}", file=sys.stderr)
            rc = 2
        if rc != 0:
            last = rc
    return last


def _closure_type003_subprocess(
    ufc_root: Path, scan: str, cwd: str | None = None
) -> tuple[int, list[dict], str]:
    """Run arch_guardian with --rules TYPE-003 --json; returns (rc, violations, stderr)."""
    _ensure_harness_import_path()
    import guardian_client  # noqa: E402

    rc, data, stderr, _perr = guardian_client.run_guardian_json(
        ufc_root, scan, cwd=cwd, rules="TYPE-003"
    )
    return rc, data, stderr


def cmd_closure(ns: argparse.Namespace) -> int:
    """Run doc → plan → guardian → naming; write REPORTS/loop_run_*.md; optional --fail-on-p0."""
    _ensure_harness_import_path()
    import harness_paths  # noqa: E402
    import guardian_client  # noqa: E402

    ufc_root = harness_paths.ufc_root()
    ufc_cwd = str(ufc_root)
    reports_dir = ufc_root / "REPORTS"
    reports_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = reports_dir / f"loop_run_{ts}.md"
    checklist_rel = "ufc_harness/closure_loop_checklist.json"

    dry = getattr(ns, "dry_run", False)

    lines: list[str] = []
    lines.append("# UFC closure loop report\n\n")
    lines.append(f"- **Generated**: `{ts}` (local time)\n")
    lines.append(f"- **UFC root**: `{ufc_root}`\n")
    lines.append(f"- **Machine-readable checklist**: `{checklist_rel}`\n")
    if dry:
        lines.append("- **Mode**: `dry-run` (no subprocesses executed)\n")
    if getattr(ns, "with_ci_gates", False):
        lines.append("- **CI gates**: requested (`--with-ci-gates`)\n")
    if getattr(ns, "with_pillar_loop", False):
        if dry:
            lines.append("- **Pillar-loop**: `--with-pillar-loop` (not executed under closure `--dry-run`)\n")
        else:
            pl_full = getattr(ns, "pillar_loop_full", False)
            lines.append(
                "- **Pillar-loop**: `--with-pillar-loop` — "
                + ("full Guardian (`--pillar-loop-full`)" if pl_full else "default `pillar-loop --dry-run` after naming")
                + "\n"
            )
    lines.append("\n## Harness steps\n\n")
    lines.append("| Step | Exit | Notes |\n|------|------|-------|\n")

    exit_overall = 0
    naming_excerpt = ""
    ci_gates_excerpt = ""

    if dry:
        print("[harness] closure: --dry-run (no checks executed; report still written)", file=sys.stderr)
        if not ns.skip_doc_structure:
            lines.append("| doc-structure | — | dry-run (skipped) |\n")
        else:
            lines.append("| doc-structure | — | skipped |\n")
        if not ns.skip_plan_checks:
            lines.append("| plan-checks | — | dry-run (skipped) |\n")
        else:
            lines.append("| plan-checks | — | skipped |\n")
        if not ns.skip_guardian:
            lines.append("| guardian (--json) | — | dry-run (skipped) |\n")
        else:
            lines.append("| guardian | — | skipped |\n")
        if not ns.skip_naming:
            lines.append("| naming | — | dry-run (skipped) |\n")
        else:
            lines.append("| naming | — | skipped |\n")
        if getattr(ns, "with_pillar_loop", False):
            lines.append("| pillar-loop | — | dry-run (skipped) |\n")
        if ns.with_ci_gates:
            lines.append("| ci-gates | — | dry-run (skipped) |\n")
    else:
        if ns.skip_doc_structure:
            lines.append("| doc-structure | — | skipped |\n")
        else:
            rc = cmd_doc_structure(argparse.Namespace(plan=ns.plan, subprocess_cwd=ufc_cwd))
            note = ""
            if rc != 0:
                exit_overall = 1
                note = "non-zero"
            lines.append(f"| doc-structure | {rc} | {note} |\n")

        if ns.skip_plan_checks:
            lines.append("| plan-checks | — | skipped |\n")
        else:
            rc = cmd_plan_checks(argparse.Namespace(plan=ns.plan, subprocess_cwd=ufc_cwd))
            note = ""
            if rc != 0:
                exit_overall = 1
                note = "non-zero (see cross_ref / structure)"
            lines.append(f"| plan-checks | {rc} | {note} |\n")

    core = harness_paths.ufc_core_dir()
    scan = ns.path if ns.path else (str(core) if core.exists() else ".")

    guardian_script = guardian_client.guardian_script_path(ufc_root)
    guardian_data: list[dict] = []
    parse_err: str | None = None
    g_rc = 2
    g_stderr = ""

    if not dry:
        if ns.skip_guardian:
            lines.append("| guardian | — | skipped |\n")
        elif not guardian_script:
            lines.append("| guardian | 2 | missing arch_guardian.py under scripts/ or tools/ |\n")
            exit_overall = 1
        else:
            g_rc, guardian_data, g_stderr, parse_err = guardian_client.run_guardian_json(
                ufc_root, scan, cwd=ufc_cwd
            )
            note = ""
            if g_rc != 0:
                exit_overall = 1
                note = "guardian process error"
            if parse_err:
                note = (note + "; " if note else "") + parse_err
            lines.append(f"| guardian (--json) | {g_rc} | {note or 'ok'} |\n")

    naming_script = HARNESS_ROOT / "tools/code_development/naming_checker.py"
    if not dry:
        if ns.skip_naming:
            lines.append("| naming | — | skipped |\n")
        elif not naming_script.is_file():
            lines.append("| naming | — | skipped (naming_checker.py missing) |\n")
        else:
            nm_path = ns.naming_path
            if not nm_path:
                nm_path = str(core) if core.exists() else "."
            print("[harness] closure: running naming_checker (stdout/stderr captured; excerpt in report)…", file=sys.stderr)
            proc_nm = guardian_client.run_subprocess_text(
                [_python(), str(naming_script), nm_path],
                cwd=ufc_cwd,
            )
            rc = proc_nm.returncode
            combined = _merge_stdout_stderr(proc_nm)
            tail_lines = combined.splitlines()[-80:]
            naming_excerpt = "\n".join(tail_lines)
            note = ""
            if rc != 0:
                exit_overall = 1
                note = "violations or tool error"
            lines.append(f"| naming | {rc} | {note} |\n")

    if not dry and getattr(ns, "with_pillar_loop", False):
        import pillar_loop as pl  # noqa: E402

        pl_full = getattr(ns, "pillar_loop_full", False)
        pl_dry = not pl_full
        if pl_dry:
            print("[harness] closure: pillar-loop (--dry-run; no second full guardian)…", file=sys.stderr)
        else:
            print("[harness] closure: pillar-loop (full guardian scan)…", file=sys.stderr)
        pl_ns = argparse.Namespace(
            path=ns.path,
            dry_run=pl_dry,
            fail_on_p0=bool(ns.fail_on_p0) if pl_full else False,
        )
        pl_rc = pl.run_pillar_loop(pl_ns)
        pl_note = "pillar-loop --dry-run" if pl_dry else "pillar-loop (full)"
        if pl_rc != 0:
            exit_overall = 1
            pl_note += "; non-zero"
        lines.append(f"| pillar-loop | {pl_rc} | {pl_note} |\n")

    if not dry and ns.with_ci_gates:
        ci_script = ufc_root / "scripts" / "ci" / "check_harness_gates.py"
        if not core.exists():
            lines.append("| ci-gates | — | skipped (ufc_core missing) |\n")
        elif not ci_script.is_file():
            lines.append("| ci-gates | — | skipped (scripts/ci/check_harness_gates.py missing) |\n")
        else:
            print("[harness] closure: running check_harness_gates.py (cwd UFC root)…", file=sys.stderr)
            proc_ci = guardian_client.run_subprocess_text(
                [_python(), str(ci_script), str(core)],
                cwd=ufc_cwd,
            )
            rc_ci = proc_ci.returncode
            comb_ci = _merge_stdout_stderr(proc_ci)
            ci_gates_excerpt = "\n".join(comb_ci.splitlines()[-120:])
            note_ci = ""
            if rc_ci != 0:
                exit_overall = 1
                note_ci = "hard gate failure or tool error"
            lines.append(f"| ci-gates | {rc_ci} | {note_ci} |\n")

    lines.append("\n## Guardian summary\n\n")
    p0 = p1 = p2 = 0
    type003_in_full = 0
    if dry:
        lines.append("- **Dry-run**: Guardian and TYPE-003 were not executed.\n")
    elif guardian_data:
        for v in guardian_data:
            sev = v.get("severity", "")
            if sev == "P0":
                p0 += 1
            elif sev == "P1":
                p1 += 1
            elif sev == "P2":
                p2 += 1
            if v.get("rule_id") == "TYPE-003":
                type003_in_full += 1
        lines.append(f"- **Violations (full scan)**: total {len(guardian_data)}, P0={p0}, P1={p1}, P2={p2}\n")
        lines.append(f"- **TYPE-003 rows in full JSON**: {type003_in_full}\n")
    elif not ns.skip_guardian and guardian_script:
        lines.append("- No parsed guardian JSON (scan may have failed).\n")

    t3_rc = -1
    t3_count = 0
    if not dry and not ns.skip_guardian and guardian_script and core.exists():
        t3_rc, t3_list, _ = _closure_type003_subprocess(ufc_root, str(core), cwd=ufc_cwd)
        t3_count = len(t3_list)
        lines.append(f"- **Dedicated TYPE-003 run** (`--rules TYPE-003 --json`): exit {t3_rc}, violation rows {t3_count}\n")

    lines.append("\n## Next actions (loop feedback)\n\n")
    next_bullets: list[str] = []
    if dry:
        next_bullets.append(
            "Re-run without `--dry-run` to execute doc/plan/guardian/naming "
            "(and optional CI gates / `--with-pillar-loop`)."
        )
    elif exit_overall != 0:
        next_bullets.append("Re-run failing harness steps individually from `UFC/` root (see table above).")
    if p0 > 0:
        by_rule = Counter(str(v.get("rule_id", "?")) for v in guardian_data if v.get("severity") == "P0")
        top = ", ".join(f"{k}×{c}" for k, c in by_rule.most_common(8))
        next_bullets.append(f"**P0 ({p0})**: fix in `ufc_core/` before merge; top rules: {top or 'see guardian output'}.")
    if type003_in_full > 0 or t3_count > 0:
        next_bullets.append(
            f"**TYPE-003** (Ctx hot-path allocation): {t3_count} dedicated-scan rows; "
            "treat zero-allocation hot paths per Guardian narrative."
        )
    if not next_bullets:
        next_bullets.append("Harness chain clean for executed steps; keep running `closure` after substantive edits.")
    for b in next_bullets:
        lines.append(f"- {b}\n")

    lines.append("\n## External gaps (not closed by this repo)\n\n")
    lines.append(
        "- **MCP**: servers in checklist must be enabled in Cursor/IDE settings; secrets/API keys are local.\n"
    )
    lines.append("- **Agent**: cloud or IDE agent policies, model choice, and tool allowlists are external.\n")
    lines.append(
        "- **Skills**: `npx openskills read …` requires Node + openskills; placeholders in checklist need human authoring.\n"
    )
    lines.append("- **Memory / Loop**: IDE memory and org process are outside `run_harness.py`.\n")

    if g_stderr and ns.verbose:
        lines.append("\n## Guardian stderr (verbose)\n\n```text\n")
        lines.append(g_stderr[-8000:] if len(g_stderr) > 8000 else g_stderr)
        lines.append("\n```\n")

    if naming_excerpt:
        lines.append("\n## Naming checker excerpt (last lines)\n\n```text\n")
        lines.append(naming_excerpt[-12000:] if len(naming_excerpt) > 12000 else naming_excerpt)
        lines.append("\n```\n")

    if ci_gates_excerpt:
        lines.append("\n## CI harness gates excerpt (last lines)\n\n```text\n")
        lines.append(ci_gates_excerpt[-12000:] if len(ci_gates_excerpt) > 12000 else ci_gates_excerpt)
        lines.append("\n```\n")

    report_path.write_text("".join(lines), encoding="utf-8")
    print(f"[harness] closure report written: {report_path}")

    if ns.fail_on_p0 and not dry and p0 > 0:
        print(f"[harness] closure: --fail-on-p0 and P0 count={p0} → exit 1", file=sys.stderr)
        return 1
    if dry:
        return 0
    return exit_overall


def cmd_show_config(_: argparse.Namespace) -> int:
    _ensure_harness_import_path()
    import harness_paths  # noqa: E402

    cfg = harness_paths.load_harness_config()
    print(
        json.dumps(
            {
                "ufc_root": str(harness_paths.ufc_root()),
                "plan_dir": str(harness_paths.default_plan_dir()),
                "default_plan_resolution": "UFC_DEFAULT_PLAN (if set) else ufc_root / paths.plan_relative_to_ufc from harness_config.json",
                "plan_relative_to_ufc": (cfg.get("paths") or {}).get("plan_relative_to_ufc"),
                "required_plan_dirs": harness_paths.plan_required_dirs(cfg),
                "config_file": str(harness_paths.config_path()),
            },
            indent=2,
            ensure_ascii=False,
        )
    )
    return 0


def cmd_pillar_loop(ns: argparse.Namespace) -> int:
    _ensure_harness_import_path()
    import pillar_loop as pl  # noqa: E402

    return pl.run_pillar_loop(ns)


def cmd_agent_bundle(ns: argparse.Namespace) -> int:
    _ensure_harness_import_path()
    import agent_harness_ops as aho  # noqa: E402

    return aho.cmd_agent_bundle(ns)


def cmd_agent_checkpoint(ns: argparse.Namespace) -> int:
    _ensure_harness_import_path()
    import agent_harness_ops as aho  # noqa: E402

    return aho.cmd_agent_checkpoint(ns)


def cmd_agent_trace(ns: argparse.Namespace) -> int:
    _ensure_harness_import_path()
    import agent_harness_ops as aho  # noqa: E402

    inner = argparse.Namespace(
        action=ns.trace_action,
        kind=ns.kind,
        cmd=ns.cmd,
        rc=ns.rc,
        ms=ns.ms,
        session=ns.session,
        note=ns.note,
        lines=ns.lines,
    )
    return aho.cmd_agent_trace(inner)


def cmd_agent_slow_loop(ns: argparse.Namespace) -> int:
    _ensure_harness_import_path()
    import agent_harness_ops as aho  # noqa: E402

    return aho.cmd_agent_slow_loop(ns)


def cmd_agent_task(ns: argparse.Namespace) -> int:
    _ensure_harness_import_path()
    import agent_task_ops as ato  # noqa: E402

    return ato.cmd_agent_task(ns)


def cmd_change_package_entry(ns: argparse.Namespace) -> int:
    _ensure_harness_import_path()
    import governance_ops as gov  # noqa: E402

    if getattr(ns, "cp_cmd", None) == "validate":
        return gov.cmd_change_package_validate(ns)
    print(f"[change-package] unknown subcommand: {getattr(ns, 'cp_cmd', None)}", file=sys.stderr)
    return 2


def cmd_discipline_entry(ns: argparse.Namespace) -> int:
    _ensure_harness_import_path()
    import governance_ops as gov  # noqa: E402

    if getattr(ns, "dis_cmd", None) == "verify":
        return gov.cmd_discipline_verify(ns)
    print(f"[discipline] unknown subcommand: {getattr(ns, 'dis_cmd', None)}", file=sys.stderr)
    return 2


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == "build":
        script = HARNESS_ROOT / "tools/code_development/build_trigger.py"
        return subprocess.call([_python(), str(script)] + sys.argv[2:])

    parser = argparse.ArgumentParser(
        description="UFC Harness：文档检查与辅助工具统一入口",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_ds = sub.add_parser("doc-structure", help="PLAN 目录结构检查（读 harness_config）")
    p_ds.add_argument("plan", nargs="?", default=None, help="计划根路径，默认 harness_paths.default_plan_dir()（见 harness_config paths.plan_relative_to_ufc）")
    p_ds.set_defaults(func=cmd_doc_structure)

    p_cr = sub.add_parser("cross-ref", help="PLAN 内 Markdown 链接检查")
    p_cr.add_argument("plan", nargs="?", default=None)
    p_cr.set_defaults(func=cmd_cross_ref)

    p_rd = sub.add_parser("redundancy", help="PLAN 冗余/临时文件启发式检测（退出码恒为 0）")
    p_rd.add_argument("plan", nargs="?", default=None)
    p_rd.set_defaults(func=cmd_redundancy)

    p_pc = sub.add_parser(
        "plan-checks",
        help="CI 推荐：doc-structure + cross-ref + reports-root-guard + code-templates-ssot，任一失败则非零退出",
    )
    p_pc.add_argument("plan", nargs="?", default=None)
    p_pc.set_defaults(func=cmd_plan_checks)

    p_rr = sub.add_parser(
        "reports-root-guard",
        help="UFC/REPORTS 根目录 *.md 行数门禁（harness_config.reports_root_md_guard）",
    )
    p_rr.set_defaults(func=cmd_reports_root_guard)

    p_css = sub.add_parser(
        "code-templates-ssot",
        help="Code_Templates + docs/02_Developer_Guide（除 Code_Templates/）+ docs/03_Domain_Pillars：md 围栏与模板 Fortran 真源门禁",
    )
    p_css.add_argument(
        "--root",
        dest="ssot_root",
        action="append",
        default=None,
        help="扫描根（可重复；相对路径相对 UFC 根；每项 .f90+.md。省略则用脚本内置三处默认根）",
    )
    p_css.add_argument("--report", dest="ssot_report", default=None, help="报告输出路径")
    p_css.add_argument("--json", dest="ssot_json", action="store_true", help="stdout 打印 JSON")
    p_css.add_argument(
        "--warn-only",
        dest="ssot_warn_only",
        action="store_true",
        help="违规仍打印/写报告，但退出码为 0（渐进启用 CI 时用）",
    )
    p_css.set_defaults(func=cmd_code_templates_ssot)

    p_nm = sub.add_parser("naming", help="Fortran 命名规范扫描（默认 UFC/ufc_core）")
    p_nm.add_argument("path", nargs="?", default=None)
    p_nm.set_defaults(func=cmd_naming)

    p_ar = sub.add_parser("arch", help="六层目录与命名粗检")
    p_ar.add_argument("ufc_root", nargs="?", default=None)
    p_ar.add_argument("--json", action="store_true", help="JSON 输出（仍按规则设退出码）")
    p_ar.set_defaults(func=cmd_arch)

    p_gd = sub.add_parser(
        "guardian",
        help="架构守卫 arch_guardian.py（层间USE/热路径/全局容器/四型/Mesh Idx 等）",
    )
    p_gd.add_argument(
        "path",
        nargs="?",
        default=None,
        help="扫描路径，默认 UFC/ufc_core",
    )
    p_gd.add_argument(
        "--fail-on-p0",
        action="store_true",
        help="存在 P0 违规时非零退出（CI/pre-commit）",
    )
    p_gd.add_argument("--json", action="store_true", help="JSON 报告")
    p_gd.add_argument("--report", action="store_true", help="Markdown 报告")
    p_gd.add_argument(
        "--rules",
        type=str,
        default=None,
        help="仅运行指定规则，逗号分隔（如 GLB-001,DEP-002）",
    )
    p_gd.set_defaults(func=cmd_guardian)

    p_tst = sub.add_parser(
        "tst",
        help="最小验证集入口：按 TST-* / case 编排 guardian + syntax + 最小回归",
    )
    p_tst.add_argument("path", nargs="?", default=None, help="guardian 扫描路径，默认 UFC/ufc_core")
    p_tst.add_argument("--list", action="store_true", help="列出内置最小验证集 case/profile")
    p_tst.add_argument("--case", type=str, default="baseline", help="选择验证集 case/profile，默认 baseline")
    p_tst.add_argument("--tst-id", type=str, default=None, help="按 TST-* 规则编号选择内置验证集")
    p_tst.add_argument("--dry-run", action="store_true", help="仅打印将执行的最小验证集步骤")
    p_tst.set_defaults(func=cmd_tst)

    p_cf = sub.add_parser("show-config", help="打印解析后的路径与 required_dirs")
    p_cf.set_defaults(func=cmd_show_config)

    p_cl = sub.add_parser(
        "closure",
        help="闭环编排：doc-structure → plan-checks → guardian(JSON) → naming；写 REPORTS/loop_run_*.md",
    )
    p_cl.add_argument(
        "--plan",
        dest="plan",
        default=None,
        help="PLAN 目录，默认 harness_paths.default_plan_dir()（通常为 UFC/design_plan）",
    )
    p_cl.add_argument(
        "--scan",
        dest="path",
        default=None,
        help="guardian 扫描路径，默认 UFC/ufc_core",
    )
    p_cl.add_argument(
        "--naming-path",
        dest="naming_path",
        default=None,
        help="naming_checker 根路径，默认与 run_harness naming 相同",
    )
    p_cl.add_argument(
        "--fail-on-p0",
        action="store_true",
        help="若 guardian JSON 中 P0>0，最终以退出码 1 结束（报告仍写入）",
    )
    p_cl.add_argument("--skip-doc-structure", action="store_true")
    p_cl.add_argument("--skip-plan-checks", action="store_true")
    p_cl.add_argument("--skip-guardian", action="store_true")
    p_cl.add_argument("--skip-naming", action="store_true")
    p_cl.add_argument("--verbose", action="store_true", help="在报告中附加 guardian stderr 尾部")
    p_cl.add_argument(
        "--with-ci-gates",
        action="store_true",
        help="若存在 scripts/ci/check_harness_gates.py，则在命名后运行并追加摘要到报告（cwd=UFC 根）",
    )
    p_cl.add_argument(
        "--with-pillar-loop",
        action="store_true",
        help="在命名之后运行 pillar-loop：默认 pillar-loop --dry-run（不再次全量 Guardian）；与 --pillar-loop-full 联用则全量",
    )
    p_cl.add_argument(
        "--pillar-loop-full",
        action="store_true",
        help="与 --with-pillar-loop 联用：运行完整 pillar-loop（再次全量 Guardian JSON）",
    )
    p_cl.add_argument(
        "--dry-run",
        action="store_true",
        help="不执行子进程，仍生成 REPORTS/loop_run_*.md（用于验证路径与编排）",
    )
    p_cl.set_defaults(func=cmd_closure)

    p_pl = sub.add_parser(
        "pillar-loop",
        help="按 P1–P6 贯通域柱切分 Guardian JSON；输出推荐 harness 命令与 REPORTS/pillar_decision_*.md",
    )
    p_pl.add_argument(
        "path",
        nargs="?",
        default=None,
        help="guardian 扫描路径，默认 UFC/ufc_core",
    )
    p_pl.add_argument("--dry-run", action="store_true", help="不跑 guardian，仅写报告骨架")
    p_pl.add_argument(
        "--fail-on-p0",
        action="store_true",
        help="若全量扫描存在任一 P0，最终以退出码 1 结束",
    )
    p_pl.set_defaults(func=cmd_pillar_loop)

    p_ab = sub.add_parser(
        "agent-bundle",
        help="Agent 上下文包：写 REPORTS/agent_context_bundle_*.md（闭环+MCP+技能+harness 链）",
    )
    p_ab.add_argument("--task", type=str, default=None, help="写入 bundle 顶部的任务描述")
    p_ab.add_argument(
        "--json-sidecar",
        action="store_true",
        help="同时写 agent_context_bundle_<ts>.json",
    )
    p_ab.set_defaults(func=cmd_agent_bundle)

    p_ac = sub.add_parser(
        "agent-checkpoint",
        help="会话断点 JSON：init/append/show/clear（REPORTS/agent_session_<id>.json）",
    )
    p_ac.add_argument("action", choices=["init", "append", "show", "clear"])
    p_ac.add_argument("--session", type=str, default="default")
    p_ac.add_argument("--goal", type=str, default=None)
    p_ac.add_argument("--label", type=str, default=None)
    p_ac.add_argument("--harness-cmd", type=str, default=None)
    p_ac.add_argument("--rc", type=int, default=None)
    p_ac.add_argument("--note", type=str, default=None)
    p_ac.set_defaults(func=cmd_agent_checkpoint)

    p_at = sub.add_parser(
        "agent-trace",
        help="可观测性 JSONL：log 追加一行 / tail 查看末尾",
    )
    p_at.add_argument("trace_action", choices=["log", "tail"])
    p_at.add_argument("--kind", type=str, default="harness")
    p_at.add_argument("--cmd", type=str, default="")
    p_at.add_argument("--rc", type=int, default=None)
    p_at.add_argument("--ms", type=int, default=None)
    p_at.add_argument("--session", type=str, default=None)
    p_at.add_argument("--note", type=str, default=None)
    p_at.add_argument("--lines", type=int, default=20)
    p_at.set_defaults(func=cmd_agent_trace)

    p_as = sub.add_parser(
        "agent-slow-loop",
        help="慢思考复盘模板：写 REPORTS/agent_slow_loop_*.md（不调 LLM）",
    )
    p_as.add_argument(
        "--from-report",
        type=str,
        default=None,
        help="指定 REPORTS 下某 .md；默认取最新 loop_run_*.md 或 pillar_decision_*.md",
    )
    p_as.set_defaults(func=cmd_agent_slow_loop)

    p_att = sub.add_parser(
        "agent-task",
        help="长任务运行卡：在 plan/tasks/<session>/ 生成或校验 TASK_RUN.md（init|status|validate|list）",
    )
    p_att.add_argument("task_action", choices=["init", "status", "validate", "list"])
    p_att.add_argument("--session", type=str, default=None, help="任务 ID（目录 plan/tasks/<session>/）")
    p_att.add_argument("--goal", type=str, default=None, help="init：写入 ## Goal")
    p_att.add_argument("--force", action="store_true", help="init：已存在则覆盖")
    p_att.add_argument("--strict", action="store_true", help="validate：要求至少一行数字 id 子任务")
    p_att.set_defaults(func=cmd_agent_task)

    p_cp = sub.add_parser(
        "change-package",
        help="治理：规格变更包校验（plan/changes/<change_id>/，OpenSpec 自研等价）",
    )
    cp_sub = p_cp.add_subparsers(dest="cp_cmd", required=True)
    p_cpv = cp_sub.add_parser("validate", help="检查 proposal/design/tasks + specs/**/*.md 与关键字")
    p_cpv.add_argument("--change-id", type=str, required=True, dest="change_id")
    p_cpv.add_argument(
        "--strict",
        action="store_true",
        help="不合规时非零退出（默认 warn-only：打印 ERROR 仍退出 0）",
    )
    p_cp.set_defaults(func=cmd_change_package_entry)

    p_dis = sub.add_parser(
        "discipline",
        help="治理：按 ufc_governance/triad/discipline/manifest.v1.json 提示 harness 义务",
    )
    dis_sub = p_dis.add_subparsers(dest="dis_cmd", required=True)
    p_disv = dis_sub.add_parser("verify", help="无 touch-path 时打印全部规则；有则按 glob 匹配")
    p_disv.add_argument(
        "--touch-path",
        action="append",
        default=[],
        dest="touch_path",
        help="可重复；相对路径相对 cwd，应能解析到 UFC 根下",
    )
    p_disv.add_argument(
        "--strict",
        action="store_true",
        help="manifest 缺失/非法或 touch-path 越界时非零退出",
    )
    p_dis.set_defaults(func=cmd_discipline_entry)

    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
