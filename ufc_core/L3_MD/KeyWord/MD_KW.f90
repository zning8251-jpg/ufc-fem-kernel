!===================================================================
! FILE   : MD_KW.f90  (LEGACY multi-module file)
! LAYER  : L3_MD
! DOMAIN : KeyWord (KW)
! ROLE   : Aggregate / Legacy
! BRIEF  : Keyword registration, mapping, coverage auditing and
!          extension for ABAQUS INP parsing.
!          Contains 6+ MODULE definitions (MD_KW_Coverage_Type etc.).
!          Violates MODULE=FileName rule -- retained as-is;
!          splitting would break import chains.
!===================================================================
MODULE MD_KW_Coverage_Type
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, only: wp, i4
  
  implicit none
  private
  
  ! ===================================================================
  ! Public Types
  ! ===================================================================
  public :: KW_Coverage_Report
  public :: KW_Priority_Check
  
  ! ===================================================================
  ! Public Procedures
  ! ===================================================================
  public :: KW_Audit_P0_Must
  public :: KW_Audit_P1_Important
  public :: KW_Audit_P2_Optional
  public :: KW_Generate_Report
  
  ! ===================================================================
  ! Priority Constants (from Plan Section P3)
  ! ===================================================================
  integer(i4), parameter, public :: KW_PRIORITY_P0 = 0_i4  ! Must-have
  integer(i4), parameter, public :: KW_PRIORITY_P1 = 1_i4  ! Important
  integer(i4), parameter, public :: KW_PRIORITY_P2 = 2_i4  ! Can-defer
  
  !=============================================================================
  !> @brief Coverage report type
  !! @details Tracks keyword coverage by priority level
  !!   Theory: Coverage metrics: n_p0_total, n_p0_covered, coverage percentage = (covered/total) �?100%
  type, public :: KW_Coverage_Report
    integer(i4) :: n_p0_total = 0_i4              ! P0 total keywords n_p0_total  ? ?
    integer(i4) :: n_p0_covered = 0_i4            ! P0 covered keywords n_p0_covered  ? ?
    integer(i4) :: n_p1_total = 0_i4              ! P1 total keywords n_p1_total  ? ?
    integer(i4) :: n_p1_covered = 0_i4            ! P1 covered keywords n_p1_covered  ? ?
    integer(i4) :: n_p2_total = 0_i4              ! P2 total keywords n_p2_total  ? ?
    integer(i4) :: n_p2_covered = 0_i4            ! P2 covered keywords n_p2_covered  ? ?
    
    character(len=64), allocatable :: p0_missing(:)  ! Missing P0 keywords
    character(len=64), allocatable :: p1_missing(:)  ! Missing P1 keywords
    
    logical :: p0_complete = .false.              ! P0 complete flag
    real(wp) :: p0_coverage = 0.0_wp              ! P0 coverage percentage  ?[0,100]  ? ?
    real(wp) :: p1_coverage = 0.0_wp              ! P1 coverage percentage  ?[0,100]  ? ?
    real(wp) :: total_coverage = 0.0_wp            ! Total coverage percentage  ?[0,100]  ? ?
    
  CONTAINS
    PROCEDURE, PUBLIC :: ComputeCoverage => KW_Coverage_Calc
    PROCEDURE, PUBLIC :: Print => KW_Coverage_Print
  END TYPE KW_Coverage_Report
  
  !=============================================================================
  !> @brief Priority check type
  !! @details Checks keyword priority and coverage status
  TYPE, PUBLIC :: KW_Priority_Check
    character(len=32) :: keyword = ""             ! Keyword name
    integer(i4) :: priority = KW_PRIORITY_P0       ! Priority level  ? ?
    logical :: is_covered = .false.                ! Coverage flag
    character(len=128) :: notes = ""               ! Notes
  END TYPE KW_Priority_Check
  
  ! ===================================================================
  ! P0 Must-Have Keywords (from Plan Section P3 table)
  ! ===================================================================
  integer(i4), parameter :: N_P0_KEYWORDS = 24
  character(len=32), parameter :: P0_KEYWORDS(N_P0_KEYWORDS) = [ &
    character(len=32) :: &
    "*NODE             ", "*ELEMENT          ", "*STEP             ", &
    "*STATIC           ", "*BOUNDARY         ", "*CLOAD            ", &
    "*DLOAD            ", "*MATERIAL         ", "*ELASTIC          ", &
    "*PLASTIC          ", "*SURFACE          ", "*CONTACT PAIR     ", &
    "*SURFACE INTERACT ", "*FIELD OUTPUT     ", "*HISTORY OUTPUT   ", &
    "*SOLID SECTION    ", "*SHELL SECTION    ", "*NSET             ", &
    "*ELSET            ", "*PART             ", "*END PART         ", &
    "*ASSEMBLY         ", "*INSTANCE         ", "*END INSTANCE     " &
  ]
  
  ! ===================================================================
  ! P1 Important Keywords
  ! ===================================================================
  integer(i4), parameter :: N_P1_KEYWORDS = 12
  character(len=32), parameter :: P1_KEYWORDS(N_P1_KEYWORDS) = [ &
    character(len=32) :: &
    "*COUPLING         ", "*TIE              ", "*MPC              ", &
    "*INITIAL CONDITI  ", "*PREDEFINED FIELD ", "*AMPLITUDE        ", &
    "*DYNAMIC          ", "*HEAT TRANSFER    ", "*BEAM SECTION     ", &
    "*RESTART          ", "*ORIENTATION      ", "*DENSITY          " &
  ]

contains

  ! ===================================================================
  ! P0 Must-Have Audit
  ! ===================================================================
  
  !=============================================================================
  !> @brief Audit P0 must-have keyword coverage (legacy interface)
  !! @details Audits P0 keyword coverage against covered keywords list
  !! @param[in] covered_kws Covered keywords array
  !! @param[out] report Coverage report
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !=============================================================================
  SUBROUTINE KW_Audit_P0_Must(covered_kws, report, status)
    character(len=*), intent(in) :: covered_kws(:)
    type(KW_Coverage_Report), intent(out) :: report
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i_kw, j_kw, n_missing
    logical :: found
    character(len=64), allocatable :: missing_temp(:)
    
    if (present(status)) call init_error_status(status)
    
    report%n_p0_total = N_P0_KEYWORDS
    report%n_p0_covered = 0_i4
    n_missing = 0_i4
    
    allocate(missing_temp(N_P0_KEYWORDS))
    
    ! Check each P0 keyword
    do i_kw = 1, N_P0_KEYWORDS
      found = .false.
      
      do j_kw = 1, size(covered_kws)
        if (trim(adjustl(P0_KEYWORDS(i_kw))) == trim(adjustl(covered_kws(j_kw)))) then
          found = .true.
          exit
        end if
      end do
      
      if (found) then
        report%n_p0_covered = report%n_p0_covered + 1
      else
        n_missing = n_missing + 1
        missing_temp(n_missing) = trim(P0_KEYWORDS(i_kw))
      end if
    end do
    
    ! Store missing keywords
    if (n_missing > 0) then
      allocate(report%p0_missing(n_missing))
      report%p0_missing = missing_temp(1:n_missing)
    end if
    
    deallocate(missing_temp)
    
    ! Compute coverage
    call report%ComputeCoverage()
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine KW_Audit_P0_Must

  ! ===================================================================
  ! P1 Important Audit
  ! ===================================================================
  
  !=============================================================================
  !> @brief Audit P1 important keyword coverage (legacy interface)
  !! @details Audits P1 keyword coverage against covered keywords list
  !! @param[in] covered_kws Covered keywords array
  !! @param[inout] report Coverage report
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !=============================================================================
  SUBROUTINE KW_Audit_P1_Important(covered_kws, report, status)
    character(len=*), intent(in) :: covered_kws(:)
    type(KW_Coverage_Report), intent(inout) :: report
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i_kw, j_kw, n_missing
    logical :: found
    character(len=64), allocatable :: missing_temp(:)
    
    if (present(status)) call init_error_status(status)
    
    report%n_p1_total = N_P1_KEYWORDS
    report%n_p1_covered = 0_i4
    n_missing = 0_i4
    
    allocate(missing_temp(N_P1_KEYWORDS))
    
    do i_kw = 1, N_P1_KEYWORDS
      found = .false.
      
      do j_kw = 1, size(covered_kws)
        if (index(trim(P1_KEYWORDS(i_kw)), trim(covered_kws(j_kw))) > 0) then
          found = .true.
          exit
        end if
      end do
      
      if (found) then
        report%n_p1_covered = report%n_p1_covered + 1
      else
        n_missing = n_missing + 1
        missing_temp(n_missing) = trim(P1_KEYWORDS(i_kw))
      end if
    end do
    
    if (n_missing > 0) then
      allocate(report%p1_missing(n_missing))
      report%p1_missing = missing_temp(1:n_missing)
    end if
    
    deallocate(missing_temp)
    
    call report%ComputeCoverage()
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE KW_Audit_P1_Important

  ! ===================================================================
  ! P2 Optional Audit
  ! ===================================================================
  
  SUBROUTINE KW_Audit_P2_Optional(covered_kws, report, status)
    !! Audit P2 optional keyword coverage
    character(len=*), intent(in) :: covered_kws(:)
    type(KW_Coverage_Report), intent(inout) :: report
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4), parameter :: N_P2 = 6
    character(len=32), parameter :: P2_KWS(N_P2) = [ &
      "*FREQUENCY  ", "*BUCKLE     ", "*RESTART    ", &
      "*ORIENTATION", "*MASS       ", "*DAMPING    " &
    ]
    
    integer(i4) :: i_kw, j_kw
    logical :: found
    
    if (present(status)) call init_error_status(status)
    
    report%n_p2_total = N_P2
    report%n_p2_covered = 0_i4
    
    do i_kw = 1, N_P2
      found = .false.
      
      do j_kw = 1, size(covered_kws)
        if (index(trim(P2_KWS(i_kw)), trim(covered_kws(j_kw))) > 0) then
          found = .true.
          exit
        end if
      end do
      
      if (found) report%n_p2_covered = report%n_p2_covered + 1
    end do
    
    call report%ComputeCoverage()
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE KW_Audit_P2_Optional

  ! ===================================================================
  ! Coverage Report Generation
  ! ===================================================================
  
  !=============================================================================
  !> @brief Generate comprehensive coverage report (legacy interface)
  !! @details Generates coverage report for all priority levels (P0/P1/P2)
  !! @param[in] covered_kws Covered keywords array
  !! @param[out] report Coverage report
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !=============================================================================
  SUBROUTINE KW_Generate_Report(covered_kws, report, status)
    character(len=*), intent(in) :: covered_kws(:)
    type(KW_Coverage_Report), intent(out) :: report
    type(ErrorStatusType), intent(out), optional :: status
    
    type(ErrorStatusType) :: status_local
    
    if (present(status)) call init_error_status(status)
    call init_error_status(status_local)
    
    ! Audit all priority levels
    call KW_Audit_P0_Must(covered_kws, report, status_local)
    if (status_local%status_code /= IF_STATUS_OK) then
      if (present(status)) status = status_local
      return
    end if
    
    call KW_Audit_P1_Important(covered_kws, report, status_local)
    if (status_local%status_code /= IF_STATUS_OK) then
      if (present(status)) status = status_local
      return
    end if
    
    call KW_Audit_P2_Optional(covered_kws, report, status_local)
    if (status_local%status_code /= IF_STATUS_OK) then
      if (present(status)) status = status_local
      return
    end if
    
    ! Final coverage computation
    call report%ComputeCoverage()
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE KW_Generate_Report

  ! ===================================================================
  ! KW_Coverage_Report Procedures
  ! ===================================================================
  
  !=============================================================================
  !> @brief Compute coverage percentages (legacy interface)
  !! @details Computes coverage percentages for P0/P1/P2 and total coverage
  !! @param[inout] this Coverage report instance
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !!   Theory: Coverage = (covered/total) �?100%, P0 complete if n_p0_covered == n_p0_total
  !=============================================================================
  subroutine KW_Coverage_Calc(this)
    class(KW_Coverage_Report), intent(inout) :: this
    
    integer(i4) :: total_keywords, total_covered
    
    ! P0 coverage
    if (this%n_p0_total > 0) then
      this%p0_coverage = real(this%n_p0_covered, wp) / real(this%n_p0_total, wp) * 100.0_wp
      this%p0_complete = (this%n_p0_covered == this%n_p0_total)
    end if
    
    ! P1 coverage
    if (this%n_p1_total > 0) then
      this%p1_coverage = real(this%n_p1_covered, wp) / real(this%n_p1_total, wp) * 100.0_wp
    end if
    
    ! Total coverage
    total_keywords = this%n_p0_total + this%n_p1_total + this%n_p2_total
    total_covered = this%n_p0_covered + this%n_p1_covered + this%n_p2_covered
    
    if (total_keywords > 0) then
      this%total_coverage = real(total_covered, wp) / real(total_keywords, wp) * 100.0_wp
    end if
    
  END SUBROUTINE KW_Coverage_Calc
  
  subroutine KW_Coverage_Print(this)
    !! Print coverage report to stdout
    class(KW_Coverage_Report), intent(in) :: this
    
    integer(i4) :: i
    
    print *, "============================================"
    print *, "  ABAQUS Keyword Coverage Report"
    print *, "============================================"
    print *, ""
    
    print '(A,I0,A,I0,A,F5.1,A)', "P0 (Must):      ", this%n_p0_covered, " / ", &
           this%n_p0_total, " (", this%p0_coverage, "%)"
    
    if (allocated(this%p0_missing)) then
      print *, "  Missing P0 keywords:"
      do i = 1, size(this%p0_missing)
        print '(A,A)', "    - ", trim(this%p0_missing(i))
      end do
    end if
    
    print *, ""
    print '(A,I0,A,I0,A,F5.1,A)', "P1 (Important): ", this%n_p1_covered, " / ", &
           this%n_p1_total, " (", this%p1_coverage, "%)"
    
    if (allocated(this%p1_missing)) then
      print *, "  Missing P1 keywords:"
      do i = 1, size(this%p1_missing)
        print '(A,A)', "    - ", trim(this%p1_missing(i))
      end do
    end if
    
    print *, ""
    print '(A,I0,A,I0)', "P2 (Optional):  ", this%n_p2_covered, " / ", this%n_p2_total
    print *, ""
    print '(A,F5.1,A)', "Total Coverage: ", this%total_coverage, "%"
    print *, ""
    
    if (this%p0_complete) then
      print *, "P0 COMPLETE - Core functionality achieved!"
    else
      print *, "P0 INCOMPLETE - Core keywords missing"
    end if
    
    print *, "============================================"
    
  END SUBROUTINE KW_Coverage_Print

