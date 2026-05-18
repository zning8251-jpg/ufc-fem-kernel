! Auto-generated adapter for HETVAL — Jinja2 template not available.
! Subroutine: HETVAL | Group: load | UFC Domain: Load
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §4
! Core: PH_Load_HETVAL_API
! Generated: 2026-04-13T14:31:06.867472+00:00
! Parameters (11):
!   RHO             → PH_Load_Base_State.state%heat_gen_rate
!   TIME            → PH_Load_Base_Ctx.ctx%step_time/ctx%total_time
!   DTIME           → PH_Load_Base_Ctx.ctx%dtime
!   NOEL            → PH_Load_Base_Ctx.ctx%elem_id
!   NPT             → PH_Load_Base_Ctx.ctx%gauss_pt
!   COORDS          → PH_Load_Base_Ctx.ctx%coords(1:3)
!   TEMP            → PH_Load_Base_Ctx.ctx%temp
!   STATEV          → PH_Load_Base_State.state%statev(1:nstatv)
!   NSTATV          → PH_Load_Base_Algo.algo%nstatv
!   NPROPS          → MD_Load_Base_Desc.desc%nprops
!   PROPS           → MD_Load_Base_Desc.desc%props(1:nprops)

MODULE PH_Load_HETVAL_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: HETVAL
CONTAINS
  SUBROUTINE HETVAL(RHO, TIME, DTIME, NOEL, NPT, COORDS, TEMP, STATEV, NSTATV, NPROPS, PROPS)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[HETVAL] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE HETVAL
END MODULE PH_Load_HETVAL_Adapter_Mod
