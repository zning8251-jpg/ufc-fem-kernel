!===============================================================================
! Module: RT_Assembly_Types                                      [Template v1.0]
! Layer:  L5_RT — Runtime Layer
! Domain: Assembly — Global matrix/vector assembly types
!
! Purpose:
!   Defines types for global stiffness/mass/damping matrix assembly
!   and residual vector computation. Supports element-by-element 
!   assembly with constraint application.
!
! Type catalogue (4 TYPEs):
!   RT_Asm_Desc   – Assembly configuration (element ranges, constraints)
!   RT_Asm_State  – Assembly progress and matrix status
!   RT_Asm_Algo   – Assembly strategy (sparse format, parallel method)
!   RT_Asm_Ctx    – Element-level temporary buffers (no allocation)
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!   USE IF_Err_Brg (ErrorStatusType, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE RT_Assembly_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Asm_Desc
  PUBLIC :: RT_Asm_State
  PUBLIC :: RT_Asm_Algo
  PUBLIC :: RT_Asm_Ctx
  
  !-- Assembly type flags
  LOGICAL, PARAMETER, PUBLIC :: ASM_MASS      = .TRUE.
  LOGICAL, PARAMETER, PUBLIC :: ASM_DAMPING   = .TRUE.
  LOGICAL, PARAMETER, PUBLIC :: ASM_STIFFNESS = .TRUE.
  LOGICAL, PARAMETER, PUBLIC :: ASM_LOADS     = .TRUE.
  
  !-- Assembly method constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_METHOD_DIRECT       = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_METHOD_ELEMENT_WISE = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_METHOD_DOMAIN_DECOMP = 2_i4  ! migrated
  
  !-- Sparse storage format constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_SPARSE_DENSE = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_SPARSE_CSR   = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_SPARSE_CSC   = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_SPARSE_SKYLINE = 3_i4  ! migrated
  
  !-- Parallel strategy constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_PARALLEL_SERIAL  = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_PARALLEL_OMP     = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ASM_PARALLEL_MPI     = 2_i4  ! migrated
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_Desc — Assembly configuration (cold, read-only)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Asm_Desc
    !-- Assembly type flags
    LOGICAL     :: assemble_mass = .FALSE.
    LOGICAL     :: assemble_damping = .FALSE.
    LOGICAL     :: assemble_stiffness = .TRUE.
    LOGICAL     :: assemble_loads = .TRUE.
    
    !-- Assembly range
    INTEGER(i4) :: elem_start = 1
    INTEGER(i4) :: elem_end = 0
    INTEGER(i4) :: node_start = 1
    INTEGER(i4) :: node_end = 0
    
    !-- Constraint information
    INTEGER(i4), POINTER :: constrained_dofs(:) => NULL()
    INTEGER(i4), POINTER :: constraint_types(:) => NULL()  ! 1=Fixed/2=Prescribed/3=Symmetric
    REAL(wp), POINTER    :: constraint_values(:) => NULL()
    
    !-- Matrix properties
    LOGICAL     :: is_symmetric = .TRUE.
    LOGICAL     :: is_positive_definite = .TRUE.
  END TYPE RT_Asm_Desc
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_State — Assembly state (warm, frequent updates)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Asm_State
    !-- Assembly progress
    INTEGER(i4) :: current_elem = 0
    INTEGER(i4) :: assembled_elements = 0
    INTEGER(i4) :: total_elements = 0
    REAL(wp)    :: assembly_fraction = 0.0_wp
    
    !-- Matrix/vector status
    REAL(wp)    :: K_matrix_norm = 0.0_wp
    REAL(wp)    :: M_matrix_norm = 0.0_wp
    REAL(wp)    :: f_vector_norm = 0.0_wp
    REAL(wp)    :: assembly_time = 0.0_wp
    
    !-- Statistics
    INTEGER(i4) :: n_nonzero_entries = 0
    INTEGER(i4) :: n_constraints_applied = 0
    INTEGER(i4) :: n_assembled_dofs = 0
    
    !-- Global matrix pointers (reference to memory pool)
    REAL(wp), POINTER :: K_global(:,:) => NULL()
    REAL(wp), POINTER :: M_global(:,:) => NULL()
    REAL(wp), POINTER :: C_global(:,:) => NULL()
    REAL(wp), POINTER :: f_global(:) => NULL()
  END TYPE RT_Asm_State
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_Algo — Assembly algorithm (optional, cold)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Asm_Algo
    !-- Assembly strategy
    INTEGER(i4) :: assembly_method = RT_ASM_ASM_METHOD_ELEMENT_WISE
    
    !-- Sparse storage format
    INTEGER(i4) :: sparse_format = ASM_SPARSE_CSR
    
    !-- Parallel strategy
    INTEGER(i4) :: parallel_strategy = ASM_PARALLEL_SERIAL
    INTEGER(i4) :: n_threads = 1_i4
    
    !-- Numerical integration
    INTEGER(i4) :: integration_order = 2  ! 2=2x2x2 Gauss points for C3D8
    
    !-- Scaling options
    LOGICAL     :: use_scaling = .FALSE.
    REAL(wp)    :: mass_scaling_factor = 1.0_wp
    REAL(wp)    :: stiffness_scaling_factor = 1.0_wp
  END TYPE RT_Asm_Algo
  
  !-----------------------------------------------------------------------------
  ! RT_Asm_Ctx — Hot path context (temporary, no dynamic allocation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Asm_Ctx
    !-- Element-level temporaries (stack space, C3D8 example)
    REAL(wp)    :: elem_ke(24,24)    ! Element stiffness
    REAL(wp)    :: elem_me(24,24)    ! Element mass
    REAL(wp)    :: elem_ce(24,24)    ! Element damping
    REAL(wp)    :: elem_fe(24)       ! Element force vector
    
    !-- Integration point temporaries
    REAL(wp)    :: gp_coords(3,8)    ! Gauss point coordinates
    REAL(wp)    :: gp_weights(8)     ! Gauss point weights
    REAL(wp)    :: shape_funcs(8)    ! Shape function values N_i
    REAL(wp)    :: dndx(3,8)         ! Shape function derivatives dN/dx
    
    !-- Jacobian at integration points
    REAL(wp)    :: jacobian(3,3)
    REAL(wp)    :: det_jacobian = 0.0_wp
    REAL(wp)    :: inv_jacobian(3,3)
    
    !-- Local indexing
    INTEGER(i4) :: elem_node_ids(8)  ! Element node numbers
    INTEGER(i4) :: elem_dof_map(24)  ! Element DOF mapping (8 nodes * 3 DOF)
    
    !-- Work pointers (pre-allocated, 禁止 ALLOCATABLE)
    REAL(wp), POINTER :: temp_array1(:) => NULL()
    REAL(wp), POINTER :: temp_array2(:) => NULL()
    
    !-- Material state pointers (reference to L4_PH)
    REAL(wp), POINTER :: stress_gp(:,:,:) => NULL()  ! (n_gp, 6 components)
    REAL(wp), POINTER :: strain_gp(:,:,:) => NULL()
  END TYPE RT_Asm_Ctx
  
  !-----------------------------------------------------------------------------
  ! Standalone procedures for RT_Asm_Desc manipulation (cold path)
  !-----------------------------------------------------------------------------
  PUBLIC :: RT_Asm_Desc_Init
  PUBLIC :: RT_Asm_Desc_SetRange
  PUBLIC :: RT_Asm_Desc_AddConstraint
  PUBLIC :: RT_Asm_Desc_Finalize
  
CONTAINS
  
  SUBROUTINE RT_Asm_Desc_Init(desc, st)
    TYPE(RT_Asm_Desc), INTENT(OUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! Initialize descriptor with default values
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Desc_Init
  
  SUBROUTINE RT_Asm_Desc_SetRange(desc, elem_start, elem_end, node_start, node_end, st)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: elem_start, elem_end, node_start, node_end
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    desc%elem_start = elem_start
    desc%elem_end = elem_end
    desc%node_start = node_start
    desc%node_end = node_end
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Desc_SetRange
  
  SUBROUTINE RT_Asm_Desc_AddConstraint(desc, dof_id, constr_type, value, st)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: dof_id
    INTEGER(i4), INTENT(IN) :: constr_type
    REAL(wp), INTENT(IN) :: value
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! TODO: implement constraint addition logic
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Desc_AddConstraint
  
  SUBROUTINE RT_Asm_Desc_Finalize(desc, st)
    TYPE(RT_Asm_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! Mark descriptor as ready for assembly
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_Desc_Finalize
  
END MODULE RT_Assembly_Types
