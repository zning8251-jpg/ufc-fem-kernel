!===============================================================================
! MODULE: PH_MatPLMEval
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Eval
! BRIEF:  Plastic constitutive dispatch and legacy UMAT wrappers (LEGACY).
!   W1 gold path: orchestration uses **PH_Mat_Core** + L4 slot **PH_Mat_Desc**
!   (**cfg%matModel** + **PH_Mat_Desc_SyncDeprecatedFlat**, **desc%props**).
!   This module keeps **PlastModels_Desc** + **MatEval_Ctx** UMAT dispatch for
!   mat_id 201+ legacy kernels — do not fold **PH_Mat_Desc** here without a
!   dedicated migration MR.
!===============================================================================

MODULE PH_MatPLMEval
    USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_NOT_FOUND, IF_STATUS_OK, &
        init_error_status
    USE IF_Prec_Core, ONLY: i4, wp
    USE MD_Mat_Brg, ONLY: MD_Mat_PH_UMAT_In, MD_Mat_PH_UMAT_Out, UF_PH_UMAT_Dispatch
    USE MD_Mat_Eval_Types, ONLY: MatEval_Ctx, MatAlgo_Algo
    ! Legacy stub constants (modules MD_MATLIB_PLAST_* deleted)
    INTEGER(i4), PARAMETER :: PH_MAT_CRUSHABLE_FOAM = 222_i4
    USE MD_Mat_Plast_Reg, ONLY: PlastModels_Desc, UF_Plastic_InitReg, MD_MAT_PLAST_MAX_PROPS
    USE IF_Mem_Algo, ONLY: IF_Mem_Algo_Scratch_Real1D, IF_Mem_Algo_Release_Real1D
    USE PH_MatPLM_Kernels, ONLY: &
        UF_Hill_UMAT, UF_Hill_UMAT_Arg, UF_DruckerPrager_UMAT, UF_CamClay_UMAT, UF_MohrCoulomb_UMAT, &
        UF_JohnsonCook_UMAT, UF_Gurson_UMAT, UF_Chaboche_UMAT, &
        UF_CapPlasticity_UMAT, UF_CrushableFoam_UMAT, UF_CastIron_UMAT, &
        UF_SoftRock_UMAT, UF_Foam3Stage_UMAT, UF_Ceramic_UMAT, &
        UF_Viscoplastic_UMAT, UF_ViscoplasticDamageEM_UMAT, UF_Nanomaterial_UMAT, UF_FGM_UMAT, &
        UF_SmartMaterial_UMAT, UF_ViscoelasticDamage_UMAT, UF_ThermoViscoplastic_UMAT, &
        UF_MultiscaleDamage_UMAT, UF_ThermoElectroMagnetoMechanical_UMAT, &
        UF_Geotechnical_UMAT, UF_CrystalPlasticity_UMAT, UF_RateDependentPlasticity_UMAT, &
        UF_ZerilliArmstrong_UMAT

    ! Legacy mat_id constants (modules MD_MatPLM_* / MD_MatPOR_* deleted)
    INTEGER(i4), PARAMETER :: PH_MAT_VONMISES_MAT_ID = 201_i4
    INTEGER(i4), PARAMETER :: PH_MAT_HILL_MAT_ID = 205_i4
    INTEGER(i4), PARAMETER :: PH_MAT_DRUCKERPRAGER_M = 202_i4
    INTEGER(i4), PARAMETER :: PH_MAT_CAMCLAY_MAT_ID = 203_i4
    INTEGER(i4), PARAMETER :: PH_MAT_MOHRCOULOMB_MAT = 204_i4
    INTEGER(i4), PARAMETER :: PH_MAT_JOHNSONCOOK_MAT = 206_i4
    INTEGER(i4), PARAMETER :: PH_MAT_GURSON_MAT_ID = 207_i4
    INTEGER(i4), PARAMETER :: PH_MAT_CHABOCHE_MAT_ID = 210_i4
    INTEGER(i4), PARAMETER :: PH_MAT_CAP_PLASTICITY = 221_i4
    INTEGER(i4), PARAMETER :: PH_MAT_CRUSHFOAM_MAT_ID = 212_i4
    INTEGER(i4), PARAMETER :: PH_MAT_CAST_IRON_MAT_I = 223_i4
    INTEGER(i4), PARAMETER :: PH_MAT_SOFTROCK_MAT_ID = 215_i4
    INTEGER(i4), PARAMETER :: PH_MAT_VISCOPLASTIC_MAT_ID = 250_i4
    INTEGER(i4), PARAMETER :: PH_MAT_FOAM3_STAGE_MAT_ID = 214_i4
    INTEGER(i4), PARAMETER :: PH_MAT_CRYSTAL_PLASTICITY_MAT_ID = 266_i4
    INTEGER(i4), PARAMETER :: PH_MAT_RATE_DEPENDENT_PLAST_MAT_ID = 267_i4
    INTEGER(i4), PARAMETER :: PH_MAT_ZERILLI_ARMSTRONG_MAT_ID = 268_i4

    IMPLICIT NONE
    PRIVATE
    INTEGER(i4), PARAMETER :: PH_MAT_LEGACY_UMAT_201 = 201_i4
    INTEGER(i4), PARAMETER :: PH_MAT_LEGACY_UMAT_202 = 202_i4
    INTEGER(i4), PARAMETER :: PH_MAT_LEGACY_UMAT_203 = 203_i4
    INTEGER(i4), PARAMETER :: PH_MAT_LEGACY_UMAT_204 = 204_i4
    INTEGER(i4), PARAMETER :: PH_MAT_LEGACY_UMAT_212 = 212_i4
    INTEGER(i4), PARAMETER :: PH_MAT_LEGACY_UMAT_231 = 231_i4
    PUBLIC :: UF_Plastic_Eval_Dispatch, UF_Plastic_UMAT_Dispatch
    PUBLIC :: UF_Plastic_UMAT_Wrapper, PH_MAT_UMAT_Plastic_Dispatch, UF_Plastic_GetLegacyID
    PUBLIC :: UF_Plastic_Legacy_VonMises, UF_Plastic_Legacy_Hill, UF_Plastic_Legacy_CamClay
    PUBLIC :: UF_Plastic_Leg_MohrCoulomb, UF_Plastic_Leg_ConcreteDmg, UF_Plastic_Leg_DruckerPrager
    PUBLIC :: UF_Plastic_Legacy_SoftRock, UF_Plastic_Legacy_Cap, UF_Plastic_Leg_CrushableFoam
    PUBLIC :: UF_Plastic_Legacy_CastIron, UF_Plastic_Leg_JohnsonCook, UF_Plastic_Legacy_Gurson
    PUBLIC :: UF_Plastic_Legacy_Chaboche, UF_Plastic_Leg_CompProgressive, UF_Plastic_Legacy_Foam3Stage
    PUBLIC :: UF_Plastic_Leg_Biomaterial, UF_Plastic_Legacy_Ceramic, UF_Plastic_Leg_ViscoplasticDmgEM
    PUBLIC :: UF_Plastic_Leg_Nanomaterial, UF_Plastic_Legacy_FGM, UF_Plastic_Leg_SmartMat
    PUBLIC :: UF_Plastic_Leg_ViscoelasticDmg, UF_Plastic_Leg_ThermoViscoplastic
    PUBLIC :: UF_Plastic_Leg_MultiscaleDmg, UF_Plastic_Leg_ThermoElectroMagneto
    PUBLIC :: UF_Plastic_Leg_PuckComp, UF_Plastic_Leg_Geotechnical, UF_Plastic_Leg_HashinComp

