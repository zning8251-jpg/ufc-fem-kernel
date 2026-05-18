!===============================================================================
! MODULE: PH_BC_Mgr
! LAYER:  L4_PH
! DOMAIN: LoadBC
! ROLE:   Mgr �?BC algorithm implementations (Penalty/Lagrange/Elimination)
! BRIEF:  Core BC application for dense and sparse matrices; context-based API.
!===============================================================================
!>>> UFC_PH_CONTRACT | LoadBC/CONTRACT.md

MODULE PH_BC_Mgr
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR, &
                        IF_STATUS_WARN, log_warn, log_info
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_Mtx_Sparse, ONLY: NM_CSR_Type
  USE PH_BC_Def, ONLY: PH_BC_Ctrl_Type, PH_BC_System_Type, PH_BC_SystemAug_Type, &
                         PH_BC_BC_PENALTY, PH_BC_BC_LAGRANGE, PH_BC_BC_ELIMINATION

  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! BC Context (merged from PH_BC_Ctx 2026-03-09)
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BC_BC_MASTER_SLAVE = 4_i4

  TYPE, PUBLIC :: PH_BC_Ctx
    INTEGER(i4) :: enforcement_method = PH_BC_BC_PENALTY
    REAL(wp)    :: penalty_factor = 1.0e30_wp
    LOGICAL     :: use_reduced_integration = .FALSE.
    INTEGER(i4) :: n_bcs_applied = 0_i4
    INTEGER(i4) :: n_dofs_constrained = 0_i4
    INTEGER(i4), ALLOCATABLE :: constrained_dofs(:)
    REAL(wp),    ALLOCATABLE :: prescribed_values(:)
  CONTAINS
    PROCEDURE, PUBLIC :: Init => PH_BC_Ctx_Init
    PROCEDURE, PUBLIC :: Clear => PH_BC_Ctx_Clear
    PROCEDURE, PUBLIC :: SetMethod => PH_BC_Ctx_SetMethod
    PROCEDURE, PUBLIC :: GetMethod => PH_BC_Ctx_GetMethod
  END TYPE PH_BC_Ctx


  TYPE, PUBLIC :: PH_BC_Ctx_Init_Arg
    TYPE(PH_BC_Ctx) :: ctx                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_BC_Ctx_Init_Arg



  TYPE, PUBLIC :: PH_BC_Ctx_SetMethod_Arg
    TYPE(PH_BC_Ctx) :: ctx                   ! [INOUT]
    INTEGER(i4) :: method                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_BC_Ctx_SetMethod_Arg


  PUBLIC :: PH_BC_Ctx_Init_Structured
  PUBLIC :: PH_BC_Ctx_SetMethod_Structured
  PUBLIC :: PH_BC_BC_PENALTY

  !---------------------------------------------------------------------------
  ! BC algorithm interface (only for API layer)
  !---------------------------------------------------------------------------
  PUBLIC :: BCM_Apply_Dense
  PUBLIC :: BCM_Apply_Sparse

