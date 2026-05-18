!===============================================================================
! FILE:    MD_BaseTypes.f90
! LAYER:   L3_MD
! DOMAIN:  Model / Base Types
! ROLE:    _Def (multi-module legacy type file)
! BRIEF:   Unified type definitions for MD and UF layers. Contains multiple
!          modules for dependency management. LEGACY-EXEMPT: multi-module file,
!          split deferred. New code should NOT follow this pattern.
!
! MODULES: MD_BaseTypes, MD_Model_Kernel_Types, MD_Elem_Types,
!          MD_Elem_Base, MD_TypeSystem
!===============================================================================

!===============================================================================
! MODULE:  MD_BaseTypes
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Def (kernel mesh/material type definitions, standalone)
! BRIEF:   Lightweight kernel type definitions (IF_Prec only dependency).
!          Types superseded by MD_Base_Def.f90 equivalents for rich usage.
!===============================================================================
MODULE MD_BaseTypes
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemDef_Desc
  ! KIND:  Desc
  ! DESC:  Kernel element definition (lightweight)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ElemDef_Type
    CHARACTER(LEN=16) :: name     = ""       ! element name
    CHARACTER(LEN=8)  :: family   = ""       ! element family
    INTEGER(i4)       :: nNode    = 0_i4     ! nodes per element
    INTEGER(i4)       :: nDof     = 0_i4     ! DOF per node
    INTEGER(i4)       :: nGP      = 0_i4     ! Gauss point count
    INTEGER(i4)       :: nCoord   = 0_i4     ! coordinate dimension
    INTEGER(i4)       :: nStress  = 0_i4     ! stress component count
    LOGICAL           :: isNonlin = .FALSE.  ! nonlinear geometry flag
  END TYPE MD_ElemDef_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_NodeTbl_Desc
  ! KIND:  Desc
  ! DESC:  Kernel node table
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_NodeTbl_Type
    INTEGER(i4)              :: nNodes = 0_i4  ! node count
    INTEGER(i4)              :: nDim   = 3_i4  ! spatial dimension
    REAL(wp), ALLOCATABLE    :: coords(:,:)    ! coordinates (nDim x nNodes)
    INTEGER(i4), ALLOCATABLE :: dofMap(:,:)    ! DOF map
  END TYPE MD_NodeTbl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemTbl_Desc
  ! KIND:  Desc
  ! DESC:  Kernel element table
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ElemTbl_Type
    INTEGER(i4)              :: nElems = 0_i4  ! element count
    INTEGER(i4), ALLOCATABLE :: elemId(:)      ! element IDs
    INTEGER(i4), ALLOCATABLE :: typeId(:)      ! type IDs
    INTEGER(i4), ALLOCATABLE :: conn(:,:)      ! connectivity
  END TYPE MD_ElemTbl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemDefTbl_Desc
  ! KIND:  Desc
  ! DESC:  Kernel element definition table
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ElemDefTbl_Type
    INTEGER(i4) :: nElemTypes = 0_i4                   ! type count
    TYPE(MD_ElemDef_Type), ALLOCATABLE :: ElemDefs(:)   ! definitions
  END TYPE MD_ElemDefTbl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MeshCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Kernel mesh controller
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MeshCtrl_Type
    TYPE(MD_NodeTbl_Type)    :: NodeTbl     ! node table
    TYPE(MD_ElemTbl_Type)    :: ElemTbl     ! element table
    TYPE(MD_ElemDefTbl_Type) :: ElemDefTbl  ! element definitions
  END TYPE MD_MeshCtrl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MatDef_Desc
  ! KIND:  Desc
  ! DESC:  Kernel material definition
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MatDef_Type
    CHARACTER(LEN=32) :: name     = ""       ! material name
    CHARACTER(LEN=16) :: category = ""       ! category
    CHARACTER(LEN=16) :: type     = ""       ! type
    INTEGER(i4)       :: nProps   = 0_i4     ! property count
    REAL(wp), ALLOCATABLE :: props(:)        ! properties
    INTEGER(i4)       :: nState   = 0_i4     ! state variable count
    CHARACTER(LEN=32), ALLOCATABLE :: stateNames(:)  ! state names
  END TYPE MD_MatDef_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MatLib_Desc
  ! KIND:  Desc
  ! DESC:  Kernel material library
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MatLib_Type
    INTEGER(i4) :: nMats = 0_i4                        ! material count
    TYPE(MD_MatDef_Type), ALLOCATABLE :: MatDefs(:)    ! materials
  END TYPE MD_MatLib_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MatAssign_Desc
  ! KIND:  Desc
  ! DESC:  Kernel material assignment
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MatAssign_Type
    INTEGER(i4), ALLOCATABLE :: matIdOfElem(:)  ! mat ID per element
  END TYPE MD_MatAssign_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MatCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Kernel material controller
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MatCtrl_Type
    TYPE(MD_MatLib_Type)    :: MatLib     ! material library
    TYPE(MD_MatAssign_Type) :: MatAssign  ! assignment
  END TYPE MD_MatCtrl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_SectDef_Desc
  ! KIND:  Desc
  ! DESC:  Kernel section definition
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_SectDef_Type
    INTEGER(i4)       :: sectId    = 0_i4    ! section ID
    CHARACTER(LEN=32) :: name      = ""      ! section name
    CHARACTER(LEN=16) :: type      = ""      ! section type
    REAL(wp)          :: thickness = 0.0_wp  ! thickness
  END TYPE MD_SectDef_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_SectCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Kernel section controller
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_SectCtrl_Type
    INTEGER(i4) :: nSects = 0_i4                       ! section count
    TYPE(MD_SectDef_Type), ALLOCATABLE :: SectDefs(:)  ! sections
  END TYPE MD_SectCtrl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_NodeSet_Desc
  ! KIND:  Desc
  ! DESC:  Kernel node set
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_NodeSet_Type
    CHARACTER(LEN=32) :: name   = ""       ! set name
    INTEGER(i4)       :: nNodes = 0_i4     ! node count
    INTEGER(i4), ALLOCATABLE :: nodeId(:)  ! node IDs
  END TYPE MD_NodeSet_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemSet_Desc
  ! KIND:  Desc
  ! DESC:  Kernel element set
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ElemSet_Type
    CHARACTER(LEN=32) :: name   = ""       ! set name
    INTEGER(i4)       :: nElems = 0_i4     ! element count
    INTEGER(i4), ALLOCATABLE :: elemId(:)  ! element IDs
  END TYPE MD_ElemSet_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_SetCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Kernel set controller
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_SetCtrl_Type
    TYPE(MD_NodeSet_Type), ALLOCATABLE :: NodeSets(:)  ! node sets
    TYPE(MD_ElemSet_Type), ALLOCATABLE :: ElemSets(:)  ! element sets
  END TYPE MD_SetCtrl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_AmpDef_Desc
  ! KIND:  Desc
  ! DESC:  Kernel amplitude definition
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_AmpDef_Type
    CHARACTER(LEN=32) :: name = ""          ! amplitude name
    REAL(wp), ALLOCATABLE :: time(:)        ! time values
    REAL(wp), ALLOCATABLE :: value(:)       ! amplitude values
  END TYPE MD_AmpDef_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_AmpCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Kernel amplitude controller
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_AmpCtrl_Type
    INTEGER(i4) :: nAmps = 0_i4                       ! amplitude count
    TYPE(MD_AmpDef_Type), ALLOCATABLE :: AmpDefs(:)   ! amplitudes
  END TYPE MD_AmpCtrl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_StepCfg_Desc
  ! KIND:  Desc
  ! DESC:  Kernel step configuration
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_StepCfg_Type
    CHARACTER(LEN=32) :: name      = ""      ! step name
    CHARACTER(LEN=16) :: analysis  = ""      ! analysis type
    REAL(wp)          :: totalTime = 0.0_wp  ! total step time
    REAL(wp)          :: dt        = 0.0_wp  ! time increment
  END TYPE MD_StepCfg_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_StepDef_Desc
  ! KIND:  Desc
  ! DESC:  Kernel step definition controller
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_StepDef_Type
    INTEGER(i4) :: nSteps = 0_i4                       ! step count
    TYPE(MD_StepCfg_Type), ALLOCATABLE :: StepCfg(:)   ! step configs
  END TYPE MD_StepDef_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ModelCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Kernel model controller (lightweight root aggregate)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ModelCtrl_Type
    TYPE(MD_MeshCtrl_Type) :: mesh       ! mesh domain
    TYPE(MD_MatCtrl_Type)  :: material   ! material domain
    TYPE(MD_SectCtrl_Type) :: section    ! section domain
    TYPE(MD_SetCtrl_Type)  :: sets       ! set domain
    TYPE(MD_AmpCtrl_Type)  :: amplitude  ! amplitude domain
    TYPE(MD_StepDef_Type)  :: step       ! step domain
  END TYPE MD_ModelCtrl_Type

