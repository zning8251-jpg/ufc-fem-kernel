! Auto-generated adapter for UVARM — Jinja2 template not available.
! Subroutine: UVARM | Group: analysis | UFC Domain: Output
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §9
! Core: RT_Output_UVARM_API
! Generated: 2026-04-13T14:31:06.877224+00:00
! Parameters (13):
!   VAR             → RT_Output_Ctx.ctx%uvar(1:nuvarm)
!   TIME            → PH_Mat_Base_Ctx.ctx%step_time/ctx%total_time
!   DTIME           → PH_Mat_Base_Ctx.ctx%dtime
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   NUVARM          → RT_Output_Ctx.ctx%nuvarm
!   JLTYP           → PH_Mat_Base_Ctx.ctx%output_type
!   NNODE           → PH_Mat_Base_Ctx.ctx%nnode
!   COORDS          → PH_Mat_Base_Ctx.ctx%coords(1:3)
!   NFIELD          → PH_Mat_Base_Ctx.ctx%nfield
!   FIELD           → PH_Mat_Base_Ctx.ctx%field(1:nfield)

MODULE RT_Output_UVARM_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UVARM
CONTAINS
  SUBROUTINE UVARM(VAR, TIME, DTIME, KSTEP, KINC, NOEL, NPT, NUVARM, JLTYP, NNODE, COORDS, NFIELD, FIELD)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UVARM] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UVARM
END MODULE RT_Output_UVARM_Adapter_Mod
