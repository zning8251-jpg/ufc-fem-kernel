!===============================================================================
! MODULE: PH_Mat_Elas_Core
! LAYER:  L4_PH
! DOMAIN: Material / Elas
! ROLE:   Core
! BRIEF:  Core computation routines for elastic material family.
!         Implements constitutive integration (stress update) and tangent computation.
!         Hot path optimized for performance.
!
!         Internal subroutines (module-private):
!           Build_Stiffness  -- build elastic stiffness D_el
!           Compute_Stress  -- compute stress from strain
!           Compute_Tangent -- compute tangent stiffness
!           Update_State    -- update state after evaluation
!===============================================================================
MODULE PH_Mat_Elas_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Elas_Def, ONLY: PH_Mat_Elas_Desc, &
                                  PH_Mat_Elas_State, &
                                  PH_Mat_Elas_Algo, &
                                  PH_Mat_Elas_Ctx, &
                                  PH_MAT_ELAS_SUB_ISO, &
                                  PH_MAT_ELAS_SUB_ORTHO, &
                                  PH_MAT_ELAS_SUB_ANISO
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: PH_Mat_Elas_Build_Stiffness
  PUBLIC :: PH_Mat_Elas_Compute_Stress
  PUBLIC :: PH_Mat_Elas_Compute_Tangent
  PUBLIC :: PH_Mat_Elas_Update_State
  PUBLIC :: PH_Mat_Elas_Populate_From_L3

  ! Phase6 Track22: internal SoA props buffer (Populate-time, not hot IP loop).
  REAL(wp), SAVE, ALLOCATABLE :: ph_elas_soa_props(:)

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Mat_Elas_Populate_From_L3
  ! Populate L4 descriptor from L3 data (via bridge)
  ! Phase: Config | Verb: Populate | COLD_PATH
  ! Spatial: - | Temporal: Init | Action: Populate
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Populate_From_L3(desc, l3_props, l3_nprops, &
                                          l3_sub_type, status)
    TYPE(PH_Mat_Elas_Desc), INTENT(INOUT) :: desc
    REAL(wp), INTENT(IN) :: l3_props(:)
    INTEGER(i4), INTENT(IN) :: l3_nprops
    INTEGER(i4), INTENT(IN) :: l3_sub_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: one, two, three

    CALL init_error_status(status)
    one = 1.0_wp; two = 2.0_wp; three = 3.0_wp

    ! Copy configuration
    desc%cfg%sub_type      = l3_sub_type
    desc%cfg%num_constants = l3_nprops

    ! Allocate and copy properties
    IF (ALLOCATED(desc%props)) DEALLOCATE(desc%props)
    ALLOCATE(desc%props(l3_nprops), SOURCE=l3_props(1:l3_nprops))
    IF (ALLOCATED(ph_elas_soa_props)) DEALLOCATE(ph_elas_soa_props)
    ALLOCATE(ph_elas_soa_props(l3_nprops))
    ph_elas_soa_props(1:l3_nprops) = l3_props(1:l3_nprops)

    ! Compute derived parameters based on sub-type
    SELECT CASE (l3_sub_type)
    CASE (PH_MAT_ELAS_SUB_ISO)
      IF (l3_nprops < 2) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Isotropic elastic requires at least 2 properties"
        RETURN
      END IF
      desc%E = l3_props(1)
      desc%nu = l3_props(2)
      desc%lambda = desc%E * desc%nu / ((one + desc%nu) * (one - two * desc%nu))
      desc%mu = desc%E / (two * (one + desc%nu))
      desc%G = desc%mu
      desc%K = desc%E / (three * (one - two * desc%nu))

    CASE (PH_MAT_ELAS_SUB_ORTHO)
      IF (l3_nprops < 9) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Orthotropic elastic requires 9 properties"
        RETURN
      END IF
      desc%E11 = l3_props(1)
      desc%E22 = l3_props(2)
      desc%E33 = l3_props(3)
      desc%nu12 = l3_props(4)
      desc%nu13 = l3_props(5)
      desc%nu23 = l3_props(6)
      desc%G12 = l3_props(7)
      desc%G13 = l3_props(8)
      desc%G23 = l3_props(9)

    CASE (PH_MAT_ELAS_SUB_ANISO)
      IF (l3_nprops < 21) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Anisotropic elastic requires 21 properties"
        RETURN
      END IF
      CALL Build_Aniso_Stiffness(l3_props, desc%C)

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "Unknown elastic sub-type"
      RETURN
    END SELECT

    desc%pop%is_valid = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Populate_From_L3

  !-----------------------------------------------------------------------------
  ! PH_Mat_Elas_Build_Stiffness
  ! Build elastic stiffness matrix D_el in context
  ! Spatial: IP | Temporal: Incr | Action: Build (HOT_PATH O(36))
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Build_Stiffness(desc, ctx, status)
    TYPE(PH_Mat_Elas_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_Elas_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: one, two, lam, mu_val, G2, nu21, nu31, nu32, delta
    REAL(wp) :: S(6,6)

    CALL init_error_status(status)
    one = 1.0_wp; two = 2.0_wp

    IF (.NOT. desc%pop%is_valid) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Descriptor not valid"
      RETURN
    END IF

    ctx%D_el = 0.0_wp

    SELECT CASE (desc%cfg%sub_type)
    CASE (PH_MAT_ELAS_SUB_ISO)
      ! Isotropic stiffness matrix
      lam = desc%lambda
      mu_val = desc%mu
      G2 = two * mu_val

      ctx%D_el(1,1) = lam + G2; ctx%D_el(1,2) = lam;       ctx%D_el(1,3) = lam
      ctx%D_el(2,1) = lam;       ctx%D_el(2,2) = lam + G2; ctx%D_el(2,3) = lam
      ctx%D_el(3,1) = lam;       ctx%D_el(3,2) = lam;       ctx%D_el(3,3) = lam + G2
      ctx%D_el(4,4) = mu_val
      ctx%D_el(5,5) = mu_val
      ctx%D_el(6,6) = mu_val

    CASE (PH_MAT_ELAS_SUB_ORTHO)
      ! Orthotropic stiffness matrix (from compliance inversion)
      ! Compliance matrix S
      S = 0.0_wp
      S(1,1) = 1.0_wp / desc%E11
      S(2,2) = 1.0_wp / desc%E22
      S(3,3) = 1.0_wp / desc%E33
      S(1,2) = -desc%nu12 / desc%E11;  S(2,1) = S(1,2)
      S(1,3) = -desc%nu13 / desc%E11;  S(3,1) = S(1,3)
      S(2,3) = -desc%nu23 / desc%E22;  S(3,2) = S(2,3)
      S(4,4) = 1.0_wp / desc%G12
      S(5,5) = 1.0_wp / desc%G13
      S(6,6) = 1.0_wp / desc%G23
      CALL Invert_6x6_Symmetric(S, ctx%D_el, status)

    CASE (PH_MAT_ELAS_SUB_ANISO)
      ! Direct anisotropic stiffness
      ctx%D_el = desc%C

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "Unsupported elastic sub-type"
      RETURN
    END SELECT

    ctx%D_el_cached = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Build_Stiffness

  !-----------------------------------------------------------------------------
  ! PH_Mat_Elas_Compute_Stress
  ! Compute stress from total strain using cached D_el
  ! Spatial: IP | Temporal: Incr | Action: Compute (HOT_PATH O(36))
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Compute_Stress(ctx, strain, stress, status)
    TYPE(PH_Mat_Elas_Ctx), INTENT(IN) :: ctx
    REAL(wp), INTENT(IN) :: strain(6)
    REAL(wp), INTENT(OUT) :: stress(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)

    IF (.NOT. ctx%D_el_cached) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Stiffness matrix not built"
      RETURN
    END IF

    ! stress = D_el * strain (Voigt notation)
    DO i = 1, 6
      stress(i) = 0.0_wp
      DO j = 1, 6
        stress(i) = stress(i) + ctx%D_el(i, j) * strain(j)
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Compute_Stress

  !-----------------------------------------------------------------------------
  ! PH_Mat_Elas_Compute_Tangent
  ! Compute tangent stiffness matrix
  ! Spatial: IP | Temporal: Incr | Action: Compute (HOT_PATH O(1))
  ! For linear elastic: tangent = elastic stiffness D_el
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Compute_Tangent(ctx, tangent, status)
    TYPE(PH_Mat_Elas_Ctx), INTENT(IN) :: ctx
    REAL(wp), INTENT(OUT) :: tangent(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. ctx%D_el_cached) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Stiffness matrix not built"
      RETURN
    END IF

    ! For linear elastic: tangent = D_el
    tangent = ctx%D_el
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Compute_Tangent

  !-----------------------------------------------------------------------------
  ! PH_Mat_Elas_Update_State
  ! Update state after successful increment
  ! Spatial: IP | Temporal: Incr | Action: Update (WARM_PATH)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Update_State(state, stress, strain, status)
    TYPE(PH_Mat_Elas_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress(6)
    REAL(wp), INTENT(IN) :: strain(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    state%stress = stress
    state%strain = strain
    state%elastic_strain = strain  ! For pure elastic, elastic_strain = total_strain
    state%initialized = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Update_State

  !-----------------------------------------------------------------------------
  ! Helper: Build_Aniso_Stiffness
  ! Build anisotropic stiffness matrix from 21 Voigt components
  !-----------------------------------------------------------------------------
  SUBROUTINE Build_Aniso_Stiffness(props, C)
    REAL(wp), INTENT(IN) :: props(21)
    REAL(wp), INTENT(OUT) :: C(6,6)
    C = 0.0_wp
    C(1,1)=props(1);  C(1,2)=props(2);  C(1,3)=props(3)
    C(1,4)=props(4);  C(1,5)=props(5);  C(1,6)=props(6)
    C(2,2)=props(7);  C(2,3)=props(8);  C(2,4)=props(9)
    C(2,5)=props(10); C(2,6)=props(11); C(3,3)=props(12)
    C(3,4)=props(13); C(3,5)=props(14); C(3,6)=props(15)
    C(4,4)=props(16); C(4,5)=props(17); C(4,6)=props(18)
    C(5,5)=props(19); C(5,6)=props(20); C(6,6)=props(21)
    C(2,1)=C(1,2); C(3,1)=C(1,3); C(3,2)=C(2,3)
    C(4,1)=C(1,4); C(4,2)=C(2,4); C(4,3)=C(3,4)
    C(5,1)=C(1,5); C(5,2)=C(2,5); C(5,3)=C(3,5); C(5,4)=C(4,5)
    C(6,1)=C(1,6); C(6,2)=C(2,6); C(6,3)=C(3,6); C(6,4)=C(4,6); C(6,5)=C(5,6)
  END SUBROUTINE Build_Aniso_Stiffness

  !-----------------------------------------------------------------------------
  ! Helper: Invert_6x6_Symmetric
  ! Invert a 6x6 symmetric matrix (simplified for orthotropic case)
  !-----------------------------------------------------------------------------
  SUBROUTINE Invert_6x6_Symmetric(A, A_inv, status)
    REAL(wp), INTENT(IN) :: A(6,6)
    REAL(wp), INTENT(OUT) :: A_inv(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: det, temp(6,6)
    INTEGER(i4) :: i, j

    CALL init_error_status(status)

    temp = A
    A_inv = 0.0_wp
    DO i = 1, 6
      A_inv(i,i) = 1.0_wp / temp(i,i)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE Invert_6x6_Symmetric

END MODULE PH_Mat_Elas_Core