# Design: p1-material-crystal-w2-multislip

> **Status**: **W2a LOCKED**（2026-05-19）— `props`/`statev` 与 **W2-REF-01** 已锁定。

## 1. 基线（W1b）

- 单系：\(\tau^\alpha = P^\alpha : \sigma\)，\(P^\alpha = \mathrm{sym}(s^\alpha \otimes m^\alpha)\)
- 屈服：\(|\tau^\alpha| \le \tau_c^\alpha\)，\(\tau_c^\alpha = \tau_{c0}^\alpha + \sum_\beta h_{\alpha\beta} \gamma^\beta\)
- `statev(1)` = \(\gamma\)（W1b）；`statev(2:7)` = \(\varepsilon_p\)

## 2. W2a 目标（建议首 PR）

**固定 N=2 滑移系**，率无关返回映射（逐系或耦合 Newton）。

### 2.1 `props[]`（**LOCKED**）

| Index | 内容 |
|-------|------|
| 1 | `E` |
| 2 | `nu` |
| 3 | `tau_c0`（两系共用初始 CRSS） |
| 4 | `H11` |
| 5–7 | 系1 `s` |
| 8–10 | 系1 `m` |
| 11–13 | 系2 `s` |
| 14–16 | 系2 `m` |
| 17 | `H12` |
| 18 | `H21` |
| 19 | `H22` |

`nprops_min`（W2a）= **19**；`nprops < 19` → **W1b** 路径。

### 2.2 `statev`（**LOCKED**）

| Index | 内容 |
|-------|------|
| 1–2 | \(\gamma^{(1)}, \gamma^{(2)}\) |
| 3–8 | \(\varepsilon_p\) Voigt 6 |
| 9+ | 预留 W2b / 背应力 |

`nstatev_min` = **8**（W2a）；W1b 仍为 **7**（`statev(1)` + `statev(2:7)`）。

### 2.3 算法要点

1. 弹性试应力 \(\sigma^{tr}\)（同 W1b）。  
2. 对各系 \(\alpha\)：\(\tau^{tr}_\alpha = P^\alpha : \sigma^{tr}\)。  
3. 主动系集合：\(f_\alpha = |\tau^{tr}_\alpha| - \tau^\alpha_{c}(\gamma)\)。  
4. **耦合返回**：求 \(\Delta\gamma^\alpha\) 满足一致性（参考 Asaro / Simo 单晶盒，W2a 可用顺序或 2×2 牛顿）。  
5. \(\varepsilon_p \leftarrow \varepsilon_p + \sum_\alpha \Delta\gamma^\alpha \,\mathrm{sign}(\tau_\alpha)\, P^\alpha\)。  
6. 一致切线：W2a PR 输出 **`ddsdde = D_el`**（弹性近似）；塑性一致切线 → 后续 PR。

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

## 6. 参考算例 W2-REF-01（回归锁定）

单点、率无关、**单增量**、仅系1屈服（系2 \(\tau^{tr}=0\)）。

| 项 | 值 |
|----|-----|
| `E`, `nu` | `200e3`, `0.3` |
| `tau_c0`, `H11`, `H22`, `H12`, `H21` | `50`, `1000`, `1000`, `0`, `0` |
| 系1 `s`, `m` | `[0,0,1]`, `[1,0,0]` |
| 系2 `s`, `m` | `[0,1,0]`, `[0,0,1]` |
| `dstran` | `[0,0,0,0, 0.004, 0]`（Voigt 第5分量 \(\varepsilon_{13}\)） |
| 初值 | `stress=0`, `statev=0`, `ntens=6` |

**预期（容差 \(10^{-6}\) 相对量纲）**：

| 量 | 值 |
|----|-----|
| \(\tau^{tr}_1\) | `307.692308` |
| \(\tau^{tr}_2\) | `0` |
| \(\gamma^{(1)}\)（一步后） | `0.003307009` |
| \(\gamma^{(2)}\) | `0` |
| \(\sigma_{13}\)（Voigt 5，一步后） | `53.307009`（\(|\tau_1|=\tau_c0+H_{11}\gamma^{(1)}\)） |
| \(|\tau_1|\)（一步后） | `53.307009` |
| `status` | `IF_STATUS_OK` |

双系同时激活路径见 tasks §3.2（后续 harness）。
