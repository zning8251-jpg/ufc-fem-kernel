!===============================================================================
! MODULE: RT_Elem_AsmProc
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Proc — Standalone assembly entry point (Ke/Fe/Me/Ce → global)
! BRIEF:  SKELETON — not used by production RT_AsmSolv.  Will activate when
!         unified L5 element loop replaces L4-heavy assembly path.
!===============================================================================
MODULE RT_Elem_AsmProc
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE RT_Elem_Def, ONLY: RT_Elem_State, RT_Elem_Ctx
  USE RT_Elem_ComputeProc, ONLY: RT_Elem_Compute_Args, &
                                     RT_Element_Compute_Ke, &
                                     RT_Element_Compute_Fe, &
                                     RT_Element_Compute_Me, &
                                     RT_Element_Compute_All

  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! TYPE: RT_Elem_Assembly_In
  ! Assembly input parameters (SIO structured IO)
  !============================================================================
  TYPE, PUBLIC :: RT_Elem_Assembly_In
    !-- Element identification
    INTEGER(i4) :: elem_id = 0           ! Global element ID
    INTEGER(i4) :: n_nodes = 0           ! Number of nodes
    INTEGER(i4) :: dof_per_node = 0      ! DOFs per node
    
    !-- Connectivity and mapping
    INTEGER(i4), ALLOCATABLE :: conn(:)      ! Node connectivity [n_nodes]
    INTEGER(i4), ALLOCATABLE :: lm(:)        ! LM array (destination array) [n_dof]
    
    !-- Nodal data
    REAL(wp), ALLOCATABLE :: coords(:,:)     ! Nodal coordinates [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: displ(:,:)      ! Nodal displacements [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: vel(:,:)        ! Nodal velocities [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: accel(:,:)      ! Nodal accelerations [dim, n_nodes]
    
    !-- Time parameters
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0
    INTEGER(i4) :: kinc = 0
    
    !-- Flags
    LOGICAL :: nlgeom = .FALSE.          ! Geometric nonlinearity
    
  END TYPE RT_Elem_Assembly_In

  !============================================================================
  ! Public interfaces
  !============================================================================
  PUBLIC :: RT_Element_Assemble_Ke
  PUBLIC :: RT_Element_Assemble_Fe
  PUBLIC :: RT_Element_Assemble_Me
  PUBLIC :: RT_Element_Assemble_All

CONTAINS

  !============================================================================
  ! Subroutine: RT_Element_Assemble_Ke
  ! Purpose: Assemble element stiffness matrix into global K
  !============================================================================
  SUBROUTINE RT_Element_Assemble_Ke(state, ctx, inp, &
                                    global_k, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Elem_Assembly_In), INTENT(IN) :: inp
    REAL(wp), INTENT(INOUT) :: global_k(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), ALLOCATABLE :: amatrx(:,:)
    TYPE(RT_Elem_Compute_Args) :: args
    INTEGER(i4) :: n_dof, i, j, ii, jj

    ! Compute element stiffness
    CALL Setup_Compute_Args(args, inp)
    args%compute_ke = .TRUE.

    CALL RT_Element_Compute_Ke(state, ctx, args, amatrx, status)

    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Assemble into global matrix using LM array
    n_dof = SIZE(inp%lm)

    DO i = 1, n_dof
      ii = inp%lm(i)
      IF (ii <= 0) CYCLE  ! Skip constrained DOF

      DO j = 1, n_dof
        jj = inp%lm(j)
        IF (jj <= 0) CYCLE  ! Skip constrained DOF

        global_k(ii, jj) = global_k(ii, jj) + amatrx(i, j)
      END DO
    END DO

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE RT_Element_Assemble_Ke

  !============================================================================
  ! Subroutine: RT_Element_Assemble_Fe
  ! Purpose: Assemble element force residual into global F
  !============================================================================
  SUBROUTINE RT_Element_Assemble_Fe(state, ctx, inp, &
                                    global_f, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Elem_Assembly_In), INTENT(IN) :: inp
    REAL(wp), INTENT(INOUT) :: global_f(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), ALLOCATABLE :: rhs(:,:)
    TYPE(RT_Elem_Compute_Args) :: args
    INTEGER(i4) :: n_dof, i, ii

    ! Compute element force
    CALL Setup_Compute_Args(args, inp)
    args%compute_fe = .TRUE.

    CALL RT_Element_Compute_Fe(state, ctx, args, rhs, status)

    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Assemble into global vector using LM array
    n_dof = SIZE(inp%lm)

    DO i = 1, n_dof
      ii = inp%lm(i)
      IF (ii <= 0) CYCLE  ! Skip constrained DOF

      global_f(ii) = global_f(ii) + rhs(i, 1)
    END DO

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE RT_Element_Assemble_Fe

  !============================================================================
  ! Subroutine: RT_Element_Assemble_Me
  ! Purpose: Assemble element mass matrix into global M
  !============================================================================
  SUBROUTINE RT_Element_Assemble_Me(state, ctx, inp, &
                                    global_m, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Elem_Assembly_In), INTENT(IN) :: inp
    REAL(wp), INTENT(INOUT) :: global_m(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), ALLOCATABLE :: mass(:,:)
    TYPE(RT_Elem_Compute_Args) :: args
    INTEGER(i4) :: n_dof, i, j, ii, jj

    ! Compute element mass
    CALL Setup_Compute_Args(args, inp)
    args%compute_me = .TRUE.

    CALL RT_Element_Compute_Me(state, ctx, args, mass, status)

    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Assemble into global matrix using LM array
    n_dof = SIZE(inp%lm)

    DO i = 1, n_dof
      ii = inp%lm(i)
      IF (ii <= 0) CYCLE  ! Skip constrained DOF

      DO j = 1, n_dof
        jj = inp%lm(j)
        IF (jj <= 0) CYCLE  ! Skip constrained DOF

        global_m(ii, jj) = global_m(ii, jj) + mass(i, j)
      END DO
    END DO

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE RT_Element_Assemble_Me

  !============================================================================
  ! Subroutine: RT_Element_Assemble_All
  ! Purpose: Assemble all element matrices (Ke + Fe + Me)
  !============================================================================
  SUBROUTINE RT_Element_Assemble_All(state, ctx, inp, &
                                     global_k, global_f, global_m, &
                                     global_c, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Elem_Assembly_In), INTENT(IN) :: inp
    REAL(wp), INTENT(INOUT) :: global_k(:,:)
    REAL(wp), INTENT(INOUT) :: global_f(:)
    REAL(wp), INTENT(INOUT) :: global_m(:,:)
    REAL(wp), INTENT(INOUT) :: global_c(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), ALLOCATABLE :: amatrx(:,:), rhs(:,:), mass(:,:), damp(:,:)
    TYPE(RT_Elem_Compute_Args) :: args
    INTEGER(i4) :: n_dof, i, j, ii, jj

    ! Compute all element matrices
    CALL Setup_Compute_Args(args, inp)
    args%compute_ke = .TRUE.
    args%compute_fe = .TRUE.
    args%compute_me = .TRUE.
    args%compute_ce = .TRUE.

    CALL RT_Element_Compute_All(state, ctx, args, &
                                amatrx, rhs, mass, damp, status)

    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Assemble all into global system
    n_dof = SIZE(inp%lm)

    ! Assemble Ke
    DO i = 1, n_dof
      ii = inp%lm(i)
      IF (ii <= 0) CYCLE

      DO j = 1, n_dof
        jj = inp%lm(j)
        IF (jj <= 0) CYCLE

        global_k(ii, jj) = global_k(ii, jj) + amatrx(i, j)
      END DO
    END DO

    ! Assemble Fe
    DO i = 1, n_dof
      ii = inp%lm(i)
      IF (ii <= 0) CYCLE

      global_f(ii) = global_f(ii) + rhs(i, 1)
    END DO

    ! Assemble Me
    DO i = 1, n_dof
      ii = inp%lm(i)
      IF (ii <= 0) CYCLE

      DO j = 1, n_dof
        jj = inp%lm(j)
        IF (jj <= 0) CYCLE

        global_m(ii, jj) = global_m(ii, jj) + mass(i, j)
      END DO
    END DO

    ! Assemble Ce (if provided)
    IF (ALLOCATED(damp)) THEN
      DO i = 1, n_dof
        ii = inp%lm(i)
        IF (ii <= 0) CYCLE

        DO j = 1, n_dof
          jj = inp%lm(j)
          IF (jj <= 0) CYCLE

          global_c(ii, jj) = global_c(ii, jj) + damp(i, j)
        END DO
      END DO
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE RT_Element_Assemble_All

  !============================================================================
  ! Private helpers
  !============================================================================

  SUBROUTINE Setup_Compute_Args(args, inp)
    TYPE(RT_Elem_Compute_Args), INTENT(OUT) :: args
    TYPE(RT_Elem_Assembly_In), INTENT(IN) :: inp

    ! Copy nodal data
    IF (ALLOCATED(inp%coords)) args%coords = inp%coords
    IF (ALLOCATED(inp%displ)) args%displ = inp%displ
    IF (ALLOCATED(inp%vel)) args%vel = inp%vel
    IF (ALLOCATED(inp%accel)) args%accel = inp%accel

    ! Time parameters
    args%time = inp%time
    args%dtime = inp%dtime
    args%kstep = inp%kstep
    args%kinc = inp%kinc

    ! Flags
    args%stp%nlgeom = inp%stp%nlgeom

  END SUBROUTINE Setup_Compute_Args

END MODULE RT_Elem_AsmProc