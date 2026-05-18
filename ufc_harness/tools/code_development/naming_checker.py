#!/usr/bin/env python3
"""
UFC 命名规范检查器
功能: 扫描 Fortran 过程/类型/模块后缀；与仓库约定对齐（层前缀大小写不敏感、*Def_* 绑定名、全小写私有过程）。
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

_UFC_HARNESS = Path(__file__).resolve().parents[2]
if str(_UFC_HARNESS) not in sys.path:
    sys.path.insert(0, str(_UFC_HARNESS))

import harness_paths  # noqa: E402
from typing import Dict, List, Optional, Tuple
from collections import defaultdict

# 统一 diff 中识别「新增」的 module 声明行（不要求行首 module，允许前导空白）
_GIT_DIFF_MODULE_LINE = re.compile(r"^\s*module\s+(\w+)\b", re.IGNORECASE)


def find_git_repo_root(start: Optional[Path] = None) -> Optional[Path]:
    """自 start 向上查找含 .git 的目录。"""
    cur = (start or Path.cwd()).resolve()
    for _ in range(40):
        if (cur / ".git").exists():
            return cur
        parent = cur.parent
        if parent == cur:
            return None
        cur = parent
    return None


def parse_git_diff_for_new_module_algo(diff_text: str) -> List[Dict[str, object]]:
    """
    扫描 unified diff：在「+」侧出现的 `MODULE …_Algo`（不区分大小写后缀 _algo）。
    仅用于检测变更中**新引入**的遗留形态；存量树扫描见文档 §3.2。
    """
    violations: List[Dict[str, object]] = []
    cur_file: Optional[str] = None
    new_line: Optional[int] = None

    for raw in diff_text.splitlines():
        if raw.startswith("diff --git "):
            cur_file = None
            new_line = None
            continue
        if raw.startswith("Binary files "):
            cur_file = None
            new_line = None
            continue
        if raw.startswith("+++ "):
            p = raw[4:].strip()
            if p == "/dev/null":
                cur_file = None
            else:
                cur_file = p[2:] if p.startswith("b/") else p
            new_line = None
            continue
        if raw.startswith("@@"):
            m = re.search(r"\+(\d+)(?:,(\d+))?\s+@@", raw)
            new_line = int(m.group(1)) if m else None
            continue
        if cur_file is None or new_line is None:
            continue
        if not raw:
            continue
        tag = raw[0]
        if tag == " ":
            new_line += 1
            continue
        if tag == "-":
            continue
        if tag == "+":
            body = raw[1:]
            inner_stripped = body.lstrip()
            if inner_stripped.startswith("!"):
                new_line += 1
                continue
            m = _GIT_DIFF_MODULE_LINE.match(inner_stripped)
            if m:
                mod = m.group(1)
                if mod.lower().endswith("_algo"):
                    violations.append(
                        {
                            "file": cur_file,
                            "line": new_line,
                            "module": mod,
                            "content": inner_stripped[:160],
                            "message": (
                                "禁止使用新的 MODULE …_Algo：与 TYPE 四型 _Algo 同形易混；"
                                "过程主体模块请改名为 …_Ops（见 UFC/docs/02_Developer_Guide/UFC_命名与数据结构规范.md §3.2）。"
                            ),
                        }
                    )
            new_line += 1
            continue
        if raw.startswith("\\"):
            continue

    return violations


def git_diff_new_module_algo_violations(
    repo_root: Path,
    rev_from: str,
    rev_to: str,
    pathspecs: List[str],
) -> Tuple[List[Dict[str, object]], str]:
    """
    执行 `git diff rev_from..rev_to -- pathspecs`，返回 (violations, stderr)。
    git 失败时 violations 为空，stderr 含错误信息。
    """
    if not pathspecs:
        pathspecs = ["UFC/ufc_core"]
    cmd = ["git", "-C", str(repo_root), "diff", f"{rev_from}..{rev_to}", "--", *pathspecs]
    proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        return [], (proc.stderr or proc.stdout or "git diff failed").strip()
    return parse_git_diff_for_new_module_algo(proc.stdout), ""


def resolve_ci_git_range(repo_root: Path) -> Tuple[str, str]:
    """
    从环境变量或回退逻辑得到 diff 两端 SHA。
    支持 NAMING_GIT_FROM / NAMING_GIT_TO（CI 注入）。
    """
    fr = (os.environ.get("NAMING_GIT_FROM") or "").strip()
    to = (os.environ.get("NAMING_GIT_TO") or "").strip()
    zero = "0" * 40
    if not fr or fr == zero:
        p = subprocess.run(
            ["git", "-C", str(repo_root), "rev-parse", "--verify", "HEAD~1"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        fr = p.stdout.strip() if p.returncode == 0 else ""
    if not to or to == zero:
        p = subprocess.run(
            ["git", "-C", str(repo_root), "rev-parse", "--verify", "HEAD"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        to = p.stdout.strip() if p.returncode == 0 else ""
    return fr, to


def run_git_policy_no_new_module_algo(
    repo_root: Path,
    rev_from: str,
    rev_to: str,
    pathspecs: List[str],
    github_actions: bool = False,
    *,
    print_ok: bool = True,
) -> int:
    """
    若有违规打印并返回 1，否则 0。git 不可用时打印 warning 并返回 0。
    print_ok=False 时成功路径不打印（供 CI 脚本自行写 JSON 报告）。
    """
    if not rev_from or not rev_to:
        print("::warning::无法解析 git 比较范围，跳过「禁止新 MODULE *_Algo」检查（请设置 NAMING_GIT_FROM/TO）")
        return 0
    viol, err = git_diff_new_module_algo_violations(repo_root, rev_from, rev_to, pathspecs)
    if err and not viol:
        print(f"::warning::git diff 失败，跳过 MODULE*_Algo 策略检查: {err[:500]}")
        return 0
    if not viol:
        if print_ok:
            print(f"OK: git {rev_from[:7]}..{rev_to[:7]} 未发现新增的 MODULE …_Algo")
        return 0
    print("命名策略违规：diff 中出现新的 MODULE …_Algo（应使用 …_Ops）:")
    gh = github_actions or (os.environ.get("GITHUB_ACTIONS") == "true")
    for v in viol:
        fp = str(v["file"]).replace("%", "%25")
        msg = str(v["message"]).replace("%", "%25").replace("\n", " ")
        if gh:
            print(f"::error file={fp},line={v['line']}::{msg} ({v['module']})")
        else:
            print(f"  {v['file']}:{v['line']}: {v['module']} — {msg}")
        print(f"    {v.get('content', '')}")
    return 1


def _layer_prefix_ok(name: str, prefixes: Tuple[str, ...]) -> bool:
    """Fortran 符号不区分大小写：接受 MD_/md_、PH_/ph_ 等与仓库一致的层前缀。"""
    if not name:
        return False
    low = name.lower()
    return any(low.startswith(p.lower()) for p in prefixes)


# TBP 常见实现体短名（与宿主 TYPE 同模块、单型时常用；Fortran 对过程名大小写不敏感）
_TBP_IMPL_SHORT_NAMES = frozenset({
    "validateprops",
    "initfromprops",
    "valid",
    "init",
    "clear",
    "reglayout",
    "ensure",
    "destroy",
    "update",
    "clean",
    "reset",
    "copy",
    "config",
    "pack",
    "unpack",
    "finalize",
    "getsummary",
    "cleanup",
    "desc_validate",
    "desc_computedderived",
    "desc_finalize",
    "desc_compute_ke",
    "desc_compute_fe",
    "mgr_init",
    "mgr_clean",
    "mgr_reg",
    "mgr_getstat",
    "dispatch_table_init",
    "dispatch_table_clean",
})


def _procedure_name_ok(name: str) -> bool:
    """过程名：层前缀（大小写不敏感）、TYPE 绑定（*Def_*）、L3 解析入口或下划线分词 legacy 名。"""
    low = name.lower()
    if low in _TBP_IMPL_SHORT_NAMES:
        return True
    if _layer_prefix_ok(
        name, ("md_", "ph_", "nm_", "rt_", "if_", "ufc_", "uf_", "ap_", "kw_")
    ):
        return True
    if "def_" in low:
        return True
    # L3 关键字 / 统一解析入口（大小写不敏感）
    if low.startswith(("parse_", "valid_", "validate_")):
        return True
    # 小工具（无层前缀、单词少）
    if low.startswith(("to_", "hash_")):
        return True
    # Legacy：Fortran 不区分大小写，ElasticProperties_Init 等价于全小写+下划线
    if "_" in low and re.fullmatch(r"[a-z][a-z0-9_]*", low):
        return True
    # Legacy：含大写字母的标识符（PascalCase / UMAT 风格），视为历史 API
    if any(ch.isupper() for ch in name):
        return True
    return False


# L3_MD KeyWord：MD_KW_Parser 等模块名不以 _Core 结尾（与 *_Core 重构并存）
_KW_LEGACY_MODULE_NAMES = frozenset({
    "md_kw_parser",
    "md_kw_lexer",
    "md_kw_registry",
    "md_kw_mempool",
    "md_kw_memorypool",
    "md_kw_mapper",
    "md_kw_dispatch",
    "md_kw_abaqus",
    "md_inp_parse",
})

# L3_MD Material: registry façade module name predates _Reg suffix convention (wide USE graph).
_MAT_LEGACY_MODULE_NAMES = frozenset({
    "md_mat_reg",
})

# L4_PH/Material: façade modules whose stem matches v3 role suffix `_Dsp` / Populate
# cold-path entry; `_dsp` / bare `_Populate` are not in the generic suffix tuple.
_PH_MAT_FACE_MODULE_NAMES = frozenset({
    "ph_mat_dsp",
    "ph_l4_populate",
    # L4_PH/Material/Dispatch — legacy façade MODULE stems (MODULE == filename; suffix not in core 20)
    "ph_mateval",
    "ph_matplmeval",
    "ph_matplm_kernels",
    "ph_matplm_plastcall",
    "ph_matplm_legacyfacadeumats",
    "ph_matela_elascall",
})

# L3_MD Material: seven Abaqus-style category packs (no _Core/_Types suffix).
_MAT_CATEGORY_PACK_MODULE_NAMES = frozenset({
    "md_mat_elastic",
    "md_mat_plasticity",
    "md_mat_hyperelasticity",
    "md_mat_visco",
    "md_mat_damage",
    "md_mat_thermalmultiphysics",
    "md_mat_special",
})


def _module_name_ok(name: str) -> bool:
    """模块名后缀：大小写不敏感；扩展 _Lib/_Ids/_Base/_Bridge 等 Mat/工具模块形态。"""
    if not name:
        return False
    low = name.lower()
    if low == "ufc_core":
        return True
    # Mat 域拆分类型包：MD_Mat_Types_Elastic / _Plastic / …（不以 _Types 结尾）
    if low.startswith("md_mat_types_"):
        return True
    suffixes = (
        "_core",
        "_type",
        "_types",
        "_intf",
        "_wrapper",
        "_module",
        "_api",
        "_idx_api",
        "_pairdef",
        "_propdb",
        "_surfbridge",
        "_sync",
        "_brg",
        "_lib",
        "_ids",
        "_base",
        "_bridge",
        "_parse",
        # L3_MD Analysis (and common L3) domain split: Def / Algo / UF / Idx modules
        "_def",
        "_algo",
        "_uf",
        "_idx",
        "_proc",
    )
    if low in _KW_LEGACY_MODULE_NAMES:
        return True
    if low in _MAT_LEGACY_MODULE_NAMES:
        return True
    if low in _MAT_CATEGORY_PACK_MODULE_NAMES:
        return True
    if low in _PH_MAT_FACE_MODULE_NAMES:
        return True
    return any(low.endswith(s) for s in suffixes)


class NamingChecker:
    """命名规范检查器"""
    
    # UFC 命名规范规则
    RULES = {
        "module_suffix": {
            "pattern": r"^module\s+(\w+)$",
            "check": _module_name_ok,
            "message": "模块名应以 UFC 约定后缀结尾（_Core/_Types/_API/_SurfBridge/…，大小写不敏感）"
        },
        "type_prefix": {
            "pattern": r"^\s*type\s*::\s*(\w+)",
            "check": lambda name: _layer_prefix_ok(
                name, ("MD_", "PH_", "NM_", "RT_", "IF_", "AP_", "UF_", "KW_")
            ),
            "message": "TYPE 名应以 MD_/PH_/NM_/RT_/IF_/AP_/UF_/KW_ 开头（大小写不敏感）"
        },
        "procedure_prefix": {
            "pattern": r"^\s*(?:recursive\s+|pure\s+)*(?:subroutine|function)\s+(\w+)",
            "check": _procedure_name_ok,
            "message": "过程名应为层前缀(MD/PH/…，大小写不敏感)或 TYPE 绑定名(*Def_*)"
        },
        "variable_naming": {
            "pattern": r"^\s*(integer|real|logical|character)\s*(?:\(\w+\))?\s*::\s*(\w+)",
            "check": lambda name: name.islower() or name.isupper(),
            "message": "变量名应全小写或全大写"
        },
        "constant_upper": {
            "pattern": r"^\s*integer,\s*parameter\s*::\s*(\w+)",
            "check": lambda name: name.isupper(),
            "message": "常量名应全大写"
        }
    }
    
    # 禁止的模式
    FORBIDDEN_PATTERNS = [
        (r"^\s*!.*TODO", "注释中包含 TODO 未清理"),
        (r"^\s*!.*FIXME", "注释中包含 FIXME 未清理"),
        (r"^\s*!.*XXX", "注释中包含 XXX 未清理"),
        (r"write\s*\(\*\*,?\s*\*\)", "调试用的 write(*,*) 未移除"),
        (r"print\s*\*", "调试用的 print * 未移除")
    ]
    
    def __init__(self, root_path: str = None):
        self.root_path = Path(root_path) if root_path else None
        if self.root_path is None:
            core = harness_paths.ufc_core_dir()
            self.root_path = core if core.exists() else Path.cwd()
        self.issues: List[Dict] = []
        self.stats = defaultdict(int)
    
    def check_file(self, file_path: Path) -> Dict:
        """检查单个文件"""
        issues = []
        
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            lines = content.split('\n')
        except Exception as e:
            return {
                "file": str(file_path),
                "success": False,
                "error": str(e)
            }
        
        # 检查每行
        for line_num, line in enumerate(lines, 1):
            # 跳过注释行
            stripped = line.strip()
            if stripped.startswith('!'):
                continue
            
            # 检查禁止模式
            for pattern, message in self.FORBIDDEN_PATTERNS:
                if re.search(pattern, stripped, re.IGNORECASE):
                    issues.append({
                        "line": line_num,
                        "content": stripped[:80],
                        "type": "forbidden",
                        "message": message
                    })
            
            # 检查命名规则
            for rule_name, rule in self.RULES.items():
                match = re.search(rule['pattern'], stripped, re.IGNORECASE)
                if match:
                    name = match.group(1) if match.lastindex else None
                    if name and not rule['check'](name):
                        issues.append({
                            "line": line_num,
                            "content": stripped[:80],
                            "type": "naming",
                            "rule": rule_name,
                            "message": rule['message']
                        })
        
        return {
            "file": str(file_path.relative_to(self.root_path)) if self.root_path and file_path.is_relative_to(self.root_path) else str(file_path),
            "success": len(issues) == 0,
            "issues": issues
        }
    
    def check_directory(self, directory: Path = None) -> Dict:
        """检查目录下的所有 .f90 文件"""
        dir_path = Path(directory) if directory else self.root_path
        
        results = []
        for f90_file in dir_path.rglob("*.f90"):
            result = self.check_file(f90_file)
            results.append(result)
            
            if not result['success']:
                self.stats['files_with_issues'] += 1
                self.issues.extend([
                    {**issue, 'file': result['file']} 
                    for issue in result['issues']
                ])
            else:
                self.stats['clean_files'] += 1
        
        self.stats['total_files'] = len(results)
        
        return {
            "directory": str(dir_path),
            "total_files": self.stats['total_files'],
            "clean_files": self.stats['clean_files'],
            "files_with_issues": self.stats['files_with_issues'],
            "results": results,
            "all_issues": self.issues
        }
    
    def generate_report(self, result: Dict) -> str:
        """生成文本报告"""
        lines = [
            "=" * 60,
            "UFC 命名规范检查报告",
            "=" * 60,
            f"检查目录: {result['directory']}",
            f"总文件数: {result['total_files']}",
            f"合规文件: {result['clean_files']}",
            f"问题文件: {result['files_with_issues']}",
            ""
        ]
        
        if result['all_issues']:
            lines.append("问题详情:")
            lines.append("-" * 40)
            
            # 按文件分组
            by_file = defaultdict(list)
            for issue in result['all_issues']:
                by_file[issue['file']].append(issue)
            
            for file_path, issues in sorted(by_file.items()):
                lines.append(f"\n[{file_path}]")
                for issue in issues:
                    lines.append(f"  L{issue['line']}: {issue['message']}")
                    lines.append(f"    {issue['content']}")
        
        lines.append("")
        lines.append("=" * 60)
        
        return "\n".join(lines)


def main():
    """主函数"""
    import argparse

    parser = argparse.ArgumentParser(description="UFC 命名规范检查器")
    parser.add_argument(
        "--git-diff-no-new-module-algo",
        nargs=2,
        metavar=("FROM", "TO"),
        help="对 git 范围 FROM..TO 的 diff 检查是否新增 MODULE …_Algo（违规则 exit 1）",
    )
    parser.add_argument(
        "--git-repo",
        type=str,
        default=None,
        help="git 仓库根（默认：自 cwd 向上查找 .git）",
    )
    parser.add_argument(
        "--pathspec",
        action="append",
        default=[],
        help="git diff 的 pathspec，可重复；默认 UFC/ufc_core",
    )
    parser.add_argument(
        "--github-actions-annotations",
        action="store_true",
        help="以 ::error file=…:: 输出（GitHub Actions 注解）",
    )
    parser.add_argument("path", nargs="?", help="检查路径 (文件或目录)；与 --git-diff-no-new-module-algo 二选一")
    parser.add_argument("--output", "-o", help="输出报告文件")
    parser.add_argument("--json", action="store_true", help="JSON 格式输出")

    args = parser.parse_args()

    if args.git_diff_no_new_module_algo:
        repo = Path(args.git_repo).resolve() if args.git_repo else find_git_repo_root()
        if repo is None:
            print("::warning::未找到 .git 仓库根，跳过「禁止新 MODULE *_Algo」检查")
            sys.exit(0)
        specs = args.pathspec if args.pathspec else ["UFC/ufc_core"]
        fr, to = args.git_diff_no_new_module_algo[0], args.git_diff_no_new_module_algo[1]
        code = run_git_policy_no_new_module_algo(
            repo, fr, to, specs, github_actions=args.github_actions_annotations
        )
        sys.exit(code)

    if args.path:
        check_path = args.path
    else:
        core = harness_paths.ufc_core_dir()
        check_path = str(core) if core.exists() else str(Path.cwd() / "ufc_core")
    path = Path(check_path)

    checker = NamingChecker()
    exit_code = 1

    if path.is_file():
        result = checker.check_file(path)
        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            nf = len(result.get("issues") or [])
            print(f"{path}: {'OK' if result.get('success') else f'{nf} issue(s)'}")
        exit_code = 0 if result.get("success") else 1
    else:
        result = checker.check_directory(path)

        if args.json:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            report = checker.generate_report(result)
            print(report)

            if args.output:
                Path(args.output).write_text(report, encoding="utf-8")
                print(f"\n报告已保存到: {args.output}")

        exit_code = 0 if result.get("files_with_issues", 1) == 0 else 1

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
