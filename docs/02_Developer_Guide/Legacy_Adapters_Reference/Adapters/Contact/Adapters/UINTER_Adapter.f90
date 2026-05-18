! Auto-generated adapter for UINTER — Jinja2 template not available.
! Subroutine: UINTER | Group: contact | UFC Domain: Contact
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §6
! Core: PH_Cont_UINTER_API
! Generated: 2026-04-13T14:31:06.872281+00:00
! Parameters (17):
!   NDIR            → PH_Cont_Base_State.state%nactive
!   NSTATV          → PH_Cont_Base_Algo.algo%nstatv
!   STATEV          → PH_Cont_Base_State.state%statev(1:nstatv)
!   TIME            → PH_Cont_Base_Ctx.ctx%step_time/ctx%total_time
!   U               → PH_Cont_Base_Ctx.ctx%disp(1:6)
!   V               → PH_Cont_Base_Ctx.ctx%velocity(1:6)
!   A               → PH_Cont_Base_Ctx.ctx%accel(1:6)
!   NOEL            → PH_Cont_Base_Ctx.ctx%slave_elem_id
!   NPT             → PH_Cont_Base_Ctx.ctx%slave_pt_id
!   PROPS           → MD_Cont_Base_Desc.desc%props(1:nprops)
!   NPROPS          → MD_Cont_Base_Desc.desc%nprops
!   COORDS          → PH_Cont_Base_Ctx.ctx%coords(1:3)
!   DGAM            → PH_Cont_Base_State.state%dgamma
!   DDD             → PH_Cont_Base_State.state%dddg(1:3,1:3)
!   SNAM            → MD_Cont_Base_Desc.desc%pair_name
!   KSTEP           → PH_Cont_Base_Ctx.ctx%kstep
!   KINC            → PH_Cont_Base_Ctx.ctx%kinc

MODULE PH_Cont_UINTER_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UINTER
CONTAINS
  SUBROUTINE UINTER(NDIR, NSTATV, STATEV, TIME, U, V, A, NOEL, NPT, PROPS, NPROPS, COORDS, DGAM, DDD, SNAM, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UINTER] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UINTER
END MODULE PH_Cont_UINTER_Adapter_Mod
