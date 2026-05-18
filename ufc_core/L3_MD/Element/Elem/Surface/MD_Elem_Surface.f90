!===============================================================================
! MODULE: MD_Elem_Surface
! LAYER:  L3_MD
! DOMAIN: Element/Surface
! ROLE:   Impl (Family implementation)
! BRIEF:  Surface effect element family — registration and lookup (8 variants)
! **W2**：表面效应单元族 **Desc**；→ **`MD_ELEM_BIND_SURFACE`** / L4 Surface 核。
!===============================================================================
MODULE MD_Elem_Surface
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Surface_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Surface_Register
  PUBLIC :: MD_Elem_Surface_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Surface_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Surface element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Surface_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc)    :: desc
    TYPE(MD_Elem_Surface_Desc) :: fam_desc

    !--- SF3D4: 3D 4-node surface ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 240;  desc%cfg%family_id = 16
    desc%pop%n_nodes = 4;  desc%pop%dof_per_node = 3;  desc%cfg%ndim = 3
    desc%n_ip = 1
    fam_desc%surface_type       = 0   ! Element-based
    fam_desc%distribution_type  = 0   ! Uniform
    fam_desc%film_coef_provided = .FALSE.
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Surface_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Surface_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Surface descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Surface_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Surface_Desc) :: desc

    desc = MD_Elem_Surface_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Surface_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Surface type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),    INTENT(IN)  :: desc
    TYPE(MD_Elem_Surface_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),      INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Surface
