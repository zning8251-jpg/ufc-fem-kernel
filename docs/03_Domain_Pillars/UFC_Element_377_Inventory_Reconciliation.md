# UFC Element 377 Inventory Reconciliation

> Status: ACTIVE  
> Date: 2026-04-27  
> Scope: `UFC/ufc_core/L4_PH/Element/` element inventory, registry coverage, and material-route closure status.

## 1. Verdict

当前不能判定“12 主族、245 种、含变体 377 种单元类型”已经全部完成逐项改造。

已完成的是材料 route 架构层面的族级覆盖：连续体、壳/膜、梁、桁架、管、弹簧、阻尼、质量、热、声学、孔隙、界面、无限元等均已建立对应 helper 或 family wrapper；`Rigid/RotaryInertia` 已明确为非材料本构路径。

尚未完成的是 377 个目标单元的逐项 inventory 与逐项验收：当前仓库没有 377 项逐条权威目标清单，`PH_Elem_Reg.f90` 当前实际注册 225 项，距离 PPLAN 中的 377 变体目标仍有 152 项差额；仓库源码可发现的未注册候选已处理完，剩余均为等待权威名称导入的 accounting slots。

本报告已配套生成可重复执行的 inventory 工具与三份对账产物：

| Artifact | Purpose |
|----------|---------|
| `tools/element_inventory_audit.py` | 从 registry、Element 源码与 closure test 自动刷新对账矩阵 |
| `docs/ElementInventory/element_target_377.csv` | 377 行 accounting target；当前 225 行来自 registry，0 行为仓库可发现但未注册候选，152 行仍为 `UNRESOLVED_TARGET_SLOT_*` |
| `docs/ElementInventory/element_registry_route_crosswalk.csv` | 逐项标注 `REGISTERED/UNREGISTERED_DISCOVERED/UNREGISTERED_TARGET_GAP`、registry action 与 route/test/module 状态 |
| `docs/ElementInventory/element_inventory_summary.md` | 机器生成的统计摘要 |
| `docs/ElementInventory/element_registry_backlog.md` | 从 crosswalk 生成的 registry 补表/复核 backlog |

## 2. Evidence

| Source | Evidence | Meaning |
|--------|----------|---------|
| `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md` | “12大族245种单元(含变体377)” and “注册表(约800行, 377种单元)” | 这是目标口径，但不是逐项清单 |
| `ufc_core/L4_PH/Element/PH_Elem_Reg.f90` | 225 calls to `PH_Elem_Reg_Add` | 当前 L4 registry 实装基线为 225 项 |
| `ufc_core/L4_PH/Element/` | 203 `.f90` files | 源文件数不能等同于 377 单元类型 |
| `ufc_core/L4_PH/Element/CONTRACT.md` | Route helper/family wrapper coverage | 族级 material-route 已闭环，但不代表每个变体热路径已接线 |
| `docs/ElementInventory/element_registry_route_crosswalk.csv` | 377 target accounting rows | 当前已有逐项可刷新对账矩阵，仓库源码可发现候选已清零，152 个目标槽位仍需权威清单补名 |

## 3. Registered Inventory Snapshot

The table below is based on the current `PH_Elem_Reg_InitAll` registration calls.

| Bucket in current registry | Registered count | Material-route status | Notes |
|----------------------------|------------------|-----------------------|-------|
| 3D continuum `C3D*` | 36 | PARTIAL | Main solid and thermo/pore variants have helper coverage, but some registered variants are base/family semantics, not independent routed hot paths |
| Plane strain `CPE*` / `CPEG*` | 21 | PARTIAL | CPE route helpers exist; only representative structured hot paths are fully connected |
| Plane stress `CPS*` | 14 | PARTIAL | CPS route helpers exist; variant-level structured wiring remains incomplete |
| Axisymmetric `CAX*` | 16 | PARTIAL | Axisymmetric helper exists; variant-level structured wiring remains incomplete |
| Shell `S*` / `SC*` / `SAX*` | 21 | PARTIAL | Membrane and thermal subpaths are covered; full bending/shear/layered shell material closure remains separate |
| Beam `B*` | 18 | FAMILY_ROUTE | `E/nu` route exists at family wrapper; per-topology bending/shear/section resultants are not individually migrated |
| Truss `T*` | 10 | PARTIAL | `T2D2/T3D2/T3D3` routed; hybrid/thermal variants remain to be checked one by one |
| Membrane `M*` / `MAX*` | 13 | PARTIAL | `M3D9R` and shell membrane subpaths covered; registered `M*` variants need explicit route audit |
| Heat transfer `DC*` | 12 | FAMILY_ROUTE | Thermal scalar route exists for DS/S4T/S8RT paths, but registered `DC*` variants need dedicated audit |
| Acoustic `AC*` / `ACAX*` | 19 | FAMILY_ROUTE | Acoustic fluid route exists at family wrapper; per-topology hot path wiring remains incomplete |
| Cohesive `COH*` | 8 | FAMILY_ROUTE | Interface-law route exists at family wrapper; per-topology damage/degradation wiring remains incomplete |
| Rigid `R*` | 4 | NON_MATERIAL | Registry classified under Mass/Inertia/Rigid; no material route by design |
| Connector/Spring/Dashpot/Mass/RotaryI | 9 | MIXED | Spring/Dashpot/Mass routed; Connector and RotaryI remain non-material or pending dedicated path |
| Standalone porous `P*SAT/RCH` | 8 | FAMILY_ROUTE | Two-phase parameter route exists; saturated Biot and coupling remain facade/element-owned |
| **Total registered** | **225** | **NOT_FULL_377** | Current registry does not match 377 target |

