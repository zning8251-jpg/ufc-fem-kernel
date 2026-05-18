! Auto-generated adapter for UMAT — Jinja2 template not available.
! Subroutine: UMAT | Group: material | UFC Domain: Material
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §2
! Core: PH_Mat_UMAT_API
! Generated: 2026-04-13T14:31:06.847157+00:00
! Parameters (37):
!   STRESS          → PH_Mat_Base_State.state%stress(1:ntens)
!   STATEV          → PH_Mat_Base_State.state%statev(1:nstatv)
!   DDSDDE          → PH_Mat_Base_State.state%ddsdde(1:ntens,1:ntens)
!   SSE             → PH_Mat_Base_State.state%sse
!   SPD             → PH_Mat_Base_State.state%spd
!   SCD             → PH_Mat_Base_State.state%scd
!   RPL             → PH_Mat_Base_State.state%rpl
!   DDSDDT          → PH_Mat_Base_State.state%ddsddt(1:ntens)
!   DRPLDE          → PH_Mat_Base_State.state%drplde(1:ntens)
!   DRPLDT          → PH_Mat_Base_State.state%drpldt
!   STRAN           → PH_Mat_Base_Ctx.ctx%stran(1:ntens)
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
!   NSTATV          → PH_Mat_Base_Algo.algo%nstatv
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!   COORDS          → PH_Mat_Base_Ctx.ctx%coords(1:3)
!   DROT            → PH_Mat_Base_Ctx.ctx%drot(1:3,1:3)
!   PNEWDT          → PH_Mat_Base_State.state%pnewdt
!   CELENT          → PH_Mat_Base_Ctx.ctx%celent
!   DFGRD0          → PH_Mat_Base_Ctx.ctx%dfgrd0(1:3,1:3)
!   DFGRD1          → PH_Mat_Base_Ctx.ctx%dfgrd1(1:3,1:3)
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   LAYER           → PH_Mat_Base_Ctx.ctx%layer
!   KSPT            → PH_Mat_Base_Ctx.ctx%kspt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Mat_UMAT_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UMAT
CONTAINS
  SUBROUTINE UMAT(STRESS, STATEV, DDSDDE, SSE, SPD, SCD, RPL, DDSDDT, DRPLDE, DRPLDT, STRAN, DSTRAN, TIME, DTIME, TEMP, DTEMP, PREDEF, DPRED, CMNAME, NDI, NSHR, NTENS, NSTATV, NPROPS, PROPS, COORDS, DROT, PNEWDT, CELENT, DFGRD0, DFGRD1, NOEL, NPT, LAYER, KSPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UMAT] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UMAT
END MODULE PH_Mat_UMAT_Adapter_Mod
