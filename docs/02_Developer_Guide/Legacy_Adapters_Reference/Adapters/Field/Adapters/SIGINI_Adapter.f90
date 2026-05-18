! Auto-generated adapter for SIGINI — Jinja2 template not available.
! Subroutine: SIGINI | Group: field | UFC Domain: Field
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §8
! Core: PH_Field_SIGINI_API
! Generated: 2026-04-13T14:31:06.857280+00:00
! Parameters (9):
!   STRESS          → PH_Mat_Base_State.state%stress(1:ntens)
!   NSTATV          → PH_Mat_Base_Algo.algo%nstatv
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!   COORDS          → PH_Mat_Base_Ctx.ctx%coords(1:3)
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Field_SIGINI_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: SIGINI
CONTAINS
  SUBROUTINE SIGINI(STRESS, NSTATV, NPROPS, PROPS, COORDS, NOEL, NPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[SIGINI] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE SIGINI
END MODULE PH_Field_SIGINI_Adapter_Mod
