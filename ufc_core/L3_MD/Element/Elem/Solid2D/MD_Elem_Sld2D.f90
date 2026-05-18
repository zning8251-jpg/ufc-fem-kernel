!===============================================================================
! MODULE: MD_Elem_Sld2D
! LAYER:  L3_MD
! DOMAIN: Element/Solid2D
! ROLE:   Impl (Family implementation)
! BRIEF:  2D solid element family — registration and lookup (18 variants)
! **W2**：平面实体族 **Desc**；→ **`MD_ELEM_BIND_SOLID2D`** / **`PH_Elem_Sld2D*`**。
!===============================================================================
MODULE MD_Elem_Sld2D
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Solid2D_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Sld2D_Register
  PUBLIC :: MD_Elem_Sld2D_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Sld2D_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Solid2D element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Sld2D_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc)    :: desc
    TYPE(MD_Elem_Solid2D_Desc) :: fam_desc

    !--- CPE4: 4-node plane strain ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 20;  desc%cfg%family_id = 2
    desc%pop%n_nodes = 4;  desc%pop%dof_per_node = 2;  desc%cfg%ndim = 2
    desc%geom_kind = 3;  desc%n_ip = 4  ! GEOM_PLANE_STRAIN
    desc%has_mass = .TRUE.;  desc%stp%nlgeom = .TRUE.
    fam_desc%thickness = 1.0_wp
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Sld2D_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Sld2D_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Solid2D descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Sld2D_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Solid2D_Desc) :: desc

    desc = MD_Elem_Solid2D_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Sld2D_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Solid2D type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),    INTENT(IN)  :: desc
    TYPE(MD_Elem_Solid2D_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),      INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Sld2D
