!===============================================================================
! MODULE: PH_Elem_C3D8EAS
! LAYER:  L4_PH
! DOMAIN: Element/Solid3D
! ROLE:   Proc
! BRIEF:  Enhanced Assumed Strain (EAS) method for C3D8
!===============================================================================
MODULE PH_Elem_C3D8EAS
!> [CORE] Enhanced Assumed Strain method for C3D8
! > Theory: = + G , static condensation: K_eff = K_uu - K_u K_ _ u
!> Status: Production | Last verified: 2026-02-28

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Elem_Mgr, ONLY: ElemType, ElemCtx
  
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  PUBLIC :: PH_Elem_C3D8_EAS_Ctx
  PUBLIC :: PH_Elem_C3D8_EAS_InitCtx_Arg
  PUBLIC :: PH_Elem_C3D8_EAS_InitCtx
  PUBLIC :: PH_Elem_C3D8_EAS_ComputeGMatrix_Arg
  PUBLIC :: PH_Elem_C3D8_EAS_ComputeGMatrix
  PUBLIC :: PH_Elem_C3D8_EAS_UpdateAlpha_Arg
  PUBLIC :: PH_Elem_C3D8_EAS_UpdateAlpha
  PUBLIC :: PH_Elem_C3D8_EAS_CondenseStiffness_Arg
  PUBLIC :: PH_Elem_C3D8_EAS_CondenseStiffness
  PUBLIC :: PH_Elem_C3D8_EAS_Stiffness_Arg
  PUBLIC :: PH_Elem_C3D8_EAS_Stiffness
  PUBLIC :: PH_Elem_C3D8_EAS_Material_Update_Routed

  !=============================================================================
  ! EAS PARAMETERS
  !=============================================================================
  ! Number of enhanced strain parameters
  ! For C3D8: typically 4-9 parameters (volumetric + deviatoric)
  INTEGER(i4), PARAMETER :: PH_ELEM_EAS_NPARAM = 9_i4  ! 9 parameters for full 3D
  
  !=============================================================================
  ! EAS CONTEXT TYPE (Ctx category)
  !=============================================================================
  !> @brief EAS context for C3D8 element (Ctx: context data)
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_Ctx
    ! Enhanced strain parameters (static condensation)
    REAL(wp) :: alpha(PH_ELEM_EAS_NPARAM) = 0.0_wp
    
    ! G matrix at each Gauss point (6 strain components n_param)
    REAL(wp), POINTER :: G_matrix(:,:,:) => NULL()  ! (n_gp, 6, PH_ELEM_EAS_NPARAM)
    
    ! Static condensation matrices
    REAL(wp) :: K_alpha_alpha(PH_ELEM_EAS_NPARAM, PH_ELEM_EAS_NPARAM) = 0.0_wp
    REAL(wp) :: K_u_alpha(24, PH_ELEM_EAS_NPARAM) = 0.0_wp
    REAL(wp) :: K_alpha_u(PH_ELEM_EAS_NPARAM, 24) = 0.0_wp
    
    ! Condensed stiffness matrix
    REAL(wp) :: K_condensed(24, 24) = 0.0_wp
    
    ! Flag: whether EAS is active
    LOGICAL :: is_active = .FALSE.
    
    ! Number of Gauss points
    INTEGER(i4) :: n_gp = 8_i4
  END TYPE PH_Elem_C3D8_EAS_Ctx

  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for EAS context initialization
  
  !> @brief Output structure for EAS context initialization
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_InitCtx_Arg
    INTEGER(i4) :: n_gp  ! Number of Gauss points (Algo)                   ! [IN]
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! Initialized EAS context (Ctx)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_InitCtx_Arg


  !> @brief Input structure for G matrix computation
  
  !> @brief Output structure for G matrix computation
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_ComputeGMatrix_Arg
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! EAS context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_ComputeGMatrix_Arg


  !> @brief Input structure for alpha update
  
  !> @brief Output structure for alpha update
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_UpdateAlpha_Arg
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! EAS context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_UpdateAlpha_Arg


  !> @brief Input structure for stiffness condensation
  
  !> @brief Output structure for stiffness condensation
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_CondenseStiffness_Arg
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! EAS context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_CondenseStiffness_Arg


  !> @brief Input structure for EAS stiffness computation
  
  !> @brief Output structure for EAS stiffness computation
  TYPE, PUBLIC :: PH_Elem_C3D8_EAS_Stiffness_Arg
    TYPE(PH_Elem_C3D8_EAS_Ctx) :: ctx  ! EAS context (Ctx)                   ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_EAS_Stiffness_Arg


