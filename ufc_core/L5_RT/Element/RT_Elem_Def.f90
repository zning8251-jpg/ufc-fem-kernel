!===============================================================================
! MODULE: RT_Elem_Def
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Def — Four-type system (Desc/State/Algo/Ctx) + dispatch table types
! BRIEF:  AUTHORITY type definitions for Element domain.
! **W2**：L5 **四型** **`RT_Elem_*`** ↔ **`PH_Elem_*`**；**`RT_Elem_Dispatch_Table`** / **`family_id`**
!         与 L4 族枚举路由一致（装配入口消费此口径）。
!===============================================================================
!
! Four-Type Architecture (v2.0):
!   RT_Elem_Desc  — routing-level element descriptor (wraps PH_Elem_Desc)
!   RT_Elem_State — runtime element state (wraps PH_Elem_State + kernel ext)
!   RT_Elem_Algo  — step-level algorithm config (wraps PH_Elem_Algo)
!   RT_Elem_Ctx   — per-element runtime context (wraps PH_Elem_Ctx + DOF map)
!
! Dispatch Types:
!   RT_Elem_Compute_Proc   — abstract interface for family kernel callbacks
!   RT_Elem_Router_Entry   — single entry in the dispatch table
!   RT_Elem_Dispatch_Table — family_id → L4 kernel routing table
!
! Status: ACTIVE | Last verified: 2026-04-26
!===============================================================================
MODULE RT_Elem_Def
  USE IF_Prec_Core,     ONLY: wp, i4
  USE IF_Err_Brg,  ONLY: ErrorStatusType
  USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_State, &
                          PH_Elem_Algo,  PH_Elem_Ctx
  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! Desc -- routing-level element descriptor
  !   Wraps L4 cold metadata + L5 domain-level bookkeeping
  !============================================================================
  TYPE, PUBLIC :: RT_Elem_Desc
    TYPE(PH_Elem_Desc) :: base       ! L4 cold metadata (Populate source)
    INTEGER(i4) :: n_elem         = 0     ! Total elements in domain
    INTEGER(i4) :: max_nn         = 8     ! Max nodes per element type
    INTEGER(i4) :: max_ndof_elem  = 24    ! Max DOF per element
    INTEGER(i4) :: ndof_per_node  = 3     ! DOF per node (default: 3D structural)
  END TYPE RT_Elem_Desc

  !============================================================================
  ! State -- runtime element state (hot path output)
  !   Wraps L4 base state + assembly context + kernel state variables
  !============================================================================
  TYPE, PUBLIC :: RT_Elem_State
    TYPE(PH_Elem_State) :: base      ! L4 base state

    ! Assembly context
    INTEGER(i4) :: n_eq = 0               ! Number of equations
    INTEGER(i4), ALLOCATABLE :: eq_map(:) ! Equation mapping
    LOGICAL     :: is_active = .TRUE.     ! Active flag

    ! Kernel state extensions (UEL / per-element state variables)
    REAL(wp), ALLOCATABLE :: statev(:)    ! State variables [nstatev]
    REAL(wp)    :: energy(8) = 0.0_wp     ! Energy components [8]
    INTEGER(i4) :: nstatev = 0            ! Number of state variables
  END TYPE RT_Elem_State

  !============================================================================
  ! Algo -- step-level algorithm configuration
  !   Wraps L4 base algo + L5 routing/scheduling parameters
  !============================================================================
  TYPE, PUBLIC :: RT_Elem_Algo
    TYPE(PH_Elem_Algo) :: base       ! L4 algo (integration, hourglass)
    INTEGER(i4) :: calc_type = 0          ! 0=all, 1=Ke, 2=Fe, 3=Me, 4=output
    LOGICAL     :: nlgeom = .FALSE.       ! Geometric nonlinearity flag
  END TYPE RT_Elem_Algo

  !============================================================================
  ! Ctx -- per-element runtime context (hot path temporary)
  !   Wraps L4 base ctx + assembly offsets + DOF mapping scratch
  !============================================================================
  TYPE, PUBLIC :: RT_Elem_Ctx
    TYPE(PH_Elem_Ctx) :: base        ! L4 IP scratch (current_ip, det_J)

    ! Assembly offsets
    INTEGER(i4) :: node_offset  = 0       ! Node equation offset
    INTEGER(i4) :: elem_offset  = 0       ! Element matrix offset
    INTEGER(i4) :: n_secondary  = 0       ! Number of secondary DOFs

    ! Per-element DOF mapping scratch
    INTEGER(i4) :: elem_id      = 0       ! Current element ID
    INTEGER(i4) :: nn           = 0       ! Current element node count
    INTEGER(i4) :: ndof_elem    = 0       ! Current element DOF count
    INTEGER(i4) :: conn(8)      = 0       ! Node connectivity [max_nn]
    INTEGER(i4) :: dof_map(24)  = 0       ! DOF mapping [max_ndof_elem]
  END TYPE RT_Elem_Ctx

  !============================================================================
  ! Dispatch types -- family_id → L4 kernel routing
  !   Analogous to RT_Mat_Dispatch_Table for the Material domain.
  !============================================================================

  ABSTRACT INTERFACE
    SUBROUTINE RT_Elem_Compute_Proc(state, ctx, status)
      IMPORT :: RT_Elem_State, RT_Elem_Ctx, ErrorStatusType
      TYPE(RT_Elem_State),  INTENT(INOUT) :: state
      TYPE(RT_Elem_Ctx),    INTENT(IN)    :: ctx
      TYPE(ErrorStatusType), INTENT(OUT)  :: status
    END SUBROUTINE RT_Elem_Compute_Proc
  END INTERFACE

  TYPE, PUBLIC :: RT_Elem_Router_Entry
    INTEGER(i4) :: family_id = 0
    PROCEDURE(RT_Elem_Compute_Proc), POINTER, NOPASS :: compute => NULL()
  END TYPE RT_Elem_Router_Entry

  TYPE, PUBLIC :: RT_Elem_Dispatch_Table
    INTEGER(i4) :: n_registered = 0
    INTEGER(i4) :: max_families = 0
    TYPE(RT_Elem_Router_Entry), ALLOCATABLE :: entries(:)
  END TYPE RT_Elem_Dispatch_Table

