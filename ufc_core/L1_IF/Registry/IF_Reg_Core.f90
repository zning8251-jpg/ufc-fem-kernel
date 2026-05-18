!===============================================================================
! MODULE: IF_Reg_Core
! LAYER:  L1_IF
! DOMAIN: Registry
! ROLE:   _Core
! BRIEF:  Model registration, versioning, degradation detection, audit log.
!===============================================================================
!
! TYPE Four-Type Mapping:
!   ModelEntry       [Desc]  Model registration entry
!   AuditLogEntry    [State] Audit log record
!   ModelRegistry    [State] Global model registry
!
! Contents (A-Z):
!   Subroutines:
!     AlertDegradation         [P3] Generate degradation alert message
!     BenchmarkModel           [P2] Get model benchmark score
!     ExportAuditReport        [P3] Export audit log to file
!     GetModelHistory          [P3] Get version history
!     Governance_Finalize      [P0] Finalize governance
!     Governance_Init          [P0] Initialize governance
!     IncrementModelVersion    [P0] Increment model version
!     ModelAuditLog            [P1] Record audit log entry
!     QueryAuditLog            [P3] Query audit entries
!     RollbackModelVersion     [P0] Rollback to target version
!     UnregisterModel          [P0] Deactivate model
!   Functions:
!     CheckModelDegradation    [P2] Check for performance regression
!     QueryModelRegistry       [P2] Find model by name
!     RegisterModel            [P0] Register new model
!
! Status: Production | Last verified: 2026-04-28
!===============================================================================

MODULE IF_Reg_Core
  USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: OUTPUT_UNIT
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Public Interface
  !---------------------------------------------------------------------------
  PUBLIC :: ModelRegistry, ModelEntry, AuditLogEntry
  PUBLIC :: RegisterModel, UnregisterModel, QueryModelRegistry
  PUBLIC :: IncrementModelVersion, RollbackModelVersion, GetModelHistory
  PUBLIC :: CheckModelDegradation, BenchmarkModel, AlertDegradation
  PUBLIC :: ModelAuditLog, QueryAuditLog, ExportAuditReport
  PUBLIC :: Governance_Init, Governance_Finalize

  !---------------------------------------------------------------------------
  ! Constants
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: IF_MAX_MODELS = 1000
  INTEGER(i4), PARAMETER :: IF_MAX_AUDIT_ENTRIES = 10000
  INTEGER(i4), PARAMETER :: IF_MAX_NAME_LEN = 128
  INTEGER(i4), PARAMETER :: IF_MAX_VERSION_HISTORY = 100

  !---------------------------------------------------------------------------
  ! Types
  !---------------------------------------------------------------------------

  !-----------------------------------------------------------------------------
  ! TYPE: ModelEntry  [Desc]  (canonical: IF_Reg_ModelEntry_Desc)
  !-----------------------------------------------------------------------------

  TYPE :: ModelEntry
    INTEGER(i8)              :: model_id = 0
    CHARACTER(IF_MAX_NAME_LEN)     :: model_name = ''
    CHARACTER(IF_MAX_NAME_LEN)     :: model_type = ''      ! AI, Classic, User
    CHARACTER(32)               :: version = '0.0.0'
    INTEGER(i4) :: version_count = 0
    REAL(wp)                    :: benchmark_score = 0.0_wp
    REAL(wp)                    :: baseline_score = 0.0_wp
    LOGICAL                     :: active = .FALSE.
    INTEGER(i8)              :: created_time = 0
    INTEGER(i8)              :: updated_time = 0
    CHARACTER(IF_MAX_NAME_LEN)     :: version_history(IF_MAX_VERSION_HISTORY)
  END TYPE ModelEntry

  !-----------------------------------------------------------------------------
  ! TYPE: AuditLogEntry  [State]  (canonical: IF_Reg_AuditLog_State)
  !-----------------------------------------------------------------------------

  TYPE :: AuditLogEntry
    INTEGER(i8)              :: entry_id = 0
    INTEGER(i8)              :: model_id = 0
    CHARACTER(32)               :: operation = ''       ! REGISTER, UPDATE, ROLLBACK
    CHARACTER(32)               :: old_version = ''
    CHARACTER(32)               :: new_version = ''
    CHARACTER(256)              :: description = ''
    INTEGER(i8)              :: timestamp = 0
    REAL(wp)                    :: performance_delta = 0.0_wp
  END TYPE AuditLogEntry

  !-----------------------------------------------------------------------------
  ! TYPE: ModelRegistry  [State]  (canonical: IF_Reg_Registry_State)
  !-----------------------------------------------------------------------------

  TYPE :: ModelRegistry
    TYPE(ModelEntry)            :: models(IF_MAX_MODELS)
    INTEGER(i4) :: n_models = 0
    TYPE(AuditLogEntry)         :: audit_log(IF_MAX_AUDIT_ENTRIES)
    INTEGER(i4) :: n_audit_entries = 0
    LOGICAL                     :: initialized = .FALSE.
  END TYPE ModelRegistry

  !---------------------------------------------------------------------------
  ! Module Variables
  !---------------------------------------------------------------------------
  TYPE(ModelRegistry), SAVE, PROTECTED :: g_model_registry

