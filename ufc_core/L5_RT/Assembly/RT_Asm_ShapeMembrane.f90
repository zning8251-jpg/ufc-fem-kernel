!===============================================================================
! MODULE: RT_Asm_ShapeMembrane
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Impl (shape/membrane)
! BRIEF:  Membrane B-matrix for M3D3/M3D4/M3D8 elements
!===============================================================================
MODULE RT_Asm_ShapeMembrane
  ! INTF-001 合规：Shape_Eval 扁参为热路径渐进迁移；调用侧 SIO 封装见装配主流程。
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Elem_Mgr, ONLY: ELEM_M3D4, ELEM_M3D4R, ELEM_M3D3, ELEM_M3D3R, ELEM_M3D8, ELEM_M3D8R
  USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_GaussPoints, PH_Elem_CPS4_JacB
  USE PH_Elem_CPS3, ONLY: PH_Elem_CPS3_GaussPoints, PH_Elem_CPS3_JacB
  USE PH_Elem_CPS8, ONLY: PH_Elem_CPS8_GaussPoints, PH_Elem_CPS8_JacB
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Asm_ShapeMembrane_GetNumGauss
  PUBLIC :: RT_Asm_ShapeMembrane_Supported
  PUBLIC :: RT_Asm_ShapeMembrane_Eval

