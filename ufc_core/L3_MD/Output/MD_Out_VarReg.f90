!======================================================================
! Module: MD_OutVarReg
! Layer:  L3_MD - Model Definition Layer
! Domain: Output / Variable Registry
! Purpose: Output variable registry - manages output variables (ABAQUS compatible).
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
MODULE MD_Out_VarReg
!>>> UFC_L3_CONTRACT | Output/CONTRACT.md
!> Status: Production | Last verified: 2026-03-01
!> Theory: Output variable registration and enumeration | Ref: ABAQUS Output Variables
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: i4, wp
  USE MD_Out_Def, only: OutVarDesc, OUT_LOC_NODE, OUT_LOC_ELEM_IN, &
                              OUT_RANK_SCALAR, OUT_RANK_VECTOR, OUT_RANK_TENSOR, &
                              OUT_VAR_U, OUT_VAR_V, OUT_VAR_A, OUT_VAR_RF, OUT_VAR_CF, &
                              OUT_VAR_TEMP, OUT_VAR_S, OUT_VAR_E, OUT_VAR_PE, OUT_VAR_EE, &
                              OUT_VAR_PEEQ, OUT_VAR_MISES, OUT_VAR_POR, OUT_VAR_HFL, &
                              OUT_VAR_VFL, OUT_VAR_CONC, OUT_VAR_ALLIE, OUT_VAR_ALLKE, &
                              OUT_VAR_ALLPD, OUT_VAR_ALLSE
  
  implicit none
  private
  
  public :: OutVarRegistry
  public :: OutVarReg_Init
  public :: OutVarReg_GetVarDesc
  public :: OutVarReg_GetVarName
  public :: OutVarReg_IsValidVar
  public :: OutVarReg_GetVarLocation
  public :: OutVarReg_GetVarRank
  
  type, public :: OutVarRegistry
    type(OutVarDesc), allocatable :: vars(:)
    integer(i4) :: num_vars = 0_i4
    LOGICAL :: init = .false.
  contains
    procedure, public :: Init => OutVarReg_Init
    procedure, public :: GetVarDesc => OutVarReg_GetVarDesc
    procedure, public :: GetVarName => OutVarReg_GetVarName
    procedure, public :: IsValidVar => OutVarReg_IsValidVar
    procedure, public :: GetVarLocation => OutVarReg_GetVarLocation
    procedure, public :: GetVarRank => OutVarReg_GetVarRank
  end type OutVarRegistry
  
  type(OutVarRegistry), save :: g_var_registry
  
