#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC L3/L4/L5 命名合规基线扫描工具
检查文件名是否符合 {层前缀}_{域缩写}_{功能名称}[_{后缀}] 三级命名规范
"""
from pathlib import Path
import re
from collections import defaultdict
from datetime import datetime

UFC_ROOT = Path(__file__).resolve().parent.parent / "ufc_core"

# 层级前缀映射
LAYER_PREFIX = {
    "L3_MD": "MD_",
    "L4_PH": "PH_",
    "L5_RT": "RT_",
}

# 允许的角色后缀闭集
ALLOWED_SUFFIXES = {
    "_Def", "_Core", "_Ops", "_Eval", "_Brg", "_Proc", "_Sync", "_Reg", "_Mgr",
    "_API", "_Idx", "_Map", "_Ctrl", "_Impl", "_Exec", "_Loc", "_Glb",
    "_Asm", "_Sym", "_Lib", "_Strat", "_Solv", "_Step", "_Run", "_Pop",
    "_Wb", "_Wsp", "_Env", "_Orc", "_Drv", "_Cfg",
}

# 四型后缀（禁止用于文件名）
FORBIDDEN_TYPE_SUFFIXES = {"_Desc", "_State", "_Algo", "_Ctx"}

# 泛词集合（单泛词两段式禁止）
GENERIC_WORDS = {
    "Idx", "Reg", "Mgr", "API", "Core", "Def", "Brg", "Eval", "Proc",
    "Sync", "Ops", "Map", "Ctrl", "Impl", "Exec", "Lib", "Init",
    "Base", "Types", "Type", "Utils", "Util", "Data", "Domain",
}


def get_layer(filepath: Path) -> str | None:
    s = str(filepath)
    for layer in LAYER_PREFIX:
        if f"\\{layer}\\" in s or f"/{layer}/" in s:
            return layer
    return None


def get_domain_from_path(filepath: Path, layer: str) -> str:
    """从文件路径提取域名（L3_MD下的第一级子目录）"""
    s = str(filepath)
    sep = f"\\{layer}\\" if f"\\{layer}\\" in s else f"/{layer}/"
    after = s.split(sep, 1)[1]
    parts = after.replace("\\", "/").split("/")
    if len(parts) > 1:
        return parts[0]
    return "(root)"


def check_filename(filepath: Path, layer: str) -> list[dict]:
    """检查单个文件名的合规性，返回违规列表"""
    violations = []
    stem = filepath.stem  # 不含 .f90
    prefix = LAYER_PREFIX[layer]

    # Rule 1: 层前缀检查
    if not stem.startswith(prefix):
        violations.append({
            "rule": "R1-层前缀",
            "detail": f"文件名 '{stem}' 未以 '{prefix}' 开头",
            "suggestion": f"{prefix}{stem}",
        })
        return violations  # 前缀错误则后续规则无法可靠判定

    # 去除前缀后的部分
    rest = stem[len(prefix):]
    # 按下划线拆分（首字母大写的段）
    segments = rest.split("_")
    seg_count = len(segments)

    # Rule 2: 四型后缀禁止用于文件名
    for fs in FORBIDDEN_TYPE_SUFFIXES:
        suffix_word = fs[1:]  # 去掉下划线
        if seg_count >= 1 and segments[-1] == suffix_word:
            violations.append({
                "rule": "R2-四型后缀",
                "detail": f"文件名 '{stem}' 使用了禁止的四型后缀 '{fs}'",
                "suggestion": f"将 {fs} 移至TYPE定义，文件名改用 _Def",
            })

    # Rule 3: 两段式禁止（层缀+单泛词）
    # 即 prefix + 单个泛词，如 PH_Idx, MD_Reg
    if seg_count == 1 and segments[0] in GENERIC_WORDS:
        violations.append({
            "rule": "R3-两段式",
            "detail": f"文件名 '{stem}' 为层缀+单泛词两段式，缺少域缩写",
            "suggestion": f"添加域缩写，如 {prefix}XXX_{segments[0]}",
        })

    # Rule 4: 文件名长度检查（stem > 30字符建议）
    if len(stem) > 35:
        violations.append({
            "rule": "R4-过长",
            "detail": f"文件名 '{stem}' 长度 {len(stem)} 字符，超过35字符建议阈值",
            "suggestion": "使用压缩词根缩短",
        })

    # Rule 5: 全大写模块名检查（如 MD_MAT_COMPOSITE_CORE）
    if rest == rest.upper() and len(rest) > 3:
        violations.append({
            "rule": "R5-全大写",
            "detail": f"文件名 '{stem}' 使用全大写，应使用PascalCase混合",
            "suggestion": f"改用 PascalCase，如 {prefix}{rest.title().replace('_', '_')}",
        })

    return violations


def scan_layer(layer: str) -> tuple[list[dict], int, int]:
    """扫描某一层所有 .f90 文件"""
    layer_dir = UFC_ROOT / layer
    if not layer_dir.is_dir():
        return [], 0, 0

    files = sorted(layer_dir.rglob("*.f90"))
    results = []
    compliant = 0
    non_compliant = 0

    for f in files:
        viols = check_filename(f, layer)
        rel_path = str(f.relative_to(UFC_ROOT))
        domain = get_domain_from_path(f, layer)
        entry = {
            "file": f.stem + ".f90",
            "rel_path": rel_path,
            "domain": domain,
            "violations": viols,
        }
        results.append(entry)
        if viols:
            non_compliant += 1
        else:
            compliant += 1

    return results, compliant, non_compliant


def generate_report():
    layers = ["L3_MD", "L4_PH", "L5_RT"]
    all_results = {}
    summary = {}

    for layer in layers:
        results, comp, non_comp = scan_layer(layer)
        all_results[layer] = results
        summary[layer] = {"total": comp + non_comp, "compliant": comp, "non_compliant": non_comp}

    # 统计违规类型
    violation_type_count = defaultdict(int)
    violation_by_domain = defaultdict(lambda: defaultdict(int))
    for layer in layers:
        for entry in all_results[layer]:
            for v in entry["violations"]:
                violation_type_count[v["rule"]] += 1
                violation_by_domain[layer][entry["domain"]] += 1

    # 生成 Markdown 报告
    lines = []
    lines.append("# L3/L4/L5 命名合规基线报告")
    lines.append("")
    lines.append(f"> 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"> 扫描范围: `UFC/ufc_core/` 下 L3_MD / L4_PH / L5_RT 全部 .f90 文件")
    lines.append(f"> 规范依据: UFC_统一命名方案_v1.0 / UFC_命名规范与接口标准_v2.0 / ufc-naming.mdc")
    lines.append("")

    # 总览表
    lines.append("## 总览")
    lines.append("")
    lines.append("| 层 | 文件总数 | 合规数 | 不合规数 | 合规率 |")
    lines.append("|:---|:-------:|:-----:|:-------:|:------:|")
    total_all = 0
    comp_all = 0
    non_comp_all = 0
    for layer in layers:
        s = summary[layer]
        rate = f"{s['compliant']/s['total']*100:.1f}%" if s['total'] > 0 else "N/A"
        lines.append(f"| {layer} | {s['total']} | {s['compliant']} | {s['non_compliant']} | {rate} |")
        total_all += s['total']
        comp_all += s['compliant']
        non_comp_all += s['non_compliant']
    overall_rate = f"{comp_all/total_all*100:.1f}%" if total_all > 0 else "N/A"
    lines.append(f"| **合计** | **{total_all}** | **{comp_all}** | **{non_comp_all}** | **{overall_rate}** |")
    lines.append("")

    # 不合规文件清单
    lines.append("## 不合规文件清单")
    lines.append("")
    for layer in layers:
        non_comp_entries = [e for e in all_results[layer] if e["violations"]]
        lines.append(f"### {layer}")
        lines.append("")
        if not non_comp_entries:
            lines.append("**全部合规** :white_check_mark:")
            lines.append("")
            continue
        lines.append(f"共 {len(non_comp_entries)} 个不合规文件：")
        lines.append("")
        lines.append("| # | 文件路径 | 违反规则 | 建议修正 |")
        lines.append("|:--|:--------|:---------|:---------|")
        idx = 0
        for entry in non_comp_entries:
            for v in entry["violations"]:
                idx += 1
                lines.append(f"| {idx} | `{entry['rel_path']}` | {v['rule']}: {v['detail']} | {v['suggestion']} |")
        lines.append("")

    # 统计分析
    lines.append("## 统计分析")
    lines.append("")
    lines.append("### 最常见违规类型")
    lines.append("")
    lines.append("| 违规类型 | 数量 | 占比 |")
    lines.append("|:---------|:----:|:----:|")
    total_viols = sum(violation_type_count.values())
    for rule, count in sorted(violation_type_count.items(), key=lambda x: -x[1]):
        pct = f"{count/total_viols*100:.1f}%" if total_viols > 0 else "N/A"
        lines.append(f"| {rule} | {count} | {pct} |")
    if total_viols == 0:
        lines.append("| (无违规) | 0 | - |")
    lines.append("")

    lines.append("### 按域分布")
    lines.append("")
    for layer in layers:
        if violation_by_domain[layer]:
            lines.append(f"**{layer}**:")
            lines.append("")
            lines.append("| 域 | 不合规文件数 |")
            lines.append("|:---|:-----------:|")
            for domain, count in sorted(violation_by_domain[layer].items(), key=lambda x: -x[1]):
                lines.append(f"| {domain} | {count} |")
            lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("### 检查规则说明")
    lines.append("")
    lines.append("| 规则编号 | 规则名称 | 说明 |")
    lines.append("|:---------|:---------|:-----|")
    lines.append("| R1 | 层前缀 | L3文件必须 `MD_` 开头，L4必须 `PH_`，L5必须 `RT_` |")
    lines.append("| R2 | 四型后缀 | `_Desc`/`_State`/`_Algo`/`_Ctx` 禁止用于文件名（仅限TYPE定义） |")
    lines.append("| R3 | 两段式 | 禁止「层缀+单泛词」两段式命名（如 `PH_Idx.f90`） |")
    lines.append("| R4 | 过长 | 文件名（不含.f90）超过 35 字符 |")
    lines.append("| R5 | 全大写 | 文件名应使用 PascalCase 混合大小写 |")
    lines.append("")

    report_path = UFC_ROOT.parent / "REPORTS" / "Naming_Compliance_Baseline.md"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Report written to: {report_path}")
    print(f"\n=== Summary ===")
    print(f"Total files: {total_all}")
    print(f"Compliant: {comp_all} ({overall_rate})")
    print(f"Non-compliant: {non_comp_all}")
    for rule, count in sorted(violation_type_count.items(), key=lambda x: -x[1]):
        print(f"  {rule}: {count}")


if __name__ == "__main__":
    generate_report()
