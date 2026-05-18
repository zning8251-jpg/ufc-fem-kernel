# 推演卡模板 (Derivation Card Template)

> **版本**: v1.0 | **日期**: 2026-04-26
>
> **用途**: 从域级 CONTRACT 系统推演出完整的过程清单和实现骨架。
>
> **关联**: [UFC_PhaseVerb_过程双轴体系.md](../PPLAN/06_核心架构/UFC_PhaseVerb_过程双轴体系.md) · [UFC_Procedure_Design_Template.md](UFC_Procedure_Design_Template.md) · [UFC_四型裁剪矩阵.md](../PPLAN/06_核心架构/UFC_四型裁剪矩阵.md)

---

## 使用方法

1. 复制本模板，替换 `{Layer}`, `{Domain}`, `{Feature}` 占位符
2. 按 A→B→C→D→E 顺序填写（每步依赖前一步的输出）
3. D 节过程清单确定后，即可生成 `_Def.f90` / `_Core.f90` / `_Brg.f90` 骨架

---

## [A] 意图推断

**域**：`{Layer}/{Domain}/{Feature}`

**CONTRACT 摘要**：
<!-- 从 CONTRACT.md 提取一句话职责描述 -->

**核心意图**（动词组）：
<!-- 从 CONTRACT 的"核心接口清单"提取主要动作 -->
- [ ] <!-- 例如：校验材料参数 -->
- [ ] <!-- 例如：计算应力应变关系 -->
- [ ] <!-- 例如：提供一致切线矩阵 -->

**Verb 族分布**：
<!-- 标记本域涉及的 Verb 族 -->
- [ ] Init
- [ ] Validate
- [ ] Compute
- [ ] Evolve
- [ ] Assemble
- [ ] Access
- [ ] Control
- [ ] Bridge

**Phase 分布**：
<!-- 标记本域过程覆盖的 Phase -->
- [ ] Config
- [ ] Populate
- [ ] Step
- [ ] Increment
- [ ] Iteration
- [ ] Local

---

## [B] 四型裁剪

| 四型 | 保留？ | 字段 | 理由 |
|------|-------|------|------|
| **Desc** | Y / N | <!-- 例如：E, nu, rho --> | <!-- 例如：材料参数，分析期不变 --> |
| **State** | Y / N | <!-- 例如：plastic_strain, sdv --> | <!-- 例如：塑性应变，跨步演化 --> |
| **Algo** | Y / N | <!-- 例如：integration_scheme --> | <!-- 例如：积分方案选择 --> |
| **Ctx** | Y / N | <!-- 例如：D_el, stress_trial --> | <!-- 例如：弹性矩阵临时缓存 --> |

**签名模式**：
<!-- 根据裁剪结果确定 -->
- [ ] `(desc, state, algo, ctx, status)` — 全四型
- [ ] `(desc, state, ctx, status)` — 无 Algo
- [ ] `(desc, ctx, status)` — 无 State/Algo
- [ ] `(desc, status)` — 纯 Desc

---

## [C] 算法锚定

**推演策略**：
<!-- 根据域类型选择 -->
- [ ] **计算域**：物理公式 → 有序步骤链 S1..Sn
- [ ] **编排域**：流程 → 状态机 (Begin → Loop{Check→Act} → End)
- [ ] **数据域**：数据生命周期 → CRUD 动词表

**理论/业务基础**：
<!-- 计算域填公式，编排域填状态转移，数据域填数据生命周期 -->

```
<!-- 例如：σ = D : ε (各向同性线弹性) -->
```

**算法步骤分解**：

| 步骤 | 名称 | Phase | Verb | 复杂度 | 说明 |
|------|------|-------|------|--------|------|
| S1 | <!-- ValidateProps --> | <!-- Config --> | <!-- Validate --> | <!-- O(1) --> | <!-- 参数合法性 --> |
| S2 | <!-- InitFromProps --> | <!-- Config --> | <!-- Init --> | <!-- O(1) --> | <!-- 派生量计算 --> |
| S3 | <!-- ... --> | | | | |

---

## [D] 过程绑定

将 C 节步骤绑定为具体 Fortran 子程序签名。

| 过程名 | Phase | Verb | 参数签名 | 热/冷 | 归属文件 |
|--------|-------|------|---------|-------|---------|
| <!-- {L}_{D}_{F}_Validate_Props --> | <!-- Config --> | <!-- Validate --> | <!-- (nprops, props, status) --> | <!-- COLD --> | <!-- _Core.f90 --> |
| <!-- {L}_{D}_{F}_Init_From_Props --> | <!-- Config --> | <!-- Init --> | <!-- (desc, nprops, props, status) --> | <!-- COLD --> | <!-- _Core.f90 --> |
| <!-- ... --> | | | | | |

**文件归属规则**：
- TYPE 定义 (Desc/State/Algo/Ctx) → `*_Def.f90`
- Init / Finalize / Compute / Evolve / Access / Validate → `*_Core.f90`
- Bridge / Populate / WriteBack → `*_Brg.f90`
- SIO 入口 (L5/Harness) → `*_Proc.f90`

---

## [E] 血肉清单

### 已有骨架

| 文件 | 行数 | 包含过程 |
|------|------|---------|
| <!-- {L}_{D}_{F}_Def.f90 --> | <!-- 50 --> | <!-- TYPE 定义 --> |
| <!-- {L}_{D}_{F}_Core.f90 --> | <!-- 100 --> | <!-- Init, Get_By_ID --> |

### 待补全

| 缺失过程 | Phase x Verb | 优先级 | 依赖 |
|---------|-------------|--------|------|
| <!-- Compute_Stress --> | <!-- Local x Compute --> | <!-- P0 --> | <!-- Build_D_el --> |
| <!-- ... --> | | | |

### 关键实现注意

<!-- 列出实现时需要注意的约束、依赖、性能要求等 -->
- <!-- 例如：热路径过程不得动态分配 -->
- <!-- 例如：须通过 Populate 预填缓存，不得在 Local 中读 L3 -->

---

## 附录：快速参考

### Phase 温度对照

| Phase | 温度 | 写入数据 |
|-------|------|---------|
| Config | 冷 | Desc |
| Populate | 冷 | L4/L5 槽位 |
| Step | 温 | State(步级) |
| Increment | 温热 | State(增量级) |
| Iteration | 热 | Ctx |
| Local | 最热 | Ctx + State(IP) |

### Verb 族速查

| 族 | 核心子动词 |
|----|-----------|
| Init | Init, Finalize, Reset |
| Validate | Validate, Guard |
| Compute | Compute, Build, Evaluate, Integrate, Solve |
| Evolve | Update, Commit, Revert, Advance |
| Assemble | Assemble, Reduce, Apply, Impose |
| Access | Get, Set, Add, Remove, Find, Count |
| Control | Begin, End, Route, Check, Loop |
| Bridge | Bridge, Populate, WriteBack, Map |