END MODULE MD_BaseTypes


!===============================================================================
! MODULE:  MD_Model_Kernel_Types
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Def (step type string constants)
! BRIEF:   ABAQUS-compatible step type character identifiers for StepDesc.
!===============================================================================
MODULE MD_Model_Kernel_Types
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_MODEL_STEP_Static
  PUBLIC :: MD_MODEL_STEP_ImplicitDynamic
  PUBLIC :: MD_MODEL_STEP_ExplicitDynamic
  PUBLIC :: MD_MODEL_STEP_ArcLength

  CHARACTER(LEN=32), PARAMETER :: MD_MODEL_STEP_Static          = "STATIC"
  CHARACTER(LEN=32), PARAMETER :: MD_MODEL_STEP_ImplicitDynamic = "IMPLICIT_DYNAMIC"
  CHARACTER(LEN=32), PARAMETER :: MD_MODEL_STEP_ExplicitDynamic = "EXPLICIT_DYNAMIC"
  CHARACTER(LEN=32), PARAMETER :: MD_MODEL_STEP_ArcLength       = "ARC_LENGTH"

END MODULE MD_Model_Kernel_Types


!===============================================================================
! MODULE:  MD_Elem_Types
! LAYER:   L3_MD
! DOMAIN:  Model / Element
! ROLE:    _Def (shape function result type)
! BRIEF:   ShapeFuncResult type for UF_ElementLib, shared with MD_Elem_Algo.
!          Extracted to avoid circular dependency.
!===============================================================================
MODULE MD_Elem_Types
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: ShapeFuncResult

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ShapeFunc_Desc
  ! KIND:  Desc
  ! DESC:  Shape function evaluation result container
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: ShapeFuncResult
    INTEGER(i4) :: numNodes     = 0_i4     ! node count
    INTEGER(i4) :: numIntPoints = 0_i4     ! integration point count
    REAL(wp), ALLOCATABLE :: N(:,:)        ! shape functions (nNode x nIP)
    REAL(wp), ALLOCATABLE :: dNdxi(:,:,:)  ! derivatives in natural coords
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:)   ! (nNode x nDim) for Jacobian
    REAL(wp), ALLOCATABLE :: dNdx(:,:,:)   ! derivatives in physical coords
    REAL(wp), ALLOCATABLE :: detJ(:)       ! Jacobian determinants
    REAL(wp), ALLOCATABLE :: weights(:)    ! integration weights
  CONTAINS
    PROCEDURE, PUBLIC :: Init  => ShapeFuncResult_Init
    PROCEDURE, PUBLIC :: Clear => ShapeFuncResult_Clear
  END TYPE ShapeFuncResult

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: ShapeFuncResult_Init
  ! PHASE:      P0
  ! PURPOSE:    Allocate and initialize shape function arrays
  !---------------------------------------------------------------------------
  SUBROUTINE ShapeFuncResult_Init(this, numNodes, numIntPoints)
    CLASS(ShapeFuncResult), INTENT(INOUT) :: this          ! [inout] result
    INTEGER(i4), INTENT(IN), OPTIONAL    :: numNodes      ! [in] node count
    INTEGER(i4), INTENT(IN), OPTIONAL    :: numIntPoints  ! [in] IP count

    IF (PRESENT(numNodes)) this%numNodes = numNodes
    IF (PRESENT(numIntPoints)) this%numIntPoints = numIntPoints
    IF (this%numNodes > 0 .AND. this%numIntPoints > 0) THEN
      ALLOCATE(this%N(this%numNodes, this%numIntPoints))
      ALLOCATE(this%dNdxi(3, this%numNodes, this%numIntPoints))
      ALLOCATE(this%dNdx(3, this%numNodes, this%numIntPoints))
      ALLOCATE(this%detJ(this%numIntPoints))
      ALLOCATE(this%weights(this%numIntPoints))
      this%N       = 0.0_wp
      this%dNdxi   = 0.0_wp
      this%dNdx    = 0.0_wp
      this%detJ    = 0.0_wp
      this%weights = 0.0_wp
    END IF
  END SUBROUTINE ShapeFuncResult_Init


  !---------------------------------------------------------------------------
  ! SUBROUTINE: ShapeFuncResult_Clear
  ! PHASE:      P0
  ! PURPOSE:    Deallocate shape function arrays and reset counts
  !---------------------------------------------------------------------------
  SUBROUTINE ShapeFuncResult_Clear(this)
    CLASS(ShapeFuncResult), INTENT(INOUT) :: this  ! [inout] result

    IF (ALLOCATED(this%N))      DEALLOCATE(this%N)
    IF (ALLOCATED(this%dNdxi))  DEALLOCATE(this%dNdxi)
    IF (ALLOCATED(this%dN_dxi)) DEALLOCATE(this%dN_dxi)
    IF (ALLOCATED(this%dNdx))   DEALLOCATE(this%dNdx)
    IF (ALLOCATED(this%detJ))   DEALLOCATE(this%detJ)
    IF (ALLOCATED(this%weights)) DEALLOCATE(this%weights)
    this%numNodes     = 0_i4
    this%numIntPoints = 0_i4
  END SUBROUTINE ShapeFuncResult_Clear

