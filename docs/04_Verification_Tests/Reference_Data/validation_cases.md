# UFC 验证用例清单（自动生成）

> 来源: gen_validation_cases.py from elem_meta.csv, mat_meta.csv

## 高优先级

| 单元 | 材料 | 用例 |
|------|------|------|
| C3D8 | ElasticIso | Patch Test、单轴拉伸 |
| C3D8 | PlasticJ2 | 单轴拉伸、NAFEMS |
| C3D8 | MooneyRivlin | 超弹性 |
| CAX4 | ElasticIso | 轴对称 |
| CPE4 | ElasticIso | Patch Test、平面应变 |

## 中优先级

| 单元 | 材料 | 用例 |
|------|------|------|
| C3D8R | ElasticIso | 减缩积分 |
| CPE3 | ElasticIso | 常应变三角形 |
| M3D4 | ElasticIso | 膜单元 |
| S4R | ElasticIso | 壳单元 |

## 低优先级（力学单元 × 真实 UMAT）

共 1301 组。详见 validation_cases.csv。
