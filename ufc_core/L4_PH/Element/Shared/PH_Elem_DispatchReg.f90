!===============================================================================
! MODULE: PH_Elem_DispatchReg
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Dispatch
! BRIEF:  Central registry for all element dispatch interfaces
!===============================================================================
MODULE PH_Elem_DispatchReg
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  USE IF_Prec_Core, ONLY: wp, i4

  ! Import all dispatch modules
  USE PH_Elem_DispatchC3D8
  ! Note: PH_Elem_Dispatch_CPS4 removed - CPS4 elements are handled through
  !       standard SLD2D element modules (PH_Elem_CPS4_Definition, etc.)

  IMPLICIT NONE
  PRIVATE

  ! Element type enumeration
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8 = 1
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D20 = 2
  INTEGER(i4), PARAMETER :: PH_ELEM_CPS4 = 3
  INTEGER(i4), PARAMETER :: PH_ELEM_CPE4 = 4
  INTEGER(i4), PARAMETER :: PH_ELEM_S4 = 5
  INTEGER(i4), PARAMETER :: PH_ELEM_B31 = 6
  INTEGER(i4), PARAMETER :: PH_ELEM_T3D2 = 7
  INTEGER(i4), PARAMETER :: PH_ELEM_DC3D8 = 8
  INTEGER(i4), PARAMETER :: PH_ELEM_AC3D8 = 9
  INTEGER(i4), PARAMETER :: PH_ELEM_C3D8T = 10
  INTEGER(i4), PARAMETER :: PH_ELEM_MAX = 10

  ! Element type database
  CHARACTER(len=10), DIMENSION(PH_ELEM_MAX), PARAMETER :: &
    PH_ELEM_NAMES = ['C3D8     ', &
                  'C3D20    ', &
                  'CPS4     ', &
                  'CPE4     ', &
                  'S4       ', &
                  'B31      ', &
                  'T3D2     ', &
                  'DC3D8    ', &
                  'AC3D8    ', &
                  'C3D8T    ']

  CHARACTER(len=20), DIMENSION(PH_ELEM_MAX), PARAMETER :: &
    PH_ELEM_DESCRIPTIONS = ['8-node hexahedron    ', &
                         '20-node hexahedron   ', &
                         '4-node plane sigma  ', &
                         '4-node plane strain  ', &
                         '4-node shell         ', &
                         '3-node beam          ', &
                         '3-node truss         ', &
                         '8-node thermal       ', &
                         '8-node acoustic      ', &
                         '8-node coupled       ']

  PUBLIC :: PH_ELEM_C3D8, PH_ELEM_C3D20, PH_ELEM_CPS4, PH_ELEM_CPE4
  PUBLIC :: PH_ELEM_S4, PH_ELEM_B31, PH_ELEM_T3D2
  PUBLIC :: PH_ELEM_DC3D8, PH_ELEM_AC3D8, PH_ELEM_C3D8T, PH_ELEM_MAX
  PUBLIC :: PH_ELEM_NAMES, PH_ELEM_DESCRIPTIONS

  ! Registry interface
  PUBLIC :: PH_Elem_Registry_GetElementType
  PUBLIC :: PH_Elem_Registry_GetElementInfo
  PUBLIC :: PH_Elem_Registry_ListElements
  PUBLIC :: PH_Elem_Registry_IsValidElement

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Shared_Args
  TYPE :: PH_Elem_Shared_Args
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
  END TYPE PH_Elem_Shared_Args


CONTAINS

SUBROUTINE PH_Elem_Registry_GetElementInfo(elem_type, name, desc)
  INTEGER(i4), INTENT(IN) :: elem_type
  CHARACTER(len=*), INTENT(OUT) :: name
  CHARACTER(len=*), INTENT(OUT) :: desc

  IF (elem_type >= 1 .AND. elem_type <= PH_ELEM_MAX) THEN
    name = PH_ELEM_NAMES(elem_type)
    desc = PH_ELEM_DESCRIPTIONS(elem_type)
  ELSE
    name = 'UNKNOWN'
    desc = 'Invalid element type'
  END IF

END SUBROUTINE PH_Elem_Registry_GetElementInfo

SUBROUTINE PH_El_Re_ListElements()
  INTEGER(i4) :: i

  PRINT *, 'Available Element Types:'
  PRINT *, '======================='
  DO i = 1, PH_ELEM_MAX
    PRINT '(I2, ": ", A10, " - ", A)', i, PH_ELEM_NAMES(i), PH_ELEM_DESCRIPTIONS(i)
  END DO

END SUBROUTINE PH_Elem_Registry_ListElements

FUNCTION PH_Elem_Registry_GetElementType(elem_name) RESULT(elem_type)
  CHARACTER(len=*), INTENT(IN) :: elem_name
  INTEGER(i4) :: elem_type
  INTEGER(i4) :: i

  elem_type = 0
  DO i = 1, PH_ELEM_MAX
    IF (TRIM(ADJUSTL(elem_name)) == TRIM(ADJUSTL(PH_ELEM_NAMES(i)))) THEN
      elem_type = i
      EXIT
    END IF
  END DO

END FUNCTION PH_Elem_Registry_GetElementType

FUNCTION PH_Elem_Registry_IsValidElement(elem_type) RESULT(is_valid)
  INTEGER(i4), INTENT(IN) :: elem_type
  LOGICAL :: is_valid

  is_valid = (elem_type >= 1 .AND. elem_type <= PH_ELEM_MAX)

END FUNCTION PH_Elem_Registry_IsValidElement
END MODULE PH_Elem_DispatchReg