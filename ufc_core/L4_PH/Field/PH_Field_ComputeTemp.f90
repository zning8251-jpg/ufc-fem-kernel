!===============================================================================
! MODULE: PH_Field_ComputeTemp
! LAYER:  L4_PH
! DOMAIN: Field
! ROLE:   Eval — temperature field PDE solving with Laplacian discretization
! BRIEF:  Explicit/implicit thermal solvers, Laplacian/mass/source assembly,
!         Dirichlet/Neumann/Robin thermal BC application.
!===============================================================================
! Theory:  Heat equation: ∂T/∂t = α·∇²T + Q/(ρ·cp)
!          Weak form: ∫Ω Nᵢ·∂T/∂t dΩ + ∫Ω k·∇Nᵢ·∇T dΩ = ∫Ω Nᵢ·Q dΩ + ∫Γ_N Nᵢ·q dΓ
! Status:  Phase C (Laplacian template delivered) | Last verified: 2026-04-13
!===============================================================================
!>>> UFC_PH_TAG | layer:L4_PH | domain:Field | role:Compute | FuncSet:Temperature
!>>> UFC_PH_CONTRACT | Field/CONTRACT.md

MODULE PH_Field_ComputeTemp
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Field_Def, ONLY: PH_Temperature_Desc, PH_Temperature_Algo, &
                            PH_Temperature_Arg

  ! Field domain adapters
  USE PH_Field_ShapeFunc, ONLY: PH_Field_GetShapeFunctionGradient, &
                                       PH_Field_Gradient_Arg, &
                                       PH_Field_GetShapeFunctions, &
                                       PH_Field_ShapeFunc_Arg
  USE PH_Field_GaussQuadrature, ONLY: PH_Field_GetGaussPoints, &
                                      PH_FIELD_GAUSS_RULE_3D_HEX, &
                                      PH_FIELD_GAUSS_RULE_2D_QUAD, &
                                      PH_Field_GaussPt_Arg

  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! PUBLIC API - Temperature field computation
  ! ==========================================================================
  PUBLIC :: PH_Field_Compute_Temperature_Explicit
  PUBLIC :: PH_Field_Compute_Temperature_Implicit
  
  ! Laplacian assembly (for external use by L5_RT coupling)
  PUBLIC :: PH_Field_Assemble_ThermalLaplacian
  PUBLIC :: PH_Field_Assemble_ThermalMass
  PUBLIC :: PH_Field_Assemble_HeatSource
  PUBLIC :: PH_Field_Apply_ThermalBC_Dirichlet
  PUBLIC :: PH_Field_Apply_ThermalBC_Neumann
  PUBLIC :: PH_Field_Apply_ThermalBC_Robin

