!===============================================================================
! MODULE: RT_Asm_Core
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Core
! BRIEF:  Global assembly scatter/apply/residual operations (hot-path P2)
!===============================================================================
!
! Theory:  K_global += L_e^T * K_e * L_e   (element-by-element scatter)
!          F_global += L_e^T * F_e
!
! Partial Pillar: H3 Assembly (AUTHORITY types: RT_Asm_Def.f90)
!
! FACADE NOTE (v4.0): Four-type-style assembly facade.
!   GOLDEN-LINE assembly is RT_Asm_Solv.f90 (production global assembly hub).
!   This module provides clean scatter/apply/residual operations with
!   RT_Asm_Def four-type bundles.
!
! Status: FACADE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Asm_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Asm_Def, ONLY: RT_Asm_Desc, RT_Asm_State, RT_Asm_Algo, RT_Asm_Ctx, &
                         RT_Asm_Arg
  USE RT_Asm_Execute, ONLY: RT_Asm_Execute_Flow, &
                            RT_Asm_S1_MapDof, RT_Asm_S2_ElemLoop, &
                            RT_Asm_S3_Scatter, RT_Asm_S4_ApplyBC
  IMPLICIT NONE
  PRIVATE

  !-- Standardized 4-step flow (NEW entry point)
  PUBLIC :: RT_Asm_Execute_Flow
  PUBLIC :: RT_Asm_S1_MapDof
  PUBLIC :: RT_Asm_S2_ElemLoop
  PUBLIC :: RT_Asm_S3_Scatter
  PUBLIC :: RT_Asm_S4_ApplyBC

  !-- Legacy core operations (kept for backward compatibility)
  PUBLIC :: RT_Asm_Core_Init
  PUBLIC :: RT_Asm_Core_Zero_System
  PUBLIC :: RT_Asm_Core_Scatter_Ke
  PUBLIC :: RT_Asm_Core_Scatter_Fe
  PUBLIC :: RT_Asm_Core_Scatter_Me
  PUBLIC :: RT_Asm_Core_Scatter_Ce
  PUBLIC :: RT_Asm_Core_Apply_BC
  PUBLIC :: RT_Asm_Core_Apply_MPC
  PUBLIC :: RT_Asm_Core_Apply_Contact
  PUBLIC :: RT_Asm_Core_Compute_Residual
  PUBLIC :: RT_Asm_Core_Finalize

  PUBLIC :: RT_Asm_Core_Build_DofMap
  PUBLIC :: RT_Asm_Core_Assemble_K
  PUBLIC :: RT_Asm_Core_Assemble_F
  PUBLIC :: RT_Asm_Core_Assemble_M
  PUBLIC :: RT_Asm_Core_Apply_Constraints

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Init
  ! PHASE:      P0
  ! PURPOSE:    Set up assembly state from descriptor
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Init(desc, algo, state, ctx, status)
    TYPE(RT_Asm_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Asm_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    state%total_elements = desc%elem_end - desc%elem_start + 1
    state%assembled_elements = 0
    state%n_constraints_applied = 0
    state%assembly_fraction = 0.0_wp

    CALL ctx%ClearElementData()

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Init

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Zero_System
  ! PHASE:      P0
  ! PURPOSE:    Zero global K/M/C/F before assembly pass
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Zero_System(state, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (ASSOCIATED(state%K_global)) state%K_global = 0.0_wp
    IF (ASSOCIATED(state%M_global)) state%M_global = 0.0_wp
    IF (ASSOCIATED(state%C_global)) state%C_global = 0.0_wp
    IF (ASSOCIATED(state%f_global)) state%f_global = 0.0_wp

    state%assembled_elements = 0
    state%assembly_fraction  = 0.0_wp

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Zero_System

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Scatter_Ke
  ! PHASE:      P2
  ! PURPOSE:    Scatter element Ke into global K via DOF map | HOT_PATH O(ndof_e^2)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Scatter_Ke(state, Ke, dof_map, ndof_e, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    REAL(wp),           INTENT(IN)    :: Ke(:,:)
    INTEGER(i4),        INTENT(IN)    :: dof_map(:)
    INTEGER(i4),        INTENT(IN)    :: ndof_e
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, gi, gj

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(state%K_global)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Asm_Core_Scatter_Ke]: K_global not attached"
      RETURN
    END IF

    DO j = 1, ndof_e
      gj = dof_map(j)
      DO i = 1, ndof_e
        gi = dof_map(i)
        state%K_global(gi, gj) = state%K_global(gi, gj) + Ke(i,j)
      END DO
    END DO

    state%assembled_elements = state%assembled_elements + 1
    IF (state%total_elements > 0) THEN
      state%assembly_fraction = REAL(state%assembled_elements, wp) &
                              / REAL(state%total_elements, wp)
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Scatter_Ke

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Scatter_Fe
  ! PHASE:      P2
  ! PURPOSE:    Scatter element Fe into global F via DOF map | HOT_PATH O(ndof_e)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Scatter_Fe(state, Fe, dof_map, ndof_e, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    REAL(wp),           INTENT(IN)    :: Fe(:)
    INTEGER(i4),        INTENT(IN)    :: dof_map(:)
    INTEGER(i4),        INTENT(IN)    :: ndof_e
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, gi

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(state%f_global)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Asm_Core_Scatter_Fe]: f_global not attached"
      RETURN
    END IF

    DO i = 1, ndof_e
      gi = dof_map(i)
      state%f_global(gi) = state%f_global(gi) + Fe(i)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Scatter_Fe

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Scatter_Me
  ! PHASE:      P2
  ! PURPOSE:    Scatter element Me into global M via DOF map
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Scatter_Me(state, Me, dof_map, ndof_e, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    REAL(wp),           INTENT(IN)    :: Me(:,:)
    INTEGER(i4),        INTENT(IN)    :: dof_map(:)
    INTEGER(i4),        INTENT(IN)    :: ndof_e
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, gi, gj

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(state%M_global)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Asm_Core_Scatter_Me]: M_global not attached"
      RETURN
    END IF

    DO j = 1, ndof_e
      gj = dof_map(j)
      DO i = 1, ndof_e
        gi = dof_map(i)
        state%M_global(gi, gj) = state%M_global(gi, gj) + Me(i,j)
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Scatter_Me

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Scatter_Ce
  ! PHASE:      P2
  ! PURPOSE:    Scatter element Ce into global C via DOF map | HOT_PATH O(ndof_e^2)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Scatter_Ce(state, Ce, dof_map, ndof_e, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    REAL(wp),           INTENT(IN)    :: Ce(:,:)
    INTEGER(i4),        INTENT(IN)    :: dof_map(:)
    INTEGER(i4),        INTENT(IN)    :: ndof_e
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, gi, gj

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(state%C_global)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Asm_Core_Scatter_Ce]: C_global not attached"
      RETURN
    END IF

    DO j = 1, ndof_e
      gj = dof_map(j)
      DO i = 1, ndof_e
        gi = dof_map(i)
        state%C_global(gi, gj) = state%C_global(gi, gj) + Ce(i,j)
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Scatter_Ce

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Apply_BC
  ! PHASE:      P2
  ! PURPOSE:    Apply Dirichlet BCs via penalty method
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Apply_BC(state, ctx, n_bc, bc_dofs, bc_values, &
                                   status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Ctx),   INTENT(INOUT) :: ctx
    INTEGER(i4),        INTENT(IN)    :: n_bc
    INTEGER(i4),        INTENT(IN)    :: bc_dofs(:)
    REAL(wp),           INTENT(IN)    :: bc_values(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: ibc, dof, n_total, i
    REAL(wp)    :: max_diag, penalty

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(state%K_global) .OR. .NOT. ASSOCIATED(state%f_global)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Asm_Core_Apply_BC]: K/F not attached"
      RETURN
    END IF

    n_total = SIZE(state%f_global)

    max_diag = 0.0_wp
    DO i = 1, n_total
      IF (ABS(state%K_global(i,i)) > max_diag) max_diag = ABS(state%K_global(i,i))
    END DO
    IF (max_diag < 1.0E-30_wp) max_diag = 1.0_wp
    penalty = 1.0E20_wp * max_diag

    DO ibc = 1, n_bc
      dof = bc_dofs(ibc)
      IF (dof < 1 .OR. dof > n_total) CYCLE

      DO i = 1, n_total
        IF (i /= dof) THEN
          state%f_global(i) = state%f_global(i) &
            - state%K_global(i, dof) * bc_values(ibc)
          state%K_global(i, dof) = 0.0_wp
          state%K_global(dof, i) = 0.0_wp
        END IF
      END DO
      state%K_global(dof, dof) = penalty
      state%f_global(dof)      = penalty * bc_values(ibc)
    END DO

    state%n_constraints_applied = n_bc
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Apply_BC

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Compute_Residual
  ! PHASE:      P2
  ! PURPOSE:    Compute residual R = F_ext - K*u
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Compute_Residual(state, ctx, u, R, rnorm, status)
    TYPE(RT_Asm_State), INTENT(IN)    :: state
    TYPE(RT_Asm_Ctx),   INTENT(IN)    :: ctx
    REAL(wp),           INTENT(IN)    :: u(:)
    REAL(wp),           INTENT(OUT)   :: R(:)
    REAL(wp),           INTENT(OUT)   :: rnorm
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, n

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(state%K_global) .OR. .NOT. ASSOCIATED(state%f_global)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Asm_Core_Compute_Residual]: K/F not attached"
      RETURN
    END IF

    n = SIZE(u)

    DO i = 1, n
      R(i) = state%f_global(i)
      DO j = 1, n
        R(i) = R(i) - state%K_global(i,j) * u(j)
      END DO
    END DO

    rnorm = 0.0_wp
    DO i = 1, n
      rnorm = rnorm + R(i) * R(i)
    END DO
    rnorm = SQRT(rnorm)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Compute_Residual

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Reset state and clear context
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Finalize(state, ctx, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    CALL state%Reset()
    CALL ctx%ClearElementData()
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Finalize

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Build_DofMap
  ! PHASE:      P1
  ! PURPOSE:    Compute global DOF indices for one element
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Build_DofMap(desc, ctx, connectivity, &
                                       n_elem, n_nodes_per_elem, status)
    TYPE(RT_Asm_Desc), INTENT(IN)     :: desc
    TYPE(RT_Asm_Ctx),  INTENT(INOUT)  :: ctx
    INTEGER(i4),       INTENT(IN)     :: connectivity(:,:)
    INTEGER(i4),       INTENT(IN)     :: n_elem
    INTEGER(i4),       INTENT(IN)     :: n_nodes_per_elem
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    state_n_assembled_dofs_placeholder: BLOCK
    END BLOCK state_n_assembled_dofs_placeholder
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Build_DofMap

  !---------------------------------------------------------------------------
  ! Legacy wrappers (delegate to scatter routines)
  !---------------------------------------------------------------------------

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Assemble_K
  ! PHASE:      P2
  ! PURPOSE:    Legacy wrapper -- scatter ctx%elem_ke into global K
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Assemble_K(desc, algo, state, ctx, status)
    TYPE(RT_Asm_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Asm_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    CALL RT_Asm_Core_Scatter_Ke(state, ctx%elem_ke, ctx%elem_dof_map, &
                                 24_i4, status)
  END SUBROUTINE RT_Asm_Core_Assemble_K

  SUBROUTINE RT_Asm_Core_Assemble_F(desc, algo, state, ctx, status)
    TYPE(RT_Asm_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Asm_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    CALL RT_Asm_Core_Scatter_Fe(state, ctx%elem_fe, ctx%elem_dof_map, &
                                 24_i4, status)
  END SUBROUTINE RT_Asm_Core_Assemble_F

  SUBROUTINE RT_Asm_Core_Assemble_M(desc, algo, state, ctx, rho, status)
    TYPE(RT_Asm_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Asm_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Ctx),   INTENT(INOUT) :: ctx
    REAL(wp),           INTENT(IN)    :: rho
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    CALL RT_Asm_Core_Scatter_Me(state, ctx%elem_me, ctx%elem_dof_map, &
                                 24_i4, status)
  END SUBROUTINE RT_Asm_Core_Assemble_M

  SUBROUTINE RT_Asm_Core_Apply_Constraints(state, ctx, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ! Delegate to Apply_BC if constraints are stored in desc
    ! Constraint application is handled via RT_Asm_Core_Apply_BC
    ! and RT_Asm_Core_Apply_MPC at the orchestration level
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Apply_Constraints

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Apply_MPC
  ! PHASE:      P2
  ! PURPOSE:    Multi-Point Constraint via penalty transformation method
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Apply_MPC(state, n_mpc, slave_dofs, master_dofs, &
                                    coefficients, rhs_values, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    INTEGER(i4),        INTENT(IN)    :: n_mpc
    INTEGER(i4),        INTENT(IN)    :: slave_dofs(:)
    INTEGER(i4),        INTENT(IN)    :: master_dofs(:)
    REAL(wp),           INTENT(IN)    :: coefficients(:)
    REAL(wp),           INTENT(IN)    :: rhs_values(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: impc, sd, md, n_total, i
    REAL(wp)    :: coeff, rhs_val, penalty

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(state%K_global) .OR. .NOT. ASSOCIATED(state%f_global)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Asm_Core_Apply_MPC]: K/F not attached"
      RETURN
    END IF

    n_total = SIZE(state%f_global)
    penalty = 1.0E16_wp  ! MPC penalty parameter

    DO impc = 1, n_mpc
      sd = slave_dofs(impc)
      md = master_dofs(impc)
      coeff = coefficients(impc)
      rhs_val = rhs_values(impc)

      IF (sd < 1 .OR. sd > n_total .OR. md < 1 .OR. md > n_total) CYCLE
      IF (sd == md) CYCLE

      ! Penalty method for MPC: u_slave = coeff * u_master + rhs_val
      ! Add penalty terms:
      !   K(sd,sd) += penalty
      !   K(sd,md) -= penalty * coeff
      !   K(md,sd) -= penalty * coeff
      !   K(md,md) += penalty * coeff^2
      !   F(sd)    += penalty * rhs_val
      !   F(md)    -= penalty * coeff * rhs_val
      state%K_global(sd, sd) = state%K_global(sd, sd) + penalty
      state%K_global(sd, md) = state%K_global(sd, md) - penalty * coeff
      state%K_global(md, sd) = state%K_global(md, sd) - penalty * coeff
      state%K_global(md, md) = state%K_global(md, md) + penalty * coeff**2
      state%f_global(sd)     = state%f_global(sd) + penalty * rhs_val
      state%f_global(md)     = state%f_global(md) - penalty * coeff * rhs_val
    END DO

    state%n_constraints_applied = state%n_constraints_applied + n_mpc
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Apply_MPC

  !---------------------------------------------------------------------------
  ! SUBROUTINE: RT_Asm_Core_Apply_Contact
  ! PHASE:      P2
  ! PURPOSE:    Add contact K/F contributions into global system | HOT_PATH
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Asm_Core_Apply_Contact(state, Kc, Fc, dof_map_c, ndof_c, status)
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    REAL(wp),           INTENT(IN)    :: Kc(:,:)
    REAL(wp),           INTENT(IN)    :: Fc(:)
    INTEGER(i4),        INTENT(IN)    :: dof_map_c(:)
    INTEGER(i4),        INTENT(IN)    :: ndof_c
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, gi, gj

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(state%K_global) .OR. .NOT. ASSOCIATED(state%f_global)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Asm_Core_Apply_Contact]: K/F not attached"
      RETURN
    END IF

    ! Scatter contact stiffness contribution
    DO j = 1, ndof_c
      gj = dof_map_c(j)
      DO i = 1, ndof_c
        gi = dof_map_c(i)
        state%K_global(gi, gj) = state%K_global(gi, gj) + Kc(i,j)
      END DO
    END DO

    ! Scatter contact force contribution
    DO i = 1, ndof_c
      gi = dof_map_c(i)
      state%f_global(gi) = state%f_global(gi) + Fc(i)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Core_Apply_Contact

END MODULE RT_Asm_Core
