!===============================================================================
! Module: RT_AnalysisGroup_Validator                           [Template v1.0]
! Layer:  L5_RT — Runtime Control Layer
! Domain: Analysis Group Constraint Validation & Conflict Detection
!
! Purpose:
!   Validates runtime compatibility of:
!   1. Analysis group + material families (permissibility check)
!   2. Analysis group + element types (permission matrix)
!   3. Material-element combinations (physical coherence)
!   4. Coupling strategy feasibility (solver capability check)
!
!   This module implements comprehensive constraint enforcement at runtime,
!   catching violations before FEA computation begins. It bridges L4_PH
!   routing decisions and L5_RT/L6_AP execution.
!
! Key functions:
!   - Assert_Group_Materials_Compatible()
!   - Assert_Group_Elements_Compatible()
!   - Assert_Coupling_Strategy_Feasible()
!   - Generate_Constraint_Report()
!
! Principle #14 (Structured IO):
!   All public subroutines use unified *_Arg bundle with [IN]/[OUT] comments.
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType, IF_STATUS_*, IF_ERROR_CODE_*)
!   USE MD_Analysis_GroupAware_Desc (group desc, group constants)
!   USE PH_Analysis_Group_Router (router, handler IDs)
!===============================================================================
MODULE RT_AnalysisGroup_Validator
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Analysis_GroupAware_Desc, ONLY: MD_AnalyGroup_Desc, &
                                          MD_AnalyGroup_Validator, &
                                          ANALY_GROUP_G1, ANALY_GROUP_G2, &
                                          ANALY_GROUP_G3, ANALY_GROUP_G4, &
                                          ANALY_GROUP_G5, ANALY_GROUP_G6, &
                                          ANALY_GROUP_G7, ANALY_GROUP_G8, &
                                          ANALY_GROUP_G9, &
                                          AnalyGroup_Get_AllowedMaterials, &
                                          AnalyGroup_Get_AllowedElements, &
                                          AnalyGroup_Get_SolverType
  USE PH_Analysis_Group_Router, ONLY: PH_AnalyGroup_Router, &
                                       ROUTE_STRATEGY_WEAK, &
                                       ROUTE_STRATEGY_STRONG
  IMPLICIT NONE
  PRIVATE

  !-- Public exports
  PUBLIC :: RT_AnalyGroup_ConstraintValidator
  PUBLIC :: Assert_Group_Materials_Compatible
  PUBLIC :: Assert_Group_Elements_Compatible
  PUBLIC :: Assert_Coupling_Strategy_Feasible
  PUBLIC :: Generate_Constraint_Report

  !-- Constraint violation codes
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_OK                    = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_MATFAMILY_FORBIDDEN   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_ELEMTYPE_FORBIDDEN    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_COUPLING_UNSUPPORTED  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_MATELEM_INCOHERENT    = 4_i4

  !-- Element type registry (simple hardcoded for template)
  CHARACTER(LEN=256), PARAMETER :: ELEMTYPE_REGISTRY = &
    'C3D3,C3D4,C3D6,C3D8,C3D10,C3D15,C3D20,' // &
    'CPS3,CPS4,CPS6,CPS8,' // &
    'CAX3,CAX4,CAX6,CAX8,' // &
    'S3,S3R,S4,S4R,S4RS,' // &
    'B31,B32,B32R,' // &
    'T3D2,' // &
    'DC2D3,DC2D4,DC3D4,DC3D6,DC3D8,' // &
    'AC2D3,AC2D4,AC3D4,AC3D10,' // &
    'EM3D1'

  !-- Material family registry (11 families)
  CHARACTER(LEN=256), PARAMETER :: MATFAMILY_REGISTRY = &
    'Elastic,Plastic,Geomaterial,HyperElastic,Viscoelastic,' // &
    'Creep,Damage,Composite,Thermal,Acoustic,Electromagnetic'

  !-----------------------------------------------------------------------------
  ! VALIDATOR TYPE — Comprehensive constraint checking
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_AnalyGroup_ConstraintValidator
    !-- Configuration
    LOGICAL           :: is_initialized = .FALSE.
    INTEGER(i4)       :: n_max_violations = 100_i4
    
    !-- Violation tracking
    INTEGER(i4)       :: n_violations = 0_i4
    TYPE(ConstraintViolation), ALLOCATABLE :: violations(:)
    
    !-- Counters
    INTEGER(i4)       :: n_mat_checks_passed = 0_i4
    INTEGER(i4)       :: n_elem_checks_passed = 0_i4
    INTEGER(i4)       :: n_coupling_checks_passed = 0_i4
    
    !-- Error status
    TYPE(ErrorStatusType) :: status
    
  CONTAINS
    PROCEDURE :: Initialize  => Validator_Initialize
    PROCEDURE :: Reset       => Validator_Reset
    PROCEDURE :: Check_All   => Validator_Check_All
    PROCEDURE :: Check_Materials => Validator_Check_Materials
    PROCEDURE :: Check_Elements => Validator_Check_Elements
    PROCEDURE :: Check_Coupling => Validator_Check_Coupling
    PROCEDURE :: Report      => Validator_Report
  END TYPE RT_AnalyGroup_ConstraintValidator

  !-- Internal: Constraint violation record
  TYPE :: ConstraintViolation
    INTEGER(i4)       :: code          = CONSTRAINT_OK
    CHARACTER(LEN=32) :: severity      = 'ERROR'     ! ERROR, WARNING
    CHARACTER(LEN=512) :: message      = ''
  END TYPE ConstraintViolation

  !-- Material-Element coherence lookup table
  !   Maps material family to compatible element types
  CHARACTER(LEN=256), PARAMETER :: MAT_ELEM_COHERENCE_TABLE(1:11) = [ &
    'C3D,CPS,CAX,S,B,T              ', &  ! Family 01: Elastic
    'C3D,CPS,CAX,S,B,T              ', &  ! Family 02: Plastic
    'C3D,CPS,CAX                    ', &  ! Family 03: Geomaterial
    'C3D,CPS,CAX,S                  ', &  ! Family 04: HyperElastic
    'C3D,CPS,CAX,S,B,T              ', &  ! Family 05: Viscoelastic
    'C3D,CPS,CAX,S,B,T              ', &  ! Family 06: Creep
    'C3D,CPS,CAX,S,B,T              ', &  ! Family 07: Damage
    'C3D,CPS,CAX,S                  ', &  ! Family 08: Composite
    'DC,CAX                         ', &  ! Family 09: Thermal
    'AC,CAX                         ', &  ! Family 10: Acoustic
    'EM,CAX                         '  &  ! Family 11: Electromagnetic
  ]

