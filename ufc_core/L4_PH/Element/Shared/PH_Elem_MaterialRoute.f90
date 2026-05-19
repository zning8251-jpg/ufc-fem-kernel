!===============================================================================
! MODULE: PH_Elem_MaterialRoute
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Element-side material routing — build elastic/material hooks per family using PH slots.
! **W2**：单元侧取 **`PH_Mat_Slot`/`desc%props`** 与 **`PH_Mat_Desc_Effective_Model`**；
!         路由上下文校验在 L4（**`PH_Elem_MatRoute_ValidateRtCtx`**），不 USE L5 **`RT_Mat_Core`**。
! Status: ACTIVE | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Elem_MaterialRoute
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_INVALID, init_error_status
  USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx, &
      IF_MAT_ROUTE_OK, IF_MAT_ROUTE_NOT_FOUND, IF_MAT_ROUTE_NO_KERNEL
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE PH_Mat_Def, ONLY: PH_Mat_Slot, &
      PH_MAT_ELASTIC
  USE PH_Mat_Core, ONLY: PH_Mat_Desc_Effective_Model
  USE PH_Mat_Elas_Def, ONLY: PH_Mat_Elas_Desc, PH_Mat_Elas_Ctx, PH_Mat_Elas_State
  USE PH_Mat_Elas_Core, ONLY: PH_Mat_Elas_Init_From_Props, &
                              PH_Mat_Elas_Build_D_el, PH_Mat_Elas_Compute_Stress
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Elem_MatRoute_BuildElasticSlot
  PUBLIC :: PH_Elem_MatRoute_AcousticFluid
  PUBLIC :: PH_Elem_MatRoute_BeamElasticConstants
  PUBLIC :: PH_Elem_MatRoute_CohesiveLinear
  PUBLIC :: PH_Elem_MatRoute_DashpotScalar
  PUBLIC :: PH_Elem_MatRoute_ElasticUniaxial
  PUBLIC :: PH_Elem_MatRoute_GasketLinear
  PUBLIC :: PH_Elem_MatRoute_InfiniteDecay
  PUBLIC :: PH_Elem_MatRoute_MassScalar
  PUBLIC :: PH_Elem_MatRoute_PorousTwoPhase
  PUBLIC :: PH_Elem_MatRoute_Elastic3D
  PUBLIC :: PH_Elem_MatRoute_ElasticAxisymmetric
  PUBLIC :: PH_Elem_MatRoute_ElasticPlaneStrain
  PUBLIC :: PH_Elem_MatRoute_ElasticPlaneStress
  PUBLIC :: PH_Elem_MatRoute_ThermoElastic3D
  PUBLIC :: PH_Elem_MatRoute_ThermoElasticAxisymmetric
  PUBLIC :: PH_Elem_MatRoute_ThermoElasticPlaneStrain
  PUBLIC :: PH_Elem_MatRoute_ThermoElasticPlaneStress
  PUBLIC :: PH_Elem_MatRoute_ThermalConductivityScalar

