!===============================================================================
! Module: MD_OutDP_Brg
! Layer:  L3_MD - Model Data Layer
! Domain: Output / DataPlatform Bridge
! Purpose: Bridge for MD_Out DataPlatform access. Registers output domain
!          structured types into the DataPlatform and provides DP-based
!          create/query operations for output requests.
!
! Status: ACTIVE | Last verified: 2026-04-28
!
! Domain Pillar: P5 Output (DataPlatform integration)
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Out | Role:Brg | FuncSet:Init,Register | HotPath:No
!>>> UFC_L3_CONTRACT | Output/CONTRACT.md

MODULE MD_OutDP_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Base_DP, ONLY: dp_create_dp_ar, dp_get_real2D, dp_register_var, &
                              STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_DP, &
                              StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
                              DATA_TYPE_STRUCT, IF_DATA_TYPE_INT, IF_DATA_TYPE_CHAR, &
                              dp_get_struct_ptr
  IMPLICIT NONE
  PRIVATE

  ! Re-export DP symbols for domain consumers
  PUBLIC :: dp_create_dp_ar, dp_get_real2D, dp_register_var
  PUBLIC :: STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_DP, DATA_TYPE_STRUCT
  PUBLIC :: IF_DATA_TYPE_INT, IF_DATA_TYPE_CHAR
  PUBLIC :: StructFieldDesc, dp_register_struct_type, dp_create_struct_array
  PUBLIC :: dp_get_struct_ptr

  ! Domain-specific DP interface
  PUBLIC :: MD_OutDP_RegisterStructType
  PUBLIC :: MD_OutDP_Init
  PUBLIC :: MD_OutDP_Finalize

  !--- Module state ---
  LOGICAL, SAVE :: g_dp_registered = .FALSE.
  INTEGER(i4), SAVE :: g_output_struct_id = 0_i4

CONTAINS

  !---------------------------------------------------------------------------
  ! MD_OutDP_Init
  ! Initialize the Output DataPlatform bridge.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_OutDP_Init(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. g_dp_registered) THEN
      CALL MD_OutDP_RegisterStructType(status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_OutDP_Init

  !---------------------------------------------------------------------------
  ! MD_OutDP_RegisterStructType
  ! Register the Output request struct type in DataPlatform.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_OutDP_RegisterStructType(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: struct_id

    CALL init_error_status(status)

    ! Define struct fields for output request
    fields(1)%name      = "request_type"
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%n_comp    = 1

    fields(2)%name      = "frequency"
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%n_comp    = 1

    fields(3)%name      = "n_variables"
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%n_comp    = 1

    fields(4)%name      = "format"
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%n_comp    = 1

    fields(5)%name      = "time_interval"
    fields(5)%data_type = IF_DATA_TYPE_DP
    fields(5)%n_comp    = 1

    CALL dp_register_struct_type("MD_OutputRequest", fields, 5, struct_id)
    g_output_struct_id = struct_id
    g_dp_registered = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_OutDP_RegisterStructType

  !---------------------------------------------------------------------------
  ! MD_OutDP_Finalize
  ! Finalize the Output DataPlatform bridge.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_OutDP_Finalize(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    g_dp_registered = .FALSE.
    g_output_struct_id = 0_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_OutDP_Finalize

END MODULE MD_OutDP_Brg
