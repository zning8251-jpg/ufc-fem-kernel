!===============================================================================
! MODULE: MD_Elem_Truss
! LAYER:  L3_MD
! DOMAIN: Element/Truss
! ROLE:   Impl (Family implementation)
! BRIEF:  Truss element family — registration and lookup (6 variants)
! **W2**：桁架族 **Desc**；→ **`MD_ELEM_BIND_TRUSS`** / L4 Truss 核。
!===============================================================================
MODULE MD_Elem_Truss
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Truss_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Truss_Register
  PUBLIC :: MD_Elem_Truss_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Truss_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Truss element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Truss_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc)  :: desc
    TYPE(MD_Elem_Truss_Desc) :: fam_desc

    !--- T3D2: 3D 2-node truss ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 80;  desc%cfg%family_id = 8
    desc%pop%n_nodes = 2;  desc%pop%dof_per_node = 3;  desc%cfg%ndim = 3
    desc%n_ip = 2;  desc%has_mass = .TRUE.
    fam_desc%cross_section = 1.0_wp
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Truss_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Truss_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Truss descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Truss_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Truss_Desc) :: desc

    desc = MD_Elem_Truss_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Truss_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Truss type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),  INTENT(IN)  :: desc
    TYPE(MD_Elem_Truss_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),    INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Truss
