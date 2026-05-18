!===============================================================================
! MODULE: PH_Elem_ThermalForceAsm
! LAYER:  L4_PH
! DOMAIN: Element/Thermal
! ROLE:   Proc
! BRIEF:  Thermal force vector assembly
!===============================================================================
MODULE PH_Elem_ThermalForceAsm
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_ThermalForceAsm_Algo
  PUBLIC :: PH_Thermal_Force_Args

  !=============================================================================
  ! TYPE: PH_Thermal_Force_Args
  ! Purpose: INTF-style argument bundle for thermal force assembly
  ! Status: INTF-001 Progressive Refactoring
  !=============================================================================
  TYPE :: PH_Thermal_Force_Args
    !-- Input: Element topology
    INTEGER(i4)           :: n_nodes = 0_i4            ! Number of nodes
    INTEGER(i4)           :: n_dof_per_node = 3_i4     ! DOFs per node (2D/3D)
    INTEGER(i4)           :: n_integ_pts = 0_i4        ! Integration points
    
    !-- Input: Strain-displacement matrix
    REAL(wp), POINTER     :: B(:,:,:) => NULL()        ! [n_dim, n_nodes, n_ip] B-matrix
    
    !-- Input: Thermal stress
    REAL(wp), POINTER     :: thermal_stress(:) => NULL() ! [6] Voigt thermal stress
    
    !-- Input: Integration data
    REAL(wp), POINTER     :: detJ(:) => NULL()         ! [n_ip] Jacobian determinant
    REAL(wp), POINTER     :: weights(:) => NULL()      ! [n_ip] Integration weights
    
    !-- Output: Thermal force vector
    REAL(wp), ALLOCATABLE :: f_thermal(:)              ! [n_dof] assembled force
    
    !-- Metadata
    INTEGER(i4)           :: elem_type = 0_i4          ! Element type code
    LOGICAL               :: consistent = .TRUE._wp    ! Use consistent formulation
    
  END TYPE PH_Thermal_Force_Args

