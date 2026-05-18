!===============================================================================
! MODULE: RT_Asm_Tripartite
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Def — Phase6 §3.2 orthogonal dispatch key (Element × Section × Material)
! BRIEF:  Linear index helper for future L5 assembly dispatch table; no hot-path use yet.
!===============================================================================
MODULE RT_Asm_Tripartite
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Asm_TripartiteKey
  PUBLIC :: RT_Asm_Tripartite_LinearIndex

  TYPE, PUBLIC :: RT_Asm_TripartiteKey
    INTEGER(i4) :: elem_stem_id = 0_i4
    INTEGER(i4) :: section_rule_id = 0_i4
    INTEGER(i4) :: material_leaf_id = 0_i4
  END TYPE RT_Asm_TripartiteKey

CONTAINS

  PURE FUNCTION RT_Asm_Tripartite_LinearIndex(key, n_section, n_material) RESULT(idx)
    TYPE(RT_Asm_TripartiteKey), INTENT(IN) :: key
    INTEGER(i4), INTENT(IN) :: n_section, n_material
    INTEGER(i4) :: idx
    INTEGER(i4) :: es, ss, mm
    es = MAX(key%elem_stem_id, 1_i4)
    ss = MAX(key%section_rule_id, 1_i4)
    mm = MAX(key%material_leaf_id, 1_i4)
    idx = (es - 1_i4) * n_section * n_material + (ss - 1_i4) * n_material + mm
  END FUNCTION RT_Asm_Tripartite_LinearIndex

END MODULE RT_Asm_Tripartite
