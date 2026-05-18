!===============================================================================
! MODULE:  RT_BC_ReactionForce
! LAYER:   L5_RT
! DOMAIN:  BC
! ROLE:    Proc
! BRIEF:   BC penalty/elimination enforcement and reaction force computation.
!===============================================================================
MODULE RT_BC_ReactionForce
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                        IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: RT_BC_Apply_In
    INTEGER(i4) :: bc_id = 0
    INTEGER(i4) :: bc_type = 0
    INTEGER(i4) :: dof = 0
    INTEGER(i4) :: n_nodes = 0
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    REAL(wp), ALLOCATABLE :: bc_values(:)
    REAL(wp) :: magnitude = 0.0_wp
    REAL(wp) :: time = 0.0_wp
    INTEGER(i4) :: apply_method = 0
  END TYPE

  TYPE, PUBLIC :: RT_BC_Reaction_Out
    REAL(wp), ALLOCATABLE :: reactions(:)
    INTEGER(i4) :: n_reactions = 0
    REAL(wp) :: total_rx = 0.0_wp
    REAL(wp) :: total_ry = 0.0_wp
    REAL(wp) :: total_rz = 0.0_wp
    REAL(wp) :: total_energy = 0.0_wp
    LOGICAL :: computed = .FALSE.
  END TYPE

  PUBLIC :: RT_BC_Apply_Constraints
  PUBLIC :: RT_BC_Compute_Reactions
  PUBLIC :: RT_BC_Process_Element_Reactions

CONTAINS

  SUBROUTINE RT_BC_Apply_Constraints(inp, K_global, F_global, status)
    TYPE(RT_BC_Apply_In), INTENT(IN) :: inp
    REAL(wp), INTENT(INOUT) :: K_global(:,:), F_global(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, dof_idx, n_total_dof
    REAL(wp) :: pv

    CALL init_error_status(status)

    IF (.NOT. ALLOCATED(inp%node_ids)) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'No nodes'
      RETURN
    END IF

    n_total_dof = SIZE(F_global)
    pv = 1.0e20_wp

    SELECT CASE (inp%apply_method)

    CASE (1)
      DO i = 1, inp%n_nodes
        dof_idx = (i - 1) * 3 + inp%dof
        IF (dof_idx > 0 .AND. dof_idx <= n_total_dof) THEN
          K_global(dof_idx, dof_idx) = &
            K_global(dof_idx, dof_idx) + pv
          IF (ALLOCATED(inp%bc_values)) THEN
            F_global(dof_idx) = F_global(dof_idx) &
              + K_global(dof_idx, dof_idx) * inp%bc_values(i)
          END IF
        END IF
      END DO

    CASE (2)
      DO i = 1, inp%n_nodes
        dof_idx = (i - 1) * 3 + inp%dof
        IF (dof_idx > 0 .AND. dof_idx <= n_total_dof) THEN
          K_global(dof_idx, :) = 0.0_wp
          K_global(:, dof_idx) = 0.0_wp
          K_global(dof_idx, dof_idx) = 1.0_wp
          IF (ALLOCATED(inp%bc_values)) THEN
            F_global(dof_idx) = inp%bc_values(i)
          ELSE
            F_global(dof_idx) = 0.0_wp
          END IF
        END IF
      END DO

    CASE DEFAULT
      status%status_code = IF_STATUS_ERROR
      status%message = 'Invalid method'
      RETURN

    END SELECT

    CALL init_error_status(status)
  END SUBROUTINE

  SUBROUTINE RT_BC_Compute_Reactions(f_ext, f_reaction, status)
    REAL(wp), INTENT(IN) :: f_ext(:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: f_reaction(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: n

    CALL init_error_status(status)
    n = SIZE(f_ext)

    IF (ALLOCATED(f_reaction)) DEALLOCATE(f_reaction)
    ALLOCATE(f_reaction(n))
    f_reaction = f_ext
    CALL init_error_status(status)
  END SUBROUTINE

  SUBROUTINE RT_BC_Process_Element_Reactions(asm_inp, f_reaction, status)
    CLASS(*), INTENT(IN) :: asm_inp
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: f_reaction(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ALLOCATE(f_reaction(1))
    f_reaction = 0.0_wp
  END SUBROUTINE

END MODULE RT_BC_ReactionForce
