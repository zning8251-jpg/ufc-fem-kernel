!===============================================================================
! MODULE: PH_ConstrEmbedded_Def
! LAYER:  L4_PH
! DOMAIN: Constraint / Embedded
! ROLE:   _Def
! BRIEF:  Embedded region type definitions (Desc/State) and P0 lifecycle.
!         Embedded region constrains embedded element/nodes DOFs to follow
!         host element interpolation — kinematic constraints from *EMBEDDED.
!
! P0 FILL: 2026-05-05 — formerly only PH_CONSTR_TYPE_EMBEDDED=6 enum existed
!           without implementation. This file provides the full four-type subset.
!===============================================================================
MODULE PH_ConstrEmbedded_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Public types
  !---------------------------------------------------------------------------
  PUBLIC :: Embedded_Host_Elem
  PUBLIC :: Embedded_Node_Constraint
  PUBLIC :: EmbeddedRegion_Params
  PUBLIC :: EmbeddedRegion_State
  PUBLIC :: EmbeddedRegion_Brg_Ctx

  !---------------------------------------------------------------------------
  ! Public procedures
  !---------------------------------------------------------------------------
  PUBLIC :: EmbeddedRegion_Params_Init
  PUBLIC :: EmbeddedRegion_Params_Valid
  PUBLIC :: EmbeddedRegion_Params_Cleanup
  PUBLIC :: EmbeddedRegion_State_Init

  !===========================================================================
  ! TYPE: Embedded_Host_Elem
  ! DESC: Identifies a host element containing one or more embedded nodes,
  !       with the shape function interpolation data computed during pairing.
  !===========================================================================
  TYPE, PUBLIC :: Embedded_Host_Elem
    INTEGER(i4) :: host_elem_id    = 0_i4     ! Global host element ID
    INTEGER(i4) :: n_embedded      = 0_i4     ! # embedded nodes in this element
    INTEGER(i4), ALLOCATABLE :: embedded_node_ids(:)
    REAL(wp),    ALLOCATABLE :: N_at_embedded(:,:)  ! (n_embedded, n_host_nodes)
    REAL(wp)    :: host_det_J      = 0.0_wp   ! Jacobian determinant at embed pt
    LOGICAL     :: found_host      = .FALSE.  ! Host element found in search
  END TYPE Embedded_Host_Elem

  !===========================================================================
  ! TYPE: Embedded_Node_Constraint
  ! DESC: Single embedded node → its host element + interpolation coeffs.
  !       u_embed = sum_a N_a(xi_embed) * u_host_a
  !===========================================================================
  TYPE, PUBLIC :: Embedded_Node_Constraint
    INTEGER(i4) :: embedded_node_id  = 0_i4
    INTEGER(i4) :: host_elem_id      = 0_i4
    INTEGER(i4) :: n_host_nodes      = 0_i4
    REAL(wp), ALLOCATABLE :: N_host(:)     ! (n_host_nodes) shape func values
    REAL(wp), ALLOCATABLE :: xi_nat(:)     ! (ndim) natural coords in host elem
    REAL(wp)              :: gap_tol       = 1.0e-6_wp
    LOGICAL               :: is_inside     = .FALSE.
  END TYPE Embedded_Node_Constraint

  !===========================================================================
  ! TYPE: EmbeddedRegion_Params
  ! KIND: Desc (frozen after Populate)
  ! DESC: Configuration parameters for one embedded region definition.
  !===========================================================================
  TYPE, PUBLIC :: EmbeddedRegion_Params
    INTEGER(i4) :: region_id         = 0_i4
    CHARACTER(LEN=64) :: name        = ""
    CHARACTER(LEN=64) :: host_set    = ""
    CHARACTER(LEN=64) :: embedded_set = ""
    LOGICAL           :: use_rounding = .TRUE.
    INTEGER(i4)       :: n_embedded_nodes = 0_i4
    INTEGER(i4)       :: n_host_elems     = 0_i4
    TYPE(Embedded_Node_Constraint), ALLOCATABLE :: constraints(:)
    TYPE(Embedded_Host_Elem),       ALLOCATABLE :: host_elems(:)
    REAL(wp)          :: tol_abs = 1.0e-8_wp     ! Absolute constraint tolerance
    REAL(wp)          :: penalty_scale = 1.0e12_wp ! Penalty factor for embedding
    INTEGER(i4)       :: enforcement = 1_i4        ! 1=penalty, 2=Lagrange, 3=elimination
  END TYPE EmbeddedRegion_Params

  !===========================================================================
  ! TYPE: EmbeddedRegion_State
  ! KIND: State (mutable per-step)
  ! DESC: Runtime tracking for embedded region constraints.
  !===========================================================================
  TYPE, PUBLIC :: EmbeddedRegion_State
    LOGICAL     :: initialized     = .FALSE.
    LOGICAL     :: paired          = .FALSE.
    INTEGER(i4) :: n_active_nodes  = 0_i4
    INTEGER(i4) :: n_violations    = 0_i4
    REAL(wp)    :: max_violation   = 0.0_wp
  END TYPE EmbeddedRegion_State

  !===========================================================================
  ! TYPE: EmbeddedRegion_Brg_Ctx
  ! KIND: Ctx (per-call transient)
  ! DESC: Bridge context for L3→L4 population.
  !===========================================================================
  TYPE, PUBLIC :: EmbeddedRegion_Brg_Ctx
    INTEGER(i4) :: src_region_id = 0_i4
    LOGICAL     :: populate_done = .FALSE.
  END TYPE EmbeddedRegion_Brg_Ctx

