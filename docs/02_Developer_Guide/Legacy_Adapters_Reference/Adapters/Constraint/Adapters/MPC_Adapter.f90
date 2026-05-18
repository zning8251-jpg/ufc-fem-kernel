! Auto-generated adapter for MPC — Jinja2 template not available.
! Subroutine: MPC | Group: constraint | UFC Domain: Constraint
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §7
! Core: PH_Cons_MPC_API
! Generated: 2026-04-13T14:31:06.874437+00:00
! Parameters (15):
!   AMATRX          → PH_Cons_Base_State.state%constraint_A(1:ndof,1:ndof)
!   TIME            → PH_Cons_Base_Ctx.ctx%step_time/ctx%total_time
!   NODE            → PH_Cons_Base_Ctx.ctx%node_ids(1:nnode)
!   JDOF            → PH_Cons_Base_Ctx.ctx%dof_map(1:ndof)
!   NDOF            → PH_Cons_Base_Algo.algo%ndof
!   NNODE           → MD_Cons_Base_Desc.desc%nnode
!   COORDS          → PH_Cons_Base_Ctx.ctx%coords(1:3,1:nnode)
!   JTYPE           → MD_Cons_Base_Desc.desc%constraint_type
!   PROPS           → MD_Cons_Base_Desc.desc%props(1:nprops)
!   NPROPS          → MD_Cons_Base_Desc.desc%nprops
!   UE              → PH_Cons_Base_Ctx.ctx%disp_master(1:ndof)
!   DUE             → PH_Cons_Base_Ctx.ctx%disp_inc(1:ndof)
!   NOEL            → PH_Cons_Base_Ctx.ctx%elem_id
!   KSTEP           → PH_Cons_Base_Ctx.ctx%kstep
!   KINC            → PH_Cons_Base_Ctx.ctx%kinc

MODULE PH_Cons_MPC_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MPC
CONTAINS
  SUBROUTINE MPC(AMATRX, TIME, NODE, JDOF, NDOF, NNODE, COORDS, JTYPE, PROPS, NPROPS, UE, DUE, NOEL, KSTEP, KINC)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[MPC] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE MPC
END MODULE PH_Cons_MPC_Adapter_Mod
