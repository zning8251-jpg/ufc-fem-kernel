!===============================================================================
! MODULE: RT_Shared_Def
! LAYER:  L5_RT
! DOMAIN: Bridge / Shared
! ROLE:   Def ?shared type definitions to break circular dependencies
! BRIEF:  RT_Sol_Cfg/DofMap/State, RT_CSRMatrix, UF_RT_JobStatus.
!===============================================================================
MODULE RT_Shared_Def

  USE IF_Prec_Core, only: wp, i4
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status

  implicit none
  private

  !=============================================================================
  ! PUBLIC TYPES
  !=============================================================================
  
  ! Solver Configuration Types
  public :: RT_Sol_Cfg
  public :: RT_Sol_DofMap
  public :: RT_Sol_State
  public :: RT_CSRMatrix
  
  ! Solver Constants
  public :: RT_SOL_LINSOL_A, RT_SOL_LINSOL_AGMG
  public :: RT_SOL_LINSOL_D, RT_SOL_LINSOL_I, RT_SOL_LINSOL_S
  public :: RT_Sol_Mat_CSR
  public :: RT_SOL_MAT_DENS
  public :: RT_SOL_CONV_FOR
  public :: RT_SOL_CONV_DIS
  public :: RT_SOL_CONV_ENE
  public :: RT_SOL_CONV_MIX
  
  ! Driver Status Types
  public :: UF_RT_JobStatus
  public :: UF_JobStatus_Success

  !=============================================================================
  ! SOLVER CONFIGURATION TYPES
  !=============================================================================

  ! Phase3 S1.4: Auto = 0 (align with NM_LinearSolver SOLVER_AUTO=0)
  integer(i4), parameter :: RT_SOL_LINSOL_A     = 0_i4
  integer(i4), parameter :: RT_SOL_LINSOL_D     = 1_i4
  integer(i4), parameter :: RT_SOL_LINSOL_I    = 2_i4
  ! Phase3 S1.3: AGMG / SparsePak (align with NM_LinearSolver SOLVER_AGMG=7, SOLVER_SPARSEPAK=8)
  integer(i4), parameter :: RT_SOL_LINSOL_AGMG = 7_i4
  integer(i4), parameter :: RT_SOL_LINSOL_S     = 8_i4

  integer(i4), parameter :: RT_Sol_Mat_CSR         = 1_i4
  integer(i4), parameter :: RT_SOL_MAT_DENS       = 2_i4
  ! Phase3 S6.1: convergence type (align with NM_NonlinSolv CONV_*)
  integer(i4), parameter :: RT_SOL_CONV_FOR   = 1_i4
  integer(i4), parameter :: RT_SOL_CONV_DIS   = 2_i4
  integer(i4), parameter :: RT_SOL_CONV_ENE = 3_i4
  integer(i4), parameter :: RT_SOL_CONV_MIX  = 4_i4

  ! ===================================================================
  ! Solver Configuration Type
  ! ===================================================================
  type, public :: RT_Sol_Cfg
    character(len=80) :: name = ""

    ! Linear solver settings (K * du = R)
    integer(i4) :: linearsolvertyp = RT_SOL_LINSOL_I
    integer(i4) :: maxLinearIter    = 10000_i4
    real(wp)    :: linearTol        = 1.0e-6_wp
    integer(i4) :: nThreads         = 1_i4
    logical     :: useGPU           = .false.
    ! Phase7 P1.7.1: GPU configuration
    logical     :: use_gpu_linear = .false.
    logical     :: use_gpu_assembl = .false.
    logical     :: use_gpu_contact = .false.
    integer(i4) :: gpu_device_id = 0
    logical     :: gpu_fallback_to = .true.
    integer(i4) :: matrixStorage    = RT_Sol_Mat_CSR
    logical     :: symmetric        = .true.
    ! Phase3 S4.1: preconditioner (0=auto from symmetric, 1=Jacobi, 2=ILU0, 3=IC0; -1 lfil/droptol = use UF default)
    integer(i4) :: precondType      = 0_i4
    integer(i4) :: precondLfil      = -1_i4
    real(wp)    :: precondDroptol   = -1.0_wp

    ! Nonlinear Newton controls (static NR / implicit dynamics)
    integer(i4) :: maxNewtonIter    = 20_i4
    real(wp)    :: residualTol      = 1.0e-4_wp
    real(wp)    :: correctionTol    = 1.0e-6_wp
    real(wp)    :: energyTol        = 0.0_wp
    ! Phase3 S2.2/S2.4: line search & LBFGS (align with UF_NLParams)
    logical     :: use_line_search  = .false.
    real(wp)    :: ls_min           = 0.1_wp
    real(wp)    :: ls_max           = 1.0_wp
    integer(i4) :: lbfgs_m          = 10_i4
    ! Phase3 S2.3: arc-length (Crisfield/Riks, align with UF_NLParams)
    real(wp)    :: arc_length_init = 0.0_wp
    real(wp)    :: arc_min           = 1.0e-6_wp
    real(wp)    :: arc_max           = 1.0e+2_wp
    real(wp)    :: psi               = 1.0_wp
    ! Phase3 S6.1: convergence criterion (1=force, 2=disp, 3=energy, 4=mixed)
    integer(i4) :: conv_type        = 4_i4

    ! Analysis mode flag
    logical     :: isExplicit       = .false.

    ! Rayleigh damping parameters
    logical     :: useRayleigh      = .false.
    real(wp)    :: alphaRayleigh    = 0.0_wp
    real(wp)    :: betaRayleigh     = 0.0_wp
    logical     :: rayleighinclude = .true.

    ! Contact assembly path selection
    logical     :: usecontactmanag = .false.
    integer(i4) :: contactMethod = 0_i4

    ! HHT-alpha parameters
    logical     :: useHHT           = .false.
    real(wp)    :: alphaHHT         = 0.0_wp

    ! Explicit multi-field update switch
    logical     :: explicitmultifi = .false.
    real(wp)    :: thermalCapacity    = 0.0_wp
    real(wp)    :: poreCapacity       = 0.0_wp
    ! Phase2 N6.1.2/N6.4.2: Precision/Condition/Error estimation flags
    logical     :: enable_precision = .false.
    logical     :: enable_condition = .false.
    logical     :: enable_error_es   = .false.
  end type RT_Sol_Cfg

  ! ===================================================================
  ! DOF Mapping Type
  ! ===================================================================
  type, public :: RT_Sol_DofMap
    integer(i4) :: nTotalEq = 0_i4
    
    ! Node to equation mapping
    integer(i4), allocatable :: nodeToEqStart(:)
    integer(i4), allocatable :: nodeNumDof(:)
    
    ! Equation to node mapping
    integer(i4), allocatable :: eqToNode(:)
    integer(i4), allocatable :: eqToLocal(:)
    
    ! Field info
    integer(i4) :: nFields = 0_i4
    integer(i4), allocatable :: eqFieldId(:)
    integer(i4), allocatable :: fieldEqCount(:)
    integer(i4), allocatable :: eqLocalInField(:)
    
    ! Boundary condition data
    integer(i4), allocatable :: dofMask(:)
    real(wp),    allocatable :: constrained_value(:)
  contains
    final :: RT_Sol_DofMap_Finalize
  end type RT_Sol_DofMap

  ! ===================================================================
  ! CSR Matrix Type
  ! ===================================================================
  type, public :: RT_CSRMatrix
    integer(i4) :: nRows = 0_i4
    integer(i4) :: nCols = 0_i4
    integer(i4) :: nnz = 0_i4
    integer(i4), allocatable :: rowPtr(:)
    integer(i4), allocatable :: colInd(:)
    real(wp), allocatable :: values(:)
    logical :: is_symmetric = .false.
    logical :: init = .false.
  contains
    procedure :: matvec
  end type RT_CSRMatrix

  ! ===================================================================
  ! Solver State Type
  ! ===================================================================
  type, public :: RT_Sol_State
    ! Solution vectors (unified memory: pointer + id)
    real(wp), pointer :: u(:) => null()          ! Current displacement (total inc)
    integer(i4) :: u_id = -1
    real(wp), pointer :: du(:) => null()         ! Displacement increment/correction
    integer(i4) :: du_id = -1
    real(wp), pointer :: u_ref(:) => null()      ! Reference displacement
    integer(i4) :: u_ref_id = -1
    real(wp), pointer :: R(:) => null()          ! Residual vector
    integer(i4) :: R_id = -1
    real(wp), pointer :: F_ext(:) => null()     ! External load vector
    integer(i4) :: F_ext_id = -1
    real(wp), pointer :: F_int(:) => null()     ! Internal force vector
    integer(i4) :: F_int_id = -1
    real(wp), pointer :: R_int(:) => null()      ! Internal residual
    integer(i4) :: R_int_id = -1
    
    ! Matrix
    type(RT_CSRMatrix) :: K                ! Tangent stiffness matrix
    
    ! Load factor
    real(wp) :: lambda = 1.0_wp            ! Current load factor
    
    ! State flags
    logical :: initialized = .false.
    integer(i4) :: nDOF = 0_i4
    ! Linear solver statistics
    integer(i4) :: nLinearIter = 0_i4
    real(wp)    :: linearResidual = 0.0_wp
    real(wp)    :: linearSolveTime = 0.0_wp
    ! Nonlinear result
    integer(i4) :: nNewtonIter = 0_i4
    integer(i4) :: nlConverged = 0_i4
    real(wp)    :: nlResidualNorm = 0.0_wp
    real(wp)    :: nlDispNorm = 0.0_wp
    real(wp)    :: nlEnergyNorm = 0.0_wp
    ! Arc-length result
    real(wp)    :: nlLoadFactor = 0.0_wp
    real(wp)    :: nlArcLength  = 0.0_wp
    ! Condition and error estimation
    real(wp)    :: last_condition = 0.0_wp
    real(wp)    :: last_error_esti   = 0.0_wp
  contains
    procedure, public :: Init => RT_Sol_State_Init
    procedure, public :: Destroy => RT_Sol_State_Destroy
    procedure, public :: Clear => RT_Sol_State_Clear
  end type RT_Sol_State

  !=============================================================================
  ! DRIVER STATUS TYPES
  !=============================================================================

  type, public :: UF_RT_JobStatus
    integer(i4) :: code    = 0_i4  ! Status code
    character(len=256) :: message = ''
    integer(i4) :: id = 0_i4
    integer(i4) :: incId  = 0_i4
    
    integer(i4) :: nStepsTotal      = 0_i4
    integer(i4) :: nStepsCompleted  = 0_i4
    integer(i4) :: nIncsTotal       = 0_i4
    integer(i4) :: nIncsConverged   = 0_i4
    integer(i4) :: totalNewtonIter  = 0_i4
    integer(i4) :: maxNewtonIter    = 0_i4
    integer(i4) :: totalLinearIter  = 0_i4
    integer(i4) :: maxLinearIter    = 0_i4
  end type UF_RT_JobStatus

  integer(i4), parameter, public :: UF_JobStatus_Success = 0_i4

