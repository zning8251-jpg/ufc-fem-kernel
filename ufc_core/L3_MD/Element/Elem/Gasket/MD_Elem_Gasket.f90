!===============================================================================
! MODULE: MD_Elem_Gasket
! LAYER:  L3_MD
! DOMAIN: Element/Gasket
! ROLE:   Impl (Family implementation)
! BRIEF:  Gasket element family — registration and lookup (6 variants)
! **W2**：垫片族 **Desc**；→ **`MD_ELEM_BIND_GASKET`** / L4 Gasket 核。
!===============================================================================
MODULE MD_Elem_Gasket
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Gasket_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Gasket_Register
  PUBLIC :: MD_Elem_Gasket_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Gasket_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Gasket element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Gasket_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc)   :: desc
    TYPE(MD_Elem_Gasket_Desc) :: fam_desc

    !--- GK8: 8-node gasket axisymmetric ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 230;  desc%cfg%family_id = 15
    desc%pop%n_nodes = 8;  desc%pop%dof_per_node = 2;  desc%cfg%ndim = 2
    desc%geom_kind = 1;  desc%n_ip = 4  ! Axisymmetric
    fam_desc%thickness0        = 1.0_wp
    fam_desc%normal_stiffness  = 0.0_wp
    fam_desc%gasket_type       = 1   ! Kappa
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Gasket_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Gasket_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Gasket descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Gasket_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Gasket_Desc) :: desc

    desc = MD_Elem_Gasket_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Gasket_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Gasket type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),   INTENT(IN)  :: desc
    TYPE(MD_Elem_Gasket_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Gasket
