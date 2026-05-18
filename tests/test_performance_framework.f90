! ================================================================================
! Program: test_performance_framework
! ================================================================================
! Purpose:
!   Performance benchmark framework for Phase 4 KeyWord Enhancement Project
!   Measures and analyzes parsing, validation, and mapping performance
!
! Author: UFC Development Team
! Date: 2026-04-12 (Week 3 Day 3)
! Version: v1.0 (Performance Benchmark Framework)
! ================================================================================

PROGRAM test_performance_framework
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType
  USE MD_KeyWord_Parser_Types
  USE MD_KeyWord_Parser_Recursive
  USE MD_KeyWord_Validator
  IMPLICIT NONE

  ! Performance counters
  REAL(wp) :: start_time, end_time
  REAL(wp) :: parse_time_total = 0.0_wp
  REAL(wp) :: validate_time_total = 0.0_wp
  REAL(wp) :: map_time_total = 0.0_wp
  
  INTEGER(i4) :: test_count = 0
  INTEGER(i4) :: i, j
  
  CHARACTER(len=256) :: test_keywords(10)
  CHARACTER(len=256) :: line
  CHARACTER(len=32) :: keyword_name
  CHARACTER(len=256), ALLOCATABLE :: params(:)
  LOGICAL :: is_keyword, is_valid
  TYPE(ErrorStatusType) :: status, val_status
  
  ! Initialize
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') "Phase 4 KeyWord Performance Benchmark Framework"
  WRITE(*, '(A)') "Week 3 Day 3: Performance Analysis"
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') ""
  
  ! Setup test keywords
  test_keywords(1) = "*PART, NAME=TEST_PART"
  test_keywords(2) = "*MATERIAL, NAME=STEEL"
  test_keywords(3) = "*ELASTIC, TYPE=ISO"
  test_keywords(4) = "*ELEMENT, TYPE=C3D8, ELSET=ELEMENTS"
  test_keywords(5) = "*NODE, NSET=ALL_NODES"
  test_keywords(6) = "*ASSEMBLY"
  test_keywords(7) = "*STEP, NAME=ANALYSIS"
  test_keywords(8) = "*STATIC"
  test_keywords(9) = "*OUTPUT"
  test_keywords(10) = "*END STEP"
  
  ! ============================================================================
  ! Test Group 1: Parsing Performance (1000 iterations)
  ! ============================================================================
  WRITE(*, '(A)') "--- Test 1: Parsing Performance (1000 iterations) ---"
  
  CALL CPU_TIME(start_time)
  
  DO i = 1, 1000
    DO j = 1, 10
      CALL MD_Parse_Line(test_keywords(j), is_keyword, keyword_name, params, status)
      IF (ALLOCATED(params)) DEALLOCATE(params)
    END DO
  END DO
  
  CALL CPU_TIME(end_time)
  parse_time_total = end_time - start_time
  
  WRITE(*, '(A,F10.6,A)') "  Parse Time:  ", parse_time_total, " seconds"
  WRITE(*, '(A,F10.6,A)') "  Per keyword: ", parse_time_total / 10000.0_wp * 1e6, " microseconds"
  WRITE(*, '(A)') ""
  
  ! ============================================================================
  ! Test Group 2: Validation Performance (1000 iterations)
  ! ============================================================================
  WRITE(*, '(A)') "--- Test 2: Validation Performance (1000 iterations) ---"
  
  CALL CPU_TIME(start_time)
  
  DO i = 1, 1000
    DO j = 1, 10
      CALL MD_Is_Valid_Keyword(test_keywords(j), is_valid, val_status)
    END DO
  END DO
  
  CALL CPU_TIME(end_time)
  validate_time_total = end_time - start_time
  
  WRITE(*, '(A,F10.6,A)') "  Validate Time: ", validate_time_total, " seconds"
  WRITE(*, '(A,F10.6,A)') "  Per keyword:  ", validate_time_total / 10000.0_wp * 1e6, " microseconds"
  WRITE(*, '(A)') ""
  
  ! ============================================================================
  ! Test Group 3: Combined Workflow Performance (100 iterations)
  ! ============================================================================
  WRITE(*, '(A)') "--- Test 3: Combined Workflow (100 iterations) ---"
  
  CALL CPU_TIME(start_time)
  
  DO i = 1, 100
    DO j = 1, 10
      ! Parse
      CALL MD_Parse_Line(test_keywords(j), is_keyword, keyword_name, params, status)
      
      ! Validate
      IF (is_keyword) THEN
        CALL MD_Is_Valid_Keyword(keyword_name, is_valid, val_status)
      END IF
      
      IF (ALLOCATED(params)) DEALLOCATE(params)
    END DO
  END DO
  
  CALL CPU_TIME(end_time)
  map_time_total = end_time - start_time
  
  WRITE(*, '(A,F10.6,A)') "  Total Time:  ", map_time_total, " seconds"
  WRITE(*, '(A,F10.6,A)') "  Per workflow:", map_time_total / 1000.0_wp * 1e6, " microseconds"
  WRITE(*, '(A)') ""
  
  ! ============================================================================
  ! Performance Summary Report
  ! ============================================================================
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') "                 PERFORMANCE SUMMARY"
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A,F10.6,A)') "  Parsing:     ", parse_time_total, " seconds (10000 ops)"
  WRITE(*, '(A,F10.6,A)') "  Validation:  ", validate_time_total, " seconds (10000 ops)"
  WRITE(*, '(A,F10.6,A)') "  Combined:    ", map_time_total, " seconds (1000 workflows)"
  WRITE(*, '(A)') ""
  WRITE(*, '(A,F10.6,A)') "  Throughput:  ", 1000.0_wp / map_time_total, " workflows/second"
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') ""

END PROGRAM test_performance_framework
