!===============================================================================
! Module: PH_Constraint_Types                                    [Template v1.0]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Constraint — Ctx / State / Algo types for per-increment constraints
!
! Purpose:
!   Defines the full Ctx / State / Algo three-type system for constraint
!   computation at the PH_ layer.  Covers:
!   - UMPC         : User multi-point constraint (Implicit)
!   - UMESHMOTION  : User-defined mesh motion (ALE/morph)
!   - ORIENT       : User-defined local material orientation
!
! Design principle:
!   UMPC: constrains DOF relationships between nodes via Lagrange multipliers.
!   UMESHMOTION: defines adaptive mesh constraint velocities.
!   ORIENT: defines local coordinate system for anisotropic materials.
!
! Abaqus parameter map (UMPC):
!   U(NDOFC)    → u_constrained    constrained DOF current values
!   A(NDOFC)    → coeff_a          constraint coefficients (UMPC output)
!   RHS(NDOFC)  → rhs              RHS of constraint equation
!   LMULT       → lagrange_mult    Lagrange multiplier value
!   NDOFC       → n_constrained_dof
!   NODE        → node_ids(:)      nodes involved in constraint
!
! Layer dependency:
!   USE IF_Prec      (wp, i4)
!   USE IF_Err_Brg   (structured ErrorStatusType status; baseline vocabulary:
!                     init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE PH_Constraint_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Constr_Base_Ctx
  PUBLIC :: PH_Constr_Base_State
  PUBLIC :: PH_Constr_Base_Algo
  PUBLIC :: PH_Constr_MPC_Ctx
  PUBLIC :: PH_Constr_MeshMotion_Ctx

  !-----------------------------------------------------------------------------
  ! CTX — Constraint Computation Context (per-increment driving inputs)
  !   Generic context for all constraint types
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_Base_Ctx
    !-- Node identification
    INTEGER(i4) :: n_nodes = 0_i4    ! Number of nodes in constraint
    INTEGER(i4), POINTER :: node_ids(:)    ! [n_nodes] node numbers
    INTEGER(i4), POINTER :: dof_ids(:)     ! [n_nodes] DOF indices
    !-- Current displacement values
    REAL(wp), POINTER :: u_current(:)      ! Current DOF values [n_dof]
    REAL(wp), POINTER :: du_current(:)     ! DOF increments [n_dof]
    !-- Temporal context
    REAL(wp) :: time_current = 0.0_wp
    REAL(wp) :: time_total   = 0.0_wp
    INTEGER(i4) :: kstep = 0_i4
    INTEGER(i4) :: kinc  = 0_i4
  END TYPE PH_Constr_Base_Ctx

  !-----------------------------------------------------------------------------
  ! STATE — Constraint Computation Output
  !   Constraint coefficients and RHS returned to solver
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_Base_State
    !-- Constraint equation output: sum(A_i * u_i) = RHS
    REAL(wp), ALLOCATABLE :: coeff_a(:)      ! A: constraint coefficients [n_dof]
    REAL(wp) :: rhs      = 0.0_wp            ! RHS of constraint equation
    REAL(wp) :: lmult    = 0.0_wp            ! Lagrange multiplier
    !-- Jacobian d(constraint)/d(u_i)
    REAL(wp), ALLOCATABLE :: jac(:,:)        ! [n_dof, n_dof]
    !-- Convergence bookkeeping
    LOGICAL     :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Constr_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Per-Increment Algorithm Control
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_Base_Algo
    !-- Iteration control
    INTEGER(i4) :: max_iter = 20
    REAL(wp)    :: tolerance = 1.0e-8_wp     ! Tight for constraint satisfaction
    !-- Enforcement method
    INTEGER(i4) :: method = 1_i4             ! 1=Lagrange, 2=penalty, 3=augmented
    REAL(wp)    :: penalty_factor = 1.0e6_wp ! Penalty stiffness [Pa/m]
    !-- Time-step suggestion
    REAL(wp) :: pnewdt_min = 0.1_wp
    REAL(wp) :: pnewdt_max = 2.0_wp
  END TYPE PH_Constr_Base_Algo

  !-----------------------------------------------------------------------------
  ! PH_Constr_MPC_Ctx — UMPC: multi-point constraint specific context
  !   Provides DOF-level data for UMPC: node pairs and constrained DOFs.
  !   UMPC is called for each constrained DOF; u-of-independent nodes provided.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_MPC_Ctx
    !-- Constrained node information
    INTEGER(i4) :: ndofc     = 0_i4   ! NDOFC: number of constrained DOFs
    INTEGER(i4) :: jdof      = 0_i4   ! JDOF: DOF to be constrained
    INTEGER(i4) :: node_c    = 0_i4   ! Constrained node number
    !-- Independent node DOF values
    REAL(wp), POINTER :: u_ind(:)   ! Independent DOF values [ndofn]
    INTEGER(i4), POINTER :: node_ind(:) ! Independent node numbers
    INTEGER(i4), POINTER :: jdof_ind(:) ! Independent DOF indices
    INTEGER(i4) :: ndofn = 0_i4           ! Number of independent DOFs
    !-- Temporal context
    REAL(wp) :: time_current = 0.0_wp
    REAL(wp) :: time_total   = 0.0_wp
    INTEGER(i4) :: kstep = 0_i4
    INTEGER(i4) :: kinc  = 0_i4
    !-- Output (UMPC writes these)
    REAL(wp), POINTER :: a(:)       ! Constraint coefficients [ndofn]
    REAL(wp) :: an = 0.0_wp             ! Coefficient for constrained DOF
    REAL(wp) :: rhs_val = 0.0_wp        ! RHS constant term
  END TYPE PH_Constr_MPC_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Constr_MeshMotion_Ctx — UMESHMOTION: ALE adaptive mesh motion
  !   User defines mesh velocity at surface nodes for ALE analyses.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_MeshMotion_Ctx
    !-- Node context
    INTEGER(i4) :: node_id   = 0_i4    ! NOEL (node number)
    INTEGER(i4) :: jgvblock  = 0_i4    ! JGVBLOCK: block identifier
    !-- Node coordinates and material displacement
    REAL(wp) :: coords(3)    = 0.0_wp  ! Current node coordinates
    REAL(wp) :: disp_mat(3)  = 0.0_wp  ! Material displacement [m]
    REAL(wp) :: vel_mat(3)   = 0.0_wp  ! Material velocity [m/s]
    !-- Temporal context
    REAL(wp) :: time_current = 0.0_wp
    REAL(wp) :: dtime        = 0.0_wp  ! Time increment
    !-- Surface normal
    REAL(wp) :: normal(3)    = 0.0_wp  ! Outward surface normal
    !-- Output: prescribed mesh velocity
    REAL(wp) :: vel_mesh(3)  = 0.0_wp  ! Mesh (ALE) velocity [m/s]
    REAL(wp) :: weight(3)    = 1.0_wp  ! Weighting for mesh smoothing
  END TYPE PH_Constr_MeshMotion_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Constr_UMPC_State — UMPC output state
  !   UMPC: equality constraint residual F and Jacobian d(F)/d(u)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_UMPC_State
    REAL(wp), ALLOCATABLE :: f_res(:)       ! OUT: constraint residuals [nterms]
    REAL(wp), ALLOCATABLE :: a_jac(:,:)    ! OUT: d(F)/d(u) [nterms, ndofel]
    REAL(wp), ALLOCATABLE :: u_eq(:)       ! OUT: prescribed u at controlled DOF
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Constr_UMPC_State

  !-----------------------------------------------------------------------------
  ! PH_Constr_VMPC_Ctx — VMPC (Vectorised MPC, Explicit) per-call driving Ctx
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_VMPC_Ctx
    INTEGER(i4) :: nblock    = 1_i4    ! NBLOCK: constraint groups in block
    INTEGER(i4) :: nterms    = 0_i4    ! NTERMS: number of terms
    REAL(wp), POINTER :: u_blk(:,:)  ! [nblock, nterms] DOF values
    REAL(wp) :: step_time    = 0.0_wp
    REAL(wp) :: total_time   = 0.0_wp
  END TYPE PH_Constr_VMPC_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Constr_VMPC_State — VMPC output state (Explicit block form)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_VMPC_State
    REAL(wp), ALLOCATABLE :: f_blk(:,:)   ! [nblock, nterms] residuals
    REAL(wp), ALLOCATABLE :: u_eq_blk(:)  ! [nblock] controlled DOF value
    INTEGER(i4) :: nblock = 0
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Constr_VMPC_State

  !-----------------------------------------------------------------------------
  ! PH_Constr_UPATH_Ctx — UPATH user-defined path/sensor driving Ctx
  !   UPATH: used for path-dependent response tracking
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_UPATH_Ctx
    INTEGER(i4) :: path_id   = 0_i4    ! Path identifier
    INTEGER(i4) :: kstep     = 0_i4
    INTEGER(i4) :: kinc      = 0_i4
    REAL(wp)    :: time_step = 0.0_wp
    REAL(wp)    :: coords(3) = 0.0_wp  ! Reference point coordinates
  END TYPE PH_Constr_UPATH_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Constr_UPATH_State — UPATH output state
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_UPATH_State
    REAL(wp) :: path_val  = 0.0_wp  ! OUT: path response value
    REAL(wp) :: d_path_dt = 0.0_wp  ! OUT: rate
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Constr_UPATH_State

  !-----------------------------------------------------------------------------
  ! PH_Constr_UMPC_Ctx — UMPC user-MPC per-call driving inputs
  !   UMPC(UE, A, JDOF, MDOF, N, JTYPE, X, U, UINIT, MAXDOF, LMPC, KSTEP, KINC)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_UMPC_Ctx
    REAL(wp), POINTER :: x(:,:)    ! I X    node coordinates [ndim, nnode]
    REAL(wp), POINTER :: u(:)      ! I U    current displacements [ndof]
    REAL(wp), POINTER :: uinit(:)  ! I UINIT initial displacements
    INTEGER(i4) :: jtype  = 0_i4  ! I JTYPE   MPC type identifier
    INTEGER(i4) :: n      = 0_i4  ! I N       number of nodes
    INTEGER(i4) :: mdof   = 0_i4  ! I MDOF    number of DOF
    INTEGER(i4) :: maxdof = 0_i4  ! I MAXDOF  max DOF index
    INTEGER(i4) :: kstep  = 0_i4
    INTEGER(i4) :: kinc   = 0_i4
    LOGICAL     :: lmpc   = .FALSE.  ! linear MPC flag
  END TYPE PH_Constr_UMPC_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Constr_UMPC_Algo — UMPC algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_UMPC_Algo
    INTEGER(i4) :: max_iter = 20_i4
    REAL(wp)    :: tol_res  = 1.0e-10_wp
    LOGICAL     :: nonlinear = .FALSE.  ! nonlinear MPC
  END TYPE PH_Constr_UMPC_Algo

  !-----------------------------------------------------------------------------
  ! PH_Constr_VMPC_Algo — VMPC explicit vectorised MPC algorithm
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_VMPC_Algo
    INTEGER(i4) :: nblock_max = 512_i4
    LOGICAL     :: nonlinear  = .FALSE.
  END TYPE PH_Constr_VMPC_Algo

  !-----------------------------------------------------------------------------
  ! PH_Constr_UPATH_Algo — UPATH contact path algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_UPATH_Algo
    REAL(wp)    :: ds_max   = 1.0e-3_wp  ! max path increment
    INTEGER(i4) :: n_pts    = 100_i4     ! number of path points
    LOGICAL     :: closed   = .FALSE.    ! closed path
  END TYPE PH_Constr_UPATH_Algo

  !-----------------------------------------------------------------------------
  ! PH_Constr_UMESHMOTION_State — UMESHMOTION mesh-motion output
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_UMESHMOTION_State
    REAL(wp), ALLOCATABLE :: disp(:)    ! O displacement vector [ndim]
    REAL(wp), ALLOCATABLE :: vel(:)     ! O velocity vector [ndim]
    LOGICAL  :: is_valid = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Constr_UMESHMOTION_State

  !-----------------------------------------------------------------------------
  ! PH_Constr_UMESHMOTION_Algo — UMESHMOTION algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Constr_UMESHMOTION_Algo
    REAL(wp)    :: smooth_factor = 1.0_wp  ! mesh smoothing factor
    INTEGER(i4) :: sweep_max     = 5_i4   ! ALE sweeps per increment
    LOGICAL     :: adaptive_mesh = .TRUE.  ! adaptive meshing enabled
  END TYPE PH_Constr_UMESHMOTION_Algo

END MODULE PH_Constraint_Types
