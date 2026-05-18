!===============================================================================
! Template: MD_Constraint_XXX.f90                               [Template v1.0]
! Layer:  L3_MD - Model Description Layer
! Domain: Constraint / [Family] (e.g., MPC / UMPC / VMPC / UMESHMOTION)
!
! HOW TO USE:
!   1. Copy to L3_MD/Constraint/[Family]/
!   2. Rename: MD_Constr_[Family]_[Type].f90
!              (e.g., MD_Constr_MPC_Linear.f90, MD_Constr_UMESHMOTION_ALE.f90)
!   3. Replace XXX_XXX -> [Family]_[Type]  (e.g., MPC_Linear)
!   4. Replace XXX     -> [Type abbrev]    (e.g., Lin)
!   5. Fill in: constr_type_id, required props layout
!   6. Implement: MD_XXX_Constr_ValidateProps, MD_XXX_Constr_InitFromProps
!
! Naming Convention (layer prefix rule):
!   Module:    MD_Constr_[Family]_[Type]       → MD_Constr_MPC_Linear
!   Desc type: MD_XXX_Constr_Desc              → MD_Constr_Lin_Desc  (MD-owned)
!   Validate:  MD_XXX_Constr_ValidateProps     → MD_Constr_Lin_ValidateProps
!   Init:      MD_XXX_Constr_InitFromProps     → MD_Constr_Lin_InitFromProps
!
! Design notes (UFC Constraint domain):
!   - UMPC:         User multi-point constraint (Implicit Standard)
!   - VMPC:         Vectorised MPC (Explicit); nblock-based
!   - UMESHMOTION:  ALE adaptive mesh constraint velocity
!   - MD_Constr_Base_Desc carries: constr_id, constr_type, n_nodes, n_dof,
!     nprops, is_initialized.  This Desc extends it with constraint-family
!     specific parameters (coefficients, penalty, orientation, etc.).
!   - Purely static / configuration: set ONCE at model load.
!   - NEVER carry per-increment Lagrange multiplier values here
!     (those belong in PH_Constr_Base_State / PH_Constr_UMPC_State).
!===============================================================================
MODULE MD_Constraint_XXX
  USE IF_Prec_Core,             ONLY: wp, i4
  USE IF_Err_Brg,          ONLY: ErrorStatusType, init_error_status, &
                                 IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Constraint_Types, ONLY: MD_Constr_Base_Desc, &
                                 MD_CONSTR_CONSTR_TYPE_MPC   ! ← replace enum if needed
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public exports: Desc type + two standard MD-layer interfaces
  ! Prefix MD_XXX_ signals these subroutines belong to L3_MD layer.
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_XXX_Constr_Desc            ! L3_MD constraint descriptor (MD-owned)
  PUBLIC :: MD_XXX_Constr_ValidateProps   ! Validate flat props array
  PUBLIC :: MD_XXX_Constr_InitFromProps   ! Unpack props -> MD_XXX_Constr_Desc

  !-----------------------------------------------------------------------------
  ! Constants — constraint family invariants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: CONSTR_NPROPS_MIN = 1_i4   ! Minimum props count
  !
  ! Props layout (document ALL slots for THIS constraint family):
  !   props(1) = ???    : [unit]  (e.g., penalty stiffness [N/m])
  !   props(2) = ???    : [unit]  (e.g., tolerance factor [-])
  !   props(3) = ???    : model-specific [unit]
  !   ...
  !
  ! jprops layout (if applicable — integer props from *USER MPC):
  !   jprops(1) = jtype : constraint type integer (JTYPE from ABAQUS UMPC)
  !   jprops(2) = n     : number of nodes (N)
  !   ...

  !-----------------------------------------------------------------------------
  ! DESC type: EXTENDS MD_Constr_Base_Desc, adds constraint-family parameters.
  !
  !   MD_Constr_Base_Desc provides:
  !     constr_id     — constraint set ID
  !     constr_type   — type enum (MPC / MESHMOTION / ORIENT / TIE)
  !     constr_name   — human-readable label (CHARACTER(LEN=64))
  !     n_nodes       — number of nodes in constraint
  !     n_dof         — number of constrained DOFs
  !     nprops        — number of real properties
  !     props(:)      — user properties array (ALLOCATABLE)
  !     is_initialized — .TRUE. after InitFromProps succeeds
  !
  !   Add constraint-family-specific Desc fields below.
  !   For MPC/UMPC:       add mpc_type, n_terms, coeff_a(:), const_b
  !   For UMESHMOTION:    add ale_sweeps, smooth_factor
  !   For ORIENT:         add euler_angles(3), dir_cos(3,3)
  !   For penalty constr: add penalty_stiff, augmentation_factor
  !-----------------------------------------------------------------------------
  !> L3 descriptor for [Constraint Family / Type Name].
  TYPE, PUBLIC, EXTENDS(MD_Constr_Base_Desc) :: MD_XXX_Constr_Desc
    !-- Constraint family type identifier (replace with actual family enum)
    INTEGER(i4) :: constr_family  = MD_CONSTR_CONSTR_TYPE_MPC

    !-- Constraint-family-specific parameters (replace with actual parameters)
    !   For MPC/UMPC linear:    add n_terms, coeff_a(:), const_b
    !   For penalty enforcement: add penalty_stiff, tol_violation
    !   For UMESHMOTION ALE:    add n_ale_sweeps, smooth_factor, vel_scale
    INTEGER(i4) :: jtype          = 0_i4      ! JTYPE: MPC type from *MPC,TYPE=
    INTEGER(i4) :: n_terms        = 2_i4      ! Number of terms in constraint equation
    REAL(wp)    :: const_b        = 0.0_wp    ! Constant RHS term b
    REAL(wp)    :: penalty_stiff  = 1.0e6_wp  ! Penalty stiffness if method=2 [N/m]
    REAL(wp)    :: constr_param1  = 0.0_wp    ! Family-specific parameter [unit]
    REAL(wp)    :: constr_param2  = 0.0_wp    ! Family-specific parameter [unit]

    !-- Derived / pre-computed constants (populated in InitFromProps for speed)
    REAL(wp)    :: inv_penalty    = 0.0_wp    ! 1/penalty_stiff (avoid division in hot path)

  END TYPE MD_XXX_Constr_Desc

