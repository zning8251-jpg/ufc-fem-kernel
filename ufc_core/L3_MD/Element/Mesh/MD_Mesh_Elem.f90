!===============================================================================
! MODULE:  MD_Mesh_Elem
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Impl
! BRIEF:   Mesh element descriptor, state, and integration point state types
!          (Desc element topology).
!===============================================================================
MODULE MD_Mesh_Elem
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md
!> Status: CORE | Last verified: 2026-03-05
!> Theory: IP state ? ??^6, ? ??^6, element state K_e ??^(ndof ndof), R_e ??^ndof, element descriptor conn ??^max_nodes
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, IF_DATA_TYPE_INT, IF_DATA_TYPE_DP
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, only: wp, i4
  USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, StateBase, StateBase_Init, CAT_DESC, CAT_STATE
  USE IF_Err_Brg, ONLY: uf_set_error
  implicit none
  private

  ! IPState: moved from MD_Elem_Algo to break cycle (used by MeshElemState%ipStates)
  ! Extended with damage, stateV for compatibility with FillPredef/StructIntegrateIp (RT_Contm_Struct_Mat)
  TYPE, PUBLIC, EXTENDS(StateBase) :: IPState
    INTEGER(i4) :: ipId = 0_i4
    INTEGER(i4) :: id = 0_i4
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: plasticStrain(6) = 0.0_wp
    REAL(wp) :: equivalentplast = 0.0_wp
    REAL(wp) :: temp = 0.0_wp                    ! Temperature T  ? ?(alias for temperature)
    REAL(wp) :: temperature = 0.0_wp            ! Temperature T  ? ?    REAL(wp) :: jacobian = 1.0_wp
    REAL(wp) :: damage = 0.0_wp
    REAL(wp), ALLOCATABLE :: stateV(:)
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => IPState_RegLayout
    PROCEDURE, PUBLIC :: Ensure => IPState_Ensure
    PROCEDURE, PUBLIC :: Init => IPState_Init
  END TYPE IPState

  TYPE, PUBLIC, EXTENDS(DescBase) :: MeshElemDesc
    INTEGER(i4) :: id = 0_i4
    INTEGER(i4) :: typeId = 0_i4
    INTEGER(i4) :: nodes(8) = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MeshElemDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MeshElemDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MeshElemDesc_Init
  END TYPE MeshElemDesc

  TYPE, PUBLIC, EXTENDS(StateBase) :: MeshElemState
    INTEGER(i4) :: id = 0_i4
    INTEGER(i4) :: nIntPoints = 0_i4
    INTEGER(i4) :: elemStatus = 0_i4
    LOGICAL :: isActive = .true.
    LOGICAL :: failed = .false.
    REAL(wp) :: stableDt = 0.0_wp
    REAL(wp) :: rhs_norm = 0.0_wp
    REAL(wp) :: int_energy = 0.0_wp
    REAL(wp) :: volume = 0.0_wp
    REAL(wp) :: mass = 0.0_wp
    REAL(wp) :: strainEnergy = 0.0_wp
    REAL(wp) :: kineticEnergy = 0.0_wp
    REAL(wp), ALLOCATABLE :: Ke(:,:)
    REAL(wp), ALLOCATABLE :: Re(:)
    REAL(wp), ALLOCATABLE :: Me(:,:)
    REAL(wp), ALLOCATABLE :: Ce(:,:)
    TYPE(IPState), ALLOCATABLE :: ipStates(:)
    REAL(wp), ALLOCATABLE :: ipFields(:,:)
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MeshElemState_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MeshElemState_Ensure
    PROCEDURE, PUBLIC :: Init => MeshElemState_Init
  END TYPE MeshElemState

