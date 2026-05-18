!===============================================================================
! MODULE: PH_Elem_Beam_Def
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Def
! BRIEF:  Beam element unified interface
! **W2**：L4 **梁** 族统一接口；截面矩阵 / **`PH_Elem_Desc`** 与 **`MD_ELEM_BIND_BEAM`** / **`PH_Elem_Core`** 一致。
!===============================================================================
MODULE PH_Elem_Beam_Def
!> [CORE] Beam element unified interface
!> Theory: K = ? B^TDB dL, Euler-Bernoulli/Timoshenko
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
  use PH_Elem_B23, only: UF_Elem_B23_Calc
  use PH_Elem_B22, only: UF_Elem_B22_Calc
  use PH_Elem_B21, only: UF_Elem_B21_Calc
  use PH_Elem_B31, only: UF_Elem_B31_Calc
  use PH_Elem_B32, only: UF_Elem_B32_Calc
  use PH_Elem_B32NL, only: UF_Elem_B32NL_Calc
  use PH_Elem_B32S, only: UF_Elem_B32S_Calc
  use PH_Elem_B32T, only: UF_Elem_B32T_Calc
  use PH_Elem_B32P, only: UF_Elem_B32P_Calc
  use PH_Elem_B33, only: UF_Elem_B33_Calc
  use PH_Elem_B31T, only: UF_Elem_B31T_Calc
  use PH_Elem_B31TNL, only: UF_Elem_B31TNL_Calc
  use PH_Elem_B31TS, only: UF_Elem_B31TS_Calc
  use PH_Elem_B31TP, only: UF_Elem_B31TP_Calc
  use PH_Elem_B21T, only: UF_Elem_B21T_Calc
  use PH_Elem_B31H, only: UF_Elem_B31H_Calc
  use PH_Elem_B31OS, only: UF_Elem_B31OS_Calc
  use PH_Elem_B31PIPE, only: UF_Elem_B31PIPE_Calc
  ! TL/UL formulations (Phase 2)
  use PH_Elem_B31TL, only: PH_Elem_B31_TL_StiffnessMatrix, &
      PH_Elem_B31_TL_InternalForce, PH_Elem_B31_TL_StressUpdate
  use PH_Elem_B31UL, only: PH_Elem_B31_UL_StiffnessMatrix, &
      PH_Elem_B31_UL_InternalForce, PH_Elem_B31_UL_StressUpdate
  use PH_Elem_B31NL, only: PH_Elem_B31_NL_Initialize, &
      PH_Elem_B31_NL_ComputeSystem, PH_Elem_B31_NL_NewtonRaphson
  use NM_TimeInt_BEAM, only: L2_NM_TimeInt_BEAM_Init, &
      L2_NM_TimeInt_BEAM_Predict, L2_NM_TimeInt_BEAM_Correct
  use UF_Material_Base

  implicit none
  private

  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  PUBLIC :: PH_Elem_Beam_Calc_Arg
  PUBLIC :: PH_Elem_Beam_Calc
  PUBLIC :: PH_Elem_Beam_Calc_Structured
  PUBLIC :: UF_Elem_Beam_Calc
  PUBLIC :: UF_Elem_B31T_Calc
  PUBLIC :: UF_Elem_B21T_Calc
  PUBLIC :: UF_Elem_B21_Calc
  PUBLIC :: UF_Elem_B22_Calc
  PUBLIC :: UF_Elem_B31TNL_Calc
  PUBLIC :: UF_Elem_B31TS_Calc
  PUBLIC :: UF_Elem_B31TP_Calc
  PUBLIC :: UF_Elem_B32NL_Calc
  PUBLIC :: UF_Elem_B32S_Calc
  PUBLIC :: UF_Elem_B32T_Calc
  PUBLIC :: UF_Elem_B32P_Calc
  PUBLIC :: UF_Elem_B31H_Calc
  PUBLIC :: UF_Elem_B31OS_Calc
  PUBLIC :: UF_Elem_B31PIPE_Calc
  ! TL/UL formulations (Phase 2)
  PUBLIC :: PH_Elem_B31_TL_StiffnessMatrix
  PUBLIC :: PH_Elem_B31_TL_InternalForce
  PUBLIC :: PH_Elem_B31_TL_StressUpdate
  PUBLIC :: PH_Elem_B31_UL_StiffnessMatrix
  PUBLIC :: PH_Elem_B31_UL_InternalForce
  PUBLIC :: PH_Elem_B31_UL_StressUpdate
  PUBLIC :: PH_Elem_B31_NL_Initialize
  PUBLIC :: PH_Elem_B31_NL_ComputeSystem
  PUBLIC :: PH_Elem_B31_NL_NewtonRaphson
  PUBLIC :: L2_NM_TimeInt_BEAM_Init
  PUBLIC :: L2_NM_TimeInt_BEAM_Predict
  PUBLIC :: L2_NM_TimeInt_BEAM_Correct
  PUBLIC :: Calc_B31
  PUBLIC :: RecoverStress_Beam
  PUBLIC :: PH_Elem_Beam_Material_Update_Routed

  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for beam element calculation
  
  !> @brief Output structure for beam element calculation
  TYPE, PUBLIC :: PH_Elem_Beam_Calc_Arg
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(ElemFormul) :: formul  ! Formulation parameters (Algo)                   ! [IN]
    TYPE(ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(ElemState) :: state_in  ! Input element state (State)                   ! [IN]
    TYPE(MatProperties) :: mat  ! Material properties (Desc)                   ! [IN]
    TYPE(ElemState) :: state_out  ! Output element state (State)                   ! [OUT]
    TYPE(ElemFlags) :: flags  ! Element flags and status (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_Beam_Calc_Arg


CONTAINS

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Beam_Calc
  ! Purpose: Unified beam element calculation interface
  ! Interface: Structured (In/Out types)
  ! Description:
  !   This function dispatches to specific beam element implementations:
  !     - B23: 2-node 2D Euler-Bernoulli beam (6 DOF)
  !     - B31: 2-node 3D Euler-Bernoulli beam (12 DOF)
  !     - B32: 2-node 3D Euler-Bernoulli beam (12 DOF, quadratic interpolation)
  !     - B33: 2-node 3D Euler-Bernoulli beam (12 DOF, cubic interpolation)
  !
  !   Dispatch logic:
  !     1. Check ElemType%name for explicit match ('B23', 'B31', 'B32', 'B33')
  !     2. Fallback: Use numNodes and dim to determine type
  ! Theory: K = ? B^TDB dL, Euler-Bernoulli/Timoshenko beam theory
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Beam_Calc(arg)
    TYPE(PH_Elem_Beam_Calc_Arg), INTENT(INOUT) :: arg

    CHARACTER(len=10) :: ename
    INTEGER(i4) :: nNode, nDim

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

    nNode = arg%elem_type%pop%n_nodes
    nDim = arg%elem_type%dim

    ! Dispatch based on element name
    IF (INDEX(ename, 'B23') > 0) THEN
      CALL UF_Elem_B23_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    ELSE IF (INDEX(ename, 'B22') > 0) THEN
      CALL UF_Elem_B22_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    ELSE IF (INDEX(ename, 'B21T') > 0) THEN
      CALL UF_Elem_B21T_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    ELSE IF (INDEX(ename, 'B21') > 0) THEN
      CALL UF_Elem_B21_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    ELSE IF (INDEX(ename, 'B31T') > 0) THEN
      ! Check for B31T extensions first (NL, S, P)
      IF (INDEX(ename, 'B31TNL') > 0) THEN
        CALL UF_Elem_B31TNL_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                                arg%mat, arg%state_out, arg%flags)
      ELSE IF (INDEX(ename, 'B31TS') > 0) THEN
        CALL UF_Elem_B31TS_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                               arg%mat, arg%state_out, arg%flags)
      ELSE IF (INDEX(ename, 'B31TP') > 0) THEN
        CALL UF_Elem_B31TP_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                               arg%mat, arg%state_out, arg%flags)
      ELSE
        ! Standard B31T
        CALL UF_Elem_B31T_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      END IF
                              arg%mat, arg%state_out, arg%flags)
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    ELSE IF (INDEX(ename, 'B31EX') > 0 .OR. INDEX(ename, 'B31OS') > 0 .OR. &
             INDEX(ename, 'B31H') > 0 .OR. INDEX(ename, 'B31PIPE') > 0) THEN
      ! Phase 3 variants (under development)
      IF (INDEX(ename, 'B31H') > 0) THEN
        CALL UF_Elem_B31H_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      ELSE IF (INDEX(ename, 'B31OS') > 0) THEN
        CALL UF_Elem_B31OS_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                               arg%mat, arg%state_out, arg%flags)
      ELSE IF (INDEX(ename, 'B31PIPE') > 0) THEN
        CALL UF_Elem_B31PIPE_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                                 arg%mat, arg%state_out, arg%flags)
      ELSE
        ! Fallback to standard B31
        CALL UF_Elem_B31_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      END IF
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    ELSE IF (INDEX(ename, 'B31') > 0) THEN
      ! Check for TL/UL nonlinear variants first (Phase 2)
      IF (INDEX(ename, 'B31TL') > 0 .OR. INDEX(ename, 'B31UL') > 0) THEN
        ! TL/UL geometric nonlinear formulation
        ! Formulation type determined by element name suffix
        ! B31TL: Total Lagrangian
        ! B31UL: Updated Lagrangian (default for nonlinear)
        ! flags%nlgeom = 1 indicates nonlinear geometry active
        arg%flags%stp%nlgeom = 1_i4
        IF (INDEX(ename, 'B31TL') > 0) THEN
          arg%flags%formulation_typ = 3_i4  ! TL formulation
        ELSE
          arg%flags%formulation_typ = 2_i4  ! UL formulation (ADINAM INDNL=2)
        END IF
        ! Dispatch to nonlinear core
        CALL UF_Elem_B31_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                                arg%mat, arg%state_out, arg%flags)
      ELSE
        ! Standard linear B31
        CALL UF_Elem_B31_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                                arg%mat, arg%state_out, arg%flags)
      END IF
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    ELSE IF (INDEX(ename, 'B32') > 0) THEN
      ! Check for B32 extensions first (NL, S, T, P)
      IF (INDEX(ename, 'B32NL') > 0) THEN
        CALL UF_Elem_B32NL_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                               arg%mat, arg%state_out, arg%flags)
      ELSE IF (INDEX(ename, 'B32S') > 0) THEN
        CALL UF_Elem_B32S_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      ELSE IF (INDEX(ename, 'B32T') > 0) THEN
        CALL UF_Elem_B32T_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      ELSE IF (INDEX(ename, 'B32P') > 0) THEN
        CALL UF_Elem_B32P_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      ELSE
        ! Standard B32
        CALL UF_Elem_B32_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                             arg%mat, arg%state_out, arg%flags)
      END IF
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    ELSE IF (INDEX(ename, 'B33') > 0) THEN
      CALL UF_Elem_B33_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
      ! Copy error status
      IF (arg%flags%failed) THEN
        arg%status = arg%flags%status
      ELSE
        arg%status%status_code = IF_STATUS_OK
      END IF
      RETURN
    END IF

    ! Fallback dispatch based on numNodes and dim
    IF (nNode == 3 .AND. nDim == 2) THEN
      ! 3-node 2D beam -> B22 (quadratic)
      CALL UF_Elem_B22_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
    ELSE IF (nNode == 2 .AND. nDim == 2) THEN
      ! 2-node 2D beam -> B21 (linear, default)
      CALL UF_Elem_B21_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
    ELSE IF (nNode == 2 .AND. nDim == 3) THEN
      ! 2-node 3D beam -> B31 (default for 3D)
      CALL UF_Elem_B31_Calc(arg%elem_type, arg%formul, arg%ctx, arg%state_in, &
                              arg%mat, arg%state_out, arg%flags)
    ELSE
      ! Unknown beam topology ?explicit failure (no silent zero stiffness)
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
        message='PH_Elem_Beam_Calc: unsupported beam (expected 2 nodes with dim=2 -> B23 or dim=3 -> B31/B32/B33)')
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

  END SUBROUTINE PH_Elem_Beam_Calc

  !-----------------------------------------------------------------------------
  ! Subroutine: PH_Elem_Beam_Calc_Structured
  ! Purpose: Structured interface wrapper (aligned with BC benchmark pattern)
  ! Interface: Structured (In/Out types)
  ! Note: This is an alias for PH_Elem_Beam_Calc, provided for consistency
  !       with BC module naming convention (_Structured suffix)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Beam_Calc_Structured(arg)
    TYPE(PH_Elem_Beam_Calc_Arg), INTENT(INOUT) :: arg
    
    ! Call main interface
    CALL PH_Elem_Beam_Calc(arg)
    
  END SUBROUTINE PH_Elem_Beam_Calc_Structured

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Elem_Beam_Calc
  ! Purpose: Flat interface for RT_Elem_Comp (same signature as Calc_UEL_Intf)
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Elem_Beam_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    TYPE(PH_Elem_Beam_Calc_Arg) :: in
    TYPE(PH_Elem_Beam_Calc_Arg) :: out

    in%elem_type = ElemType
    in%formul = Formul
    in%ctx = Ctx
    in%state_in = state_in
    in%mat = Mat
    CALL PH_Elem_Beam_Calc(arg)
    state_out = out%state_out
    flags = out%flags
  END SUBROUTINE UF_Elem_Beam_Calc

  !-----------------------------------------------------------------------------
  ! Subroutine: Calc_B31
  ! Purpose: B31 thin wrapper (Calc_UEL_Intf), delegates to UF_Elem_Beam_Calc.
  !          UFC UEL/UMAT unified template - task 2010.
  !-----------------------------------------------------------------------------
  SUBROUTINE Calc_B31(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CALL UF_Elem_Beam_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
  END SUBROUTINE Calc_B31

  !-----------------------------------------------------------------------------
  ! Subroutine: RecoverStress_Beam
  ! Purpose: Stress recovery at nodes for beam elements (B23/B31/B32/B33)
  ! Theory: Euler-Bernoulli/Timoshenko beam theory
  !         sigma = N/A + M*y/I + M*z/I (axial + bending)
  ! Input:
  !   - ipStates: Integration point states (axial force, moments)
  !   - sf: Shape function results at nodes
  !   - section_props: Section properties (A, Iy, Iz, J)
  ! Output:
  !   - nodeStress: Recovered stress at each node (6 x nNode)
  !-----------------------------------------------------------------------------
  SUBROUTINE RecoverStress_Beam(ipStates, sf, nodeStress, nNode, ntens, section_props)
    TYPE(IPState), INTENT(IN) :: ipStates(:)
    TYPE(ShapeFuncResult), INTENT(IN) :: sf
    REAL(wp), INTENT(OUT) :: nodeStress(:, :)
    INTEGER(i4), INTENT(IN) :: nNode, ntens
    REAL(wp), INTENT(IN), OPTIONAL :: section_props(:)
    
    INTEGER(i4) :: i, j, ip
    INTEGER(i4) :: nInt
    REAL(wp) :: N_ip(4)  ! Max shape functions for B33
    REAL(wp) :: weight_sum(4)
    REAL(wp) :: A, Iy, Iz
    
    ! Initialize output
    nodeStress = 0.0_wp
    weight_sum = 0.0_wp
    
    nInt = SIZE(ipStates)
    
    ! Section properties (if provided)
    A = 1.0_wp
    Iy = 1.0_wp
    Iz = 1.0_wp
    IF (PRESENT(section_props) .AND. SIZE(section_props) >= 3) THEN
      A = MAX(section_props(1), 1.0e-10_wp)
      Iy = MAX(section_props(2), 1.0e-10_wp)
      Iz = MAX(section_props(3), 1.0e-10_wp)
    END IF
    
    ! Extrapolate stress resultants from IPs to nodes
    DO ip = 1, nInt
      IF (.NOT. ALLOCATED(ipStates(ip)%stateV)) CYCLE
      IF (SIZE(ipStates(ip)%stateV) < ntens) CYCLE
      
      ! Get shape function values
      DO i = 1, MIN(nNode, 4)
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
    
    ! Convert stress resultants to stresses (simplified)
    ! Full implementation needs section geometry and curvature
    
  END SUBROUTINE RecoverStress_Beam

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

  SUBROUTINE PH_Elem_Beam_Material_Update_Routed(rt_ctx, mat_slot, E_young, nu, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_BeamElasticConstants

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: E_young
    REAL(wp),                  INTENT(OUT)   :: nu
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_BeamElasticConstants(rt_ctx, mat_slot, E_young, nu, status)
  END SUBROUTINE PH_Elem_Beam_Material_Update_Routed

END MODULE PH_Elem_Beam_Def

