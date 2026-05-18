!===============================================================================
! MODULE:  MD_Asm_Mgr
! LAYER:   L3_MD
! DOMAIN:  Assembly
! ROLE:    _Mgr
! BRIEF:   Assembly domain container + Register/Query/Get TBP + Idx API.
!          Unified container for instances, sets, surfaces, constraints.
! Pilot:   ufc-layer-l3-l4-l5-pilot.md — L3 冷数据；**MD_Assembly_Domain** 已嵌
!          **algo / state / ctx**；实例/集合/面等保持**扁平可增长数组**（双规范之
!          「域存储」侧）。Idx API 走 **g_ufc_global%md_layer%assembly** 金线读。
!===============================================================================

MODULE MD_Asm_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_MEM_ERROR
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE IF_Base_SymTbl, ONLY: register_variable, symbol_table_exists, &
                            IF_STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_STRUCT
  USE MD_Constr_Def, ONLY: CONSTRAINT_TIE, CONSTRAINT_MPC, &
                                 CONSTRAINT_COUPLING, CONSTRAINT_RIGID, &
                                 TieConstraintDef, MPCConstraintDef, &
                                 CplConstraintDef, RigidBodyDef, &
                                 MD_ConstraintUnion
  USE MD_Int_Def, ONLY: MD_InteractionUnion, MD_ContactPairDef
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Constraint type enumerations (re-exported from MD_Constr_Def)
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_RBE2 = CONSTRAINT_RIGID
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_RBE3 = CONSTRAINT_RIGID

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Instance_Desc
  ! KIND:  Desc
  ! DESC:  Instance descriptor — part reference + rigid transform
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Instance_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: inst_id    = 0_i4
    INTEGER(i4)       :: part_ref   = 0_i4
    REAL(wp)          :: translation(3) = (/ 0.0_wp, 0.0_wp, 0.0_wp /)
    REAL(wp)          :: rotation(3,3)  = RESHAPE( &
      (/ 1.0_wp,0.0_wp,0.0_wp, 0.0_wp,1.0_wp,0.0_wp, 0.0_wp,0.0_wp,1.0_wp /), &
      (/ 3, 3 /) )
    LOGICAL           :: dependent  = .FALSE.
  END TYPE MD_Instance_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_SetDef
  ! KIND:  Desc
  ! DESC:  Node/element set descriptor — name + member IDs
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_SetDef
    CHARACTER(LEN=64)          :: name    = ""
    INTEGER(i4)                :: set_id  = 0_i4
    INTEGER(i4), ALLOCATABLE   :: members(:)
    INTEGER(i4)                :: n_members = 0_i4
    LOGICAL                    :: is_internal = .FALSE.
  END TYPE MD_SetDef


  !---------------------------------------------------------------------------
  ! TYPE:  MD_SurfaceDef
  ! KIND:  Desc
  ! DESC:  Surface descriptor — element-face pairs
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_SurfaceDef
    CHARACTER(LEN=64)          :: name      = ""
    INTEGER(i4)                :: surf_id   = 0_i4
    INTEGER(i4), ALLOCATABLE   :: elem_ids(:)
    INTEGER(i4), ALLOCATABLE   :: face_ids(:)
    INTEGER(i4)                :: n_faces   = 0_i4
  END TYPE MD_SurfaceDef

  !---------------------------------------------------------------------------
  ! Arg bundles (KIND: Arg)
  !---------------------------------------------------------------------------

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Asm_GetSummary_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for assembly summary retrieval
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Asm_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Asm_GetSummary_Arg

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Asm_GetInstance_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for instance retrieval by index
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Asm_GetInstance_Arg
    TYPE(MD_Instance_Desc) :: desc
  END TYPE MD_Asm_GetInstance_Arg
  !---------------------------------------------------------------------------
  ! TYPE:  MD_Asm_GetNodeSet_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for node-set retrieval by index
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Asm_GetNodeSet_Arg
    TYPE(MD_SetDef) :: def
  END TYPE MD_Asm_GetNodeSet_Arg
  !---------------------------------------------------------------------------
  ! TYPE:  MD_Asm_GetElemSet_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for element-set retrieval by index
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Asm_GetElemSet_Arg
    TYPE(MD_SetDef) :: def
  END TYPE MD_Asm_GetElemSet_Arg
  !---------------------------------------------------------------------------
  ! TYPE:  MD_Asm_GetSurface_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for surface retrieval by index
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Asm_GetSurface_Arg
    TYPE(MD_SurfaceDef) :: def
  END TYPE MD_Asm_GetSurface_Arg

  TYPE, PUBLIC :: MD_Asm_GetSurfaceByName_Arg
    TYPE(MD_SurfaceDef) :: def
    LOGICAL :: found = .FALSE.
  END TYPE MD_Asm_GetSurfaceByName_Arg
  TYPE, PUBLIC :: MD_Asm_GetNodeSetByName_Arg
    TYPE(MD_SetDef) :: def
    LOGICAL :: found = .FALSE.
  END TYPE MD_Asm_GetNodeSetByName_Arg
  TYPE, PUBLIC :: MD_Asm_GetElemSetByName_Arg
    TYPE(MD_SetDef) :: def
    LOGICAL :: found = .FALSE.
  END TYPE MD_Asm_GetElemSetByName_Arg

  ! Public interfaces
  PUBLIC :: MD_Assembly_GetInstance_Idx, MD_Assembly_GetNodeSet_Idx
  PUBLIC :: MD_Assembly_GetElemSet_Idx, MD_Assembly_GetSurface_Idx
  PUBLIC :: MD_Assembly_GetSurfaceByName_Idx, MD_Assembly_GetNodeSetByName_Idx
  PUBLIC :: MD_Assembly_GetElemSetByName_Idx

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Asm_Algo
  ! KIND:  Algo
  ! DESC:  Assembly algorithm parameters — tolerance / constraint config
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Asm_Algo
    REAL(wp)    :: default_tie_tolerance = 0.01_wp
    LOGICAL     :: auto_adjust           = .TRUE.
    INTEGER(i4) :: max_constraint_iters  = 100_i4
    LOGICAL     :: small_sliding_default = .FALSE.
    REAL(wp)    :: mpc_penalty_factor    = 1.0E+8_wp
    LOGICAL     :: rigid_auto_ref      = .TRUE.
  END TYPE MD_Asm_Algo

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Asm_State
  ! KIND:  State
  ! DESC:  Assembly runtime state — active counts / error tracking
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Asm_State
    INTEGER(i4) :: active_constraints    = 0_i4
    INTEGER(i4) :: active_contact_pairs  = 0_i4
    INTEGER(i4) :: total_constraint_violations = 0_i4
    REAL(wp)    :: max_constraint_error  = 0.0_wp
    LOGICAL     :: tie_satisfied         = .TRUE.
    LOGICAL     :: mpc_satisfied         = .TRUE.
    INTEGER(i4) :: failed_constraints    = 0_i4
  END TYPE MD_Asm_State

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Asm_Ctx
  ! KIND:  Ctx
  ! DESC:  Assembly transient context — current instance cache
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Asm_Ctx
    INTEGER(i4) :: current_inst_id = 0_i4
    LOGICAL     :: transform_cached = .FALSE.
    REAL(wp)    :: cached_translation(3) = (/ 0.0_wp, 0.0_wp, 0.0_wp /)
    REAL(wp)    :: cached_rotation(3,3)  = RESHAPE( &
      (/ 1.0_wp,0.0_wp,0.0_wp, 0.0_wp,1.0_wp,0.0_wp, 0.0_wp,0.0_wp,1.0_wp /), &
      (/ 3, 3 /) )
    INTEGER(i4) :: current_constraint_idx = 0_i4
    LOGICAL     :: constraint_cache_valid = .FALSE.
  END TYPE MD_Asm_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:  MD_ConstraintDef
  ! KIND:  Desc
  ! DESC:  Simplified constraint descriptor (TIE/MPC/Coupling/Rigid)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_ConstraintDef
    CHARACTER(LEN=64) :: name            = ""
    INTEGER(i4)       :: constraint_id   = 0_i4
    INTEGER(i4)       :: constraint_type = CONSTRAINT_TIE
    CHARACTER(LEN=64) :: master_surface  = ""
    CHARACTER(LEN=64) :: slave_surface   = ""
    REAL(wp)          :: tolerance       = 0.0_wp
    LOGICAL           :: adjust          = .TRUE.
  END TYPE MD_ConstraintDef

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Assembly_Domain
  ! KIND:  Desc
  ! DESC:  Assembly domain container — instances + sets + surfaces +
  !        constraints + Algo/State/Ctx aggregation
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Assembly_Domain
    TYPE(MD_Instance_Desc),   ALLOCATABLE :: instances(:)
    TYPE(MD_SetDef),          ALLOCATABLE :: node_sets(:)
    TYPE(MD_SetDef),          ALLOCATABLE :: elem_sets(:)
    TYPE(MD_SurfaceDef),      ALLOCATABLE :: surfaces(:)
    TYPE(MD_ConstraintDef),   ALLOCATABLE :: constraints(:)
    TYPE(MD_ConstraintUnion)              :: constraint_union
    TYPE(MD_InteractionUnion)             :: interaction_union

    INTEGER(i4) :: n_instances   = 0_i4
    INTEGER(i4) :: n_node_sets   = 0_i4
    INTEGER(i4) :: n_elem_sets   = 0_i4
    INTEGER(i4) :: n_surfaces    = 0_i4
    INTEGER(i4) :: n_constraints = 0_i4

    TYPE(MD_Asm_Algo) :: algo
    TYPE(MD_Asm_State) :: state
    TYPE(MD_Asm_Ctx) :: ctx
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddInstance
    PROCEDURE :: AddNodeSet
    PROCEDURE :: AddElemSet
    PROCEDURE :: AddSurface
    PROCEDURE :: AddConstraint
    PROCEDURE :: AddTie
    PROCEDURE :: AddMPC
    PROCEDURE :: AddCpl
    PROCEDURE :: AddRigid
    PROCEDURE :: GetInstance
    PROCEDURE :: GetNodeSet
    PROCEDURE :: GetNodeSetByName
    PROCEDURE :: GetElemSet
    PROCEDURE :: GetElemSetByName
    PROCEDURE :: GetSurface
    PROCEDURE :: GetSurfaceByName
    PROCEDURE :: GetConstraint
    PROCEDURE :: GetConstraintByName
    PROCEDURE :: GetTie
    PROCEDURE :: GetMPC
    PROCEDURE :: GetCpl
    PROCEDURE :: GetRigid
    PROCEDURE :: AddContactPair
    PROCEDURE :: GetContactPair
    PROCEDURE :: GetSummary
    PROCEDURE :: ReleaseConstraintUnion
    PROCEDURE :: ReleaseInteractionUnion
  END TYPE MD_Assembly_Domain

