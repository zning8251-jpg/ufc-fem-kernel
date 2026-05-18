! Auto-generated adapter for CLOAD — Jinja2 template not available.
! Subroutine: CLOAD | Group: load | UFC Domain: Load
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §4
! Core: PH_Load_CLOAD_API
! Generated: 2026-04-13T14:31:06.859088+00:00
! Parameters (5):
!   F               → PH_Load_Base_State.state%nodal_force
!   NODE            → PH_Load_Base_Ctx.ctx%node_id
!   NDOF            → PH_Load_Base_Ctx.ctx%dof_number
!   TIME            → PH_Load_Base_Ctx.ctx%step_time/ctx%total_time
!   SNAME           → MD_Load_Base_Desc.desc%load_name

MODULE PH_Load_CLOAD_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: CLOAD
CONTAINS
  SUBROUTINE CLOAD(F, NODE, NDOF, TIME, SNAME)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[CLOAD] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE CLOAD
END MODULE PH_Load_CLOAD_Adapter_Mod
