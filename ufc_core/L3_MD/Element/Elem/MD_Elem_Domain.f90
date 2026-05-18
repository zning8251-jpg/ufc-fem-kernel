!===============================================================================
! MODULE: MD_Elem_Domain
! LAYER:  L3_MD
! DOMAIN: Element
! ROLE:   Domain (container)
! BRIEF:  Element domain container — four-class TYPE aggregate with Init/Register/Finalize
! **W2**：域 **`MD_Elem_Domain_Algo`** 嵌套 **desc/state/algo/ctx**；下行 L4 **`PH_Elem*`** /
!         L5 **`RT_Elem*`**，拓扑与类型 ID 勿落第二套旁路。
!===============================================================================
MODULE MD_Elem_Domain
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Elem_Def,  ONLY: MD_Elem_Desc, MD_Elem_State, &
                           MD_Elem_Algo, MD_Elem_Ctx

  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Domain_Algo
  ! KIND: Algo
  ! DESC: Domain container with four-class TYPE nested indexing
  !       Cross-layer: MD_Elem_Domain_Algo → PH_ElemDomain_Algo → RT_ElemProc
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Domain_Algo
    !--- Four-class TYPE nested structure ---
    TYPE(MD_Elem_Desc)  :: desc           ! [1] Cold path — registry data
    TYPE(MD_Elem_State) :: state          ! [2] Hot path  — model aggregations
    TYPE(MD_Elem_Algo)   :: algo           ! [3] Step cfg  — algorithm params
    TYPE(MD_Elem_Ctx)   :: ctx            ! [4] Hot path  — model metadata
    !--- Domain metadata ---
    INTEGER(i4) :: domain_id      = 0_i4      ! Domain identifier
    INTEGER(i4) :: n_elements     = 0_i4      ! Element count in domain
    LOGICAL     :: is_initialized = .FALSE.    ! Initialization flag
  END TYPE MD_Elem_Domain_Algo

  !=============================================================================
  ! SECTION: Public interfaces (three-segment naming)
  !=============================================================================
  PUBLIC :: MD_Elem_Domain_Init
  PUBLIC :: MD_Elem_Domain_Register
  PUBLIC :: MD_Elem_Domain_GetDesc
  PUBLIC :: MD_Elem_Domain_Finalize


CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Domain_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize element domain from registry
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Domain_Init(domain, elem_type_id, family_id, status)
    TYPE(MD_Elem_Domain_Algo), INTENT(INOUT) :: domain
    INTEGER(i4),               INTENT(IN)    :: elem_type_id
    INTEGER(i4),               INTENT(IN)    :: family_id
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    ! Initialize Desc from registry (cold path)
    domain%desc%cfg_id%elem_type_id = elem_type_id
    domain%desc%cfg_id%family_id    = family_id

    ! Default topology (overridden by Register)
    domain%desc%cfg_topo%n_nodes      = 0_i4
    domain%desc%cfg_topo%dof_per_node = 0_i4
    domain%desc%cfg_topo%ndim         = 0_i4
    domain%desc%cfg_topo%n_dof        = 0_i4

    ! Default algorithm params
    domain%algo%stp%ip_scheme    = 0_i4
    domain%algo%dyn%mass_type    = 0_i4

    ! Metadata
    domain%domain_id         = elem_type_id
    domain%is_initialized    = .TRUE.

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Domain_Init

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Domain_Register
  ! PHASE:      P1
  ! PURPOSE:    Populate domain from registry entry table
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Domain_Register(domain, registry_entry, status)
    TYPE(MD_Elem_Domain_Algo), INTENT(INOUT) :: domain
    INTEGER(i4),               INTENT(IN)    :: registry_entry(:)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    IF (.NOT. domain%is_initialized) THEN
      CALL init_error_status(status, IF_STATUS_OK)
      RETURN
    END IF

    IF (SIZE(registry_entry) >= 12) THEN
      domain%desc%cfg_topo%n_nodes      = registry_entry(1)
      domain%desc%cfg_topo%dof_per_node = registry_entry(2)
      domain%desc%cfg_topo%ndim         = registry_entry(3)
      domain%desc%cfg_topo%n_ip         = registry_entry(4)
      domain%desc%cfg_geom%geom_kind    = registry_entry(5)
      domain%desc%pop_flag%has_mass     = (registry_entry(6) /= 0)
      domain%desc%pop_flag%has_damp     = (registry_entry(7) /= 0)
      domain%desc%pop_flag%has_thermal  = (registry_entry(8) /= 0)
      domain%desc%pop_flag%has_porous   = (registry_entry(9) /= 0)
      domain%desc%pop_flag%nlgeom       = (registry_entry(10) /= 0)
      domain%desc%cfg_topo%n_dof        = domain%desc%cfg_topo%n_nodes * domain%desc%cfg_topo%dof_per_node
      domain%algo%stp%ip_scheme         = registry_entry(11)
      domain%algo%dyn%mass_type         = registry_entry(12)
    END IF

    domain%n_elements = 1
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Domain_Register

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Domain_GetDesc
  ! PHASE:      P1
  ! PURPOSE:    Get descriptor for cross-layer binding
  !---------------------------------------------------------------------------
  FUNCTION MD_Elem_Domain_GetDesc(domain) RESULT(desc_out)
    TYPE(MD_Elem_Domain_Algo), INTENT(IN) :: domain
    TYPE(MD_Elem_Desc) :: desc_out

    desc_out = domain%desc
  END FUNCTION MD_Elem_Domain_GetDesc

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Elem_Domain_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Release domain resources
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Elem_Domain_Finalize(domain, status)
    TYPE(MD_Elem_Domain_Algo), INTENT(INOUT) :: domain
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    domain%domain_id              = 0_i4
    domain%n_elements             = 0_i4
    domain%is_initialized         = .FALSE.
    domain%desc%cfg_id%elem_type_id  = 0_i4
    domain%desc%cfg_id%family_id     = 0_i4

    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Elem_Domain_Finalize

END MODULE MD_Elem_Domain
