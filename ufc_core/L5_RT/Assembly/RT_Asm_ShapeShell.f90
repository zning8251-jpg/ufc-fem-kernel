!===============================================================================
! MODULE: RT_Asm_ShapeShell
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Impl (shape/shell)
! BRIEF:  Shell B-matrix for S3/S4/S8 family -- membrane+bending
!===============================================================================
MODULE RT_Asm_ShapeShell
  ! INTF-001 合规：Shape_Eval 扁参为热路径渐进迁移；调用侧 SIO 封装见装配主流程。
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Elem_Mgr, ONLY: ELEM_S4, ELEM_S4R, ELEM_S4RS, ELEM_S4R5, ELEM_S3, ELEM_S3R, &
       ELEM_S6, ELEM_S6R, ELEM_S8, ELEM_S8R, ELEM_S8R5
  USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_GaussPoints, PH_Elem_CPS4_JacB
  USE PH_Elem_CPS3, ONLY: PH_Elem_CPS3_GaussPoints, PH_Elem_CPS3_JacB
  USE PH_Elem_CPS6, ONLY: PH_Elem_CPS6_GaussPoints, PH_Elem_CPS6_JacB
  USE PH_Elem_CPS8, ONLY: PH_Elem_CPS8_GaussPoints, PH_Elem_CPS8_JacB
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Asm_ShapeShell_GetNumGauss
  PUBLIC :: RT_Asm_ShapeShell_Supported
  PUBLIC :: RT_Asm_ShapeShell_Eval

