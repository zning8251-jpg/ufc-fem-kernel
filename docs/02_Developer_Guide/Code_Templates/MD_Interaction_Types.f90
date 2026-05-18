!=======================================================================
! Module: MD_Interaction_Types                            [Template v1.0]
! Layer:  L3_MD �?Model Description Layer
! Domain: Surface interaction / contact property descriptions
!
! Purpose:
!   Provides Desc types for surface interaction properties (*SURFACE
!   INTERACTION) including normal contact models, thermal conductance
!   and radiation.  Complements MD_Contact_Types.f90 which covers the
!   UINTER/GAPCON subroutine hooks.
!=======================================================================
MODULE MD_Interaction_Types
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  ! Normal contact model flags
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INTERACTION_HARD_CONTACT_LAGRANGE  = 0_i4  ! hard (default)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INTERACTION_SOFT_CONTACT_LINEAR    = 1_i4  ! linear soft  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INTERACTION_SOFT_CONTACT_TABULAR   = 2_i4  ! tabular  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INTERACTION_SOFT_CONTACT_EXPONENTIAL = 3_i4 ! exponential  ! migrated

  !=====================================================================
  ! MD_SurfInteract_Desc �?surface interaction property set description
  !   *SURFACE INTERACTION, NAME=
  !=====================================================================
  TYPE, PUBLIC :: MD_SurfInteract_Desc
    CHARACTER(LEN=80) :: inter_name   = ' '   ! surface interaction name
    INTEGER(i4)       :: normal_model = MD_INTERACTION_HARD_CONTACT_LAGRANGE
    LOGICAL           :: augmented_lagrange = .FALSE.  ! augmented Lagrange
    LOGICAL           :: fric_active  = .FALSE.        ! friction attached
    LOGICAL           :: thermal      = .FALSE.        ! thermal contact
    LOGICAL           :: is_active    = .FALSE.
  END TYPE MD_SurfInteract_Desc

  !=====================================================================
  ! MD_HardContact_Desc �?hard (rigid) normal contact description
  !   *CONTACT PAIR + *SURFACE BEHAVIOR (hard)
  !=====================================================================
  TYPE, PUBLIC :: MD_HardContact_Desc
    CHARACTER(LEN=80) :: inter_name  = ' '
    REAL(wp)    :: pressure_overshoot = 0.0_wp  ! allowable penetration overshoot
    LOGICAL     :: no_separation      = .FALSE.  ! no-separation (tension) flag
    REAL(wp)    :: c0                 = 0.0_wp  ! clearance at zero pressure
    LOGICAL     :: is_active          = .FALSE.
  END TYPE MD_HardContact_Desc

  !=====================================================================
  ! MD_SoftContact_Desc �?soft (compliant) normal contact description
  !   *SURFACE BEHAVIOR with softened contact
  !=====================================================================
  TYPE, PUBLIC :: MD_SoftContact_Desc
    CHARACTER(LEN=80) :: inter_name  = ' '
    INTEGER(i4) :: model_type   = MD_INTERACTION_SOFT_CONTACT_EXPONENTIAL
    REAL(wp)    :: p0           = 0.0_wp   ! contact pressure at zero clearance
    REAL(wp)    :: c0           = 0.0_wp   ! clearance at zero pressure
    REAL(wp)    :: stiffness    = 0.0_wp   ! linear stiffness (linear model)
    INTEGER(i4) :: n_table_pts  = 0_i4    ! tabular points
    REAL(wp), ALLOCATABLE :: table_data(:,:)  ! [2, n_table_pts]: clearance, pressure
    LOGICAL     :: is_active    = .FALSE.
  END TYPE MD_SoftContact_Desc

  !=====================================================================
  ! MD_ThermalConduct_Desc �?thermal contact conductance description
  !   *GAP CONDUCTANCE (built-in, non-user)
  !=====================================================================
  TYPE, PUBLIC :: MD_ThermalConduct_Desc
    CHARACTER(LEN=80) :: inter_name  = ' '
    REAL(wp)    :: h_ref         = 0.0_wp   ! reference gap conductance
    LOGICAL     :: pressure_dep  = .FALSE.  ! pressure-dependent h
    LOGICAL     :: clearance_dep = .TRUE.   ! clearance-dependent h
    INTEGER(i4) :: n_table_pts   = 0_i4
    REAL(wp), ALLOCATABLE :: table_data(:,:)  ! [2, n_pts]: clearance/pressure, h
    LOGICAL     :: is_active     = .FALSE.
  END TYPE MD_ThermalConduct_Desc

  !=============================================================================
  ! MD_Interaction_Domain  Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_Interaction_Domain
    TYPE(MD_ThermalConduct_Desc), ALLOCATABLE :: thermal_conduct(:)   ! [n_thermal]
    TYPE(MD_SurfInteract_Desc),   ALLOCATABLE :: surf_interactions(:)    ! [n_surf]
    TYPE(MD_SoftContact_Desc),    ALLOCATABLE :: soft_contacts(:)   ! [n_soft]
    INTEGER(i4) :: n_thermal       = 0_i4
    INTEGER(i4) :: n_surf     = 0_i4
    INTEGER(i4) :: n_soft        = 0_i4
    INTEGER(i4) :: max_interactions = 0_i4
    LOGICAL     :: initialized  = .FALSE.
    LOGICAL     :: frozen       = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => MD_Interaction_Domain_Init
    PROCEDURE :: Finalize => MD_Interaction_Domain_Finalize
  END TYPE MD_Interaction_Domain

CONTAINS

  SUBROUTINE MD_Interaction_Domain_Init(this, cap_interactions, status)
    CLASS(MD_Interaction_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                  INTENT(IN)    :: cap_interactions
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL MD_Interaction_Domain_Finalize(this)
    IF (cap_interactions < 1_i4) THEN
      CALL init_error_status(status, IF_STATUS_INVALID, &
          message='MD_Interaction_Domain_Init: cap_interactions must be >= 1')
      RETURN
    END IF
    ALLOCATE(this%thermal_conduct(cap_interactions/3+1))
    ALLOCATE(this%surf_interactions(cap_interactions/3+1))
    ALLOCATE(this%soft_contacts(cap_interactions/3+1))
    this%n_thermal       = 0_i4
    this%n_surf     = 0_i4
    this%n_soft        = 0_i4
    this%max_interactions = cap_interactions
    this%initialized  = .TRUE.
    this%frozen       = .FALSE.
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE MD_Interaction_Domain_Init

  SUBROUTINE MD_Interaction_Domain_Finalize(this)
    CLASS(MD_Interaction_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%thermal_conduct))  DEALLOCATE(this%thermal_conduct)
    IF (ALLOCATED(this%surf_interactions))   DEALLOCATE(this%surf_interactions)
    IF (ALLOCATED(this%soft_contacts))  DEALLOCATE(this%soft_contacts)
    this%n_thermal       = 0_i4
    this%n_surf     = 0_i4
    this%n_soft        = 0_i4
    this%max_interactions = 0_i4
    this%initialized  = .FALSE.
    this%frozen       = .FALSE.
  END SUBROUTINE MD_Interaction_Domain_Finalize

END MODULE MD_Interaction_Types