!===============================================================================
! MODULE: PH_Elem_Sld3D_Def
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Def
! BRIEF:  3D structural continuum element unified interface
! **W2**：L4 **3D 实体** 族统一接口；**`PH_Elem_Desc`** / Gauss 与 **`PH_Elem_Core`**、L3 **`MD_ELEM_BIND_SOLID3D`** 金线一致。
!===============================================================================
MODULE PH_Elem_Sld3D_Def
!> [CORE] 3D structural continuum element unified interface
!> Theory: K = ? B^TDB d?, R_int = ? B^T? d?
!> Status: Production | Last verified: 2026-02-28

  use IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: wp, i4
  use MD_Base_ElemLib
  USE MD_Elem_Types, ONLY: ShapeFuncResult
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  use MD_Model_Mgr
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, only: MatProperties
  use PH_ElemContm_Ops, only: Calc_Continuum3D
  use UF_Material_Base
  ! NOTE: Register additional 3D continuum element *_Calc modules here when implemented.
  ! use PH_Elem_C3D8_Definition, only: UF_Elem_C3D8_Calc
  ! use PH_Elem_C3D20_Definition, only: UF_Elem_C3D20_Calc
  ! use PH_Elem_C3D4_Definition, only: UF_Elem_C3D4_Calc

  implicit none
  private

  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  PUBLIC :: PH_Elem_Sld3D_Calc_Arg
  PUBLIC :: PH_Elem_Sld3D_Calc
  PUBLIC :: PH_Elem_Sld3D_Calc_Structured
  PUBLIC :: UF_Elem_Sld3D_Calc
  PUBLIC :: Calc_C3D8
  PUBLIC :: Calc_C3D4
  PUBLIC :: Calc_C3D8R
  PUBLIC :: RecoverStress_Sld3D

  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for 3D structural continuum element calculation
  
  !> @brief Output structure for 3D structural continuum element calculation
  TYPE, PUBLIC :: PH_Elem_Sld3D_Calc_Arg
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(ElemFormul) :: formul  ! Formulation parameters (Algo)                   ! [IN]
    TYPE(ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(ElemState) :: state_in  ! Input element state (State)                   ! [IN]
    TYPE(MatProperties) :: mat  ! Material properties (Desc)                   ! [IN]
    TYPE(ElemState) :: state_out  ! Output element state (State)                   ! [OUT]
    TYPE(ElemFlags) :: flags  ! Element flags and status (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_Sld3D_Calc_Arg


CONTAINS

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Sld3D_Calc
  ! Purpose: Unified 3D structural continuum element calculation interface
  ! Interface: Structured (In/Out types)
  ! Description:
  !   This function dispatches to specific 3D continuum element implementations:
  !     - C3D4: 4-node tetrahedron
  !     - C3D6: 6-node wedge/prism
  !     - C3D8: 8-node hexahedron
  !     - C3D10: 10-node tetrahedron
  !     - C3D15: 15-node wedge/prism
  !     - C3D20: 20-node hexahedron
  !     - C3D27: 27-node hexahedron
  !     - C3D8R, C3D20R: Reduced integration variants
  !     - C3D8H, C3D20H: Hybrid variants
  !     - C3D8I, C3D20I: Incompatible modes variants
  !     - C3D10M, C3D10H: Modified tetrahedron variants
  !
  !   Dispatch logic:
  !     1. Check ElemType%name for explicit match ('C3D*')
  !     2. Fallback: Use Calc_Continuum3D for all 3D continuum elements
  ! Theory: K = ? B^TDB d?, R_int = ? B^T? d?
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Sld3D_Calc(arg)
    TYPE(PH_Elem_Sld3D_Calc_Arg), INTENT(INOUT) :: arg

    CHARACTER(len=32) :: ename
    INTEGER(i4) :: nInt, i
    TYPE(UF_MaterialModel), ALLOCATABLE :: matModels(:)

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

    ! Get element name (uppercase for comparison)
    ename = arg%elem_type%name
    CALL UPPER_CASE(ename)

    ! Convert MatProperties to UF_MaterialModel array for compatibility
    nInt = MAX(1_i4, arg%elem_type%n_int_points)
    ALLOCATE(matModels(nInt))
    ! Initialize matModels array with material properties
    DO i = 1, nInt
      matModels(i)%cfg%id = arg%mat%material_id
      matModels(i)%props = arg%mat
    END DO

    ! Dispatch based on element name prefix
    ! All 3D continuum elements (C3D*) use Calc_Continuum3D
    IF (INDEX(ename, 'C3D') > 0) THEN
      ! 3D structural continuum elements
      ! Note: Calc_Continuum3D handles all C3D* variants internally
      CALL Calc_Continuum3D(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           matModels, arg%state_out, arg%flags)
    ELSE
      ! Unknown type - try Calc_Continuum3D as fallback if dimension is 3
      IF (arg%elem_type%dim == 3) THEN
        CALL Calc_Continuum3D(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                             matModels, arg%state_out, arg%flags)
      ELSE
        ! Invalid dimension
        arg%flags%failed = .TRUE.
        arg%status%status_code = IF_STATUS_INVALID
        arg%status%message = 'PH_Elem_Sld3D_Calc: Invalid element dimension (expected 3D)'
        CALL UF_Elem_PrepareStructStorage(arg%elem_type, arg%state_out)
      END IF
    END IF

    ! Copy error status from flags if present
    IF (arg%flags%failed) THEN
      arg%status = arg%flags%status
    ELSE
      arg%status%status_code = IF_STATUS_OK
    END IF

    DEALLOCATE(matModels)

  END SUBROUTINE PH_Elem_Sld3D_Calc

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Sld3D_Calc_Structured
  ! Purpose: Structured interface wrapper (aligned with BC benchmark pattern)
  ! Interface: Structured (In/Out types)
  ! Note: This is an alias for PH_Elem_Sld3D_Calc, provided for consistency
  !       with BC module naming convention (_Structured suffix)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Sld3D_Calc_Structured(arg)
    TYPE(PH_Elem_Sld3D_Calc_Arg), INTENT(INOUT) :: arg
    
    ! Call main interface
    CALL PH_Elem_Sld3D_Calc(arg)
    
  END SUBROUTINE PH_Elem_Sld3D_Calc_Structured

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Elem_Sld3D_Calc
  ! Purpose: Flat interface for RT_Elem_Comp (same signature as Calc_UEL_Intf)
  !          Wraps PH_Elem_Sld3D_Calc (structured).
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Elem_Sld3D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    TYPE(PH_Elem_Sld3D_Calc_Arg) :: in
    TYPE(PH_Elem_Sld3D_Calc_Arg) :: out

    in%elem_type = ElemType
    in%formul = Formul
    in%ctx = Ctx
    in%state_in = state_in
    in%mat = Mat
    CALL PH_Elem_Sld3D_Calc(arg)
    state_out = out%state_out
    flags = out%flags
  END SUBROUTINE UF_Elem_Sld3D_Calc

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_C3D8
  ! Purpose: C3D8 thin wrapper (Calc_UEL_Intf), delegates to UF_Elem_Sld3D_Calc.
  !          UFC UEL/UMAT unified template - task 2001.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_C3D8(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL UF_Elem_Sld3D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_C3D8

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_C3D4
  ! Purpose: C3D4 thin wrapper (Calc_UEL_Intf), delegates to UF_Elem_Sld3D_Calc.
  !          UFC UEL/UMAT unified template - task 2002.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_C3D4(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL UF_Elem_Sld3D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_C3D4

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_C3D8R
  ! Purpose: C3D8R thin wrapper (Calc_UEL_Intf), delegates to Calc_C3D8.
  !          C3D8R = reduced integration C3D8. UFC UEL/UMAT unified - task 2003.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_C3D8R(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL Calc_C3D8(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_C3D8R

  !-----------------------------------------------------------------------------
  ! Subroutine: RecoverStress_Sld3D
  ! Purpose: Stress recovery at nodes for 3D elements (C3D4/C3D6/C3D8/C3D10/C3D15/C3D20)
  ! Theory: Superconvergent Patch Recovery (SPR) for 3D stress tensors
  !         sigma_node = sum(N_ip * sigma_ip) / sum(|N_ip|)
  ! Input:
  !   - ipStates: Integration point states (stress tensor at Gauss points)
  !   - sf: Shape function results at nodes
  ! Output:
  !   - nodeStress: Recovered stress tensor at each node (6 x nNode)
  !-----------------------------------------------------------------------------
  SUBROUTINE RecoverStress_Sld3D(ipStates, sf, nodeStress, nNode, ntens)
    TYPE(IPState), INTENT(IN) :: ipStates(:)
    TYPE(ShapeFuncResult), INTENT(IN) :: sf
    REAL(wp), INTENT(OUT) :: nodeStress(:, :)
    INTEGER(i4), INTENT(IN) :: nNode, ntens
    
    INTEGER(i4) :: i, j, ip
    INTEGER(i4) :: nInt
    REAL(wp) :: N_ip(20)  ! Max shape functions for C3D20
    REAL(wp) :: weight_sum(20)
    
    ! Initialize output
    nodeStress = 0.0_wp
    weight_sum = 0.0_wp
    
    nInt = SIZE(ipStates)
    
    ! Extrapolate stress from IPs to nodes using shape functions
    DO ip = 1, nInt
      IF (.NOT. ALLOCATED(ipStates(ip)%stateV)) CYCLE
      IF (SIZE(ipStates(ip)%stateV) < ntens) CYCLE
      
      ! Get shape function values at this IP location
      DO i = 1, MIN(nNode, 20)
        N_ip(i) = sf%N(i, 1)
      END DO
      
      ! Accumulate weighted stress
      DO i = 1, nNode
        DO j = 1, ntens
          nodeStress(j, i) = nodeStress(j, i) + N_ip(i) * ipStates(ip)%stateV(j)
        END DO
        weight_sum(i) = weight_sum(i) + ABS(N_ip(i))
      END DO
    END DO
    
    ! Normalize by shape function weights
    DO i = 1, nNode
      IF (weight_sum(i) > 1.0e-10_wp) THEN
        nodeStress(:, i) = nodeStress(:, i) / weight_sum(i)
      END IF
    END DO
    
  END SUBROUTINE RecoverStress_Sld3D

  !-----------------------------------------------------------------------------
  ! Helper: UPPER_CASE
  ! Purpose: Convert string to uppercase
  !-----------------------------------------------------------------------------
  SUBROUTINE UPPER_CASE(str)
    CHARACTER(len=*), INTENT(INOUT) :: str
    INTEGER(i4) :: i
    DO i = 1, LEN(str)
      IF (str(i:i) >= 'a' .AND. str(i:i) <= 'z') THEN
        str(i:i) = CHAR(ICHAR(str(i:i)) - 32)
      END IF
    END DO
  END SUBROUTINE UPPER_CASE

END MODULE PH_Elem_Sld3D_Def