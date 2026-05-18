!===============================================================================
! MODULE: IF_Mat_Dispatch_Def
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Def — material dispatch routing TYPEs (cross-layer shared)
! BRIEF:  Lightweight TYPE definitions for material dispatch routing.
!         Lives at L1_IF so L4_PH consumers and L5_RT routers share
!         types without cross-layer dependency violation.
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Mat_Dispatch_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Routing status constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MAT_ROUTE_OK        = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MAT_ROUTE_NOT_FOUND = -1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MAT_ROUTE_NO_KERNEL = -2_i4

  !-----------------------------------------------------------------------------
  ! RT_Mat_Dispatch_Ctx — lightweight context for material dispatch routing
  !
  ! Populated during step init from L3 Desc (via Populate chain);
  ! consumed during element loop to dispatch constitutive calls.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Mat_Dispatch_Ctx
    INTEGER(i4) :: mat_type    = 0_i4   ! 11-family marker PH_MAT_* (1..11) when from L4 slot; registry mat_id 101.. elsewhere
    INTEGER(i4) :: mat_id      = 0_i4   ! L3 material ID (for diagnostics)
    INTEGER(i4) :: mat_pt_idx  = 0_i4   ! L4 slot_pool index (assigned by Populate)
    LOGICAL     :: is_user_sub = .FALSE. ! True if UMAT/VUMAT
    INTEGER(i4) :: route_status = 0_i4  ! IF_MAT_ROUTE_* after last dispatch
  END TYPE RT_Mat_Dispatch_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Mat_Dispatch_Table — routing table entry
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MAT_TABLE_MAX = 128_i4

  TYPE, PUBLIC :: RT_Mat_Route_Entry
    INTEGER(i4) :: mat_type   = 0_i4
    INTEGER(i4) :: mat_id     = 0_i4
    INTEGER(i4) :: mat_pt_idx = 0_i4
    LOGICAL     :: is_user    = .FALSE.
    LOGICAL     :: active     = .FALSE.
  END TYPE RT_Mat_Route_Entry

  TYPE, PUBLIC :: RT_Mat_Dispatch_Table
    TYPE(RT_Mat_Route_Entry) :: entries(IF_MAT_TABLE_MAX)
    INTEGER(i4)              :: n_entries = 0_i4
    LOGICAL                  :: initialized = .FALSE.
  END TYPE RT_Mat_Dispatch_Table

END MODULE IF_Mat_Dispatch_Def
