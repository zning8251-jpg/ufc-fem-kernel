!===============================================================================
! MODULE:  MD_Base_Def
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Def (type definition authority)
! BRIEF:   Core FEM data structure types for L3 model description.
!          Mesh, Material, Section, Set, Amplitude, Step, Constraint, Part
!          domain controllers aggregated into root MD_ModelCtrl_Type.
!===============================================================================
MODULE MD_Base_Def
  USE IF_Prec_Core,   ONLY: wp, i4, i8
  USE MD_Int_Def,     ONLY: MD_ContactCtrl_Type, MD_ContactCtrl_Init, &
                            MD_ContactCtrl_Free
  USE MD_LoadBC_Types, ONLY: MD_LoadBC_Ctrl_Type, MD_LoadBC_Ctrl_Init, &
                             MD_LoadBC_Ctrl_Free
  USE MD_Out_Def,     ONLY: MD_OutCtrl_Type, MD_OutCtrl_Init, MD_OutCtrl_Free
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Constants
  !---------------------------------------------------------------------------
  INTEGER, PARAMETER, PUBLIC :: MD_BASE_SLEN = 64   ! short string length
  INTEGER, PARAMETER, PUBLIC :: MD_BASE_MLEN = 256  ! medium string length

  !=============================================================================
  ! Mesh Domain Types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_NodeTbl_Desc
  ! KIND:  Desc
  ! DESC:  Node coordinate and DOF mapping table
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_NodeTbl_Type
    INTEGER(i4)              :: nNodes = 0_i4      ! node count
    INTEGER(i4)              :: nDim   = 3_i4      ! spatial dimension {2,3}
    REAL(wp), ALLOCATABLE    :: coords(:,:)        ! coordinates (nDim x nNodes)
    INTEGER(i4), ALLOCATABLE :: dofMap(:,:)        ! DOF map (maxDof x nNodes)
  END TYPE MD_NodeTbl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemTbl_Desc
  ! KIND:  Desc
  ! DESC:  Element connectivity and type assignment table
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ElemTbl_Type
    INTEGER(i4)              :: nElems = 0_i4      ! element count
    INTEGER(i4), ALLOCATABLE :: elemId(:)          ! element IDs (nElems)
    INTEGER(i4), ALLOCATABLE :: typeId(:)          ! type IDs (nElems)
    INTEGER(i4), ALLOCATABLE :: conn(:,:)          ! connectivity (maxNodes x nElems)
  END TYPE MD_ElemTbl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemDef_Desc
  ! KIND:  Desc
  ! DESC:  Single element type definition (nodes, DOF, Gauss points)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ElemDef_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! element name (C3D8, S4R)
    CHARACTER(LEN=32)           :: family = ""     ! family (SOLID, SHELL, BEAM)
    INTEGER(i4) :: nNode   = 0_i4                  ! nodes per element
    INTEGER(i4) :: nDof    = 0_i4                  ! DOF per node
    INTEGER(i4) :: nGP     = 0_i4                  ! Gauss point count
    INTEGER(i4) :: nCoord  = 0_i4                  ! coordinate dimension
    INTEGER(i4) :: nStress = 0_i4                  ! stress component count
    LOGICAL     :: isNonlin = .FALSE.              ! nonlinear geometry flag
  END TYPE MD_ElemDef_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemDefTbl_Desc
  ! KIND:  Desc
  ! DESC:  Collection of element type definitions
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ElemDefTbl_Type
    INTEGER(i4) :: nElemTypes = 0_i4               ! type count
    TYPE(MD_ElemDef_Type), ALLOCATABLE :: ElemDefs(:)  ! definitions array
  END TYPE MD_ElemDefTbl_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MeshCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Mesh domain controller (nodes + elements + definitions)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MeshCtrl_Type
    TYPE(MD_NodeTbl_Type)    :: NodeTbl            ! node table
    TYPE(MD_ElemTbl_Type)    :: ElemTbl            ! element table
    TYPE(MD_ElemDefTbl_Type) :: ElemDefTbl         ! element definition table
  END TYPE MD_MeshCtrl_Type

  !=============================================================================
  ! Material Domain Types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MatDef_Desc
  ! KIND:  Desc
  ! DESC:  Material property definition with state variable layout
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MatDef_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name     = ""   ! material name
    CHARACTER(LEN=32)           :: category = ""   ! category (Elastic, Plastic)
    CHARACTER(LEN=32)           :: type     = ""   ! type (Isotropic, Orthotropic)
    INTEGER(i4)                 :: nProps   = 0_i4 ! property count
    REAL(wp), ALLOCATABLE       :: props(:)        ! property values (nProps)
    INTEGER(i4)                 :: nState   = 0_i4 ! state variable count
    CHARACTER(LEN=32), ALLOCATABLE :: stateNames(:)  ! state variable names
  END TYPE MD_MatDef_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MatLib_Desc
  ! KIND:  Desc
  ! DESC:  Material library collection
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MatLib_Type
    INTEGER(i4) :: nMats = 0_i4                    ! material count
    TYPE(MD_MatDef_Type), ALLOCATABLE :: MatDefs(:)  ! material definitions
  END TYPE MD_MatLib_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MatAssign_Desc
  ! KIND:  Desc
  ! DESC:  Element-to-material assignment mapping
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MatAssign_Type
    INTEGER(i4), ALLOCATABLE :: matIdOfElem(:)     ! material ID per element
  END TYPE MD_MatAssign_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MatCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Material domain controller (library + assignment)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MatCtrl_Type
    TYPE(MD_MatLib_Type)    :: MatLib               ! material library
    TYPE(MD_MatAssign_Type) :: MatAssign            ! material assignment
  END TYPE MD_MatCtrl_Type

  !=============================================================================
  ! Section Domain Types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_SectDef_Desc
  ! KIND:  Desc
  ! DESC:  Section property definition
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_SectDef_Type
    INTEGER(i4)                 :: sectId    = 0_i4   ! section ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name      = ""     ! section name
    CHARACTER(LEN=32)           :: type      = ""     ! type (SOLID, SHELL, BEAM)
    REAL(wp)                    :: thickness = 0.0_wp ! section thickness
    CHARACTER(LEN=MD_BASE_SLEN) :: matName   = ""     ! assigned material name
    CHARACTER(LEN=MD_BASE_SLEN) :: elemSet   = ""     ! assigned element set
  END TYPE MD_SectDef_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_SectCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Section domain controller
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_SectCtrl_Type
    INTEGER(i4) :: nSects = 0_i4                   ! section count
    TYPE(MD_SectDef_Type), ALLOCATABLE :: SectDefs(:)  ! section definitions
  END TYPE MD_SectCtrl_Type

  !=============================================================================
  ! Set Domain Types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_NodeSet_Desc
  ! KIND:  Desc
  ! DESC:  Named node set
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_NodeSet_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! set name
    INTEGER(i4)                 :: nNodes = 0_i4   ! node count
    INTEGER(i4), ALLOCATABLE    :: nodeId(:)       ! node IDs
  END TYPE MD_NodeSet_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ElemSet_Desc
  ! KIND:  Desc
  ! DESC:  Named element set
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ElemSet_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! set name
    INTEGER(i4)                 :: nElems = 0_i4   ! element count
    INTEGER(i4), ALLOCATABLE    :: elemId(:)       ! element IDs
  END TYPE MD_ElemSet_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_Surface_Desc
  ! KIND:  Desc
  ! DESC:  Named surface definition (element faces)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Surface_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! surface name
    CHARACTER(LEN=32)           :: type   = ""     ! type: ELEMENT, NODE
    INTEGER(i4)                 :: nFaces = 0_i4   ! face count
    INTEGER(i4), ALLOCATABLE    :: elemId(:)       ! element IDs
    INTEGER(i4), ALLOCATABLE    :: faceId(:)       ! face IDs
  END TYPE MD_Surface_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_SetCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Set domain controller (node sets + element sets + surfaces)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_SetCtrl_Type
    INTEGER(i4) :: nNodeSets = 0_i4                ! node set count
    INTEGER(i4) :: nElemSets = 0_i4                ! element set count
    INTEGER(i4) :: nSurfaces = 0_i4                ! surface count
    TYPE(MD_NodeSet_Type), ALLOCATABLE  :: NodeSets(:)  ! node sets
    TYPE(MD_ElemSet_Type), ALLOCATABLE  :: ElemSets(:)  ! element sets
    TYPE(MD_Surface_Type), ALLOCATABLE  :: Surfaces(:)  ! surfaces
  END TYPE MD_SetCtrl_Type

  !=============================================================================
  ! Amplitude Domain Types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_AmpDef_Desc
  ! KIND:  Desc
  ! DESC:  Amplitude curve definition (time-value pairs)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_AmpDef_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name    = ""    ! amplitude name
    CHARACTER(LEN=32)           :: type    = ""    ! type: TABULAR, SMOOTH, PERIODIC
    INTEGER(i4)                 :: nPoints = 0_i4  ! data point count
    REAL(wp), ALLOCATABLE       :: time(:)         ! time values
    REAL(wp), ALLOCATABLE       :: value(:)        ! amplitude values
  END TYPE MD_AmpDef_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_AmpCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Amplitude domain controller
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_AmpCtrl_Type
    INTEGER(i4) :: nAmps = 0_i4                    ! amplitude count
    TYPE(MD_AmpDef_Type), ALLOCATABLE :: AmpDefs(:)  ! amplitude definitions
  END TYPE MD_AmpCtrl_Type

  !=============================================================================
  ! Step Domain Types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_StepCfg_Desc
  ! KIND:  Desc
  ! DESC:  Single analysis step configuration
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_StepCfg_Type
    INTEGER(i4)                 :: stepId   = 0_i4   ! step ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name     = ""     ! step name
    CHARACTER(LEN=32)           :: analysis = ""     ! type: STATIC, DYNAMIC, FREQ
    REAL(wp)                    :: totalTime = 0.0_wp ! total step time
    REAL(wp)                    :: dt       = 0.0_wp  ! time increment
    INTEGER(i4)                 :: nIncs    = 0_i4   ! increment count
    LOGICAL                     :: nlgeom   = .FALSE. ! nonlinear geometry flag
  END TYPE MD_StepCfg_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_StepDef_Desc
  ! KIND:  Desc
  ! DESC:  Step domain controller (collection of step configs)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_StepDef_Type
    INTEGER(i4) :: nSteps = 0_i4                   ! step count
    TYPE(MD_StepCfg_Type), ALLOCATABLE :: StepCfg(:)  ! step configurations
  END TYPE MD_StepDef_Type

  !=============================================================================
  ! Constraint Domain Types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_MPC_Desc
  ! KIND:  Desc
  ! DESC:  Multi-point constraint definition
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_MPC_Constraint_Type
    INTEGER(i4)                 :: id     = 0_i4   ! constraint ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! constraint name
    INTEGER(i4)                 :: stepId = 0_i4   ! active step ID
    INTEGER(i4)                 :: nNodes = 0_i4   ! node count
    INTEGER(i4), ALLOCATABLE    :: nodeIds(:)      ! node IDs
    INTEGER(i4), ALLOCATABLE    :: dofIds(:)       ! DOF IDs
    REAL(wp), ALLOCATABLE       :: coeffs(:)       ! coefficients
    REAL(wp)                    :: rhs    = 0.0_wp ! right-hand side value
  END TYPE MD_MPC_Constraint_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_EqConst_Desc
  ! KIND:  Desc
  ! DESC:  Equation constraint definition
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Eq_Constraint_Type
    INTEGER(i4)                 :: id     = 0_i4   ! constraint ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! constraint name
    INTEGER(i4)                 :: stepId = 0_i4   ! active step ID
    INTEGER(i4)                 :: nTerms = 0_i4   ! term count
    INTEGER(i4), ALLOCATABLE    :: nodeIds(:)      ! node IDs
    INTEGER(i4), ALLOCATABLE    :: dofIds(:)       ! DOF IDs
    REAL(wp), ALLOCATABLE       :: coeffs(:)       ! coefficients
    REAL(wp)                    :: rhs    = 0.0_wp ! right-hand side value
  END TYPE MD_Eq_Constraint_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_Coupling_Desc
  ! KIND:  Desc
  ! DESC:  Coupling constraint (Kinematic/Distributing)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Coupling_Constraint_Type
    INTEGER(i4)                 :: id           = 0_i4  ! constraint ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name         = ""    ! constraint name
    INTEGER(i4)                 :: stepId       = 0_i4  ! active step ID
    INTEGER(i4)                 :: refNodeId    = 0_i4  ! reference node ID
    CHARACTER(LEN=MD_BASE_SLEN) :: surfaceSet   = ""    ! surface set name
    CHARACTER(LEN=32)           :: couplingType = ""    ! KINEMATIC, DISTRIBUTING
  END TYPE MD_Coupling_Constraint_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_RigidBody_Desc
  ! KIND:  Desc
  ! DESC:  Rigid body constraint definition
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_RigidBody_Constraint_Type
    INTEGER(i4)                 :: id        = 0_i4  ! constraint ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name      = ""    ! constraint name
    INTEGER(i4)                 :: stepId    = 0_i4  ! active step ID
    INTEGER(i4)                 :: refNodeId = 0_i4  ! reference node ID
    CHARACTER(LEN=MD_BASE_SLEN) :: bodySet   = ""    ! body set name
  END TYPE MD_RigidBody_Constraint_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ConstCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Constraint domain controller (MPC + Eq + Coupling + RigidBody)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ConstCtrl_Type
    INTEGER(i4) :: nMPCs        = 0_i4             ! MPC count
    INTEGER(i4) :: nEquations   = 0_i4             ! equation count
    INTEGER(i4) :: nCouplings   = 0_i4             ! coupling count
    INTEGER(i4) :: nRigidBodies = 0_i4             ! rigid body count
    TYPE(MD_MPC_Constraint_Type), ALLOCATABLE       :: mpcs(:)
    TYPE(MD_Eq_Constraint_Type), ALLOCATABLE        :: equations(:)
    TYPE(MD_Coupling_Constraint_Type), ALLOCATABLE  :: couplings(:)
    TYPE(MD_RigidBody_Constraint_Type), ALLOCATABLE :: rigidbodies(:)
  END TYPE MD_ConstCtrl_Type

  !=============================================================================
  ! Part/Assembly Domain Types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_Part_Desc
  ! KIND:  Desc
  ! DESC:  Part definition with local mesh
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Part_Type
    INTEGER(i4)                 :: partId = 0_i4   ! part ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name   = ""     ! part name
    TYPE(MD_MeshCtrl_Type)      :: localMesh       ! part-local mesh data
    INTEGER(i4), ALLOCATABLE    :: matIds(:)       ! assigned material IDs
    INTEGER(i4), ALLOCATABLE    :: sectIds(:)      ! assigned section IDs
  END TYPE MD_Part_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_Instance_Desc
  ! KIND:  Desc
  ! DESC:  Part instance with transform
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Instance_Type
    INTEGER(i4)                 :: instId  = 0_i4  ! instance ID
    CHARACTER(LEN=MD_BASE_SLEN) :: name    = ""    ! instance name
    INTEGER(i4)                 :: partId  = 0_i4  ! referenced part ID
    REAL(wp)                    :: translation(3) = 0.0_wp  ! translation vector
    REAL(wp)                    :: rotation(3,3)   ! rotation matrix
    LOGICAL                     :: isDep   = .FALSE.  ! dependent instance flag
  END TYPE MD_Instance_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_Assembly_Desc
  ! KIND:  Desc
  ! DESC:  Assembly container (collection of instances)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Assembly_Type
    CHARACTER(LEN=MD_BASE_SLEN) :: name       = ""   ! assembly name
    INTEGER(i4)                 :: nInstances = 0_i4 ! instance count
    TYPE(MD_Instance_Type), ALLOCATABLE :: instances(:)  ! instance array
  END TYPE MD_Assembly_Type


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_PartCtrl_Desc
  ! KIND:  Desc
  ! DESC:  Part domain controller (parts + assembly)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_PartCtrl_Type
    INTEGER(i4) :: nParts = 0_i4                   ! part count
    TYPE(MD_Part_Type), ALLOCATABLE :: parts(:)    ! part array
    TYPE(MD_Assembly_Type)          :: assembly    ! assembly container
  END TYPE MD_PartCtrl_Type

  !=============================================================================
  ! Root Controller
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_ModelCtrl_Desc
  ! KIND:  Desc
  ! DESC:  L3 model root controller aggregating all domain controllers
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ModelCtrl_Type
    ! Core domain controllers
    TYPE(MD_MeshCtrl_Type)     :: mesh          ! mesh domain
    TYPE(MD_MatCtrl_Type)      :: material      ! material domain
    TYPE(MD_SectCtrl_Type)     :: section       ! section domain
    TYPE(MD_SetCtrl_Type)      :: sets          ! set domain
    TYPE(MD_AmpCtrl_Type)      :: amplitude     ! amplitude domain
    TYPE(MD_StepDef_Type)      :: step          ! step domain
    ! P0 domain controllers
    TYPE(MD_ConstCtrl_Type)    :: constraint    ! constraint domain
    TYPE(MD_PartCtrl_Type)     :: part          ! part/assembly domain
    ! P1 domain controllers (imported)
    TYPE(MD_LoadBC_Ctrl_Type)  :: loadbc        ! load & BC domain
    TYPE(MD_ContactCtrl_Type)  :: interaction   ! contact domain
    TYPE(MD_OutCtrl_Type)      :: output        ! output domain
  END TYPE MD_ModelCtrl_Type

  !---------------------------------------------------------------------------
  ! Public interface
  !---------------------------------------------------------------------------
  PUBLIC :: MD_ModelCtrl_Init
  PUBLIC :: MD_ModelCtrl_Free

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_ModelCtrl_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize all domain controllers to default state
  !---------------------------------------------------------------------------
  SUBROUTINE MD_ModelCtrl_Init(ctrl)
    TYPE(MD_ModelCtrl_Type), INTENT(INOUT) :: ctrl  ! [inout] root controller

    ctrl%mesh%NodeTbl%nNodes    = 0
    ctrl%mesh%ElemTbl%nElems    = 0
    ctrl%material%MatLib%nMats  = 0
    ctrl%section%nSects         = 0
    ctrl%sets%nNodeSets         = 0
    ctrl%amplitude%nAmps        = 0
    ctrl%step%nSteps            = 0
    ctrl%constraint%nMPCs       = 0
    ctrl%part%nParts            = 0
    CALL MD_LoadBC_Ctrl_Init(ctrl%loadbc)
    CALL MD_ContactCtrl_Init(ctrl%interaction)
    CALL MD_OutCtrl_Init(ctrl%output)
  END SUBROUTINE MD_ModelCtrl_Init


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_ModelCtrl_Free
  ! PHASE:      P0
  ! PURPOSE:    Deallocate all dynamic memory in domain controllers
  !---------------------------------------------------------------------------
  SUBROUTINE MD_ModelCtrl_Free(ctrl)
    TYPE(MD_ModelCtrl_Type), INTENT(INOUT) :: ctrl  ! [inout] root controller
    INTEGER(i4) :: i

    ! Free Mesh domain
    IF (ALLOCATED(ctrl%mesh%NodeTbl%coords))    DEALLOCATE(ctrl%mesh%NodeTbl%coords)
    IF (ALLOCATED(ctrl%mesh%NodeTbl%dofMap))     DEALLOCATE(ctrl%mesh%NodeTbl%dofMap)
    IF (ALLOCATED(ctrl%mesh%ElemTbl%elemId))     DEALLOCATE(ctrl%mesh%ElemTbl%elemId)
    IF (ALLOCATED(ctrl%mesh%ElemTbl%typeId))     DEALLOCATE(ctrl%mesh%ElemTbl%typeId)
    IF (ALLOCATED(ctrl%mesh%ElemTbl%conn))       DEALLOCATE(ctrl%mesh%ElemTbl%conn)
    IF (ALLOCATED(ctrl%mesh%ElemDefTbl%ElemDefs)) &
      DEALLOCATE(ctrl%mesh%ElemDefTbl%ElemDefs)

    ! Free Mat domain
    IF (ALLOCATED(ctrl%material%MatLib%MatDefs)) THEN
      DO i = 1, SIZE(ctrl%material%MatLib%MatDefs)
        IF (ALLOCATED(ctrl%material%MatLib%MatDefs(i)%props)) &
          DEALLOCATE(ctrl%material%MatLib%MatDefs(i)%props)
        IF (ALLOCATED(ctrl%material%MatLib%MatDefs(i)%stateNames)) &
          DEALLOCATE(ctrl%material%MatLib%MatDefs(i)%stateNames)
      END DO
      DEALLOCATE(ctrl%material%MatLib%MatDefs)
    END IF
    IF (ALLOCATED(ctrl%material%MatAssign%matIdOfElem)) &
      DEALLOCATE(ctrl%material%MatAssign%matIdOfElem)

    ! Free Sect domain
    IF (ALLOCATED(ctrl%section%SectDefs)) DEALLOCATE(ctrl%section%SectDefs)

    ! Free Set domain
    IF (ALLOCATED(ctrl%sets%NodeSets)) THEN
      DO i = 1, SIZE(ctrl%sets%NodeSets)
        IF (ALLOCATED(ctrl%sets%NodeSets(i)%nodeId)) &
          DEALLOCATE(ctrl%sets%NodeSets(i)%nodeId)
      END DO
      DEALLOCATE(ctrl%sets%NodeSets)
    END IF
    IF (ALLOCATED(ctrl%sets%ElemSets)) THEN
      DO i = 1, SIZE(ctrl%sets%ElemSets)
        IF (ALLOCATED(ctrl%sets%ElemSets(i)%elemId)) &
          DEALLOCATE(ctrl%sets%ElemSets(i)%elemId)
      END DO
      DEALLOCATE(ctrl%sets%ElemSets)
    END IF
    IF (ALLOCATED(ctrl%sets%Surfaces)) THEN
      DO i = 1, SIZE(ctrl%sets%Surfaces)
        IF (ALLOCATED(ctrl%sets%Surfaces(i)%elemId)) &
          DEALLOCATE(ctrl%sets%Surfaces(i)%elemId)
        IF (ALLOCATED(ctrl%sets%Surfaces(i)%faceId)) &
          DEALLOCATE(ctrl%sets%Surfaces(i)%faceId)
      END DO
      DEALLOCATE(ctrl%sets%Surfaces)
    END IF

    ! Free Amp domain
    IF (ALLOCATED(ctrl%amplitude%AmpDefs)) THEN
      DO i = 1, SIZE(ctrl%amplitude%AmpDefs)
        IF (ALLOCATED(ctrl%amplitude%AmpDefs(i)%time)) &
          DEALLOCATE(ctrl%amplitude%AmpDefs(i)%time)
        IF (ALLOCATED(ctrl%amplitude%AmpDefs(i)%value)) &
          DEALLOCATE(ctrl%amplitude%AmpDefs(i)%value)
      END DO
      DEALLOCATE(ctrl%amplitude%AmpDefs)
    END IF

    ! Free Step domain
    IF (ALLOCATED(ctrl%step%StepCfg)) DEALLOCATE(ctrl%step%StepCfg)

    ! Free Constraint domain
    IF (ALLOCATED(ctrl%constraint%mpcs)) THEN
      DO i = 1, SIZE(ctrl%constraint%mpcs)
        IF (ALLOCATED(ctrl%constraint%mpcs(i)%nodeIds)) &
          DEALLOCATE(ctrl%constraint%mpcs(i)%nodeIds)
        IF (ALLOCATED(ctrl%constraint%mpcs(i)%dofIds)) &
          DEALLOCATE(ctrl%constraint%mpcs(i)%dofIds)
        IF (ALLOCATED(ctrl%constraint%mpcs(i)%coeffs)) &
          DEALLOCATE(ctrl%constraint%mpcs(i)%coeffs)
      END DO
      DEALLOCATE(ctrl%constraint%mpcs)
    END IF
    IF (ALLOCATED(ctrl%constraint%equations)) THEN
      DO i = 1, SIZE(ctrl%constraint%equations)
        IF (ALLOCATED(ctrl%constraint%equations(i)%nodeIds)) &
          DEALLOCATE(ctrl%constraint%equations(i)%nodeIds)
        IF (ALLOCATED(ctrl%constraint%equations(i)%dofIds)) &
          DEALLOCATE(ctrl%constraint%equations(i)%dofIds)
        IF (ALLOCATED(ctrl%constraint%equations(i)%coeffs)) &
          DEALLOCATE(ctrl%constraint%equations(i)%coeffs)
      END DO
      DEALLOCATE(ctrl%constraint%equations)
    END IF
    IF (ALLOCATED(ctrl%constraint%couplings))   DEALLOCATE(ctrl%constraint%couplings)
    IF (ALLOCATED(ctrl%constraint%rigidbodies)) DEALLOCATE(ctrl%constraint%rigidbodies)

    ! Free Part domain
    IF (ALLOCATED(ctrl%part%parts)) THEN
      DO i = 1, SIZE(ctrl%part%parts)
        IF (ALLOCATED(ctrl%part%parts(i)%matIds)) &
          DEALLOCATE(ctrl%part%parts(i)%matIds)
        IF (ALLOCATED(ctrl%part%parts(i)%sectIds)) &
          DEALLOCATE(ctrl%part%parts(i)%sectIds)
        CALL MD_Base_Free_LocalMesh(ctrl%part%parts(i)%localMesh)
      END DO
      DEALLOCATE(ctrl%part%parts)
    END IF
    IF (ALLOCATED(ctrl%part%assembly%instances)) &
      DEALLOCATE(ctrl%part%assembly%instances)

    ! Free P1/P2 domain controllers
    CALL MD_LoadBC_Ctrl_Free(ctrl%loadbc)
    CALL MD_ContactCtrl_Free(ctrl%interaction)
    CALL MD_OutCtrl_Free(ctrl%output)
  END SUBROUTINE MD_ModelCtrl_Free


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Base_Free_LocalMesh
  ! PHASE:      P0
  ! PURPOSE:    Free part-local mesh allocations
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Base_Free_LocalMesh(mesh)
    TYPE(MD_MeshCtrl_Type), INTENT(INOUT) :: mesh  ! [inout] local mesh

    IF (ALLOCATED(mesh%NodeTbl%coords))      DEALLOCATE(mesh%NodeTbl%coords)
    IF (ALLOCATED(mesh%NodeTbl%dofMap))       DEALLOCATE(mesh%NodeTbl%dofMap)
    IF (ALLOCATED(mesh%ElemTbl%elemId))       DEALLOCATE(mesh%ElemTbl%elemId)
    IF (ALLOCATED(mesh%ElemTbl%typeId))       DEALLOCATE(mesh%ElemTbl%typeId)
    IF (ALLOCATED(mesh%ElemTbl%conn))         DEALLOCATE(mesh%ElemTbl%conn)
    IF (ALLOCATED(mesh%ElemDefTbl%ElemDefs))  DEALLOCATE(mesh%ElemDefTbl%ElemDefs)
  END SUBROUTINE MD_Base_Free_LocalMesh

END MODULE MD_Base_Def