CONTAINS

  SUBROUTINE PH_Elem_MatRoute_BuildElasticSlot(mat_pt_idx, rt_ctx, mat_slot, status)
    INTEGER(i4),                INTENT(IN)  :: mat_pt_idx
    TYPE(RT_Mat_Dispatch_Ctx),  INTENT(OUT) :: rt_ctx
    TYPE(PH_Mat_Slot),     INTENT(OUT) :: mat_slot
    TYPE(ErrorStatusType),      INTENT(OUT) :: status

    INTEGER(i4) :: mid_eff

    IF (mat_pt_idx <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_BuildElasticSlot: missing mat_pt_idx from Element map"
      RETURN
    END IF

    IF (.NOT. g_ufc_global%IsReady()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_BuildElasticSlot: global layer not ready"
      RETURN
    END IF

    ASSOCIATE (md => g_ufc_global%ph_layer%material)
      IF (.NOT. md%initialized .OR. .NOT. ALLOCATED(md%slot_pool)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "PH_Elem_MatRoute_BuildElasticSlot: material domain not ready"
        RETURN
      END IF

      IF (mat_pt_idx < 1_i4 .OR. mat_pt_idx > md%pool_count) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "PH_Elem_MatRoute_BuildElasticSlot: mat_pt_idx out of range"
        RETURN
      END IF

      mat_slot = md%slot_pool(mat_pt_idx)
    END ASSOCIATE

    mid_eff = mat_slot%desc%cfg%matId

    rt_ctx%mat_type = PH_Mat_Desc_Effective_Model(mat_slot%desc)
    rt_ctx%mat_id = mid_eff
    rt_ctx%mat_pt_idx = mat_pt_idx
    rt_ctx%is_user_sub = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_BuildElasticSlot

  SUBROUTINE PH_Elem_MatRoute_Elastic3D(rt_ctx, mat_slot, dstrain, &
                                        stress_old, stress_new, D_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain(6)
    REAL(wp),                  INTENT(IN)    :: stress_old(6)
    REAL(wp),                  INTENT(OUT)   :: stress_new(6)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(6, 6)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    TYPE(PH_Mat_Elas_Desc) :: elas_desc
    TYPE(PH_Mat_Elas_Ctx) :: elas_ctx
    TYPE(PH_Mat_Elas_State) :: elas_state
    REAL(wp) :: stress_inc(6)

    CALL PH_Elem_MatRoute_ValidateElasticSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_Elas_Init_From_Props(elas_desc, elas_state, &
                                     SIZE(mat_slot%desc%props), mat_slot%desc%props, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_Elas_Build_D_el(elas_desc, elas_ctx, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_Elas_Compute_Stress(elas_ctx, dstrain, stress_inc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    stress_new = stress_old + stress_inc
    D_tangent = elas_ctx%D_el
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_Elastic3D

  SUBROUTINE PH_Elem_MatRoute_ElasticUniaxial(rt_ctx, mat_slot, dstrain, &
                                              stress_old, stress_new, D_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain
    REAL(wp),                  INTENT(IN)    :: stress_old
    REAL(wp),                  INTENT(OUT)   :: stress_new
    REAL(wp),                  INTENT(OUT)   :: D_tangent
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    TYPE(PH_Mat_Elas_Desc) :: elas_desc
    TYPE(PH_Mat_Elas_State) :: elas_state

    CALL PH_Elem_MatRoute_ValidateElasticSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_Elas_Init_From_Props(elas_desc, elas_state, &
                                     SIZE(mat_slot%desc%props), mat_slot%desc%props, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    D_tangent = elas_desc%E
    stress_new = stress_old + D_tangent * dstrain
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_ElasticUniaxial

  SUBROUTINE PH_Elem_MatRoute_BeamElasticConstants(rt_ctx, mat_slot, E_young, nu, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: E_young
    REAL(wp),                  INTENT(OUT)   :: nu
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    TYPE(PH_Mat_Elas_Desc) :: elas_desc
    TYPE(PH_Mat_Elas_State) :: elas_state

    CALL PH_Elem_MatRoute_ValidateElasticSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_Elas_Init_From_Props(elas_desc, elas_state, &
                                     SIZE(mat_slot%desc%props), mat_slot%desc%props, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    E_young = elas_desc%E
    nu = elas_desc%nu
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_BeamElasticConstants

  SUBROUTINE PH_Elem_MatRoute_DashpotScalar(rt_ctx, mat_slot, rel_velocity, &
                                            force_new, C_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: rel_velocity
    REAL(wp),                  INTENT(OUT)   :: force_new
    REAL(wp),                  INTENT(OUT)   :: C_tangent
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    C_tangent = mat_slot%desc%props(1)
    IF (C_tangent < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_DashpotScalar: negative damping coefficient"
      RETURN
    END IF

    force_new = C_tangent * rel_velocity
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_DashpotScalar

  SUBROUTINE PH_Elem_MatRoute_ThermalConductivityScalar(rt_ctx, mat_slot, temp_gradient, &
                                                        heat_flux, K_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: temp_gradient
    REAL(wp),                  INTENT(OUT)   :: heat_flux
    REAL(wp),                  INTENT(OUT)   :: K_tangent
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    K_tangent = mat_slot%desc%props(1)
    IF (K_tangent < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_ThermalConductivityScalar: negative conductivity"
      RETURN
    END IF

    heat_flux = -K_tangent * temp_gradient
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_ThermalConductivityScalar

  SUBROUTINE PH_Elem_MatRoute_MassScalar(rt_ctx, mat_slot, n_node, mass_total, &
                                         mass_per_node, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    INTEGER(i4),               INTENT(IN)    :: n_node
    REAL(wp),                  INTENT(OUT)   :: mass_total
    REAL(wp),                  INTENT(OUT)   :: mass_per_node
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (n_node <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_MassScalar: invalid node count"
      RETURN
    END IF

    mass_total = mat_slot%desc%props(1)
    IF (mass_total < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_MassScalar: negative mass"
      RETURN
    END IF

    mass_per_node = mass_total / REAL(n_node, wp)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_MassScalar

  SUBROUTINE PH_Elem_MatRoute_AcousticFluid(rt_ctx, mat_slot, density, bulk_modulus, &
                                            sound_speed, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: density
    REAL(wp),                  INTENT(OUT)   :: bulk_modulus
    REAL(wp),                  INTENT(OUT)   :: sound_speed
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (SIZE(mat_slot%desc%props) < 2) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_AcousticFluid: missing density or bulk modulus"
      RETURN
    END IF

    density = mat_slot%desc%props(1)
    bulk_modulus = mat_slot%desc%props(2)
    IF (density <= 0.0_wp .OR. bulk_modulus <= 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_AcousticFluid: non-positive acoustic property"
      RETURN
    END IF

    sound_speed = SQRT(bulk_modulus / density)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_AcousticFluid

  SUBROUTINE PH_Elem_MatRoute_CohesiveLinear(rt_ctx, mat_slot, K_n, K_s, &
                                             t_n_max, t_s_max, G_Ic, G_IIc, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: K_n
    REAL(wp),                  INTENT(OUT)   :: K_s
    REAL(wp),                  INTENT(OUT)   :: t_n_max
    REAL(wp),                  INTENT(OUT)   :: t_s_max
    REAL(wp),                  INTENT(OUT)   :: G_Ic
    REAL(wp),                  INTENT(OUT)   :: G_IIc
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (SIZE(mat_slot%desc%props) < 2) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_CohesiveLinear: missing normal/shear stiffness"
      RETURN
    END IF

    K_n = mat_slot%desc%props(1)
    K_s = mat_slot%desc%props(2)
    t_n_max = 1.0E10_wp
    t_s_max = 1.0E10_wp
    G_Ic = 1.0E10_wp
    G_IIc = 1.0E10_wp
    IF (SIZE(mat_slot%desc%props) >= 4) THEN
      t_n_max = mat_slot%desc%props(3)
      t_s_max = mat_slot%desc%props(4)
    END IF
    IF (SIZE(mat_slot%desc%props) >= 6) THEN
      G_Ic = mat_slot%desc%props(5)
      G_IIc = mat_slot%desc%props(6)
    END IF

    IF (K_n < 0.0_wp .OR. K_s < 0.0_wp .OR. t_n_max < 0.0_wp .OR. &
        t_s_max < 0.0_wp .OR. G_Ic < 0.0_wp .OR. G_IIc < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_CohesiveLinear: negative cohesive property"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_CohesiveLinear

  SUBROUTINE PH_Elem_MatRoute_GasketLinear(rt_ctx, mat_slot, K_g, h_0, p_max, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: K_g
    REAL(wp),                  INTENT(OUT)   :: h_0
    REAL(wp),                  INTENT(OUT)   :: p_max
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (SIZE(mat_slot%desc%props) < 2) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_GasketLinear: missing stiffness or initial gap"
      RETURN
    END IF

    K_g = mat_slot%desc%props(1)
    h_0 = mat_slot%desc%props(2)
    p_max = 1.0E10_wp
    IF (SIZE(mat_slot%desc%props) >= 3) p_max = mat_slot%desc%props(3)

    IF (K_g < 0.0_wp .OR. h_0 <= 0.0_wp .OR. p_max < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_GasketLinear: invalid gasket property"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_GasketLinear

  SUBROUTINE PH_Elem_MatRoute_InfiniteDecay(rt_ctx, mat_slot, decay_rate, decay_type, &
                                            decay_power, reference_dista, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: decay_rate
    INTEGER(i4),               INTENT(OUT)   :: decay_type
    REAL(wp),                  INTENT(OUT)   :: decay_power
    REAL(wp),                  INTENT(OUT)   :: reference_dista
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    decay_rate = mat_slot%desc%props(1)
    decay_type = 1_i4
    decay_power = 2.0_wp
    reference_dista = 1.0_wp
    IF (SIZE(mat_slot%desc%props) >= 2) decay_type = INT(mat_slot%desc%props(2), i4)
    IF (SIZE(mat_slot%desc%props) >= 3) decay_power = mat_slot%desc%props(3)
    IF (SIZE(mat_slot%desc%props) >= 4) reference_dista = mat_slot%desc%props(4)

    IF (decay_type < 1_i4 .OR. decay_type > 3_i4) decay_type = 1_i4
    IF (decay_rate <= 0.0_wp .OR. decay_power <= 0.0_wp .OR. reference_dista <= 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_InfiniteDecay: invalid decay property"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_InfiniteDecay

  SUBROUTINE PH_Elem_MatRoute_PorousTwoPhase(rt_ctx, mat_slot, model_flag, alpha_vg, &
                                             n_vg, phi, Swr, Snr, n_corey, m_vg, &
                                             l_mualem, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: model_flag
    REAL(wp),                  INTENT(OUT)   :: alpha_vg
    REAL(wp),                  INTENT(OUT)   :: n_vg
    REAL(wp),                  INTENT(OUT)   :: phi
    REAL(wp),                  INTENT(OUT)   :: Swr
    REAL(wp),                  INTENT(OUT)   :: Snr
    REAL(wp),                  INTENT(OUT)   :: n_corey
    REAL(wp),                  INTENT(OUT)   :: m_vg
    REAL(wp),                  INTENT(OUT)   :: l_mualem
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (SIZE(mat_slot%desc%props) < 4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_PorousTwoPhase: missing core porous props"
      RETURN
    END IF

    model_flag = mat_slot%desc%props(1)
    alpha_vg = mat_slot%desc%props(2)
    n_vg = mat_slot%desc%props(3)
    phi = mat_slot%desc%props(4)
    Swr = 0.0_wp
    Snr = 0.0_wp
    n_corey = 2.0_wp
    m_vg = 1.0_wp - 1.0_wp / MAX(n_vg, 2.0_wp)
    l_mualem = 0.5_wp

    IF (SIZE(mat_slot%desc%props) >= 5) Swr = mat_slot%desc%props(5)
    IF (SIZE(mat_slot%desc%props) >= 6) Snr = mat_slot%desc%props(6)
    IF (SIZE(mat_slot%desc%props) >= 7) n_corey = mat_slot%desc%props(7)
    IF (SIZE(mat_slot%desc%props) >= 8) m_vg = mat_slot%desc%props(8)
    IF (SIZE(mat_slot%desc%props) >= 9) l_mualem = mat_slot%desc%props(9)

    IF (alpha_vg <= 0.0_wp .OR. n_vg <= 1.0_wp .OR. phi <= 0.0_wp .OR. &
        phi >= 1.0_wp .OR. Swr < 0.0_wp .OR. Snr < 0.0_wp .OR. &
        Swr + Snr >= 1.0_wp .OR. n_corey <= 0.0_wp .OR. m_vg <= 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute_PorousTwoPhase: invalid porous property"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_PorousTwoPhase

  SUBROUTINE PH_Elem_MatRoute_ElasticPlaneStrain(rt_ctx, mat_slot, dstrain, &
                                                 stress_old, stress_new, D_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    REAL(wp) :: D6(6, 6)
    REAL(wp) :: strain6(6)
    REAL(wp) :: stress_old6(6)
    REAL(wp) :: stress_new6(6)

    strain6 = 0.0_wp
    strain6(1) = dstrain(1)
    strain6(2) = dstrain(2)
    strain6(4) = dstrain(3)
    stress_old6 = 0.0_wp
    stress_old6(1) = stress_old(1)
    stress_old6(2) = stress_old(2)
    stress_old6(4) = stress_old(3)

    CALL PH_Elem_MatRoute_Elastic3D(rt_ctx, mat_slot, strain6, &
                                    stress_old6, stress_new6, D6, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    stress_new(1) = stress_new6(1)
    stress_new(2) = stress_new6(2)
    stress_new(3) = stress_new6(4)
    D_tangent = 0.0_wp
    D_tangent(1,1) = D6(1,1)
    D_tangent(1,2) = D6(1,2)
    D_tangent(2,1) = D6(2,1)
    D_tangent(2,2) = D6(2,2)
    D_tangent(3,3) = D6(4,4)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_ElasticPlaneStrain

  SUBROUTINE PH_Elem_MatRoute_ElasticPlaneStress(rt_ctx, mat_slot, dstrain, &
                                                 stress_old, stress_new, D_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    TYPE(PH_Mat_Elas_Desc) :: elas_desc
    TYPE(PH_Mat_Elas_State) :: elas_state
    REAL(wp) :: factor, shear_mod

    CALL PH_Elem_MatRoute_ValidateElasticSlot(rt_ctx, mat_slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_Elas_Init_From_Props(elas_desc, elas_state, &
                                     SIZE(mat_slot%desc%props), mat_slot%desc%props, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    factor = elas_desc%E / (1.0_wp - elas_desc%nu * elas_desc%nu)
    shear_mod = elas_desc%E / (2.0_wp * (1.0_wp + elas_desc%nu))
    D_tangent = 0.0_wp
    D_tangent(1,1) = factor
    D_tangent(1,2) = factor * elas_desc%nu
    D_tangent(2,1) = factor * elas_desc%nu
    D_tangent(2,2) = factor
    D_tangent(3,3) = shear_mod

    stress_new = stress_old + MATMUL(D_tangent, dstrain)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_ElasticPlaneStress

  SUBROUTINE PH_Elem_MatRoute_ElasticAxisymmetric(rt_ctx, mat_slot, dstrain, &
                                                  stress_old, stress_new, D_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain(4)
    REAL(wp),                  INTENT(IN)    :: stress_old(4)
    REAL(wp),                  INTENT(OUT)   :: stress_new(4)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(4, 4)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    REAL(wp) :: D6(6, 6)
    REAL(wp) :: strain6(6)
    REAL(wp) :: stress_old6(6)
    REAL(wp) :: stress_new6(6)
    INTEGER(i4) :: map4(4)
    INTEGER(i4) :: i, j

    map4 = (/ 1_i4, 2_i4, 3_i4, 4_i4 /)
    strain6 = 0.0_wp
    stress_old6 = 0.0_wp
    DO i = 1, 4
      strain6(map4(i)) = dstrain(i)
      stress_old6(map4(i)) = stress_old(i)
    END DO

    CALL PH_Elem_MatRoute_Elastic3D(rt_ctx, mat_slot, strain6, &
                                    stress_old6, stress_new6, D6, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    DO i = 1, 4
      stress_new(i) = stress_new6(map4(i))
      DO j = 1, 4
        D_tangent(i, j) = D6(map4(i), map4(j))
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_ElasticAxisymmetric

  SUBROUTINE PH_Elem_MatRoute_ThermoElastic3D(rt_ctx, mat_slot, dstrain_total, &
                                              thermal_strain, stress_old, stress_new, &
                                              D_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain_total(6)
    REAL(wp),                  INTENT(IN)    :: thermal_strain(6)
    REAL(wp),                  INTENT(IN)    :: stress_old(6)
    REAL(wp),                  INTENT(OUT)   :: stress_new(6)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(6, 6)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_Elastic3D(rt_ctx, mat_slot, dstrain_total - thermal_strain, &
                                    stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_MatRoute_ThermoElastic3D

  SUBROUTINE PH_Elem_MatRoute_ThermoElasticPlaneStrain(rt_ctx, mat_slot, dstrain_total, &
                                                       thermal_strain, stress_old, stress_new, &
                                                       D_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain_total(3)
    REAL(wp),                  INTENT(IN)    :: thermal_strain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticPlaneStrain(rt_ctx, mat_slot, dstrain_total - thermal_strain, &
                                             stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_MatRoute_ThermoElasticPlaneStrain

  SUBROUTINE PH_Elem_MatRoute_ThermoElasticPlaneStress(rt_ctx, mat_slot, dstrain_total, &
                                                       thermal_strain, stress_old, stress_new, &
                                                       D_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain_total(3)
    REAL(wp),                  INTENT(IN)    :: thermal_strain(3)
    REAL(wp),                  INTENT(IN)    :: stress_old(3)
    REAL(wp),                  INTENT(OUT)   :: stress_new(3)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(3, 3)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticPlaneStress(rt_ctx, mat_slot, dstrain_total - thermal_strain, &
                                             stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_MatRoute_ThermoElasticPlaneStress

  SUBROUTINE PH_Elem_MatRoute_ThermoElasticAxisymmetric(rt_ctx, mat_slot, dstrain_total, &
                                                        thermal_strain, stress_old, stress_new, &
                                                        D_tangent, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dstrain_total(4)
    REAL(wp),                  INTENT(IN)    :: thermal_strain(4)
    REAL(wp),                  INTENT(IN)    :: stress_old(4)
    REAL(wp),                  INTENT(OUT)   :: stress_new(4)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(4, 4)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_ElasticAxisymmetric(rt_ctx, mat_slot, &
                                              dstrain_total - thermal_strain, &
                                              stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_MatRoute_ThermoElasticAxisymmetric

  SUBROUTINE PH_Elem_MatRoute_ValidateElasticSlot(rt_ctx, mat_slot, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    INTEGER(i4) :: mid, ph_fam

    CALL PH_Elem_MatRoute_ValidateRtCtx(rt_ctx, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (.NOT. mat_slot%active .OR. rt_ctx%mat_pt_idx <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: inactive material slot"
      RETURN
    END IF

    mid = mat_slot%desc%cfg%matId
    IF (rt_ctx%mat_id /= mid) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: material id mismatch (rt_ctx vs slot desc)"
      RETURN
    END IF

    ph_fam = PH_Mat_Desc_Effective_Model(mat_slot%desc)
    IF (ph_fam /= PH_MAT_ELASTIC) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: only elastic slot is supported"
      RETURN
    END IF

    IF (.NOT. ALLOCATED(mat_slot%desc%props)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: material props missing"
      RETURN
    END IF

    IF (SIZE(mat_slot%desc%props) < 2) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: material props missing"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_ValidateElasticSlot

  SUBROUTINE PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    INTEGER(i4) :: mid

    CALL PH_Elem_MatRoute_ValidateRtCtx(rt_ctx, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (.NOT. mat_slot%active .OR. rt_ctx%mat_pt_idx <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: inactive scalar material slot"
      RETURN
    END IF

    mid = mat_slot%desc%cfg%matId
    IF (rt_ctx%mat_id /= mid) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: scalar material id mismatch (rt_ctx vs slot desc)"
      RETURN
    END IF

    IF (.NOT. ALLOCATED(mat_slot%desc%props)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: scalar material props missing"
      RETURN
    END IF

    IF (SIZE(mat_slot%desc%props) < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: scalar material props missing"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_ValidateScalarSlot

  ! L4-only routing ctx check (mirrors RT_Mat_Dispatch_Stress without material_dom).
  SUBROUTINE PH_Elem_MatRoute_ValidateRtCtx(rt_ctx, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (rt_ctx%mat_type <= 0_i4) THEN
      rt_ctx%route_status = IF_MAT_ROUTE_NOT_FOUND
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: invalid mat_type in dispatch ctx"
      RETURN
    END IF

    IF (rt_ctx%mat_pt_idx <= 0_i4) THEN
      rt_ctx%route_status = IF_MAT_ROUTE_NO_KERNEL
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Elem_MatRoute: invalid mat_pt_idx in dispatch ctx"
      RETURN
    END IF

    rt_ctx%route_status = IF_MAT_ROUTE_OK
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_MatRoute_ValidateRtCtx

END MODULE PH_Elem_MaterialRoute


