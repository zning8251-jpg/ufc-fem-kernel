!===============================================================================
! MODULE: PH_Elem_TrussDefn
! LAYER:  L4_PH
! DOMAIN: Element/Truss
! ROLE:   Def
! BRIEF:  Truss element unified interface
! **W2**：L4 **桁架** 族统一接口；轴向刚度路径与 **`MD_ELEM_BIND_TRUSS`** / **`PH_Elem_Core`** 一致。
!===============================================================================
MODULE PH_Elem_Truss_Def
!> [CORE] Truss element unified interface
!> Theory: K = (EA/L)[1 -1; -1 1], axial force only
!> Status: Production | Last verified: 2026-02-28

  use IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: wp, i4
  use MD_Base_ElemLib
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  use MD_Model_Mgr
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                              UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib, only: MatProperties
  use PH_Elem_T2D2, only: UF_Elem_T2D2_Calc
  use PH_Elem_T3D2, only: UF_Elem_T3D2_Calc
  use PH_Elem_T3D3, only: UF_Elem_T3D3_Calc
  use UF_Material_Base

  implicit none
  private

  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  PUBLIC :: PH_Elem_Truss_Calc_Arg
  PUBLIC :: PH_Elem_Truss_Calc
  PUBLIC :: PH_Elem_Truss_Calc_Structured
  PUBLIC :: UF_Elem_Truss_Calc
  PUBLIC :: Calc_T3D2

  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for truss element calculation
  
  !> @brief Output structure for truss element calculation
  TYPE, PUBLIC :: PH_Elem_Truss_Calc_Arg
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(ElemFormul) :: formul  ! Formulation parameters (Algo)                   ! [IN]
    TYPE(ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(ElemState) :: state_in  ! Input element state (State)                   ! [IN]
    TYPE(MatProperties) :: mat  ! Material properties (Desc)                   ! [IN]
    TYPE(ElemState) :: state_out  ! Output element state (State)                   ! [OUT]
    TYPE(ElemFlags) :: flags  ! Element flags and status (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_Truss_Calc_Arg


CONTAINS

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Truss_Calc
  ! Purpose: Unified truss element computation interface
  ! Interface: Structured (In/Out types)
  ! Description:
  !   Unified interface for all truss elements (T2D2, T3D2, T3D3).
  !   Dispatches to element-family-specific Calc functions based on ElemType%name.
  ! Theory: K = (EA/L)[1 -1; -1 1], stress: ? = E? = E(u? - u?)/L
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Truss_Calc(arg)
    TYPE(PH_Elem_Truss_Calc_Arg), INTENT(INOUT) :: arg

    CHARACTER(len=:), ALLOCATABLE :: ename
    
    ! Initialize output
    CALL init_error_status(arg%status)
    arg%state_out = arg%state_in
    ! Initialize flags with default values
    arg%flags%failed = .FALSE.
    arg%flags%suggest_cutback = .FALSE.
    arg%flags%requires_reasse = .FALSE.
    arg%flags%stableDt = 0.0_wp
    CALL init_error_status(arg%flags%status)
    arg%flags%stp%nlgeom = 0_i4
    arg%flags%formulation_typ = 0_i4
    
    ! Extract element name and convert to uppercase for matching
    ename = ADJUSTL(arg%elem_type%name)
    CALL to_upper_internal(ename)
    
    ! Dispatch to element-family-specific implementations
    IF (INDEX(ename, 'T2D2') > 0) THEN
      CALL UF_Elem_T2D2_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                             arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
    ELSE IF (INDEX(ename, 'T3D2') > 0) THEN
      CALL UF_Elem_T3D2_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                             arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
    ELSE IF (INDEX(ename, 'T3D3') > 0) THEN
      CALL UF_Elem_T3D3_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                             arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
    ELSE
      ! Fallback: Try to determine from nNode and nDim
      ! Default to T3D2 for backward compatibility
      IF (arg%elem_type%pop%n_nodes == 2 .AND. arg%elem_type%dim == 2) THEN
        CALL UF_Elem_T2D2_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                               arg%mat, arg%state_out, arg%flags)
      ELSE IF (arg%elem_type%pop%n_nodes == 2 .AND. arg%elem_type%dim == 3) THEN
        CALL UF_Elem_T3D2_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                               arg%mat, arg%state_out, arg%flags)
      ELSE IF (arg%elem_type%pop%n_nodes == 3 .AND. arg%elem_type%dim == 3) THEN
        CALL UF_Elem_T3D3_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                               arg%mat, arg%state_out, arg%flags)
      ELSE
        ! Last resort: use T3D2 as default
        CALL UF_Elem_T3D2_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                               arg%mat, arg%state_out, arg%flags)
      END IF
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
    END IF

  END SUBROUTINE PH_Elem_Truss_Calc

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Truss_Calc_Structured
  ! Purpose: Structured interface wrapper (aligned with BC benchmark pattern)
  ! Interface: Structured (In/Out types)
  ! Note: This is an alias for PH_Elem_Truss_Calc, provided for consistency
  !       with BC module naming convention (_Structured suffix)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Truss_Calc_Structured(arg)
    TYPE(PH_Elem_Truss_Calc_Arg), INTENT(INOUT) :: arg
    
    ! Call main interface
    CALL PH_Elem_Truss_Calc(arg)
    
  END SUBROUTINE PH_Elem_Truss_Calc_Structured

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Elem_Truss_Calc
  ! Purpose: Flat interface for RT_Elem_Comp (same signature as Calc_UEL_Intf)
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Elem_Truss_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    TYPE(PH_Elem_Truss_Calc_Arg) :: in
    TYPE(PH_Elem_Truss_Calc_Arg) :: out

    in%elem_type = ElemType
    in%formul = Formul
    in%ctx = Ctx
    in%state_in = state_in
    in%mat = Mat
    CALL PH_Elem_Truss_Calc(arg)
    state_out = out%state_out
    flags = out%flags
  END SUBROUTINE UF_Elem_Truss_Calc

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_T3D2
  ! Purpose: T3D2 thin wrapper (Calc_UEL_Intf), delegates to UF_Elem_Truss_Calc.
  !          UFC UEL/UMAT unified template - task 2007.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_T3D2(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL UF_Elem_Truss_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_T3D2

  !-----------------------------------------------------------------------------
  ! Internal utility: Convert string to uppercase
  !-----------------------------------------------------------------------------
  subroutine to_upper_internal(s)
    character(len=*), intent(inout) :: s
    integer(i4) :: i, ic
    do i = 1, len_trim(s)
      ic = iachar(s(i:i))
      if (ic >= iachar('a') .and. ic <= iachar('z')) then
        s(i:i) = achar(ic - 32)
      end if
    end do
  end subroutine to_upper_internal

END MODULE PH_Elem_Truss_Def