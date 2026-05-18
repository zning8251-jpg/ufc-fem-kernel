!===============================================================================
! Module: RT_Domain_Types                                        [Template v1.0]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: All 9 Domains — Runtime Ctx types for each execution domain
!
! Purpose:
!   Defines the L5_RT runtime context (Ctx) types for ALL 9 UFC domains.
!   Each RT_XXX_Ctx aggregates the domain-specific PH_ types (Ctx + State)
!   with a pointer to RT_Com_Base_Ctx (which in turn points to RT_Global_Ctx).
!
!   This module is the "glue layer" that assembles the complete call packet
!   for each Abaqus subroutine invocation at runtime.
!
! Three-level Ctx hierarchy:
!   Level 1 (Global):  RT_Global_Ctx     — singleton, time/step source
!   Level 2 (Common):  RT_Com_Base_Ctx   — per-call framework context
!   Level 3 (Domain):  RT_XXX_Domain_Ctx — domain-specific aggregator
!
! Zero-copy time access pattern:
!   mat_rt_ctx%com_ctx%global_ctx%time_current  (no copy, pointer chain)
!
! Domain list (9 domains):
!   RT_Mat_Domain_Ctx       — Material: UMAT / VUMAT
!   RT_Elem_Domain_Ctx      — Element:  UEL / VUEL
!   RT_Load_Domain_Ctx      — Load:     DLOAD / DFLUX / FILM / HETVAL
!   RT_BC_Domain_Ctx        — BC:       DISP / UPOT / UTEMP / UMASFL
!   RT_Contact_Domain_Ctx   — Contact:  UINTER / VUINTER / GAPCON
!   RT_Fric_Domain_Ctx      — Friction: FRIC / VFRIC / FRIC_COEF
!   RT_Constr_Domain_Ctx    — Constraint: UMPC / UMESHMOTION
!   RT_Field_Domain_Ctx     — Field:    USDFLD / VUSDFLD / UFIELD / SDVINI
!   RT_Analy_Domain_Ctx     — Analysis: UEXTERNALDB / UAMP / UVARM
!
! Layer dependency:
!   USE IF_Prec           (wp, i4)
!   USE RT_Global_Types   (RT_Global_Ctx)
!   USE RT_Com_Types      (RT_Com_Base_Ctx)
!   USE PH_Mat_Types      (PH_Mat_Base_Ctx, PH_Mat_Base_State, ...)
!   USE PH_Elem_Types     (PH_Elem_Base_Ctx, PH_Elem_Base_State, ...)
!   USE PH_Load_Types     (PH_Load_Base_Ctx, PH_Load_Base_State, ...)
!   USE PH_BC_Types       (PH_BC_Base_Ctx, PH_BC_Base_State, ...)
!   USE PH_Contact_Types  (PH_Contact_Base_Ctx, PH_Contact_Base_State, ...)
!   USE PH_Friction_Types (PH_Fric_Base_Ctx, PH_Fric_Base_State, ...)
!   USE PH_Constraint_Types (PH_Constr_Base_Ctx, PH_Constr_Base_State, ...)
!   USE PH_Field_Def      (PH_Field_Ctx, PH_Field_State, ...)
!   USE PH_Analysis_Types (PH_Analy_Base_Ctx, PH_Analy_Base_State, ...)
!===============================================================================
MODULE RT_Domain_Types
  USE IF_Prec_Core,             ONLY: wp, i4
  USE IF_Err_Brg,          ONLY: ErrorStatusType
  USE RT_Global_Types,     ONLY: RT_Global_Ctx
  USE RT_Com_Types,        ONLY: RT_Com_Base_Ctx
  USE PH_Mat_Types,        ONLY: PH_Mat_Base_Ctx, PH_Mat_Base_State
  USE PH_Elem_Types,       ONLY: PH_Elem_Base_Ctx, PH_Elem_Base_State
  USE PH_Load_Types,       ONLY: PH_Load_Base_Ctx, PH_Load_Base_State, &
                                  PH_Load_Base_Algo
  USE PH_BC_Types,         ONLY: PH_BC_Base_Ctx, PH_BC_Base_State, &
                                  PH_BC_Base_Algo
  USE PH_Contact_Types,    ONLY: PH_Contact_Base_Ctx, PH_Contact_Base_State, &
                                  PH_Contact_Base_Algo
  USE PH_Friction_Types,   ONLY: PH_Fric_Base_Ctx, PH_Fric_Base_State, &
                                  PH_Fric_Base_Algo
  USE PH_Constraint_Types, ONLY: PH_Constr_Base_Ctx, PH_Constr_Base_State, &
                                  PH_Constr_Base_Algo
  USE PH_Field_Def,        ONLY: PH_Field_Ctx, PH_Field_State, &
                                  PH_Field_Algo
  USE PH_Analysis_Types,   ONLY: PH_Analy_Base_Ctx, PH_Analy_Base_State, &
                                  PH_Analy_Base_Algo
  !-- New domain types from this-round additions
  USE PH_Special_Types,    ONLY: PH_Spec_DFLOW_Ctx,   PH_Spec_DFLOW_State, &
                                  PH_Spec_HARDINI_Ctx, PH_Spec_HARDINI_State, &
                                  PH_Spec_RSURFU_Ctx,  PH_Spec_RSURFU_State, &
                                  PH_Spec_UCORR_Ctx,   PH_Spec_UCORR_State, &
                                  PH_Spec_UGENS_Ctx,   PH_Spec_UGENS_State
  USE PH_Fluid_Types,      ONLY: PH_Fluid_UFLUID_Ctx,  PH_Fluid_UFLUID_State, &
                                  PH_Fluid_UDECURRENT_Ctx, &
                                  PH_Fluid_UFLUIDCONNECTORLOSS_Ctx, &
                                  PH_Fluid_UFLUIDLEAKOFF_Ctx, &
                                  PH_Fluid_UFLUIDPIPEFRICTION_Ctx
  USE PH_Misc_Types,       ONLY: PH_Misc_UMOTION_Ctx,  PH_Misc_UMOTION_State, &
                                  PH_Misc_UDMGINI_Ctx,  PH_Misc_UDMGINI_State, &
                                  PH_Misc_UTRSNETWORK_Ctx, &
                                  PH_Misc_UXFEMNONLOCALWEIGHT_Ctx
  USE PH_CFD_Types,        ONLY: PH_CFD_PressureBC_Ctx, PH_CFD_PressureBC_State, &
                                  PH_CFD_VelocityBC_Ctx, PH_CFD_VelocityBC_State
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Mat_Domain_Ctx
  PUBLIC :: RT_Elem_Domain_Ctx
  PUBLIC :: RT_Load_Domain_Ctx
  PUBLIC :: RT_BC_Domain_Ctx
  PUBLIC :: RT_Contact_Domain_Ctx
  PUBLIC :: RT_Fric_Domain_Ctx
  PUBLIC :: RT_Constr_Domain_Ctx
  PUBLIC :: RT_Field_Domain_Ctx
  PUBLIC :: RT_Analy_Domain_Ctx
  !-- New domains added in this round (Special/Fluid/Misc/CFD)
  PUBLIC :: RT_Special_Domain_Ctx
  PUBLIC :: RT_Fluid_Domain_Ctx
  PUBLIC :: RT_Misc_Domain_Ctx
  PUBLIC :: RT_CFD_Domain_Ctx

  !=============================================================================
  ! ① RT_Mat_Domain_Ctx — Material domain runtime context
  !    Aggregates UMAT / VUMAT call packet
  !    Zero-copy time: this%com_ctx%global_ctx%time_current
  !=============================================================================
  TYPE, PUBLIC :: RT_Mat_Domain_Ctx
    !-- Framework channel (pointer to RT_Com_Base_Ctx; set before every call)
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics driving inputs (per-increment, filled by bridge)
    TYPE(PH_Mat_Base_Ctx)   :: ph_ctx
    !-- Physics state (history + outputs, updated in place)
    TYPE(PH_Mat_Base_State), POINTER :: ph_state => NULL()
    !-- Time-step feedback scalar (pnewdt: <1=cut, >1=grow, =1=no change)
    REAL(wp) :: pnewdt = 1.0_wp
    !-- Subroutine family identifier (MAT_FAMILY_UMAT / VUMAT / CREEP / ...)
    INTEGER(i4) :: mat_family = 0_i4
  END TYPE RT_Mat_Domain_Ctx

  !=============================================================================
  ! ② RT_Elem_Domain_Ctx — Element domain runtime context
  !    Aggregates UEL / VUEL call packet
  !=============================================================================
  TYPE, PUBLIC :: RT_Elem_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics driving inputs
    TYPE(PH_Elem_Base_Ctx)   :: ph_ctx
    !-- Physics state (RHS, AMATRX, SVARS, ENERGY)
    TYPE(PH_Elem_Base_State), POINTER :: ph_state => NULL()
    !-- Time-step feedback
    REAL(wp) :: pnewdt = 1.0_wp
    !-- Element family (ELEM_FAMILY_UEL / VUEL / UELMAT)
    INTEGER(i4) :: elem_family = 0_i4
    !-- Element type flag (JTYPE from ABAQUS)
    INTEGER(i4) :: jtype = 0_i4
  END TYPE RT_Elem_Domain_Ctx

  !=============================================================================
  ! ③ RT_Load_Domain_Ctx — Load domain runtime context
  !    Aggregates DLOAD / VDLOAD / DFLUX / FILM / HETVAL call packet
  !=============================================================================
  TYPE, PUBLIC :: RT_Load_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics driving inputs
    TYPE(PH_Load_Base_Ctx)   :: ph_ctx
    !-- Physics state (computed load output)
    TYPE(PH_Load_Base_State) :: ph_state
    !-- Algorithm control
    TYPE(PH_Load_Base_Algo)  :: ph_algo
    !-- Time-step feedback
    REAL(wp) :: pnewdt = 1.0_wp
    !-- Load family (LOAD_FAMILY_DLOAD / DFLUX / FILM / HETVAL / WAVE)
    INTEGER(i4) :: load_family = 0_i4
  END TYPE RT_Load_Domain_Ctx

  !=============================================================================
  ! ④ RT_BC_Domain_Ctx — Boundary condition domain runtime context
  !    Aggregates DISP / VDISP / UPOT / UTEMP / UMASFL call packet
  !=============================================================================
  TYPE, PUBLIC :: RT_BC_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics driving inputs
    TYPE(PH_BC_Base_Ctx)   :: ph_ctx
    !-- Physics state (prescribed value output)
    TYPE(PH_BC_Base_State) :: ph_state
    !-- Algorithm control
    TYPE(PH_BC_Base_Algo)  :: ph_algo
    !-- Time-step feedback
    REAL(wp) :: pnewdt = 1.0_wp
    !-- BC family (BC_FAMILY_DISP / UPOT / UTEMP / UMASFL)
    INTEGER(i4) :: bc_family = 0_i4
  END TYPE RT_BC_Domain_Ctx

  !=============================================================================
  ! ⑤ RT_Contact_Domain_Ctx — Contact domain runtime context
  !    Aggregates UINTER / VUINTER / GAPCON call packet
  !=============================================================================
  TYPE, PUBLIC :: RT_Contact_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics driving inputs
    TYPE(PH_Contact_Base_Ctx)   :: ph_ctx
    !-- Physics state (traction output)
    TYPE(PH_Contact_Base_State) :: ph_state
    !-- Algorithm control
    TYPE(PH_Contact_Base_Algo)  :: ph_algo
    !-- Time-step feedback
    REAL(wp) :: pnewdt = 1.0_wp
    !-- Contact family (CONTACT_FAMILY_UINTER / VUINTER / GAPCON / GAPELECTR)
    INTEGER(i4) :: contact_family = 0_i4
  END TYPE RT_Contact_Domain_Ctx

  !=============================================================================
  ! ⑥ RT_Fric_Domain_Ctx — Friction domain runtime context
  !    Aggregates FRIC / VFRIC / FRIC_COEF / VFRIC_COEF call packet
  !=============================================================================
  TYPE, PUBLIC :: RT_Fric_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics driving inputs
    TYPE(PH_Fric_Base_Ctx)   :: ph_ctx
    !-- Physics state (traction output)
    TYPE(PH_Fric_Base_State) :: ph_state
    !-- Algorithm control
    TYPE(PH_Fric_Base_Algo)  :: ph_algo
    !-- Time-step feedback
    REAL(wp) :: pnewdt = 1.0_wp
    !-- Friction subroutine family (FRIC_SUBRT_FRIC / VFRIC / FRIC_COEF / VFRIC_COEF)
    INTEGER(i4) :: fric_family = 0_i4
  END TYPE RT_Fric_Domain_Ctx

  !=============================================================================
  ! ⑦ RT_Constr_Domain_Ctx — Constraint domain runtime context
  !    Aggregates UMPC / UMESHMOTION call packet
  !=============================================================================
  TYPE, PUBLIC :: RT_Constr_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics driving inputs
    TYPE(PH_Constr_Base_Ctx)   :: ph_ctx
    !-- Physics state (constraint coefficients output)
    TYPE(PH_Constr_Base_State) :: ph_state
    !-- Algorithm control
    TYPE(PH_Constr_Base_Algo)  :: ph_algo
    !-- Time-step feedback
    REAL(wp) :: pnewdt = 1.0_wp
    !-- Constraint subroutine family (CONSTR_FAMILY_MPC / MESHMOTION / ORIENT)
    INTEGER(i4) :: constr_family = 0_i4
  END TYPE RT_Constr_Domain_Ctx

  !=============================================================================
  ! ⑧ RT_Field_Domain_Ctx — Field variable domain runtime context
  !    Aggregates USDFLD / VUSDFLD / UFIELD / SDVINI call packet
  !=============================================================================
  TYPE, PUBLIC :: RT_Field_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics driving inputs
    TYPE(PH_Field_Base_Ctx)   :: ph_ctx
    !-- Physics state (updated field values output)
    TYPE(PH_Field_Base_State) :: ph_state
    !-- Algorithm control
    TYPE(PH_Field_Base_Algo)  :: ph_algo
    !-- Time-step feedback
    REAL(wp) :: pnewdt = 1.0_wp
    !-- Field subroutine family (FIELD_FAMILY_USDFLD / VUSDFLD / UFIELD / SDVINI)
    INTEGER(i4) :: field_family = 0_i4
  END TYPE RT_Field_Domain_Ctx

  !=============================================================================
  ! ⑨ RT_Analy_Domain_Ctx — Analysis control domain runtime context
  !    Aggregates UEXTERNALDB / UAMP / VUAMP / UVARM call packet
  !=============================================================================
  TYPE, PUBLIC :: RT_Analy_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics driving inputs
    TYPE(PH_Analy_Base_Ctx)   :: ph_ctx
    !-- Physics state (event completion status)
    TYPE(PH_Analy_Base_State) :: ph_state
    !-- Algorithm control
    TYPE(PH_Analy_Base_Algo)  :: ph_algo
    !-- Analysis subroutine family (ANALY_FAMILY_UEXTDB / UAMP / VUAMP / UVARM)
    INTEGER(i4) :: analy_family = 0_i4
  END TYPE RT_Analy_Domain_Ctx

  !=============================================================================
  ! ⑩ RT_Special_Domain_Ctx — Special Standard subroutines domain context
  !    Aggregates: DFLOW / HARDINI / RSURFU / UCORR / UGENS
  !    (pore-fluid seepage, initial hardening, rigid surface geometry,
  !     random-response correlation, beam section stiffness)
  !=============================================================================
  TYPE, PUBLIC :: RT_Special_Domain_Ctx
    !-- Framework channel (Level 2 pointer, non-owning)
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Representative driving contexts (union: only one active per call)
    TYPE(PH_Spec_DFLOW_Ctx)   :: dflow_ctx
    TYPE(PH_Spec_HARDINI_Ctx) :: hardini_ctx
    TYPE(PH_Spec_RSURFU_Ctx)  :: rsurfu_ctx
    TYPE(PH_Spec_UCORR_Ctx)   :: ucorr_ctx
    TYPE(PH_Spec_UGENS_Ctx)   :: ugens_ctx
    !-- Representative output states
    TYPE(PH_Spec_DFLOW_State),   POINTER :: dflow_state   => NULL()
    TYPE(PH_Spec_HARDINI_State), POINTER :: hardini_state => NULL()
    TYPE(PH_Spec_RSURFU_State),  POINTER :: rsurfu_state  => NULL()
    TYPE(PH_Spec_UCORR_State),   POINTER :: ucorr_state   => NULL()
    TYPE(PH_Spec_UGENS_State),   POINTER :: ugens_state   => NULL()
    !-- Active subroutine discriminator
    !   SPEC_FAMILY_DFLOW=1 / HARDINI=2 / RSURFU=3 / UCORR=4 / UGENS=5
    INTEGER(i4) :: spec_family = 0_i4
    !-- pnewdt feedback (unused for most Special routines, default 1.0)
    REAL(wp)    :: pnewdt = 1.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Special_Domain_Ctx

  !=============================================================================
  ! ⑪ RT_Fluid_Domain_Ctx — Fluid/Electromagnetic domain context
  !    Aggregates: UDECURRENT / UDEMPOTENTIAL / UDSECURRENT / UFLUID
  !                UFLUIDCONNECTORLOSS / UFLUIDCONNECTORVALVE
  !                UFLUIDLEAKOFF / UFLUIDPIPEFRICTION
  !=============================================================================
  TYPE, PUBLIC :: RT_Fluid_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Primary physics context (fluid cavity is most common; others share Ctx slot)
    TYPE(PH_Fluid_UFLUID_Ctx)   :: ufluid_ctx
    TYPE(PH_Fluid_UDECURRENT_Ctx)             :: udecurrent_ctx
    TYPE(PH_Fluid_UFLUIDCONNECTORLOSS_Ctx)    :: connector_loss_ctx
    TYPE(PH_Fluid_UFLUIDLEAKOFF_Ctx)          :: leakoff_ctx
    TYPE(PH_Fluid_UFLUIDPIPEFRICTION_Ctx)     :: pipe_friction_ctx
    !-- Primary output state
    TYPE(PH_Fluid_UFLUID_State), POINTER :: ufluid_state => NULL()
    !-- Discriminator
    !   FLUID_FAMILY_UDECURRENT=1 / UDEMPOTENTIAL=2 / UDSECURRENT=3
    !   UFLUID=4 / CONNLOSS=5 / CONNVALVE=6 / LEAKOFF=7 / PIPEFRICTION=8
    INTEGER(i4) :: fluid_family = 0_i4
    REAL(wp)    :: pnewdt = 1.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Fluid_Domain_Ctx

  !=============================================================================
  ! ⑫ RT_Misc_Domain_Ctx — Miscellaneous Standard subroutines domain context
  !    Aggregates: UMOTION / UPOREP / UPRESS / UPSD
  !                UDMGINI / UXFEMNONLOCALWEIGHT / VOIDRI / UTRSNETWORK
  !=============================================================================
  TYPE, PUBLIC :: RT_Misc_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- Physics contexts (one active per call)
    TYPE(PH_Misc_UMOTION_Ctx)              :: umotion_ctx
    TYPE(PH_Misc_UDMGINI_Ctx)              :: udmgini_ctx
    TYPE(PH_Misc_UTRSNETWORK_Ctx)          :: utrsnetwork_ctx
    TYPE(PH_Misc_UXFEMNONLOCALWEIGHT_Ctx)  :: uxfem_ctx
    !-- Output states
    TYPE(PH_Misc_UMOTION_State), POINTER :: umotion_state => NULL()
    TYPE(PH_Misc_UDMGINI_State), POINTER :: udmgini_state => NULL()
    !-- Discriminator
    !   MISC_FAMILY_UMOTION=1 / UPOREP=2 / UPRESS=3 / UPSD=4
    !   UDMGINI=5 / UXFEM=6 / VOIDRI=7 / UTRSNETWORK=8
    INTEGER(i4) :: misc_family = 0_i4
    REAL(wp)    :: pnewdt = 1.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Misc_Domain_Ctx

  !=============================================================================
  ! ⑬ RT_CFD_Domain_Ctx — Abaqus/CFD user subroutine domain context
  !    Aggregates: SMACfdUserPressureBC / SMACfdUserVelocityBC
  !    Note: Original C-interface subroutines; UFC provides Fortran TYPE wrappers
  !          as equivalent data carriers for the L4_PH physics layer.
  !=============================================================================
  TYPE, PUBLIC :: RT_CFD_Domain_Ctx
    !-- Framework channel
    TYPE(RT_Com_Base_Ctx), POINTER :: com_ctx => NULL()
    !-- CFD boundary condition contexts
    TYPE(PH_CFD_PressureBC_Ctx)   :: pressure_bc_ctx
    TYPE(PH_CFD_VelocityBC_Ctx)   :: velocity_bc_ctx
    !-- CFD output states
    TYPE(PH_CFD_PressureBC_State), POINTER :: pressure_bc_state => NULL()
    TYPE(PH_CFD_VelocityBC_State), POINTER :: velocity_bc_state => NULL()
    !-- Discriminator: CFD_FAMILY_PRESSURE_BC=1 / VELOCITY_BC=2
    INTEGER(i4) :: cfd_family = 0_i4
    !-- CFD solver iteration control
    INTEGER(i4) :: cfd_iter    = 0_i4    ! current CFD iteration number
    REAL(wp)    :: cfd_residual = 0.0_wp ! current velocity/pressure residual
    LOGICAL     :: cfd_converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_CFD_Domain_Ctx

END MODULE RT_Domain_Types
