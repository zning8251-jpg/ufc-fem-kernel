!===============================================================================
! MODULE: PH_UEL_Def
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Def
! BRIEF:  UEL context (ABAQUS-style) and abstract interface types.
!   W1: **PH_UEL_Context** is ABI_Flat workspace; physical parameters must match
!        **slot%desc%props** when wired from Populate.
!   W2: **≠ PH_Elem_Ctx** (four-kind Ctx). PH_UEL_Context aligns with external
!        UEL subroutine signature; use ASSOCIATE to point to PH_Elem_* four-kind.
!   G6: First implementation — U1 (TYPE definition + Init/Cleanup).
!===============================================================================
MODULE PH_UEL_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !--- SECTION 1: TYPE DEFINITIONS ---

  !=============================================================================
  ! TYPE: PH_UEL_Context
  ! KIND: Ctx (per-call UEL workspace; document name: PH_UEL_ABI_Flat)
  ! DESC: ABAQUS-style UEL in/out bundle — all standard UEL fields.
  !       Symmetric with PH_UMAT_Context (Material Contract).
  !=============================================================================
  TYPE, PUBLIC :: PH_UEL_Context
    !--- OUT: Results ---
    REAL(wp), ALLOCATABLE :: rhs(:,:)        ! rhs(ndofel, nrhs)
    REAL(wp), ALLOCATABLE :: amatrx(:,:)     ! amatrx(ndofel, ndofel)
    REAL(wp), ALLOCATABLE :: energy(:)       ! energy(8)

    !--- INOUT: State ---
    REAL(wp), ALLOCATABLE :: svars(:)        ! svars(nsvars)

    !--- IN: DOF / dimension scalars ---
    INTEGER(i4) :: ndofel   = 0_i4
    INTEGER(i4) :: nrhs     = 1_i4
    INTEGER(i4) :: nsvars   = 0_i4
    INTEGER(i4) :: nprops   = 0_i4
    INTEGER(i4) :: njprop   = 0_i4
    INTEGER(i4) :: nnode    = 0_i4
    INTEGER(i4) :: ndload   = 0_i4
    INTEGER(i4) :: mlvarx   = 0_i4
    INTEGER(i4) :: npredef  = 0_i4
    INTEGER(i4) :: nparam   = 0_i4

    !--- IN: Properties ---
    REAL(wp), ALLOCATABLE :: props(:)        ! props(nprops)
    INTEGER(i4), ALLOCATABLE :: jprops(:)    ! jprops(njprop)
    INTEGER(i4) :: jtype     = 0_i4

    !--- IN: Time / step ---
    REAL(wp), ALLOCATABLE :: time(:)         ! time(2)
    REAL(wp) :: dtime     = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc     = 0_i4

    !--- IN: Displacement / velocity / acceleration ---
    REAL(wp), ALLOCATABLE :: u(:)            ! u(ndofel)
    REAL(wp), ALLOCATABLE :: du(:)           ! du(ndofel)
    REAL(wp), ALLOCATABLE :: v(:)            ! v(ndofel)
    REAL(wp), ALLOCATABLE :: a(:)            ! a(ndofel)

    !--- IN: Coordinates ---
    REAL(wp), ALLOCATABLE :: coords(:,:)     ! coords(3, nnode)

    !--- IN: Load flags ---
    INTEGER(i4), ALLOCATABLE :: jdltyp(:)    ! jdltyp(ndload)
    INTEGER(i4), ALLOCATABLE :: lflags(:)    ! lflags(6)

    !--- IN: Predefined fields ---
    REAL(wp), ALLOCATABLE :: preload(:,:)    ! preload(npredef, nnode)

    !--- INOUT: Time increment control ---
    REAL(wp) :: pnewdt    = -1.0_wp

    !--- IN: Element identification ---
    REAL(wp) :: celent    = 0.0_wp
    INTEGER(i4) :: noel    = 0_i4
    INTEGER(i4) :: npt     = 0_i4
    INTEGER(i4) :: layer   = 0_i4
    INTEGER(i4) :: kspt    = 0_i4

    !--- IN: Parameters (extended UEL) ---
    REAL(wp), ALLOCATABLE :: params(:)       ! params(nparam)

  CONTAINS
    PROCEDURE, PUBLIC :: Init
    PROCEDURE, PUBLIC :: Cleanup
  END TYPE PH_UEL_Context

  !=============================================================================
  ! INTERFACE: PH_UEL_Intf
  ! KIND: Abstract
  ! DESC: Unified Compute interface for all UEL-compatible elements.
  !=============================================================================
  PUBLIC :: PH_UEL_Intf
  ABSTRACT INTERFACE
    SUBROUTINE PH_UEL_Intf(ctx, status)
      IMPORT :: PH_UEL_Context, ErrorStatusType
      TYPE(PH_UEL_Context), INTENT(INOUT) :: ctx
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    END SUBROUTINE PH_UEL_Intf
  END INTERFACE

