!===============================================================================
! MODULE: PH_Mat_Therm_Iso_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Thermal expansion and temperature-dependent moduli for TMC
!   W1: thermal props (**alpha**, **T_ref**, tables) from **desc%props**; coupled stiffness uses same slot truth as mechanical branch.
!===============================================================================
!
! Design Document: DESIGN_Mat_ConstitutiveKernels.md §10
! Reference: Boley & Weiner (1960) Theory of Thermal Stresses
!            Zienkiewicz & Taylor (2000) The Finite Element Method, Vol.2
!
! Thermal Strain (§10.2):
!   ε_th = α(T) · (T - T_ref) · m
!   where: α(T) = coefficient of thermal expansion [1/K]
!          T_ref = stress-free reference temperature [K]
!          m = [1,1,1,0,0,0]^T (isotropic) or [α1,α2,α3,0,0,0]^T (ortho)
!
! Temperature-Dependent Moduli (§10.3):
!   E(T) = E_0 + dE_dT · (T - T_ref)  (linear)
!   or E(T) from tabulated data (piecewise linear interpolation)
!
! Mechanical Stress (§10.4):
!   σ = D_el(T) : (ε_total - ε_th(T))
!   C_tan = D_el(T)  (secant tangent for thermal coupling)
!
! CONTRACT Compliance:
!   - ErrorStatusType on all public procedures (no STOP)
!   - wp/i4 precision from IF_Prec_Core
!   - Intent declarations on all arguments
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
!
!>>> UFC_PH_QUENCH | Domain:Material/Thermal | Role:Core | FuncSet:Compute,Init,Validate | HotPath:Yes
!>>> UFC_PH_CONTRACT | Material/CONTRACT.md
!
MODULE PH_Mat_Therm_Iso_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public Interface
  !-----------------------------------------------------------------------------
  PUBLIC :: PH_Mat_Therm_Compute_Stress
  PUBLIC :: PH_Mat_Therm_Compute_Tangent
  PUBLIC :: PH_Mat_Therm_Update_State
  PUBLIC :: PH_Mat_Therm_Validate_Params
  PUBLIC :: PH_Mat_Therm_Init
  PUBLIC :: PH_Mat_Therm_Compute_ThermalStrain
  PUBLIC :: PH_Mat_Therm_Get_Modulus

  !-----------------------------------------------------------------------------
  ! Constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_THERM_MAX_TABLE = 20_i4  ! Max temp points

  !-----------------------------------------------------------------------------
  ! TYPE: PH_Therm_Props — Thermal material properties (P2 nested)
  !-----------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Therm_Cfg_Elastic
    REAL(wp) :: E_ref    = 0.0_wp     ! Young's modulus at T_ref [Pa]
    REAL(wp) :: nu       = 0.0_wp     ! Poisson's ratio [-] (assumed T-independent)
    REAL(wp) :: T_ref    = 293.0_wp   ! Reference temperature [K]
  END TYPE PH_Therm_Cfg_Elastic

  TYPE, PUBLIC :: PH_Therm_Cfg_Expansion
    REAL(wp) :: alpha_iso = 0.0_wp    ! Isotropic CTE [1/K]
    REAL(wp) :: alpha_ortho(3) = 0.0_wp ! Orthotropic CTE [α1, α2, α3] [1/K]
    LOGICAL  :: is_orthotropic = .FALSE.
  END TYPE PH_Therm_Cfg_Expansion

  TYPE, PUBLIC :: PH_Therm_Cfg_TempDep_Lin
    REAL(wp) :: dE_dT    = 0.0_wp     ! dE/dT slope [Pa/K] (typically negative)
  END TYPE PH_Therm_Cfg_TempDep_Lin

  TYPE, PUBLIC :: PH_Therm_Cfg_TempDep_Table
    LOGICAL  :: use_table = .FALSE.
    INTEGER(i4) :: n_table = 0_i4     ! Number of table entries
    REAL(wp) :: T_table(PH_THERM_MAX_TABLE) = 0.0_wp  ! Temperature points [K]
    REAL(wp) :: E_table(PH_THERM_MAX_TABLE) = 0.0_wp  ! E at each T point [Pa]
  END TYPE PH_Therm_Cfg_TempDep_Table

  TYPE, PUBLIC :: PH_Therm_Props
    TYPE(PH_Therm_Cfg_Elastic)       :: elastic
    TYPE(PH_Therm_Cfg_Expansion)     :: expansion
    TYPE(PH_Therm_Cfg_TempDep_Lin)   :: tempdep_lin
    TYPE(PH_Therm_Cfg_TempDep_Table) :: tempdep_table
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Therm_Props

  !-----------------------------------------------------------------------------
  ! TYPE: PH_Therm_State — Integration point thermal state (P2 nested)
  !-----------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Therm_St_Stress
    REAL(wp) :: stress(6)     = 0.0_wp  ! Mechanical stress [Pa]
    REAL(wp) :: strain_th(6)  = 0.0_wp  ! Thermal strain [-]
  END TYPE PH_Therm_St_Stress

  TYPE, PUBLIC :: PH_Therm_St_Temp
    REAL(wp) :: E_current     = 0.0_wp  ! Current modulus at T [Pa]
    REAL(wp) :: T_current     = 293.0_wp ! Current temperature [K]
  END TYPE PH_Therm_St_Temp

  TYPE, PUBLIC :: PH_Therm_St_Tangent
    REAL(wp) :: C_tan(6,6)    = 0.0_wp  ! Current tangent [Pa]
  END TYPE PH_Therm_St_Tangent

  TYPE, PUBLIC :: PH_Therm_State
    TYPE(PH_Therm_St_Stress)  :: stress
    TYPE(PH_Therm_St_Temp)    :: temp
    TYPE(PH_Therm_St_Tangent) :: tangent
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Therm_State

