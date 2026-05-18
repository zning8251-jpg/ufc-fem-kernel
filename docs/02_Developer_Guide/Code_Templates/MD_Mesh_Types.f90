!===============================================================================
! Module: MD_Mesh_Types                                          [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Mesh — Node/element topology and DOF mapping descriptors
!
! Purpose:
!   Defines Desc types for the Mesh domain at the MD layer.
!   Mesh data is read from the INP file at load time and remains immutable
!   throughout the analysis (coordinates are updated only inside L5_RT state).
!
! Type catalogue (5 TYPEs):
!   MD_Node_Desc         – Single node: coordinates + DOF label list
!   MD_Elem_Connect_Desc – Connectivity descriptor (global node numbers)
!   MD_NodeSet_Desc      – Named node set (*NSET)
!   MD_ElemSet_Desc      – Named element set (*ELSET)
!   MD_Mesh_Registry     – Model-level mesh container
!
! Layer dependency:
!   USE IF_Prec     (wp, i4)
!   USE IF_Err_Brg  (ErrorStatusType + standard bridge vocabulary:
!                   init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_Mesh_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Node_Desc
  PUBLIC :: MD_Elem_Connect_Desc
  PUBLIC :: MD_NodeSet_Desc
  PUBLIC :: MD_ElemSet_Desc
  PUBLIC :: MD_Mesh_Registry

  !-- Spatial dimension constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MESH_NDIM_2D  ! migrated from MESH_NDIM_2D
    MESH_NDIM_2D = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MESH_NDIM_3D  ! migrated from MESH_NDIM_3D
    MESH_NDIM_3D = 3_i4

  !-- DOF type constants (aligned with Abaqus convention)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_UX  = 1_i4   ! Translation X  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_UY  = 2_i4   ! Translation Y  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_UZ  = 3_i4   ! Translation Z  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_RX  = 4_i4   ! Rotation X  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_RY  = 5_i4   ! Rotation Y  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_RZ  = 6_i4   ! Rotation Z  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_T   = 11_i4  ! Temperature (thermal DOF)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_DOF_DOF_P   = 8_i4   ! Pore pressure / fluid press  ! migrated

  !-----------------------------------------------------------------------------
  ! MD_Node_Desc — Single node descriptor
  !   Stores the reference (undeformed) coordinates and DOF assignments.
  !   node_id is the global Abaqus node number (from *NODE).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Node_Desc
    !-- Identification
    INTEGER(i4) :: node_id  = 0           ! Global node number (≥1)
    INTEGER(i4) :: ndim     = MESH_NDIM_3D ! Spatial dimension (2 or 3)

    !-- Reference coordinates [m] (immutable; updated coords live in RT state)
    REAL(wp) :: x0(3) = 0.0_wp            ! (X, Y, Z) reference position

    !-- DOF map: dof_ids(ndof) — Abaqus DOF labels assigned to this node
    INTEGER(i4), ALLOCATABLE :: dof_ids(:)   ! Allocated to size ndof
    INTEGER(i4) :: ndof = 0                  ! Number of active DOFs

    !-- Global equation numbers (assigned by L5_RT numbering)
    INTEGER(i4), ALLOCATABLE :: eq_nums(:)   ! eq_nums(ndof), 0=constrained

    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Node_Desc

  !-----------------------------------------------------------------------------
  ! MD_Elem_Connect_Desc — Element connectivity descriptor
  !   Stores ordered node list and element family identifier.
  !   elem_id is the global Abaqus element number (from *ELEMENT).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Connect_Desc
    !-- Identification
    INTEGER(i4) :: elem_id   = 0    ! Global element number (≥1)
    INTEGER(i4) :: elem_type = 0    ! Internal elem-type code (ELEM_FAMILY_XXX)
    INTEGER(i4) :: nnode     = 0    ! Number of nodes in this element

    !-- Ordered global node numbers (size = nnode)
    INTEGER(i4), ALLOCATABLE :: node_ids(:)   ! node_ids(nnode)

    !-- Section and material cross-references
    INTEGER(i4) :: section_id = 0  ! Associated section (MD_Sect_Base_Desc)
    INTEGER(i4) :: mat_id     = 0  ! Shortcut to material (via section)

    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Elem_Connect_Desc

  !-----------------------------------------------------------------------------
  ! MD_NodeSet_Desc — Named node set (*NSET)
  !   Stores the sorted list of global node IDs belonging to the set.
  !   Used by BC/Load domains to look up node sets by name at runtime.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_NodeSet_Desc
    CHARACTER(LEN=64) :: set_name   = ''   ! Abaqus *NSET,NSET=<name>
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    INTEGER(i4) :: nnodes = 0

    !-- Generation flag: .TRUE. if generated via GENERATE option
    LOGICAL :: is_generated = .FALSE.
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_NodeSet_Desc

  !-----------------------------------------------------------------------------
  ! MD_ElemSet_Desc — Named element set (*ELSET)
  !   Stores the sorted list of global element IDs belonging to the set.
  !   Used by output/field domains to filter elements.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ElemSet_Desc
    CHARACTER(LEN=64) :: set_name   = ''
    INTEGER(i4), ALLOCATABLE :: elem_ids(:)
    INTEGER(i4) :: nelems = 0

    LOGICAL :: is_generated   = .FALSE.
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_ElemSet_Desc

  !-----------------------------------------------------------------------------
  ! MD_Mesh_Registry — Model-level mesh container
  !   Owns all nodes, element connectivities, and named sets.
  !   Provides lookup utilities used by L4_PH bridge and L5_RT assembly.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mesh_Registry
    !-- Node array (indexed by sequential position; use GetNodeIdx for ID→pos)
    TYPE(MD_Node_Desc),         POINTER :: nodes(:)
    INTEGER(i4) :: nnodes    = 0
    INTEGER(i4) :: node_cap  = 0

    !-- Element connectivity array
    TYPE(MD_Elem_Connect_Desc), POINTER :: elems(:)
    INTEGER(i4) :: nelems    = 0
    INTEGER(i4) :: elem_cap  = 0

    !-- Named sets
    TYPE(MD_NodeSet_Desc), POINTER :: node_sets(:)
    INTEGER(i4) :: n_node_sets = 0

    TYPE(MD_ElemSet_Desc), POINTER :: elem_sets(:)
    INTEGER(i4) :: n_elem_sets = 0

    !-- Spatial dimension of the model
    INTEGER(i4) :: ndim = MESH_NDIM_3D

    !-- Total active DOF count (assigned after numbering)
    INTEGER(i4) :: total_dof = 0

  CONTAINS
    PROCEDURE :: Init          => MeshReg_Init
    PROCEDURE :: AddNode       => MeshReg_AddNode
    PROCEDURE :: AddElem       => MeshReg_AddElem
    PROCEDURE :: AddNodeSet    => MeshReg_AddNodeSet
    PROCEDURE :: AddElemSet    => MeshReg_AddElemSet
    PROCEDURE :: GetNodeIdx    => MeshReg_GetNodeIdx
    PROCEDURE :: GetElemIdx    => MeshReg_GetElemIdx
    PROCEDURE :: FindNodeSet   => MeshReg_FindNodeSet
    PROCEDURE :: FindElemSet   => MeshReg_FindElemSet
    PROCEDURE :: Clear         => MeshReg_Clear
  END TYPE MD_Mesh_Registry

CONTAINS

  !=============================================================================
  ! MD_Mesh_Registry procedures
  !=============================================================================

  SUBROUTINE MeshReg_Init(self, est_nodes, est_elems)
    CLASS(MD_Mesh_Registry), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: est_nodes, est_elems

    IF (ALLOCATED(self%nodes)) CALL self%Clear()
    self%node_cap = MAX(64_i4, est_nodes)
    self%elem_cap = MAX(64_i4, est_elems)
    ALLOCATE(self%nodes(self%node_cap))
    ALLOCATE(self%elems(self%elem_cap))
    ALLOCATE(self%node_sets(16))
    ALLOCATE(self%elem_sets(16))
    self%nnodes     = 0
    self%nelems     = 0
    self%n_node_sets = 0
    self%n_elem_sets = 0
  END SUBROUTINE MeshReg_Init

  SUBROUTINE MeshReg_AddNode(self, nd)
    CLASS(MD_Mesh_Registry), INTENT(INOUT) :: self
    TYPE(MD_Node_Desc),      INTENT(IN)    :: nd

    TYPE(MD_Node_Desc), POINTER :: tmp(:)
    INTEGER(i4) :: n, nc

    n  = self%nnodes
    nc = self%node_cap
    IF (nc > 0 .AND. n >= nc) THEN
      ALLOCATE(tmp(nc*2))
      tmp(1:n) = self%nodes(1:n)
      CALL MOVE_ALLOC(tmp, self%nodes)
      self%node_cap = nc * 2_i4
    END IF
    self%nnodes = n + 1
    self%nodes(self%nnodes) = nd
  END SUBROUTINE MeshReg_AddNode

  SUBROUTINE MeshReg_AddElem(self, el)
    CLASS(MD_Mesh_Registry),    INTENT(INOUT) :: self
    TYPE(MD_Elem_Connect_Desc), INTENT(IN)    :: el

    TYPE(MD_Elem_Connect_Desc), POINTER :: tmp(:)
    INTEGER(i4) :: n, nc

    n  = self%nelems
    nc = self%elem_cap
    IF (nc > 0 .AND. n >= nc) THEN
      ALLOCATE(tmp(nc*2))
      tmp(1:n) = self%elems(1:n)
      CALL MOVE_ALLOC(tmp, self%elems)
      self%elem_cap = nc * 2_i4
    END IF
    self%nelems = n + 1
    self%elems(self%nelems) = el
  END SUBROUTINE MeshReg_AddElem

  SUBROUTINE MeshReg_AddNodeSet(self, ns)
    CLASS(MD_Mesh_Registry), INTENT(INOUT) :: self
    TYPE(MD_NodeSet_Desc),   INTENT(IN)    :: ns

    self%n_node_sets = self%n_node_sets + 1
    self%node_sets(self%n_node_sets) = ns
  END SUBROUTINE MeshReg_AddNodeSet

  SUBROUTINE MeshReg_AddElemSet(self, es)
    CLASS(MD_Mesh_Registry), INTENT(INOUT) :: self
    TYPE(MD_ElemSet_Desc),   INTENT(IN)    :: es

    self%n_elem_sets = self%n_elem_sets + 1
    self%elem_sets(self%n_elem_sets) = es
  END SUBROUTINE MeshReg_AddElemSet

  FUNCTION MeshReg_GetNodeIdx(self, id) RESULT(idx)
    CLASS(MD_Mesh_Registry), INTENT(IN) :: self
    INTEGER(i4),             INTENT(IN) :: id
    INTEGER(i4) :: idx, i
    idx = 0
    DO i = 1, self%nnodes
      IF (self%nodes(i)%node_id == id) THEN
        idx = i
        RETURN
      END IF
    END DO
  END FUNCTION MeshReg_GetNodeIdx

  FUNCTION MeshReg_GetElemIdx(self, id) RESULT(idx)
    CLASS(MD_Mesh_Registry), INTENT(IN) :: self
    INTEGER(i4),             INTENT(IN) :: id
    INTEGER(i4) :: idx, i
    idx = 0
    DO i = 1, self%nelems
      IF (self%elems(i)%elem_id == id) THEN
        idx = i
        RETURN
      END IF
    END DO
  END FUNCTION MeshReg_GetElemIdx

  FUNCTION MeshReg_FindNodeSet(self, name) RESULT(idx)
    CLASS(MD_Mesh_Registry), INTENT(IN) :: self
    CHARACTER(LEN=*),        INTENT(IN) :: name
    INTEGER(i4) :: idx, i
    idx = 0
    DO i = 1, self%n_node_sets
      IF (TRIM(self%node_sets(i)%set_name) == TRIM(name)) THEN
        idx = i
        RETURN
      END IF
    END DO
  END FUNCTION MeshReg_FindNodeSet

  FUNCTION MeshReg_FindElemSet(self, name) RESULT(idx)
    CLASS(MD_Mesh_Registry), INTENT(IN) :: self
    CHARACTER(LEN=*),        INTENT(IN) :: name
    INTEGER(i4) :: idx, i
    idx = 0
    DO i = 1, self%n_elem_sets
      IF (TRIM(self%elem_sets(i)%set_name) == TRIM(name)) THEN
        idx = i
        RETURN
      END IF
    END DO
  END FUNCTION MeshReg_FindElemSet

  SUBROUTINE MeshReg_Clear(self)
    CLASS(MD_Mesh_Registry), INTENT(INOUT) :: self
    INTEGER(i4) :: i
    IF (ALLOCATED(self%nodes)) THEN
      DO i = 1, self%nnodes
        IF (ALLOCATED(self%nodes(i)%dof_ids)) DEALLOCATE(self%nodes(i)%dof_ids)
        IF (ALLOCATED(self%nodes(i)%eq_nums)) DEALLOCATE(self%nodes(i)%eq_nums)
      END DO
      DEALLOCATE(self%nodes)
    END IF
    IF (ALLOCATED(self%elems)) THEN
      DO i = 1, self%nelems
        IF (ALLOCATED(self%elems(i)%node_ids)) DEALLOCATE(self%elems(i)%node_ids)
      END DO
      DEALLOCATE(self%elems)
    END IF
    IF (ALLOCATED(self%node_sets)) THEN
      DO i = 1, self%n_node_sets
        IF (ALLOCATED(self%node_sets(i)%node_ids)) &
            DEALLOCATE(self%node_sets(i)%node_ids)
      END DO
      DEALLOCATE(self%node_sets)
    END IF
    IF (ALLOCATED(self%elem_sets)) THEN
      DO i = 1, self%n_elem_sets
        IF (ALLOCATED(self%elem_sets(i)%elem_ids)) &
            DEALLOCATE(self%elem_sets(i)%elem_ids)
      END DO
      DEALLOCATE(self%elem_sets)
    END IF
    self%nnodes     = 0
    self%nelems      = 0
    self%n_node_sets = 0
    self%n_elem_sets = 0
    self%node_cap    = 0
    self%elem_cap    = 0
    self%total_dof   = 0
  END SUBROUTINE MeshReg_Clear

  !=============================================================================
  ! MD_Mesh_Domain — Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_Mesh_Domain
    TYPE(MD_Node_Desc),    ALLOCATABLE :: nodes(:)    ! Node array [n_nodes]
    TYPE(MD_Elem_Desc),    ALLOCATABLE :: elems(:)    ! Elem array [n_elems]
    TYPE(MD_NodeSet_Desc), ALLOCATABLE :: node_sets(:)! Node sets [n_node_sets]
    TYPE(MD_ElemSet.Desc), ALLOCATABLE :: elem_sets(:)! Elem sets [n_elem_sets]
    INTEGER(i4) :: nnodes      = 0_i4
    INTEGER(i4) :: nelems      = 0_i4
    INTEGER(i4) :: n_node_sets = 0_i4
    INTEGER(i4) :: n_elem_sets = 0_i4
    INTEGER(i4) :: max_nodes   = 0_i4
    INTEGER(i4) :: max_elems   = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen      = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => MD_Mesh_Domain_Init
    PROCEDURE :: Finalize => MD_Mesh_Domain_Finalize
  END TYPE MD_Mesh_Domain

CONTAINS

  SUBROUTINE MD_Mesh_Domain_Init(this, cap_nodes, cap_elems, status)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: cap_nodes, cap_elems
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL MD_Mesh_Domain_Finalize(this)
    IF (cap_nodes < 1_i4 .OR. cap_elems < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Mesh_Domain_Init: capacities must be >= 1'
      RETURN
    END IF
    ALLOCATE(this%nodes(cap_nodes))
    ALLOCATE(this%elems(cap_elems))
    ALLOCATE(this%node_sets(cap_nodes/100+1))
    ALLOCATE(this%elem_sets(cap_elems/100+1))
    this%nnodes      = 0_i4
    this%nelems      = 0_i4
    this%n_node_sets = 0_i4
    this%n_elem_sets = 0_i4
    this%max_nodes   = cap_nodes
    this%max_elems   = cap_elems
    this%initialized = .TRUE.
    this%frozen      = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Domain_Init

  SUBROUTINE MD_Mesh_Domain_Finalize(this)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this
    INTEGER(i4) :: i
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%nodes)) THEN
      DO i = 1, this%nnodes
        IF (ALLOCATED(this%nodes(i)%coords)) DEALLOCATE(this%nodes(i)%coords)
      END DO
      DEALLOCATE(this%nodes)
    END IF
    IF (ALLOCATED(this%elems)) THEN
      DO i = 1, this%nelems
        IF (ALLOCATED(this%elems(i)%connectivity)) DEALLOCATE(this%elems(i)%connectivity)
      END DO
      DEALLOCATE(this%elems)
    END IF
    IF (ALLOCATED(this%node_sets)) DEALLOCATE(this%node_sets)
    IF (ALLOCATED(this%elem_sets)) DEALLOCATE(this%elem_sets)
    this%nnodes      = 0_i4
    this%nelems      = 0_i4
    this%n_node_sets = 0_i4
    this%n_elem_sets = 0_i4
    this%max_nodes   = 0_i4
    this%max_elems   = 0_i4
    this%initialized = .FALSE.
    this%frozen      = .FALSE.
  END SUBROUTINE MD_Mesh_Domain_Finalize

END MODULE MD_Mesh_Types
