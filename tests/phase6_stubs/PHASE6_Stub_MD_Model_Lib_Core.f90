! Harness-only minimal UF_ModelDef / UF_MaterialDB for Phase6 driver smoke (not production MD_Model_Lib_Core).
MODULE MD_Model_Lib_Core
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UF_ModelDef, UF_Model, UF_MaterialDB

  TYPE :: UF_MaterialDB
    INTEGER(i4) :: num_materials = 0_i4
  END TYPE UF_MaterialDB

  TYPE :: UF_ModelDef
    INTEGER(i4) :: nMaterials = 0_i4
    CHARACTER(LEN=64) :: name = ''
    TYPE(UF_MaterialDB) :: material_db
  END TYPE UF_ModelDef

  TYPE :: UF_Model
    TYPE(UF_ModelDef), POINTER :: model_def => NULL()
    LOGICAL :: has_mesh = .FALSE.
  END TYPE UF_Model

END MODULE MD_Model_Lib_Core
