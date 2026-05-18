! Auto-generated adapter for UEL — Jinja2 template not available.
! Subroutine: UEL | Group: element | UFC Domain: Element
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §3
! Core: PH_Elem_UEL_API
! Generated: 2026-04-13T14:31:06.857693+00:00
! Parameters (54):
!   RHS             → PH_Elem_Base_State.elem_state_out%rhs(1:ndofel,1:nrhs)
!   AMATRX          → PH_Elem_Base_State.elem_state_out%amatrx(1:ndofel,1:ndofel)
!   SVARS           → MD_Elem_Base_State.elem_state%svars(1:nsvars)
!    ENERGY         → PH_Elem_Base_State.elem_state_out%energy(1:8)
!   JDLTYP          → MD_Elem_Base_Desc.elem_desc%jdltyp(1:njprop)
!   KSTEP           → PH_Elem_Base_Ctx.elem_ctx%kstep
!   KINC            → PH_Elem_Base_Ctx.elem_ctx%kinc
!   JELEM           → PH_Elem_Base_Ctx.elem_ctx%elem_id
!   TIME            → PH_Elem_Base_Ctx.elem_ctx%step_time/elem_ctx%total_time
!   DTIME           → PH_Elem_Base_Ctx.elem_ctx%dtime
!   NODE            → PH_Elem_Base_Ctx.elem_ctx%node_ids(1:nnode)
!   JDOF            → PH_Elem_Base_Ctx.elem_ctx%dof_map(1:ndofel)
!   JTYPE           → MD_Elem_Base_Desc.elem_desc%jtype
!   NNODE           → MD_Elem_Base_Desc.elem_desc%nnode
!   NDOFEL          → MD_Elem_Base_Desc.elem_desc%ndofel
!   NRHS            → PH_Elem_Base_Ctx.elem_ctx%nrhs
!   NSYMM           → PH_Elem_Base_Ctx.elem_ctx%nsymm
!   MLVARX          → PH_Elem_Base_Ctx.elem_ctx%mlvarx
!   NDLOAD          → MD_Elem_Base_Desc.elem_desc%ndload
!   JDLTYP          → MD_Elem_Base_Desc.elem_desc%jdltyp(1:ndload)
!   PERIOD          → PH_Elem_Base_Ctx.elem_ctx%period
!   LFLAGS          → PH_Elem_Base_Ctx.elem_ctx%lflags(1:6)
!   JPROPS          → MD_Elem_Base_Desc.elem_desc%jprops(1:njprop)
!   NJPROP          → MD_Elem_Base_Desc.elem_desc%njprop
!   NPROPS          → MD_Elem_Base_Desc.elem_desc%nprops
!   PROPS           → MD_Elem_Base_Desc.elem_desc%props(1:nprops)
!   COORDS          → PH_Elem_Base_Ctx.elem_ctx%coords_1d(1:3*nnode)
!   NTENS           → MD_Elem_Base_Algo.elem_desc%ntens
!   NSTATV          → MD_Elem_Base_State.elem_state%nstatv
!   NOEL            → PH_Elem_Base_Ctx.elem_ctx%elem_id
!   NPT             → PH_Elem_Base_Ctx.elem_ctx%gauss_pt
!   KSPT            → PH_Elem_Base_Ctx.elem_ctx%kspt
!   KSPG            → PH_Elem_Base_Ctx.elem_ctx%kspg
!   NLAYER          → PH_Elem_Base_Ctx.elem_ctx%nlayer
!   NPTT            → PH_Elem_Base_Ctx.elem_ctx%npTT
!   JSTEP           → PH_Elem_Base_Ctx.elem_ctx%jstep
!   JINCR           → PH_Elem_Base_Ctx.elem_ctx%jincr
!   QUERY           → PH_Elem_Base_Ctx.elem_ctx%query_flag
!   V               → PH_Elem_Base_Ctx.elem_ctx%v(1:ndofel)
!   U               → PH_Elem_Base_Ctx.elem_ctx%u(1:ndofel)
!   DU              → PH_Elem_Base_Ctx.elem_ctx%du(1:ndofel)
!   A               → PH_Elem_Base_Ctx.elem_ctx%a(1:ndofel)
!   PREDEF          → PH_Elem_Base_Ctx.elem_ctx%predef_ip(1:npredf,1:2)
!   DPRED           → PH_Elem_Base_Ctx.elem_ctx%dpred_ip(1:npredf)
!   CMAUR           → PH_Elem_Base_Ctx.elem_ctx%cmaur
!   NDLJD           → PH_Elem_Base_Ctx.elem_ctx%ndljd
!   MDLtyp          → PH_Elem_Base_Ctx.elem_ctx%mdltyp(1:ndljd)
!   JDLJDs          → PH_Elem_Base_Ctx.elem_ctx%jdljds(1:ndljd)
!   DLJDF           → PH_Elem_Base_Ctx.elem_ctx%dljdf(1:mdof,1:nrhs)
!   SNRM            → PH_Elem_Base_State.elem_state_out%norm_rhs
!   PNEWDT          → PH_Elem_Base_State.elem_state_out%pnewdt
!   NFLUX           → PH_Elem_Base_Ctx.elem_ctx%nflux
!   DKDG            → PH_Elem_Base_State.elem_state_out%dkdg(1:mlvarx,1:mlvarx)
!   SCON            → PH_Elem_Base_State.elem_state_out%scond(1:nlayer)

MODULE PH_Elem_UEL_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UEL
CONTAINS
  SUBROUTINE UEL(RHS, AMATRX, SVARS, ENERGY, JDLTYP, KSTEP, KINC, JELEM, TIME, DTIME, NODE, JDOF, JTYPE, NNODE, NDOFEL, NRHS, NSYMM, MLVARX, NDLOAD, JDLTYP, PERIOD, LFLAGS, JPROPS, NJPROP, NPROPS, PROPS, COORDS, NTENS, NSTATV, NOEL, NPT, KSPT, KSPG, NLAYER, NPTT, JSTEP, JINCR, QUERY, V, U, DU, A, PREDEF, DPRED, CMAUR, NDLJD, MDLtyp, JDLJDs, DLJDF, SNRM, PNEWDT, NFLUX, DKDG, SCON)
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[UEL] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE UEL
END MODULE PH_Elem_UEL_Adapter_Mod
