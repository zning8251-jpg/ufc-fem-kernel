! Auto-generated adapter for GAPCON — Jinja2 template not available.
! Subroutine: GAPCON | Group: contact | UFC Domain: Contact
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §6
! Core: PH_Cont_GAPCON_API
! Generated: 2026-04-13T14:31:06.873933+00:00
! Parameters (10):
!   FLOW            → PH_Cont_Base_State.state%gap_flow
!   DFLOW           → PH_Cont_Base_State.state%dgap_flow
!   TIME            → PH_Cont_Base_Ctx.ctx%step_time/ctx%total_time
!   TEMP            → PH_Cont_Base_Ctx.ctx%temp
!   COORDS          → PH_Cont_Base_Ctx.ctx%coords(1:3)
!   NOEL            → PH_Cont_Base_Ctx.ctx%elem_id
!   NPT             → PH_Cont_Base_Ctx.ctx%pt_id
!   PROPS           → MD_Cont_Base_Desc.desc%props(1:nprops)
!   NPROPS          → MD_Cont_Base_Desc.desc%nprops
!   SNAME           → MD_Cont_Base_Desc.desc%pair_name

MODULE PH_Cont_GAPCON_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: GAPCON
CONTAINS
  SUBROUTINE GAPCON(FLOW, DFLOW, TIME, TEMP, COORDS, NOEL, NPT, PROPS, NPROPS, SNAME)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[GAPCON] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE GAPCON
END MODULE PH_Cont_GAPCON_Adapter_Mod
