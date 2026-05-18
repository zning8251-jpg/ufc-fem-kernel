!===============================================================================
! MODULE: PH_Elem_Mtx
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Element K/M/F assembly helpers (Shared Tool)
!===============================================================================
MODULE PH_Elem_Mtx
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
    USE IF_Base_Def, ONLY: ZERO, ONE, HALF
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    USE PH_Elem_BMtx, ONLY: PH_Elem_BMatrix_2D_Plane, &
                            PH_Elem_BMatrix_3D_Continuum
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: PH_Elem_StiffnessMatrix_2D
    PUBLIC :: PH_Elem_StiffnessMatrix_3D
    PUBLIC :: PH_Elem_MassMatrix_2D
    PUBLIC :: PH_Elem_MassMatrix_3D
    PUBLIC :: PH_Elem_LoadVector_BodyForce
    PUBLIC :: PH_Elem_LoadVector_SurfaceForce
    PUBLIC :: PH_Elem_StressRecovery
    PUBLIC :: PH_Elem_StrainRecovery
    ! Extended API (task8700-8899)
    PUBLIC :: PH_Elem_AssembleStiffnessMatrix
    PUBLIC :: PH_Elem_AssembleMassMatrix
    PUBLIC :: PH_Elem_AssembleLoadVector

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Shared_Args
  TYPE :: PH_Elem_Shared_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Shared_Args