CONTAINS

  !===========================================================================
  ! [P0] EmbeddedRegion_Params: Init / Valid / Cleanup
  !===========================================================================
  SUBROUTINE EmbeddedRegion_Params_Init(params, region_id, &
      host_set, embedded_set, status, use_rounding)
    TYPE(EmbeddedRegion_Params), INTENT(OUT)  :: params
    INTEGER(i4),                 INTENT(IN)   :: region_id
    CHARACTER(LEN=*),            INTENT(IN)   :: host_set
    CHARACTER(LEN=*),            INTENT(IN)   :: embedded_set
    TYPE(ErrorStatusType),       INTENT(OUT)  :: status
    LOGICAL,                     INTENT(IN), OPTIONAL :: use_rounding

    CALL init_error_status(status)
    params%region_id     = region_id
    params%name          = ""
    params%host_set      = TRIM(host_set)
    params%embedded_set  = TRIM(embedded_set)
    IF (PRESENT(use_rounding)) THEN
      params%use_rounding = use_rounding
    ELSE
      params%use_rounding = .TRUE.
    END IF
    params%n_embedded_nodes = 0_i4
    params%n_host_elems     = 0_i4
    params%tol_abs          = 1.0e-8_wp
    params%penalty_scale    = 1.0e12_wp
    params%enforcement      = 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE EmbeddedRegion_Params_Init

  FUNCTION EmbeddedRegion_Params_Valid(params) RESULT(ok)
    TYPE(EmbeddedRegion_Params), INTENT(IN) :: params
    LOGICAL :: ok
    ok = params%region_id > 0_i4 .AND. &
         LEN_TRIM(params%host_set) > 0 .AND. &
         LEN_TRIM(params%embedded_set) > 0
  END FUNCTION EmbeddedRegion_Params_Valid

  SUBROUTINE EmbeddedRegion_Params_Cleanup(params, status)
    TYPE(EmbeddedRegion_Params), INTENT(INOUT) :: params
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    IF (ALLOCATED(params%constraints)) THEN
      DO i = 1, SIZE(params%constraints)
        IF (ALLOCATED(params%constraints(i)%N_host)) &
          DEALLOCATE(params%constraints(i)%N_host)
        IF (ALLOCATED(params%constraints(i)%xi_nat)) &
          DEALLOCATE(params%constraints(i)%xi_nat)
      END DO
      DEALLOCATE(params%constraints)
    END IF
    IF (ALLOCATED(params%host_elems)) THEN
      DO i = 1, SIZE(params%host_elems)
        IF (ALLOCATED(params%host_elems(i)%embedded_node_ids)) &
          DEALLOCATE(params%host_elems(i)%embedded_node_ids)
        IF (ALLOCATED(params%host_elems(i)%N_at_embedded)) &
          DEALLOCATE(params%host_elems(i)%N_at_embedded)
      END DO
      DEALLOCATE(params%host_elems)
    END IF
    params%region_id = 0_i4
    params%host_set  = ""
    params%embedded_set = ""
    status%status_code = IF_STATUS_OK
  END SUBROUTINE EmbeddedRegion_Params_Cleanup

  !===========================================================================
  ! [P0] EmbeddedRegion_State: Init
  !===========================================================================
  SUBROUTINE EmbeddedRegion_State_Init(state)
    TYPE(EmbeddedRegion_State), INTENT(OUT) :: state
    state%initialized    = .TRUE.
    state%paired         = .FALSE.
    state%n_active_nodes = 0_i4
    state%n_violations   = 0_i4
    state%max_violation  = 0.0_wp
  END SUBROUTINE EmbeddedRegion_State_Init

END MODULE PH_ConstrEmbedded_Def
