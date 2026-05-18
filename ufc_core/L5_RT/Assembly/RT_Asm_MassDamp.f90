!===============================================================================
! MODULE: RT_Asm_MassDamp
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Impl (mass/damping)
! BRIEF:  Mass and damping matrix assembly -- consistent/lumped mass, Rayleigh
!===============================================================================

MODULE RT_Asm_MassDamp
!> Theory: Bathe FEM §9.3 (mass); Chopra §11.3 (Rayleigh damping)
!> ARCHITECTURE: Routes to L4_PH for physical computation (PH_Mass_*, PH_Damping_*)
  !! Mass and damping matrix assembly (scheduling layer)
  !! Implements U1-U4 - mass/damping for dynamics via L4_PH routing
  
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE IF_Prec_Core, only: wp, i4
  ! L4_PH Physical computation modules (NEW)
  USE PH_Elem_Mass2, ONLY: PH_Elem_Mass_Algo, PH_Elem_Mass_State, &
                          PH_Elem_Mass_Consistent, PH_Elem_Mass_Lumped, PH_Elem_Mass_Hybrid, &
                          PH_ELEM_MASS_CONSIST, PH_ELEM_MASS_LUMP_ROWSUM, PH_ELEM_MASS_LUMP_DIAG, &
                          PH_ELEM_MASS_LUMP_HRZ, PH_ELEM_MASS_HYBRID
  ! BEAM element specialized mass/damping (B31OS/B31H)
  USE PH_Elem_B31OS, ONLY: PH_Elem_B31OS_ConsMassMatrix, &
                                 PH_Elem_B31OS_LumpMassVector, &
                                 PH_Elem_B31OS_RayleighDamping
  USE PH_Elem_B31H, ONLY: PH_Elem_B31H_ConsMassMatrix, &
                                PH_Elem_B31H_LumpMassVector, &
                                PH_Elem_B31H_RayleighDamping
  USE PH_Damping_Core, ONLY: PH_Damping_Params, PH_Damping_Result, &
                              PH_Damping_Rayleigh, PH_Damping_Modal, PH_Damping_Structural, &
                              PH_DAMP_NONE, PH_DAMP_RAYLEIGH, PH_DAMP_MODAL, PH_DAMP_STRUCTURAL
  ! L3_MD Model data
  USE MD_Base_ElemLib, ONLY: UF_GetGaussPoints, UF_GetShapeFunctions, &
                                   UF_ComputeJacobian, ShapeFuncResult
  USE MD_Base_ObjModel, ONLY: UF_Part, UF_Element, UF_Node
  USE MD_Mesh_Elem_Types, ONLY: UF_TOPO_Hex, UF_TOPO_Tet, UF_TOPO_Quad, &
                                 UF_TOPO_Tri, UF_TOPO_Line, UF_TOPO_Wedge
  USE MD_Model_Lib_Core, ONLY: UF_Model
  USE RT_Asm_Util, ONLY: RT_Asm_ElemLoop_Info, RT_Asm_GetElemInfo, &
                                    RT_Asm_GetElemDensity, RT_Asm_GetElemDOFs, &
                                    RT_Asm_GetElemCoords
  USE RT_Solv_Sparse, ONLY: RT_TripletList, RT_Triplet_Init, RT_Triplet_Add, &
                               RT_Triplet_Free, RT_CSR_FromTriplet
  USE RT_Solv_Def, ONLY: RT_CSRMatrix
  
  implicit none
  private
  
  ! ===================================================================
  ! Public Constants (aligned with PH layer)
  ! ===================================================================
  integer(i4), parameter, public :: MASS_TYPE_CONSIST = PH_ELEM_MASS_CONSIST
  integer(i4), parameter, public :: MASS_TYPE_LUMP = PH_ELEM_MASS_LUMP_ROWSUM
  integer(i4), parameter, public :: MASS_TYPE_HYBR = PH_ELEM_MASS_HYBRID
  
  integer(i4), parameter, public :: DAMP_NONE = PH_DAMP_NONE
  integer(i4), parameter, public :: DAMP_RAYLEIGH = PH_DAMP_RAYLEIGH
  integer(i4), parameter, public :: DAMP_MODAL = PH_DAMP_MODAL
  integer(i4), parameter, public :: DAMP_STRUCT = PH_DAMP_STRUCTURAL
  
  integer(i4), parameter, public :: LUMP_METH_ROWSUM = PH_ELEM_MASS_LUMP_ROWSUM
  integer(i4), parameter, public :: LUMP_METH_DIAG = PH_ELEM_MASS_LUMP_DIAG
  integer(i4), parameter, public :: LUMP_METH_HRZ = PH_ELEM_MASS_LUMP_HRZ
  
  ! ===================================================================
  ! Public Types
  ! ===================================================================
  public :: RT_MassConfig
  public :: RT_DampingConfig
  public :: RT_MassMatrix
  public :: RT_DampingMatrix
  
  ! Auxiliary TYPE for Gauss point parameters (NEW)
  TYPE, PUBLIC :: GaussParams
    !! Helper TYPE for numerical integration parameters
    INTEGER(i4) :: n_gp = 0_i4
    REAL(wp), ALLOCATABLE :: weights(:)
    REAL(wp), ALLOCATABLE :: coords(:, :)
  END TYPE GaussParams
  
  ! ===================================================================
  ! Public Procedures
  ! ===================================================================
  public :: RT_Asm_Mass_Assem_Consist  ! RT_Mass_Assem_Consistent
  public :: RT_Asm_Mass_Assem_Lump     ! RT_Mass_Assem_Lumped
  public :: RT_Asm_Damp_Assem_Rayleigh ! RT_Damping_Assem_Rayleigh
  public :: RT_Asm_Damp_Assem_Modal    ! RT_Damping_Assem_Modal
  ! CSR Format Mass Assembly (from RT_Asm_Mass_CSR_Core)
  public :: RT_Asm_CSRMassCons        ! RT_Asm_Mass_Assemble_CSR_Consistent
  public :: RT_Asm_CSRMassLump       ! RT_Asm_Mass_Assemble_CSR_Lumped
  public :: RT_Asm_CSRMass_FromModel ! RT_Asm_Mass_Assemble_CSR_FromModel
  ! Extended API (task11950-11999)
  public :: RT_Asm_MassDamp_Unified_Assem  ! RT_MassDamping_Unified_Assem
  public :: RT_Asm_MassDamp_Unified_Cfg    ! RT_MassDamping_Unified_Cfg
  
  ! ===================================================================
  ! Mass Matrix Configuration
  ! ===================================================================
  type, public :: RT_MassConfig
    !! Configuration for mass matrix assembly
    
    integer(i4) :: mass_type = MASS_TYPE_CONSIST
    integer(i4) :: lump_method = LUMP_METH_ROWSUM
    
    logical :: use_hciz_lump = .false.        ! use_hciz_lumping
    real(wp) :: mass_scaling = 1.0_wp
    
    logical :: incl_rot_inert = .false.       ! incl_rot_inert
    real(wp) :: mass_prop_damp = 0.0_wp      ! mass_proportional_damping
    
  contains
    procedure, public :: Init => RT_MassConfig_Init
    procedure, public :: Valid => RT_MassConfig_Valid
  end type RT_MassConfig
  
  ! ===================================================================
  ! Damping Configuration
  ! ===================================================================
  type, public :: RT_DampingConfig
    !! Configuration for damping matrix assembly
    
    integer(i4) :: damping_type = DAMP_NONE
    
    ! Rayleigh damping: C = alpha*M + beta*K
    real(wp) :: alpha_mass = 0.0_wp
    real(wp) :: beta_stiffness = 0.0_wp
    
    ! Modal damping
    integer(i4) :: n_modes = 0_i4
    real(wp), allocatable :: modal_damping_ratios(:)
    real(wp), allocatable :: modal_frequencies(:)
    
    ! Structural damping
    real(wp) :: struct_damp_fac = 0.0_wp     ! struct_damp_fac
    
  contains
    procedure, public :: Init => RT_DampingConfig_Init
    procedure, public :: Valid => RT_DampingConfig_Valid
    procedure, public :: SetRayleigh => RT_DampingConfig_SetRayleigh
    procedure, public :: SetModal => RT_DampingConfig_SetModal
  end type RT_DampingConfig
  
  ! ===================================================================
  ! Mass Matrix
  ! ===================================================================
  type, public :: RT_MassMatrix
    !! Mass matrix container
    
    integer(i4) :: n_dofs = 0_i4
    integer(i4) :: mass_type = MASS_TYPE_CONSIST
    
    ! Consistent mass (sparse)
    real(wp), allocatable :: M_consistent(:,:)
    
    ! Lumped mass (diagonal)
    real(wp), allocatable :: M_lumped(:)
    
    ! Mass matrix statistics
    real(wp) :: total_mass = 0.0_wp
    real(wp) :: max_mass_value = 0.0_wp
    real(wp) :: min_mass_value = 0.0_wp
    
    logical :: assembled = .false.
    
  contains
    procedure, public :: Init => RT_MassMatrix_Init
    procedure, public :: Assemble => RT_MassMatrix_Assem
    procedure, public :: Lump => RT_MassMatrix_Lump
    procedure, public :: Scale => RT_MassMatrix_Scale
    procedure, public :: GetTotalMass => RT_MassMatrix_GetTotal
    procedure, public :: Print => RT_MassMatrix_Print
    procedure, public :: Cleanup => RT_MassMatrix_Clean
  end type RT_MassMatrix
  
  ! ===================================================================
  ! Damping Matrix
  ! ===================================================================
  type, public :: RT_DampingMatrix
    !! Damping matrix container
    
    integer(i4) :: n_dofs = 0_i4
    integer(i4) :: damping_type = DAMP_NONE
    
    ! Damping matrix (sparse)
    real(wp), allocatable :: C(:,:)
    
    ! Modal damping (diagonal in modal space)
    real(wp), allocatable :: C_modal(:)
    
    logical :: assembled = .false.
    
  contains
    procedure, public :: Init => RT_DampingMatrix_Init
    procedure, public :: AssembleRayleigh => RT_DampingMatrix_Rayleigh
    procedure, public :: AssembleModal => RT_DampingMatrix_Modal
    procedure, public :: Print => RT_DampingMatrix_Print
    procedure, public :: Cleanup => RT_DampingMatrix_Clean
  end type RT_DampingMatrix

