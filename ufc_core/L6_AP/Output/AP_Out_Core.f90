!===============================================================================
! Module:  AP_Output_Core
! Layer:   L6_AP - Application System Layer
! Domain:  Output
! Purpose: Report writing and VTK file output.
!
! Signature: (desc, ctx, ..., status)
!   desc — AP_Output_Desc [IN]    output unit and path
!   ctx  — AP_Output_Ctx  [INOUT] format buffer
!
! Status: ACTIVE | Last verified: 2026-04-25
!===============================================================================
MODULE AP_Out_Core
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Out_Def,  ONLY: AP_Output_Desc, AP_Output_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Output_Core_Init
  PUBLIC :: AP_Output_Core_Finalize
  PUBLIC :: AP_Output_Write_Report
  PUBLIC :: AP_Output_Write_Summary_Table
  PUBLIC :: AP_Output_Write_VTK_Header
  PUBLIC :: AP_Output_Write_VTK_Nodes
  PUBLIC :: AP_Output_Write_VTK_Cells
  PUBLIC :: AP_Output_Write_VTK_Point_Vector
  PUBLIC :: AP_Output_Write_VTK_Point_Scalar
  PUBLIC :: AP_Output_Write_VTK_Full

CONTAINS

  SUBROUTINE AP_Output_Core_Init(desc, ctx, status)
    TYPE(AP_Output_Desc),  INTENT(IN)  :: desc
    TYPE(AP_Output_Ctx),   INTENT(OUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ctx%format_buffer = ""
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Core_Init

  SUBROUTINE AP_Output_Core_Finalize(desc, ctx, status)
    TYPE(AP_Output_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Output_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ctx%format_buffer = ""
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Core_Finalize

  !---------------------------------------------------------------------------
  ! Write a titled report section
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Output_Write_Report(desc, ctx, title, body, status)
    TYPE(AP_Output_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Output_Ctx),   INTENT(INOUT) :: ctx
    CHARACTER(LEN=*),      INTENT(IN)    :: title
    CHARACTER(LEN=*),      INTENT(IN)    :: body
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    WRITE(desc%report_unit, '(A)') "--- " // TRIM(title) // " ---"
    WRITE(desc%report_unit, '(A)') TRIM(body)
    WRITE(desc%report_unit, '(A)') ""
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Write_Report

  !---------------------------------------------------------------------------
  ! Write summary table (placeholder)
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Output_Write_Summary_Table(desc, ctx, n_rows, headers, values, status)
    TYPE(AP_Output_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Output_Ctx),   INTENT(INOUT) :: ctx
    INTEGER(i4),           INTENT(IN)    :: n_rows
    CHARACTER(LEN=*),      INTENT(IN)    :: headers
    REAL(wp),              INTENT(IN)    :: values(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    WRITE(desc%report_unit, '(A)') TRIM(headers)
    DO i = 1, n_rows
      IF (i <= SIZE(values)) THEN
        WRITE(desc%report_unit, '(I6,ES14.6)') i, values(i)
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Write_Summary_Table

  !---------------------------------------------------------------------------
  ! Write VTK legacy header (placeholder)
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Output_Write_VTK_Header(desc, ctx, filename, n_nodes, n_elem, status)
    TYPE(AP_Output_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Output_Ctx),   INTENT(INOUT) :: ctx
    CHARACTER(LEN=*),      INTENT(IN)    :: filename
    INTEGER(i4),           INTENT(IN)    :: n_nodes
    INTEGER(i4),           INTENT(IN)    :: n_elem
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: iu, ios

    CALL init_error_status(status)
    OPEN(NEWUNIT=iu, FILE=TRIM(filename), STATUS='REPLACE', &
         ACTION='WRITE', IOSTAT=ios)
    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Output_Write_VTK_Header]: cannot open file"
      RETURN
    END IF

    WRITE(iu, '(A)') "# vtk DataFile Version 3.0"
    WRITE(iu, '(A)') "UFC output"
    WRITE(iu, '(A)') "ASCII"
    WRITE(iu, '(A)') "DATASET UNSTRUCTURED_GRID"
    WRITE(iu, '(A,I0,A)') "POINTS ", n_nodes, " double"
    CLOSE(iu)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Write_VTK_Header

  !---------------------------------------------------------------------------
  ! Write VTK node coordinates
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Output_Write_VTK_Nodes(desc, ctx, n_nodes, ndim, coords, status)
    TYPE(AP_Output_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Output_Ctx),   INTENT(INOUT) :: ctx
    INTEGER(i4),           INTENT(IN)    :: n_nodes
    INTEGER(i4),           INTENT(IN)    :: ndim
    REAL(wp),              INTENT(IN)    :: coords(ndim, n_nodes)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    DO i = 1, n_nodes
      IF (ndim == 2) THEN
        WRITE(desc%report_unit, '(3ES14.6)') coords(1, i), coords(2, i), 0.0_wp
      ELSE
        WRITE(desc%report_unit, '(3ES14.6)') coords(1, i), coords(2, i), coords(3, i)
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Write_VTK_Nodes

  !---------------------------------------------------------------------------
  ! Write VTK cell connectivity
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Output_Write_VTK_Cells(desc, ctx, n_elem, max_nn, conn, status)
    TYPE(AP_Output_Desc),  INTENT(IN)    :: desc
    TYPE(AP_Output_Ctx),   INTENT(INOUT) :: ctx
    INTEGER(i4),           INTENT(IN)    :: n_elem
    INTEGER(i4),           INTENT(IN)    :: max_nn
    INTEGER(i4),           INTENT(IN)    :: conn(max_nn, n_elem)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)
    DO i = 1, n_elem
      WRITE(desc%report_unit, '(I4)', ADVANCE='NO') max_nn
      DO j = 1, max_nn
        WRITE(desc%report_unit, '(I8)', ADVANCE='NO') conn(j, i)
      END DO
      WRITE(desc%report_unit, '(A)') ""
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Write_VTK_Cells

  !---------------------------------------------------------------------------
  ! Write VTK point data header + vector field (e.g., displacements)
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Output_Write_VTK_Point_Vector(unit_num, field_name, &
                                               n_nodes, ndim, data, status)
    INTEGER(i4),        INTENT(IN)    :: unit_num
    CHARACTER(LEN=*),   INTENT(IN)    :: field_name
    INTEGER(i4),        INTENT(IN)    :: n_nodes
    INTEGER(i4),        INTENT(IN)    :: ndim
    REAL(wp),           INTENT(IN)    :: data(ndim, n_nodes)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    WRITE(unit_num, '(A,A,A)') "VECTORS ", TRIM(field_name), " double"
    DO i = 1, n_nodes
      IF (ndim == 2) THEN
        WRITE(unit_num, '(3ES14.6)') data(1,i), data(2,i), 0.0_wp
      ELSE
        WRITE(unit_num, '(3ES14.6)') data(1,i), data(2,i), data(3,i)
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Write_VTK_Point_Vector

  !---------------------------------------------------------------------------
  ! Write VTK scalar point data (e.g., von Mises stress)
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Output_Write_VTK_Point_Scalar(unit_num, field_name, &
                                                n_nodes, data, status)
    INTEGER(i4),        INTENT(IN)    :: unit_num
    CHARACTER(LEN=*),   INTENT(IN)    :: field_name
    INTEGER(i4),        INTENT(IN)    :: n_nodes
    REAL(wp),           INTENT(IN)    :: data(n_nodes)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    WRITE(unit_num, '(A,A,A)') "SCALARS ", TRIM(field_name), " double 1"
    WRITE(unit_num, '(A)') "LOOKUP_TABLE default"
    DO i = 1, n_nodes
      WRITE(unit_num, '(ES14.6)') data(i)
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Write_VTK_Point_Scalar

  !---------------------------------------------------------------------------
  ! Write complete VTK file: header + nodes + cells + displacement field
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Output_Write_VTK_Full(filename, n_nodes, n_elem, ndim, &
                                       max_nn, coords, conn, u, status)
    CHARACTER(LEN=*), INTENT(IN) :: filename
    INTEGER(i4),      INTENT(IN) :: n_nodes, n_elem, ndim, max_nn
    REAL(wp),         INTENT(IN) :: coords(ndim, n_nodes)
    INTEGER(i4),      INTENT(IN) :: conn(max_nn, n_elem)
    REAL(wp),         INTENT(IN) :: u(ndim, n_nodes)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: iu, ios, i, j, vtk_type

    CALL init_error_status(status)
    OPEN(NEWUNIT=iu, FILE=TRIM(filename), STATUS='REPLACE', &
         ACTION='WRITE', IOSTAT=ios)
    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Output_Write_VTK_Full]: cannot open file"
      RETURN
    END IF

    WRITE(iu, '(A)') "# vtk DataFile Version 3.0"
    WRITE(iu, '(A)') "UFC FEM results"
    WRITE(iu, '(A)') "ASCII"
    WRITE(iu, '(A)') "DATASET UNSTRUCTURED_GRID"
    WRITE(iu, '(A,I0,A)') "POINTS ", n_nodes, " double"

    DO i = 1, n_nodes
      IF (ndim == 2) THEN
        WRITE(iu, '(3ES16.8)') coords(1,i), coords(2,i), 0.0_wp
      ELSE
        WRITE(iu, '(3ES16.8)') coords(1,i), coords(2,i), coords(3,i)
      END IF
    END DO

    WRITE(iu, '(A,I0,A,I0)') "CELLS ", n_elem, " ", n_elem * (max_nn + 1)
    DO i = 1, n_elem
      WRITE(iu, '(I4)', ADVANCE='NO') max_nn
      DO j = 1, max_nn
        WRITE(iu, '(I8)', ADVANCE='NO') conn(j,i) - 1
      END DO
      WRITE(iu, '(A)') ""
    END DO

    SELECT CASE(max_nn)
      CASE(4);  vtk_type = 10  ! VTK_TETRA
      CASE(8);  vtk_type = 12  ! VTK_HEXAHEDRON
      CASE(3);  vtk_type = 5   ! VTK_TRIANGLE
      CASE(2);  vtk_type = 3   ! VTK_LINE
      CASE DEFAULT; vtk_type = 12
    END SELECT
    WRITE(iu, '(A,I0)') "CELL_TYPES ", n_elem
    DO i = 1, n_elem
      WRITE(iu, '(I4)') vtk_type
    END DO

    WRITE(iu, '(A,I0)') "POINT_DATA ", n_nodes
    CALL AP_Output_Write_VTK_Point_Vector(iu, "Displacement", &
                                           n_nodes, ndim, u, status)

    CLOSE(iu)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Write_VTK_Full

END MODULE AP_Out_Core
