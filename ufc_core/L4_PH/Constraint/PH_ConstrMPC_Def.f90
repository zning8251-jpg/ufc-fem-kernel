!===============================================================================
! MODULE: PH_ConstrMPC_Def
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Def â€?MPC type definitions (constraint equations AÂ·u = b)
! BRIEF:  MPC_Constraint, MPC_Params, MPC_State, MPC_Term types.
!===============================================================================
!
! Contents (A-Z):
!   Types:
!     - MPC_Constraint      - Single MPC constraint definition
!     - MPC_Params          - MPC enforcement parameters
!     - MPC_State           - MPC constraint violation state
!     - MPC_Term            - Single term in MPC equation
!     - PH_Constr_MPC_Def   - Simplified MPC definition for RT layer
!   Subroutines:
!     - (None)
!   Functions:
!     - (None)
!===============================================================================

MODULE PH_ConstrMPC_Def
  USE IF_Base_Def, ONLY: ZERO
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Constr_Domain, ONLY: PH_CONSTR_PENALTY
  IMPLICIT NONE
  PRIVATE
  
  ! ==========================================================================
  ! Public types
  ! ==========================================================================
  PUBLIC :: MPC_Constraint
  PUBLIC :: MPC_Params
  PUBLIC :: MPC_State
  PUBLIC :: MPC_Term
  PUBLIC :: PH_Constr_MPC_Def
  
  ! ==========================================================================
  ! MPC Term - single term in MPC equation (a_i * u_i)
  ! ==========================================================================
  TYPE :: MPC_Term
    INTEGER(i4) :: node_id = 0_i4       ! Node ID
    INTEGER(i4) :: dof_type = 0_i4      ! DOF type (1=u1, 2=u2, 3=u3, 4=ur1, 5=ur2, 6=ur3)
    REAL(wp) :: coef = ZERO             ! Coefficient a_i
  END TYPE MPC_Term
  
  ! ==========================================================================
  ! MPC Constraint - complete constraint definition
  ! ==========================================================================
  TYPE :: MPC_Constraint
    CHARACTER(LEN=64) :: constraint_name = ""
    INTEGER(i4) :: num_terms = 0_i4                     ! Number of terms
    TYPE(MPC_Term), ALLOCATABLE :: terms(:)             ! Constraint terms
    REAL(wp) :: rhs_value = ZERO                        ! Right-hand side c
    INTEGER(i4) :: master_dof_id = 0_i4                 ! Master DOF ID for elimination method
    LOGICAL :: is_active = .TRUE.                       ! Whether constraint is active
  END TYPE MPC_Constraint
  
  ! ==========================================================================
  ! MPC Parameters - enforcement method configuration
  ! ==========================================================================
  TYPE :: MPC_Params
    INTEGER(i4) :: enforcement_method = PH_CONSTR_PENALTY  ! PH_CONS_* (PH_ConstraintDomain_Algo)
    REAL(wp) :: penalty_factor = 1.0e12_wp              ! Penalty parameter kappa
    REAL(wp) :: tolerance = 1.0e-8_wp                   ! Constraint violation tolerance
    LOGICAL :: auto_detect_master = .FALSE.             ! Auto-detect master DOF
  END TYPE MPC_Params
  
  ! ==========================================================================
  ! MPC State - constraint violation monitoring
  ! ==========================================================================
  TYPE :: MPC_State
    INTEGER(i4) :: num_constraints = 0_i4               ! Total number of constraints
    REAL(wp) :: max_violation = ZERO                    ! Maximum constraint violation
    REAL(wp) :: avg_violation = ZERO                    ! Average constraint violation
    INTEGER(i4) :: num_violations = 0_i4                ! Number of violated constraints
    LOGICAL :: is_satisfied = .TRUE.                    ! Whether all constraints satisfied
    REAL(wp), ALLOCATABLE :: lagrange_multipliers(:)    ! Lagrange multipliers (Lagrange method)
  END TYPE MPC_State
  
  ! ==========================================================================
  ! PH_Constr_MPC_Def - simplified MPC definition for RT layer
  ! ==========================================================================
  TYPE :: PH_Constr_MPC_Def
    INTEGER(i4) :: n_terms = 0_i4
    INTEGER(i4) :: ndof_per_node = 3_i4
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    INTEGER(i4), ALLOCATABLE :: dof_ids(:)
    REAL(wp), ALLOCATABLE :: coefficients(:)
    REAL(wp) :: rhs = ZERO
  END TYPE PH_Constr_MPC_Def

END MODULE PH_ConstrMPC_Def