CONTAINS

  !============================================================================
  ! Subroutine: PH_ThermalForceAsm_Algo
  ! Purpose: Assemble thermal force vector using virtual work principle
  ! Contract: 
  !   [IN]  args%B - strain-displacement matrix at IPs
  !   [IN]  args%thermal_stress - thermal stress (Voigt)
  !   [IN]  args%detJ, args%weights - integration data
  !   [OUT] args%f_thermal - equivalent nodal force vector
  !============================================================================
  SUBROUTINE PH_ThermalForceAsm_Algo(args, status)
    TYPE(PH_Thermal_Force_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: ip, i, j, k, stat
    INTEGER(i4) :: n_dim, dof_base
    REAL(wp) :: weight_vol, stress_work(6)
    
    CALL init_error_status(status)
    
    !--------------------------------------------------------------------------
    ! Contract validation
    !--------------------------------------------------------------------------
    IF (args%pop%n_nodes <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalForceAsm_Algo]: n_nodes must be > 0')
      RETURN
    END IF
    
    IF (args%n_dof_per_node <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalForceAsm_Algo]: n_dof_per_node must be > 0')
      RETURN
    END IF
    
    IF (args%n_integ_pts <= 0) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalForceAsm_Algo]: n_integ_pts must be > 0')
      RETURN
    END IF
    
    IF (.NOT. ASSOCIATED(args%B)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalForceAsm_Algo]: B matrix not associated')
      RETURN
    END IF
    
    IF (.NOT. ASSOCIATED(args%thermal_stress)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalForceAsm_Algo]: thermal_stress not associated')
      RETURN
    END IF
    
    IF (SIZE(args%thermal_stress) /= 6) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalForceAsm_Algo]: thermal_stress must be size 6 (Voigt)')
      RETURN
    END IF
    
    ! Optional: validate integration arrays if provided
    IF (ASSOCIATED(args%detJ) .AND. SIZE(args%detJ) < args%n_integ_pts) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalForceAsm_Algo]: detJ size mismatch')
      RETURN
    END IF
    
    IF (ASSOCIATED(args%weights) .AND. SIZE(args%weights) < args%n_integ_pts) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[PH_ThermalForceAsm_Algo]: weights size mismatch')
      RETURN
    END IF
    
    !--------------------------------------------------------------------------
    ! Allocate output array
    !--------------------------------------------------------------------------
    INTEGER(i4) :: n_total_dof
    n_total_dof = args%pop%n_nodes * args%n_dof_per_node
    
    IF (.NOT. ALLOCATED(args%f_thermal)) THEN
      ALLOCATE(args%f_thermal(n_total_dof), stat=stat)
      IF (stat /= 0) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[PH_ThermalForceAsm_Algo]: failed to allocate f_thermal')
        RETURN
      END IF
    ELSE IF (SIZE(args%f_thermal) /= n_total_dof) THEN
      DEALLOCATE(args%f_thermal)
      ALLOCATE(args%f_thermal(n_total_dof), stat=stat)
      IF (stat /= 0) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[PH_ThermalForceAsm_Algo]: failed to reallocate f_thermal')
        RETURN
      END IF
    END IF
    
    ! Initialize force vector to zero
    args%f_thermal = 0.0_wp
    
    !--------------------------------------------------------------------------
    ! Determine spatial dimension from B matrix
    !--------------------------------------------------------------------------
    n_dim = SIZE(args%B, 1)  ! Usually 2 or 3
    
    !--------------------------------------------------------------------------
    ! Numerical integration: F_th = Σ_ip (w_ip · B_ip^T · σ_th · detJ_ip)
    ! Loop over integration points
    !--------------------------------------------------------------------------
    DO ip = 1, args%n_integ_pts
      
      ! Integration weight × volume element
      IF (ASSOCIATED(args%detJ) .AND. ASSOCIATED(args%weights)) THEN
        weight_vol = args%weights(ip) * args%detJ(ip)
      ELSE
        weight_vol = 1.0_wp  ! Fallback for unit cube
      END IF
      
      ! Extract thermal stress at this IP (assuming uniform for now)
      stress_work = args%thermal_stress
      
      ! Loop over nodes in this element
      DO i = 1, args%pop%n_nodes
        
        ! Compute B^T · σ (strain-displacement transpose times stress)
        ! For node i: f_i = B_i^T · σ_th · w · detJ
        ! B has shape [n_dim, n_nodes, n_ip], but we need Voigt mapping
        
        ! Map Voigt stress to force components
        ! For 3D: f_x = B_11·σ_xx + B_12·σ_yy + B_13·σ_zz + B_14·τ_xy + ...
        
        dof_base = (i - 1) * args%n_dof_per_node
        
        ! Extract B matrix row for node i at IP ip
        ! Note: Simplified mapping; full implementation needs proper B matrix layout
        DO k = 1, MIN(args%n_dof_per_node, 3)
          ! Accumulate contribution from each stress component
          ! Using simplified index mapping (full Voigt: 1=xx, 2=yy, 3=zz, 4=xy, 5=yz, 6=xz)
          
          SELECT CASE (k)
          CASE (1)  ! X-direction
            args%f_thermal(dof_base + 1) = args%f_thermal(dof_base + 1) + &
                 (args%B(1,i,ip) * stress_work(1) + &
                  args%B(4,i,ip) * stress_work(4) + &
                  args%B(6,i,ip) * stress_work(6)) * weight_vol
          CASE (2)  ! Y-direction
            args%f_thermal(dof_base + 2) = args%f_thermal(dof_base + 2) + &
                 (args%B(2,i,ip) * stress_work(2) + &
                  args%B(4,i,ip) * stress_work(4) + &
                  args%B(5,i,ip) * stress_work(5)) * weight_vol
          CASE (3)  ! Z-direction
            args%f_thermal(dof_base + 3) = args%f_thermal(dof_base + 3) + &
                 (args%B(3,i,ip) * stress_work(3) + &
                  args%B(5,i,ip) * stress_work(5) + &
                  args%B(6,i,ip) * stress_work(6)) * weight_vol
          END SELECT
        END DO
        
      END DO  ! nodes
      
    END DO  ! integration points
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ThermalForceAsm_Algo

END MODULE PH_Elem_ThermalForceAsm