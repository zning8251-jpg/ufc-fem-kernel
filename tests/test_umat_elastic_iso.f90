!===============================================================================
! test_umat_elastic_iso: Unit test for UMAT_ElasticIso (mat_id 101)
! Run: BUILD_TESTING=ON, cmake --build build, ctest -R UMAT_ElasticIso
!===============================================================================
program test_umat_elastic_iso
  use IF_Prec_Core, only: wp
  use IF_Err_API, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  use PH_UMAT_Types, only: PH_UMAT_Context
  use PH_UMAT_ElasticIso, only: UMAT_ElasticIso
  implicit none

  type(PH_UMAT_Context) :: ctx
  type(ErrorStatusType) :: st
  real(wp) :: E, nu, tol, err
  integer :: i

  call init_error_status(st)
  E = 210000.0_wp
  nu = 0.3_wp
  tol = 1.0e-10_wp

  ! Init: 3D (ndi=3, nshr=3), nstatv=0, nprops=2
  call ctx%Init(ndi=3, nshr=3, nstatv=0, nprops=2)
  ctx%ndi = 3
  ctx%nshr = 3
  ctx%props(1) = E
  ctx%props(2) = nu

  ! Uniaxial strain: dstran = [0.001, 0, 0, 0, 0, 0]
  ctx%dstran = 0.0_wp
  ctx%dstran(1) = 0.001_wp

  call UMAT_ElasticIso(ctx, st)
  if (st%status_code /= IF_STATUS_OK) then
    write(*,*) 'FAIL: UMAT_ElasticIso returned status ', st%status_code, ' ', trim(st%message)
    call ctx%Cleanup()
    stop 1
  endif

  ! Check sigma_11 = E * strain_11 for uniaxial (nu=0.3: sigma_1 = E*(1-nu)/((1+nu)(1-2*nu))*e)
  ! For e=0.001: sigma_1 = 210000 * 0.7 / (1.3 * 0.4) * 0.001 = 282.69...
  err = abs(ctx%sigma(1) - 282.69230769230769_wp)
  if (err > tol) then
    write(*,*) 'FAIL: sigma(1)=', ctx%sigma(1), ' expected ~282.69, err=', err
    call ctx%Cleanup()
    stop 1
  endif

  ! Check ddsdde(1,1) = lambda + 2*mu
  err = abs(ctx%ddsdde(1,1) - (E*nu/((1+nu)*(1-2*nu)) + E/(1+nu)))
  if (err > tol) then
    write(*,*) 'FAIL: ddsdde(1,1)=', ctx%ddsdde(1,1), ' err=', err
    call ctx%Cleanup()
    stop 1
  endif

  call ctx%Cleanup()
  write(*,*) 'PASS: UMAT_ElasticIso unit test'
end program test_umat_elastic_iso
