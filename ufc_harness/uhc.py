#!/usr/bin/env python3
"""
UFC Harness 统一入口（按「类别 + 工具名」转发到 tools/ 下脚本）。

推荐日常使用：同目录下的 run_harness.py（子命令更贴近 CI）。
"""

import os
import subprocess
import sys
from pathlib import Path


TOOLS = {
    "doc": {
        "name": "文档管理",
        "tools": [
            ("doc_structure_checker", "检查目录结构"),
            ("cross_ref_validator", "验证交叉引用"),
            ("redundancy_detector", "检测冗余内容"),
            ("analyze_links", "分析链接"),
            ("analyze_anchors", "分析锚点"),
            ("analyze_file_links", "分析文件链接"),
            ("anchor_link_fixer", "修复锚点链接"),
        ],
    },
    "code": {
        "name": "代码开发",
        "tools": [
            ("module_scaffold", "生成模块脚手架"),
            ("naming_checker", "命名规范检查"),
            ("sio_checker", "SIO-01~14 结构化IO检查"),
            ("build_trigger", "CMake 构建触发"),
        ],
    },
    "algo": {
        "name": "算法落地图谱",
        "tools": [
            ("algo_tracing", "算法追踪"),
            ("contract_linker", "合同卡关联"),
        ],
    },
    "arch": {
        "name": "架构验证",
        "tools": [
            ("arch_consistency", "架构一致性验证"),
            ("domain_boundary_checker", "六层依赖铁律检查"),
        ],
    },
}


def list_tools() -> None:
    print("=" * 70)
    print("UFC Harness Engineering - 工具列表")
    print("=" * 70)

    for category, info in TOOLS.items():
        print(f"\n{info['name']} ({category}):")
        for tool_name, tool_desc in info["tools"]:
            print(f"  {tool_name:25} - {tool_desc}")

    print("\n" + "=" * 70)
    print("使用示例（在仓库根执行，路径按你本机 UFC 位置调整）：")
    print("  python UFC/ufc_harness/uhc.py doc doc_structure_checker UFC/design_plan")
    print("  python UFC/ufc_harness/run_harness.py plan-checks")
    print("  python UFC/ufc_harness/run_harness.py build --status")
    print("=" * 70)


def run_tool(category: str, tool_name: str, args: list) -> bool:
    if category not in TOOLS:
        print(f"错误：无效类别 '{category}'")
        print(f"可用类别：{', '.join(TOOLS.keys())}")
        return False

    tool_found = any(t_name == tool_name for t_name, _ in TOOLS[category]["tools"])
    if not tool_found:
        print(f"错误：未找到工具 '{tool_name}'")
        print(f"可用工具：{', '.join(t[0] for t in TOOLS[category]['tools'])}")
        return False

    tools_dir = Path(__file__).parent / "tools"
    if category == "arch":
        tool_path = tools_dir / "arch_validation" / f"{tool_name}.py"
    elif category == "doc":
        tool_path = tools_dir / "doc_management" / f"{tool_name}.py"
    elif category == "code":
        tool_path = tools_dir / "code_development" / f"{tool_name}.py"
    elif category == "algo":
        tool_path = tools_dir / "algo_mapping" / f"{tool_name}.py"
    else:
        tool_path = tools_dir / category / f"{tool_name}.py"

    if not tool_path.exists():
        print(f"错误：工具文件不存在：{tool_path}")
        return False

    cmd = [sys.executable, str(tool_path)] + args
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    result = subprocess.run(cmd, encoding="utf-8", env=env)
    return result.returncode == 0


def main() -> None:
    if len(sys.argv) < 2:
        list_tools()
        return

    command = sys.argv[1].lower()
    if command in ("help", "-h", "--help"):
        list_tools()
        return

    if len(sys.argv) < 3:
        print("错误：缺少参数")
        print("用法：python uhc.py <类别> <工具名> [参数...]")
        sys.exit(1)

    category = sys.argv[1]
    tool_name = sys.argv[2]
    extra = sys.argv[3:]
    ok = run_tool(category, tool_name, extra)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
