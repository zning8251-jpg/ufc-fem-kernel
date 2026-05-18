!===============================================================================
! MODULE: RT_Asm_ShapeBeam
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Impl (shape/beam)
! BRIEF:  Beam B-matrix for B21/B31/B32 family -- axial+torsion+bending
!===============================================================================
MODULE RT_Asm_ShapeBeam
  ! INTF-001 合规：Shape_Eval 扁参为热路径渐进迁移；调用侧 SIO 封装见装配主流程。
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Elem_Mgr, ONLY: ELEM_B21, ELEM_B21H, ELEM_B22, ELEM_B22H, ELEM_B23, ELEM_B21T, &
       ELEM_B31, ELEM_B31H, ELEM_B31OS, ELEM_B32, ELEM_B32H, ELEM_B32OS, &
       ELEM_B33, ELEM_B33H, ELEM_B34, ELEM_B34H, ELEM_B31T, ELEM_B31EX
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Asm_ShapeBeam_GetNumGauss
  PUBLIC :: RT_Asm_ShapeBeam_Supported
  PUBLIC :: RT_Asm_ShapeBeam_Eval

CONTAINS

  PURE FUNCTION RT_Asm_ShapeBeam_GetNumGauss(elem_type_id, npe) RESULT(n_ip)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    INTEGER(i4) :: n_ip
    SELECT CASE (elem_type_id)
    CASE (ELEM_B21, ELEM_B21H, ELEM_B22, ELEM_B22H, ELEM_B23, ELEM_B21T)
      n_ip = 1_i4
    CASE (ELEM_B31, ELEM_B31H, ELEM_B31OS, ELEM_B32, ELEM_B32H, ELEM_B32OS, &
          ELEM_B33, ELEM_B33H, ELEM_B34, ELEM_B34H, ELEM_B31T, ELEM_B31EX)
      n_ip = 1_i4
    CASE DEFAULT
      IF (npe == 2_i4 .OR. npe == 3_i4) n_ip = 1_i4
      IF (npe /= 2_i4 .AND. npe /= 3_i4) n_ip = 0_i4
    END SELECT
  END FUNCTION RT_Asm_ShapeBeam_GetNumGauss

  PURE FUNCTION RT_Asm_ShapeBeam_Supported(elem_type_id, npe) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe
    LOGICAL :: ok
    ok = (RT_Asm_ShapeBeam_GetNumGauss(elem_type_id, npe) > 0_i4)
  END FUNCTION RT_Asm_ShapeBeam_Supported

  SUBROUTINE RT_Asm_ShapeBeam_Eval(elem_type_id, coords, npe, ip, N, dNdx, B_beam, detJ, weight, status)
    INTEGER(i4), INTENT(IN) :: elem_type_id, npe, ip
    REAL(wp), INTENT(IN) :: coords(3, *)
    REAL(wp), INTENT(OUT) :: N(*), dNdx(3, *)
    REAL(wp), INTENT(OUT) :: B_beam(6, *)
    REAL(wp), INTENT(OUT) :: detJ, weight
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: p1(3), p2(3), L
    REAL(wp), PARAMETER :: ZERO = 0.0_wp

    CALL init_error_status(status)
    detJ = 0.0_wp
    weight = 0.0_wp
    B_beam = 0.0_wp
    dNdx = 0.0_wp

    IF (npe < 2_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_Asm_ShapeBeam_Eval: npe < 2"
      RETURN
    END IF

    p1 = coords(1:3, 1)
    p2 = coords(1:3, npe)
    L = SQRT(SUM((p2 - p1)**2))
    IF (L <= 1.0e-12_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_Asm_ShapeBeam_Eval: zero length"
      RETURN
    END IF

    IF (ip /= 1_i4) RETURN

    ! 1-point Gauss at center: xi=0, weight=2, detJ = L/2
    detJ = L / 2.0_wp
    weight = 2.0_wp

    ! N at center: N1=0.5, N2=0.5 (2-node bar)
    N(1) = 0.5_wp
    N(2) = 0.5_wp
    IF (npe >= 3_i4) N(3) = ZERO

    ! Axial strain B: epsilon = (u_last-u_first)/L. DOF: 6 per node.
    ! u at col 1 (node1), col 6*(npe-1)+1 (last node)
    B_beam(1, 1) = -1.0_wp / L
    B_beam(1, 6*(npe-1)+1) = 1.0_wp / L
    ! dN/dx for 1D: dN1/dx=-1/L, dN2/dx=1/L (axial direction = (p2-p1)/L)
    dNdx(1, 1) = -1.0_wp / L
    dNdx(1, 2) = 1.0_wp / L
    dNdx(2:3, 1:npe) = ZERO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Asm_ShapeBeam_Eval

END MODULE RT_Asm_ShapeBeam