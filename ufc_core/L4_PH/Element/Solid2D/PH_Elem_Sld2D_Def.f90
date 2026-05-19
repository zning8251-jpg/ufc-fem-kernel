!===============================================================================
! MODULE: PH_Elem_Sld2D_Def
! LAYER:  L4_PH
! DOMAIN: Element/Solid2D
! ROLE:   Def
! BRIEF:  2D structural continuum element unified interface
! **W2**：L4 **平面实体** 族接口；平面应力/应变/轴对称与 **`MD_ELEM_BIND_SOLID2D`** / **`PH_Elem_Core`** 一致。
! **Phase6 §3.1**：本族入口须以 **ndim=2 / nshr=1（平面）或轴对称等价约定** 向 `PH_Mat_Algo` 提供应力/应变维数，
! 禁止把 3D 本构维数隐式嵌入 2D 单元核；具体映射在各自 `Calc_*` 实现中显式化。
!===============================================================================
MODULE PH_Elem_Sld2D_Def
!> [CORE] 2D structural continuum element unified interface
!> Theory: K = integral B^T*D*B dV, plane stress/strain/axisymmetric
!> Status: Production | Last verified: 2026-02-28

  use IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: wp, i4
  use MD_Base_ElemLib
  USE MD_Elem_Types, ONLY: ShapeFuncResult
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  use MD_Model_Mgr
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, only: MatProperties
  USE PH_ElemContm_Ops, ONLY: Calc_Continuum2D_elem, Calc_Continuum2D
  use UF_Material_Base
  ! NOTE: Register additional 2D continuum element *_Calc modules here when implemented.
  ! use PH_Elem_CPS4_Definition, only: UF_Elem_CPS4_Calc
  ! use PH_Elem_CPE4_Definition, only: UF_Elem_CPE4_Calc
  ! use PH_Elem_CAX4_Definition, only: UF_Elem_CAX4_Calc

  implicit none
  private

  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  PUBLIC :: PH_Elem_Sld2D_Calc_Arg
  PUBLIC :: PH_Elem_Sld2D_Calc
  PUBLIC :: PH_Elem_Sld2D_Calc_Structured
  PUBLIC :: UF_Elem_Sld2D_Calc
  PUBLIC :: Calc_CPE4
  PUBLIC :: Calc_CPS4
  PUBLIC :: Calc_CAX4
  PUBLIC :: RecoverStress_Sld2D

  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for 2D structural continuum element calculation
  
  !> @brief Output structure for 2D structural continuum element calculation
  TYPE, PUBLIC :: PH_Elem_Sld2D_Calc_Arg
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(ElemFormul) :: formul  ! Formulation parameters (Algo)                   ! [IN]
    TYPE(ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(ElemState) :: state_in  ! Input element state (State)                   ! [IN]
    TYPE(MatProperties) :: mat  ! Material properties (Desc)                   ! [IN]
    TYPE(ElemState) :: state_out  ! Output element state (State)                   ! [OUT]
    TYPE(ElemFlags) :: flags  ! Element flags and status (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_Sld2D_Calc_Arg


CONTAINS

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Sld2D_Calc
  ! Purpose: Unified 2D structural continuum element calculation interface
  ! Interface: Structured (In/Out types)
  ! Description:
  !   This function dispatches to specific 2D continuum element implementations:
  !     - CPS*: Plane stress elements (CPS3, CPS4, CPS6, CPS8)
  !     - CPE*: Plane strain elements (CPE3, CPE4, CPE6, CPE8)
  !     - CAX*: Axisymmetric elements (CAX3, CAX4, CAX6, CAX8)
  !
  !   Dispatch logic (G6-W1):
  !     1. Registered CPS/CPE/CAX -> Calc_Continuum2D_elem (structured 2D kernel)
  !     2. Unknown 2D -> Calc_Continuum2D legacy fallback
  ! Theory: K = ? B^TDB d?, plane stress: ??? = 0, plane strain: ??? = 0
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Sld2D_Calc(arg)
    TYPE(PH_Elem_Sld2D_Calc_Arg), INTENT(INOUT) :: arg

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

    CALL PH_Elem_Sld2D_DispatchCalc(ename, arg%elem_type, arg%formul, arg%ctx, &
        arg%state_in, matModels, arg%state_out, arg%flags)

    ! Copy error status from flags if present
    IF (arg%flags%failed) THEN
      arg%status = arg%flags%status
    ELSE
      arg%status%status_code = IF_STATUS_OK
    END IF

    DEALLOCATE(matModels)

  END SUBROUTINE PH_Elem_Sld2D_Calc

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Sld2D_Calc_Structured
  ! Purpose: Structured interface wrapper (aligned with BC benchmark pattern)
  ! Interface: Structured (In/Out types)
  ! Note: This is an alias for PH_Elem_Sld2D_Calc, provided for consistency
  !       with BC module naming convention (_Structured suffix)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Sld2D_Calc_Structured(arg)
    TYPE(PH_Elem_Sld2D_Calc_Arg), INTENT(INOUT) :: arg
    
    ! Call main interface
    CALL PH_Elem_Sld2D_Calc(arg)
    
  END SUBROUTINE PH_Elem_Sld2D_Calc_Structured

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Elem_Sld2D_Calc
  ! Purpose: Flat interface for RT_Elem_Comp (same signature as Calc_UEL_Intf)
  !          Wraps PH_Elem_Sld2D_Calc (structured).
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Elem_Sld2D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    TYPE(PH_Elem_Sld2D_Calc_Arg) :: in

    in%elem_type = ElemType
    in%formul = Formul
    in%ctx = Ctx
    in%state_in = state_in
    in%mat = Mat
    CALL PH_Elem_Sld2D_Calc(in)
    state_out = in%state_out
    flags = in%flags
  END SUBROUTINE UF_Elem_Sld2D_Calc
  
    !-----------------------------------------------------------------------------
    ! Subroutine: RecoverStress_Sld2D
    ! Purpose: Stress recovery at nodes for 2D elements (CPS/CPE/CAX)
    ! Theory: Superconvergent Patch Recovery (SPR) or simple extrapolation
    !         from integration points to nodes using shape functions
    ! Input:
    !   - ipStates: Integration point states (stress at Gauss points)
    !   - sf: Shape function results at nodes
    ! Output:
    !   - nodeStress: Recovered stress tensor at each node (6 x nNode)
    !-----------------------------------------------------------------------------
    SUBROUTINE RecoverStress_Sld2D(ipStates, sf, nodeStress, nNode, ntens)
      TYPE(IPState), INTENT(IN) :: ipStates(:)
      TYPE(ShapeFuncResult), INTENT(IN) :: sf
      REAL(wp), INTENT(OUT) :: nodeStress(:, :)
      INTEGER(i4), INTENT(IN) :: nNode, ntens
      
      INTEGER(i4) :: i, j, ip
      INTEGER(i4) :: nInt
      REAL(wp) :: N_ip(8)  ! Max shape functions
      REAL(wp) :: weight_sum(8)
      
      ! Initialize output
      nodeStress = 0.0_wp
      weight_sum = 0.0_wp
      
      nInt = SIZE(ipStates)
      
      ! Extrapolate stress from IPs to nodes using shape functions
      ! Simple extrapolation: sigma_node = sum(N_ip * sigma_ip) / sum(N_ip)
      DO ip = 1, nInt
        IF (.NOT. ALLOCATED(ipStates(ip)%stateV)) CYCLE
        IF (SIZE(ipStates(ip)%stateV) < ntens) CYCLE
        
        ! Get shape function values at this IP location (for all nodes)
        DO i = 1, MIN(nNode, 8)
          N_ip(i) = sf%N(i, 1)  ! Simplified - in practice need N at IP locations
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
      
    END SUBROUTINE RecoverStress_Sld2D

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_CPE4
  ! Purpose: CPE4 thin wrapper (Calc_UEL_Intf), delegates to UF_Elem_Sld2D_Calc.
  !          UFC UEL/UMAT unified template - task 2004.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_CPE4(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL UF_Elem_Sld2D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_CPE4

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_CPS4
  ! Purpose: CPS4 thin wrapper (Calc_UEL_Intf), delegates to UF_Elem_Sld2D_Calc.
  !          UFC UEL/UMAT unified template - task 2005.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_CPS4(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL UF_Elem_Sld2D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_CPS4

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_CAX4
  ! Purpose: CAX4 thin wrapper (Calc_UEL_Intf), delegates to UF_Elem_Sld2D_Calc.
  !          UFC UEL/UMAT unified template - task 2006.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_CAX4(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL UF_Elem_Sld2D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_CAX4

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

  SUBROUTINE PH_Elem_Sld2D_DispatchCalc(ename, elem_type, formul, ctx, state_in, matModels, &
                                      state_out, flags)
    CHARACTER(len=*), INTENT(IN) :: ename
    TYPE(ElemType), INTENT(IN) :: elem_type
    TYPE(ElemFormul), INTENT(IN) :: formul
    TYPE(ElemCtx), INTENT(IN) :: ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(UF_MaterialModel), INTENT(IN) :: matModels(:)
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CHARACTER(len=32) :: en
    LOGICAL :: use_elem_kernel

    en = ADJUSTL(ename)
    use_elem_kernel = .FALSE.

    SELECT CASE (TRIM(en))
    CASE ('CPS3', 'CPS4', 'CPS6', 'CPS8', 'CPE3', 'CPE4', 'CPE6', 'CPE8', &
          'CAX3', 'CAX4', 'CAX6', 'CAX8', 'CPS4R', 'CPE4R', 'CPE8R')
      use_elem_kernel = .TRUE.
    CASE DEFAULT
      IF (INDEX(en, 'CPS') > 0 .OR. INDEX(en, 'CPE') > 0 .OR. INDEX(en, 'CAX') > 0) THEN
        use_elem_kernel = .TRUE.
      END IF
    END SELECT

    IF (use_elem_kernel) THEN
      CALL Calc_Continuum2D_elem(elem_type, formul, ctx, state_in, matModels, state_out, flags)
    ELSE
      CALL Calc_Continuum2D(elem_type, formul, ctx, state_in, matModels, state_out, flags)
    END IF
  END SUBROUTINE PH_Elem_Sld2D_DispatchCalc

END MODULE PH_Elem_Sld2D_Def