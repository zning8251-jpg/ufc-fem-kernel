!===============================================================================
! MODULE: RT_Brg_Def
! LAYER:  L5_RT
! DOMAIN: Bridge
! ROLE:   Def — per-domain Bridge_Ctx types for L4→L5 data handoff
! BRIEF:  9 Bridge_Ctx types (Mat/Elem/Load/BC/Contact/Fric/Constr/Field/Analy) + Mesh/Step.
!   W1 Material: **RT_Mat_Bridge_Ctx** mirrors assembly routing (**mat_family** / **mat_id**) with
!   **RT_Mat_Brg** / **`RT_Mat_Dispatch_Ctx%mat_type`** ↔ **PH_Mat_Desc** — use **Sync** routines below for legacy flat fields.
!===============================================================================
!
! Type catalogue (9 TYPEs):
!   RT_Mat_Bridge_Ctx        �?Material bridge (UMAT/VUMAT)
!   RT_Elem_Bridge_Ctx       �?Element bridge (UEL/VUEL)
!   RT_Load_Bridge_Ctx       �?Load bridge (DLOAD/VDLOAD/DFLUX/FILM/HETVAL)
!   RT_BC_Bridge_Ctx         �?BC bridge (DISP/VDISP/UPOT/UTEMP/UMASFL)
!   RT_Contact_Bridge_Ctx    �?Contact bridge (UINTER/VUINTER/GAPCON)
!   RT_Fric_Bridge_Ctx       �?Friction bridge (FRIC/VFRIC/FRIC_COEF)
!   RT_Constr_Bridge_Ctx     �?Constraint bridge (UMPC/VMPC)
!   RT_Field_Bridge_Ctx      �?Field bridge (USDFLD/VUSDFLD/UFIELD/SDVINI)
!   RT_Analy_Bridge_Ctx      �?Analysis bridge (UEXTERNALDB/UAMP/UVARM)
!
! Design rules:
!   1. All pointer fields are NON-OWNING; targets live in domain registries.
!   2. Bridge_Ctx is populated by the assembly layer before each subroutine call.
!   3. Bridge_Ctx is cleared (pointers NULLified) after each call group.
!
! Layer dependency:
!   USE IF_Prec_Core (wp, i4)  -- actual USE statement below
!===============================================================================
MODULE RT_Brg_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Mat_Bridge_Ctx
  PUBLIC :: RT_Elem_Bridge_Ctx
  PUBLIC :: RT_Load_Bridge_Ctx
  PUBLIC :: RT_BC_Bridge_Ctx
  PUBLIC :: RT_Contact_Bridge_Ctx
  PUBLIC :: RT_Fric_Bridge_Ctx
  PUBLIC :: RT_Constr_Bridge_Ctx
  PUBLIC :: RT_Field_Bridge_Ctx
  PUBLIC :: RT_Analy_Bridge_Ctx
  PUBLIC :: RT_Mesh_Bridge_Ctx
  PUBLIC :: RT_Step_Bridge_Ctx
  !--- [BRIDGE AUXILIARY TYPEs] ---
  PUBLIC :: RT_Mat_Stp_Ctl_BrgCtx
  PUBLIC :: RT_Mat_Lcl_Brg_Ctx
  PUBLIC :: RT_Elem_Stp_Ctl_BrgCtx
  PUBLIC :: RT_Elem_Lcl_Brg_Ctx
  !--- Bridge flat <-> %stp/%lcl mirror sync (W1 assembly / legacy paths) ---
  PUBLIC :: RT_Mat_Bridge_Sync_Aux_From_Deprecated
  PUBLIC :: RT_Mat_Bridge_Sync_Deprecated_From_Aux
  PUBLIC :: RT_Elem_Bridge_Sync_Aux_From_Deprecated
  PUBLIC :: RT_Elem_Bridge_Sync_Deprecated_From_Aux
  PUBLIC :: RT_Bridge_Init
  PUBLIC :: RT_Bridge_SetReady
  PUBLIC :: RT_Bridge_SetDone
  
  !-- Bridge state flags
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_BRIDGE_IDLE    = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_BRIDGE_READY   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_BRIDGE_DONE    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_BRIDGE_ERROR   = 3_i4
  
  !-----------------------------------------------------------------------------
  ! RT_Mat_Stp_Ctl_BrgCtx -- [Phase:Stp|Verb:Ctl] Material bridge Step control
  ! NOTE: L5 Bridge auxiliary TYPEs prohibit ALLOCATABLE (fixed buffer rule)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Mat_Stp_Ctl_BrgCtx
    INTEGER(i4) :: mat_id     = 0_i4
    INTEGER(i4) :: mat_family = 0_i4
    INTEGER(i4) :: algo_id    = 0_i4
  END TYPE RT_Mat_Stp_Ctl_BrgCtx

  !-----------------------------------------------------------------------------
  ! RT_Mat_Lcl_Brg_Ctx -- [Phase:Lcl|Verb:Brg] Material bridge Local fields
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Mat_Lcl_Brg_Ctx
    INTEGER(i4) :: integ_pt_id = 0_i4
    REAL(wp)    :: dtime       = 0.0_wp
    REAL(wp)    :: time_step   = 0.0_wp
    REAL(wp)    :: time_total  = 0.0_wp
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
  END TYPE RT_Mat_Lcl_Brg_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Mat_Bridge_Ctx -- Material domain bridge (restructured by Phase)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Mat_Bridge_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(RT_Mat_Stp_Ctl_BrgCtx) :: stp   ! Step control fields
    TYPE(RT_Mat_Lcl_Brg_Ctx)    :: lcl   ! Local bridge fields
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: mat_id       = 0_i4   ! DEPRECATED: use %stp%mat_id
    INTEGER(i4) :: mat_family   = 0_i4   ! DEPRECATED: use %stp%mat_family
    INTEGER(i4) :: integ_pt_id  = 0_i4   ! DEPRECATED: use %lcl%integ_pt_id
    INTEGER(i4) :: algo_id      = 0_i4   ! DEPRECATED: use %stp%algo_id
    REAL(wp) :: dtime           = 0.0_wp ! DEPRECATED: use %lcl%dtime
    REAL(wp) :: time_step       = 0.0_wp ! DEPRECATED: use %lcl%time_step
    REAL(wp) :: time_total      = 0.0_wp ! DEPRECATED: use %lcl%time_total
    INTEGER(i4) :: kstep        = 0_i4   ! DEPRECATED: use %lcl%kstep
    INTEGER(i4) :: kinc         = 0_i4   ! DEPRECATED: use %lcl%kinc
    INTEGER(i4) :: noel         = 0_i4   ! DEPRECATED: use %lcl%noel
    INTEGER(i4) :: npt          = 0_i4   ! DEPRECATED: use %lcl%npt
    ! [Phase:*|Verb:Ctl] bridge state -- bare field
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Mat_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_Elem_Bridge_Ctx �?Element domain bridge
  !-----------------------------------------------------------------------------
  !-----------------------------------------------------------------------------
  ! RT_Elem_Stp_Ctl_BrgCtx -- [Phase:Stp|Verb:Ctl] Element bridge Step control
  ! NOTE: L5 Bridge auxiliary TYPEs prohibit ALLOCATABLE (fixed buffer rule)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Elem_Stp_Ctl_BrgCtx
    INTEGER(i4) :: elem_id     = 0_i4
    INTEGER(i4) :: jtype       = 0_i4
    INTEGER(i4) :: elem_family = 0_i4
  END TYPE RT_Elem_Stp_Ctl_BrgCtx

  !-----------------------------------------------------------------------------
  ! RT_Elem_Lcl_Brg_Ctx -- [Phase:Lcl|Verb:Brg] Element bridge Local fields
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Elem_Lcl_Brg_Ctx
    INTEGER(i4) :: lflags(5)   = 0_i4
    REAL(wp)    :: dtime       = 0.0_wp
    REAL(wp)    :: time_step   = 0.0_wp
    REAL(wp)    :: time_total  = 0.0_wp
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    INTEGER(i4) :: nrhs        = 1_i4
    INTEGER(i4) :: isym        = 1_i4
  END TYPE RT_Elem_Lcl_Brg_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Elem_Bridge_Ctx -- Element domain bridge (restructured by Phase)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Elem_Bridge_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(RT_Elem_Stp_Ctl_BrgCtx) :: stp  ! Step control fields
    TYPE(RT_Elem_Lcl_Brg_Ctx)    :: lcl  ! Local bridge fields
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: elem_id      = 0_i4   ! DEPRECATED: use %stp%elem_id
    INTEGER(i4) :: jtype        = 0_i4   ! DEPRECATED: use %stp%jtype
    INTEGER(i4) :: elem_family  = 0_i4   ! DEPRECATED: use %stp%elem_family
    INTEGER(i4) :: lflags(5)    = 0_i4   ! DEPRECATED: use %lcl%lflags
    REAL(wp) :: dtime           = 0.0_wp ! DEPRECATED: use %lcl%dtime
    REAL(wp) :: time_step       = 0.0_wp ! DEPRECATED: use %lcl%time_step
    REAL(wp) :: time_total      = 0.0_wp ! DEPRECATED: use %lcl%time_total
    INTEGER(i4) :: kstep        = 0_i4   ! DEPRECATED: use %lcl%kstep
    INTEGER(i4) :: kinc         = 0_i4   ! DEPRECATED: use %lcl%kinc
    INTEGER(i4) :: nrhs         = 1_i4   ! DEPRECATED: use %lcl%nrhs
    INTEGER(i4) :: isym         = 1_i4   ! DEPRECATED: use %lcl%isym
    ! [Phase:*|Verb:Ctl] bridge state -- bare field
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Elem_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_Load_Bridge_Ctx �?Load domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Load_Bridge_Ctx
    INTEGER(i4) :: noel          = 0_i4
    INTEGER(i4) :: npt           = 0_i4
    INTEGER(i4) :: jltyp         = 0_i4
    INTEGER(i4) :: load_subrt    = 0_i4
    
    CHARACTER(LEN=80) :: sname   = ''
    CHARACTER(LEN=80) :: cmname  = ''
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    REAL(wp) :: amplitude  = 1.0_wp
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Load_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_BC_Bridge_Ctx �?Boundary condition domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_BC_Bridge_Ctx
    INTEGER(i4) :: node_id     = 0_i4
    INTEGER(i4) :: dof_id      = 0_i4
    INTEGER(i4) :: bc_subrt    = 0_i4
    
    CHARACTER(LEN=8) :: doflab = ''
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    
    INTEGER(i4) :: kstep    = 0_i4
    INTEGER(i4) :: kinc     = 0_i4
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_BC_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_Contact_Bridge_Ctx �?Contact domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_Bridge_Ctx
    INTEGER(i4) :: surf_id     = 0_i4
    INTEGER(i4) :: contact_subrt = 0_i4
    
    REAL(wp) :: gap        = 0.0_wp
    REAL(wp) :: pressure   = 0.0_wp
    REAL(wp) :: coords(3)  = 0.0_wp
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Contact_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_Fric_Bridge_Ctx �?Friction domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Fric_Bridge_Ctx
    INTEGER(i4) :: surf_id     = 0_i4
    INTEGER(i4) :: fric_subrt  = 0_i4
    
    REAL(wp) :: pressure   = 0.0_wp
    REAL(wp) :: temp       = 0.0_wp
    REAL(wp) :: coords(3)  = 0.0_wp
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Fric_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_Constr_Bridge_Ctx �?Constraint domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Constr_Bridge_Ctx
    INTEGER(i4) :: constr_id   = 0_i4
    INTEGER(i4) :: constr_subrt = 0_i4
    
    INTEGER(i4) :: nterms  = 0_i4
    INTEGER(i4) :: nblock  = 1_i4
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Constr_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_Field_Bridge_Ctx �?Field variable domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Field_Bridge_Ctx
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
    INTEGER(i4) :: field_subrt = 0_i4
    
    INTEGER(i4) :: nfield  = 0_i4
    INTEGER(i4) :: nstatv  = 0_i4
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Field_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_Analy_Bridge_Ctx �?Analysis control domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Analy_Bridge_Ctx
    INTEGER(i4) :: lop           = -1_i4
    INTEGER(i4) :: analy_subrt   = 0_i4
    
    CHARACTER(LEN=80) :: ampname = ''
    
    INTEGER(i4) :: noel    = 0_i4
    INTEGER(i4) :: npt     = 0_i4
    INTEGER(i4) :: nblock  = 1_i4
    INTEGER(i4) :: nuvarm  = 0_i4
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Analy_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_Mesh_Bridge_Ctx �?Mesh data bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Mesh_Bridge_Ctx
    INTEGER(i4)          :: bridge_status = 0_i4
    INTEGER(i4)          :: n_nodes       = 0_i4
    INTEGER(i4)          :: n_elems       = 0_i4
    INTEGER(i4)          :: n_dofs        = 0_i4
    REAL(wp),    POINTER :: coord(:,:)    => NULL()
    INTEGER(i4), POINTER :: connect(:,:)  => NULL()
    INTEGER(i4), POINTER :: dof_map(:,:)  => NULL()
  END TYPE RT_Mesh_Bridge_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_Step_Bridge_Ctx �?Step configuration bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Step_Bridge_Ctx
    INTEGER(i4) :: bridge_status  = 0_i4
    INTEGER(i4) :: step_id        = 0_i4
    INTEGER(i4) :: proc_family    = 0_i4
    REAL(wp)    :: time_period    = 0.0_wp
    REAL(wp)    :: time_in_step   = 0.0_wp
    REAL(wp)    :: dt_current     = 0.0_wp
    REAL(wp)    :: dt_min         = 0.0_wp
    REAL(wp)    :: dt_max         = 0.0_wp
    INTEGER(i4) :: kinc           = 0_i4
  END TYPE RT_Step_Bridge_Ctx
  
CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_*_Bridge_Sync_* — keep deprecated flat fields and %stp/%lcl mirrors aligned.
  ! Call Sync_Aux_From_Deprecated after assembly writes **only** flat fields;
  ! call Sync_Deprecated_From_Aux after code paths write **only** nested fields.
  !-----------------------------------------------------------------------------

  SUBROUTINE RT_Mat_Bridge_Sync_Aux_From_Deprecated(b)
    TYPE(RT_Mat_Bridge_Ctx), INTENT(INOUT) :: b
    b%stp%mat_id     = b%mat_id
    b%stp%mat_family = b%mat_family
    b%stp%algo_id    = b%algo_id
    b%lcl%integ_pt_id = b%integ_pt_id
    b%lcl%dtime       = b%dtime
    b%lcl%time_step   = b%time_step
    b%lcl%time_total  = b%time_total
    b%lcl%kstep       = b%kstep
    b%lcl%kinc        = b%kinc
    b%lcl%noel        = b%noel
    b%lcl%npt         = b%npt
  END SUBROUTINE RT_Mat_Bridge_Sync_Aux_From_Deprecated

  SUBROUTINE RT_Mat_Bridge_Sync_Deprecated_From_Aux(b)
    TYPE(RT_Mat_Bridge_Ctx), INTENT(INOUT) :: b
    b%mat_id     = b%stp%mat_id
    b%mat_family = b%stp%mat_family
    b%algo_id    = b%stp%algo_id
    b%integ_pt_id = b%lcl%integ_pt_id
    b%dtime       = b%lcl%dtime
    b%time_step   = b%lcl%time_step
    b%time_total  = b%lcl%time_total
    b%kstep       = b%lcl%kstep
    b%kinc        = b%lcl%kinc
    b%noel        = b%lcl%noel
    b%npt         = b%lcl%npt
  END SUBROUTINE RT_Mat_Bridge_Sync_Deprecated_From_Aux

  SUBROUTINE RT_Elem_Bridge_Sync_Aux_From_Deprecated(b)
    TYPE(RT_Elem_Bridge_Ctx), INTENT(INOUT) :: b
    b%stp%elem_id     = b%elem_id
    b%stp%jtype       = b%jtype
    b%stp%elem_family = b%elem_family
    b%lcl%lflags      = b%lflags
    b%lcl%dtime       = b%dtime
    b%lcl%time_step   = b%time_step
    b%lcl%time_total  = b%time_total
    b%lcl%kstep       = b%kstep
    b%lcl%kinc        = b%kinc
    b%lcl%nrhs        = b%nrhs
    b%lcl%isym        = b%isym
  END SUBROUTINE RT_Elem_Bridge_Sync_Aux_From_Deprecated

  SUBROUTINE RT_Elem_Bridge_Sync_Deprecated_From_Aux(b)
    TYPE(RT_Elem_Bridge_Ctx), INTENT(INOUT) :: b
    b%elem_id     = b%stp%elem_id
    b%jtype       = b%stp%jtype
    b%elem_family = b%stp%elem_family
    b%lflags      = b%lcl%lflags
    b%dtime       = b%lcl%dtime
    b%time_step   = b%lcl%time_step
    b%time_total  = b%lcl%time_total
    b%kstep       = b%lcl%kstep
    b%kinc        = b%lcl%kinc
    b%nrhs        = b%lcl%nrhs
    b%isym        = b%lcl%isym
  END SUBROUTINE RT_Elem_Bridge_Sync_Deprecated_From_Aux

  ! Helper subroutines for bridge management
  SUBROUTINE RT_Bridge_Init(mat_brg, elem_brg, load_brg, bc_brg, cont_brg, &
                            fric_brg, constr_brg, field_brg, analy_brg)
    TYPE(RT_Mat_Bridge_Ctx), INTENT(OUT), OPTIONAL :: mat_brg
    TYPE(RT_Elem_Bridge_Ctx), INTENT(OUT), OPTIONAL :: elem_brg
    TYPE(RT_Load_Bridge_Ctx), INTENT(OUT), OPTIONAL :: load_brg
    TYPE(RT_BC_Bridge_Ctx), INTENT(OUT), OPTIONAL :: bc_brg
    TYPE(RT_Contact_Bridge_Ctx), INTENT(OUT), OPTIONAL :: cont_brg
    TYPE(RT_Fric_Bridge_Ctx), INTENT(OUT), OPTIONAL :: fric_brg
    TYPE(RT_Constr_Bridge_Ctx), INTENT(OUT), OPTIONAL :: constr_brg
    TYPE(RT_Field_Bridge_Ctx), INTENT(OUT), OPTIONAL :: field_brg
    TYPE(RT_Analy_Bridge_Ctx), INTENT(OUT), OPTIONAL :: analy_brg
    
    IF (PRESENT(mat_brg)) THEN
      ! Structure constructor resets both deprecated flat fields and auxiliary TYPEs (stp, lcl)
      mat_brg = RT_Mat_Bridge_Ctx()
      mat_brg%bridge_state = RT_BRG_BRIDGE_IDLE
      CALL RT_Mat_Bridge_Sync_Aux_From_Deprecated(mat_brg)
    END IF
    IF (PRESENT(elem_brg)) THEN
      ! Structure constructor resets both deprecated flat fields and auxiliary TYPEs (stp, lcl)
      elem_brg = RT_Elem_Bridge_Ctx()
      elem_brg%bridge_state = RT_BRG_BRIDGE_IDLE
      CALL RT_Elem_Bridge_Sync_Aux_From_Deprecated(elem_brg)
    END IF
    IF (PRESENT(load_brg)) THEN
      load_brg%bridge_state = RT_BRG_BRIDGE_IDLE
    END IF
    IF (PRESENT(bc_brg)) THEN
      bc_brg%bridge_state = RT_BRG_BRIDGE_IDLE
    END IF
    IF (PRESENT(cont_brg)) THEN
      cont_brg%bridge_state = RT_BRG_BRIDGE_IDLE
    END IF
    IF (PRESENT(fric_brg)) THEN
      fric_brg%bridge_state = RT_BRG_BRIDGE_IDLE
    END IF
    IF (PRESENT(constr_brg)) THEN
      constr_brg%bridge_state = RT_BRG_BRIDGE_IDLE
    END IF
    IF (PRESENT(field_brg)) THEN
      field_brg%bridge_state = RT_BRG_BRIDGE_IDLE
    END IF
    IF (PRESENT(analy_brg)) THEN
      analy_brg%bridge_state = RT_BRG_BRIDGE_IDLE
    END IF
  END SUBROUTINE RT_Bridge_Init
  
  SUBROUTINE RT_Bridge_SetReady(bridge_ctx)
    INTEGER(i4), INTENT(INOUT) :: bridge_ctx
    
    bridge_ctx = RT_BRG_BRIDGE_READY
  END SUBROUTINE RT_Bridge_SetReady
  
  SUBROUTINE RT_Bridge_SetDone(bridge_ctx)
    INTEGER(i4), INTENT(INOUT) :: bridge_ctx
    
    bridge_ctx = RT_BRG_BRIDGE_DONE
  END SUBROUTINE RT_Bridge_SetDone
  
END MODULE RT_Brg_Def
