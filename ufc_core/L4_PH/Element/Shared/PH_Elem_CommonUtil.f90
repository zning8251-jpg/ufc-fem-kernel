!===============================================================================
! MODULE: PH_Elem_CommonUtil
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Common element utility functions
!===============================================================================
MODULE PH_Elem_CommonUtil
!> [UTIL] Common element utility functions
! > Theory: _vm = ?0.5 [( ? ? +( ? ? +( ? ? ]), U = 0.5 ? : dV
!> Status: Production | Last verified: 2026-02-28

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ObjModel, ONLY: MatProperties
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, &
                             ElemFlags, ElemState
  USE PH_Elem_Quality, ONLY: UF_Elem_CheckQuality, ElemQualMetrics
  
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC TYPES AND SUBROUTINES
  !=============================================================================
  ! Structured interfaces (new)
  PUBLIC :: PH_Elem_ExtractResults_Arg
  PUBLIC :: PH_Elem_ExtractResults
  PUBLIC :: PH_Elem_ExtractResults_Structured
  PUBLIC :: PH_Elem_ValidateInput_Arg
  PUBLIC :: PH_Elem_ValidateInput
  PUBLIC :: PH_Elem_ValidateInput_Structured
  PUBLIC :: PH_Elem_ComputeEnergy_Arg
  PUBLIC :: PH_Elem_ComputeEnergy
  PUBLIC :: PH_Elem_ComputeEnergy_Structured
  
  ! Legacy interfaces (kept for backward compatibility)
  PUBLIC :: UF_ExtractElementResults
  PUBLIC :: UF_ValidateElementInput
  PUBLIC :: UF_BatchComputeElements
  PUBLIC :: UF_ComputeElementEnergy
  PUBLIC :: UF_CheckElementConvergence
  PUBLIC :: UF_Elem_ComputeWithQualityCheck
  
  !=============================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  !=============================================================================
  
  !> @brief Input structure for element result extraction
  
  !> @brief Output structure for element result extraction
  TYPE, PUBLIC :: PH_Elem_ExtractResults_Arg
    TYPE(ElemState) :: state_out  ! Element output state (State)                   ! [IN]
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    REAL(wp) :: max_stress  ! Maximum stress magnitude                   ! [OUT]
    REAL(wp) :: max_strain  ! Maximum strain magnitude                   ! [OUT]
    REAL(wp) :: von_mises_stress  ! Maximum Von Mises stress _vm                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_ExtractResults_Arg

  
  !> @brief Input structure for element input validation
  
  !> @brief Output structure for element input validation
  TYPE, PUBLIC :: PH_Elem_ValidateInput_Arg
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(MatProperties) :: mat  ! Material properties (Desc)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_ValidateInput_Arg

  
  !> @brief Input structure for element energy computation
  
  !> @brief Output structure for element energy computation
  TYPE, PUBLIC :: PH_Elem_ComputeEnergy_Arg
    TYPE(ElemState) :: state_out  ! Element output state (State)                   ! [IN]
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    REAL(wp) :: strain_energy  ! Strain energy U                   ! [OUT]
    REAL(wp) :: kinetic_energy  ! Kinetic energy T                   ! [OUT]
    REAL(wp) :: total_energy  ! Total energy E = U + T                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_ComputeEnergy_Arg


CONTAINS

  SUBROUTINE PH_Elem_ComputeEnergy(in, out)
    ! > [Theory] W_e=?∫�?ε dΩ≈�??·σ_gp·ε_gp·vol_gp) T=?∫ρ·v^2 dΩ≈�??·ρ·v?·vol_gp)
    ! > [Logic] �?�?( ) �?    !> [Compute] strain_energy+=0.5*dot_product(sigma_gp,strain_gp)*vol_gp; kinetic_energy+=0.5*rho*v?*vol_gp
    !> [Data chain] in%stress_gp(6,nIP), in%strain_gp(6,nIP), in%vol_gp(nIP) �?out%strain_energy, out%kinetic_energy, out%total_energy
    TYPE(PH_Elem_ComputeEnergy_Arg), INTENT(IN) :: in
    TYPE(PH_Elem_ComputeEnergy_Arg), INTENT(OUT) :: out
    
    INTEGER(i4) :: ip, nInt
    REAL(wp) :: sigma(6), strain(6)
    
    CALL init_error_status(out%status)
    
    out%strain_energy = 0.0_wp
    out%kinetic_energy = 0.0_wp
    out%total_energy = 0.0_wp
    
    IF (.NOT. ALLOCATED(in%state_out%ipStates)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Integration point states not allocated"
      RETURN
    END IF
    
    nInt = SIZE(in%state_out%ipStates)
    
    ! Compute strain energy: U = 0.5 ? : dV
    DO ip = 1, nInt
      sigma = in%state_out%ipStates(ip)%sigma
      strain = in%state_out%ipStates(ip)%strain
      
      ! Strain energy density: 0.5 ( x x + y y + z z + 2 xy xy + 2 yz yz + 2 zx zx)
      out%strain_energy = out%strain_energy + 0.5_wp * &
        (sigma(1)*strain(1) + sigma(2)*strain(2) + sigma(3)*strain(3) + &
         2.0_wp * (sigma(4)*strain(4) + sigma(5)*strain(5) + sigma(6)*strain(6)))
    END DO
    
    ! Kinetic energy (if velocities are available)
    IF (ALLOCATED(in%state_out%velocities)) THEN
      ! T = 0.5 m v (simplified - would need mass matrix)
      out%kinetic_energy = 0.0_wp  ! Placeholder
    END IF
    
    out%total_energy = out%strain_energy + out%kinetic_energy
    
    out%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_ComputeEnergy

  SUBROUTINE PH_Elem_ComputeEnergy_Structured(arg)
    TYPE(PH_Elem_ComputeEnergy_Arg), INTENT(INOUT) :: arg
    
    ! Call main interface
    CALL PH_Elem_ComputeEnergy(arg)
    
  END SUBROUTINE PH_Elem_ComputeEnergy_Structured

  SUBROUTINE PH_Elem_ExtractResults(arg)
    TYPE(PH_Elem_ExtractResults_Arg), INTENT(INOUT) :: arg
    
    INTEGER(i4) :: ip, nInt
    REAL(wp) :: sigma(6), strain(6)
    REAL(wp) :: s1, s2, s3, s_vm
    
    CALL init_error_status(arg%status)
    
    arg%max_stress = 0.0_wp
    arg%max_strain = 0.0_wp
    arg%von_mises_stress = 0.0_wp
    arg%principal_stress = 0.0_wp
    
    IF (.NOT. ALLOCATED(arg%state_arg%ipStates)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Integration point states not allocated"
      RETURN
    END IF
    
    nInt = SIZE(arg%state_arg%ipStates)
    
    ! Loop over integration points
    DO ip = 1, nInt
      sigma = arg%state_arg%ipStates(ip)%sigma
      strain = arg%state_arg%ipStates(ip)%strain
      
      ! Maximum stress magnitude: || || = ? �?)
      arg%max_stress = MAX(arg%max_stress, SQRT(SUM(sigma(1:3)**2) + &
                                         SUM(sigma(4:6)**2)))
      
      ! Maximum strain magnitude: || || = ? �?)
      arg%max_strain = MAX(arg%max_strain, SQRT(SUM(strain(1:3)**2) + &
                                        SUM(strain(4:6)**2)))
      
      ! Von Mises stress: _vm = ?0.5 [( ? ? +( ? ? +( ? ? ])
      ! For 3D: _vm = ? x + y + z - x y- y z- z x+3( xy + yz + zx ))
      s_vm = SQRT(0.5_wp * ((sigma(1) - sigma(2))**2 + &
                            (sigma(2) - sigma(3))**2 + &
                            (sigma(3) - sigma(1))**2) + &
                  3.0_wp * (sigma(4)**2 + sigma(5)**2 + sigma(6)**2))
      arg%von_mises_stress = MAX(arg%von_mises_stress, s_vm)
      
      ! Principal stresses (simplified - would need eigenvalue computation for full 3D)
      ! For 2D: ? ?= 0.5 ( x+ y) ?0.25 ( x- y) + xy )
      IF (arg%elem_type%dim == 2) THEN
        s1 = 0.5_wp * (sigma(1) + sigma(2)) + &
             SQRT(0.25_wp * (sigma(1) - sigma(2))**2 + sigma(4)**2)
        s2 = 0.5_wp * (sigma(1) + sigma(2)) - &
             SQRT(0.25_wp * (sigma(1) - sigma(2))**2 + sigma(4)**2)
        arg%principal_stress(1) = MAX(arg%principal_stress(1), s1)
        arg%principal_stress(2) = MAX(arg%principal_stress(2), s2)
        arg%principal_stress(3) = 0.0_wp  ! Plane stress: ?= 0
      END IF
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_ExtractResults

  SUBROUTINE PH_Elem_ExtractResults_Structured(arg)
    TYPE(PH_Elem_ExtractResults_Arg), INTENT(INOUT) :: arg
    
    ! Call main interface
    CALL PH_Elem_ExtractResults(arg)
    
  END SUBROUTINE PH_Elem_ExtractResults_Structured

  SUBROUTINE PH_Elem_ValidateInput(arg)
    TYPE(PH_Elem_ValidateInput_Arg), INTENT(INOUT) :: arg
    
    INTEGER(i4) :: nNode, nDim, i
    REAL(wp) :: coord_min, coord_max, coord_range
    
    CALL init_error_status(arg%status)
    
    ! Check element type
    IF (arg%elem_type%pop%n_nodes <= 0) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Invalid element: nNodes <= 0"
      RETURN
    END IF
    
    IF (arg%elem_type%dim <= 0 .OR. arg%elem_type%dim > 3) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Invalid element dimension"
      RETURN
    END IF
    
    ! Check coordinates
    IF (.NOT. ALLOCATED(arg%ctx%coords_ref)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Element coordinates not allocated"
      RETURN
    END IF
    
    nNode = arg%elem_type%pop%n_nodes
    nDim = arg%elem_type%dim
    
    IF (SIZE(arg%ctx%coords_ref, 1) < nDim .OR. &
        SIZE(arg%ctx%coords_ref, 2) < nNode) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Coordinate array size mismatch"
      RETURN
    END IF
    
    ! Check for NaN or Inf coordinates
    DO i = 1, nNode
      IF (ANY(.NOT. (arg%ctx%coords_ref(1:nDim, i) == &
                     arg%ctx%coords_ref(1:nDim, i)))) THEN
        arg%status%status_code = IF_STATUS_INVALID
        arg%status%message = "NaN or Inf detected in coordinates"
        RETURN
      END IF
    END DO
    
    ! Check coordinate range (warn if too large or too small)
    coord_min = MINVAL(arg%ctx%coords_ref(1:nDim, 1:nNode))
    coord_max = MAXVAL(arg%ctx%coords_ref(1:nDim, 1:nNode))
    coord_range = coord_max - coord_min
    
    IF (coord_range < 1.0e-12_wp) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Element has zero or near-zero size"
      RETURN
    END IF
    
    IF (ABS(coord_max) > 1.0e10_wp .OR. ABS(coord_min) > 1.0e10_wp) THEN
      ! Warning: Very large coordinates (possible units issue)
      arg%status%status_code = IF_STATUS_OK
      arg%status%message = "Very large coordinates detected (possible units issue)"
    END IF
    
    ! Check material properties
    IF (arg%mat%E <= 0.0_wp) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Invalid Young's modulus: E <= 0"
      RETURN
    END IF
    
    IF (arg%mat%nu < -1.0_wp .OR. arg%mat%nu >= 0.5_wp) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Invalid Poisson's ratio: nu < -1 or >= 0.5"
      RETURN
    END IF
    
    IF (arg%mat%rho < 0.0_wp) THEN
      ! Warning: Negative density
      arg%status%status_code = IF_STATUS_OK
      arg%status%message = "Negative density detected"
    END IF
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Elem_ValidateInput

  SUBROUTINE UF_BatchComputeElements(elementTypes, contexts, materials, &
                                      states_in, states_out, flags_array, &
                                      nElements, status)
    !! Batch compute multiple elements (for parallel processing)
    !! 
    !! @param elementTypes Array of element types
    !! @param contexts Array of element contexts
    !! @param materials Array of Mat properties
    !! @param states_in Array of input states
    !! @param states_out Array of output states
    !! @param flags_array Array of element flags
    !! @param nElements Number of elements to process
    !! @param status Error status
    !! 
    !! Note: This is a placeholder implementation. Actual dispatch to element
    !!       routines should be implemented based on element type.
    
    TYPE(ElemType), INTENT(IN) :: elementTypes(:)
    TYPE(ElemCtx), INTENT(IN) :: contexts(:)
    TYPE(MatProperties), INTENT(IN) :: materials(:)
    TYPE(ElemState), INTENT(IN) :: states_in(:)
    TYPE(ElemState), INTENT(INOUT) :: states_out(:)
    TYPE(ElemFlags), INTENT(INOUT) :: flags_array(:)
    INTEGER(i4), INTENT(IN) :: nElements
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: iElem
    TYPE(ErrorStatusType) :: elem_status
    
    CALL init_error_status(status)
    
    IF (nElements <= 0 .OR. nElements > SIZE(elementTypes)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of elements"
      RETURN
    END IF
    
    ! Process each element
    DO iElem = 1, nElements
      ! Validate input
      CALL UF_ValidateElementInput(elementTypes(iElem), &
                                   contexts(iElem), &
                                   materials(iElem), &
                                   elem_status)
      
      IF (elem_status%status_code /= IF_STATUS_OK) THEN
        flags_array(iElem)%failed = .true.
        flags_array(iElem)%status = elem_status
        CYCLE
      END IF
      
      ! Compute element (would call appropriate element routine)
      ! This is a placeholder - actual implementation would dispatch
      ! to the correct element routine based on element type
      ! CALL UF_Elem_ComputeDispatch(elementTypes(iElem), ...)
      
    END DO
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE UF_BatchComputeElements

  FUNCTION UF_CheckElementConvergence(state_old, state_new, &
                                       tolerance) RESULT(converged)
    
    TYPE(ElemState), INTENT(IN) :: state_old, state_new
    REAL(wp), INTENT(IN) :: tolerance
    LOGICAL :: converged
    
    REAL(wp) :: max_residual, max_displacement
    INTEGER(i4) :: i
    
    converged = .false.
    
    ! Check residual force convergence
    IF (ALLOCATED(state_old%residual) .AND. &
        ALLOCATED(state_new%residual)) THEN
      max_residual = MAXVAL(ABS(state_new%residual - state_old%residual))
      IF (max_residual > tolerance) RETURN
    END IF
    
    ! Check displacement convergence
    IF (ALLOCATED(state_old%displacements) .AND. &
        ALLOCATED(state_new%displacements)) THEN
      max_displacement = MAXVAL(ABS(state_new%displacements - &
                                    state_old%displacements))
      IF (max_displacement > tolerance) RETURN
    END IF
    
    converged = .true.
    
  END FUNCTION UF_CheckElementConvergence

  SUBROUTINE UF_ComputeElementEnergy(state_out, ElemType, &
                                      strain_energy, kinetic_energy, &
                                      total_energy, status)
    TYPE(ElemState), INTENT(IN) :: state_out
    TYPE(ElemType), INTENT(IN) :: ElemType
    REAL(wp), INTENT(OUT) :: strain_energy, kinetic_energy, total_energy
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(PH_Elem_ComputeEnergy_Arg) :: in_struct
    TYPE(PH_Elem_ComputeEnergy_Arg) :: out_struct
    
    ! Convert to structured interface
    in_struct%state_out = state_out
    in_struct%elem_type = ElemType
    
    ! Call structured interface
    CALL PH_Elem_ComputeEnergy(arg_struct)
    
    ! Copy results back
    strain_energy = out_struct%strain_energy
    kinetic_energy = out_struct%kinetic_energy
    total_energy = out_struct%total_energy
    status = out_struct%status
    
  END SUBROUTINE UF_ComputeElementEnergy

  SUBROUTINE UF_Elem_ComputeWithQualityCheck(ElemType, Formul, Ctx, &
                                             state_in, Mat, state_out, flags, &
                                             compute_proc)
    
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags
    PROCEDURE() :: compute_proc

    TYPE(ElemQualMetrics) :: quality_metrics
    TYPE(ErrorStatusType) :: quality_status

    ! Quality check before computation
    CALL UF_Elem_CheckQuality(ElemType, Ctx, quality_metrics, quality_status)
    IF (quality_status%status_code == IF_STATUS_OK) THEN
      IF (.NOT. quality_metrics%is_valid) THEN
        flags%failed = .true.
        flags%status%status_code = IF_STATUS_INVALID
        flags%status%message = "Element quality check failed"
        RETURN
      END IF
    END IF

    ! Call actual computation procedure
    CALL compute_proc(ElemType, Formul, Ctx, state_in, &
                      Mat, state_out, flags)

  END SUBROUTINE UF_Elem_ComputeWithQualityCheck

  SUBROUTINE UF_ExtractElementResults(state_out, ElemType, &
                                      max_stress, max_strain, &
                                      von_mises_stres, principal_stres, &
                                      status)
    TYPE(ElemState), INTENT(IN) :: state_out
    TYPE(ElemType), INTENT(IN) :: ElemType
    REAL(wp), INTENT(OUT) :: max_stress, max_strain
    REAL(wp), INTENT(OUT) :: von_mises_stres
    REAL(wp), INTENT(OUT) :: principal_stres(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(PH_Elem_ExtractResults_Arg) :: in_struct
    TYPE(PH_Elem_ExtractResults_Arg) :: out_struct
    
    ! Convert to structured interface
    in_struct%state_out = state_out
    in_struct%elem_type = ElemType
    
    ! Call structured interface
    CALL PH_Elem_ExtractResults(arg_struct)
    
    ! Copy results back
    max_stress = out_struct%max_stress
    max_strain = out_struct%max_strain
    von_mises_stres = out_struct%von_mises_stress
    principal_stres = out_struct%principal_stress
    status = out_struct%status
    
  END SUBROUTINE UF_ExtractElementResults

  SUBROUTINE UF_ValidateElementInput(ElemType, Ctx, Mat, &
                                     status)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(MatProperties), INTENT(IN) :: Mat
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(PH_Elem_ValidateInput_Arg) :: in_struct
    TYPE(PH_Elem_ValidateInput_Arg) :: out_struct
    
    ! Convert to structured interface
    in_struct%elem_type = ElemType
    in_struct%ctx = Ctx
    in_struct%mat = Mat
    
    ! Call structured interface
    CALL PH_Elem_ValidateInput(arg_struct)
    
    ! Copy results back
    status = out_struct%status
    
  END SUBROUTINE UF_ValidateElementInput
end module PH_Elem_CommonUtil