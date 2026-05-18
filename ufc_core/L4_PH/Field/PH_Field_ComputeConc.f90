!===============================================================================
! MODULE: PH_Field_ComputeConc
! LAYER:  L4_PH
! DOMAIN: Field
! ROLE:   Eval — concentration field computation (diffusion-reaction)
! BRIEF:  Explicit/implicit concentration solvers, diffusion Laplacian,
!         reaction matrix, source assembly, and Dirichlet BC application.
!===============================================================================
!>>> UFC_PH_TAG | layer:L4_PH | domain:Field | role:Compute | FuncSet:Concentration
!>>> UFC_PH_CONTRACT | Field/CONTRACT.md

MODULE PH_Field_ComputeConc
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Field_Def, ONLY: PH_Concentration_Desc, PH_Concentration_Algo, &
                            PH_Concentration_In, PH_Concentration_Out

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Field_Compute_Concentration_Explicit
  PUBLIC :: PH_Field_Compute_Concentration_Implicit
  
  PUBLIC :: PH_Field_Assemble_DiffusionLaplacian
  PUBLIC :: PH_Field_Assemble_ReactionMatrix
  PUBLIC :: PH_Field_Assemble_ConcentrationSource
  PUBLIC :: PH_Field_Apply_ConcBC_Dirichlet

CONTAINS

  ! ==========================================================================
  ! CONCENTRATION FIELD - EXPLICIT SOLVER
  ! ==========================================================================
  !> @brief Explicit concentration solver: c^{n+1} = c^n + dt·M⁻¹·(F - (K+R)·c^n)
  SUBROUTINE PH_Field_Compute_Concentration_Explicit(desc, algo, in, out, status)
    TYPE(PH_Concentration_Desc), INTENT(IN) :: desc
    TYPE(PH_Concentration_Algo), INTENT(IN) :: algo
    TYPE(PH_Concentration_In), INTENT(IN) :: in
    TYPE(PH_Concentration_Out), INTENT(INOUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(in%concentration)) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Compute_Concentration_Explicit: concentration pointer not associated'
      RETURN
    END IF

    n = SIZE(in%concentration, 2)

    IF (ALLOCATED(out%concentration)) DEALLOCATE(out%concentration)
    IF (ALLOCATED(out%flux)) DEALLOCATE(out%flux)
    ALLOCATE(out%concentration(1, n))
    ALLOCATE(out%flux(3, n))

    ! ============================================================
    ! TODO: Complete explicit solver
    ! ============================================================
    ! Step 1: Assemble diffusion Laplacian K
    !   K_ij = ∫Ω D·∇Nᵢ·∇Nⱼ dΩ
    ! CALL PH_Field_Assemble_DiffusionLaplacian(...)
    
    ! Step 2: Assemble mass matrix M
    !   M_ij = ∫Ω Nᵢ·Nⱼ dΩ
    ! CALL PH_Field_Assemble_ConcentrationMass(...)
    
    ! Step 3: Assemble reaction matrix R (if has_reaction)
    !   R_ij = ∫Ω R·Nᵢ·Nⱼ dΩ
    ! IF (desc%has_reaction) CALL PH_Field_Assemble_ReactionMatrix(...)
    
    ! Step 4: Assemble source F
    !   F_i = ∫Ω Nᵢ·S dΩ
    ! CALL PH_Field_Assemble_ConcentrationSource(...)
    
    ! Step 5: Explicit update: c^{n+1} = c^n + dt·M⁻¹·(F - (K+R)·c^n)
    
    out%concentration = in%concentration
    out%flux = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Compute_Concentration_Explicit

  ! ==========================================================================
  ! CONCENTRATION FIELD - IMPLICIT SOLVER
  ! ==========================================================================
  !> @brief Implicit concentration solver: (M + dt·(K+R))·c^{n+1} = M·c^n + dt·F
  SUBROUTINE PH_Field_Compute_Concentration_Implicit(desc, algo, in, out, status)
    TYPE(PH_Concentration_Desc), INTENT(IN) :: desc
    TYPE(PH_Concentration_Algo), INTENT(IN) :: algo
    TYPE(PH_Concentration_In), INTENT(IN) :: in
    TYPE(PH_Concentration_Out), INTENT(INOUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(in%concentration)) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Compute_Concentration_Implicit: concentration pointer not associated'
      RETURN
    END IF

    n = SIZE(in%concentration, 2)

    IF (ALLOCATED(out%concentration)) DEALLOCATE(out%concentration)
    ALLOCATE(out%concentration(1, n))

    ! ============================================================
    ! TODO: Complete implicit solver
    ! ============================================================
    ! Step 1-4: Assemble K, M, R, F
    ! Step 5: Apply BC
    ! Step 6: Solve: (M + dt·(K+R))·c^{n+1} = M·c^n + dt·F
    
    out%concentration = in%concentration

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Compute_Concentration_Implicit

  ! ==========================================================================
  ! LAPLACIAN ASSEMBLY - Diffusion matrix
  ! ==========================================================================
  !> @brief Assemble diffusion Laplacian (Fick's law)
  !! K_ij = ∫Ω D·∇Nᵢ·∇Nⱼ dΩ
  SUBROUTINE PH_Field_Assemble_DiffusionLaplacian(coords, conn, diffusivity, &
                                                    K_global, status)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    REAL(wp), INTENT(IN) :: diffusivity    ! D [m²/s]
    REAL(wp), INTENT(OUT) :: K_global(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! ============================================================
    ! TODO: Complete assembly
    ! ============================================================
    ! K_e(i,j) = ∑_gp w_gp · D · ∇Nᵢ·∇Nⱼ · det(J)
    
    K_global = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Assemble_DiffusionLaplacian

  ! ==========================================================================
  ! REACTION ASSEMBLY - First-order reaction
  ! ==========================================================================
  !> @brief Assemble reaction matrix
  !! R_ij = ∫Ω R·Nᵢ·Nⱼ dΩ
  SUBROUTINE PH_Field_Assemble_ReactionMatrix(coords, conn, reaction_rate, &
                                               R_global, status)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    REAL(wp), INTENT(IN) :: reaction_rate   ! R [1/s]
    REAL(wp), INTENT(OUT) :: R_global(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! ============================================================
    ! TODO: Complete assembly
    ! ============================================================
    ! R_e(i,j) = ∑_gp w_gp · R · Nᵢ·Nⱼ · det(J)
    
    R_global = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Assemble_ReactionMatrix

  ! ==========================================================================
  ! SOURCE ASSEMBLY - Concentration source/sink
  ! ==========================================================================
  !> @brief Assemble concentration source vector
  !! F_i = ∫Ω Nᵢ·S dΩ
  SUBROUTINE PH_Field_Assemble_ConcentrationSource(coords, conn, &
                                                     source_conc, F_global, status)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    REAL(wp), INTENT(IN) :: source_conc    ! S [mol/m³]
    REAL(wp), INTENT(OUT) :: F_global(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! ============================================================
    ! TODO: Complete assembly
    ! ============================================================
    ! F_e(i) = ∑_gp w_gp · Nᵢ · S · det(J)
    
    F_global = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Assemble_ConcentrationSource

  ! ==========================================================================
  ! BOUNDARY CONDITIONS
  ! ==========================================================================
  !> @brief Apply Dirichlet BC: c = c₀
  SUBROUTINE PH_Field_Apply_ConcBC_Dirichlet(K_global, F_global, &
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
        status%error_message = 'PH_Field_Apply_ConcBC_Dirichlet: node index out of range'
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
  END SUBROUTINE PH_Field_Apply_ConcBC_Dirichlet

END MODULE PH_Field_ComputeConc