CONTAINS

  SUBROUTINE Governance_Init()
    IF (g_model_registry%initialized) RETURN
    g_model_registry%n_models = 0
    g_model_registry%n_audit_entries = 0
    g_model_registry%initialized = .TRUE.
  END SUBROUTINE

  SUBROUTINE Governance_Finalize()
    g_model_registry%initialized = .FALSE.
    g_model_registry%n_models = 0
    g_model_registry%n_audit_entries = 0
  END SUBROUTINE

  FUNCTION RegisterModel(model_name, model_type, benchmark_score) RESULT(model_id)
    CHARACTER(*), INTENT(IN) :: model_name, model_type
    REAL(wp), INTENT(IN), OPTIONAL :: benchmark_score
    INTEGER(i8) :: model_id
    
    IF (.NOT. g_model_registry%initialized) CALL Governance_Init()
    
    g_model_registry%n_models = g_model_registry%n_models + 1
    model_id = g_model_registry%n_models
    
    IF (model_id > IF_MAX_MODELS) THEN
      model_id = -1
      RETURN
    END IF
    
    ASSOCIATE(m => g_model_registry%models(model_id))
      m%model_id = model_id
      m%model_name = TRIM(model_name)
      m%model_type = TRIM(model_type)
      m%version = '1.0.0'
      m%version_count = 1
      IF (PRESENT(benchmark_score)) THEN
        m%benchmark_score = benchmark_score
        m%baseline_score = benchmark_score
      END IF
      m%active = .TRUE.
      m%version_history(1) = '1.0.0'
    END ASSOCIATE
    
    CALL ModelAuditLog(model_id, 'REGISTER', '', '1.0.0', 'Model registered')
  END FUNCTION

  SUBROUTINE UnregisterModel(model_id)
    INTEGER(i8), INTENT(IN) :: model_id
    IF (model_id < 1 .OR. model_id > g_model_registry%n_models) RETURN
    g_model_registry%models(model_id)%active = .FALSE.
    CALL ModelAuditLog(model_id, 'UNREGISTER', &
                       g_model_registry%models(model_id)%version, '', 'Model unregistered')
  END SUBROUTINE

  FUNCTION QueryModelRegistry(model_name) RESULT(model_id)
    CHARACTER(*), INTENT(IN) :: model_name
    INTEGER(i8) :: model_id
    INTEGER(i4) :: i
    
    model_id = 0
    DO i = 1, g_model_registry%n_models
      IF (TRIM(g_model_registry%models(i)%model_name) == TRIM(model_name)) THEN
        model_id = i
        RETURN
      END IF
    END DO
  END FUNCTION

  SUBROUTINE IncrementModelVersion(model_id, new_benchmark)
    INTEGER(i8), INTENT(IN) :: model_id
    REAL(wp), INTENT(IN), OPTIONAL :: new_benchmark
    CHARACTER(32) :: old_ver, new_ver
    INTEGER(i4) :: major, minor, patch
    
    IF (model_id < 1 .OR. model_id > g_model_registry%n_models) RETURN
    IF (.NOT. g_model_registry%models(model_id)%active) RETURN
    
    ASSOCIATE(m => g_model_registry%models(model_id))
      old_ver = m%version
      m%version_count = m%version_count + 1
      
      IF (m%version_count <= IF_MAX_VERSION_HISTORY) THEN
        WRITE(new_ver, '(I0,".0.0")') m%version_count
        m%version_history(m%version_count) = new_ver
        m%version = new_ver
      END IF
      
      IF (PRESENT(new_benchmark)) THEN
        m%benchmark_score = new_benchmark
      END IF
      
      CALL ModelAuditLog(model_id, 'UPDATE', old_ver, new_ver, 'Version incremented')
    END ASSOCIATE
  END SUBROUTINE

  SUBROUTINE RollbackModelVersion(model_id, target_version)
    INTEGER(i8), INTENT(IN) :: model_id
    INTEGER(i4), INTENT(IN) :: target_version
    CHARACTER(32) :: old_ver, new_ver
    
    IF (model_id < 1 .OR. model_id > g_model_registry%n_models) RETURN
    IF (target_version < 1 .OR. target_version > g_model_registry%models(model_id)%version_count) RETURN
    
    ASSOCIATE(m => g_model_registry%models(model_id))
      old_ver = m%version
      m%version = m%version_history(target_version)
      new_ver = m%version
      CALL ModelAuditLog(model_id, 'ROLLBACK', old_ver, new_ver, 'Version rolled back')
    END ASSOCIATE
  END SUBROUTINE

  SUBROUTINE GetModelHistory(model_id, history, n_versions)
    INTEGER(i8), INTENT(IN) :: model_id
    CHARACTER(*), INTENT(OUT) :: history(:)
    INTEGER(i4), INTENT(OUT) :: n_versions
    
    INTEGER(i4) :: i
    
    n_versions = 0
    IF (model_id < 1 .OR. model_id > g_model_registry%n_models) RETURN
    
    n_versions = g_model_registry%models(model_id)%version_count
    DO i = 1, MIN(n_versions, SIZE(history))
      history(i) = g_model_registry%models(model_id)%version_history(i)
    END DO
  END SUBROUTINE

  FUNCTION CheckModelDegradation(model_id, threshold) RESULT(is_degraded)
    INTEGER(i8), INTENT(IN) :: model_id
    REAL(wp), INTENT(IN), OPTIONAL :: threshold
    LOGICAL :: is_degraded
    
    REAL(wp) :: thresh
    
    is_degraded = .FALSE.
    IF (model_id < 1 .OR. model_id > g_model_registry%n_models) RETURN
    
    thresh = 0.1_wp  ! Default 10% degradation threshold
    IF (PRESENT(threshold)) thresh = threshold
    
    ASSOCIATE(m => g_model_registry%models(model_id))
      IF (m%baseline_score > 0.0_wp) THEN
        is_degraded = (m%benchmark_score < m%baseline_score * (1.0_wp - thresh))
      END IF
    END ASSOCIATE
  END FUNCTION

  SUBROUTINE BenchmarkModel(model_id, score)
    INTEGER(i8), INTENT(IN) :: model_id
    REAL(wp), INTENT(OUT) :: score
    
    score = 0.0_wp
    IF (model_id < 1 .OR. model_id > g_model_registry%n_models) RETURN
    score = g_model_registry%models(model_id)%benchmark_score
  END SUBROUTINE

  SUBROUTINE AlertDegradation(model_id, message)
    INTEGER(i8), INTENT(IN) :: model_id
    CHARACTER(*), INTENT(OUT) :: message
    
    IF (model_id < 1 .OR. model_id > g_model_registry%n_models) THEN
      message = 'Invalid model ID'
      RETURN
    END IF
    
    WRITE(message, '(A,A,A,F6.2,A)') &
      'Model ', TRIM(g_model_registry%models(model_id)%model_name), &
      ' degraded by ', &
      (1.0_wp - g_model_registry%models(model_id)%benchmark_score / &
       g_model_registry%models(model_id)%baseline_score) * 100.0_wp, '%'
  END SUBROUTINE

  SUBROUTINE ModelAuditLog(model_id, operation, old_version, new_version, description)
    INTEGER(i8), INTENT(IN) :: model_id
    CHARACTER(*), INTENT(IN) :: operation, old_version, new_version, description
    
    INTEGER(i8) :: count
    
    g_model_registry%n_audit_entries = g_model_registry%n_audit_entries + 1
    IF (g_model_registry%n_audit_entries > IF_MAX_AUDIT_ENTRIES) RETURN
    
    ASSOCIATE(a => g_model_registry%audit_log(g_model_registry%n_audit_entries))
      a%entry_id = g_model_registry%n_audit_entries
      a%model_id = model_id
      a%operation = TRIM(operation)
      a%old_version = TRIM(old_version)
      a%new_version = TRIM(new_version)
      a%description = TRIM(description)
      CALL SYSTEM_CLOCK(count)
      a%timestamp = count
    END ASSOCIATE
  END SUBROUTINE

  SUBROUTINE QueryAuditLog(model_id, entries, n_entries)
    INTEGER(i8), INTENT(IN) :: model_id
    TYPE(AuditLogEntry), INTENT(OUT) :: entries(:)
    INTEGER(i4), INTENT(OUT) :: n_entries
    
    INTEGER(i4) :: i, j
    
    n_entries = 0
    j = 0
    
    DO i = 1, g_model_registry%n_audit_entries
      IF (g_model_registry%audit_log(i)%model_id == model_id .OR. model_id == 0) THEN
        j = j + 1
        IF (j <= SIZE(entries)) THEN
          entries(j) = g_model_registry%audit_log(i)
          n_entries = j
        END IF
      END IF
    END DO
  END SUBROUTINE

  SUBROUTINE ExportAuditReport(filename)
    CHARACTER(*), INTENT(IN) :: filename
    
    INTEGER(i4) :: unit, i
    
    OPEN(NEWUNIT=unit, FILE=filename, STATUS='REPLACE')
    
    WRITE(unit, '(A)') '# UFC Model Governance Audit Report'
    WRITE(unit, '(A,I0)') '# Total models: ', g_model_registry%n_models
    WRITE(unit, '(A,I0)') '# Total audit entries: ', g_model_registry%n_audit_entries
    WRITE(unit, '(A)') '#'
    WRITE(unit, '(A)') '# model_id, operation, old_ver, new_ver, description, timestamp'
    
    DO i = 1, g_model_registry%n_audit_entries
      ASSOCIATE(a => g_model_registry%audit_log(i))
        WRITE(unit, '(I0,",",A,",",A,",",A,",",A,",",I0)') &
          a%model_id, TRIM(a%operation), TRIM(a%old_version), &
          TRIM(a%new_version), TRIM(a%description), a%timestamp
      END ASSOCIATE
    END DO
    
    CLOSE(unit)
  END SUBROUTINE

END MODULE IF_Reg_Core