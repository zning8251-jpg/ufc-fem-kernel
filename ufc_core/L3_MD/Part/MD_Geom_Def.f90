!===============================================================================
! MODULE:  MD_Geom_Def
! LAYER:   L3_MD
! DOMAIN:  Part / Geom
! ROLE:    _Def
! BRIEF:   Geometry descriptor types — node coords, element connectivity,
!          geometry context aggregation. Desc-only (no State/Algo/Ctx).
!===============================================================================
MODULE MD_Geom_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: GEOM_SLEN = 64


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Geom_Node_Desc
  ! KIND:  Desc
  ! DESC:  Single node — ID + spatial coordinates
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Geom_Node_Desc
    INTEGER(i4) :: node_id = 0_i4                            ! [in] node ID
    INTEGER(i4) :: n_dim   = 3_i4                            ! [in] spatial dimension {2,3}
    REAL(wp)    :: coords(3) = 0.0_wp                        ! [in] node coordinates
  END TYPE MD_Geom_Node_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Geom_Elem_Desc
  ! KIND:  Desc
  ! DESC:  Single element — connectivity + properties
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Geom_Elem_Desc
    INTEGER(i4)       :: elem_id    = 0_i4                   ! [in] element ID
    CHARACTER(LEN=16) :: elem_type  = ""                     ! [in] type string (C3D8, S4R, etc.)
    CHARACTER(LEN=8)  :: family     = ""                     ! [in] family (SOLID, SHELL, BEAM)
    INTEGER(i4)       :: n_nodes    = 0_i4                   ! [in] number of nodes
    INTEGER(i4)       :: n_dof      = 0_i4                   ! [in] number of DOFs
    INTEGER(i4)       :: n_gp       = 0_i4                   ! [in] number of Gauss points
    INTEGER(i4)       :: section_id = 0_i4                   ! [in] section ID
    INTEGER(i4)       :: mat_id     = 0_i4                   ! [in] material ID
    INTEGER(i4), ALLOCATABLE :: conn(:)                      ! [in] connectivity array
  END TYPE MD_Geom_Elem_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Geom_Ctx
  ! KIND:  Ctx
  ! DESC:  Geometry context — aggregated node and element descriptions
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Geom_Ctx
    TYPE(MD_Geom_Node_Desc), ALLOCATABLE :: node_descs(:)    ! [inout] node descriptions
    TYPE(MD_Geom_Elem_Desc), ALLOCATABLE :: elem_descs(:)    ! [inout] element descriptions
    INTEGER(i4) :: n_nodes = 0_i4                            ! [inout] node count
    INTEGER(i4) :: n_elems = 0_i4                            ! [inout] element count
  END TYPE MD_Geom_Ctx

  PUBLIC :: MD_Geom_Ctx_Init

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Geom_Ctx_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize geometry context — reset counts, deallocate arrays
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Geom_Ctx_Init(geom_ctx)
    TYPE(MD_Geom_Ctx), INTENT(INOUT) :: geom_ctx

    geom_ctx%pop%n_nodes = 0_i4
    geom_ctx%n_elems = 0_i4
    IF (ALLOCATED(geom_ctx%node_descs)) DEALLOCATE(geom_ctx%node_descs)
    IF (ALLOCATED(geom_ctx%elem_descs)) DEALLOCATE(geom_ctx%elem_descs)
  END SUBROUTINE MD_Geom_Ctx_Init

END MODULE MD_Geom_Def
