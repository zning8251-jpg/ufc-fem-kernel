!===============================================================================
! MODULE: PH_BC_Brg
! LAYER:  L4_PH
! DOMAIN: LoadBC
! ROLE:   Brg �?unified public API for BC application
! BRIEF:  Single entry point PH_BC_Apply (generic) for dense/sparse,
!         struct/scalar parameter styles; delegates to PH_BC_Mgr.
!===============================================================================
!>>> UFC_PH_CONTRACT | LoadBC/CONTRACT.md

MODULE PH_BC_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_Mtx_Sparse, ONLY: NM_CSR_Type
  USE PH_BC_Mgr, ONLY: BCM_Apply_Dense, BCM_Apply_Sparse, PH_BC_Ctx
  USE PH_BC_Def, ONLY: PH_BC_System_Type, PH_BC_SystemAug_Type, &
                         PH_BC_Dirichlet_Desc, PH_BC_Neumann_Desc, &
                         PH_BC_Ctrl_Type, PH_BC_Cache_Type, &
                         PH_BC_BC_PENALTY, PH_BC_BC_LAGRANGE, PH_BC_BC_ELIMINATION
  
  IMPLICIT NONE
  PRIVATE
  
  !---------------------------------------------------------------------------
  ! Public unified interface
  !---------------------------------------------------------------------------
  PUBLIC :: PH_BC_Apply
  PUBLIC :: PH_BC_Apply_Neumann_FromDesc
  PUBLIC :: PH_BC_Apply_Penalty_CSR_FromDesc
  
  !---------------------------------------------------------------------------
  ! CSR System Type (for sparse BC)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_CSR_System_Type
    TYPE(NM_CSR_Type), POINTER :: K_csr => NULL()
    REAL(wp), CONTIGUOUS, POINTER :: F(:) => NULL()
  END TYPE PH_BC_CSR_System_Type
  
  !---------------------------------------------------------------------------
  ! Backward compatibility interfaces (DEPRECATED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_BC_Apply_Dirichlet_FromDesc
  PUBLIC :: PH_BC_Enforce_Penalty_FromDesc
  
  !---------------------------------------------------------------------------
  ! Generic interface: PH_BC_Apply
  !---------------------------------------------------------------------------
  INTERFACE PH_BC_Apply
    MODULE PROCEDURE PH_BC_Apply_Dense_Struct
    MODULE PROCEDURE PH_BC_Apply_Dense_Scalar
  END INTERFACE PH_BC_Apply
  
CONTAINS

  SUBROUTINE PH_BC_Apply_Dense_Scalar(K, R, dof_indices, prescribed_values, &
                                       method, penalty_param, status)
    REAL(wp), INTENT(INOUT) :: K(:,:), R(:)
    INTEGER(i4), INTENT(IN) :: dof_indices(:)
    REAL(wp), INTENT(IN) :: prescribed_values(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: method
    REAL(wp), INTENT(IN), OPTIONAL :: penalty_param
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(PH_BC_System_Type) :: system
    TYPE(PH_BC_Dirichlet_Desc) :: desc
    TYPE(PH_BC_Ctx) :: ctx
    INTEGER(i4) :: n, i
    
    n = SIZE(dof_indices)
    
    ! Wrap arrays into structs
    ALLOCATE(system%K(SIZE(K,1), SIZE(K,2)), system%R(SIZE(R)))
    system%K = K
    system%R = R
    
    desc%n_dofs = n
    ALLOCATE(desc%dof_indices(n), desc%prescribed_values(n))
    desc%dof_indices = dof_indices
    desc%prescribed_values = prescribed_values
    
    IF (PRESENT(method)) THEN
      ctx%enforcement_method = method
    ELSE
      ctx%enforcement_method = PH_BC_BC_PENALTY
    END IF
    
    IF (PRESENT(penalty_param)) THEN
      ctx%penalty_factor = penalty_param
    ELSE
      ctx%penalty_factor = 1.0e12_wp
    END IF
    
    ! Call struct version
    CALL PH_BC_Apply_Dense_Struct(system, desc, ctx, status)
    
    ! Copy back
    K = system%K
    R = system%R
    
    DEALLOCATE(system%K, system%R, desc%dof_indices, desc%prescribed_values)
  END SUBROUTINE PH_BC_Apply_Dense_Scalar

  SUBROUTINE PH_BC_Apply_Dense_Struct(system, desc, ctx, status)
    TYPE(PH_BC_System_Type), INTENT(INOUT) :: system
    TYPE(PH_BC_Dirichlet_Desc), INTENT(IN) :: desc
    TYPE(PH_BC_Ctx), INTENT(IN), OPTIONAL :: ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    TYPE(PH_BC_Ctrl_Type) :: ctrl
    INTEGER(i4) :: i, n, method
    REAL(wp) :: penalty_param
    
    CALL init_error_status(local_status)
    
    ! Validation
    IF (desc%n_dofs <= 0) THEN
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    IF (.NOT. ALLOCATED(desc%dof_indices) .OR. .NOT. ALLOCATED(desc%prescribed_values)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Dense_Struct: desc not allocated'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    IF (SIZE(desc%dof_indices) < desc%n_dofs .OR. SIZE(desc%prescribed_values) < desc%n_dofs) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Dense_Struct: desc size mismatch'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    IF (.NOT. ALLOCATED(system%K) .OR. .NOT. ALLOCATED(system%R)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Dense_Struct: system K/R not allocated'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Build ctrl from desc and ctx
    n = desc%n_dofs
    IF (PRESENT(ctx)) THEN
      method = ctx%enforcement_method
      penalty_param = ctx%penalty_factor
    ELSE
      method = PH_BC_BC_PENALTY
      penalty_param = 1.0e12_wp
    END IF
    
    ctrl%enforcement%method = method
    ctrl%enforcement%penalty_param = penalty_param
    ctrl%nActiveBCs = n
    ctrl%nTotalDOFs = SIZE(system%K, 1)
    
    IF (ALLOCATED(ctrl%bc_cache)) DEALLOCATE(ctrl%bc_cache)
    ALLOCATE(ctrl%bc_cache(n))
    DO i = 1, n
      ctrl%bc_cache(i)%dof = desc%dof_indices(i)
      ctrl%bc_cache(i)%value = desc%prescribed_values(i)
      ctrl%bc_cache(i)%amp_factor = 1.0_wp
    END DO
    
    ! Dispatch to Methods layer
    SELECT CASE (method)
    CASE (PH_BC_BC_PENALTY)
      CALL BCM_Apply_Dense(ctrl, system, local_status)
    CASE (PH_BC_BC_ELIMINATION)
      CALL BCM_Apply_Dense(ctrl, system, local_status)
    CASE (PH_BC_BC_LAGRANGE)
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Dense_Struct: Lagrange requires SystemAug, use PH_BC_Apply_Lagrange'
    CASE DEFAULT
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Dense_Struct: Unknown method'
    END SELECT
    
    IF (PRESENT(status)) status = local_status
  END SUBROUTINE PH_BC_Apply_Dense_Struct

  SUBROUTINE PH_BC_Apply_Dirichlet_FromDesc(system, desc, bc_ctx, status)
    TYPE(PH_BC_System_Type), INTENT(INOUT) :: system
    TYPE(PH_BC_Dirichlet_Desc), INTENT(IN) :: desc
    TYPE(PH_BC_Ctx), INTENT(IN) :: bc_ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    ! Forward to unified API
    CALL PH_BC_Apply_Dense_Struct(system, desc, bc_ctx, status)
  END SUBROUTINE PH_BC_Apply_Dirichlet_FromDesc

  SUBROUTINE PH_BC_Apply_Neumann_FromDesc(system, desc, status)
    TYPE(PH_BC_System_Type), INTENT(INOUT) :: system
    TYPE(PH_BC_Neumann_Desc), INTENT(IN) :: desc
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: i, n_bc, n_dof
    
    CALL init_error_status(local_status)
    
    IF (desc%n_dofs <= 0) THEN
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    IF (.NOT. ALLOCATED(system%R)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Neumann_FromDesc: system%R not allocated'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    IF (.NOT. ALLOCATED(desc%dof_indices) .OR. .NOT. ALLOCATED(desc%values)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Neumann_FromDesc: desc not allocated'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    IF (SIZE(desc%dof_indices) < desc%n_dofs .OR. SIZE(desc%values) < desc%n_dofs) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Neumann_FromDesc: desc size mismatch'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    n_bc = desc%n_dofs
    n_dof = SIZE(system%R)
    
    DO i = 1, n_bc
      IF (desc%dof_indices(i) < 1 .OR. desc%dof_indices(i) > n_dof) THEN
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = 'PH_BC_Apply_Neumann_FromDesc: Invalid DOF index'
        IF (PRESENT(status)) status = local_status
        RETURN
      END IF
      system%R(desc%dof_indices(i)) = system%R(desc%dof_indices(i)) + desc%values(i)
    END DO
    
    local_status%status_code = IF_STATUS_OK
    IF (PRESENT(status)) status = local_status
  END SUBROUTINE PH_BC_Apply_Neumann_FromDesc

  SUBROUTINE PH_BC_Apply_Penalty_CSR_FromDesc(system_csr, desc, bc_ctx, status)
    TYPE(PH_BC_CSR_System_Type), INTENT(INOUT) :: system_csr
    TYPE(PH_BC_Dirichlet_Desc), INTENT(IN) :: desc
    TYPE(PH_BC_Ctx), INTENT(INOUT) :: bc_ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    
    CALL init_error_status(local_status)
    
    IF (desc%n_dofs <= 0) THEN
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    IF (.NOT. ASSOCIATED(system_csr%K_csr) .OR. .NOT. ASSOCIATED(system_csr%F)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Penalty_CSR_FromDesc: system_csr not associated'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    IF (.NOT. ALLOCATED(desc%dof_indices) .OR. .NOT. ALLOCATED(desc%prescribed_values)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Penalty_CSR_FromDesc: desc not allocated'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    IF (SIZE(desc%dof_indices) < desc%n_dofs .OR. SIZE(desc%prescribed_values) < desc%n_dofs) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'PH_BC_Apply_Penalty_CSR_FromDesc: desc size mismatch'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    CALL BCM_Apply_Sparse(system_csr%K_csr, system_csr%F, &
        desc%dof_indices(1:desc%n_dofs), desc%prescribed_values(1:desc%n_dofs), &
        bc_ctx%enforcement_method, bc_ctx%penalty_factor, local_status)
    
    IF (PRESENT(status)) status = local_status
  END SUBROUTINE PH_BC_Apply_Penalty_CSR_FromDesc

  SUBROUTINE PH_BC_Enforce_Penalty_FromDesc(system, desc, bc_ctx, status)
    TYPE(PH_BC_System_Type), INTENT(INOUT) :: system
    TYPE(PH_BC_Dirichlet_Desc), INTENT(IN) :: desc
    TYPE(PH_BC_Ctx), INTENT(IN) :: bc_ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    ! Forward to unified API (same as Apply_Dirichlet for Penalty method)
    CALL PH_BC_Apply_Dense_Struct(system, desc, bc_ctx, status)
  END SUBROUTINE PH_BC_Enforce_Penalty_FromDesc
END MODULE PH_BC_Brg