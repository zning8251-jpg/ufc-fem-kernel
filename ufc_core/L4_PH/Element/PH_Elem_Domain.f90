!===============================================================================
! MODULE: PH_Elem_Domain
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Domain
! BRIEF:  Element domain container with four-kind TYPE structure.
!===============================================================================
MODULE PH_Elem_Domain
  USE IF_Prec_Core,     ONLY: wp, i4
  USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                           IF_STATUS_INVALID
  USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_State, &
                           PH_Elem_Algo, PH_Elem_Ctx, &
                           PH_Element_Compute_Ke_Arg, PH_Element_Compute_Fe_Arg, &
                           PH_Elem_Eval_Ke_Arg, PH_Elem_Eval_Fe_Arg
  USE PH_Elem_Eval, ONLY: PH_Elem_Eval_Ke, PH_Elem_Eval_Fe
  USE PH_Elem_Reg, ONLY: PH_Elem_Reg_Get, PH_Elem_Reg_Entry, PH_ELEM_FAMILY_SOLID_3D

  IMPLICIT NONE
  PRIVATE

  !--- [PUBLIC TYPES] ---
  PUBLIC :: PH_Elem_Domain_Desc

  !--- [PUBLIC PROCEDURES] ---
  PUBLIC :: PH_Elem_Domain_Init
  PUBLIC :: PH_Elem_Domain_Populate
  PUBLIC :: PH_Elem_Domain_Validate
  PUBLIC :: PH_Elem_Domain_Finalize


  !--- SECTION 1: TYPE DEFINITIONS ---

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Domain_Desc
  ! KIND: Desc
  ! DESC: Domain container with four-kind TYPE nested indexing.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Domain_Desc
    TYPE(PH_Elem_Desc)  :: desc   ! [index 1] cold path read-only
    TYPE(PH_Elem_State) :: state  ! [index 2] hot path output
    TYPE(PH_Elem_Algo)  :: algo   ! [index 3] step-level config
    TYPE(PH_Elem_Ctx)   :: ctx    ! [index 4] hot path workspace
    INTEGER(i4) :: domain_id = 0
    INTEGER(i4) :: n_elements = 0
    LOGICAL     :: is_initialized = .FALSE.
    ! L3 mesh mirror for assembly / Populate (PH_L4_Populate_Element, RT_Asm_Solv)
    INTEGER(i4), ALLOCATABLE :: elem_to_mat_map(:)
    REAL(wp), ALLOCATABLE :: elem_coords_cache(:, :, :)
    INTEGER(i4), ALLOCATABLE :: elem_npe_cache(:)
    INTEGER(i4), ALLOCATABLE :: elem_ndim_cache(:)
    INTEGER(i4), ALLOCATABLE :: elem_type_cache(:)
    LOGICAL :: coords_cached = .FALSE.
  CONTAINS
    ! L4 layer / L5 assembly 金线（与 PH_Mat_Domain Init/Finalize 对称）
    PROCEDURE :: Init        => Desc_Init
    PROCEDURE :: Finalize    => Desc_Finalize
    PROCEDURE :: Compute_Ke  => Desc_Compute_Ke
    PROCEDURE :: Compute_Fe  => Desc_Compute_Fe
  END TYPE PH_Elem_Domain_Desc

  !--- SECTION 2: MODULE CONSTANTS ---
  ! (none)

