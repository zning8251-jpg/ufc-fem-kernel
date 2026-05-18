!===============================================================================
! MODULE: RT_Asm_Color
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Util
! BRIEF:  Greedy graph-coloring for race-free parallel assembly
!===============================================================================
!
! Algorithm:
!   1. Build element adjacency via shared DOF analysis
!   2. Greedy coloring: assign smallest available color to each element
!   3. Return color_of(1:n_elem) and n_colors
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Asm_Color
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_AsmColor_Build
  PUBLIC :: RT_AsmColor_Result

  TYPE :: RT_AsmColor_Result
    INTEGER(i4), ALLOCATABLE :: color_of(:)
    INTEGER(i4) :: n_colors = 0_i4
    INTEGER(i4), ALLOCATABLE :: color_count(:)
    INTEGER(i4), ALLOCATABLE :: color_start(:)
    INTEGER(i4), ALLOCATABLE :: color_elems(:)
  END TYPE RT_AsmColor_Result

CONTAINS

  SUBROUTINE RT_AsmColor_Build(n_elem, n_dof_per_elem, elem_dof_table, &
                               result, status)
    INTEGER(i4), INTENT(IN) :: n_elem
    INTEGER(i4), INTENT(IN) :: n_dof_per_elem
    INTEGER(i4), INTENT(IN) :: elem_dof_table(n_dof_per_elem, n_elem)
    TYPE(RT_AsmColor_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: ie, je, id, jd, c, max_colors
    INTEGER(i4) :: n_neighbors, max_adj
    LOGICAL :: conflict
    LOGICAL, ALLOCATABLE :: used_colors(:)

    INTEGER(i4), ALLOCATABLE :: dof_to_elem_count(:)
    INTEGER(i4), ALLOCATABLE :: dof_to_elem_start(:)
    INTEGER(i4), ALLOCATABLE :: dof_to_elem_list(:)
    INTEGER(i4) :: max_dof, dof_val, pos

    CALL init_error_status(status)

    IF (n_elem < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "n_elem must be > 0"
      RETURN
    END IF

    ALLOCATE(result%color_of(n_elem))
    result%color_of = 0_i4

    ! --- Build DOF-to-element inverse map ---
    max_dof = MAXVAL(elem_dof_table)
    IF (max_dof < 1) THEN
      result%color_of = 1_i4
      result%n_colors = 1_i4
      CALL build_color_groups(result, n_elem)
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ALLOCATE(dof_to_elem_count(max_dof))
    dof_to_elem_count = 0_i4

    DO ie = 1, n_elem
      DO id = 1, n_dof_per_elem
        dof_val = elem_dof_table(id, ie)
        IF (dof_val > 0) dof_to_elem_count(dof_val) = &
          dof_to_elem_count(dof_val) + 1
      END DO
    END DO

    ALLOCATE(dof_to_elem_start(max_dof + 1))
    dof_to_elem_start(1) = 1
    DO id = 1, max_dof
      dof_to_elem_start(id + 1) = dof_to_elem_start(id) + &
                                    dof_to_elem_count(id)
    END DO

    ALLOCATE(dof_to_elem_list(dof_to_elem_start(max_dof + 1) - 1))
    dof_to_elem_count = 0_i4

    DO ie = 1, n_elem
      DO id = 1, n_dof_per_elem
        dof_val = elem_dof_table(id, ie)
        IF (dof_val > 0) THEN
          pos = dof_to_elem_start(dof_val) + dof_to_elem_count(dof_val)
          dof_to_elem_list(pos) = ie
          dof_to_elem_count(dof_val) = dof_to_elem_count(dof_val) + 1
        END IF
      END DO
    END DO

    ! --- Greedy coloring ---
    max_colors = MIN(n_elem, 256)
    ALLOCATE(used_colors(max_colors))

    DO ie = 1, n_elem
      used_colors = .FALSE.

      DO id = 1, n_dof_per_elem
        dof_val = elem_dof_table(id, ie)
        IF (dof_val < 1 .OR. dof_val > max_dof) CYCLE
        DO pos = dof_to_elem_start(dof_val), &
                 dof_to_elem_start(dof_val + 1) - 1
          je = dof_to_elem_list(pos)
          IF (je /= ie .AND. result%color_of(je) > 0) THEN
            IF (result%color_of(je) <= max_colors) THEN
              used_colors(result%color_of(je)) = .TRUE.
            END IF
          END IF
        END DO
      END DO

      DO c = 1, max_colors
        IF (.NOT. used_colors(c)) THEN
          result%color_of(ie) = c
          EXIT
        END IF
      END DO

      IF (result%color_of(ie) == 0) THEN
        result%color_of(ie) = max_colors + 1
      END IF
    END DO

    result%n_colors = MAXVAL(result%color_of)

    DEALLOCATE(used_colors)
    DEALLOCATE(dof_to_elem_count, dof_to_elem_start, dof_to_elem_list)

    CALL build_color_groups(result, n_elem)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_AsmColor_Build

  SUBROUTINE build_color_groups(result, n_elem)
    TYPE(RT_AsmColor_Result), INTENT(INOUT) :: result
    INTEGER(i4), INTENT(IN) :: n_elem

    INTEGER(i4) :: ie, c, pos

    ALLOCATE(result%color_count(result%n_colors))
    result%color_count = 0_i4
    DO ie = 1, n_elem
      c = result%color_of(ie)
      result%color_count(c) = result%color_count(c) + 1
    END DO

    ALLOCATE(result%color_start(result%n_colors + 1))
    result%color_start(1) = 1
    DO c = 1, result%n_colors
      result%color_start(c + 1) = result%color_start(c) + &
                                   result%color_count(c)
    END DO

    ALLOCATE(result%color_elems(n_elem))
    result%color_count = 0_i4
    DO ie = 1, n_elem
      c = result%color_of(ie)
      pos = result%color_start(c) + result%color_count(c)
      result%color_elems(pos) = ie
      result%color_count(c) = result%color_count(c) + 1
    END DO

  END SUBROUTINE build_color_groups

END MODULE RT_Asm_Color
