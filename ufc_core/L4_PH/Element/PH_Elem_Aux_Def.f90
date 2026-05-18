!===============================================================================
! MODULE: PH_Elem_Aux_Def
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Def
! BRIEF:  Auxiliary TYPE definitions for Element domain.
!         Phase x Verb grouped sub-TYPEs for precise data carrier matching.
! **W2**：辅 **TYPE**（Cfg/Pop/Itr/Lcl…）支撑 **四型** 与 **SIO**；主 **`PH_Elem_Desc`** 仍在 **`PH_Elem_Def`**。
! 
! Naming convention:
!   Auxiliary TYPE: {Layer}_{Domain}_{Phase}_{Verb}_{FourKind}
!   Phase markers:  Cfg/Pop/Stp/Inc/Itr/Lcl
!   Verb markers:   Init/Vld(Validate)/Comp(Compute)/Evo(Evolve)/
!                   Asm(Assemble)/Acc(Access)/Ctl(Control)/Brg(Bridge)
!   FourKind:       Desc/State/Ctx/Algo
!
! Rules:
!   - Auxiliary TYPEs must carry >= 2 fields (over-encapsulation prevention)
!   - Single-field auxiliary TYPEs downgraded to bare fields with annotation
!   - F2003 syntax only
!===============================================================================
MODULE PH_Elem_Aux_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! SECTION: Element Formulation & Control Enum Constants (P1 fill 2026-05-05)
  !=============================================================================

  !-- Formulation variants (mirror MD_ELEM_FORM_*)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FORM_DISP           = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FORM_HYBRID         = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FORM_INCOMPAT       = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FORM_REDUCED        = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FORM_SELECTIVE      = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FORM_FBAR           = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FORM_ASSUMED_STRAIN = 6_i4

  !-- Hourglass control methods (mirror MD_ELEM_HG_*)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_HG_NONE      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_HG_STIFFNESS  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_HG_VISCOUS    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_HG_ENHANCED   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_HG_RELAXED    = 4_i4

  !-- Mass matrix types (mirror MD_ELEM_MASS_*)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_MASS_CONSISTENT = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_MASS_LUMPED     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_MASS_HRZ        = 3_i4

  !-- Integration scheme types (mirror MD_ELEM_INTEG_*)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_INTEG_FULL      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_INTEG_REDUCED   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_INTEG_USER      = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_INTEG_SELECTIVE = 3_i4

  !--- [PUBLIC AUXILIARY TYPES] ---
  PUBLIC :: PH_Elem_Cfg_Init_Desc
  PUBLIC :: PH_Elem_Pop_Vld_Desc
  PUBLIC :: PH_Elem_Itr_Asm_Ctx
  PUBLIC :: PH_Elem_Lcl_Comp_Ctx
  PUBLIC :: PH_Elem_Lcl_Evo_Ctx
  PUBLIC :: PH_Elem_Stp_Ctl_Algo
  PUBLIC :: PH_Elem_Stp_Ctl_Dyn_Algo
  PUBLIC :: PH_Elem_Itr_Asm_ArgHub
  PUBLIC :: PH_Elem_Lcl_Comp_ArgHub
  PUBLIC :: PH_Elem_Lcl_Brg_ArgHub
  PUBLIC :: PH_Elem_Inc_Evo_Ctx
  PUBLIC :: PH_Elem_Stp_Evo_State
  PUBLIC :: PH_Elem_Itr_Acc_State

  !===================================================================
  ! SECTION 1: PH_Elem_Desc AUXILIARY TYPEs
  !===================================================================

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Cfg_Init_Desc
  ! PHASE: Config | VERB: Init
  ! KIND:  Desc (auxiliary)
  ! DESC:  Config-phase initialization fields for element descriptor.
  !        Element type, family, dimension, section classification.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Cfg_Init_Desc
    INTEGER(i4) :: elem_type_id = 0_i4  ! MD_ELEM_C3D8 etc.
    INTEGER(i4) :: family_id    = 0_i4  ! PH_ELEM_FAMILY_*
    INTEGER(i4) :: ndim         = 0_i4  ! spatial dimension
    INTEGER(i4) :: section_type = 0_i4  ! section type from L3
  END TYPE PH_Elem_Cfg_Init_Desc

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Pop_Vld_Desc
  ! PHASE: Populate | VERB: Validate
  ! KIND:  Desc (auxiliary)
  ! DESC:  Populate-phase validation fields for element descriptor.
  !        Topology and DOF counts validated at population time.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Pop_Vld_Desc
    INTEGER(i4) :: n_nodes       = 0_i4
    INTEGER(i4) :: n_dof         = 0_i4
    INTEGER(i4) :: dof_per_node  = 0_i4
    INTEGER(i4) :: n_integration = 0_i4
    INTEGER(i4) :: n_elements    = 0_i4
  END TYPE PH_Elem_Pop_Vld_Desc

  !===================================================================
  ! SECTION 2: PH_Elem_Ctx AUXILIARY TYPEs
  !===================================================================

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Inc_Evo_Ctx
  ! PHASE: Increment | VERB: Evolve
  ! KIND:  Ctx (auxiliary)
  ! DESC:  Increment-phase evolution context - step/increment tracking
  !        for element evolution. Mirrors PH_Mat_Inc_Evo_Ctx pattern.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Elem_Inc_Evo_Ctx

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Itr_Asm_Ctx
  ! PHASE: Iteration | VERB: Assemble
  ! KIND:  Ctx (auxiliary)
  ! DESC:  Iteration-phase assembly context - current integration point
  !        and element tracking, Jacobian and weight at IP.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Itr_Asm_Ctx
    INTEGER(i4) :: current_ip   = 0_i4
    INTEGER(i4) :: current_elem = 0_i4
    REAL(wp)    :: det_J        = 0.0_wp
    REAL(wp)    :: weight       = 0.0_wp
  END TYPE PH_Elem_Itr_Asm_Ctx

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Lcl_Comp_Ctx
  ! PHASE: Local | VERB: Compute
  ! KIND:  Ctx (auxiliary)
  ! DESC:  Local-phase compute context - element displacement workspace,
  !        shape function derivatives and Jacobian matrix.
  !        TYPE-003: *Ctx must not use ALLOCATABLE components; use POINTER targets.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Lcl_Comp_Ctx
    REAL(wp), POINTER :: u_elem(:)   => NULL()   ! (n_dof) total displacement
    REAL(wp), POINTER :: du_elem(:)  => NULL()   ! (n_dof) displacement increment
    REAL(wp), POINTER :: dN_dX(:,:)  => NULL()  ! (ndim,n_node) shape func derivatives
    REAL(wp), POINTER :: J_mat(:,:)  => NULL()  ! (ndim,ndim) Jacobian matrix
  END TYPE PH_Elem_Lcl_Comp_Ctx

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Lcl_Evo_Ctx
  ! PHASE: Local | VERB: Evolve
  ! KIND:  Ctx (auxiliary)
  ! DESC:  Local-phase evolution context - element stiffness matrices
  !        and internal force vector workspace.
  !        TYPE-003: *Ctx must not use ALLOCATABLE components; use POINTER targets.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Lcl_Evo_Ctx
    REAL(wp), POINTER :: Ke_mat(:,:) => NULL()  ! material stiffness
    REAL(wp), POINTER :: Ke_geo(:,:) => NULL()  ! geometric stiffness
    REAL(wp), POINTER :: Ke(:,:)     => NULL()  ! total stiffness
    REAL(wp), POINTER :: R_int(:)    => NULL()  ! internal force
  END TYPE PH_Elem_Lcl_Evo_Ctx

  !===================================================================
  ! SECTION 3B: PH_Elem_State AUXILIARY TYPEs (G8 expansion)
  !===================================================================

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Stp_Evo_State
  ! PHASE: Step | VERB: Evolve
  ! KIND:  State (auxiliary)
  ! DESC:  Step-level evolution tracking — convergence, stiffness status,
  !        active element count. Read/written per step.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Stp_Evo_State
    LOGICAL     :: initialized     = .FALSE.
    LOGICAL     :: stiffness_built = .FALSE.
    INTEGER(i4) :: n_active_elems  = 0_i4
    INTEGER(i4) :: current_step    = 0_i4
    INTEGER(i4) :: n_converged     = 0_i4
  END TYPE PH_Elem_Stp_Evo_State

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Itr_Acc_State
  ! PHASE: Iteration | VERB: Accumulate
  ! KIND:  State (auxiliary)
  ! DESC:  Iteration-level output accumulation — UEL-compatible output arrays
  !        (RHS, AMATRX, SVARS, energy, mass). Zeroed at start of each
  !        increment; accumulated during IP loop.
  !        W2: ≠ PH_UEL_Context (ABI_Flat). These are four-kind State fields;
  !            PH_UEL_Context aligns with external UEL subroutine signature.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Itr_Acc_State
    REAL(wp), ALLOCATABLE :: rhs(:,:)      ! (ndofel, nrhs) residual / RHS
    REAL(wp), ALLOCATABLE :: amatrx(:,:)   ! (ndofel, ndofel) stiffness matrix
    REAL(wp), ALLOCATABLE :: svars(:)      ! (nsvars) solution-dependent state vars
    REAL(wp)              :: energy(8) = 0.0_wp  ! UEL energy output (always 8)
    REAL(wp), ALLOCATABLE :: mass(:,:)    ! (ndofel, ndofel) mass matrix
    REAL(wp), ALLOCATABLE :: damping(:,:)  ! (ndofel, ndofel) damping matrix (Rayleigh)
  END TYPE PH_Elem_Itr_Acc_State

  !===================================================================
  ! SECTION 3: PH_Elem_Algo AUXILIARY TYPEs
  !===================================================================

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Stp_Ctl_Algo
  ! PHASE: Step | VERB: Control
  ! KIND:  Algo (auxiliary)
  ! DESC:  Step-level algorithm control - integration order, hourglass,
  !        NLGeom flag.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Stp_Ctl_Algo
    INTEGER(i4) :: integration_order = 2_i4
    INTEGER(i4) :: hourglass_control = 0_i4    ! 0=none, 1=viscous, 2=stiffness
    REAL(wp)    :: hourglass_coeff   = 0.0_wp
    LOGICAL     :: nlgeom            = .FALSE.
  END TYPE PH_Elem_Stp_Ctl_Algo

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Stp_Ctl_Dyn_Algo
  ! PHASE: Step | VERB: Control (Dynamic)
  ! KIND:  Algo (auxiliary)
  ! DESC:  Dynamic-specific algorithm parameters - reduced integration,
  !        mass type, Rayleigh damping coefficients.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Stp_Ctl_Dyn_Algo
    LOGICAL     :: reduced_integ  = .FALSE.
    INTEGER(i4) :: mass_type      = 1_i4   ! 1=consistent, 2=lumped
    REAL(wp)    :: alpha_rayleigh = 0.0_wp
    REAL(wp)    :: beta_rayleigh  = 0.0_wp
  END TYPE PH_Elem_Stp_Ctl_Dyn_Algo

  ! NOTE: integrator PROCEDURE POINTER stays as bare field in PH_Elem_Algo
  !       with annotation: ! [Phase:Cfg|Verb:Brg] — strategy pattern slot

  !===================================================================
  ! SECTION 4: SIO ARG AGGREGATION HUBS
  !===================================================================

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Itr_Asm_ArgHub
  ! PHASE: Iteration | VERB: Assemble
  ! DESC:  Lightweight marker to avoid circular USE with PH_Elem_Def.
  !        Real aggregation lives in PH_Elem_Def (PH_Elem_Itr_Asm_ArgHub_Real).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Itr_Asm_ArgHub
    INTEGER(i4) :: hub_tag = 0_i4  ! 0=uninit; nonzero marks active aggregation
  END TYPE PH_Elem_Itr_Asm_ArgHub

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Lcl_Comp_ArgHub
  ! PHASE: Local | VERB: Compute
  ! DESC:  Lightweight marker to avoid circular USE with PH_Elem_Def.
  !        Real aggregation lives in PH_Elem_Def (PH_Elem_Lcl_Comp_ArgHub_Real).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Lcl_Comp_ArgHub
    INTEGER(i4) :: hub_tag = 0_i4  ! 0=uninit; nonzero marks active aggregation
  END TYPE PH_Elem_Lcl_Comp_ArgHub

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Lcl_Brg_ArgHub
  ! PHASE: Local | VERB: Bridge
  ! DESC:  Lightweight marker to avoid circular USE with PH_Elem_Def.
  !        Real aggregation lives in PH_Elem_Def (PH_Elem_Lcl_Brg_ArgHub_Real).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Lcl_Brg_ArgHub
    INTEGER(i4) :: hub_tag = 0_i4  ! 0=uninit; nonzero marks active aggregation
  END TYPE PH_Elem_Lcl_Brg_ArgHub

END MODULE PH_Elem_Aux_Def
