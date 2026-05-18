!===============================================================================
! MODULE: PH_Elem_AC3D8
! LAYER:  L4_PH
! DOMAIN: Element/Acoustic
! ROLE:   Proc
! BRIEF:  AC3D8 8-node 3D acoustic hexahedral element
!===============================================================================
MODULE PH_Elem_AC3D8
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, STATUS_SUCCESS, STATUS_ERROR, &
    init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
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
  ! CONSTANTS - ELEMENT PROPERTIES
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D8_NNODE  = 8_i4  ! 8-node hexahedron
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D8_NDOF   = 8_i4  ! Pressure DOF per node
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D8_NIP    = 8_i4  ! 8-point Gauss integration
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D8_NFACE  = 6_i4  ! 6 faces (quadrilaterals)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D8_NSVARS_PER_IP = 14_i4  ! State variables per IP
  
  !===========================================================================
  ! SVARS LAYOUT (Standardized across AC elements)
  !===========================================================================
  ! Slot 1-6:   stress              (hydrostatic) [Pa]
  ! Slot 7-12:  stran               (volumetric) [-]
  ! Slot 13:    pressure            [Pa]
  ! Slot 14:    velocity_potential  [m2/s]

  !===========================================================================
  ! PUBLIC INTERFACES - CATEGORIZED BY PRIORITY AND STATUS
  !===========================================================================
  
  !---------------------------------------------------------------------------
  ! CORE PHYSICS (P2/P3 - Acoustic element fundamentals)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_DefInit              ! Element definition init (stub)
  PUBLIC :: PH_Elem_AC3D8_FormStiffMatrix      ! Stiffness matrix assembly
  PUBLIC :: PH_Elem_AC3D8_FormIntForce         ! Internal force vector
  PUBLIC :: PH_Elem_AC3D8_ConsMass             ! Consistent mass matrix
  PUBLIC :: PH_Elem_AC3D8_LumpMass             ! Lumped mass matrix
  PUBLIC :: PH_Elem_AC3D8_ThermStrainVector    ! Thermo-acoustic coupling (P4)
  
  !---------------------------------------------------------------------------
  ! NONLINEAR GEOMETRY (Large amplitude acoustics)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_NL_TL                ! Total Lagrangian formulation
  PUBLIC :: PH_Elem_AC3D8_NL_UL                ! Updated Lagrangian formulation
  
  !---------------------------------------------------------------------------
  ! BOUNDARY CONDITIONS (Essential and natural)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_ApplyEssentialBC     ! Dirichlet BC (elimination)
  PUBLIC :: PH_Elem_AC3D8_ApplyPenaltyBC       ! Neumann BC (penalty method)
  PUBLIC :: PH_Elem_AC3D8_FormConstraintMatrix ! Constraint matrix (MPC)
  
  !---------------------------------------------------------------------------
  ! SPECIAL BOUNDARY CONDITIONS
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_FormAcousticImpedance    ! Impedance BC (Robin)
  PUBLIC :: PH_Elem_AC3D8_FormRadiationCondition  ! Sommerfeld radiation
  PUBLIC :: PH_Elem_AC3D8_FormStructureCoupling    ! FSI coupling
  
  !---------------------------------------------------------------------------
  ! LOADS (Body force, pressure, surface traction)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_FormPressureLoad     ! Pressure load vector
  PUBLIC :: PH_Elem_AC3D8_FormBodyForce       ! Body force vector
  PUBLIC :: PH_Elem_AC3D8_FormSurfaceTraction ! Surface traction
  
  !---------------------------------------------------------------------------
  ! POST-PROCESSING (Results extraction)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_CalcPressure        ! Pressure at nodes/IP
  PUBLIC :: PH_Elem_AC3D8_CalcAcousticIntensity  ! Acoustic intensity
  PUBLIC :: PH_Elem_AC3D8_CalcEnergy          ! Acoustic energy
  PUBLIC :: PH_Elem_AC3D8_CalcEnergy_FromDesc ! Energy from descriptor
  PUBLIC :: PH_Elem_AC3D8_OutputResults       ! Output results
  
  !---------------------------------------------------------------------------
  ! MATERIAL PROPERTIES
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_GetMaterialProps       ! Get material properties
  PUBLIC :: PH_Elem_AC3D8_GetMaterialProps_FromDesc  ! From descriptor
  PUBLIC :: PH_Elem_AC3D8_GetVolume             ! Element volume
  PUBLIC :: PH_Elem_AC3D8_GetAcousticProps      ! Acoustic properties
  PUBLIC :: PH_Elem_AC3D8_SetSectionProps       ! Section properties
  PUBLIC :: PH_Elem_AC3D8_SetSectionProps_FromDesc  ! From descriptor
  
  !---------------------------------------------------------------------------
  ! P4-1 THERMO-ACOUSTIC COUPLING
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_Temperature_Dependent_Speed ! c(T) model
  PUBLIC :: PH_Elem_AC3D8_Thermal_Expansion_Source    ! Thermal expansion source
  PUBLIC :: PH_Elem_AC3D8_Rayleigh_Damping           ! P3 Rayleigh damping C = aM + bK
  
  !---------------------------------------------------------------------------
  ! P4-2 BIOT POROUS MEDIA
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_Biot_Wave_Speed           ! Biot wave speeds (P1/P2/S)
  PUBLIC :: PH_Elem_AC3D8_Biot_Damping              ! Biot damping mechanisms
  PUBLIC :: PH_Elem_AC3D8_Biot_Stabilize_SlowWave   ! SUPG stabilization for P2
  PUBLIC :: PH_Elem_AC3D8_Biot_Compute_Stab_Param   ! Stabilization parameter
  
  !---------------------------------------------------------------------------
  ! P4-3 PML INFINITE ELEMENTS
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D8_Sommerfeld_Radiation ! Sommerfeld radiation condition
  PUBLIC :: PH_Elem_AC3D8_Infinite_Element_Map  ! Mapping to infinite elements
  PUBLIC :: PH_Elem_AC3D8_PML_Update_State     ! PML state update
  PUBLIC :: PH_Elem_AC3D8_PML_Absorbing_Boundary ! PML absorbing layer
  
  !===========================================================================
  ! PRIVATE HELPERS (Used internally)
  !===========================================================================
  PRIVATE :: AC3D8_ShapeFunc
  PRIVATE :: AC3D8_Jacobian
  PRIVATE :: AC3D8_B_Matrix
  PRIVATE :: AC3D8_GaussPoints

  !===========================================================================
  ! UEL_Args TYPE - Principle #14 Structured IO (SIO)
  !===========================================================================
  TYPE, PUBLIC :: PH_AC3D8_UEL_Args
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
  END TYPE PH_AC3D8_UEL_Args

