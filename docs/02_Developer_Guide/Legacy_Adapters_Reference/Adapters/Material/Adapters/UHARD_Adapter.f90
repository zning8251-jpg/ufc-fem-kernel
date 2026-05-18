! Auto-generated adapter for UHARD — Jinja2 template not available.
! Subroutine: UHARD | Group: material | UFC Domain: Material
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §2
! Core: PH_Mat_UHARD_API
! Generated: 2026-04-13T14:31:06.855284+00:00
! Parameters (14):
!   YIELD           → PH_Mat_Base_State.state%yield_stress
!   DYIELD          → PH_Mat_Base_State.state%yield_hardening(1:2)
!   STATEV          → PH_Mat_Base_State.state%statev(1:nstatv)
!   NSTATV          → PH_Mat_Base_Algo.algo%nstatv
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!   EQSTRAIN        → PH_Mat_Base_Ctx.ctx%eq_plastic_strain
!   TIME            → PH_Mat_Base_Ctx.ctx%step_time/ctx%total_time
!   TEMP            → PH_Mat_Base_Ctx.ctx%temp
!   DTEMP           → PH_Mat_Base_Ctx.ctx%dtemp
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Mat_UHARD_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UHARD
CONTAINS
  SUBROUTINE UHARD(YIELD, DYIELD, STATEV, NSTATV, NPROPS, PROPS, EQSTRAIN, TIME, TEMP, DTEMP, NOEL, NPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UHARD] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UHARD
END MODULE PH_Mat_UHARD_Adapter_Mod
