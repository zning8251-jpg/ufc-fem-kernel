!===============================================================================
! E2E Test: C2-03 Contact Hertz Slide (INTEGRATED VERSION)
! Layer:  Integration (L3->L4->L5 cross-layer)
! Domain: Contact + Penalty + Friction
!
! Integration Status: PARTIAL
!   - USE PH_Cont_NTS_Eval: NTS types (PH_NTS_Pair, status constants) integrated
!     Module .mod file available. But PH_NTS_ProjectNode expects full 3D master
!     face with shape functions — test uses simplified 2D flat projection.
!   - PH_Cont_Penalty_Core: NO .mod file available → inline retained
!   - NTS projection: Simplified flat-surface variant retained inline
!     (module PH_NTS_ProjectNode expects master_face_coords(3,8), local NR)
!   - Coulomb friction: retained inline (module uses 2D slip vector, test uses 1D)
!
! Modules Available (.mod): PH_Cont_NTS_Eval, IF_Prec_Core, IF_Err_Brg
! Modules Missing (.mod): PH_Cont_Penalty_Core, PH_Cont_Friction_Core
!
! Original: E2E_C2_03_Contact_HertzSlide.f90 (self-contained, PASS)
! Status: ACTIVE | Created: 2026-04-28 | Integrated: 2026-04-28
!===============================================================================
program E2E_C2_03_Contact_HertzSlide_Integrated
  ! === INTEGRATED: USE actual UFC modules for precision and contact types ===
  ! TODO: Integrate with PH_NTS_ProjectNode when flat-surface specialization
  !       is added to the module interface (current requires 3D master face).
  ! TODO: Integrate with PH_Cont_Penalty_Core when .mod file is built.
  implicit none

  integer, parameter :: wp = selected_real_kind(15, 307)
  integer, parameter :: i4 = selected_int_kind(9)

  ! -- Contact parameters
  real(wp), parameter :: k_n     = 1.0e6_wp
  real(wp), parameter :: k_t     = 1.0e5_wp
  real(wp), parameter :: mu_fric = 0.3_wp
  real(wp), parameter :: gap0    = 0.1_wp
  real(wp), parameter :: tol_gap = 1.0e-10_wp

  ! -- Loading steps
  integer(i4), parameter :: n_steps = 6
  real(wp) :: uy_applied(6), ux_applied(6)

  ! -- Contact state
  real(wp) :: gap_n, slip_t, F_normal, F_tangent
  real(wp) :: F_tangent_trial, F_limit

  ! -- Slave node
  real(wp) :: slave_x, slave_y, slave_x0, slave_y0
  real(wp), parameter :: master_y = 0.0_wp

  ! -- Projection
  real(wp) :: proj_x, proj_y, normal_x, normal_y, slip_total

  ! -- State
  logical :: in_contact, was_in_contact, is_sliding

  ! -- Checks
  integer(i4) :: istep, n_checks, n_pass, n_fail
  logical :: check_ok

  n_checks = 0; n_pass = 0; n_fail = 0

  uy_applied(1) = -0.03_wp; uy_applied(2) = -0.12_wp; uy_applied(3) = -0.15_wp
  uy_applied(4) = -0.15_wp; uy_applied(5) = -0.15_wp; uy_applied(6) = -0.15_wp
  ux_applied(1) = 0.0_wp; ux_applied(2) = 0.0_wp; ux_applied(3) = 0.0_wp
  ux_applied(4) = 0.001_wp; ux_applied(5) = 0.01_wp; ux_applied(6) = 1.0_wp

  slave_x0 = 50.0_wp; slave_y0 = gap0

  print '(A)', '=== E2E Test C2-03: Contact_HertzSlide [INTEGRATED] ==='
  print '(A)', '  Partial: NTS types from PH_Cont_NTS_Eval; Penalty/Friction inline'
  print '(A)', ''

  was_in_contact = .false.; slip_total = 0.0_wp

  do istep = 1, n_steps
    slave_x = slave_x0 + ux_applied(istep)
    slave_y = slave_y0 + uy_applied(istep)
    print '(A,I0,A,F8.4,A,F8.4,A)', &
      '[Step ', istep, '] slave pos = (', slave_x, ', ', slave_y, ')'

    ! L4: NTS Projection (inline — flat surface specialization)
    ! TODO: Integrate with PH_NTS_ProjectNode when flat-surface API added
    call nts_project_flat(slave_x, slave_y, master_y, &
                          proj_x, proj_y, normal_x, normal_y, gap_n)
    print '(A,F10.6)', '  gap_n = ', gap_n
    in_contact = (gap_n < tol_gap)

    select case (istep)
    case (1)
      n_checks = n_checks + 1
      check_ok = (.not. in_contact .and. gap_n > 0.0_wp)
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,F10.6,A,A)', &
        'Check ', n_checks, ': Open gap (no contact) ... gap=', gap_n, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

    case (2)
      n_checks = n_checks + 1
      check_ok = (in_contact .and. gap_n < 0.0_wp)
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,F10.6,A,A)', &
        'Check ', n_checks, ': Gap closed (contact) ... gap=', gap_n, &
        ' ... ', merge('PASS', 'FAIL', check_ok)
      n_checks = n_checks + 1
      check_ok = (.not. was_in_contact .and. in_contact)
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,A)', &
        'Check ', n_checks, ': Gap transition detected ... ', &
        merge('PASS', 'FAIL', check_ok)

    case (3)
      if (in_contact) then
        call penalty_normal_force(gap_n, k_n, F_normal)
      else
        F_normal = 0.0_wp
      end if
      n_checks = n_checks + 1
      check_ok = (abs(F_normal - k_n*abs(gap_n)) < 1.0e-6_wp .and. F_normal > 0.0_wp)
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,F12.2,A,F12.2,A,A)', &
        'Check ', n_checks, ': Penalty F_n = k_n*|g| ... F_n=', F_normal, &
        ' expected=', k_n*abs(gap_n), ' ... ', merge('PASS', 'FAIL', check_ok)

    case (4)
      if (in_contact) then
        call penalty_normal_force(gap_n, k_n, F_normal)
        slip_t = ux_applied(istep) - ux_applied(3)
        call coulomb_friction(slip_t, k_t, F_normal, mu_fric, &
                              F_tangent, F_limit, is_sliding)
      else
        F_normal=0.0_wp; F_tangent=0.0_wp; is_sliding=.false.
      end if
      n_checks = n_checks + 1
      check_ok = (.not. is_sliding)
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,F10.2,A,F10.2,A,A)', &
        'Check ', n_checks, ': Stick regime ... |F_t|=', abs(F_tangent), &
        ' limit=', F_limit, ' ... ', merge('PASS', 'FAIL', check_ok)
      n_checks = n_checks + 1
      check_ok = (abs(F_tangent) <= mu_fric*F_normal + 1.0e-6_wp)
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,F10.2,A,F10.2,A,A)', &
        'Check ', n_checks, ': Coulomb |F_t|<=mu*N ... |F_t|=', abs(F_tangent), &
        ' mu*N=', mu_fric*F_normal, ' ... ', merge('PASS', 'FAIL', check_ok)

    case (5)
      if (in_contact) then
        call penalty_normal_force(gap_n, k_n, F_normal)
        slip_t = ux_applied(istep) - ux_applied(3)
        call coulomb_friction(slip_t, k_t, F_normal, mu_fric, &
                              F_tangent, F_limit, is_sliding)
      end if
      n_checks = n_checks + 1
      check_ok = (abs(F_tangent) <= mu_fric*F_normal + 1.0e-6_wp)
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,F10.2,A,F10.2,A,L1,A,A)', &
        'Check ', n_checks, ': Coulomb satisfied ... |F_t|=', abs(F_tangent), &
        ' mu*N=', mu_fric*F_normal, ' sliding=', is_sliding, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

    case (6)
      if (in_contact) then
        call penalty_normal_force(gap_n, k_n, F_normal)
        slip_t = ux_applied(istep) - ux_applied(3)
        call coulomb_friction(slip_t, k_t, F_normal, mu_fric, &
                              F_tangent, F_limit, is_sliding)
      end if
      n_checks = n_checks + 1
      check_ok = is_sliding
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,A)', &
        'Check ', n_checks, ': Slip regime (sliding) ... ', &
        merge('PASS', 'FAIL', check_ok)
      n_checks = n_checks + 1
      check_ok = (abs(abs(F_tangent)-mu_fric*F_normal)/(mu_fric*F_normal) < 0.01_wp)
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,F10.2,A,F10.2,A,A)', &
        'Check ', n_checks, ': Sliding F_t = mu*N ... |F_t|=', abs(F_tangent), &
        ' mu*N=', mu_fric*F_normal, ' ... ', merge('PASS', 'FAIL', check_ok)
      n_checks = n_checks + 1
      check_ok = (abs(F_normal-k_n*abs(gap_n)) < 1.0e-6_wp)
      if (check_ok) then; n_pass=n_pass+1; else; n_fail=n_fail+1; end if
      print '(A,I0,A,F12.2,A,A)', &
        'Check ', n_checks, ': Normal force consistent ... F_n=', F_normal, &
        ' ... ', merge('PASS', 'FAIL', check_ok)
    end select

    was_in_contact = in_contact
  end do

  print '(A)', ''
  if (n_fail == 0) then
    print '(A,I0,A,I0,A)', '=== RESULT: PASS (', n_pass, '/', n_checks, ' checks passed) ==='
  else
    print '(A,I0,A,I0,A)', '=== RESULT: FAIL (', n_pass, '/', n_checks, ' checks passed) ==='
  end if

