!===============================================================================
! MODULE:  MD_Mesh_Mgr
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Mgr
! BRIEF:   Mesh manager — P0 Register/Query, single-mesh container.
!===============================================================================
!
! DEPRECATED: g_mesh_manager Mesh_FromDesc/MD_Bridge_Conv_Mesh
! md_layer%mesh (MD_Mesh_IsAvailable + MD_Mesh_Get*) ?!
! Contents:
!   Types:
!     - MeshManager: Mesh manager type (mesh: MeshData)
!   Variables:
!     - g_mesh_manager: Legacy; Conv only; read paths use md_layer%mesh
!   Subroutines:
!     - MeshManager: Init, Clean, CreateMesh, GetMesh, Valid
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
MODULE MD_Mesh_Mgr
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md
  USE IF_Prec_Core,        only: wp, i4, i8
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mesh_Data, ONLY: MeshData

  implicit none

  private

  !=============================================================================
  ! Mesh Manager Type
  !=============================================================================
  type, public :: MeshManager
    type(MeshData)                       :: mesh
    LOGICAL :: init = .false.
  contains
    procedure :: Init
    procedure :: Clean
    procedure :: CreateMesh
    procedure :: GetMesh
    procedure :: Valid
  end type MeshManager

  ! Global mesh manager
  type(MeshManager), save, public :: g_mesh_manager

  public :: MeshManager

contains

  !=============================================================================
  ! MeshManager Procedures
  !=============================================================================
  subroutine Init(this, status)
    class(MeshManager),    intent(inout) :: this
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    if (this%init) then
      status%status_code = IF_STATUS_OK
      return
    end if

    this%init = .true.
    status%status_code = IF_STATUS_OK
  end subroutine Init

  subroutine Clean(this)
    class(MeshManager), intent(inout) :: this

    call this%mesh%Clean()
    this%init = .false.
  end subroutine Clean

  subroutine CreateMesh(this, nNodes, nElems, spatial_dim, status, max_nodes_per_elem)
    class(MeshManager),   intent(inout) :: this
    integer(i8),           intent(in)    :: nNodes
    integer(i8),           intent(in)    :: nElems
    integer(i4),           intent(in)    :: spatial_dim
    type(ErrorStatusType),  intent(out)   :: status
    integer(i4),           intent(in), optional :: max_nodes_per_elem

    call this%mesh%Init(nNodes, nElems, spatial_dim, status, max_nodes_per_elem)
    if (status%status_code == IF_STATUS_OK) then
      this%init = .true.
    end if
  end subroutine CreateMesh

  subroutine GetMesh(this, mesh)
    class(MeshManager), intent(in)  :: this
    type(MeshData),      intent(out) :: mesh

    mesh = this%mesh
  end subroutine GetMesh

  subroutine Valid(this, status)
    class(MeshManager),   intent(in)  :: this
    type(ErrorStatusType),  intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "MeshManager not initialized"
      return
    end if

    call this%mesh%Valid(status)
    if (status%status_code /= IF_STATUS_OK) return

    status%status_code = IF_STATUS_OK
  end subroutine Valid

END MODULE MD_Mesh_Mgr
