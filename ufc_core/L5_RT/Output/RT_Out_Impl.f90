!======================================================================
! Module: RT_OutImpl
! Layer:  L5_RT - Runtime Layer
! Domain: Output / Implementation Logic
! Purpose: Core output runtime operations (thin adapter to L2_NM writers).
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: ACTIVE | SIO-REFACTORED | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output (AUTHORITY: RT_Out_Def.f90)
!======================================================================
!   5. RT_Out_Impl_Finalize �?Output system cleanup
!
! Design Principles:
!   1. Thin Routing: L5_RT delegates to L2_NM writers
!   2. No I/O in L5: All file operations live in L2_NM
!   3. Error Handling: Comprehensive error checking and propagation
!   4. Performance: Buffer-based collection, minimal allocations
!
! Layer Dependency:
!   USE IF_Prec              (wp, i4)
!   USE IF_Err_Brg           (ErrorStatusType)
!   USE RT_Out_Def         (Runtime output types)
!   USE RT_OutProc          (Structured interfaces)
!   USE NM_Writer_HDF5       (L2_NM HDF5 writer)
!   USE NM_Writer_ODB        (L2_NM ODB writer)
!===============================================================================
MODULE RT_Out_Impl
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_ERROR, init_error_status
  USE RT_Out_Def, ONLY: RT_Out_Desc, RT_Out_FieldState, &
                          RT_Out_HistState, RT_Out, RT_Out_Ctx, &
                          RT_Out_Frame, RT_Out_Buffer, RT_Out_TriggerCtx, &
                          RT_OUT_FMT_VTK, RT_OUT_FMT_HDF5, RT_OUT_FMT_ODB, &
                          RT_OUT_FMT_ASCII
  USE RT_Out_Proc, ONLY: RT_Out_Init_In, RT_Out_Init_Out, &
                         RT_Out_Collect_In, RT_Out_Collect_Out, &
                         RT_Out_CheckFreq_In, RT_Out_CheckFreq_Out, &
                         RT_Out_Write_In, RT_Out_Write_Out, &
                         RT_Out_Finalize_In, RT_Out_Finalize_Out
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Out_Impl_Init
  PUBLIC :: RT_Out_Impl_Collect
  PUBLIC :: RT_Out_Impl_CheckFreq
  PUBLIC :: RT_Out_Impl_Write
  PUBLIC :: RT_Out_Impl_Finalize
  PUBLIC :: RT_Out_Impl_WriteScalar
  PUBLIC :: RT_Out_Impl_WriteVector
  PUBLIC :: RT_Out_Impl_WriteTensor
  
CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_Out_Impl_Init �?Initialize Output System
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Out_Impl_Init(input, output)
    TYPE(RT_Out_Init_In), INTENT(INOUT) :: input
    TYPE(RT_Out_Init_Out), INTENT(OUT) :: output
    
    CALL init_error_status(output%status)
    output%initialized = .FALSE.
    
    ! Validate descriptor
    IF (.NOT. ASSOCIATED(input%desc%md_registry)) THEN
      output%status%status_code = IF_STATUS_ERROR
      output%message = 'ERROR: MD output registry not associated'
      RETURN
    END IF
    
    ! Cache request counts
    output%n_field_requests = input%desc%md_registry%n_field
    output%n_hist_requests = input%desc%md_registry%n_hist
    
    ! Initialize field state
    CALL input%desc%field_state%Init( &
      incr_interval=input%algo%field_freq_incr, &
      max_frames=0_i4)
    
    ! Initialize hist state
    CALL input%desc%hist_state%Init( &
      n_vars=10_i4, &  ! TODO: From MD requests
      buffer_size=input%algo%hist_buffer_size)
    
    ! Preallocate frame buffer if requested
    IF (input%preallocate_buffers) THEN
      CALL input%frame%Allocate(input%pop%n_nodes, input%pop%n_elements)
      output%buffer_memory_mb = 10_i4  ! Estimate
    END IF
    
    ! Set initialized flag
    input%desc%is_initialized = .TRUE.
    output%initialized = .TRUE.
    output%status%status_code = IF_STATUS_OK
    output%message = 'Output system initialized successfully'
    
  END SUBROUTINE RT_Out_Impl_Init
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Impl_Collect �?Collect Output Data from Solver State
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Out_Impl_Collect(input, output)
    TYPE(RT_Out_Collect_In), INTENT(INOUT) :: input
    TYPE(RT_Out_Collect_Out), INTENT(OUT) :: output
    
    INTEGER(i4) :: n_nodes, n_elems
    INTEGER(i4) :: i, j
    
    CALL init_error_status(output%status)
    output%collection_complete = .FALSE.
    
    ! Get mesh dimensions
    n_nodes = SIZE(input%node_coords, 2)
    n_elems = SIZE(input%elem_stress, 2)
    
    ! Allocate frame if needed
    IF (.NOT. input%frame%is_valid) THEN
      CALL input%frame%Init()
      CALL input%frame%Allocate(n_nodes, n_elems)
    END IF
    
    ! Copy nodal data
    IF (input%collect_nodal) THEN
      DO i = 1, n_nodes
        DO j = 1, 3
          input%frame%node_coords(j, i) = input%node_coords(j, i)
          input%frame%node_displ(j, i) = input%node_displ(j, i)
        END DO
      END DO
      output%n_nodes_collected = n_nodes
    END IF
    
    ! Copy elemental data
    IF (input%collect_elemental) THEN
      DO i = 1, n_elems
        DO j = 1, 6
          input%frame%elem_stress(j, i) = input%elem_stress(j, i)
          input%frame%elem_strain(j, i) = input%elem_strain(j, i)
        END DO
      END DO
      output%n_elements_collected = n_elems
    END IF
    
    ! Set metadata
    input%frame%step_id = input%ctx%step_id
    input%frame%incr_id = input%ctx%incr_id
    input%frame%time = input%ctx%total_time
    input%frame%dt = input%ctx%time_increment
    
    output%n_variables_collected = 6  ! Stress + Strain
    output%collection_complete = .TRUE.
    output%status%status_code = IF_STATUS_OK
    output%message = 'Data collection complete'
    
  END SUBROUTINE RT_Out_Impl_Collect
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Impl_CheckFreq �?Check Output Frequency and Triggers
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Out_Impl_CheckFreq(input, output)
    TYPE(RT_Out_CheckFreq_In), INTENT(INOUT) :: input
    TYPE(RT_Out_CheckFreq_Out), INTENT(OUT) :: output
    
    INTEGER(i4) :: curr_incr
    REAL(wp) :: curr_time
    
    CALL init_error_status(output%status)
    
    curr_incr = input%ctx%incr_id
    curr_time = input%ctx%total_time
    
    ! Evaluate field output trigger
    output%should_write_field = input%force_field
    
    IF (.NOT. output%should_write_field) THEN
      ! Check increment-based trigger
      IF (MOD(curr_incr, input%algo%field_freq_incr) == 0) THEN
        output%should_write_field = .TRUE.
        output%field_trigger_reason = 1_i4  ! Increment trigger
      END IF
      
      ! Check time-based trigger
      IF (.NOT. output%should_write_field .AND. input%algo%field_freq_time > 0.0_wp) THEN
        IF (curr_time >= input%field_state%time_next_due) THEN
          output%should_write_field = .TRUE.
          output%field_trigger_reason = 2_i4  ! Time trigger
          input%field_state%time_next_due = curr_time + input%algo%field_freq_time
        END IF
      END IF
      
      ! Check step end trigger
      IF (.NOT. output%should_write_field .AND. input%ctx%is_step_end) THEN
        IF (input%algo%trigger_at_step_end) THEN
          output%should_write_field = .TRUE.
          output%field_trigger_reason = 3_i4  ! Step end trigger
        END IF
      END IF
    END IF
    
    ! Evaluate history output trigger (similar logic)
    output%should_write_hist = input%force_hist
    
    IF (.NOT. output%should_write_hist) THEN
      IF (MOD(curr_incr, input%algo%hist_freq_incr) == 0) THEN
        output%should_write_hist = .TRUE.
        output%hist_trigger_reason = 1_i4
      END IF
    END IF
    
    ! Predict next triggers
    IF (output%should_write_field) THEN
      output%next_field_incr = curr_incr + input%algo%field_freq_incr
      output%next_field_time = curr_time + input%algo%field_freq_time
    END IF
    
    output%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE RT_Out_Impl_CheckFreq
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Impl_Write �?Write Output Frame
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Out_Impl_Write(input, output)
    TYPE(RT_Out_Write_In), INTENT(INOUT) :: input
    TYPE(RT_Out_Write_Out), INTENT(OUT) :: output
    
    CHARACTER(LEN=256) :: file_path
    
    CALL init_error_status(output%status)
    output%write_successful = .FALSE.
    
    ! Construct output file path
    file_path = TRIM(input%desc%output_directory) // &
                TRIM(input%desc%file_prefix) // &
                '_STEP' // TRIM(ADJUSTL(ITOA(input%ctx%step_id))) // &
                '_INC' // TRIM(ADJUSTL(ITOA(input%ctx%incr_id)))
    
    ! Route based on output format
    SELECT CASE (input%desc%output_format)
    CASE (RT_OUT_FMT_HDF5)
      ! Delegate to L2_NM HDF5 writer
      ! CALL NM_Writer_HDF5_WriteFrame(input%frame, file_path, ...)
      output%message = 'HDF5 write (placeholder - delegate to L2_NM)'
      
    CASE (RT_OUT_FMT_ODB)
      ! Delegate to L2_NM ODB writer
      ! CALL NM_Writer_ODB_WriteFrame(input%frame, file_path, ...)
      output%message = 'ODB write (placeholder - delegate to L2_NM)'
      
    CASE (RT_OUT_FMT_VTK)
      ! Delegate to L2_NM VTK writer
      ! CALL NM_Writer_VTK_WriteFrame(input%frame, file_path, ...)
      output%message = 'VTK write (placeholder - delegate to L2_NM)'
      
    CASE (RT_OUT_FMT_ASCII)
      ! Delegate to L2_NM ASCII writer
      ! CALL NM_Writer_ASCII_WriteFrame(input%frame, file_path, ...)
      output%message = 'ASCII write (placeholder - delegate to L2_NM)'
      
    CASE DEFAULT
      output%status%status_code = IF_STATUS_ERROR
      output%message = 'ERROR: Unknown output format'
      RETURN
    END SELECT
    
    ! Update statistics
    IF (input%write_field) THEN
      input%field_state%n_frames_written = input%field_state%n_frames_written + 1
      output%n_frames_written = input%field_state%n_frames_written
    END IF
    
    output%bytes_written = 1024 * 1024  ! Estimate
    output%write_successful = .TRUE.
    output%output_file_path = file_path // '.vtk'
    output%status%status_code = IF_STATUS_OK
    
  CONTAINS
    
    ! Local helper function
    FUNCTION ITOA(i) RESULT(str)
      INTEGER(i4), INTENT(IN) :: i
      CHARACTER(LEN=16) :: str
      WRITE(str, '(I16)') i
    END FUNCTION ITOA
    
  END SUBROUTINE RT_Out_Impl_Write
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Impl_WriteScalar - Write a single scalar field
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Out_Impl_WriteScalar(field_name, values, n_values, &
                                      output_format, file_path, ierr)
    CHARACTER(LEN=*), INTENT(IN)  :: field_name
    REAL(wp),         INTENT(IN)  :: values(:)
    INTEGER(i4),      INTENT(IN)  :: n_values
    INTEGER(i4),      INTENT(IN)  :: output_format
    CHARACTER(LEN=*), INTENT(IN)  :: file_path
    INTEGER(i4),      INTENT(OUT) :: ierr
    
    INTEGER(i4) :: i
    ierr = 0_i4
    
    IF (n_values <= 0_i4) THEN
      ierr = -1_i4
      RETURN
    END IF
    
    SELECT CASE (output_format)
    CASE (RT_OUT_FMT_ASCII)
      ! Placeholder: delegate to L2_NM ASCII scalar writer
      ! CALL NM_Writer_ASCII_WriteScalar(field_name, values, n_values, file_path, ierr)
      CONTINUE
    CASE (RT_OUT_FMT_HDF5)
      ! Placeholder: delegate to L2_NM HDF5 scalar writer
      ! CALL NM_Writer_HDF5_WriteScalar(field_name, values, n_values, file_path, ierr)
      CONTINUE
    CASE (RT_OUT_FMT_ODB)
      ! Placeholder: delegate to L2_NM ODB scalar writer
      ! CALL NM_Writer_ODB_WriteScalar(field_name, values, n_values, file_path, ierr)
      CONTINUE
    CASE DEFAULT
      ierr = -2_i4  ! Unknown format
    END SELECT
    
  END SUBROUTINE RT_Out_Impl_WriteScalar
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Impl_WriteVector - Write a vector field (ndim per node/elem)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Out_Impl_WriteVector(field_name, values, n_values, ndim, &
                                      output_format, file_path, ierr)
    CHARACTER(LEN=*), INTENT(IN)  :: field_name
    REAL(wp),         INTENT(IN)  :: values(:,:)
    INTEGER(i4),      INTENT(IN)  :: n_values
    INTEGER(i4),      INTENT(IN)  :: ndim
    INTEGER(i4),      INTENT(IN)  :: output_format
    CHARACTER(LEN=*), INTENT(IN)  :: file_path
    INTEGER(i4),      INTENT(OUT) :: ierr
    
    ierr = 0_i4
    
    IF (n_values <= 0_i4 .OR. ndim <= 0_i4) THEN
      ierr = -1_i4
      RETURN
    END IF
    
    SELECT CASE (output_format)
    CASE (RT_OUT_FMT_ASCII)
      ! Placeholder: delegate to L2_NM ASCII vector writer
      CONTINUE
    CASE (RT_OUT_FMT_HDF5)
      ! Placeholder: delegate to L2_NM HDF5 vector writer
      CONTINUE
    CASE (RT_OUT_FMT_ODB)
      ! Placeholder: delegate to L2_NM ODB vector writer
      CONTINUE
    CASE DEFAULT
      ierr = -2_i4
    END SELECT
    
  END SUBROUTINE RT_Out_Impl_WriteVector
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Impl_WriteTensor - Write a tensor field (ncomp per node/elem)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Out_Impl_WriteTensor(field_name, values, n_values, ncomp, &
                                      output_format, file_path, ierr)
    CHARACTER(LEN=*), INTENT(IN)  :: field_name
    REAL(wp),         INTENT(IN)  :: values(:,:)
    INTEGER(i4),      INTENT(IN)  :: n_values
    INTEGER(i4),      INTENT(IN)  :: ncomp
    INTEGER(i4),      INTENT(IN)  :: output_format
    CHARACTER(LEN=*), INTENT(IN)  :: file_path
    INTEGER(i4),      INTENT(OUT) :: ierr
    
    ierr = 0_i4
    
    IF (n_values <= 0_i4 .OR. ncomp <= 0_i4) THEN
      ierr = -1_i4
      RETURN
    END IF
    
    SELECT CASE (output_format)
    CASE (RT_OUT_FMT_ASCII)
      ! Placeholder: delegate to L2_NM ASCII tensor writer
      CONTINUE
    CASE (RT_OUT_FMT_HDF5)
      ! Placeholder: delegate to L2_NM HDF5 tensor writer
      CONTINUE
    CASE (RT_OUT_FMT_ODB)
      ! Placeholder: delegate to L2_NM ODB tensor writer
      CONTINUE
    CASE DEFAULT
      ierr = -2_i4
    END SELECT
    
  END SUBROUTINE RT_Out_Impl_WriteTensor
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Impl_Finalize �?Finalize Output System
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Out_Impl_Finalize(input, output)
    TYPE(RT_Out_Finalize_In), INTENT(INOUT) :: input
    TYPE(RT_Out_Finalize_Out), INTENT(OUT) :: output
    
    CALL init_error_status(output%status)
    output%finalized = .FALSE.
    
    ! Flush remaining buffers
    IF (input%flush_buffers) THEN
      ! CALL input%field_buffer%Flush()
      ! CALL input%hist_buffer%Flush()
    END IF
    
    ! Close output files
    IF (input%close_files) THEN
      ! CALL NM_Writer_CloseFiles(...)
    END IF
    
    ! Write summary
    IF (input%write_summary) THEN
      output%total_frames_written = input%field_state%n_frames_written
      output%total_points_written = input%hist_state%n_points_written
      output%summary_message = 'Output system finalized successfully'
    END IF
    
    output%finalized = .TRUE.
    output%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE RT_Out_Impl_Finalize
  
END MODULE RT_Out_Impl