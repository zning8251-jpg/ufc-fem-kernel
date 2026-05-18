!===============================================================================
! MODULE: MD_Constr_Def
! LAYER:  L3_MD
! DOMAIN: Constraint
! ROLE:   Def — Desc+Ctx+State+Algo type definitions
! BRIEF:  Four-type definitions for constraint domain (Tie/MPC/Coupling/Rigid).
!===============================================================================
!
! Type catalogue (4-TYPE system):
!   [Desc]  TieConstraintDef    — Tie constraint descriptor (immutable after parse)
!   [Desc]  MPCConstraintDef    — Multi-point constraint descriptor
!   [Desc]  CplConstraintDef    — Coupling constraint descriptor
!   [Desc]  RigidBodyDef        — Rigid body constraint descriptor (RBE2/RBE3)
!   [Desc]  MD_ConstraintUnion  — Container holding arrays of all 4 Desc types
!   [Ctx]   MD_Constraint_Ctx   — Transient per-operation context (hot)
!   [State] MD_Constraint_State — Runtime activation tracking (warm)
!   [Algo]  MD_Constraint_Algo  — Algorithm config (frozen after parse)
!
! Constants (MD_CONSTR_* canonical prefix):
!   MD_CONSTR_TIE/MPC/COUPLING/RIGID  — constraint category IDs
!   MD_CONSTR_MPC_GENERAL/BEAM/LINK/PIN — MPC sub-types
!   MD_CONSTR_CPL_KINEMATIC/DISTRIBUTING
!   MD_CONSTR_RBE2/RBE3
!   MD_CONSTR_DOF_UX..RZ/ALL           — DOF bitmask flags
!
! Procedures (P0: Init/Finalize/Valid/Cleanup):
!   TieConstraintDef_Init/Valid/Cleanup
!   MPCConstraintDef_Init/AddTerm/Valid/Cleanup
!   CplConstraintDef_Init/SetDOFs/Valid/Cleanup
!   RigidBodyDef_Init/Valid/Cleanup
!
! Pilot: L3 不暴露矩阵装配/Apply/Release 占位 — 数值路径以 L4 `PH_Constr_*` / L5 `RT_Asm_*` 为准。
!
! Status: FOUR-TYPE | AUTHORITY (L3 Constraint Desc) | Last verified: 2026-04-28
!===============================================================================
MODULE MD_Constr_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Constraint category constants  [MD_CONSTR_* canonical]
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_TIE       = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_MPC       = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_COUPLING  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_RIGID     = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_EMBEDDED  = 5_i4

  ! --- legacy aliases (backward compat) ---
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_TIE       = MD_CONSTR_TIE
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_MPC       = MD_CONSTR_MPC
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_COUPLING  = MD_CONSTR_COUPLING
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_RIGID     = MD_CONSTR_RIGID
  INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_EMBEDDED  = MD_CONSTR_EMBEDDED

  !---------------------------------------------------------------------------
  ! MPC sub-type constants  [MD_CONSTR_MPC_* canonical]
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_MPC_GENERAL = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_MPC_BEAM    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_MPC_LINK    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_MPC_PIN     = 3_i4

  ! --- legacy aliases ---
  INTEGER(i4), PARAMETER, PUBLIC :: MPC_TYPE_GENERAL = MD_CONSTR_MPC_GENERAL
  INTEGER(i4), PARAMETER, PUBLIC :: MPC_TYPE_BEAM    = MD_CONSTR_MPC_BEAM
  INTEGER(i4), PARAMETER, PUBLIC :: MPC_TYPE_LINK    = MD_CONSTR_MPC_LINK
  INTEGER(i4), PARAMETER, PUBLIC :: MPC_TYPE_PIN     = MD_CONSTR_MPC_PIN

  !---------------------------------------------------------------------------
  ! Coupling type constants  [MD_CONSTR_CPL_* canonical]
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_CPL_KINEMATIC    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_CPL_DISTRIBUTING = 2_i4

  ! --- legacy aliases ---
  INTEGER(i4), PARAMETER, PUBLIC :: COUPLING_TYPE_KINEMATIC     = MD_CONSTR_CPL_KINEMATIC
  INTEGER(i4), PARAMETER, PUBLIC :: COUPLING_TYPE_DISTRIBUTING  = MD_CONSTR_CPL_DISTRIBUTING

  !---------------------------------------------------------------------------
  ! Rigid body kind constants  [MD_CONSTR_RBE_* canonical]
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_RBE2 = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_RBE3 = 2_i4

  ! --- legacy aliases ---
  INTEGER(i4), PARAMETER, PUBLIC :: RBE_TYPE_RBE2 = MD_CONSTR_RBE2
  INTEGER(i4), PARAMETER, PUBLIC :: RBE_TYPE_RBE3 = MD_CONSTR_RBE3

  !---------------------------------------------------------------------------
  ! DOF bitmask flags  [MD_CONSTR_DOF_* canonical]
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_DOF_UX  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_DOF_UY  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_DOF_UZ  = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_DOF_RX  = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_DOF_RY  = 16_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_DOF_RZ  = 32_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_DOF_ALL = 63_i4

  ! --- legacy aliases ---
  INTEGER(i4), PARAMETER, PUBLIC :: DOF_UX  = MD_CONSTR_DOF_UX
  INTEGER(i4), PARAMETER, PUBLIC :: DOF_UY  = MD_CONSTR_DOF_UY
  INTEGER(i4), PARAMETER, PUBLIC :: DOF_UZ  = MD_CONSTR_DOF_UZ
  INTEGER(i4), PARAMETER, PUBLIC :: DOF_RX  = MD_CONSTR_DOF_RX
  INTEGER(i4), PARAMETER, PUBLIC :: DOF_RY  = MD_CONSTR_DOF_RY
  INTEGER(i4), PARAMETER, PUBLIC :: DOF_RZ  = MD_CONSTR_DOF_RZ
  INTEGER(i4), PARAMETER, PUBLIC :: DOF_ALL = MD_CONSTR_DOF_ALL

  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONSTR_MAX_NAME = 64_i4

  !===========================================================================
  ! [Desc] TieConstraintDef — Tie constraint descriptor (immutable after parse)
  !===========================================================================
  TYPE, PUBLIC :: TieConstraintDef
    INTEGER(i4)       :: tie_id           = 0_i4
    CHARACTER(LEN=64) :: name             = ""
    CHARACTER(LEN=64) :: slave_surface    = ""
    CHARACTER(LEN=64) :: master_surface   = ""
    INTEGER(i4)       :: slave_surface_id  = 0_i4
    INTEGER(i4)       :: master_surface_id = 0_i4
    REAL(wp)          :: position_tolerance = 0.0_wp
    LOGICAL           :: adjust           = .TRUE.
    LOGICAL           :: is_active        = .TRUE.
    INTEGER(i4)       :: n_pairs          = 0_i4
    INTEGER(i4), ALLOCATABLE :: slave_nodes(:)
    INTEGER(i4), ALLOCATABLE :: master_nodes(:)
  CONTAINS
    PROCEDURE :: Valid => TieConstraintDef_Valid_TBP
  END TYPE TieConstraintDef

  !===========================================================================
  ! [Desc] MPCConstraintDef — Multi-point constraint descriptor
  !===========================================================================
  TYPE, PUBLIC :: MPCConstraintDef
    INTEGER(i4)       :: mpc_id       = 0_i4
    CHARACTER(LEN=64) :: name         = ""
    INTEGER(i4)       :: mpc_type     = MPC_TYPE_GENERAL
    INTEGER(i4)       :: n_terms      = 0_i4
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    INTEGER(i4), ALLOCATABLE :: dof_ids(:)
    REAL(wp),    ALLOCATABLE :: coefficients(:)
    REAL(wp)          :: equation_rhs = 0.0_wp
    LOGICAL           :: is_active    = .TRUE.
  CONTAINS
    PROCEDURE :: Valid => MPCConstraintDef_Valid_TBP
  END TYPE MPCConstraintDef

  !===========================================================================
  ! [Desc] CplConstraintDef — Coupling constraint descriptor
  !===========================================================================
  TYPE, PUBLIC :: CplConstraintDef
    INTEGER(i4)       :: coupling_id    = 0_i4
    CHARACTER(LEN=64) :: name           = ""
    INTEGER(i4)       :: coupling_type  = COUPLING_TYPE_KINEMATIC
    INTEGER(i4)       :: ref_node       = 0_i4
    CHARACTER(LEN=64) :: surface_name   = ""
    LOGICAL           :: constrain_dof(6) = (/ .TRUE., .TRUE., .TRUE., &
                                               .FALSE., .FALSE., .FALSE. /)
    INTEGER(i4)       :: n_coupled      = 0_i4
    INTEGER(i4), ALLOCATABLE :: coupled_nodes(:)
    REAL(wp),    ALLOCATABLE :: weights(:)
    LOGICAL           :: is_active      = .TRUE.
  CONTAINS
    PROCEDURE :: Valid => CplConstraintDef_Valid_TBP
  END TYPE CplConstraintDef

  !===========================================================================
  ! [Desc] RigidBodyDef — Rigid body constraint descriptor (RBE2/RBE3)
  !===========================================================================
  TYPE, PUBLIC :: RigidBodyDef
    INTEGER(i4)       :: rigid_id      = 0_i4
    CHARACTER(LEN=64) :: name          = ""
    INTEGER(i4)       :: rbe_kind      = RBE_TYPE_RBE2
    INTEGER(i4)       :: ref_node      = 0_i4
    CHARACTER(LEN=64) :: element_set   = ""
    LOGICAL           :: tie_nset      = .FALSE.
    LOGICAL           :: is_active     = .TRUE.
    INTEGER(i4)       :: n_tied        = 0_i4
    INTEGER(i4), ALLOCATABLE :: tied_nodes(:)
    REAL(wp),    ALLOCATABLE :: tied_weights(:)
  CONTAINS
    PROCEDURE :: Valid => RigidBodyDef_Valid_TBP
  END TYPE RigidBodyDef

  !===========================================================================
  ! [Desc] EmbeddedRegionDef — Embedded region constraint descriptor
  !   Embeds an element set / node set into a host region.
  !   Degrees of freedom of embedded nodes are constrained to follow
  !   the host element interpolation of the surrounding host nodes.
  !===========================================================================
  TYPE, PUBLIC :: EmbeddedRegionDef
    INTEGER(i4)       :: embed_id       = 0_i4
    CHARACTER(LEN=64) :: name           = ""
    CHARACTER(LEN=64) :: host_surface   = ""       ! Host surface or element set
    CHARACTER(LEN=64) :: embedded_set   = ""       ! Embedded element set name
    CHARACTER(LEN=64) :: host_set       = ""       ! Host element set name
    INTEGER(i4)       :: host_surface_id = 0_i4
    LOGICAL           :: use_rounding   = .TRUE.   ! Round embedded nodes onto host boundary
    LOGICAL           :: is_active      = .TRUE.
    INTEGER(i4)       :: n_embedded_elem = 0_i4
    INTEGER(i4)       :: n_embedded_node = 0_i4
    INTEGER(i4), ALLOCATABLE :: embedded_elem_ids(:)
    INTEGER(i4), ALLOCATABLE :: embedded_node_ids(:)
    INTEGER(i4), ALLOCATABLE :: host_elem_ids(:)
    REAL(wp),    ALLOCATABLE :: host_coeffs(:,:)  ! Interpolation coeffs per embedded node
  CONTAINS
    PROCEDURE :: Valid => EmbeddedRegionDef_Valid_TBP
  END TYPE EmbeddedRegionDef

  !===========================================================================
  ! [Desc] MD_ConstraintUnion — container holding arrays of all Desc types
  !===========================================================================
  TYPE, PUBLIC :: MD_ConstraintUnion
    TYPE(TieConstraintDef),  ALLOCATABLE :: tie(:)
    TYPE(MPCConstraintDef),  ALLOCATABLE :: mpc(:)
    TYPE(CplConstraintDef),  ALLOCATABLE :: cpl(:)
    TYPE(RigidBodyDef),      ALLOCATABLE :: rigid(:)
    TYPE(EmbeddedRegionDef), ALLOCATABLE :: embedded(:)
    INTEGER(i4) :: n_tie      = 0_i4
    INTEGER(i4) :: n_mpc      = 0_i4
    INTEGER(i4) :: n_cpl      = 0_i4
    INTEGER(i4) :: n_rigid    = 0_i4
    INTEGER(i4) :: n_embedded = 0_i4
    INTEGER(i4) :: n_total    = 0_i4
    LOGICAL     :: validated  = .FALSE.
  END TYPE MD_ConstraintUnion

  !===========================================================================
  ! [State] MD_Constraint_State — runtime activation tracking (warm)
  !===========================================================================
  TYPE, PUBLIC :: MD_Constraint_State
    LOGICAL     :: assembled    = .FALSE.
    INTEGER(i4) :: n_active     = 0_i4
    INTEGER(i4) :: n_suppressed = 0_i4
  END TYPE MD_Constraint_State

  !===========================================================================
  ! [Algo] MD_Constraint_Algo — algorithm config (frozen after L6_AP parse)
  !   Constraint enforcement method & penalty parameters.
  !   Read-only during Solve phase.
  !===========================================================================
  TYPE, PUBLIC :: MD_Constraint_Algo
    INTEGER(i4) :: default_enforcement = 1_i4    !! 1=Transform, 2=Lagrange, 3=Penalty
    REAL(wp)    :: default_penalty     = 1.0E+10_wp
    REAL(wp)    :: default_tolerance   = 1.0E-8_wp
    LOGICAL     :: use_elimination     = .FALSE.  !! Prefer elimination over penalty
  END TYPE MD_Constraint_Algo

  !===========================================================================
  ! [Ctx] MD_Constraint_Ctx — transient per-operation context (hot)
  !   Not resident in global container; created per constraint operation.
  !===========================================================================
  TYPE, PUBLIC :: MD_Constraint_Ctx
    INTEGER(i4) :: current_constraint_id = 0_i4
    INTEGER(i4) :: operation_type        = 0_i4  ! 1=Add, 2=Modify, 3=Delete
    LOGICAL     :: validation_pending    = .FALSE.
    CHARACTER(LEN=64) :: last_operation  = ""
  END TYPE MD_Constraint_Ctx

  !---------------------------------------------------------------------------
  ! Public procedure interfaces
  !---------------------------------------------------------------------------
  PUBLIC :: TieConstraintDef_Init
  PUBLIC :: TieConstraintDef_Cleanup
  PUBLIC :: TieConstraintDef_Valid

  PUBLIC :: MPCConstraintDef_Init
  PUBLIC :: MPCConstraintDef_AddTerm
  PUBLIC :: MPCConstraintDef_Cleanup
  PUBLIC :: MPCConstraintDef_Valid

  PUBLIC :: CplConstraintDef_Init
  PUBLIC :: CplConstraintDef_Cleanup
  PUBLIC :: CplConstraintDef_SetDOFs
  PUBLIC :: CplConstraintDef_Valid

  PUBLIC :: RigidBodyDef_Init
  PUBLIC :: RigidBodyDef_Cleanup
  PUBLIC :: RigidBodyDef_Valid

  PUBLIC :: EmbeddedRegionDef_Init
  PUBLIC :: EmbeddedRegionDef_Cleanup
  PUBLIC :: EmbeddedRegionDef_Valid