CONTAINS

  !---------------------------------------------------------------------------
  ! UF_Plastic_Eval_Dispatch: struct-only dispatch (plm_in+ctx+algo)
  !   Calls each model's UMAT internally, unpacking/repacking ctx.
  !---------------------------------------------------------------------------
  SUBROUTINE UF_Plastic_Eval_Dispatch(material_id, plm_in, ctx, algo, status)
    INTEGER(i4),           INTENT(IN)    :: material_id
    TYPE(PlastModels_Desc),INTENT(IN)    :: plm_in
    TYPE(MatEval_Ctx),     INTENT(INOUT) :: ctx
    TYPE(MatAlgo_Algo),    INTENT(IN)    :: algo
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    REAL(wp) :: stress_loc(6), statev_loc(50)
    REAL(wp) :: ddsdde_loc(6,6)
    REAL(wp) :: sse_loc, spd_loc, scd_loc, rpl_loc
    REAL(wp) :: ddsddt_loc(6), drplde_loc(6), drpldt_loc
    TYPE(MD_Mat_PH_UMAT_In)  :: in_struct
    TYPE(MD_Mat_PH_UMAT_Out) :: out_struct
    INTEGER(i4) :: ntens, nstatv, np
    INTEGER(i4) :: plm_scratch_id
    REAL(wp), POINTER :: plm_scratch(:)
    CALL init_error_status(status)
    CALL UF_Plastic_InitReg(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    ntens  = ctx%ntens
    nstatv = ctx%nstatv
    np     = plm_in%nprops
    ! Phase6 Track21: scratch facade touch (Populate/Dispatch boundary).
    CALL IF_Mem_Algo_Scratch_Real1D(1_i4, 'PH_PLM_dispatch_anchor', plm_scratch, plm_scratch_id, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      CALL IF_Mem_Algo_Release_Real1D(plm_scratch_id, status)
    END IF
    CALL init_error_status(status)
    stress_loc  = 0.0_wp
    stress_loc(1:ntens) = ctx%stress(1:ntens)
    statev_loc = 0.0_wp
    IF (nstatv > 0) statev_loc(1:MIN(nstatv,50)) = ctx%statev(1:MIN(nstatv,50))
    sse_loc = ctx%sse
    spd_loc = 0.0_wp; scd_loc = 0.0_wp; rpl_loc = 0.0_wp
    ddsddt_loc = 0.0_wp; drplde_loc = 0.0_wp; drpldt_loc = 0.0_wp
    ! Phase6 Track21: consolidate legacy UMAT buffer alloc outside CASE (one shot per eval).
    IF (np > 0_i4) THEN
      ASSOCIATE (um_pack => in_struct%desc)
      IF (.NOT. ALLOCATED(um_pack%props)) ALLOCATE(um_pack%props(np))
      um_pack%props(1:np) = plm_in%props(1:np)
      END ASSOCIATE
    END IF
    IF (.NOT. ALLOCATED(in_struct%state%stress)) ALLOCATE(in_struct%state%stress(6))
    IF (nstatv > 0_i4) THEN
      IF (.NOT. ALLOCATED(in_struct%state%statev)) ALLOCATE(in_struct%state%statev(nstatv))
    END IF
    IF (.NOT. ALLOCATED(in_struct%state%stran)) ALLOCATE(in_struct%state%stran(6))
    IF (.NOT. ALLOCATED(in_struct%state%dstran)) ALLOCATE(in_struct%state%dstran(6))
    IF (.NOT. ALLOCATED(in_struct%state%ddsdde)) ALLOCATE(in_struct%state%ddsdde(6, 6))
    IF (.NOT. ALLOCATED(in_struct%state%ddsddt)) ALLOCATE(in_struct%state%ddsddt(6))
    IF (.NOT. ALLOCATED(in_struct%state%drplde)) ALLOCATE(in_struct%state%drplde(6))
    IF (.NOT. ALLOCATED(out_struct%state%stress)) ALLOCATE(out_struct%state%stress(6))
    IF (nstatv > 0_i4) THEN
      IF (.NOT. ALLOCATED(out_struct%state%statev)) ALLOCATE(out_struct%state%statev(nstatv))
    END IF
    IF (.NOT. ALLOCATED(out_struct%state%ddsdde)) ALLOCATE(out_struct%state%ddsdde(6, 6))
    IF (.NOT. ALLOCATED(out_struct%state%ddsddt)) ALLOCATE(out_struct%state%ddsddt(6))
    IF (.NOT. ALLOCATED(out_struct%state%drplde)) ALLOCATE(out_struct%state%drplde(6))
    SELECT CASE (material_id)
    CASE (PH_MAT_VONMISES_MAT_ID)
      ASSOCIATE (um_pack => in_struct%desc)
      um_pack%material_id = material_id
      um_pack%nprops = np
      um_pack%props(1:np) = plm_in%props(1:np)
      END ASSOCIATE
      in_struct%algo%ndir = ctx%ndi
      in_struct%algo%nshr = ctx%nshr
      in_struct%algo%ntens = ntens
      in_struct%algo%cfg%ndim = ctx%cfg%ndim
      in_struct%ctx%time = ctx%time
      in_struct%ctx%dtime = ctx%dtime
      in_struct%ctx%temp = ctx%temp
      in_struct%ctx%dtemp = ctx%dtemp
      in_struct%ctx%kstep = algo%kstep
      in_struct%ctx%kinc  = algo%kinc
      in_struct%state%nstatev = nstatv
      in_struct%state%stress  = stress_loc
      in_struct%state%statev = statev_loc(1:nstatv)
      in_struct%state%stran  = ctx%stran
      in_struct%state%dstran = ctx%dstran
      CALL UF_PH_UMAT_Dispatch(in_struct, out_struct)
          stress_loc = out_struct%state%stress
      IF (nstatv > 0) statev_loc(1:nstatv) = out_struct%state%statev
      ddsdde_loc = out_struct%state%ddsdde
      sse_loc = out_struct%state%sse
      spd_loc = out_struct%state%spd
      scd_loc = out_struct%state%scd
      rpl_loc = out_struct%state%rpl
      IF (ALLOCATED(out_struct%state%ddsddt)) ddsddt_loc = out_struct%state%ddsddt
      IF (ALLOCATED(out_struct%state%drplde)) drplde_loc = out_struct%state%drplde
      drpldt_loc = out_struct%state%drpldt
      status = out_struct%status
    CASE (PH_MAT_HILL_MAT_ID)
      BLOCK
        TYPE(UF_Hill_UMAT_Arg) :: hill_arg
        INTEGER(i4) :: nsv_hill
        nsv_hill = MIN(MAX(nstatv, 0_i4), SIZE(hill_arg%statev, KIND=i4))
        hill_arg%stress = stress_loc
        hill_arg%nstatev = nsv_hill
        IF (nsv_hill > 0) hill_arg%statev(1:nsv_hill) = statev_loc(1:nsv_hill)
        hill_arg%stran = ctx%stran
        hill_arg%dstran = ctx%dstran
        hill_arg%time = ctx%time
        hill_arg%dtime = ctx%dtime
        hill_arg%temp = ctx%temp
        hill_arg%dtemp = ctx%dtemp
        hill_arg%ndir = ctx%ndi
        hill_arg%nshr = ctx%nshr
        hill_arg%ndim = ctx%cfg%ndim
        hill_arg%kstep = algo%kstep
        hill_arg%kinc = algo%kinc
        hill_arg%nprops = np
        IF (np > 0) hill_arg%props(1:np) = plm_in%props(1:np)
        hill_arg%sse = sse_loc
        CALL init_error_status(hill_arg%status)
        CALL UF_Hill_UMAT(hill_arg)
        stress_loc = hill_arg%stress
        ddsdde_loc = hill_arg%ddsdde
        sse_loc = hill_arg%sse
        spd_loc = hill_arg%spd
        scd_loc = hill_arg%scd
        rpl_loc = hill_arg%rpl
        ddsddt_loc = hill_arg%ddsddt
        drplde_loc = hill_arg%drplde
        drpldt_loc = hill_arg%drpldt
        IF (nsv_hill > 0) statev_loc(1:nsv_hill) = hill_arg%statev(1:nsv_hill)
        status = hill_arg%status
      END BLOCK
    CASE (PH_MAT_DRUCKERPRAGER_M)
      CALL UF_DruckerPrager_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_CAMCLAY_MAT_ID)
      CALL UF_CamClay_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_MOHRCOULOMB_MAT)
      CALL UF_MohrCoulomb_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_JOHNSONCOOK_MAT)
      CALL UF_JohnsonCook_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_GURSON_MAT_ID)
      CALL UF_Gurson_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_CHABOCHE_MAT_ID)
      CALL UF_Chaboche_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_CAP_PLASTICITY, 221_i4)
      CALL UF_CapPlasticity_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc)
      status%status_code = IF_STATUS_OK
    CASE (PH_MAT_CRUSHABLE_FOAM, PH_MAT_CRUSHFOAM_MAT_ID, 222_i4)
      CALL UF_CrushableFoam_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc)
      status%status_code = IF_STATUS_OK
    CASE (PH_MAT_CAST_IRON_MAT_I, 223_i4)
      CALL UF_CastIron_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc)
      status%status_code = IF_STATUS_OK
    CASE (205_i4)
      CALL UF_ConcreteDamage_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_SOFTROCK_MAT_ID)
      CALL UF_SoftRock_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_VISCOPLASTIC_MAT_ID)
      CALL UF_Viscoplastic_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (251_i4)
      CALL UF_CompProgDmg_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_FOAM3_STAGE_MAT_ID)
      CALL UF_Foam3Stage_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (253_i4)
      CALL UF_Biomaterial_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (254_i4)
      CALL UF_Ceramic_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (255_i4)
      CALL UF_ViscoplasticDamageEM_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (256_i4)
      CALL UF_Nanomaterial_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (257_i4)
      CALL UF_FGM_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (258_i4)
      CALL UF_SmartMaterial_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (259_i4)
      CALL UF_ViscoelasticDamage_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (260_i4)
      CALL UF_ThermoViscoplastic_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (261_i4)
      CALL UF_MultiscaleDamage_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (262_i4)
      CALL UF_ThermoElectroMagnetoMechanical_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (263_i4)
      CALL UF_PuckCompositeDamage_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (264_i4)
      CALL UF_Geotechnical_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (265_i4)
      CALL UF_HashinCompDmg_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_CRYSTAL_PLASTICITY_MAT_ID)
      CALL UF_CrystalPlasticity_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_RATE_DEPENDENT_PLAST_MAT_ID)
      CALL UF_RateDependentPlasticity_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE (PH_MAT_ZERILLI_ARMSTRONG_MAT_ID)
      CALL UF_ZerilliArmstrong_UMAT(stress_loc, statev_loc(1:MAX(nstatv,1)), ddsdde_loc, sse_loc, spd_loc, scd_loc, &
           rpl_loc, ddsddt_loc, drplde_loc, drpldt_loc, ctx%stran, ctx%dstran, ctx%time, ctx%dtime, &
           ctx%temp, ctx%dtemp, [0.0_wp], [0.0_wp], ctx%ndi, ctx%nshr, MAX(nstatv,1), np, &
           plm_in%props(1:np), ctx%cfg%ndim, algo%kstep, algo%kinc, status)
    CASE DEFAULT
      status%status_code = IF_STATUS_NOT_FOUND
      status%message = "Unknown plastic Mat ID"
      RETURN
    END SELECT
    IF (status%status_code /= IF_STATUS_OK) RETURN
    ! Write back to ctx
        ctx%stress(1:ntens)         = stress_loc(1:ntens)
    ctx%ddsdde(1:ntens,1:ntens) = ddsdde_loc(1:ntens,1:ntens)
    ctx%sse                     = sse_loc
    IF (nstatv > 0) ctx%statev(1:MIN(nstatv,50)) = statev_loc(1:MIN(nstatv,50))
  END SUBROUTINE UF_Plastic_Eval_Dispatch

  !---------------------------------------------------------------------------
  ! UF_Plastic_UMAT_Dispatch: legacy UMAT interface -> packs ctx -> Eval_Dispatch
  !---------------------------------------------------------------------------
  SUBROUTINE UF_Plastic_UMAT_Dispatch(material_id, stress, statev, ddsdde, &
                                       sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
                                       stran, dstran, time, dtime, temp, dtemp, &
                                       predef, dpred, ndir, nshr, nstatev, nprops, &
                                       props, ndim, kstep, kinc, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    REAL(wp), INTENT(OUT) :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6)
    REAL(wp), INTENT(IN) :: time(2), dtime
    REAL(wp), INTENT(IN) :: temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(PlastModels_Desc) :: plm_wrk
    TYPE(MatEval_Ctx)      :: ctx
    TYPE(MatAlgo_Algo)     :: algo
    INTEGER(i4) :: np
    CALL init_error_status(status)
    CALL UF_Plastic_InitReg(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    ! Pack Desc
    np = MIN(nprops, SIZE(plm_wrk%props, KIND=i4))
    plm_wrk%nprops = np
    IF (np > 0) plm_wrk%props(1:np) = props(1:np)
    ! Pack ctx
    ctx%ndi    = ndir
    ctx%nshr   = nshr
    ctx%ntens  = ndir + nshr
    ctx%cfg%ndim   = ndim
    ctx%nstatv = nstatev
    ctx%stress(1:6)   = stress(1:6)
    ctx%stran(1:6)    = stran(1:6)
    ctx%dstran(1:6)   = dstran(1:6)
    ctx%sse    = sse
    ctx%time(1:2) = time(1:2)
    ctx%dtime  = dtime
    ctx%temp   = temp
    ctx%dtemp  = dtemp
    IF (nstatev > 0) ctx%statev(1:nstatev) = statev(1:nstatev)
    ! Pack algo
    algo%kstep = kstep
    algo%kinc  = kinc
    CALL UF_Plastic_Eval_Dispatch(material_id, plm_wrk, ctx, algo, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    ! Unpack ctx
    stress(1:6)        = ctx%stress(1:6)
    ddsdde(1:6,1:6)   = ctx%ddsdde(1:6,1:6)
    sse               = ctx%sse
    IF (nstatev > 0) statev(1:nstatev) = ctx%statev(1:nstatev)
  END SUBROUTINE UF_Plastic_UMAT_Dispatch


  SUBROUTINE Plast_Legacy_Invoke(material_id, stress, statev, ddsdde, sse, spd, scd, &
                                  rpl, ddsddt, drplde, drpldt, &
                                  stran, dstran, time, dtime, temp, dtemp, &
                                  predef, dpred, ndir, nshr, nstatev, nprops, &
                                  props, ndim, kstep, kinc)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    REAL(wp), INTENT(OUT) :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6)
    REAL(wp), INTENT(IN) :: time(2), dtime
    REAL(wp), INTENT(IN) :: temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN) :: props(*)
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: mid
    mid = UF_Plastic_GetLegacyID(material_id)
    CALL UF_Plastic_UMAT_Dispatch(mid, stress, statev(1:nstatev), ddsdde, sse, spd, scd, &
                                  rpl, ddsddt, drplde, drpldt, &
                                  stran, dstran, time, dtime, temp, dtemp, &
                                  predef, dpred, INT(ndir,i4), INT(nshr,i4), INT(nstatev,i4), INT(nprops,i4), &
                                  props, INT(ndim,i4), INT(kstep,i4), INT(kinc,i4), status)
  END SUBROUTINE Plast_Legacy_Invoke

  SUBROUTINE UF_Plastic_Leg_CompProgressive(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(251_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_CompProgressive

  SUBROUTINE UF_Plastic_Leg_ThermoElectroMagneto(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(262_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_ThermoElectroMagneto

  SUBROUTINE UF_Plastic_Leg_ThermoViscoplastic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(260_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_ThermoViscoplastic

  SUBROUTINE UF_Plastic_Leg_ViscoelasticDmg(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(259_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_ViscoelasticDmg

  SUBROUTINE UF_Plastic_Leg_ViscoplasticDmgEM(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(255_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_ViscoplasticDmgEM

  FUNCTION UF_Plastic_GetLegacyID(legacy_id) RESULT(new_id)
    !! Map legacy Mat IDs to new unified IDs

    INTEGER(i4), INTENT(IN) :: legacy_id
    INTEGER(i4) :: new_id

    SELECT CASE (legacy_id)
    CASE (PH_MAT_LEGACY_UMAT_201)
      new_id = PH_MAT_VONMISES_MAT_ID
    CASE (PH_MAT_LEGACY_UMAT_202)
      new_id = PH_MAT_HILL_MAT_ID
    CASE (PH_MAT_LEGACY_UMAT_203)
      new_id = PH_MAT_CAMCLAY_MAT_ID
    CASE (PH_MAT_LEGACY_UMAT_204)
      new_id = PH_MAT_MOHRCOULOMB_MAT
    CASE (PH_MAT_LEGACY_UMAT_212)
      new_id = PH_MAT_DRUCKERPRAGER_M
    CASE (PH_MAT_LEGACY_UMAT_231)
      new_id = PH_MAT_JOHNSONCOOK_MAT
    CASE DEFAULT
      ! Use as-is if no mapping found
      new_id = legacy_id
    END SELECT

  END FUNCTION UF_Plastic_GetLegacyID

  SUBROUTINE UF_Plastic_Leg_Biomaterial(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(253_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_Biomaterial

  SUBROUTINE UF_Plastic_Leg_ConcreteDmg(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(205_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_ConcreteDmg

  SUBROUTINE UF_Plastic_Leg_CrushableFoam(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(222_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_CrushableFoam

  SUBROUTINE UF_Plastic_Leg_DruckerPrager(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(212_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_DruckerPrager

  SUBROUTINE UF_Plastic_Leg_Geotechnical(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(264_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_Geotechnical

  SUBROUTINE UF_Plastic_Leg_HashinComp(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(265_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_HashinComp

  SUBROUTINE UF_Plastic_Leg_JohnsonCook(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(231_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_JohnsonCook

  SUBROUTINE UF_Plastic_Leg_MohrCoulomb(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(204_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_MohrCoulomb

  SUBROUTINE UF_Plastic_Leg_MultiscaleDmg(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(261_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_MultiscaleDmg

  SUBROUTINE UF_Plastic_Leg_Nanomaterial(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(256_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_Nanomaterial

  SUBROUTINE UF_Plastic_Leg_PuckComp(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(263_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_PuckComp

  SUBROUTINE UF_Plastic_Leg_SmartMat(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(258_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Leg_SmartMat

  SUBROUTINE UF_Plastic_Legacy_CamClay(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(203_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_CamClay

  SUBROUTINE UF_Plastic_Legacy_Cap(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(PH_MAT_CAP_PLASTICITY, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_Cap

  SUBROUTINE UF_Plastic_Legacy_CastIron(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(PH_MAT_CAST_IRON_MAT_I, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_CastIron

  SUBROUTINE UF_Plastic_Legacy_Ceramic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(254_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_Ceramic

  SUBROUTINE UF_Plastic_Legacy_Chaboche(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(242_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_Chaboche

  SUBROUTINE UF_Plastic_Legacy_FGM(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(257_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_FGM

  SUBROUTINE UF_Plastic_Legacy_Foam3Stage(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(PH_MAT_FOAM3_STAGE_MAT_ID, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_Foam3Stage

  SUBROUTINE UF_Plastic_Legacy_Gurson(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(241_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_Gurson

  SUBROUTINE UF_Plastic_Legacy_Hill(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(202_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_Hill

  SUBROUTINE UF_Plastic_Legacy_SoftRock(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(PH_MAT_SOFTROCK_MAT_ID, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_SoftRock

  SUBROUTINE UF_Plastic_Legacy_VonMises(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL Plast_Legacy_Invoke(201_i4, stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
  END SUBROUTINE UF_Plastic_Legacy_VonMises


  SUBROUTINE UF_Plastic_UMAT_Wrapper(material_id, stress, statev, ddsdde, &
                                      sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
                                      stran, dstran, time, dtime, temp, dtemp, &
                                      predef, dpred, ndir, nshr, nstatev, nprops, &
                                      props, ndim, kstep, kinc, status)
    !! Wrapper for legacy UMAT interface (without status parameter)
    !! This provides backward compatibility with existing code

    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    REAL(wp), INTENT(OUT) :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6)
    REAL(wp), INTENT(IN) :: time(2), dtime
    REAL(wp), INTENT(IN) :: temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN) :: props(*)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: mapped_id

    ! Map legacy IDs to new IDs
    mapped_id = UF_Plastic_GetLegacyID(material_id)

    ! Call unified dispatch
    CALL UF_Plastic_UMAT_Dispatch(mapped_id, stress, statev, ddsdde, &
                                   sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
                                   stran, dstran, time, dtime, temp, dtemp, &
                                   predef, dpred, ndir, nshr, nstatev, nprops, &
                                   props, ndim, kstep, kinc, status)

  END SUBROUTINE UF_Plastic_UMAT_Wrapper

  SUBROUTINE PH_MAT_UMAT_Plastic_Dispatch(material_id, stress, statev, ddsdde, sse, spd, scd, &
                                  rpl, ddsddt, drplde, drpldt, &
                                  stran, dstran, time, dtime, temp, dtemp, &
                                  predef, dpred, ndir, nshr, nstatev, nprops, &
                                  props, ndim, kstep, kinc, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    REAL(wp), INTENT(OUT) :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6)
    REAL(wp), INTENT(IN) :: time(2), dtime
    REAL(wp), INTENT(IN) :: temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN) :: props(*)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: mid
    mid = UF_Plastic_GetLegacyID(material_id)
    CALL UF_Plastic_UMAT_Dispatch(mid, stress, statev(1:nstatev), ddsdde, sse, spd, scd, &
                                  rpl, ddsddt, drplde, drpldt, &
                                  stran, dstran, time, dtime, temp, dtemp, &
                                  predef, dpred, INT(ndir,i4), INT(nshr,i4), INT(nstatev,i4), INT(nprops,i4), &
                                  props, INT(ndim,i4), INT(kstep,i4), INT(kinc,i4), status)
  END SUBROUTINE PH_MAT_UMAT_Plastic_Dispatch

    ! 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
    ! Procedures from: MD_MAT_PLAST_SOFTROCK
    ! 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€


  !---------------------------------------------------------------------------
  ! Legacy UMAT stubs (modules MD_MATLIB_PLAST_* deleted in material cleanup)
  !---------------------------------------------------------------------------

  SUBROUTINE UF_ConcreteDamage_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_NOT_FOUND
    status%message = "UF_ConcreteDamage_UMAT: legacy module MD_MATLIB_PLAST_CONCDMG removed"
  END SUBROUTINE UF_ConcreteDamage_UMAT

  SUBROUTINE UF_CompProgDmg_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_NOT_FOUND
    status%message = "UF_CompProgDmg_UMAT: legacy module MD_MATLIB_PLAST_CPD removed"
  END SUBROUTINE UF_CompProgDmg_UMAT

  SUBROUTINE UF_PuckCompositeDamage_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_NOT_FOUND
    status%message = "UF_PuckCompositeDamage_UMAT: legacy module MD_MATLIB_PLAST_PUCKCD removed"
  END SUBROUTINE UF_PuckCompositeDamage_UMAT

  SUBROUTINE UF_HashinCompDmg_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_NOT_FOUND
    status%message = "UF_HashinCompDmg_UMAT: legacy module MD_MATLIB_PLAST_HASHINCD removed"
  END SUBROUTINE UF_HashinCompDmg_UMAT

  SUBROUTINE UF_Biomaterial_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_NOT_FOUND
    status%message = "UF_Biomaterial_UMAT: legacy module MD_MATLIB_PLAST_BIOMAT removed"
  END SUBROUTINE UF_Biomaterial_UMAT

END MODULE PH_MatPLMEval