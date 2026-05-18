!===============================================================================
! MODULE: PH_Elem_Nlgeom
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  Geometric nonlinearity core for TL/UL formulations
!===============================================================================
MODULE PH_Elem_Nlgeom
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_State, &
                           PH_Elem_Algo, PH_Elem_Ctx
  USE PH_Mat_hTensor, ONLY: PH_Tensor_Sym_To_Voigt, PH_Voigt_To_Tensor_Sym

  USE PH_Elem_NLGeom_Core, ONLY: PH_ELEM_NLGEOM_NONE, PH_ELEM_NLGEOM_TL, PH_ELEM_NLGEOM_UL

  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! Constants — re-exported from PH_Elem_NLGeom_Core (canonical names)
  !============================================================================
  PUBLIC :: PH_ELEM_NLGEOM_NONE, PH_ELEM_NLGEOM_TL, PH_ELEM_NLGEOM_UL

  !============================================================================
  ! TYPE: PH_Nlgeom_Args
  ! Nonlinear geometry computation arguments
  !============================================================================
  TYPE, PUBLIC :: PH_Nlgeom_Args
    !-- Input: kinematics
    REAL(wp), ALLOCATABLE :: coords_ref(:,:)  ! Reference coords [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: coords_cur(:,:)  ! Current coords [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:,:)    ! Shape func derivs [n_nodes, dim, n_ip]
    
    !-- Output: strain measures
    REAL(wp), ALLOCATABLE :: E_gl(:)          ! Green-Lagrange strain [6/n_strain]
    REAL(wp), ALLOCATABLE :: e_alm(:)         ! Almansi strain [6/n_strain]
    
    !-- Output: deformation measures
    REAL(wp), ALLOCATABLE :: F(:,:)           ! Deformation gradient [dim, dim]
    REAL(wp), ALLOCATABLE :: Finv(:,:)        ! Inverse F [dim, dim]
    REAL(wp) :: detF = 1.0_wp                 ! Jacobian J = det(F)
    
    !-- Output: stress measures
    REAL(wp), ALLOCATABLE :: S_pk2(:)         ! 2nd Piola-Kirchhoff [6/n_strain]
    REAL(wp), ALLOCATABLE :: sigma_cauchy(:)  ! Cauchy stress [6/n_strain]
    
    !-- Metadata
    INTEGER(i4) :: ndim = 3                   ! Spatial dimension
    INTEGER(i4) :: nlgeom_type = PH_ELEM_NLGEOM_NONE  ! TL/UL/None
    LOGICAL :: is_valid = .FALSE.             ! Validation flag
    
  END TYPE PH_Nlgeom_Args

  !============================================================================
  ! Public interfaces
  !============================================================================
  PUBLIC :: PH_Compute_Deformation_Gradient
  PUBLIC :: PH_Compute_Green_Lagrange_Strain
  PUBLIC :: PH_Compute_Almansi_Strain
  PUBLIC :: PH_Compute_B_Matrix_NL
  PUBLIC :: PH_Transform_Stress_PK2_to_Cauchy
  PUBLIC :: PH_Transform_Stress_Cauchy_to_PK2

CONTAINS

  !============================================================================
  ! Subroutine: PH_Compute_Deformation_Gradient
  ! Purpose: Compute deformation gradient F = dx/dX = I + du/dX
  !============================================================================
  SUBROUTINE PH_Compute_Deformation_Gradient(args, status)
    TYPE(PH_Nlgeom_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, k, node
    REAL(wp) :: dX(3), dx(3)
    REAL(wp) :: dudX(3,3)

    IF (.NOT. args%is_valid) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid args")
      RETURN
    END IF

    IF (args%cfg%ndim < 2 .OR. args%cfg%ndim > 3) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid ndim")
      RETURN
    END IF

    ! Initialize F = I
    args%F = 0.0_wp
    DO i = 1, args%cfg%ndim
      args%F(i,i) = 1.0_wp
    END DO

    ! Compute displacement gradient: du/dX = sum_node (dN_dxi * u_node)
    dudX = 0.0_wp
    DO node = 1, SIZE(args%coords_ref, 2)
      DO i = 1, args%cfg%ndim
        dx(i) = args%coords_cur(i, node)
        dX(i) = args%coords_ref(i, node)
        DO j = 1, args%cfg%ndim
          dudX(i,j) = dudX(i,j) + args%dN_dxi(node, j, 1) * (dx(i) - dX(i))
        END DO
      END DO
    END DO

    ! F = I + du/dX
    DO i = 1, args%cfg%ndim
      DO j = 1, args%cfg%ndim
        args%F(i,j) = args%F(i,j) + dudX(i,j)
      END DO
    END DO

    ! Compute det(F)
    IF (args%cfg%ndim == 3) THEN
      args%detF = args%F(1,1)*(args%F(2,2)*args%F(3,3) - args%F(2,3)*args%F(3,2)) &
                - args%F(1,2)*(args%F(2,1)*args%F(3,3) - args%F(2,3)*args%F(3,1)) &
                + args%F(1,3)*(args%F(2,1)*args%F(3,2) - args%F(2,2)*args%F(3,1))
    ELSE IF (args%cfg%ndim == 2) THEN
      args%detF = args%F(1,1)*args%F(2,2) - args%F(1,2)*args%F(2,1)
    END IF

    ! Check det(F) > 0
    IF (args%detF <= 0.0_wp) THEN
      CALL init_error_status(status, STATUS_ERR, "detF <= 0")
      RETURN
    END IF

    ! Compute F^{-1}
    CALL PH_Invert_Matrix_2x2_or_3x3(args%F, args%Finv, args%cfg%ndim, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      RETURN
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Compute_Deformation_Gradient

  !============================================================================
  ! Subroutine: PH_Compute_Green_Lagrange_Strain
  ! Purpose: Compute Green-Lagrange strain E = 0.5*(F^T*F - I)
  !============================================================================
  SUBROUTINE PH_Compute_Green_Lagrange_Strain(args, status)
    TYPE(PH_Nlgeom_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j
    REAL(wp) :: C(3,3)  ! Right Cauchy-Green tensor

    IF (.NOT. args%is_valid) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid args")
      RETURN
    END IF

    ! Compute C = F^T * F
    C = MATMUL(TRANSPOSE(args%F), args%F)

    ! E = 0.5 * (C - I)
    DO i = 1, args%cfg%ndim
      DO j = 1, args%cfg%ndim
        IF (i == j) THEN
          C(i,j) = C(i,j) - 1.0_wp
        END IF
        C(i,j) = 0.5_wp * C(i,j)
      END DO
    END DO

    ! Convert to Voigt notation
    IF (ALLOCATED(args%E_gl)) THEN
      CALL PH_Tensor_Sym_To_Voigt(C, args%E_gl, args%cfg%ndim)
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Compute_Green_Lagrange_Strain

  !============================================================================
  ! Subroutine: PH_Compute_Almansi_Strain
  ! Purpose: Compute Almansi strain e = 0.5*(I - F^{-T}*F^{-1})
  !============================================================================
  SUBROUTINE PH_Compute_Almansi_Strain(args, status)
    TYPE(PH_Nlgeom_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j
    REAL(wp) :: b(3,3)  ! Left Cauchy-Green tensor
    REAL(wp) :: e_tensor(3,3)

    IF (.NOT. args%is_valid) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid args")
      RETURN
    END IF

    ! Compute b = F * F^T
    b = MATMUL(args%F, TRANSPOSE(args%F))

    ! e = 0.5 * (I - b^{-1})
    ! Note: b^{-1} = F^{-T} * F^{-1}
    e_tensor = 0.0_wp
    DO i = 1, args%cfg%ndim
      DO j = 1, args%cfg%ndim
        e_tensor(i,j) = -0.5_wp * b(i,j)
      END DO
      e_tensor(i,i) = e_tensor(i,i) + 0.5_wp
    END DO

    ! Convert to Voigt notation
    IF (ALLOCATED(args%e_alm)) THEN
      CALL PH_Tensor_Sym_To_Voigt(e_tensor, args%e_alm, args%cfg%ndim)
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Compute_Almansi_Strain

  !============================================================================
  ! Subroutine: PH_Compute_B_Matrix_NL
  ! Purpose: Compute nonlinear strain-displacement matrix B
  !============================================================================
  SUBROUTINE PH_Compute_B_Matrix_NL(args, B_matrix, status)
    TYPE(PH_Nlgeom_Args), INTENT(IN) :: args
    REAL(wp), INTENT(OUT) :: B_matrix(:,:)  ! [n_strain, n_dof]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: node, i, j, idx
    REAL(wp) :: dN_dX(3)

    IF (.NOT. args%is_valid) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid args")
      RETURN
    END IF

    B_matrix = 0.0_wp

    ! For TL: B = dN/dX (reference configuration)
    ! For UL: B = dN/dx (current configuration)
    ! This is simplified; full implementation requires B = B_linear + B_nonlinear

    DO node = 1, SIZE(args%dN_dxi, 1)
      dN_dX = args%dN_dxi(node, :, 1)  ! Simplified: use first IP
      
      DO i = 1, args%cfg%ndim
        idx = (node - 1) * args%cfg%ndim + i
        
        ! Normal strains
        B_matrix(i, idx) = dN_dX(i)
        
        ! Shear strains (engineering notation)
        IF (i < args%cfg%ndim) THEN
          DO j = i + 1, args%cfg%ndim
            SELECT CASE (i*10 + j)
            CASE (12)  ! gamma_xy
              B_matrix(4, idx) = dN_dX(j)
              B_matrix(4, (node-1)*args%cfg%ndim + j) = dN_dX(i)
            CASE (13)  ! gamma_xz
              B_matrix(5, idx) = dN_dX(j)
              B_matrix(5, (node-1)*args%cfg%ndim + j) = dN_dX(i)
            CASE (23)  ! gamma_yz
              B_matrix(6, idx) = dN_dX(j)
              B_matrix(6, (node-1)*args%cfg%ndim + j) = dN_dX(i)
            END SELECT
          END DO
        END IF
      END DO
    END DO

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Compute_B_Matrix_NL

  !============================================================================
  ! Subroutine: PH_Transform_Stress_PK2_to_Cauchy
  ! Purpose: Transform 2nd PK stress to Cauchy stress: sigma = (1/J) * F * S * F^T
  !============================================================================
  SUBROUTINE PH_Transform_Stress_PK2_to_Cauchy(args, status)
    TYPE(PH_Nlgeom_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, k, l
    REAL(wp) :: S_tensor(3,3), sigma_tensor(3,3)

    IF (.NOT. args%is_valid) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid args")
      RETURN
    END IF

    ! Convert PK2 from Voigt to tensor
    IF (ALLOCATED(args%S_pk2)) THEN
      CALL PH_Voigt_To_Tensor_Sym(args%S_pk2, S_tensor, args%cfg%ndim)
    ELSE
      CALL init_error_status(status, STATUS_ERR, "S_pk2 not allocated")
      RETURN
    END IF

    ! sigma = (1/J) * F * S * F^T
    sigma_tensor = 0.0_wp
    DO i = 1, args%cfg%ndim
      DO j = 1, args%cfg%ndim
        DO k = 1, args%cfg%ndim
          DO l = 1, args%cfg%ndim
            sigma_tensor(i,j) = sigma_tensor(i,j) + &
                                args%F(i,k) * S_tensor(k,l) * args%F(j,l)
          END DO
        END DO
        sigma_tensor(i,j) = sigma_tensor(i,j) / args%detF
      END DO
    END DO

    ! Convert back to Voigt
    IF (ALLOCATED(args%sigma_cauchy)) THEN
      CALL PH_Tensor_Sym_To_Voigt(sigma_tensor, args%sigma_cauchy, args%cfg%ndim)
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Transform_Stress_PK2_to_Cauchy

  !============================================================================
  ! Subroutine: PH_Transform_Stress_Cauchy_to_PK2
  ! Purpose: Transform Cauchy stress to 2nd PK: S = J * F^{-1} * sigma * F^{-T}
  !============================================================================
  SUBROUTINE PH_Transform_Stress_Cauchy_to_PK2(args, status)
    TYPE(PH_Nlgeom_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j, k, l
    REAL(wp) :: S_tensor(3,3), sigma_tensor(3,3)

    IF (.NOT. args%is_valid) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid args")
      RETURN
    END IF

    ! Convert Cauchy from Voigt to tensor
    IF (ALLOCATED(args%sigma_cauchy)) THEN
      CALL PH_Voigt_To_Tensor_Sym(args%sigma_cauchy, sigma_tensor, args%cfg%ndim)
    ELSE
      CALL init_error_status(status, STATUS_ERR, "sigma_cauchy not allocated")
      RETURN
    END IF

    ! S = J * F^{-1} * sigma * F^{-T}
    S_tensor = 0.0_wp
    DO i = 1, args%cfg%ndim
      DO j = 1, args%cfg%ndim
        DO k = 1, args%cfg%ndim
          DO l = 1, args%cfg%ndim
            S_tensor(i,j) = S_tensor(i,j) + &
                            args%Finv(i,k) * sigma_tensor(k,l) * args%Finv(j,l)
          END DO
        END DO
        S_tensor(i,j) = S_tensor(i,j) * args%detF
      END DO
    END DO

    ! Convert back to Voigt
    IF (ALLOCATED(args%S_pk2)) THEN
      CALL PH_Tensor_Sym_To_Voigt(S_tensor, args%S_pk2, args%cfg%ndim)
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Transform_Stress_Cauchy_to_PK2

  !============================================================================
  ! Helper: Matrix inversion (2x2 or 3x3)
  !============================================================================
  SUBROUTINE PH_Invert_Matrix_2x2_or_3x3(A, Ainv, ndim, status)
    REAL(wp), INTENT(IN) :: A(:,:)
    REAL(wp), INTENT(OUT) :: Ainv(:,:)
    INTEGER(i4), INTENT(IN) :: ndim
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: detA, inv_det

    IF (ndim == 2) THEN
      detA = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      IF (ABS(detA) < 1.0E-12_wp) THEN
        CALL init_error_status(status, STATUS_ERR, "Singular 2x2 matrix")
        RETURN
      END IF
      inv_det = 1.0_wp / detA
      Ainv(1,1) = A(2,2) * inv_det
      Ainv(1,2) = -A(1,2) * inv_det
      Ainv(2,1) = -A(2,1) * inv_det
      Ainv(2,2) = A(1,1) * inv_det

    ELSE IF (ndim == 3) THEN
      detA = A(1,1)*(A(2,2)*A(3,3) - A(2,3)*A(3,2)) &
           - A(1,2)*(A(2,1)*A(3,3) - A(2,3)*A(3,1)) &
           + A(1,3)*(A(2,1)*A(3,2) - A(2,2)*A(3,1))
      
      IF (ABS(detA) < 1.0E-12_wp) THEN
        CALL init_error_status(status, STATUS_ERR, "Singular 3x3 matrix")
        RETURN
      END IF
      inv_det = 1.0_wp / detA
      
      Ainv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) * inv_det
      Ainv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) * inv_det
      Ainv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) * inv_det
      Ainv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) * inv_det
      Ainv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) * inv_det
      Ainv(2,3) = (A(2,1)*A(1,3) - A(1,1)*A(2,3)) * inv_det
      Ainv(3,1) = (A(2,1)*A(3,2) - A(3,1)*A(2,2)) * inv_det
      Ainv(3,2) = (A(3,1)*A(1,2) - A(1,1)*A(3,2)) * inv_det
      Ainv(3,3) = (A(1,1)*A(2,2) - A(2,1)*A(1,2)) * inv_det
    ELSE
      CALL init_error_status(status, STATUS_ERR, "Invalid dimension")
      RETURN
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Invert_Matrix_2x2_or_3x3

END MODULE PH_Elem_Nlgeom