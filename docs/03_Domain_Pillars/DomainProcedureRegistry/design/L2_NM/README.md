# L2_NM — 设计意图目录（入口）

## 与源码的对应

| 子域（源码路径） | 合同（若存在） | 建议 `INTENT.md` 路径 |
|------------------|----------------|------------------------|
| `L2_NM/Base/` | `ufc_core/L2_NM/Base/CONTRACT.md` | `design/L2_NM/Base/INTENT.md` |
| `L2_NM/Bridge/` | — | `design/L2_NM/Bridge/INTENT.md` |
| `L2_NM/Matrix/` | `ufc_core/L2_NM/Matrix/CONTRACT.md` | `design/L2_NM/Matrix/INTENT.md` |
| `L2_NM/Solver/` | `ufc_core/L2_NM/Solver/CONTRACT.md` 等 | `design/L2_NM/Solver/INTENT.md`（可按 LinSolv/NonlinSolv 再拆） |
| `L2_NM/TimeInt/` | `ufc_core/L2_NM/TimeInt/CONTRACT.md` | `design/L2_NM/TimeInt/INTENT.md` |
| `L2_NM/ExternalLibs/` | `CONTRACT.md` | **不**在此树建 `INTENT` 细表；见 [L2_SCOPE.md](../../L2_SCOPE.md) |

## 清单（现状）

跑 `python UFC/tools/domain_procedure_registry_scan.py` 后查看：

- [`../../generated/L2_NM/_LAYER_INDEX.md`](../../generated/L2_NM/_LAYER_INDEX.md)

**design ↔ generated 对齐**（示例已提供 [`Matrix/manifest.json`](Matrix/manifest.json)）：

```bash
python UFC/tools/domain_procedure_registry_align.py
```

初稿生成：`python UFC/tools/domain_procedure_registry_align.py --bootstrap UFC/docs/03_Domain_Pillars/DomainProcedureRegistry/design/L2_NM/Matrix/manifest.json`

漂移报告：[`../../../../../REPORTS/DESIGN_GENERATED_DRIFT.md`](../../../../../REPORTS/DESIGN_GENERATED_DRIFT.md)

## 排除说明

**`ExternalLibs/`** 不参与 `generated/` 逐文件扫描；L2 其余域 **全部参与**。
