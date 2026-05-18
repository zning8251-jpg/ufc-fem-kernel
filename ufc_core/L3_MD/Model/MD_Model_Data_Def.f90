!===============================================================================
! MODULE:  MD_Model_Data_Def
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Def (re-export facade)
! BRIEF:   Re-exports all _Type modules from the Data family.
!          Individual modules are now in separate files for single-module=file compliance.
!          Split per L3_MD/Model refactoring plan Step 4.
!===============================================================================
MODULE MD_Model_Data_Def
  USE MD_Model_Data_Table
  USE MD_Model_Data_Param
  USE MD_Model_Data_Field
  USE MD_Model_Data_Dist
  USE MD_Model_Data_Variable
  USE MD_Model_Data_Filter
  USE MD_Model_Data_PhysConst
  IMPLICIT NONE
  PRIVATE
END MODULE MD_Model_Data_Def
