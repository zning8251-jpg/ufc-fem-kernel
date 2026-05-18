# {{Abbr}}_Output_CONTRACT.md

<!-- 域间数据合同：{{DOMAIN_NAME}} → Output -->

**版本**：v1.0
**状态**：草稿

---

## 一、合同概述

本合同定义 `{{DOMAIN_NAME}}` 域向 `Output` 域的结果传递规范。

---

## 二、输出数据

### 2.1 场变量输出

| 变量名 | 维度 | 说明 |
|--------|------|------|
| `output_stress` | (nElem, nIP, 6) | 应力张量 |
| `output_strain` | (nElem, nIP, 6) | 应变张量 |
| `output_energy` | (nElem, nIP) | 能量密度 |

### 2.2 历史变量

| 变量名 | 说明 |
|--------|------|
| `history_state` | 状态变量数组 |
| `accumulated_damage` | 累积损伤 |

---

## 三、接口规范

```fortran
! 输出结果写入
SUBROUTINE {{Abbr}}_Output_Write(elem_id, output_data, err)
    INTEGER, INTENT(IN) :: elem_id
    REAL, INTENT(IN) :: output_data(*)
    INTEGER, INTENT(OUT) :: err
END SUBROUTINE
```

---

*最后更新: 2026-04-16*