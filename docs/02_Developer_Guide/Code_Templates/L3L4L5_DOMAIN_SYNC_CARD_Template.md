# L3/L4/L5 Domain Sync Card Template

> 用途: 为跨 L3_MD / L4_PH / L5_RT 的域柱建立统一合同卡。  
> 使用位置: 域 `CONTRACT.md`、`docs/03_Domain_Pillars/DomainProcedureRegistry/design/<Layer>/<Domain>/INTENT.md` 或 PPLAN 域级落地文档。  
> 原则: L3 是数据真源；L4 是物理计算；L5 是运行调度。

---

## 1. 域柱摘要

| 项 | 内容 |
|----|------|
| 域柱名称 | `{{Domain}}` |
| 分类 | `全柱域 / 半柱域 / 单层域 / 桥接域` |
| L3 真源 | `{{L3 path / N/A}}` |
| L4 物理层 | `{{L4 path / N/A}}` |
| L5 调度层 | `{{L5 path / N/A}}` |
| 主链 | `{{INP -> L3 Desc -> L4 Populate -> L5 Runtime}}` |
| 禁止事项 | `{{例如: L4 热路径回读 L3 / L3 做数值计算 / L5 复制 Desc}}` |

---

## 2. 层级职责

| 层 | 职责 | 典型模块 | 生命周期 |
|----|------|----------|----------|
| L3_MD | `{{Desc / model truth / registry / parse map}}` | `{{MD_*_Def / Mgr / Map / Brg}}` | Model |
| L4_PH | `{{physical kernel / slot / local state}}` | `{{PH_*_Domain / Ops / Reg / Dsp}}` | Step |
| L5_RT | `{{driver / assembly / solver / writeback}}` | `{{RT_*_Proc / Solv / Asm / Wb}}` | Incr/Iter |

---

## 3. 四型归属

| DataKind | 归属层 | 热/冷 | 写入者 | 读取者 | 代表 TYPE |
|----------|--------|-------|--------|--------|-----------|
| Desc | `{{L3}}` | Cold | `{{Parser / domain Add}}` | `{{Populate / query}}` | `{{MD_*_Desc}}` |
| Ctx | `{{L4/L5}}` | Hot/Transient | `{{Populate / driver}}` | `{{kernel / assembly}}` | `{{PH_*_Ctx / RT_*_Ctx}}` |
| State | `{{L4/L5}}` | Hot | `{{kernel / solver}}` | `{{solver / writeback}}` | `{{PH_*_State / RT_*_State}}` |
| Algo | `{{L3/L4/L5}}` | Cold | `{{configuration}}` | `{{driver / kernel}}` | `{{*_Algo}}` |

---

## 4. 目标功能模块集合

| 层 | 文件 / MODULE | 后缀 | 角色 | 保留/新增/合并/删除 | 备注 |
|----|---------------|------|------|--------------------|------|
| L3 | `{{MD_*_Def}}` | `Def` | TYPE / constants | `{{保留}}` | |
| L3 | `{{MD_*_Mgr}}` | `Mgr` | domain container | `{{保留}}` | |
| L4 | `{{PH_*_Ops}}` | `Ops` | compute body | `{{保留}}` | |
| L5 | `{{RT_*_Proc}}` | `Proc` | SIO runtime process | `{{保留}}` | |

后缀选择必须来自 `UFC_数据四型×过程四型_主责正交矩阵.md` 的闭集；新建 MODULE 不使用 `_Desc/_Ctx/_State/_Algo` 文件后缀。

---

## 5. 过程步骤链

| Step | 时相 | 动作 | 输入 TYPE | 输出 TYPE | 对应过程 |
|------|------|------|-----------|-----------|----------|
| 1 | Parse / Build | `{{合法化 Desc}}` | `{{*_Arg}}` | `{{MD_*_Desc}}` | `{{...}}` |
| 2 | Populate | `{{L3 -> L4 slot/cache}}` | `{{MD_*_Desc}}` | `{{PH_*_Ctx/State}}` | `{{...}}` |
| 3 | Compute | `{{局部物理核}}` | `{{PH_*_Ctx/Algo}}` | `{{PH_*_State / Ke/Fe}}` | `{{...}}` |
| 4 | Reduce / Assemble | `{{全局归约}}` | `{{Ke/Fe/Fc}}` | `{{RT matrix/vector}}` | `{{...}}` |
| 5 | WriteBack | `{{白名单回写}}` | `{{RT state}}` | `{{L3 / Output}}` | `{{...}}` |

---

## 6. 跨层契约

| 边 | 形式 | 输入 | 输出 | 禁止 |
|----|------|------|------|------|
| L3 -> L4 | Populate / Brg | `{{MD Desc}}` | `{{PH slot/cache}}` | `{{热路径反复回读 L3}}` |
| L4 -> L5 | Compute result | `{{PH Ctx/State}}` | `{{Ke/Fe/Ctan/Fc}}` | `{{L5 调 L4 内部私有核}}` |
| L5 -> L3 | WriteBack | `{{RT result}}` | `{{白名单字段}}` | `{{任意写 L3 Desc}}` |

---

## 7. SIO 偏好

- 层间边界、L5 `_Proc`、Harness 消费接口优先 `*_Arg`。
- L3 小域不强制每个过程都套 `*_Arg`。
- 禁止仅承载 `status` 的薄 `Arg`。
- 合并 `*_Arg` 内字段用 `! [IN]` / `! [OUT]` / `! [INOUT]` 注释标明方向。

---

## 8. 验收

| Gate | 级别 | 检查 |
|------|------|------|
| L3 仅真源，不做物理计算 | 硬 | Contract + code review |
| L4 热路径零 L3 | 硬 | `USE MD_*` 审计 + 热路径审查 |
| L5 调度不复制 Desc 真源 | 硬 | runtime state review |
| 功能模块后缀闭集 | 硬 | naming checker / registry |
| registry 对账 | 软到硬 | `domain_procedure_registry_scan.py` + `align.py` |
| Fortran 语法 | 硬 | `gfortran -std=f2003 -ffree-line-length-none -fsyntax-only` |

