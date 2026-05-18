!===============================================================================
! MODULE: MD_MatELA_CoupledDesc
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Coupled elastic Desc types + keyword helpers for mat_id 108~110.
!         ThermoElastic (108), PiezoElastic (109), ThermoElecElastic (110).
!         L3 Desc only -- no stress integration.
!         **W1**：**ToProps** / 解析输出与 **Populate** **`MD_Mat_Desc%props`** 一致；L4 耦合弹性读 **`desc%props`**。
!===============================================================================
MODULE MD_Mat_Elas_Contract
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_OK, init_error_status, uf_set_error_status
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_KW_Def, ONLY: KW_ASTNodeType, KW_MAX_VALUE_LEN
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_THERMO_ELAS_MAT_ID = 108_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PIEZO_ELAS_MAT_ID = 109_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_THERMOPIEZO_ELAS_MAT_ID = 110_i4

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_NPROPS_THERMO108 = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_NPROPS_PIEZO109 = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_NPROPS_THERMOPIEZO110 = 12_i4

  INTEGER(i4), PARAMETER :: MD_MAT_MAX_FLAT = 32_i4

  PUBLIC :: MD_CoupledElas_FlattenDataLines
  PUBLIC :: MD_CoupledElas_ParseThermo108
  PUBLIC :: MD_CoupledElas_ParsePiezo109
  PUBLIC :: MD_CoupledElas_ParseThermoPiezo110
  PUBLIC :: MD_CoupledElas_Thermo108_ToProps
  PUBLIC :: MD_CoupledElas_Piezo109_ToProps
  PUBLIC :: MD_CoupledElas_ThermoPiezo110_ToProps

