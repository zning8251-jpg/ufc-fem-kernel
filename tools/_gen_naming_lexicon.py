# One-off generator; run: python tools/_gen_naming_lexicon.py
import ast
import pathlib
import re

def main() -> None:
    root = pathlib.Path(__file__).resolve().parent
    text = (root / "check_naming_l3l4l5l6.py").read_text(encoding="utf-8")
    m = re.search(r"LONG_NAME_ABBREV = (\{[\s\S]*?\n\})\n\n+def get_layer", text)
    if not m:
        raise SystemExit("could not parse LONG_NAME_ABBREV")
    d: dict[str, str] = ast.literal_eval(m.group(1))
    extra = {
        "Properties": "props",
        "Property": "prop",
        "Configuration": "cfg",
        "Computation": "comp",
        "Calculation": "calc",
        "Information": "info",
        "Implementation": "impl",
        "Management": "mgr",
        "Performance": "perf",
        "Accumulation": "acc",
        "Interpolation": "interp",
        "Extrapolation": "extrap",
        "Distribution": "distrib",
        "Reconstruction": "Recon",
        "Documentation": "doc",
        "Characteristic": "Char_",
        "Coefficient": "coef",
        "Subsection": "subsect",
        "Initialisation": "Init",
    }
    d.update(extra)
    items = ",\n    ".join(f"{k!r}: {v!r}" for k, v in sorted(d.items()))
    content = f'''# -*- coding: utf-8 -*-
"""UFC 命名词表（单一真源）。

- ``LONG_NAME_ABBREV``：供 ``check_naming_l3l4l5l6.py`` 做模块名长词根检查；
  键为 PascalCase / 单词形态（与历史脚本一致）。
- ``verbose_token_hints()``：供 ``scan_verbose_identifiers.py`` 做局部标识符冗长词根扫描；
  返回 ``小写词根 -> 建议缩写``（消息用）。

新增/合并词根时**只改本文件**（或重新运行 ``_gen_naming_lexicon.py`` 从旧脚本抽取后再手工合并 extra）。
"""

from __future__ import annotations

from typing import Dict

LONG_NAME_ABBREV: Dict[str, str] = {{
    {items}
}}


def verbose_token_hints() -> Dict[str, str]:
    """Lowercase morpheme -> abbrev hint (scanner messages)."""
    return {{k.lower(): v for k, v in LONG_NAME_ABBREV.items()}}
'''
    (root / "naming_lexicon.py").write_text(content, encoding="utf-8")
    print("naming_lexicon.py written, entries:", len(d))


if __name__ == "__main__":
    main()
