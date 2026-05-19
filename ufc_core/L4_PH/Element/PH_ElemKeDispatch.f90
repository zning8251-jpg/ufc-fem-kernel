!===============================================================================
! MODULE: PH_ElemKeDispatch
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Dispatch
! BRIEF:  Stiffness matrix computation dispatch (from PH_ElemDomain_Ops).
!         Phase 6A: Supports Procedure-as-Parameter via PH_Elem_Algo%integrator.
!===============================================================================
MODULE PH_ElemKeDispatch
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                         IF_STATUS_INVALID
  USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_State, PH_Elem_Algo, &
                          PH_Elem_Stiff_Arg
  USE MD_Elem_Mgr, ONLY: PH_ELEM_C3D4, PH_ELEM_C3D8
  USE PH_Elem_C3D8, ONLY: PH_Elem_C3D8_FormStiffMatrix
  USE PH_Elem_C3D4, ONLY: PH_Elem_C3D4_FormStiffMatrix

  ! Element type constants (2D families — keep local until wired)
  INTEGER(i4), PARAMETER, PRIVATE :: PH_ELEM_CAX4 = 210
  INTEGER(i4), PARAMETER, PRIVATE :: PH_ELEM_CAX8 = 211
  INTEGER(i4), PARAMETER, PRIVATE :: PH_ELEM_CPE4 = 151
  INTEGER(i4), PARAMETER, PRIVATE :: PH_ELEM_CPE8 = 158
  INTEGER(i4), PARAMETER, PRIVATE :: PH_ELEM_CPS4 = 161
  INTEGER(i4), PARAMETER, PRIVATE :: PH_ELEM_CPS8 = 168
  INTEGER(i4), PARAMETER, PRIVATE :: PH_ELEM_S4   = 400
  INTEGER(i4), PARAMETER, PRIVATE :: PH_ELEM_S8   = 408

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Compute_Ke