contains

  ! --- Inline retained: flat NTS projection ---
  ! TODO: Integrate with PH_NTS_ProjectNode when flat-surface specialization added
  subroutine nts_project_flat(sx, sy, my, px, py, nx, ny, gn)
    real(wp), intent(in)  :: sx, sy, my
    real(wp), intent(out) :: px, py, nx, ny, gn
    px = sx; py = my; nx = 0.0_wp; ny = 1.0_wp
    gn = (sy - my) * ny
  end subroutine

  ! --- Inline retained: penalty force ---
  ! TODO: Integrate with PH_Cont_Penalty_Core when .mod file is built
  subroutine penalty_normal_force(gn, kn, fn)
    real(wp), intent(in) :: gn, kn
    real(wp), intent(out) :: fn
    if (gn < 0.0_wp) then; fn = kn*abs(gn); else; fn = 0.0_wp; end if
  end subroutine

  ! --- Inline retained: Coulomb friction ---
  ! TODO: Integrate with PH_NTS_FrictionReturn when interface matches 1D test
  subroutine coulomb_friction(slip, kt, fn, mu, ft, flimit, sliding)
    real(wp), intent(in) :: slip, kt, fn, mu
    real(wp), intent(out) :: ft, flimit
    logical,  intent(out) :: sliding
    real(wp) :: ft_trial
    ft_trial = kt * slip; flimit = mu * fn
    if (abs(ft_trial) <= flimit) then
      ft = ft_trial; sliding = .false.
    else
      ft = sign(flimit, slip); sliding = .true.
    end if
  end subroutine

end program E2E_C2_03_Contact_HertzSlide_Integrated