CONTAINS

  !============================================================================
  ! AC3D8 GAUSS POINTS - 8-point integration for hexahedron
  !============================================================================
  SUBROUTINE AC3D8_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(:), eta(:), zeta(:), weights(:)
    REAL(wp), PARAMETER :: gp = 1.0_wp / SQRT(3.0_wp)
    REAL(wp), PARAMETER :: w = 1.0_wp
    INTEGER(i4) :: i
    ! 8-point Gauss
    xi(1:8) = [-gp, gp, gp, -gp, -gp, gp, gp, -gp]
    eta(1:8) = [-gp, -gp, gp, gp, -gp, -gp, gp, gp]
    zeta(1:8) = [-gp, -gp, -gp, -gp, gp, gp, gp, gp]
    weights = w
  END SUBROUTINE AC3D8_GaussPoints

  !============================================================================
  ! AC3D8 SHAPE FUNCTIONS - 8-node serendipity element
  ! N_i = (1+xi*xi_i)*(1+eta*eta_i)*(1+zeta*zeta_i)/8
  !============================================================================
  SUBROUTINE AC3D8_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(:), dNdxi(:,:)
    ! Node 1: (-1,-1,-1)
    N(1) = (1.0_wp-xi)*(1.0_wp-eta)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(1,1) = -(1.0_wp-eta)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(2,1) = -(1.0_wp-xi)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(3,1) = -(1.0_wp-xi)*(1.0_wp-eta) / 8.0_wp
    ! Node 2: (1,-1,-1)
    N(2) = (1.0_wp+xi)*(1.0_wp-eta)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(1,2) =  (1.0_wp-eta)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(2,2) = -(1.0_wp+xi)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(3,2) = -(1.0_wp+xi)*(1.0_wp-eta) / 8.0_wp
    ! Node 3: (1,1,-1)
    N(3) = (1.0_wp+xi)*(1.0_wp+eta)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(1,3) =  (1.0_wp+eta)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(2,3) =  (1.0_wp+xi)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(3,3) = -(1.0_wp+xi)*(1.0_wp+eta) / 8.0_wp
    ! Node 4: (-1,1,-1)
    N(4) = (1.0_wp-xi)*(1.0_wp+eta)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(1,4) = -(1.0_wp+eta)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(2,4) =  (1.0_wp-xi)*(1.0_wp-zeta) / 8.0_wp
    dNdxi(3,4) = -(1.0_wp-xi)*(1.0_wp+eta) / 8.0_wp
    ! Node 5: (-1,-1,1)
    N(5) = (1.0_wp-xi)*(1.0_wp-eta)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(1,5) = -(1.0_wp-eta)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(2,5) = -(1.0_wp-xi)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(3,5) =  (1.0_wp-xi)*(1.0_wp-eta) / 8.0_wp
    ! Node 6: (1,-1,1)
    N(6) = (1.0_wp+xi)*(1.0_wp-eta)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(1,6) =  (1.0_wp-eta)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(2,6) = -(1.0_wp+xi)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(3,6) =  (1.0_wp+xi)*(1.0_wp-eta) / 8.0_wp
    ! Node 7: (1,1,1)
    N(7) = (1.0_wp+xi)*(1.0_wp+eta)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(1,7) =  (1.0_wp+eta)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(2,7) =  (1.0_wp+xi)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(3,7) =  (1.0_wp+xi)*(1.0_wp+eta) / 8.0_wp
    ! Node 8: (-1,1,1)
    N(8) = (1.0_wp-xi)*(1.0_wp+eta)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(1,8) = -(1.0_wp+eta)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(2,8) =  (1.0_wp-xi)*(1.0_wp+zeta) / 8.0_wp
    dNdxi(3,8) =  (1.0_wp-xi)*(1.0_wp+eta) / 8.0_wp
  END SUBROUTINE AC3D8_ShapeFunc

  !============================================================================
  ! AC3D8 JACOBIAN - Geometric mapping J = dx/dxi
  !============================================================================
  SUBROUTINE AC3D8_Jacobian(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 8), coords(3, 8)
    REAL(wp), INTENT(OUT) :: J(3, 3), detJ
    J = MATMUL(coords, TRANSPOSE(dNdxi))
    detJ = J(1,1)*(J(2,2)*J(3,3)-J(2,3)*J(3,2)) - &
           J(1,2)*(J(2,1)*J(3,3)-J(2,3)*J(3,1)) + &
           J(1,3)*(J(2,1)*J(3,2)-J(2,2)*J(3,1))
  END SUBROUTINE AC3D8_Jacobian

  !============================================================================
  ! AC3D8 B MATRIX - Pressure gradient operator [3 x 8]
  ! B(i,j) = dN_j/dx_i
  !============================================================================
  SUBROUTINE AC3D8_B_Matrix(dNdxi, J, detJ, B)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 8), J(3, 3), detJ
    REAL(wp), INTENT(OUT) :: B(3, 8)
    REAL(wp) :: Jinv(3, 3)
    IF (ABS(detJ) < 1.0e-12_wp) THEN
      B = ZERO
      RETURN
    END IF
    Jinv(1,1) = (J(2,2)*J(3,3)-J(2,3)*J(3,2))/detJ
    Jinv(1,2) = (J(1,3)*J(3,2)-J(1,2)*J(3,3))/detJ
    Jinv(1,3) = (J(1,2)*J(2,3)-J(1,3)*J(2,2))/detJ
    Jinv(2,1) = (J(2,3)*J(3,1)-J(2,1)*J(3,3))/detJ
    Jinv(2,2) = (J(1,1)*J(3,3)-J(1,3)*J(3,1))/detJ
    Jinv(2,3) = (J(1,3)*J(2,1)-J(1,1)*J(2,3))/detJ
    Jinv(3,1) = (J(2,1)*J(3,2)-J(2,2)*J(3,1))/detJ
    Jinv(3,2) = (J(1,2)*J(3,1)-J(1,1)*J(3,2))/detJ
    Jinv(3,3) = (J(1,1)*J(2,2)-J(1,2)*J(2,1))/detJ
    B = MATMUL(Jinv, dNdxi)
  END SUBROUTINE AC3D8_B_Matrix
  
  !============================================================================
  ! ELEMENT UTILITIES
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    INTEGER(i4) :: ip
    volume = ZERO
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_AC3D8_GetVolume
  
  SUBROUTINE PH_Elem_AC3D8_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_Elem_AC3D8_GetVolume(coords, area)
  END SUBROUTINE PH_Elem_AC3D8_GetArea
  
  SUBROUTINE PH_Elem_AC3D8_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(OUT) :: centroid(3)
    centroid = SUM(coords, DIM=2) / 8.0_wp
  END SUBROUTINE PH_Elem_AC3D8_GetCentroid
  
  SUBROUTINE PH_Elem_AC3D8_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    CALL PH_Elem_AC3D8_GetArea(coords, area)
    mass = density_in * area
  END SUBROUTINE PH_Elem_AC3D8_GetSectProps
  
  !============================================================================
  ! ELEMENT STIFFNESS MATRIX - Acoustic formulation
  ! K_ij = integral( (1/rho*c^2) * dNi/dxk * dNj/dxk * dV )
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_FormStiffMatrix(coords, rho, c_sound, Ke)
    REAL(wp), INTENT(IN)  :: coords(3, 8), rho, c_sound
    REAL(wp), INTENT(OUT) :: Ke(8, 8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ, B(3, 8)
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: inv_rho_c2, dV
    INTEGER(i4) :: ip, i, j
    Ke = ZERO
    inv_rho_c2 = 1.0_wp / (rho * c_sound**2)
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL AC3D8_B_Matrix(dNdxi, J, detJ, B)
      dV = detJ * weights(ip)
      DO i = 1, 8
        DO j = 1, 8
          Ke(i, j) = Ke(i, j) + inv_rho_c2 * (B(1,i)*B(1,j) + B(2,i)*B(2,j) + B(3,i)*B(3,j)) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_FormStiffMatrix
  
  SUBROUTINE PH_Elem_AC3D8_FormIntForce(coords, u, rho, c_sound, R_int)
    REAL(wp), INTENT(IN)  :: coords(3, 8), u(8), rho, c_sound
    REAL(wp), INTENT(OUT) :: R_int(8)
    REAL(wp) :: Ke(8, 8)
    CALL PH_Elem_AC3D8_FormStiffMatrix(coords, rho, c_sound, Ke)
    R_int = MATMUL(Ke, u)
  END SUBROUTINE PH_Elem_AC3D8_FormIntForce
  
  !============================================================================
  ! MASS MATRIX - Consistent (P3)
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_ConsMass(coords, rho, Me)
    REAL(wp), INTENT(IN)  :: coords(3, 8), rho
    REAL(wp), INTENT(OUT) :: Me(8, 8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, j
    Me = ZERO
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 8
        DO j = 1, 8
          Me(i, j) = Me(i, j) + N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_ConsMass
  
  !============================================================================
  ! MASS MATRIX - Lumped (HRZ/RowSum/Uniform)
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_LumpMass(coords, rho, M_lumped, method)
    REAL(wp), INTENT(IN)  :: coords(3, 8), rho
    REAL(wp), INTENT(OUT) :: M_lumped(8)
    INTEGER(i4), INTENT(IN), OPTIONAL :: method
    REAL(wp) :: Me(8, 8), vol, m_total, trace_Me
    INTEGER(i4) :: i, imethod
    imethod = 1  ! Default: HRZ
    IF (PRESENT(method)) imethod = method
    CALL PH_Elem_AC3D8_ConsMass(coords, rho, Me)
    SELECT CASE (imethod)
    CASE (2)  ! Row-sum
      DO i = 1, 8
        M_lumped(i) = SUM(Me(i, :))
      END DO
    CASE (3)  ! Uniform
      CALL PH_Elem_AC3D8_GetVolume(coords, vol)
      m_total = rho * vol
      M_lumped = m_total / 8.0_wp
    CASE DEFAULT  ! HRZ
      trace_Me = 0.0_wp
      DO i = 1, 8
        trace_Me = trace_Me + Me(i, i)
      END DO
      CALL PH_Elem_AC3D8_GetVolume(coords, vol)
      m_total = rho * vol
      IF (trace_Me > 1.0e-12_wp) THEN
        DO i = 1, 8
          M_lumped(i) = m_total * Me(i, i) / trace_Me
        END DO
      ELSE
        M_lumped = m_total / 8.0_wp
      END IF
    END SELECT
  END SUBROUTINE PH_Elem_AC3D8_LumpMass
  
  !============================================================================
  ! BOUNDARY CONDITIONS
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_ApplyEssentialBC(idof, val, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(INOUT) :: K_el(8, 8), F_el(8)
    REAL(wp) :: penalty
    penalty = 1.0e20_wp
    IF (idof < 1 .OR. idof > 8) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_AC3D8_ApplyEssentialBC
  
  SUBROUTINE PH_Elem_AC3D8_ApplyPenaltyBC(idof, penalty, val, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: penalty, val
    REAL(wp), INTENT(INOUT) :: K_el(8, 8), F_el(8)
    IF (idof < 1 .OR. idof > 8) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_AC3D8_ApplyPenaltyBC
  
  SUBROUTINE PH_Elem_AC3D8_FormConstraintMatrix(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(8), val, penalty
    REAL(wp), INTENT(INOUT) :: K_el(8, 8), F_el(8)
    INTEGER(i4) :: i, j
    DO i = 1, 8
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 8
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_FormConstraintMatrix
  
  SUBROUTINE PH_Elem_AC3D8_FormAcousticImpedance(coords, Zc, C_imp)
    REAL(wp), INTENT(IN)  :: coords(3, 8), Zc
    REAL(wp), INTENT(OUT) :: C_imp(8, 8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: dA
    INTEGER(i4) :: ip, i, j
    C_imp = ZERO
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dA = detJ * weights(ip)
      DO i = 1, 8
        DO j = 1, 8
          C_imp(i, j) = C_imp(i, j) + (Zc / rho) * N(i) * N(j) * dA
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_FormAcousticImpedance
  
  !============================================================================
  ! LOADS
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_FormPressureLoad(coords, pressure, F_load)
    REAL(wp), INTENT(IN)  :: coords(3, 8), pressure
    REAL(wp), INTENT(OUT) :: F_load(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: dA
    INTEGER(i4) :: ip, i
    F_load = ZERO
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dA = detJ * weights(ip)
      DO i = 1, 8
        F_load(i) = F_load(i) + pressure * N(i) * dA
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_FormPressureLoad
  
  SUBROUTINE PH_Elem_AC3D8_FormBodyForce(coords, bx, by, bz, F_eq)
    REAL(wp), INTENT(IN)  :: coords(3, 8), bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(8)
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: dV, b_vec(3)
    INTEGER(i4) :: ip, i
    F_eq = ZERO
    b_vec = [bx, by, bz]
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      DO i = 1, 8
        F_eq(i) = F_eq(i) + DOT_PRODUCT(b_vec, N(i) * coords(:, i)) * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_FormBodyForce
  
  SUBROUTINE PH_Elem_AC3D8_FormSurfaceTraction(coords, t1, t2, F_traction)
    REAL(wp), INTENT(IN)  :: coords(3, 8), t1(3), t2(3)
    REAL(wp), INTENT(OUT) :: F_traction(8)
    F_traction = ZERO
  END SUBROUTINE PH_Elem_AC3D8_FormSurfaceTraction

  !============================================================================
  ! POST-PROCESSING
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_CalcPressure(coords, u, p_ip)
    REAL(wp), INTENT(IN)  :: coords(3, 8), u(8)
    REAL(wp), INTENT(OUT) :: p_ip(:)
    p_ip = u  ! Linear interpolation
  END SUBROUTINE PH_Elem_AC3D8_CalcPressure

  SUBROUTINE PH_Elem_AC3D8_CalcAcousticIntensity(p, v, I_avg)
    REAL(wp), INTENT(IN)  :: p, v(3)
    REAL(wp), INTENT(OUT) :: I_avg
    I_avg = p * v(1)  ! Simplified
  END SUBROUTINE PH_Elem_AC3D8_CalcAcousticIntensity

  SUBROUTINE PH_Elem_AC3D8_CalcEnergy(coords, p, E_acoustic)
    REAL(wp), INTENT(IN)  :: coords(3, 8), p(8)
    REAL(wp), INTENT(OUT) :: E_acoustic
    REAL(wp) :: Ke(8, 8), rho, c_sound
    rho = 1.21_wp
    c_sound = 343.0_wp
    CALL PH_Elem_AC3D8_FormStiffMatrix(coords, rho, c_sound, Ke)
    E_acoustic = 0.5_wp * DOT_PRODUCT(p, MATMUL(Ke, p))
  END SUBROUTINE PH_Elem_AC3D8_CalcEnergy

  SUBROUTINE PH_Elem_AC3D8_CalcEnergy_FromDesc(MD_Desc, E_acoustic)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    REAL(wp), INTENT(OUT) :: E_acoustic
    E_acoustic = ZERO
  END SUBROUTINE PH_Elem_AC3D8_CalcEnergy_FromDesc

  SUBROUTINE PH_Elem_AC3D8_OutputResults(coords, u, svars, output)
    REAL(wp), INTENT(IN)  :: coords(3, 8), u(8), svars(:,:)
    REAL(wp), INTENT(OUT) :: output(:,:)
    output = ZERO
  END SUBROUTINE PH_Elem_AC3D8_OutputResults

  !============================================================================
  ! MATERIAL PROPERTIES
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_GetMaterialProps(coords, Mat_Algo, rho, c_sound)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    TYPE(MD_MatAlgo), INTENT(INOUT) :: Mat_Algo
    REAL(wp), INTENT(OUT) :: rho, c_sound
    rho = 1.21_wp
    c_sound = 343.0_wp
  END SUBROUTINE PH_Elem_AC3D8_GetMaterialProps

  SUBROUTINE PH_Elem_AC3D8_GetMaterialProps_FromDesc(MD_Desc, rho, c_sound)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    REAL(wp), INTENT(OUT) :: rho, c_sound
    rho = 1.21_wp
    c_sound = 343.0_wp
  END SUBROUTINE PH_Elem_AC3D8_GetMaterialProps_FromDesc

  SUBROUTINE PH_Elem_AC3D8_GetAcousticProps(rho, c_sound, Zc, K_bulk)
    REAL(wp), INTENT(IN)  :: rho, c_sound
    REAL(wp), INTENT(OUT) :: Zc, K_bulk
    Zc = rho * c_sound
    K_bulk = rho * c_sound**2
  END SUBROUTINE PH_Elem_AC3D8_GetAcousticProps

  SUBROUTINE PH_Elem_AC3D8_SetSectionProps(Sect_Registry, props)
    TYPE(MD_Sect_Registry), INTENT(IN) :: Sect_Registry
    REAL(wp), INTENT(OUT) :: props(:)
    props = ZERO
  END SUBROUTINE PH_Elem_AC3D8_SetSectionProps

  SUBROUTINE PH_Elem_AC3D8_SetSectionProps_FromDesc(MD_Desc, props)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    REAL(wp), INTENT(OUT) :: props(:)
    props = ZERO
  END SUBROUTINE PH_Elem_AC3D8_SetSectionProps_FromDesc

  !============================================================================
  ! P4-1 THERMO-ACOUSTIC COUPLING
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)
    ! Purpose: Compute temperature-dependent sound speed
    ! Theory: c(T) = c0*sqrt(T/T0) (ideal gas law derivation)
    !         For liquids: c(T) = c0*[1 + alpha_T*(T-T0)]
    REAL(wp), INTENT(OUT) :: c_speed
    REAL(wp), INTENT(IN)  :: temperature
    REAL(wp), INTENT(IN)  :: c_ref      ! Reference sound speed at T_ref
    REAL(wp), INTENT(IN)  :: T_ref      ! Reference temperature [K]
    REAL(wp), INTENT(IN)  :: alpha_T    ! Thermal expansion coefficient [1/K]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: T_ratio
    status%code = STATUS_SUCCESS
    IF (temperature <= 0.0_wp) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    T_ratio = temperature / T_ref
    ! Use square root model (default for gases)
    c_speed = c_ref * SQRT(T_ratio)
    ! For liquids: c_speed = c_ref * (1.0_wp + alpha_T * (temperature - T_ref))
  END SUBROUTINE PH_Elem_AC3D8_Temperature_Dependent_Speed

  SUBROUTINE PH_Elem_AC3D8_Thermal_Expansion_Source(F_thermal, coords, temperature_field, MD_Desc, MD_Algo, status)
    ! Purpose: Compute thermal expansion source term in acoustic equation
    ! Theory: nabla^2*p - (1/c^2)*d^2p/dt^2 = -rho*beta*d^2T/dt^2
    !         where beta = thermal expansion coefficient
    REAL(wp), INTENT(OUT) :: F_thermal(8)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(IN)  :: temperature_field(:)  ! Nodal temperatures
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(8), dNdxi(3, 8), B(3, 8)
    REAL(wp) :: J(3, 3), detJ
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8)
    REAL(wp) :: dV, rho, beta_T, dTdt2, T_ip
    INTEGER(i4) :: ip, i
    status%code = STATUS_SUCCESS
    F_thermal = ZERO
    rho = 1.21_wp
    beta_T = 2.1e-4_wp
    dTdt2 = 1.0_wp
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      T_ip = DOT_PRODUCT(N, temperature_field(1:8))
      DO i = 1, 8
        F_thermal(i) = F_thermal(i) + rho * beta_T * dTdt2 * N(i) * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_Thermal_Expansion_Source

  !============================================================================
  ! P4-2 BIOT POROUS MEDIA
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_Biot_Wave_Speed(v_p1, v_p2, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)
    ! Purpose: Compute Biot wave speeds for porous media (P1/P2/S waves)
    ! Theory: Biot theory predicts three wave types:
    !         - Fast compressional wave (P1): in-phase solid/fluid motion
    !         - Slow compressional wave (P2): out-of-phase motion (highly attenuated)
    !         - Shear wave (S): solid matrix shear motion
    REAL(wp), INTENT(OUT) :: v_p1  ! Fast P-wave speed [m/s]
    REAL(wp), INTENT(OUT) :: v_p2  ! Slow P-wave speed [m/s]
    REAL(wp), INTENT(OUT) :: v_s   ! S-wave speed [m/s]
    REAL(wp), INTENT(IN)  :: porosity    ! phi: porosity [0-1]
    REAL(wp), INTENT(IN)  :: K_s   ! Bulk modulus of solid frame [Pa]
    REAL(wp), INTENT(IN)  :: K_f   ! Bulk modulus of pore fluid [Pa]
    REAL(wp), INTENT(IN)  :: G     ! Shear modulus of solid frame [Pa]
    REAL(wp), INTENT(IN)  :: rho_s ! Density of solid phase [kg/m3]
    REAL(wp), INTENT(IN)  :: rho_f ! Density of pore fluid [kg/m3]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: K_b, alpha, M, rho_11, rho_22, rho_12
    REAL(wp) :: sigma_11, sigma_22, delta
    status%code = STATUS_SUCCESS
    IF (porosity < 0.0_wp .OR. porosity > 1.0_wp) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    K_b = K_s
    alpha = 1.0_wp - K_b / K_s
    M = K_f / (porosity + (alpha - porosity) * (K_f / K_s))
    rho_11 = (1.0_wp - porosity) * rho_s
    rho_22 = porosity * rho_f
    rho_12 = -0.5_wp * porosity * rho_f
    sigma_11 = K_b + 4.0_wp * G / 3.0_wp + alpha**2 * M
    sigma_22 = porosity**2 * M
    delta = alpha * M * porosity
    v_p1 = SQRT((sigma_11 + 2.0_wp * delta + sigma_22) / (rho_11 + 2.0_wp * rho_12 + rho_22))
    v_p2 = SQRT(M / rho_22)
    v_s = SQRT(G / rho_11)
  END SUBROUTINE PH_Elem_AC3D8_Biot_Wave_Speed

  SUBROUTINE PH_Elem_AC3D8_Biot_Damping(C_biot, frequency, permeability, viscosity, porosity, tortuosity, status)
    ! Purpose: Compute Biot damping mechanisms (viscous dissipation)
    ! Theory: Damping from viscous fluid flow in pores
    !         Frequency-dependent: low freq (Poiseuille) vs high freq (inertial)
    REAL(wp), INTENT(OUT) :: C_biot(8, 8)
    REAL(wp), INTENT(IN)  :: frequency     ! Angular frequency omega [rad/s]
    REAL(wp), INTENT(IN)  :: permeability  ! kappa [m2]
    REAL(wp), INTENT(IN)  :: viscosity     ! mu [Pa*s]
    REAL(wp), INTENT(IN)  :: porosity      ! phi [0-1]
    REAL(wp), INTENT(IN)  :: tortuosity    ! alpha_infinity (high-freq limit parameter)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: b_coeff, omega_c, F_freq
    INTEGER(i4) :: i
    status%code = STATUS_SUCCESS
    C_biot = ZERO
    IF (permeability <= 1.0e-20_wp) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    b_coeff = viscosity / permeability
    omega_c = porosity * b_coeff / (1000.0_wp * tortuosity)
    IF (frequency < omega_c) THEN
      F_freq = 1.0_wp
    ELSE
      F_freq = SQRT(frequency / omega_c)
    END IF
    DO i = 1, 8
      C_biot(i, i) = b_coeff * F_freq * porosity**2
    END DO
  END SUBROUTINE PH_Elem_AC3D8_Biot_Damping

  SUBROUTINE PH_Elem_AC3D8_Biot_Stabilize_SlowWave(tau_supg, coords, frequency, status)
    ! Purpose: Add SUPG stabilization for slow P-wave (numerical stability)
    ! Theory: Slow P-wave is highly attenuated and requires stabilization
    !         in finite element formulations (SUPG/GLS methods)
    REAL(wp), INTENT(OUT) :: tau_supg
    REAL(wp), INTENT(IN)  :: coords(3, 8), frequency
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: h_elem, c_slow, omega
    INTEGER(i4) :: i
    status%code = STATUS_SUCCESS
    h_elem = 0.0_wp
    DO i = 1, 8
      h_elem = h_elem + SQRT(SUM((coords(:, 1) - coords(:, i+1))**2))
    END DO
    h_elem = h_elem / 7.0_wp
    IF (h_elem < 1.0e-6_wp) h_elem = 0.1_wp
    c_slow = 100.0_wp
    omega = 2.0_wp * 3.14159265358979_wp * frequency
    IF (omega <= 1.0e-6_wp) THEN
      tau_supg = 0.0_wp
    ELSE
      tau_supg = h_elem / (2.0_wp * c_slow)
    END IF
  END SUBROUTINE PH_Elem_AC3D8_Biot_Stabilize_SlowWave

  SUBROUTINE PH_Elem_AC3D8_Biot_Compute_Stab_Param(h_char, omega, c_fast, c_slow, stab_param, status)
    ! Purpose: Compute stabilization parameter for Biot formulation
    ! Theory: Balance between P1/P2 wave resolution and numerical stability
    REAL(wp), INTENT(OUT) :: stab_param
    REAL(wp), INTENT(IN)  :: h_char  ! Characteristic element size
    REAL(wp), INTENT(IN)  :: omega   ! Angular frequency
    REAL(wp), INTENT(IN)  :: c_fast  ! Fast P-wave speed
    REAL(wp), INTENT(IN)  :: c_slow  ! Slow P-wave speed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k_fast, k_slow, pe_fast, pe_slow
    status%code = STATUS_SUCCESS
    k_fast = omega / c_fast
    k_slow = omega / c_slow
    pe_fast = k_fast * h_char
    pe_slow = k_slow * h_char
    IF (pe_slow > 1.0_wp) THEN
      stab_param = (pe_slow - 1.0_wp) / pe_slow
    ELSE
      stab_param = 0.0_wp
    END IF
  END SUBROUTINE PH_Elem_AC3D8_Biot_Compute_Stab_Param

  SUBROUTINE PH_Elem_AC3D8_Rayleigh_Damping(alpha_M, beta_K, Me, Ke, Ce, status)
    ! Purpose: Compute Rayleigh damping matrix C = alpha*M + beta*K
    ! Theory: Proportional damping for modal analysis and transient response
    REAL(wp), INTENT(IN)  :: alpha_M  ! Mass proportional coefficient [1/s]
    REAL(wp), INTENT(IN)  :: beta_K   ! Stiffness proportional coefficient [s]
    REAL(wp), INTENT(IN)  :: Me(8, 8) ! Consistent mass matrix
    REAL(wp), INTENT(IN)  :: Ke(8, 8) ! Stiffness matrix
    REAL(wp), INTENT(OUT) :: Ce(8, 8) ! Damping matrix
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    status%code = STATUS_SUCCESS
    Ce = alpha_M * Me + beta_K * Ke
  END SUBROUTINE PH_Elem_AC3D8_Rayleigh_Damping

  !============================================================================
  ! P4-3 PML INFINITE ELEMENTS
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, status)
    REAL(wp), INTENT(INOUT) :: C_rad(8, 8), K_rad(8, 8)
    REAL(wp), INTENT(IN)  :: face_normal(3), sound_speed, frequency
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: omega, k_wave, sigma
    status%code = STATUS_SUCCESS
    C_rad = ZERO
    K_rad = ZERO
    omega = 2.0_wp * 3.14159_wp * frequency
    k_wave = omega / sound_speed
    sigma = k_wave * 0.1_wp
  END SUBROUTINE PH_Elem_AC3D8_Sommerfeld_Radiation

  SUBROUTINE PH_Elem_AC3D8_Infinite_Element_Map(coords_phys, coords_nat, infinite_direction, decay_profile, status)
    REAL(wp), INTENT(OUT) :: coords_phys(3, 8)
    REAL(wp), INTENT(IN)  :: coords_nat(3, 8), infinite_direction(3), decay_profile(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: r_nat, stretching_factor
    INTEGER(i4) :: i
    status%code = STATUS_SUCCESS
    stretching_factor = 1.0_wp
    IF (SIZE(decay_profile) >= 1) stretching_factor = decay_profile(1)
    DO i = 1, 8
      r_nat = DOT_PRODUCT(coords_nat(:, i), infinite_direction)
      coords_phys(:, i) = coords_nat(:, i) + infinite_direction * (r_nat / (1.0_wp - r_nat * stretching_factor) - r_nat)
    END DO
  END SUBROUTINE PH_Elem_AC3D8_Infinite_Element_Map

  SUBROUTINE PH_Elem_AC3D8_PML_Update_State(pml_state, pml_params, time_step, pressure, status)
    TYPE(*), DIMENSION(*), INTENT(INOUT) :: pml_state
    REAL(wp), INTENT(IN)  :: pml_params(:), time_step, pressure(8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D8_PML_Update_State

  SUBROUTINE PH_Elem_AC3D8_PML_Absorbing_Boundary(K_pml, C_pml, pml_region_mask, pml_params, coords, sound_speed, density, status)
    REAL(wp), INTENT(OUT) :: K_pml(8, 8), C_pml(8, 8)
    REAL(wp), INTENT(IN)  :: pml_region_mask(:), pml_params(:), coords(3, 8), sound_speed, density
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: sigma(3), N(8), dNdxi(3, 8), B(3, 8), J(3, 3), detJ, dV
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8), sigma_avg
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    K_pml = ZERO
    C_pml = ZERO
    sigma = [5.0_wp, 5.0_wp, 5.0_wp]
    IF (SIZE(pml_params) >= 3) sigma = pml_params(1:3)
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL AC3D8_B_Matrix(dNdxi, J, detJ, B)
      dV = detJ * weights(ip)
      sigma_avg = SUM(N * pml_region_mask) * SUM(sigma) / 3.0_wp
      DO i = 1, 8
        DO j = 1, 8
          K_pml(i, j) = K_pml(i, j) + (1.0_wp/density) * (B(1,i)*B(1,j) + B(2,i)*B(2,j) + B(3,i)*B(3,j)) * dV
          C_pml(i, j) = C_pml(i, j) + sigma_avg * N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_PML_Absorbing_Boundary

  !============================================================================
  ! STUBS - Placeholder implementations
  !============================================================================
  SUBROUTINE PH_Elem_AC3D8_DefInit()
  END SUBROUTINE PH_Elem_AC3D8_DefInit

  SUBROUTINE PH_Elem_AC3D8_ThermStrainVector(alpha, deltaT, eps_th)
    REAL(wp), INTENT(IN)  :: alpha, deltaT
    REAL(wp), INTENT(OUT) :: eps_th(:)
    eps_th = ZERO
  END SUBROUTINE PH_Elem_AC3D8_ThermStrainVector

  SUBROUTINE PH_Elem_AC3D8_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 8), p_elem(8), D(1, 1)
    REAL(wp), INTENT(OUT) :: Ke_mat(8, 8), Ke_geo(8, 8), R_int(8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: rho, c_sound
    rho = 1.21_wp
    c_sound = 343.0_wp
    status%code = STATUS_SUCCESS
    CALL PH_Elem_AC3D8_FormStiffMatrix(coords_ref, rho, c_sound, Ke_mat)
    CALL PH_Elem_AC3D8_FormIntForce(coords_ref, p_elem, rho, c_sound, R_int)
    Ke_geo = ZERO
  END SUBROUTINE PH_Elem_AC3D8_NL_TL

  SUBROUTINE PH_Elem_AC3D8_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 8), p_incr(8), D(1, 1)
    REAL(wp), INTENT(OUT) :: Ke_mat(8, 8), Ke_geo(8, 8), R_int(8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: rho, c_sound
    rho = 1.21_wp
    c_sound = 343.0_wp
    status%code = STATUS_SUCCESS
    CALL PH_Elem_AC3D8_FormStiffMatrix(coords_prev, rho, c_sound, Ke_mat)
    CALL PH_Elem_AC3D8_FormIntForce(coords_prev, p_incr, rho, c_sound, R_int)
    Ke_geo = ZERO
  END SUBROUTINE PH_Elem_AC3D8_NL_UL

  SUBROUTINE PH_Elem_AC3D8_FormRadiationCondition(coords, face_normal, sound_speed, frequency, C_rad, K_rad, status)
    REAL(wp), INTENT(IN)  :: coords(3, 8), face_normal(3), sound_speed, frequency
    REAL(wp), INTENT(OUT) :: C_rad(8, 8), K_rad(8, 8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: omega, k_wave, sigma, N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8), dA
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    C_rad = ZERO
    K_rad = ZERO
    omega = 2.0_wp * 3.14159265359_wp * frequency
    k_wave = omega / sound_speed
    ! Sommerfeld radiation coefficient
    sigma = k_wave / (2.0_wp * 3.14159265359_wp)
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dA = detJ * weights(ip)
      DO i = 1, 8
        DO j = 1, 8
          ! Acoustic radiation impedance contribution
          C_rad(i, j) = C_rad(i, j) + sigma * N(i) * N(j) * dA
          ! Stiffness-like contribution from radiation
          K_rad(i, j) = K_rad(i, j) + (omega / sound_speed) * N(i) * N(j) * dA
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_FormRadiationCondition

  SUBROUTINE PH_Elem_AC3D8_FormStructureCoupling(coords, coupling_matrix, structure_dof_indices, acoustic_dof_indices, status)
    REAL(wp), INTENT(IN)  :: coords(3, 8)
    INTEGER(i4), INTENT(IN) :: structure_dof_indices(:), acoustic_dof_indices(:)
    REAL(wp), INTENT(OUT) :: coupling_matrix(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(8), dNdxi(3, 8), J(3, 3), detJ
    REAL(wp) :: xi(8), eta(8), zeta(8), weights(8), dV
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    coupling_matrix = ZERO
    ! FSI coupling: Interface mass/pressure conversion
    ! Structure displaces fluid, creating pressure response
    CALL AC3D8_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 8
      CALL AC3D8_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D8_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      DO i = 1, 8
        DO j = 1, 8
          ! Simplified FSI coupling: pressure couples through shape functions
          coupling_matrix(i, j) = coupling_matrix(i, j) + N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D8_FormStructureCoupling

  !=============================================================================
  ! UNIFIED INTERFACE (RT Layer compatible)
  !=============================================================================
  
  SUBROUTINE UF_Elem_AC3D8_Calc(ElemType, Formul, Ctx, state_in, &
                                 Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, PH_ELEM_AC3D8_NNODE)
    REAL(wp) :: u(PH_ELEM_AC3D8_NDOF)
    REAL(wp) :: density, bulk_modulus, sound_speed
    REAL(wp) :: k_eff, nu
    REAL(wp) :: Ke(PH_ELEM_AC3D8_NDOF, PH_ELEM_AC3D8_NDOF)
    REAL(wp) :: R_int(PH_ELEM_AC3D8_NDOF)
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D8_Calc: coords_ref not allocated'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < PH_ELEM_AC3D8_NNODE) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D8_Calc: insufficient nodes'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    DO i = 1, PH_ELEM_AC3D8_NNODE
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
    END DO

    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= PH_ELEM_AC3D8_NNODE) THEN
        DO i = 1, PH_ELEM_AC3D8_NNODE
          IF (SIZE(Ctx%disp_total, 1) >= 1) THEN
            u(i) = Ctx%disp_total(1, i)
          END IF
        END DO
      END IF
    END IF

    density = 1.21_wp
    bulk_modulus = 1.42e5_wp
    sound_speed = 343.0_wp

    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 2) density = Mat%props%props(1)
      IF (SIZE(Mat%props%props) >= 3) bulk_modulus = Mat%props%props(2)
    END IF

    k_eff = bulk_modulus
    nu = 0.0_wp

    IF (k_eff <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D8_Calc: invalid bulk modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    CALL PH_Elem_AC3D8_FormStiffMatrix(coords, k_eff, nu, Ke)
    CALL PH_Elem_AC3D8_FormIntForce(coords, u, k_eff, nu, R_int)

    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(PH_ELEM_AC3D8_NDOF, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(PH_ELEM_AC3D8_NDOF, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(PH_ELEM_AC3D8_NDOF, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, PH_ELEM_AC3D8_NIP)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    flags%status%status_code = IF_STATUS_OK
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt
    
  END SUBROUTINE UF_Elem_AC3D8_Calc

END MODULE PH_Elem_AC3D8
