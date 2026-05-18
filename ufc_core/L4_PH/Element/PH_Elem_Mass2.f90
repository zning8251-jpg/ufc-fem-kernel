!===============================================================================
! MODULE: PH_Elem_Mass2
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  Mass matrix physical computation for dynamics analysis
!===============================================================================
MODULE PH_Elem_Mass2
!> [PROD] Physical mass matrix computation
!> Theory: Variational formulation, row-sum lumping, HRZ scaling
!> Status: Production | Last verified: 2026-02-28
  
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE MD_Base_ElemLib, ONLY: UF_GetGaussPoints, UF_GetShapeFunctions, &
                                   UF_ComputeJacobian
  USE PH_Elem_ShapeFunc, ONLY: PH_Elem_ShapeFunc_Ctx
  
  IMPLICIT NONE
  PRIVATE
  
  !--- SECTION 2: MODULE CONSTANTS ---
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_MASS_CONSIST    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_MASS_LUMP_ROWSUM = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_MASS_LUMP_DIAG  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_MASS_LUMP_HRZ   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_MASS_HYBRID     = 5_i4

  
  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Mass_Algo
  ! KIND: Algo
  ! DESC: Mass computation algorithm parameters.
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_Mass_Algo
  PUBLIC :: PH_Elem_Mass_State
  
  ! ===================================================================
  ! Public Procedures
  ! ===================================================================
  PUBLIC :: PH_Elem_Mass_Consistent
  PUBLIC :: PH_Elem_Mass_Lumped
  PUBLIC :: PH_Elem_Mass_Hybrid
  
  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Mass_Algo
  ! KIND: Algo
  ! DESC: Mass computation algorithm parameters.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Mass_Algo
    !! Mass computation parameters
    !! Groups: density, formulation options, numerical integration
    
    real(wp) :: density = 0.0_wp           ! Material density (ρ)
    integer(i4) :: mass_formulation = PH_ELEM_MASS_CONSIST
    logical :: incl_rot_inertia = .FALSE.  ! Include rotational DOF inertia
    real(wp) :: mass_scaling = 1.0_wp      ! Global mass scaling factor
    
    ! Numerical integration
    integer(i4) :: n_gauss_points = 0_i4
    real(wp), allocatable :: gauss_weights(:)
    real(wp), allocatable :: gauss_coords(:,:)
    
  CONTAINS
    PROCEDURE, PUBLIC :: Init => Algo_Init
    PROCEDURE, PUBLIC :: Valid => Algo_Valid
  END TYPE PH_Elem_Mass_Algo
  
  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Mass_State
  ! KIND: State
  ! DESC: Mass computation result (element mass, lumped, statistics).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Mass_State
    !! Computed mass matrix result
    !! Contains: element mass matrix, statistics, metadata
    
    integer(i4) :: n_elem_dofs = 0_i4
    integer(i4) :: mass_type = PH_ELEM_MASS_CONSIST
    real(wp), allocatable :: elem_mass(:,:)    ! Element mass matrix [n×n]
    real(wp), allocatable :: lumped_mass(:)    ! Lumped mass vector [n]
    
    ! Statistics
    real(wp) :: total_mass = 0.0_wp
    real(wp) :: max_diag_value = 0.0_wp
    real(wp) :: min_diag_value = 0.0_wp
    logical :: is_positive_definite = .FALSE.
    
    ! Metadata
    character(len=128) :: elem_type = ""
    integer(i4) :: n_nodes = 0_i4
    integer(i4) :: n_dof_per_node = 0_i4
    
  CONTAINS
    PROCEDURE, PUBLIC :: Init => State_Init
    PROCEDURE, PUBLIC :: Clear => State_Clear
    PROCEDURE, PUBLIC :: Print => State_Print
  END TYPE PH_Elem_Mass_State
  
