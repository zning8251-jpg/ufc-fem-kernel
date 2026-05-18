!===============================================================================
! MODULE: PH_Field_Ops
! LAYER:  L4_PH
! DOMAIN: Field
! ROLE:   Core — field interpolation and extrapolation operations
! BRIEF:  Interpolate node→IP, extrapolate IP→node, gradient, averaging;
!         generic operations using Desc/Ctx signatures.
!===============================================================================
MODULE PH_Field_Ops
  USE IF_Prec_Core,       ONLY: wp, i4
  USE IF_Err_Brg,    ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Field_Def,  ONLY: PH_Field_Desc, PH_Field_State, PH_Field_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Field_Ops_Init
  PUBLIC :: PH_Field_Ops_Finalize
  PUBLIC :: PH_Field_Interpolate_To_IP
  PUBLIC :: PH_Field_Extrapolate_To_Nodes
  PUBLIC :: PH_Field_Extrapolate_LeastSquares
  PUBLIC :: PH_Field_Average_At_Nodes
  PUBLIC :: PH_Field_Average_VolumeWeighted
  PUBLIC :: PH_Field_Gradient_At_IP
  PUBLIC :: PH_Field_Compute_Invariants

CONTAINS

  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_Ops_Init(desc, state, ctx, status)
    TYPE(PH_Field_Desc),   INTENT(IN)  :: desc
    TYPE(PH_Field_State),  INTENT(OUT) :: state
    TYPE(PH_Field_Ctx),    INTENT(OUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    state%allocated    = .FALSE.
    state%values_set   = .FALSE.
    state%current_step = 0

    ctx%N_shape      = 0.0_wp
    ctx%dN_dx        = 0.0_wp
    ctx%E_mat        = 0.0_wp
    ctx%ip_vals      = 0.0_wp
    ctx%nodal_vals   = 0.0_wp
    ctx%grad         = 0.0_wp
    ctx%stress_voigt = 0.0_wp
    ctx%I1           = 0.0_wp
    ctx%J2           = 0.0_wp
    ctx%J3           = 0.0_wp
    NULLIFY(ctx%nodal_sum)
    NULLIFY(ctx%nodal_count)
    NULLIFY(ctx%nodal_avg)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Ops_Init

  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_Ops_Finalize(state, ctx, status)
    TYPE(PH_Field_State),  INTENT(INOUT) :: state
    TYPE(PH_Field_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    state%allocated = .FALSE.

    NULLIFY(ctx%nodal_sum)
    NULLIFY(ctx%nodal_count)
    NULLIFY(ctx%nodal_avg)

    ctx%N_shape      = 0.0_wp
    ctx%dN_dx        = 0.0_wp
    ctx%E_mat        = 0.0_wp
    ctx%ip_vals      = 0.0_wp
    ctx%nodal_vals   = 0.0_wp
    ctx%grad         = 0.0_wp
    ctx%stress_voigt = 0.0_wp
    ctx%I1           = 0.0_wp
    ctx%J2           = 0.0_wp
    ctx%J3           = 0.0_wp

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Ops_Finalize

  !---------------------------------------------------------------------------
  ! Interpolate nodal values to a single IP:
  ! ip_vals(ic,1) = sum_in N_shape(in) * nodal_vals(ic,in)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_Interpolate_To_IP(desc, ctx, status)
    TYPE(PH_Field_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Field_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: ic, in

    CALL init_error_status(status)
    DO ic = 1, desc%n_comp
      ctx%ip_vals(ic, 1) = 0.0_wp
      DO in = 1, desc%nn
        ctx%ip_vals(ic, 1) = ctx%ip_vals(ic, 1) + &
                              ctx%N_shape(in) * ctx%nodal_vals(ic, in)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Interpolate_To_IP

  !---------------------------------------------------------------------------
  ! Extrapolate IP values to nodes: nodal = E_mat * ip_vals
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_Extrapolate_To_Nodes(desc, ctx, status)
    TYPE(PH_Field_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Field_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: in, ig, ic

    CALL init_error_status(status)
    ctx%nodal_vals = 0.0_wp
    DO in = 1, desc%nn
      DO ig = 1, desc%nip
        DO ic = 1, desc%n_comp
          ctx%nodal_vals(ic, in) = ctx%nodal_vals(ic, in) + &
                                    ctx%E_mat(in, ig) * ctx%ip_vals(ic, ig)
        END DO
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Extrapolate_To_Nodes

  !---------------------------------------------------------------------------
  ! Least-squares extrapolation: GP -> Node
  ! Solves N^T N a = N^T f_gp for nodal values
  ! Uses pre-computed E_mat = (N^T N)^{-1} N^T as the LS extrapolation matrix.
  ! If E_mat is not set, falls back to simple extrapolation.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_Extrapolate_LeastSquares(desc, ctx, status)
    TYPE(PH_Field_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Field_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: in, ig, ic
    REAL(wp) :: NtN(27,27), NtF(27), diag_val
    REAL(wp) :: sol(27)

    CALL init_error_status(status)

    ! Validate dimensions
    IF (desc%nn < 1 .OR. desc%nip < 1 .OR. desc%n_comp < 1) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ! If E_mat is pre-computed (non-zero), use matrix-based extrapolation
    ! E_mat = (N^T N)^{-1} N^T is the optimal LS extrapolation matrix
    diag_val = 0.0_wp
    DO in = 1, MIN(desc%nn, desc%nip)
      diag_val = diag_val + ABS(ctx%E_mat(in, in))
    END DO

    IF (diag_val > 1.0E-30_wp) THEN
      ! Use pre-computed E_mat for extrapolation: nodal = E_mat * ip_vals
      ctx%nodal_vals = 0.0_wp
      DO in = 1, desc%nn
        DO ig = 1, desc%nip
          DO ic = 1, desc%n_comp
            ctx%nodal_vals(ic, in) = ctx%nodal_vals(ic, in) + &
                                      ctx%E_mat(in, ig) * ctx%ip_vals(ic, ig)
          END DO
        END DO
      END DO
    ELSE
      ! Fallback: build N^T N and solve per component
      ! N^T N (nn x nn), N^T F (nn x 1)
      NtN = 0.0_wp
      DO ig = 1, desc%nip
        DO in = 1, desc%nn
          DO ic = 1, desc%nn
            NtN(in, ic) = NtN(in, ic) + ctx%N_shape(in) * ctx%N_shape(ic)
          END DO
        END DO
      END DO

      ! Solve for each component using diagonal approximation
      ! (exact solve requires LAPACK; here use lumped approximation)
      ctx%nodal_vals = 0.0_wp
      DO ic = 1, desc%n_comp
        NtF = 0.0_wp
        DO ig = 1, desc%nip
          DO in = 1, desc%nn
            NtF(in) = NtF(in) + ctx%N_shape(in) * ctx%ip_vals(ic, ig)
          END DO
        END DO
        ! Diagonal solve: a_i = NtF_i / NtN_ii
        DO in = 1, desc%nn
          IF (ABS(NtN(in, in)) > 1.0E-30_wp) THEN
            ctx%nodal_vals(ic, in) = NtF(in) / NtN(in, in)
          ELSE
            ctx%nodal_vals(ic, in) = 0.0_wp
          END IF
        END DO
      END DO
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Extrapolate_LeastSquares

  !---------------------------------------------------------------------------
  ! Average nodal values from element contributions (uses pointers)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_Average_At_Nodes(desc, ctx, status)
    TYPE(PH_Field_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Field_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: in, ic

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(ctx%nodal_sum) .OR. &
        .NOT. ASSOCIATED(ctx%nodal_count) .OR. &
        .NOT. ASSOCIATED(ctx%nodal_avg)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO in = 1, desc%pop%n_nodes
      IF (ctx%nodal_count(in) > 0) THEN
        DO ic = 1, desc%n_comp
          ctx%nodal_avg(ic, in) = ctx%nodal_sum(ic, in) / &
                                   REAL(ctx%nodal_count(in), wp)
        END DO
      ELSE
        ctx%nodal_avg(:, in) = 0.0_wp
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Average_At_Nodes

  !---------------------------------------------------------------------------
  ! Volume-weighted nodal averaging from element contributions
  ! nodal_avg(ic,in) = sum_elem(vol_elem * val_elem) / sum_elem(vol_elem)
  ! Uses ctx%nodal_sum as weighted accumulator and nodal_count as volume sum
  ! Caller must set nodal_sum(ic,in) += vol_e * val_e and
  !   nodal_count(in) = sum of elem volumes touching node in (stored as integer
  !   count, actual volume weights stored in nodal_sum).
  ! This routine expects:
  !   nodal_sum(ic,in) = sum over elements of (V_e * f_e(ic,in))
  !   elem_vol(in)     = accumulated volume per node (via pointer)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_Average_VolumeWeighted(desc, ctx, elem_vol, status)
    TYPE(PH_Field_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Field_Ctx),    INTENT(INOUT) :: ctx
    REAL(wp),              INTENT(IN)    :: elem_vol(:)  ! accumulated volume per node
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: in, ic

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(ctx%nodal_sum) .OR. &
        .NOT. ASSOCIATED(ctx%nodal_avg)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (SIZE(elem_vol) < desc%pop%n_nodes) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO in = 1, desc%pop%n_nodes
      IF (elem_vol(in) > 1.0E-30_wp) THEN
        DO ic = 1, desc%n_comp
          ctx%nodal_avg(ic, in) = ctx%nodal_sum(ic, in) / elem_vol(in)
        END DO
      ELSE
        ctx%nodal_avg(:, in) = 0.0_wp
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Average_VolumeWeighted

  !---------------------------------------------------------------------------
  ! Compute gradient of scalar field at IP: grad = sum(dN_dx * nodal_scalar)
  ! nodal_scalar is an external IN array.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_Gradient_At_IP(desc, ctx, nodal_scalar, status)
    TYPE(PH_Field_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Field_Ctx),    INTENT(INOUT) :: ctx
    REAL(wp),              INTENT(IN)    :: nodal_scalar(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: id, in

    CALL init_error_status(status)
    ctx%grad = 0.0_wp
    DO in = 1, desc%nn
      DO id = 1, desc%cfg%ndim
        ctx%grad(id) = ctx%grad(id) + ctx%dN_dx(id, in) * nodal_scalar(in)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Gradient_At_IP

  !---------------------------------------------------------------------------
  ! Compute stress invariants (I1, J2, J3) from ctx%stress_voigt
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_Compute_Invariants(ctx, status)
    TYPE(PH_Field_Ctx),    INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    REAL(wp) :: s(6), p

    CALL init_error_status(status)

    ! I1 = trace(sigma)
    ctx%I1 = ctx%stress_voigt(1) + ctx%stress_voigt(2) + ctx%stress_voigt(3)

    ! deviatoric stress
    p = ctx%I1 / 3.0_wp
    s(1) = ctx%stress_voigt(1) - p
    s(2) = ctx%stress_voigt(2) - p
    s(3) = ctx%stress_voigt(3) - p
    s(4) = ctx%stress_voigt(4)
    s(5) = ctx%stress_voigt(5)
    s(6) = ctx%stress_voigt(6)

    ! J2 = 0.5 * s:s
    ctx%J2 = 0.5_wp * (s(1)**2 + s(2)**2 + s(3)**2) + &
             s(4)**2 + s(5)**2 + s(6)**2

    ! J3 = det(s)
    ctx%J3 = s(1)*(s(2)*s(3) - s(6)**2) &
           - s(4)*(s(4)*s(3) - s(5)*s(6)) &
           + s(5)*(s(4)*s(6) - s(5)*s(2))

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Compute_Invariants

END MODULE PH_Field_Ops
