! Auto-generated adapter for CREEP — Jinja2 template not available.
! Subroutine: CREEP | Group: material | UFC Domain: Material
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §2
! Core: PH_Mat_CREEP_API
! Generated: 2026-04-13T14:31:06.854767+00:00
! Parameters (16):
!   ECR             → PH_Mat_Base_State.state%creep_strain
!   DECR            → PH_Mat_Base_State.state%creep_rate
!   STATEV          → PH_Mat_Base_State.state%statev(1:nstatv)
!   NSTATV          → PH_Mat_Base_Algo.algo%nstatv
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!   TIME            → PH_Mat_Base_Ctx.ctx%step_time/ctx%total_time
!   DTIME           → PH_Mat_Base_Ctx.ctx%dtime
!   TEMP            → PH_Mat_Base_Ctx.ctx%temp
!   DTEMP           → PH_Mat_Base_Ctx.ctx%dtemp
!   TRESCA          → PH_Mat_Base_Ctx.ctx%stress_eq
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   KSPT            → PH_Mat_Base_Ctx.ctx%kspt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Mat_CREEP_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: CREEP
CONTAINS
  SUBROUTINE CREEP(ECR, DECR, STATEV, NSTATV, NPROPS, PROPS, TIME, DTIME, TEMP, DTEMP, TRESCA, NOEL, NPT, KSPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[CREEP] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE CREEP
END MODULE PH_Mat_CREEP_Adapter_Mod
