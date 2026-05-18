!===============================================================================
! MODULE: PH_Field_ComputePore
! LAYER:  L4_PH
! DOMAIN: Field
! ROLE:   Eval — pore pressure field computation (Darcy flow, consolidation)
! BRIEF:  Explicit/implicit pore pressure solvers, permeability Laplacian,
!         storativity mass, fluid source, and Dirichlet/Neumann BC application.
!===============================================================================
!>>> UFC_PH_TAG | layer:L4_PH | domain:Field | role:Compute | FuncSet:PorePressure
!>>> UFC_PH_CONTRACT | Field/CONTRACT.md

MODULE PH_Field_ComputePore
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Field_Def, ONLY: PH_PorePressure_Desc, PH_PorePressure_Algo, &
                            PH_PorePressure_In, PH_PorePressure_Out

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Field_Compute_PorePressure_Explicit
  PUBLIC :: PH_Field_Compute_PorePressure_Implicit
  
  PUBLIC :: PH_Field_Assemble_PermeabilityLaplacian
  PUBLIC :: PH_Field_Assemble_StorativityMass
  PUBLIC :: PH_Field_Assemble_FluidSource
  PUBLIC :: PH_Field_Apply_PoreBC_Dirichlet
  PUBLIC :: PH_Field_Apply_PoreBC_Neumann

