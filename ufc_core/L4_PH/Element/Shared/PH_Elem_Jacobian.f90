!===============================================================================
! MODULE: PH_Elem_Jacobian
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Jacobian J = ∂x/∂�?and det J (Shared Tool)
!===============================================================================
MODULE PH_Elem_Jacobian
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
    USE IF_Base_Def, ONLY: ZERO, ONE
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: PH_Elem_Jacobian_2D
    PUBLIC :: PH_Elem_Jacobian_3D
    PUBLIC :: PH_Elem_Jacobian_Det2D
    PUBLIC :: PH_Elem_Jacobian_Det3D
    PUBLIC :: PH_Elem_Jacobian_Inverse2D
    PUBLIC :: PH_Elem_Jacobian_Inverse3D
    PUBLIC :: PH_Elem_Jacobian_ShapeDerivatives

    !==========================================================================
    ! INTF-001 Jacobian
    ! Purpose: ET_Jacobian_2D / ET_Jacobian_3D /
    ! ET_Jacobian_ShapeDerivatives 6
    ! Theory: J_ij = Σ_k (dN_k/dξ_i) · x_j^k Jacobian
    ! det(J) > 0
    ! Status: Draft |
    !==========================================================================
    PUBLIC :: PH_Elem_JacobianArgs

    TYPE :: PH_Elem_JacobianArgs
      ! ---- ----
      INTEGER(i4) :: dim     = 3_i4  !! 2 3
      INTEGER(i4) :: n_nodes = 0_i4  ! node count

      ! ---- POINTER ----
      REAL(wp), POINTER :: dN_dxi(:,:) => NULL()  !! (dim, n_nodes)
      REAL(wp), POINTER :: coords(:,:) => NULL()  !! (dim, n_nodes)

      ! ---- Jacobian ----
      REAL(wp) :: J_2D(2,2) = 0.0_wp    !! 2D Jacobian
      REAL(wp) :: J_3D(3,3) = 0.0_wp    !! 3D Jacobian
      REAL(wp) :: detJ      = 0.0_wp    !! Jacobian

      ! ---- Jacobian ----
      REAL(wp) :: J_inv_2D(2,2) = 0.0_wp  !! 2D Jacobian
      REAL(wp) :: J_inv_3D(3,3) = 0.0_wp  !! 3D Jacobian
      REAL(wp), POINTER :: dN_dx(:,:) => NULL()  !! (dim, n_nodes)

      ! ---- ----
      TYPE(ErrorStatusType), POINTER :: status => NULL()  ! error status ptr (IF_Err)
    END TYPE PH_Elem_JacobianArgs



    !> @brief Compute 2D Jacobian matrix
    !! @param[in] dN_dxi Shape function derivatives w.r.t. natural coords (2, n_nodes)
    !! @param[in] coords Node coordinates (2, n_nodes)
    !! @param[in] n_nodes Number of nodes
    !! @param[out] J Jacobian matrix (2, 2)
    !! @param[out] detJ Determinant of Jacobian
    !! @param[out] status Error status
    SUBROUTINE ET_Jacobian_2D(dN_dxi, coords, n_nodes, J, detJ, status)
        REAL(wp), INTENT(IN) :: dN_dxi(:,:)  ! (2, n_nodes)
        REAL(wp), INTENT(IN) :: coords(:,:)  ! (2, n_nodes)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: J(2, 2)
        REAL(wp), INTENT(OUT) :: detJ
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i

        CALL init_error_status(status)

        IF (SIZE(dN_dxi, 1) < 2 .OR. SIZE(dN_dxi, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_2D: Invalid dN_dxi dimensions'
            RETURN
        END IF

        IF (SIZE(coords, 1) < 2 .OR. SIZE(coords, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_2D: Invalid coords dimensions'
            RETURN
        END IF

        ! J = sum(dN_i/dxi * x_i)
        J = ZERO
        DO i = 1, n_nodes
            J(1, 1) = J(1, 1) + dN_dxi(1, i) * coords(1, i)  ! dx/dxi
            J(1, 2) = J(1, 2) + dN_dxi(1, i) * coords(2, i)  ! dy/dxi
            J(2, 1) = J(2, 1) + dN_dxi(2, i) * coords(1, i)  ! dx/deta
            J(2, 2) = J(2, 2) + dN_dxi(2, i) * coords(2, i)  ! dy/deta
        END DO

        ! Determinant
        detJ = J(1, 1) * J(2, 2) - J(1, 2) * J(2, 1)

        IF (ABS(detJ) < 1.0e-15_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_2D: Singular Jacobian'
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_Jacobian_2D

    !> @brief Compute 3D Jacobian matrix
    !! @param[in] dN_dxi Shape function derivatives w.r.t. natural coords (3, n_nodes)
    !! @param[in] coords Node coordinates (3, n_nodes)
    !! @param[in] n_nodes Number of nodes
    !! @param[out] J Jacobian matrix (3, 3)
    !! @param[out] detJ Determinant of Jacobian
    !! @param[out] status Error status
    SUBROUTINE ET_Jacobian_3D(dN_dxi, coords, n_nodes, J, detJ, status)
        REAL(wp), INTENT(IN) :: dN_dxi(:,:)  ! (3, n_nodes)
        REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, n_nodes)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: J(3, 3)
        REAL(wp), INTENT(OUT) :: detJ
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i

        CALL init_error_status(status)

        IF (SIZE(dN_dxi, 1) < 3 .OR. SIZE(dN_dxi, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_3D: Invalid dN_dxi dimensions'
            RETURN
        END IF

        IF (SIZE(coords, 1) < 3 .OR. SIZE(coords, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_3D: Invalid coords dimensions'
            RETURN
        END IF

        ! J = sum(dN_i/dxi * x_i)
        J = ZERO
        DO i = 1, n_nodes
            J(1, 1) = J(1, 1) + dN_dxi(1, i) * coords(1, i)  ! dx/dxi
            J(1, 2) = J(1, 2) + dN_dxi(1, i) * coords(2, i)  ! dy/dxi
            J(1, 3) = J(1, 3) + dN_dxi(1, i) * coords(3, i)  ! dz/dxi
            J(2, 1) = J(2, 1) + dN_dxi(2, i) * coords(1, i)  ! dx/deta
            J(2, 2) = J(2, 2) + dN_dxi(2, i) * coords(2, i)  ! dy/deta
            J(2, 3) = J(2, 3) + dN_dxi(2, i) * coords(3, i)  ! dz/deta
            J(3, 1) = J(3, 1) + dN_dxi(3, i) * coords(1, i)  ! dx/dzeta
            J(3, 2) = J(3, 2) + dN_dxi(3, i) * coords(2, i)  ! dy/dzeta
            J(3, 3) = J(3, 3) + dN_dxi(3, i) * coords(3, i)  ! dz/dzeta
        END DO

        ! Determinant using Sarrus' rule
        detJ = J(1, 1) * (J(2, 2) * J(3, 3) - J(2, 3) * J(3, 2)) - &
               J(1, 2) * (J(2, 1) * J(3, 3) - J(2, 3) * J(3, 1)) + &
               J(1, 3) * (J(2, 1) * J(3, 2) - J(2, 2) * J(3, 1))

        IF (ABS(detJ) < 1.0e-15_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_3D: Singular Jacobian'
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_Jacobian_3D

    !> @brief Compute 2D Jacobian determinant only
    !! @param[in] J Jacobian matrix (2, 2)
    !! @return Determinant
    FUNCTION ET_Jacobian_Det2D(J) RESULT(detJ)
        REAL(wp), INTENT(IN) :: J(2, 2)
        REAL(wp) :: detJ

        detJ = J(1, 1) * J(2, 2) - J(1, 2) * J(2, 1)
    END FUNCTION ET_Jacobian_Det2D

    !> @brief Compute 3D Jacobian determinant only
    !! @param[in] J Jacobian matrix (3, 3)
    !! @return Determinant
    FUNCTION ET_Jacobian_Det3D(J) RESULT(detJ)
        REAL(wp), INTENT(IN) :: J(3, 3)
        REAL(wp) :: detJ

        detJ = J(1, 1) * (J(2, 2) * J(3, 3) - J(2, 3) * J(3, 2)) - &
               J(1, 2) * (J(2, 1) * J(3, 3) - J(2, 3) * J(3, 1)) + &
               J(1, 3) * (J(2, 1) * J(3, 2) - J(2, 2) * J(3, 1))
    END FUNCTION ET_Jacobian_Det3D

    !> @brief Compute inverse of 2D Jacobian matrix
    !! @param[in] J Jacobian matrix (2, 2)
    !! @param[in] detJ Determinant of J
    !! @param[out] J_inv Inverse Jacobian (2, 2)
    !! @param[out] status Error status
    SUBROUTINE ET_Jacobian_Inverse2D(J, detJ, J_inv, status)
        REAL(wp), INTENT(IN) :: J(2, 2), detJ
        REAL(wp), INTENT(OUT) :: J_inv(2, 2)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (ABS(detJ) < 1.0e-15_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'ET_Jacobian_Inverse2D: Singular Jacobian'
            RETURN
        END IF

        ! J_inv = (1/detJ) * [J22, -J12; -J21, J11]
        J_inv(1, 1) = J(2, 2) / detJ
        J_inv(1, 2) = -J(1, 2) / detJ
        J_inv(2, 1) = -J(2, 1) / detJ
        J_inv(2, 2) = J(1, 1) / detJ

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_Jacobian_Inverse2D

    !> @brief Compute inverse of 3D Jacobian matrix
    !! @param[in] J Jacobian matrix (3, 3)
    !! @param[in] detJ Determinant of J
    !! @param[out] J_inv Inverse Jacobian (3, 3)
    !! @param[out] status Error status
    SUBROUTINE ET_Jacobian_Inverse3D(J, detJ, J_inv, status)
        REAL(wp), INTENT(IN) :: J(3, 3), detJ
        REAL(wp), INTENT(OUT) :: J_inv(3, 3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (ABS(detJ) < 1.0e-15_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'ET_Jacobian_Inverse3D: Singular Jacobian'
            RETURN
        END IF

        ! Compute cofactor matrix and transpose
        J_inv(1, 1) = (J(2, 2) * J(3, 3) - J(2, 3) * J(3, 2)) / detJ
        J_inv(1, 2) = -(J(1, 2) * J(3, 3) - J(1, 3) * J(3, 2)) / detJ
        J_inv(1, 3) = (J(1, 2) * J(2, 3) - J(1, 3) * J(2, 2)) / detJ

        J_inv(2, 1) = -(J(2, 1) * J(3, 3) - J(2, 3) * J(3, 1)) / detJ
        J_inv(2, 2) = (J(1, 1) * J(3, 3) - J(1, 3) * J(3, 1)) / detJ
        J_inv(2, 3) = -(J(1, 1) * J(2, 3) - J(1, 3) * J(2, 1)) / detJ

        J_inv(3, 1) = (J(2, 1) * J(3, 2) - J(2, 2) * J(3, 1)) / detJ
        J_inv(3, 2) = -(J(1, 1) * J(3, 2) - J(1, 2) * J(3, 1)) / detJ
        J_inv(3, 3) = (J(1, 1) * J(2, 2) - J(1, 2) * J(2, 1)) / detJ

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_Jacobian_Inverse3D

    !> @brief Transform shape function derivatives from natural to physical coordinates
    !! @param[in] dN_dxi Shape function derivatives w.r.t. natural coords (dim, n_nodes)
    !! @param[in] J_inv Inverse Jacobian matrix (dim, dim)
    !! @param[in] dim Spatial dimension (2 or 3)
    !! @param[in] n_nodes Number of nodes
    !! @param[out] dN_dx Shape function derivatives w.r.t. physical coords (dim, n_nodes)
    !! @param[out] status Error status
    SUBROUTINE ET_Jacobian_ShapeDerivatives(dN_dxi, J_inv, dim, n_nodes, dN_dx, status)
        REAL(wp), INTENT(IN) :: dN_dxi(:,:)  ! (dim, n_nodes)
        REAL(wp), INTENT(IN) :: J_inv(:,:)  ! (dim, dim)
        INTEGER(i4), INTENT(IN) :: dim, n_nodes
        REAL(wp), INTENT(OUT) :: dN_dx(:,:)  ! (dim, n_nodes)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, j, k

        CALL init_error_status(status)

        IF (dim < 2 .OR. dim > 3) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_ShapeDerivatives: Invalid dimension'
            RETURN
        END IF

        IF (SIZE(dN_dxi, 1) < dim .OR. SIZE(dN_dxi, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_ShapeDerivatives: Invalid dN_dxi dimensions'
            RETURN
        END IF

        IF (SIZE(J_inv, 1) < dim .OR. SIZE(J_inv, 2) < dim) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_ShapeDerivatives: Invalid J_inv dimensions'
            RETURN
        END IF

        IF (SIZE(dN_dx, 1) < dim .OR. SIZE(dN_dx, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_Jacobian_ShapeDerivatives: Invalid dN_dx dimensions'
            RETURN
        END IF

        ! dN/dx = J_inv * dN/dxi
        dN_dx = ZERO
        DO i = 1, n_nodes
            DO j = 1, dim
                DO k = 1, dim
                    dN_dx(j, i) = dN_dx(j, i) + J_inv(j, k) * dN_dxi(k, i)
                END DO
            END DO
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_Jacobian_ShapeDerivatives

END MODULE PH_Elem_Jacobian