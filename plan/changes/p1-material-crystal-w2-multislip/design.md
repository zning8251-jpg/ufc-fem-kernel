# Design: p1-material-crystal-w2-multislip

> **Status**: DRAFT（2026-05-19）— plan only；实施前确认算例与 `N_slip`。

## 1. 基线（W1b）

- 单系：\(\tau^\alpha = P^\alpha : \sigma\)，\(P^\alpha = \mathrm{sym}(s^\alpha \otimes m^\alpha)\)
- 屈服：\(|\tau^\alpha| \le \tau_c^\alpha\)，\(\tau_c^\alpha = \tau_{c0}^\alpha + \sum_\beta h_{\alpha\beta} \gamma^\beta\)
- `statev(1)` = \(\gamma\)（W1b）；`statev(2:7)` = \(\varepsilon_p\)

## 2. W2a 目标（建议首 PR）

**固定 N=2 滑移系**，率无关返回映射（逐系或耦合 Newton）。

### 2.1 `props[]`（草案）

| Index | 内容 |
|-------|------|
| 1–4 | 同 W1b：`E`, `nu`, `tau_c0^{(1)}`, `H_{11}` 或统一 `tau_c0` + 矩阵打包 |
| 5–10 | 系1：`s1,s2,s3`, `m1,m2,m3` |
| 11–16 | 系2：`s2`, `m2` |
| 17–20 | 潜硬化 `H_{12}, H_{21}, H_{22}`（对称化） |

> **简化选项**：`tau_c0` 两系共用 props(3)，`H` 为 2×2 对称存 props(17:19)；实施 PR 前用表格锁死索引。

`nprops_min`（W2a）≈ **19**（待算例锁定）。

### 2.2 `statev`（草案）

| Index | 内容 |
|-------|------|
| 1–2 | \(\gamma^{(1)}, \gamma^{(2)}\) |
| 3–8 | \(\varepsilon_p\) Voigt 6 |
| 9+ | 预留 W2b / 背应力 |

`nstatev_min` = **8**（W2a）。

### 2.3 算法要点

1. 弹性试应力 \(\sigma^{tr}\)（同 W1b）。  
2. 对各系 \(\alpha\)：\(\tau^{tr}_\alpha = P^\alpha : \sigma^{tr}\)。  
3. 主动系集合：\(f_\alpha = |\tau^{tr}_\alpha| - \tau^\alpha_{c}(\gamma)\)。  
4. **耦合返回**：求 \(\Delta\gamma^\alpha\) 满足一致性（参考 Asaro / Simo 单晶盒，W2a 可用顺序或 2×2 牛顿）。  
5. \(\varepsilon_p \leftarrow \varepsilon_p + \sum_\alpha \Delta\gamma^\alpha \,\mathrm{sign}(\tau_\alpha)\, P^\alpha\)。  
6. 一致切线：弹性 + 塑性修正（W2a 可先 **弹性切线** + 文档化，P1 门禁若要求再补）。

### 2.4 W1b 兼容

- `nprops` 仅含 W1b 长度（4–10）且仅启用系1 → **退化**为当前 W1b 行为。  
- 或 `props(0)` 魔数 `N_slip=1|2`（W2b）。

## 3. W2b（out of scope for W2a PR）

- 可配置 `N_slip` ≤ `N_max`（如 12）  
- FCC 典型 12 系模板辅助输入  
- 温度 / 率相关

## 4. Harness

```text
guardian PH_Mat_Plast_Crystal_Core.f90 --fail-on-p0
change-package validate --change-id p1-material-crystal-w2-multislip --strict
# 待增：最小双滑移单点驱动（若 harness 模式存在）
```

## 5. 风险

| 风险 | 缓解 |
|------|------|
| `props` 爆炸 | W2a 固定 N=2；W2b 再泛化 |
| 切线不完整 | 分 PR：先应力路径，后切线 |
| PLM `nstatev` 宿主不足 | 文档 + Registry `nstatev_min` |
