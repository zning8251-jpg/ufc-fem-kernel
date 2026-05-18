# Abaqus U* 子程序 ↔ UFC 对齐表（自动生成）

生成：`python tools/build_usub_ufc_alignment_table.py`
数据源：`tools/gen_umat_adapter.py` → `ALL_SUBROUTINES`（27 条）。

## 列说明

| 列 | 含义 |
|---|------|
| abaqus_subroutine | Abaqus 用户子程序名 |
| generator_group | 生成器分组（material/element/…） |
| ufc_domain | 生成器中的域标签 |
| ufc_layer_hint | 建议 UFC 层（L4_PH / L5_RT …） |
| target_module / target_core_api | 生成器目标模块与核心 API 名 |
| legacy_adapter_path | 文档区 Legacy 适配器 f90 路径（若存在） |
| ufc_core_core_file | 在 `ufc_core` 中首次命中 `core_api` 定义的 .f90 |
| sio_five_param_example | 同域下五参 `(desc,state,algo,ctx,args)` 示例文件（启发式） |
| sio_bridge_note | 简短说明 |

## 表

| abaqus_subroutine | generator_group | ufc_domain | ufc_layer_hint | target_module | target_core_api | legacy_adapter_path | ufc_core_core_file | sio_five_param_example | sio_bridge_note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| UMAT | material | Material | L4_PH | PH_Mat_UMAT | PH_Mat_UMAT_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Material/UMAT_Adapter.f90 | (not found) | ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90 | core `PH_Mat_UMAT_API` not found in ufc_core; five-param example in `ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90` |
| VUMAT | material | Material | L4_PH | PH_Mat_VUMAT | PH_Mat_VUMAT_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Material/VUMAT_Adapter.f90 | (not found) | ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90 | core `PH_Mat_VUMAT_API` not found in ufc_core; five-param example in `ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90` |
| UMATHT | material | Material | L4_PH | PH_Mat_UMATHT | PH_Mat_UMATHT_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Material/UMATHT_Adapter.f90 | (not found) | ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90 | core `PH_Mat_UMATHT_API` not found in ufc_core; five-param example in `ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90` |
| CREEP | material | Material | L4_PH | PH_Mat_CREEP | PH_Mat_CREEP_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Material/CREEP_Adapter.f90 | (not found) | ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90 | core `PH_Mat_CREEP_API` not found in ufc_core; five-param example in `ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90` |
| UHARD | material | Material | L4_PH | PH_Mat_UHARD | PH_Mat_UHARD_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Material/UHARD_Adapter.f90 | (not found) | ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90 | core `PH_Mat_UHARD_API` not found in ufc_core; five-param example in `ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90` |
| UHYPER | material | Material | L4_PH | PH_Mat_UHYPER | PH_Mat_UHYPER_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Material/UHYPER_Adapter.f90 | (not found) | ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90 | core `PH_Mat_UHYPER_API` not found in ufc_core; five-param example in `ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90` |
| UMULLINS | material | Material | L4_PH | PH_Mat_UMULLINS | PH_Mat_UMULLINS_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Material/UMULLINS_Adapter.f90 | (not found) | ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90 | core `PH_Mat_UMULLINS_API` not found in ufc_core; five-param example in `ufc_core/L4_PH/Material/Plast/PH_Mat_DP_Proc.f90` |
| USDFLD | field | Field | L4_PH | PH_Field_USDFLD | PH_Field_USDFLD_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Field/USDFLD_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Field_USDFLD_API` / module `PH_Field_USDFLD` — planned (adapter generator); verify ufc_core implementation |
| SDVINI | field | Field | L4_PH | PH_Field_SDVINI | PH_Field_SDVINI_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Field/SDVINI_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Field_SDVINI_API` / module `PH_Field_SDVINI` — planned (adapter generator); verify ufc_core implementation |
| SIGINI | field | Field | L4_PH | PH_Field_SIGINI | PH_Field_SIGINI_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Field/SIGINI_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Field_SIGINI_API` / module `PH_Field_SIGINI` — planned (adapter generator); verify ufc_core implementation |
| UEL | element | Element | L4_PH | PH_Elem_UEL | PH_Elem_UEL_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Element/UEL_Adapter.f90 | (not found) | ufc_core/L4_PH/Element/PH_Elem_Nlgeom.f90 | core `PH_Elem_UEL_API` not found in ufc_core; five-param example in `ufc_core/L4_PH/Element/PH_Elem_Nlgeom.f90` |
| DLOAD | load | Load | L5_RT (LoadBC) / L3_MD | PH_Ldbc_DLOAD | PH_Ldbc_DLOAD_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Load/DLOAD_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Ldbc_DLOAD_API` / module `PH_Ldbc_DLOAD` — planned (adapter generator); verify ufc_core implementation |
| VDLOAD | load | Load | L5_RT (LoadBC) / L3_MD | PH_Ldbc_VDLOAD | PH_Ldbc_VDLOAD_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Load/VDLOAD_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Ldbc_VDLOAD_API` / module `PH_Ldbc_VDLOAD` — planned (adapter generator); verify ufc_core implementation |
| CLOAD | load | Load | L5_RT (LoadBC) / L3_MD | PH_Ldbc_CLOAD | PH_Ldbc_CLOAD_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Load/CLOAD_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Ldbc_CLOAD_API` / module `PH_Ldbc_CLOAD` — planned (adapter generator); verify ufc_core implementation |
| FILM | load | Load | L5_RT (LoadBC) / L3_MD | PH_Ldbc_FILM | PH_Ldbc_FILM_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Load/FILM_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Ldbc_FILM_API` / module `PH_Ldbc_FILM` — planned (adapter generator); verify ufc_core implementation |
| HETVAL | load | Load | L5_RT (LoadBC) / L3_MD | PH_Ldbc_HETVAL | PH_Ldbc_HETVAL_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Load/HETVAL_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Ldbc_HETVAL_API` / module `PH_Ldbc_HETVAL` — planned (adapter generator); verify ufc_core implementation |
| DISP | bc | BC | L5_RT (LoadBC) / L3_MD | PH_Ldbc_DISP | PH_Ldbc_DISP_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/BC/DISP_Adapter.f90 | (not found) | ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90 | core `PH_Ldbc_DISP_API` not found in ufc_core; five-param example in `ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90` |
| UTEMP | bc | BC | L5_RT (LoadBC) / L3_MD | PH_Ldbc_UTEMP | PH_Ldbc_UTEMP_API | (no Legacy_Adapters_Reference stub) | (not found) | ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90 | core `PH_Ldbc_UTEMP_API` not found in ufc_core; five-param example in `ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90` |
| UPSD | bc | BC | L5_RT (LoadBC) / L3_MD | PH_Ldbc_UPSD | PH_Ldbc_UPSD_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/BC/UPSD_Adapter.f90 | (not found) | ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90 | core `PH_Ldbc_UPSD_API` not found in ufc_core; five-param example in `ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90` |
| UINTER | contact | Contact | L4_PH | PH_Cont_UINTER | PH_Cont_UINTER_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Contact/UINTER_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Cont_UINTER_API` / module `PH_Cont_UINTER` — planned (adapter generator); verify ufc_core implementation |
| UFRIC | contact | Contact | L4_PH | PH_Cont_UFRIC | PH_Cont_UFRIC_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Contact/UFRIC_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Cont_UFRIC_API` / module `PH_Cont_UFRIC` — planned (adapter generator); verify ufc_core implementation |
| GAPCON | contact | Contact | L4_PH | PH_Cont_GAPCON | PH_Cont_GAPCON_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Contact/GAPCON_Adapter.f90 | (not found) | (no local five-param match) | core `PH_Cont_GAPCON_API` / module `PH_Cont_GAPCON` — planned (adapter generator); verify ufc_core implementation |
| MPC | constraint | Constraint | L5_RT / L3_MD | PH_Cons_MPC | PH_Cons_MPC_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Constraint/MPC_Adapter.f90 | (not found) | ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90 | core `PH_Cons_MPC_API` not found in ufc_core; five-param example in `ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90` |
| UMESHMOTION | constraint | Constraint | L5_RT / L3_MD | PH_Cons_UMESHMOTION | PH_Cons_UMESHMOTION_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Constraint/UMESHMOTION_Adapter.f90 | (not found) | ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90 | core `PH_Cons_UMESHMOTION_API` not found in ufc_core; five-param example in `ufc_core/L3_MD/Element/Elem/MD_Elem_Populate.f90` |
| UAMP | analysis | Analysis | L5_RT / L6_AP | PH_Amp_UAMP | PH_Amp_UAMP_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Analysis/UAMP_Adapter.f90 | (not found) | ufc_core/L6_AP/UI/AP_UI_Mgr.f90 | core `PH_Amp_UAMP_API` not found in ufc_core; five-param example in `ufc_core/L6_AP/UI/AP_UI_Mgr.f90` |
| UVARM | analysis | Output | L5_RT / L6_AP | RT_Output_UVARM | RT_Output_UVARM_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Analysis/UVARM_Adapter.f90 | (not found) | ufc_core/L6_AP/UI/AP_UI_Mgr.f90 | core `RT_Output_UVARM_API` not found in ufc_core; five-param example in `ufc_core/L6_AP/UI/AP_UI_Mgr.f90` |
| UEXTERNALDB | analysis | Analysis | L5_RT / L6_AP | RT_Analysis_UEXTERNALDB | RT_Analysis_UEXTERNALDB_API | docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/Analysis/UEXTERNALDB_Adapter.f90 | (not found) | ufc_core/L6_AP/UI/AP_UI_Mgr.f90 | core `RT_Analysis_UEXTERNALDB_API` not found in ufc_core; five-param example in `ufc_core/L6_AP/UI/AP_UI_Mgr.f90` |

## 说明

- **五参入口**：UFC 规范为 `(desc, state, algo, ctx, args)`；材料类 Abaqus 适配历史上常见 `(desc, ctx, state, algo, rt_ctx, pnewdt)` 等变体，见 `docs/.../UMAT_Adapter.f90` 注释与 `ufc-structured-io`。
- 未在 `ufc_core` 命中 `target_core_api` 的条目表示**生成器已登记、内核未落地或名称不同**，需人工核对。