CONTAINS

  !-----------------------------------------------------------------------------
  !> MD_XXX_Constr_ValidateProps
  !>   Validates the flat props array for [Constraint Family / Type].
  !>   Called by L4_PH (via MD_XXX_Constr_InitFromProps) before populating Desc.
  !>   Returns structured status with %status_code = IF_STATUS_INVALID on any
  !>   constraint violation.
  !>
  !>   nprops  — number of real properties
  !>   props   — real properties array (from *USER MPC, PROPERTY or similar)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Constr_ValidateProps(nprops, props, st)
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)

    !-- Minimum count check
    IF (nprops < CONSTR_NPROPS_MIN) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Constr]: need >= CONSTR_NPROPS_MIN props"
      RETURN
    END IF

    !-- Per-slot physical constraints (replace with actual model rules)
    !   e.g., penalty stiffness must be positive
    IF (nprops >= 1) THEN
      IF (props(1) <= 0.0_wp) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Constr]: props(1) (penalty_stiff) must be > 0"
        RETURN
      END IF
    END IF

    !-- TODO: add further constraint-type-specific validation here

    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Constr_ValidateProps

  !-----------------------------------------------------------------------------
  !> MD_XXX_Constr_InitFromProps
  !>   Unpacks nprops/props into MD_XXX_Constr_Desc.
  !>   Computes all derived constants (inv_penalty, etc.).
  !>   Called ONCE at model load (or first UMPC call if lazy-init).
  !>
  !>   desc   — output Desc (populated by this subroutine)
  !>   nprops — number of real properties
  !>   props  — real property array (penalty_stiff, tol, ...)
  !>   st     — structured status object (%status_code == IF_STATUS_OK on success)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Constr_InitFromProps(desc, nprops, props, st)
    TYPE(MD_XXX_Constr_Desc), INTENT(OUT) :: desc
    INTEGER(i4),              INTENT(IN)  :: nprops
    REAL(wp),                 INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),    INTENT(OUT) :: st

    CALL init_error_status(st)

    !-- Step 1: validate before unpacking
    CALL MD_XXX_Constr_ValidateProps(nprops, props, st)
    IF (st%status_code /= IF_STATUS_OK) RETURN

    !-- Step 2: populate base fields (inherited from MD_Constr_Base_Desc)
    desc%constr_type   = MD_CONSTR_CONSTR_TYPE_MPC   ! ← replace with actual type
    desc%n_terms       = 2_i4                         ! default: master + slave node
    desc%constr_family = MD_CONSTR_CONSTR_TYPE_MPC

    !-- Step 3: unpack real props
    IF (nprops >= 1) desc%penalty_stiff  = props(1)
    IF (nprops >= 2) desc%const_b        = props(2)
    IF (nprops >= 3) desc%constr_param1  = props(3)
    IF (nprops >= 4) desc%constr_param2  = props(4)
    !-- TODO: unpack further constraint-family-specific props slots

    !-- Step 4: compute derived constants
    IF (desc%penalty_stiff > 0.0_wp) THEN
      desc%inv_penalty = 1.0_wp / desc%penalty_stiff
    ELSE
      desc%inv_penalty = 0.0_wp
    END IF

    !-- Step 5: allocate base props array for compatibility
    desc%nprops = nprops
    IF (.NOT. ALLOCATED(desc%props)) ALLOCATE(desc%props(nprops))
    desc%props(1:nprops) = props(1:nprops)

    !-- Step 6: mark initialized
    desc%is_initialized = .TRUE.
    st%status_code      = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Constr_InitFromProps

END MODULE MD_Constr_XXX

!===============================================================================
! USAGE NOTES — MD_XXX_Constr_Desc instantiation example
!
!   USE MD_Constr_MPC_Linear, ONLY: MD_Constr_Lin_Desc, MD_Constr_Lin_InitFromProps
!   TYPE(MD_Constr_Lin_Desc)  :: constr_desc
!   TYPE(ErrorStatusType)     :: st
!
!   !-- From ABAQUS UMPC arguments (nprops / props from *USER MPC):
!   CALL MD_Constr_Lin_InitFromProps(constr_desc, nprops, props, st)
!   IF (st%status_code /= IF_STATUS_OK) ERROR STOP '[UMPC]: Bad constraint props'
!
!   !-- Pass to L4_PH constraint kernel:
!   CALL PH_XXX_Constr_API(constr_desc, PH_Constr_Ctx, PH_Constr_State, ...)
!===============================================================================
