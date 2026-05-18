# {{Abbr}}_Section_CONTRACT.md

<!-- 域间数据合同：{{DOMAIN_NAME}} ↔ Section -->

**版本**：v1.0
**状态**：草稿

---

## 一、合同概述

本合同定义 `{{DOMAIN_NAME}}` 域与 `Section` 域之间的数据桥接规范。

---

## 二、数据流

### 2.1 {{DOMAIN_NAME}} → Section

| 数据字段 | 类型 | 说明 |
|----------|------|------|
| `section_id` | INTEGER | Section 标识符 |
| `section_props` | REAL array | Section 属性数组 |

### 2.2 Section → {{DOMAIN_NAME}}

| 数据字段 | 类型 | 说明 |
|----------|------|------|
| `integration_points` | INTEGER | 积分点数量 |
| `section_geometry` | TYPE | 截面几何参数 |

---

## 三、接口规范

```fortran
! {{DOMAIN_NAME}} → Section 数据传递
SUBROUTINE {{Abbr}}_Section_GetData(section_id, data, err)
    INTEGER, INTENT(IN) :: section_id
    REAL, INTENT(OUT) :: data(*)
    INTEGER, INTENT(OUT) :: err
END SUBROUTINE

! Section → {{DOMAIN_NAME}} 数据查询
SUBROUTINE Section_{{Abbr}}_Query(key, value, err)
    CHARACTER(*), INTENT(IN) :: key
    REAL, INTENT(OUT) :: value
    INTEGER, INTENT(OUT) :: err
END SUBROUTINE
```

---

*最后更新: 2026-04-16*