! Auto-generated adapter for UFRIC — Jinja2 template not available.
! Subroutine: UFRIC | Group: contact | UFC Domain: Contact
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §6
! Core: PH_Cont_UFRIC_API
! Generated: 2026-04-13T14:31:06.873451+00:00
! Parameters (16):
!   TFRIC           → PH_Cont_Base_State.state%fric_stress
!   STATF           → PH_Cont_Base_State.state%statev(1:nstatv)
!   TIME            → PH_Cont_Base_Ctx.ctx%step_time/ctx%total_time
!   SLIP            → PH_Cont_Base_Ctx.ctx%slip_magnitude
!   SPRESS          → PH_Cont_Base_Ctx.ctx%contact_pressure
!   TEMP            → PH_Cont_Base_Ctx.ctx%temp
!   NOEL            → PH_Cont_Base_Ctx.ctx%elem_id
!   NPT             → PH_Cont_Base_Ctx.ctx%pt_id
!   PROPS           → MD_Fric_Base_Desc.desc%props(1:nprops)
!   NPROPS          → MD_Fric_Base_Desc.desc%nprops
!   NTENS           → PH_Cont_Base_Algo.algo%ntens
!   STATEV          → PH_Cont_Base_State.state%statev(1:nstatv)
!   NSTATV          → PH_Cont_Base_Algo.algo%nstatv
!   SNAME           → MD_Fric_Base_Desc.desc%fric_name
!   KSTEP           → PH_Cont_Base_Ctx.ctx%kstep
!   KINC            → PH_Cont_Base_Ctx.ctx%kinc

MODULE PH_Cont_UFRIC_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UFRIC
CONTAINS
  SUBROUTINE UFRIC(TFRIC, STATF, TIME, SLIP, SPRESS, TEMP, NOEL, NPT, PROPS, NPROPS, NTENS, STATEV, NSTATV, SNAME, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UFRIC] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UFRIC
END MODULE PH_Cont_UFRIC_Adapter_Mod
