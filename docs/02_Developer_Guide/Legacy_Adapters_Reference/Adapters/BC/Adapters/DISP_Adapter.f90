! Auto-generated adapter for DISP — Jinja2 template not available.
! Subroutine: DISP | Group: bc | UFC Domain: BC
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §5
! Core: PH_BC_DISP_API
! Generated: 2026-04-13T14:31:06.868722+00:00
! Parameters (6):
!   U               → PH_BC_Base_State.state%bc_value(1:6)
!   NODE            → PH_BC_Base_Ctx.ctx%node_id
!   NDOF            → PH_BC_Base_Ctx.ctx%dof_number
!   TIME            → PH_BC_Base_Ctx.ctx%step_time/ctx%total_time
!   DTIME           → PH_BC_Base_Ctx.ctx%dtime
!   SNAME           → MD_BC_Base_Desc.desc%bc_name

MODULE PH_BC_DISP_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: DISP
CONTAINS
  SUBROUTINE DISP(U, NODE, NDOF, TIME, DTIME, SNAME)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[DISP] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE DISP
END MODULE PH_BC_DISP_Adapter_Mod
