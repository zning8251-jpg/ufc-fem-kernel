!===============================================================================
! MODULE: PH_Mat_UMAT_Brg
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Brg
! BRIEF:  Enhanced UMAT bridge — parameter validation, dispatch, error handling.
!===============================================================================

MODULE PH_Mat_UMAT_Brg
!> [BRIDGE] Enhanced UMAT interface
!> Theory: UMAT bridge with parameter validation, error handling, material classification
!> Status: Production | Last verified: 2026-02-28

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp
  USE ISO_C_BINDING
  USE MD_Mat_Lib, ONLY: MatPropertyDef, MAT_ID_VONMISES, MAT_ID_NEOHOOKEAN, MAT_ID_PRONY
  USE PH_Elem_MaterialDispatch, ONLY: PH_UpdateStress, PH_GetTangent
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  IMPLICIT NONE
  PRIVATE

  ! ==================== public interface ====================
  PUBLIC :: PH_UMAT_Call_Enhanced
  PUBLIC :: PH_UMAT_ValidateProps
  PUBLIC :: PH_UMAT_AllocateStateVars
  PUBLIC :: PH_UMAT_RetrieveMaterialClass

  ! ==================== parameter ====================
  INTEGER(i4), PARAMETER :: PH_MAT_MAX_PROPS = 100
  INTEGER(i4), PARAMETER :: PH_MAT_UMAT_VONMISES = 1
  INTEGER(i4), PARAMETER :: PH_MAT_UMAT_NEOHOOKEAN = 2
  INTEGER(i4), PARAMETER :: PH_MAT_UMAT_PRONY = 3

  ! ==================== material type recognition ====================
  TYPE, PUBLIC :: PH_MAT_UMAT_MaterialClassifier
    INTEGER(i4) :: material_id  ! Material ID: 1=VonMises, 2=NeoHookean, 3=Prony
    CHARACTER(LEN=50) :: mat_name  ! Material name
    INTEGER(i4) :: nprops_expected  ! Expected parameter count
    INTEGER(i4) :: nstatv_expected  ! Expected state variable count
  END TYPE PH_MAT_UMAT_MaterialClassifier

