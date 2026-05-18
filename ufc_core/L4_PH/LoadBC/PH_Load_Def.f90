!===============================================================================
! MODULE: PH_Load_Def
! LAYER:  L4_PH
! DOMAIN: LoadBC
! ROLE:   Def — load application domain-level types and controller
! BRIEF:  Load type enums, load controller, integration config, surface traction,
!         element equivalent forces, load cache, and Arg bundles for P0/P2.
!         All types use canonical PH_Load_* naming.
!         No aliases — global unique names only.
!===============================================================================
! Theory:
!   Load vector assembly methods in FEM:
!   1. Concentrated loads (CLOAD): F_i = f_i (direct nodal force assembly)
!   2. Distributed loads (DLOAD): F_elem = &#x222b;N&#x1d40;&middot;t dS (surface traction integration)
!   3. Body forces (BODYFORCE): F_elem = &#x222b;N&#x1d40;&middot;b dV (volume force integration)
!   4. Pressure loads (PRESSURE): F_elem = &#x222b;N&#x1d40;&middot;p&#x1d43;&middot;n dS (pressure with normal vector)
!   5. Gravity loads (GRAVITY): F = M&#x1d43;&middot;g (mass matrix &#x1d43;&middot; gravity acceleration)
!   Integration: &#x222b;f(&#x3be;)d&#x3be; &#x2248; &#x3a3;w_i&#x1d43;&middot;f(&#x3be;_i) using Gauss quadrature
!   Call chain: MD_Load_Def &#x2192; PH_Load_Apply &#x2192; RT_Asm_Load_Apply
! References:
!   - Zienkiewicz, O.C. & Taylor, R.L. (2005). The Finite Element Method, 6th ed.
! Status: Production | Last verified: 2026-02-28
!
! Contents:
!   Types:
!     - PH_Load_LoadCtrl_Type: Load controller type (Ctx)
!     - PH_Load_LoadIntegration_Type: Integration configuration (Desc)
!     - PH_Load_ElemEquivForce_Type: Element equivalent nodal forces (State)
!     - PH_Load_SurfaceTraction_Type: Surface traction (State)
!     - PH_Load_LoadCache_Type: Load cache (State)
!     - PH_Load_LoadRhs_Type: Load RHS vector (State)
!     - PH_Load_LoadMassRhs_Type: Mass and RHS (State)
!     - PH_Load_Init_Arg / PH_Load_SetGravity_Arg / PH_Load_ApplyLoads_Arg
!   Subroutines: PH_Load_Init, PH_Load_Free, PH_Load_SetGravity, PH_Load_ApplyLoads
! Contract: L4_PH/LoadBC/CONTRACT.md
!===============================================================================

