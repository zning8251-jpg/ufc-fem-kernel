# TASK_RUN — `w0-registry-refresh`

> **Phase B** · [`L3L4L5_MASTER_PLAN.md`](../../workflows/L3L4L5_MASTER_PLAN.md) §3  
> **规范**：[`UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md)

---

## Meta

| 字段 | 值 |
|------|-----|
| **task_id** | `w0-registry-refresh` |
| **pillar_id** | P1（基线扫描） |
| **wave** | Phase B / W0 刷新 |
| **change_id** | N/A |
| **created** | 2026-05-19 |

---

## Goal

刷新 P1 Material 三层 **Registry 快照** 与 **Plast 子树 Guardian 基线**，产出差距表供 [`p1-material-wave3-plast-loc`](../p1-material-wave3-plast-loc/TASK_RUN.md) 使用。

---

## References

| # | 路径 |
|---|------|
| 1 | [`plan/workflows/P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md) |
| 2 | `docs/03_Domain_Pillars/DomainProcedureRegistry/generated/_REGISTRY_STATS.md` |
| 3 | [`L3_L4_L5_W0_出口检查表.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_W0_出口检查表.md) |

---

## 七步工序（本任务仅 S2 + 摘录 S3）

| Step | state | 证据 |
|------|-------|------|
| S1 | skipped | W0 书面认定已存在（2026-04-30） |
| S2 | done | `domain_procedure_registry_scan.py` → 1067 md under `generated/`（2026-05-19） |
| S3 | done | `P1_MATERIAL_GAP_SNAPSHOT.md` + wave3 change 包 |
| S4–S7 | N/A | 无 ufc_core 代码变更 |

---

## Harness Log

```text
# 2026-05-19
python tools/domain_procedure_registry_scan.py
# → Wrote 1067 markdown files under docs/03_Domain_Pillars/DomainProcedureRegistry/generated

python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast --fail-on-p0
# → rc=1；P0 含 DEP-001@PH_Mat_Plast_J2_UMAT_Core.f90:52（L4 USE L5_RT）；详见 GAP_SNAPSHOT
```

---

## Next action

无（本任务 done）。接续 **[`p1-material-wave3-plast-loc`](../p1-material-wave3-plast-loc/TASK_RUN.md)** S1。

---

## Log

- 2026-05-19：Registry 全量再生；Plast Guardian 基线摘录入 `P1_MATERIAL_GAP_SNAPSHOT.md`；Phase B 刷新完成。