CONTAINS

  SUBROUTINE PH_UMAT_AllocateStateVars(mat_classifier, statev, nstatv, err_stat)

    IMPLICIT NONE

    TYPE(PH_MAT_UMAT_MaterialClassifier), INTENT(IN) :: mat_classifier
    REAL(wp), INTENT(OUT), ALLOCATABLE :: statev(:)
    INTEGER(i4), INTENT(OUT) :: nstatv
    INTEGER(i4), INTENT(OUT) :: err_stat

    err_stat = 0
    nstatv = mat_classifier%nstatv_expected

    IF (nstatv <= 0) THEN
      PRINT *, "ERROR: Invalid state variable count:", nstatv
      err_stat = 1
      RETURN
    END IF

    ALLOCATE(statev(nstatv), STAT=err_stat)
    IF (err_stat /= 0) THEN
      PRINT *, "ERROR: Failed to allocate state variables"
      RETURN
    END IF

    ! Initialize state variables
    statev = 0.0D0

  END SUBROUTINE PH_UMAT_AllocateStateVars

  SUBROUTINE PH_UMAT_Call_Enhanced(stress_voigt, statev_in, ddsdde, &
                                   strain_voigt, dstran, time, dtime, temp, dtemp, &
                                   props, nprops, coordinates, drot, pnewdt, &
                                   sse, spd, scd, rpl, drpl, celent, &
                                   dfgrd0, dfgrd1, noel, npt, layer, kspt, jstep, kinc, &
                                   mat_classifier, err_stat)

    IMPLICIT NONE

    ! Standard UMAT parameters
    REAL(wp), INTENT(INOUT) :: stress_voigt(6)  ! Cauchy stress σ (Voigt)
    REAL(wp), INTENT(INOUT) :: statev_in(:)  ! Old state variables
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)  ! Consistent tangent stiffness D_ep
    REAL(wp), INTENT(IN) :: strain_voigt(6)  ! Total accumulated strain ε (Voigt)
    REAL(wp), INTENT(IN) :: dstran(6)  ! Strain increment Δε (Voigt)
    REAL(wp), INTENT(IN) :: time(2)  ! [within step time, total time]
    REAL(wp), INTENT(IN) :: dtime  ! Time increment Δt
    REAL(wp), INTENT(IN) :: temp  ! Current temperature T
    REAL(wp), INTENT(IN) :: dtemp  ! Temperature increment ΔT
    REAL(wp), INTENT(IN) :: props(nprops)  ! Material parameters
    INTEGER(i4), INTENT(IN) :: nprops  ! Parameter count
    REAL(wp), INTENT(IN) :: coordinates(3)  ! Element coordinates
    REAL(wp), INTENT(IN) :: drot(3,3)  ! Rotation matrix increment
    REAL(wp), INTENT(INOUT) :: pnewdt  ! Time step scaling factor
    REAL(wp), INTENT(OUT) :: sse, spd, scd  ! Energy values
    REAL(wp), INTENT(IN) :: rpl, drpl  ! Internal heat generation
    REAL(wp), INTENT(IN) :: celent  ! Element characteristic length
    REAL(wp), INTENT(IN) :: dfgrd0(3,3), dfgrd1(3,3)  ! Deformation gradient F
    INTEGER(i4), INTENT(IN) :: noel, npt, layer, kspt  ! Element/integration point numbers
    INTEGER(i4), INTENT(IN) :: jstep(4), kinc  ! Step/increment numbers

    ! Enhanced parameters
    TYPE(PH_MAT_UMAT_MaterialClassifier), INTENT(IN) :: mat_classifier
    INTEGER(i4), INTENT(OUT) :: err_stat

    ! Local variables
    REAL(wp) :: statev_out(SIZE(statev_in))
    INTEGER(i4) :: material_id

    ! Initialization
    err_stat = 0
    pnewdt = 1.0D0
    ddsdde = 0.0D0
    sse = 0.0D0
    spd = 0.0D0
    scd = 0.0D0

    ! STEP 1: Parameter validation
    IF (nprops < mat_classifier%nprops_expected) THEN
      PRINT *, "WARNING: UMAT props count mismatch"
      PRINT *, "Expected:", mat_classifier%nprops_expected
      PRINT *, "Provided:", nprops
      err_stat = 1
      RETURN
    END IF

    ! STEP 2: Material type dispatch to constitutive model
    material_id = mat_classifier%material_id

    SELECT CASE (material_id)

      CASE (PH_MAT_UMAT_VONMISES)
        CALL PH_UMAT_VonMises_Wrapper(stress_voigt, statev_in, ddsdde, &
                                      dstran, dtime, props, err_stat)

      CASE (PH_MAT_UMAT_NEOHOOKEAN)
        CALL PH_UMAT_NeoHookean_Wrapper(stress_voigt, statev_in, ddsdde, &
                                        dstran, dtime, dfgrd1, props, err_stat)

      CASE (PH_MAT_UMAT_PRONY)
        CALL PH_UMAT_Prony_Wrapper(stress_voigt, statev_in, ddsdde, &
                                   dstran, dtime, props, err_stat)

      CASE DEFAULT
        PRINT *, "ERROR: Unknown Mat class ID:", material_id
        err_stat = 2
        RETURN

    END SELECT

    ! STEP 3: Error handling and time step scaling
    IF (err_stat /= 0) THEN
      PRINT *, "ERROR in UMAT at element", noel, "point", npt
      pnewdt = 0.5D0  ! Automatic time step scaling
      RETURN
    END IF

  END SUBROUTINE PH_UMAT_Call_Enhanced

  SUBROUTINE PH_UMAT_NeoHookean_Wrapper(stress_voigt, statev_in, ddsdde, &
                                        dstran, dtime, dfgrd1, props, err_stat)

    IMPLICIT NONE

    REAL(wp), INTENT(INOUT) :: stress_voigt(6)
    REAL(wp), INTENT(INOUT) :: statev_in(:)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    REAL(wp), INTENT(IN) :: dstran(6)
    REAL(wp), INTENT(IN) :: dtime
    REAL(wp), INTENT(IN) :: dfgrd1(3,3)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(OUT) :: err_stat

    TYPE(MatPropertyDef) :: mat_prop
    TYPE(PH_MatPoint_State) :: mat_state
    TYPE(PH_MatPoint_StressStrain) :: strain_stress
    TYPE(ErrorStatusType) :: err
    INTEGER(i4) :: nprops, nstatv

    err_stat = 0
    nprops = SIZE(props)
    nstatv = MAX(1, SIZE(statev_in))
    mat_prop%mat_id = MAT_ID_NEOHOOKEAN
    mat_prop%num_props = nprops
    mat_prop%num_state_vars = nstatv
    IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
    ALLOCATE(mat_prop%props(nprops))
    mat_prop%props(1:nprops) = REAL(props(1:nprops), wp)
    mat_state%mat_id = MAT_ID_NEOHOOKEAN
    mat_state%nStatev = nstatv
    mat_state%time_step = REAL(dtime, wp)
    IF (ALLOCATED(mat_state%statev)) DEALLOCATE(mat_state%statev)
    IF (ALLOCATED(mat_state%statev_old)) DEALLOCATE(mat_state%statev_old)
    ALLOCATE(mat_state%statev(nstatv), mat_state%statev_old(nstatv))
    mat_state%statev_old(1:nstatv) = REAL(statev_in(1:SIZE(statev_in)), wp)
    mat_state%statev = mat_state%statev_old
    mat_state%is_initialized = .TRUE.
    strain_stress%stress_old(1:6) = REAL(stress_voigt(1:6), wp)
    strain_stress%strain_inc(1:6) = REAL(dstran(1:6), wp)
    strain_stress%sigma = strain_stress%stress_old
    CALL PH_UpdateStress(mat_prop, mat_state, strain_stress, err)
    IF (err%status_code /= IF_STATUS_OK) THEN
      err_stat = 1
      RETURN
    END IF
    stress_voigt(1:6) = REAL(strain_stress%sigma(1:6), 8)
    ddsdde(1:6, 1:6) = REAL(strain_stress%tangent(1:6, 1:6), 8)
    statev_in(1:SIZE(statev_in)) = REAL(mat_state%statev(1:MIN(nstatv,SIZE(statev_in))), 8)
    IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
    IF (ALLOCATED(mat_state%statev)) DEALLOCATE(mat_state%statev)
    IF (ALLOCATED(mat_state%statev_old)) DEALLOCATE(mat_state%statev_old)
  END SUBROUTINE PH_UMAT_NeoHookean_Wrapper

  SUBROUTINE PH_UMAT_Prony_Wrapper(stress_voigt, statev_in, ddsdde, &
                                   dstran, dtime, props, err_stat)

    IMPLICIT NONE

    REAL(wp), INTENT(INOUT) :: stress_voigt(6)
    REAL(wp), INTENT(INOUT) :: statev_in(:)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    REAL(wp), INTENT(IN) :: dstran(6)
    REAL(wp), INTENT(IN) :: dtime
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(OUT) :: err_stat

    TYPE(MatPropertyDef) :: mat_prop
    TYPE(PH_MatPoint_State) :: mat_state
    TYPE(PH_MatPoint_StressStrain) :: strain_stress
    TYPE(ErrorStatusType) :: err
    INTEGER(i4) :: nprops, nstatv

    err_stat = 0
    nprops = SIZE(props)
    nstatv = MAX(1, SIZE(statev_in))
    mat_prop%mat_id = MAT_ID_PRONY
    mat_prop%num_props = nprops
    mat_prop%num_state_vars = nstatv
    IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
    ALLOCATE(mat_prop%props(nprops))
    mat_prop%props(1:nprops) = REAL(props(1:nprops), wp)
    mat_state%mat_id = MAT_ID_PRONY
    mat_state%nStatev = nstatv
    mat_state%time_step = REAL(dtime, wp)
    IF (ALLOCATED(mat_state%statev)) DEALLOCATE(mat_state%statev)
    IF (ALLOCATED(mat_state%statev_old)) DEALLOCATE(mat_state%statev_old)
    ALLOCATE(mat_state%statev(nstatv), mat_state%statev_old(nstatv))
    mat_state%statev_old(1:nstatv) = REAL(statev_in(1:SIZE(statev_in)), wp)
    mat_state%statev = mat_state%statev_old
    mat_state%is_initialized = .TRUE.
    strain_stress%stress_old(1:6) = REAL(stress_voigt(1:6), wp)
    strain_stress%strain_inc(1:6) = REAL(dstran(1:6), wp)
    strain_stress%sigma = strain_stress%stress_old
    CALL PH_UpdateStress(mat_prop, mat_state, strain_stress, err)
    IF (err%status_code /= IF_STATUS_OK) THEN
      err_stat = 1
      RETURN
    END IF
    stress_voigt(1:6) = REAL(strain_stress%sigma(1:6), 8)
    ddsdde(1:6, 1:6) = REAL(strain_stress%tangent(1:6, 1:6), 8)
    statev_in(1:SIZE(statev_in)) = REAL(mat_state%statev(1:MIN(nstatv,SIZE(statev_in))), 8)
    IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
    IF (ALLOCATED(mat_state%statev)) DEALLOCATE(mat_state%statev)
    IF (ALLOCATED(mat_state%statev_old)) DEALLOCATE(mat_state%statev_old)
  END SUBROUTINE PH_UMAT_Prony_Wrapper

  FUNCTION PH_UMAT_RetrieveMaterialClass(props, nprops) RESULT(classifier)

    IMPLICIT NONE

    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(PH_MAT_UMAT_MaterialClassifier) :: classifier

    ! Simplified material type recognition - return default
    classifier%material_id = PH_MAT_UMAT_NEOHOOKEAN
    classifier%mat_name = "NeoHookean"
    classifier%nprops_expected = 2
    classifier%nstatv_expected = 0

  END FUNCTION PH_UMAT_RetrieveMaterialClass

  SUBROUTINE PH_UMAT_ValidateProps(mat_classifier, props, nprops, err_stat)

    IMPLICIT NONE

    TYPE(PH_MAT_UMAT_MaterialClassifier), INTENT(IN) :: mat_classifier
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    INTEGER(i4), INTENT(OUT) :: err_stat

    err_stat = 0

    IF (nprops < mat_classifier%nprops_expected) THEN
      PRINT *, "ERROR: Props count = ", nprops
      PRINT *, "Expected at least:", mat_classifier%nprops_expected
      err_stat = 1
      RETURN
    END IF

    SELECT CASE (mat_classifier%material_id)

      CASE (PH_MAT_UMAT_NEOHOOKEAN)
        IF (props(1) <= 0.0D0) THEN
          PRINT *, "ERROR: mu (shear modulus) must be positive"
          err_stat = 1
          RETURN
        END IF
        IF (props(2) < -2.0D0*props(1)/3.0D0) THEN
          PRINT *, "ERROR: lambda violates stability condition"
          err_stat = 1
          RETURN
        END IF

      CASE (PH_MAT_UMAT_PRONY)
        IF (props(1) <= 0.0D0 .OR. props(2) <= 0.0D0) THEN
          PRINT *, "ERROR: G_inf and K must be positive"
          err_stat = 1
          RETURN
        END IF

      CASE DEFAULT
        ! No specific checks
    END SELECT

  END SUBROUTINE PH_UMAT_ValidateProps

  SUBROUTINE PH_UMAT_VonMises_Wrapper(stress_voigt, statev_in, ddsdde, &
                                      dstran, dtime, props, err_stat)

    IMPLICIT NONE

    REAL(wp), INTENT(INOUT) :: stress_voigt(6)
    REAL(wp), INTENT(INOUT) :: statev_in(:)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    REAL(wp), INTENT(IN) :: dstran(6)
    REAL(wp), INTENT(IN) :: dtime
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(OUT) :: err_stat

    TYPE(MatPropertyDef) :: mat_prop
    TYPE(PH_MatPoint_State) :: mat_state
    TYPE(PH_MatPoint_StressStrain) :: strain_stress
    TYPE(ErrorStatusType) :: err
    INTEGER(i4) :: nprops, nstatv

    err_stat = 0
    nprops = SIZE(props)
    nstatv = SIZE(statev_in)
    IF (nprops < 3) THEN
      err_stat = 1
      RETURN
    END IF

    mat_prop%mat_id = MAT_ID_VONMISES
    mat_prop%num_props = nprops
    mat_prop%num_state_vars = MAX(7, nstatv)
    IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
    ALLOCATE(mat_prop%props(nprops))
    mat_prop%props(1:nprops) = REAL(props(1:nprops), wp)

    mat_state%mat_id = MAT_ID_VONMISES
    mat_state%nStatev = nstatv
    mat_state%time_step = REAL(dtime, wp)
    IF (ALLOCATED(mat_state%statev)) DEALLOCATE(mat_state%statev)
    IF (ALLOCATED(mat_state%statev_old)) DEALLOCATE(mat_state%statev_old)
    ALLOCATE(mat_state%statev(nstatv), mat_state%statev_old(nstatv))
    mat_state%statev_old(1:nstatv) = REAL(statev_in(1:nstatv), wp)
    mat_state%statev(1:nstatv) = mat_state%statev_old(1:nstatv)
    mat_state%is_initialized = .TRUE.

    strain_stress%stress_old(1:6) = REAL(stress_voigt(1:6), wp)
    strain_stress%strain_inc(1:6) = REAL(dstran(1:6), wp)
    strain_stress%sigma = strain_stress%stress_old

    CALL PH_UpdateStress(mat_prop, mat_state, strain_stress, err)
    IF (err%status_code /= IF_STATUS_OK) THEN
      err_stat = 1
      RETURN
    END IF

    stress_voigt(1:6) = REAL(strain_stress%sigma(1:6), 8)
    ddsdde(1:6, 1:6) = REAL(strain_stress%tangent(1:6, 1:6), 8)
    statev_in(1:nstatv) = REAL(mat_state%statev(1:nstatv), 8)

    IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
    IF (ALLOCATED(mat_state%statev)) DEALLOCATE(mat_state%statev)
    IF (ALLOCATED(mat_state%statev_old)) DEALLOCATE(mat_state%statev_old)
  END SUBROUTINE PH_UMAT_VonMises_Wrapper
END MODULE PH_Mat_UMAT_Brg
