!===============================================================================
! MODULE:  MD_Elem_InpMap
! LAYER:   L3_MD
! DOMAIN:  Element / Elem
! ROLE:    _Impl
! BRIEF:   Element INP mapping — P1 Map: ABAQUS *ELEMENT TYPE strings
!          to MD_MESH_ELEM_* codes.
!===============================================================================
!
! Contract:
!   - Output elem_type is always an MD_Elem_Algo PARAMETER (L3 enum).
!   - n_nodes matches Abaqus connectivity line length for that type.
!   - Unknown / empty string -> IF_STATUS_INVALID.
!
! See: PH_L4_Populate_Element copies mesh%raw_data%element_types(:) -> elem_type_cache.
!======================================================================
!>>> UFC_L3_QUENCH | Domain:Element | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Element/Elem/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Element | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Elem_InpMap
  USE IF_Prec_Core, ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Elem_Mgr, ONLY: &
       MD_MESH_ELEM_C3D4, MD_MESH_ELEM_C3D10, MD_MESH_ELEM_C3D10M, MD_MESH_ELEM_C3D10E, MD_MESH_ELEM_C3D10R, &
       MD_MESH_ELEM_C3D8, MD_MESH_ELEM_C3D8R, MD_MESH_ELEM_C3D8I, MD_MESH_ELEM_C3D8H, &
       MD_MESH_ELEM_C3D20, MD_MESH_ELEM_C3D20R, MD_MESH_ELEM_C3D20H, MD_MESH_ELEM_C3D20I, &
       MD_MESH_ELEM_C3D27, MD_MESH_ELEM_C3D27R, &
       MD_MESH_ELEM_C3D6, MD_MESH_ELEM_C3D15, MD_MESH_ELEM_C3D6R, MD_MESH_ELEM_C3D15R, &
       MD_MESH_ELEM_C3D5, MD_MESH_ELEM_C3D13, &
       MD_MESH_ELEM_C3D4T, MD_MESH_ELEM_C3D6T, MD_MESH_ELEM_C3D8T, MD_MESH_ELEM_C3D10T, MD_MESH_ELEM_C3D15T, &
       MD_MESH_ELEM_C3D20T, MD_MESH_ELEM_C3D27T, &
       MD_MESH_ELEM_C3D4P, MD_MESH_ELEM_C3D6P, MD_MESH_ELEM_C3D8P, MD_MESH_ELEM_C3D10P, MD_MESH_ELEM_C3D15P, MD_MESH_ELEM_C3D20P, MD_MESH_ELEM_C3D27P, MD_MESH_ELEM_C3D8PT, &
       MD_MESH_ELEM_CPE4, MD_MESH_ELEM_CPE4R, MD_MESH_ELEM_CPE4H, MD_MESH_ELEM_CPE4I, &
       MD_MESH_ELEM_CPE8, MD_MESH_ELEM_CPE8R, MD_MESH_ELEM_CPE8H, MD_MESH_ELEM_CPE8I, &
       MD_MESH_ELEM_CPS4, MD_MESH_ELEM_CPS4R, MD_MESH_ELEM_CPS4I, MD_MESH_ELEM_CPS8, MD_MESH_ELEM_CPS8R, &
       MD_MESH_ELEM_CAX4, MD_MESH_ELEM_CAX4R, MD_MESH_ELEM_CAX4H, MD_MESH_ELEM_CAX8, MD_MESH_ELEM_CAX8R, &
       MD_MESH_ELEM_CAX8I, MD_MESH_ELEM_CAX8H, &
       MD_MESH_ELEM_CPE4T, MD_MESH_ELEM_CPE8T, MD_MESH_ELEM_CPS4T, MD_MESH_ELEM_CPS8T, &
       MD_MESH_ELEM_CAX4T, MD_MESH_ELEM_CAX8T, &
       MD_MESH_ELEM_CPE4P, MD_MESH_ELEM_CPE8P, MD_MESH_ELEM_CAX4P, MD_MESH_ELEM_CAX8P, &
       MD_MESH_ELEM_S3, MD_MESH_ELEM_S3R, MD_MESH_ELEM_STRI3, MD_MESH_ELEM_S6, MD_MESH_ELEM_STRI65, &
       MD_MESH_ELEM_S4, MD_MESH_ELEM_S4R, MD_MESH_ELEM_S4T, MD_MESH_ELEM_S8, MD_MESH_ELEM_S8R, MD_MESH_ELEM_S8R5, MD_MESH_ELEM_S8RT, &
       MD_MESH_ELEM_B21, MD_MESH_ELEM_B21H, MD_MESH_ELEM_B21T, &
       MD_MESH_ELEM_B31, MD_MESH_ELEM_B31H, MD_MESH_ELEM_B31T, MD_MESH_ELEM_B32, MD_MESH_ELEM_B32H, &
       MD_MESH_ELEM_T3D2, MD_MESH_ELEM_T3D2H, MD_MESH_ELEM_T3D3, MD_MESH_ELEM_T3D3H
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Elem_MapAbqTypeString

