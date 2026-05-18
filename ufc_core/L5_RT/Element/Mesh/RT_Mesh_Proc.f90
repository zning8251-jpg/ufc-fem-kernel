!===============================================================================
! MODULE: RT_Mesh_Proc
! LAYER:  L5_RT
! DOMAIN: Mesh
! ROLE:   Proc — Public procedure interfaces for mesh runtime management
! BRIEF:  Structured I/O types + interfaces for Init/Clean/Numbering/
!         UpdateCoords/GetState/Assembly (SIO Principle #14).
!===============================================================================
MODULE RT_Mesh_Proc
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE RT_Mesh_Def, ONLY: RT_Mesh_Base_Desc, RT_Mesh_Base_State, RT_Mesh_Base_Algo, RT_Mesh_Base_Ctx
  USE RT_Mesh_Def, ONLY: RT_Mesh_NodeState, RT_Mesh_ElementState
  USE RT_Mesh_Def, ONLY: RT_Mesh_NumberingAlgo, RT_Mesh_AssemblyCtx
  IMPLICIT NONE
  PRIVATE
  
  !-----------------------------------------------------------------------------
  ! Structured Input/Output Types
  !-----------------------------------------------------------------------------
  
  !-- RT_Mesh_Init
  TYPE, PUBLIC :: RT_Mesh_Init_In
    TYPE(MD_Mesh_Registry), POINTER :: md_registry => NULL()
    INTEGER(i4) :: n_partitions = 1_i4
    LOGICAL :: use_parallel = .FALSE.
    TYPE(RT_Mesh_Base_Algo), OPTIONAL :: algo_default
  END TYPE RT_Mesh_Init_In
  
  TYPE, PUBLIC :: RT_Mesh_Init_Out
    LOGICAL :: success = .FALSE.
    INTEGER(i4) :: nnodes = 0_i4
    INTEGER(i4) :: nelems = 0_i4
    INTEGER(i4) :: total_dof = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Init_Out
  
  !-- RT_Mesh_Clean
  TYPE, PUBLIC :: RT_Mesh_Clean_In
    LOGICAL :: full_cleanup = .TRUE.
    LOGICAL :: keep_numbering = .FALSE.
  END TYPE RT_Mesh_Clean_In
  
  TYPE, PUBLIC :: RT_Mesh_Clean_Out
    LOGICAL :: success = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Clean_Out
  
  !-- RT_Mesh_Numbering
  TYPE, PUBLIC :: RT_Mesh_Numbering_In
    TYPE(RT_Mesh_NumberingAlgo) :: algo
    LOGICAL :: renumber_existing = .FALSE.
  END TYPE RT_Mesh_Numbering_In
  
  TYPE, PUBLIC :: RT_Mesh_Numbering_Out
    LOGICAL :: success = .FALSE.
    INTEGER(i4) :: total_active_dof = 0_i4
    INTEGER(i4) :: max_bandwidth = 0_i4
    REAL(wp) :: fill_ratio = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Numbering_Out
  
  !-- RT_Mesh_UpdateCoords
  TYPE, PUBLIC :: RT_Mesh_UpdateCoords_In
    REAL(wp), POINTER :: displ(:,:) => NULL()      ! [nnodes, 3]
    REAL(wp), POINTER :: velocity(:,:) => NULL()   ! [nnodes, 3]
    LOGICAL :: update_velocity = .FALSE.
  END TYPE RT_Mesh_UpdateCoords_In
  
  TYPE, PUBLIC :: RT_Mesh_UpdateCoords_Out
    LOGICAL :: success = .FALSE.
    INTEGER(i4) :: updated_nodes = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_UpdateCoords_Out
  
  !-- RT_Mesh_GetState
  TYPE, PUBLIC :: RT_Mesh_GetState_In
    INTEGER(i4) :: node_id = 0_i4         ! Query specific node
    INTEGER(i4) :: elem_id = 0_i4         ! Query specific element
    CHARACTER(LEN=64) :: field_name = ' ' ! Field to query
  END TYPE RT_Mesh_GetState_In
  
  TYPE, PUBLIC :: RT_Mesh_GetState_Out
    REAL(wp), ALLOCATABLE :: values(:)    ! Queried field values
    INTEGER(i4) :: int_values(:)          ! Integer field values
    LOGICAL :: is_valid = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_GetState_Out
  
  !-- RT_Mesh_Assembly
  TYPE, PUBLIC :: RT_Mesh_Assembly_In
    TYPE(RT_Mesh_AssemblyCtx) :: ctx
    REAL(wp), POINTER :: elem_matrix(:,:) => NULL()  ! Element matrix to assemble
    REAL(wp), POINTER :: elem_vector(:) => NULL()    ! Element vector to assemble
    INTEGER(i4) :: elem_id = 0_i4                    ! Element ID
  END TYPE RT_Mesh_Assembly_In
  
  TYPE, PUBLIC :: RT_Mesh_Assembly_Out
    LOGICAL :: success = .FALSE.
    INTEGER(i4) :: assembled_entries = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Assembly_Out
  
  !-----------------------------------------------------------------------------
  ! Interface Declarations
  !-----------------------------------------------------------------------------
  
  INTERFACE RT_Mesh_Init
    MODULE PROCEDURE RT_Mesh_Init
  END INTERFACE
  
  INTERFACE RT_Mesh_Clean
    MODULE PROCEDURE RT_Mesh_Clean
  END INTERFACE
  
  INTERFACE RT_Mesh_Numbering
    MODULE PROCEDURE RT_Mesh_Numbering
  END INTERFACE
  
  INTERFACE RT_Mesh_UpdateCoords
    MODULE PROCEDURE RT_Mesh_UpdateCoords
  END INTERFACE
  
  INTERFACE RT_Mesh_GetState
    MODULE PROCEDURE RT_Mesh_GetState
  END INTERFACE
  
  INTERFACE RT_Mesh_Assembly
    MODULE PROCEDURE RT_Mesh_Assembly
  END INTERFACE
  
  !-----------------------------------------------------------------------------
  ! Public Procedures
  !-----------------------------------------------------------------------------
  
  PUBLIC :: RT_Mesh_Init
  PUBLIC :: RT_Mesh_Clean
  PUBLIC :: RT_Mesh_Numbering
  PUBLIC :: RT_Mesh_UpdateCoords
  PUBLIC :: RT_Mesh_GetState
  PUBLIC :: RT_Mesh_Assembly
  
CONTAINS
  
  !=============================================================================
  ! RT_Mesh_Init
  !=============================================================================
  SUBROUTINE RT_Mesh_Init(input, output)
    TYPE(RT_Mesh_Init_In), INTENT(IN) :: input
    TYPE(RT_Mesh_Init_Out), INTENT(OUT) :: output
    
    ! Implementation in RT_MeshImpl
    CALL RT_Mesh_Impl_Init(input, output)
  END SUBROUTINE RT_Mesh_Init
  
  !=============================================================================
  ! RT_Mesh_Clean
  !=============================================================================
  SUBROUTINE RT_Mesh_Clean(input, output)
    TYPE(RT_Mesh_Clean_In), INTENT(IN) :: input
    TYPE(RT_Mesh_Clean_Out), INTENT(OUT) :: output
    
    ! Implementation in RT_MeshImpl
    CALL RT_Mesh_Impl_Clean(input, output)
  END SUBROUTINE RT_Mesh_Clean
  
  !=============================================================================
  ! RT_Mesh_Numbering
  !=============================================================================
  SUBROUTINE RT_Mesh_Numbering(input, output)
    TYPE(RT_Mesh_Numbering_In), INTENT(INOUT) :: input
    TYPE(RT_Mesh_Numbering_Out), INTENT(OUT) :: output
    
    ! Implementation in RT_MeshImpl
    CALL RT_Mesh_Impl_Numbering(input, output)
  END SUBROUTINE RT_Mesh_Numbering
  
  !=============================================================================
  ! RT_Mesh_UpdateCoords
  !=============================================================================
  SUBROUTINE RT_Mesh_UpdateCoords(input, output)
    TYPE(RT_Mesh_UpdateCoords_In), INTENT(IN) :: input
    TYPE(RT_Mesh_UpdateCoords_Out), INTENT(OUT) :: output
    
    ! Implementation in RT_MeshImpl
    CALL RT_Mesh_Impl_UpdateCoords(input, output)
  END SUBROUTINE RT_Mesh_UpdateCoords
  
  !=============================================================================
  ! RT_Mesh_GetState
  !=============================================================================
  SUBROUTINE RT_Mesh_GetState(input, output)
    TYPE(RT_Mesh_GetState_In), INTENT(IN) :: input
    TYPE(RT_Mesh_GetState_Out), INTENT(OUT) :: output
    
    ! Implementation in RT_MeshImpl
    CALL RT_Mesh_Impl_GetState(input, output)
  END SUBROUTINE RT_Mesh_GetState
  
  !=============================================================================
  ! RT_Mesh_Assembly
  !=============================================================================
  SUBROUTINE RT_Mesh_Assembly(input, output)
    TYPE(RT_Mesh_Assembly_In), INTENT(INOUT) :: input
    TYPE(RT_Mesh_Assembly_Out), INTENT(OUT) :: output
    
    ! Implementation in RT_MeshImpl
    CALL RT_Mesh_Impl_Assembly(input, output)
  END SUBROUTINE RT_Mesh_Assembly
  
END MODULE RT_Mesh_Proc