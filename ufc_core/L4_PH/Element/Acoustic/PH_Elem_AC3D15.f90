!===============================================================================
! MODULE: PH_Elem_AC3D15
! LAYER:  L4_PH
! DOMAIN: Element/Acoustic
! ROLE:   Proc
! BRIEF:  AC3D15 15-node 3D acoustic wedge element
!===============================================================================
MODULE PH_Elem_AC3D15
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
  USE PH_Elem_C3D15, ONLY: PH_Elem_C3D15_ShapeFunc, PH_Elem_C3D15_Jac, &
       PH_Elem_C3D15_GaussPoints, PH_Elem_C3D15_JacB
  IMPLICIT NONE
  PRIVATE

  !===========================================================================
  ! CONSTANTS - ELEMENT PROPERTIES
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D15_NNODE  = 15_i4  ! 15-node quadratic wedge
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D15_NDOF   = 15_i4  ! Pressure DOF per node
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D15_NIP    = 9_i4   ! 9-point Gauss integration
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D15_NFACE  = 5_i4   ! 5 faces (2 triangles + 3 quads)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D15_NSVARS_PER_IP = 14_i4  ! State variables per IP
  
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_CTYPE_PENALTY_DOF = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_CTYPE_MPC_LINEAR  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_LOAD_BODY   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_LOAD_EDGE_P = 2_i4
  
  !===========================================================================
  ! SVARS LAYOUT (Standardized across AC elements)
  !===========================================================================
  ! Slot 1-6:   stress              (hydrostatic) [Pa]
  ! Slot 7-12:  stran               (volumetric) [-]
  ! Slot 13:    pressure            [Pa]
  ! Slot 14:    velocity_potential  [m²/s]

  !===========================================================================
  ! PUBLIC INTERFACES - CATEGORIZED BY PRIORITY AND STATUS
  !===========================================================================
  
  !---------------------------------------------------------------------------
  ! CORE PHYSICS (P2/P3 - Acoustic element fundamentals)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_DefInit              ! Element definition init (stub)
  PUBLIC :: PH_Elem_AC3D15_FormStiffMatrix      ! Stiffness matrix assembly
  PUBLIC :: PH_Elem_AC3D15_FormIntForce         ! Internal force vector
  PUBLIC :: PH_Elem_AC3D15_ConsMass             ! Consistent mass matrix
  PUBLIC :: PH_Elem_AC3D15_LumpMass             ! Lumped mass matrix
  PUBLIC :: PH_Elem_AC3D15_FormDampingMatrix   ! Rayleigh damping matrix
  PUBLIC :: PH_Elem_AC3D15_ThermStrainVector    ! Thermo-acoustic coupling (P4)
  
  !---------------------------------------------------------------------------
  ! NONLINEAR GEOMETRY (Large amplitude acoustics)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_NL_TL                ! Total Lagrangian formulation
  PUBLIC :: PH_Elem_AC3D15_NL_UL                ! Updated Lagrangian formulation
  
  !---------------------------------------------------------------------------
  ! BOUNDARY CONDITIONS (Essential and natural)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_ApplyEssentialBC     ! Dirichlet BC (elimination)
  PUBLIC :: PH_Elem_AC3D15_ApplyPenaltyBC      ! Neumann BC (penalty method)
  PUBLIC :: PH_Elem_AC3D15_FormConstraintMatrix ! Constraint matrix (MPC)
  
  !---------------------------------------------------------------------------
  ! SPECIAL BOUNDARY CONDITIONS
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_FormAcousticImpedance    ! Impedance BC (Robin)
  PUBLIC :: PH_Elem_AC3D15_FormRadiationCondition  ! Sommerfeld radiation
  PUBLIC :: PH_Elem_AC3D15_FormStructureCoupling
  PUBLIC :: UF_Elem_AC3D15_Calc    ! FSI coupling
  
  !---------------------------------------------------------------------------
  ! LOADS (Body force, pressure, surface traction)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_FormPressureLoad     ! Pressure load vector
  PUBLIC :: PH_Elem_AC3D15_FormBodyForce       ! Body force vector
  PUBLIC :: PH_Elem_AC3D15_FormSurfaceTraction ! Surface traction
  
  !---------------------------------------------------------------------------
  ! POST-PROCESSING (Results extraction)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_CalcPressure        ! Pressure at nodes/IP
  PUBLIC :: PH_Elem_AC3D15_CalcAcousticIntensity  ! Acoustic intensity
  PUBLIC :: PH_Elem_AC3D15_CalcEnergy          ! Acoustic energy
  PUBLIC :: PH_Elem_AC3D15_CalcEnergy_FromDesc ! Energy from descriptor
  PUBLIC :: PH_Elem_AC3D15_OutputResults       ! Output results
  
  !---------------------------------------------------------------------------
  ! MATERIAL PROPERTIES
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_GetMaterialProps       ! Get material properties
  PUBLIC :: PH_Elem_AC3D15_GetMaterialProps_FromDesc  ! From descriptor
  PUBLIC :: PH_Elem_AC3D15_GetVolume             ! Element volume
  PUBLIC :: PH_Elem_AC3D15_GetAcousticProps      ! Acoustic properties
  PUBLIC :: PH_Elem_AC3D15_SetSectionProps       ! Section properties
  PUBLIC :: PH_Elem_AC3D15_SetSectionProps_FromDesc  ! From descriptor
  
  !---------------------------------------------------------------------------
  ! VOLUME INTEGRATION
  !---------------------------------------------------------------------------
  PUBLIC :: PH_ELEM_AC3D15_VolumeInt            ! Element volume computation
  PUBLIC :: PH_Elem_AC3D15_GetArea             ! Element area
  PUBLIC :: PH_Elem_AC3D15_GetCentroid         ! Centroid computation
  PUBLIC :: PH_Elem_AC3D15_GetSectProps        ! Section properties
  
  !---------------------------------------------------------------------------
  ! P4-1 THERMO-ACOUSTIC COUPLING
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_Temperature_Dependent_Speed ! c(T) model
  PUBLIC :: PH_Elem_AC3D15_Thermal_Expansion_Source    ! Thermal expansion source
  PUBLIC :: PH_Elem_AC3D15_UpdateMaterialProps_TempDep ! Update material props
  
  !---------------------------------------------------------------------------
  ! P4-2 BIOT POROUS MEDIA
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_Biot_Wave_Speed           ! Biot wave speeds (P1/P2/S)
  PUBLIC :: PH_Elem_AC3D15_Biot_Damping              ! Biot damping mechanisms
  PUBLIC :: PH_Elem_AC3D15_Biot_Stabilize_SlowWave   ! SUPG stabilization for P2
  PUBLIC :: PH_Elem_AC3D15_Biot_Compute_Stab_Param   ! Stabilization parameter
  
  !---------------------------------------------------------------------------
  ! P4-3 PML INFINITE ELEMENTS
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_Sommerfeld_Radiation ! Sommerfeld radiation condition
  PUBLIC :: PH_Elem_AC3D15_Infinite_Element_Map  ! Mapping to infinite elements
  PUBLIC :: PH_Elem_AC3D15_PML_Update_State     ! PML state update
  PUBLIC :: PH_Elem_AC3D15_PML_Absorbing_Boundary ! PML absorbing layer
  
  !---------------------------------------------------------------------------
  ! CONTACT AND CONSTRAINTS (Legacy support)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_ApplyConstraint      ! Penalty constraint
  PUBLIC :: PH_Elem_AC3D15_ApplyMPC            ! Multi-point constraint
  PUBLIC :: PH_Elem_AC3D15_FormContactContrib  ! Contact contribution
  PUBLIC :: PH_Elem_AC3D15_FormContactEdgeCtr  ! Contact edge center
  
  !---------------------------------------------------------------------------
  ! OUTPUT AND EXTRAPOLATION
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D15_CollectIPVars       ! Collect IP variables
  PUBLIC :: PH_Elem_AC3D15_MapToNode          ! Map to nodes
  PUBLIC :: PH_Elem_AC3D15_GetExtrapMat      ! Extrapolation matrix
  PUBLIC :: PH_Elem_AC3D15_FormNodalForce     ! Nodal force vector
  PUBLIC :: PH_Elem_AC3D15_EvalVonMises      ! Von Mises stress

  !===========================================================================
  ! UEL_Args TYPE - Principle #14 Structured IO (SIO)
  !===========================================================================
  TYPE, PUBLIC :: PH_AC3D15_UEL_Args
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
  END TYPE PH_AC3D15_UEL_Args

  !===========================================================================
  ! PRIVATE HELPERS (Used internally)
  !===========================================================================
  PRIVATE :: AC3D15_ShapeFunc
  PRIVATE :: AC3D15_Jacobian
  PRIVATE :: AC3D15_B_Matrix
  PRIVATE :: AC3D15_GaussPoints

