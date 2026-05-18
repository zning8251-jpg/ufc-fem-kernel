!===============================================================================
! MODULE: PH_Mat_Elas_Def
! LAYER:  L4_PH
! DOMAIN: Material / Elas
! ROLE:   Def
! BRIEF:  TYPE definitions for elastic material family at L4_PH layer.
!         Implements binary structure: 4-type (Desc/State/Algo/Ctx) + Args.
!         Auxiliary types nested under primary TYPEs.
!         SIO: unified *_Arg bundles with [IN]/[OUT] comments.
!
!         Cross-layer data flow:
!         L3_MD(MD_Mat_Elas_Desc) --[Populate]--> L4_PH(PH_Mat_Elas_Desc)
!         L4_PH(PH_Mat_Elas_Eval) --[Brg]-------> L5_RT(RT_Mat_Elas_Dispatch)
!===============================================================================
MODULE PH_Mat_Elas_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Elastic sub-type constants (aligned with L3_MD)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_ISO        = 101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_ORTHO      = 102_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_TRANSISO   = 103_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_ANISO      = 104_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_POROUS     = 105_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_HYPO       = 106_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_SHEAR      = 107_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_ENGINEERING = 108_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_THERMO     = 109_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ELAS_SUB_PIEZO      = 110_i4

  !-----------------------------------------------------------------------------
  ! AUXILIARY TYPES: Phase x Verb grouping for primary TYPE nesting
  !-----------------------------------------------------------------------------

    ! Phase: Cfg | Verb: Init | DataKind: Desc
  TYPE, PUBLIC :: PH_Mat_Elas_Cfg_Init_Desc
    INTEGER(i4) :: family_type    = 0_i4   ! Material family (ELASTIC)
    INTEGER(i4) :: sub_type       = 0_i4   ! Elastic variant (ISO/ORTHO/etc.)
    INTEGER(i4) :: num_constants  = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies   = 0_i4   ! Temperature/field dependencies
    INTEGER(i4) :: property_flags = 0_i4   ! Additional property flags
    REAL(wp)    :: density        = 0.0_wp ! Material density
  END TYPE PH_Mat_Elas_Cfg_Init_Desc

  ! Phase: Pop | Verb: Vld | DataKind: Desc
  TYPE, PUBLIC :: PH_Mat_Elas_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Elas_Pop_Vld_Desc

  ! Phase: Inc | Verb: Evo | DataKind: Ctx
  TYPE, PUBLIC :: PH_Mat_Elas_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp       ! Current temperature
    REAL(wp) :: field_var   = 0.0_wp       ! Field variable
    REAL(wp) :: strain_inc(6) = 0.0_wp    ! Strain increment
  END TYPE PH_Mat_Elas_Inc_Evo_Ctx

  !=======================================================================
  ! PRIMARY TYPE: Desc  -- Immutable material configuration
  !=======================================================================
  TYPE, PUBLIC :: PH_Mat_Elas_Desc
    !--- Auxiliary nesting: cfg (config+init), pop (populate+validate) ---
    TYPE(PH_Mat_Elas_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Elas_Pop_Vld_Desc)  :: pop

    ! Material properties array (populated from L3_MD)
    REAL(wp), ALLOCATABLE :: props(:)

    ! Derived isotropic constants (fast access)
    REAL(wp) :: E        = 0.0_wp   ! Young's modulus
    REAL(wp) :: nu       = 0.0_wp   ! Poisson's ratio
    REAL(wp) :: G        = 0.0_wp   ! Shear modulus
    REAL(wp) :: K        = 0.0_wp   ! Bulk modulus
    REAL(wp) :: lambda   = 0.0_wp   ! Lame first parameter
    REAL(wp) :: mu       = 0.0_wp   ! Lame second parameter

    ! Derived orthotropic constants
    REAL(wp) :: E11 = 0.0_wp, E22 = 0.0_wp, E33 = 0.0_wp
    REAL(wp) :: nu12 = 0.0_wp, nu13 = 0.0_wp, nu23 = 0.0_wp
    REAL(wp) :: G12 = 0.0_wp, G13 = 0.0_wp, G23 = 0.0_wp

    ! Anisotropic stiffness matrix (Voigt notation)
    REAL(wp) :: C(6,6) = 0.0_wp

    ! Material density
    REAL(wp) :: density = 0.0_wp

  CONTAINS
    !--- TBP short names (no context prefix) ---
    PROCEDURE :: Init   => Desc_Init
    PROCEDURE :: Valid  => Desc_Valid
    PROCEDURE :: Copy   => Desc_Copy
    PROCEDURE :: Clean  => Desc_Clean
  END TYPE PH_Mat_Elas_Desc

  !=======================================================================
  ! PRIMARY TYPE: State -- Integration point runtime state
  !=======================================================================
  TYPE, PUBLIC :: PH_Mat_Elas_State
    REAL(wp) :: stress(6)         = 0.0_wp   ! Current stress (Voigt)
    REAL(wp) :: strain(6)         = 0.0_wp   ! Current total strain
    REAL(wp) :: elastic_strain(6) = 0.0_wp   ! Elastic strain (= total for pure elastic)
    LOGICAL  :: initialized       = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => State_Init
    PROCEDURE :: Update   => State_Update
    PROCEDURE :: Clean    => State_Clean
    PROCEDURE :: Reset    => State_Reset
  END TYPE PH_Mat_Elas_State

  !=======================================================================
  ! PRIMARY TYPE: Algo -- Algorithm descriptor
  !=======================================================================
  TYPE, PUBLIC :: PH_Mat_Elas_Algo
    INTEGER(i4) :: tangent_type            = 1_i4       ! 1=consistent, 2=continuum
    LOGICAL     :: use_numerical_tangent   = .FALSE.
    REAL(wp)    :: numerical_perturbation  = 1.0e-8_wp
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
    PROCEDURE :: Config => Algo_Config
  END TYPE PH_Mat_Elas_Algo

  !=======================================================================
  ! PRIMARY TYPE: Ctx -- Per-increment/iteration workspace
  !=======================================================================
  TYPE, PUBLIC :: PH_Mat_Elas_Ctx
    !--- Auxiliary nesting ---
    TYPE(PH_Mat_Elas_Inc_Evo_Ctx) :: inc   ! Increment-level context

    ! Cached stiffness matrix (hot path optimization)
    REAL(wp) :: D_el(6,6)        = 0.0_wp
    LOGICAL  :: D_el_cached      = .FALSE.

    ! Integration point identification
    INTEGER(i4) :: ip_id    = 0_i4
    INTEGER(i4) :: elem_id  = 0_i4
  CONTAINS
    PROCEDURE :: Init      => Ctx_Init
    PROCEDURE :: CacheStif => Ctx_CacheStif
    PROCEDURE :: Clean     => Ctx_Clean
  END TYPE PH_Mat_Elas_Ctx

  !=======================================================================
  ! SIO ARGS: PH_Mat_Elas_Eval_Arg -- Unified argument bundle
  ! Replaces (inp, out) pair with single [IN]/[OUT] annotated TYPE.
  ! Usage: (desc, state, algo, ctx, args, status) -- 6-param form
  !=======================================================================
  TYPE, PUBLIC :: PH_Mat_Elas_Eval_Arg
    !--- [IN] fields ---
    REAL(wp) :: strain(6)              ! [IN]  current total strain
    REAL(wp) :: dstrain(6)             ! [IN]  strain increment
    REAL(wp) :: temperature            ! [IN]  current temperature
    REAL(wp) :: dtemp                  ! [IN]  temperature increment
    REAL(wp) :: field_var              ! [IN]  field variable

    !--- [OUT] fields ---
    REAL(wp) :: stress(6)              ! [OUT] updated Cauchy stress
    REAL(wp) :: ddsdde(6,6)            ! [OUT] tangent stiffness matrix

    !--- [INOUT] fields ---
    REAL(wp), ALLOCATABLE :: statev(:) ! [INOUT] state variables

    !--- [OUT] status ---
    INTEGER(i4)           :: status_code ! [OUT] exit status
    CHARACTER(len=256)    :: message     ! [OUT] status message
  END TYPE PH_Mat_Elas_Eval_Arg

  !=======================================================================
  ! Public exports
  !=======================================================================
  PUBLIC :: PH_MAT_ELAS_SUB_ISO, PH_MAT_ELAS_SUB_ORTHO, &
            PH_MAT_ELAS_SUB_TRANSISO, PH_MAT_ELAS_SUB_ANISO, &
            PH_MAT_ELAS_SUB_POROUS, PH_MAT_ELAS_SUB_HYPO, &
            PH_MAT_ELAS_SUB_SHEAR, PH_MAT_ELAS_SUB_ENGINEERING, &
            PH_MAT_ELAS_SUB_THERMO, PH_MAT_ELAS_SUB_PIEZO