END MODULE MD_KW_Coverage_Type


!===============================================================================
! Module: MD_KWReg
! Purpose: Keyword Registration System - Complete keyword and macro command registry
! Version: 1.0
! Date: 2026-02-11
! Description:
!   Complete keyword registration system for all P0/P1/P2 keywords and macro commands
!   Based on UFC keyword manual requirements
!===============================================================================
MODULE MD_KW_Reg_Type
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
    USE IF_Prec_Core, ONLY: wp, i4, i8
    USE MD_KW_Coverage_Type, ONLY: KW_PRIORITY_P0, KW_PRIORITY_P1, KW_PRIORITY_P2
    IMPLICIT NONE
    PRIVATE

    !=============================================================================
    ! Constants
    !=============================================================================
    INTEGER(i4), PARAMETER :: KW_MAX_NAME_LEN = 64
    INTEGER(i4), PARAMETER :: KW_MAX_DESC_LEN = 256
    INTEGER(i4), PARAMETER :: KW_MAX_REGISTRY = 500
    INTEGER(i4), PARAMETER :: KW_MAX_PARAMS = 32

    !=============================================================================
    ! Keyword Categories
    !=============================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_MODEL = 1          ! Model definition
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_PART = 2           ! Part/instance
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_MESH = 3           ! Mesh
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_MATERIAL = 4       ! Mat
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_SECTION = 5       ! Section
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_CONSTRAINT = 6    ! Constraint
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_LOAD = 7          ! Load
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_CONTACT = 8      ! Contact
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_STEP = 9          ! Analysis step
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_OUTPUT = 10      ! Output
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_AMPLITUDE = 11   ! Amplitude
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_MACRO = 12       ! Macro commands (*INCLUDE, *PARAMETER, etc.)
    INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_END = 13         ! End keywords

    !=============================================================================
    !> @brief Keyword metadata type
    !! @details Stores keyword registration metadata
    !!   Theory: Keyword metadata with name, category, priority, parse procedures, validation
    TYPE, PUBLIC :: KW_MetadataType
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: keyword_name = ""     ! Keyword name (without *)
        INTEGER(i4) :: category = 0                              ! Keyword category  ? ?
        INTEGER(i4) :: priority = KW_PRIORITY_P0                ! Priority (P0/P1/P2)  ? ?
        CHARACTER(LEN=KW_MAX_DESC_LEN) :: description = ""      ! Keyword description
        LOGICAL :: is_macro = .FALSE.                           ! Is macro command flag
        LOGICAL :: is_registered = .FALSE.                      ! Is registered flag
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: parse_module = ""     ! Parse module name
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: parse_proc = ""       ! Parse procedure name
        LOGICAL :: has_validate = .FALSE.                      ! Has validation function flag
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: validate_proc = ""    ! Validation procedure name
    END TYPE KW_MetadataType

    !=============================================================================
    ! Hash Table Constants (merged from MD_KW_Registry_Optimized)
    !=============================================================================
    INTEGER(i4), PARAMETER :: HASH_TABLE_SIZE = 256
    INTEGER(i4), PARAMETER :: HASH_MASK = HASH_TABLE_SIZE - 1

    !=============================================================================
    !> @brief Hash table type
    !! @details Hash table for O(1) keyword lookup
    !! Theory: Hash table with buckets array, hash function h(keyword) ?bucket index
    TYPE, PUBLIC :: KW_HashTableType
        INTEGER(i4), ALLOCATABLE :: buckets(:)    ! Hash buckets array
        INTEGER(i4) :: size = 0                    ! Hash table size  ? ?
        LOGICAL :: is_initialized = .FALSE.        ! Initialization flag
    CONTAINS
        PROCEDURE, PUBLIC :: Init => HashTable_Init
        PROCEDURE, PUBLIC :: Insert => HashTable_Insert
        PROCEDURE, PUBLIC :: Find => HashTable_Find
        PROCEDURE, PUBLIC :: Clear => HashTable_Clear
    END TYPE KW_HashTableType

    !=============================================================================
    !> @brief Registry type
    !! @details Keyword registry with metadata array
    !!   Theory: Registry with n_keywords keywords, keyword metadata array
    TYPE, PUBLIC :: KW_RegistryType
        INTEGER(i4) :: count = 0                   ! Keyword count n_keywords  ? ?
        TYPE(KW_MetadataType), ALLOCATABLE :: keywords(:)  ! Keyword metadata array
        LOGICAL :: is_initialized = .FALSE.         ! Initialization flag
    CONTAINS
        PROCEDURE, PUBLIC :: Init => KW_Registry_Init
        PROCEDURE, PUBLIC :: Reg => KW_Registry_Reg
        PROCEDURE, PUBLIC :: Find => KW_Registry_Find
        PROCEDURE, PUBLIC :: GetAllKeywords => KW_Registry_GetAllKeywords
        PROCEDURE, PUBLIC :: GetKeywordsByCategory => KW_Registry_GetKeywordsByCategory
        PROCEDURE, PUBLIC :: GetKeywordsByPriority => KW_Registry_GetKeywordsByPriority
        PROCEDURE, PUBLIC :: GetMacroCommands => KW_Registry_GetMacroCommands
        PROCEDURE, PUBLIC :: CheckCoverage => KW_Registry_CheckCoverage
    END TYPE KW_RegistryType

    !=============================================================================
    !> @brief Optimized registry type
    !! @details Registry with hash table for fast lookup
    !!   Theory: Extended registry with hash table, O(1) lookup vs O(n) linear search
    TYPE, PUBLIC, EXTENDS(KW_RegistryType) :: KW_RegistryOptimizedType
        TYPE(KW_HashTableType) :: hash_table      ! Hash table for fast lookup
        LOGICAL :: use_hash = .TRUE.               ! Use hash table flag
    CONTAINS
        PROCEDURE, PUBLIC :: InitOptimized => Reg_InitOptimized
        PROCEDURE, PUBLIC :: RegisterOptimized => Reg_RegisterOptimized
        PROCEDURE, PUBLIC :: FindOptimized => Reg_FindOptimized
        PROCEDURE, PUBLIC :: BuildHashTable => Reg_BuildHashTable
    END TYPE KW_RegistryOptimizedType

    !=============================================================================
    ! Global Registry Instances
    !=============================================================================
    TYPE(KW_RegistryType), SAVE, PUBLIC :: g_kw_registry
    TYPE(KW_RegistryOptimizedType), SAVE, PUBLIC :: g_kw_registry_opt

    !=============================================================================
    ! Structured Interface Types (Desc/Algo/Ctx/State pattern)
    !=============================================================================
    
    !> @brief Keyword registration input type (Desc category)
    !! @details Encapsulates keyword registration parameters
    !!   Theory: Registration input with keyword name, category, priority, parse procedures
    TYPE, PUBLIC :: KW_Reg_Desc
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: keyword_name = ""     ! Keyword name
        INTEGER(i4) :: category = 0                              ! Category  ? ?
        INTEGER(i4) :: priority = KW_PRIORITY_P0                ! Priority  ? ?
        CHARACTER(LEN=KW_MAX_DESC_LEN) :: description = ""      ! Description
        LOGICAL :: is_macro = .FALSE.                           ! Is macro flag
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: parse_module = ""     ! Parse module name
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: parse_proc = ""       ! Parse procedure name
        LOGICAL :: has_validate = .FALSE.                      ! Has validation flag
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: validate_proc = ""    ! Validation procedure name
    END TYPE KW_Reg_Desc
    
    !> @brief Keyword registry context type (Ctx category)
    !! @details Registry context for keyword operations
    TYPE, PUBLIC :: KW_Registry_Ctx
        TYPE(KW_RegistryType), POINTER :: registry => null()   ! Registry pointer
        LOGICAL :: use_optimized = .FALSE.                      ! Use optimized registry flag
    END TYPE KW_Registry_Ctx
    
    !> @brief Coverage audit input type (Desc category)
    !! @details Encapsulates coverage audit parameters
    TYPE, PUBLIC :: KW_CoverageAudit_Desc
        CHARACTER(LEN=64), ALLOCATABLE :: covered_keywords(:)   ! Covered keywords array
        INTEGER(i4) :: n_keywords = 0_i4                        ! Number of keywords n_keywords  ? ?
    END TYPE KW_CoverageAudit_Desc
    
    !> @brief Coverage report output type (State category)
    !! @details Coverage report output with coverage metrics
    !! Theory: Coverage metrics: n_p0_total, n_p0_covered, coverage percentage ?[0,100] ? ?
    TYPE, PUBLIC :: MD_KW_CoverageReportOut_Type
        INTEGER(i4) :: p0_count = 0_i4                          ! P0 total n_p0_total  ? ?
        INTEGER(i4) :: p0_covered = 0_i4                        ! P0 covered n_p0_covered  ? ?
        INTEGER(i4) :: p1_count = 0_i4                          ! P1 total n_p1_total  ? ?
        INTEGER(i4) :: p1_covered = 0_i4                        ! P1 covered n_p1_covered  ? ?
        INTEGER(i4) :: p2_count = 0_i4                          ! P2 total n_p2_total  ? ?
        INTEGER(i4) :: p2_covered = 0_i4                        ! P2 covered n_p2_covered  ? ?
        INTEGER(i4) :: macro_count = 0_i4                       ! Macro total n_macro  ? ?
        INTEGER(i4) :: macro_covered = 0_i4                    ! Macro covered n_macro_covered  ? ?
    END TYPE MD_KW_CoverageReportOut_Type
    
    !> @brief Keyword find input type (Desc category)
    !! @details Encapsulates keyword lookup parameters
    TYPE, PUBLIC :: KW_Find_Desc
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: keyword_name = ""     ! Keyword name to find
    END TYPE KW_Find_Desc
    
    !> @brief Keyword find output type (State category)
    !! @details Keyword lookup result
    TYPE, PUBLIC :: KW_Find_State
        INTEGER(i4) :: index = 0_i4                             ! Keyword index idx  ? ?(0 if not found)
        TYPE(KW_MetadataType), POINTER :: metadata => null()    ! Keyword metadata pointer
        LOGICAL :: found = .FALSE.                              ! Found flag
    END TYPE KW_Find_State

    ! Types above use TYPE, PUBLIC :: (no duplicate PUBLIC :: type-name lines).

    !=============================================================================
    ! Public Interfaces
    !=============================================================================
    PUBLIC :: KW_Registry_InitGlobal
    PUBLIC :: KW_Registry_RegisterAllKeywords
    PUBLIC :: KW_Registry_FindKeyword
    PUBLIC :: KW_Registry_GetCoverageReport
    INTERFACE KW_Registry_GetCoverageReport
        MODULE PROCEDURE KW_Registry_GetCoverageReport_Scalar, KW_Registry_GetCoverageReport_Out
    END INTERFACE KW_Registry_GetCoverageReport
    ! Optimized interfaces (merged from MD_KW_Registry_Optimized)
    PUBLIC :: KW_Registry_InitOptimizedGlobal
    PUBLIC :: KW_Registry_FindKeywordFast
    PUBLIC :: KW_Registry_BuildHashTable

