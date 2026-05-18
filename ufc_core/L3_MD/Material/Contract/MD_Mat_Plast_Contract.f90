!===============================================================================
! MODULE: MD_MatPLM_DescBase
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Shared plastic Desc types (PlastMatBase, flow/state helpers).
!         Split from legacy monolithic L3 plastic registry for porous/geotech.
!         **W1**：**PlastMatBase** 为塑性 Desc 基石；**mat_id** 真源以各模型 **PARAMETER** 与
!         **`MD_Mat_Ids`** 为准（头内 **MD_MAT_PLASTIC_*** 为历史 yield 标签，勿与现行 ID 混同）。
!===============================================================================
MODULE MD_Mat_Plast_Contract
    USE IF_Err_Brg, ONLY: ErrorStatusType
    USE IF_Prec_Core, ONLY: i4, wp
    IMPLICIT NONE
    PRIVATE

    ! NOTE (yield-criterion tags, not the full mat_id registry):
    ! These INTEGERs were historically aligned with an early 201�?08 plastic ID band and are still
    ! used as yield_criterion selectors (e.g. MD_MAT_PLASTIC_VON_MIS in legacy VM helpers). Authoritative
    ! material IDs for registration and L4 dispatch are the per-model PARAMETERs (e.g. MD_MAT_CAMCLAY_MAT_ID=203,
    ! MD_MAT_GURSON_MAT_ID, MD_MAT_VONMISES_MAT_ID) and PH_Mat_Reg_Core. Do not assume MD_MAT_PLASTIC_* equals the current
    ! mat_id for every model without checking that model's MODULE.
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLASTIC_VON_MIS = 201_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLASTIC_HILL = 205_i4  ! MT-0.4: align with MD_MAT_HILL_MAT_ID / MAT_PLAST_ANISO_HIL
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLASTIC_DRUCKER = 203_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLASTIC_CAM_CLA = 204_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLASTIC_MOHR_CO = 303_i4  ! legacy yield tag; mat_id uses MD_MAT_MOHRCOULOMB_MAT / MAT_GEO_MC
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLASTIC_JOHNSON = 206_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLASTIC_GURSON = 207_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLASTIC_CHABOCH = 210_i4  ! MT-F2.x: MAT_PLAST_CHABOCHE

    TYPE, PUBLIC :: PlastStateVariables
        REAL(wp) :: eps_p_eqv = 0.0_wp
        REAL(wp), ALLOCATABLE :: eps_p(:, :)
        REAL(wp) :: alpha = 0.0_wp
        REAL(wp) :: kappa = 0.0_wp
        INTEGER(i4) :: n_statev = 0
    END TYPE PlastStateVariables

    TYPE, PUBLIC :: PlastHardeningRule
        INTEGER(i4) :: hardening_type = 0
        REAL(wp) :: H = 0.0_wp
        REAL(wp) :: sigma_y0 = 0.0_wp
        REAL(wp) :: sigma_y_inf = 0.0_wp
        REAL(wp) :: delta = 0.0_wp
    END TYPE PlastHardeningRule

    TYPE, PUBLIC :: PlastFlowRule
        INTEGER(i4) :: flow_type = 1
        REAL(wp) :: dilation_angle = 0.0_wp
    END TYPE PlastFlowRule

    TYPE, PUBLIC :: PlastMatBase
        INTEGER(i4) :: material_id = 0
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: yield_criterion = 0
        TYPE(PlastHardeningRule) :: hardening
        TYPE(PlastFlowRule) :: flow_rule
        REAL(wp), ALLOCATABLE :: props(:)
        INTEGER(i4) :: n_props = 0
    END TYPE PlastMatBase

    TYPE, PUBLIC :: ComputeDeviatoricStress_In
        REAL(wp) :: stress(6)
    END TYPE ComputeDeviatoricStress_In

    TYPE, PUBLIC :: ComputeDeviatoricStress_Out
        REAL(wp) :: s_dev(6)
    END TYPE ComputeDeviatoricStress_Out

    TYPE, PUBLIC :: ComputeFlowDirection_In
        REAL(wp) :: stress(6)
        TYPE(PlastMatBase) :: mat
    END TYPE ComputeFlowDirection_In

    TYPE, PUBLIC :: ComputeFlowDirection_Out
        REAL(wp) :: flow_direction(6)
        TYPE(ErrorStatusType) :: status
    END TYPE ComputeFlowDirection_Out

END MODULE MD_Mat_Plast_Contract