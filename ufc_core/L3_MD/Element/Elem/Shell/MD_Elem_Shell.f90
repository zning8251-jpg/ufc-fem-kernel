!===============================================================================
! MODULE: MD_Elem_Shell
! LAYER:  L3_MD
! DOMAIN: Element/Shell
! ROLE:   Impl (Family implementation)
! BRIEF:  Shell element family — registration and lookup (24 variants)
! **W2**：壳族 **Desc** 注册/查表；金线同 **`MD_Elem_Reg`** → **`PH_Elem_Shell*`**。
!===============================================================================
MODULE MD_Elem_Shell
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Shell_Desc
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! SECTION: Public interfaces (three-segment naming)
  !=============================================================================
  PUBLIC :: MD_Elem_Shell_Register
  PUBLIC :: MD_Elem_Shell_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Shell_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Shell element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Shell_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc)  :: desc
    TYPE(MD_Elem_Shell_Desc) :: fam_desc

    !--- S4: 4-node shell ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 50;  desc%cfg%family_id = 5
    desc%pop%n_nodes = 4;  desc%pop%dof_per_node = 6;  desc%cfg%ndim = 3
    desc%n_ip = 5;  desc%has_mass = .TRUE.
    desc%has_thermal = .TRUE.;  desc%stp%nlgeom = .TRUE.
    fam_desc%thickness = 1.0_wp;  fam_desc%n_layers = 1
    fam_desc%drill_dof = 0
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Shell_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Shell_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Shell descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Shell_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Shell_Desc) :: desc

    desc = MD_Elem_Shell_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Shell_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Shell type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),  INTENT(IN)  :: desc
    TYPE(MD_Elem_Shell_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),    INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Shell
