!===============================================================================
! MODULE: PH_Elem_DispatchC3D8
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Dispatch
! BRIEF:  C3D8 element dispatch interface - structural adaptation to flat parameter interf
!===============================================================================
MODULE PH_Elem_DispatchC3D8
!> Status: Production | Last verified: 2026-03-01
!> Theory: Element dispatcher for multiple formulations | Ref: UFC Architecture
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Prec_Core, ONLY: wp, i4

  ! Core and Unit Implementations
  USE PH_Elem_C3D8_Constraints
  USE PH_Elem_C3D8_Contact
  USE PH_Elem_C3D8_Definition
  USE PH_Elem_C3D8_Loads
  USE PH_Elem_C3D8_Output
  USE PH_Elem_C3D8_Section

  IMPLICIT NONE
  PRIVATE

  ! Public Interface
  PUBLIC :: PH_Elem_C3D8_FormStiffMatrix
  PUBLIC :: PH_Elem_C3D8_AssembleForceVector
  PUBLIC :: PH_Elem_C3D8_ApplyConstraints
  PUBLIC :: PH_Elem_C3D8_ApplyContact
  PUBLIC :: PH_Elem_C3D8_ProcessSection
  PUBLIC :: PH_Elem_C3D8_GenerateOutput

  ! Data Structures for Interface
  TYPE :: PH_Elem_C3D8_Data
    INTEGER(i4) :: elem_id
    INTEGER(i4) :: n_nodes = 8
    INTEGER(i4) :: n_dofs_per_node = 3
    REAL(wp) :: coords(8, 3)  ! Node coordinates
    REAL(wp) :: material_props(10)  ! Mat properties
    REAL(wp) :: section_props(5)    ! Section properties
    LOGICAL :: nl_geom = .FALSE.
    LOGICAL :: thermal_coupling = .FALSE.
  END TYPE PH_Elem_C3D8_Data

  TYPE :: PH_Elem_C3D8_Output_Data
    INTEGER(i4) :: n_output_points = 8
    REAL(wp) :: stresses(8, 6)     ! S11, S22, S33, S12, S13, S23
    REAL(wp) :: strains(8, 6)     ! E11, E22, E33, E12, E13, E23
    REAL(wp) :: displacements(24)  ! Nodal displacements
    REAL(wp) :: forces(24)         ! Nodal forces
  END TYPE PH_Elem_C3D8_Output_Data

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

SUBROUTINE PH_El_C3_ApplyConstraints(elem_data, bc_nodes, bc_dofs, bc_values, Ke_reduced)
  TYPE(PH_Elem_C3D8_Data), INTENT(IN) :: elem_data
  INTEGER(i4), INTENT(IN) :: bc_nodes(:)
  INTEGER(i4), INTENT(IN) :: bc_dofs(:)
  REAL(wp), INTENT(IN) :: bc_values(:)
  REAL(wp), INTENT(OUT) :: Ke_reduced(:,:)

  ! Dispatch to constraints implementation
  CALL PH_Elem_C3D8_Constraints_ApplyBC(elem_data%coords, bc_nodes, bc_dofs, bc_values, Ke_reduced)

END SUBROUTINE PH_Elem_C3D8_ApplyConstraints

SUBROUTINE PH_El_C3_AssembleForceVector(elem_data, u, R_int)
  TYPE(PH_Elem_C3D8_Data), INTENT(IN) :: elem_data
  REAL(wp), INTENT(IN) :: u(:)
  REAL(wp), INTENT(OUT) :: R_int(:)

  ! Convert structural data to flat interface
  CALL PH_Elem_C3D8_Loads_AssembleForceVector(elem_data%coords, u, R_int)

END SUBROUTINE PH_Elem_C3D8_AssembleForceVector

SUBROUTINE PH_El_C3_FormCoupledStiffMat(elem_data, D_mech, D_thermal, alpha, Ke_coupled)
  TYPE(PH_Elem_C3D8_Data), INTENT(IN) :: elem_data
  REAL(wp), INTENT(IN) :: D_mech(:,:)
  REAL(wp), INTENT(IN) :: D_thermal(:,:)
  REAL(wp), INTENT(IN) :: alpha
  REAL(wp), INTENT(OUT) :: Ke_coupled(:,:)

  Ke_coupled = 0.0_wp

END SUBROUTINE PH_Elem_C3D8_FormCoupledStiffMatrix

SUBROUTINE PH_Elem_C3D8_ApplyContact(elem_data, contact_surf, penalty, K_contact)
  TYPE(PH_Elem_C3D8_Data), INTENT(IN) :: elem_data
  INTEGER(i4), INTENT(IN) :: contact_surf(:,:)
  REAL(wp), INTENT(IN) :: penalty
  REAL(wp), INTENT(OUT) :: K_contact(:,:)

  ! Dispatch to contact implementation
  CALL PH_Elem_C3D8_Contact_ApplyContact(elem_data%coords, contact_surf, penalty, K_contact)

END SUBROUTINE PH_Elem_C3D8_ApplyContact

SUBROUTINE PH_Elem_C3D8_FormStiffMatrix(elem_data, D_matrix, Ke)
  TYPE(PH_Elem_C3D8_Data), INTENT(IN) :: elem_data
  REAL(wp), INTENT(IN) :: D_matrix(:,:)
  REAL(wp), INTENT(OUT) :: Ke(:,:)

  ! Convert structural data to flat interface
  CALL PH_Elem_C3D8_Definition_StiffMatrix(elem_data%coords, D_matrix, Ke)

END SUBROUTINE PH_Elem_C3D8_FormStiffMatrix

SUBROUTINE PH_Elem_C3D8_GenerateOutput(elem_data, u, output_data)
  TYPE(PH_Elem_C3D8_Data), INTENT(IN) :: elem_data
  REAL(wp), INTENT(IN) :: u(:)
  TYPE(PH_Elem_C3D8_Output_Data), INTENT(OUT) :: output_data

  ! Dispatch to output implementation
  CALL PH_Elem_C3D8_Output_GenerateOutput(elem_data%coords, u, output_data)

END SUBROUTINE PH_Elem_C3D8_GenerateOutput

SUBROUTINE PH_Elem_C3D8_ProcessSection(elem_data, Ke_section)
  TYPE(PH_Elem_C3D8_Data), INTENT(IN) :: elem_data
  REAL(wp), INTENT(OUT) :: Ke_section(:,:)

  ! Dispatch to section implementation
  CALL PH_Elem_C3D8_Section_ProcessSection(elem_data%section_props, Ke_section)

END SUBROUTINE PH_Elem_C3D8_ProcessSection
END MODULE PH_Elem_DispatchC3D8