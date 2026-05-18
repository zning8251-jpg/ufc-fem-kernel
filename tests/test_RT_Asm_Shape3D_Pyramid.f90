!===============================================================================
! test_RT_Asm_Shape3D_Pyramid: L5 RT_Asm_ShapeMechanicalField / ScalarField
!   regression for C3D5 / C3D13 (8 GP), volume via sum(detJ*weight).
! Run: cmake -S UFC -B UFC/build -DBUILD_TESTING=ON; cmake --build UFC/build
!      ctest -R Shape3D_Pyramid --output-on-failure
!===============================================================================
program test_RT_Asm_Shape3D_Pyramid
  use IF_Prec_Core, only: wp, i4
  use IF_Err_API, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  use MD_Elem_Core, only: ELEM_C3D5, ELEM_C3D13
  use RT_Asm_ShapeMechanicalField, only: RT_Asm_ShapeMechanicalField_GetNumGauss, &
       RT_Asm_ShapeMechanicalField_Supported, RT_Asm_ShapeMechanicalField_Eval
  use RT_Asm_ShapeScalarField, only: RT_Asm_ShapeScalarField_GetNumGauss, &
       RT_Asm_ShapeScalarField_Supported, RT_Asm_ShapeScalarField_Eval
  implicit none

  type(ErrorStatusType) :: st
  real(wp), parameter :: expect_vol = 1.0_wp / 3.0_wp
  real(wp) :: coords5(3, 5), coords13(3, 13)
  real(wp) :: N_mech(13), dNdx_mech(3, 13), B_u(6, 45)
  real(wp) :: N_sca(13), dNdx_sca(3, 13)
  real(wp) :: detJ, weight, tol, sum_m, sum_s
  integer(i4) :: n_ip, ip

  tol = 5.0e-6_wp

  ! --- Reference pyramid: unit square base z=0, apex (0.5,0.5,1); V = 1/3 ---
  ! C3D5: nodes 1�? base corners, 5 apex (see PH_Elem_C3D5_Core header).
  coords5(1:3, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
  coords5(1:3, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
  coords5(1:3, 3) = [1.0_wp, 1.0_wp, 0.0_wp]
  coords5(1:3, 4) = [0.0_wp, 1.0_wp, 0.0_wp]
  coords5(1:3, 5) = [0.5_wp, 0.5_wp, 1.0_wp]

  ! C3D13 ABAQUS order: 1�? corners, 5�? base edge mids, 9�?2 lateral mids, 13 apex.
  coords13(1:3, 1) = coords5(1:3, 1)
  coords13(1:3, 2) = coords5(1:3, 2)
  coords13(1:3, 3) = coords5(1:3, 3)
  coords13(1:3, 4) = coords5(1:3, 4)
  coords13(1:3, 5) = [0.5_wp, 0.0_wp, 0.0_wp]
  coords13(1:3, 6) = [1.0_wp, 0.5_wp, 0.0_wp]
  coords13(1:3, 7) = [0.5_wp, 1.0_wp, 0.0_wp]
  coords13(1:3, 8) = [0.0_wp, 0.5_wp, 0.0_wp]
  coords13(1:3, 9) = [0.25_wp, 0.25_wp, 0.5_wp]
  coords13(1:3, 10) = [0.75_wp, 0.25_wp, 0.5_wp]
  coords13(1:3, 11) = [0.75_wp, 0.75_wp, 0.5_wp]
  coords13(1:3, 12) = [0.25_wp, 0.75_wp, 0.5_wp]
  coords13(1:3, 13) = coords5(1:3, 5)

  ! --- Mechanical: GetNumGauss / Supported ---
  n_ip = RT_Asm_ShapeMechanicalField_GetNumGauss(ELEM_C3D5, 5_i4)
  if (n_ip /= 8_i4) then
    write(*,*) 'FAIL: Mech GetNumGauss(C3D5)=', n_ip, ' expected 8'
    stop 1
  endif
  n_ip = RT_Asm_ShapeMechanicalField_GetNumGauss(ELEM_C3D13, 13_i4)
  if (n_ip /= 8_i4) then
    write(*,*) 'FAIL: Mech GetNumGauss(C3D13)=', n_ip, ' expected 8'
    stop 1
  endif
  if (.not. RT_Asm_ShapeMechanicalField_Supported(ELEM_C3D5, 5_i4)) then
    write(*,*) 'FAIL: Mech Supported(C3D5) should be true'
    stop 1
  endif
  if (.not. RT_Asm_ShapeMechanicalField_Supported(0_i4, 5_i4)) then
    write(*,*) 'FAIL: Mech Supported(0,npe=5) should map to C3D5'
    stop 1
  endif

  ! --- Scalar field: same counts ---
  n_ip = RT_Asm_ShapeScalarField_GetNumGauss(ELEM_C3D5, 5_i4)
  if (n_ip /= 8_i4) then
    write(*,*) 'FAIL: Scalar GetNumGauss(C3D5)=', n_ip, ' expected 8'
    stop 1
  endif
  n_ip = RT_Asm_ShapeScalarField_GetNumGauss(ELEM_C3D13, 13_i4)
  if (n_ip /= 8_i4) then
    write(*,*) 'FAIL: Scalar GetNumGauss(C3D13)=', n_ip, ' expected 8'
    stop 1
  endif

  ! --- Mechanical Eval C3D5: volume ---
  sum_m = 0.0_wp
  do ip = 1, 8
    call init_error_status(st)
    call RT_Asm_ShapeMechanicalField_Eval(ELEM_C3D5, coords5, 5_i4, ip, N_mech, dNdx_mech, &
         B_u, detJ, weight, st)
    if (st%status_code /= IF_STATUS_OK) then
      write(*,*) 'FAIL: Mech Eval C3D5 ip=', ip, ' status=', st%status_code
      stop 1
    endif
    if (detJ <= 0.0_wp .or. weight <= 0.0_wp) then
      write(*,*) 'FAIL: Mech C3D5 ip=', ip, ' detJ=', detJ, ' w=', weight
      stop 1
    endif
    sum_m = sum_m + detJ * weight
  enddo
  if (abs(sum_m - expect_vol) > tol) then
    write(*,*) 'FAIL: Mech C3D5 sum(detJ*w)=', sum_m, ' expected', expect_vol
    stop 1
  endif

  ! --- Mechanical Eval C3D13 ---
  sum_m = 0.0_wp
  do ip = 1, 8
    call init_error_status(st)
    call RT_Asm_ShapeMechanicalField_Eval(ELEM_C3D13, coords13, 13_i4, ip, N_mech, dNdx_mech, &
         B_u, detJ, weight, st)
    if (st%status_code /= IF_STATUS_OK) then
      write(*,*) 'FAIL: Mech Eval C3D13 ip=', ip, ' status=', st%status_code
      stop 1
    endif
    if (detJ <= 0.0_wp .or. weight <= 0.0_wp) then
      write(*,*) 'FAIL: Mech C3D13 ip=', ip, ' detJ=', detJ, ' w=', weight
      stop 1
    endif
    sum_m = sum_m + detJ * weight
  enddo
  if (abs(sum_m - expect_vol) > tol) then
    write(*,*) 'FAIL: Mech C3D13 sum(detJ*w)=', sum_m, ' expected', expect_vol
    stop 1
  endif

  ! --- Scalar Eval C3D5 / C3D13 (same geometry) ---
  sum_s = 0.0_wp
  do ip = 1, 8
    call init_error_status(st)
    call RT_Asm_ShapeScalarField_Eval(ELEM_C3D5, coords5, 5_i4, ip, N_sca, dNdx_sca, detJ, weight, st)
    if (st%status_code /= IF_STATUS_OK) then
      write(*,*) 'FAIL: Scalar Eval C3D5 ip=', ip
      stop 1
    endif
    sum_s = sum_s + detJ * weight
  enddo
  if (abs(sum_s - expect_vol) > tol) then
    write(*,*) 'FAIL: Scalar C3D5 sum(detJ*w)=', sum_s, ' expected', expect_vol
    stop 1
  endif

  sum_s = 0.0_wp
  do ip = 1, 8
    call init_error_status(st)
    call RT_Asm_ShapeScalarField_Eval(ELEM_C3D13, coords13, 13_i4, ip, N_sca, dNdx_sca, detJ, weight, st)
    if (st%status_code /= IF_STATUS_OK) then
      write(*,*) 'FAIL: Scalar Eval C3D13 ip=', ip
      stop 1
    endif
    sum_s = sum_s + detJ * weight
  enddo
  if (abs(sum_s - expect_vol) > tol) then
    write(*,*) 'FAIL: Scalar C3D13 sum(detJ*w)=', sum_s, ' expected', expect_vol
    stop 1
  endif

  write(*,*) 'OK: RT_Asm_Shape3D_Pyramid (C3D5/C3D13 mech+scalar volume checks)'
end program test_RT_Asm_Shape3D_Pyramid
