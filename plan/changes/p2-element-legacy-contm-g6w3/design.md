# Design: p2-element-legacy-contm-g6w3

> **Status**: PLAN（未开工代码迁移）

## 1. 目标态

```text
L4_PH/Element/
  Legacy/
    LEGACY_CONTM_BOUNDARY.md
    PH_Elem_Contm_Brg.f90      ! MD 映射（已有）
    PH_ElemContm_Ops.f90       ! 实现体（迁入）
  PH_Elem_Contm.f90            ! 薄 facade（已有）
  PH_ElemKeDispatch.f90        ! 金线 Ke（无 Contm）
```

## 2. 风险

| 风险 | 缓解 |
|------|------|
| 构建系统按路径收集 `.f90` | 全库 grep `PH_ElemContm_Ops`；CI syntax |
| Ops 与 20+ `Solid*_Def` USE | 模块名不变则仅路径变更（W3a） |
| 去 `MD_*` 编译面大 | W3b 分族分批；保持 verifier 绿 |

## 3. 验收

- `verify_element_contm_legacy_boundary.py` 通过（allowlist 含 `Legacy/PH_ElemContm_Ops.f90`）
- 新脚本（W3c）：`tools/verify_l4_element_no_md_use.py` — 扫描 `L4_PH/Element/**/*.f90` 排除 `Legacy/`

## 4. 建议顺序

1. W3a 纯移动 + allowlist 更新（1 PR）
2. W3b 按子程序簇替换 `ElemType`→`UF_ElemType`（多 PR）
3. W3c guardian 门控 + 更新 `P2_ELEMENT_GAP_SNAPSHOT` G6→绿