CONTAINS

  !===========================================================================
  ! PH_Mat_Therm_Validate_Params — Validate thermal material parameters
  !===========================================================================
  SUBROUTINE PH_Mat_Therm_Validate_Params(props, ierr)
    TYPE(PH_Therm_Props),   INTENT(IN)  :: props
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    CALL init_error_status(ierr)

    IF (props%elastic%E_ref <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Therm]: E_ref must be positive'
      RETURN
    END IF
    IF (props%elastic%nu <= -1.0_wp .OR. props%elastic%nu >= 0.5_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Therm]: nu must be in (-1, 0.5)'
      RETURN
    END IF
    IF (props%elastic%T_ref <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Therm]: T_ref must be positive (absolute temperature)'
      RETURN
    END IF
    IF (props%tempdep_table%use_table .AND. props%tempdep_table%n_table < 2) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Therm]: Table requires at least 2 points'
      RETURN
    END IF

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Therm_Validate_Params

  !===========================================================================
  ! PH_Mat_Therm_Init — Initialize thermal context
  !===========================================================================
  SUBROUTINE PH_Mat_Therm_Init(props, state, ierr)
    TYPE(PH_Therm_Props),   INTENT(IN)  :: props
    TYPE(PH_Therm_State),   INTENT(OUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    CALL PH_Mat_Therm_Validate_Params(props, ierr)
    IF (ierr%status_code /= IF_STATUS_OK) RETURN

    state%stress%stress    = 0.0_wp
    state%stress%strain_th = 0.0_wp
    state%temp%E_current = props%elastic%E_ref
    state%temp%T_current = props%elastic%T_ref
    state%tangent%C_tan     = 0.0_wp

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Therm_Init

  !===========================================================================
  ! PH_Mat_Therm_Get_Modulus — Get temperature-dependent Young's modulus
  !
  ! Linear: E(T) = E_ref + dE_dT * (T - T_ref)
  ! Table:  piecewise linear interpolation
  !===========================================================================
  SUBROUTINE PH_Mat_Therm_Get_Modulus(props, T_curr, E_curr, ierr)
    TYPE(PH_Therm_Props),   INTENT(IN)  :: props
    REAL(wp),               INTENT(IN)  :: T_curr   ! Current temperature [K]
    REAL(wp),               INTENT(OUT) :: E_curr   ! Modulus at T [Pa]
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    INTEGER(i4) :: i
    REAL(wp) :: frac

    CALL init_error_status(ierr)

    IF (props%tempdep_table%use_table .AND. props%tempdep_table%n_table >= 2) THEN
      ! Piecewise linear interpolation from table
      IF (T_curr <= props%tempdep_table%T_table(1)) THEN
        E_curr = props%tempdep_table%E_table(1)
      ELSE IF (T_curr >= props%tempdep_table%T_table(props%tempdep_table%n_table)) THEN
        E_curr = props%tempdep_table%E_table(props%tempdep_table%n_table)
      ELSE
        DO i = 1, props%tempdep_table%n_table - 1
          IF (T_curr >= props%tempdep_table%T_table(i) .AND. T_curr < props%tempdep_table%T_table(i+1)) THEN
            frac = (T_curr - props%tempdep_table%T_table(i)) / &
                   (props%tempdep_table%T_table(i+1) - props%tempdep_table%T_table(i))
            E_curr = props%tempdep_table%E_table(i) + frac * (props%tempdep_table%E_table(i+1) - props%tempdep_table%E_table(i))
            EXIT
          END IF
        END DO
      END IF
    ELSE
      ! Linear model
      E_curr = props%elastic%E_ref + props%tempdep_lin%dE_dT * (T_curr - props%elastic%T_ref)
    END IF

    ! Safety: ensure E > 0
    IF (E_curr <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_Mat_Therm]: E(T) <= 0 at current temperature'
      E_curr = props%elastic%E_ref * 0.01_wp  ! Fallback to 1% of reference
      RETURN
    END IF

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Therm_Get_Modulus

  !===========================================================================
  ! PH_Mat_Therm_Compute_ThermalStrain — Compute thermal strain vector
  !
  ! Isotropic: ε_th = α · ΔT · [1,1,1,0,0,0]^T
  ! Orthotropic: ε_th = [α1,α2,α3,0,0,0]^T · ΔT
  !===========================================================================
  SUBROUTINE PH_Mat_Therm_Compute_ThermalStrain(props, T_curr, strain_th, ierr)
    TYPE(PH_Therm_Props),   INTENT(IN)  :: props
    REAL(wp),               INTENT(IN)  :: T_curr      ! Current temperature [K]
    REAL(wp),               INTENT(OUT) :: strain_th(6) ! Thermal strain
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    REAL(wp) :: dT

    CALL init_error_status(ierr)

    dT = T_curr - props%elastic%T_ref
    strain_th = 0.0_wp

    IF (props%expansion%is_orthotropic) THEN
      strain_th(1) = props%expansion%alpha_ortho(1) * dT
      strain_th(2) = props%expansion%alpha_ortho(2) * dT
      strain_th(3) = props%expansion%alpha_ortho(3) * dT
    ELSE
      strain_th(1) = props%expansion%alpha_iso * dT
      strain_th(2) = props%expansion%alpha_iso * dT
      strain_th(3) = props%expansion%alpha_iso * dT
    END IF
    ! Shear components: strain_th(4:6) = 0 (no thermal shear)

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Therm_Compute_ThermalStrain

  !===========================================================================
  ! PH_Mat_Therm_Compute_Stress — Compute thermo-mechanical stress
  !
  ! σ = D_el(T) : (ε_total - ε_th(T))
  !===========================================================================
  SUBROUTINE PH_Mat_Therm_Compute_Stress(props, strain_total, T_curr, &
                                           state, stress, ierr)
    TYPE(PH_Therm_Props),   INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: strain_total(6)
    REAL(wp),               INTENT(IN)    :: T_curr
    TYPE(PH_Therm_State),   INTENT(INOUT) :: state
    REAL(wp),               INTENT(OUT)   :: stress(6)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    ! Local
    REAL(wp) :: E_curr, G_curr, lambda
    REAL(wp) :: strain_mech(6)    ! Mechanical strain
    REAL(wp) :: strain_th(6)      ! Thermal strain
    REAL(wp) :: D_el(6,6)         ! Elastic stiffness at T
    INTEGER(i4) :: i, j

    CALL init_error_status(ierr)

    ! Get temperature-dependent modulus
    CALL PH_Mat_Therm_Get_Modulus(props, T_curr, E_curr, ierr)
    IF (ierr%status_code /= IF_STATUS_OK) RETURN
    state%temp%E_current = E_curr
    state%temp%T_current = T_curr

    ! Compute thermal strain
    CALL PH_Mat_Therm_Compute_ThermalStrain(props, T_curr, strain_th, ierr)
    IF (ierr%status_code /= IF_STATUS_OK) RETURN
    state%stress%strain_th = strain_th

    ! Mechanical strain = total - thermal
    strain_mech = strain_total - strain_th

    ! Build elastic stiffness at current temperature
    G_curr = E_curr / (2.0_wp * (1.0_wp + props%elastic%nu))
    lambda = E_curr * props%elastic%nu / ((1.0_wp + props%elastic%nu) * (1.0_wp - 2.0_wp * props%elastic%nu))

    D_el = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        D_el(i,j) = lambda
      END DO
      D_el(i,i) = lambda + 2.0_wp * G_curr
    END DO
    D_el(4,4) = G_curr
    D_el(5,5) = G_curr
    D_el(6,6) = G_curr

    ! Stress: σ = D_el(T) : ε_mech
    stress = MATMUL(D_el, strain_mech)

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Therm_Compute_Stress

  !===========================================================================
  ! PH_Mat_Therm_Compute_Tangent — Compute elastic tangent at current T
  !===========================================================================
  SUBROUTINE PH_Mat_Therm_Compute_Tangent(props, T_curr, C_tangent, ierr)
    TYPE(PH_Therm_Props),   INTENT(IN)  :: props
    REAL(wp),               INTENT(IN)  :: T_curr
    REAL(wp),               INTENT(OUT) :: C_tangent(6,6)
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    REAL(wp) :: E_curr, G_curr, lambda
    INTEGER(i4) :: i, j

    CALL init_error_status(ierr)

    CALL PH_Mat_Therm_Get_Modulus(props, T_curr, E_curr, ierr)
    IF (ierr%status_code /= IF_STATUS_OK) RETURN

    G_curr = E_curr / (2.0_wp * (1.0_wp + props%elastic%nu))
    lambda = E_curr * props%elastic%nu / ((1.0_wp + props%elastic%nu) * (1.0_wp - 2.0_wp * props%elastic%nu))

    C_tangent = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        C_tangent(i,j) = lambda
      END DO
      C_tangent(i,i) = C_tangent(i,i) + 2.0_wp * G_curr
    END DO
    C_tangent(4,4) = G_curr
    C_tangent(5,5) = G_curr
    C_tangent(6,6) = G_curr

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Therm_Compute_Tangent

  !===========================================================================
  ! PH_Mat_Therm_Update_State — Update state after convergence
  !===========================================================================
  SUBROUTINE PH_Mat_Therm_Update_State(props, stress, C_tangent, state, ierr)
    TYPE(PH_Therm_Props),   INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: stress(6)
    REAL(wp),               INTENT(IN)    :: C_tangent(6,6)
    TYPE(PH_Therm_State),   INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    CALL init_error_status(ierr)
    state%stress%stress = stress
    state%tangent%C_tan  = C_tangent
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Therm_Update_State

END MODULE PH_Mat_Therm_Iso_Core
