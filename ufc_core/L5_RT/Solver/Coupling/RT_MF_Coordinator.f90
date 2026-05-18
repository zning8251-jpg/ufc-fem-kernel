!===============================================================================
! MODULE: RT_MF_Coordinator
! LAYER:  L5_RT
! DOMAIN: Coupling
! ROLE:   Ctrl
! BRIEF:  Top-level driver for multi-field coupled analyses
!===============================================================================
!
! Coupling strategies (RT_MF_COUP_* constants):
!   0 = ONEWAY    -- one-directional data pass
!   1 = STAG      -- Staggered sequential solve
!   2 = PARTITER  -- Partitioned Iterative + outer coupling loop
!   3 = MONO      -- Monolithic unified block system
!
! Process族:
!   P0: Init / Finalize                       [COLD_PATH]
!   P2: Solve (strategy dispatch per increment) [HOT_PATH]
!   P1: Sync (interface field exchange)         [HOT_PATH]
!
! Status: GOLDEN-LINE | PLACEHOLDER | Last verified: 2026-04-28
!===============================================================================
MODULE RT_MF_Coordinator
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_WARN
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_MF_Coordinator_Run       ! Top-level analysis entry
  PUBLIC :: RT_MF_Coordinator_Init      ! Pre-analysis initialisation
  PUBLIC :: RT_MF_Coordinator_Finalize  ! Post-analysis cleanup

  !-- Strategy-specific drivers
  PRIVATE :: RT_MF_Oneway_Loop
  PRIVATE :: RT_MF_Staggered_Loop
  PRIVATE :: RT_MF_PartIter_Loop
  PRIVATE :: RT_MF_Monolithic_Loop

  !-- Per-iteration helpers
  PRIVATE :: RT_MF_Solve_SingleField
  PRIVATE :: RT_MF_Exchange_Interface
  PRIVATE :: RT_MF_ConvCheck_Coupling
  PRIVATE :: RT_MF_Aitken_Accelerate

