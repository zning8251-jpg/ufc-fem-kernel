!===============================================================================
! MODULE: PH_Elem_GK3D4Defn
! LAYER:  L4_PH
! DOMAIN: Element/Special
! ROLE:   Def
! BRIEF:  GK3D4 ï¿?4-node 3D gasket element
!===============================================================================
MODULE PH_Elem_GK3D4_Def
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
  PUBLIC :: UF_Elem_GK3D4_Calc
  PUBLIC :: PH_ELEM_GK3D4_NNODE
  PUBLIC :: PH_ELEM_GK3D4_NDOF

  INTEGER(i4), PARAMETER :: PH_ELEM_GK3D4_NNODE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_GK3D4_NDOF = 12_i4

CONTAINS

  FUNCTION ComputeGasketArea(coords, nNode, nDim) RESULT(area)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: nNode, nDim
    REAL(wp) :: area

    REAL(wp) :: vec1(3), vec2(3), cross(3)

    area = 0.0_wp
    IF (nDim == 3 .AND. nNode >= 4) THEN
      ! 3D: compute area from quadrilateral
      vec1(1:3) = coords(1:3, 2) - coords(1:3, 1)
      vec2(1:3) = coords(1:3, 4) - coords(1:3, 1)
      cross(1) = vec1(2) * vec2(3) - vec1(3) * vec2(2)
      cross(2) = vec1(3) * vec2(1) - vec1(1) * vec2(3)
      cross(3) = vec1(1) * vec2(2) - vec1(2) * vec2(1)
      area = SQRT(cross(1)**2 + cross(2)**2 + cross(3)**2)
    END IF
  END FUNCTION ComputeGasketArea

  SUBROUTINE UF_Elem_GK3D4_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDim, nDOF
    REAL(wp) :: K_g, h_0, p_max
    REAL(wp) :: h_current, p_gasket
    REAL(wp), ALLOCATABLE :: Ke_loc(:,:), Re_loc(:)
    REAL(wp) :: coords(3, 4), u(3, 4)
    REAL(wp) :: area
    INTEGER(i4) :: i

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    nNode = ElemType%numNodes
    nDim = 3_i4
    nDOF = nNode * nDim

    IF (nNode /= 4) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_GK3D4_Calc: expected 4 nodes')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    ! Extract Mat parameters
    K_g = 1.0e10_wp
    h_0 = 1.0_wp
    p_max = 1.0e10_wp

    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 2) THEN
        K_g = Mat%props%props(1)
        h_0 = Mat%props%props(2)
        IF (SIZE(Mat%props%props) >= 3) p_max = Mat%props%props(3)
      END IF
    END IF

    ! Extract coordinates and displacements
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      IF (ASSOCIATED(state_out%evo%Ke)) state_out%evo%Ke = 0.0_wp
      IF (ASSOCIATED(state_out%Re)) state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_GK3D4_Calc: coords_ref not allocated')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    coords(1:3, 1:4) = Ctx%coords_ref(1:3, 1:4)

    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= 4) THEN
        u(1:3, 1:4) = Ctx%disp_total(1:3, 1:4)
      ELSE
        u = 0.0_wp
      END IF
    ELSE
      u = 0.0_wp
    END IF

    ! Compute current thickness
    h_current = h_0 - (u(3, 4) - u(3, 1))
    h_current = MAX(0.0_wp, h_current)  ! No negative thickness

    ! Compute gasket pressure
    IF (h_current < h_0) THEN
      p_gasket = K_g * (h_0 - h_current) / MAX(h_0, 1.0e-12_wp)
      p_gasket = MIN(p_gasket, p_max)
    ELSE
      p_gasket = 0.0_wp  ! No pressure in tension
    END IF

    ! Compute element area (3D: from quadrilateral geometry)
    area = ComputeGasketArea(coords, 4, 3)

    ! Build stiffness matrix
    ALLOCATE(Ke_loc(nDOF, nDOF))
    ALLOCATE(Re_loc(nDOF))
    Ke_loc = 0.0_wp
    Re_loc = 0.0_wp

    IF (h_current < h_0) THEN
      ! Stiffness only in compression
      DO i = 1, nNode
        Ke_loc((i-1)*nDim + 3, (i-1)*nDim + 3) = K_g * area / MAX(h_0, 1.0e-12_wp)
        Re_loc((i-1)*nDim + 3) = -p_gasket * area / nNode
      END DO
    END IF

    ! Store results
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
    state_out%evo%Ke(1:nDOF, 1:nDOF) = Ke_loc(1:nDOF, 1:nDOF)
    state_out%Re(1:nDOF) = Re_loc(1:nDOF)
    state_out%Me = 0.0_wp
    state_out%Ce = 0.0_wp

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    CALL init_error_status(flags%status, IF_STATUS_OK)

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

    DEALLOCATE(Ke_loc, Re_loc)

  END SUBROUTINE UF_Elem_GK3D4_Calc
END MODULE PH_Elem_GK3D4_Def