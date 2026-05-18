! Auto-generated adapter for UMATHT — Jinja2 template not available.
! Subroutine: UMATHT | Group: material | UFC Domain: Material
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §2
! Core: PH_Mat_UMATHT_API
! Generated: 2026-04-13T14:31:06.854322+00:00
! Parameters (14):
!   FLUX            → PH_Mat_Base_State.state%flux(1:3)
!   STATEV          → PH_Mat_Base_State.state%statev(1:nstatv)
!   NSTATV          → PH_Mat_Base_Algo.algo%nstatv
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!   TEMP            → PH_Mat_Base_Ctx.ctx%temp
!   DTEMP           → PH_Mat_Base_Ctx.ctx%dtemp
!   TIME            → PH_Mat_Base_Ctx.ctx%step_time/ctx%total_time
!   DTIME           → PH_Mat_Base_Ctx.ctx%dtime
!   COORDS          → PH_Mat_Base_Ctx.ctx%coords(1:3)
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Mat_UMATHT_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UMATHT
CONTAINS
  SUBROUTINE UMATHT(FLUX, STATEV, NSTATV, NPROPS, PROPS, TEMP, DTEMP, TIME, DTIME, COORDS, NOEL, NPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UMATHT] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UMATHT
END MODULE PH_Mat_UMATHT_Adapter_Mod