CONTAINS

  !===========================================================================
  ! [P0] Tie: Init / Valid / Cleanup
  !===========================================================================
  SUBROUTINE TieConstraintDef_Init(def, name, slave_surf, master_surf, status)
    TYPE(TieConstraintDef), INTENT(OUT)   :: def
    CHARACTER(LEN=*),       INTENT(IN)    :: name
    CHARACTER(LEN=*),       INTENT(IN)    :: slave_surf
    CHARACTER(LEN=*),       INTENT(IN)    :: master_surf
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    def%tie_id         = 0_i4
    def%name           = TRIM(name)
    def%slave_surface  = TRIM(slave_surf)
    def%master_surface = TRIM(master_surf)
    def%slave_surface_id  = 0_i4
    def%master_surface_id = 0_i4
    def%position_tolerance = 0.0_wp
    def%adjust         = .TRUE.
    def%is_active      = .TRUE.
    def%n_pairs        = 0_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE TieConstraintDef_Init

  FUNCTION TieConstraintDef_Valid(def) RESULT(ok)
    TYPE(TieConstraintDef), INTENT(IN) :: def
    LOGICAL :: ok
    ok = LEN_TRIM(def%name) > 0 .AND. &
         (LEN_TRIM(def%slave_surface) > 0 .OR. def%n_pairs > 0)
  END FUNCTION TieConstraintDef_Valid

  FUNCTION TieConstraintDef_Valid_TBP(this) RESULT(ok)
    CLASS(TieConstraintDef), INTENT(IN) :: this
    LOGICAL :: ok
    ok = TieConstraintDef_Valid(this)
  END FUNCTION TieConstraintDef_Valid_TBP

  SUBROUTINE TieConstraintDef_Cleanup(def, status)
    TYPE(TieConstraintDef), INTENT(INOUT) :: def
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (ALLOCATED(def%slave_nodes))  DEALLOCATE(def%slave_nodes)
    IF (ALLOCATED(def%master_nodes)) DEALLOCATE(def%master_nodes)
    def%n_pairs = 0_i4
    def%name    = ""
    status%status_code = IF_STATUS_OK
  END SUBROUTINE TieConstraintDef_Cleanup

  !===========================================================================
  ! [P0] MPC: Init / AddTerm / Valid / Cleanup
  !===========================================================================
  SUBROUTINE MPCConstraintDef_Init(def, name, mpc_type, status)
    TYPE(MPCConstraintDef), INTENT(OUT)   :: def
    CHARACTER(LEN=*),       INTENT(IN)    :: name
    INTEGER(i4),            INTENT(IN)    :: mpc_type
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    def%mpc_id       = 0_i4
    def%name         = TRIM(name)
    def%mpc_type     = mpc_type
    def%n_terms      = 0_i4
    def%equation_rhs = 0.0_wp
    def%is_active    = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MPCConstraintDef_Init

  SUBROUTINE MPCConstraintDef_AddTerm(def, node_id, dof_id, coeff, status)
    TYPE(MPCConstraintDef), INTENT(INOUT) :: def
    INTEGER(i4),            INTENT(IN)    :: node_id
    INTEGER(i4),            INTENT(IN)    :: dof_id
    REAL(wp),               INTENT(IN)    :: coeff
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4), ALLOCATABLE :: tmp_n(:), tmp_d(:)
    REAL(wp),    ALLOCATABLE :: tmp_c(:)
    INTEGER(i4) :: old_sz

    CALL init_error_status(status)

    IF (.NOT. ALLOCATED(def%node_ids)) THEN
      ALLOCATE(def%node_ids(8), def%dof_ids(8), def%coefficients(8))
      def%node_ids     = 0_i4
      def%dof_ids      = 0_i4
      def%coefficients = 0.0_wp
    END IF

    def%n_terms = def%n_terms + 1_i4

    IF (def%n_terms > SIZE(def%node_ids)) THEN
      old_sz = SIZE(def%node_ids)
      ALLOCATE(tmp_n(old_sz * 2), tmp_d(old_sz * 2), tmp_c(old_sz * 2))
      tmp_n = 0_i4; tmp_d = 0_i4; tmp_c = 0.0_wp
      tmp_n(1:old_sz) = def%node_ids(1:old_sz)
      tmp_d(1:old_sz) = def%dof_ids(1:old_sz)
      tmp_c(1:old_sz) = def%coefficients(1:old_sz)
      CALL MOVE_ALLOC(tmp_n, def%node_ids)
      CALL MOVE_ALLOC(tmp_d, def%dof_ids)
      CALL MOVE_ALLOC(tmp_c, def%coefficients)
    END IF

    def%node_ids(def%n_terms)     = node_id
    def%dof_ids(def%n_terms)      = dof_id
    def%coefficients(def%n_terms) = coeff
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MPCConstraintDef_AddTerm

  FUNCTION MPCConstraintDef_Valid(def) RESULT(ok)
    TYPE(MPCConstraintDef), INTENT(IN) :: def
    LOGICAL :: ok
    ok = def%n_terms >= 1 .AND. ALLOCATED(def%node_ids) .AND. &
         ALLOCATED(def%dof_ids) .AND. ALLOCATED(def%coefficients) .AND. &
         SIZE(def%node_ids) >= def%n_terms
  END FUNCTION MPCConstraintDef_Valid

  FUNCTION MPCConstraintDef_Valid_TBP(this) RESULT(ok)
    CLASS(MPCConstraintDef), INTENT(IN) :: this
    LOGICAL :: ok
    ok = MPCConstraintDef_Valid(this)
  END FUNCTION MPCConstraintDef_Valid_TBP

  SUBROUTINE MPCConstraintDef_Cleanup(def, status)
    TYPE(MPCConstraintDef), INTENT(INOUT) :: def
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (ALLOCATED(def%node_ids))     DEALLOCATE(def%node_ids)
    IF (ALLOCATED(def%dof_ids))      DEALLOCATE(def%dof_ids)
    IF (ALLOCATED(def%coefficients)) DEALLOCATE(def%coefficients)
    def%n_terms = 0_i4
    def%name    = ""
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MPCConstraintDef_Cleanup

  !===========================================================================
  ! [P0] Coupling: Init / SetDOFs / Valid / Cleanup
  !===========================================================================
  SUBROUTINE CplConstraintDef_Init(def, name, ref_node, surf, status)
    TYPE(CplConstraintDef), INTENT(OUT)   :: def
    CHARACTER(LEN=*),       INTENT(IN)    :: name
    INTEGER(i4),            INTENT(IN)    :: ref_node
    CHARACTER(LEN=*),       INTENT(IN)    :: surf
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    def%coupling_id   = 0_i4
    def%name          = TRIM(name)
    def%coupling_type = COUPLING_TYPE_KINEMATIC
    def%ref_node      = ref_node
    def%surface_name  = TRIM(surf)
    def%constrain_dof = (/ .TRUE., .TRUE., .TRUE., .FALSE., .FALSE., .FALSE. /)
    def%n_coupled     = 0_i4
    def%is_active     = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE CplConstraintDef_Init

  SUBROUTINE CplConstraintDef_SetDOFs(def, dof_flags)
    TYPE(CplConstraintDef), INTENT(INOUT) :: def
    LOGICAL,                INTENT(IN)    :: dof_flags(6)
    def%constrain_dof = dof_flags
  END SUBROUTINE CplConstraintDef_SetDOFs

  FUNCTION CplConstraintDef_Valid(def) RESULT(ok)
    TYPE(CplConstraintDef), INTENT(IN) :: def
    LOGICAL :: ok
    ok = LEN_TRIM(def%name) > 0 .AND. def%ref_node > 0 .AND. &
         LEN_TRIM(def%surface_name) > 0
  END FUNCTION CplConstraintDef_Valid

  FUNCTION CplConstraintDef_Valid_TBP(this) RESULT(ok)
    CLASS(CplConstraintDef), INTENT(IN) :: this
    LOGICAL :: ok
    ok = CplConstraintDef_Valid(this)
  END FUNCTION CplConstraintDef_Valid_TBP

  SUBROUTINE CplConstraintDef_Cleanup(def, status)
    TYPE(CplConstraintDef), INTENT(INOUT) :: def
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (ALLOCATED(def%coupled_nodes)) DEALLOCATE(def%coupled_nodes)
    IF (ALLOCATED(def%weights))       DEALLOCATE(def%weights)
    def%n_coupled = 0_i4
    def%name      = ""
    def%ref_node  = 0_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE CplConstraintDef_Cleanup

  !===========================================================================
  ! [P0] Rigid: Init / Valid / Cleanup
  !===========================================================================
  SUBROUTINE RigidBodyDef_Init(def, name, ref_node, element_set, status, rbe_kind)
    TYPE(RigidBodyDef),    INTENT(OUT)            :: def
    CHARACTER(LEN=*),      INTENT(IN)             :: name
    INTEGER(i4),           INTENT(IN)             :: ref_node
    CHARACTER(LEN=*),      INTENT(IN)             :: element_set
    TYPE(ErrorStatusType), INTENT(OUT)            :: status
    INTEGER(i4),           INTENT(IN),  OPTIONAL  :: rbe_kind

    CALL init_error_status(status)
    def%rigid_id    = 0_i4
    def%name        = TRIM(name)
    def%ref_node    = ref_node
    def%element_set = TRIM(element_set)
    def%tie_nset    = .FALSE.
    def%is_active   = .TRUE.
    def%n_tied      = 0_i4
    IF (PRESENT(rbe_kind)) THEN
      def%rbe_kind = rbe_kind
    ELSE
      def%rbe_kind = RBE_TYPE_RBE2
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RigidBodyDef_Init

  FUNCTION RigidBodyDef_Valid(def) RESULT(ok)
    TYPE(RigidBodyDef), INTENT(IN) :: def
    LOGICAL :: ok
    ok = LEN_TRIM(def%name) > 0 .AND. def%ref_node > 0 .AND. &
         (LEN_TRIM(def%element_set) > 0 .OR. def%n_tied > 0)
  END FUNCTION RigidBodyDef_Valid

  FUNCTION RigidBodyDef_Valid_TBP(this) RESULT(ok)
    CLASS(RigidBodyDef), INTENT(IN) :: this
    LOGICAL :: ok
    ok = RigidBodyDef_Valid(this)
  END FUNCTION RigidBodyDef_Valid_TBP

  !===========================================================================
  ! [P0] Embedded: Init / Valid / Cleanup
  !===========================================================================
  SUBROUTINE EmbeddedRegionDef_Init(def, name, host_set, embedded_set, status, use_rounding)
    TYPE(EmbeddedRegionDef), INTENT(OUT)  :: def
    CHARACTER(LEN=*),        INTENT(IN)   :: name
    CHARACTER(LEN=*),        INTENT(IN)   :: host_set
    CHARACTER(LEN=*),        INTENT(IN)   :: embedded_set
    TYPE(ErrorStatusType),   INTENT(OUT)  :: status
    LOGICAL,                 INTENT(IN), OPTIONAL :: use_rounding

    CALL init_error_status(status)
    def%embed_id     = 0_i4
    def%name         = TRIM(name)
    def%host_set     = TRIM(host_set)
    def%embedded_set = TRIM(embedded_set)
    def%host_surface = ""
    def%host_surface_id = 0_i4
    IF (PRESENT(use_rounding)) THEN
      def%use_rounding = use_rounding
    ELSE
      def%use_rounding = .TRUE.
    END IF
    def%is_active       = .TRUE.
    def%n_embedded_elem = 0_i4
    def%n_embedded_node = 0_i4
    status%status_code  = IF_STATUS_OK
  END SUBROUTINE EmbeddedRegionDef_Init

  FUNCTION EmbeddedRegionDef_Valid(def) RESULT(ok)
    TYPE(EmbeddedRegionDef), INTENT(IN) :: def
    LOGICAL :: ok
    ok = LEN_TRIM(def%name) > 0 .AND. &
         LEN_TRIM(def%embedded_set) > 0 .AND. &
         (LEN_TRIM(def%host_set) > 0 .OR. LEN_TRIM(def%host_surface) > 0)
  END FUNCTION EmbeddedRegionDef_Valid

  FUNCTION EmbeddedRegionDef_Valid_TBP(this) RESULT(ok)
    CLASS(EmbeddedRegionDef), INTENT(IN) :: this
    LOGICAL :: ok
    ok = EmbeddedRegionDef_Valid(this)
  END FUNCTION EmbeddedRegionDef_Valid_TBP

  SUBROUTINE EmbeddedRegionDef_Cleanup(def, status)
    TYPE(EmbeddedRegionDef), INTENT(INOUT) :: def
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (ALLOCATED(def%embedded_elem_ids)) DEALLOCATE(def%embedded_elem_ids)
    IF (ALLOCATED(def%embedded_node_ids)) DEALLOCATE(def%embedded_node_ids)
    IF (ALLOCATED(def%host_elem_ids))     DEALLOCATE(def%host_elem_ids)
    IF (ALLOCATED(def%host_coeffs))       DEALLOCATE(def%host_coeffs)
    def%n_embedded_elem = 0_i4
    def%n_embedded_node = 0_i4
    def%name            = ""
    def%host_set        = ""
    def%embedded_set    = ""
    status%status_code  = IF_STATUS_OK
  END SUBROUTINE EmbeddedRegionDef_Cleanup

  !===========================================================================
  ! [P0] Rigid: Init / Valid / Cleanup
  !===========================================================================
  SUBROUTINE RigidBodyDef_Cleanup(def, status)
    TYPE(RigidBodyDef),    INTENT(INOUT) :: def
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (ALLOCATED(def%tied_nodes))   DEALLOCATE(def%tied_nodes)
    IF (ALLOCATED(def%tied_weights)) DEALLOCATE(def%tied_weights)
    def%n_tied      = 0_i4
    def%name        = ""
    def%ref_node    = 0_i4
    def%element_set = ""
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RigidBodyDef_Cleanup

END MODULE MD_Constr_Def
