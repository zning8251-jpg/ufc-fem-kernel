!===============================================================================
! MODULE: RT_Elem_ComputeProc
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Proc — Computation scheduler (Ke/Fe/Me/Ce) via RT_ElemKernelProc
! BRIEF:  Schedules element computation requests.  SKELETON.
!         Production routes through RT_AsmSolv → L4 PH_ElemCalcWrapper.
!===============================================================================
MODULE RT_Elem_ComputeProc
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE RT_Elem_Def, ONLY: RT_Elem_State, RT_Elem_Ctx
  USE RT_Elem_KernelProc, ONLY: RT_Elem_Kernel_In, RT_Elem_Kernel_Out

  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! TYPE: RT_Elem_Compute_Args
  ! Computation arguments container
  !============================================================================
  TYPE, PUBLIC :: RT_Elem_Compute_Args
    !-- Input data
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
    LOGICAL :: nlgeom = .FALSE.
    LOGICAL :: compute_ke = .FALSE.
    LOGICAL :: compute_fe = .FALSE.
    LOGICAL :: compute_me = .FALSE.
    LOGICAL :: compute_ce = .FALSE.
    
  END TYPE RT_Elem_Compute_Args

  !============================================================================
  ! Public interfaces
  !============================================================================
  PUBLIC :: RT_Element_Compute_Ke
  PUBLIC :: RT_Element_Compute_Fe
  PUBLIC :: RT_Element_Compute_Me
  PUBLIC :: RT_Element_Compute_All

CONTAINS

  !============================================================================
  ! Subroutine: RT_Element_Compute_Ke
  ! Purpose: Compute element stiffness matrix
  !============================================================================
  SUBROUTINE RT_Element_Compute_Ke(state, ctx, args, amatrx, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Elem_Compute_Args), INTENT(IN) :: args
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: amatrx(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(RT_Elem_Kernel_In) :: inp
    TYPE(RT_Elem_Kernel_Out) :: out

    ! Setup input
    CALL Setup_Kernel_In(inp, args)
    inp%stp%nlgeom = args%stp%nlgeom
    inp%calc_type = 1  ! Ke only

    CALL RT_Elem_Kernel_Compute(state, ctx, inp, out, status)

    IF (status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(out%amatrx)) THEN
        amatrx = out%amatrx
      ELSE
        CALL init_error_status(status, STATUS_ERR, "Ke not computed")
      END IF
    END IF

  END SUBROUTINE RT_Element_Compute_Ke

  !============================================================================
  ! Subroutine: RT_Element_Compute_Fe
  ! Purpose: Compute element force residual
  !============================================================================
  SUBROUTINE RT_Element_Compute_Fe(state, ctx, args, rhs, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Elem_Compute_Args), INTENT(IN) :: args
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: rhs(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(RT_Elem_Kernel_In) :: inp
    TYPE(RT_Elem_Kernel_Out) :: out

    ! Setup input
    CALL Setup_Kernel_In(inp, args)
    inp%stp%nlgeom = args%stp%nlgeom
    inp%calc_type = 2  ! Fe only

    CALL RT_Elem_Kernel_Compute(state, ctx, inp, out, status)

    IF (status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(out%rhs)) THEN
        rhs = out%rhs
      ELSE
        CALL init_error_status(status, STATUS_ERR, "Fe not computed")
      END IF
    END IF

  END SUBROUTINE RT_Element_Compute_Fe

  !============================================================================
  ! Subroutine: RT_Element_Compute_Me
  ! Purpose: Compute element mass matrix
  !============================================================================
  SUBROUTINE RT_Element_Compute_Me(state, ctx, args, mass, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Elem_Compute_Args), INTENT(IN) :: args
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: mass(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(RT_Elem_Kernel_In) :: inp
    TYPE(RT_Elem_Kernel_Out) :: out

    ! Setup input
    CALL Setup_Kernel_In(inp, args)
    inp%calc_type = 3  ! Me only

    CALL RT_Elem_Kernel_Compute(state, ctx, inp, out, status)

    IF (status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(out%mass)) THEN
        mass = out%mass
      ELSE
        CALL init_error_status(status, STATUS_ERR, "Me not computed")
      END IF
    END IF

  END SUBROUTINE RT_Element_Compute_Me

  !============================================================================
  ! Subroutine: RT_Element_Compute_All
  ! Purpose: Compute all element matrices (Ke + Fe + Me)
  !============================================================================
  SUBROUTINE RT_Element_Compute_All(state, ctx, args, &
                                    amatrx, rhs, mass, damp, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Elem_Compute_Args), INTENT(IN) :: args
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: amatrx(:,:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: rhs(:,:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: mass(:,:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: damp(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(RT_Elem_Kernel_In) :: inp
    TYPE(RT_Elem_Kernel_Out) :: out

    ! Setup input
    CALL Setup_Kernel_In(inp, args)
    inp%stp%nlgeom = args%stp%nlgeom
    inp%calc_type = 0  ! Full computation

    CALL RT_Elem_Kernel_Compute(state, ctx, inp, out, status)

    IF (status%status_code == IF_STATUS_OK) THEN
      ! Transfer outputs
      IF (ALLOCATED(out%amatrx)) amatrx = out%amatrx
      IF (ALLOCATED(out%rhs)) rhs = out%rhs
      IF (ALLOCATED(out%mass)) mass = out%mass
      IF (ALLOCATED(out%damp)) damp = out%damp

      ! Update state variables
      IF (ALLOCATED(out%statev)) THEN
        state%statev = out%statev
      END IF

      ! Update energy
      IF (ALLOCATED(out%energy)) THEN
        state%energy(1:MIN(8,SIZE(out%energy))) = out%energy(1:MIN(8,SIZE(out%energy)))
      END IF
    END IF

  END SUBROUTINE RT_Element_Compute_All

  !============================================================================
  ! Private helpers
  !============================================================================

  SUBROUTINE Setup_Kernel_In(inp, ctx, args)
    TYPE(RT_Elem_Kernel_In), INTENT(OUT) :: inp
    TYPE(RT_Elem_Ctx), INTENT(IN) :: ctx
    TYPE(RT_Elem_Compute_Args), INTENT(IN) :: args

    inp%elem_id = ctx%base%cfg%elem_type_id
    inp%cfg%elem_type_id = ctx%base%cfg%elem_type_id
    inp%step_id = args%kstep

    ! Copy nodal data
    IF (ALLOCATED(args%coords)) inp%coords = args%coords
    IF (ALLOCATED(args%displ)) inp%displ = args%displ
    IF (ALLOCATED(args%vel)) inp%vel = args%vel
    IF (ALLOCATED(args%accel)) inp%accel = args%accel

    ! Time and loading
    inp%time = args%time
    inp%dtime = args%dtime
    inp%kstep = args%kstep
    inp%kinc = args%kinc

  END SUBROUTINE Setup_Kernel_In

END MODULE RT_Elem_ComputeProc