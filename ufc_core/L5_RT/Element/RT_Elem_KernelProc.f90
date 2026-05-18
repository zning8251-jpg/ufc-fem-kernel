!===============================================================================
! MODULE: RT_Elem_KernelProc
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Proc — L5 element kernel computation wrapper (UEL-style)
! BRIEF:  Maps RT types ↔ PH types and dispatches to L4 kernels.  SKELETON.
!         Production routes through RT_ElemDispatcher → L4 directly.
! **W2**：**UEL 风格**包装层；生产 **`RT_Elem_Dispatcher`** → **`PH_Elem_*`**，本模块保持 **RT↔PH** 类型映射骨架。
!===============================================================================
MODULE RT_Elem_KernelProc
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE RT_Elem_Def, ONLY: RT_Elem_Desc, RT_Elem_State, RT_Elem_Algo, RT_Elem_Ctx
  USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_State, &
                           PH_Elem_Algo, PH_Elem_Ctx

  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! TYPE: RT_Elem_Kernel_In
  ! Kernel input parameters (SIO structured IO)
  !============================================================================
  TYPE, PUBLIC :: RT_Elem_Kernel_In
    !-- Element identification
    INTEGER(i4) :: elem_id = 0           ! Global element ID
    INTEGER(i4) :: elem_type_id = 0      ! Element type ID
    INTEGER(i4) :: step_id = 0           ! Analysis step ID
    
    !-- Nodal data
    REAL(wp), ALLOCATABLE :: coords(:,:)     ! Nodal coordinates [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: displ(:,:)      ! Nodal displacements [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: vel(:,:)        ! Nodal velocities [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: accel(:,:)      ! Nodal accelerations [dim, n_nodes]
    
    !-- Time and loading
    REAL(wp) :: time = 0.0_wp            ! Current time
    REAL(wp) :: dtime = 0.0_wp           ! Time increment
    INTEGER(i4) :: kstep = 0             ! Step number
    INTEGER(i4) :: kinc = 0              ! Increment number
    
    !-- Flags
    LOGICAL :: nlgeom = .FALSE.          ! Geometric nonlinearity flag
    LOGICAL :: is_first_iter = .FALSE.   ! First iteration in step
    
  END TYPE RT_Elem_Kernel_In

  !============================================================================
  ! TYPE: RT_Elem_Kernel_Out
  ! Kernel output parameters (SIO structured IO)
  !============================================================================
  TYPE, PUBLIC :: RT_Elem_Kernel_Out
    !-- Element matrices
    REAL(wp), ALLOCATABLE :: amatrx(:,:)     ! Stiffness matrix [n_dof, n_dof]
    REAL(wp), ALLOCATABLE :: rhs(:,:)        ! Residual force [n_dof, 1]
    REAL(wp), ALLOCATABLE :: mass(:,:)       ! Mass matrix [n_dof, n_dof]
    REAL(wp), ALLOCATABLE :: damp(:,:)       ! Damping matrix [n_dof, n_dof]
    
    !-- State variables
    REAL(wp), ALLOCATABLE :: statev(:)       ! State variables [nstatev]
    REAL(wp), ALLOCATABLE :: energy(:)       ! Energy components [8]
    
    !-- Diagnostics
    INTEGER(i4) :: status = 0            ! Completion status
    REAL(wp) :: pnewdt = 1.0_wp          ! Time increment factor
    
  END TYPE RT_Elem_Kernel_Out

  !============================================================================
  ! Public interfaces
  !============================================================================
  PUBLIC :: RT_Elem_Kernel_Compute
  PUBLIC :: RT_Elem_Kernel_Init
  PUBLIC :: RT_Elem_Kernel_Update

CONTAINS

  !============================================================================
  ! Subroutine: RT_Elem_Kernel_Compute
  ! Purpose: Main element kernel computation entry point
  !          Implements SIO six-parameter signature
  !============================================================================
  SUBROUTINE RT_Elem_Kernel_Compute(state, ctx, inp, out, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Elem_Kernel_In), INTENT(IN) :: inp
    TYPE(RT_Elem_Kernel_Out), INTENT(OUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Local working variables
    TYPE(PH_Elem_State) :: ph_state
    TYPE(PH_Elem_Ctx) :: ph_ctx
    INTEGER(i4) :: calc_type

    ! Map RT layer to PH layer (cross-layer bridge)
    ph_state = state%base
    ph_ctx = ctx%base
    calc_type = inp%calc_type  ! From kernel input

    ! Allocate output arrays
    CALL RT_Elem_Kernel_Allocate_Out(out, ctx%base%cfg%elem_type_id, state%nstatev)

    ! Call L4_PH kernel computation
    SELECT CASE (calc_type)
    CASE (1)  ! Stiffness only
      CALL PH_ElemKeDispatch_Algo(ph_state, ph_ctx, inp, out, status)
    CASE (2)  ! Force residual only
      CALL PH_ElemFeDispatch_Algo(ph_state, ph_ctx, inp, out, status)
    CASE (3)  ! Mass matrix only
      CALL PH_ElemMassDispatch_Algo(ph_state, ph_ctx, inp, out, status)
    CASE (4)  ! Output only
      CALL PH_ElemOutDispatch_Algo(ph_state, ph_ctx, inp, out, status)
    CASE DEFAULT  ! Full computation (Ke + Fe + Mass + Out)
      CALL PH_ElemKeDispatch_Algo(ph_state, ph_ctx, inp, out, status)
      IF (status%status_code == IF_STATUS_OK) THEN
        CALL PH_ElemFeDispatch_Algo(ph_state, ph_ctx, inp, out, status)
      END IF
      IF (status%status_code == IF_STATUS_OK) THEN
        CALL PH_ElemMassDispatch_Algo(ph_state, ph_ctx, inp, out, status)
      END IF
      IF (status%status_code == IF_STATUS_OK) THEN
        CALL PH_ElemOutDispatch_Algo(ph_state, ph_ctx, inp, out, status)
      END IF
    END SELECT

    ! Update RT state from PH state
    IF (status%status_code == IF_STATUS_OK) THEN
      CALL PH_to_RT_Update(ph_state, state)
    END IF

  END SUBROUTINE RT_Elem_Kernel_Compute

  !============================================================================
  ! Subroutine: RT_Elem_Kernel_Init
  ! Purpose: Initialize element kernel state
  !============================================================================
  SUBROUTINE RT_Elem_Kernel_Init(state, nstatev, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    INTEGER(i4), INTENT(IN) :: nstatev
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (nstatev <= 0) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid nstatev")
      RETURN
    END IF

    IF (ALLOCATED(state%statev)) DEALLOCATE(state%statev)
    IF (ALLOCATED(state%energy)) DEALLOCATE(state%energy)

    ALLOCATE(state%statev(nstatev))
    ALLOCATE(state%energy(8))

    state%statev = 0.0_wp
    state%energy = 0.0_wp
    state%nstatev = nstatev

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE RT_Elem_Kernel_Init

  !============================================================================
  ! Subroutine: RT_Elem_Kernel_Update
  ! Purpose: Update element state after convergence
  !============================================================================
  SUBROUTINE RT_Elem_Kernel_Update(state, out, status)
    TYPE(RT_Elem_State), INTENT(INOUT) :: state
    TYPE(RT_Elem_Kernel_Out), INTENT(IN) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (ALLOCATED(out%statev)) THEN
      IF (SIZE(out%statev) == state%nstatev) THEN
        state%statev = out%statev
      END IF
    END IF

    IF (ALLOCATED(out%energy)) THEN
      IF (SIZE(out%energy) >= 8) THEN
        state%energy = out%energy(1:8)
      END IF
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE RT_Elem_Kernel_Update

  !============================================================================
  ! Private helpers
  !============================================================================

  SUBROUTINE RT_to_PH_Map(rt_desc, rt_state, rt_algo, rt_ctx, &
                          ph_desc, ph_state, ph_algo, ph_ctx)
    TYPE(RT_Elem_Desc), INTENT(IN) :: rt_desc
    TYPE(RT_Elem_State), INTENT(IN) :: rt_state
    TYPE(RT_Elem_Algo), INTENT(IN) :: rt_algo
    TYPE(RT_Elem_Ctx), INTENT(IN) :: rt_ctx
    TYPE(PH_Elem_Desc), INTENT(OUT) :: ph_desc
    TYPE(PH_Elem_State), INTENT(OUT) :: ph_state
    TYPE(PH_Elem_Algo), INTENT(OUT) :: ph_algo
    TYPE(PH_Elem_Ctx), INTENT(OUT) :: ph_ctx

    ! Direct mapping (RT wraps PH base types)
    ph_desc = rt_desc%base
    ph_state = rt_state%base
    ph_algo = rt_algo%base
    ph_ctx = rt_ctx%base

  END SUBROUTINE RT_to_PH_Map

  SUBROUTINE PH_to_RT_Update(ph_state, rt_state)
    TYPE(PH_Elem_State), INTENT(IN) :: ph_state
    TYPE(RT_Elem_State), INTENT(INOUT) :: rt_state

    ! Update RT state from PH state
    IF (ALLOCATED(ph_state%svars) .AND. ALLOCATED(rt_state%statev)) THEN
      IF (SIZE(ph_state%svars) == SIZE(rt_state%statev)) THEN
        rt_state%statev = ph_state%svars
      END IF
    END IF

    IF (ALLOCATED(ph_state%energy)) THEN
      rt_state%energy(1:MIN(8,SIZE(ph_state%energy))) = &
                  ph_state%energy(1:MIN(8,SIZE(ph_state%energy)))
    END IF

  END SUBROUTINE PH_to_RT_Update

  SUBROUTINE RT_Elem_Kernel_Allocate_Out(out, n_dof, nstatev)
    TYPE(RT_Elem_Kernel_Out), INTENT(OUT) :: out
    INTEGER(i4), INTENT(IN) :: n_dof, nstatev

    IF (ALLOCATED(out%amatrx)) DEALLOCATE(out%amatrx)
    IF (ALLOCATED(out%rhs)) DEALLOCATE(out%rhs)
    IF (ALLOCATED(out%mass)) DEALLOCATE(out%mass)
    IF (ALLOCATED(out%damp)) DEALLOCATE(out%damp)
    IF (ALLOCATED(out%statev)) DEALLOCATE(out%statev)
    IF (ALLOCATED(out%energy)) DEALLOCATE(out%energy)

    ALLOCATE(out%amatrx(n_dof, n_dof))
    ALLOCATE(out%rhs(n_dof, 1))

    ALLOCATE(out%damp(n_dof, n_dof))
    ALLOCATE(out%statev(nstatev))
    ALLOCATE(out%energy(8))

    out%amatrx = 0.0_wp
    out%rhs = 0.0_wp
    out%mass = 0.0_wp
    out%damp = 0.0_wp
    out%statev = 0.0_wp
    out%energy = 0.0_wp
    out%status = 0
    out%pnewdt = 1.0_wp

  END SUBROUTINE RT_Elem_Kernel_Allocate_Out

END MODULE RT_Elem_KernelProc