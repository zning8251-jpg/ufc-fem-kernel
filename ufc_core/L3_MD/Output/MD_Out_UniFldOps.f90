!===============================================================================
! Module: MD_UniFldOps
! Layer:  L3_MD - Model Definition Layer
! Domain: Ctx - Context
! Purpose: [TODO: Add module purpose]
! Theory:  [TODO: Add theory reference]
! Status:  Phase B | Last verified: 2026-03-11
!
! Contents (A-Z):
!   Types:
!     - [List types in A-Z order]
!   Subroutines:
!     - [List subroutines in A-Z order]
!   Functions:
!     - [List functions in A-Z order]
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Out | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
MODULE MD_Out_UniFldOps
!>>> UFC_L3_CONTRACT | Output/CONTRACT.md
!> Status: stub (not implemented yet)
!> Theory: (TODO) | Last verified: 2026-02-14
  !! [Unified Field - Operations]
  !! Abaqus-style field operations for multi-physics simulation:
  !!   - Field interpolation and shape functions
  !!   - Boundary condition management
  !!   - Initial conditions
  !!   - Load application
  !!   - Output control
  !!   - Post-processing utilities

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, only: wp, i4
  USE MD_Base_MathUtils, only: smart_grow_real_vector, smart_grow_real_Mtx, &
                           smart_grow_int_vector
  use MD_Out_UniFld, only: MD_Field_Mgr, MD_FieldManager, MD_FieldDesc, &
                        MD_FIELD_DISPLACEMENT, MD_FIELD_TEMPERATURE, MD_FIELD_PRESSURE

  implicit none
  private

  ! ===================================================================
  ! Public Types and Procedures
  ! ===================================================================
  public :: MD_ShapeFuncResult
  public :: MD_BoundaryCondition
  public :: MD_InitialCondition
  public :: MD_Load
  public :: MD_OutReq
  public :: MD_PostProcessor

  public :: MD_BC_TYPE_DISP
  public :: MD_BC_TYPE_VELOCITY
  public :: MD_BC_TYPE_ACCELERATION
  public :: MD_BC_TYPE_TEMPERATURE
  public :: MD_BC_TYPE_PRESSURE
  public :: MD_BC_TYPE_FIXED
  public :: MD_BC_TYPE_FREE

  public :: MD_LOAD_TYPE_CONCENTRATED
  public :: MD_LOAD_TYPE_DISTRIBUTED
  public :: MD_LOAD_TYPE_BODY
  public :: MD_LOAD_TYPE_THERMAL

  public :: MD_OUTPUT_FIELD
  public :: MD_OUTPUT_HISTORY

  public :: ComputeShapeFunctions
  public :: InterpolateField
  public :: ComputeFieldGradient
  public :: ComputeFieldHessian

  public :: CreateBoundaryCondition
  public :: ApplyBoundaryCondition
  public :: RemoveBoundaryCondition
  public :: GetBoundaryCondition

  public :: CreateInitialCondition
  public :: ApplyInitialCondition
  public :: GetInitialCondition

  public :: CreateLoad
  public :: ApplyLoad
  public :: RemoveLoad
  public :: GetLoad

  public :: CreateOutputRequest
  public :: SetupOutput
  public :: WriteOutput
  public :: FinalizeOutput

  public :: CreatePostProcessor
  public :: ComputeContourData
  public :: ComputeVectorData
  public :: ComputeTensorData

  ! ===================================================================
  ! Boundary Condition Type Enumeration
  ! ===================================================================
  integer(i4), parameter, public :: MD_BC_TYPE_DISP         = 1_i4
  integer(i4), parameter, public :: MD_BC_TYPE_VELOCITY    = 2_i4
  integer(i4), parameter, public :: MD_BC_TYPE_ACCELERATION = 3_i4
  integer(i4), parameter, public :: MD_BC_TYPE_TEMPERATURE = 4_i4
  integer(i4), parameter, public :: MD_BC_TYPE_PRESSURE    = 5_i4
  integer(i4), parameter, public :: MD_BC_TYPE_FIXED       = 6_i4
  integer(i4), parameter, public :: MD_BC_TYPE_FREE        = 7_i4

  ! ===================================================================
  ! Load Type Enumeration
  ! ===================================================================
  integer(i4), parameter, public :: MD_LOAD_TYPE_CONCENTRATED = 1_i4
  integer(i4), parameter, public :: MD_LOAD_TYPE_DISTRIBUTED  = 2_i4
  integer(i4), parameter, public :: MD_LOAD_TYPE_BODY        = 3_i4
  integer(i4), parameter, public :: MD_LOAD_TYPE_THERMAL    = 4_i4

  ! ===================================================================
  ! Output Type Enumeration
  ! ===================================================================
  integer(i4), parameter, public :: MD_OUTPUT_FIELD   = 1_i4
  integer(i4), parameter, public :: MD_OUTPUT_HISTORY = 2_i4

  ! ===================================================================
  ! Shape Function Result Type
  ! ===================================================================
  type, public :: MD_ShapeFuncResult
    integer(i4) :: nNodes = 0_i4
    integer(i4) :: nDim = 0_i4

    real(wp), allocatable :: N(:)
    real(wp), allocatable :: dNdxi(:,:)
    real(wp), allocatable :: dNdx(:,:)
    real(wp), allocatable :: d2Ndxi2(:,:,:)
    real(wp), allocatable :: d2Ndx2(:,:,:)
  contains
    procedure, public :: Init => MD_ShapeFuncResult_Init
    procedure, public :: Cleanup => MD_ShapeFuncResult_Cleanup
  end type MD_ShapeFuncResult

  ! ===================================================================
  ! Boundary Condition Type
  ! ===================================================================
  type, public :: MD_BoundaryCondition
    integer(i4) :: bcId = 0_i4
    integer(i4) :: bcType = MD_BC_TYPE_DISP
    integer(i4) :: fieldType = MD_FIELD_DISPLACEMENT

    integer(i4), allocatable :: nodeIds(:)
    integer(i4), allocatable :: dofIds(:)

    real(wp), allocatable :: values(:)
    real(wp), allocatable :: amplitudes(:)
    character(len=64) :: amplitudeName = ""

    logical :: isActive = .true.
    logical :: isAmplitude = .false.
    real(wp) :: startTime = 0.0_wp
    real(wp) :: endTime = huge(1.0_wp)
  contains
    procedure, public :: Init => MD_BoundaryCondition_Init
    procedure, public :: SetNodes => MD_BoundaryCondition_SetNodes
    procedure, public :: SetValues => MD_BoundaryCondition_SetValues
    procedure, public :: IsActiveAtTime => MD_BoundaryCondition_IsActiveAtTime
  end type MD_BoundaryCondition

  ! ===================================================================
  ! Initial Condition Type
  ! ===================================================================
  type, public :: MD_InitialCondition
    integer(i4) :: icId = 0_i4
    integer(i4) :: fieldType = MD_FIELD_DISPLACEMENT

    integer(i4), allocatable :: nodeIds(:)
    integer(i4), allocatable :: dofIds(:)

    real(wp), allocatable :: values(:)
    real(wp), allocatable :: velocities(:)
    real(wp), allocatable :: accelerations(:)

    logical :: isApplied = .false.
  contains
    procedure, public :: Init => MD_InitialCondition_Init
    procedure, public :: SetNodes => MD_InitialCondition_SetNodes
    procedure, public :: SetValues => MD_InitialCondition_SetValues
  end type MD_InitialCondition

  ! ===================================================================
  ! Load Type
  ! ===================================================================
  type, public :: MD_Load
    integer(i4) :: loadId = 0_i4
    integer(i4) :: loadType = MD_LOAD_TYPE_CONCENTRATED
    integer(i4) :: fieldType = MD_FIELD_DISPLACEMENT

    integer(i4), allocatable :: nodeIds(:)
    integer(i4), allocatable :: elementIds(:)

    real(wp), allocatable :: values(:)
    real(wp), allocatable :: directions(:)
    real(wp), allocatable :: magnitudes(:)

    real(wp), allocatable :: amplitudes(:)
    character(len=64) :: amplitudeName = ""

    logical :: isActive = .true.
    logical :: isAmplitude = .false.
    real(wp) :: startTime = 0.0_wp
    real(wp) :: endTime = huge(1.0_wp)
  contains
    procedure, public :: Init => MD_Load_Init
    procedure, public :: SetNodes => MD_Load_SetNodes
    procedure, public :: SetElements => MD_Load_SetElements
    procedure, public :: SetValues => MD_Load_SetValues
    procedure, public :: IsActiveAtTime => MD_Load_IsActiveAtTime
  end type MD_Load

  ! ===================================================================
  ! Output Request Type
  ! ===================================================================
  type, public :: MD_OutReq
    integer(i4) :: outputId = 0_i4
    integer(i4) :: outputType = MD_OUTPUT_FIELD

    integer(i4), allocatable :: fieldIds(:)
    integer(i4), allocatable :: variableIds(:)

    character(len=256) :: fileName = ""
    character(len=64) :: format = "ASCII"

    integer(i4) :: frequency = 1_i4
    integer(i4) :: interval = 1_i4
    real(wp) :: timeInterval = 0.0_wp

    logical :: isActive = .true.
    logical :: isInitialized = .false.
    integer(i4) :: lastOutputStep = 0_i4
    real(wp) :: lastOutputTime = 0.0_wp
  contains
    procedure, public :: Init => MD_OutReq_Init
    procedure, public :: SetFields => MD_OutReq_SetFields
    procedure, public :: SetFrequency => MD_OutReq_SetFrequency
    procedure, public :: ShouldOutput => MD_OutReq_ShouldOutput
  end type MD_OutReq

  ! ===================================================================
  ! Post Processor Type
  ! ===================================================================
  type, public :: MD_PostProcessor
    integer(i4) :: nPoints = 0_i4
    integer(i4) :: nDim = 0_i4

    real(wp), allocatable :: coordinates(:,:)
    real(wp), allocatable :: fieldValues(:,:)
    real(wp), allocatable :: gradients(:,:,:)

    character(len=64) :: contourVariable = ""
    real(wp) :: contourMin = 0.0_wp
    real(wp) :: contourMax = 0.0_wp
    integer(i4) :: nContourLevels = 10_i4
  contains
    procedure, public :: Init => MD_PostProcessor_Init
    procedure, public :: SetPoints => MD_PostProcessor_SetPoints
    procedure, public :: SetContour => MD_PostProcessor_SetContour
    procedure, public :: Cleanup => MD_PostProcessor_Cleanup
  end type MD_PostProcessor

