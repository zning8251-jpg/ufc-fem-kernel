!===============================================================================
! MODULE: PH_Elem_RigidDefn
! LAYER:  L4_PH
! DOMAIN: Element/Special
! ROLE:   Def
! BRIEF:  Elem Rigid Defn module (auto-filled)
!===============================================================================
MODULE PH_Elem_Rigid_Def
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  !! ===================================================================
  !! UniField-Core Rigid Element Definition Module ( ï¿?
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Element/SPECIAL/Rigid
  !!   KIND: Core (Rigid element kernels & unified interface)
  !! 
  !! This module provides the main rigid element interface:
  !!   - UF_Elem_Rigid_Calc: Unified interface with struct-based parameters
  !!   - Internal dispatch to element-family-specific implementations
  !!
  !! Element types:
  !!   - R2D2: 2-node 2D rigid element
  !!   - R3D3: 3-node 3D rigid element
  !!   - R3D4: 4-node 3D rigid element
  !!
  !! Design Principles:
  !!   -  ï¿? This is the main module for RIGID family
  !!   - Unified struct-based interface for L5_RT layer stability
  !!   - Internal dispatch to R2D2/R3D3/R3D4 specific implementations
  !!   - Maintains backward compatibility
  !! ===================================================================

  USE IF_Prec_Core, only: wp, i4
  USE IF_Err_Brg, ONLY: init_error_status, IF_STATUS_INVALID
  USE MD_Base_ObjModel, only: MatProperties
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
      UF_Elem_PrepareStructStorage
  
  ! Element-family-specific modules
  use PH_Elem_R2D2_Definition, only: UF_Elem_R2D2_Calc
  use PH_Elem_R3D3_Definition, only: UF_Elem_R3D3_Calc
  use PH_Elem_R3D4_Definition, only: UF_Elem_R3D4_Calc

  implicit none
  private

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  public :: UF_Elem_Rigid_Calc

contains

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

  subroutine UF_Elem_Rigid_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
    !! Unified interface for all rigid elements (R2D2, R3D3, R3D4).
    !! Dispatches to element-family-specific Calc functions based on ElemType%name.
    
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(MatProperties),          intent(inout) :: Mat
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(inout) :: flags

    character(len=:), allocatable :: ename
    
    ! Extract element name and convert to uppercase for matching
    ename = adjustl(ElemType%name)
    call to_upper_internal(ename)
    
    ! Dispatch to element-family-specific implementations
    if (index(ename, 'R2D2') > 0) then
      call UF_Elem_R2D2_Calc(ElemType, Formul, Ctx, state_in, &
                             Mat, state_out, flags)
    else if (index(ename, 'R3D3') > 0) then
      call UF_Elem_R3D3_Calc(ElemType, Formul, Ctx, state_in, &
                             Mat, state_out, flags)
    else if (index(ename, 'R3D4') > 0) then
      call UF_Elem_R3D4_Calc(ElemType, Formul, Ctx, state_in, &
                             Mat, state_out, flags)
    else
      ! Fallback: Try to determine from nNode and nDim
      if (ElemType%numNodes == 2 .and. ElemType%dim == 2) then
        call UF_Elem_R2D2_Calc(ElemType, Formul, Ctx, state_in, &
                               Mat, state_out, flags)
      else if (ElemType%numNodes == 3 .and. ElemType%dim == 3) then
        call UF_Elem_R3D3_Calc(ElemType, Formul, Ctx, state_in, &
                               Mat, state_out, flags)
      else if (ElemType%numNodes == 4 .and. ElemType%dim == 3) then
        call UF_Elem_R3D4_Calc(ElemType, Formul, Ctx, state_in, &
                               Mat, state_out, flags)
      else
        call UF_Elem_PrepareStructStorage(ElemType, state_out)
        if (associated(state_out%evo%Ke)) state_out%evo%Ke = 0.0_wp
        if (associated(state_out%Re)) state_out%Re = 0.0_wp
        if (associated(state_out%Me)) state_out%Me = 0.0_wp
        if (associated(state_out%Ce)) state_out%Ce = 0.0_wp
        flags%failed = .true.
        call init_error_status(flags%status, IF_STATUS_INVALID, &
          message='UF_Elem_Rigid_Calc: unsupported rigid topology (expected R2D2/R3D3/R3D4 match)')
        state_out%failed = flags%failed
        state_out%stableDt = flags%stableDt
      end if
    end if

  end subroutine UF_Elem_Rigid_Calc
END MODULE PH_Elem_Rigid_Def