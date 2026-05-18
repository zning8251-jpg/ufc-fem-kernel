!===============================================================================
! MODULE: PH_Elem_Utils
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Quality, volume, Jacobian utilities (Shared Tool)
!===============================================================================
MODULE PH_Elem_Utils
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
    USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: PH_Elem_ComputeVolume
    PUBLIC :: PH_Elem_ComputeJacobian
    PUBLIC :: PH_Elem_CheckQuality
    PUBLIC :: PH_Elem_GetAspectRatio
    PUBLIC :: PH_Elem_GetSkewness
    PUBLIC :: PH_Elem_GetDistortion
    ! Extended API (task7900-7999)
    PUBLIC :: PH_Elem_ComputeVolumeExtended
    PUBLIC :: PH_Elem_ComputeMass
    PUBLIC :: PH_Elem_CheckMassConservation
    PUBLIC :: PH_Elem_GetVolumeQuality

    !==========================================================================
    ! INTF-001
    ! Purpose: PH_El_CheckMassConservation(8 ) /
    ! PH_Elem_ComputeMass(5 ) / PH_Elem_ComputeJacobian(5 )
    ! Theory: ρ₀V₀ = ρV Lagrange = |ρV - ρ₀V₀|/ρ₀V₀
    ! Status: Draft |
    !==========================================================================
    PUBLIC :: PH_ElemQualityArgs

    TYPE :: PH_ElemQualityArgs
      ! ---- POINTER ----
      REAL(wp), POINTER :: coords_old(:,:) => NULL()  !! (dim,nnode)
      REAL(wp), POINTER :: coords_new(:,:) => NULL()  !! (dim,nnode)
      REAL(wp), POINTER :: coords(:,:)     => NULL()  !! (dim,nnode)

      ! ---- ----
      INTEGER(i4) :: n_gauss = 2_i4  ! Gauss point count

      ! ---- ----
      REAL(wp) :: density_old = 0.0_wp  !! ρ₀
      REAL(wp) :: density_new = 0.0_wp  !! ρ

      ! ---- ----
      REAL(wp) :: volume     = 0.0_wp  ! element volume (integrated)
      REAL(wp) :: mass       = 0.0_wp  ! element mass
      REAL(wp) :: mass_error = 0.0_wp  ! mass-balance error metric

      ! ---- ----
      LOGICAL  :: mass_conserved = .FALSE.! mass conservation flag
      REAL(wp) :: aspect_ratio   = 0.0_wp  ! element aspect ratio metric
      REAL(wp) :: skewness       = 0.0_wp  ! element skewness metric
      REAL(wp) :: distortion     = 0.0_wp  ! element distortion metric

      ! ---- Jacobian ----
      REAL(wp), POINTER :: jacobian(:,:)   => NULL()  !! Jacobian
      REAL(wp)           :: jacobian_det   = 0.0_wp   !! Jacobian

      ! ---- ----
      TYPE(ErrorStatusType), POINTER :: status => NULL()  ! error status ptr (IF_Err)
    END TYPE PH_ElemQualityArgs

