!===============================================================================
! MODULE: PH_Elem_Reg
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Reg
! BRIEF:  L4 element registry — elem_type → metadata + compute procedure
! **W2**：冷 **`elem_type`** → L4 核元数据；与 L3 **`MD_Elem_Reg`** / **`PH_Elem_Core`** 路由闭环（勿第二套类型表）。
!===============================================================================
MODULE PH_Elem_Reg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
  USE MD_Elem_Mgr, ONLY: PH_ELEM_USER, &
       PH_ELEM_C3D4, PH_ELEM_C3D10, PH_ELEM_C3D10M, PH_ELEM_C3D10E, PH_ELEM_C3D10R, &
       PH_ELEM_C3D8, PH_ELEM_C3D8R, PH_ELEM_C3D8I, PH_ELEM_C3D8H, &
       PH_ELEM_C3D20, PH_ELEM_C3D20R, PH_ELEM_C3D20H, PH_ELEM_C3D20I, &
       PH_ELEM_C3D27, PH_ELEM_C3D27R, PH_ELEM_C3D6, PH_ELEM_C3D15, PH_ELEM_C3D6R, PH_ELEM_C3D15R, &
       PH_ELEM_C3D5, PH_ELEM_C3D13, PH_ELEM_C3D4T, PH_ELEM_C3D6T, PH_ELEM_C3D8T, PH_ELEM_C3D10T, PH_ELEM_C3D15T, &
       PH_ELEM_C3D20T, PH_ELEM_C3D27T, &
       PH_ELEM_C3D4P, PH_ELEM_C3D6P, PH_ELEM_C3D8P, PH_ELEM_C3D10P, &
       PH_ELEM_C3D15P, PH_ELEM_C3D20P, PH_ELEM_C3D27P, PH_ELEM_C3D8PT, &
       PH_ELEM_CPE3, PH_ELEM_CPE6, PH_ELEM_CPE6R, PH_ELEM_CPE4, PH_ELEM_CPE4R, PH_ELEM_CPE4H, PH_ELEM_CPE4I, &
       PH_ELEM_CPE8, PH_ELEM_CPE8R, PH_ELEM_CPE8H, PH_ELEM_CPE8I, &
       PH_ELEM_CPE4T, PH_ELEM_CPE8T, PH_ELEM_CPE4P, PH_ELEM_CPE8P, &
       PH_ELEM_CPEG4, PH_ELEM_CPEG4R, PH_ELEM_CPEG6, PH_ELEM_CPEG8, &
       PH_ELEM_CPS3, PH_ELEM_CPS6, PH_ELEM_CPS6R, PH_ELEM_CPS4, &
       PH_ELEM_CPS4R, PH_ELEM_CPS4I, PH_ELEM_CPS8, PH_ELEM_CPS8R, &
       PH_ELEM_CPS4T, PH_ELEM_CPS8T, &
       PH_ELEM_CAX3, PH_ELEM_CAX6, PH_ELEM_CAX6R, PH_ELEM_CAX4, PH_ELEM_CAX4R, PH_ELEM_CAX4H, &
       PH_ELEM_CAX8, PH_ELEM_CAX8R, PH_ELEM_CAX8I, PH_ELEM_CAX8H, &
       PH_ELEM_CAX4T, PH_ELEM_CAX8T, PH_ELEM_CAX4P, PH_ELEM_CAX8P, &
       PH_ELEM_S3, PH_ELEM_S3R, PH_ELEM_STRI3, PH_ELEM_S6, PH_ELEM_S6R, &
       PH_ELEM_STRI65, PH_ELEM_S4, PH_ELEM_S4R, PH_ELEM_S4RS, PH_ELEM_S4R5, &
       PH_ELEM_S8, PH_ELEM_S8R, PH_ELEM_S8R5, PH_ELEM_S9R5, PH_ELEM_SC6R, PH_ELEM_SC8R, PH_ELEM_S4T, PH_ELEM_S8RT, &
       PH_ELEM_SAX1, PH_ELEM_SAX2, PH_ELEM_SAX2T, &
       PH_ELEM_B21, PH_ELEM_B21H, PH_ELEM_B22, PH_ELEM_B22H, PH_ELEM_B23, PH_ELEM_B21T, &
       PH_ELEM_B31, PH_ELEM_B31H, PH_ELEM_B31OS, PH_ELEM_B32, PH_ELEM_B32H, PH_ELEM_B32OS, &
       PH_ELEM_B33, PH_ELEM_B33H, PH_ELEM_B34, PH_ELEM_B34H, PH_ELEM_B31T, PH_ELEM_B31EX, &
       PH_ELEM_T2D2, PH_ELEM_T2D2H, PH_ELEM_T2D3, PH_ELEM_T2D3H, PH_ELEM_T2D2T, &
       PH_ELEM_T3D2, PH_ELEM_T3D2H, PH_ELEM_T3D3, PH_ELEM_T3D3H, PH_ELEM_T3D2T, &
       PH_ELEM_M3D3, PH_ELEM_M3D3R, PH_ELEM_M3D4, PH_ELEM_M3D4R, &
       PH_ELEM_M3D6, PH_ELEM_M3D6R, &
       PH_ELEM_M3D8, PH_ELEM_M3D8R, PH_ELEM_M2D3, PH_ELEM_M2D3R, &
       PH_ELEM_M2D4, PH_ELEM_M2D4R, PH_ELEM_MAX2, &
       PH_ELEM_DC1D2, PH_ELEM_DC1D3, PH_ELEM_DC2D3, PH_ELEM_DC2D4, &
       PH_ELEM_DC2D6, PH_ELEM_DC2D8, &
       PH_ELEM_DC3D4, PH_ELEM_DC3D6, PH_ELEM_DC3D8, PH_ELEM_DC3D10, &
       PH_ELEM_DC3D15, PH_ELEM_DC3D20, &
       PH_ELEM_AC1D2, PH_ELEM_AC1D3, PH_ELEM_AC2D3, PH_ELEM_AC2D4, &
       PH_ELEM_AC2D4R, PH_ELEM_AC2D6, PH_ELEM_AC2D8, &
       PH_ELEM_AC3D4, PH_ELEM_AC3D6, PH_ELEM_AC3D8, PH_ELEM_AC3D8R, &
       PH_ELEM_AC3D10, PH_ELEM_AC3D15, PH_ELEM_AC3D20, &
       PH_ELEM_ACAX3, PH_ELEM_ACAX4, PH_ELEM_ACAX4R, PH_ELEM_ACAX6, PH_ELEM_ACAX8, &
       PH_ELEM_COH2D4, PH_ELEM_COH2D6, PH_ELEM_COHAX4, PH_ELEM_COHAX6, PH_ELEM_COH3D6, PH_ELEM_COH3D8, &
       PH_ELEM_COH3D12, PH_ELEM_COH3D16, &
       PH_ELEM_R2D2, PH_ELEM_R3D3, PH_ELEM_R3D4, PH_ELEM_RAX2, &
       PH_ELEM_CONN2D2, PH_ELEM_CONN3D2, PH_ELEM_SPRING1, PH_ELEM_SPRING2, PH_ELEM_SPRINGA, &
       PH_ELEM_DASHPOT1, PH_ELEM_DASHPOT2, MD_MESH_ELEM_MASS, PH_ELEM_ROTARYI, &
       MD_MESH_ELEM_C3D8EAS, MD_MESH_ELEM_C3D8FBAR, &
       MD_MESH_ELEM_CPE3T, MD_MESH_ELEM_CPE6T, MD_MESH_ELEM_CPS3T, MD_MESH_ELEM_CPS6T, &
       MD_MESH_ELEM_CPE3P, MD_MESH_ELEM_CPE6P, MD_MESH_ELEM_CPS3P, MD_MESH_ELEM_CPS4P, &
       MD_MESH_ELEM_CPS6P, MD_MESH_ELEM_CPS8P, &
       MD_MESH_ELEM_CAX3T, MD_MESH_ELEM_CAX6T, MD_MESH_ELEM_CAX3P, MD_MESH_ELEM_CAX6P, &
       MD_MESH_ELEM_DS3, MD_MESH_ELEM_DS4, MD_MESH_ELEM_DS6, MD_MESH_ELEM_DS8, &
       MD_MESH_ELEM_M3D9R, MD_MESH_ELEM_PIPE21, MD_MESH_ELEM_PIPE22, MD_MESH_ELEM_S9, &
       PH_ELEM_P3D8SAT, PH_ELEM_P3D8RCH, PH_ELEM_P3D6SAT, PH_ELEM_P3D6RCH, &
       PH_ELEM_P2D4SAT, PH_ELEM_P2D4RCH, PH_ELEM_P2D8SAT, PH_ELEM_P2D8RCH
  USE MD_Elem_Family, ONLY: ElemTypeToFamily
  USE PH_Elem_Aux_Def, ONLY: PH_Elem_Cfg_Init_Desc, PH_Elem_Pop_Vld_Desc
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_ELEM_REG_MAX = 450_i4  ! 430~440 built-in + user slots (PLAN §9.1)

  !--------------------------------------------------------------------
  ! PH_ELEM_FAMILY_*: 12 major families (aligned with Abaqus)
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_SOLID_3D = 1_i4   ! 3D continuum
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_SOLID_2D = 2_i4   ! 2D continuum
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_SHELL    = 3_i4   ! Shell
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_MEMBRANE = 4_i4   ! Membrane
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_BEAM     = 5_i4   ! Beam
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_TRUSS    = 6_i4   ! Truss
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_COHESIVE = 7_i4   ! Cohesive
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_INFINITE = 8_i4   ! Infinite
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_ACOUSTIC = 9_i4   ! Acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_GASKET   = 10_i4  ! Gasket
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_CONN     = 11_i4  ! Connector/Spring/Dashpot
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_MASS     = 12_i4  ! Mass/Inertia/Rigid
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_FAMILY_OTHER    = 99_i4  ! Other/User

  !--------------------------------------------------------------------
  ! Short aliases for Abaqus-like family naming in PH_Elem_Reg_InitAll
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: PH_ELEM_FAMILY_C3D = PH_ELEM_FAMILY_SOLID_3D  ! 3D continuum alias
  INTEGER(i4), PARAMETER :: PH_ELEM_FAMILY_CPE = PH_ELEM_FAMILY_SOLID_2D  ! 2D plane strain alias
  INTEGER(i4), PARAMETER :: PH_ELEM_FAMILY_CPS = PH_ELEM_FAMILY_SOLID_2D  ! 2D plane stress alias
  INTEGER(i4), PARAMETER :: PH_ELEM_FAMILY_CAX = PH_ELEM_FAMILY_SOLID_2D  ! Axisymmetric alias
  INTEGER(i4), PARAMETER :: PH_ELEM_FAMILY_S   = PH_ELEM_FAMILY_SHELL     ! Shell alias
  INTEGER(i4), PARAMETER :: PH_ELEM_FAMILY_B   = PH_ELEM_FAMILY_BEAM      ! Beam alias
  INTEGER(i4), PARAMETER :: PH_ELEM_FAMILY_T   = PH_ELEM_FAMILY_TRUSS     ! Truss alias

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Reg_Entry
  ! KIND: Desc
  ! DESC: Registry entry per elem_type — metadata + base element mapping.
  !       n_nodes / n_dof / family_id live in %pop / %cfg (PH_Elem_Aux_Def), not top-level.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Reg_Entry
    INTEGER(i4) :: elem_type = 0_i4
    INTEGER(i4) :: base_elem_type = 0_i4   ! 0 = self; else base for shape/B-matrix
    CHARACTER(LEN=16) :: name = ""
    INTEGER(i4) :: n_ip = 0_i4
    LOGICAL :: is_registered = .FALSE.
    TYPE(PH_Elem_Cfg_Init_Desc) :: cfg
    TYPE(PH_Elem_Pop_Vld_Desc) :: pop
  END TYPE PH_Elem_Reg_Entry

  !--------------------------------------------------------------------
  ! Global registry
  !--------------------------------------------------------------------
  TYPE(PH_Elem_Reg_Entry), TARGET, SAVE :: g_elem_registry(PH_ELEM_REG_MAX)
  INTEGER(i4), SAVE :: g_num_registered = 0_i4

  PUBLIC :: PH_Elem_Reg_Add
  PUBLIC :: PH_Elem_Reg_Get
  PUBLIC :: PH_Elem_Reg_GetBaseElemType
  PUBLIC :: PH_Elem_Reg_InitAll
  PUBLIC :: PH_Elem_Reg_IsRegistered
  PUBLIC :: PH_Elem_Reg_Entry
  PUBLIC :: PH_ELEM_REG_MAX
  PUBLIC :: PH_ELEM_FAMILY_SOLID_3D, PH_ELEM_FAMILY_SOLID_2D, PH_ELEM_FAMILY_SHELL, PH_ELEM_FAMILY_MEMBRANE
  PUBLIC :: PH_ELEM_FAMILY_BEAM, PH_ELEM_FAMILY_TRUSS, PH_ELEM_FAMILY_COHESIVE, PH_ELEM_FAMILY_INFINITE
  PUBLIC :: PH_ELEM_FAMILY_ACOUSTIC, PH_ELEM_FAMILY_GASKET, PH_ELEM_FAMILY_CONN, PH_ELEM_FAMILY_MASS
  PUBLIC :: PH_ELEM_FAMILY_OTHER

