!===============================================================================
! E2E Test: C2-03 Contact Hertz Slide (NTS + Penalty + Coulomb Friction)
! Layer:  Integration (L3->L4->L5 cross-layer)
! Domain: Contact + Penalty + Friction
!
! Scenario:
!   - Two blocks: upper block pressed onto lower block
!   - Upper block slides horizontally under applied tangential force
!   - Normal contact via penalty method
!   - Tangential friction via Coulomb law
!
! Geometry:
!   - Lower block: fixed, top surface at y=0
!   - Upper block: bottom surface initially at y=gap0 (small positive gap)
!   - Applied: vertical approach + horizontal sliding
!
! Contact Parameters:
!   - Penalty stiffness: k_n = 1.0e6 N/mm
!   - Friction coefficient: mu = 0.3
!   - Initial gap: gap0 = 0.1 mm
!
! Verification:
!   - Gap detection: gap transitions from positive to negative
!   - Penalty force: F_n = k_n * |penetration|
!   - Coulomb friction: |F_t| <= mu * F_n
!   - Stick-slip transition
!
! Note: Self-contained. NTS projection, penalty, and friction are inlined.
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
program E2E_C2_03_Contact_HertzSlide
  implicit none

  ! -- Precision
  integer, parameter :: wp = selected_real_kind(15, 307)
  integer, parameter :: i4 = selected_int_kind(9)

  ! -- Contact parameters
  real(wp), parameter :: k_n     = 1.0e6_wp     ! Normal penalty stiffness [N/mm]
  real(wp), parameter :: k_t     = 1.0e5_wp     ! Tangential penalty stiffness [N/mm]
  real(wp), parameter :: mu_fric = 0.3_wp       ! Coulomb friction coefficient
  real(wp), parameter :: gap0    = 0.1_wp       ! Initial gap [mm]
  real(wp), parameter :: tol_gap = 1.0e-10_wp   ! Gap tolerance

  ! -- Loading steps: (vertical displacement, horizontal displacement) of upper block
  integer(i4), parameter :: n_steps = 6
  real(wp) :: uy_applied(6)   ! Vertical approach (negative = closing gap)
  real(wp) :: ux_applied(6)   ! Horizontal sliding attempt

  ! -- NTS contact state
  real(wp) :: gap_n            ! Normal gap (positive = open, negative = penetration)
  real(wp) :: slip_t           ! Tangential slip
  real(wp) :: F_normal         ! Normal contact force (compression positive)
  real(wp) :: F_tangent        ! Tangential friction force
  real(wp) :: F_tangent_trial  ! Trial tangential force (elastic predictor)
  real(wp) :: F_limit          ! Coulomb friction limit

  ! -- Slave node position (upper block bottom center)
  real(wp) :: slave_x, slave_y
  real(wp) :: slave_x0, slave_y0   ! Initial position

  ! -- Master segment (lower block top surface: horizontal line y=0)
  real(wp), parameter :: master_y = 0.0_wp

  ! -- Projection result
  real(wp) :: proj_x, proj_y     ! Closest point on master
  real(wp) :: normal_x, normal_y ! Outward normal (pointing from master to slave)

  ! -- Accumulated tangential slip for friction
  real(wp) :: slip_total

  ! -- State tracking
  logical :: in_contact, was_in_contact
  logical :: is_sliding

  ! -- Checks
  integer(i4) :: istep, n_checks, n_pass, n_fail
  logical :: check_ok

  n_checks = 0
  n_pass   = 0
  n_fail   = 0

  ! Define loading sequence
  ! Steps 1-2: approach (closing gap)
  ! Steps 3-4: pressed in + start horizontal slide
  ! Steps 5-6: further slide (should trigger slip)
  uy_applied(1) = -0.03_wp    ! Approach, still open (gap=0.07)
  uy_applied(2) = -0.12_wp    ! Penetration (gap=-0.02)
  uy_applied(3) = -0.15_wp    ! More penetration (gap=-0.05)
  uy_applied(4) = -0.15_wp    ! Same vertical, horizontal push
  uy_applied(5) = -0.15_wp    ! Same vertical, more horizontal
  uy_applied(6) = -0.15_wp    ! Same vertical, large horizontal

  ux_applied(1) = 0.0_wp
  ux_applied(2) = 0.0_wp
  ux_applied(3) = 0.0_wp
  ux_applied(4) = 0.001_wp    ! Small tangential (stick)
  ux_applied(5) = 0.01_wp     ! Medium tangential
  ux_applied(6) = 1.0_wp      ! Large tangential (definitely sliding)

  ! Initial slave position
  slave_x0 = 50.0_wp          ! Horizontal position [mm]
  slave_y0 = gap0              ! At gap0 above master surface

  print '(A)', '=== E2E Test C2-03: Contact_HertzSlide ==='
  print '(A)', ''

  ! Initialize
  was_in_contact = .false.
  slip_total = 0.0_wp

  !============================================================================
  ! Main loading loop
  !============================================================================
  do istep = 1, n_steps

    ! Update slave node position
    slave_x = slave_x0 + ux_applied(istep)
    slave_y = slave_y0 + uy_applied(istep)

    print '(A,I0,A,F8.4,A,F8.4,A)', &
      '[Step ', istep, '] slave pos = (', slave_x, ', ', slave_y, ')'

    !========================================================================
    ! L4: NTS Projection (PH_Cont_NTS equivalent)
    !========================================================================
    ! For flat master surface at y=0, projection is trivial:
    ! closest point = (slave_x, 0), normal = (0, 1)
    call nts_project_flat(slave_x, slave_y, master_y, &
                          proj_x, proj_y, normal_x, normal_y, gap_n)

    print '(A,F10.6)', '  gap_n = ', gap_n

    ! Determine contact status
    in_contact = (gap_n < tol_gap)

    !========================================================================
    ! Step-specific checks
    !========================================================================
    select case (istep)

    case (1)
      ! Step 1: Gap should be POSITIVE (no contact)
      n_checks = n_checks + 1
      check_ok = (.not. in_contact .and. gap_n > 0.0_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F10.6,A,A)', &
        'Check ', n_checks, ': Open gap (no contact) ... gap=', gap_n, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

    case (2)
      ! Step 2: Gap should be NEGATIVE (contact established)
      n_checks = n_checks + 1
      check_ok = (in_contact .and. gap_n < 0.0_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F10.6,A,A)', &
        'Check ', n_checks, ': Gap closed (contact) ... gap=', gap_n, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

      ! Check: gap transition from positive to negative
      n_checks = n_checks + 1
      check_ok = (.not. was_in_contact .and. in_contact)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,A)', &
        'Check ', n_checks, ': Gap transition detected ... ', &
        merge('PASS', 'FAIL', check_ok)

    case (3)
      ! Step 3: Penalty normal force check
      ! F_n = k_n * |gap_n|
      if (in_contact) then
        call penalty_normal_force(gap_n, k_n, F_normal)
      else
        F_normal = 0.0_wp
      end if

      n_checks = n_checks + 1
      check_ok = (abs(F_normal - k_n * abs(gap_n)) < 1.0e-6_wp .and. F_normal > 0.0_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F12.2,A,F12.2,A,A)', &
        'Check ', n_checks, ': Penalty F_n = k_n*|g| ... F_n=', F_normal, &
        ' expected=', k_n * abs(gap_n), &
        ' ... ', merge('PASS', 'FAIL', check_ok)

    case (4)
      ! Step 4: Small tangential - should STICK
      if (in_contact) then
        call penalty_normal_force(gap_n, k_n, F_normal)
        slip_t = ux_applied(istep) - ux_applied(3)   ! Tangential slip increment
        call coulomb_friction(slip_t, k_t, F_normal, mu_fric, &
                              F_tangent, F_limit, is_sliding)
      else
        F_normal = 0.0_wp
        F_tangent = 0.0_wp
        is_sliding = .false.
      end if

      ! Should be sticking (trial force < friction limit)
      n_checks = n_checks + 1
      check_ok = (.not. is_sliding)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F10.2,A,F10.2,A,A)', &
        'Check ', n_checks, ': Stick regime ... |F_t|=', abs(F_tangent), &
        ' limit=', F_limit, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

      ! Coulomb check: |F_t| <= mu * F_n
      n_checks = n_checks + 1
      check_ok = (abs(F_tangent) <= mu_fric * F_normal + 1.0e-6_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F10.2,A,F10.2,A,A)', &
        'Check ', n_checks, ': Coulomb |F_t|<=mu*N ... |F_t|=', abs(F_tangent), &
        ' mu*N=', mu_fric * F_normal, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

    case (5)
      ! Step 5: Medium tangential - check friction
      if (in_contact) then
        call penalty_normal_force(gap_n, k_n, F_normal)
        slip_t = ux_applied(istep) - ux_applied(3)
        call coulomb_friction(slip_t, k_t, F_normal, mu_fric, &
                              F_tangent, F_limit, is_sliding)
      end if

      n_checks = n_checks + 1
      check_ok = (abs(F_tangent) <= mu_fric * F_normal + 1.0e-6_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F10.2,A,F10.2,A,L1,A,A)', &
        'Check ', n_checks, ': Coulomb satisfied ... |F_t|=', abs(F_tangent), &
        ' mu*N=', mu_fric * F_normal, &
        ' sliding=', is_sliding, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

    case (6)
      ! Step 6: Large tangential - should SLIDE
      if (in_contact) then
        call penalty_normal_force(gap_n, k_n, F_normal)
        slip_t = ux_applied(istep) - ux_applied(3)
        call coulomb_friction(slip_t, k_t, F_normal, mu_fric, &
                              F_tangent, F_limit, is_sliding)
      end if

      ! Should be sliding
      n_checks = n_checks + 1
      check_ok = is_sliding
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,A)', &
        'Check ', n_checks, ': Slip regime (sliding) ... ', &
        merge('PASS', 'FAIL', check_ok)

      ! In sliding: |F_t| = mu * F_n (at the limit)
      n_checks = n_checks + 1
      check_ok = (abs(abs(F_tangent) - mu_fric * F_normal) / (mu_fric * F_normal) < 0.01_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F10.2,A,F10.2,A,A)', &
        'Check ', n_checks, ': Sliding F_t = mu*N ... |F_t|=', abs(F_tangent), &
        ' mu*N=', mu_fric * F_normal, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

      ! Normal force should still be correct
      n_checks = n_checks + 1
      check_ok = (abs(F_normal - k_n * abs(gap_n)) < 1.0e-6_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F12.2,A,A)', &
        'Check ', n_checks, ': Normal force consistent ... F_n=', F_normal, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

    end select

    was_in_contact = in_contact
  end do

  !============================================================================
  ! SUMMARY
  !============================================================================
  print '(A)', ''
  if (n_fail == 0) then
    print '(A,I0,A,I0,A)', '=== RESULT: PASS (', n_pass, '/', n_checks, ' checks passed) ==='
  else
    print '(A,I0,A,I0,A)', '=== RESULT: FAIL (', n_pass, '/', n_checks, ' checks passed) ==='
  end if

