!===============================================================================
! MODULE: PH_Elem_CohesiveDefn
! LAYER:  L4_PH
! DOMAIN: Element/Special
! ROLE:   Def
! BRIEF:  Cohesive interface element L4 unified definition module.
! **W2**：内聚力 **Defn**；与 **`MD_ELEM_BIND_COHESIVE`** / **`PH_Elem_Core`** 双线性/指数等接口一致。
!===============================================================================
MODULE PH_Elem_Cohesive_Def
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  !! ===================================================================
  !! UniField-Core Cohesive Element Definition Module ( ï¿?
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Element/SPECIAL/Cohesive
  !!   KIND: Core (Cohesive element kernels & unified interface)
  !! 
  !! This module provides the main cohesive element interface:
  !!   - UF_Elem_Cohesive_Calc: Unified interface with struct-based parameters
  !!   - Internal dispatch to element-family-specific implementations
  !!
  !! Element types:
  !!   - COH2D4: 4-node 2D cohesive element
  !!   - COH3D6: 6-node 3D cohesive element
  !!   - COH3D8: 8-node 3D cohesive element
  !!
  !! Design Principles:
  !!   -  ï¿? This is the main module for COHESIVE family
  !!   - Unified struct-based interface for L5_RT layer stability
  !!   - Internal dispatch to COH2D4/COH3D6/COH3D8 specific implementations
  !!   - Maintains backward compatibility
  !! ===================================================================

  USE IF_Prec_Core, only: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_INVALID
  USE MD_Base_ObjModel, only: MatProperties
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
      UF_Elem_PrepareStructStorage
  
  ! Element-family-specific modules
  use PH_Elem_COH2D4_Definition, only: UF_Elem_COH2D4_Calc
  use PH_Elem_COH3D6_Definition, only: UF_Elem_COH3D6_Calc
  use PH_Elem_COH3D8_Definition, only: UF_Elem_COH3D8_Calc

  implicit none
  private

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  public :: UF_Elem_Cohesive_Calc
  public :: PH_Elem_Cohesive_Material_Update_Routed

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

  subroutine UF_Elem_Cohesive_Calc(ElemType, Formul, Ctx, state_in, &
                                     Mat, state_out, flags)
    !! Unified interface for all cohesive elements (COH2D4, COH3D6, COH3D8).
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
    if (index(ename, 'COH2D4') > 0) then
      call UF_Elem_COH2D4_Calc(ElemType, Formul, Ctx, state_in, &
                               Mat, state_out, flags)
    else if (index(ename, 'COH3D6') > 0) then
      call UF_Elem_COH3D6_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
    else if (index(ename, 'COH3D8') > 0) then
      call UF_Elem_COH3D8_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
    else
      ! Fallback: Try to determine from nNode and nDim
      if (ElemType%numNodes == 4 .and. ElemType%dim == 2) then
        call UF_Elem_COH2D4_Calc(ElemType, Formul, Ctx, state_in, &
                                 Mat, state_out, flags)
      else if (ElemType%numNodes == 6 .and. ElemType%dim == 3) then
        call UF_Elem_COH3D6_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
      else if (ElemType%numNodes == 8 .and. ElemType%dim == 3) then
        call UF_Elem_COH3D8_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
      else
        call UF_Elem_PrepareStructStorage(ElemType, state_out)
        if (associated(state_out%evo%Ke)) state_out%evo%Ke = 0.0_wp
        if (associated(state_out%Re)) state_out%Re = 0.0_wp
        if (associated(state_out%Me)) state_out%Me = 0.0_wp
        if (associated(state_out%Ce)) state_out%Ce = 0.0_wp
        flags%failed = .true.
        call init_error_status(flags%status, IF_STATUS_INVALID, &
          message='UF_Elem_Cohesive_Calc: unsupported cohesive topology (expected COH2D4/COH3D6/COH3D8 match)')
        state_out%failed = flags%failed
        state_out%stableDt = flags%stableDt
      end if
    end if

  end subroutine UF_Elem_Cohesive_Calc

  SUBROUTINE PH_Elem_Cohesive_Material_Update_Routed(rt_ctx, mat_slot, K_n, K_s, &
                                                     t_n_max, t_s_max, G_Ic, G_IIc, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_CohesiveLinear

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: K_n
    REAL(wp),                  INTENT(OUT)   :: K_s
    REAL(wp),                  INTENT(OUT)   :: t_n_max
    REAL(wp),                  INTENT(OUT)   :: t_s_max
    REAL(wp),                  INTENT(OUT)   :: G_Ic
    REAL(wp),                  INTENT(OUT)   :: G_IIc
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_CohesiveLinear(rt_ctx, mat_slot, K_n, K_s, &
                                         t_n_max, t_s_max, G_Ic, G_IIc, status)
  END SUBROUTINE PH_Elem_Cohesive_Material_Update_Routed
END MODULE PH_Elem_Cohesive_Def

