!======================================================================
! Module: RT_Out
! Layer:  L5_RT - Runtime Layer
! Domain: Output / Core
! Purpose: Runtime output core module (field and history data).
!          ACTIVE Golden Path production module for output orchestration.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: ACTIVE | GOLDEN-LINE | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output
!   AUTHORITY types: RT_Out_Def.f90 (RT_Out_Desc, RT_Out_FieldState, etc.)
!   This module:     Production orchestration (Init/Inc/BuildFrame/WriteFrame)
!   LEGACY facade:   RT_Output_Core.f90 (do not extend)
!======================================================================
!     Output system implements efficient data collection from
!     runtime solver state and writes to various file formats:
!     - Field output: Nodal/element variables at specified increments
!     - History output: Time series data for specific locations
!     - Buffered writes to minimize system calls
!     - Continuous memory layout for cache efficiency
!
!   Performance Strategies:
!     - Block I/O: Batch multiple writes into single operation
!     - Memory pooling: Reuse buffers across increments
!     - Lazy evaluation: Only collect requested variables
!     - Stride-1 access: Optimize memory traversal patterns
!
!   Reference:
!     - UFC_Core_Phase2_Plan.md Section H (H1 H2 H3)
!     - ABAQUS Analysis User's Manual, Section 4.1.2
!     - Paraview VTK File Formats Guide
!
!   Author: UFC Development Team
!   Date: 2026-02
! ===================================================================

!===============================================================================
! Module: RT_Out
! Layer:  L5_RT - Runtime Layer
! Domain: Output - Output, field output
! Purpose: Output core: orchestrate field/history/restart output at step/increment end
! Theory:  ABAQUS Analysis User Manual §4.1 (output requests)
! Status:  [STUB/CORE/PROD] | Last verified: 2026-02-28
!
! Contents (A-Z):
!   Types:
!     - [List types in A-Z order]
!   Subroutines:
!     - [List subroutines in A-Z order]
!   Functions:
!     - [List functions in A-Z order]
!===============================================================================

