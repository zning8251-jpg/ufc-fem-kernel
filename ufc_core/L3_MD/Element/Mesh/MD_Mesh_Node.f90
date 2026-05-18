!===============================================================================
! MODULE:  MD_Mesh_Node
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Impl
! BRIEF:   Mesh node descriptor and state types (Desc node).
!===============================================================================
MODULE MD_Mesh_Node
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md
  USE IF_Prec_Core,        only: wp, i4, i8
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
  USE MD_Base_ObjModel, ONLY: DescBase, StateBase, CAT_DESC, CAT_STATE, uf_set_error_status
  USE UF_DataPlatform, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, IF_DATA_TYPE_INT, IF_DATA_TYPE_DP

  implicit none

  private

  !=============================================================================
  ! Mesh Node Type Definitions
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(DescBase) :: MeshNodeDesc
    INTEGER(i4) :: id = 0_i4
    REAL(wp) :: coords(3) = 0.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MeshNodeDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MeshNodeDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MeshNodeDesc_Init
  END TYPE MeshNodeDesc

  TYPE, PUBLIC, EXTENDS(StateBase) :: MeshNodeState
    INTEGER(i4) :: id = 0_i4
    REAL(wp) :: coords(3) = 0.0_wp
    REAL(wp) :: currentCoords(3) = 0.0_wp  ! Large-deform WriteBack target (node_state%currentCoords)
    REAL(wp) :: disp(3) = 0.0_wp
    REAL(wp) :: vel(3) = 0.0_wp
    REAL(wp) :: acc(3) = 0.0_wp
    REAL(wp) :: rotation(3) = 0.0_wp
    REAL(wp) :: temperature = 0.0_wp
    REAL(wp) :: pressure = 0.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MeshNodeState_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MeshNodeState_Ensure
    PROCEDURE, PUBLIC :: Init => MeshNodeState_Init
  END TYPE MeshNodeState

  public :: MeshNodeDesc, MeshNodeState

contains

  !=============================================================================
  ! MeshNodeDesc Procedures
  !=============================================================================
  SUBROUTINE MeshNodeDesc_Init(this, id, coords)
    CLASS(MeshNodeDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id
    REAL(wp), INTENT(IN), OPTIONAL :: coords(3)
    CALL this%DescBase%Init(CAT_DESC, 'DESC::MESHNODE')
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(coords)) this%coords = coords
  END SUBROUTINE MeshNodeDesc_Init

  SUBROUTINE MeshNodeDesc_RegLayout(this)
    CLASS(MeshNodeDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(2)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'coords'
    fields(2)%data_type = IF_DATA_TYPE_DP
    fields(2)%offset_bytes = offset
    offset = offset + 24
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 2, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshNodeDesc_RegLayout")
  END SUBROUTINE MeshNodeDesc_RegLayout

  SUBROUTINE MeshNodeDesc_Ensure(this)
    CLASS(MeshNodeDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_MESHNODEDESC_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshNodeDesc_Ensure")
  END SUBROUTINE MeshNodeDesc_Ensure

  !=============================================================================
  ! MeshNodeState Procedures
  !=============================================================================
  SUBROUTINE MeshNodeState_Init(this, id, coords, disp, vel, acc)
    CLASS(MeshNodeState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id
    REAL(wp), INTENT(IN), OPTIONAL :: coords(3), disp(3), vel(3), acc(3)
    this%category = CAT_STATE
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(coords)) this%coords = coords
    IF (PRESENT(disp)) this%disp = disp
    IF (PRESENT(vel)) this%vel = vel
    IF (PRESENT(acc)) this%acc = acc
  END SUBROUTINE MeshNodeState_Init

  SUBROUTINE MeshNodeState_RegLayout(this)
    CLASS(MeshNodeState), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(9)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'coords'
    fields(2)%data_type = IF_DATA_TYPE_DP
    fields(2)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(2)%offset_bytes = offset
    offset = offset + 24
    fields(3)%field_name = 'currentCoords'
    fields(3)%data_type = IF_DATA_TYPE_DP
    fields(3)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(3)%offset_bytes = offset
    offset = offset + 24
    fields(4)%field_name = 'disp'
    fields(4)%data_type = IF_DATA_TYPE_DP
    fields(4)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(4)%offset_bytes = offset
    offset = offset + 24
    fields(5)%field_name = 'vel'
    fields(5)%data_type = IF_DATA_TYPE_DP
    fields(5)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(5)%offset_bytes = offset
    offset = offset + 24
    fields(6)%field_name = 'acc'
    fields(6)%data_type = IF_DATA_TYPE_DP
    fields(6)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(6)%offset_bytes = offset
    offset = offset + 24
    fields(7)%field_name = 'rotation'
    fields(7)%data_type = IF_DATA_TYPE_DP
    fields(7)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(7)%offset_bytes = offset
    offset = offset + 24
    fields(8)%field_name = 'temperature'
    fields(8)%data_type = IF_DATA_TYPE_DP
    fields(8)%offset_bytes = offset
    offset = offset + 8
    fields(9)%field_name = 'pressure'
    fields(9)%data_type = IF_DATA_TYPE_DP
    fields(9)%offset_bytes = offset
    offset = offset + 8
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 9, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshNodeState_RegLayout")
  END SUBROUTINE MeshNodeState_RegLayout

  SUBROUTINE MeshNodeState_Ensure(this)
    CLASS(MeshNodeState), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_MESHNODESTATE_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshNodeState_Ensure")
  END SUBROUTINE MeshNodeState_Ensure

END MODULE MD_Mesh_Node
