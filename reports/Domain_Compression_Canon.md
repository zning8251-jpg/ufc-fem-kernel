# UFC Domain Compression Canon

**Report ID**: REP-DOMAIN-COMPRESSION-CANON  
**Version**: v1.1 | **Date**: 2026-05-08  
**Scope**: ufc_core except L2_NM/ExternalLibs. Authoritative DomainAbbr for Layer_DomainAbbr_Topic_Role.f90 pattern.

**P4 LoadBC note**: Pillar **`DomainAbbr` = `LoadBC`** (camel segment). Fortran identifiers may exceed v3 length hints where legacy stems (`PH_Ldbc_*`, `MD_LBC_*`) persist until rename slices.  
**Links**: REPORT_Naming_Unified_Spec.md Section 1; docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md Section 2.

## 0. Precedence

1. This table defines the normative token for new code and docs.  
2. Per-domain CONTRACT.md may refine sub-topic stems; must not collide with pillar tokens here.  
3. Legacy code keeps old stems until a rename slice.  
4. ExternalLibs is out of scope.

**Casing (R-10a)**: Domain segment uses PascalCase chunk: LoadBC, Cont, Elem (not LDBC, CONT).

## 1. Name template

```
{LayerPrefix}_{DomainAbbr}_{TopicOrFeature}[_{Role}].f90
```

| Part | Meaning | Example |
|------|---------|---------|
| LayerPrefix | IF_/NM_/MD_/PH_/RT_/AP_ | PH_ |
| DomainAbbr | Sections 2-8 below | Mat |
| TopicOrFeature | family / topic | Elas |
| Role | Def/Core/Brg/... | Core |

## 2. Full pillars P1-P6

| Pillar | DomainAbbr | L3 paths | L4 | L5 | Legacy stems |
|--------|------------|----------|----|----|--------------|
| Material | Mat | L3_MD/Material | L4_PH/Material | L5_RT/Material | - |
| Element | Elem | L3_MD/Element | L4_PH/Element | L5_RT/Element | - |
| Contact | Cont | L3_MD/Interaction | L4_PH/Contact | L5_RT/Contact | L3 folder Interaction; bridge token Int is NOT this pillar (Section 5) |
| LoadBC | LoadBC | L3_MD/Boundary, L3_MD/LoadBC | L4_PH/LoadBC | L5_RT/LoadBC | Load, BC, LBC are in-pillar splits; do not invent a fourth family |
| Output | Out | L3_MD/Output | L4_PH/Output | L5_RT/Output | - |
| WriteBack | WB | L3_MD/WriteBack | L4_PH/WriteBack | L5_RT/WriteBack | - |

## 3. Half pillars H1-H2

| Concept | DomainAbbr | Paths | Notes |
|---------|------------|-------|-------|
| Section | Sect | L3_MD/Section, L5_RT/Section | |
| Step | Step | L3_MD/Analysis/Step, L5_RT/StepDriver | |
| Solver (metadata/API) | Solv | L3_MD/Analysis/Solver, L5_RT/Solver, L2_NM/Solver | L2 kernel also Solv |
| Amplitude | Amp | L3_MD/Analysis/Amplitude | |
| Coupling | Cpl | L3_MD/Analysis/Coupling | |
| Analysis umbrella | Ana | L3_MD/Analysis top-level bridges | MD_Ana_*; not Cont |

## 4. L3_MD top-level (non-pillar folders)

| Folder | DomainAbbr |
|--------|------------|
| Assembly | Asm |
| Base | Base |
| Bridge | Brg |
| Constraint | Constr |
| Element/Mesh | Mesh (MD_Mesh_*; MD_DOF_* cluster) |
| Field | Field |
| KeyWord | KW |
| Model | Model (no new Mo; see Model_Domain_FourType_Procedure_Naming_Spec.md) |
| Part | Part |
| Contracts | (no MODULE) |

## 5. Bridge naming

| Pattern | DomainAbbr | Examples |
|---------|------------|----------|
| Generic bridge def | Brg | MD_Brg_Def, PH_Brg_Def |
| Target domain + Brg | per domain | MD_ContPH_Brg, MD_ElemPH_Brg |
| L3 interaction bridge (historical) | Int | MD_Int_Brg (not P3 Cont body) |
| Output / WB bridges | Out / WB | MD_Out_Brg, PH_WB_Brg |

## 6. L1_IF / L2_NM (exclude ExternalLibs)

### L1_IF

Base, Err, IO, Log, Mem, Mon, Prec, Reg (folder maps 1:1).

### L2_NM

| Folder | DomainAbbr | Notes |
|--------|------------|-------|
| Base | Base; BVH subfolder: BVH | NM_BVH_* |
| Bridge | Brg | |
| Matrix | Mtx | NM_LinAlg_* exists; prefer Mtx + topic for new code |
| Solver | Solv | |
| TimeInt | TimeInt | NM_TimeInt_* as one token |

## 7. L4_PH / L5_RT extras

| Folder | DomainAbbr |
|--------|------------|
| L4_PH/Field | Field |
| L5_RT/Logging | Log |
| L5_RT/Bridge | Brg |
| RT_Shared_* | Shared is topic segment, not a pillar |

## 8. L6_AP

Brg, Cfg, Inp, Job, Out, Reg, Solv, UI; root Base, SimData; prefer AP_Inp_* over AP_Input_* for new modules.

## 9. Migration notes vs old v3.0 table

- P3 pillar: Cont (not Int). Int = L3 bridge only.  
- P4 pillar doc token: LoadBC (not only LBC). BC / Load / LBC = legacy or split stems.  
- Model stays full word; ban new MD_Mo_*.

## 10. Doc sync checklist

- REPORT_Naming_Unified_Spec.md  
- docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md  
- UFC_L3L4L5_二元重构蓝图规范_v1.0.md  
- Master_Domain_Inventory_Index.md  
- .cursor/rules/ufc-naming.mdc  

END