CONTAINS

  !============================================================================
  ! RT_MF_Coordinator_Init — Pre-analysis initialisation
  !   Called once at analysis start by UFC_Driver.
  !   Validates Desc and initialises State.
  !============================================================================
  SUBROUTINE RT_MF_Coordinator_Init(desc, state, algo, err_status)
    TYPE(RT_MF_Coupling_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Algo),   INTENT(INOUT) :: algo
    TYPE(ErrorStatusType),         INTENT(INOUT) :: err_status

    CHARACTER(LEN=256) :: errmsg

    !-- Validate Desc
    IF (desc%n_fields < 2_i4) THEN
      errmsg = 'RT_MF_Coordinator_Init: n_fields must be >= 2, got ' &
               // TRIM(ADJUSTL(i4toa(desc%n_fields)))
      CALL init_error_status(err_status, IF_STATUS_ERROR)
      RETURN
    END IF

    IF (desc%n_pairs < 1_i4 .AND. desc%global_strategy /= RT_MF_COUP_ONEWAY) THEN
      errmsg = 'RT_MF_Coordinator_Init: n_pairs must be >= 1 for coupled analysis'
      CALL init_error_status(err_status, IF_STATUS_ERROR)
      RETURN
    END IF

    !-- Initialise State (allocates pair_residual arrays)
    CALL state%Init(desc%n_pairs)

    !-- Mark Desc as valid
    desc%is_valid = .TRUE.

    CALL init_error_status(err_status, IF_STATUS_OK)

  CONTAINS
    ! Helper: integer to string (Fortran-only, no iso_env_binding)
    FUNCTION i4toa(val) RESULT(str)
      INTEGER(i4), INTENT(IN) :: val
      CHARACTER(LEN=32) :: str
      WRITE(str, '(I0)') val
    END FUNCTION i4toa

  END SUBROUTINE RT_MF_Coordinator_Init

  !============================================================================
  ! RT_MF_Coordinator_Run — Top-level entry point
  !   Called by UFC_Driver for each coupled analysis step.
  !============================================================================
  SUBROUTINE RT_MF_Coordinator_Run(desc, state, algo, ctx, err_status)
    TYPE(RT_MF_Coupling_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Algo),   INTENT(INOUT) :: algo
    TYPE(RT_MF_Coupling_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),          INTENT(INOUT) :: err_status

    CHARACTER(LEN=256) :: errmsg

    !-- Guard: Desc not valid
    IF (.NOT. desc%is_valid) THEN
      errmsg = 'RT_MF_Coordinator_Run: Desc not validated. Call Init first.'
      CALL init_error_status(err_status, IF_STATUS_ERROR)
      RETURN
    END IF

    !-- Strategy dispatch
    SELECT CASE (desc%global_strategy)

    CASE (RT_MF_COUP_ONEWAY)
      CALL RT_MF_Oneway_Loop(desc, state, algo, ctx, err_status)

    CASE (RT_MF_COUP_STAG)
      CALL RT_MF_Staggered_Loop(desc, state, algo, ctx, err_status)

    CASE (RT_MF_COUP_PARTITER)
      CALL RT_MF_PartIter_Loop(desc, state, algo, ctx, err_status)

    CASE (RT_MF_COUP_MONO)
      CALL RT_MF_Monolithic_Loop(desc, state, algo, ctx, err_status)

    CASE DEFAULT
      errmsg = 'RT_MF_Coordinator_Run: unknown coupling strategy'
      CALL init_error_status(err_status, IF_STATUS_ERROR)
    END SELECT

  END SUBROUTINE RT_MF_Coordinator_Run

  !============================================================================
  ! RT_MF_Coordinator_Finalize — Post-analysis cleanup
  !   Deallocates all state arrays (called after analysis completes).
  !============================================================================
  SUBROUTINE RT_MF_Coordinator_Finalize(state, err_status)
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),         INTENT(INOUT) :: err_status

    IF (ALLOCATED(state%pair_res_abs)) DEALLOCATE(state%pair_res_abs)
    IF (ALLOCATED(state%pair_res_rel)) DEALLOCATE(state%pair_res_rel)
    CALL init_error_status(err_status, IF_STATUS_OK)
  END SUBROUTINE RT_MF_Coordinator_Finalize

  !============================================================================
  ! RT_MF_Oneway_Loop — One-way data pass
  !   Field A solves → Field A data passed to Field B → done.
  !   No iteration, no convergence check, no feedback.
  !============================================================================
  SUBROUTINE RT_MF_Oneway_Loop(desc, state, algo, ctx, err_status)
    TYPE(RT_MF_Coupling_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Algo),   INTENT(INOUT) :: algo
    TYPE(RT_MF_Coupling_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),          INTENT(INOUT) :: err_status

    INTEGER(i4) :: ifield, field_id

    state%coup_status = RT_MF_STATE_ITERATING

    !-- Solve each active field in order
    DO ifield = 1, desc%n_fields
      field_id = desc%field_ids(ifield)
      CALL RT_MF_Solve_SingleField(field_id, desc, state, algo, ctx, err_status)
    END DO

    !-- Exchange interface data (one pass only)
    CALL RT_MF_Exchange_Interface(desc, state, ctx, err_status)

    !-- Mark converged (one-way always "converged" after single pass)
    state%coup_status = RT_MF_STATE_CONVERGED
    state%coup_converged = .TRUE.

    CALL init_error_status(err_status, IF_STATUS_OK)
  END SUBROUTINE RT_MF_Oneway_Loop

  !============================================================================
  ! RT_MF_Staggered_Loop — Staggered (weakly coupled)
  !   All fields solve sequentially → check coupling convergence → next increment.
  !   max_coup_iter = 1 (no outer iteration; convergence is per-increment).
  !   Phase-1 priority: STR↔THM uses this strategy.
  !============================================================================
  SUBROUTINE RT_MF_Staggered_Loop(desc, state, algo, ctx, err_status)
    TYPE(RT_MF_Coupling_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Algo),   INTENT(INOUT) :: algo
    TYPE(RT_MF_Coupling_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),          INTENT(INOUT) :: err_status

    INTEGER(i4) :: ifield, field_id

    state%coup_status = RT_MF_STATE_ITERATING
    state%coup_iter = 1_i4   ! Staggered: exactly one iteration per increment

    !-- §FIELD SEQUENTIAL SOLVE
    !   For Phase-1 STR↔THM:
    !     1. Solve STR (mechanical) → displacement u, stress σ, ε̇_p
    !     2. Exchange: σ:ε̇_p → THM via PH_Thm_HeatGen (Taylor-Quinney)
    !     3. Solve THM (thermal)   → temperature T, heat flux q
    !     4. Exchange: T → STR via thermal expansion ε_th = α·ΔT
    DO ifield = 1, desc%n_fields
      field_id = desc%field_ids(ifield)
      CALL RT_MF_Solve_SingleField(field_id, desc, state, algo, ctx, err_status)
    END DO

    !-- §INTERFACE EXCHANGE
    CALL RT_MF_Exchange_Interface(desc, state, ctx, err_status)

    !-- §COUPLING CONVERGENCE CHECK
    CALL RT_MF_ConvCheck_Coupling(desc, state, algo, ctx, err_status)

    !-- §AITKEN ACCELERATION (optional)
    IF (algo%use_aitken) THEN
      CALL RT_MF_Aitken_Accelerate(state, algo)
    END IF

    CALL init_error_status(err_status, IF_STATUS_OK)
  END SUBROUTINE RT_MF_Staggered_Loop

  !============================================================================
  ! RT_MF_PartIter_Loop — Partitioned Iterative (stronger coupling)
  !   Outer coupling loop: iterate field solves until interface residual converges.
  !   max_coup_iter > 1 (typically 5-20 for FSI, 10-50 for THM).
  !============================================================================
  SUBROUTINE RT_MF_PartIter_Loop(desc, state, algo, ctx, err_status)
    TYPE(RT_MF_Coupling_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Algo),   INTENT(INOUT) :: algo
    TYPE(RT_MF_Coupling_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),          INTENT(INOUT) :: err_status

    INTEGER(i4) :: k

    state%coup_status = RT_MF_STATE_ITERATING

    !-- §OUTER COUPLING LOOP
    outer_loop: DO k = 1, algo%max_coup_iter
      state%coup_iter = k

      !-- §FIELD SEQUENTIAL SOLVE (same as Staggered, but inside iteration)
      DO ifield = 1, desc%n_fields
        CALL RT_MF_Solve_SingleField(desc%field_ids(ifield), desc, state, algo, ctx, err_status)
      END DO

      !-- §INTERFACE EXCHANGE
      CALL RT_MF_Exchange_Interface(desc, state, ctx, err_status)

      !-- §COUPLING CONVERGENCE CHECK
      CALL RT_MF_ConvCheck_Coupling(desc, state, algo, ctx, err_status)

      IF (state%coup_converged) THEN
        state%coup_status = RT_MF_STATE_CONVERGED
        EXIT outer_loop
      END IF

      !-- Aitken relaxation
      IF (algo%use_aitken) CALL RT_MF_Aitken_Accelerate(state, algo)

    END DO outer_loop

    !-- Check: did we exit due to convergence or max_iter?
    IF (.NOT. state%coup_converged .AND. state%coup_iter >= algo%max_coup_iter) THEN
      state%coup_status = RT_MF_STATE_MAX_ITER
    END IF

    CALL init_error_status(err_status, IF_STATUS_OK)
  END SUBROUTINE RT_MF_PartIter_Loop

  !============================================================================
  ! RT_MF_Monolithic_Loop — Monolithic (unified block system)
  !   Assembles all field equations into a single block system:
  !   [K_11  K_12  K_13] [Δu ]   [R_1]
  !   [K_21  K_22  K_23] [ΔT ] = [R_2]
  !   [K_31  K_32  K_33] [Δφ ]   [R_3]
  !   Calls L2_NM linear solver on the unified block matrix.
  !   Stub: requires L2_NM block matrix assembly interface.
  !============================================================================
  SUBROUTINE RT_MF_Monolithic_Loop(desc, state, algo, ctx, err_status)
    TYPE(RT_MF_Coupling_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Algo),   INTENT(INOUT) :: algo
    TYPE(RT_MF_Coupling_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),          INTENT(INOUT) :: err_status

    CHARACTER(LEN=256) :: errmsg

    state%coup_status = RT_MF_STATE_ITERATING

    !-- §BLOCK SYSTEM ASSEMBLY
    !   DO ifield = 1, desc%n_fields
    !     CALL RT_MF_Assemble_Block_K(ifield, ifield, ctx)  ! diagonal K_ii
    !     DO jfield = 1, desc%n_fields
    !       IF (desc%coup_matrix(ifield, jfield)) THEN
    !         CALL RT_MF_Assemble_Block_K(ifield, jfield, ctx)  ! off-diagonal K_ij
    !       END IF
    !     END DO
    !   END DO
    !
    !-- §UNIFIED LINEAR SOLVE
    !   CALL L2_NM_BlockSolve(ctx%dof_total, ctx%dof_offset, &
    !                         K_block, R_vector, X_solution, algo%mono_linsol)
    !
    !-- Mark converged (single solve = always converged at this level)
    state%coup_status = RT_MF_STATE_CONVERGED
    state%coup_converged = .TRUE.
    state%coup_iter = 1_i4

    CALL init_error_status(err_status, IF_STATUS_WARN)
    errmsg = 'RT_MF_Monolithic_Loop: STUB — block assembly not implemented'
    ! TODO: implement block assembly when L2_NM block interface is ready

  END SUBROUTINE RT_MF_Monolithic_Loop

  !============================================================================
  ! RT_MF_Solve_SingleField — Solve one physics field
  !   Routes to the appropriate field solver based on field_id.
  !
  ! Field ID routing:
  !   RT_MF_FIELD_STR → RT_Str_StepDriver   (structural)
  !   RT_MF_FIELD_THM → RT_Thm_StepDriver   (thermal)
  !   RT_MF_FIELD_FLD → RT_Fld_StepDriver   (CFD / fluid)
  !   RT_MF_FIELD_DIF → RT_Dif_StepDriver   (diffusion)
  !   RT_MF_FIELD_EM  → RT_EM_StepDriver   (electromagnetic)
  !   RT_MF_FIELD_ACO → RT_Aco_StepDriver   (acoustic)
  !============================================================================
  SUBROUTINE RT_MF_Solve_SingleField(field_id, desc, state, algo, ctx, err_status)
    INTEGER(i4),                   INTENT(IN)    :: field_id
    TYPE(RT_MF_Coupling_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Algo),   INTENT(INOUT) :: algo
    TYPE(RT_MF_Coupling_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),          INTENT(INOUT) :: err_status

    CHARACTER(LEN=256) :: errmsg

    SELECT CASE (field_id)

    CASE (RT_MF_FIELD_STR)
      ! CALL RT_Str_StepDriver(desc, state, algo, ctx)  ! STUB
      state%field_converged(RT_MF_FIELD_STR) = .TRUE.
      state%field_pnewdt(RT_MF_FIELD_STR) = 1.0_wp

    CASE (RT_MF_FIELD_THM)
      ! CALL RT_Thm_StepDriver(desc, state, algo, ctx)  ! STUB
      state%field_converged(RT_MF_FIELD_THM) = .TRUE.
      state%field_pnewdt(RT_MF_FIELD_THM) = 1.0_wp

    CASE (RT_MF_FIELD_FLD)
      ! CALL RT_Fld_StepDriver(desc, state, algo, ctx)  ! STUB
      state%field_converged(RT_MF_FIELD_FLD) = .TRUE.
      state%field_pnewdt(RT_MF_FIELD_FLD) = 1.0_wp

    CASE (RT_MF_FIELD_DIF)
      ! CALL RT_Dif_StepDriver(desc, state, algo, ctx)  ! STUB
      state%field_converged(RT_MF_FIELD_DIF) = .TRUE.
      state%field_pnewdt(RT_MF_FIELD_DIF) = 1.0_wp

    CASE (RT_MF_FIELD_EM)
      ! CALL RT_EM_StepDriver(desc, state, algo, ctx)  ! STUB
      state%field_converged(RT_MF_FIELD_EM) = .TRUE.
      state%field_pnewdt(RT_MF_FIELD_EM) = 1.0_wp

    CASE (RT_MF_FIELD_ACO)
      ! CALL RT_Aco_StepDriver(desc, state, algo, ctx)  ! STUB
      state%field_converged(RT_MF_FIELD_ACO) = .TRUE.
      state%field_pnewdt(RT_MF_FIELD_ACO) = 1.0_wp

    CASE DEFAULT
      errmsg = 'RT_MF_Solve_SingleField: unknown field_id'
      CALL init_error_status(err_status, IF_STATUS_ERROR)
      RETURN
    END SELECT

    !-- Aggregate pnewdt across fields
    state%pnewdt_min = MINVAL(state%field_pnewdt(1:desc%n_fields))
    !-- All fields converged?
    state%all_fields_converged = ALL(state%field_converged(1:desc%n_fields))

    CALL init_error_status(err_status, IF_STATUS_OK)
  END SUBROUTINE RT_MF_Solve_SingleField

  !============================================================================
  ! RT_MF_Exchange_Interface — Exchange field quantities across interface
  !
  ! Phase-1 STR↔THM implementation:
  !   STR→THM: σ:ε̇_p → RPL [W/m³]  (via PH_Thm_Hetval)
  !   THM→STR: T → thermal strain ε_th = α·ΔT·I
  !
  ! Phase-2 FSI implementation:
  !   STR→FLD: u → v_bc,  σ·n → p_bc
  !   FLD→STR: p → F_ext
  !
  ! Phase-3 EM→THM:
  !   EM→THM: J²/σ_e → RPL_joule
  !============================================================================
  SUBROUTINE RT_MF_Exchange_Interface(desc, state, ctx, err_status)
    TYPE(RT_MF_Coupling_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),          INTENT(INOUT) :: err_status

    INTEGER(i4) :: ip, src_id, dst_id, qty_type

    DO ip = 1, desc%n_pairs
      IF (.NOT. desc%pairs(ip)%active) CYCLE

      src_id = desc%pairs(ip)%src_field_id
      dst_id = desc%pairs(ip)%dst_field_id
      qty_type = desc%pairs(ip)%qty_type

      SELECT CASE (qty_type)

      CASE (RT_MF_QTY_DISP)
        ! STR→FLD: structural displacement → CFD velocity BC
        ! CALL RT_MF_STR2FLD_Exchange(ctx%bufs(ip))

      CASE (RT_MF_QTY_HEATGEN)
        ! STR→THM: plastic dissipation → volumetric heat source (Taylor-Quinney)
        ! CALL RT_MF_STR2THM_Hetval_Exchange(ctx%bufs(ip), desc%pairs(ip)%scale_factor)

      CASE (RT_MF_QTY_TEMP)
        ! THM→STR: temperature → thermal strain
        ! CALL RT_MF_THM2STR_Texp_Exchange(ctx%bufs(ip), desc%pairs(ip)%scale_factor)

      CASE (RT_MF_QTY_JOULE)
        ! EM→THM: Joule heating
        ! CALL RT_MF_EM2THM_Joule_Exchange(ctx%bufs(ip))

      CASE DEFAULT
        ! Unknown qty_type — skip (extensible for future channels)
        CYCLE
      END SELECT

    END DO

    CALL init_error_status(err_status, IF_STATUS_OK)
  END SUBROUTINE RT_MF_Exchange_Interface

  !============================================================================
  ! RT_MF_ConvCheck_Coupling — Evaluate coupling convergence
  !   Computes: ||Φ^k - Φ^{k-1}|| / ||Φ^1||
  !   where Φ is the interface exchanged quantity (per pair).
  !   Updates state%coup_converged and state%coup_res_rel.
  !============================================================================
  SUBROUTINE RT_MF_ConvCheck_Coupling(desc, state, algo, ctx, err_status)
    TYPE(RT_MF_Coupling_Desc),   INTENT(INOUT) :: desc
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Algo),   INTENT(INOUT) :: algo
    TYPE(RT_MF_Coupling_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),          INTENT(INOUT) :: err_status

    REAL(wp) :: norm_diff, norm_ref, pair_norm
    INTEGER(i4) :: ip, ndof, nnode

    state%coup_converged = .FALSE.
    norm_diff = 0.0_wp
    norm_ref = 0.0_wp

    DO ip = 1, desc%n_pairs
      IF (.NOT. desc%pairs(ip)%active) CYCLE
      IF (.NOT. ALLOCATED(ctx%bufs(ip)%recv_buf)) CYCLE
      IF (.NOT. ALLOCATED(ctx%bufs(ip)%recv_prev)) CYCLE

      nnode = ctx%bufs(ip)%pop%n_nodes
      ndof  = ctx%bufs(ip)%pop%n_dof

      !-- L2 norm of change: ||Φ^k - Φ^{k-1}||
      pair_norm = 0.0_wp
      CALL compute_L2_norm_pair(ctx%bufs(ip)%recv_buf, &
                                ctx%bufs(ip)%recv_prev, &
                                nnode, ndof, pair_norm)
      ctx%norm_buf(ip) = pair_norm

      IF (state%coup_iter == 1_i4) THEN
        norm_ref = norm_ref + pair_norm**2  ! reference from first iteration
      ELSE
        norm_diff = norm_diff + pair_norm**2
      END IF

      state%pair_res_abs(ip) = pair_norm
    END DO

    !-- Relative norm
    IF (state%coup_iter == 1_i4) THEN
      norm_ref = SQRT(norm_ref)
      state%coup_res_ref = MAX(norm_ref, 1.0e-30_wp)
      state%coup_res_abs = 0.0_wp
      state%coup_res_rel = 1.0_wp
    ELSE
      norm_diff = SQRT(norm_diff)
      state%coup_res_abs = norm_diff
      state%coup_res_rel = norm_diff / MAX(state%coup_res_ref, 1.0e-30_wp)
    END IF

    !-- Convergence criterion
    IF (state%coup_res_rel <= algo%eps_coup_rel) THEN
      state%coup_converged = .TRUE.
    END IF

    CALL init_error_status(err_status, IF_STATUS_OK)

  CONTAINS
    SUBROUTINE compute_L2_norm_pair(A, B, nnode, ndof, norm)
      REAL(wp), INTENT(IN)  :: A(nnode, ndof), B(nnode, ndof)
      INTEGER(i4), INTENT(IN) :: nnode, ndof
      REAL(wp), INTENT(OUT) :: norm
      REAL(wp) :: diff
      norm = 0.0_wp
      DO j = 1, ndof
        DO i = 1, nnode
          diff = A(i,j) - B(i,j)
          norm = norm + diff*diff
        END DO
      END DO
      norm = SQRT(norm)
    END SUBROUTINE compute_L2_norm_pair
  END SUBROUTINE RT_MF_ConvCheck_Coupling

  !============================================================================
  ! RT_MF_Aitken_Accelerate — Aitken Δ² acceleration for Partitioned Iterative
  !   ω_{k+1} = ω_k - (ω_k - ω_{k-1}) · (Δ_k · Δ_{k-1}) / ||Δ_k - Δ_{k-1}||²
  !   Applied to interface quantities for faster convergence (especially FSI).
  !   Stub: requires iteration history buffer.
  !============================================================================
  SUBROUTINE RT_MF_Aitken_Accelerate(state, algo)
    TYPE(RT_MF_Coupling_State), INTENT(INOUT) :: state
    TYPE(RT_MF_Coupling_Algo),   INTENT(INOUT) :: algo

    ! Stub: Aitken acceleration requires storing Δ^{k-1} and ω^{k-1}
    ! for the formula:
    !   ω^{k+1} = ω^k - (ω^k - ω^{k-1}) * (Δ^k · Δ^{k-1}) / ||Δ^k - Δ^{k-1}||²
    ! This is Phase-2 implementation.
    ! For now: use fixed omega = algo%aitken_omega_0
    state%aitken_omega = algo%aitken_omega_0

  END SUBROUTINE RT_MF_Aitken_Accelerate

END MODULE RT_MF_Coordinator