!===============================================================================
! MODULE: MD_Elem_Infinite
! LAYER:  L3_MD
! DOMAIN: Element/Infinite
! ROLE:   Impl (Family implementation)
! BRIEF:  Infinite element family — registration and lookup (8 variants)
! **W2**：无限元族 **Desc**；→ **`MD_ELEM_BIND_INFINITE`** / L4 Infinite 核。
!===============================================================================
MODULE MD_Elem_Infinite
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Infinite_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Infinite_Register
  PUBLIC :: MD_Elem_Infinite_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Infinite_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Infinite element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Infinite_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc)      :: desc
    TYPE(MD_Elem_Infinite_Desc)  :: fam_desc

    !--- CIN3D8: 3D 8-node infinite ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 100;  desc%cfg%family_id = 17
    desc%pop%n_nodes = 8;  desc%pop%dof_per_node = 3;  desc%cfg%ndim = 3
    desc%n_ip = 4
    fam_desc%decay_function = 1;  fam_desc%r_decay = 1.5_wp
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Infinite_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Infinite_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Infinite descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Infinite_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Infinite_Desc) :: desc

    desc = MD_Elem_Infinite_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Infinite_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Infinite type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),     INTENT(IN)  :: desc
    TYPE(MD_Elem_Infinite_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Infinite
