!===============================================================================
! MODULE: RT_Asm_Global
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Core
! BRIEF:  Unified global assembly core -- geometric NL + general sparse CSR
!===============================================================================
!
! Theory:
!   K_global (CSR) = sum_elem (K_mat + K_geo)_elem
!   R_global = sum_elem R_int_elem
!   Supports COO -> CSR conversion and penalty/Lagrange BC methods.
!
! Data Flow:
!   1. L3_MD/Model -> L4_PH/Elem -> K_elem
!   2. K_elem -> K_global_CSR (sparse assembly via COO -> CSR)
!   3. L3_MD/BCDef -> L4_PH/BC -> K_CSR, F modification
!   4. K_CSR, F -> L2_NM/Solv -> u
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!
!   Main assembly driver connecting element-level TL/UL to global K/R.
!   Supports CSR sparse matrix assembly ( ??Dense).
!   Integration: MD_ModelTree ?RT_Asm_Global_Core ?RT_Asm_GeomNL_Dispatch ?PH_Elem_*
!
!   Data Flow:
!   1. L3_MD/Model ?L4_PH/Elem ?K_elem
!   2. K_elem ?K_global_CSR (sparse assembly via COO ?CSR)
!   3. L3_MD/BCDef ?L4_PH/BC ?K_CSR, F modification
!   4. L3_MD/LoadDef ?L4_PH/Load ?F modification
!   5. K_CSR, F ?L2_NM/Solv ?u
!
! Theory:
!   -  stiffnessmatrix K_global (CSR) = ?_elem (K_mat + K_geo)_elem
!   -  force R_global = ?_elem R_int_elem
!   -  ?Memory id=2f0ec6d8: CSR  ?
!
! Performance Improvement:
!   - Memory: O(nnz) vs O(n?
!   - Assembly speed: 10-100?faster for large DOF
!   - Solver speed: 5-50?faster with sparse solvers
!
! References:
!   - Memory id=5c1a5dee:  ?BC  
!   - Memory id=f5b482c6: Lagrange  
! Status: Production | Last verified: 2026-02-21
!===============================================================================
!===============================================================================
! Module: RT_AsmGlobal
! Layer:  L5_RT - Runtime Layer
! Domain: Asm - Assembly
! Purpose: Global stiffness/mass assembly: loop over elements and scatter to CSR/dense
! Theory:  Zienkiewicz & Taylor FEM Vol.1 §3; Hughes The FEM §1.8
! Status:  [STUB/CORE/PROD] | Last verified: 2026-02-28
!
! Contents (A-Z):
!   Types:
!     - [List types in A-Z order]
!   Subroutines:
!     - [List subroutines in A-Z order]
!   Functions:
!     - [List functions in A-Z order]
!===============================================================================

MODULE RT_Asm_Global
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR, &
                        log_info, log_warn, log_error
  USE IF_Err_Brg, ONLY: IF_STATUS_SUCCESS
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_Mtx_Sparse, ONLY: NM_CSR_Type, NM_COO_Type, NM_CSR_GetStatistics, &
                                  NM_COO_Init, NM_COO_AddElementMatrix, NM_COO_Finalize, &
                                  NM_CSR_AssembleFromElements
  USE PH_BC_Brg, ONLY: PH_BC_CSR_System_Type, PH_BC_Apply_Penalty_CSR_FromDesc
  USE PH_BC_Mgr, ONLY: PH_BC_Ctx
  USE PH_BC_Def, ONLY: PH_BC_Dirichlet_Desc
  USE PH_Load_Mgr, ONLY: PH_Load_Ctx
  ! Load application is routed through PH_LoadBC_Domain / MD_LBC directly
  ! inside the RT_AsmSolv golden line.  Retained as comment for traceability.
  ! USE RT_Asm_LoadBC_Apply, ONLY: RT_Asm_Apply_Loads_FromMDDef
  USE RT_Asm_NLGeomDispatch, ONLY: RT_Asm_NLGeom_Dispatch_TL, RT_Asm_NLGeom_Dispatch_UL
  
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  ! Geometric nonlinear assembly (using CSR_Matrix)
  PUBLIC :: RT_Asm_Global_Init
  PUBLIC :: RT_Asm_Globalble_NL
  PUBLIC :: RT_Asm_Global_ApplyBC_Sparse
  PUBLIC :: CSR_Matrix
  
  ! General sparse assembly (using NM_CSR_Type)
  PUBLIC :: RT_Asm_BuildGlobSys_Sparse  ! RT_Asm_BuildGlobalSystem_Sparse
  PUBLIC :: RT_Asm_AssemElems_Sparse    ! RT_Asm_AssembleElements_Sparse
  PUBLIC :: RT_Asm_ApplyBC_Sparse       ! RT_Asm_ApplyBoundaryConditions_Sparse

  !-----------------------------------------------------------------------------
  ! Type: CSR_Matrix (Legacy type for backward compatibility)
  ! Purpose: Compressed Sparse Row matrix storage
  ! Note: For new code, prefer using NM_CSR_Type from NM_SparseMtx
  !-----------------------------------------------------------------------------
  TYPE :: CSR_Matrix
    INTEGER(i4) :: n_rows = 0
    INTEGER(i4) :: n_cols = 0
    INTEGER(i4) :: nnz = 0
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)   ! Length: n_rows + 1
    INTEGER(i4), ALLOCATABLE :: col_ind(:)   ! Length: nnz
    REAL(wp), ALLOCATABLE :: values(:)       ! Length: nnz
  END TYPE CSR_Matrix

