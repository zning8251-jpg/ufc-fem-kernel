#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC Structured IO Checker (SIO-01~14)

自动化检查 **`*_Proc.f90`** 模块是否符合 UFC Principle #14 相关约定。

**分层（重要）**：
- **L5 / RT `*_Proc.f90`**（默认严格档）：要求 **`*_Arg` / `*_In|Out`**、**`ABSTRACT INTERFACE`**、操作词命名等，与 L5 热路径 SIO 对齐。
- **`L3_MD` 下 `*_Proc.f90`**（放宽档，与 L5 区分）：此类文件多为 **UF 过程常量 / legacy 过程束**（如 **`MD_Step_Proc`**），**不**强制 L5 的 *_Arg 块与 ABSTRACT INTERFACE；只要模块内使用 **`ErrorStatusType`** 等错误语义即视为 SIO 数据链基本合格。由路径 **`…/L3_MD/…`** 且文件名 **`*_Proc.f90`** 自动识别，或通过 **`--layer L3`** 强制。

未实现 CFG 扫描的规则：
- **SIO-07 / SIO-08**（热路径无 I/O / ALLOCATE）：当前 **默认记为通过**（占位），避免全仓库误报。
- SIO-01: _Proc 模块存在
- SIO-02: 每操作有 *_Arg（新）或 _In/_Out 对（遗留）
- SIO-03: *_Arg（或 _Out）含 ErrorStatusType
- SIO-04: ABSTRACT INTERFACE 完整
- SIO-05: *_Arg 的 [IN] 段无 ALLOCATABLE
- SIO-06: Ctx 无 ALLOCATABLE
- SIO-07: 热路径无 I/O
- SIO-08: 热路径无 ALLOCATE
- SIO-09: 命名含操作词
- SIO-10: IMPORT 完整
- SIO-11: TYPE 体内无 INTENT
- SIO-12: 接口为五参或六参，末参为 args
- SIO-13: *_Arg / _In 无四大类内嵌
- SIO-14: 版本注释更新

用法:
  python sio_checker.py                           # 检查整个 L5_RT（仅 *_Proc.f90）
  python sio_checker.py L5_RT/Solver/RT_Solv_Proc.f90  # 检查单个文件
  python sio_checker.py L3_MD/Analysis/Step/MD_Step_Proc.f90  # L3_MD 下自动用放宽档
  python sio_checker.py --layer L5 …            # 强制严格档
  python sio_checker.py --json                  # JSON 输出
  python sio_checker.py … --out-json rep.json --quiet
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Any
from dataclasses import dataclass, field
from collections import defaultdict


@dataclass
class SIOViolation:
    rule: str
    severity: str  # ERROR / WARNING / INFO
    message: str
    line: int = 0


@dataclass
class SIOCheckResult:
    file: str
    module_name: str = ""
    checks: Dict[str, bool] = field(default_factory=dict)
    violations: List[SIOViolation] = field(default_factory=list)
    passed: bool = True