CONTAINS

  ! ==========================================================================
  ! PORE PRESSURE FIELD - EXPLICIT SOLVER
  ! ==========================================================================
  !> @brief Explicit pore pressure solver: p^{n+1} = p^n + dt·M⁻¹·(F - K·p^n)
  SUBROUTINE PH_Field_Compute_PorePressure_Explicit(desc, algo, in, out, status)
    TYPE(PH_PorePressure_Desc), INTENT(IN) :: desc
    TYPE(PH_PorePressure_Algo), INTENT(IN) :: algo
    TYPE(PH_PorePressure_In), INTENT(IN) :: in
    TYPE(PH_PorePressure_Out), INTENT(INOUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(in%pressure)) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Compute_PorePressure_Explicit: pressure pointer not associated'
      RETURN
    END IF

    n = SIZE(in%pressure, 2)

    IF (ALLOCATED(out%pressure)) DEALLOCATE(out%pressure)
    IF (ALLOCATED(out%velocity)) DEALLOCATE(out%velocity)
    ALLOCATE(out%pressure(1, n))
    ALLOCATE(out%velocity(3, n))

    ! ============================================================
    ! TODO: Complete explicit solver
    ! ============================================================
    ! Step 1: Assemble permeability Laplacian K
    !   K_ij = ∫Ω (k/μ)·∇Nᵢ·∇Nⱼ dΩ
    ! CALL PH_Field_Assemble_PermeabilityLaplacian(...)
    
    ! Step 2: Assemble storativity mass M
    !   M_ij = ∫Ω s·Nᵢ·Nⱼ dΩ
    ! CALL PH_Field_Assemble_StorativityMass(...)
    
    ! Step 3: Assemble source F
    !   F_i = ∫Ω Nᵢ·q/ρ dΩ
    ! CALL PH_Field_Assemble_FluidSource(...)
    
    ! Step 4: Explicit update: p^{n+1} = p^n + dt·M⁻¹·(F - K·p^n)
    
    out%pressure = in%pressure
    out%velocity = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Compute_PorePressure_Explicit

  ! ==========================================================================
  ! PORE PRESSURE FIELD - IMPLICIT SOLVER
  ! ==========================================================================
  !> @brief Implicit pore pressure solver: (M + dt·K)·p^{n+1} = M·p^n + dt·F
  SUBROUTINE PH_Field_Compute_PorePressure_Implicit(desc, algo, in, out, status)
    TYPE(PH_PorePressure_Desc), INTENT(IN) :: desc
    TYPE(PH_PorePressure_Algo), INTENT(IN) :: algo
    TYPE(PH_PorePressure_In), INTENT(IN) :: in
    TYPE(PH_PorePressure_Out), INTENT(INOUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(in%pressure)) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Compute_PorePressure_Implicit: pressure pointer not associated'
      RETURN
    END IF

    n = SIZE(in%pressure, 2)

    IF (ALLOCATED(out%pressure)) DEALLOCATE(out%pressure)
    ALLOCATE(out%pressure(1, n))

    ! ============================================================
    ! TODO: Complete implicit solver
    ! ============================================================
    ! Step 1-3: Assemble K, M, F
    ! Step 4: Apply BC
    ! Step 5: Solve linear system: (M + dt·K)·p^{n+1} = M·p^n + dt·F
    
    out%pressure = in%pressure

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Compute_PorePressure_Implicit

  ! ==========================================================================
  ! LAPLACIAN ASSEMBLY - Permeability matrix
  ! ==========================================================================
  !> @brief Assemble permeability Laplacian (Darcy flow)
  !! K_ij = ∫Ω (k/μ)·∇Nᵢ·∇Nⱼ dΩ
  SUBROUTINE PH_Field_Assemble_PermeabilityLaplacian(coords, conn, &
                                                      permeability, K_global, status)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    REAL(wp), INTENT(IN) :: permeability   ! k [m/s]
    REAL(wp), INTENT(OUT) :: K_global(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! ============================================================
    ! TODO: Complete assembly (similar to thermal Laplacian)
    ! ============================================================
    ! K_e(i,j) = ∑_gp w_gp · (k/μ) · ∇Nᵢ·∇Nⱼ · det(J)
    
    K_global = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Assemble_PermeabilityLaplacian

  ! ==========================================================================
  ! MASS ASSEMBLY - Storativity matrix
  ! ==========================================================================
  !> @brief Assemble storativity mass matrix
  !! M_ij = ∫Ω s·Nᵢ·Nⱼ dΩ
  SUBROUTINE PH_Field_Assemble_StorativityMass(coords, conn, storativity, &
                                                M_global, status)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    REAL(wp), INTENT(IN) :: storativity    ! s [1/m]
    REAL(wp), INTENT(OUT) :: M_global(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! ============================================================
    ! TODO: Complete assembly
    ! ============================================================
    ! M_e(i,j) = ∑_gp w_gp · s · Nᵢ·Nⱼ · det(J)
    
    M_global = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Assemble_StorativityMass

  ! ==========================================================================
  ! SOURCE ASSEMBLY - Fluid source/sink
  ! ==========================================================================
  !> @brief Assemble fluid source vector
  !! F_i = ∫Ω Nᵢ·q/ρ dΩ
  SUBROUTINE PH_Field_Assemble_FluidSource(coords, conn, source_rate, &
                                            F_global, status)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    REAL(wp), INTENT(IN) :: source_rate    ! q [kg/(m³·s)]
    REAL(wp), INTENT(OUT) :: F_global(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! ============================================================
    ! TODO: Complete assembly
    ! ============================================================
    ! F_e(i) = ∑_gp w_gp · Nᵢ · (q/ρ) · det(J)
    
    F_global = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Assemble_FluidSource

  ! ==========================================================================
  ! BOUNDARY CONDITIONS
  ! ==========================================================================
  !> @brief Apply Dirichlet BC: p = p₀
  SUBROUTINE PH_Field_Apply_PoreBC_Dirichlet(K_global, F_global, &
                                               bc_nodes, bc_values, status)
    REAL(wp), INTENT(INOUT) :: K_global(:,:)
    REAL(wp), INTENT(INOUT) :: F_global(:)
    INTEGER(i4), INTENT(IN) :: bc_nodes(:)
    REAL(wp), INTENT(IN) :: bc_values(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_bc, i, node_idx, j, nnode

    CALL init_error_status(status)

    n_bc = SIZE(bc_nodes)
    nnode = SIZE(F_global)

    DO i = 1, n_bc
      node_idx = bc_nodes(i)
      
      IF (node_idx < 1 .OR. node_idx > nnode) THEN
        status%status_code = IF_STATUS_INVALID
        status%error_message = 'PH_Field_Apply_PoreBC_Dirichlet: node index out of range'
        RETURN
      END IF

      DO j = 1, nnode
        IF (j /= node_idx) THEN
          F_global(j) = F_global(j) - K_global(j, node_idx) * bc_values(i)
          K_global(j, node_idx) = ZERO
        END IF
      END DO
      K_global(node_idx, node_idx) = ONE
      F_global(node_idx) = bc_values(i)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Apply_PoreBC_Dirichlet

  !> @brief Apply Neumann BC: prescribed flux
  SUBROUTINE PH_Field_Apply_PoreBC_Neumann(F_global, bc_faces, &
                                            flux_values, status)
    REAL(wp), INTENT(INOUT) :: F_global(:)
    INTEGER(i4), INTENT(IN) :: bc_faces(:)
    REAL(wp), INTENT(IN) :: flux_values(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! TODO: Complete Neumann BC assembly
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Apply_PoreBC_Neumann

END MODULE PH_Field_ComputePore