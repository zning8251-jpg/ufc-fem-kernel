!===============================================================================
! MODULE: PH_MatPLM_Kernels
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Dispatch
! BRIEF:  Plastic UMAT kernel aggregate re-export for PH_MatPLMEval.
!   W1: kernels consume **UMAT** bundles from **PH_MatPLMEval**; slot-level
!   **PH_Mat_Desc** remains upstream（Populate / **PH_Mat_Core**）.
!===============================================================================

MODULE PH_MatPLM_Kernels
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_NOT_FOUND
    USE PH_Mat_Plast_Hill_Core, ONLY: UF_Hill_UMAT, UF_Hill_UMAT_Arg
    USE PH_Mat_Geo_MohrCoulomb_Core, ONLY: UF_MohrCoulomb_UMAT
    USE PH_Mat_Plast_Chaboche_Core, ONLY: UF_Chaboche_UMAT, UF_Chaboche_UMAT_Arg
    USE PH_Mat_Plast_Crystal_Core, ONLY: UF_CrystalPlasticity_UMAT, UF_CrystalPlasticity_UMAT_Arg
    USE PH_Mat_Comp_Cast_Core, ONLY: UF_CastIron_UMAT
    USE PH_MatPLM_LegacyFacadeUMATs, ONLY: UF_FGM_UMAT, UF_Geotechnical_UMAT, UF_SmartMaterial_UMAT, &
        UF_MultiscaleDamage_UMAT, UF_ThermoElectroMagnetoMechanical_UMAT, UF_ThermoViscoplastic_UMAT, &
        UF_ViscoelasticDamage_UMAT
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: UF_Hill_UMAT, UF_Hill_UMAT_Arg, UF_DruckerPrager_UMAT, UF_CamClay_UMAT, UF_MohrCoulomb_UMAT, &
        UF_JohnsonCook_UMAT, UF_Gurson_UMAT, UF_Chaboche_UMAT, UF_Chaboche_UMAT_Arg, &
        UF_CapPlasticity_UMAT, UF_CrushableFoam_UMAT, UF_CastIron_UMAT, &
        UF_SoftRock_UMAT, UF_Foam3Stage_UMAT, UF_Ceramic_UMAT, &
        UF_Viscoplastic_UMAT, UF_ViscoplasticDamageEM_UMAT, UF_Nanomaterial_UMAT, UF_FGM_UMAT, &
        UF_SmartMaterial_UMAT, UF_ViscoelasticDamage_UMAT, UF_ThermoViscoplastic_UMAT, &
        UF_MultiscaleDamage_UMAT, UF_ThermoElectroMagnetoMechanical_UMAT, &
        UF_Geotechnical_UMAT, UF_CrystalPlasticity_UMAT, UF_CrystalPlasticity_UMAT_Arg, &
        UF_RateDependentPlasticity_UMAT, &
        UF_ZerilliArmstrong_UMAT
CONTAINS

    SUBROUTINE UF_DruckerPrager_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_DruckerPrager_UMAT: legacy module removed"
    END SUBROUTINE UF_DruckerPrager_UMAT

    SUBROUTINE UF_CamClay_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_CamClay_UMAT: legacy module removed"
    END SUBROUTINE UF_CamClay_UMAT

    SUBROUTINE UF_JohnsonCook_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_JohnsonCook_UMAT: legacy module removed"
    END SUBROUTINE UF_JohnsonCook_UMAT

    SUBROUTINE UF_Gurson_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_Gurson_UMAT: legacy module removed"
    END SUBROUTINE UF_Gurson_UMAT

    SUBROUTINE UF_CapPlasticity_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    END SUBROUTINE UF_CapPlasticity_UMAT

    SUBROUTINE UF_CrushableFoam_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    END SUBROUTINE UF_CrushableFoam_UMAT

    SUBROUTINE UF_SoftRock_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_SoftRock_UMAT: legacy module removed"
    END SUBROUTINE UF_SoftRock_UMAT

    SUBROUTINE UF_Foam3Stage_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_Foam3Stage_UMAT: legacy module removed"
    END SUBROUTINE UF_Foam3Stage_UMAT

    SUBROUTINE UF_Ceramic_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_Ceramic_UMAT: legacy module removed"
    END SUBROUTINE UF_Ceramic_UMAT

    SUBROUTINE UF_Viscoplastic_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_Viscoplastic_UMAT: legacy module removed"
    END SUBROUTINE UF_Viscoplastic_UMAT

    SUBROUTINE UF_RateDependentPlasticity_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_RateDependentPlasticity_UMAT: legacy module removed"
    END SUBROUTINE UF_RateDependentPlasticity_UMAT

    SUBROUTINE UF_ZerilliArmstrong_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_ZerilliArmstrong_UMAT: legacy module removed"
    END SUBROUTINE UF_ZerilliArmstrong_UMAT

    SUBROUTINE UF_ViscoplasticDamageEM_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_ViscoplasticDamageEM_UMAT: legacy module removed"
    END SUBROUTINE UF_ViscoplasticDamageEM_UMAT

    SUBROUTINE UF_Nanomaterial_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
        stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc, status)
        REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
        REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
        REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
        INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "UF_Nanomaterial_UMAT: legacy module removed"
    END SUBROUTINE UF_Nanomaterial_UMAT

END MODULE PH_MatPLM_Kernels