CONTAINS
  
  ! ===================================================================
  ! PH_Elem_Mass_Algo Procedures
  ! ===================================================================
  
  SUBROUTINE Algo_Init(this, density, mass_formulation, &
                                     n_gp, gp_weights, gp_coords, status)
    !! Initialize mass computation parameters
    CLASS(PH_Elem_Mass_Algo), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: density
    INTEGER(i4), INTENT(IN), OPTIONAL :: mass_formulation
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_gp
    REAL(wp), INTENT(IN), OPTIONAL :: gp_weights(:)
    REAL(wp), INTENT(IN), OPTIONAL :: gp_coords(:,:)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    CALL init_error_status(status)
    
    this%density = density
    this%mass_formulation = PH_ELEM_MASS_CONSIST
    this%incl_rot_inertia = .FALSE.
    this%mass_scaling = 1.0_wp
    
    IF (present(mass_formulation)) THEN
      this%mass_formulation = mass_formulation
    END IF
    
    IF (present(n_gp) .AND. present(gp_weights) .AND. present(gp_coords)) THEN
      this%n_gauss_points = n_gp
      IF (ALLOCATED(this%gauss_weights)) DEALLOCATE(this%gauss_weights)
      IF (ALLOCATED(this%gauss_coords)) DEALLOCATE(this%gauss_coords)
      ALLOCATE(this%gauss_weights(n_gp))
      ALLOCATE(this%gauss_coords(n_gp, 3))
      this%gauss_weights = gp_weights(1:n_gp)
      this%gauss_coords = gp_coords(1:n_gp, 1:3)
    END IF
    
    IF (present(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Algo_Init

  SUBROUTINE Algo_Valid(this, status)
    !! Validate mass computation parameters
    CLASS(PH_Elem_Mass_Algo), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (this%density <= 0.0_wp) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "Algo_Valid: Invalid density (must be > 0)"
      RETURN
    END IF
    
    IF (this%mass_formulation < 1 .OR. this%mass_formulation > 5) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "Algo_Valid: Invalid mass formulation type"
      RETURN
    END IF
    
    IF (this%mass_scaling <= 0.0_wp) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "Algo_Valid: Invalid mass scaling factor"
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Algo_Valid
  
  ! ===================================================================
  ! PH_Elem_Mass_State Procedures
  ! ===================================================================
  
  SUBROUTINE State_Init(this, n_dofs, mass_type, status)
    !! Initialize mass result container
    CLASS(PH_Elem_Mass_State), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: n_dofs
    INTEGER(i4), INTENT(IN), OPTIONAL :: mass_type
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    CALL init_error_status(status)
    
    this%n_elem_dofs = n_dofs
    this%dyn%mass_type = PH_ELEM_MASS_CONSIST
    IF (present(mass_type)) this%dyn%mass_type = mass_type
    
    IF (ALLOCATED(this%elem_mass)) DEALLOCATE(this%elem_mass)
    IF (ALLOCATED(this%lumped_mass)) DEALLOCATE(this%lumped_mass)
    
    ALLOCATE(this%elem_mass(n_dofs, n_dofs))
    this%elem_mass = 0.0_wp
    
    IF (present(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE State_Init

  SUBROUTINE State_Clear(this)
    !! Clear mass result data
    CLASS(PH_Elem_Mass_State), INTENT(INOUT) :: this
    
    IF (ALLOCATED(this%elem_mass)) DEALLOCATE(this%elem_mass)
    IF (ALLOCATED(this%lumped_mass)) DEALLOCATE(this%lumped_mass)
    
    this%n_elem_dofs = 0_i4
    this%total_mass = 0.0_wp
    this%max_diag_value = 0.0_wp
    this%min_diag_value = 0.0_wp
    this%is_positive_definite = .FALSE.
  END SUBROUTINE State_Clear

  SUBROUTINE State_Print(this, status)
    !! Print mass matrix summary
    CLASS(PH_Elem_Mass_State), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    CALL init_error_status(status)
    
    PRINT *, "=== Mass Matrix Result ==="
    PRINT *, "  Element Type:", this%elem_type
    PRINT *, "  DOFs:", this%n_elem_dofs
    PRINT *, "  Nodes:", this%pop%n_nodes
    PRINT *, "  Mass Type:", this%dyn%mass_type
    PRINT *, "  Total Mass:", this%total_mass
    PRINT *, "  Max Diag:", this%max_diag_value
    PRINT *, "  Min Diag:", this%min_diag_value
    PRINT *, "  Positive Definite:", this%is_positive_definite
    
    IF (present(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE State_Print
  
  ! ===================================================================
  ! Physical Computation: Consistent Mass Matrix
  ! ===================================================================
  
  SUBROUTINE PH_Elem_Mass_Consistent(coords, params, result, status)
    !! Compute consistent mass matrix using variational formulation
    !! m_ij = ∫_V ρ N_i^T N_j dV = Σ_k ρ N_i(ξ_k)^T N_j(ξ_k) det(J_k) w_k
    !!
    !! ARCHITECTURE: L4_PH physical computation
    !! INPUT: coords (nodal coordinates), params (density, integration)
    !! OUTPUT: result%elem_mass (consistent mass matrix)
    !! THEORY: Bathe §9.3, Hughes §12.3
    
    REAL(wp), INTENT(IN) :: coords(:,:)       ! Nodal coordinates [3×n_nodes]
    TYPE(PH_Elem_Mass_Algo), INTENT(IN) :: params
    TYPE(PH_Elem_Mass_State), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, j, k, m
    INTEGER(i4) :: n_nodes, n_dof_per_node, n_dofs
    INTEGER(i4) :: n_gp
    REAL(wp) :: rho, det_J, weight
    REAL(wp), ALLOCATABLE :: shape_funcs(:)
    TYPE(ErrorStatusType) :: local_status
    TYPE(PH_Elem_ShapeFunc_Ctx) :: sf_result
    
    CALL init_error_status(local_status)
    IF (present(status)) CALL init_error_status(status)
    
    ! Validate input
    n_nodes = SIZE(coords, 2)
    IF (n_nodes == 0) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = "PH_Elem_Mass_Consistent: Empty node set"
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    n_dof_per_node = 3  ! Default structural DOFs (U1, U2, U3)
    n_dofs = n_nodes * n_dof_per_node
    
    ! Initialize result
    CALL result%Init(n_dofs, PH_ELEM_MASS_CONSIST, local_status)
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    ! Get material density
    rho = params%density * params%mass_scaling
    
    ! Get Gauss points
    IF (.NOT. ALLOCATED(params%gauss_weights)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = "PH_Elem_Mass_Consistent: Gauss points not provided"
      IF (present(status)) status = local_status
      RETURN
    END IF
    n_gp = params%n_gauss_points
    
    ! Allocate shape function buffer
    ALLOCATE(shape_funcs(n_nodes))
    
    ! === Numerical Integration Loop ===
    DO k = 1, n_gp
      weight = params%gauss_weights(k)
      
      ! Compute shape functions at Gauss point k
      CALL UF_GetShapeFunctions(coords, params%gauss_coords(k, :), &
                                shape_funcs, sf_result, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        IF (present(status)) status = local_status
        RETURN
      END IF
      
      ! Compute Jacobian determinant
      det_J = sf_result%itr%det_J
      IF (det_J <= 0.0_wp) THEN
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = "PH_Elem_Mass_Consistent: Invalid Jacobian"
        IF (present(status)) status = local_status
        RETURN
      END IF
      
      ! Assemble mass matrix: m_ij += ρ N_i N_j det(J) w_k
      DO i = 1, n_nodes
        DO j = 1, n_nodes
          REAL(wp) :: mass_contrib
          mass_contrib = rho * shape_funcs(i) * shape_funcs(j) * det_J * weight
          
          ! Translate to global DOF indices
          DO m = 1, n_dof_per_node
            INTEGER(i4) :: dof_i, dof_j
            dof_i = (i - 1) * n_dof_per_node + m
            dof_j = (j - 1) * n_dof_per_node + m
            result%elem_mass(dof_i, dof_j) = &
              result%elem_mass(dof_i, dof_j) + mass_contrib
          END DO
        END DO
      END DO
    END DO
    
    ! Compute statistics
    result%total_mass = 0.0_wp
    result%max_diag_value = 0.0_wp
    result%min_diag_value = HUGE(1.0_wp)
    
    DO i = 1, n_dofs
      result%total_mass = result%total_mass + result%elem_mass(i, i)
      IF (result%elem_mass(i, i) > result%max_diag_value) THEN
        result%max_diag_value = result%elem_mass(i, i)
      END IF
      IF (result%elem_mass(i, i) < result%min_diag_value) THEN
        result%min_diag_value = result%elem_mass(i, i)
      END IF
    END DO
    
    result%is_positive_definite = (result%min_diag_value > 0.0_wp)
    result%pop%n_nodes = n_nodes
    result%n_dof_per_node = n_dof_per_node
    
    DEALLOCATE(shape_funcs)
    
    IF (present(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_Mass_Consistent
  
  ! ===================================================================
  ! Physical Computation: Lumped Mass Matrix
  ! ===================================================================
  
  SUBROUTINE PH_Elem_Mass_Lumped(coords, params, result, status)
    !! Compute lumped mass matrix using various methods
    !! Methods: row-sum, diagonal, HRZ (Hinton-Rock-Zienkiewicz)
    !!
    !! ARCHITECTURE: L4_PH physical computation
    !! INPUT: coords, params (lump_method, density)
    !! OUTPUT: result%lumped_mass (diagonal mass vector)
    !! THEORY: Row-sum: m_i = Σ_j m_ij; HRZ: m_i = M_ii × scale
    
    REAL(wp), INTENT(IN) :: coords(:,:)
    TYPE(PH_Elem_Mass_Algo), INTENT(IN) :: params
    TYPE(PH_Elem_Mass_State), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, n_dofs
    REAL(wp) :: total_mass, total_diag, hrz_scale
    TYPE(ErrorStatusType) :: local_status
    
    CALL init_error_status(local_status)
    
    ! First compute consistent mass for lumping
    CALL PH_Elem_Mass_Consistent(coords, params, result, local_status)
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    n_dofs = result%n_elem_dofs
    
    ! Allocate lumped mass if not already
    IF (.NOT. ALLOCATED(result%lumped_mass)) THEN
      ALLOCATE(result%lumped_mass(n_dofs))
    END IF
    result%lumped_mass = 0.0_wp
    
    SELECT CASE(params%mass_formulation)
    
    CASE(PH_ELEM_MASS_LUMP_ROWSUM)
      ! Row-sum lumping: m_i = Σ_j m_ij
      DO i = 1, n_dofs
        REAL(wp) :: row_sum
        row_sum = 0.0_wp
        DO j = 1, n_dofs
          row_sum = row_sum + result%elem_mass(i, j)
        END DO
        result%lumped_mass(i) = row_sum
      END DO
      
    CASE(PH_ELEM_MASS_LUMP_DIAG)
      ! Diagonal lumping: m_i = M_ii
      DO i = 1, n_dofs
        result%lumped_mass(i) = result%elem_mass(i, i)
      END DO
      
    CASE(PH_ELEM_MASS_LUMP_HRZ)
      ! HRZ lumping: preserve total mass by scaling diagonal
      ! m_i = M_ii × (Σ_kl M_kl / Σ_k M_kk)
      total_mass = 0.0_wp
      total_diag = 0.0_wp
      
      DO i = 1, n_dofs
        DO j = 1, n_dofs
          total_mass = total_mass + result%elem_mass(i, j)
        END DO
        total_diag = total_diag + result%elem_mass(i, i)
      END DO
      
      IF (total_diag > 1.0e-30_wp) THEN
        hrz_scale = total_mass / total_diag
        DO i = 1, n_dofs
          result%lumped_mass(i) = result%elem_mass(i, i) * hrz_scale
        END DO
      ELSE
        ! Fallback to row-sum if HRZ fails
        DO i = 1, n_dofs
          REAL(wp) :: row_sum
          row_sum = 0.0_wp
          DO j = 1, n_dofs
            row_sum = row_sum + result%elem_mass(i, j)
          END DO
          result%lumped_mass(i) = row_sum
        END DO
      END IF
      
    END SELECT
    
    result%dyn%mass_type = params%mass_formulation
    
    IF (present(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_Mass_Lumped
  
  ! ===================================================================
  ! Physical Computation: Hybrid Mass Matrix
  ! ===================================================================
  
  SUBROUTINE PH_Elem_Mass_Hybrid(coords, params, result, status)
    !! Compute hybrid mass matrix (consistent + rotational inertia)
    !! For shells/beams: includes translational + rotational DOF inertia
    !!
    !! ARCHITECTURE: L4_PH physical computation
    !! INPUT: coords, params (incl_rot_inertia)
    !! OUTPUT: result%elem_mass (hybrid mass with rot. DOF)
    !! THEORY: Shell theory, Timoshenko beam theory
    
    REAL(wp), INTENT(IN) :: coords(:,:)
    TYPE(PH_Elem_Mass_Algo), INTENT(IN) :: params
    TYPE(PH_Elem_Mass_State), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    
    CALL init_error_status(local_status)
    
    ! Compute consistent mass first
    CALL PH_Elem_Mass_Consistent(coords, params, result, local_status)
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    ! Add rotational inertia if requested
    IF (params%incl_rot_inertia) THEN
      ! TODO: Implement rotational inertia terms for shell/beam elements
      ! This requires element-specific formulations (thickness, area moment)
      local_status%status_code = IF_STATUS_WARN
      local_status%message = "PH_Elem_Mass_Hybrid: Rotational inertia not yet implemented"
    END IF
    
    result%dyn%mass_type = PH_ELEM_MASS_HYBRID
    
    IF (present(status)) status = local_status
  END SUBROUTINE PH_Elem_Mass_Hybrid
  
END MODULE PH_Elem_Mass2