CONTAINS

    SUBROUTINE PH_El_CheckMassConservation(coords_old, coords_new, &
                                             density_old, density_new, &
                                             n_gauss, mass_conserved, &
                                             mass_error, status)
        REAL(wp), INTENT(IN) :: coords_old(:,:), coords_new(:,:)
        REAL(wp), INTENT(IN) :: density_old, density_new
        INTEGER(i4), INTENT(IN) :: n_gauss
        LOGICAL, INTENT(OUT) :: mass_conserved
        REAL(wp), INTENT(OUT), OPTIONAL :: mass_error
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: volume_old, volume_new, mass_old, mass_new
        REAL(wp) :: error

        CALL init_error_status(status)

        ! Compute volumes
        CALL PH_Elem_ComputeVolume(coords_old, n_gauss, volume_old, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            mass_conserved = .FALSE.
            IF (PRESENT(mass_error)) mass_error = HUGE(ONE)
            RETURN
        END IF

        CALL PH_Elem_ComputeVolume(coords_new, n_gauss, volume_new, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            mass_conserved = .FALSE.
            IF (PRESENT(mass_error)) mass_error = HUGE(ONE)
            RETURN
        END IF

        ! Compute masses
        mass_old = density_old * volume_old
        mass_new = density_new * volume_new

        ! Check conservation
        error = ABS(mass_new - mass_old) / MAX(ABS(mass_old), 1.0e-12_wp)
        mass_conserved = (error < 1.0e-6_wp)

        IF (PRESENT(mass_error)) mass_error = error

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_CheckMassConservation

    SUBROUTINE PH_El_ComputeVolumeExtended(coords, n_gauss, volume, &
                                              volume_quality, status)
        REAL(wp), INTENT(IN) :: coords(:,:)
        INTEGER(i4), INTENT(IN) :: n_gauss
        REAL(wp), INTENT(OUT) :: volume
        REAL(wp), INTENT(OUT), OPTIONAL :: volume_quality
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: distortion

        CALL init_error_status(status)

        ! Compute volume
        CALL PH_Elem_ComputeVolume(coords, n_gauss, volume, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Compute volume quality if requested
        IF (PRESENT(volume_quality)) THEN
            distortion = PH_Elem_GetDistortion(coords, status)
            IF (status%status_code == IF_STATUS_OK) THEN
                volume_quality = distortion
            ELSE
                volume_quality = ZERO
            END IF
        END IF

    END SUBROUTINE PH_Elem_ComputeVolumeExtended

    SUBROUTINE PH_Elem_CheckQuality(coords, quality_metrics, is_good, status)
        REAL(wp), INTENT(IN) :: coords(:,:)
        REAL(wp), INTENT(OUT) :: quality_metrics(3)
        LOGICAL, INTENT(OUT) :: is_good
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: aspect_ratio, skewness, distortion

        CALL init_error_status(status)

        ! Compute quality metrics
        aspect_ratio = PH_Elem_GetAspectRatio(coords, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        skewness = PH_Elem_GetSkewness(coords, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        distortion = PH_Elem_GetDistortion(coords, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        quality_metrics(1) = aspect_ratio
        quality_metrics(2) = skewness
        quality_metrics(3) = distortion

        ! Quality criteria (thresholds can be adjusted)
        is_good = (aspect_ratio < 10.0_wp) .AND. &
                 (skewness < 0.5_wp) .AND. &
                 (distortion > 0.1_wp)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Elem_CheckQuality

    SUBROUTINE PH_Elem_ComputeJacobian(coords, dN_dxi, jacobian, jacobian_det, status)
        ! > [Theory] Jacobian J=∂x/∂�?Σ(dN_i/dξ)·x_i J nDim×nDim det(J)>0
        ! > [Logic] (m,k) J(m,k)=Σ_i dN_i/dξ_m * x_k(i) �?det(J) �?det>0
        ! > [Compute] jacobian(m,k)=matmul(dN_dxi,coords^T); jacobian_det=det3x3(jacobian); det�? IF_STATUS_INVALID
        ! > [Data chain] coords(nDim,nNodes), dN_dxi(nDim,nNodes) �?jacobian(nDim,nDim), jacobian_det;
        REAL(wp), INTENT(IN) :: coords(:,:), dN_dxi(:,:)
        REAL(wp), INTENT(OUT) :: jacobian(:,:), jacobian_det
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: n_nodes, n_dim, i, j, k

        CALL init_error_status(status)

        n_nodes = SIZE(coords, 1)
        n_dim = SIZE(coords, 2)

        IF (SIZE(dN_dxi, 1) /= n_nodes .OR. SIZE(jacobian, 1) /= n_dim .OR. &
            SIZE(jacobian, 2) /= n_dim) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_ComputeJacobian: Dimension mismatch'
            RETURN
        END IF

        ! Jacobian: J = âx/âï¿½?= Î£ (x_i Â· âN_i/âï¿½?
        jacobian = ZERO
        DO i = 1, n_dim
            DO j = 1, n_dim
                DO k = 1, n_nodes
                    jacobian(i,j) = jacobian(i,j) + coords(k,i) * dN_dxi(k,j)
                END DO
            END DO
        END DO

        ! Compute determinant
        IF (n_dim == 2) THEN
            jacobian_det = jacobian(1,1) * jacobian(2,2) - jacobian(1,2) * jacobian(2,1)
        ELSE IF (n_dim == 3) THEN
            jacobian_det = jacobian(1,1) * (jacobian(2,2) * jacobian(3,3) - &
                                           jacobian(2,3) * jacobian(3,2)) - &
                          jacobian(1,2) * (jacobian(2,1) * jacobian(3,3) - &
                                           jacobian(2,3) * jacobian(3,1)) + &
                          jacobian(1,3) * (jacobian(2,1) * jacobian(3,2) - &
                                           jacobian(2,2) * jacobian(3,1))
        ELSE
            jacobian_det = ZERO
        END IF

        IF (jacobian_det <= ZERO) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_ComputeJacobian: Negative or zero Jacobian determinant'
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Elem_ComputeJacobian

    SUBROUTINE PH_Elem_ComputeMass(coords, density, n_gauss, mass, status)
        REAL(wp), INTENT(IN) :: coords(:,:)
        REAL(wp), INTENT(IN) :: density
        INTEGER(i4), INTENT(IN) :: n_gauss
        REAL(wp), INTENT(OUT) :: mass
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: volume

        CALL init_error_status(status)

        ! Compute volume
        CALL PH_Elem_ComputeVolume(coords, n_gauss, volume, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            mass = ZERO
            RETURN
        END IF

        ! Mass = density * volume
        mass = density * volume

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_ComputeMass

    SUBROUTINE PH_Elem_ComputeVolume(coords, n_gauss, volume, status)
        ! > [Theory] V=∫dΩ≈Σ_GP det(J(ξ_gp))·w_gp
        ! > [Logic] �?/ �?J(ξ_gp) detJ �?
        ! > [Compute] volume=0; DO gp=1,n_gauss: detJ=det(J(ξ_gp)); volume+=detJ*w_gp; END DO; GetCornerIndices3D
        ! > [Data chain] coords(nDim,nNodes), n_gauss �?volume( ); PH_Elem_GetCornerIndices3D
        REAL(wp), INTENT(IN) :: coords(:,:)
        INTEGER(i4), INTENT(IN) :: n_gauss
        REAL(wp), INTENT(OUT) :: volume
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: n_nodes, n_dim, i, n_corner
        INTEGER(i4), ALLOCATABLE :: corner_ids(:)
        REAL(wp) :: jacobian_det, sum_vol

        CALL init_error_status(status)

        n_nodes = SIZE(coords, 1)
        n_dim = SIZE(coords, 2)

        IF (n_dim < 2 .OR. n_dim > 3) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_ComputeVolume: Invalid dimension'
            RETURN
        END IF

        ! Robust volume/area calculation based on corner nodes
        IF (n_dim == 2) THEN
            CALL PH_Elem_GetCornerIndices2D(n_nodes, corner_ids, n_corner, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                volume = ZERO
                RETURN
            END IF
            volume = PH_Elem_ComputePolygonArea2D(coords, corner_ids, n_corner)
            DEALLOCATE(corner_ids)
        ELSE
            CALL PH_Elem_GetCornerIndices3D(n_nodes, corner_ids, n_corner, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                volume = ZERO
                RETURN
            END IF
            SELECT CASE (n_corner)
            CASE (4)
                volume = PH_Elem_ComputeTetraVolume(coords, corner_ids)
            CASE (5)
                volume = PH_Elem_ComputePyramidVolume(coords, corner_ids)
            CASE (6)
                volume = PH_Elem_ComputeWedgeVolume(coords, corner_ids)
            CASE (8)
                volume = PH_Elem_ComputeHexVolume(coords, corner_ids)
            CASE DEFAULT
                volume = PH_Elem_ComputeBoundingBoxVolume(coords, n_corner)
            END SELECT
            DEALLOCATE(corner_ids)
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Elem_ComputeVolume

    SUBROUTINE PH_Elem_GetCornerIndices2D(n_nodes, corner_ids, n_corner, status)
        INTEGER(i4), INTENT(IN) :: n_nodes
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: corner_ids(:)
        INTEGER(i4), INTENT(OUT) :: n_corner
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        SELECT CASE (n_nodes)
        CASE (3, 6, 7)
            n_corner = 3
            ALLOCATE(corner_ids(3))
            corner_ids = [1, 2, 3]
        CASE (4, 8, 9)
            n_corner = 4
            ALLOCATE(corner_ids(4))
            corner_ids = [1, 2, 3, 4]
        CASE DEFAULT
            IF (n_nodes >= 4) THEN
                n_corner = 4
                ALLOCATE(corner_ids(4))
                corner_ids = [1, 2, 3, 4]
            ELSE
                status%status_code = IF_STATUS_INVALID
                status%message = 'PH_Elem_GetCornerIndices2D: Unsupported node count'
                RETURN
            END IF
        END SELECT
        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Elem_GetCornerIndices2D

    SUBROUTINE PH_Elem_GetCornerIndices3D(n_nodes, corner_ids, n_corner, status)
        INTEGER(i4), INTENT(IN) :: n_nodes
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: corner_ids(:)
        INTEGER(i4), INTENT(OUT) :: n_corner
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        SELECT CASE (n_nodes)
        CASE (4, 10)
            n_corner = 4
            ALLOCATE(corner_ids(4))
            corner_ids = [1, 2, 3, 4]
        CASE (5)
            n_corner = 5
            ALLOCATE(corner_ids(5))
            corner_ids = [1, 2, 3, 4, 5]
        CASE (6, 15)
            n_corner = 6
            ALLOCATE(corner_ids(6))
            corner_ids = [1, 2, 3, 4, 5, 6]
        CASE (8, 20, 27)
            n_corner = 8
            ALLOCATE(corner_ids(8))
            corner_ids = [1, 2, 3, 4, 5, 6, 7, 8]
        CASE DEFAULT
            IF (n_nodes >= 8) THEN
                n_corner = 8
                ALLOCATE(corner_ids(8))
                corner_ids = [1, 2, 3, 4, 5, 6, 7, 8]
            ELSE
                status%status_code = IF_STATUS_INVALID
                status%message = 'PH_Elem_GetCornerIndices3D: Unsupported node count'
                RETURN
            END IF
        END SELECT
        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Elem_GetCornerIndices3D
END MODULE PH_Elem_Utils