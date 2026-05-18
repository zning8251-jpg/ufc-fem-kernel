!===============================================================================
! MODULE: RT_Asm_NLGeomDispatch
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Impl (nonlinear geometry dispatch)
! BRIEF:  Geometric nonlinearity dispatcher -- TL vs UL formulation selection
!===============================================================================

MODULE RT_Asm_NLGeomDispatch
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_SUCCESS, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  ! Public interfaces
  PUBLIC :: RT_Asm_NLGeom_Dispatch_TL  ! RT_Asm_GeomNL_Dispatch_TL
  PUBLIC :: RT_Asm_NLGeom_Dispatch_UL  ! RT_Asm_GeomNL_Dispatch_UL
  PUBLIC :: RT_Asm_NLGeom_RegElemFam   ! RT_Asm_GeomNL_Register_ElementFamily
  PUBLIC :: RT_Asm_NLGeom_Dispatch_Init

  ! Element type enumerations (must match MD layer)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D8  = 1
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_S4    = 2
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_B31   = 3
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CPE4  = 4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D10 = 5
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D20 = 6
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_S4R   = 7
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_T3D2  = 8
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_S3RS  = 9  ! Deprecated: Use RT_ASM_ELEM_TYPE_S3 instead
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_S3    = 9   ! S3 - 3-node triangle shell (unified)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_S8R5  = 10  ! Deprecated: Use RT_ASM_ELEM_TYPE_S8 instead
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_S8    = 10  ! S8 - 8-node shell (unified)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_S9    = 11  ! S9 - 9-node shell (unified)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D4  = 11
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_T2D2  = 12
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_T3D3  = 13
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CPE3  = 14
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CPE6  = 15
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CPE8  = 16
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CAX3  = 17
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D6  = 18
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D15 = 19
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D27 = 20
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_B32  = 21
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CAX4 = 22
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CAX6 = 23
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CAX8 = 24
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CPS6 = 25
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CPS3 = 26
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CPS4 = 27
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_CPS8 = 28
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D8R = 29
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D20R = 30
  ! New element families (Membrane, Pipe, Acoustic, Thermal)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_M3D9R  = 31
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_PIPE21  = 32
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_PIPE22  = 33
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_AC2D4  = 34
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_AC2D6  = 35
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_AC2D8  = 36
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_AC3D4  = 37
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_AC3D6  = 38
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_AC3D8  = 39
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_AC3D10 = 40
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_AC3D15 = 41
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_AC3D20 = 42
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC2D3  = 43
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC2D4  = 44
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC2D6  = 45
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC2D8  = 46
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC3D4  = 47
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC3D6  = 48
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC3D8  = 49
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC3D10 = 50
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC3D15 = 51
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DC3D20 = 52
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D8P  = 53
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_SPRING1 = 54
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_SPRING2 = 55
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DASHPOT1 = 56
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_DASHPOT2 = 57
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D4P  = 58  ! 4-node tet with pore pressure (16 DOF)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D6P  = 59  ! 6-node wedge with pore pressure (24 DOF)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D10P = 60  ! 10-node tet with pore pressure (40 DOF)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D15P = 61  ! 15-node wedge with pore pressure (60 DOF)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D20P = 62  ! 20-node hex with pore pressure (80 DOF)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ASM_ELEM_TYPE_C3D27P = 63   ! 27-node hex with pore pressure (108 DOF)
  INTEGER(i4), PARAMETER :: RT_ASM_MAX_ELEM_TYPES = 65

  ! Function pointer type for element NL routines
  TYPE :: ElemNL_FuncPtr
    LOGICAL :: is_registered = .FALSE.
    INTEGER(i4) :: elem_type_id
    CHARACTER(LEN=32) :: elem_name
  END TYPE ElemNL_FuncPtr

  ! Registry of all element families
  TYPE(ElemNL_FuncPtr), DIMENSION(RT_ASM_MAX_ELEM_TYPES), SAVE :: nl_registry  ! FLOW-002-exempt: static NLGeom registry table (init-once)

