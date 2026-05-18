!===============================================================================
! MODULE: MD_MatELA_ElasCall
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Dispatch
! BRIEF:  Elastic family dispatch -- routes elastic evaluation calls
!         to iso/ortho/transIso/aniso/porous sub-models.
! **W1**：**弹性 FromDesc/Dispatch**；**`MD_Mat_Desc`/`desc%props`** + **`SyncDeprecatedFlat`**；
!         **`UF_Elastic_Eval_Dispatch_FromDesc`** 与 **`MD_Mat_ValidatePropsForPopulate`** 弹性支路 **`material_id`** 一致；**`MD_Mat_Lib`** 再导出。
!===============================================================================
MODULE MD_Mat_Elas_Dispatch
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_NOT_FOUND, MD_MAT_STATUS_OK, init_error_status
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_Mat_Desc_SyncDeprecatedFlat, MD_MAT_CATEGORY_EL
  USE MD_Mat_Eval_Types, ONLY: MatEval_Ctx, MatAlgo_Algo, MAT_ALGO_DEFAULT
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UF_Elastic_Eval_Dispatch, UF_Elastic_Eval_Dispatch_FromDesc
  PUBLIC :: UF_Elastic_UMAT_Dispatch, MD_MAT_UMAT_Elastic_Dispatch
  PUBLIC :: UF_Elastic_UMAT_Wrapper
  PUBLIC :: UF_Elastic_Legacy_Isotropic, UF_Elastic_Legacy_Orthotropic
  PUBLIC :: UF_Elastic_Legacy_TransverseIso, UF_Elastic_Legacy_Anisotropic
  PUBLIC :: UF_Elastic_Legacy_Porous

