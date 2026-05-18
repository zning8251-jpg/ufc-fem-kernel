!===============================================================================
! MODULE: PH_Mat_Plast_Crystal_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Crystal plasticity Desc from L3 + UMAT stub (reserved ID 266) —
!         **W1**：落地后与 **`desc%props`** / **CrystalPlast_MatDesc** 金线一致；
!         当前 UMAT 桩仍消费 ABI **`props`**。
!===============================================================================
MODULE PH_Mat_Plast_Crystal_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_UNSUPPORTED, init_error_status
  USE IF_Prec_Core, ONLY: wp, i4
  ! Legacy stub definitions (module MD_MatPLMCrystal deleted in material domain cleanup)
  INTEGER(i4), PARAMETER :: PH_MAT_CRYSTAL_PLASTICITY_MAT_ID = 266_i4
  TYPE :: CrystalPlast_MatDesc
    REAL(wp) :: props(50) = 0.0_wp
    INTEGER(i4) :: nprops = 0_i4
  END TYPE CrystalPlast_MatDesc

  IMPLICIT NONE
  PRIVATE
  PUBLIC :: CrystalPlast_MatDesc, PH_MAT_CRYSTAL_PLASTICITY_MAT_ID, UF_CrystalPlasticity_UMAT
CONTAINS

  SUBROUTINE UF_CrystalPlasticity_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
      rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, &
      predef, dpred, ndir, nshr, nstatev, nprops, &
      props, ndim, kstep, kinc, status)
    REAL(wp), INTENT(INOUT) :: sigma(6)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(OUT) :: ddsdde(6, 6)
    REAL(wp), INTENT(OUT) :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6)
    REAL(wp), INTENT(IN) :: time(2), dtime
    REAL(wp), INTENT(IN) :: temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ddsdde = 0.0_wp
    sse = 0.0_wp
    spd = 0.0_wp
    scd = 0.0_wp
    rpl = 0.0_wp
    ddsddt = 0.0_wp
    drplde = 0.0_wp
    drpldt = 0.0_wp
    status%status_code = STATUS_UNSUPPORTED
    status%message = 'UF_CrystalPlasticity_UMAT: not implemented (reserved material ID)'
  END SUBROUTINE UF_CrystalPlasticity_UMAT

END MODULE PH_Mat_Plast_Crystal_Core