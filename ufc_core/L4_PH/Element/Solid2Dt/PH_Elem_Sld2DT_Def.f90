!===============================================================================
! MODULE: PH_Elem_Sld2DT_Def
! LAYER:  L4_PH
! DOMAIN: Element/Solid2Dt
! ROLE:   Def
! BRIEF:  2D thermally coupled solid (Sld2DT) L4 unified definition module.
! **W2**：**平面热力耦合实体** 族 **Defn**；与 **`PH_Elem_Sld2D*`** / 热路径一致。
!===============================================================================
MODULE PH_Elem_Sld2DT_Def
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  !! ===================================================================
  !! UniField-Core 2D Thermal-Structural Continuum Element Definition Module ( ï¿?
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Element/SLD2DT
  !!   KIND: Core (2D thermal-structural continuum element kernels & unified interface)
  !!
  !! This module provides the main 2D thermal-structural continuum element interface:
  !!   - UF_Elem_Sld2DT_Calc: Unified interface with struct-based parameters
  !!   - Internal dispatch to element-family-specific implementations
  !!
  !! Design Principles:
  !!   -  ï¿? This is the main module for SLD2DT family
  !!   - Unified struct-based interface for L5_RT layer stability
  !!   - Internal dispatch to CPS*T/CPE*T/CAX*T specific implementations
  !!   - Maintains backward compatibility
  !! ===================================================================

  use IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: wp, i4
  use MD_Base_ElemLib
  USE MD_Base_ObjModel, only: MatCtxLegacy, MatRes, MatProps, IPState
  use MD_Model_Mgr
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, only: MatProperties
  use PH_ElemContm_Ops, only: Calc_Continuum2D_Thermal
  use UF_Material_Base
  ! NOTE: Register additional 2D thermal-structural element modules here when implemented.
  ! use PH_Elem_CPS4T_Definition, only: UF_Elem_CPS4T_Calc
  ! use PH_Elem_CPE4T_Definition, only: UF_Elem_CPE4T_Calc
  ! use PH_Elem_CAX4T_Definition, only: UF_Elem_CAX4T_Calc

  implicit none
  private

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  public :: UF_Elem_Sld2DT_Calc

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Sld2DT_Args
  TYPE :: PH_Elem_Sld2DT_Args
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
  REAL(wp)              :: k_therm     = 0.0_wp  ! thermal conductivity scale
  REAL(wp)              :: rho_cp      = 0.0_wp  ! density times heat capacity
  REAL(wp), POINTER     :: T_elem(:)   => NULL()  ! element temperature vector ptr
  REAL(wp), POINTER     :: Ktherm(:,:) => NULL()  ! thermal-thermal block ptr
  REAL(wp), POINTER     :: F_heat(:)   => NULL()  ! thermal force / heat flux load ptr
  REAL(wp), POINTER     :: ip_temp(:)  => NULL()  ! IP temperature ptr
  END TYPE PH_Elem_Sld2DT_Args


contains

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Elem_Sld2DT_Calc
  ! Purpose: Unified 2D thermal-structural continuum element calculation interface (RT_Elem_Core compatible)
  ! Description:
  !   This function dispatches to specific 2D thermal-structural continuum element implementations:
  !     - CPS*T: Plane stress thermal-structural elements (CPS3T, CPS4T, CPS6T, CPS8T)
  !     - CPE*T: Plane strain thermal-structural elements (CPE3T, CPE4T, CPE6T, CPE8T)
  !     - CAX*T: Axisymmetric thermal-structural elements (CAX3T, CAX4T, CAX6T, CAX8T)
  !
  !   Dispatch logic:
  !     1. Check ElemType%name for explicit match ('CPS*T', 'CPE*T', 'CAX*T')
  !     2. Fallback: Use Calc_Continuum2D_Thermal for all 2D thermal-structural continuum elements
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Elem_Sld2DT_Calc(ElemType, Formul, Ctx, state_in, &
                                  Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    CHARACTER(len=32) :: ename
    INTEGER(i4) :: nInt, i
    TYPE(UF_MaterialModel), ALLOCATABLE :: matModels(:)

    ! Get element name (uppercase for comparison)
    ename = ElemType%name
    CALL UPPER_CASE(ename)

    ! Convert MatProperties to UF_MaterialModel array for compatibility
    nInt = MAX(1_i4, ElemType%n_int_points)
    ALLOCATE(matModels(nInt))
    ! Initialize matModels array with Mat properties
    DO i = 1, nInt
      matModels(i)%cfg%id = Mat%material_id
      matModels(i)%props = Mat
    END DO

    ! Dispatch based on element name prefix
    ! All 2D thermal-structural continuum elements (CPS*T, CPE*T, CAX*T) use Calc_Continuum2D_Thermal
    IF ((INDEX(ename, 'CPS') > 0 .OR. INDEX(ename, 'CPE') > 0 .OR. INDEX(ename, 'CAX') > 0) .AND. &
        INDEX(ename, 'T') > 0) THEN
      ! 2D thermal-structural continuum elements
      CALL Calc_Continuum2D_Thermal(ElemType, Formul, Ctx, state_in, &
                                    matModels, state_out, flags)
    ELSE
      ! Unknown type - try Calc_Continuum2D_Thermal as fallback
      CALL Calc_Continuum2D_Thermal(ElemType, Formul, Ctx, state_in, &
                                    matModels, state_out, flags)
    END IF

    DEALLOCATE(matModels)

  END SUBROUTINE UF_Elem_Sld2DT_Calc

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

END MODULE PH_Elem_Sld2DT_Def