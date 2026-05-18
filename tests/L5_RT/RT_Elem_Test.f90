!===============================================================================
! Module:  RT_Element_Test
! Layer:   L5_RT
! Domain:  Element
! Purpose: Test suite for unified Element domain types and dispatch table.
!
! Status: ACTIVE | Last verified: 2026-04-26
!===============================================================================
MODULE RT_Elem_Test
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Elem_Def
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Element_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE RT_Element_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_type_defaults()
    CALL test_dispatch_table_lifecycle()
    CALL test_ctx_dof_scratch()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[RT_Element_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE RT_Element_Run_Tests

  !---------------------------------------------------------------------------
  ! Test: All four types initialize with correct defaults
  !---------------------------------------------------------------------------
  SUBROUTINE test_type_defaults()
    TYPE(RT_Elem_Desc)  :: desc
    TYPE(RT_Elem_State) :: state
    TYPE(RT_Elem_Algo)  :: algo
    TYPE(RT_Elem_Ctx)   :: ctx

    LOGICAL :: ok

    ok = .TRUE.

    IF (desc%n_elem /= 0)        ok = .FALSE.
    IF (desc%max_nn /= 8)        ok = .FALSE.
    IF (desc%ndof_per_node /= 3) ok = .FALSE.
    IF (desc%base%n_nodes /= 0)  ok = .FALSE.

    IF (state%is_active .NEQV. .TRUE.)        ok = .FALSE.
    IF (state%nstatev /= 0)                   ok = .FALSE.
    IF (state%base%initialized .NEQV. .FALSE.) ok = .FALSE.

    IF (algo%calc_type /= 0)                 ok = .FALSE.
    IF (algo%nlgeom .NEQV. .FALSE.)          ok = .FALSE.
    IF (algo%base%integration_order /= 2)    ok = .FALSE.

    IF (ctx%elem_id /= 0)        ok = .FALSE.
    IF (ctx%node_offset /= 0)    ok = .FALSE.
    IF (ctx%base%current_ip /= 0) ok = .FALSE.

    IF (ok) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_type_defaults"
    END IF
  END SUBROUTINE test_type_defaults

  !---------------------------------------------------------------------------
  ! Test: Dispatch table allocation and entry management
  !---------------------------------------------------------------------------
  SUBROUTINE test_dispatch_table_lifecycle()
    TYPE(RT_Elem_Dispatch_Table) :: table
    LOGICAL :: ok

    ok = .TRUE.

    table%max_families = 4
    ALLOCATE(table%entries(table%max_families))
    table%n_registered = 0

    IF (.NOT. ALLOCATED(table%entries))    ok = .FALSE.
    IF (SIZE(table%entries) /= 4)          ok = .FALSE.
    IF (table%entries(1)%family_id /= 0)   ok = .FALSE.
    IF (ASSOCIATED(table%entries(1)%compute)) ok = .FALSE.

    table%entries(1)%family_id = 101
    table%n_registered = 1
    IF (table%entries(1)%family_id /= 101) ok = .FALSE.

    DEALLOCATE(table%entries)
    table%n_registered = 0

    IF (ok) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_dispatch_table_lifecycle"
    END IF
  END SUBROUTINE test_dispatch_table_lifecycle

  !---------------------------------------------------------------------------
  ! Test: Ctx DOF scratch fields work correctly
  !---------------------------------------------------------------------------
  SUBROUTINE test_ctx_dof_scratch()
    TYPE(RT_Elem_Ctx)  :: ctx
    TYPE(RT_Elem_Desc) :: desc
    INTEGER(i4) :: i, j, base_dof
    LOGICAL :: ok

    ok = .TRUE.

    desc%n_elem = 10
    desc%ndof_per_node = 3
    desc%max_nn = 8

    ctx%elem_id = 5
    ctx%nn = 4
    ctx%conn(1:4) = [1, 2, 5, 6]

    ctx%ndof_elem = ctx%nn * desc%ndof_per_node
    ctx%dof_map = 0
    DO i = 1, ctx%nn
      base_dof = (ctx%conn(i) - 1) * desc%ndof_per_node
      DO j = 1, desc%ndof_per_node
        ctx%dof_map((i - 1) * desc%ndof_per_node + j) = base_dof + j
      END DO
    END DO

    IF (ctx%ndof_elem /= 12)   ok = .FALSE.
    IF (ctx%dof_map(1) /= 1)   ok = .FALSE.
    IF (ctx%dof_map(4) /= 4)   ok = .FALSE.
    IF (ctx%dof_map(7) /= 13)  ok = .FALSE.

    IF (ok) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_ctx_dof_scratch"
    END IF
  END SUBROUTINE test_ctx_dof_scratch

END MODULE RT_Elem_Test
