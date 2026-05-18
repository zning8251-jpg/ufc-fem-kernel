---
name: ufc-naming-checker
description: "UFC 命名规范自动化检查技能。封装 harness/tools/code_development/naming_checker.py + scripts/check_naming_l3l4l5l6.py，支持模块前缀/后缀、TYPE 名前缀、过程名前缀、变量名大小写、禁止模式（TODO/FIXME/XXX）等检查，输出合规报告。触发：命名检查、naming-checker、ufc-naming、规范校验。"
---

# UFC Naming Checker 可执行技能

## 何时使用

| 场景 | 触发条件 |
|------|----------|
| 代码审查 | 用户说「检查命名规范」「naming-check」「命名合规」 |
| 新模块检查 | 用户说「检查这个模块是否符合命名规范」 |
| CI 门禁 | Git pre-commit 或 CI pipeline 调用 |
| 批量扫描 | 用户说「扫描 L4_PH 下所有文件命名」 |

---

## 第一步：执行检查

### 方式 A：命令行（直接调用 harness）

```powershell
# 检查整个 ufc_core
python UFC/ufc_harness/uhc.py code naming_checker

# 检查特定目录
python UFC/ufc_harness/uhc.py code naming_checker UFC/ufc_core/L4_PH

# 检查单个文件
python UFC/ufc_harness/uhc.py code naming_checker UFC/ufc_core/L4_PH/Material/Elastic/PH_Ela_Iso.f90
```

### 方式 B：Python API（集成到其他工具）

```python
from pathlib import Path
import sys
sys.path.insert(0, 'UFC/ufc_harness/tools/code_development')
from naming_checker import NamingChecker

checker = NamingChecker()
result = checker.check_directory(Path('UFC/ufc_core/L4_PH'))
print(checker.generate_report(result))
```

---

## 域名压缩（第二段）

- **真源**：`UFC/REPORTS/Domain_Compression_Canon.md`（`ufc_core` 各域 `DomainAbbr`，不含 `L2_NM/ExternalLibs`）。
- 模块名 `{层缀}_{DomainAbbr}_{...}` 的 **`DomainAbbr`** 以 Canon + 域 `CONTRACT.md` 为准。

## 第二步：检查规则速查

### N-01：模块名后缀规则

| 规则 | 合法后缀 | 非法示例 |
|------|----------|----------|
| 后缀必须为以下之一 | `_Core`, `_Type`, `_Types`, `_Intf`, `_API`, `_Bridge`, `_Wrapper`, `_Module`, `_Base`, `_Registry`, `_Lib`, `_Ids`, `_PropDB`, `_SurfBridge`, `_Sync`, `_Brg`, `_Parse` | `MD_Mat_MyModule`（无后缀） |

### N-02：TYPE 名前缀规则

| 规则 | 合法前缀 | 非法示例 |
|------|----------|----------|
| 必须以层前缀开头（大小写不敏感） | `MD_`, `PH_`, `RT_`, `NM_`, `IF_`, `AP_`, `UF_`, `KW_` | `Elastic_Props`（无前缀） |

### N-03：过程名前缀规则

| 规则 | 合法前缀/模式 | 非法示例 |
|------|--------------|----------|
| 必须以层前缀开头（大小写不敏感） | `MD_`, `PH_`, `RT_`, `NM_`, `IF_`, `AP_`, `UF_`, `KW_` | `ComputeStress()` |
| **TBP 实现体短名**（与宿主 `TYPE` 同模块、**单具体类型**时常用；绑定名与实现同名，无 `=>`） | `ValidateProps`, `InitFromProps`, `Init`, `Valid`, `Clear`, `Reset`, `Finalize`, `GetSummary`, `Cleanup`, `RegLayout`, …（见 `naming_checker._TBP_IMPL_SHORT_NAMES`） | 同模块多型：`=> {Desc\|State\|Algo\|Ctx}_{动词}`（如 `Desc_Init`），或 `Impl_Desc_Init`；避免冗长 `RT_*_` 前缀 |
| TYPE 绑定名 | `*Def_*`, `*_Def` | — |
| 特殊入口 | `parse_`, `valid_`, `validate_`, `to_`, `hash_` | — |