CONTAINS

  !----------------------------------------------------------------------------
  ! Compute_Ke - Stiffness matrix computation dispatch
  ! Phase 6A: If algo%integrator is ASSOCIATED, call it directly;
  !           otherwise fall back to original SELECT CASE dispatch.
  !
  ! Input:  elem_type_id, coords, mat_props, algo_params
  ! Output: Ke (stiffness matrix), status
  !----------------------------------------------------------------------------
  SUBROUTINE Compute_Ke(elem_type, coords, mat_props, algo_params, Ke, status, &
                         desc, elem_state, algo)
    INTEGER(i4),  INTENT(IN)  :: elem_type       ! element type ID
    REAL(wp),    INTENT(IN)  :: coords(:,:)     ! [ndim, n_nodes] coordinates
    REAL(wp),    INTENT(IN)  :: mat_props(:)   ! material property array
    REAL(wp),    INTENT(IN)  :: algo_params(:) ! algorithm params (integration etc.)
    REAL(wp),    INTENT(OUT) :: Ke(:,:)         ! [n_dof, n_dof] stiffness matrix
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    !--- Phase 6A: optional procedure-pointer dispatch arguments ---
    TYPE(PH_Elem_Desc),  INTENT(IN),    OPTIONAL :: desc
    TYPE(PH_Elem_State),  INTENT(INOUT), OPTIONAL :: elem_state
    TYPE(PH_Elem_Algo),  INTENT(IN),    OPTIONAL :: algo

    INTEGER(i4) :: n_nodes, ndim, n_dof
    TYPE(PH_Elem_Stiff_Arg) :: stiff_arg
    INTEGER(i4) :: ifc_status

    ! Parameter extraction
    n_nodes = SIZE(coords, 2)
    ndim = SIZE(coords, 1)
    n_dof = n_nodes * ndim  ! simplified: ndim DOF per node

    ! Initialize output
    Ke = 0.0_wp

    !--- Phase 6A: Procedure-as-Parameter fast path ---
    IF (PRESENT(algo) .AND. PRESENT(desc) .AND. PRESENT(elem_state)) THEN
      IF (ASSOCIATED(algo%integrator)) THEN
        ! Pack stiff_arg bundle (note: coords/D_mat via pointer association
        ! would require TARGET attribute on caller side; here we allocate output)
        ALLOCATE(stiff_arg%Ke(n_dof, n_dof))
        ALLOCATE(stiff_arg%R_int(n_dof))
        stiff_arg%Ke    = 0.0_wp
        stiff_arg%R_int = 0.0_wp
        ifc_status = 0_i4

        ! Direct call via procedure pointer
        CALL algo%integrator(desc, elem_state, stiff_arg, ifc_status)

        ! Copy result back
        IF (SIZE(stiff_arg%Ke,1) == SIZE(Ke,1) .AND. &
            SIZE(stiff_arg%Ke,2) == SIZE(Ke,2)) THEN
          Ke = stiff_arg%Ke
        END IF

        IF (ifc_status /= 0_i4) THEN
          CALL init_error_status(status)
          status%status_code = IF_STATUS_INVALID
          status%message = "[Compute_Ke]: integrator ptr returned error"
        ELSE
          CALL init_error_status(status)
          status%status_code = IF_STATUS_OK
        END IF

        IF (ALLOCATED(stiff_arg%Ke))    DEALLOCATE(stiff_arg%Ke)
        IF (ALLOCATED(stiff_arg%R_int)) DEALLOCATE(stiff_arg%R_int)
        RETURN
      END IF
    END IF

    !--- Fallback: original SELECT CASE dispatch ---
    SELECT CASE (elem_type)
      !-------------------------
      ! 3D continuum
      !-------------------------
      CASE (PH_ELEM_C3D4)
        CALL Compute_Ke_C3D4(coords, mat_props, Ke, status)

      CASE (PH_ELEM_C3D8)
        CALL Compute_Ke_C3D8(coords, mat_props, Ke, status)

      !-------------------------
      ! 2D continuum (axisymmetric)
      !-------------------------
      CASE (PH_ELEM_CAX4)
        CALL Compute_Ke_CAX4(coords, mat_props, Ke, status)

      CASE (PH_ELEM_CAX8)
        CALL Compute_Ke_CAX8(coords, mat_props, Ke, status)

      !-------------------------
      ! 2D continuum (plane strain)
      !-------------------------
      CASE (PH_ELEM_CPE4)
        CALL Compute_Ke_CPE4(coords, mat_props, Ke, status)

      CASE (PH_ELEM_CPE8)
        CALL Compute_Ke_CPE8(coords, mat_props, Ke, status)

      !-------------------------
      ! 2D continuum (plane stress)
      !-------------------------
      CASE (PH_ELEM_CPS4)
        CALL Compute_Ke_CPS4(coords, mat_props, Ke, status)

      CASE (PH_ELEM_CPS8)
        CALL Compute_Ke_CPS8(coords, mat_props, Ke, status)

      !-------------------------
      ! SHELL elements
      !-------------------------
      CASE (PH_ELEM_S4)
        CALL Compute_Ke_S4(coords, mat_props, Ke, status)

      CASE (PH_ELEM_S8)
        CALL Compute_Ke_S8(coords, mat_props, Ke, status)

      !-------------------------
      ! Default: not implemented
      !-------------------------
      CASE DEFAULT
        CALL init_error_status(status, IF_STATUS_OK)  ! placeholder
    END SELECT

  END SUBROUTINE Compute_Ke

  !----------------------------------------------------------------------------
  ! Stub subroutines: per-family Ke computation
  ! Full implementations connect to corresponding family Core modules.
  !----------------------------------------------------------------------------
  SUBROUTINE Compute_Ke_C3D4(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: E_young, nu
    REAL(wp) :: coords4(3, 4)
    INTEGER(i4) :: n

    CALL init_error_status(status)
    n = SIZE(coords, 2)
    IF (SIZE(coords, 1) /= 3 .OR. n /= 4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[Compute_Ke_C3D4] expected 4-node 3D coords (3 x 4)'
      RETURN
    END IF
    IF (SIZE(mat_props) < 2) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[Compute_Ke_C3D4] mat_props must include E and nu'
      RETURN
    END IF
    IF (SIZE(Ke, 1) < 12 .OR. SIZE(Ke, 2) < 12) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[Compute_Ke_C3D4] Ke must be at least 12 x 12'
      RETURN
    END IF
    E_young = mat_props(1)
    nu = mat_props(2)
    coords4 = coords(1:3, 1:4)
    Ke(1:12, 1:12) = 0.0_wp
    CALL PH_Elem_C3D4_FormStiffMatrix(coords4, E_young, nu, Ke(1:12, 1:12))
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Compute_Ke_C3D4

  SUBROUTINE Compute_Ke_C3D8(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: E_young, nu
    REAL(wp) :: coords8(3, 8)

    CALL init_error_status(status)
    IF (SIZE(coords, 1) /= 3 .OR. SIZE(coords, 2) /= 8) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[Compute_Ke_C3D8] expected 8-node 3D coords (3 x 8)'
      RETURN
    END IF
    IF (SIZE(mat_props) < 2) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[Compute_Ke_C3D8] mat_props must include E and nu'
      RETURN
    END IF
    IF (SIZE(Ke, 1) < 24 .OR. SIZE(Ke, 2) < 24) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = '[Compute_Ke_C3D8] Ke must be at least 24 x 24'
      RETURN
    END IF
    E_young = mat_props(1)
    nu = mat_props(2)
    coords8 = coords(1:3, 1:8)
    Ke(1:24, 1:24) = 0.0_wp
    CALL PH_Elem_C3D8_FormStiffMatrix(coords8, E_young, nu, Ke(1:24, 1:24))
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Compute_Ke_C3D8

  SUBROUTINE Compute_Ke_CAX4(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    Ke = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE Compute_Ke_CAX4

  SUBROUTINE Compute_Ke_CAX8(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    Ke = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE Compute_Ke_CAX8

  SUBROUTINE Compute_Ke_CPE4(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    Ke = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE Compute_Ke_CPE4

  SUBROUTINE Compute_Ke_CPE8(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    Ke = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE Compute_Ke_CPE8

  SUBROUTINE Compute_Ke_CPS4(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    Ke = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE Compute_Ke_CPS4

  SUBROUTINE Compute_Ke_CPS8(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    Ke = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE Compute_Ke_CPS8

  SUBROUTINE Compute_Ke_S4(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    Ke = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE Compute_Ke_S4

  SUBROUTINE Compute_Ke_S8(coords, mat_props, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: mat_props(:)
    REAL(wp), INTENT(OUT) :: Ke(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    Ke = 0.0_wp
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE Compute_Ke_S8

END MODULE PH_ElemKeDispatch
