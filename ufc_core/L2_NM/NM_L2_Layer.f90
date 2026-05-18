!===============================================================================
! MODULE: NM_L2_Layer
! LAYER:  L2_NM
! DOMAIN: (Layer-level aggregation — all 6 algorithm domains)
! ROLE:   Layer  — top-level L2 aggregation container
! BRIEF:  Aggregates Base/LinAlg/Solver/Eigen/TimeInt/Bridge domain
!         containers into a single unified access point.
!
! Theory chain:
!   L2_NM provides pure mathematical algorithms (no FEM knowledge).
!   CSR sparse format is the universal matrix representation.
!   External libraries are isolated in Bridge domain only.
!
! Logic chain:
!   UFC_GlobalContainer holds this as nm_layer field
!   L5_RT / L4_PH access via g_ufc_global%nm_layer%<domain>
!   L6_AP configures solver parameters at Job startup
!
! Data chain:
!   Container path: g_ufc_global%nm_layer
!   Contains 6 domain fields (base through bridge)
!   Init order:     1-base -> 2-linAlg -> 3-solver -> 4-eigen -> 5-timeInt -> 6-bridge
!   Finalize order: 6-bridge -> 5-timeInt -> 4-eigen -> 3-solver -> 2-linAlg -> 1-base
!
! Contents:
!   Types:
!     NM_L2_LayerContainer  — Aggregation of all 6 domain containers
!   Subroutines (A-Z):
!     NM_L2_Finalize        — P0 Finalize all domains in reverse init order
!     NM_L2_Init            — P0 Initialize all domains in dependency order
!
! Status: ACTIVE
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_L2_Layer
  USE IF_Prec_Core,                    ONLY: wp, i4
  USE IF_Err_Brg,                 ONLY: ErrorStatusType, init_error_status, &
                                         IF_STATUS_OK, IF_STATUS_INVALID
  USE NM_Base_Core,        ONLY: NM_Base_Domain
  USE NM_LinAlg_Domain,   ONLY: NM_LinAlg_Domain
  USE NM_Solv_Mgr,      ONLY: NM_Solver_Domain
  USE NM_Eigen_Core,       ONLY: NM_Eigen_Domain
  USE NM_TimeInt_Mgr,     ONLY: NM_TimeInt_Domain
  USE NM_Brg_Mgr,      ONLY: NM_Bridge_Domain
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! NM_L2_LayerContainer — Second-level container (6 domains)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_L2_LayerContainer
    TYPE(NM_Base_Domain)    :: base
    TYPE(NM_LinAlg_Domain)  :: linAlg
    TYPE(NM_Solver_Domain)  :: solver
    TYPE(NM_Eigen_Domain)   :: eigen
    TYPE(NM_TimeInt_Domain) :: timeInt
    TYPE(NM_Bridge_Domain)  :: bridge
    LOGICAL                 :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => NM_L2_Init
    PROCEDURE :: Finalize => NM_L2_Finalize
  END TYPE NM_L2_LayerContainer

CONTAINS

  !====================================================================
  ! NM_L2_Finalize — P0 Finalize all domains in REVERSE init order
  !====================================================================
  SUBROUTINE NM_L2_Finalize(this)
    CLASS(NM_L2_LayerContainer), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN

    CALL this%bridge%Finalize()
    CALL this%timeInt%Finalize()
    CALL this%eigen%Finalize()
    CALL this%solver%Finalize()
    CALL this%linAlg%Finalize()
    CALL this%base%Finalize()

    this%initialized = .FALSE.

  END SUBROUTINE NM_L2_Finalize

  !====================================================================
  ! NM_L2_Init — P0 Initialize all domains in dependency order
  !====================================================================
  SUBROUTINE NM_L2_Init(this, status)
    CLASS(NM_L2_LayerContainer), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (this%initialized) CALL this%Finalize()

    CALL this%base%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL this%linAlg%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL this%solver%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL this%eigen%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL this%timeInt%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL this%bridge%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    this%initialized = .TRUE.

  END SUBROUTINE NM_L2_Init

END MODULE NM_L2_Layer