contains

  SUBROUTINE IPState_Init(this, n)
    CLASS(IPState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: n
    CALL StateBase_Init(this, n)
    this%algo_category = CAT_STATE
    IF (PRESENT(n)) this%ipId = n
  END SUBROUTINE IPState_Init

  SUBROUTINE IPState_RegLayout(this)
    CLASS(IPState), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(8)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'ipId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'id'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'sigma'
    fields(3)%data_type = IF_DATA_TYPE_DP
    fields(3)%rank = 1
    fields(3)%dims(1) = 6
    fields(3)%offset_bytes = offset
    offset = offset + 48
    fields(4)%field_name = 'strain'
    fields(4)%data_type = IF_DATA_TYPE_DP
    fields(4)%rank = 1
    fields(4)%dims(1) = 6
    fields(4)%offset_bytes = offset
    offset = offset + 48
    fields(5)%field_name = 'plasticStrain'
    fields(5)%data_type = IF_DATA_TYPE_DP
    fields(5)%rank = 1
    fields(5)%dims(1) = 6
    fields(5)%offset_bytes = offset
    offset = offset + 48
    fields(6)%field_name = 'equivalentplast'
    fields(6)%data_type = IF_DATA_TYPE_DP
    fields(6)%offset_bytes = offset
    offset = offset + 8
    fields(7)%field_name = 'temperature'
    fields(7)%data_type = IF_DATA_TYPE_DP
    fields(7)%offset_bytes = offset
    offset = offset + 8
    fields(8)%field_name = 'jacobian'
    fields(8)%data_type = IF_DATA_TYPE_DP
    fields(8)%offset_bytes = offset
    offset = offset + 8
    CALL dp_register_struct_type(TRIM(this%TypeName()), fields, 8, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "IPState_RegLayout")
  END SUBROUTINE IPState_RegLayout

  SUBROUTINE IPState_Ensure(this)
    CLASS(IPState), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CHARACTER(len=64) :: vn
    CALL init_error_status(status)
    IF (LEN_TRIM(this%VarName()) == 0) THEN
      WRITE(vn, '(A,I0)') 'UF_IPSTATE_', this%ipId
      CALL this%SetVarName(TRIM(vn))
    END IF
    CALL dp_create_struct_array(TRIM(this%VarName()), [1,0,0,0], TRIM(this%TypeName()), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "IPState_Ensure")
  END SUBROUTINE IPState_Ensure

  SUBROUTINE MeshElemDesc_Init(this)
    CLASS(MeshElemDesc), INTENT(INOUT) :: this
    CALL DescBase_Init(this)
    CALL this%SetTypeName('DESC::MESHELEM')
  END SUBROUTINE MeshElemDesc_Init

  SUBROUTINE MeshElemDesc_RegLayout(this)
    CLASS(MeshElemDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(3)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'typeId'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'nodes'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 32
    CALL dp_register_struct_type(TRIM(this%TypeName()), fields, 3, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshElemDesc_RegLayout")
  END SUBROUTINE MeshElemDesc_RegLayout

  SUBROUTINE MeshElemDesc_Ensure(this)
    CLASS(MeshElemDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CHARACTER(len=64) :: vn
    CALL init_error_status(status)
    IF (LEN_TRIM(this%VarName()) == 0) THEN
      WRITE(vn, '(A,I0)') 'UF_MESHELEMDESC_', this%cfg%id
      CALL this%SetVarName(TRIM(vn))
    END IF
    CALL dp_create_struct_array(TRIM(this%VarName()), [1,0,0,0], TRIM(this%TypeName()), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshElemDesc_Ensure")
  END SUBROUTINE MeshElemDesc_Ensure

  SUBROUTINE MeshElemState_Init(this, n)
    CLASS(MeshElemState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: n
    CALL StateBase_Init(this, n)
    this%algo_category = CAT_STATE
  END SUBROUTINE MeshElemState_Init

  SUBROUTINE MeshElemState_RegLayout(this)
    CLASS(MeshElemState), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(12)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'nIntPoints'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'elemStatus'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'isActive'
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%offset_bytes = offset
    offset = offset + 4
    fields(5)%field_name = 'failed'
    fields(5)%data_type = IF_DATA_TYPE_INT
    fields(5)%offset_bytes = offset
    offset = offset + 4
    fields(6)%field_name = 'stableDt'
    fields(6)%data_type = IF_DATA_TYPE_DP
    fields(6)%offset_bytes = offset
    offset = offset + 8
    fields(7)%field_name = 'rhs_norm'
    fields(7)%data_type = IF_DATA_TYPE_DP
    fields(7)%offset_bytes = offset
    offset = offset + 8
    fields(8)%field_name = 'int_energy'
    fields(8)%data_type = IF_DATA_TYPE_DP
    fields(8)%offset_bytes = offset
    offset = offset + 8
    fields(9)%field_name = 'volume'
    fields(9)%data_type = IF_DATA_TYPE_DP
    fields(9)%offset_bytes = offset
    offset = offset + 8
    fields(10)%field_name = 'mass'
    fields(10)%data_type = IF_DATA_TYPE_DP
    fields(10)%offset_bytes = offset
    offset = offset + 8
    fields(11)%field_name = 'strainEnergy'
    fields(11)%data_type = IF_DATA_TYPE_DP
    fields(11)%offset_bytes = offset
    offset = offset + 8
    fields(12)%field_name = 'kineticEnergy'
    fields(12)%data_type = IF_DATA_TYPE_DP
    fields(12)%offset_bytes = offset
    offset = offset + 8
    CALL dp_register_struct_type(TRIM(this%TypeName()), fields, 12, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshElemState_RegLayout")
  END SUBROUTINE MeshElemState_RegLayout

  SUBROUTINE MeshElemState_Ensure(this)
    CLASS(MeshElemState), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CHARACTER(len=64) :: vn
    CALL init_error_status(status)
    IF (LEN_TRIM(this%VarName()) == 0) THEN
      WRITE(vn, '(A,I0)') 'UF_MESHELEMSTATE_', this%cfg%id
      CALL this%SetVarName(TRIM(vn))
    END IF
    CALL dp_create_struct_array(TRIM(this%VarName()), [1,0,0,0], TRIM(this%TypeName()), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshElemState_Ensure")
  END SUBROUTINE MeshElemState_Ensure

END MODULE MD_Mesh_Elem
