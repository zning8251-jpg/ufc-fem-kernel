!===============================================================================
! MODULE: PH_Elem_Acoustic_Def
! LAYER:  L4_PH
! DOMAIN: Element/Acoustic
! ROLE:   Def
! BRIEF:  Acoustic element unified interface
! **W2**：L4 **声学** 单元接口；与 **`PH_Elem_Acoustic*`** / **`MD_ELEM_BIND_*`**（声学族）及 **`PH_Elem_Core`** 路由一致。
!===============================================================================
MODULE PH_Elem_Acoustic_Def
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec Â§1 (see UFC_ .md) | Last verified: 2026-02-14
  !! ===================================================================
  !! UniField-Core Acoustic Element Definition Module ( Ã¯Â¿?
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Element/ACOUSTIC
  !!   KIND: Core (Acoustic element kernels & unified interface)
  !!
  !! This module provides the main acoustic element interface:
  !!   - UF_Elem_Acoustic_Calc: Unified interface with struct-based parameters
  !!   - Internal dispatch to element-family-specific implementations
  !!
  !! Design Principles:
  !!   -  Ã¯Â¿? This is the main module for ACOUSTIC family
  !!   - Unified struct-based interface for L5_RT layer stability
  !!   - Internal dispatch to AC2D4/AC2D6/AC2D8/AC3D4/AC3D6/AC3D8/AC3D10/AC3D15/AC3D20 specific implementations
  !!   - Maintains backward compatibility
  !! ===================================================================

  USE IF_Prec_Core, only: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_INVALID
  use MD_Base_ElemLib
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  use MD_Model_Mgr
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                              UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib, only: MatProperties
  use PH_Elem_AC2D4, only: UF_Elem_AC2D4_Calc
  use PH_Elem_AC3D8, only: UF_Elem_AC3D8_Calc
  use UF_Material_Base
  ! Additional acoustic elements - all wired
  use PH_Elem_AC3D4, only: UF_Elem_AC3D4_Calc
  use PH_Elem_AC3D6, only: UF_Elem_AC3D6_Calc
  use PH_Elem_AC3D10, only: UF_Elem_AC3D10_Calc
  use PH_Elem_AC3D15, only: UF_Elem_AC3D15_Calc
  use PH_Elem_AC3D20, only: UF_Elem_AC3D20_Calc

  implicit none
  private

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  public :: UF_Elem_Acoustic_Calc
  public :: PH_Elem_Acoustic_Material_Update_Routed

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Acoustic_Args
  TYPE :: PH_Elem_Acoustic_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! [IN]  nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! [IN]  DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! [IN]  integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! [IN]  load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! [IN]  constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! [IN]  face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! [IN]  local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! [IN]  parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp  ! [IN]  parametric coordinate eta
  REAL(wp)              :: zeta        = 0.0_wp  ! [IN]  parametric coordinate zeta
  REAL(wp)              :: detJ        = 0.0_wp ! [INOUT] Jacobian determinant
  REAL(wp)              :: penalty     = 0.0_wp  ! [IN]  penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! [IN]  prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! [IN]  grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! [IN]  grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! [IN]  grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! [IN]  nodal coordinates (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! [IN]  element displacement vector
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! [IN]  material stiffness (elasticity) matrix
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! [OUT] element stiffness matrix
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! [OUT] equivalent nodal force
  REAL(wp), POINTER     :: N(:)        => NULL()  ! [OUT] shape-function matrix
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! [OUT] shape-function spatial derivatives
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! [OUT] strain-displacement operator
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! [OUT] geometric stiffness contribution
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! [OUT] internal residual
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! [OUT] IP stress pack
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! [OUT] IP strain pack
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! [OUT] IP equivalent plastic strain
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! [OUT] output variable mask / ids
  END TYPE PH_Elem_Acoustic_Args


contains

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Elem_Acoustic_Calc
  ! Purpose: Unified acoustic element calculation interface (RT_Elem_Core compatible)
  ! Description:
  !   This function dispatches to specific acoustic element implementations:
  !     - AC2D4: 4-node 2D acoustic quadrilateral
  !     - AC2D6: 6-node 2D acoustic triangle
  !     - AC2D8: 8-node 2D acoustic quadrilateral
  !     - AC3D4: 4-node 3D acoustic tetrahedron
  !     - AC3D6: 6-node 3D acoustic wedge
  !     - AC3D8: 8-node 3D acoustic hexahedron
  !     - AC3D10: 10-node 3D acoustic tetrahedron
  !     - AC3D15: 15-node 3D acoustic wedge
  !     - AC3D20: 20-node 3D acoustic hexahedron
  !
  !   Dispatch logic:
  !     1. Check ElemType%name for explicit match ('AC2D4', 'AC2D6', etc.)
  !     2. Fallback: Use numNodes and dim to determine type
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Elem_Acoustic_Calc(ElemType, Formul, Ctx, state_in, &
                                    Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CHARACTER(len=10) :: ename
    INTEGER(i4) :: nNode, nDim

    ! Get element name (uppercase for comparison)
    ename = ElemType%name
    CALL UPPER_CASE(ename)

    nNode = ElemType%numNodes
    nDim = ElemType%dim

    ! Dispatch based on element name
    IF (INDEX(ename, 'AC2D4') > 0) THEN
      CALL UF_Elem_AC2D4_Calc(ElemType, Formul, Ctx, state_in, &
                              Mat, state_out, flags)
      RETURN
    ELSE IF (INDEX(ename, 'AC3D8') > 0) THEN
      CALL UF_Elem_AC3D8_Calc(ElemType, Formul, Ctx, state_in, &
                              Mat, state_out, flags)
      RETURN
    ! Additional elements - all wired
    ELSE IF (INDEX(ename, 'AC3D4') > 0) THEN
      CALL UF_Elem_AC3D4_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    ELSE IF (INDEX(ename, 'AC3D6') > 0) THEN
      CALL UF_Elem_AC3D6_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    ELSE IF (INDEX(ename, 'AC3D10') > 0) THEN
      CALL UF_Elem_AC3D10_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    ELSE IF (INDEX(ename, 'AC3D15') > 0) THEN
      CALL UF_Elem_AC3D15_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    ELSE IF (INDEX(ename, 'AC3D20') > 0) THEN
      CALL UF_Elem_AC3D20_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)
      RETURN
    END IF

    ! Fallback dispatch based on numNodes and dim
    IF (nDim == 2) THEN
      IF (nNode == 4) THEN
        ! 2D, 4 nodes -> AC2D4
        CALL UF_Elem_AC2D4_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
      ! ELSE IF (nNode == 6) THEN
      !   ! 2D, 6 nodes -> AC2D6
      !   CALL UF_Elem_AC2D6_Calc(ElemType, Formul, Ctx, state_in, &
      !                           Mat, state_out, flags)
      ! ELSE IF (nNode == 8) THEN
      !   ! 2D, 8 nodes -> AC2D8
      !   CALL UF_Elem_AC2D8_Calc(ElemType, Formul, Ctx, state_in, &
      !                           Mat, state_out, flags)
      ELSE
        ! Unknown 2D topology â?explicit failure (no silent zero stiffness)
        CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
        state_out%evo%Ke = 0.0_wp
        state_out%Re = 0.0_wp
        state_out%Me = 0.0_wp
        state_out%Ce = 0.0_wp
        flags%failed = .TRUE.
        flags%suggest_cutback = .FALSE.
        flags%requires_reasse = .TRUE.
        flags%stableDt = 0.0_wp
        CALL init_error_status(flags%status, IF_STATUS_INVALID, &
          message='UF_Elem_Acoustic_Calc: unsupported 2D acoustic topology (only AC2D4 / 4 nodes wired)')
        state_out%failed = flags%failed
        state_out%stableDt = flags%stableDt
      END IF
    ELSE IF (nDim == 3) THEN
      IF (nNode == 4) THEN
        ! 3D, 4 nodes -> AC3D4 (tetrahedron)
        CALL UF_Elem_AC3D4_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
      ELSE IF (nNode == 6) THEN
        ! 3D, 6 nodes -> AC3D6 (wedge)
        CALL UF_Elem_AC3D6_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
      ELSE IF (nNode == 8) THEN
        ! 3D, 8 nodes -> AC3D8 (hexahedron)
        CALL UF_Elem_AC3D8_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
      ELSE IF (nNode == 10) THEN
        ! 3D, 10 nodes -> AC3D10 (quadratic tetrahedron)
        CALL UF_Elem_AC3D10_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
      ELSE IF (nNode == 15) THEN
        ! 3D, 15 nodes -> AC3D15 (quadratic wedge)
        CALL UF_Elem_AC3D15_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
      ELSE IF (nNode == 20) THEN
        ! 3D, 20 nodes -> AC3D20 (quadratic hexahedron)
        CALL UF_Elem_AC3D20_Calc(ElemType, Formul, Ctx, state_in, &
                                Mat, state_out, flags)
      ELSE
        CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
        state_out%evo%Ke = 0.0_wp
        state_out%Re = 0.0_wp
        state_out%Me = 0.0_wp
        state_out%Ce = 0.0_wp
        flags%failed = .TRUE.
        flags%suggest_cutback = .FALSE.
        flags%requires_reasse = .TRUE.
        flags%stableDt = 0.0_wp
        CALL init_error_status(flags%status, IF_STATUS_INVALID, &
          message='UF_Elem_Acoustic_Calc: unsupported 3D acoustic topology (only AC3D4/6/8/10/15/20 wired)'
        state_out%failed = flags%failed
        state_out%stableDt = flags%stableDt
      END IF
    ELSE
      ! Invalid spatial dimension â?explicit failure
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      state_out%Me = 0.0_wp
      state_out%Ce = 0.0_wp
      flags%failed = .TRUE.
      flags%suggest_cutback = .FALSE.
      flags%requires_reasse = .TRUE.
      flags%stableDt = 0.0_wp
      CALL init_error_status(flags%status, IF_STATUS_INVALID, &
        message='UF_Elem_Acoustic_Calc: invalid ElemType%dim (expected 2 or 3)')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
    END IF

  END SUBROUTINE UF_Elem_Acoustic_Calc

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

  SUBROUTINE PH_Elem_Acoustic_Material_Update_Routed(rt_ctx, mat_slot, density, &
                                                     bulk_modulus, sound_speed, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_AcousticFluid

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(OUT)   :: density
    REAL(wp),                  INTENT(OUT)   :: bulk_modulus
    REAL(wp),                  INTENT(OUT)   :: sound_speed
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_AcousticFluid(rt_ctx, mat_slot, density, &
                                        bulk_modulus, sound_speed, status)
  END SUBROUTINE PH_Elem_Acoustic_Material_Update_Routed

END MODULE PH_Elem_Acoustic_Def

