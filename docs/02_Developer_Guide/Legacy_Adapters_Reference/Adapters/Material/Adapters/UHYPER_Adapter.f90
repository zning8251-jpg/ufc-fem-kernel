! Auto-generated adapter for UHYPER — Jinja2 template not available.
! Subroutine: UHYPER | Group: material | UFC Domain: Material
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §2
! Core: PH_Mat_UHYPER_API
! Generated: 2026-04-13T14:31:06.855668+00:00
! Parameters (10):
!   STATEV          → PH_Mat_Base_State.state%statev(1:nstatv)
!   NSTATV          → PH_Mat_Base_Algo.algo%nstatv
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!   STRETCH         → PH_Mat_Base_Ctx.ctx%stretch
!   DTEMP           → PH_Mat_Base_Ctx.ctx%dtemp
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Mat_UHYPER_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UHYPER
CONTAINS
  SUBROUTINE UHYPER(STATEV, NSTATV, NPROPS, PROPS, STRETCH, DTEMP, NOEL, NPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UHYPER] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UHYPER
END MODULE PH_Mat_UHYPER_Adapter_Mod