CONTAINS

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_NLGeom_Dispatch_Init
  ! Purpose: Initialize the nonlinear element dispatcher registry
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_NLGeom_Dispatch_Init(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    status%status_code = IF_STATUS_SUCCESS

    ! Register core element families (hardcoded for now)
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D8, "C3D8", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_S4, "S4", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_B31, "B31", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CPE4, "CPE4", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D10, "C3D10", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D20, "C3D20", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_S4R, "S4R", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_T3D2, "T3D2", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    ! S3RS and S3 share the same type ID (9), register as S3 (S3RS is deprecated)
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_S3, "S3", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    ! Also register "S3RS" name for backward compatibility (same type ID)
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_S3RS, "S3RS", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    ! S8R5 and S8 share the same type ID (10), register as S8 (S8R5 is deprecated)
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_S8, "S8", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    ! Also register "S8R5" name for backward compatibility (same type ID)
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_S8R5, "S8R5", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    ! Register S9
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_S9, "S9", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D4, "C3D4", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_T2D2, "T2D2", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_T3D3, "T3D3", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CPE3, "CPE3", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CPE6, "CPE6", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CPE8, "CPE8", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CAX3, "CAX3", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D6, "C3D6", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D15, "C3D15", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D27, "C3D27", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_B32, "B32", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CAX4, "CAX4", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CAX6, "CAX6", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CAX8, "CAX8", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CPS6, "CPS6", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CPS3, "CPS3", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CPS4, "CPS4", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_CPS8, "CPS8", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D8R, "C3D8R", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D20R, "C3D20R", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    ! Membrane, Pipe, Acoustic, Thermal
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_M3D9R, "M3D9R", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_PIPE21, "PIPE21", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_PIPE22, "PIPE22", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_AC2D4, "AC2D4", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_AC2D6, "AC2D6", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_AC2D8, "AC2D8", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_AC3D4, "AC3D4", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_AC3D6, "AC3D6", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_AC3D8, "AC3D8", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_AC3D10, "AC3D10", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_AC3D15, "AC3D15", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_AC3D20, "AC3D20", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC2D3, "DC2D3", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC2D4, "DC2D4", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC2D6, "DC2D6", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC2D8, "DC2D8", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC3D4, "DC3D4", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC3D6, "DC3D6", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC3D8, "DC3D8", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC3D10, "DC3D10", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC3D15, "DC3D15", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DC3D20, "DC3D20", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D8P, "C3D8P", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_SPRING1, "SPRING1", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_SPRING2, "SPRING2", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DASHPOT1, "DASHPOT1", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_DASHPOT2, "DASHPOT2", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D4P, "C3D4P", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D6P, "C3D6P", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D10P, "C3D10P", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D15P, "C3D15P", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D20P, "C3D20P", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN
    CALL RT_Asm_NLGeom_RegElemFam(RT_ASM_ELEM_TYPE_C3D27P, "C3D27P", status)
    IF (status%status_code /= IF_STATUS_SUCCESS) RETURN

  END SUBROUTINE RT_Asm_NLGeom_Dispatch_Init

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_NLGeom_RegElemFam
  ! Purpose: Register an element family to the NL dispatcher
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_NLGeom_RegElemFam(elem_type_id, elem_name, status)
    INTEGER(i4), INTENT(IN) :: elem_type_id
    CHARACTER(LEN=*), INTENT(IN) :: elem_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    status%status_code = IF_STATUS_SUCCESS

    IF (elem_type_id < 1 .OR. elem_type_id > RT_ASM_MAX_ELEM_TYPES) THEN
      status%status_code = IF_STATUS_ERROR
      RETURN
    END IF

    nl_registry(elem_type_id)%is_registered = .TRUE.
    nl_registry(elem_type_id)%cfg%elem_type_id = elem_type_id
    nl_registry(elem_type_id)%elem_name = TRIM(elem_name)

  END SUBROUTINE RT_Asm_NLGeom_RegElemFam

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_NLGeom_Dispatch_TL
  ! Purpose: Dispatch Total Lagrangian geometric nonlinearity
  ! Input:
  !   elem_type_id    : Element type identifier
  !   coords_ref(:,:) : Initial coordinates (layout varies by element)
  !   u_elem(:)       : Displacement/rotation vector
  !   D(:,:)          : Mat tangent
  !   extra_params(:) : Optional parameters (thickness, area, etc.)
  ! Output:
  !   Ke_mat(:,:)     : Mat stiffness matrix
  !   Ke_geo(:,:)     : Geometric stiffness matrix
  !   R_int(:)        : Internal force vector
  !   status          : Error status
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_NLGeom_Dispatch_TL(elem_type_id, coords_ref, u_elem, D, &
                                    extra_params, Ke_mat, Ke_geo, R_int, status)
    ! S4R: CASE calls PH_Elem_S4_NL_TL (no separate S4R module)
    ! S3RS/S8R5 deprecated: CASE dispatches to S3/S8, no separate module
    ! C3D8R uses C3D8 main module; C3D20R uses C3D20 main module
    ! (No separate stub files needed)
    ! Membrane, Pipe, Acoustic, Thermal
    ! 
    ! Direct USE L4_PH (no glue layer)
    USE PH_Elem_C3D8, ONLY: PH_Elem_C3D8_NL_TL_FromD
    USE PH_Elem_S4, ONLY: PH_Elem_S4_NL_TL
    USE PH_Elem_B31, ONLY: PH_Elem_B31_NL_TL
    USE PH_Elem_CPE4, ONLY: PH_Elem_CPE4_NL_TL
    USE PH_Elem_C3D10, ONLY: PH_Elem_C3D10_NL_TL
    USE PH_Elem_C3D20, ONLY: PH_Elem_C3D20_NL_TL
    USE PH_Elem_C3D4, ONLY: PH_Elem_C3D4_NL_TL
    USE PH_Elem_C3D6, ONLY: PH_Elem_C3D6_NL_TL
    USE PH_Elem_C3D15, ONLY: PH_Elem_C3D15_NL_TL
    USE PH_Elem_C3D27, ONLY: PH_Elem_C3D27_NL_TL
    USE PH_Elem_S3, ONLY: PH_Elem_S3_NL_TL
    USE PH_Elem_S8, ONLY: PH_Elem_S8_NL_TL
    USE PH_Elem_S9, ONLY: PH_Elem_S9_NL_TL
    USE PH_Elem_T2D2, ONLY: PH_Elem_T2D2_NL_TL
    USE PH_Elem_T3D2, ONLY: PH_Elem_T3D2_NL_TL
    USE PH_Elem_T3D3, ONLY: PH_Elem_T3D3_NL_TL
    USE PH_Elem_CPE3, ONLY: PH_Elem_CPE3_NL_TL
    USE PH_Elem_CPE6, ONLY: PH_Elem_CPE6_NL_TL
    USE PH_Elem_CPE8, ONLY: PH_Elem_CPE8_NL_TL
    USE PH_Elem_CAX3, ONLY: PH_Elem_CAX3_NL_TL
    USE PH_Elem_CAX4, ONLY: PH_Elem_CAX4_NL_TL
    USE PH_Elem_CAX6, ONLY: PH_Elem_CAX6_NL_TL
    USE PH_Elem_CAX8, ONLY: PH_Elem_CAX8_NL_TL
    USE PH_Elem_CPS3, ONLY: PH_Elem_CPS3_NL_TL
    USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_NL_TL
    USE PH_Elem_CPS6, ONLY: PH_Elem_CPS6_NL_TL
    USE PH_Elem_CPS8, ONLY: PH_Elem_CPS8_NL_TL
    USE PH_Elem_B32, ONLY: PH_Elem_B32_NL_TL
    USE PH_Elem_C3D8P, ONLY: PH_Elem_C3D8P_NL_TL
    USE PH_Elem_C3D4P, ONLY: PH_Elem_C3D4P_NL_TL
    USE PH_Elem_C3D6P, ONLY: PH_Elem_C3D6P_NL_TL
    USE PH_Elem_C3D10P, ONLY: PH_Elem_C3D10P_NL_TL
    USE PH_Elem_C3D15P, ONLY: PH_Elem_C3D15P_NL_TL
    USE PH_Elem_C3D20P, ONLY: PH_Elem_C3D20P_NL_TL
    USE PH_Elem_C3D27P, ONLY: PH_Elem_C3D27P_NL_TL
    USE PH_Elem_SPRING1, ONLY: PH_Elem_SPRING1_NL_TL
    USE PH_Elem_SPRING2, ONLY: PH_Elem_SPRING2_NL_TL
    USE PH_Elem_DASHPOT1, ONLY: PH_Elem_DASHPOT1_NL_TL
    USE PH_Elem_DASHPOT2, ONLY: PH_Elem_DASHPOT2_NL_TL
    USE PH_Elem_Membrane, ONLY: PH_Elem_M3D9R_NL_TL
    USE PH_Elem_Pipe, ONLY: PH_Elem_PIPE21_NL_TL, PH_Elem_PIPE22_NL_TL
    USE PH_Elem_AC2D4, ONLY: PH_Elem_AC2D4_NL_TL
    USE PH_Elem_AC2D6, ONLY: PH_Elem_AC2D6_NL_TL
    USE PH_Elem_AC2D8, ONLY: PH_Elem_AC2D8_NL_TL
    USE PH_Elem_AC3D4, ONLY: PH_Elem_AC3D4_NL_TL
    USE PH_Elem_AC3D6, ONLY: PH_Elem_AC3D6_NL_TL
    USE PH_Elem_AC3D8, ONLY: PH_Elem_AC3D8_NL_TL
    USE PH_Elem_AC3D10, ONLY: PH_Elem_AC3D10_NL_TL
    USE PH_Elem_AC3D15, ONLY: PH_Elem_AC3D15_NL_TL
    USE PH_Elem_AC3D20, ONLY: PH_Elem_AC3D20_NL_TL
    USE PH_Elem_DC2D3_Definition, ONLY: PH_Elem_DC2D3_NL_TL
    USE PH_Elem_DC2D4_Definition, ONLY: PH_Elem_DC2D4_NL_TL
    USE PH_Elem_DC2D6_Definition, ONLY: PH_Elem_DC2D6_NL_TL
    USE PH_Elem_DC2D8_Definition, ONLY: PH_Elem_DC2D8_NL_TL
    USE PH_Elem_DC3D4_Definition, ONLY: PH_Elem_DC3D4_NL_TL
    USE PH_Elem_DC3D6_Definition, ONLY: PH_Elem_DC3D6_NL_TL
    USE PH_Elem_DC3D8_Definition, ONLY: PH_Elem_DC3D8_NL_TL
    USE PH_Elem_DC3D10_Definition, ONLY: PH_Elem_DC3D10_NL_TL
    USE PH_Elem_DC3D15_Definition, ONLY: PH_Elem_DC3D15_NL_TL
    USE PH_Elem_DC3D20_Definition, ONLY: PH_Elem_DC3D20_NL_TL
    ! Removed all direct USE PH_Elem_*_Definition statements (50+ statements removed)
    INTEGER(i4), INTENT(IN) :: elem_type_id
    REAL(wp), INTENT(IN) :: coords_ref(:,:)
    REAL(wp), INTENT(IN) :: u_elem(:)
    REAL(wp), INTENT(IN) :: D(:,:)
    REAL(wp), INTENT(IN), OPTIONAL :: extra_params(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(:,:)
    REAL(wp), INTENT(OUT) :: Ke_geo(:,:)
    REAL(wp), INTENT(OUT) :: R_int(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: thickness, area, Iy, Iz, k_hyd, alpha_b
    INTEGER(i4) :: n_layers, n_section_pts

    status%status_code = IF_STATUS_SUCCESS

    ! Check if element family is registered
    IF (.NOT. nl_registry(elem_type_id)%is_registered) THEN
      status%status_code = IF_STATUS_ERROR
      ! status%msg removed - use init_error_status for messaging
      RETURN
    END IF

    ! Dispatch to specific element family TL routine
    SELECT CASE (elem_type_id)

      CASE (RT_ASM_ELEM_TYPE_C3D8)
        ! C3D8: 3D hex (3, 8) coords, 24 DOF, variant via extra_params(1)
        ! Direct call L4_PH PH_Elem_C3D8_NL_TL_FromD
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 1) THEN
          variant = INT(extra_params(1), i4)
        ELSE
          variant = 1  ! STANDARD
        END IF
        CALL PH_Elem_C3D8_NL_TL_FromD(coords_ref(1:3, 1:8), u_elem(1:24), D(1:6, 1:6), &
                               Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status, variant)

      CASE (RT_ASM_ELEM_TYPE_S4)
        ! S4: Shell (3, 4) coords, 24 DOF, needs thickness + n_layers
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 3
        END IF
        CALL PH_Elem_S4_NL_TL(coords_ref(1:3, 1:4), u_elem(1:24), D(1:6, 1:6), &
                               thickness, n_layers, &
                               Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status)

      CASE (RT_ASM_ELEM_TYPE_B31)
        ! B31: Beam (3, 2) coords, 12 DOF, needs area/Iy/Iz + n_section_pts
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
          Iy = extra_params(2)
          Iz = extra_params(3)
          n_section_pts = INT(extra_params(4), i4)
        ELSE
          area = 1.0_wp
          Iy = 1.0_wp
          Iz = 1.0_wp
          n_section_pts = 4
        END IF
        CALL PH_Elem_B31_NL_TL(coords_ref(1:3, 1:2), u_elem(1:12), D(1:6, 1:6), &
                                area, Iy, Iz, n_section_pts, &
                                Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CPE4)
        ! CPE4: Plane strain (2, 4) coords, 8 DOF
        CALL PH_Elem_CPE4_NL_TL(coords_ref(1:2, 1:4), u_elem(1:8), D(1:3, 1:3), &
                                 Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)

      CASE (RT_ASM_ELEM_TYPE_C3D10)
        ! C3D10: 10-node tet (3, 10) coords, 30 DOF
        CALL PH_Elem_C3D10_NL_TL(coords_ref(1:3, 1:10), u_elem(1:30), D(1:6, 1:6), &
                                  Ke_mat(1:30, 1:30), Ke_geo(1:30, 1:30), R_int(1:30), status)

      CASE (RT_ASM_ELEM_TYPE_C3D20)
        ! C3D20: 20-node hex (3, 20) coords, 60 DOF, variant via extra_params(1)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 1) THEN
          variant = INT(extra_params(1), i4)
        ELSE
          variant = 1  ! STANDARD
        END IF
        CALL PH_Elem_C3D20_NL_TL(coords_ref(1:3, 1:20), u_elem(1:60), D(1:6, 1:6), &
                                  Ke_mat(1:60, 1:60), Ke_geo(1:60, 1:60), R_int(1:60), status, variant)

      CASE (RT_ASM_ELEM_TYPE_S4R)
        ! S4R: Use S4 with reduced integration (same interface; integration variant via Formul)
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 1
        END IF
        CALL PH_Elem_S4_NL_TL(coords_ref(1:3, 1:4), u_elem(1:24), D(1:6, 1:6), &
                               thickness, n_layers, &
                               Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status)

      CASE (RT_ASM_ELEM_TYPE_T3D2)
        ! T3D2: 2-node truss (3, 2) coords, 6 DOF, needs E_young + area
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_T3D2_NL_TL(coords_ref(1:3, 1:2), u_elem(1:6), &
                                 D(1,1), area, &
                                 Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_S3RS, RT_ASM_ELEM_TYPE_S3)
        ! S3: 3-node triangle shell (3, 3) coords, 18 DOF, needs thickness + n_layers
        ! S3RS is deprecated, use S3 instead
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 3
        END IF
        CALL PH_Elem_S3_NL_TL(coords_ref(1:3, 1:3), u_elem(1:18), D(1:6, 1:6), &
                              thickness, n_layers, &
                              Ke_mat(1:18, 1:18), Ke_geo(1:18, 1:18), R_int(1:18), status)

      CASE (RT_ASM_ELEM_TYPE_S8R5, RT_ASM_ELEM_TYPE_S8)
        ! S8: 8-node shell (3, 8) coords, 48 DOF, needs thickness + n_layers
        ! S8R5 is deprecated, use S8 instead (note: S8R5 had 40 DOF, S8 has 48 DOF)
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 3
        END IF
        CALL PH_Elem_S8_NL_TL(coords_ref(1:3, 1:8), u_elem(1:48), D(1:6, 1:6), &
                              thickness, n_layers, &
                              Ke_mat(1:48, 1:48), Ke_geo(1:48, 1:48), R_int(1:48), status)

      CASE (RT_ASM_ELEM_TYPE_S9)
        ! S9: 9-node shell (3, 9) coords, 54 DOF, needs thickness + n_layers
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 3
        END IF
        CALL PH_Elem_S9_NL_TL(coords_ref(1:3, 1:9), u_elem(1:54), D(1:6, 1:6), &
                              thickness, n_layers, &
                              Ke_mat(1:54, 1:54), Ke_geo(1:54, 1:54), R_int(1:54), status)

      CASE (RT_ASM_ELEM_TYPE_C3D4)
        ! C3D4: 4-node linear tet (3, 4) coords, 12 DOF
        CALL PH_Elem_C3D4_NL_TL(coords_ref(1:3, 1:4), u_elem(1:12), D(1:6, 1:6), &
                                 Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_T2D2)
        ! T2D2: 2-node 2D truss (2, 2) coords, 4 DOF, needs E_young + area
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_T2D2_NL_TL(coords_ref(1:2, 1:2), u_elem(1:4), &
                                 D(1,1), area, &
                                 Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)

      CASE (RT_ASM_ELEM_TYPE_T3D3)
        ! T3D3: 3-node 3D truss (3, 3) coords, 9 DOF, needs E_young + area
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_T3D3_NL_TL(coords_ref(1:3, 1:3), u_elem(1:9), &
                                 D(1,1), area, &
                                 Ke_mat(1:9, 1:9), Ke_geo(1:9, 1:9), R_int(1:9), status)

      CASE (RT_ASM_ELEM_TYPE_CPE3)
        ! CPE3: 3-node plane strain triangle (2, 3) coords, 6 DOF
        CALL PH_Elem_CPE3_NL_TL(coords_ref(1:2, 1:3), u_elem(1:6), D(1:3, 1:3), &
                                 Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_CPE6)
        ! CPE6: 6-node plane strain triangle (2, 6) coords, 12 DOF
        CALL PH_Elem_CPE6_NL_TL(coords_ref(1:2, 1:6), u_elem(1:12), D(1:3, 1:3), &
                                 Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CPE8)
        ! CPE8: 8-node plane strain quad (2, 8) coords, 16 DOF
        CALL PH_Elem_CPE8_NL_TL(coords_ref(1:2, 1:8), u_elem(1:16), D(1:3, 1:3), &
                                 Ke_mat(1:16, 1:16), Ke_geo(1:16, 1:16), R_int(1:16), status)

      CASE (RT_ASM_ELEM_TYPE_CAX3)
        ! CAX3: 3-node axisymmetric triangle (2, 3) coords, 6 DOF
        CALL PH_Elem_CAX3_NL_TL(coords_ref(1:2, 1:3), u_elem(1:6), D(1:4, 1:4), &
                                 Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_C3D6)
        ! C3D6: 6-node wedge (3, 6) coords, 18 DOF
        CALL PH_Elem_C3D6_NL_TL(coords_ref(1:3, 1:6), u_elem(1:18), D(1:6, 1:6), &
                                 Ke_mat(1:18, 1:18), Ke_geo(1:18, 1:18), R_int(1:18), status)

      CASE (RT_ASM_ELEM_TYPE_C3D15)
        ! C3D15: 15-node wedge (3, 15) coords, 45 DOF
        CALL PH_Elem_C3D15_NL_TL(coords_ref(1:3, 1:15), u_elem(1:45), D(1:6, 1:6), &
                                  Ke_mat(1:45, 1:45), Ke_geo(1:45, 1:45), R_int(1:45), status)

      CASE (RT_ASM_ELEM_TYPE_C3D27)
        ! C3D27: 27-node hex (3, 27) coords, 81 DOF
        CALL PH_Elem_C3D27_NL_TL(coords_ref(1:3, 1:27), u_elem(1:81), D(1:6, 1:6), &
                                  Ke_mat(1:81, 1:81), Ke_geo(1:81, 1:81), R_int(1:81), status)

      CASE (RT_ASM_ELEM_TYPE_B32)
        ! B32: 2-node beam (3, 2) coords, 12 DOF, needs E_young only
        CALL PH_Elem_B32_NL_TL(coords_ref(1:3, 1:2), u_elem(1:12), D(1:1, 1:1), &
                                Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CAX4)
        ! CAX4: 4-node axisymmetric quad (2, 4) coords, 8 DOF, D(1:4, 1:4) for axisymmetric
        CALL PH_Elem_CAX4_NL_TL(coords_ref(1:2, 1:4), u_elem(1:8), D(1:4, 1:4), &
                                 Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)

      CASE (RT_ASM_ELEM_TYPE_CAX6)
        ! CAX6: 6-node axisymmetric quadratic triangle (2, 6) coords, 12 DOF
        CALL PH_Elem_CAX6_NL_TL(coords_ref(1:2, 1:6), u_elem(1:12), D(1:4, 1:4), &
                                 Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CAX8)
        ! CAX8: 8-node axisymmetric Serendipity quad (2, 8) coords, 16 DOF
        CALL PH_Elem_CAX8_NL_TL(coords_ref(1:2, 1:8), u_elem(1:16), D(1:4, 1:4), &
                                 Ke_mat(1:16, 1:16), Ke_geo(1:16, 1:16), R_int(1:16), status)

      CASE (RT_ASM_ELEM_TYPE_CPS6)
        ! CPS6: 6-node plane stress quadratic triangle (2, 6) coords, 12 DOF
        CALL PH_Elem_CPS6_NL_TL(coords_ref(1:2, 1:6), u_elem(1:12), D(1:3, 1:3), &
                                 Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CPS3)
        ! CPS3: 3-node plane stress triangle (2, 3) coords, 6 DOF
        CALL PH_Elem_CPS3_NL_TL(coords_ref(1:2, 1:3), u_elem(1:6), D(1:3, 1:3), &
                                 Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_CPS4)
        ! CPS4: 4-node plane stress quad (2, 4) coords, 8 DOF
        CALL PH_Elem_CPS4_NL_TL(coords_ref(1:2, 1:4), u_elem(1:8), D(1:3, 1:3), &
                                 Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)

      CASE (RT_ASM_ELEM_TYPE_CPS8)
        ! CPS8: 8-node plane stress Serendipity quad (2, 8) coords, 16 DOF
        CALL PH_Elem_CPS8_NL_TL(coords_ref(1:2, 1:8), u_elem(1:16), D(1:3, 1:3), &
                                 Ke_mat(1:16, 1:16), Ke_geo(1:16, 1:16), R_int(1:16), status)

      CASE (RT_ASM_ELEM_TYPE_C3D8R)
        ! C3D8R: Use C3D8 with VARIANT_REDUCED (1-point + hourglass)
        variant = 2  ! REDUCED
        CALL PH_Elem_C3D8_NL_TL(coords_ref(1:3, 1:8), u_elem(1:24), D(1:6, 1:6), &
                                 Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status, variant)

      CASE (RT_ASM_ELEM_TYPE_C3D20R)
        ! C3D20R: Use C3D20 with VARIANT_REDUCED (2?? vs 3??)
        variant = 2  ! REDUCED
        CALL PH_Elem_C3D20_NL_TL(coords_ref(1:3, 1:20), u_elem(1:60), D(1:6, 1:6), &
                                  Ke_mat(1:60, 1:60), Ke_geo(1:60, 1:60), R_int(1:60), status, variant)

      CASE (RT_ASM_ELEM_TYPE_M3D9R)
        ! M3D9R: 4-node membrane (3, 4) coords, 12 DOF, needs thickness
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
        ELSE
          thickness = 1.0_wp
        END IF
        CALL PH_Elem_M3D9R_NL_TL(coords_ref(1:3, 1:4), u_elem(1:12), D(1:6, 1:6), &
                                  thickness, Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_PIPE21)
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_PIPE21_NL_TL(coords_ref(1:3, 1:2), u_elem(1:6), D(1:6, 1:6), area, &
                                   Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_PIPE22)
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_PIPE22_NL_TL(coords_ref(1:3, 1:2), u_elem(1:6), D(1:6, 1:6), area, &
                                   Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_AC2D4)
        CALL PH_Elem_AC2D4_NL_TL(coords_ref(1:2, 1:4), u_elem(1:4), D(1:1, 1:1), &
                                  Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)
      CASE (RT_ASM_ELEM_TYPE_AC2D6)
        CALL PH_Elem_AC2D6_NL_TL(coords_ref(1:2, 1:6), u_elem(1:6), D(1:1, 1:1), &
                                  Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)
      CASE (RT_ASM_ELEM_TYPE_AC2D8)
        CALL PH_Elem_AC2D8_NL_TL(coords_ref(1:2, 1:8), u_elem(1:8), D(1:1, 1:1), &
                                  Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D4)
        CALL PH_Elem_AC3D4_NL_TL(coords_ref(1:3, 1:4), u_elem(1:4), D(1:1, 1:1), &
                                  Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D6)
        CALL PH_Elem_AC3D6_NL_TL(coords_ref(1:3, 1:6), u_elem(1:6), D(1:1, 1:1), &
                                  Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D8)
        CALL PH_Elem_AC3D8_NL_TL(coords_ref(1:3, 1:8), u_elem(1:8), D(1:1, 1:1), &
                                  Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D10)
        CALL PH_Elem_AC3D10_NL_TL(coords_ref(1:3, 1:10), u_elem(1:10), D(1:1, 1:1), &
                                   Ke_mat(1:10, 1:10), Ke_geo(1:10, 1:10), R_int(1:10), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D15)
        CALL PH_Elem_AC3D15_NL_TL(coords_ref(1:3, 1:15), u_elem(1:15), D(1:1, 1:1), &
                                   Ke_mat(1:15, 1:15), Ke_geo(1:15, 1:15), R_int(1:15), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D20)
        CALL PH_Elem_AC3D20_NL_TL(coords_ref(1:3, 1:20), u_elem(1:20), D(1:1, 1:1), &
                                   Ke_mat(1:20, 1:20), Ke_geo(1:20, 1:20), R_int(1:20), status)

      CASE (RT_ASM_ELEM_TYPE_DC2D3)
        CALL PH_Elem_DC2D3_NL_TL(coords_ref(1:3, 1:3), u_elem(1:3), D(1:1, 1:1), &
                                  Ke_mat(1:3, 1:3), Ke_geo(1:3, 1:3), R_int(1:3), status)
      CASE (RT_ASM_ELEM_TYPE_DC2D4)
        CALL PH_Elem_DC2D4_NL_TL(coords_ref(1:3, 1:4), u_elem(1:4), D(1:1, 1:1), &
                                  Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)
      CASE (RT_ASM_ELEM_TYPE_DC2D6)
        CALL PH_Elem_DC2D6_NL_TL(coords_ref(1:3, 1:6), u_elem(1:6), D(1:1, 1:1), &
                                  Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)
      CASE (RT_ASM_ELEM_TYPE_DC2D8)
        CALL PH_Elem_DC2D8_NL_TL(coords_ref(1:3, 1:8), u_elem(1:8), D(1:1, 1:1), &
                                  Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D4)
        CALL PH_Elem_DC3D4_NL_TL(coords_ref(1:3, 1:4), u_elem(1:4), D(1:1, 1:1), &
                                  Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D6)
        CALL PH_Elem_DC3D6_NL_TL(coords_ref(1:3, 1:6), u_elem(1:6), D(1:1, 1:1), &
                                  Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D8)
        CALL PH_Elem_DC3D8_NL_TL(coords_ref(1:3, 1:8), u_elem(1:8), D(1:1, 1:1), &
                                  Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D10)
        CALL PH_Elem_DC3D10_NL_TL(coords_ref(1:3, 1:10), u_elem(1:10), D(1:1, 1:1), &
                                   Ke_mat(1:10, 1:10), Ke_geo(1:10, 1:10), R_int(1:10), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D15)
        CALL PH_Elem_DC3D15_NL_TL(coords_ref(1:3, 1:15), u_elem(1:15), D(1:1, 1:1), &
                                   Ke_mat(1:15, 1:15), Ke_geo(1:15, 1:15), R_int(1:15), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D20)
        CALL PH_Elem_DC3D20_NL_TL(coords_ref(1:3, 1:20), u_elem(1:20), D(1:1, 1:1), &
                                   Ke_mat(1:20, 1:20), Ke_geo(1:20, 1:20), R_int(1:20), status)

      CASE (RT_ASM_ELEM_TYPE_C3D8P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D8P_NL_TL(coords_ref(1:3, 1:8), u_elem(1:32), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:32, 1:32), Ke_geo(1:32, 1:32), R_int(1:32), status)

      CASE (RT_ASM_ELEM_TYPE_C3D4P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D4P_NL_TL(coords_ref(1:3, 1:4), u_elem(1:16), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:16, 1:16), Ke_geo(1:16, 1:16), R_int(1:16), status)

      CASE (RT_ASM_ELEM_TYPE_C3D6P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D6P_NL_TL(coords_ref(1:3, 1:6), u_elem(1:24), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status)

      CASE (RT_ASM_ELEM_TYPE_C3D10P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D10P_NL_TL(coords_ref(1:3, 1:10), u_elem(1:40), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:40, 1:40), Ke_geo(1:40, 1:40), R_int(1:40), status)

      CASE (RT_ASM_ELEM_TYPE_C3D15P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D15P_NL_TL(coords_ref(1:3, 1:15), u_elem(1:60), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:60, 1:60), Ke_geo(1:60, 1:60), R_int(1:60), status)

      CASE (RT_ASM_ELEM_TYPE_C3D20P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D20P_NL_TL(coords_ref(1:3, 1:20), u_elem(1:80), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:80, 1:80), Ke_geo(1:80, 1:80), R_int(1:80), status)

      CASE (RT_ASM_ELEM_TYPE_C3D27P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D27P_NL_TL(coords_ref(1:3, 1:27), u_elem(1:108), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:108, 1:108), Ke_geo(1:108, 1:108), R_int(1:108), status)

      CASE (RT_ASM_ELEM_TYPE_SPRING1)
        CALL PH_Elem_SPRING1_NL_TL(coords_ref(1:3, 1:2), u_elem(1:2), D(1:1, 1:1), &
                                    Ke_mat(1:2, 1:2), Ke_geo(1:2, 1:2), R_int(1:2), status)

      CASE (RT_ASM_ELEM_TYPE_SPRING2)
        CALL PH_Elem_SPRING2_NL_TL(coords_ref(1:3, 1:2), u_elem(1:4), D(1:1, 1:1), &
                                    Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)

      CASE (RT_ASM_ELEM_TYPE_DASHPOT1)
        CALL PH_Elem_DASHPOT1_NL_TL(coords_ref(1:3, 1:2), u_elem(1:2), D(1:1, 1:1), &
                                     Ke_mat(1:2, 1:2), Ke_geo(1:2, 1:2), R_int(1:2), status)

      CASE (RT_ASM_ELEM_TYPE_DASHPOT2)
        CALL PH_Elem_DASHPOT2_NL_TL(coords_ref(1:3, 1:2), u_elem(1:4), D(1:1, 1:1), &
                                     Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)

      CASE DEFAULT
        status%status_code = IF_STATUS_ERROR
        ! status%msg removed - use init_error_status for messaging

    END SELECT

  END SUBROUTINE RT_Asm_NLGeom_Dispatch_TL

  !-----------------------------------------------------------------------------
  ! Subroutine: RT_Asm_NLGeom_Dispatch_UL
  ! Purpose: Dispatch Updated Lagrangian geometric nonlinearity
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_NLGeom_Dispatch_UL(elem_type_id, coords_prev, u_incr, D, &
                                    extra_params, Ke_mat, Ke_geo, R_int, status)
    ! S4R: CASE calls PH_Elem_S4_NL_UL (no separate S4R module)
    ! S3RS/S8R5 deprecated: CASE dispatches to S3/S8, no separate module
    ! C3D8R uses C3D8 main module; C3D20R uses C3D20 main module
    ! (No separate stub files needed)
    ! Membrane, Pipe, Acoustic, Thermal
    !
    ! Direct USE L4_PH (no glue layer)
    USE PH_Elem_C3D8, ONLY: PH_Elem_C3D8_NL_UL_FromD
    USE PH_Elem_S4, ONLY: PH_Elem_S4_NL_UL
    USE PH_Elem_B31, ONLY: PH_Elem_B31_NL_UL
    USE PH_Elem_CPE4, ONLY: PH_Elem_CPE4_NL_UL
    USE PH_Elem_C3D10, ONLY: PH_Elem_C3D10_NL_UL
    USE PH_Elem_C3D20, ONLY: PH_Elem_C3D20_NL_UL
    USE PH_Elem_C3D4, ONLY: PH_Elem_C3D4_NL_UL
    USE PH_Elem_C3D6, ONLY: PH_Elem_C3D6_NL_UL
    USE PH_Elem_C3D15, ONLY: PH_Elem_C3D15_NL_UL
    USE PH_Elem_C3D27, ONLY: PH_Elem_C3D27_NL_UL
    USE PH_Elem_S3, ONLY: PH_Elem_S3_NL_UL
    USE PH_Elem_S8, ONLY: PH_Elem_S8_NL_UL
    USE PH_Elem_S9, ONLY: PH_Elem_S9_NL_UL
    USE PH_Elem_T2D2, ONLY: PH_Elem_T2D2_NL_UL
    USE PH_Elem_T3D2, ONLY: PH_Elem_T3D2_NL_UL
    USE PH_Elem_T3D3, ONLY: PH_Elem_T3D3_NL_UL
    USE PH_Elem_CPE3, ONLY: PH_Elem_CPE3_NL_UL
    USE PH_Elem_CPE6, ONLY: PH_Elem_CPE6_NL_UL
    USE PH_Elem_CPE8, ONLY: PH_Elem_CPE8_NL_UL
    USE PH_Elem_CAX3, ONLY: PH_Elem_CAX3_NL_UL
    USE PH_Elem_CAX4, ONLY: PH_Elem_CAX4_NL_UL
    USE PH_Elem_CAX6, ONLY: PH_Elem_CAX6_NL_UL
    USE PH_Elem_CAX8, ONLY: PH_Elem_CAX8_NL_UL
    USE PH_Elem_CPS3, ONLY: PH_Elem_CPS3_NL_UL
    USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_NL_UL
    USE PH_Elem_CPS6, ONLY: PH_Elem_CPS6_NL_UL
    USE PH_Elem_CPS8, ONLY: PH_Elem_CPS8_NL_UL
    USE PH_Elem_B32, ONLY: PH_Elem_B32_NL_UL
    USE PH_Elem_C3D8P, ONLY: PH_Elem_C3D8P_NL_UL
    USE PH_Elem_C3D4P, ONLY: PH_Elem_C3D4P_NL_UL
    USE PH_Elem_C3D6P, ONLY: PH_Elem_C3D6P_NL_UL
    USE PH_Elem_C3D10P, ONLY: PH_Elem_C3D10P_NL_UL
    USE PH_Elem_C3D15P, ONLY: PH_Elem_C3D15P_NL_UL
    USE PH_Elem_C3D20P, ONLY: PH_Elem_C3D20P_NL_UL
    USE PH_Elem_C3D27P, ONLY: PH_Elem_C3D27P_NL_UL
    USE PH_Elem_SPRING1, ONLY: PH_Elem_SPRING1_NL_UL
    USE PH_Elem_SPRING2, ONLY: PH_Elem_SPRING2_NL_UL
    USE PH_Elem_DASHPOT1, ONLY: PH_Elem_DASHPOT1_NL_UL
    USE PH_Elem_DASHPOT2, ONLY: PH_Elem_DASHPOT2_NL_UL
    USE PH_Elem_Membrane, ONLY: PH_Elem_M3D9R_NL_UL
    USE PH_Elem_Pipe, ONLY: PH_Elem_PIPE21_NL_UL, PH_Elem_PIPE22_NL_UL
    USE PH_Elem_AC2D4, ONLY: PH_Elem_AC2D4_NL_UL
    USE PH_Elem_AC2D6, ONLY: PH_Elem_AC2D6_NL_UL
    USE PH_Elem_AC2D8, ONLY: PH_Elem_AC2D8_NL_UL
    USE PH_Elem_AC3D4, ONLY: PH_Elem_AC3D4_NL_UL
    USE PH_Elem_AC3D6, ONLY: PH_Elem_AC3D6_NL_UL
    USE PH_Elem_AC3D8, ONLY: PH_Elem_AC3D8_NL_UL
    USE PH_Elem_AC3D10, ONLY: PH_Elem_AC3D10_NL_UL
    USE PH_Elem_AC3D15, ONLY: PH_Elem_AC3D15_NL_UL
    USE PH_Elem_AC3D20, ONLY: PH_Elem_AC3D20_NL_UL
    USE PH_Elem_DC2D3_Definition, ONLY: PH_Elem_DC2D3_NL_UL
    USE PH_Elem_DC2D4_Definition, ONLY: PH_Elem_DC2D4_NL_UL
    USE PH_Elem_DC2D6_Definition, ONLY: PH_Elem_DC2D6_NL_UL
    USE PH_Elem_DC2D8_Definition, ONLY: PH_Elem_DC2D8_NL_UL
    USE PH_Elem_DC3D4_Definition, ONLY: PH_Elem_DC3D4_NL_UL
    USE PH_Elem_DC3D6_Definition, ONLY: PH_Elem_DC3D6_NL_UL
    USE PH_Elem_DC3D8_Definition, ONLY: PH_Elem_DC3D8_NL_UL
    USE PH_Elem_DC3D10_Definition, ONLY: PH_Elem_DC3D10_NL_UL
    USE PH_Elem_DC3D15_Definition, ONLY: PH_Elem_DC3D15_NL_UL
    USE PH_Elem_DC3D20_Definition, ONLY: PH_Elem_DC3D20_NL_UL
    
    INTEGER(i4), INTENT(IN) :: elem_type_id
    REAL(wp), INTENT(IN) :: coords_prev(:,:)
    REAL(wp), INTENT(IN) :: u_incr(:)
    REAL(wp), INTENT(IN) :: D(:,:)
    REAL(wp), INTENT(IN), OPTIONAL :: extra_params(:)
    REAL(wp), INTENT(OUT) :: Ke_mat(:,:)
    REAL(wp), INTENT(OUT) :: Ke_geo(:,:)
    REAL(wp), INTENT(OUT) :: R_int(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: thickness, area, Iy, Iz, k_hyd, alpha_b
    INTEGER(i4) :: n_layers, n_section_pts

    status%status_code = IF_STATUS_SUCCESS

    IF (.NOT. nl_registry(elem_type_id)%is_registered) THEN
      status%status_code = IF_STATUS_ERROR
      ! status%msg removed - use init_error_status for messaging
      RETURN
    END IF

    ! Dispatch to specific element family UL routine
    SELECT CASE (elem_type_id)

      CASE (RT_ASM_ELEM_TYPE_C3D8)
        ! C3D8: 3D hex (3, 8) coords, 24 DOF, variant via extra_params(1)
        ! Direct call L4_PH PH_Elem_C3D8_NL_UL_FromD
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 1) THEN
          variant = INT(extra_params(1), i4)
        ELSE
          variant = 1  ! STANDARD
        END IF
        CALL PH_Elem_C3D8_NL_UL_FromD(coords_prev(1:3, 1:8), u_incr(1:24), D(1:6, 1:6), &
                                 Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status, variant)

      CASE (RT_ASM_ELEM_TYPE_S4)
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 3
        END IF
        CALL PH_Elem_S4_NL_UL(coords_prev(1:3, 1:4), u_incr(1:24), D(1:6, 1:6), &
                               thickness, n_layers, &
                               Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status)

      CASE (RT_ASM_ELEM_TYPE_B31)
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
          Iy = extra_params(2)
          Iz = extra_params(3)
          n_section_pts = INT(extra_params(4), i4)
        ELSE
          area = 1.0_wp
          Iy = 1.0_wp
          Iz = 1.0_wp
          n_section_pts = 4
        END IF
        CALL PH_Elem_B31_NL_UL(coords_prev(1:3, 1:2), u_incr(1:12), D(1:6, 1:6), &
                                area, Iy, Iz, n_section_pts, &
                                Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CPE4)
        CALL PH_Elem_CPE4_NL_UL(coords_prev(1:2, 1:4), u_incr(1:8), D(1:3, 1:3), &
                                 Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)

      CASE (RT_ASM_ELEM_TYPE_C3D10)
        CALL PH_Elem_C3D10_NL_UL(coords_prev(1:3, 1:10), u_incr(1:30), D(1:6, 1:6), &
                                  Ke_mat(1:30, 1:30), Ke_geo(1:30, 1:30), R_int(1:30), status)

      CASE (RT_ASM_ELEM_TYPE_C3D20)
        ! C3D20: 20-node hex (3, 20) coords, 60 DOF, variant via extra_params(1)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 1) THEN
          variant = INT(extra_params(1), i4)
        ELSE
          variant = 1  ! STANDARD
        END IF
        CALL PH_Elem_C3D20_NL_UL(coords_prev(1:3, 1:20), u_incr(1:60), D(1:6, 1:6), &
                                  Ke_mat(1:60, 1:60), Ke_geo(1:60, 1:60), R_int(1:60), status, variant)

      CASE (RT_ASM_ELEM_TYPE_S4R)
        ! S4R: Use S4 with reduced integration
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 1
        END IF
        CALL PH_Elem_S4_NL_UL(coords_prev(1:3, 1:4), u_incr(1:24), D(1:6, 1:6), &
                               thickness, n_layers, &
                               Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status)

      CASE (RT_ASM_ELEM_TYPE_T3D2)
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_T3D2_NL_UL(coords_prev(1:3, 1:2), u_incr(1:6), &
                                 D(1,1), area, &
                                 Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_S3RS, RT_ASM_ELEM_TYPE_S3)
        ! S3: 3-node triangle shell (unified implementation)
        ! S3RS is deprecated, use S3 instead
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 3
        END IF
        CALL PH_Elem_S3_NL_UL(coords_prev(1:3, 1:3), u_incr(1:18), D(1:6, 1:6), &
                              thickness, n_layers, &
                              Ke_mat(1:18, 1:18), Ke_geo(1:18, 1:18), R_int(1:18), status)

      CASE (RT_ASM_ELEM_TYPE_S8R5, RT_ASM_ELEM_TYPE_S8)
        ! S8: 8-node shell (unified implementation)
        ! S8R5 is deprecated, use S8 instead (note: S8R5 had 40 DOF, S8 has 48 DOF)
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 3
        END IF
        CALL PH_Elem_S8_NL_UL(coords_prev(1:3, 1:8), u_incr(1:48), D(1:6, 1:6), &
                              thickness, n_layers, &
                              Ke_mat(1:48, 1:48), Ke_geo(1:48, 1:48), R_int(1:48), status)

      CASE (RT_ASM_ELEM_TYPE_S9)
        ! S9: 9-node shell (unified implementation)
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
          n_layers = INT(extra_params(2), i4)
        ELSE
          thickness = 1.0_wp
          n_layers = 3
        END IF
        CALL PH_Elem_S9_NL_UL(coords_prev(1:3, 1:9), u_incr(1:54), D(1:6, 1:6), &
                              thickness, n_layers, &
                              Ke_mat(1:54, 1:54), Ke_geo(1:54, 1:54), R_int(1:54), status)

      CASE (RT_ASM_ELEM_TYPE_C3D4)
        CALL PH_Elem_C3D4_NL_UL(coords_prev(1:3, 1:4), u_incr(1:12), D(1:6, 1:6), &
                                 Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_T2D2)
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_T2D2_NL_UL(coords_prev(1:2, 1:2), u_incr(1:4), &
                                 D(1,1), area, &
                                 Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)

      CASE (RT_ASM_ELEM_TYPE_T3D3)
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_T3D3_NL_UL(coords_prev(1:3, 1:3), u_incr(1:9), &
                                 D(1,1), area, &
                                 Ke_mat(1:9, 1:9), Ke_geo(1:9, 1:9), R_int(1:9), status)

      CASE (RT_ASM_ELEM_TYPE_CPE3)
        CALL PH_Elem_CPE3_NL_UL(coords_prev(1:2, 1:3), u_incr(1:6), D(1:3, 1:3), &
                                 Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_CPE6)
        CALL PH_Elem_CPE6_NL_UL(coords_prev(1:2, 1:6), u_incr(1:12), D(1:3, 1:3), &
                                 Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CPE8)
        CALL PH_Elem_CPE8_NL_UL(coords_prev(1:2, 1:8), u_incr(1:16), D(1:3, 1:3), &
                                 Ke_mat(1:16, 1:16), Ke_geo(1:16, 1:16), R_int(1:16), status)

      CASE (RT_ASM_ELEM_TYPE_CAX3)
        CALL PH_Elem_CAX3_NL_UL(coords_prev(1:2, 1:3), u_incr(1:6), D(1:4, 1:4), &
                                 Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_C3D6)
        CALL PH_Elem_C3D6_NL_UL(coords_prev(1:3, 1:6), u_incr(1:18), D(1:6, 1:6), &
                                 Ke_mat(1:18, 1:18), Ke_geo(1:18, 1:18), R_int(1:18), status)

      CASE (RT_ASM_ELEM_TYPE_C3D15)
        CALL PH_Elem_C3D15_NL_UL(coords_prev(1:3, 1:15), u_incr(1:45), D(1:6, 1:6), &
                                  Ke_mat(1:45, 1:45), Ke_geo(1:45, 1:45), R_int(1:45), status)

      CASE (RT_ASM_ELEM_TYPE_C3D27)
        CALL PH_Elem_C3D27_NL_UL(coords_prev(1:3, 1:27), u_incr(1:81), D(1:6, 1:6), &
                                  Ke_mat(1:81, 1:81), Ke_geo(1:81, 1:81), R_int(1:81), status)

      CASE (RT_ASM_ELEM_TYPE_B32)
        CALL PH_Elem_B32_NL_UL(coords_prev(1:3, 1:2), u_incr(1:12), D(1:1, 1:1), &
                                Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CAX4)
        CALL PH_Elem_CAX4_NL_UL(coords_prev(1:2, 1:4), u_incr(1:8), D(1:4, 1:4), &
                                 Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)

      CASE (RT_ASM_ELEM_TYPE_CAX6)
        CALL PH_Elem_CAX6_NL_UL(coords_prev(1:2, 1:6), u_incr(1:12), D(1:4, 1:4), &
                                 Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CAX8)
        CALL PH_Elem_CAX8_NL_UL(coords_prev(1:2, 1:8), u_incr(1:16), D(1:4, 1:4), &
                                 Ke_mat(1:16, 1:16), Ke_geo(1:16, 1:16), R_int(1:16), status)

      CASE (RT_ASM_ELEM_TYPE_CPS6)
        CALL PH_Elem_CPS6_NL_UL(coords_prev(1:2, 1:6), u_incr(1:12), D(1:3, 1:3), &
                                 Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_CPS3)
        CALL PH_Elem_CPS3_NL_UL(coords_prev(1:2, 1:3), u_incr(1:6), D(1:3, 1:3), &
                                 Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_CPS4)
        CALL PH_Elem_CPS4_NL_UL(coords_prev(1:2, 1:4), u_incr(1:8), D(1:3, 1:3), &
                                 Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)

      CASE (RT_ASM_ELEM_TYPE_CPS8)
        CALL PH_Elem_CPS8_NL_UL(coords_prev(1:2, 1:8), u_incr(1:16), D(1:3, 1:3), &
                                 Ke_mat(1:16, 1:16), Ke_geo(1:16, 1:16), R_int(1:16), status)

      CASE (RT_ASM_ELEM_TYPE_C3D8R)
        ! C3D8R: Use C3D8 with VARIANT_REDUCED (1-point + hourglass)
        variant = 2  ! REDUCED
        CALL PH_Elem_C3D8_NL_UL(coords_prev(1:3, 1:8), u_incr(1:24), D(1:6, 1:6), &
                                 Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status, variant)

      CASE (RT_ASM_ELEM_TYPE_C3D20R)
        ! C3D20R: Use C3D20 with VARIANT_REDUCED (2?? vs 3??)
        variant = 2  ! REDUCED
        CALL PH_Elem_C3D20_NL_UL(coords_prev(1:3, 1:20), u_incr(1:60), D(1:6, 1:6), &
                                  Ke_mat(1:60, 1:60), Ke_geo(1:60, 1:60), R_int(1:60), status, variant)

      CASE (RT_ASM_ELEM_TYPE_M3D9R)
        IF (PRESENT(extra_params)) THEN
          thickness = extra_params(1)
        ELSE
          thickness = 1.0_wp
        END IF
        CALL PH_Elem_M3D9R_NL_UL(coords_prev(1:3, 1:4), u_incr(1:12), D(1:6, 1:6), &
                                  thickness, Ke_mat(1:12, 1:12), Ke_geo(1:12, 1:12), R_int(1:12), status)

      CASE (RT_ASM_ELEM_TYPE_PIPE21)
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_PIPE21_NL_UL(coords_prev(1:3, 1:2), u_incr(1:6), D(1:6, 1:6), area, &
                                   Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_PIPE22)
        IF (PRESENT(extra_params)) THEN
          area = extra_params(1)
        ELSE
          area = 1.0_wp
        END IF
        CALL PH_Elem_PIPE22_NL_UL(coords_prev(1:3, 1:2), u_incr(1:6), D(1:6, 1:6), area, &
                                   Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)

      CASE (RT_ASM_ELEM_TYPE_AC2D4)
        CALL PH_Elem_AC2D4_NL_UL(coords_prev(1:2, 1:4), u_incr(1:4), D(1:1, 1:1), &
                                  Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)
      CASE (RT_ASM_ELEM_TYPE_AC2D6)
        CALL PH_Elem_AC2D6_NL_UL(coords_prev(1:2, 1:6), u_incr(1:6), D(1:1, 1:1), &
                                  Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)
      CASE (RT_ASM_ELEM_TYPE_AC2D8)
        CALL PH_Elem_AC2D8_NL_UL(coords_prev(1:2, 1:8), u_incr(1:8), D(1:1, 1:1), &
                                  Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D4)
        CALL PH_Elem_AC3D4_NL_UL(coords_prev(1:3, 1:4), u_incr(1:4), D(1:1, 1:1), &
                                  Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D6)
        CALL PH_Elem_AC3D6_NL_UL(coords_prev(1:3, 1:6), u_incr(1:6), D(1:1, 1:1), &
                                  Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D8)
        CALL PH_Elem_AC3D8_NL_UL(coords_prev(1:3, 1:8), u_incr(1:8), D(1:1, 1:1), &
                                  Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D10)
        CALL PH_Elem_AC3D10_NL_UL(coords_prev(1:3, 1:10), u_incr(1:10), D(1:1, 1:1), &
                                   Ke_mat(1:10, 1:10), Ke_geo(1:10, 1:10), R_int(1:10), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D15)
        CALL PH_Elem_AC3D15_NL_UL(coords_prev(1:3, 1:15), u_incr(1:15), D(1:1, 1:1), &
                                   Ke_mat(1:15, 1:15), Ke_geo(1:15, 1:15), R_int(1:15), status)
      CASE (RT_ASM_ELEM_TYPE_AC3D20)
        CALL PH_Elem_AC3D20_NL_UL(coords_prev(1:3, 1:20), u_incr(1:20), D(1:1, 1:1), &
                                   Ke_mat(1:20, 1:20), Ke_geo(1:20, 1:20), R_int(1:20), status)

      CASE (RT_ASM_ELEM_TYPE_DC2D3)
        CALL PH_Elem_DC2D3_NL_UL(coords_prev(1:3, 1:3), u_incr(1:3), D(1:1, 1:1), &
                                  Ke_mat(1:3, 1:3), Ke_geo(1:3, 1:3), R_int(1:3), status)
      CASE (RT_ASM_ELEM_TYPE_DC2D4)
        CALL PH_Elem_DC2D4_NL_UL(coords_prev(1:3, 1:4), u_incr(1:4), D(1:1, 1:1), &
                                  Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)
      CASE (RT_ASM_ELEM_TYPE_DC2D6)
        CALL PH_Elem_DC2D6_NL_UL(coords_prev(1:3, 1:6), u_incr(1:6), D(1:1, 1:1), &
                                  Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)
      CASE (RT_ASM_ELEM_TYPE_DC2D8)
        CALL PH_Elem_DC2D8_NL_UL(coords_prev(1:3, 1:8), u_incr(1:8), D(1:1, 1:1), &
                                  Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D4)
        CALL PH_Elem_DC3D4_NL_UL(coords_prev(1:3, 1:4), u_incr(1:4), D(1:1, 1:1), &
                                  Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D6)
        CALL PH_Elem_DC3D6_NL_UL(coords_prev(1:3, 1:6), u_incr(1:6), D(1:1, 1:1), &
                                  Ke_mat(1:6, 1:6), Ke_geo(1:6, 1:6), R_int(1:6), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D8)
        CALL PH_Elem_DC3D8_NL_UL(coords_prev(1:3, 1:8), u_incr(1:8), D(1:1, 1:1), &
                                  Ke_mat(1:8, 1:8), Ke_geo(1:8, 1:8), R_int(1:8), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D10)
        CALL PH_Elem_DC3D10_NL_UL(coords_prev(1:3, 1:10), u_incr(1:10), D(1:1, 1:1), &
                                   Ke_mat(1:10, 1:10), Ke_geo(1:10, 1:10), R_int(1:10), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D15)
        CALL PH_Elem_DC3D15_NL_UL(coords_prev(1:3, 1:15), u_incr(1:15), D(1:1, 1:1), &
                                   Ke_mat(1:15, 1:15), Ke_geo(1:15, 1:15), R_int(1:15), status)
      CASE (RT_ASM_ELEM_TYPE_DC3D20)
        CALL PH_Elem_DC3D20_NL_UL(coords_prev(1:3, 1:20), u_incr(1:20), D(1:1, 1:1), &
                                   Ke_mat(1:20, 1:20), Ke_geo(1:20, 1:20), R_int(1:20), status)

      CASE (RT_ASM_ELEM_TYPE_C3D8P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D8P_NL_UL(coords_prev(1:3, 1:8), u_incr(1:32), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:32, 1:32), Ke_geo(1:32, 1:32), R_int(1:32), status)

      CASE (RT_ASM_ELEM_TYPE_C3D4P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D4P_NL_UL(coords_prev(1:3, 1:4), u_incr(1:16), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:16, 1:16), Ke_geo(1:16, 1:16), R_int(1:16), status)

      CASE (RT_ASM_ELEM_TYPE_C3D6P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D6P_NL_UL(coords_prev(1:3, 1:6), u_incr(1:24), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:24, 1:24), Ke_geo(1:24, 1:24), R_int(1:24), status)

      CASE (RT_ASM_ELEM_TYPE_C3D10P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D10P_NL_UL(coords_prev(1:3, 1:10), u_incr(1:40), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:40, 1:40), Ke_geo(1:40, 1:40), R_int(1:40), status)

      CASE (RT_ASM_ELEM_TYPE_C3D15P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D15P_NL_UL(coords_prev(1:3, 1:15), u_incr(1:60), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:60, 1:60), Ke_geo(1:60, 1:60), R_int(1:60), status)

      CASE (RT_ASM_ELEM_TYPE_C3D20P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D20P_NL_UL(coords_prev(1:3, 1:20), u_incr(1:80), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:80, 1:80), Ke_geo(1:80, 1:80), R_int(1:80), status)

      CASE (RT_ASM_ELEM_TYPE_C3D27P)
        IF (PRESENT(extra_params) .AND. SIZE(extra_params) >= 2) THEN
          k_hyd = extra_params(1)
          alpha_b = extra_params(2)
        ELSE
          k_hyd = 1.0_wp
          alpha_b = 1.0_wp
        END IF
        CALL PH_Elem_C3D27P_NL_UL(coords_prev(1:3, 1:27), u_incr(1:108), D(1:6, 1:6), &
                                  k_hyd, alpha_b, &
                                  Ke_mat(1:108, 1:108), Ke_geo(1:108, 1:108), R_int(1:108), status)

      CASE (RT_ASM_ELEM_TYPE_SPRING1)
        CALL PH_Elem_SPRING1_NL_UL(coords_prev(1:3, 1:2), u_incr(1:2), D(1:1, 1:1), &
                                    Ke_mat(1:2, 1:2), Ke_geo(1:2, 1:2), R_int(1:2), status)

      CASE (RT_ASM_ELEM_TYPE_SPRING2)
        CALL PH_Elem_SPRING2_NL_UL(coords_prev(1:3, 1:2), u_incr(1:4), D(1:1, 1:1), &
                                    Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)

      CASE (RT_ASM_ELEM_TYPE_DASHPOT1)
        CALL PH_Elem_DASHPOT1_NL_UL(coords_prev(1:3, 1:2), u_incr(1:2), D(1:1, 1:1), &
                                     Ke_mat(1:2, 1:2), Ke_geo(1:2, 1:2), R_int(1:2), status)

      CASE (RT_ASM_ELEM_TYPE_DASHPOT2)
        CALL PH_Elem_DASHPOT2_NL_UL(coords_prev(1:3, 1:2), u_incr(1:4), D(1:1, 1:1), &
                                     Ke_mat(1:4, 1:4), Ke_geo(1:4, 1:4), R_int(1:4), status)

      CASE DEFAULT
        status%status_code = IF_STATUS_ERROR
        ! status%msg removed - use init_error_status for messaging

    END SELECT

  END SUBROUTINE RT_Asm_NLGeom_Dispatch_UL

END MODULE RT_Asm_NLGeomDispatch