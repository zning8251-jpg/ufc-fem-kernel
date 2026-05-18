!===============================================================================
! MODULE: MD_WB_Def
! LAYER:  L3_MD
! DOMAIN: WriteBack
! ROLE:   Def — Desc+State+Ctx type definitions (no Algo)
! BRIEF:  WriteBack domain types: mapping registry, runtime state, context.
!===============================================================================
!
! Type catalogue (3-TYPE system, Algo clipped):
!   [Desc]  MD_WriteBack_Entry   — Single whitelist entry (domain.field)
!   [Desc]  MD_WriteBack_Target  — Index tree reference (domain_id, entity_idx)
!   [Desc]  MD_WBMapEntry        — Source→target field mapping entry
!   [Desc]  MD_WriteBack_Desc    — Mapping registry (immutable after parse)
!   [State] MD_WriteBack_State   — Runtime write-back progress (warm)
!   [Ctx]   MD_WriteBack_Ctx     — Write-back operation context (hot)
!
! Constants (MD_WB_* canonical prefix):
!   MD_WB_MAX_MAPS                — max mapping entries
!   MD_WB_DOMAIN_STEP/.../SECTION — domain ID constants
!
! Status: FOUR-TYPE | AUTHORITY (L3 WriteBack) | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:WB | Role:Types | FuncSet:Desc,Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | WriteBack/CONTRACT.md

MODULE MD_WB_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! Parameters
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_MAX_MAPS = 128_i4

  !--------------------------------------------------------------------
  ! [Desc] Domain ID constants  [MD_WB_DOMAIN_* canonical]
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_STEP        = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_AMPLITUDE   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_LOADBC      = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_MESH        = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_MODEL       = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_INTERACTION = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_OUTPUT      = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_ASSEMBLY    = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_CONSTRAINT  = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_MATERIAL    = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_WB_DOMAIN_SECTION     = 11_i4

  ! --- legacy aliases (backward compat) ---
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_STEP        = MD_WB_DOMAIN_STEP
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_AMPLITUDE   = MD_WB_DOMAIN_AMPLITUDE
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_LOADBC      = MD_WB_DOMAIN_LOADBC
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_MESH        = MD_WB_DOMAIN_MESH
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_MODEL       = MD_WB_DOMAIN_MODEL
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_INTERACTION = MD_WB_DOMAIN_INTERACTION
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_OUTPUT      = MD_WB_DOMAIN_OUTPUT
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_ASSEMBLY    = MD_WB_DOMAIN_ASSEMBLY
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_CONSTRAINT  = MD_WB_DOMAIN_CONSTRAINT
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_MATERIAL    = MD_WB_DOMAIN_MATERIAL
  INTEGER(i4), PARAMETER, PUBLIC :: WB_DOMAIN_SECTION     = MD_WB_DOMAIN_SECTION

  !--------------------------------------------------------------------
  ! [Desc] MD_WriteBack_Entry — flat domain storage (one per allowed domain.field)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_WriteBack_Entry
    CHARACTER(LEN=128) :: field_path   = ""
    CHARACTER(LEN=32)  :: domain_name  = ""
    CHARACTER(LEN=64)  :: field_name   = ""
    INTEGER(i4)        :: domain_id    = 0_i4
    LOGICAL            :: is_active    = .FALSE.
    LOGICAL            :: requires_lock = .FALSE.
  END TYPE MD_WriteBack_Entry

  !--------------------------------------------------------------------
  ! [Desc] MD_WriteBack_Target — index tree reference (domain_id, entity_idx)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_WriteBack_Target
    INTEGER(i4) :: domain_id   = 0_i4
    INTEGER(i4) :: entity_idx  = 0_i4
    INTEGER(i4) :: field_slot  = 0_i4   ! slot in flat domain
  END TYPE MD_WriteBack_Target

  !--------------------------------------------------------------------
  ! [Desc] MD_WBMapEntry — source→target field mapping entry
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_WBMapEntry
    INTEGER(i4) :: source_field_id = 0_i4
    INTEGER(i4) :: target_field_id = 0_i4
    INTEGER(i4) :: map_type        = 0_i4
    LOGICAL     :: valid           = .FALSE.
  END TYPE MD_WBMapEntry

  !--------------------------------------------------------------------
  ! [Desc] MD_WriteBack_Desc — mapping registry (immutable after parse)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_WriteBack_Desc
    INTEGER(i4)        :: n_maps = 0_i4
    TYPE(MD_WBMapEntry) :: maps(MD_WB_MAX_MAPS)
  END TYPE MD_WriteBack_Desc

  !--------------------------------------------------------------------
  ! [State] MD_WriteBack_State — runtime write-back progress (warm)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_WriteBack_State
    LOGICAL     :: active       = .FALSE.
    INTEGER(i4) :: n_completed  = 0_i4
    INTEGER(i4) :: n_failed     = 0_i4
    INTEGER(i4) :: current_step = 0_i4
  END TYPE MD_WriteBack_State

  !--------------------------------------------------------------------
  ! [Ctx] MD_WriteBack_Ctx — write-back operation context (hot)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_WriteBack_Ctx
    INTEGER(i4) :: step_idx    = 0_i4
    INTEGER(i4) :: incr_idx    = 0_i4
    LOGICAL     :: in_progress = .FALSE.
  END TYPE MD_WriteBack_Ctx

END MODULE MD_WB_Def
