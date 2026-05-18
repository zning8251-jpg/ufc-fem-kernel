! Auto-generated adapter for VDLOAD — Jinja2 template not available.
! Subroutine: VDLOAD | Group: load | UFC Domain: Load
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §4
! Core: PH_Load_VDLOAD_API
! Generated: 2026-04-13T14:31:06.858717+00:00
! Parameters (10):
!   F               → PH_Load_Base_State.state%load_vector(1:6)
!   COORDS          → PH_Load_Base_Ctx.ctx%coords(1:3)
!   DIRECT          → PH_Load_Base_Ctx.ctx%load_direction(1:3)
!   TEMP            → PH_Load_Base_Ctx.ctx%temp
!   TIME            → PH_Load_Base_Ctx.ctx%step_time/ctx%total_time
!   NOEL            → PH_Load_Base_Ctx.ctx%elem_id
!   NPT             → PH_Load_Base_Ctx.ctx%gauss_pt
!   LFTAG           → PH_Load_Base_Ctx.ctx%load_tag
!   SNAME           → MD_Load_Base_Desc.desc%load_name
!   NVAL            → PH_Load_Base_Algo.algo%nval

MODULE PH_Load_VDLOAD_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: VDLOAD
CONTAINS
  SUBROUTINE VDLOAD(F, COORDS, DIRECT, TEMP, TIME, NOEL, NPT, LFTAG, SNAME, NVAL)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[VDLOAD] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE VDLOAD
END MODULE PH_Load_VDLOAD_Adapter_Mod