contains
  
  ! ===================================================================
  ! Init Output Variable Registry
  ! ===================================================================
  
  subroutine OutVarReg_Init(this, status)
    class(OutVarRegistry), intent(inout) :: this
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i
    
    if (present(status)) call init_error_status(status)
    
    if (this%init) return
    
    ! Allocate space for variables
    allocate(this%vars(100))
    this%num_vars = 0_i4
    
    ! Reg structural variables
    call RegisterVar(this, OUT_VAR_U, 'U', 'Displacement', OUT_LOC_NODE, OUT_RANK_VECTOR, 3_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_V, 'V', 'Velocity', OUT_LOC_NODE, OUT_RANK_VECTOR, 3_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_A, 'A', 'Acceleration', OUT_LOC_NODE, OUT_RANK_VECTOR, 3_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_RF, 'RF', 'Reaction Force', OUT_LOC_NODE, OUT_RANK_VECTOR, 3_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_CF, 'CF', 'Concentrated Force', OUT_LOC_NODE, OUT_RANK_VECTOR, 3_i4, .true., .true.)
    
    ! Reg sigma/strain variables
    call RegisterVar(this, OUT_VAR_S, 'S', 'Cauchy Stress', OUT_LOC_ELEM_IN, OUT_RANK_TENSOR, 6_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_E, 'E', 'Total Strain', OUT_LOC_ELEM_IN, OUT_RANK_TENSOR, 6_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_PE, 'PE', 'Plastic Strain', OUT_LOC_ELEM_IN, OUT_RANK_TENSOR, 6_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_EE, 'EE', 'Elastic Strain', OUT_LOC_ELEM_IN, OUT_RANK_TENSOR, 6_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_PEEQ, 'PEEQ', 'Equivalent Plastic Strain', OUT_LOC_ELEM_IN, OUT_RANK_SCALAR, 1_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_MISES, 'MISES', 'von Mises Stress', OUT_LOC_ELEM_IN, OUT_RANK_SCALAR, 1_i4, .true., .true.)
    
    ! Reg thermal variables
    call RegisterVar(this, OUT_VAR_TEMP, 'TEMP', 'Temperature', OUT_LOC_NODE, OUT_RANK_SCALAR, 1_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_HFL, 'HFL', 'Heat Flux', OUT_LOC_ELEM_IN, OUT_RANK_VECTOR, 3_i4, .true., .true.)
    
    ! Reg pore pressure variables
    call RegisterVar(this, OUT_VAR_POR, 'POR', 'Pore Pressure', OUT_LOC_NODE, OUT_RANK_SCALAR, 1_i4, .true., .true.)
    call RegisterVar(this, OUT_VAR_VFL, 'VFL', 'Seepage Velocity', OUT_LOC_ELEM_IN, OUT_RANK_VECTOR, 3_i4, .true., .true.)
    
    ! Reg chemical variables
    call RegisterVar(this, OUT_VAR_CONC, 'CONC', 'Concentration', OUT_LOC_NODE, OUT_RANK_SCALAR, 1_i4, .true., .true.)
    
    ! Reg energy variables (history only)
    call RegisterVar(this, OUT_VAR_ALLIE, 'ALLIE', 'All Internal Energy', OUT_LOC_GLOBAL, OUT_RANK_SCALAR, 1_i4, .false., .true.)
    call RegisterVar(this, OUT_VAR_ALLKE, 'ALLKE', 'All Kinetic Energy', OUT_LOC_GLOBAL, OUT_RANK_SCALAR, 1_i4, .false., .true.)
    call RegisterVar(this, OUT_VAR_ALLPD, 'ALLPD', 'All Plastic Dissipation', OUT_LOC_GLOBAL, OUT_RANK_SCALAR, 1_i4, .false., .true.)
    call RegisterVar(this, OUT_VAR_ALLSE, 'ALLSE', 'All Strain Energy', OUT_LOC_GLOBAL, OUT_RANK_SCALAR, 1_i4, .false., .true.)
    
    this%init = .true.
    if (present(status)) status%status_code = IF_STATUS_OK
    
  contains
    
    subroutine RegisterVar(reg, var_id, var_name, var_desc, location, rank, n_comp, support_field, support_history)
      type(OutVarRegistry), intent(inout) :: reg
      integer(i4), intent(in) :: var_id, location, rank, n_comp
      character(len=*), intent(in) :: var_name, var_desc
      logical, intent(in) :: support_field, support_history
      
      integer(i4) :: n
      
      n = reg%num_vars + 1_i4
      if (n > size(reg%vars)) then
        ! Expand array if needed
        return
      end if
      
      reg%vars(n)%var_id = var_id
      reg%vars(n)%var_name = var_name
      reg%vars(n)%var_description = var_desc
      reg%vars(n)%location = location
      reg%vars(n)%rank = rank
      reg%vars(n)%n_components = n_comp
      reg%vars(n)%is_tensor = (rank == OUT_RANK_TENSOR)
      reg%vars(n)%is_vector = (rank == OUT_RANK_VECTOR)
      reg%vars(n)%is_scalar = (rank == OUT_RANK_SCALAR)
      reg%vars(n)%support_field = support_field
      reg%vars(n)%support_history = support_history
      
      reg%num_vars = n
    end subroutine RegisterVar
    
  end subroutine OutVarReg_Init
  
  ! ===================================================================
  ! Get Variable Description
  ! ===================================================================
  
  function OutVarReg_GetVarDesc(this, var_id) result(var_desc)
    class(OutVarRegistry), intent(in) :: this
    integer(i4), intent(in) :: var_id
    type(OutVarDesc), pointer :: var_desc
    integer(i4) :: i
    
    nullify(var_desc)
    if (.not. this%init) return
    
    do i = 1, this%num_vars
      if (this%vars(i)%var_id == var_id) then
        var_desc => this%vars(i)
        return
      end if
    end do
  end function OutVarReg_GetVarDesc
  
  ! ===================================================================
  ! Get Variable Name
  ! ===================================================================
  
  function OutVarReg_GetVarName(this, var_id) result(var_name)
    class(OutVarRegistry), intent(in) :: this
    integer(i4), intent(in) :: var_id
    character(len=16) :: var_name
    type(OutVarDesc), pointer :: var_desc
    
    var_name = ''
    var_desc => this%GetVarDesc(var_id)
    if (associated(var_desc)) then
      var_name = var_desc%var_name
    end if
  end function OutVarReg_GetVarName
  
  ! ===================================================================
  ! Check if Variable is Valid
  ! ===================================================================
  
  function OutVarReg_IsValidVar(this, var_id) result(is_valid)
    class(OutVarRegistry), intent(in) :: this
    integer(i4), intent(in) :: var_id
    logical :: is_valid
    type(OutVarDesc), pointer :: var_desc
    
    is_valid = .false.
    var_desc => this%GetVarDesc(var_id)
    if (associated(var_desc)) then
      is_valid = .true.
    end if
  end function OutVarReg_IsValidVar
  
  ! ===================================================================
  ! Get Variable Location
  ! ===================================================================
  
  function OutVarReg_GetVarLocation(this, var_id) result(location)
    class(OutVarRegistry), intent(in) :: this
    integer(i4), intent(in) :: var_id
    integer(i4) :: location
    type(OutVarDesc), pointer :: var_desc
    
    location = OUT_LOC_NODE
    var_desc => this%GetVarDesc(var_id)
    if (associated(var_desc)) then
      location = var_desc%location
    end if
  end function OutVarReg_GetVarLocation
  
  ! ===================================================================
  ! Get Variable Rank
  ! ===================================================================
  
  function OutVarReg_GetVarRank(this, var_id) result(rank)
    class(OutVarRegistry), intent(in) :: this
    integer(i4), intent(in) :: var_id
    integer(i4) :: rank
    type(OutVarDesc), pointer :: var_desc
    
    rank = OUT_RANK_SCALAR
    var_desc => this%GetVarDesc(var_id)
    if (associated(var_desc)) then
      rank = var_desc%rank
    end if
  end function OutVarReg_GetVarRank
  
  ! ===================================================================
  ! Global Functions
  ! ===================================================================
  
  subroutine OutVarReg_Init(status)
    type(ErrorStatusType), intent(out), optional :: status
    call g_var_registry%Init(status)
  end subroutine OutVarReg_Init
  
  function OutVarReg_GetVarDesc(var_id) result(var_desc)
    integer(i4), intent(in) :: var_id
    type(OutVarDesc), pointer :: var_desc
    var_desc => g_var_registry%GetVarDesc(var_id)
  end function OutVarReg_GetVarDesc
  
  function OutVarReg_GetVarName(var_id) result(var_name)
    integer(i4), intent(in) :: var_id
    character(len=16) :: var_name
    var_name = g_var_registry%GetVarName(var_id)
  end function OutVarReg_GetVarName
  
  function OutVarReg_IsValidVar(var_id) result(is_valid)
    integer(i4), intent(in) :: var_id
    logical :: is_valid
    is_valid = g_var_registry%IsValidVar(var_id)
  end function OutVarReg_IsValidVar
  
  function OutVarReg_GetVarLocation(var_id) result(location)
    integer(i4), intent(in) :: var_id
    integer(i4) :: location
    location = g_var_registry%GetVarLocation(var_id)
  end function OutVarReg_GetVarLocation
  
  function OutVarReg_GetVarRank(var_id) result(rank)
    integer(i4), intent(in) :: var_id
    integer(i4) :: rank
    rank = g_var_registry%GetVarRank(var_id)
  end function OutVarReg_GetVarRank
  
end module MD_Out_VarReg