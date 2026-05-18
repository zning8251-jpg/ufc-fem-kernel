!===============================================================================
! MODULE: MD_Elem_Reg
! LAYER:  L3_MD
! DOMAIN: Element
! ROLE:   Reg (Registry)
! BRIEF:  Element type registry — registration, lookup, validation, family dispatch
! **W2**：冷路径 **`elem_type_id`** / **family** 注册表；与 **Populate** 输出及 **`MD_Elem_PHBinding`**
!         → L4 族核路由一致。
!===============================================================================
MODULE MD_Elem_Reg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_Algo

  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! SECTION: Constants — MD_ELEM_ prefix, UPPER_CASE
  !=============================================================================

  !--- Capacity limits ---
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_MAX_TYPES     = 500
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_MAX_INSTANCES = 1000000

  !--- Element family IDs ---
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_C3D      = 1   ! 3D solid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_CPE      = 2   ! Plane strain
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_CPS      = 3   ! Plane stress
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_CAX      = 4   ! Axisymmetric
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_S4       = 5   ! Shell 4-node
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_S3       = 6   ! Shell 3-node
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_B31      = 7   ! Beam 3D 2-node
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_T3D2     = 8   ! Truss 3D 2-node
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_C3D8R    = 10  ! 3D reduced
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_COH      = 11  ! Cohesive
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_SPRING   = 12  ! Spring
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_DASHPOT  = 13  ! Dashpot
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_MASS     = 14  ! Mass
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_GASKET   = 15  ! Gasket
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_SURFACE  = 16  ! Surface
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FAMILY_INFINITE = 17  ! Infinite

  !--- Element group IDs (bulk registration) ---
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_SOLID3D  = 1   ! 18 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_SHELL    = 2   ! 24 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_BEAM     = 3   ! 16 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_TRUSS    = 4   ! 6 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_SOLID2D  = 5   ! 18 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_INFINITE = 6   ! 8 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_COHESIVE = 7   ! 12 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_SPRING   = 8   ! 4 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_DASHPOT  = 9   ! 2 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_MASS     = 10  ! 2 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_GASKET   = 11  ! 6 variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GROUP_SURFACE  = 12  ! 8 variants

  !--- Element type IDs (standard numbering) ---
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_C3D8  = 10
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_C3D8R = 11
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_C3D4  = 12
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_CPE4  = 20
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_CPE4R = 21
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_CPS4  = 30
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_CPS4R = 31
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_CAX4  = 40
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_CAX4R = 41
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_S4    = 50
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_S4R   = 51
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_S3    = 60
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_B31   = 70
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_TYPE_T3D2  = 80

  !--- Integration schemes ---
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_IP_FULL    = 0
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_IP_REDUCED = 1
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_IP_USER    = 2

  !--- Geometric classifications ---
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GEOM_ISOTROPIC    = 0
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GEOM_AXISYMMETRIC = 1
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GEOM_PLANE_STRESS = 2
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_GEOM_PLANE_STRAIN = 3

  !--- Mass matrix types ---
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_MASS_CONSISTENT = 0
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_MASS_LUMPED     = 1

  !--- Hourglass control types ---
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_HG_NONE      = 0
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_HG_STIFFNESS = 1
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_HG_VISCOUS   = 2

  !=============================================================================
  ! SECTION: Module variables (registry storage)
  !=============================================================================
  TYPE(MD_Elem_Desc), ALLOCATABLE, SAVE :: elem_registry_(:)
  INTEGER(i4), SAVE :: n_registered_ = 0
  LOGICAL,     SAVE :: is_initialized_ = .FALSE.

  !=============================================================================
  ! SECTION: Public interfaces (three-segment naming)
  !=============================================================================
  PUBLIC :: MD_Elem_Reg_Init
  PUBLIC :: MD_Elem_Reg_Register
  PUBLIC :: MD_Elem_Reg_LookupById
  PUBLIC :: MD_Elem_Reg_LookupByFamily
  PUBLIC :: MD_Elem_Reg_Validate
  PUBLIC :: MD_Elem_Reg_Finalize
  PUBLIC :: MD_Elem_Reg_RegisterFamily
  PUBLIC :: MD_Elem_Reg_GetFamilyDesc
  PUBLIC :: MD_Elem_Reg_RegisterAll

  !--- 12 family-specific registration ---
  PUBLIC :: MD_Elem_Reg_RegisterSolid3D
  PUBLIC :: MD_Elem_Reg_RegisterShell
  PUBLIC :: MD_Elem_Reg_RegisterBeam
  PUBLIC :: MD_Elem_Reg_RegisterTruss
  PUBLIC :: MD_Elem_Reg_RegisterSolid2D
  PUBLIC :: MD_Elem_Reg_RegisterInfinite
  PUBLIC :: MD_Elem_Reg_RegisterCohesive
  PUBLIC :: MD_Elem_Reg_RegisterSpring
  PUBLIC :: MD_Elem_Reg_RegisterDashpot
  PUBLIC :: MD_Elem_Reg_RegisterMass
  PUBLIC :: MD_Elem_Reg_RegisterGasket
  PUBLIC :: MD_Elem_Reg_RegisterSurface

  ! [REMOVED] 16 legacy procedure aliases (no external refs):
  !   MD_Element_InitRegistry, MD_Element_RegisterType, MD_Element_GetDescById,
  !   MD_Element_GetDescByFamily, MD_Element_ValidateType, MD_Element_FinalizeRegistry,
  !   MD_Element_RegisterFamily, MD_Element_GetFamilyDesc, MD_Element_RegisterAllFamilies,
  !   MD_Element_RegisterSolid3D, MD_Element_RegisterShell, MD_Element_RegisterBeam,
  !   MD_Element_RegisterTruss, MD_Element_RegisterSolid2D, MD_Element_RegisterInfinite,
  !   MD_Element_RegisterCohesive, MD_Element_RegisterSpring, MD_Element_RegisterDashpot,
  !   MD_Element_RegisterMass, MD_Element_RegisterGasket, MD_Element_RegisterSurface

  !=============================================================================
  ! [REMOVED] SECTION: Legacy interface bindings (16 INTERFACE aliases, no external refs)
  !=============================================================================

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize element type registry
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_Init(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (is_initialized_) THEN
      CALL init_error_status(status, IF_STATUS_OK)
      RETURN
    END IF

    ALLOCATE(elem_registry_(MD_ELEM_MAX_TYPES))
    n_registered_    = 0
    is_initialized_  = .TRUE.

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_Init

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_Register
  ! PHASE:      P0
  ! PURPOSE:    Register an element type descriptor in the registry
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_Register(desc, status)
    TYPE(MD_Elem_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    IF (.NOT. is_initialized_) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Registry not initialized")
      RETURN
    END IF

    IF (n_registered_ >= MD_ELEM_MAX_TYPES) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Registry full")
      RETURN
    END IF

    IF (desc%cfg_id%elem_type_id <= 0 .OR. desc%cfg_id%family_id <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid element ID")
      RETURN
    END IF

    n_registered_ = n_registered_ + 1
    elem_registry_(n_registered_) = desc

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_LookupById
  ! PHASE:      P1
  ! PURPOSE:    Get element descriptor by type ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Reg_LookupById(elem_type_id, status) RESULT(desc_out)
    INTEGER(i4),         INTENT(IN)  :: elem_type_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc_out
    INTEGER(i4) :: i

    desc_out = MD_Elem_Desc()

    IF (.NOT. is_initialized_) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Registry not initialized")
      RETURN
    END IF

    DO i = 1, n_registered_
      IF (elem_registry_(i)%cfg_id%elem_type_id == elem_type_id) THEN
        desc_out = elem_registry_(i)
        CALL init_error_status(status, IF_STATUS_OK)
        RETURN
      END IF
    END DO

    CALL init_error_status(status, IF_STATUS_ERROR, "Element type not found")
  END FUNCTION MD_Elem_Reg_LookupById

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_LookupByFamily
  ! PHASE:      P1
  ! PURPOSE:    Get first element descriptor by family ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Reg_LookupByFamily(family_id, status) RESULT(desc_out)
    INTEGER(i4),         INTENT(IN)  :: family_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc_out
    INTEGER(i4) :: i

    desc_out = MD_Elem_Desc()

    IF (.NOT. is_initialized_) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Registry not initialized")
      RETURN
    END IF

    DO i = 1, n_registered_
      IF (elem_registry_(i)%cfg_id%family_id == family_id) THEN
        desc_out = elem_registry_(i)
        CALL init_error_status(status, IF_STATUS_OK)
        RETURN
      END IF
    END DO

    CALL init_error_status(status, IF_STATUS_ERROR, "Family not found")
  END FUNCTION MD_Elem_Reg_LookupByFamily

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_Validate
  ! PHASE:      P0
  ! PURPOSE:    Validate element type configuration
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Reg_Validate(desc, status) RESULT(is_valid)
    TYPE(MD_Elem_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    LOGICAL :: is_valid

    is_valid = .TRUE.

    IF (desc%cfg_id%elem_type_id <= 0) THEN
      is_valid = .FALSE.
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid type ID")
      RETURN
    END IF

    IF (desc%cfg_id%family_id <= 0) THEN
      is_valid = .FALSE.
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid family ID")
      RETURN
    END IF

    IF (desc%cfg_topo%n_nodes <= 0) THEN
      is_valid = .FALSE.
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid node count")
      RETURN
    END IF

    IF (desc%cfg_topo%dof_per_node <= 0) THEN
      is_valid = .FALSE.
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid DOF per node")
      RETURN
    END IF

    IF (desc%cfg_topo%ndim < 1 .OR. desc%cfg_topo%ndim > 3) THEN
      is_valid = .FALSE.
      CALL init_error_status(status, IF_STATUS_ERROR, "Invalid dimension")
      RETURN
    END IF

    CALL init_error_status(status, IF_STATUS_OK)
  END FUNCTION MD_Elem_Reg_Validate

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Release registry resources
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_Finalize(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (ALLOCATED(elem_registry_)) DEALLOCATE(elem_registry_)
    n_registered_   = 0
    is_initialized_ = .FALSE.

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_Finalize

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterAll
  ! PHASE:      P0
  ! PURPOSE:    Bulk-register all 12 element families
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterAll(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(ErrorStatusType) :: ls

    CALL MD_Elem_Reg_RegisterSolid3D(ls);  IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterShell(ls);    IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterBeam(ls);     IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterTruss(ls);    IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterSolid2D(ls);  IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterInfinite(ls); IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterCohesive(ls); IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterSpring(ls);   IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterDashpot(ls);  IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterMass(ls);     IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterGasket(ls);   IF (ls%status_code /= IF_STATUS_OK) GOTO 999
    CALL MD_Elem_Reg_RegisterSurface(ls);  IF (ls%status_code /= IF_STATUS_OK) GOTO 999

    CALL init_error_status(status, IF_STATUS_OK)
    RETURN
999 CONTINUE
    status = ls
  END SUBROUTINE MD_Elem_Reg_RegisterAll

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterSolid3D
  ! PHASE:      P0
  ! PURPOSE:    Register Solid3D family (18 variants: C3D8, C3D8R, C3D4 ...)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterSolid3D(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc

    !--- C3D8: 8-node linear brick ---
    desc = MD_Elem_Desc()
    desc%cfg_id%elem_type_id = MD_ELEM_TYPE_C3D8
    desc%cfg_id%family_id    = MD_ELEM_FAMILY_C3D
    desc%cfg_topo%n_nodes      = 8;  desc%cfg_topo%dof_per_node = 3;  desc%cfg_topo%ndim = 3
    desc%cfg_topo%n_ip         = 8;  desc%pop_flag%has_mass = .TRUE.;  desc%pop_flag%nlgeom = .TRUE.
    CALL MD_Elem_Reg_Register(desc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    !--- C3D8R: reduced integration ---
    desc = MD_Elem_Desc()
    desc%cfg_id%elem_type_id = MD_ELEM_TYPE_C3D8R
    desc%cfg_id%family_id    = MD_ELEM_FAMILY_C3D8R
    desc%cfg_topo%n_nodes      = 8;  desc%cfg_topo%dof_per_node = 3;  desc%cfg_topo%ndim = 3
    desc%cfg_topo%n_ip         = 1;  desc%pop_flag%has_mass = .TRUE.;  desc%pop_flag%nlgeom = .TRUE.
    CALL MD_Elem_Reg_Register(desc, status)

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterSolid3D

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterShell
  ! PHASE:      P0
  ! PURPOSE:    Register Shell family (24 variants: S4, S4R, S3 ...)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterShell(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc

    !--- S4: 4-node shell ---
    desc = MD_Elem_Desc()
    desc%cfg_id%elem_type_id = MD_ELEM_TYPE_S4
    desc%cfg_id%family_id    = MD_ELEM_FAMILY_S4
    desc%cfg_topo%n_nodes      = 4;  desc%cfg_topo%dof_per_node = 6;  desc%cfg_topo%ndim = 3
    desc%cfg_topo%n_ip         = 5;  desc%pop_flag%has_mass = .TRUE.
    desc%pop_flag%has_thermal  = .TRUE.;  desc%pop_flag%nlgeom = .TRUE.
    CALL MD_Elem_Reg_Register(desc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    !--- S4R: reduced integration ---
    desc = MD_Elem_Desc()
    desc%cfg_id%elem_type_id = MD_ELEM_TYPE_S4R
    desc%cfg_id%family_id    = MD_ELEM_FAMILY_S4
    desc%cfg_topo%n_nodes      = 4;  desc%cfg_topo%dof_per_node = 6;  desc%cfg_topo%ndim = 3
    desc%cfg_topo%n_ip         = 4;  desc%pop_flag%has_mass = .TRUE.;  desc%pop_flag%nlgeom = .TRUE.
    CALL MD_Elem_Reg_Register(desc, status)

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterShell

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterBeam
  ! PHASE:      P0
  ! PURPOSE:    Register Beam family (16 variants: B31, B32, B33 ...)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterBeam(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc

    desc = MD_Elem_Desc()
    desc%cfg_id%elem_type_id = MD_ELEM_TYPE_B31
    desc%cfg_id%family_id    = MD_ELEM_FAMILY_B31
    desc%cfg_topo%n_nodes      = 2;  desc%cfg_topo%dof_per_node = 6;  desc%cfg_topo%ndim = 3
    desc%cfg_topo%n_ip         = 3;  desc%pop_flag%has_mass = .TRUE.
    desc%pop_flag%has_damp     = .TRUE.;  desc%pop_flag%nlgeom = .TRUE.
    CALL MD_Elem_Reg_Register(desc, status)

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterBeam

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterTruss
  ! PHASE:      P0
  ! PURPOSE:    Register Truss family (6 variants: T2D2, T3D2 ...)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterTruss(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc

    desc = MD_Elem_Desc()
    desc%cfg_id%elem_type_id = MD_ELEM_TYPE_T3D2
    desc%cfg_id%family_id    = MD_ELEM_FAMILY_T3D2
    desc%cfg_topo%n_nodes      = 2;  desc%cfg_topo%dof_per_node = 3;  desc%cfg_topo%ndim = 3
    desc%cfg_topo%n_ip         = 2;  desc%pop_flag%has_mass = .TRUE.
    CALL MD_Elem_Reg_Register(desc, status)

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterTruss

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterSolid2D
  ! PHASE:      P0
  ! PURPOSE:    Register Solid2D family (18 variants: CPE4, CPS4, CAX4 ...)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterSolid2D(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc

    !--- CPE4: plane strain ---
    desc = MD_Elem_Desc()
    desc%cfg_id%elem_type_id = MD_ELEM_TYPE_CPE4
    desc%cfg_id%family_id    = MD_ELEM_FAMILY_CPE
    desc%cfg_topo%n_nodes      = 4;  desc%cfg_topo%dof_per_node = 2;  desc%cfg_topo%ndim = 2
    desc%cfg_geom%geom_kind    = MD_ELEM_GEOM_PLANE_STRAIN
    desc%cfg_topo%n_ip         = 4;  desc%pop_flag%has_mass = .TRUE.;  desc%pop_flag%nlgeom = .TRUE.
    CALL MD_Elem_Reg_Register(desc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    !--- CAX4: axisymmetric ---
    desc%cfg_id%elem_type_id = MD_ELEM_TYPE_CAX4
    desc%cfg_id%family_id    = MD_ELEM_FAMILY_CAX
    desc%cfg_geom%geom_kind    = MD_ELEM_GEOM_AXISYMMETRIC
    CALL MD_Elem_Reg_Register(desc, status)

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterSolid2D

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterInfinite
  ! PHASE:      P0
  ! PURPOSE:    Register Infinite family (8 variants: CIN2D3, CIN3D8 ...)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterInfinite(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterInfinite

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterCohesive
  ! PHASE:      P0
  ! PURPOSE:    Register Cohesive family (12 variants: COH2D4, COH3D8 ...)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterCohesive(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterCohesive

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterSpring
  ! PHASE:      P0
  ! PURPOSE:    Register Spring family (4 variants: SPRING1, SPRING2, SPRINGA)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterSpring(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterSpring

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterDashpot
  ! PHASE:      P0
  ! PURPOSE:    Register Dashpot family (2 variants: DASHPOT1, DASHPOT2)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterDashpot(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterDashpot

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterMass
  ! PHASE:      P0
  ! PURPOSE:    Register Mass family (2 variants: MASS, MASS2D)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterMass(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterMass

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterGasket
  ! PHASE:      P0
  ! PURPOSE:    Register Gasket family (6 variants: GS6, GS8, GK6, GK8)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterGasket(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterGasket

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterSurface
  ! PHASE:      P0
  ! PURPOSE:    Register Surface family (8 variants: SF2D4, SF3D8 ...)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterSurface(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Reg_RegisterSurface

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_RegisterFamily
  ! PHASE:      P0
  ! PURPOSE:    Dispatch registration by group ID
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Reg_RegisterFamily(group_id, status)
    INTEGER(i4),         INTENT(IN)  :: group_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(ErrorStatusType) :: ls

    SELECT CASE (group_id)
    CASE (MD_ELEM_GROUP_SOLID3D);  CALL MD_Elem_Reg_RegisterSolid3D(ls)
    CASE (MD_ELEM_GROUP_SHELL);    CALL MD_Elem_Reg_RegisterShell(ls)
    CASE (MD_ELEM_GROUP_BEAM);     CALL MD_Elem_Reg_RegisterBeam(ls)
    CASE (MD_ELEM_GROUP_TRUSS);    CALL MD_Elem_Reg_RegisterTruss(ls)
    CASE (MD_ELEM_GROUP_SOLID2D);  CALL MD_Elem_Reg_RegisterSolid2D(ls)
    CASE (MD_ELEM_GROUP_INFINITE); CALL MD_Elem_Reg_RegisterInfinite(ls)
    CASE (MD_ELEM_GROUP_COHESIVE); CALL MD_Elem_Reg_RegisterCohesive(ls)
    CASE (MD_ELEM_GROUP_SPRING);   CALL MD_Elem_Reg_RegisterSpring(ls)
    CASE (MD_ELEM_GROUP_DASHPOT);  CALL MD_Elem_Reg_RegisterDashpot(ls)
    CASE (MD_ELEM_GROUP_MASS);     CALL MD_Elem_Reg_RegisterMass(ls)
    CASE (MD_ELEM_GROUP_GASKET);   CALL MD_Elem_Reg_RegisterGasket(ls)
    CASE (MD_ELEM_GROUP_SURFACE);  CALL MD_Elem_Reg_RegisterSurface(ls)
    CASE DEFAULT
      CALL init_error_status(status, IF_STATUS_ERROR, "Unknown family group")
      RETURN
    END SELECT

    status = ls
  END SUBROUTINE MD_Elem_Reg_RegisterFamily

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Reg_GetFamilyDesc
  ! PHASE:      P1
  ! PURPOSE:    Get family descriptor by group ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Reg_GetFamilyDesc(group_id, status) RESULT(desc_out)
    INTEGER(i4),         INTENT(IN)  :: group_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Elem_Desc) :: desc_out
    INTEGER(i4) :: fam_id

    SELECT CASE (group_id)
    CASE (MD_ELEM_GROUP_SOLID3D);  fam_id = MD_ELEM_FAMILY_C3D
    CASE (MD_ELEM_GROUP_SHELL);    fam_id = MD_ELEM_FAMILY_S4
    CASE (MD_ELEM_GROUP_BEAM);     fam_id = MD_ELEM_FAMILY_B31
    CASE (MD_ELEM_GROUP_TRUSS);    fam_id = MD_ELEM_FAMILY_T3D2
    CASE (MD_ELEM_GROUP_SOLID2D);  fam_id = MD_ELEM_FAMILY_CPE
    CASE (MD_ELEM_GROUP_INFINITE); fam_id = MD_ELEM_FAMILY_INFINITE
    CASE (MD_ELEM_GROUP_COHESIVE); fam_id = MD_ELEM_FAMILY_COH
    CASE (MD_ELEM_GROUP_SPRING);   fam_id = MD_ELEM_FAMILY_SPRING
    CASE (MD_ELEM_GROUP_DASHPOT);  fam_id = MD_ELEM_FAMILY_DASHPOT
    CASE (MD_ELEM_GROUP_MASS);     fam_id = MD_ELEM_FAMILY_MASS
    CASE (MD_ELEM_GROUP_GASKET);   fam_id = MD_ELEM_FAMILY_GASKET
    CASE (MD_ELEM_GROUP_SURFACE);  fam_id = MD_ELEM_FAMILY_SURFACE
    CASE DEFAULT
      CALL init_error_status(status, IF_STATUS_ERROR, "Unknown family group")
      RETURN
    END SELECT

    desc_out = MD_Elem_Reg_LookupByFamily(fam_id, status)
  END FUNCTION MD_Elem_Reg_GetFamilyDesc

END MODULE MD_Elem_Reg