MODULE PH_Load_Def
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE MD_LBC_Domain, ONLY: LOAD_CLOAD, LOAD_GRAVITY
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: slen = 64

  ! ==========================================================================
  ! Load type enumeration
  ! ==========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LOAD_CLOAD     = 1_i4  ! Concentrated force
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LOAD_DLOAD     = 2_i4  ! Distributed load
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LOAD_BODYFORCE = 3_i4  ! Body load
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LOAD_GRAVITY   = 4_i4  ! Gravity
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LOAD_PRESSURE  = 5_i4  ! Pressure
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LOAD_THERMAL   = 6_i4  ! Thermal load

  ! ==========================================================================
  ! Canonical TYPE definitions (PH_Load_*)
  ! ==========================================================================

  !> Element equivalent nodal force type
  TYPE, PUBLIC :: PH_Load_ElemEquivForce_Type
    INTEGER(i4) :: elemId = 0_i4               ! Element ID
    INTEGER(i4) :: nNodes = 0_i4               ! Number of element nodes
    INTEGER(i4), ALLOCATABLE :: nodeIds(:)     ! Node ID list
    REAL(wp), ALLOCATABLE :: equiv_forces(:,:) ! Equivalent nodal forces (nDofs, nNodes)
  END TYPE PH_Load_ElemEquivForce_Type

  !> Surface traction type
  TYPE, PUBLIC :: PH_Load_SurfaceTraction_Type
    CHARACTER(len=slen) :: surfaceName = ""
    INTEGER(i4) :: nFaces = 0_i4
    INTEGER(i4), ALLOCATABLE :: faceIds(:)     ! Face ID list
    REAL(wp), ALLOCATABLE :: traction(:,:)     ! Traction vector (3, nFaces)
  END TYPE PH_Load_SurfaceTraction_Type

  !> Load integration configuration type
  TYPE, PUBLIC :: PH_Load_LoadIntegration_Type
    INTEGER(i4) :: quad_order = 2_i4           ! Gauss quadrature order
    LOGICAL :: use_nodal_lumping = .FALSE.     ! Nodal lumping
    LOGICAL :: use_reduced_integration = .FALSE. ! Reduced integration
  END TYPE PH_Load_LoadIntegration_Type

  !> Single load application cache
  TYPE, PUBLIC :: PH_Load_LoadCache_Type
    INTEGER(i4) :: loadId = 0_i4               ! Load ID
    INTEGER(i4) :: loadType = 0_i4             ! MD_LBC_Domain LOAD_*
    CHARACTER(len=slen) :: target = ""         ! Target object (node set/element set/surface)
    REAL(wp) :: magnitude(3) = 0.0_wp          ! Load vector
    REAL(wp) :: current_time = 0.0_wp          ! Current time
    REAL(wp) :: amp_factor = 1.0_wp            ! Amplitude factor
  END TYPE PH_Load_LoadCache_Type

  !> Load controller (P1 core type)
  TYPE, PUBLIC :: PH_Load_LoadCtrl_Type
    ! Integration strategy
    TYPE(PH_Load_LoadIntegration_Type) :: integration

    ! Load vector
    INTEGER(i4) :: nTotalDOFs = 0_i4
    REAL(wp), ALLOCATABLE :: load_vector(:)    ! Global load vector (nTotalDOFs)

    ! Element equivalent nodal forces
    INTEGER(i4) :: nElemLoads = 0_i4
    TYPE(PH_Load_ElemEquivForce_Type), ALLOCATABLE :: elem_equiv_forces(:)

    ! Surface tractions
    INTEGER(i4) :: nSurfaceLoads = 0_i4
    TYPE(PH_Load_SurfaceTraction_Type), ALLOCATABLE :: surface_tractions(:)

    ! Body loads (gravity, etc.)
    LOGICAL :: has_gravity = .FALSE.
    REAL(wp) :: gravity_vector(3) = 0.0_wp     ! Gravity vector (m/s^2)

    ! Cache current Step's Load list
    INTEGER(i4) :: nActiveLoads = 0_i4
    TYPE(PH_Load_LoadCache_Type), ALLOCATABLE :: load_cache(:)

  END TYPE PH_Load_LoadCtrl_Type

  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  ! ==========================================================================

  !> Load vector R (for load assembly)
  TYPE, PUBLIC :: PH_Load_LoadRhs_Type
    REAL(wp), ALLOCATABLE :: R(:)
  END TYPE PH_Load_LoadRhs_Type

  !> Mass and load vector (for gravity assembly)
  TYPE, PUBLIC :: PH_Load_LoadMassRhs_Type
    REAL(wp), ALLOCATABLE :: M(:)
    REAL(wp), ALLOCATABLE :: R(:)
  END TYPE PH_Load_LoadMassRhs_Type

  !> Structured argument for load controller initialization
  TYPE, PUBLIC :: PH_Load_Init_Arg
    INTEGER(i4) :: nTotalDOFs = 0_i4                  ! [IN]
    TYPE(PH_Load_LoadCtrl_Type) :: ctrl               ! [OUT]
  END TYPE PH_Load_Init_Arg

  !> Structured argument for gravity setting
  TYPE, PUBLIC :: PH_Load_SetGravity_Arg
    REAL(wp) :: gx = 0.0_wp                          ! [IN] gravity x
    REAL(wp) :: gy = 0.0_wp                          ! [IN] gravity y
    REAL(wp) :: gz = 0.0_wp                          ! [IN] gravity z
    TYPE(PH_Load_LoadCtrl_Type) :: ctrl               ! [INOUT]
  END TYPE PH_Load_SetGravity_Arg

  !> Structured argument for load application
  TYPE, PUBLIC :: PH_Load_ApplyLoads_Arg
    INTEGER(i4) :: nLoads = 0_i4                     ! [IN] number of loads
    TYPE(PH_Load_LoadCache_Type), ALLOCATABLE :: load_cache(:) ! [IN]
    TYPE(PH_Load_LoadCtrl_Type) :: ctrl               ! [INOUT]
  END TYPE PH_Load_ApplyLoads_Arg

  ! ==========================================================================
  ! PUBLIC SUBROUTINES (Canonical PH_Load_* naming)
  ! ==========================================================================
  PUBLIC :: PH_Load_Init
  PUBLIC :: PH_Load_Free
  PUBLIC :: PH_Load_SetGravity
  PUBLIC :: PH_Load_ApplyLoads

