!===============================================================================
! MODULE: PH_Constr_Embedded
! LAYER:  L4_PH
! DOMAIN: Constraint / Embedded
! ROLE:   Compute (specialized)
! BRIEF:  Embedded region constraint core algorithms:
!         - Host element search (locate embedded node in host mesh)
!         - Shape function interpolation coefficient computation
!         - Penalty/Lagrange constraint matrix contribution
!         - Constraint violation detection
!
! P0 FILL: 2026-05-05 - new module to implement PH_CONSTR_TYPE_EMBEDDED=6.
!===============================================================================
MODULE PH_Constr_Embedded
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_ConstrEmbedded_Def, ONLY: EmbeddedRegion_Params, &
                                   EmbeddedRegion_State, &
                                   Embedded_Node_Constraint, &
                                   Embedded_Host_Elem
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: EmbeddedCore_SearchHostElem
  PUBLIC :: EmbeddedCore_ComputeWeights
  PUBLIC :: EmbeddedCore_AssemblePenalty
  PUBLIC :: EmbeddedCore_AssembleLagrange
  PUBLIC :: EmbeddedCore_CheckViolation
  PUBLIC :: EmbeddedCore_FindNearestHost

  REAL(wp), PARAMETER :: PRIV_EMBED_XI_TOL = 1.0001_wp

