!===============================================================================
! MODULE: RT_Asm_Brg
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Brg
! BRIEF:  Bridge -- populate RT_Asm_Desc from L3 model data, build DOF maps;
!         per-element mat_pt_idx helper for PH_Element_Compute_Ke/Fe args;
!         UMAT-style RT_*_Bridge_Ctx：Apply* 先写 %stp/%lcl 真源，再 Sync_Deprecated_From_Aux 镜像平场
!===============================================================================
! 闭环（Populate → L5）— 与本仓库实际调用关系 **对齐**（ufc-layer-l3-l4-l5-pilot / H3）：
!   - **L3 装配体（实例/集合/面）** 经 **`MD_Assembly_SyncFromLegacy`**（`MD_Model_Brg` 金线
!     序）进入 `md_layer%assembly`；**不是** `L3_MD/Bridge/Bridge_L5/MD_AssemRT_Brg.f90`
!    （该文件仅 re-export `RT_Solv_Sparse` 的 Triplet/CSR，名易混）。
!   - **L4**：`PH_L4_Populate_*` 不写 Assembly 域容器；`RT_Asm_Brg_ElemMatPtIdx` 读 **L4 Element**
!     在 Populate 后写入的 **`elem_to_mat_map`**（Populate→组装循环）。
!   - **L5**：`g_ufc_global%rt_layer%assembly`（`RT_Assembly_Domain`）持 **CSR/热路径**；`l3_bounds` 在
!     **`MD_Model_Brg` + `SyncL3BoundsFromBridge`** 与 **`bridge%assembly_desc`** 对齐。`RT_Asm_Solv` 全局装配；
!     **`RT_Asm_Brg_FromL3Model`** 写 **`bridge%assembly_desc`**（金线），再同步到 **`assembly%l3_bounds`**。
!   - **推荐顺序**（与 solver 解耦）：L3 mesh/model 就绪 -> FromL3Model -> SyncL3BoundsFromBridge ->
!     （独立一步）BuildPattern / 全局装配。
!
! Partial Pillar: H3 Assembly (AUTHORITY types: RT_Asm_Def.f90)
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Asm_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Asm_Def, ONLY: RT_Asm_Desc, RT_Asm_State, RT_Asm_Algo, RT_Asm_Ctx
  USE RT_Brg_Def, ONLY: RT_Mat_Bridge_Ctx, RT_Elem_Bridge_Ctx, &
                        RT_Mat_Bridge_Sync_Aux_From_Deprecated, &
                        RT_Mat_Bridge_Sync_Deprecated_From_Aux, &
                        RT_Elem_Bridge_Sync_Aux_From_Deprecated, &
                        RT_Elem_Bridge_Sync_Deprecated_From_Aux
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Asm_Brg_FromL3Model
  PUBLIC :: RT_Asm_Brg_BuildElemDofMap
  PUBLIC :: RT_Asm_Brg_AllocGlobalSystem
  PUBLIC :: RT_Asm_Brg_FreeGlobalSystem
  !--- UMAT/UEL-style per-IP bridge: write deprecated flat fields then mirror %stp/%lcl ---
  PUBLIC :: RT_Asm_Brg_SyncMatBridgeMirror
  PUBLIC :: RT_Asm_Brg_SyncElemBridgeMirror
  PUBLIC :: RT_Asm_Brg_ApplyMatBridge_Flat_IP
  PUBLIC :: RT_Asm_Brg_ApplyElemBridge_Flat_IP
  PUBLIC :: RT_Asm_Brg_ElemMatPtIdx

