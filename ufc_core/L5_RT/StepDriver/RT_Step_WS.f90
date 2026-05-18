!===============================================================================
! MODULE: RT_Step_WS
! LAYER:  L5_RT
! DOMAIN: StepDriver
! ROLE:   WS �?Runtime workspace types
! BRIEF:  JobWS, ThreadWS, Owners, Ctx views, UEL pools.
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Step_WS
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_State_API, ONLY: GlobalState, NodeState, ElemState
  USE MD_Base_ObjModel, ONLY: UF_Model
  USE MD_Mesh_GlobalNum, ONLY: MeshGlobalNum
  USE RT_Solv_Def, ONLY: RT_Sol_Cfg, RT_Sol_DofMap
  USE UF_AbaqusUMAT_Types, ONLY: UF_AbaqusUMATVars
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: JobWS
  PUBLIC :: StructWS
  PUBLIC :: UelPools
  PUBLIC :: ThreadWS
  PUBLIC :: Owners
  PUBLIC :: Ctx

  !===========================================================================
  ! Job Memory Estimate
  !===========================================================================
  TYPE, PUBLIC :: JobMemEstimate
    INTEGER(i4) :: maxStructDOF = 0_i4
    INTEGER(i4) :: maxThermalNodes = 0_i4
    INTEGER(i4) :: maxPoroNodes = 0_i4
    INTEGER(i4) :: maxTHMNodes = 0_i4
    INTEGER(i4) :: maxElementNodes = 0_i4
    REAL(wp) :: estimatedmemory = 0.0_wp
  END TYPE JobMemEstimate

  !===========================================================================
  ! Job Workspace
  !===========================================================================
  TYPE, PUBLIC :: JobWS
    TYPE(UF_Model), POINTER :: model => NULL()
    TYPE(JobMemEstimate) :: mem_est
    INTEGER(i4) :: numThreads = 1_i4
    LOGICAL :: init = .FALSE.
  END TYPE JobWS

  !===========================================================================
  ! Structure Workspace
  !===========================================================================
  TYPE, PUBLIC :: StructWS
    REAL(wp), ALLOCATABLE :: Ke(:,:)
    REAL(wp), ALLOCATABLE :: Me(:,:)
    REAL(wp), ALLOCATABLE :: Ce(:,:)
    REAL(wp), ALLOCATABLE :: B(:,:)
    REAL(wp), ALLOCATABLE :: Re(:)
    LOGICAL :: preheated = .FALSE.
  END TYPE StructWS

  !===========================================================================
  !UEL Pools
  !===========================================================================
  TYPE, PUBLIC :: UelPools
    REAL(wp), ALLOCATABLE :: RHS(:,:)
    REAL(wp), ALLOCATABLE :: COORDS(:,:)
    REAL(wp), ALLOCATABLE :: U(:)
    REAL(wp), ALLOCATABLE :: DU(:,:)
    REAL(wp), ALLOCATABLE :: V(:)
    REAL(wp), ALLOCATABLE :: A(:)
    REAL(wp), ALLOCATABLE :: PREDEF(:,:,:)
    REAL(wp), ALLOCATABLE :: ADLMAG(:,:)
    REAL(wp), ALLOCATABLE :: DDLMAG(:,:)
    INTEGER(i4), ALLOCATABLE :: JDLTYP(:,:)
    REAL(wp), ALLOCATABLE :: SVARS(:)
    REAL(wp), ALLOCATABLE :: PROPS(:)
    REAL(wp), ALLOCATABLE :: PARAMS(:)
    LOGICAL :: preheated = .FALSE.
  END TYPE UelPools

  !===========================================================================
  ! Thread Workspace
  !===========================================================================
  TYPE, PUBLIC :: ThreadWS
    TYPE(JobWS), POINTER :: job => NULL()
    INTEGER(i4) :: tid = -1_i4
    TYPE(StructWS) :: ws_struct
    TYPE(UelPools) :: uel_pools
    TYPE(UF_AbaqusUMATVars) :: umat_ws

    ! Solver workspace arrays
    REAL(wp), ALLOCATABLE :: solver_u(:)
    REAL(wp), ALLOCATABLE :: solver_du(:)
    REAL(wp), ALLOCATABLE :: solver_F_ext(:)
    REAL(wp), ALLOCATABLE :: solver_R(:)
    REAL(wp), ALLOCATABLE :: solver_u_ref(:)
    REAL(wp), ALLOCATABLE :: solver_R_int(:)

    ! PCG solver workspace vectors
    REAL(wp), ALLOCATABLE :: pcg_r(:)
    REAL(wp), ALLOCATABLE :: pcg_z(:)
    REAL(wp), ALLOCATABLE :: pcg_p(:)
    REAL(wp), ALLOCATABLE :: pcg_Ap(:)

    ! Iteration workspace
    REAL(wp), ALLOCATABLE :: iter_u_curr(:)
    REAL(wp), ALLOCATABLE :: iter_du_corr(:)
    REAL(wp), ALLOCATABLE :: iter_R_work(:)
    REAL(wp), ALLOCATABLE :: iter_u_prev(:)
    REAL(wp), ALLOCATABLE :: iter_F_int(:)
    INTEGER(i4) :: iter_max_nDOF = 0_i4
    LOGICAL :: iter_preheated = .FALSE.
  END TYPE ThreadWS

  !===========================================================================
  ! Runtime Owners (???)
  !===========================================================================
  TYPE, PUBLIC :: Owners
    TYPE(UF_Model)         :: model
    TYPE(RT_Sol_Cfg)            :: solver
    TYPE(GlobalState)       :: global
    TYPE(NodeState),    ALLOCATABLE :: nodeStates(:)
    TYPE(ElemState), ALLOCATABLE :: elemStates(:)
    TYPE(RT_Sol_DofMap)          :: dofMap
    TYPE(MeshGlobalNum)     :: globNum
    TYPE(ThreadWS), ALLOCATABLE :: workspaces(:)
  CONTAINS
    PROCEDURE :: Init
    FINAL :: Owners_Final
  END TYPE Owners

  !===========================================================================
  ! Runtime Context (???????)
  !===========================================================================
  TYPE, PUBLIC :: Ctx
    TYPE(Owners), POINTER :: owners => NULL()
  END TYPE Ctx

