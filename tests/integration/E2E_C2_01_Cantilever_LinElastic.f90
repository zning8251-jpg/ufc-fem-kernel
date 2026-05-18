!===============================================================================
! E2E Test: C2-01 Cantilever Beam Linear Elastic Static
! Layer:  Integration (L3->L4->L5 cross-layer)
! Domain: Element + Material + Load + BC + Assembly + Solver
!
! Geometry:
!   - Cantilever beam: 10x4x2 C3D8 elements (incompatible modes)
!   - Length L = 100 mm, Height H = 10 mm, Width B = 10 mm
!
! Material:  E = 210000 MPa, nu = 0.3
! BC:        Left end clamped (u=v=w=0)
! Loading:   Free end P = 1000 N in -y direction
!
! Verification:
!   - Tip deflection vs beam theory: delta = P*L^3/(3*E*I), error < 5%
!   - Stiffness matrix symmetry
!   - Clamped end zero displacement
!
! Element: C3D8 + Wilson incompatible modes (9 internal DOFs condensed out)
!          Eliminates shear locking for bending-dominated problems.
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
program E2E_C2_01_Cantilever_LinElastic
  implicit none

  integer, parameter :: wp = selected_real_kind(15, 307)
  integer, parameter :: i4 = selected_int_kind(9)

  ! Geometry & Material
  real(wp), parameter :: beam_L = 100.0_wp, beam_H = 10.0_wp, beam_B = 10.0_wp
  real(wp), parameter :: E_mod = 210000.0_wp, nu_mat = 0.3_wp
  real(wp), parameter :: P_load = -1000.0_wp

  ! Mesh: 10x4x2
  integer(i4), parameter :: nx = 10, ny = 4, nz = 2
  integer(i4), parameter :: nnx = nx+1, nny = ny+1, nnz = nz+1
  integer(i4), parameter :: n_node = nnx*nny*nnz   ! = 165
  integer(i4), parameter :: n_dof  = n_node * 3     ! = 495

  real(wp) :: coords(3, n_node)
  real(wp) :: K_global(n_dof, n_dof)
  real(wp) :: F_global(n_dof), U_global(n_dof)
  real(wp) :: D_mat(6,6), Ke(24,24)
  integer(i4) :: elem_conn(8)
  integer(i4) :: bc_dofs(nny*nnz*3)
  integer(i4) :: load_nodes(nny*nnz)

  real(wp) :: I_moment, delta_theory, delta_fem, err_pct, max_sym, sym_err
  integer(i4) :: ix, iy, iz, ex, ey, ez, ii, jj, nd, nbc, n_ln
  integer(i4) :: n_checks, n_pass, n_fail
  logical :: check_ok

  n_checks = 0; n_pass = 0; n_fail = 0

  print '(A)', '=== E2E Test C2-01: Cantilever_LinElastic ==='
  print '(A,I0,A,I0,A,I0,A)', 'Mesh: ', nx, 'x', ny, 'x', nz, &
    ' C3D8+IM (incompatible modes)'
  print '(A)', ''

  ! === L3: Generate mesh ===
  print '(A)', '[L3] Generating structured hex mesh ...'
  do iz = 0, nz; do iy = 0, ny; do ix = 0, nx
    nd = iz*nnx*nny + iy*nnx + ix + 1
    coords(1,nd) = real(ix,wp) * beam_L / real(nx,wp)
    coords(2,nd) = real(iy,wp) * beam_H / real(ny,wp)
    coords(3,nd) = real(iz,wp) * beam_B / real(nz,wp)
  end do; end do; end do

  ! === L3: Material ===
  print '(A)', '[L3] Building isotropic elastic D matrix ...'
  call build_elastic_D(E_mod, nu_mat, D_mat)

  ! === L4+L5: Element stiffness + assembly ===
  print '(A)', '[L4] Computing C3D8+IM element stiffness (2x2x2 Gauss) ...'
  print '(A)', '[L5] Assembling global stiffness matrix ...'
  K_global = 0.0_wp; F_global = 0.0_wp

  do ez = 0, nz-1; do ey = 0, ny-1; do ex = 0, nx-1
    elem_conn(1) = ez*nnx*nny + ey*nnx + ex + 1
    elem_conn(2) = (ez+1)*nnx*nny + ey*nnx + ex + 1
    elem_conn(3) = (ez+1)*nnx*nny + ey*nnx + (ex+1) + 1
    elem_conn(4) = ez*nnx*nny + ey*nnx + (ex+1) + 1
    elem_conn(5) = ez*nnx*nny + (ey+1)*nnx + ex + 1
    elem_conn(6) = (ez+1)*nnx*nny + (ey+1)*nnx + ex + 1
    elem_conn(7) = (ez+1)*nnx*nny + (ey+1)*nnx + (ex+1) + 1
    elem_conn(8) = ez*nnx*nny + (ey+1)*nnx + (ex+1) + 1
    call compute_C3D8_IM(coords, elem_conn, D_mat, Ke)
    call scatter_Ke(Ke, elem_conn, K_global, n_dof)
  end do; end do; end do

  ! Check 1: Symmetry
  max_sym = 0.0_wp
  do ii = 1, min(n_dof,100)
    do jj = ii+1, min(n_dof,100)
      sym_err = abs(K_global(ii,jj)-K_global(jj,ii))
      if (sym_err > max_sym) max_sym = sym_err
    end do
  end do
  n_checks = n_checks + 1; check_ok = (max_sym < 1.0e-6_wp)
  call rpt(n_checks, 'K_global symmetry', check_ok, n_pass, n_fail)

  ! === L3: BC (clamped at x=0) ===
  print '(A)', '[L3] Applying clamped BC at x=0 ...'
  nbc = 0
  do iz = 0, nz; do iy = 0, ny
    nd = iz*nnx*nny + iy*nnx + 0 + 1
    nbc=nbc+1; bc_dofs(nbc) = (nd-1)*3+1
    nbc=nbc+1; bc_dofs(nbc) = (nd-1)*3+2
    nbc=nbc+1; bc_dofs(nbc) = (nd-1)*3+3
  end do; end do

  ! === L3: Load at free end ===
  print '(A)', '[L3] Applying tip load P=-1000N ...'
  n_ln = 0
  do iz = 0, nz; do iy = 0, ny
    n_ln = n_ln + 1
    load_nodes(n_ln) = iz*nnx*nny + iy*nnx + nx + 1
  end do; end do
  do ii = 1, n_ln
    F_global((load_nodes(ii)-1)*3+2) = P_load / real(n_ln, wp)
  end do

  ! === L5: Solve ===
  print '(A)', '[L5] Applying penalty BC and solving ...'
  call apply_bc_penalty(K_global, F_global, bc_dofs, nbc, n_dof)
  call solve_gauss(K_global, F_global, U_global, n_dof)

  ! === Verification ===
  print '(A)', ''
  print '(A)', '--- Verification ---'

  I_moment = beam_B * beam_H**3 / 12.0_wp
  delta_theory = abs(P_load) * beam_L**3 / (3.0_wp * E_mod * I_moment)

  delta_fem = 0.0_wp
  do ii = 1, n_ln
    delta_fem = delta_fem + U_global((load_nodes(ii)-1)*3+2)
  end do
  delta_fem = abs(delta_fem / real(n_ln, wp))
  err_pct = abs(delta_fem - delta_theory) / delta_theory * 100.0_wp

  print '(A,F10.6,A,F10.6,A,F6.2,A)', &
    '  FEM=', delta_fem, '  Theory=', delta_theory, '  err=', err_pct, '%'

  n_checks = n_checks + 1; check_ok = (err_pct < 5.0_wp)
  call rpt(n_checks, 'Tip deflection error < 5%', check_ok, n_pass, n_fail)

  ! Clamped DOFs
  check_ok = .true.
  do ii = 1, nbc
    if (abs(U_global(bc_dofs(ii))) > 1.0e-8_wp) check_ok = .false.
  end do
  n_checks = n_checks + 1
  call rpt(n_checks, 'Clamped end u=v=w=0', check_ok, n_pass, n_fail)

  ! Free end > midspan
  nd = nz/2*nnx*nny + ny/2*nnx + nx + 1
  ii = nz/2*nnx*nny + ny/2*nnx + nx/2 + 1
  n_checks = n_checks + 1
  check_ok = (abs(U_global((nd-1)*3+2)) > abs(U_global((ii-1)*3+2)))
  call rpt(n_checks, 'Free end > midspan deflection', check_ok, n_pass, n_fail)

  ! Correct direction
  n_checks = n_checks + 1
  check_ok = (U_global((load_nodes(1)-1)*3+2) < 0.0_wp)
  call rpt(n_checks, 'Deflection direction (neg y)', check_ok, n_pass, n_fail)

  ! Summary
  print '(A)', ''
  if (n_fail == 0) then
    print '(A,I0,A,I0,A)', '=== RESULT: PASS (', n_pass, '/', n_checks, ' checks passed) ==='
  else
    print '(A,I0,A,I0,A)', '=== RESULT: FAIL (', n_pass, '/', n_checks, ' checks passed) ==='
  end if

