!===============================================================================
! MODULE: RT_Asm_ShapeScalarField
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Impl (shape/scalar field, @DEPRECATED -> L4_PH)
! BRIEF:  Unified N, dNdx, detJ for scalar-field assembly (thermal/acoustic)
!===============================================================================
!   @DEPRECATED - Shape function evaluation belongs in L4_PH
!   Migration: Replace CALL RT_Asm_ShapeScalarField_* with PH_ShapeScalarField_*
! Supported: C3D*, AC3D*, CPE*, AC2D*, CAX*, ACAX*, T3D2, B31, S4*, M3D4*, DC*
!===============================================================================
MODULE RT_Asm_ShapeScalarField
  ! INTF-001 合规：Shape_Eval 扁参为热路径渐进迁移；调用侧 SIO 封装见装配主流程。
  USE IF_Base_Def, ONLY: TWO_PI
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Elem_Mgr, ONLY: ELEM_C3D4, ELEM_C3D5, ELEM_C3D13, ELEM_C3D8, ELEM_C3D8R, ELEM_C3D8I, ELEM_C3D8H, &
       ELEM_C3D10, ELEM_C3D20, ELEM_C3D20R, ELEM_C3D20I, ELEM_C3D20H, ELEM_C3D27, ELEM_C3D27R, &
       ELEM_C3D6, ELEM_C3D15, ELEM_C3D6R, ELEM_C3D15R, &
       ELEM_CPE3, ELEM_CPE4, ELEM_CPE4R, ELEM_CPE4H, ELEM_CPE4I, ELEM_CPE6, ELEM_CPE6R, &
       ELEM_CPE8, ELEM_CPE8R, ELEM_CPE8H, ELEM_CPE8I, &
       ELEM_CPEG4, ELEM_CPEG4R, ELEM_CPEG6, ELEM_CPEG8, &
       ELEM_CPS4, ELEM_CPS4R, ELEM_CPS4I, ELEM_CPS8, ELEM_CPS8R, &
       ELEM_CAX3, ELEM_CAX4, ELEM_CAX4R, ELEM_CAX4H, ELEM_CAX6, ELEM_CAX8, ELEM_CAX8R, ELEM_CAX8I, ELEM_CAX8H, &
       ELEM_DC2D4, ELEM_DC3D4, ELEM_DC3D8, &
       ELEM_AC3D4, ELEM_AC3D6, ELEM_AC3D8, ELEM_AC3D8R, ELEM_AC3D10, &
       ELEM_AC3D15, ELEM_AC3D20, &
       ELEM_AC2D3, ELEM_AC2D4, ELEM_AC2D4R, ELEM_AC2D6, ELEM_AC2D8, &
       ELEM_ACAX3, ELEM_ACAX4, ELEM_ACAX4R, ELEM_ACAX6, ELEM_ACAX8, &
       ELEM_T3D2, ELEM_B31, ELEM_S4, ELEM_S4R, ELEM_M3D4, ELEM_M3D4R
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
  USE PH_Elem_CPE3, ONLY: PH_Elem_CPE3_GaussPoints, PH_Elem_CPE3_JacB
  USE PH_Elem_CPE4, ONLY: PH_Elem_CPE4_GaussPoints, PH_Elem_CPE4_JacB
  USE PH_Elem_CPE6, ONLY: PH_Elem_CPE6_GaussPoints, PH_Elem_CPE6_JacB
  USE PH_Elem_CPE8, ONLY: PH_Elem_CPE8_GaussPoints, PH_Elem_CPE8_JacB
  USE PH_Elem_CAX3, ONLY: PH_Elem_CAX3_GaussPoints, PH_Elem_CAX3_JacB
  USE PH_Elem_CAX4, ONLY: PH_Elem_CAX4_GaussPoints, PH_Elem_CAX4_JacB
  USE PH_Elem_CAX6, ONLY: PH_Elem_CAX6_GaussPoints, PH_Elem_CAX6_JacB
  USE PH_Elem_CAX8, ONLY: PH_Elem_CAX8_GaussPoints, PH_Elem_CAX8_JacB
  USE PH_Elem_CPS4, ONLY: PH_Elem_CPS4_GaussPoints, PH_Elem_CPS4_JacB, PH_Elem_CPS4_ShapeFunc
  USE PH_Elem_Reg, ONLY: PH_Elem_Reg_GetBaseElemType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Asm_ShapeScalarField_GetNumGauss
  PUBLIC :: RT_Asm_ShapeScalarField_Eval
  PUBLIC :: RT_Asm_ShapeScalarField_Supported

