!===============================================================================
! MODULE: PH_Elem_AcousticSuite
! LAYER:  L4_PH
! DOMAIN: Element/Acoustic
! ROLE:   Proc
! BRIEF:  P6 Series Enhancement Suite for Acoustic Elements
!===============================================================================
MODULE PH_Elem_AcousticSuite
  USE IF_Prec_Core, ONLY: wp, i4
  USE UFC_Base_Types
  USE UFC_Error_Handler
  USE MD_Mat_AcousticProps, ONLY: MD_Mat_Acoustic_Desc
  IMPLICIT NONE
  
  PRIVATE
  
  !-- P6-1: Diagnostic and Verification
  PUBLIC :: PH_Acoustic_Diagnose
  PUBLIC :: PH_Acoustic_Verify_Matrices
  PUBLIC :: PH_Acoustic_Check_Consistency
  
  !-- P6-2: Unified Interface Enhancements
  PUBLIC :: PH_Acoustic_Init_Unified_Ctx
  PUBLIC :: PH_Acoustic_Select_Analysis_Type
  PUBLIC :: PH_Acoustic_Compute_Eigenvalues
  PUBLIC :: PH_Acoustic_Estimate_CFL
  PUBLIC :: PH_Acoustic_Time_To_Frequency
  PUBLIC :: PH_Acoustic_Frequency_To_Time
  
  !-- P6-3: Material Integration
  PUBLIC :: PH_Acoustic_Map_Material_To_Context
  PUBLIC :: PH_Acoustic_Biot_Wave_Speeds
  PUBLIC :: PH_Acoustic_Compute_Impedance
  PUBLIC :: PH_Acoustic_Temperature_Dependent_c
  
