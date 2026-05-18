! Auto-generated adapter for FILM — Jinja2 template not available.
! Subroutine: FILM | Group: load | UFC Domain: Load
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §4
! Core: PH_Load_FILM_API
! Generated: 2026-04-13T14:31:06.866315+00:00
! Parameters (11):
!   F               → PH_Load_Base_State.state%film_flux
!   H               → PH_Load_Base_State.state%film_coef
!   TEMP            → PH_Load_Base_Ctx.ctx%temp_surf
!   TEMP0           → PH_Load_Base_Ctx.ctx%temp_ref
!   TEMP1           → PH_Load_Base_Ctx.ctx%temp_film
!   COORDS          → PH_Load_Base_Ctx.ctx%coords(1:3)
!   NOEL            → PH_Load_Base_Ctx.ctx%elem_id
!   NPT             → PH_Load_Base_Ctx.ctx%gauss_pt
!   TIME            → PH_Load_Base_Ctx.ctx%step_time/ctx%total_time
!   DTIME           → PH_Load_Base_Ctx.ctx%dtime
!   SNAME           → MD_Load_Base_Desc.desc%film_name

MODULE PH_Load_FILM_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: FILM
CONTAINS
  SUBROUTINE FILM(F, H, TEMP, TEMP0, TEMP1, COORDS, NOEL, NPT, TIME, DTIME, SNAME)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[FILM] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE FILM
END MODULE PH_Load_FILM_Adapter_Mod