CONTAINS

  !=============================================================================
  ! TBP IMPLEMENTATIONS: PH_Mat_Elas_Desc
  !=============================================================================

  SUBROUTINE Desc_Init(this, sub_type, nprops, props, status)
    CLASS(PH_Mat_Elas_Desc), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: sub_type
    INTEGER(i4),             INTENT(IN)    :: nprops
    REAL(wp),                INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    this%cfg%family_type    = 1_i4  ! ELASTIC
    this%cfg%sub_type       = sub_type
    this%cfg%num_constants  = nprops
    this%cfg%dependencies   = 0_i4
    this%cfg%property_flags = 0_i4
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops), SOURCE=props(1:nprops))
    this%pop%is_valid = .TRUE.
    this%density = 0.0_wp
    status%status_code = 0
  END SUBROUTINE Desc_Init

  SUBROUTINE Desc_Valid(this, status)
    CLASS(PH_Mat_Elas_Desc), INTENT(IN)  :: this
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%pop%is_valid) THEN
      status%status_code = -1; status%message = "Desc not initialized"; RETURN
    END IF
    IF (this%cfg%num_constants <= 0) THEN
      status%status_code = -2; status%message = "No material constants"; RETURN
    END IF
    status%status_code = 0
  END SUBROUTINE Desc_Valid

  SUBROUTINE Desc_Copy(this, other, status)
    CLASS(PH_Mat_Elas_Desc), INTENT(IN)  :: this
    CLASS(PH_Mat_Elas_Desc), INTENT(OUT) :: other
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)
    other%cfg = this%cfg
    other%pop = this%pop
    IF (ALLOCATED(this%props)) THEN
      ALLOCATE(other%props(SIZE(this%props)), SOURCE=this%props)
    END IF
    other%E = this%E; other%nu = this%nu; other%G = this%G
    other%K = this%K; other%lambda = this%lambda; other%mu = this%mu
    other%density = this%density
    status%status_code = 0
  END SUBROUTINE Desc_Copy

  SUBROUTINE Desc_Clean(this)
    CLASS(PH_Mat_Elas_Desc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    this%pop%is_valid = .FALSE.
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: PH_Mat_Elas_State
  !=============================================================================

  SUBROUTINE State_Init(this)
    CLASS(PH_Mat_Elas_State), INTENT(OUT) :: this
    this%stress         = 0.0_wp
    this%strain         = 0.0_wp
    this%elastic_strain = 0.0_wp
    this%initialized    = .TRUE.
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(this, stress, strain)
    CLASS(PH_Mat_Elas_State), INTENT(INOUT) :: this
    REAL(wp),                 INTENT(IN)    :: stress(6)
    REAL(wp),                 INTENT(IN)    :: strain(6)
    this%stress         = stress
    this%strain         = strain
    this%elastic_strain = strain
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(this)
    CLASS(PH_Mat_Elas_State), INTENT(INOUT) :: this
    this%stress         = 0.0_wp
    this%strain         = 0.0_wp
    this%elastic_strain = 0.0_wp
    this%initialized    = .FALSE.
  END SUBROUTINE State_Clean

  SUBROUTINE State_Reset(this)
    CLASS(PH_Mat_Elas_State), INTENT(INOUT) :: this
    this%stress         = 0.0_wp
    this%elastic_strain = this%strain
  END SUBROUTINE State_Reset

  !=============================================================================
  ! TBP IMPLEMENTATIONS: PH_Mat_Elas_Algo
  !=============================================================================

  SUBROUTINE Algo_Init(this)
    CLASS(PH_Mat_Elas_Algo), INTENT(OUT) :: this
    this%tangent_type          = 1_i4
    this%use_numerical_tangent = .FALSE.
    this%numerical_perturbation = 1.0e-8_wp
  END SUBROUTINE Algo_Init

  SUBROUTINE Algo_Config(this, tangent_type, use_num_tangent)
    CLASS(PH_Mat_Elas_Algo), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: tangent_type
    LOGICAL,                 INTENT(IN)    :: use_num_tangent
    this%tangent_type          = tangent_type
    this%use_numerical_tangent = use_num_tangent
  END SUBROUTINE Algo_Config

  !=============================================================================
  ! TBP IMPLEMENTATIONS: PH_Mat_Elas_Ctx
  !=============================================================================

  SUBROUTINE Ctx_Init(this)
    CLASS(PH_Mat_Elas_Ctx), INTENT(OUT) :: this
    this%D_el        = 0.0_wp
    this%D_el_cached = .FALSE.
    this%ip_id       = 0_i4
    this%elem_id     = 0_i4
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_CacheStif(this, D_el)
    CLASS(PH_Mat_Elas_Ctx), INTENT(INOUT) :: this
    REAL(wp),               INTENT(IN)    :: D_el(6,6)
    this%D_el        = D_el
    this%D_el_cached = .TRUE.
  END SUBROUTINE Ctx_CacheStif

  SUBROUTINE Ctx_Clean(this)
    CLASS(PH_Mat_Elas_Ctx), INTENT(INOUT) :: this
    this%D_el        = 0.0_wp
    this%D_el_cached = .FALSE.
  END SUBROUTINE Ctx_Clean

END MODULE PH_Mat_Elas_Def