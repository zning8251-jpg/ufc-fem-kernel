!===============================================================================
! MODULE: MD_Elem_PHBinding
! LAYER:  L3_MD
! DOMAIN: Element
! ROLE:   Brg (Bridge — L3↔L4 cross-layer binding)
! BRIEF:  Bidirectional mapping between L3_MD element descriptors and L4_PH cores
! **W2**：**`MD_ELEM_BIND_*`** L3↔L4 族映射；连通性/实例仍以 **Populate→Domain** 为真源，
!         本模块不做第二套网格仓。
!===============================================================================
MODULE MD_Elem_PHBinding
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Solid3D_Desc,    &
                           MD_Elem_Shell_Desc, MD_Elem_Beam_Desc,      &
                           MD_Elem_Truss_Desc, MD_Elem_Solid2D_Desc,   &
                           MD_Elem_Infinite_Desc, MD_Elem_Cohesive_Desc, &
                           MD_Elem_Spring_Desc, MD_Elem_Dashpot_Desc,  &
                           MD_Elem_Mass_Desc, MD_Elem_Gasket_Desc,     &
                           MD_Elem_Surface_Desc
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! SECTION: Binding constants — MD_ELEM_BIND_ prefix
  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_SOLID3D  = 1
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_SHELL    = 2
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_BEAM     = 3
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_TRUSS    = 4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_SOLID2D  = 5
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_INFINITE = 6
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_COHESIVE = 7
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_SPRING   = 8
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_DASHPOT  = 9
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_MASS     = 10
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_GASKET   = 11
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_BIND_SURFACE  = 12

  !=============================================================================
  ! SECTION: Public interfaces (three-segment naming)
  !=============================================================================
  PUBLIC :: MD_Elem_Brg_GetBindingId
  PUBLIC :: MD_Elem_Brg_GetPHModule
  PUBLIC :: MD_Elem_Brg_Validate
  PUBLIC :: MD_Elem_Brg_GetTable


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Brg_GetBindingId
  ! PHASE:      P1
  ! PURPOSE:    Map element type ID to binding group
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Brg_GetBindingId(elem_type_id) RESULT(bind_id)
    INTEGER(i4), INTENT(IN) :: elem_type_id
    INTEGER(i4) :: bind_id

    SELECT CASE (elem_type_id)
    CASE (10:29);   bind_id = MD_ELEM_BIND_SOLID3D   ! Solid3D
    CASE (50:69);   bind_id = MD_ELEM_BIND_SHELL      ! Shell
    CASE (70:89);   bind_id = MD_ELEM_BIND_BEAM       ! Beam
    CASE (90:99);   bind_id = MD_ELEM_BIND_TRUSS      ! Truss
    CASE (20:49);   bind_id = MD_ELEM_BIND_SOLID2D    ! Solid2D
    CASE (100:109); bind_id = MD_ELEM_BIND_INFINITE   ! Infinite
    CASE (110:119); bind_id = MD_ELEM_BIND_COHESIVE   ! Cohesive
    CASE (200:209); bind_id = MD_ELEM_BIND_SPRING     ! Spring
    CASE (210:219); bind_id = MD_ELEM_BIND_DASHPOT    ! Dashpot
    CASE (220:229); bind_id = MD_ELEM_BIND_MASS       ! Mass
    CASE (230:239); bind_id = MD_ELEM_BIND_GASKET     ! Gasket
    CASE (240:249); bind_id = MD_ELEM_BIND_SURFACE    ! Surface
    CASE DEFAULT;   bind_id = 0                        ! Unknown
    END SELECT
  END FUNCTION MD_Elem_Brg_GetBindingId

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Brg_GetPHModule
  ! PHASE:      P1
  ! PURPOSE:    Get L4_PH module name for element type
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Brg_GetPHModule(elem_type_id) RESULT(module_name)
    INTEGER(i4), INTENT(IN) :: elem_type_id
    CHARACTER(LEN=64) :: module_name
    INTEGER(i4) :: bind_id

    bind_id = MD_Elem_Brg_GetBindingId(elem_type_id)

    SELECT CASE (bind_id)
    CASE (MD_ELEM_BIND_SOLID3D)
      module_name = "PH_Elem_SLD3D_Core"
    CASE (MD_ELEM_BIND_SHELL)
      module_name = "PH_Elem_SHELL_Core"
    CASE (MD_ELEM_BIND_BEAM)
      IF (elem_type_id >= 180 .AND. elem_type_id <= 189) THEN
        module_name = "PH_ElemPipe"
      ELSE
        module_name = "PH_Elem_BEAM_Core"
      END IF
    CASE (MD_ELEM_BIND_TRUSS)
      module_name = "PH_Elem_TRUSS_Core"
    CASE (MD_ELEM_BIND_SOLID2D)
      IF (elem_type_id >= 40 .AND. elem_type_id <= 49) THEN
        module_name = "PH_Elem_SLD2DT_Core"
      ELSE
        module_name = "PH_Elem_SLD2D_Core"
      END IF
    CASE (MD_ELEM_BIND_INFINITE)
      module_name = "PH_ElemInfinite"
    CASE (MD_ELEM_BIND_COHESIVE)
      module_name = "PH_Elem_SPECIAL_COHESIVE_Core"
    CASE (MD_ELEM_BIND_SPRING)
      module_name = "PH_Elem_SPRING_Core"
    CASE (MD_ELEM_BIND_DASHPOT)
      module_name = "PH_Elem_DASHPOT_Core"
    CASE (MD_ELEM_BIND_MASS)
      module_name = "PH_Elem_SPECIAL_MASS_Core"
    CASE (MD_ELEM_BIND_GASKET)
      module_name = "PH_Elem_SPECIAL_GASKET_Core"
    CASE (MD_ELEM_BIND_SURFACE)
      module_name = "PH_Elem_SurfaceEffect_Core"
    CASE DEFAULT
      module_name = "UNKNOWN"
    END SELECT
  END FUNCTION MD_Elem_Brg_GetPHModule

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Brg_Validate
  ! PHASE:      P0
  ! PURPOSE:    Validate L3_MD descriptor compatibility with L4_PH core
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Brg_Validate(desc, ph_core_name, is_valid, msg) RESULT(status)
    TYPE(MD_Elem_Desc), INTENT(IN)  :: desc
    CHARACTER(LEN=*),        INTENT(IN)  :: ph_core_name
    LOGICAL,                 INTENT(OUT) :: is_valid
    CHARACTER(LEN=*),        INTENT(OUT) :: msg
    INTEGER(i4) :: status

    is_valid = .TRUE.
    msg      = ""
    status   = 0

    IF (desc%cfg%ndim /= 2 .AND. desc%cfg%ndim /= 3) THEN
      is_valid = .FALSE.
      msg      = "Invalid dimension (must be 2 or 3)"
      status   = -1
      RETURN
    END IF

    IF (desc%pop%dof_per_node <= 0) THEN
      is_valid = .FALSE.
      msg      = "Invalid DOF per node"
      status   = -2
      RETURN
    END IF

    IF (desc%pop%n_nodes <= 0) THEN
      is_valid = .FALSE.
      msg      = "Invalid node count"
      status   = -3
      RETURN
    END IF

    status = 1  ! Validation passed
  END FUNCTION MD_Elem_Brg_Validate

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Brg_GetTable
  ! PHASE:      P1
  ! PURPOSE:    Return complete binding table for documentation
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Brg_GetTable(n_entries, table)
    INTEGER(i4),              INTENT(OUT) :: n_entries
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: table(:,:)

    INTEGER(i4), PARAMETER :: MD_ELEM_BIND_TABLE_MAX = 124

    ALLOCATE(table(MD_ELEM_BIND_TABLE_MAX, 3))
    table     = 0
    n_entries = 0

    ! TODO: Populate complete table with all 124 element variants
  END SUBROUTINE MD_Elem_Brg_GetTable

END MODULE MD_Elem_PHBinding