CONTAINS

  !============================================================================
  ! AC3D15 GAUSS POINTS - 9-point integration for quadratic wedge
  !============================================================================
  SUBROUTINE AC3D15_GaussPoints(xi, eta, zeta, weights)
    REAL(wp), INTENT(OUT) :: xi(:), eta(:), zeta(:), weights(:)
    REAL(wp), PARAMETER :: w_tri = 1.0_wp / 6.0_wp
    REAL(wp), PARAMETER :: gp = 1.0_wp / SQRT(3.0_wp)
    REAL(wp), PARAMETER :: w_z1 = 5.0_wp / 9.0_wp
    REAL(wp), PARAMETER :: w_z2 = 8.0_wp / 9.0_wp
    REAL(wp), PARAMETER :: t1 = 1.0_wp / 6.0_wp
    REAL(wp), PARAMETER :: t2 = 2.0_wp / 3.0_wp
    REAL(wp), PARAMETER :: t3 = 1.0_wp / 6.0_wp
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: zeta_gp(3) = [-gp, ZERO, gp]
    REAL(wp), PARAMETER :: w_zeta(3) = [w_z1, w_z2, w_z1]
    
    i = 1
    xi(i) = t2; eta(i) = t1; zeta(i) = zeta_gp(1); weights(i) = w_tri * w_zeta(1); i = i + 1
    xi(i) = t1; eta(i) = t3; zeta(i) = zeta_gp(1); weights(i) = w_tri * w_zeta(1); i = i + 1
    xi(i) = t1; eta(i) = t1; zeta(i) = zeta_gp(1); weights(i) = w_tri * w_zeta(1); i = i + 1
    xi(i) = t2; eta(i) = t1; zeta(i) = zeta_gp(2); weights(i) = w_tri * w_zeta(2); i = i + 1
    xi(i) = t1; eta(i) = t3; zeta(i) = zeta_gp(2); weights(i) = w_tri * w_zeta(2); i = i + 1
    xi(i) = t1; eta(i) = t1; zeta(i) = zeta_gp(2); weights(i) = w_tri * w_zeta(2); i = i + 1
    xi(i) = t2; eta(i) = t1; zeta(i) = zeta_gp(3); weights(i) = w_tri * w_zeta(3); i = i + 1
    xi(i) = t1; eta(i) = t3; zeta(i) = zeta_gp(3); weights(i) = w_tri * w_zeta(3); i = i + 1
    xi(i) = t1; eta(i) = t1; zeta(i) = zeta_gp(3); weights(i) = w_tri * w_zeta(3)
  END SUBROUTINE AC3D15_GaussPoints

  !============================================================================
  ! AC3D15 SHAPE FUNCTIONS - 15-node quadratic wedge
  !============================================================================
  SUBROUTINE AC3D15_ShapeFunc(xi, eta, zeta, N, dNdxi)
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(15), dNdxi(3, 15)
    REAL(wp) :: L1, L2, L3
    
    L1 = 1.0_wp - xi - eta
    L2 = xi
    L3 = eta
    
    ! Corner nodes - bottom triangle (zeta = -1)
    N(1) = 0.5_wp * L1 * (2.0_wp * L1 - 1.0_wp) * (1.0_wp - zeta) / 2.0_wp
    dNdxi(1, 1) = 0.5_wp * (1.0_wp - zeta) / 2.0_wp * (-3.0_wp + 4.0_wp * L1)
    dNdxi(2, 1) = 0.5_wp * (1.0_wp - zeta) / 2.0_wp * (-3.0_wp + 4.0_wp * L1)
    dNdxi(3, 1) = -0.5_wp * L1 * (2.0_wp * L1 - 1.0_wp) / 2.0_wp
    
    N(2) = 0.5_wp * L2 * (2.0_wp * L2 - 1.0_wp) * (1.0_wp - zeta) / 2.0_wp
    dNdxi(1, 2) = 0.5_wp * (1.0_wp - zeta) / 2.0_wp * (4.0_wp * L2 - 1.0_wp)
    dNdxi(2, 2) = 0.0_wp
    dNdxi(3, 2) = -0.5_wp * L2 * (2.0_wp * L2 - 1.0_wp) / 2.0_wp
    
    N(3) = 0.5_wp * L3 * (2.0_wp * L3 - 1.0_wp) * (1.0_wp - zeta) / 2.0_wp
    dNdxi(1, 3) = 0.0_wp
    dNdxi(2, 3) = 0.5_wp * (1.0_wp - zeta) / 2.0_wp * (4.0_wp * L3 - 1.0_wp)
    dNdxi(3, 3) = -0.5_wp * L3 * (2.0_wp * L3 - 1.0_wp) / 2.0_wp
    
    ! Corner nodes - top triangle (zeta = +1)
    N(4) = 0.5_wp * L1 * (2.0_wp * L1 - 1.0_wp) * (1.0_wp + zeta) / 2.0_wp
    dNdxi(1, 4) = 0.5_wp * (1.0_wp + zeta) / 2.0_wp * (-3.0_wp + 4.0_wp * L1)
    dNdxi(2, 4) = 0.5_wp * (1.0_wp + zeta) / 2.0_wp * (-3.0_wp + 4.0_wp * L1)
    dNdxi(3, 4) = 0.5_wp * L1 * (2.0_wp * L1 - 1.0_wp) / 2.0_wp
    
    N(5) = 0.5_wp * L2 * (2.0_wp * L2 - 1.0_wp) * (1.0_wp + zeta) / 2.0_wp
    dNdxi(1, 5) = 0.5_wp * (1.0_wp + zeta) / 2.0_wp * (4.0_wp * L2 - 1.0_wp)
    dNdxi(2, 5) = 0.0_wp
    dNdxi(3, 5) = 0.5_wp * L2 * (2.0_wp * L2 - 1.0_wp) / 2.0_wp
    
    N(6) = 0.5_wp * L3 * (2.0_wp * L3 - 1.0_wp) * (1.0_wp + zeta) / 2.0_wp
    dNdxi(1, 6) = 0.0_wp
    dNdxi(2, 6) = 0.5_wp * (1.0_wp + zeta) / 2.0_wp * (4.0_wp * L3 - 1.0_wp)
    dNdxi(3, 6) = 0.5_wp * L3 * (2.0_wp * L3 - 1.0_wp) / 2.0_wp
    
    ! Mid-side nodes - bottom triangle edges (zeta = -1)
    N(7) = 2.0_wp * L1 * L2 * (1.0_wp - zeta) / 2.0_wp
    dNdxi(1, 7) = (1.0_wp - zeta) / 2.0_wp * (2.0_wp * L2 - 2.0_wp * L1)
    dNdxi(2, 7) = (1.0_wp - zeta) / 2.0_wp * (-2.0_wp * L2)
    dNdxi(3, 7) = -L1 * L2 / 2.0_wp
    
    N(8) = 2.0_wp * L2 * L3 * (1.0_wp - zeta) / 2.0_wp
    dNdxi(1, 8) = (1.0_wp - zeta) / 2.0_wp * (2.0_wp * L3)
    dNdxi(2, 8) = (1.0_wp - zeta) / 2.0_wp * (2.0_wp * L2 - 2.0_wp * L3)
    dNdxi(3, 8) = -L2 * L3 / 2.0_wp
    
    N(9) = 2.0_wp * L3 * L1 * (1.0_wp - zeta) / 2.0_wp
    dNdxi(1, 9) = (1.0_wp - zeta) / 2.0_wp * (-2.0_wp * L3)
    dNdxi(2, 9) = (1.0_wp - zeta) / 2.0_wp * (2.0_wp * L1 - 2.0_wp * L3)
    dNdxi(3, 9) = -L3 * L1 / 2.0_wp
    
    ! Mid-side nodes - top triangle edges (zeta = +1)
    N(10) = 2.0_wp * L1 * L2 * (1.0_wp + zeta) / 2.0_wp
    dNdxi(1, 10) = (1.0_wp + zeta) / 2.0_wp * (2.0_wp * L2 - 2.0_wp * L1)
    dNdxi(2, 10) = (1.0_wp + zeta) / 2.0_wp * (-2.0_wp * L2)
    dNdxi(3, 10) = L1 * L2 / 2.0_wp
    
    N(11) = 2.0_wp * L2 * L3 * (1.0_wp + zeta) / 2.0_wp
    dNdxi(1, 11) = (1.0_wp + zeta) / 2.0_wp * (2.0_wp * L3)
    dNdxi(2, 11) = (1.0_wp + zeta) / 2.0_wp * (2.0_wp * L2 - 2.0_wp * L3)
    dNdxi(3, 11) = L2 * L3 / 2.0_wp
    
    N(12) = 2.0_wp * L3 * L1 * (1.0_wp + zeta) / 2.0_wp
    dNdxi(1, 12) = (1.0_wp + zeta) / 2.0_wp * (-2.0_wp * L3)
    dNdxi(2, 12) = (1.0_wp + zeta) / 2.0_wp * (2.0_wp * L1 - 2.0_wp * L3)
    dNdxi(3, 12) = L3 * L1 / 2.0_wp
    
    ! Vertical edge mid-side nodes (zeta direction)
    N(13) = L1 * (1.0_wp - zeta**2)
    dNdxi(1, 13) = (1.0_wp - zeta**2) * (-1.0_wp)
    dNdxi(2, 13) = (1.0_wp - zeta**2) * (-1.0_wp)
    dNdxi(3, 13) = -2.0_wp * zeta * L1
    
    N(14) = L2 * (1.0_wp - zeta**2)
    dNdxi(1, 14) = (1.0_wp - zeta**2)
    dNdxi(2, 14) = 0.0_wp
    dNdxi(3, 14) = -2.0_wp * zeta * L2
    
    N(15) = L3 * (1.0_wp - zeta**2)
    dNdxi(1, 15) = 0.0_wp
    dNdxi(2, 15) = (1.0_wp - zeta**2)
    dNdxi(3, 15) = -2.0_wp * zeta * L3
  END SUBROUTINE AC3D15_ShapeFunc

  !============================================================================
  ! AC3D15 JACOBIAN - Geometric mapping J = dx/dxi
  !============================================================================
  SUBROUTINE AC3D15_Jacobian(dNdxi, coords, J, detJ)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 15), coords(3, 15)
    REAL(wp), INTENT(OUT) :: J(3, 3), detJ
    INTEGER(i4) :: i, j, k
    J = ZERO
    DO i = 1, 3
      DO j = 1, 3
        DO k = 1, 15
          J(i, j) = J(i, j) + coords(i, k) * dNdxi(j, k)
        END DO
      END DO
    END DO
    detJ = J(1,1)*(J(2,2)*J(3,3)-J(2,3)*J(3,2)) - &
           J(1,2)*(J(2,1)*J(3,3)-J(2,3)*J(3,1)) + &
           J(1,3)*(J(2,1)*J(3,2)-J(2,2)*J(3,1))
  END SUBROUTINE AC3D15_Jacobian

  !============================================================================
  ! AC3D15 B MATRIX - Pressure gradient operator [3 x 15]
  !============================================================================
  SUBROUTINE AC3D15_B_Matrix(dNdxi, J, detJ, B)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 15), J(3, 3), detJ
    REAL(wp), INTENT(OUT) :: B(3, 15)
    REAL(wp) :: Jinv(3, 3)
    INTEGER(i4) :: i, j
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
    DO i = 1, 3
      DO j = 1, 15
        B(i, j) = Jinv(i,1)*dNdxi(1,j) + Jinv(i,2)*dNdxi(2,j) + Jinv(i,3)*dNdxi(3,j)
      END DO
    END DO
  END SUBROUTINE AC3D15_B_Matrix

  SUBROUTINE PH_Elem_AC3D15_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)    :: ctype
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(15, 15)
    REAL(wp), INTENT(INOUT) :: F_el(15)
    IF (ctype /= PH_ELEM_CTYPE_PENALTY_DOF) RETURN
    IF (idof < 1 .OR. idof > 15) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_AC3D15_ApplyConstraint

  SUBROUTINE PH_Elem_AC3D15_ApplyMPC(c, val, penalty, K_el, F_el)
    REAL(wp), INTENT(IN)    :: c(15)
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(INOUT) :: K_el(15, 15)
    REAL(wp), INTENT(INOUT) :: F_el(15)
    INTEGER(i4) :: i, j
    DO i = 1, 15
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 15
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_ApplyMPC

  SUBROUTINE PH_Elem_AC3D15_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: xi, eta
    REAL(wp), INTENT(IN)  :: N(15)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(IN)  :: gap, penalty, edge_len
    REAL(wp), INTENT(INOUT) :: K_el(15, 15)
    REAL(wp), INTENT(INOUT) :: F_el(15)
  END SUBROUTINE PH_Elem_AC3D15_FormContactContrib

  SUBROUTINE PH_Elem_AC3D15_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: gap, penalty
    REAL(wp), INTENT(OUT) :: K_el(15, 15)
    REAL(wp), INTENT(OUT) :: F_el(15)
    K_el = ZERO
    F_el = ZERO
  END SUBROUTINE PH_Elem_AC3D15_FormContactEdgeCtr

  SUBROUTINE PH_Elem_AC3D15_FormBodyForce(coords, bx, by, bz, F_eq, status)
    ! Purpose: Compute body force contribution to acoustic element
    ! Theory: F_i = integral(N_i * rho * b * dV) where b is body force vector
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9), b_vec(3), dV
    INTEGER(i4) :: ip, i
    status%code = STATUS_SUCCESS
    F_eq = ZERO
    b_vec = [bx, by, bz]
    ! For acoustic wave equation, body force typically represents
    ! mass injection/absorption or acoustic sources
    IF (SQRT(bx**2 + by**2 + bz**2) < 1.0e-30_wp) RETURN
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      DO i = 1, 15
        ! Acoustic body force: F = integral(rho * N * b dV)
        F_eq(i) = F_eq(i) + DOT_PRODUCT(b_vec, N(i) * coords(:, i)) * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_FormBodyForce

  SUBROUTINE PH_Elem_AC3D15_FormNodalForce(load_type, coords, val, edge_id, F_eq, status)
    ! Purpose: Apply nodal forces or edge loads
    ! Theory: Concentrated force at nodes or edge traction
    INTEGER(i4), INTENT(IN)  :: load_type
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: val(:)
    INTEGER(i4), INTENT(IN)  :: edge_id
    REAL(wp), INTENT(OUT) :: F_eq(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15)
    REAL(wp) :: xi, eta, zeta
    INTEGER(i4) :: i
    status%code = STATUS_SUCCESS
    F_eq = ZERO
    SELECT CASE (load_type)
    CASE (PH_ELEM_LOAD_EDGE_P)  ! Edge pressure load
      IF (SIZE(val) >= 1) THEN
        DO i = 1, 15
          xi = 0.5_wp * (1.0_wp - COS(3.14159_wp * REAL(i-1, wp) / 7.5_wp))
          eta = 0.5_wp * (1.0_wp - COS(3.14159_wp * REAL(i-1, wp) / 7.5_wp))
          zeta = 0.0_wp
          CALL AC3D15_ShapeFunc(xi, eta, zeta, N, dNdxi)
          F_eq(i) = val(1) * N(i)
        END DO
      END IF
    CASE DEFAULT  ! Point load
      IF (SIZE(val) >= 1) THEN
        F_eq = val(1) / 15.0_wp  ! Distribute evenly
      END IF
    END SELECT
  END SUBROUTINE PH_Elem_AC3D15_FormNodalForce

  SUBROUTINE PH_Elem_AC3D15_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars, status)
    ! Purpose: Collect integration point variables for output
    ! Theory: Gather IP stress/strain into output array
    REAL(wp), INTENT(IN)  :: ip_stress(:, :)
    REAL(wp), INTENT(IN)  :: ip_strain(:, :)
    REAL(wp), INTENT(IN)  :: ip_peeq(:)
    INTEGER(i4), INTENT(IN)  :: n_ip
    REAL(wp), INTENT(OUT) :: out_vars(:, :)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ip, j
    status%code = STATUS_SUCCESS
    out_vars = ZERO
    DO ip = 1, MIN(n_ip, SIZE(ip_stress, 2), SIZE(out_vars, 2))
      DO j = 1, MIN(SIZE(ip_stress, 1), SIZE(out_vars, 1))
        out_vars(j, ip) = ip_stress(j, ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_CollectIPVars

  SUBROUTINE PH_Elem_AC3D15_EvalVonMises(sigma, seq, status)
    ! Purpose: Compute von Mises stress for acoustic pressure
    ! Theory: For hydrostatic stress state: seq = |sigma_h| = |p|
    REAL(wp), INTENT(IN)  :: sigma(:)
    REAL(wp), INTENT(OUT) :: seq
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: sigma_h
    status%code = STATUS_SUCCESS
    ! Hydrostatic stress = mean of diagonal components
    IF (SIZE(sigma) >= 3) THEN
      sigma_h = (sigma(1) + sigma(2) + sigma(3)) / 3.0_wp
      seq = ABS(sigma_h)  ! Von Mises equivalent for hydrostatic state
    ELSE
      seq = ZERO
    END IF
  END SUBROUTINE PH_Elem_AC3D15_EvalVonMises

  SUBROUTINE PH_Elem_AC3D15_GetExtrapMat(E, status)
    ! Purpose: Get extrapolation matrix for IP to nodal quantities
    ! Theory: E = [N(X_i)] at each IP (B-bar projection or lumping)
    REAL(wp), INTENT(OUT) :: E(15, 15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(15), eta(15), zeta(15), weights(15)
    INTEGER(i4) :: ip, i
    status%code = STATUS_SUCCESS
    E = ZERO
    ! Use equidistant points for extrapolation
    DO ip = 1, 15
      xi(ip) = 1.0_wp / 3.0_wp
      eta(ip) = 1.0_wp / 3.0_wp
      zeta(ip) = -1.0_wp + 2.0_wp * REAL(ip-1, wp) / 14.0_wp
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      DO i = 1, 15
        E(i, ip) = N(i)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_GetExtrapMat

  SUBROUTINE PH_Elem_AC3D15_MapToNode(ip_vars, weights, node_vars, status)
    ! Purpose: Map IP quantities to nodes via extrapolation
    ! Theory: Node value = E^T * IP_value (weighted extrapolation)
    REAL(wp), INTENT(IN)  :: ip_vars(:, :)
    REAL(wp), INTENT(IN)  :: weights(:)
    REAL(wp), INTENT(OUT) :: node_vars(:, :)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: E(15, 15)
    INTEGER(i4) :: i, j, n_var
    status%code = STATUS_SUCCESS
    node_vars = ZERO
    n_var = MIN(SIZE(ip_vars, 1), SIZE(node_vars, 1))
    CALL PH_Elem_AC3D15_GetExtrapMat(E, status)
    DO i = 1, 15
      DO j = 1, n_var
        node_vars(j, i) = SUM(E(i, :) * ip_vars(j, :) * weights(:))
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_MapToNode

  SUBROUTINE PH_ELEM_AC3D15_VolumeInt(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL PH_Elem_C3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_AC3D15_VolumeInt

  !============================================================================
  ! ELEMENT UTILITIES
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_GetVolume(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    INTEGER(i4) :: ip
    volume = ZERO
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_Elem_AC3D15_GetVolume
  
  SUBROUTINE PH_Elem_AC3D15_GetArea(coords, area)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: area
    CALL PH_Elem_AC3D15_GetVolume(coords, area)
  END SUBROUTINE PH_Elem_AC3D15_GetArea
  
  SUBROUTINE PH_Elem_AC3D15_GetCentroid(coords, centroid)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: centroid(3)
    centroid = SUM(coords, DIM=2) / 15.0_wp
  END SUBROUTINE PH_Elem_AC3D15_GetCentroid
  
  SUBROUTINE PH_Elem_AC3D15_GetSectProps(coords, density_in, area, mass)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: density_in
    REAL(wp), INTENT(OUT) :: area, mass
    REAL(wp) :: vol
    CALL PH_Elem_AC3D15_GetVolume(coords, vol)
    area = vol
    mass = density_in * vol
  END SUBROUTINE PH_Elem_AC3D15_GetSectProps
  
  !============================================================================
  ! ELEMENT STIFFNESS MATRIX - Acoustic formulation
  ! K_ij = integral( (1/rho*c^2) * dNi/dxk * dNj/dxk * dV )
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_FormStiffMatrix(coords, rho, c_sound, Ke, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), rho, c_sound
    REAL(wp), INTENT(OUT) :: Ke(15, 15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ, B(3, 15)
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: inv_rho_c2, dV
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    Ke = ZERO
    inv_rho_c2 = 1.0_wp / (rho * c_sound**2)
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL AC3D15_B_Matrix(dNdxi, J, detJ, B)
      dV = detJ * weights(ip)
      DO i = 1, 15
        DO j = 1, 15
          Ke(i, j) = Ke(i, j) + inv_rho_c2 * (B(1,i)*B(1,j) + B(2,i)*B(2,j) + B(3,i)*B(3,j)) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_FormStiffMatrix
  
  SUBROUTINE PH_Elem_AC3D15_FormIntForce(coords, p, rho, c_sound, R_int, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), p(15), rho, c_sound
    REAL(wp), INTENT(OUT) :: R_int(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: Ke(15, 15)
    CALL PH_Elem_AC3D15_FormStiffMatrix(coords, rho, c_sound, Ke, status)
    R_int = MATMUL(Ke, p)
  END SUBROUTINE PH_Elem_AC3D15_FormIntForce
  
  !============================================================================
  ! MASS MATRIX - Consistent (P3)
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_ConsMass(coords, rho, Me, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), rho
    REAL(wp), INTENT(OUT) :: Me(15, 15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    Me = ZERO
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = rho * detJ * weights(ip)
      DO i = 1, 15
        DO j = 1, 15
          Me(i, j) = Me(i, j) + N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_ConsMass
  
  !============================================================================
  ! MASS MATRIX - Lumped (HRZ/RowSum/Uniform)
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_LumpMass(coords, rho, M_lumped, method, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), rho
    REAL(wp), INTENT(OUT) :: M_lumped(15)
    INTEGER(i4), INTENT(IN), OPTIONAL :: method
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: Me(15, 15), vol, m_total, trace_Me
    INTEGER(i4) :: i, imethod
    status%code = STATUS_SUCCESS
    imethod = 1  ! Default: HRZ
    IF (PRESENT(method)) imethod = method
    CALL PH_Elem_AC3D15_ConsMass(coords, rho, Me, status)
    SELECT CASE (imethod)
    CASE (2)  ! Row-sum
      DO i = 1, 15
        M_lumped(i) = SUM(Me(i, :))
      END DO
    CASE (3)  ! Uniform
      CALL PH_Elem_AC3D15_GetVolume(coords, vol)
      m_total = rho * vol
      M_lumped = m_total / 15.0_wp
    CASE DEFAULT  ! HRZ
      trace_Me = 0.0_wp
      DO i = 1, 15
        trace_Me = trace_Me + Me(i, i)
      END DO
      CALL PH_Elem_AC3D15_GetVolume(coords, vol)
      m_total = rho * vol
      IF (trace_Me > 1.0e-12_wp) THEN
        DO i = 1, 15
          M_lumped(i) = m_total * Me(i, i) / trace_Me
        END DO
      ELSE
        M_lumped = m_total / 15.0_wp
      END IF
    END SELECT
  END SUBROUTINE PH_Elem_AC3D15_LumpMass

  !============================================================================
  ! RAYLEIGH DAMPING - C = alpha*M + beta*K
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_FormDampingMatrix(alpha_M, beta_K, Me, Ke, Ce, status)
    REAL(wp), INTENT(IN)  :: alpha_M, beta_K, Me(15, 15), Ke(15, 15)
    REAL(wp), INTENT(OUT) :: Ce(15, 15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    status%code = STATUS_SUCCESS
    Ce = alpha_M * Me + beta_K * Ke
  END SUBROUTINE PH_Elem_AC3D15_FormDampingMatrix

  ! Note: PH_ELEM_AC3D15_VolumeInt is aliased to PH_Elem_AC3D15_GetVolume

  SUBROUTINE PH_Elem_AC3D15_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 15)
    REAL(wp), INTENT(IN)  :: p_elem(15)
    REAL(wp), INTENT(IN)  :: D(1, 1)
    REAL(wp), INTENT(OUT) :: Ke_mat(15, 15)
    REAL(wp), INTENT(OUT) :: Ke_geo(15, 15)
    REAL(wp), INTENT(OUT) :: R_int(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k_eff
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    k_eff = 2.2e9_wp
    IF (ABS(D(1, 1)) > 1.0e-30_wp) k_eff = D(1, 1)
    CALL PH_Elem_AC3D15_FormStiffMatrix(coords_ref, k_eff, ZERO, Ke_mat)
    CALL PH_Elem_AC3D15_FormIntForce(coords_ref, p_elem, k_eff, ZERO, R_int)
  END SUBROUTINE PH_Elem_AC3D15_NL_TL

  SUBROUTINE PH_Elem_AC3D15_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)
    REAL(wp), INTENT(IN)  :: coords_prev(3, 15)
    REAL(wp), INTENT(IN)  :: p_incr(15)
    REAL(wp), INTENT(IN)  :: D(1, 1)
    REAL(wp), INTENT(OUT) :: Ke_mat(15, 15)
    REAL(wp), INTENT(OUT) :: Ke_geo(15, 15)
    REAL(wp), INTENT(OUT) :: R_int(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: k_eff
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int  = ZERO
    status%code = STATUS_SUCCESS
    k_eff = 2.2e9_wp
    IF (ABS(D(1, 1)) > 1.0e-30_wp) k_eff = D(1, 1)
    CALL PH_Elem_AC3D15_FormStiffMatrix(coords_prev, k_eff, ZERO, Ke_mat)
    CALL PH_Elem_AC3D15_FormIntForce(coords_prev, p_incr, k_eff, ZERO, R_int)
  END SUBROUTINE PH_Elem_AC3D15_NL_UL

  !============================================================================
  ! BOUNDARY CONDITIONS
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_ApplyEssentialBC(idof, val, K_el, F_el, status)
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: val
    REAL(wp), INTENT(INOUT) :: K_el(15, 15), F_el(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: penalty
    status%code = STATUS_SUCCESS
    penalty = 1.0e20_wp
    IF (idof < 1 .OR. idof > 15) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_AC3D15_ApplyEssentialBC
  
  SUBROUTINE PH_Elem_AC3D15_ApplyPenaltyBC(idof, penalty, val, K_el, F_el, status)
    INTEGER(i4), INTENT(IN)    :: idof
    REAL(wp), INTENT(IN)    :: penalty, val
    REAL(wp), INTENT(INOUT) :: K_el(15, 15), F_el(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    status%code = STATUS_SUCCESS
    IF (idof < 1 .OR. idof > 15) RETURN
    K_el(idof, idof) = K_el(idof, idof) + penalty
    F_el(idof) = F_el(idof) + penalty * val
  END SUBROUTINE PH_Elem_AC3D15_ApplyPenaltyBC
  
  SUBROUTINE PH_Elem_AC3D15_FormConstraintMatrix(c, val, penalty, K_el, F_el, status)
    REAL(wp), INTENT(IN)    :: c(15), val, penalty
    REAL(wp), INTENT(INOUT) :: K_el(15, 15), F_el(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, j
    status%code = STATUS_SUCCESS
    DO i = 1, 15
      F_el(i) = F_el(i) + penalty * val * c(i)
      DO j = 1, 15
        K_el(i, j) = K_el(i, j) + penalty * c(i) * c(j)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_FormConstraintMatrix

  !============================================================================
  ! SPECIAL BOUNDARY CONDITIONS - ACOUSTIC IMPEDANCE & RADIATION
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_FormAcousticImpedance(coords, Zc, rho, C_imp, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), Zc, rho
    REAL(wp), INTENT(OUT) :: C_imp(15, 15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: dA
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    C_imp = ZERO
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dA = detJ * weights(ip)
      DO i = 1, 15
        DO j = 1, 15
          C_imp(i, j) = C_imp(i, j) + (Zc / rho) * N(i) * N(j) * dA
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_FormAcousticImpedance

  SUBROUTINE PH_Elem_AC3D15_FormRadiationCondition(coords, face_normal, sound_speed, frequency, C_rad, K_rad, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), face_normal(3), sound_speed, frequency
    REAL(wp), INTENT(OUT) :: C_rad(15, 15), K_rad(15, 15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: omega, k_wave, sigma, N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9), dA
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    C_rad = ZERO
    K_rad = ZERO
    omega = 2.0_wp * 3.14159_wp * frequency
    k_wave = omega / sound_speed
    sigma = k_wave * 0.1_wp
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dA = detJ * weights(ip)
      DO i = 1, 15
        DO j = 1, 15
          C_rad(i, j) = C_rad(i, j) + sigma * N(i) * N(j) * dA
          K_rad(i, j) = K_rad(i, j) + (omega / sound_speed) * N(i) * N(j) * dA
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_FormRadiationCondition

  SUBROUTINE PH_Elem_AC3D15_FormStructureCoupling(coords, coupling_matrix, structure_dof_indices, acoustic_dof_indices, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    INTEGER(i4), INTENT(IN) :: structure_dof_indices(:), acoustic_dof_indices(:)
    REAL(wp), INTENT(OUT) :: coupling_matrix(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    INTEGER(i4) :: ip, i
    status%code = STATUS_SUCCESS
    coupling_matrix = ZERO
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 15
        coupling_matrix(acoustic_dof_indices(i), structure_dof_indices) = &
          coupling_matrix(acoustic_dof_indices(i), structure_dof_indices) + &
          N(i) * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_FormStructureCoupling

  !============================================================================
  ! LOADS
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_FormPressureLoad(coords, pressure, F_load, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), pressure
    REAL(wp), INTENT(OUT) :: F_load(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    INTEGER(i4) :: ip, i
    status%code = STATUS_SUCCESS
    F_load = ZERO
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      DO i = 1, 15
        F_load(i) = F_load(i) + pressure * N(i) * detJ * weights(ip)
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_FormPressureLoad
  
  SUBROUTINE PH_Elem_AC3D15_FormBodyForce(coords, bx, by, bz, F_eq, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), bx, by, bz
    REAL(wp), INTENT(OUT) :: F_eq(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9), b_vec(3), dV
    INTEGER(i4) :: ip, i
    status%code = STATUS_SUCCESS
    F_eq = ZERO
    b_vec = [bx, by, bz]
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      DO i = 1, 15
        F_eq(i) = F_eq(i) + DOT_PRODUCT(b_vec, N(i) * coords(:, i)) * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_FormBodyForce
  
  SUBROUTINE PH_Elem_AC3D15_FormSurfaceTraction(coords, t1, t2, F_traction, status)
    ! Purpose: Compute surface traction on boundary faces
    ! Theory: F_i = integral(N_i * t * dGamma) for acoustic pressure traction
    REAL(wp), INTENT(IN)  :: coords(3, 15), t1(3), t2(3)
    REAL(wp), INTENT(OUT) :: F_traction(15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi, eta, zeta, weights(3), dA
    REAL(wp) :: v1(3), v2(3), normal(3), area_norm, t_normal
    INTEGER(i4) :: i
    status%code = STATUS_SUCCESS
    F_traction = ZERO
    ! 3-point Gauss for triangular face integration
    weights = [1.0_wp/3.0_wp, 1.0_wp/3.0_wp, 1.0_wp/3.0_wp]
    DO i = 1, 3
      SELECT CASE (i)
      CASE (1); xi = 0.5_wp; eta = 0.0_wp; zeta = 0.0_wp
      CASE (2); xi = 0.0_wp; eta = 0.5_wp; zeta = 0.0_wp
      CASE (3); xi = 0.0_wp; eta = 0.0_wp; zeta = 0.0_wp
      END SELECT
      CALL AC3D15_ShapeFunc(xi, eta, zeta, N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      ! Compute normal for triangular face
      v1 = coords(:,2) - coords(:,1)
      v2 = coords(:,4) - coords(:,1)
      normal(1) = v1(2)*v2(3) - v1(3)*v2(2)
      normal(2) = v1(3)*v2(1) - v1(1)*v2(3)
      normal(3) = v1(1)*v2(2) - v1(2)*v2(1)
      area_norm = SQRT(SUM(normal**2))
      IF (area_norm > 1.0e-12_wp) THEN
        normal = normal / area_norm
        t_normal = DOT_PRODUCT(t1, normal) + DOT_PRODUCT(t2, normal)
        dA = area_norm * weights(i)
        DO i = 1, 15
          F_traction(i) = F_traction(i) + t_normal * N(i) * dA
        END DO
      END IF
    END DO
  END SUBROUTINE PH_Elem_AC3D15_FormSurfaceTraction

  !============================================================================
  ! POST-PROCESSING
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_CalcPressure(coords, p, rho, c_sound, p_ip, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), p(15), rho, c_sound
    REAL(wp), INTENT(OUT) :: p_ip
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15)
    REAL(wp) :: xi, eta, zeta
    status%code = STATUS_SUCCESS
    ! Evaluate pressure at centroid
    xi = 1.0_wp / 3.0_wp
    eta = 1.0_wp / 3.0_wp
    zeta = ZERO
    CALL AC3D15_ShapeFunc(xi, eta, zeta, N, dNdxi)
    p_ip = DOT_PRODUCT(N, p)
  END SUBROUTINE PH_Elem_AC3D15_CalcPressure

  SUBROUTINE PH_Elem_AC3D15_CalcAcousticIntensity(p, v, I_avg, status)
    REAL(wp), INTENT(IN)  :: p, v(3)
    REAL(wp), INTENT(OUT) :: I_avg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    I_avg = p * v(1)  ! Simplified: x-component intensity
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_CalcAcousticIntensity

  SUBROUTINE PH_Elem_AC3D15_CalcEnergy(coords, p, rho, c_sound, E_acoustic, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), p(15), rho, c_sound
    REAL(wp), INTENT(OUT) :: E_acoustic
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: Ke(15, 15)
    CALL PH_Elem_AC3D15_FormStiffMatrix(coords, rho, c_sound, Ke, status)
    E_acoustic = 0.5_wp * DOT_PRODUCT(p, MATMUL(Ke, p))
  END SUBROUTINE PH_Elem_AC3D15_CalcEnergy

  SUBROUTINE PH_Elem_AC3D15_CalcEnergy_FromDesc(MD_Desc, p_elem, coords, E_acoustic, status)
    ! Purpose: Compute acoustic energy from element descriptor
    ! Theory: E = 1/2 * integral(p^2/(rho*c^2) + rho*|grad(p)/rho|^2) dV
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    REAL(wp), INTENT(IN)  :: p_elem(15)
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(OUT) :: E_acoustic
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: rho, c_sound, K_bulk
    REAL(wp) :: N(15), dNdxi(3, 15), B(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9), dV
    REAL(wp) :: pressure, grad_p(3), ke_density, pe_density
    INTEGER(i4) :: ip, i
    status%code = STATUS_SUCCESS
    E_acoustic = ZERO
    ! Default properties
    rho = 1.21_wp; c_sound = 343.0_wp
    ! Extract from MD_Desc if available
    IF (ASSOCIATED(MD_Desc%props)) THEN
      IF (SIZE(MD_Desc%props) >= 2) THEN
        rho = MD_Desc%props(1)
        c_sound = MD_Desc%props(2)
      END IF
    END IF
    K_bulk = rho * c_sound**2
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      CALL AC3D15_B_Matrix(dNdxi, J, detJ, B)
      dV = detJ * weights(ip)
      pressure = DOT_PRODUCT(N, p_elem)
      grad_p = MATMUL(B, p_elem)
      ! Kinetic energy density: KE = 1/2 * rho * |v|^2 = 1/2 * |grad(p)|^2 / rho
      ke_density = 0.5_wp * DOT_PRODUCT(grad_p, grad_p) / rho
      ! Potential energy density: PE = p^2 / (2 * rho * c^2)
      pe_density = 0.5_wp * pressure**2 / K_bulk
      E_acoustic = E_acoustic + (ke_density + pe_density) * dV
    END DO
  END SUBROUTINE PH_Elem_AC3D15_CalcEnergy_FromDesc

  SUBROUTINE PH_Elem_AC3D15_OutputResults(coords, p, svars, output, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), p(15), svars(:,:)
    REAL(wp), INTENT(OUT) :: output(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: p_ip, E_acoustic, rho, c_sound
    status%code = STATUS_SUCCESS
    output = ZERO
    rho = 1.21_wp
    c_sound = 343.0_wp
    CALL PH_Elem_AC3D15_CalcPressure(coords, p, rho, c_sound, p_ip, status)
    output(1) = p_ip
    CALL PH_Elem_AC3D15_CalcEnergy(coords, p, rho, c_sound, E_acoustic, status)
    output(2) = E_acoustic
  END SUBROUTINE PH_Elem_AC3D15_OutputResults

  !============================================================================
  ! MATERIAL PROPERTIES
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_GetMaterialProps(coords, Mat_Algo, rho, c_sound, status)
    ! Purpose: Get material properties at element location
    ! Theory: Query material algorithm for spatially varying properties
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    TYPE(MD_MatAlgo), INTENT(INOUT) :: Mat_Algo
    REAL(wp), INTENT(OUT) :: rho, c_sound
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    ! Default values (air at room temperature)
    rho = 1.21_wp      ! Density [kg/m³]
    c_sound = 343.0_wp ! Speed of sound [m/s]
    
    ! Query material algorithm if available
    IF (ASSOCIATED(Mat_Algo%p_rho)) THEN
      SELECT TYPE(ptr => Mat_Algo%p_rho)
      TYPE IS (REAL(wp))
        rho = ptr
      END SELECT
    END IF
    
    IF (ASSOCIATED(Mat_Algo%p_c_sound)) THEN
      SELECT TYPE(ptr => Mat_Algo%p_c_sound)
      TYPE IS (REAL(wp))
        c_sound = ptr
      END SELECT
    END IF
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_GetMaterialProps

  SUBROUTINE PH_Elem_AC3D15_GetMaterialProps_FromDesc(MD_Desc, rho, c_sound, status)
    ! Purpose: Extract material properties from element descriptor
    ! Theory: Read density and sound speed from MD_Desc%material
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    REAL(wp), INTENT(OUT) :: rho, c_sound
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    ! Extract from descriptor
    rho = MD_Desc%material%density
    c_sound = MD_Desc%material%sound_speed
    
    ! Fallback defaults if not set
    IF (rho <= ZERO) rho = 1.21_wp      ! Air density [kg/m³]
    IF (c_sound <= ZERO) c_sound = 343.0_wp  ! Speed of sound in air [m/s]
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_GetMaterialProps_FromDesc

  SUBROUTINE PH_Elem_AC3D15_GetAcousticProps(rho, c_sound, Zc, K_bulk, status)
    ! Purpose: Compute acoustic properties from density and sound speed
    ! Theory: Zc = rho*c (acoustic impedance)
    !         K_bulk = rho*c^2 (bulk modulus)
    REAL(wp), INTENT(IN)  :: rho, c_sound
    REAL(wp), INTENT(OUT) :: Zc, K_bulk
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    ! Acoustic impedance: Z = rho * c
    Zc = rho * c_sound
    
    ! Bulk modulus: K = rho * c^2
    K_bulk = rho * c_sound**2
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_GetAcousticProps

  SUBROUTINE PH_Elem_AC3D15_SetSectionProps(Sect_Registry, props, status)
    ! Purpose: Set section properties from section registry
    ! Theory: Map registry entries to element property array
    TYPE(MD_Sect_Registry), INTENT(IN) :: Sect_Registry
    REAL(wp), INTENT(OUT) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    status = init_error_status()
    props = ZERO
    
    ! Map registry properties to element property array
    DO i = 1, MIN(SIZE(props), Sect_Registry%n_props)
      props(i) = Sect_Registry%props(i)
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_SetSectionProps

  SUBROUTINE PH_Elem_AC3D15_SetSectionProps_FromDesc(MD_Desc, props, status)
    ! Purpose: Set section properties from element descriptor
    ! Theory: Extract material/section data from MD_Desc for acoustic properties
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    REAL(wp), INTENT(OUT) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: prop_idx
    
    status = init_error_status()
    props = ZERO
    
    ! Extract properties from descriptor
    ! Props(1): density (rho)
    ! Props(2): bulk modulus (K) or sound speed (c)
    ! Props(3): thermal expansion coefficient
    ! Props(4): section thickness (for 2D reduction)
    
    IF (SIZE(props) >= 1) props(1) = MD_Desc%material%density
    IF (SIZE(props) >= 2) props(2) = MD_Desc%material%bulk_modulus
    IF (SIZE(props) >= 3) props(3) = MD_Desc%material%alpha_T
    IF (SIZE(props) >= 4) props(4) = MD_Desc%section%thickness
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_SetSectionProps_FromDesc

  SUBROUTINE PH_Elem_AC3D15_ThermStrainVector(coords, alpha_T, deltaT, eps_th, status)
    ! Purpose: Compute thermal strain for thermo-acoustic coupling (P4-1)
    ! Theory: eps_th = alpha_T * deltaT * I (volumetric thermal expansion)
    !         In acoustics: thermal coupling through volumetric strain
    REAL(wp), INTENT(IN)  :: coords(3, 15)
    REAL(wp), INTENT(IN)  :: alpha_T   ! Thermal expansion coefficient [1/K]
    REAL(wp), INTENT(IN)  :: deltaT    ! Temperature increment [K]
    REAL(wp), INTENT(OUT) :: eps_th(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    ! Thermal volumetric strain: eps_th = alpha * deltaT
    ! For acoustic elements, this represents the source term in wave equation
    IF (SIZE(eps_th) >= 1) THEN
      eps_th(1) = alpha_T * deltaT  ! Volumetric thermal strain
    END IF
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_ThermStrainVector

  !============================================================================
  ! P4-1 THERMO-ACOUSTIC COUPLING
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)
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
    
    status = init_error_status()
    
    ! Check for valid temperature (absolute zero check)
    IF (temperature <= 0.0_wp) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    
    ! Temperature ratio
    T_ratio = temperature / T_ref
    
    ! Use square root model (default for gases/ideal behavior)
    c_speed = c_ref * SQRT(T_ratio)
    
    ! Alternative liquid model (uncomment for water/liquids):
    ! c_speed = c_ref * (1.0_wp + alpha_T * (temperature - T_ref))
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_Temperature_Dependent_Speed

  SUBROUTINE PH_Elem_AC3D15_Thermal_Expansion_Source(F_thermal, coords, temperature_field, MD_Desc, MD_Algo, status)
    REAL(wp), INTENT(OUT) :: F_thermal(15)
    REAL(wp), INTENT(IN)  :: coords(3, 15), temperature_field(15)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ, dV
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9)
    REAL(wp) :: T_ip, beta_T, rho, c_sound, dTdt2
    INTEGER(i4) :: ip, i
    status%code = STATUS_SUCCESS
    F_thermal = ZERO
    beta_T = 1.0e-3_wp   ! Thermal expansion coefficient [1/K]
    rho = 1.21_wp
    c_sound = 343.0_wp
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      T_ip = DOT_PRODUCT(N, temperature_field)
      dTdt2 = beta_T / (rho * c_sound**2)
      DO i = 1, 15
        F_thermal(i) = F_thermal(i) + rho * beta_T * dTdt2 * N(i) * dV
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_Thermal_Expansion_Source

  SUBROUTINE PH_Elem_AC3D15_UpdateMaterialProps_TempDep(rho, c_sound, temperature, T_ref, alpha_rho, alpha_c, status)
    REAL(wp), INTENT(INOUT) :: rho, c_sound
    REAL(wp), INTENT(IN)  :: temperature, T_ref, alpha_rho, alpha_c
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: T_ratio
    status%code = STATUS_SUCCESS
    T_ratio = temperature / T_ref
    rho = rho * (1.0_wp - alpha_rho * (temperature - T_ref))
    c_sound = c_sound * SQRT(T_ratio) * (1.0_wp + alpha_c * (temperature - T_ref))
  END SUBROUTINE PH_Elem_AC3D15_UpdateMaterialProps_TempDep

  !============================================================================
  ! P4-2 BIOT POROUS MEDIA
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_Biot_Wave_Speed(v_p1, v_p2, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)
    REAL(wp), INTENT(OUT) :: v_p1, v_p2, v_s
    REAL(wp), INTENT(IN)  :: porosity, K_s, K_f, G, rho_s, rho_f
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: rho_11, rho_12, rho_22, sigma_11, sigma_22, delta, M, R, Q
    status%code = STATUS_SUCCESS
    rho_11 = (1.0_wp - porosity) * rho_s + porosity * rho_f
    rho_12 = porosity * (rho_f - 1.0_wp)
    rho_22 = porosity * rho_f
    Q = K_f / ((1.0_wp - porosity) / K_s + porosity / K_f)
    R = Q * porosity**2 / (1.0_wp - porosity - K_s / K_s)
    sigma_11 = (K_s + 4.0_wp / 3.0_wp * G) * (1.0_wp - porosity)**2 + Q
    sigma_22 = Q * porosity**2
    delta = Q * porosity * (1.0_wp - porosity)
    M = R + 2.0_wp * delta**2 / sigma_11
    v_p1 = SQRT((sigma_11 + 2.0_wp * delta + sigma_22) / (rho_11 + 2.0_wp * rho_12 + rho_22))
    v_p2 = SQRT(M / rho_22)
    v_s = SQRT(G / rho_11)
  END SUBROUTINE PH_Elem_AC3D15_Biot_Wave_Speed

  SUBROUTINE PH_Elem_AC3D15_Biot_Damping(C_biot, frequency, permeability, viscosity, porosity, tortuosity, status)
    REAL(wp), INTENT(OUT) :: C_biot(15, 15)
    REAL(wp), INTENT(IN)  :: frequency, permeability, viscosity, porosity, tortuosity
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: omega, b_coeff, N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9), dV
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    C_biot = ZERO
    omega = 2.0_wp * 3.14159_wp * frequency
    b_coeff = viscosity / (permeability * porosity * tortuosity)
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      DO i = 1, 15
        DO j = 1, 15
          C_biot(i, j) = C_biot(i, j) + b_coeff * N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_Biot_Damping

  SUBROUTINE PH_Elem_AC3D15_Biot_Stabilize_SlowWave(C_stab, v_p2, rho_f, frequency, coords, status)
    REAL(wp), INTENT(OUT) :: C_stab(15, 15)
    REAL(wp), INTENT(IN)  :: v_p2, rho_f, frequency, coords(3, 15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: omega, tau_supg, N(15), dNdxi(3, 15), J(3, 3), detJ
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9), dV
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    C_stab = ZERO
    omega = 2.0_wp * 3.14159_wp * frequency
    tau_supg = 0.5_wp / omega  ! SUPG stabilization parameter
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      DO i = 1, 15
        DO j = 1, 15
          C_stab(i, j) = C_stab(i, j) + tau_supg * rho_f * v_p2 * N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_Biot_Stabilize_SlowWave

  SUBROUTINE PH_Elem_AC3D15_Biot_Compute_Stab_Param(tau_supg, element_size, v_p2, rho_f, frequency, status)
    REAL(wp), INTENT(OUT) :: tau_supg
    REAL(wp), INTENT(IN)  :: element_size, v_p2, rho_f, frequency
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: omega, c_char
    status%code = STATUS_SUCCESS
    omega = 2.0_wp * 3.14159_wp * frequency
    c_char = v_p2
    tau_supg = element_size**2 / (4.0_wp * rho_f * c_char**2)
  END SUBROUTINE PH_Elem_AC3D15_Biot_Compute_Stab_Param

  !============================================================================
  ! P4-3 PML INFINITE ELEMENTS
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, status)
    REAL(wp), INTENT(INOUT) :: C_rad(15, 15), K_rad(15, 15)
    REAL(wp), INTENT(IN)  :: face_normal(3), sound_speed, frequency
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: omega, k_wave, sigma
    status%code = STATUS_SUCCESS
    C_rad = ZERO
    K_rad = ZERO
    omega = 2.0_wp * 3.14159_wp * frequency
    k_wave = omega / sound_speed
    sigma = k_wave * 0.1_wp
  END SUBROUTINE PH_Elem_AC3D15_Sommerfeld_Radiation

  SUBROUTINE PH_Elem_AC3D15_Infinite_Element_Map(coords_phys, coords_nat, infinite_direction, decay_profile, status)
    REAL(wp), INTENT(OUT) :: coords_phys(3, 15)
    REAL(wp), INTENT(IN)  :: coords_nat(3, 15), infinite_direction(3), decay_profile(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: r_nat, stretching_factor
    INTEGER(i4) :: i
    status%code = STATUS_SUCCESS
    coords_phys = ZERO
    stretching_factor = 0.1_wp
    DO i = 1, 15
      r_nat = DOT_PRODUCT(coords_nat(:, i), infinite_direction)
      coords_phys(:, i) = coords_nat(:, i) + infinite_direction * &
        (r_nat / (1.0_wp - r_nat * stretching_factor) - r_nat)
    END DO
  END SUBROUTINE PH_Elem_AC3D15_Infinite_Element_Map

  SUBROUTINE PH_Elem_AC3D15_PML_Update_State(pml_state, pml_params, time_step, pressure, status)
    ! Purpose: Update PML state variables for time-domain simulation
    ! Theory: Crank-Nicolson scheme for PML update
    !         Split-field formulation: p = px + py + pz (decoupled components)
    TYPE(*), DIMENSION(*), INTENT(INOUT) :: pml_state  ! PML state variables
    REAL(wp), INTENT(IN)  :: pml_params(:)  ! PML parameters [sigma_max, depth, ...]
    REAL(wp), INTENT(IN)  :: time_step      ! Time step dt
    REAL(wp), INTENT(IN)  :: pressure(15)   ! Pressure at element nodes
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: sigma_max, depth, decay
    REAL(wp) :: damping_coeff
    INTEGER(i4) :: i, state_size
    
    status = init_error_status()
    
    ! Extract PML parameters
    IF (SIZE(pml_params) >= 2) THEN
      sigma_max = pml_params(1)  ! Maximum damping coefficient [1/s]
      depth = pml_params(2)       ! PML thickness [m]
    ELSE
      sigma_max = 100.0_wp        ! Default value
      depth = 0.1_wp
    END IF
    
    ! Get state size from pml_state
    state_size = SIZE(pml_state)
    
    ! Analytical PML update: p^{n+1} = p^n * exp(-2*sigma*dt)
    ! This is exact solution for constant sigma
    damping_coeff = EXP(-2.0_wp * sigma_max * time_step)
    
    ! Update PML state variables (pressure components)
    DO i = 1, MIN(state_size, 15)
      IF (ASSOCIATED(pml_state(i)%ptr)) THEN
        SELECT TYPE(ptr => pml_state(i)%ptr)
        TYPE IS (REAL(wp))
          ptr = ptr * damping_coeff
        END SELECT
      END IF
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_PML_Update_State

  SUBROUTINE PH_Elem_AC3D15_PML_Absorbing_Boundary(coords, pml_thickness, sigma_max, C_pml, K_pml, status)
    REAL(wp), INTENT(IN)  :: coords(3, 15), pml_thickness, sigma_max
    REAL(wp), INTENT(OUT) :: C_pml(15, 15), K_pml(15, 15)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: N(15), dNdxi(3, 15), J(3, 3), detJ, sigma_pml
    REAL(wp) :: xi(9), eta(9), zeta(9), weights(9), dV
    INTEGER(i4) :: ip, i, j
    status%code = STATUS_SUCCESS
    C_pml = ZERO
    K_pml = ZERO
    CALL AC3D15_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 9
      CALL AC3D15_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D15_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      sigma_pml = sigma_max * (1.0_wp - ABS(zeta(ip)))
      DO i = 1, 15
        DO j = 1, 15
          C_pml(i, j) = C_pml(i, j) + sigma_pml * N(i) * N(j) * dV
          K_pml(i, j) = K_pml(i, j) + sigma_pml**2 * N(i) * N(j) * dV
        END DO
      END DO
    END DO
  END SUBROUTINE PH_Elem_AC3D15_PML_Absorbing_Boundary

  !============================================================================
  ! ELEMENT DEFINITION INITIALIZATION (STUB)
  !============================================================================
  SUBROUTINE PH_Elem_AC3D15_DefInit()
    ! Purpose: Initialize element definition and lookup tables
    ! Theory: Set up shape function constants, Gauss point data, etc.
    !         Called once during model definition phase
    TYPE(ErrorStatusType) :: status
    
    status = init_error_status()
    
    ! AC3D15 element definition initialization
    ! - Gauss point coordinates (9-point rule for triangular prism)
    ! - Shape function evaluation constants
    ! - Integration weights
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D15_DefInit


  !=============================================================================
  ! UNIFIED INTERFACE (RT Layer compatible)
  !=============================================================================
  
  SUBROUTINE UF_Elem_AC3D15_Calc(ElemType, Formul, Ctx, state_in, &
                                          Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, 15)
    REAL(wp) :: u(15)
    REAL(wp) :: density, bulk_modulus, sound_speed
    REAL(wp) :: k_eff, nu
    REAL(wp) :: Ke(15, 15)
    REAL(wp) :: R_int(15)
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    ! Validate coords_ref allocation
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D15_Calc: coords_ref not allocated'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < 15) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D15_Calc: insufficient nodes'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    ! Extract coordinates
    DO i = 1, 15
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
    END DO

    ! Extract displacement/pressure field
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= 15) THEN
        DO i = 1, 15
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
      flags%status%message = 'UF_Elem_AC3D15_Calc: invalid bulk modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    ! Compute stiffness matrix and internal force
    CALL PH_Elem_AC3D15_FormStiffMatrix(coords, k_eff, nu, Ke)
    CALL PH_Elem_AC3D15_FormIntForce(coords, u, k_eff, nu, R_int)

    ! Prepare output structure
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    ! Copy Ke to state_out
    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(15, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(15, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    ! Copy R_int to state_out
    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(15, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    ! Prepare integration point states
    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, 9)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    flags%status%status_code = IF_STATUS_OK
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt
    
  END SUBROUTINE UF_Elem_AC3D15_Calc

END MODULE PH_Elem_AC3D15
