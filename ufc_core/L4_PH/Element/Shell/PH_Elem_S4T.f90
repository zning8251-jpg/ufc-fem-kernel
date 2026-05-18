!===============================================================================
! MODULE: PH_Elem_S4T
! LAYER:  L4_PH
! DOMAIN: Element/Shell
! ROLE:   Proc
! BRIEF:  S4T thermo-mechanical coupling element (4-node)
!===============================================================================
MODULE PH_Elem_S4T
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_S4, ONLY: PH_Elem_S4_StiffMatrix_In, PH_Elem_S4_StiffMatrix_Out, &
       PH_Elem_S4_IntForce_In, PH_Elem_S4_IntForce_Out, &
       PH_Elem_S4_FormStiffMatrix, PH_Elem_S4_FormIntForce, PH_ELEM_S4_INTEGRATION_FULL, &
       PH_Elem_S4_Material_Update_Membrane_Routed
  USE PH_Elem_CPS4T, ONLY: PH_Elem_CPS4T_FormThermalStiffness
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, ONLY: MatProperties
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_S4T_NNODE = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_S4T_NDOF_MECH = 24_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_S4T_NDOF_THERM = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_S4T_NDOF_TOTAL = 28_i4
  ! Mat%props indices aligned with common iso tables (E, nu, ?
  INTEGER(i4), PARAMETER :: PH_S4T_PROP_E = 1_i4
  INTEGER(i4), PARAMETER :: PH_S4T_PROP_NU = 2_i4

  PUBLIC :: PH_Elem_S4T_FormStiffMatrix
  PUBLIC :: PH_Elem_S4T_FormIntForce
  PUBLIC :: PH_Elem_S4T_Material_Update_Membrane_Routed
  PUBLIC :: PH_Elem_S4T_Material_Update_Thermal_Routed
  PUBLIC :: UF_Elem_S4T_Calc

CONTAINS

  SUBROUTINE PH_Elem_S4T_FormStiffMatrix(coords3, E_young, nu, integration_scheme, k_thermal, &
       Ke28, status)
    REAL(wp), INTENT(IN) :: coords3(3, 4)
    REAL(wp), INTENT(IN) :: E_young, nu
    INTEGER(i4), INTENT(IN) :: integration_scheme
    REAL(wp), INTENT(IN) :: k_thermal
    REAL(wp), INTENT(OUT) :: Ke28(28, 28)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(PH_Elem_S4_StiffMatrix_In) :: in_s4
    TYPE(PH_Elem_S4_StiffMatrix_Out) :: out_s4
    REAL(wp) :: Ke_tt(4, 4)

    CALL init_error_status(status)
    Ke28 = 0.0_wp
    in_s4%coords(1:3, 1:4) = coords3(1:3, 1:4)
    in_s4%E_young = E_young
    in_s4%nu = nu
    in_s4%integration_scheme = integration_scheme
    CALL PH_Elem_S4_FormStiffMatrix(in_s4, out_s4)
    IF (out_s4%status%status_code /= IF_STATUS_OK) THEN
      status = out_s4%status
      RETURN
    END IF
    Ke28(1:24, 1:24) = out_s4%evo%Ke(1:24, 1:24)
    CALL PH_Elem_CPS4T_FormThermalStiffness(coords3(1:2, 1:4), k_thermal, Ke_tt)
    Ke28(25:28, 25:28) = Ke_tt(1:4, 1:4)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_S4T_FormStiffMatrix

  SUBROUTINE PH_Elem_S4T_FormIntForce(coords3, u28, E_young, nu, integration_scheme, k_thermal, &
       R28, status)
    REAL(wp), INTENT(IN) :: coords3(3, 4)
    REAL(wp), INTENT(IN) :: u28(28)
    REAL(wp), INTENT(IN) :: E_young, nu
    INTEGER(i4), INTENT(IN) :: integration_scheme
    REAL(wp), INTENT(IN) :: k_thermal
    REAL(wp), INTENT(OUT) :: R28(28)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(PH_Elem_S4_IntForce_In) :: in_f
    TYPE(PH_Elem_S4_IntForce_Out) :: out_f
    REAL(wp) :: Ke_tt(4, 4)

    CALL init_error_status(status)
    R28 = 0.0_wp
    in_f%coords(1:3, 1:4) = coords3(1:3, 1:4)
    in_f%u(1:24) = u28(1:24)
    in_f%E_young = E_young
    in_f%nu = nu
    in_f%integration_scheme = integration_scheme
    CALL PH_Elem_S4_FormIntForce(in_f, out_f)
    IF (out_f%status%status_code /= IF_STATUS_OK) THEN
      status = out_f%status
      RETURN
    END IF
    R28(1:24) = out_f%evo%R_int(1:24)
    CALL PH_Elem_CPS4T_FormThermalStiffness(coords3(1:2, 1:4), k_thermal, Ke_tt)
    R28(25:28) = MATMUL(Ke_tt, u28(25:28))
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_S4T_FormIntForce

  SUBROUTINE UF_Elem_S4T_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: i
    REAL(wp) :: coords(3, 4)
    REAL(wp) :: u28(28)
    REAL(wp) :: E_young, nu, k_th
    REAL(wp) :: Ke28(28, 28), R28(28)
    TYPE(MatProperties) :: props
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    IF (.NOT. ALLOCATED(Ctx%coords_ref) .OR. SIZE(Ctx%coords_ref, 2) < 4_i4) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S4T_Calc: coords_ref missing or nNode < 4'
      RETURN
    END IF

    DO i = 1, 4
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
           Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
      IF (SIZE(Ctx%coords_ref, 1) < 3) coords(3, i) = 0.0_wp
    END DO

    u28 = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total) .AND. SIZE(Ctx%disp_total, 2) >= 4_i4) THEN
      DO i = 1, 4
        IF (SIZE(Ctx%disp_total, 1) >= 6_i4) THEN
          u28((i - 1) * 6 + 1:(i - 1) * 6 + 3) = Ctx%disp_total(1:3, i)
          u28((i - 1) * 6 + 4:(i - 1) * 6 + 6) = Ctx%disp_total(4:6, i)
        ELSE IF (SIZE(Ctx%disp_total, 1) >= 3_i4) THEN
          u28((i - 1) * 6 + 1:(i - 1) * 6 + 3) = Ctx%disp_total(1:3, i)
        END IF
        IF (SIZE(Ctx%disp_total, 1) >= 7_i4) u28(24 + i) = Ctx%disp_total(7, i)
      END DO
    END IF

    E_young = 0.0_wp
    nu = 0.3_wp
    k_th = 50.0_wp
    props = Mat%props
    IF (ALLOCATED(props%props)) THEN
      IF (SIZE(props%props) >= PH_S4T_PROP_E) E_young = props%props(PH_S4T_PROP_E)
      IF (SIZE(props%props) >= PH_S4T_PROP_NU) nu = props%props(PH_S4T_PROP_NU)
      IF (SIZE(props%props) >= 3_i4) THEN
        IF (props%props(3) > 1.0e-6_wp .AND. props%props(3) < 500.0_wp) k_th = props%props(3)
      END IF
    END IF

    IF (E_young <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_S4T_Calc: invalid Young modulus'
      RETURN
    END IF

    CALL PH_Elem_S4T_FormStiffMatrix(coords, E_young, nu, PH_ELEM_S4_INTEGRATION_FULL, k_th, Ke28, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      flags%failed = .TRUE.
      flags%status = st
      RETURN
    END IF

    CALL PH_Elem_S4T_FormIntForce(coords, u28, E_young, nu, PH_ELEM_S4_INTEGRATION_FULL, k_th, R28, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      flags%failed = .TRUE.
      flags%status = st
      RETURN
    END IF

    CALL PH_S4T_EnsureStorage28(state_out)
    state_out%evo%Ke(1:28, 1:28) = Ke28
    state_out%Re(1:28) = R28

    flags%status%status_code = IF_STATUS_OK
    flags%requires_reasse = .TRUE.
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt
  END SUBROUTINE UF_Elem_S4T_Calc

  SUBROUTINE PH_S4T_EnsureStorage28(state_out)
    TYPE(ElemState), INTENT(INOUT) :: state_out
    IF (.NOT. ASSOCIATED(state_out%evo%Ke)) THEN
      ALLOCATE(state_out%evo%Ke(28, 28))
    ELSE IF (SIZE(state_out%evo%Ke, 1) /= 28_i4 .OR. SIZE(state_out%evo%Ke, 2) /= 28_i4) THEN
      DEALLOCATE(state_out%evo%Ke)
      ALLOCATE(state_out%evo%Ke(28, 28))
    END IF
    IF (.NOT. ASSOCIATED(state_out%Re)) THEN
      ALLOCATE(state_out%Re(28))
    ELSE IF (SIZE(state_out%Re) /= 28_i4) THEN
      DEALLOCATE(state_out%Re)
      ALLOCATE(state_out%Re(28))
    END IF
  END SUBROUTINE PH_S4T_EnsureStorage28

  SUBROUTINE PH_Elem_S4T_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
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

    CALL PH_Elem_S4_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &
                                                    stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_S4T_Material_Update_Membrane_Routed

  SUBROUTINE PH_Elem_S4T_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &
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
  END SUBROUTINE PH_Elem_S4T_Material_Update_Thermal_Routed

END MODULE PH_Elem_S4T

