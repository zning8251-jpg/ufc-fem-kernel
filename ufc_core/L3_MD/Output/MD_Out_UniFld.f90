!===============================================================================
! Module: MD_UniFld
! Layer:  L3_MD - Model Definition Layer
! Domain: Ctx - Context
! Purpose: Unified field type system and field manager for multi-physics simulation
! Theory: Unified field framework for multi-physics coupling:
!   - Field types: Displacement u ?ℝ^n_dof, temperature T ? ? pressure p ? ?
!     electric potential φ_e ? ? magnetic potential φ_m ? ? chemical potential μ ? ?
!   - Field state: Current values φ(t), velocities dφ/dt, accelerations d²φ/dt²
!   - Field history: φ(t-Δt), φ(t-2Δt), ... for time integration
!   - Field coupling: One-way, two-way, full coupling between fields
!   - Integration: Structural kinematics (strain ε, deformation gradient F, B-matrix),
!     thermal coefficients (k_cond, ϝ, c_p), poro coefficients (α_b, k_hyd, S_s),
!     THM coefficients (combined thermal-poro-structural)
! References:
!   - Zienkiewicz, O.C. & Taylor, R.L. (2005). The Finite Element Method, 6th ed.
!   - Felippa, C.A. "Introduction to Finite Element Methods"
! Status:  Phase B | Last verified: 2026-03-11
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Out | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Output/CONTRACT.md

MODULE MD_Out_UniFld
!>>> UFC_L3_CONTRACT | Output/CONTRACT.md

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
  USE IF_Prec_Core,        only: wp, i4, i8
  USE MD_Base_ElemLib, ONLY: UF_GetGaussPoints, UF_GetShapeFunctions, UF_ComputeJacobian
  USE MD_Base_ObjModel,     only: UF_StateObject, CAT_STATE
  USE MD_Elem_Base, ONLY: UF_Form_UL, UF_Int_Reduced, UF_Topo_Hex, UF_Topo_Quad, UF_Topo_Wedge
  USE MD_Elem_Types, ONLY: ShapeFuncResult
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx
  USE MD_Field_Mgr, only: Kinematics, ThermPointState, PoroPointState, THMPointState, MD_IPStaSta
  USE MD_Mat_Lib, only: MatProps
  use MD_Sect_Mgr, only: UF_Section_GetDescriptor, MatDesc
  use MD_UniFldRT_Brg, only: ContmMatRes, MD_RT_UniFld_EvalStructAtIp, MD_RT_UniFld_IntegrateIp

  implicit none
  private

  ! ===================================================================
  ! Public Types and Procedures
  ! ===================================================================
  public :: MD_FieldType
  public :: MD_Field_Mgr
  public :: MD_FieldDesc
  public :: MD_FieldManager
  public :: MD_FieldCoupling
  public :: MD_FieldCouplingType

  public :: MD_FIELD_DISPLACEMENT
  public :: MD_FIELD_TEMPERATURE
  public :: MD_FIELD_PRESSURE
  public :: MD_FIELD_ELECTRIC
  public :: MD_FIELD_MAGNETIC
  public :: MD_FIELD_CHEMICAL
  public :: MD_FIELD_UNKNOWN
  public :: MD_FIELD_ROTATION
  public :: MD_FIELD_QUANTUM
  public :: MD_FIELD_GRAVITATIONAL
  public :: MD_FIELD_BIOLOGICAL

  public :: MD_SYS_FIRST_ORDER
  public :: MD_SYS_SECOND_ORDER
  public :: MD_SYS_MIXED

  public :: GetFieldTypeName
  public :: GetFieldDOFs
  public :: GetFieldOrder

  public :: MD_FldEq
  public :: MD_FldSysType
  public :: MD_UniFldSys
  public :: MD_UniFldMgr
  public :: MD_FldCplDesc

  public :: MD_FldStaSnap
  public :: MD_FldStaHist
  public :: MD_UniFldSta
  public :: MD_FldStaMgr

  public :: MD_StructFld
  public :: MD_ThermalFld
  public :: MD_FluidFld
  public :: MD_ElectroMagFld
  public :: MD_ChemicalFld
  public :: MD_BiologicalFld
  public :: MD_QuantumFld
  public :: MD_GravitationalFld

  public :: MD_FieldInitDesc
  public :: MD_ThermalFieldInitDesc
  public :: MD_ChemicalFieldInitDesc
  public :: MD_BiologicalFieldInitDesc

  public :: MD_CreateStructFld
  public :: MD_CreateThermalFld
  public :: MD_CreateFluidFld
  public :: MD_CreateElectroMagFld
  public :: MD_CreateChemicalFld
  public :: MD_CreateBiologicalFld
  public :: MD_CreateQuantumFld
  public :: MD_CreateGravitationalFld

  public :: ContIpKernel, DiffIpKernel
  public :: GetContOrder, GetEffOrder
  public :: ContGauss, DiffGauss
  public :: ComputeKinematics
  public :: KineEval
  public :: UF_ContTh_MakeCoeffsFromContext, UF_ContTh_AllocCapacity
  public :: UF_ContPoro_MakeCoeffsFromContext, UF_ContPoro_AllocCapacity
  public :: UF_ContTHM_EvalMaterial, UF_ContTHM_AllocCtt, UF_ContTHM_AllocSpp
  public :: StructMatRes
  public :: StructGetSectionDesc, StructIntegrateIp
  public :: ThermCoeffs, ThermAllocCtt
  public :: PoroCoeffs, PoroAllocSpp
  public :: UF_Phys_THM_EvalMaterial
  public :: UF_ContTHM_AllocCtt, UF_ContTHM_AllocSpp

  public :: DiffIpKernel_Proc
  public :: ThermCoeffs_Proc
  public :: PoroCoeffs_Proc

  ! ===================================================================
  ! Abstract Interfaces (from MD_UniFld_ElemTypes)
  ! ===================================================================
  abstract interface
    subroutine DiffIpKernel_Proc(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)
      import :: wp, i4, ShapeFuncResult
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in)  :: field_ip
      real(wp), intent(in)  :: field_old_ip
      real(wp), intent(out) :: k_eff_ip
      real(wp), intent(out) :: C_eff_ip
    end subroutine DiffIpKernel_Proc
  end interface

  abstract interface
    subroutine ThermCoeffs_Proc(matModel, Ctx, k_cond, rho, c_p, alphaT, flag_th_exp, &
                                  hasTransient, thState, ierr_material)
      import :: wp, i4, ElemCtx, ThermPointState
      class(*), intent(in)  :: matModel
      type(ElemCtx), intent(in)  :: Ctx
      real(wp), intent(out) :: k_cond, rho, c_p
      real(wp), intent(out) :: alphaT
      real(wp), intent(out) :: flag_th_exp
      logical, intent(out) :: hasTransient
      type(ThermPointState), intent(out) :: thState
      integer(i4), intent(out) :: ierr_material
    end subroutine ThermCoeffs_Proc
  end interface

  abstract interface
    subroutine PoroCoeffs_Proc(matModel, Ctx, alpha_b, k_hyd, S_s, rho_f, cp_f, flag_vol, &
                               hasTransient, prState, ierr_material)
      import :: wp, i4, ElemCtx, PoroPointState
      class(*), intent(in)  :: matModel
      type(ElemCtx), intent(in)  :: Ctx
      real(wp), intent(out) :: alpha_b, k_hyd, S_s
      real(wp), intent(out) :: rho_f, cp_f
      real(wp), intent(out) :: flag_vol
      logical, intent(out) :: hasTransient
      type(PoroPointState), intent(out) :: prState
      integer(i4), intent(out) :: ierr_material
    end subroutine PoroCoeffs_Proc
  end interface

  ! ===================================================================
  ! Field Type Enumeration
  ! ===================================================================
  integer(i4), parameter, public :: MD_FIELD_DISPLACEMENT = 1_i4
  integer(i4), parameter, public :: MD_FIELD_TEMPERATURE  = 2_i4
  integer(i4), parameter, public :: MD_FIELD_PRESSURE     = 3_i4
  integer(i4), parameter, public :: MD_FIELD_ELECTRIC    = 4_i4
  integer(i4), parameter, public :: MD_FIELD_MAGNETIC    = 5_i4
  integer(i4), parameter, public :: MD_FIELD_CHEMICAL    = 6_i4
  integer(i4), parameter, public :: MD_FIELD_ROTATION    = 7_i4
  integer(i4), parameter, public :: MD_FIELD_QUANTUM     = 8_i4
  integer(i4), parameter, public :: MD_FIELD_GRAVITATIONAL = 9_i4
  integer(i4), parameter, public :: MD_FIELD_BIOLOGICAL  = 10_i4
  integer(i4), parameter, public :: MD_FIELD_UNKNOWN     = 0_i4

  ! System type enumeration
  integer(i4), parameter, public :: MD_SYS_FIRST_ORDER = 1_i4
  integer(i4), parameter, public :: MD_SYS_SECOND_ORDER = 2_i4
  integer(i4), parameter, public :: MD_SYS_MIXED = 3_i4

  ! ===================================================================
  ! Field Coupling Type Enumeration
  ! ===================================================================
  integer(i4), parameter, public :: MD_CPL_NONE         = 0_i4
  integer(i4), parameter, public :: MD_CPL_ONE_WAY       = 1_i4
  integer(i4), parameter, public :: MD_CPL_TWO_WAY       = 2_i4
  integer(i4), parameter, public :: MD_CPL_FULL          = 3_i4

  !=============================================================================
  !> @brief Field coupling type
  !! @details Defines coupling between two fields
  !! Theory: Coupling type (none, one-way, two-way, full), coupling coefficient α_cpl ? ?
  type, public :: MD_FieldCpl
    integer(i4) :: field1_type = MD_FIELD_UNKNOWN    ! First field type  ? ?
    integer(i4) :: field2_type = MD_FIELD_UNKNOWN      ! Second field type  ? ?
    integer(i4) :: coupling_type = MD_CPL_NONE         ! Coupling type  ? ?
    logical     :: active = .false.                     ! Active flag
    real(wp)    :: coupling_coeff = 1.0_wp             ! Coupling coefficient α_cpl  ? ?
  contains
    procedure, public :: Init
    procedure, public :: IsActive
  end type MD_FieldCpl
  
  !=============================================================================
  !> @brief Field state type
  !! @details Stores field values, velocities, accelerations, and history
  !!   Theory: Field state φ(t), velocities dφ/dt, accelerations d²φ/dt², history φ(t-Δt)
  type, public :: MD_Field_Mgr
    integer(i4)       :: fieldId    = 0_i4              ! Field ID  ? ?
    integer(i4)       :: fieldType   = MD_FIELD_UNKNOWN ! Field type  ? ?
    character(len=64)  :: fieldName   = ""               ! Field name
    integer(i4)       :: nDOFs       = 0_i4             ! Number of DOFs n_dof  ? ?
    integer(i4)       :: order       = 1_i4             ! Field order  ? ?

    real(wp), allocatable :: values(:)                  ! Current values φ(t)  ?ℝ^n_dof
    real(wp), allocatable :: velocities(:)             ! Velocities dφ/dt  ?ℝ^n_dof
    real(wp), allocatable :: accelerations(:)           ! Accelerations d²φ/dt²  ?ℝ^n_dof
    real(wp), allocatable :: values_old(:)             ! Previous values φ(t-Δt)  ?ℝ^n_dof
    real(wp), allocatable :: velocities_old(:)         ! Previous velocities  ?ℝ^n_dof

    logical :: hasHistory = .false.                     ! History flag
    integer(i4) :: nHistory = 0_i4                     ! Number of history steps n_hist  ? ?
    real(wp), allocatable :: history(:,:)              ! History array  ?ℝ^(n_dof×n_hist)

    logical :: isConstrained = .false.                  ! Constrained flag
    logical, allocatable :: isFixed(:)                  ! Fixed DOF flags
    real(wp), allocatable :: prescribedvalue(:)        ! Prescribed values  ?ℝ^n_dof
  contains
    procedure, public :: Init
    procedure, public :: AllocateDOFs
    procedure, public :: SetValues
    procedure, public :: GetValues
    procedure, public :: UpdateHistory
    procedure, public :: GetHistory
    procedure, public :: ApplyConstraints
    procedure, public :: GetConstrainedDOFs
  end type MD_Field_Mgr
  
  !=============================================================================
  !> @brief Field description type
  !! @details Describes field properties (type, DOF range, active status)
  !!   Theory: Field descriptor with DOF range [start_dof, end_dof], order, active/transient flags
  type, public :: MD_FieldDesc
    integer(i4)       :: fieldId    = 0_i4              ! Field ID  ? ?
    integer(i4)       :: fieldType   = MD_FIELD_UNKNOWN ! Field type  ? ?
    character(len=64)  :: fieldName   = ""               ! Field name
    character(len=256) :: description = ""              ! Description
    integer(i4)       :: nDOFs       = 0_i4             ! Number of DOFs n_dof  ? ?
    integer(i4)       :: order       = 1_i4             ! Field order  ? ?
    integer(i4)       :: startDOF    = 0_i4             ! Start DOF index  ? ?
    integer(i4)       :: endDOF      = 0_i4             ! End DOF index  ? ?
    logical           :: isActive     = .true.          ! Active flag
    logical           :: isTransient  = .true.          ! Transient flag
    logical           :: isNonlinear  = .false.          ! Nonlinear flag

    real(wp) :: min_value = -huge(1.0_wp)              ! Minimum value φ_min  ? ?
    real(wp) :: max_value = huge(1.0_wp)                ! Maximum value φ_max  ? ?
    real(wp) :: default_value = 0.0_wp                  ! Default value φ_default  ? ?
  contains
    procedure, public :: Init
    procedure, public :: SetDOFRange
    procedure, public :: GetDOFRange
  end type MD_FieldDesc
  
  !=============================================================================
  !> @brief Field initialization descriptor (Desc category)
  !! @details Encapsulates field initialization parameters to avoid exposing member names
  !!   Theory: Field initialization descriptor with field_id, n_nodes, n_dimensions
  !!   This Desc class follows L3_MD layer structured parameter passing rules
  type, public :: MD_FieldInitDesc
    integer(i4) :: field_id = 0_i4                      ! Field ID  ? ?
    integer(i4) :: n_nodes = 0_i4                       ! Number of nodes n_nodes  ? ?
    integer(i4) :: n_dimensions = 0_i4                  ! Number of dimensions n_dim  ? ?
  end type MD_FieldInitDesc
  
  !=============================================================================
  !> @brief Thermal field initialization descriptor (Desc category)
  !! @details Encapsulates thermal field initialization parameters
  type, public :: MD_ThermalFieldInitDesc
    integer(i4) :: field_id = 0_i4                      ! Field ID  ? ?
    integer(i4) :: n_nodes = 0_i4                       ! Number of nodes n_nodes  ? ?
  end type MD_ThermalFieldInitDesc
  
  !=============================================================================
  !> @brief Chemical field initialization descriptor (Desc category)
  !! @details Encapsulates chemical field initialization parameters
  type, public :: MD_ChemicalFieldInitDesc
    integer(i4) :: field_id = 0_i4                      ! Field ID  ? ?
    integer(i4) :: n_nodes = 0_i4                       ! Number of nodes n_nodes  ? ?
    integer(i4) :: n_species = 0_i4                     ! Number of species n_species  ? ?
  end type MD_ChemicalFieldInitDesc
  
  !=============================================================================
  !> @brief Biological field initialization descriptor (Desc category)
  !! @details Encapsulates biological field initialization parameters
  type, public :: MD_BiologicalFieldInitDesc
    integer(i4) :: field_id = 0_i4                      ! Field ID  ? ?
    integer(i4) :: n_nodes = 0_i4                       ! Number of nodes n_nodes  ? ?
    integer(i4) :: n_cell_types = 0_i4                  ! Number of cell types n_cell_types  ? ?
  end type MD_BiologicalFieldInitDesc
  
  !=============================================================================
  !> @brief Field manager type
  !! @details Manages multiple fields, states, and couplings
  !!   Theory: Manager with n_fields fields, total n_dofs_total DOFs, field/state arrays, DOF mapping
  type, public :: MD_FieldManager
    logical :: isInitialized = .false.                  ! Initialization flag

    integer(i4) :: nFields = 0_i4                       ! Number of fields n_fields  ? ?
    integer(i4) :: nDOFsTotal = 0_i4                    ! Total DOFs n_dofs_total  ? ?

    type(MD_FieldDesc), allocatable :: fields(:)       ! Field descriptions array
    type(MD_Field_Mgr), allocatable :: fieldStates(:)  ! Field states array
    type(MD_FieldCpl), allocatable :: couplings(:)      ! Field couplings array

    integer(i4), allocatable :: fieldDOFMap(:)          ! Field DOF mapping  ?ℤ^n_dofs_total
    integer(i4), allocatable :: globalDOFMap(:)         ! Global DOF mapping  ?ℤ^n_dofs_total
  contains
    procedure, public :: Init
    procedure, public :: RegisterField
    procedure, public :: GetFieldDesc
    procedure, public :: GetFieldState
    procedure, public :: GetFieldStateById
    procedure, public :: UpdateFieldState
    procedure, public :: AddCoupling
    procedure, public :: GetCoupling
    procedure, public :: GetTotalDOFs
    procedure, public :: GetFieldDOFMap
    procedure, public :: GetGlobalDOFMap
    procedure, public :: BuildDOFMap
    procedure, public :: Cleanup
  end type MD_FieldManager