contains

  !=============================================================================
  ! RT_Sol_DofMap Finalizer
  !=============================================================================
  subroutine RT_Sol_DofMap_Finalize(this)
    type(RT_Sol_DofMap), intent(inout) :: this
    
    if (allocated(this%nodeToEqStart)) deallocate(this%nodeToEqStart)
    if (allocated(this%nodeNumDof)) deallocate(this%nodeNumDof)
    if (allocated(this%eqToNode)) deallocate(this%eqToNode)
    if (allocated(this%eqToLocal)) deallocate(this%eqToLocal)
    if (allocated(this%eqFieldId)) deallocate(this%eqFieldId)
    if (allocated(this%fieldEqCount)) deallocate(this%fieldEqCount)
    if (allocated(this%eqLocalInField)) deallocate(this%eqLocalInField)
    if (allocated(this%dofMask)) deallocate(this%dofMask)
    if (allocated(this%constrained_value)) deallocate(this%constrained_value)
  end subroutine RT_Sol_DofMap_Finalize


  !=============================================================================
  ! RT_CSRMatrix Procedures
  !=============================================================================
  subroutine RT_CSRMatrix_matvec(this, x, y)
    class(RT_CSRMatrix), intent(in) :: this
    real(wp), intent(in) :: x(:)
    real(wp), intent(out) :: y(:)
    
    integer(i4) :: i, j, k
    
    y = 0.0_wp
    
    if (.not. this%init .or. size(x) /= this%nCols .or. size(y) /= this%nRows) then
      return
    end if
    
    do i = 1, this%nRows
      do k = this%rowPtr(i), this%rowPtr(i+1) - 1
        j = this%colInd(k)
        y(i) = y(i) + this%values(k) * x(j)
      end do
    end do
  end subroutine RT_CSRMatrix_matvec

  !=============================================================================
  ! RT_Sol_State Procedures
  !=============================================================================
  subroutine RT_Sol_State_Init(this, nDOF)
    class(RT_Sol_State), intent(inout) :: this
    integer(i4), intent(in) :: nDOF
    type(ErrorStatusType) :: st
    
    if (nDOF <= 0_i4) then
      this%initialized = .false.
      this%nDOF = 0_i4
      return
    end if
    
    call init_error_status(st)
    ! Note: Memory allocation would go here, but simplified for now
    ! In full implementation, would call UF_Mem_AllocReal1D
    
    this%lambda = 1.0_wp
    this%nDOF = nDOF
    this%initialized = .true.
  end subroutine RT_Sol_State_Init

  subroutine RT_Sol_State_Destroy(this)
    class(RT_Sol_State), intent(inout) :: this
    
    ! Nullify pointers
    if (associated(this%u)) nullify(this%u)
    if (associated(this%du)) nullify(this%du)
    if (associated(this%u_ref)) nullify(this%u_ref)
    if (associated(this%R)) nullify(this%R)
    if (associated(this%F_ext)) nullify(this%F_ext)
    if (associated(this%F_int)) nullify(this%F_int)
    if (associated(this%evo%R_int)) nullify(this%evo%R_int)
    
    if (this%K%init) then
      if (allocated(this%K%rowPtr)) deallocate(this%K%rowPtr)
      if (allocated(this%K%colInd)) deallocate(this%K%colInd)
      if (allocated(this%K%values)) deallocate(this%K%values)
      this%K%init = .false.
    end if
    
    this%initialized = .false.
    this%nDOF = 0_i4
    this%lambda = 1.0_wp
  end subroutine RT_Sol_State_Destroy

  subroutine RT_Sol_State_Clear(this)
    class(RT_Sol_State), intent(inout) :: this
    
    if (.not. this%initialized) return
    
    if (associated(this%u)) this%u = 0.0_wp
    if (associated(this%du)) this%du = 0.0_wp
    if (associated(this%u_ref)) this%u_ref = 0.0_wp
    if (associated(this%R)) this%R = 0.0_wp
    if (associated(this%F_ext)) this%F_ext = 0.0_wp
    if (associated(this%F_int)) this%F_int = 0.0_wp
    if (associated(this%evo%R_int)) this%evo%R_int = 0.0_wp
    
    if (this%K%init) then
      if (allocated(this%K%rowPtr)) deallocate(this%K%rowPtr)
      if (allocated(this%K%colInd)) deallocate(this%K%colInd)
      if (allocated(this%K%values)) deallocate(this%K%values)
      this%K%init = .false.
    end if
    this%K%nRows = 0_i4
    this%K%nCols = 0_i4
    this%K%nnz = 0_i4
    
    this%lambda = 1.0_wp
    this%last_condition = 0.0_wp
    this%last_error_esti   = 0.0_wp
  end subroutine RT_Sol_State_Clear

END MODULE RT_Shared_Def