END MODULE MD_Elem_Types


!===============================================================================
! MODULE:  MD_Elem_Base
! LAYER:   L3_MD
! DOMAIN:  Model / Element
! ROLE:    _Def (extended element types)
! BRIEF:   Extended element types for continuum/thermal/poro with formulation
!          options (integration scheme, kinematic formulation, B-bar).
!===============================================================================
MODULE MD_Elem_Base
  USE IF_Prec_Core,  ONLY: wp, i4
  USE MD_Base_Enums, ONLY: MD_MODEL_UF_TOPO_Hex, MD_MODEL_UF_TOPO_Quad, &
                           MD_MODEL_UF_TOPO_Tet, MD_MODEL_UF_TOPO_Wedge, &
                           MD_MODEL_UF_TOPO_Tri, MD_MODEL_UF_TOPO_Line, &
                           MD_MODEL_UF_TOPO_Pyramid, MD_MODEL_UF_FAMILY_CONTI
  USE MD_Elem_Mgr,   ONLY: ElemType, ElemCtx, ElemFlags
  IMPLICIT NONE
  PRIVATE

  ! Public constants
  PUBLIC :: MD_MODEL_UF_FORM_TL, MD_MODEL_UF_FORM_UL
  PUBLIC :: MD_MODEL_UF_INT_Full, MD_MODEL_UF_INT_Reduced, MD_MODEL_UF_INT_Selective
  PUBLIC :: UF_Topo_Hex, UF_Topo_Line, UF_Topo_Pyramid
  PUBLIC :: UF_Topo_Quad, UF_Topo_Tet, UF_Topo_Tri, UF_Topo_Wedge

  ! Public types
  PUBLIC :: UF_ElemCtx, UF_ElemFlags, UF_ElemFormul, UF_ElemType

  !---------------------------------------------------------------------------
  ! Integration scheme constants
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_INT_Full      = 1  ! full integration
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_INT_Reduced   = 2  ! reduced integration
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_INT_Selective = 3  ! selective integration

  !---------------------------------------------------------------------------
  ! Formulation constants
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_FORM_TL = 1  ! Total Lagrangian
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_FORM_UL = 2  ! Updated Lagrangian

  !---------------------------------------------------------------------------
  ! Topology aliases (case-insensitive convenience)
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: UF_Topo_Hex     = MD_MODEL_UF_TOPO_Hex
  INTEGER(i4), PARAMETER :: UF_Topo_Quad    = MD_MODEL_UF_TOPO_Quad
  INTEGER(i4), PARAMETER :: UF_Topo_Tet     = MD_MODEL_UF_TOPO_Tet
  INTEGER(i4), PARAMETER :: UF_Topo_Wedge   = MD_MODEL_UF_TOPO_Wedge
  INTEGER(i4), PARAMETER :: UF_Topo_Tri     = MD_MODEL_UF_TOPO_Tri
  INTEGER(i4), PARAMETER :: UF_Topo_Line    = MD_MODEL_UF_TOPO_Line
  INTEGER(i4), PARAMETER :: UF_Topo_Pyramid = MD_MODEL_UF_TOPO_Pyramid

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemFormul_Algo
  ! KIND:  Algo
  ! DESC:  Element formulation algorithm configuration
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: UF_ElemFormul
    INTEGER(i4) :: formulationType    = 0                    ! formulation type ID
    INTEGER(i4) :: order              = 1                    ! polynomial order
    INTEGER(i4) :: nIntPoints         = 0                    ! integration point count
    LOGICAL     :: reducedintegrat    = .FALSE.              ! reduced integration flag
    LOGICAL     :: hourglasscontro    = .FALSE.              ! hourglass control flag
    INTEGER(i4) :: integration_scheme = MD_MODEL_UF_INT_Full ! integration scheme
    INTEGER(i4) :: kineFormulation    = MD_MODEL_UF_FORM_UL  ! kinematic formulation
    LOGICAL     :: use_bbar           = .FALSE.              ! B-bar method flag
  END TYPE UF_ElemFormul


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemType_Desc
  ! KIND:  Desc
  ! DESC:  Extended element type with default formulation
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(ElemType) :: UF_ElemType
    TYPE(UF_ElemFormul) :: defaultFormul  ! default formulation config
  END TYPE UF_ElemType


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemCtx_Ctx
  ! KIND:  Ctx
  ! DESC:  Extended element context
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(ElemCtx) :: UF_ElemCtx
  END TYPE UF_ElemCtx


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemFlags_State
  ! KIND:  State
  ! DESC:  Extended element flags
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(ElemFlags) :: UF_ElemFlags
  END TYPE UF_ElemFlags

