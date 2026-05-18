!===============================================================================
! MODULE: PH_Elem_R3D4Defn
! LAYER:  L4_PH
! DOMAIN: Element/Special
! ROLE:   Def
! BRIEF:  R3D4 ï¿?4-node 3D rigid element
!===============================================================================
MODULE PH_Elem_R3D4_Def
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
  PUBLIC :: UF_Elem_R3D4_Calc
  PUBLIC :: PH_ELEM_R3D4_NNODE
  PUBLIC :: PH_ELEM_R3D4_NDOF

  INTEGER(i4), PARAMETER :: PH_ELEM_R3D4_NNODE = 4_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_R3D4_NDOF = 12_i4

CONTAINS

!===============================================================================
! Subroutine: UF_Elem_R3D4_Calc
! Purpose: Calc function for R3D4 rigid element (RT_Elem_Core interface)
!===============================================================================
  SUBROUTINE UF_Elem_R3D4_Calc(ElemType, Formul, Ctx, state_in, &
                                 Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    INTEGER(i4) :: nNode, nDim, nDOF
    INTEGER(i4) :: master_node, constraint_type
    REAL(wp), ALLOCATABLE :: Ke_loc(:,:), Re_loc(:)
    REAL(wp) :: coords(3, 4), u(3, 4)
    REAL(wp) :: K_rigid
    INTEGER(i4) :: i, j, master_idx

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
        message='UF_Elem_R3D4_Calc: expected 4 nodes')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    ! Extract Mat parameters
    master_node = 1
    constraint_type = 1
    K_rigid = 1.0e12_wp  ! Very large stiffness for rigid constraint

    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 1) THEN
        master_node = INT(Mat%props%props(1))
        IF (SIZE(Mat%props%props) >= 2) THEN
          constraint_type = INT(Mat%props%props(2))
        END IF
      END IF
    END IF

    master_idx = MIN(MAX(master_node, 1), nNode)

    ! Extract coordinates
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      IF (ASSOCIATED(state_out%evo%Ke)) state_out%evo%Ke = 0.0_wp
      IF (ASSOCIATED(state_out%Re)) state_out%Re = 0.0_wp
      flags%failed = .TRUE.
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_R3D4_Calc: coords_ref not allocated')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    coords(1:3, 1:4) = Ctx%coords_ref(1:3, 1:4)

    ! Extract displacements
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= 4) THEN
        u(1:3, 1:4) = Ctx%disp_total(1:3, 1:4)
      ELSE
        u = 0.0_wp
      END IF
    ELSE
      u = 0.0_wp
    END IF

    ! Build rigid constraint stiffness matrix
    ALLOCATE(Ke_loc(nDOF, nDOF))
    ALLOCATE(Re_loc(nDOF))
    Ke_loc = 0.0_wp
    Re_loc = 0.0_wp

    DO i = 1, nNode
      IF (i == master_idx) THEN
        ! Master node: large diagonal stiffness
        DO j = 1, nDim
          Ke_loc((i-1)*nDim + j, (i-1)*nDim + j) = K_rigid
        END DO
      ELSE
        ! Slave nodes: constraint to master
        DO j = 1, nDim
          ! Slave node stiffness (coupling to master)
          Ke_loc((i-1)*nDim + j, (i-1)*nDim + j) = K_rigid
          Ke_loc((i-1)*nDim + j, (master_idx-1)*nDim + j) = -K_rigid
          Ke_loc((master_idx-1)*nDim + j, (i-1)*nDim + j) = -K_rigid
          Ke_loc((master_idx-1)*nDim + j, (master_idx-1)*nDim + j) = &
            Ke_loc((master_idx-1)*nDim + j, (master_idx-1)*nDim + j) + K_rigid

          ! Residual: enforce constraint
          Re_loc((i-1)*nDim + j) = -K_rigid * (u(j, i) - u(j, master_idx))
          Re_loc((master_idx-1)*nDim + j) = &
            Re_loc((master_idx-1)*nDim + j) + K_rigid * (u(j, i) - u(j, master_idx))
        END DO
      END IF
    END DO

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

  END SUBROUTINE UF_Elem_R3D4_Calc

END MODULE PH_Elem_R3D4_Def