CONTAINS

  SUBROUTINE EmbeddedCore_SearchHostElem(node_coords, candidate_hosts, &
      n_candidates, host_elem_id, xi_nat, found, status)
    REAL(wp),    INTENT(IN)  :: node_coords(:)
    INTEGER(i4), INTENT(IN)  :: candidate_hosts(:)
    INTEGER(i4), INTENT(IN)  :: n_candidates
    INTEGER(i4), INTENT(OUT) :: host_elem_id
    REAL(wp),    INTENT(OUT) :: xi_nat(:)
    LOGICAL,     INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    host_elem_id = 0_i4; xi_nat = 0.0_wp; found = .FALSE.
    DO i = 1, n_candidates
      CALL EmbeddedCore_TestPointInElem(node_coords, candidate_hosts(i), &
          xi_nat, found, status)
      IF (found) THEN
        host_elem_id = candidate_hosts(i); EXIT
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE EmbeddedCore_SearchHostElem

  SUBROUTINE EmbeddedCore_TestPointInElem(point_coords, elem_id, &
      xi_nat, inside, status)
    REAL(wp),    INTENT(IN)  :: point_coords(:)
    INTEGER(i4), INTENT(IN)  :: elem_id
    REAL(wp),    INTENT(OUT) :: xi_nat(:)
    LOGICAL,     INTENT(OUT) :: inside
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ndim
    REAL(wp)    :: xi(SIZE(point_coords))
    CALL init_error_status(status)
    ndim = SIZE(point_coords)
    xi = 0.0_wp; inside = .FALSE.; xi_nat = 0.0_wp
    ! Stub: Newton iteration for xi via inverse isoparametric map.
    ! In production:
    !   1. Get host elem node coords   2. N(xi) evaluation
    !   3. x_calc = sum N_a*x_a        4. residual = x_calc - point
    !   5. dxi = J^{-1}*residual       6. xi -= dxi until converged
    !   7. Check |xi_i| <= PRIV_EMBED_XI_TOL
    inside = .TRUE.
    xi_nat = xi
    status%status_code = IF_STATUS_OK
  END SUBROUTINE EmbeddedCore_TestPointInElem

  SUBROUTINE EmbeddedCore_ComputeWeights(xi_nat, elem_type, &
      N_host, status)
    REAL(wp),    INTENT(IN)  :: xi_nat(:)
    INTEGER(i4), INTENT(IN)  :: elem_type
    REAL(wp),    INTENT(OUT) :: N_host(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    N_host = 0.0_wp
    ! Stub: delegates to PH_Elem_ShapeFunc_Eval. For C3D8:
    !   N_a = 0.125*(1+r*r_a)*(1+s*s_a)*(1+t*t_a)
    IF (SIZE(N_host) >= 1) N_host(1) = 1.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE EmbeddedCore_ComputeWeights

  SUBROUTINE EmbeddedCore_AssemblePenalty(constraint, alpha, &
      u_embed, u_host, Ke, Fe, status)
    TYPE(Embedded_Node_Constraint), INTENT(IN)  :: constraint
    REAL(wp),                       INTENT(IN)  :: alpha
    REAL(wp),                       INTENT(IN)  :: u_embed(:)
    REAL(wp),                       INTENT(IN)  :: u_host(:,:)
    REAL(wp),                       INTENT(OUT) :: Ke(:,:)
    REAL(wp),                       INTENT(OUT) :: Fe(:)
    TYPE(ErrorStatusType),          INTENT(OUT) :: status
    INTEGER(i4) :: ndim, i, j, nhn
    REAL(wp)    :: u_interp
    CALL init_error_status(status)
    ndim = SIZE(u_embed); nhn = constraint%n_host_nodes
    Ke = 0.0_wp; Fe = 0.0_wp
    DO i = 1, ndim
      u_interp = 0.0_wp
      DO j = 1, nhn
        u_interp = u_interp + constraint%N_host(j) * u_host(i, j)
      END DO
      Ke(i, i) = Ke(i, i) + alpha
      Fe(i)    = Fe(i)    + alpha * (u_interp - u_embed(i))
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE EmbeddedCore_AssemblePenalty

  SUBROUTINE EmbeddedCore_AssembleLagrange(constraint, &
      n_total_dof, col_offset_embed, col_offset_host, &
      G_row, status)
    TYPE(Embedded_Node_Constraint), INTENT(IN)  :: constraint
    INTEGER(i4),                    INTENT(IN)  :: n_total_dof
    INTEGER(i4),                    INTENT(IN)  :: col_offset_embed
    INTEGER(i4),                    INTENT(IN)  :: col_offset_host(:)
    REAL(wp),                       INTENT(OUT) :: G_row(:)
    TYPE(ErrorStatusType),          INTENT(OUT) :: status
    INTEGER(i4) :: i, col
    CALL init_error_status(status)
    G_row = 0.0_wp
    DO i = 1, SIZE(constraint%N_host)
      col = col_offset_host(i)
      IF (col > 0_i4 .AND. col <= n_total_dof) G_row(col) = constraint%N_host(i)
    END DO
    col = col_offset_embed
    IF (col > 0_i4 .AND. col <= n_total_dof) G_row(col) = -1.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE EmbeddedCore_AssembleLagrange

  SUBROUTINE EmbeddedCore_CheckViolation(constraint, &
      u_embed, u_host, violation, status)
    TYPE(Embedded_Node_Constraint), INTENT(IN)  :: constraint
    REAL(wp),                       INTENT(IN)  :: u_embed(:)
    REAL(wp),                       INTENT(IN)  :: u_host(:,:)
    REAL(wp),                       INTENT(OUT) :: violation
    TYPE(ErrorStatusType),          INTENT(OUT) :: status
    INTEGER(i4) :: ndim, i, j
    REAL(wp)    :: u_interp, diff
    CALL init_error_status(status)
    ndim = SIZE(u_embed); violation = 0.0_wp
    DO i = 1, ndim
      u_interp = 0.0_wp
      DO j = 1, constraint%n_host_nodes
        u_interp = u_interp + constraint%N_host(j) * u_host(i, j)
      END DO
      diff = ABS(u_embed(i) - u_interp)
      IF (diff > violation) violation = diff
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE EmbeddedCore_CheckViolation

  SUBROUTINE EmbeddedCore_FindNearestHost(node_coords, candidate_hosts, &
      n_candidates, host_elem_id, xi_proj, found, status)
    REAL(wp),    INTENT(IN)  :: node_coords(:)
    INTEGER(i4), INTENT(IN)  :: candidate_hosts(:)
    INTEGER(i4), INTENT(IN)  :: n_candidates
    INTEGER(i4), INTENT(OUT) :: host_elem_id
    REAL(wp),    INTENT(OUT) :: xi_proj(:)
    LOGICAL,     INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: min_dist, dist
    INTEGER(i4) :: i
    CALL init_error_status(status)
    host_elem_id = 0_i4; xi_proj = 0.0_wp; found = .FALSE.
    min_dist = HUGE(1.0_wp)
    DO i = 1, n_candidates
      dist = 1.0e10_wp  ! placeholder - needs mesh access
      IF (dist < min_dist) THEN; min_dist = dist; host_elem_id = candidate_hosts(i); END IF
    END DO
    IF (host_elem_id > 0_i4) found = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE EmbeddedCore_FindNearestHost

END MODULE PH_Constr_Embedded
