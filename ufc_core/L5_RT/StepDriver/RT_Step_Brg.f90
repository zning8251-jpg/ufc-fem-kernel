!===============================================================================
! MODULE: RT_Step_Brg
! LAYER:  L5_RT
! DOMAIN: StepDriver
! ROLE:   Brg — Bridge from L6 config to L4_PH interfaces
! BRIEF:  StepDriver facade — routes element compute + assembly + solve
!         requests through L4_PH bridge modules.
!===============================================================================
MODULE RT_Step_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Step_Def, ONLY: RT_StepDrv_Desc, RT_StepDrv_State, RT_StepDrv_Ctx
  ! 引入底层的桥接门面
  USE PH_ElemRT_Brg, ONLY: PH_Elem_Compute
  USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_Ctx
  USE MD_Field_Mgr, ONLY: MD_ElemIPData
  USE MD_Mat_BaseDef, ONLY: MD_Mat_Ctx
  
  ! 引入全局组装与求解
  USE RT_Shared_Def, ONLY: RT_CSRMatrix
  USE RT_Asm_Mgr, ONLY: RT_Asm_AddElemStiff_Structured, RT_Asm_AddElemStiff_In, RT_Asm_AddElemStiff_Out
  USE RT_Solv_Brg, ONLY: RT_Solv_Bridge_Unified
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_StepDriver_Run

CONTAINS

  !> @brief 执行一个分析步的核心循环
  !> @param job_desc L6传入的只读配?  !> @param job_state 全局作业状态
  !> @param job_ctx 运行时临时工作内存
  SUBROUTINE RT_StepDriver_Run(job_desc, job_state, job_ctx, status)
    USE RT_Asm_Def, ONLY: RT_Asm_Ctx
    TYPE(RT_StepDrv_Desc), INTENT(IN) :: job_desc
    TYPE(RT_StepDrv_State), INTENT(INOUT) :: job_state
    TYPE(RT_StepDrv_Ctx), INTENT(INOUT) :: job_ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: inc, iter, elem_idx, num_elements, i
    LOGICAL :: inc_converged

    TYPE(PH_Elem_Desc) :: elem_cfg
    TYPE(MD_ElemIPData) :: elem_state
    TYPE(PH_Elem_Ctx) :: elem_ctx
    TYPE(MD_Mat_Ctx) :: mat_cfg

    TYPE(RT_CSRMatrix) :: K_csr
    REAL(wp), ALLOCATABLE :: dU_global(:)
    TYPE(RT_Asm_AddElemStiff_In) :: asm_in
    TYPE(RT_Asm_AddElemStiff_Out) :: asm_out

    ! Per-thread element workspace (stack-allocated, thread-private via PRIVATE clause)
    TYPE(RT_Asm_Ctx) :: thr_asm_ctx
    TYPE(PH_Elem_Desc) :: thr_elem_cfg
    TYPE(MD_ElemIPData) :: thr_elem_state
    TYPE(PH_Elem_Ctx) :: thr_elem_ctx
    TYPE(MD_Mat_Ctx) :: thr_mat_cfg
    TYPE(ErrorStatusType) :: thr_status

    status%status_code = IF_STATUS_OK

    job_state%current_time = 0.0_wp

    IF (.NOT. ALLOCATED(dU_global)) ALLOCATE(dU_global(100))

    DO inc = 1, job_desc%default_max_increments
      job_state%current_increment = inc
      inc_converged = .FALSE.

      DO iter = 1, job_desc%default_max_iterations
        job_state%current_iteration = iter

        job_ctx%f_residual = 0.0_wp

        num_elements = 1

        !$OMP PARALLEL DO DEFAULT(NONE) &
        !$OMP   SHARED(num_elements, job_desc, job_state, job_ctx, K_csr) &
        !$OMP   PRIVATE(elem_idx, thr_asm_ctx, thr_elem_cfg, thr_elem_state, &
        !$OMP           thr_elem_ctx, thr_mat_cfg, thr_status) &
        !$OMP   SCHEDULE(DYNAMIC, 64)
        DO elem_idx = 1, num_elements

           CALL thr_asm_ctx%ClearElementData()

           CALL PH_Elem_Compute(thr_elem_cfg, thr_elem_state, &
                                thr_elem_ctx, thr_mat_cfg, thr_status)
           IF (thr_status%status_code /= IF_STATUS_OK) CYCLE

           ! Assembly to global K: accumulate element stiffness into CSR matrix
           asm_in%K_element = thr_asm_ctx%elem_ke
           asm_in%elem_dof  = thr_asm_ctx%elem_dof_map
           asm_in%K_csr     = K_csr
           CALL RT_Asm_AddElemStiff_Structured(asm_in, asm_out)
           IF (asm_out%status%status_code /= IF_STATUS_OK) CYCLE

        END DO
        !$OMP END PARALLEL DO

        ! 3. Solve linear system: K * dU = R (external - internal forces)
        CALL RT_Solv_Bridge_Unified(K_csr, job_ctx%f_residual, &
                                     dU_global, status)
        IF (status%status_code /= IF_STATUS_OK) EXIT

        ! 4. Update global displacements
        job_ctx%u_global = job_ctx%u_global + dU_global

        ! 5. Compute residual norm and check convergence
        BLOCK
          REAL(wp) :: residual_norm, tol
          INTEGER(i4) :: j
          residual_norm = 0.0_wp
          DO j = 1, SIZE(job_ctx%f_residual)
            residual_norm = residual_norm + job_ctx%f_residual(j)**2
          END DO
          residual_norm = SQRT(residual_norm)
          tol = job_desc%convergence_tol
          IF (tol <= 0.0_wp) tol = 1.0e-6_wp
          IF (residual_norm < tol) THEN
            inc_converged = .TRUE.
            EXIT
          END IF
        END BLOCK
      END DO

      IF (.NOT. inc_converged) THEN
        status%status_code = -1
        EXIT
      END IF

      job_state%current_time = job_state%current_time + job_state%current_dt
      IF (job_state%current_time >= 1.0_wp) THEN
         job_state%step_converged = .TRUE.
         EXIT
      END IF
    END DO

    IF (ALLOCATED(dU_global)) DEALLOCATE(dU_global)
  END SUBROUTINE RT_StepDriver_Run

END MODULE RT_Step_Brg
