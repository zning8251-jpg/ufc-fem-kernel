!===============================================================================
! MODULE: MD_Elem_Mass
! LAYER:  L3_MD
! DOMAIN: Element/Mass
! ROLE:   Impl (Family implementation)
! BRIEF:  Mass element family — registration and lookup (2 variants)
! **W2**：质量元族 **Desc**；→ **`MD_ELEM_BIND_MASS`** / L4 Mass 核。
!===============================================================================
MODULE MD_Elem_Mass
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Mass_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Mass_Register
  PUBLIC :: MD_Elem_Mass_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Mass_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Mass element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Mass_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc
    TYPE(MD_Elem_Mass_Desc) :: fam_desc

    !--- MASS: Concentrated mass ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 220;  desc%cfg%family_id = 14
    desc%pop%n_nodes = 1;  desc%pop%dof_per_node = 6;  desc%cfg%ndim = 3
    desc%n_ip = 1;  desc%has_mass = .TRUE.
    fam_desc%mass_value     = 0.0_wp
    fam_desc%rotary_inertia = .FALSE.
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Mass_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Mass_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Mass descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Mass_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Mass_Desc) :: desc

    desc = MD_Elem_Mass_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Mass_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Mass type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc), INTENT(IN)  :: desc
    TYPE(MD_Elem_Mass_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Mass
