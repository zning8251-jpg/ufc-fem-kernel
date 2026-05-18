!==============================================================================!
! MODULE RT_Assembly_XXX_XXX_Proc                             [Template v1.0]
! Layer  : L5_RT  (When — run-time orchestration)
! Domain : Assembly
! Feature: XXX_XXX  ← replace with concrete assembly strategy name
!          e.g. RT_Assembly_Std_CSR_Proc (standard CSR sparse assembly)
!
! Purpose:
!   Performs element-by-element global stiffness/mass/load vector assembly
!   for one Newton-Raphson iteration.  Loops over active elements, calls the
!   L5_RT element dispatcher to retrieve Ke/Me/Fe, then scatters into the
!   global sparse matrix via DOF mapping.
!
! SIO-01  Six-parameter standard form (Principle #14):
!   (Am_Desc, Am_State, Am_Algo, Am_Ctx, args)
!   Am_Desc  ← TYPE(RT_Asm_Desc)   [Desc — assembly config, element ranges]
!   Am_State ← TYPE(RT_Asm_State)  [State — progress + global matrix ptrs]
!   Am_Algo  ← TYPE(RT_Asm_Algo)   [Algo — sparse format, parallel strategy]
!   Am_Ctx   ← TYPE(RT_Asm_Ctx)    [Ctx  — element-level temporaries]
!   args     ← TYPE(RT_XXX_Asm_Args)  unified [IN]/[OUT] bundle (INOUT)
!
! SIO-02  Single RT_XXX_Asm_Args; [IN]/[OUT] fields in comments.
! SIO-03  No dynamic memory allocation inside SUBROUTINE body.
! SIO-04  pnewdt: Assembly domain does NOT generate pnewdt (caller of UEL
!         handles pnewdt via RT_XXX_Elem_Proc which is called before assembly).
! SIO-05  args%status is the structured status object; init with
!         init_error_status(...) and inspect %status_code.
!
! Assembly sequence:
!   1. Zero global K, M, C, f (or K += for Modified Newton stiffness reuse)
!   2. Loop over elements [elem_start .. elem_end]
!      a. Extract nodal coordinates and DOF map
!      b. Call RT_XXX_Asm_ElemContrib → fills Ke(24,24), Me(24,24), Fe(24)
!      c. Apply Ke scaling / mass scaling (from Algo)
!      d. Scatter Ke → K_global via DOF-map (RT_XXX_Asm_Scatter)
!      e. Scatter Fe → f_global
!   3. Apply Dirichlet / prescribed BCs (zero row/col + RHS adjustment)
!   4. Update Am_State norms (||K||, ||f||)
!
! Module catalogue:
!   TYPE RT_XXX_Asm_Args       — unified [IN]/[OUT] bundle
!   SUBROUTINE RT_XXX_Asm_Apply      — public dispatcher (6-param SIO)
!   SUBROUTINE RT_XXX_Asm_ElemContrib — PRIVATE element K/M/f contribution
!   SUBROUTINE RT_XXX_Asm_Scatter     — PRIVATE element → global scatter
!   SUBROUTINE RT_XXX_Asm_ApplyBC     — PRIVATE Dirichlet BC application
!==============================================================================!
MODULE RT_XXX_Assembly_Proc
  USE IF_Prec_Core,             ONLY: wp, i4
  USE IF_Err_Brg,          ONLY: ErrorStatusType, init_error_status, &
                                  IF_STATUS_OK, IF_STATUS_WARN, IF_STATUS_ERROR
  USE RT_Assembly_Types,   ONLY: RT_Asm_Desc, RT_Asm_State, &
                                  RT_Asm_Algo,  RT_Asm_Ctx,  &
                                  RT_ASM_ASM_METHOD_ELEMENT_WISE,     &
                                  RT_ASM_ASM_SPARSE_CSR,              &
                                  RT_ASM_ASM_PARALLEL_SERIAL
  IMPLICIT NONE
  PRIVATE

  !-- Element max-DOF constant for stack-allocated arrays
  INTEGER(i4), PARAMETER :: MAX_NDOF_ELEM = 24_i4  ! C3D8: 8 nodes × 3 DOF
  INTEGER(i4), PARAMETER :: MAX_NODES_ELEM = 8_i4

  !============================================================================!
  ! TYPE RT_XXX_Asm_Args — unified assembly-call bundle (Principle #14)
  !============================================================================!
  TYPE, PUBLIC :: RT_XXX_Asm_Args
    !-- [IN] Iteration / scope / flags / pointers / topology / caches
    INTEGER(i4) :: step_id        = 0_i4
    INTEGER(i4) :: inc_id         = 0_i4
    INTEGER(i4) :: iter_id        = 0_i4
    REAL(wp)    :: step_time      = 0.0_wp
    REAL(wp)    :: dtime          = 0.0_wp
    INTEGER(i4) :: elem_start     = 1_i4
    INTEGER(i4) :: elem_end       = 0_i4  ! 0 = use Am_Desc%elem_end
    LOGICAL     :: assemble_stiffness = .TRUE.
    LOGICAL     :: assemble_mass      = .FALSE.
    LOGICAL     :: assemble_damping   = .FALSE.
    LOGICAL     :: assemble_loads     = .TRUE.
    LOGICAL     :: reuse_stiffness = .FALSE.
    REAL(wp), POINTER :: ext_load(:) => NULL()
    REAL(wp),    POINTER :: coords(:,:)    => NULL()
    INTEGER(i4), POINTER :: conn(:,:)      => NULL()
    INTEGER(i4), POINTER :: dof_map(:,:)   => NULL()
    INTEGER(i4)          :: n_nodes        = 0_i4
    INTEGER(i4)          :: n_dof_total    = 0_i4
    INTEGER(i4)          :: n_dof_per_node = 3_i4
    INTEGER(i4)          :: n_nodes_per_elem = MAX_NODES_ELEM
    REAL(wp), POINTER :: ddsdde_store(:,:,:) => NULL()
    REAL(wp), POINTER :: sigma_store(:,:)    => NULL()
    INTEGER(i4)       :: n_gp_total = 0_i4
    INTEGER(i4), POINTER :: constrained_dofs(:) => NULL()
    REAL(wp),    POINTER :: prescribed_vals(:)   => NULL()
    INTEGER(i4)          :: n_constrained = 0_i4
    INTEGER(i4) :: lflags(6) = 0_i4

    !-- [OUT] Status, stats, norms, timing, checks
    TYPE(ErrorStatusType) :: status            ! Structured status; check %status_code
    LOGICAL               :: success = .FALSE.
    INTEGER(i4) :: n_elem_assembled  = 0_i4
    INTEGER(i4) :: n_dof_assembled   = 0_i4
    INTEGER(i4) :: n_bc_applied      = 0_i4
    REAL(wp)    :: K_norm            = 0.0_wp
    REAL(wp)    :: f_norm            = 0.0_wp
    REAL(wp)    :: M_norm            = 0.0_wp
    REAL(wp)    :: asm_cpu_time      = 0.0_wp
    REAL(wp)    :: scatter_cpu_time  = 0.0_wp
    LOGICAL     :: K_has_zero_diag   = .FALSE.
  END TYPE RT_XXX_Asm_Args

  PUBLIC :: RT_XXX_Asm_Apply

CONTAINS

  !============================================================================!
  ! SUBROUTINE RT_XXX_Asm_Apply                           [Public, 6-param SIO]
  !
  ! Global stiffness assembly for one Newton iteration.
  !
  ! Arguments (SIO-01):
  !   Am_Desc  [IN]    RT_Asm_Desc  — element range + matrix properties
  !   Am_State [INOUT] RT_Asm_State — progress + global matrix pointers
  !   Am_Algo  [IN]    RT_Asm_Algo  — sparse format + parallel strategy
  !   Am_Ctx   [INOUT] RT_Asm_Ctx   — element-level temporaries (stack)
  !   args     [INOUT] RT_XXX_Asm_Args — unified IO bundle
  !============================================================================!
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE RT_XXX_Asm_Apply(Am_Desc, Am_State, Am_Algo, Am_Ctx, args)
    TYPE(RT_Asm_Desc),      INTENT(IN)    :: Am_Desc
    TYPE(RT_Asm_State),     INTENT(INOUT) :: Am_State
    TYPE(RT_Asm_Algo),      INTENT(IN)    :: Am_Algo
    TYPE(RT_Asm_Ctx),       INTENT(INOUT) :: Am_Ctx
    TYPE(RT_XXX_Asm_Args),  INTENT(INOUT) :: args

    REAL(wp)    :: t_cpu_start, t_cpu_end, t_scatter_start, t_scatter_end
    INTEGER(i4) :: ielem, elem_start, elem_end
    INTEGER(i4) :: ndof_elem
    REAL(wp)    :: Ke(MAX_NDOF_ELEM, MAX_NDOF_ELEM)  ! Element stiffness (stack)
    REAL(wp)    :: Me(MAX_NDOF_ELEM, MAX_NDOF_ELEM)  ! Element mass (stack)
    REAL(wp)    :: Fe(MAX_NDOF_ELEM)                 ! Element RHS (stack)
    INTEGER(i4) :: dof_idx(MAX_NDOF_ELEM)            ! Global DOF indices (stack)

    !--------------------------------------------------------------------------!
    ! Step 0: Initialise output bundle
    !--------------------------------------------------------------------------!
    CALL init_error_status(args%status)
    args%success           = .FALSE.
    args%n_elem_assembled  = 0_i4
    args%n_dof_assembled   = 0_i4
    args%n_bc_applied      = 0_i4
    args%K_norm            = 0.0_wp
    args%f_norm            = 0.0_wp
    args%M_norm            = 0.0_wp
    args%asm_cpu_time      = 0.0_wp
    args%scatter_cpu_time  = 0.0_wp
    args%K_has_zero_diag   = .FALSE.

    CALL CPU_TIME(t_cpu_start)

    !--------------------------------------------------------------------------!
    ! Step 1: Validate global matrix pointers
    !--------------------------------------------------------------------------!
    IF (.NOT. ASSOCIATED(Am_State%K_global)) THEN
      args%status%status_code = IF_STATUS_ERROR
      args%status%message     = 'RT_XXX_Asm_Apply: K_global not associated'
      RETURN
    END IF
    IF (.NOT. ASSOCIATED(Am_State%f_global)) THEN
      args%status%status_code = IF_STATUS_ERROR
      args%status%message     = 'RT_XXX_Asm_Apply: f_global not associated'
      RETURN
    END IF

    !--------------------------------------------------------------------------!
    ! Step 2: Determine element range
    !--------------------------------------------------------------------------!
    elem_start = args%elem_start
    IF (args%elem_end > 0_i4) THEN
      elem_end = args%elem_end
    ELSE
      elem_end = Am_Desc%elem_end
    END IF

    IF (elem_end < elem_start) THEN
      args%status%status_code = IF_STATUS_WARN
      args%status%message     = 'RT_XXX_Asm_Apply: empty element range'
      args%success = .TRUE.
      CALL CPU_TIME(t_cpu_end)
      args%asm_cpu_time = t_cpu_end - t_cpu_start
      RETURN
    END IF

    !--------------------------------------------------------------------------!
    ! Step 3: Zero global arrays (skip if reusing stiffness for Modified Newton)
    !--------------------------------------------------------------------------!
    IF (.NOT. args%reuse_stiffness) THEN
      IF (args%assemble_stiffness) Am_State%K_global = 0.0_wp
    END IF
    IF (args%assemble_loads) Am_State%f_global = 0.0_wp
    IF (args%assemble_mass .AND. ASSOCIATED(Am_State%M_global)) THEN
      Am_State%M_global = 0.0_wp
    END IF
    IF (args%assemble_damping .AND. ASSOCIATED(Am_State%C_global)) THEN
      Am_State%C_global = 0.0_wp
    END IF

    !--------------------------------------------------------------------------!
    ! Step 4: Element loop — compute contributions and scatter
    !--------------------------------------------------------------------------!
    Am_State%total_elements = elem_end - elem_start + 1_i4
    ndof_elem = args%n_nodes_per_elem * args%n_dof_per_node
    IF (ndof_elem > MAX_NDOF_ELEM) ndof_elem = MAX_NDOF_ELEM  ! safety clamp

    DO ielem = elem_start, elem_end

      !-- 4a. Zero element arrays on stack
      Ke       = 0.0_wp
      Me       = 0.0_wp
      Fe       = 0.0_wp
      dof_idx  = 0_i4

      !-- 4b. Build element DOF index from connectivity + dof_map
      !       (uses Am_Ctx%elem_node_ids / elem_dof_map as scratch)
      CALL RT_XXX_Asm_BuildDOFIdx(args, ielem, ndof_elem, dof_idx)

      !-- 4c. Compute element Ke / Me / Fe contribution
      CALL RT_XXX_Asm_ElemContrib(Am_Desc, Am_Algo, Am_Ctx, &
                                    args, ielem, ndof_elem, Ke, Me, Fe)

      !-- 4d. Apply element-level scaling
      IF (Am_Algo%use_scaling) THEN
        Ke = Ke * Am_Algo%stiffness_scaling_factor
        Me = Me * Am_Algo%mass_scaling_factor
      END IF

      !-- 4e. Scatter into global arrays
      CALL CPU_TIME(t_scatter_start)
      CALL RT_XXX_Asm_Scatter(Am_State, Am_Algo, args, &
                               ndof_elem, dof_idx, Ke, Me, Fe)
      CALL CPU_TIME(t_scatter_end)
      args%scatter_cpu_time = args%scatter_cpu_time + (t_scatter_end - t_scatter_start)

      IF (args%status%status_code == IF_STATUS_ERROR) THEN
        CALL CPU_TIME(t_cpu_end)
        args%asm_cpu_time = t_cpu_end - t_cpu_start
        RETURN
      END IF

      !-- 4f. Update progress state
      Am_State%assembled_elements = Am_State%assembled_elements + 1_i4
      Am_State%current_elem       = ielem
      args%n_elem_assembled = args%n_elem_assembled + 1_i4
      args%n_dof_assembled  = args%n_dof_assembled  + ndof_elem

    END DO  ! ielem

    !-- Add external load contribution
    IF (args%assemble_loads .AND. ASSOCIATED(args%ext_load)) THEN
      Am_State%f_global = Am_State%f_global + args%ext_load
    END IF

    !--------------------------------------------------------------------------!
    ! Step 5: Apply Dirichlet / prescribed boundary conditions
    !--------------------------------------------------------------------------!
    IF (args%n_constrained > 0_i4 .AND. ASSOCIATED(args%constrained_dofs)) THEN
      CALL RT_XXX_Asm_ApplyBC(Am_State, args)
      IF (args%status%status_code == IF_STATUS_ERROR) THEN
        CALL CPU_TIME(t_cpu_end)
        args%asm_cpu_time = t_cpu_end - t_cpu_start
        RETURN
      END IF
    END IF

    !--------------------------------------------------------------------------!
    ! Step 6: Compute matrix norms (Frobenius approximation on diagonal)
    !--------------------------------------------------------------------------!
    IF (args%assemble_stiffness .AND. ASSOCIATED(Am_State%K_global)) THEN
      BLOCK
        INTEGER(i4) :: idiag
        REAL(wp)    :: diag_min
        args%K_norm = 0.0_wp
        diag_min   = HUGE(1.0_wp)
        DO idiag = 1, args%n_dof_total
          args%K_norm = args%K_norm + Am_State%K_global(idiag, idiag)**2
          IF (ABS(Am_State%K_global(idiag, idiag)) < diag_min) THEN
            diag_min = ABS(Am_State%K_global(idiag, idiag))
          END IF
        END DO
        args%K_norm = SQRT(args%K_norm)
        IF (diag_min < 1.0e-30_wp) args%K_has_zero_diag = .TRUE.
      END BLOCK
    END IF

    IF (args%assemble_loads .AND. ASSOCIATED(Am_State%f_global)) THEN
      args%f_norm = SQRT(DOT_PRODUCT(Am_State%f_global, Am_State%f_global))
    END IF

    Am_State%K_matrix_norm  = args%K_norm
    Am_State%f_vector_norm  = args%f_norm
    Am_State%assembly_fraction = 1.0_wp

    !--------------------------------------------------------------------------!
    ! Step 7: Finalise
    !--------------------------------------------------------------------------!
    CALL CPU_TIME(t_cpu_end)
    args%asm_cpu_time = t_cpu_end - t_cpu_start
    Am_State%assembly_time  = args%asm_cpu_time
    args%success = .TRUE.

  END SUBROUTINE RT_XXX_Asm_Apply


  !============================================================================!
  ! SUBROUTINE RT_XXX_Asm_BuildDOFIdx                             [PRIVATE]
  ! Builds global DOF index array for element ielem.
  !============================================================================!
  SUBROUTINE RT_XXX_Asm_BuildDOFIdx(args, ielem, ndof_elem, dof_idx)
    TYPE(RT_XXX_Asm_Args), INTENT(IN)  :: args
    INTEGER(i4),         INTENT(IN)  :: ielem, ndof_elem
    INTEGER(i4),         INTENT(OUT) :: dof_idx(ndof_elem)

    INTEGER(i4) :: inode_local, inode_global, idof_local, dof_slot

    dof_idx = 0_i4

    IF (.NOT. ASSOCIATED(args%conn)) RETURN
    IF (.NOT. ASSOCIATED(args%dof_map)) RETURN

    dof_slot = 0_i4
    DO inode_local = 1, args%n_nodes_per_elem
      inode_global = args%conn(inode_local, ielem)
      DO idof_local = 1, args%n_dof_per_node
        dof_slot = dof_slot + 1_i4
        IF (dof_slot > ndof_elem) EXIT
        dof_idx(dof_slot) = args%dof_map(idof_local, inode_global)
      END DO
    END DO

  END SUBROUTINE RT_XXX_Asm_BuildDOFIdx


  !============================================================================!
  ! SUBROUTINE RT_XXX_Asm_ElemContrib                             [PRIVATE]
  ! Computes element stiffness Ke, mass Me, and force Fe for element ielem.
  ! Uses pre-computed DDSDDE / sigma from args%ddsdde_store / sigma_store.
  !============================================================================!
  SUBROUTINE RT_XXX_Asm_ElemContrib(Desc, Algo, Ctx, args, ielem, &
                                      ndof_elem, Ke, Me, Fe)
    TYPE(RT_Asm_Desc),    INTENT(IN)    :: Desc
    TYPE(RT_Asm_Algo),    INTENT(IN)    :: Algo
    TYPE(RT_Asm_Ctx),     INTENT(INOUT) :: Ctx
    TYPE(RT_XXX_Asm_Args), INTENT(IN)    :: args
    INTEGER(i4),          INTENT(IN)    :: ielem, ndof_elem
    REAL(wp),             INTENT(OUT)   :: Ke(ndof_elem, ndof_elem)
    REAL(wp),             INTENT(OUT)   :: Me(ndof_elem, ndof_elem)
    REAL(wp),             INTENT(OUT)   :: Fe(ndof_elem)

    !-- Integration point loop stub
    !   In production: loop over Gauss points, evaluate B-matrix,
    !   Ke += w * det_J * B^T * D * B,  Fe += w * det_J * B^T * sigma
    !
    !   igp_offset = (ielem - 1) * n_gp_per_elem
    !   DO igp_local = 1, n_gp_per_elem
    !     igp_global = igp_offset + igp_local
    !     D(1:6,1:6) = args%ddsdde_store(1:6, 1:6, igp_global)
    !     sig(1:6)   = args%sigma_store(1:6, igp_global)
    !     CALL RT_XXX_Asm_ComputeB(Ctx, coords_local, igp_local, B, det_J, w)
    !     Ke = Ke + w * det_J * MATMUL(TRANSPOSE(B), MATMUL(D, B))
    !     Fe = Fe + w * det_J * MATMUL(TRANSPOSE(B), sig)
    !   END DO
    !
    !   Consistent mass matrix:
    !     Me = Me + w * det_J * rho * MATMUL(N_T, N) (if assemble_mass)

    Ke = 0.0_wp
    Me = 0.0_wp
    Fe = 0.0_wp

    !-- Copy Ctx element stiffness / force stubs
    Ke(1:ndof_elem, 1:ndof_elem) = Ctx%elem_ke(1:ndof_elem, 1:ndof_elem)
    Me(1:ndof_elem, 1:ndof_elem) = Ctx%elem_me(1:ndof_elem, 1:ndof_elem)
    Fe(1:ndof_elem)              = Ctx%elem_fe(1:ndof_elem)

  END SUBROUTINE RT_XXX_Asm_ElemContrib


  !============================================================================!
  ! SUBROUTINE RT_XXX_Asm_Scatter                                  [PRIVATE]
  ! Scatters element Ke / Me / Fe into global K / M / f via dof_idx.
  ! Dense scatter (production: use CSR row/col pointer for sparse storage).
  !============================================================================!
  SUBROUTINE RT_XXX_Asm_Scatter(State, Algo, args, &
                                  ndof_elem, dof_idx, Ke, Me, Fe)
    TYPE(RT_Asm_State),   INTENT(INOUT) :: State
    TYPE(RT_Asm_Algo),    INTENT(IN)    :: Algo
    TYPE(RT_XXX_Asm_Args), INTENT(INOUT) :: args
    INTEGER(i4),          INTENT(IN)    :: ndof_elem
    INTEGER(i4),          INTENT(IN)    :: dof_idx(ndof_elem)
    REAL(wp),             INTENT(IN)    :: Ke(ndof_elem, ndof_elem)
    REAL(wp),             INTENT(IN)    :: Me(ndof_elem, ndof_elem)
    REAL(wp),             INTENT(IN)    :: Fe(ndof_elem)

    INTEGER(i4) :: ii, jj, gi, gj

    !-- Stiffness scatter
    IF (args%assemble_stiffness .AND. ASSOCIATED(State%K_global)) THEN
      DO ii = 1, ndof_elem
        gi = dof_idx(ii)
        IF (gi <= 0_i4 .OR. gi > args%n_dof_total) CYCLE
        DO jj = 1, ndof_elem
          gj = dof_idx(jj)
          IF (gj <= 0_i4 .OR. gj > args%n_dof_total) CYCLE
          State%K_global(gi, gj) = State%K_global(gi, gj) + Ke(ii, jj)
        END DO
        !-- RHS: subtract internal force (K * u_trial term handled by Newton)
        IF (ASSOCIATED(State%f_global)) THEN
          State%f_global(gi) = State%f_global(gi) - Fe(ii)
        END IF
      END DO
    END IF

    !-- Mass scatter
    IF (args%assemble_mass .AND. ASSOCIATED(State%M_global)) THEN
      DO ii = 1, ndof_elem
        gi = dof_idx(ii)
        IF (gi <= 0_i4 .OR. gi > args%n_dof_total) CYCLE
        DO jj = 1, ndof_elem
          gj = dof_idx(jj)
          IF (gj <= 0_i4 .OR. gj > args%n_dof_total) CYCLE
          State%M_global(gi, gj) = State%M_global(gi, gj) + Me(ii, jj)
        END DO
      END DO
    END IF

  END SUBROUTINE RT_XXX_Asm_Scatter


  !============================================================================!
  ! SUBROUTINE RT_XXX_Asm_ApplyBC                                 [PRIVATE]
  ! Applies Dirichlet / prescribed BCs to the assembled global system.
  ! Strategy: zero row & column, set diagonal = 1, adjust RHS.
  !============================================================================!
  SUBROUTINE RT_XXX_Asm_ApplyBC(State, args)
    TYPE(RT_Asm_State),   INTENT(INOUT) :: State
    TYPE(RT_XXX_Asm_Args), INTENT(INOUT) :: args

    INTEGER(i4) :: ibc, gdof, jdof
    REAL(wp)    :: u_presc

    DO ibc = 1, args%n_constrained
      gdof   = args%constrained_dofs(ibc)
      u_presc = 0.0_wp
      IF (ASSOCIATED(args%prescribed_vals)) THEN
        u_presc = args%prescribed_vals(ibc)
      END IF

      IF (gdof <= 0_i4 .OR. gdof > args%n_dof_total) CYCLE

      IF (ASSOCIATED(State%K_global)) THEN
        !-- Adjust RHS for off-diagonal K columns
        DO jdof = 1, args%n_dof_total
          IF (jdof == gdof) CYCLE
          IF (ASSOCIATED(State%f_global)) THEN
            State%f_global(jdof) = State%f_global(jdof) - &
                                    State%K_global(jdof, gdof) * u_presc
          END IF
          State%K_global(gdof, jdof) = 0.0_wp
          State%K_global(jdof, gdof) = 0.0_wp
        END DO
        !-- Set diagonal to 1
        State%K_global(gdof, gdof) = 1.0_wp
      END IF

      !-- Set RHS to prescribed value
      IF (ASSOCIATED(State%f_global)) THEN
        State%f_global(gdof) = u_presc
      END IF

      args%n_bc_applied = args%n_bc_applied + 1_i4
    END DO

    State%n_constraints_applied = args%n_bc_applied

  END SUBROUTINE RT_XXX_Asm_ApplyBC

END MODULE RT_XXX_Assembly_Proc