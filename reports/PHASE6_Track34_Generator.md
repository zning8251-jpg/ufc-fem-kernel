# Phase6 Track 3.4 — 单元 stem 生成器占位

- **脚本**：[`tools/gen_ph_element_stem_stub.py`](../tools/gen_ph_element_stem_stub.py)
- **用法**：`python tools/gen_ph_element_stem_stub.py --stem C3D8` 打印空 MODULE；`--out-dir build/gen_elem` 批量落盘；`--json stems.json` 接受 JSON 字符串数组。
- **后续**：与 §3.2 `RT_Asm_TripartiteKey` 的 `elem_stem_id` 枚举对齐，再由配置驱动 370+ 变体。
