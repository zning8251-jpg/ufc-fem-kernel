!===============================================================================
! MODULE: PH_Elem_DashDefn
! LAYER:  L4_PH
! DOMAIN: Element/Dashpot
! ROLE:   Def
! BRIEF:  Dashpot element unified interface
! **W2**：L4 **阻尼器** 族 **Defn**；与 **`MD_ELEM_BIND_DASHPOT`** / **`PH_Elem_Core`** 一致。
!===============================================================================
MODULE PH_Elem_Dash_Def
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  !! ===================================================================
  !! UniField-Core Dashpot Element Definition Module ( ï¿?
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Element/DASHPOT
  !!   KIND: Core (Dashpot element kernels & unified interface)
  !!
  !! This module provides the main dashpot element interface:
  !!   - UF_Elem_Dashpot_Calc: Unified interface with struct-based parameters
  !!   - Internal dispatch to element-family-specific implementations
  !!
  !! Design Principles:
  !!   -  ï¿? This is the main module for DASHPOT family
  !!   - Unified struct-based interface for L5_RT layer stability
  !!   - Internal dispatch to DASHPOT1/DASHPOT2 specific implementations
  !!   - Maintains backward compatibility
  !! ===================================================================

  USE IF_Prec_Core, only: wp, i4
  USE IF_Err_Brg, ONLY: init_error_status, IF_STATUS_INVALID
  use MD_Base_ElemLib
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  use MD_Model_Mgr
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState, &
                              UF_Elem_PrepareStructStorage, UF_Element_PrepareIntPointStates
  USE MD_Mat_Lib, only: MatProperties
  use PH_Elem_DASHPOT1, only: UF_Elem_DASHPOT1_Calc
  use PH_Elem_DASHPOT2, only: UF_Elem_DASHPOT2_Calc
  use UF_Material_Base

  implicit none
  private

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  public :: UF_Elem_Dashpot_Calc

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Dashpot_Args
  TYPE :: PH_Elem_Dashpot_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Dashpot_Args


contains

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Elem_Dashpot_Calc
  ! Purpose: Unified dashpot element calculation interface (RT_Elem_Core compatible)
  ! Description:
  !   This function dispatches to specific dashpot element implementations:
  !     - DASHPOT1: 1D dashpot (2-node, 1 DOF per node)
  !     - DASHPOT2: 2D dashpot (2-node, 2 DOF per node)
  !
  !   Dispatch logic:
  !     1. Check ElemType%name for explicit match ('DASHPOT1', 'DASHPOT2')
  !     2. Fallback: Use dim to determine type (1D -> DASHPOT1, 2D -> DASHPOT2)
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Elem_Dashpot_Calc(ElemType, Formul, Ctx, state_in, &
                                    Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CHARACTER(len=10) :: ename
    INTEGER(i4) :: nDim

    ! Get element name (uppercase for comparison)
    ename = ElemType%name
    CALL UPPER_CASE(ename)

    nDim = ElemType%dim

    ! Dispatch based on element name
    IF (INDEX(ename, 'DASHPOT1') > 0) THEN
      CALL UF_Elem_DASHPOT1_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
      RETURN
    ELSE IF (INDEX(ename, 'DASHPOT2') > 0) THEN
      CALL UF_Elem_DASHPOT2_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
      RETURN
    END IF

    ! Fallback dispatch based on dim
    IF (nDim == 1) THEN
      ! 1D -> DASHPOT1
      CALL UF_Elem_DASHPOT1_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
    ELSE IF (nDim == 2) THEN
      ! 2D -> DASHPOT2
      CALL UF_Elem_DASHPOT2_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
    ELSE
      ! Invalid dim �?explicit failure (no silent zero stiffness)
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
        message='UF_Elem_Dashpot_Calc: unsupported ElemType%dim (expected 1=DASHPOT1 or 2=DASHPOT2)')
      state_out%failed = flags%failed
      state_out%stableDt = flags%stableDt
    END IF

  END SUBROUTINE UF_Elem_Dashpot_Calc

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

END MODULE PH_Elem_Dash_Def