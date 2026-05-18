!===============================================================================
! MODULE: PH_Mat_UMAT_Def
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  UMAT context (ABAQUS-style) and abstract interface types.
!   W1: **PH_UMAT_Context** is ABI workspace; physical parameters must match **slot_pool%desc%props** when wired from Populate.
!===============================================================================
MODULE PH_Mat_UMAT_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !--- SECTION 1: TYPE DEFINITIONS ---

  !=============================================================================
  ! TYPE: PH_UMAT_Context
  ! KIND: Ctx (per-call UMAT workspace)
  ! DESC: ABAQUS-style UMAT in/out bundle — all standard UMAT fields.
  !=============================================================================
  TYPE, PUBLIC :: PH_UMAT_Context
    REAL(wp), ALLOCATABLE :: sigma(:)
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp), ALLOCATABLE :: ddsdde(:,:)
    REAL(wp) :: sse, spd, scd, rpl
    REAL(wp), ALLOCATABLE :: ddsddt(:)
    REAL(wp), ALLOCATABLE :: drplde(:)
    REAL(wp) :: drpldt
    REAL(wp), ALLOCATABLE :: stran(:)
    REAL(wp), ALLOCATABLE :: dstran(:)
    REAL(wp), ALLOCATABLE :: time(:)
    REAL(wp) :: dtime, temp, dtemp
    REAL(wp), ALLOCATABLE :: predef(:)
    REAL(wp), ALLOCATABLE :: dpred(:)
    CHARACTER(LEN=80) :: cmname
    INTEGER(i4) :: ndi, nshr, ntens, nstatv, nprops
    REAL(wp), ALLOCATABLE :: props(:)
    REAL(wp), ALLOCATABLE :: coords(:)
    REAL(wp), ALLOCATABLE :: drot(:,:)
    REAL(wp) :: pnewdt, celent
    REAL(wp), ALLOCATABLE :: dfgrd0(:,:)
    REAL(wp), ALLOCATABLE :: dfgrd1(:,:)
    INTEGER(i4) :: noel, npt, layer, kspt, kinc, kstep
  CONTAINS
    PROCEDURE, PUBLIC :: Init => PH_UMAT_Context_Init
    PROCEDURE, PUBLIC :: Cleanup => PH_UMAT_Context_Clean
  END TYPE PH_UMAT_Context

  !=============================================================================
  ! INTERFACE: PH_UMAT_Intf
  ! KIND: Abstract
  ! DESC: Unified Compute interface for all UMAT-compatible materials.
  !=============================================================================
  PUBLIC :: PH_UMAT_Intf
  ABSTRACT INTERFACE
    SUBROUTINE PH_UMAT_Intf(ctx, status)
      IMPORT :: PH_UMAT_Context, ErrorStatusType
      TYPE(PH_UMAT_Context), INTENT(INOUT) :: ctx
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    END SUBROUTINE PH_UMAT_Intf
  END INTERFACE

CONTAINS

  SUBROUTINE PH_UMAT_Context_Init(this, ndi, nshr, nstatv, nprops)
    CLASS(PH_UMAT_Context), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndi, nshr, nstatv, nprops
    INTEGER(i4) :: ntens, nsv, npr
    this%ndi = ndi
    this%nshr = nshr
    this%nstatv = MAX(1, nstatv)
    this%nprops = MAX(1, nprops)
    ntens = ndi + nshr
    nsv = this%nstatv
    npr = this%nprops
    IF (ALLOCATED(this%sigma)) DEALLOCATE(this%sigma)
    ALLOCATE(this%sigma(ntens))
    this%sigma = 0.0_wp
    IF (ALLOCATED(this%statev)) DEALLOCATE(this%statev)
    ALLOCATE(this%statev(nsv))
    this%statev = 0.0_wp
    IF (ALLOCATED(this%ddsdde)) DEALLOCATE(this%ddsdde)
    ALLOCATE(this%ddsdde(ntens, ntens))
    this%ddsdde = 0.0_wp
    IF (ALLOCATED(this%stran)) DEALLOCATE(this%stran)
    ALLOCATE(this%stran(ntens))
    this%stran = 0.0_wp
    IF (ALLOCATED(this%dstran)) DEALLOCATE(this%dstran)
    ALLOCATE(this%dstran(ntens))
    this%dstran = 0.0_wp
    IF (ALLOCATED(this%time)) DEALLOCATE(this%time)
    ALLOCATE(this%time(2))
    this%time = 0.0_wp
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(npr))
    this%props = 0.0_wp
    IF (ALLOCATED(this%ddsddt)) DEALLOCATE(this%ddsddt)
    ALLOCATE(this%ddsddt(ntens))
    this%ddsddt = 0.0_wp
    IF (ALLOCATED(this%drplde)) DEALLOCATE(this%drplde)
    ALLOCATE(this%drplde(ntens))
    this%drplde = 0.0_wp
    IF (ALLOCATED(this%predef)) DEALLOCATE(this%predef)
    ALLOCATE(this%predef(1))
    this%predef = 0.0_wp
    IF (ALLOCATED(this%dpred)) DEALLOCATE(this%dpred)
    ALLOCATE(this%dpred(1))
    this%dpred = 0.0_wp
    IF (ALLOCATED(this%coords)) DEALLOCATE(this%coords)
    ALLOCATE(this%coords(3))
    this%coords = 0.0_wp
    IF (ALLOCATED(this%drot)) DEALLOCATE(this%drot)
    ALLOCATE(this%drot(3,3))
    this%drot = 0.0_wp
    IF (ALLOCATED(this%dfgrd0)) DEALLOCATE(this%dfgrd0)
    ALLOCATE(this%dfgrd0(3,3))
    this%dfgrd0 = 0.0_wp
    IF (ALLOCATED(this%dfgrd1)) DEALLOCATE(this%dfgrd1)
    ALLOCATE(this%dfgrd1(3,3))
    this%dfgrd1 = 0.0_wp
  END SUBROUTINE PH_UMAT_Context_Init

  SUBROUTINE PH_UMAT_Context_Clean(this)
    CLASS(PH_UMAT_Context), INTENT(INOUT) :: this
    IF (ALLOCATED(this%sigma)) DEALLOCATE(this%sigma)
    IF (ALLOCATED(this%statev)) DEALLOCATE(this%statev)
    IF (ALLOCATED(this%ddsdde)) DEALLOCATE(this%ddsdde)
    IF (ALLOCATED(this%stran)) DEALLOCATE(this%stran)
    IF (ALLOCATED(this%dstran)) DEALLOCATE(this%dstran)
    IF (ALLOCATED(this%time)) DEALLOCATE(this%time)
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    IF (ALLOCATED(this%ddsddt)) DEALLOCATE(this%ddsddt)
    IF (ALLOCATED(this%drplde)) DEALLOCATE(this%drplde)
    IF (ALLOCATED(this%predef)) DEALLOCATE(this%predef)
    IF (ALLOCATED(this%dpred)) DEALLOCATE(this%dpred)
    IF (ALLOCATED(this%coords)) DEALLOCATE(this%coords)
    IF (ALLOCATED(this%drot)) DEALLOCATE(this%drot)
    IF (ALLOCATED(this%dfgrd0)) DEALLOCATE(this%dfgrd0)
    IF (ALLOCATED(this%dfgrd1)) DEALLOCATE(this%dfgrd1)
  END SUBROUTINE PH_UMAT_Context_Clean

END MODULE PH_Mat_UMAT_Def