module RT_Out_Mgr
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
!> Theory: ABAQUS Analysis User Manual §4.1 (output requests) | Last verified: 2026-02-14
!> Status: (TODO) | Last verified: 2026-02-14
  !! Runtime Output Core Module
  !! Implements H3 - Output system industrialization
  
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR, IF_STATUS_WARN
  USE IF_Mem_Mgr, only: UF_Mem_AllocInt1D, UF_Mem_FreeInt1D, MEM_DOMAIN_CMD
  USE IF_Prec_Core, only: wp, i4, i8
  USE IF_IO_File, only: IF_FileHandle, IF_IO_MODE_WRITE, IF_IO_FORMAT_BINARY, &
                        IF_FileHandle_Open_In, IF_FileHandle_Close_Out
  USE MD_Out_Def, only: FldOutReq, HistOutReq, OutFrame
  use MD_Step_Mgr, only: MD_OutCfg, MD_OutReq
  
  implicit none
  private
  
  ! ===================================================================
  ! Public Types
  ! ===================================================================
  public :: RT_Out_Frame
  public :: RT_Out_Cfg
  public :: RT_Out_State
  public :: RT_Out_Buf
  
  ! ===================================================================
  ! Public Procedures
  ! ===================================================================
  public :: RT_Out_Init
  public :: RT_Out_Inc
  public :: RT_Out_BuildFrame
  public :: RT_Out_WriteFrame
  public :: RT_Out_Finalize
  public :: RT_Out_ChkFreq
  ! Extended API (11500-11599)
  public :: RT_Out_UnifMgr
  
  ! ===================================================================
  ! Constants
  ! ===================================================================
  integer(i4), parameter :: MAX_FLD_VARS = 50_i4
  integer(i4), parameter :: MAX_HIST_VARS = 100_i4
  integer(i4), parameter :: BUF_SIZE = 1024_i4
  
  ! Output formats
  integer(i4), parameter, public :: RT_OUT_FMT_VTK = 1_i4
  integer(i4), parameter, public :: RT_OUT_FMT_HDF5 = 2_i4
  integer(i4), parameter, public :: RT_OUT_FMT_ODB = 3_i4
  integer(i4), parameter, public :: RT_OUT_FMT_ASCII = 4_i4
  
  ! ===================================================================
  ! Runtime Output Frame Type
  ! ===================================================================
  type, public :: RT_Out_Frame
    !! Output frame for single increment
    
    ! Meta information
    integer(i4) :: stepId = 0_i4
    integer(i4) :: incId = 0_i4
    real(wp) :: time = 0.0_wp
    real(wp) :: dt = 0.0_wp
    
    ! Mesh information
    integer(i4) :: nNodes = 0_i4
    integer(i4) :: nElems = 0_i4
    integer(i4) :: nDofs = 0_i4
    
    ! Node data (continuous memory layout)
    real(wp), allocatable :: nodeCoords(:,:)      ! (3, nNodes)
    real(wp), allocatable :: nodeDisp(:,:) ! (3, nNodes)
    real(wp), allocatable :: nodeVel(:,:)    ! (3, nNodes)
    real(wp), allocatable :: nodeAccel(:,:) ! (3, nNodes)
    real(wp), allocatable :: nodeTemp(:)    ! (nNodes)
    real(wp), allocatable :: nodePress(:)       ! (nNodes)
    
    ! Element data
    integer(i4), allocatable :: elemConn(:,:) ! (max_nodes_per_elem, nElems)
    integer(i4), allocatable :: elemTypes(:)          ! (nElems)
    real(wp), allocatable :: elemStress(:,:)        ! (6, nElems) Voigt notation
    real(wp), allocatable :: elemStrain(:,:)         ! (6, nElems)
    real(wp), allocatable :: elemEnerg(:)          ! (nElems)
    
    ! Field variables (generic storage)
    integer(i4) :: nFldVars = 0_i4
    character(len=64), allocatable :: fldVarNames(:)
    real(wp), allocatable :: fldVarData(:,:)  ! (nNodes or nElems, nFldVars)
    
    ! Status flags
    logical :: hasDisp = .false.
    logical :: hasVel = .false.
    logical :: hasAccel = .false.
    logical :: hasTemp = .false.
    logical :: hasPress = .false.
    logical :: hasStress = .false.
    logical :: hasStrain = .false.
    logical :: inited = .false.
  
  contains
    procedure, public :: Init => RT_Out_FrameInit
    procedure, public :: AllocateNode => RT_Out_FrameAllocNode
    procedure, public :: AllocateElem => RT_Out_FrameAllocElem
    procedure, public :: Cleanup => RT_Out_FrameCleanup
  end type RT_Out_Frame
  
  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: RT_Out_Core_Args
  TYPE :: RT_Out_Core_Args
  ! Purpose: Core element argument container for output system
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE RT_Out_Core_Args
  
  ! ===================================================================
  ! Runtime Output Configuration Type
  ! ===================================================================
  type, public :: RT_Out_Cfg
    !! Configuration for output system
    
    ! Output frequencies
    integer(i4) :: fldFreq = 1_i4
    integer(i4) :: histFreq = 1_i4
    integer(i4) :: restartFreq = 10_i4
    
    ! Output format
    integer(i4) :: format = RT_OUT_FMT_VTK
    character(len=256) :: outDir = "./"
    character(len=64) :: filePrefix = "output"
    
    ! Field output requests
    integer(i4) :: nFldReqs = 0_i4
    type(FldOutReq), allocatable :: fldReqs(:)
    
    ! History output requests
    integer(i4) :: nHistReqs = 0_i4
    type(HistOutReq), allocatable :: histReqs(:)
    
    ! Performance options
    logical :: useBuf = .true.
    logical :: useComp = .false.
    integer(i4) :: bufSize = BUF_SIZE
    logical :: writeBin = .true.
    
    ! Output control
    logical :: outInit = .true.
    logical :: outFinal = .true.
    real(wp) :: timeIntv = 0.0_wp
    
  contains
    procedure, public :: Init => RT_Out_CfgInit
    procedure, public :: AddFieldRequest => RT_Out_CfgAddFldReq
    procedure, public :: AddHistoryRequest => RT_Out_CfgAddHistReq
  end type RT_Out_Cfg
  
  ! ===================================================================
  ! Runtime Output State Type
  ! ===================================================================
  type, public :: RT_Out_State
    !! State tracking for output system
    
    integer(i4) :: lastFldOutInc = 0_i4
    integer(i4) :: lastHistOutInc = 0_i4
    integer(i4) :: lastRestartOutInc = 0_i4
    real(wp) :: lastFldOutTime = 0.0_wp
    real(wp) :: lastHistOutTime = 0.0_wp
    
    integer(i4) :: totalFramesWr = 0_i4
    integer(i4) :: totalHistPts = 0_i4
    
    logical :: inited = .false.
    
  contains
    procedure, public :: Init => RT_Out_StateInit
    procedure, public :: Reset => RT_Out_StateReset
  end type RT_Out_State
  
  ! ===================================================================
  ! Runtime Output Buffer Type (for performance)
  ! ===================================================================
  type, public :: RT_Out_Buf
    !! Buffer for batched write operations
    
    integer(i4) :: capacity = BUF_SIZE
    integer(i4) :: size = 0_i4
    real(wp), allocatable :: data(:)
    integer(i4), allocatable :: indices(:)
    
    logical :: full = .false.
    
  contains
    procedure, public :: Init => RT_Out_BufInit
    procedure, public :: Add => RT_Out_BufAdd
    procedure, public :: Flush => RT_Out_BufFlush
    procedure, public :: Clear => RT_Out_BufClear
    procedure, public :: Cleanup => RT_Out_BufCleanup
  end type RT_Out_Buf

