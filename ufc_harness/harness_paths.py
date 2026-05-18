"""
UFC Harness 路径与配置（与仓库位置绑定，不依赖本机绝对路径）。

`ufc_harness` 目录须位于 `UFC/ufc_harness/`。
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

# 与 PLAN/README.md §2 现行结构一致（目录名在仓库根下由 paths.plan_relative_to_ufc 指向，默认 design_plan/；不含已废弃的 00_导航与元信息、07_理论参考）
_DEFAULT_REQUIRED_PLAN_DIRS: List[str] = [
    "01_架构总纲与设计哲学",
    "02_域级建模与实施清单",
    "03_技术规范与标准",
    "04_实施路线与任务规划",
    "05_技术标准与参考",
    "06_实施指南",
    "99_归档库",
]


def harness_root() -> Path:
    """`UFC/ufc_harness` 根目录。"""
    return Path(__file__).resolve().parent


def ufc_root() -> Path:
    """`UFC` 仓库根（`ufc_harness` 的父目录）。"""
    return harness_root().parent


def default_plan_dir() -> Path:
    """
    Harness `doc-structure` / `plan-checks` 默认 `--plan` 根目录。

    解析顺序（显式、可覆盖）：
    1. 环境变量 `UFC_DEFAULT_PLAN`（绝对路径或相对 **当前进程 cwd** 的路径）；
    2. `harness_config.json` → `paths.plan_relative_to_ufc`（相对 UFC 仓库根）；
    3. 回退 `"design_plan"`（避免与 `plan/` 在大小写不敏感 FS 上冲突）。
    """
    env = os.environ.get("UFC_DEFAULT_PLAN")
    if env:
        p = Path(env).expanduser()
        if not p.is_absolute():
            p = Path.cwd() / p
        return p.resolve()
    cfg = load_harness_config()
    paths = cfg.get("paths") or {}
    rel = paths.get("plan_relative_to_ufc") or "design_plan"
    return (ufc_root() / str(rel).replace("\\", "/").strip("/")).resolve()


def ufc_core_dir() -> Path:
    return ufc_root() / "ufc_core"


def default_build_dir() -> Path:
    return ufc_root() / "build"


def config_path() -> Path:
    return harness_root() / "config" / "harness_config.json"


def load_harness_config() -> Dict[str, Any]:
    """读取 harness_config.json；文件缺失时返回内置默认。"""
    p = config_path()
    if not p.is_file():
        return {
            "version": "fallback",
            "doc_structure": {"required_dirs": list(_DEFAULT_REQUIRED_PLAN_DIRS)},
            "thresholds": {"max_root_files": 25, "max_files_per_dir": 50},
        }
    with p.open(encoding="utf-8") as f:
        return json.load(f)


def plan_required_dirs(cfg: Optional[Dict[str, Any]] = None) -> List[str]:
    cfg = cfg or load_harness_config()
    ds = cfg.get("doc_structure") or {}
    dirs = ds.get("required_dirs")
    if isinstance(dirs, list) and dirs:
        return [str(x) for x in dirs]
    return list(_DEFAULT_REQUIRED_PLAN_DIRS)


def plan_thresholds(cfg: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    cfg = cfg or load_harness_config()
    th = cfg.get("thresholds") or {}
    return {
        "max_root_files": int(th.get("max_root_files", 25)),
        "max_files_per_dir": int(th.get("max_files_per_dir", 50)),
    }