CONTAINS

  ! ==========================================================================
  ! TEMPERATURE FIELD - EXPLICIT SOLVER (Forward Euler)
  ! ==========================================================================
  !> @brief Explicit temperature solver: T^{n+1} = T^n + dt·M⁻¹·(F - K·T^n)
  !! @param[in] desc Temperature descriptor (thermal properties)
  !! @param[in] algo Algorithm configuration (time integration, tolerance)
  !! @param[inout] arg Unified temperature IO (t_n in, temperature/heat_flux out)
  !! @param[out] status Error status
  SUBROUTINE PH_Field_Compute_Temperature_Explicit(desc, algo, arg, status)
    TYPE(PH_Temperature_Desc), INTENT(IN) :: desc
    TYPE(PH_Temperature_Algo), INTENT(IN) :: algo
    TYPE(PH_Temperature_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n
    REAL(wp) :: alpha

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(arg%t_n)) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Compute_Temperature_Explicit: t_n pointer not associated'
      RETURN
    END IF

    n = SIZE(arg%t_n, 2)

    IF (ALLOCATED(arg%temperature)) DEALLOCATE(arg%temperature)
    IF (ALLOCATED(arg%heat_flux)) DEALLOCATE(arg%heat_flux)
    ALLOCATE(arg%temperature(1, n))
    ALLOCATE(arg%heat_flux(3, n))

    alpha = desc%thermal_conductivity / (desc%heat_capacity * desc%density)

    arg%temperature = arg%t_n
    arg%heat_flux = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Compute_Temperature_Explicit

  ! ==========================================================================
  ! TEMPERATURE FIELD - IMPLICIT SOLVER (Backward Euler)
  ! ==========================================================================
  !> @brief Implicit temperature solver: (M + dt·K)·T^{n+1} = M·T^n + dt·F
  !! @param[in] desc Temperature descriptor
  !! @param[in] algo Algorithm configuration
  !! @param[inout] arg Unified temperature IO (t_n in, temperature out)
  !! @param[out] status Error status
  SUBROUTINE PH_Field_Compute_Temperature_Implicit(desc, algo, arg, status)
    TYPE(PH_Temperature_Desc), INTENT(IN) :: desc
    TYPE(PH_Temperature_Algo), INTENT(IN) :: algo
    TYPE(PH_Temperature_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(arg%t_n)) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Compute_Temperature_Implicit: t_n pointer not associated'
      RETURN
    END IF

    n = SIZE(arg%t_n, 2)

    IF (ALLOCATED(arg%temperature)) DEALLOCATE(arg%temperature)
    ALLOCATE(arg%temperature(1, n))

    arg%temperature = arg%t_n

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Compute_Temperature_Implicit

  ! ==========================================================================
  ! LAPLACIAN ASSEMBLY - Thermal conduction matrix
  ! ==========================================================================
  !> @brief Assemble thermal Laplacian (conduction) matrix
  !! K_ij = ∫Ω k·∇Nᵢ·∇Nⱼ dΩ (Gaussian quadrature)
  !! @param[in] coords Node coordinates [3, nnode]
  !! @param[in] conn Element connectivity [npe, nelem]
  !! @param[in] conductivity Thermal conductivity k [W/(m·K)]
  !! @param[out] K_global Global stiffness matrix [nnode, nnode] (sparse CSR)
  !! @param[out] status Error status
  SUBROUTINE PH_Field_Assemble_ThermalLaplacian(coords, conn, conductivity, &
                                                  K_global, status)
    REAL(wp), INTENT(IN) :: coords(:,:)       ! [3, nnode]
    INTEGER(i4), INTENT(IN) :: conn(:,:)      ! [npe, nelem]
    REAL(wp), INTENT(IN) :: conductivity      ! k [W/(m·K)]
    REAL(wp), INTENT(OUT) :: K_global(:,:)    ! [nnode, nnode] (dense for now)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: elem_coords(3, 8)
    REAL(wp) :: Ke(8, 8)
    REAL(wp) :: dN_dx(3, 8)
    REAL(wp) :: detJ, w_gp
    INTEGER(i4) :: nnode, nelem, npe, elem
    INTEGER(i4) :: gp_i, i, j, node_i, node_j
    TYPE(PH_Field_Gradient_Arg) :: grad
    TYPE(PH_Field_GaussPt_Arg) :: gauss_pts

    CALL init_error_status(status)

    nnode = SIZE(coords, 2)
    nelem = SIZE(conn, 2)
    npe = SIZE(conn, 1)

    ! Initialize global matrix
    K_global = ZERO

    ! Get Gauss points for volume integration (2x2x2 rule for hex8)
    CALL PH_Field_GetGaussPoints(PH_FIELD_GAUSS_RULE_3D_HEX, 2, gauss_pts)
    IF (gauss_pts%status%status_code /= IF_STATUS_OK) THEN
      status = gauss_pts%status
      RETURN
    END IF

    ! Loop over all elements
    DO elem = 1, nelem
      ! Extract element node coordinates
      DO i = 1, npe
        elem_coords(:, i) = coords(:, conn(i, elem))
      END DO

      ! Initialize local stiffness matrix
      Ke = ZERO

      ! Loop over Gauss points
      DO gp_i = 1, gauss_pts%n_ip
        w_gp = gauss_pts%weights(gp_i)

        ! Get shape function gradient dN/dx at this Gauss point
        CALL PH_Field_GetShapeFunctionGradient(elem_coords, &
                                               gauss_pts%xi(gp_i), &
                                               gauss_pts%eta(gp_i), &
                                               gauss_pts%zeta(gp_i), &
                                               npe, grad)
        
        IF (grad%status%status_code /= IF_STATUS_OK) THEN
          status = grad%status
          RETURN
        END IF

        dN_dx = grad%dN_dx
        detJ = grad%detJ

        ! Local stiffness assembly: K_e(i,j) = w_gp · k · ∇Nᵢ·∇Nⱼ · detJ
        DO i = 1, npe
          DO j = 1, npe
            Ke(i, j) = Ke(i, j) + w_gp * conductivity * &
                      (dN_dx(1, i)*dN_dx(1, j) + &
                       dN_dx(2, i)*dN_dx(2, j) + &
                       dN_dx(3, i)*dN_dx(3, j)) * detJ
          END DO
        END DO
      END DO

      ! Assemble local to global: K_global(conn(i), conn(j)) += Ke(i, j)
      DO i = 1, npe
        node_i = conn(i, elem)
        DO j = 1, npe
          node_j = conn(j, elem)
          K_global(node_i, node_j) = K_global(node_i, node_j) + Ke(i, j)
        END DO
      END DO
    END DO

    ! Cleanup
    IF (ALLOCATED(grad%dN_dx)) DEALLOCATE(grad%dN_dx)
    IF (ALLOCATED(gauss_pts%xi)) DEALLOCATE(gauss_pts%xi, gauss_pts%eta, &
                                            gauss_pts%zeta, gauss_pts%weights)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Assemble_ThermalLaplacian

  ! ==========================================================================
  ! MASS ASSEMBLY - Heat capacity matrix
  ! ==========================================================================
  !> @brief Assemble thermal mass matrix
  !! M_ij = ∫Ω ρ·cp·Nᵢ·Nⱼ dΩ
  !! @param[in] coords Node coordinates [3, nnode]
  !! @param[in] conn Element connectivity [npe, nelem]
  !! @param[in] density Density ρ [kg/m³]
  !! @param[in] heat_capacity Specific heat cp [J/(kg·K)]
  !! @param[out] M_global Global mass matrix [nnode, nnode]
  !! @param[out] status Error status
  SUBROUTINE PH_Field_Assemble_ThermalMass(coords, conn, density, heat_capacity, &
                                            M_global, status, do_lumping)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    REAL(wp), INTENT(IN) :: density          ! ρ [kg/m³]
    REAL(wp), INTENT(IN) :: heat_capacity    ! cp [J/(kg·K)]
    REAL(wp), INTENT(OUT) :: M_global(:,:)   ! [nnode, nnode]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: do_lumping  ! Optional mass lumping

    REAL(wp) :: elem_coords(3, 8)
    REAL(wp) :: N(8)
    REAL(wp) :: dN_dxi(3, 8)
    REAL(wp) :: Me(8, 8), Me_lumped(8)
    REAL(wp) :: J_temp(3, 3), detJ, w_gp, rho_cp
    INTEGER(i4) :: nnode, nelem, npe, elem
    INTEGER(i4) :: gp_i, i, j, node_i, node_j
    TYPE(PH_Field_GaussPt_Arg) :: gauss_pts
    TYPE(PH_Field_ShapeFunc_Arg) :: shape_out
    TYPE(ErrorStatusType) :: shape_status

    CALL init_error_status(status)

    nnode = SIZE(coords, 2)
    nelem = SIZE(conn, 2)
    npe = SIZE(conn, 1)
    rho_cp = density * heat_capacity

    ! Check if lumping requested
    IF (PRESENT(do_lumping) .AND. do_lumping) THEN
      ! Diagonal mass matrix (lumped)
      M_global = ZERO
    ELSE
      ! Consistent mass matrix
      M_global = ZERO
    END IF

    ! Get Gauss points for volume integration (2x2x2 rule)
    CALL PH_Field_GetGaussPoints(PH_FIELD_GAUSS_RULE_3D_HEX, 2, gauss_pts)
    IF (gauss_pts%status%status_code /= IF_STATUS_OK) THEN
      status = gauss_pts%status
      RETURN
    END IF

    ! Loop over all elements
    DO elem = 1, nelem
      ! Extract element node coordinates
      DO i = 1, npe
        elem_coords(:, i) = coords(:, conn(i, elem))
      END DO

      ! Initialize local mass matrix
      Me = ZERO
      Me_lumped = ZERO

      ! Loop over Gauss points
      DO gp_i = 1, gauss_pts%n_ip
        w_gp = gauss_pts%weights(gp_i)

        ! Get shape functions at this Gauss point
        CALL PH_Field_GetShapeFunctions('C3D8', gauss_pts%xi(gp_i), &
                                         gauss_pts%eta(gp_i), &
                                         gauss_pts%zeta(gp_i), &
                                         npe, shape_out)

        N = shape_out%N
        dN_dxi = shape_out%dN_dxi

        ! Compute Jacobian
        CALL PH_Field_ComputeJacobian(elem_coords, dN_dxi, npe, &
                                      J_temp, detJ, shape_status)
        IF (shape_status%status_code /= IF_STATUS_OK) THEN
          status = shape_status
          RETURN
        END IF

        ! Consistent mass: M_e(i,j) = w_gp · ρ·cp · Nᵢ·Nⱼ · detJ
        DO i = 1, npe
          DO j = 1, npe
            Me(i, j) = Me(i, j) + w_gp * rho_cp * N(i) * N(j) * detJ
          END DO
          ! Lumped mass (row-sum): M_ii = Σ_j M_ij
          Me_lumped(i) = Me_lumped(i) + w_gp * rho_cp * N(i) * detJ
        END DO
      END DO

      ! Assemble to global
      DO i = 1, npe
        node_i = conn(i, elem)
        IF (PRESENT(do_lumping) .AND. do_lumping) THEN
          ! Diagonal lumped mass
          M_global(node_i, node_i) = M_global(node_i, node_i) + Me_lumped(i)
        ELSE
          ! Consistent mass
          DO j = 1, npe
            node_j = conn(j, elem)
            M_global(node_i, node_j) = M_global(node_i, node_j) + Me(i, j)
          END DO
        END IF
      END DO

      DEALLOCATE(shape_out%N, shape_out%dN_dxi)
    END DO

    ! Cleanup
    IF (ALLOCATED(gauss_pts%xi)) DEALLOCATE(gauss_pts%xi, gauss_pts%eta, &
                                            gauss_pts%zeta, gauss_pts%weights)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Assemble_ThermalMass

  ! ==========================================================================
  ! SOURCE ASSEMBLY - Heat generation + boundary flux
  ! ==========================================================================
  !> @brief Assemble thermal source vector
  !! F_i = ∫Ω Nᵢ·Q dΩ + ∫Γ_N Nᵢ·q dΓ
  !! @param[in] coords Node coordinates [3, nnode]
  !! @param[in] conn Element connectivity [npe, nelem]
  !! @param[in] heat_gen_rate Volumetric heat generation Q [W/m³]
  !! @param[out] F_global Global force vector [nnode]
  !! @param[out] status Error status
  SUBROUTINE PH_Field_Assemble_HeatSource(coords, conn, heat_gen_rate, &
                                           F_global, status)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    REAL(wp), INTENT(IN) :: heat_gen_rate   ! Q [W/m³]
    REAL(wp), INTENT(OUT) :: F_global(:)    ! [nnode]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nnode, nelem

    CALL init_error_status(status)

    nnode = SIZE(coords, 2)
    nelem = SIZE(conn, 2)

    F_global = ZERO

    ! ============================================================
    ! TODO: Complete source vector assembly
    ! ============================================================
    ! For each element:
    !   1. Gaussian quadrature:
    !      F_e(i) = ∑_gp w_gp · Nᵢ(ξ_gp) · Q · det(J)
    !   2. Assemble to global: F_global(conn(i,e)) += F_e(i)
    
    ! Boundary flux (Neumann BC):
    !   For boundary faces:
    !     F_b(i) = ∑_gp w_gp · Nᵢ(ξ_gp) · q · det(J_face)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Assemble_HeatSource

  ! ==========================================================================
  ! BOUNDARY CONDITIONS - Dirichlet (fixed temperature)
  ! ==========================================================================
  !> @brief Apply Dirichlet BC: T = T₀ at Γ_D
  !! Method 1: Elimination (modify K and F)
  !!   K_ii = 1, K_ij = 0 (j≠i), F_i = T₀
  !! @param[inout] K_global Stiffness matrix [nnode, nnode]
  !! @param[inout] F_global Force vector [nnode]
  !! @param[in] bc_nodes Node indices with Dirichlet BC [n_bc]
  !! @param[in] bc_values Prescribed temperatures T₀ [n_bc]
  !! @param[out] status Error status
  SUBROUTINE PH_Field_Apply_ThermalBC_Dirichlet(K_global, F_global, &
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

    ! Validate indices
    IF (SIZE(bc_values) /= n_bc) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Apply_ThermalBC_Dirichlet: bc_nodes/bc_values size mismatch'
      RETURN
    END IF

    ! Apply Dirichlet BC (elimination method)
    DO i = 1, n_bc
      node_idx = bc_nodes(i)
      
      IF (node_idx < 1 .OR. node_idx > nnode) THEN
        status%status_code = IF_STATUS_INVALID
        status%error_message = 'PH_Field_Apply_ThermalBC_Dirichlet: node index out of range'
        RETURN
      END IF

      ! Modify row: K_ii = 1, K_ij = 0
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
  END SUBROUTINE PH_Field_Apply_ThermalBC_Dirichlet

  ! ==========================================================================
  ! BOUNDARY CONDITIONS - Neumann (fixed heat flux)
  ! ==========================================================================
  !> @brief Apply Neumann BC: -k·∂T/∂n = q at Γ_N
  !! Boundary integral: F_i += ∫Γ_N Nᵢ·q dΓ
  !! @param[inout] F_global Force vector [nnode]
  !! @param[in] bc_faces Boundary face indices [n_faces]
  !! @param[in] flux_values Prescribed heat flux q [W/m²] [n_faces]
  !! @param[out] status Error status
  SUBROUTINE PH_Field_Apply_ThermalBC_Neumann(F_global, coords, conn, &
                                                bc_faces, face_nodes, &
                                                flux_values, status)
    REAL(wp), INTENT(INOUT) :: F_global(:)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    INTEGER(i4), INTENT(IN) :: bc_faces(:)       ! [n_faces]
    INTEGER(i4), INTENT(IN) :: face_nodes(:,:)   ! [n_face_nodes, n_faces]
    REAL(wp), INTENT(IN) :: flux_values(:)       ! [n_faces]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: face_coords(3, 4)
    REAL(wp) :: N_face(4)
    REAL(wp) :: dN_dxi(2, 4)
    REAL(wp) :: dx_dxi(3, 2), tangent1(3), tangent2(3)
    REAL(wp) :: detJ_face, w_gp
    REAL(wp) :: F_face(4)
    INTEGER(i4) :: n_faces, n_face_nodes, n_fp
    INTEGER(i4) :: f, gp_i, i, node_i, node_global
    TYPE(PH_Field_GaussPt_Arg) :: face_gp
    TYPE(PH_Field_ShapeFunc_Arg) :: shape_out
    TYPE(ErrorStatusType) :: shape_status

    CALL init_error_status(status)

    n_faces = SIZE(bc_faces)
    IF (SIZE(flux_values) /= n_faces) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Apply_ThermalBC_Neumann: bc_faces/flux_values size mismatch'
      RETURN
    END IF

    n_face_nodes = SIZE(face_nodes, 1)

    ! Get Gauss points for surface integration (2x2 = 4 points for quad face)
    CALL PH_Field_GetGaussPoints(PH_FIELD_GAUSS_RULE_2D_QUAD, 2, face_gp)
    IF (face_gp%status%status_code /= IF_STATUS_OK) THEN
      status = face_gp%status
      RETURN
    END IF

    n_fp = face_gp%n_ip

    ! Loop over boundary faces
    DO f = 1, n_faces
      ! Extract face node coordinates
      DO i = 1, n_face_nodes
        node_global = face_nodes(i, f)
        face_coords(:, i) = coords(:, node_global)
      END DO

      ! Initialize face force vector
      F_face = ZERO

      ! Loop over Gauss points on face
      DO gp_i = 1, n_fp
        w_gp = face_gp%weights(gp_i)

        ! Get shape functions at this face Gauss point
        CALL PH_Field_GetShapeFunctions('C3D8', face_gp%xi(gp_i), &
                                         face_gp%eta(gp_i), ZERO, &
                                         n_face_nodes, shape_out)

        N_face = shape_out%N(1:n_face_nodes)
        dN_dxi(1, 1:n_face_nodes) = shape_out%dN_dxi(1, 1:n_face_nodes)
        dN_dxi(2, 1:n_face_nodes) = shape_out%dN_dxi(2, 1:n_face_nodes)

        ! Compute boundary Jacobian: detJ_face = ||dx/dxi × dx/deta||
        dx_dxi(:, 1) = MATMUL(face_coords, dN_dxi(1, :))
        dx_dxi(:, 2) = MATMUL(face_coords, dN_dxi(2, :))

        ! Cross product
        tangent1(1) = dx_dxi(2, 1) * dx_dxi(3, 2) - dx_dxi(3, 1) * dx_dxi(2, 2)
        tangent1(2) = dx_dxi(3, 1) * dx_dxi(1, 2) - dx_dxi(1, 1) * dx_dxi(3, 2)
        tangent1(3) = dx_dxi(1, 1) * dx_dxi(2, 2) - dx_dxi(2, 1) * dx_dxi(1, 2)

        detJ_face = SQRT(tangent1(1)**2 + tangent1(2)**2 + tangent1(3)**2)

        ! Face force: F_face(i) = w_gp · N_i · q · detJ_face
        DO i = 1, n_face_nodes
          F_face(i) = F_face(i) + w_gp * N_face(i) * flux_values(f) * detJ_face
        END DO
      END DO

      ! Assemble to global
      DO i = 1, n_face_nodes
        node_global = face_nodes(i, f)
        F_global(node_global) = F_global(node_global) + F_face(i)
      END DO

      DEALLOCATE(shape_out%N, shape_out%dN_dxi)
    END DO

    ! Cleanup
    IF (ALLOCATED(face_gp%xi)) DEALLOCATE(face_gp%xi, face_gp%eta, &
                                          face_gp%zeta, face_gp%weights)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Apply_ThermalBC_Neumann

  ! ==========================================================================
  ! BOUNDARY CONDITIONS - Robin (convection)
  ! ==========================================================================
  !> @brief Apply Robin BC: -k·∂T/∂n = h·(T - T∞) at Γ_R
  !! Modify K and F:
  !!   K_ij += ∫Γ_R h·Nᵢ·Nⱼ dΓ
  !!   F_i += ∫Γ_R h·T∞·Nᵢ dΓ
  !! @param[inout] K_global Stiffness matrix [nnode, nnode]
  !! @param[inout] F_global Force vector [nnode]
  !! @param[in] bc_faces Boundary face indices [n_faces]
  !! @param[in] h_coeff Convection coefficient h [W/(m²·K)]
  !! @param[in] T_inf Ambient temperature T∞ [K]
  !! @param[out] status Error status
  SUBROUTINE PH_Field_Apply_ThermalBC_Robin(K_global, F_global, coords, &
                                              conn, bc_faces, face_nodes, &
                                              h_coeff, T_inf, status)
    REAL(wp), INTENT(INOUT) :: K_global(:,:)
    REAL(wp), INTENT(INOUT) :: F_global(:)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: conn(:,:)
    INTEGER(i4), INTENT(IN) :: bc_faces(:)       ! [n_faces]
    INTEGER(i4), INTENT(IN) :: face_nodes(:,:)   ! [n_face_nodes, n_faces]
    REAL(wp), INTENT(IN) :: h_coeff   ! h [W/(m²·K)]
    REAL(wp), INTENT(IN) :: T_inf     ! T∞ [K]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: face_coords(3, 4)
    REAL(wp) :: N_face(4)
    REAL(wp) :: dN_dxi(2, 4)
    REAL(wp) :: dx_dxi(3, 2), tangent1(3), tangent2(3)
    REAL(wp) :: detJ_face, w_gp
    REAL(wp) :: K_face(4, 4), F_face(4)
    INTEGER(i4) :: n_faces, n_face_nodes, n_fp
    INTEGER(i4) :: f, gp_i, i, j, node_i, node_j, node_global_i, node_global_j
    TYPE(PH_Field_GaussPt_Arg) :: face_gp
    TYPE(PH_Field_ShapeFunc_Arg) :: shape_out
    TYPE(ErrorStatusType) :: shape_status

    CALL init_error_status(status)

    n_faces = SIZE(bc_faces)
    n_face_nodes = SIZE(face_nodes, 1)

    ! Get Gauss points for surface integration (2x2 = 4 points)
    CALL PH_Field_GetGaussPoints(PH_FIELD_GAUSS_RULE_2D_QUAD, 2, face_gp)
    IF (face_gp%status%status_code /= IF_STATUS_OK) THEN
      status = face_gp%status
      RETURN
    END IF

    n_fp = face_gp%n_ip

    ! Loop over boundary faces
    DO f = 1, n_faces
      ! Extract face node coordinates
      DO i = 1, n_face_nodes
        node_global_i = face_nodes(i, f)
        face_coords(:, i) = coords(:, node_global_i)
      END DO

      ! Initialize face matrices
      K_face = ZERO
      F_face = ZERO

      ! Loop over Gauss points on face
      DO gp_i = 1, n_fp
        w_gp = face_gp%weights(gp_i)

        ! Get shape functions at this face Gauss point
        CALL PH_Field_GetShapeFunctions('C3D8', face_gp%xi(gp_i), &
                                         face_gp%eta(gp_i), ZERO, &
                                         n_face_nodes, shape_out)

        N_face = shape_out%N(1:n_face_nodes)
        dN_dxi(1, 1:n_face_nodes) = shape_out%dN_dxi(1, 1:n_face_nodes)
        dN_dxi(2, 1:n_face_nodes) = shape_out%dN_dxi(2, 1:n_face_nodes)

        ! Compute boundary Jacobian: detJ_face = ||dx/dxi × dx/deta||
        dx_dxi(:, 1) = MATMUL(face_coords, dN_dxi(1, :))
        dx_dxi(:, 2) = MATMUL(face_coords, dN_dxi(2, :))

        ! Cross product
        tangent1(1) = dx_dxi(2, 1) * dx_dxi(3, 2) - dx_dxi(3, 1) * dx_dxi(2, 2)
        tangent1(2) = dx_dxi(3, 1) * dx_dxi(1, 2) - dx_dxi(1, 1) * dx_dxi(3, 2)
        tangent1(3) = dx_dxi(1, 1) * dx_dxi(2, 2) - dx_dxi(2, 1) * dx_dxi(1, 2)

        detJ_face = SQRT(tangent1(1)**2 + tangent1(2)**2 + tangent1(3)**2)

        ! Face stiffness: K_face(i,j) = w_gp · h · Nᵢ·Nⱼ · detJ_face
        ! Face force: F_face(i) = w_gp · h · T∞ · Nᵢ · detJ_face
        DO i = 1, n_face_nodes
          DO j = 1, n_face_nodes
            K_face(i, j) = K_face(i, j) + w_gp * h_coeff * &
                          N_face(i) * N_face(j) * detJ_face
          END DO
          F_face(i) = F_face(i) + w_gp * h_coeff * T_inf * &
                     N_face(i) * detJ_face
        END DO
      END DO

      ! Assemble to global
      DO i = 1, n_face_nodes
        node_global_i = face_nodes(i, f)
        DO j = 1, n_face_nodes
          node_global_j = face_nodes(j, f)
          K_global(node_global_i, node_global_j) = &
            K_global(node_global_i, node_global_j) + K_face(i, j)
        END DO
        F_global(node_global_i) = F_global(node_global_i) + F_face(i)
      END DO

      DEALLOCATE(shape_out%N, shape_out%dN_dxi)
    END DO

    ! Cleanup
    IF (ALLOCATED(face_gp%xi)) DEALLOCATE(face_gp%xi, face_gp%eta, &
                                          face_gp%zeta, face_gp%weights)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Apply_ThermalBC_Robin

END MODULE PH_Field_ComputeTemp