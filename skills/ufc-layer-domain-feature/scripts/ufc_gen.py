#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC 层级-域级-功能级-子程序 模板一键生成脚本（快捷键命令式）

用法:
  python ufc_gen.py LAYER DOMAIN FEATURE [MODULE_OR_SUB]
示例:
  python ufc_gen.py L4_PH BC Dirichlet
  python ufc_gen.py L5_RT Solv Nonlin RT_Solv_Nonlin_Core

输出: 打印模板设计（容器路径、四类 TYPE、四链+数据结构拆解+Contents 头注释骨架、
      Mermaid 占位），便于复制到文件或由 Agent 直接实施。对齐六层+四类+四链+三步+三级+两图+一体。
"""

import sys
import os

PREFIX = {"L3_MD": "MD_", "L4_PH": "PH_", "L5_RT": "RT_", "L6_AP": "AP_"}


def main():
    args = [a.strip() for a in sys.argv[1:] if a.strip()]
    if len(args) < 3:
        print("Usage: ufc_gen.py LAYER DOMAIN FEATURE [MODULE_OR_SUB]")
        print("Example: ufc_gen.py L4_PH BC Dirichlet")
        print("         ufc_gen.py L5_RT Solv Nonlin RT_Solv_Nonlin_Core")
        sys.exit(1)
    layer, domain, feature = args[0], args[1], args[2]
    module_or_sub = args[3] if len(args) > 3 else f"{PREFIX.get(layer, '')}{domain}_{feature}_Core"

    if layer not in PREFIX:
        print(f"Warning: Layer {layer} not in L3_MD|L4_PH|L5_RT|L6_AP, using generic prefix.")

    container_path = f"g_ufc_global%{layer.lower().replace('_','')}%{domain.lower()}"
    # normalize: L5_RT -> runtime, L4_PH -> physics, L3_MD -> model_data, L6_AP -> application
    layer_key = {"L3_MD": "model_data", "L4_PH": "physics", "L5_RT": "runtime", "L6_AP": "application"}.get(layer, layer.lower())
    container_path = f"g_ufc_global%{layer_key}%{domain.lower()}"

    pre = PREFIX.get(layer, "UF_")
    desc_name = f"{pre}{domain}_{feature}_Desc"
    state_name = f"{pre}{domain}_{feature}_State"
    algo_name = f"{pre}{domain}_{feature}_Algo"
    ctx_name = f"{pre}{domain}_{feature}_Ctx"

    out = []
    out.append("=" * 60)
    out.append("UFC 模板设计（由 ufc_gen.py 生成）")
    out.append("=" * 60)
    out.append(f"Layer:    {layer}")
    out.append(f"Domain:   {domain}")
    out.append(f"Feature:  {feature}")
    out.append(f"Module:   {module_or_sub}")
    out.append("")
    out.append("容器路径:")
    out.append(f"  {container_path}")
    out.append("")
    out.append("四类 TYPE 建议:")
    out.append(f"  Desc:   {desc_name}  (只读配置)")
    out.append(f"  State:  {state_name}  (可变状态)")
    out.append(f"  Algo:   {algo_name}  (算法参数)")
    out.append(f"  Ctx:    {ctx_name}  (临时上下文)")
    out.append("")
    out.append("f90 头注释块（四链+数据结构拆解+Contents，请填入后写入文件）:")
    out.append("-" * 40)
    out.append("!===============================================================================")
    out.append(f"! Module: {module_or_sub}")
    out.append(f"! Layer:  {layer} - ...")
    out.append(f"! Domain: {domain}")
    out.append(f"! Feature: {feature}")
    out.append("! Purpose:")
    out.append("!   [TODO: one-line purpose]")
    out.append("!")
    out.append("! Theory chain (理论链):")
    out.append("!   [Manual/ref] → key eqns (Unicode) → this module role")
    out.append("!")
    out.append("! Logic chain (逻辑链):")
    out.append("!   [Caller] --> this module --> [Callees]")
    out.append("!")
    out.append("! Computation chain (计算链, Unicode math):")
    out.append("!   [TODO: key formulas]")
    out.append("!")
    out.append("! Data chain (数据链, four types):")
    out.append(f"!   - Desc : {desc_name}")
    out.append(f"!   - State: {state_name}")
    out.append(f"!   - Algo : {algo_name}")
    out.append(f"!   - Ctx  : {ctx_name}")
    out.append("!")
    out.append("! Data structure (数据结构拆解):")
    out.append(f"!   Container path: {container_path}")
    out.append("!   Desc: [array/single], fields [...] , read-only")
    out.append("!   State: [array/single], fields [...] , updated in Step/Iter")
    out.append("!   Algo: singleton, fields [...] , read-only at solve")
    out.append("!   Ctx: per call/iter, not stored in container")
    out.append("!")
    out.append("! Three-step mapping: [Step|Increment|Iteration] --> [entry subroutine]")
    out.append("!")
    out.append("! Contents (TYPE / SUBROUTINE 列举表, A-Z):")
    out.append("!   Types:")
    out.append(f"!     - {desc_name}, {state_name}, {algo_name}, {ctx_name}")
    out.append("!   Subroutines:")
    out.append("!     - [TODO: list PUBLIC subroutines]")
    out.append("!")
    out.append("! Notes: Desc read-only; State updated only in ...")
    out.append("! Status: CORE | Last verified: YYYY-MM-DD")
    out.append("!===============================================================================")
    out.append("-" * 40)
    out.append("")
    out.append("Mermaid 四链（请放入 *_Chains.md）: 逻辑链 + 计算链 必选；理论链/数据链 按需")
    out.append("-" * 40)
    out.append('flowchart TD  %% logic')
    out.append('  A["[Caller]"] --> B["' + module_or_sub + '"]')
    out.append('  B --> C["[Callee1]"]')
    out.append('  B --> D["[Callee2]"]')
    out.append("-" * 40)
    out.append("")
    out.append("请将上述内容交给 Agent 或复制到对应 f90 / *_Chains.md 中，并执行 PLAN 检查清单。")
    out.append("")

    print("\n".join(out))


if __name__ == "__main__":
    main()