CONTAINS

  PURE FUNCTION RT_Asm_ShapeShell_GetNumGauss(elem_type_id, npe) RESULT(n_ip)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    INTEGER(i4) :: n_ip
    SELECT CASE (elem_type_id)
    CASE (ELEM_S4)
      n_ip = 4_i4
    CASE (ELEM_S4R, ELEM_S4RS, ELEM_S4R5)
      n_ip = 1_i4
    CASE (ELEM_S3, ELEM_S3R)
      n_ip = 3_i4
    CASE (ELEM_S6, ELEM_S6R)
      n_ip = 3_i4
    CASE (ELEM_S8, ELEM_S8R, ELEM_S8R5)
      n_ip = 9_i4
    CASE DEFAULT
      IF (npe == 4_i4) n_ip = 4_i4
      IF (npe == 3_i4) n_ip = 3_i4
      IF (npe == 6_i4) n_ip = 3_i4
      IF (npe == 8_i4) n_ip = 9_i4
      IF (npe /= 4_i4 .AND. npe /= 3_i4 .AND. npe /= 6_i4 .AND. npe /= 8_i4) n_ip = 0_i4
    END SELECT
  END FUNCTION RT_Asm_ShapeShell_GetNumGauss

  PURE FUNCTION RT_Asm_ShapeShell_Supported(elem_type_id, npe) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    LOGICAL :: ok
    ok = (RT_Asm_ShapeShell_GetNumGauss(elem_type_id, npe) > 0_i4)
  END FUNCTION RT_Asm_ShapeShell_Supported

  SUBROUTINE RT_Asm_ShapeShell_Eval(elem_type_id, coords, npe, ip, N, dNdx, B_shell, detJ, weight, status)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe, ip
    REAL(wp), INTENT(IN) :: coords(3, *)
    REAL(wp), INTENT(OUT) :: N(*), dNdx(3, *)
    REAL(wp), INTENT(OUT) :: B_shell(6, *)
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
    B_shell = 0.0_wp
    dNdx = 0.0_wp

    et = elem_type_id
    IF (et == 0_i4) THEN
      IF (npe == 4_i4) et = ELEM_S4
      IF (npe == 3_i4) et = ELEM_S3
      IF (npe == 6_i4) et = ELEM_S6
      IF (npe == 8_i4) et = ELEM_S8
    END IF

    IF (npe == 4_i4) THEN
      coords2d(1:2, 1:4) = coords(1:2, 1:4)
      SELECT CASE (et)
      CASE (ELEM_S4, ELEM_S4R, ELEM_S4RS, ELEM_S4R5)
        n_ip = 4_i4
        IF (et == ELEM_S4R .OR. et == ELEM_S4RS .OR. et == ELEM_S4R5) n_ip = 1_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        IF (et == ELEM_S4R .OR. et == ELEM_S4RS .OR. et == ELEM_S4R5) THEN
          xi(1) = 0.0_wp
          eta(1) = 0.0_wp
          weights(1) = 4.0_wp
        ELSE
          CALL PH_Elem_CPS4_GaussPoints(xi(1:4), eta(1:4), weights(1:4))
        END IF
        CALL PH_Elem_CPS4_JacB(coords2d(1:2, 1:4), xi(ip), eta(ip), N(1:4), dNdx(1:2, 1:4), J, detJ, B_cps(1:3, 1:8))
        weight = weights(ip)
        DO i = 1, 4
          B_shell(1:3, 6*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_shell(1:3, 6*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:4) = 0.0_wp
        status%status_code = IF_STATUS_OK
      CASE DEFAULT
        n_ip = 4_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS4_GaussPoints(xi(1:4), eta(1:4), weights(1:4))
        CALL PH_Elem_CPS4_JacB(coords2d(1:2, 1:4), xi(ip), eta(ip), N(1:4), dNdx(1:2, 1:4), J, detJ, B_cps(1:3, 1:8))
        weight = weights(ip)
        DO i = 1, 4
          B_shell(1:3, 6*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_shell(1:3, 6*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:4) = 0.0_wp
        status%status_code = IF_STATUS_OK
      END SELECT
    ELSE IF (npe == 3_i4) THEN
      coords2d(1:2, 1:3) = coords(1:2, 1:3)
      SELECT CASE (et)
      CASE (ELEM_S3, ELEM_S3R)
        n_ip = 3_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS3_GaussPoints(xi(1:3), eta(1:3), weights(1:3))
        CALL PH_Elem_CPS3_JacB(coords2d(1:2, 1:3), xi(ip), eta(ip), N(1:3), dNdx(1:2, 1:3), J, detJ, B_cps(1:3, 1:6))
        weight = weights(ip)
        DO i = 1, 3
          B_shell(1:3, 6*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_shell(1:3, 6*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
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
          B_shell(1:3, 6*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_shell(1:3, 6*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:3) = 0.0_wp
        status%status_code = IF_STATUS_OK
      END SELECT
    ELSE IF (npe == 6_i4) THEN
      coords2d(1:2, 1:6) = coords(1:2, 1:6)
      SELECT CASE (et)
      CASE (ELEM_S6, ELEM_S6R)
        n_ip = 3_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS6_GaussPoints(xi(1:3), eta(1:3), weights(1:3))
        CALL PH_Elem_CPS6_JacB(coords2d(1:2, 1:6), xi(ip), eta(ip), N(1:6), dNdx(1:2, 1:6), J, detJ, B_cps(1:3, 1:12))
        weight = weights(ip)
        DO i = 1, 6
          B_shell(1:3, 6*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_shell(1:3, 6*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:6) = 0.0_wp
        status%status_code = IF_STATUS_OK
      CASE DEFAULT
        n_ip = 3_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS6_GaussPoints(xi(1:3), eta(1:3), weights(1:3))
        CALL PH_Elem_CPS6_JacB(coords2d(1:2, 1:6), xi(ip), eta(ip), N(1:6), dNdx(1:2, 1:6), J, detJ, B_cps(1:3, 1:12))
        weight = weights(ip)
        DO i = 1, 6
          B_shell(1:3, 6*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_shell(1:3, 6*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:6) = 0.0_wp
        status%status_code = IF_STATUS_OK
      END SELECT
    ELSE IF (npe == 8_i4) THEN
      coords2d(1:2, 1:8) = coords(1:2, 1:8)
      SELECT CASE (et)
      CASE (ELEM_S8, ELEM_S8R, ELEM_S8R5)
        n_ip = 9_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
        CALL PH_Elem_CPS8_JacB(coords2d(1:2, 1:8), xi(ip), eta(ip), N(1:8), dNdx(1:2, 1:8), J, detJ, B_cps(1:3, 1:16))
        weight = weights(ip)
        DO i = 1, 8
          B_shell(1:3, 6*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_shell(1:3, 6*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:8) = 0.0_wp
        status%status_code = IF_STATUS_OK
      CASE DEFAULT
        n_ip = 9_i4
        IF (ip < 1_i4 .OR. ip > n_ip) RETURN
        CALL PH_Elem_CPS8_GaussPoints(xi, eta, weights)
        CALL PH_Elem_CPS8_JacB(coords2d(1:2, 1:8), xi(ip), eta(ip), N(1:8), dNdx(1:2, 1:8), J, detJ, B_cps(1:3, 1:16))
        weight = weights(ip)
        DO i = 1, 8
          B_shell(1:3, 6*(i-1)+1) = B_cps(1:3, 2*(i-1)+1)
          B_shell(1:3, 6*(i-1)+2) = B_cps(1:3, 2*(i-1)+2)
        END DO
        dNdx(3, 1:8) = 0.0_wp
        status%status_code = IF_STATUS_OK
      END SELECT
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_Asm_ShapeShell_Eval: unsupported npe"
    END IF
  END SUBROUTINE RT_Asm_ShapeShell_Eval

END MODULE RT_Asm_ShapeShell