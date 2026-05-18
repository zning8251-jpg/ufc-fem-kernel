!===============================================================================
! MODULE: PH_Elem_COH2D4Defn
! LAYER:  L4_PH
! DOMAIN: Element/Special
! ROLE:   Def
! BRIEF:  COH2D4 ï¿?4-node 2D cohesive element
!===============================================================================
MODULE PH_Elem_COH2D4_Def
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  USE IF_Base_Def, only: ZERO, ONE
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: wp, i4
  USE MD_Base_ObjModel, only: MatProperties
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                          UF_Elem_PrepareStructStorage
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UF_Elem_COH2D4_Calc
  PUBLIC :: PH_ELEM_COH2D4_NNODE
  PUBLIC :: PH_ELEM_COH2D4_NDOF

  INTEGER(i4), PARAMETER :: PH_ELEM_COH2D4_NNODE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_COH2D4_NDOF = 8_i4

CONTAINS

!===============================================================================
! Subroutine: UF_Elem_COH2D4_Calc
! Purpose: Calc function for COH2D4 cohesive element (RT_Elem_Core interface)
!===============================================================================
  SUBROUTINE UF_Elem_COH2D4_Calc(ElemType, Formul, Ctx, state_in, &
                                   Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDim, nDOF
    REAL(wp) :: K_n, K_s, t_n_max, t_s_max, G_Ic, G_IIc
    REAL(wp) :: delta_n, delta_s, delta_n_max, delta_s_max
    REAL(wp) :: t_n, t_s, d_n, d_s
    REAL(wp), ALLOCATABLE :: Ke_loc(:,:), Re_loc(:)
    REAL(wp) :: coords(2, 4), u(2, 4)
    REAL(wp) :: area
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    nNode = ElemType%numNodes
    nDim = 2_i4
    nDOF = nNode * nDim

    IF (nNode /= 4) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_COH2D4_Calc: expected 4 nodes')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    ! Extract Mat parameters
    K_n = 1.0e10_wp
    K_s = 1.0e10_wp
    t_n_max = 1.0e10_wp
    t_s_max = 1.0e10_wp
    G_Ic = 1.0e10_wp
    G_IIc = 1.0e10_wp

    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 2) THEN
        K_n = Mat%props%props(1)
        K_s = Mat%props%props(2)
        IF (SIZE(Mat%props%props) >= 4) THEN
          t_n_max = Mat%props%props(3)
          t_s_max = Mat%props%props(4)
        END IF
        IF (SIZE(Mat%props%props) >= 6) THEN
          G_Ic = Mat%props%props(5)
          G_IIc = Mat%props%props(6)
        END IF
      END IF
    END IF

    ! Extract coordinates and displacements
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      IF (ASSOCIATED(state_out%evo%Ke)) state_out%evo%Ke = 0.0_wp
      IF (ASSOCIATED(state_out%Re)) state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_COH2D4_Calc: coords_ref not allocated')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    coords(1:2, 1:4) = Ctx%coords_ref(1:2, 1:4)

    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= 4) THEN
        u(1:2, 1:4) = Ctx%disp_total(1:2, 1:4)
      ELSE
        u = 0.0_wp
      END IF
    ELSE
      u = 0.0_wp
    END IF

    ! Compute element area (2D: length)
    area = SQRT((coords(1,2) - coords(1,1))**2 + (coords(2,2) - coords(2,1))**2)

    ! Compute separation (relative displacement)
    delta_n = 0.0_wp
    delta_s = 0.0_wp
    ! Normal separation (simplified: use first two nodes)
    delta_n = u(2, 2) - u(2, 1)
    ! Shear separation
    delta_s = ABS(u(1, 2) - u(1, 1))

    ! Damage evolution
    d_n = 0.0_wp
    d_s = 0.0_wp
    IF (ABS(delta_n) > 0.0_wp) THEN
      delta_n_max = 2.0_wp * G_Ic / MAX(t_n_max, 1.0e-12_wp)
      IF (ABS(delta_n) > delta_n_max) THEN
        d_n = MIN(1.0_wp, ABS(delta_n) / delta_n_max)
      END IF
    END IF
    IF (delta_s > 0.0_wp) THEN
      delta_s_max = 2.0_wp * G_IIc / MAX(t_s_max, 1.0e-12_wp)
      IF (delta_s > delta_s_max) THEN
        d_s = MIN(1.0_wp, delta_s / delta_s_max)
      END IF
    END IF

    ! Traction
    t_n = K_n * delta_n * (1.0_wp - d_n)
    t_s = K_s * delta_s * (1.0_wp - d_s)

    ! Build stiffness matrix
    ALLOCATE(Ke_loc(nDOF, nDOF))
    ALLOCATE(Re_loc(nDOF))
    Ke_loc = 0.0_wp
    Re_loc = 0.0_wp

    DO i = 1, nNode
      DO j = 1, nNode
        IF (i == j) THEN
          ! Diagonal: stiffness contribution
          Ke_loc((i-1)*nDim + 2, (j-1)*nDim + 2) = K_n * (1.0_wp - d_n) * area
          Ke_loc((i-1)*nDim + 1, (i-1)*nDim + 1) = K_s * (1.0_wp - d_s) * area
        ELSE
          ! Off-diagonal: coupling
          Ke_loc((i-1)*nDim + 2, (j-1)*nDim + 2) = -K_n * (1.0_wp - d_n) * area / nNode
        END IF
      END DO
      ! Residual force
      Re_loc((i-1)*nDim + 2) = -t_n * area / nNode
      Re_loc((i-1)*nDim + 1) = -t_s * area / nNode
    END DO

    ! Store results
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
    state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)
    state_out%Me = 0.0_wp
    state_out%Ce = 0.0_wp

    flags%failed = (d_n >= 1.0_wp .OR. d_s >= 1.0_wp)
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    IF (flags%failed) THEN
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_COH2D4_Calc: cohesive traction fully degraded (d_n or d_s >= 1)')
    ELSE
      CALL init_error_status(flags%status, IF_STATUS_OK)
    END IF

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

    DEALLOCATE(Ke_loc, Re_loc)

  END SUBROUTINE UF_Elem_COH2D4_Calc

END MODULE PH_Elem_COH2D4_Def