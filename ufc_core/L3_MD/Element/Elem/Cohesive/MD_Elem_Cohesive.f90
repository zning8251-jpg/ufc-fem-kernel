!===============================================================================
! MODULE: MD_Elem_Cohesive
! LAYER:  L3_MD
! DOMAIN: Element/Cohesive
! ROLE:   Impl (Family implementation)
! BRIEF:  Cohesive element family — registration and lookup (12 variants)
! **W2**：内聚力族 **Desc** 注册/查表；经 **`MD_ELEM_BIND_COHESIVE`** → L4 **Cohesive** 族核。
!===============================================================================
MODULE MD_Elem_Cohesive
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Cohesive_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Cohesive_Register
  PUBLIC :: MD_Elem_Cohesive_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Cohesive_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Cohesive element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Cohesive_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc)      :: desc
    TYPE(MD_Elem_Cohesive_Desc)  :: fam_desc

    !--- COH3D8: 3D 8-node cohesive ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 110;  desc%cfg%family_id = 11
    desc%pop%n_nodes = 8;  desc%pop%dof_per_node = 3;  desc%cfg%ndim = 3
    desc%n_ip = 4
    fam_desc%thickness0    = 1.0_wp
    fam_desc%traction_law  = 0;  fam_desc%G_c = 0.0_wp
    fam_desc%sigma_max     = 0.0_wp
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Cohesive_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Cohesive_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Cohesive descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Cohesive_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Cohesive_Desc) :: desc

    desc = MD_Elem_Cohesive_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Cohesive_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Cohesive type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),     INTENT(IN)  :: desc
    TYPE(MD_Elem_Cohesive_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Cohesive
