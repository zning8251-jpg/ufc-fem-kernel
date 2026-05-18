!===============================================================================
! MODULE: PH_Constr_MPC
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Eval — core MPC algorithm implementations
! BRIEF:  Penalty/Lagrange/elimination enforcement for MPC constraint equations.
!===============================================================================
! Theory:
!   Penalty method:    K' = K + kappa * A^T * A,  F' = F + kappa * A^T * b
!   Lagrange method:   [K  C^T] [u]   [F]
!                      [C   0 ] [λ] = [g]
!   Elimination:       Direct removal of constrained DOFs
! Status:  CORE | Last verified: 2026-03-01
!
! Contents (A-Z):
!   Types:
!     - (None)
!   Subroutines:
!     - PH_Constr_MPCCore_AssembleLagrangeBlock
!     - PH_Constr_MPCCore_AssembleMatrix
!     - PH_Constr_MPCCore_AssemblePenalty
!     - PH_Constr_MPCCore_CheckConsistency
!     - PH_Constr_MPCCore_ComputeViolation
!     - PH_Constr_MPCCore_Opt
!   Functions:
!     - (None)
!===============================================================================

MODULE PH_Constr_MPC
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, SMALL_VAL => SMALL
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_ConstrMPC_Def
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! Public interface (only for API layer)
  ! ==========================================================================
  PUBLIC :: PH_Constr_MPCCore_AssembleMatrix
  PUBLIC :: PH_Constr_MPCCore_AssemblePenalty
  PUBLIC :: PH_Constr_MPCCore_AssembleLagrangeBlock
  PUBLIC :: PH_Constr_MPCCore_ComputeViolation
  PUBLIC :: PH_Constr_MPCCore_CheckConsistency
  PUBLIC :: PH_Constr_MPCCore_Opt

  !=============================================================================
  ! INTF-001 MPC
  ! Purpose: PH_Constr_MPCCore_AssemblePenalty(5 )
  ! Theory: : K' = K + κ·A^T·A F' = F + κ·A^T·b κ
  ! Status: Draft |
  !=============================================================================
  PUBLIC :: PH_Constr_MPCCore_PenaltyArgs
  TYPE :: PH_Constr_MPCCore_PenaltyArgs
    TYPE(PH_Constr_MPC_Def), POINTER :: mpc     => NULL()  !! MPC
    INTEGER(i4) :: n_dof_total = 0_i4  ! total constraint DoFs
    REAL(wp)    :: kappa       = 1.0e6_wp  !! κ
    REAL(wp), POINTER :: K(:,:) => NULL()  !! INOUT
    REAL(wp), POINTER :: R(:)   => NULL()  !! INOUT
  END TYPE PH_Constr_MPCCore_PenaltyArgs

