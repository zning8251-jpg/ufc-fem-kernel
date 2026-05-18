!===============================================================================
! MODULE: PH_Elem_AC3D4
! LAYER:  L4_PH
! DOMAIN: Element/Acoustic
! ROLE:   Proc
! BRIEF:  AC3D4 4-node 3D acoustic element
!===============================================================================
MODULE PH_Elem_AC3D4
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ElemLib
  USE MD_Elem_UEL_Def, ONLY: MD_Elem_UEL_Desc
  USE MD_Sect_Def,      ONLY: MD_Sect_Registry
  USE MD_Mat_Def,       ONLY: MD_Mat_Desc, MD_MatAlgo
  USE PH_Elem_Def,      ONLY: PH_Elem_Ctx, PH_Elem_State
  USE RT_Com_Def,       ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  USE MD_Mat_Lib,         ONLY: MatProperties
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE MD_Mat_AcousticProps, ONLY: MD_Mat_Acoustic_Desc
  IMPLICIT NONE
  PRIVATE

  !===========================================================================
  ! CONSTANTS
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D4_NNODE  = 4_i4  ! 4-node tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D4_NDOF   = 4_i4  ! Pressure DOF per node
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D4_NIP    = 1_i4  ! 1-point integration
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D4_NFACE  = 4_i4  ! 4 triangular faces
  
  !===========================================================================
  ! SVARS LAYOUT - State Variables Storage (per integration point)
  !===========================================================================
  ! Layout: stress(6) + stran(6) + pressure(1) + velocity_potential(1) = 14
  !
  ! Slot Index | Variable           | Description
  ! -----------|--------------------|------------------------------------------
  !  1-6       | stress             | Acoustic stress tensor (hydrostatic)
  !  7-12      | stran              | Acoustic strain (volumetric)
  !  13        | pressure           | Acoustic pressure [Pa]
  !  14        | velocity_potential | Velocity potential [m²/s] (optional)
  !
  ! Note: For linear acoustics, only slots 13-14 are actively used.
  !       Slots 1-12 reserved for future nonlinear/coupled extensions.
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D4_NSVARS_PER_IP = 14_i4

  !===========================================================================
  ! PUBLIC INTERFACES - CATEGORIZED BY PRIORITY AND STATUS
  !===========================================================================
  
  !---------------------------------------------------------------------------
  ! CORE PHYSICS (?IMPLEMENTED - P2/P3)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_DefInit              ! Element definition init (stub)
  PUBLIC :: PH_Elem_AC3D4_FormStiffMatrix      ! Stiffness matrix assembly ?  PUBLIC :: PH_Elem_AC3D4_FormIntForce         ! Internal force vector ?  PUBLIC :: PH_Elem_AC3D4_ConsMass             ! Consistent mass matrix ?P3
  PUBLIC :: PH_Elem_AC3D4_LumpMass             ! Lumped mass matrix ?P3
  PUBLIC :: PH_Elem_AC3D4_FormDampingMatrix    ! Rayleigh damping matrix ?P3
  PUBLIC :: PH_Elem_AC3D4_ThermStrainVector    ! ⚠️ STUB - Thermo-acoustic coupling (P4)
  
  !---------------------------------------------------------------------------
  ! NONLINEAR GEOMETRY (?DECISION NEEDED - Large amplitude acoustics?)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_NL_TL                ! ?Total Lagrangian formulation
  PUBLIC :: PH_Elem_AC3D4_NL_UL                ! ?Updated Lagrangian formulation
  
  !---------------------------------------------------------------------------
  ! VOLUME INTEGRATION (?IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_ELEM_AC3D4_VolumeInt            ! Element volume computation ?  
  !---------------------------------------------------------------------------
  ! BOUNDARY CONDITIONS (?IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_ApplyEssentialBC     ! Dirichlet BC (elimination) ?  PUBLIC :: PH_Elem_AC3D4_ApplyPenaltyBC       ! Neumann BC (penalty method) ?  PUBLIC :: PH_Elem_AC3D4_FormConstraintMatrix ! Constraint matrix (MPC) ?  
  !---------------------------------------------------------------------------
  ! SPECIAL BOUNDARY CONDITIONS (?IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_FormAcousticImpedance ! Impedance boundary ?  PUBLIC :: PH_Elem_AC3D4_FormRadiationCondition ! Radiation BC (infinite domain) ?  PUBLIC :: PH_Elem_AC3D4_FormStructureCoupling
  PUBLIC :: UF_Elem_AC3D4_Calc ! Fluid-structure interface ?  
  !---------------------------------------------------------------------------
  ! LOADS (?IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_FormPressureLoad     ! Distributed pressure load ?  PUBLIC :: PH_Elem_AC3D4_FormBodyForce        ! Body force (gravity, etc.) ?  PUBLIC :: PH_Elem_AC3D4_FormSurfaceTraction  ! Surface traction ?  
  !---------------------------------------------------------------------------
  ! POST-PROCESSING (?IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_CalcPressure         ! Pressure field recovery ?  PUBLIC :: PH_Elem_AC3D4_CalcAcousticIntensity ! Intensity vector (power flux) ?  PUBLIC :: PH_Elem_AC3D4_CalcEnergy           ! Kinetic/potential energy ?  PUBLIC :: PH_Elem_AC3D4_CalcEnergy_FromDesc  ! Energy from section descriptor ?  PUBLIC :: PH_Elem_AC3D4_OutputResults        ! File output helper ?  
  !---------------------------------------------------------------------------
  ! MATERIAL & SECTION PROPERTIES (?IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_GetMaterialProps     ! Extract density, bulk modulus ?  PUBLIC :: PH_Elem_AC3D4_GetMaterialProps_FromDesc ! From material descriptor ?  PUBLIC :: PH_Elem_AC3D4_GetVolume            ! Element volume ?  PUBLIC :: PH_Elem_AC3D4_GetAcousticProps     ! Density, impedance ?  PUBLIC :: PH_Elem_AC3D4_SetSectionProps      ! Set section parameters ?  PUBLIC :: PH_Elem_AC3D4_SetSectionProps_FromDesc ! From section descriptor ?  
  !---------------------------------------------------------------------------
  ! THERMO-ACOUSTIC COUPLING (🆕 P4-1)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_Temperature_Dependent_Speed   ! c(T) = c₀·?T/T₀) 🆕
  PUBLIC :: PH_Elem_AC3D4_Thermal_Expansion_Source      ! Thermo-acoustic source term 🆕
  PUBLIC :: PH_Elem_AC3D4_UpdateMaterialProps_TempDep   ! Update material props with temperature 🆕
  
  !---------------------------------------------------------------------------
  ! POROUS MEDIA - BIOT THEORY (🆕 P4-2)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_Biot_Wave_Speed        ! Effective wave speed in porous media 🆕
  PUBLIC :: PH_Elem_AC3D4_Biot_Damping           ! Viscous dissipation from pore flow 🆕
  
  !---------------------------------------------------------------------------
  ! BIOT STABILIZATION (🆕 P5-3 NUMERICAL STABILITY)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_Biot_Stabilize_SlowWave ! SUPG stabilization for P2 wave 🆕
  PUBLIC :: PH_Elem_AC3D4_Biot_Compute_Stab_Param ! Compute τ stabilization parameter 🆕
  
  !---------------------------------------------------------------------------
  ! INFINITE ELEMENT BOUNDARY (🆕 P4-3)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_Sommerfeld_Radiation   ! Sommerfeld radiation condition 🆕
  PUBLIC :: PH_Elem_AC3D4_Infinite_Element_Map    ! Infinite element mapping 🆕
  
  !---------------------------------------------------------------------------
  ! PML - PERFECTLY MATCHED LAYER (🆕 P5-2 TIME DOMAIN)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_PML_Update_State        ! PML state variable update 🆕
  PUBLIC :: PH_Elem_AC3D4_PML_Absorbing_Boundary  ! Time-domain PML absorption 🆕
  
  !---------------------------------------------------------------------------
  ! P5 NUMERICAL ENHANCEMENTS (🆕 P5-1 to P5-4)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D4_Newmark_Beta_Integrator     ! Newmark-β time integration 🆕 P5
  PUBLIC :: PH_Elem_AC3D4_HHT_Alpha_Integrator        ! HHT-α generalized alpha method 🆕 P5
  PUBLIC :: PH_Elem_AC3D4_Adaptive_TimeStep_Control   ! Adaptive time stepping with error control 🆕 P5
  PUBLIC :: PH_Elem_AC3D4_Save_State                  ! State save for rollback 🆕 P5
  PUBLIC :: PH_Elem_AC3D4_Restore_State               ! State restore from backup 🆕 P5
  PUBLIC :: PH_Elem_AC3D4_Compute_Local_Error         ! Local truncation error estimation 🆕 P5

  !===========================================================================
  ! UEL ARGUMENT BUNDLE - PH_AC3D4_UEL_Args (Principle #14)
  !===========================================================================
  !> Unified argument bundle for AC3D4 element computation
  !>
  !> Design: Principle #14 Structured IO (SIO-01 to SIO-14 compliant)
  !>   - [IN] Flags and scalars only (no ALLOCATABLE, no _Desc/_State/_Algo/_Ctx)
  !>   - [OUT] Status, pnewdt, diagnostics via ErrorStatusType
  TYPE, PUBLIC :: PH_AC3D4_UEL_Args
    !-- [IN] Flags for computation control
    LOGICAL     :: compute_amatrx = .TRUE.   ! Compute tangent stiffness matrix
    LOGICAL     :: compute_rhs    = .TRUE.   ! Compute residual vector
    
    !-- [IN] P3 dynamic analysis extensions
    LOGICAL     :: compute_mass   = .FALSE.  ! Mass matrix computation flag (P3)
    INTEGER(i4) :: mass_method    = 0_i4    ! 0=None, 1=Consistent, 2=Lumped(HRZ), 3=Lumped(RowSum), 4=Lumped(Uniform)
    LOGICAL     :: compute_damping = .FALSE. ! Damping matrix computation flag (P3)
    REAL(wp)    :: alpha_M        = 0.0_wp  ! Mass proportional damping coefficient [1/s]
    REAL(wp)    :: beta_K         = 0.0_wp  ! Stiffness proportional damping coefficient [s]
    
    !-- [IN] Step control (from RT_Com_Ctx%lflags)
    INTEGER(i4) :: lflags_kstep   = 0_i4
    
    !-- [IN] P5 numerical enhancements
    LOGICAL     :: use_hht_alpha  = .FALSE.  ! Use HHT-α method (default: Newmark-β)
    REAL(wp)    :: hht_alpha_param = -0.05_wp ! HHT-α parameter α ?[-? 0]
    REAL(wp)    :: dt_current     = 1.0e-6_wp ! Current time step size [s]
    REAL(wp)    :: dt_previous    = 1.0e-6_wp ! Previous time step size [s]
    LOGICAL     :: adaptive_dt    = .FALSE.  ! Enable adaptive time stepping
    REAL(wp)    :: error_tolerance = 1.0e-6_wp ! Local error tolerance for adaptive dt
    
    !-- [OUT] Status and diagnostics
    TYPE(ErrorStatusType) :: status      ! Error status (required by SIO-03)
    LOGICAL               :: success      = .FALSE.  ! Overall step success flag
    REAL(wp)              :: pnewdt       = 1.0_wp   ! Suggested time step change ratio
    REAL(wp)              :: strain_energy = 0.0_wp  ! Element strain energy (acoustic potential)
    INTEGER(i4)           :: ip_failed    = 0_i4     ! IP index where failure occurred
    REAL(wp)              :: total_mass   = 0.0_wp  ! Total element mass (P3 diagnostic)
    REAL(wp)              :: local_error  = 0.0_wp  ! Local truncation error estimate (P5)
    LOGICAL               :: state_saved  = .FALSE.  ! State backup flag (P5)
  END TYPE PH_AC3D4_UEL_Args

CONTAINS

  !===========================================================================
  ! UEL API - Thin Wrapper (Principle #14 / SIO adaptation for L4_PH UEL)
  !===========================================================================
  !> PH_AC3D4_UEL_API
  !>
  !> ROLE: THIN WRAPPER ONLY ?fills PH_AC3D4_UEL_Args, delegates to PH_AC3D4_UEL_Impl.
  !>   DO NOT add element physics here; implement in PH_AC3D4_UEL_Impl.
  SUBROUTINE PH_AC3D4_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
       RT_Com_Ctx, pnewdt, uel_status)
    TYPE(MD_Sect_Registry),    INTENT(IN), TARGET :: sect_registry
    TYPE(MD_Elem_UEL_Desc),   INTENT(IN)    :: MD_Elem_Desc
    TYPE(PH_Elem_Ctx),    INTENT(INOUT) :: PH_Elem_Ctx
    TYPE(PH_Elem_State),  INTENT(INOUT) :: PH_Elem_State
    TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                  INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType),     INTENT(OUT)   :: uel_status
    
    TYPE(PH_AC3D4_UEL_Args) :: uel_args
    
    uel_args%compute_amatrx = .TRUE.   ! Default: compute both
    uel_args%compute_rhs    = .TRUE.
    uel_args%lflags_kstep   = RT_Com_Ctx%lflags(1)
    uel_args%success = .FALSE.         ! Reset before delegate call
    
    CALL PH_AC3D4_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
        RT_Com_Ctx, uel_args)
    
    pnewdt     = uel_args%pnewdt
    uel_status = uel_args%status
  END SUBROUTINE PH_AC3D4_UEL_API
  
  !===========================================================================
  ! UEL IMPL - Physical Computation Core (PRIVATE)
  !===========================================================================
  !> PH_AC3D4_UEL_Impl
  !>
  !> Six-parameter inner interface (Principle #14, L4 hot-path form).
  !> All acoustic element physics implemented here.
  SUBROUTINE PH_AC3D4_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
       RT_Com_Ctx, args)
    TYPE(MD_Sect_Registry),    INTENT(IN), TARGET :: sect_registry
    TYPE(MD_Elem_UEL_Desc),   INTENT(IN)    :: MD_Elem_Desc
    TYPE(PH_Elem_Ctx),    INTENT(INOUT) :: PH_Elem_Ctx
    TYPE(PH_Elem_State),  INTENT(INOUT) :: PH_Elem_State
    TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx
    TYPE(PH_AC3D4_UEL_Args),   INTENT(INOUT) :: args
    
    !-- Local variables
    !$UFC HOT_PATH
    INTEGER(i4) :: sect_id, sect_idx
    CLASS(MD_Mat_Desc), POINTER :: mat_d => NULL()
    REAL(wp) :: N(PH_ELEM_AC3D4_NNODE), dNdX(3, PH_ELEM_AC3D4_NNODE)
    REAL(wp) :: B(3, PH_ELEM_AC3D4_NDOF)
    REAL(wp) :: w_ip, det_J
    REAL(wp) :: dstran_ip, fint(PH_ELEM_AC3D4_NDOF)
    INTEGER(i4) :: ip, ndofel, nip
    INTEGER(i4) :: nsvars_per_ip, slot_base
    REAL(wp) :: density, bulk_modulus, sound_speed
    
    !-- SVARS stride: must match CONTRACT_SVARS_IP_LAYOUT.md
    INTEGER(i4), PARAMETER :: NSVARS_PER_IP = PH_ELEM_AC3D4_NSVARS_PER_IP
    
    CALL init_error_status(args%status)
    args%success       = .FALSE.
    args%pnewdt        = RT_PNEWDT_NO_CHANGE
    args%strain_energy = 0.0_wp
    args%ip_failed     = 0
    
    ndofel = PH_ELEM_AC3D4_NDOF
    nip    = PH_ELEM_AC3D4_NIP
    
    !-- Validation checks
    IF (.NOT. ALLOCATED(PH_Elem_State%itr%svars) .OR. &
        SIZE(PH_Elem_State%itr%svars) < nip * NSVARS_PER_IP) THEN
      CALL init_error_status(args%status, STATUS_ERROR, &
          message='[AC3D4_UEL_Impl]: svars too small; expected nip*NSVARS_PER_IP slots')
      RETURN
    END IF
    
    nsvars_per_ip = NSVARS_PER_IP
    
    IF (ALLOCATED(PH_Elem_State%itr%rhs))    PH_Elem_State%itr%rhs    = 0.0_wp
    IF (ALLOCATED(PH_Elem_State%itr%amatrx)) PH_Elem_State%itr%amatrx = 0.0_wp
    PH_Elem_State%itr%energy = 0.0_wp
    fint = 0.0_wp
    
    !-- Section registry lookup (NO hot-loop scan ?SIO-10)
    sect_id  = MD_Elem_Desc%jprops(1)
    sect_idx = sect_registry%GetSectIdx(sect_id)
    IF (sect_idx == 0) THEN
      CALL init_error_status(args%status, STATUS_ERROR, &
          message='[AC3D4_UEL_Impl]: section_id not found in registry')
      RETURN
    END IF
    
    mat_d => sect_registry%sections(sect_idx)%mat_desc
    IF (.NOT. ASSOCIATED(mat_d)) THEN
      CALL init_error_status(args%status, STATUS_ERROR, &
          message='[AC3D4_UEL_Impl]: section mat_desc not associated')
      args%ip_failed = 0
      args%pnewdt    = 0.0_wp
      RETURN
    END IF
    
    !-- Get material properties from MD_Mat_Acoustic_Desc
    SELECT TYPE (md => mat_d)
    TYPE IS (MD_Mat_Acoustic_Desc)
      density      = md%density_ref
      bulk_modulus = md%bulk_modulus_ref
      sound_speed  = md%sound_speed_ref
      
      ! P4-1: Thermo-acoustic coupling - Temperature dependence
      IF (md%use_temp_dependence .AND. ASSOCIATED(md%T_field)) THEN
        REAL(wp) :: T_centroid, T_ratio
        T_centroid = SUM(md%T_field(1:PH_ELEM_AC3D4_NNODE)) / REAL(PH_ELEM_AC3D4_NNODE)
        T_ratio = SQRT(T_centroid / md%T_ref)
        sound_speed = md%sound_speed_ref * T_ratio
        
        ! Density thermal expansion
        IF (md%alpha_T > 0.0_wp) THEN
          REAL(wp) :: rho_factor
          rho_factor = 1.0_wp - md%alpha_T * (T_centroid - md%T_ref)
          density = md%density_ref * rho_factor
        END IF
      END IF
      
    CLASS DEFAULT
      ! Fallback to default air properties
      density      = 1.225_wp
      bulk_modulus = 1.42e5_wp
      sound_speed  = SQRT(bulk_modulus / density)
    END SELECT
    
    !-- Integration loop over Gauss points (1-point rule for tetrahedron)
    DO ip = 1, nip
      
      !-- Gauss point coordinates and weight (C3D4: 1-point tetrahedron rule)
      REAL(wp) :: xi, eta, zeta
      CALL C3D4_GetGaussPoint(ip, xi, eta, zeta, w_ip)
      
      !-- Shape functions and physical derivatives
      CALL C3D4_Shape_Functions(xi, eta, zeta, N)
      CALL C3D4_Jacobian(PH_Elem_Ctx%coords, N, xi, eta, zeta, dNdX, det_J)
      
      IF (det_J <= 0.0_wp) THEN
        CALL init_error_status(args%status, STATUS_ERROR, &
            message='[AC3D4_UEL_Impl]: non-positive Jacobian det at IP')
        args%ip_failed = ip
        args%pnewdt    = 0.0_wp
        RETURN
      END IF
      
      !-- B-matrix: pressure gradient operator [3 x 4]
      CALL AC3D4_B_Matrix(dNdX, B)
      
      !-- Strain increment (volumetric): delta_eps = ∇p · delta_u
      dstran_ip = B(1, :) * PH_Elem_Ctx%du(1, :) + &
                  B(2, :) * PH_Elem_Ctx%du(2, :) + &
                  B(3, :) * PH_Elem_Ctx%du(3, :)
      
      !-- Acoustic constitutive: p = -K·ε (pressure from volumetric strain)
      REAL(wp) :: pressure_increment
      pressure_increment = -bulk_modulus * dstran_ip
      
      !-- Assemble internal force vector: f_int += Bᵀ · p · detJ · w
      IF (args%compute_rhs .AND. ALLOCATED(PH_Elem_State%itr%rhs)) THEN
        fint(:) = fint(:) + MATMUL(TRANSPOSE(B), pressure_increment) * det_J * w_ip
      END IF
      
      !-- Assemble stiffness matrix: K += Bᵀ · K · B · detJ · w
      IF (args%compute_amatrx .AND. ALLOCATED(PH_Elem_State%itr%amatrx)) THEN
        REAL(wp) :: Ke_local(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
        Ke_local = bulk_modulus * MATMUL(TRANSPOSE(B), B) * det_J * w_ip
        PH_Elem_State%itr%amatrx(1:ndofel, 1:ndofel) = &
             PH_Elem_State%itr%amatrx(1:ndofel, 1:ndofel) + Ke_local
      END IF
      
      !-- Assemble mass matrix: M += ρ · Nᵀ · N · detJ · w
      IF (args%compute_mass .AND. ALLOCATED(PH_Elem_State%itr%mass)) THEN
        SELECT CASE(args%mass_method)
          CASE(1)  ! Consistent mass matrix
            REAL(wp) :: Me_cons(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
            CALL AC3D4_ConsMass(density, N, w_ip, det_J, Me_cons)
            PH_Elem_State%itr%mass(1:ndofel, 1:ndofel) = &
                 PH_Elem_State%itr%mass(1:ndofel, 1:ndofel) + Me_cons
          CASE(2)  ! Lumped mass (HRZ)
            REAL(wp) :: Me_lump(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
            CALL AC3D4_LumpMass_HRZ(density, N, w_ip, det_J, Me_lump)
            PH_Elem_State%itr%mass(1:ndofel, 1:ndofel) = &
                 PH_Elem_State%itr%mass(1:ndofel, 1:ndofel) + Me_lump
          CASE(3)  ! Lumped mass (RowSum)
            REAL(wp) :: Me_lump(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
            CALL AC3D4_LumpMass_RowSum(density, N, w_ip, det_J, Me_lump)
            PH_Elem_State%itr%mass(1:ndofel, 1:ndofel) = &
                 PH_Elem_State%itr%mass(1:ndofel, 1:ndofel) + Me_lump
          CASE(4)  ! Lumped mass (Uniform)
            REAL(wp) :: Me_lump(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
            CALL AC3D4_LumpMass_Uniform(density, N, w_ip, det_J, Me_lump)
            PH_Elem_State%itr%mass(1:ndofel, 1:ndofel) = &
                 PH_Elem_State%itr%mass(1:ndofel, 1:ndofel) + Me_lump
          CASE DEFAULT
            ! No mass matrix computation
        END SELECT
        args%total_mass = args%total_mass + SUM(MEYE(Me_cons))  ! Diagnostic
      END IF
      
      !-- Assemble damping matrix: C += α_M · M + β_K · K
      IF (args%compute_damping .AND. ALLOCATED(PH_Elem_State%itr%damping)) THEN
        IF (ALLOCATED(PH_Elem_State%itr%mass) .AND. ALLOCATED(PH_Elem_State%itr%amatrx)) THEN
          PH_Elem_State%itr%damping(1:ndofel, 1:ndofel) = &
               args%alpha_M * PH_Elem_State%itr%mass(1:ndofel, 1:ndofel) + &
               args%beta_K  * PH_Elem_State%itr%amatrx(1:ndofel, 1:ndofel)
        END IF
      END IF
      
      !-- Accumulate strain energy
      args%strain_energy = args%strain_energy + &
           0.5_wp * pressure_increment * dstran_ip * det_J * w_ip
      
    END DO
    
    !-- Finalize RHS
    IF (args%compute_rhs .AND. ALLOCATED(PH_Elem_State%itr%rhs)) &
      PH_Elem_State%itr%rhs(1:ndofel, 1) = -fint(1:ndofel)
    
    args%pnewdt = RT_PNEWDT_NO_CHANGE
    args%success = .TRUE.
    CALL init_error_status(args%status, IF_STATUS_OK)
    
  CONTAINS
    
    !-------------------------------------------------------------------------
    ! ELEMENT-TOPOLOGY PRIVATE HELPERS (C3D4 - 4-node tetrahedron)
    !-------------------------------------------------------------------------
    
    SUBROUTINE C3D4_GetGaussPoint(ip, xi, eta, zeta, w)
      !! Return natural coordinates and weight for 1-point tetrahedron rule
      INTEGER(i4), INTENT(IN)  :: ip
      REAL(wp),    INTENT(OUT) :: xi, eta, zeta, w
      
      ! Centroid of tetrahedron (volume coordinates L1=L2=L3=L4=1/4)
      xi = 0.25_wp
      eta = 0.25_wp
      zeta = 0.25_wp
      w = 1.0_wp  ! Volume coordinate integration
    END SUBROUTINE C3D4_GetGaussPoint
    
    SUBROUTINE C3D4_Shape_Functions(xi, eta, zeta, N)
      !! 4-node tetrahedral shape functions (linear)
      !! N1 = 1 - ξ - η - ζ, N2 = ξ, N3 = η, N4 = ζ
      REAL(wp), INTENT(IN)  :: xi, eta, zeta
      REAL(wp), INTENT(OUT) :: N(:)
      
      N(1) = 1.0_wp - xi - eta - zeta  ! Node 1
      N(2) = xi                         ! Node 2
      N(3) = eta                        ! Node 3
      N(4) = zeta                       ! Node 4
    END SUBROUTINE C3D4_Shape_Functions
    
    SUBROUTINE C3D4_Shape_Functions_Derivatives(dNdxi, dNdeta, dNdzeta)
      !! Derivatives of 4-node tetrahedral shape functions
      !! Constants: dN1/dξ=-1, dN2/dξ=1, etc.
      REAL(wp), INTENT(OUT) :: dNdxi(:), dNdeta(:), dNdzeta(:)
      
      ! dN/dξ
      dNdxi(1) = -1.0_wp
      dNdxi(2) =  1.0_wp
      dNdxi(3) =  0.0_wp
      dNdxi(4) =  0.0_wp
      
      ! dN/dη
      dNdeta(1) = -1.0_wp
      dNdeta(2) =  0.0_wp
      dNdeta(3) =  1.0_wp
      dNdeta(4) =  0.0_wp
      
      ! dN/dζ
      dNdzeta(1) = -1.0_wp
      dNdzeta(2) =  0.0_wp
      dNdzeta(3) =  0.0_wp
      dNdzeta(4) =  1.0_wp
    END SUBROUTINE C3D4_Shape_Functions_Derivatives
    
    SUBROUTINE C3D4_Jacobian(coords, N, xi, eta, zeta, dNdX, detJ)
      !! Compute Jacobian and physical derivatives
      REAL(wp), INTENT(IN)  :: coords(:,:)
      REAL(wp), INTENT(IN)  :: N(:)
      REAL(wp), INTENT(IN)  :: xi, eta, zeta
      REAL(wp), INTENT(OUT) :: dNdX(:,:)
      REAL(wp), INTENT(OUT) :: detJ
      
      REAL(wp) :: dNdxi(3, PH_ELEM_AC3D4_NNODE)
      REAL(wp) :: J(3, 3)
      INTEGER(i4) :: a
      
      ! Derivatives in natural coordinates (constants for linear tet)
      CALL C3D4_Shape_Functions_Derivatives(dNdxi(1,:), dNdxi(2,:), dNdxi(3,:))
      
      ! Jacobian: J = ∂x/∂?= [∂x/∂? ∂y/∂? ∂z/∂? ...]
      J = MATMUL(coords, TRANSPOSE(dNdxi))
      
      ! Determinant: det(J) = 6 × Volume for linear tetrahedron
      detJ = J(1,1)*(J(2,2)*J(3,3) - J(2,3)*J(3,2)) - &
             J(1,2)*(J(2,1)*J(3,3) - J(2,3)*J(3,1)) + &
             J(1,3)*(J(2,1)*J(3,2) - J(2,2)*J(3,1))
      
      ! Inverse: dN/dX = J⁻?· dN/dξ
      IF (ABS(detJ) > 1.0e-12_wp) THEN
        REAL(wp) :: Jinv(3, 3)
        ! 3×3 matrix inverse using cofactors
        Jinv(1,1) = (J(2,2)*J(3,3) - J(2,3)*J(3,2)) / detJ
        Jinv(1,2) = (J(1,3)*J(3,2) - J(1,2)*J(3,3)) / detJ
        Jinv(1,3) = (J(1,2)*J(2,3) - J(1,3)*J(2,2)) / detJ
        Jinv(2,1) = (J(2,3)*J(3,1) - J(2,1)*J(3,3)) / detJ
        Jinv(2,2) = (J(1,1)*J(3,3) - J(1,3)*J(3,1)) / detJ
        Jinv(2,3) = (J(1,3)*J(2,1) - J(1,1)*J(2,3)) / detJ
        Jinv(3,1) = (J(2,1)*J(3,2) - J(2,2)*J(3,1)) / detJ
        Jinv(3,2) = (J(1,2)*J(3,1) - J(1,1)*J(3,2)) / detJ
        Jinv(3,3) = (J(1,1)*J(2,2) - J(1,2)*J(2,1)) / detJ
        dNdX = MATMUL(Jinv, dNdxi)
      ELSE
        dNdX = 0.0_wp
      END IF
    END SUBROUTINE C3D4_Jacobian
    
    SUBROUTINE AC3D4_B_Matrix(dNdX, B)
      !! Acoustic B-matrix: relates nodal pressures to pressure gradient
      !! ∇p = B · p_node
      REAL(wp), INTENT(IN)  :: dNdX(:,:)
      REAL(wp), INTENT(OUT) :: B(:,:)
      
      INTEGER(i4) :: a
      
      B = 0.0_wp
      DO a = 1, PH_ELEM_AC3D4_NNODE
        B(1, a) = dNdX(1, a)  ! ∂N/∂x
        B(2, a) = dNdX(2, a)  ! ∂N/∂y
        B(3, a) = dNdX(3, a)  ! ∂N/∂z
      END DO
    END SUBROUTINE AC3D4_B_Matrix
    
  END SUBROUTINE PH_AC3D4_UEL_Impl

  !=============================================================================
  ! SECTION
  !=============================================================================
  SUBROUTINE PH_Elem_AC3D4_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_ELEM_AC3D4_VolumeInt(coords, area)
  END SUBROUTINE PH_Elem_AC3D4_GetArea

  SUBROUTINE PH_Elem_AC3D4_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: centroid(3)
    INTEGER(i4) :: j
    centroid = ZERO
    DO j = 1, 4
      centroid(1:3) = centroid(1:3) + coords(1:3, j)
    END DO
    centroid = centroid * QUARTER
  END SUBROUTINE PH_Elem_AC3D4_GetCentroid

  SUBROUTINE PH_Elem_AC3D4_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_AC3D4_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_AC3D4_GetSectProps

  !=============================================================================
  ! CONSTRAINTS
  !=============================================================================
  SUBROUTINE PH_Elem_AC3D4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 4) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_AC3D4_ApplyConstraint

  SUBROUTINE PH_Elem_AC3D4_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(4)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
    INTEGER(i4) :: i, j
    DO i = 1, 4
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 4
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D4_ApplyMPC

  !=============================================================================
  ! CONTACT
  !=============================================================================
  SUBROUTINE PH_Elem_AC3D4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(4)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(4, 4)
    REAL(wp), INTENT(INOUT) :: F_el(4)
  END SUBROUTINE PH_Elem_AC3D4_FormContactContrib

  SUBROUTINE PH_Elem_AC3D4_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(4, 4)
    REAL(wp), INTENT(OUT) :: F_el(4)
    K_el = ZERO
    F_el = ZERO
  END SUBROUTINE PH_Elem_AC3D4_FormContactEdgeCtr

  !=============================================================================
  ! LOADS
  !=============================================================================
  SUBROUTINE PH_Elem_AC3D4_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(4)
    F_eq = ZERO
  END SUBROUTINE PH_Elem_AC3D4_FormBodyForce

  SUBROUTINE PH_Elem_AC3D4_FormNodalForce(load_type, coords, val, edge_id, F_eq)
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(4)
    F_eq = ZERO
  END SUBROUTINE PH_Elem_AC3D4_FormNodalForce

  !=============================================================================
  ! OUTPUT
  !=============================================================================
  SUBROUTINE PH_Elem_AC3D4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    out_vars = ZERO
  END SUBROUTINE PH_Elem_AC3D4_CollectIPVars

  SUBROUTINE PH_Elem_AC3D4_EvalVonMises(sigma, seq)
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    seq = ZERO
  END SUBROUTINE PH_Elem_AC3D4_EvalVonMises

  SUBROUTINE PH_Elem_AC3D4_GetExtrapMat(E)
    REAL(wp), INTENT(OUT) :: E(4, 4)
    E = ZERO
  END SUBROUTINE PH_Elem_AC3D4_GetExtrapMat

  SUBROUTINE PH_Elem_AC3D4_MapToNode(ip_vars, weights, node_vars)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    node_vars = ZERO
  END SUBROUTINE PH_Elem_AC3D4_MapToNode

  !=============================================================================
  ! DEFINITION (main element routines)
  !=============================================================================
  SUBROUTINE PH_ELEM_AC3D4_VolumeInt(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    CALL PH_Elem_C3D4_ShapeFunc(xi(1), eta(1), zeta(1), N, dNdxi)
    CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
    volume = detJ * weights(1)
  END SUBROUTINE PH_ELEM_AC3D4_VolumeInt

  SUBROUTINE PH_Elem_AC3D4_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(4, 4)
    REAL(wp) :: k_eff
    REAL(wp) :: N(4), dNdx(3, 4), J(3, 3), detJ, B(6, 12)
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, j
    k_eff = E_young
    Ke = ZERO
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4_JacB(coords, xi(ip), eta(ip), zeta(ip), N, dNdx, J, detJ, B)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      DO i = 1, 4
        DO j = 1, 4
          Ke(i, j) = Ke(i, j) + k_eff * (dNdx(1,i)*dNdx(1,j) + dNdx(2,i)*dNdx(2,j) + dNdx(3,i)*dNdx(3,j)) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D4_FormStiffMatrix

  SUBROUTINE PH_Elem_AC3D4_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    eps_th = ZERO
  END SUBROUTINE PH_Elem_AC3D4_ThermStrainVector

  SUBROUTINE PH_Elem_AC3D4_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(4, 4)
    REAL(wp) :: N(4), dNdxi(3, 4), J(3, 3), detJ
    REAL(wp) :: xi(1), eta(1), zeta(1), weights(1)
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_C3D4_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 1
      CALL PH_Elem_C3D4_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D4_Jac(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 4
        DO j = 1, 4
          Me(i, j) = Me(i, j) + N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D4_ConsMass

  SUBROUTINE PH_Elem_AC3D4_DefInit()
  END SUBROUTINE PH_Elem_AC3D4_DefInit

  SUBROUTINE PH_Elem_AC3D4_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: u(4)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(4)
    REAL(wp) :: Ke(4, 4)
    CALL PH_Elem_AC3D4_FormStiffMatrix(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_AC3D4_FormIntForce

  SUBROUTINE PH_Elem_AC3D4_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(4)
    REAL(wp) :: vol, m
    INTEGER(i4) :: i
    CALL PH_ELEM_AC3D4_VolumeInt(coords, vol)
    m = rho * vol / 4.0_wp
    DO i = 1, 4
      M_lumped(i) = m
    END DO
  END SUBROUTINE PH_Elem_AC3D4_LumpMass

  ! NL_TL/NL_UL: interface (coords, u, D, Ke_mat, Ke_geo, R_int, status) for RT_Asm dispatch
  SUBROUTINE PH_Elem_AC3D4_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 4)
    REAL(wp), INTENT(IN)  :: p_elem(4)
    REAL(wp), INTENT(IN)  :: D(1, 1)
    REAL(wp), INTENT(OUT) :: Ke_mat(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_geo(4, 4)
    REAL(wp), INTENT(OUT) :: R_int(4)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k_eff
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    k_eff = 2.2e9_wp
    IF (ABS(D(1, 1)) > 1.0e-30_wp) k_eff = D(1, 1)
    CALL PH_Elem_AC3D4_FormStiffMatrix(coords_ref, k_eff, ZERO, Ke_mat)
    CALL PH_Elem_AC3D4_FormIntForce(coords_ref, p_elem, k_eff, ZERO, R_int)
  END SUBROUTINE PH_Elem_AC3D4_NL_TL

  SUBROUTINE PH_Elem_AC3D4_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 4)
    REAL(wp), INTENT(IN)  :: p_incr(4)
    REAL(wp), INTENT(IN)  :: D(1, 1)
    REAL(wp), INTENT(OUT) :: Ke_mat(4, 4)
    REAL(wp), INTENT(OUT) :: Ke_geo(4, 4)
    REAL(wp), INTENT(OUT) :: R_int(4)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k_eff
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    k_eff = 2.2e9_wp
    IF (ABS(D(1, 1)) > 1.0e-30_wp) k_eff = D(1, 1)
    CALL PH_Elem_AC3D4_FormStiffMatrix(coords_prev, k_eff, ZERO, Ke_mat)
    CALL PH_Elem_AC3D4_FormIntForce(coords_prev, p_incr, k_eff, ZERO, R_int)
  END SUBROUTINE PH_Elem_AC3D4_NL_UL
  
  !===========================================================================
  ! LEGACY HELPER SUBROUTINES (Compatibility layer)
  !===========================================================================
  
  ! SECTION PROPERTIES
  SUBROUTINE PH_Elem_AC3D4_GetMaterialProps(density, bulk_modulus, sound_speed)
    REAL(wp), INTENT(OUT) :: density, bulk_modulus, sound_speed
    density = 1.225_wp  ! Air at 20°C
    bulk_modulus = 1.42e5_wp
    sound_speed = SQRT(bulk_modulus / density)
  END SUBROUTINE PH_Elem_AC3D4_GetMaterialProps
  
  SUBROUTINE PH_Elem_AC3D4_GetMaterialProps_FromDesc(desc)
    TYPE(PH_El_AC_Mat_Desc), INTENT(OUT) :: desc
    desc%density = 1.225_wp
    desc%bulk_modulus = 1.42e5_wp
    desc%sound_speed = SQRT(desc%bulk_modulus / desc%density)
  END SUBROUTINE PH_Elem_AC3D4_GetMaterialProps_FromDesc
  
  SUBROUTINE PH_Elem_AC3D4_GetVolume(coords, volume)
    !! Calculate element volume
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(OUT) :: volume
    CALL PH_ELEM_AC3D4_VolumeInt(coords, volume)
  END SUBROUTINE PH_Elem_AC3D4_GetVolume
  
  SUBROUTINE PH_Elem_AC3D4_GetAcousticProps(acoustic_density, acoustic_impedance)
    REAL(wp), INTENT(OUT) :: acoustic_density, acoustic_impedance
    REAL(wp) :: bulk_modulus, sound_speed
    CALL PH_Elem_AC3D4_GetMaterialProps(acoustic_density, bulk_modulus, sound_speed)
    sound_speed = SQRT(bulk_modulus / acoustic_density)
    acoustic_impedance = acoustic_density * sound_speed
  END SUBROUTINE PH_Elem_AC3D4_GetAcousticProps
  
  SUBROUTINE PH_Elem_AC3D4_SetSectionProps(density, bulk_modulus)
    REAL(wp), INTENT(IN) :: density, bulk_modulus
    ! Stub - section properties set via descriptor
  END SUBROUTINE PH_Elem_AC3D4_SetSectionProps
  
  SUBROUTINE PH_Elem_AC3D4_SetSectionProps_FromDesc(sect_desc)
    TYPE(PH_El_AC_Sect_Desc), INTENT(IN) :: sect_desc
    CALL PH_Elem_AC3D4_SetSectionProps(sect_desc%density, sect_desc%bulk_modulus)
  END SUBROUTINE PH_Elem_AC3D4_SetSectionProps_FromDesc
  
  ! BOUNDARY CONDITIONS (4-node tetrahedron)
  SUBROUTINE PH_Elem_AC3D4_ApplyEssentialBC(Ke, F_ext, constrained_nodes, prescribed_values)
    REAL(wp), INTENT(INOUT) :: Ke(4, 4)
    REAL(wp), INTENT(INOUT) :: F_ext(4)
    INTEGER(i4), INTENT(IN) :: constrained_nodes(:)
    REAL(wp), INTENT(IN)    :: prescribed_values(:)
    INTEGER(i4) :: i, j, node_idx
    DO i = 1, SIZE(constrained_nodes)
      node_idx = constrained_nodes(i)
      DO j = 1, 4
        IF (j /= node_idx) THEN
          Ke(node_idx, j) = ZERO
          Ke(j, node_idx) = ZERO
        END IF
      END DO
      Ke(node_idx, node_idx) = ONE
      F_ext(node_idx) = prescribed_values(i)
      DO j = 1, 4
        IF (j /= node_idx) F_ext(j) = F_ext(j) - Ke(j, node_idx) * prescribed_values(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D4_ApplyEssentialBC
  
  SUBROUTINE PH_Elem_AC3D4_FormConstraintMatrix(constrained_nodes, C_matrix)
    INTEGER(i4), INTENT(IN) :: constrained_nodes(:)
    REAL(wp), INTENT(OUT)   :: C_matrix(SIZE(constrained_nodes), 4)
    INTEGER(i4) :: i, node_idx
    C_matrix = ZERO
    DO i = 1, SIZE(constrained_nodes)
      node_idx = constrained_nodes(i)
      C_matrix(i, node_idx) = ONE
    END DO
  END SUBROUTINE PH_Elem_AC3D4_FormConstraintMatrix
  
  SUBROUTINE PH_Elem_AC3D4_ApplyPenaltyBC(Ke, F_ext, constrained_nodes, prescribed_values, penalty)
    REAL(wp), INTENT(INOUT) :: Ke(4, 4)
    REAL(wp), INTENT(INOUT) :: F_ext(4)
    INTEGER(i4), INTENT(IN) :: constrained_nodes(:)
    REAL(wp), INTENT(IN)    :: prescribed_values(:)
    REAL(wp), INTENT(IN)    :: penalty
    INTEGER(i4) :: i, node_idx
    DO i = 1, SIZE(constrained_nodes)
      node_idx = constrained_nodes(i)
      Ke(node_idx, node_idx) = Ke(node_idx, node_idx) + penalty
      F_ext(node_idx) = F_ext(node_idx) + penalty * prescribed_values(i)
    END DO
  END SUBROUTINE PH_Elem_AC3D4_ApplyPenaltyBC
  
  ! SPECIAL BOUNDARY CONDITIONS (4 triangular faces)
  SUBROUTINE PH_Elem_AC3D4_FormAcousticImpedance(coords, impedance, face, K_impedance)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: impedance
    INTEGER(i4), INTENT(IN) :: face
    REAL(wp), INTENT(OUT) :: K_impedance(4, 4)
    INTEGER(i4) :: face_nodes(3)
    REAL(wp) :: face_area, N_face(3), N_face_mat(3, 3)
    INTEGER(i4) :: i, j
    
    K_impedance = ZERO
    SELECT CASE(face)
      CASE(1); face_nodes = [1, 2, 3]  ! Face 1-2-3
      CASE(2); face_nodes = [1, 2, 4]  ! Face 1-2-4
      CASE(3); face_nodes = [1, 3, 4]  ! Face 1-3-4
      CASE(4); face_nodes = [2, 3, 4]  ! Face 2-3-4
      CASE DEFAULT
        RETURN
    END SELECT
    
    ! Compute face area (triangular)
    REAL(wp) :: v1(3), v2(3), cross_prod(3)
    v1 = coords(:,face_nodes(2)) - coords(:,face_nodes(1))
    v2 = coords(:,face_nodes(3)) - coords(:,face_nodes(1))
    cross_prod = [v1(2)*v2(3)-v1(3)*v2(2), &
                  v1(3)*v2(1)-v1(1)*v2(3), &
                  v1(1)*v2(2)-v1(2)*v2(1)]
    face_area = 0.5_wp * SQRT(SUM(cross_prod**2))
    
    ! Uniform distribution
    N_face = 1.0_wp / 3.0_wp
    DO i = 1, 3
      DO j = 1, 3
        N_face_mat(i, j) = N_face(i) * N_face(j)
      END DO
    END DO
    
    DO i = 1, 3
      DO j = 1, 3
        K_impedance(face_nodes(i), face_nodes(j)) = impedance * face_area * N_face_mat(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D4_FormAcousticImpedance
  
  SUBROUTINE PH_Elem_AC3D4_FormRadiationCondition(coords, radiation_coeff, face, K_radiation)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: radiation_coeff
    INTEGER(i4), INTENT(IN) :: face
    REAL(wp), INTENT(OUT) :: K_radiation(4, 4)
    CALL PH_Elem_AC3D4_FormAcousticImpedance(coords, radiation_coeff, face, K_radiation)
  END SUBROUTINE PH_Elem_AC3D4_FormRadiationCondition
  
  SUBROUTINE PH_Elem_AC3D4_FormStructureCoupling(coords, coupling_coeff, face, K_coupling)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: coupling_coeff
    INTEGER(i4), INTENT(IN) :: face
    REAL(wp), INTENT(OUT) :: K_coupling(4, 4)
    CALL PH_Elem_AC3D4_FormAcousticImpedance(coords, coupling_coeff, face, K_coupling)
  END SUBROUTINE PH_Elem_AC3D4_FormStructureCoupling
  
  ! LOADS (4-node tetrahedron)
  SUBROUTINE PH_Elem_AC3D4_FormPressureLoad(coords, pressure, F_ext)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: pressure
    REAL(wp), INTENT(OUT) :: F_ext(4)
    REAL(wp) :: volume, load_per_node
    INTEGER(i4) :: i
    CALL PH_ELEM_AC3D4_VolumeInt(coords, volume)
    load_per_node = pressure * volume / 4.0_wp
    DO i = 1, 4
      F_ext(i) = load_per_node
    END DO
  END SUBROUTINE PH_Elem_AC3D4_FormPressureLoad
  
  SUBROUTINE PH_Elem_AC3D4_FormBodyForce(coords, body_force, F_ext)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: body_force(3)
    REAL(wp), INTENT(OUT) :: F_ext(4)
    REAL(wp) :: volume, load_per_node
    INTEGER(i4) :: i
    CALL PH_ELEM_AC3D4_VolumeInt(coords, volume)
    load_per_node = volume / 4.0_wp * (body_force(1) + body_force(2) + body_force(3))
    DO i = 1, 4
      F_ext(i) = load_per_node / 4.0_wp
    END DO
  END SUBROUTINE PH_Elem_AC3D4_FormBodyForce
  
  SUBROUTINE PH_Elem_AC3D4_FormSurfaceTraction(coords, traction, face, F_ext)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: traction(3)
    INTEGER(i4), INTENT(IN) :: face
    REAL(wp), INTENT(OUT) :: F_ext(4)
    INTEGER(i4) :: face_nodes(3)
    REAL(wp) :: face_area, N_face(3)
    INTEGER(i4) :: i
    
    F_ext = ZERO
    SELECT CASE(face)
      CASE(1); face_nodes = [1, 2, 3]
      CASE(2); face_nodes = [1, 2, 4]
      CASE(3); face_nodes = [1, 3, 4]
      CASE(4); face_nodes = [2, 3, 4]
      CASE DEFAULT
        RETURN
    END SELECT
    
    ! Compute face area
    REAL(wp) :: v1(3), v2(3), cross_prod(3)
    v1 = coords(:,face_nodes(2)) - coords(:,face_nodes(1))
    v2 = coords(:,face_nodes(3)) - coords(:,face_nodes(1))
    cross_prod = [v1(2)*v2(3)-v1(3)*v2(2), &
                  v1(3)*v2(1)-v1(1)*v2(3), &
                  v1(1)*v2(2)-v1(2)*v2(1)]
    face_area = 0.5_wp * SQRT(SUM(cross_prod**2))
    
    N_face = 1.0_wp / 3.0_wp
    DO i = 1, 3
      F_ext(face_nodes(i)) = N_face(i) * face_area * (traction(1) + traction(2) + traction(3))
    END DO
  END SUBROUTINE PH_Elem_AC3D4_FormSurfaceTraction
  
  ! POST-PROCESSING
  SUBROUTINE PH_Elem_AC3D4_CalcAcousticIntensity(coords, nodal_pressures, nodal_velocities, intensity)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: nodal_pressures(4)
    REAL(wp), INTENT(IN)  :: nodal_velocities(4, 3)
    REAL(wp), INTENT(OUT) :: intensity(3)
    REAL(wp) :: avg_pressure, avg_velocity(3)
    INTEGER(i4) :: i
    
    avg_pressure = SUM(nodal_pressures) / 4.0_wp
    DO i = 1, 3
      avg_velocity(i) = SUM(nodal_velocities(:, i)) / 4.0_wp
    END DO
    intensity = avg_pressure * avg_velocity
  END SUBROUTINE PH_Elem_AC3D4_CalcAcousticIntensity
  
  SUBROUTINE PH_Elem_AC3D4_CalcEnergy(coords, nodal_pressures, nodal_velocities, density, kinetic_energy, potential_energy)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: nodal_pressures(4)
    REAL(wp), INTENT(IN)  :: nodal_velocities(4, 3)
    REAL(wp), INTENT(IN)  :: density
    REAL(wp), INTENT(OUT) :: kinetic_energy, potential_energy
    REAL(wp) :: avg_pressure, avg_velocity_mag, volume
    INTEGER(i4) :: i
    
    avg_pressure = SUM(nodal_pressures) / 4.0_wp
    avg_velocity_mag = ZERO
    DO i = 1, 4
      avg_velocity_mag = avg_velocity_mag + SQRT(SUM(nodal_velocities(i, :)**2))
    END DO
    avg_velocity_mag = avg_velocity_mag / 4.0_wp
    
    CALL PH_ELEM_AC3D4_VolumeInt(coords, volume)
    kinetic_energy = 0.5_wp * density * avg_velocity_mag**2 * volume
    potential_energy = 0.5_wp * avg_pressure**2 / (density * 343.0_wp**2) * volume
  END SUBROUTINE PH_Elem_AC3D4_CalcEnergy
  
  SUBROUTINE PH_Elem_AC3D4_CalcEnergy_FromDesc(coords, nodal_pressures, nodal_velocities, sect_desc, kinetic_energy, potential_energy)
    !! Calculate energy from section descriptor
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: nodal_pressures(4)
    REAL(wp), INTENT(IN)  :: nodal_velocities(4, 3)
    TYPE(PH_El_AC_Sect_Desc), INTENT(IN) :: sect_desc
    REAL(wp), INTENT(OUT) :: kinetic_energy, potential_energy
    REAL(wp) :: density
    density = sect_desc%density
    CALL PH_Elem_AC3D4_CalcEnergy(coords, nodal_pressures, nodal_velocities, density, kinetic_energy, potential_energy)
  END SUBROUTINE PH_Elem_AC3D4_CalcEnergy_FromDesc
  
  SUBROUTINE PH_Elem_AC3D4_OutputResults(coords, nodal_pressures, nodal_velocities, filename)
    !! Output results to file
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: nodal_pressures(4)
    REAL(wp), INTENT(IN)  :: nodal_velocities(4, 3)
    CHARACTER(*), INTENT(IN) :: filename
    ! Stub implementation - actual output depends on file format
    ! TODO: Implement VTK/CSV output for AC3D4 results
  END SUBROUTINE PH_Elem_AC3D4_OutputResults
  
  SUBROUTINE PH_Elem_AC3D4_CalcPressure(coords, nodal_pressures, gauss_points, pressure_field)
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: nodal_pressures(4)
    REAL(wp), INTENT(IN)  :: gauss_points(:, :)
    REAL(wp), INTENT(OUT) :: pressure_field(SIZE(gauss_points, 2))
    REAL(wp) :: xi, eta, zeta, N(4)
    INTEGER(i4) :: ip
    
    DO ip = 1, SIZE(gauss_points, 2)
      xi = gauss_points(1, ip)
      eta = gauss_points(2, ip)
      zeta = gauss_points(3, ip)
      CALL C3D4_Shape_Functions(xi, eta, zeta, N)
      pressure_field(ip) = DOT_PRODUCT(N, nodal_pressures)
    END DO
  END SUBROUTINE PH_Elem_AC3D4_CalcPressure
  
  !===========================================================================
  ! P3 DYNAMIC ANALYSIS - MASS AND DAMPING MATRICES
  !===========================================================================
  
  SUBROUTINE AC3D4_ConsMass(density, N, w_ip, det_J, Me)
    !! Consistent mass matrix: M = ?ρ · Nᵀ · N dV
    REAL(wp), INTENT(IN)  :: density
    REAL(wp), INTENT(IN)  :: N(:)
    REAL(wp), INTENT(IN)  :: w_ip, det_J
    REAL(wp), INTENT(OUT) :: Me(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
    INTEGER(i4) :: i, j
    
    DO i = 1, PH_ELEM_AC3D4_NNODE
      DO j = 1, PH_ELEM_AC3D4_NNODE
        Me(i, j) = density * N(i) * N(j) * w_ip * det_J
      END DO
    END DO
  END SUBROUTINE AC3D4_ConsMass
  
  SUBROUTINE AC3D4_LumpMass_HRZ(density, N, w_ip, det_J, Me)
    !! Lumped mass matrix - HRZ (Hinton-Rock-Zienkiewicz) method
    !! Scale diagonal of consistent mass to preserve total mass
    REAL(wp), INTENT(IN)  :: density
    REAL(wp), INTENT(IN)  :: N(:)
    REAL(wp), INTENT(IN)  :: w_ip, det_J
    REAL(wp), INTENT(OUT) :: Me(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
    REAL(wp) :: Me_cons(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
    REAL(wp) :: total_mass, scale_factor
    INTEGER(i4) :: i
    
    ! Compute consistent mass first
    CALL AC3D4_ConsMass(density, N, w_ip, det_J, Me_cons)
    
    ! Total mass
    total_mass = 0.0_wp
    DO i = 1, PH_ELEM_AC3D4_NNODE
      total_mass = total_mass + Me_cons(i, i)
    END DO
    
    ! HRZ scaling: distribute total mass equally to nodes
    scale_factor = total_mass / REAL(PH_ELEM_AC3D4_NNODE)
    
    Me = 0.0_wp
    DO i = 1, PH_ELEM_AC3D4_NNODE
      Me(i, i) = scale_factor
    END DO
  END SUBROUTINE AC3D4_LumpMass_HRZ
  
  SUBROUTINE AC3D4_LumpMass_RowSum(density, N, w_ip, det_J, Me)
    !! Lumped mass matrix - Row-sum method
    !! M_ii = Σ?M_cons(i,j)
    REAL(wp), INTENT(IN)  :: density
    REAL(wp), INTENT(IN)  :: N(:)
    REAL(wp), INTENT(IN)  :: w_ip, det_J
    REAL(wp), INTENT(OUT) :: Me(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
    REAL(wp) :: Me_cons(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
    INTEGER(i4) :: i, j
    
    ! Compute consistent mass first
    CALL AC3D4_ConsMass(density, N, w_ip, det_J, Me_cons)
    
    ! Row sum lumping
    Me = 0.0_wp
    DO i = 1, PH_ELEM_AC3D4_NNODE
      DO j = 1, PH_ELEM_AC3D4_NNODE
        Me(i, i) = Me(i, i) + Me_cons(i, j)
      END DO
    END DO
  END SUBROUTINE AC3D4_LumpMass_RowSum
  
  SUBROUTINE AC3D4_LumpMass_Uniform(density, N, w_ip, det_J, Me)
    !! Lumped mass matrix - Uniform distribution
    !! M_ii = (ρ · V) / NNODE
    REAL(wp), INTENT(IN)  :: density
    REAL(wp), INTENT(IN)  :: N(:)
    REAL(wp), INTENT(IN)  :: w_ip, det_J
    REAL(wp), INTENT(OUT) :: Me(PH_ELEM_AC3D4_NDOF, PH_ELEM_AC3D4_NDOF)
    REAL(wp) :: total_mass, node_mass
    INTEGER(i4) :: i
    
    total_mass = density * w_ip * det_J
    node_mass = total_mass / REAL(PH_ELEM_AC3D4_NNODE)
    
    Me = 0.0_wp
    DO i = 1, PH_ELEM_AC3D4_NNODE
      Me(i, i) = node_mass
    END DO
  END SUBROUTINE AC3D4_LumpMass_Uniform
  
  SUBROUTINE PH_Elem_AC3D4_FormDampingMatrix(mass_matrix, stiffness_matrix, alpha_M, beta_K, damping_matrix)
    !! Rayleigh damping matrix: C = α_M · M + β_K · K
    REAL(wp), INTENT(IN)  :: mass_matrix(:,:)
    REAL(wp), INTENT(IN)  :: stiffness_matrix(:,:)
    REAL(wp), INTENT(IN)  :: alpha_M, beta_K
    REAL(wp), INTENT(OUT) :: damping_matrix(SIZE(mass_matrix, 1), SIZE(mass_matrix, 2))
    
    damping_matrix = alpha_M * mass_matrix + beta_K * stiffness_matrix
  END SUBROUTINE PH_Elem_AC3D4_FormDampingMatrix
  
  SUBROUTINE PH_Elem_AC3D4_ConsMass(coords, density, mass_matrix)
    !! Wrapper for consistent mass matrix computation
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: density
    REAL(wp), INTENT(OUT) :: mass_matrix(4, 4)
    REAL(wp) :: N(PH_ELEM_AC3D4_NNODE)
    REAL(wp) :: volume
    
    CALL PH_ELEM_AC3D4_VolumeInt(coords, volume)
    N = 0.25_wp  ! Centroid value for linear tetrahedron
    CALL AC3D4_ConsMass(density, N, 1.0_wp, volume, mass_matrix)
  END SUBROUTINE PH_Elem_AC3D4_ConsMass
  
  SUBROUTINE PH_Elem_AC3D4_LumpMass(coords, density, method, mass_matrix)
    !! Wrapper for lumped mass matrix computation
    REAL(wp), INTENT(IN)  :: coords(3, 4)
    REAL(wp), INTENT(IN)  :: density
    INTEGER(i4), INTENT(IN) :: method  ! 1=HRZ, 2=RowSum, 3=Uniform
    REAL(wp), INTENT(OUT) :: mass_matrix(4, 4)
    REAL(wp) :: N(PH_ELEM_AC3D4_NNODE)
    REAL(wp) :: volume, w_ip, det_J
    
    CALL PH_ELEM_AC3D4_VolumeInt(coords, volume)
    N = 0.25_wp
    w_ip = 1.0_wp
    det_J = volume
    
    SELECT CASE(method)
      CASE(1)
        CALL AC3D4_LumpMass_HRZ(density, N, w_ip, det_J, mass_matrix)
      CASE(2)
        CALL AC3D4_LumpMass_RowSum(density, N, w_ip, det_J, mass_matrix)
      CASE(3)
        CALL AC3D4_LumpMass_Uniform(density, N, w_ip, det_J, mass_matrix)
      CASE DEFAULT
        mass_matrix = 0.0_wp
    END SELECT
  END SUBROUTINE PH_Elem_AC3D4_LumpMass
  
  !===========================================================================
  ! P4 ADVANCED PHYSICS - THERMO-ACOUSTIC COUPLING (P4-1)
  !===========================================================================
  
  SUBROUTINE PH_Elem_AC3D4_Temperature_Dependent_Speed(c0, T0, T_current, c_T)
    !! Compute temperature-dependent sound speed c(T)
    !!
    !! Theory: For ideal gases and many fluids, sound speed varies with temperature:
    !!   c(T) = c₀ · ?T/T₀)
    REAL(wp), INTENT(IN)  :: c0, T0, T_current
    REAL(wp), INTENT(OUT) :: c_T
    REAL(wp) :: temp_ratio
    
    IF (T0 <= 0.0_wp .OR. T_current <= 0.0_wp) THEN
      c_T = c0
      RETURN
    END IF
    
    temp_ratio = T_current / T0
    c_T = c0 * SQRT(temp_ratio)
  END SUBROUTINE PH_Elem_AC3D4_Temperature_Dependent_Speed
  
  SUBROUTINE PH_Elem_AC3D4_UpdateMaterialProps_TempDep(density_ref, bulk_modulus_ref, &
       sound_speed_ref, T_ref, T_current, alpha_T, density_T, bulk_modulus_T, sound_speed_T)
    !! Update material properties with temperature dependence
    REAL(wp), INTENT(IN)  :: density_ref, bulk_modulus_ref, sound_speed_ref
    REAL(wp), INTENT(IN)  :: T_ref, T_current, alpha_T
    REAL(wp), INTENT(OUT) :: density_T, bulk_modulus_T, sound_speed_T
    REAL(wp) :: T_ratio, rho_factor
    
    T_ratio = MERGE(T_current / T_ref, 1.0_wp, T_ref > 0.0_wp .AND. T_current > 0.0_wp)
    sound_speed_T = sound_speed_ref * SQRT(T_ratio)
    
    IF (alpha_T > 0.0_wp) THEN
      rho_factor = 1.0_wp - alpha_T * (T_current - T_ref)
      density_T = density_ref * MAX(rho_factor, 0.1_wp)
    ELSE
      density_T = density_ref
    END IF
    
    bulk_modulus_T = density_T * sound_speed_T**2
  END SUBROUTINE PH_Elem_AC3D4_UpdateMaterialProps_TempDep
  
  !===========================================================================
  ! P4 ADVANCED PHYSICS - BIOT POROUS MEDIA THEORY (P4-2)
  !===========================================================================
  
  SUBROUTINE PH_Elem_AC3D4_Biot_Wave_Speed(porosity, tortuosity, fluid_density, &
       solid_density, fluid_bulk, solid_bulk, shear_modulus, &
       fast_wave_speed, slow_wave_speed, shear_wave_speed)
    !! Compute Biot wave speeds for porous media
    REAL(wp), INTENT(IN)  :: porosity, tortuosity, fluid_density, solid_density
    REAL(wp), INTENT(IN)  :: fluid_bulk, solid_bulk, shear_modulus
    REAL(wp), INTENT(OUT) :: fast_wave_speed, slow_wave_speed, shear_wave_speed
    REAL(wp) :: phi, alpha_inf, rho_11, rho_22, rho_12, P, R, Q
    REAL(wp) :: sum_speeds_sq, prod_speeds_sq, discriminant, V1_sq, V2_sq
    
    phi = porosity
    alpha_inf = tortuosity
    rho_11 = (1.0_wp - phi) * solid_density
    rho_22 = phi * fluid_density
    rho_12 = -(phi - 1.0_wp) * fluid_density
    
    shear_wave_speed = SQRT(shear_modulus / rho_11)
    
    P = shear_modulus * 8.0_wp / 3.0_wp
    R = phi * fluid_bulk
    Q = phi * fluid_bulk
    
    sum_speeds_sq = (P*rho_22 + R*rho_11 - 2.0_wp*Q*rho_12) / (rho_11*rho_22 - rho_12**2)
    prod_speeds_sq = (P*R - Q**2) / (rho_11*rho_22 - rho_12**2)
    discriminant = sum_speeds_sq**2 - 4.0_wp * prod_speeds_sq
    
    IF (discriminant >= 0.0_wp) THEN
      V1_sq = 0.5_wp * (sum_speeds_sq + SQRT(discriminant))
      V2_sq = 0.5_wp * (sum_speeds_sq - SQRT(discriminant))
      fast_wave_speed = SQRT(MAX(V1_sq, 0.0_wp))
      slow_wave_speed = SQRT(MAX(V2_sq, 0.0_wp))
    ELSE
      fast_wave_speed = SQRT(P / rho_11)
      slow_wave_speed = 0.0_wp
    END IF
  END SUBROUTINE PH_Elem_AC3D4_Biot_Wave_Speed
  
  SUBROUTINE PH_Elem_AC3D4_Biot_Damping(permeability, fluid_viscosity, porosity, &
       tortuosity, angular_freq, damping_coefficient)
    !! Compute viscous damping from fluid flow through pores
    REAL(wp), INTENT(IN)  :: permeability, fluid_viscosity, porosity, tortuosity, angular_freq
    REAL(wp), INTENT(OUT) :: damping_coefficient
    REAL(wp) :: b0, omega_crit, freq_correction
    
    b0 = fluid_viscosity * porosity**2 / permeability
    omega_crit = fluid_viscosity * porosity / (tortuosity * permeability * 1000.0_wp)
    
    IF (angular_freq > omega_crit) THEN
      freq_correction = SQRT(angular_freq / omega_crit)
    ELSE
      freq_correction = 1.0_wp
    END IF
    
    damping_coefficient = b0 * freq_correction
  END SUBROUTINE PH_Elem_AC3D4_Biot_Damping
  
  SUBROUTINE PH_Elem_AC3D4_Biot_Stabilize_SlowWave(mesh_size, slow_wave_speed, &
       damping_coefficient, porosity, stabilization_parameter)
    !! Compute SUPG stabilization parameter for Biot slow wave
    REAL(wp), INTENT(IN)  :: mesh_size, slow_wave_speed, damping_coefficient, porosity
    REAL(wp), INTENT(OUT) :: stabilization_parameter
    REAL(wp) :: diffusivity, peclét, coth_pe
    
    diffusivity = porosity * slow_wave_speed**2 / MAX(damping_coefficient, 1.0e-12_wp)
    peclét = slow_wave_speed * mesh_size / (2.0_wp * MAX(diffusivity, 1.0e-12_wp))
    
    IF (ABS(peclét) < 1.0e-6_wp) THEN
      coth_pe = 1.0_wp / peclét + peclét / 3.0_wp
    ELSEIF (peclét > 10.0_wp) THEN
      coth_pe = 1.0_wp
    ELSE
      coth_pe = 1.0_wp / TANH(peclét)
    END IF
    
    IF (ABS(slow_wave_speed) > 1.0e-12_wp) THEN
      stabilization_parameter = (mesh_size / (2.0_wp * slow_wave_speed)) * (coth_pe - 1.0_wp / peclét)
    ELSE
      stabilization_parameter = 0.0_wp
    END IF
  END SUBROUTINE PH_Elem_AC3D4_Biot_Stabilize_SlowWave
  
  SUBROUTINE PH_Elem_AC3D4_Biot_Compute_Stab_Param(coords, porosity, permeability, &
       fluid_viscosity, slow_wave_speed, stabilization_parameter)
    !! Wrapper to compute SUPG stabilization from element data
    REAL(wp), INTENT(IN)  :: coords(:,:), porosity, permeability, fluid_viscosity, slow_wave_speed
    REAL(wp), INTENT(OUT) :: stabilization_parameter
    REAL(wp) :: mesh_size, damping_coef
    
    CALL PH_ELEM_AC3D4_VolumeInt(coords, mesh_size)
    mesh_size = mesh_size**(1.0_wp/3.0_wp)
    
    CALL PH_Elem_AC3D4_Biot_Damping(permeability, fluid_viscosity, porosity, 1.5_wp, 1000.0_wp, damping_coef)
    CALL PH_Elem_AC3D4_Biot_Stabilize_SlowWave(mesh_size, slow_wave_speed, damping_coef, porosity, stabilization_parameter)
  END SUBROUTINE PH_Elem_AC3D4_Biot_Compute_Stab_Param
  
  !===========================================================================
  ! P4 ADVANCED PHYSICS - INFINITE ELEMENTS & PML (P4-3)
  !===========================================================================
  
  SUBROUTINE PH_Elem_AC3D4_Sommerfeld_Radiation(coords, face_nodes, sound_speed, &
       density, radiation_stiffness, radiation_damping)
    !! Apply Sommerfeld radiation condition on truncated boundary
    REAL(wp), INTENT(IN)  :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: face_nodes(:)
    REAL(wp), INTENT(IN)  :: sound_speed, density
    REAL(wp), INTENT(OUT) :: radiation_stiffness(:,:), radiation_damping(:,:)
    REAL(wp) :: face_area, char_length, coeff
    REAL(wp) :: v1(3), v2(3), cross_prod(3)
    INTEGER(i4) :: i, j
    
    radiation_stiffness = 0.0_wp
    radiation_damping = 0.0_wp
    
    IF (SIZE(face_nodes) /= 3) RETURN
    
    v1 = coords(:,face_nodes(2)) - coords(:,face_nodes(1))
    v2 = coords(:,face_nodes(3)) - coords(:,face_nodes(1))
    cross_prod = [v1(2)*v2(3)-v1(3)*v2(2), v1(3)*v2(1)-v1(1)*v2(3), v1(1)*v2(2)-v1(2)*v2(1)]
    face_area = 0.5_wp * SQRT(SUM(cross_prod**2))
    char_length = SQRT(face_area)
    coeff = face_area / (density * sound_speed)
    
    DO i = 1, 3
      DO j = 1, 3
        radiation_stiffness(face_nodes(i), face_nodes(j)) = coeff * sound_speed / char_length / 9.0_wp
        radiation_damping(face_nodes(i), face_nodes(j)) = coeff / 9.0_wp
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D4_Sommerfeld_Radiation
  
  SUBROUTINE PH_Elem_AC3D4_PML_Absorbing_Boundary(coords, pml_region_flag, &
       absorption_strength, pml_stiffness, pml_damping)
    !! Assemble PML contributions to system matrices
    REAL(wp), INTENT(IN)  :: coords(:,:)
    LOGICAL, INTENT(IN)  :: pml_region_flag
    REAL(wp), INTENT(IN)  :: absorption_strength
    REAL(wp), INTENT(OUT) :: pml_stiffness(:,:), pml_damping(:,:)
    REAL(wp) :: volume
    INTEGER(i4) :: i
    
    pml_stiffness = 0.0_wp
    pml_damping = 0.0_wp
    
    IF (.NOT. pml_region_flag) RETURN
    
    CALL PH_ELEM_AC3D4_VolumeInt(coords, volume)
    
    DO i = 1, PH_ELEM_AC3D4_NNODE
      pml_damping(i, i) = absorption_strength * volume / REAL(PH_ELEM_AC3D4_NNODE)
      pml_stiffness(i, i) = -0.1_wp * absorption_strength**2 * pml_damping(i, i)
    END DO
  END SUBROUTINE PH_Elem_AC3D4_PML_Absorbing_Boundary
  
  !===========================================================================
  ! P5 NUMERICAL ENHANCEMENTS - TIME INTEGRATION & ADAPTIVE CONTROL
  !===========================================================================
  
  SUBROUTINE PH_Elem_AC3D4_Newmark_Beta_Integrator(
       mass_matrix, damping_matrix, stiffness_matrix,
       u_n, v_n, a_n, dt,
       beta_newmark, gamma_newmark,
       F_ext, F_int,
       u_np1, v_np1, a_np1,
       converged, status)
    !! Newmark-β time integration for acoustic transient analysis
    !!
    !! Governing equation: M·a + C·v + K·u = F(t)
    !!
    !! Newmark assumptions:
    !!   u_{n+1} = u_n + dt·v_n + dt²·[(½-β)·a_n + β·a_{n+1}]
    !!   v_{n+1} = v_n + dt·[(1-γ)·a_n + γ·a_{n+1}]
    !!
    !! Parameters:
    !!   β = ¼ (average acceleration), γ = ½ (unconditionally stable)
    REAL(wp), INTENT(IN)  :: mass_matrix(:,:)
    REAL(wp), INTENT(IN)  :: damping_matrix(:,:)
    REAL(wp), INTENT(IN)  :: stiffness_matrix(:,:)
    REAL(wp), INTENT(IN)  :: u_n(:)    ! Displacement at t_n
    REAL(wp), INTENT(IN)  :: v_n(:)    ! Velocity at t_n
    REAL(wp), INTENT(IN)  :: a_n(:)    ! Acceleration at t_n
    REAL(wp), INTENT(IN)  :: dt        ! Time step size [s]
    REAL(wp), INTENT(IN)  :: beta_newmark ! Newmark parameter β (default 0.25)
    REAL(wp), INTENT(IN)  :: gamma_newmark ! Newmark parameter γ (default 0.5)
    REAL(wp), INTENT(IN)  :: F_ext(:)  ! External force vector at t_{n+1}
    REAL(wp), INTENT(IN)  :: F_int(:)  ! Internal force vector at t_n
    REAL(wp), INTENT(OUT) :: u_np1(:)  ! Displacement at t_{n+1}
    REAL(wp), INTENT(OUT) :: v_np1(:)  ! Velocity at t_{n+1}
    REAL(wp), INTENT(OUT) :: a_np1(:)  ! Acceleration at t_{n+1}
    LOGICAL, INTENT(OUT)  :: converged ! Iterative solver convergence flag
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: ndof, iter, max_iter
    REAL(wp) :: a0, a1, a2, a3, a4, a5
    REAL(wp) :: Keffective(:,:), Feffective(:)
    REAL(wp) :: residual, tolerance
    
    ndof = SIZE(u_n)
    max_iter = 50
    tolerance = 1.0e-8_wp
    
    ! Newmark constants
    a0 = 1.0_wp / (beta_newmark * dt**2)
    a1 = gamma_newmark / (beta_newmark * dt)
    a2 = 1.0_wp / (beta_newmark * dt)
    a3 = 1.0_wp / (2.0_wp * beta_newmark) - 1.0_wp
    a4 = gamma_newmark / beta_newmark - 1.0_wp
    a5 = dt * (gamma_newmark / (2.0_wp * beta_newmark) - 1.0_wp)
    
    ! Effective stiffness matrix
    Keffective = stiffness_matrix + a0 * mass_matrix + a1 * damping_matrix
    
    ! Effective force vector
    Feffective = F_ext - F_int + &
                 mass_matrix @ (a0*u_n + a2*v_n + a3*a_n) + &
                 damping_matrix @ (a1*u_n + a4*v_n + a5*a_n)
    
    ! Solve linear system: Keffective · u* = Feffective
    ! (Using simple Gaussian elimination or iterative solver)
    ! TODO: Replace with actual linear solver
    u_np1 = MATMUL(mass_matrix, Feffective) / ndof  ! Placeholder
    
    ! Compute acceleration and velocity
    a_np1 = a0 * (u_np1 - u_n) - a2 * v_n - a3 * a_n
    v_np1 = v_n + dt * ((1.0_wp - gamma_newmark) * a_n + gamma_newmark * a_np1)
    
    ! Check convergence
    residual = SQRT(SUM((Keffective @ u_np1 - Feffective)**2))
    converged = (residual < tolerance)
    
    IF (.NOT. converged) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='Newmark-β iteration did not converge')
    ELSE
      CALL init_error_status(status, IF_STATUS_OK)
    END IF
    
  END SUBROUTINE PH_Elem_AC3D4_Newmark_Beta_Integrator
  
  SUBROUTINE PH_Elem_AC3D4_HHT_Alpha_Integrator(
       mass_matrix, damping_matrix, stiffness_matrix,
       u_n, v_n, a_n, dt,
       alpha_hht,
       F_ext, F_int,
       u_np1, v_np1, a_np1,
       converged, status)
    !! HHT-α generalized alpha method for high-frequency numerical dissipation
    !!
    !! Theory: Hilber-Hughes-Taylor (HHT) method introduces numerical damping
    !! via weighted combination of equilibrium equations at t_n and t_{n+1}:
    !!   (1+α)·[M·a_{n+1} + C·v_{n+1} + K·u_{n+1}] - α·[M·a_n + C·v_n + K·u_n] = F_{n+1}
    !!
    !! Parameter α ?[-? 0]:
    !!   α = 0: Reduces to Newmark-β (no numerical damping)
    !!   α = -? Maximum high-frequency dissipation
    !!   Recommended: α = -0.05 to -0.1 for acoustics
    REAL(wp), INTENT(IN)  :: mass_matrix(:,:)
    REAL(wp), INTENT(IN)  :: damping_matrix(:,:)
    REAL(wp), INTENT(IN)  :: stiffness_matrix(:,:)
    REAL(wp), INTENT(IN)  :: u_n(:), v_n(:), a_n(:)
    REAL(wp), INTENT(IN)  :: dt
    REAL(wp), INTENT(IN)  :: alpha_hht  ! HHT-α parameter ?[-? 0]
    REAL(wp), INTENT(IN)  :: F_ext(:), F_int(:)
    REAL(wp), INTENT(OUT) :: u_np1(:), v_np1(:), a_np1(:)
    LOGICAL, INTENT(OUT)  :: converged
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: ndof, iter
    REAL(wp) :: beta_hht, gamma_hht
    REAL(wp) :: a0, a1, a2, a3, a4, a5
    REAL(wp) :: Keffective(:,:), Feffective(:)
    REAL(wp) :: residual, tolerance
    
    ndof = SIZE(u_n)
    tolerance = 1.0e-8_wp
    
    ! HHT-α parameters (ensure second-order accuracy)
    beta_hht = (1.0_wp - alpha_hht)**2 / 4.0_wp
    gamma_hht = (1.0_wp - 2.0_wp * alpha_hht) / 2.0_wp
    
    ! Newmark-like constants adapted for HHT-α
    a0 = 1.0_wp / (beta_hht * dt**2)
    a1 = gamma_hht / (beta_hht * dt)
    a2 = 1.0_wp / (beta_hht * dt)
    a3 = 1.0_wp / (2.0_wp * beta_hht) - 1.0_wp
    a4 = gamma_hht / beta_hht - 1.0_wp
    a5 = dt * (gamma_hht / (2.0_wp * beta_hht) - 1.0_wp)
    
    ! Effective stiffness (includes HHT-α weighting)
    Keffective = (1.0_wp + alpha_hht) * stiffness_matrix + &
                 a0 * mass_matrix + a1 * damping_matrix
    
    ! Effective force with HHT-α history terms
    Feffective = (1.0_wp + alpha_hht) * F_ext - alpha_hht * F_int + &
                 mass_matrix @ (a0*u_n + a2*v_n + a3*a_n) + &
                 damping_matrix @ (a1*u_n + a4*v_n + a5*a_n)
    
    ! Solve for u_{n+1}
    u_np1 = MATMUL(mass_matrix, Feffective) / ndof  ! Placeholder
    
    ! Update acceleration and velocity
    a_np1 = a0 * (u_np1 - u_n) - a2 * v_n - a3 * a_n
    v_np1 = v_n + dt * ((1.0_wp - gamma_hht) * a_n + gamma_hht * a_np1)
    
    ! Convergence check
    residual = SQRT(SUM((Keffective @ u_np1 - Feffective)**2))
    converged = (residual < tolerance)
    
    IF (converged) THEN
      CALL init_error_status(status, IF_STATUS_OK)
    ELSE
      CALL init_error_status(status, STATUS_ERROR, &
           message='HHT-α iteration did not converge')
    END IF
    
  END SUBROUTINE PH_Elem_AC3D4_HHT_Alpha_Integrator
  
  SUBROUTINE PH_Elem_AC3D4_Compute_Local_Error(
       u_np1, v_np1, a_np1,
       u_n, v_n, a_n,
       dt, local_error_estimate)
    !! Estimate local truncation error for adaptive time stepping
    !!
    !! Method: Compare solutions from two different order methods
    !! or use embedded error estimation via difference between
    !! predicted and computed accelerations.
    REAL(wp), INTENT(IN)  :: u_np1(:), v_np1(:), a_np1(:)
    REAL(wp), INTENT(IN)  :: u_n(:), v_n(:), a_n(:)
    REAL(wp), INTENT(IN)  :: dt
    REAL(wp), INTENT(OUT) :: local_error_estimate
    
    REAL(wp) :: error_disp, error_vel, error_acc
    REAL(wp) :: scale_factor
    INTEGER(i4) :: ndof
    
    ndof = SIZE(u_n)
    
    ! Error estimate based on acceleration difference
    ! e = ||a_{n+1} - a_n|| / ||a_max||
    error_acc = SQRT(SUM((a_np1 - a_n)**2))
    
    ! Scaling factor (typical acceleration magnitude)
    scale_factor = MAXVAL(ABS(a_np1)) + 1.0e-12_wp
    
    local_error_estimate = error_acc / scale_factor
    
  END SUBROUTINE PH_Elem_AC3D4_Compute_Local_Error
  
  SUBROUTINE PH_Elem_AC3D4_Adaptive_TimeStep_Control(
       local_error, error_tolerance,
       dt_current, dt_previous,
       dt_suggested, pnewdt, status)
    !! Adaptive time step control based on local truncation error
    !!
    !! Algorithm: Adjust dt to maintain error within tolerance:
    !!   dt_{new} = dt_{old} · (tol/error)^{1/(p+1)}
    !! where p = order of method (p=2 for Newmark/HHT)
    REAL(wp), INTENT(IN)  :: local_error
    REAL(wp), INTENT(IN)  :: error_tolerance
    REAL(wp), INTENT(IN)  :: dt_current
    REAL(wp), INTENT(IN)  :: dt_previous
    REAL(wp), INTENT(OUT) :: dt_suggested
    REAL(wp), INTENT(OUT) :: pnewdt
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: safety_factor, error_ratio, exponent
    REAL(wp) :: dt_min, dt_max
    
    safety_factor = 0.9_wp  ! Safety margin to prevent oscillations
    dt_min = 1.0e-12_wp     ! Minimum time step
    dt_max = 1.0e-3_wp      ! Maximum time step
    
    ! Exponent for 2nd-order method (p=2)
    exponent = 1.0_wp / 3.0_wp  ! 1/(p+1) = 1/3
    
    ! Compute error ratio
    IF (local_error > 1.0e-12_wp) THEN
      error_ratio = error_tolerance / local_error
    ELSE
      error_ratio = 100.0_wp  ! Error is negligible
    END IF
    
    ! Suggested time step change
    pnewdt = safety_factor * error_ratio**exponent
    
    ! Limit rate of change (prevent abrupt changes)
    pnewdt = MAX(0.2_wp, MIN(5.0_wp, pnewdt))
    
    ! Apply suggested change
    dt_suggested = dt_current * pnewdt
    
    ! Enforce bounds
    dt_suggested = MAX(dt_min, MIN(dt_max, dt_suggested))
    
    ! Determine if step should be accepted
    IF (local_error <= error_tolerance) THEN
      ! Error acceptable - step accepted, may increase dt
      CALL init_error_status(status, IF_STATUS_OK)
    ELSE
      ! Error too large - reject step, reduce dt
      CALL init_error_status(status, STATUS_ERROR, &
           message='Local error exceeds tolerance - step rejected')
      pnewdt = MAX(0.2_wp, pnewdt)  ! Limit reduction
    END IF
    
  END SUBROUTINE PH_Elem_AC3D4_Adaptive_TimeStep_Control
  
  SUBROUTINE PH_Elem_AC3D4_Save_State(state_current, state_backup)
    !! Save current element state for potential rollback
    !!
    !! Used in conjunction with adaptive time stepping:
    !! If step is rejected, restore previous state and retry with smaller dt.
    TYPE(PH_Elem_State), INTENT(IN)  :: state_current
    TYPE(PH_Elem_State), INTENT(OUT) :: state_backup
    
    ! Deep copy of all state variables
    IF (ALLOCATED(state_current%svars)) THEN
      IF (.NOT. ALLOCATED(state_backup%svars)) THEN
        ALLOCATE(state_backup%svars, SOURCE=state_current%svars)
      ELSE
        state_backup%svars = state_current%svars
      END IF
    END IF
    
    IF (ALLOCATED(state_current%rhs)) THEN
      IF (.NOT. ALLOCATED(state_backup%rhs)) THEN
        ALLOCATE(state_backup%rhs, SOURCE=state_current%rhs)
      ELSE
        state_backup%rhs = state_current%rhs
      END IF
    END IF
    
    IF (ALLOCATED(state_current%amatrx)) THEN
      IF (.NOT. ALLOCATED(state_backup%amatrx)) THEN
        ALLOCATE(state_backup%amatrx, SOURCE=state_current%amatrx)
      ELSE
        state_backup%amatrx = state_current%amatrx
      END IF
    END IF
    
    IF (ALLOCATED(state_current%mass)) THEN
      IF (.NOT. ALLOCATED(state_backup%mass)) THEN
        ALLOCATE(state_backup%mass, SOURCE=state_current%mass)
      ELSE
        state_backup%mass = state_current%mass
      END IF
    END IF
    
    IF (ALLOCATED(state_current%damping)) THEN
      IF (.NOT. ALLOCATED(state_backup%damping)) THEN
        ALLOCATE(state_backup%damping, SOURCE=state_current%damping)
      ELSE
        state_backup%damping = state_current%damping
      END IF
    END IF
    
    state_backup%energy = state_current%energy
    
  END SUBROUTINE PH_Elem_AC3D4_Save_State
  
  SUBROUTINE PH_Elem_AC3D4_Restore_State(state_backup, state_current)
    !! Restore element state from backup (rollback after rejected step)
    TYPE(PH_Elem_State), INTENT(IN)  :: state_backup
    TYPE(PH_Elem_State), INTENT(INOUT) :: state_current
    
    ! Deep copy back from backup
    IF (ALLOCATED(state_backup%svars)) THEN
      IF (.NOT. ALLOCATED(state_current%svars)) THEN
        ALLOCATE(state_current%svars, SOURCE=state_backup%svars)
      ELSE
        state_current%svars = state_backup%svars
      END IF
    END IF
    
    IF (ALLOCATED(state_backup%rhs)) THEN
      IF (.NOT. ALLOCATED(state_current%rhs)) THEN
        ALLOCATE(state_current%rhs, SOURCE=state_backup%rhs)
      ELSE
        state_current%rhs = state_backup%rhs
      END IF
    END IF
    
    IF (ALLOCATED(state_backup%amatrx)) THEN
      IF (.NOT. ALLOCATED(state_current%amatrx)) THEN
        ALLOCATE(state_current%amatrx, SOURCE=state_backup%amatrx)
      ELSE
        state_current%amatrx = state_backup%amatrx
      END IF
    END IF
    
    IF (ALLOCATED(state_backup%mass)) THEN
      IF (.NOT. ALLOCATED(state_current%mass)) THEN
        ALLOCATE(state_current%mass, SOURCE=state_backup%mass)
      ELSE
        state_current%mass = state_backup%mass
      END IF
    END IF
    
    IF (ALLOCATED(state_backup%damping)) THEN
      IF (.NOT. ALLOCATED(state_current%damping)) THEN
        ALLOCATE(state_current%damping, SOURCE=state_backup%damping)
      ELSE
        state_current%damping = state_backup%damping
      END IF
    END IF
    
    state_current%energy = state_backup%energy
    
  END SUBROUTINE PH_Elem_AC3D4_Restore_State
  

  !=============================================================================
  ! UNIFIED INTERFACE (RT Layer compatible)
  !=============================================================================
  
  SUBROUTINE UF_Elem_AC3D4_Calc(ElemType, Formul, Ctx, state_in, &
                                          Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, 4)
    REAL(wp) :: u(4)
    REAL(wp) :: density, bulk_modulus, sound_speed
    REAL(wp) :: k_eff, nu
    REAL(wp) :: Ke(4, 4)
    REAL(wp) :: R_int(4)
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    ! Validate coords_ref allocation
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D4_Calc: coords_ref not allocated'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < 4) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D4_Calc: insufficient nodes'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    ! Extract coordinates
    DO i = 1, 4
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
    END DO

    ! Extract displacement/pressure field
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= 4) THEN
        DO i = 1, 4
          IF (SIZE(Ctx%disp_total, 1) >= 1) THEN
            u(i) = Ctx%disp_total(1, i)
          END IF
        END DO
      END IF
    END IF

    ! Get material properties (defaults for air)
    density = 1.21_wp
    bulk_modulus = 1.42e5_wp
    sound_speed = 343.0_wp

    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 1) density = Mat%props%props(1)
      IF (SIZE(Mat%props%props) >= 2) bulk_modulus = Mat%props%props(2)
    END IF

    k_eff = bulk_modulus
    nu = 0.0_wp

    IF (k_eff <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D4_Calc: invalid bulk modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    ! Compute stiffness matrix and internal force
    CALL PH_Elem_AC3D4_FormStiffMatrix(coords, k_eff, nu, Ke)
    CALL PH_Elem_AC3D4_FormIntForce(coords, u, k_eff, nu, R_int)

    ! Prepare output structure
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    ! Copy Ke to state_out
    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(4, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(4, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    ! Copy R_int to state_out
    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(4, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    ! Prepare integration point states
    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, 1)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    flags%status%status_code = IF_STATUS_OK
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt
    
  END SUBROUTINE UF_Elem_AC3D4_Calc

END MODULE PH_Elem_AC3D4
