#!/usr/bin/env python3
"""
Material 执行闭环校验器
- 读取 material_contracts.json
- 校验标签与兼容矩阵
- 可用于 harness / CI / guardian 前置校验
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Set, Tuple

_HARNESS_ROOT = Path(__file__).resolve().parents[2]
if str(_HARNESS_ROOT) not in sys.path:
    sys.path.insert(0, str(_HARNESS_ROOT))

import harness_paths  # noqa: E402


def _contracts_path() -> Path:
    return harness_paths.harness_root() / "config" / "material_contracts.json"


def load_contracts() -> Dict[str, Any]:
    path = _contracts_path()
    if not path.is_file():
        raise FileNotFoundError(f"缺少配置文件: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def build_enum_set(cfg: Dict[str, Any]) -> Set[str]:
    enums: Set[str] = set()
    material_enum = cfg.get("material_enum", {})
    for values in material_enum.values():
        enums.update(values)
    aliases = cfg.get("aliases", {})
    for mapped in aliases.get("material_family", {}).values():
        enums.update(mapped)
    for tag in aliases.get("bridge_tags", []):
        enums.add(tag)
    return enums


def validate_contracts(cfg: Dict[str, Any]) -> List[str]:
    errors: List[str] = []
    enums = build_enum_set(cfg)
    compat = cfg.get("compatibility_matrix", [])

    if not enums:
        errors.append("material_enum 不能为空")

    for idx, item in enumerate(compat, start=1):
        req = item.get("required", [])
        if not isinstance(req, list) or not req:
            errors.append(f"compatibility_matrix[{idx}] required 不能为空")
            continue

        missing_alias = [tag for tag in req if tag not in enums and tag not in {"beam_like", "shell_layered"}]
        if missing_alias:
            errors.append(
                f"compatibility_matrix[{idx}] 含未定义标签: {', '.join(missing_alias)}"
            )

        policy = item.get("policy")
        if policy not in {"allow", "deny", "bridge-required", "needs-review"}:
            errors.append(f"compatibility_matrix[{idx}] policy 必须为 allow/deny/bridge-required/needs-review")

        for field in ("element_family", "section_family", "procedure_family"):
            if not item.get(field):
                errors.append(f"compatibility_matrix[{idx}] 缺少字段 {field}")

    return errors


def dump_summary(cfg: Dict[str, Any]) -> Dict[str, Any]:
    material_enum = cfg.get("material_enum", {})
    return {
        "enum_groups": {k: len(v) for k, v in material_enum.items()},
        "enum_total": len(build_enum_set(cfg)),
        "matrix_rows": len(cfg.get("compatibility_matrix", [])),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Material 执行闭环校验器")
    parser.add_argument("--json", action="store_true", help="JSON 输出")
    parser.add_argument("--summary", action="store_true", help="输出摘要")
    args = parser.parse_args()

    cfg = load_contracts()
    errors = validate_contracts(cfg)

    if args.json:
        print(json.dumps({"errors": errors, "summary": dump_summary(cfg)}, ensure_ascii=False, indent=2))
    elif args.summary:
        print(json.dumps(dump_summary(cfg), ensure_ascii=False, indent=2))
        if errors:
            print("\nErrors:")
            for err in errors:
                print(f"- {err}")
    else:
        if errors:
            for err in errors:
                print(f"[material-contract-validator] {err}", file=sys.stderr)
        else:
            print("[material-contract-validator] OK")

    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
