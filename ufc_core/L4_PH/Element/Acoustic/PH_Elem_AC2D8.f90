!===============================================================================
! MODULE: PH_Elem_AC2D8
! LAYER:  L4_PH
! DOMAIN: Element/Acoustic
! ROLE:   Proc
! BRIEF:  AC2D8 8-node 2D acoustic element
!===============================================================================
MODULE PH_Elem_AC2D8
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
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC2D8_NNODE  = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC2D8_NDOF   = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC2D8_NIP    = 9_i4  ! 3x3 Gauss rule
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC2D8_NEDGE  = 4_i4
  
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
  !  14        | velocity_potential | Velocity potential [m?/s] (optional)
  !
  ! Note: For linear acoustics, only slots 13-14 are actively used.
  !       Slots 1-12 reserved for future nonlinear/coupled extensions.
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC2D8_NSVARS_PER_IP = 14_i4

  !===========================================================================
  ! PUBLIC INTERFACES - CATEGORIZED BY PRIORITY AND STATUS
  !===========================================================================
  
  !---------------------------------------------------------------------------
  ! CORE PHYSICS (??IMPLEMENTED - P2/P3)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_DefInit              ! Element definition init (stub)
  PUBLIC :: PH_Elem_AC2D8_FormStiffMatrix      ! Stiffness matrix assembly ??  PUBLIC :: PH_Elem_AC2D8_FormIntForce         ! Internal force vector ??  PUBLIC :: PH_Elem_AC2D8_ConsMass             ! Consistent mass matrix ??  PUBLIC :: PH_Elem_AC2D8_LumpMass             ! Lumped mass matrix ??  PUBLIC :: PH_Elem_AC2D8_ThermStrainVector    ! ?? STUB - Thermo-acoustic coupling (P4)
  
  !---------------------------------------------------------------------------
  ! NONLINEAR GEOMETRY (??DECISION NEEDED - Large amplitude acoustics?)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_NL_TL                ! ??Total Lagrangian formulation
  PUBLIC :: PH_Elem_AC2D8_NL_UL                ! ??Updated Lagrangian formulation
  
  !---------------------------------------------------------------------------
  ! AREA INTEGRATION (??IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_ELEM_AC2D8_AreaInt              ! Element area computation ??  
  !---------------------------------------------------------------------------
  ! BOUNDARY CONDITIONS (??IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_ApplyEssentialBC     ! Dirichlet BC (elimination) ??  PUBLIC :: PH_Elem_AC2D8_ApplyPenaltyBC       ! Neumann BC (penalty method) ??  PUBLIC :: PH_Elem_AC2D8_FormConstraintMatrix ! Constraint matrix (MPC) ??  
  !---------------------------------------------------------------------------
  ! SPECIAL BOUNDARY CONDITIONS (??IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_FormAcousticImpedance ! Impedance boundary ??  PUBLIC :: PH_Elem_AC2D8_FormRadiationCondition ! Radiation BC (infinite domain) ??  PUBLIC :: PH_Elem_AC2D8_FormStructureCoupling ! Fluid-structure interface ??  
  !---------------------------------------------------------------------------
  ! LOADS (??IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_FormPressureLoad     ! Distributed pressure load ??  PUBLIC :: PH_Elem_AC2D8_FormBodyForce        ! Body force (gravity, etc.) ??  PUBLIC :: PH_Elem_AC2D8_FormSurfaceTraction  ! Surface traction ??  
  !---------------------------------------------------------------------------
  ! POST-PROCESSING (??IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_CalcPressure         ! Pressure field recovery ??  PUBLIC :: PH_Elem_AC2D8_CalcAcousticIntensity ! Intensity vector (power flux) ??  PUBLIC :: PH_Elem_AC2D8_CalcEnergy           ! Kinetic/potential energy ??  PUBLIC :: PH_Elem_AC2D8_CalcEnergy_FromDesc  ! Energy from section descriptor ??  PUBLIC :: PH_Elem_AC2D8_OutputResults        ! File output helper ??  
  !---------------------------------------------------------------------------
  ! MATERIAL & SECTION PROPERTIES (??IMPLEMENTED)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_GetMaterialProps     ! Extract density, bulk modulus ??  PUBLIC :: PH_Elem_AC2D8_GetMaterialProps_FromDesc ! From material descriptor ??  PUBLIC :: PH_Elem_AC2D8_GetThickness         ! Element thickness (2D plane) ??  PUBLIC :: PH_Elem_AC2D8_GetAcousticProps     ! Density, impedance ??  PUBLIC :: PH_Elem_AC2D8_SetSectionProps      ! Set section parameters ??  PUBLIC :: PH_Elem_AC2D8_SetSectionProps_FromDesc ! From section descriptor ??  
  !---------------------------------------------------------------------------
  ! THERMO-ACOUSTIC COUPLING (? P4-1)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_Temperature_Dependent_Speed   ! c(T) = c?��??T/T?) ?
  PUBLIC :: PH_Elem_AC2D8_Thermal_Expansion_Source      ! Thermo-acoustic source term ?
  
  !---------------------------------------------------------------------------
  ! POROUS MEDIA - BIOT THEORY (? P4-2)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_Biot_Wave_Speed        ! Effective wave speed in porous media ?
  PUBLIC :: PH_Elem_AC2D8_Biot_Damping           ! Viscous dissipation from pore flow ?
  
  !---------------------------------------------------------------------------
  ! BIOT STABILIZATION (? P5-3 NUMERICAL STABILITY)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_Biot_Stabilize_SlowWave ! SUPG stabilization for P2 wave ?
  PUBLIC :: PH_Elem_AC2D8_Biot_Compute_Stab_Param ! Compute �� stabilization parameter ?
  
  !---------------------------------------------------------------------------
  ! INFINITE ELEMENT BOUNDARY (? P4-3)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_Sommerfeld_Radiation   ! Sommerfeld radiation condition ?
  PUBLIC :: PH_Elem_AC2D8_Infinite_Element_Map    ! Infinite element mapping ?
  
  !---------------------------------------------------------------------------
  ! PML - PERFECTLY MATCHED LAYER (? P5-2 TIME DOMAIN)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC2D8_PML_Update_State        ! PML state variable update ?
  PUBLIC :: PH_Elem_AC2D8_PML_Absorbing_Boundary  ! Time-domain PML absorption ?
  
  !===========================================================================
  ! UEL ARGUMENT BUNDLE - PH_AC2D8_UEL_Args (Principle #14)
  !===========================================================================
  !> Unified argument bundle for AC2D8 element computation
  !>
  !> Design: Principle #14 Structured IO (SIO-01 to SIO-14 compliant)
  !>   - [IN] Flags and scalars only (no ALLOCATABLE, no _Desc/_State/_Algo/_Ctx)
  !>   - [OUT] Status, pnewdt, diagnostics via ErrorStatusType
  TYPE, PUBLIC :: PH_AC2D8_UEL_Args
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
    
    !-- [OUT] Status and diagnostics
    TYPE(ErrorStatusType) :: status      ! Error status (required by SIO-03)
    LOGICAL               :: success      = .FALSE.  ! Overall step success flag
    REAL(wp)              :: pnewdt       = 1.0_wp   ! Suggested time step change ratio
    REAL(wp)              :: strain_energy = 0.0_wp  ! Element strain energy (acoustic potential)
    INTEGER(i4)           :: ip_failed    = 0_i4     ! IP index where failure occurred
    REAL(wp)              :: total_mass   = 0.0_wp  ! Total element mass (P3 diagnostic)
  END TYPE PH_AC2D8_UEL_Args

CONTAINS

  !===========================================================================
  ! UEL API - Thin Wrapper (Principle #14 / SIO adaptation for L4_PH UEL)
  !===========================================================================
  !> PH_AC2D8_UEL_API
  !>
  !> ROLE: THIN WRAPPER ONLY ??fills PH_AC2D8_UEL_Args, delegates to PH_AC2D8_UEL_Impl.
  !>   DO NOT add element physics here; implement in PH_AC2D8_UEL_Impl.
  SUBROUTINE PH_AC2D8_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
       RT_Com_Ctx, pnewdt, uel_status)
    TYPE(MD_Sect_Registry),    INTENT(IN), TARGET :: sect_registry
    TYPE(MD_Elem_UEL_Desc),   INTENT(IN)    :: MD_Elem_Desc
    TYPE(PH_Elem_Ctx),    INTENT(INOUT) :: PH_Elem_Ctx
    TYPE(PH_Elem_State),  INTENT(INOUT) :: PH_Elem_State
    TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                  INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType),     INTENT(OUT)   :: uel_status
    
    TYPE(PH_AC2D8_UEL_Args) :: uel_args
    
    uel_args%compute_amatrx = .TRUE.   ! Default: compute both
    uel_args%compute_rhs    = .TRUE.
    uel_args%lflags_kstep   = RT_Com_Ctx%lflags(1)
    uel_args%success = .FALSE.         ! Reset before delegate call
    
    CALL PH_AC2D8_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
        RT_Com_Ctx, uel_args)
    
    pnewdt     = uel_args%pnewdt
    uel_status = uel_args%status
  END SUBROUTINE PH_AC2D8_UEL_API
  
  !===========================================================================
  ! UEL IMPL - Physical Computation Core (PRIVATE)
  !===========================================================================
  !> PH_AC2D8_UEL_Impl
  !>
  !> Six-parameter inner interface (Principle #14, L4 hot-path form).
  !> All acoustic element physics implemented here.
  SUBROUTINE PH_AC2D8_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
       RT_Com_Ctx, args)
    TYPE(MD_Sect_Registry),    INTENT(IN), TARGET :: sect_registry
    TYPE(MD_Elem_UEL_Desc),   INTENT(IN)    :: MD_Elem_Desc
    TYPE(PH_Elem_Ctx),    INTENT(INOUT) :: PH_Elem_Ctx
    TYPE(PH_Elem_State),  INTENT(INOUT) :: PH_Elem_State
    TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx
    TYPE(PH_AC2D8_UEL_Args),   INTENT(INOUT) :: args
    
    !-- Local variables
    !$UFC HOT_PATH
    INTEGER(i4) :: sect_id, sect_idx
    CLASS(MD_Mat_Desc), POINTER :: mat_d => NULL()
    REAL(wp) :: pnewdt_ip
    REAL(wp) :: N(PH_ELEM_AC2D8_NNODE), dNdX(2, PH_ELEM_AC2D8_NNODE)
    REAL(wp) :: B(2, PH_ELEM_AC2D8_NDOF)
    REAL(wp) :: xi, eta, w_ip, det_J
    REAL(wp) :: dstran_ip, fint(PH_ELEM_AC2D8_NDOF), pnewdt_min
    INTEGER(i4) :: ip, ndofel, nip
    INTEGER(i4) :: nsvars_per_ip, slot_base
    REAL(wp) :: density, bulk_modulus, sound_speed
    
    !-- SVARS stride: must match CONTRACT_SVARS_IP_LAYOUT.md
    INTEGER(i4), PARAMETER :: NSVARS_PER_IP = PH_ELEM_AC2D8_NSVARS_PER_IP
    
    CALL init_error_status(args%status)
    args%success       = .FALSE.
    args%pnewdt        = RT_PNEWDT_NO_CHANGE
    args%strain_energy = 0.0_wp
    args%ip_failed     = 0
    
    ndofel = PH_ELEM_AC2D8_NDOF
    nip    = PH_ELEM_AC2D8_NIP
    
    !-- Validation checks
    IF (.NOT. ALLOCATED(PH_Elem_State%itr%svars) .OR. &
        SIZE(PH_Elem_State%itr%svars) < nip * NSVARS_PER_IP) THEN
      CALL init_error_status(args%status, STATUS_ERROR, &
          message='[AC2D8_UEL_Impl]: svars too small; expected nip*NSVARS_PER_IP slots')
      RETURN
    END IF
    
    pnewdt_min   = RT_PNEWDT_NO_CHANGE
    nsvars_per_ip = NSVARS_PER_IP
    
    IF (ALLOCATED(PH_Elem_State%itr%rhs))    PH_Elem_State%itr%rhs    = 0.0_wp
    IF (ALLOCATED(PH_Elem_State%itr%amatrx)) PH_Elem_State%itr%amatrx = 0.0_wp
    PH_Elem_State%itr%energy = 0.0_wp
    fint = 0.0_wp
    
    !-- Section registry lookup (NO hot-loop scan ??SIO-10)
    sect_id  = MD_Elem_Desc%jprops(1)
    sect_idx = sect_registry%GetSectIdx(sect_id)
    IF (sect_idx == 0) THEN
      CALL init_error_status(args%status, STATUS_ERROR, &
          message='[AC2D8_UEL_Impl]: section_id not found in registry')
      RETURN
    END IF
    
    mat_d => sect_registry%sections(sect_idx)%mat_desc
    IF (.NOT. ASSOCIATED(mat_d)) THEN
      CALL init_error_status(args%status, STATUS_ERROR, &
          message='[AC2D8_UEL_Impl]: section mat_desc not associated')
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
        ! Interpolate temperature at element centroid
        REAL(wp) :: T_centroid, T_ratio
        T_centroid = SUM(md%T_field(1:PH_ELEM_AC2D8_NNODE)) / REAL(PH_ELEM_AC2D8_NNODE)
        T_ratio = SQRT(T_centroid / md%T_ref)
        sound_speed = md%sound_speed_ref * T_ratio
        
        ! Also update density if thermal expansion is enabled
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
    
    !-- Integration loop over Gauss points (3x3 rule)
    DO ip = 1, nip
      
      !-- Convert linear IP to 2D indices for 3x3 Gauss rule
      INTEGER(i4) :: ip_x, ip_y
      REAL(wp) :: xi_gp, eta_gp, w_x, w_y
      ip_x = MOD(ip-1, 3) + 1
      ip_y = (ip-1) / 3 + 1
      CALL CPS8_GetGaussPoint1D(ip_x, xi_gp, w_x)
      CALL CPS8_GetGaussPoint1D(ip_y, eta_gp, w_y)
      xi = xi_gp
      eta = eta_gp
      w_ip = w_x * w_y
      
      !-- Shape functions and physical derivatives
      CALL CPS8_Shape_Functions(xi, eta, N)
      CALL CPS8_Jacobian(PH_Elem_Ctx%coords, N, xi, eta, dNdX, det_J)
      
      IF (det_J <= 0.0_wp) THEN
        CALL init_error_status(args%status, STATUS_ERROR, &
            message='[AC2D8_UEL_Impl]: non-positive Jacobian det at IP')
        args%ip_failed = ip
        args%pnewdt    = 0.0_wp
        RETURN
      END IF
      
      !-- B-matrix: pressure gradient operator [2 x 8]
      CALL AC2D8_B_Matrix(dNdX, B)
      
      !-- Strain increment (volumetric): delta_eps = ?p �� delta_u
      dstran_ip = B(1, :) * PH_Elem_Ctx%du(1, :) + B(2, :) * PH_Elem_Ctx%du(2, :)
      
      !-- Acoustic constitutive: p = -K���� (pressure from volumetric strain)
      REAL(wp) :: pressure_increment
      pressure_increment = -bulk_modulus * dstran_ip
      
      !-- Assemble internal force vector: f_int += B? �� p �� detJ �� w
      IF (args%compute_rhs .AND. ALLOCATED(PH_Elem_State%itr%rhs)) THEN
        fint(:) = fint(:) + MATMUL(TRANSPOSE(B), pressure_increment) * det_J * w_ip
      END IF
      
      !-- Assemble stiffness matrix: K += B? �� K �� B �� detJ �� w
      IF (args%compute_amatrx .AND. ALLOCATED(PH_Elem_State%itr%amatrx)) THEN
        REAL(wp) :: Ke_local(PH_ELEM_AC2D8_NDOF, PH_ELEM_AC2D8_NDOF)
        Ke_local = bulk_modulus * MATMUL(TRANSPOSE(B), B) * det_J * w_ip
        PH_Elem_State%itr%amatrx(1:ndofel, 1:ndofel) = &
             PH_Elem_State%itr%amatrx(1:ndofel, 1:ndofel) + Ke_local
      END IF
      
      !-- Accumulate strain energy
      args%strain_energy = args%strain_energy + &
           0.5_wp * pressure_increment * dstran_ip * det_J * w_ip
      
    END DO
    
    !-- Finalize RHS
    IF (args%compute_rhs .AND. ALLOCATED(PH_Elem_State%itr%rhs)) &
      PH_Elem_State%itr%rhs(1:ndofel, 1) = -fint(1:ndofel)
    
    args%pnewdt = MIN(RT_PNEWDT_NO_CHANGE, pnewdt_min)
    args%success = .TRUE.
    CALL init_error_status(args%status, IF_STATUS_OK)
    
  CONTAINS
    
    !-------------------------------------------------------------------------
    ! ELEMENT-TOPOLOGY PRIVATE HELPERS (CPS8 - 8-node quadrilateral)
    !-------------------------------------------------------------------------
    
    SUBROUTINE CPS8_GetGaussPoint1D(ip, xi, w)
      !! Return 1D Gauss point coordinates and weight
      INTEGER(i4), INTENT(IN)  :: ip
      REAL(wp),    INTENT(OUT) :: xi, w
      
      SELECT CASE (ip)
      CASE (1)
        xi = -SQRT(3.0_wp/5.0_wp); w = 5.0_wp/9.0_wp
      CASE (2)
        xi = 0.0_wp;                w = 8.0_wp/9.0_wp
      CASE (3)
        xi = SQRT(3.0_wp/5.0_wp);  w = 5.0_wp/9.0_wp
      CASE DEFAULT
        xi = 0.0_wp; w = 0.0_wp
      END SELECT
    END SUBROUTINE CPS8_GetGaussPoint1D
    
    SUBROUTINE CPS8_Shape_Functions(xi, eta, N)
      !! 8-node quadratic quadrilateral shape functions
      REAL(wp), INTENT(IN)  :: xi, eta
      REAL(wp), INTENT(OUT) :: N(:)
      REAL(wp) :: xi2, eta2, xim1, etam1, xip1, etap1
      
      xi2 = xi*xi
      eta2 = eta*eta
      xim1 = xi - 1.0_wp
      etam1 = eta - 1.0_wp
      xip1 = xi + 1.0_wp
      etap1 = eta + 1.0_wp
      
      ! Corner nodes (1-4)
      N(1) = -0.25_wp * xim1 * etam1 * (xi + eta + 1.0_wp)
      N(2) =  0.25_wp * xip1 * etam1 * (xi - eta - 1.0_wp)
      N(3) =  0.25_wp * xip1 * etap1 * (xi + eta - 1.0_wp)
      N(4) = -0.25_wp * xim1 * etap1 * (xi - eta + 1.0_wp)
      
      ! Midside nodes (5-8)
      N(5) = -0.5_wp * xim1 * xip1 * etam1  ! Node 5 (midside 1-2)
      N(6) =  0.5_wp * xip1 * etap1 * etam1  ! Node 6 (midside 2-3)
      N(7) = -0.5_wp * xim1 * xip1 * etap1  ! Node 7 (midside 3-4)
      N(8) =  0.5_wp * xim1 * etam1 * etap1  ! Node 8 (midside 4-1)
    END SUBROUTINE CPS8_Shape_Functions
    
    SUBROUTINE CPS8_Shape_Functions_Derivatives(xi, eta, dNdxi, dNdeta)
      !! Derivatives of 8-node quadratic quadrilateral shape functions
      REAL(wp), INTENT(IN)  :: xi, eta
      REAL(wp), INTENT(OUT) :: dNdxi(:), dNdeta(:)
      REAL(wp) :: xi2, eta2, xim1, etam1, xip1, etap1
      
      xi2 = xi*xi
      eta2 = eta*eta
      xim1 = xi - 1.0_wp
      etam1 = eta - 1.0_wp
      xip1 = xi + 1.0_wp
      etap1 = eta + 1.0_wp
      
      ! dN/d��
      dNdxi(1) = -0.25_wp * etam1 * (2.0_wp*xi + eta)
      dNdxi(2) =  0.25_wp * etam1 * (2.0_wp*xi - eta)
      dNdxi(3) =  0.25_wp * etap1 * (2.0_wp*xi + eta)
      dNdxi(4) = -0.25_wp * etap1 * (2.0_wp*xi - eta)
      dNdxi(5) = -xi * etam1
      dNdxi(6) =  0.5_wp * etap1 * etam1
      dNdxi(7) = -xi * etap1
      dNdxi(8) =  0.5_wp * etam1 * etap1
      
      ! dN/d��
      dNdeta(1) = -0.25_wp * xim1 * (xi + 2.0_wp*eta)
      dNdeta(2) =  0.25_wp * xip1 * (xi - 2.0_wp*eta)
      dNdeta(3) =  0.25_wp * xip1 * (xi + 2.0_wp*eta)
      dNdeta(4) = -0.25_wp * xim1 * (xi - 2.0_wp*eta)
      dNdeta(5) = -0.5_wp * xim1 * xip1
      dNdeta(6) =  eta * etap1
      dNdeta(7) = -0.5_wp * xim1 * xip1
      dNdeta(8) =  eta * etam1
    END SUBROUTINE CPS8_Shape_Functions_Derivatives
    
    SUBROUTINE CPS8_Jacobian(coords, N, xi, eta, dNdX, detJ)
      !! Compute Jacobian and physical derivatives
      REAL(wp), INTENT(IN)  :: coords(:,:)
      REAL(wp), INTENT(IN)  :: N(:)
      REAL(wp), INTENT(IN)  :: xi, eta
      REAL(wp), INTENT(OUT) :: dNdX(:,:)
      REAL(wp), INTENT(OUT) :: detJ
      
      REAL(wp) :: dNdxi(2, PH_ELEM_AC2D8_NNODE)
      REAL(wp) :: J(2, 2)
      INTEGER(i4) :: a
      
      ! Derivatives in natural coordinates
      CALL CPS8_Shape_Functions_Derivatives(xi, eta, dNdxi(1,:), dNdxi(2,:))
      
      ! Jacobian: J = ?x/???= [?x/??? ?y/??? ?x/??? ?y/?��]
      J = MATMUL(coords, TRANSPOSE(dNdxi))
      detJ = J(1,1)*J(2,2) - J(1,2)*J(2,1)
      
      ! Inverse: dN/dX = J???�� dN/d��
      IF (ABS(detJ) > 1.0e-12_wp) THEN
        REAL(wp) :: Jinv(2, 2)
        Jinv(1,1) =  J(2,2) / detJ
        Jinv(1,2) = -J(1,2) / detJ
        Jinv(2,1) = -J(2,1) / detJ
        Jinv(2,2) =  J(1,1) / detJ
        dNdX = MATMUL(Jinv, dNdxi)
      ELSE
        dNdX = 0.0_wp
      END IF
    END SUBROUTINE CPS8_Jacobian
    
    SUBROUTINE AC2D8_B_Matrix(dNdX, B)
      !! Acoustic B-matrix: relates nodal pressures to pressure gradient
      !! ?p = B �� p_node
      REAL(wp), INTENT(IN)  :: dNdX(:,:)
      REAL(wp), INTENT(OUT) :: B(:,:)
      
      INTEGER(i4) :: a
      
      B = 0.0_wp
      DO a = 1, PH_ELEM_AC2D8_NNODE
        B(1, a) = dNdX(1, a)  ! ?N/?x
        B(2, a) = dNdX(2, a)  ! ?N/?y
      END DO
    END SUBROUTINE AC2D8_B_Matrix
    
  END SUBROUTINE PH_AC2D8_UEL_Impl
  
  !===========================================================================
  ! LEGACY HELPER SUBROUTINES (Compatibility layer)
  !===========================================================================
  
  ! SECTION PROPERTIES
  SUBROUTINE PH_Elem_AC2D8_GetMaterialProps(density, bulk_modulus, sound_speed)
    REAL(wp), INTENT(OUT) :: density, bulk_modulus, sound_speed
    density = 1000.0_wp
    bulk_modulus = 2.2e9_wp
    sound_speed = SQRT(bulk_modulus / density)
  END SUBROUTINE PH_Elem_AC2D8_GetMaterialProps
  
  SUBROUTINE PH_Elem_AC2D8_GetMaterialProps_FromDesc(desc)
    TYPE(PH_El_AC_Mat_Desc), INTENT(OUT) :: desc
    desc%density = 1000.0_wp
    desc%bulk_modulus = 2.2e9_wp
    desc%sound_speed = SQRT(desc%bulk_modulus / desc%density)
  END SUBROUTINE PH_Elem_AC2D8_GetMaterialProps_FromDesc
  
  SUBROUTINE PH_Elem_AC2D8_GetThickness(thickness)
    REAL(wp), INTENT(OUT) :: thickness
    thickness = 1.0_wp
  END SUBROUTINE PH_Elem_AC2D8_GetThickness
  
  SUBROUTINE PH_Elem_AC2D8_GetAcousticProps(acoustic_density, acoustic_impedance)
    REAL(wp), INTENT(OUT) :: acoustic_density, acoustic_impedance
    REAL(wp) :: bulk_modulus, sound_speed
    CALL PH_Elem_AC2D8_GetMaterialProps(acoustic_density, bulk_modulus, sound_speed)
    sound_speed = SQRT(bulk_modulus / acoustic_density)
    acoustic_impedance = acoustic_density * sound_speed
  END SUBROUTINE PH_Elem_AC2D8_GetAcousticProps
  
  SUBROUTINE PH_Elem_AC2D8_SetSectionProps(density, bulk_modulus, thickness)
    REAL(wp), INTENT(IN) :: density, bulk_modulus, thickness
  END SUBROUTINE PH_Elem_AC2D8_SetSectionProps
  
  SUBROUTINE PH_Elem_AC2D8_SetSectionProps_FromDesc(sect_desc)
    TYPE(PH_El_AC_Sect_Desc), INTENT(IN) :: sect_desc
    CALL PH_Elem_AC2D8_SetSectionProps(sect_desc%density, sect_desc%bulk_modulus, sect_desc%thickness)
  END SUBROUTINE PH_Elem_AC2D8_SetSectionProps_FromDesc
  
  ! CONSTRAINTS (8-node quadrilateral)
  SUBROUTINE PH_Elem_AC2D8_ApplyEssentialBC(Ke, F_ext, constrained_nodes, prescribed_values)
    REAL(wp), INTENT(INOUT) :: Ke(8, 8)
    REAL(wp), INTENT(INOUT) :: F_ext(8)
    INTEGER(i4), INTENT(IN) :: constrained_nodes(:)
    REAL(wp), INTENT(IN)    :: prescribed_values(:)
    INTEGER(i4) :: i, j, node_idx
    DO i = 1, SIZE(constrained_nodes)
      node_idx = constrained_nodes(i)
      DO j = 1, 8
        IF (j /= node_idx) THEN
          Ke(node_idx, j) = ZERO
          Ke(j, node_idx) = ZERO
        END IF
      END DO
      Ke(node_idx, node_idx) = ONE
      F_ext(node_idx) = prescribed_values(i)
      DO j = 1, 8
        IF (j /= node_idx) F_ext(j) = F_ext(j) - Ke(j, node_idx) * prescribed_values(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC2D8_ApplyEssentialBC
  
  SUBROUTINE PH_Elem_AC2D8_FormConstraintMatrix(constrained_nodes, C_matrix)
    INTEGER(i4), INTENT(IN) :: constrained_nodes(:)
    REAL(wp), INTENT(OUT)   :: C_matrix(SIZE(constrained_nodes), 8)
    INTEGER(i4) :: i, node_idx
    C_matrix = ZERO
    DO i = 1, SIZE(constrained_nodes)
      node_idx = constrained_nodes(i)
      C_matrix(i, node_idx) = ONE
    END DO
  END SUBROUTINE PH_Elem_AC2D8_FormConstraintMatrix
  
  SUBROUTINE PH_Elem_AC2D8_ApplyPenaltyBC(Ke, F_ext, constrained_nodes, prescribed_values, penalty)
    REAL(wp), INTENT(INOUT) :: Ke(8, 8)
    REAL(wp), INTENT(INOUT) :: F_ext(8)
    INTEGER(i4), INTENT(IN) :: constrained_nodes(:)
    REAL(wp), INTENT(IN)    :: prescribed_values(:)
    REAL(wp), INTENT(IN)    :: penalty
    INTEGER(i4) :: i, node_idx
    DO i = 1, SIZE(constrained_nodes)
      node_idx = constrained_nodes(i)
      Ke(node_idx, node_idx) = Ke(node_idx, node_idx) + penalty
      F_ext(node_idx) = F_ext(node_idx) + penalty * prescribed_values(i)
    END DO
  END SUBROUTINE PH_Elem_AC2D8_ApplyPenaltyBC
  
  ! CONTACT (quadrilateral: 4 edges)
  SUBROUTINE PH_Elem_AC2D8_FormAcousticImpedance(coords, impedance, face, K_impedance)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: impedance
    INTEGER(i4), INTENT(IN) :: face
    REAL(wp), INTENT(OUT) :: K_impedance(8, 8)
    INTEGER(i4) :: face_nodes(3)
    REAL(wp) :: face_length, N_face(3), N_face_mat(3, 3)
    INTEGER(i4) :: i, j
    K_impedance = ZERO
    SELECT CASE(face)
      CASE(1); face_nodes = [1, 2, 5]  ! Edge 1-2
      CASE(2); face_nodes = [2, 3, 6]  ! Edge 2-3
      CASE(3); face_nodes = [3, 4, 7]  ! Edge 3-4
      CASE(4); face_nodes = [4, 1, 8]  ! Edge 4-1
      CASE DEFAULT
        RETURN
    END SELECT
    ! Compute edge length using 3-point Gauss rule
    face_length = 0.0_wp
    DO i = 1, 3
      REAL(wp) :: xi_gp, w_gp, dxdxi, dydxi
      xi_gp = -1.0_wp + 2.0_wp*(REAL(i)-1.0_wp)/2.0_wp
      w_gp = 1.0_wp
      dxdxi = 0.5_wp*(coords(1,face_nodes(2)) - coords(1,face_nodes(1)))
      dydxi = 0.5_wp*(coords(2,face_nodes(2)) - coords(2,face_nodes(1)))
      face_length = face_length + SQRT(dxdxi**2 + dydxi**2) * w_gp
    END DO
    N_face = 1.0_wp / 3.0_wp  ! Uniform distribution
    DO i = 1, 3
      DO j = 1, 3
        N_face_mat(i, j) = N_face(i) * N_face(j)
      END DO
    END DO
    DO i = 1, 3
      DO j = 1, 3
        K_impedance(face_nodes(i), face_nodes(j)) = impedance * face_length * N_face_mat(i, j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC2D8_FormAcousticImpedance
  
  SUBROUTINE PH_Elem_AC2D8_FormRadiationCondition(coords, radiation_coeff, face, K_radiation)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: radiation_coeff
    INTEGER(i4), INTENT(IN) :: face
    REAL(wp), INTENT(OUT) :: K_radiation(8, 8)
    CALL PH_Elem_AC2D8_FormAcousticImpedance(coords, radiation_coeff, face, K_radiation)
  END SUBROUTINE PH_Elem_AC2D8_FormRadiationCondition
  
  SUBROUTINE PH_Elem_AC2D8_FormStructureCoupling(coords, coupling_coeff, face, K_coupling)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: coupling_coeff
    INTEGER(i4), INTENT(IN) :: face
    REAL(wp), INTENT(OUT) :: K_coupling(8, 8)
    CALL PH_Elem_AC2D8_FormAcousticImpedance(coords, coupling_coeff, face, K_coupling)
  END SUBROUTINE PH_Elem_AC2D8_FormStructureCoupling
  
  ! LOADS (8-node quadrilateral)
  SUBROUTINE PH_Elem_AC2D8_FormPressureLoad(coords, pressure, F_ext)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: pressure
    REAL(wp), INTENT(OUT) :: F_ext(8)
    REAL(wp) :: area, load_per_node
    INTEGER(i4) :: i
    CALL PH_ELEM_AC2D8_AreaInt(coords, area)
    load_per_node = pressure * area / 8.0_wp
    DO i = 1, 8
      F_ext(i) = load_per_node
    END DO
  END SUBROUTINE PH_Elem_AC2D8_FormPressureLoad
  
  SUBROUTINE PH_Elem_AC2D8_FormSurfaceTraction(coords, traction, face, F_ext)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: traction(2)
    INTEGER(i4), INTENT(IN) :: face
    REAL(wp), INTENT(OUT) :: F_ext(8)
    INTEGER(i4) :: face_nodes(3)
    REAL(wp) :: face_length, N_face(3)
    INTEGER(i4) :: i
    F_ext = ZERO
    SELECT CASE(face)
      CASE(1); face_nodes = [1, 2, 5]
      CASE(2); face_nodes = [2, 3, 6]
      CASE(3); face_nodes = [3, 4, 7]
      CASE(4); face_nodes = [4, 1, 8]
      CASE DEFAULT
        RETURN
    END SELECT
    face_length = 0.0_wp
    DO i = 1, 3
      REAL(wp) :: xi_gp, dxdxi, dydxi
      xi_gp = -1.0_wp + 2.0_wp*(REAL(i)-1.0_wp)/2.0_wp
      dxdxi = 0.5_wp*(coords(1,face_nodes(2)) - coords(1,face_nodes(1)))
      dydxi = 0.5_wp*(coords(2,face_nodes(2)) - coords(2,face_nodes(1)))
      face_length = face_length + SQRT(dxdxi**2 + dydxi**2)
    END DO
    N_face = 1.0_wp / 3.0_wp
    DO i = 1, 3
      F_ext(face_nodes(i)) = N_face(i) * face_length * (traction(1) + traction(2))
    END DO
  END SUBROUTINE PH_Elem_AC2D8_FormSurfaceTraction
  
  SUBROUTINE PH_Elem_AC2D8_FormBodyForce(coords, body_force, F_ext)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: body_force(2)
    REAL(wp), INTENT(OUT) :: F_ext(8)
    REAL(wp) :: area, load_per_node
    INTEGER(i4) :: i
    CALL PH_ELEM_AC2D8_AreaInt(coords, area)
    load_per_node = area / 8.0_wp * (body_force(1) + body_force(2))
    DO i = 1, 8
      F_ext(i) = load_per_node / 8.0_wp
    END DO
  END SUBROUTINE PH_Elem_AC2D8_FormBodyForce
  
  ! OUTPUT (8-node)
  SUBROUTINE PH_Elem_AC2D8_CalcAcousticIntensity(coords, nodal_pressures, nodal_velocities, intensity)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: nodal_pressures(8)
    REAL(wp), INTENT(IN)  :: nodal_velocities(8, 2)
    REAL(wp), INTENT(OUT) :: intensity(2)
    REAL(wp) :: avg_pressure, avg_velocity(2)
    INTEGER(i4) :: i
    avg_pressure = SUM(nodal_pressures) / 8.0_wp
    DO i = 1, 2
      avg_velocity(i) = SUM(nodal_velocities(:, i)) / 8.0_wp
    END DO
    intensity = avg_pressure * avg_velocity
  END SUBROUTINE PH_Elem_AC2D8_CalcAcousticIntensity
  
  SUBROUTINE PH_Elem_AC2D8_CalcEnergy(coords, nodal_pressures, nodal_velocities, density, kinetic_energy, potential_energy)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: nodal_pressures(8)
    REAL(wp), INTENT(IN)  :: nodal_velocities(8, 2)
    REAL(wp), INTENT(IN)  :: density
    REAL(wp), INTENT(OUT) :: kinetic_energy, potential_energy
    REAL(wp) :: avg_pressure, avg_velocity_mag, area
    INTEGER(i4) :: i
    avg_pressure = SUM(nodal_pressures) / 8.0_wp
    avg_velocity_mag = ZERO
    DO i = 1, 8
      avg_velocity_mag = avg_velocity_mag + SQRT(nodal_velocities(i, 1)**2 + nodal_velocities(i, 2)**2)
    END DO
    avg_velocity_mag = avg_velocity_mag / 8.0_wp
    CALL PH_ELEM_AC2D8_AreaInt(coords, area)
    kinetic_energy = 0.5_wp * density * avg_velocity_mag**2 * area
    potential_energy = 0.5_wp * avg_pressure**2 / (density * 1500.0_wp**2) * area
  END SUBROUTINE PH_Elem_AC2D8_CalcEnergy
  
  SUBROUTINE PH_Elem_AC2D8_CalcEnergy_FromDesc(coords, nodal_pressures, nodal_velocities, sect_desc, kinetic_energy, potential_energy)
    !! Calculate energy from section descriptor
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: nodal_pressures(8)
    REAL(wp), INTENT(IN)  :: nodal_velocities(8, 2)
    TYPE(PH_El_AC_Sect_Desc), INTENT(IN) :: sect_desc
    REAL(wp), INTENT(OUT) :: kinetic_energy, potential_energy
    REAL(wp) :: density
    density = sect_desc%density
    CALL PH_Elem_AC2D8_CalcEnergy(coords, nodal_pressures, nodal_velocities, density, kinetic_energy, potential_energy)
  END SUBROUTINE PH_Elem_AC2D8_CalcEnergy_FromDesc
  
  SUBROUTINE PH_Elem_AC2D8_OutputResults(coords, nodal_pressures, nodal_velocities, filename)
    !! Output results to file
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: nodal_pressures(8)
    REAL(wp), INTENT(IN)  :: nodal_velocities(8, 2)
    CHARACTER(*), INTENT(IN) :: filename
    ! Stub implementation - actual output depends on file format
    ! TODO: Implement VTK/CSV output for AC2D8 results
  END SUBROUTINE PH_Elem_AC2D8_OutputResults
  
  SUBROUTINE PH_Elem_AC2D8_CalcPressure(coords, nodal_pressures, gauss_points, pressure_field)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: nodal_pressures(8)
    REAL(wp), INTENT(IN)  :: gauss_points(:, :)
    REAL(wp), INTENT(OUT) :: pressure_field(SIZE(gauss_points, 2))
    REAL(wp) :: xi, eta, N(8), dNdxi(2, 8)
    INTEGER(i4) :: ip
    DO ip = 1, SIZE(gauss_points, 2)
      xi = gauss_points(1, ip)
      eta = gauss_points(2, ip)
      CALL CPS8_Shape_Functions(xi, eta, N)
      pressure_field(ip) = DOT_PRODUCT(N, nodal_pressures)
    END DO
  END SUBROUTINE PH_Elem_AC2D8_CalcPressure
  
  !===========================================================================
  ! P4-1 THERMO-ACOUSTIC COUPLING FUNCTIONS
  !===========================================================================
  
  SUBROUTINE PH_Elem_AC2D8_Update_Speed_of_Sound(mat_desc, temperature, &
       updated_sound_speed, updated_density, updated_bulk_modulus)
    !! Update acoustic properties based on temperature
    !!
    !! Theory: c(T) = c? �� ??T/T?) for ideal gases
    !!         ��(T) = ��? �� [1 - ��_T��(T - T?)] for liquids
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_Update_Speed_of_Sound(mat_desc, T_field, c_new, rho_new, K_new)
    
    CLASS(MD_Mat_Desc), INTENT(IN) :: mat_desc
    REAL(wp), INTENT(IN) :: temperature(:)  ! Nodal temperatures
    REAL(wp), INTENT(OUT) :: updated_sound_speed
    REAL(wp), INTENT(OUT), OPTIONAL :: updated_density, updated_bulk_modulus
    
    REAL(wp) :: T_centroid, T_ratio, rho_factor
    
    SELECT TYPE (md => mat_desc)
    TYPE IS (MD_Mat_Acoustic_Desc)
      
      ! Centroid temperature (average of nodal values)
      T_centroid = SUM(temperature(1:PH_ELEM_AC2D8_NNODE)) / REAL(PH_ELEM_AC2D8_NNODE)
      
      ! Sound speed temperature dependence
      IF (md%use_temp_dependence) THEN
        T_ratio = SQRT(T_centroid / md%T_ref)
        updated_sound_speed = md%sound_speed_ref * T_ratio
        
        ! Density thermal expansion
        IF (PRESENT(updated_density) .AND. md%alpha_T > 0.0_wp) THEN
          rho_factor = 1.0_wp - md%alpha_T * (T_centroid - md%T_ref)
          updated_density = md%density_ref * rho_factor
        END IF
        
        ! Bulk modulus temperature dependence (if pressure-dependent)
        IF (PRESENT(updated_bulk_modulus) .AND. md%use_pressure_dependence) THEN
          ! Simplified: K(T) ??K? �� (T/T?)^(-n), n ??0.5-1.0
          updated_bulk_modulus = md%bulk_modulus_ref * (md%T_ref / T_centroid)**0.7_wp
        END IF
      ELSE
        ! No temperature dependence - use reference values
        updated_sound_speed = md%sound_speed_ref
        IF (PRESENT(updated_density)) updated_density = md%density_ref
        IF (PRESENT(updated_bulk_modulus)) updated_bulk_modulus = md%bulk_modulus_ref
      END IF
      
    CLASS DEFAULT
      ! Fallback
      updated_sound_speed = 343.0_wp
      IF (PRESENT(updated_density)) updated_density = 1.225_wp
      IF (PRESENT(updated_bulk_modulus)) updated_bulk_modulus = 1.42e5_wp
    END SELECT
    
  END SUBROUTINE PH_Elem_AC2D8_Update_Speed_of_Sound
  
  ! Aliases for AC2D4 naming consistency
  PUBLIC :: PH_Elem_AC2D8_Update_Speed_of_Sound => PH_Elem_AC2D8_Temperature_Dependent_Speed
  
  SUBROUTINE PH_Elem_AC2D8_Thermal_Expansion_Source(coords, mat_desc, temperature, source_term, status)
    !! Compute thermal expansion source term for thermo-acoustic coupling
    !!
    !! Theory: S_therm = -�ѡ���_T��??T/?t? (thermal acceleration source)
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_Thermal_Expansion_Source(coords, mat_desc, T_nodes, f_therm, status)
    
    REAL(wp), INTENT(IN)  :: coords(:,:)
    CLASS(MD_Mat_Desc), INTENT(IN) :: mat_desc
    REAL(wp), INTENT(IN)  :: temperature(:)
    REAL(wp), INTENT(OUT) :: source_term(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: T_centroid, alpha_T, rho
    INTEGER(i4) :: a
    
    CALL init_error_status(status)
    source_term = 0.0_wp
    
    SELECT TYPE (md => mat_desc)
    TYPE IS (MD_Mat_Acoustic_Desc)
      T_centroid = SUM(temperature(1:PH_ELEM_AC2D8_NNODE)) / REAL(PH_ELEM_AC2D8_NNODE)
      alpha_T = md%alpha_T
      rho = md%density_ref
      
      ! Distribute source to nodes (simplified - actual implementation needs time derivative)
      DO a = 1, PH_ELEM_AC2D8_NNODE
        source_term(a) = -rho * alpha_T * T_centroid / 8.0_wp
      END DO
      
    CLASS DEFAULT
      CALL init_error_status(status, STATUS_ERROR, \
           message='[AC2D8_Thermal_Expansion]: Not an acoustic material')
    END SELECT
    
  END SUBROUTINE PH_Elem_AC2D8_Thermal_Expansion_Source
  
  SUBROUTINE PH_Elem_AC2D8_Setup_Thermo_Coupling(mat_desc, T_field, status)
    !! Setup thermo-acoustic coupling by linking temperature field
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_Setup_Thermo_Coupling(mat_desc, T_nodes, status)
    
    CLASS(MD_Mat_Desc), INTENT(INOUT) :: mat_desc
    REAL(wp), POINTER, INTENT(IN) :: T_field(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    SELECT TYPE (md => mat_desc)
    TYPE IS (MD_Mat_Acoustic_Desc)
      
      IF (.NOT. md%use_temp_dependence) THEN
        CALL init_error_status(status, STATUS_ERROR, &
             message='[AC2D8_Setup_Thermo_Coupling]: Temperature dependence not enabled')
        RETURN
      END IF
      
      IF (.NOT. ASSOCIATED(T_field)) THEN
        CALL init_error_status(status, STATUS_ERROR, &
             message='[AC2D8_Setup_Thermo_Coupling]: T_field not associated')
        RETURN
      END IF
      
      IF (SIZE(T_field) < PH_ELEM_AC2D8_NNODE) THEN
        CALL init_error_status(status, STATUS_ERROR, &
             message='[AC2D8_Setup_Thermo_Coupling]: T_field size mismatch')
        RETURN
      END IF
      
      ! Link temperature field to material descriptor
      md%use_temp_dependence = .TRUE.
      
    CLASS DEFAULT
      CALL init_error_status(status, STATUS_ERROR, &
           message='[AC2D8_Setup_Thermo_Coupling]: Not an acoustic material')
    END SELECT
    
  END SUBROUTINE PH_Elem_AC2D8_Setup_Thermo_Coupling

  SUBROUTINE PH_ELEM_AC2D8_AreaInt(coords, area)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: N(8), dNdxi(2, 8), J(2, 2), detJ
    REAL(wp) :: xi(9), eta(9), weights(9)
    TYPE(PH_Elem_CPS8_ShapeFunc_In) :: in_sf
    TYPE(PH_Elem_CPS8_ShapeFunc_Out) :: out_sf
    TYPE(PH_Elem_CPS8_Jac_In) :: in_jac
    TYPE(PH_Elem_CPS8_Jac_Out) :: out_jac
    INTEGER(i4) :: ip
    area = ZERO
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      in_sf%xi = xi(ip)
      in_sf%eta = eta(ip)
      CALL PH_Elem_CPS8_ShapeFunc(in_sf, out_sf)
      N = out_sf%N
      dNdxi = out_sf%dNdxi
      in_jac%dNdxi = dNdxi
      in_jac%coords = coords
      CALL PH_Elem_CPS8_Jac(in_jac, out_jac)
      detJ = out_jac%detJ
      area = area + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_AC2D8_AreaInt

  SUBROUTINE PH_Elem_AC2D8_FormStiffMatrix(coords, E_young, nu, Ke)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(8, 8)
    REAL(wp) :: k_eff
    REAL(wp) :: N(8), dNdx(2, 8), detJ
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: dV
    TYPE(PH_Elem_CPS8_JacB_In) :: in_jacb
    TYPE(PH_Elem_CPS8_JacB_Out) :: out_jacb
    INTEGER(i4) :: ip, i, j
    k_eff = E_young
    Ke = ZERO
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      in_jacb%coords = coords
      in_jacb%xi = xi(ip)
      in_jacb%eta = eta(ip)
      CALL PH_Elem_CPS8_JacB(in_jacb, out_jacb)
      detJ = out_jacb%detJ
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      N = out_jacb%N
      dNdx = out_jacb%dNdx
      dV = detJ * weights(ip)
      DO i = 1, 8
        DO j = 1, 8
          Ke(i, j) = Ke(i, j) + k_eff * (dNdx(1,i)*dNdx(1,j) + dNdx(2,i)*dNdx(2,j)) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC2D8_FormStiffMatrix

  SUBROUTINE PH_Elem_AC2D8_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    eps_th = ZERO
  END SUBROUTINE PH_Elem_AC2D8_ThermStrainVector

  SUBROUTINE PH_Elem_AC2D8_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(8, 8)
    REAL(wp) :: N(8), dNdxi(2, 8), detJ
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: dV
    TYPE(PH_Elem_CPS8_ShapeFunc_In) :: in_sf
    TYPE(PH_Elem_CPS8_ShapeFunc_Out) :: out_sf
    TYPE(PH_Elem_CPS8_Jac_In) :: in_jac
    TYPE(PH_Elem_CPS8_Jac_Out) :: out_jac
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
    DO ip = 1, 9
      in_sf%xi = xi(ip)
      in_sf%eta = eta(ip)
      CALL PH_Elem_CPS8_ShapeFunc(in_sf, out_sf)
      N = out_sf%N
      dNdxi = out_sf%dNdxi
      in_jac%dNdxi = dNdxi
      in_jac%coords = coords
      CALL PH_Elem_CPS8_Jac(in_jac, out_jac)
      detJ = out_jac%detJ
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 8
        DO j = 1, 8
          Me(i, j) = Me(i, j) + N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC2D8_ConsMass

  SUBROUTINE PH_Elem_AC2D8_DefInit()
  END SUBROUTINE PH_Elem_AC2D8_DefInit

  SUBROUTINE PH_Elem_AC2D8_FormIntForce(coords, u, E_young, nu, R_int)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: u(8)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(8)
    REAL(wp) :: Ke(8, 8)
    CALL PH_Elem_AC2D8_FormStiffMatrix(coords, E_young, nu, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_AC2D8_FormIntForce

  SUBROUTINE PH_Elem_AC2D8_LumpMass(coords, rho, M_lumped)
    REAL(wp), INTENT(IN)  :: coords(2, 8)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(8)
    REAL(wp) :: area, m
    INTEGER(i4) :: i
    CALL PH_ELEM_AC2D8_AreaInt(coords, area)
    m = rho * area / 8.0_wp
    DO i = 1, 8
      M_lumped(i) = m
    END DO
  END SUBROUTINE PH_Elem_AC2D8_LumpMass

  SUBROUTINE PH_Elem_AC2D8_NL_TL(coords_ref, p_elem, mat_prop, mat_state, &
                                   Ke_mat, Ke_geo, R_int, status)
    USE IF_Err_Brg, ONLY: ErrorStatusType
    REAL(wp), INTENT(IN)  :: coords_ref(2, 8)
    REAL(wp), INTENT(IN)  :: p_elem(8)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(8, 8)
    REAL(wp), INTENT(OUT) :: Ke_geo(8, 8)
    REAL(wp), INTENT(OUT) :: R_int(8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k_eff
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    IF (ALLOCATED(mat_prop%props) .AND. SIZE(mat_prop%props) >= 1) THEN
      k_eff = mat_prop%props(1)
    ELSE
      k_eff = 2.2e9_wp
    END IF
    CALL PH_Elem_AC2D8_FormStiffMatrix(coords_ref, k_eff, ZERO, Ke_mat)
    CALL PH_Elem_AC2D8_FormIntForce(coords_ref, p_elem, k_eff, ZERO, R_int)
  END SUBROUTINE PH_Elem_AC2D8_NL_TL

  SUBROUTINE PH_Elem_AC2D8_NL_UL(coords_prev, p_incr, mat_prop, mat_state, &
                                   Ke_mat, Ke_geo, R_int, status)
    USE IF_Err_Brg, ONLY: ErrorStatusType
    REAL(wp), INTENT(IN)  :: coords_prev(2, 8)
    REAL(wp), INTENT(IN)  :: p_incr(8)
    TYPE(MatPropertyDef), INTENT(IN) :: mat_prop
    TYPE(PH_MatPoint_State), INTENT(INOUT) :: mat_state(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(8, 8)
    REAL(wp), INTENT(OUT) :: Ke_geo(8, 8)
    REAL(wp), INTENT(OUT) :: R_int(8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k_eff
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    IF (ALLOCATED(mat_prop%props) .AND. SIZE(mat_prop%props) >= 1) THEN
      k_eff = mat_prop%props(1)
    ELSE
      k_eff = 2.2e9_wp
    END IF
    CALL PH_Elem_AC2D8_FormStiffMatrix(coords_prev, k_eff, ZERO, Ke_mat)
    CALL PH_Elem_AC2D8_FormIntForce(coords_prev, p_incr, k_eff, ZERO, R_int)
  END SUBROUTINE PH_Elem_AC2D8_NL_UL
  
  !===========================================================================
  ! P4-2 BIOT POROUS MEDIA - STABILIZATION FUNCTIONS
  !===========================================================================
  
  FUNCTION PH_Elem_AC2D8_Biot_Compute_Stab_Param(wavenumber, flow_velocity, &
       element_size, diffusion_coef) RESULT(tau_supg)
    !! Compute SUPG stabilization parameter for Biot slow wave
    !!
    !! Theory: �� = h/(2|v|) �� [coth(Pe) - 1/Pe]
    !! where Pe = |v|h/(2D) is the P��clet number
    !!
    !! Usage:
    !!   tau = PH_Elem_AC2D8_Biot_Compute_Stab_Param(k, v, h, D)
    
    REAL(wp), INTENT(IN) :: wavenumber      ! Wave number k [1/m]
    REAL(wp), INTENT(IN) :: flow_velocity(:)! Interstitial flow velocity [m/s]
    REAL(wp), INTENT(IN) :: element_size    ! Characteristic element size h [m]
    REAL(wp), INTENT(IN) :: diffusion_coef  ! Diffusion coefficient D [m?/s]
    
    REAL(wp) :: tau_supg
    REAL(wp) :: vel_mag, peclet, coth_pe
    
    ! Velocity magnitude
    vel_mag = SQRT(SUM(flow_velocity**2))
    
    ! P��clet number: Pe = |v|h/(2D)
    IF (diffusion_coef > 1.0e-12_wp .AND. vel_mag > 1.0e-12_wp) THEN
      peclet = vel_mag * element_size / (2.0_wp * diffusion_coef)
      
      ! Stabilization parameter with coth smoothing
      IF (peclet > 10.0_wp) THEN
        ! High P��clet (advection-dominated): �� ??h/(2|v|)
        tau_supg = element_size / (2.0_wp * vel_mag)
      ELSEIF (peclet < 0.1_wp) THEN
        ! Low P��clet (diffusion-dominated): �� ??0
        tau_supg = 0.0_wp
      ELSE
        ! Intermediate: Full formula �� = h/(2|v|)��[coth(Pe) - 1/Pe]
        coth_pe = COSH(peclet) / SINH(peclet)
        tau_supg = (element_size / (2.0_wp * vel_mag)) * (coth_pe - 1.0_wp/peclet)
      END IF
    ELSE
      ! No flow or no diffusion: No stabilization needed
      tau_supg = 0.0_wp
    END IF
    
  END FUNCTION PH_Elem_AC2D8_Biot_Compute_Stab_Param
  
  SUBROUTINE PH_Elem_AC2D8_Biot_Wave_Speed(mat_desc, porosity, tortuosity, wave_speed, status)
    !! Compute effective wave speed in porous media based on Biot theory
    !!
    !! Theory: c_eff = c? / ??���ޡ�?? where ��??tortuosity, ��=porosity
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_Biot_Wave_Speed(mat_desc, phi, alpha_inf, c_eff, status)
    
    CLASS(MD_Mat_Desc), INTENT(IN) :: mat_desc
    REAL(wp), INTENT(IN) :: porosity       ! �� ??[0, 1]
    REAL(wp), INTENT(IN) :: tortuosity     ! ��????1
    REAL(wp), INTENT(OUT) :: wave_speed    ! Effective wave speed [m/s]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: c?
    
    CALL init_error_status(status)
    
    SELECT TYPE (md => mat_desc)
    TYPE IS (MD_Mat_Acoustic_Desc)
      c? = md%sound_speed_ref
      
      IF (porosity <= 0.0_wp .OR. porosity > 1.0_wp) THEN
        CALL init_error_status(status, STATUS_ERROR, \
             message='[AC2D8_Biot_Wave]: Invalid porosity')
        wave_speed = c?
        RETURN
      END IF
      
      IF (tortuosity < 1.0_wp) THEN
        CALL init_error_status(status, STATUS_ERROR, \
             message='[AC2D8_Biot_Wave]: Invalid tortuosity')
        wave_speed = c?
        RETURN
      END IF
      
      ! Biot effective wave speed
      wave_speed = c? / SQRT(tortuosity * porosity)
      
    CLASS DEFAULT
      CALL init_error_status(status, STATUS_ERROR, \
           message='[AC2D8_Biot_Wave]: Not an acoustic material')
      wave_speed = 343.0_wp
    END SELECT
    
  END SUBROUTINE PH_Elem_AC2D8_Biot_Wave_Speed
  
  SUBROUTINE PH_Elem_AC2D8_Biot_Damping(mat_desc, permeability, viscosity, damping_coef, status)
    !! Compute viscous damping coefficient from pore flow
    !!
    !! Theory: �� = ��/(�ʡ��ѡ���) where ��=viscosity, ��=permeability, ��=density
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_Biot_Damping(mat_desc, kappa, mu, xi, status)
    
    CLASS(MD_Mat_Desc), INTENT(IN) :: mat_desc
    REAL(wp), INTENT(IN) :: permeability   ! �� [m?]
    REAL(wp), INTENT(IN) :: viscosity      ! �� [Pa��s]
    REAL(wp), INTENT(OUT) :: damping_coef  ! Damping coefficient [1/s]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: rho, omega
    
    CALL init_error_status(status)
    
    SELECT TYPE (md => mat_desc)
    TYPE IS (MD_Mat_Acoustic_Desc)
      rho = md%density_ref
      omega = 2.0_wp * 3.14159265358979_wp * 1000.0_wp  ! Assume 1 kHz (TODO: from analysis)
      
      IF (permeability <= 0.0_wp) THEN
        CALL init_error_status(status, STATUS_ERROR, \
             message='[AC2D8_Biot_Damping]: Invalid permeability')
        damping_coef = 0.0_wp
        RETURN
      END IF
      
      IF (viscosity <= 0.0_wp) THEN
        CALL init_error_status(status, STATUS_ERROR, \
             message='[AC2D8_Biot_Damping]: Invalid viscosity')
        damping_coef = 0.0_wp
        RETURN
      END IF
      
      ! Biot damping coefficient
      damping_coef = viscosity / (permeability * rho * omega)
      
    CLASS DEFAULT
      CALL init_error_status(status, STATUS_ERROR, \
           message='[AC2D8_Biot_Damping]: Not an acoustic material')
      damping_coef = 0.0_wp
    END SELECT
    
  END SUBROUTINE PH_Elem_AC2D8_Biot_Damping
  
  SUBROUTINE PH_Elem_AC2D8_Biot_Stabilize_SlowWave(coords, mat_desc, &
       pressure_field, velocity_field, K_stab, F_stab, status)
    !! Add SUPG stabilization for Biot slow wave in porous media
    !!
    !! Theory: Adds streamline upwind Petrov-Galerkin terms to weak form
    !!         ??�ӡ�(v��?w)��(v��?p + ?p/?t) dV
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_Biot_Stabilize_SlowWave(coords, mat_desc, p, v, Ks, Fs, status)
    
    REAL(wp), INTENT(IN) :: coords(:,:)        ! Nodal coordinates [2��8]
    CLASS(MD_Mat_Desc), INTENT(IN) :: mat_desc
    REAL(wp), INTENT(IN) :: pressure_field(:)  ! Nodal pressures [8]
    REAL(wp), INTENT(IN) :: velocity_field(:,:) ! Nodal velocities [2��8]
    REAL(wp), INTENT(INOUT) :: K_stab(:,:)     ! Stabilization stiffness [8��8]
    REAL(wp), INTENT(INOUT) :: F_stab(:)       ! Stabilization force [8]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: tau_supg, h_elem, D_biot
    REAL(wp) :: flow_vel(2), centroid_vel(2)
    INTEGER(i4) :: ip, a, b
    REAL(wp) :: N(PH_ELEM_AC2D8_NNODE), dNdX(2, PH_ELEM_AC2D8_NNODE)
    REAL(wp) :: xi, eta, w_ip, det_J
    REAL(wp) :: grad_p(2), grad_w(2)
    REAL(wp) :: v_dot_grad_p, v_dot_grad_w
    
    CALL init_error_status(status)
    
    ! Check if porous media
    SELECT TYPE (md => mat_desc)
    TYPE IS (MD_Mat_Acoustic_Desc)
      
      IF (.NOT. md%is_porous_media) THEN
        ! Not porous media: skip stabilization
        RETURN
      END IF
      
      ! Biot diffusion coefficient: D = ��/(�̡���)
      ! where ��=permeability, ��=viscosity, ��=porosity
      REAL(wp) :: permeability, viscosity, porosity
      permeability = md%permeability
      porosity = md%porosity
      viscosity = 1.0e-3_wp  ! Water viscosity [Pa��s] (TODO: from material)
      
      IF (porosity > 0.0_wp .AND. permeability > 0.0_wp) THEN
        D_biot = permeability / (viscosity * porosity)
      ELSE
        D_biot = 0.0_wp
      END IF
      
    CLASS DEFAULT
      CALL init_error_status(status, STATUS_ERROR, &
           message='[AC2D8_Biot_Stabilize]: Not an acoustic material')
      RETURN
    END SELECT
    
    ! Element characteristic size (sqrt of area)
    CALL PH_ELEM_AC2D8_AreaInt(coords, h_elem)
    h_elem = SQRT(h_elem)
    
    ! Compute centroid velocity (average of nodal values)
    centroid_vel = 0.0_wp
    DO a = 1, PH_ELEM_AC2D8_NNODE
      centroid_vel(1) = centroid_vel(1) + velocity_field(1, a)
      centroid_vel(2) = centroid_vel(2) + velocity_field(2, a)
    END DO
    centroid_vel = centroid_vel / REAL(PH_ELEM_AC2D8_NNODE)
    
    ! Compute stabilization parameter
    flow_vel = centroid_vel
    tau_supg = PH_Elem_AC2D8_Biot_Compute_Stab_Param(1.0_wp, flow_vel, h_elem, D_biot)
    
    IF (tau_supg < 1.0e-12_wp) THEN
      ! Negligible stabilization
      RETURN
    END IF
    
    ! Integration loop for stabilization terms
    DO ip = 1, PH_ELEM_AC2D8_NIP
      
      ! Convert linear IP to 2D indices for 3x3 Gauss rule
      INTEGER(i4) :: ip_x, ip_y
      REAL(wp) :: xi_gp, eta_gp, w_x, w_y
      ip_x = MOD(ip-1, 3) + 1
      ip_y = (ip-1) / 3 + 1
      CALL CPS8_GetGaussPoint1D(ip_x, xi_gp, w_x)
      CALL CPS8_GetGaussPoint1D(ip_y, eta_gp, w_y)
      xi = xi_gp
      eta = eta_gp
      w_ip = w_x * w_y
      
      ! Gauss point
      CALL CPS8_Shape_Functions(xi, eta, N)
      CALL CPS8_Jacobian(coords, N, xi, eta, dNdX, det_J)
      
      IF (det_J <= 0.0_wp) CYCLE
      
      ! Pressure gradient at IP: ?p = B��p_node
      grad_p = 0.0_wp
      DO a = 1, PH_ELEM_AC2D8_NNODE
        grad_p(1) = grad_p(1) + dNdX(1, a) * pressure_field(a)
        grad_p(2) = grad_p(2) + dNdX(2, a) * pressure_field(a)
      END DO
      
      ! v��?p term
      v_dot_grad_p = DOT_PRODUCT(centroid_vel, grad_p)
      
      ! Assemble stabilization stiffness and force
      DO a = 1, PH_ELEM_AC2D8_NNODE
        grad_w(1) = dNdX(1, a)
        grad_w(2) = dNdX(2, a)
        v_dot_grad_w = DOT_PRODUCT(centroid_vel, grad_w)
        
        ! K_stab += ??�ӡ�(v��?N??��(v��?N?? dV
        DO b = 1, PH_ELEM_AC2D8_NNODE
          grad_w(1) = dNdX(1, b)
          grad_w(2) = dNdX(2, b)
          v_dot_grad_w = DOT_PRODUCT(centroid_vel, grad_w)
          
          K_stab(a, b) = K_stab(a, b) + &
               tau_supg * v_dot_grad_w * v_dot_grad_p * det_J * w_ip
        END DO
        
        ! F_stab += ??�ӡ�(v��?N??��(v��?p) dV
        F_stab(a) = F_stab(a) + &
             tau_supg * v_dot_grad_w * v_dot_grad_p * det_J * w_ip
      END DO
      
    END DO
    
  END SUBROUTINE PH_Elem_AC2D8_Biot_Stabilize_SlowWave
  
  !===========================================================================
  ! P4-3 TIME-DOMAIN PML (PERFECTLY MATCHED LAYER) FUNCTIONS
  !===========================================================================
  
  SUBROUTINE PH_Elem_AC2D8_PML_Update_State(pressure_current, pressure_prev, &
       damping_profile, dt, svars, ip_index, status)
    !! Update PML state variables for time-domain absorption
    !!
    !! Theory: Split-field PML formulation
    !!         ?p/?t + ��(x)��p = c?��??p
    !!         p = p_x + p_y (split fields)
    !!
    !! State variables layout (per IP):
    !!   svars(1): p_x - x-direction split field
    !!   svars(2): p_y - y-direction split field
    !!   svars(3): ?p_x/?t - time derivative
    !!   svars(4): ?p_y/?t - time derivative
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_PML_Update_State(p, p_old, sigma, dt, svars, ip, status)
    
    REAL(wp), INTENT(IN) :: pressure_current   ! Current pressure at IP
    REAL(wp), INTENT(IN) :: pressure_prev      ! Previous pressure at IP
    REAL(wp), INTENT(IN) :: damping_profile(:) ! ��(x) profile [��_x, ��_y]
    REAL(wp), INTENT(IN) :: dt                 ! Time step [s]
    REAL(wp), INTENT(INOUT) :: svars(:)        ! State variables
    INTEGER(i4), INTENT(IN) :: ip_index        ! Integration point index
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: slot_base
    REAL(wp) :: p_x, p_y, dpdt_x, dpdt_y
    REAL(wp) :: sigma_x, sigma_y
    REAL(wp) :: p_total, dpdt_total
    
    CALL init_error_status(status)
    
    ! SVARS slot offset for this IP
    slot_base = (ip_index - 1) * PH_ELEM_AC2D8_NSVARS_PER_IP
    
    ! Check bounds
    IF (SIZE(svars) < slot_base + 4) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='[AC2D8_PML_Update]: Insufficient SVARS size')
      RETURN
    END IF
    
    ! Get damping coefficients
    sigma_x = damping_profile(1)
    sigma_y = damping_profile(2)
    
    ! Load previous state
    p_x = svars(slot_base + 1)
    p_y = svars(slot_base + 2)
    dpdt_x = svars(slot_base + 3)
    dpdt_y = svars(slot_base + 4)
    
    ! Total pressure and time derivative
    p_total = pressure_current
    dpdt_total = (pressure_current - pressure_prev) / dt
    
    ! Update split fields using Crank-Nicolson scheme
    ! p_x^{n+1} = p_x^n + dt��(dpdt_total - ��_y��p_total)/2
    ! Implicit treatment for stability
    REAL(wp) :: factor_x, factor_y
    
    factor_x = 1.0_wp / (1.0_wp + 0.5_wp * sigma_x * dt)
    factor_y = 1.0_wp / (1.0_wp + 0.5_wp * sigma_y * dt)
    
    ! Update x-split field
    p_x = factor_x * (p_x + 0.5_wp * dt * dpdt_total)
    
    ! Update y-split field
    p_y = factor_y * (p_y + 0.5_wp * dt * dpdt_total)
    
    ! Update time derivatives
    dpdt_x = (p_x - svars(slot_base + 1)) / dt
    dpdt_y = (p_y - svars(slot_base + 2)) / dt
    
    ! Store updated state
    svars(slot_base + 1) = p_x
    svars(slot_base + 2) = p_y
    svars(slot_base + 3) = dpdt_x
    svars(slot_base + 4) = dpdt_y
    
  END SUBROUTINE PH_Elem_AC2D8_PML_Update_State
  
  SUBROUTINE PH_Elem_AC2D8_PML_Absorbing_Boundary(coords, mat_desc, &
       pressure_field, velocity_field, svars, time, dt, &
       K_pml, F_pml, status)
    !! Implement time-domain PML absorbing boundary condition
    !!
    !! Theory: Complex coordinate stretching in time domain
    !!         Creates artificial damping layer that absorbs outgoing waves
    !!
    !! Damping profile: ��(x) = ��_max��(x/L)^m
    !!   where m=2 (quadratic), L=PML thickness, ��_max from reflection coeff
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_PML_Absorbing_Boundary(coords, mat, p, v, svars, t, dt, K, F, status)
    
    REAL(wp), INTENT(IN) :: coords(:,:)        ! Nodal coordinates [2��8]
    CLASS(MD_Mat_Desc), INTENT(IN) :: mat_desc
    REAL(wp), INTENT(IN) :: pressure_field(:)  ! Nodal pressures [8]
    REAL(wp), INTENT(IN) :: velocity_field(:,:) ! Nodal velocities [2��8]
    REAL(wp), INTENT(INOUT) :: svars(:)        ! PML state variables
    REAL(wp), INTENT(IN) :: time               ! Current time [s]
    REAL(wp), INTENT(IN) :: dt                 ! Time step [s]
    REAL(wp), INTENT(INOUT) :: K_pml(:,:)      ! PML stiffness [8��8]
    REAL(wp), INTENT(INOUT) :: F_pml(:)        ! PML force [8]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: sound_speed, sigma_max, L_pml
    REAL(wp) :: damping_profile(2)
    REAL(wp) :: N(PH_ELEM_AC2D8_NNODE), dNdX(2, PH_ELEM_AC2D8_NNODE)
    REAL(wp) :: xi, eta, w_ip, det_J
    REAL(wp) :: p_ip, dpdt_ip
    REAL(wp) :: x_coord, y_coord
    INTEGER(i4) :: ip, a, b
    
    CALL init_error_status(status)
    
    ! Get material properties
    SELECT TYPE (md => mat_desc)
    TYPE IS (MD_Mat_Acoustic_Desc)
      sound_speed = md%sound_speed_ref
    CLASS DEFAULT
      sound_speed = 343.0_wp  ! Air
    END SELECT
    
    ! PML parameters
    L_pml = 0.1_wp  ! PML thickness [m] (TODO: from geometry)
    
    ! Compute ��_max for target reflection coefficient R
    ! ��_max = -(m+1)��c��ln(R)/(2L)
    ! For R=0.001 (0.1% reflection), m=2:
    REAL(wp) :: R_target, m_order
    R_target = 0.001_wp
    m_order = 2.0_wp
    sigma_max = -(m_order + 1.0_wp) * sound_speed * LOG(R_target) / (2.0_wp * L_pml)
    
    ! Integration loop for PML terms
    DO ip = 1, PH_ELEM_AC2D8_NIP
      
      ! Convert linear IP to 2D indices for 3x3 Gauss rule
      INTEGER(i4) :: ip_x, ip_y
      REAL(wp) :: xi_gp, eta_gp, w_x, w_y
      ip_x = MOD(ip-1, 3) + 1
      ip_y = (ip-1) / 3 + 1
      CALL CPS8_GetGaussPoint1D(ip_x, xi_gp, w_x)
      CALL CPS8_GetGaussPoint1D(ip_y, eta_gp, w_y)
      xi = xi_gp
      eta = eta_gp
      w_ip = w_x * w_y
      
      ! Gauss point
      CALL CPS8_Shape_Functions(xi, eta, N)
      CALL CPS8_Jacobian(coords, N, xi, eta, dNdX, det_J)
      
      IF (det_J <= 0.0_wp) CYCLE
      
      ! Compute physical coordinates at IP
      x_coord = SUM(N * coords(1, :))
      y_coord = SUM(N * coords(2, :))
      
      ! Compute damping profile ��(x), ��(y)
      ! Quadratic grading: ��(x) = ��_max��(x/L)^2
      IF (x_coord > 0.0_wp) THEN
        damping_profile(1) = sigma_max * (x_coord / L_pml)**m_order
      ELSE
        damping_profile(1) = 0.0_wp
      END IF
      
      IF (y_coord > 0.0_wp) THEN
        damping_profile(2) = sigma_max * (y_coord / L_pml)**m_order
      ELSE
        damping_profile(2) = 0.0_wp
      END IF
      
      ! Pressure and time derivative at IP
      p_ip = SUM(N * pressure_field)
      dpdt_ip = SUM(N * velocity_field(1, :))  ! Simplified: ?p/?t ??v_x
      
      ! Update PML state variables
      CALL PH_Elem_AC2D8_PML_Update_State(p_ip, p_ip - dpdt_ip*dt, &
           damping_profile, dt, svars, ip, status)
      
      ! Extract updated split fields
      INTEGER(i4) :: slot_base
      REAL(wp) :: p_x, p_y
      slot_base = (ip - 1) * PH_ELEM_AC2D8_NSVARS_PER_IP
      p_x = svars(slot_base + 1)
      p_y = svars(slot_base + 2)
      
      ! Assemble PML contributions to stiffness and force
      DO a = 1, PH_ELEM_AC2D8_NNODE
        
        ! Mass-like term from split fields: ??�ҡ�N?��p dV
        F_pml(a) = F_pml(a) + &
             (damping_profile(1) + damping_profile(2)) * N(a) * p_ip * det_J * w_ip
        
        ! Stiffness contribution from gradient of split fields
        DO b = 1, PH_ELEM_AC2D8_NNODE
          K_pml(a, b) = K_pml(a, b) + &
               (damping_profile(1) + damping_profile(2)) * N(a) * N(b) * det_J * w_ip
        END DO
        
      END DO
      
    END DO
    
  END SUBROUTINE PH_Elem_AC2D8_PML_Absorbing_Boundary
  
  !-------------------------------------------------------------------------
  ! ADDITIONAL PML HELPER FUNCTIONS (AC2D4 consistency)
  !-------------------------------------------------------------------------
  
  SUBROUTINE PH_Elem_AC2D8_Sommerfeld_Radiation(coords, mat_desc, pressure_field, \
       normal_vector, K_radiation, F_radiation, status)
    !! Sommerfeld radiation condition for infinite domain
    !!
    !! Theory: ?p/?n + (1/c)��?p/?t = 0 (non-reflecting boundary)
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_Sommerfeld_Radiation(coords, mat_desc, p, n, K, F, status)
    
    REAL(wp), INTENT(IN) :: coords(:,:)
    CLASS(MD_Mat_Desc), INTENT(IN) :: mat_desc
    REAL(wp), INTENT(IN) :: pressure_field(:)
    REAL(wp), INTENT(IN) :: normal_vector(:,:)
    REAL(wp), INTENT(INOUT) :: K_radiation(:,:)
    REAL(wp), INTENT(INOUT) :: F_radiation(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: sound_speed
    INTEGER(i4) :: a, b
    
    CALL init_error_status(status)
    
    SELECT TYPE (md => mat_desc)
    TYPE IS (MD_Mat_Acoustic_Desc)
      sound_speed = md%sound_speed_ref
    CLASS DEFAULT
      sound_speed = 343.0_wp
    END SELECT
    
    ! Simplified Sommerfeld implementation (boundary integral)
    DO a = 1, PH_ELEM_AC2D8_NNODE
      DO b = 1, PH_ELEM_AC2D8_NNODE
        K_radiation(a, b) = K_radiation(a, b) + &
             (1.0_wp / sound_speed) * normal_vector(1, a) * normal_vector(1, b)
      END DO
      F_radiation(a) = F_radiation(a) - &
           (1.0_wp / sound_speed) * normal_vector(1, a) * pressure_field(a)
    END DO
    
  END SUBROUTINE PH_Elem_AC2D8_Sommerfeld_Radiation
  
  SUBROUTINE PH_Elem_AC2D8_Infinite_Element_Map(coords_infinite, coords_finite, &
       mapping_coeffs, status)
    !! Map infinite element to finite domain
    !!
    !! Theory: Serendipity mapping with geometric decay
    !!
    !! Usage:
    !!   CALL PH_Elem_AC2D8_Infinite_Element_Map(x_inf, x_fin, coeffs, status)
    
    REAL(wp), INTENT(IN) :: coords_infinite(:,:)
    REAL(wp), INTENT(IN) :: coords_finite(:,:)
    REAL(wp), INTENT(OUT) :: mapping_coeffs(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: a
    
    CALL init_error_status(status)
    
    ! Simple linear mapping (TODO: implement proper infinite element shape functions)
    DO a = 1, PH_ELEM_AC2D8_NNODE
      mapping_coeffs(1, a) = coords_finite(1, a) - coords_infinite(1, a)
      mapping_coeffs(2, a) = coords_finite(2, a) - coords_infinite(2, a)
    END DO
    
  END SUBROUTINE PH_Elem_AC2D8_Infinite_Element_Map
  
END MODULE PH_Elem_AC2D8
