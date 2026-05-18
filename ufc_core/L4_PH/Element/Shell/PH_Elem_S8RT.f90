!===============================================================================
! MODULE: PH_Elem_S8RT
! LAYER:  L4_PH
! DOMAIN: Element/Shell
! ROLE:   Proc
! BRIEF:  S8RT thermo-mechanical coupling element (8-node)
!===============================================================================
MODULE PH_Elem_S8RT
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_S8, ONLY: PH_Elem_S8_StiffMatrix_In, PH_Elem_S8_StiffMatrix_Out, &
       PH_Elem_S8_FormStiffMatrix, PH_Elem_S8_FormIntForce_Legacy, &
       PH_Elem_S8_Material_Update_Membrane_Routed
  USE PH_Elem_CPS8T, ONLY: PH_Elem_CPS8T_FormThermalStiffness
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, ONLY: MatProperties
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_S8RT_NDOF_TOTAL = 56_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_S8RT_NDOF_MECH = 48_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_S8RT_NDOF_THERM = 8_i4
  INTEGER(i4), PARAMETER :: PH_S8RT_PROP_E = 1_i4
  INTEGER(i4), PARAMETER :: PH_S8RT_PROP_NU = 2_i4

  PUBLIC :: PH_Elem_S8RT_FormStiffMatrix
  PUBLIC :: PH_Elem_S8RT_FormIntForce
  PUBLIC :: PH_Elem_S8RT_Material_Update_Membrane_Routed
  PUBLIC :: PH_Elem_S8RT_Material_Update_Thermal_Routed
  PUBLIC :: UF_Elem_S8RT_Calc

