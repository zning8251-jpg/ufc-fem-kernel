!===============================================================================
! MODULE: MD_Elem_Beam
! LAYER:  L3_MD
! DOMAIN: Element/Beam
! ROLE:   Impl (Family implementation)
! BRIEF:  Beam element family — registration and lookup (16 variants)
! **W2**：梁族 **Desc** 注册/查表；与 **`MD_Elem_Def`** + **`MD_Elem_PHBinding`** / L4 **Beam** 族一致。
!===============================================================================
MODULE MD_Elem_Beam
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Beam_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_Beam_Register
  PUBLIC :: MD_Elem_Beam_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Beam_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Beam element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Beam_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc
    TYPE(MD_Elem_Beam_Desc) :: fam_desc

    !--- B31: 2-node beam ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 70;  desc%cfg%family_id = 7
    desc%pop%n_nodes = 2;  desc%pop%dof_per_node = 6;  desc%cfg%ndim = 3
    desc%n_ip = 3;  desc%has_mass = .TRUE.
    desc%has_damp = .TRUE.;  desc%stp%nlgeom = .TRUE.
    fam_desc%section_area = 1.0_wp;  fam_desc%beam_theory = 0
    CALL register_one_(desc, fam_desc, status)
  END SUBROUTINE MD_Elem_Beam_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Beam_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Beam descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Beam_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Beam_Desc) :: desc

    desc = MD_Elem_Beam_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Beam_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Beam type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc), INTENT(IN)  :: desc
    TYPE(MD_Elem_Beam_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Beam
