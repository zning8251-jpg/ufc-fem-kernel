# UFC Rules Index

UFC 仓库专属规则集。每条规则对应一个 `.mdc` 文件（含 frontmatter 描述和 globs）。

## 规则清单

| 文件 | 描述 | 触发范围 |
|------|------|----------|
| `ufc-arch-guardian.mdc` | 架构守卫（层间 USE、全局容器禁止） | `ufc_core/**/*.f90` |
| `ufc-constraint-domain.mdc` | 约束域设计规范 | `ufc_core/**/Constraint/` |
| `ufc-coupling-domain.mdc` | 耦合域设计规范 | `ufc_core/**/Coupling/` |
| `ufc-directory-layout.mdc` | 仓库根目录分区 | `UFC/**` |
| `ufc-fortran-syntax.mdc` | Fortran 90/2003 语法约束 | `UFC/**/*.f90` |
| `ufc-naming.mdc` | 六层架构命名规范 | `UFC/**/*.f90` |

## 补充参考

- `ufc_linter.md` — arch_guardian.py 的完整规则集参考（HOT/WB/DEP/DATA/INTF/MAT/NAME/MOD/CHAIN/GLB/T4/IDX/SYN/COMM），存放于 `.qoder/rules/ufc_linter.md`
- `UFC/AGENTS.md` — 仓库级 Agent 指令（含规则优先级）
- `UFC/docs/` — 架构 SSOT 和开发者指南

## 规则优先级

当同一约束在多个位置出现时，优先级：`UFC/rules/` > `.cursor/rules/` > `.qoder/rules/`。具体规则以最新版本号为准。
