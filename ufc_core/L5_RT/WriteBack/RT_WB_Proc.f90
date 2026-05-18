!===============================================================================
! MODULE: RT_WB_Proc
! LAYER:  L5_RT
! DOMAIN: WriteBack
! ROLE:   Proc — structured IO interfaces
! BRIEF:  SIO *_Arg types + 5-param (desc,state,algo,ctx,args) abstract interfaces.
!         Principle #14: unified Arg, no _In/_Out pair, 5-param signature.
!===============================================================================
MODULE RT_WB_Proc
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE RT_WB_Def, ONLY: RT_WB_Desc, RT_WB_State, RT_WB_Algo, RT_WB_Ctx
  IMPLICIT NONE
  PRIVATE

  !-- Unified Arg types (one per operation)
  PUBLIC :: RT_WB_Init_Arg
  PUBLIC :: RT_WB_NodePos_Arg
  PUBLIC :: RT_WB_NodeDisp_Arg
  PUBLIC :: RT_WB_ElemStress_Arg
  PUBLIC :: RT_WB_Checkpoint_Arg
  PUBLIC :: RT_WB_Write_Arg

  !-- Abstract interfaces (5-param: desc,state,algo,ctx,args)
  PUBLIC :: RT_WB_Init_Interface
  PUBLIC :: RT_WB_NodePos_Interface
  PUBLIC :: RT_WB_NodeDisp_Interface
  PUBLIC :: RT_WB_ElemStress_Interface
  PUBLIC :: RT_WB_Checkpoint_Interface

  !-----------------------------------------------------------------------------
  ! RT_WB_Init_Arg — WriteBack initialization
  !   [IN]: system dimensions + options
  !   [OUT]: initialization result + diagnostics
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_Init_Arg
    !-- [IN]
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_total_dofs = 0_i4
    LOGICAL :: preallocate_buffers = .TRUE.
    LOGICAL :: enable_checkpointing = .FALSE.
    INTEGER(i4) :: max_checkpoints = 10_i4
    INTEGER(i4) :: n_threads = 1_i4
    INTEGER(i4) :: comm_rank = 0_i4
    INTEGER(i4) :: comm_size = 1_i4
    !-- [OUT]
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: buffer_memory_mb = 0_i4
    INTEGER(i4) :: checkpoint_slots_allocated = 0_i4
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_Init_Arg

  !-----------------------------------------------------------------------------
  ! RT_WB_NodePos_Arg — Node position write-back
  !   [IN]: node identification + new coordinates
  !   [OUT]: old coords (if requested) + write status
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_NodePos_Arg
    !-- [IN]
    INTEGER(i4) :: node_id = 0_i4
    INTEGER(i4) :: node_idx = 0_i4
    REAL(wp) :: new_coords(3)
    LOGICAL :: return_old_coords = .TRUE.
    LOGICAL :: validate_before_write = .TRUE.
    !-- [OUT]
    REAL(wp) :: old_coords(3) = 0.0_wp
    LOGICAL :: write_successful = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_NodePos_Arg

  !-----------------------------------------------------------------------------
  ! RT_WB_NodeDisp_Arg — Node displacement write-back
  !   [IN]: node identification + new displacement
  !   [OUT]: old displacement (if requested) + write status
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_NodeDisp_Arg
    !-- [IN]
    INTEGER(i4) :: node_id = 0_i4
    INTEGER(i4) :: node_idx = 0_i4
    REAL(wp) :: new_disp(3)
    LOGICAL :: return_old_disp = .TRUE.
    LOGICAL :: use_batch_mode = .FALSE.
    !-- [OUT]
    REAL(wp) :: old_disp(3) = 0.0_wp
    LOGICAL :: write_successful = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_NodeDisp_Arg

  !-----------------------------------------------------------------------------
  ! RT_WB_ElemStress_Arg — Element stress write-back
  !   [IN]: element/Gauss-point identification + stress tensor (Voigt)
  !   [OUT]: principal stresses / von Mises (if computed) + write status
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_ElemStress_Arg
    !-- [IN]
    INTEGER(i4) :: elem_id = 0_i4
    INTEGER(i4) :: elem_idx = 0_i4
    INTEGER(i4) :: gp_id = 0_i4
    REAL(wp) :: stress(6) = 0.0_wp
    LOGICAL :: compute_principal = .FALSE.
    LOGICAL :: use_buffering = .TRUE.
    !-- [OUT]
    REAL(wp) :: principal_stress(3) = 0.0_wp
    REAL(wp) :: von_mises = 0.0_wp
    LOGICAL :: write_successful = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_ElemStress_Arg

  !-----------------------------------------------------------------------------
  ! RT_WB_Checkpoint_Arg — Checkpoint save/load/rollback
  !   [IN]: step/increment/iteration metadata + operation type
  !   [OUT]: checkpoint ID / loaded state + validation + status
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_Checkpoint_Arg
    !-- [IN]
    INTEGER(i4) :: step_id = 0_i4
    INTEGER(i4) :: increment_id = 0_i4
    INTEGER(i4) :: iteration_id = 0_i4
    REAL(wp) :: time_val = 0.0_wp
    INTEGER(i4) :: operation = 0_i4    ! 0=Save, 1=Load, 2=Rollback
    CHARACTER(LEN=256) :: file_path = ''
    LOGICAL :: compute_checksum = .FALSE.
    LOGICAL :: compress_data = .FALSE.
    !-- [OUT]
    INTEGER(i4) :: checkpoint_id = 0_i4
    INTEGER(i4) :: loaded_step = 0_i4
    INTEGER(i4) :: loaded_increment = 0_i4
    REAL(wp) :: loaded_time = 0.0_wp
    REAL(wp) :: checksum = 0.0_wp
    LOGICAL :: checksum_valid = .FALSE.
    LOGICAL :: operation_successful = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_Checkpoint_Arg

  !-----------------------------------------------------------------------------
  ! RT_WB_Write_Arg — Bulk write-back (multiple nodes/elements in one call)
  !   [IN]: domain data arrays + dimensions
  !   [OUT]: byte count + status
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_Write_Arg
    !-- [IN]
    REAL(wp), ALLOCATABLE :: node_pos(:,:)
    REAL(wp), ALLOCATABLE :: node_disp(:,:)
    REAL(wp), ALLOCATABLE :: elem_stress(:,:)
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elems = 0_i4
    !-- [OUT]
    INTEGER(i4) :: bytes_written = 0_i4
    INTEGER(i4) :: status_code = 0_i4
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_Write_Arg

  !-----------------------------------------------------------------------------
  ! Abstract Interfaces — 5-param: (desc, state, algo, ctx, args)
  !-----------------------------------------------------------------------------
  ABSTRACT INTERFACE
    SUBROUTINE RT_WB_Init_Interface(desc, state, algo, ctx, args)
      IMPORT :: RT_WB_Desc, RT_WB_State, RT_WB_Algo, RT_WB_Ctx, RT_WB_Init_Arg
      TYPE(RT_WB_Desc),        INTENT(INOUT) :: desc
      TYPE(RT_WB_State),       INTENT(INOUT) :: state
      TYPE(RT_WB_Algo),        INTENT(IN)    :: algo
      TYPE(RT_WB_Ctx),         INTENT(INOUT) :: ctx
      TYPE(RT_WB_Init_Arg),    INTENT(INOUT) :: args
    END SUBROUTINE
  END INTERFACE

  ABSTRACT INTERFACE
    SUBROUTINE RT_WB_NodePos_Interface(desc, state, algo, ctx, args)
      IMPORT :: RT_WB_Desc, RT_WB_State, RT_WB_Algo, RT_WB_Ctx, RT_WB_NodePos_Arg
      TYPE(RT_WB_Desc),        INTENT(INOUT) :: desc
      TYPE(RT_WB_State),       INTENT(INOUT) :: state
      TYPE(RT_WB_Algo),        INTENT(IN)    :: algo
      TYPE(RT_WB_Ctx),         INTENT(INOUT) :: ctx
      TYPE(RT_WB_NodePos_Arg), INTENT(INOUT) :: args
    END SUBROUTINE
  END INTERFACE

  ABSTRACT INTERFACE
    SUBROUTINE RT_WB_NodeDisp_Interface(desc, state, algo, ctx, args)
      IMPORT :: RT_WB_Desc, RT_WB_State, RT_WB_Algo, RT_WB_Ctx, RT_WB_NodeDisp_Arg
      TYPE(RT_WB_Desc),          INTENT(INOUT) :: desc
      TYPE(RT_WB_State),         INTENT(INOUT) :: state
      TYPE(RT_WB_Algo),          INTENT(IN)    :: algo
      TYPE(RT_WB_Ctx),           INTENT(INOUT) :: ctx
      TYPE(RT_WB_NodeDisp_Arg),  INTENT(INOUT) :: args
    END SUBROUTINE
  END INTERFACE

  ABSTRACT INTERFACE
    SUBROUTINE RT_WB_ElemStress_Interface(desc, state, algo, ctx, args)
      IMPORT :: RT_WB_Desc, RT_WB_State, RT_WB_Algo, RT_WB_Ctx, RT_WB_ElemStress_Arg
      TYPE(RT_WB_Desc),            INTENT(INOUT) :: desc
      TYPE(RT_WB_State),           INTENT(INOUT) :: state
      TYPE(RT_WB_Algo),            INTENT(IN)    :: algo
      TYPE(RT_WB_Ctx),             INTENT(INOUT) :: ctx
      TYPE(RT_WB_ElemStress_Arg),  INTENT(INOUT) :: args
    END SUBROUTINE
  END INTERFACE

  ABSTRACT INTERFACE
    SUBROUTINE RT_WB_Checkpoint_Interface(desc, state, algo, ctx, args)
      IMPORT :: RT_WB_Desc, RT_WB_State, RT_WB_Algo, RT_WB_Ctx, RT_WB_Checkpoint_Arg
      TYPE(RT_WB_Desc),             INTENT(INOUT) :: desc
      TYPE(RT_WB_State),            INTENT(INOUT) :: state
      TYPE(RT_WB_Algo),             INTENT(IN)    :: algo
      TYPE(RT_WB_Ctx),              INTENT(INOUT) :: ctx
      TYPE(RT_WB_Checkpoint_Arg),   INTENT(INOUT) :: args
    END SUBROUTINE
  END INTERFACE

END MODULE RT_WB_Proc