CONTAINS

  PURE FUNCTION RT_Asm_ShapeMembrane_GetNumGauss(elem_type_id, npe) RESULT(n_ip)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    INTEGER(i4) :: n_ip
    SELECT CASE (elem_type_id)
    CASE (ELEM_M3D4)
      n_ip = 4_i4
    CASE (ELEM_M3D4R)
      n_ip = 1_i4
    CASE (ELEM_M3D3, ELEM_M3D3R)
      n_ip = 3_i4
    CASE (ELEM_M3D8, ELEM_M3D8R)
      n_ip = 9_i4
    CASE DEFAULT
      IF (npe == 4_i4) n_ip = 4_i4
      IF (npe == 3_i4) n_ip = 3_i4
      IF (npe == 8_i4) n_ip = 9_i4
      IF (npe /= 4_i4 .AND. npe /= 3_i4 .AND. npe /= 8_i4) n_ip = 0_i4
    END SELECT
  END FUNCTION RT_Asm_ShapeMembrane_GetNumGauss

  PURE FUNCTION RT_Asm_ShapeMembrane_Supported(elem_type_id, npe) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    LOGICAL :: ok
    ok = (RT_Asm_ShapeMembrane_GetNumGauss(elem_type_id, npe) > 0_i4)
  END FUNCTION RT_Asm_ShapeMembrane_Supported

  SUBROUTINE RT_Asm_ShapeMembrane_Eval(elem_type_id, coords, npe, ip, N, dNdx, B_mem, detJ, weight, status)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe, ip
    REAL(wp), INTENT(IN) :: coords(3, *)
    REAL(wp), INTENT(OUT) :: N(*), dNdx(3, *)
    REAL(wp), INTENT(OUT) :: B_mem(3, *)
    REAL(wp), INTENT(OUT) :: detJ, weight
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: et, n_ip, i
    REAL(wp) :: coords2d(2, 8)
    REAL(wp) :: B_cps(3, 16)
    REAL(wp) :: xi(9), eta(9), weights(9)
    REAL(wp) :: J(2, 2)

    CALL init_error_status(status)
    detJ = 0.0_wp
    weight = 0.0_wp
    B_mem = 0.0_wp
    dNdx = 0.0_wp

    et = elem_type_id
    IF (et == 0_i4) THEN
      IF (npe == 4_i4) et = ELEM_M3D4
      IF (npe == 3_i4) et = ELEM_M3D3
    END IF

    IF (npe == 4_i4) THEN
      coords2d(1:2, 1:4) = coords(1:2, 1:4)
      SELECT CASE (et)
      CASE (ELEM_M3D4, ELEM_M3D4R)
        n_ip = 4_i4
        IF (et == ELEM_M3D4R) n_ip = 1_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        IF (et == ELEM_M3D4R) THEN
          xi(1) = 0.0_wp
          eta(1) = 0.0_wp
          weights(1) = 4.0_wp
        ELSE
          CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
        END IF
        CALL PH_Elem_CPS4_JacB(coords2d, xi(ip), eta(ip), N(1:4), dNdx(1:2, 1:4), J, detJ, B_cps(1:3, 1:8))
        weight = weights(ip)
        DO i = 1, 4
          B_mem(1:3, 3*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_mem(1:3, 3*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:4) = 0.0_wp
        status%status_code = IF_STATUS_OK
      CASE DEFAULT
        n_ip = 4_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
        CALL PH_Elem_CPS4_JacB(coords2d, xi(ip), eta(ip), N(1:4), dNdx(1:2, 1:4), J, detJ, B_cps(1:3, 1:8))
        weight = weights(ip)
        DO i = 1, 4
          B_mem(1:3, 3*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_mem(1:3, 3*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:4) = 0.0_wp
        status%status_code = IF_STATUS_OK
      END SELECT
    ELSE IF (npe == 3_i4) THEN
      coords2d(1:2, 1:3) = coords(1:2, 1:3)
      SELECT CASE (et)
      CASE (ELEM_M3D3, ELEM_M3D3R)
        n_ip = 3_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS3_GaussPoints(xi(1:3), eta(1:3), weights(1:3))
        CALL PH_Elem_CPS3_JacB(coords2d(1:2, 1:3), xi(ip), eta(ip), N(1:3), dNdx(1:2, 1:3), J, detJ, B_cps(1:3, 1:6))
        weight = weights(ip)
        DO i = 1, 3
          B_mem(1:3, 3*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_mem(1:3, 3*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:3) = 0.0_wp
        status%status_code = IF_STATUS_OK
      CASE DEFAULT
        n_ip = 3_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS3_GaussPoints(xi(1:3), eta(1:3), weights(1:3))
        CALL PH_Elem_CPS3_JacB(coords2d(1:2, 1:3), xi(ip), eta(ip), N(1:3), dNdx(1:2, 1:3), J, detJ, B_cps(1:3, 1:6))
        weight = weights(ip)
        DO i = 1, 3
          B_mem(1:3, 3*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_mem(1:3, 3*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:3) = 0.0_wp
        status%status_code = IF_STATUS_OK
      END SELECT
    ELSE IF (npe == 8_i4) THEN
      coords2d(1:2, 1:8) = coords(1:2, 1:8)
      SELECT CASE (et)
      CASE (ELEM_M3D8, ELEM_M3D8R)
        n_ip = 9_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS8_GaussPoints(xi(1:9), eta(1:9), weights(1:9))
        CALL PH_Elem_CPS8_JacB(coords2d(1:2, 1:8), xi(ip), eta(ip), N(1:8), dNdx(1:2, 1:8), J, detJ, B_cps(1:3, 1:16))
        weight = weights(ip)
        DO i = 1, 8
          B_mem(1:3, 3*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_mem(1:3, 3*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:8) = 0.0_wp
        status%status_code = IF_STATUS_OK
      CASE DEFAULT
        n_ip = 9_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS8_GaussPoints(xi(1:9), eta(1:9), weights(1:9))
        CALL PH_Elem_CPS8_JacB(coords2d(1:2, 1:8), xi(ip), eta(ip), N(1:8), dNdx(1:2, 1:8), J, detJ, B_cps(1:3, 1:16))
        weight = weights(ip)
        DO i = 1, 8
          B_mem(1:3, 3*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_mem(1:3, 3*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:8) = 0.0_wp
        status%status_code = IF_STATUS_OK
      END SELECT
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_Asm_ShapeMembrane_Eval: unsupported npe"
    END IF
  END SUBROUTINE RT_Asm_ShapeMembrane_Eval

END MODULE RT_Asm_ShapeMembrane