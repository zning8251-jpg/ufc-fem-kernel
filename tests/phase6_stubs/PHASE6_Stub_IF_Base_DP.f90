! Harness-only IF_Base_DP: minimal API for production MD_Mat_Def syntax check.
MODULE IF_Base_DP
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: StructFieldDesc
  PUBLIC :: IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
  PUBLIC :: IF_DATA_TYPE_STRUCT, IF_DATA_TYPE_CLASS
  PUBLIC :: dp_register_struct_type, dp_create_struct_array

  INTEGER(i4), PARAMETER :: IF_DATA_TYPE_INT = 1_i4
  INTEGER(i4), PARAMETER :: IF_DATA_TYPE_DP = 2_i4
  INTEGER(i4), PARAMETER :: IF_DATA_TYPE_CHAR = 3_i4
  INTEGER(i4), PARAMETER :: IF_DATA_TYPE_STRUCT = 4_i4
  INTEGER(i4), PARAMETER :: IF_DATA_TYPE_CLASS = 5_i4

  TYPE :: StructFieldDesc
    CHARACTER(LEN=64) :: name = ''
    INTEGER(i4) :: data_type = 0_i4
    INTEGER(i4) :: offset = 0_i4
    INTEGER(i4) :: length = 0_i4
  END TYPE StructFieldDesc

CONTAINS

  SUBROUTINE dp_register_struct_type(type_name, n_fields, status)
    CHARACTER(LEN=*), INTENT(IN) :: type_name
    INTEGER(i4), INTENT(IN) :: n_fields
    INTEGER(i4), INTENT(OUT) :: status
    status = 0_i4
  END SUBROUTINE dp_register_struct_type

  SUBROUTINE dp_create_struct_array(array_id, type_name, n_elem, status)
    CHARACTER(LEN=*), INTENT(IN) :: type_name
    INTEGER(i4), INTENT(IN) :: array_id, n_elem
    INTEGER(i4), INTENT(OUT) :: status
    status = 0_i4
  END SUBROUTINE dp_create_struct_array

END MODULE IF_Base_DP
