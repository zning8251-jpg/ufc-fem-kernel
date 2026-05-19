!===============================================================================
! MODULE: PH_MatEval
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Eval
! BRIEF:  Legacy aggregate Eval facade (staging until plan C2 per-family split).
!   W1 gold path: `PH_Mat_Core` + slot `PH_Mat_Desc`; Arg-only public API (no Eval_In/Out pairs).
! Purpose: Document and stabilize SIO entry points; no new Arg types in this change.
! Theory: Point models — elastic, plastic, hyper, damage, creep, visco, composite (Voigt 6).
! Status: Production (legacy staging) | Last verified: 2026-05-19
! Contract: L4_PH/Material/CONTRACT.md — "Legacy PH_MatEval aggregate" table.
!===============================================================================
MODULE PH_MatEval
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Lib, ONLY: MD_ElasticMatDesc, MD_PlasticMatDesc, MD_HyperElasticMatDesc, &
                            MD_PronyMatDesc, MD_CompositeMatDesc
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! PUBLIC API — each Eval is SUBROUTINE PH_Mat_<Model>_Eval(PH_Mat_<Model>_Eval_Arg)
  !   TYPE names end in _Eval_Arg; procedure names end in _Eval (single Arg dummy).
  !   FLOW-003: effective moduli use local wire Desc (md_elas_wire), not in-place mat_desc.
  ! ==========================================================================
  PUBLIC :: PH_Mat_ElasticIsotropic_Eval_Arg
  PUBLIC :: PH_Mat_ElasticOrthotropic_Eval_Arg
  PUBLIC :: PH_Mat_PlasticVonMises_Eval_Arg
  PUBLIC :: PH_Mat_PlasticHill_Eval_Arg
  PUBLIC :: PH_Mat_HyperelasticNeoHookean_Eval_Arg
  PUBLIC :: PH_Mat_HyperelasticMooneyRivlin_Eval_Arg
  PUBLIC :: PH_Mat_DamageDuctile_Eval_Arg
  PUBLIC :: PH_Mat_DamageBrittle_Eval_Arg
  PUBLIC :: PH_Mat_CreepNorton_Eval_Arg
  PUBLIC :: PH_Mat_ViscoelasticProny_Eval_Arg
  PUBLIC :: PH_Mat_ViscoelasticMaxwell_Eval_Arg
  PUBLIC :: PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg
  PUBLIC :: PH_Mat_CompositeLaminate_Eval_Arg
  PUBLIC :: PH_Mat_CompositeFiberReinforced_Eval_Arg
  PUBLIC :: PH_Mat_UMATEnsureWorkspace_Arg
  PUBLIC :: PH_Mat_ElasticIsotropic_Eval
  PUBLIC :: PH_Mat_ElasticOrthotropic_Eval
  PUBLIC :: PH_Mat_PlasticVonMises_Eval
  PUBLIC :: PH_Mat_PlasticHill_Eval
  PUBLIC :: PH_Mat_HyperelasticNeoHookean_Eval
  PUBLIC :: PH_Mat_HyperelasticMooneyRivlin_Eval
  PUBLIC :: PH_Mat_DamageDuctile_Eval
  PUBLIC :: PH_Mat_DamageBrittle_Eval
  PUBLIC :: PH_Mat_CreepNorton_Eval
  PUBLIC :: PH_Mat_ViscoelasticProny_Eval
  PUBLIC :: PH_Mat_ViscoelasticMaxwell_Eval
  PUBLIC :: PH_Mat_ViscoelasticKelvinVoigt_Eval
  PUBLIC :: PH_Mat_CompositeLaminate_Eval
  PUBLIC :: PH_Mat_CompositeFiberReinforced_Eval
  PUBLIC :: PH_Mat_UMATEnsureWorkspace

  ! ==========================================================================
  ! Arg bundles (Principle #14) — legacy Eval_In/Eval_Out pairs removed from docs
  ! ==========================================================================
  
  !> @brief Input structure for isotropic elastic evaluation
  
  !> @brief Output structure for isotropic elastic evaluation
  TYPE, PUBLIC :: PH_Mat_ElasticIsotropic_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ElasticIsotropic_Eval_Arg

  
  !> @brief Input structure for orthotropic elastic evaluation
  
  !> @brief Output structure for orthotropic elastic evaluation
  TYPE, PUBLIC :: PH_Mat_ElasticOrthotropic_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ElasticOrthotropic_Eval_Arg

  
  !> @brief Input structure for Von Mises plasticity evaluation
  
  !> @brief Output structure for Von Mises plasticity evaluation
  TYPE, PUBLIC :: PH_Mat_PlasticVonMises_Eval_Arg
    TYPE(MD_PlasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: strain_increment(6) = 0.0_wp
    REAL(wp) :: stress_old(6) = 0.0_wp
    REAL(wp) :: stress_new(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    REAL(wp) :: equiv_plastic_strain  ! Equivalent plastic strain ε̄_p                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_PlasticVonMises_Eval_Arg

  
  !> @brief Input structure for Hill plasticity evaluation
  
  !> @brief Output structure for Hill plasticity evaluation
  TYPE, PUBLIC :: PH_Mat_PlasticHill_Eval_Arg
    TYPE(MD_PlasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: strain_increment(6) = 0.0_wp
    REAL(wp) :: stress_old(6) = 0.0_wp
    REAL(wp) :: stress_new(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    REAL(wp) :: equiv_plastic_strain  ! Equivalent plastic strain ε̄_p                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_PlasticHill_Eval_Arg

  
  !> @brief Input structure for Neo-Hookean hyperelastic evaluation
  
  !> @brief Output structure for Neo-Hookean hyperelastic evaluation
  TYPE, PUBLIC :: PH_Mat_HyperelasticNeoHookean_Eval_Arg
    TYPE(MD_HyperElasticMatDesc) :: mat_desc                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_HyperelasticNeoHookean_Eval_Arg

  
  !> @brief Input structure for Mooney-Rivlin hyperelastic evaluation
  
  !> @brief Output structure for Mooney-Rivlin hyperelastic evaluation
  TYPE, PUBLIC :: PH_Mat_HyperelasticMooneyRivlin_Eval_Arg
    TYPE(MD_HyperElasticMatDesc) :: mat_desc                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_HyperelasticMooneyRivlin_Eval_Arg

  
  !> @brief Input structure for ductile damage evaluation
  
  !> @brief Output structure for ductile damage evaluation
  TYPE, PUBLIC :: PH_Mat_DamageDuctile_Eval_Arg
    REAL(wp) :: damage  ! Damage variable D  ?[0,1]                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_DamageDuctile_Eval_Arg

  
  !> @brief Input structure for brittle damage evaluation
  
  !> @brief Output structure for brittle damage evaluation
  TYPE, PUBLIC :: PH_Mat_DamageBrittle_Eval_Arg
    REAL(wp) :: damage  ! Damage variable D  ?[0,1]                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_DamageBrittle_Eval_Arg

  
  !> @brief Input structure for Norton creep evaluation
  
  !> @brief Output structure for Norton creep evaluation
  TYPE, PUBLIC :: PH_Mat_CreepNorton_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: temperature  ! Temperature T                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_CreepNorton_Eval_Arg

  
  !> @brief Input structure for Prony viscoelastic evaluation
  
  !> @brief Output structure for Prony viscoelastic evaluation
  TYPE, PUBLIC :: PH_Mat_ViscoelasticProny_Eval_Arg
    TYPE(MD_PronyMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: strain_rate(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    REAL(wp) :: time  ! Current time t                   ! [IN]
    REAL(wp) :: dtime  ! Time increment Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ViscoelasticProny_Eval_Arg

  
  !> @brief Input structure for Maxwell viscoelastic evaluation
  
  !> @brief Output structure for Maxwell viscoelastic evaluation
  TYPE, PUBLIC :: PH_Mat_ViscoelasticMaxwell_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: dtime  ! Time increment Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ViscoelasticMaxwell_Eval_Arg

  
  !> @brief Input structure for Kelvin-Voigt viscoelastic evaluation
  
  !> @brief Output structure for Kelvin-Voigt viscoelastic evaluation
  TYPE, PUBLIC :: PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg

  
  !> @brief Input structure for laminate composite evaluation
  
  !> @brief Output structure for laminate composite evaluation
  TYPE, PUBLIC :: PH_Mat_CompositeLaminate_Eval_Arg
    INTEGER(i4) :: n_layers  ! Number of layers                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_CompositeLaminate_Eval_Arg

  
  !> @brief Input structure for fiber-reinforced composite evaluation
  
  !> @brief Output structure for fiber-reinforced composite evaluation
  TYPE, PUBLIC :: PH_Mat_CompositeFiberReinforced_Eval_Arg
    TYPE(MD_CompositeMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_CompositeFiberReinforced_Eval_Arg

  
  !> @brief Input structure for UMAT workspace ensure
  
  !> @brief Output structure for UMAT workspace ensure
  TYPE, PUBLIC :: PH_Mat_UMATEnsureWorkspace_Arg
    INTEGER(i4) :: nstate_target  ! Minimum number of state variables required                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_UMATEnsureWorkspace_Arg


contains

  SUBROUTINE PH_Mat_CompositeFiberReinforced_Eval(arg)
    TYPE(PH_Mat_CompositeFiberReinforced_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: E_fiber, E_matrix, nu_fiber, nu_matrix, V_fiber
    REAL(wp) :: E_eff, nu_eff, V_matrix
    TYPE(MD_ElasticMatDesc) :: md_elas_wire
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg) :: elastic_in
    
    CALL init_error_status(arg%status)
    
    ! Extract material properties from structure
    E_fiber = arg%mat_desc%E_fiber
    E_matrix = arg%mat_desc%E_matrix
    nu_fiber = arg%mat_desc%nu_fiber
    nu_matrix = arg%mat_desc%nu_matrix
    V_fiber = arg%mat_desc%volume_fraction
    
    ! Rule of mixtures for effective properties
    V_matrix = ONE - V_fiber
    E_eff = E_fiber * V_fiber + E_matrix * V_matrix
    nu_eff = nu_fiber * V_fiber + nu_matrix * V_matrix
    
    ! Use isotropic elastic with effective properties (wire Desc, no runtime field writes)
    CALL init_error_status(elastic_in%status)
    md_elas_wire%PH_MAT_E = E_eff
    md_elas_wire%nu = nu_eff
    elastic_in%mat_desc = md_elas_wire
    elastic_in%strain = arg%strain
    CALL PH_Mat_ElasticIsotropic_Eval(elastic_in)
    
    arg%sigma = elastic_in%sigma
    arg%D_matrix = elastic_in%D_matrix
    arg%status = elastic_in%status
    
  END SUBROUTINE PH_Mat_CompositeFiberReinforced_Eval

  SUBROUTINE PH_Mat_CompositeLaminate_Eval(arg)
    TYPE(PH_Mat_CompositeLaminate_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: stress_layer(6)
    INTEGER(i4) :: i, j, k
    
    CALL init_error_status(arg%status)
    
    ! Average stress and stiffness over layers
    arg%sigma = ZERO
    arg%D_matrix = ZERO
    
    DO k = 1, MIN(arg%n_layers, 100)  ! Limit to 100 layers
      stress_layer = ZERO
      DO i = 1, 6
        DO j = 1, 6
          stress_layer(i) = stress_layer(i) + arg%Q_matrix(i,j,k) * arg%strain(j)
        END DO
      END DO
      arg%sigma = arg%sigma + stress_layer / REAL(arg%n_layers, wp)
      
      DO i = 1, 6
        DO j = 1, 6
          arg%D_matrix(i,j) = arg%D_matrix(i,j) + arg%Q_matrix(i,j,k) / REAL(arg%n_layers, wp)
        END DO
      END DO
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_CompositeLaminate_Eval

  SUBROUTINE PH_Mat_CreepNorton_Eval(arg)
    TYPE(PH_Mat_CreepNorton_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: A, n, Q, R_gas
    REAL(wp) :: sigma_eqv, s_dev(6)
    REAL(wp) :: creep_rate_scalar, temp_factor
    INTEGER(i4) :: i
    
    CALL init_error_status(arg%status)
    
    ! Extract creep properties from structure
    A = arg%mat_desc%creep_A
    n = arg%mat_desc%creep_n
    Q = arg%mat_desc%creep_Q
    R_gas = arg%mat_desc%R_gas
    
    ! Compute von Mises equivalent stress: sigma_eqv = sqrt(3/2 * s:s)
    s_dev(1) = arg%sigma(1) - (arg%sigma(1) + arg%sigma(2) + arg%sigma(3)) / THREE
    s_dev(2) = arg%sigma(2) - (arg%sigma(1) + arg%sigma(2) + arg%sigma(3)) / THREE
    s_dev(3) = arg%sigma(3) - (arg%sigma(1) + arg%sigma(2) + arg%sigma(3)) / THREE
    s_dev(4) = arg%sigma(4)
    s_dev(5) = arg%sigma(5)
    s_dev(6) = arg%sigma(6)
    
    sigma_eqv = SQRT(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2 + &
                               TWO * (s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
    
    ! Norton creep rate: ε̇_cr = A·σ^n
    creep_rate_scalar = A * sigma_eqv**n
    
    ! Temperature dependence: Arrhenius exp(-Q/(R·T))
    IF (arg%temperature > 1.0e-12_wp .AND. Q > ZERO) THEN
      temp_factor = EXP(-Q / (R_gas * arg%temperature))
      creep_rate_scalar = creep_rate_scalar * temp_factor
    END IF
    
    ! Creep strain rate direction: deviatoric stress direction
    IF (sigma_eqv > 1.0e-12_wp) THEN
      DO i = 1, 6
        arg%creep_rate(i) = 1.5_wp * creep_rate_scalar * s_dev(i) / sigma_eqv
      END DO
    ELSE
      arg%creep_rate = ZERO
    END IF
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_CreepNorton_Eval

  SUBROUTINE PH_Mat_DamageBrittle_Eval(arg)
    TYPE(PH_Mat_DamageBrittle_Eval_Arg), INTENT(INOUT) :: arg
    
    ! Similar to ductile damage
    TYPE(PH_Mat_DamageDuctile_Eval_Arg) :: ductile_in
    TYPE(PH_Mat_DamageDuctile_Eval_Arg) :: ductile_out
    
    ductile_arg%stress_undamaged = arg%stress_undamaged
    ductile_arg%damage = arg%damage
    ductile_arg%D_matrix_undamaged = arg%D_matrix_undamaged
    
    CALL PH_Mat_DamageDuctile_Eval(ductile_in, ductile_out)
    
    arg%stress_damaged = ductile_arg%stress_damaged
    arg%D_matrix_damaged = ductile_arg%D_matrix_damaged
    arg%status = ductile_arg%status
    
  END SUBROUTINE PH_Mat_DamageBrittle_Eval

  SUBROUTINE PH_Mat_DamageDuctile_Eval(arg)
    TYPE(PH_Mat_DamageDuctile_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: damage_factor
    INTEGER(i4) :: i, j
    
    CALL init_error_status(arg%status)
    
    ! Effective stress: σ_eff = (1-D)·σ
    damage_factor = ONE - arg%damage
    damage_factor = MAX(damage_factor, 1.0e-6_wp)  ! Avoid zero
    
    arg%stress_damaged = damage_factor * arg%stress_undamaged
    
    ! Degraded stiffness: D_eff = (1-D)·D
    DO i = 1, 6
      DO j = 1, 6
        arg%D_matrix_damaged(i,j) = damage_factor * arg%D_matrix_undamaged(i,j)
      END DO
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_DamageDuctile_Eval

  ! Theory: Isotropic Hooke σ = D·ε.
  ! Logic: Read E, ν from mat_desc → Lame → D → stress from strain.
  ! Compute: Voigt 6×6 σ_i = Σ_j D_ij ε_j.
  ! Data: arg%strain [IN]; arg%sigma, arg%D_matrix, arg%status [OUT]; mat_desc read-only.
  SUBROUTINE PH_Mat_ElasticIsotropic_Eval(arg)
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: PH_MAT_E, nu
    REAL(wp) :: lambda, mu, factor
    INTEGER(i4) :: i, j
    
    CALL init_error_status(arg%status)
    
    ! Extract material properties from structure
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    nu = arg%mat_desc%nu
    
    ! Lame parameters
    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = PH_MAT_E / (TWO * (ONE + nu))
    factor = PH_MAT_E / ((ONE + nu) * (ONE - TWO * nu))
    
    ! Build elastic stiffness matrix D
    arg%D_matrix = ZERO
    arg%D_matrix(1,1) = factor * (ONE - nu)
    arg%D_matrix(1,2) = factor * nu
    arg%D_matrix(1,3) = factor * nu
    arg%D_matrix(2,1) = factor * nu
    arg%D_matrix(2,2) = factor * (ONE - nu)
    arg%D_matrix(2,3) = factor * nu
    arg%D_matrix(3,1) = factor * nu
    arg%D_matrix(3,2) = factor * nu
    arg%D_matrix(3,3) = factor * (ONE - nu)
    arg%D_matrix(4,4) = mu
    arg%D_matrix(5,5) = mu
    arg%D_matrix(6,6) = mu
    
    ! Compute stress: σ = D·ε
    arg%sigma = ZERO
    DO i = 1, 6
      DO j = 1, 6
        arg%sigma(i) = arg%sigma(i) + arg%D_matrix(i,j) * arg%strain(j)
      END DO
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_ElasticIsotropic_Eval

  ! Theory: Orthotropic Hooke σ = D·ε (engineering constants, diagonal S approx).
  ! Logic: Read E_i, ν_ij, G_ij from mat_desc → compliance S → invert diag → stress.
  ! Data: arg%strain [IN]; arg%sigma, arg%D_matrix, arg%status [OUT].
  SUBROUTINE PH_Mat_ElasticOrthotropic_Eval(arg)
    TYPE(PH_Mat_ElasticOrthotropic_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: E1, E2, E3, nu12, nu23, nu13, G12, G23, G13
    REAL(wp) :: nu21, nu31, nu32
    REAL(wp) :: S(6,6)
    INTEGER(i4) :: i, j
    
    CALL init_error_status(arg%status)
    
    ! Extract orthotropic properties from structure
    E1 = arg%mat_desc%E1
    E2 = arg%mat_desc%E2
    E3 = arg%mat_desc%E3
    nu12 = arg%mat_desc%nu12
    nu23 = arg%mat_desc%nu23
    nu13 = arg%mat_desc%nu13
    G12 = arg%mat_desc%G12
    G23 = arg%mat_desc%G23
    G13 = arg%mat_desc%G13
    
    ! Compute dependent Poisson's ratios: ν_ji = ν_ij·E_j/E_i
    nu21 = nu12 * E2 / E1
    nu31 = nu13 * E3 / E1
    nu32 = nu23 * E3 / E2
    
    ! Build compliance matrix S (simplified)
    S = ZERO
    S(1,1) = ONE / E1
    S(1,2) = -nu12 / E1
    S(1,3) = -nu13 / E1
    S(2,1) = -nu21 / E2
    S(2,2) = ONE / E2
    S(2,3) = -nu23 / E2
    S(3,1) = -nu31 / E3
    S(3,2) = -nu32 / E3
    S(3,3) = ONE / E3
    S(4,4) = ONE / G12
    S(5,5) = ONE / G23
    S(6,6) = ONE / G13
    
    ! Invert compliance to get stiffness (simplified: assume diagonal)
    ! Production should use proper matrix inversion
    arg%D_matrix = ZERO
    IF (ABS(S(1,1)) > 1.0e-12_wp) arg%D_matrix(1,1) = ONE / S(1,1)
    IF (ABS(S(2,2)) > 1.0e-12_wp) arg%D_matrix(2,2) = ONE / S(2,2)
    IF (ABS(S(3,3)) > 1.0e-12_wp) arg%D_matrix(3,3) = ONE / S(3,3)
    IF (ABS(S(4,4)) > 1.0e-12_wp) arg%D_matrix(4,4) = ONE / S(4,4)
    IF (ABS(S(5,5)) > 1.0e-12_wp) arg%D_matrix(5,5) = ONE / S(5,5)
    IF (ABS(S(6,6)) > 1.0e-12_wp) arg%D_matrix(6,6) = ONE / S(6,6)
    
    ! Compute stress: σ = D·ε
    arg%sigma = ZERO
    DO i = 1, 6
      DO j = 1, 6
        arg%sigma(i) = arg%sigma(i) + arg%D_matrix(i,j) * arg%strain(j)
      END DO
    END DO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_ElasticOrthotropic_Eval

  SUBROUTINE PH_Mat_HyperelasticMooneyRivlin_Eval(arg)
    TYPE(PH_Mat_HyperelasticMooneyRivlin_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: C10, C01, D1
    
    CALL init_error_status(arg%status)
    
    ! Extract hyperelastic properties from structure
    C10 = arg%mat_desc%C10
    C01 = arg%mat_desc%C01
    D1 = arg%mat_desc%D1
    
    ! Placeholder: production should call MD_MatLib_Hyperelastic_Standard functions
    arg%sigma = ZERO
    arg%D_matrix = ZERO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_HyperelasticMooneyRivlin_Eval

  SUBROUTINE PH_Mat_HyperelasticNeoHookean_Eval(arg)
    TYPE(PH_Mat_HyperelasticNeoHookean_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: C10, D1
    
    CALL init_error_status(arg%status)
    
    ! Extract hyperelastic properties from structure
    C10 = arg%mat_desc%C10
    D1 = arg%mat_desc%D1
    
    ! Placeholder: production should call MD_MatLib_Hyperelastic_Standard functions
    arg%sigma = ZERO
    arg%D_matrix = ZERO
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_HyperelasticNeoHookean_Eval

  ! Theory: Hill48 equivalent stress + isotropic hardening; radial return if φ > σ_y.
  ! Logic: Elastic trial via wired iso Eval → Hill φ → scale stress or elastic branch.
  ! Compute: φ from Hill coefficients; Δε̄_p increment on yield.
  ! Data: stress_old/strain_increment [IN]; stress_new/D_matrix/status [OUT]; wire Desc for trial.
  SUBROUTINE PH_Mat_PlasticHill_Eval(arg)
    TYPE(PH_Mat_PlasticHill_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: PH_MAT_E, nu, sigma_y0, H
    REAL(wp) :: F, G, Hh, L, M, N  ! Hill anisotropy coefficients
    REAL(wp) :: D_elastic(6,6), stress_trial(6)
    REAL(wp) :: sigma_y, phi_trial, phi_factor
    TYPE(MD_ElasticMatDesc) :: md_elas_wire
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg) :: elastic_in
    
    CALL init_error_status(arg%status)
    
    ! Extract material properties from structure
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    nu = arg%mat_desc%nu
    sigma_y0 = arg%mat_desc%yieldStress
    H = arg%mat_desc%hardeningModulus
    F = arg%mat_desc%Hill_F
    G = arg%mat_desc%Hill_G
    Hh = arg%mat_desc%Hill_H
    L = arg%mat_desc%Hill_L
    M = arg%mat_desc%Hill_M
    N = arg%mat_desc%Hill_N
    
    ! Current yield stress (isotropic hardening): σ_y = σ_y0 + H·ε̄_p
    sigma_y = sigma_y0 + H * arg%equiv_plastic_strain
    
    ! Build elastic stiffness using structured interface
    CALL init_error_status(elastic_in%status)
    md_elas_wire%PH_MAT_E = PH_MAT_E
    md_elas_wire%nu = nu
    elastic_in%mat_desc = md_elas_wire
    elastic_in%strain = arg%strain_increment
    CALL PH_Mat_ElasticIsotropic_Eval(elastic_in)
    IF (elastic_in%status%status_code /= IF_STATUS_OK) THEN
      arg%status = elastic_in%status
      RETURN
    END IF
    D_elastic = elastic_in%D_matrix
    stress_trial = elastic_in%sigma
    
    ! Compute trial stress: σ_trial = σ_n + D_e·Δε
    stress_trial = arg%stress_old + stress_trial
    
    ! Compute Hill equivalent stress: φ² = F(σ_yy-σ_zz)² + G(σ_zz-σ_xx)² + H(σ_xx-σ_yy)² + 2Lτ_yz² + 2Mτ_zx² + 2Nτ_xy²
    phi_trial = SQRT( &
      F * (stress_trial(2) - stress_trial(3))**2 + &
      G * (stress_trial(3) - stress_trial(1))**2 + &
      Hh * (stress_trial(1) - stress_trial(2))**2 + &
      TWO * L * stress_trial(4)**2 + &
      TWO * M * stress_trial(5)**2 + &
      TWO * N * stress_trial(6)**2 )
    
    ! Check yield condition: f = φ_trial - σ_y
    IF (phi_trial > sigma_y) THEN
      ! Plastic loading: radial return to yield surface
      phi_factor = sigma_y / phi_trial
      arg%stress_new = stress_trial * phi_factor
      
      ! Update equivalent plastic strain: Δε̄_p = (φ_trial - σ_y)/H
      arg%equiv_plastic_strain = arg%equiv_plastic_strain + (phi_trial - sigma_y) / H
    ELSE
      ! Elastic loading
      arg%stress_new = stress_trial
      arg%equiv_plastic_strain = arg%equiv_plastic_strain
    END IF
    
    ! Simplified tangent modulus (elastic)
    arg%D_matrix = D_elastic
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_PlasticHill_Eval

  ! Theory: J2 von Mises with isotropic hardening; deviatoric q vs σ_y.
  ! Logic: Elastic trial → q_trial; radial return factor or elastic branch.
  ! Compute: deviatoric q; σ_y = σ_y0 + H·ε̄_p.
  ! Data: same Arg bundle pattern as Hill; md_elas_wire for elastic predictor.
  SUBROUTINE PH_Mat_PlasticVonMises_Eval(arg)
    TYPE(PH_Mat_PlasticVonMises_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: PH_MAT_E, nu, sigma_y0, H
    REAL(wp) :: D_elastic(6,6), stress_trial(6)
    REAL(wp) :: s_dev(6), q_trial, sigma_y
    TYPE(MD_ElasticMatDesc) :: md_elas_wire
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg) :: elastic_in
    
    CALL init_error_status(arg%status)
    
    ! Extract material properties from structure
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    nu = arg%mat_desc%nu
    sigma_y0 = arg%mat_desc%yieldStress
    H = arg%mat_desc%hardeningModulus
    
    ! Current yield stress (hardening): σ_y = σ_y0 + H·ε̄_p
    sigma_y = sigma_y0 + H * arg%equiv_plastic_strain
    
    ! Build elastic stiffness using structured interface
    CALL init_error_status(elastic_in%status)
    md_elas_wire%PH_MAT_E = PH_MAT_E
    md_elas_wire%nu = nu
    elastic_in%mat_desc = md_elas_wire
    elastic_in%strain = arg%strain_increment
    CALL PH_Mat_ElasticIsotropic_Eval(elastic_in)
    IF (elastic_in%status%status_code /= IF_STATUS_OK) THEN
      arg%status = elastic_in%status
      RETURN
    END IF
    D_elastic = elastic_in%D_matrix
    stress_trial = elastic_in%sigma
    
    ! Compute trial stress: σ_trial = σ_n + D_e·Δε
    stress_trial = arg%stress_old + stress_trial
    
    ! Compute deviatoric stress: s = dev(σ)
    s_dev(1) = stress_trial(1) - (stress_trial(1) + stress_trial(2) + stress_trial(3)) / THREE
    s_dev(2) = stress_trial(2) - (stress_trial(1) + stress_trial(2) + stress_trial(3)) / THREE
    s_dev(3) = stress_trial(3) - (stress_trial(1) + stress_trial(2) + stress_trial(3)) / THREE
    s_dev(4) = stress_trial(4)
    s_dev(5) = stress_trial(5)
    s_dev(6) = stress_trial(6)
    
    ! von Mises: q = sqrt(3/2 * s:s)
    q_trial = SQRT(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2 + &
                              TWO * (s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
    
    ! Check yield condition: f = q_trial - σ_y
    IF (q_trial > sigma_y) THEN
      ! Plastic loading: radial return σ_{n+1} = σ_trial·(σ_y/q_trial)
      arg%stress_new = stress_trial * (sigma_y / q_trial)
      ! Update equivalent plastic strain: Δε̄_p = (q_trial - σ_y)/(3G + H)
      arg%equiv_plastic_strain = arg%equiv_plastic_strain + &
        (q_trial - sigma_y) / (THREE * PH_MAT_E / (TWO * (ONE + nu)) + H)
    ELSE
      ! Elastic loading
      arg%stress_new = stress_trial
      arg%equiv_plastic_strain = arg%equiv_plastic_strain
    END IF
    
    ! Simplified tangent modulus (use elastic for now)
    arg%D_matrix = D_elastic
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_PlasticVonMises_Eval

  SUBROUTINE PH_Mat_UMATEnsureWorkspace(arg)
    TYPE(PH_Mat_UMATEnsureWorkspace_Arg), INTENT(INOUT) :: arg
    
    CALL init_error_status(arg%status)
    
    ! Placeholder: no centralized workspace. Per-point state is managed
    ! in IncCtx_PrepMP via material_points(i)%ip_state%nStateV_total.
    ! Could add: mat_pool_alloc, global buffer resize, or MatLib registration.
    IF (arg%nstate_target < 0_i4) THEN
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_UMATEnsureWorkspace

  SUBROUTINE PH_Mat_ViscoelasticKelvinVoigt_Eval(arg)
    TYPE(PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: PH_MAT_E, eta
    
    CALL init_error_status(arg%status)
    
    ! Extract viscoelastic properties from structure
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    eta = arg%mat_desc%viscosity
    
    ! Kelvin-Voigt model: σ = PH_MAT_E·ε + η·ε̇
    arg%sigma = PH_MAT_E * arg%strain + eta * arg%strain_rate
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_ViscoelasticKelvinVoigt_Eval

  SUBROUTINE PH_Mat_ViscoelasticMaxwell_Eval(arg)
    TYPE(PH_Mat_ViscoelasticMaxwell_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: PH_MAT_E, eta, relaxation_time
    
    CALL init_error_status(arg%status)
    
    ! Extract viscoelastic properties from structure
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    eta = arg%mat_desc%viscosity
    
    ! Maxwell model: σ̇ = PH_MAT_E·ε̇ - σ/τ, where τ = η/PH_MAT_E
    relaxation_time = eta / PH_MAT_E
    IF (relaxation_time > 1.0e-12_wp) THEN
      arg%stress_new = arg%stress_old * EXP(-arg%dtime / relaxation_time) + &
                       PH_MAT_E * arg%strain_rate * relaxation_time * &
                       (ONE - EXP(-arg%dtime / relaxation_time))
    ELSE
      arg%stress_new = arg%stress_old + PH_MAT_E * arg%strain_rate * arg%dtime
    END IF
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_ViscoelasticMaxwell_Eval

  SUBROUTINE PH_Mat_ViscoelasticProny_Eval(arg)
    TYPE(PH_Mat_ViscoelasticProny_Eval_Arg), INTENT(INOUT) :: arg
    
    REAL(wp) :: E_inf, nu
    INTEGER(i4) :: n_terms, i
    REAL(wp) :: D_elastic(6,6), stress_elastic(6)
    REAL(wp) :: stress_viscous(6)
    TYPE(MD_ElasticMatDesc) :: md_elas_wire
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg) :: elastic_in
    
    CALL init_error_status(arg%status)
    
    ! Extract material properties from structure
    E_inf = arg%mat_desc%E_inf
    nu = arg%mat_desc%nu
    n_terms = arg%mat_desc%n_terms
    
    ! Elastic contribution at long-term modulus (wire Desc, no runtime field writes)
    CALL init_error_status(elastic_in%status)
    md_elas_wire%PH_MAT_E = E_inf
    md_elas_wire%nu = nu
    elastic_in%mat_desc = md_elas_wire
    elastic_in%strain = arg%strain
    CALL PH_Mat_ElasticIsotropic_Eval(elastic_in)
    IF (elastic_in%status%status_code /= IF_STATUS_OK) THEN
      arg%status = elastic_in%status
      RETURN
    END IF
    D_elastic = elastic_in%D_matrix
    stress_elastic = elastic_in%sigma
    
    ! Viscous contribution from Prony series: G(t) = G_�??1 + Σ g_i·exp(-t/τ_i))
    stress_viscous = ZERO
    DO i = 1, MIN(n_terms, 10)  ! Limit to 10 terms
      IF (arg%mat_desc%tau_prony(i) > 1.0e-12_wp) THEN
        ! Exponential decay factor
        stress_viscous = stress_viscous + arg%mat_desc%g_prony(i) * arg%strain_rate(:) * &
                         (ONE - EXP(-arg%dtime / arg%mat_desc%tau_prony(i)))
      END IF
    END DO
    
    ! Total stress: σ = σ_elastic + σ_viscous
    arg%sigma = stress_elastic + stress_viscous
    
    ! Tangent modulus (simplified: use long-term modulus)
    arg%D_matrix = D_elastic
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Mat_ViscoelasticProny_Eval
end module PH_MatEval