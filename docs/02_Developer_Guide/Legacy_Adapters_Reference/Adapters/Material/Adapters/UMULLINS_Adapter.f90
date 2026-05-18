! Auto-generated adapter for UMULLINS — Jinja2 template not available.
! Subroutine: UMULLINS | Group: material | UFC Domain: Material
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §2
! Core: PH_Mat_UMULLINS_API
! Generated: 2026-04-13T14:31:06.856073+00:00
! Parameters (10):
!   STATEV          → PH_Mat_Base_State.state%statev(1:nstatv)
!   NSTATV          → PH_Mat_Base_Algo.algo%nstatv
!   NPROPS          → MD_Mat_Base_Desc.desc%nprops
!   PROPS           → MD_Mat_Base_Desc.desc%props(1:nprops)
!   STRMAX          → PH_Mat_Base_Ctx.ctx%max_stretch_ratio
!   TEMP            → PH_Mat_Base_Ctx.ctx%temp
!   NOEL            → PH_Mat_Base_Ctx.ctx%elem_id
!   NPT             → PH_Mat_Base_Ctx.ctx%gauss_pt
!   KSTEP           → PH_Mat_Base_Ctx.ctx%kstep
!   KINC            → PH_Mat_Base_Ctx.ctx%kinc

MODULE PH_Mat_UMULLINS_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UMULLINS
CONTAINS
  SUBROUTINE UMULLINS(STATEV, NSTATV, NPROPS, PROPS, STRMAX, TEMP, NOEL, NPT, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UMULLINS] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UMULLINS
END MODULE PH_Mat_UMULLINS_Adapter_Mod