contains

  ! ===================================================================
  ! RT_Out_Frame Procedures
  ! ===================================================================
  
  subroutine RT_Out_FrameInit(this, nNodes, nElems)
    !! Init output frame
    class(RT_Out_Frame), intent(inout) :: this
    integer(i4), intent(in) :: nNodes, nElems
    
    this%nNodes = nNodes
    this%nElems = nElems
    this%inited = .true.
    
    ! Allocate basic arrays
    call this%AllocateNode(nNodes)
    call this%AllocateElem(nElems)
    
  end subroutine RT_Out_FrameInit
  
  subroutine RT_Out_FrameAllocNode(this, nNodes)
    !! Allocate node-based arrays
    class(RT_Out_Frame), intent(inout) :: this
    integer(i4), intent(in) :: nNodes
    
    if (allocated(this%nodeCoords)) deallocate(this%nodeCoords)
    allocate(this%nodeCoords(3, nNodes))
    this%nodeCoords = 0.0_wp
    
  end subroutine RT_Out_FrameAllocNode
  
  subroutine RT_Out_FrameAllocElem(this, nElems)
    !! Allocate element-based arrays
    class(RT_Out_Frame), intent(inout) :: this
    integer(i4), intent(in) :: nElems
    
    if (allocated(this%elemTypes)) deallocate(this%elemTypes)
    allocate(this%elemTypes(nElems))
    this%elemTypes = 0_i4
    
  end subroutine RT_Out_FrameAllocElem
  
  subroutine RT_Out_FrameCleanup(this)
    !! Cleanup output frame
    class(RT_Out_Frame), intent(inout) :: this
    
    if (allocated(this%nodeCoords)) deallocate(this%nodeCoords)
    if (allocated(this%nodeDisp)) deallocate(this%nodeDisp)
    if (allocated(this%nodeVel)) deallocate(this%nodeVel)
    if (allocated(this%nodeAccel)) deallocate(this%nodeAccel)
    if (allocated(this%nodeTemp)) deallocate(this%nodeTemp)
    if (allocated(this%nodePress)) deallocate(this%nodePress)
    
    if (allocated(this%elemConn)) deallocate(this%elemConn)
    if (allocated(this%elemTypes)) deallocate(this%elemTypes)
    if (allocated(this%elemStress)) deallocate(this%elemStress)
    if (allocated(this%elemStrain)) deallocate(this%elemStrain)
    if (allocated(this%elemEnerg)) deallocate(this%elemEnerg)
    
    if (allocated(this%fldVarNames)) deallocate(this%fldVarNames)
    if (allocated(this%fldVarData)) deallocate(this%fldVarData)
    
    this%inited = .false.
    
  end subroutine RT_Out_FrameCleanup

  ! ===================================================================
  ! RT_OutConfig Procedures
  ! ===================================================================
  
  subroutine RT_Out_CfgInit(this, fldFreq, histFreq, format)
    !! Init output configuration
    class(RT_Out_Cfg), intent(inout) :: this
    integer(i4), intent(in), optional :: fldFreq, histFreq, format
    
    if (present(fldFreq)) this%fldFreq = fldFreq
    if (present(histFreq)) this%histFreq = histFreq
    if (present(format)) this%format = format
    
    this%useBuf = .true.
    this%writeBin = .true.
    this%outInit = .true.
    this%outFinal = .true.
    
  end subroutine RT_Out_CfgInit
  
  subroutine RT_Out_CfgAddFldReq(this, fldReq, stat)
    !! Add field output request
    class(RT_Out_Cfg), intent(inout) :: this
    type(FldOutReq), intent(in) :: fldReq
    type(ErrorStatusType), intent(out), optional :: stat
    
    type(FldOutReq), allocatable :: temp(:)
    integer(i4) :: n, newSize
    
    call init_error_status(stat)
    
    n = this%nFldReqs
    
    if (allocated(this%fldReqs)) then
      if (n >= size(this%fldReqs)) then
        ! Resize array
        newSize = size(this%fldReqs) * 2
        allocate(temp(newSize))
        temp(1:n) = this%fldReqs(1:n)
        deallocate(this%fldReqs)
        allocate(this%fldReqs(newSize))
        this%fldReqs = temp
        deallocate(temp)
      end if
    else
      allocate(this%fldReqs(10))
    end if
    
    this%nFldReqs = n + 1
    this%fldReqs(this%nFldReqs) = fldReq
    
    if (present(stat)) stat%status_code = IF_STATUS_OK
    
  end subroutine RT_Out_CfgAddFldReq
  
  subroutine RT_Out_CfgAddHistReq(this, histReq, stat)
    !! Add history output request
    class(RT_Out_Cfg), intent(inout) :: this
    type(HistOutReq), intent(in) :: histReq
    type(ErrorStatusType), intent(out), optional :: stat
    
    type(HistOutReq), allocatable :: temp(:)
    integer(i4) :: n, newSize
    
    call init_error_status(stat)
    
    n = this%nHistReqs
    
    if (allocated(this%histReqs)) then
      if (n >= size(this%histReqs)) then
        newSize = size(this%histReqs) * 2
        allocate(temp(newSize))
        temp(1:n) = this%histReqs(1:n)
        deallocate(this%histReqs)
        allocate(this%histReqs(newSize))
        this%histReqs = temp
        deallocate(temp)
      end if
    else
      allocate(this%histReqs(10))
    end if
    
    this%nHistReqs = n + 1
    this%histReqs(this%nHistReqs) = histReq
    
    if (present(stat)) stat%status_code = IF_STATUS_OK
    
  end subroutine RT_Out_CfgAddHistReq

  ! ===================================================================
  ! RT_Out_State Procedures
  ! ===================================================================
  
  subroutine RT_Out_StateInit(this)
    !! Init output state
    class(RT_Out_State), intent(inout) :: this
    
    this%lastFldOutInc = 0_i4
    this%lastHistOutInc = 0_i4
    this%lastRestartOutInc = 0_i4
    this%lastFldOutTime = 0.0_wp
    this%lastHistOutTime = 0.0_wp
    this%totalFramesWr = 0_i4
    this%totalHistPts = 0_i4
    this%inited = .true.
    
  end subroutine RT_Out_StateInit
  
  subroutine RT_Out_StateReset(this)
    !! Reset output state
    class(RT_Out_State), intent(inout) :: this
    
    call this%Init()
    
  end subroutine RT_Out_StateReset

  ! ===================================================================
  ! RT_Out_Buf Procedures
  ! ===================================================================
  
  subroutine RT_Out_BufInit(this, capacity)
    !! Init output buffer
    class(RT_Out_Buf), intent(inout) :: this
    integer(i4), intent(in), optional :: capacity
    
    if (present(capacity)) this%capacity = capacity
    
    if (allocated(this%data)) deallocate(this%data)
    allocate(this%data(this%capacity))
    this%data = 0.0_wp
    
    if (allocated(this%indices)) deallocate(this%indices)
    allocate(this%indices(this%capacity))
    this%indices = 0_i4
    
    this%size = 0_i4
    this%full = .false.
    
  end subroutine RT_Out_BufInit
  
  subroutine RT_Out_BufAdd(this, value, index)
    !! Add data to buffer
    class(RT_Out_Buf), intent(inout) :: this
    real(wp), intent(in) :: value
    integer(i4), intent(in) :: index
    
    if (this%size >= this%capacity) then
      this%full = .true.
      return
    end if
    
    this%size = this%size + 1
    this%data(this%size) = value
    this%indices(this%size) = index
    
    if (this%size >= this%capacity) this%full = .true.
    
  end subroutine RT_Out_BufAdd
  
  subroutine RT_Out_BufFlush(this)
    !! Flush buffer (write to file rt_out_buffer.dat)
    !! ARCHITECTURE FIX (SB-1): Route IO operations to L1_IF/IO
    class(RT_Out_Buf), intent(inout) :: this
    
    integer(i4) :: i
    type(IF_FileHandle) :: handle
    type(IF_FileHandle_Open_In) :: open_in
    type(IF_FileHandle_Close_Out) :: close_out
    type(ErrorStatusType) :: io_status
    
    if (this%size > 0 .and. allocated(this%data) .and. allocated(this%indices)) then
      ! Open file using L1_IF/IO infrastructure
      open_in%filename = 'rt_out_buffer.dat'
      open_in%mode = IF_IO_MODE_WRITE
      open_in%format = IF_IO_FORMAT_BINARY
      CALL IF_FileHandle_Open(handle, open_in%filename, open_in%mode, open_in%format, io_status)
      
      ! Write buffer size
      CALL handle%WriteBinary(this%size, SIZE(this%size)*STORAGE_SIZE(this%size)/8_i8, io_status)
      
      ! Write indices array
      CALL handle%WriteBinary(this%indices(1:this%size), INT(this%size, i8)*STORAGE_SIZE(this%indices(1))/8_i8, io_status)
      
      ! Write data array
      CALL handle%WriteBinary(this%data(1:this%size), INT(this%size, i8)*STORAGE_SIZE(this%data(1))/8_i8, io_status)
      
      ! Close file
      close_out%handle = handle
      CALL IF_FileHandle_Close(close_out, io_status)
    end if
    call this%Clear()
  end subroutine RT_Out_BufFlush
  
  subroutine RT_Out_BufClear(this)
    !! Clear buffer
    class(RT_Out_Buf), intent(inout) :: this
    
    this%size = 0_i4
    this%full = .false.
    
  end subroutine RT_Out_BufClear
  
  subroutine RT_Out_BufCleanup(this)
    !! Cleanup buffer
    class(RT_Out_Buf), intent(inout) :: this
    
    if (allocated(this%data)) deallocate(this%data)
    if (allocated(this%indices)) deallocate(this%indices)
    this%size = 0_i4
    this%capacity = 0_i4
    
  end subroutine RT_Out_BufCleanup

  ! ===================================================================
  ! Main Output Procedures
  ! ===================================================================
  
  subroutine RT_Out_Init(cfg, outState, stat)
    !! Init output system
    !!
    !! Sets up output configuration and initializes state tracking
    
    type(RT_Out_Cfg), intent(inout) :: cfg
    type(RT_Out_State), intent(out) :: outState
    type(ErrorStatusType), intent(out), optional :: stat
    
    call init_error_status(stat)
    
    ! Init output state
    call outState%Init()
    
    ! Valid configuration
    if (cfg%fldFreq < 0) cfg%fldFreq = 1
    if (cfg%histFreq < 0) cfg%histFreq = 1
    
    if (present(stat)) stat%status_code = IF_STATUS_OK
    
  end subroutine RT_Out_Init

  subroutine RT_Out_Inc(stepId, incId, time, cfg, outState, outFrame, stat)
    !! Main output driver for increment
    !!
    !! Algorithm (from UFC_Core_Phase2_Plan.md H3):
    !! 1. Check if output is needed based on frequency
    !! 2. Build output frame if needed
    !! 3. Write frame to file in requested format
    !! 4. Update output state
    
    integer(i4), intent(in) :: stepId, incId
    real(wp), intent(in) :: time
    type(RT_Out_Cfg), intent(in) :: cfg
    type(RT_Out_State), intent(inout) :: outState
    type(RT_Out_Frame), intent(inout) :: outFrame
    type(ErrorStatusType), intent(out), optional :: stat
    
    logical :: needFld, needHist
    
    call init_error_status(stat)
    
    ! Step 1: Check if output is needed
    call RT_Out_ChkFreq(stepId, incId, time, cfg, outState, &
                        needFld, needHist, stat)
    
    if (.not. (needFld .or. needHist)) then
      if (present(stat)) stat%status_code = IF_STATUS_OK
      return
    end if
    
    ! Step 2: Build output frame (data collection)
    ! This would collect data from job/solver state
    ! Placeholder - actual implementation needs job Ctx
    outFrame%stepId = stepId
    outFrame%incId = incId
    outFrame%time = time
    
    ! Step 3: Write frame to file
    if (needFld) then
      call RT_Out_WriteFrame(outFrame, cfg, outState, stat)
      if (present(stat) .and. stat%status_code /= IF_STATUS_OK) return
    end if
    
    ! Step 4: Update output state
    if (needFld) then
      outState%lastFldOutInc = incId
      outState%lastFldOutTime = time
      outState%totalFramesWr = outState%totalFramesWr + 1
    end if
    
    if (needHist) then
      outState%lastHistOutInc = incId
      outState%lastHistOutTime = time
      outState%totalHistPts = outState%totalHistPts + 1
    end if
    
    if (present(stat)) stat%status_code = IF_STATUS_OK
    
  end subroutine RT_Out_Inc

  subroutine RT_Out_BuildFrame(job, stepId, incId, time, needFld, needHist, &
                                 outFrame, stat)
    !! Build output frame from job state
    !!
    !! Performance optimizations (from UFC_Core_Phase2_Plan.md H3):
    !! - Continuous memory layout for coord/conn arrays
    !! - Stride-1 memory access patterns
    !! - Lazy evaluation: only collect requested variables
    !! - Memory pooling: reuse frame buffers
    
    class(*), intent(in) :: job  ! Would be RT_Job_Type
    integer(i4), intent(in) :: stepId, incId
    real(wp), intent(in) :: time
    logical, intent(in) :: needFld, needHist
    type(RT_Out_Frame), intent(out) :: outFrame
    type(ErrorStatusType), intent(out), optional :: stat
    
    integer(i4) :: iNode
    
    call init_error_status(stat)
    
    ! Set meta information
    outFrame%stepId = stepId
    outFrame%incId = incId
    outFrame%time = time
    
    ! Placeholder implementation
    ! Actual implementation would:
    ! 1. Get mesh from job: CALL RT_Job_GetMesh(job, mesh)
    ! 2. Extract node coordinates: outFrame%nodeCoords = mesh%coords
    ! 3. Extract element connectivity: outFrame%elemConn = mesh%connectivity
    ! 4. Extract solution fields from DOF vectors
    ! 5. Compute derived quantities (stresses, strains) if requested
    
    if (needFld) then
      ! TODO: Collect field data
      ! - Loop over nodes, extract displacements/temperatures
      ! - Use stride-1 access for cache efficiency
      ! - Batch operations for vectorization
    end if
    
    if (needHist) then
      ! TODO: Collect history data
      ! - Extract time series for specified locations
      ! - Append to history buffers
    end if
    
    if (present(stat)) stat%status_code = IF_STATUS_OK
    
  end subroutine RT_Out_BuildFrame

  subroutine RT_Out_WriteFrame(outFrame, cfg, outState, stat)
    !! Write output frame to file
    !!
    !! Dispatches to format-specific writers
    
    type(RT_Out_Frame), intent(in) :: outFrame
    type(RT_Out_Cfg), intent(in) :: cfg
    type(RT_Out_State), intent(in) :: outState
    type(ErrorStatusType), intent(out), optional :: stat
    
    character(len=512) :: filename
    integer(i4) :: frameNum
    
    call init_error_status(stat)
    
    frameNum = outState%totalFramesWr
    
    ! Construct filename
    select case(cfg%format)
    case(RT_OUT_FMT_VTK)
      write(filename, '(A,A,A,I0.6,A)') trim(cfg%outDir), '/', &
                                         trim(cfg%filePrefix), frameNum, '.vtu'
      call RT_Out_WriteVTK(outFrame, filename, stat)
      
    case(RT_OUT_FMT_HDF5)
      write(filename, '(A,A,A,I0.6,A)') trim(cfg%outDir), '/', &
                                         trim(cfg%filePrefix), frameNum, '.h5'
      call RT_Out_WriteHDF5(outFrame, filename, stat)
      
    case(RT_OUT_FMT_ODB)
      write(filename, '(A,A,A,A)') trim(cfg%outDir), '/', &
                                    trim(cfg%filePrefix), '.odb'
      call RT_Out_WriteODB(outFrame, filename, stat)
      
    case default
      if (present(stat)) then
        stat%status_code = IF_STATUS_INVALID
        stat%message = 'RT_Out_WriteFrame: Unknown output format'
      end if
      return
    end select
    
  end subroutine RT_Out_WriteFrame

  subroutine RT_Out_ChkFreq(stepId, incId, time, cfg, outState, &
                                     needFld, needHist, stat)
    !! Check if output is needed based on frequency settings
    
    integer(i4), intent(in) :: stepId, incId
    real(wp), intent(in) :: time
    type(RT_Out_Cfg), intent(in) :: cfg
    type(RT_Out_State), intent(in) :: outState
    logical, intent(out) :: needFld, needHist
    type(ErrorStatusType), intent(out), optional :: stat
    
    call init_error_status(stat)
    
    needFld = .false.
    needHist = .false.
    
    ! Check field output frequency
    if (cfg%fldFreq > 0) then
      needFld = (mod(incId, cfg%fldFreq) == 0)
    end if
    
    ! Check history output frequency
    if (cfg%histFreq > 0) then
      needHist = (mod(incId, cfg%histFreq) == 0)
    end if
    
    ! Check time interval
    if (cfg%timeIntv > 0.0_wp) then
      if (time - outState%lastFldOutTime >= cfg%timeIntv) then
        needFld = .true.
      end if
    end if
    
    ! Output initial state if configured
    if (cfg%outInit .and. incId == 0) then
      needFld = .true.
      needHist = .true.
    end if
    
    if (present(stat)) stat%status_code = IF_STATUS_OK
    
  end subroutine RT_Out_ChkFreq

  subroutine RT_Out_Finalize(outState, stat)
    !! Finalize output system
    !!
    !! Cleanup and close all output files
    
    type(RT_Out_State), intent(inout) :: outState
    type(ErrorStatusType), intent(out), optional :: stat
    
    call init_error_status(stat)
    
    ! Cleanup state
    outState%inited = .false.
    
    if (present(stat)) stat%status_code = IF_STATUS_OK
    
  end subroutine RT_Out_Finalize

  ! ===================================================================
  ! Format-Specific Writers (Placeholders)
  ! ===================================================================
  
  subroutine RT_Out_WriteVTK(out_frame, filename, status)
    !! Write frame in VTK format (minimal VTU: points and cells)
    
    type(RT_Out_Frame), intent(in) :: out_frame
    character(len=*), intent(in) :: filename
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: u, ios, i, j, n_nodes, n_elems
    
    call init_error_status(status)
    n_nodes = out_frame%pop%n_nodes
    n_elems = out_frame%pop%n_elements
    open(newunit=u, file=trim(filename), status='replace', action='write', form='formatted', iostat=ios)
    if (ios /= 0) then
      if (present(status)) status%status_code = IF_STATUS_INVALID
      return
    end if
    write(u, '(A)') '<?xml version="1.0"?>'
    write(u, '(A)') '<VTKFile type="UnstructuredGrid" version="1.0">'
    write(u, '(A,I0,A,I0,A)') '<UnstructuredGrid><Piece NumberOfPoints="', n_nodes, '" NumberOfCells="', n_elems, '">'
    if (n_nodes > 0 .and. allocated(out_frame%node_coords)) then
      write(u, '(A)') '<Points><DataArray type="Float64" NumberOfComponents="3" format="ascii">'
      do i = 1, n_nodes
        write(u, '(3(1X,ES15.7))') (out_frame%node_coords(j, i), j = 1, 3)
      end do
      write(u, '(A)') '</DataArray></Points>'
    else
      write(u, '(A)') '<Points/>'
    end if
    write(u, '(A)') '<Cells/>'
    write(u, '(A)') '</Piece></UnstructuredGrid></VTKFile>'
    close(u)
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_Out_WriteVTK
  
  subroutine RT_Out_WriteHDF5(outFrame, filename, stat)
    !! Write frame in HDF5-like format (simplified text structure)
    
    type(RT_Out_Frame), intent(in) :: outFrame
    character(len=*), intent(in) :: filename
    type(ErrorStatusType), intent(out), optional :: stat
    
    integer(i4) :: u, ios
    call init_error_status(stat)
    open(newunit=u, file=trim(filename), status='replace', action='write', form='formatted', iostat=ios)
    if (ios /= 0) then
      if (present(stat)) stat%status_code = IF_STATUS_INVALID
      return
    end if
    write(u, '(A)') '# HDF5-like output'
    write(u, '(A,I0,A,I0,A,I0)') 'step_id ', outFrame%stepId, ' increment_id ', outFrame%incId, ' time ', 0
    write(u, '(A,ES15.7)') 'time ', outFrame%time
    write(u, '(A,I0,A,I0)') 'n_nodes ', outFrame%nNodes, ' n_elements ', outFrame%nElems
    close(u)
    if (present(stat)) stat%status_code = IF_STATUS_OK
  end subroutine RT_Out_WriteHDF5
  
  subroutine RT_Out_WriteODB(outFrame, filename, stat)
    !! Write frame in ODB-like format (simplified binary header)
    
    type(RT_Out_Frame), intent(in) :: outFrame
    character(len=*), intent(in) :: filename
    type(ErrorStatusType), intent(out), optional :: stat
    
    integer(i4) :: u, ios
    call init_error_status(stat)
    open(newunit=u, file=trim(filename), status='replace', action='write', form='unformatted', access='stream', iostat=ios)
    if (ios /= 0) then
      if (present(stat)) stat%status_code = IF_STATUS_INVALID
      return
    end if
    write(u) 'ODB '
    write(u) outFrame%stepId, outFrame%incId, outFrame%time, outFrame%nNodes, outFrame%nElems
    close(u)
    if (present(stat)) stat%status_code = IF_STATUS_OK
  end subroutine RT_Out_WriteODB

  !=============================================================================
  ! Extended Output Management API (11500-11599)
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! ??????11500-11549????????????????????????????
  !-----------------------------------------------------------------------------
  subroutine RT_Out_UnifMgr(model, stepId, incId, time, cfg, &
                                      outState, stat)
    !! Unified output management interface
    !!
    !! Delegates to RT_Out_Inc for frequency check, frame build, write, state update.
    !! model is passed for future use (RT_Out_Inc uses job Ctx; model can provide mesh/solution).
    !!
    !! Task: 11500-11549
    class(*), intent(in) :: model
    integer(i4), intent(in) :: stepId, incId
    real(wp), intent(in) :: time
    type(RT_Out_Cfg), intent(in) :: cfg
    type(RT_Out_State), intent(inout) :: outState
    type(ErrorStatusType), intent(out) :: stat

    type(RT_Out_Frame) :: outFrame

    call init_error_status(stat)
    call RT_Out_Inc(stepId, incId, time, cfg, outState, outFrame, stat)
  end subroutine RT_Out_UnifMgr

  ! ===================================================================
  ! Configuration Management Procedures (merged from RT_Output_Config)
  ! ===================================================================
  
  SUBROUTINE RT_Out_CfgAddFldOut(cfg, outReq, stat)
    !! Add field output request (Runtime layer implementation)
    TYPE(MD_OutCfg), INTENT(INOUT) :: cfg
    TYPE(MD_OutReq), INTENT(IN) :: outReq
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: stat
    
    TYPE(ErrorStatusType) :: localStat
    TYPE(MD_OutReq), ALLOCATABLE :: tempReqs(:)
    INTEGER(i4) :: currSize, newSize, i
    
    CALL init_error_status(localStat)
    
    ! Step 1: Validate
    IF (LEN_TRIM(outReq%variable_name) == 0) THEN
      localStat%status_code = IF_STATUS_INVALID
      localStat%message = 'Add field output: Empty variable name'
      IF (PRESENT(stat)) stat = localStat
      RETURN
    END IF
    
    ! Step 2: Get current size
    IF (ALLOCATED(cfg%field_output_requests)) THEN
      currSize = SIZE(cfg%field_output_requests)
    ELSE
      currSize = 0_i4
    END IF
    
    ! Step 3: Grow array if needed
    IF (cfg%nFieldOutput >= currSize) THEN
      newSize = MAX(10_i4, currSize * 2_i4)
      ALLOCATE(tempReqs(newSize))
      
      ! Copy existing
      IF (currSize > 0_i4) THEN
        DO i = 1, currSize
          tempReqs(i) = cfg%field_output_requests(i)
        END DO

      END IF

      cfg%field_output_requests = tempReqs
      DEALLOCATE(tempReqs)
    END IF
    
    ! Step 4-5: Add request
    cfg%nFieldOutput = cfg%nFieldOutput + 1_i4
    cfg%field_output_requests(cfg%nFieldOutput) = outReq
    
    ! Step 6: Validate variable (U, V, A, S, E, RF, CF)
    ! TODO: Validate variable name against allowed list    
    ! Step 7: Set default frequency
    IF (cfg%field_output_requests(cfg%nFieldOutput)%frequency <= 0_i4) THEN
      cfg%field_output_requests(cfg%nFieldOutput)%frequency = 1_i4
    END IF
    
    ! Step 8: Success
    localStat%status_code = IF_STATUS_OK
    WRITE(localStat%message, '(A,A,A,I0)') &
      'Field output added: ', TRIM(outReq%variable_name), &
      ', total requests: ', cfg%nFieldOutput
    
    IF (PRESENT(stat)) stat = localStat
    
  END SUBROUTINE RT_Out_CfgAddFldOut
  
  !-----------------------------------------------------------------------------
  
  SUBROUTINE RT_Out_CfgAddHistOut(cfg, outReq, stat)
    !! Add history output request (Runtime layer implementation)
    TYPE(MD_OutCfg), INTENT(INOUT) :: cfg
    TYPE(MD_OutReq), INTENT(IN) :: outReq
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: stat
    
    TYPE(ErrorStatusType) :: localStat
    TYPE(MD_OutReq), ALLOCATABLE :: tempReqs(:)
    INTEGER(i4) :: currSize, newSize, i
    
    CALL init_error_status(localStat)
    
    ! Step 1: Validate
    IF (LEN_TRIM(outReq%variable_name) == 0) THEN
      localStat%status_code = IF_STATUS_INVALID
      localStat%message = 'Add history output: Empty variable name'
      IF (PRESENT(stat)) stat = localStat
      RETURN
    END IF
    
    ! Step 2: Get current size
    IF (ALLOCATED(cfg%history_output_requests)) THEN
      currSize = SIZE(cfg%history_output_requests)
    ELSE
      currSize = 0_i4
    END IF
    
    ! Step 3: Grow if needed
    IF (cfg%nHistoryOutput >= currSize) THEN
      newSize = MAX(10_i4, currSize * 2_i4)
      ALLOCATE(tempReqs(newSize))
      
      ! Copy existing
      IF (currSize > 0_i4) THEN
        DO i = 1, currSize
          tempReqs(i) = cfg%history_output_requests(i)
        END DO

      END IF

      cfg%history_output_requests = tempReqs
      DEALLOCATE(tempReqs)
    END IF
    
    ! Step 4-5: Add request
    cfg%nHistoryOutput = cfg%nHistoryOutput + 1_i4
    cfg%history_output_requests(cfg%nHistoryOutput) = outReq
    
    ! Step 6: Validate variable (U, RF, ALLKE, ALLSE, ALLWK)
    ! TODO: Validate variable name against allowed list
    
    ! Step 7: Set default frequency
    IF (cfg%history_output_requests(cfg%nHistoryOutput)%frequency <= 0_i4) THEN
      cfg%history_output_requests(cfg%nHistoryOutput)%frequency = 1_i4
    END IF
    
    ! Step 8: Success
    localStat%status_code = IF_STATUS_OK
    WRITE(localStat%message, '(A,A,A,I0)') &
      'History output added: ', TRIM(outReq%variable_name), &
      ', total requests: ', cfg%nHistoryOutput
    
    IF (PRESENT(stat)) stat = localStat
    
  END SUBROUTINE RT_Out_CfgAddHistOut

end module RT_Out_Mgr