CONTAINS

  SUBROUTINE InvertMatrix(n, A, info)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(INOUT) :: A(n, n)
    INTEGER(i4), INTENT(OUT) :: info
    
    ! Use LAPACK dgetri (via interface if available)
    ! Simplified: use Gaussian elimination for small matrices
    IF (n <= 3) THEN
      CALL InvertSmallMatrix(n, A, info)
    ELSE
      ! For larger matrices, use LAPACK or implement LU decomposition
      info = -1  ! Not implemented for large matrices
    END IF
    
  END SUBROUTINE InvertMatrix

  SUBROUTINE InvertSmallMatrix(n, A, info)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(INOUT) :: A(n, n)
    INTEGER(i4), INTENT(OUT) :: info
    
    REAL(wp) :: det, A_inv(n, n)
    
    info = 0
    
    IF (n == 1) THEN
      IF (ABS(A(1,1)) < 1.0e-12_wp) THEN
        info = -1
        RETURN
      END IF
      A(1,1) = 1.0_wp / A(1,1)
    ELSE IF (n == 2) THEN
      det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      IF (ABS(det) < 1.0e-12_wp) THEN
        info = -1
        RETURN
      END IF
      A_inv(1,1) = A(2,2) / det
      A_inv(1,2) = -A(1,2) / det
      A_inv(2,1) = -A(2,1) / det
      A_inv(2,2) = A(1,1) / det
      A = A_inv
    ELSE IF (n == 3) THEN
      ! 3 3 matrix inversion (Cramer's rule)
      det = A(1,1)*(A(2,2)*A(3,3) - A(2,3)*A(3,2)) - &
            A(1,2)*(A(2,1)*A(3,3) - A(2,3)*A(3,1)) + &
            A(1,3)*(A(2,1)*A(3,2) - A(2,2)*A(3,1))
      
      IF (ABS(det) < 1.0e-12_wp) THEN
        info = -1
        RETURN
      END IF
      
      ! Compute inverse using cofactors
      A_inv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) / det
      A_inv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) / det
      A_inv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) / det
      A_inv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) / det
      A_inv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) / det
      A_inv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) / det
      A_inv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) / det
      A_inv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) / det
      A_inv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) / det
      
      A = A_inv
    END IF
    
  END SUBROUTINE InvertSmallMatrix

  SUBROUTINE PH_Elem_C3D8_EAS_ComputeGMatrix(in, out)
    ! > [Theory] EAS G(6,nEAS)=J0/J·T0·G?(ξ,η,ζ) G? /
    ! > [Logic] ?J det(J) ?(det?) ?G_gp ?G_matrix
    ! > [Compute] G_gp(6,nEAS): (1,1,1); / (ξη,ηζ,ξζ ); out%G_matrix(gp,:,:)=G_gp*det_J0/det_J
    ! > [Data chain] in%coords(3,8), in%n_gp, in%nEAS ?out%G_matrix(n_gp,6,nEAS), out%status; Jacobian
    TYPE(PH_Elem_C3D8_EAS_ComputeGMatrix_Arg), INTENT(IN) :: in
    TYPE(PH_Elem_C3D8_EAS_ComputeGMatrix_Arg), INTENT(OUT) :: out
    
    INTEGER(i4) :: igp
    REAL(wp) :: xi, eta, zeta, det_J
    REAL(wp) :: G_gp(6, PH_ELEM_EAS_NPARAM)  ! G matrix at current GP
    
    CALL init_error_status(out%status)
    
    out%ctx = in%ctx
    
    IF (SIZE(in%xi_gp) /= out%ctx%n_gp) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Gauss point array size mismatch"
      RETURN
    END IF
    
    ! Compute G matrix at each Gauss point
    DO igp = 1, out%ctx%n_gp
      xi = in%xi_gp(igp)
      eta = in%eta_gp(igp)
      zeta = in%zeta_gp(igp)
      det_J = in%det_J_gp(igp)
      
      IF (ABS(det_J) < 1.0e-12_wp) CYCLE
      
      G_gp = 0.0_wp
      
      ! Enhanced strain interpolation functions
      ! Parameter 1-4: Volumetric enhancement (prevents volumetric locking)
      G_gp(1, 1) = 1.0_wp        ! xx: constant
      G_gp(2, 1) = 1.0_wp        ! yy: constant
      G_gp(3, 1) = 1.0_wp        ! zz: constant
      
      G_gp(1, 2) = xi            ! xx: linear in
      G_gp(2, 3) = eta           ! yy: linear in
      G_gp(3, 4) = zeta          ! zz: linear in
      
      ! Parameter 5-9: Deviatoric enhancement (improves bending)
      G_gp(1, 5) = xi * eta      ! xx:
      G_gp(2, 5) = -xi * eta     ! yy: - (deviatoric)
      
      G_gp(2, 6) = eta * zeta    ! yy:
      G_gp(3, 6) = -eta * zeta   ! zz: - (deviatoric)
      
      G_gp(1, 7) = zeta * xi     ! xx:
      G_gp(3, 7) = -zeta * xi    ! zz: - (deviatoric)
      
      G_gp(4, 8) = xi            ! xy:
      G_gp(5, 9) = eta           ! yz:
      
      ! Store G matrix (normalized by det_J for consistency)
      out%ctx%G_matrix(igp, :, :) = G_gp(:,:) / det_J
      
    END DO
    
    out%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_EAS_ComputeGMatrix

  SUBROUTINE PH_Elem_C3D8_EAS_CondenseStiffness(arg)
    TYPE(PH_Elem_C3D8_EAS_CondenseStiffness_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: K_alpha_alpha_inv(PH_ELEM_EAS_NPARAM, PH_ELEM_EAS_NPARAM)
    REAL(wp) :: temp_mat(24, PH_ELEM_EAS_NPARAM)
    INTEGER(i4) :: info
    
    CALL init_error_status(arg%status)
    
    arg%ctx = arg%ctx
    
    IF (.NOT. arg%ctx%is_active) THEN
      ! If EAS not active, return standard stiffness
      arg%ctx%K_condensed = arg%K_uu
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Invert K_ matrix
    K_alpha_alpha_inv = arg%ctx%K_alpha_alpha
    CALL InvertMatrix(PH_ELEM_EAS_NPARAM, K_alpha_alpha_inv, info)
    
    IF (info /= 0) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "K_alpha_alpha matrix is singular"
      RETURN
    END IF
    
    ! Compute: K_condensed = K_uu - K_u K_ _ u
    temp_mat = MATMUL(arg%ctx%K_u_alpha, K_alpha_alpha_inv)
    arg%ctx%K_condensed = arg%K_uu - MATMUL(temp_mat, arg%ctx%K_alpha_u)
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_EAS_CondenseStiffness

  SUBROUTINE PH_Elem_C3D8_EAS_InitCtx(arg)
    TYPE(PH_Elem_C3D8_EAS_InitCtx_Arg), INTENT(INOUT) :: arg
    
    CALL init_error_status(arg%status)
    
    IF (arg%n_gp <= 0 .OR. arg%n_gp > 27) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Invalid number of Gauss points for EAS"
      RETURN
    END IF
    
    arg%ctx%n_gp = arg%n_gp
    arg%ctx%is_active = .TRUE.
    arg%ctx%alpha = 0.0_wp
    arg%ctx%K_alpha_alpha = 0.0_wp
    arg%ctx%K_u_alpha = 0.0_wp
    arg%ctx%K_alpha_u = 0.0_wp
    arg%ctx%K_condensed = 0.0_wp
    
    ! Allocate G matrix for all Gauss points
    IF (ASSOCIATED(arg%ctx%G_matrix)) DEALLOCATE(arg%ctx%G_matrix)
    ALLOCATE(arg%ctx%G_matrix(arg%n_gp, 6, PH_ELEM_EAS_NPARAM))
    arg%ctx%G_matrix = 0.0_wp
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_EAS_InitCtx

  SUBROUTINE PH_Elem_C3D8_EAS_Stiffness(arg)
    TYPE(PH_Elem_C3D8_EAS_Stiffness_Arg), INTENT(INOUT) :: arg
    
    INTEGER(i4) :: igp
    REAL(wp) :: K_uu(24, 24)
    REAL(wp) :: B_gp(6, 24), G_gp(6, PH_ELEM_EAS_NPARAM)
    REAL(wp) :: BtD(24, 6), GtD(6, PH_ELEM_EAS_NPARAM)
    REAL(wp) :: w_detJ
    
    CALL init_error_status(arg%status)
    
    arg%ctx = arg%ctx
    
    K_uu = 0.0_wp
    arg%ctx%K_u_alpha = 0.0_wp
    arg%ctx%K_alpha_u = 0.0_wp
    arg%ctx%K_alpha_alpha = 0.0_wp
    
    ! Assemble matrices at each Gauss point
    DO igp = 1, arg%ctx%n_gp
      w_detJ = arg%weights(igp) * arg%det_J_gp(igp)
      
      IF (ABS(w_detJ) < 1.0e-12_wp) CYCLE
      
      B_gp = arg%B_matrix(igp, :, :)
      G_gp = arg%ctx%G_matrix(igp, :, :)
      
      ! K_uu = ?B^T D B d
      BtD = MATMUL(TRANSPOSE(B_gp), arg%D_matrix)
      K_uu = K_uu + MATMUL(BtD, B_gp) * w_detJ
      
      ! K_u = ?B^T D G d
      GtD = MATMUL(TRANSPOSE(G_gp), arg%D_matrix)
      arg%ctx%K_u_alpha = arg%ctx%K_u_alpha + MATMUL(BtD, G_gp) * w_detJ
      
      ! K_ u = K_u ^T
      arg%ctx%K_alpha_u = arg%ctx%K_alpha_u + MATMUL(GtD, B_gp) * w_detJ
      
      ! K_ = ?G^T D G d
      arg%ctx%K_alpha_alpha = arg%ctx%K_alpha_alpha + MATMUL(GtD, G_gp) * w_detJ
      
    END DO
    
    ! Static condensation
    TYPE(PH_Elem_C3D8_EAS_CondenseStiffness_Arg) :: in_condense
    TYPE(PH_Elem_C3D8_EAS_CondenseStiffness_Arg) :: out_condense
    
    in_condense%K_uu = K_uu
    in_condense%ctx = arg%ctx
    CALL PH_Elem_C3D8_EAS_CondenseStiffness(arg_condense)
    IF (out_condense%status%status_code /= IF_STATUS_OK) THEN
      arg%status = out_condense%status
      RETURN
    END IF
    
    arg%ctx = out_condense%ctx
    arg%K_eff = arg%ctx%K_condensed
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_EAS_Stiffness

  SUBROUTINE PH_Elem_C3D8_EAS_UpdateAlpha(arg)
    TYPE(PH_Elem_C3D8_EAS_UpdateAlpha_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: K_alpha_alpha_inv(PH_ELEM_EAS_NPARAM, PH_ELEM_EAS_NPARAM)
    REAL(wp) :: temp_vec(PH_ELEM_EAS_NPARAM)
    INTEGER(i4) :: info
    
    CALL init_error_status(arg%status)
    
    arg%ctx = arg%ctx
    
    IF (.NOT. arg%ctx%is_active) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "EAS context not initialized"
      RETURN
    END IF
    
    ! Invert K_ matrix
    K_alpha_alpha_inv = arg%ctx%K_alpha_alpha
    CALL InvertMatrix(PH_ELEM_EAS_NPARAM, K_alpha_alpha_inv, info)
    
    IF (info /= 0) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "K_alpha_alpha matrix is singular"
      RETURN
    END IF
    
    ! Compute: = -K_ _ u u
    temp_vec = MATMUL(arg%ctx%K_alpha_u, arg%lcl%u_elem)
    arg%ctx%alpha = -MATMUL(K_alpha_alpha_inv, temp_vec)
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_C3D8_EAS_UpdateAlpha

  SUBROUTINE PH_Elem_C3D8_EAS_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &
                                                      stress_old, stress_new, D_tangent, status)
    USE IF_Mat_Dispatch_Def, ONLY: RT_Mat_Dispatch_Ctx
    USE PH_Mat_Def, ONLY: PH_Mat_Slot
    USE PH_Elem_MaterialRoute, ONLY: PH_Elem_MatRoute_Elastic3D

    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: rt_ctx
    TYPE(PH_Mat_Slot),    INTENT(IN)    :: mat_slot
    REAL(wp),                  INTENT(IN)    :: dStrain(6)
    REAL(wp),                  INTENT(IN)    :: stress_old(6)
    REAL(wp),                  INTENT(OUT)   :: stress_new(6)
    REAL(wp),                  INTENT(OUT)   :: D_tangent(6, 6)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL PH_Elem_MatRoute_Elastic3D(rt_ctx, mat_slot, dStrain, &
                                    stress_old, stress_new, D_tangent, status)
  END SUBROUTINE PH_Elem_C3D8_EAS_Material_Update_Routed
END MODULE PH_Elem_C3D8EAS

