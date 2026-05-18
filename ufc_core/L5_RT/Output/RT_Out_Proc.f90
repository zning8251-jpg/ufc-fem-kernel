!======================================================================
! Module: RT_OutProc
! Layer:  L5_RT - Runtime Layer
! Domain: Output / Structured Procedure Interfaces
! Purpose: Structured IO interfaces for output operations (Principle #14).
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: ACTIVE | SIO-REFACTORED | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output (AUTHORITY: RT_Out_Def.f90)
!======================================================================
!   5. RT_Out_Finalize_Structure �?Output system cleanup
!
! Design Principles:
!   1. Structured Input/Output: All arguments use derived types
!   2. Intent Clarity: Explicit INTENT(IN/INOUT/OUT) for all fields
!   3. Error Propagation: ErrorStatusType returned in output structures
!   4. Thin Adapter: L5_RT routes to L2_NM writers (HDF5/ODB/VTK)
!
! Layer Dependency:
!   USE IF_Prec              (wp, i4)
!   USE IF_Err_Brg           (ErrorStatusType)
!   USE RT_Out_Def         (Runtime output types)
!   USE MD_Out_Def      (L3_MD output requests)
!===============================================================================
MODULE RT_Out_Proc
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_ERROR
  USE RT_Out_Def, ONLY: RT_Out_Desc, RT_Out_FieldState, &
                          RT_Out_HistState, RT_Out, RT_Out_Ctx, &
                          RT_Out_Frame, RT_Out_Buffer
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Out_Init_In
  PUBLIC :: RT_Out_Init_Out
  PUBLIC :: RT_Out_Collect_In
  PUBLIC :: RT_Out_Collect_Out
  PUBLIC :: RT_Out_Write_In
  PUBLIC :: RT_Out_Write_Out
  PUBLIC :: RT_Out_CheckFreq_In
  PUBLIC :: RT_Out_CheckFreq_Out
  PUBLIC :: RT_Out_Finalize_In
  PUBLIC :: RT_Out_Finalize_Out
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Init_In �?Input Structure for Output System Initialization
  ! NOTE: Members MUST NOT have INTENT. desc/algo are separate parameters.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_Init_In
    ! Output descriptor (passed separately per six-parameter rule)
    ! TYPE(RT_Out_Desc), POINTER :: desc => NULL()
    
    ! Algorithm parameters (passed separately per six-parameter rule)
    ! TYPE(RT_Out), POINTER :: algo => NULL()
    
    ! Mesh information
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_dofs = 0_i4
    
    ! Options
    LOGICAL :: validate_requests = .TRUE.
    LOGICAL :: preallocate_buffers = .TRUE.
    
    ! Parallel context
    INTEGER(i4) :: n_threads = 1_i4
    INTEGER(i4) :: comm_rank = 0_i4
    INTEGER(i4) :: comm_size = 1_i4
  END TYPE RT_Out_Init_In
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Init_Out �?Output Structure for Output System Initialization
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_Init_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Diagnostics
    LOGICAL :: initialized = .FALSE.
    CHARACTER(LEN=256) :: message = ''
    INTEGER(i4) :: n_field_requests = 0_i4
    INTEGER(i4) :: n_hist_requests = 0_i4
    INTEGER(i4) :: buffer_memory_mb = 0_i4
  END TYPE RT_Out_Init_Out
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Collect_In �?Input Structure for Data Collection
  ! NOTE: frame/ctx are separate parameters (six-parameter rule).
  !       Use POINTER for arrays; no INTENT on members.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_Collect_In
    ! Output frame (modified in-place; passed separately)
    ! TYPE(RT_Out_Frame), POINTER :: frame => NULL()
    
    ! Context (passed separately)
    ! TYPE(RT_Out_Ctx), POINTER :: ctx => NULL()
    
    ! Solver state references (NON_OWNING_PTR)
    REAL(wp), POINTER :: node_coords(:,:) => NULL()   ! [3, n_nodes]
    REAL(wp), POINTER :: node_displ(:,:) => NULL()    ! [3, n_nodes]
    REAL(wp), POINTER :: node_velocity(:,:) => NULL() ! [3, n_nodes]
    REAL(wp), POINTER :: elem_stress(:,:) => NULL()   ! [6, n_elems]
    REAL(wp), POINTER :: elem_strain(:,:) => NULL()   ! [6, n_elems]
    INTEGER(i4), POINTER :: elem_conn(:,:) => NULL()  ! Connectivity
    
    ! Options
    LOGICAL :: collect_nodal = .TRUE.
    LOGICAL :: collect_elemental = .TRUE.
    LOGICAL :: collect_reactions = .FALSE.
  END TYPE RT_Out_Collect_In
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Collect_Out �?Output Structure for Data Collection
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_Collect_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Collection statistics
    INTEGER(i4) :: n_nodes_collected = 0_i4
    INTEGER(i4) :: n_elements_collected = 0_i4
    INTEGER(i4) :: n_variables_collected = 0_i4
    LOGICAL :: collection_complete = .FALSE.
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Out_Collect_Out
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Write_In �?Input Structure for Output Write
  ! NOTE: field_state/hist_state/frame/ctx/desc/algo are separate parameters.
  !       No INTENT on any member.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_Write_In
    ! Output state (modified in-place; passed separately)
    ! TYPE(RT_Out_FieldState), POINTER :: field_state => NULL()
    ! TYPE(RT_Out_HistState), POINTER :: hist_state => NULL()
    
    ! Output frame (passed separately)
    ! TYPE(RT_Out_Frame), POINTER :: frame => NULL()
    
    ! Context (passed separately)
    ! TYPE(RT_Out_Ctx), POINTER :: ctx => NULL()
    
    ! Descriptor (passed separately)
    ! TYPE(RT_Out_Desc), POINTER :: desc => NULL()
    
    ! Algorithm (passed separately)
    ! TYPE(RT_Out), POINTER :: algo => NULL()
    
    ! Options
    LOGICAL :: write_field = .TRUE.
    LOGICAL :: write_history = .FALSE.
    LOGICAL :: flush_buffer = .TRUE.
    
    ! File handles (if using external writers)
    INTEGER(i4) :: hdf5_file_id = -1_i4
    INTEGER(i4) :: odb_file_id = -1_i4
  END TYPE RT_Out_Write_In
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Write_Out �?Output Structure for Output Write
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_Write_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Write statistics
    INTEGER(i4) :: n_frames_written = 0_i4
    INTEGER(i4) :: n_points_written = 0_i4
    INTEGER(i4) :: bytes_written = 0_i4
    REAL(wp) :: io_time_sec = 0.0_wp
    
    ! Diagnostics
    LOGICAL :: write_successful = .FALSE.
    CHARACTER(LEN=256) :: message = ''
    CHARACTER(LEN=256) :: output_file_path = ''
  END TYPE RT_Out_Write_Out
  
  !-----------------------------------------------------------------------------
  ! RT_Out_CheckFreq_In �?Input Structure for Frequency Check
  ! NOTE: field_state/hist_state/algo/ctx are separate parameters.
  !       No INTENT on any member.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_CheckFreq_In
    ! State (modified in-place; passed separately)
    ! TYPE(RT_Out_FieldState), POINTER :: field_state => NULL()
    ! TYPE(RT_Out_HistState), POINTER :: hist_state => NULL()
    
    ! Algorithm (passed separately)
    ! TYPE(RT_Out), POINTER :: algo => NULL()
    
    ! Context (passed separately)
    ! TYPE(RT_Out_Ctx), POINTER :: ctx => NULL()
    
    ! Force flags
    LOGICAL :: force_field = .FALSE.
    LOGICAL :: force_hist = .FALSE.
  END TYPE RT_Out_CheckFreq_In
  
  !-----------------------------------------------------------------------------
  ! RT_Out_CheckFreq_Out �?Output Structure for Frequency Check
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_CheckFreq_Out
    ! Trigger results
    LOGICAL :: should_write_field = .FALSE.
    LOGICAL :: should_write_hist = .FALSE.
    
    ! Reason codes
    INTEGER(i4) :: field_trigger_reason = 0_i4  ! 0=None, 1=Incr, 2=Time, 3=StepEnd
    INTEGER(i4) :: hist_trigger_reason = 0_i4
    
    ! Next trigger prediction
    INTEGER(i4) :: next_field_incr = 0_i4
    REAL(wp) :: next_field_time = 0.0_wp
    INTEGER(i4) :: next_hist_incr = 0_i4
    REAL(wp) :: next_hist_time = 0.0_wp
    
    ! Status
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Out_CheckFreq_Out
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Finalize_In �?Input Structure for Output Finalization
  ! NOTE: field_state/hist_state/desc/algo are separate parameters.
  !       No INTENT on any member.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_Finalize_In
    ! State (modified in-place; passed separately)
    ! TYPE(RT_Out_FieldState), POINTER :: field_state => NULL()
    ! TYPE(RT_Out_HistState), POINTER :: hist_state => NULL()
    
    ! Descriptor (passed separately)
    ! TYPE(RT_Out_Desc), POINTER :: desc => NULL()
    
    ! Algorithm (passed separately)
    ! TYPE(RT_Out), POINTER :: algo => NULL()
    
    ! Options
    LOGICAL :: close_files = .TRUE.
    LOGICAL :: flush_buffers = .TRUE.
    LOGICAL :: write_summary = .TRUE.
  END TYPE RT_Out_Finalize_In
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Finalize_Out �?Output Structure for Output Finalization
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_Finalize_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Summary statistics
    INTEGER(i4) :: total_frames_written = 0_i4
    INTEGER(i4) :: total_points_written = 0_i4
    INTEGER(i4) :: total_bytes_written = 0_i4
    REAL(wp) :: total_io_time_sec = 0.0_wp
    
    ! Diagnostics
    LOGICAL :: finalized = .FALSE.
    CHARACTER(LEN=256) :: summary_message = ''
    CHARACTER(LEN=256) :: final_output_path = ''
  END TYPE RT_Out_Finalize_Out
  
  !-----------------------------------------------------------------------------
  ! Abstract Interfaces for Output Operations
  !-----------------------------------------------------------------------------
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Out_Init(input, output)
      IMPORT :: RT_Out_Init_In, RT_Out_Init_Out
      TYPE(RT_Out_Init_In), INTENT(INOUT) :: input
      TYPE(RT_Out_Init_Out), INTENT(OUT) :: output
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Out_Collect(input, output)
      IMPORT :: RT_Out_Collect_In, RT_Out_Collect_Out
      TYPE(RT_Out_Collect_In), INTENT(INOUT) :: input
      TYPE(RT_Out_Collect_Out), INTENT(OUT) :: output
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Out_Write(input, output)
      IMPORT :: RT_Out_Write_In, RT_Out_Write_Out
      TYPE(RT_Out_Write_In), INTENT(INOUT) :: input
      TYPE(RT_Out_Write_Out), INTENT(OUT) :: output
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Out_CheckFreq(input, output)
      IMPORT :: RT_Out_CheckFreq_In, RT_Out_CheckFreq_Out
      TYPE(RT_Out_CheckFreq_In), INTENT(INOUT) :: input
      TYPE(RT_Out_CheckFreq_Out), INTENT(OUT) :: output
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Out_Finalize(input, output)
      IMPORT :: RT_Out_Finalize_In, RT_Out_Finalize_Out
      TYPE(RT_Out_Finalize_In), INTENT(INOUT) :: input
      TYPE(RT_Out_Finalize_Out), INTENT(OUT) :: output
    END SUBROUTINE
  END INTERFACE
  
END MODULE RT_Out_Proc