CONTAINS

  SUBROUTINE UF_Elastic_Eval_Dispatch(material_id, nprops, props, ctx, algo, status)
    INTEGER(i4),           INTENT(IN)    :: material_id
    INTEGER(i4),           INTENT(IN)    :: nprops
    REAL(wp),              INTENT(IN)    :: props(:)
    TYPE(MatEval_Ctx),     INTENT(INOUT) :: ctx
    TYPE(MatAlgo_Algo),    INTENT(IN)    :: algo
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    TYPE(IsoElas_Desc)     :: iso_desc
    TYPE(OrthoElas_Desc)   :: ortho_desc
    TYPE(TransIsoElas_Desc) :: transiso_desc
    TYPE(AnisoElas_Desc)   :: aniso_desc
    TYPE(PorousElas_Desc)  :: porous_desc
    INTEGER(i4) :: np

    CALL init_error_status(status)
    CALL UF_Elastic_InitReg(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    np = MIN(nprops, SIZE(props))

    SELECT CASE (material_id)
    CASE (MD_MAT_ELAS_ISO_ID)
      iso_desc%nprops          = np
      iso_desc%props(1:np)     = props(1:np)
      CALL UF_IsotropicElastic_Eval(iso_desc, ctx, algo, status)
    CASE (MD_MAT_ELAS_ORTHO_ID)
      ortho_desc%nprops        = np
      ortho_desc%props(1:np)   = props(1:np)
      CALL UF_OrthotropicElastic_Eval(ortho_desc, ctx, algo, status)
    CASE (MD_MAT_ELAS_TRANSV_ISO)
      transiso_desc%nprops     = np
      transiso_desc%props(1:np) = props(1:np)
      CALL UF_TransverseIsoElastic_Eval(transiso_desc, ctx, algo, status)
    CASE (MD_MAT_ELAS_ANISO_ID)
      aniso_desc%nprops        = np
      aniso_desc%props(1:np)   = props(1:np)
      CALL UF_AnisotropicElastic_Eval(aniso_desc, ctx, algo, status)
    CASE (MD_MAT_ELAS_POROUS_ID)
      porous_desc%nprops       = np
      porous_desc%props(1:np)  = props(1:np)
      CALL UF_PorousElastic_Eval(porous_desc, ctx, algo, status)
    CASE DEFAULT
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      status%message     = 'Elastic Mat not found'
    END SELECT
  END SUBROUTINE UF_Elastic_Eval_Dispatch

  !---------------------------------------------------------------------------
  ! UF_Elastic_Eval_Dispatch_FromDesc
  ! W1: route from **MD_Mat_Desc** — SyncDeprecatedFlat; **material_id** / range
  !     mirror **MD_Mat_ValidatePropsForPopulate** (elastic branch).
  !---------------------------------------------------------------------------
  SUBROUTINE UF_Elastic_Eval_Dispatch_FromDesc(desc, ctx, algo, status)
    TYPE(MD_Mat_Desc), INTENT(INOUT) :: desc
    TYPE(MatEval_Ctx), INTENT(INOUT) :: ctx
    TYPE(MatAlgo_Algo), INTENT(IN) :: algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: material_id, eff_class, np, nprops_eff
    INTEGER(i4), PARAMETER :: MD_MAT_ELAS_ID_LO = 101_i4, MD_MAT_ELAS_ID_HI = 199_i4

    CALL init_error_status(status)
    CALL MD_Mat_Desc_SyncDeprecatedFlat(desc)

    eff_class = desc%cfg%class_id
    IF (eff_class == 0_i4) eff_class = desc%class_id

    material_id = desc%cfg%id
    IF (material_id <= 0_i4) material_id = desc%id

    IF (eff_class == MD_MAT_CATEGORY_EL) THEN
      IF (material_id < MD_MAT_ELAS_ID_LO .OR. material_id > MD_MAT_ELAS_ID_HI) material_id = MD_MAT_ELAS_ISO_ID
    ELSE IF (eff_class /= 0_i4) THEN
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      status%message = '[UF_Elastic_Eval_Dispatch_FromDesc] material category is not elastic'
      RETURN
    ELSE
      IF (material_id < MD_MAT_ELAS_ID_LO .OR. material_id > MD_MAT_ELAS_ID_HI) THEN
        status%status_code = MD_MAT_STATUS_NOT_FOUND
        status%message = '[UF_Elastic_Eval_Dispatch_FromDesc] cannot infer elastic material_id'
        RETURN
      END IF
    END IF

    IF (.NOT. ALLOCATED(desc%props)) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = '[UF_Elastic_Eval_Dispatch_FromDesc] desc%props not allocated'
      RETURN
    END IF

    nprops_eff = desc%pop%nProps
    IF (nprops_eff <= 0_i4) nprops_eff = desc%nProps
    IF (nprops_eff <= 0_i4) nprops_eff = INT(SIZE(desc%props), KIND=i4)
    np = MIN(nprops_eff, INT(SIZE(desc%props), KIND=i4))
    IF (np < 1_i4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = '[UF_Elastic_Eval_Dispatch_FromDesc] empty props'
      RETURN
    END IF

    CALL UF_Elastic_Eval_Dispatch(material_id, np, desc%props, ctx, algo, status)
  END SUBROUTINE UF_Elastic_Eval_Dispatch_FromDesc

  !=============================================================================
  ! Backward-compat UMAT wrapper - packs ctx, calls Eval dispatch
  !=============================================================================

  SUBROUTINE UF_Elastic_UMAT_Dispatch(material_id, stress, statev, ddsdde, &
                                       sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
                                       stran, dstran, time, dtime, temp, dtemp, &
                                       predef, dpred, ndir, nshr, nstatev, nprops, &
                                       props, ndim, kstep, kinc, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(OUT)   :: ddsdde(6,6)
    REAL(wp), INTENT(OUT)   :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT)   :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN)    :: stran(6), dstran(6)
    REAL(wp), INTENT(IN)    :: time(2), dtime
    REAL(wp), INTENT(IN)    :: temp, dtemp
    REAL(wp), INTENT(IN)    :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MatEval_Ctx) :: ctx

    ctx%stress  = stress
    ctx%statev(1:nstatev) = statev(1:nstatev)
    ctx%nstatv  = nstatev
    ctx%stran   = stran
    ctx%dstran  = dstran
    ctx%time    = time
    ctx%dtime   = dtime
    ctx%temp    = temp
    ctx%dtemp   = dtemp
    ctx%ndi     = ndir
    ctx%nshr    = nshr
    ctx%ntens   = ndir + nshr
    ctx%cfg%ndim    = ndim
    ctx%kstep   = kstep
    ctx%kinc    = kinc

    CALL UF_Elastic_Eval_Dispatch(material_id, nprops, props, ctx, MAT_ALGO_DEFAULT, status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    stress          = ctx%stress
    statev(1:nstatev) = ctx%statev(1:nstatev)
    ddsdde         = ctx%ddsdde
    sse            = ctx%sse
    spd            = ctx%spd
    scd            = ctx%scd
    rpl            = ctx%rpl
    ddsddt         = ctx%ddsddt
    drplde         = ctx%drplde
    drpldt         = ctx%drpldt
  END SUBROUTINE UF_Elastic_UMAT_Dispatch

  SUBROUTINE MD_MAT_UMAT_Elastic_Dispatch(material_id, stress, statev, ddsdde, sse, spd, scd, &
                                  rpl, ddsddt, drplde, drpldt, &
                                  stran, dstran, time, dtime, temp, dtemp, &
                                  predef, dpred, ndir, nshr, nstatev, nprops, &
                                  props, ndim, kstep, kinc, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(*)
    REAL(wp), INTENT(OUT)   :: ddsdde(6,6)
    REAL(wp), INTENT(OUT)   :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT)   :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN)    :: stran(6), dstran(6)
    REAL(wp), INTENT(IN)    :: time(2), dtime
    REAL(wp), INTENT(IN)    :: temp, dtemp
    REAL(wp), INTENT(IN)    :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN)    :: props(*)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL UF_Elastic_UMAT_Dispatch(material_id, stress, statev(1:nstatev), ddsdde, &
                                  sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
                                  stran, dstran, time, dtime, temp, dtemp, &
                                  predef, dpred, INT(ndir,i4), INT(nshr,i4), INT(nstatev,i4), INT(nprops,i4), &
                                  props(1:nprops), INT(ndim,i4), INT(kstep,i4), INT(kinc,i4), status)
  END SUBROUTINE MD_MAT_UMAT_Elastic_Dispatch

  SUBROUTINE UF_Elastic_UMAT_Wrapper(material_id, stress, statev, ddsdde, &
                                      sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
                                      stran, dstran, time, dtime, temp, dtemp, &
                                      predef, dpred, ndir, nshr, nstatev, nprops, &
                                      props, ndim, kstep, kinc, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(OUT)   :: ddsdde(6,6)
    REAL(wp), INTENT(OUT)   :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT)   :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN)    :: stran(6), dstran(6)
    REAL(wp), INTENT(IN)    :: time(2), dtime
    REAL(wp), INTENT(IN)    :: temp, dtemp
    REAL(wp), INTENT(IN)    :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL UF_Elastic_UMAT_Dispatch(material_id, stress, statev, ddsdde, &
                                  sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
                                  stran, dstran, time, dtime, temp, dtemp, &
                                  predef, dpred, ndir, nshr, nstatev, nprops, &
                                  props, ndim, kstep, kinc, status)
  END SUBROUTINE UF_Elastic_UMAT_Wrapper

  !=============================================================================
  ! Legacy thin wrappers (fixed-ID, no status)
  !=============================================================================

  SUBROUTINE UF_Elastic_Legacy_Isotropic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT)   :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN)    :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType) :: status
    CALL UF_Elastic_UMAT_Dispatch(101_i4, stress, statev(1:nstatev), ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, INT(ndir,i4), INT(nshr,i4), INT(nstatev,i4), INT(nprops,i4), &
      props(1:nprops), INT(ndim,i4), INT(kstep,i4), INT(kinc,i4), status)
  END SUBROUTINE UF_Elastic_Legacy_Isotropic

  SUBROUTINE UF_Elastic_Legacy_Orthotropic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT)   :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN)    :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType) :: status
    CALL UF_Elastic_UMAT_Dispatch(102_i4, stress, statev(1:nstatev), ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, INT(ndir,i4), INT(nshr,i4), INT(nstatev,i4), INT(nprops,i4), &
      props(1:nprops), INT(ndim,i4), INT(kstep,i4), INT(kinc,i4), status)
  END SUBROUTINE UF_Elastic_Legacy_Orthotropic

  SUBROUTINE UF_Elastic_Legacy_TransverseIso(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT)   :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN)    :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType) :: status
    CALL UF_Elastic_UMAT_Dispatch(MD_MAT_ELAS_TRANSV_ISO, stress, statev(1:nstatev), ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, INT(ndir,i4), INT(nshr,i4), INT(nstatev,i4), INT(nprops,i4), &
      props(1:nprops), INT(ndim,i4), INT(kstep,i4), INT(kinc,i4), status)
  END SUBROUTINE UF_Elastic_Legacy_TransverseIso

  SUBROUTINE UF_Elastic_Legacy_Anisotropic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT)   :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN)    :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType) :: status
    CALL UF_Elastic_UMAT_Dispatch(MD_MAT_ELAS_ANISO_ID, stress, statev(1:nstatev), ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, INT(ndir,i4), INT(nshr,i4), INT(nstatev,i4), INT(nprops,i4), &
      props(1:nprops), INT(ndim,i4), INT(kstep,i4), INT(kinc,i4), status)
  END SUBROUTINE UF_Elastic_Legacy_Anisotropic

  SUBROUTINE UF_Elastic_Legacy_Porous(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT)   :: ddsdde(6,6), sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN)    :: stran(6), dstran(6), time(2), dtime, temp, dtemp, predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType) :: status
    CALL UF_Elastic_UMAT_Dispatch(MD_MAT_ELAS_POROUS_ID, stress, statev(1:nstatev), ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, predef, dpred, INT(ndir,i4), INT(nshr,i4), INT(nstatev,i4), INT(nprops,i4), &
      props(1:nprops), INT(ndim,i4), INT(kstep,i4), INT(kinc,i4), status)
  END SUBROUTINE UF_Elastic_Legacy_Porous

END MODULE MD_Mat_Elas_Dispatch