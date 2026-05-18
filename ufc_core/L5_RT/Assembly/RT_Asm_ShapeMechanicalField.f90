!===============================================================================
! MODULE: RT_Asm_ShapeMechanicalField
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Impl (shape/mechanical field, @DEPRECATED -> L4_PH)
! BRIEF:  Unified N, dNdx, B for 3D mechanical elements (C3D family)
!===============================================================================
!   @DEPRECATED - Shape function evaluation belongs in L4_PH
!   Migration: Replace CALL RT_Asm_ShapeMechanicalField_* with PH_ShapeMechanicalField_*
! Supported: C3D4..C3D27 (3D only)
!===============================================================================
MODULE RT_Asm_ShapeMechanicalField
  ! INTF-001 合规：Shape_Eval 扁参为热路径渐进迁移；调用侧 SIO 封装见装配主流程。
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Elem_Mgr, ONLY: ELEM_C3D4, ELEM_C3D5, ELEM_C3D13, ELEM_C3D8, ELEM_C3D8R, ELEM_C3D8I, ELEM_C3D8H, &
       ELEM_C3D10, ELEM_C3D20, ELEM_C3D20R, ELEM_C3D20I, ELEM_C3D20H, ELEM_C3D27, &
       ELEM_C3D6, ELEM_C3D15, ELEM_C3D6R, ELEM_C3D15R, &
       ELEM_T3D2, ELEM_B31, ELEM_S4, ELEM_S4R, ELEM_M3D4, ELEM_M3D4R
  USE PH_Elem_T3D2, ONLY: PH_Elem_T3D2_BMatrix
  USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_GaussPoints, PH_Elem_CPS4_ShapeFunc, PH_Elem_CPS4_JacB
  USE PH_Elem_C3D8, ONLY: PH_Elem_C3D8_GaussPoints, PH_Elem_C3D8_JacB, &
       PH_Elem_C3D8_JacB_In, PH_Elem_C3D8_JacB_Out
  USE PH_Elem_C3D4, ONLY: PH_Elem_C3D4_GaussPoints, PH_Elem_C3D4_JacB
  USE PH_Elem_C3D5, ONLY: PH_Elem_C3D5_GaussPoints, PH_Elem_C3D5_JacB
  USE PH_Elem_C3D13, ONLY: PH_Elem_C3D13_GaussPoints, PH_Elem_C3D13_JacB
  USE PH_Elem_C3D10, ONLY: PH_Elem_C3D10_GaussPoints, PH_Elem_C3D10_JacB
  USE PH_Elem_C3D20, ONLY: PH_Elem_C3D20_GaussPoints, PH_Elem_C3D20_JacB, &
       PH_Elem_C3D20_JacB_In, PH_Elem_C3D20_JacB_Out
  USE PH_Elem_C3D6, ONLY: PH_Elem_C3D6_GaussPoints, PH_Elem_C3D6_JacB
  USE PH_Elem_C3D15, ONLY: PH_Elem_C3D15_GaussPoints, PH_Elem_C3D15_JacB
  USE PH_Elem_C3D27, ONLY: PH_Elem_C3D27_GaussPoints, PH_Elem_C3D27_JacB
  USE PH_Elem_Reg, ONLY: PH_Elem_Reg_GetBaseElemType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Asm_ShapeMechanicalField_GetNumGauss
  PUBLIC :: RT_Asm_ShapeMechanicalField_Eval
  PUBLIC :: RT_Asm_ShapeMechanicalField_Supported