CONTAINS

  !> Map Abaqus element type label (e.g. C3D8T, C3D4T) to L3 `MD_MESH_ELEM_*` and `n_nodes`.
  SUBROUTINE MD_Elem_MapAbqTypeString(abq_type, elem_type, n_nodes, status)
    CHARACTER(LEN=*),      INTENT(IN)  :: abq_type
    INTEGER(i4),           INTENT(OUT) :: elem_type, n_nodes
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(LEN=64) :: k

    CALL init_error_status(status)
    elem_type = 0_i4
    n_nodes = 0_i4

    k = TRIM(ADJUSTL(abq_type))
    IF (LEN_TRIM(k) < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Elem_MapAbqTypeString: empty TYPE string"
      RETURN
    END IF

    SELECT CASE (TRIM(k))
    ! --- 3D continuum solids ---
    CASE ("C3D4")
      elem_type = MD_MESH_ELEM_C3D4;   n_nodes = 4_i4
    CASE ("C3D10")
      elem_type = MD_MESH_ELEM_C3D10;  n_nodes = 10_i4
    CASE ("C3D10M")
      elem_type = MD_MESH_ELEM_C3D10M; n_nodes = 10_i4
    CASE ("C3D10E")
      elem_type = MD_MESH_ELEM_C3D10E; n_nodes = 10_i4
    CASE ("C3D10R")
      elem_type = MD_MESH_ELEM_C3D10R; n_nodes = 10_i4

    CASE ("C3D6")
      elem_type = MD_MESH_ELEM_C3D6;   n_nodes = 6_i4
    CASE ("C3D6R")
      elem_type = MD_MESH_ELEM_C3D6R;  n_nodes = 6_i4
    CASE ("C3D15")
      elem_type = MD_MESH_ELEM_C3D15;  n_nodes = 15_i4
    CASE ("C3D15R")
      elem_type = MD_MESH_ELEM_C3D15R; n_nodes = 15_i4

    CASE ("C3D5")
      elem_type = MD_MESH_ELEM_C3D5;   n_nodes = 5_i4
    CASE ("C3D13")
      elem_type = MD_MESH_ELEM_C3D13;  n_nodes = 13_i4

    CASE ("C3D8")
      elem_type = MD_MESH_ELEM_C3D8;   n_nodes = 8_i4
    CASE ("C3D8R")
      elem_type = MD_MESH_ELEM_C3D8R;  n_nodes = 8_i4
    CASE ("C3D8I")
      elem_type = MD_MESH_ELEM_C3D8I;  n_nodes = 8_i4
    CASE ("C3D8H")
      elem_type = MD_MESH_ELEM_C3D8H;  n_nodes = 8_i4

    CASE ("C3D20")
      elem_type = MD_MESH_ELEM_C3D20;  n_nodes = 20_i4
    CASE ("C3D20R")
      elem_type = MD_MESH_ELEM_C3D20R; n_nodes = 20_i4
    CASE ("C3D20H")
      elem_type = MD_MESH_ELEM_C3D20H; n_nodes = 20_i4
    CASE ("C3D20I")
      elem_type = MD_MESH_ELEM_C3D20I; n_nodes = 20_i4

    CASE ("C3D27")
      elem_type = MD_MESH_ELEM_C3D27;  n_nodes = 27_i4
    CASE ("C3D27R")
      elem_type = MD_MESH_ELEM_C3D27R; n_nodes = 27_i4

    ! --- 3D thermo-mechanical (*T) & pore (*P) ---
    CASE ("C3D4T")
      elem_type = MD_MESH_ELEM_C3D4T;   n_nodes = 4_i4
    CASE ("C3D6T")
      elem_type = MD_MESH_ELEM_C3D6T;   n_nodes = 6_i4
    CASE ("C3D8T")
      elem_type = MD_MESH_ELEM_C3D8T;   n_nodes = 8_i4
    CASE ("C3D10T")
      elem_type = MD_MESH_ELEM_C3D10T;  n_nodes = 10_i4
    CASE ("C3D15T")
      elem_type = MD_MESH_ELEM_C3D15T;  n_nodes = 15_i4
    CASE ("C3D20T")
      elem_type = MD_MESH_ELEM_C3D20T;  n_nodes = 20_i4
    CASE ("C3D27T")
      elem_type = MD_MESH_ELEM_C3D27T;  n_nodes = 27_i4

    CASE ("C3D4P")
      elem_type = MD_MESH_ELEM_C3D4P;   n_nodes = 4_i4
    CASE ("C3D6P")
      elem_type = MD_MESH_ELEM_C3D6P;   n_nodes = 6_i4
    CASE ("C3D8P")
      elem_type = MD_MESH_ELEM_C3D8P;   n_nodes = 8_i4
    CASE ("C3D10P")
      elem_type = MD_MESH_ELEM_C3D10P;  n_nodes = 10_i4
    CASE ("C3D15P")
      elem_type = MD_MESH_ELEM_C3D15P;  n_nodes = 15_i4
    CASE ("C3D20P")
      elem_type = MD_MESH_ELEM_C3D20P;  n_nodes = 20_i4
    CASE ("C3D27P")
      elem_type = MD_MESH_ELEM_C3D27P;  n_nodes = 27_i4
    CASE ("C3D8PT")
      elem_type = MD_MESH_ELEM_C3D8PT;  n_nodes = 8_i4

    ! --- 2D continuum (common INP names) ---
    CASE ("CPE4")
      elem_type = MD_MESH_ELEM_CPE4; n_nodes = 4_i4
    CASE ("CPE4R")
      elem_type = MD_MESH_ELEM_CPE4R; n_nodes = 4_i4
    CASE ("CPE4H")
      elem_type = MD_MESH_ELEM_CPE4H; n_nodes = 4_i4
    CASE ("CPE4I")
      elem_type = MD_MESH_ELEM_CPE4I; n_nodes = 4_i4
    CASE ("CPE8")
      elem_type = MD_MESH_ELEM_CPE8; n_nodes = 8_i4
    CASE ("CPE8R")
      elem_type = MD_MESH_ELEM_CPE8R; n_nodes = 8_i4
    CASE ("CPE8H")
      elem_type = MD_MESH_ELEM_CPE8H; n_nodes = 8_i4
    CASE ("CPE8I")
      elem_type = MD_MESH_ELEM_CPE8I; n_nodes = 8_i4

    CASE ("CPS4")
      elem_type = MD_MESH_ELEM_CPS4; n_nodes = 4_i4
    CASE ("CPS4R")
      elem_type = MD_MESH_ELEM_CPS4R; n_nodes = 4_i4
    CASE ("CPS4I")
      elem_type = MD_MESH_ELEM_CPS4I; n_nodes = 4_i4
    CASE ("CPS8")
      elem_type = MD_MESH_ELEM_CPS8; n_nodes = 8_i4
    CASE ("CPS8R")
      elem_type = MD_MESH_ELEM_CPS8R; n_nodes = 8_i4

    CASE ("CAX4")
      elem_type = MD_MESH_ELEM_CAX4; n_nodes = 4_i4
    CASE ("CAX4R")
      elem_type = MD_MESH_ELEM_CAX4R; n_nodes = 4_i4
    CASE ("CAX4H")
      elem_type = MD_MESH_ELEM_CAX4H; n_nodes = 4_i4
    CASE ("CAX8")
      elem_type = MD_MESH_ELEM_CAX8; n_nodes = 8_i4
    CASE ("CAX8R")
      elem_type = MD_MESH_ELEM_CAX8R; n_nodes = 8_i4
    CASE ("CAX8I")
      elem_type = MD_MESH_ELEM_CAX8I; n_nodes = 8_i4
    CASE ("CAX8H")
      elem_type = MD_MESH_ELEM_CAX8H; n_nodes = 8_i4

    CASE ("CPE4T")
      elem_type = MD_MESH_ELEM_CPE4T; n_nodes = 4_i4
    CASE ("CPE8T")
      elem_type = MD_MESH_ELEM_CPE8T; n_nodes = 8_i4
    CASE ("CPS4T")
      elem_type = MD_MESH_ELEM_CPS4T; n_nodes = 4_i4
    CASE ("CPS8T")
      elem_type = MD_MESH_ELEM_CPS8T; n_nodes = 8_i4
    CASE ("CAX4T")
      elem_type = MD_MESH_ELEM_CAX4T; n_nodes = 4_i4
    CASE ("CAX8T")
      elem_type = MD_MESH_ELEM_CAX8T; n_nodes = 8_i4
    CASE ("CPE4P")
      elem_type = MD_MESH_ELEM_CPE4P; n_nodes = 4_i4
    CASE ("CPE8P")
      elem_type = MD_MESH_ELEM_CPE8P; n_nodes = 8_i4
    CASE ("CAX4P")
      elem_type = MD_MESH_ELEM_CAX4P; n_nodes = 4_i4
    CASE ("CAX8P")
      elem_type = MD_MESH_ELEM_CAX8P; n_nodes = 8_i4

    ! --- Shell / beam / truss (legacy AP_InpMesh set) ---
    CASE ("S4")
      elem_type = MD_MESH_ELEM_S4;   n_nodes = 4_i4
    CASE ("S4R")
      elem_type = MD_MESH_ELEM_S4R;  n_nodes = 4_i4
    CASE ("S4T")
      elem_type = MD_MESH_ELEM_S4T;  n_nodes = 4_i4
    CASE ("S8")
      elem_type = MD_MESH_ELEM_S8;   n_nodes = 8_i4
    CASE ("S8R")
      elem_type = MD_MESH_ELEM_S8R;  n_nodes = 8_i4
    CASE ("S8R5")
      elem_type = MD_MESH_ELEM_S8R5; n_nodes = 8_i4
    CASE ("S8RT")
      elem_type = MD_MESH_ELEM_S8RT; n_nodes = 8_i4
    CASE ("S3")
      elem_type = MD_MESH_ELEM_S3;   n_nodes = 3_i4
    CASE ("S3R")
      elem_type = MD_MESH_ELEM_S3R;  n_nodes = 3_i4
    CASE ("STRI3")
      elem_type = MD_MESH_ELEM_STRI3; n_nodes = 3_i4
    CASE ("STRI65")
      elem_type = MD_MESH_ELEM_STRI65; n_nodes = 6_i4
    CASE ("S6")
      elem_type = MD_MESH_ELEM_S6; n_nodes = 6_i4

    CASE ("B21")
      elem_type = MD_MESH_ELEM_B21;  n_nodes = 2_i4
    CASE ("B21H")
      elem_type = MD_MESH_ELEM_B21H; n_nodes = 2_i4
    CASE ("B21T")
      elem_type = MD_MESH_ELEM_B21T; n_nodes = 2_i4
    CASE ("B31")
      elem_type = MD_MESH_ELEM_B31;  n_nodes = 2_i4
    CASE ("B31H")
      elem_type = MD_MESH_ELEM_B31H; n_nodes = 2_i4
    CASE ("B31T")
      elem_type = MD_MESH_ELEM_B31T; n_nodes = 2_i4
    CASE ("B32")
      elem_type = MD_MESH_ELEM_B32;  n_nodes = 3_i4
    CASE ("B32H")
      elem_type = MD_MESH_ELEM_B32H; n_nodes = 3_i4

    CASE ("T3D2")
      elem_type = MD_MESH_ELEM_T3D2;  n_nodes = 2_i4
    CASE ("T3D2H")
      elem_type = MD_MESH_ELEM_T3D2H; n_nodes = 2_i4
    CASE ("T3D3")
      elem_type = MD_MESH_ELEM_T3D3;  n_nodes = 3_i4
    CASE ("T3D3H")
      elem_type = MD_MESH_ELEM_T3D3H; n_nodes = 3_i4

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      WRITE (status%message, '(A,A)') "MD_Elem_MapAbqTypeString: unknown TYPE= ", TRIM(k)
      RETURN
    END SELECT

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Elem_MapAbqTypeString

END MODULE MD_Elem_InpMap