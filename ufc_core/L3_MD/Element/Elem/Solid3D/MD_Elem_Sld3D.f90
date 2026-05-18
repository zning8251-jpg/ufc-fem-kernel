!===============================================================================
! MODULE: MD_Elem_Sld3D
! LAYER:  L3_MD
! DOMAIN: Element/Solid3D
! ROLE:   Impl (Family implementation)
! BRIEF:  3D solid element family — registration and lookup (18 variants)
! **W2**：实体族 **Desc** 注册/查表；与 **`MD_Elem_PHBinding`** / **`PH_Elem_Sld3D*`** 路由闭环。
!===============================================================================
MODULE MD_Elem_Sld3D
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Solid3D_Desc
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! SECTION: Public interfaces (three-segment naming)
  !=============================================================================
  PUBLIC :: MD_Elem_Sld3D_Register
  PUBLIC :: MD_Elem_Sld3D_Lookup


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Sld3D_Register
  ! PHASE:      P0
  ! PURPOSE:    Register all Solid3D element variants
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Sld3D_Register(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(ErrorStatusType) :: ls
    TYPE(MD_Elem_Desc)    :: desc
    TYPE(MD_Elem_Solid3D_Desc) :: fam_desc

    !--- C3D8: 8-node linear brick ---
    desc = MD_Elem_Desc()
    desc%cfg%elem_type_id = 10;  desc%cfg%family_id = 1
    desc%pop%n_nodes = 8;  desc%pop%dof_per_node = 3;  desc%cfg%ndim = 3
    desc%n_ip = 8;  desc%has_mass = .TRUE.;  desc%stp%nlgeom = .TRUE.
    fam_desc%n_ip_default = 8;  fam_desc%reduced_integration = .FALSE.
    CALL register_one_(desc, fam_desc, ls)
    IF (.NOT. ls%ok) GOTO 999

    !--- C3D8R: reduced integration ---
    desc%cfg%elem_type_id = 11;  desc%n_ip = 1
    fam_desc%n_ip_default = 1;  fam_desc%reduced_integration = .TRUE.
    CALL register_one_(desc, fam_desc, ls)
    IF (.NOT. ls%ok) GOTO 999

    !--- C3D4: 4-node tetrahedron ---
    desc%cfg%elem_type_id = 12;  desc%pop%n_nodes = 4;  desc%n_ip = 4
    fam_desc%n_ip_default = 4;  fam_desc%reduced_integration = .FALSE.
    CALL register_one_(desc, fam_desc, ls)

    CALL init_error_status(status, IF_STATUS_OK)
    RETURN
999 CONTINUE
    status = ls
  END SUBROUTINE MD_Elem_Sld3D_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Sld3D_Lookup
  ! PHASE:      P1
  ! PURPOSE:    Get Solid3D descriptor by element type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Sld3D_Lookup(elem_type_id, status) RESULT(desc)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Solid3D_Desc) :: desc

    ! TODO: Lookup from registry
    desc = MD_Elem_Solid3D_Desc()
    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Sld3D_Lookup

  !---------------------------------------------------------------------------
  ! SUBROUTINE: register_one_
  ! PHASE:      P0 (private)
  ! PURPOSE:    Register single Solid3D type
  !---------------------------------------------------------------------------
  SUBROUTINE register_one_(desc, fam_desc, status)
    TYPE(MD_Elem_Desc),    INTENT(IN)  :: desc
    TYPE(MD_Elem_Solid3D_Desc), INTENT(IN)  :: fam_desc
    TYPE(ErrorStatusType),      INTENT(OUT) :: status

    ! TODO: Call MD_Elem_Reg_Register from MD_Elem_Reg
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE register_one_

END MODULE MD_Elem_Sld3D