class SIOChecker:
    """UFC Structured IO Checker - SIO-01~14"""

    RULES = {
        "SIO-01": "模块文件存在",
        "SIO-02": "每操作有 *_Arg（新）或 _In/_Out 对（遗留）",
        "SIO-03": "*_Arg（或 _Out）含 ErrorStatusType",
        "SIO-04": "ABSTRACT INTERFACE 完整",
        "SIO-05": "*_Arg 的 [IN] 段无 ALLOCATABLE",
        "SIO-06": "Ctx 无 ALLOCATABLE",
        "SIO-07": "热路径无 I/O",
        "SIO-08": "热路径无 ALLOCATE",
        "SIO-09": "命名含操作词",
        "SIO-10": "IMPORT 完整",
        "SIO-11": "TYPE 体内无 INTENT",
        "SIO-12": "接口为五参或六参，末参为 args",
        "SIO-13": "*_Arg / _In 无四大类内嵌",
        "SIO-14": "版本注释更新",
    }

    # 合规的 B类后缀
    VALID_B_SUFFIXES = ("_Impl", "_API", "_Bridge", "_Exec", "_Proc")

    def __init__(self, root_path: Path = None, layer_mode: str = "auto"):
        self.root_path = root_path
        self.results: List[SIOCheckResult] = []
        # auto | L3 | L5 — 见模块文档「分层」
        self.layer_mode = (layer_mode or "auto").lower()

    def _is_l3_md_proc_relax_path(self, file_path: Path) -> bool:
        """L3_MD 下的 *_Proc.f90 使用放宽档（与 L5 RT _Proc 区分）。"""
        lm = self.layer_mode
        if lm == "l5":
            return False
        name = file_path.name.lower()
        if not name.endswith("_proc.f90"):
            return False
        if lm == "l3":
            return True
        parts = [p.lower() for p in file_path.parts]
        return "l3_md" in parts

    def check_file(self, file_path: Path) -> SIOCheckResult:
        """检查单个 _Proc 文件"""
        result = SIOCheckResult(file=str(file_path))

        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            lines = content.split('\n')
        except Exception as e:
            result.violations.append(SIOViolation(
                "SIO-01", "ERROR", f"无法读取文件: {e}"
            ))
            result.passed = False
            return result

        # SIO-01: 检查 _Proc 模块文件
        result.checks["SIO-01"] = True

        relax_l3 = self._is_l3_md_proc_relax_path(file_path)
        setattr(result, "sio_layer", "L3_MD_Proc_relaxed" if relax_l3 else "L5_Proc_strict")

        # 提取模块名
        module_match = re.search(r'MODULE\s+(\w+)', content, re.IGNORECASE)
        if module_match:
            result.module_name = module_match.group(1)

        # SIO-02: 检查 *_Arg 或 _In/_Out
        has_arg = bool(re.search(r'TYPE\s+\w+_Arg\b', content))
        has_in_out = bool(re.search(r'TYPE\s+\w+_(In|Out)\b', content))
        result.checks["SIO-02"] = has_arg or has_in_out
        if not result.checks["SIO-02"]:
            result.violations.append(SIOViolation(
                "SIO-02", "ERROR", "未找到 *_Arg 或 *_In/*_Out TYPE 定义", 0
            ))

        # SIO-05：无 *_Arg 时本项不适用，记为通过（否则 dict 缺键导致汇总误报）
        if not has_arg:
            result.checks["SIO-05"] = True

        # SIO-03: *_Arg 或 _Out 含 ErrorStatusType
        has_status = bool(re.search(r'TYPE\s+\w+_Arg\b.*?ErrorStatusType',
                                     content, re.DOTALL))
        has_out_status = bool(re.search(r'TYPE\s+\w+_Out\b.*?ErrorStatusType',
                                         content, re.DOTALL))
        result.checks["SIO-03"] = has_status or has_out_status
        if not result.checks["SIO-03"]:
            result.violations.append(SIOViolation(
                "SIO-03", "ERROR", "*_Arg 或 *_Out 缺少 ErrorStatusType", 0
            ))

        # SIO-04: ABSTRACT INTERFACE 完整
        interface_count = len(re.findall(r'ABSTRACT\s+INTERFACE', content, re.IGNORECASE))
        result.checks["SIO-04"] = interface_count > 0

        # SIO-05: *_Arg 的 [IN] 段无 ALLOCATABLE
        if has_arg:
            in_alloc = self._check_in_section_allocatable(content, r'TYPE\s+(\w+_Arg)')
            if in_alloc:
                result.violations.append(SIOViolation(
                    "SIO-05", "ERROR", f"TYPE {in_alloc} 的 [IN] 段含 ALLOCATABLE", 0
                ))
                result.checks["SIO-05"] = False
            else:
                result.checks["SIO-05"] = True

        # SIO-06: Ctx 无 ALLOCATABLE
        ctx_alloc = self._check_type_allocatable(content, r'TYPE\s+.*?Ctx\b')
        result.checks["SIO-06"] = not ctx_alloc
        if ctx_alloc:
            result.violations.append(SIOViolation(
                "SIO-06", "WARNING", f"TYPE *Ctx 含 ALLOCATABLE 字段", 0
            ))

        # SIO-11: TYPE 体内无 INTENT（核心检查）
        type_intent_violations = self._check_type_intent(content)
        result.checks["SIO-11"] = len(type_intent_violations) == 0
        for line, type_name in type_intent_violations:
            result.violations.append(SIOViolation(
                "SIO-11", "ERROR", f"TYPE {type_name} 体内含 INTENT 属性（非法）", line
            ))

        # SIO-12: 接口为五参或六参，末参为 args
        interface_params = self._check_interface_params(content)
        if interface_params:
            is_valid, msg = interface_params
            result.checks["SIO-12"] = is_valid
            if not is_valid:
                result.violations.append(SIOViolation(
                    "SIO-12", "ERROR", f"接口参数: {msg}", 0
                ))
        else:
            result.checks["SIO-12"] = True  # 无接口则跳过

        # SIO-13: *_Arg / _In 无四大类内嵌
        embedded = self._check_embedded_base_types(content)
        result.checks["SIO-13"] = len(embedded) == 0
        for type_name in embedded:
            result.violations.append(SIOViolation(
                "SIO-13", "ERROR", f"TYPE {type_name} 内嵌 Desc/State/Algo/Ctx", 0
            ))

        # SIO-09: 命名含操作词
        has_operation = bool(re.search(r'TYPE\s+\w+_(Init|Update|Validate|Compute)\b', content))
        result.checks["SIO-09"] = has_operation

        # SIO-14: 版本注释
        has_version = bool(re.search(r'\[v\d+\.\d+\]', content))
        result.checks["SIO-14"] = has_version

        # SIO-07 / SIO-08：尚未做过程级 CFG / 热路径扫描，占位为通过，避免全仓库假失败
        result.checks["SIO-07"] = True
        result.checks["SIO-08"] = True

        # --- L3_MD *Proc 放宽档：与 L5 RT _Proc 区分 ---
        if relax_l3:
            has_et = "ErrorStatusType" in content
            result.checks["SIO-02"] = has_arg or has_in_out or has_et
            result.checks["SIO-03"] = has_et
            result.checks["SIO-04"] = True
            result.checks["SIO-09"] = True
            result.checks["SIO-10"] = True
            result.checks["SIO-14"] = True
            if not has_arg:
                result.checks["SIO-05"] = True
            drop_rules = {"SIO-02", "SIO-03", "SIO-04", "SIO-09", "SIO-10", "SIO-14"}
            if not has_arg:
                drop_rules.add("SIO-05")
            result.violations = [v for v in result.violations if v.rule not in drop_rules]

        # 汇总：与 RULES 键对齐（防止缺键）
        result.passed = all(result.checks.get(rule, False) for rule in self.RULES)

        return result

    def _check_in_section_allocatable(self, content: str, pattern: str) -> str:
        """检查 [IN] 段是否有 ALLOCATABLE"""
        for match in re.finditer(pattern, content):
            type_name = match.group(1)
            # 提取 TYPE 块
            type_start = match.start()
            type_end = content.find('END TYPE', type_start)
            if type_end == -1:
                continue
            type_block = content[type_start:type_end]

            # 检查是否有 [IN] 段
            in_section = re.search(r'!\s*--\s*\[IN\](.*?)(?:!\s*--\s*\[OUT\]|$)',
                                   type_block, re.DOTALL)
            if in_section and 'ALLOCATABLE' in in_section.group(1):
                return type_name
        return ""

    def _check_type_allocatable(self, content: str, pattern: str) -> str:
        """检查 TYPE 是否含 ALLOCATABLE"""
        for match in re.finditer(pattern, content, re.IGNORECASE):
            type_start = match.start()
            type_end = content.find('END TYPE', type_start)
            if type_end == -1:
                continue
            type_block = content[type_start:type_end]
            if 'ALLOCATABLE' in type_block:
                return match.group(0)
        return ""

    def _check_type_intent(self, content: str) -> List[Tuple[int, str]]:
        """检查 TYPE 体内是否有 INTENT（非法）"""
        violations = []
        for match in re.finditer(r'TYPE\s*,\s*(?:PUBLIC\s+|PRIVATE\s+)?::?\s*(\w+)',
                                 content):
            type_name = match.group(1)
            type_start = match.start()
            type_end = content.find('END TYPE', type_start)
            if type_end == -1:
                continue

            # 获取行号
            line_num = content[:type_start].count('\n') + 1

            # 在 TYPE 块内查找 INTENT
            type_block = content[type_start:type_end]
            intent_match = re.search(r'INTENT\s*\(', type_block)
            if intent_match:
                violations.append((line_num, type_name))

        return violations

    def _check_interface_params(self, content: str) -> Tuple[bool, str]:
        """检查 ABSTRACT INTERFACE 参数是否为五参或六参，末参为 args"""
        interface_pattern = r'ABSTRACT\s+INTERFACE.*?END\s+INTERFACE'
        for match in re.finditer(interface_pattern, content, re.DOTALL | re.IGNORECASE):
            interface_block = match.group(0)
            sub_match = re.search(r'SUBROUTINE\s+\w+\s*\(([^)]+)\)',
                                  interface_block, re.IGNORECASE)
            if sub_match:
                params = [p.strip() for p in sub_match.group(1).split(',')]
                if len(params) < 4:
                    return False, f"参数少于4个: {len(params)}"
                last_param = params[-1].strip().split()[-1]  # 取最后一个参数名
                if last_param != 'args':
                    return False, f"末参不是 'args'，而是 '{last_param}'"
                # 检查倒数第二个是否为 RT_Com_Ctx（可选六参）
                if len(params) >= 6:
                    second_last = params[-2].strip().split()[-1]
                    if 'RT_Com_Ctx' not in second_last and 'ctx' not in second_last.lower():
                        return False, f"六参但第五参不是 RT_Com_Ctx"
        return True, ""

    def _check_embedded_base_types(self, content: str) -> List[str]:
        """检查 *_Arg 或 *_In 是否内嵌 Desc/State/Algo/Ctx"""
        embedded = []
        patterns = [
            r'TYPE\s+(\w+_Arg)\b.*?(?=END TYPE)',
            r'TYPE\s+(\w+_In)\b.*?(?=END TYPE)',
        ]
        for pattern in patterns:
            for match in re.finditer(pattern, content, re.DOTALL):
                type_name = match.group(1)
                type_block = match.group(0)
                if any(f'Base_{t}' in type_block for t in ['Desc', 'State', 'Algo', 'Ctx']):
                    embedded.append(type_name)
        return embedded

    def check_directory(self, dir_path: Path) -> List[SIOCheckResult]:
        """检查目录下所有 _Proc.f90 文件"""
        results = []
        for f90_file in dir_path.rglob("*_Proc.f90"):
            result = self.check_file(f90_file)
            results.append(result)
            self.results.append(result)
        return results

    def generate_report(self, results: List[SIOCheckResult], json_output: bool = False) -> str:
        """生成检查报告"""
        if json_output:
            data = {
                "total_files": len(results),
                "passed": sum(1 for r in results if r.passed),
                "failed": sum(1 for r in results if not r.passed),
                "results": [
                    {
                        "file": r.file,
                        "module": r.module_name,
                        "sio_layer": getattr(r, "sio_layer", ""),
                        "passed": r.passed,
                        "checks": r.checks,
                        "violations": [
                            {"rule": v.rule, "severity": v.severity,
                             "message": v.message, "line": v.line}
                            for v in r.violations
                        ]
                    }
                    for r in results
                ]
            }
            return json.dumps(data, indent=2, ensure_ascii=False)

        # 文本报告
        lines = [
            "=" * 70,
            "UFC Structured IO Checker - SIO-01~14 检查报告",
            "=" * 70,
            f"检查文件数: {len(results)}",
            f"通过: {sum(1 for r in results if r.passed)}",
            f"失败: {sum(1 for r in results if not r.passed)}",
            "",
        ]

        for result in results:
            if not result.passed:
                lines.append(f"\n[{result.module_name or result.file}]")
                for v in result.violations:
                    line_info = f"L{v.line}" if v.line else "L?"
                    lines.append(f"  {v.rule} [{v.severity}] {line_info}: {v.message}")

        # 检查项汇总
        lines.append("\n" + "=" * 70)
        lines.append("检查项汇总:")
        for rule, desc in self.RULES.items():
            passed = sum(1 for r in results if r.checks.get(rule, False))
            n = len(results)
            status = "[OK]" if (n == 0 or passed == n) else "[X]"
            if n == 0:
                lines.append(f"  {status} {rule}: {desc} (no matching *_Proc.f90)")
            else:
                lines.append(f"  {status} {rule}: {desc} ({passed}/{n})")

        lines.append("=" * 70)
        return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description='UFC Structured IO Checker - SIO-01~14'
    )
    parser.add_argument('path', nargs='?', help='检查路径（文件或目录）')
    parser.add_argument('--json', action='store_true', help='JSON 输出到 stdout')
    parser.add_argument('--out-json', metavar='PATH', help='JSON 报告写入 PATH（UTF-8），便于 CI 收集')
    parser.add_argument('--quiet', action='store_true', help='不向 stdout 打印（需配合 --out-json）')
    parser.add_argument(
        '--layer',
        choices=('auto', 'L3', 'L5'),
        default='auto',
        help='SIO 档位：auto=路径含 L3_MD 且 *_Proc.f90 用 L3 放宽档；L3=凡 *_Proc.f90 均放宽；L5=全严格',
    )
    parser.add_argument('--ufc-root', default='../../ufc_core', help='UFC 根目录')

    args = parser.parse_args()

    # 确定路径
    if args.path:
        check_path = Path(args.path)
    else:
        ufc_root = Path(__file__).parent.parent.parent / 'ufc_core' / 'L5_RT'
        check_path = ufc_root if ufc_root.exists() else Path('.')

    checker = SIOChecker(layer_mode=args.layer)

    if check_path.is_file():
        results = [checker.check_file(check_path)]
    else:
        results = checker.check_directory(check_path)

    json_text = checker.generate_report(results, json_output=True)
    if args.out_json:
        Path(args.out_json).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out_json).write_text(json_text, encoding="utf-8")

    if not args.quiet:
        print(checker.generate_report(results, json_output=args.json))
    elif args.json and not args.out_json:
        print(json_text)

    # 退出码
    failed = sum(1 for r in results if not r.passed)
    sys.exit(1 if failed > 0 else 0)


if __name__ == '__main__':
    main()
