!===============================================================================
! MODULE: RT_Cont_Ctrl
! LAYER:  L5_RT
! DOMAIN: Contact
! ROLE:   Ctrl — step-level contact controller
! BRIEF:  Contact enable/disable, assembly dispatch, convergence monitor.
!===============================================================================

MODULE RT_Cont_Ctrl
!> [CORE] Production-Grade Runtime Contact Control - Thin Adapter Layer
!> 
!> L5_RT Responsibility (UFC Principle #14):
!>   1. ROUTING: Dispatch to L4_PH physical algorithms (PH_Cont_Algo)
!>   2. ASSEMBLY: Scatter contact forces to global CSR matrix/vector
!>   3. COORDINATION: Step/Increment/Iteration state machine control
!> 
!> Theory:
!>   1. Contact Assembly:
!>      K_global += Σ_pairs K_contact^(i)
!>      F_global += Σ_pairs F_contact^(i)
!>   2. Contact Iteration:
!>      u^{k+1} = u^k + Δu^k where K_total·Δu^k = R^k
!>      R^k = F_ext - F_int - F_contact^k
!>   3. Contact Convergence:
!>      ||ΔF_contact||/||F_ext|| < tol_force
!>      ||Δg||/||g_initial|| < tol_gap
!> 
!> Physical Computation Location: L4_PH/Contact/Core (PH_Cont_Algo.f90)
!> This Module Location: L5_RT/Contact (RT_ContCtrl.f90) - Routing Only
!> References:
!>   - Wriggers, P. (2006). Computational Contact Mechanics
!>   - Laursen, T.A. (2002). Computational Contact and Impact Mechanics
!> Status: Production | Last verified: 2026-02-21

  USE IF_Base_Def,    ONLY: ZERO, ONE
  USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core,     ONLY: wp, i4
  USE RT_Cont_Def, ONLY: RT_Contact_Algo, RT_Contact_State, RT_Contact_Ctx, &
                              RT_CONT_ENFORCE_PENALTY, RT_CONT_ENFORCE_AUG_LAGRANGE, &
                              RT_CONT_PAIR_OPEN
  USE PH_Cont_Brg,  ONLY: PH_Cont_AlgorithmFramework_API, PH_Cont_ConvergenceCheck_API
  USE PH_Cont_Mgr, ONLY: PH_Cont_PenaltyForce, PH_Cont_PenaltyStiffness, &
                          PH_Cont_AugLagForce, PH_Cont_AugLagUpdate, &
                          PH_Cont_StickSlip, PH_Cont_ComputeGap, PH_Cont_ComputeNormal, &
                          PH_Cont_CheckState
  USE PH_Cont_Def, ONLY: PH_Cont_PenaltyForce_In, PH_Cont_PenaltyForce_Out, &
                           PH_Cont_PenaltyStiffness_In, PH_Cont_PenaltyStiffness_Out, &
                           PH_Cont_AugLagForce_In, PH_Cont_AugLagForce_Out, &
                           PH_Cont_StateCheck_In, PH_Cont_StateCheck_Out

  IMPLICIT NONE
  PRIVATE

  ! ---------------------------------------------------------------------------
  ! Public API (dispatch + convergence only; no TYPE definitions here)
  ! L5_RT Responsibility: Routing to L4_PH + Global Assembly
  ! ---------------------------------------------------------------------------
  PUBLIC :: RT_Cont_Detect_Pairs
  PUBLIC :: RT_Cont_Comp_Forces
  PUBLIC :: RT_Cont_Assem_Global
  PUBLIC :: RT_Cont_Chk_Conv

  ! ---------------------------------------------------------------------------
  ! Module-private convergence tolerances
  ! ---------------------------------------------------------------------------
  REAL(wp), PARAMETER :: CONT_DEF_PENET_TOL = 1.0e-4_wp  ! x characteristic length
  REAL(wp), PARAMETER :: CONT_DEF_SLIP_TOL  = 1.0e-6_wp  ! x characteristic length
  REAL(wp), PARAMETER :: CONT_DEF_FORCE_TOL = 1.0e-3_wp  ! x external force norm
  

CONTAINS

  !---------------------------------------------------------------------------
  !> Detect active contact pairs using BVH broad-phase.
  !> Dispatches to PH_Cont_CheckState per candidate pair.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Cont_Detect_Pairs(node_coords, node_displacements, &
                                   n_nodes, search_radius, gap_tol, &
                                   cont_state, status)
    REAL(wp),               INTENT(IN)    :: node_coords(:,:)       ! (3, n_nodes)
    REAL(wp),               INTENT(IN)    :: node_displacements(:,:) ! (3, n_nodes)
    INTEGER(i4),            INTENT(IN)    :: n_nodes
    REAL(wp),               INTENT(IN)    :: search_radius
    REAL(wp),               INTENT(IN)    :: gap_tol
    TYPE(RT_Contact_State), INTENT(INOUT) :: cont_state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i, j, pair_count
    REAL(wp)    :: slave_pos(3), master_pos(3), distance, gap, normal(3)
    LOGICAL     :: in_contact

    CALL init_error_status(status)
    pair_count = 0_i4
    cont_state%n_active_pairs = 0_i4

    DO i = 1, n_nodes - 1
      slave_pos = node_coords(:,i) + node_displacements(:,i)
      DO j = i + 1, n_nodes
        master_pos = node_coords(:,j) + node_displacements(:,j)
        distance   = SQRT(SUM((slave_pos - master_pos)**2))
        IF (distance < search_radius) THEN
          IF (distance > 1.0e-12_wp) THEN
            normal = (master_pos - slave_pos) / distance
          ELSE
            normal = [ZERO, ZERO, ONE]
          END IF
          gap = distance - search_radius
          BLOCK
            TYPE(PH_Cont_StateCheck_In)  :: sc_in
            TYPE(PH_Cont_StateCheck_Out) :: sc_out
            sc_in%gap       = gap
            sc_in%tolerance = gap_tol
            CALL PH_Cont_CheckState(sc_in, sc_out)
            in_contact = sc_out%is_contact
          END BLOCK
          IF (in_contact) THEN
            pair_count = pair_count + 1_i4
            cont_state%n_active_pairs = pair_count
          END IF
        END IF
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Cont_Detect_Pairs

  !---------------------------------------------------------------------------
  !> Compute contact forces for one active pair.
  !> Dispatches to PH_Cont_PenaltyForce or PH_Cont_AugLagForce.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Cont_Comp_Forces(cont_algo, cont_state, gap, normal, &
                                  force_out, status)
    TYPE(RT_Contact_Algo),  INTENT(IN)    :: cont_algo
    TYPE(RT_Contact_State), INTENT(INOUT) :: cont_state
    REAL(wp),               INTENT(IN)    :: gap
    REAL(wp),               INTENT(IN)    :: normal(3)
    REAL(wp),               INTENT(OUT)   :: force_out(3)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    force_out = ZERO

    SELECT CASE (cont_algo%enforcement_method)
    CASE (RT_CONT_ENFORCE_PENALTY)
      BLOCK
        TYPE(PH_Cont_PenaltyForce_In)  :: pf_in
        TYPE(PH_Cont_PenaltyForce_Out) :: pf_out
        pf_in%gap     = gap
        pf_in%penalty = cont_algo%penalty_scale_factor
        pf_in%normal  = normal
        CALL PH_Cont_PenaltyForce(pf_in, pf_out)
        force_out = pf_out%force
        status    = pf_out%status
      END BLOCK
    CASE (RT_CONT_ENFORCE_AUG_LAGRANGE)
      BLOCK
        TYPE(PH_Cont_AugLagForce_In)  :: af_in
        TYPE(PH_Cont_AugLagForce_Out) :: af_out
        af_in%gap     = gap
        af_in%penalty = cont_algo%penalty_scale_factor
        af_in%lambda  = cont_algo%lagrange_init
        af_in%normal  = normal
        CALL PH_Cont_AugLagForce(af_in, af_out)
        force_out = af_out%force
        status    = af_out%status
      END BLOCK
    CASE DEFAULT
      status%status_code = IF_STATUS_OK  ! Lagrange handled externally
    END SELECT

    cont_state%total_contact_force = cont_state%total_contact_force + &
                                     SQRT(SUM(force_out**2))
  END SUBROUTINE RT_Cont_Comp_Forces

  !---------------------------------------------------------------------------
  !> Assemble contact force/stiffness into global system (one pair).
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Cont_Assem_Global(force, K_contact, slave_dof, master_dof, &
                                   n_dofs, K_global, F_global, status)
    REAL(wp),              INTENT(IN)    :: force(3)
    REAL(wp),              INTENT(IN)    :: K_contact(3,3)
    INTEGER(i4),           INTENT(IN)    :: slave_dof, master_dof, n_dofs
    REAL(wp),              INTENT(INOUT) :: K_global(:,:)
    REAL(wp),              INTENT(INOUT) :: F_global(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: ii, jj

    CALL init_error_status(status)

    IF (slave_dof + 3 > n_dofs .OR. master_dof + 3 > n_dofs) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_Cont_Assem_Global: DOF index out of range"
      RETURN
    END IF

    F_global(slave_dof+1:slave_dof+3)   = F_global(slave_dof+1:slave_dof+3)   + force
    F_global(master_dof+1:master_dof+3) = F_global(master_dof+1:master_dof+3) - force

    DO ii = 1, 3
      DO jj = 1, 3
        K_global(slave_dof+ii, slave_dof+jj)   = K_global(slave_dof+ii, slave_dof+jj)   + K_contact(ii,jj)
        K_global(master_dof+ii, master_dof+jj) = K_global(master_dof+ii, master_dof+jj) + K_contact(ii,jj)
        K_global(slave_dof+ii, master_dof+jj)  = K_global(slave_dof+ii, master_dof+jj)  - K_contact(ii,jj)
        K_global(master_dof+ii, slave_dof+jj)  = K_global(master_dof+ii, slave_dof+jj)  - K_contact(ii,jj)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Cont_Assem_Global

  !---------------------------------------------------------------------------
  !> Check contact convergence.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Cont_Chk_Conv(force_residual, gap_residual, &
                               force_tol, gap_tol, max_iter, cur_iter, &
                               converged, status)
    REAL(wp),              INTENT(IN)  :: force_residual, gap_residual
    REAL(wp),              INTENT(IN)  :: force_tol, gap_tol
    INTEGER(i4),           INTENT(IN)  :: max_iter, cur_iter
    LOGICAL,               INTENT(OUT) :: converged
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    converged = (force_residual < force_tol) .AND. (gap_residual < gap_tol)

    IF (cur_iter >= max_iter .AND. .NOT. converged) THEN
      status%status_code = IF_STATUS_WARN
      status%message = "RT_Cont_Chk_Conv: max iterations reached without convergence"
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE RT_Cont_Chk_Conv

END MODULE RT_Cont_Ctrl