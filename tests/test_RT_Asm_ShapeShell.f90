!===============================================================================
! test_RT_Asm_ShapeShell: Unit test for RT_Asm_ShapeShell (shell B-matrix)
! Run: BUILD_TESTING=ON, cmake --build build, ctest -R RT_Asm_ShapeShell
!
! Theory: Shell strain B_shell; S4/S4R membrane delegates to CPS4.
!         Unit square in xy plane: (0,0,0), (1,0,0), (1,1,0), (0,1,0)
!===============================================================================
program test_RT_Asm_ShapeShell
  use IF_Prec_Core, only: wp, i4
  use IF_Err_API, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  use MD_Elem_Core, only: ELEM_S4, ELEM_S4R, ELEM_S8
  use RT_Asm_ShapeShell, only: RT_Asm_ShapeShell_GetNumGauss, &
       RT_Asm_ShapeShell_Supported, RT_Asm_ShapeShell_Eval
  implicit none

  type(ErrorStatusType) :: st
  real(wp) :: coords(3, 4), N(8), dNdx(3, 8), B_shell(6, 48)
  real(wp) :: detJ, weight, tol, sum_detJ_w
  integer(i4) :: n_ip, ip

  tol = 1.0e-10_wp

  ! --- GetNumGauss ---
  n_ip = RT_Asm_ShapeShell_GetNumGauss(ELEM_S4, 4_i4)
  if (n_ip /= 4) then
    write(*,*) 'FAIL: GetNumGauss(S4,4)=', n_ip, ' expected 4'
    stop 1
  endif

  n_ip = RT_Asm_ShapeShell_GetNumGauss(ELEM_S4R, 4_i4)
  if (n_ip /= 1) then
    write(*,*) 'FAIL: GetNumGauss(S4R,4)=', n_ip, ' expected 1'
    stop 1
  endif

  n_ip = RT_Asm_ShapeShell_GetNumGauss(ELEM_S8, 8_i4)
  if (n_ip /= 9) then
    write(*,*) 'FAIL: GetNumGauss(S8,8)=', n_ip, ' expected 9'
    stop 1
  endif

  ! --- Supported ---
  if (.not. RT_Asm_ShapeShell_Supported(ELEM_S4, 4_i4)) then
    write(*,*) 'FAIL: Supported(S4,4) should be true'
    stop 1
  endif

  if (.not. RT_Asm_ShapeShell_Supported(ELEM_S4R, 4_i4)) then
    write(*,*) 'FAIL: Supported(S4R,4) should be true'
    stop 1
  endif

  ! --- Eval: unit square in xy plane (0,0,0), (1,0,0), (1,1,0), (0,1,0) - S4 ---
  coords(1, 1) = 0.0_wp
  coords(2, 1) = 0.0_wp
  coords(3, 1) = 0.0_wp
  coords(1, 2) = 1.0_wp
  coords(2, 2) = 0.0_wp
  coords(3, 2) = 0.0_wp
  coords(1, 3) = 1.0_wp
  coords(2, 3) = 1.0_wp
  coords(3, 3) = 0.0_wp
  coords(1, 4) = 0.0_wp
  coords(2, 4) = 1.0_wp
  coords(3, 4) = 0.0_wp

  sum_detJ_w = 0.0_wp
  do ip = 1, 4
    call init_error_status(st)
    call RT_Asm_ShapeShell_Eval(ELEM_S4, coords, 4_i4, ip, N, dNdx, B_shell, detJ, weight, st)
    if (st%status_code /= IF_STATUS_OK) then
      write(*,*) 'FAIL: Eval S4 ip=', ip, ' status=', st%status_code
      stop 1
    endif
    if (detJ <= 0.0_wp .or. weight <= 0.0_wp) then
      write(*,*) 'FAIL: Eval S4 ip=', ip, ' detJ=', detJ, ' weight=', weight
      stop 1
    endif
    sum_detJ_w = sum_detJ_w + detJ * weight
  enddo

  ! Sum of detJ*weight over 4 GPs should equal area = 1.0
  if (abs(sum_detJ_w - 1.0_wp) > tol) then
    write(*,*) 'FAIL: sum(detJ*weight)=', sum_detJ_w, ' expected 1.0'
    stop 1
  endif

  ! --- Eval: S4R single GP ---
  call init_error_status(st)
  call RT_Asm_ShapeShell_Eval(ELEM_S4R, coords, 4_i4, 1_i4, N, dNdx, B_shell, detJ, weight, st)
  if (st%status_code /= IF_STATUS_OK) then
    write(*,*) 'FAIL: Eval S4R status=', st%status_code
    stop 1
  endif
  if (abs(detJ - 1.0_wp) > tol) then
    write(*,*) 'FAIL: S4R detJ=', detJ, ' expected 1.0'
    stop 1
  endif
  if (abs(weight - 4.0_wp) > tol) then
    write(*,*) 'FAIL: S4R weight=', weight, ' expected 4.0'
    stop 1
  endif

  write(*,*) 'PASS: RT_Asm_ShapeShell unit test'
end program test_RT_Asm_ShapeShell