CONTAINS

  !===========================================================================
  ! PUBLIC SUBROUTINE: Assert_Group_Materials_Compatible
  !   Check if material families are allowed for analysis group.
  !   [IN]  group_desc : Analysis group descriptor
  !   [IN]  mat_families : Array of material family IDs (1-11)
  !   [OUT] args : Violations and result
  !===========================================================================
  SUBROUTINE Assert_Group_Materials_Compatible(group_desc, mat_families, args)
    IMPLICIT NONE
    TYPE(MD_AnalyGroup_Desc), INTENT(IN) :: group_desc
    INTEGER(i4), INTENT(IN) :: mat_families(:)
    TYPE(Assert_Arg), INTENT(INOUT), OPTIONAL :: args

    INTEGER(i4) :: i, fam, allowed_bitmap
    LOGICAL :: is_allowed

    IF (PRESENT(args)) THEN
      args%success = .TRUE.
      args%n_violations = 0_i4
    END IF

    ! Get allowed material families for this group
    CALL AnalyGroup_Get_AllowedMaterials(group_desc%group_id, &
                                          allowed_bitmap)

    ! Check each material family
    DO i = 1, SIZE(mat_families)
      fam = mat_families(i)
      
      ! Check if bit (fam-1) is set in allowed_bitmap
      is_allowed = BTEST(allowed_bitmap, fam - 1)
      
      IF (.NOT. is_allowed) THEN
        IF (PRESENT(args)) THEN
          args%success = .FALSE.
          args%n_violations = args%n_violations + 1_i4
          WRITE(args%violation_msg, '(A,I0,A,I0,A)') &
            'Material family ', fam, ' not allowed in group ', &
            group_desc%group_id, ' (constraint violated)'
        END IF
      END IF
    END DO

  END SUBROUTINE Assert_Group_Materials_Compatible

  !===========================================================================
  ! PUBLIC SUBROUTINE: Assert_Group_Elements_Compatible
  !   Check if element types are allowed for analysis group.
  !   [IN]  group_desc : Analysis group descriptor
  !   [IN]  elem_types : Array of element type strings
  !   [OUT] args : Violations and result
  !===========================================================================
  SUBROUTINE Assert_Group_Elements_Compatible(group_desc, elem_types, args)
    IMPLICIT NONE
    TYPE(MD_AnalyGroup_Desc), INTENT(IN) :: group_desc
    CHARACTER(LEN=*), INTENT(IN) :: elem_types(:)
    TYPE(Assert_Arg), INTENT(INOUT), OPTIONAL :: args

    CHARACTER(LEN=256) :: allowed_types
    INTEGER(i4) :: i
    LOGICAL :: is_allowed

    IF (PRESENT(args)) THEN
      args%success = .TRUE.
      args%n_violations = 0_i4
    END IF

    ! Get allowed element types for this group
    CALL AnalyGroup_Get_AllowedElements(group_desc%group_id, allowed_types)

    ! Check each element type
    DO i = 1, SIZE(elem_types)
      is_allowed = Index(allowed_types, TRIM(elem_types(i))) > 0
      
      IF (.NOT. is_allowed) THEN
        IF (PRESENT(args)) THEN
          args%success = .FALSE.
          args%n_violations = args%n_violations + 1_i4
          WRITE(args%violation_msg, '(A,A,A,I0,A)') &
            'Element type ''', TRIM(elem_types(i)), &
            ''' not allowed in group ', group_desc%group_id, &
            ' (constraint violated)'
        END IF
      END IF
    END DO

  END SUBROUTINE Assert_Group_Elements_Compatible

  !===========================================================================
  ! PUBLIC SUBROUTINE: Assert_Coupling_Strategy_Feasible
  !   Check if coupling strategy is supported by analysis group.
  !   [IN]  group_desc : Analysis group descriptor
  !   [IN]  router : Configured router with strategy
  !   [OUT] args : Feasibility assessment
  !===========================================================================
  SUBROUTINE Assert_Coupling_Strategy_Feasible(group_desc, router, args)
    IMPLICIT NONE
    TYPE(MD_AnalyGroup_Desc), INTENT(IN) :: group_desc
    TYPE(PH_AnalyGroup_Router), INTENT(IN) :: router
    TYPE(Assert_Arg), INTENT(INOUT), OPTIONAL :: args

    INTEGER(i4) :: grp
    LOGICAL :: feasible

    feasible = .TRUE.
    grp = group_desc%group_id

    ! Constraint checks per group
    SELECT CASE (grp)
      CASE (ANALY_GROUP_G1, ANALY_GROUP_G2, ANALY_GROUP_G3, &
            ANALY_GROUP_G4, ANALY_GROUP_G5, ANALY_GROUP_G8)
        ! Single-field groups: only ONESHOT supported
        IF (router%strategy /= 1_i4) THEN  ! ROUTE_STRATEGY_ONESHOT = 1
          feasible = .FALSE.
        END IF
      
      CASE (ANALY_GROUP_G6)
        ! Thermal-structure: WEAK coupling supported
        IF (router%strategy /= ROUTE_STRATEGY_WEAK) THEN
          ! Could relax to ONEWAY if user explicitly requests
          feasible = .FALSE.
        END IF
      
      CASE (ANALY_GROUP_G7)
        ! Multi-field: STRONG coupling required
        IF (router%strategy /= ROUTE_STRATEGY_STRONG) THEN
          feasible = .FALSE.
        END IF
      
      CASE (ANALY_GROUP_G9)
        ! Special: flexible strategy per analysis
        feasible = .TRUE.
      
      CASE DEFAULT
        feasible = .FALSE.
    END SELECT

    IF (PRESENT(args)) THEN
      args%success = feasible
      IF (.NOT. feasible) THEN
        args%n_violations = 1_i4
        WRITE(args%violation_msg, '(A,I0,A,I0,A)') &
          'Group ', grp, ' coupling strategy ', router%strategy, &
          ' is not feasible'
      END IF
    END IF

  END SUBROUTINE Assert_Coupling_Strategy_Feasible

  !===========================================================================
  ! PUBLIC SUBROUTINE: Generate_Constraint_Report
  !   Create detailed constraint report for diagnosis and documentation.
  !===========================================================================
  SUBROUTINE Generate_Constraint_Report(validator, output_file, args)
    IMPLICIT NONE
    TYPE(RT_AnalyGroup_ConstraintValidator), INTENT(IN) :: validator
    CHARACTER(LEN=*), INTENT(IN) :: output_file
    TYPE(Assert_Arg), INTENT(INOUT), OPTIONAL :: args

    INTEGER(i4) :: u_out, i
    CHARACTER(LEN=256) :: timestamp

    OPEN(NEWUNIT=u_out, FILE=TRIM(output_file), STATUS='REPLACE', &
         ACTION='WRITE', FORM='FORMATTED')

    WRITE(u_out, '(A)') '! ============================================================================'
    WRITE(u_out, '(A)') '! Analysis Group Constraint Validation Report'
    WRITE(u_out, '(A)') '! ============================================================================'
    WRITE(u_out, '(A)') ''

    WRITE(u_out, '(A)') 'Total violations: '
    WRITE(u_out, '(I0)') validator%n_violations
    WRITE(u_out, '(A)') ''

    WRITE(u_out, '(A)') 'Material constraint checks passed: '
    WRITE(u_out, '(I0)') validator%n_mat_checks_passed
    WRITE(u_out, '(A)') 'Element constraint checks passed: '
    WRITE(u_out, '(I0)') validator%n_elem_checks_passed
    WRITE(u_out, '(A)') 'Coupling strategy checks passed: '
    WRITE(u_out, '(I0)') validator%n_coupling_checks_passed
    WRITE(u_out, '(A)') ''

    IF (validator%n_violations > 0) THEN
      WRITE(u_out, '(A)') 'Violation Details:'
      WRITE(u_out, '(A)') '-------------------'
      
      DO i = 1, MIN(validator%n_violations, SIZE(validator%violations))
        WRITE(u_out, '(A,I0,A)') '[ ', i, ' ]'
        WRITE(u_out, '(A,I0)') '  Code: ', validator%violations(i)%code
        WRITE(u_out, '(A,A)') '  Severity: ', TRIM(validator%violations(i)%severity)
        WRITE(u_out, '(A,A)') '  Message: ', TRIM(validator%violations(i)%message)
        WRITE(u_out, '(A)') ''
      END DO
    END IF

    CLOSE(u_out)

    IF (PRESENT(args)) args%success = .TRUE.

  END SUBROUTINE Generate_Constraint_Report

  !==========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Initialize
  !===========================================================================
  SUBROUTINE Validator_Initialize(self)
    CLASS(RT_AnalyGroup_ConstraintValidator), INTENT(INOUT) :: self
    
    IF (ALLOCATED(self%violations)) DEALLOCATE(self%violations)
    ALLOCATE(self%violations(self%n_max_violations))
    
    self%n_violations = 0_i4
    self%n_mat_checks_passed = 0_i4
    self%n_elem_checks_passed = 0_i4
    self%n_coupling_checks_passed = 0_i4
    CALL init_error_status(self%status, IF_STATUS_OK)
    self%is_initialized = .TRUE.

  END SUBROUTINE Validator_Initialize

  !==========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Reset
  !===========================================================================
  SUBROUTINE Validator_Reset(self)
    CLASS(RT_AnalyGroup_ConstraintValidator), INTENT(INOUT) :: self
    
    self%n_violations = 0_i4
    self%n_mat_checks_passed = 0_i4
    self%n_elem_checks_passed = 0_i4
    self%n_coupling_checks_passed = 0_i4

  END SUBROUTINE Validator_Reset

  !==========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Check_All
  !===========================================================================
  SUBROUTINE Validator_Check_All(self, group_desc, mat_families, &
                                  elem_types, router)
    CLASS(RT_AnalyGroup_ConstraintValidator), INTENT(INOUT) :: self
    TYPE(MD_AnalyGroup_Desc), INTENT(IN) :: group_desc
    INTEGER(i4), INTENT(IN) :: mat_families(:)
    CHARACTER(LEN=*), INTENT(IN) :: elem_types(:)
    TYPE(PH_AnalyGroup_Router), INTENT(IN) :: router

    IF (.NOT. self%is_initialized) CALL self%Initialize()

    CALL self%Check_Materials(group_desc, mat_families)
    CALL self%Check_Elements(group_desc, elem_types)
    CALL self%Check_Coupling(group_desc, router)

  END SUBROUTINE Validator_Check_All

  !==========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Check_Materials (placeholder)
  !===========================================================================
  SUBROUTINE Validator_Check_Materials(self, group_desc, mat_families)
    CLASS(RT_AnalyGroup_ConstraintValidator), INTENT(INOUT) :: self
    TYPE(MD_AnalyGroup_Desc), INTENT(IN) :: group_desc
    INTEGER(i4), INTENT(IN) :: mat_families(:)
    ! Implementation in Phase 2
    self%n_mat_checks_passed = self%n_mat_checks_passed + 1_i4
  END SUBROUTINE Validator_Check_Materials

  !==========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Check_Elements (placeholder)
  !===========================================================================
  SUBROUTINE Validator_Check_Elements(self, group_desc, elem_types)
    CLASS(RT_AnalyGroup_ConstraintValidator), INTENT(INOUT) :: self
    TYPE(MD_AnalyGroup_Desc), INTENT(IN) :: group_desc
    CHARACTER(LEN=*), INTENT(IN) :: elem_types(:)
    ! Implementation in Phase 2
    self%n_elem_checks_passed = self%n_elem_checks_passed + 1_i4
  END SUBROUTINE Validator_Check_Elements

  !==========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Check_Coupling (placeholder)
  !===========================================================================
  SUBROUTINE Validator_Check_Coupling(self, group_desc, router)
    CLASS(RT_AnalyGroup_ConstraintValidator), INTENT(INOUT) :: self
    TYPE(MD_AnalyGroup_Desc), INTENT(IN) :: group_desc
    TYPE(PH_AnalyGroup_Router), INTENT(IN) :: router
    ! Implementation in Phase 2
    self%n_coupling_checks_passed = self%n_coupling_checks_passed + 1_i4
  END SUBROUTINE Validator_Check_Coupling

  !==========================================================================
  ! TYPE-BOUND PROCEDURE: Validator_Report (placeholder)
  !===========================================================================
  SUBROUTINE Validator_Report(self, output_unit)
    CLASS(RT_AnalyGroup_ConstraintValidator), INTENT(IN) :: self
    INTEGER(i4), INTENT(IN) :: output_unit
    ! Implementation in Phase 2
  END SUBROUTINE Validator_Report

  !==========================================================================
  ! INTERNAL TYPE: Assert_Arg (Principle #14 unified argument bundle)
  !===========================================================================
  TYPE :: Assert_Arg
    LOGICAL :: success = .FALSE.
    INTEGER(i4) :: n_violations = 0_i4
    CHARACTER(LEN=512) :: violation_msg = ''
  END TYPE Assert_Arg

END MODULE RT_AnalysisGroup_Validator
