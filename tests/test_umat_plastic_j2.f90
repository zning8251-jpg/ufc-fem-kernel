!===============================================================================
! test_umat_plastic_j2: Unit test for PH_Mat_PLM_J2_UMAT (mat_id 201 registry path)
! Run: BUILD_TESTING=ON, cmake --build build, ctest -R UMAT_PlasticJ2 (ctest name unchanged)
!
! Theory: J2 plasticity; props(1:4)=E,nu,sigma_y0,H; statev(1)=eq_pl, (2:7)=pl_strain
!         Elastic step: strain 0.001, sigma_y0=500 -> sigma ~282 (elastic)
!         Plastic step: strain 0.005 -> yield, eq_plastic_strain > 0
!===============================================================================
program test_umat_plastic_j2
  use IF_Prec_Core, only: wp
  use IF_Err_API, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  use PH_UMAT_Types, only: PH_UMAT_Context
  use PH_Mat_PLM_J2, only: PH_Mat_PLM_J2_UMAT
  implicit none

  type(PH_UMAT_Context) :: ctx
  type(ErrorStatusType) :: st
  real(wp) :: E, nu, sigma_y0, H, tol, err
  integer :: i

  call init_error_status(st)
  E = 210000.0_wp
  nu = 0.3_wp
  sigma_y0 = 500.0_wp
  H = 1000.0_wp
  tol = 1.0e-6_wp

  ! Init: 3D (ndi=3, nshr=3), nstatv=7, nprops=4
  call ctx%Init(ndi=3, nshr=3, nstatv=7, nprops=4)
  ctx%ndi = 3
  ctx%nshr = 3
  ctx%props(1) = E
  ctx%props(2) = nu
  ctx%props(3) = sigma_y0
  ctx%props(4) = H

  ! --- Step 1: Elastic uniaxial strain (sigma_11 < sigma_y0) ---
  ctx%dstran = 0.0_wp
  ctx%dstran(1) = 0.001_wp

  call PH_Mat_PLM_J2_UMAT(ctx, st)
  if (st%status_code /= IF_STATUS_OK) then
    write(*,*) 'FAIL: PH_Mat_PLM_J2_UMAT step1 returned status ', st%status_code, ' ', trim(st%message)
    call ctx%Cleanup()
    stop 1
  endif

  ! sigma_11 ~ 282.69 for elastic uniaxial (same as ElasticIso)
  err = abs(ctx%sigma(1) - 282.69230769230769_wp)
  if (err > tol) then
    write(*,*) 'FAIL: sigma(1)=', ctx%sigma(1), ' expected ~282.69, err=', err
    call ctx%Cleanup()
    stop 1
  endif

  ! eq_plastic_strain should be 0 (elastic)
  if (abs(ctx%statev(1)) > tol) then
    write(*,*) 'FAIL: statev(1) eq_pl=', ctx%statev(1), ' expected 0 (elastic)'
    call ctx%Cleanup()
    stop 1
  endif

  ! --- Step 2: Larger strain to trigger plasticity ---
  ctx%dstran(1) = 0.004_wp
  call PH_Mat_PLM_J2_UMAT(ctx, st)
  if (st%status_code /= IF_STATUS_OK) then
    write(*,*) 'FAIL: PH_Mat_PLM_J2_UMAT step2 returned status ', st%status_code
    call ctx%Cleanup()
    stop 1
  endif

  ! eq_plastic_strain should be > 0
  if (ctx%statev(1) <= 0.0_wp) then
    write(*,*) 'FAIL: statev(1) eq_pl=', ctx%statev(1), ' expected > 0 (plastic)'
    call ctx%Cleanup()
    stop 1
  endif

  ! sigma_11 should be near yield (500 + H*eq_pl)
  if (ctx%sigma(1) < sigma_y0 * 0.9_wp) then
    write(*,*) 'FAIL: sigma(1)=', ctx%sigma(1), ' expected near yield'
    call ctx%Cleanup()
    stop 1
  endif

  call ctx%Cleanup()
  write(*,*) 'PASS: PH_Mat_PLM_J2_UMAT unit test'
end program test_umat_plastic_j2