END MODULE MD_Elem_Base


!===============================================================================
! MODULE:  MD_TypeSystem
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Def (type aggregation re-export)
! BRIEF:   Type aggregation for UFC Model Layer. Re-exports Desc/State types
!          from sub-domain modules. Used by RT_Job_Core, MD_Step_Mgr, etc.
!===============================================================================
MODULE MD_TypeSystem
  USE IF_Prec_Core,      ONLY: i4, wp
  USE MD_Asm_Mgr,        ONLY: AssemDesc
  USE MD_Base_ObjModel,  ONLY: UF_Model, UF_Part, UF_Instance, UF_Element, &
                               UF_Assem, UF_NodeSet, UF_ElemSet, UF_Node, &
                               UF_ModelDesc
  USE MD_Elem_Base,      ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx, &
                               UF_ElemFlags
  USE MD_Asm_Inst,       ONLY: Desc_Instance
  USE MD_Int_Ctx_Core,   ONLY: MD_InterDesc
  USE MD_Kinematics_Def, ONLY: UF_Kinematics
  USE MD_Model_Def, ONLY: Desc_Model => MD_Model_Desc, &
                               State_Model => MD_Model_State
  USE MD_Part_Mgr,       ONLY: PartDesc
  USE MD_Step_Proc,      ONLY: Desc_Step => StepDesc, &
                               State_Step => StepStateData, StepState, &
                               MD_MODEL_STEP_STATIC, MD_MODEL_STEP_IMPLICIT_D, &
                               MD_MODEL_STEP_EXPLICIT_D, MD_MODEL_STEP_ARCLENGTH
  IMPLICIT NONE
  PRIVATE

  ! Public constants
  PUBLIC :: MD_MODEL_STEP_ARCLENGTH, MD_MODEL_STEP_EXPLICIT_D
  PUBLIC :: MD_MODEL_STEP_IMPLICIT_D, MD_MODEL_STEP_STATIC

  ! Public types
  PUBLIC :: AssemDesc, Desc_Instance, Desc_Model, Desc_Step
  PUBLIC :: MD_InterDesc, PartDesc
  PUBLIC :: State_Instance, State_Model, State_Step, StepState
  PUBLIC :: UF_Assem, UF_ElemCtx, UF_ElemFlags, UF_ElemFormul, UF_ElemSet
  PUBLIC :: UF_ElemType, UF_Element, UF_Instance, UF_Kinematics
  PUBLIC :: UF_Model, UF_ModelDesc, UF_Node, UF_NodeSet, UF_Part

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_StateInstance_State
  ! KIND:  State
  ! DESC:  Instance state placeholder (avoids circular dep with MD_Instance)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: State_Instance
    INTEGER(i4) :: id     = 0_i4    ! instance ID
    LOGICAL     :: active = .FALSE. ! active flag
  END TYPE State_Instance

END MODULE MD_TypeSystem
