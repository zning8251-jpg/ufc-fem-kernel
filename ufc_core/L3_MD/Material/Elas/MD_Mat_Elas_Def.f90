!===============================================================================
! MODULE: MD_Mat_Elas_Def
! LAYER:  L3_MD
! DOMAIN: Material / Elas
! ROLE:   Def
! BRIEF:  Unified TYPE definitions for elastic material family.
!         Binary structure: 4-type (Desc/State/Algo/Ctx) + Args.
!--- COLD (this Def) vs HOT (MD_Mat_Elas_Core / MD_Mat_Elas_Brg) ---
!         Auxiliary types nested under primary TYPEs with Phase x Verb grouping.
!         TBP short names (no context prefix).
!
!     Cross-layer:
!       L3_MD Desc --[Populate]--> L4_PH Desc
!       L3_MD State --[Sync]-----> L5_RT State table
!===============================================================================
MODULE MD_Mat_Elas_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_ELASTIC, &
                                MD_MAT_ELAS_SUB_ISO, &
                                MD_MAT_ELAS_SUB_ORTHO, &
                                MD_MAT_ELAS_SUB_TRANSISO, &
                                MD_MAT_ELAS_SUB_ANISO, &
                                MD_MAT_ELAS_SUB_POROUS, &
                                MD_MAT_ELAS_SUB_HYPO, &
                                MD_MAT_ELAS_SUB_SHEAR, &
                                MD_MAT_ELAS_SUB_ENGINEERING, &
                                MD_MAT_ELAS_SUB_THERMO, &
                                MD_MAT_ELAS_SUB_PIEZO, &
                                MD_MAT_PROP_NONE, &
                                MD_MAT_PROP_TEMP_DEP, &
                                MD_MAT_PROP_FIELD_DEP
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Elastic sub-type constants (re-export)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_ISO        = 101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_ORTHO      = 102_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_TRANSISO   = 103_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_ANISO      = 104_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_POROUS     = 105_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_HYPO       = 106_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_SHEAR      = 107_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_ENGINEERING = 108_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_THERMO     = 109_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_PIEZO      = 110_i4

  !-----------------------------------------------------------------------------
  ! AUXILIARY TYPES: Phase x Verb grouping
  !-----------------------------------------------------------------------------

  ! Phase: Cfg | Verb: Init | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Elas_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Main family (ELASTIC)
    INTEGER(i4) :: sub_type         = 0_i4   ! Variant (ISO/ORTHO/etc.)
    INTEGER(i4) :: property_flags   = 0_i4   ! Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! Temp/field dependencies
  END TYPE MD_Mat_Elas_Cfg_Init_Desc

  ! Phase: Pop | Verb: Vld | DataKind: Desc
  TYPE, PUBLIC :: MD_Mat_Elas_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Elas_Pop_Vld_Desc

  ! Phase: Step | Verb: Evo | DataKind: Ctx
  TYPE, PUBLIC :: MD_Mat_Elas_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp) :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id     = 0_i4       ! Integration point number
    INTEGER(i4) :: elem_id   = 0_i4       ! Element ID
  END TYPE MD_Mat_Elas_Stp_Evo_Ctx

  !=======================================================================
  ! PRIMARY TYPE: Desc  -- Static material descriptor
  ! Lifecycle: Created during model definition, immutable during solve
  ! Owner: L3_MD layer
  !=======================================================================
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Elas_Desc
    !--- Auxiliary nesting ---
    TYPE(MD_Mat_Elas_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Elas_Pop_Vld_Desc)  :: pop

    ! Material constants table (temp/field dependent)
    REAL(wp), ALLOCATABLE :: constants(:,:)

    ! Derived parameters (fast access)
    ! Isotropic
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp
    REAL(wp) :: G = 0.0_wp, K = 0.0_wp, lambda = 0.0_wp, mu = 0.0_wp

    ! Orthotropic
    REAL(wp) :: E11 = 0.0_wp, E22 = 0.0_wp, E33 = 0.0_wp
    REAL(wp) :: nu12 = 0.0_wp, nu13 = 0.0_wp, nu23 = 0.0_wp
    REAL(wp) :: G12 = 0.0_wp, G13 = 0.0_wp, G23 = 0.0_wp

    ! Anisotropic stiffness matrix (Voigt notation)
    REAL(wp) :: C(6,6) = 0.0_wp

    ! Density parameter
    REAL(wp) :: density = 0.0_wp
  CONTAINS
    !--- TBP short names ---
    PROCEDURE :: Init           => Desc_Init
    PROCEDURE :: Valid          => Desc_Valid
    PROCEDURE :: ComputeDerived => Desc_ComputeDerived
    PROCEDURE :: Clean          => Desc_Clean
  END TYPE MD_Mat_Elas_Desc

  !=======================================================================
  ! PRIMARY TYPE: State -- Runtime state (elastic: no internal state vars)
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Elas_State
    REAL(wp) :: stress(6)         = 0.0_wp   ! Stress tensor (Voigt)
    REAL(wp) :: strain(6)         = 0.0_wp   ! Strain tensor (Voigt)
    REAL(wp) :: elastic_strain(6) = 0.0_wp   ! Elastic strain
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Elas_State

  !=======================================================================
  ! PRIMARY TYPE: Algo -- Algorithm descriptor
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Elas_Algo
    INTEGER(i4) :: integration_method = 0_i4  ! Integration method
    INTEGER(i4) :: tangent_type       = 0_i4  ! Tangent type
    LOGICAL     :: use_numerical_tangent = .FALSE.
    REAL(wp)    :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
    PROCEDURE :: Config => Algo_Config
  END TYPE MD_Mat_Elas_Algo

  !=======================================================================
  ! PRIMARY TYPE: Ctx -- Runtime context
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Elas_Ctx
    TYPE(MD_Mat_Elas_Stp_Evo_Ctx) :: stp  ! Step-level context
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Elas_Ctx

  !=======================================================================
  ! SIO ARGS: MD_Mat_Elas_Reg_Arg -- Registration argument bundle
  !=======================================================================
  TYPE, PUBLIC :: MD_Mat_Elas_Reg_Arg
    ! [IN] fields
    INTEGER(i4)           :: sub_type       ! [IN]  elastic variant type
    INTEGER(i4)           :: num_constants  ! [IN]  number of constants
    REAL(wp), ALLOCATABLE :: constants(:,:) ! [IN]  material constants table
    INTEGER(i4)           :: dependencies   ! [IN]  temp/field dependencies

    ! [OUT] fields
    INTEGER(i4)           :: mat_id         ! [OUT] assigned material ID
    CHARACTER(len=64)     :: mat_name       ! [OUT] assigned material name
    INTEGER(i4)           :: status_code    ! [OUT] exit status
    CHARACTER(len=256)    :: message        ! [OUT] status message
  END TYPE MD_Mat_Elas_Reg_Arg

  !=======================================================================
  ! Public exports
  !=======================================================================
  PUBLIC :: MD_MAT_ELAS_SUB_ISO, MD_MAT_ELAS_SUB_ORTHO, &
            MD_MAT_ELAS_SUB_TRANSISO, MD_MAT_ELAS_SUB_ANISO, &
            MD_MAT_ELAS_SUB_POROUS, MD_MAT_ELAS_SUB_HYPO, &
            MD_MAT_ELAS_SUB_SHEAR, MD_MAT_ELAS_SUB_ENGINEERING, &
            MD_MAT_ELAS_SUB_THERMO, MD_MAT_ELAS_SUB_PIEZO

  PUBLIC :: MD_Mat_Elas_Get_SubType_Name