CONTAINS

  !--------------------------------------------------------------------
  ! PH_Elem_Reg_Add: Register element type
  !   base_elem_type: optional; 0 or absent = self is base.
  !--------------------------------------------------------------------
  SUBROUTINE PH_Elem_Reg_Add(elem_type, name, n_nodes, n_ip, n_dof, family_id, status, base_elem_type)
    INTEGER(i4), INTENT(IN) :: elem_type
    CHARACTER(LEN=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(IN) :: n_nodes, n_ip, n_dof
    INTEGER(i4), INTENT(IN), OPTIONAL :: family_id
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: base_elem_type ! same-geometry base for shape reuse

    INTEGER(i4) :: i, slot, fid, base

    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(family_id)) THEN
      fid = family_id
    ELSE
      fid = ElemTypeToFamily(elem_type)
    END IF
    base = 0_i4
    IF (PRESENT(base_elem_type)) base = base_elem_type

    ! Check if already registered
    DO i = 1, g_num_registered
      IF (g_elem_registry(i)%elem_type == elem_type) THEN
        g_elem_registry(i)%name = name
        g_elem_registry(i)%base_elem_type = base
        g_elem_registry(i)%cfg%elem_type_id = elem_type
        g_elem_registry(i)%pop%n_nodes = n_nodes
        g_elem_registry(i)%n_ip = n_ip
        g_elem_registry(i)%pop%n_dof = n_dof
        g_elem_registry(i)%cfg%family_id = fid
        g_elem_registry(i)%is_registered = .TRUE.
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    ! Add new entry
    IF (g_num_registered >= PH_ELEM_REG_MAX) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      IF (PRESENT(status)) status%message = "PH_Elem_Reg: registry full"
      RETURN
    END IF

    g_num_registered = g_num_registered + 1_i4
    slot = g_num_registered
    g_elem_registry(slot)%elem_type = elem_type
    g_elem_registry(slot)%base_elem_type = base
    g_elem_registry(slot)%name = name
    g_elem_registry(slot)%cfg%elem_type_id = elem_type
    g_elem_registry(slot)%pop%n_nodes = n_nodes
    g_elem_registry(slot)%n_ip = n_ip
    g_elem_registry(slot)%pop%n_dof = n_dof
    g_elem_registry(slot)%cfg%family_id = fid
    g_elem_registry(slot)%is_registered = .TRUE.
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_Reg_Add

  !--------------------------------------------------------------------
  ! PH_Elem_Reg_Get: Get registry entry by elem_type
  !--------------------------------------------------------------------
  FUNCTION PH_Elem_Reg_Get(elem_type) RESULT(entry)
    INTEGER(i4), INTENT(IN) :: elem_type
    TYPE(PH_Elem_Reg_Entry), POINTER :: entry

    INTEGER(i4) :: i

    NULLIFY(entry)
    DO i = 1, g_num_registered
      IF (g_elem_registry(i)%elem_type == elem_type .AND. g_elem_registry(i)%is_registered) THEN
        entry => g_elem_registry(i)
        RETURN
      END IF
    END DO
  END FUNCTION PH_Elem_Reg_Get

  !--------------------------------------------------------------------
  ! PH_Elem_Reg_GetBaseElemType: Get base elem_type for shape reuse.
  !   Returns base_elem_type if set, else elem_type (self is base).
  !--------------------------------------------------------------------
  FUNCTION PH_Elem_Reg_GetBaseElemType(elem_type) RESULT(base_type)
    INTEGER(i4), INTENT(IN) :: elem_type
    INTEGER(i4) :: base_type

    TYPE(PH_Elem_Reg_Entry), POINTER :: ep

    base_type = elem_type
    ep => PH_Elem_Reg_Get(elem_type)
    IF (ASSOCIATED(ep) .AND. ep%base_elem_type /= 0_i4) base_type = ep%base_elem_type
  END FUNCTION PH_Elem_Reg_GetBaseElemType

  !--------------------------------------------------------------------
  ! PH_Elem_Reg_IsRegistered: Check if elem_type is registered
  !--------------------------------------------------------------------
  PURE FUNCTION PH_Elem_Reg_IsRegistered(elem_type) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: elem_type
    LOGICAL :: ok

    INTEGER(i4) :: i

    ok = .FALSE.
    DO i = 1, g_num_registered
      IF (g_elem_registry(i)%elem_type == elem_type .AND. g_elem_registry(i)%is_registered) THEN
        ok = .TRUE.
        RETURN
      END IF
    END DO
  END FUNCTION PH_Elem_Reg_IsRegistered

  !--------------------------------------------------------------------
  ! PH_Elem_Reg_InitAll: Register built-in PH_ELEM_* (all MD_Elem_Algo codes except PH_ELEM_USER; count grows with C3D*T, etc.).
  !   PH_ELEM_USER=0: runtime user UEL via PH_Elem_Reg_Add only.
  !   Aligns with MD_Elem_Algo; see UFC_Chain_Rollout §2.4 for count audit.
  !--------------------------------------------------------------------
  SUBROUTINE PH_Elem_Reg_InitAll(status)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(ErrorStatusType) :: st

    IF (PRESENT(status)) CALL init_error_status(status)

    ! === 3D continuum (C3D) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D4,   "C3D4",   4,  1, 12, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D10,  "C3D10", 10,  4, 30, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D10M, "C3D10M",10,  4, 30, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D10E, "C3D10E",10,  4, 30, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D10R, "C3D10R",10,  4, 30, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D8,   "C3D8",   8,  8, 24, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D8R,  "C3D8R",  8,  1, 24, PH_ELEM_FAMILY_C3D, status=st, base_elem_type=PH_ELEM_C3D8)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D8I,  "C3D8I",  8,  8, 24, PH_ELEM_FAMILY_C3D, status=st, base_elem_type=PH_ELEM_C3D8)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D8H,  "C3D8H",  8,  8, 24, PH_ELEM_FAMILY_C3D, status=st, base_elem_type=PH_ELEM_C3D8)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_C3D8EAS,  "C3D8EAS",  8,  8, 24, PH_ELEM_FAMILY_C3D, &
                         status=st, base_elem_type=PH_ELEM_C3D8)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_C3D8FBAR, "C3D8FBAR", 8,  8, 24, PH_ELEM_FAMILY_C3D, &
                         status=st, base_elem_type=PH_ELEM_C3D8)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D20,  "C3D20", 20, 27, 60, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D20R, "C3D20R",20,  8, 60, PH_ELEM_FAMILY_C3D, status=st, base_elem_type=PH_ELEM_C3D20)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D20H, "C3D20H",20, 27, 60, PH_ELEM_FAMILY_C3D, status=st, base_elem_type=PH_ELEM_C3D20)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D20I, "C3D20I",20, 27, 60, PH_ELEM_FAMILY_C3D, status=st, base_elem_type=PH_ELEM_C3D20)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D27,  "C3D27", 27, 27, 81, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D27R, "C3D27R",27, 27, 81, PH_ELEM_FAMILY_C3D, status=st, base_elem_type=PH_ELEM_C3D27)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D6,   "C3D6",   6,  6, 18, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D15,  "C3D15", 15,  9, 45, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D6R,  "C3D6R",  6,  6, 18, PH_ELEM_FAMILY_C3D, status=st, base_elem_type=PH_ELEM_C3D6)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D15R,"C3D15R", 15,  9, 45, PH_ELEM_FAMILY_C3D, status=st, base_elem_type=PH_ELEM_C3D15)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D5,   "C3D5",   5,  8, 15, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D13,  "C3D13", 13,  8, 39, PH_ELEM_FAMILY_C3D, st)
    ! n_dof_total = 8×(3 disp + 1 temp) = 32 (see PH_ElemC3D8T_Algo PH_ELEM_C3D8T_NDOF_TOTAL)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D8T,  "C3D8T",  8,  8, 32, PH_ELEM_FAMILY_C3D, st)
    ! n_dof = 20×(3+1) = 80 (PH_ElemC3D20T_Algo PH_ELEM_C3D20T_NDOF_TOTAL)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D20T, "C3D20T",20, 27, 80, PH_ELEM_FAMILY_C3D, st)
    ! 3D u–p: n_dof from PH_Elem_C3D*n*P_Core
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D4P,  "C3D4P",  4,  1, 16, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D6P,  "C3D6P",  6,  6, 24, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D8P,  "C3D8P",  8,  8, 32, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D10P, "C3D10P",10,  4, 40, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D15P, "C3D15P",15,  9, 60, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D20P, "C3D20P",20, 27, 80, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D27P, "C3D27P",27, 27,108, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D8PT,"C3D8PT", 8,  8, 40, PH_ELEM_FAMILY_C3D, st)
    ! Thermo-mechanical 3D (n_nodes×4 dof); n_ip from PH_Elem_C3D*n*T_Core
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D4T,  "C3D4T",  4,  1, 16, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D6T,  "C3D6T",  6,  6, 24, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D10T, "C3D10T",10,  4, 40, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D15T, "C3D15T",15,  9, 60, PH_ELEM_FAMILY_C3D, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_C3D27T, "C3D27T",27, 27,108, PH_ELEM_FAMILY_C3D, st)

    ! === 2D plane strain (CPE) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE3,   "CPE3",   3,  3,  6, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE6,   "CPE6",   6,  3, 12, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE6R,  "CPE6R",  6,  3, 12, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE6)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE4,   "CPE4",   4,  4,  8, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE4R,  "CPE4R",  4,  1,  8, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE4H,  "CPE4H",  4,  4,  8, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE4I,  "CPE4I",  4,  4,  8, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE8,   "CPE8",   8,  9, 16, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE8R,  "CPE8R",  8,  9, 16, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE8)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE8H,  "CPE8H",  8,  9, 16, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE8)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE8I,  "CPE8I",  8,  9, 16, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE8)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPEG4,  "CPEG4",  4,  4,  8, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPEG4R, "CPEG4R", 4,  1,  8, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPEG6,  "CPEG6",  6,  3, 12, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE6)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPEG8,  "CPEG8",  8,  9, 16, PH_ELEM_FAMILY_CPE, status=st, base_elem_type=PH_ELEM_CPE8)
    ! 4×(2 disp + 1 temp) = 12; 8×3 = 24 (PH_Elem_CPE4T / CPE8T *_NDOF_TOTAL)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPE3T,  "CPE3T",  3,  3,  9, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPE6T,  "CPE6T",  6,  3, 18, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE4T,  "CPE4T",  4,  4, 12, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE8T,  "CPE8T",  8,  9, 24, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPE3P,  "CPE3P",  3,  3,  9, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPE6P,  "CPE6P",  6,  3, 18, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE4P,  "CPE4P",  4,  4, 12, PH_ELEM_FAMILY_CPE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPE8P,  "CPE8P",  8,  9, 24, PH_ELEM_FAMILY_CPE, st)

    ! === 2D plane stress (CPS) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS3,   "CPS3",   3,  3,  6, PH_ELEM_FAMILY_CPS, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS6,   "CPS6",   6,  3, 12, PH_ELEM_FAMILY_CPS, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS6R,  "CPS6R",  6,  3, 12, PH_ELEM_FAMILY_CPS, status=st, base_elem_type=PH_ELEM_CPS6)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS4,   "CPS4",   4,  4,  8, PH_ELEM_FAMILY_CPS, status=st, base_elem_type=PH_ELEM_CPE4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS4R,  "CPS4R",  4,  1,  8, PH_ELEM_FAMILY_CPS, status=st, base_elem_type=PH_ELEM_CPS4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS4I,  "CPS4I",  4,  4,  8, PH_ELEM_FAMILY_CPS, status=st, base_elem_type=PH_ELEM_CPS4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS8,   "CPS8",   8,  9, 16, PH_ELEM_FAMILY_CPS, status=st, base_elem_type=PH_ELEM_CPE8)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS8R,  "CPS8R",  8,  9, 16, PH_ELEM_FAMILY_CPS, status=st, base_elem_type=PH_ELEM_CPS8)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPS3T,  "CPS3T",  3,  3,  9, PH_ELEM_FAMILY_CPS, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPS6T,  "CPS6T",  6,  3, 18, PH_ELEM_FAMILY_CPS, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS4T,  "CPS4T",  4,  4, 12, PH_ELEM_FAMILY_CPS, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CPS8T,  "CPS8T",  8,  9, 24, PH_ELEM_FAMILY_CPS, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPS3P,  "CPS3P",  3,  3,  9, PH_ELEM_FAMILY_CPS, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPS4P,  "CPS4P",  4,  4, 12, PH_ELEM_FAMILY_CPS, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPS6P,  "CPS6P",  6,  3, 18, PH_ELEM_FAMILY_CPS, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CPS8P,  "CPS8P",  8,  9, 24, PH_ELEM_FAMILY_CPS, st)

    ! === Axisymmetric (CAX) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX3,   "CAX3",   3,  3,  6, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX6,   "CAX6",   6,  3, 12, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX6R,  "CAX6R",  6,  3, 12, PH_ELEM_FAMILY_CAX, status=st, base_elem_type=PH_ELEM_CAX6)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX4,   "CAX4",   4,  4,  8, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX4R,  "CAX4R",  4,  1,  8, PH_ELEM_FAMILY_CAX, status=st, base_elem_type=PH_ELEM_CAX4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX4H,  "CAX4H",  4,  4,  8, PH_ELEM_FAMILY_CAX, status=st, base_elem_type=PH_ELEM_CAX4)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX8,   "CAX8",   8,  9, 16, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX8R,  "CAX8R",  8,  9, 16, PH_ELEM_FAMILY_CAX, status=st, base_elem_type=PH_ELEM_CAX8)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX8I,  "CAX8I",  8,  9, 16, PH_ELEM_FAMILY_CAX, status=st, base_elem_type=PH_ELEM_CAX8)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX8H,  "CAX8H",  8,  9, 16, PH_ELEM_FAMILY_CAX, status=st, base_elem_type=PH_ELEM_CAX8)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CAX3T,  "CAX3T",  3,  3,  9, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CAX6T,  "CAX6T",  6,  3, 18, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX4T,  "CAX4T",  4,  4, 12, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX8T,  "CAX8T",  8,  9, 24, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CAX3P,  "CAX3P",  3,  3,  9, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_CAX6P,  "CAX6P",  6,  3, 18, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX4P,  "CAX4P",  4,  4, 12, PH_ELEM_FAMILY_CAX, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CAX8P,  "CAX8P",  8,  9, 24, PH_ELEM_FAMILY_CAX, st)

    ! === Shell (S) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_S3,     "S3",     3,  3, 18, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_S3R,    "S3R",    3,  3, 18, PH_ELEM_FAMILY_S, status=st, base_elem_type=PH_ELEM_S3)
    CALL PH_Elem_Reg_Add(PH_ELEM_STRI3,   "STRI3",  3,  3, 15, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_S6,     "S6",     6,  3, 36, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_S6R,    "S6R",    6,  3, 36, PH_ELEM_FAMILY_S, status=st, base_elem_type=PH_ELEM_S6)
    CALL PH_Elem_Reg_Add(PH_ELEM_STRI65,  "STRI65", 6,  3, 30, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_S4,     "S4",     4,  4, 24, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_S4R,    "S4R",    4,  1, 24, PH_ELEM_FAMILY_S, status=st, base_elem_type=PH_ELEM_S4)
    CALL PH_Elem_Reg_Add(PH_ELEM_S4RS,   "S4RS",   4,  1, 24, PH_ELEM_FAMILY_S, status=st, base_elem_type=PH_ELEM_S4)
    CALL PH_Elem_Reg_Add(PH_ELEM_S4R5,   "S4R5",   4,  1, 20, PH_ELEM_FAMILY_S, status=st, base_elem_type=PH_ELEM_S4)
    CALL PH_Elem_Reg_Add(PH_ELEM_S8,     "S8",     8,  9, 48, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_S8R,    "S8R",    8,  9, 48, PH_ELEM_FAMILY_S, status=st, base_elem_type=PH_ELEM_S8)
    CALL PH_Elem_Reg_Add(PH_ELEM_S8R5,   "S8R5",   8,  9, 40, PH_ELEM_FAMILY_S, status=st, base_elem_type=PH_ELEM_S8)
    CALL PH_Elem_Reg_Add(PH_ELEM_S9R5,   "S9R5",   9,  9, 45, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_S9, "S9",     9,  4, 54, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_SC6R,   "SC6R",   6,  3, 36, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_SC8R,   "SC8R",   8,  9, 48, PH_ELEM_FAMILY_S, st)
    ! S4T/S8RT: mech dof + 1 temperature per node (7×n_nodes); thermal block via CPS*T proxy on x–y projection in Domain
    CALL PH_Elem_Reg_Add(PH_ELEM_S4T,    "S4T",    4,  4, 28, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_S8RT,   "S8RT",   8,  9, 56, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_SAX1,   "SAX1",   1,  1,  2, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_SAX2,   "SAX2",   2,  1,  4, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_SAX2T,  "SAX2T",  2,  1,  4, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_DS3, "DS3",   3,  3,  3, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_DS4, "DS4",   4,  4,  4, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_DS6, "DS6",   6,  3,  6, PH_ELEM_FAMILY_S, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_DS8, "DS8",   8,  9,  8, PH_ELEM_FAMILY_S, st)

    ! === Beam (B) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_B21,    "B21",    2,  1,  6, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B21H,   "B21H",   2,  1,  6, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B22,    "B22",    3,  1,  9, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B22H,   "B22H",   3,  1,  9, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B23,    "B23",    2,  1,  6, PH_ELEM_FAMILY_B, st)
    ! B21T: Abaqus 2-node plane beam + TEMP: 2*(3 mech + 1 T) = 8 dof (not 6)
    CALL PH_Elem_Reg_Add(PH_ELEM_B21T,   "B21T",   2,  1,  8, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B31,    "B31",    2,  1, 12, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B31H,   "B31H",   2,  1, 12, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B31OS,  "B31OS",  2,  1, 12, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B32,    "B32",    3,  1, 18, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B32H,   "B32H",   3,  1, 18, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B32OS,  "B32OS",  3,  1, 18, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B33,    "B33",    2,  1, 12, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B33H,   "B33H",   2,  1, 12, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B34,    "B34",    2,  1, 12, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B34H,   "B34H",   2,  1, 12, PH_ELEM_FAMILY_B, st)
    ! B31T: 6 mech + 1 T per node (14 dof); 1D thermal link between nodes in Domain
    CALL PH_Elem_Reg_Add(PH_ELEM_B31T,   "B31T",   2,  1, 14, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_B31EX,  "B31EX",  2,  1, 12, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_PIPE21, "PIPE21", 2,  2,  6, PH_ELEM_FAMILY_B, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_PIPE22, "PIPE22", 2,  2,  6, PH_ELEM_FAMILY_B, st)

    ! === Truss (T) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_T2D2,   "T2D2",   2,  1,  4, PH_ELEM_FAMILY_T, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_T2D2H,  "T2D2H",  2,  1,  4, PH_ELEM_FAMILY_T, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_T2D3,   "T2D3",   3,  1,  6, PH_ELEM_FAMILY_T, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_T2D3H,  "T2D3H",  3,  1,  6, PH_ELEM_FAMILY_T, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_T2D2T,  "T2D2T",  2,  1,  4, PH_ELEM_FAMILY_T, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_T3D2,   "T3D2",   2,  1,  6, PH_ELEM_FAMILY_T, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_T3D2H,  "T3D2H",  2,  1,  6, PH_ELEM_FAMILY_T, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_T3D3,   "T3D3",   3,  1,  9, PH_ELEM_FAMILY_T, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_T3D3H,  "T3D3H",  3,  1,  9, PH_ELEM_FAMILY_T, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_T3D2T,  "T3D2T",  2,  1,  6, PH_ELEM_FAMILY_T, st)

    ! === Membrane (M) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_M3D3,   "M3D3",   3,  3,  9, PH_ELEM_FAMILY_MEMBRANE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_M3D3R,  "M3D3R",  3,  3,  9, PH_ELEM_FAMILY_MEMBRANE, status=st, base_elem_type=PH_ELEM_M3D3)
    CALL PH_Elem_Reg_Add(PH_ELEM_M3D4,   "M3D4",   4,  4, 12, PH_ELEM_FAMILY_MEMBRANE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_M3D4R,  "M3D4R",  4,  1, 12, PH_ELEM_FAMILY_MEMBRANE, status=st, base_elem_type=PH_ELEM_M3D4)
    CALL PH_Elem_Reg_Add(PH_ELEM_M3D6,   "M3D6",   6,  3, 18, PH_ELEM_FAMILY_MEMBRANE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_M3D6R,  "M3D6R",  6,  3, 18, PH_ELEM_FAMILY_MEMBRANE, status=st, base_elem_type=PH_ELEM_M3D6)
    CALL PH_Elem_Reg_Add(PH_ELEM_M3D8,   "M3D8",   8,  9, 24, PH_ELEM_FAMILY_MEMBRANE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_M3D8R,  "M3D8R",  8,  9, 24, PH_ELEM_FAMILY_MEMBRANE, status=st, base_elem_type=PH_ELEM_M3D8)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_M3D9R, "M3D9R", 4,  4, 12, PH_ELEM_FAMILY_MEMBRANE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_M2D3,   "M2D3",   3,  3,  6, PH_ELEM_FAMILY_MEMBRANE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_M2D3R,  "M2D3R",  3,  3,  6, PH_ELEM_FAMILY_MEMBRANE, status=st, base_elem_type=PH_ELEM_M2D3)
    CALL PH_Elem_Reg_Add(PH_ELEM_M2D4,   "M2D4",   4,  4,  8, PH_ELEM_FAMILY_MEMBRANE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_M2D4R,  "M2D4R",  4,  1,  8, PH_ELEM_FAMILY_MEMBRANE, status=st, base_elem_type=PH_ELEM_M2D4)
    CALL PH_Elem_Reg_Add(PH_ELEM_MAX2,   "MAX2",   2,  1,  4, PH_ELEM_FAMILY_MEMBRANE, st)

    ! === (DC) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_DC1D2,  "DC1D2",  2,  1,  2, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC1D3,  "DC1D3",  3,  1,  3, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC2D3,  "DC2D3",  3,  3,  3, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC2D4,  "DC2D4",  4,  4,  4, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC2D6,  "DC2D6",  6,  3,  6, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC2D8,  "DC2D8",  8,  9,  8, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC3D4,  "DC3D4",  4,  1,  4, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC3D6,  "DC3D6",  6,  6,  6, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC3D8,  "DC3D8",  8,  8,  8, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC3D10, "DC3D10",10,  4, 10, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC3D15, "DC3D15",15,  9, 15, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DC3D20, "DC3D20",20, 27, 20, PH_ELEM_FAMILY_OTHER, st)

    ! === Acoustic (AC) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_AC1D2,  "AC1D2",  2,  1,  2, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC1D3,  "AC1D3",  3,  1,  3, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC2D3,  "AC2D3",  3,  3,  3, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC2D4,  "AC2D4",  4,  4,  4, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC2D4R, "AC2D4R", 4,  1,  4, PH_ELEM_FAMILY_ACOUSTIC, status=st, base_elem_type=PH_ELEM_AC2D4)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC2D6,  "AC2D6",  6,  3,  6, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC2D8,  "AC2D8",  8,  9,  8, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC3D4,  "AC3D4",  4,  1,  4, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC3D6,  "AC3D6",  6,  6,  6, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC3D8,  "AC3D8",  8,  8,  8, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC3D8R, "AC3D8R", 8,  8,  8, PH_ELEM_FAMILY_ACOUSTIC, status=st, base_elem_type=PH_ELEM_AC3D8)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC3D10, "AC3D10",10,  4, 10, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC3D15, "AC3D15",15,  9, 15, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_AC3D20, "AC3D20",20, 27, 20, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_ACAX3,  "ACAX3",  3,  3,  3, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_ACAX4,  "ACAX4",  4,  4,  4, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_ACAX6,  "ACAX6",  6,  3,  6, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_ACAX8,  "ACAX8",  8,  9,  8, PH_ELEM_FAMILY_ACOUSTIC, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_ACAX4R, "ACAX4R", 4,  1,  4, PH_ELEM_FAMILY_ACOUSTIC, status=st, base_elem_type=PH_ELEM_ACAX4)

    ! === Cohesive (COH) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_COH2D4, "COH2D4", 4,  4,  8, PH_ELEM_FAMILY_COHESIVE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_COH2D6, "COH2D6", 6,  3, 12, PH_ELEM_FAMILY_COHESIVE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_COHAX4, "COHAX4", 4,  4,  8, PH_ELEM_FAMILY_COHESIVE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_COHAX6, "COHAX6", 6,  3, 12, PH_ELEM_FAMILY_COHESIVE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_COH3D6, "COH3D6", 6,  3, 18, PH_ELEM_FAMILY_COHESIVE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_COH3D8, "COH3D8", 8,  8, 24, PH_ELEM_FAMILY_COHESIVE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_COH3D12,"COH3D12",12, 12, 36, PH_ELEM_FAMILY_COHESIVE, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_COH3D16,"COH3D16",16, 16, 48, PH_ELEM_FAMILY_COHESIVE, st)

    ! === (R) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_R2D2,   "R2D2",   2,  1,  6, PH_ELEM_FAMILY_MASS, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_R3D3,   "R3D3",   3,  1, 18, PH_ELEM_FAMILY_MASS, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_R3D4,   "R3D4",   4,  1, 24, PH_ELEM_FAMILY_MASS, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_RAX2,   "RAX2",   2,  1,  4, PH_ELEM_FAMILY_MASS, st)

    ! === / / / ===
    CALL PH_Elem_Reg_Add(PH_ELEM_CONN2D2,"CONN2D2",2,  1,  4, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_CONN3D2,"CONN3D2",2,  1,  6, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_SPRING1, "SPRING1",1,  1,  3, PH_ELEM_FAMILY_CONN, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_SPRING2, "SPRING2",2,  1,  6, PH_ELEM_FAMILY_CONN, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_SPRINGA, "SPRINGA",2,  1,  6, PH_ELEM_FAMILY_CONN, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DASHPOT1,"DASHPOT1",1, 1,  3, PH_ELEM_FAMILY_CONN, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_DASHPOT2,"DASHPOT2",2, 1,  6, PH_ELEM_FAMILY_CONN, st)
    CALL PH_Elem_Reg_Add(MD_MESH_ELEM_MASS,   "MASS",    1,  1,  3, PH_ELEM_FAMILY_MASS, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_ROTARYI,"ROTARYI", 1,  1,  3, PH_ELEM_FAMILY_MASS, st)

    ! === (P) ===
    CALL PH_Elem_Reg_Add(PH_ELEM_P3D8SAT, "P3D8SAT", 8,  8,  8, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_P3D8RCH,"P3D8RCH", 8,  8,  8, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_P3D6SAT, "P3D6SAT", 6,  6,  6, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_P3D6RCH,"P3D6RCH", 6,  6,  6, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_P2D4SAT, "P2D4SAT", 4,  4,  4, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_P2D4RCH,"P2D4RCH", 4,  4,  4, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_P2D8SAT, "P2D8SAT", 8,  9,  8, PH_ELEM_FAMILY_OTHER, st)
    CALL PH_Elem_Reg_Add(PH_ELEM_P2D8RCH,"P2D8RCH", 8,  9,  8, PH_ELEM_FAMILY_OTHER, st)

    IF (PRESENT(status)) status = st
  END SUBROUTINE PH_Elem_Reg_InitAll

END MODULE PH_Elem_Reg