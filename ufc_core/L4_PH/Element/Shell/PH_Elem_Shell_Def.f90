!===============================================================================
! MODULE: PH_Elem_Shell_Def
! LAYER:  L4_PH
! DOMAIN: Element/Shell
! ROLE:   Def
! BRIEF:  Shell element unified interface
! **W2**：L4 **壳** 族统一接口；**MITC/厚度** 等与 **`PH_Elem_Core`**、**`MD_ELEM_BIND_SHELL`** 对齐。
!===============================================================================
MODULE PH_Elem_Shell_Def
!> [CORE] Shell element unified interface
!> Theory: K = K_m + K_b + K_s, Reissner-Mindlin, MITC
!> Status: Production | Last verified: 2026-02-28

  use IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: wp, i4
  use MD_Base_ElemLib
  USE MD_Elem_Types, ONLY: ShapeFuncResult
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  use MD_Model_Mgr
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                          UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib, only: MatProperties
  use PH_Elem_S3, only: UF_Elem_S3_Calc
  use PH_Elem_S4, only: UF_Elem_S4_Calc
  use PH_Elem_S6, only: UF_Elem_S6_Calc
  use PH_Elem_S8, only: UF_Elem_S8_Calc
  use PH_Elem_S9, only: UF_Elem_S9_Calc
  use PH_Elem_S4T, only: UF_Elem_S4T_Calc
  use PH_Elem_S8RT, only: UF_Elem_S8RT_Calc
  use PH_Elem_ShellMITC, only: UF_Elem_Shell_MITC4_Calc
  use UF_Element_Base, only: UF_ElemType
  use UF_Material_Base
  ! NOTE: Register additional shell element modules here when implemented.
  ! use PH_ElemDS3_Algo, only: UF_Elem_DS3_Calc  (thermal shell)
  ! use PH_ElemDS4_Algo, only: UF_Elem_DS4_Calc  (thermal shell)
  ! use PH_ElemDS6_Algo, only: UF_Elem_DS6_Calc  (thermal shell)
  ! use PH_ElemDS8_Algo, only: UF_Elem_DS8_Calc  (thermal shell)

  implicit none
  private

  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  PUBLIC :: PH_Elem_Shell_Calc_Arg
  PUBLIC :: PH_Elem_Shell_Calc
  PUBLIC :: PH_Elem_Shell_Calc_Structured
  PUBLIC :: UF_Elem_Shell_Calc
  PUBLIC :: UF_Elem_S4T_Calc
  PUBLIC :: UF_Elem_S8RT_Calc
  PUBLIC :: Calc_S4
  PUBLIC :: Calc_S4R
  PUBLIC :: RecoverStress_Shell

  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for shell element calculation
  
  !> @brief Output structure for shell element calculation
  TYPE, PUBLIC :: PH_Elem_Shell_Calc_Arg
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(ElemFormul) :: formul  ! Formulation parameters (Algo)                   ! [IN]
    TYPE(ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(ElemState) :: state_in  ! Input element state (State)                   ! [IN]
    TYPE(MatProperties) :: mat  ! Material properties (Desc)                   ! [IN]
    TYPE(ElemState) :: state_out  ! Output element state (State)                   ! [OUT]
    TYPE(ElemFlags) :: flags  ! Element flags and status (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_Shell_Calc_Arg


CONTAINS

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Shell_Calc
  ! Purpose: Unified shell element calculation interface
  ! Interface: Structured (In/Out types)
  ! Description:
  !   This function dispatches to specific shell element implementations:
  !     - S3: 3-node triangle shell element
  !     - S4: 4-node quadrilateral shell element (supports full/reduced integration)
  !     - S4R/S4RS: Uses S4 with reduced integration
  !     - S6: 6-node triangle shell element
  !     - S8: 8-node quadrilateral shell element
  !     - S8R: Uses S8
  !     - S9: 9-node quadrilateral shell element
  !     - MITC4: Mixed interpolation shell element (4-node)
  !
  !   Dispatch logic:
  !     1. Check ElemType%name for explicit match ('S3', 'S4', 'S6', 'S8', 'S9', 'MITC4')
  !     2. Fallback: Use numNodes to determine type
  ! Theory: K = K_m + K_b + K_s, Reissner-Mindlin theory, MITC for shear locking
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Shell_Calc(arg)
    TYPE(PH_Elem_Shell_Calc_Arg), INTENT(INOUT) :: arg

    CHARACTER(len=32) :: ename
    INTEGER(i4) :: nNode

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

    ! Get number of nodes (ElemType uses nNodes)
    nNode = arg%elem_type%pop%n_nodes

    ! Dispatch based on element name
    ! Check MITC4 first (more specific)
    IF (INDEX(ename, 'MITC4') > 0 .OR. INDEX(ename, 'S4R-MITC') > 0) THEN
      CALL UF_Elem_Shell_MITC4_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                                     arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! Check S3 (must exclude S3R and S3RS)
    IF (INDEX(ename, 'S3') > 0 .AND. INDEX(ename, 'S3R') == 0 .AND. INDEX(ename, 'S3RS') == 0) THEN
      CALL UF_Elem_S3_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! S4T before S4* (ename 'S4T' matches INDEX(...,'S4'))
    IF (INDEX(ename, 'S4T') > 0) THEN
      CALL UF_Elem_S4T_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
           arg%mat, arg%state_out, arg%flags)
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! Check S4R/S4RS (reduced integration variants)
    IF (INDEX(ename, 'S4R') > 0 .OR. INDEX(ename, 'S4RS') > 0) THEN
      ! S4R/S4RS uses S4 with reduced integration
      CALL UF_Elem_S4_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! Check S4 (must exclude S4R and S4RS)
    IF (INDEX(ename, 'S4') > 0) THEN
      CALL UF_Elem_S4_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! Check S6
    IF (INDEX(ename, 'S6') > 0) THEN
      CALL UF_Elem_S6_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! S8RT before S8R (ename 'S8RT' matches INDEX(...,'S8R'))
    IF (INDEX(ename, 'S8RT') > 0) THEN
      CALL UF_Elem_S8RT_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
           arg%mat, arg%state_out, arg%flags)
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! Check S8R (reduced integration variant)
    IF (INDEX(ename, 'S8R') > 0) THEN
      ! S8R uses S8
      CALL UF_Elem_S8_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! Check S8
    IF (INDEX(ename, 'S8') > 0) THEN
      CALL UF_Elem_S8_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! Check S9
    IF (INDEX(ename, 'S9') > 0) THEN
      CALL UF_Elem_S9_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! Fallback dispatch based on numNodes
    IF (nNode == 3) THEN
      ! 3 nodes -> S3
      CALL UF_Elem_S3_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
    ELSE IF (nNode == 4) THEN
      ! 4 nodes -> S4 (default)
      CALL UF_Elem_S4_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
    ELSE IF (nNode == 6) THEN
      ! 6 nodes -> S6
      CALL UF_Elem_S6_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
    ELSE IF (nNode == 8) THEN
      ! 8 nodes -> S8
      CALL UF_Elem_S8_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
    ELSE IF (nNode == 9) THEN
      ! 9 nodes -> S9
      CALL UF_Elem_S9_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                           arg%mat, arg%state_out, arg%flags)
    ELSE
      ! Unknown shell topology �?explicit failure (no silent zero stiffness)
      CALL UF_Elem_PrepareStructStorage(arg%elem_type, arg%state_out)
      IF (ASSOCIATED(arg%state_arg%evo%Ke)) arg%state_arg%evo%Ke = 0.0_wp
      IF (ASSOCIATED(arg%state_arg%Re)) arg%state_arg%Re = 0.0_wp
      IF (ASSOCIATED(arg%state_arg%Me)) arg%state_arg%Me = 0.0_wp
      IF (ASSOCIATED(arg%state_arg%Ce)) arg%state_arg%Ce = 0.0_wp
      arg%flags%failed = .TRUE.
      arg%flags%suggest_cutback = .FALSE.
      arg%flags%requires_reasse = .TRUE.
      arg%flags%stableDt = 0.0_wp
      CALL init_error_status(arg%flags%status, IF_STATUS_INVALID, &
        message='PH_Elem_Shell_Calc: unsupported shell node count / name (expected S3/S4/S6/S8/S9 family)')
      arg%state_arg%failed = arg%flags%failed
      arg%state_arg%stableDt = arg%flags%stableDt
      arg%status = arg%flags%status
    END IF

    ! Copy error status from flags if not already set
    IF (.NOT. arg%flags%failed .AND. arg%status%status_code == IF_STATUS_OK) THEN
      ! Status already OK
    ELSE IF (arg%flags%failed) THEN
      arg%status = arg%flags%status
    END IF

  END SUBROUTINE PH_Elem_Shell_Calc

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Shell_Calc_Structured
  ! Purpose: Structured interface wrapper (aligned with BC benchmark pattern)
  ! Interface: Structured (In/Out types)
  ! Note: This is an alias for PH_Elem_Shell_Calc, provided for consistency
  !       with BC module naming convention (_Structured suffix)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Shell_Calc_Structured(arg)
    TYPE(PH_Elem_Shell_Calc_Arg), INTENT(INOUT) :: arg
    
    ! Call main interface
    CALL PH_Elem_Shell_Calc(arg)
    
  END SUBROUTINE PH_Elem_Shell_Calc_Structured

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Elem_Shell_Calc
  ! Purpose: Flat interface for RT_Elem_Comp (same signature as Calc_UEL_Intf)
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Elem_Shell_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    TYPE(PH_Elem_Shell_Calc_Arg) :: in
    TYPE(PH_Elem_Shell_Calc_Arg) :: out

    in%elem_type = ElemType
    in%formul = Formul
    in%ctx = Ctx
    in%state_in = state_in
    in%mat = Mat
    CALL PH_Elem_Shell_Calc(arg)
    state_out = out%state_out
    flags = out%flags
  END SUBROUTINE UF_Elem_Shell_Calc

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_S4
  ! Purpose: S4 thin wrapper (Calc_UEL_Intf), delegates to UF_Elem_Shell_Calc.
  !          UFC UEL/UMAT unified template - task 2008.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_S4(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL UF_Elem_Shell_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_S4

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_S4R
  ! Purpose: S4R thin wrapper (Calc_UEL_Intf), delegates to UF_Elem_Shell_Calc.
  !          UFC UEL/UMAT unified template - task 2009.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_S4R(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL UF_Elem_Shell_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_S4R

  !-----------------------------------------------------------------------------
  ! Subroutine: RecoverStress_Shell
  ! Purpose: Stress recovery at nodes for shell elements (S3/S4/S6/S8/S9)
  ! Theory: Superconvergent Patch Recovery (SPR) with membrane+bending separation
  !         sigma_node = sigma_membrane + z * kappa_bending
  ! Input:
  !   - ipStates: Integration point states (stress resultants at Gauss points)
  !   - sf: Shape function results at nodes
  !   - z_coords: Through-thickness coordinates for layer stresses
  ! Output:
  !   - nodeStress: Recovered stress tensor at each node (6 x nNode)
  !-----------------------------------------------------------------------------
  SUBROUTINE RecoverStress_Shell(ipStates, sf, nodeStress, nNode, ntens, z_coords)
    TYPE(IPState), INTENT(IN) :: ipStates(:)
    TYPE(ShapeFuncResult), INTENT(IN) :: sf
    REAL(wp), INTENT(OUT) :: nodeStress(:, :)
    INTEGER(i4), INTENT(IN) :: nNode, ntens
    REAL(wp), INTENT(IN), OPTIONAL :: z_coords(:)
    
    INTEGER(i4) :: i, j, ip, layer
    INTEGER(i4) :: nInt, nLayers
    REAL(wp) :: N_ip(9)  ! Max shape functions for S9
    REAL(wp) :: weight_sum(9)
    REAL(wp) :: z
    
    ! Initialize output
    nodeStress = 0.0_wp
    weight_sum = 0.0_wp
    
    nInt = SIZE(ipStates)
    nLayers = 1
    IF (PRESENT(z_coords)) nLayers = SIZE(z_coords)
    
    ! Extrapolate stress resultants from IPs to nodes
    DO ip = 1, nInt
      IF (.NOT. ALLOCATED(ipStates(ip)%stateV)) CYCLE
      IF (SIZE(ipStates(ip)%stateV) < ntens) CYCLE
      
      ! Get shape function values
      DO i = 1, MIN(nNode, 9)
        N_ip(i) = sf%N(i, 1)
      END DO
      
      ! Accumulate weighted stress resultants
      DO i = 1, nNode
        DO j = 1, ntens
          nodeStress(j, i) = nodeStress(j, i) + N_ip(i) * ipStates(ip)%stateV(j)
        END DO
        weight_sum(i) = weight_sum(i) + ABS(N_ip(i))
      END DO
    END DO
    
    ! Normalize
    DO i = 1, nNode
      IF (weight_sum(i) > 1.0e-10_wp) THEN
        nodeStress(:, i) = nodeStress(:, i) / weight_sum(i)
      END IF
    END DO
    
    ! If multiple layers, compute layer-specific stresses
    IF (nLayers > 1 .AND. PRESENT(z_coords)) THEN
      DO layer = 1, nLayers
        z = z_coords(layer)
        ! Add bending contribution: sigma_bending = z * kappa
        ! This is simplified - full implementation needs curvature extraction
      END DO
    END IF
    
  END SUBROUTINE RecoverStress_Shell

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

END MODULE PH_Elem_Shell_Def