CONTAINS

  !-----------------------------------------------------------------------------
  ! Get number of Gauss points for elem_type. Returns 0 if unsupported.
  !-----------------------------------------------------------------------------
  PURE FUNCTION RT_Asm_ShapeScalarField_GetNumGauss(elem_type_id, npe) RESULT(n_ip)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    INTEGER(i4) :: n_ip
    SELECT CASE (elem_type_id)
    CASE (ELEM_C3D4, ELEM_DC3D4, ELEM_AC3D4)
      n_ip = 1_i4
    CASE (ELEM_C3D5)
      n_ip = 8_i4
    CASE (ELEM_C3D13)
      n_ip = 8_i4
    CASE (ELEM_C3D8, ELEM_C3D8R, ELEM_C3D8I, ELEM_C3D8H, ELEM_DC3D8, ELEM_AC3D8, ELEM_AC3D8R)
      n_ip = 8_i4
    CASE (ELEM_C3D10, ELEM_AC3D10)
      n_ip = 4_i4
    CASE (ELEM_C3D20, ELEM_C3D20R, ELEM_C3D20I, ELEM_C3D20H, ELEM_AC3D20, ELEM_C3D27, ELEM_C3D27R)
      n_ip = 27_i4
    CASE (ELEM_C3D6, ELEM_C3D6R, ELEM_AC3D6)
      n_ip = 6_i4
    CASE (ELEM_C3D15, ELEM_C3D15R, ELEM_AC3D15)
      n_ip = 9_i4
    CASE (ELEM_CPE3, ELEM_AC2D3, ELEM_ACAX3)
      n_ip = 3_i4
    CASE (ELEM_CPE4, ELEM_CPE4R, ELEM_CPE4H, ELEM_CPE4I, ELEM_CPEG4, ELEM_CAX4, ELEM_CAX4R, ELEM_CAX4H, ELEM_DC2D4, ELEM_AC2D4, ELEM_AC2D4R, ELEM_ACAX4, ELEM_ACAX4R)
      n_ip = 4_i4
    CASE (ELEM_CPEG4R, ELEM_CPS4R)
      n_ip = 1_i4
    CASE (ELEM_CPE6, ELEM_CPE6R, ELEM_CPEG6, ELEM_AC2D6, ELEM_ACAX6)
      n_ip = 3_i4
    CASE (ELEM_CPS4, ELEM_CPS4I)
      n_ip = 4_i4
    CASE (ELEM_CPS8, ELEM_CPS8R)
      n_ip = 9_i4
    CASE (ELEM_CPE8, ELEM_CPE8R, ELEM_CPE8H, ELEM_CPE8I, ELEM_CPEG8, ELEM_CAX8, ELEM_CAX8R, ELEM_CAX8I, ELEM_CAX8H, ELEM_AC2D8, ELEM_ACAX8)
      n_ip = 9_i4
    CASE (ELEM_T3D2, ELEM_B31)
      n_ip = 1_i4
    CASE (ELEM_S4, ELEM_M3D4)
      n_ip = 4_i4
    CASE (ELEM_S4R, ELEM_M3D4R)
      n_ip = 1_i4
    CASE (0_i4)
      IF (npe == 3_i4) n_ip = 3_i4
      IF (npe == 4_i4) n_ip = 1_i4
      IF (npe == 5_i4) n_ip = 8_i4
      IF (npe == 6_i4) n_ip = 6_i4
      IF (npe == 8_i4) n_ip = 8_i4
      IF (npe == 10_i4) n_ip = 4_i4
      IF (npe == 13_i4) n_ip = 8_i4
      IF (npe == 15_i4) n_ip = 9_i4
      IF (npe == 20_i4) n_ip = 27_i4
      IF (npe == 27_i4) n_ip = 27_i4
      IF (npe == 2_i4) n_ip = 1_i4
      IF (npe /= 2_i4 .AND. npe /= 3_i4 .AND. npe /= 4_i4 .AND. npe /= 5_i4 .AND. npe /= 6_i4 .AND. npe /= 8_i4 .AND. &
          npe /= 10_i4 .AND. npe /= 13_i4 .AND. npe /= 15_i4 .AND. npe /= 20_i4 .AND. npe /= 27_i4) n_ip = 0_i4
    CASE DEFAULT
      n_ip = 0_i4
    END SELECT
  END FUNCTION RT_Asm_ShapeScalarField_GetNumGauss

  !-----------------------------------------------------------------------------
  ! Check if elem_type is supported for scalar field assembly.
  !-----------------------------------------------------------------------------
  PURE FUNCTION RT_Asm_ShapeScalarField_Supported(elem_type_id, npe) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    LOGICAL :: ok
    ok = (RT_Asm_ShapeScalarField_GetNumGauss(elem_type_id, npe) > 0_i4)
  END FUNCTION RT_Asm_ShapeScalarField_Supported

  !-----------------------------------------------------------------------------
  ! Eval: Get N, dNdx, detJ, weight at Gauss point ip for elem_type.
  !   coords(3, npe), N(npe), dNdx(3, npe). npe>=2 (1D), npe>=3 (2D), npe>=4 (3D).
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Asm_ShapeScalarField_Eval(elem_type_id, coords, npe, ip, N, dNdx, detJ, weight, status)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe, ip
    REAL(wp), INTENT(IN) :: coords(3, *)
    REAL(wp), INTENT(OUT) :: N(*), dNdx(3, *)
    REAL(wp), INTENT(OUT) :: detJ, weight
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_ip, et
    TYPE(PH_Elem_C3D8_JacB_In) :: in_jacb
    TYPE(PH_Elem_C3D8_JacB_Out) :: out_jacb
    REAL(wp) :: xi(27), eta(27), zeta(27), weights(27)
    REAL(wp) :: coords4(3, 4), coords8(3, 8), coords10(3, 10), coords6(3, 6), coords15(3, 15)
    REAL(wp) :: coords2d_3(2, 3), coords2d_4(2, 4), coords2d_6(2, 6), coords2d_8(2, 8)
    REAL(wp) :: N4(4), dNdx4(3, 4), N10(10), dNdx10(3, 10), N6(6), dNdx6(3, 6), N15(15), dNdx15(3, 15)
    REAL(wp) :: N3_2d(3), dNdx3_2d(2, 3), N4_2d(4), dNdx4_2d(2, 4)
    REAL(wp) :: N6_2d(6), dNdx6_2d(2, 6), N8_2d(8), dNdx8_2d(2, 8)
    REAL(wp) :: xi_2d(9), eta_2d(9), weights_2d(9)
    REAL(wp) :: J_dum(3, 3), J2_dum(2, 2), B_dum(6, 45), B_dum_2d(4, 16)
    REAL(wp) :: r_pt

    CALL init_error_status(status)
    detJ = 0.0_wp
    weight = 0.0_wp
    et = elem_type_id
    IF (et == 0_i4) THEN
      IF (npe == 2_i4) et = ELEM_T3D2
      IF (npe == 3_i4) et = ELEM_CPE3
      IF (npe == 4_i4) et = ELEM_C3D4
      IF (npe == 5_i4) et = ELEM_C3D5
      IF (npe == 6_i4) et = ELEM_C3D6
      IF (npe == 8_i4) et = ELEM_C3D8
      IF (npe == 10_i4) et = ELEM_C3D10
      IF (npe == 13_i4) et = ELEM_C3D13
      IF (npe == 15_i4) et = ELEM_C3D15
      IF (npe == 20_i4) et = ELEM_C3D20
      IF (npe == 27_i4) et = ELEM_C3D27
    END IF

    ! 2D elements: coords(1:2, 1:npe); dNdx(1:2,:) filled, dNdx(3,:)=0
    SELECT CASE (et)
    CASE (ELEM_C3D4, ELEM_DC3D4, ELEM_AC3D4)
      n_ip = 1_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 4_i4) RETURN
      coords4(1:3, 1:4) = coords(1:3, 1:4)
      CALL PH_Elem_C3D4_GaussPoints(xi(1:1), eta(1:1), zeta(1:1), weights(1:1))
      CALL PH_Elem_C3D4_JacB(coords4, xi(1), eta(1), zeta(1), N4, dNdx4, J_dum, detJ, B_dum(1:6,1:12))
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
        CALL PH_Elem_C3D5_JacB(coords5, xi5(ip), eta5(ip), zeta5(ip), N5, dNdx5, J_dum, detJ, B_dum(1:6, 1:15))
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
        CALL PH_Elem_C3D13_JacB(coords13, xi13(ip), eta13(ip), zeta13(ip), N13, dNdx13, J_dum, detJ, B_dum(1:6, 1:39))
        N(1:13) = N13
        dNdx(1:3, 1:13) = dNdx13
        weight = wt13(ip)
      END BLOCK

    CASE (ELEM_C3D8, ELEM_C3D8R, ELEM_C3D8I, ELEM_C3D8H, ELEM_DC3D8, ELEM_AC3D8, ELEM_AC3D8R)
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
      detJ = out_jacb%detJ
      weight = weights(ip)

    CASE (ELEM_C3D10, ELEM_AC3D10)
      n_ip = 4_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 10_i4) RETURN
      coords10(1:3, 1:10) = coords(1:3, 1:10)
      CALL PH_Elem_C3D10_GaussPoints(xi(1:4), eta(1:4), zeta(1:4), weights(1:4))
      CALL PH_Elem_C3D10_JacB(coords10, xi(ip), eta(ip), zeta(ip), N10, dNdx10, J_dum, detJ, B_dum(1:6,1:30))
      N(1:10) = N10
      dNdx(1:3, 1:10) = dNdx10
      weight = weights(ip)

    CASE (ELEM_C3D6, ELEM_C3D6R, ELEM_AC3D6)
      n_ip = 6_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 6_i4) RETURN
      coords6(1:3, 1:6) = coords(1:3, 1:6)
      CALL PH_Elem_C3D6_GaussPoints(xi(1:6), eta(1:6), zeta(1:6), weights(1:6))
      CALL PH_Elem_C3D6_JacB(coords6, xi(ip), eta(ip), zeta(ip), N6, dNdx6, J_dum, detJ, B_dum(1:6,1:18))
      N(1:6) = N6
      dNdx(1:3, 1:6) = dNdx6
      weight = weights(ip)

    CASE (ELEM_C3D15, ELEM_C3D15R, ELEM_AC3D15)
      n_ip = 9_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 15_i4) RETURN
      coords15(1:3, 1:15) = coords(1:3, 1:15)
      CALL PH_Elem_C3D15_GaussPoints(xi(1:9), eta(1:9), zeta(1:9), weights(1:9))
      CALL PH_Elem_C3D15_JacB(coords15, xi(ip), eta(ip), zeta(ip), N15, dNdx15, J_dum, detJ, B_dum(1:6,1:45))
      N(1:15) = N15
      dNdx(1:3, 1:15) = dNdx15
      weight = weights(ip)

    CASE (ELEM_C3D20, ELEM_C3D20R, ELEM_C3D20I, ELEM_C3D20H, ELEM_AC3D20)
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
        detJ = out_j20%state%detJ
        weight = wt20(ip)
      END BLOCK
      status%status_code = IF_STATUS_OK
      RETURN

    CASE (ELEM_C3D27)
      n_ip = 27_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 27_i4) RETURN
      BLOCK
        REAL(wp) :: xi27(27), eta27(27), zeta27(27), wt27(27)
        REAL(wp) :: coords27(3, 27), N27(27), dNdx27(3, 27), B27(6, 81)
        coords27(1:3, 1:27) = coords(1:3, 1:27)
        CALL PH_Elem_C3D27_GaussPoints(xi27, eta27, zeta27, wt27)
        CALL PH_Elem_C3D27_JacB(coords27, xi27(ip), eta27(ip), zeta27(ip), N27, dNdx27, J_dum, detJ, B27)
        N(1:27) = N27
        dNdx(1:3, 1:27) = dNdx27
        weight = wt27(ip)
      END BLOCK
      status%status_code = IF_STATUS_OK
      RETURN

    ! --- 2D plane: CPE3, AC2D3 (3-node triangle) ---
    CASE (ELEM_CPE3, ELEM_AC2D3)
      n_ip = 3_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 3_i4) RETURN
      coords2d_3(1:2, 1:3) = coords(1:2, 1:3)
      CALL PH_Elem_CPE3_GaussPoints(xi_2d(1:3), eta_2d(1:3), weights_2d(1:3))
      CALL PH_Elem_CPE3_JacB(coords2d_3, xi_2d(ip), eta_2d(ip), N3_2d, dNdx3_2d, J2_dum, detJ, B_dum_2d(1:3, 1:6))
      IF (ABS(detJ) <= 1.0e-12_wp) RETURN
      N(1:3) = N3_2d
      dNdx(1:2, 1:3) = dNdx3_2d
      dNdx(3, 1:3) = 0.0_wp
      weight = weights_2d(ip)

    ! --- 2D plane: CPE6, AC2D6 (6-node triangle) ---
    CASE (ELEM_CPE6, ELEM_AC2D6)
      n_ip = 3_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 6_i4) RETURN
      coords2d_6(1:2, 1:6) = coords(1:2, 1:6)
      CALL PH_Elem_CPE6_GaussPoints(xi_2d(1:3), eta_2d(1:3), weights_2d(1:3))
      CALL PH_Elem_CPE6_JacB(coords2d_6, xi_2d(ip), eta_2d(ip), N6_2d, dNdx6_2d, J2_dum, detJ, B_dum_2d(1:3, 1:12))
      IF (ABS(detJ) <= 1.0e-12_wp) RETURN
      N(1:6) = N6_2d
      dNdx(1:2, 1:6) = dNdx6_2d
      dNdx(3, 1:6) = 0.0_wp
      weight = weights_2d(ip)

    ! --- 2D plane: CPE4, CPE4R, DC2D4, AC2D4, AC2D4R ---
    CASE (ELEM_CPE4, ELEM_CPE4R, ELEM_DC2D4, ELEM_AC2D4, ELEM_AC2D4R)
      n_ip = 4_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 4_i4) RETURN
      coords2d_4(1:2, 1:4) = coords(1:2, 1:4)
      CALL PH_Elem_CPE4_GaussPoints(xi_2d(1:4), eta_2d(1:4), weights_2d(1:4))
      CALL PH_Elem_CPE4_JacB(coords2d_4, xi_2d(ip), eta_2d(ip), N4_2d, dNdx4_2d, J2_dum, detJ, B_dum_2d(1:3, 1:8))
      IF (ABS(detJ) <= 1.0e-12_wp) RETURN
      N(1:4) = N4_2d
      dNdx(1:2, 1:4) = dNdx4_2d
      dNdx(3, 1:4) = 0.0_wp
      weight = weights_2d(ip)

    ! --- 2D plane: CPE8, CPE8R, AC2D8 ---
    CASE (ELEM_CPE8, ELEM_CPE8R, ELEM_AC2D8)
      n_ip = 9_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 8_i4) RETURN
      coords2d_8(1:2, 1:8) = coords(1:2, 1:8)
      CALL PH_Elem_CPE8_GaussPoints(xi_2d, eta_2d, weights_2d)
      CALL PH_Elem_CPE8_JacB(coords2d_8, xi_2d(ip), eta_2d(ip), N8_2d, dNdx8_2d, J2_dum, detJ, B_dum_2d(1:3, 1:16))
      IF (ABS(detJ) <= 1.0e-12_wp) RETURN
      N(1:8) = N8_2d
      dNdx(1:2, 1:8) = dNdx8_2d
      dNdx(3, 1:8) = 0.0_wp
      weight = weights_2d(ip)

    ! --- 2D axisymmetric: CAX3, ACAX3 (dV = 2*pi*r*detJ*w) ---
    CASE (ELEM_CAX3, ELEM_ACAX3)
      n_ip = 3_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 3_i4) RETURN
      coords2d_3(1:2, 1:3) = coords(1:2, 1:3)
      CALL PH_Elem_CAX3_GaussPoints(xi_2d(1:3), eta_2d(1:3), weights_2d(1:3))
      CALL PH_Elem_CAX3_JacB(coords2d_3, xi_2d(ip), eta_2d(ip), N3_2d, dNdx3_2d, J2_dum, detJ, r_pt, B_dum_2d)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) RETURN
      N(1:3) = N3_2d
      dNdx(1:2, 1:3) = dNdx3_2d
      dNdx(3, 1:3) = 0.0_wp
      weight = TWO_PI * r_pt * weights_2d(ip)

    ! --- 2D axisymmetric: CAX6, ACAX6 (dV = 2*pi*r*detJ*w) ---
    CASE (ELEM_CAX6, ELEM_ACAX6)
      n_ip = 3_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 6_i4) RETURN
      coords2d_6(1:2, 1:6) = coords(1:2, 1:6)
      CALL PH_Elem_CAX6_GaussPoints(xi_2d(1:3), eta_2d(1:3), weights_2d(1:3))
      CALL PH_Elem_CAX6_JacB(coords2d_6, xi_2d(ip), eta_2d(ip), N6_2d, dNdx6_2d, J2_dum, detJ, r_pt, B_dum_2d)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) RETURN
      N(1:6) = N6_2d
      dNdx(1:2, 1:6) = dNdx6_2d
      dNdx(3, 1:6) = 0.0_wp
      weight = TWO_PI * r_pt * weights_2d(ip)

    ! --- 2D axisymmetric: CAX4, CAX4R, ACAX4 (dV = 2*pi*r*detJ*w) ---
    CASE (ELEM_CAX4, ELEM_CAX4R, ELEM_ACAX4)
      n_ip = 4_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 4_i4) RETURN
      coords2d_4(1:2, 1:4) = coords(1:2, 1:4)
      CALL PH_Elem_CAX4_GaussPoints(xi_2d(1:4), eta_2d(1:4), weights_2d(1:4))
      CALL PH_Elem_CAX4_JacB(coords2d_4, xi_2d(ip), eta_2d(ip), N4_2d, dNdx4_2d, J2_dum, detJ, r_pt, B_dum_2d)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) RETURN
      N(1:4) = N4_2d
      dNdx(1:2, 1:4) = dNdx4_2d
      dNdx(3, 1:4) = 0.0_wp
      weight = TWO_PI * r_pt * weights_2d(ip)

    ! --- 2D axisymmetric: CAX8, CAX8R, ACAX8 (dV = 2*pi*r*detJ*w) ---
    CASE (ELEM_CAX8, ELEM_CAX8R, ELEM_ACAX8)
      n_ip = 9_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 8_i4) RETURN
      coords2d_8(1:2, 1:8) = coords(1:2, 1:8)
      CALL PH_Elem_CAX8_GaussPoints(xi_2d, eta_2d, weights_2d)
      CALL PH_Elem_CAX8_JacB(coords2d_8, xi_2d(ip), eta_2d(ip), N8_2d, dNdx8_2d, J2_dum, detJ, r_pt, B_dum_2d)
      IF (ABS(detJ) <= 1.0e-12_wp .OR. r_pt < 1.0e-12_wp) RETURN
      N(1:8) = N8_2d
      dNdx(1:2, 1:8) = dNdx8_2d
      dNdx(3, 1:8) = 0.0_wp
      weight = TWO_PI * r_pt * weights_2d(ip)

    ! --- 1D: T3D2 (truss), B31 (beam axial) ---
    CASE (ELEM_T3D2, ELEM_B31)
      n_ip = 1_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 2_i4) RETURN
      BLOCK
        REAL(wp) :: dx, dy, dz, L, invL, e_dir(3), xi_1d
        xi_1d = 0.0_wp
        N(1) = 0.5_wp * (1.0_wp - xi_1d)
        N(2) = 0.5_wp * (1.0_wp + xi_1d)
        dx = coords(1, 2) - coords(1, 1)
        dy = coords(2, 2) - coords(2, 1)
        dz = coords(3, 2) - coords(3, 1)
        L = SQRT(dx*dx + dy*dy + dz*dz)
        IF (L <= 1.0e-12_wp) RETURN
        invL = 1.0_wp / L
        e_dir(1) = dx * invL
        e_dir(2) = dy * invL
        e_dir(3) = dz * invL
        dNdx(1, 1) = -e_dir(1) * invL
        dNdx(2, 1) = -e_dir(2) * invL
        dNdx(3, 1) = -e_dir(3) * invL
        dNdx(1, 2) =  e_dir(1) * invL
        dNdx(2, 2) =  e_dir(2) * invL
        dNdx(3, 2) =  e_dir(3) * invL
        detJ = L * 0.5_wp
        weight = 2.0_wp
      END BLOCK

    ! --- 3D surface: S4, M3D4 (4-node shell/membrane) ---
    CASE (ELEM_S4, ELEM_M3D4)
      n_ip = 4_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 4_i4) RETURN
      BLOCK
        REAL(wp) :: xi_pt, eta_pt, N4s(4), dNdxi_s(2, 4)
        REAL(wp) :: dr_dxi(3), dr_deta(3), g11, g12, g22, detg, ginv11, ginv12, ginv22
        REAL(wp) :: a, b
        INTEGER(i4) :: ii
        CALL PH_Elem_CPS4_GaussPoints(xi_2d(1:4), eta_2d(1:4), weights_2d(1:4))
        xi_pt = xi_2d(ip)
        eta_pt = eta_2d(ip)
        CALL PH_Elem_CPS4_ShapeFunc(xi_pt, eta_pt, N4s, dNdxi_s)
        dr_dxi = 0.0_wp
        dr_deta = 0.0_wp
        DO ii = 1, 4
          dr_dxi(1:3) = dr_dxi(1:3) + dNdxi_s(1, ii) * coords(1:3, ii)
          dr_deta(1:3) = dr_deta(1:3) + dNdxi_s(2, ii) * coords(1:3, ii)
        END DO
        g11 = dr_dxi(1)*dr_dxi(1) + dr_dxi(2)*dr_dxi(2) + dr_dxi(3)*dr_dxi(3)
        g12 = dr_dxi(1)*dr_deta(1) + dr_dxi(2)*dr_deta(2) + dr_dxi(3)*dr_deta(3)
        g22 = dr_deta(1)*dr_deta(1) + dr_deta(2)*dr_deta(2) + dr_deta(3)*dr_deta(3)
        detg = g11*g22 - g12*g12
        IF (detg <= 1.0e-24_wp) RETURN
        detJ = SQRT(detg)
        ginv11 = g22 / detg
        ginv12 = -g12 / detg
        ginv22 = g11 / detg
        N(1:4) = N4s
        DO ii = 1, 4
          a = ginv11 * dNdxi_s(1, ii) + ginv12 * dNdxi_s(2, ii)
          b = ginv12 * dNdxi_s(1, ii) + ginv22 * dNdxi_s(2, ii)
          dNdx(1:3, ii) = a * dr_dxi(1:3) + b * dr_deta(1:3)
        END DO
        weight = weights_2d(ip)
      END BLOCK

    ! --- 3D surface reduced: S4R, M3D4R (1 GP at center, weight=4) ---
    CASE (ELEM_S4R, ELEM_M3D4R)
      n_ip = 1_i4
      IF (ip < 1_i4 .OR. ip > n_ip .OR. npe < 4_i4) RETURN
      BLOCK
        REAL(wp) :: xi_pt, eta_pt, N4s(4), dNdxi_s(2, 4)
        REAL(wp) :: dr_dxi(3), dr_deta(3), g11, g12, g22, detg, ginv11, ginv12, ginv22
        REAL(wp) :: a, b
        INTEGER(i4) :: ii
        xi_pt = 0.0_wp
        eta_pt = 0.0_wp
        CALL PH_Elem_CPS4_ShapeFunc(xi_pt, eta_pt, N4s, dNdxi_s)
        dr_dxi = 0.0_wp
        dr_deta = 0.0_wp
        DO ii = 1, 4
          dr_dxi(1:3) = dr_dxi(1:3) + dNdxi_s(1, ii) * coords(1:3, ii)
          dr_deta(1:3) = dr_deta(1:3) + dNdxi_s(2, ii) * coords(1:3, ii)
        END DO
        g11 = dr_dxi(1)*dr_dxi(1) + dr_dxi(2)*dr_dxi(2) + dr_dxi(3)*dr_dxi(3)
        g12 = dr_dxi(1)*dr_deta(1) + dr_dxi(2)*dr_deta(2) + dr_dxi(3)*dr_deta(3)
        g22 = dr_deta(1)*dr_deta(1) + dr_deta(2)*dr_deta(2) + dr_deta(3)*dr_deta(3)
        detg = g11*g22 - g12*g12
        IF (detg <= 1.0e-24_wp) RETURN
        detJ = SQRT(detg)
        ginv11 = g22 / detg
        ginv12 = -g12 / detg
        ginv22 = g11 / detg
        N(1:4) = N4s
        DO ii = 1, 4
          a = ginv11 * dNdxi_s(1, ii) + ginv12 * dNdxi_s(2, ii)
          b = ginv12 * dNdxi_s(1, ii) + ginv22 * dNdxi_s(2, ii)
          dNdx(1:3, ii) = a * dr_dxi(1:3) + b * dr_deta(1:3)
        END DO
        weight = 4.0_wp
      END BLOCK

    CASE DEFAULT
      ! Fallback: try base_elem_type for shape reuse (Option B)
      BLOCK
        INTEGER(i4) :: base_et
        base_et = PH_Elem_Reg_GetBaseElemType(elem_type_id)
        IF (base_et > 0_i4 .AND. base_et /= elem_type_id) THEN
          CALL RT_Asm_ShapeScalarField_Eval(base_et, coords, npe, ip, N, dNdx, detJ, weight, status)
          RETURN
        END IF
      END BLOCK
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_AsmShapeScalarField: unsupported elem_type'
      RETURN
    END SELECT
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_ShapeScalarField_Eval

END MODULE RT_Asm_ShapeScalarField