contains

  ! ===================================================================
  ! Shape Function Procedures
  ! ===================================================================
  subroutine MD_ShapeFuncResult_Init(this, nNodes, nDim)
    class(MD_ShapeFuncResult), intent(inout) :: this
    integer(i4), intent(in) :: nNodes, nDim
    type(ErrorStatusType) :: status

    this%nNodes = nNodes
    this%nDim = nDim

    ! Use smart growth for shape function arrays
    call smart_grow_real_vector(this%N, nNodes, status)
    call smart_grow_real_Mtx(this%dNdxi, nDim, nNodes, status)
    call smart_grow_real_Mtx(this%dNdx, nDim, nNodes, status)
    call smart_grow_real_Mtx(this%d2Ndxi2, nDim, nDim, nNodes, status)
    call smart_grow_real_Mtx(this%d2Ndx2, nDim, nDim, nNodes, status)

    this%N = 0.0_wp
    this%dNdxi = 0.0_wp
    this%dNdx = 0.0_wp
    this%d2Ndxi2 = 0.0_wp
    this%d2Ndx2 = 0.0_wp
  end subroutine MD_ShapeFuncResult_Init

  subroutine MD_ShapeFuncResult_Cleanup(this)
    class(MD_ShapeFuncResult), intent(inout) :: this

    if (allocated(this%N)) deallocate(this%N)
    if (allocated(this%dNdxi)) deallocate(this%dNdxi)
    if (allocated(this%dNdx)) deallocate(this%dNdx)
    if (allocated(this%d2Ndxi2)) deallocate(this%d2Ndxi2)
    if (allocated(this%d2Ndx2)) deallocate(this%d2Ndx2)

    this%nNodes = 0_i4
    this%nDim = 0_i4
  end subroutine MD_ShapeFuncResult_Cleanup

  subroutine ComputeShapeFunctions(result, xi, eta, zeta, ElemType, status)
    type(MD_ShapeFuncResult), intent(inout) :: result
    real(wp), intent(in) :: xi, eta, zeta
    integer(i4), intent(in) :: ElemType
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    select case (ElemType)
      case (1)
        call ComputeShapeFunc_2DQuad(result, xi, eta)
      case (2)
        call ComputeShapeFunc_2DTri(result, xi, eta)
      case (3)
        call ComputeShapeFunc_3DHex(result, xi, eta, zeta)
      case (4)
        call ComputeShapeFunc_3DTet(result, xi, eta, zeta)
      case default
        status%status_code = IF_STATUS_INVALID
        status%message = "Unknown element type"
        return
    end select

    status%status_code = IF_STATUS_OK
  end subroutine ComputeShapeFunctions

  subroutine ComputeShapeFunc_2DQuad(result, xi, eta)
    type(MD_ShapeFuncResult), intent(inout) :: result
    real(wp), intent(in) :: xi, eta

    real(wp) :: xi2, eta2

    xi2 = xi * xi
    eta2 = eta * eta

    result%N(1) = 0.25_wp * (1.0_wp - xi) * (1.0_wp - eta)
    result%N(2) = 0.25_wp * (1.0_wp + xi) * (1.0_wp - eta)
    result%N(3) = 0.25_wp * (1.0_wp + xi) * (1.0_wp + eta)
    result%N(4) = 0.25_wp * (1.0_wp - xi) * (1.0_wp + eta)

    result%dNdxi(1,1) = -0.25_wp * (1.0_wp - eta)
    result%dNdxi(1,2) =  0.25_wp * (1.0_wp - eta)
    result%dNdxi(1,3) =  0.25_wp * (1.0_wp + eta)
    result%dNdxi(1,4) = -0.25_wp * (1.0_wp + eta)

    result%dNdxi(2,1) = -0.25_wp * (1.0_wp - xi)
    result%dNdxi(2,2) = -0.25_wp * (1.0_wp + xi)
    result%dNdxi(2,3) =  0.25_wp * (1.0_wp + xi)
    result%dNdxi(2,4) =  0.25_wp * (1.0_wp - xi)
  end subroutine ComputeShapeFunc_2DQuad

  subroutine ComputeShapeFunc_2DTri(result, xi, eta)
    type(MD_ShapeFuncResult), intent(inout) :: result
    real(wp), intent(in) :: xi, eta

    result%N(1) = 1.0_wp - xi - eta
    result%N(2) = xi
    result%N(3) = eta

    result%dNdxi(1,1) = -1.0_wp
    result%dNdxi(1,2) =  1.0_wp
    result%dNdxi(1,3) =  0.0_wp

    result%dNdxi(2,1) = -1.0_wp
    result%dNdxi(2,2) =  0.0_wp
    result%dNdxi(2,3) =  1.0_wp
  end subroutine ComputeShapeFunc_2DTri

  subroutine ComputeShapeFunc_3DHex(result, xi, eta, zeta)
    type(MD_ShapeFuncResult), intent(inout) :: result
    real(wp), intent(in) :: xi, eta, zeta

    result%N(1) = 0.125_wp * (1.0_wp - xi) * (1.0_wp - eta) * (1.0_wp - zeta)
    result%N(2) = 0.125_wp * (1.0_wp + xi) * (1.0_wp - eta) * (1.0_wp - zeta)
    result%N(3) = 0.125_wp * (1.0_wp + xi) * (1.0_wp + eta) * (1.0_wp - zeta)
    result%N(4) = 0.125_wp * (1.0_wp - xi) * (1.0_wp + eta) * (1.0_wp - zeta)
    result%N(5) = 0.125_wp * (1.0_wp - xi) * (1.0_wp - eta) * (1.0_wp + zeta)
    result%N(6) = 0.125_wp * (1.0_wp + xi) * (1.0_wp - eta) * (1.0_wp + zeta)
    result%N(7) = 0.125_wp * (1.0_wp + xi) * (1.0_wp + eta) * (1.0_wp + zeta)
    result%N(8) = 0.125_wp * (1.0_wp - xi) * (1.0_wp + eta) * (1.0_wp + zeta)

    result%dNdxi(1,1) = -0.125_wp * (1.0_wp - eta) * (1.0_wp - zeta)
    result%dNdxi(1,2) =  0.125_wp * (1.0_wp - eta) * (1.0_wp - zeta)
    result%dNdxi(1,3) =  0.125_wp * (1.0_wp + eta) * (1.0_wp - zeta)
    result%dNdxi(1,4) = -0.125_wp * (1.0_wp + eta) * (1.0_wp - zeta)
    result%dNdxi(1,5) = -0.125_wp * (1.0_wp - eta) * (1.0_wp + zeta)
    result%dNdxi(1,6) =  0.125_wp * (1.0_wp - eta) * (1.0_wp + zeta)
    result%dNdxi(1,7) =  0.125_wp * (1.0_wp + eta) * (1.0_wp + zeta)
    result%dNdxi(1,8) = -0.125_wp * (1.0_wp + eta) * (1.0_wp + zeta)

    result%dNdxi(2,1) = -0.125_wp * (1.0_wp - xi) * (1.0_wp - zeta)
    result%dNdxi(2,2) = -0.125_wp * (1.0_wp + xi) * (1.0_wp - zeta)
    result%dNdxi(2,3) =  0.125_wp * (1.0_wp + xi) * (1.0_wp - zeta)
    result%dNdxi(2,4) =  0.125_wp * (1.0_wp - xi) * (1.0_wp - zeta)
    result%dNdxi(2,5) = -0.125_wp * (1.0_wp - xi) * (1.0_wp + zeta)
    result%dNdxi(2,6) = -0.125_wp * (1.0_wp + xi) * (1.0_wp + zeta)
    result%dNdxi(2,7) =  0.125_wp * (1.0_wp + xi) * (1.0_wp + zeta)
    result%dNdxi(2,8) =  0.125_wp * (1.0_wp - xi) * (1.0_wp + zeta)

    result%dNdxi(3,1) = -0.125_wp * (1.0_wp - xi) * (1.0_wp - eta)
    result%dNdxi(3,2) = -0.125_wp * (1.0_wp + xi) * (1.0_wp - eta)
    result%dNdxi(3,3) = -0.125_wp * (1.0_wp + xi) * (1.0_wp + eta)
    result%dNdxi(3,4) = -0.125_wp * (1.0_wp - xi) * (1.0_wp + eta)
    result%dNdxi(3,5) =  0.125_wp * (1.0_wp - xi) * (1.0_wp - eta)
    result%dNdxi(3,6) =  0.125_wp * (1.0_wp + xi) * (1.0_wp - eta)
    result%dNdxi(3,7) =  0.125_wp * (1.0_wp + xi) * (1.0_wp + eta)
    result%dNdxi(3,8) =  0.125_wp * (1.0_wp - xi) * (1.0_wp + eta)
  end subroutine ComputeShapeFunc_3DHex

  subroutine ComputeShapeFunc_3DTet(result, xi, eta, zeta)
    type(MD_ShapeFuncResult), intent(inout) :: result
    real(wp), intent(in) :: xi, eta, zeta

    result%N(1) = 1.0_wp - xi - eta - zeta
    result%N(2) = xi
    result%N(3) = eta
    result%N(4) = zeta

    result%dNdxi(1,1) = -1.0_wp
    result%dNdxi(1,2) =  1.0_wp
    result%dNdxi(1,3) =  0.0_wp
    result%dNdxi(1,4) =  0.0_wp

    result%dNdxi(2,1) = -1.0_wp
    result%dNdxi(2,2) =  0.0_wp
    result%dNdxi(2,3) =  1.0_wp
    result%dNdxi(2,4) =  0.0_wp

    result%dNdxi(3,1) = -1.0_wp
    result%dNdxi(3,2) =  0.0_wp
    result%dNdxi(3,3) =  0.0_wp
    result%dNdxi(3,4) =  1.0_wp
  end subroutine ComputeShapeFunc_3DTet

  subroutine InterpolateField(fieldState, result, values, status)
    type(MD_Field_Mgr), intent(in) :: fieldState
    type(MD_ShapeFuncResult), intent(in) :: result
    real(wp), intent(out) :: values(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, nDOFs, nNodes

    call init_error_status(status)

    if (.not. allocated(fieldState%values)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Field state not allocated"
      return
    end if

    nNodes = result%nNodes
    nDOFs = min(size(values), fieldState%nDOFs)

    do i = 1, nDOFs
      values(i) = 0.0_wp
      do j = 1, nNodes
        values(i) = values(i) + result%N(j) * fieldState%values(i)
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine InterpolateField

  subroutine ComputeFieldGradient(fieldState, result, jacobian, gradient, status)
    type(MD_Field_Mgr), intent(in) :: fieldState
    type(MD_ShapeFuncResult), intent(in) :: result
    real(wp), intent(in) :: jacobian(:,:)
    real(wp), intent(out) :: gradient(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, k, nDim, nNodes
    real(wp) :: invJac(3,3), detJac

    call init_error_status(status)

    if (.not. allocated(fieldState%values)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Field state not allocated"
      return
    end if

    nDim = result%nDim
    nNodes = result%nNodes

    invJac = 0.0_wp
    detJac = jacobian(1,1) * (jacobian(2,2) * jacobian(3,3) - jacobian(2,3) * jacobian(3,2)) - &
             jacobian(1,2) * (jacobian(2,1) * jacobian(3,3) - jacobian(2,3) * jacobian(3,1)) + &
             jacobian(1,3) * (jacobian(2,1) * jacobian(3,2) - jacobian(2,2) * jacobian(3,1))

    if (abs(detJac) < 1.0e-12_wp) then
      status%status_code = IF_STATUS_ERROR
      status%message = "Singular Jacobian"
      return
    end if

    invJac(1,1) = (jacobian(2,2) * jacobian(3,3) - jacobian(2,3) * jacobian(3,2)) / detJac
    invJac(1,2) = (jacobian(1,3) * jacobian(3,2) - jacobian(1,2) * jacobian(3,3)) / detJac
    invJac(1,3) = (jacobian(1,2) * jacobian(2,3) - jacobian(1,3) * jacobian(2,2)) / detJac
    invJac(2,1) = (jacobian(2,3) * jacobian(3,1) - jacobian(2,1) * jacobian(3,3)) / detJac
    invJac(2,2) = (jacobian(1,1) * jacobian(3,3) - jacobian(1,3) * jacobian(3,1)) / detJac
    invJac(2,3) = (jacobian(1,3) * jacobian(2,1) - jacobian(1,1) * jacobian(2,3)) / detJac
    invJac(3,1) = (jacobian(2,1) * jacobian(3,2) - jacobian(2,2) * jacobian(3,1)) / detJac
    invJac(3,2) = (jacobian(1,2) * jacobian(3,1) - jacobian(1,1) * jacobian(3,2)) / detJac
    invJac(3,3) = (jacobian(1,1) * jacobian(2,2) - jacobian(1,2) * jacobian(2,1)) / detJac

    do i = 1, nDim
      do j = 1, nDim
        gradient(i,j) = 0.0_wp
        do k = 1, nNodes
          gradient(i,j) = gradient(i,j) + invJac(i,1) * result%dNdxi(1,k) * fieldState%values(j) + &
                                        invJac(i,2) * result%dNdxi(2,k) * fieldState%values(j)
          if (nDim == 3) then
            gradient(i,j) = gradient(i,j) + invJac(i,3) * result%dNdxi(3,k) * fieldState%values(j)
          end if
        end do
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ComputeFieldGradient

  subroutine ComputeFieldHessian(fieldState, result, gradient, hessian, status)
    type(MD_Field_Mgr), intent(in) :: fieldState
    type(MD_ShapeFuncResult), intent(in) :: result
    real(wp), intent(in) :: gradient(:,:)
    real(wp), intent(out) :: hessian(:,:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, k, nDim

    call init_error_status(status)

    nDim = size(gradient, 1)

    hessian = 0.0_wp

    do i = 1, nDim
      do j = 1, nDim
        do k = 1, nDim
          hessian(i,j,k) = 0.0_wp
        end do
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ComputeFieldHessian

  ! ===================================================================
  ! Boundary Condition Procedures
  ! ===================================================================
  subroutine CreateBoundaryCondition(bc, bcId, bcType, fieldType, status)
    type(MD_BoundaryCondition), intent(out) :: bc
    integer(i4), intent(in) :: bcId, bcType, fieldType
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    ! Inline: directly call Init method
    call bc%Init(bcId, bcType, fieldType)
    status%status_code = IF_STATUS_OK
  end subroutine CreateBoundaryCondition

  subroutine MD_BoundaryCondition_Init(this, bcId, bcType, fieldType)
    class(MD_BoundaryCondition), intent(inout) :: this
    integer(i4), intent(in) :: bcId, bcType, fieldType

    this%bcId = bcId
    this%bcType = bcType
    this%fieldType = fieldType
    this%isActive = .true.
    this%isAmplitude = .false.
    this%startTime = 0.0_wp
    this%endTime = huge(1.0_wp)
  end subroutine MD_BoundaryCondition_Init

  subroutine MD_Bo_SetNodes(this, nodeIds, dofIds, values)
    class(MD_BoundaryCondition), intent(inout) :: this
    integer(i4), intent(in) :: nodeIds(:)
    integer(i4), intent(in), optional :: dofIds(:)
    real(wp), intent(in), optional :: values(:)

    integer(i4) :: nNodes

    nNodes = size(nodeIds)

    if (allocated(this%nodeIds)) deallocate(this%nodeIds)
    allocate(this%nodeIds(nNodes))
    this%nodeIds = nodeIds

    if (present(dofIds)) then
      if (allocated(this%dofIds)) deallocate(this%dofIds)
      allocate(this%dofIds(size(dofIds)))
      this%dofIds = dofIds
    end if

    if (present(values)) then
      if (allocated(this%values)) deallocate(this%values)
      allocate(this%values(size(values)))
      this%values = values
    end if
  end subroutine MD_BoundaryCondition_SetNodes

  subroutine MD_Bo_SetValues(this, values, amplitudes, amplitudeName)
    class(MD_BoundaryCondition), intent(inout) :: this
    real(wp), intent(in) :: values(:)
    real(wp), intent(in), optional :: amplitudes(:)
    character(len=*), intent(in), optional :: amplitudeName

    if (allocated(this%values)) deallocate(this%values)
    allocate(this%values(size(values)))
    this%values = values

    if (present(amplitudes)) then
      if (allocated(this%amplitudes)) deallocate(this%amplitudes)
      allocate(this%amplitudes(size(amplitudes)))
      this%amplitudes = amplitudes
      this%isAmplitude = .true.
    end if

    if (present(amplitudeName)) then
      this%amplitudeName = trim(amplitudeName)
    end if
  end subroutine MD_BoundaryCondition_SetValues

  function MD_BoundaryCondition_IsActiveAtTime(this, currentTime) result(isActive)
    class(MD_BoundaryCondition), intent(in) :: this
    real(wp), intent(in) :: currentTime
    logical :: isActive

    isActive = this%isActive .and. (currentTime >= this%startTime) .and. (currentTime <= this%endTime)
  end function MD_BoundaryCondition_IsActiveAtTime

  subroutine ApplyBoundaryCondition(fieldState, bc, currentTime, status)
    type(MD_Field_Mgr), intent(inout) :: fieldState
    type(MD_BoundaryCondition), intent(in) :: bc
    real(wp), intent(in) :: currentTime
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, nNodes, nDOFs
    real(wp) :: amplitudeFactor

    call init_error_status(status)

    if (.not. bc%IsActiveAtTime(currentTime)) then
      status%status_code = IF_STATUS_OK
      return
    end if

    nNodes = size(bc%nodeIds)
    nDOFs = min(size(bc%values), fieldState%nDOFs)

    amplitudeFactor = 1.0_wp
    if (bc%isAmplitude .and. allocated(bc%amplitudes)) then
      amplitudeFactor = bc%amplitudes(1)
    end if

    do i = 1, nNodes
      do j = 1, nDOFs
        fieldState%isFixed(j) = .true.
        fieldState%prescribedvalue(j) = bc%values(j) * amplitudeFactor
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ApplyBoundaryCondition

  subroutine RemoveBoundaryCondition(fieldState, bc, status)
    type(MD_Field_Mgr), intent(inout) :: fieldState
    type(MD_BoundaryCondition), intent(in) :: bc
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, nNodes, nDOFs

    call init_error_status(status)

    nNodes = size(bc%nodeIds)
    nDOFs = fieldState%nDOFs

    do i = 1, nNodes
      do j = 1, nDOFs
        fieldState%isFixed(j) = .false.
        fieldState%prescribedvalue(j) = 0.0_wp
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine RemoveBoundaryCondition

  subroutine GetBoundaryCondition(bc, bcId, bcType, fieldType, nodeIds, dofIds, values, status)
    type(MD_BoundaryCondition), intent(in) :: bc
    integer(i4), intent(in) :: bcId
    integer(i4), intent(out) :: bcType, fieldType
    integer(i4), intent(out), allocatable :: nodeIds(:), dofIds(:)
    real(wp), intent(out), allocatable :: values(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (bc%bcId /= bcId) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Boundary condition ID mismatch"
      return
    end if

    bcType = bc%bcType
    fieldType = bc%fieldType

    if (allocated(bc%nodeIds)) then
      allocate(nodeIds(size(bc%nodeIds)))
      nodeIds = bc%nodeIds
    end if

    if (allocated(bc%dofIds)) then
      allocate(dofIds(size(bc%dofIds)))
      dofIds = bc%dofIds
    end if

    if (allocated(bc%values)) then
      allocate(values(size(bc%values)))
      values = bc%values
    end if

    status%status_code = IF_STATUS_OK
  end subroutine GetBoundaryCondition

  ! ===================================================================
  ! Initial Condition Procedures
  ! ===================================================================
  subroutine CreateInitialCondition(ic, icId, fieldType, status)
    type(MD_InitialCondition), intent(out) :: ic
    integer(i4), intent(in) :: icId, fieldType
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    ! Inline: directly call Init method
    call ic%Init(icId, fieldType)
    status%status_code = IF_STATUS_OK
  end subroutine CreateInitialCondition

  subroutine MD_InitialCondition_Init(this, icId, fieldType)
    class(MD_InitialCondition), intent(inout) :: this
    integer(i4), intent(in) :: icId, fieldType

    this%icId = icId
    this%fieldType = fieldType
    this%isApplied = .false.
  end subroutine MD_InitialCondition_Init

  subroutine MD_InitialCondition_SetNodes(this, nodeIds, dofIds)
    class(MD_InitialCondition), intent(inout) :: this
    integer(i4), intent(in) :: nodeIds(:)
    integer(i4), intent(in), optional :: dofIds(:)

    integer(i4) :: nNodes

    nNodes = size(nodeIds)

    if (allocated(this%nodeIds)) deallocate(this%nodeIds)
    allocate(this%nodeIds(nNodes))
    this%nodeIds = nodeIds

    if (present(dofIds)) then
      if (allocated(this%dofIds)) deallocate(this%dofIds)
      allocate(this%dofIds(size(dofIds)))
      this%dofIds = dofIds
    end if
  end subroutine MD_InitialCondition_SetNodes

  subroutine MD_In_SetValues(this, values, velocities, accelerations)
    class(MD_InitialCondition), intent(inout) :: this
    real(wp), intent(in) :: values(:)
    real(wp), intent(in), optional :: velocities(:), accelerations(:)

    if (allocated(this%values)) deallocate(this%values)
    allocate(this%values(size(values)))
    this%values = values

    if (present(velocities)) then
      if (allocated(this%velocities)) deallocate(this%velocities)
      allocate(this%velocities(size(velocities)))
      this%velocities = velocities
    end if

    if (present(accelerations)) then
      if (allocated(this%accelerations)) deallocate(this%accelerations)
      allocate(this%accelerations(size(accelerations)))
      this%accelerations = accelerations
    end if
  end subroutine MD_InitialCondition_SetValues

  subroutine ApplyInitialCondition(fieldState, ic, status)
    type(MD_Field_Mgr), intent(inout) :: fieldState
    type(MD_InitialCondition), intent(in) :: ic
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, nDOFs

    call init_error_status(status)

    if (.not. allocated(fieldState%values)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Field state not allocated"
      return
    end if

    nDOFs = min(size(ic%values), fieldState%nDOFs)

    do i = 1, nDOFs
      fieldState%values(i) = ic%values(i)
    end do

    if (allocated(ic%velocities) .and. allocated(fieldState%velocities)) then
      nDOFs = min(size(ic%velocities), fieldState%nDOFs)
      do i = 1, nDOFs
        fieldState%velocities(i) = ic%velocities(i)
      end do
    end if

    if (allocated(ic%accelerations) .and. allocated(fieldState%accelerations)) then
      nDOFs = min(size(ic%accelerations), fieldState%nDOFs)
      do i = 1, nDOFs
        fieldState%accelerations(i) = ic%accelerations(i)
      end do
    end if

    ic%isApplied = .true.
    status%status_code = IF_STATUS_OK
  end subroutine ApplyInitialCondition

  subroutine GetInitialCondition(ic, icId, fieldType, nodeIds, dofIds, values, velocities, accelerations, status)
    type(MD_InitialCondition), intent(in) :: ic
    integer(i4), intent(in) :: icId
    integer(i4), intent(out) :: fieldType
    integer(i4), intent(out), allocatable :: nodeIds(:), dofIds(:)
    real(wp), intent(out), allocatable :: values(:), velocities(:), accelerations(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (ic%icId /= icId) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Initial condition ID mismatch"
      return
    end if

    fieldType = ic%fieldType

    if (allocated(ic%nodeIds)) then
      allocate(nodeIds(size(ic%nodeIds)))
      nodeIds = ic%nodeIds
    end if

    if (allocated(ic%dofIds)) then
      allocate(dofIds(size(ic%dofIds)))
      dofIds = ic%dofIds
    end if

    if (allocated(ic%values)) then
      allocate(values(size(ic%values)))
      values = ic%values
    end if

    if (allocated(ic%velocities)) then
      allocate(velocities(size(ic%velocities)))
      velocities = ic%velocities
    end if

    if (allocated(ic%accelerations)) then
      allocate(accelerations(size(ic%accelerations)))
      accelerations = ic%accelerations
    end if

    status%status_code = IF_STATUS_OK
  end subroutine GetInitialCondition

  ! ===================================================================
  ! Load Procedures
  ! ===================================================================
  subroutine CreateLoad(load, loadId, loadType, fieldType, status)
    type(MD_Load), intent(out) :: load
    integer(i4), intent(in) :: loadId, loadType, fieldType
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    ! Inline: directly call Init method
    call load%Init(loadId, loadType, fieldType)
    status%status_code = IF_STATUS_OK
  end subroutine CreateLoad

  subroutine MD_Load_Init(this, loadId, loadType, fieldType)
    class(MD_Load), intent(inout) :: this
    integer(i4), intent(in) :: loadId, loadType, fieldType

    this%loadId = loadId
    this%loadType = loadType
    this%fieldType = fieldType
    this%isActive = .true.
    this%isAmplitude = .false.
    this%startTime = 0.0_wp
    this%endTime = huge(1.0_wp)
  end subroutine MD_Load_Init

  subroutine MD_Load_SetNodes(this, nodeIds, values)
    class(MD_Load), intent(inout) :: this
    integer(i4), intent(in) :: nodeIds(:)
    real(wp), intent(in), optional :: values(:)

    integer(i4) :: nNodes

    nNodes = size(nodeIds)

    if (allocated(this%nodeIds)) deallocate(this%nodeIds)
    allocate(this%nodeIds(nNodes))
    this%nodeIds = nodeIds

    if (present(values)) then
      if (allocated(this%values)) deallocate(this%values)
      allocate(this%values(size(values)))
      this%values = values
    end if
  end subroutine MD_Load_SetNodes

  subroutine MD_Load_SetElements(this, elementIds, values)
    class(MD_Load), intent(inout) :: this
    integer(i4), intent(in) :: elementIds(:)
    real(wp), intent(in), optional :: values(:)

    integer(i4) :: nElements

    nElements = size(elementIds)

    if (allocated(this%elementIds)) deallocate(this%elementIds)
    allocate(this%elementIds(nElements))
    this%elementIds = elementIds

    if (present(values)) then
      if (allocated(this%values)) deallocate(this%values)
      allocate(this%values(size(values)))
      this%values = values
    end if
  end subroutine MD_Load_SetElements

  subroutine MD_Load_SetValues(this, values, directions, magnitudes, amplitudes, amplitudeName)
    class(MD_Load), intent(inout) :: this
    real(wp), intent(in) :: values(:)
    real(wp), intent(in), optional :: directions(:), magnitudes(:), amplitudes(:)
    character(len=*), intent(in), optional :: amplitudeName

    if (allocated(this%values)) deallocate(this%values)
    allocate(this%values(size(values)))
    this%values = values

    if (present(directions)) then
      if (allocated(this%directions)) deallocate(this%directions)
      allocate(this%directions(size(directions)))
      this%directions = directions
    end if

    if (present(magnitudes)) then
      if (allocated(this%magnitudes)) deallocate(this%magnitudes)
      allocate(this%magnitudes(size(magnitudes)))
      this%magnitudes = magnitudes
    end if

    if (present(amplitudes)) then
      if (allocated(this%amplitudes)) deallocate(this%amplitudes)
      allocate(this%amplitudes(size(amplitudes)))
      this%amplitudes = amplitudes
      this%isAmplitude = .true.
    end if

    if (present(amplitudeName)) then
      this%amplitudeName = trim(amplitudeName)
    end if
  end subroutine MD_Load_SetValues

  function MD_Load_IsActiveAtTime(this, currentTime) result(isActive)
    class(MD_Load), intent(in) :: this
    real(wp), intent(in) :: currentTime
    logical :: isActive

    isActive = this%isActive .and. (currentTime >= this%startTime) .and. (currentTime <= this%endTime)
  end function MD_Load_IsActiveAtTime

  subroutine ApplyLoad(fieldState, load, currentTime, status)
    type(MD_Field_Mgr), intent(inout) :: fieldState
    type(MD_Load), intent(in) :: load
    real(wp), intent(in) :: currentTime
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. load%IsActiveAtTime(currentTime)) then
      status%status_code = IF_STATUS_OK
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine ApplyLoad

  subroutine RemoveLoad(fieldState, load, status)
    type(MD_Field_Mgr), intent(inout) :: fieldState
    type(MD_Load), intent(in) :: load
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine RemoveLoad

  subroutine GetLoad(load, loadId, loadType, fieldType, nodeIds, elementIds, values, status)
    type(MD_Load), intent(in) :: load
    integer(i4), intent(in) :: loadId
    integer(i4), intent(out) :: loadType, fieldType
    integer(i4), intent(out), allocatable :: nodeIds(:), elementIds(:)
    real(wp), intent(out), allocatable :: values(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (load%loadId /= loadId) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Load ID mismatch"
      return
    end if

    loadType = load%loadType
    fieldType = load%fieldType

    if (allocated(load%nodeIds)) then
      allocate(nodeIds(size(load%nodeIds)))
      nodeIds = load%nodeIds
    end if

    if (allocated(load%elementIds)) then
      allocate(elementIds(size(load%elementIds)))
      elementIds = load%elementIds
    end if

    if (allocated(load%values)) then
      allocate(values(size(load%values)))
      values = load%values
    end if

    status%status_code = IF_STATUS_OK
  end subroutine GetLoad

  ! ===================================================================
  ! Output Request Procedures
  ! ===================================================================
  subroutine CreateOutputRequest(output, outputId, outputType, status)
    type(MD_OutReq), intent(out) :: output
    integer(i4), intent(in) :: outputId, outputType
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    ! Inline: directly call Init method
    call output%Init(outputId, outputType)
    status%status_code = IF_STATUS_OK
  end subroutine CreateOutputRequest

  subroutine MD_OutReq_Init(this, outputId, outputType)
    class(MD_OutReq), intent(inout) :: this
    integer(i4), intent(in) :: outputId, outputType

    this%outputId = outputId
    this%outputType = outputType
    this%isActive = .true.
    this%isInitialized = .false.
    this%frequency = 1_i4
    this%interval = 1_i4
    this%timeInterval = 0.0_wp
    this%lastOutputStep = 0_i4
    this%lastOutputTime = 0.0_wp
  end subroutine MD_OutReq_Init

  subroutine MD_OutReq_SetFields(this, fieldIds, variableIds)
    class(MD_OutReq), intent(inout) :: this
    integer(i4), intent(in) :: fieldIds(:)
    integer(i4), intent(in), optional :: variableIds(:)

    if (allocated(this%fieldIds)) deallocate(this%fieldIds)
    allocate(this%fieldIds(size(fieldIds)))
    this%fieldIds = fieldIds

    if (present(variableIds)) then
      if (allocated(this%variableIds)) deallocate(this%variableIds)
      allocate(this%variableIds(size(variableIds)))
      this%variableIds = variableIds
    end if
  end subroutine MD_OutReq_SetFields

  subroutine MD_OutReq_SetFrequency(this, frequency, interval, timeInterval)
    class(MD_OutReq), intent(inout) :: this
    integer(i4), intent(in), optional :: frequency, interval
    real(wp), intent(in), optional :: timeInterval

    if (present(frequency)) this%frequency = frequency
    if (present(interval)) this%interval = interval
    if (present(timeInterval)) this%timeInterval = timeInterval
  end subroutine MD_OutReq_SetFrequency

  function MD_OutReq_ShouldOutput(this, currentStep, currentTime) result(shouldOutput)
    class(MD_OutReq), intent(in) :: this
    integer(i4), intent(in) :: currentStep
    real(wp), intent(in) :: currentTime
    logical :: shouldOutput

    shouldOutput = .false.

    if (.not. this%isActive) return

    if (this%frequency > 0) then
      if (mod(currentStep, this%frequency) == 0) then
        shouldOutput = .true.
      end if
    end if

    if (this%timeInterval > 0.0_wp) then
      if ((currentTime - this%lastOutputTime) >= this%timeInterval) then
        shouldOutput = .true.
      end if
    end if
  end function MD_OutReq_ShouldOutput

  subroutine SetupOutput(output, fileName, format, status)
    type(MD_OutReq), intent(inout) :: output
    character(len=*), intent(in) :: fileName, format
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    output%fileName = trim(fileName)
    output%format = trim(format)
    output%isInitialized = .true.

    status%status_code = IF_STATUS_OK
  end subroutine SetupOutput

  subroutine WriteOutput(output, fieldManager, currentStep, currentTime, status)
    type(MD_OutReq), intent(inout) :: output
    type(MD_FieldManager), intent(in) :: fieldManager
    integer(i4), intent(in) :: currentStep
    real(wp), intent(in) :: currentTime
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. output%isInitialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Output not initialized"
      return
    end if

    output%lastOutputStep = currentStep
    output%lastOutputTime = currentTime

    status%status_code = IF_STATUS_OK
  end subroutine WriteOutput

  subroutine FinalizeOutput(output, status)
    type(MD_OutReq), intent(inout) :: output
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    output%isInitialized = .false.

    status%status_code = IF_STATUS_OK
  end subroutine FinalizeOutput

  ! ===================================================================
  ! Post Processor Procedures
  ! ===================================================================
  subroutine CreatePostProcessor(postProcessor, nPoints, nDim, status)
    type(MD_PostProcessor), intent(out) :: postProcessor
    integer(i4), intent(in) :: nPoints, nDim
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    postProcessor%nPoints = nPoints
    postProcessor%nDim = nDim

    allocate(postProcessor%coordinates(nDim, nPoints))
    allocate(postProcessor%fieldValues(nPoints, nDim))
    allocate(postProcessor%gradients(nDim, nDim, nPoints))

    postProcessor%coordinates = 0.0_wp
    postProcessor%fieldValues = 0.0_wp
    postProcessor%gradients = 0.0_wp

    postProcessor%contourVariable = ""
    postProcessor%contourMin = 0.0_wp
    postProcessor%contourMax = 0.0_wp
    postProcessor%nContourLevels = 10_i4

    status%status_code = IF_STATUS_OK
  end subroutine CreatePostProcessor

  subroutine MD_PostProcessor_Init(this, nPoints, nDim)
    class(MD_PostProcessor), intent(inout) :: this
    integer(i4), intent(in) :: nPoints, nDim

    this%nPoints = nPoints
    this%nDim = nDim

    allocate(this%coordinates(nDim, nPoints))
    allocate(this%fieldValues(nPoints, nDim))
    allocate(this%gradients(nDim, nDim, nPoints))

    this%coordinates = 0.0_wp
    this%fieldValues = 0.0_wp
    this%gradients = 0.0_wp

    this%contourVariable = ""
    this%contourMin = 0.0_wp
    this%contourMax = 0.0_wp
    this%nContourLevels = 10_i4
  end subroutine MD_PostProcessor_Init

  subroutine MD_PostProcessor_SetPoints(this, coordinates, fieldValues, gradients)
    class(MD_PostProcessor), intent(inout) :: this
    real(wp), intent(in) :: coordinates(:,:)
    real(wp), intent(in), optional :: fieldValues(:,:), gradients(:,:,:)

    integer(i4) :: nDim, nPoints

    nDim = size(coordinates, 1)
    nPoints = size(coordinates, 2)

    this%coordinates = coordinates

    if (present(fieldValues)) then
      this%fieldValues = fieldValues
    end if

    if (present(gradients)) then
      this%gradients = gradients
    end if
  end subroutine MD_PostProcessor_SetPoints

  subroutine MD_PostProcessor_SetContour(this, variable, minValue, maxValue, nLevels)
    class(MD_PostProcessor), intent(inout) :: this
    character(len=*), intent(in) :: variable
    real(wp), intent(in) :: minValue, maxValue
    integer(i4), intent(in), optional :: nLevels

    this%contourVariable = trim(variable)
    this%contourMin = minValue
    this%contourMax = maxValue

    if (present(nLevels)) then
      this%nContourLevels = nLevels
    end if
  end subroutine MD_PostProcessor_SetContour

  subroutine ComputeContourData(postProcessor, contourLevels, contourValues, status)
    type(MD_PostProcessor), intent(in) :: postProcessor
    real(wp), intent(out) :: contourLevels(:)
    real(wp), intent(out) :: contourValues(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, nLevels, nPoints
    real(wp) :: delta

    call init_error_status(status)

    nLevels = postProcessor%nContourLevels
    nPoints = postProcessor%nPoints

    delta = (postProcessor%contourMax - postProcessor%contourMin) / real(nLevels - 1, wp)

    do i = 1, nLevels
      contourLevels(i) = postProcessor%contourMin + real(i - 1, wp) * delta
    end do

    do i = 1, nPoints
      do j = 1, nLevels
        contourValues(i, j) = postProcessor%fieldValues(i, 1)
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ComputeContourData

  subroutine ComputeVectorData(postProcessor, vectorData, status)
    type(MD_PostProcessor), intent(in) :: postProcessor
    real(wp), intent(out) :: vectorData(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, nPoints, nDim

    call init_error_status(status)

    nPoints = postProcessor%nPoints
    nDim = postProcessor%nDim

    do i = 1, nPoints
      vectorData(i, 1:nDim) = postProcessor%fieldValues(i, 1:nDim)
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ComputeVectorData

  subroutine ComputeTensorData(postProcessor, tensorData, status)
    type(MD_PostProcessor), intent(in) :: postProcessor
    real(wp), intent(out) :: tensorData(:,:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, k, nPoints, nDim

    call init_error_status(status)

    nPoints = postProcessor%nPoints
    nDim = postProcessor%nDim

    do i = 1, nPoints
      do j = 1, nDim
        do k = 1, nDim
          tensorData(i, j, k) = postProcessor%gradients(j, k, i)
        end do
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ComputeTensorData

  subroutine MD_PostProcessor_Cleanup(this)
    class(MD_PostProcessor), intent(inout) :: this

    if (allocated(this%coordinates)) deallocate(this%coordinates)
    if (allocated(this%fieldValues)) deallocate(this%fieldValues)
    if (allocated(this%gradients)) deallocate(this%gradients)

    this%nPoints = 0_i4
    this%nDim = 0_i4
  end subroutine MD_PostProcessor_Cleanup

end module MD_Out_UniFldOps