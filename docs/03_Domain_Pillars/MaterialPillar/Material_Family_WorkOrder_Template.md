# 材料族工单模板（复制到 MR / Feature Manifest）

**用途**：按 `mat_family` 1→11 顺序开展时，每个族（或子族）MR 复制本模板并填实。真源：`UFC/ufc_core/L3_MD/Material/CONTRACT.md`、`MD_Ana_Comp.f90`（`GROUP_MAT_COMPAT`）。

---

## 元信息

| 字段 | 填写 |
|------|------|
| MR / 分支 | |
| `mat_family` | 1..11 |
| 主族名（CONTRACT） | Elastic / Plastic / … |
| 子族 / Abaqus `TYPE=` 或等价关键字 | |
| 手册锚点 | Abaqus Analysis Manual 章节 / 表 ID（或 `ANALYSIS_3_Materials_PartV_Manual.md` §） |

---

## 1. 手册 → 数据

| Abaqus 关键字 / 选项 | UFC L3 TYPE 或 `props` 槽 | 备注（互斥/默认） |
|----------------------|---------------------------|------------------|
| | | |

---

## 2. L3_MD（仅 Desc / Populate / 校验）

- [ ] 字段补全或映射表更新（**嵌套 ≤3**；主卡 `MD_Mat_Desc` 见 `Contract/MD_Mat_Def.f90`）
- [ ] 双写仅经 `MD_Mat_Desc_SyncDeprecatedFlat`（禁止新旁路）
- [ ] 新 `PUBLIC` 过程：`MD_Mat_*` / `MD_MAT_*`；**不**新增无前缀 `Mat*` 对外 API
- [ ] 精度：`USE IF_Prec_Core, ONLY: wp, i4`（禁止 `MD_Precision`）

**涉及路径（按族勾选）**：

- `Contract/MD_Mat_Def.f90` / 族 Contract 分文件（`MD_MatHYP_Def` 等）
- `Material/<族目录>/`
- `Bridge/`、`Shared/`（若仅冷路径）

---

## 3. L4_PH（槽与族核；非 L3）

- [ ] `PH_L4_Populate_Material` → `desc%props` 金线
- [ ] `PH_MAT_*` 枚举与 dispatch 一致
- [ ] 禁止在积分点热路径新增「扫 L3 全局库」依赖

**涉及路径**：`L4_PH/Material/<族>/`

---

## 4. L5_RT（薄路由）

- [ ] `RT_Mat_Brg_BuildTable_FromMaterial` 与 `elem_to_mat_map` 一致（见 L3 CONTRACT §L5 mat_pt）

---

## 5. 验证

- [ ] `python UFC/tools/material_pillar_audit.py`，diff 审查本族相关行
- [ ] 语法或闭包：`tests/TEST_Material_L3_L4_Closure.f90` / `TEST_Material_Pillar_Runner.f90`（若覆盖本族）
- [ ] 更新 `Material_Family_Rollout_Matrix.md` 对应族行（若 Level 推进）

---

## 6. PR 描述粘贴块（Definition of Done）

1. 手册锚点已填 §1。  
2. L3：子族互斥用 EXTENDS / `mat_model_id` / category；`SyncDeprecatedFlat` 无新旁路。  
3. L4：Populate 金线；`PH_MAT_*` 一致。  
4. L5：路由表与 `elem_to_mat_map` 无矛盾。  
5. `material_pillar_audit.py` 已跑并审查。  
