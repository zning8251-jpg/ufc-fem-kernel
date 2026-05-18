! Auto-generated adapter for USDFLD — Jinja2 template not available.
! Subroutine: USDFLD | Group: field | UFC Domain: Field
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §8
! Core: PH_Field_USDFLD_API
! Generated: 2026-04-13T14:31:06.856433+00:00
! Parameters (19):
!   STATEV          → PH_Mat_Base_State.state%statev(1:nstatv)
!   NSTATV          → PH_Mat_Base_Algo.algo%nstatv
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!   COORDS          → PH_Mat_Base_Ctx.ctx%coords(1:3)
!   TIME            → PH_Mat_Base_Ctx.ctx%step_time/ctx%total_time
!   DTIME           → PH_Mat_Base_Ctx.ctx%dtime
!   TEMP            → PH_Mat_Base_Ctx.ctx%temp
!   DTEMP           → PH_Mat_Base_Ctx.ctx%dtemp
!   PREDEF          → PH_Mat_Base_Ctx.ctx%predef(1:npredf)
!   DPRED           → PH_Mat_Base_Ctx.ctx%dpred(1:npredf)
!   CMNAME          → MD_Mat_Base_Desc.desc%model_name
!   NDI             → PH_Mat_Base_Algo.algo%ndi
!   NSHR            → PH_Mat_Base_Algo.algo%nshr
!   NTENS           → PH_Mat_Base_Algo.algo%ntens
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Field_USDFLD_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: USDFLD
CONTAINS
  SUBROUTINE USDFLD(STATEV, NSTATV, NPROPS, PROPS, COORDS, TIME, DTIME, TEMP, DTEMP, PREDEF, DPRED, CMNAME, NDI, NSHR, NTENS, NOEL, NPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[USDFLD] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE USDFLD
END MODULE PH_Field_USDFLD_Adapter_Mod
