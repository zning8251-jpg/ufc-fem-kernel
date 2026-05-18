# LoadBC 域级合同卡 (L4_PH)

**Layer**: L4_PH (物理计算层)  
**Domain**: LoadBC (载荷与边界条件) — 严格拆分为 Load + BC 两柱  
**Prefix**: `PH_Load_*`(纯载荷), `PH_BC_*`(纯边界条件)  
**Version**: v5.0  
**Created**: 2026-05-08  
**Status**: ACTIVE

---

## 1. 域职责定义

### 核心职责
- **定位**: L4_PH 层 Load/BC 域，载荷与边界条件的 PH 侧表示与数值准备
- **职责**:
  - 在 Populate 后持有步内可用的载荷/BC 视图
  - 集中力组装 (CLOAD): F(dof) += f·A(t)
  - 分布力/面载/压力组装: ∫ N^T t dS（含外法向）
  - 体力组装 (Gravity): ∫ N^T b dΩ
  - Dirichlet BC 施加: u=ū(t) 经消元/大罚/拉氏乘子写入 K/R 或 CSR
  - 幅值因子求值: A(t) 查询
  - 地应力 (Geostatic) K₀ 特化算法

### 非职责
- 不做全局 CSR 的唯一权威实现（与 L5 `RT_Asm_*` / `NM_CSR` 协同）
- 不持久写回 L3（回写仅 L5 白名单）
- 不解析 INP 载荷卡（L3 负责）
- 不做全局求解（最终方程形态以 L5 为准）

---

## 2. 文件布局（Load / BC 两柱）

### 2.1 Load 柱 — `PH_Load_*`

| 文件 | MODULE | 角色 | 说明 |
|------|--------|------|------|
| `PH_Load_Def.f90` | `PH_Load_Def` | `_Def` | 载荷 TYPE 定义、_Arg、控制器 |
| `PH_Load_Core.f90` | `PH_Load_Core` | `_Core` | 载荷计算内核(集中/分布/压力/体力/重力/热/Geostatic K₀) |
| `PH_Load_Aux_Def.f90` | `PH_Load_Aux_Def` | `Aux_Def` | 步级载荷施加算法控制 `PH_Load_Stp_Ctl_Algo` |
| `PH_Load_NestedToFlat.f90` | `PH_Load_NestedToFlat` | `_Proc` | Load FlattenAll 投影(含幅值插值) |
| `PH_Load_Mgr.f90` | `PH_Load_Mgr` | `_Mgr` | 载荷管理器 |

### 2.2 BC 柱 — `PH_BC_*`

| 文件 | MODULE | 角色 | 说明 |
|------|--------|------|------|
| `PH_BC_Def.f90` | `PH_BC_Def` | `_Def` | BC TYPE 定义、控制器、Cache |
| `PH_BC_Core.f90` | `PH_BC_Core` | `_Core` | BC 计算内核(Dirichlet 施加 CSR/密排) |
| `PH_BC_Aux_Def.f90` | `PH_BC_Aux_Def` | `Aux_Def` | 步级 BC 施加算法控制 `PH_BC_Stp_Ctl_Algo` |
| `PH_BC_NestedToFlat.f90` | `PH_BC_NestedToFlat` | `_Proc` | BC FlattenAll 投影 |
| `PH_BC_FlatToNested.f90` | `PH_BC_FlatToNested` | `_Proc` | BC WriteBack(白名单控制, Load 不可写) |
| `PH_BC_Brg.f90` | `PH_BC_Brg` | `_Brg` | BC 桥接 |
| `PH_BC_Mgr.f90` | `PH_BC` | `_Mgr` | BC 管理器 |

---

## 3. 对外接口（公开 API）

## 4. 废弃文件（DEPRECATED，保留向后兼容）

| 文件 | 替代 |
|------|------|
| `PH_LoadBC_Def.f90` | `PH_Load_Def.f90` + `PH_BC_Def.f90` |
| `PH_LoadBC_Core.f90` | `PH_Load_Core.f90` + `PH_BC_Core.f90` |
| `PH_LoadBC_Aux_Def.f90` | `PH_Load_Aux_Def.f90` + `PH_BC_Aux_Def.f90` |
| `PH_LoadBC_GeostaticAlgo.f90` | `PH_Load_Core.f90` |
| `PH_LoadBC_FlatToNested.f90` | `PH_BC_FlatToNested.f90` |
| `PH_LoadBC_NestedToFlat.f90` | `PH_Load_NestedToFlat.f90` + `PH_BC_NestedToFlat.f90` |
| `PH_Load_SurfaceTraction.f90` | `PH_Load_Core.f90` 集成 |
| `PH_Ldbc_*.f90` (系列) | Load/BC 纯柱对应文件 |

---

## 5. 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v5.0 | 2026-05-08 | 严格拆分为 Load/BC 两柱，Geostatic 合并入 Load_Core |
| v4.0 | 2026-04-27 | 初始化合同卡 |
