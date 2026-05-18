! Auto-generated adapter for VUMAT — Jinja2 template not available.
! Subroutine: VUMAT | Group: material | UFC Domain: Material
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §2
! Core: PH_Mat_VUMAT_API
! Generated: 2026-04-13T14:31:06.853901+00:00
! Parameters (23):
!   STRESS          → PH_Mat_Base_State.state%stress(1:ntens)
!   STATEV          → PH_Mat_Base_State.state%statev(1:nstatv)
!   NSTATEV         → PH_Mat_Base_Algo.algo%nstatv
!   NFIELDS         → PH_Mat_Base_Algo.algo%nfields
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!    coords         → PH_Mat_Base_Ctx.ctx%coords(1:3)
!   DSTRAN          → PH_Mat_Base_Ctx.ctx%dstran(1:ntens)
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
!   NUMINT          → PH_Mat_Base_Ctx.ctx%gauss_pt
!   NLAYER          → PH_Mat_Base_Ctx.ctx%layer
!   KSPT            → PH_Mat_Base_Ctx.ctx%kspt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Mat_VUMAT_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: VUMAT
CONTAINS
  SUBROUTINE VUMAT(STRESS, STATEV, NSTATEV, NFIELDS, NPROPS, PROPS, coords, DSTRAN, TIME, DTIME, TEMP, DTEMP, PREDEF, DPRED, CMNAME, NDI, NSHR, NTENS, NUMINT, NLAYER, KSPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[VUMAT] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE VUMAT
END MODULE PH_Mat_VUMAT_Adapter_Mod