CONTAINS

  SUBROUTINE MD_CoupledElas_FlattenDataLines(ast_node, vals, nvals, status)
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    REAL(wp), INTENT(OUT) :: vals(:)
    INTEGER(i4), INTENT(OUT) :: nvals
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)
    nvals = 0_i4
    DO i = 1, ast_node%data_line_count
      DO j = 1, ast_node%data_lines(i)%col_count
        IF (nvals < SIZE(vals)) THEN
          nvals = nvals + 1_i4
          vals(nvals) = ast_node%data_lines(i)%real_values(j)
        END IF
      END DO
    END DO
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_CoupledElas_FlattenDataLines

  SUBROUTINE MD_CoupledElas_ParseThermo108(ast_node, E, nu, alpha, t_ref, status)
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    REAL(wp), INTENT(OUT) :: E, nu, alpha, t_ref
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: vals(MD_MAT_MAX_FLAT)
    INTEGER(i4) :: nvals

    CALL init_error_status(status)
    E = 0.0_wp
    nu = 0.0_wp
    alpha = 1.0e-5_wp
    t_ref = 293.15_wp

    CALL MD_CoupledElas_FlattenDataLines(ast_node, vals, nvals, status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
    IF (nvals < 2_i4) THEN
      CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, '*THERMO ELASTIC needs at least E, nu on data lines')
      RETURN
    END IF
    E = vals(1)
    nu = vals(2)
    IF (nvals >= 3_i4) alpha = vals(3)
    IF (nvals >= 4_i4) t_ref = vals(4)
    IF (E <= 0.0_wp) THEN
      CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, 'ThermoElastic: E must be positive')
      RETURN
    END IF
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_CoupledElas_ParseThermo108

  SUBROUTINE MD_CoupledElas_Thermo108_ToProps(E, nu, alpha, t_ref, props, nprops, status)
    REAL(wp), INTENT(IN) :: E, nu, alpha, t_ref
    REAL(wp), INTENT(OUT) :: props(:)
    INTEGER(i4), INTENT(OUT) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (SIZE(props) < MD_MAT_NPROPS_THERMO108) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_CoupledElas_Thermo108_ToProps: props too small'
      RETURN
    END IF
    nprops = MD_MAT_NPROPS_THERMO108
    props(1) = E
    props(2) = nu
    props(3) = alpha
    props(4) = t_ref
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_CoupledElas_Thermo108_ToProps

  SUBROUTINE MD_CoupledElas_ParsePiezo109(ast_node, props, nprops, status)
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    REAL(wp), INTENT(OUT) :: props(:)
    INTEGER(i4), INTENT(OUT) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: vals(MD_MAT_MAX_FLAT)
    INTEGER(i4) :: nvals, k

    CALL init_error_status(status)
    nprops = 0_i4
    IF (SIZE(props) < MD_MAT_NPROPS_PIEZO109) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_CoupledElas_ParsePiezo109: props buffer too small'
      RETURN
    END IF

    CALL MD_CoupledElas_FlattenDataLines(ast_node, vals, nvals, status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
    IF (nvals < MD_MAT_NPROPS_PIEZO109) THEN
      CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, '*PIEZO ELASTIC needs 10 property values')
      RETURN
    END IF
    DO k = 1, MD_MAT_NPROPS_PIEZO109
      props(k) = vals(k)
    END DO
    nprops = MD_MAT_NPROPS_PIEZO109
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_CoupledElas_ParsePiezo109

  SUBROUTINE MD_CoupledElas_Piezo109_ToProps(vals10, props, nprops, status)
    REAL(wp), INTENT(IN) :: vals10(:)
    REAL(wp), INTENT(OUT) :: props(:)
    INTEGER(i4), INTENT(OUT) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: k

    CALL init_error_status(status)
    IF (SIZE(vals10) < MD_MAT_NPROPS_PIEZO109 .OR. SIZE(props) < MD_MAT_NPROPS_PIEZO109) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_CoupledElas_Piezo109_ToProps: size error'
      RETURN
    END IF
    DO k = 1, MD_MAT_NPROPS_PIEZO109
      props(k) = vals10(k)
    END DO
    nprops = MD_MAT_NPROPS_PIEZO109
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_CoupledElas_Piezo109_ToProps

  SUBROUTINE MD_CoupledElas_ParseThermoPiezo110(ast_node, props, nprops, status)
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    REAL(wp), INTENT(OUT) :: props(:)
    INTEGER(i4), INTENT(OUT) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: vals(MD_MAT_MAX_FLAT)
    INTEGER(i4) :: nvals, k

    CALL init_error_status(status)
    nprops = 0_i4
    IF (SIZE(props) < MD_MAT_NPROPS_THERMOPIEZO110) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_CoupledElas_ParseThermoPiezo110: props buffer too small'
      RETURN
    END IF

    CALL MD_CoupledElas_FlattenDataLines(ast_node, vals, nvals, status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
    IF (nvals < MD_MAT_NPROPS_THERMOPIEZO110) THEN
      CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, '*THERMO ELEC ELASTIC needs 12 property values')
      RETURN
    END IF
    DO k = 1, MD_MAT_NPROPS_THERMOPIEZO110
      props(k) = vals(k)
    END DO
    nprops = MD_MAT_NPROPS_THERMOPIEZO110
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_CoupledElas_ParseThermoPiezo110

  SUBROUTINE MD_CoupledElas_ThermoPiezo110_ToProps(vals12, props, nprops, status)
    REAL(wp), INTENT(IN) :: vals12(:)
    REAL(wp), INTENT(OUT) :: props(:)
    INTEGER(i4), INTENT(OUT) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: k

    CALL init_error_status(status)
    IF (SIZE(vals12) < MD_MAT_NPROPS_THERMOPIEZO110 .OR. SIZE(props) < MD_MAT_NPROPS_THERMOPIEZO110) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_CoupledElas_ThermoPiezo110_ToProps: size error'
      RETURN
    END IF
    DO k = 1, MD_MAT_NPROPS_THERMOPIEZO110
      props(k) = vals12(k)
    END DO
    nprops = MD_MAT_NPROPS_THERMOPIEZO110
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_CoupledElas_ThermoPiezo110_ToProps

END MODULE MD_Mat_Elas_Contract