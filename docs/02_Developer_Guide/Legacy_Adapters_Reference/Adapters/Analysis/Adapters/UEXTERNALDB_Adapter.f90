! Auto-generated adapter for UEXTERNALDB — Jinja2 template not available.
! Subroutine: UEXTERNALDB | Group: analysis | UFC Domain: Analysis
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §9
! Core: RT_Analysis_UEXTERNALDB_API
! Generated: 2026-04-13T14:31:06.878297+00:00
! Parameters (8):
!   LOP             → RT_Analysis_Ctx.ctx%db_operation
!   TIME            → RT_Analysis_Ctx.ctx%step_time/ctx%total_time
!   DTIME           → RT_Analysis_Ctx.ctx%dtime
!   KSTEP           → RT_Analysis_Ctx.ctx%kstep
!   KINC            → RT_Analysis_Ctx.ctx%kinc
!   LREAD           → RT_Analysis_Ctx.ctx%lread
!   LSTOP           → RT_Analysis_Ctx.ctx%lstop
!   KOLD            → RT_Analysis_Ctx.ctx%kold

MODULE RT_Analysis_UEXTERNALDB_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UEXTERNALDB
CONTAINS
  SUBROUTINE UEXTERNALDB(LOP, TIME, DTIME, KSTEP, KINC, LREAD, LSTOP, KOLD)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UEXTERNALDB] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UEXTERNALDB
END MODULE RT_Analysis_UEXTERNALDB_Adapter_Mod
