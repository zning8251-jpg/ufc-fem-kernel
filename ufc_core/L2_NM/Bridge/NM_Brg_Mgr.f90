!===============================================================================
! MODULE: NM_Brg_Mgr
! LAYER:  L2_NM
! DOMAIN: Bridge
! ROLE:   Mgr — bridge domain container and external library isolation
! BRIEF:  External library isolation layer. MUMPS, LAPACK, cuSPARSE, AGMG,
!         SparsePak adapters. #ifdef macros for external libs ONLY here.
!
! Theory chain:
!   External library isolation: all external solver calls wrapped in
!   Bridge adapters. Unavailable lib returns NM_ERR_EXTERNAL_NOT_AVAILABLE.
!
! Logic chain:
!   NM Solver calls Bridge adapter for direct solve (MUMPS)
!   NM Solver calls Bridge adapter for GPU solve (cuSPARSE)
!   NM Solver calls Bridge adapter for AMG preconditioner (AGMG)
!
! Data chain:
!   Container path: g_ufc_global%nm_layer%bridge
!   Config: external library availability flags
!   Lifecycle: Process-level (detected once at startup)
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_Brg_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! NM_Brg_ExtLibFlags_Desc — External library availability (immutable after init)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Brg_ExtLibFlags_Desc
    LOGICAL :: hasMUMPS    = .FALSE.
    LOGICAL :: hasLAPACK   = .TRUE.    ! Typically always available
    LOGICAL :: hasCuSPARSE = .FALSE.
    LOGICAL :: hasAGMG     = .FALSE.
    LOGICAL :: hasSparsePak = .TRUE.
  END TYPE NM_Brg_ExtLibFlags_Desc
  ! legacy alias
  TYPE, PUBLIC :: NM_ExtLibFlags
    LOGICAL :: hasMUMPS    = .FALSE.
    LOGICAL :: hasLAPACK   = .TRUE.
    LOGICAL :: hasCuSPARSE = .FALSE.
    LOGICAL :: hasAGMG     = .FALSE.
    LOGICAL :: hasSparsePak = .TRUE.
  END TYPE NM_ExtLibFlags

  !--------------------------------------------------------------------
  ! NM_Bridge_Domain — Domain container (State-like)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Bridge_Domain
    TYPE(NM_Brg_ExtLibFlags_Desc) :: extLibs
    LOGICAL              :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init              => NM_Brg_Init
    PROCEDURE :: Finalize          => NM_Brg_Finalize
    PROCEDURE :: CheckLibrary      => NM_Bridge_Domain_CheckLibrary
    PROCEDURE :: GetLibraryStatus  => NM_Brg_GetLibStatus
    PROCEDURE :: GetSummary        => NM_Brg_GetSummary
  END TYPE NM_Bridge_Domain

CONTAINS

  SUBROUTINE NM_Brg_Finalize(this)
    !> [INOUT] this - Domain instance to finalize
    CLASS(NM_Bridge_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%extLibs = NM_Brg_ExtLibFlags_Desc()
    this%initialized = .FALSE.
  END SUBROUTINE NM_Brg_Finalize

  SUBROUTINE NM_Brg_Init(this, status)
    !> [INOUT] this   - Domain instance to initialize
    !> [OUT]   status - Error status
    CLASS(NM_Bridge_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    ! TODO: detect external library availability via #ifdef / probe
    this%initialized  = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Brg_Init

  !====================================================================
  ! NM_Bridge_Domain_CheckLibrary
  ! Check if external library is available
  !====================================================================
  SUBROUTINE NM_Bridge_Domain_CheckLibrary(this, libName, isAvailable, status)
    !> [IN]    this        - Domain instance
    !> [IN]    libName     - Library name to check
    !> [OUT]   isAvailable - Whether library is available
    !> [OUT]   status     - Error status
    CLASS(NM_Bridge_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),        INTENT(IN)    :: libName
    LOGICAL,                 INTENT(OUT)   :: isAvailable
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    isAvailable = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Bridge domain not initialized"
      RETURN
    END IF

    SELECT CASE(TRIM(libName))
    CASE("MUMPS")
      isAvailable = this%extLibs%hasMUMPS
    CASE("LAPACK")
      isAvailable = this%extLibs%hasLAPACK
    CASE("cuSPARSE")
      isAvailable = this%extLibs%hasCuSPARSE
    CASE("AGMG")
      isAvailable = this%extLibs%hasAGMG
    CASE("SparsePak")
      isAvailable = this%extLibs%hasSparsePak
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "Unknown library name: " // TRIM(libName)
      RETURN
    END SELECT

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_Bridge_Domain_CheckLibrary

  !====================================================================
  ! NM_Brg_GetLibStatus
  ! Get library availability status
  !====================================================================
  SUBROUTINE NM_Brg_GetLibStatus(this, libName, status)
    CLASS(NM_Bridge_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),        INTENT(IN)  :: libName
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    LOGICAL :: isAvailable

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Bridge domain not initialized"
      RETURN
    END IF

    CALL this%CheckLibrary(libName, isAvailable, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (isAvailable) THEN
      status%status_code = IF_STATUS_OK
      status%message = "Library " // TRIM(libName) // " is available"
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "Library " // TRIM(libName) // " is NOT available"
    END IF

  END SUBROUTINE NM_Brg_GetLibStatus

  !====================================================================
  ! NM_Brg_GetSummary
  ! Get summary string of bridge domain
  !====================================================================
  SUBROUTINE NM_Brg_GetSummary(this, summary, status)
    CLASS(NM_Bridge_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Bridge domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,L1,A,L1,A,L1,A,L1,A,L1,A,L1)') &
      "Bridge Summary: MUMPS=", this%extLibs%hasMUMPS, &
      ", LAPACK=", this%extLibs%hasLAPACK, &
      ", cuSPARSE=", this%extLibs%hasCuSPARSE, &
      ", AGMG=", this%extLibs%hasAGMG, &
      ", SparsePak=", this%extLibs%hasSparsePak, &
      ", Initialized=", this%initialized

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_Brg_GetSummary

END MODULE NM_Brg_Mgr