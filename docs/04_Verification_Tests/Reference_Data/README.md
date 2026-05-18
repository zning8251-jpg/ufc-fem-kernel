# UFC 元数据 CSV 文件

本目录用于代码生成辅助，包含从 L4 注册表提取的单元与材料元数据。

## 文件说明

| 文件 | 来源 | 用途 |
|------|------|------|
| `elem_meta.csv` | PH_Elem_Reg_InitAll | 单元类型、节点数、积分点数、自由度、族、base_elem_type |
| `mat_meta.csv` | PH_Mat_Reg_InitAll | 材料 ID、名称、属性数、状态变量数、实现类型 |
| `validation_cases.csv` | gen_validation_cases.py | 验证用例清单（单元×材料×优先级） |
| `validation_cases.md` | gen_validation_cases.py | 同上，Markdown 格式 |

## elem_meta.csv 列说明

| 列 | 类型 | 说明 |
|----|------|------|
| elem_type_id | int | MD_Elem_Core ELEM_* 常量值 |
| name | str | 单元名称（如 C3D8、CPE4） |
| n_nodes | int | 节点数 |
| n_ip | int | 积分点数 |
| n_dof | int | 自由度总数 |
| family_id | int | 1=C3D, 2=CPE, 3=CPS, 4=CAX, 5=S, 6=B, 7=T, 8=OTHER |
| base_elem_type | int | 0=自身为 base；否则为 shape 复用委托的 base |

## mat_meta.csv 列说明

| 列 | 类型 | 说明 |
|----|------|------|
| mat_id | int | 材料 ID（101–707） |
| name | str | 材料名称 |
| num_props | int | 属性数量；若模型含 **可选尾部 props**（如 201 第 5 项 `alpha_thermal`），本列为 **最大** props 条数，最少以 L3 `nprops_min` / `props_schema` 为准 |
| nStatev | int | 状态变量数量 |
| impl_type | str | real=真实 UMAT；placeholder=ElasticIso 占位 |

## 验证用例生成

```bash
python gen_validation_cases.py
```

生成 `validation_cases.csv` 与 `validation_cases.md`，包含高/中/低优先级 elem×mat 组合。

## 更新方式

当 `PH_Elem_Reg_InitAll` 或 `PH_Mat_Reg_InitAll` 变更时，需同步更新本目录 CSV 文件。可手动编辑或通过解析 Fortran 代码重新生成。验证用例可重新运行 `gen_validation_cases.py` 生成。

## 参考文档

- `UFC/ufc_core/L4_PH/Element/PH_Elem_Reg_Core.f90`
- `UFC/ufc_core/L4_PH/Material/PH_Mat_Reg_Core.f90`
- `UFC/ufc_core/L3_MD/Mesh/MD_Elem_Core.f90`（ELEM_* 常量）
- [`docs/05_Project_Planning/PPLAN/06_核心架构/UFC_UMAT_Props_Statev_Layout.md`](../../../05_Project_Planning/PPLAN/06_核心架构/UFC_UMAT_Props_Statev_Layout.md)（UEL/UMAT 槽位与参考数据口径）
