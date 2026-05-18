!===============================================================================
! MODULE: MD_Elem_Dashpot
! LAYER:  L3_MD
! DOMAIN: Element/Dashpot
! ROLE:   Impl (Family implementation)
! BRIEF:  Dashpot element family — registration and lookup (2 variants)
! **W2**：阻尼器族 **Desc**；→ **`MD_ELEM_BIND_DASHPOT`** / L4 Dashpot 核。
!===============================================================================
MODULE MD_Elem_Dashpot
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Dashpot_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Dashpot_Register
  PUBLIC :: MD_Elem_Dashpot_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Dashpot_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Dashpot element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Dashpot_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc)     :: desc
    TYPE(MD_Elem_Dashpot_Desc)  :: fam_desc

    !--- DASHPOT2: 2-node dashpot ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 210;  desc%cfg%family_id = 13
    desc%pop%n_nodes = 2;  desc%pop%dof_per_node = 3;  desc%cfg%ndim = 3
    desc%n_ip = 1
    fam_desc%dashpot_coeff = 0.0_wp;  fam_desc%direction = 0
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Dashpot_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Dashpot_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Dashpot descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Dashpot_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Dashpot_Desc) :: desc

    desc = MD_Elem_Dashpot_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Dashpot_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Dashpot type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),    INTENT(IN)  :: desc
    TYPE(MD_Elem_Dashpot_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),      INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Dashpot