CONTAINS

  !---------------------------------------------------------------------------
  !> Owners_Init
  !---------------------------------------------------------------------------
  SUBROUTINE Owners_Init(this, numThreads)
    CLASS(Owners), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: numThreads

    ALLOCATE(this%workspaces(numThreads))
    this%workspaces%iter_preheated = .FALSE.
  END SUBROUTINE Owners_Init

  !---------------------------------------------------------------------------
  !> Owners_Final
  !---------------------------------------------------------------------------
  SUBROUTINE Owners_Final(this)
    TYPE(Owners), INTENT(INOUT) :: this
    INTEGER(i4) :: i

    IF (ALLOCATED(this%nodeStates)) DEALLOCATE(this%nodeStates)
    IF (ALLOCATED(this%elemStates)) DEALLOCATE(this%elemStates)

    IF (ALLOCATED(this%workspaces)) THEN
      DO i = 1, SIZE(this%workspaces)
        IF (ALLOCATED(this%workspaces(i)%solver_u)) DEALLOCATE(this%workspaces(i)%solver_u)
        IF (ALLOCATED(this%workspaces(i)%solver_du)) DEALLOCATE(this%workspaces(i)%solver_du)
        IF (ALLOCATED(this%workspaces(i)%solver_F_ext)) DEALLOCATE(this%workspaces(i)%solver_F_ext)
        IF (ALLOCATED(this%workspaces(i)%solver_R)) DEALLOCATE(this%workspaces(i)%solver_R)
        IF (ALLOCATED(this%workspaces(i)%pcg_r)) DEALLOCATE(this%workspaces(i)%pcg_r)
        IF (ALLOCATED(this%workspaces(i)%pcg_z)) DEALLOCATE(this%workspaces(i)%pcg_z)
        IF (ALLOCATED(this%workspaces(i)%pcg_p)) DEALLOCATE(this%workspaces(i)%pcg_p)
        IF (ALLOCATED(this%workspaces(i)%pcg_Ap)) DEALLOCATE(this%workspaces(i)%pcg_Ap)
        IF (ALLOCATED(this%workspaces(i)%iter_u_curr)) DEALLOCATE(this%workspaces(i)%iter_u_curr)
        IF (ALLOCATED(this%workspaces(i)%iter_du_corr)) DEALLOCATE(this%workspaces(i)%iter_du_corr)
        IF (ALLOCATED(this%workspaces(i)%iter_R_work)) DEALLOCATE(this%workspaces(i)%iter_R_work)
        IF (ALLOCATED(this%workspaces(i)%iter_u_prev)) DEALLOCATE(this%workspaces(i)%iter_u_prev)
        IF (ALLOCATED(this%workspaces(i)%iter_F_int)) DEALLOCATE(this%workspaces(i)%iter_F_int)
      END DO
      DEALLOCATE(this%workspaces)
    END IF
  END SUBROUTINE Owners_Final

END MODULE RT_Step_WS