!===============================================================================
! MODULE: PH_Mat_Plast_Crystal_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Crystal plasticity Desc from L3 + UMAT stub (reserved ID 266) —
!         **W1**：落地后与 **`desc%props`** / **CrystalPlast_MatDesc** 金线一致；
!         当前 UMAT 桩仍消费 ABI **`props`**。
! Purpose: Crystal plasticity UMAT placeholder (mat_id 266); SIO via UF_CrystalPlasticity_UMAT_Arg.
! Theory: Reserved for CPFEM integration; stub returns STATUS_UNSUPPORTED.
! Status: Stub (unsupported) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Plast_Crystal_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_UNSUPPORTED, init_error_status
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Eval_Types, ONLY: MD_MATCTX_MAX_STATEV
  USE MD_Mat_Plast_Reg, ONLY: MD_MAT_PLAST_MAX_PROPS
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CRYSTAL_PLASTICITY_MAT_ID = 266_i4
  TYPE, PUBLIC :: CrystalPlast_MatDesc
    REAL(wp) :: props(50) = 0.0_wp
    INTEGER(i4) :: nprops = 0_i4
  END TYPE CrystalPlast_MatDesc

  IMPLICIT NONE
  PRIVATE
  PUBLIC :: CrystalPlast_MatDesc, PH_MAT_CRYSTAL_PLASTICITY_MAT_ID
  PUBLIC :: UF_CrystalPlasticity_UMAT, UF_CrystalPlasticity_UMAT_Arg

  TYPE, PUBLIC :: UF_CrystalPlasticity_UMAT_Arg
    REAL(wp) :: stress(6) = 0.0_wp                       ! [INOUT]
    INTEGER(i4) :: nstatev = 0_i4                        ! [IN]
    REAL(wp) :: statev(MD_MATCTX_MAX_STATEV) = 0.0_wp    ! [INOUT]
    REAL(wp) :: ddsdde(6, 6) = 0.0_wp                    ! [OUT]
    REAL(wp) :: sse = 0.0_wp                             ! [OUT]
    REAL(wp) :: spd = 0.0_wp                             ! [OUT]
    REAL(wp) :: scd = 0.0_wp                             ! [OUT]
    REAL(wp) :: rpl = 0.0_wp                             ! [OUT]
    REAL(wp) :: ddsddt(6) = 0.0_wp                       ! [OUT]
    REAL(wp) :: drplde(6) = 0.0_wp                       ! [OUT]
    REAL(wp) :: drpldt = 0.0_wp                          ! [OUT]
    REAL(wp) :: stran(6) = 0.0_wp                        ! [IN]
    REAL(wp) :: dstran(6) = 0.0_wp                       ! [IN]
    REAL(wp) :: time(2) = 0.0_wp                         ! [IN]
    REAL(wp) :: dtime = 0.0_wp                           ! [IN]
    REAL(wp) :: temp = 0.0_wp                            ! [IN]
    REAL(wp) :: dtemp = 0.0_wp                           ! [IN]
    INTEGER(i4) :: ndir = 0_i4                           ! [IN]
    INTEGER(i4) :: nshr = 0_i4                           ! [IN]
    INTEGER(i4) :: nprops = 0_i4                         ! [IN]
    REAL(wp) :: props(MD_MAT_PLAST_MAX_PROPS) = 0.0_wp   ! [IN]
    INTEGER(i4) :: ndim = 0_i4                           ! [IN]
    INTEGER(i4) :: kstep = 0_i4                          ! [IN]
    INTEGER(i4) :: kinc = 0_i4                           ! [IN]
    TYPE(ErrorStatusType) :: status                      ! [OUT]
  END TYPE UF_CrystalPlasticity_UMAT_Arg

CONTAINS

  SUBROUTINE UF_CrystalPlasticity_UMAT(arg)
    TYPE(UF_CrystalPlasticity_UMAT_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    arg%ddsdde = 0.0_wp
    arg%sse = 0.0_wp
    arg%spd = 0.0_wp
    arg%scd = 0.0_wp
    arg%rpl = 0.0_wp
    arg%ddsddt = 0.0_wp
    arg%drplde = 0.0_wp
    arg%drpldt = 0.0_wp
    arg%status%status_code = STATUS_UNSUPPORTED
    arg%status%message = 'UF_CrystalPlasticity_UMAT: not implemented (reserved material ID)'
  END SUBROUTINE UF_CrystalPlasticity_UMAT

END MODULE PH_Mat_Plast_Crystal_Core