CONTAINS

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Elas_Desc
  !=============================================================================

  SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)
    CLASS(MD_Mat_Elas_Desc), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: sub_type
    INTEGER(i4),             INTENT(IN)    :: num_constants
    INTEGER(i4),             INTENT(IN), OPTIONAL :: dependencies
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    this%cfg%family_type    = MD_MAT_FAMILY_ELASTIC
    this%cfg%sub_type       = sub_type
    this%cfg%num_constants  = num_constants
    this%cfg%property_flags = MD_MAT_PROP_NONE
    this%cfg%dependencies   = 0_i4
    IF (PRESENT(dependencies)) THEN
      this%cfg%dependencies = dependencies
      IF (dependencies == 1) THEN
        this%cfg%property_flags = IOR(this%cfg%property_flags, MD_MAT_PROP_TEMP_DEP)
      ELSE IF (dependencies >= 2) THEN
        this%cfg%property_flags = IOR(this%cfg%property_flags, MD_MAT_PROP_FIELD_DEP)
      END IF
    END IF

    ! Allocate constants table
    IF (ALLOCATED(this%constants)) DEALLOCATE(this%constants)
    IF (this%cfg%dependencies > 0) THEN
      ALLOCATE(this%constants(num_constants, this%cfg%dependencies + 1))
    ELSE
      ALLOCATE(this%constants(num_constants, 1))
    END IF
    this%constants = 0.0_wp

    this%pop%is_initialized = .TRUE.
    status%status_code = 0
  END SUBROUTINE Desc_Init

  SUBROUTINE Desc_Valid(this, status)
    CLASS(MD_Mat_Elas_Desc), INTENT(IN)  :: this
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%pop%is_initialized) THEN
      status%status_code = -1; status%message = "Not initialized"; RETURN
    END IF
    IF (this%cfg%family_type /= MD_MAT_FAMILY_ELASTIC) THEN
      status%status_code = -2; status%message = "Not ELASTIC family"; RETURN
    END IF
    IF (this%cfg%sub_type < 101 .OR. this%cfg%sub_type > 110) THEN
      status%status_code = -3; status%message = "Invalid sub_type"; RETURN
    END IF
    IF (this%cfg%num_constants <= 0) THEN
      status%status_code = -4; status%message = "No constants"; RETURN
    END IF
    status%status_code = 0
  END SUBROUTINE Desc_Valid

  SUBROUTINE Desc_ComputeDerived(this, status)
    CLASS(MD_Mat_Elas_Desc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    REAL(wp) :: one, two, three
    CALL init_error_status(status)
    one = 1.0_wp; two = 2.0_wp; three = 3.0_wp

    SELECT CASE (this%cfg%sub_type)
    CASE (MD_MAT_ELAS_SUB_ISO)
      this%E = this%constants(1, 1)
      this%nu = this%constants(2, 1)
      this%lambda = this%E * this%nu / ((one + this%nu) * (one - two * this%nu))
      this%mu = this%E / (two * (one + this%nu))
      this%G = this%mu
      this%K = this%E / (three * (one - two * this%nu))

    CASE (MD_MAT_ELAS_SUB_ORTHO)
      this%E11 = this%constants(1, 1)
      this%E22 = this%constants(2, 1)
      this%E33 = this%constants(3, 1)
      this%nu12 = this%constants(4, 1)
      this%nu13 = this%constants(5, 1)
      this%nu23 = this%constants(6, 1)
      this%G12 = this%constants(7, 1)
      this%G13 = this%constants(8, 1)
      this%G23 = this%constants(9, 1)

    CASE (MD_MAT_ELAS_SUB_ANISO)
      CALL Build_Aniso_C(this%constants(:,1), this%C)

    CASE DEFAULT
      CONTINUE
    END SELECT
    status%status_code = 0
  END SUBROUTINE Desc_ComputeDerived

  SUBROUTINE Desc_Clean(this)
    CLASS(MD_Mat_Elas_Desc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%constants)) DEALLOCATE(this%constants)
    this%pop%is_initialized = .FALSE.
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Elas_State
  !=============================================================================

  SUBROUTINE State_Init(this)
    CLASS(MD_Mat_Elas_State), INTENT(OUT) :: this
    this%stress         = 0.0_wp
    this%strain         = 0.0_wp
    this%elastic_strain = 0.0_wp
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(this, stress, strain)
    CLASS(MD_Mat_Elas_State), INTENT(INOUT) :: this
    REAL(wp),                 INTENT(IN)    :: stress(6)
    REAL(wp),                 INTENT(IN)    :: strain(6)
    this%stress         = stress
    this%strain         = strain
    this%elastic_strain = strain
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(this)
    CLASS(MD_Mat_Elas_State), INTENT(INOUT) :: this
    this%stress         = 0.0_wp
    this%strain         = 0.0_wp
    this%elastic_strain = 0.0_wp
  END SUBROUTINE State_Clean

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Elas_Algo
  !=============================================================================

  SUBROUTINE Algo_Init(this)
    CLASS(MD_Mat_Elas_Algo), INTENT(OUT) :: this
    this%integration_method    = 0_i4
    this%tangent_type          = 0_i4
    this%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Init

  SUBROUTINE Algo_Config(this, tangent_type, use_num)
    CLASS(MD_Mat_Elas_Algo), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: tangent_type
    LOGICAL,                 INTENT(IN)    :: use_num
    this%tangent_type          = tangent_type
    this%use_numerical_tangent = use_num
  END SUBROUTINE Algo_Config

  !=============================================================================
  ! TBP IMPLEMENTATIONS: MD_Mat_Elas_Ctx
  !=============================================================================

  SUBROUTINE Ctx_Init(this)
    CLASS(MD_Mat_Elas_Ctx), INTENT(OUT) :: this
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(this)
    CLASS(MD_Mat_Elas_Ctx), INTENT(INOUT) :: this
  END SUBROUTINE Ctx_Clean

  !=============================================================================
  ! STATELESS HELPERS
  !=============================================================================

  SUBROUTINE Build_Aniso_C(constants, C)
    REAL(wp), INTENT(IN)  :: constants(21)
    REAL(wp), INTENT(OUT) :: C(6,6)
    C = 0.0_wp
    C(1,1)=constants(1);  C(1,2)=constants(2);  C(1,3)=constants(3)
    C(1,4)=constants(4);  C(1,5)=constants(5);  C(1,6)=constants(6)
    C(2,2)=constants(7);  C(2,3)=constants(8);  C(2,4)=constants(9)
    C(2,5)=constants(10); C(2,6)=constants(11); C(3,3)=constants(12)
    C(3,4)=constants(13); C(3,5)=constants(14); C(3,6)=constants(15)
    C(4,4)=constants(16); C(4,5)=constants(17); C(4,6)=constants(18)
    C(5,5)=constants(19); C(5,6)=constants(20); C(6,6)=constants(21)
    C(2,1)=C(1,2); C(3,1)=C(1,3); C(3,2)=C(2,3)
    C(4,1)=C(1,4); C(4,2)=C(2,4); C(4,3)=C(3,4)
    C(5,1)=C(1,5); C(5,2)=C(2,5); C(5,3)=C(3,5); C(5,4)=C(4,5)
    C(6,1)=C(1,6); C(6,2)=C(2,6); C(6,3)=C(3,6); C(6,4)=C(4,6); C(6,5)=C(5,6)
  END SUBROUTINE Build_Aniso_C

  !=============================================================================
  ! MD_Mat_Elas_Get_SubType_Name
  ! Get the name of an elastic sub-type
  !=============================================================================
  FUNCTION MD_Mat_Elas_Get_SubType_Name(sub_type) RESULT(name)
    INTEGER(i4), INTENT(IN) :: sub_type
    CHARACTER(LEN=32) :: name
    SELECT CASE (sub_type)
    CASE (MD_MAT_ELAS_SUB_ISO);        name = "Isotropic"
    CASE (MD_MAT_ELAS_SUB_ORTHO);      name = "Orthotropic"
    CASE (MD_MAT_ELAS_SUB_TRANSISO);   name = "Transversely Isotropic"
    CASE (MD_MAT_ELAS_SUB_ANISO);      name = "Anisotropic"
    CASE (MD_MAT_ELAS_SUB_POROUS);     name = "Porous"
    CASE (MD_MAT_ELAS_SUB_HYPO);       name = "Hypoelastic"
    CASE (MD_MAT_ELAS_SUB_SHEAR);      name = "Shear Modulus Form"
    CASE (MD_MAT_ELAS_SUB_ENGINEERING); name = "Engineering Constants"
    CASE (MD_MAT_ELAS_SUB_THERMO);     name = "Thermo-Elastic"
    CASE (MD_MAT_ELAS_SUB_PIEZO);      name = "Piezo-Elastic"
    CASE DEFAULT;                      name = "Unknown"
    END SELECT
  END FUNCTION MD_Mat_Elas_Get_SubType_Name

END MODULE MD_Mat_Elas_Def