CONTAINS

  !---------------------------------------------------------------------------
  ! RT_Asm_Brg_ElemMatPtIdx — L4 Populate 写入的 elem_to_mat_map -> mat_pt_idx
  ! Returns 0 if global/L4 element域未就绪或未分配 map 或 iElem 越界。
  !---------------------------------------------------------------------------
  INTEGER(i4) FUNCTION RT_Asm_Brg_ElemMatPtIdx(iElem) RESULT(midx)
    INTEGER(i4), INTENT(IN) :: iElem

    midx = 0_i4
    IF (.NOT. g_ufc_global%IsReady()) RETURN
    IF (.NOT. g_ufc_global%ph_layer%element%is_initialized) RETURN
    IF (.NOT. ALLOCATED(g_ufc_global%ph_layer%element%elem_to_mat_map)) RETURN
    IF (iElem < 1_i4) RETURN
    IF (iElem > SIZE(g_ufc_global%ph_layer%element%elem_to_mat_map)) RETURN
    midx = g_ufc_global%ph_layer%element%elem_to_mat_map(iElem)
  END FUNCTION RT_Asm_Brg_ElemMatPtIdx

  SUBROUTINE RT_Asm_Brg_SyncMatBridgeMirror(mat_brg)
    TYPE(RT_Mat_Bridge_Ctx), INTENT(INOUT) :: mat_brg
    CALL RT_Mat_Bridge_Sync_Aux_From_Deprecated(mat_brg)
  END SUBROUTINE RT_Asm_Brg_SyncMatBridgeMirror

  SUBROUTINE RT_Asm_Brg_SyncElemBridgeMirror(elem_brg)
    TYPE(RT_Elem_Bridge_Ctx), INTENT(INOUT) :: elem_brg
    CALL RT_Elem_Bridge_Sync_Aux_From_Deprecated(elem_brg)
  END SUBROUTINE RT_Asm_Brg_SyncElemBridgeMirror

  SUBROUTINE RT_Asm_Brg_ApplyMatBridge_Flat_IP(mat_brg, mat_id, mat_family, algo_id, &
      integ_pt_id, dtime, time_step, time_total, kstep, kinc, noel, npt)
    TYPE(RT_Mat_Bridge_Ctx), INTENT(INOUT) :: mat_brg
    INTEGER(i4), INTENT(IN) :: mat_id, mat_family, algo_id, integ_pt_id
    REAL(wp), INTENT(IN)    :: dtime, time_step, time_total
    INTEGER(i4), INTENT(IN) :: kstep, kinc, noel, npt
    ! W1 Step4 前奏：真源为 %stp / %lcl；平场 DEPRECATED 仅作兼容镜像（ufc-layer-l3-l4-l5-pilot §15.5）
    mat_brg%stp%mat_id     = mat_id
    mat_brg%stp%mat_family = mat_family
    mat_brg%stp%algo_id    = algo_id
    mat_brg%lcl%integ_pt_id = integ_pt_id
    mat_brg%lcl%dtime       = dtime
    mat_brg%lcl%time_step   = time_step
    mat_brg%lcl%time_total  = time_total
    mat_brg%lcl%kstep       = kstep
    mat_brg%lcl%kinc        = kinc
    mat_brg%lcl%noel        = noel
    mat_brg%lcl%npt         = npt
    CALL RT_Mat_Bridge_Sync_Deprecated_From_Aux(mat_brg)
  END SUBROUTINE RT_Asm_Brg_ApplyMatBridge_Flat_IP

  SUBROUTINE RT_Asm_Brg_ApplyElemBridge_Flat_IP(elem_brg, elem_id, jtype, elem_family, &
      lflags, dtime, time_step, time_total, kstep, kinc, nrhs, isym)
    TYPE(RT_Elem_Bridge_Ctx), INTENT(INOUT) :: elem_brg
    INTEGER(i4), INTENT(IN) :: elem_id, jtype, elem_family
    INTEGER(i4), INTENT(IN) :: lflags(5)
    REAL(wp), INTENT(IN)    :: dtime, time_step, time_total
    INTEGER(i4), INTENT(IN) :: kstep, kinc, nrhs, isym
    elem_brg%stp%elem_id     = elem_id
    elem_brg%stp%jtype       = jtype
    elem_brg%stp%elem_family = elem_family
    elem_brg%lcl%lflags      = lflags
    elem_brg%lcl%dtime       = dtime
    elem_brg%lcl%time_step   = time_step
    elem_brg%lcl%time_total  = time_total
    elem_brg%lcl%kstep       = kstep
    elem_brg%lcl%kinc        = kinc
    elem_brg%lcl%nrhs        = nrhs
    elem_brg%lcl%isym        = isym
    CALL RT_Elem_Bridge_Sync_Deprecated_From_Aux(elem_brg)
  END SUBROUTINE RT_Asm_Brg_ApplyElemBridge_Flat_IP

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Brg_FromL3Model
  ! PHASE:      P1
  ! PURPOSE:    Populate RT_Asm_Desc from L3 model sizes
  ! NOTE:        Gold-path caller: `MD_Model_Brg::UF_register_model_in_dataplatform` after mesh counts known.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Brg_FromL3Model(n_nodes, n_elems, n_dof_per_node, &
                                     out_asm, status)
    INTEGER(i4), INTENT(IN)  :: n_nodes
    INTEGER(i4), INTENT(IN)  :: n_elems
    INTEGER(i4), INTENT(IN)  :: n_dof_per_node
    TYPE(RT_Asm_Desc), INTENT(OUT) :: out_asm
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    CALL out_asm%Init()
    out_asm%elem_start = 1
    out_asm%elem_end   = n_elems
    out_asm%node_start = 1
    out_asm%node_end   = n_nodes

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Brg_FromL3Model

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Brg_BuildElemDofMap
  ! PHASE:      P1
  ! PURPOSE:    Build element DOF map from connectivity
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Brg_BuildElemDofMap(elem_conn, n_nodes_elem, ndim, &
                                         dof_map, ndof_elem, status)
    INTEGER(i4), INTENT(IN)  :: elem_conn(:)
    INTEGER(i4), INTENT(IN)  :: n_nodes_elem
    INTEGER(i4), INTENT(IN)  :: ndim
    INTEGER(i4), INTENT(OUT) :: dof_map(:)
    INTEGER(i4), INTENT(OUT) :: ndof_elem
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: inode, idim

    CALL init_error_status(status)
    ndof_elem = n_nodes_elem * ndim

    DO inode = 1, n_nodes_elem
      DO idim = 1, ndim
        dof_map((inode-1)*ndim + idim) = (elem_conn(inode)-1)*ndim + idim
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Brg_BuildElemDofMap

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Brg_AllocGlobalSystem
  ! PHASE:      P1
  ! PURPOSE:    Allocate global K/F and attach to state
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Brg_AllocGlobalSystem(n_dof_total, state, &
                                            K_store, F_store, status)
    INTEGER(i4), INTENT(IN)              :: n_dof_total
    TYPE(RT_Asm_State), INTENT(INOUT)    :: state
    REAL(wp), INTENT(INOUT), TARGET      :: K_store(:,:)
    REAL(wp), INTENT(INOUT), TARGET      :: F_store(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    K_store = 0.0_wp
    F_store = 0.0_wp
    state%K_global => K_store
    state%f_global => F_store
    state%n_assembled_dofs = n_dof_total

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Brg_AllocGlobalSystem

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Brg_FreeGlobalSystem
  ! PHASE:      P0
  ! PURPOSE:    Detach global system from state
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Brg_FreeGlobalSystem(state, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    CALL state%Detach()
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Brg_FreeGlobalSystem

END MODULE RT_Asm_Brg
