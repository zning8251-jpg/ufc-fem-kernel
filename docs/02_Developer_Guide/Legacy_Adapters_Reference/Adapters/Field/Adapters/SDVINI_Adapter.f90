! Auto-generated adapter for SDVINI — Jinja2 template not available.
! Subroutine: SDVINI | Group: field | UFC Domain: Field
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §8
! Core: PH_Field_SDVINI_API
! Generated: 2026-04-13T14:31:06.856974+00:00
! Parameters (9):
!   STATEV          → PH_Mat_Base_State.state%statev(1:nstatv)
!   NSTATV          → PH_Mat_Base_Algo.algo%nstatv
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!   COORDS          → PH_Mat_Base_Ctx.ctx%coords(1:3)
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Field_SDVINI_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: SDVINI
CONTAINS
  SUBROUTINE SDVINI(STATEV, NSTATV, NPROPS, PROPS, COORDS, NOEL, NPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[SDVINI] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE SDVINI
END MODULE PH_Field_SDVINI_Adapter_Mod
