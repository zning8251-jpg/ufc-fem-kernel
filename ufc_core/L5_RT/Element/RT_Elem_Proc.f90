!===============================================================================
! MODULE: RT_Elem_Proc
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Proc — Abstract interfaces + I/O structures for element operations
! BRIEF:  SIO six-parameter signatures that L4_PH implements.  SKELETON.
!         Future unified element kernel registry (function-pointer table).
!         Production routing uses RT_ElemDispatcher.
! **W2**：**SIO** 接口骨架与 **`RT_Elem_*`** 四型 IO；生产路由以 **`RT_Elem_Dispatcher`** → **`PH_Elem_*`** 为准。
!===============================================================================
MODULE RT_Elem_Proc
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Elem_Def,  ONLY: PH_Elem_Ctx
  USE RT_Elem_Def,  ONLY: RT_Elem_Desc, RT_Elem_State, RT_Elem_Algo, RT_Elem_Ctx
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! SIO Specification: Abstract Interfaces (Two-parameter signature)
  ! Refactored: 2026-04-17 (P3任务2) - Aligned with P2 TYPE精简
  !---------------------------------------------------------------------------
  ! Init Interface
  ABSTRACT INTERFACE
    SUBROUTINE Elem_Init_Interface(state, ctx, inp, out)
      IMPORT :: RT_Elem_State, RT_Elem_Ctx, Elem_Init_In, Elem_Init_Out
      TYPE(RT_Elem_State),   INTENT(INOUT) :: state
      TYPE(RT_Elem_Ctx),     INTENT(INOUT) :: ctx
      TYPE(Elem_Init_In),     INTENT(IN)    :: inp
      TYPE(Elem_Init_Out),   INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE

  ! ComputeKe Interface
  ABSTRACT INTERFACE
    SUBROUTINE Elem_ComputeKe_Interface(state, ctx, inp, out)
      IMPORT :: RT_Elem_State, RT_Elem_Ctx, Elem_Ke_In, Elem_Ke_Out
      TYPE(RT_Elem_State),   INTENT(INOUT) :: state
      TYPE(RT_Elem_Ctx),     INTENT(INOUT) :: ctx
      TYPE(Elem_Ke_In),      INTENT(IN)    :: inp
      TYPE(Elem_Ke_Out),     INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE

  ! ComputeFe Interface
  ABSTRACT INTERFACE
    SUBROUTINE Elem_ComputeFe_Interface(state, ctx, inp, out)
      IMPORT :: RT_Elem_State, RT_Elem_Ctx, Elem_Fe_In, Elem_Fe_Out
      TYPE(RT_Elem_State),   INTENT(INOUT) :: state
      TYPE(RT_Elem_Ctx),     INTENT(INOUT) :: ctx
      TYPE(Elem_Fe_In),      INTENT(IN)    :: inp
      TYPE(Elem_Fe_Out),     INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE

  ! ComputeMe Interface
  ABSTRACT INTERFACE
    SUBROUTINE Elem_ComputeMe_Interface(state, ctx, inp, out)
      IMPORT :: RT_Elem_State, RT_Elem_Ctx, Elem_Me_In, Elem_Me_Out
      TYPE(RT_Elem_State),   INTENT(INOUT) :: state
      TYPE(RT_Elem_Ctx),     INTENT(INOUT) :: ctx
      TYPE(Elem_Me_In),      INTENT(IN)    :: inp
      TYPE(Elem_Me_Out),     INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE

  ! ComputeCe Interface
  ABSTRACT INTERFACE
    SUBROUTINE Elem_ComputeCe_Interface(state, ctx, inp, out)
      IMPORT :: RT_Elem_State, RT_Elem_Ctx, Elem_Ce_In, Elem_Ce_Out
      TYPE(RT_Elem_State),   INTENT(INOUT) :: state
      TYPE(RT_Elem_Ctx),     INTENT(INOUT) :: ctx
      TYPE(Elem_Ce_In),      INTENT(IN)    :: inp
      TYPE(Elem_Ce_Out),     INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE

  ! CollectOutput Interface
  ABSTRACT INTERFACE
    SUBROUTINE Elem_CollectOutput_Interface(state, ctx, inp, out)
      IMPORT :: RT_Elem_State, RT_Elem_Ctx, Elem_Out_In, Elem_Out_Out
      TYPE(RT_Elem_State),   INTENT(INOUT) :: state
      TYPE(RT_Elem_Ctx),     INTENT(INOUT) :: ctx
      TYPE(Elem_Out_In),     INTENT(IN)    :: inp
      TYPE(Elem_Out_Out),    INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE

  ! Finalize Interface
  ABSTRACT INTERFACE
    SUBROUTINE Elem_Finalize_Interface(state, ctx, inp, out)
      IMPORT :: RT_Elem_State, RT_Elem_Ctx, Elem_Init_In, Elem_Init_Out
      TYPE(RT_Elem_State),   INTENT(INOUT) :: state
      TYPE(RT_Elem_Ctx),     INTENT(INOUT) :: ctx
      TYPE(Elem_Init_In),    INTENT(IN)    :: inp
      TYPE(Elem_Init_Out),   INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE

  !---------------------------------------------------------------------------
  ! Operation Input/Output Structures (SIO Specification)
  !---------------------------------------------------------------------------

  ! Init_In: Initialization input
  TYPE, PUBLIC :: Elem_Init_In
    INTEGER(i4) :: elem_type_id = 0      ! Element type ID
    INTEGER(i4) :: sect_id = 0           ! Section ID
    INTEGER(i4) :: mat_id = 0            ! Material ID
  END TYPE Elem_Init_In

  ! Init_Out: Initialization output (with state)
  TYPE, PUBLIC :: Elem_Init_Out
    TYPE(RT_Elem_Desc) :: desc
    TYPE(RT_Elem_Ctx) :: ctx
    TYPE(RT_Elem_State) :: state
    TYPE(RT_Elem_Algo) :: algo
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Init_Out

  ! ComputeKe_In: Stiffness calculation input
  TYPE, PUBLIC :: Elem_Ke_In
    REAL(wp), POINTER :: coords(:,:) => NULL()    ! [ndim, n_nodes]
    REAL(wp), POINTER :: u(:) => NULL()            ! [n_dof] displacement
    REAL(wp), POINTER :: du(:) => NULL()           ! [n_dof] displacement increment
  END TYPE Elem_Ke_In

  ! ComputeKe_Out: Stiffness calculation output
  TYPE, PUBLIC :: Elem_Ke_Out
    REAL(wp), ALLOCATABLE :: Ke(:,:)    ! [n_dof, n_dof]
    REAL(wp), ALLOCATABLE :: Fe(:)      ! [n_dof] residual
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Ke_Out

  ! ComputeFe_In: Load calculation input
  TYPE, PUBLIC :: Elem_Fe_In
    REAL(wp), POINTER :: coords(:,:) => NULL()
    REAL(wp), POINTER :: u(:) => NULL()
    INTEGER(i4) :: load_case = 0        ! Load case
  END TYPE Elem_Fe_In

  ! ComputeFe_Out: Load calculation output
  TYPE, PUBLIC :: Elem_Fe_Out
    REAL(wp), ALLOCATABLE :: Fe(:)    ! [n_dof]
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Fe_Out

  ! ComputeMe_In: Mass matrix input
  TYPE, PUBLIC :: Elem_Me_In
    REAL(wp), POINTER :: coords(:,:) => NULL()
    REAL(wp) :: mass_density = 0.0_wp   ! Mass density
  END TYPE Elem_Me_In

  ! ComputeMe_Out: Mass matrix output
  TYPE, PUBLIC :: Elem_Me_Out
    REAL(wp), ALLOCATABLE :: Me(:,:)    ! [n_dof, n_dof]
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Me_Out

  ! ComputeCe_In: Damping matrix input
  TYPE, PUBLIC :: Elem_Ce_In
    REAL(wp), POINTER :: coords(:,:) => NULL()
    REAL(wp) :: damping_alpha = 0.0_wp  ! Rayleigh alpha
    REAL(wp) :: damping_beta = 0.0_wp   ! Rayleigh beta
  END TYPE Elem_Ce_In

  ! ComputeCe_Out: Damping matrix output
  TYPE, PUBLIC :: Elem_Ce_Out
    REAL(wp), ALLOCATABLE :: Ce(:,:)    ! [n_dof, n_dof]
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Ce_Out

  ! CollectOutput_In: Output collection input
  TYPE, PUBLIC :: Elem_Out_In
    INTEGER(i4) :: ip_mask = 0          ! Integration point mask
    INTEGER(i4) :: node_mask = 0        ! Node mask
  END TYPE Elem_Out_In

  ! CollectOutput_Out: Output collection output
  TYPE, PUBLIC :: Elem_Out_Out
    REAL(wp), ALLOCATABLE :: svars(:)   ! State variables
    REAL(wp) :: energy(8) = 0.0_wp      ! Energy
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Out_Out

  !---------------------------------------------------------------------------
  ! PUBLIC: Abstract Interfaces (Exported for L4_PH implementation)
  !---------------------------------------------------------------------------
  PUBLIC :: Elem_Init_Interface
  PUBLIC :: Elem_ComputeKe_Interface
  PUBLIC :: Elem_ComputeFe_Interface
  PUBLIC :: Elem_ComputeMe_Interface
  PUBLIC :: Elem_ComputeCe_Interface
  PUBLIC :: Elem_CollectOutput_Interface
  PUBLIC :: Elem_Finalize_Interface

  ! Note: All implementations delegated to L4_PH/*_Proc.f90
  ! L5_RT only defines interface contracts (thin adapter pattern)

END MODULE RT_Elem_Proc