CONTAINS

  !-----------------------------------------------------------------------------
  ! Get number of Gauss points for elem_type. Returns 0 if unsupported.
  !-----------------------------------------------------------------------------
  PURE FUNCTION RT_Asm_ShapeMechanicalField_GetNumGauss(elem_type_id, npe) RESULT(n_ip)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    INTEGER(i4) :: n_ip
    SELECT CASE (elem_type_id)
    CASE (ELEM_C3D4)
      n_ip = 1_i4
    CASE (ELEM_C3D5)
      n_ip = 8_i4
    CASE (ELEM_C3D13)
      n_ip = 8_i4
    CASE (ELEM_C3D8, ELEM_C3D8R, ELEM_C3D8I, ELEM_C3D8H)
      n_ip = 8_i4
    CASE (ELEM_C3D10)
      n_ip = 4_i4
    CASE (ELEM_C3D20, ELEM_C3D20R, ELEM_C3D20I, ELEM_C3D20H, ELEM_C3D27)
      n_ip = 27_i4
    CASE (ELEM_C3D6, ELEM_C3D6R)
      n_ip = 6_i4
    CASE (ELEM_C3D15, ELEM_C3D15R)
      n_ip = 9_i4
    CASE (ELEM_T3D2, ELEM_B31)
      n_ip = 1_i4
    CASE (ELEM_S4, ELEM_M3D4)
      n_ip = 4_i4
    CASE (ELEM_S4R, ELEM_M3D4R)
      n_ip = 1_i4
    CASE (0_i4)
      IF (npe == 4_i4) n_ip = 1_i4
      IF (npe == 5_i4) n_ip = 8_i4
      IF (npe == 8_i4) n_ip = 8_i4
      IF (npe == 10_i4) n_ip = 4_i4
      IF (npe == 13_i4) n_ip = 8_i4
      IF (npe == 20_i4) n_ip = 27_i4
      IF (npe == 6_i4) n_ip = 6_i4
      IF (npe == 15_i4) n_ip = 9_i4
      IF (npe == 27_i4) n_ip = 27_i4
      IF (npe == 2_i4) n_ip = 1_i4
      IF (npe /= 4_i4 .AND. npe /= 5_i4 .AND. npe /= 8_i4 .AND. npe /= 10_i4 .AND. npe /= 13_i4 .AND. &
          npe /= 20_i4 .AND. npe /= 6_i4 .AND. npe /= 15_i4 .AND. npe /= 27_i4 .AND. npe /= 2_i4) n_ip = 0_i4
    CASE DEFAULT
      n_ip = 0_i4
    END SELECT
  END FUNCTION RT_Asm_ShapeMechanicalField_GetNumGauss

  !-----------------------------------------------------------------------------
  ! Check if elem_type is supported for mechanical (B-matrix) assembly.
  !-----------------------------------------------------------------------------
  PURE FUNCTION RT_Asm_ShapeMechanicalField_Supported(elem_type_id, npe) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    LOGICAL :: ok
    ok = (RT_Asm_ShapeMechanicalField_GetNumGauss(elem_type_id, npe) > 0_i4)
  END FUNCTION RT_Asm_ShapeMechanicalField_Supported

  !-----------------------------------------------------------------------------
  ! Eval: Get N, dNdx, B (strain-displacement), detJ, weight at Gauss point ip.
  !   B(6, 3*npe) for 3D; B_phi = dNdx.
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_ShapeMechanicalField_Eval(elem_type_id, coords, npe, ip, N, dNdx, B_u, detJ, weight, status)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe, ip
    REAL(wp), INTENT(IN) :: coords(3, *)
    REAL(wp), INTENT(OUT) :: N(*), dNdx(3, *)
    REAL(wp), INTENT(OUT) :: B_u(6, *)
    REAL(wp), INTENT(OUT) :: detJ, weight
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_ip, et
    TYPE(PH_Elem_C3D8_JacB_In) :: in_jacb
    TYPE(PH_Elem_C3D8_JacB_Out) :: out_jacb
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: coords4(3, 4), coords8(3, 8), coords10(3, 10), coords6(3, 6), coords15(3, 15)
    REAL(wp) :: N4(4), dNdx4(3, 4), N10(10), dNdx10(3, 10), N6(6), dNdx6(3, 6), N15(15), dNdx15(3, 15)
    REAL(wp) :: J_dum(3, 3)

    CALL init_error_status(status)
    detJ = 0.0_wp
    weight = 0.0_wp
    et = elem_type_id
    IF (et == 0_i4) THEN
      IF (npe == 4_i4) et = ELEM_C3D4
      IF (npe == 5_i4) et = ELEM_C3D5
      IF (npe == 8_i4) et = ELEM_C3D8
      IF (npe == 10_i4) et = ELEM_C3D10
      IF (npe == 13_i4) et = ELEM_C3D13
      IF (npe == 20_i4) et = ELEM_C3D20
      IF (npe == 6_i4) et = ELEM_C3D6
      IF (npe == 15_i4) et = ELEM_C3D15
      IF (npe == 27_i4) et = ELEM_C3D27
      IF (npe == 2_i4) et = ELEM_T3D2
    END IF

    SELECT CASE (et)
    CASE (ELEM_C3D4)
      n_ip = 1_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 4_i4) RETURN
      coords4(1:3, 1:4) = coords(1:3, 1:4)
      CALL PH_Elem_C3D4_GaussPoints(xi(1:1), eta(1:1), zeta(1:1), weights(1:1))
      CALL PH_Elem_C3D4_JacB(coords4, xi(1), eta(1), zeta(1), N4, dNdx4, J_dum, detJ, B_u(1:6, 1:12))
      N(1:4) = N4
      dNdx(1:3, 1:4) = dNdx4
      weight = weights(1)

    CASE (ELEM_C3D5)
      n_ip = 8_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 5_i4) RETURN
      BLOCK
        REAL(wp) :: xi5(8), eta5(8), zeta5(8), wt5(8)
        REAL(wp) :: coords5(3, 5), N5(5), dNdx5(3, 5)
        coords5(1:3, 1:5) = coords(1:3, 1:5)
        CALL PH_Elem_C3D5_GaussPoints(xi5, eta5, zeta5, wt5)
        CALL PH_Elem_C3D5_JacB(coords5, xi5(ip), eta5(ip), zeta5(ip), N5, dNdx5, J_dum, detJ, B_u(1:6, 1:15))
        N(1:5) = N5
        dNdx(1:3, 1:5) = dNdx5
        weight = wt5(ip)
      END BLOCK

    CASE (ELEM_C3D13)
      n_ip = 8_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 13_i4) RETURN
      BLOCK
        REAL(wp) :: xi13(8), eta13(8), zeta13(8), wt13(8)
        REAL(wp) :: coords13(3, 13), N13(13), dNdx13(3, 13)
        coords13(1:3, 1:13) = coords(1:3, 1:13)
        CALL PH_Elem_C3D13_GaussPoints(xi13, eta13, zeta13, wt13)
        CALL PH_Elem_C3D13_JacB(coords13, xi13(ip), eta13(ip), zeta13(ip), N13, dNdx13, J_dum, detJ, B_u(1:6, 1:39))
        N(1:13) = N13
        dNdx(1:3, 1:13) = dNdx13
        weight = wt13(ip)
      END BLOCK

    CASE (ELEM_C3D8, ELEM_C3D8R, ELEM_C3D8I, ELEM_C3D8H)
      n_ip = 8_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 8_i4) RETURN
      coords8(1:3, 1:8) = coords(1:3, 1:8)
      CALL PH_Elem_C3D8_GaussPoints(xi(1:8), eta(1:8), zeta(1:8), weights(1:8))
      in_jacb%coords = coords8
      in_jacb%xi = xi(ip)
      in_jacb%eta = eta(ip)
      in_jacb%zeta = zeta(ip)
      CALL PH_Elem_C3D8_JacB(in_jacb, out_jacb)
      IF (out_jacb%status%status_code /= IF_STATUS_OK) THEN
        status = out_jacb%status
        RETURN
      END IF
      N(1:8) = out_jacb%N
      dNdx(1:3, 1:8) = out_jacb%dNdx
      B_u(1:6, 1:24) = out_jacb%B
      detJ = out_jacb%detJ
      weight = weights(ip)

    CASE (ELEM_C3D10)
      n_ip = 4_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 10_i4) RETURN
      coords10(1:3, 1:10) = coords(1:3, 1:10)
      CALL PH_Elem_C3D10_GaussPoints(xi(1:4), eta(1:4), zeta(1:4), weights(1:4))
      CALL PH_Elem_C3D10_JacB(coords10, xi(ip), eta(ip), zeta(ip), N10, dNdx10, J_dum, detJ, B_u(1:6, 1:30))
      N(1:10) = N10
      dNdx(1:3, 1:10) = dNdx10
      weight = weights(ip)

    CASE (ELEM_C3D6, ELEM_C3D6R)
      n_ip = 6_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 6_i4) RETURN
      coords6(1:3, 1:6) = coords(1:3, 1:6)
      CALL PH_Elem_C3D6_GaussPoints(xi(1:6), eta(1:6), zeta(1:6), weights(1:6))
      CALL PH_Elem_C3D6_JacB(coords6, xi(ip), eta(ip), zeta(ip), N6, dNdx6, J_dum, detJ, B_u(1:6, 1:18))
      N(1:6) = N6
      dNdx(1:3, 1:6) = dNdx6
      weight = weights(ip)

    CASE (ELEM_C3D15, ELEM_C3D15R)
      n_ip = 9_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 15_i4) RETURN
      coords15(1:3, 1:15) = coords(1:3, 1:15)
      CALL PH_Elem_C3D15_GaussPoints(xi(1:9), eta(1:9), zeta(1:9), weights(1:9))
      CALL PH_Elem_C3D15_JacB(coords15, xi(ip), eta(ip), zeta(ip), N15, dNdx15, J_dum, detJ, B_u(1:6, 1:45))
      N(1:15) = N15
      dNdx(1:3, 1:15) = dNdx15
      weight = weights(ip)

    CASE (ELEM_C3D20, ELEM_C3D20R, ELEM_C3D20I, ELEM_C3D20H)
      n_ip = 27_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 20_i4) RETURN
      BLOCK
        REAL(wp) :: xi20(27), eta20(27), zeta20(27), wt20(27)
        REAL(wp) :: coords20(3, 20)
        TYPE(PH_Elem_C3D20_JacB_In) :: in_j20
        TYPE(PH_Elem_C3D20_JacB_Out) :: out_j20
        coords20(1:3, 1:20) = coords(1:3, 1:20)
        CALL PH_Elem_C3D20_GaussPoints(xi20, eta20, zeta20, wt20)
        in_j20%desc%coords = coords20  ! FLOW-003-exempt: SIO JacB inbound bundle, not SSOT Desc mutation
        in_j20%algo%xi = xi20(ip)
        in_j20%algo%eta = eta20(ip)
        in_j20%algo%zeta = zeta20(ip)
        CALL PH_Elem_C3D20_JacB(in_j20, out_j20)
        IF (out_j20%status%status_code /= IF_STATUS_OK) THEN
          status = out_j20%status
          RETURN
        END IF
        N(1:20) = out_j20%state%N
        dNdx(1:3, 1:20) = out_j20%state%dNdx
        B_u(1:6, 1:60) = out_j20%state%B
        detJ = out_j20%state%detJ
        weight = wt20(ip)
      END BLOCK

    CASE (ELEM_C3D27)
      n_ip = 27_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 27_i4) RETURN
      BLOCK
        REAL(wp) :: xi27(27), eta27(27), zeta27(27), wt27(27)
        REAL(wp) :: coords27(3, 27), N27(27), dNdx27(3, 27)
        coords27(1:3, 1:27) = coords(1:3, 1:27)
        CALL PH_Elem_C3D27_GaussPoints(xi27, eta27, zeta27, wt27)
        CALL PH_Elem_C3D27_JacB(coords27, xi27(ip), eta27(ip), zeta27(ip), N27, dNdx27, J_dum, detJ, B_u(1:6, 1:81))
        N(1:27) = N27
        dNdx(1:3, 1:27) = dNdx27
        weight = wt27(ip)
      END BLOCK

    ! --- 1D: T3D2 (truss), B31 (beam axial) ---
    CASE (ELEM_T3D2, ELEM_B31)
      n_ip = 1_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 2_i4) RETURN
      BLOCK
        REAL(wp) :: dx, dy, dz, L, e_dir(3), B1(1, 6)
        B_u = 0.0_wp
        N(1) = 0.5_wp
        N(2) = 0.5_wp
        dx = coords(1, 2) - coords(1, 1)
        dy = coords(2, 2) - coords(2, 1)
        dz = coords(3, 2) - coords(3, 1)
        L = SQRT(dx*dx + dy*dy + dz*dz)
        IF (L <= 1.0e-12_wp) RETURN
        CALL PH_Elem_T3D2_BMatrix(coords(1:3, 1:2), L, e_dir, B1)
        B_u(1:1, 1:6) = B1
        dNdx(1:3, 1) = -e_dir / L
        dNdx(1:3, 2) =  e_dir / L
        detJ = L * 0.5_wp
        weight = 2.0_wp
      END BLOCK

    ! --- 3D surface: S4, M3D4 (4-node shell/membrane) - membrane B from CPS4 ---
    CASE (ELEM_S4, ELEM_M3D4)
      n_ip = 4_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 4_i4) RETURN
      BLOCK
        REAL(wp) :: xi_2d(4), eta_2d(4), weights_2d(4)
        REAL(wp) :: coords_2d(2, 4), N4s(4), dNdxi_s(2, 4)
        REAL(wp) :: e1(3), e2(3), c(3), p21(3), p41(3), len
        INTEGER(i4) :: ii
        CALL PH_Elem_CPS4_GaussPoints(xi_2d, eta_2d, weights_2d)
        c = (coords(1:3, 1) + coords(1:3, 2) + coords(1:3, 3) + coords(1:3, 4)) * 0.25_wp
        p21 = coords(1:3, 2) - coords(1:3, 1)
        p41 = coords(1:3, 4) - coords(1:3, 1)
        len = SQRT(SUM(p21*p21))
        IF (len <= 1.0e-12_wp) RETURN
        e1 = p21 / len
        e2 = p41 - SUM(p41*e1)*e1
        len = SQRT(SUM(e2*e2))
        IF (len <= 1.0e-12_wp) RETURN
        e2 = e2 / len
        DO ii = 1, 4
          coords_2d(1, ii) = SUM((coords(1:3, ii) - c)*e1)
          coords_2d(2, ii) = SUM((coords(1:3, ii) - c)*e2)
        END DO
        BLOCK
          REAL(wp) :: B_mem(3, 8)
          CALL PH_Elem_CPS4_JacB(coords_2d, xi_2d(ip), eta_2d(ip), N4s, dNdxi_s, J_dum(1:2,1:2), detJ, B_mem)
          B_u = 0.0_wp
          DO ii = 1, 4
            B_u(1:3, 3*ii-2:3*ii-1) = B_mem(1:3, 2*ii-1:2*ii)
          END DO
        END BLOCK
        N(1:4) = N4s
        dNdx(1:3, 1:4) = 0.0_wp
        weight = weights_2d(ip)
      END BLOCK

    ! --- 3D surface reduced: S4R, M3D4R (1 GP at center, weight=4) ---
    CASE (ELEM_S4R, ELEM_M3D4R)
      n_ip = 1_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 4_i4) RETURN
      BLOCK
        REAL(wp) :: coords_2d(2, 4), N4s(4), dNdxi_s(2, 4)
        REAL(wp) :: e1(3), e2(3), c(3), p21(3), p41(3), len
        INTEGER(i4) :: ii
        c = (coords(1:3, 1) + coords(1:3, 2) + coords(1:3, 3) + coords(1:3, 4)) * 0.25_wp
        p21 = coords(1:3, 2) - coords(1:3, 1)
        p41 = coords(1:3, 4) - coords(1:3, 1)
        len = SQRT(SUM(p21*p21))
        IF (len <= 1.0e-12_wp) RETURN
        e1 = p21 / len
        e2 = p41 - SUM(p41*e1)*e1
        len = SQRT(SUM(e2*e2))
        IF (len <= 1.0e-12_wp) RETURN
        e2 = e2 / len
        DO ii = 1, 4
          coords_2d(1, ii) = SUM((coords(1:3, ii) - c)*e1)
          coords_2d(2, ii) = SUM((coords(1:3, ii) - c)*e2)
        END DO
        BLOCK
          REAL(wp) :: B_mem(3, 8)
          CALL PH_Elem_CPS4_JacB(coords_2d, 0.0_wp, 0.0_wp, N4s, dNdxi_s, J_dum(1:2,1:2), detJ, B_mem)
          B_u = 0.0_wp
          DO ii = 1, 4
            B_u(1:3, 3*ii-2:3*ii-1) = B_mem(1:3, 2*ii-1:2*ii)
          END DO
        END BLOCK
        N(1:4) = N4s
        dNdx(1:3, 1:4) = 0.0_wp
        weight = 4.0_wp
      END BLOCK

    CASE DEFAULT
      ! Fallback: try base_elem_type for shape reuse (Option B)
      BLOCK
        INTEGER(i4) :: base_et
        base_et = PH_Elem_Reg_GetBaseElemType(elem_type_id)
        IF (base_et > 0_i4 .AND. base_et /= elem_type_id) THEN
          CALL RT_Asm_ShapeMechanicalField_Eval(base_et, coords, npe, ip, N, dNdx, B_u, detJ, weight, status)
          RETURN
        END IF
      END BLOCK
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_AsmShapeMechanicalField: unsupported elem_type'
      RETURN
    END SELECT
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_ShapeMechanicalField_Eval

END MODULE RT_Asm_ShapeMechanicalField