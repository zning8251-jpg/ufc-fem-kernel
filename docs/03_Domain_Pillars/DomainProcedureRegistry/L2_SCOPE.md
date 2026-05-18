# L2（`L2_NM`）扫描范围

## 纳入清单生成

除 **`ExternalLibs/`** 以外，`UFC/ufc_core/L2_NM/**/*.f90` **全部**进入 `domain_procedure_registry_scan.py` 的输出（与 L1/L3 等相同粒度）。

当前 L2 顶层子域（与源码目录一致，便于「逐个新目录」对齐）：

| 子域目录 | 说明 |
|----------|------|
| `Base/` | 基础工具、范数等 |
| `Bridge/` | 调度 / 桥接 |
| `Matrix/` | 矩阵、稀疏结构、**含** `NM_LAPACK_Brg` 等桥（仍在清单内；与 `ExternalLibs` 聚合目录区分） |
| `Solver/` | 线/非线性求解、预条件、耦合、收敛加速等 |
| `TimeInt/` | 时间积分、步长控制 |

各子域若已有 **`CONTRACT.md`**，以合同为语义真源；`generated/` 仅反映 **现存源码**。

---

## 排除：`ExternalLibs/`

路径段 **`ExternalLibs`** 下的 `.f90` **不生成** `generated/` 条目（LAPACK/BLAS/ITSOL/SparsePak/AMG 等 **第三方接口封装** 聚合区）。

- 域级说明仍可读：[`../../ufc_core/L2_NM/ExternalLibs/CONTRACT.md`](../../ufc_core/L2_NM/ExternalLibs/CONTRACT.md)  
- 若需 **符号级** 外部库清单，应走 **Vendor 文档 / 构建系统依赖表**，不重复塞进本 Registry。

---

## 与设计目录的关系

「完整设计意图」写在 **`design/`**（意图真源，逐步补全）；**`generated/`** 为源码快照。L2 残缺实现 → 以 `design/L2_NM/...` 为靶标 **逆向改造** 的流程见 [README.md — 双轨工作流](README.md#双轨工作流设计真源--源码快照--逆向对齐)。