规范出处：`UFC/rules/ufc-naming.mdc`（TBP 节）、`UFC/REPORTS/UFC_L3L4L5_二元重构蓝图规范_v1.0.md` §6。材料 `*_Mat_*_Def.f90` 批量短实现名：`UFC/tools/tbp_mat_def_short_impl.py`。

### N-04：变量名大小写规则

| 规则 | 合法形式 | 非法示例 |
|------|----------|----------|
| 全小写 | `stress`, `disp`, `nnode` | `Strss`, `Disp` |
| 全大写（常量） | `RT_SOLVER_IMPLICIT`, `MAX_ITER` | — |
| PascalCase（仅限 legacy UMAT） | `ElasticProperties` | — |

### N-05：禁止模式

| 模式 | 说明 | 检查命令 |
|------|------|----------|
| `TODO` / `FIXME` / `XXX` | 未清理的标记注释 | `grep -n "TODO\|FIXME\|XXX" file.f90` |
| `write(*,*)` | 调试输出未移除 | `grep "write\s*(\*\s*,\s*\*)"` |
| `print *` | 调试 print 未移除 | `grep "print\s*\*"` |

---

## 第三步：解读报告

### 报告结构

```
===============================================================================
UFC 命名规范检查报告
===============================================================================
检查目录: UFC/ufc_core/L4_PH
总文件数: 45
合规文件: 38
问题文件: 7

问题详情:
----------------------------------------

[L4_PH/Material/Elastic/PH_Ela_Iso.f90]
  L12: 变量名应全小写
      REAL(wp) :: YoungModulus
```

### 退出码

| 退出码 | 含义 |
|--------|------|
| 0 | 全部合规 |
| 1 | 存在违规 |

---

## 第四步：常见违规修复

### 修复示例 1：变量名大小写

```fortran
! ❌ 违规
REAL(wp) :: YoungModulus, PoissonRatio

! ✅ 合规
REAL(wp) :: young_modulus, poisson_ratio
```

### 修复示例 2：TYPE 名前缀缺失

```fortran
! ❌ 违规
TYPE :: ElasticProperties
  REAL(wp) :: young_modulus
END TYPE

! ✅ 合规
TYPE :: PH_Ela_Iso_Desc
  REAL(wp) :: young_modulus
END TYPE
```

### 修复示例 3：模块名后缀缺失

```fortran
! ❌ 违规
MODULE PH_Ela_Iso

! ✅ 合规
MODULE PH_Ela_Iso_Impl
! 或
MODULE PH_Ela_Iso_Types
```

---

## 第五步：与 UFC 命名规范 v1.0 对齐

本技能规则与 [`UFC_命名规范_v3.0.md`](../../../05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md) 保持同步：

| 技能规则 | 规范章节 |
|----------|----------|
| 模块名后缀 | §5.2 B类—职责组件后缀 |
| TYPE 名前缀 | §2.1 层级前缀 |
| 变量名大小写 | §11.1 变量命名 |
| 禁止模式 | §12 编码规范 |

---

## 附：Harness 集成

### Pre-commit 集成

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: ufc-naming-checker
      name: UFC Naming Checker
      entry: python UFC/ufc_harness/uhc.py code naming_checker
      language: system
      files: \.f90$
```

### CI 流水线集成

```bash
# .github/workflows/fortran-ci.yml
- name: UFC Naming Check
  run: python UFC/ufc_harness/uhc.py code naming_checker
```

---

**技能版本**: v1.0 | **日期**: 2026-04-04
**依赖**: `UFC/ufc_harness/tools/code_development/naming_checker.py`