CONTAINS

  !--------------------------------------------------------------------
  ! Host readiness for flat Idx API and g_ufc_global delegates
  !--------------------------------------------------------------------
  LOGICAL FUNCTION md_assem_global_assembly_ready()
    IMPLICIT NONE
    md_assem_global_assembly_ready = g_ufc_global%md_layer%initialized .AND. &
      g_ufc_global%md_layer%assembly%initialized
  END FUNCTION md_assem_global_assembly_ready

  LOGICAL FUNCTION md_assem_global_constraint_ready()
    IMPLICIT NONE
    md_assem_global_constraint_ready = g_ufc_global%md_layer%initialized .AND. &
      g_ufc_global%md_layer%constraint%initialized
  END FUNCTION md_assem_global_constraint_ready

  LOGICAL FUNCTION md_assem_global_interaction_ready()
    IMPLICIT NONE
    md_assem_global_interaction_ready = g_ufc_global%md_layer%initialized .AND. &
      g_ufc_global%md_layer%interaction%initialized
  END FUNCTION md_assem_global_interaction_ready

  !> Flat Idx 入口：init + 金线 assembly 就绪（消重复子程序体）
  LOGICAL FUNCTION md_assem_begin_flat_idx(status) RESULT(ok)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. md_assem_global_assembly_ready()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 layer or assembly domain not initialized"
      ok = .FALSE.
    ELSE
      ok = .TRUE.
    END IF
  END FUNCTION md_assem_begin_flat_idx

  LOGICAL FUNCTION md_assem_require_constraint_domain(status) RESULT(ok)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    IF (.NOT. md_assem_global_constraint_ready()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 layer or constraint domain not initialized"
      ok = .FALSE.
    ELSE
      ok = .TRUE.
    END IF
  END FUNCTION md_assem_require_constraint_domain

  LOGICAL FUNCTION md_assem_require_interaction_domain(status) RESULT(ok)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    IF (.NOT. md_assem_global_interaction_ready()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 layer or interaction domain not initialized"
      ok = .FALSE.
    ELSE
      ok = .TRUE.
    END IF
  END FUNCTION md_assem_require_interaction_domain

  !====================================================================
  ! Add* procedures (basic types - no global dependency)
  !====================================================================
  SUBROUTINE AddConstraint(this, def, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(MD_ConstraintDef),    INTENT(IN)    :: def
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    TYPE(MD_ConstraintDef), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: astat

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    this%n_constraints = this%n_constraints + 1_i4
    IF (.NOT. ALLOCATED(this%constraints)) THEN
      ALLOCATE(this%constraints(16), stat=astat)
      IF (astat /= 0) THEN
        this%n_constraints = this%n_constraints - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddConstraint: initial ALLOCATE failed"
        RETURN
      END IF
    ELSE IF (this%n_constraints > SIZE(this%constraints)) THEN
      ALLOCATE(tmp(this%n_constraints * 2), stat=astat)
      IF (astat /= 0) THEN
        this%n_constraints = this%n_constraints - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddConstraint: grow ALLOCATE failed"
        RETURN
      END IF
      tmp(1:this%n_constraints-1) = this%constraints(1:this%n_constraints-1)
      CALL MOVE_ALLOC(tmp, this%constraints)
    END IF
    this%constraints(this%n_constraints) = def
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AddConstraint

  SUBROUTINE AddElemSet(this, def, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(MD_SetDef),           INTENT(IN)    :: def
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    TYPE(MD_SetDef), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: astat

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    this%n_elem_sets = this%n_elem_sets + 1_i4
    IF (.NOT. ALLOCATED(this%elem_sets)) THEN
      ALLOCATE(this%elem_sets(16), stat=astat)
      IF (astat /= 0) THEN
        this%n_elem_sets = this%n_elem_sets - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddElemSet: initial ALLOCATE failed"
        RETURN
      END IF
    ELSE IF (this%n_elem_sets > SIZE(this%elem_sets)) THEN
      ALLOCATE(tmp(this%n_elem_sets * 2), stat=astat)
      IF (astat /= 0) THEN
        this%n_elem_sets = this%n_elem_sets - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddElemSet: grow ALLOCATE failed"
        RETURN
      END IF
      tmp(1:this%n_elem_sets-1) = this%elem_sets(1:this%n_elem_sets-1)
      CALL MOVE_ALLOC(tmp, this%elem_sets)
    END IF
    this%elem_sets(this%n_elem_sets) = def

    ! SymTbl: register user-named element set for O(1) lookup
    IF (symbol_table_exists() .AND. LEN_TRIM(def%name) > 0) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80) :: sym_key, sym_val
        WRITE(sym_key, '(A,A)') "ELSET:", TRIM(def%name)
        WRITE(sym_val, '(I0)') this%n_elem_sets
        CALL register_variable(TRIM(sym_key), TRIM(sym_val), &
          IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, sym_st)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AddElemSet

  SUBROUTINE AddInstance(this, desc, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(MD_Instance_Desc),    INTENT(IN)    :: desc
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    TYPE(MD_Instance_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: astat

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    this%n_instances = this%n_instances + 1_i4
    IF (.NOT. ALLOCATED(this%instances)) THEN
      ALLOCATE(this%instances(16), stat=astat)
      IF (astat /= 0) THEN
        this%n_instances = this%n_instances - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddInstance: initial ALLOCATE failed"
        RETURN
      END IF
    ELSE IF (this%n_instances > SIZE(this%instances)) THEN
      ALLOCATE(tmp(this%n_instances * 2), stat=astat)
      IF (astat /= 0) THEN
        this%n_instances = this%n_instances - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddInstance: grow ALLOCATE failed"
        RETURN
      END IF
      tmp(1:this%n_instances-1) = this%instances(1:this%n_instances-1)
      CALL MOVE_ALLOC(tmp, this%instances)
    END IF
    this%instances(this%n_instances) = desc

    ! SymTbl: register user-named instance for O(1) lookup
    IF (symbol_table_exists() .AND. LEN_TRIM(desc%name) > 0) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80) :: sym_key, sym_val
        WRITE(sym_key, '(A,A)') "INST:", TRIM(desc%name)
        WRITE(sym_val, '(I0)') this%n_instances
        CALL register_variable(TRIM(sym_key), TRIM(sym_val), &
          IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, sym_st)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AddInstance

  SUBROUTINE AddNodeSet(this, def, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(MD_SetDef),           INTENT(IN)    :: def
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    TYPE(MD_SetDef), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: astat

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    this%n_node_sets = this%n_node_sets + 1_i4
    IF (.NOT. ALLOCATED(this%node_sets)) THEN
      ALLOCATE(this%node_sets(16), stat=astat)
      IF (astat /= 0) THEN
        this%n_node_sets = this%n_node_sets - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddNodeSet: initial ALLOCATE failed"
        RETURN
      END IF
    ELSE IF (this%n_node_sets > SIZE(this%node_sets)) THEN
      ALLOCATE(tmp(this%n_node_sets * 2), stat=astat)
      IF (astat /= 0) THEN
        this%n_node_sets = this%n_node_sets - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddNodeSet: grow ALLOCATE failed"
        RETURN
      END IF
      tmp(1:this%n_node_sets-1) = this%node_sets(1:this%n_node_sets-1)
      CALL MOVE_ALLOC(tmp, this%node_sets)
    END IF
    this%node_sets(this%n_node_sets) = def

    ! SymTbl: register user-named node set for O(1) lookup
    IF (symbol_table_exists() .AND. LEN_TRIM(def%name) > 0) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80) :: sym_key, sym_val
        WRITE(sym_key, '(A,A)') "NSET:", TRIM(def%name)
        WRITE(sym_val, '(I0)') this%n_node_sets
        CALL register_variable(TRIM(sym_key), TRIM(sym_val), &
          IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, sym_st)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AddNodeSet

  SUBROUTINE AddSurface(this, def, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(MD_SurfaceDef),       INTENT(IN)    :: def
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    TYPE(MD_SurfaceDef), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: astat

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    this%n_surfaces = this%n_surfaces + 1_i4
    IF (.NOT. ALLOCATED(this%surfaces)) THEN
      ALLOCATE(this%surfaces(16), stat=astat)
      IF (astat /= 0) THEN
        this%n_surfaces = this%n_surfaces - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddSurface: initial ALLOCATE failed"
        RETURN
      END IF
    ELSE IF (this%n_surfaces > SIZE(this%surfaces)) THEN
      ALLOCATE(tmp(this%n_surfaces * 2), stat=astat)
      IF (astat /= 0) THEN
        this%n_surfaces = this%n_surfaces - 1_i4
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "MD_Assembly_Domain_AddSurface: grow ALLOCATE failed"
        RETURN
      END IF
      tmp(1:this%n_surfaces-1) = this%surfaces(1:this%n_surfaces-1)
      CALL MOVE_ALLOC(tmp, this%surfaces)
    END IF
    this%surfaces(this%n_surfaces) = def

    ! SymTbl: register user-named surface for O(1) lookup
    IF (symbol_table_exists() .AND. LEN_TRIM(def%name) > 0) THEN
      BLOCK
        TYPE(ErrorStatusType) :: sym_st
        CHARACTER(LEN=80) :: sym_key, sym_val
        WRITE(sym_key, '(A,A)') "SURF:", TRIM(def%name)
        WRITE(sym_val, '(I0)') this%n_surfaces
        CALL register_variable(TRIM(sym_key), TRIM(sym_val), &
          IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, sym_st)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AddSurface

  !====================================================================
  ! Constraint Add* procedures (synchronize with global container)
  !====================================================================
  SUBROUTINE AddTie(this, tie_def, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(TieConstraintDef),    INTENT(IN)    :: tie_def
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_constraint_domain(status)) RETURN

    ! Synchronize with global constraint domain
    CALL g_ufc_global%md_layer%constraint%AddTie(tie_def, status)

  END SUBROUTINE AddTie

  SUBROUTINE AddMPC(this, mpc_def, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(MPCConstraintDef),    INTENT(IN)    :: mpc_def
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_constraint_domain(status)) RETURN

    CALL g_ufc_global%md_layer%constraint%AddMPC(mpc_def, status)

  END SUBROUTINE AddMPC

  SUBROUTINE AddCpl(this, cpl_def, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(CplConstraintDef),    INTENT(IN)    :: cpl_def
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_constraint_domain(status)) RETURN

    CALL g_ufc_global%md_layer%constraint%AddCpl(cpl_def, status)

  END SUBROUTINE AddCpl

  SUBROUTINE AddRigid(this, rigid_def, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(RigidBodyDef),        INTENT(IN)    :: rigid_def
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_constraint_domain(status)) RETURN

    CALL g_ufc_global%md_layer%constraint%AddRigid(rigid_def, status)

  END SUBROUTINE AddRigid

  !====================================================================
  ! Contact pair operations
  !====================================================================
  SUBROUTINE AddContactPair(this, pair_def, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(MD_ContactPairDef),   INTENT(IN)    :: pair_def
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_interaction_domain(status)) RETURN

    CALL g_ufc_global%md_layer%interaction%AddPair(pair_def, status)

  END SUBROUTINE AddContactPair

  !====================================================================
  ! Get* procedures (basic types - no global dependency)
  !====================================================================
  SUBROUTINE GetInstance(this, idx, desc, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(MD_Instance_Desc),    INTENT(OUT) :: desc
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_instances) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    desc = this%instances(idx)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE GetInstance

  SUBROUTINE GetNodeSet(this, idx, def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(MD_SetDef),           INTENT(OUT) :: def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_node_sets) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    def = this%node_sets(idx)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE GetNodeSet

  SUBROUTINE GetNodeSetByName(this, name, def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),          INTENT(IN)  :: name
    TYPE(MD_SetDef),           INTENT(OUT) :: def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%n_node_sets
      IF (TRIM(this%node_sets(i)%name) == TRIM(name)) THEN
        def = this%node_sets(i)
        status%status_code = IF_STATUS_OK; RETURN
      END IF
    END DO
    status%status_code  = IF_STATUS_INVALID
    status%message = "NodeSet not found: " // TRIM(name)

  END SUBROUTINE GetNodeSetByName

  SUBROUTINE GetElemSet(this, idx, def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(MD_SetDef),           INTENT(OUT) :: def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_elem_sets) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    def = this%elem_sets(idx)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE GetElemSet

  SUBROUTINE GetElemSetByName(this, name, def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),          INTENT(IN)  :: name
    TYPE(MD_SetDef),           INTENT(OUT) :: def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%n_elem_sets
      IF (TRIM(this%elem_sets(i)%name) == TRIM(name)) THEN
        def = this%elem_sets(i)
        status%status_code = IF_STATUS_OK; RETURN
      END IF
    END DO
    status%status_code  = IF_STATUS_INVALID
    status%message = "ElemSet not found: " // TRIM(name)

  END SUBROUTINE GetElemSetByName

  SUBROUTINE GetSurface(this, idx, def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(MD_SurfaceDef),       INTENT(OUT) :: def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_surfaces) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    def = this%surfaces(idx)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE GetSurface

  SUBROUTINE GetSurfaceByName(this, name, def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),          INTENT(IN)  :: name
    TYPE(MD_SurfaceDef),       INTENT(OUT) :: def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%n_surfaces
      IF (TRIM(this%surfaces(i)%name) == TRIM(name)) THEN
        def = this%surfaces(i)
        status%status_code = IF_STATUS_OK; RETURN
      END IF
    END DO
    status%status_code  = IF_STATUS_INVALID
    status%message = "Surface not found: " // TRIM(name)

  END SUBROUTINE GetSurfaceByName

  SUBROUTINE GetConstraint(this, idx, def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(MD_ConstraintDef),    INTENT(OUT) :: def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_constraints) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    def = this%constraints(idx)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE GetConstraint

  !====================================================================
  ! Constraint Get* procedures (read from global container)
  !====================================================================
  SUBROUTINE GetConstraintByName(this, name, def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),          INTENT(IN)  :: name
    TYPE(MD_ConstraintDef),    INTENT(OUT) :: def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_constraint_domain(status)) RETURN

    ! Search in global constraint domain
    ASSOCIATE(u => g_ufc_global%md_layer%constraint%constraint_union)
      DO i = 1, u%n_tie
        IF (TRIM(u%tie(i)%name) == TRIM(name)) THEN
          def%name = u%tie(i)%name
          def%constraint_type = CONSTRAINT_TIE
          def%master_surface = u%tie(i)%master_surface
          def%slave_surface = u%tie(i)%slave_surface
          def%tolerance = u%tie(i)%position_tolerance
          def%adjust = u%tie(i)%adjust
          status%status_code = IF_STATUS_OK; RETURN
        END IF
      END DO
      DO i = 1, u%n_mpc
        IF (TRIM(u%mpc(i)%name) == TRIM(name)) THEN
          def%name = u%mpc(i)%name
          def%constraint_type = CONSTRAINT_MPC
          def%master_surface = ""
          def%slave_surface = ""
          status%status_code = IF_STATUS_OK; RETURN
        END IF
      END DO
      DO i = 1, u%n_cpl
        IF (TRIM(u%cpl(i)%name) == TRIM(name)) THEN
          def%name = u%cpl(i)%name
          def%constraint_type = CONSTRAINT_COUPLING
          def%master_surface = u%cpl(i)%surface_name
          def%slave_surface = ""
          status%status_code = IF_STATUS_OK; RETURN
        END IF
      END DO
      DO i = 1, u%n_rigid
        IF (TRIM(u%rigid(i)%name) == TRIM(name)) THEN
          def%name = u%rigid(i)%name
          def%constraint_type = CONSTRAINT_RIGID
          def%master_surface = u%rigid(i)%element_set
          def%slave_surface = ""
          status%status_code = IF_STATUS_OK; RETURN
        END IF
      END DO
    END ASSOCIATE

    status%status_code = IF_STATUS_INVALID
    status%message = "Constraint not found: " // TRIM(name)

  END SUBROUTINE GetConstraintByName

  SUBROUTINE GetTie(this, idx, tie_def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(TieConstraintDef),    INTENT(OUT) :: tie_def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_constraint_domain(status)) RETURN

    CALL g_ufc_global%md_layer%constraint%GetTie(idx, tie_def, status)

  END SUBROUTINE GetTie

  SUBROUTINE GetMPC(this, idx, mpc_def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(MPCConstraintDef),    INTENT(OUT) :: mpc_def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_constraint_domain(status)) RETURN

    CALL g_ufc_global%md_layer%constraint%GetMPC(idx, mpc_def, status)

  END SUBROUTINE GetMPC

  SUBROUTINE GetCpl(this, idx, cpl_def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(CplConstraintDef),    INTENT(OUT) :: cpl_def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_constraint_domain(status)) RETURN

    CALL g_ufc_global%md_layer%constraint%GetCpl(idx, cpl_def, status)

  END SUBROUTINE GetCpl

  SUBROUTINE GetRigid(this, idx, rigid_def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(RigidBodyDef),        INTENT(OUT) :: rigid_def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_constraint_domain(status)) RETURN

    CALL g_ufc_global%md_layer%constraint%GetRigid(idx, rigid_def, status)

  END SUBROUTINE GetRigid

  SUBROUTINE GetContactPair(this, idx, pair_def, status)
    CLASS(MD_Assembly_Domain), INTENT(IN)  :: this
    INTEGER(i4),               INTENT(IN)  :: idx
    TYPE(MD_ContactPairDef),   INTENT(OUT) :: pair_def
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. md_assem_require_interaction_domain(status)) RETURN

    CALL g_ufc_global%md_layer%interaction%GetPair(idx, pair_def, status)

  END SUBROUTINE GetContactPair

  !====================================================================
  ! Flat Idx API procedures (access global assembly directly)
  !====================================================================
  SUBROUTINE MD_Assembly_GetInstance_Idx(inst_idx, arg, status)
    INTEGER(i4),                      INTENT(IN)    :: inst_idx
    TYPE(MD_Asm_GetInstance_Arg),INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),            INTENT(OUT)   :: status

    IF (.NOT. md_assem_begin_flat_idx(status)) RETURN
    ASSOCIATE(dom => g_ufc_global%md_layer%assembly)
      IF (inst_idx < 1 .OR. inst_idx > dom%n_instances) THEN
        status%status_code = IF_STATUS_INVALID; RETURN
      END IF
      arg%desc = dom%instances(inst_idx)
    END ASSOCIATE
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Assembly_GetInstance_Idx

  SUBROUTINE MD_Assembly_GetNodeSet_Idx(set_idx, arg, status)
    INTEGER(i4),                     INTENT(IN)    :: set_idx
    TYPE(MD_Asm_GetNodeSet_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),           INTENT(OUT)   :: status

    IF (.NOT. md_assem_begin_flat_idx(status)) RETURN
    ASSOCIATE(dom => g_ufc_global%md_layer%assembly)
      IF (set_idx < 1 .OR. set_idx > dom%n_node_sets) THEN
        status%status_code = IF_STATUS_INVALID; RETURN
      END IF
      arg%def = dom%node_sets(set_idx)
    END ASSOCIATE
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Assembly_GetNodeSet_Idx

  SUBROUTINE MD_Assembly_GetElemSet_Idx(set_idx, arg, status)
    INTEGER(i4),                     INTENT(IN)    :: set_idx
    TYPE(MD_Asm_GetElemSet_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),           INTENT(OUT)   :: status

    IF (.NOT. md_assem_begin_flat_idx(status)) RETURN
    ASSOCIATE(dom => g_ufc_global%md_layer%assembly)
      IF (set_idx < 1 .OR. set_idx > dom%n_elem_sets) THEN
        status%status_code = IF_STATUS_INVALID; RETURN
      END IF
      arg%def = dom%elem_sets(set_idx)
    END ASSOCIATE
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Assembly_GetElemSet_Idx

  SUBROUTINE MD_Assembly_GetSurface_Idx(surf_idx, arg, status)
    INTEGER(i4),                      INTENT(IN)    :: surf_idx
    TYPE(MD_Asm_GetSurface_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),            INTENT(OUT)   :: status

    IF (.NOT. md_assem_begin_flat_idx(status)) RETURN
    ASSOCIATE(dom => g_ufc_global%md_layer%assembly)
      IF (surf_idx < 1 .OR. surf_idx > dom%n_surfaces) THEN
        status%status_code = IF_STATUS_INVALID; RETURN
      END IF
      arg%def = dom%surfaces(surf_idx)
    END ASSOCIATE
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Assembly_GetSurface_Idx

  SUBROUTINE MD_Assembly_GetSurfaceByName_Idx(name, arg, status)
    CHARACTER(LEN=*),                 INTENT(IN)    :: name
    TYPE(MD_Asm_GetSurfaceByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),            INTENT(OUT)   :: status
    INTEGER(i4) :: i

    IF (.NOT. md_assem_begin_flat_idx(status)) RETURN
    arg%found = .FALSE.
    ASSOCIATE(dom => g_ufc_global%md_layer%assembly)
      DO i = 1, dom%n_surfaces
        IF (TRIM(dom%surfaces(i)%name) == TRIM(name)) THEN
          arg%found = .TRUE.
          arg%def = dom%surfaces(i)
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END DO
    END ASSOCIATE
    status%status_code = IF_STATUS_INVALID
    status%message = "Surface not found: " // TRIM(name)

  END SUBROUTINE MD_Assembly_GetSurfaceByName_Idx

  SUBROUTINE MD_Assembly_GetNodeSetByName_Idx(name, arg, status)
    CHARACTER(LEN=*),                 INTENT(IN)    :: name
    TYPE(MD_Asm_GetNodeSetByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),            INTENT(OUT)   :: status
    INTEGER(i4) :: i

    IF (.NOT. md_assem_begin_flat_idx(status)) RETURN
    arg%found = .FALSE.
    ASSOCIATE(dom => g_ufc_global%md_layer%assembly)
      DO i = 1, dom%n_node_sets
        IF (TRIM(dom%node_sets(i)%name) == TRIM(name)) THEN
          arg%found = .TRUE.
          arg%def = dom%node_sets(i)
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END DO
    END ASSOCIATE
    status%status_code = IF_STATUS_INVALID
    status%message = "NodeSet not found: " // TRIM(name)

  END SUBROUTINE MD_Assembly_GetNodeSetByName_Idx

  SUBROUTINE MD_Assembly_GetElemSetByName_Idx(name, arg, status)
    CHARACTER(LEN=*),                 INTENT(IN)    :: name
    TYPE(MD_Asm_GetElemSetByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),            INTENT(OUT)   :: status
    INTEGER(i4) :: i

    IF (.NOT. md_assem_begin_flat_idx(status)) RETURN
    arg%found = .FALSE.
    ASSOCIATE(dom => g_ufc_global%md_layer%assembly)
      DO i = 1, dom%n_elem_sets
        IF (TRIM(dom%elem_sets(i)%name) == TRIM(name)) THEN
          arg%found = .TRUE.
          arg%def = dom%elem_sets(i)
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END DO
    END ASSOCIATE
    status%status_code = IF_STATUS_INVALID
    status%message = "ElemSet not found: " // TRIM(name)

  END SUBROUTINE MD_Assembly_GetElemSetByName_Idx

  !====================================================================
  ! Lifecycle and utility procedures
  !====================================================================
  SUBROUTINE Init(this, status)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    INTEGER(i4) :: astat

    CALL init_error_status(status)

    IF (this%initialized) CALL this%Finalize()

    ALLOCATE(this%instances(16), stat=astat)
    IF (astat /= 0) THEN
      status%status_code = IF_STATUS_MEM_ERROR
      status%message = "MD_Assembly_Domain_Init: ALLOCATE instances failed"
      RETURN
    END IF
    ALLOCATE(this%node_sets(16), stat=astat)
    IF (astat /= 0) THEN
      DEALLOCATE(this%instances)
      status%status_code = IF_STATUS_MEM_ERROR
      status%message = "MD_Assembly_Domain_Init: ALLOCATE node_sets failed"
      RETURN
    END IF
    ALLOCATE(this%elem_sets(16), stat=astat)
    IF (astat /= 0) THEN
      DEALLOCATE(this%instances, this%node_sets)
      status%status_code = IF_STATUS_MEM_ERROR
      status%message = "MD_Assembly_Domain_Init: ALLOCATE elem_sets failed"
      RETURN
    END IF
    ALLOCATE(this%surfaces(16), stat=astat)
    IF (astat /= 0) THEN
      DEALLOCATE(this%instances, this%node_sets, this%elem_sets)
      status%status_code = IF_STATUS_MEM_ERROR
      status%message = "MD_Assembly_Domain_Init: ALLOCATE surfaces failed"
      RETURN
    END IF
    ALLOCATE(this%constraints(8), stat=astat)
    IF (astat /= 0) THEN
      DEALLOCATE(this%instances, this%node_sets, this%elem_sets, this%surfaces)
      status%status_code = IF_STATUS_MEM_ERROR
      status%message = "MD_Assembly_Domain_Init: ALLOCATE constraints failed"
      RETURN
    END IF

    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK

  END SUBROUTINE Init

  SUBROUTINE Finalize(this)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this

    INTEGER(i4) :: i

    IF (ALLOCATED(this%instances))   DEALLOCATE(this%instances)
    IF (ALLOCATED(this%node_sets))   DEALLOCATE(this%node_sets)
    IF (ALLOCATED(this%elem_sets))   DEALLOCATE(this%elem_sets)
    IF (ALLOCATED(this%surfaces))    DEALLOCATE(this%surfaces)
    IF (ALLOCATED(this%constraints)) DEALLOCATE(this%constraints)

    IF (ALLOCATED(this%constraint_union%tie)) THEN
      DO i = 1, this%constraint_union%n_tie
        CALL this%constraint_union%tie(i)%Cleanup()
      END DO
      DEALLOCATE(this%constraint_union%tie)
    END IF
    IF (ALLOCATED(this%constraint_union%mpc)) THEN
      DO i = 1, this%constraint_union%n_mpc
        CALL this%constraint_union%mpc(i)%Cleanup()
      END DO
      DEALLOCATE(this%constraint_union%mpc)
    END IF
    IF (ALLOCATED(this%constraint_union%cpl)) THEN
      DO i = 1, this%constraint_union%n_cpl
        CALL this%constraint_union%cpl(i)%Cleanup()
      END DO
      DEALLOCATE(this%constraint_union%cpl)
    END IF
    IF (ALLOCATED(this%constraint_union%rigid)) THEN
      DO i = 1, this%constraint_union%n_rigid
        CALL this%constraint_union%rigid(i)%Cleanup()
      END DO
      DEALLOCATE(this%constraint_union%rigid)
    END IF

    IF (ALLOCATED(this%interaction_union%contact_pairs)) THEN
      DEALLOCATE(this%interaction_union%contact_pairs)
    END IF

    this%n_instances   = 0_i4
    this%n_node_sets   = 0_i4
    this%n_elem_sets   = 0_i4
    this%n_surfaces    = 0_i4
    this%n_constraints = 0_i4
    this%constraint_union%n_tie = 0_i4
    this%constraint_union%n_mpc = 0_i4
    this%constraint_union%n_cpl = 0_i4
    this%constraint_union%n_rigid = 0_i4
    this%constraint_union%n_total = 0_i4
    this%interaction_union%n_pairs = 0_i4
    this%initialized   = .FALSE.

  END SUBROUTINE Finalize

  SUBROUTINE ReleaseConstraintUnion(this)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this

    INTEGER(i4) :: i

    IF (ALLOCATED(this%constraint_union%tie)) THEN
      DO i = 1, this%constraint_union%n_tie
        CALL this%constraint_union%tie(i)%Cleanup()
      END DO
      DEALLOCATE(this%constraint_union%tie)
    END IF
    IF (ALLOCATED(this%constraint_union%mpc)) THEN
      DO i = 1, this%constraint_union%n_mpc
        CALL this%constraint_union%mpc(i)%Cleanup()
      END DO
      DEALLOCATE(this%constraint_union%mpc)
    END IF
    IF (ALLOCATED(this%constraint_union%cpl)) THEN
      DO i = 1, this%constraint_union%n_cpl
        CALL this%constraint_union%cpl(i)%Cleanup()
      END DO
      DEALLOCATE(this%constraint_union%cpl)
    END IF
    IF (ALLOCATED(this%constraint_union%rigid)) THEN
      DO i = 1, this%constraint_union%n_rigid
        CALL this%constraint_union%rigid(i)%Cleanup()
      END DO
      DEALLOCATE(this%constraint_union%rigid)
    END IF

    this%constraint_union%n_tie   = 0_i4
    this%constraint_union%n_mpc   = 0_i4
    this%constraint_union%n_cpl   = 0_i4
    this%constraint_union%n_rigid = 0_i4
    this%constraint_union%n_total = 0_i4
    this%constraint_union%validated = .FALSE.

  END SUBROUTINE ReleaseConstraintUnion

  SUBROUTINE ReleaseInteractionUnion(this)
    CLASS(MD_Assembly_Domain), INTENT(INOUT) :: this

    IF (ALLOCATED(this%interaction_union%contact_pairs)) THEN
      DEALLOCATE(this%interaction_union%contact_pairs)
    END IF
    this%interaction_union%n_pairs = 0_i4

  END SUBROUTINE ReleaseInteractionUnion

  SUBROUTINE GetSummary(this, arg)
    CLASS(MD_Assembly_Domain),         INTENT(IN)    :: this
    TYPE(MD_Asm_GetSummary_Arg),  INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%summary = "Assembly Domain: not initialized"
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    WRITE(arg%summary, '(A,I0,A,I0,A,I0,A,I0,A,I0)') &
      "Assembly Summary: n_instances=", this%n_instances, &
      ", n_node_sets=", this%n_node_sets, &
      ", n_elem_sets=", this%n_elem_sets, &
      ", n_surfaces=", this%n_surfaces, &
      ", n_constraints=", this%n_constraints
    arg%status%status_code = IF_STATUS_OK

  END SUBROUTINE GetSummary

END MODULE MD_Asm_Mgr