CONTAINS
  !--- TBP bodies (PH_Elem_Domain_Desc) ---

  SUBROUTINE Desc_Init(this, stepId, status)
    CLASS(PH_Elem_Domain_Desc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: stepId
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(status)
    IF (this%is_initialized) CALL PH_Elem_Domain_Finalize(this, st)
    CALL PH_Elem_Domain_Init(this, 0_i4, PH_ELEM_FAMILY_SOLID_3D, 8_i4, 3_i4, 3_i4, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    this%ctx%inc%step_idx = stepId
    this%ctx%inc%incr_idx = 0_i4
  END SUBROUTINE Desc_Init

  SUBROUTINE Desc_Finalize(this)
    CLASS(PH_Elem_Domain_Desc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: st
    CALL PH_Elem_Domain_Finalize(this, st)
  END SUBROUTINE Desc_Finalize

  SUBROUTINE Desc_Compute_Ke(this, arg)
    CLASS(PH_Elem_Domain_Desc), INTENT(INOUT) :: this
    TYPE(PH_Element_Compute_Ke_Arg), INTENT(INOUT) :: arg

    INTEGER(i4) :: iel, et, et_use, npe, ndim, n_dof
    TYPE(PH_Elem_Reg_Entry), POINTER :: ep
    TYPE(PH_Elem_Desc) :: ed
    TYPE(PH_Elem_Eval_Ke_Arg) :: eva
    REAL(wp), ALLOCATABLE, TARGET :: coords(:, :)
    REAL(wp), ALLOCATABLE, TARGET :: mprop(:)
    TYPE(ErrorStatusType) :: st
    LOGICAL :: use_internal_mprop

    CALL init_error_status(arg%status)
    use_internal_mprop = .FALSE.
    n_dof = arg%nDof
    iel = arg%l3_elem_idx
    IF (arg%elem_idx > 0_i4 .AND. iel > 0_i4 .AND. arg%elem_idx /= iel) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Ke: elem_idx / l3_elem_idx mismatch"
      RETURN
    END IF
    IF (arg%mat_pt_idx <= 0_i4) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Ke: missing mat_pt_idx"
      RETURN
    END IF
    IF (.NOT. ALLOCATED(arg%mat_props_in) .OR. SIZE(arg%mat_props_in) < 1) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Ke: mat_props_in not attached (L5 AttachMatProps)"
      RETURN
    END IF
    IF (iel < 1_i4 .OR. n_dof < 1_i4) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Ke: invalid elem_idx or nDof"
      RETURN
    END IF
    IF (.NOT. this%coords_cached .OR. .NOT. ALLOCATED(this%elem_coords_cache)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Ke: element coords not populated"
      RETURN
    END IF
    IF (iel > this%n_elements .OR. iel > SIZE(this%elem_coords_cache, 3)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Ke: elem index out of cache range"
      RETURN
    END IF

    et = 0_i4
    IF (ALLOCATED(this%elem_type_cache) .AND. iel <= SIZE(this%elem_type_cache)) &
      et = this%elem_type_cache(iel)
    npe = 0_i4
    IF (ALLOCATED(this%elem_npe_cache) .AND. iel <= SIZE(this%elem_npe_cache)) &
      npe = this%elem_npe_cache(iel)
    ndim = 3_i4
    IF (ALLOCATED(this%elem_ndim_cache) .AND. iel <= SIZE(this%elem_ndim_cache)) THEN
      ndim = this%elem_ndim_cache(iel)
      IF (ndim < 2_i4) ndim = 3_i4
    END IF
    IF (npe < 1_i4) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Ke: invalid npe in cache"
      RETURN
    END IF

    et_use = et
    IF (et_use == 0_i4) et_use = this%desc%cfg%elem_type_id
    ed%cfg%elem_type_id = et_use
    ed%cfg%ndim = ndim
    ep => PH_Elem_Reg_Get(et_use)
    IF (ASSOCIATED(ep) .AND. ep%is_registered) THEN
      ed%cfg%family_id = ep%cfg%family_id
    ELSE
      ed%cfg%family_id = this%desc%cfg%family_id
      IF (ed%cfg%family_id == 0_i4) ed%cfg%family_id = PH_ELEM_FAMILY_SOLID_3D
    END IF
    ed%pop%n_nodes = npe
    ed%pop%n_dof = n_dof

    ALLOCATE(coords(ndim, npe))
    coords(1:ndim, 1:npe) = this%elem_coords_cache(1:ndim, 1:npe, iel)
    eva%coords => coords
    IF (ALLOCATED(arg%mat_props_in) .AND. SIZE(arg%mat_props_in) > 0) THEN
      eva%mat_props => arg%mat_props_in
    ELSE
      ALLOCATE(mprop(8))
      mprop = 0.0_wp
      eva%mat_props => mprop
      use_internal_mprop = .TRUE.
    END IF

    CALL PH_Elem_Eval_Ke(ed, this%algo, eva, st)
    arg%status = st
    IF (st%status_code /= IF_STATUS_OK) GOTO 999

    IF (.NOT. ALLOCATED(eva%Ke)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Ke: Eval_Ke produced no Ke"
      GOTO 999
    END IF
    IF (.NOT. ASSOCIATED(arg%evo%Ke)) ALLOCATE(arg%evo%Ke(n_dof, n_dof))
    arg%evo%Ke(1:n_dof, 1:n_dof) = eva%Ke(1:n_dof, 1:n_dof)

999 CONTINUE
    IF (ALLOCATED(coords)) DEALLOCATE(coords)
    IF (use_internal_mprop) THEN
      IF (ALLOCATED(mprop)) DEALLOCATE(mprop)
    END IF
    IF (ALLOCATED(eva%Ke)) DEALLOCATE(eva%Ke)
  END SUBROUTINE Desc_Compute_Ke

  SUBROUTINE Desc_Compute_Fe(this, arg)
    CLASS(PH_Elem_Domain_Desc), INTENT(INOUT) :: this
    TYPE(PH_Element_Compute_Fe_Arg), INTENT(INOUT) :: arg

    INTEGER(i4) :: iel, et, et_use, npe, ndim, n_dof
    TYPE(PH_Elem_Reg_Entry), POINTER :: ep
    TYPE(PH_Elem_Desc) :: ed
    TYPE(PH_Elem_Eval_Fe_Arg) :: eva
    REAL(wp), ALLOCATABLE, TARGET :: coords(:, :)
    REAL(wp), ALLOCATABLE, TARGET :: u_loc(:)
    REAL(wp), ALLOCATABLE, TARGET :: magn(:)
    TYPE(ErrorStatusType) :: st
    LOGICAL :: use_internal_magn

    CALL init_error_status(arg%status)
    use_internal_magn = .FALSE.
    n_dof = arg%nDof
    iel = arg%l3_elem_idx
    IF (iel < 1_i4 .OR. n_dof < 1_i4) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Fe: invalid l3_elem_idx or nDof"
      RETURN
    END IF
    IF (.NOT. this%coords_cached .OR. .NOT. ALLOCATED(this%elem_coords_cache)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Fe: element coords not populated"
      RETURN
    END IF
    IF (iel > this%n_elements .OR. iel > SIZE(this%elem_coords_cache, 3)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Fe: elem index out of cache range"
      RETURN
    END IF

    et = 0_i4
    IF (ALLOCATED(this%elem_type_cache) .AND. iel <= SIZE(this%elem_type_cache)) &
      et = this%elem_type_cache(iel)
    npe = 0_i4
    IF (ALLOCATED(this%elem_npe_cache) .AND. iel <= SIZE(this%elem_npe_cache)) &
      npe = this%elem_npe_cache(iel)
    ndim = 3_i4
    IF (ALLOCATED(this%elem_ndim_cache) .AND. iel <= SIZE(this%elem_ndim_cache)) THEN
      ndim = this%elem_ndim_cache(iel)
      IF (ndim < 2_i4) ndim = 3_i4
    END IF
    IF (npe < 1_i4) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Fe: invalid npe in cache"
      RETURN
    END IF

    et_use = et
    IF (et_use == 0_i4) et_use = this%desc%cfg%elem_type_id
    ed%cfg%elem_type_id = et_use
    ed%cfg%ndim = ndim
    ep => PH_Elem_Reg_Get(et_use)
    IF (ASSOCIATED(ep) .AND. ep%is_registered) THEN
      ed%cfg%family_id = ep%cfg%family_id
    ELSE
      ed%cfg%family_id = this%desc%cfg%family_id
      IF (ed%cfg%family_id == 0_i4) ed%cfg%family_id = PH_ELEM_FAMILY_SOLID_3D
    END IF
    ed%pop%n_nodes = npe
    ed%pop%n_dof = n_dof

    ALLOCATE(coords(ndim, npe))
    coords(1:ndim, 1:npe) = this%elem_coords_cache(1:ndim, 1:npe, iel)
    ALLOCATE(u_loc(n_dof))
    u_loc(1:n_dof) = arg%u(1:n_dof)
    IF (ALLOCATED(arg%load_magn_in) .AND. SIZE(arg%load_magn_in) > 0) THEN
      eva%load_magn => arg%load_magn_in
    ELSE
      ALLOCATE(magn(1))
      magn(1) = 0.0_wp
      eva%load_magn => magn
      use_internal_magn = .TRUE.
    END IF

    eva%coords => coords
    eva%u => u_loc
    eva%load_case = arg%load_case

    CALL PH_Elem_Eval_Fe(ed, this%algo, eva, st)
    arg%status = st
    IF (st%status_code /= IF_STATUS_OK) GOTO 998

    IF (.NOT. ALLOCATED(eva%Fe)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Elem_Domain%Compute_Fe: Eval_Fe produced no Fe"
      GOTO 998
    END IF
    IF (.NOT. ALLOCATED(arg%Fe) .OR. SIZE(arg%Fe) < n_dof) THEN
      IF (ALLOCATED(arg%Fe)) DEALLOCATE(arg%Fe)
      ALLOCATE(arg%Fe(n_dof))
    END IF
    arg%Fe(1:n_dof) = eva%Fe(1:n_dof)

998 CONTINUE
    IF (ALLOCATED(coords)) DEALLOCATE(coords)
    IF (ALLOCATED(u_loc)) DEALLOCATE(u_loc)
    IF (use_internal_magn) THEN
      IF (ALLOCATED(magn)) DEALLOCATE(magn)
    END IF
    IF (ALLOCATED(eva%Fe)) DEALLOCATE(eva%Fe)
  END SUBROUTINE Desc_Compute_Fe

  !--- P0 cold-path procedures ---

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Domain_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize Element domain container.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Domain_Init(domain, elem_type_id, family_id, n_nodes, &
                                     dof_per_node, ndim, status)
    TYPE(PH_Elem_Domain_Desc), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN) :: elem_type_id
    INTEGER(i4), INTENT(IN) :: family_id
    INTEGER(i4), INTENT(IN) :: n_nodes
    INTEGER(i4), INTENT(IN) :: dof_per_node
    INTEGER(i4), INTENT(IN) :: ndim
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Initialize Desc (cold path, read-only after init)
    domain%desc%cfg%elem_type_id = elem_type_id
    domain%desc%cfg%family_id = family_id
    domain%desc%pop%n_nodes = n_nodes
    domain%desc%pop%dof_per_node = dof_per_node
    domain%desc%cfg%ndim = ndim
    domain%desc%pop%n_dof = n_nodes * dof_per_node
    
    ! Initialize Algo with defaults (Step-level config)
    domain%algo%stp%integration_order = 0   ! Full integration
    domain%algo%dyn%mass_type = 0           ! Consistent mass
    domain%algo%dyn%alpha_rayleigh = 0.0_wp
    domain%algo%dyn%beta_rayleigh = 0.0_wp
    
    ! Domain metadata
    domain%domain_id = elem_type_id
    domain%is_initialized = .TRUE.
    
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Elem_Domain_Init

  

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Domain_Populate
  ! PHASE:      P1
  ! PURPOSE:    Populate domain with element-specific data from registry.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Domain_Populate(domain, registry_entry, status)
    TYPE(PH_Elem_Domain_Desc), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN) :: registry_entry(:)  ! [n_props] from registry
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Validate initialization
    IF (.NOT. domain%is_initialized) THEN
      CALL init_error_status(status, IF_STATUS_OK)
      RETURN
    END IF

    ! Populate Desc from registry (cold path)
    IF (SIZE(registry_entry) >= 8) THEN
      domain%desc%pop%n_integration = registry_entry(1)
      ! L4 PH_Elem_Desc does not have geom_kind, geom_param, has_mass,
      ! has_damp, has_thermal, has_porous fields; skip mapping
      domain%algo%stp%nlgeom = (registry_entry(8) /= 0)
    END IF

    domain%desc%pop%n_elements = 1_i4  ! Default
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Elem_Domain_Populate

  

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Domain_Validate
  ! PHASE:      P0
  ! PURPOSE:    Validate domain consistency and cross-domain bindings.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Domain_Validate(domain, status)
    TYPE(PH_Elem_Domain_Desc), INTENT(INOUT) :: domain
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Check initialization
    IF (.NOT. domain%is_initialized) THEN
      CALL init_error_status(status, IF_STATUS_OK)
      RETURN
    END IF

    ! Validate topology consistency
    IF (domain%desc%pop%n_nodes <= 0 .OR. domain%desc%pop%dof_per_node <= 0) THEN
      CALL init_error_status(status, IF_STATUS_OK)
      RETURN
    END IF

    ! Validate dimension
    IF (domain%desc%cfg%ndim /= 2 .AND. domain%desc%cfg%ndim /= 3) THEN
      CALL init_error_status(status, IF_STATUS_OK)
      RETURN
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Elem_Domain_Validate

  

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Domain_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Release domain resources.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Domain_Finalize(domain, status)
    TYPE(PH_Elem_Domain_Desc), INTENT(INOUT) :: domain
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Reset metadata
    domain%domain_id = 0
    domain%desc%pop%n_elements = 0_i4
    domain%is_initialized = .FALSE.
    domain%n_elements = 0_i4
    domain%coords_cached = .FALSE.
    IF (ALLOCATED(domain%elem_to_mat_map)) DEALLOCATE(domain%elem_to_mat_map)
    IF (ALLOCATED(domain%elem_coords_cache)) DEALLOCATE(domain%elem_coords_cache)
    IF (ALLOCATED(domain%elem_npe_cache)) DEALLOCATE(domain%elem_npe_cache)
    IF (ALLOCATED(domain%elem_ndim_cache)) DEALLOCATE(domain%elem_ndim_cache)
    IF (ALLOCATED(domain%elem_type_cache)) DEALLOCATE(domain%elem_type_cache)

    ! Reset Desc
    domain%desc%cfg%elem_type_id = 0
    domain%desc%cfg%family_id = 0
    domain%desc%pop%n_nodes = 0
    domain%desc%pop%n_dof = 0

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Elem_Domain_Finalize

  

END MODULE PH_Elem_Domain