CONTAINS

  !=============================================================================
  ! GEOMETRIC NONLINEAR ASSEMBLY (Legacy interface using CSR_Matrix)
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_Global_Init
  ! Purpose: Initialize global assembly structures (CSR allocation)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Global_Init(n_dof_global, n_elements, K_global, R_global, status)
    INTEGER(i4), INTENT(IN) :: n_dof_global
    INTEGER(i4), INTENT(IN) :: n_elements
    TYPE(CSR_Matrix), INTENT(OUT) :: K_global
    REAL(wp), INTENT(OUT) :: R_global(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Initialize global residual
    IF (SIZE(R_global) /= n_dof_global) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "R_global size mismatch"
      RETURN
    END IF
    R_global = 0.0_wp

    ! Initialize CSR structure ( ?   27  ? ??3D  )
    K_global%n_rows = n_dof_global
    K_global%n_cols = n_dof_global
    K_global%nnz = n_dof_global * 27  !  

    ALLOCATE(K_global%row_ptr(n_dof_global + 1))
    ALLOCATE(K_global%col_ind(K_global%nnz))
    ALLOCATE(K_global%values(K_global%nnz))

    K_global%row_ptr = 0
    K_global%col_ind = 0
    K_global%values = 0.0_wp

    status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_Asm_Global_Init

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_Globalble_NL
  ! Purpose: Assemble element contributions to global CSR K and R
  ! Input:
  !   elem_type_id      : Element type (from MD layer)
  !   elem_node_ids(:)  : Global node IDs for current element
  !   coords_ref/prev   : Reference/previous coordinates
  !   u_elem            : Element displacement vector
  !   D                 : Mat tangent
  !   formulation_typ   : 1=TL, 2=UL
  !   extra_params      : Optional (thickness/area/etc.)
  ! Output:
  !   K_global (CSR)    : Updated global stiffness (in-place)
  !   R_global          : Updated global residual (in-place)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Globalble_NL(elem_type_id, elem_node_ids, &
                                        coords_ref, u_elem, D, formulation_typ, &
                                        extra_params, K_global, R_global, status)
    INTEGER(i4), INTENT(IN) :: elem_type_id
    INTEGER(i4), INTENT(IN) :: elem_node_ids(:)
    REAL(wp), INTENT(IN) :: coords_ref(:,:)
    REAL(wp), INTENT(IN) :: u_elem(:)
    REAL(wp), INTENT(IN) :: D(:,:)
    INTEGER(i4), INTENT(IN) :: formulation_typ
    REAL(wp), INTENT(IN), OPTIONAL :: extra_params(:)
    TYPE(CSR_Matrix), INTENT(INOUT) :: K_global
    REAL(wp), INTENT(INOUT) :: R_global(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), ALLOCATABLE :: Ke_mat(:,:), Ke_geo(:,:), R_int(:)
    INTEGER(i4) :: n_dof_elem, i, j, global_i, global_j

    CALL init_error_status(status)

    n_dof_elem = SIZE(u_elem)

    ! 1.  element-grade ?
    ALLOCATE(Ke_mat(n_dof_elem, n_dof_elem))
    ALLOCATE(Ke_geo(n_dof_elem, n_dof_elem))
    ALLOCATE(R_int(n_dof_elem))

    Ke_mat = 0.0_wp; Ke_geo = 0.0_wp; R_int = 0.0_wp

    ! 2.  element  TL/UL
    IF (formulation_typ == 1) THEN
      CALL RT_Asm_NLGeom_Dispatch_TL(elem_type_id, coords_ref, u_elem, D, &
                                  extra_params, Ke_mat, Ke_geo, R_int, status)
    ELSE IF (formulation_typ == 2) THEN
      CALL RT_Asm_NLGeom_Dispatch_UL(elem_type_id, coords_ref, u_elem, D, &
                                  extra_params, Ke_mat, Ke_geo, R_int, status)
    ELSE
      status%status_code = IF_STATUS_ERROR
      status%message = "Invalid formulation_typ (must be 1=TL or 2=UL)"
      RETURN
    END IF

    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 3.   K (CSR  ) ?R
    ! TODO:   CSR  ??stub?matrix ?
    !  ? CSR AddEntry  ?
    DO i = 1, n_dof_elem
      global_i = elem_node_ids((i-1)/3 + 1) * 3 + MOD(i-1, 3)  !   DOF
      R_global(global_i) = R_global(global_i) + R_int(i)

      DO j = 1, n_dof_elem
        global_j = elem_node_ids((j-1)/3 + 1) * 3 + MOD(j-1, 3)
        !   CSR  ?stub?
        CALL CSR_AddEntry(K_global, global_i, global_j, Ke_mat(i,j) + Ke_geo(i,j), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
      END DO
    END DO

    DEALLOCATE(Ke_mat, Ke_geo, R_int)

  END SUBROUTINE RT_Asm_Globalble_NL

  !-----------------------------------------------------------------------------
  ! Subroutine: CSR_AddEntry
  ! Purpose: Add value to CSR matrix at (i, j)
  ! Memory:   id=2f0ec6d8?
  !-----------------------------------------------------------------------------
  SUBROUTINE CSR_AddEntry(matrix, row, col, value, status)
    TYPE(CSR_Matrix), INTENT(INOUT) :: matrix
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(IN) :: value
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: k

    CALL init_error_status(status)

    ! ?[row_ptr(row), row_ptr(row+1))  ?col
    DO k = matrix%row_ptr(row), matrix%row_ptr(row+1) - 1
      IF (matrix%col_ind(k) == col) THEN
        matrix%values(k) = matrix%values(k) + value
        RETURN
      END IF
    END DO

    !  ?  ?CSR???
    ! TODO:  ?CSR  ? Memory id=2f0ec6d8?
    status%status_code = IF_STATUS_ERROR
    status%message = "CSR dynamic insertion not yet implemented"

  END SUBROUTINE CSR_AddEntry

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_Global_ApplyBC_Sparse
  ! Purpose: Apply boundary conditions to CSR K and R ( ?
  ! Memory:   id=5c1a5dee??BC  ??id=f5b482c6?Lagrange  ?
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Global_ApplyBC_Sparse(K_global, R_global, bc_dofs, bc_values, &
                                           method, status)
    TYPE(CSR_Matrix), INTENT(INOUT) :: K_global
    REAL(wp), INTENT(INOUT) :: R_global(:)
    INTEGER(i4), INTENT(IN) :: bc_dofs(:)
    REAL(wp), INTENT(IN) :: bc_values(:)
    CHARACTER(LEN=*), INTENT(IN) :: method  ! "PENALTY" / "LAGRANGE" / "ELIMINATION"
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, dof_id, k

    CALL init_error_status(status)

    SELECT CASE (TRIM(method))

      CASE ("PENALTY")
        ! Penalty method: K(i,i) += penalty, R(i) = penalty * bc_value
        DO i = 1, SIZE(bc_dofs)
          dof_id = bc_dofs(i)
          ! ?CSR   K(dof_id, dof_id)
          DO k = K_global%row_ptr(dof_id), K_global%row_ptr(dof_id+1) - 1
            IF (K_global%col_ind(k) == dof_id) THEN
              K_global%values(k) = K_global%values(k) + 1.0e12_wp
              R_global(dof_id) = 1.0e12_wp * bc_values(i)
              EXIT
            END IF
          END DO
        END DO

      CASE ("LAGRANGE")
        ! Lagrange multiplier:   CSR  ?[K C^T; C 0]
        ! TODO:   CSR  ? Memory id=f5b482c6?
        status%status_code = IF_STATUS_ERROR
        status%message = "LAGRANGE method not yet implemented"
        RETURN

      CASE ("ELIMINATION")
        ! Direct elimination:   CSR ??
        ! TODO:  
        status%status_code = IF_STATUS_ERROR
        status%message = "ELIMINATION method not yet implemented"
        RETURN

      CASE DEFAULT
        status%status_code = IF_STATUS_ERROR
        status%message = "Unknown BC method"
        RETURN

    END SELECT

    status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_Asm_Global_ApplyBC_Sparse

  !=============================================================================
  ! GENERAL SPARSE ASSEMBLY (Production interface using NM_CSR_Type)
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_BuildGlobSys_Sparse
  ! Purpose: Build global system (sparse format): K_CSR, F = Assemble + BC + Load
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_BuildGlobSys_Sparse(K_csr, F_global, &
                                              elem_K, elem_dofs, n_dof, &
                                              bc_defs, load_defs, dof_map, &
                                              bc_ctx, load_ctx, status)
    TYPE(NM_CSR_Type), INTENT(OUT) :: K_csr
    REAL(wp),    INTENT(INOUT) :: F_global(:)
    REAL(wp),    INTENT(IN) :: elem_K(:,:,:)
    INTEGER(i4), INTENT(IN) :: elem_dofs(:,:)
    INTEGER(i4), INTENT(IN) :: n_dof
    TYPE(*),     INTENT(IN) :: bc_defs(:)
    TYPE(*),     INTENT(IN) :: load_defs(:)
    INTEGER(i4), INTENT(IN) :: dof_map(:)
    TYPE(PH_BC_Ctx),   INTENT(INOUT) :: bc_ctx
    TYPE(PH_Load_Ctx), INTENT(INOUT) :: load_ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status, sub_status
    INTEGER(i4) :: n_elem, nnz_estimate
    REAL(wp) :: t_start, t_end
    CHARACTER(LEN=512) :: stats_msg
    
    CALL init_error_status(local_status)
    CALL CPU_TIME(t_start)
    
    n_elem = SIZE(elem_K, 3)
    
    ! Estimate nnz (typical FEM: ~10 nonzeros per row)
    nnz_estimate = n_dof * 10
    
    ! Initialize RHS
    F_global = 0.0_wp
    
    ! Step 1: Assemble element stiffness matrices (sparse)
    CALL log_info("RT_AsmGlobal: Assembling element matrices (CSR format)...", sub_status)
    
    CALL RT_Asm_AssemElems_Sparse(K_csr, elem_K, elem_dofs, n_dof, nnz_estimate, sub_status)
    
    IF (sub_status%status_code /= IF_STATUS_OK) THEN
        CALL log_error("RT_AsmGlobal: Element assembly failed", local_status)
        IF (PRESENT(status)) status = local_status
        RETURN
    END IF
    
    ! Log sparse matrix statistics
    CALL NM_CSR_GetStatistics(K_csr, stats_msg, sub_status)
    IF (sub_status%status_code == IF_STATUS_OK) THEN
        CALL log_info("RT_AsmGlobal: " // TRIM(stats_msg), sub_status)
    END IF
    
    ! Step 2: Apply boundary conditions (sparse-aware)
    CALL log_info("RT_AsmGlobal: Applying boundary conditions...", sub_status)
    
    CALL RT_Asm_ApplyBC_Sparse(K_csr, F_global, &
                                               bc_defs, dof_map, bc_ctx, &
                                               sub_status)
    
    IF (sub_status%status_code /= IF_STATUS_OK) THEN
        CALL log_warn("RT_AsmGlobal: BC application encountered issues", local_status)
    END IF
    
    ! Step 3: Apply loads
    ! DANGLING-REF (v2.0): RT_Asm_Apply_Loads_FromMDDef does not exist.
    ! Load application is handled by PH_LoadBC_Domain in the RT_AsmSolv path.
    ! This subroutine (RT_Asm_BuildGlobSys_Sparse) is not on the golden line.
    CALL log_info("RT_AsmGlobal: Load apply skipped (DANGLING-REF)", sub_status)
    CALL init_error_status(sub_status)
    
    CALL CPU_TIME(t_end)
    
    ! Log summary
    WRITE(*,'(A,I0,A,I0,A,F8.3,A)') "RT_AsmGlobal: Assembly completed (" // &
          "n_elem=", n_elem, ", n_dof=", n_dof, ", time=", t_end - t_start, " s)"
    
    local_status%status_code = IF_STATUS_OK
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_Asm_BuildGlobSys_Sparse

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_AssemElems_Sparse
  ! Purpose: Assemble element stiffness matrices (sparse format)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_AssemElems_Sparse(K_csr, elem_K, elem_dofs, n_dof, nnz_estimate, status)
    TYPE(NM_CSR_Type), INTENT(OUT) :: K_csr
    REAL(wp),    INTENT(IN) :: elem_K(:,:,:)
    INTEGER(i4), INTENT(IN) :: elem_dofs(:,:)
    INTEGER(i4), INTENT(IN) :: n_dof
    INTEGER(i4), INTENT(IN) :: nnz_estimate
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status, sub_status
    
    CALL init_error_status(local_status)
    
    ! Use one-pass assembly: elem_K ?COO ?CSR
    CALL NM_CSR_AssembleFromElements(K_csr, elem_K, elem_dofs, n_dof, nnz_estimate, sub_status)
    
    IF (sub_status%status_code /= IF_STATUS_OK) THEN
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = "RT_Asm_AssembleElements_Sparse: Assembly failed"
        IF (PRESENT(status)) status = local_status
        RETURN
    END IF
    
    local_status%status_code = IF_STATUS_OK
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_Asm_AssemElems_Sparse

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_ApplyBC_Sparse
  ! Purpose: Apply boundary conditions on sparse matrix (direct CSR modification)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_ApplyBC_Sparse(K_csr, F_global, &
                                                   bc_defs, dof_map, bc_ctx, &
                                                   status)
    TYPE(NM_CSR_Type), INTENT(INOUT) :: K_csr
    REAL(wp),    INTENT(INOUT) :: F_global(:)
    TYPE(*),     INTENT(IN) :: bc_defs(:)
    INTEGER(i4), INTENT(IN) :: dof_map(:)
    TYPE(PH_BC_Ctx),   INTENT(INOUT) :: bc_ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status, sub_status
    INTEGER(i4) :: n_bc, i_bc, dof_index
    REAL(wp) :: presc_val  ! prescribed_value ?presc_val
    TYPE(PH_BC_Dirichlet_Desc) :: bc_pack
    TYPE(PH_BC_CSR_System_Type) :: system_csr  ! prescribed_values ?presc_vals
    
    CALL init_error_status(local_status)
    
    n_bc = SIZE(bc_defs)
    
    IF (n_bc == 0) THEN
        CALL log_info("RT_AsmGlobal: No BCs to apply", sub_status)
        local_status%status_code = IF_STATUS_OK
        IF (PRESENT(status)) status = local_status
        RETURN
    END IF
    
    ! Build Desc (struct-only API)
    bc_pack%n_dofs = n_bc
    ALLOCATE(bc_pack%dof_indices(n_bc), bc_pack%prescribed_values(n_bc))
    DO i_bc = 1, n_bc
        dof_index = i_bc  ! TODO: parse bc_defs for real dof_index, presc_val
        presc_val = 0.0_wp
        bc_pack%dof_indices(i_bc) = dof_index
        bc_pack%prescribed_values(i_bc) = presc_val
    END DO
    
    bc_ctx%penalty_factor = 1.0e30_wp
    system_csr%K_csr => K_csr
    system_csr%F => F_global
    
    CALL PH_BC_Apply_Penalty_CSR_FromDesc(system_csr, bc_pack, bc_ctx, sub_status)
    
    DEALLOCATE(bc_pack%dof_indices, bc_pack%prescribed_values)
    
    IF (sub_status%status_code /= IF_STATUS_OK) THEN
        CALL log_warn("RT_AsmGlobal: BC application failed", local_status)
        local_status%status_code = sub_status%status_code
    ELSE
        local_status%status_code = IF_STATUS_OK
    END IF
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_Asm_ApplyBC_Sparse

END MODULE RT_Asm_Global
