!===============================================================================
! MODULE: RT_Asm_ShapeMech2D
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Impl (shape/2D mechanical)
! BRIEF:  2D mechanical B-matrix for CPE/CPS/CAX elements
!===============================================================================
MODULE RT_Asm_ShapeMech2D
  ! INTF-001 合规：Shape_Eval 扁参为热路径渐进迁移；调用侧 SIO 封装见装配主流程。
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Elem_Mgr, ONLY: ELEM_CPE4, ELEM_CPE4R, ELEM_CPS4, ELEM_CPS4R, &
       ELEM_CAX4, ELEM_CAX4R, ELEM_CPE3, ELEM_CPS3, ELEM_CAX3
  USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_GaussPoints, PH_Elem_CPS4_JacB
  USE PH_Elem_CPE4, ONLY: PH_Elem_CPE4_GaussPoints, PH_Elem_CPE4_JacB
  USE PH_Elem_CAX4, ONLY: PH_Elem_CAX4_GaussPoints, PH_Elem_CAX4_JacB
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Asm_ShapeMech2D_GetNumGauss
  PUBLIC :: RT_Asm_ShapeMech2D_Supported
  PUBLIC :: RT_Asm_ShapeMech2D_Eval

CONTAINS

  !-----------------------------------------------------------------------------
  ! Get number of Gauss points for 2D elem_type.
  !-----------------------------------------------------------------------------
  PURE FUNCTION RT_Asm_ShapeMech2D_GetNumGauss(elem_type_id, npe) RESULT(n_ip)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    INTEGER(i4) :: n_ip

    SELECT CASE (elem_type_id)
    CASE (ELEM_CPE4, ELEM_CPS4, ELEM_CAX4)
      n_ip = 4_i4
    CASE (ELEM_CPE4R, ELEM_CPS4R, ELEM_CAX4R)
      n_ip = 1_i4
    CASE (ELEM_CPE3, ELEM_CPS3, ELEM_CAX3)
      n_ip = 1_i4
    CASE DEFAULT
      IF (npe == 4_i4) n_ip = 4_i4
      IF (npe == 3_i4) n_ip = 1_i4
      IF (npe /= 4_i4 .AND. npe /= 3_i4) n_ip = 0_i4
    END SELECT
  END FUNCTION RT_Asm_ShapeMech2D_GetNumGauss

  !-----------------------------------------------------------------------------
  ! Check if elem_type is supported for 2D mechanical assembly.
  !-----------------------------------------------------------------------------
  PURE FUNCTION RT_Asm_ShapeMech2D_Supported(elem_type_id, npe) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    LOGICAL :: ok
    ok = (RT_Asm_ShapeMech2D_GetNumGauss(elem_type_id, npe) > 0_i4)
  END FUNCTION RT_Asm_ShapeMech2D_Supported

  !-----------------------------------------------------------------------------
  ! Eval: Get N, dNdx, B_2d (3 or 4 rows, 2*npe cols), detJ, weight at GP ip.
  !   coords(2, npe): 2D coordinates (x,y) or (r,z) for axisymmetric
  !   B_2d: CPS/CPE B(3,2*npe); CAX B(4,2*npe)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_ShapeMech2D_Eval(elem_type_id, coords, npe, ip, N, dNdx, B_2d, detJ, weight, status)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe, ip
    REAL(wp), INTENT(IN) :: coords(2, *)
    REAL(wp), INTENT(OUT) :: N(*), dNdx(2, *)
    REAL(wp), INTENT(OUT) :: B_2d(4, *)
    REAL(wp), INTENT(OUT) :: detJ, weight
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: et, n_ip
    REAL(wp) :: xi(4), eta(4), weights(4)
    REAL(wp) :: coords4(2, 4)
    REAL(wp) :: J(2, 2)
    REAL(wp) :: r_pt

    CALL init_error_status(status)
    detJ = 0.0_wp
    weight = 0.0_wp
    B_2d = 0.0_wp

    et = elem_type_id
    IF (et == 0_i4) THEN
      IF (npe == 4_i4) et = ELEM_CPS4
      IF (npe == 3_i4) et = ELEM_CPS3
    END IF

    ! --- 3-node constant strain triangle (CPE3, CPS3, CAX3) ---
    IF (npe == 3_i4) THEN
      IF (ip /= 1_i4) RETURN
      CALL RT_Asm_ShapeMech2D_Eval_Tri3(et, coords, N, dNdx, B_2d, detJ, weight, status)
      RETURN
    END IF

    IF (npe < 4_i4) RETURN

    coords4(1:2, 1:4) = coords(1:2, 1:4)

    SELECT CASE (et)
    CASE (ELEM_CPS4, ELEM_CPS4R)
      n_ip = 4_i4
      IF (et == ELEM_CPS4R) n_ip = 1_i4
      IF (ip < 1_i4 .OR. ip > n_ip) RETURN
      IF (et == ELEM_CPS4R) THEN
        xi(1) = 0.0_wp
        eta(1) = 0.0_wp
        weights(1) = 4.0_wp
      ELSE
        CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
      END IF
      CALL PH_Elem_CPS4_JacB(coords4, xi(ip), eta(ip), N(1:4), dNdx(1:2, 1:4), J, detJ, B_2d(1:3, 1:8))
      weight = weights(ip)

    CASE (ELEM_CPE4, ELEM_CPE4R)
      n_ip = 4_i4
      IF (et == ELEM_CPE4R) n_ip = 1_i4
      IF (ip < 1_i4 .OR. ip > n_ip) RETURN
      IF (et == ELEM_CPE4R) THEN
        xi(1) = 0.0_wp
        eta(1) = 0.0_wp
        weights(1) = 4.0_wp
      ELSE
        CALL PH_Elem_CPE4_GaussPoints(xi, eta, weights)
      END IF
      CALL PH_Elem_CPE4_JacB(coords4, xi(ip), eta(ip), N(1:4), dNdx(1:2, 1:4), J, detJ, B_2d(1:3, 1:8))
      weight = weights(ip)

    CASE (ELEM_CAX4, ELEM_CAX4R)
      n_ip = 4_i4
      IF (et == ELEM_CAX4R) n_ip = 1_i4
      IF (ip < 1_i4 .OR. ip > n_ip) RETURN
      IF (et == ELEM_CAX4R) THEN
        xi(1) = 0.0_wp
        eta(1) = 0.0_wp
        weights(1) = 4.0_wp
      ELSE
        CALL PH_Elem_CAX4_GaussPoints(xi, eta, weights)
      END IF
      CALL PH_Elem_CAX4_JacB(coords4, xi(ip), eta(ip), N(1:4), dNdx(1:2, 1:4), J, detJ, r_pt, B_2d(1:4, 1:8))
      weight = weights(ip)

    CASE DEFAULT
      n_ip = 4_i4
      IF (ip < 1_i4 .OR. ip > n_ip) RETURN
      CALL PH_Elem_CPS4_GaussPoints(xi, eta, weights)
      CALL PH_Elem_CPS4_JacB(coords4, xi(ip), eta(ip), N(1:4), dNdx(1:2, 1:4), J, detJ, B_2d(1:3, 1:8))
      weight = weights(ip)
    END SELECT

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_ShapeMech2D_Eval

  !-----------------------------------------------------------------------------
  ! Eval_Tri3: 3-node constant strain triangle. 1 GP at centroid.
  !   B(3,6) for CPE/CPS; B(4,6) for CAX (hoop strain).
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_ShapeMech2D_Eval_Tri3(elem_type_id, coords, N, dNdx, B_2d, detJ, weight, status)
    INTEGER(i4), INTENT(IN) :: elem_type_id
    REAL(wp), INTENT(IN) :: coords(2, *)
    REAL(wp), INTENT(OUT) :: N(*), dNdx(2, *)
    REAL(wp), INTENT(OUT) :: B_2d(4, *)
    REAL(wp), INTENT(OUT) :: detJ, weight
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: x1, x2, x3, y1, y2, y3, area2, r_pt
    LOGICAL :: is_axisym

    CALL init_error_status(status)
    detJ = 0.0_wp
    weight = 0.0_wp
    B_2d = 0.0_wp

    x1 = coords(1, 1)
    y1 = coords(2, 1)
    x2 = coords(1, 2)
    y2 = coords(2, 2)
    x3 = coords(1, 3)
    y3 = coords(2, 3)

    area2 = (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)
    IF (ABS(area2) <= 1.0e-20_wp) RETURN
    detJ = ABS(area2)
    weight = 0.5_wp

    N(1) = 1.0_wp / 3.0_wp
    N(2) = 1.0_wp / 3.0_wp
    N(3) = 1.0_wp / 3.0_wp

    dNdx(1, 1) = (y2 - y3) / area2
    dNdx(2, 1) = (x3 - x2) / area2
    dNdx(1, 2) = (y3 - y1) / area2
    dNdx(2, 2) = (x1 - x3) / area2
    dNdx(1, 3) = (y1 - y2) / area2
    dNdx(2, 3) = (x2 - x1) / area2

    B_2d(1, 1) = dNdx(1, 1)
    B_2d(1, 3) = dNdx(1, 2)
    B_2d(1, 5) = dNdx(1, 3)
    B_2d(2, 2) = dNdx(2, 1)
    B_2d(2, 4) = dNdx(2, 2)
    B_2d(2, 6) = dNdx(2, 3)
    B_2d(3, 1) = dNdx(2, 1)
    B_2d(3, 2) = dNdx(1, 1)
    B_2d(3, 3) = dNdx(2, 2)
    B_2d(3, 4) = dNdx(1, 2)
    B_2d(3, 5) = dNdx(2, 3)
    B_2d(3, 6) = dNdx(1, 3)

    is_axisym = (elem_type_id == ELEM_CAX3)
    IF (is_axisym) THEN
      r_pt = (x1 + x2 + x3) / 3.0_wp
      IF (r_pt < 1.0e-12_wp) r_pt = 1.0e-12_wp
      B_2d(4, 1) = N(1) / r_pt
      B_2d(4, 3) = N(2) / r_pt
      B_2d(4, 5) = N(3) / r_pt
      detJ = detJ * 2.0_wp * 3.141592653589793_wp * r_pt
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_ShapeMech2D_Eval_Tri3

END MODULE RT_Asm_ShapeMech2D