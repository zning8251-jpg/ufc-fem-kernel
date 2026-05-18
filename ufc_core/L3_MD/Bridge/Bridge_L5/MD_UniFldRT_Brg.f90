!===============================================================================
! MODULE: MD_UniFldRT_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — Material/IP-eval L3→L5 bridge
! BRIEF:  Forward continuum material IP evaluation to L5_RT (EvalStructAtIp,
!         IntegrateIp).
! PILOT:  Material/continuum IP path — not L4 `PH_Field_*` 场方程核；场真源在 L3 `MD_Field_*` + L4 Compute* / Ops。
!===============================================================================


MODULE MD_UniFldRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Contm_Struct_Mat, ONLY: ContmMatRes, ContmIntegrateIp, UF_RT_EvalStructAtIp
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: ContmMatRes
  PUBLIC :: MD_RT_UniFld_EvalStructAtIp
  PUBLIC :: MD_RT_UniFld_IntegrateIp

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_UniFld_EvalStructAtIp
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Evaluate structural material response at IP (bridge → RT).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_UniFld_EvalStructAtIp(matModel, Ctx, kin, desc, &
                                         ipState_in, ipState_out, MatResult, ip_local)
    CLASS(*), INTENT(INOUT) :: matModel
    CLASS(*), INTENT(IN) :: Ctx
    REAL(wp), INTENT(IN) :: kin(:,:)
    CLASS(*), INTENT(IN) :: desc
    CLASS(*), INTENT(IN) :: ipState_in
    CLASS(*), INTENT(INOUT) :: ipState_out
    TYPE(ContmMatRes), INTENT(OUT) :: MatResult
    INTEGER(i4), INTENT(IN), OPTIONAL :: ip_local

    IF (PRESENT(ip_local)) THEN
      CALL UF_RT_EvalStructAtIp(matModel, Ctx, kin, desc, &
                                ipState_in, ipState_out, MatResult, ip_local)
    ELSE
      CALL UF_RT_EvalStructAtIp(matModel, Ctx, kin, desc, &
                                ipState_in, ipState_out, MatResult)
    END IF

  END SUBROUTINE MD_RT_UniFld_EvalStructAtIp

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_UniFld_IntegrateIp
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Integrate continuum material at IP (bridge → RT).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_UniFld_IntegrateIp(matModel, Ctx, kin, desc, MatResult)
    CLASS(*), INTENT(IN) :: matModel
    CLASS(*), INTENT(INOUT) :: Ctx
    REAL(wp), INTENT(IN) :: kin(:,:)
    CLASS(*), INTENT(IN) :: desc
    TYPE(ContmMatRes), INTENT(OUT) :: MatResult

    CALL ContmIntegrateIp(matModel, Ctx, kin, desc, MatResult)

  END SUBROUTINE MD_RT_UniFld_IntegrateIp

END MODULE MD_UniFldRT_Brg
