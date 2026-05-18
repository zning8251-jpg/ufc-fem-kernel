!===============================================================================
! test_defn_invoke_umat — smoke test for PH_Mat_Defn_UMAT_Bridge::Defn_Invoke_UMAT
! Run: cmake -DBUILD_TESTING=ON ... && ctest -R Defn_Invoke_UMAT
!===============================================================================
program test_defn_invoke_umat
  use IF_Prec_Core, only: wp, i4
  use IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  use MD_Mat_Lib, only: MatProperties
  use PH_Mat_Defn_UMAT_Bridge, only: Defn_Invoke_UMAT, Defn_Invoke_UMAT_Arg, PH_Mat_TypeToId, CAT_PLAST, &
      PH_MAT_ID_INVALID
  implicit none

  type(MatProperties) :: Mat
  type(ErrorStatusType) :: st
  type(Defn_Invoke_UMAT_Arg) :: du
  real(wp) :: strain_in(6), stress_out(6), tangent_out(6, 6)
  real(wp) :: E, nu, tol, err
  integer(i4) :: mid

  tol = 1.0e-5_wp

  E = 210000.0_wp
  nu = 0.3_wp
  call Mat%Init(props=[E, nu])
  strain_in = 0.0_wp
  strain_in(1) = 0.001_wp

  du%mat_id = 101_i4
  allocate(du%mat, source=Mat)
  du%strain_in = strain_in
  du%want_tangent = .true.
  call Defn_Invoke_UMAT(du)
  stress_out = du%stress_out
  tangent_out = du%tangent_out
  st = du%status
  if (allocated(du%mat)) deallocate(du%mat)

  if (st%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: Defn_Invoke_UMAT(101) returned ', st%status_code, ' ', trim(st%message)
    stop 1
  end if

  err = abs(stress_out(1) - 282.69230769230769_wp)
  if (err > tol) then
    write (*, *) 'FAIL: ElasticIso sigma(1)=', stress_out(1), ' expected ~282.69, err=', err
    stop 1
  end if

  call Mat%Init(props=[E, nu, 500.0_wp, 1000.0_wp])
  du%mat_id = 201_i4
  allocate(du%mat, source=Mat)
  du%strain_in = strain_in
  du%want_tangent = .true.
  call Defn_Invoke_UMAT(du)
  stress_out = du%stress_out
  tangent_out = du%tangent_out
  st = du%status
  if (allocated(du%mat)) deallocate(du%mat)

  if (st%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: Defn_Invoke_UMAT(201) returned ', st%status_code
    stop 1
  end if

  err = abs(stress_out(1) - 282.69230769230769_wp)
  if (err > tol) then
    write (*, *) 'FAIL: mat_id 201 stub sigma(1)=', stress_out(1), ' expected ~282.69'
    stop 1
  end if

  mid = PH_Mat_TypeToId(CAT_PLAST, 2_i4)
  if (mid /= 202_i4) then
    write (*, *) 'FAIL: PH_Mat_TypeToId(CAT_PLAST,2)=', mid, ' expected 202'
    stop 1
  end if
  mid = PH_Mat_TypeToId(CAT_PLAST, 13_i4)
  if (mid /= PH_MAT_ID_INVALID) then
    write (*, *) 'FAIL: deprecated plastic subtype 13 should map to INVALID, got ', mid
    stop 1
  end if

  du%mat_id = 202_i4
  allocate(du%mat, source=Mat)
  du%strain_in = strain_in
  du%want_tangent = .true.
  call Defn_Invoke_UMAT(du)
  st = du%status
  if (allocated(du%mat)) deallocate(du%mat)

  if (st%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: Defn_Invoke_UMAT(202) returned ', st%status_code
    stop 1
  end if

  write (*, *) 'PASS: Defn_Invoke_UMAT unit test (mat_id 101, 201, TypeToId+202)'
end program test_defn_invoke_umat
