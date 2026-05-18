!======================================================================
! Module:  UFC_GlobalContainer_Core
! Layer:   L0_Global (Cross-layer singleton)
! Purpose: Top-level container aggregating all 6 layer containers
!          into a single global access point (g_ufc_global).
!
! Theory chain:
!   UFC three-level container hierarchy:
!     UFC_GlobalContainer -> L*_LayerContainer -> *_Domain
!   This is level 1 (the root). Each layer is level 2.
!   Domains within each layer are level 3 (max nesting depth).
!
! Logic chain:
!   g_ufc_global is the ONLY globally-accessible data root.
!   All cross-layer access goes through g_ufc_global%<layer>%<domain>.
!   Init follows dependency order (L1 first, L6 last).
!   Finalize follows strict reverse order (L6 first, L1 last).
!
! Data chain:
!   SAVE + TARGET ensures stable address for pointer access.
!   Init order:  L1 -> L2 -> L3 -> L4 -> L5 -> L6
!   Finalize:    L6 -> L5 -> L4 -> L3 -> L2 -> L1
!
! Status: CORE
! Last verified: 2026-04-26
!======================================================================
MODULE UFC_GlobalContainer_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_L1_Layer, ONLY: IF_L1_LayerContainer
  USE NM_L2_Layer, ONLY: NM_L2_LayerContainer
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  USE PH_L4_Layer, ONLY: PH_L4_Layer_Ctx
  USE RT_L5_Layer, ONLY: RT_L5_LayerContainer
  USE AP_L6_Layer, ONLY: AP_L6_LayerContainer
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! UFC_GlobalContainer - Top-level container (6 layer containers)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: UFC_GlobalContainer
    TYPE(IF_L1_LayerContainer) :: if_layer
    TYPE(NM_L2_LayerContainer) :: nm_layer
    TYPE(MD_L3_LayerContainer) :: md_layer
    TYPE(PH_L4_Layer_Ctx) :: ph_layer
    TYPE(RT_L5_LayerContainer) :: rt_layer
    TYPE(AP_L6_LayerContainer) :: ap_layer
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => UFC_Global_Init
    PROCEDURE :: Finalize => UFC_Global_Finalize
    PROCEDURE :: IsReady  => UFC_Global_IsReady
  END TYPE UFC_GlobalContainer

  TYPE(UFC_GlobalContainer), PUBLIC, SAVE, TARGET :: g_ufc_global

CONTAINS

  !====================================================================
  ! UFC_Global_IsReady - Check if global container is initialized
  !   Used by L4/L5 before accessing md_layer etc.
  !====================================================================
  PURE FUNCTION UFC_Global_IsReady(this) RESULT(ready)
    CLASS(UFC_GlobalContainer), INTENT(IN) :: this
    LOGICAL :: ready
    ready = this%initialized
  END FUNCTION UFC_Global_IsReady

  !====================================================================
  ! UFC_Global_Init - Initialize all layers in dependency order
  !   L1 must be first (error, log, memory, IO, persist, base).
  !   L2 depends on L1 (numerical methods use memory/error).
  !   L3 depends on L1 (model data uses error/memory).
  !   L4 depends on L1, L3 (physics reads model data).
  !   L5 depends on L1..L4 (runtime orchestrates all).
  !   L6 depends on L1 (application layer uses error/IO).
  !
  !   Note: L3 Init requires model_name and spatial_dim.
  !   L4 Init requires stepId (deferred to step execution).
  !   This Init only initializes layers that can be initialized
  !   without FEM-specific parameters. L3/L4 are initialized
  !   later through the application pipeline.
  !====================================================================
  SUBROUTINE UFC_Global_Init(this, nThreads, workDir, status)
    USE omp_lib, ONLY: omp_set_num_threads
    CLASS(UFC_GlobalContainer), INTENT(INOUT) :: this
    INTEGER(i4),                INTENT(IN)    :: nThreads
    CHARACTER(LEN=*),           INTENT(IN)    :: workDir
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (this%initialized) CALL this%Finalize()

    ! 0. Set OpenMP thread count globally (single entry point)
    IF (nThreads > 0) THEN
      CALL omp_set_num_threads(nThreads)
    END IF

    ! 1. L1_IF: infrastructure (error, log, monitor, memory, IO, persist, base)
    CALL this%if_layer%Init(nThreads, workDir, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 2. L2_NM: numerical methods (base, linAlg, solver, eigen, timeInt, bridge)
    CALL this%nm_layer%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 3-4. L3_MD and L4_PH: deferred (require model_name/spatial_dim/stepId)
    !   Initialized via application pipeline:
    !     L6 parse -> L3 Init(model_name, dim) -> L4 Init(stepId)

    ! 5. L5_RT: runtime (bridge domain only currently)
    CALL this%rt_layer%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 6. L6_AP: application (base, input, registry)
    CALL this%ap_layer%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    this%initialized = .TRUE.

  END SUBROUTINE UFC_Global_Init

  !====================================================================
  ! UFC_Global_Finalize - Finalize all layers in strict reverse order
  !   LIFO: last initialized = first finalized.
  !====================================================================
  SUBROUTINE UFC_Global_Finalize(this)
    CLASS(UFC_GlobalContainer), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN

    ! 6 -> 1: strict reverse order
    CALL this%ap_layer%Finalize()
    CALL this%rt_layer%Finalize()
    CALL this%ph_layer%Finalize()
    CALL this%md_layer%Finalize()
    CALL this%nm_layer%Finalize()
    CALL this%if_layer%Finalize()

    this%initialized = .FALSE.

  END SUBROUTINE UFC_Global_Finalize

END MODULE UFC_GlobalContainer_Core
