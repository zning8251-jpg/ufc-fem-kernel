!===============================================================================
! MODULE: PH_Mat_Core_Types
! Purpose: Core material point types for MatPoint_In/Out paradigm
!   Used by: Hill, J2, Drucker-Prager, Mohr-Coulomb, CamClay, Castani
!-------------------------------------------------------------------------------
MODULE PH_Mat_Core_Types
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PUBLIC

  !---------------------------------------------------------------------------
  ! TYPE: MatPoint_In — Material point input (UMAT-style bridge)
  !---------------------------------------------------------------------------
  TYPE :: MatPoint_In
    REAL(wp), ALLOCATABLE :: props(:)      ! Material properties
    REAL(wp) :: strain_inc(6) = 0.0_wp     ! Strain increment (Voigt)
    REAL(wp) :: sigma_old(6)  = 0.0_wp     ! Old stress (Voigt)
    INTEGER(i4) :: ntens = 6_i4            ! Number of tensor components
    REAL(wp), ALLOCATABLE :: statev(:)     ! State variables
  END TYPE MatPoint_In

  !---------------------------------------------------------------------------
  ! TYPE: MatPoint_Out — Material point output (UMAT-style bridge)
  !---------------------------------------------------------------------------
  TYPE :: MatPoint_Out
    REAL(wp) :: stress(6)   = 0.0_wp       ! Updated stress (Voigt)
    REAL(wp) :: ddsdde(6,6) = 0.0_wp       ! Material tangent (Voigt)
    REAL(wp) :: pnewdt      = 1.0_wp       ! Time step suggestion
    REAL(wp), ALLOCATABLE :: statev(:)     ! Updated state variables
    TYPE(ErrorStatusType) :: status        ! Error status
  END TYPE MatPoint_Out

  !---------------------------------------------------------------------------
  ! TYPE: MatInit_In — Material initialization input
  !---------------------------------------------------------------------------
  TYPE :: MatInit_In
    REAL(wp), ALLOCATABLE :: props(:)      ! Material properties
    INTEGER(i4) :: nStatev = 0_i4          ! Number of state variables
  END TYPE MatInit_In

  !---------------------------------------------------------------------------
  ! TYPE: MatInit_Out — Material initialization output
  !---------------------------------------------------------------------------
  TYPE :: MatInit_Out
    REAL(wp), ALLOCATABLE :: statev(:)     ! Initialized state variables
    TYPE(ErrorStatusType) :: status        ! Error status
  END TYPE MatInit_Out

END MODULE PH_Mat_Core_Types
