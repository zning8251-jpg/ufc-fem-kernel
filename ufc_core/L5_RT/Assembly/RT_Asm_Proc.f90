!===============================================================================
! MODULE: RT_Asm_Proc
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Proc
! BRIEF:  Time-phase orchestration -- structured IO interfaces for assembly ops
!===============================================================================
!
! Interface list:
!   RT_Asm_Init             - Initialize assembly domain          [P0]
!   RT_Asm_BuildPattern     - Build sparsity pattern              [P1]
!   RT_Asm_AssembleK        - Assemble global stiffness           [P2]
!   RT_Asm_AssembleM        - Assemble global mass                [P2]
!   RT_Asm_AssembleF        - Assemble global force               [P2]
!   RT_Asm_ApplyConstraints - Apply boundary constraints          [P2]
!   RT_Asm_ComputeResidual  - Compute residual vector             [P2]
!   RT_Asm_Finalize         - Finalize and cleanup                [P0]
!
! Layer dependency:
!   USE IF_Prec_Core (wp, i4)
!   USE IF_Err_Brg   (ErrorStatusType)
!   USE RT_Asm_Def
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Asm_Proc
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE RT_Asm_Def
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Asm_Init
  PUBLIC :: RT_Asm_BuildPattern
  PUBLIC :: RT_Asm_AssembleK
  PUBLIC :: RT_Asm_AssembleM
  PUBLIC :: RT_Asm_AssembleF
  PUBLIC :: RT_Asm_ApplyConstraints
  PUBLIC :: RT_Asm_ComputeResidual
  PUBLIC :: RT_Asm_Finalize
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_Init  (_In / _Out IO types)
  !-----------------------------------------------------------------------------
  TYPE :: RT_Asm_Init_In
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_dofs_per_node = 3_i4
    LOGICAL     :: assemble_K = .TRUE.
    LOGICAL     :: assemble_M = .FALSE.
    LOGICAL     :: assemble_C = .FALSE.
    LOGICAL     :: assemble_f = .TRUE.
  END TYPE RT_Asm_Init_In
  
  TYPE :: RT_Asm_Init_Out
    TYPE(ErrorStatusType) :: status
    LOGICAL     :: initialized = .FALSE.
  END TYPE RT_Asm_Init_Out
  
  INTERFACE RT_Asm_Init
    MODULE PROCEDURE RT_Asm_Init
  END INTERFACE
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_BuildPattern  (_In / _Out IO types)
  !-----------------------------------------------------------------------------
  TYPE :: RT_Asm_BuildPattern_In
    INTEGER(i4) :: nEq = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    INTEGER(i4) :: renum_method = 1_i4  ! RCM default
  END TYPE RT_Asm_BuildPattern_In
  
  TYPE :: RT_Asm_BuildPattern_Out
    TYPE(ErrorStatusType) :: status
    LOGICAL     :: pattern_built = .FALSE.
  END TYPE RT_Asm_BuildPattern_Out
  
  INTERFACE RT_Asm_BuildPattern
    MODULE PROCEDURE RT_Asm_BuildPattern
  END INTERFACE
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleK  (_In / _Out IO types)
  !-----------------------------------------------------------------------------
  TYPE :: RT_Asm_AssembleK_In
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp), POINTER :: Ke(:,:) => NULL()
    INTEGER(i4), POINTER :: dof_map(:) => NULL()
    LOGICAL     :: use_scaling = .FALSE.
    REAL(wp)    :: scale_factor = 1.0_wp
  END TYPE RT_Asm_AssembleK_In
  
  TYPE :: RT_Asm_AssembleK_Out
    TYPE(ErrorStatusType) :: status
    REAL(wp)    :: K_norm = 0.0_wp
    LOGICAL     :: assembly_complete = .FALSE.
  END TYPE RT_Asm_AssembleK_Out
  
  INTERFACE RT_Asm_AssembleK
    MODULE PROCEDURE RT_Asm_AssembleK
  END INTERFACE
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleM  (_In / _Out IO types)
  !-----------------------------------------------------------------------------
  TYPE :: RT_Asm_AssembleM_In
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp), POINTER :: Me(:,:) => NULL()
    INTEGER(i4), POINTER :: dof_map(:) => NULL()
    LOGICAL     :: consistent = .TRUE.  ! .T.=consistent, .F.=lumped
  END TYPE RT_Asm_AssembleM_In
  
  TYPE :: RT_Asm_AssembleM_Out
    TYPE(ErrorStatusType) :: status
    REAL(wp)    :: M_norm = 0.0_wp
    LOGICAL     :: assembly_complete = .FALSE.
  END TYPE RT_Asm_AssembleM_Out
  
  INTERFACE RT_Asm_AssembleM
    MODULE PROCEDURE RT_Asm_AssembleM
  END INTERFACE
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_AssembleF  (_In / _Out IO types)
  !-----------------------------------------------------------------------------
  TYPE :: RT_Asm_AssembleF_In
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp), POINTER :: Fe(:) => NULL()
    INTEGER(i4), POINTER :: dof_map(:) => NULL()
    LOGICAL     :: is_internal = .FALSE.  ! .T.=internal force, .F.=external
  END TYPE RT_Asm_AssembleF_In
  
  TYPE :: RT_Asm_AssembleF_Out
    TYPE(ErrorStatusType) :: status
    REAL(wp)    :: f_norm = 0.0_wp
    LOGICAL     :: assembly_complete = .FALSE.
  END TYPE RT_Asm_AssembleF_Out
  
  INTERFACE RT_Asm_AssembleF
    MODULE PROCEDURE RT_Asm_AssembleF
  END INTERFACE
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_ApplyConstraints  (_In / _Out IO types)
  !-----------------------------------------------------------------------------
  TYPE :: RT_Asm_ApplyConstraints_In
    INTEGER(i4), POINTER :: dof_indices(:) => NULL()
    INTEGER(i4), POINTER :: constraint_types(:) => NULL()
    REAL(wp), POINTER    :: constraint_values(:) => NULL()
    INTEGER(i4) :: n_constraints = 0_i4
  END TYPE RT_Asm_ApplyConstraints_In
  
  TYPE :: RT_Asm_ApplyConstraints_Out
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: n_applied = 0_i4
    LOGICAL     :: constraints_applied = .FALSE.
  END TYPE RT_Asm_ApplyConstraints_Out
  
  INTERFACE RT_Asm_ApplyConstraints
    MODULE PROCEDURE RT_Asm_ApplyConstraints
  END INTERFACE
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_ComputeResidual  (_In / _Out IO types)
  !-----------------------------------------------------------------------------
  TYPE :: RT_Asm_ComputeResidual_In
    REAL(wp), POINTER :: f_external(:) => NULL()
    REAL(wp), POINTER :: f_internal(:) => NULL()
    LOGICAL     :: use_norm = .TRUE.
  END TYPE RT_Asm_ComputeResidual_In
  
  TYPE :: RT_Asm_ComputeResidual_Out
    TYPE(ErrorStatusType) :: status
    REAL(wp)    :: res_norm = 0.0_wp
    REAL(wp), ALLOCATABLE :: residual(:)
    LOGICAL     :: converged = .FALSE.
  END TYPE RT_Asm_ComputeResidual_Out
  
  INTERFACE RT_Asm_ComputeResidual
    MODULE PROCEDURE RT_Asm_ComputeResidual
  END INTERFACE
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_Finalize  (_In / _Out IO types)
  !-----------------------------------------------------------------------------
  TYPE :: RT_Asm_Finalize_In
    LOGICAL     :: keep_pattern = .FALSE.
  END TYPE RT_Asm_Finalize_In
  
  TYPE :: RT_Asm_Finalize_Out
    TYPE(ErrorStatusType) :: status
    LOGICAL     :: finalized = .FALSE.
  END TYPE RT_Asm_Finalize_Out
  
  INTERFACE RT_Asm_Finalize
    MODULE PROCEDURE RT_Asm_Finalize
  END INTERFACE
  