## 3.1 Generated Route Status Summary

This section is generated from the current audit outputs and should be refreshed by rerunning `python tools/element_inventory_audit.py`.

| Route status | Count | Meaning |
|--------------|------:|---------|
| `ROUTED_PER_ELEMENT` | 64 | Exact routed wrapper or exact closure-test signal exists |
| `FAMILY_ROUTE` | 96 | Family/base route exists, but row-level hot path is not fully audited |
| `PARTIAL` | 46 | Family helper exists; row-level wrapper/test is incomplete |
| `NOT_ROUTED` | 12 | Registered/discovered row lacks audited material-route wrapper |
| `NON_MATERIAL` | 7 | Valid closure by constraint/inertia/metadata path |
| `UNREGISTERED_TARGET_GAP` | 152 | Target accounting slot still has no concrete candidate name |

## 3.2 Registry Backlog Summary

The generated backlog now separates the remaining work queues after the high-confidence and review candidates were processed:

| Queue | Count | Next action |
|-------|------:|-------------|
| `ADD_REGISTRY_ROW` discovered candidates | 0 | High-confidence batch has been registered |
| `REVIEW_ADD_OR_ALIAS` discovered candidates | 0 | Pore-pressure 2D/axisym variants and `C3D8PT` registered; Beam special implementation files excluded from target discovery |
| `REVIEW_DEFER_OR_NON_UFC_SCOPE` discovered candidates | 0 | `MASS2` treated as non-target/internal mass implementation candidate |
| Registered `NOT_ROUTED` rows | 12 | Audit `DC*` thermal transfer rows against scalar conductivity route or mark as non-material thermal path |
| Registered `PARTIAL` rows | 46 | Promote row-level wrappers/tests or explicitly keep family/base route semantics |

## 4. Coverage Labels

| Label | Meaning |
|-------|---------|
| `ROUTED_PER_ELEMENT` | Specific element module has a routed wrapper and focused closure test |
| `FAMILY_ROUTE` | Family-level route helper/wrapper exists, but per-element topology hot path is not fully audited |
| `PARTIAL` | Some topologies/variants are routed, others need explicit audit |
| `NON_MATERIAL` | Element does not own material constitutive route; handled by constraint/inertia/assembly metadata |
| `UNREGISTERED_TARGET_GAP` | Expected by target count but no row exists in current registry |

## 5. Reconciliation Gaps

| Gap | Impact | Required closure |
|-----|--------|------------------|
| No explicit 377 target list | Cannot prove 377-by-377 completion | Create canonical target list with `target_name`, `main_family`, `variant_kind`, `source_manual`, and `expected_registry_name` |
| Registry has 225 rows | 152 target variants are not represented in L4 registry; no repo-discovered candidate names remain outside registry | Import authoritative target names before adding more invented rows |
| Many rows are family/base semantics | Route helper coverage can be mistaken for per-element completion | Add row-level status: `registered`, `has_module`, `has_route_wrapper`, `has_structured_hot_path`, `has_test` |
| `PH_ELEM_FAMILY_OTHER` still used widely | 12主族 statistics are blurred | Map `OTHER` rows into true 12-family buckets or document why they remain other |
| Non-material paths mixed with material paths | Rigid/RotaryI can be miscounted as failed material route | Keep `NON_MATERIAL` as explicit closure state |

## 6. Next Closure Batches

1. **Inventory generator**: DONE. `tools/element_inventory_audit.py` extracts current registry rows from `PH_Elem_Reg.f90`, route wrappers from `Element/**/*.f90`, and produces CSV/Markdown matrices.
2. **Canonical target list**: SEEDED. `docs/ElementInventory/element_target_377.csv` has 377 accounting rows; 225 rows are registered and 152 `UNRESOLVED_TARGET_SLOT_*` rows must be replaced by authoritative element names before final acceptance.
3. **Registry completion**: PAUSED ON SOURCE OF TRUTH. Repo-discovered candidates are processed; compare authoritative target names to the remaining unresolved rows before adding more registry entries.
4. **Route completion**: NEXT. For every registered row, use `docs/ElementInventory/element_registry_route_crosswalk.csv` to drive `ROUTED_PER_ELEMENT`, `FAMILY_ROUTE`, `PARTIAL`, `NON_MATERIAL`, or `NOT_ROUTED` closure.
5. **Test completion**: NEXT. Extend `TEST_Material_L3_L4_Closure.f90` or split family closure tests so every `ROUTED_PER_ELEMENT` row has an exact helper-level assertion, and every `FAMILY_ROUTE` row has explicit family acceptance.

## 7. Current Answer to Completion Question

| Question | Answer |
|----------|--------|
| Are 12 main families directionally covered? | Yes, at material-route architecture level |
| Is the material route architecture basically closed? | Yes, for family-level route shapes |
| Are all 245 canonical element types complete? | Not proven |
| Are all 377 variants complete? | No |
| Is current L4 registry at 377 rows? | No, it has 225 rows |
| Can we return to Material domain plan without this caveat? | Yes, with the caveat carried forward as an Element inventory P0 source-of-truth task |