CONTAINS

    SUBROUTINE PH_El_AssembleStiffnessMatri(K_element, dof_map, &
                                               K_global, status)
        ! > [Theory] Ke(n,n) DOF K_global
        ! > [Logic] K_element dof_map �?DOF (i,j) �?DOF �?
        !> [Compute] DO i=1,n; g_i=dof_map(i); DO j=1,n; g_j=dof_map(j); K_global(g_i,g_j)+=K_element(i,j); END DO; END DO
        ! > [Data chain] K_element(n,n), dof_map(n) �?K_global(nDOF,nDOF)
        REAL(wp), INTENT(IN) :: K_element(:,:)     ! Element stiffness matrix
        INTEGER(i4), INTENT(IN) :: dof_map(:)       ! DOF mapping (local to global)
        REAL(wp), INTENT(INOUT) :: K_global(:,:)    ! Global stiffness matrix
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, j, n_dof, g_i, g_j

        CALL init_error_status(status)

        n_dof = SIZE(K_element, 1)

        IF (SIZE(dof_map) < n_dof) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_AssembleStiffnessMatrix: Invalid dof_map size'
            RETURN
        END IF

        ! Assemble: K_global(dof_map(i), dof_map(j)) += K_element(i, j)
        DO i = 1, n_dof
            g_i = dof_map(i)
            IF (g_i > 0 .AND. g_i <= SIZE(K_global, 1)) THEN
                DO j = 1, n_dof
                    g_j = dof_map(j)
                    IF (g_j > 0 .AND. g_j <= SIZE(K_global, 2)) THEN
                        K_global(g_i, g_j) = K_global(g_i, g_j) + K_element(i, j)
                    END IF
                END DO
            END IF
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_AssembleStiffnessMatrix

    SUBROUTINE PH_El_Lo_SurfaceForce(N, surface_force, detJ_surf, &
                                               weight, n_gauss, F_vector, status)
        REAL(wp), INTENT(IN) :: N(:)            ! Shape functions (n_nodes)
        REAL(wp), INTENT(IN) :: surface_force(:) ! Surface force (n_dim)
        REAL(wp), INTENT(IN) :: detJ_surf       ! Surface Jacobian determinant
        REAL(wp), INTENT(IN) :: weight          ! Gauss weight
        INTEGER(i4), INTENT(IN) :: n_gauss      ! Number of Gauss points
        REAL(wp), INTENT(OUT) :: F_vector(:)    ! Load vector
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: dA
        INTEGER(i4) :: i, j, n_nodes, n_dim

        CALL init_error_status(status)

        n_nodes = SIZE(N)
        n_dim = SIZE(surface_force)

        IF (SIZE(F_vector) < n_dim * n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_LoadVector_SurfaceForce: Invalid F dimensions'
            RETURN
        END IF

        ! Surface area element
        dA = detJ_surf * weight

        ! Compute F = N^T * t * dA
        DO i = 1, n_nodes
            DO j = 1, n_dim
                F_vector(n_dim*(i-1) + j) = F_vector(n_dim*(i-1) + j) + &
                                           N(i) * surface_force(j) * dA
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_LoadVector_SurfaceForce

    SUBROUTINE PH_Elem_AssembleLoadVector(F_element, dof_map, &
                                          F_global, status)
        REAL(wp), INTENT(IN) :: F_element(:)       ! Element load vector
        INTEGER(i4), INTENT(IN) :: dof_map(:)       ! DOF mapping (local to global)
        REAL(wp), INTENT(INOUT) :: F_global(:)      ! Global load vector
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, n_dof, g_i

        CALL init_error_status(status)

        n_dof = SIZE(F_element)

        IF (SIZE(dof_map) < n_dof) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_AssembleLoadVector: Invalid dof_map size'
            RETURN
        END IF

        ! Assemble: F_global(dof_map(i)) += F_element(i)
        DO i = 1, n_dof
            g_i = dof_map(i)
            IF (g_i > 0 .AND. g_i <= SIZE(F_global)) THEN
                F_global(g_i) = F_global(g_i) + F_element(i)
            END IF
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_AssembleLoadVector

    SUBROUTINE PH_Elem_AssembleMassMatrix(M_element, dof_map, &
                                         M_global, status)
        REAL(wp), INTENT(IN) :: M_element(:,:)     ! Element mass matrix
        INTEGER(i4), INTENT(IN) :: dof_map(:)       ! DOF mapping (local to global)
        REAL(wp), INTENT(INOUT) :: M_global(:,:)   ! Global mass matrix
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        ! ============================================================================
        ! Purpose:
        ! : M_global = Σ_e A_e^T M_e A_e (A_e )
        ! : M_element,dof_map -> DOF -> ->
        ! : (i,j) -> M_global(g_i,g_j) += M_element(i,j) [O(n^2)]
        ! : M_element(alloc) -> dof_map(alloc) -> M_global(CSR,INOUT)
        ! ============================================================================
        INTEGER(i4) :: i, j, n_dof, g_i, g_j

        CALL init_error_status(status)

        n_dof = SIZE(M_element, 1)

        IF (SIZE(dof_map) < n_dof) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_AssembleMassMatrix: Invalid dof_map size'
            RETURN
        END IF

        ! Assemble: M_global(dof_map(i), dof_map(j)) += M_element(i, j)
        DO i = 1, n_dof
            g_i = dof_map(i)
            IF (g_i > 0 .AND. g_i <= SIZE(M_global, 1)) THEN
                DO j = 1, n_dof
                    g_j = dof_map(j)
                    IF (g_j > 0 .AND. g_j <= SIZE(M_global, 2)) THEN
                        M_global(g_i, g_j) = M_global(g_i, g_j) + M_element(i, j)
                    END IF
                END DO
            END IF
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_AssembleMassMatrix

    SUBROUTINE PH_Elem_LoadVector_BodyForce(N, body_force, detJ, weight, &
                                            n_gauss, F_vector, status)
        REAL(wp), INTENT(IN) :: N(:)            ! Shape functions (n_nodes)
        REAL(wp), INTENT(IN) :: body_force(:)   ! Body force (n_dim)
        REAL(wp), INTENT(IN) :: detJ            ! Jacobian determinant
        REAL(wp), INTENT(IN) :: weight          ! Gauss weight
        INTEGER(i4), INTENT(IN) :: n_gauss     ! Number of Gauss points
        REAL(wp), INTENT(OUT) :: F_vector(:)   ! Load vector
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: dV
        INTEGER(i4) :: i, j, n_nodes, n_dim

        CALL init_error_status(status)

        n_nodes = SIZE(N)
        n_dim = SIZE(body_force)

        IF (SIZE(F_vector) < n_dim * n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_LoadVector_BodyForce: Invalid F dimensions'
            RETURN
        END IF

        ! Volume element
        dV = detJ * weight

        ! Compute F = N^T * b * dV
        DO i = 1, n_nodes
            DO j = 1, n_dim
                F_vector(n_dim*(i-1) + j) = F_vector(n_dim*(i-1) + j) + &
                                           N(i) * body_force(j) * dV
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_LoadVector_BodyForce

    SUBROUTINE PH_Elem_MassMatrix_2D(N, density, detJ, weight, &
                                    n_gauss, M_matrix, status)
        REAL(wp), INTENT(IN) :: N(:)            ! Shape functions (n_nodes)
        REAL(wp), INTENT(IN) :: density         ! Mat density
        REAL(wp), INTENT(IN) :: detJ            ! Jacobian determinant
        REAL(wp), INTENT(IN) :: weight          ! Gauss weight
        INTEGER(i4), INTENT(IN) :: n_gauss      ! Number of Gauss points
        REAL(wp), INTENT(OUT) :: M_matrix(:,:) ! Mass matrix
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: dV
        INTEGER(i4) :: i, j, n_nodes

        CALL init_error_status(status)

        n_nodes = SIZE(N)

        IF (SIZE(M_matrix, 1) < 2*n_nodes .OR. SIZE(M_matrix, 2) < 2*n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_MassMatrix_2D: Invalid M dimensions'
            RETURN
        END IF

        ! Volume element
        dV = detJ * weight

        ! Compute M = Ï * N^T * N * dV (lumped mass matrix)
        DO i = 1, n_nodes
            DO j = 1, n_nodes
                M_matrix(2*i-1, 2*j-1) = M_matrix(2*i-1, 2*j-1) + &
                                          density * N(i) * N(j) * dV
                M_matrix(2*i, 2*j) = M_matrix(2*i, 2*j) + &
                                    density * N(i) * N(j) * dV
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_MassMatrix_2D

    SUBROUTINE PH_Elem_MassMatrix_3D(N, density, detJ, weight, &
                                    n_gauss, M_matrix, status)
        REAL(wp), INTENT(IN) :: N(:)            ! Shape functions (n_nodes)
        REAL(wp), INTENT(IN) :: density         ! Mat density
        REAL(wp), INTENT(IN) :: detJ            ! Jacobian determinant
        REAL(wp), INTENT(IN) :: weight          ! Gauss weight
        INTEGER(i4), INTENT(IN) :: n_gauss      ! Number of Gauss points
        REAL(wp), INTENT(OUT) :: M_matrix(:,:) ! Mass matrix
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: dV
        INTEGER(i4) :: i, j, n_nodes

        CALL init_error_status(status)

        n_nodes = SIZE(N)

        IF (SIZE(M_matrix, 1) < 3*n_nodes .OR. SIZE(M_matrix, 2) < 3*n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_MassMatrix_3D: Invalid M dimensions'
            RETURN
        END IF

        ! Volume element
        dV = detJ * weight

        ! Compute M = Ï * N^T * N * dV (lumped mass matrix)
        DO i = 1, n_nodes
            DO j = 1, n_nodes
                M_matrix(3*i-2, 3*j-2) = M_matrix(3*i-2, 3*j-2) + &
                                         density * N(i) * N(j) * dV
                M_matrix(3*i-1, 3*j-1) = M_matrix(3*i-1, 3*j-1) + &
                                         density * N(i) * N(j) * dV
                M_matrix(3*i, 3*j) = M_matrix(3*i, 3*j) + &
                                    density * N(i) * N(j) * dV
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_MassMatrix_3D

    SUBROUTINE PH_Elem_StiffnessMatrix_2D(B, D_matrix, detJ, weight, &
                                          n_gauss, K_matrix, status)
        REAL(wp), INTENT(IN) :: B(:,:)          ! B-matrix (3, 2*n_nodes)
        REAL(wp), INTENT(IN) :: D_matrix(:,:)   ! Mat stiffness (3, 3)
        REAL(wp), INTENT(IN) :: detJ            ! Jacobian determinant
        REAL(wp), INTENT(IN) :: weight          ! Gauss weight
        INTEGER(i4), INTENT(IN) :: n_gauss      ! Number of Gauss points
        REAL(wp), INTENT(OUT) :: K_matrix(:,:)  ! Stiffness matrix
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: DB(3, SIZE(B, 2))
        REAL(wp) :: dV
        INTEGER(i4) :: i, j, k, n_dof

        CALL init_error_status(status)

        n_dof = SIZE(B, 2)

        IF (SIZE(K_matrix, 1) < n_dof .OR. SIZE(K_matrix, 2) < n_dof) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_StiffnessMatrix_2D: Invalid K dimensions'
            RETURN
        END IF

        ! Volume element
        dV = detJ * weight

        ! Compute DB = D * B
        DB = ZERO
        DO i = 1, 3
            DO j = 1, n_dof
                DO k = 1, 3
                    DB(i, j) = DB(i, j) + D_matrix(i, k) * B(k, j)
                END DO
            END DO
        END DO

        ! Compute K = B^T * DB * dV
        DO i = 1, n_dof
            DO j = 1, n_dof
                DO k = 1, 3
                    K_matrix(i, j) = K_matrix(i, j) + B(k, i) * DB(k, j) * dV
                END DO
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_StiffnessMatrix_2D

    SUBROUTINE PH_Elem_StiffnessMatrix_3D(B, D_matrix, detJ, weight, &
                                          n_gauss, K_matrix, status)
        REAL(wp), INTENT(IN) :: B(:,:)          ! B-matrix (6, 3*n_nodes)
        REAL(wp), INTENT(IN) :: D_matrix(:,:)   ! Mat stiffness (6, 6)
        REAL(wp), INTENT(IN) :: detJ            ! Jacobian determinant
        REAL(wp), INTENT(IN) :: weight          ! Gauss weight
        INTEGER(i4), INTENT(IN) :: n_gauss      ! Number of Gauss points
        REAL(wp), INTENT(OUT) :: K_matrix(:,:)  ! Stiffness matrix
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: DB(6, SIZE(B, 2))
        REAL(wp) :: dV
        INTEGER(i4) :: i, j, k, n_dof

        CALL init_error_status(status)

        n_dof = SIZE(B, 2)

        IF (SIZE(K_matrix, 1) < n_dof .OR. SIZE(K_matrix, 2) < n_dof) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_StiffnessMatrix_3D: Invalid K dimensions'
            RETURN
        END IF

        ! Volume element
        dV = detJ * weight

        ! Compute DB = D * B
        DB = ZERO
        DO i = 1, 6
            DO j = 1, n_dof
                DO k = 1, 6
                    DB(i, j) = DB(i, j) + D_matrix(i, k) * B(k, j)
                END DO
            END DO
        END DO

        ! Compute K = B^T * DB * dV
        DO i = 1, n_dof
            DO j = 1, n_dof
                DO k = 1, 6
                    K_matrix(i, j) = K_matrix(i, j) + B(k, i) * DB(k, j) * dV
                END DO
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_StiffnessMatrix_3D

    SUBROUTINE PH_Elem_StrainRecovery(B, u_nodal, strain, status)
        REAL(wp), INTENT(IN) :: B(:,:)          ! B-matrix
        REAL(wp), INTENT(IN) :: u_nodal(:)      ! Nodal displacements
        REAL(wp), INTENT(OUT) :: strain(:)      ! Strain components
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, j, n_strain

        CALL init_error_status(status)

        n_strain = SIZE(B, 1)

        IF (SIZE(strain) < n_strain) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_StrainRecovery: Invalid strain dimensions'
            RETURN
        END IF

        ! Compute strain: Îµ = B * u
        strain = ZERO
        DO i = 1, n_strain
            DO j = 1, SIZE(u_nodal)
                strain(i) = strain(i) + B(i, j) * u_nodal(j)
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_StrainRecovery

    SUBROUTINE PH_Elem_StressRecovery(B, D_matrix, u_nodal, sigma, status)
        REAL(wp), INTENT(IN) :: B(:,:)          ! B-matrix
        REAL(wp), INTENT(IN) :: D_matrix(:,:)   ! Mat stiffness
        REAL(wp), INTENT(IN) :: u_nodal(:)       ! Nodal displacements
        REAL(wp), INTENT(OUT) :: sigma(:)       ! Stress components
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: strain(SIZE(B, 1))
        INTEGER(i4) :: i, j, n_strain

        CALL init_error_status(status)

        n_strain = SIZE(B, 1)

        IF (SIZE(sigma) < n_strain) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_StressRecovery: Invalid sigma dimensions'
            RETURN
        END IF

        ! Compute strain: Îµ = B * u
        strain = ZERO
        DO i = 1, n_strain
            DO j = 1, SIZE(u_nodal)
                strain(i) = strain(i) + B(i, j) * u_nodal(j)
            END DO
        END DO

        ! Compute sigma: Ï = D * Îµ
        sigma = ZERO
        DO i = 1, n_strain
            DO j = 1, n_strain
                sigma(i) = sigma(i) + D_matrix(i, j) * strain(j)
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_StressRecovery
END MODULE PH_Elem_Mtx