CONTAINS

  SUBROUTINE PH_Elem_S8RT_FormStiffMatrix(coords3, E_young, nu, k_thermal, Ke56, status)
    REAL(wp), INTENT(IN) :: coords3(3, 8)
    REAL(wp), INTENT(IN) :: E_young, nu, k_thermal
    REAL(wp), INTENT(OUT) :: Ke56(56, 56)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(PH_Elem_S8_StiffMatrix_In) :: in_s8
    TYPE(PH_Elem_S8_StiffMatrix_Out) :: out_s8
    REAL(wp) :: Ke_tt(8, 8)

    CALL init_error_status(status)
    Ke56 = 0.0_wp
    in_s8%coords(1:3, 1:8) = coords3(1:3, 1:8)
    in_s8%E_young = E_young
    in_s8%nu = nu
    CALL PH_Elem_S8_FormStiffMatrix(in_s8, out_s8)
    IF (out_s8%status%status_code /= IF_STATUS_OK) THEN
      status = out_s8%status
      RETURN
    END IF
    Ke56(1:48, 1:48) = out_s8%evo%Ke(1:48, 1:48)
    CALL PH_Elem_CPS8T_FormThermalStiffness(coords3(1:2, 1:8), k_thermal, Ke_tt)
    Ke56(49:56, 49:56) = Ke_tt(1:8, 1:8)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_S8RT_FormStiffMatrix

  SUBROUTINE PH_Elem_S8RT_FormIntForce(coords3, u56, E_young, nu, k_thermal, R56, status)
    REAL(wp), INTENT(IN) :: coords3(3, 8)
    REAL(wp), INTENT(IN) :: u56(56)
    REAL(wp), INTENT(IN) :: E_young, nu, k_thermal
    REAL(wp), INTENT(OUT) :: R56(56)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: R48(48)
    REAL(wp) :: Ke_tt(8, 8)

    CALL init_error_status(status)
    R56 = 0.0_wp
    CALL PH_Elem_S8_FormIntForce_Legacy(coords3, u56(1:48), E_young, nu, R48)
    R56(1:48) = R48
    CALL PH_Elem_CPS8T_FormThermalStiffness(coords3(1:2, 1:8), k_thermal, Ke_tt)
    R56(49:56) = MATMUL(Ke_tt, u56(49:56))
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_S8RT_FormIntForce

  SUBROUTINE UF_Elem_S8RT_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: i
    REAL(wp) :: coords(3, 8)
    REAL(wp) :: u56(56)
    REAL(wp) :: E_young, nu, k_th
    REAL(wp) :: Ke56(56, 56), R56(56)
    TYPE(MatProperties) :: props
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    IF (.NOT. ALLOCATED(Ctx%coords_ref) .OR. SIZE(Ctx%coords_ref, 2) < 8_i4) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S8RT_Calc: coords_ref missing or nNode < 8'
      RETURN
    END IF

    DO i = 1, 8
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
           Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
      IF (SIZE(Ctx%coords_ref, 1) < 3) coords(3, i) = 0.0_wp
    END DO

    u56 = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total) .AND. SIZE(Ctx%disp_total, 2) >= 8_i4) THEN
      DO i = 1, 8
        IF (SIZE(Ctx%disp_total, 1) >= 6_i4) THEN
          u56((i - 1) * 6 + 1:(i - 1) * 6 + 3) = Ctx%disp_total(1:3, i)
          u56((i - 1) * 6 + 4:(i - 1) * 6 + 6) = Ctx%disp_total(4:6, i)
        ELSE IF (SIZE(Ctx%disp_total, 1) >= 3_i4) THEN
          u56((i - 1) * 6 + 1:(i - 1) * 6 + 3) = Ctx%disp_total(1:3, i)
        END IF
        IF (SIZE(Ctx%disp_total, 1) >= 7_i4) u56(48 + i) = Ctx%disp_total(7, i)
      END DO
    END IF

    E_young = 0.0_wp
    nu = 0.3_wp
    k_th = 50.0_wp
    props = Mat%props
    IF (ALLOCATED(props%props)) THEN
      IF (SIZE(props%props) >= PH_S8RT_PROP_E) E_young = props%props(PH_S8RT_PROP_E)
      IF (SIZE(props%props) >= PH_S8RT_PROP_NU) nu = props%props(PH_S8RT_PROP_NU)
      IF (SIZE(props%props) >= 3_i4) THEN
        IF (props%props(3) > 1.0e-6_wp .AND. props%props(3) < 500.0_wp) k_th = props%props(3)
      END IF
    END IF

    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S8RT_Calc: invalid Young modulus'
      RETURN
    END IF

    CALL PH_Elem_S8RT_FormStiffMatrix(coords, E_young, nu, k_th, Ke56, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      flags%failed = .TRUE.
      flags%status = st
      RETURN
    END IF

    CALL PH_Elem_S8RT_FormIntForce(coords, u56, E_young, nu, k_th, R56, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      flags%failed = .TRUE.
      flags%status = st
      RETURN
    END IF

    CALL PH_S8RT_EnsureStorage56(state_out)
    state_out%evo%Ke(1:56, 1:56) = Ke56
    state_out%Re(1:56) = R56

    flags%status%status_code = IF_STATUS_OK
    flags%requires_reasse = .TRUE.
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt
  END SUBROUTINE UF_Elem_S8RT_Calc

  SUBROUTINE PH_S8RT_EnsureStorage56(state_out)
    TYPE(ElemState), INTENT(INOUT) :: state_out
    IF (.NOT. ASSOCIATED(state_out%evo%Ke)) THEN
      ALLOCATE(state_out%evo%Ke(56, 56))
    ELSE IF (SIZE(state_out%evo%Ke, 1) /= 56_i4 .OR. SIZE(state_out%evo%Ke, 2) /= 56_i4) THEN
      DEALLOCATE(state_out%evo%Ke)
      ALLOCATE(state_out%evo%Ke(56, 56))
    END IF
    IF (.NOT. ASSOCIATED(state_out%Re)) THEN
      ALLOCATE(state_out%Re(56))
    ELSE IF (SIZE(state_out%Re) /= 56_i4) THEN
      DEALLOCATE(state_out%Re)
      ALLOCATE(state_out%Re(56))
    END IF
  END SUBROUTINE PH_S8RT_EnsureStorage56

  SUBROUTINE PH_Elem_S8RT_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                          stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_S8_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                    stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_S8RT_Material_Update_Membrane_Routed

  SUBROUTINE PH_Elem_S8RT_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
                                                         heat_flux, K_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_ThermalConductivityScalar

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: temp_gradient
    REAL(wp),                  INTENT(OUT)   :: heat_flux
    REAL(wp),                  INTENT(OUT)   :: K_tangent
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ThermalConductivityScalar(rt_ctx, mat_slot, temp_gradient, &
                                                    heat_flux, K_tangent, status)
  END SUBROUTINE PH_Elem_S8RT_Material_Update_Thermal_Routed

END MODULE PH_Elem_S8RT