contains

  !============================================================================
  ! NTS Projection onto flat master surface (y = master_y)
  ! For a horizontal master surface, projection is trivial
  !============================================================================
  subroutine nts_project_flat(sx, sy, my, px, py, nx, ny, gn)
    real(wp), intent(in)  :: sx, sy      ! Slave node position
    real(wp), intent(in)  :: my           ! Master surface y-coordinate
    real(wp), intent(out) :: px, py       ! Projection point
    real(wp), intent(out) :: nx, ny       ! Outward normal (master -> slave)
    real(wp), intent(out) :: gn           ! Normal gap (>0 open, <0 penetration)

    ! Closest point on master surface
    px = sx
    py = my

    ! Normal direction: from master to slave = (0, 1) for flat horizontal surface
    nx = 0.0_wp
    ny = 1.0_wp

    ! Gap = signed distance from master to slave along normal
    gn = (sy - my) * ny   ! = sy - my
  end subroutine nts_project_flat

  !============================================================================
  ! Penalty normal force computation
  ! F_n = k_n * |penetration|  (only when gap < 0)
  !============================================================================
  subroutine penalty_normal_force(gn, kn, fn)
    real(wp), intent(in)  :: gn    ! Normal gap (negative = penetration)
    real(wp), intent(in)  :: kn    ! Penalty stiffness
    real(wp), intent(out) :: fn    ! Normal force (positive = compression)

    if (gn < 0.0_wp) then
      fn = kn * abs(gn)
    else
      fn = 0.0_wp
    end if
  end subroutine penalty_normal_force

  !============================================================================
  ! Coulomb friction with penalty regularization
  !
  ! Trial tangential force (elastic predictor):
  !   F_t_trial = k_t * slip
  !
  ! Coulomb check:
  !   if |F_t_trial| <= mu * F_n  -> STICK (F_t = F_t_trial)
  !   if |F_t_trial| >  mu * F_n  -> SLIP  (F_t = mu * F_n * sign(slip))
  !============================================================================
  subroutine coulomb_friction(slip, kt, fn, mu, ft, flimit, sliding)
    real(wp), intent(in)  :: slip      ! Tangential slip
    real(wp), intent(in)  :: kt        ! Tangential penalty stiffness
    real(wp), intent(in)  :: fn        ! Normal force
    real(wp), intent(in)  :: mu        ! Friction coefficient
    real(wp), intent(out) :: ft        ! Tangential friction force
    real(wp), intent(out) :: flimit    ! Friction limit
    logical,  intent(out) :: sliding   ! True if sliding

    real(wp) :: ft_trial

    ! Elastic predictor
    ft_trial = kt * slip

    ! Friction limit
    flimit = mu * fn

    ! Coulomb check
    if (abs(ft_trial) <= flimit) then
      ! Stick
      ft = ft_trial
      sliding = .false.
    else
      ! Slip: cap at friction limit
      ft = sign(flimit, slip)
      sliding = .true.
    end if
  end subroutine coulomb_friction

end program E2E_C2_03_Contact_HertzSlide