contains

  ! ===================================================================
  ! RT_MassConfig Procedures
  ! ===================================================================
  
  subroutine RT_MassConfig_Init(this, mass_type, lump_method)
    class(RT_MassConfig), intent(inout) :: this
    integer(i4), intent(in), optional :: mass_type
    integer(i4), intent(in), optional :: lump_method
    
    this%dyn%mass_type = MASS_TYPE_CONSIST
    this%lump_method = LUMP_METH_ROWSUM
    this%mass_scaling = 1.0_wp
    this%use_hciz_lump = .false.
    this%incl_rot_inert = .false.
    this%mass_prop_damp = 0.0_wp
    
    if (present(mass_type)) this%dyn%mass_type = mass_type
    if (present(lump_method)) this%lump_method = lump_method
    
  end subroutine RT_MassConfig_Init
  
  subroutine RT_MassConfig_Valid(this, status)
    class(RT_MassConfig), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (this%mass_scaling <= 0.0_wp) then
      status%status_code = IF_STATUS_ERROR
      status%message = "Invalid mass scaling factor"
      return
    end if
    
    if (this%dyn%mass_type < 1 .or. this%dyn%mass_type > 3) then
      status%status_code = IF_STATUS_ERROR
      status%message = "Invalid mass type"
      return
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine RT_MassConfig_Valid
  
  ! ===================================================================
  ! RT_DampingConfig Procedures
  ! ===================================================================
  
  subroutine RT_DampingConfig_Init(this, damping_type)
    class(RT_DampingConfig), intent(inout) :: this
    integer(i4), intent(in), optional :: damping_type
    
    this%damping_type = DAMP_NONE
    this%alpha_mass = 0.0_wp
    this%beta_stiffness = 0.0_wp
    this%n_modes = 0_i4
    this%struct_damp_fac = 0.0_wp
    
    if (present(damping_type)) this%damping_type = damping_type
    
  end subroutine RT_DampingConfig_Init
  
  subroutine RT_DampingConfig_Valid(this, status)
    class(RT_DampingConfig), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (this%damping_type < 0 .or. this%damping_type > 3) then
      status%status_code = IF_STATUS_ERROR
      status%message = "Invalid damping type"
      return
    end if
    
    if (this%damping_type == DAMP_RAYLEIGH) then
      if (this%alpha_mass < 0.0_wp .or. this%beta_stiffness < 0.0_wp) then
        status%status_code = IF_STATUS_ERROR
        status%message = "Invalid Rayleigh damping parameters"
        return
      end if
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine RT_DampingConfig_Valid
  
  subroutine RT_DampingConfig_SetRayleigh(this, alpha, beta, status)
    class(RT_DampingConfig), intent(inout) :: this
    real(wp), intent(in) :: alpha, beta
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    this%damping_type = DAMP_RAYLEIGH
    this%alpha_mass = alpha
    this%beta_stiffness = beta
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_DampingConfig_SetRayleigh
  
  subroutine RT_DampingConfig_SetModal(this, n_modes, ratios, frequencies, status)
    class(RT_DampingConfig), intent(inout) :: this
    integer(i4), intent(in) :: n_modes
    real(wp), intent(in) :: ratios(:)
    real(wp), intent(in) :: frequencies(:)
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    this%damping_type = DAMP_MODAL
    this%n_modes = n_modes
    
    if (allocated(this%modal_damping_ratios)) deallocate(this%modal_damping_ratios)
    if (allocated(this%modal_frequencies)) deallocate(this%modal_frequencies)
    
    allocate(this%modal_damping_ratios(n_modes))
    allocate(this%modal_frequencies(n_modes))
    
    this%modal_damping_ratios = ratios(1:n_modes)
    this%modal_frequencies = frequencies(1:n_modes)
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_DampingConfig_SetModal
  
  ! ===================================================================
  ! RT_MassMatrix Procedures
  ! ===================================================================
  
  subroutine RT_MassMatrix_Init(this, n_dofs, mass_type, status)
    class(RT_MassMatrix), intent(inout) :: this
    integer(i4), intent(in) :: n_dofs
    integer(i4), intent(in) :: mass_type
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    this%n_dofs = n_dofs
    this%dyn%mass_type = mass_type
    this%assembled = .false.
    
    select case(mass_type)
    case(MASS_TYPE_CONSIST)
      if (allocated(this%M_consistent)) deallocate(this%M_consistent)
      allocate(this%M_consistent(n_dofs, n_dofs))
      this%M_consistent = 0.0_wp
      
    case(MASS_TYPE_LUMP)
      if (allocated(this%M_lumped)) deallocate(this%M_lumped)
      allocate(this%M_lumped(n_dofs))
      this%M_lumped = 0.0_wp
      
    case(MASS_TYPE_HYBRID)
      if (allocated(this%M_consistent)) deallocate(this%M_consistent)
      if (allocated(this%M_lumped)) deallocate(this%M_lumped)
      allocate(this%M_consistent(n_dofs, n_dofs))
      allocate(this%M_lumped(n_dofs))
      this%M_consistent = 0.0_wp
      this%M_lumped = 0.0_wp
    end select
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_MassMatrix_Init
  
  subroutine RT_MassMatrix_Assem(this, elem_mass, elem_dofs, status)
    class(RT_MassMatrix), intent(inout) :: this
    real(wp), intent(in) :: elem_mass(:,:)
    integer(i4), intent(in) :: elem_dofs(:)
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i, j, idof, jdof, n_elem_dofs
    
    if (present(status)) call init_error_status(status)
    
    n_elem_dofs = size(elem_dofs)
    
    if (this%dyn%mass_type == MASS_TYPE_CONSIST .or. &
        this%dyn%mass_type == MASS_TYPE_HYBRID) then
      
      ! Assemble consistent mass matrix
      do i = 1, n_elem_dofs
        idof = elem_dofs(i)
        if (idof < 1 .or. idof > this%n_dofs) cycle
        
        do j = 1, n_elem_dofs
          jdof = elem_dofs(j)
          if (jdof < 1 .or. jdof > this%n_dofs) cycle
          
          this%M_consistent(idof, jdof) = this%M_consistent(idof, jdof) + elem_mass(i, j)
        end do
      end do
    end if
    
    this%assembled = .true.
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_MassMatrix_Assem
  
  subroutine RT_MassMatrix_Lump(this, lump_method, status)
    class(RT_MassMatrix), intent(inout) :: this
    integer(i4), intent(in) :: lump_method
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i, j
    real(wp) :: row_sum, total_mass, total_diag, hrz_scale
    
    if (present(status)) call init_error_status(status)
    
    if (.not. allocated(this%M_consistent)) then
      if (present(status)) then
        status%status_code = IF_STATUS_ERROR
        status%message = "Consistent mass matrix not allocated"
      end if
      return
    end if
    
    if (.not. allocated(this%M_lumped)) then
      allocate(this%M_lumped(this%n_dofs))
    end if
    
    select case(lump_method)
    
    case(LUMP_METH_ROWSUM)
      ! Row-sum lumping
      do i = 1, this%n_dofs
        row_sum = 0.0_wp
        do j = 1, this%n_dofs
          row_sum = row_sum + this%M_consistent(i, j)
        end do
        this%M_lumped(i) = row_sum
      end do
      
    case(LUMP_METH_DIAG)
      ! Diagonal lumping
      do i = 1, this%n_dofs
        this%M_lumped(i) = this%M_consistent(i, i)
      end do
      
    case(LUMP_METH_HRZ)
      ! HRZ lumping (Hinton-Rock-Zienkiewicz): scale diagonal so total mass preserved
      ! m_i = M_ii * (sum_kl M_kl / sum_k M_kk)
      total_mass = 0.0_wp
      total_diag = 0.0_wp
      do i = 1, this%n_dofs
        do j = 1, this%n_dofs
          total_mass = total_mass + this%M_consistent(i, j)
        end do
        total_diag = total_diag + this%M_consistent(i, i)
      end do
      if (total_diag > 1.0e-30_wp) then
        hrz_scale = total_mass / total_diag
        do i = 1, this%n_dofs
          this%M_lumped(i) = this%M_consistent(i, i) * hrz_scale
        end do
      else
        do i = 1, this%n_dofs
          row_sum = 0.0_wp
          do j = 1, this%n_dofs
            row_sum = row_sum + this%M_consistent(i, j)
          end do
          this%M_lumped(i) = row_sum
        end do
      end if
      
    end select
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_MassMatrix_Lump
  
  subroutine RT_MassMatrix_Scale(this, scale_factor, status)
    class(RT_MassMatrix), intent(inout) :: this
    real(wp), intent(in) :: scale_factor
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    if (allocated(this%M_consistent)) then
      this%M_consistent = this%M_consistent * scale_factor
    end if
    
    if (allocated(this%M_lumped)) then
      this%M_lumped = this%M_lumped * scale_factor
    end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_MassMatrix_Scale
  
  function RT_MassMatrix_GetTotal(this) result(total_mass)
    class(RT_MassMatrix), intent(in) :: this
    real(wp) :: total_mass
    
    integer(i4) :: i
    
    total_mass = 0.0_wp
    
    if (allocated(this%M_lumped)) then
      do i = 1, this%n_dofs
        total_mass = total_mass + this%M_lumped(i)
      end do
    else if (allocated(this%M_consistent)) then
      do i = 1, this%n_dofs
        total_mass = total_mass + this%M_consistent(i, i)
      end do
    end if
    
  end function RT_MassMatrix_GetTotal
  
  subroutine RT_MassMatrix_Print(this, status)
    class(RT_MassMatrix), intent(in) :: this
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    print *, "=== Mass Matrix Summary ==="
    print *, "  DOFs:", this%n_dofs
    print *, "  Type:", this%dyn%mass_type
    print *, "  Assembled:", this%assembled
    print *, "  Total Mass:", this%GetTotalMass()
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_MassMatrix_Print
  
  subroutine RT_MassMatrix_Clean(this)
    class(RT_MassMatrix), intent(inout) :: this
    
    if (allocated(this%M_consistent)) deallocate(this%M_consistent)
    if (allocated(this%M_lumped)) deallocate(this%M_lumped)
    
    this%assembled = .false.
    
  end subroutine RT_MassMatrix_Clean
  
  ! ===================================================================
  ! RT_DampingMatrix Procedures
  ! ===================================================================
  
  subroutine RT_DampingMatrix_Init(this, n_dofs, damping_type, status)
    class(RT_DampingMatrix), intent(inout) :: this
    integer(i4), intent(in) :: n_dofs
    integer(i4), intent(in) :: damping_type
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    this%n_dofs = n_dofs
    this%damping_type = damping_type
    this%assembled = .false.
    
    if (damping_type /= DAMP_NONE) then
      if (allocated(this%C)) deallocate(this%C)
      allocate(this%C(n_dofs, n_dofs))
      this%C = 0.0_wp
    end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_DampingMatrix_Init
  
  subroutine RT_DampingMatrix_Rayleigh(this, alpha, beta, M, K, status)
    class(RT_DampingMatrix), intent(inout) :: this
    real(wp), intent(in) :: alpha, beta
    real(wp), intent(in) :: M(:,:)
    real(wp), intent(in) :: K(:,:)
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i, j
    
    if (present(status)) call init_error_status(status)
    
    if (.not. allocated(this%C)) then
      allocate(this%C(this%n_dofs, this%n_dofs))
    end if
    
    ! C = alpha*M + beta*K
    do i = 1, this%n_dofs
      do j = 1, this%n_dofs
        this%C(i, j) = alpha * M(i, j) + beta * K(i, j)
      end do
    end do
    
    this%assembled = .true.
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_DampingMatrix_Rayleigh
  
  subroutine RT_DampingMatrix_Modal(this, n_modes, zeta, omega, status)
    class(RT_DampingMatrix), intent(inout) :: this
    integer(i4), intent(in) :: n_modes
    real(wp), intent(in) :: zeta(:)
    real(wp), intent(in) :: omega(:)
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i
    
    if (present(status)) call init_error_status(status)
    
    if (allocated(this%C_modal)) deallocate(this%C_modal)
    allocate(this%C_modal(n_modes))
    
    ! C_modal(i) = 2 * zeta(i) * omega(i)
    do i = 1, n_modes
      this%C_modal(i) = 2.0_wp * zeta(i) * omega(i)
    end do
    
    this%assembled = .true.
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_DampingMatrix_Modal
  
  subroutine RT_DampingMatrix_Print(this, status)
    class(RT_DampingMatrix), intent(in) :: this
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    print *, "=== Damping Matrix Summary ==="
    print *, "  DOFs:", this%n_dofs
    print *, "  Type:", this%damping_type
    print *, "  Assembled:", this%assembled
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_DampingMatrix_Print
  
  subroutine RT_DampingMatrix_Clean(this)
    class(RT_DampingMatrix), intent(inout) :: this
    
    if (allocated(this%C)) deallocate(this%C)
    if (allocated(this%C_modal)) deallocate(this%C_modal)
    
    this%assembled = .false.
    
  end subroutine RT_DampingMatrix_Clean
  
  ! ===================================================================
  ! Public Interface Procedures
  ! ===================================================================
  
  ! ===================================================================
  ! Public Interface Procedures (Thin Adapter - Route to L4_PH)
  ! ===================================================================
  
  subroutine RT_Asm_Mass_Assem_Consist(mass_matrix, coords, density, gauss_params, &
                                        elem_type, area, Iy, Iz, J_tors, I_warp, status)
    !! ARCHITECTURE: L5_RT thin adapter - routes to PH_Elem_Mass_Consistent
    !! INPUT: mass_matrix (container), coords (nodal), density, gauss_params
    !!        elem_type (optional, for BEAM specialized), section properties
    !! OUTPUT: mass_matrix%elem_mass (computed via PH layer)
    type(RT_MassMatrix), intent(inout) :: mass_matrix
    real(wp), intent(in) :: coords(:,:)        ! Nodal coordinates [3×n_nodes]
    real(wp), intent(in) :: density            ! Material density
    type(GaussParams), intent(in), optional :: gauss_params  ! Integration params
    character(len=*), intent(in), optional :: elem_type      ! Element type (e.g., 'B31OS')
    real(wp), intent(in), optional :: area, Iy, Iz           ! Section props (BEAM)
    real(wp), intent(in), optional :: J_tors, I_warp         ! Torsion/warping (B31OS)
    type(ErrorStatusType), intent(out), optional :: status
    
    type(PH_Elem_Mass_Algo) :: ph_params
    type(PH_Elem_Mass_State) :: ph_result
    type(ErrorStatusType) :: local_status
    
    call init_error_status(local_status)
    
    !--------------------------------------------------------
    ! DISPATCH: Check if specialized BEAM element
    !--------------------------------------------------------
    IF (present(elem_type)) THEN
      SELECT CASE(trim(ADJUSTL(elem_type)))
        
      !--- B31OS (14 DOF): Open section beam with warping ---
      CASE ('B31OS', 'B31OS_Core')
        REAL(wp) :: Me14(14, 14)
        TYPE(ErrorStatusType) :: beam_status
        
        IF (.NOT. present(area) .OR. .NOT. present(Iy) .OR. &
            .NOT. present(Iz) .OR. .NOT. present(J_tors) .OR. &
            .NOT. present(I_warp)) THEN
          local_status%status_code = IF_STATUS_ERROR
          local_status%message = 'RT_Asm_Mass_Assem_Consist: B31OS requires section properties'
          IF (present(status)) status = local_status
          RETURN
        END IF
        
        CALL PH_Elem_B31OS_ConsMassMatrix(coords, density, area, Iy, Iz, &
                                           J_tors, I_warp, Me14, beam_status)
        
        IF (beam_status%status_code /= IF_STATUS_OK) THEN
          IF (present(status)) status = beam_status
          RETURN
        END IF
        
        ! Load result into container
        mass_matrix%n_dofs = 14
        IF (ALLOCATED(mass_matrix%M_consistent)) DEALLOCATE(mass_matrix%M_consistent)
        ALLOCATE(mass_matrix%M_consistent(14, 14))
        mass_matrix%M_consistent = Me14
        mass_matrix%total_mass = SUM(Me14(i,i) for i=1,14) / 2.0_wp  ! Approximate
        mass_matrix%assembled = .TRUE.
        mass_matrix%dyn%mass_type = MASS_TYPE_CONSIST
        
        IF (present(status)) status%status_code = IF_STATUS_OK
        RETURN
        
      !--- B31H (12 DOF): Hu-Washizu mixed beam ---
      CASE ('B31H', 'B31H_Core')
        REAL(wp) :: Me12(12, 12)
        TYPE(ErrorStatusType) :: beam_status
        
        IF (.NOT. present(area) .OR. .NOT. present(Iy) .OR. &
            .NOT. present(Iz)) THEN
          local_status%status_code = IF_STATUS_ERROR
          local_status%message = 'RT_Asm_Mass_Assem_Consist: B31H requires section properties'
          IF (present(status)) status = local_status
          RETURN
        END IF
        
        CALL PH_Elem_B31H_ConsMassMatrix(coords, density, area, Iy, Iz, &
                                          Me12, beam_status)
        
        IF (beam_status%status_code /= IF_STATUS_OK) THEN
          IF (present(status)) status = beam_status
          RETURN
        END IF
        
        ! Load result
        mass_matrix%n_dofs = 12
        IF (ALLOCATED(mass_matrix%M_consistent)) DEALLOCATE(mass_matrix%M_consistent)
        ALLOCATE(mass_matrix%M_consistent(12, 12))
        mass_matrix%M_consistent = Me12
        mass_matrix%total_mass = SUM(Me12(i,i) for i=1,12) / 2.0_wp
        mass_matrix%assembled = .TRUE.
        mass_matrix%dyn%mass_type = MASS_TYPE_CONSIST
        
        IF (present(status)) status%status_code = IF_STATUS_OK
        RETURN
        
      !--- Standard elements: use generic PH_Elem_Mass_Consistent ---
      CASE DEFAULT
        ! Continue to standard implementation below
      END SELECT
    END IF
    
    ! Initialize PH parameters
    IF (present(gauss_params)) THEN
      CALL ph_params%Init(density, PH_ELEM_MASS_CONSIST, gauss_params%n_gp, &
                         gauss_params%weights, gauss_params%coords, local_status)
    ELSE
      CALL ph_params%Init(density, PH_ELEM_MASS_CONSIST, status=local_status)
    END IF
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    ! ROUTE TO L4_PH: Physical computation
    CALL PH_Elem_Mass_Consistent(coords, ph_params, ph_result, local_status)
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    ! Extract result and assemble into RT layer container
    mass_matrix%n_dofs = ph_result%n_elem_dofs
    IF (ALLOCATED(ph_result%elem_mass)) THEN
      IF (ALLOCATED(mass_matrix%M_consistent)) DEALLOCATE(mass_matrix%M_consistent)
      ALLOCATE(mass_matrix%M_consistent(ph_result%n_elem_dofs, ph_result%n_elem_dofs))
      mass_matrix%M_consistent = ph_result%elem_mass
      mass_matrix%total_mass = ph_result%total_mass
      mass_matrix%max_mass_value = ph_result%max_diag_value
      mass_matrix%min_mass_value = ph_result%min_diag_value
    END IF
    
    mass_matrix%assembled = .TRUE.
    mass_matrix%dyn%mass_type = MASS_TYPE_CONSIST
    
    IF (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_Asm_Mass_Assem_Consist
  
  subroutine RT_Asm_Mass_Assem_Lump(mass_matrix, coords, density, lump_method, &
                                     gauss_params, elem_type, area, Iy, Iz, J_tors, I_warp, status)
    !! ARCHITECTURE: L5_RT thin adapter - routes to PH_Elem_Mass_Lumped
    !! INPUT: mass_matrix, coords, density, lump_method, gauss_params
    !!        elem_type (optional), section properties (for BEAM)
    !! OUTPUT: mass_matrix%M_lumped (computed via PH layer)
    type(RT_MassMatrix), intent(inout) :: mass_matrix
    real(wp), intent(in) :: coords(:,:)
    integer(i4), intent(in) :: lump_method
    type(GaussParams), intent(in), optional :: gauss_params
    character(len=*), intent(in), optional :: elem_type      ! Element type
    real(wp), intent(in), optional :: area, Iy, Iz           ! Section props
    real(wp), intent(in), optional :: J_tors, I_warp         ! Torsion/warping
    type(ErrorStatusType), intent(out), optional :: status
    
    type(PH_Elem_Mass_Algo) :: ph_params
    type(PH_Elem_Mass_State) :: ph_result
    type(ErrorStatusType) :: local_status
    
    call init_error_status(local_status)
    
    !--------------------------------------------------------
    ! DISPATCH: Check if specialized BEAM element
    !--------------------------------------------------------
    IF (present(elem_type)) THEN
      SELECT CASE(trim(ADJUSTL(elem_type)))
        
      !--- B31OS (14 DOF): Open section beam ---
      CASE ('B31OS', 'B31OS_Core')
        REAL(wp) :: M_lumped14(14)
        TYPE(ErrorStatusType) :: beam_status
        
        IF (.NOT. present(area) .OR. .NOT. present(Iy) .OR. &
            .NOT. present(Iz) .OR. .NOT. present(J_tors) .OR. &
            .NOT. present(I_warp)) THEN
          local_status%status_code = IF_STATUS_ERROR
          local_status%message = 'RT_Asm_Mass_Assem_Lump: B31OS requires section properties'
          IF (present(status)) status = local_status
          RETURN
        END IF
        
        CALL PH_Elem_B31OS_LumpMassVector(coords, density, area, Iy, Iz, &
                                           J_tors, I_warp, M_lumped14, beam_status)
        
        IF (beam_status%status_code /= IF_STATUS_OK) THEN
          IF (present(status)) status = beam_status
          RETURN
        END IF
        
        ! Load result
        mass_matrix%n_dofs = 14
        IF (ALLOCATED(mass_matrix%M_lumped)) DEALLOCATE(mass_matrix%M_lumped)
        ALLOCATE(mass_matrix%M_lumped(14))
        mass_matrix%M_lumped = M_lumped14
        mass_matrix%total_mass = SUM(M_lumped14)
        mass_matrix%assembled = .TRUE.
        mass_matrix%dyn%mass_type = lump_method
        
        IF (present(status)) status%status_code = IF_STATUS_OK
        RETURN
        
      !--- B31H (12 DOF): Hu-Washizu mixed beam ---
      CASE ('B31H', 'B31H_Core')
        REAL(wp) :: M_lumped12(12)
        TYPE(ErrorStatusType) :: beam_status
        
        IF (.NOT. present(area) .OR. .NOT. present(Iy) .OR. &
            .NOT. present(Iz)) THEN
          local_status%status_code = IF_STATUS_ERROR
          local_status%message = 'RT_Asm_Mass_Assem_Lump: B31H requires section properties'
          IF (present(status)) status = local_status
          RETURN
        END IF
        
        CALL PH_Elem_B31H_LumpMassVector(coords, density, area, Iy, Iz, &
                                          M_lumped12, beam_status)
        
        IF (beam_status%status_code /= IF_STATUS_OK) THEN
          IF (present(status)) status = beam_status
          RETURN
        END IF
        
        ! Load result
        mass_matrix%n_dofs = 12
        IF (ALLOCATED(mass_matrix%M_lumped)) DEALLOCATE(mass_matrix%M_lumped)
        ALLOCATE(mass_matrix%M_lumped(12))
        mass_matrix%M_lumped = M_lumped12
        mass_matrix%total_mass = SUM(M_lumped12)
        mass_matrix%assembled = .TRUE.
        mass_matrix%dyn%mass_type = lump_method
        
        IF (present(status)) status%status_code = IF_STATUS_OK
        RETURN
        
      !--- Standard elements: use generic PH_Elem_Mass_Lumped ---
      CASE DEFAULT
        ! Continue to standard implementation below
      END SELECT
    END IF
    
    ! Map RT constants to PH constants
    integer(i4) :: ph_lump_method
    SELECT CASE(lump_method)
      CASE(LUMP_METH_ROWSUM)
        ph_lump_method = PH_ELEM_MASS_LUMP_ROWSUM
      CASE(LUMP_METH_DIAG)
        ph_lump_method = PH_ELEM_MASS_LUMP_DIAG
      CASE(LUMP_METH_HRZ)
        ph_lump_method = PH_ELEM_MASS_LUMP_HRZ
      CASE DEFAULT
        ph_lump_method = PH_ELEM_MASS_LUMP_ROWSUM
    END SELECT
    
    ! Initialize PH parameters
    IF (present(gauss_params)) THEN
      CALL ph_params%Init(density, ph_lump_method, gauss_params%n_gp, &
                         gauss_params%weights, gauss_params%coords, local_status)
    ELSE
      CALL ph_params%Init(density, ph_lump_method, status=local_status)
    END IF
    
    ! ROUTE TO L4_PH: Physical computation
    CALL PH_Elem_Mass_Lumped(coords, ph_params, ph_result, local_status)
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    ! Extract result
    mass_matrix%n_dofs = ph_result%n_elem_dofs
    IF (ALLOCATED(ph_result%lumped_mass)) THEN
      IF (ALLOCATED(mass_matrix%M_lumped)) DEALLOCATE(mass_matrix%M_lumped)
      ALLOCATE(mass_matrix%M_lumped(ph_result%n_elem_dofs))
      mass_matrix%M_lumped = ph_result%lumped_mass
      mass_matrix%total_mass = ph_result%total_mass
    END IF
    
    mass_matrix%assembled = .TRUE.
    mass_matrix%dyn%mass_type = lump_method
    
    IF (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_Asm_Mass_Assem_Lump
  
  subroutine RT_Asm_Damp_Assem_Rayleigh(damping_matrix, mass_matrix, stiff_matrix, &
                                         alpha, beta, elem_type, status)
    !! ARCHITECTURE: L5_RT thin adapter - routes to PH_Damping_Rayleigh
    !! INPUT: damping_matrix, mass_matrix, stiff_matrix, alpha, beta
    !!        elem_type (optional, for BEAM specialized damping)
    !! OUTPUT: damping_matrix%C (computed via PH layer: C = αM + βK)
    type(RT_DampingMatrix), intent(inout) :: damping_matrix
    type(RT_MassMatrix), intent(in) :: mass_matrix    ! Mass matrix M
    real(wp), intent(in) :: stiff_matrix(:,:)         ! Stiffness matrix K
    real(wp), intent(in) :: alpha, beta               ! Rayleigh coefficients
    character(len=*), intent(in), optional :: elem_type      ! Element type
    type(ErrorStatusType), intent(out), optional :: status
    
    type(PH_Damping_Params) :: ph_params
    type(PH_Damping_Result) :: ph_result
    type(ErrorStatusType) :: local_status
    
    call init_error_status(local_status)
    
    !--------------------------------------------------------
    ! DISPATCH: Check if specialized BEAM element
    !--------------------------------------------------------
    IF (present(elem_type)) THEN
      SELECT CASE(trim(ADJUSTL(elem_type)))
        
      !--- B31OS (14 DOF): Open section beam ---
      CASE ('B31OS', 'B31OS_Core')
        REAL(wp) :: Ce14(14, 14)
        TYPE(ErrorStatusType) :: beam_status
        
        IF (.NOT. ALLOCATED(mass_matrix%M_consistent)) THEN
          local_status%status_code = IF_STATUS_ERROR
          local_status%message = 'RT_Asm_Damp_Assem_Rayleigh: B31OS requires consistent mass'
          IF (present(status)) status = local_status
          RETURN
        END IF
        
        CALL PH_Elem_B31OS_RayleighDamping(mass_matrix%M_consistent, stiff_matrix, &
                                            alpha, beta, Ce14, beam_status)
        
        IF (beam_status%status_code /= IF_STATUS_OK) THEN
          IF (present(status)) status = beam_status
          RETURN
        END IF
        
        ! Load result
        damping_matrix%n_dofs = 14
        IF (ALLOCATED(damping_matrix%C)) DEALLOCATE(damping_matrix%C)
        ALLOCATE(damping_matrix%C(14, 14))
        damping_matrix%C = Ce14
        damping_matrix%assembled = .TRUE.
        damping_matrix%damping_type = DAMP_RAYLEIGH
        
        IF (present(status)) status%status_code = IF_STATUS_OK
        RETURN
        
      !--- B31H (12 DOF): Hu-Washizu mixed beam ---
      CASE ('B31H', 'B31H_Core')
        REAL(wp) :: Ce12(12, 12)
        TYPE(ErrorStatusType) :: beam_status
        
        IF (.NOT. ALLOCATED(mass_matrix%M_consistent)) THEN
          local_status%status_code = IF_STATUS_ERROR
          local_status%message = 'RT_Asm_Damp_Assem_Rayleigh: B31H requires consistent mass'
          IF (present(status)) status = local_status
          RETURN
        END IF
        
        CALL PH_Elem_B31H_RayleighDamping(mass_matrix%M_consistent, stiff_matrix, &
                                           alpha, beta, Ce12, beam_status)
        
        IF (beam_status%status_code /= IF_STATUS_OK) THEN
          IF (present(status)) status = beam_status
          RETURN
        END IF
        
        ! Load result
        damping_matrix%n_dofs = 12
        IF (ALLOCATED(damping_matrix%C)) DEALLOCATE(damping_matrix%C)
        ALLOCATE(damping_matrix%C(12, 12))
        damping_matrix%C = Ce12
        damping_matrix%assembled = .TRUE.
        damping_matrix%damping_type = DAMP_RAYLEIGH
        
        IF (present(status)) status%status_code = IF_STATUS_OK
        RETURN
        
      !--- Standard elements: use generic PH_Damping_Rayleigh ---
      CASE DEFAULT
        ! Continue to standard implementation below
      END SELECT
    END IF
    
    ! Initialize PH parameters
    CALL ph_params%Init(PH_DAMP_RAYLEIGH, local_status)
    CALL ph_params%SetRayleigh(alpha, beta, local_status)
    
    ! ROUTE TO L4_PH: Physical computation C = αM + βK
    IF (.NOT. ALLOCATED(mass_matrix%M_consistent)) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'RT_Asm_Damp_Assem_Rayleigh: Mass matrix not assembled'
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    CALL PH_Damping_Rayleigh(mass_matrix%M_consistent, stiff_matrix, &
                            ph_params, ph_result, local_status)
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    ! Extract result
    damping_matrix%n_dofs = ph_result%n_dofs
    IF (ALLOCATED(ph_result%damp_matrix)) THEN
      IF (ALLOCATED(damping_matrix%C)) DEALLOCATE(damping_matrix%C)
      ALLOCATE(damping_matrix%C(ph_result%n_dofs, ph_result%n_dofs))
      damping_matrix%C = ph_result%damp_matrix
    END IF
    
    damping_matrix%assembled = .TRUE.
    damping_matrix%damping_type = DAMP_RAYLEIGH
    
    IF (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_Asm_Damp_Assem_Rayleigh
  
  subroutine RT_Asm_Damp_Assem_Modal(damping_matrix, xi, omega, status)
    !! ARCHITECTURE: L5_RT thin adapter - routes to PH_Damping_Modal
    !! INPUT: damping_matrix, xi (damping ratios), omega (frequencies)
    !! OUTPUT: damping_matrix%C_modal (computed via PH layer: c_i = 2ξ_iω_i)
    type(RT_DampingMatrix), intent(inout) :: damping_matrix
    real(wp), intent(in) :: xi(:)      ! Damping ratios [ξ_1, ξ_2, ...]
    real(wp), intent(in) :: omega(:)   ! Natural frequencies [ω_1, ω_2, ...]
    type(ErrorStatusType), intent(out), optional :: status
    
    type(PH_Damping_Params) :: ph_params
    type(PH_Damping_Result) :: ph_result
    type(ErrorStatusType) :: local_status
    
    call init_error_status(local_status)
    
    ! Initialize PH parameters
    CALL ph_params%Init(PH_DAMP_MODAL, local_status)
    CALL ph_params%SetModal(xi, omega, local_status)
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    ! ROUTE TO L4_PH: Physical computation c_i = 2ξ_iω_i
    CALL PH_Damping_Modal(ph_params, ph_result, local_status)
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (present(status)) status = local_status
      RETURN
    END IF
    
    ! Extract result
    damping_matrix%n_dofs = ph_result%n_dofs
    IF (ALLOCATED(ph_result%modal_damping)) THEN
      IF (ALLOCATED(damping_matrix%C_modal)) DEALLOCATE(damping_matrix%C_modal)
      ALLOCATE(damping_matrix%C_modal(SIZE(ph_result%modal_damping)))
      damping_matrix%C_modal = ph_result%modal_damping
    END IF
    
    damping_matrix%assembled = .TRUE.
    damping_matrix%damping_type = DAMP_MODAL
    
    IF (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_Asm_Damp_Assem_Modal

  !=============================================================================
  ! Extended Mass/Damping Management API (task11950-11999)
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! task11950-11999 ?mass damping ?
  !-----------------------------------------------------------------------------
  subroutine RT_Asm_Ma_Un_Assem(mass_config, damping_config, &
                                               mass_matrix, damping_matrix, &
                                               coords, density, K_stiffness, gauss_params, status)
    !! Unified mass and damping assembly interface (L5_RT - Thin Adapter)
    !! ARCHITECTURE: Routes to L4_PH for physical computation
    !!
    !! Input:
    !!   mass_config    - Mass matrix configuration
    !!   damping_config - Damping matrix configuration
    !!   coords         - Nodal coordinates [3×n_nodes]
    !!   density        - Material density
    !!   K_stiffness    - Stiffness matrix (for Rayleigh damping, optional)
    !!   gauss_params   - Gauss integration parameters (optional)
    !!
    !! Input/Output:
    !!   mass_matrix    - Mass matrix (to be assembled via PH layer)
    !!   damping_matrix - Damping matrix (to be assembled via PH layer)
    !!
    !! Output:
    !!   status         - Error status
    !!
    !! Task: 11950-11999
    type(RT_MassConfig), intent(in) :: mass_config
    type(RT_DampingConfig), intent(in) :: damping_config
    type(RT_MassMatrix), intent(inout) :: mass_matrix
    type(RT_DampingMatrix), intent(inout) :: damping_matrix
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: density
    real(wp), intent(in), optional :: K_stiffness(:,:)
    type(GaussParams), intent(in), optional :: gauss_params
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    ! Assemble mass matrix based on configuration (ROUTE TO L4_PH)
    select case (mass_config%dyn%mass_type)
    case (MASS_TYPE_CONSIST)
      CALL RT_Asm_Mass_Assem_Consist(mass_matrix, coords, density, gauss_params, local_status)
      if (local_status%status_code /= IF_STATUS_OK) then
        if (present(status)) status = local_status
        return
      end if

    case (MASS_TYPE_LUMP)
      Call RT_Asm_Mass_Assem_Lump(mass_matrix, coords, density, mass_config%lump_method, &
                                   gauss_params, local_status)
      if (local_status%status_code /= IF_STATUS_OK) then
        if (present(status)) status = local_status
        return
      end if

    case default
      ! Default to consistent mass
      CALL RT_Asm_Mass_Assem_Consist(mass_matrix, coords, density, gauss_params, local_status)
      if (local_status%status_code /= IF_STATUS_OK) then
        if (present(status)) status = local_status
        return
      end if
    end select

    ! Assemble damping matrix based on configuration (ROUTE TO L4_PH)
    select case (damping_config%damping_type)
    case (DAMPING_RAYLEIGH)
      if (present(K_stiffness)) then
        CALL RT_Asm_Damp_Assem_Rayleigh(damping_matrix, mass_matrix, K_stiffness, &
                                       damping_config%alpha_mass, &
                                       damping_config%beta_stiffness, local_status)
      else
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = 'RT_MassDamping_Unified_Assem: Stiffness matrix required for Rayleigh damping'
        if (present(status)) status = local_status
        return
      end if

    case (DAMP_MODAL)
      if (allocated(damping_config%modal_damping_ratios) .and. &
          allocated(damping_config%modal_frequencies)) then
        CALL RT_Asm_Damp_Assem_Modal(damping_matrix, &
                                    damping_config%modal_damping_ratios, &
                                    damping_config%modal_frequencies, &
                                    local_status)
      else
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = 'RT_MassDamping_Unified_Assem: Modal damping data not allocated'
        if (present(status)) status = local_status
        return
      end if

    case (DAMP_NONE)
      ! No damping - damping matrix remains zero
      local_status%status_code = IF_STATUS_OK
      local_status%message = 'RT_MassDamping_Unified_Assem: No damping configured'

    case default
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'RT_MassDamping_Unified_Assem: Invalid damping type'
    end select

    if (present(status)) status = local_status

  end subroutine RT_MassDamping_Unified_Assem

  !-----------------------------------------------------------------------------
  ! task11950-11999 ?mass damping ?
  !-----------------------------------------------------------------------------
  subroutine RT_Asm_MassDamp_Unified_Cfg(mass_type, lump_method, &
                                                damping_type, alpha, beta, &
                                                mass_config, damping_config, &
                                                status)
    !! Unified mass and damping configuration interface
    !!  mass damping 
    !!
    !! This subroutine provides a unified interface for configuring mass and
    !! damping parameters, automatically setting up configuration structures.
    !!
    !! Input:
    !!   mass_type      - Mass matrix type (MASS_TYPE_CONSIST, MASS_TYPE_LUMP)
    !!   lump_method    - Lumping method (for lumped mass, optional)
    !!   damping_type   - Damping type (DAMPING_RAYLEIGH, DAMP_MODAL, etc.)
    !!   alpha          - Mass proportional damping coef (for Rayleigh)
    !!   beta           - Stiffness proportional damping coef (for Rayleigh)
    !!
    !! Output:
    !!   mass_config    - Mass configuration
    !!   damping_config - Damping configuration
    !!   status         - Error status
    !!
    !! Task: 11950-11999
    integer(i4), intent(in) :: mass_type
    integer(i4), intent(in), optional :: lump_method
    integer(i4), intent(in) :: damping_type
    real(wp), intent(in), optional :: alpha, beta
    type(RT_MassConfig), intent(out) :: mass_config
    type(RT_DampingConfig), intent(out) :: damping_config
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    ! Cfg mass matrix
    call mass_config%Init(mass_type)
    if (present(lump_method)) then
      mass_config%lump_method = lump_method
    else
      mass_config%lump_method = LUMP_METH_ROWSUM
    end if

    ! Valid mass configuration
    call mass_config%Valid(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if

    ! Cfg damping matrix
    call damping_config%Init(damping_type)

    ! Set damping parameters based on type
    select case (damping_type)
    case (DAMPING_RAYLEIGH)
      if (present(alpha) .and. present(beta)) then
        call damping_config%SetRayleigh(alpha, beta, local_status)
      else
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = 'RT_MassDamping_Unified_Cfg: Alpha and beta required for Rayleigh damping'
        if (present(status)) status = local_status
        return
      end if

    case (DAMP_MODAL)
      ! Modal damping requires mode data - leave unset for now
      ! User should call SetModal separately with mode data

    case (DAMP_NONE)
      ! No damping - configuration already initialized

    case default
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'RT_MassDamping_Unified_Cfg: Invalid damping type'
      if (present(status)) status = local_status
      return
    end select

    ! Valid damping configuration
    call damping_config%Valid(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if

    local_status%status_code = IF_STATUS_OK
    local_status%message = 'RT_MassDamping_Unified_Cfg: Configuration completed successfully'

    if (present(status)) status = local_status

  end subroutine RT_Asm_MassDamp_Unified_Cfg

  ! ===================================================================
  ! CSR Format Mass Matrix Assembly (from RT_Asm_Mass_CSR_Core)
  ! ===================================================================
  
  !> @brief Assemble consistent mass matrix in CSR format
  SUBROUTINE RT_Asm_CSRMassCons(model, nDOF, M_csr, error)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: nDOF
    TYPE(RT_CSRMatrix), INTENT(OUT) :: M_csr
    TYPE(ErrorStatusType), INTENT(OUT) :: error
    
    TYPE(RT_TripletList) :: triplet_list
    TYPE(RT_Asm_ElemLoop_Info) :: elem_info
    TYPE(ShapeFuncResult) :: sf
    INTEGER(i4) :: i, j, k, ip, elem_idx
    INTEGER(i4) :: dof_i, dof_j
    INTEGER(i4) :: n_gauss, nDim, n_dofs_per_node
    REAL(wp) :: density, detJ, weight, dV
    REAL(wp), ALLOCATABLE :: M_elem(:,:)
    REAL(wp), ALLOCATABLE :: gauss_coords(:,:), gauss_weights(:)
    REAL(wp), ALLOCATABLE :: dN_dx(:,:)
    INTEGER(i4) :: nnz_estimate, n_elems_total
    
    CALL init_error_status(error)
    
    n_elems_total = 1000  ! TODO: Get actual number from model
    nnz_estimate = n_elems_total * 100
    
    CALL RT_Triplet_Init(triplet_list, nnz_estimate)
    
    nDim = 3
    n_dofs_per_node = 3
    
    DO elem_idx = 1, n_elems_total
      CALL RT_Asm_GetElemInfo(model, 1, elem_idx, elem_info, error)
      IF (error%has_error) CYCLE
      
      CALL RT_Asm_GetElemDensity(model, 1, elem_idx, density, error)
      IF (error%has_error .OR. density <= 0.0_wp) THEN
        density = 7800.0_wp
      END IF
      
      CALL RT_Asm_GetElemDOFs(model, 1, elem_idx, n_dofs_per_node, &
                             elem_info%elem_dofs, error)
      IF (error%has_error) CYCLE
      
      SELECT CASE(elem_info%topology)
      CASE(UF_TOPO_Hex)
        n_gauss = 8
      CASE(UF_TOPO_Tet)
        n_gauss = 4
      CASE(UF_TOPO_Quad)
        n_gauss = 4
      CASE(UF_TOPO_Tri)
        n_gauss = 3
      CASE DEFAULT
        n_gauss = 1
      END SELECT
      
      CALL UF_GetGaussPoints(elem_info%topology, 2, nDim, &
                             gauss_coords, gauss_weights)
      
      ALLOCATE(M_elem(elem_info%n_elem_dofs, elem_info%n_elem_dofs))
      M_elem = 0.0_wp
      
      DO ip = 1, n_gauss
        CALL UF_GetShapeFunctions(elem_info%elem_name, &
                                  gauss_coords(ip, 1:nDim), sf)
        
        ALLOCATE(dN_dx(elem_info%pop%n_nodes, nDim))
        CALL UF_ComputeJacobian(elem_info%node_coords, sf%dN_dxi, &
                                detJ, dN_dx)
        
        weight = gauss_weights(ip)
        dV = detJ * weight
        
        DO i = 1, elem_info%pop%n_nodes
          DO j = 1, elem_info%pop%n_nodes
            DO k = 1, n_dofs_per_node
              dof_i = elem_info%elem_dofs((i-1)*n_dofs_per_node + k)
              dof_j = elem_info%elem_dofs((j-1)*n_dofs_per_node + k)
              
              IF (dof_i >= 1 .AND. dof_i <= nDOF .AND. &
                  dof_j >= 1 .AND. dof_j <= nDOF) THEN
                M_elem((i-1)*n_dofs_per_node + k, &
                       (j-1)*n_dofs_per_node + k) = &
                  M_elem((i-1)*n_dofs_per_node + k, &
                         (j-1)*n_dofs_per_node + k) + &
                  density * sf%N(i, 1) * sf%N(j, 1) * dV
              END IF
            END DO
          END DO
        END DO
        
        DEALLOCATE(dN_dx)
      END DO
      
      DO i = 1, elem_info%n_elem_dofs
        dof_i = elem_info%elem_dofs(i)
        IF (dof_i < 1 .OR. dof_i > nDOF) CYCLE
        
        DO j = 1, elem_info%n_elem_dofs
          dof_j = elem_info%elem_dofs(j)
          IF (dof_j < 1 .OR. dof_j > nDOF) CYCLE
          
          IF (ABS(M_elem(i, j)) > 1.0e-15_wp) THEN
            CALL RT_Triplet_Add(triplet_list, dof_i, dof_j, M_elem(i, j))
          END IF
        END DO
      END DO
      
      DEALLOCATE(M_elem, gauss_coords, gauss_weights)
    END DO
    
    CALL RT_CSR_FromTriplet(triplet_list, nDOF, nDOF, M_csr, error)
    IF (error%has_error) THEN
      CALL RT_Triplet_Free(triplet_list)
      RETURN
    END IF
    
    CALL RT_Triplet_Free(triplet_list)
    
    M_csr%is_symmetric = .true.
    M_csr%init = .true.
    
  END SUBROUTINE RT_Asm_CSRMassCons
  
  !> @brief Assemble lumped mass matrix in CSR format
  SUBROUTINE RT_Asm_CSRMassLump(model, nDOF, M_csr, error)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: nDOF
    TYPE(RT_CSRMatrix), INTENT(OUT) :: M_csr
    TYPE(ErrorStatusType), INTENT(OUT) :: error
    
    TYPE(RT_Asm_ElemLoop_Info) :: elem_info
    TYPE(ShapeFuncResult) :: sf
    INTEGER(i4) :: i, k, ip, elem_idx
    INTEGER(i4) :: dof_i
    INTEGER(i4) :: n_gauss, nDim, n_dofs_per_node
    REAL(wp) :: density, detJ, weight, dV, total_mass, lumped_mass
    REAL(wp), ALLOCATABLE :: gauss_coords(:,:), gauss_weights(:)
    REAL(wp), ALLOCATABLE :: dN_dx(:,:)
    REAL(wp), ALLOCATABLE :: M_diag(:)
    INTEGER(i4) :: n_elems_total
    
    CALL init_error_status(error)
    
    ALLOCATE(M_diag(nDOF))
    M_diag = 0.0_wp
    
    nDim = 3
    n_dofs_per_node = 3
    n_elems_total = 1000
    
    DO elem_idx = 1, n_elems_total
      CALL RT_Asm_GetElemInfo(model, 1, elem_idx, elem_info, error)
      IF (error%has_error) CYCLE
      
      CALL RT_Asm_GetElemDensity(model, 1, elem_idx, density, error)
      IF (error%has_error .OR. density <= 0.0_wp) THEN
        density = 7800.0_wp
      END IF
      
      CALL RT_Asm_GetElemDOFs(model, 1, elem_idx, n_dofs_per_node, &
                             elem_info%elem_dofs, error)
      IF (error%has_error) CYCLE
      
      SELECT CASE(elem_info%topology)
      CASE(UF_TOPO_Hex)
        n_gauss = 8
      CASE(UF_TOPO_Tet)
        n_gauss = 4
      CASE(UF_TOPO_Quad)
        n_gauss = 4
      CASE(UF_TOPO_Tri)
        n_gauss = 3
      CASE DEFAULT
        n_gauss = 1
      END SELECT
      
      CALL UF_GetGaussPoints(elem_info%topology, 2, nDim, &
                             gauss_coords, gauss_weights)
      
      total_mass = 0.0_wp
      DO ip = 1, n_gauss
        CALL UF_GetShapeFunctions(elem_info%elem_name, &
                                  gauss_coords(ip, 1:nDim), sf)
        
        ALLOCATE(dN_dx(elem_info%pop%n_nodes, nDim))
        CALL UF_ComputeJacobian(elem_info%node_coords, sf%dN_dxi, &
                                detJ, dN_dx)
        
        weight = gauss_weights(ip)
        dV = detJ * weight
        total_mass = total_mass + density * dV
        
        DEALLOCATE(dN_dx)
      END DO
      
      lumped_mass = total_mass / REAL(elem_info%pop%n_nodes, wp)
      
      DO i = 1, elem_info%pop%n_nodes
        DO k = 1, n_dofs_per_node
          dof_i = elem_info%elem_dofs((i-1)*n_dofs_per_node + k)
          IF (dof_i >= 1 .AND. dof_i <= nDOF) THEN
            M_diag(dof_i) = M_diag(dof_i) + lumped_mass
          END IF
        END DO
      END DO
      
      DEALLOCATE(gauss_coords, gauss_weights)
    END DO
    
    ALLOCATE(M_csr%rowPtr(nDOF + 1))
    ALLOCATE(M_csr%colInd(nDOF))
    ALLOCATE(M_csr%values(nDOF))
    
    DO i = 1, nDOF
      M_csr%rowPtr(i) = i
      M_csr%colInd(i) = i
      M_csr%values(i) = M_diag(i)
    END DO
    M_csr%rowPtr(nDOF + 1) = nDOF + 1
    
    M_csr%nRows = nDOF
    M_csr%nCols = nDOF
    M_csr%nnz = nDOF
    M_csr%is_symmetric = .true.
    M_csr%init = .true.
    
    DEALLOCATE(M_diag)
    
  END SUBROUTINE RT_Asm_CSRMassLump
  
  !> @brief Assemble mass matrix from model (high-level interface)
  SUBROUTINE RT_Asm_CSRMass_FromModel(model, nDOF, mass_type, M_csr, error)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: nDOF
    INTEGER(i4), INTENT(IN) :: mass_type  ! 1=Consistent, 2=Lumped
    TYPE(RT_CSRMatrix), INTENT(OUT) :: M_csr
    TYPE(ErrorStatusType), INTENT(OUT) :: error
    
    CALL init_error_status(error)
    
    SELECT CASE(mass_type)
    CASE(1)
      CALL RT_Asm_CSRMassCons(model, nDOF, M_csr, error)
    CASE(2)
      CALL RT_Asm_CSRMassLump(model, nDOF, M_csr, error)
    CASE DEFAULT
      CALL init_error_status(error, IF_STATUS_ERROR, "Invalid mass type")
      RETURN
    END SELECT
    
  END SUBROUTINE RT_Asm_CSRMass_FromModel

END MODULE RT_Asm_MassDamp