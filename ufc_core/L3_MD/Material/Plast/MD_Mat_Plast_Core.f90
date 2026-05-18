!===============================================================================
! MODULE: MD_Mat_Plast_Core
! LAYER:  L3_MD
! DOMAIN: Material / Plast
! ROLE:   Core
! BRIEF:  Core implementation for plastic material family.
!         Provides initialization, validation, registration, and utility functions.
!         Follows the golden template from elastic material family.
!
!         Design principle:
!         - Single source of truth (SSOT) for plastic material definitions
!         - Three-level nesting validation
!         - ABAQUS keyword parsing and mapping
!         - Support for 12 plastic variants
!===============================================================================
MODULE MD_Mat_Plast_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Plast_Def, ONLY: MD_Mat_Plast_Desc, &
                               MD_Mat_Plast_State, &
                               MD_Mat_Plast_Algo, &
                               MD_Mat_Plast_Ctx, &
                               MD_Mat_Plast_Desc_Init, &
                               MD_Mat_Plast_Desc_Validate
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_PLASTIC, &
                                MD_MAT_PLAST_SUB_J2_ISO, &
                                MD_MAT_PLAST_SUB_KIN_LIN, &
                                MD_MAT_PLAST_SUB_KIN_COMB, &
                                MD_MAT_PLAST_SUB_HILL, &
                                MD_MAT_PLAST_SUB_JOHNSON_C, &
                                MD_MAT_PLAST_SUB_GTN
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Plast_Create_From_Props
  PUBLIC :: MD_Mat_Plast_Create_J2_Isotropic
  PUBLIC :: MD_Mat_Plast_Create_Hill
  PUBLIC :: MD_Mat_Plast_Create_Johnson_Cook
  PUBLIC :: MD_Mat_Plast_Parse_ABAQUS_Keyword
  PUBLIC :: MD_Mat_Plast_Register

  !-----------------------------------------------------------------------------
  ! Material registry - REMOVED (Week 2 Day 1)
  ! Now using unified MD_Mat_Registry module
  !-----------------------------------------------------------------------------

