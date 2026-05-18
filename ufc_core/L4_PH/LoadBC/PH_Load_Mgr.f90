!===============================================================================
! MODULE: PH_Load_Mgr
! LAYER:  L4_PH
! DOMAIN: LoadBC
! ROLE:   Mgr — load vector assembly and application
! BRIEF:  CLoad, gravity, distributed, follower, pressure, thermal load assembly;
!         context-based load manager with Arg bundles.
!===============================================================================
!>>> UFC_PH_CONTRACT | LoadBC/CONTRACT.md

MODULE PH_Load_Mgr
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_LBC_Domain, ONLY: LOAD_CLOAD, LOAD_DLOAD, LOAD_DSLOAD, LOAD_BODY_FORCE, LOAD_PRESSURE
  USE MD_Load_Def, ONLY: LOAD_FAMILY_DIST, LOAD_FAMILY_CONC, LOAD_FAMILY_FLUX
  USE PH_Load_Def
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! LOAD CONTEXT (merged from PH_Load_Ctx 2026-03-09)
  ! ==========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_INTEG_GAUSS   = 1_i4  ! Gauss quadrature
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_INTEG_LOBATTO = 2_i4  ! Gauss-Lobatto
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_INTEG_UNIFORM = 3_i4  ! Uniform distribution

  TYPE, PUBLIC :: PH_Load_Ctx
    INTEGER(i4) :: integration_method = LOAD_INTEG_GAUSS
    INTEGER(i4) :: n_integration_points = 2_i4
    LOGICAL     :: use_consistent_load = .TRUE.
    LOGICAL     :: account_follower = .FALSE.
    INTEGER(i4) :: n_loads_applied = 0_i4
    REAL(wp)    :: total_load_magnitude = 0.0_wp
    INTEGER(i4) :: n_concentrated_loads = 0_i4
    INTEGER(i4) :: n_distributed_loads = 0_i4
    INTEGER(i4) :: n_body_forces = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => PH_Load_Ctx_Init
    PROCEDURE, PUBLIC :: Clear => PH_Load_Ctx_Clear
    PROCEDURE, PUBLIC :: SetIntegMethod => PH_Load_Ctx_SetIntegMethod
    PROCEDURE, PUBLIC :: GetIntegMethod => PH_Load_Ctx_GetIntegMethod
    PROCEDURE, PUBLIC :: IncrementCount => PH_Load_Ctx_IncrementCount
  END TYPE PH_Load_Ctx


  TYPE, PUBLIC :: PH_Load_Ctx_Init_Arg
    INTEGER(i4) :: method = LOAD_INTEG_GAUSS     ! [IN] integration method
    INTEGER(i4) :: n_points = 2_i4               ! [IN] number of integration points
    TYPE(PH_Load_Ctx) :: ctx                     ! [OUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_Ctx_Init_Arg



  TYPE, PUBLIC :: PH_Load_Ctx_SetIntegMethod_Arg
    TYPE(PH_Load_Ctx) :: ctx                     ! [INOUT]
    INTEGER(i4) :: method = LOAD_INTEG_GAUSS     ! [IN]
    INTEGER(i4) :: n_points = 2_i4               ! [IN]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_Ctx_SetIntegMethod_Arg



  TYPE, PUBLIC :: PH_Load_Ctx_IncrementCount_Arg
    TYPE(PH_Load_Ctx) :: ctx                     ! [INOUT]
    CHARACTER(LEN=32) :: load_type = ''           ! [IN]
    REAL(wp) :: magnitude = 0.0_wp               ! [IN] optional magnitude
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_Ctx_IncrementCount_Arg


  PUBLIC :: PH_Load_Ctx_Init_Structured
  PUBLIC :: PH_Load_Ctx_SetIntegMethod_Structured
  PUBLIC :: PH_Load_Ctx_IncrementCount_Structured
  PUBLIC :: PH_Load_AssembleLoadVector

  ! ==========================================================================
  ! PUBLIC TYPES (Load Apply)
  ! ==========================================================================
  PUBLIC :: PH_Load_AssembleCLoad_Arg
  PUBLIC :: PH_Load_AssembleGravity_Arg
  PUBLIC :: PH_Load_ComputeEquivForce_Arg
  ! Body
  PUBLIC :: PH_Load_ApplyBody_Gravity_Arg
  PUBLIC :: PH_Load_ApplyBody_Generic_Arg
  ! Concentrated
  PUBLIC :: PH_Load_ApplyConcentrated_Single_Arg
  PUBLIC :: PH_Load_ApplyConcentrated_Batch_Arg
  ! Distributed
  PUBLIC :: PH_Load_ApplyDistributed_Surface_Arg
  PUBLIC :: PH_Load_ApplyDistributed_Edge_Arg
  ! Follower
  PUBLIC :: PH_Load_ApplyFollower_Pressure_Arg
  PUBLIC :: PH_Load_ComputeFollowerTangent_Arg
  ! Pressure
  PUBLIC :: PH_Load_ApplyPressure_Surface_Arg
  ! Thermal
  PUBLIC :: PH_Load_ApplyThermal_Uniform_Arg
  PUBLIC :: PH_Load_ApplyThermal_Gradient_Arg

  ! ==========================================================================
  ! PUBLIC SUBROUTINES
  ! ==========================================================================
  PUBLIC :: PH_Load_AssembleCLoad, PH_Load_AssembleGravity, PH_Load_ComputeEquivForce
  PUBLIC :: PH_Load_ApplyBody_Gravity, PH_Load_ApplyBody_Generic
  PUBLIC :: PH_Load_ApplyConcentrated_Single, PH_Load_ApplyConcentrated_Batch
  PUBLIC :: PH_Load_ApplyDistributed_Surface, PH_Load_ApplyDistributed_Edge
  PUBLIC :: PH_Load_ApplyFollower_Pressure, PH_Load_ComputeFollowerTangent
  PUBLIC :: PH_Load_ApplyPressure_Surface, PH_Load_ApplyThermal_Uniform, PH_Load_ApplyThermal_Gradient

  ! ==========================================================================
  ! PUBLIC FUNCTIONS
  ! ==========================================================================
  PUBLIC :: PH_Load_ComputeSurfaceNormal

  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES - Assemble (legacy)
  ! ==========================================================================

  TYPE, PUBLIC :: PH_Load_AssembleCLoad_Arg
    TYPE(PH_Load_LoadCtrl_Type) :: ctrl                   ! [IN]
    TYPE(PH_Load_LoadRhs_Type) :: rhs                   ! [INOUT]
  END TYPE PH_Load_AssembleCLoad_Arg



  TYPE, PUBLIC :: PH_Load_AssembleGravity_Arg
    TYPE(PH_Load_LoadCtrl_Type) :: ctrl                   ! [IN]
    TYPE(PH_Load_LoadMassRhs_Type) :: mass_rhs                   ! [INOUT]
  END TYPE PH_Load_AssembleGravity_Arg



  TYPE, PUBLIC :: PH_Load_ComputeEquivForce_Arg
    INTEGER(i4) :: load_type = 0_i4              ! [IN] MD_LBC_Domain: LOAD_DLOAD / etc.
    REAL(wp) :: magnitude(3) = 0.0_wp            ! [IN] load magnitude vector
    REAL(wp), ALLOCATABLE :: elem_coords(:,:)    ! [IN] (nDim, nNodes)
    REAL(wp), ALLOCATABLE :: equiv_forces(:,:)   ! [OUT] (nDim, nNodes)
  END TYPE PH_Load_ComputeEquivForce_Arg


  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES - Body
  ! ==========================================================================

  TYPE, PUBLIC :: PH_Load_ApplyBody_Gravity_Arg
    REAL(wp) :: density = 0.0_wp                 ! [IN]
    REAL(wp) :: gravity_vector(3) = 0.0_wp       ! [IN] gravity acceleration
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyBody_Gravity_Arg



  TYPE, PUBLIC :: PH_Load_ApplyBody_Generic_Arg
    REAL(wp), ALLOCATABLE :: body_force_density(:) ! [IN] body force per unit volume
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyBody_Generic_Arg


  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES - Concentrated
  ! ==========================================================================

  TYPE, PUBLIC :: PH_Load_ApplyConcentrated_Single_Arg
    INTEGER(i4) :: dof_index = 0_i4              ! [IN]
    REAL(wp) :: load_magnitude = 0.0_wp          ! [IN]
    REAL(wp) :: amplitude_factor = 1.0_wp        ! [IN]
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyConcentrated_Single_Arg



  TYPE, PUBLIC :: PH_Load_ApplyConcentrated_Batch_Arg
    INTEGER(i4), ALLOCATABLE :: dof_indices(:)   ! [IN]
    REAL(wp), ALLOCATABLE :: load_magnitudes(:)  ! [IN]
    REAL(wp), ALLOCATABLE :: amplitude_factors(:) ! [IN] optional per-load
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyConcentrated_Batch_Arg


  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES - Distributed
  ! ==========================================================================

  TYPE, PUBLIC :: PH_Load_ApplyDistributed_Surface_Arg
    REAL(wp), ALLOCATABLE :: traction_vector(:)  ! [IN] surface traction
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyDistributed_Surface_Arg



  TYPE, PUBLIC :: PH_Load_ApplyDistributed_Edge_Arg
    REAL(wp) :: edge_length = 0.0_wp             ! [IN]
    INTEGER(i4) :: n_gp = 0_i4                   ! [IN]
    REAL(wp), ALLOCATABLE :: traction_vector(:)  ! [IN] edge traction
    INTEGER(i4), ALLOCATABLE :: edge_dofs(:)     ! [IN] edge DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyDistributed_Edge_Arg


  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES - Follower
  ! ==========================================================================

  TYPE, PUBLIC :: PH_Load_ApplyFollower_Pressure_Arg
    REAL(wp) :: pressure = 0.0_wp                ! [IN]
    LOGICAL :: compute_tangent = .FALSE.         ! [IN]
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:,:)       ! [IN] (nNodes, 2, nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: node_coords(:,:)    ! [IN] (nNodes, 3)
    REAL(wp), ALLOCATABLE :: displacement(:,:)   ! [IN] (nNodes, 3)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    REAL(wp), ALLOCATABLE :: K_T(:,:)            ! [INOUT] tangent stiffness
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyFollower_Pressure_Arg



  TYPE, PUBLIC :: PH_Load_ComputeFollowerTangent_Arg
    REAL(wp) :: pressure = 0.0_wp                ! [IN]
    REAL(wp), ALLOCATABLE :: K_T(:,:)            ! [INOUT] tangent stiffness
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ComputeFollowerTangent_Arg


  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES - Pressure
  ! ==========================================================================

  TYPE, PUBLIC :: PH_Load_ApplyPressure_Surface_Arg
    REAL(wp) :: pressure = 0.0_wp                ! [IN]
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:,:)       ! [IN] (nNodes, 2, nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: node_coords(:,:)    ! [IN] (nNodes, 3)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyPressure_Surface_Arg


  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES - Thermal
  ! ==========================================================================

  TYPE, PUBLIC :: PH_Load_ApplyThermal_Uniform_Arg
    REAL(wp) :: delta_T = 0.0_wp                 ! [IN] temperature change
    REAL(wp) :: alpha = 0.0_wp                   ! [IN] thermal expansion coeff
    REAL(wp) :: D_matrix(6,6) = 0.0_wp           ! [IN] elasticity matrix
    REAL(wp), ALLOCATABLE :: B_matrix(:,:,:)     ! [IN] (6, nDofElem, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyThermal_Uniform_Arg



  TYPE, PUBLIC :: PH_Load_ApplyThermal_Gradient_Arg
    REAL(wp) :: T_ref = 0.0_wp                   ! [IN] reference temperature
    REAL(wp) :: alpha = 0.0_wp                   ! [IN] thermal expansion coeff
    REAL(wp) :: D_matrix(6,6) = 0.0_wp           ! [IN] elasticity matrix
    REAL(wp), ALLOCATABLE :: T_nodes(:)          ! [IN] nodal temperatures
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: B_matrix(:,:,:)     ! [IN] (6, nDofElem, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyThermal_Gradient_Arg


CONTAINS

  !-----------------------------------------------------------------------------
  ! Load Context (merged from PH_Load_Ctx)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Load_Ctx_Init(this, method, n_points)
    CLASS(PH_Load_Ctx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: method
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_points
    this%integration_method = LOAD_INTEG_GAUSS
    this%n_integration_points = 2_i4
    this%use_consistent_load = .TRUE.
    this%account_follower = .FALSE.
    this%n_loads_applied = 0_i4
    this%total_load_magnitude = 0.0_wp
    this%n_concentrated_loads = 0_i4
    this%n_distributed_loads = 0_i4
    this%n_body_forces = 0_i4
    IF (PRESENT(method)) this%integration_method = method
    IF (PRESENT(n_points)) this%n_integration_points = n_points
  END SUBROUTINE PH_Load_Ctx_Init

  SUBROUTINE PH_Load_Ctx_Init_Structured(arg)
    TYPE(PH_Load_Ctx_Init_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    CALL arg%ctx%Init(method=arg%method, n_points=arg%n_points)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Load_Ctx_Init_Structured

  SUBROUTINE PH_Load_Ctx_Clear(this)
    CLASS(PH_Load_Ctx), INTENT(INOUT) :: this
    this%n_loads_applied = 0_i4
    this%total_load_magnitude = 0.0_wp
    this%n_concentrated_loads = 0_i4
    this%n_distributed_loads = 0_i4
    this%n_body_forces = 0_i4
  END SUBROUTINE PH_Load_Ctx_Clear

  SUBROUTINE PH_Load_Ctx_SetIntegMethod(this, method, n_points)
    CLASS(PH_Load_Ctx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: method
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_points
    this%integration_method = method
    IF (PRESENT(n_points)) this%n_integration_points = n_points
  END SUBROUTINE PH_Load_Ctx_SetIntegMethod

  SUBROUTINE PH_Load_Ctx_SetIntegMethod_Structured(arg)
    TYPE(PH_Load_Ctx_SetIntegMethod_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%ctx = arg%ctx
    CALL arg%ctx%SetIntegMethod(method=arg%method, n_points=arg%n_points)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Load_Ctx_SetIntegMethod_Structured

  FUNCTION PH_Load_Ctx_GetIntegMethod(this) RESULT(method)
    CLASS(PH_Load_Ctx), INTENT(IN) :: this
    INTEGER(i4) :: method
    method = this%integration_method
  END FUNCTION PH_Load_Ctx_GetIntegMethod

  SUBROUTINE PH_Load_Ctx_IncrementCount(this, load_type, magnitude)
    CLASS(PH_Load_Ctx), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: load_type
    REAL(wp), INTENT(IN), OPTIONAL :: magnitude
    this%n_loads_applied = this%n_loads_applied + 1_i4
    SELECT CASE (TRIM(load_type))
    CASE ('CONCENTRATED')
      this%n_concentrated_loads = this%n_concentrated_loads + 1_i4
    CASE ('DISTRIBUTED')
      this%n_distributed_loads = this%n_distributed_loads + 1_i4
    CASE ('BODY')
      this%n_body_forces = this%n_body_forces + 1_i4
    END SELECT
    IF (PRESENT(magnitude)) this%total_load_magnitude = this%total_load_magnitude + ABS(magnitude)
  END SUBROUTINE PH_Load_Ctx_IncrementCount

  SUBROUTINE PH_Load_Ctx_IncrementCount_Structured(arg)
    TYPE(PH_Load_Ctx_IncrementCount_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%ctx = arg%ctx
    CALL arg%ctx%IncrementCount(load_type=arg%load_type, magnitude=arg%magnitude)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Load_Ctx_IncrementCount_Structured

  !-----------------------------------------------------------------------------
  ! Assemble (legacy)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Load_AssembleCLoad(arg)
    TYPE(PH_Load_AssembleCLoad_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i, dof_id
    REAL(wp) :: force_value
    arg%rhs = arg%rhs
    IF (.NOT. ALLOCATED(arg%rhs%R)) RETURN
    DO i = 1, arg%ctrl%nActiveLoads
      IF (arg%ctrl%load_cache(i)%loadType == LOAD_CLOAD) THEN
        dof_id = arg%ctrl%load_cache(i)%loadId
        IF (dof_id > 0 .AND. dof_id <= SIZE(arg%rhs%R)) THEN
          force_value = arg%ctrl%load_cache(i)%magnitude(1) * arg%ctrl%load_cache(i)%amp_factor
          arg%rhs%R(dof_id) = arg%rhs%R(dof_id) + force_value
        END IF
      END IF
    END DO
  END SUBROUTINE PH_Load_AssembleCLoad

  SUBROUTINE PH_Load_AssembleGravity(arg)
    TYPE(PH_Load_AssembleGravity_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i, nDOFs, nNodes, node_dofs
    REAL(wp) :: gx, gy, gz
    arg%mass_rhs = arg%mass_rhs
    IF (.NOT. arg%ctrl%has_gravity) RETURN
    IF (.NOT. ALLOCATED(arg%mass_rhs%M) .OR. .NOT. ALLOCATED(arg%mass_rhs%R)) RETURN
    gx = arg%ctrl%gravity_vector(1)
    gy = arg%ctrl%gravity_vector(2)
    gz = arg%ctrl%gravity_vector(3)
    nDOFs = SIZE(arg%mass_rhs%R)
    node_dofs = 3
    nNodes = nDOFs / node_dofs
    DO i = 1, nNodes
      arg%mass_rhs%R((i-1)*node_dofs + 1) = arg%mass_rhs%R((i-1)*node_dofs + 1) + arg%mass_rhs%M(i) * gx
      arg%mass_rhs%R((i-1)*node_dofs + 2) = arg%mass_rhs%R((i-1)*node_dofs + 2) + arg%mass_rhs%M(i) * gy
      arg%mass_rhs%R((i-1)*node_dofs + 3) = arg%mass_rhs%R((i-1)*node_dofs + 3) + arg%mass_rhs%M(i) * gz
    END DO
  END SUBROUTINE PH_Load_AssembleGravity

  SUBROUTINE PH_Load_ComputeEquivForce(arg)
    TYPE(PH_Load_ComputeEquivForce_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: nNodes, nDim, i, j
    REAL(wp) :: volume, avg_force(3)
    IF (.NOT. ALLOCATED(arg%elem_coords)) RETURN
    nDim = SIZE(arg%elem_coords, 1)
    nNodes = SIZE(arg%elem_coords, 2)
    ALLOCATE(arg%equiv_forces(nDim, nNodes))
    arg%equiv_forces = 0.0_wp
    SELECT CASE(arg%load_type)
    CASE(LOAD_DLOAD, LOAD_BODY_FORCE, LOAD_DSLOAD)
      volume = 1.0_wp
      avg_force = arg%magnitude * volume
      DO i = 1, nNodes
        DO j = 1, nDim
          arg%equiv_forces(j, i) = avg_force(j) / REAL(nNodes, wp)
        END DO
      END DO
    CASE(LOAD_PRESSURE)
      DO i = 1, nNodes
        arg%equiv_forces(:, i) = arg%magnitude / REAL(nNodes, wp)
      END DO
    END SELECT
  END SUBROUTINE PH_Load_ComputeEquivForce

  !-----------------------------------------------------------------------------
  ! Body
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Load_ApplyBody_Generic(arg)
    TYPE(PH_Load_ApplyBody_Generic_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: n_nodes, n_gp, i_gp, i_node, i_dof, dof_idx
    REAL(wp) :: F_gp, load_mag
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    arg%load_ctx = arg%load_ctx
    IF (.NOT. ALLOCATED(arg%elem_dofs) .OR. .NOT. ALLOCATED(arg%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyBody_Generic: Invalid input arrays'
      arg%status = local_status
      RETURN
    END IF
    n_nodes = SIZE(arg%elem_dofs)
    n_gp = SIZE(arg%gauss_weights)
    IF (SIZE(arg%shape_funcs, 2) /= n_gp .OR. SIZE(arg%shape_funcs, 1) /= n_nodes) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyBody_Generic: Shape function size mismatch'
      arg%status = local_status
      RETURN
    END IF
    load_mag = 0.0_wp
    DO i_node = 1, n_nodes
      DO i_dof = 1, SIZE(arg%body_force_density)
        F_gp = 0.0_wp
        DO i_gp = 1, n_gp
          F_gp = F_gp + arg%shape_funcs(i_node, i_gp) * arg%body_force_density(i_dof) &
               * arg%detJ(i_gp) * arg%gauss_weights(i_gp)
        END DO
        dof_idx = arg%elem_dofs(i_node) * SIZE(arg%body_force_density) - SIZE(arg%body_force_density) + i_dof
        IF (dof_idx > 0 .AND. dof_idx <= SIZE(arg%F)) THEN
          arg%F(dof_idx) = arg%F(dof_idx) + F_gp
          load_mag = load_mag + ABS(F_gp)
        END IF
      END DO
    END DO
    CALL arg%load_ctx%IncrementCount('BODY', load_mag)
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyBody_Generic

  SUBROUTINE PH_Load_ApplyBody_Gravity(arg)
    TYPE(PH_Load_ApplyBody_Gravity_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: n_nodes, n_gp, i_gp, i_node, i_dof, dof_idx
    REAL(wp) :: F_gp, load_mag, body_force
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    arg%load_ctx = arg%load_ctx
    IF (.NOT. ALLOCATED(arg%elem_dofs) .OR. .NOT. ALLOCATED(arg%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyBody_Gravity: Invalid input arrays'
      arg%status = local_status
      RETURN
    END IF
    n_nodes = SIZE(arg%elem_dofs)
    n_gp = SIZE(arg%gauss_weights)
    IF (SIZE(arg%shape_funcs, 2) /= n_gp .OR. SIZE(arg%shape_funcs, 1) /= n_nodes) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyBody_Gravity: Shape function size mismatch'
      arg%status = local_status
      RETURN
    END IF
    load_mag = 0.0_wp
    DO i_node = 1, n_nodes
      DO i_dof = 1, SIZE(arg%gravity_vector)
        F_gp = 0.0_wp
        DO i_gp = 1, n_gp
          body_force = arg%density * arg%gravity_vector(i_dof)
          F_gp = F_gp + arg%shape_funcs(i_node, i_gp) * body_force &
               * arg%detJ(i_gp) * arg%gauss_weights(i_gp)
        END DO
        dof_idx = arg%elem_dofs(i_node) * SIZE(arg%gravity_vector) - SIZE(arg%gravity_vector) + i_dof
        IF (dof_idx > 0 .AND. dof_idx <= SIZE(arg%F)) THEN
          arg%F(dof_idx) = arg%F(dof_idx) + F_gp
          load_mag = load_mag + ABS(F_gp)
        END IF
      END DO
    END DO
    CALL arg%load_ctx%IncrementCount('BODY', load_mag)
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyBody_Gravity

  !-----------------------------------------------------------------------------
  ! Concentrated
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Load_ApplyConcentrated_Single(arg)
    TYPE(PH_Load_ApplyConcentrated_Single_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: n_dof
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    IF (.NOT. ALLOCATED(arg%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyConcentrated_Single: Invalid input array'
      arg%status = local_status
      RETURN
    END IF
    n_dof = SIZE(arg%F)
    IF (arg%dof_index < 1 .OR. arg%dof_index > n_dof) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyConcentrated_Single: Invalid DOF index'
      arg%status = local_status
      RETURN
    END IF
    arg%F(arg%dof_index) = arg%F(arg%dof_index) + arg%load_magnitude * arg%amplitude_factor
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyConcentrated_Single

  SUBROUTINE PH_Load_ApplyConcentrated_Batch(arg)
    TYPE(PH_Load_ApplyConcentrated_Batch_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: i, n_load
    REAL(wp) :: amp_factor
    TYPE(PH_Load_ApplyConcentrated_Single_Arg) :: single_arg
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    arg%load_ctx = arg%load_ctx
    IF (.NOT. ALLOCATED(arg%dof_indices) .OR. .NOT. ALLOCATED(arg%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyConcentrated_Batch: Invalid input arrays'
      arg%status = local_status
      RETURN
    END IF
    n_load = SIZE(arg%dof_indices)
    IF (SIZE(arg%load_magnitudes) /= n_load) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyConcentrated_Batch: Size mismatch'
      arg%status = local_status
      RETURN
    END IF
    IF (ALLOCATED(arg%amplitude_factors)) THEN
      IF (SIZE(arg%amplitude_factors) /= n_load) THEN
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = 'PH_Load_ApplyConcentrated_Batch: Amplitude size mismatch'
        arg%status = local_status
        RETURN
      END IF
    END IF
    ALLOCATE(single_arg%F(SIZE(arg%F)))
    single_arg%F = arg%F
    DO i = 1, n_load
      amp_factor = 1.0_wp
      IF (ALLOCATED(arg%amplitude_factors)) amp_factor = arg%amplitude_factors(i)
      single_arg%dof_index = arg%dof_indices(i)
      single_arg%load_magnitude = arg%load_magnitudes(i)
      single_arg%amplitude_factor = amp_factor
      CALL PH_Load_ApplyConcentrated_Single(single_arg)
      IF (single_arg%status%status_code /= IF_STATUS_OK) THEN
        arg%status = single_arg%status
        IF (ALLOCATED(single_arg%F)) DEALLOCATE(single_arg%F)
        RETURN
      END IF
      CALL arg%load_ctx%IncrementCount('CONCENTRATED', arg%load_magnitudes(i))
    END DO
    arg%F = single_arg%F
    IF (ALLOCATED(single_arg%F)) DEALLOCATE(single_arg%F)
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyConcentrated_Batch

  !-----------------------------------------------------------------------------
  ! Distributed
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Load_ApplyDistributed_Edge(arg)
    TYPE(PH_Load_ApplyDistributed_Edge_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: n_nodes, i_node, i_dof, dof_idx
    REAL(wp) :: load_per_node, load_mag
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    arg%load_ctx = arg%load_ctx
    IF (.NOT. ALLOCATED(arg%edge_dofs) .OR. .NOT. ALLOCATED(arg%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyDistributed_Edge: Invalid input arrays'
      arg%status = local_status
      RETURN
    END IF
    n_nodes = SIZE(arg%edge_dofs)
    load_per_node = arg%edge_length / REAL(n_nodes, wp)
    load_mag = 0.0_wp
    DO i_node = 1, n_nodes
      DO i_dof = 1, SIZE(arg%traction_vector)
        dof_idx = arg%edge_dofs(i_node) * SIZE(arg%traction_vector) - SIZE(arg%traction_vector) + i_dof
        IF (dof_idx > 0 .AND. dof_idx <= SIZE(arg%F)) THEN
          arg%F(dof_idx) = arg%F(dof_idx) + arg%traction_vector(i_dof) * load_per_node
          load_mag = load_mag + ABS(arg%traction_vector(i_dof) * load_per_node)
        END IF
      END DO
    END DO
    CALL arg%load_ctx%IncrementCount('DISTRIBUTED', load_mag)
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyDistributed_Edge

  SUBROUTINE PH_Load_ApplyDistributed_Surface(arg)
    TYPE(PH_Load_ApplyDistributed_Surface_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: n_nodes, n_gp, i_gp, i_node, i_dof, dof_idx
    REAL(wp) :: F_gp, load_mag
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    arg%load_ctx = arg%load_ctx
    IF (.NOT. ALLOCATED(arg%elem_dofs) .OR. .NOT. ALLOCATED(arg%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyDistributed_Surface: Invalid input arrays'
      arg%status = local_status
      RETURN
    END IF
    n_nodes = SIZE(arg%elem_dofs)
    n_gp = SIZE(arg%gauss_weights)
    IF (SIZE(arg%shape_funcs, 2) /= n_gp .OR. SIZE(arg%shape_funcs, 1) /= n_nodes) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyDistributed_Surface: Shape function size mismatch'
      arg%status = local_status
      RETURN
    END IF
    load_mag = 0.0_wp
    DO i_node = 1, n_nodes
      DO i_dof = 1, SIZE(arg%traction_vector)
        F_gp = 0.0_wp
        DO i_gp = 1, n_gp
          F_gp = F_gp + arg%shape_funcs(i_node, i_gp) * arg%traction_vector(i_dof) &
               * arg%detJ(i_gp) * arg%gauss_weights(i_gp)
        END DO
        dof_idx = arg%elem_dofs(i_node) * SIZE(arg%traction_vector) - SIZE(arg%traction_vector) + i_dof
        IF (dof_idx > 0 .AND. dof_idx <= SIZE(arg%F)) THEN
          arg%F(dof_idx) = arg%F(dof_idx) + F_gp
          load_mag = load_mag + ABS(F_gp)
        END IF
      END DO
    END DO
    CALL arg%load_ctx%IncrementCount('DISTRIBUTED', load_mag)
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyDistributed_Surface

  !-----------------------------------------------------------------------------
  ! Follower
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Load_ApplyFollower_Pressure(arg)
    TYPE(PH_Load_ApplyFollower_Pressure_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: n_nodes, n_gp, i_gp, i_node, i_dim, j_node, j_dim
    INTEGER(i4) :: dof_idx_i, dof_idx_j
    REAL(wp) :: dx_dxi(3), dx_deta(3), normal(3)
    REAL(wp) :: detJ, F_gp(3), load_mag
    REAL(wp) :: dN_du(3,3), K_T_elem(3,3)
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    IF (ALLOCATED(arg%K_T) .AND. arg%compute_tangent) THEN

      arg%K_T = arg%K_T
    END IF
    arg%load_ctx = arg%load_ctx
    IF (.NOT. ALLOCATED(arg%elem_dofs) .OR. .NOT. ALLOCATED(arg%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyFollower_Pressure: Invalid input arrays'
      arg%status = local_status
      RETURN
    END IF
    n_nodes = SIZE(arg%elem_dofs)
    n_gp = SIZE(arg%gauss_weights)
    load_mag = 0.0_wp
    DO i_gp = 1, n_gp
      dx_dxi = 0.0_wp
      dx_deta = 0.0_wp
      DO i_node = 1, n_nodes
        DO i_dim = 1, 3
          dx_dxi(i_dim) = dx_dxi(i_dim) + arg%dN_dxi(i_node, 1, i_gp) * &
                         (arg%node_coords(i_node, i_dim) + arg%displacement(i_node, i_dim))
          dx_deta(i_dim) = dx_deta(i_dim) + arg%dN_dxi(i_node, 2, i_gp) * &
                          (arg%node_coords(i_node, i_dim) + arg%displacement(i_node, i_dim))
        END DO
      END DO
      normal(1) = dx_dxi(2) * dx_deta(3) - dx_dxi(3) * dx_deta(2)
      normal(2) = dx_dxi(3) * dx_deta(1) - dx_dxi(1) * dx_deta(3)
      normal(3) = dx_dxi(1) * dx_deta(2) - dx_dxi(2) * dx_deta(1)
      detJ = SQRT(normal(1)**2 + normal(2)**2 + normal(3)**2)
      IF (detJ > 1.0e-12_wp) THEN
        normal = normal / detJ
      ELSE
        normal = 0.0_wp
      END IF
      F_gp = arg%pressure * normal * detJ * arg%gauss_weights(i_gp)
      DO i_node = 1, n_nodes
        DO i_dim = 1, 3
          dof_idx_i = arg%elem_dofs(i_node) * 3 - 3 + i_dim
          IF (dof_idx_i > 0 .AND. dof_idx_i <= SIZE(arg%F)) THEN
            arg%F(dof_idx_i) = arg%F(dof_idx_i) + arg%shape_funcs(i_node, i_gp) * F_gp(i_dim)
            load_mag = load_mag + ABS(arg%shape_funcs(i_node, i_gp) * F_gp(i_dim))
          END IF
        END DO
      END DO
      IF (arg%compute_tangent .AND. ALLOCATED(arg%K_T)) THEN
        K_T_elem = 0.0_wp
        DO i_node = 1, n_nodes
          DO j_node = 1, n_nodes
            DO i_dim = 1, 3
              DO j_dim = 1, 3
                dN_du(i_dim, j_dim) = arg%pressure * arg%shape_funcs(i_node, i_gp) * &
                                     arg%shape_funcs(j_node, i_gp) * arg%gauss_weights(i_gp)
                dof_idx_i = arg%elem_dofs(i_node) * 3 - 3 + i_dim
                dof_idx_j = arg%elem_dofs(j_node) * 3 - 3 + j_dim
                IF (dof_idx_i > 0 .AND. dof_idx_i <= SIZE(arg%K_T, 1) .AND. &
                    dof_idx_j > 0 .AND. dof_idx_j <= SIZE(arg%K_T, 2)) THEN
                  arg%K_T(dof_idx_i, dof_idx_j) = arg%K_T(dof_idx_i, dof_idx_j) + dN_du(i_dim, j_dim)
                END IF
              END DO
            END DO
          END DO
        END DO
      END IF
    END DO
    CALL arg%load_ctx%IncrementCount('DISTRIBUTED', load_mag)
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyFollower_Pressure

  SUBROUTINE PH_Load_ComputeFollowerTangent(arg)
    TYPE(PH_Load_ComputeFollowerTangent_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%K_T)) THEN

      arg%K_T = arg%K_T
    END IF
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ComputeFollowerTangent

  !-----------------------------------------------------------------------------
  ! Pressure
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Load_ApplyPressure_Surface(arg)
    TYPE(PH_Load_ApplyPressure_Surface_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: n_nodes, n_gp, i_gp, i_node, i_dim, dof_idx
    REAL(wp) :: dx_dxi(3), dx_deta(3), normal(3), detJ
    REAL(wp) :: F_gp(3), load_mag
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    arg%load_ctx = arg%load_ctx
    IF (.NOT. ALLOCATED(arg%elem_dofs) .OR. .NOT. ALLOCATED(arg%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyPressure_Surface: Invalid input arrays'
      arg%status = local_status
      RETURN
    END IF
    n_nodes = SIZE(arg%elem_dofs)
    n_gp = SIZE(arg%gauss_weights)
    load_mag = 0.0_wp
    DO i_gp = 1, n_gp
      dx_dxi = 0.0_wp
      dx_deta = 0.0_wp
      DO i_node = 1, n_nodes
        DO i_dim = 1, 3
          dx_dxi(i_dim) = dx_dxi(i_dim) + arg%dN_dxi(i_node, 1, i_gp) * arg%node_coords(i_node, i_dim)
          dx_deta(i_dim) = dx_deta(i_dim) + arg%dN_dxi(i_node, 2, i_gp) * arg%node_coords(i_node, i_dim)
        END DO
      END DO
      normal = PH_Load_ComputeSurfaceNormal(dx_dxi, dx_deta)
      detJ = SQRT(dx_dxi(1)**2 + dx_dxi(2)**2 + dx_dxi(3)**2) * &
             SQRT(dx_deta(1)**2 + dx_deta(2)**2 + dx_deta(3)**2)
      F_gp = arg%pressure * normal * detJ * arg%gauss_weights(i_gp)
      DO i_node = 1, n_nodes
        DO i_dim = 1, 3
          dof_idx = arg%elem_dofs(i_node) * 3 - 3 + i_dim
          IF (dof_idx > 0 .AND. dof_idx <= SIZE(arg%F)) THEN
            arg%F(dof_idx) = arg%F(dof_idx) + arg%shape_funcs(i_node, i_gp) * F_gp(i_dim)
            load_mag = load_mag + ABS(arg%shape_funcs(i_node, i_gp) * F_gp(i_dim))
          END IF
        END DO
      END DO
    END DO
    CALL arg%load_ctx%IncrementCount('DISTRIBUTED', load_mag)
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyPressure_Surface

  FUNCTION PH_Load_ComputeSurfaceNormal(dx_dxi, dx_deta) RESULT(normal)
    REAL(wp), INTENT(IN) :: dx_dxi(3), dx_deta(3)
    REAL(wp) :: normal(3)
    REAL(wp) :: norm
    normal(1) = dx_dxi(2) * dx_deta(3) - dx_dxi(3) * dx_deta(2)
    normal(2) = dx_dxi(3) * dx_deta(1) - dx_dxi(1) * dx_deta(3)
    normal(3) = dx_dxi(1) * dx_deta(2) - dx_dxi(2) * dx_deta(1)
    norm = SQRT(normal(1)**2 + normal(2)**2 + normal(3)**2)
    IF (norm > 1.0e-12_wp) THEN
      normal = normal / norm
    ELSE
      normal = 0.0_wp
    END IF
  END FUNCTION PH_Load_ComputeSurfaceNormal

  !-----------------------------------------------------------------------------
  ! Thermal
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Load_ApplyThermal_Gradient(arg)
    TYPE(PH_Load_ApplyThermal_Gradient_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: n_nodes, n_dof_elem, n_gp, i_gp, i_node, i, j
    REAL(wp) :: T_gp, delta_T_gp
    REAL(wp) :: epsilon_th(6), sigma_th(6), F_elem_gp(24)
    REAL(wp) :: load_mag
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    arg%load_ctx = arg%load_ctx
    IF (.NOT. ALLOCATED(arg%elem_dofs) .OR. .NOT. ALLOCATED(arg%F) .OR. .NOT. ALLOCATED(arg%T_nodes)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyThermal_Gradient: Invalid input arrays'
      arg%status = local_status
      RETURN
    END IF
    n_nodes = SIZE(arg%T_nodes)
    n_dof_elem = SIZE(arg%elem_dofs)
    n_gp = SIZE(arg%gauss_weights)
    load_mag = 0.0_wp
    DO i_gp = 1, n_gp
      T_gp = 0.0_wp
      DO i_node = 1, n_nodes
        T_gp = T_gp + arg%shape_funcs(i_node, i_gp) * arg%T_nodes(i_node)
      END DO
      delta_T_gp = T_gp - arg%T_ref
      epsilon_th = 0.0_wp
      epsilon_th(1:3) = arg%alpha * delta_T_gp
      sigma_th = 0.0_wp
      DO i = 1, 6
        DO j = 1, 6
          sigma_th(i) = sigma_th(i) + arg%D_matrix(i, j) * epsilon_th(j)
        END DO
      END DO
      F_elem_gp = 0.0_wp
      DO i = 1, n_dof_elem
        DO j = 1, 6
          F_elem_gp(i) = F_elem_gp(i) - arg%B_matrix(j, i, i_gp) * sigma_th(j) * &
                        arg%detJ(i_gp) * arg%gauss_weights(i_gp)
        END DO
      END DO
      DO i = 1, n_dof_elem
        IF (arg%elem_dofs(i) > 0 .AND. arg%elem_dofs(i) <= SIZE(arg%F)) THEN
          arg%F(arg%elem_dofs(i)) = arg%F(arg%elem_dofs(i)) + F_elem_gp(i)
          load_mag = load_mag + ABS(F_elem_gp(i))
        END IF
      END DO
    END DO
    CALL arg%load_ctx%IncrementCount('BODY', load_mag)
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyThermal_Gradient

  SUBROUTINE PH_Load_ApplyThermal_Uniform(arg)
    TYPE(PH_Load_ApplyThermal_Uniform_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: n_dof_elem, n_gp, i_gp, i, j
    REAL(wp) :: epsilon_th(6), sigma_th(6), F_elem_gp(24)
    REAL(wp) :: load_mag
    CALL init_error_status(local_status)
    IF (ALLOCATED(arg%F)) THEN

      arg%F = arg%F
    END IF
    arg%load_ctx = arg%load_ctx
    IF (.NOT. ALLOCATED(arg%elem_dofs) .OR. .NOT. ALLOCATED(arg%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_Load_ApplyThermal_Uniform: Invalid input arrays'
      arg%status = local_status
      RETURN
    END IF
    n_dof_elem = SIZE(arg%elem_dofs)
    n_gp = SIZE(arg%gauss_weights)
    load_mag = 0.0_wp
    epsilon_th = 0.0_wp
    epsilon_th(1:3) = arg%alpha * arg%delta_T
    sigma_th = 0.0_wp
    DO i = 1, 6
      DO j = 1, 6
        sigma_th(i) = sigma_th(i) + arg%D_matrix(i, j) * epsilon_th(j)
      END DO
    END DO
    DO i_gp = 1, n_gp
      F_elem_gp = 0.0_wp
      DO i = 1, n_dof_elem
        DO j = 1, 6
          F_elem_gp(i) = F_elem_gp(i) - arg%B_matrix(j, i, i_gp) * sigma_th(j) * &
                        arg%detJ(i_gp) * arg%gauss_weights(i_gp)
        END DO
      END DO
      DO i = 1, n_dof_elem
        IF (arg%elem_dofs(i) > 0 .AND. arg%elem_dofs(i) <= SIZE(arg%F)) THEN
          arg%F(arg%elem_dofs(i)) = arg%F(arg%elem_dofs(i)) + F_elem_gp(i)
          load_mag = load_mag + ABS(F_elem_gp(i))
        END IF
      END DO
    END DO
    CALL arg%load_ctx%IncrementCount('BODY', load_mag)
    local_status%status_code = IF_STATUS_OK
    arg%status = local_status
  END SUBROUTINE PH_Load_ApplyThermal_Uniform

  !=============================================================================
  !> @brief Unified load vector assembly wrapper
  !> @details Combines all load types (concentrated, distributed, body force,
  !>          pressure, thermal) into a single global load vector.
  !>
  !> This is a high-level wrapper that delegates to specialized load application
  !> subroutines (PH_Load_AssembleCLoad, PH_Load_ApplyBody_Gravity, etc.).
  !>
  !> @param[in] ctrl       - Load controller containing active loads
  !> @param[in] time       - Current analysis time
  !> @param[inout] F       - Global load vector (assembled in-place)
  !> @param[out] status    - Error status
  !=============================================================================
  SUBROUTINE PH_Load_AssembleLoadVector(ctrl, time, F, status)
    TYPE(PH_Load_LoadCtrl_Type), INTENT(IN) :: ctrl
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Local variables for load iteration
    INTEGER(i4) :: n_loads, i_load, load_type
    TYPE(ErrorStatusType) :: local_status
    REAL(wp) :: total_load_magnitude

    ! Initialize
    CALL init_error_status(status)
    CALL init_error_status(local_status)
    total_load_magnitude = 0.0_wp

    ! Get number of loads from controller
    n_loads = ctrl%nActiveLoads
    IF (n_loads <= 0 .OR. .NOT. ALLOCATED(ctrl%load_cache)) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Iterate through all loads and apply
    DO i_load = 1, n_loads
      load_type = ctrl%load_cache(i_load)%loadType

      SELECT CASE (load_type)
      CASE (1)  ! Concentrated load (CLOAD)
        ! Direct DOF assembly: F(dof) += magnitude * amp_factor
        CALL AssembleSingleCLoad(ctrl%load_cache(i_load), F, local_status)

      CASE (2)  ! Distributed load (DLOAD)
        ! Placeholder: requires element shape functions
        local_status%status_code = IF_STATUS_OK

      CASE (3)  ! Body force (GRAVITY)
        ! Placeholder: requires mass matrix integration
        local_status%status_code = IF_STATUS_OK

      CASE (4)  ! Pressure load
        ! Placeholder: requires surface normal computation
        local_status%status_code = IF_STATUS_OK

      CASE (5)  ! Thermal load
        ! Placeholder: requires thermal strain computation
        local_status%status_code = IF_STATUS_OK

      CASE DEFAULT
        ! Unknown load type - skip
        CYCLE
      END SELECT

      ! Accumulate load magnitude
      IF (local_status%status_code == IF_STATUS_OK) THEN
        total_load_magnitude = total_load_magnitude + &
          ABS(ctrl%load_cache(i_load)%magnitude(1))
      END IF
    END DO

    ! Set success status
    status%status_code = IF_STATUS_OK

  CONTAINS

    !-------------------------------------------------------------------------
    !> @brief Apply single concentrated load directly
    !-------------------------------------------------------------------------
    SUBROUTINE AssembleSingleCLoad(cache, F_vec, ierr)
      TYPE(PH_Load_LoadCache_Type), INTENT(IN) :: cache
      REAL(wp), INTENT(INOUT) :: F_vec(:)
      TYPE(ErrorStatusType), INTENT(OUT) :: ierr
      INTEGER(i4) :: dof_id
      REAL(wp) :: force_value

      CALL init_error_status(ierr)
      dof_id = cache%loadId
      IF (dof_id > 0 .AND. dof_id <= SIZE(F_vec)) THEN
        force_value = cache%magnitude(1) * cache%amp_factor
        F_vec(dof_id) = F_vec(dof_id) + force_value
      END IF
      ierr%status_code = IF_STATUS_OK
    END SUBROUTINE AssembleSingleCLoad

  END SUBROUTINE PH_Load_AssembleLoadVector

END MODULE PH_Load_Mgr