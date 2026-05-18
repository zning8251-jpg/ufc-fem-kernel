# L6 AP_ 应用层

命令解析、Job 管理。原 ufc_core/Command/、Job/ 及 Inp/Out/Solv/Ctx/Flow/Brg 等。

## 子域一览

| 子域 | 路径/代表模块 | 职责简述 |
|------|----------------|----------|
| Inp | Inp/ (AP_Cmd_*, AP_Parser_*, AP_Cmd_KW_Brg) | 各类 *CMD 解析（几何/材料/载荷/分析/输出/…）、关键字桥接 |
| Out | Out/ | 输出格式、后处理、可视化、调试 |
| Solv | Solv/ (AP_Job_Core, AP_App_*) | Job 核心、重启/输出/监控 |
| Ctx | Ctx/ | 命令/文件工具、Job 上下文、AP_Types |
| Flow | Flow/ | 数据流核心 |
| Brg | Brg/ | AP_Brg_L4、AP_Brg_L5 |

## 与 L5/L4 的接口

- **L6 调用 L5/L4**：仅通过 Brg；AP_Brg_L5（配置/状态/Job）、AP_Brg_L4（结果/输出）。
- **规范**：见 [`UFC_域级模块详细设计_功能模块清单_v1.0.md`](../../../docs/03_Domain_Pillars/UFC_域级模块详细设计_功能模块清单_v1.0.md) §六（L6_AP）、[`README.md`](README.md)。

---

## Comment and diagram standard (charter: English + Unicode + two diagrams)

- **In-code comments**: **English only**; no Chinese. Use **Unicode** for formula symbols (ε, σ, Kₑ, ∂N/∂ξ, etc.). See [UFC_流程图与注释规范_英文Unicode](../docs/UFC_流程图与注释规范_英文Unicode.md).
- **Core subroutines**: Each functional subfolder should have 1–2 core subroutines with a **logic-chain** or **computation-chain** flowchart; add the corresponding header comment block in the `.f90` file.
- **Logic chain** (Step/Inc/Iter): [logic_chain_step_inc_iter.mmd](../docs/diagrams/logic_chain_step_inc_iter.mmd).
- **Computation chain** (Gauss → Kₑ, Fₑ): [computation_chain_gauss_element.mmd](../docs/diagrams/computation_chain_gauss_element.mmd).
