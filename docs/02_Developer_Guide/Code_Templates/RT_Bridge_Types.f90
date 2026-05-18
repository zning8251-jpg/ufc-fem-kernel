!===============================================================================
! Module: RT_Bridge_Types                                        [Template v1.0]
! Layer:  L5_RT — Runtime Layer
! Domain: Bridge — L4→L5 data handoff descriptors
!
! Purpose:
!   Defines per-domain Bridge_Ctx types that mediate the data handoff from
!   L3_MD/L4_PH descriptors into the L5_RT execution engine at each increment.
!
!   The Bridge pattern eliminates direct L5→L3 field access:
!     L3_MD Desc (immutable)  ─────┐
!     L4_PH Algo (pre-config) ─────┤→ RT_XXX_Bridge_Ctx → L5 domain Ctx
!     Runtime scalars (dtime) ─────┘
!
! Type catalogue (9 TYPEs — one per Abaqus subroutine domain):
!   RT_Mat_Bridge_Ctx        – Material bridge (UMAT/VUMAT)
!   RT_Elem_Bridge_Ctx       – Element bridge (UEL/VUEL)
!   RT_Load_Bridge_Ctx       – Load bridge (DLOAD/VDLOAD/DFLUX/FILM/HETVAL)
!   RT_BC_Bridge_Ctx         – BC bridge (DISP/VDISP/UPOT/UTEMP/UMASFL)
!   RT_Contact_Bridge_Ctx    – Contact bridge (UINTER/VUINTER/GAPCON)
!   RT_Fric_Bridge_Ctx       – Friction bridge (FRIC/VFRIC/FRIC_COEF)
!   RT_Constr_Bridge_Ctx     – Constraint bridge (UMPC/VMPC)
!   RT_Field_Bridge_Ctx      – Field bridge (USDFLD/VUSDFLD/UFIELD/SDVINI)
!   RT_Analy_Bridge_Ctx      – Analysis bridge (UEXTERNALDB/UAMP/UVARM)
!
! Design rules:
!   1. All pointer fields are NON-OWNING; targets live in domain registries.
!   2. Bridge_Ctx is populated by the assembly layer before each subroutine call.
!   3. Bridge_Ctx is cleared (pointers NULLified) after each call group.
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!===============================================================================
MODULE RT_Bridge_Types
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

  !-- Bridge state flags
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_BRIDGE_IDLE    = 0_i4  ! Not populated  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_BRIDGE_READY   = 1_i4  ! Ready for call  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_BRIDGE_DONE    = 2_i4  ! Call completed  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_BRIDGE_ERROR   = 3_i4  ! Error in bridge  ! migrated

  !-----------------------------------------------------------------------------
  ! RT_Mat_Bridge_Ctx — Material domain bridge
  !   Carries per-increment material identity and references to L3/L4 data.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Mat_Bridge_Ctx
    !-- Material identity (filled from L3_MD registry)
    INTEGER(i4) :: mat_id       = 0_i4   ! Material ID
    INTEGER(i4) :: mat_family   = 0_i4   ! MAT_FAMILY_XXX enum
    INTEGER(i4) :: integ_pt_id  = 0_i4   ! Integration point index

    !-- L4 algorithm reference (non-owning pointer concept via integer ID)
    INTEGER(i4) :: algo_id      = 0_i4   ! Index into PH_Mat algo registry

    !-- Per-call scalars (filled by bridge before UMAT/VUMAT call)
    REAL(wp) :: dtime       = 0.0_wp   ! Current time increment [s]
    REAL(wp) :: time_step   = 0.0_wp   ! Step time at start of increment
    REAL(wp) :: time_total  = 0.0_wp   ! Total accumulated time
    INTEGER(i4) :: kstep    = 0_i4     ! Current step number
    INTEGER(i4) :: kinc     = 0_i4     ! Current increment number
    INTEGER(i4) :: noel     = 0_i4     ! Element number
    INTEGER(i4) :: npt      = 0_i4     ! Integration point number

    !-- Bridge state
    INTEGER(i4) :: bridge_state = BRIDGE_IDLE
  END TYPE RT_Mat_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Elem_Bridge_Ctx — Element domain bridge
  !   Carries element identity and LFLAGS for UEL/VUEL dispatch.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Elem_Bridge_Ctx
    !-- Element identity
    INTEGER(i4) :: elem_id      = 0_i4
    INTEGER(i4) :: jtype        = 0_i4   ! JTYPE: element formulation
    INTEGER(i4) :: elem_family  = 0_i4   ! ELEM_FAMILY_XXX

    !-- LFLAGS (Abaqus UEL lflags array — 5 entries standard)
    INTEGER(i4) :: lflags(5)    = 0_i4   ! UEL LFLAGS: procedure/convergence flags

    !-- Increment scalars
    REAL(wp) :: dtime        = 0.0_wp
    REAL(wp) :: time_step    = 0.0_wp
    REAL(wp) :: time_total   = 0.0_wp
    INTEGER(i4) :: kstep     = 0_i4
    INTEGER(i4) :: kinc      = 0_i4
    INTEGER(i4) :: nrhs      = 1_i4     ! NRHS: number of RHS vectors

    !-- Symmetry flag (0=unsymmetric, 1=symmetric stiffness)
    INTEGER(i4) :: isym = 1_i4

    INTEGER(i4) :: bridge_state = BRIDGE_IDLE
  END TYPE RT_Elem_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Load_Bridge_Ctx — Load domain bridge
  !   Routes distributed loads / flux / film to the appropriate subroutine.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Load_Bridge_Ctx
    INTEGER(i4) :: noel          = 0_i4  ! Element number
    INTEGER(i4) :: npt           = 0_i4  ! Integration point / face point
    INTEGER(i4) :: jltyp         = 0_i4  ! Load type code (JLTYP)
    INTEGER(i4) :: load_subrt    = 0_i4  ! 1=DLOAD,2=VDLOAD,3=DFLUX,4=FILM,5=HETVAL

    CHARACTER(LEN=80) :: sname   = ''    ! *ELSET or surface set name
    CHARACTER(LEN=80) :: cmname  = ''    ! Material name (for HETVAL)

    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    REAL(wp) :: amplitude  = 1.0_wp

    INTEGER(i4) :: bridge_state = BRIDGE_IDLE
  END TYPE RT_Load_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_BC_Bridge_Ctx — Boundary condition domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_BC_Bridge_Ctx
    INTEGER(i4) :: node_id     = 0_i4  ! Node number
    INTEGER(i4) :: dof_id      = 0_i4  ! DOF index
    INTEGER(i4) :: bc_subrt    = 0_i4  ! 1=DISP,2=VDISP,3=UPOT,4=UTEMP,5=UMASFL

    CHARACTER(LEN=8) :: doflab = ''    ! DOF label string

    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp

    INTEGER(i4) :: kstep    = 0_i4
    INTEGER(i4) :: kinc     = 0_i4
    INTEGER(i4) :: bridge_state = BRIDGE_IDLE
  END TYPE RT_BC_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Contact_Bridge_Ctx — Contact domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_Bridge_Ctx
    INTEGER(i4) :: surf_id     = 0_i4  ! Contact surface/pair identifier
    INTEGER(i4) :: contact_subrt = 0_i4 ! 1=UINTER,2=VUINTER,3=GAPCON,4=GAPUNIT

    REAL(wp) :: gap        = 0.0_wp   ! Current gap [m]
    REAL(wp) :: pressure   = 0.0_wp   ! Contact pressure [Pa]
    REAL(wp) :: coords(3)  = 0.0_wp   ! Contact point coords

    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4

    INTEGER(i4) :: bridge_state = BRIDGE_IDLE
  END TYPE RT_Contact_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Fric_Bridge_Ctx — Friction domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Fric_Bridge_Ctx
    INTEGER(i4) :: surf_id     = 0_i4  ! Contact surface identifier
    INTEGER(i4) :: fric_subrt  = 0_i4  ! 1=FRIC,2=VFRIC,3=FRIC_COEF,4=VFRIC_COEF

    REAL(wp) :: pressure   = 0.0_wp   ! Normal pressure [Pa]
    REAL(wp) :: temp       = 0.0_wp   ! Contact temperature [K]
    REAL(wp) :: coords(3)  = 0.0_wp

    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4

    INTEGER(i4) :: bridge_state = BRIDGE_IDLE
  END TYPE RT_Fric_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Constr_Bridge_Ctx — Constraint domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Constr_Bridge_Ctx
    INTEGER(i4) :: constr_id   = 0_i4  ! Constraint identifier
    INTEGER(i4) :: constr_subrt = 0_i4 ! 1=UMPC,2=VMPC,3=UMESHMOTION

    INTEGER(i4) :: nterms  = 0_i4   ! Number of terms in MPC
    INTEGER(i4) :: nblock  = 1_i4   ! Block size (VMPC)

    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4

    INTEGER(i4) :: bridge_state = BRIDGE_IDLE
  END TYPE RT_Constr_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Field_Bridge_Ctx — Field variable domain bridge
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Field_Bridge_Ctx
    INTEGER(i4) :: noel        = 0_i4  ! Element number
    INTEGER(i4) :: npt         = 0_i4  ! Integration point
    INTEGER(i4) :: field_subrt = 0_i4  ! 1=USDFLD,2=VUSDFLD,3=UFIELD,4=SDVINI,5=SIGINI

    INTEGER(i4) :: nfield  = 0_i4  ! Number of field variables
    INTEGER(i4) :: nstatv  = 0_i4  ! Number of state variables

    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4

    INTEGER(i4) :: bridge_state = BRIDGE_IDLE
  END TYPE RT_Field_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Analy_Bridge_Ctx — Analysis control domain bridge
  !   Handles UEXTERNALDB LOP dispatch and UAMP/UVARM per-increment calls.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Analy_Bridge_Ctx
    INTEGER(i4) :: lop           = -1_i4  ! LOP: lifecycle event code
    INTEGER(i4) :: analy_subrt   = 0_i4   ! 1=UEXTERNALDB,2=UAMP,3=VUAMP,4=UVARM

    CHARACTER(LEN=80) :: ampname = ''    ! Amplitude name (UAMP)

    INTEGER(i4) :: noel    = 0_i4   ! Element number (for UVARM)
    INTEGER(i4) :: npt     = 0_i4   ! Integration point (for UVARM)
    INTEGER(i4) :: nblock  = 1_i4   ! Block size (VUAMP)
    INTEGER(i4) :: nuvarm  = 0_i4   ! Number of user output variables

    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4

    INTEGER(i4) :: bridge_state = BRIDGE_IDLE
  END TYPE RT_Analy_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Mesh_Bridge_Ctx — Mesh data bridge (L3_MD → L5_RT)
  !   Carries non-owning pointers to node/element topology from MD layer
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Mesh_Bridge_Ctx
    INTEGER(i4)          :: bridge_status = 0_i4   ! BRIDGE_IDLE/READY/DONE/ERROR
    INTEGER(i4)          :: n_nodes       = 0_i4
    INTEGER(i4)          :: n_elems       = 0_i4
    INTEGER(i4)          :: n_dofs        = 0_i4
    ! Non-owning pointers into MD mesh arrays (no data ownership)
    REAL(wp),    POINTER :: coord(:,:)    => NULL()  ! [ndim, n_nodes]
    INTEGER(i4), POINTER :: connect(:,:)  => NULL()  ! [nnode_per_elem, n_elems]
    INTEGER(i4), POINTER :: dof_map(:,:)  => NULL()  ! [ndof_per_node, n_nodes]
  END TYPE RT_Mesh_Bridge_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Step_Bridge_Ctx — Step configuration bridge (L3_MD → L5_RT)
  !   Carries non-owning pointer to the active step Desc and time data
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Step_Bridge_Ctx
    INTEGER(i4) :: bridge_status  = 0_i4
    INTEGER(i4) :: step_id        = 0_i4
    INTEGER(i4) :: proc_family    = 0_i4   ! STEP_PROC_XXX constant
    REAL(wp)    :: time_period    = 0.0_wp
    REAL(wp)    :: time_in_step   = 0.0_wp
    REAL(wp)    :: dt_current     = 0.0_wp
    REAL(wp)    :: dt_min         = 0.0_wp
    REAL(wp)    :: dt_max         = 0.0_wp
    INTEGER(i4) :: kinc           = 0_i4
  END TYPE RT_Step_Bridge_Ctx

END MODULE RT_Bridge_Types