CONTAINS

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Create_From_Props
  ! Create plastic material descriptor from flat props array
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Create_From_Props(desc, sub_type, nprops, props, &
                                             E, nu, dependencies, status)
    TYPE(MD_Mat_Plast_Desc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    REAL(wp), INTENT(IN) :: E, nu
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, deps
    REAL(wp) :: one, two, three

    CALL init_error_status(status)
    one = 1.0_wp
    two = 2.0_wp
    three = 3.0_wp

    ! Determine dependencies
    deps = 0
    IF (PRESENT(dependencies)) deps = dependencies

    ! Initialize descriptor
    CALL MD_Mat_Plast_Desc_Init(desc, sub_type, nprops, deps, status)
    IF (status%status_code /= 0) RETURN

    ! Set elastic properties
    desc%E = E
    desc%nu = nu
    desc%G = E / (two * (one + nu))
    desc%K = E / (three * (one - two * nu))

    ! Copy material constants
    DO i = 1, nprops
      desc%constants(i, 1) = props(i)
    END DO

    ! Extract yield stress (first constant for most models)
    IF (nprops >= 1) THEN
      desc%sigma_y = props(1)
    END IF

    ! Sub-type specific initialization
    SELECT CASE (sub_type)
    CASE (MD_MAT_PLAST_SUB_J2_ISO)
      ! J2 isotropic: sigma_y, H_iso
      IF (nprops >= 2) desc%H_iso = props(2)
      desc%hardening_type = 1  ! Isotropic

    CASE (MD_MAT_PLAST_SUB_KIN_LIN)
      ! Kinematic linear: sigma_y, H_kin
      IF (nprops >= 2) desc%H_kin = props(2)
      desc%hardening_type = 2  ! Kinematic

    CASE (MD_MAT_PLAST_SUB_KIN_COMB)
      ! Combined: sigma_y, H_iso, H_kin
      IF (nprops >= 2) desc%H_iso = props(2)
      IF (nprops >= 3) desc%H_kin = props(3)
      desc%hardening_type = 3  ! Combined

    CASE (MD_MAT_PLAST_SUB_HILL)
      ! Hill: sigma_y, F, G, H, L, M, N
      IF (nprops >= 7) THEN
        desc%F_hill = props(2)
        desc%G_hill = props(3)
        desc%H_hill = props(4)
        desc%L_hill = props(5)
        desc%M_hill = props(6)
        desc%N_hill = props(7)
      END IF

    CASE (MD_MAT_PLAST_SUB_JOHNSON_C)
      ! Johnson-Cook: A, B, n, C, m
      IF (nprops >= 5) THEN
        desc%A_jc = props(1)
        desc%B_jc = props(2)
        desc%n_jc = props(3)
        desc%C_jc = props(4)
        desc%m_jc = props(5)
      END IF

    CASE (MD_MAT_PLAST_SUB_GTN)
      ! GTN: sigma_y, q1, q2, q3, f0, fc, ff
      IF (nprops >= 7) THEN
        desc%q1_gtn = props(2)
        desc%q2_gtn = props(3)
        desc%q3_gtn = props(4)
        desc%f0_gtn = props(5)
        desc%fc_gtn = props(6)
        desc%ff_gtn = props(7)
      END IF
    END SELECT

    ! Validate
    CALL MD_Mat_Plast_Desc_Validate(desc, status)
  END SUBROUTINE MD_Mat_Plast_Create_From_Props

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Create_J2_Isotropic
  ! Convenience function for creating J2 isotropic plastic material
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Create_J2_Isotropic(desc, E, nu, sigma_y, H_iso, status)
    TYPE(MD_Mat_Plast_Desc), INTENT(OUT) :: desc
    REAL(wp), INTENT(IN) :: E, nu, sigma_y, H_iso
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: props(2)

    props(1) = sigma_y
    props(2) = H_iso

    CALL MD_Mat_Plast_Create_From_Props(desc, MD_MAT_PLAST_SUB_J2_ISO, 2, props, &
                                        E, nu, status=status)
  END SUBROUTINE MD_Mat_Plast_Create_J2_Isotropic

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Create_Hill
  ! Convenience function for creating Hill anisotropic plastic material
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Create_Hill(desc, E, nu, sigma_y, &
                                       F_hill, G_hill, H_hill, &
                                       L_hill, M_hill, N_hill, status)
    TYPE(MD_Mat_Plast_Desc), INTENT(OUT) :: desc
    REAL(wp), INTENT(IN) :: E, nu, sigma_y
    REAL(wp), INTENT(IN) :: F_hill, G_hill, H_hill, L_hill, M_hill, N_hill
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: props(7)

    props(1) = sigma_y
    props(2) = F_hill
    props(3) = G_hill
    props(4) = H_hill
    props(5) = L_hill
    props(6) = M_hill
    props(7) = N_hill

    CALL MD_Mat_Plast_Create_From_Props(desc, MD_MAT_PLAST_SUB_HILL, 7, props, &
                                        E, nu, status=status)
  END SUBROUTINE MD_Mat_Plast_Create_Hill

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Create_Johnson_Cook
  ! Convenience function for creating Johnson-Cook plastic material
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Create_Johnson_Cook(desc, E, nu, A, B, n, C, m, status)
    TYPE(MD_Mat_Plast_Desc), INTENT(OUT) :: desc
    REAL(wp), INTENT(IN) :: E, nu, A, B, n, C, m
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: props(5)

    props(1) = A
    props(2) = B
    props(3) = n
    props(4) = C
    props(5) = m

    CALL MD_Mat_Plast_Create_From_Props(desc, MD_MAT_PLAST_SUB_JOHNSON_C, 5, props, &
                                        E, nu, status=status)
  END SUBROUTINE MD_Mat_Plast_Create_Johnson_Cook

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Parse_ABAQUS_Keyword
  ! Parse ABAQUS *PLASTIC keyword and create material descriptor
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Parse_ABAQUS_Keyword(desc, hardening_type, &
                                                nprops, props, E, nu, &
                                                dependencies, status)
    TYPE(MD_Mat_Plast_Desc), INTENT(OUT) :: desc
    CHARACTER(LEN=*), INTENT(IN) :: hardening_type  ! "ISOTROPIC", "KINEMATIC", etc.
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    REAL(wp), INTENT(IN) :: E, nu
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: sub_type

    CALL init_error_status(status)

    ! Map ABAQUS keyword HARDENING parameter to sub_type
    SELECT CASE (TRIM(hardening_type))
    CASE ("ISOTROPIC", "ISO")
      sub_type = MD_MAT_PLAST_SUB_J2_ISO
    CASE ("KINEMATIC", "KIN")
      sub_type = MD_MAT_PLAST_SUB_KIN_LIN
    CASE ("COMBINED", "COMB")
      sub_type = MD_MAT_PLAST_SUB_KIN_COMB
    CASE ("JOHNSON-COOK", "JC")
      sub_type = MD_MAT_PLAST_SUB_JOHNSON_C
    CASE ("USER")
      sub_type = MD_MAT_PLAST_SUB_J2_ISO  ! Default to J2
    CASE DEFAULT
      status%status_code = 1
      status%message = "Unknown ABAQUS plastic HARDENING: " // TRIM(hardening_type)
      RETURN
    END SELECT

    ! Create material descriptor
    CALL MD_Mat_Plast_Create_From_Props(desc, sub_type, nprops, props, &
                                        E, nu, dependencies, status)
  END SUBROUTINE MD_Mat_Plast_Parse_ABAQUS_Keyword

  !-----------------------------------------------------------------------------
  ! MD_Mat_Plast_Register
  ! Register a plastic material in the global registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Plast_Register(desc, mat_id, status)
    ! UPDATED (Week 2 Day 1): Now uses unified MD_Mat_Registry
    USE MD_Mat_Registry, ONLY: MD_Mat_Registry_Register

    TYPE(MD_Mat_Plast_Desc), INTENT(IN) :: desc
    INTEGER(i4), INTENT(OUT) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Register material using unified registry
    CALL MD_Mat_Registry_Register(mat_id, MD_MAT_FAMILY_PLASTIC, &
                                   desc%sub_type, desc, status)
  END SUBROUTINE MD_Mat_Plast_Register

END MODULE MD_Mat_Plast_Core
