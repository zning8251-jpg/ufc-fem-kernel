!===============================================================================
! MODULE: PH_ConstrEmbedded_Brg
! LAYER:  L4_PH
! DOMAIN: Constraint / Embedded
! ROLE:   _Brg
! BRIEF:  Bridge module between L3 EmbeddedRegionDef and L4 Embedded region
!         algorithms. Provides Apply/Init/BuildNodePair entry points
!         following the MPC/Tie Bridge pattern.
!===============================================================================
MODULE PH_ConstrEmbedded_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_ConstrEmbedded_Def, ONLY: EmbeddedRegion_Params, &
                                   EmbeddedRegion_State, &
                                   Embedded_Node_Constraint, &
                                   Embedded_Host_Elem, &
                                   EmbeddedRegion_Params_Init, &
                                   EmbeddedRegion_Params_Valid, &
                                   EmbeddedRegion_Params_Cleanup, &
                                   EmbeddedRegion_State_Init
  USE PH_Constr_Embedded, ONLY: EmbeddedCore_SearchHostElem, &
                                EmbeddedCore_ComputeWeights, &
                                EmbeddedCore_AssemblePenalty, &
                                EmbeddedCore_CheckViolation
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Embedded_Apply
  PUBLIC :: Embedded_Init
  PUBLIC :: Embedded_BuildNodePairs
  PUBLIC :: Embedded_ApplyConstraint
  PUBLIC :: Embedded_CheckViolation

CONTAINS

  SUBROUTINE Embedded_Init(params, embedded_set, host_set, region_id, status)
    TYPE(EmbeddedRegion_Params), INTENT(OUT) :: params
    CHARACTER(LEN=*),            INTENT(IN)  :: embedded_set
    CHARACTER(LEN=*),            INTENT(IN)  :: host_set
    INTEGER(i4),                 INTENT(IN)  :: region_id
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    CALL EmbeddedRegion_Params_Init(params, region_id, &
        host_set, embedded_set, status)
  END SUBROUTINE Embedded_Init

  SUBROUTINE Embedded_BuildNodePairs(params, embedded_node_ids, &
      host_elem_candidates, n_embedded, n_candidates, status)
    TYPE(EmbeddedRegion_Params), INTENT(INOUT) :: params
    INTEGER(i4),                 INTENT(IN)     :: embedded_node_ids(:)
    INTEGER(i4),                 INTENT(IN)     :: host_elem_candidates(:)
    INTEGER(i4),                 INTENT(IN)     :: n_embedded
    INTEGER(i4),                 INTENT(IN)     :: n_candidates
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    INTEGER(i4) :: i, host_id
    REAL(wp)    :: xi_nat(3)
    LOGICAL     :: found

    CALL init_error_status(status)

    IF (.NOT. ALLOCATED(params%constraints)) THEN
      ALLOCATE(params%constraints(n_embedded))
    END IF

    DO i = 1, n_embedded
      params%constraints(i)%embedded_node_id = embedded_node_ids(i)

      CALL EmbeddedCore_SearchHostElem( &
          (/ 0.0_wp, 0.0_wp, 0.0_wp /),  &  ! placeholder coords
          host_elem_candidates, n_candidates, &
          host_id, xi_nat, found, status)

      IF (found) THEN
        params%constraints(i)%host_elem_id = host_id
        params%constraints(i)%xi_nat = xi_nat
        params%constraints(i)%is_inside = .TRUE.
        params%n_embedded_nodes = params%n_embedded_nodes + 1_i4
      END IF
    END DO

    params%n_host_elems = n_candidates
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Embedded_BuildNodePairs

  SUBROUTINE Embedded_ApplyConstraint(params, state, &
      u_embed, u_host, Ke, Fe, violation, status)
    TYPE(EmbeddedRegion_Params), INTENT(IN)    :: params
    TYPE(EmbeddedRegion_State),  INTENT(INOUT) :: state
    REAL(wp),                    INTENT(IN)    :: u_embed(:)
    REAL(wp),                    INTENT(IN)    :: u_host(:,:)
    REAL(wp),                    INTENT(OUT)   :: Ke(:,:)
    REAL(wp),                    INTENT(OUT)   :: Fe(:)
    REAL(wp),                    INTENT(OUT)   :: violation
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    CALL init_error_status(status)
    Ke = 0.0_wp; Fe = 0.0_wp; violation = 0.0_wp

    IF (.NOT. ALLOCATED(params%constraints)) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    CALL EmbeddedCore_AssemblePenalty(params%constraints(1), &
        params%penalty_scale, u_embed, u_host, Ke, Fe, status)

    CALL EmbeddedCore_CheckViolation(params%constraints(1), &
        u_embed, u_host, violation, status)

    IF (violation > params%tol_abs) THEN
      state%n_violations = state%n_violations + 1_i4
      IF (violation > state%max_violation) state%max_violation = violation
    END IF

    state%n_active_nodes = params%n_embedded_nodes
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Embedded_ApplyConstraint

  SUBROUTINE Embedded_CheckViolation(params, u_embed, u_host, &
      max_viol, n_viol, status)
    TYPE(EmbeddedRegion_Params), INTENT(IN)  :: params
    REAL(wp),                    INTENT(IN)  :: u_embed(:)
    REAL(wp),                    INTENT(IN)  :: u_host(:,:)
    REAL(wp),                    INTENT(OUT) :: max_viol
    INTEGER(i4),                 INTENT(OUT) :: n_viol
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    REAL(wp) :: viol
    INTEGER(i4) :: i
    CALL init_error_status(status)
    max_viol = 0.0_wp; n_viol = 0_i4
    IF (.NOT. ALLOCATED(params%constraints)) RETURN
    DO i = 1, MIN(SIZE(params%constraints), SIZE(u_embed))
      CALL EmbeddedCore_CheckViolation(params%constraints(i), &
          u_embed, u_host, viol, status)
      IF (viol > max_viol) max_viol = viol
      IF (viol > params%tol_abs) n_viol = n_viol + 1_i4
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Embedded_CheckViolation

  SUBROUTINE Embedded_Apply(params, state, &
      u_embed, u_host, Ke, Fe, status)
    TYPE(EmbeddedRegion_Params), INTENT(IN)    :: params
    TYPE(EmbeddedRegion_State),  INTENT(INOUT) :: state
    REAL(wp),                    INTENT(IN)    :: u_embed(:)
    REAL(wp),                    INTENT(IN)    :: u_host(:,:)
    REAL(wp),                    INTENT(OUT)   :: Ke(:,:)
    REAL(wp),                    INTENT(OUT)   :: Fe(:)
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    REAL(wp) :: violation
    CALL Embedded_ApplyConstraint(params, state, &
        u_embed, u_host, Ke, Fe, violation, status)
  END SUBROUTINE Embedded_Apply

END MODULE PH_ConstrEmbedded_Brg