contains

  ! ===================================================================
  ! Utility Functions
  ! ===================================================================
  function GetFieldTypeName(fieldType) result(name)
    integer(i4), intent(in) :: fieldType
    character(len=64) :: name

    select case (fieldType)
      case (MD_FIELD_DISPLACEMENT)
        name = "DISPLACEMENT"
      case (MD_FIELD_TEMPERATURE)
        name = "TEMPERATURE"
      case (MD_FIELD_PRESSURE)
        name = "PRESSURE"
      case (MD_FIELD_ELECTRIC)
        name = "ELECTRIC"
      case (MD_FIELD_MAGNETIC)
        name = "MAGNETIC"
      case (MD_FIELD_CHEMICAL)
        name = "CHEMICAL"
      case (MD_FIELD_ROTATION)
        name = "ROTATION"
      case (MD_FIELD_QUANTUM)
        name = "QUANTUM"
      case (MD_FIELD_GRAVITATIONAL)
        name = "GRAVITATIONAL"
      case (MD_FIELD_BIOLOGICAL)
        name = "BIOLOGICAL"
      case default
        name = "UNKNOWN"
    end select
  end function GetFieldTypeName

  function GetFieldDOFs(fieldType, nDim) result(nDOFs)
    integer(i4), intent(in) :: fieldType
    integer(i4), intent(in) :: nDim
    integer(i4) :: nDOFs

    select case (fieldType)
      case (MD_FIELD_DISPLACEMENT)
        nDOFs = nDim
      case (MD_FIELD_TEMPERATURE)
        nDOFs = 1_i4
      case (MD_FIELD_PRESSURE)
        nDOFs = 1_i4
      case (MD_FIELD_ELECTRIC)
        nDOFs = 1_i4
      case (MD_FIELD_MAGNETIC)
        nDOFs = 1_i4
      case (MD_FIELD_CHEMICAL)
        nDOFs = 1_i4
      case (MD_FIELD_ROTATION)
        nDOFs = nDim
      case (MD_FIELD_QUANTUM)
        nDOFs = 1_i4
      case (MD_FIELD_GRAVITATIONAL)
        nDOFs = 1_i4
      case (MD_FIELD_BIOLOGICAL)
        nDOFs = 1_i4
      case default
        nDOFs = 0_i4
    end select
  end function GetFieldDOFs

  function GetFieldOrder(fieldType) result(order)
    integer(i4), intent(in) :: fieldType
    integer(i4) :: order

    select case (fieldType)
      case (MD_FIELD_DISPLACEMENT)
        order = 2_i4
      case (MD_FIELD_TEMPERATURE)
        order = 1_i4
      case (MD_FIELD_PRESSURE)
        order = 1_i4
      case (MD_FIELD_ELECTRIC)
        order = 1_i4
      case (MD_FIELD_MAGNETIC)
        order = 1_i4
      case (MD_FIELD_CHEMICAL)
        order = 1_i4
      case (MD_FIELD_ROTATION)
        order = 2_i4
      case (MD_FIELD_QUANTUM)
        order = 1_i4
      case (MD_FIELD_GRAVITATIONAL)
        order = 2_i4
      case (MD_FIELD_BIOLOGICAL)
        order = 1_i4
      case default
        order = 1_i4
    end select
  end function GetFieldOrder

  !=============================================================================
  !> @brief Initialize field coupling (legacy interface)
  !! @details Initializes field coupling between two fields
  !! @param[inout] this Field coupling instance
  !! @param[in] field1_type First field type ? ?
  !! @param[in] field2_type Second field type ? ?
  !! @param[in] coupling_type Coupling type ? ?(optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !=============================================================================
  subroutine Init(this, field1_type, field2_type, coupling_type)
    class(MD_FieldCpl), intent(inout) :: this
    integer(i4),                intent(in)    :: field1_type, field2_type
    integer(i4),                intent(in), optional :: coupling_type

    this%field1_type = field1_type
    this%field2_type = field2_type
    if (present(coupling_type)) then
      this%coupling_type = coupling_type
    else
      this%coupling_type = MD_CPL_NONE
    end if
    this%active = (this%coupling_type /= MD_CPL_NONE)
    this%coupling_coeff = 1.0_wp
  end subroutine Init

  ! Original name: MD_FieldCpl_IsActive
  function IsActive(this) result(isActive)
    class(MD_FieldCpl), intent(in) :: this
    logical :: isActive
    isActive = this%active
  end function IsActive

  !=============================================================================
  !> @brief Initialize field state (legacy interface)
  !! @details Initializes field state with ID, type, name, DOFs, and order
  !! @param[inout] this Field state instance
  !! @param[in] fieldId Field ID ? ?
  !! @param[in] fieldType Field type ? ?
  !! @param[in] nDOFs Number of DOFs n_dof ? ?
  !! @param[in] fieldName Field name (optional)
  !! @param[in] order Field order ? ?(optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !=============================================================================
  subroutine Init(this, fieldId, fieldType, fieldName, nDOFs, order)
    class(MD_Field_Mgr), intent(inout) :: this
    integer(i4),             intent(in)    :: fieldId, fieldType, nDOFs
    character(len=*),         intent(in),    optional :: fieldName
    integer(i4),             intent(in),    optional :: order

    this%fieldId = fieldId
    this%fieldType = fieldType
    if (present(fieldName)) then
      this%fieldName = trim(fieldName)
    else
      this%fieldName = trim(GetFieldTypeName(fieldType))
    end if
    this%nDOFs = nDOFs
    if (present(order)) then
      this%order = order
    else
      this%order = GetFieldOrder(fieldType)
    end if
  end subroutine Init

  ! Original name: MD_Field_Mgr_AllocDOFs
  subroutine AllocateDOFs(this, nHistory)
    class(MD_Field_Mgr), intent(inout) :: this
    integer(i4),             intent(in),    optional :: nHistory

    if (this%nDOFs > 0) then
      allocate(this%values(this%nDOFs))
      this%values = 0.0_wp

      allocate(this%values_old(this%nDOFs))
      this%values_old = 0.0_wp

      if (this%order >= 1) then
        allocate(this%velocities(this%nDOFs))
        this%velocities = 0.0_wp

        allocate(this%velocities_old(this%nDOFs))
        this%velocities_old = 0.0_wp
      end if

      if (this%order >= 2) then
        allocate(this%accelerations(this%nDOFs))
        this%accelerations = 0.0_wp
      end if

      allocate(this%isFixed(this%nDOFs))
      this%isFixed = .false.

      allocate(this%prescribedvalue(this%nDOFs))
      this%prescribedvalue = 0.0_wp
    end if

    if (present(nHistory) .and. nHistory > 0) then
      this%hasHistory = .true.
      this%nHistory = nHistory
      allocate(this%history(this%nDOFs, nHistory))
      this%history = 0.0_wp
    end if
  end subroutine AllocateDOFs

  ! Original name: MD_Field_Mgr_SetVals
  subroutine SetValues(this, values, velocities, accelerations)
    class(MD_Field_Mgr), intent(inout) :: this
    real(wp),             intent(in)    :: values(:)
    real(wp),             intent(in), optional :: velocities(:), accelerations(:)

    integer(i4) :: i, n

    n = min(size(values), this%nDOFs)
    do i = 1, n
      this%values(i) = values(i)
    end do

    if (present(velocities) .and. allocated(this%velocities)) then
      n = min(size(velocities), this%nDOFs)
      do i = 1, n
        this%velocities(i) = velocities(i)
      end do
    end if

    if (present(accelerations) .and. allocated(this%accelerations)) then
      n = min(size(accelerations), this%nDOFs)
      do i = 1, n
        this%accelerations(i) = accelerations(i)
      end do
    end if
  end subroutine SetValues

  ! Original name: MD_Field_Mgr_GetVals
  subroutine GetValues(this, values, velocities, accelerations)
    class(MD_Field_Mgr), intent(in) :: this
    real(wp),             intent(out)   :: values(:)
    real(wp),             intent(out), optional :: velocities(:), accelerations(:)

    integer(i4) :: i, n

    n = min(size(values), this%nDOFs)
    do i = 1, n
      values(i) = this%values(i)
    end do

    if (present(velocities) .and. allocated(this%velocities)) then
      n = min(size(velocities), this%nDOFs)
      do i = 1, n
        velocities(i) = this%velocities(i)
      end do
    end if

    if (present(accelerations) .and. allocated(this%accelerations)) then
      n = min(size(accelerations), this%nDOFs)
      do i = 1, n
        accelerations(i) = this%accelerations(i)
      end do
    end if
  end subroutine GetValues

  ! Original name: MD_Field_Mgr_UpdHist
  subroutine UpdateHistory(this)
    class(MD_Field_Mgr), intent(inout) :: this

    integer(i4) :: i, j

    if (.not. this%hasHistory) return

    do j = this%nHistory, 2, -1
      do i = 1, this%nDOFs
        this%history(i, j) = this%history(i, j-1)
      end do
    end do

    do i = 1, this%nDOFs
      this%history(i, 1) = this%values(i)
    end do
  end subroutine UpdateHistory

  ! Original name: MD_Field_Mgr_GetHist
  subroutine GetHistory(this, historyStep, values)
    class(MD_Field_Mgr), intent(in) :: this
    integer(i4),             intent(in)    :: historyStep
    real(wp),             intent(out)   :: values(:)

    integer(i4) :: i, n

    if (.not. this%hasHistory .or. historyStep < 1 .or. historyStep > this%nHistory) then
      values = 0.0_wp
      return
    end if

    n = min(size(values), this%nDOFs)
    do i = 1, n
      values(i) = this%history(i, historyStep)
    end do
  end subroutine GetHistory

  ! Original name: MD_Field_Mgr_ApplyCons
  subroutine ApplyConstraints(this, isFixed, prescribedvalue)
    class(MD_Field_Mgr), intent(inout) :: this
    logical,               intent(in)    :: isFixed(:)
    real(wp),               intent(in),    optional :: prescribedvalue(:)

    integer(i4) :: i, n

    this%isConstrained = .true.
    n = min(size(isFixed), this%nDOFs)
    do i = 1, n
      this%isFixed(i) = isFixed(i)
    end do

    if (present(prescribedvalue)) then
      n = min(size(prescribedvalue), this%nDOFs)
      do i = 1, n
        this%prescribedvalue(i) = prescribedvalue(i)
      end do
    end if
  end subroutine ApplyConstraints

  ! Original name: MD_Field_Mgr_GetConsDOFs
  subroutine GetConstrainedDOFs(this, isFixed, prescribedvalue)
    class(MD_Field_Mgr), intent(in) :: this
    logical,               intent(out)   :: isFixed(:)
    real(wp),               intent(out), optional :: prescribedvalue(:)

    integer(i4) :: i, n

    if (.not. this%isConstrained) then
      isFixed = .false.
      if (present(prescribedvalue)) prescribedvalue = 0.0_wp
      return
    end if

    n = min(size(isFixed), this%nDOFs)
    do i = 1, n
      isFixed(i) = this%isFixed(i)
    end do

    if (present(prescribedvalue)) then
      n = min(size(prescribedvalue), this%nDOFs)
      do i = 1, n
        prescribedvalue(i) = this%prescribedvalue(i)
      end do
    end if
  end subroutine GetConstrainedDOFs

  !=============================================================================
  !> @brief Initialize field description (legacy interface)
  !! @details Initializes field description with ID, type, name, DOFs, and order
  !! @param[inout] this Field description instance
  !! @param[in] fieldId Field ID ? ?
  !! @param[in] fieldType Field type ? ?
  !! @param[in] nDOFs Number of DOFs n_dof ? ?
  !! @param[in] fieldName Field name (optional)
  !! @param[in] order Field order ? ?(optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !=============================================================================
  subroutine Init(this, fieldId, fieldType, fieldName, nDOFs, order)
    class(MD_FieldDesc), intent(inout) :: this
    integer(i4),             intent(in)    :: fieldId, fieldType, nDOFs
    character(len=*),         intent(in),    optional :: fieldName
    integer(i4),             intent(in),    optional :: order

    this%fieldId = fieldId
    this%fieldType = fieldType
    if (present(fieldName)) then
      this%fieldName = trim(fieldName)
    else
      this%fieldName = trim(GetFieldTypeName(fieldType))
    end if
    this%nDOFs = nDOFs
    if (present(order)) then
      this%order = order
    else
      this%order = GetFieldOrder(fieldType)
    end if
    this%isActive = .true.
    this%isTransient = .true.
    this%isNonlinear = .false.
  end subroutine Init

  ! Original name: MD_FieldDesc_SetDOFRng
  subroutine SetDOFRange(this, startDOF, endDOF)
    class(MD_FieldDesc), intent(inout) :: this
    integer(i4),             intent(in)    :: startDOF, endDOF

    this%startDOF = startDOF
    this%endDOF = endDOF
  end subroutine SetDOFRange

  ! Original name: MD_FieldDesc_GetDOFRng
  subroutine GetDOFRange(this, startDOF, endDOF)
    class(MD_FieldDesc), intent(in) :: this
    integer(i4),             intent(out)   :: startDOF, endDOF

    startDOF = this%startDOF
    endDOF = this%endDOF
  end subroutine GetDOFRange

  !=============================================================================
  !> @brief Initialize field manager (legacy interface)
  !! @details Initializes field manager with number of fields
  !! @param[inout] this Field manager instance
  !! @param[in] nFields Number of fields n_fields ? ?(optional)
  !! @param[out] status Error status
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !=============================================================================
  subroutine Init(this, nFields, status)
    class(MD_FieldManager), intent(inout) :: this
    integer(i4),               intent(in),    optional :: nFields
    type(ErrorStatusType),    intent(out)   :: status
    integer(i4) :: i

    call init_error_status(status)

    this%isInitialized = .true.
    this%nFields = 0_i4
    this%nDOFsTotal = 0_i4

    if (present(nFields) .and. nFields > 0) then
      this%nFields = nFields
      allocate(this%fields(nFields))
      allocate(this%fieldStates(nFields))

      ! Init fields with default values
      ! Note: Fields should be properly initialized via RegisterField with actual field descriptions
      do i = 1, nFields
        ! Init with default values - actual field info will be set via RegisterField
        call this%fields(i)%Init(i, MD_FIELD_UNKNOWN, "", 0_i4)
        call this%fieldStates(i)%Init(i, MD_FIELD_UNKNOWN, "", 0_i4)
      end do
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Init

  ! Original name: MD_FieldMgr_RegField
  subroutine RegisterField(this, fieldDesc, status)
    class(MD_FieldManager), intent(inout) :: this
    type(MD_FieldDesc), intent(in) :: fieldDesc
    type(ErrorStatusType),    intent(out)   :: status

    integer(i4) :: newId, i
    type(MD_FieldDesc), allocatable :: tempFields(:)
    type(MD_Field_Mgr), allocatable :: tempStates(:)

    call init_error_status(status)

    if (.not. this%isInitialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Field manager not initialized"
      return
    end if

    newId = this%nFields + 1

    if (allocated(this%fields)) then
      call move_alloc(this%fields, tempFields)
      allocate(this%fields(newId))
      this%fields(1:newId-1) = tempFields
      deallocate(tempFields)
    else
      allocate(this%fields(newId))
    end if

    if (allocated(this%fieldStates)) then
      call move_alloc(this%fieldStates, tempStates)
      allocate(this%fieldStates(newId))
      this%fieldStates(1:newId-1) = tempStates
      deallocate(tempStates)
    else
      allocate(this%fieldStates(newId))
    end if

    this%fields(newId) = fieldDesc
    this%fields(newId)%fieldId = newId

    call this%fieldStates(newId)%Init(newId, fieldDesc%fieldType, &
                                          fieldDesc%fieldName, &
                                          fieldDesc%nDOFs, &
                                          fieldDesc%order)
    call this%fieldStates(newId)%AllocateDOFs()

    this%nFields = newId
    this%nDOFsTotal = this%nDOFsTotal + fieldDesc%nDOFs

    status%status_code = IF_STATUS_OK
  end subroutine RegisterField

  ! Original name: MD_FieldMgr_GetFieldDesc
  subroutine GetFieldDesc(this, fieldId, fieldDesc, status)
    class(MD_FieldManager), intent(in) :: this
    integer(i4),               intent(in)    :: fieldId
    type(MD_FieldDesc),     intent(out)   :: fieldDesc
    type(ErrorStatusType),    intent(out)   :: status

    call init_error_status(status)

    if (fieldId < 1 .or. fieldId > this%nFields) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid field ID"
      return
    end if

    fieldDesc = this%fields(fieldId)
    status%status_code = IF_STATUS_OK
  end subroutine GetFieldDesc

  ! Original name: MD_FieldMgr_GetFieldState
  subroutine GetFieldState(this, fieldDesc, fieldState, status)
    class(MD_FieldManager), intent(in) :: this
    type(MD_FieldDesc),     intent(in)    :: fieldDesc
    type(MD_Field_Mgr),    intent(out)   :: fieldState
    type(ErrorStatusType),    intent(out)   :: status

    call init_error_status(status)

    if (fieldDesc%fieldId < 1 .or. fieldDesc%fieldId > this%nFields) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid field ID"
      return
    end if

    fieldState = this%fieldStates(fieldDesc%fieldId)
    status%status_code = IF_STATUS_OK
  end subroutine GetFieldState

  ! Original name: MD_FieldMgr_GetFieldStateById
  subroutine GetFieldStateById(this, fieldId, fieldState, status)
    class(MD_FieldManager), intent(in) :: this
    integer(i4),               intent(in)    :: fieldId
    type(MD_Field_Mgr),    intent(out)   :: fieldState
    type(ErrorStatusType),    intent(out)   :: status

    call init_error_status(status)

    if (fieldId < 1 .or. fieldId > this%nFields) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid field ID"
      return
    end if

    fieldState = this%fieldStates(fieldId)
    status%status_code = IF_STATUS_OK
  end subroutine GetFieldStateById

  ! Original name: MD_FieldMgr_UpdFieldState
  subroutine UpdateFieldState(this, fieldId, values, velocities, accelerations, status)
    class(MD_FieldManager), intent(inout) :: this
    integer(i4),               intent(in)    :: fieldId
    real(wp),                 intent(in)    :: values(:)
    real(wp),                 intent(in),    optional :: velocities(:), accelerations(:)
    type(ErrorStatusType),    intent(out)   :: status

    call init_error_status(status)

    if (fieldId < 1 .or. fieldId > this%nFields) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid field ID"
      return
    end if

    call this%fieldStates(fieldId)%SetValues(values, velocities, accelerations)
    status%status_code = IF_STATUS_OK
  end subroutine UpdateFieldState

  ! Original name: MD_FieldMgr_AddCpl
  subroutine AddCoupling(this, field1_type, field2_type, coupling_type, coupling_coeff, status)
    class(MD_FieldManager), intent(inout) :: this
    integer(i4),               intent(in)    :: field1_type, field2_type
    integer(i4),               intent(in),    optional :: coupling_type
    real(wp),                 intent(in),    optional :: coupling_coeff
    type(ErrorStatusType),    intent(out)   :: status

    integer(i4) :: nCouplings

    call init_error_status(status)

    nCouplings = 0_i4
    if (allocated(this%couplings)) nCouplings = size(this%couplings)

    allocate(this%couplings(nCouplings + 1))

    call this%couplings(nCouplings + 1)%Init(field1_type, field2_type, coupling_type)

    if (present(coupling_coeff)) then
      this%couplings(nCouplings + 1)%coupling_coeff = coupling_coeff
    end if

    status%status_code = IF_STATUS_OK
  end subroutine AddCoupling

  ! Original name: MD_FieldMgr_GetCpl
  subroutine GetCoupling(this, field1_type, field2_type, coupling, status)
    class(MD_FieldManager), intent(in) :: this
    integer(i4),               intent(in)    :: field1_type, field2_type
    type(MD_FieldCpl),   intent(out)   :: coupling
    type(ErrorStatusType),    intent(out)   :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. allocated(this%couplings)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "No couplings defined"
      return
    end if

    do i = 1, size(this%couplings)
      if (this%couplings(i)%field1_type == field1_type .and. &
          this%couplings(i)%field2_type == field2_type) then
        coupling = this%couplings(i)
        status%status_code = IF_STATUS_OK
        return
      end if
    end do

    status%status_code = IF_STATUS_INVALID
    status%message = "Coupling not found"
  end subroutine GetCoupling

  ! Original name: MD_FieldMgr_GetTotalDOFs
  function GetTotalDOFs(this) result(nDOFs)
    class(MD_FieldManager), intent(in) :: this
    integer(i4) :: nDOFs
    nDOFs = this%nDOFsTotal
  end function GetTotalDOFs

  ! Original name: MD_FieldMgr_GetFieldDOFMap
  subroutine GetFieldDOFMap(this, fieldDOFMap)
    class(MD_FieldManager), intent(in) :: this
    integer(i4),               intent(out)   :: fieldDOFMap(:)

    integer(i4) :: i, j, startDOF

    if (.not. allocated(this%fieldDOFMap)) then
      fieldDOFMap = 0_i4
      return
    end if

    startDOF = 1_i4
    do i = 1, this%nFields
      do j = 1, this%fields(i)%nDOFs
        fieldDOFMap(startDOF + j - 1) = i
      end do
      startDOF = startDOF + this%fields(i)%nDOFs
    end do
  end subroutine GetFieldDOFMap

  ! Original name: MD_FieldMgr_GetGlobalDOFMap
  subroutine GetGlobalDOFMap(this, globalDOFMap)
    class(MD_FieldManager), intent(in) :: this
    integer(i4),               intent(out)   :: globalDOFMap(:)

    if (.not. allocated(this%globalDOFMap)) then
      globalDOFMap = 0_i4
      return
    end if

    globalDOFMap = this%globalDOFMap
  end subroutine GetGlobalDOFMap

  ! Original name: MD_FieldMgr_BuildDOFMap
  subroutine BuildDOFMap(this, status)
    class(MD_FieldManager), intent(inout) :: this
    type(ErrorStatusType),    intent(out)   :: status

    integer(i4) :: i, j, globalDOF

    call init_error_status(status)

    if (this%nFields == 0_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = "No fields registered"
      return
    end if

    allocate(this%fieldDOFMap(this%nDOFsTotal))
    allocate(this%globalDOFMap(this%nDOFsTotal))

    globalDOF = 1_i4
    do i = 1, this%nFields
      this%fields(i)%startDOF = globalDOF
      this%fields(i)%endDOF = globalDOF + this%fields(i)%nDOFs - 1

      do j = 1, this%fields(i)%nDOFs
        this%fieldDOFMap(globalDOF) = i
        this%globalDOFMap(globalDOF) = globalDOF
        globalDOF = globalDOF + 1
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine BuildDOFMap

  ! Original name: MD_FieldMgr_Cleanup
  subroutine Cleanup(this)
    class(MD_FieldManager), intent(inout) :: this

    integer(i4) :: i

    if (allocated(this%fields)) then
      deallocate(this%fields)
    end if

    if (allocated(this%fieldStates)) then
      do i = 1, size(this%fieldStates)
        if (allocated(this%fieldStates(i)%values)) deallocate(this%fieldStates(i)%values)
        if (allocated(this%fieldStates(i)%velocities)) deallocate(this%fieldStates(i)%velocities)
        if (allocated(this%fieldStates(i)%accelerations)) deallocate(this%fieldStates(i)%accelerations)
        if (allocated(this%fieldStates(i)%values_old)) deallocate(this%fieldStates(i)%values_old)
        if (allocated(this%fieldStates(i)%velocities_old)) deallocate(this%fieldStates(i)%velocities_old)
        if (allocated(this%fieldStates(i)%history)) deallocate(this%fieldStates(i)%history)
        if (allocated(this%fieldStates(i)%isFixed)) deallocate(this%fieldStates(i)%isFixed)
        if (allocated(this%fieldStates(i)%prescribedvalue)) deallocate(this%fieldStates(i)%prescribedvalue)
      end do
      deallocate(this%fieldStates)
    end if

    if (allocated(this%couplings)) then
      deallocate(this%couplings)
    end if

    if (allocated(this%fieldDOFMap)) then
      deallocate(this%fieldDOFMap)
    end if

    if (allocated(this%globalDOFMap)) then
      deallocate(this%globalDOFMap)
    end if

    this%nFields = 0_i4
    this%nDOFsTotal = 0_i4
    this%isInitialized = .false.
  end subroutine Cleanup

  ! ===================================================================
  ! Continuum Integration Interfaces
  ! ===================================================================
  abstract interface
    subroutine ContIpKernel(ip, sf, dN_dx, dVol, radius)
      import :: wp, i4, ShapeFuncResult
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx(:,:)
      real(wp), intent(in) :: dVol, radius
    end subroutine ContIpKernel

    subroutine DiffIpKernel(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)
      import :: wp, i4, ShapeFuncResult
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in)  :: field_ip
      real(wp), intent(in)  :: field_old_ip
      real(wp), intent(out) :: k_eff_ip
      real(wp), intent(out) :: C_eff_ip
    end subroutine DiffIpKernel
  end abstract interface

  interface KineEval
!>>> UFC_L3_QUENCH | Domain:Out | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

    module procedure ComputeKinematics
  end interface

  ! ===================================================================
  ! Continuum Core Functions
  ! ===================================================================
  integer(i4) function GetContOrder(et) result(order)
    type(ElemType), intent(in) :: et
    integer(i4) :: nNode

    nNode = et%pop%n_nodes

    if (index(et%name, 'R') > 0) then
       order = 1
       if (nNode > 8 .and. et%topo == UF_Topo_Hex) order = 2
       if (et%topo == UF_Topo_Quad .and. nNode > 4) order = 2
    else
       order = 2
       if (et%topo == UF_Topo_Hex .and. nNode > 8) order = 3
       if (et%topo == UF_Topo_Quad .and. nNode > 4) order = 3
       if (et%topo == UF_Topo_Wedge) order = 2
    end if
  end function GetContOrder

  integer(i4) function GetEffOrder(et, fm) result(order)
    type(ElemType), intent(in) :: et
    type(ElemFormul), intent(in) :: fm

    order = GetContOrder(et)

    select case (fm%integration_scheme)
    case (UF_Int_Reduced)
       select case (et%topo)
       case (UF_Topo_Hex)
          if (et%pop%n_nodes == 8) then
             order = 1
          else if (et%pop%n_nodes > 8) then
             order = 2
          end if
       case (UF_Topo_Quad)
          if (et%pop%n_nodes == 4) then
             order = 1
          else if (et%pop%n_nodes > 4) then
             order = 2
          end if
       case default
       end select
    case default
    end select
  end function GetEffOrder

  subroutine ContGauss(et, fm, cx, ipKernel)
    type(ElemType), intent(in) :: et
    type(ElemFormul), intent(in) :: fm
    type(ElemCtx), intent(in) :: cx
    procedure(ContIpKernel) :: ipKernel

    integer(i4) :: nNode, nDim, ip, nInt, iNode
    integer(i4) :: integrationorde
    logical     :: isAxisym
    real(wp), allocatable :: gaussCoords(:,:), weights(:)
    type(ShapeFuncResult) :: sf
    real(wp), allocatable :: dN_dx(:,:)
    real(wp) :: detJ, dVol, radius, r_coord

    nNode = et%pop%n_nodes
    nDim  = et%dim
    isAxisym = (index(et%name, 'CAX') > 0)

    integrationorde = GetEffOrder(et, fm)
    call UF_GetGaussPoints(et%topo, integrationorde, nDim, gaussCoords, weights)
    nInt = size(weights)

    if (allocated(dN_dx)) deallocate(dN_dx)
    allocate(dN_dx(nNode, nDim))

    do ip = 1, nInt
      call UF_GetShapeFunctions(et%name, gaussCoords(:,ip), sf)

      if (fm%kineFormulation == UF_Form_UL) then
        call UF_ComputeJacobian(cx%coords_curr(1:nDim, :), sf%dN_dxi, detJ, dN_dx)
      else
        call UF_ComputeJacobian(cx%coords_ref(1:nDim, :), sf%dN_dxi, detJ, dN_dx)
      end if

      dVol = detJ * weights(ip)

      radius = 0.0_wp
      if (isAxisym) then
        do iNode = 1, nNode
          if (fm%kineFormulation == UF_Form_UL) then
            r_coord = cx%coords_curr(1, iNode)
          else
            r_coord = cx%coords_ref(1, iNode)
          end if
          radius  = radius + sf%N(iNode, 1) * r_coord
        end do
        if (radius < 1.0e-10_wp) radius = 1.0e-10_wp
        dVol = dVol * 6.283185307179586_wp * radius
      else if (nDim == 2) then
        dVol = dVol * 1.0_wp
      end if

      call ipKernel(ip, sf, dN_dx, dVol, radius)
    end do

    if (allocated(dN_dx)) deallocate(dN_dx)
    if (allocated(gaussCoords)) deallocate(gaussCoords)
    if (allocated(weights)) deallocate(weights)
  end subroutine ContGauss

  subroutine DiffGauss(et, fm, cx, &
                                            field, field_incr, hasTransient, &
                                            ipCoeffProc, Ke, C)
    type(ElemType), intent(in) :: et
    type(ElemFormul), intent(in) :: fm
    type(ElemCtx), intent(in) :: cx
    real(wp), allocatable,       intent(in), optional :: field(:)
    real(wp), allocatable,       intent(in), optional :: field_incr(:)
    logical,                     intent(in)    :: hasTransient
    procedure(DiffIpKernel)                :: ipCoeffProc

    real(wp),                    intent(inout) :: Ke(:,:)
    real(wp),                    intent(inout) :: C(:,:)

    integer(i4) :: nNode, nDim, ip, nInt
    integer(i4) :: iNode, jNode, aDim
    integer(i4) :: integrationorde
    logical     :: isAxisym
    real(wp), allocatable :: gaussCoords(:,:), weights(:)
    type(ShapeFuncResult) :: sf
    real(wp), allocatable :: dN_dx(:,:)
    real(wp) :: detJ, dVol, radius, r_coord
    real(wp) :: field_ip, field_old_ip
    real(wp) :: gradni_dot_grad, Nij
    real(wp) :: k_eff_ip, C_eff_ip

    nNode = et%pop%n_nodes
    nDim  = et%dim
    isAxisym = (index(et%name, 'CAX') > 0)

    integrationorde = GetEffOrder(et, fm)
    call UF_GetGaussPoints(et%topo, integrationorde, nDim, gaussCoords, weights)
    nInt = size(weights)

    if (allocated(dN_dx)) deallocate(dN_dx)
    allocate(dN_dx(nNode, nDim))

    do ip = 1, nInt
      call UF_GetShapeFunctions(et%name, gaussCoords(:,ip), sf)

      call UF_ComputeJacobian(cx%coords_ref(1:nDim, :), sf%dN_dxi, detJ, dN_dx)

      dVol = detJ * weights(ip)

      radius = 0.0_wp
      if (isAxisym) then
        do iNode = 1, nNode
          r_coord = cx%coords_ref(1, iNode)
          radius  = radius + sf%N(iNode, 1) * r_coord
        end do
        if (radius < 1.0e-10_wp) radius = 1.0e-10_wp
        dVol = dVol * 6.283185307179586_wp * radius
      else if (nDim == 2) then
        dVol = dVol * 1.0_wp
      end if

      field_ip     = 0.0_wp
      field_old_ip = 0.0_wp
      if (present(field)) then
        if (allocated(field)) then
          do jNode = 1, min(nNode, size(field))
            field_ip = field_ip + sf%N(jNode, 1) * field(jNode)
          end do
        end if
      end if
      if (present(field_incr)) then
        if (allocated(field_incr)) then
          do jNode = 1, min(nNode, size(field_incr))
            field_old_ip = field_old_ip + sf%N(jNode, 1) * field_incr(jNode)
          end do
        end if
      end if
      field_old_ip = field_ip - field_old_ip

      call ipCoeffProc(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)

      if (k_eff_ip > 0.0_wp) then
        do iNode = 1, nNode
          do jNode = 1, nNode
            gradni_dot_grad = 0.0_wp
            do aDim = 1, nDim
              gradni_dot_grad = gradni_dot_grad + dN_dx(iNode, aDim) * dN_dx(jNode, aDim)
            end do
            Ke(iNode, jNode) = Ke(iNode, jNode) + k_eff_ip * gradni_dot_grad * dVol
          end do
        end do
      end if

      if (hasTransient .and. C_eff_ip /= 0.0_wp) then
        do iNode = 1, nNode
          do jNode = 1, nNode
            Nij = sf%N(iNode, 1) * sf%N(jNode, 1)
            C(iNode, jNode) = C(iNode, jNode) + C_eff_ip * Nij * dVol
          end do
        end do
      end if

    end do

    if (allocated(dN_dx)) deallocate(dN_dx)
    if (allocated(gaussCoords)) deallocate(gaussCoords)
    if (allocated(weights)) deallocate(weights)
  end subroutine DiffGauss

  ! ===================================================================
  ! Structural Kinematics Functions
  ! ===================================================================
  subroutine ComputeKinematics(Ctx, sf, dN_dx, form, nDim, isAxisym, radius, kin)
    type(ElemCtx),  intent(in)  :: Ctx
    type(ShapeFuncResult), intent(in)  :: sf
    real(wp),                 intent(in)  :: dN_dx(:,:)
    integer(i4),              intent(in)  :: form, nDim
    logical,                  intent(in)  :: isAxisym
    real(wp),                 intent(in)  :: radius
    type(Kinematics),      intent(out) :: kin

    integer(i4) :: i, j, k, nNodeLoc
    real(wp) :: F(3,3), F_old(3,3), F_incr(3,3)
    real(wp) :: H_curr(3,3), H_old(3,3)
    real(wp) :: u_r, u_r_old
    real(wp) :: u_curr_node(3, size(dN_dx,1))
    real(wp) :: u_old_node(3, size(dN_dx,1))
    real(wp) :: detF_old
    logical  :: has_disp_incr

    kin%F      = 0.0_wp
    kin%F_old  = 0.0_wp
    kin%detF   = 1.0_wp
    kin%C      = 0.0_wp
    kin%E      = 0.0_wp
    kin%b      = 0.0_wp
    kin%J      = 1.0_wp

    nNodeLoc = size(dN_dx,1)
    F      = 0.0_wp
    F_old  = 0.0_wp
    F_incr = 0.0_wp
    H_curr = 0.0_wp
    H_old  = 0.0_wp
    do i = 1, 3
      F(i,i)      = 1.0_wp
      F_old(i,i)  = 1.0_wp
      F_incr(i,i) = 1.0_wp
    end do

    u_curr_node = 0.0_wp
    u_old_node  = 0.0_wp
    has_disp_incr = allocated(Ctx%disp_incr)
    do i = 1, min(3, size(Ctx%disp_total,1))
      do j = 1, min(nNodeLoc, size(Ctx%disp_total,2))
        u_curr_node(i,j) = Ctx%disp_total(i,j)
        if (has_disp_incr) then
          if (size(Ctx%disp_incr,1) >= i .and. size(Ctx%disp_incr,2) >= j) then
            u_old_node(i,j) = Ctx%disp_total(i,j) - Ctx%disp_incr(i,j)
          else
            u_old_node(i,j) = 0.0_wp
          end if
        else
          u_old_node(i,j) = 0.0_wp
        end if
      end do
    end do

    do j = 1, nDim
      do i = 1, 3
        do k = 1, nNodeLoc
          H_curr(i,j) = H_curr(i,j) + u_curr_node(i,k) * dN_dx(k,j)
          H_old(i,j)  = H_old(i,j)  + u_old_node(i,k)  * dN_dx(k,j)
        end do
      end do
    end do

    do i = 1, nDim
      do j = 1, nDim
        F(i,j)     = F(i,j)     + H_curr(i,j)
        F_old(i,j) = F_old(i,j) + H_old(i,j)
      end do
    end do

    if (isAxisym) then
       u_r     = 0.0_wp
       u_r_old = 0.0_wp
       do i = 1, nNodeLoc
          u_r     = u_r     + sf%N(i, 1) * u_curr_node(1, i)
          u_r_old = u_r_old + sf%N(i, 1) * u_old_node(1, i)
       end do
       if (abs(radius) > 1.0e-12_wp) then
          F(3,3)     = 1.0_wp + u_r     / radius
          F_old(3,3) = 1.0_wp + u_r_old / radius
       else
          F(3,3)     = 1.0_wp
          F_old(3,3) = 1.0_wp
       end if
    end if

    detF_old = UF_Determinant3x3(F_old)
    if (abs(detF_old) > 1.0e-20_wp) then
      F_incr = matmul(F, UF_InvertMatrix3x3(F_old, detF_old))
    else
      F_incr = 0.0_wp
      do i = 1, 3
        F_incr(i,i) = 1.0_wp
      end do
      do i = 1, nDim
        do j = 1, nDim
          F_incr(i,j) = F_incr(i,j) + (H_curr(i,j) - H_old(i,j))
        end do
      end do
    end if

    kin%mech%F      = F
    kin%mech%F_old  = F_old
    kin%mech%F_incr = F_incr
    kin%mech%Jac    = UF_Determinant3x3(F)
    kin%mech%C      = matmul(transpose(F), F)

    do i = 1, 3
      do j = 1, 3
        kin%mech%strain(TensorIndex(i,j)) = 0.5_wp * (kin%mech%C(i,j) - if_real(i==j,1.0_wp,0.0_wp))
      end do
    end do

    kin%mech%strain(4) = 2.0_wp * kin%mech%strain(4)
    kin%mech%strain(5) = 2.0_wp * kin%mech%strain(5)
    kin%mech%strain(6) = 2.0_wp * kin%mech%strain(6)

  end subroutine ComputeKinematics

  function TensorIndex(i, j) result(idx)
    integer(i4), intent(in) :: i, j
    integer(i4) :: idx
    integer(i4) :: map(3,3)
    map(1,1) = 1
    map(2,2) = 2
    map(3,3) = 3
    map(1,2) = 4
    map(2,1) = 4
    map(1,3) = 5
    map(3,1) = 5
    map(2,3) = 6
    map(3,2) = 6
    idx = map(i,j)
  end function TensorIndex

  function if_real(cond, val_true, val_false) result(res)
    logical, intent(in) :: cond
    real(wp), intent(in) :: val_true, val_false
    real(wp) :: res
    if (cond) then
      res = val_true
    else
      res = val_false
    end if
  end function if_real

  ! ===================================================================
  ! Thermal Core Functions
  ! ===================================================================
  subroutine UF_Co_MakeCoeffsFromContxt(matModel, Ctx, k_cond, rho, c_p, &
                                             alphaT, flag_th_exp, hasTransient, thState, ierr_material)
    type(MatProps),   intent(in)  :: matModel
    type(ElemCtx),  intent(in)  :: Ctx
    real(wp),                 intent(out) :: k_cond, rho, c_p
    real(wp),                 intent(out) :: alphaT
    real(wp),                 intent(out) :: flag_th_exp
    logical,                  intent(out) :: hasTransient
    type(ThermPointState), intent(out) :: thState
    integer(i4),              intent(out) :: ierr_material

    type(MatProps) :: props
    integer(i4)       :: nprops
    real(wp)          :: dt

    k_cond      = 0.0_wp
    rho         = 0.0_wp
    c_p         = 0.0_wp
    alphaT      = 0.0_wp
    flag_th_exp = 0.0_wp
    hasTransient = .false.
    ierr_material    = 0_i4

    props  = matModel
    nprops = 0_i4
    if (allocated(props%props)) nprops = size(props%props)

    if (nprops >= 3) rho    = props%props(3)
    if (nprops >= 4) alphaT = props%props(4)
    if (nprops >= 5) k_cond = props%props(5)
    if (nprops >= 6) c_p    = props%props(6)
    if (nprops >= 7) flag_th_exp = props%props(7)

    dt = max(Ctx%deltaTime, 0.0_wp)
    hasTransient = (rho * c_p > 0.0_wp .and. dt > 0.0_wp &
                    .and. allocated(Ctx%temp) &
                    .and. allocated(Ctx%temp_incr))

    thState%temperature = 0.0_wp
    thState%temperatureOld = 0.0_wp
    thState%tempRate = 0.0_wp
    thState%tempGradient = 0.0_wp
    thState%heatFlux = 0.0_wp

  end subroutine UF_ContTh_MakeCoeffsFromContext

  subroutine UF_ContTh_AllocCapacity(nNode, C)
    integer(i4), intent(in)    :: nNode
    real(wp),    pointer, intent(out) :: C(:,:)

    integer(i4) :: n

    n = max(nNode, 0_i4)
    if (n <= 0_i4) then
      nullify(C)
      return
    end if

    allocate(C(n, n))
    C = 0.0_wp
  end subroutine UF_ContTh_AllocCapacity

  ! ===================================================================
  ! Poro Core Functions
  ! ===================================================================
  subroutine UF_Co_MakeCoeffsFromContxt(matModel, Ctx, alpha_b, k_hyd, S_s, &
                                               rho_f, cp_f, flag_vol, hasTransient, prState, ierr_material)
    type(MatProps),   intent(in)  :: matModel
    type(ElemCtx),  intent(in)  :: Ctx
    real(wp),                 intent(out) :: alpha_b, k_hyd, S_s
    real(wp),                 intent(out) :: rho_f, cp_f
    real(wp),                 intent(out) :: flag_vol
    logical,                  intent(out) :: hasTransient
    type(PoroPointState),  intent(out) :: prState
    integer(i4),              intent(out) :: ierr_material

    type(MatProps) :: props
    integer(i4)       :: nprops
    real(wp)          :: dt

    alpha_b     = 0.0_wp
    k_hyd       = 0.0_wp
    S_s         = 0.0_wp
    rho_f       = 0.0_wp
    cp_f        = 0.0_wp
    flag_vol    = 0.0_wp
    hasTransient = .false.
    ierr_material    = 0_i4

    props  = matModel
    nprops = 0_i4
    if (allocated(props%props)) nprops = size(props%props)

    if (nprops >= 4) alpha_b  = props%props(4)
    if (nprops >= 5) k_hyd    = props%props(5)
    if (nprops >= 6) S_s      = props%props(6)
    if (nprops >= 8) flag_vol = props%props(8)
    if (nprops >= 9) rho_f    = props%props(9)
    if (nprops >= 10) cp_f    = props%props(10)

    dt = max(Ctx%deltaTime, 0.0_wp)
    hasTransient = (S_s > 0.0_wp .and. dt > 0.0_wp &
                    .and. allocated(Ctx%pore) &
                    .and. allocated(Ctx%pore_incr))

    prState%porePressure = 0.0_wp
    prState%porePressureOld = 0.0_wp
    prState%pressureRate = 0.0_wp
    prState%pressuregradien = 0.0_wp
    prState%fluidVelocity = 0.0_wp
    prState%saturation = 1.0_wp
    prState%porosity = 0.0_wp

  end subroutine UF_ContPoro_MakeCoeffsFromContext

  subroutine UF_ContPoro_AllocCapacity(nNode, S)
    integer(i4), intent(in)    :: nNode
    real(wp),    pointer, intent(out) :: S(:,:)

    integer(i4) :: n

    n = max(nNode, 0_i4)
    if (n <= 0_i4) then
      nullify(S)
      return
    end if

    allocate(S(n, n))
    S = 0.0_wp
  end subroutine UF_ContPoro_AllocCapacity

  ! ===================================================================
  ! THM Core Functions
  ! ===================================================================
  integer(i4), parameter, public :: MATERIAL_IDX_E        = 1_i4
  integer(i4), parameter, public :: MATERIAL_IDX_NU       = 2_i4
  integer(i4), parameter, public :: MAT_IDX_RHO_S    = 3_i4
  integer(i4), parameter, public :: MAT_IDX_ALPHA_B  = 4_i4
  integer(i4), parameter, public :: MAT_IDX_K_HYD    = 5_i4
  integer(i4), parameter, public :: MAT_IDX_S_S      = 6_i4
  integer(i4), parameter, public :: MAT_IDX_ENABLE = 7_i4
  integer(i4), parameter, public :: MAT_IDX_ENABLE = 8_i4
  integer(i4), parameter, public :: MAT_IDX_RHO_F    = 9_i4
  integer(i4), parameter, public :: MAT_IDX_CP_F     = 10_i4
  integer(i4), parameter, public :: MAT_IDX_KCOND_S  = 11_i4
  integer(i4), parameter, public :: MAT_IDX_CP_S     = 12_i4

  subroutine UF_ContTHM_EvalMaterial(matModel, thmState, rho_s, k_cond_s, c_p_s, &
                                    rho_f, c_p_f, alpha_b, k_hyd, S_s, flag_vol, ierr_material)
    type(MatProps),  intent(in)  :: matModel
    type(THMPointState),  intent(in)  :: thmState
    real(wp),                intent(out) :: rho_s, k_cond_s, c_p_s
    real(wp),                intent(out) :: rho_f, c_p_f
    real(wp),                intent(out) :: alpha_b, k_hyd, S_s
    real(wp),                intent(out) :: flag_vol
    integer(i4),             intent(out) :: ierr_material

    type(MatProps) :: props
    integer(i4)       :: nprops

    rho_s    = 0.0_wp
    k_cond_s = 0.0_wp
    c_p_s    = 0.0_wp
    rho_f    = 0.0_wp
    c_p_f    = 0.0_wp
    alpha_b  = 0.0_wp
    k_hyd    = 0.0_wp
    S_s      = 0.0_wp
    flag_vol = 0.0_wp
    ierr_material = 0_i4

    props   = matModel
    nprops  = 0_i4
    if (allocated(props%props)) nprops = size(props%props)

    if (nprops >= MAT_IDX_RHO_S)   rho_s    = props%props(MAT_IDX_RHO_S)
    if (nprops >= MAT_IDX_RHO_F)   rho_f    = props%props(MAT_IDX_RHO_F)
    if (nprops >= MAT_IDX_CP_S)    c_p_s    = props%props(MAT_IDX_CP_S)
    if (nprops >= MAT_IDX_CP_F)    c_p_f    = props%props(MAT_IDX_CP_F)

    if (nprops >= MAT_IDX_ALPHA_B) alpha_b  = props%props(MAT_IDX_ALPHA_B)
    if (nprops >= MAT_IDX_K_HYD)   k_hyd    = props%props(MAT_IDX_K_HYD)
    if (nprops >= MAT_IDX_S_S)     S_s      = props%props(MAT_IDX_S_S)

    if (nprops >= MAT_IDX_KCOND_S) then
      k_cond_s = props%props(MAT_IDX_KCOND_S)
    else if (nprops >= 5_i4) then
      k_cond_s = props%props(5)
    end if

    if (nprops >= MAT_IDX_ENABLE) then
      flag_vol = props%props(MAT_IDX_ENABLE)
    else
      flag_vol = 0.0_wp
    end if

  end subroutine UF_ContTHM_EvalMaterial

  subroutine UF_ContTHM_AllocCtt(nNode, Ctt)
    integer(i4), intent(in)    :: nNode
    real(wp),    pointer, intent(out) :: Ctt(:,:)

    integer(i4) :: n

    n = max(nNode, 0_i4)
    if (n <= 0_i4) then
      nullify(Ctt)
      return
    end if

    allocate(Ctt(n, n))
    Ctt = 0.0_wp
  end subroutine UF_ContTHM_AllocCtt

  subroutine UF_ContTHM_AllocSpp(nNode, Spp)
    integer(i4), intent(in)    :: nNode
    real(wp),    pointer, intent(out) :: Spp(:,:)

    integer(i4) :: n

    n = max(nNode, 0_i4)
    if (n <= 0_i4) then
      nullify(Spp)
      return
    end if

    allocate(Spp(n, n))
    Spp = 0.0_wp
  end subroutine UF_ContTHM_AllocSpp

  ! ===================================================================
  ! Physical Model Functions
  ! ===================================================================
  type, public :: StructMatRes
    type(ContmMatRes) :: core
  end type StructMatRes

  function StructGetSectionDesc(id) result(desc)
    integer(i4), intent(in) :: id
    type(MatDesc) :: desc

    desc = UF_Section_GetDescriptor(id)
  end function StructGetSectionDesc

  subroutine StructIntegrateIp(matModel, Ctx, kin, desc, &
                               ipState_in, ipState_out, physRes, ip_local)
    type(MatProps),      intent(in)    :: matModel
    type(ElemCtx),     intent(in)    :: Ctx
    type(Kinematics),         intent(in)    :: kin
    type(MatDesc),intent(in)    :: desc
    type(MD_IPStaSta),      intent(in)    :: ipState_in
    type(MD_IPStaSta),      intent(inout) :: ipState_out
    type(StructMatRes),          intent(out)   :: physRes
    integer(i4),                 intent(in),    optional :: ip_local

    type(ContmMatRes) :: MatResult

    if (present(ip_local)) then
      call MD_RT_UniFld_EvalStructAtIp(matModel, Ctx, kin, desc, &
                                        ipState_in, ipState_out, MatResult, ip_local)
    else
      call MD_RT_UniFld_EvalStructAtIp(matModel, Ctx, kin, desc, &
                                        ipState_in, ipState_out, MatResult)
    end if

    physRes%core = MatResult

  end subroutine StructIntegrateIp

  subroutine ThermCoeffs(matModel, Ctx, k_cond, rho, c_p, &
                           alphaT, flag_th_exp, hasTransient, thState, ierr_material)
    type(MatProps),  intent(in)  :: matModel
    type(ElemCtx), intent(in)  :: Ctx
    real(wp),                intent(out) :: k_cond, rho, c_p
    real(wp),                intent(out) :: alphaT
    real(wp),                intent(out) :: flag_th_exp
    logical,                 intent(out) :: hasTransient
    type(ThermPointState), intent(out) :: thState
    integer(i4),             intent(out) :: ierr_material

    call UF_ContTh_MakeCoeffsFromContext(matModel, Ctx, k_cond, rho, c_p, &
                                         alphaT, flag_th_exp, hasTransient, thState, ierr_material)
  end subroutine ThermCoeffs

  subroutine ThermAllocCtt(nNode, C)
    integer(i4), intent(in) :: nNode
    real(wp), pointer, intent(out) :: C(:,:)

    call UF_ContTh_AllocCapacity(nNode, C)
  end subroutine ThermAllocCtt

  subroutine PoroCoeffs(matModel, Ctx, alpha_b, k_hyd, S_s, &
                        rho_f, cp_f, flag_vol, hasTransient, prState, ierr_material)
    type(UF_MaterialModel),  intent(in)  :: matModel
    type(UF_ElemCtx), intent(in)  :: Ctx
    real(wp),                intent(out) :: alpha_b, k_hyd, S_s
    real(wp),                intent(out) :: rho_f, cp_f
    real(wp),                intent(out) :: flag_vol
    logical,                 intent(out) :: hasTransient
    type(UF_PoroPointState), intent(out) :: prState
    integer(i4),             intent(out) :: ierr_material

    call UF_ContPoro_MakeCoeffsFromContext(matModel, Ctx, alpha_b, k_hyd, S_s, &
                                           rho_f, cp_f, flag_vol, hasTransient, prState, ierr_material)
  end subroutine PoroCoeffs

  subroutine PoroAllocSpp(nNode, S)
    integer(i4), intent(in) :: nNode
    real(wp), pointer, intent(out) :: S(:,:)

    call UF_ContPoro_AllocCapacity(nNode, S)
  end subroutine PoroAllocSpp

  subroutine THMAllocSpp(nNode, Spp)
    integer(i4), intent(in) :: nNode
    real(wp), pointer, intent(out) :: Spp(:,:)

    call UF_Phys_THM_AllocSpp(nNode, Spp)
  end subroutine THMAllocSpp

  subroutine MD_Phys_THM_EvalMaterial(matModel, thmState, rho_s, k_cond_s, c_p_s, &
                                      rho_f, c_p_f, alpha_b, k_hyd, S_s, flag_vol, ierr_material)
    type(MatProps),  intent(in)  :: matModel
    type(THMPointState),  intent(in)  :: thmState
    real(wp),                intent(out) :: rho_s, k_cond_s, c_p_s
    real(wp),                intent(out) :: rho_f, c_p_f
    real(wp),                intent(out) :: alpha_b, k_hyd, S_s
    real(wp),                intent(out) :: flag_vol
    integer(i4),             intent(out) :: ierr_material

    call UF_ContTHM_EvalMaterial(matModel, thmState, rho_s, k_cond_s, c_p_s, &
                                 rho_f, c_p_f, alpha_b, k_hyd, S_s, flag_vol, ierr_material)
  end subroutine MD_Phys_THM_EvalMaterial

  ! ===================================================================
  ! Unified Field Equation Type (from UF_UnifiedField_Core)
  ! ===================================================================
  type, public :: MD_FldEq
    !! Unified field equation: CĂÂˇĂâ Ăâ?+ KĂÂˇĂâ?+ f_int(Ăâ? = f_ext(t)
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: field_type = MD_FIELD_UNKNOWN
    integer(i4) :: system_type = MD_SYS_FIRST_ORDER
    integer(i4) :: n_dofs = 0_i4
    
    ! Capacity matrix C (mass M, thermal capacity C_T, storage S, etc.)
    real(wp), allocatable :: C(:,:)
    
    ! Conduction/stiffness matrix K
    real(wp), allocatable :: K(:,:)
    
    ! Damping matrix (for second-order systems)
    real(wp), allocatable :: D(:,:)
    
    ! Mass matrix (for second-order systems)
    real(wp), allocatable :: M(:,:)
    
    ! Internal force/flux f_int(Ăâ? - nonlinear function
    real(wp), allocatable :: f_int(:)
    
    ! External force/source f_ext(t)
    real(wp), allocatable :: f_ext(:)
    
    ! Field variable Ăâ?
    real(wp), allocatable :: phi(:)
    
    ! Time derivative Ăâ Ăâ?
    real(wp), allocatable :: phi_dot(:)
    
    ! Second time derivative Ăâ ĂË?(for second-order systems)
    real(wp), allocatable :: phi_ddot(:)
    
    ! Residual R = f_ext - f_int - CĂÂˇĂâ Ăâ?- KĂÂˇĂâ?
    real(wp), allocatable :: residual(:)
    
    ! Tangent operator K_t = Ă˘ËâR/Ă˘ËâĂ?
    real(wp), allocatable :: K_tangent(:,:)
    
    ! Time step
    real(wp) :: dt = 0.0_wp
    
    ! Current time
    real(wp) :: time = 0.0_wp
    
    ! Nonlinear flag
    logical :: is_nonlinear = .false.
    
    ! Transient flag
    logical :: is_transient = .true.
    
  contains
    procedure, public :: Init => MD_FldEq_Init
    procedure, public :: ComputeResidual => MD_FldEq_ComputeResidual
    procedure, public :: ComputeTangent => MD_FldEq_ComputeTangent
    procedure, public :: UpdateState => MD_FldEq_UpdateState
    procedure, public :: GetResidualNorm => MD_FldEq_GetResidualNorm
    procedure, public :: Clean => MD_FldEq_Clean
  end type MD_FldEq

  ! ===================================================================
  ! Field System Type
  ! ===================================================================
  type, public :: MD_FldSysType
    !! Field system type descriptor
    
    integer(i4) :: system_type = MD_SYS_FIRST_ORDER
    integer(i4) :: n_fields = 0_i4
    integer(i4), allocatable :: field_types(:)
    integer(i4), allocatable :: field_orders(:)  ! Order of each field (1 or 2)
    logical :: is_coupled = .false.
    integer(i4), allocatable :: coupling_matrix(:,:)  ! Coupling relationship matrix
    
  contains
    procedure, public :: Init => MD_FldSysType_Init
    procedure, public :: AddField => MD_FldSysType_AddField
    procedure, public :: SetCoupling => MD_FldSysType_SetCoupling
    procedure, public :: Clean => MD_FldSysType_Clean
  end type MD_FldSysType

  ! ===================================================================
  ! Field Coupling Descriptor
  ! ===================================================================
  type, public :: MD_FldCplDesc
    !! Describes coupling between two fields
    
    integer(i4) :: field1_id = 0_i4
    integer(i4) :: field2_id = 0_i4
    integer(i4) :: field1_type = MD_FIELD_UNKNOWN
    integer(i4) :: field2_type = MD_FIELD_UNKNOWN
    
    ! Coupling matrix K_{ij} (field i affects field j)
    real(wp), allocatable :: coupling_matrix(:,:)
    
    ! Coupling strength
    real(wp) :: cpl_strength = 1.0_wp
    
    ! Coupling type
    integer(i4) :: coupling_type = 0_i4  ! 0=none, 1=one-way, 2=two-way, 3=full
    
    ! Active flag
    logical :: is_active = .false.
    
  contains
    procedure, public :: Init => MD_FldCplDesc_Init
    procedure, public :: ComputeCouplingTerm => MD_FldCplDesc_ComputeCouplingTerm
    procedure, public :: Clean => MD_FldCplDesc_Clean
  end type MD_FldCplDesc

  ! ===================================================================
  ! Unified Field System
  ! ===================================================================
  type, public :: MD_UniFldSys
    !! Unified field system containing multiple coupled fields
    
    logical :: is_initialized = .false.
    
    ! System configuration
    type(MD_FldSysType) :: system_config
    
    ! Field equations
    type(MD_FldEq), allocatable :: field_equations(:)
    
    ! Field manager (from MD_UniFld)
    type(MD_FieldManager) :: field_manager
    
    ! Coupling descriptors
    type(MD_FldCplDesc), allocatable :: couplings(:)
    
    ! Global system matrices (for monolithic coupling)
    real(wp), allocatable :: K_global(:,:)
    real(wp), allocatable :: C_global(:,:)
    real(wp), allocatable :: M_global(:,:)
    real(wp), allocatable :: R_global(:)
    real(wp), allocatable :: phi_global(:)
    
    ! Total DOFs
    integer(i4) :: n_dofs_total = 0_i4
    
    ! Time integration parameters
    real(wp) :: dt = 0.0_wp
    real(wp) :: time = 0.0_wp
    real(wp) :: theta = 0.5_wp  ! Time integration parameter (0=explicit, 1=implicit, 0.5=Crank-Nicolson)
    
    ! Solver parameters
    integer(i4) :: max_iterations = 50_i4
    real(wp) :: tolerance = 1.0e-6_wp
    logical :: converged = .false.
    integer(i4) :: iterations = 0_i4
    
  contains
    procedure, public :: Init => MD_UniFldSys_Init
    procedure, public :: AddField => MD_UniFldSys_AddField
    procedure, public :: AddCoupling => MD_UniFldSys_AddCoupling
    procedure, public :: AssembleGlobal => MD_UniFldSys_AssembleGlobal
    procedure, public :: ComputeResidual => MD_UniFldSys_ComputeResidual
    procedure, public :: ComputeTangent => MD_UniFldSys_ComputeTangent
    procedure, public :: Solve => MD_UniFldSys_Solv
    procedure, public :: UpdateTimeStep => MD_UniFldSys_UpdateTimeStep
    procedure, public :: GetFieldEquation => MD_UniFldSys_GetFieldEquation
    procedure, public :: GetTotalDOFs => MD_UniFldSys_GetTotalDOFs
    procedure, public :: Clean => MD_UniFldSys_Clean
  end type MD_UniFldSys

  ! ===================================================================
  ! Unified Field Manager (Enhanced)
  ! ===================================================================
  type, public :: MD_UniFldMgr
    !! Enhanced unified field manager
    
    type(MD_FieldManager) :: base_manager
    type(MD_UniFldSys) :: unified_system
    
    logical :: is_initialized = .false.
    
  contains
    procedure, public :: Init => MD_UniFldMgr_Init
    procedure, public :: RegisterField => MD_UniFldMgr_RegisterField
    procedure, public :: RegisterCoupling => MD_UniFldMgr_RegCoupling
    procedure, public :: GetFieldSystem => MD_UniFldMgr_GetFieldSystem
    procedure, public :: Clean => MD_UniFldMgr_Clean
  end type MD_UniFldMgr

  ! ===================================================================
  ! MD_FldEq Procedures
  ! ===================================================================
  
  subroutine MD_FldEq_Init(this, field_id, field_type, n_dofs, system_type, dt, status)
    class(MD_FldEq), intent(inout) :: this
    integer(i4), intent(in) :: field_id, field_type, n_dofs
    integer(i4), intent(in), optional :: system_type
    real(wp), intent(in), optional :: dt
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (n_dofs <= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of DOFs"
      return
    end if
    
    this%field_id = field_id
    this%field_type = field_type
    this%n_dofs = n_dofs
    
    if (present(system_type)) then
      this%system_type = system_type
    else
      ! Determine system type from field type
      if (field_type == MD_FIELD_DISPLACEMENT .or. field_type == MD_FIELD_ROTATION) then
        this%system_type = MD_SYS_SECOND_ORDER
      else
        this%system_type = MD_SYS_FIRST_ORDER
      end if
    end if
    
    if (present(dt)) then
      this%dt = dt
    end if
    
    ! Allocate matrices and vectors
    allocate(this%C(n_dofs, n_dofs))
    allocate(this%K(n_dofs, n_dofs))
    allocate(this%f_int(n_dofs))
    allocate(this%f_ext(n_dofs))
    allocate(this%phi(n_dofs))
    allocate(this%phi_dot(n_dofs))
    allocate(this%residual(n_dofs))
    allocate(this%K_tangent(n_dofs, n_dofs))
    
    this%C = 0.0_wp
    this%K = 0.0_wp
    this%f_int = 0.0_wp
    this%f_ext = 0.0_wp
    this%phi = 0.0_wp
    this%phi_dot = 0.0_wp
    this%residual = 0.0_wp
    this%K_tangent = 0.0_wp
    
    ! For second-order systems, allocate M and D
    if (this%system_type == MD_SYS_SECOND_ORDER) then
      allocate(this%M(n_dofs, n_dofs))
      allocate(this%D(n_dofs, n_dofs))
      allocate(this%phi_ddot(n_dofs))
      this%M = 0.0_wp
      this%D = 0.0_wp
      this%phi_ddot = 0.0_wp
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldEq_Init

  subroutine MD_FldEq_ComputeResidual(this, status)
    class(MD_FldEq), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, j
    
    call init_error_status(status)
    
    ! R = f_ext - f_int
    this%residual = this%f_ext - this%f_int
    
    ! R = R - KĂÂˇĂâ?
    do j = 1, this%n_dofs
      do i = 1, this%n_dofs
        this%residual(i) = this%residual(i) - this%K(i,j) * this%phi(j)
      end do
    end do
    
    ! R = R - CĂÂˇĂâ Ăâ?(for first-order systems)
    if (this%system_type == MD_SYS_FIRST_ORDER) then
      do j = 1, this%n_dofs
        do i = 1, this%n_dofs
          this%residual(i) = this%residual(i) - this%C(i,j) * this%phi_dot(j)
        end do
      end do
    end if
    
    ! R = R - MĂÂˇĂâ ĂË?- DĂÂˇĂâ Ăâ?(for second-order systems)
    if (this%system_type == MD_SYS_SECOND_ORDER) then
      do j = 1, this%n_dofs
        do i = 1, this%n_dofs
          this%residual(i) = this%residual(i) - this%M(i,j) * this%phi_ddot(j)
          this%residual(i) = this%residual(i) - this%D(i,j) * this%phi_dot(j)
        end do
      end do
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldEq_ComputeResidual

  subroutine MD_FldEq_ComputeTangent(this, theta, dt, status)
    class(MD_FldEq), intent(inout) :: this
    real(wp), intent(in) :: theta, dt
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, j
    real(wp) :: coeff
    
    call init_error_status(status)
    
    ! K_t = K (Mat tangent stiffness)
    this%K_tangent = this%K
    
    ! Add capacity matrix contribution: K_t = K_t + (1/(ĂÂ¸ĂÂˇĂât))ĂÂˇC
    if (this%system_type == MD_SYS_FIRST_ORDER .and. abs(theta * dt) > 1.0e-30_wp) then
      coeff = 1.0_wp / (theta * dt)
      do j = 1, this%n_dofs
        do i = 1, this%n_dofs
          this%K_tangent(i,j) = this%K_tangent(i,j) + coeff * this%C(i,j)
        end do
      end do
    end if
    
    ! For second-order systems: K_t = K_t + (1/(ĂÂ˛ĂÂˇĂâtĂÂ˛))ĂÂˇM + (ĂÂł/(ĂÂ˛ĂÂˇĂât))ĂÂˇD
    if (this%system_type == MD_SYS_SECOND_ORDER .and. abs(dt) > 1.0e-30_wp) then
      ! Using Newmark-ĂÂ˛ parameters (ĂÂ˛=0.25, ĂÂł=0.5 for average acceleration)
      real(wp), parameter :: beta = 0.25_wp
      real(wp), parameter :: gamma = 0.5_wp
      coeff = 1.0_wp / (beta * dt * dt)
      do j = 1, this%n_dofs
        do i = 1, this%n_dofs
          this%K_tangent(i,j) = this%K_tangent(i,j) + coeff * this%M(i,j)
        end do
      end do
      coeff = gamma / (beta * dt)
      do j = 1, this%n_dofs
        do i = 1, this%n_dofs
          this%K_tangent(i,j) = this%K_tangent(i,j) + coeff * this%D(i,j)
        end do
      end do
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldEq_ComputeTangent

  subroutine MD_FldEq_UpdateState(this, delta_phi, delta_phi_dot, delta_phi_ddot, status)
    class(MD_FldEq), intent(inout) :: this
    real(wp), intent(in) :: delta_phi(:)
    real(wp), intent(in), optional :: delta_phi_dot(:)
    real(wp), intent(in), optional :: delta_phi_ddot(:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, n
    
    call init_error_status(status)
    
    n = min(size(delta_phi), this%n_dofs)
    
    ! Update field variable
    do i = 1, n
      this%phi(i) = this%phi(i) + delta_phi(i)
    end do
    
    ! Update time derivative
    if (present(delta_phi_dot)) then
      n = min(size(delta_phi_dot), this%n_dofs)
      do i = 1, n
        this%phi_dot(i) = this%phi_dot(i) + delta_phi_dot(i)
      end do
    end if
    
    ! Update second time derivative (for second-order systems)
    if (present(delta_phi_ddot) .and. this%system_type == MD_SYS_SECOND_ORDER) then
      n = min(size(delta_phi_ddot), this%n_dofs)
      do i = 1, n
        this%phi_ddot(i) = this%phi_ddot(i) + delta_phi_ddot(i)
      end do
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldEq_UpdateState

  function MD_FldEq_GetResidualNorm(this) result(norm)
    class(MD_FldEq), intent(in) :: this
    real(wp) :: norm
    
    integer(i4) :: i
    
    norm = 0.0_wp
    do i = 1, this%n_dofs
      norm = norm + this%residual(i) * this%residual(i)
    end do
    norm = sqrt(norm)
  end function MD_FldEq_GetResidualNorm

  subroutine MD_FldEq_Clean(this)
    class(MD_FldEq), intent(inout) :: this
    
    if (allocated(this%C)) deallocate(this%C)
    if (allocated(this%K)) deallocate(this%K)
    if (allocated(this%D)) deallocate(this%D)
    if (allocated(this%M)) deallocate(this%M)
    if (allocated(this%f_int)) deallocate(this%f_int)
    if (allocated(this%f_ext)) deallocate(this%f_ext)
    if (allocated(this%phi)) deallocate(this%phi)
    if (allocated(this%phi_dot)) deallocate(this%phi_dot)
    if (allocated(this%phi_ddot)) deallocate(this%phi_ddot)
    if (allocated(this%residual)) deallocate(this%residual)
    if (allocated(this%K_tangent)) deallocate(this%K_tangent)
  end subroutine MD_FldEq_Clean

  ! ===================================================================
  ! MD_FldSysType Procedures
  ! ===================================================================
  
  subroutine MD_FldSysType_Init(this, n_fields, status)
    class(MD_FldSysType), intent(inout) :: this
    integer(i4), intent(in) :: n_fields
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (n_fields <= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of fields"
      return
    end if
    
    this%n_fields = n_fields
    allocate(this%field_types(n_fields))
    allocate(this%field_orders(n_fields))
    allocate(this%coupling_matrix(n_fields, n_fields))
    
    this%field_types = MD_FIELD_UNKNOWN
    this%field_orders = 1_i4
    this%coupling_matrix = 0_i4
    this%is_coupled = .false.
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldSysType_Init

  subroutine MD_FldSysType_AddField(this, field_id, field_type, field_order, status)
    class(MD_FldSysType), intent(inout) :: this
    integer(i4), intent(in) :: field_id, field_type
    integer(i4), intent(in), optional :: field_order
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (field_id < 1 .or. field_id > this%n_fields) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid field ID"
      return
    end if
    
    this%field_types(field_id) = field_type
    if (present(field_order)) then
      this%field_orders(field_id) = field_order
    else
      ! Determine order from field type
      if (field_type == MD_FIELD_DISPLACEMENT .or. field_type == MD_FIELD_ROTATION) then
        this%field_orders(field_id) = 2_i4
      else
        this%field_orders(field_id) = 1_i4
      end if
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldSysType_AddField

  subroutine MD_FldSysType_SetCoupling(this, field1_id, field2_id, coupling_type, status)
    class(MD_FldSysType), intent(inout) :: this
    integer(i4), intent(in) :: field1_id, field2_id, coupling_type
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (field1_id < 1 .or. field1_id > this%n_fields .or. &
        field2_id < 1 .or. field2_id > this%n_fields) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid field ID"
      return
    end if
    
    this%coupling_matrix(field1_id, field2_id) = coupling_type
    if (coupling_type /= 0) then
      this%is_coupled = .true.
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldSysType_SetCoupling

  subroutine MD_FldSysType_Clean(this)
    class(MD_FldSysType), intent(inout) :: this
    
    if (allocated(this%field_types)) deallocate(this%field_types)
    if (allocated(this%field_orders)) deallocate(this%field_orders)
    if (allocated(this%coupling_matrix)) deallocate(this%coupling_matrix)
  end subroutine MD_FldSysType_Clean

  ! ===================================================================
  ! MD_FldCplDesc Procedures
  ! ===================================================================
  
  subroutine MD_FldCplDesc_Init(this, field1_id, field2_id, field1_type, field2_type, &
                       n_dofs1, n_dofs2, coupling_type, status)
    class(MD_FldCplDesc), intent(inout) :: this
    integer(i4), intent(in) :: field1_id, field2_id, field1_type, field2_type
    integer(i4), intent(in) :: n_dofs1, n_dofs2
    integer(i4), intent(in), optional :: coupling_type
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    this%field1_id = field1_id
    this%field2_id = field2_id
    this%field1_type = field1_type
    this%field2_type = field2_type
    
    if (present(coupling_type)) then
      this%coupling_type = coupling_type
    else
      this%coupling_type = 2_i4  ! Default: two-way coupling
    end if
    
    if (this%coupling_type /= 0) then
      allocate(this%coupling_matrix(n_dofs1, n_dofs2))
      this%coupling_matrix = 0.0_wp
      this%is_active = .true.
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldCplDesc_Init

  subroutine MD_Fl_ComputeCouplingTerm(this, phi1, phi2, coupling_term, status)
    class(MD_FldCplDesc), intent(in) :: this
    real(wp), intent(in) :: phi1(:), phi2(:)
    real(wp), intent(out) :: coupling_term(:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, j, n1, n2
    
    call init_error_status(status)
    
    if (.not. this%is_active .or. .not. allocated(this%coupling_matrix)) then
      coupling_term = 0.0_wp
      status%status_code = IF_STATUS_OK
      return
    end if
    
    n1 = min(size(phi1), size(this%coupling_matrix, 1))
    n2 = min(size(phi2), size(this%coupling_matrix, 2))
    n1 = min(n1, size(coupling_term))
    
    coupling_term = 0.0_wp
    do j = 1, n2
      do i = 1, n1
        coupling_term(i) = coupling_term(i) + &
          this%coupling_matrix(i,j) * phi2(j) * this%cpl_strength
      end do
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldCplDesc_ComputeCouplingTerm

  subroutine MD_FldCplDesc_Clean(this)
    class(MD_FldCplDesc), intent(inout) :: this
    
    if (allocated(this%coupling_matrix)) deallocate(this%coupling_matrix)
  end subroutine MD_FldCplDesc_Clean

  ! ===================================================================
  ! MD_UniFldSys Procedures
  ! ===================================================================
  
  subroutine MD_UniFldSys_Init(this, n_fields, dt, theta, status)
    class(MD_UniFldSys), intent(inout) :: this
    integer(i4), intent(in) :: n_fields
    real(wp), intent(in), optional :: dt, theta
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    call this%system_config%Init(n_fields, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    allocate(this%field_equations(n_fields))
    
    if (present(dt)) then
      this%dt = dt
    end if
    
    if (present(theta)) then
      this%theta = theta
    end if
    
    call this%field_manager%Init(n_fields, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    this%is_initialized = .true.
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSys_Init

  subroutine MD_UniFldSys_AddField(this, field_id, field_type, n_dofs, system_type, status)
    class(MD_UniFldSys), intent(inout) :: this
    integer(i4), intent(in) :: field_id, field_type, n_dofs
    integer(i4), intent(in), optional :: system_type
    type(ErrorStatusType), intent(out) :: status
    
    type(MD_FieldDesc) :: field_desc
    
    call init_error_status(status)
    
    if (.not. this%is_initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "System not initialized"
      return
    end if
    
    ! Add to system configuration
    call this%system_config%AddField(field_id, field_type, status=status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Init field equation
    call this%field_equations(field_id)%Init(field_id, field_type, n_dofs, &
                                                   system_type, this%dt, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Reg in field manager
    call field_desc%Init(field_id, field_type, GetFieldTypeName(field_type), &
                              n_dofs, GetFieldOrder(field_type))
    call this%field_manager%RegisterField(field_desc, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Update total DOFs
    this%n_dofs_total = this%n_dofs_total + n_dofs
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSys_AddField

  subroutine MD_UniFldSys_AddCoupling(this, field1_id, field2_id, field1_type, field2_type, &
                        n_dofs1, n_dofs2, coupling_type, status)
    class(MD_UniFldSys), intent(inout) :: this
    integer(i4), intent(in) :: field1_id, field2_id, field1_type, field2_type
    integer(i4), intent(in) :: n_dofs1, n_dofs2
    integer(i4), intent(in), optional :: coupling_type
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: n_couplings
    type(MD_FldCplDesc), allocatable :: temp_couplings(:)
    
    call init_error_status(status)
    
    ! Add to system configuration
    call this%system_config%SetCoupling(field1_id, field2_id, &
                                       merge(2_i4, 0_i4, present(coupling_type) .and. coupling_type /= 0), &
                                       status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Add coupling descriptor
    n_couplings = 0_i4
    if (allocated(this%couplings)) n_couplings = size(this%couplings)
    
    allocate(temp_couplings(n_couplings + 1))
    if (n_couplings > 0) then
      temp_couplings(1:n_couplings) = this%couplings
      deallocate(this%couplings)
    end if
    allocate(this%couplings(n_couplings + 1))
    this%couplings(1:n_couplings) = temp_couplings(1:n_couplings)
    deallocate(temp_couplings)
    
    call this%couplings(n_couplings + 1)%Init(field1_id, field2_id, &
                                                   field1_type, field2_type, &
                                                   n_dofs1, n_dofs2, &
                                                   coupling_type, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Reg in field manager
    call this%field_manager%AddCoupling(field1_type, field2_type, coupling_type, &
                                        status=status)
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSys_AddCoupling

  subroutine MD_UniFldSys_AssembleGlobal(this, status)
    class(MD_UniFldSys), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, j, k, offset_i, offset_j
    integer(i4) :: n_dofs_i, n_dofs_j
    
    call init_error_status(status)
    
    ! Build DOF map
    call this%field_manager%BuildDOFMap(status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Allocate global matrices
    if (allocated(this%K_global)) deallocate(this%K_global)
    if (allocated(this%C_global)) deallocate(this%C_global)
    if (allocated(this%M_global)) deallocate(this%M_global)
    if (allocated(this%R_global)) deallocate(this%R_global)
    if (allocated(this%phi_global)) deallocate(this%phi_global)
    
    allocate(this%K_global(this%n_dofs_total, this%n_dofs_total))
    allocate(this%C_global(this%n_dofs_total, this%n_dofs_total))
    allocate(this%M_global(this%n_dofs_total, this%n_dofs_total))
    allocate(this%R_global(this%n_dofs_total))
    allocate(this%phi_global(this%n_dofs_total))
    
    this%K_global = 0.0_wp
    this%C_global = 0.0_wp
    this%M_global = 0.0_wp
    this%R_global = 0.0_wp
    this%phi_global = 0.0_wp
    
    ! Assemble field matrices
    offset_i = 0_i4
    do i = 1, this%system_config%n_fields
      n_dofs_i = this%field_equations(i)%n_dofs
      
      ! Diagonal blocks
      this%K_global(offset_i+1:offset_i+n_dofs_i, offset_i+1:offset_i+n_dofs_i) = &
        this%field_equations(i)%K
      this%C_global(offset_i+1:offset_i+n_dofs_i, offset_i+1:offset_i+n_dofs_i) = &
        this%field_equations(i)%C
      if (allocated(this%field_equations(i)%M)) then
        this%M_global(offset_i+1:offset_i+n_dofs_i, offset_i+1:offset_i+n_dofs_i) = &
          this%field_equations(i)%M
      end if
      
      ! Assemble field solution and residual
      this%phi_global(offset_i+1:offset_i+n_dofs_i) = this%field_equations(i)%phi
      this%R_global(offset_i+1:offset_i+n_dofs_i) = this%field_equations(i)%residual
      
      offset_i = offset_i + n_dofs_i
    end do
    
    ! Assemble coupling terms
    if (allocated(this%couplings)) then
      do k = 1, size(this%couplings)
        if (.not. this%couplings(k)%is_active) cycle
        
        i = this%couplings(k)%field1_id
        j = this%couplings(k)%field2_id
        
        ! Find DOF offsets
        offset_i = 0_i4
        do k = 1, i - 1
          offset_i = offset_i + this%field_equations(k)%n_dofs
        end do
        
        offset_j = 0_i4
        do k = 1, j - 1
          offset_j = offset_j + this%field_equations(k)%n_dofs
        end do
        
        n_dofs_i = this%field_equations(i)%n_dofs
        n_dofs_j = this%field_equations(j)%n_dofs
        
        ! Add coupling matrix
        if (allocated(this%couplings(k)%coupling_matrix)) then
          this%K_global(offset_i+1:offset_i+n_dofs_i, offset_j+1:offset_j+n_dofs_j) = &
            this%K_global(offset_i+1:offset_i+n_dofs_i, offset_j+1:offset_j+n_dofs_j) + &
            this%couplings(k)%coupling_matrix
        end if
      end do
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSys_AssembleGlobal

  subroutine MD_UniFldSys_ComputeResidual(this, status)
    class(MD_UniFldSys), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    ! Compute residual for each field
    do i = 1, this%system_config%n_fields
      call this%field_equations(i)%ComputeResidual(status)
      if (status%status_code /= IF_STATUS_OK) return
    end do
    
    ! Assemble global residual
    call this%AssembleGlobal(status)
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSys_ComputeResidual

  subroutine MD_UniFldSys_ComputeTangent(this, status)
    class(MD_UniFldSys), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    ! Compute tangent operator for each field
    do i = 1, this%system_config%n_fields
      call this%field_equations(i)%ComputeTangent(this%theta, this%dt, status)
      if (status%status_code /= IF_STATUS_OK) return
    end do
    
    ! Assemble global tangent operator
    call this%AssembleGlobal(status)
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSys_ComputeTangent

  subroutine MD_UniFldSys_Solv(this, status)
    !! ?-gradeNewton-Raphsoniterationimplements
    !! Step 1: init status iterationparam
    !! Step 2: Newton-Raphsoniteration 
    !! Step 3: computation 
    !! Step 4: convergence check ? ? ? ?
    !! Step 5:  
    !! Step 6: return ?
    class(MD_UniFldSys), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: iter, max_iter
    real(wp) :: residual_norm, delta_norm, energy_norm
    real(wp) :: tol_residual, tol_delta, tol_energy
    logical :: converged_residual, converged_delta, converged_energy
    
    call init_error_status(status)
    
    ! Step 1: init param
    max_iter = 50_i4
    tol_residual = 1.0e-6_wp
    tol_delta = 1.0e-8_wp
    tol_energy = 1.0e-10_wp
    this%converged = .false.
    this%iterations = 0_i4
    
    ! Step 2: Newton-Raphsoniteration 
    do iter = 1, max_iter
      this%iterations = iter
      
      ! Step 3: computation 
      call this%ComputeResidual(status)
      if (status%status_code /= IF_STATUS_OK) then
        status%message = 'MD_UniFldSys_Solv: Residual computation failed at iteration ' // &
                        trim(adjustl(i4_to_str(iter)))
        return
      end if
      
      ! Step 3: computation stiffnessmatrix
      call this%ComputeTangent(status)
      if (status%status_code /= IF_STATUS_OK) then
        status%message = 'MD_UniFldSys_Solv: Tangent computation failed at iteration ' // &
                        trim(adjustl(i4_to_str(iter)))
        return
      end if
      
      ! Step 4: convergence 
      ! computation 
      if (allocated(this%R_global)) then
        residual_norm = sqrt(dot_product(this%R_global, this%R_global))
      else
        residual_norm = 0.0_wp
      end if
      
      ! computation ?phi_global ?
      if (allocated(this%phi_global)) then
        delta_norm = sqrt(dot_product(this%phi_global, this%phi_global))
      else
        delta_norm = 0.0_wp
      end if
      
      ! computation  (R·Δu)
      if (allocated(this%R_global) .and. allocated(this%phi_global)) then
        energy_norm = abs(dot_product(this%R_global, this%phi_global))
      else
        energy_norm = 0.0_wp
      end if
      
      !  convergence ?
      converged_residual = (residual_norm < tol_residual)
      converged_delta = (delta_norm < tol_delta)
      converged_energy = (energy_norm < tol_energy)
      
      !  
      if ((converged_residual .and. converged_delta) .or. &
          (converged_residual .and. converged_energy) .or. &
          (converged_delta .and. converged_energy)) then
        this%converged = .true.
        status%status_code = IF_STATUS_OK
        write(status%message, '(A,I0,A,3(A,ES12.5))') &
          'MD_UniFldSys_Solv: Converged at iteration ', iter, &
          ', R_norm=', residual_norm, ', Δ_norm=', delta_norm, ', E_norm=', energy_norm
        return
      end if
      
      ! Step 5: vector ?Runtime ?
      !  iterationstatus ?
      
    end do
    
    ! Step 6: convergence return ?
    this%converged = .false.
    status%status_code = IF_STATUS_INVALID
    write(status%message, '(A,I0,A,3(A,ES12.5))') &
      'MD_UniFldSys_Solv: Failed to converge after ', max_iter, ' iterations', &
      ', R_norm=', residual_norm, ', Δ_norm=', delta_norm, ', E_norm=', energy_norm
      
  contains
    ! utils ?
    function i4_to_str(i) result(str)
      integer(i4), intent(in) :: i
      character(len=32) :: str
      write(str, '(I0)') i
    end function i4_to_str
    
  end subroutine MD_UniFldSys_Solv

  subroutine MD_UniFldSys_UpdateTimeStep(this, dt, time, status)
    class(MD_UniFldSys), intent(inout) :: this
    real(wp), intent(in) :: dt, time
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    this%dt = dt
    this%time = time
    
    ! Update time step for each field equation
    do i = 1, this%system_config%n_fields
      this%field_equations(i)%dt = dt
      this%field_equations(i)%time = time
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSys_UpdateTimeStep

  subroutine MD_Un_GetFieldEquation(this, field_id, field_eq, status)
    class(MD_UniFldSys), intent(in) :: this
    integer(i4), intent(in) :: field_id
    type(MD_FldEq), intent(out) :: field_eq
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (field_id < 1 .or. field_id > this%system_config%n_fields) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid field ID"
      return
    end if
    
    field_eq = this%field_equations(field_id)
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSys_GetFieldEquation

  function MD_UniFldSys_GetTotalDOFs(this) result(n_dofs)
    class(MD_UniFldSys), intent(in) :: this
    integer(i4) :: n_dofs
    n_dofs = this%n_dofs_total
  end function MD_UniFldSys_GetTotalDOFs

  subroutine MD_UniFldSys_Clean(this)
    class(MD_UniFldSys), intent(inout) :: this
    
    integer(i4) :: i
    
    if (allocated(this%field_equations)) then
      do i = 1, size(this%field_equations)
        call this%field_equations(i)%Clean
      end do
      deallocate(this%field_equations)
    end if
    
    if (allocated(this%couplings)) then
      do i = 1, size(this%couplings)
        call this%couplings(i)%Clean
      end do
      deallocate(this%couplings)
    end if
    
    if (allocated(this%K_global)) deallocate(this%K_global)
    if (allocated(this%C_global)) deallocate(this%C_global)
    if (allocated(this%M_global)) deallocate(this%M_global)
    if (allocated(this%R_global)) deallocate(this%R_global)
    if (allocated(this%phi_global)) deallocate(this%phi_global)
    
    call this%system_config%Clean
    call this%field_manager%Cleanup
    
    this%is_initialized = .false.
  end subroutine MD_UniFldSys_Clean

  ! ===================================================================
  ! MD_UniFldMgr Procedures
  ! ===================================================================
  
  subroutine MD_UniFldMgr_Init(this, n_fields, dt, theta, status)
    class(MD_UniFldMgr), intent(inout) :: this
    integer(i4), intent(in) :: n_fields
    real(wp), intent(in), optional :: dt, theta
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    ! Initialize base_manager and unified_system
    call this%base_manager%Init(n_fields, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call this%unified_system%Init(n_fields, dt, theta, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    this%is_initialized = .true.
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldMgr_Init

  subroutine MD_UniFldMgr_RegisterField(this, field_id, field_type, n_dofs, system_type, status)
    class(MD_UniFldMgr), intent(inout) :: this
    integer(i4), intent(in) :: field_id, field_type, n_dofs
    integer(i4), intent(in), optional :: system_type
    type(ErrorStatusType), intent(out) :: status
    
    ! Inline: directly call unified_system%AddField
    call this%unified_system%AddField(field_id, field_type, n_dofs, system_type, status)
    
  end subroutine MD_UniFldMgr_RegisterField

  subroutine MD_UniFldMgr_RegCoupling(this, field1_id, field2_id, field1_type, field2_type, &
                              n_dofs1, n_dofs2, coupling_type, status)
    class(MD_UniFldMgr), intent(inout) :: this
    integer(i4), intent(in) :: field1_id, field2_id, field1_type, field2_type
    integer(i4), intent(in) :: n_dofs1, n_dofs2
    integer(i4), intent(in), optional :: coupling_type
    type(ErrorStatusType), intent(out) :: status
    
    ! Inline: directly call unified_system%AddCoupling
    call this%unified_system%AddCoupling(field1_id, field2_id, field1_type, field2_type, &
                                        n_dofs1, n_dofs2, coupling_type, status)
    
  end subroutine MD_UniFldMgr_RegCoupling

  function MD_UniFldMgr_GetFieldSystem(this) result(system)
    class(MD_UniFldMgr), intent(in) :: this
    type(MD_UniFldSys) :: system
    ! Inline: directly return unified_system
    system = this%unified_system
  end function MD_UniFldMgr_GetFieldSystem

  subroutine MD_UniFldMgr_Clean(this)
    class(MD_UniFldMgr), intent(inout) :: this
    
    ! Cleanup both base_manager and unified_system
    call this%base_manager%Cleanup
    call this%unified_system%Clean
    this%is_initialized = .false.
  end subroutine MD_UniFldMgr_Clean

  ! ===================================================================
  ! Field State Snapshot (from UF_UnifiedField_State)
  ! ===================================================================
  type, public :: MD_FldStaSnap
    !! Snapshot of field state at a specific time
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: field_type = MD_FIELD_UNKNOWN
    real(wp) :: time = 0.0_wp
    integer(i4) :: n_dofs = 0_i4
    integer(i4) :: order = 1_i4
    
    ! Field values
    real(wp), allocatable :: phi(:)
    real(wp), allocatable :: phi_dot(:)
    real(wp), allocatable :: phi_ddot(:)
    
    ! Metadata
    integer(i8) :: timestamp = 0_i8
    character(len=256) :: description = ""
    
  contains
    procedure, public :: Init => MD_FldStaSnap_Init
    procedure, public :: CopyFrom => MD_FldStaSnap_CopyFrom
    procedure, public :: CopyTo => MD_FldStaSnap_CopyTo
    procedure, public :: Ser => MD_FldStaSnap_Ser
    procedure, public :: Deserial => MD_FldStaSnap_Deserial
    procedure, public :: Clean => MD_FldStaSnap_Clean
  end type MD_FldStaSnap

  ! ===================================================================
  ! Field State History
  ! ===================================================================
  type, public :: MD_FldStaHist
    !! History of field states over time
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: field_type = MD_FIELD_UNKNOWN
    integer(i4) :: max_history = 100_i4
    integer(i4) :: current_size = 0_i4
    
    ! History snapshots
    type(MD_FldStaSnap), allocatable :: snapshots(:)
    
    ! Time array
    real(wp), allocatable :: time_array(:)
    
  contains
    procedure, public :: Init => MD_FldStaHist_Init
    procedure, public :: AddSnap => MD_FldStaHist_AddSnap
    procedure, public :: GetSnap => MD_FldStaHist_GetSnap
    procedure, public :: GetSnapAtTime => MD_FldStaHist_GetSnapAtTime
    procedure, public :: GetLatestSnap => MD_FldStaHist_GetLatestSnap
    procedure, public :: Clear => MD_FldStaHist_Clear
    procedure, public :: Clean => MD_FldStaHist_Clean
  end type MD_FldStaHist

  ! ===================================================================
  ! Unified Field State (Enhanced)
  ! ===================================================================
  type, public :: MD_UniFldSta
    !! Enhanced unified field state
    
    ! Base state (from MD_Field_Mgr)
    type(MD_Field_Mgr) :: base_state
    
    ! Current state
    real(wp), allocatable :: phi(:)           ! Field values
    real(wp), allocatable :: phi_dot(:)       ! Field velocities
    real(wp), allocatable :: phi_ddot(:)      ! Field accelerations
    
    ! Previous state
    real(wp), allocatable :: phi_old(:)
    real(wp), allocatable :: phi_dot_old(:)
    real(wp), allocatable :: phi_ddot_old(:)
    
    ! State history
    type(MD_FldStaHist) :: history
    
    ! Checkpoint state
    type(MD_FldStaSnap) :: checkpoint
    
    ! State metadata
    real(wp) :: time = 0.0_wp
    real(wp) :: dt = 0.0_wp
    integer(i4) :: step = 0_i4
    integer(i4) :: iteration = 0_i4
    
    ! State flags
    logical :: has_checkpoint = .false.
    logical :: is_dirty = .false.
    
  contains
    procedure, public :: Init => MD_UniFldSta_Init
    procedure, public :: UpdateSta => MD_UniFldSta_UpdateSta
    procedure, public :: SaveChkpt => MD_UniFldSta_SaveChkpt
    procedure, public :: RestoreChkpt => MD_UniFldSta_RestoreChkpt
    procedure, public :: AddToHist => MD_UniFldSta_AddToHist
    procedure, public :: GetStaAtTime => MD_UniFldSta_GetStaAtTime
    procedure, public :: CopyFromFldEq => MD_UniFldSta_CopyFromFldEq
    procedure, public :: CopyToFldEq => MD_UniFldSta_CopyToFldEq
    procedure, public :: Ser => MD_UniFldSta_Ser
    procedure, public :: Deserial => MD_UniFldSta_Deserial
    procedure, public :: Clean => MD_UniFldSta_Clean
  end type MD_UniFldSta

  ! ===================================================================
  ! State Manager
  ! ===================================================================
  type, public :: MD_FldStaMgr
    !! Manager for multiple field states
    
    logical :: is_initialized = .false.
    
    integer(i4) :: n_fields = 0_i4
    type(MD_UniFldSta), allocatable :: field_states(:)
    
    ! Global state metadata
    real(wp) :: global_time = 0.0_wp
    real(wp) :: global_dt = 0.0_wp
    integer(i4) :: global_step = 0_i4
    
    ! Checkpoint directory
    character(len=512) :: checkpoint_dir = "./checkpoints"
    
  contains
    procedure, public :: Init => MD_FldStaMgr_Init
    procedure, public :: RegField => MD_FldStaMgr_RegField
    procedure, public :: UpdateAllSta => MD_FldStaMgr_UpdateAllSta
    procedure, public :: SaveAllChkpt => MD_FldStaMgr_SaveAllChkpt
    procedure, public :: RestoreAllChkpt => MD_FldStaMgr_RestoreAllChkpt
    procedure, public :: GetFldSta => MD_FldStaMgr_GetFldSta
    procedure, public :: Clean => MD_FldStaMgr_Clean
  end type MD_FldStaMgr

  ! ===================================================================
  ! MD_FldStaSnap Procedures
  ! ===================================================================
  
  subroutine MD_FldStaSnap_Init(this, field_id, field_type, n_dofs, order, time, status)
    class(MD_FldStaSnap), intent(inout) :: this
    integer(i4), intent(in) :: field_id, field_type, n_dofs
    integer(i4), intent(in), optional :: order
    real(wp), intent(in), optional :: time
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (n_dofs <= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of DOFs"
      return
    end if
    
    this%field_id = field_id
    this%field_type = field_type
    this%n_dofs = n_dofs
    
    if (present(order)) then
      this%order = order
    else
      this%order = 1_i4
    end if
    
    if (present(time)) then
      this%time = time
    end if
    
    allocate(this%phi(n_dofs))
    this%phi = 0.0_wp
    
    if (this%order >= 1) then
      allocate(this%phi_dot(n_dofs))
      this%phi_dot = 0.0_wp
    end if
    
    if (this%order >= 2) then
      allocate(this%phi_ddot(n_dofs))
      this%phi_ddot = 0.0_wp
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaSnap_Init

  subroutine MD_FldStaSnap_CopyFrom(this, source, status)
    class(MD_FldStaSnap), intent(inout) :: this
    type(MD_FldStaSnap), intent(in) :: source
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: n
    
    call init_error_status(status)
    
    if (this%n_dofs /= source%n_dofs) then
      status%status_code = IF_STATUS_INVALID
      status%message = "DOF mismatch"
      return
    end if
    
    this%field_id = source%field_id
    this%field_type = source%field_type
    this%time = source%time
    this%order = source%order
    this%timestamp = source%timestamp
    this%cfg%description = source%cfg%description
    
    n = min(size(this%phi), size(source%phi))
    this%phi(1:n) = source%phi(1:n)
    
    if (allocated(this%phi_dot) .and. allocated(source%phi_dot)) then
      n = min(size(this%phi_dot), size(source%phi_dot))
      this%phi_dot(1:n) = source%phi_dot(1:n)
    end if
    
    if (allocated(this%phi_ddot) .and. allocated(source%phi_ddot)) then
      n = min(size(this%phi_ddot), size(source%phi_ddot))
      this%phi_ddot(1:n) = source%phi_ddot(1:n)
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaSnap_CopyFrom

  subroutine MD_FldStaSnap_CopyTo(this, target, status)
    class(MD_FldStaSnap), intent(in) :: this
    type(MD_FldStaSnap), intent(inout) :: target
    type(ErrorStatusType), intent(out) :: status
    
    call target%CopyFrom(this, status)
  end subroutine MD_FldStaSnap_CopyTo

  subroutine MD_FldStaSnap_Ser(this, buffer, status)
    class(MD_FldStaSnap), intent(in) :: this
    real(wp), intent(out), allocatable :: buffer(:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: offset, n
    
    call init_error_status(status)
    
    ! Estimate buffer size: header (10) + phi + phi_dot + phi_ddot
    n = 10_i4 + this%n_dofs
    if (allocated(this%phi_dot)) n = n + this%n_dofs
    if (allocated(this%phi_ddot)) n = n + this%n_dofs
    
    allocate(buffer(n))
    buffer = 0.0_wp
    
    ! Serialize header
    buffer(1) = real(this%field_id, wp)
    buffer(2) = real(this%field_type, wp)
    buffer(3) = real(this%n_dofs, wp)
    buffer(4) = real(this%order, wp)
    buffer(5) = this%time
    buffer(6) = real(this%timestamp, wp)
    
    ! Serialize phi
    offset = 7
    buffer(offset:offset+this%n_dofs-1) = this%phi
    
    ! Serialize phi_dot
    if (allocated(this%phi_dot)) then
      offset = offset + this%n_dofs
      buffer(offset:offset+this%n_dofs-1) = this%phi_dot
    end if
    
    ! Serialize phi_ddot
    if (allocated(this%phi_ddot)) then
      offset = offset + this%n_dofs
      buffer(offset:offset+this%n_dofs-1) = this%phi_ddot
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaSnap_Ser

  subroutine MD_FldStaSnap_Deserial(this, buffer, status)
    class(MD_FldStaSnap), intent(inout) :: this
    real(wp), intent(in) :: buffer(:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: offset, n_dofs, order
    
    call init_error_status(status)
    
    if (size(buffer) < 6) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid buffer size"
      return
    end if
    
    ! Deserialize header
    this%field_id = int(buffer(1), i4)
    this%field_type = int(buffer(2), i4)
    n_dofs = int(buffer(3), i4)
    order = int(buffer(4), i4)
    this%time = buffer(5)
    this%timestamp = int(buffer(6), i8)
    
    ! Init if needed
    if (this%n_dofs /= n_dofs) then
      call this%Init(this%field_id, this%field_type, n_dofs, order, this%time, status)
      if (status%status_code /= IF_STATUS_OK) return
    end if
    
    ! Deserialize phi
    offset = 7
    if (size(buffer) < offset + n_dofs - 1) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Buffer too small for phi"
      return
    end if
    this%phi = buffer(offset:offset+n_dofs-1)
    
    ! Deserialize phi_dot
    if (order >= 1) then
      offset = offset + n_dofs
      if (size(buffer) >= offset + n_dofs - 1) then
        if (allocated(this%phi_dot)) then
          this%phi_dot = buffer(offset:offset+n_dofs-1)
        end if
      end if
    end if
    
    ! Deserialize phi_ddot
    if (order >= 2) then
      offset = offset + n_dofs
      if (size(buffer) >= offset + n_dofs - 1) then
        if (allocated(this%phi_ddot)) then
          this%phi_ddot = buffer(offset:offset+n_dofs-1)
        end if
      end if
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaSnap_Deserial

  subroutine MD_FldStaSnap_Clean(this)
    class(MD_FldStaSnap), intent(inout) :: this
    
    if (allocated(this%phi)) deallocate(this%phi)
    if (allocated(this%phi_dot)) deallocate(this%phi_dot)
    if (allocated(this%phi_ddot)) deallocate(this%phi_ddot)
  end subroutine MD_FldStaSnap_Clean

  ! ===================================================================
  ! MD_FldStaHist Procedures
  ! ===================================================================
  
  subroutine MD_FldStaHist_Init(this, field_id, field_type, max_history, status)
    class(MD_FldStaHist), intent(inout) :: this
    integer(i4), intent(in) :: field_id, field_type
    integer(i4), intent(in), optional :: max_history
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    this%field_id = field_id
    this%field_type = field_type
    
    if (present(max_history)) then
      this%max_history = max_history
    end if
    
    allocate(this%snapshots(this%max_history))
    allocate(this%time_array(this%max_history))
    this%time_array = 0.0_wp
    this%current_size = 0_i4
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaHist_Init

  subroutine MD_FldStaHist_AddSnap(this, snapshot, status)
    class(MD_FldStaHist), intent(inout) :: this
    type(MD_FldStaSnap), intent(in) :: snapshot
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    ! Shift existing snapshots if at capacity
    if (this%current_size >= this%max_history) then
      do i = 1, this%max_history - 1
        call this%snapshots(i)%CopyFrom(this%snapshots(i+1), status)
        if (status%status_code /= IF_STATUS_OK) return
        this%time_array(i) = this%time_array(i+1)
      end do
      this%current_size = this%max_history - 1
    end if
    
    ! Add new snapshot
    this%current_size = this%current_size + 1
    call this%snapshots(this%current_size)%CopyFrom(snapshot, status)
    if (status%status_code /= IF_STATUS_OK) return
    this%time_array(this%current_size) = snapshot%time
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaHist_AddSnap

  subroutine MD_FldStaHist_GetSnap(this, index, snapshot, status)
    class(MD_FldStaHist), intent(in) :: this
    integer(i4), intent(in) :: index
    type(MD_FldStaSnap), intent(out) :: snapshot
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (index < 1 .or. index > this%current_size) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid snapshot index"
      return
    end if
    
    call snapshot%CopyFrom(this%snapshots(index), status)
  end subroutine MD_FldStaHist_GetSnap

  subroutine MD_FldStaHist_GetSnapAtTime(this, time, snapshot, tolerance, status)
    class(MD_FldStaHist), intent(in) :: this
    real(wp), intent(in) :: time
    type(MD_FldStaSnap), intent(out) :: snapshot
    real(wp), intent(in), optional :: tolerance
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    real(wp) :: tol, min_diff, diff
    integer(i4) :: best_index
    
    call init_error_status(status)
    
    if (present(tolerance)) then
      tol = tolerance
    else
      tol = 1.0e-6_wp
    end if
    
    best_index = 0
    min_diff = huge(1.0_wp)
    
    do i = 1, this%current_size
      diff = abs(this%time_array(i) - time)
      if (diff < min_diff) then
        min_diff = diff
        best_index = i
      end if
    end do
    
    if (best_index == 0 .or. min_diff > tol) then
      status%status_code = IF_STATUS_NOT_FOUND
      status%message = "No snapshot found at specified time"
      return
    end if
    
    call snapshot%CopyFrom(this%snapshots(best_index), status)
  end subroutine MD_FldStaHist_GetSnapAtTime

  subroutine MD_FldStaHist_GetLatestSnap(this, snapshot, status)
    class(MD_FldStaHist), intent(in) :: this
    type(MD_FldStaSnap), intent(out) :: snapshot
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (this%current_size == 0) then
      status%status_code = IF_STATUS_NOT_FOUND
      status%message = "No snapshots available"
      return
    end if
    
    call snapshot%CopyFrom(this%snapshots(this%current_size), status)
  end subroutine MD_FldStaHist_GetLatestSnap

  subroutine MD_FldStaHist_Clear(this)
    class(MD_FldStaHist), intent(inout) :: this
    this%current_size = 0_i4
    this%time_array = 0.0_wp
  end subroutine MD_FldStaHist_Clear

  subroutine MD_FldStaHist_Clean(this)
    class(MD_FldStaHist), intent(inout) :: this
    
    integer(i4) :: i
    
    if (allocated(this%snapshots)) then
      do i = 1, size(this%snapshots)
        call this%snapshots(i)%Clean
      end do
      deallocate(this%snapshots)
    end if
    
    if (allocated(this%time_array)) deallocate(this%time_array)
  end subroutine MD_FldStaHist_Clean

  ! ===================================================================
  ! MD_UniFldSta Procedures
  ! ===================================================================
  
  subroutine MD_UniFldSta_Init(this, field_id, field_type, n_dofs, order, max_history, status)
    class(MD_UniFldSta), intent(inout) :: this
    integer(i4), intent(in) :: field_id, field_type, n_dofs
    integer(i4), intent(in), optional :: order
    integer(i4), intent(in), optional :: max_history
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: order_val, max_hist
    
    call init_error_status(status)
    
    if (present(order)) then
      order_val = order
    else
      order_val = 1_i4
    end if
    
    if (present(max_history)) then
      max_hist = max_history
    else
      max_hist = 100_i4
    end if
    
    ! Init base state
    call this%base_state%Init(field_id, field_type, "", n_dofs, order_val)
    call this%base_state%AllocateDOFs(max_hist)
    
    ! Allocate current state
    allocate(this%phi(n_dofs))
    allocate(this%phi_dot(n_dofs))
    if (order_val >= 2) then
      allocate(this%phi_ddot(n_dofs))
    end if
    
    ! Allocate old state
    allocate(this%phi_old(n_dofs))
    allocate(this%phi_dot_old(n_dofs))
    if (order_val >= 2) then
      allocate(this%phi_ddot_old(n_dofs))
    end if
    
    this%phi = 0.0_wp
    this%phi_dot = 0.0_wp
    if (allocated(this%phi_ddot)) this%phi_ddot = 0.0_wp
    this%phi_old = 0.0_wp
    this%phi_dot_old = 0.0_wp
    if (allocated(this%phi_ddot_old)) this%phi_ddot_old = 0.0_wp
    
    ! Init history
    call this%history%Init(field_id, field_type, max_hist, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Init checkpoint
    call this%checkpoint%Init(field_id, field_type, n_dofs, order_val, 0.0_wp, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    this%has_checkpoint = .false.
    this%is_dirty = .false.
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSta_Init

  subroutine MD_UniFldSta_UpdateSta(this, phi_new, phi_dot_new, phi_ddot_new, time, dt, step, iteration, status)
    class(MD_UniFldSta), intent(inout) :: this
    real(wp), intent(in) :: phi_new(:)
    real(wp), intent(in), optional :: phi_dot_new(:), phi_ddot_new(:)
    real(wp), intent(in) :: time, dt
    integer(i4), intent(in), optional :: step, iteration
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: n
    
    call init_error_status(status)
    
    ! Save old state
    n = min(size(this%phi), size(phi_new))
    this%phi_old(1:n) = this%phi(1:n)
    if (allocated(this%phi_dot) .and. present(phi_dot_new)) then
      n = min(size(this%phi_dot), size(phi_dot_new))
      this%phi_dot_old(1:n) = this%phi_dot(1:n)
    end if
    if (allocated(this%phi_ddot) .and. present(phi_ddot_new)) then
      n = min(size(this%phi_ddot), size(phi_ddot_new))
      this%phi_ddot_old(1:n) = this%phi_ddot(1:n)
    end if
    
    ! Update current state
    n = min(size(this%phi), size(phi_new))
    this%phi(1:n) = phi_new(1:n)
    
    if (allocated(this%phi_dot) .and. present(phi_dot_new)) then
      n = min(size(this%phi_dot), size(phi_dot_new))
      this%phi_dot(1:n) = phi_dot_new(1:n)
    end if
    
    if (allocated(this%phi_ddot) .and. present(phi_ddot_new)) then
      n = min(size(this%phi_ddot), size(phi_ddot_new))
      this%phi_ddot(1:n) = phi_ddot_new(1:n)
    end if
    
    ! Update metadata
    this%time = time
    this%dt = dt
    if (present(step)) this%step = step
    if (present(iteration)) this%iteration = iteration
    
    ! Update base state
    call this%base_state%SetValues(this%phi, this%phi_dot, this%phi_dot)
    
    this%is_dirty = .true.
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSta_UpdateSta

  subroutine MD_UniFldSta_SaveChkpt(this, status)
    class(MD_UniFldSta), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    this%checkpoint%field_id = this%base_state%fieldId
    this%checkpoint%field_type = this%base_state%fieldType
    this%checkpoint%time = this%time
    this%checkpoint%n_dofs = this%base_state%nDOFs
    this%checkpoint%order = this%base_state%order
    
    this%checkpoint%phi = this%phi
    if (allocated(this%phi_dot)) then
      this%checkpoint%phi_dot = this%phi_dot
    end if
    if (allocated(this%phi_ddot)) then
      this%checkpoint%phi_ddot = this%phi_ddot
    end if
    
    this%has_checkpoint = .true.
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSta_SaveChkpt

  subroutine MD_UniFldSta_RestoreChkpt(this, status)
    class(MD_UniFldSta), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. this%has_checkpoint) then
      status%status_code = IF_STATUS_NOT_FOUND
      status%message = "No checkpoint available"
      return
    end if
    
    this%phi = this%checkpoint%phi
    if (allocated(this%phi_dot) .and. allocated(this%checkpoint%phi_dot)) then
      this%phi_dot = this%checkpoint%phi_dot
    end if
    if (allocated(this%phi_ddot) .and. allocated(this%checkpoint%phi_ddot)) then
      this%phi_ddot = this%checkpoint%phi_ddot
    end if
    
    this%time = this%checkpoint%time
    
    ! Update base state
    call this%base_state%SetValues(this%phi, this%phi_dot, this%phi_dot)
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSta_RestoreChkpt

  subroutine MD_UniFldSta_AddToHist(this, status)
    class(MD_UniFldSta), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    type(MD_FldStaSnap) :: snapshot
    
    call init_error_status(status)
    
    call snapshot%Init(this%base_state%fieldId, this%base_state%fieldType, &
                            this%base_state%nDOFs, this%base_state%order, &
                            this%time, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    snapshot%phi = this%phi
    if (allocated(this%phi_dot)) then
      snapshot%phi_dot = this%phi_dot
    end if
    if (allocated(this%phi_ddot)) then
      snapshot%phi_ddot = this%phi_ddot
    end if
    
    call this%history%AddSnap(snapshot, status)
    call snapshot%Clean
    
  end subroutine MD_UniFldSta_AddToHist

  subroutine MD_UniFldSta_GetStaAtTime(this, time, phi, phi_dot, phi_ddot, status)
    class(MD_UniFldSta), intent(in) :: this
    real(wp), intent(in) :: time
    real(wp), intent(out) :: phi(:)
    real(wp), intent(out), optional :: phi_dot(:), phi_ddot(:)
    type(ErrorStatusType), intent(out) :: status
    
    type(MD_FldStaSnap) :: snapshot
    
    call init_error_status(status)
    
    call this%history%GetSnapAtTime(time, snapshot, status=status)
    if (status%status_code /= IF_STATUS_OK) return
    
    phi(1:min(size(phi), snapshot%n_dofs)) = snapshot%phi(1:min(size(phi), snapshot%n_dofs))
    
    if (present(phi_dot) .and. allocated(snapshot%phi_dot)) then
      phi_dot(1:min(size(phi_dot), snapshot%n_dofs)) = &
        snapshot%phi_dot(1:min(size(phi_dot), snapshot%n_dofs))
    end if
    
    if (present(phi_ddot) .and. allocated(snapshot%phi_ddot)) then
      phi_ddot(1:min(size(phi_ddot), snapshot%n_dofs)) = &
        snapshot%phi_ddot(1:min(size(phi_ddot), snapshot%n_dofs))
    end if
    
    call snapshot%Clean
    
  end subroutine MD_UniFldSta_GetStaAtTime

  subroutine MD_UniFldSta_CopyFromFldEq(this, field_eq, status)
    class(MD_UniFldSta), intent(inout) :: this
    type(MD_FldEq), intent(in) :: field_eq
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: n
    
    call init_error_status(status)
    
    n = min(size(this%phi), size(field_eq%phi))
    this%phi(1:n) = field_eq%phi(1:n)
    
    if (allocated(this%phi_dot) .and. allocated(field_eq%phi_dot)) then
      n = min(size(this%phi_dot), size(field_eq%phi_dot))
      this%phi_dot(1:n) = field_eq%phi_dot(1:n)
    end if
    
    if (allocated(this%phi_ddot) .and. allocated(field_eq%phi_ddot)) then
      n = min(size(this%phi_ddot), size(field_eq%phi_ddot))
      this%phi_ddot(1:n) = field_eq%phi_ddot(1:n)
    end if
    
    this%time = field_eq%time
    this%dt = field_eq%dt
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSta_CopyFromFldEq

  subroutine MD_UniFldSta_CopyToFldEq(this, field_eq, status)
    class(MD_UniFldSta), intent(in) :: this
    type(MD_FldEq), intent(inout) :: field_eq
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: n
    
    call init_error_status(status)
    
    n = min(size(this%phi), size(field_eq%phi))
    field_eq%phi(1:n) = this%phi(1:n)
    
    if (allocated(this%phi_dot) .and. allocated(field_eq%phi_dot)) then
      n = min(size(this%phi_dot), size(field_eq%phi_dot))
      field_eq%phi_dot(1:n) = this%phi_dot(1:n)
    end if
    
    if (allocated(this%phi_ddot) .and. allocated(field_eq%phi_ddot)) then
      n = min(size(this%phi_ddot), size(field_eq%phi_ddot))
      field_eq%phi_ddot(1:n) = this%phi_ddot(1:n)
    end if
    
    field_eq%time = this%time
    field_eq%dt = this%dt
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_UniFldSta_CopyToFldEq

  subroutine MD_UniFldSta_Ser(this, buffer, status)
    class(MD_UniFldSta), intent(in) :: this
    real(wp), intent(out), allocatable :: buffer(:)
    type(ErrorStatusType), intent(out) :: status
    
    call this%checkpoint%Ser(buffer, status)
  end subroutine MD_UniFldSta_Ser

  subroutine MD_UniFldSta_Deserial(this, buffer, status)
    class(MD_UniFldSta), intent(inout) :: this
    real(wp), intent(in) :: buffer(:)
    type(ErrorStatusType), intent(out) :: status
    
    call this%checkpoint%Deserial(buffer, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call this%RestoreChkpt(status)
    
  end subroutine MD_UniFldSta_Deserial

  subroutine MD_UniFldSta_Clean(this)
    class(MD_UniFldSta), intent(inout) :: this
    
    if (allocated(this%phi)) deallocate(this%phi)
    if (allocated(this%phi_dot)) deallocate(this%phi_dot)
    if (allocated(this%phi_ddot)) deallocate(this%phi_ddot)
    if (allocated(this%phi_old)) deallocate(this%phi_old)
    if (allocated(this%phi_dot_old)) deallocate(this%phi_dot_old)
    if (allocated(this%phi_ddot_old)) deallocate(this%phi_ddot_old)
    
    call this%history%Clean
    call this%checkpoint%Clean
  end subroutine MD_UniFldSta_Clean

  ! ===================================================================
  ! MD_FldStaMgr Procedures
  ! ===================================================================
  
  subroutine MD_FldStaMgr_Init(this, n_fields, checkpoint_dir, status)
    class(MD_FldStaMgr), intent(inout) :: this
    integer(i4), intent(in) :: n_fields
    character(len=*), intent(in), optional :: checkpoint_dir
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (n_fields <= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of fields"
      return
    end if
    
    this%n_fields = n_fields
    allocate(this%field_states(n_fields))
    
    if (present(checkpoint_dir)) then
      this%checkpoint_dir = checkpoint_dir
    end if
    
    this%is_initialized = .true.
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaMgr_Init

  subroutine MD_FldStaMgr_RegField(this, field_id, field_type, n_dofs, order, max_history, status)
    class(MD_FldStaMgr), intent(inout) :: this
    integer(i4), intent(in) :: field_id, field_type, n_dofs
    integer(i4), intent(in), optional :: order, max_history
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (field_id < 1 .or. field_id > this%n_fields) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid field ID"
      return
    end if
    
    call this%field_states(field_id)%Init(field_id, field_type, n_dofs, &
                                               order, max_history, status)
    
  end subroutine MD_FldStaMgr_RegField

  subroutine MD_FldStaMgr_UpdateAllSta(this, time, dt, step, iteration, status)
    class(MD_FldStaMgr), intent(inout) :: this
    real(wp), intent(in) :: time, dt
    integer(i4), intent(in), optional :: step, iteration
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    type(ErrorStatusType) :: sta_status
    
    call init_error_status(status)
    
    !------------------------------------------------------------------
    !   status time ?“time ? ?
    !  designprinciples
    !    1) Manager statusobject time management ? ?
    !    2) time ?MD_UniFldSta_UpdateSta is_dirty = .true.
    !    3)  
    !         - is_dirty ? history time
    !         - time/ /iter count status ? ?
    !         - clear is_dirty ?time status ? ?
    !    3) ?/ iteration ? MD_UniFldSys/Runtime ?
    !        MD_UniFldSta%UpdateSta status ? ? ?
    !------------------------------------------------------------------
    
    !  management time 
    this%global_time = time
    this%global_dt = dt
    if (present(step)) this%global_step = step
    
    !  status ?time
    do i = 1, this%n_fields
      !  status ? ? ?
      if (this%field_states(i)%is_dirty) then
        call this%field_states(i)%AddToHist(sta_status)
        if (sta_status%status_code /= IF_STATUS_OK) then
          status = sta_status
          return
        end if
        this%field_states(i)%is_dirty = .false.
      end if
      
      !  time 
      this%field_states(i)%time = time
      this%field_states(i)%dt = dt
      if (present(step)) this%field_states(i)%step = step
      if (present(iteration)) this%field_states(i)%iteration = iteration
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaMgr_UpdateAllSta

  subroutine MD_FldStaMgr_SaveAllChkpt(this, status)
    class(MD_FldStaMgr), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    do i = 1, this%n_fields
      call this%field_states(i)%SaveChkpt(status)
      if (status%status_code /= IF_STATUS_OK) return
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaMgr_SaveAllChkpt

  subroutine MD_FldStaMgr_RestoreAllChkpt(this, status)
    class(MD_FldStaMgr), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    do i = 1, this%n_fields
      call this%field_states(i)%RestoreChkpt(status)
      if (status%status_code /= IF_STATUS_OK) return
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaMgr_RestoreAllChkpt

  subroutine MD_FldStaMgr_GetFldSta(this, field_id, field_state, status)
    class(MD_FldStaMgr), intent(in) :: this
    integer(i4), intent(in) :: field_id
    type(MD_UniFldSta), intent(out) :: field_state
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (field_id < 1 .or. field_id > this%n_fields) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid field ID"
      return
    end if
    
    field_state = this%field_states(field_id)
    status%status_code = IF_STATUS_OK
  end subroutine MD_FldStaMgr_GetFldSta

  subroutine MD_FldStaMgr_Clean(this)
    class(MD_FldStaMgr), intent(inout) :: this
    
    integer(i4) :: i
    
    if (allocated(this%field_states)) then
      do i = 1, size(this%field_states)
        call this%field_states(i)%Clean
      end do
      deallocate(this%field_states)
    end if
    
    this%is_initialized = .false.
  end subroutine MD_FldStaMgr_Clean

  ! ===================================================================
  ! Specialized Field Types (from UF_FieldTypes)
  ! ===================================================================
  
  ! ===================================================================
  ! Structural Field Type
  ! ===================================================================
  type, public :: MD_StructFld
    !! Structural field: displacement and rotation
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Displacement field (u, v, w)
    integer(i4) :: n_disp_dofs = 0_i4
    real(wp), allocatable :: displacement(:,:)  ! (n_dimensions, n_nodes)
    real(wp), allocatable :: velocity(:,:)     ! (n_dimensions, n_nodes)
    real(wp), allocatable :: acceleration(:,:) ! (n_dimensions, n_nodes)
    
    ! Rotation field (ĂÂ¸x, ĂÂ¸y, ĂÂ¸z)
    integer(i4) :: n_rot_dofs = 0_i4
    real(wp), allocatable :: rotation(:,:)     ! (n_dimensions, n_nodes)
    real(wp), allocatable :: angular_velocit(:,:)  ! (n_dimensions, n_nodes)
    real(wp), allocatable :: angular_acceler(:,:) ! (n_dimensions, n_nodes)
    
    ! Field equation
    type(MD_FldEq) :: disp_equation
    type(MD_FldEq) :: rot_equation
    
  contains
    procedure, public :: Init => MD_StructFld_Init
    procedure, public :: ComputeStrain => MD_StructFld_ComputeStrain
    procedure, public :: MatCompStress => MD_StructFld_MatCompStress
    procedure, public :: Clean => MD_StructFld_Clean
  end type MD_StructFld

  ! ===================================================================
  ! Thermal Field Type
  ! ===================================================================
  type, public :: MD_ThermalFld
    !! Thermal field: temperature and heat flux
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Temperature field (T)
    integer(i4) :: n_temp_dofs = 0_i4
    real(wp), allocatable :: temperature(:)    ! (n_nodes)
    real(wp), allocatable :: temp_rate(:)      ! (n_nodes)
    
    ! Heat flux field (q)
    integer(i4) :: n_flux_dofs = 0_i4
    real(wp), allocatable :: heat_flux(:,:)    ! (n_dimensions, n_nodes)
    
    ! Mat properties
    real(wp), allocatable :: thermal_conduct(:)  ! (n_nodes)
    real(wp), allocatable :: thermal_capacit(:)      ! (n_nodes)
    real(wp), allocatable :: density(:)               ! (n_nodes)
    
    ! Field equation
    type(MD_FldEq) :: temp_equation
    
  contains
    procedure, public :: Init => MD_ThermalFld_Init
    procedure, public :: ComputeHeatFlux => MD_ThermalFld_ComputeHeatFlux
    procedure, public :: ComputeThermalGrad => MD_ThermalFld_ComputeThermalGrad
    procedure, public :: Clean => MD_ThermalFld_Clean
  end type MD_ThermalFld

  ! ===================================================================
  ! Fluid Field Type
  ! ===================================================================
  type, public :: MD_FluidFld
    !! Fluid field: velocity and pressure
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Velocity field (vx, vy, vz)
    integer(i4) :: n_vel_dofs = 0_i4
    real(wp), allocatable :: velocity(:,:)     ! (n_dimensions, n_nodes)
    real(wp), allocatable :: velocity_rate(:,:) ! (n_dimensions, n_nodes)
    
    ! Pressure field (p)
    integer(i4) :: n_press_dofs = 0_i4
    real(wp), allocatable :: pressure(:)       ! (n_nodes)
    real(wp), allocatable :: pressure_rate(:)  ! (n_nodes)
    
    ! Mat properties
    real(wp) :: viscosity = 1.0e-3_wp
    real(wp) :: density = 1000.0_wp
    real(wp) :: bulk_modulus = 2.0e9_wp
    
    ! Field equations
    type(MD_FldEq) :: vel_equation
    type(MD_FldEq) :: press_equation
    
  contains
    procedure, public :: Init => MD_FluidFld_Init
    procedure, public :: ComputeStrainRate => MD_FluidFld_ComputeStrainRate
    procedure, public :: ComputeDivergence => MD_FluidFld_ComputeDivergence
    procedure, public :: Clean => MD_FluidFld_Clean
  end type MD_FluidFld

  ! ===================================================================
  ! Electromagnetic Field Type
  ! ===================================================================
  type, public :: MD_ElectroMagFld
    !! Electromagnetic field: electric and magnetic fields
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Electric field (Ex, Ey, Ez)
    integer(i4) :: n_electric_dofs = 0_i4
    real(wp), allocatable :: electric_field(:,:)    ! (n_dimensions, n_nodes)
    real(wp), allocatable :: electric_potent(:)  ! (n_nodes)
    real(wp), allocatable :: electric_rate(:,:)     ! (n_dimensions, n_nodes)
    
    ! Magnetic field (Bx, By, Bz)
    integer(i4) :: n_magnetic_dofs = 0_i4
    real(wp), allocatable :: magnetic_field(:,:)    ! (n_dimensions, n_nodes)
    real(wp), allocatable :: magnetic_potent(:,:) ! (n_dimensions, n_nodes)
    real(wp), allocatable :: magnetic_rate(:,:)     ! (n_dimensions, n_nodes)
    
    ! Mat properties
    real(wp), allocatable :: permittivity(:)   ! (n_nodes)
    real(wp), allocatable :: permeability(:)  ! (n_nodes)
    real(wp), allocatable :: conductivity(:)  ! (n_nodes)
    
    ! Field equations
    type(MD_FldEq) :: electric_equation
    type(MD_FldEq) :: magnetic_equation
    
  contains
    procedure, public :: Init => MD_ElectroMagFld_Init
    procedure, public :: ComputePoyntingVec => MD_ElectroMagFld_ComputePoyntingVec
    procedure, public :: ComputeMaxwellStress => MD_ElectroMagFld_ComputeMaxwellStress
    procedure, public :: Clean => MD_ElectroMagFld_Clean
  end type MD_ElectroMagFld

  ! ===================================================================
  ! Chemical Field Type
  ! ===================================================================
  type, public :: MD_ChemicalFld
    !! Chemical field: concentration and reaction rate
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    integer(i4) :: n_species = 1_i4
    
    ! Concentration field (c1, c2, ..., cn)
    integer(i4) :: n_conc_dofs = 0_i4
    real(wp), allocatable :: concentration(:,:)    ! (n_species, n_nodes)
    real(wp), allocatable :: conc_rate(:,:)         ! (n_species, n_nodes)
    
    ! Reaction rate field (r1, r2, ..., rn)
    integer(i4) :: n_reaction_dofs = 0_i4
    real(wp), allocatable :: reaction_rate(:,:)     ! (n_species, n_nodes)
    
    ! Diffusion coefficients
    real(wp), allocatable :: diffusion_coeff(:,:)   ! (n_species, n_nodes)
    
    ! Reaction kinetics
    real(wp), allocatable :: reaction_coeff(:,:)    ! (n_species, n_nodes)
    
    ! Field equations
    type(MD_FldEq), allocatable :: conc_equations(:)
    
  contains
    procedure, public :: Init => MD_ChemicalFld_Init
    procedure, public :: ComputeDiffusionFlux => MD_ChemicalFld_ComputeDiffusionFlux
    procedure, public :: ComputeReactionRate => MD_ChemicalFld_ComputeReactionRate
    procedure, public :: Clean => MD_ChemicalFld_Clean
  end type MD_ChemicalFld

  ! ===================================================================
  ! Biological Field Type
  ! ===================================================================
  type, public :: MD_BiologicalFld
    !! Biological field: cell density and growth rate
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    integer(i4) :: n_cell_types = 1_i4
    
    ! Cell density field (Ăĝż?, Ăĝż?, ..., Ăĝż˝n)
    integer(i4) :: n_density_dofs = 0_i4
    real(wp), allocatable :: cell_density(:,:)      ! (n_cell_types, n_nodes)
    real(wp), allocatable :: density_rate(:,:)      ! (n_cell_types, n_nodes)
    
    ! Growth rate field (g1, g2, ..., gn)
    integer(i4) :: n_growth_dofs = 0_i4
    real(wp), allocatable :: growth_rate(:,:)       ! (n_cell_types, n_nodes)
    
    ! Migration parameters
    real(wp), allocatable :: migration_coeff(:,:)    ! (n_cell_types, n_nodes)
    
    ! Growth parameters
    real(wp), allocatable :: growth_coeff(:,:)      ! (n_cell_types, n_nodes)
    real(wp), allocatable :: carrying_capaci(:,:) ! (n_cell_types, n_nodes)
    
    ! Field equations
    type(MD_FldEq), allocatable :: density_equation(:)
    
  contains
    procedure, public :: Init => MD_BiologicalFld_Init
    procedure, public :: COMPUTEMIGRATIO => MD_BiologicalFld_ComputeMigrationFlux
    procedure, public :: COMPUTEGROWTHRA => MD_BiologicalFld_ComputeGrowthRate
    procedure, public :: Clean => MD_BiologicalFld_Clean
  end type MD_BiologicalFld

  ! ===================================================================
  ! Quantum Field Type
  ! ===================================================================
  type, public :: MD_QuantumFld
    !! Quantum field: wave function and probability density
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Wave function (ĂË, complex)
    integer(i4) :: n_wave_dofs = 0_i4
    complex(wp), allocatable :: wave_function(:)    ! (n_nodes)
    complex(wp), allocatable :: wave_function_rate(:) ! (n_nodes)
    
    ! Probability density (|ĂË|ĂÂ˛)
    real(wp), allocatable :: probability_den(:) ! (n_nodes)
    
    ! Phase (arg(ĂË))
    real(wp), allocatable :: phase(:)               ! (n_nodes)
    
    ! Quantum properties
    real(wp) :: planck_constant = 1.054571817e-34_wp
    real(wp) :: mass = 9.1093837015e-31_wp
    
    ! Field equation (SchrĂÂśdinger equation)
    type(MD_FldEq) :: wave_equation
    
  contains
    procedure, public :: Init => MD_QuantumFld_Init
    procedure, public :: ComputeProbDensity => MD_QuantumFld_ComputeProbDensity
    procedure, public :: ComputeExpectVal => MD_QuantumFld_ComputeExpectVal
    procedure, public :: Clean => MD_QuantumFld_Clean
  end type MD_QuantumFld

  ! ===================================================================
  ! Gravitational Field Type
  ! ===================================================================
  type, public :: MD_GravitationalFld
    !! Gravitational field: spacetime curvature
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Spacetime curvature (Riemann tensor components)
    integer(i4) :: n_curvature_dof = 0_i4
    real(wp), allocatable :: curvature(:,:,:,:)     ! (4, 4, 4, 4) - Riemann tensor
    real(wp), allocatable :: ricci_tensor(:,:)      ! (4, 4)
    real(wp) :: ricci_scalar = 0.0_wp
    
    ! Metric tensor (g_ĂÂźĂÂ˝)
    real(wp), allocatable :: metric(:,:)             ! (4, 4)
    
    ! Stress-energy tensor (T_ĂÂźĂÂ˝)
    real(wp), allocatable :: stress_energy(:,:)     ! (4, 4)
    
    ! Field equation (Einstein field equations)
    type(MD_FldEq) :: einstein_equation
    
  contains
    procedure, public :: Init => MD_GravitationalFld_Init
    procedure, public :: ComputeRicciTensor => MD_GravitationalFld_ComputeRicciTensor
    procedure, public :: ComputeEinsteinTensor => MD_GravitationalFld_ComputeEinsteinTensor
    procedure, public :: Clean => MD_GravitationalFld_Clean
  end type MD_GravitationalFld

  ! ===================================================================
  ! MD_StructFld Procedures
  ! ===================================================================
  
  !=============================================================================
  !> @brief Initialize structural field (structured interface)
  !! @details Initializes structural field using structured Desc type
  !! @param[inout] this Structural field instance
  !! @param[in] init_desc Field initialization descriptor (Desc category)
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_StructFld_Init(this, init_desc, status)
    class(MD_StructFld), intent(inout) :: this
    type(MD_FieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    this%field_id = init_desc%field_id
    this%pop%n_nodes = init_desc%pop%n_nodes
    this%n_disp_dofs = init_desc%n_dimensions * init_desc%pop%n_nodes
    this%n_rot_dofs = init_desc%n_dimensions * init_desc%pop%n_nodes
    
    allocate(this%displacement(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%velocity(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%acceleration(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%rotation(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%angular_velocit(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%angular_acceler(init_desc%n_dimensions, init_desc%pop%n_nodes))
    
    this%displacement = 0.0_wp
    this%velocity = 0.0_wp
    this%acceleration = 0.0_wp
    this%rotation = 0.0_wp
    this%angular_velocit = 0.0_wp
    this%angular_acceler = 0.0_wp
    
    ! Init field equations
    call this%disp_equation%Init(init_desc%field_id, MD_FIELD_DISPLACEMENT, &
                                      MD_SYS_SECOND_ORDER, &
                                      this%n_disp_dofs, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call this%rot_equation%Init(init_desc%field_id, MD_FIELD_ROTATION, &
                                     MD_SYS_SECOND_ORDER, &
                                     this%n_rot_dofs, status)
    
  end subroutine MD_StructFld_Init

  subroutine MD_StructFld_ComputeStrain(this, coordinates, strain, status)
    class(MD_StructFld), intent(in) :: this
    real(wp), intent(in) :: coordinates(:,:)
    real(wp), intent(out) :: strain(:,:)
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    strain = 0.0_wp
    status%status_code = IF_STATUS_OK
  end subroutine MD_StructFld_ComputeStrain

  subroutine MD_StructFld_MatCompStress(this, strain, sigma, status)
    class(MD_StructFld), intent(in) :: this
    real(wp), intent(in) :: strain(:,:)
    real(wp), intent(out) :: sigma(:,:)
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    sigma = 0.0_wp
    status%status_code = IF_STATUS_OK
  end subroutine MD_StructFld_MatCompStress

  subroutine MD_StructFld_Clean(this)
    class(MD_StructFld), intent(inout) :: this
    
    if (allocated(this%displacement)) deallocate(this%displacement)
    if (allocated(this%velocity)) deallocate(this%velocity)
    if (allocated(this%acceleration)) deallocate(this%acceleration)
    if (allocated(this%rotation)) deallocate(this%rotation)
    if (allocated(this%angular_velocit)) deallocate(this%angular_velocit)
    if (allocated(this%angular_acceler)) deallocate(this%angular_acceler)
    
    call this%disp_equation%Clean
    call this%rot_equation%Clean
  end subroutine MD_StructFld_Clean

  ! ===================================================================
  ! MD_ThermalFld Procedures
  ! ===================================================================
  
  !=============================================================================
  !> @brief Initialize thermal field (structured interface)
  !! @details Initializes thermal field using structured Desc type
  !! @param[inout] this Thermal field instance
  !! @param[in] init_desc Thermal field initialization descriptor (Desc category)
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_ThermalFld_Init(this, init_desc, status)
    class(MD_ThermalFld), intent(inout) :: this
    type(MD_ThermalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    this%field_id = init_desc%field_id
    this%pop%n_nodes = init_desc%pop%n_nodes
    this%n_temp_dofs = init_desc%pop%n_nodes
    this%n_flux_dofs = 3_i4 * init_desc%pop%n_nodes  ! 3D heat flux
    
    allocate(this%temperature(init_desc%pop%n_nodes))
    allocate(this%temp_rate(init_desc%pop%n_nodes))
    allocate(this%heat_flux(3, init_desc%pop%n_nodes))
    allocate(this%thermal_conduct(init_desc%pop%n_nodes))
    allocate(this%thermal_capacit(init_desc%pop%n_nodes))
    allocate(this%density(init_desc%pop%n_nodes))
    
    this%temperature = 0.0_wp
    this%temp_rate = 0.0_wp
    this%heat_flux = 0.0_wp
    this%thermal_conduct = 1.0_wp
    this%thermal_capacit = 1.0_wp
    this%density = 1.0_wp
    
    ! Init field equation
    call this%temp_equation%Init(init_desc%field_id, MD_FIELD_TEMPERATURE, &
                                      MD_SYS_FIRST_ORDER, &
                                      this%n_temp_dofs, status)
    
  end subroutine MD_ThermalFld_Init

  subroutine MD_Th_ComputeHeatFlux(this, temp_gradient, heat_flux, status)
    class(MD_ThermalFld), intent(in) :: this
    real(wp), intent(in) :: temp_gradient(:,:)
    real(wp), intent(out) :: heat_flux(:,:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    ! Fourier's law: q = -kĂÂˇĂ˘ËâĄT
    do i = 1, this%pop%n_nodes
      heat_flux(:, i) = -this%thermal_conduct(i) * temp_gradient(:, i)
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_ThermalFld_ComputeHeatFlux

  subroutine MD_Th_ComputeThermalGrad(this, coordinates, temp_gradient, status)
    class(MD_ThermalFld), intent(in) :: this
    real(wp), intent(in) :: coordinates(:,:)
    real(wp), intent(out) :: temp_gradient(:,:)
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    temp_gradient = 0.0_wp
    status%status_code = IF_STATUS_OK
  end subroutine MD_ThermalFld_ComputeThermalGrad

  subroutine MD_ThermalFld_Clean(this)
    class(MD_ThermalFld), intent(inout) :: this
    
    if (allocated(this%temperature)) deallocate(this%temperature)
    if (allocated(this%temp_rate)) deallocate(this%temp_rate)
    if (allocated(this%heat_flux)) deallocate(this%heat_flux)
    if (allocated(this%thermal_conduct)) deallocate(this%thermal_conduct)
    if (allocated(this%thermal_capacit)) deallocate(this%thermal_capacit)
    if (allocated(this%density)) deallocate(this%density)
    
    call this%temp_equation%Clean
  end subroutine MD_ThermalFld_Clean

  ! ===================================================================
  ! MD_FluidFld Procedures
  ! ===================================================================
  
  !=============================================================================
  !> @brief Initialize fluid field (structured interface)
  !! @details Initializes fluid field using structured Desc type
  !! @param[inout] this Fluid field instance
  !! @param[in] init_desc Field initialization descriptor (Desc category)
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_FluidFld_Init(this, init_desc, status)
    class(MD_FluidFld), intent(inout) :: this
    type(MD_FieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    this%field_id = init_desc%field_id
    this%pop%n_nodes = init_desc%pop%n_nodes
    this%n_vel_dofs = init_desc%n_dimensions * init_desc%pop%n_nodes
    this%n_press_dofs = init_desc%pop%n_nodes
    
    allocate(this%velocity(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%velocity_rate(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%pressure(init_desc%pop%n_nodes))
    allocate(this%pressure_rate(init_desc%pop%n_nodes))
    
    this%velocity = 0.0_wp
    this%velocity_rate = 0.0_wp
    this%pressure = 0.0_wp
    this%pressure_rate = 0.0_wp
    
    ! Init field equations
    call this%vel_equation%Init(init_desc%field_id, MD_FIELD_PRESSURE, &
                                     MD_SYS_FIRST_ORDER, &
                                     this%n_vel_dofs, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call this%press_equation%Init(init_desc%field_id, MD_FIELD_PRESSURE, &
                                       MD_SYS_FIRST_ORDER, &
                                       this%n_press_dofs, status)
    
  end subroutine MD_FluidFld_Init

  subroutine MD_Fl_ComputeStrainRate(this, velocity_gradie, strain_rate, status)
    class(MD_FluidFld), intent(in) :: this
    real(wp), intent(in) :: velocity_gradie(:,:,:)
    real(wp), intent(out) :: strain_rate(:,:,:)
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    strain_rate = 0.0_wp
    status%status_code = IF_STATUS_OK
  end subroutine MD_FluidFld_ComputeStrainRate

  subroutine MD_Fl_ComputeDivergence(this, velocity, divergence, status)
    class(MD_FluidFld), intent(in) :: this
    real(wp), intent(in) :: velocity(:,:)
    real(wp), intent(out) :: divergence(:)
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    divergence = 0.0_wp
    status%status_code = IF_STATUS_OK
  end subroutine MD_FluidFld_ComputeDivergence

  subroutine MD_FluidFld_Clean(this)
    class(MD_FluidFld), intent(inout) :: this
    
    if (allocated(this%velocity)) deallocate(this%velocity)
    if (allocated(this%velocity_rate)) deallocate(this%velocity_rate)
    if (allocated(this%pressure)) deallocate(this%pressure)
    if (allocated(this%pressure_rate)) deallocate(this%pressure_rate)
    
    call this%vel_equation%Clean
    call this%press_equation%Clean
  end subroutine MD_FluidFld_Clean

  ! ===================================================================
  ! MD_ElectroMagFld Procedures
  ! ===================================================================
  
  !=============================================================================
  !> @brief Initialize electromagnetic field (structured interface)
  !! @details Initializes electromagnetic field using structured Desc type
  !! @param[inout] this Electromagnetic field instance
  !! @param[in] init_desc Field initialization descriptor (Desc category)
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_ElectroMagFld_Init(this, init_desc, status)
    class(MD_ElectroMagFld), intent(inout) :: this
    type(MD_FieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    this%field_id = init_desc%field_id
    this%pop%n_nodes = init_desc%pop%n_nodes
    this%n_electric_dofs = init_desc%n_dimensions * init_desc%pop%n_nodes
    this%n_magnetic_dofs = init_desc%n_dimensions * init_desc%pop%n_nodes
    
    allocate(this%electric_field(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%electric_potent(init_desc%pop%n_nodes))
    allocate(this%electric_rate(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%magnetic_field(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%magnetic_potent(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%magnetic_rate(init_desc%n_dimensions, init_desc%pop%n_nodes))
    allocate(this%permittivity(init_desc%pop%n_nodes))
    allocate(this%permeability(init_desc%pop%n_nodes))
    allocate(this%conductivity(init_desc%pop%n_nodes))
    
    this%electric_field = 0.0_wp
    this%electric_potent = 0.0_wp
    this%electric_rate = 0.0_wp
    this%magnetic_field = 0.0_wp
    this%magnetic_potent = 0.0_wp
    this%magnetic_rate = 0.0_wp
    this%permittivity = 8.8541878128e-12_wp  ! Vacuum permittivity
    this%permeability = 1.25663706212e-6_wp  ! Vacuum permeability
    this%conductivity = 0.0_wp
    
    ! Init field equations
    call this%electric_equation%Init(init_desc%field_id, MD_FIELD_ELECTRIC, &
                                          MD_SYS_FIRST_ORDER, &
                                          this%n_electric_dofs, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call this%magnetic_equation%Init(init_desc%field_id, MD_FIELD_MAGNETIC, &
                                          MD_SYS_FIRST_ORDER, &
                                          this%n_magnetic_dofs, status)
    
  end subroutine MD_ElectroMagFld_Init

  subroutine MD_El_ComputePoyntingVec(this, poynting, status)
    class(MD_ElectroMagFld), intent(in) :: this
    real(wp), intent(out) :: poynting(:,:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    ! Poynting vector: S = (1/ĂÂź) E Ăâ?B
    do i = 1, this%pop%n_nodes
      poynting(1, i) = (this%electric_field(2, i) * this%magnetic_field(3, i) - &
                       this%electric_field(3, i) * this%magnetic_field(2, i)) / &
                       this%permeability(i)
      poynting(2, i) = (this%electric_field(3, i) * this%magnetic_field(1, i) - &
                       this%electric_field(1, i) * this%magnetic_field(3, i)) / &
                       this%permeability(i)
      poynting(3, i) = (this%electric_field(1, i) * this%magnetic_field(2, i) - &
                       this%electric_field(2, i) * this%magnetic_field(1, i)) / &
                       this%permeability(i)
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_ElectroMagFld_ComputePoyntingVec

  subroutine MD_El_ComputeMaxwellStress(this, maxwell_stress, status)
    class(MD_ElectroMagFld), intent(in) :: this
    real(wp), intent(out) :: maxwell_stress(:,:,:)
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    maxwell_stress = 0.0_wp
    status%status_code = IF_STATUS_OK
  end subroutine MD_ElectroMagFld_ComputeMaxwellStress

  subroutine MD_ElectroMagFld_Clean(this)
    class(MD_ElectroMagFld), intent(inout) :: this
    
    if (allocated(this%electric_field)) deallocate(this%electric_field)
    if (allocated(this%electric_potent)) deallocate(this%electric_potent)
    if (allocated(this%electric_rate)) deallocate(this%electric_rate)
    if (allocated(this%magnetic_field)) deallocate(this%magnetic_field)
    if (allocated(this%magnetic_potent)) deallocate(this%magnetic_potent)
    if (allocated(this%magnetic_rate)) deallocate(this%magnetic_rate)
    if (allocated(this%permittivity)) deallocate(this%permittivity)
    if (allocated(this%permeability)) deallocate(this%permeability)
    if (allocated(this%conductivity)) deallocate(this%conductivity)
    
    call this%electric_equation%Clean
    call this%magnetic_equation%Clean
  end subroutine MD_ElectroMagFld_Clean

  ! ===================================================================
  ! MD_ChemicalFld Procedures
  ! ===================================================================
  
  !=============================================================================
  !> @brief Initialize chemical field (structured interface)
  !! @details Initializes chemical field using structured Desc type
  !! @param[inout] this Chemical field instance
  !! @param[in] init_desc Chemical field initialization descriptor (Desc category)
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_ChemicalFld_Init(this, init_desc, status)
    class(MD_ChemicalFld), intent(inout) :: this
    type(MD_ChemicalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    this%field_id = init_desc%field_id
    this%pop%n_nodes = init_desc%pop%n_nodes
    this%n_species = init_desc%n_species
    this%n_conc_dofs = init_desc%n_species * init_desc%pop%n_nodes
    this%n_reaction_dofs = init_desc%n_species * init_desc%pop%n_nodes
    
    allocate(this%concentration(init_desc%n_species, init_desc%pop%n_nodes))
    allocate(this%conc_rate(init_desc%n_species, init_desc%pop%n_nodes))
    allocate(this%reaction_rate(init_desc%n_species, init_desc%pop%n_nodes))
    allocate(this%diffusion_coeff(init_desc%n_species, init_desc%pop%n_nodes))
    allocate(this%reaction_coeff(init_desc%n_species, init_desc%pop%n_nodes))
    allocate(this%conc_equations(init_desc%n_species))
    
    this%concentration = 0.0_wp
    this%conc_rate = 0.0_wp
    this%reaction_rate = 0.0_wp
    this%diffusion_coeff = 1.0e-9_wp  ! Default diffusion coef
    this%reaction_coeff = 1.0_wp
    
    ! Init field equations for each species
    do i = 1, init_desc%n_species
      call this%conc_equations(i)%Init(init_desc%field_id, MD_FIELD_CHEMICAL, &
                                             MD_SYS_FIRST_ORDER, &
                                             init_desc%pop%n_nodes, status)
      if (status%status_code /= IF_STATUS_OK) return
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_ChemicalFld_Init

  subroutine MD_Ch_ComputeDiffusionFlux(this, conc_gradient, flux, status)
    class(MD_ChemicalFld), intent(in) :: this
    real(wp), intent(in) :: conc_gradient(:,:,:)
    real(wp), intent(out) :: flux(:,:,:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, j
    
    call init_error_status(status)
    
    ! Fick's law: J = -DĂÂˇĂ˘ËâĄc
    do j = 1, this%pop%n_nodes
      do i = 1, this%n_species
        flux(:, i, j) = -this%diffusion_coeff(i, j) * conc_gradient(:, i, j)
      end do
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_ChemicalFld_ComputeDiffusionFlux

  subroutine MD_Ch_ComputeReactionRate(this, concentration, reaction_rate, status)
    class(MD_ChemicalFld), intent(in) :: this
    real(wp), intent(in) :: concentration(:,:)
    real(wp), intent(out) :: reaction_rate(:,:)
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    reaction_rate = 0.0_wp
    status%status_code = IF_STATUS_OK
  end subroutine MD_ChemicalFld_ComputeReactionRate

  subroutine MD_ChemicalFld_Clean(this)
    class(MD_ChemicalFld), intent(inout) :: this
    
    integer(i4) :: i
    
    if (allocated(this%concentration)) deallocate(this%concentration)
    if (allocated(this%conc_rate)) deallocate(this%conc_rate)
    if (allocated(this%reaction_rate)) deallocate(this%reaction_rate)
    if (allocated(this%diffusion_coeff)) deallocate(this%diffusion_coeff)
    if (allocated(this%reaction_coeff)) deallocate(this%reaction_coeff)
    
    if (allocated(this%conc_equations)) then
      do i = 1, size(this%conc_equations)
        call this%conc_equations(i)%Clean
      end do
      deallocate(this%conc_equations)
    end if
  end subroutine MD_ChemicalFld_Clean

  ! ===================================================================
  ! MD_BiologicalFld Procedures
  ! ===================================================================
  
  !=============================================================================
  !> @brief Initialize biological field (structured interface)
  !! @details Initializes biological field using structured Desc type
  !! @param[inout] this Biological field instance
  !! @param[in] init_desc Biological field initialization descriptor (Desc category)
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_BiologicalFld_Init(this, init_desc, status)
    class(MD_BiologicalFld), intent(inout) :: this
    type(MD_BiologicalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    
    this%field_id = init_desc%field_id
    this%pop%n_nodes = init_desc%pop%n_nodes
    this%n_cell_types = init_desc%n_cell_types
    this%n_density_dofs = init_desc%n_cell_types * init_desc%pop%n_nodes
    this%n_growth_dofs = init_desc%n_cell_types * init_desc%pop%n_nodes
    
    allocate(this%cell_density(init_desc%n_cell_types, init_desc%pop%n_nodes))
    allocate(this%density_rate(init_desc%n_cell_types, init_desc%pop%n_nodes))
    allocate(this%growth_rate(init_desc%n_cell_types, init_desc%pop%n_nodes))
    allocate(this%migration_coeff(init_desc%n_cell_types, init_desc%pop%n_nodes))
    allocate(this%growth_coeff(init_desc%n_cell_types, init_desc%pop%n_nodes))
    allocate(this%carrying_capaci(init_desc%n_cell_types, init_desc%pop%n_nodes))
    allocate(this%density_equation(init_desc%n_cell_types))
    
    this%cell_density = 0.0_wp
    this%density_rate = 0.0_wp
    this%growth_rate = 0.0_wp
    this%migration_coeff = 1.0e-12_wp  ! Default migration coef
    this%growth_coeff = 0.1_wp
    this%carrying_capaci = 1.0e6_wp
    
    ! Init field equations for each cell type
    do i = 1, init_desc%n_cell_types
      call this%density_equation(i)%Init(init_desc%field_id, MD_FIELD_BIOLOGICAL, &
                                                MD_SYS_FIRST_ORDER, &
                                                init_desc%pop%n_nodes, status)
      if (status%status_code /= IF_STATUS_OK) return
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_BiologicalFld_Init

  subroutine MD_Bi_ComputeMigrationFlux(this, density_gradien, flux, status)
    class(MD_BiologicalFld), intent(in) :: this
    real(wp), intent(in) :: density_gradien(:,:,:)
    real(wp), intent(out) :: flux(:,:,:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, j
    
    call init_error_status(status)
    
    ! Migration flux: J = -D_migĂÂˇĂ˘ËâĄĂ?
    do j = 1, this%pop%n_nodes
      do i = 1, this%n_cell_types
        flux(:, i, j) = -this%migration_coeff(i, j) * density_gradien(:, i, j)
      end do
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_BiologicalFld_ComputeMigrationFlux

  subroutine MD_Bi_ComputeGrowthRate(this, cell_density, growth_rate, status)
    class(MD_BiologicalFld), intent(in) :: this
    real(wp), intent(in) :: cell_density(:,:)
    real(wp), intent(out) :: growth_rate(:,:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, j
    
    call init_error_status(status)
    
    ! Logistic growth: g = rĂÂˇĂĝż˝ĂÂ?1 - Ăĝż?K)
    do j = 1, this%pop%n_nodes
      do i = 1, this%n_cell_types
        if (this%carrying_capaci(i, j) > 1.0e-30_wp) then
          growth_rate(i, j) = this%growth_coeff(i, j) * cell_density(i, j) * &
                             (1.0_wp - cell_density(i, j) / this%carrying_capaci(i, j))
        else
          growth_rate(i, j) = 0.0_wp
        end if
      end do
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_BiologicalFld_ComputeGrowthRate

  subroutine MD_BiologicalFld_Clean(this)
    class(MD_BiologicalFld), intent(inout) :: this
    
    integer(i4) :: i
    
    if (allocated(this%cell_density)) deallocate(this%cell_density)
    if (allocated(this%density_rate)) deallocate(this%density_rate)
    if (allocated(this%growth_rate)) deallocate(this%growth_rate)
    if (allocated(this%migration_coeff)) deallocate(this%migration_coeff)
    if (allocated(this%growth_coeff)) deallocate(this%growth_coeff)
    if (allocated(this%carrying_capaci)) deallocate(this%carrying_capaci)
    
    if (allocated(this%density_equation)) then
      do i = 1, size(this%density_equation)
        call this%density_equation(i)%Clean
      end do
      deallocate(this%density_equation)
    end if
  end subroutine MD_BiologicalFld_Clean

  ! ===================================================================
  ! MD_QuantumFld Procedures
  ! ===================================================================
  
  !=============================================================================
  !> @brief Initialize quantum field (structured interface)
  !! @details Initializes quantum field using structured Desc type
  !! @param[inout] this Quantum field instance
  !! @param[in] init_desc Thermal field initialization descriptor (Desc category)
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_QuantumFld_Init(this, init_desc, status)
    class(MD_QuantumFld), intent(inout) :: this
    type(MD_ThermalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    this%field_id = field_id
    this%pop%n_nodes = n_nodes
    this%n_wave_dofs = n_nodes
    
    allocate(this%wave_function(n_nodes))
    allocate(this%wave_function_rate(n_nodes))
    allocate(this%probability_den(n_nodes))
    allocate(this%phase(n_nodes))
    
    this%wave_function = (0.0_wp, 0.0_wp)
    this%wave_function_rate = (0.0_wp, 0.0_wp)
    this%probability_den = 0.0_wp
    this%phase = 0.0_wp
    
    ! Init field equation (SchrĂÂśdinger equation)
    call this%wave_equation%Init(field_id, MD_FIELD_QUANTUM, &
                                      MD_SYS_FIRST_ORDER, &
                                      this%n_wave_dofs, status)
    
  end subroutine MD_QuantumFld_Init

  subroutine MD_Qu_ComputeProbDensity(this)
    class(MD_QuantumFld), intent(inout) :: this
    
    integer(i4) :: i
    
    do i = 1, this%pop%n_nodes
      this%probability_den(i) = abs(this%wave_function(i))**2
      this%phase(i) = atan2(aimag(this%wave_function(i)), &
                           real(this%wave_function(i)))
    end do
  end subroutine MD_QuantumFld_ComputeProbDensity

  subroutine MD_Qu_ComputeExpectVal(this, operator, expectation, status)
    class(MD_QuantumFld), intent(in) :: this
    complex(wp), intent(in) :: operator(:,:)
    complex(wp), intent(out) :: expectation
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, j
    
    call init_error_status(status)
    
    ! Expectation value: <ĂË|O|ĂË> = ĂÂŝ_i ĂÂŝ_j ĂË*_i ĂÂˇ O_ij ĂÂˇ ĂË_j
    expectation = (0.0_wp, 0.0_wp)
    do j = 1, this%pop%n_nodes
      do i = 1, this%pop%n_nodes
        expectation = expectation + &
          conjg(this%wave_function(i)) * operator(i, j) * this%wave_function(j)
      end do
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_QuantumFld_ComputeExpectVal

  subroutine MD_QuantumFld_Clean(this)
    class(MD_QuantumFld), intent(inout) :: this
    
    if (allocated(this%wave_function)) deallocate(this%wave_function)
    if (allocated(this%wave_function_rate)) deallocate(this%wave_function_rate)
    if (allocated(this%probability_den)) deallocate(this%probability_den)
    if (allocated(this%phase)) deallocate(this%phase)
    
    call this%wave_equation%Clean
  end subroutine MD_QuantumFld_Clean

  ! ===================================================================
  ! MD_GravitationalFld Procedures
  ! ===================================================================
  
  !=============================================================================
  !> @brief Initialize gravitational field (structured interface)
  !! @details Initializes gravitational field using structured Desc type
  !! @param[inout] this Gravitational field instance
  !! @param[in] init_desc Thermal field initialization descriptor (Desc category)
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_GravitationalFld_Init(this, init_desc, status)
    class(MD_GravitationalFld), intent(inout) :: this
    type(MD_ThermalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    this%field_id = field_id
    this%pop%n_nodes = n_nodes
    this%n_curvature_dof = 256_i4  ! 4Ăâ?Ăâ?Ăâ? components
    
    allocate(this%curvature(4, 4, 4, 4))
    allocate(this%ricci_tensor(4, 4))
    allocate(this%metric(4, 4))
    allocate(this%stress_energy(4, 4))
    
    this%curvature = 0.0_wp
    this%ricci_tensor = 0.0_wp
    this%ricci_scalar = 0.0_wp
    this%metric = 0.0_wp
    this%stress_energy = 0.0_wp
    
    ! Init Minkowski metric (flat spacetime)
    this%metric(1, 1) = -1.0_wp
    this%metric(2, 2) = 1.0_wp
    this%metric(3, 3) = 1.0_wp
    this%metric(4, 4) = 1.0_wp
    
    ! Init field equation (Einstein field equations)
    call this%einstein_equation%Init(init_desc%field_id, MD_FIELD_GRAVITATIONAL, &
                                          MD_SYS_SECOND_ORDER, &
                                          this%n_curvature_dof, status)
    
  end subroutine MD_GravitationalFld_Init

  subroutine MD_Gr_ComputeRicciTensor(this, status)
    class(MD_GravitationalFld), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: mu, nu, alpha
    
    call init_error_status(status)
    
    ! Ricci tensor: R_ĂÂźĂÂ˝ = R^ĂÂą_{ĂÂźĂÂąĂÂ˝}
    this%ricci_tensor = 0.0_wp
    do nu = 1, 4
      do mu = 1, 4
        do alpha = 1, 4
          this%ricci_tensor(mu, nu) = this%ricci_tensor(mu, nu) + &
            this%curvature(alpha, mu, alpha, nu)
        end do
      end do
    end do
    
    ! Ricci scalar: R = g^ĂÂźĂÂ˝ ĂÂˇ R_ĂÂźĂÂ˝
    this%ricci_scalar = 0.0_wp
    do nu = 1, 4
      do mu = 1, 4
        this%ricci_scalar = this%ricci_scalar + &
          this%metric(mu, nu) * this%ricci_tensor(mu, nu)
      end do
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_GravitationalFld_ComputeRicciTensor

  subroutine MD_Gr_ComputeEinsteinTensor(this, einstein_tensor, status)
    class(MD_GravitationalFld), intent(in) :: this
    real(wp), intent(out) :: einstein_tensor(:,:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: mu, nu
    
    call init_error_status(status)
    
    ! Einstein tensor: G_ĂÂźĂÂ˝ = R_ĂÂźĂÂ˝ - (1/2)ĂÂˇRĂÂˇg_ĂÂźĂÂ˝
    do nu = 1, 4
      do mu = 1, 4
        einstein_tensor(mu, nu) = this%ricci_tensor(mu, nu) - &
          0.5_wp * this%ricci_scalar * this%metric(mu, nu)
      end do
    end do
    
    status%status_code = IF_STATUS_OK
  end subroutine MD_GravitationalFld_ComputeEinsteinTensor

  subroutine MD_GravitationalFld_Clean(this)
    class(MD_GravitationalFld), intent(inout) :: this
    
    if (allocated(this%curvature)) deallocate(this%curvature)
    if (allocated(this%ricci_tensor)) deallocate(this%ricci_tensor)
    if (allocated(this%metric)) deallocate(this%metric)
    if (allocated(this%stress_energy)) deallocate(this%stress_energy)
    
    call this%einstein_equation%Clean
  end subroutine MD_GravitationalFld_Clean

  ! ===================================================================
  ! Standalone Creation Interfaces (Structured Parameter Passing)
  ! ===================================================================
  
  !=============================================================================
  !> @brief Create structural field (structured interface)
  !! @details Creates structural field using structured Desc type
  !! @param[in] init_desc Field initialization descriptor (Desc category)
  !! @param[out] structural_fiel Structural field instance
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_CreateStructFld(init_desc, structural_fiel, status)
    type(MD_FieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(MD_StructFld), intent(out) :: structural_fiel
    type(ErrorStatusType), intent(out) :: status
    
    call structural_fiel%Init(init_desc, status)
  end subroutine MD_CreateStructFld

  !=============================================================================
  !> @brief Create thermal field (structured interface)
  !! @details Creates thermal field using structured Desc type
  !! @param[in] init_desc Thermal field initialization descriptor (Desc category)
  !! @param[out] thermal_field Thermal field instance
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_CreateThermalFld(init_desc, thermal_field, status)
    type(MD_ThermalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(MD_ThermalFld), intent(out) :: thermal_field
    type(ErrorStatusType), intent(out) :: status
    
    call thermal_field%Init(init_desc, status)
  end subroutine MD_CreateThermalFld

  !=============================================================================
  !> @brief Create fluid field (structured interface)
  !! @details Creates fluid field using structured Desc type
  !! @param[in] init_desc Field initialization descriptor (Desc category)
  !! @param[out] fluid_field Fluid field instance
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_CreateFluidFld(init_desc, fluid_field, status)
    type(MD_FieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(MD_FluidFld), intent(out) :: fluid_field
    type(ErrorStatusType), intent(out) :: status
    
    call fluid_field%Init(init_desc, status)
  end subroutine MD_CreateFluidFld

  !=============================================================================
  !> @brief Create electromagnetic field (structured interface)
  !! @details Creates electromagnetic field using structured Desc type
  !! @param[in] init_desc Field initialization descriptor (Desc category)
  !! @param[out] em_field Electromagnetic field instance
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_CreateElectroMagFld(init_desc, em_field, status)
    type(MD_FieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(MD_ElectroMagFld), intent(out) :: em_field
    type(ErrorStatusType), intent(out) :: status
    
    call em_field%Init(init_desc, status)
  end subroutine MD_CreateElectroMagFld

  !=============================================================================
  !> @brief Create chemical field (structured interface)
  !! @details Creates chemical field using structured Desc type
  !! @param[in] init_desc Chemical field initialization descriptor (Desc category)
  !! @param[out] chemical_field Chemical field instance
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_CreateChemicalFld(init_desc, chemical_field, status)
    type(MD_ChemicalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(MD_ChemicalFld), intent(out) :: chemical_field
    type(ErrorStatusType), intent(out) :: status
    
    call chemical_field%Init(init_desc, status)
  end subroutine MD_CreateChemicalFld

  !=============================================================================
  !> @brief Create biological field (structured interface)
  !! @details Creates biological field using structured Desc type
  !! @param[in] init_desc Biological field initialization descriptor (Desc category)
  !! @param[out] biological_fiel Biological field instance
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_CreateBiologicalFld(init_desc, biological_fiel, status)
    type(MD_BiologicalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(MD_BiologicalFld), intent(out) :: biological_fiel
    type(ErrorStatusType), intent(out) :: status
    
    call biological_fiel%Init(init_desc, status)
  end subroutine MD_CreateBiologicalFld

  !=============================================================================
  !> @brief Create quantum field (structured interface)
  !! @details Creates quantum field using structured Desc type
  !! @param[in] init_desc Thermal field initialization descriptor (Desc category)
  !! @param[out] quantum_field Quantum field instance
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_CreateQuantumFld(init_desc, quantum_field, status)
    type(MD_ThermalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(MD_QuantumFld), intent(out) :: quantum_field
    type(ErrorStatusType), intent(out) :: status
    
    call quantum_field%Init(init_desc, status)
  end subroutine MD_CreateQuantumFld

  !=============================================================================
  !> @brief Create gravitational field (structured interface)
  !! @details Creates gravitational field using structured Desc type
  !! @param[in] init_desc Thermal field initialization descriptor (Desc category)
  !! @param[out] gravitational_f Gravitational field instance
  !! @param[out] status Error status
  !! @note Structured interface following L3_MD layer rules: pass complete struct, not member names
  subroutine MD_CreateGravitationalFld(init_desc, gravitational_f, status)
    type(MD_ThermalFieldInitDesc), intent(in) :: init_desc  ! Complete struct, not exposed members
    type(MD_GravitationalFld), intent(out) :: gravitational_f
    type(ErrorStatusType), intent(out) :: status
    
    call gravitational_f%Init(init_desc, status)
  end subroutine MD_CreateGravitationalFld

end module MD_Out_UniFld