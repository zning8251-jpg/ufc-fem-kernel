# Design: p1-material-plast-name-debt

> **Status**: DRAFT

## 1. 基线

| 指标 | 值 |
|------|-----|
| 命令 | `python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast` |
| P0/P1 | 0 |
| P2 | **17**（NAME-001 为主 + 1× CHAIN-001） |

## 2. 命名规则（Guardian NAME-001）

公开过程动词段应以 **Compute / Assemble / Apply / Get / Set / Init / Update / …** 开头。

**策略**：

| 存量模式 | 建议处理 |
|----------|----------|
| `PH_J2_TrialStress` | → `PH_J2_ComputeTrialStress` 或保留 + `DEPRECATED` 别名一层 |
| `PH_Mat_PLM_J2_*` | → `PH_Mat_Compute_PLM_J2_*` 或保留 PLM 为族前缀备案 |
| `PH_Mat_Hill_Calc_Stress` | → `PH_Mat_Hill_ComputeStress`（与 Barlat 对齐） |

**原则**：优先 **新增规范名 + 旧名 interface 转发** 若符号跨模块 PUBLIC；内部过程可直改。

## 3. 范围边界

| 包含 | 排除 |
|------|------|
| `ufc_core/L4_PH/Material/Plast/*.f90` | `Plast/` 外 USE 方（单独列迁移表） |
| CHAIN-001 同文件顺带 | 算法重构 |

## 4. 验收

```text
guardian Plast → P2=0（或仅剩备案例外清单）
naming touched files → OK
```

## 5. PR 切分建议

| PR | 范围 |
|----|------|
| A | `PH_Mat_Plast_J2_Iso_Core` + `PH_Mat_Plast_J2_UMAT_Core` |
| B | `PH_Mat_Plast_Hill_Core` + `PH_Mat_Plast_Barlat_*` |
| C | `PH_Mat_Plast_Core` / `Eval` / 其余 |
