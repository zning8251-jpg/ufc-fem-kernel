!===============================================================================
! Module: MD_Analysis_GroupAware_Desc                         [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Analysis Control — Group-aware Analysis Type Definition
!
! Purpose:
!   Extends MD_Analysis_Types with physical field grouping (G1-G9).
!   Each analysis type is now classified into one of 9 groups based on:
!     - Whether related to structure (mechanics)
!     - Number of physical fields coupled
!     - Coupling method (one-way, weak, strong)
!
!   This enables:
!     - Automatic material constraint checking (family 01-11)
!     - Element type filtering per group
!     - Solver strategy selection (Standard/Explicit/CFD/Acoustic/EM)
!
! Group Classification (G1-G9):
!   G1: Structure single-field (9 types) — PROC 1,2,11,12,21,22,23,24,29
!   G2: Pure thermal (1 type) — PROC 31
!   G3: Frequency-domain (4 types) — PROC 25,27,28,62
!   G4: Acoustic single-field (1 type) — PROC 81
!   G5: Electromagnetic single-field (1 type) — PROC 71
!   G6: Thermal-structure coupled (2 types) — PROC 32,34
!   G7: Three-field or multi-field (3 types) — PROC 33,35,51
!   G8: Geomechanics/soil (2 types) — PROC 41,42
!   G9: Other special types (5 types) — PROC 43,44,61,91
!
! Principle #14 (Structured IO):
!   All public subroutines use unified *_Arg bundle with [IN]/[OUT] comments
!   No paired inp/out parameters; single unified structure
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!   USE MD_Analysis_Types (base types and constants)
!===============================================================================
MODULE MD_Analysis_GroupAware_Desc
  USE IF_Prec_Core,    ONLY: wp, i4, i2
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                        IF_ERROR_CODE_INVALID_PARAMETER
  USE MD_Analysis_Types, ONLY: MD_Analy_Base_Desc, MD_Analy_Base_State, &
                               MD_Analy_Base_Algo
  IMPLICIT NONE
  PRIVATE

  !-- Public type exports
  PUBLIC :: MD_AnalyGroup_Desc
  PUBLIC :: MD_AnalyGroup_Validator
  PUBLIC :: MD_AnalyGroup_MatConstraint
  PUBLIC :: MD_AnalyGroup_ElemConstraint

  !-- Public subroutine exports
  PUBLIC :: AnalyGroup_Create_Desc
  PUBLIC :: AnalyGroup_Validate_Type
  PUBLIC :: AnalyGroup_Get_AllowedMaterials
  PUBLIC :: AnalyGroup_Get_AllowedElements
  PUBLIC :: AnalyGroup_Get_SolverType

  !-- Group enumeration (G1-G9)
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_ID_MIN = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_ID_MAX = 9_i4

  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_G1 = 1_i4  ! Structure single-field (9 types)
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_G2 = 2_i4  ! Pure thermal (1 type)
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_G3 = 3_i4  ! Frequency-domain (4 types)
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_G4 = 4_i4  ! Acoustic single-field (1 type)
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_G5 = 5_i4  ! Electromagnetic single-field (1 type)
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_G6 = 6_i4  ! Thermal-structure coupled (2 types)
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_G7 = 7_i4  ! Three-field or multi-field (3 types)
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_G8 = 8_i4  ! Geomechanics/soil (2 types)
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_GROUP_G9 = 9_i4  ! Other special (5 types)

  !-- PROC_ID mapping to group
  !   Map ABAQUS procedure ID (1-91) to analysis group (G1-G9)
  INTEGER(i2), PARAMETER :: PROC_TO_GROUP(0:99) = [ &
    0_i2, 1_i2, 1_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, &  ! 0-9
    0_i2, 1_i2, 1_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, &  ! 10-19
    0_i2, 1_i2, 1_i2, 1_i2, 1_i2, 3_i2, 0_i2, 3_i2, 3_i2, 1_i2, &  ! 20-29
    0_i2, 2_i2, 6_i2, 7_i2, 6_i2, 7_i2, 0_i2, 0_i2, 0_i2, 0_i2, &  ! 30-39
    0_i2, 8_i2, 8_i2, 9_i2, 9_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, &  ! 40-49
    0_i2, 7_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, &  ! 50-59
    0_i2, 9_i2, 3_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, &  ! 60-69
    0_i2, 5_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, &  ! 70-79
    0_i2, 4_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 0_i2, 9_i2, &  ! 80-89
    0_i2, 9_i2                                                      &  ! 90-91
  ]

  !-- Material family constraints per group
  !   Bit pattern: bit n set ⟹ material family (n+1) allowed
  !   Family 01-11: Elastic, Plastic, Geo, HyperElastic, Viscoelastic,
  !                 Creep, Damage, Composite, Thermal, Acoustic, User
  !   Example: G1=structural ⟹ families 01-08 allowed (bits 0-7 set)
  INTEGER(i4), PARAMETER :: GROUP_MATFAMILY_ALLOWED(1:9) = [ &
    INT(B'00000111111111',i4), &  ! G1: fam 01-08 mechanics (bits 0-7)
    INT(B'00000100000000',i4), &  ! G2: fam 09 thermal only (bit 8)
    INT(B'00000111111111',i4), &  ! G3: fam 01-08 mechanics (bits 0-7) freq-domain
    INT(B'00010000000000',i4), &  ! G4: fam 10 acoustic (bit 9)
    INT(B'00100000000000',i4), &  ! G5: fam 11 electromagnetic (bit 10)
    INT(B'00000111111111',i4), &  ! G6: fam 01-08 + fam 09 thermal (bits 0-8)
    INT(B'00000111111111',i4), &  ! G7: fam 01-08 + multi-field (bits 0-8+)
    INT(B'00000111111111',i4), &  ! G8: fam 01-08 + geo materials (bits 0-7+)
    INT(B'00000111111111',i4)  &  ! G9: special materials mixed (bits 0-7+)
  ]

  !-- Element type constraints per group
  !   Allowed element types: C3D (solid), CPS (plane stress), CAX (axisymm),
  !                          S (shell), B (beam), T (truss),
  !                          DC (thermal), AC (acoustic), EM (electromagnetic)
  CHARACTER(LEN=256), PARAMETER :: GROUP_ELEM_ALLOWED(1:9) = [ &
    'C3D,CPS,CAX,S,B,T              ', &  ! G1: all structural
    'DC,CAX                          ', &  ! G2: thermal solid/axisymm
    'C3D,CPS,CAX,S,B,T              ', &  ! G3: structural freq-domain
    'AC,CAX                          ', &  ! G4: acoustic
    'EM,CAX                          ', &  ! G5: electromagnetic
    'C3D,CPS,CAX,S,B,T,DC           ', &  ! G6: thermal-structure coupled
    'C3D,CPS,CAX,S,B,T,DC,AC,EM     ', &  ! G7: multi-field
    'C3D,CPS,CAX                     ', &  ! G8: geomechanics solid
    'C3D,CPS,CAX,S,B,T,DC,AC,EM     '  &  ! G9: special (all allowed)
  ]

  !-- Solver type mapping per group
  INTEGER(i4), PARAMETER :: GROUP_SOLVER_TYPE(1:9) = [ &
    1_i4,  &  ! G1: Standard or Explicit
    1_i4,  &  ! G2: Standard thermal
    1_i4,  &  ! G3: Standard frequency
    2_i4,  &  ! G4: Acoustic solver
    3_i4,  &  ! G5: EM solver
    1_i4,  &  ! G6: Standard coupled
    1_i4,  &  ! G7: Standard multi-field
    1_i4,  &  ! G8: Standard geomech
    1_i4  &   ! G9: Standard or specialized
  ]
  ! Solver types: 1=Standard, 2=Acoustic, 3=EM, 4=CFD, 5=Explicit

  !-----------------------------------------------------------------------------
  ! DESC — Analysis Group Descriptor
  !    Extends base analysis descriptor with group-aware constraints.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_AnalyGroup_Desc
    !-- Inherited from base (flatten for clarity in this template)
    INTEGER(i4)       :: analy_id        = 0_i4
    CHARACTER(LEN=64) :: analy_name      = ''
    INTEGER(i4)       :: analysis_proc   = 1_i4    ! PROC_ID (1-91)
    
    !-- NEW: Group classification
    INTEGER(i4)       :: group_id        = 0_i4    ! G1-G9 (0=uninitialized)
    LOGICAL           :: group_validated = .FALSE.
    
    !-- Physical field properties
    LOGICAL           :: has_struct_field   = .TRUE.   ! Involves displacement DOF
    LOGICAL           :: has_thermal_field  = .FALSE.  ! Involves temperature DOF
    LOGICAL           :: has_acoustic_field = .FALSE.  ! Involves acoustic pressure
    LOGICAL           :: has_em_field       = .FALSE.  ! Involves EM potential
    
    !-- Coupling specification
    CHARACTER(LEN=32) :: coupling_type   = 'NONE'   ! NONE/ONE_WAY/WEAK/STRONG
    INTEGER(i4)       :: n_coupled_fields = 1_i4    ! Number of coupled fields
    
    !-- Time integration characteristics
    CHARACTER(LEN=32) :: time_type       = 'QUASI_STATIC'  ! QUASI_STATIC/TRANSIENT/MODAL/FREQUENCY
    CHARACTER(LEN=32) :: method_type     = 'IMPLICIT'     ! IMPLICIT/EXPLICIT/FREQUENCY
    
    !-- Material and element constraints (derived from group)
    INTEGER(i4)       :: allowed_mat_families = 0_i4   ! Bit pattern of allowed families
    CHARACTER(LEN=256) :: allowed_elem_types  = ''      ! Comma-separated element types
    
    !-- Validation and error tracking
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: constraint_violation = ''     ! Description of constraint failure
    
  END TYPE MD_AnalyGroup_Desc

  !-----------------------------------------------------------------------------
  ! VALIDATOR — Analysis Group Validator
  !    Provides validation rules and constraint checking.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_AnalyGroup_Validator
    LOGICAL           :: initialized = .FALSE.
    INTEGER(i4)       :: n_violations = 0_i4
    CHARACTER(LEN=512), ALLOCATABLE :: violations(:)
  CONTAINS
    PROCEDURE :: Init          => Validator_Init
    PROCEDURE :: Validate      => Validator_Validate
    PROCEDURE :: Check_PROC    => Validator_Check_PROC
    PROCEDURE :: Check_Materials => Validator_Check_Materials
    PROCEDURE :: Check_Elements => Validator_Check_Elements
  END TYPE MD_AnalyGroup_Validator

  !-----------------------------------------------------------------------------
  ! Material constraint lookup
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_AnalyGroup_MatConstraint
    INTEGER(i4) :: group_id       = 0_i4
    INTEGER(i4) :: allowed_bitmap = 0_i4  ! Families 01-11
    CHARACTER(LEN=256) :: allowed_names = ''
  END TYPE MD_AnalyGroup_MatConstraint

  !-----------------------------------------------------------------------------
  ! Element constraint lookup
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_AnalyGroup_ElemConstraint
    INTEGER(i4) :: group_id = 0_i4
    CHARACTER(LEN=256) :: allowed_types = ''
  END TYPE MD_AnalyGroup_ElemConstraint

CONTAINS

  !===========================================================================
  ! PUBLIC SUBROUTINE: AnalyGroup_Create_Desc
  !   [IN]  proc_id : ABAQUS procedure type (1-91)
  !   [OUT] desc : Filled MD_AnalyGroup_Desc with group assignment
  !===========================================================================
  SUBROUTINE AnalyGroup_Create_Desc(proc_id, desc, args)
    IMPLICIT NONE
    INTEGER(i4), INTENT(IN) :: proc_id
    TYPE(MD_AnalyGroup_Desc), INTENT(OUT) :: desc
    TYPE(AnalyGroup_Arg), INTENT(INOUT), OPTIONAL :: args  ! [OUT] success flag

    INTEGER(i4) :: grp

    desc%analysis_proc = proc_id
    CALL init_error_status(desc%status, IF_STATUS_OK)
    
    ! Map PROC_ID to group
    IF (proc_id < 0 .OR. proc_id > UBOUND(PROC_TO_GROUP, 1)) THEN
      CALL init_error_status(desc%status, IF_ERROR_CODE_INVALID_PARAMETER, &
        'AnalyGroup_Create_Desc: proc_id out of supported range')
      IF (PRESENT(args)) args%success = .FALSE.
      RETURN
    END IF

    grp = INT(PROC_TO_GROUP(proc_id), i4)
    
    IF (grp < ANALY_GROUP_ID_MIN .OR. grp > ANALY_GROUP_ID_MAX) THEN
      CALL init_error_status(desc%status, IF_ERROR_CODE_INVALID_PARAMETER, &
        'AnalyGroup_Create_Desc: unresolved analysis group mapping')
      IF (PRESENT(args)) args%success = .FALSE.
      RETURN
    END IF

    desc%group_id = grp
    
    ! Assign material and element constraints based on group
    CALL AnalyGroup_Assign_Constraints(desc)
    
    desc%group_validated = .TRUE.
    IF (PRESENT(args)) args%success = .TRUE.

  END SUBROUTINE AnalyGroup_Create_Desc

  !===========================================================================
  ! PRIVATE HELPER: Assign constraints based on group
  !===========================================================================
  SUBROUTINE AnalyGroup_Assign_Constraints(desc)
    IMPLICIT NONE
    TYPE(MD_AnalyGroup_Desc), INTENT(INOUT) :: desc
    INTEGER(i4) :: g

    g = desc%group_id
    IF (g < 1 .OR. g > 9) RETURN

    desc%allowed_mat_families = GROUP_MATFAMILY_ALLOWED(g)
    desc%allowed_elem_types = TRIM(ADJUSTL(GROUP_ELEM_ALLOWED(g)))

  END SUBROUTINE AnalyGroup_Assign_Constraints

  !===========================================================================
  ! PUBLIC SUBROUTINE: AnalyGroup_Validate_Type
  !   Validates if an analysis type is correctly configured.
  !===========================================================================
  SUBROUTINE AnalyGroup_Validate_Type(desc, validator)
    IMPLICIT NONE
    TYPE(MD_AnalyGroup_Desc), INTENT(INOUT) :: desc
    TYPE(MD_AnalyGroup_Validator), INTENT(INOUT) :: validator

    IF (.NOT. validator%initialized) CALL Validator_Init(validator)

    CALL Validator_Validate(validator, desc)

  END SUBROUTINE AnalyGroup_Validate_Type

  !===========================================================================
  ! PUBLIC SUBROUTINE: AnalyGroup_Get_AllowedMaterials
  !   Returns bitmap of allowed material families for a group.
  !===========================================================================
  SUBROUTINE AnalyGroup_Get_AllowedMaterials(group_id, bitmap, names)
    IMPLICIT NONE
    INTEGER(i4), INTENT(IN) :: group_id
    INTEGER(i4), INTENT(OUT), OPTIONAL :: bitmap
    CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: names

    INTEGER(i4) :: g

    g = group_id
    IF (g < 1 .OR. g > 9) THEN
      IF (PRESENT(bitmap)) bitmap = 0_i4
      IF (PRESENT(names)) names = ''
      RETURN
    END IF

    IF (PRESENT(bitmap)) bitmap = GROUP_MATFAMILY_ALLOWED(g)
    
    IF (PRESENT(names)) THEN
      SELECT CASE (g)
        CASE (1)  ! G1: structure single-field
          names = 'Elastic,Plastic,Geomaterial,HyperElastic,Viscoelastic,Creep,Damage,Composite'
        CASE (2)  ! G2: pure thermal
          names = 'Thermal'
        CASE (3)  ! G3: frequency-domain
          names = 'Elastic,Plastic,Geomaterial,HyperElastic,Viscoelastic,Creep,Damage,Composite'
        CASE (4)  ! G4: acoustic
          names = 'Acoustic'
        CASE (5)  ! G5: electromagnetic
          names = 'Electromagnetic'
        CASE (6)  ! G6: thermal-structure
          names = 'Elastic,Plastic,Geomaterial,HyperElastic,Viscoelastic,Creep,Damage,Composite,Thermal'
        CASE (7)  ! G7: three-field+
          names = 'ALL'
        CASE (8)  ! G8: geomechanics
          names = 'Elastic,Plastic,Geomaterial,HyperElastic,Viscoelastic,Creep,Damage,Composite'
        CASE (9)  ! G9: other special
          names = 'ALL'
      END SELECT
    END IF

  END SUBROUTINE AnalyGroup_Get_AllowedMaterials

  !===========================================================================
  ! PUBLIC SUBROUTINE: AnalyGroup_Get_AllowedElements
  !   Returns comma-separated list of allowed element types for a group.
  !===========================================================================
  SUBROUTINE AnalyGroup_Get_AllowedElements(group_id, elem_types)
    IMPLICIT NONE
    INTEGER(i4), INTENT(IN) :: group_id
    CHARACTER(LEN=*), INTENT(OUT) :: elem_types

    INTEGER(i4) :: g

    g = group_id
    IF (g < 1 .OR. g > 9) THEN
      elem_types = ''
      RETURN
    END IF

    elem_types = TRIM(ADJUSTL(GROUP_ELEM_ALLOWED(g)))

  END SUBROUTINE AnalyGroup_Get_AllowedElements

  !===========================================================================
  ! PUBLIC SUBROUTINE: AnalyGroup_Get_SolverType
  !   Returns the solver type category for a group (Standard/Acoustic/EM/CFD/Explicit).
  !===========================================================================
  SUBROUTINE AnalyGroup_Get_SolverType(group_id, solver_type, solver_name)
    IMPLICIT NONE
    INTEGER(i4), INTENT(IN) :: group_id
    INTEGER(i4), INTENT(OUT), OPTIONAL :: solver_type
    CHARACTER(LEN=32), INTENT(OUT), OPTIONAL :: solver_name

    INTEGER(i4) :: g, st

    g = group_id
    IF (g < 1 .OR. g > 9) THEN
      IF (PRESENT(solver_type)) solver_type = 0_i4
      IF (PRESENT(solver_name)) solver_name = 'UNKNOWN'
      RETURN
    END IF

    st = GROUP_SOLVER_TYPE(g)
    IF (PRESENT(solver_type)) solver_type = st

    IF (PRESENT(solver_name)) THEN
      SELECT CASE (st)
        CASE (1)
          solver_name = 'STANDARD'
        CASE (2)
          solver_name = 'ACOUSTIC'
        CASE (3)
          solver_name = 'ELECTROMAGNETIC'
        CASE (4)
          solver_name = 'CFD'
        CASE (5)
          solver_name = 'EXPLICIT'
        CASE DEFAULT
          solver_name = 'UNKNOWN'
      END SELECT
    END IF

  END SUBROUTINE AnalyGroup_Get_SolverType

  !===========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Init
  !===========================================================================
  SUBROUTINE Validator_Init(self)
    CLASS(MD_AnalyGroup_Validator), INTENT(INOUT) :: self
    ALLOCATE(self%violations(100))
    self%n_violations = 0_i4
    self%initialized = .TRUE.
  END SUBROUTINE Validator_Init

  !===========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Validate
  !===========================================================================
  SUBROUTINE Validator_Validate(self, desc)
    CLASS(MD_AnalyGroup_Validator), INTENT(INOUT) :: self
    TYPE(MD_AnalyGroup_Desc), INTENT(INOUT) :: desc

    self%n_violations = 0_i4
    
    ! Check PROC_ID validity
    CALL self%Check_PROC(desc)
    
    ! Additional validation rules can be added here
    ! - Material-group compatibility
    ! - Element-group compatibility
    ! - Coupling strategy coherence
    
  END SUBROUTINE Validator_Validate

  !===========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Check_PROC
  !===========================================================================
  SUBROUTINE Validator_Check_PROC(self, desc)
    CLASS(MD_AnalyGroup_Validator), INTENT(INOUT) :: self
    TYPE(MD_AnalyGroup_Desc), INTENT(INOUT) :: desc

    IF (desc%analysis_proc < 1 .OR. desc%analysis_proc > 91) THEN
      self%n_violations = self%n_violations + 1_i4
      IF (self%n_violations <= SIZE(self%violations)) THEN
        WRITE(self%violations(self%n_violations), '(A,I0)') &
          'Invalid PROC_ID: ', desc%analysis_proc
      END IF
    END IF

  END SUBROUTINE Validator_Check_PROC

  !===========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Check_Materials (placeholder)
  !===========================================================================
  SUBROUTINE Validator_Check_Materials(self, desc)
    CLASS(MD_AnalyGroup_Validator), INTENT(INOUT) :: self
    TYPE(MD_AnalyGroup_Desc), INTENT(IN) :: desc
    ! To be implemented in integration phase
  END SUBROUTINE Validator_Check_Materials

  !===========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Check_Elements (placeholder)
  !===========================================================================
  SUBROUTINE Validator_Check_Elements(self, desc)
    CLASS(MD_AnalyGroup_Validator), INTENT(INOUT) :: self
    TYPE(MD_AnalyGroup_Desc), INTENT(IN) :: desc
    ! To be implemented in integration phase
  END SUBROUTINE Validator_Check_Elements

  !-- Auxiliary type for Principle #14 (unified Arg bundle)
  TYPE :: AnalyGroup_Arg
    LOGICAL :: success = .FALSE.
  END TYPE AnalyGroup_Arg

END MODULE MD_Analysis_GroupAware_Desc