CONTAINS

  SUBROUTINE Init(this, ndofel, nrhs, nsvars, nprops, nnode, njprop)
    CLASS(PH_UEL_Context), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndofel, nrhs, nsvars, nprops, nnode
    INTEGER(i4), INTENT(IN), OPTIONAL :: njprop

    this%ndofel = MAX(1, ndofel)
    this%nrhs   = MAX(1, nrhs)
    this%nsvars = MAX(0, nsvars)
    this%nprops = MAX(1, nprops)
    this%nnode  = MAX(1, nnode)
    this%njprop = 0_i4
    IF (PRESENT(njprop)) this%njprop = MAX(0, njprop)

    !--- OUT arrays ---
    IF (ALLOCATED(this%rhs))    DEALLOCATE(this%rhs)
    ALLOCATE(this%rhs(this%ndofel, this%nrhs));       this%rhs    = 0.0_wp
    IF (ALLOCATED(this%amatrx)) DEALLOCATE(this%amatrx)
    ALLOCATE(this%amatrx(this%ndofel, this%ndofel));   this%amatrx = 0.0_wp
    IF (ALLOCATED(this%energy)) DEALLOCATE(this%energy)
    ALLOCATE(this%energy(8));                          this%energy = 0.0_wp

    !--- INOUT arrays ---
    IF (ALLOCATED(this%svars))  DEALLOCATE(this%svars)
    IF (this%nsvars > 0) THEN
      ALLOCATE(this%svars(this%nsvars));               this%svars  = 0.0_wp
    END IF

    !--- IN: Properties ---
    IF (ALLOCATED(this%props))  DEALLOCATE(this%props)
    ALLOCATE(this%props(this%nprops));                  this%props  = 0.0_wp
    IF (ALLOCATED(this%jprops)) DEALLOCATE(this%jprops)
    IF (this%njprop > 0) THEN
      ALLOCATE(this%jprops(this%njprop));              this%jprops = 0_i4
    END IF

    !--- IN: Time ---
    IF (ALLOCATED(this%time))   DEALLOCATE(this%time)
    ALLOCATE(this%time(2));                             this%time   = 0.0_wp

    !--- IN: DOF vectors ---
    IF (ALLOCATED(this%u))      DEALLOCATE(this%u)
    ALLOCATE(this%u(this%ndofel));                      this%u      = 0.0_wp
    IF (ALLOCATED(this%du))     DEALLOCATE(this%du)
    ALLOCATE(this%du(this%ndofel));                     this%du     = 0.0_wp
    IF (ALLOCATED(this%v))      DEALLOCATE(this%v)
    ALLOCATE(this%v(this%ndofel));                      this%v      = 0.0_wp
    IF (ALLOCATED(this%a))      DEALLOCATE(this%a)
    ALLOCATE(this%a(this%ndofel));                      this%a      = 0.0_wp

    !--- IN: Coordinates ---
    IF (ALLOCATED(this%coords)) DEALLOCATE(this%coords)
    ALLOCATE(this%coords(3, this%nnode));               this%coords = 0.0_wp

    !--- IN: Flags ---
    IF (ALLOCATED(this%lflags)) DEALLOCATE(this%lflags)
    ALLOCATE(this%lflags(6));                           this%lflags = 0_i4
  END SUBROUTINE Init

  SUBROUTINE Cleanup(this)
    CLASS(PH_UEL_Context), INTENT(INOUT) :: this
    IF (ALLOCATED(this%rhs))     DEALLOCATE(this%rhs)
    IF (ALLOCATED(this%amatrx))  DEALLOCATE(this%amatrx)
    IF (ALLOCATED(this%energy))  DEALLOCATE(this%energy)
    IF (ALLOCATED(this%svars))   DEALLOCATE(this%svars)
    IF (ALLOCATED(this%props))   DEALLOCATE(this%props)
    IF (ALLOCATED(this%jprops))  DEALLOCATE(this%jprops)
    IF (ALLOCATED(this%time))    DEALLOCATE(this%time)
    IF (ALLOCATED(this%u))       DEALLOCATE(this%u)
    IF (ALLOCATED(this%du))      DEALLOCATE(this%du)
    IF (ALLOCATED(this%v))       DEALLOCATE(this%v)
    IF (ALLOCATED(this%a))       DEALLOCATE(this%a)
    IF (ALLOCATED(this%coords))  DEALLOCATE(this%coords)
    IF (ALLOCATED(this%jdltyp))  DEALLOCATE(this%jdltyp)
    IF (ALLOCATED(this%lflags))  DEALLOCATE(this%lflags)
    IF (ALLOCATED(this%preload)) DEALLOCATE(this%preload)
    IF (ALLOCATED(this%params))  DEALLOCATE(this%params)
  END SUBROUTINE Cleanup

END MODULE PH_UEL_Def