CONTAINS

  !-----------------------------------------------------------------------------
  ! BC Context (merged from PH_BC_Ctx)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_BC_Ctx_Init(this, method, penalty_factor)
    CLASS(PH_BC_Ctx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: method
    REAL(wp),    INTENT(IN), OPTIONAL :: penalty_factor
    this%enforcement_method = PH_BC_BC_PENALTY
    this%penalty_factor = 1.0e30_wp
    this%n_bcs_applied = 0_i4
    this%n_dofs_constrained = 0_i4
    IF (PRESENT(method)) this%enforcement_method = method
    IF (PRESENT(penalty_factor)) this%penalty_factor = penalty_factor
  END SUBROUTINE PH_BC_Ctx_Init

  SUBROUTINE PH_BC_Ctx_Init_Structured(arg)
    TYPE(PH_BC_Ctx_Init_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    CALL arg%ctx%Init(method=arg%method, penalty_factor=arg%penalty_factor)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_BC_Ctx_Init_Structured

  SUBROUTINE PH_BC_Ctx_Clear(this)
    CLASS(PH_BC_Ctx), INTENT(INOUT) :: this
    IF (ALLOCATED(this%constrained_dofs)) DEALLOCATE(this%constrained_dofs)
    IF (ALLOCATED(this%prescribed_values)) DEALLOCATE(this%prescribed_values)
    this%n_bcs_applied = 0_i4
    this%n_dofs_constrained = 0_i4
  END SUBROUTINE PH_BC_Ctx_Clear

  SUBROUTINE PH_BC_Ctx_SetMethod(this, method, penalty_factor)
    CLASS(PH_BC_Ctx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: method
    REAL(wp), INTENT(IN), OPTIONAL :: penalty_factor
    this%enforcement_method = method
    IF (PRESENT(penalty_factor)) this%penalty_factor = penalty_factor
  END SUBROUTINE PH_BC_Ctx_SetMethod

  SUBROUTINE PH_BC_Ctx_SetMethod_Structured(arg)
    TYPE(PH_BC_Ctx_SetMethod_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%ctx = arg%ctx
    CALL arg%ctx%SetMethod(method=arg%method, penalty_factor=arg%penalty_factor)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_BC_Ctx_SetMethod_Structured

  FUNCTION PH_BC_Ctx_GetMethod(this) RESULT(method)
    CLASS(PH_BC_Ctx), INTENT(IN) :: this
    INTEGER(i4) :: method
    method = this%enforcement_method
  END FUNCTION PH_BC_Ctx_GetMethod

  !-----------------------------------------------------------------------------
  ! BC algorithms
  !-----------------------------------------------------------------------------

  SUBROUTINE BCM_Apply_Dense(ctrl, sys, status)
    TYPE(PH_BC_Ctrl_Type), INTENT(IN) :: ctrl
    TYPE(PH_BC_System_Type), INTENT(INOUT) :: sys
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(ErrorStatusType) :: local_status

    CALL init_error_status(local_status)

    SELECT CASE (ctrl%enforcement%method)
    CASE (PH_BC_BC_PENALTY)
      CALL BCM_Penalty_Dense(ctrl, sys, local_status)
    CASE (PH_BC_BC_LAGRANGE)
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'BCM_Apply_Dense: Lagrange requires augmented system, use BCM_Apply_Lagrange_Dense'
    CASE (PH_BC_BC_ELIMINATION)
      CALL BCM_Elimination_Dense(ctrl, sys, local_status)
    CASE DEFAULT
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'BCM_Apply_Dense: Unknown BC method'
    END SELECT

    IF (PRESENT(status)) status = local_status
  END SUBROUTINE BCM_Apply_Dense

  SUBROUTINE BCM_Apply_Lagrange_Dense(ctrl, sys_aug, status)
    TYPE(PH_BC_Ctrl_Type), INTENT(IN) :: ctrl
    TYPE(PH_BC_SystemAug_Type), INTENT(INOUT) :: sys_aug
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i, dof_id, n, constraint_id

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. ALLOCATED(sys_aug%K_aug) .OR. .NOT. ALLOCATED(sys_aug%R_aug)) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = 'BCM_Apply_Lagrange_Dense: sys_aug%K_aug or sys_aug%R_aug not allocated'
      END IF
      RETURN
    END IF

    n = ctrl%nTotalDOFs
    DO i = 1, ctrl%nActiveBCs
      dof_id = ctrl%bc_cache(i)%dof
      constraint_id = n + i
      IF (dof_id > 0 .AND. dof_id <= n) THEN
        sys_aug%K_aug(constraint_id, dof_id) = 1.0_wp
        sys_aug%K_aug(dof_id, constraint_id) = 1.0_wp
        sys_aug%R_aug(constraint_id) = ctrl%bc_cache(i)%value * ctrl%bc_cache(i)%amp_factor
      END IF
    END DO

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE BCM_Apply_Lagrange_Dense

  SUBROUTINE BCM_Apply_Sparse(K_csr, R, dof_indices, prescribed_values, &
                              method, penalty_param, status)
    TYPE(NM_CSR_Type), INTENT(INOUT) :: K_csr
    REAL(wp), INTENT(INOUT) :: R(:)
    INTEGER(i4), INTENT(IN) :: dof_indices(:)
    REAL(wp), INTENT(IN) :: prescribed_values(:)
    INTEGER(i4), INTENT(IN) :: method
    REAL(wp), INTENT(IN) :: penalty_param
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(ErrorStatusType) :: local_status

    CALL init_error_status(local_status)

    SELECT CASE (method)
    CASE (PH_BC_BC_PENALTY)
      CALL BCM_Penalty_Sparse(K_csr, R, dof_indices, prescribed_values, &
                              penalty_param, local_status)
    CASE (PH_BC_BC_LAGRANGE)
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'BCM_Apply_Sparse: Lagrange requires BuildAugmentedSystem, use BCM_BuildAugmentedSystem_Lagrange'
    CASE (PH_BC_BC_ELIMINATION)
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'BCM_Apply_Sparse: Elimination requires BuildReducedSystem, use BCM_BuildReducedSystem_Elimination'
    CASE DEFAULT
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'BCM_Apply_Sparse: Unknown BC method'
    END SELECT

    IF (PRESENT(status)) status = local_status
  END SUBROUTINE BCM_Apply_Sparse

  SUBROUTINE BCM_Elimination_Dense(ctrl, sys, status)
    TYPE(PH_BC_Ctrl_Type), INTENT(IN) :: ctrl
    TYPE(PH_BC_System_Type), INTENT(INOUT) :: sys
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i, dof_id

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. ALLOCATED(sys%K) .OR. .NOT. ALLOCATED(sys%R)) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = 'BCM_Elimination_Dense: sys%K or sys%R not allocated'
      END IF
      RETURN
    END IF

    DO i = 1, ctrl%nActiveBCs
      dof_id = ctrl%bc_cache(i)%dof
      IF (dof_id > 0 .AND. dof_id <= SIZE(sys%K, 1)) THEN
        sys%K(dof_id, :) = 0.0_wp
        sys%K(:, dof_id) = 0.0_wp
        sys%K(dof_id, dof_id) = 1.0_wp
        sys%R(dof_id) = ctrl%bc_cache(i)%value * ctrl%bc_cache(i)%amp_factor
      END IF
    END DO

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE BCM_Elimination_Dense

  SUBROUTINE BCM_InsertDiagonal_CSR(K_csr, row_index, diag_value, status)
    TYPE(NM_CSR_Type), INTENT(INOUT) :: K_csr
    INTEGER(i4), INTENT(IN) :: row_index
    REAL(wp), INTENT(IN) :: diag_value
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: p_start, p_end, p, insert_pos
    INTEGER(i4) :: new_nnz, row
    INTEGER(i4), ALLOCATABLE :: ja_new(:)
    REAL(wp), ALLOCATABLE :: a_new(:)
    LOGICAL :: found

    CALL init_error_status(local_status)

    ! Check if diagonal already exists
    p_start = K_csr%ia(row_index)
    p_end = K_csr%ia(row_index + 1) - 1

    found = .FALSE.
    DO p = p_start, p_end
      IF (K_csr%ja(p) == row_index) THEN
        K_csr%a(p) = diag_value
        found = .TRUE.
        EXIT
      END IF
    END DO

    IF (found) THEN
      local_status%status_code = IF_STATUS_OK
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF

    ! Insert diagonal entry
    insert_pos = p_end + 1
    DO p = p_start, p_end
      IF (K_csr%ja(p) > row_index) THEN
        insert_pos = p
        EXIT
      END IF
    END DO

    new_nnz = K_csr%nnz + 1
    ALLOCATE(ja_new(new_nnz), a_new(new_nnz))

    IF (insert_pos > 1) THEN
      ja_new(1:insert_pos-1) = K_csr%ja(1:insert_pos-1)
      a_new(1:insert_pos-1) = K_csr%a(1:insert_pos-1)
    END IF

    ja_new(insert_pos) = row_index
    a_new(insert_pos) = diag_value

    IF (insert_pos <= K_csr%nnz) THEN
      ja_new(insert_pos+1:new_nnz) = K_csr%ja(insert_pos:K_csr%nnz)
      a_new(insert_pos+1:new_nnz) = K_csr%a(insert_pos:K_csr%nnz)
    END IF

    DO row = row_index + 1, K_csr%n + 1
      K_csr%ia(row) = K_csr%ia(row) + 1
    END DO

    DEALLOCATE(K_csr%ja, K_csr%a)
    ALLOCATE(K_csr%ja(new_nnz), K_csr%a(new_nnz))
    K_csr%ja = ja_new
    K_csr%a = a_new
    K_csr%nnz = new_nnz

    DEALLOCATE(ja_new, a_new)

    local_status%status_code = IF_STATUS_OK
    IF (PRESENT(status)) status = local_status
  END SUBROUTINE BCM_InsertDiagonal_CSR

  SUBROUTINE BCM_Penalty_Dense(ctrl, sys, status)
    TYPE(PH_BC_Ctrl_Type), INTENT(IN) :: ctrl
    TYPE(PH_BC_System_Type), INTENT(INOUT) :: sys
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i, dof_id
    REAL(wp) :: alpha

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. ALLOCATED(sys%K) .OR. .NOT. ALLOCATED(sys%R)) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = 'BCM_Penalty_Dense: sys%K or sys%R not allocated'
      END IF
      RETURN
    END IF

    alpha = ctrl%enforcement%penalty_param
    DO i = 1, ctrl%nActiveBCs
      dof_id = ctrl%bc_cache(i)%dof
      IF (dof_id > 0 .AND. dof_id <= SIZE(sys%K, 1)) THEN
        sys%K(dof_id, dof_id) = sys%K(dof_id, dof_id) + alpha
        sys%R(dof_id) = sys%R(dof_id) + alpha * ctrl%bc_cache(i)%value * ctrl%bc_cache(i)%amp_factor
      END IF
    END DO

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE BCM_Penalty_Dense

  SUBROUTINE BCM_Penalty_Sparse(K_csr, R, dof_indices, prescribed_values, &
                                 penalty_param, status)
    TYPE(NM_CSR_Type), INTENT(INOUT) :: K_csr
    REAL(wp), INTENT(INOUT) :: R(:)
    INTEGER(i4), INTENT(IN) :: dof_indices(:)
    REAL(wp), INTENT(IN) :: prescribed_values(:)
    REAL(wp), INTENT(IN) :: penalty_param
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: i, dof_id, p_start, p_end, p
    REAL(wp) :: alpha, val
    LOGICAL :: found

    CALL init_error_status(local_status)

    IF (SIZE(dof_indices) /= SIZE(prescribed_values)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'BCM_Penalty_Sparse: Dimension mismatch'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF

    alpha = penalty_param

    DO i = 1, SIZE(dof_indices)
      dof_id = dof_indices(i)
      IF (dof_id < 1 .OR. dof_id > SIZE(R)) CYCLE

      val = prescribed_values(i)

      ! Locate diagonal entry in CSR
      p_start = K_csr%ia(dof_id)
      p_end = K_csr%ia(dof_id + 1) - 1
      found = .FALSE.

      DO p = p_start, p_end
        IF (K_csr%ja(p) == dof_id) THEN
          K_csr%a(p) = K_csr%a(p) + alpha
          R(dof_id) = R(dof_id) + alpha * val
          found = .TRUE.
          EXIT
        END IF
      END DO

      IF (.NOT. found) THEN
        ! Diagonal missing - insert it
        CALL BCM_InsertDiagonal_CSR(K_csr, dof_id, alpha, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
          IF (PRESENT(status)) status = local_status
          RETURN
        END IF
        R(dof_id) = R(dof_id) + alpha * val
      END IF
    END DO

    local_status%status_code = IF_STATUS_OK
    IF (PRESENT(status)) status = local_status
  END SUBROUTINE BCM_Penalty_Sparse
END MODULE PH_BC_Mgr