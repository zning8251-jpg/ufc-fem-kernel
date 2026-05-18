!===============================================================================
! test_RT_Asm_ShapeMech2D: Unit test for RT_Asm_ShapeMech2D (2D mechanical B-matrix)
! Run: BUILD_TESTING=ON, cmake --build build, ctest -R RT_Asm_ShapeMech2D
!===============================================================================
program test_RT_Asm_ShapeMech2D
  use IF_Prec_Core, only: wp, i4
  use IF_Err_API, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  use MD_Elem_Core, only: ELEM_CPE4, ELEM_CPS4, ELEM_CAX4, ELEM_CPE4R, ELEM_CPS4R, &
       ELEM_CPE3, ELEM_CPS3, ELEM_CAX3
  use RT_Asm_ShapeMech2D, only: RT_Asm_ShapeMech2D_GetNumGauss, &
       RT_Asm_ShapeMech2D_Supported, RT_Asm_ShapeMech2D_Eval
  implicit none

  type(ErrorStatusType) :: st
  real(wp) :: coords4(2, 4), N(4), dNdx(2, 4), B_2d(4, 8)
  real(wp) :: detJ, weight, tol, sum_detJ_w
  integer(i4) :: n_ip, ip

  tol = 1.0e-10_wp

  ! --- GetNumGauss ---
  n_ip = RT_Asm_ShapeMech2D_GetNumGauss(ELEM_CPS4, 4_i4)
  if (n_ip /= 4) then
    write(*,*) 'FAIL: GetNumGauss(CPS4,4)=', n_ip, ' expected 4'
    stop 1
  endif

  n_ip = RT_Asm_ShapeMech2D_GetNumGauss(ELEM_CPE4R, 4_i4)
  if (n_ip /= 1) then
    write(*,*) 'FAIL: GetNumGauss(CPE4R,4)=', n_ip, ' expected 1'
    stop 1
  endif

  n_ip = RT_Asm_ShapeMech2D_GetNumGauss(ELEM_CPS3, 3_i4)
  if (n_ip /= 1) then
    write(*,*) 'FAIL: GetNumGauss(CPS3,3)=', n_ip, ' expected 1'
    stop 1
  endif

  ! --- Supported ---
  if (.not. RT_Asm_ShapeMech2D_Supported(ELEM_CPS4, 4_i4)) then
    write(*,*) 'FAIL: Supported(CPS4,4) should be true'
    stop 1
  endif

  if (.not. RT_Asm_ShapeMech2D_Supported(ELEM_CAX4, 4_i4)) then
    write(*,*) 'FAIL: Supported(CAX4,4) should be true'
    stop 1
  endif

  ! --- Eval: unit square (0,0), (1,0), (1,1), (0,1) - CPS4 ---
  coords4(1, 1) = 0.0_wp
  coords4(2, 1) = 0.0_wp
  coords4(1, 2) = 1.0_wp
  coords4(2, 2) = 0.0_wp
  coords4(1, 3) = 1.0_wp
  coords4(2, 3) = 1.0_wp
  coords4(1, 4) = 0.0_wp
  coords4(2, 4) = 1.0_wp

  sum_detJ_w = 0.0_wp
  do ip = 1, 4
    call init_error_status(st)
    call RT_Asm_ShapeMech2D_Eval(ELEM_CPS4, coords4, 4_i4, ip, N, dNdx, B_2d, detJ, weight, st)
    if (st%status_code /= IF_STATUS_OK) then
      write(*,*) 'FAIL: Eval CPS4 ip=', ip, ' status=', st%status_code
      stop 1
    endif
    if (detJ <= 0.0_wp .or. weight <= 0.0_wp) then
      write(*,*) 'FAIL: Eval CPS4 ip=', ip, ' detJ=', detJ, ' weight=', weight
      stop 1
    endif
    sum_detJ_w = sum_detJ_w + detJ * weight
  enddo

  ! Sum of detJ*weight over 4 GPs should equal area = 1.0
  if (abs(sum_detJ_w - 1.0_wp) > tol) then
    write(*,*) 'FAIL: sum(detJ*weight)=', sum_detJ_w, ' expected 1.0'
    stop 1
  endif

  ! --- Eval: 3-node triangle (0,0), (1,0), (0,1) - CPS3 ---
  coords4(1, 1) = 0.0_wp
  coords4(2, 1) = 0.0_wp
  coords4(1, 2) = 1.0_wp
  coords4(2, 2) = 0.0_wp
  coords4(1, 3) = 0.0_wp
  coords4(2, 3) = 1.0_wp

  call init_error_status(st)
  call RT_Asm_ShapeMech2D_Eval(ELEM_CPS3, coords4, 3_i4, 1_i4, N, dNdx, B_2d, detJ, weight, st)
  if (st%status_code /= IF_STATUS_OK) then
    write(*,*) 'FAIL: Eval CPS3 status=', st%status_code
    stop 1
  endif
  ! Triangle area = 0.5, detJ = area, weight = 0.5
  if (abs(detJ - 0.5_wp) > tol) then
    write(*,*) 'FAIL: CPS3 detJ=', detJ, ' expected 0.5'
    stop 1
  endif
  if (abs(weight - 0.5_wp) > tol) then
    write(*,*) 'FAIL: CPS3 weight=', weight, ' expected 0.5'
    stop 1
  endif
  ! N at centroid = 1/3 each
  if (abs(N(1) - 1.0_wp/3.0_wp) > tol .or. abs(N(2) - 1.0_wp/3.0_wp) > tol .or. &
      abs(N(3) - 1.0_wp/3.0_wp) > tol) then
    write(*,*) 'FAIL: CPS3 N=', N(1), N(2), N(3), ' expected 1/3 each'
    stop 1
  endif

  write(*,*) 'PASS: RT_Asm_ShapeMech2D unit test'
end program test_RT_Asm_ShapeMech2D