!===============================================================================
! SIO unified Arg types for Element domain
! These replace the legacy inp/out pair pattern.
!===============================================================================

PUBLIC :: RT_Elem_Eval_Ke_Arg
PUBLIC :: RT_Elem_Eval_Fe_Arg

TYPE, PUBLIC :: RT_Elem_Eval_Ke_Arg
  ! [IN] element state
  TYPE(RT_Elem_Desc) :: desc                  ! [IN]  element descriptor
  TYPE(RT_Elem_State) :: state                ! [INOUT] element state
  TYPE(RT_Elem_Ctx) :: ctx                    ! [INOUT] element context

  ! [IN] evaluation parameters
  INTEGER(i4) :: elem_id                      ! [IN]  element ID
  INTEGER(i4) :: n_dof                        ! [IN]  degrees of freedom
  REAL(wp), ALLOCATABLE :: coords(:,:)         ! [IN]  node coordinates
  REAL(wp), ALLOCATABLE :: props(:)            ! [IN]  section properties
  REAL(wp) :: time_step                       ! [IN]  time step size

  ! [OUT] stiffness matrix
  REAL(wp), ALLOCATABLE :: ke(:,:)            ! [OUT] element stiffness matrix
  INTEGER(i4) :: status_code                  ! [OUT] exit status
  CHARACTER(len=256) :: message               ! [OUT] status message
END TYPE RT_Elem_Eval_Ke_Arg

TYPE, PUBLIC :: RT_Elem_Eval_Fe_Arg
  ! [IN] element state
  TYPE(RT_Elem_Desc) :: desc                  ! [IN]  element descriptor
  TYPE(RT_Elem_State) :: state                ! [INOUT] element state
  TYPE(RT_Elem_Ctx) :: ctx                    ! [INOUT] element context

  ! [IN] evaluation parameters
  INTEGER(i4) :: elem_id                      ! [IN]  element ID
  INTEGER(i4) :: n_dof                        ! [IN]  degrees of freedom
  REAL(wp), ALLOCATABLE :: coords(:,:)         ! [IN]  node coordinates
  REAL(wp), ALLOCATABLE :: u_elem(:)           ! [IN]  element nodal displacements

  ! [OUT] force vector
  REAL(wp), ALLOCATABLE :: fe(:)              ! [OUT] element force vector
  INTEGER(i4) :: status_code                  ! [OUT] exit status
  CHARACTER(len=256) :: message               ! [OUT] status message
END TYPE RT_Elem_Eval_Fe_Arg

END MODULE RT_Elem_Def