CONTAINS

  !=============================================================================
  !> @brief Initialize load controller (structured interface)
  !=============================================================================
  SUBROUTINE PH_Load_Init(arg)
    TYPE(PH_Load_Init_Arg), INTENT(INOUT) :: arg

    arg%ctrl%nTotalDOFs = arg%nTotalDOFs
    arg%ctrl%nElemLoads = 0
    arg%ctrl%nSurfaceLoads = 0
    arg%ctrl%nActiveLoads = 0
    arg%ctrl%has_gravity = .FALSE.
    arg%ctrl%gravity_vector = 0.0_wp

    ! Allocate load vector
    ALLOCATE(arg%ctrl%load_vector(arg%nTotalDOFs))
    arg%ctrl%load_vector = 0.0_wp

    ! Default integration configuration
    arg%ctrl%integration%quad_order = 2
    arg%ctrl%integration%use_nodal_lumping = .FALSE.
    arg%ctrl%integration%use_reduced_integration = .FALSE.

  END SUBROUTINE PH_Load_Init

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Load_Free
  ! Purpose: Free load controller memory
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Load_Free(ctrl)
    TYPE(PH_Load_LoadCtrl_Type), INTENT(INOUT) :: ctrl
    INTEGER(i4) :: i

    IF (ALLOCATED(ctrl%load_vector)) DEALLOCATE(ctrl%load_vector)
    IF (ALLOCATED(ctrl%load_cache)) DEALLOCATE(ctrl%load_cache)

    ! Free element equivalent nodal forces
    IF (ALLOCATED(ctrl%elem_equiv_forces)) THEN
      DO i = 1, SIZE(ctrl%elem_equiv_forces)
        IF (ALLOCATED(ctrl%elem_equiv_forces(i)%nodeIds)) &
          DEALLOCATE(ctrl%elem_equiv_forces(i)%nodeIds)
        IF (ALLOCATED(ctrl%elem_equiv_forces(i)%equiv_forces)) &
          DEALLOCATE(ctrl%elem_equiv_forces(i)%equiv_forces)
      END DO
      DEALLOCATE(ctrl%elem_equiv_forces)
    END IF

    ! Free surface tractions
    IF (ALLOCATED(ctrl%surface_tractions)) THEN
      DO i = 1, SIZE(ctrl%surface_tractions)
        IF (ALLOCATED(ctrl%surface_tractions(i)%faceIds)) &
          DEALLOCATE(ctrl%surface_tractions(i)%faceIds)
        IF (ALLOCATED(ctrl%surface_tractions(i)%traction)) &
          DEALLOCATE(ctrl%surface_tractions(i)%traction)
      END DO
      DEALLOCATE(ctrl%surface_tractions)
    END IF

    ctrl%nTotalDOFs = 0
    ctrl%nElemLoads = 0
    ctrl%nSurfaceLoads = 0
    ctrl%nActiveLoads = 0

  END SUBROUTINE PH_Load_Free

  !=============================================================================
  !> @brief Set gravity load (structured interface)
  !=============================================================================
  SUBROUTINE PH_Load_SetGravity(arg)
    TYPE(PH_Load_SetGravity_Arg), INTENT(INOUT) :: arg
    arg%ctrl%has_gravity = .TRUE.
    arg%ctrl%gravity_vector(1) = arg%gx
    arg%ctrl%gravity_vector(2) = arg%gy
    arg%ctrl%gravity_vector(3) = arg%gz
  END SUBROUTINE PH_Load_SetGravity

  !=============================================================================
  !> @brief Apply loads to system (structured interface)
  !=============================================================================
  SUBROUTINE PH_Load_ApplyLoads(arg)
    TYPE(PH_Load_ApplyLoads_Arg), INTENT(INOUT) :: arg

    INTEGER(i4) :: i
    TYPE(PH_Load_SetGravity_Arg) :: gravity_arg

    IF (arg%nLoads > 0 .AND. ALLOCATED(arg%load_cache) .AND. SIZE(arg%load_cache) >= arg%nLoads) THEN
      arg%ctrl%load_vector = 0.0_wp
      arg%ctrl%nActiveLoads = arg%nLoads
      IF (ALLOCATED(arg%ctrl%load_cache)) DEALLOCATE(arg%ctrl%load_cache)
      ALLOCATE(arg%ctrl%load_cache(arg%nLoads))
      arg%ctrl%load_cache = arg%load_cache(1:arg%nLoads)

      DO i = 1, arg%nLoads
        IF (arg%load_cache(i)%loadType == LOAD_GRAVITY) THEN
          ! Set gravity
          gravity_arg%ctrl = arg%ctrl
          gravity_arg%gx = arg%load_cache(i)%magnitude(1) * arg%load_cache(i)%amp_factor
          gravity_arg%gy = arg%load_cache(i)%magnitude(2) * arg%load_cache(i)%amp_factor
          gravity_arg%gz = arg%load_cache(i)%magnitude(3) * arg%load_cache(i)%amp_factor
          CALL PH_Load_SetGravity(gravity_arg)
          arg%ctrl = gravity_arg%ctrl
        END IF
      END DO
    END IF

  END SUBROUTINE PH_Load_ApplyLoads

END MODULE PH_Load_Def