contains

  subroutine rpt(num, desc, passed, np, nf)
    integer(i4), intent(in) :: num
    character(*), intent(in) :: desc
    logical, intent(in) :: passed
    integer(i4), intent(inout) :: np, nf
    if (passed) then
      np = np + 1; print '(A,I0,A,A,A)', 'Check ', num, ': ', desc, ' ... PASS'
    else
      nf = nf + 1; print '(A,I0,A,A,A)', 'Check ', num, ': ', desc, ' ... FAIL'
    end if
  end subroutine

  subroutine build_elastic_D(E, nu, D)
    real(wp), intent(in)  :: E, nu
    real(wp), intent(out) :: D(6,6)
    real(wp) :: lam, mu
    lam = E*nu/((1.0_wp+nu)*(1.0_wp-2.0_wp*nu))
    mu  = E/(2.0_wp*(1.0_wp+nu))
    D = 0.0_wp
    D(1,1) = lam+2*mu; D(1,2) = lam;     D(1,3) = lam
    D(2,1) = lam;      D(2,2) = lam+2*mu; D(2,3) = lam
    D(3,1) = lam;      D(3,2) = lam;      D(3,3) = lam+2*mu
    D(4,4) = mu; D(5,5) = mu; D(6,6) = mu
  end subroutine

  !============================================================================
  ! C3D8 + Incompatible Modes (Wilson-Taylor)
  ! Adds 9 internal enhanced DOFs and statically condenses them out.
  ! Eliminates shear locking while maintaining full-integration stability.
  !============================================================================
  subroutine compute_C3D8_IM(all_coords, ec, D, Ke)
    real(wp), intent(in)     :: all_coords(3,*)
    integer(i4), intent(in)  :: ec(8)
    real(wp), intent(in)     :: D(6,6)
    real(wp), intent(out)    :: Ke(24,24)

    real(wp) :: xe(3,8)
    real(wp) :: gp(2)
    real(wp) :: dN_dxi(8,3), dN_dx(8,3)
    real(wp) :: J(3,3), Jinv(3,3), detJ
    real(wp) :: J0(3,3), J0inv(3,3), detJ0
    real(wp) :: B(6,24), G(6,9)
    real(wp) :: DB(6,24), DG(6,9)
    real(wp) :: Kuu(24,24), Kua(24,9), Kaa(9,9)
    real(wp) :: Kaa_inv(9,9), temp(24,9)
    real(wp) :: xi, eta, zeta, w
    real(wp) :: xi_nat(3), dMm_dx(3)
    integer(i4) :: ig, jg, kg, a, ii, jj, kk, idir, m, q

    do a = 1, 8
      xe(:,a) = all_coords(:, ec(a))
    end do

    gp(1) = -1.0_wp/sqrt(3.0_wp)
    gp(2) =  1.0_wp/sqrt(3.0_wp)

    ! Jacobian at element center (for enhanced modes, patch test)
    call C3D8_dN(0.0_wp, 0.0_wp, 0.0_wp, dN_dxi)
    J0 = 0.0_wp
    do a = 1, 8
      do ii = 1, 3; do jj = 1, 3
        J0(ii,jj) = J0(ii,jj) + xe(ii,a)*dN_dxi(a,jj)
      end do; end do
    end do
    call invert3x3(J0, J0inv, detJ0)

    Kuu = 0.0_wp; Kua = 0.0_wp; Kaa = 0.0_wp

    do ig = 1, 2; do jg = 1, 2; do kg = 1, 2
      xi = gp(ig); eta = gp(jg); zeta = gp(kg)

      call C3D8_dN(xi, eta, zeta, dN_dxi)

      ! Jacobian at Gauss point
      J = 0.0_wp
      do a = 1, 8
        do ii = 1, 3; do jj = 1, 3
          J(ii,jj) = J(ii,jj) + xe(ii,a)*dN_dxi(a,jj)
        end do; end do
      end do
      call invert3x3(J, Jinv, detJ)
      w = abs(detJ)

      ! Physical shape function derivatives
      dN_dx = 0.0_wp
      do a = 1, 8
        do ii = 1, 3; do jj = 1, 3
          dN_dx(a,ii) = dN_dx(a,ii) + dN_dxi(a,jj)*Jinv(jj,ii)
        end do; end do
      end do

      ! Standard B matrix (6x24)
      B = 0.0_wp
      do a = 1, 8
        kk = (a-1)*3
        B(1,kk+1) = dN_dx(a,1)
        B(2,kk+2) = dN_dx(a,2)
        B(3,kk+3) = dN_dx(a,3)
        B(4,kk+1) = dN_dx(a,2); B(4,kk+2) = dN_dx(a,1)
        B(5,kk+2) = dN_dx(a,3); B(5,kk+3) = dN_dx(a,2)
        B(6,kk+1) = dN_dx(a,3); B(6,kk+3) = dN_dx(a,1)
      end do

      ! Enhanced G matrix (6x9) using J0inv for patch test
      ! Incompatible modes: M_m = 1 - xi_m^2, dMm/dxi_j = -2*xi_m*delta(m,j)
      ! Physical: dMm/dx_i = -2*xi_m * J0inv(m,i)
      xi_nat(1) = xi; xi_nat(2) = eta; xi_nat(3) = zeta
      G = 0.0_wp
      do idir = 1, 3
        do m = 1, 3
          q = (idir-1)*3 + m
          dMm_dx(1) = -2.0_wp * xi_nat(m) * J0inv(m,1)
          dMm_dx(2) = -2.0_wp * xi_nat(m) * J0inv(m,2)
          dMm_dx(3) = -2.0_wp * xi_nat(m) * J0inv(m,3)
          select case(idir)
          case(1)
            G(1,q) = dMm_dx(1); G(4,q) = dMm_dx(2); G(6,q) = dMm_dx(3)
          case(2)
            G(2,q) = dMm_dx(2); G(4,q) = dMm_dx(1); G(5,q) = dMm_dx(3)
          case(3)
            G(3,q) = dMm_dx(3); G(5,q) = dMm_dx(2); G(6,q) = dMm_dx(1)
          end select
        end do
      end do

      ! D*B and D*G
      DB = 0.0_wp; DG = 0.0_wp
      do ii = 1, 6
        do jj = 1, 24; do kk = 1, 6
          DB(ii,jj) = DB(ii,jj) + D(ii,kk)*B(kk,jj)
        end do; end do
        do jj = 1, 9; do kk = 1, 6
          DG(ii,jj) = DG(ii,jj) + D(ii,kk)*G(kk,jj)
        end do; end do
      end do

      ! Kuu += B^T * D * B * w
      do ii = 1, 24; do jj = 1, 24; do kk = 1, 6
        Kuu(ii,jj) = Kuu(ii,jj) + B(kk,ii)*DB(kk,jj)*w
      end do; end do; end do

      ! Kua += B^T * D * G * w
      do ii = 1, 24; do jj = 1, 9; do kk = 1, 6
        Kua(ii,jj) = Kua(ii,jj) + B(kk,ii)*DG(kk,jj)*w
      end do; end do; end do

      ! Kaa += G^T * D * G * w
      do ii = 1, 9; do jj = 1, 9; do kk = 1, 6
        Kaa(ii,jj) = Kaa(ii,jj) + G(kk,ii)*DG(kk,jj)*w
      end do; end do; end do

    end do; end do; end do

    ! Static condensation: Ke = Kuu - Kua * inv(Kaa) * Kau
    call invert_small(Kaa, Kaa_inv, 9)

    ! temp(24,9) = Kua * Kaa_inv
    temp = 0.0_wp
    do ii = 1, 24; do jj = 1, 9; do kk = 1, 9
      temp(ii,jj) = temp(ii,jj) + Kua(ii,kk)*Kaa_inv(kk,jj)
    end do; end do; end do

    ! Ke = Kuu - temp * Kau  (Kau = transpose(Kua))
    Ke = Kuu
    do ii = 1, 24; do jj = 1, 24; do kk = 1, 9
      Ke(ii,jj) = Ke(ii,jj) - temp(ii,kk)*Kua(jj,kk)
    end do; end do; end do

  end subroutine compute_C3D8_IM

  subroutine C3D8_dN(xi, eta, zeta, dN)
    real(wp), intent(in) :: xi, eta, zeta
    real(wp), intent(out) :: dN(8,3)
    real(wp) :: xn(8), en(8), zn(8)
    integer(i4) :: a
    xn = (/-1.0_wp,-1.0_wp, 1.0_wp, 1.0_wp,-1.0_wp,-1.0_wp, 1.0_wp, 1.0_wp/)
    en = (/-1.0_wp,-1.0_wp,-1.0_wp,-1.0_wp, 1.0_wp, 1.0_wp, 1.0_wp, 1.0_wp/)
    zn = (/-1.0_wp, 1.0_wp, 1.0_wp,-1.0_wp,-1.0_wp, 1.0_wp, 1.0_wp,-1.0_wp/)
    do a = 1, 8
      dN(a,1) = xn(a)*(1+en(a)*eta)*(1+zn(a)*zeta)/8.0_wp
      dN(a,2) = (1+xn(a)*xi)*en(a)*(1+zn(a)*zeta)/8.0_wp
      dN(a,3) = (1+xn(a)*xi)*(1+en(a)*eta)*zn(a)/8.0_wp
    end do
  end subroutine

  subroutine invert3x3(A, Ai, det)
    real(wp), intent(in) :: A(3,3)
    real(wp), intent(out) :: Ai(3,3), det
    det = A(1,1)*(A(2,2)*A(3,3)-A(2,3)*A(3,2)) &
        - A(1,2)*(A(2,1)*A(3,3)-A(2,3)*A(3,1)) &
        + A(1,3)*(A(2,1)*A(3,2)-A(2,2)*A(3,1))
    Ai(1,1)= (A(2,2)*A(3,3)-A(2,3)*A(3,2))/det
    Ai(1,2)=-(A(1,2)*A(3,3)-A(1,3)*A(3,2))/det
    Ai(1,3)= (A(1,2)*A(2,3)-A(1,3)*A(2,2))/det
    Ai(2,1)=-(A(2,1)*A(3,3)-A(2,3)*A(3,1))/det
    Ai(2,2)= (A(1,1)*A(3,3)-A(1,3)*A(3,1))/det
    Ai(2,3)=-(A(1,1)*A(2,3)-A(1,3)*A(2,1))/det
    Ai(3,1)= (A(2,1)*A(3,2)-A(2,2)*A(3,1))/det
    Ai(3,2)=-(A(1,1)*A(3,2)-A(1,2)*A(3,1))/det
    Ai(3,3)= (A(1,1)*A(2,2)-A(1,2)*A(2,1))/det
  end subroutine

  ! Invert small NxN matrix via Gauss-Jordan
  subroutine invert_small(A, Ainv, n)
    integer(i4), intent(in) :: n
    real(wp), intent(in) :: A(n,n)
    real(wp), intent(out) :: Ainv(n,n)
    real(wp) :: W(n,2*n), piv, tmp
    integer(i4) :: ii, jj, kk, pr
    ! Augmented matrix [A | I]
    W = 0.0_wp
    do ii = 1, n; do jj = 1, n
      W(ii,jj) = A(ii,jj)
    end do; end do
    do ii = 1, n
      W(ii,n+ii) = 1.0_wp
    end do
    ! Gauss-Jordan elimination
    do kk = 1, n
      pr = kk
      do ii = kk+1, n
        if (abs(W(ii,kk)) > abs(W(pr,kk))) pr = ii
      end do
      if (pr /= kk) then
        do jj = 1, 2*n
          tmp = W(kk,jj); W(kk,jj) = W(pr,jj); W(pr,jj) = tmp
        end do
      end if
      piv = W(kk,kk)
      do jj = 1, 2*n
        W(kk,jj) = W(kk,jj) / piv
      end do
      do ii = 1, n
        if (ii /= kk) then
          piv = W(ii,kk)
          do jj = 1, 2*n
            W(ii,jj) = W(ii,jj) - piv*W(kk,jj)
          end do
        end if
      end do
    end do
    do ii = 1, n; do jj = 1, n
      Ainv(ii,jj) = W(ii,n+jj)
    end do; end do
  end subroutine

  subroutine scatter_Ke(Ke, ec, K_g, ndg)
    real(wp), intent(in) :: Ke(24,24)
    integer(i4), intent(in) :: ec(8)
    real(wp), intent(inout) :: K_g(ndg,ndg)
    integer(i4), intent(in) :: ndg
    integer(i4) :: a, b, gi, gj, li, lj
    do a = 1, 8; do b = 1, 8
      do li = 1, 3; do lj = 1, 3
        gi = (ec(a)-1)*3+li; gj = (ec(b)-1)*3+lj
        K_g(gi,gj) = K_g(gi,gj) + Ke((a-1)*3+li, (b-1)*3+lj)
      end do; end do
    end do; end do
  end subroutine

  subroutine apply_bc_penalty(K, F, bc, nb, nd)
    real(wp), intent(inout) :: K(nd,nd), F(nd)
    integer(i4), intent(in) :: bc(*), nb, nd
    real(wp), parameter :: pen = 1.0e20_wp
    integer(i4) :: ii
    do ii = 1, nb
      K(bc(ii),bc(ii)) = K(bc(ii),bc(ii)) + pen
      F(bc(ii)) = 0.0_wp
    end do
  end subroutine

  subroutine solve_gauss(A, b, x, n)
    integer(i4), intent(in) :: n
    real(wp), intent(inout) :: A(n,n), b(n)
    real(wp), intent(out) :: x(n)
    real(wp) :: fac, mx, tmp
    integer(i4) :: ii, jj, kk, pr
    do kk = 1, n-1
      mx = abs(A(kk,kk)); pr = kk
      do ii = kk+1, n
        if (abs(A(ii,kk))>mx) then; mx=abs(A(ii,kk)); pr=ii; end if
      end do
      if (pr /= kk) then
        do jj = 1, n
          tmp=A(kk,jj); A(kk,jj)=A(pr,jj); A(pr,jj)=tmp
        end do
        tmp=b(kk); b(kk)=b(pr); b(pr)=tmp
      end if
      do ii = kk+1, n
        if (abs(A(kk,kk))>1e-30_wp) then
          fac = A(ii,kk)/A(kk,kk)
          do jj = kk+1, n
            A(ii,jj) = A(ii,jj) - fac*A(kk,jj)
          end do
          b(ii) = b(ii) - fac*b(kk)
        end if
      end do
    end do
    x = 0.0_wp
    do ii = n, 1, -1
      x(ii) = b(ii)
      do jj = ii+1, n
        x(ii) = x(ii) - A(ii,jj)*x(jj)
      end do
      if (abs(A(ii,ii))>1e-30_wp) x(ii) = x(ii)/A(ii,ii)
    end do
  end subroutine

end program E2E_C2_01_Cantilever_LinElastic