CONTAINS

  !============================================================================
  ! P6-1: DIAGNOSTIC AND VERIFICATION TOOLS
  !============================================================================
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Diagnose
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Diagnose(ctx, Mass, Damping, Stiffness, &
       diagnostics, status)
    !! Perform comprehensive diagnostic check on acoustic system
    TYPE(PH_Acoustic_Unified_Analysis_Ctx), INTENT(IN) :: ctx
    REAL(wp), INTENT(IN) :: Mass(:,:)
    REAL(wp), INTENT(IN) :: Damping(:,:)
    REAL(wp), INTENT(IN) :: Stiffness(:,:)
    REAL(wp), INTENT(OUT) :: diagnostics(:)  ! [10] diagnostics array
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n
    REAL(wp) :: max_eig, min_eig, cond_num
    REAL(wp) :: trace_M, trace_K
    LOGICAL :: is_sym_M, is_sym_K, is_pos_def_M, is_pos_def_K
    
    n = SIZE(Mass, 1)
    diagnostics = 0.0_wp
    
    IF (SIZE(diagnostics) < 10) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           'diagnostics array too small')
      RETURN
    END IF
    
    ! Diagnostic 1: Matrix symmetry
    is_sym_M = check_symmetry(Mass)
    is_sym_K = check_symmetry(Stiffness)
    diagnostics(1) = MERGE(1.0_wp, 0.0_wp, is_sym_M .AND. is_sym_K)
    
    ! Diagnostic 2: Positive definiteness (using trace)
    trace_M = TRACE(Mass)
    trace_K = TRACE(Stiffness)
    is_pos_def_M = (trace_M > 0.0_wp)
    is_pos_def_K = (trace_K > 0.0_wp)
    diagnostics(2) = MERGE(1.0_wp, 0.0_wp, is_pos_def_M .AND. is_pos_def_K)
    
    ! Diagnostic 3-4: Trace values
    diagnostics(3) = trace_M
    diagnostics(4) = trace_K
    
    ! Diagnostic 5: Condition number estimate (K/M ratio)
    max_eig = power_iteration_max(Stiffness, Mass)
    min_eig = power_iteration_min(Stiffness, Mass)
    IF (min_eig > 0.0_wp) THEN
      cond_num = max_eig / min_eig
    ELSE
      cond_num = 1.0e10_wp
    END IF
    diagnostics(5) = MIN(cond_num, 1.0e10_wp)
    
    ! Diagnostic 6: Frequency range estimate
    IF (trace_M > 0.0_wp .AND. trace_K > 0.0_wp) THEN
      diagnostics(6) = SQRT(trace_K / trace_M)  ! Characteristic frequency
    END IF
    
    ! Diagnostic 7-10: Reserved
    diagnostics(7:10) = 0.0_wp
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  CONTAINS
    
    FUNCTION check_symmetry(A) RESULT(is_sym)
      REAL(wp), INTENT(IN) :: A(:,:)
      LOGICAL :: is_sym
      INTEGER(i4) :: i, j, n
      REAL(wp) :: tol
      tol = 1.0e-10_wp
      n = SIZE(A, 1)
      is_sym = .TRUE.
      DO i = 1, n
        DO j = i+1, n
          IF (ABS(A(i,j) - A(j,i)) > tol) THEN
            is_sym = .FALSE.
            RETURN
          END IF
        END DO
      END DO
    END FUNCTION check_symmetry
    
    FUNCTION TRACE(A) RESULT(tr)
      REAL(wp), INTENT(IN) :: A(:,:)
      REAL(wp) :: tr
      INTEGER(i4) :: i, n
      n = MIN(SIZE(A,1), SIZE(A,2))
      tr = 0.0_wp
      DO i = 1, n
        tr = tr + A(i,i)
      END DO
    END FUNCTION TRACE
    
    FUNCTION power_iteration_max(K, M) RESULT(lambda_max)
      REAL(wp), INTENT(IN) :: K(:,:), M(:,:)
      REAL(wp) :: lambda_max
      INTEGER(i4) :: i, n, max_iter
      REAL(wp), ALLOCATABLE :: v(:), v_new(:)
      REAL(wp) :: beta, beta_old
      n = SIZE(K, 1)
      max_iter = 50
      ALLOCATE(v(n), v_new(n))
      v = 1.0_wp / SQRT(REAL(n, wp))
      beta = 0.0_wp
      DO i = 1, max_iter
        v_new = MATMUL(K, v) - beta * MATMUL(M, v)
        beta_old = beta
        beta = SQRT(DOT_PRODUCT(v_new, v_new))
        IF (beta < 1.0e-12_wp) EXIT
        v = v_new / beta
      END DO
      lambda_max = beta
      DEALLOCATE(v, v_new)
    END FUNCTION power_iteration_max
    
    FUNCTION power_iteration_min(K, M) RESULT(lambda_min)
      REAL(wp), INTENT(IN) :: K(:,:), M(:,:)
      REAL(wp) :: lambda_min
      ! Shifted inverse iteration for minimum eigenvalue
      lambda_min = 0.0_wp  ! Placeholder
    END FUNCTION power_iteration_min
    
  END SUBROUTINE PH_Acoustic_Diagnose
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Verify_Matrices
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Verify_Matrices(Mass, Damping, Stiffness, &
       n_dof, verified, status)
    !! Verify acoustic system matrices pass basic sanity checks
    REAL(wp), INTENT(IN) :: Mass(:,:)
    REAL(wp), INTENT(IN) :: Damping(:,:)
    REAL(wp), INTENT(IN) :: Stiffness(:,:)
    INTEGER(i4), INTENT(IN) :: n_dof
    LOGICAL, INTENT(OUT) :: verified
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: tol
    tol = 1.0e-10_wp
    
    verified = .TRUE.
    
    ! Check dimensions
    IF (SIZE(Mass,1) /= n_dof .OR. SIZE(Stiffness,1) /= n_dof) THEN
      verified = .FALSE.
      CALL init_error_status(status, STATUS_ERROR, &
           'Matrix dimension mismatch')
      RETURN
    END IF
    
    ! Check symmetry
    IF (.NOT. is_symmetric(Mass, tol)) verified = .FALSE.
    IF (.NOT. is_symmetric(Damping, tol)) verified = .FALSE.
    IF (.NOT. is_symmetric(Stiffness, tol)) verified = .FALSE.
    
    ! Check positive diagonal
    IF (.NOT. all_positive_diag(Mass)) verified = .FALSE.
    IF (.NOT. all_positive_diag(Stiffness)) verified = .FALSE.
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  CONTAINS
    
    FUNCTION is_symmetric(A, tol) RESULT(res)
      REAL(wp), INTENT(IN) :: A(:,:)
      REAL(wp), INTENT(IN) :: tol
      LOGICAL :: res
      INTEGER(i4) :: i, j, n
      n = SIZE(A, 1)
      res = .TRUE.
      DO i = 1, n
        DO j = i+1, n
          IF (ABS(A(i,j) - A(j,i)) > tol) THEN
            res = .FALSE.
            RETURN
          END IF
        END DO
      END DO
    END FUNCTION is_symmetric
    
    FUNCTION all_positive_diag(A) RESULT(res)
      REAL(wp), INTENT(IN) :: A(:,:)
      LOGICAL :: res
      INTEGER(i4) :: i, n
      n = SIZE(A, 1)
      res = .TRUE.
      DO i = 1, n
        IF (A(i,i) <= 0.0_wp) THEN
          res = .FALSE.
          RETURN
        END IF
      END DO
    END FUNCTION all_positive_diag
    
  END SUBROUTINE PH_Acoustic_Verify_Matrices
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Check_Consistency
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Check_Consistency(ctx, material, status)
    !! Check consistency between analysis context and material model
    TYPE(PH_Acoustic_Unified_Analysis_Ctx), INTENT(IN) :: ctx
    TYPE(MD_Mat_Acoustic_Desc), INTENT(IN) :: material
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    LOGICAL :: issues(5)
    CHARACTER(len=200) :: msg
    
    issues = .FALSE.
    
    ! Check 1: Sound speed consistency
    IF (ABS(ctx%sound_speed - SQRT(ctx%bulk_modulus/ctx%density)) > 1.0_wp) THEN
      issues(1) = .TRUE.
    END IF
    
    ! Check 2: Material temperature dependence enabled
    IF (ctx%use_thermo_coupling .AND. .NOT. material%use_temp_dependence) THEN
      issues(2) = .TRUE.
    END IF
    
    ! Check 3: Material porous media enabled
    IF (ctx%use_porous_media .AND. .NOT. material%is_porous_media) THEN
      issues(3) = .TRUE.
    END IF
    
    ! Check 4: Valid physical parameters
    IF (ctx%density <= 0.0_wp .OR. ctx%bulk_modulus <= 0.0_wp) THEN
      issues(4) = .TRUE.
    END IF
    
    ! Check 5: Time step stability
    IF (.NOT. ctx%is_frequency_domain) THEN
      IF (ctx%dt <= 0.0_wp) issues(5) = .TRUE.
    END IF
    
    IF (ANY(issues)) THEN
      WRITE(msg, '(A,5L1)') 'Consistency issues detected: ', issues
      CALL init_error_status(status, STATUS_WARNING, TRIM(msg))
    ELSE
      CALL init_error_status(status, IF_STATUS_OK, 'All checks passed')
    END IF
    
  END SUBROUTINE PH_Acoustic_Check_Consistency

  !============================================================================
  ! P6-2: UNIFIED INTERFACE ENHANCEMENTS
  !============================================================================
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Init_Unified_Ctx
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Init_Unified_Ctx(ctx, density, bulk_modulus, &
       analysis_type, status)
    !! Initialize unified analysis context with acoustic properties
    TYPE(PH_Acoustic_Unified_Analysis_Ctx), INTENT(OUT) :: ctx
    REAL(wp), INTENT(IN) :: density
    REAL(wp), INTENT(IN) :: bulk_modulus
    CHARACTER(*), INTENT(IN) :: analysis_type  ! 'TIME' or 'FREQUENCY'
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Validate inputs
    IF (density <= 0.0_wp) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           'Density must be positive')
      RETURN
    END IF
    
    IF (bulk_modulus <= 0.0_wp) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           'Bulk modulus must be positive')
      RETURN
    END IF
    
    ! Set basic properties
    ctx%density = density
    ctx%bulk_modulus = bulk_modulus
    ctx%sound_speed = SQRT(bulk_modulus / density)
    
    ! Set analysis type
    SELECT CASE (TRIM(analysis_type))
    CASE ('TIME', 'time', 'Time')
      ctx%is_frequency_domain = .FALSE.
    CASE ('FREQUENCY', 'frequency', 'Frequency')
      ctx%is_frequency_domain = .TRUE.
    CASE DEFAULT
      CALL init_error_status(status, STATUS_ERROR, &
           'Invalid analysis type')
      RETURN
    END SELECT
    
    ! Initialize defaults
    ctx%use_thermo_coupling = .FALSE.
    ctx%use_porous_media = .FALSE.
    ctx%dt = 0.0_wp
    ctx%omega = 0.0_wp
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  END SUBROUTINE PH_Acoustic_Init_Unified_Ctx
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Select_Analysis_Type
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Select_Analysis_Type(ctx, analysis_type, &
       status)
    !! Select analysis type and configure solver parameters
    TYPE(PH_Acoustic_Unified_Analysis_Ctx), INTENT(INOUT) :: ctx
    CHARACTER(*), INTENT(IN) :: analysis_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    SELECT CASE (TRIM(analysis_type))
    CASE ('TIME', 'time', 'Time', 'TRANSIENT', 'transient')
      ctx%is_frequency_domain = .FALSE.
      ! Default Newmark-Beta parameters
      ctx%gamma = 0.5_wp
      ctx%beta = 0.25_wp
      ctx%use_hht = .FALSE.
      
    CASE ('FREQUENCY', 'frequency', 'Frequency', 'HARMONIC', 'harmonic')
      ctx%is_frequency_domain = .TRUE.
      ! Default frequency parameters
      ctx%frequency = 1000.0_wp  ! 1 kHz default
      ctx%omega = 2.0_wp * 3.14159265358979_wp * ctx%frequency
      
    CASE DEFAULT
      CALL init_error_status(status, STATUS_ERROR, &
           'Invalid analysis type')
      RETURN
    END SELECT
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  END SUBROUTINE PH_Acoustic_Select_Analysis_Type
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Compute_Eigenvalues
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Compute_Eigenvalues(Mass, Stiffness, &
       eigenvalues, n_eigen, status)
    !! Compute natural frequencies (eigenvalues of acoustic system)
    REAL(wp), INTENT(IN) :: Mass(:,:)
    REAL(wp), INTENT(IN) :: Stiffness(:,:)
    REAL(wp), INTENT(OUT) :: eigenvalues(:)
    INTEGER(i4), INTENT(IN) :: n_eigen
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, max_iter
    REAL(wp), ALLOCATABLE :: A(:,:), work(:)
    REAL(wp) :: shift
    
    n = SIZE(Mass, 1)
    
    IF (n_eigen > n) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           'n_eigen exceeds matrix dimension')
      RETURN
    END IF
    
    ! Shifted inverse power iteration for first n_eigen eigenvalues
    shift = 0.0_wp  ! Shift for stability
    
    DO i = 1, n_eigen
      ! Simple power iteration (simplified)
      eigenvalues(i) = power_iter_eigenvalue(Stiffness, Mass, shift)
      shift = eigenvalues(i) + 1.0_wp  ! Avoid convergence to same mode
    END DO
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  CONTAINS
    
    FUNCTION power_iter_eigenvalue(K, M, shift) RESULT(lambda)
      REAL(wp), INTENT(IN) :: K(:,:), M(:,:), shift
      REAL(wp) :: lambda
      INTEGER(i4) :: n, iter, max_iter
      REAL(wp), ALLOCATABLE :: v(:), v_new(:)
      REAL(wp) :: beta, tol
      
      n = SIZE(K, 1)
      max_iter = 100
      tol = 1.0e-8_wp
      ALLOCATE(v(n), v_new(n))
      
      ! Initial guess
      v = 1.0_wp
      beta = 0.0_wp
      
      DO iter = 1, max_iter
        v_new = MATMUL(K - shift * M, v)
        beta = SQRT(DOT_PRODUCT(v_new, v_new))
        IF (beta < tol) EXIT
        v = v_new / beta
      END DO
      
      lambda = beta + shift
      DEALLOCATE(v, v_new)
      
    END FUNCTION power_iter_eigenvalue
    
  END SUBROUTINE PH_Acoustic_Compute_Eigenvalues
  
  !-----------------------------------------------------------------------------
  ! FUNCTION: PH_Acoustic_Estimate_CFL
  !-----------------------------------------------------------------------------
  FUNCTION PH_Acoustic_Estimate_CFL(c, dx, dt) RESULT(cfl)
    !! Estimate Courant-Friedrichs-Lewy number for stability
    REAL(wp), INTENT(IN) :: c        ! Sound speed [m/s]
    REAL(wp), INTENT(IN) :: dx       ! Element size [m]
    REAL(wp), INTENT(IN) :: dt       ! Time step [s]
    REAL(wp) :: cfl
    
    ! CFL for 1D: c*dt/dx
    ! For 3D acoustic: CFL = c*dt * sqrt(1/dx² + 1/dy² + 1/dz²)
    cfl = c * dt / dx
    
  END FUNCTION PH_Acoustic_Estimate_CFL
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Time_To_Frequency
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Time_To_Frequency(p_time, t_array, &
       p_freq, f_array, status)
    !! Transform time-domain signal to frequency domain (FFT)
    REAL(wp), INTENT(IN) :: p_time(:)    ! Time-domain pressure
    REAL(wp), INTENT(IN) :: t_array(:)   ! Time array
    COMPLEX(wp), INTENT(OUT) :: p_freq(:) ! Frequency-domain spectrum
    REAL(wp), INTENT(OUT) :: f_array(:)  ! Frequency array
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i
    REAL(wp) :: dt, df
    
    n = SIZE(p_time)
    
    IF (SIZE(p_freq) /= n .OR. SIZE(f_array) /= n) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           'Array size mismatch')
      RETURN
    END IF
    
    IF (SIZE(t_array) /= n) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           'Time array size mismatch')
      RETURN
    END IF
    
    dt = t_array(2) - t_array(1)
    df = 1.0_wp / (REAL(n, wp) * dt)
    
    ! Generate frequency array
    DO i = 1, n
      f_array(i) = REAL(i-1, wp) * df
    END DO
    
    ! Simple DFT (replace with FFT in production)
    DO i = 1, n
      p_freq(i) = DFT_point(p_time, t_array, f_array(i))
    END DO
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  CONTAINS
    
    FUNCTION DFT_point(signal, t, freq) RESULT(value)
      REAL(wp), INTENT(IN) :: signal(:), t(:), freq
      COMPLEX(wp) :: value
      INTEGER(i4) :: n, i
      REAL(wp) :: omega, phase
      n = SIZE(signal)
      omega = 2.0_wp * 3.14159265358979_wp * freq
      value = CMPLX(0.0_wp, 0.0_wp, wp)
      DO i = 1, n
        phase = omega * t(i)
        value = value + CMPLX(signal(i) * COS(phase), &
             -signal(i) * SIN(phase), wp)
      END DO
      value = value / REAL(n, wp)
    END FUNCTION DFT_point
    
  END SUBROUTINE PH_Acoustic_Time_To_Frequency
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Frequency_To_Time
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Frequency_To_Time(p_freq, f_array, &
       p_time, t_array, status)
    !! Transform frequency-domain spectrum to time domain (inverse FFT)
    COMPLEX(wp), INTENT(IN) :: p_freq(:)
    REAL(wp), INTENT(IN) :: f_array(:)
    REAL(wp), INTENT(OUT) :: p_time(:)
    REAL(wp), INTENT(OUT) :: t_array(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i
    REAL(wp) :: dt, t_max
    
    n = SIZE(p_freq)
    
    IF (SIZE(p_time) /= n .OR. SIZE(t_array) /= n) THEN
      CALL init_error_status(status, STATUS_ERROR, 'Array size mismatch')
      RETURN
    END IF
    
    ! Generate time array
    t_max = 1.0_wp / (f_array(2) - f_array(1))
    dt = t_max / REAL(n, wp)
    DO i = 1, n
      t_array(i) = REAL(i-1, wp) * dt
    END DO
    
    ! Simple inverse DFT
    DO i = 1, n
      p_time(i) = REAL(iDFT_point(p_freq, f_array, t_array(i)))
    END DO
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  CONTAINS
    
    FUNCTION iDFT_point(spectrum, f, t) RESULT(value)
      COMPLEX(wp), INTENT(IN) :: spectrum(:)
      REAL(wp), INTENT(IN) :: f(:), t
      COMPLEX(wp) :: value
      INTEGER(i4) :: n, i
      REAL(wp) :: omega, phase
      n = SIZE(spectrum)
      value = CMPLX(0.0_wp, 0.0_wp, wp)
      DO i = 1, n
        omega = 2.0_wp * 3.14159265358979_wp * f(i)
        phase = omega * t
        value = value + spectrum(i) * CMPLX(COS(phase), SIN(phase), wp)
      END DO
    END FUNCTION iDFT_point
    
  END SUBROUTINE PH_Acoustic_Frequency_To_Time

  !============================================================================
  ! P6-3: MATERIAL MODEL DEEP INTEGRATION
  !============================================================================
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Map_Material_To_Context
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Map_Material_To_Context(material, ctx, status)
    !! Map MD_Mat_Acoustic_Desc to unified analysis context
    TYPE(MD_Mat_Acoustic_Desc), INTENT(IN) :: material
    TYPE(PH_Acoustic_Unified_Analysis_Ctx), INTENT(OUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Basic acoustic properties
    ctx%density = material%density_ref
    ctx%bulk_modulus = material%bulk_modulus_ref
    ctx%sound_speed = material%sound_speed_ref
    
    ! Temperature dependence
    ctx%use_thermo_coupling = material%use_temp_dependence
    IF (material%use_temp_dependence) THEN
      ctx%T_ref = material%T_ref
      ctx%c0_ref = material%sound_speed_ref
    END IF
    
    ! Porous media (Biot)
    ctx%use_porous_media = material%is_porous_media
    IF (material%is_porous_media) THEN
      ctx%porosity = material%porosity
      ctx%permeability = material%permeability
      ctx%tortuosity = material%tortuosity
    END IF
    
    CALL init_error_status(status, IF_STATUS_OK, &
         'Material mapped to context successfully')
    
  END SUBROUTINE PH_Acoustic_Map_Material_To_Context
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Biot_Wave_Speeds
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Biot_Wave_Speeds(material, c_p1, c_p2, c_s, status)
    !! Compute Biot wave speeds for porous media
    !!
    !! Theory: Biot (1956) three-wave system
    !!   c_p1: Fast compressional wave (P1)
    !!   c_p2: Slow compressional wave (P2) - mostly fluid
    !!   c_s:  Shear wave (S)
    !!
    !! For high porosity (φ → 1): c_p1 ≈ c_f, c_p2 ≈ c_s ≈ 0
    !! For low porosity (φ → 0): c_p1 ≈ c_s ≈ c_solid
    TYPE(MD_Mat_Acoustic_Desc), INTENT(IN) :: material
    REAL(wp), INTENT(OUT) :: c_p1     ! Fast P-wave [m/s]
    REAL(wp), INTENT(OUT) :: c_p2     ! Slow P-wave [m/s]
    REAL(wp), INTENT(OUT) :: c_s      ! S-wave [m/s]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: rho_s, K_s, K_f, K_b, eta, phi
    REAL(wp) :: rho_11, rho_12, rho_22, R, Q
    REAL(wp) :: Delta, a, b, c_term
    
    IF (.NOT. material%is_porous_media) THEN
      ! Not porous media - return fluid acoustic speed
      c_p1 = SQRT(material%bulk_modulus_ref / material%density_ref)
      c_p2 = 0.0_wp
      c_s = 0.0_wp
      CALL init_error_status(status, IF_STATUS_OK, &
           'Not porous media, returning fluid c')
      RETURN
    END IF
    
    ! Extract parameters
    phi = material%porosity
    eta = material%viscosity  ! Assumed field in material
    
    ! Simplified Biot parameters (placeholder values)
    rho_s = 2500.0_wp         ! Solid density [kg/m³]
    K_s = 3.6e10_wp          ! Solid bulk modulus [Pa]
    K_f = material%bulk_modulus_ref  ! Fluid bulk modulus
    K_b = K_f * (1.0_wp + 2.0_wp*phi)  ! Bulk frame modulus (simplified)
    
    ! Densities
    rho_11 = (1.0_wp - phi) * rho_s - material%tortuosity**2 * phi * rho_s
    rho_12 = material%tortuosity * phi * rho_s - (1.0_wp - phi) * rho_s
    rho_22 = phi * rho_s
    
    ! Coupling modulus
    R = K_f / phi
    Q = (1.0_wp - phi - K_b/K_s) * K_f / phi
    
    ! Characteristic equation coefficients
    a = rho_11 * rho_22 - rho_12**2
    b = (rho_11 + rho_12) * K_b + (rho_22 + rho_12) * R + 2.0_wp * rho_12 * Q
    c_term = K_b * K_b
    
    ! Discriminant
    Delta = b*b - 4.0_wp * a * c_term
    
    IF (Delta < 0.0_wp) THEN
      Delta = 0.0_wp  ! Clamp for numerical stability
    END IF
    
    ! Wave speeds
    c_p1 = SQRT((b + SQRT(Delta)) / (2.0_wp * a))  ! Fast P-wave
    c_p2 = SQRT((b - SQRT(Delta)) / (2.0_wp * a))  ! Slow P-wave
    
    ! Shear wave (simplified)
    c_s = SQRT(K_b / rho_11)
    
    CALL init_error_status(status, IF_STATUS_OK, &
         'Biot wave speeds computed')
    
  END SUBROUTINE PH_Acoustic_Biot_Wave_Speeds
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Compute_Impedance
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Compute_Impedance(ctx, omega, Z, status)
    !! Compute acoustic impedance Z = ρc at given frequency
    TYPE(PH_Acoustic_Unified_Analysis_Ctx), INTENT(IN) :: ctx
    REAL(wp), INTENT(IN) :: omega           ! Angular frequency [rad/s]
    COMPLEX(wp), INTENT(OUT) :: Z           ! Acoustic impedance
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: rho, c, Z_0
    
    rho = ctx%density
    c = ctx%sound_speed
    Z_0 = rho * c  ! Characteristic impedance
    
    ! For lossy media: Z = Z_0 * (1 + i*δ) where δ is loss angle
    ! For viscous/thermal dissipation: Z = Z_0 * sqrt(1 + i*ω*τ)
    Z = CMPLX(Z_0, 0.0_wp, wp)
    
    IF (ctx%use_porous_media) THEN
      ! Biot porous media impedance model
      CALL porous_impedance(rho, c, omega, Z)
    END IF
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  CONTAINS
    
    SUBROUTINE porous_impedance(rho, c, w, Z_pml)
      REAL(wp), INTENT(IN) :: rho, c, w
      COMPLEX(wp), INTENT(OUT) :: Z_pml
      REAL(wp) :: phi, tau, kappa, omega_c
      COMPLEX(wp) :: i_unit
      
      i_unit = CMPLX(0.0_wp, 1.0_wp, wp)
      phi = ctx%porosity
      tau = ctx%tortuosity
      kappa = ctx%permeability
      
      ! Characteristic frequency
      IF (kappa > 0.0_wp) THEN
        omega_c = phi * eta / (rho * kappa)  ! Simplified
      ELSE
        omega_c = 1.0e10_wp
      END IF
      
      ! High-frequency limit: Z → ρ*c
      ! Low-frequency limit: Z → sqrt(ρ*K/i*ω) (diffusive)
      Z_pml = CMPLX(rho*c, 0.0_wp, wp)  ! Placeholder
      
    END SUBROUTINE porous_impedance
    
  END SUBROUTINE PH_Acoustic_Compute_Impedance
  
  !-----------------------------------------------------------------------------
  ! SUBROUTINE: PH_Acoustic_Temperature_Dependent_c
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Acoustic_Temperature_Dependent_c(ctx, T, c_T, status)
    !! Compute temperature-dependent sound speed c(T)
    !!
    !! Theory: For ideal gases:
    !!   c(T) = c₀ * sqrt(T/T₀)
    !!
    !! For real gases/fluids:
    !!   c(T) = c₀ * sqrt(1 + α_T*(T-T₀) + ...)
    TYPE(PH_Acoustic_Unified_Analysis_Ctx), INTENT(IN) :: ctx
    REAL(wp), INTENT(IN) :: T            ! Current temperature [K]
    REAL(wp), INTENT(OUT) :: c_T        ! Sound speed at T [m/s]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: T_0, c_0, gamma, R_gas
    
    IF (.NOT. ctx%use_thermo_coupling) THEN
      c_T = ctx%sound_speed
      CALL init_error_status(status, IF_STATUS_OK, &
           'Thermo coupling disabled, using ref c')
      RETURN
    END IF
    
    T_0 = ctx%T_ref
    c_0 = ctx%c0_ref
    
    IF (T <= 0.0_wp .OR. T_0 <= 0.0_wp) THEN
      c_T = c_0
      CALL init_error_status(status, STATUS_WARNING, &
           'Invalid temperature, using ref c')
      RETURN
    END IF
    
    ! Ideal gas: c(T) = c₀ * sqrt(T/T₀)
    c_T = c_0 * SQRT(T / T_0)
    
    ! Physical bounds check (prevent unrealistic values)
    c_T = MAX(c_T, 0.1_wp * c_0)
    c_T = MIN(c_T, 10.0_wp * c_0)
    
    CALL init_error_status(status, IF_STATUS_OK, &
         'Temperature-dependent c computed')
    
  END SUBROUTINE PH_Acoustic_Temperature_Dependent_c

END MODULE PH_Elem_AcousticSuite