CONTAINS

    !=============================================================================
    ! Init Registry
    !=============================================================================
    !=============================================================================
    !> @brief Initialize registry (legacy interface)
    !! @details Initializes keyword registry, allocates keyword array
    !! @param[inout] this Registry instance
    !! @param[out] status Error status (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE KW_Registry_Init(this, status)
        CLASS(KW_RegistryType), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        IF (.NOT. ALLOCATED(this%keywords)) THEN
            ALLOCATE(this%keywords(KW_MAX_REGISTRY))
        END IF

        this%count = 0
        this%is_initialized = .TRUE.

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Registry_Init

    !=============================================================================
    ! Reg Keyword
    !=============================================================================
    !=============================================================================
    !> @brief Register keyword (legacy interface)
    !! @details Registers a keyword with metadata in the registry
    !! @param[inout] this Registry instance
    !! @param[in] keyword_name Keyword name
    !! @param[in] category Keyword category ? ?
    !! @param[in] priority Keyword priority ? ?
    !! @param[in] description Description (optional)
    !! @param[in] is_macro Is macro flag (optional)
    !! @param[in] parse_module Parse module name (optional)
    !! @param[in] parse_proc Parse procedure name (optional)
    !! @param[in] has_validate Has validation flag (optional)
    !! @param[in] validate_proc Validation procedure name (optional)
    !! @param[out] status Error status (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE KW_Registry_Reg(this, keyword_name, category, priority, &
                                     description, is_macro, parse_module, &
                                     parse_proc, has_validate, validate_proc, status)
        CLASS(KW_RegistryType), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4), INTENT(IN) :: category, priority
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: description
        LOGICAL, INTENT(IN), OPTIONAL :: is_macro
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: parse_module, parse_proc
        LOGICAL, INTENT(IN), OPTIONAL :: has_validate
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: validate_proc
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: idx
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: kw_upper

        IF (PRESENT(status)) CALL init_error_status(status)

        IF (.NOT. this%is_initialized) THEN
            CALL this%Init(status)
        END IF

        ! Check if already registered
        kw_upper = keyword_name
        CALL to_upper(kw_upper)
        idx = this%Find(kw_upper)
        IF (idx > 0) THEN
            IF (PRESENT(status)) THEN
                status%status_code = IF_STATUS_INVALID
                WRITE(status%message, '(A,A,A)') "Keyword already registered: ", TRIM(keyword_name)
            END IF
            RETURN
        END IF

        ! Add new keyword
        IF (this%count >= KW_MAX_REGISTRY) THEN
            IF (PRESENT(status)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Keyword registry full"
            END IF
            RETURN
        END IF

        this%count = this%count + 1
        idx = this%count

        this%keywords(idx)%keyword_name = kw_upper
        this%keywords(idx)%category = category
        this%keywords(idx)%priority = priority
        IF (PRESENT(description)) this%keywords(idx)%cfg%description = description
        IF (PRESENT(is_macro)) this%keywords(idx)%is_macro = is_macro
        IF (PRESENT(parse_module)) this%keywords(idx)%parse_module = parse_module
        IF (PRESENT(parse_proc)) this%keywords(idx)%parse_proc = parse_proc
        IF (PRESENT(has_validate)) this%keywords(idx)%has_validate = has_validate
        IF (PRESENT(validate_proc)) this%keywords(idx)%validate_proc = validate_proc
        this%keywords(idx)%is_registered = .TRUE.

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Registry_Reg

    !=============================================================================
    ! Find Keyword
    !=============================================================================
    !=============================================================================
    !> @brief Find keyword (legacy interface)
    !! @details Finds keyword in registry by name
    !! @param[in] this Registry instance
    !! @param[in] keyword_name Keyword name to find
    !! @return idx Keyword index ? ?(0 if not found)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use KW_Find_Desc and KW_Find_State types:
    !!     TYPE(KW_Find_Desc) :: find_desc
    !!     TYPE(KW_Find_State) :: find_state
    !!     find_desc%keyword_name = ...
    !!     CALL KW_Registry_Find_Structured(this, find_desc, find_state)
    !=============================================================================
    FUNCTION KW_Registry_Find(this, keyword_name) RESULT(idx)
        CLASS(KW_RegistryType), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4) :: idx

        INTEGER(i4) :: i
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: kw_upper

        idx = 0
        kw_upper = keyword_name
        CALL to_upper(kw_upper)

        DO i = 1, this%count
            IF (TRIM(this%keywords(i)%keyword_name) == TRIM(kw_upper)) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION KW_Registry_Find

    !=============================================================================
    ! Get All Keywords
    !=============================================================================
    SUBROUTINE KW_Registry_GetAllKeywords(this, keywords, count)
        CLASS(KW_RegistryType), INTENT(IN) :: this
        TYPE(KW_MetadataType), INTENT(OUT), ALLOCATABLE :: keywords(:)
        INTEGER(i4), INTENT(OUT) :: count

        count = this%count
        IF (count > 0) THEN
            ALLOCATE(keywords(count))
            keywords(1:count) = this%keywords(1:count)
        END IF
    END SUBROUTINE KW_Registry_GetAllKeywords

    !=============================================================================
    ! Get Keywords by Category
    !=============================================================================
    !=============================================================================
    !> @brief Get keywords by category (legacy interface)
    !! @details Retrieves all keywords in a specific category
    !! @param[in] this Registry instance
    !! @param[in] category Category ID ? ?
    !! @param[out] keywords Keywords array
    !! @param[out] count Number of keywords n_keywords ? ?
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE KW_Registry_GetKeywordsByCategory(this, category, keywords, count)
        CLASS(KW_RegistryType), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: category
        TYPE(KW_MetadataType), INTENT(OUT), ALLOCATABLE :: keywords(:)
        INTEGER(i4), INTENT(OUT) :: count

        INTEGER(i4) :: i, j
        TYPE(KW_MetadataType), ALLOCATABLE :: temp(:)

        ALLOCATE(temp(this%count))
        count = 0

        DO i = 1, this%count
            IF (this%keywords(i)%category == category) THEN
                count = count + 1
                temp(count) = this%keywords(i)
            END IF
        END DO

        IF (count > 0) THEN
            ALLOCATE(keywords(count))
            keywords(1:count) = temp(1:count)
        END IF
        DEALLOCATE(temp)
    END SUBROUTINE KW_Registry_GetKeywordsByCategory

    !=============================================================================
    ! Get Keywords by Priority
    !=============================================================================
    !=============================================================================
    !> @brief Get keywords by priority (legacy interface)
    !! @details Retrieves all keywords with a specific priority level
    !! @param[in] this Registry instance
    !! @param[in] priority Priority level ? ?
    !! @param[out] keywords Keywords array
    !! @param[out] count Number of keywords n_keywords ? ?
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE KW_Registry_GetKeywordsByPriority(this, priority, keywords, count)
        CLASS(KW_RegistryType), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: priority
        TYPE(KW_MetadataType), INTENT(OUT), ALLOCATABLE :: keywords(:)
        INTEGER(i4), INTENT(OUT) :: count

        INTEGER(i4) :: i
        TYPE(KW_MetadataType), ALLOCATABLE :: temp(:)

        ALLOCATE(temp(this%count))
        count = 0

        DO i = 1, this%count
            IF (this%keywords(i)%priority == priority) THEN
                count = count + 1
                temp(count) = this%keywords(i)
            END IF
        END DO

        IF (count > 0) THEN
            ALLOCATE(keywords(count))
            keywords(1:count) = temp(1:count)
        END IF
        DEALLOCATE(temp)
    END SUBROUTINE KW_Registry_GetKeywordsByPriority

    !=============================================================================
    ! Get Macro Commands
    !=============================================================================
    SUBROUTINE KW_Registry_GetMacroCommands(this, keywords, count)
        CLASS(KW_RegistryType), INTENT(IN) :: this
        TYPE(KW_MetadataType), INTENT(OUT), ALLOCATABLE :: keywords(:)
        INTEGER(i4), INTENT(OUT) :: count

        INTEGER(i4) :: i
        TYPE(KW_MetadataType), ALLOCATABLE :: temp(:)

        ALLOCATE(temp(this%count))
        count = 0

        DO i = 1, this%count
            IF (this%keywords(i)%is_macro) THEN
                count = count + 1
                temp(count) = this%keywords(i)
            END IF
        END DO

        IF (count > 0) THEN
            ALLOCATE(keywords(count))
            keywords(1:count) = temp(1:count)
        END IF
        DEALLOCATE(temp)
    END SUBROUTINE KW_Registry_GetMacroCommands

    !=============================================================================
    ! Check Coverage
    !=============================================================================
    !=============================================================================
    !> @brief Check coverage (legacy interface)
    !! @details Checks keyword coverage by priority level
    !! @param[in] this Registry instance
    !! @param[out] p0_count P0 total count n_p0_total ? ?
    !! @param[out] p0_covered P0 covered count n_p0_covered ? ?
    !! @param[out] p1_count P1 total count n_p1_total ? ?
    !! @param[out] p1_covered P1 covered count n_p1_covered ? ?
    !! @param[out] p2_count P2 total count n_p2_total ? ?
    !! @param[out] p2_covered P2 covered count n_p2_covered ? ?
    !! @param[out] macro_count Macro total count n_macro ? ?
    !! @param[out] macro_covered Macro covered count n_macro_covered ? ?
    !! @param[out] status Error status (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use MD_KW_CoverageReportOut_Type to encapsulate all coverage outputs
    !=============================================================================
    SUBROUTINE KW_Registry_CheckCoverage(this, p0_count, p0_covered, &
                                          p1_count, p1_covered, &
                                          p2_count, p2_covered, &
                                          macro_count, macro_covered, status)
        CLASS(KW_RegistryType), INTENT(IN) :: this
        INTEGER(i4), INTENT(OUT) :: p0_count, p0_covered
        INTEGER(i4), INTENT(OUT) :: p1_count, p1_covered
        INTEGER(i4), INTENT(OUT) :: p2_count, p2_covered
        INTEGER(i4), INTENT(OUT) :: macro_count, macro_covered
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i

        IF (PRESENT(status)) CALL init_error_status(status)

        p0_count = 0
        p0_covered = 0
        p1_count = 0
        p1_covered = 0
        p2_count = 0
        p2_covered = 0
        macro_count = 0
        macro_covered = 0

        DO i = 1, this%count
            SELECT CASE (this%keywords(i)%priority)
            CASE (KW_PRIORITY_P0)
                p0_count = p0_count + 1
                IF (this%keywords(i)%is_registered) p0_covered = p0_covered + 1
            CASE (KW_PRIORITY_P1)
                p1_count = p1_count + 1
                IF (this%keywords(i)%is_registered) p1_covered = p1_covered + 1
            CASE (KW_PRIORITY_P2)
                p2_count = p2_count + 1
                IF (this%keywords(i)%is_registered) p2_covered = p2_covered + 1
            END SELECT

            IF (this%keywords(i)%is_macro) THEN
                macro_count = macro_count + 1
                IF (this%keywords(i)%is_registered) macro_covered = macro_covered + 1
            END IF
        END DO

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Registry_CheckCoverage

    !=============================================================================
    ! Helper: Convert to Uppercase
    !=============================================================================
    SUBROUTINE to_upper(str)
        CHARACTER(LEN=*), INTENT(INOUT) :: str
        INTEGER(i4) :: i, c

        DO i = 1, LEN_TRIM(str)
            c = ICHAR(str(i:i))
            IF (c >= ICHAR('a') .AND. c <= ICHAR('z')) THEN
                str(i:i) = CHAR(c - 32)
            END IF
        END DO
    END SUBROUTINE to_upper

    !=============================================================================
    ! Init Global Registry
    !=============================================================================
    SUBROUTINE KW_Registry_InitGlobal(status)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        CALL g_kw_registry%Init(status)
        IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN

        CALL KW_Registry_RegisterAllKeywords(status)

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Registry_InitGlobal

    !=============================================================================
    ! Reg All Keywords (P0/P1/P2 + Macros)
    ! parse_proc: Parse_*_Keyword or *_Unified_Parse. See L3_MD/L5_RT Parse modules and docs/Unified_Parse_Index.md
    !=============================================================================
    SUBROUTINE KW_Registry_RegisterAllKeywords(status)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        TYPE(ErrorStatusType) :: local_status

        IF (PRESENT(status)) CALL init_error_status(status)
        CALL init_error_status(local_status)

        !=========================================================================
        ! P0 Core Keywords (24 total)
        !=========================================================================
        CALL g_kw_registry%Reg("NODE", KW_CAT_MESH, KW_PRIORITY_P0, &
            "Node", parse_module="MD_Part", parse_proc="PartTree_AddNode", &
            has_validate=.TRUE., validate_proc="PartTree_AddNode", status=local_status)

        CALL g_kw_registry%Reg("ELEMENT", KW_CAT_MESH, KW_PRIORITY_P0, &
            "Element", parse_module="MD_Part", parse_proc="PartTree_AddElement", &
            has_validate=.TRUE., validate_proc="PartTree_AddElement", status=local_status)

        CALL g_kw_registry%Reg("STEP", KW_CAT_STEP, KW_PRIORITY_P0, &
            "Step", parse_module="MD_Step", parse_proc="StepDesc_Init", &
            has_validate=.TRUE., validate_proc="StepDesc_Valid", status=local_status)

        CALL g_kw_registry%Reg("STATIC", KW_CAT_STEP, KW_PRIORITY_P0, &
            "Static analysis step", parse_module="MD_Step", status=local_status)

        CALL g_kw_registry%Reg("BOUNDARY", KW_CAT_CONSTRAINT, KW_PRIORITY_P0, &
            "Boundary condition", parse_module="MD_LBC", parse_proc="BCDef_Init", &
            has_validate=.TRUE., validate_proc="BCDef_Validate", status=local_status)

        CALL g_kw_registry%Reg("CLOAD", KW_CAT_LOAD, KW_PRIORITY_P0, &
            "Concentrated load", parse_module="MD_LBC", parse_proc="LoadDef_Init", &
            has_validate=.TRUE., validate_proc="LoadDef_Validate", status=local_status)

        CALL g_kw_registry%Reg("DLOAD", KW_CAT_LOAD, KW_PRIORITY_P0, &
            "Distributed load", parse_module="MD_LBC", parse_proc="LoadDef_Init", &
            has_validate=.TRUE., validate_proc="LoadDef_Validate", status=local_status)

        CALL g_kw_registry%Reg("Mat", KW_CAT_MATERIAL, KW_PRIORITY_P0, &
            "Mat", parse_module="MD_Mat_Unified", parse_proc="MD_Mat_Desc_Init", &
            has_validate=.TRUE., validate_proc="MD_Mat_Desc_Valid", status=local_status)

        CALL g_kw_registry%Reg("ELASTIC", KW_CAT_MATERIAL, KW_PRIORITY_P0, &
            "Elastic Mat", parse_module="MD_Mat_Unified", parse_proc="MD_ElasticMatDesc_Init", &
            has_validate=.TRUE., validate_proc="MD_ElasticMatDesc_Valid", status=local_status)

        CALL g_kw_registry%Reg("PLASTIC", KW_CAT_MATERIAL, KW_PRIORITY_P0, &
            "Plastic Mat", parse_module="MD_Mat_Unified", status=local_status)

        CALL g_kw_registry%Reg("SURFACE", KW_CAT_MESH, KW_PRIORITY_P0, &
            "Surface", parse_module="MD_Sets", status=local_status)

        CALL g_kw_registry%Reg("CONTACT PAIR", KW_CAT_CONTACT, KW_PRIORITY_P0, &
            "Contact pair", parse_module="MD_Interaction", status=local_status)

        CALL g_kw_registry%Reg("SURFACE INTERACTION", KW_CAT_CONTACT, KW_PRIORITY_P0, &
            "Surface interaction", parse_module="MD_Interaction", status=local_status)

        CALL g_kw_registry%Reg("FIELD OUTPUT", KW_CAT_OUTPUT, KW_PRIORITY_P0, &
            "Field output", parse_module="MD_Out", parse_proc="FldOutDesc_Init", &
            has_validate=.TRUE., validate_proc="FldOutDesc_Valid", status=local_status)

        CALL g_kw_registry%Reg("HISTORY OUTPUT", KW_CAT_OUTPUT, KW_PRIORITY_P0, &
            "History output", parse_module="MD_Out", parse_proc="HistOutDesc_Init", &
            has_validate=.TRUE., validate_proc="HistOutDesc_Valid", status=local_status)

        CALL g_kw_registry%Reg("SOLID SECTION", KW_CAT_SECTION, KW_PRIORITY_P0, &
            "Solid section", parse_module="MD_Sect", parse_proc="SolidSectDesc_Init", &
            has_validate=.TRUE., validate_proc="SolidSectDesc_Valid", status=local_status)

        CALL g_kw_registry%Reg("SHELL SECTION", KW_CAT_SECTION, KW_PRIORITY_P0, &
            "Shell section", parse_module="MD_Sect", parse_proc="ShellSectDesc_Init", &
            has_validate=.TRUE., validate_proc="ShellSectDesc_Valid", status=local_status)

        CALL g_kw_registry%Reg("NSET", KW_CAT_MESH, KW_PRIORITY_P0, &
            "Node set", parse_module="MD_Sets", status=local_status)

        CALL g_kw_registry%Reg("ELSET", KW_CAT_MESH, KW_PRIORITY_P0, &
            "Element set", parse_module="MD_Sets", status=local_status)

        CALL g_kw_registry%Reg("PART", KW_CAT_PART, KW_PRIORITY_P0, &
            "Part", parse_module="MD_Part", status=local_status)

        CALL g_kw_registry%Reg("END PART", KW_CAT_END, KW_PRIORITY_P0, &
            "End part", status=local_status)

        CALL g_kw_registry%Reg("ASSEMBLY", KW_CAT_PART, KW_PRIORITY_P0, &
            "Assembly", parse_module="MD_Assem", parse_proc="AssemDesc_Init", &
            has_validate=.TRUE., validate_proc="AssemDesc_Validate", status=local_status)

        CALL g_kw_registry%Reg("INSTANCE", KW_CAT_PART, KW_PRIORITY_P0, &
            "Instance", parse_module="MD_Assem", parse_proc="InstDesc_Init", &
            has_validate=.TRUE., validate_proc="InstDesc_Valid", status=local_status)

        CALL g_kw_registry%Reg("END INSTANCE", KW_CAT_END, KW_PRIORITY_P0, &
            "End instance", status=local_status)

        !=========================================================================
        ! P1 Important Keywords (12 total)
        !=========================================================================
        CALL g_kw_registry%Reg("COUPLING", KW_CAT_CONSTRAINT, KW_PRIORITY_P1, &
            "Coupling constraint", status=local_status)

        CALL g_kw_registry%Reg("TIE", KW_CAT_CONSTRAINT, KW_PRIORITY_P1, &
            "Tie constraint", status=local_status)

        CALL g_kw_registry%Reg("MPC", KW_CAT_CONSTRAINT, KW_PRIORITY_P1, &
            "Multi-point constraint", status=local_status)

        CALL g_kw_registry%Reg("INITIAL CONDITIONS", KW_CAT_CONSTRAINT, KW_PRIORITY_P1, &
            "Initial conditions", status=local_status)

        CALL g_kw_registry%Reg("PREDEFINED FIELD", KW_CAT_CONSTRAINT, KW_PRIORITY_P1, &
            "Predefined field", status=local_status)

        CALL g_kw_registry%Reg("AMPLITUDE", KW_CAT_AMPLITUDE, KW_PRIORITY_P1, &
            "Amplitude", parse_module="MD_Amp_Core", status=local_status)

        CALL g_kw_registry%Reg("DYNAMIC", KW_CAT_STEP, KW_PRIORITY_P1, &
            "Dynamic analysis step", parse_module="MD_Step", status=local_status)

        CALL g_kw_registry%Reg("HEAT TRANSFER", KW_CAT_STEP, KW_PRIORITY_P1, &
            "Heat transfer step", parse_module="MD_Step", status=local_status)

        CALL g_kw_registry%Reg("BEAM SECTION", KW_CAT_SECTION, KW_PRIORITY_P1, &
            "Beam section", parse_module="MD_Sect", parse_proc="BeamSectDesc_Init", &
            has_validate=.TRUE., validate_proc="BeamSectDesc_Valid", status=local_status)

        CALL g_kw_registry%Reg("RESTART", KW_CAT_STEP, KW_PRIORITY_P1, &
            "Restart", parse_module="MD_Step", status=local_status)

        CALL g_kw_registry%Reg("ORIENTATION", KW_CAT_MATERIAL, KW_PRIORITY_P1, &
            "Orientation", status=local_status)

        CALL g_kw_registry%Reg("DENSITY", KW_CAT_MATERIAL, KW_PRIORITY_P1, &
            "Density", parse_module="MD_Mat_Unified", status=local_status)

        !=========================================================================
        ! P2 Extended Keywords (P0+Extended)
        !=========================================================================
        ! Note: parse_proc uses Unified_Parse interface. Caller must USE module and allocate out_data
        CALL g_kw_registry%Reg("FILM", KW_CAT_LOAD, KW_PRIORITY_P2, &
            "Film coef", parse_module="MD_LoadBC_Parse", &
            parse_proc="MD_LoadBC_Film_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("RADIATE", KW_CAT_LOAD, KW_PRIORITY_P2, &
            "Radiation", parse_module="MD_LoadBC_Parse", &
            parse_proc="MD_LoadBC_Radiate_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("DSFLUX", KW_CAT_LOAD, KW_PRIORITY_P2, &
            "Surface heat flux", parse_module="MD_LoadBC_Parse", &
            parse_proc="MD_LoadBC_Dsflux_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("MASS FLOW", KW_CAT_LOAD, KW_PRIORITY_P2, &
            "Mass flow", parse_module="MD_LoadBC_Parse", &
            parse_proc="MD_LoadBC_MassFlow_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("SFILM", KW_CAT_LOAD, KW_PRIORITY_P2, &
            "Surface film", parse_module="MD_LoadBC_Parse", &
            parse_proc="MD_LoadBC_Sfilm_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("SRADIATION", KW_CAT_LOAD, KW_PRIORITY_P2, &
            "Surface radiation", parse_module="MD_LoadBC_Parse", &
            parse_proc="MD_LoadBC_Sradiation_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("SPECIFIC HEAT", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Specific heat", parse_module="MD_Mat_SpecificHeat_Parse", &
            parse_proc="MD_Mat_SpecificHeat_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("LATENT HEAT", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Latent heat", parse_module="MD_Mat_LatentHeat_Parse", &
            parse_proc="MD_Mat_LatentHeat_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("JOULE HEAT", KW_CAT_LOAD, KW_PRIORITY_P2, &
            "Joule heat", parse_module="MD_Mat_JouleHeat_Parse", &
            parse_proc="MD_Mat_JouleHeat_Unified_Parse", status=local_status)

        ! Mass properties
        CALL g_kw_registry%Reg("MASS", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Mass", status=local_status)

        CALL g_kw_registry%Reg("ROTARY INERTIA", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Rotary inertia", status=local_status)

        CALL g_kw_registry%Reg("POINT MASS", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Point mass", status=local_status)

        CALL g_kw_registry%Reg("NONSTRUCTURAL MASS", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "", status=local_status)

        ! Mat properties
        CALL g_kw_registry%Reg("EXPANSION", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Thermal expansion", parse_module="MD_Mat_ELA_Expansion_Parse", &
            parse_proc="MD_Mat_ELA_Expansion_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("DAMPING", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Damping", parse_module="MD_Mat_ELA_Damping_Parse", &
            parse_proc="MD_Mat_ELA_Damping_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("VISCOSITY", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Viscosity", parse_module="MD_Mat_Viscosity_Parse", &
            parse_proc="MD_Mat_Viscosity_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("THERMAL CONDUCTIVITY", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Thermal conductivity", parse_module="MD_Mat_ThermalConductivity_Parse", &
            parse_proc="MD_Mat_ThermalConductivity_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("PERMEABILITY", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Permeability", parse_module="MD_Mat_Permeability_Parse", &
            parse_proc="MD_Mat_Permeability_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("SORPTION", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Sorption", parse_module="MD_Mat_Sorption_Parse", &
            parse_proc="MD_Mat_Sorption_Unified_Parse", status=local_status)

        ! Advanced Mat models
        CALL g_kw_registry%Reg("RATE DEPENDENT", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Rate dependent", parse_module="MD_MatPLMRateDep", &
            parse_proc="MD_Mat_RateDependent_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("VISCO", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Viscoelastic", parse_module="MD_Mat_Visco_Parse", &
            parse_proc="MD_Mat_Visco_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("HYPERFOAM", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Hyperfoam", parse_module="MD_Mat_Hyperfoam_Parse", &
            parse_proc="MD_Mat_Hyperfoam_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("HYPOELASTIC", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Hypoelastic", parse_module="MD_Mat_Hypoelastic_Parse", &
            parse_proc="MD_Mat_Hypoelastic_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("DRUCKER PRAGER", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Drucker-Prager", parse_module="MD_Mat_DruckerPrager_Parse", &
            parse_proc="MD_Mat_DruckerPrager_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("MOHR COULOMB", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Mohr-Coulomb", parse_module="MD_Mat_MohrCoulomb_Parse", &
            parse_proc="MD_Mat_MohrCoulomb_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("PROGRESSIVE DAMAGE", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Progressive damage", parse_module="MD_Mat_ProgressiveDamage_Parse", &
            parse_proc="MD_Mat_ProgressiveDamage_Unified_Parse", status=local_status)

        ! System/Transform
        CALL g_kw_registry%Reg("TRANSFORM", KW_CAT_PART, KW_PRIORITY_P2, &
            "Transform", status=local_status)

        CALL g_kw_registry%Reg("SYSTEM", KW_CAT_PART, KW_PRIORITY_P2, &
            "System", status=local_status)

        CALL g_kw_registry%Reg("NORMAL", KW_CAT_PART, KW_PRIORITY_P2, &
            "Normal", status=local_status)

        ! System/Transform
        CALL g_kw_registry%Reg("DISTRIBUTION", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Distribution", parse_module="MD_Model_Data_Dist", &
            parse_proc="MD_Model_Data_Dist_Parse", &
            has_validate=.TRUE., validate_proc="Valid_DISTRIBUTION_Keyword", status=local_status)

        CALL g_kw_registry%Reg("TABLE", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Table", parse_module="MD_Model_Data_Table", &
            parse_proc="MD_Model_Data_Table_Parse", &
            has_validate=.TRUE., validate_proc="Valid_TABLE_Keyword", status=local_status)

        CALL g_kw_registry%Reg("FIELD", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Field", parse_module="MD_Model_Data_Field", &
            parse_proc="MD_Model_Data_Field_Parse", &
            has_validate=.TRUE., validate_proc="Valid_FIELD_Keyword", status=local_status)

        CALL g_kw_registry%Reg("VARIABLE", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Variable", parse_module="MD_Model_Data_Variable", &
            parse_proc="MD_Model_Data_Variable_Parse", &
            has_validate=.TRUE., validate_proc="Valid_VARIABLE_Keyword", status=local_status)

        CALL g_kw_registry%Reg("FILTER", KW_CAT_OUTPUT, KW_PRIORITY_P2, &
            "Output filter", parse_module="MD_Output_OutputFilter_Parse", &
            parse_proc="MD_Output_OutputFilter_Unified_Parse", status=local_status)

        ! L5_RT Solver keywords: parse_module/parse_proc points to L5_RT modules. Caller must USE L5_RT or L6_AP modules
        CALL g_kw_registry%Reg("MODAL DAMPING", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Modal damping", parse_module="RT_Solv_ModalDamping", &
            parse_proc="RT_Solv_ModalDamping_UnifiedParse", status=local_status)

        CALL g_kw_registry%Reg("STEADY STATE DYNAMICS", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Steady state dynamics", parse_module="RT_Solv_SteadyState", &
            parse_proc="RT_Solv_SteadyState_UnifiedParse", status=local_status)

        CALL g_kw_registry%Reg("DIRECT", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Direct solver", parse_module="RT_Solver_Direct_Parse", &
            parse_proc="Parse_DIRECT_Keyword", status=local_status)

        CALL g_kw_registry%Reg("SUBSTRUCTURE", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Substructure", parse_module="RT_Solv_Substructure", &
            parse_proc="RT_Solv_Substructure_UnifiedParse", status=local_status)

        CALL g_kw_registry%Reg("MODAL DYNAMIC", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Modal dynamic", parse_module="RT_Solv_ModalDynamic", &
            parse_proc="RT_Solv_ModalDynamic_UnifiedParse", status=local_status)

        CALL g_kw_registry%Reg("COMPLEX FREQUENCY", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Complex frequency", parse_module="RT_Solv_ComplexFreq", &
            parse_proc="RT_Solv_ComplexFreq_UnifiedParse", status=local_status)

        CALL g_kw_registry%Reg("RESPONSE SPECTRUM", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Response spectrum", parse_module="RT_Solv_ResponseSpectrum", &
            parse_proc="RT_Solv_ResponseSpectrum_UnifiedParse", status=local_status)

        !=========================================================================
        ! Macro Commands
        !=========================================================================
        CALL g_kw_registry%Reg("INCLUDE", KW_CAT_MACRO, KW_PRIORITY_P1, &
            "Include file", is_macro=.TRUE., &
            parse_module="AP_Parser_Include_Parse", &
            parse_proc="Parse_INCLUDE_Keyword", &
            has_validate=.TRUE., &
            validate_proc="AP_Parser_Include_Validate", status=local_status)

        CALL g_kw_registry%Reg("PARAMETER", KW_CAT_MACRO, KW_PRIORITY_P2, &
            "Parameter", is_macro=.TRUE., &
            parse_module="MD_Model_Data_Param", &
            parse_proc="MD_Model_Data_Param_Parse", &
            has_validate=.TRUE., &
            validate_proc="Valid_Param_Keyword", status=local_status)

        CALL g_kw_registry%Reg("PREPRINT", KW_CAT_MACRO, KW_PRIORITY_P2, &
            "Preprint", is_macro=.TRUE., status=local_status)

        CALL g_kw_registry%Reg("FILE FORMAT", KW_CAT_MACRO, KW_PRIORITY_P2, &
            "File format", is_macro=.TRUE., status=local_status)

        CALL g_kw_registry%Reg("PHYSICAL CONSTANTS", KW_CAT_MACRO, KW_PRIORITY_P2, &
            "Physical constants", is_macro=.TRUE., &
            parse_module="MD_Model_Data_PhysConst", &
            parse_proc="MD_Model_Data_PhysConst_Parse", &
            has_validate=.TRUE., validate_proc="PhysicalConstants_Validate_Keyword", status=local_status)

        CALL g_kw_registry%Reg("NODE FILE", KW_CAT_MACRO, KW_PRIORITY_P2, &
            "Node file", is_macro=.TRUE., status=local_status)

        CALL g_kw_registry%Reg("EL FILE", KW_CAT_MACRO, KW_PRIORITY_P2, &
            "Element file", is_macro=.TRUE., status=local_status)

        !=========================================================================
        ! Output Keywords
        !=========================================================================
        CALL g_kw_registry%Reg("OUTPUT", KW_CAT_OUTPUT, KW_PRIORITY_P0, &
            "Output", parse_module="MD_Out", parse_proc="OutDesc_Init", &
            has_validate=.TRUE., validate_proc="OutDesc_Valid", status=local_status)

        CALL g_kw_registry%Reg("NODE OUTPUT", KW_CAT_OUTPUT, KW_PRIORITY_P0, &
            "", parse_module="MD_Out", status=local_status)

        CALL g_kw_registry%Reg("ELEMENT OUTPUT", KW_CAT_OUTPUT, KW_PRIORITY_P0, &
            "Element output", parse_module="MD_Out", status=local_status)

        CALL g_kw_registry%Reg("REPORT", KW_CAT_OUTPUT, KW_PRIORITY_P2, &
            "Report", parse_module="MD_Output_Report_Parse", &
            parse_proc="MD_Output_Report_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("PLOT", KW_CAT_OUTPUT, KW_PRIORITY_P2, &
            "Plot", parse_module="MD_Output_Plot_Parse", &
            parse_proc="MD_Output_Plot_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("EXPORT", KW_CAT_OUTPUT, KW_PRIORITY_P2, &
            "Export", parse_module="MD_Output_Export_Parse", &
            parse_proc="MD_Output_Export_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("ANIMATION", KW_CAT_OUTPUT, KW_PRIORITY_P2, &
            "Animation", parse_module="MD_Output_Animation_Parse", &
            parse_proc="MD_Output_Animation_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("POST PROCESSING", KW_CAT_OUTPUT, KW_PRIORITY_P2, &
            "Post processing", parse_module="MD_Output_PostProcessing_Parse", &
            parse_proc="MD_Output_PostProcessing_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("OUTPUT VARIABLE", KW_CAT_OUTPUT, KW_PRIORITY_P2, &
            "Output variable", parse_module="MD_Output_OutputVariable_Parse", &
            parse_proc="MD_Output_OutputVariable_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("OUTPUT FREQUENCY", KW_CAT_OUTPUT, KW_PRIORITY_P2, &
            "Output frequency", parse_module="MD_Output_OutputFrequency_Parse", &
            parse_proc="MD_Output_OutputFrequency_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("OUTPUT FORMAT", KW_CAT_OUTPUT, KW_PRIORITY_P2, &
            "Output format", parse_module="MD_Output_OutputFormat_Parse", &
            parse_proc="MD_Output_OutputFormat_Unified_Parse", status=local_status)

        !=========================================================================
        ! End Keywords
        !=========================================================================
        CALL g_kw_registry%Reg("END STEP", KW_CAT_END, KW_PRIORITY_P0, &
            "End step", status=local_status)

        CALL g_kw_registry%Reg("END ASSEMBLY", KW_CAT_END, KW_PRIORITY_P0, &
            "End assembly", status=local_status)

        !=========================================================================
        ! Mass properties
        !=========================================================================
        CALL g_kw_registry%Reg("HYPERELASTIC", KW_CAT_MATERIAL, KW_PRIORITY_P1, &
            "Hyperelastic", parse_module="MD_Mat_Hyperelastic", status=local_status)

        CALL g_kw_registry%Reg("CREEP", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Creep", parse_module="MD_Mat_Creep", status=local_status)

        CALL g_kw_registry%Reg("DAMAGE INITIATION", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Damage initiation", parse_module="MD_Mat_Damage", status=local_status)

        CALL g_kw_registry%Reg("DAMAGE EVOLUTION", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Damage evolution", parse_module="MD_Mat_Damage", status=local_status)

        CALL g_kw_registry%Reg("COHESIVE BEHAVIOR", KW_CAT_MATERIAL, KW_PRIORITY_P2, &
            "Cohesive behavior", parse_module="MD_Mat_Cohesive", status=local_status)

        !=========================================================================
        ! Coupled Analysis Steps
        !=========================================================================
        CALL g_kw_registry%Reg("COUPLED TEMPERATURE-DISPLACEMENT", KW_CAT_STEP, KW_PRIORITY_P1, &
            "Coupled temperature-displacement", parse_module="MD_Step", status=local_status)

        CALL g_kw_registry%Reg("BUCKLE", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Buckle", parse_module="MD_Step", status=local_status)

        CALL g_kw_registry%Reg("FREQUENCY", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Frequency", parse_module="MD_Step", status=local_status)

        !=========================================================================
        ! Constraints
        !=========================================================================
        CALL g_kw_registry%Reg("RIGID BODY", KW_CAT_CONSTRAINT, KW_PRIORITY_P1, &
            "Rigid body", parse_module="MD_Assem", status=local_status)

        !=========================================================================
        ! Contact Keywords
        !=========================================================================
        CALL g_kw_registry%Reg("CONTACT CONTROLS", KW_CAT_CONTACT, KW_PRIORITY_P1, &
            "Contact controls", parse_module="MD_Interaction", status=local_status)

        CALL g_kw_registry%Reg("CONTACT INITIALIZATION", KW_CAT_CONTACT, KW_PRIORITY_P2, &
            "Contact initialization", parse_module="MD_Interaction_ContactInitialization_Parse", &
            parse_proc="MD_Interaction_ContactInitialization_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("CONTACT INTERFERENCE", KW_CAT_CONTACT, KW_PRIORITY_P2, &
            "Contact interference", parse_module="MD_Interaction_ContactInterference_Parse", &
            parse_proc="MD_Interaction_ContactInterference_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("STICK SLIP", KW_CAT_CONTACT, KW_PRIORITY_P2, &
            "Stick slip", parse_module="MD_Interaction_StickSlip_Parse", &
            parse_proc="MD_Interaction_StickSlip_Unified_Parse", status=local_status)

        !=========================================================================
        ! Manufacturing Keywords - REMOVED (modules deleted as unused)
        !=========================================================================
        ! Note: Manufacturing keywords (WELD, FORMING, STAMPING, ROLLING, FORGING, MACHINING)
        ! were removed as they were STUB implementations with no actual solver integration.

        !=========================================================================
        ! Multiphysics/Fluid P3 Keywords
        !=========================================================================
        CALL g_kw_registry%Reg("MULTIPHYSICS", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Multiphysics", parse_module="MD_Multiphysics_Multiphysics_Parse", &
            parse_proc="MD_Multiphysics_Multiphysics_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("FLUID", KW_CAT_STEP, KW_PRIORITY_P2, &
            "Fluid", parse_module="MD_Fluid_Fluid_Parse", &
            parse_proc="MD_Fluid_Fluid_Unified_Parse", status=local_status)

        CALL g_kw_registry%Reg("DRAG", KW_CAT_LOAD, KW_PRIORITY_P2, &
            "Drag", parse_module="MD_Fluid_Drag_Parse", &
            parse_proc="MD_Fluid_Drag_Unified_Parse", status=local_status)

        IF (PRESENT(status)) status = local_status
    END SUBROUTINE KW_Registry_RegisterAllKeywords

    !=============================================================================
    ! Find Keyword (Global)
    !=============================================================================
    FUNCTION KW_Registry_FindKeyword(keyword_name) RESULT(idx)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4) :: idx

        ! Inline: directly call g_kw_registry%Find
        idx = g_kw_registry%Find(keyword_name)
    END FUNCTION KW_Registry_FindKeyword

    !=============================================================================
    ! Get Coverage Report
    !=============================================================================
    !=============================================================================
    !> @brief Get coverage report (scalar version, legacy interface)
    !! @details Gets coverage report with scalar output parameters
    !! @param[out] p0_count P0 total count n_p0_total ? ?
    !! @param[out] p0_covered P0 covered count n_p0_covered ? ?
    !! @param[out] p1_count P1 total count n_p1_total ? ?
    !! @param[out] p1_covered P1 covered count n_p1_covered ? ?
    !! @param[out] p2_count P2 total count n_p2_total ? ?
    !! @param[out] p2_covered P2 covered count n_p2_covered ? ?
    !! @param[out] macro_count Macro total count n_macro ? ?
    !! @param[out] macro_covered Macro covered count n_macro_covered ? ?
    !! @param[out] status Error status (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use KW_Registry_GetCoverageReport_Out with MD_KW_CoverageReportOut_Type
    !=============================================================================
    SUBROUTINE KW_Registry_GetCoverageReport_Scalar(p0_count, p0_covered, p1_count, &
                                             p1_covered, p2_count, p2_covered, &
                                             macro_count, macro_covered, status)
        INTEGER(i4), INTENT(OUT) :: p0_count, p0_covered
        INTEGER(i4), INTENT(OUT) :: p1_count, p1_covered
        INTEGER(i4), INTENT(OUT) :: p2_count, p2_covered
        INTEGER(i4), INTENT(OUT) :: macro_count, macro_covered
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        CALL g_kw_registry%CheckCoverage(p0_count, p0_covered, &
                                          p1_count, p1_covered, &
                                          p2_count, p2_covered, &
                                          macro_count, macro_covered, status)
    END SUBROUTINE KW_Registry_GetCoverageReport_Scalar

    !=============================================================================
    !> @brief Get coverage report (structured output version)
    !! @details Gets coverage report with structured output type
    !! @param[out] report_out Coverage report output (State category)
    !! @param[out] status Error status (optional)
    !! @note Preferred interface - uses structured output type MD_KW_CoverageReportOut_Type
    !=============================================================================
    SUBROUTINE KW_Registry_GetCoverageReport_Out(report_out, status)
        TYPE(MD_KW_CoverageReportOut_Type), INTENT(OUT) :: report_out
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        CALL g_kw_registry%CheckCoverage(report_out%p0_count, report_out%p0_covered, &
                                          report_out%p1_count, report_out%p1_covered, &
                                          report_out%p2_count, report_out%p2_covered, &
                                          report_out%macro_count, report_out%macro_covered, status)
    END SUBROUTINE KW_Registry_GetCoverageReport_Out

    !=============================================================================
    ! Hash Table Functions (merged from MD_KW_Registry_Optimized)
    !=============================================================================
    
    !=============================================================================
    ! Hash Function (djb2 algorithm, case-insensitive)
    !=============================================================================
    FUNCTION hash_keyword(keyword_name) RESULT(hash)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4) :: hash

        INTEGER(i4) :: i, c
        INTEGER(i8) :: hash64
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: kw_upper

        kw_upper = keyword_name
        CALL to_upper(kw_upper)

        hash64 = 5381_i8
        DO i = 1, LEN_TRIM(kw_upper)
            c = ICHAR(kw_upper(i:i))
            hash64 = IAND(hash64 * 33_i8 + INT(c, i8), INT(2147483647, i8))
        END DO
        hash = INT(IAND(hash64, INT(HASH_MASK, i8)), i4) + 1
    END FUNCTION hash_keyword

    !=============================================================================
    ! Init Hash Table
    !=============================================================================
    SUBROUTINE HashTable_Init(this, size, status)
        CLASS(KW_HashTableType), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: size
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        IF (.NOT. ALLOCATED(this%buckets)) THEN
            ALLOCATE(this%buckets(HASH_TABLE_SIZE))
            this%buckets = 0
        END IF

        this%size = size
        this%is_initialized = .TRUE.

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE HashTable_Init

    !=============================================================================
    ! Insert into Hash Table
    !=============================================================================
    SUBROUTINE HashTable_Insert(this, keyword_name, index, status)
        CLASS(KW_HashTableType), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4), INTENT(IN) :: index
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: hash_idx

        IF (PRESENT(status)) CALL init_error_status(status)

        IF (.NOT. this%is_initialized) THEN
            CALL this%Init(HASH_TABLE_SIZE, status)
            IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
        END IF

        hash_idx = hash_keyword(keyword_name)
        this%buckets(hash_idx) = index

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE HashTable_Insert

    !=============================================================================
    ! Find in Hash Table
    !=============================================================================
    FUNCTION HashTable_Find(this, keyword_name) RESULT(idx)
        CLASS(KW_HashTableType), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4) :: idx

        INTEGER(i4) :: hash_idx

        idx = 0
        IF (.NOT. this%is_initialized) RETURN

        hash_idx = hash_keyword(keyword_name)
        IF (hash_idx > 0 .AND. hash_idx <= HASH_TABLE_SIZE) THEN
            idx = this%buckets(hash_idx)
        END IF
    END FUNCTION HashTable_Find

    !=============================================================================
    ! Clear Hash Table
    !=============================================================================
    SUBROUTINE HashTable_Clear(this)
        CLASS(KW_HashTableType), INTENT(INOUT) :: this

        IF (ALLOCATED(this%buckets)) THEN
            this%buckets = 0
        END IF
        this%is_initialized = .FALSE.
        this%size = 0
    END SUBROUTINE HashTable_Clear

    !=============================================================================
    ! Optimized Registry Functions (merged from MD_KW_Registry_Optimized)
    !=============================================================================
    
    !=============================================================================
    ! Init Optimized Registry
    !=============================================================================
    SUBROUTINE Reg_InitOptimized(this, status)
        CLASS(KW_RegistryOptimizedType), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        CALL this%Init(status)
        IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN

        CALL this%hash_table%Init(HASH_TABLE_SIZE, status)

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE Reg_InitOptimized

    !=============================================================================
    ! Reg Keyword (Optimized)
    !=============================================================================
    SUBROUTINE Reg_RegisterOptimized(this, keyword_name, category, priority, &
                                           description, is_macro, parse_module, &
                                           parse_proc, has_validate, validate_proc, status)
        CLASS(KW_RegistryOptimizedType), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4), INTENT(IN) :: category, priority
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: description
        LOGICAL, INTENT(IN), OPTIONAL :: is_macro
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: parse_module, parse_proc
        LOGICAL, INTENT(IN), OPTIONAL :: has_validate
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: validate_proc
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: idx

        ! Reg in base registry
        CALL this%Reg(keyword_name, category, priority, description, &
                           is_macro, parse_module, parse_proc, &
                           has_validate, validate_proc, status)
        IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN

        ! Insert into hash table
        idx = this%count
        IF (this%use_hash .AND. idx > 0) THEN
            CALL this%hash_table%Insert(keyword_name, idx, status)
        END IF

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE Reg_RegisterOptimized

    !=============================================================================
    ! Find Keyword (Optimized - O(1) lookup)
    !=============================================================================
    FUNCTION Reg_FindOptimized(this, keyword_name) RESULT(idx)
        CLASS(KW_RegistryOptimizedType), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4) :: idx

        CHARACTER(LEN=KW_MAX_NAME_LEN) :: kw_upper

        kw_upper = keyword_name
        CALL to_upper(kw_upper)

        IF (this%use_hash .AND. this%hash_table%is_initialized) THEN
            idx = this%hash_table%Find(kw_upper)
            IF (idx > 0 .AND. idx <= this%count) THEN
                ! Verify it's the correct keyword (handle hash collisions)
                IF (TRIM(this%keywords(idx)%keyword_name) == TRIM(kw_upper)) THEN
                    RETURN
                END IF
            END IF
        END IF

        ! Fallback to linear search
        idx = this%Find(kw_upper)
    END FUNCTION Reg_FindOptimized

    !=============================================================================
    ! Build Hash Table from Existing Registry
    !=============================================================================
    SUBROUTINE Reg_BuildHashTable(this, status)
        CLASS(KW_RegistryOptimizedType), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i

        IF (PRESENT(status)) CALL init_error_status(status)

        CALL this%hash_table%Clear()
        CALL this%hash_table%Init(HASH_TABLE_SIZE, status)
        IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, this%count
            IF (this%keywords(i)%is_registered) THEN
                CALL this%hash_table%Insert(this%keywords(i)%keyword_name, i, status)
                IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
            END IF
        END DO

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE Reg_BuildHashTable

    !=============================================================================
    ! Init Optimized Global Registry
    !=============================================================================
    SUBROUTINE KW_Registry_InitOptimizedGlobal(status)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        CALL g_kw_registry_opt%InitOptimized(status)
        IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN

        ! Copy from base registry
        IF (g_kw_registry%is_initialized) THEN
            IF (.NOT. ALLOCATED(g_kw_registry_opt%keywords)) THEN
                ALLOCATE(g_kw_registry_opt%keywords(KW_MAX_REGISTRY))
            END IF
            g_kw_registry_opt%keywords = g_kw_registry%keywords
            g_kw_registry_opt%count = g_kw_registry%count
            g_kw_registry_opt%is_initialized = g_kw_registry%is_initialized
        END IF

        ! Build hash table
        CALL g_kw_registry_opt%BuildHashTable(status)

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Registry_InitOptimizedGlobal

    !=============================================================================
    ! Fast Keyword Lookup
    !=============================================================================
    FUNCTION KW_Registry_FindKeywordFast(keyword_name) RESULT(idx)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4) :: idx

        IF (.NOT. g_kw_registry_opt%is_initialized) THEN
            CALL KW_Registry_InitOptimizedGlobal
        END IF

        idx = g_kw_registry_opt%FindOptimized(keyword_name)
    END FUNCTION KW_Registry_FindKeywordFast

    !=============================================================================
    ! Build Hash Table (Global)
    !=============================================================================
    SUBROUTINE KW_Registry_BuildHashTable(status)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (.NOT. g_kw_registry_opt%is_initialized) THEN
            CALL KW_Registry_InitOptimizedGlobal(status)
            RETURN
        END IF

        CALL g_kw_registry_opt%BuildHashTable(status)
    END SUBROUTINE KW_Registry_BuildHashTable

END MODULE MD_KW_Reg_Type


!===============================================================================
! Module: MD_KWMapper
! Purpose: Keyword to Parser Function Mapper
! Version: 1.0
! Date: 2026-02-11
! Description:
!   Maps keywords to their parsing functions
!   Ensures all keywords have corresponding parse procedures
!===============================================================================
MODULE MD_KW_Mapper_Type
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_KW_Reg_Type, ONLY: KW_RegistryType, KW_MetadataType, g_kw_registry, &
                               KW_Registry_FindKeyword
    IMPLICIT NONE
    PRIVATE

    !=============================================================================
    ! Public Interfaces
    !=============================================================================
    PUBLIC :: KW_Mapper_GetParseProc
    PUBLIC :: KW_Mapper_GetValidateProc
    PUBLIC :: KW_Mapper_CheckAllKeywordsMapped
    PUBLIC :: KW_Mapper_GenerateMappingReport

CONTAINS

    !=============================================================================
    ! Get Parse Procedure Name for Keyword
    !=============================================================================
    !=============================================================================
    !> @brief Get parse procedure name (legacy interface)
    !! @details Gets parse module and procedure names for a keyword
    !! @param[in] keyword_name Keyword name
    !! @param[out] parse_module Parse module name
    !! @param[out] parse_proc Parse procedure name
    !! @param[out] status Error status (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use KW_Find_Desc and KW_Find_State types to encapsulate lookup parameters
    !=============================================================================
    SUBROUTINE KW_Mapper_GetParseProc(keyword_name, parse_module, parse_proc, status)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        CHARACTER(LEN=*), INTENT(OUT) :: parse_module, parse_proc
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: idx

        IF (PRESENT(status)) CALL init_error_status(status)

        parse_module = ""
        parse_proc = ""

        idx = KW_Registry_FindKeyword(keyword_name)
        IF (idx <= 0) THEN
            IF (PRESENT(status)) THEN
                status%status_code = IF_STATUS_NOT_FOUND
                WRITE(status%message, '(A,A,A)') "Keyword not found: ", TRIM(keyword_name)
            END IF
            RETURN
        END IF

        parse_module = g_kw_registry%keywords(idx)%parse_module
        parse_proc = g_kw_registry%keywords(idx)%parse_proc

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Mapper_GetParseProc

    !=============================================================================
    ! Get Valid Procedure Name for Keyword
    !=============================================================================
    !=============================================================================
    !> @brief Get validation procedure name (legacy interface)
    !! @details Gets validation procedure name and flag for a keyword
    !! @param[in] keyword_name Keyword name
    !! @param[out] validate_proc Validation procedure name
    !! @param[out] has_validate Has validation flag
    !! @param[out] status Error status (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use KW_Find_Desc and KW_Find_State types to encapsulate lookup parameters
    !=============================================================================
    SUBROUTINE KW_Mapper_GetValidateProc(keyword_name, validate_proc, has_validate, status)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        CHARACTER(LEN=*), INTENT(OUT) :: validate_proc
        LOGICAL, INTENT(OUT) :: has_validate
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: idx

        IF (PRESENT(status)) CALL init_error_status(status)

        validate_proc = ""
        has_validate = .FALSE.

        idx = KW_Registry_FindKeyword(keyword_name)
        IF (idx <= 0) THEN
            IF (PRESENT(status)) THEN
                status%status_code = IF_STATUS_NOT_FOUND
                WRITE(status%message, '(A,A,A)') "Keyword not found: ", TRIM(keyword_name)
            END IF
            RETURN
        END IF

        has_validate = g_kw_registry%keywords(idx)%has_validate
        IF (has_validate) THEN
            validate_proc = g_kw_registry%keywords(idx)%validate_proc
        END IF

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Mapper_GetValidateProc

    !=============================================================================
    ! Check All Keywords Mapped
    !=============================================================================
    SUBROUTINE KW_Mapper_CheckAllKeywordsMapped(unmapped_keywords, unmapped_count, status)
        CHARACTER(LEN=64), INTENT(OUT), ALLOCATABLE :: unmapped_keywords(:)
        INTEGER(i4), INTENT(OUT) :: unmapped_count
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i
        CHARACTER(LEN=64), ALLOCATABLE :: temp(:)

        IF (PRESENT(status)) CALL init_error_status(status)

        unmapped_count = 0
        ALLOCATE(temp(g_kw_registry%count))

        DO i = 1, g_kw_registry%count
            IF (g_kw_registry%keywords(i)%is_registered) THEN
                IF (LEN_TRIM(g_kw_registry%keywords(i)%parse_proc) == 0) THEN
                    unmapped_count = unmapped_count + 1
                    temp(unmapped_count) = g_kw_registry%keywords(i)%keyword_name
                END IF
            END IF
        END DO

        IF (unmapped_count > 0) THEN
            ALLOCATE(unmapped_keywords(unmapped_count))
            unmapped_keywords(1:unmapped_count) = temp(1:unmapped_count)
        END IF
        DEALLOCATE(temp)

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Mapper_CheckAllKeywordsMapped

    !=============================================================================
    ! Generate Mapping Report
    !=============================================================================
    SUBROUTINE KW_Mapper_GenerateMappingReport(status)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i, total, with_parse, with_validate, without_parse, without_validate
        INTEGER(i4) :: p0_count, p1_count, p2_count, macro_count
        INTEGER(i4) :: p0_with_parse, p1_with_parse, p2_with_parse, macro_with_parse

        IF (PRESENT(status)) CALL init_error_status(status)

        total = g_kw_registry%count
        with_parse = 0
        with_validate = 0
        without_parse = 0
        without_validate = 0
        p0_count = 0
        p1_count = 0
        p2_count = 0
        macro_count = 0
        p0_with_parse = 0
        p1_with_parse = 0
        p2_with_parse = 0
        macro_with_parse = 0

        DO i = 1, total
            IF (g_kw_registry%keywords(i)%is_registered) THEN
                IF (LEN_TRIM(g_kw_registry%keywords(i)%parse_proc) > 0) THEN
                    with_parse = with_parse + 1
                ELSE
                    without_parse = without_parse + 1
                END IF

                IF (g_kw_registry%keywords(i)%has_validate) THEN
                    with_validate = with_validate + 1
                ELSE
                    without_validate = without_validate + 1
                END IF

                SELECT CASE (g_kw_registry%keywords(i)%priority)
                CASE (0)  ! P0
                    p0_count = p0_count + 1
                    IF (LEN_TRIM(g_kw_registry%keywords(i)%parse_proc) > 0) THEN
                        p0_with_parse = p0_with_parse + 1
                    END IF
                CASE (1)  ! P1
                    p1_count = p1_count + 1
                    IF (LEN_TRIM(g_kw_registry%keywords(i)%parse_proc) > 0) THEN
                        p1_with_parse = p1_with_parse + 1
                    END IF
                CASE (2)  ! P2
                    p2_count = p2_count + 1
                    IF (LEN_TRIM(g_kw_registry%keywords(i)%parse_proc) > 0) THEN
                        p2_with_parse = p2_with_parse + 1
                    END IF
                END SELECT

                IF (g_kw_registry%keywords(i)%is_macro) THEN
                    macro_count = macro_count + 1
                    IF (LEN_TRIM(g_kw_registry%keywords(i)%parse_proc) > 0) THEN
                        macro_with_parse = macro_with_parse + 1
                    END IF
                END IF
            END IF
        END DO

        ! Print report
        PRINT *, "============================================"
        PRINT *, "  Keyword Mapping Report"
        PRINT *, "============================================"
        PRINT *, ""
        PRINT '(A,I0)', "Total Keywords Registered: ", total
        PRINT '(A,I0,A,I0)', "  With Parse Function: ", with_parse, " / ", total
        PRINT '(A,I0,A,I0)', "  With Valid Function: ", with_validate, " / ", total
        PRINT *, ""
        PRINT '(A,I0,A,I0)', "P0 Keywords: ", p0_with_parse, " / ", p0_count, " with parse"
        PRINT '(A,I0,A,I0)', "P1 Keywords: ", p1_with_parse, " / ", p1_count, " with parse"
        PRINT '(A,I0,A,I0)', "P2 Keywords: ", p2_with_parse, " / ", p2_count, " with parse"
        PRINT '(A,I0,A,I0)', "Macro Commands: ", macro_with_parse, " / ", macro_count, " with parse"
        PRINT *, ""
        PRINT *, "============================================"

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Mapper_GenerateMappingReport

END MODULE MD_KW_Mapper_Type


!===============================================================================
! Module: MD_KW_Extension
! Purpose: Keyword Extension Mechanism - Easy Addition of New Keywords
! Version: 1.0
! Date: 2026-02-11
! Description:
!   Provides easy mechanism for adding new keywords without modifying core registry
!   Supports plugin-style keyword registration
!===============================================================================
MODULE MD_KW_Extension_Type
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_KW_Coverage_Type, ONLY: KW_PRIORITY_P0, KW_PRIORITY_P1, KW_PRIORITY_P2
    USE MD_KW_Reg_Type, ONLY: KW_RegistryType, KW_MetadataType, g_kw_registry, &
                               KW_CAT_MODEL, KW_CAT_PART, KW_CAT_MESH, &
                               KW_CAT_MATERIAL, KW_CAT_SECTION, KW_CAT_CONSTRAINT, &
                               KW_CAT_LOAD, KW_CAT_CONTACT, KW_CAT_STEP, &
                               KW_CAT_OUTPUT, KW_CAT_AMPLITUDE, KW_CAT_MACRO
    IMPLICIT NONE
    PRIVATE

    !=============================================================================
    ! Extension Plugin Type
    !=============================================================================
    !> @brief Extension plugin type (Desc category)
    !! @details Plugin for extending keyword registry with custom keywords
    !!   Theory: Plugin with name, version, description, keyword array, loaded flag
    TYPE, PUBLIC :: KW_ExtensionPluginType
        CHARACTER(LEN=64) :: plugin_name = ""                      ! Plugin name
        CHARACTER(LEN=256) :: plugin_version = ""                  ! Plugin version
        CHARACTER(LEN=256) :: plugin_description = ""              ! Plugin description
        INTEGER(i4) :: keyword_count = 0                            ! Keyword count n_keywords  ? ?
        TYPE(KW_MetadataType), ALLOCATABLE :: keywords(:)           ! Keyword array
        LOGICAL :: is_loaded = .FALSE.                              ! Loaded flag
    CONTAINS
        PROCEDURE, PUBLIC :: Init => Plugin_Init
        PROCEDURE, PUBLIC :: AddKeyword => Plugin_AddKeyword
        PROCEDURE, PUBLIC :: Reg => Plugin_Reg
        PROCEDURE, PUBLIC :: Unregister => Plugin_Unregister
    END TYPE KW_ExtensionPluginType

    !=============================================================================
    ! Extension Manager Type
    !=============================================================================
    !> @brief Extension manager type (Ctx category)
    !! @details Manages extension plugins for keyword registry
    !!   Theory: Manager with n_plugins plugins, plugin array, initialization flag
    TYPE, PUBLIC :: KW_ExtensionManagerType
        INTEGER(i4) :: plugin_count = 0                            ! Plugin count n_plugins  ? ?
        TYPE(KW_ExtensionPluginType), ALLOCATABLE :: plugins(:)      ! Plugin array
        LOGICAL :: is_initialized = .FALSE.                          ! Initialization flag
    CONTAINS
        PROCEDURE, PUBLIC :: Init => Init_Mgr
        PROCEDURE, PUBLIC :: LoadPlugin => LoadPlugin_Mgr
        PROCEDURE, PUBLIC :: UnloadPlugin => UnloadPlugin_Mgr
        PROCEDURE, PUBLIC :: ListPlugins => ListPlugins_Mgr
        PROCEDURE, PUBLIC :: GetPlugin => GetPlugin_Mgr
    END TYPE KW_ExtensionManagerType

    !=============================================================================
    ! Global Extension Manager
    !=============================================================================
    TYPE(KW_ExtensionManagerType), SAVE, PUBLIC :: g_extension_mgr

    !=============================================================================
    ! Public Interfaces
    !=============================================================================
    PUBLIC :: KW_Extension_InitGlobal
    PUBLIC :: KW_Extension_RegisterKeyword
    PUBLIC :: KW_Extension_CreatePlugin
    PUBLIC :: KW_Extension_LoadPlugin
    PUBLIC :: KW_Extension_UnloadPlugin

CONTAINS

    !=============================================================================
    ! Init Plugin
    !=============================================================================
    SUBROUTINE Plugin_Init(this, name, version, description, status)
        CLASS(KW_ExtensionPluginType), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name, version, description
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        this%plugin_name = name
        this%plugin_version = version
        this%plugin_description = description
        this%keyword_count = 0
        this%is_loaded = .FALSE.

        IF (.NOT. ALLOCATED(this%keywords)) THEN
            ALLOCATE(this%keywords(100))  !  100
        END IF

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE Plugin_Init

    !=============================================================================
    ! Add Keyword to Plugin
    !=============================================================================
    SUBROUTINE Plugin_AddKeyword(this, keyword_name, category, priority, &
                                  description, is_macro, parse_module, &
                                  parse_proc, has_validate, validate_proc, status)
        CLASS(KW_ExtensionPluginType), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4), INTENT(IN) :: category, priority
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: description
        LOGICAL, INTENT(IN), OPTIONAL :: is_macro
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: parse_module, parse_proc
        LOGICAL, INTENT(IN), OPTIONAL :: has_validate
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: validate_proc
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: idx

        IF (PRESENT(status)) CALL init_error_status(status)

        IF (.NOT. ALLOCATED(this%keywords)) THEN
            CALL this%Init("", "", "", status)
            IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
        END IF

        IF (this%keyword_count >= SIZE(this%keywords)) THEN
            IF (PRESENT(status)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Plugin keyword capacity exceeded"
            END IF
            RETURN
        END IF

        idx = this%keyword_count + 1
        this%keyword_count = idx

        this%keywords(idx)%keyword_name = keyword_name
        this%keywords(idx)%category = category
        this%keywords(idx)%priority = priority
        IF (PRESENT(description)) this%keywords(idx)%cfg%description = description
        IF (PRESENT(is_macro)) this%keywords(idx)%is_macro = is_macro
        IF (PRESENT(parse_module)) this%keywords(idx)%parse_module = parse_module
        IF (PRESENT(parse_proc)) this%keywords(idx)%parse_proc = parse_proc
        IF (PRESENT(has_validate)) this%keywords(idx)%has_validate = has_validate
        IF (PRESENT(validate_proc)) this%keywords(idx)%validate_proc = validate_proc
        this%keywords(idx)%is_registered = .FALSE.

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE Plugin_AddKeyword

    !=============================================================================
    ! Reg Plugin Keywords
    !=============================================================================
    SUBROUTINE Plugin_Reg(this, status)
        CLASS(KW_ExtensionPluginType), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i
        TYPE(ErrorStatusType) :: local_status

        IF (PRESENT(status)) CALL init_error_status(status)
        CALL init_error_status(local_status)

        DO i = 1, this%keyword_count
            CALL g_kw_registry%Reg( &
                this%keywords(i)%keyword_name, &
                this%keywords(i)%category, &
                this%keywords(i)%priority, &
                description=this%keywords(i)%cfg%description, &
                is_macro=this%keywords(i)%is_macro, &
                parse_module=this%keywords(i)%parse_module, &
                parse_proc=this%keywords(i)%parse_proc, &
                has_validate=this%keywords(i)%has_validate, &
                validate_proc=this%keywords(i)%validate_proc, &
                status=local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                IF (PRESENT(status)) status = local_status
                RETURN
            END IF
            this%keywords(i)%is_registered = .TRUE.
        END DO

        this%is_loaded = .TRUE.

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE Plugin_Reg

    !=============================================================================
    ! Unregister Plugin Keywords
    !=============================================================================
    SUBROUTINE Plugin_Unregister(this, status)
        CLASS(KW_ExtensionPluginType), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        ! Note: Unregistering keywords is complex as they may be in use
        ! For now, just mark as unloaded
        IF (PRESENT(status)) CALL init_error_status(status)

        this%is_loaded = .FALSE.

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE Plugin_Unregister

    !=============================================================================
    ! Init Extension Manager
    !=============================================================================
    SUBROUTINE Init_Mgr(this, status)
        CLASS(KW_ExtensionManagerType), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        IF (.NOT. ALLOCATED(this%plugins)) THEN
            ALLOCATE(this%plugins(50))  ! Support up to 50 plugins
        END IF

        this%plugin_count = 0
        this%is_initialized = .TRUE.

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE Init_Mgr

    !=============================================================================
    ! Load Plugin
    !=============================================================================
    SUBROUTINE LoadPlugin_Mgr(this, plugin, status)
        CLASS(KW_ExtensionManagerType), INTENT(INOUT) :: this
        TYPE(KW_ExtensionPluginType), INTENT(INOUT) :: plugin
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: idx

        IF (PRESENT(status)) CALL init_error_status(status)

        IF (.NOT. this%is_initialized) THEN
            CALL this%Init(status)
            IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
        END IF

        IF (this%plugin_count >= SIZE(this%plugins)) THEN
            IF (PRESENT(status)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Extension manager plugin capacity exceeded"
            END IF
            RETURN
        END IF

        ! Reg plugin keywords
        CALL plugin%Reg(status)
        IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN

        ! Add to manager
        idx = this%plugin_count + 1
        this%plugin_count = idx
        this%plugins(idx) = plugin

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE LoadPlugin_Mgr

    !=============================================================================
    ! Unload Plugin
    !=============================================================================
    SUBROUTINE UnloadPlugin_Mgr(this, plugin_name, status)
        CLASS(KW_ExtensionManagerType), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: plugin_name
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i, idx

        IF (PRESENT(status)) CALL init_error_status(status)

        idx = 0
        DO i = 1, this%plugin_count
            IF (TRIM(this%plugins(i)%plugin_name) == TRIM(plugin_name)) THEN
                idx = i
                EXIT
            END IF
        END DO

        IF (idx == 0) THEN
            IF (PRESENT(status)) THEN
                status%status_code = IF_STATUS_INVALID
                WRITE(status%message, '(A,A,A)') "Plugin not found: ", TRIM(plugin_name)
            END IF
            RETURN
        END IF

        ! Unregister plugin
        CALL this%plugins(idx)%Unregister(status)
        IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN

        ! Remove from manager (shift remaining plugins)
        DO i = idx, this%plugin_count - 1
            this%plugins(i) = this%plugins(i + 1)
        END DO
        this%plugin_count = this%plugin_count - 1

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE UnloadPlugin_Mgr

    !=============================================================================
    ! List Plugins
    !=============================================================================
    SUBROUTINE ListPlugins_Mgr(this, plugin_names, count)
        CLASS(KW_ExtensionManagerType), INTENT(IN) :: this
        CHARACTER(LEN=64), INTENT(OUT), ALLOCATABLE :: plugin_names(:)
        INTEGER(i4), INTENT(OUT) :: count

        INTEGER(i4) :: i

        count = this%plugin_count
        IF (count > 0) THEN
            ALLOCATE(plugin_names(count))
            DO i = 1, count
                plugin_names(i) = this%plugins(i)%plugin_name
            END DO
        END IF
    END SUBROUTINE ListPlugins_Mgr

    !=============================================================================
    ! Get Plugin
    !=============================================================================
    SUBROUTINE GetPlugin_Mgr(this, plugin_name, plugin_out, found)
        CLASS(KW_ExtensionManagerType), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: plugin_name
        TYPE(KW_ExtensionPluginType), INTENT(OUT) :: plugin_out
        LOGICAL, INTENT(OUT) :: found

        INTEGER(i4) :: i

        found = .FALSE.
        DO i = 1, this%plugin_count
            IF (TRIM(this%plugins(i)%plugin_name) == TRIM(plugin_name)) THEN
                plugin_out = this%plugins(i)
                found = .TRUE.
                RETURN
            END IF
        END DO
    END SUBROUTINE GetPlugin_Mgr

    !=============================================================================
    ! Init Global Extension Manager
    !=============================================================================
    SUBROUTINE KW_Extension_InitGlobal(status)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        CALL g_extension_mgr%Init(status)

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE KW_Extension_InitGlobal

    !=============================================================================
    ! Reg Keyword (Convenience Function)
    !=============================================================================
    SUBROUTINE KW_Extension_RegisterKeyword(keyword_name, category, priority, &
                                             description, is_macro, parse_module, &
                                             parse_proc, has_validate, validate_proc, status)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4), INTENT(IN) :: category, priority
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: description
        LOGICAL, INTENT(IN), OPTIONAL :: is_macro
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: parse_module, parse_proc
        LOGICAL, INTENT(IN), OPTIONAL :: has_validate
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: validate_proc
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        CALL g_kw_registry%Reg(keyword_name, category, priority, &
                                     description, is_macro, parse_module, &
                                     parse_proc, has_validate, validate_proc, status)
    END SUBROUTINE KW_Extension_RegisterKeyword

    !=============================================================================
    ! Create Plugin
    !=============================================================================
    SUBROUTINE KW_Extension_CreatePlugin(name, version, description, plugin, status)
        CHARACTER(LEN=*), INTENT(IN) :: name, version, description
        TYPE(KW_ExtensionPluginType), INTENT(OUT) :: plugin
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        CALL plugin%Init(name, version, description, status)
    END SUBROUTINE KW_Extension_CreatePlugin

    !=============================================================================
    ! Load Plugin (Global)
    !=============================================================================
    SUBROUTINE KW_Extension_LoadPlugin(plugin, status)
        TYPE(KW_ExtensionPluginType), INTENT(INOUT) :: plugin
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (.NOT. g_extension_mgr%is_initialized) THEN
            CALL KW_Extension_InitGlobal(status)
            IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
        END IF

        CALL g_extension_mgr%LoadPlugin(plugin, status)
    END SUBROUTINE KW_Extension_LoadPlugin

    !=============================================================================
    ! Unload Plugin (Global)
    !=============================================================================
    SUBROUTINE KW_Extension_UnloadPlugin(plugin_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: plugin_name
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (.NOT. g_extension_mgr%is_initialized) THEN
            IF (PRESENT(status)) CALL init_error_status(status)
            RETURN
        END IF

        CALL g_extension_mgr%UnloadPlugin(plugin_name, status)
    END SUBROUTINE KW_Extension_UnloadPlugin

END MODULE MD_KW_Extension_Type

!===============================================================================
! Module: MD_KW (facade)
! Purpose: Single USE point for coverage audit + registry types + **AST/Token
!   exports for MD_KWRT_Brg** (merged from former `MD_KeyWord.f90` re-export file).
!   Submodules above: MD_KW_Coverage_Type, MD_KW_Registry_Type, MD_KW_Mapper_Type,
!   MD_KW_Extension_Type. Callers (e.g. MD_KeyWordDomain, MD_ModelLib) USE
!   MD_KW instead of reaching into *_Type modules directly.
!===============================================================================
MODULE MD_KW
  USE MD_KW_Coverage_Type, ONLY: &
      KW_Coverage_Report, KW_Priority_Check, &
      KW_Audit_P0_Must, KW_Audit_P1_Important, KW_Audit_P2_Optional, KW_Generate_Report, &
      KW_PRIORITY_P0, KW_PRIORITY_P1, KW_PRIORITY_P2
  USE MD_KW_Reg_Type, ONLY: &
      KW_RegistryType, KW_MetadataType, KW_RegistryOptimizedType, KW_HashTableType, &
      g_kw_registry, g_kw_registry_opt
  USE MD_KW_Def, ONLY: &
      KW_ASTNodeType, &
      KW_MAX_NAME_LEN, KW_MAX_VALUE_LEN, KW_MAX_PARAMS, &
      KW_MAX_CHILDREN, KW_MAX_DATA_COLS, KW_MAX_DESC_LEN, &
      TOKEN_KEYWORD, TOKEN_PARAM_NAME, TOKEN_PARAM_VALUE, TOKEN_DATA, &
      TOKEN_COMMENT, TOKEN_EOF, TOKEN_INVALID, &
      KW_CAT_MODEL, KW_CAT_PART, KW_CAT_MESH, &
      KW_CAT_MATERIAL, KW_CAT_SECTION, KW_CAT_OTHER
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: KW_Coverage_Report, KW_Priority_Check
  PUBLIC :: KW_Audit_P0_Must, KW_Audit_P1_Important, KW_Audit_P2_Optional, KW_Generate_Report
  PUBLIC :: KW_PRIORITY_P0, KW_PRIORITY_P1, KW_PRIORITY_P2
  PUBLIC :: KW_RegistryType, KW_MetadataType, KW_RegistryOptimizedType, KW_HashTableType
  PUBLIC :: g_kw_registry, g_kw_registry_opt
  ! Bridge / parser facade (from MD_KW_Def via single MODULE MD_KW — pilot dedupe)
  PUBLIC :: KW_ASTNodeType
  PUBLIC :: KW_MAX_NAME_LEN, KW_MAX_VALUE_LEN, KW_MAX_PARAMS
  PUBLIC :: KW_MAX_CHILDREN, KW_MAX_DATA_COLS, KW_MAX_DESC_LEN
  PUBLIC :: TOKEN_KEYWORD, TOKEN_PARAM_NAME, TOKEN_PARAM_VALUE, TOKEN_DATA
  PUBLIC :: TOKEN_COMMENT, TOKEN_EOF, TOKEN_INVALID
  PUBLIC :: KW_CAT_MODEL, KW_CAT_PART, KW_CAT_MESH
  PUBLIC :: KW_CAT_MATERIAL, KW_CAT_SECTION, KW_CAT_OTHER
END MODULE MD_KW