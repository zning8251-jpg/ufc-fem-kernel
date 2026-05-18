!===============================================================================
! MODULE: PH_Elem_Mass
! LAYER:  L4_PH
! DOMAIN: Element/Special
! ROLE:   Proc
! BRIEF:  Mass element for point masses and distributed masses
!===============================================================================
MODULE PH_Elem_Mass
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  USE IF_Base_Def, only: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: wp, i4
  USE MD_Base_ObjModel, only: MatProperties
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                          UF_Elem_PrepareStructStorage
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UF_Elem_Mass_Calc
  PUBLIC :: PH_Elem_Mass_Material_Update_Routed

CONTAINS

!===============================================================================
! Subroutine: UF_Elem_Mass_Calc
! Purpose: Mass element calculation
!
! Element types:
!   - MASS: Point mass element
!
! Mass matrix:
!   M = m * I  (lumped mass)
!
! Mat parameters:
!   props(1) = m      : Mass value
!
! Reference: ABAQUS Analysis User's Guide, Section 25.1.4
!===============================================================================
  SUBROUTINE UF_Elem_Mass_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
    type(ElemType), intent(in) :: ElemType
    type(ElemFormul), intent(in) :: Formul
    type(ElemCtx), intent(in) :: Ctx
    type(ElemState), intent(in) :: state_in
    type(MatProperties), intent(in) :: Mat
    type(ElemState), intent(inout) :: state_out
    type(ElemFlags), intent(inout) :: flags

    integer(i4) :: nNode, nDim, nDOF
    real(wp) :: m_mass
    real(wp) :: Me_loc(6,6)
    integer(i4) :: i

    CALL init_error_status(flags%status)
    flags%failed = .false.

    nNode = ElemType%pop%n_nodes
    nDim = ElemType%dim
    nDOF = nNode * nDim

    IF (nDOF <= 0 .OR. nDOF > 6) THEN
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      IF (ASSOCIATED(state_out%evo%Ke)) state_out%evo%Ke = 0.0_wp
      IF (ASSOCIATED(state_out%Re)) state_out%Re = 0.0_wp
      IF (ASSOCIATED(state_out%Me)) state_out%Me = 0.0_wp
      IF (ASSOCIATED(state_out%Ce)) state_out%Ce = 0.0_wp
      flags%failed = .TRUE.
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_Mass_Calc: nDOF out of supported range (1..6 for lumped mass)')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
      RETURN
    END IF

    ! Extract mass parameter
    if (allocated(Mat%props)) then
      if (size(Mat%props) >= 1) then
        m_mass = Mat%props(1)
      else
        m_mass = 0.0_wp
      end if
    else if (allocated(Mat%density)) then
      m_mass = Mat%density
    else
      m_mass = 0.0_wp
    end if

    ! Build lumped mass matrix
    Me_loc = 0.0_wp
    do i = 1, min(nDOF, 6)
      Me_loc(i, i) = m_mass / nNode  ! Distribute mass equally to nodes
    end do

    ! Store results
    call UF_Elem_PrepareStructStorage(ElemType, state_out)
    state_out%evo%Ke = 0.0_wp
    state_out%Re = 0.0_wp
    state_out%Me(1:nDOF, 1:nDOF) = Me_loc(1:nDOF, 1:nDOF)
    state_out%Ce = 0.0_wp

    flags%failed = .false.
    flags%suggest_cutback = .false.
    flags%requires_reasse = .false.  ! Mass matrix doesn't change
    flags%stableDt = 0.0_wp
    CALL init_error_status(flags%status, IF_STATUS_OK)

    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt

  END SUBROUTINE UF_Elem_Mass_Calc

  SUBROUTINE PH_Elem_Mass_Material_Update_Routed(rt_ctx, mat_slot, n_node, &
                                                 mass_total, mass_per_node, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_MassScalar

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    INTEGER(i4),               INTENT(IN)    :: n_node
    REAL(wp),                  INTENT(OUT)   :: mass_total
    REAL(wp),                  INTENT(OUT)   :: mass_per_node
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_MassScalar(rt_ctx, mat_slot, n_node, &
                                     mass_total, mass_per_node, status)
  END SUBROUTINE PH_Elem_Mass_Material_Update_Routed

END MODULE PH_Elem_Mass

