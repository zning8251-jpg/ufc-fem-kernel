!===============================================================================
! Module: PH_Mat_Types                                           [Template v3.2]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Material — Ctx and Algo types for per-increment material computation
!
! Purpose:
!   Defines the Ctx / Algo two-type system for the PH_ (physical) layer.
!
!   v3.2 additions:
!   - Added: PH_Mat_VUMAT_Ctx     (VUMAT: Explicit block Ctx with NBLOCK)
!   - Added: PH_Mat_CREEP_State   (CREEP: creep strain state)
!   - Added: PH_Mat_UEXPAN_State  (UEXPAN: thermal strain state)
!   - Added: PH_Mat_UHARD_State   (UHARD: hardening law output)
!
!   NOTE (v3.1 design asymmetric matrix):
!     PH_ layer carries Ctx and Algo, but NOT Desc or State.
!     Desc lives in MD_Mat_Types (model description, permanent).
!     State lives in MD_Mat_Types (owned by MD_, updated in PH_).
!
! Type roles:
!   PH_Mat_Base_Ctx  – Per-increment driving inputs (激励): strain increment,
!                      temperature, deformation gradient at end of increment,
!                      spatial coordinates, etc.
!                      Populated by the UMAT bridge at each call.
!
!   PH_Mat_Base_Algo – Per-increment iteration control: Newton-Raphson limits,
!                      convergence tolerance, time-step control.
!                      Principle ⑬: iteration-control fields MUST be here,
!                      NOT in MD_Mat_Base_Algo.
!
! Field assignment rationale (UMAT parameter map):
!   DSTRAN  → dstran(ntens)    increment driving strain   Ctx
!   DFGRD1  → dfgrd1(3,3)      F at end of increment      Ctx
!   DROT    → drot(3,3)        rotation increment         Ctx
!   TEMP    → temp             temperature at end         Ctx
!   DTEMP   → dtemp            temperature increment      Ctx
!   PREDEF  → predef(:)        predefined field values    Ctx
!   DPRED   → dpred(:)         predefined field increments Ctx
!   COORDS  → coords(3)        integration point coords   Ctx
!   CELENT  → celent           characteristic element len Ctx
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!===============================================================================
MODULE PH_Mat_Types
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Base_Ctx
  PUBLIC :: PH_Mat_Base_Algo
  PUBLIC :: PH_Mat_VUMAT_Ctx
  PUBLIC :: PH_Mat_CREEP_State
  PUBLIC :: PH_Mat_UEXPAN_State
  PUBLIC :: PH_Mat_UHARD_State
  PUBLIC :: PH_Mat_UMAT_State
  PUBLIC :: PH_Mat_VUMAT_State
  PUBLIC :: PH_Mat_UHARD_Ctx
  PUBLIC :: PH_Mat_UEXPAN_Ctx
  PUBLIC :: PH_Mat_CREEP_Ctx

  !-----------------------------------------------------------------------------
  ! ① CTX — Material Computation Context (per-increment driving inputs)
  !    These are all "THIS increment's driving inputs" that arrive at the
  !    UMAT interface and are passed down to the physics computation.
  !
  !    Contrast with MD_Mat_Base_State which holds "known past" at START.
  !      dstran / dfgrd1   → "where we are going" this increment    (Ctx)
  !      stran  / dfgrd0   → "where we came from" (history at start) (State)
  !
  !    npredf controls the length of predef / dpred; allocated dynamically.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_Base_Ctx
    !-- Strain / kinematic driving input
    REAL(wp) :: dstran(6)    = 0.0_wp  ! I  DSTRAN  strain increment  Δε
    REAL(wp) :: drot(3,3)    = 0.0_wp  ! I  DROT    rotation increment ΔR
    REAL(wp) :: dfgrd1(3,3)  = 0.0_wp  ! I  DFGRD1  deformation gradient F₁ at end
    !-- Thermal / field driving input
    REAL(wp) :: temp         = 0.0_wp  ! I  TEMP    temperature at end of increment
    REAL(wp) :: dtemp        = 0.0_wp  ! I  DTEMP   temperature increment ΔT
    !-- Predefined field variables (ALLOCATABLE; length = npredf from RT)
    REAL(wp), POINTER :: predef(:) ! I  PREDEF  predefined field at end
    REAL(wp), POINTER :: dpred(:)  ! I  DPRED   predefined field increment
    !-- Spatial context
    REAL(wp) :: coords(3)    = 0.0_wp  ! I  COORDS  integration point coordinates
    REAL(wp) :: celent       = 0.0_wp  ! I  CELENT  characteristic element length
  END TYPE PH_Mat_Base_Ctx

  !-----------------------------------------------------------------------------
  ! ② ALGO — Per-Increment Algorithm Control
  !    Principle ⑬ ALGO SPLIT MD vs PH:
  !      MD_Mat_Base_Algo = pre-analysis "how to solve" configuration
  !      PH_Mat_Base_Algo = per-increment "how hard to try" iteration control
  !
  !    pnewdt_min / pnewdt_max define the allowable range for time-step
  !    suggestion signals.  The actual pnewdt output is a bare REAL(wp)
  !    INTENT(INOUT) parameter (v4.0); initialise with RT_PNEWDT_NO_CHANGE.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_Base_Algo
    !-- Newton-Raphson iteration control
    INTEGER(i4) :: max_iter   = 100           ! Maximum Newton iterations
    REAL(wp)    :: tolerance  = 1.0e-8_wp     ! Relative convergence tolerance
    REAL(wp)    :: abs_tol    = 1.0e-12_wp    ! Absolute tolerance floor
    !-- Time-step feedback control (bounds on pnewdt signal sent to RT_Algo)
    REAL(wp) :: pnewdt_min   = 0.1_wp        ! Minimum acceptable pnewdt
    REAL(wp) :: pnewdt_max   = 1.5_wp        ! Maximum allowed pnewdt growth
    LOGICAL  :: auto_cut     = .TRUE.        ! Auto cut step on non-convergence
    !-- Optional: line-search
    LOGICAL  :: line_search  = .FALSE.       ! Enable line search in Newton loop
  END TYPE PH_Mat_Base_Algo

  !-----------------------------------------------------------------------------
  ! PH_Mat_VUMAT_Ctx — Vectorized (Explicit) material context
  !   VUMAT operates on a BLOCK of material points simultaneously.
  !   nblock = number of material points in this call.
  !   Abaqus/Explicit: VUMAT(NBLOCK, NDIR, NSHR, NSTATEV, NFIELDV, NPROPS, ...)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_VUMAT_Ctx
    INTEGER(i4) :: nblock = 1_i4    ! NBLOCK: material points in this call
    REAL(wp), POINTER :: dstran_blk(:,:)   ! [nblock, ntens] strain increment
    REAL(wp), POINTER :: dfgrd1_blk(:,:,:) ! [nblock, 3, 3] deformation gradient
    REAL(wp), POINTER :: drot_blk(:,:,:)   ! [nblock, 3, 3] rotation increment
    REAL(wp), POINTER :: temp_blk(:)       ! [nblock] temperature at end
    REAL(wp), POINTER :: dtemp_blk(:)      ! [nblock] temperature increment
    REAL(wp), POINTER :: predef_blk(:,:,:) ! [nblock, npredf, 2]
    REAL(wp), POINTER :: coords_blk(:,:)   ! [nblock, 3] coords
    REAL(wp), POINTER :: celent_blk(:)     ! [nblock] char. lengths
    REAL(wp) :: char_length = 0.0_wp
  END TYPE PH_Mat_VUMAT_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Mat_CREEP_State — Creep strain state (CREEP subroutine output)
  !   DECRA(5): creep strain rate increments (Abaqus CREEP interface)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_CREEP_State
    REAL(wp) :: decra(5)        = 0.0_wp  ! DECRA: creep strain rate increments
    REAL(wp) :: deswa(5)        = 0.0_wp  ! DESWA: swelling strain rate increments
    REAL(wp) :: creep_strain(6) = 0.0_wp  ! Accumulated creep strain [Voigt]
    REAL(wp) :: creep_rate      = 0.0_wp  ! Equivalent creep strain rate [1/s]
    REAL(wp) :: peeq_cr         = 0.0_wp  ! Accumulated equiv. creep strain
    LOGICAL  :: converged       = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_CREEP_State

  !-----------------------------------------------------------------------------
  ! PH_Mat_UEXPAN_State — Thermal expansion strain state (UEXPAN output)
  !   UEXPAN returns: EXPAN(NTENS) = expansion strain increments
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UEXPAN_State
    REAL(wp) :: expan(6) = 0.0_wp   ! EXPAN: expansion strain increments [Voigt]
    REAL(wp) :: dexpan(6)= 0.0_wp   ! d(EXPAN)/dT [optional, for Jacobian]
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UEXPAN_State

  !-----------------------------------------------------------------------------
  ! PH_Mat_UHARD_State — Hardening law output (UHARD subroutine)
  !   HARD(1)=dσ_y/dē_p  HARD(2)=dσ_y/dē_dot  HARD(3)=dσ_y/dT
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UHARD_State
    REAL(wp) :: syield     = 0.0_wp  ! SYIELD: current yield stress [Pa]
    REAL(wp) :: hard(3)    = 0.0_wp  ! HARD: [dσ_y/dē_p, dσ_y/dē_dot, dσ_y/dT]
    REAL(wp) :: peeq       = 0.0_wp  ! Equiv. plastic strain (EQPLAS input)
    REAL(wp) :: eqplasrt   = 0.0_wp  ! Equiv. plastic strain rate (EQPLASRT)
    LOGICAL  :: converged  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UHARD_State

  !-----------------------------------------------------------------------------
  ! PH_Mat_UMAT_State — Full UMAT output state (Implicit material integration)
  !   Carries all outputs written back to Abaqus/Standard by the UMAT:
  !   STRESS, DDSDDE, STATEV, SSE, SPD, SCD, RPL, DDSDDT, DRPLDE, DRPLDT.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UMAT_State
    REAL(wp) :: stress(6)      = 0.0_wp  !  O STRESS   updated Cauchy stress [Pa]
    REAL(wp) :: ddsdde(6,6)    = 0.0_wp  !  O DDSDDE   consistent tangent modulus
    REAL(wp), ALLOCATABLE :: statev(:)   ! IO STATEV   solution-dep. state variables
    REAL(wp) :: sse            = 0.0_wp  ! IO SSE      elastic strain energy density
    REAL(wp) :: spd            = 0.0_wp  ! IO SPD      plastic dissipation density
    REAL(wp) :: scd            = 0.0_wp  ! IO SCD      creep dissipation density
    REAL(wp) :: rpl            = 0.0_wp  !  O RPL      volumetric heat generation rate
    REAL(wp) :: ddsddt(6)      = 0.0_wp  !  O DDSDDT   d(stress)/dT
    REAL(wp) :: drplde(6)      = 0.0_wp  !  O DRPLDE   d(RPL)/d(strain)
    REAL(wp) :: drpldt         = 0.0_wp  !  O DRPLDT   d(RPL)/dT
    LOGICAL  :: converged      = .FALSE.
    INTEGER(i4) :: iterations  = 0
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UMAT_State

  !-----------------------------------------------------------------------------
  ! PH_Mat_VUMAT_State — VUMAT block output state (Explicit block integration)
  !   Carries the per-block stress/statev outputs written by VUMAT.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_VUMAT_State
    REAL(wp), ALLOCATABLE :: stress_blk(:,:)  ! [nblock, ntens] updated stress
    REAL(wp), ALLOCATABLE :: statev_blk(:,:)  ! [nblock, nstatv] state variables
    REAL(wp), ALLOCATABLE :: sse_blk(:)       ! [nblock] elastic energy
    REAL(wp), ALLOCATABLE :: spd_blk(:)       ! [nblock] plastic dissipation
    REAL(wp), ALLOCATABLE :: scd_blk(:)       ! [nblock] creep dissipation
    INTEGER(i4) :: nblock = 0
    LOGICAL :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUMAT_State

  !-----------------------------------------------------------------------------
  ! PH_Mat_UHARD_Ctx — UHARD subroutine per-call driving inputs
  !   UHARD(SYIELD, HARD, EQPLAS, EQPLASRT, TIME, DTIME, TEMP, DTEMP, ...)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UHARD_Ctx
    REAL(wp) :: eqplas   = 0.0_wp   ! I EQPLAS  equiv. plastic strain at start
    REAL(wp) :: eqplasrt = 0.0_wp   ! I EQPLASRT equiv. plastic strain rate
    REAL(wp) :: temp     = 0.0_wp   ! I TEMP     temperature
    REAL(wp) :: dtemp    = 0.0_wp   ! I DTEMP    temperature increment
    INTEGER(i4) :: nvalue = 0_i4    ! I NVALUE   no. of table entries
  END TYPE PH_Mat_UHARD_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Mat_UEXPAN_Ctx — UEXPAN subroutine per-call driving inputs
  !   UEXPAN(EXPAN, DEXPANDT, TEMP, DTEMP, TIME, DTIME, PREDEF, DPRED, ...)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UEXPAN_Ctx
    REAL(wp) :: temp       = 0.0_wp   ! I TEMP  temperature at end of increment
    REAL(wp) :: dtemp      = 0.0_wp   ! I DTEMP temperature increment
    REAL(wp), POINTER :: predef(:) ! I PREDEF predefined field values
    REAL(wp), POINTER :: dpred(:)  ! I DPRED  predefined field increments
    INTEGER(i4) :: nfield = 0_i4
  END TYPE PH_Mat_UEXPAN_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Mat_CREEP_Ctx — CREEP subroutine per-call driving inputs
  !   CREEP(DECRA, DESWA, STATEV, SERD, EC, ESW, P, QTILD, TEMP, DTEMP, ...)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_CREEP_Ctx
    REAL(wp) :: ec(2)   = 0.0_wp  ! I EC(2)   equiv. creep strain at start/end
    REAL(wp) :: esw(2)  = 0.0_wp  ! I ESW(2)  equiv. swelling strain start/end
    REAL(wp) :: p       = 0.0_wp  ! I P       equiv. pressure stress
    REAL(wp) :: qtild   = 0.0_wp  ! I QTILD   equiv. deviatoric stress
    REAL(wp) :: temp    = 0.0_wp  ! I TEMP    temperature at end
    REAL(wp) :: dtemp   = 0.0_wp  ! I DTEMP   temperature increment
    REAL(wp) :: serd    = 0.0_wp  ! I SERD    creep strain energy rate
    REAL(wp), POINTER :: predef(:)
    REAL(wp), POINTER :: dpred(:)
    INTEGER(i4) :: nfield = 0_i4
  END TYPE PH_Mat_CREEP_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Mat_UMAT_Ctx — UMAT subroutine per-call driving inputs
  !   Full set of incremental driving variables passed at each UMAT call
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UMAT_Ctx
    REAL(wp), POINTER :: stran(:)    ! I STRAN  total strain at start
    REAL(wp), POINTER :: dstran(:)   ! I DSTRAN strain increment
    REAL(wp), POINTER :: dfgrd0(:,:) ! I DFGRD0 deformation gradient start
    REAL(wp), POINTER :: dfgrd1(:,:) ! I DFGRD1 deformation gradient end
    REAL(wp), POINTER :: coords(:)   ! I COORDS element centroid coordinates
    REAL(wp), POINTER :: drot(:,:)   ! I DROT   rotation increment matrix
    REAL(wp), POINTER :: predef(:)   ! I PREDEF predefined fields
    REAL(wp), POINTER :: dpred(:)    ! I DPRED  predefined field increments
    REAL(wp) :: temp    = 0.0_wp   ! I TEMP   temperature at end
    REAL(wp) :: dtemp   = 0.0_wp   ! I DTEMP  temperature increment
    REAL(wp) :: time(2) = 0.0_wp   ! I TIME(2) step/total time
    REAL(wp) :: dtime   = 0.0_wp   ! I DTIME  time increment
    INTEGER(i4) :: ndi   = 3_i4    ! I NDI    no. direct stress components
    INTEGER(i4) :: nshr  = 3_i4    ! I NSHR   no. shear stress components
    INTEGER(i4) :: ntens = 6_i4    ! I NTENS  total stress components
    INTEGER(i4) :: noel  = 0_i4    ! I NOEL   element number
    INTEGER(i4) :: npt   = 0_i4    ! I NPT    integration point number
    INTEGER(i4) :: layer = 0_i4    ! I LAYER  layer number (shells)
    INTEGER(i4) :: kspt  = 0_i4    ! I KSPT   section point
    INTEGER(i4) :: kstep = 0_i4    ! I KSTEP  step number
    INTEGER(i4) :: kinc  = 0_i4    ! I KINC   increment number
    INTEGER(i4) :: nfield= 0_i4
    CHARACTER(LEN=8) :: cmname = ' '  ! I CMNAME material name
  END TYPE PH_Mat_UMAT_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Mat_VUMAT_Algo — VUMAT block-vectorised algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_VUMAT_Algo
    INTEGER(i4) :: max_iter    = 50_i4   ! max local iterations per block point
    REAL(wp)    :: tol_stress  = 1.0e-6_wp ! stress residual tolerance
    LOGICAL     :: use_subincr = .FALSE.  ! sub-incrementation flag
    INTEGER(i4) :: n_subincr   = 1_i4    ! number of sub-increments
    REAL(wp)    :: pnewdt_min  = 0.1_wp  ! minimum pnewdt cutback
  END TYPE PH_Mat_VUMAT_Algo

  !-----------------------------------------------------------------------------
  ! PH_Mat_UHARD_Algo — UHARD hardening law algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UHARD_Algo
    REAL(wp)    :: eqplas_tol  = 1.0e-10_wp ! equivalent plastic strain floor
    INTEGER(i4) :: table_extrap = 0_i4      ! 0=hold, 1=linear extrapolation
    LOGICAL     :: rate_dependent = .FALSE.  ! rate-dependent flag
  END TYPE PH_Mat_UHARD_Algo

  !-----------------------------------------------------------------------------
  ! PH_Mat_UEXPAN_Algo — UEXPAN thermal expansion algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UEXPAN_Algo
    LOGICAL     :: isotropic    = .TRUE.  ! isotropic expansion
    INTEGER(i4) :: ncomp        = 6_i4   ! no. expansion strain components
    REAL(wp)    :: ref_t     = 0.0_wp ! reference temperature for zero strain
  END TYPE PH_Mat_UEXPAN_Algo

  !-----------------------------------------------------------------------------
  ! PH_Mat_CREEP_Algo — CREEP power-law/user creep algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_CREEP_Algo
    INTEGER(i4) :: max_iter     = 10_i4    ! maximum creep sub-increments
    REAL(wp)    :: tol_creep    = 1.0e-8_wp ! creep strain increment tolerance
    REAL(wp)    :: creep_cut    = 0.5_wp   ! cutback factor on creep divergence
    LOGICAL     :: swelling     = .FALSE.   ! include swelling
  END TYPE PH_Mat_CREEP_Algo

  !-----------------------------------------------------------------------------
  ! PH_Mat_UHYPER_Ctx — UHYPER strain-energy per-call driving inputs
  !   UHYPER(BI, USC, U, DU, D2U, TEMP, NOEL, CMNAME, INCMPFLAG)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UHYPER_Ctx
    REAL(wp) :: bi(3)   = 0.0_wp  ! I BI(3)   strain invariants I1,I2,J
    REAL(wp) :: usc     = 0.0_wp  ! I USC     compressibility parameter
    REAL(wp) :: temp    = 0.0_wp  ! I TEMP    temperature
    INTEGER(i4) :: noel = 0_i4
    CHARACTER(LEN=8) :: cmname = ' '
    LOGICAL :: incmp = .FALSE.     ! incompressibility flag
  END TYPE PH_Mat_UHYPER_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Mat_UHYPER_State — UHYPER output strain-energy and derivatives
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UHYPER_State
    REAL(wp) :: u(2)    = 0.0_wp  ! O U(2)   strain-energy, volumetric part
    REAL(wp) :: du(3)   = 0.0_wp  ! O DU(3)  dU/dI1, dU/dI2, dU/dJ
    REAL(wp) :: d2u(6)  = 0.0_wp  ! O D2U(6) second derivatives
    LOGICAL  :: is_valid= .FALSE.
  END TYPE PH_Mat_UHYPER_State

  !-----------------------------------------------------------------------------
  ! PH_Mat_UHYPER_Algo — UHYPER hyperelastic algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UHYPER_Algo
    LOGICAL     :: compressible = .FALSE.  ! compressible formulation
    REAL(wp)    :: j_floor      = 1.0e-12_wp ! Jacobian lower bound
    INTEGER(i4) :: deriv_order  = 2_i4       ! 1=first only, 2=full
  END TYPE PH_Mat_UHYPER_Algo

  !-----------------------------------------------------------------------------
  ! PH_Mat_UMULLINS_Ctx — UMULLINS Mullins-effect per-call driving inputs
  !   UMULLINS(STRESSNEW, STATEV, STRAINENERGY, DESTENERGY, DETIME, ...)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UMULLINS_Ctx
    REAL(wp) :: strain_energy = 0.0_wp  ! I strain energy in primary network
    REAL(wp) :: dest_energy   = 0.0_wp  ! I undamaged strain energy
    REAL(wp) :: detime        = 0.0_wp  ! I pseudo-time increment
    REAL(wp) :: temp          = 0.0_wp  ! I TEMP
    INTEGER(i4) :: noel       = 0_i4
  END TYPE PH_Mat_UMULLINS_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Mat_UMULLINS_State — UMULLINS damage output
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UMULLINS_State
    REAL(wp) :: damage_var = 0.0_wp  ! O damage variable eta
    REAL(wp) :: ddamage    = 0.0_wp  ! O d(damage)/d(strain_energy)
    REAL(wp), ALLOCATABLE :: statev(:)
    INTEGER(i4) :: nstatv  = 0_i4
    LOGICAL  :: is_valid   = .FALSE.
  END TYPE PH_Mat_UMULLINS_State

  !-----------------------------------------------------------------------------
  ! PH_Mat_UMULLINS_Algo — UMULLINS Mullins damage algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_UMULLINS_Algo
    REAL(wp) :: tol_damage   = 1.0e-8_wp ! damage increment tolerance
    LOGICAL  :: progressive  = .TRUE.    ! progressive damage evolution
    INTEGER(i4) :: n_subincr = 1_i4      ! sub-increments for damage
  END TYPE PH_Mat_UMULLINS_Algo

  ! ------------------------------------------------------------------ !
  ! PH_Mat_UANISOHYPER_INV_Ctx
  !   Driving inputs for UANISOHYPER with invariant-based formulation.
  !   Passes strain invariants I1–I3 plus anisotropic invariants I4–I6.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_UANISOHYPER_INV_Ctx
    REAL(wp) :: i1    = 0.0_wp  ! I INVARIANTS(1) = I1 = tr(C)
    REAL(wp) :: i2    = 0.0_wp  ! I INVARIANTS(2) = I2 = 0.5*(tr(C)²-tr(C²))
    REAL(wp) :: i3    = 0.0_wp  ! I INVARIANTS(3) = I3 = det(C)
    REAL(wp) :: i4    = 0.0_wp  ! I INVARIANTS(4) = a0·C·a0 (fibre 1)
    REAL(wp) :: i5    = 0.0_wp  ! I INVARIANTS(5) = a0·C²·a0
    REAL(wp) :: i6    = 0.0_wp  ! I INVARIANTS(6) = b0·C·b0 (fibre 2)
    REAL(wp) :: temp  = 0.0_wp  ! I temperature
    INTEGER(i4) :: nfibers = 1_i4  ! number of fibre families
    LOGICAL  :: incmp = .FALSE.    ! incompressibility flag
  END TYPE PH_Mat_UANISOHYPER_INV_Ctx

  ! ------------------------------------------------------------------ !
  ! PH_Mat_UANISOHYPER_INV_State
  !   Output arrays for invariant-based anisotropic hyperelastic model.
  !   UANISOHYPER writes dU/dI_k and d²U/dI_k dI_l.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_UANISOHYPER_INV_State
    REAL(wp) :: u(2)     = 0.0_wp  ! O U(2)    strain energy (elastic/inelastic)
    REAL(wp) :: ui1(6)   = 0.0_wp  ! O UI1(6)  first derivatives dU/dI_k
    REAL(wp) :: ui2(21)  = 0.0_wp  ! O UI2(21) second derivatives (upper triangle)
    LOGICAL  :: is_updated = .FALSE.
  END TYPE PH_Mat_UANISOHYPER_INV_State

  ! ------------------------------------------------------------------ !
  ! PH_Mat_UANISOHYPER_INV_Algo
  !   Algorithmic parameters for anisotropic hyperelastic iteration.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_UANISOHYPER_INV_Algo
    LOGICAL     :: compressible    = .FALSE.  ! allow volumetric compressibility
    INTEGER(i4) :: n_fibers        = 1_i4    ! active fibre family count
    REAL(wp)    :: i3_floor        = 1.0e-12_wp  ! floor for I3 (near-incompress)
    INTEGER(i4) :: deriv_order     = 2_i4    ! 1=first only, 2=first+second
    LOGICAL     :: use_num_tangent = .FALSE. ! finite-difference numerical tangent
    REAL(wp)    :: fd_pert         = 1.0e-7_wp   ! FD perturbation size
  END TYPE PH_Mat_UANISOHYPER_INV_Algo

  ! ------------------------------------------------------------------ !
  ! PH_Mat_UMULLINS_VUMAT_Ctx
  !   Vectorised driving context for VUMAT-style Mullins effect calls.
  !   Passes block of nblock integration points simultaneously.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_UMULLINS_VUMAT_Ctx
    INTEGER(i4)           :: nblock        = 0_i4    ! number of material points
    REAL(wp), POINTER :: stretch(:,:)             ! [nblock,6] stretch tensor
    REAL(wp), POINTER :: dstretch(:,:)            ! [nblock,6] stretch increment
    REAL(wp), POINTER :: temp(:)                  ! [nblock] temperature
    REAL(wp), POINTER :: dtemp(:)                 ! [nblock] temp increment
    REAL(wp)              :: dtime   = 0.0_wp
    INTEGER(i4)           :: nstatev = 0_i4
    LOGICAL               :: is_explicit = .FALSE.    ! .T. → explicit step
  END TYPE PH_Mat_UMULLINS_VUMAT_Ctx

  ! ------------------------------------------------------------------ !
  ! PH_Mat_USDFLD_Ctx
  !   Driving context for USDFLD (solution-dependent field variable)
  !   within the material domain.  Supplements the field-domain Ctx
  !   with material-specific information.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_USDFLD_Ctx
    INTEGER(i4)           :: nfield     = 0_i4    ! number of field variables
    REAL(wp), POINTER :: field(:)             ! [nfield] field variable values
    REAL(wp), POINTER :: dfield(:)            ! [nfield] field increments
    INTEGER(i4)           :: nprops     = 0_i4
    REAL(wp), POINTER :: props(:)             ! [nprops] material constants
    REAL(wp)              :: temp       = 0.0_wp
    REAL(wp)              :: dtime      = 0.0_wp
    CHARACTER(LEN=8)      :: cmname     = ' '
  END TYPE PH_Mat_USDFLD_Ctx

  ! ----------------------------------------------------------------
  !> @type PH_Mat_VUSDFLD_Mat_Ctx
  !> @brief VUSDFLD向量化版材料場更新局部驱动输入（Ctx类）
  !>
  !> 与PH_Mat_USDFLD_Ctx类似但面向多个材料点向量化批处理，
  !> 所有数组字段尪寸为(nblock)，由调用方管理生命周期。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: PH_Mat_VUSDFLD_Mat_Ctx
    INTEGER(i4)           :: nblock      = 0_i4    ! 向量化批大小
    INTEGER(i4)           :: nstatv      = 0_i4    ! 状态变量数
    INTEGER(i4)           :: nfieldv     = 0_i4    ! 预定义场变量数
    INTEGER(i4)           :: nprops      = 0_i4    ! 材料参数数
    REAL(wp), POINTER     :: field(:,:)  => NULL() ! 场变量值 shape(nblock,nfieldv)
    REAL(wp), POINTER     :: field_prev(:,:) => NULL() ! 上增量场变量
    REAL(wp), POINTER     :: stateNew(:,:) => NULL()  ! 新状态变量 shape(nblock,nstatv)
    REAL(wp), POINTER     :: stateOld(:,:) => NULL()  ! 旧状态变量
    REAL(wp), POINTER     :: stress(:,:) => NULL()    ! 应力 shape(nblock,ndir+nshr)
    REAL(wp), POINTER     :: props(:)    => NULL()    ! 材料参数 shape(nprops)
    REAL(wp), POINTER     :: time(:,:)   => NULL()    ! 时间 shape(nblock,2)
    REAL(wp), POINTER     :: dtime_v(:)  => NULL()    ! 时间增量 shape(nblock)
    CHARACTER(LEN=8)      :: cmname      = ' '        ! 材料名称
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUSDFLD_Mat_Ctx

  ! ================================================================== !
  ! Z3 ADDITIONS — Subroutines: UMATHT / VUHARD / VUANISOHYPER_INV   !
  !                              VUANISOHYPER_STRAIN / UCREEPNETWORK  !
  !                              VUMULLINS                            !
  ! Each subroutine gets Ctx + State + Algo (Desc lives in MD_Mat_)  !
  ! ================================================================== !

  ! ------------------------------------------------------------------ !
  ! UMATHT — Coupled temperature-displacement material (热传导材料)   !
  !   Standard solver calls this when COUPLED=YES in *MATERIAL.       !
  !   Outputs: flux(ntens), dfdt(ntens), dfdg(ntens,ntens), RPL, DRPLDE, DRPLDT !
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_UMATHT_Ctx
    !-- Thermal driving input
    REAL(wp) :: temp         = 0.0_wp   ! I  TEMP    temperature at end of increment
    REAL(wp) :: dtemp        = 0.0_wp   ! I  DTEMP   temperature increment
    REAL(wp) :: dtemdx(3)   = 0.0_wp   ! I  DTEMDX(NTGRD) temperature gradient at end
    REAL(wp) :: time(2)      = 0.0_wp   ! I  TIME(1)=step, TIME(2)=total
    REAL(wp) :: dtime        = 0.0_wp   ! I  DTIME   time increment
    REAL(wp) :: coords(3)    = 0.0_wp   ! I  COORDS  integration point coords
    REAL(wp) :: celent       = 0.0_wp   ! I  CELENT  characteristic element length
    !-- Predefined field variables
    INTEGER(i4) :: npredf    = 0_i4     ! number of predefined field variables
    REAL(wp), POINTER :: predef(:)  ! [npredf] predefined field values
    REAL(wp), POINTER :: dpred(:)   ! [npredf] predefined field increments
    !-- Material identity
    CHARACTER(LEN=8) :: cmname = ' '    ! material name
    INTEGER(i4) :: nstatv     = 0_i4    ! number of SDVs
    INTEGER(i4) :: nprops     = 0_i4
    REAL(wp), POINTER :: props(:)   ! [nprops] material constants
    !-- Context linkage (three-tier)
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UMATHT_Ctx

  TYPE, PUBLIC :: PH_Mat_UMATHT_State
    !-- State variables (SDV) at start / end of increment
    REAL(wp), ALLOCATABLE :: statev(:)      ! [nstatv] SDVs at start
    REAL(wp), ALLOCATABLE :: statev_curr(:)  ! [nstatv] SDVs at end (updated)
    !-- Stored energy and internal heat generation (output from UMATHT)
    REAL(wp) :: dudt        = 0.0_wp   ! O  DUDT    time rate of change of internal energy
    REAL(wp) :: rpl         = 0.0_wp   ! IO RPL     volumetric heat generation rate
    REAL(wp) :: drpldt      = 0.0_wp   ! O  DRPLDT  dRPL/dT
    REAL(wp) :: drplde(6)   = 0.0_wp   ! O  DRPLDE(NTENS)  dRPL/dε
    !-- Heat flux and conductance (output from UMATHT)
    REAL(wp) :: flux(3)     = 0.0_wp   ! O  FLUX(NTGRD)   heat flux vector
    REAL(wp) :: dfdt(3)     = 0.0_wp   ! O  DFDT(NTGRD)   dflux/dT
    REAL(wp) :: dfdg(3,3)   = 0.0_wp   ! O  DFDG(NTGRD,NTGRD) dflux/d(grad T)
    LOGICAL  :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UMATHT_State

  TYPE, PUBLIC :: PH_Mat_UMATHT_Algo
    LOGICAL     :: use_symmetric_conductance = .FALSE. ! force symmetry on DFDG
    REAL(wp)    :: flux_tol         = 1.0e-10_wp  ! flux convergence tolerance
    INTEGER(i4) :: max_iter         = 20_i4        ! max NR iterations
    LOGICAL     :: use_full_coupled = .TRUE.       ! full coupled thermo-mech
    REAL(wp)    :: temp_floor       = -273.15_wp   ! absolute zero guard
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UMATHT_Algo

  ! ------------------------------------------------------------------ !
  ! VUHARD — Explicit (VUMAT-side) isotropic/kinematic hardening law   !
  !   Vectorised: nblock material points processed simultaneously.     !
  !   Outputs: yield stress (syield) + hardening modulus (hard)        !
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_VUHARD_Ctx
    INTEGER(i4)           :: nblock      = 0_i4   ! number of material points
    REAL(wp), POINTER :: eqplas(:)             ! [nblock] equivalent plastic strain
    REAL(wp), POINTER :: eqplasrt(:)           ! [nblock] plastic strain rate
    REAL(wp), POINTER :: temp(:)               ! [nblock] temperature
    REAL(wp), POINTER :: dtemp(:)              ! [nblock] temperature increment
    REAL(wp)              :: dtime     = 0.0_wp    ! time increment (shared)
    INTEGER(i4)           :: nprops    = 0_i4
    REAL(wp), POINTER :: props(:)              ! [nprops] material constants
    CHARACTER(LEN=8)      :: cmname    = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUHARD_Ctx

  TYPE, PUBLIC :: PH_Mat_VUHARD_State
    REAL(wp), ALLOCATABLE :: syield(:)   ! [nblock] O  yield stress at current eqplas
    REAL(wp), ALLOCATABLE :: hard(:)     ! [nblock] O  d(syield)/d(eqplas) hardening slope
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUHARD_State

  TYPE, PUBLIC :: PH_Mat_VUHARD_Algo
    LOGICAL     :: rate_dependent    = .FALSE.   ! include strain-rate effects
    LOGICAL     :: temperature_dep   = .FALSE.   ! include temperature dependence
    REAL(wp)    :: syield_floor      = 0.0_wp    ! minimum yield stress guard
    REAL(wp)    :: eqplas_rate_ref   = 1.0_wp    ! reference strain rate (rate law)
    INTEGER(i4) :: hard_model        = 0_i4      ! 0=isotropic, 1=kinematic, 2=combined
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUHARD_Algo

  ! ------------------------------------------------------------------ !
  ! VUANISOHYPER_INV — Explicit anisotropic hyperelastic (invariant)   !
  !   Vectorised version of UANISOHYPER_INV for Abaqus/Explicit.       !
  !   Outputs: U(2), UI1(NTERM), UI2(NTERM*(NTERM+1)/2)                !
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_VUANISOHYPER_INV_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! number of material points
    INTEGER(i4)           :: nterm      = 6_i4   ! number of strain invariants
    REAL(wp), POINTER :: invariants(:,:)      ! [nblock, nterm] strain invariants I1..I6
    REAL(wp), POINTER :: temp(:)              ! [nblock] temperature
    INTEGER(i4)           :: nstatv     = 0_i4
    REAL(wp), POINTER :: statev(:,:)          ! [nblock, nstatv] SDVs
    INTEGER(i4)           :: nprops     = 0_i4
    REAL(wp), POINTER :: props(:)             ! [nprops]
    CHARACTER(LEN=8)      :: cmname     = ' '
    LOGICAL               :: incmp      = .FALSE. ! incompressibility flag
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUANISOHYPER_INV_Ctx

  TYPE, PUBLIC :: PH_Mat_VUANISOHYPER_INV_State
    REAL(wp), ALLOCATABLE :: u(:,:)    ! [nblock, 2]      O  strain energy density
    REAL(wp), ALLOCATABLE :: ui1(:,:)  ! [nblock, nterm]  O  first derivatives dU/dI_k
    REAL(wp), ALLOCATABLE :: ui2(:,:)  ! [nblock, nterm*(nterm+1)/2] second derivatives
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUANISOHYPER_INV_State

  TYPE, PUBLIC :: PH_Mat_VUANISOHYPER_INV_Algo
    LOGICAL     :: compressible      = .FALSE.   ! allow volumetric compressibility
    INTEGER(i4) :: n_fibers          = 1_i4      ! active fibre families
    REAL(wp)    :: i3_floor          = 1.0e-12_wp! det(C) floor
    INTEGER(i4) :: deriv_order       = 2_i4      ! 1=first only, 2=both
    LOGICAL     :: use_num_tangent   = .FALSE.   ! finite-diff numerical tangent
    REAL(wp)    :: fd_pert           = 1.0e-7_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUANISOHYPER_INV_Algo

  ! ------------------------------------------------------------------ !
  ! VUANISOHYPER_STRAIN — Explicit anisotropic hyperelastic             !
  !   (Green strain formulation, vectorised for Explicit solver).      !
  !   Inputs: Green-Lagrange strain E; Outputs: dU/dE, d²U/dE²         !
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_VUANISOHYPER_STRAIN_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! number of material points
    INTEGER(i4)           :: ncomp      = 6_i4   ! strain tensor components (ntens)
    REAL(wp), POINTER :: eelas(:,:)           ! [nblock, ncomp] elastic Green strain E
    REAL(wp), POINTER :: temp(:)              ! [nblock] temperature
    INTEGER(i4)           :: nstatv     = 0_i4
    REAL(wp), POINTER :: statev(:,:)          ! [nblock, nstatv] SDVs
    INTEGER(i4)           :: nprops     = 0_i4
    REAL(wp), POINTER :: props(:)             ! [nprops]
    CHARACTER(LEN=8)      :: cmname     = ' '
    LOGICAL               :: incmp      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUANISOHYPER_STRAIN_Ctx

  TYPE, PUBLIC :: PH_Mat_VUANISOHYPER_STRAIN_State
    REAL(wp), ALLOCATABLE :: u(:,:)    ! [nblock, 2]            O  strain energy
    REAL(wp), ALLOCATABLE :: ui1(:,:)  ! [nblock, ncomp]        O  dU/dE_ij
    REAL(wp), ALLOCATABLE :: ui2(:,:)  ! [nblock, ncomp*(ncomp+1)/2] O  d²U/dE²
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUANISOHYPER_STRAIN_State

  TYPE, PUBLIC :: PH_Mat_VUANISOHYPER_STRAIN_Algo
    LOGICAL     :: compressible      = .FALSE.
    REAL(wp)    :: j_floor           = 1.0e-12_wp ! J = sqrt(det(2E+I)) floor
    INTEGER(i4) :: deriv_order       = 2_i4
    LOGICAL     :: use_num_tangent   = .FALSE.
    REAL(wp)    :: fd_pert           = 1.0e-7_wp
    LOGICAL     :: use_voigt_order   = .TRUE.     ! standard Voigt ordering for E
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUANISOHYPER_STRAIN_Algo

  ! ------------------------------------------------------------------ !
  ! UCREEPNETWORK — Parallel rheological network creep (Standard)      !
  !   Called for each network branch in a parallel spring-dashpot.     !
  !   Outputs: creep strain increment DECRA(5), tangent DESWA(5)       !
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_UCREEPNETWORK_Ctx
    REAL(wp) :: creeq        = 0.0_wp   ! I  CREEQ   equivalent creep strain
    REAL(wp) :: dtime        = 0.0_wp   ! I  DTIME   time increment
    REAL(wp) :: temp         = 0.0_wp   ! I  TEMP    temperature at end of inc
    REAL(wp) :: dtemp        = 0.0_wp   ! I  DTEMP   temperature increment
    REAL(wp) :: predef(1)    = 0.0_wp   ! I  PREDEF  predefined field (first var)
    REAL(wp) :: dpred(1)     = 0.0_wp   ! I  DPRED   predefined field increment
    REAL(wp) :: time(2)      = 0.0_wp   ! I  TIME(2) [step, total]
    REAL(wp) :: coords(3)    = 0.0_wp   ! I  COORDS  integration point coords
    INTEGER(i4) :: nstatv    = 0_i4     ! number of SDVs
    INTEGER(i4) :: nprops    = 0_i4
    REAL(wp), POINTER :: props(:)   ! [nprops] material constants
    INTEGER(i4) :: ndi       = 3_i4     ! number of direct stress components
    INTEGER(i4) :: nshr      = 3_i4     ! number of shear stress components
    CHARACTER(LEN=8) :: cmname = ' '
    !-- Network identification
    INTEGER(i4) :: nnet      = 0_i4     ! network index (1-based)
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UCREEPNETWORK_Ctx

  TYPE, PUBLIC :: PH_Mat_UCREEPNETWORK_State
    REAL(wp), ALLOCATABLE :: statev(:)      ! [nstatv] SDVs at start of increment
    REAL(wp), ALLOCATABLE :: statev_curr(:)  ! [nstatv] SDVs at end (updated)
    !-- Creep strain increment outputs (Abaqus DECRA array, 5 components)
    !   DECRA(1) = Δεcr_eq  DECRA(2..5) = tangent-related
    REAL(wp) :: decra(5)    = 0.0_wp   ! O  DECRA(5)  creep strain increment
    REAL(wp) :: deswa(5)    = 0.0_wp   ! O  DESWA(5)  swelling strain increment
    LOGICAL  :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UCREEPNETWORK_State

  TYPE, PUBLIC :: PH_Mat_UCREEPNETWORK_Algo
    LOGICAL     :: use_swelling       = .FALSE.  ! include swelling strains
    INTEGER(i4) :: integration_scheme = 0_i4     ! 0=explicit, 1=implicit (mid-pt)
    REAL(wp)    :: creep_tol          = 1.0e-6_wp! creep strain convergence tol
    INTEGER(i4) :: max_iter           = 20_i4    ! max sub-iterations
    REAL(wp)    :: creeq_floor        = 0.0_wp   ! guard for near-zero creep
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UCREEPNETWORK_Algo

  ! ------------------------------------------------------------------ !
  ! VUMULLINS — Explicit Mullins effect (vectorised)                   !
  !   Companion to UMULLINS for Abaqus/Explicit.                       !
  !   Passes block of nblock points; updates damage variable η.        !
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Mat_VUMULLINS_Ctx
    INTEGER(i4)           :: nblock      = 0_i4   ! number of material points
    INTEGER(i4)           :: ndir        = 3_i4   ! direct stress/strain components
    INTEGER(i4)           :: nshr        = 3_i4   ! shear stress/strain components
    REAL(wp), POINTER :: stretch(:,:)          ! [nblock, ndir+nshr] stretch tensor
    REAL(wp), POINTER :: dstretch(:,:)         ! [nblock, ndir+nshr] stretch increment
    REAL(wp), POINTER :: temp(:)               ! [nblock] temperature
    REAL(wp), POINTER :: dtemp(:)              ! [nblock] temperature increment
    REAL(wp)              :: dtime      = 0.0_wp   ! shared time increment
    INTEGER(i4)           :: nstatv     = 0_i4
    REAL(wp), POINTER :: statev_prev(:,:)        ! [nblock, nstatv] SDVs at start
    INTEGER(i4)           :: nprops     = 0_i4
    REAL(wp), POINTER :: props(:)               ! [nprops] material constants
    CHARACTER(LEN=8)      :: cmname     = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUMULLINS_Ctx

  TYPE, PUBLIC :: PH_Mat_VUMULLINS_State
    REAL(wp), ALLOCATABLE :: statev_curr(:,:)  ! [nblock, nstatv] O SDVs at end
    REAL(wp), ALLOCATABLE :: eta(:)           ! [nblock] O damage variable η
    REAL(wp), ALLOCATABLE :: svol(:)          ! [nblock] O volumetric strain energy
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUMULLINS_State

  TYPE, PUBLIC :: PH_Mat_VUMULLINS_Algo
    REAL(wp)    :: eta_floor         = 0.0_wp    ! minimum damage variable floor
    REAL(wp)    :: eta_ceil          = 1.0_wp    ! maximum damage (1=fully damaged)
    LOGICAL     :: use_deviatoric    = .TRUE.    ! use deviatoric part of stretch
    REAL(wp)    :: stretch_tol       = 1.0e-10_wp! stretch invariant floor
    INTEGER(i4) :: damage_model      = 0_i4      ! 0=Ogden-Roxburgh, 1=user-defined
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_VUMULLINS_Algo

END MODULE PH_Mat_Types