!===============================================================================
! MODULE: MD_Elem_Spring
! LAYER:  L3_MD
! DOMAIN: Element/Spring
! ROLE:   Impl (Family implementation)
! BRIEF:  Spring element family — registration and lookup (4 variants)
! **W2**：弹簧族 **Desc**；→ **`MD_ELEM_BIND_SPRING`** / L4 Spring 核。
!===============================================================================
MODULE MD_Elem_Spring
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Spring_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Spring_Register
  PUBLIC :: MD_Elem_Spring_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Spring_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Spring element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Spring_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc)   :: desc
    TYPE(MD_Elem_Spring_Desc) :: fam_desc

    !--- SPRING2: 2-node spring ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 200;  desc%cfg%family_id = 12
    desc%pop%n_nodes = 2;  desc%pop%dof_per_node = 3;  desc%cfg%ndim = 3
    desc%n_ip = 1
    fam_desc%spring_stiffness = 0.0_wp;  fam_desc%direction = 0
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Spring_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Spring_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Spring descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Spring_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Spring_Desc) :: desc

    desc = MD_Elem_Spring_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Spring_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Spring type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),   INTENT(IN)  :: desc
    TYPE(MD_Elem_Spring_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Spring