CONTAINS

  !=============================================================================
  ! Implementation stubs (TODO: Route to L3_MD or L4_PH)
  !=============================================================================
  
  SUBROUTINE RT_Asm_Init(desc, state, algo, ctx, inp, out)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Asm_Init_In), INTENT(IN) :: inp
    TYPE(RT_Asm_Init_Out), INTENT(OUT) :: out
    
    ! TODO: Call MD_Asm_Init or L4 initialization routine
    out%initialized = .TRUE.
  END SUBROUTINE RT_Asm_Init
  
  SUBROUTINE RT_Asm_BuildPattern(desc, state, algo, ctx, inp, out)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Asm_BuildPattern_In), INTENT(IN) :: inp
    TYPE(RT_Asm_BuildPattern_Out), INTENT(OUT) :: out
    
    ! TODO: Call MD_Asm_BuildPattern
    state%n_nonzero_entries = inp%nnz
    state%n_assembled_dofs = inp%nEq
    out%pattern_built = .TRUE.
  END SUBROUTINE RT_Asm_BuildPattern
  
  SUBROUTINE RT_Asm_AssembleK(desc, state, algo, ctx, inp, out)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Asm_AssembleK_In), INTENT(IN) :: inp
    TYPE(RT_Asm_AssembleK_Out), INTENT(OUT) :: out
    
    ! TODO: Call L4_PH element stiffness computation and assemble
    ! TODO: Route to PH_Elem_Stiffness then scatter to global
    CALL state%UpdateProgress(inp%elem_id)
    out%assembly_complete = .TRUE.
  END SUBROUTINE RT_Asm_AssembleK
  
  SUBROUTINE RT_Asm_AssembleM(desc, state, algo, ctx, inp, out)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Asm_AssembleM_In), INTENT(IN) :: inp
    TYPE(RT_Asm_AssembleM_Out), INTENT(OUT) :: out
    
    ! TODO: Call L4_PH element mass computation
    CALL state%UpdateProgress(inp%elem_id)
    out%assembly_complete = .TRUE.
  END SUBROUTINE RT_Asm_AssembleM
  
  SUBROUTINE RT_Asm_AssembleF(desc, state, algo, ctx, inp, out)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Asm_AssembleF_In), INTENT(IN) :: inp
    TYPE(RT_Asm_AssembleF_Out), INTENT(OUT) :: out
    
    ! TODO: Call L4_PH element force computation
    CALL state%UpdateProgress(inp%elem_id)
    out%assembly_complete = .TRUE.
  END SUBROUTINE RT_Asm_AssembleF
  
  SUBROUTINE RT_Asm_ApplyConstraints(desc, state, algo, ctx, inp, out)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Asm_ApplyConstraints_In), INTENT(IN) :: inp
    TYPE(RT_Asm_ApplyConstraints_Out), INTENT(OUT) :: out
    
    ! TODO: Call MD_Constraint or L3 constraint application
    out%n_applied = inp%n_constraints
    out%constraints_applied = .TRUE.
  END SUBROUTINE RT_Asm_ApplyConstraints
  
  SUBROUTINE RT_Asm_ComputeResidual(desc, state, algo, ctx, inp, out)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Asm_ComputeResidual_In), INTENT(IN) :: inp
    TYPE(RT_Asm_ComputeResidual_Out), INTENT(OUT) :: out
    
    ! TODO: Compute residual r = f_ext - f_int
    ! TODO: Call L4_PH for internal force computation if needed
    IF (ALLOCATED(out%residual)) THEN
      out%res_norm = SQRT(SUM(out%residual**2))
    END IF
  END SUBROUTINE RT_Asm_ComputeResidual
  
  SUBROUTINE RT_Asm_Finalize(desc, state, algo, ctx, inp, out)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(RT_Asm_State), INTENT(INOUT) :: state
    TYPE(RT_Asm_Algo), INTENT(INOUT) :: algo
    TYPE(RT_Asm_Ctx), INTENT(INOUT) :: ctx
    TYPE(RT_Asm_Finalize_In), INTENT(IN) :: inp
    TYPE(RT_Asm_Finalize_Out), INTENT(OUT) :: out
    
    ! TODO: Call cleanup routines
    CALL state%Reset()
    out%finalized = .TRUE.
  END SUBROUTINE RT_Asm_Finalize
  
END MODULE RT_Asm_Proc