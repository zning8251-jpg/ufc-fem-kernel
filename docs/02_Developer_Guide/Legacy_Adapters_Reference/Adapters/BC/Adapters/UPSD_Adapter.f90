! Auto-generated adapter for UPSD — Jinja2 template not available.
! Subroutine: UPSD | Group: bc | UFC Domain: BC
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §5
! Core: PH_BC_UPSD_API
! Generated: 2026-04-13T14:31:06.870561+00:00
! Parameters (6):
!   S               → PH_BC_Base_State.state%bc_stress(1:6)
!   TIME            → PH_BC_Base_Ctx.ctx%step_time/ctx%total_time
!   SNAME           → MD_BC_Base_Desc.desc%bc_name
!   COORDS          → PH_BC_Base_Ctx.ctx%coords(1:3)
!   NOEL            → PH_BC_Base_Ctx.ctx%elem_id
!   NPT             → PH_BC_Base_Ctx.ctx%gauss_pt

MODULE PH_BC_UPSD_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UPSD
CONTAINS
  SUBROUTINE UPSD(S, TIME, SNAME, COORDS, NOEL, NPT)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UPSD] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UPSD
END MODULE PH_BC_UPSD_Adapter_Mod