CONTAINS

  SUBROUTINE PH_Constr_MPCCore_AssembleLagrangeBlock(mpc, n_dof_total, C_row)
    TYPE(PH_Constr_MPC_Def), INTENT(IN) :: mpc
    INTEGER(i4), INTENT(IN) :: n_dof_total
    REAL(wp), INTENT(OUT) :: C_row(:)

    INTEGER(i4) :: i_term, dof_i

    C_row = ZERO
    DO i_term = 1, mpc%n_terms
      dof_i = (mpc%node_ids(i_term) - 1) * mpc%ndof_per_node + mpc%dof_ids(i_term)
      IF (dof_i >= 1 .AND. dof_i <= n_dof_total) THEN
        C_row(dof_i) = C_row(dof_i) + mpc%coefficients(i_term)
      END IF
    END DO
  END SUBROUTINE PH_Constr_MPCCore_AssembleLagrangeBlock

  SUBROUTINE PH_Constr_MPCCore_AssembleMatrix(constraints, num_constraints, &
                                  constraint_matrix, rhs_vector)
    TYPE(MPC_Constraint), INTENT(IN) :: constraints(:)
    INTEGER(i4), INTENT(IN) :: num_constraints
    REAL(wp), INTENT(OUT) :: constraint_matrix(:,:)  ! (m, n_dof)
    REAL(wp), INTENT(OUT) :: rhs_vector(:)           ! (m)

    INTEGER(i4) :: i_constraint, i_term, dof_id
    TYPE(MPC_Term) :: term

    constraint_matrix = ZERO
    rhs_vector = ZERO

    ! Assemble constraint matrix
    DO i_constraint = 1, num_constraints
      IF (.NOT. constraints(i_constraint)%is_active) CYCLE

      ! Right-hand side
      rhs_vector(i_constraint) = constraints(i_constraint)%rhs_value

      ! Constraint coefficients
      DO i_term = 1, constraints(i_constraint)%num_terms
        term = constraints(i_constraint)%terms(i_term)

        ! Compute DOF ID (assuming 3 DOFs per node)
        dof_id = (term%node_id - 1) * 3 + term%dof_type

        constraint_matrix(i_constraint, dof_id) = term%coef
      END DO
    END DO

  END SUBROUTINE PH_Constr_MPCCore_AssembleMatrix

  SUBROUTINE PH_Constr_MPCCore_AssemblePenalty(mpc, n_dof_total, kappa, K, R)
    TYPE(PH_Constr_MPC_Def), INTENT(IN) :: mpc
    INTEGER(i4), INTENT(IN) :: n_dof_total
    REAL(wp), INTENT(IN) :: kappa
    REAL(wp), INTENT(INOUT) :: K(:,:)
    REAL(wp), INTENT(INOUT) :: R(:)

    INTEGER(i4) :: i_term, j_term, dof_i, dof_j
    REAL(wp) :: coeff_i, coeff_j

    IF (mpc%n_terms < 1) RETURN
    IF (SIZE(K,1) < n_dof_total .OR. SIZE(K,2) < n_dof_total) RETURN
    IF (SIZE(R) < n_dof_total) RETURN

    DO i_term = 1, mpc%n_terms
      dof_i = (mpc%node_ids(i_term) - 1) * mpc%ndof_per_node + mpc%dof_ids(i_term)
      IF (dof_i < 1 .OR. dof_i > n_dof_total) CYCLE
      coeff_i = mpc%coefficients(i_term)

      ! Stiffness contribution: K += kappa * A^T * A
      DO j_term = 1, mpc%n_terms
        dof_j = (mpc%node_ids(j_term) - 1) * mpc%ndof_per_node + mpc%dof_ids(j_term)
        IF (dof_j < 1 .OR. dof_j > n_dof_total) CYCLE
        coeff_j = mpc%coefficients(j_term)
        K(dof_i, dof_j) = K(dof_i, dof_j) + kappa * coeff_i * coeff_j
      END DO

      ! Force contribution (penalty linearization; sign tied to solver convention)
      R(dof_i) = R(dof_i) - kappa * coeff_i * mpc%rhs
    END DO
  END SUBROUTINE PH_Constr_MPCCore_AssemblePenalty

  SUBROUTINE PH_Constr_MPCCore_CheckConsistency(mpc, is_consistent, status)
    TYPE(PH_Constr_MPC_Def), INTENT(IN) :: mpc
    LOGICAL, INTENT(OUT) :: is_consistent
    INTEGER(i4), INTENT(OUT) :: status

    REAL(wp) :: sum_coeff

    status = 0_i4
    is_consistent = .TRUE.

    ! Check: sum of coefficients should not be zero for non-zero RHS
    sum_coeff = SUM(mpc%coefficients(1:mpc%n_terms))

    IF (ABS(mpc%rhs) > SMALL_VAL .AND. ABS(sum_coeff) < SMALL_VAL) THEN
      is_consistent = .FALSE.
      status = 1_i4
      RETURN
    END IF

    ! Check: at least one term required
    IF (mpc%n_terms < 1) THEN
      is_consistent = .FALSE.
      status = 2_i4
      RETURN
    END IF

  END SUBROUTINE PH_Constr_MPCCore_CheckConsistency

  SUBROUTINE PH_Constr_MPCCore_ComputeViolation(mpc, u_nodal, violation, status)
    TYPE(PH_Constr_MPC_Def), INTENT(IN) :: mpc
    REAL(wp), INTENT(IN) :: u_nodal(:)
    REAL(wp), INTENT(OUT) :: violation
    INTEGER(i4), INTENT(OUT) :: status

    INTEGER(i4) :: i, dof_idx
    REAL(wp) :: constraint_value

    status = 0_i4
    constraint_value = ZERO

    ! Compute constraint value: Σ a_i * u_i
    DO i = 1, mpc%n_terms
      dof_idx = (mpc%node_ids(i) - 1) * mpc%ndof_per_node + mpc%dof_ids(i)
      IF (dof_idx > 0 .AND. dof_idx <= SIZE(u_nodal)) THEN
        constraint_value = constraint_value + mpc%coefficients(i) * u_nodal(dof_idx)
      END IF
    END DO

    ! Violation = constraint_value - rhs
    violation = constraint_value - mpc%rhs

  END SUBROUTINE PH_Constr_MPCCore_ComputeViolation

  SUBROUTINE PH_Constr_MPCCore_Opt(mpc, optimization_level, status)
    TYPE(PH_Constr_MPC_Def), INTENT(INOUT) :: mpc
    INTEGER(i4), INTENT(IN) :: optimization_level
    INTEGER(i4), INTENT(OUT) :: status

    INTEGER(i4) :: i, j
    REAL(wp) :: temp_coeff
    INTEGER(i4) :: temp_node, temp_dof

    status = 0_i4

    ! Level 1: Sort by coefficient magnitude
    IF (optimization_level >= 1) THEN
      DO i = 1, mpc%n_terms - 1
        DO j = i + 1, mpc%n_terms
          IF (ABS(mpc%coefficients(j)) > ABS(mpc%coefficients(i))) THEN
            ! Swap coefficients
            temp_coeff = mpc%coefficients(i)
            mpc%coefficients(i) = mpc%coefficients(j)
            mpc%coefficients(j) = temp_coeff

            ! Swap node IDs
            temp_node = mpc%node_ids(i)
            mpc%node_ids(i) = mpc%node_ids(j)
            mpc%node_ids(j) = temp_node

            ! Swap DOF IDs
            temp_dof = mpc%dof_ids(i)
            mpc%dof_ids(i) = mpc%dof_ids(j)
            mpc%dof_ids(j) = temp_dof
          END IF
        END DO
      END DO
    END IF

  END SUBROUTINE PH_Constr_MPCCore_Opt
END MODULE PH_Constr_MPC