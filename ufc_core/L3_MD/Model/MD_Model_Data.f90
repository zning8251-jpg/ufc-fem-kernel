!===============================================================================
! MODULE:  MD_Model_Data
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Facade (re-export facade)
! BRIEF:   Re-export facade for `MD_Model_Data_Table` symbols.
!          Retained for backward compatibility with existing consumers.
!===============================================================================
MODULE MD_Model_Data
  USE MD_Model_Data_Table, ONLY: TableEntry, TableProperties, TablePropertiesManager
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: TableEntry, TableProperties, TablePropertiesManager
END MODULE MD_Model_Data
