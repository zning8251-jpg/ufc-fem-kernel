!===============================================================================
! MODULE: PH_Elem_Eval
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Eval
! BRIEF:  Unified hot-path dispatch for element Ke/Fe/Me evaluations.
!         [SIO Phase 3C] Signatures use Arg TYPEs from PH_Elem_Def.
!===============================================================================
MODULE PH_Elem_Eval
  USE IF_Prec_Core,          ONLY: wp, i4
  USE IF_Err_Brg,            ONLY: ErrorStatusType, init_error_status, &
                                   IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Elem_Def,           ONLY: PH_Elem_Desc, PH_Elem_Algo, PH_Elem_Ctx, &
                                   PH_Elem_Eval_Ke_Arg, PH_Elem_Eval_Fe_Arg, &
                                   PH_Elem_Eval_Mass_Arg
  USE PH_ElemKeDispatch,     ONLY: Compute_Ke
  USE PH_ElemFeDispatch,     ONLY: Compute_Fe
  USE PH_Elem_MassDispatch,  ONLY: Compute_Me

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Elem_Eval_Ke
  PUBLIC :: PH_Elem_Eval_Fe
  PUBLIC :: PH_Elem_Eval_Mass

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Eval_Ke
  ! PHASE:      P2
  ! PURPOSE:    Unified stiffness matrix evaluation entry point.
  ! SIO:        (desc, algo, arg, status) — arg = PH_Elem_Eval_Ke_Arg
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Eval_Ke(desc, algo, arg, status)
    TYPE(PH_Elem_Desc),        INTENT(IN)    :: desc    ! [IN] element metadata
    TYPE(PH_Elem_Algo),        INTENT(IN)    :: algo    ! [IN] algorithm config
    TYPE(PH_Elem_Eval_Ke_Arg), INTENT(INOUT) :: arg     ! [INOUT] Ke arg bundle
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status  ! [OUT] error status

    ! Local: algo parameter pack forwarded to Dispatch
    REAL(wp) :: algo_params(4)

    CALL init_error_status(status)

    !-- Guard: basic input validation
    IF (desc%pop%n_dof <= 0_i4 .OR. desc%pop%n_nodes <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Ke] Invalid desc: n_dof or n_nodes <= 0"
      RETURN
    END IF

    IF (SIZE(arg%coords, 1) /= desc%cfg%ndim .OR. SIZE(arg%coords, 2) /= desc%pop%n_nodes) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Ke] coords shape mismatch with desc"
      RETURN
    END IF

    ! Allocate output if needed
    IF (.NOT. ALLOCATED(arg%Ke)) ALLOCATE(arg%Ke(desc%pop%n_dof, desc%pop%n_dof))

    IF (SIZE(arg%Ke, 1) /= desc%pop%n_dof .OR. SIZE(arg%Ke, 2) /= desc%pop%n_dof) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Ke] Ke shape mismatch with n_dof"
      RETURN
    END IF

    !-- Assemble algo parameter pack from Algo TYPE
    algo_params(1) = REAL(algo%stp%integration_order, wp)
    algo_params(2) = REAL(algo%stp%hourglass_control, wp)
    algo_params(3) = algo%stp%hourglass_coeff
    IF (algo%stp%nlgeom) THEN
      algo_params(4) = 1.0_wp
    ELSE
      algo_params(4) = 0.0_wp
    END IF

    !-- Delegate to existing dispatch
    CALL Compute_Ke(desc%cfg%elem_type_id, arg%coords, arg%mat_props, algo_params, arg%Ke, status)

  END SUBROUTINE PH_Elem_Eval_Ke

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Eval_Fe
  ! PHASE:      P2
  ! PURPOSE:    Unified internal force vector evaluation entry point.
  ! SIO:        (desc, algo, arg, status) — arg = PH_Elem_Eval_Fe_Arg
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Eval_Fe(desc, algo, arg, status)
    TYPE(PH_Elem_Desc),        INTENT(IN)    :: desc    ! [IN] element metadata
    TYPE(PH_Elem_Algo),        INTENT(IN)    :: algo    ! [IN] algorithm config
    TYPE(PH_Elem_Eval_Fe_Arg), INTENT(INOUT) :: arg     ! [INOUT] Fe arg bundle
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status  ! [OUT] error status

    CALL init_error_status(status)

    !-- Guard: basic input validation
    IF (desc%pop%n_dof <= 0_i4 .OR. desc%pop%n_nodes <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Fe] Invalid desc: n_dof or n_nodes <= 0"
      RETURN
    END IF

    IF (SIZE(arg%coords, 1) /= desc%cfg%ndim .OR. SIZE(arg%coords, 2) /= desc%pop%n_nodes) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Fe] coords shape mismatch with desc"
      RETURN
    END IF

    ! Allocate output if needed
    IF (.NOT. ALLOCATED(arg%Fe)) ALLOCATE(arg%Fe(desc%pop%n_dof))

    IF (SIZE(arg%Fe) /= desc%pop%n_dof) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Fe] Fe size mismatch with n_dof"
      RETURN
    END IF

    IF (SIZE(arg%u) /= desc%pop%n_dof) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Fe] u size mismatch with n_dof"
      RETURN
    END IF

    !-- Delegate to existing dispatch (arg%load_magn: element-only magnitudes; must not
    !   duplicate loads already assembled into global F_ext by L5 RT_Asm_GlobalLoad)
    CALL Compute_Fe(desc%cfg%elem_type_id, arg%coords, arg%u, arg%load_case, &
                    arg%load_magn, arg%Fe, status)

  END SUBROUTINE PH_Elem_Eval_Fe

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Eval_Mass
  ! PHASE:      P2
  ! PURPOSE:    Unified mass matrix evaluation entry point.
  ! SIO:        (desc, algo, arg, status) — arg = PH_Elem_Eval_Mass_Arg
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Eval_Mass(desc, algo, arg, status)
    TYPE(PH_Elem_Desc),          INTENT(IN)    :: desc    ! [IN] element metadata
    TYPE(PH_Elem_Algo),          INTENT(IN)    :: algo    ! [IN] algorithm config
    TYPE(PH_Elem_Eval_Mass_Arg), INTENT(INOUT) :: arg     ! [INOUT] Mass arg bundle
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status  ! [OUT] error status

    CALL init_error_status(status)

    !-- Guard: basic input validation
    IF (desc%pop%n_dof <= 0_i4 .OR. desc%pop%n_nodes <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Mass] Invalid desc: n_dof or n_nodes <= 0"
      RETURN
    END IF

    IF (SIZE(arg%coords, 1) /= desc%cfg%ndim .OR. SIZE(arg%coords, 2) /= desc%pop%n_nodes) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Mass] coords shape mismatch with desc"
      RETURN
    END IF

    ! Allocate output if needed
    IF (.NOT. ALLOCATED(arg%Me)) ALLOCATE(arg%Me(desc%pop%n_dof, desc%pop%n_dof))

    IF (SIZE(arg%Me, 1) /= desc%pop%n_dof .OR. SIZE(arg%Me, 2) /= desc%pop%n_dof) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Mass] Me shape mismatch with n_dof"
      RETURN
    END IF

    IF (arg%density <= 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Eval_Mass] density must be > 0"
      RETURN
    END IF

    !-- Delegate to existing dispatch
    !   algo%mass_type: 1=consistent, 2=lumped (mapped from Algo TYPE)
    CALL Compute_Me(desc%cfg%elem_type_id, arg%coords, arg%density, algo%dyn%mass_type, arg%Me, status)

  END SUBROUTINE PH_Elem_Eval_Mass

END MODULE PH_Elem_Eval
