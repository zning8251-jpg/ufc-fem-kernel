! LEGACY THIRD-PARTY (UFC_命名规范_v3.0 §10.1):
!   Module name `ModuleIters` does not follow UFC layer prefix convention.
!   This is a SPARSKIT iterative solver wrapper; not renamed.
MODULE ModuleIters
    USE ModuleBlas, ONLY: DAXPY, DDOT, DNRM2, DASUM, DCOPY, DROT, DSCAL, DSWAP, IDAMAX, AMUX, ATMUX
    USE ModuleItsol, ONLY: lusol, lutsol
    ! Note: DISTDOT is defined locally in this module as a wrapper for DDOT
    ! æ³¨æï¼ä¸ä½¿ç¨IMPLICIT NONEï¼å ä¸ºå­ç¨åºåé¨å·²åèªå£°æ?
    PUBLIC


CONTAINS

subroutine bcg(n,rhs,sol,ipar,fpar,w)
implicit none
integer n, ipar(16)
real*8  fpar(16), rhs(n), sol(n), w(n,*)
!-----------------------------------------------------------------------
!     BCG: Bi Conjugate Gradient method. Programmed with reverse
!     communication, see the header for detailed specifications
!     of the protocol.
!
!     in this routine, before successful return, the fpar's are
!     fpar(3) == initial residual norm
!     fpar(4) == target residual norm
!     fpar(5) == current residual norm
!     fpar(7) == current rho (rhok = <r, s>)
!     fpar(8) == previous rho (rhokm1)
!
!     w(:,1) -- r, the residual
!     w(:,2) -- s, the dual of the 'r'
!     w(:,3) -- p, the projection direction
!     w(:,4) -- q, the dual of the 'p'
!     w(:,5) -- v, a scratch vector to store A*p, or A*q.
!     w(:,6) -- a scratch vector to store intermediate results
!     w(:,7) -- changes in the solution
!-----------------------------------------------------------------------
!     external routines used
!
real*8 distdot
logical stopbis,brkdn
!

real*8 one
parameter(one=1.0D0)
!
!     local variables
!
integer i
real*8 alpha
logical rp, lp
save
!
!     status of the program
!
if (ipar(1).le.0) ipar(10) = 0
goto (10, 20, 40, 50, 60, 70, 80, 90, 100, 110), ipar(10)
!
!     initialization, initial residual
!
call bisinit(ipar,fpar,7*n,1,lp,rp,w)
if (ipar(1).lt.0) return
!
!     compute initial residual, request a matvecc
!
ipar(1) = 1
ipar(8) = 3*n+1
ipar(9) = ipar(8) + n
do i = 1, n
   w(i,4) = sol(i)
enddo
ipar(10) = 1
return
10 ipar(7) = ipar(7) + 1
ipar(13) = ipar(13) + 1
do i = 1, n
   w(i,1) = rhs(i) - w(i,5)
enddo
fpar(11) = fpar(11) + n
if (lp) then
   ipar(1) = 3
   ipar(8) = 1
   ipar(9) = n+1
   ipar(10) = 2
   return
endif
!
20 if (lp) then
   do i = 1, n
      w(i,1) = w(i,2)
      w(i,3) = w(i,2)
      w(i,4) = w(i,2)
   enddo
else
   do i = 1, n
      w(i,2) = w(i,1)
      w(i,3) = w(i,1)
      w(i,4) = w(i,1)
   enddo
endif
!
fpar(7) = distdot(n,w,1,w,1)
fpar(11) = fpar(11) + 2 * n
fpar(3) = sqrt(fpar(7))
fpar(5) = fpar(3)
fpar(8) = one
if (abs(ipar(3)).eq.2) then
   fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
   fpar(11) = fpar(11) + 2 * n
else if (ipar(3).ne.999) then
   fpar(4) = fpar(1) * fpar(3) + fpar(2)
endif
if (ipar(3).ge.0.and.fpar(5).le.fpar(4)) then
   fpar(6) = fpar(5)
   goto 900
endif
!
!     end of initialization, begin iteration, v = A p
!
30 if (rp) then
   ipar(1) = 5
   ipar(8) = n + n + 1
   if (lp) then
      ipar(9) = 4*n + 1
   else
      ipar(9) = 5*n + 1
   endif
   ipar(10) = 3
   return
endif
!
40 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = n + n + 1
endif
if (lp) then
   ipar(9) = 5*n + 1
else
   ipar(9) = 4*n + 1
endif
ipar(10) = 4
return
!
50 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = 4*n + 1
   ipar(10) = 5
   return
endif
!
60 ipar(7) = ipar(7) + 1
alpha = distdot(n,w(1,4),1,w(1,5),1)
fpar(11) = fpar(11) + 2 * n
if (brkdn(alpha,ipar)) goto 900
alpha = fpar(7) / alpha
do i = 1, n
   w(i,7) = w(i,7) + alpha * w(i,3)
   w(i,1) = w(i,1) - alpha * w(i,5)
enddo
fpar(11) = fpar(11) + 4 * n
if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = 6*n + 1
   ipar(9) = 5*n + 1
   ipar(10) = 6
   return
endif
70 if (ipar(3).eq.999) then
   if (ipar(11).eq.1) goto 900
else if (stopbis(n,ipar,1,fpar,w,w(1,3),alpha)) then
   goto 900
endif
!
!     A^t * x
!
if (lp) then
   ipar(1) = 4
   ipar(8) = 3*n + 1
   if (rp) then
      ipar(9) = 4*n + 1
   else
      ipar(9) = 5*n + 1
   endif
   ipar(10) = 7
   return
endif
!
80 ipar(1) = 2
if (lp) then
   ipar(8) = ipar(9)
else
   ipar(8) = 3*n + 1
endif
if (rp) then
   ipar(9) = 5*n + 1
else
   ipar(9) = 4*n + 1
endif
ipar(10) = 8
return
!
90 if (rp) then
   ipar(1) = 6
   ipar(8) = ipar(9)
   ipar(9) = 4*n + 1
   ipar(10) = 9
   return
endif
!
100 ipar(7) = ipar(7) + 1
do i = 1, n
   w(i,2) = w(i,2) - alpha * w(i,5)
enddo
fpar(8) = fpar(7)
fpar(7) = distdot(n,w,1,w(1,2),1)
fpar(11) = fpar(11) + 4 * n
if (brkdn(fpar(7), ipar)) return
alpha = fpar(7) / fpar(8)
do i = 1, n
   w(i,3) = w(i,1) + alpha * w(i,3)
   w(i,4) = w(i,2) + alpha * w(i,4)
enddo
fpar(11) = fpar(11) + 4 * n
!
!     end of the iterations
!
goto 30
!
!     some clean up job to do
!
900 if (rp) then
   if (ipar(1).lt.0) ipar(12) = ipar(1)
   ipar(1) = 5
   ipar(8) = 6*n + 1
   ipar(9) = ipar(8) - n
   ipar(10) = 10
   return
endif
110 if (rp) then
   call tidycg(n,ipar,fpar,sol,w(1,6))
else
   call tidycg(n,ipar,fpar,sol,w(1,7))
endif
return
!-----end-of-bcg
end subroutine bcg

subroutine bcgstab(n, rhs, sol, ipar, fpar, w)
implicit none
integer n, ipar(16)
real*8 rhs(n), sol(n), fpar(16), w(n,8)
!-----------------------------------------------------------------------
!     BCGSTAB --- Bi Conjugate Gradient stabilized (BCGSTAB)
!     This is an improved BCG routine. (1) no matrix transpose is
!     involved. (2) the convergence is smoother.
!
!
!     Algorithm:
!     Initialization - r = b - A x, r0 = r, p = r, rho = (r0, r),
!     Iterate -
!     (1) v = A p
!     (2) alpha = rho / (r0, v)
!     (3) s = r - alpha v
!     (4) t = A s
!     (5) omega = (t, s) / (t, t)
!     (6) x = x + alpha * p + omega * s
!     (7) r = s - omega * t
!     convergence test goes here
!     (8) beta = rho, rho = (r0, r), beta = rho * alpha / (beta * omega)
!         p = r + beta * (p - omega * v)
!
!     in this routine, before successful return, the fpar's are
!     fpar(3) == initial (preconditionied-)residual norm
!     fpar(4) == target (preconditionied-)residual norm
!     fpar(5) == current (preconditionied-)residual norm
!     fpar(6) == current residual norm or error
!     fpar(7) == current rho (rhok = <r, r0>)
!     fpar(8) == alpha
!     fpar(9) == omega
!
!     Usage of the work space W
!     w(:, 1) = r0, the initial residual vector
!     w(:, 2) = r, current residual vector
!     w(:, 3) = s
!     w(:, 4) = t
!     w(:, 5) = v
!     w(:, 6) = p
!     w(:, 7) = tmp, used in preconditioning, etc.
!     w(:, 8) = delta x, the correction to the answer is accumulated
!               here, so that the right-preconditioning may be applied
!               at the end
!-----------------------------------------------------------------------
!     external routines used
!
real*8 distdot
logical stopbis, brkdn
!

real*8 one
parameter(one=1.0D0)
!
!     local variables
!
integer i
real*8 alpha,beta,rho,omega
logical lp, rp
save lp, rp
!
!     where to go
!
if (ipar(1).gt.0) then
   goto (10, 20, 40, 50, 60, 70, 80, 90, 100, 110) ipar(10)
else if (ipar(1).lt.0) then
   goto 900
endif
!
!     call the initialization routine
!
call bisinit(ipar,fpar,8*n,1,lp,rp,w)
if (ipar(1).lt.0) return
!
!     perform a matvec to compute the initial residual
!
ipar(1) = 1
ipar(8) = 1
ipar(9) = 1 + n
do i = 1, n
   w(i,1) = sol(i)
enddo
ipar(10) = 1
return
10 ipar(7) = ipar(7) + 1
ipar(13) = ipar(13) + 1
do i = 1, n
   w(i,1) = rhs(i) - w(i,2)
enddo
fpar(11) = fpar(11) + n
if (lp) then
   ipar(1) = 3
   ipar(10) = 2
   return
endif
!
20 if (lp) then
   do i = 1, n
      w(i,1) = w(i,2)
      w(i,6) = w(i,2)
   enddo
else
   do i = 1, n
      w(i,2) = w(i,1)
      w(i,6) = w(i,1)
   enddo
endif
!
fpar(7) = distdot(n,w,1,w,1)
fpar(11) = fpar(11) + 2 * n
fpar(5) = sqrt(fpar(7))
fpar(3) = fpar(5)
if (abs(ipar(3)).eq.2) then
   fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
   fpar(11) = fpar(11) + 2 * n
else if (ipar(3).ne.999) then
   fpar(4) = fpar(1) * fpar(3) + fpar(2)
endif
if (ipar(3).ge.0) fpar(6) = fpar(5)
if (ipar(3).ge.0 .and. fpar(5).le.fpar(4) .and. &
         ipar(3).ne.999) then
   goto 900
endif
!
!     beginning of the iterations
!
!     Step (1), v = A p
30 if (rp) then
   ipar(1) = 5
   ipar(8) = 5*n+1
   if (lp) then
      ipar(9) = 4*n + 1
   else
      ipar(9) = 6*n + 1
   endif
   ipar(10) = 3
   return
endif
!
40 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = 5*n+1
endif
if (lp) then
   ipar(9) = 6*n + 1
else
   ipar(9) = 4*n + 1
endif
ipar(10) = 4
return
50 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = 4*n + 1
   ipar(10) = 5
   return
endif
!
60 ipar(7) = ipar(7) + 1
!
!     step (2)
alpha = distdot(n,w(1,1),1,w(1,5),1)
fpar(11) = fpar(11) + 2 * n
if (brkdn(alpha, ipar)) goto 900
alpha = fpar(7) / alpha
fpar(8) = alpha
!
!     step (3)
do i = 1, n
   w(i,3) = w(i,2) - alpha * w(i,5)
enddo
fpar(11) = fpar(11) + 2 * n
!
!     Step (4): the second matvec -- t = A s
!
if (rp) then
   ipar(1) = 5
   ipar(8) = n+n+1
   if (lp) then
      ipar(9) = ipar(8)+n
   else
      ipar(9) = 6*n + 1
   endif
   ipar(10) = 6
   return
endif
!
70 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = n+n+1
endif
if (lp) then
   ipar(9) = 6*n + 1
else
   ipar(9) = 3*n + 1
endif
ipar(10) = 7
return
80 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = 3*n + 1
   ipar(10) = 8
   return
endif
90 ipar(7) = ipar(7) + 1
!
!     step (5)
omega = distdot(n,w(1,4),1,w(1,4),1)
fpar(11) = fpar(11) + n + n
if (brkdn(omega,ipar)) goto 900
omega = distdot(n,w(1,4),1,w(1,3),1) / omega
fpar(11) = fpar(11) + n + n
if (brkdn(omega,ipar)) goto 900
fpar(9) = omega
alpha = fpar(8)
!
!     step (6) and (7)
do i = 1, n
   w(i,7) = alpha * w(i,6) + omega * w(i,3)
   w(i,8) = w(i,8) + w(i,7)
   w(i,2) = w(i,3) - omega * w(i,4)
enddo
fpar(11) = fpar(11) + 6 * n + 1
!
!     convergence test
if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = 7*n + 1
   ipar(9) = 6*n + 1
   ipar(10) = 9
   return
endif
if (stopbis(n,ipar,2,fpar,w(1,2),w(1,7),one))  goto 900
100 if (ipar(3).eq.999.and.ipar(11).eq.1) goto 900
!
!     step (8): computing new p and rho
rho = fpar(7)
fpar(7) = distdot(n,w(1,2),1,w(1,1),1)
omega = fpar(9)
beta = fpar(7) * fpar(8) / (fpar(9) * rho)
do i = 1, n
   w(i,6) = w(i,2) + beta * (w(i,6) - omega * w(i,5))
enddo
fpar(11) = fpar(11) + 6 * n + 3
if (brkdn(fpar(7),ipar)) goto 900
!
!     end of an iteration
!
goto 30
!
!     some clean up job to do
!
900 if (rp) then
   if (ipar(1).lt.0) ipar(12) = ipar(1)
   ipar(1) = 5
   ipar(8) = 7*n + 1
   ipar(9) = ipar(8) - n
   ipar(10) = 10
   return
endif
110 if (rp) then
   call tidycg(n,ipar,fpar,sol,w(1,7))
else
   call tidycg(n,ipar,fpar,sol,w(1,8))
endif
!
return
!-----end-of-bcgstab
end subroutine bcgstab

subroutine bisinit(ipar,fpar,wksize,dsc,lp,rp,wk)
implicit none
integer i,ipar(16),wksize,dsc
logical lp,rp
real*8  fpar(16),wk(*)
!-----------------------------------------------------------------------
!     some common initializations for the iterative solvers
!-----------------------------------------------------------------------
real*8 zero, one
parameter(zero=0.0D0, one=1.0D0)
!
!     ipar(1) = -2 inidcate that there are not enough space in the work
!     array
!
if (ipar(4).lt.wksize) then
   ipar(1) = -2
   ipar(4) = wksize
   return
endif
!
if (ipar(2).gt.2) then
   lp = .true.
   rp = .true.
else if (ipar(2).eq.2) then
   lp = .false.
   rp = .true.
else if (ipar(2).eq.1) then
   lp = .true.
   rp = .false.
else
   lp = .false.
   rp = .false.
endif
if (ipar(3).eq.0) ipar(3) = dsc
!     .. clear the ipar elements used
ipar(7) = 0
ipar(8) = 0
ipar(9) = 0
ipar(10) = 0
ipar(11) = 0
ipar(12) = 0
ipar(13) = 0
!
!     fpar(1) must be between (0, 1), fpar(2) must be positive,
!     fpar(1) and fpar(2) can NOT both be zero
!     Normally return ipar(1) = -4 to indicate any of above error
!
if (fpar(1).lt.zero .or. fpar(1).ge.one .or. fpar(2).lt.zero .or. &
         (fpar(1).eq.zero .and. fpar(2).eq.zero)) then
   if (ipar(1).eq.0) then
      ipar(1) = -4
      return
   else
      fpar(1) = 1.0D-6
      fpar(2) = 1.0D-16
   endif
endif
!     .. clear the fpar elements
do i = 3, 10
   fpar(i) = zero
enddo
if (fpar(11).lt.zero) fpar(11) = zero
!     .. clear the used portion of the work array to zero
do i = 1, wksize
   wk(i) = zero
enddo
!
return
!-----end-of-bisinit
end subroutine bisinit

subroutine cg(n, rhs, sol, ipar, fpar, w)
implicit none
integer n, ipar(16)
real*8 rhs(n), sol(n), fpar(16), w(n,*)
!-----------------------------------------------------------------------
!     This is a implementation of the Conjugate Gradient (CG) method
!     for solving linear system.
!
!     NOTE: This is not the PCG algorithm. It is a regular CG algorithm.
!     To be consistent with the other solvers, the preconditioners are
!     applied by performing Ml^{-1} A Mr^{-1} P in place of A P in the
!     CG algorithm. The PCG uses its preconditioners very differently.
!
!     fpar(7) is used here internally to store <r, r>.
!     w(:,1) -- residual vector
!     w(:,2) -- P, the conjugate direction
!     w(:,3) -- A P, matrix multiply the conjugate direction
!     w(:,4) -- temporary storage for results of preconditioning
!     w(:,5) -- change in the solution (sol) is stored here until
!               termination of this solver
!-----------------------------------------------------------------------
!     external functions used
!
real*8 distdot
logical stopbis, brkdn
!

!     local variables
!
integer i
real*8 alpha
logical lp,rp
save
!
!     check the status of the call
!
if (ipar(1).le.0) ipar(10) = 0
goto (10, 20, 40, 50, 60, 70, 80), ipar(10)
!
!     initialization
!
call bisinit(ipar,fpar,5*n,1,lp,rp,w)
if (ipar(1).lt.0) return
!
!     request for matrix vector multiplication A*x in the initialization
!
ipar(1) = 1
ipar(8) = n+1
ipar(9) = ipar(8) + n
ipar(10) = 1
do i = 1, n
   w(i,2) = sol(i)
enddo
return
10 ipar(7) = ipar(7) + 1
ipar(13) = 1
do i = 1, n
   w(i,2) = rhs(i) - w(i,3)
enddo
fpar(11) = fpar(11) + n
!
!     if left preconditioned
!
if (lp) then
   ipar(1) = 3
   ipar(9) = 1
   ipar(10) = 2
   return
endif
!
20 if (lp) then
   do i = 1, n
      w(i,2) = w(i,1)
   enddo
else
   do i = 1, n
      w(i,1) = w(i,2)
   enddo
endif
!
fpar(7) = distdot(n,w,1,w,1)
fpar(11) = fpar(11) + 2 * n
fpar(3) = sqrt(fpar(7))
fpar(5) = fpar(3)
if (abs(ipar(3)).eq.2) then
   fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
   fpar(11) = fpar(11) + 2 * n
else if (ipar(3).ne.999) then
   fpar(4) = fpar(1) * fpar(3) + fpar(2)
endif
!
!     before iteration can continue, we need to compute A * p, which
!     includes the preconditioning operations
!
30 if (rp) then
   ipar(1) = 5
   ipar(8) = n + 1
   if (lp) then
      ipar(9) = ipar(8) + n
   else
      ipar(9) = 3*n + 1
   endif
   ipar(10) = 3
   return
endif
!
40 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = n + 1
endif
if (lp) then
   ipar(9) = 3*n+1
else
   ipar(9) = n+n+1
endif
ipar(10) = 4
return
!
50 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = n+n+1
   ipar(10) = 5
   return
endif
!
!     continuing with the iterations
!
60 ipar(7) = ipar(7) + 1
alpha = distdot(n,w(1,2),1,w(1,3),1)
fpar(11) = fpar(11) + 2*n
if (brkdn(alpha,ipar)) goto 900
alpha = fpar(7) / alpha
do i = 1, n
   w(i,5) = w(i,5) + alpha * w(i,2)
   w(i,1) = w(i,1) - alpha * w(i,3)
enddo
fpar(11) = fpar(11) + 4*n
!
!     are we ready to terminate ?
!
if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = 4*n + 1
   ipar(9) = 3*n + 1
   ipar(10) = 6
   return
endif
70 if (ipar(3).eq.999) then
   if (ipar(11).eq.1) goto 900
else if (stopbis(n,ipar,1,fpar,w,w(1,2),alpha)) then
   goto 900
endif
!
!     continue the iterations
!
alpha = fpar(5)*fpar(5) / fpar(7)
fpar(7) = fpar(5)*fpar(5)
do i = 1, n
   w(i,2) = w(i,1) + alpha * w(i,2)
enddo
fpar(11) = fpar(11) + 2*n
goto 30
!
!     clean up -- necessary to accommodate the right-preconditioning
!
900 if (rp) then
   if (ipar(1).lt.0) ipar(12) = ipar(1)
   ipar(1) = 5
   ipar(8) = 4*n + 1
   ipar(9) = ipar(8) - n
   ipar(10) = 7
   return
endif
80 if (rp) then
   call tidycg(n,ipar,fpar,sol,w(1,4))
else
   call tidycg(n,ipar,fpar,sol,w(1,5))
endif
!
return
end subroutine cg

subroutine cgnr(n,rhs,sol,ipar,fpar,wk)
implicit none
integer n, ipar(16)
real*8 rhs(n),sol(n),fpar(16),wk(n,*)
!-----------------------------------------------------------------------
!     CGNR -- Using CG algorithm solving A x = b by solving
!     Normal Residual equation: A^T A x = A^T b
!     As long as the matrix is not singular, A^T A is symmetric
!     positive definite, therefore CG (CGNR) will converge.
!
!     Usage of the work space:
!     wk(:,1) == residual vector R
!     wk(:,2) == the conjugate direction vector P
!     wk(:,3) == a scratch vector holds A P, or A^T R
!     wk(:,4) == a scratch vector holds intermediate results of the
!                preconditioning
!     wk(:,5) == a place to hold the modification to SOL
!
!     size of the work space WK is required = 5*n
!-----------------------------------------------------------------------
!     external functions used
!
real*8 distdot
logical stopbis, brkdn
!

!     local variables
!
integer i
real*8 alpha, zz, zzm1
logical lp, rp
save
!
!     check the status of the call
!
if (ipar(1).le.0) ipar(10) = 0
goto (10, 20, 40, 50, 60, 70, 80, 90, 100, 110), ipar(10)
!
!     initialization
!
call bisinit(ipar,fpar,5*n,1,lp,rp,wk)
if (ipar(1).lt.0) return
!
!     request for matrix vector multiplication A*x in the initialization
!
ipar(1) = 1
ipar(8) = 1
ipar(9) = 1 + n
ipar(10) = 1
do i = 1, n
   wk(i,1) = sol(i)
enddo
return
10 ipar(7) = ipar(7) + 1
ipar(13) = ipar(13) + 1
do i = 1, n
   wk(i,1) = rhs(i) - wk(i,2)
enddo
fpar(11) = fpar(11) + n
!
!     if left preconditioned, precondition the initial residual
!
if (lp) then
   ipar(1) = 3
   ipar(10) = 2
   return
endif
!
20 if (lp) then
   do i = 1, n
      wk(i,1) = wk(i,2)
   enddo
endif
!
zz = distdot(n,wk,1,wk,1)
fpar(11) = fpar(11) + 2 * n
fpar(3) = sqrt(zz)
fpar(5) = fpar(3)
if (abs(ipar(3)).eq.2) then
   fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
   fpar(11) = fpar(11) + 2 * n
else if (ipar(3).ne.999) then
   fpar(4) = fpar(1) * fpar(3) + fpar(2)
endif
!
!     normal iteration begins here, first half of the iteration
!     computes the conjugate direction
!
30 continue
!
!     request the caller to perform a A^T r --> wk(:,3)
!
if (lp) then
   ipar(1) = 4
   ipar(8) = 1
   if (rp) then
      ipar(9) = n + n + 1
   else
      ipar(9) = 3*n + 1
   endif
   ipar(10) = 3
   return
endif
!
40 ipar(1) = 2
if (lp) then
   ipar(8) = ipar(9)
else
   ipar(8) = 1
endif
if (rp) then
   ipar(9) = 3*n + 1
else
   ipar(9) = n + n + 1
endif
ipar(10) = 4
return
!
50 if (rp) then
   ipar(1) = 6
   ipar(8) = ipar(9)
   ipar(9) = n + n + 1
   ipar(10) = 5
   return
endif
!
60 ipar(7) = ipar(7) + 1
zzm1 = zz
zz = distdot(n,wk(1,3),1,wk(1,3),1)
fpar(11) = fpar(11) + 2 * n
if (brkdn(zz,ipar)) goto 900
if (ipar(7).gt.3) then
   alpha = zz / zzm1
   do i = 1, n
      wk(i,2) = wk(i,3) + alpha * wk(i,2)
   enddo
   fpar(11) = fpar(11) + 2 * n
else
   do i = 1, n
      wk(i,2) = wk(i,3)
   enddo
endif
!
!     before iteration can continue, we need to compute A * p
!
if (rp) then
   ipar(1) = 5
   ipar(8) = n + 1
   if (lp) then
      ipar(9) = ipar(8) + n
   else
      ipar(9) = 3*n + 1
   endif
   ipar(10) = 6
   return
endif
!
70 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = n + 1
endif
if (lp) then
  ipar(9) = 3*n+1
else
   ipar(9) = n+n+1
endif
ipar(10) = 7
return
!
80 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = n+n+1
   ipar(10) = 8
   return
endif
!
!     update the solution -- accumulate the changes in w(:,5)
!
90 ipar(7) = ipar(7) + 1
alpha = distdot(n,wk(1,3),1,wk(1,3),1)
fpar(11) = fpar(11) + 2 * n
if (brkdn(alpha,ipar)) goto 900
alpha = zz / alpha
do i = 1, n
   wk(i,5) = wk(i,5) + alpha * wk(i,2)
   wk(i,1) = wk(i,1) - alpha * wk(i,3)
enddo
fpar(11) = fpar(11) + 4 * n
!
!     are we ready to terminate ?
!
if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = 4*n + 1
   ipar(9) = 3*n + 1
   ipar(10) = 9
   return
endif
100 if (ipar(3).eq.999) then
   if (ipar(11).eq.1) goto 900
else if (stopbis(n,ipar,1,fpar,wk,wk(1,2),alpha)) then
   goto 900
endif
!
!     continue the iterations
!
goto 30
!
!     clean up -- necessary to accommodate the right-preconditioning
!
900 if (rp) then
   if (ipar(1).lt.0) ipar(12) = ipar(1)
   ipar(1) = 5
   ipar(8) = 4*n + 1
   ipar(9) = ipar(8) - n
   ipar(10) = 10
   return
endif
110 if (rp) then
   call tidycg(n,ipar,fpar,sol,wk(1,4))
else
   call tidycg(n,ipar,fpar,sol,wk(1,5))
endif
return
end subroutine cgnr

subroutine dbcg (n,rhs,sol,ipar,fpar,w)
implicit none
integer n,ipar(16)
real*8 rhs(n), sol(n), fpar(16), w(n,*)
!-----------------------------------------------------------------------
! Quasi GMRES method for solving a linear
! system of equations a * sol = y.  double precision version.
! this version is without restarting and without preconditioning.
! parameters :
! -----------
! n     = dimension of the problem
!
! y     = w(:,1) a temporary storage used for various operations
! z     = w(:,2) a work vector of length n.
! v     = w(:,3:4) size n x 2
! w     = w(:,5:6) size n x 2
! p     = w(:,7:9) work array of dimension n x 3
! del x = w(:,10)  accumulation of the changes in solution
! tmp   = w(:,11)  a temporary vector used to hold intermediate result of
!                  preconditioning, etc.
!
! sol   = the solution of the problem . at input sol must contain an
!         initial guess to the solution.
!    ***  note:   y is destroyed on return.
!
!-----------------------------------------------------------------------
! subroutines and functions called:
! 1) matrix vector multiplication and preconditioning through reverse
!     communication
!
! 2) implu, uppdir, distdot (blas)
!-----------------------------------------------------------------------
! aug. 1983  version.    author youcef saad. yale university computer
! science dept. some  changes made july 3, 1986.
! references: siam j. sci. stat. comp., vol. 5, pp. 203-228 (1984)
!-----------------------------------------------------------------------
!     local variables
!
real*8 one,zero
parameter(one=1.0D0,zero=0.0D0)
!
real*8 t,sqrt,distdot,ss,res,beta,ss1,delta,x,zeta,umm
integer k,j,i,i2,ip2,ju,lb,lbm1,np,indp
logical lp,rp,full, perm(3)
real*8 ypiv(3),u(3),usav(3)
save

!
!     where to go
!
if (ipar(1).le.0) ipar(10) = 0
goto (110, 120, 130, 140, 150, 160, 170, 180, 190, 200) ipar(10)
!
!     initialization, parameter checking, clear the work arrays
!
call bisinit(ipar,fpar,11*n,1,lp,rp,w)
if (ipar(1).lt.0) return
perm(1) = .false.
perm(2) = .false.
perm(3) = .false.
usav(1) = zero
usav(2) = zero
usav(3) = zero
ypiv(1) = zero
ypiv(2) = zero
ypiv(3) = zero
!-----------------------------------------------------------------------
!     initialize constants for outer loop :
!-----------------------------------------------------------------------
lb = 3
lbm1 = 2
!
!     get initial residual vector and norm
!
ipar(1) = 1
ipar(8) = 1
ipar(9) = 1 + n
do i = 1, n
   w(i,1) = sol(i)
enddo
ipar(10) = 1
return
110 ipar(7) = ipar(7) + 1
ipar(13) = ipar(13) + 1
if (lp) then
   do i = 1, n
      w(i,1) = rhs(i) - w(i,2)
   enddo
   ipar(1) = 3
   ipar(8) = 1
   ipar(9) = n+n+1
   ipar(10) = 2
   return
else
   do i = 1, n
      w(i,3) = rhs(i) - w(i,2)
   enddo
endif
fpar(11) = fpar(11) + n
!
120 fpar(3) = sqrt(distdot(n,w(1,3),1,w(1,3),1))
fpar(11) = fpar(11) + n + n
fpar(5) = fpar(3)
fpar(7) = fpar(3)
zeta = fpar(3)
if (abs(ipar(3)).eq.2) then
   fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
   fpar(11) = fpar(11) + 2*n
else if (ipar(3).ne.999) then
   fpar(4) = fpar(1) * zeta + fpar(2)
endif
if (ipar(3).ge.0.and.fpar(5).le.fpar(4)) then
   fpar(6) = fpar(5)
   goto 900
endif
!
!     normalize first arnoldi vector
!
t = one/zeta
do 22 k=1,n
   w(k,3) = w(k,3)*t
   w(k,5) = w(k,3)
22 continue
fpar(11) = fpar(11) + n
!
!     initialize constants for main loop
!
beta = zero
delta = zero
i2 = 1
indp = 0
i = 0
!
!     main loop: i = index of the loop.
!
!-----------------------------------------------------------------------
30 i = i + 1
!
if (rp) then
   ipar(1) = 5
   ipar(8) = (1+i2)*n+1
   if (lp) then
      ipar(9) = 1
   else
      ipar(9) = 10*n + 1
   endif
   ipar(10) = 3
   return
endif
!
130 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = (1+i2)*n + 1
endif
if (lp) then
   ipar(9) = 10*n + 1
else
   ipar(9) = 1
endif
ipar(10) = 4
return
!
140 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = 1
   ipar(10) = 5
   return
endif
!
!     A^t * x
!
150 ipar(7) = ipar(7) + 1
if (lp) then
   ipar(1) = 4
   ipar(8) = (3+i2)*n + 1
   if (rp) then
      ipar(9) = n + 1
   else
      ipar(9) = 10*n + 1
   endif
   ipar(10) = 6
   return
endif
!
160 ipar(1) = 2
if (lp) then
   ipar(8) = ipar(9)
else
   ipar(8) = (3+i2)*n + 1
endif
if (rp) then
   ipar(9) = 10*n + 1
else
   ipar(9) = n + 1
endif
ipar(10) = 7
return
!
170 if (rp) then
   ipar(1) = 6
   ipar(8) = ipar(9)
   ipar(9) = n + 1
   ipar(10) = 8
   return
endif
!-----------------------------------------------------------------------
!     orthogonalize current v against previous v's and
!     determine relevant part of i-th column of u(.,.) the
!     upper triangular matrix --
!-----------------------------------------------------------------------
180 ipar(7) = ipar(7) + 1
u(1) = zero
ju = 1
k = i2
if (i .le. lbm1) ju = 0
if (i .lt. lb) k = 0
31 if (k .eq. lbm1) k=0
k=k+1
!
if (k .ne. i2) then
   ss  = delta
   ss1 = beta
   ju = ju + 1
   u(ju) = ss
else
   ss = distdot(n,w(1,1),1,w(1,4+k),1)
   fpar(11) = fpar(11) + 2*n
   ss1= ss
   ju = ju + 1
   u(ju) = ss
endif
!
do 32  j=1,n
   w(j,1) = w(j,1) - ss*w(j,k+2)
   w(j,2) = w(j,2) - ss1*w(j,k+4)
32 continue
fpar(11) = fpar(11) + 4*n
!
if (k .ne. i2) goto 31
!
!     end of Mod. Gram. Schmidt loop
!
t = distdot(n,w(1,2),1,w(1,1),1)
!
beta   = sqrt(abs(t))
delta  = t/beta
!
ss = one/beta
ss1 = one/ delta
!
!     normalize and insert new vectors
!
ip2 = i2
if (i2 .eq. lbm1) i2=0
i2=i2+1
!
do 315 j=1,n
   w(j,i2+2)=w(j,1)*ss
   w(j,i2+4)=w(j,2)*ss1
315 continue
fpar(11) = fpar(11) + 4*n
!-----------------------------------------------------------------------
!     end of orthogonalization.
!     now compute the coefficients u(k) of the last
!     column of the  l . u  factorization of h .
!-----------------------------------------------------------------------
np = min0(i,lb)
full = (i .ge. lb)
call implu(np, umm, beta, ypiv, u, perm, full)
!-----------------------------------------------------------------------
!     update conjugate directions and solution
!-----------------------------------------------------------------------
do 33 k=1,n
   w(k,1) = w(k,ip2+2)
33 continue
call uppdir(n, w(1,7), np, lb, indp, w, u, usav, fpar(11))
!-----------------------------------------------------------------------
if (i .eq. 1) goto 34
j = np - 1
if (full) j = j-1
if (.not.perm(j)) zeta = -zeta*ypiv(j)
34 x = zeta/u(np)
if (perm(np))goto 36
do 35 k=1,n
   w(k,10) = w(k,10) + x*w(k,1)
35 continue
fpar(11) = fpar(11) + 2 * n
!-----------------------------------------------------------------------
36 if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = 9*n + 1
   ipar(9) = 10*n + 1
   ipar(10) = 9
   return
endif
res = abs(beta*zeta/umm)
fpar(5) = res * sqrt(distdot(n, w(1,i2+2), 1, w(1,i2+2), 1))
fpar(11) = fpar(11) + 2 * n
if (ipar(3).lt.0) then
   fpar(6) = x * sqrt(distdot(n,w,1,w,1))
   fpar(11) = fpar(11) + 2 * n
   if (ipar(7).le.3) then
      fpar(3) = fpar(6)
      if (ipar(3).eq.-1) then
         fpar(4) = fpar(1) * sqrt(fpar(3)) + fpar(2)
      endif
   endif
else
   fpar(6) = fpar(5)
endif
!---- convergence test -----------------------------------------------
190 if (ipar(3).eq.999.and.ipar(11).eq.0) then
   goto 30
else if (fpar(6).gt.fpar(4) .and. (ipar(6).gt.ipar(7) .or. &
            ipar(6).le.0)) then
   goto 30
endif
!-----------------------------------------------------------------------
!     here the fact that the last step is different is accounted for.
!-----------------------------------------------------------------------
if (.not. perm(np)) goto 900
x = zeta/umm
do 40 k = 1,n
   w(k,10) = w(k,10) + x*w(k,1)
40 continue
fpar(11) = fpar(11) + 2 * n
!
!     right preconditioning and clean-up jobs
!
900 if (rp) then
   if (ipar(1).lt.0) ipar(12) = ipar(1)
   ipar(1) = 5
   ipar(8) = 9*n + 1
   ipar(9) = ipar(8) + n
   ipar(10) = 10
   return
endif
200 if (rp) then
   call tidycg(n,ipar,fpar,sol,w(1,11))
else
   call tidycg(n,ipar,fpar,sol,w(1,10))
endif
return
end subroutine dbcg

subroutine dqgmres(n, rhs, sol, ipar, fpar, w)
implicit none
integer n, ipar(16)
real*8 rhs(n), sol(n), fpar(16), w(*)
!-----------------------------------------------------------------------
!     DQGMRES -- Flexible Direct version of Quasi-General Minimum
!     Residual method. The right preconditioning can be varied from
!     step to step.
!
!     Work space used = n + lb * (2*n+4)
!     where lb = ipar(5) + 1 (default 16 if ipar(5) <= 1)
!-----------------------------------------------------------------------
!     local variables
!
real*8 one,zero,deps
parameter(one=1.0D0,zero=0.0D0)
parameter(deps=1.0D-33)
!
integer i,ii,j,jp1,j0,k,ptrw,ptrv,iv,iw,ic,is,ihm,ihd,lb,ptr
real*8 alpha,beta,psi,c,s,distdot
logical lp,rp,full
save

!
!     where to go
!
if (ipar(1).le.0) ipar(10) = 0
goto (10, 20, 40, 50, 60, 70) ipar(10)
!
!     locations of the work arrays. The arrangement is as follows:
!     w(1:n) -- temporary storage for the results of the preconditioning
!     w(iv+1:iw) -- the V's
!     w(iw+1:ic) -- the W's
!     w(ic+1:is) -- the COSINEs of the Givens rotations
!     w(is+1:ihm) -- the SINEs of the Givens rotations
!     w(ihm+1:ihd) -- the last column of the Hessenberg matrix
!     w(ihd+1:i) -- the inverse of the diagonals of the Hessenberg matrix
!
if (ipar(5).le.1) then
   lb = 16
else
   lb = ipar(5) + 1
endif
iv = n
iw = iv + lb * n
ic = iw + lb * n
is = ic + lb
ihm = is + lb
ihd = ihm + lb
i = ihd + lb
!
!     parameter check, initializations
!
full = .false.
call bisinit(ipar,fpar,i,1,lp,rp,w)
if (ipar(1).lt.0) return
ipar(1) = 1
if (lp) then
   do ii = 1, n
      w(iv+ii) = sol(ii)
   enddo
   ipar(8) = iv+1
   ipar(9) = 1
else
   do ii = 1, n
      w(ii) = sol(ii)
   enddo
   ipar(8) = 1
   ipar(9) = iv+1
endif
ipar(10) = 1
return
!
10 ipar(7) = ipar(7) + 1
ipar(13) = ipar(13) + 1
if (lp) then
   do i = 1, n
      w(i) = rhs(i) - w(i)
   enddo
   ipar(1) = 3
   ipar(8) = 1
   ipar(9) = iv+1
   ipar(10) = 2
   return
else
   do i = 1, n
      w(iv+i) = rhs(i) - w(iv+i)
   enddo
endif
fpar(11) = fpar(11) + n
!
20 alpha = sqrt(distdot(n, w(iv+1), 1, w(iv+1), 1))
fpar(11) = fpar(11) + (n + n)
if (abs(ipar(3)).eq.2) then
   fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
   fpar(11) = fpar(11) + 2*n
else if (ipar(3).ne.999) then
   fpar(4) = fpar(1) * alpha + fpar(2)
endif
fpar(3) = alpha
fpar(5) = alpha
psi = alpha
if (alpha.le.fpar(4)) then
   ipar(1) = 0
   fpar(6) = alpha
   goto 80
endif
alpha = one / alpha
do i = 1, n
   w(iv+i) = w(iv+i) * alpha
enddo
fpar(11) = fpar(11) + n
j = 0
!
!     iterations start here
!
30 j = j + 1
if (j.gt.lb) j = j - lb
jp1 = j + 1
if (jp1.gt.lb) jp1 = jp1 - lb
ptrv = iv + (j-1)*n + 1
ptrw = iv + (jp1-1)*n + 1
if (.not.full) then
   if (j.gt.jp1) full = .true.
endif
if (full) then
   j0 = jp1+1
   if (j0.gt.lb) j0 = j0 - lb
else
   j0 = 1
endif
!
!     request the caller to perform matrix-vector multiplication and
!     preconditioning
!
if (rp) then
   ipar(1) = 5
   ipar(8) = ptrv
   ipar(9) = ptrv + iw - iv
   ipar(10) = 3
   return
else
   do i = 0, n-1
      w(ptrv+iw-iv+i) = w(ptrv+i)
   enddo
endif
!
40 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = ptrv
endif
if (lp) then
   ipar(9) = 1
else
   ipar(9) = ptrw
endif
ipar(10) = 4
return
!
50 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = ptrw
   ipar(10) = 5
   return
endif
!
!     compute the last column of the Hessenberg matrix
!     modified Gram-schmidt procedure, orthogonalize against (lb-1)
!     previous vectors
!
60 continue
call mgsro(full,n,n,lb,jp1,fpar(11),w(iv+1),w(ihm+1), &
         ipar(12))
if (ipar(12).lt.0) then
   ipar(1) = -3
   goto 80
endif
beta = w(ihm+jp1)
!
!     incomplete factorization (QR factorization through Givens rotations)
!     (1) apply previous rotations [(lb-1) of them]
!     (2) generate a new rotation
!
if (full) then
   w(ihm+jp1) = w(ihm+j0) * w(is+jp1)
   w(ihm+j0) = w(ihm+j0) * w(ic+jp1)
endif
i = j0
do while (i.ne.j)
   k = i+1
   if (k.gt.lb) k = k - lb
   c = w(ic+i)
   s = w(is+i)
   alpha = w(ihm+i)
   w(ihm+i) = c * alpha + s * w(ihm+k)
   w(ihm+k) = c * w(ihm+k) - s * alpha
   i = k
enddo
call givens(w(ihm+j), beta, c, s)
if (full) then
   fpar(11) = fpar(11) + 6 * lb
else
   fpar(11) = fpar(11) + 6 * j
endif
!
!     detect whether diagonal element of this column is zero
!
if (abs(w(ihm+j)).lt.deps) then
   ipar(1) = -3
   goto 80
endif
w(ihd+j) = one / w(ihm+j)
w(ic+j) = c
w(is+j) = s
!
!     update the W's (the conjugate directions) -- essentially this is one
!     step of triangular solve.
!
ptrw = iw+(j-1)*n + 1
if (full) then
   do i = j+1, lb
      alpha = -w(ihm+i)*w(ihd+i)
      ptr = iw+(i-1)*n+1
      do ii = 0, n-1
         w(ptrw+ii) = w(ptrw+ii) + alpha * w(ptr+ii)
      enddo
   enddo
endif
do i = 1, j-1
   alpha = -w(ihm+i)*w(ihd+i)
   ptr = iw+(i-1)*n+1
   do ii = 0, n-1
      w(ptrw+ii) = w(ptrw+ii) + alpha * w(ptr+ii)
   enddo
enddo
!
!     update the solution to the linear system
!
alpha = psi * c * w(ihd+j)
psi = - s * psi
do i = 1, n
   sol(i) = sol(i) + alpha * w(ptrw-1+i)
enddo
if (full) then
   fpar(11) = fpar(11) + lb * (n+n)
else
   fpar(11) = fpar(11) + j * (n+n)
endif
!
!     determine whether to continue,
!     compute the desired error/residual norm
!
ipar(7) = ipar(7) + 1
fpar(5) = abs(psi)
if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = -1
   ipar(9) = 1
   ipar(10) = 6
   return
endif
if (ipar(3).lt.0) then
   alpha = abs(alpha)
   if (ipar(7).eq.2 .and. ipar(3).eq.-1) then
      fpar(3) = alpha*sqrt(distdot(n, w(ptrw), 1, w(ptrw), 1))
      fpar(4) = fpar(1) * fpar(3) + fpar(2)
      fpar(6) = fpar(3)
   else
      fpar(6) = alpha*sqrt(distdot(n, w(ptrw), 1, w(ptrw), 1))
   endif
   fpar(11) = fpar(11) + 2 * n
else
   fpar(6) = fpar(5)
endif
if (ipar(1).ge.0 .and. fpar(6).gt.fpar(4) .and. (ipar(6).le.0 &
         .or. ipar(7).lt.ipar(6))) goto 30
70 if (ipar(3).eq.999 .and. ipar(11).eq.0) goto 30
!
!     clean up the iterative solver
!
80 fpar(7) = zero
if (fpar(3).ne.zero .and. fpar(6).ne.zero .and. &
         ipar(7).gt.ipar(13)) &
         fpar(7) = log10(fpar(3) / fpar(6)) / dble(ipar(7)-ipar(13))
if (ipar(1).gt.0) then
   if (ipar(3).eq.999 .and. ipar(11).ne.0) then
      ipar(1) = 0
   else if (fpar(6).le.fpar(4)) then
      ipar(1) = 0
   else if (ipar(6).gt.0 .and. ipar(7).ge.ipar(6)) then
      ipar(1) = -1
   else
      ipar(1) = -10
   endif
endif
return
end subroutine dqgmres

subroutine fgmres(n, rhs, sol, ipar, fpar, w)
implicit none
integer n, ipar(16)
real*8 rhs(n), sol(n), fpar(16), w(*)
!-----------------------------------------------------------------------
!     This a version of FGMRES implemented with reverse communication.
!
!     ipar(5) == the dimension of the Krylov subspace
!
!     the space of the `w' is used as follows:
!     >> V: the bases for the Krylov subspace, size n*(m+1);
!     >> W: the above bases after (left-)multiplying with the
!     right-preconditioner inverse, size m*n;
!     >> a temporary vector of size n;
!     >> the Hessenberg matrix, only the upper triangular portion
!     of the matrix is stored, size (m+1)*m/2 + 1
!     >> three vectors, first two are of size m, they are the cosine
!     and sine of the Givens rotations, the third one holds the
!     residuals, it is of size m+1.
!
!     TOTAL SIZE REQUIRED == n*(2m+1) + (m+1)*m/2 + 3*m + 2
!     Note: m == ipar(5). The default value for this is 15 if
!     ipar(5) <= 1.
!-----------------------------------------------------------------------
!     external functions used
!
real*8 distdot
!

real*8 one, zero
parameter(one=1.0D0, zero=0.0D0)
!
!     local variables, ptr and p2 are temporary pointers,
!     hess points to the Hessenberg matrix,
!     vc, vs point to the cosines and sines of the Givens rotations
!     vrn points to the vectors of residual norms, more precisely
!     the right hand side of the least square problem solved.
!
integer i,ii,idx,iz,k,m,ptr,p2,hess,vc,vs,vrn
real*8 alpha, c, s
logical lp, rp
save
!
!     check the status of the call
!
if (ipar(1).le.0) ipar(10) = 0
goto (10, 20, 30, 40, 50, 60) ipar(10)
!
!     initialization
!
if (ipar(5).le.1) then
   m = 15
else
   m = ipar(5)
endif
idx = n * (m+1)
iz = idx + n
hess = iz + n*m
vc = hess + (m+1) * m / 2 + 1
vs = vc + m
vrn = vs + m
i = vrn + m + 1
call bisinit(ipar,fpar,i,1,lp,rp,w)
if (ipar(1).lt.0) return
!
!     request for matrix vector multiplication A*x in the initialization
!
100 ipar(1) = 1
ipar(8) = n+1
ipar(9) = 1
ipar(10) = 1
k = 0
do ii = 1, n
   w(ii+n) = sol(ii)
enddo
return
10 ipar(7) = ipar(7) + 1
ipar(13) = ipar(13) + 1
fpar(11) = fpar(11) + n
if (lp) then
   do i = 1, n
      w(n+i) = rhs(i) - w(i)
   enddo
   ipar(1) = 3
   ipar(10) = 2
   return
else
   do i = 1, n
      w(i) = rhs(i) - w(i)
   enddo
endif
!
20 alpha = sqrt(distdot(n,w,1,w,1))
fpar(11) = fpar(11) + n + n
if (ipar(7).eq.1 .and. ipar(3).ne.999) then
   if (abs(ipar(3)).eq.2) then
      fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
      fpar(11) = fpar(11) + 2*n
   else
      fpar(4) = fpar(1) * alpha + fpar(2)
   endif
   fpar(3) = alpha
endif
fpar(5) = alpha
w(vrn+1) = alpha
if (alpha.le.fpar(4) .and. ipar(3).ge.0 .and. ipar(3).ne.999) then
   ipar(1) = 0
   fpar(6) = alpha
   goto 300
endif
alpha = one / alpha
do ii = 1, n
   w(ii) = w(ii) * alpha
enddo
fpar(11) = fpar(11) + n
!
!     request for (1) right preconditioning
!     (2) matrix vector multiplication
!     (3) left preconditioning
!
110 k = k + 1
if (rp) then
   ipar(1) = 5
   ipar(8) = k*n - n + 1
   ipar(9) = iz + ipar(8)
   ipar(10) = 3
   return
else
   do ii = 0, n-1
      w(iz+k*n-ii) = w(k*n-ii)
   enddo
endif
!
30 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = (k-1)*n + 1
endif
if (lp) then
   ipar(9) = idx + 1
else
   ipar(9) = 1 + k*n
endif
ipar(10) = 4
return
!
40 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = k*n + 1
   ipar(10) = 5
   return
endif
!
!     Modified Gram-Schmidt orthogonalization procedure
!     temporary pointer 'ptr' is pointing to the current column of the
!     Hessenberg matrix. 'p2' points to the new basis vector
!
50 ptr = k * (k - 1) / 2 + hess
p2 = ipar(9)
ipar(7) = ipar(7) + 1
call mgsro(.false.,n,n,k+1,k+1,fpar(11),w,w(ptr+1), &
         ipar(12))
if (ipar(12).lt.0) goto 200
!
!     apply previous Givens rotations and generate a new one to eliminate
!     the subdiagonal element.
!
p2 = ptr + 1
do i = 1, k-1
   ptr = p2
   p2 = p2 + 1
   alpha = w(ptr)
   c = w(vc+i)
   s = w(vs+i)
   w(ptr) = c * alpha + s * w(p2)
   w(p2) = c * w(p2) - s * alpha
enddo
call givens(w(p2), w(p2+1), c, s)
w(vc+k) = c
w(vs+k) = s
p2 = vrn + k
alpha = - s * w(p2)
w(p2) = c * w(p2)
w(p2+1) = alpha
fpar(11) = fpar(11) + 6 * k
!
!     end of one Arnoldi iteration, alpha will store the estimated
!     residual norm at current stage
!
alpha = abs(alpha)
fpar(5) = alpha
if (k.lt.m .and. .not.(ipar(3).ge.0 .and. alpha.le.fpar(4)) &
          .and. (ipar(6).le.0 .or. ipar(7).lt.ipar(6))) goto 110
!
!     update the approximate solution, first solve the upper triangular
!     system, temporary pointer ptr points to the Hessenberg matrix,
!     p2 points to the right-hand-side (also the solution) of the system.
!
200 ptr = hess + k * (k + 1 ) / 2
p2 = vrn + k
if (w(ptr).eq.zero) then
!
!     if the diagonal elements of the last column is zero, reduce k by 1
!     so that a smaller trianguler system is solved [It should only
!     happen when the matrix is singular!]
!
   k = k - 1
   if (k.gt.0) then
      goto 200
   else
      ipar(1) = -3
      ipar(12) = -4
      goto 300
   endif
endif
w(p2) = w(p2) / w(ptr)
do i = k-1, 1, -1
   ptr = ptr - i - 1
   do ii = 1, i
      w(vrn+ii) = w(vrn+ii) - w(p2) * w(ptr+ii)
   enddo
   p2 = p2 - 1
   w(p2) = w(p2) / w(ptr)
enddo
!
do i = 0, k-1
   ptr = iz+i*n
   do ii = 1, n
      sol(ii) = sol(ii) + w(p2)*w(ptr+ii)
   enddo
   p2 = p2 + 1
enddo
fpar(11) = fpar(11) + 2*k*n + k*(k+1)
!
!     process the complete stopping criteria
!
if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = -1
   ipar(9) = idx + 1
   ipar(10) = 6
   return
else if (ipar(3).lt.0) then
   if (ipar(7).le.m+1) then
      fpar(3) = abs(w(vrn+1))
      if (ipar(3).eq.-1) fpar(4) = fpar(1)*fpar(3)+fpar(2)
   endif
   fpar(6) = abs(w(vrn+k))
else if (ipar(3).ne.999) then
   fpar(6) = fpar(5)
endif
!
!     do we need to restart ?
!
60 if (ipar(12).ne.0) then
   ipar(1) = -3
   goto 300
endif
if ((ipar(7).lt.ipar(6) .or. ipar(6).le.0).and. &
         ((ipar(3).eq.999.and.ipar(11).eq.0) .or. &
         (ipar(3).ne.999.and.fpar(6).gt.fpar(4)))) goto 100
!
!     termination, set error code, compute convergence rate
!
if (ipar(1).gt.0) then
   if (ipar(3).eq.999 .and. ipar(11).eq.1) then
      ipar(1) = 0
   else if (ipar(3).ne.999 .and. fpar(6).le.fpar(4)) then
      ipar(1) = 0
   else if (ipar(7).ge.ipar(6) .and. ipar(6).gt.0) then
      ipar(1) = -1
   else
      ipar(1) = -10
   endif
endif
300 if (fpar(3).ne.zero .and. fpar(6).ne.zero .and. &
         ipar(7).gt.ipar(13)) then
   fpar(7) = log10(fpar(3) / fpar(6)) / dble(ipar(7)-ipar(13))
else
   fpar(7) = zero
endif
return
end subroutine fgmres

subroutine fom(n, rhs, sol, ipar, fpar, w)
implicit none
integer n, ipar(16)
real*8 rhs(n), sol(n), fpar(16), w(*)
!-----------------------------------------------------------------------
!     This a version of The Full Orthogonalization Method (FOM) 
!     implemented with reverse communication. It is a simple restart 
!     version of the FOM algorithm and is implemented with plane 
!     rotations similarly to GMRES.
!
!  parameters:
!  ----------- 
!     ipar(5) == the dimension of the Krylov subspace
!     after every ipar(5) iterations, the FOM will restart with
!     the updated solution and recomputed residual vector.
!
!     the work space in `w' is used as follows:
!     (1) the basis for the Krylov subspace, size n*(m+1);
!     (2) the Hessenberg matrix, only the upper triangular
!     portion of the matrix is stored, size (m+1)*m/2 + 1
!     (3) three vectors, all are of size m, they are
!     the cosine and sine of the Givens rotations, the third one holds
!     the residuals, it is of size m+1.
!
!     TOTAL SIZE REQUIRED == (n+3)*(m+2) + (m+1)*m/2
!     Note: m == ipar(5). The default value for this is 15 if
!     ipar(5) <= 1.
!-----------------------------------------------------------------------
!     external functions used
!
real*8 distdot
!

real*8 one, zero
parameter(one=1.0D0, zero=0.0D0)
!
!     local variables, ptr and p2 are temporary pointers,
!     hes points to the Hessenberg matrix,
!     vc, vs point to the cosines and sines of the Givens rotations
!     vrn points to the vectors of residual norms, more precisely
!     the right hand side of the least square problem solved.
!
integer i,ii,idx,k,m,ptr,p2,prs,hes,vc,vs,vrn
real*8 alpha, c, s
logical lp, rp
save
!
!     check the status of the call
!
if (ipar(1).le.0) ipar(10) = 0
goto (10, 20, 30, 40, 50, 60, 70) ipar(10)
!
!     initialization
!
if (ipar(5).le.1) then
   m = 15
else
   m = ipar(5)
endif
idx = n * (m+1)
hes = idx + n
vc = hes + (m+1) * m / 2 + 1
vs = vc + m
vrn = vs + m
i = vrn + m + 1
call bisinit(ipar,fpar,i,1,lp,rp,w)
if (ipar(1).lt.0) return
!
!     request for matrix vector multiplication A*x in the initialization
!
100 ipar(1) = 1
ipar(8) = n+1
ipar(9) = 1
ipar(10) = 1
k = 0
do i = 1, n
   w(n+i) = sol(i)
enddo
return
10 ipar(7) = ipar(7) + 1
ipar(13) = ipar(13) + 1
if (lp) then
   do i = 1, n
      w(n+i) = rhs(i) - w(i)
   enddo
   ipar(1) = 3
   ipar(10) = 2
   return
else
   do i = 1, n
      w(i) = rhs(i) - w(i)
   enddo
endif
fpar(11) = fpar(11) + n
!
20 alpha = sqrt(distdot(n,w,1,w,1))
fpar(11) = fpar(11) + 2*n + 1
if (ipar(7).eq.1 .and. ipar(3).ne.999) then
   if (abs(ipar(3)).eq.2) then
      fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
      fpar(11) = fpar(11) + 2*n
   else
      fpar(4) = fpar(1) * alpha + fpar(2)
   endif
   fpar(3) = alpha
endif
fpar(5) = alpha
w(vrn+1) = alpha
if (alpha.le.fpar(4) .and. ipar(3).ge.0 .and. ipar(3).ne.999) then
   ipar(1) = 0
   fpar(6) = alpha
   goto 300
endif
alpha = one / alpha
do ii = 1, n
   w(ii) = alpha * w(ii)
enddo
fpar(11) = fpar(11) + n
!
!     request for (1) right preconditioning
!     (2) matrix vector multiplication
!     (3) left preconditioning
!
110 k = k + 1
if (rp) then
   ipar(1) = 5
   ipar(8) = k*n - n + 1
   if (lp) then
      ipar(9) = k*n + 1
   else
      ipar(9) = idx + 1
   endif
   ipar(10) = 3
   return
endif
!
30 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = (k-1)*n + 1
endif
if (lp) then
   ipar(9) = idx + 1
else
   ipar(9) = 1 + k*n
endif
ipar(10) = 4
return
!
40 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = k*n + 1
   ipar(10) = 5
   return
endif
!
!     Modified Gram-Schmidt orthogonalization procedure
!     temporary pointer 'ptr' is pointing to the current column of the
!     Hessenberg matrix. 'p2' points to the new basis vector
!
50 ipar(7) = ipar(7) + 1
ptr = k * (k - 1) / 2 + hes
p2 = ipar(9)
call mgsro(.false.,n,n,k+1,k+1,fpar(11),w,w(ptr+1), &
         ipar(12))
if (ipar(12).lt.0) goto 200
!
!     apply previous Givens rotations to column.
!
p2 = ptr + 1
do i = 1, k-1
   ptr = p2
   p2 = p2 + 1
   alpha = w(ptr)
   c = w(vc+i)
   s = w(vs+i)
   w(ptr) = c * alpha + s * w(p2)
   w(p2) = c * w(p2) - s * alpha
enddo
!
!     end of one Arnoldi iteration, alpha will store the estimated
!     residual norm at current stage
!
fpar(11) = fpar(11) + 6*k

prs = vrn+k
alpha = fpar(5)
if (w(p2) .ne. zero) alpha = abs(w(p2+1)*w(prs)/w(p2))
fpar(5) = alpha
!
if (k.ge.m .or. (ipar(3).ge.0 .and. alpha.le.fpar(4)) &
         .or. (ipar(6).gt.0 .and. ipar(7).ge.ipar(6))) &
         goto 200
!
call givens(w(p2), w(p2+1), c, s)
w(vc+k) = c
w(vs+k) = s
alpha = - s * w(prs)
w(prs) = c * w(prs)
w(prs+1) = alpha
!
if (w(p2).ne.zero) goto 110
!
!     update the approximate solution, first solve the upper triangular
!     system, temporary pointer ptr points to the Hessenberg matrix,
!     prs points to the right-hand-side (also the solution) of the system.
!
200 ptr = hes + k * (k + 1) / 2
prs = vrn + k
if (w(ptr).eq.zero) then
!
!     if the diagonal elements of the last column is zero, reduce k by 1
!     so that a smaller trianguler system is solved
!
   k = k - 1
   if (k.gt.0) then
      goto 200
   else
      ipar(1) = -3
      ipar(12) = -4
      goto 300
   endif
endif
w(prs) = w(prs) / w(ptr)
do i = k-1, 1, -1
   ptr = ptr - i - 1
   do ii = 1, i
      w(vrn+ii) = w(vrn+ii) - w(prs) * w(ptr+ii)
   enddo
   prs = prs - 1
   w(prs) = w(prs) / w(ptr)
enddo
!
do ii = 1, n
   w(ii) = w(ii) * w(prs)
enddo
do i = 1, k-1
   prs = prs + 1
   ptr = i*n
   do ii = 1, n
      w(ii) = w(ii) + w(prs) * w(ptr+ii)
   enddo
enddo
fpar(11) = fpar(11) + 2*(k-1)*n + n + k*(k+1)
!
if (rp) then
   ipar(1) = 5
   ipar(8) = 1
   ipar(9) = idx + 1
   ipar(10) = 6
   return
endif
!
60 if (rp) then
   do i = 1, n
      sol(i) = sol(i) + w(idx+i)
   enddo
else
   do i = 1, n
      sol(i) = sol(i) + w(i)
   enddo
endif
fpar(11) = fpar(11) + n
!
!     process the complete stopping criteria
!
if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = -1
   ipar(9) = idx + 1
   ipar(10) = 7
   return
else if (ipar(3).lt.0) then
   if (ipar(7).le.m+1) then
      fpar(3) = abs(w(vrn+1))
      if (ipar(3).eq.-1) fpar(4) = fpar(1)*fpar(3)+fpar(2)
   endif
   alpha = abs(w(vrn+k))
endif
fpar(6) = alpha
!
!     do we need to restart ?
!
70 if (ipar(12).ne.0) then
   ipar(1) = -3
   goto 300
endif
if (ipar(7).lt.ipar(6) .or. ipar(6).le.0) then
   if (ipar(3).ne.999) then
      if (fpar(6).gt.fpar(4)) goto 100
   else
      if (ipar(11).eq.0) goto 100
   endif
endif
!
!     termination, set error code, compute convergence rate
!
if (ipar(1).gt.0) then
   if (ipar(3).eq.999 .and. ipar(11).eq.1) then
      ipar(1) = 0
   else if (ipar(3).ne.999 .and. fpar(6).le.fpar(4)) then
      ipar(1) = 0
   else if (ipar(7).ge.ipar(6) .and. ipar(6).gt.0) then
      ipar(1) = -1
   else
      ipar(1) = -10
   endif
endif
300 if (fpar(3).ne.zero .and. fpar(6).ne.zero .and. &
         ipar(7).gt.ipar(13)) then
   fpar(7) = log10(fpar(3) / fpar(6)) / dble(ipar(7)-ipar(13))
else
   fpar(7) = zero
endif
return
end subroutine fom

subroutine givens(x,y,c,s)
real*8 x,y,c,s
!-----------------------------------------------------------------------
!     Given x and y, this subroutine generates a Givens' rotation c, s.
!     And apply the rotation on (x,y) ==> (sqrt(x**2 + y**2), 0).
!     (See P 202 of "matrix computation" by Golub and van Loan.)
!-----------------------------------------------------------------------
real*8 t,one,zero
parameter (zero=0.0D0,one=1.0D0)
!
if (x.eq.zero .and. y.eq.zero) then
   c = one
   s = zero
else if (abs(y).gt.abs(x)) then
   t = x / y
   x = sqrt(one+t*t)
   s = sign(one / x, y)
   c = t*s
else if (abs(y).le.abs(x)) then
   t = y / x
   y = sqrt(one+t*t)
   c = sign(one / y, x)
   s = t*c
else
!
!     X or Y must be an invalid floating-point number, set both to zero
!
   x = zero
   y = zero
   c = one
   s = zero
endif
x = abs(x*y)
!
!     end of givens
!
return
end subroutine givens

subroutine gmres(n, rhs, sol, ipar, fpar, w)
implicit none
integer n, ipar(16)
real*8 rhs(n), sol(n), fpar(16), w(*)
!-----------------------------------------------------------------------
!     This a version of GMRES implemented with reverse communication.
!     It is a simple restart version of the GMRES algorithm.
!
!     ipar(5) == the dimension of the Krylov subspace
!     after every ipar(5) iterations, the GMRES will restart with
!     the updated solution and recomputed residual vector.
!
!     the space of the `w' is used as follows:
!     (1) the basis for the Krylov subspace, size n*(m+1);
!     (2) the Hessenberg matrix, only the upper triangular
!     portion of the matrix is stored, size (m+1)*m/2 + 1
!     (3) three vectors, all are of size m, they are
!     the cosine and sine of the Givens rotations, the third one holds
!     the residuals, it is of size m+1.
!
!     TOTAL SIZE REQUIRED == (n+3)*(m+2) + (m+1)*m/2
!     Note: m == ipar(5). The default value for this is 15 if
!     ipar(5) <= 1.
!-----------------------------------------------------------------------
!     external functions used
!
real*8 distdot
!

real*8 one, zero
parameter(one=1.0D0, zero=0.0D0)
!
!     local variables, ptr and p2 are temporary pointers,
!     hess points to the Hessenberg matrix,
!     vc, vs point to the cosines and sines of the Givens rotations
!     vrn points to the vectors of residual norms, more precisely
!     the right hand side of the least square problem solved.
!
integer i,ii,idx,k,m,ptr,p2,hess,vc,vs,vrn
real*8 alpha, c, s
logical lp, rp
save
!
!     check the status of the call
!
if (ipar(1).le.0) ipar(10) = 0
goto (10, 20, 30, 40, 50, 60, 70) ipar(10)
!
!     initialization
!
if (ipar(5).le.1) then
   m = 15
else
   m = ipar(5)
endif
idx = n * (m+1)
hess = idx + n
vc = hess + (m+1) * m / 2 + 1
vs = vc + m
vrn = vs + m
i = vrn + m + 1
call bisinit(ipar,fpar,i,1,lp,rp,w)
if (ipar(1).lt.0) return
!
!     request for matrix vector multiplication A*x in the initialization
!
100 ipar(1) = 1
ipar(8) = n+1
ipar(9) = 1
ipar(10) = 1
k = 0
do i = 1, n
   w(n+i) = sol(i)
enddo
return
10 ipar(7) = ipar(7) + 1
ipar(13) = ipar(13) + 1
if (lp) then
   do i = 1, n
      w(n+i) = rhs(i) - w(i)
   enddo
   ipar(1) = 3
   ipar(10) = 2
   return
else
   do i = 1, n
      w(i) = rhs(i) - w(i)
   enddo
endif
fpar(11) = fpar(11) + n
!
20 alpha = sqrt(distdot(n,w,1,w,1))
fpar(11) = fpar(11) + 2*n
if (ipar(7).eq.1 .and. ipar(3).ne.999) then
   if (abs(ipar(3)).eq.2) then
      fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
      fpar(11) = fpar(11) + 2*n
   else
      fpar(4) = fpar(1) * alpha + fpar(2)
   endif
   fpar(3) = alpha
endif
fpar(5) = alpha
w(vrn+1) = alpha
if (alpha.le.fpar(4) .and. ipar(3).ge.0 .and. ipar(3).ne.999) then
   ipar(1) = 0
   fpar(6) = alpha
   goto 300
endif
alpha = one / alpha
do ii = 1, n
   w(ii) = alpha * w(ii)
enddo
fpar(11) = fpar(11) + n
!
!     request for (1) right preconditioning
!     (2) matrix vector multiplication
!     (3) left preconditioning
!
110 k = k + 1
if (rp) then
   ipar(1) = 5
   ipar(8) = k*n - n + 1
   if (lp) then
      ipar(9) = k*n + 1
   else
      ipar(9) = idx + 1
   endif
   ipar(10) = 3
   return
endif
!
30 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = (k-1)*n + 1
endif
if (lp) then
   ipar(9) = idx + 1
else
   ipar(9) = 1 + k*n
endif
ipar(10) = 4
return
!
40 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = k*n + 1
   ipar(10) = 5
   return
endif
!
!     Modified Gram-Schmidt orthogonalization procedure
!     temporary pointer 'ptr' is pointing to the current column of the
!     Hessenberg matrix. 'p2' points to the new basis vector
!
50 ipar(7) = ipar(7) + 1
ptr = k * (k - 1) / 2 + hess
p2 = ipar(9)
call mgsro(.false.,n,n,k+1,k+1,fpar(11),w,w(ptr+1), &
         ipar(12))
if (ipar(12).lt.0) goto 200
!
!     apply previous Givens rotations and generate a new one to eliminate
!     the subdiagonal element.
!
p2 = ptr + 1
do i = 1, k-1
   ptr = p2
   p2 = p2 + 1
   alpha = w(ptr)
   c = w(vc+i)
   s = w(vs+i)
   w(ptr) = c * alpha + s * w(p2)
   w(p2) = c * w(p2) - s * alpha
enddo
call givens(w(p2), w(p2+1), c, s)
w(vc+k) = c
w(vs+k) = s
p2 = vrn + k
alpha = - s * w(p2)
w(p2) = c * w(p2)
w(p2+1) = alpha
!
!     end of one Arnoldi iteration, alpha will store the estimated
!     residual norm at current stage
!
fpar(11) = fpar(11) + 6*k + 2
alpha = abs(alpha)
fpar(5) = alpha
if (k.lt.m .and. .not.(ipar(3).ge.0 .and. alpha.le.fpar(4)) &
         .and. (ipar(6).le.0 .or. ipar(7).lt.ipar(6))) goto 110
!
!     update the approximate solution, first solve the upper triangular
!     system, temporary pointer ptr points to the Hessenberg matrix,
!     p2 points to the right-hand-side (also the solution) of the system.
!
200 ptr = hess + k * (k + 1) / 2
p2 = vrn + k
if (w(ptr).eq.zero) then
!
!     if the diagonal elements of the last column is zero, reduce k by 1
!     so that a smaller trianguler system is solved [It should only
!     happen when the matrix is singular, and at most once!]
!
   k = k - 1
   if (k.gt.0) then
      goto 200
   else
      ipar(1) = -3
      ipar(12) = -4
      goto 300
   endif
endif
w(p2) = w(p2) / w(ptr)
do i = k-1, 1, -1
   ptr = ptr - i - 1
   do ii = 1, i
      w(vrn+ii) = w(vrn+ii) - w(p2) * w(ptr+ii)
   enddo
   p2 = p2 - 1
   w(p2) = w(p2) / w(ptr)
enddo
!
do ii = 1, n
   w(ii) = w(ii) * w(p2)
enddo
do i = 1, k-1
   ptr = i*n
   p2 = p2 + 1
   do ii = 1, n
      w(ii) = w(ii) + w(p2) * w(ptr+ii)
   enddo
enddo
fpar(11) = fpar(11) + 2*k*n - n + k*(k+1)
!
if (rp) then
   ipar(1) = 5
   ipar(8) = 1
   ipar(9) = idx + 1
   ipar(10) = 6
   return
endif
!
60 if (rp) then
   do i = 1, n
      sol(i) = sol(i) + w(idx+i)
   enddo
else
   do i = 1, n
      sol(i) = sol(i) + w(i)
   enddo
endif
fpar(11) = fpar(11) + n
!
!     process the complete stopping criteria
!
if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = -1
   ipar(9) = idx + 1
   ipar(10) = 7
   return
else if (ipar(3).lt.0) then
   if (ipar(7).le.m+1) then
      fpar(3) = abs(w(vrn+1))
      if (ipar(3).eq.-1) fpar(4) = fpar(1)*fpar(3)+fpar(2)
   endif
   fpar(6) = abs(w(vrn+k))
else
   fpar(6) = fpar(5)
endif
!
!     do we need to restart ?
!
70 if (ipar(12).ne.0) then
   ipar(1) = -3
   goto 300
endif
if ((ipar(7).lt.ipar(6) .or. ipar(6).le.0) .and. &
         ((ipar(3).eq.999.and.ipar(11).eq.0) .or. &
         (ipar(3).ne.999.and.fpar(6).gt.fpar(4)))) goto 100
!
!     termination, set error code, compute convergence rate
!
if (ipar(1).gt.0) then
   if (ipar(3).eq.999 .and. ipar(11).eq.1) then
      ipar(1) = 0
   else if (ipar(3).ne.999 .and. fpar(6).le.fpar(4)) then
      ipar(1) = 0
   else if (ipar(7).ge.ipar(6) .and. ipar(6).gt.0) then
      ipar(1) = -1
   else
      ipar(1) = -10
   endif
endif
300 if (fpar(3).ne.zero .and. fpar(6).ne.zero .and. &
         ipar(7).gt.ipar(13)) then
   fpar(7) = log10(fpar(3) / fpar(6)) / dble(ipar(7)-ipar(13))
else
   fpar(7) = zero
endif
return
end subroutine gmres

subroutine implu(np,umm,beta,ypiv,u,permut,full)
real*8 umm,beta,ypiv(*),u(*),x, xpiv
logical full, perm, permut(*)
integer np,k,npm1
!-----------------------------------------------------------------------
!     performs implicitly one step of the lu factorization of a
!     banded hessenberg matrix.
!-----------------------------------------------------------------------
if (np .le. 1) goto 12
npm1 = np - 1
!
!     -- perform  previous step of the factorization-
!
do 6 k=1,npm1
   if (.not. permut(k)) goto 5
   x=u(k)
   u(k) = u(k+1)
   u(k+1) = x
5    u(k+1) = u(k+1) - ypiv(k)*u(k)
6 continue
!-----------------------------------------------------------------------
!     now determine pivotal information to be used in the next call
!-----------------------------------------------------------------------
12 umm = u(np)
perm = (beta .gt. abs(umm))
if (.not. perm) goto 4
xpiv = umm / beta
u(np) = beta
goto 8
4 xpiv = beta/umm
8 permut(np) = perm
ypiv(np) = xpiv
if (.not. full) return
!     shift everything up if full...
do 7 k=1,npm1
   ypiv(k) = ypiv(k+1)
   permut(k) = permut(k+1)
7 continue
return
!-----end-of-implu
end subroutine implu

subroutine mgsro(full,lda,n,m,ind,ops,vec,hh,ierr)
implicit none
logical full
integer lda,m,n,ind,ierr
real*8  ops,hh(m),vec(lda,m)
!-----------------------------------------------------------------------
!     MGSRO  -- Modified Gram-Schmidt procedure with Selective Re-
!               Orthogonalization
!     The ind'th vector of VEC is orthogonalized against the rest of
!     the vectors.
!
!     The test for performing re-orthogonalization is performed for
!     each indivadual vectors. If the cosine between the two vectors
!     is greater than 0.99 (REORTH = 0.99**2), re-orthogonalization is
!     performed. The norm of the 'new' vector is kept in variable NRM0,
!     and updated after operating with each vector.
!
!     full   -- .ture. if it is necessary to orthogonalize the ind'th
!               against all the vectors vec(:,1:ind-1), vec(:,ind+2:m)
!               .false. only orthogonalize againt vec(:,1:ind-1)
!     lda    -- the leading dimension of VEC
!     n      -- length of the vector in VEC
!     m      -- number of vectors can be stored in VEC
!     ind    -- index to the vector to be changed
!     ops    -- operation counts
!     vec    -- vector of LDA X M storing the vectors
!     hh     -- coefficient of the orthogonalization
!     ierr   -- error code
!               0 : successful return
!               -1: zero input vector
!               -2: input vector contains abnormal numbers
!               -3: input vector is a linear combination of others
!
!     External routines used: real*8 distdot
!-----------------------------------------------------------------------
integer i,k
real*8  nrm0, nrm1, fct, thr, distdot, zero, one, reorth
parameter (zero=0.0D0, one=1.0D0, reorth=0.98D0)
!

!     compute the norm of the input vector
!
nrm0 = distdot(n,vec(1,ind),1,vec(1,ind),1)
ops = ops + n + n
thr = nrm0 * reorth
if (nrm0.le.zero) then
   ierr = - 1
   return
else if (nrm0.gt.zero .and. one/nrm0.gt.zero) then
   ierr = 0
else
   ierr = -2
   return
endif
!
!     Modified Gram-Schmidt loop
!
if (full) then
   do 40 i = ind+1, m
      fct = distdot(n,vec(1,ind),1,vec(1,i),1)
      hh(i) = fct
      do 20 k = 1, n
         vec(k,ind) = vec(k,ind) - fct * vec(k,i)
20       continue
      ops = ops + 4 * n + 2
      if (fct*fct.gt.thr) then
         fct = distdot(n,vec(1,ind),1,vec(1,i),1)
         hh(i) = hh(i) + fct
         do 30 k = 1, n
            vec(k,ind) = vec(k,ind) - fct * vec(k,i)
30          continue
         ops = ops + 4*n + 1
      endif
      nrm0 = nrm0 - hh(i) * hh(i)
      if (nrm0.lt.zero) nrm0 = zero
      thr = nrm0 * reorth
40    continue
endif
!
do 70 i = 1, ind-1
   fct = distdot(n,vec(1,ind),1,vec(1,i),1)
   hh(i) = fct
   do 50 k = 1, n
      vec(k,ind) = vec(k,ind) - fct * vec(k,i)
50    continue
   ops = ops + 4 * n + 2
   if (fct*fct.gt.thr) then
      fct = distdot(n,vec(1,ind),1,vec(1,i),1)
      hh(i) = hh(i) + fct
      do 60 k = 1, n
         vec(k,ind) = vec(k,ind) - fct * vec(k,i)
60       continue
      ops = ops + 4*n + 1
   endif
   nrm0 = nrm0 - hh(i) * hh(i)
   if (nrm0.lt.zero) nrm0 = zero
   thr = nrm0 * reorth
70 continue
!
!     test the resulting vector
!
nrm1 = sqrt(distdot(n,vec(1,ind),1,vec(1,ind),1))
ops = ops + n + n
75 hh(ind) = nrm1
if (nrm1.le.zero) then
   ierr = -3
   return
endif
!
!     scale the resulting vector
!
fct = one / nrm1
do 80 k = 1, n
   vec(k,ind) = vec(k,ind) * fct
80 continue
ops = ops + n + 1
!
!     normal return
!
ierr = 0
return
!     end surbotine mgsro
end subroutine mgsro

 subroutine pgmres(n, im, rhs, sol, vv, eps, maxits, iout, &
                        aa, ja, ia, alu, jlu, ju, ierr)
!-----------------------------------------------------------------------
 implicit real*8 (a-h,o-z)
 integer n, im, maxits, iout, ierr, ja(*), ia(n+1), jlu(*), ju(n)
 real*8 vv(n,*), rhs(n), sol(n), aa(*), alu(*), eps
!----------------------------------------------------------------------*
!                                                                      *
!                 *** ILUT - Preconditioned GMRES ***                  *
!                                                                      *
!----------------------------------------------------------------------*
! This is a simple version of the ILUT preconditioned GMRES algorithm. *
! The ILUT preconditioner uses a dual strategy for dropping elements   *
! instead  of the usual level of-fill-in approach. See details in ILUT *
! subroutine documentation. PGMRES uses the L and U matrices generated *
! from the subroutine ILUT to precondition the GMRES algorithm.        *
! The preconditioning is applied to the right. The stopping criterion  *
! utilized is based simply on reducing the residual norm by epsilon.   *
! This preconditioning is more reliable than ilu0 but requires more    *
! storage. It seems to be much less prone to difficulties related to   *
! strong nonsymmetries in the matrix. We recommend using a nonzero tol *
! (tol=.005 or .001 usually give good results) in ILUT. Use a large    *
! lfil whenever possible (e.g. lfil = 5 to 10). The higher lfil the    *
! more reliable the code is. Efficiency may also be much improved.     *
! Note that lfil=n and tol=0.0 in ILUT  will yield the same factors as *
! Gaussian elimination without pivoting.                               *
!                                                                      *
! ILU(0) and MILU(0) are also provided for comparison purposes         *
! USAGE: first call ILUT or ILU0 or MILU0 to set up preconditioner and *
! then call pgmres.                                                    *
!----------------------------------------------------------------------*
! Coded by Y. Saad - This version dated May, 7, 1990.                  *
!----------------------------------------------------------------------*
! parameters                                                           *
!-----------                                                           *
! on entry:                                                            *
!==========                                                            *
!                                                                      *
! n     == integer. The dimension of the matrix.                       *
! im    == size of krylov subspace:  should not exceed 50 in this      *
!          version (can be reset by changing parameter command for     *
!          kmax below)                                                 *
! rhs   == real vector of length n containing the right hand side.     *
!          Destroyed on return.                                        *
! sol   == real vector of length n containing an initial guess to the  *
!          solution on input. approximate solution on output           *
! eps   == tolerance for stopping criterion. process is stopped        *
!          as soon as ( ||.|| is the euclidean norm):                  *
!          || current residual||/||initial residual|| <= eps           *
! maxits== maximum number of iterations allowed                        *
! iout  == output unit number number for printing intermediate results *
!          if (iout .le. 0) nothing is printed out.                    *
!                                                                      *
! aa, ja,                                                              *
! ia    == the input matrix in compressed sparse row format:           *
!          aa(1:nnz)  = nonzero elements of A stored row-wise in order *
!          ja(1:nnz) = corresponding column indices.                   *
!          ia(1:n+1) = pointer to beginning of each row in aa and ja.  *
!          here nnz = number of nonzero elements in A = ia(n+1)-ia(1)  *
!                                                                      *
! alu,jlu== A matrix stored in Modified Sparse Row format containing   *
!           the L and U factors, as computed by subroutine ilut.       *
!                                                                      *
! ju     == integer array of length n containing the pointers to       *
!           the beginning of each row of U in alu, jlu as computed     *
!           by subroutine ILUT.                                        *
!                                                                      *
! on return:                                                           *
!==========                                                            *
! sol   == contains an approximate solution (upon successful return).  *
! ierr  == integer. Error message with the following meaning.          *
!          ierr = 0 --> successful return.                             *
!          ierr = 1 --> convergence not achieved in itmax iterations.  *
!          ierr =-1 --> the initial guess seems to be the exact        *
!                       solution (initial residual computed was zero)  *
!                                                                      *
!----------------------------------------------------------------------*
!                                                                      *
! work arrays:                                                         *
!=============                                                         *
! vv    == work array of length  n x (im+1) (used to store the Arnoli  *
!          basis)                                                      *
!----------------------------------------------------------------------*
! subroutines called :                                                 *
! amux   : SPARSKIT routine to do the matrix by vector multiplication  *
!          delivers y=Ax, given x  -- see SPARSKIT/BLASSM/amux         *
! lusol : combined forward and backward solves (Preconditioning ope.) *
! BLAS1  routines.                                                     *
!----------------------------------------------------------------------*
 parameter (kmax=50)
 real*8 hh(kmax+1,kmax), c(kmax), s(kmax), rs(kmax+1),t
!-------------------------------------------------------------
! arnoldi size should not exceed kmax=50 in this version..
! to reset modify paramter kmax accordingly.
!-------------------------------------------------------------
 data epsmac/1.d-16/
 n1 = n + 1
 its = 0
!-------------------------------------------------------------
! outer loop starts here..
!-------------- compute initial residual vector --------------
 call amux (n, sol, vv, aa, ja, ia)
 do 21 j=1,n
    vv(j,1) = rhs(j) - vv(j,1)
21  continue
!-------------------------------------------------------------
20  ro = dnrm2(n, vv, 1)
 if (iout .gt. 0 .and. its .eq. 0) &
          write(iout, 199) its, ro
 if (ro .eq. 0.0d0) goto 999
 t = 1.0d0/ ro
 do 210 j=1, n
    vv(j,1) = vv(j,1)*t
210  continue
 if (its .eq. 0) eps1=eps*ro
!     ** initialize 1-st term  of rhs of hessenberg system..
 rs(1) = ro
 i = 0
4  i=i+1
 its = its + 1
 i1 = i + 1
 call lusol (n, vv(1,i), rhs, alu, jlu, ju)
 call amux (n, rhs, vv(1,i1), aa, ja, ia)
!-----------------------------------------
!     modified gram - schmidt...
!-----------------------------------------
 do 55 j=1, i
    t = ddot(n, vv(1,j),1,vv(1,i1),1)
    hh(j,i) = t
    call daxpy(n, -t, vv(1,j), 1, vv(1,i1), 1)
55  continue
 t = dnrm2(n, vv(1,i1), 1)
 hh(i1,i) = t
 if ( t .eq. 0.0d0) goto 58
 t = 1.0d0/t
 do 57  k=1,n
    vv(k,i1) = vv(k,i1)*t
57  continue
!
!     done with modified gram schimd and arnoldi step..
!     now  update factorization of hh
!
58  if (i .eq. 1) goto 121
!--------perfrom previous transformations  on i-th column of h
 do 66 k=2,i
    k1 = k-1
    t = hh(k1,i)
    hh(k1,i) = c(k1)*t + s(k1)*hh(k,i)
    hh(k,i) = -s(k1)*t + c(k1)*hh(k,i)
66  continue
121  gam = sqrt(hh(i,i)**2 + hh(i1,i)**2)
!
!     if gamma is zero then any small value will do...
!     will affect only residual estimate
!
 if (gam .eq. 0.0d0) gam = epsmac
!
!     get  next plane rotation
!
 c(i) = hh(i,i)/gam
 s(i) = hh(i1,i)/gam
 rs(i1) = -s(i)*rs(i)
 rs(i) =  c(i)*rs(i)
!
!     detrermine residual norm and test for convergence-
!
 hh(i,i) = c(i)*hh(i,i) + s(i)*hh(i1,i)
 ro = abs(rs(i1))
131  format(1h ,2e14.4)
 if (iout .gt. 0) &
          write(iout, 199) its, ro
 if (i .lt. im .and. (ro .gt. eps1))  goto 4
!
!     now compute solution. first solve upper triangular system.
!
 rs(i) = rs(i)/hh(i,i)
 do 30 ii=2,i
    k=i-ii+1
    k1 = k+1
    t=rs(k)
    do 40 j=k1,i
       t = t-hh(k,j)*rs(j)
40     continue
    rs(k) = t/hh(k,k)
30  continue
!
!     form linear combination of v(*,i)'s to get solution
!
 t = rs(1)
 do 15 k=1, n
    rhs(k) = vv(k,1)*t
15  continue
 do 16 j=2, i
    t = rs(j)
    do 161 k=1, n
       rhs(k) = rhs(k)+t*vv(k,j)
161     continue
16  continue
!
!     call preconditioner.
!
 call lusol (n, rhs, rhs, alu, jlu, ju)
 do 17 k=1, n
    sol(k) = sol(k) + rhs(k)
17  continue
!
!     restart outer loop  when necessary
!
 if (ro .le. eps1) goto 990
 if (its .ge. maxits) goto 991
!
!     else compute residual vector and continue..
!
 do 24 j=1,i
    jj = i1-j+1
    rs(jj-1) = -s(jj-1)*rs(jj)
    rs(jj) = c(jj-1)*rs(jj)
24  continue
 do 25  j=1,i1
    t = rs(j)
    if (j .eq. 1)  t = t-1.0d0
    call daxpy (n, t, vv(1,j), 1,  vv, 1)
25  continue
199  format('   its =', i4, ' res. norm =', d20.6)
!     restart outer loop.
 goto 20
990  ierr = 0
 return
991  ierr = 1
 return
999  continue
 ierr = -1
 return
!-----------------end of pgmres ---------------------------------------
!-----------------------------------------------------------------------
end subroutine pgmres

subroutine SLVRC(n,rhs,sol,ipar,fpar,wk,guess,a,ja,ia, &
         au,jau,ju,solver,iou)
implicit none
integer n,ipar(16),ia(n+1),ja(*),ju(*),jau(*)
real*8 fpar(16),rhs(n),sol(n),guess(n),wk(*),a(*),au(*)
external solver
!-----------------------------------------------------------------------
!     the actual tester. It starts the iterative linear system solvers
!     with a initial guess suppied by the user.
!
!     The structure {au, jau, ju} is assumed to have the output from
!     the ILU* routines in ilut.f.
!
!-----------------------------------------------------------------------
!     local variables
!
integer i, iou, its
real*8 res
!     real dtime, dt(2), time
!     external dtime
!     dnrm2 is now from ModuleBlas via USE
save its,res
!
!     ipar(2) can be 0, 1, 2, please don't use 3
!
if (ipar(2).gt.2) then
   print *, 'I can not do both left and right preconditioning.'
   return
endif
!
!     normal execution
!
its = 0
res = 0.0D0
!
do i = 1, n
   sol(i) = guess(i)
enddo
!
!      iou = 6
ipar(1) = 0
!     time = dtime(dt)
10 call solver(n,rhs,sol,ipar,fpar,wk)
!
!     output the residuals
!
if (ipar(7).ne.its) then
if(MOD(ipar(7),500).eq.0)then  !!
   write (iou, *) its, real(res) !!!
endif
   its = ipar(7)
endif
res = fpar(5)
!
if (ipar(1).eq.1) then
   call amux(n, wk(ipar(8)), wk(ipar(9)), a, ja, ia)
   goto 10
else if (ipar(1).eq.2) then
   call atmux(n, wk(ipar(8)), wk(ipar(9)), a, ja, ia)
   goto 10
else if (ipar(1).eq.3 .or. ipar(1).eq.5) then
   call lusol(n,wk(ipar(8)),wk(ipar(9)),au,jau,ju)
   goto 10
else if (ipar(1).eq.4 .or. ipar(1).eq.6) then
   call lutsol(n,wk(ipar(8)),wk(ipar(9)),au,jau,ju)
   goto 10
else if (ipar(1).le.0) then
!         if (ipar(1).eq.0) then
!            print *, 'Iterative sovler has satisfied convergence test.'
!         else if (ipar(1).eq.-1) then
!            print *, 'Iterative solver has iterated too many times.'
!         else if (ipar(1).eq.-2) then
!            print *, 'Iterative solver was not given enough work space.'
!            print *, 'The work space should at least have ', ipar(4),
!     &           ' elements.'
!         else if (ipar(1).eq.-3) then
!            print *, 'Iterative sovler is facing a break-down.'
!         else
!            print *, 'Iterative solver terminated. code =', ipar(1)
!         endif
endif

write (iou, *) ipar(7), real(fpar(6))
write (iou, *) '# retrun code =', ipar(1), &
         '    convergence rate =', fpar(7)
!     write (iou, *) '# total execution time (sec)', time
!
!     check the error
!
call amux(n,sol,wk,a,ja,ia)
do i = 1, n
   wk(i) = wk(i) - rhs(i)
enddo
!      if(MOD(ipar(7),500).eq.0)then  !!
write (iou, *) '# the actual residual norm is', dnrm2(n,wk,1) !!
write (iou, *) '# the error norm is', dnrm2(n,wk(1+n),1)      !!
!      endif !!
!
!      if (iou.ne.6) close(iou)
return
end subroutine slvrc

subroutine tfqmr(n, rhs, sol, ipar, fpar, w)
implicit none
integer n, ipar(16)
real*8 rhs(n), sol(n), fpar(16), w(n,*)
!-----------------------------------------------------------------------
!     TFQMR --- transpose-free Quasi-Minimum Residual method
!     This is developed from BCG based on the principle of Quasi-Minimum
!     Residual, and it is transpose-free.
!
!     It uses approximate residual norm.
!
!     Internally, the fpar's are used as following:
!     fpar(3) --- initial residual norm squared
!     fpar(4) --- target residual norm squared
!     fpar(5) --- current residual norm squared
!
!     w(:,1) -- R, residual
!     w(:,2) -- R0, the initial residual
!     w(:,3) -- W
!     w(:,4) -- Y
!     w(:,5) -- Z
!     w(:,6) -- A * Y
!     w(:,7) -- A * Z
!     w(:,8) -- V
!     w(:,9) -- D
!     w(:,10) -- intermediate results of preconditioning
!     w(:,11) -- changes in the solution
!-----------------------------------------------------------------------
!     external functions
!
real*8 distdot
logical stopbis, brkdn
!

real*8 one,zero
parameter(one=1.0D0,zero=0.0D0)
!
!     local variables
!
integer i
logical lp, rp
real*8 eta,sigma,theta,te,alpha,rho,tao
save
!
!     status of the call (where to go)
!
if (ipar(1).le.0) ipar(10) = 0
goto (10,20,40,50,60,70,80,90,100,110), ipar(10)
!
!     initializations
!
call bisinit(ipar,fpar,11*n,2,lp,rp,w)
if (ipar(1).lt.0) return
ipar(1) = 1
ipar(8) = 1
ipar(9) = 1 + 6*n
do i = 1, n
   w(i,1) = sol(i)
enddo
ipar(10) = 1
return
10 ipar(7) = ipar(7) + 1
ipar(13) = ipar(13) + 1
do i = 1, n
   w(i,1) = rhs(i) - w(i,7)
   w(i,9) = zero
enddo
fpar(11) = fpar(11) + n
!
if (lp) then
   ipar(1) = 3
   ipar(9) = n+1
   ipar(10) = 2
   return
endif
20 continue
if (lp) then
   do i = 1, n
      w(i,1) = w(i,2)
      w(i,3) = w(i,2)
   enddo
else
   do i = 1, n
      w(i,2) = w(i,1)
      w(i,3) = w(i,1)
   enddo
endif
!
fpar(5) = sqrt(distdot(n,w,1,w,1))
fpar(3) = fpar(5)
tao = fpar(5)
fpar(11) = fpar(11) + n + n
if (abs(ipar(3)).eq.2) then
   fpar(4) = fpar(1) * sqrt(distdot(n,rhs,1,rhs,1)) + fpar(2)
   fpar(11) = fpar(11) + n + n
else if (ipar(3).ne.999) then
   fpar(4) = fpar(1) * tao + fpar(2)
endif
te = zero
rho = zero
!
!     begin iteration
!
30 sigma = rho
rho = distdot(n,w(1,2),1,w(1,3),1)
fpar(11) = fpar(11) + n + n
if (brkdn(rho,ipar)) goto 900
if (ipar(7).eq.1) then
   alpha = zero
else
   alpha = rho / sigma
endif
do i = 1, n
   w(i,4) = w(i,3) + alpha * w(i,5)
enddo
fpar(11) = fpar(11) + n + n
!
!     A * x -- with preconditioning
!
if (rp) then
   ipar(1) = 5
   ipar(8) = 3*n + 1
   if (lp) then
      ipar(9) = 5*n + 1
   else
      ipar(9) = 9*n + 1
   endif
   ipar(10) = 3
   return
endif
!
40 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = 3*n + 1
endif
if (lp) then
   ipar(9) = 9*n + 1
else
   ipar(9) = 5*n + 1
endif
ipar(10) = 4
return
!
50 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = 5*n + 1
   ipar(10) = 5
   return
endif
60 ipar(7) = ipar(7) + 1
do i = 1, n
   w(i,8) = w(i,6) + alpha * (w(i,7) + alpha * w(i,8))
enddo
sigma = distdot(n,w(1,2),1,w(1,8),1)
fpar(11) = fpar(11) + 6 * n
if (brkdn(sigma,ipar)) goto 900
alpha = rho / sigma
do i = 1, n
   w(i,5) = w(i,4) - alpha * w(i,8)
enddo
fpar(11) = fpar(11) + 2*n
!
!     the second A * x
!
if (rp) then
   ipar(1) = 5
   ipar(8) = 4*n + 1
   if (lp) then
      ipar(9) = 6*n + 1
   else
      ipar(9) = 9*n + 1
   endif
   ipar(10) = 6
   return
endif
!
70 ipar(1) = 1
if (rp) then
   ipar(8) = ipar(9)
else
   ipar(8) = 4*n + 1
endif
if (lp) then
   ipar(9) = 9*n + 1
else
   ipar(9) = 6*n + 1
endif
ipar(10) = 7
return
!
80 if (lp) then
   ipar(1) = 3
   ipar(8) = ipar(9)
   ipar(9) = 6*n + 1
   ipar(10) = 8
   return
endif
90 ipar(7) = ipar(7) + 1
do i = 1, n
   w(i,3) = w(i,3) - alpha * w(i,6)
enddo
!
!     update I
!
theta = distdot(n,w(1,3),1,w(1,3),1) / (tao*tao)
sigma = one / (one + theta)
tao = tao * sqrt(sigma * theta)
fpar(11) = fpar(11) + 4*n + 6
if (brkdn(tao,ipar)) goto 900
eta = sigma * alpha
sigma = te / alpha
te = theta * eta
do i = 1, n
   w(i,9) = w(i,4) + sigma * w(i,9)
   w(i,11) = w(i,11) + eta * w(i,9)
   w(i,3) = w(i,3) - alpha * w(i,7)
enddo
fpar(11) = fpar(11) + 6 * n + 6
if (ipar(7).eq.1) then
   if (ipar(3).eq.-1) then
      fpar(3) = eta * sqrt(distdot(n,w(1,9),1,w(1,9),1))
      fpar(4) = fpar(1)*fpar(3) + fpar(2)
      fpar(11) = fpar(11) + n + n + 4
   endif
endif
!
!     update II
!
theta = distdot(n,w(1,3),1,w(1,3),1) / (tao*tao)
sigma = one / (one + theta)
tao = tao * sqrt(sigma * theta)
fpar(11) = fpar(11) + 8 + 2*n
if (brkdn(tao,ipar)) goto 900
eta = sigma * alpha
sigma = te / alpha
te = theta * eta
do i = 1, n
   w(i,9) = w(i,5) + sigma * w(i,9)
   w(i,11) = w(i,11) + eta * w(i,9)
enddo
fpar(11) = fpar(11) + 4*n + 3
!
!     this is the correct over-estimate
!      fpar(5) = sqrt(real(ipar(7)+1)) * tao
!     this is an approximation
fpar(5) = tao
if (ipar(3).eq.999) then
   ipar(1) = 10
   ipar(8) = 10*n + 1
   ipar(9) = 9*n + 1
   ipar(10) = 9
   return
else if (ipar(3).lt.0) then
   fpar(6) = eta * sqrt(distdot(n,w(1,9),1,w(1,9),1))
   fpar(11) = fpar(11) + n + n + 2
else
   fpar(6) = fpar(5)
endif
if (fpar(6).gt.fpar(4) .and. (ipar(7).lt.ipar(6) &
         .or. ipar(6).le.0)) goto 30
100 if (ipar(3).eq.999.and.ipar(11).eq.0) goto 30
!
!     clean up
!
900 if (rp) then
   if (ipar(1).lt.0) ipar(12) = ipar(1)
   ipar(1) = 5
   ipar(8) = 10*n + 1
   ipar(9) = ipar(8) - n
   ipar(10) = 10
   return
endif
110 if (rp) then
   call tidycg(n,ipar,fpar,sol,w(1,10))
else
   call tidycg(n,ipar,fpar,sol,w(1,11))
endif
!
return
end subroutine tfqmr

subroutine tidycg(n,ipar,fpar,sol,delx)
implicit none
integer i,n,ipar(16)
real*8 fpar(16),sol(n),delx(n)
!-----------------------------------------------------------------------
!     Some common operations required before terminating the CG routines
!-----------------------------------------------------------------------
real*8 zero
parameter(zero=0.0D0)
!
if (ipar(12).ne.0) then
   ipar(1) = ipar(12)
else if (ipar(1).gt.0) then
   if ((ipar(3).eq.999 .and. ipar(11).eq.1) .or. &
            fpar(6).le.fpar(4)) then
      ipar(1) = 0
   else if (ipar(7).ge.ipar(6) .and. ipar(6).gt.0) then
      ipar(1) = -1
   else
      ipar(1) = -10
   endif
endif
if (fpar(3).gt.zero .and. fpar(6).gt.zero .and. &
         ipar(7).gt.ipar(13)) then
   fpar(7) = log10(fpar(3) / fpar(6)) / dble(ipar(7)-ipar(13))
else
   fpar(7) = zero
endif
do i = 1, n
   sol(i) = sol(i) + delx(i)
enddo
return
end subroutine tidycg

subroutine uppdir(n,p,np,lbp,indp,y,u,usav,flops)
real*8 p(n,lbp), y(*), u(*), usav(*), x, flops
integer k,np,n,npm1,j,ju,indp,lbp
!-----------------------------------------------------------------------
!     updates the conjugate directions p given the upper part of the
!     banded upper triangular matrix u.  u contains the non zero
!     elements of the column of the triangular matrix..
!-----------------------------------------------------------------------
real*8 zero
parameter(zero=0.0D0)
!
npm1=np-1
if (np .le. 1) goto 12
j=indp
ju = npm1
10 if (j .le. 0) j=lbp
x = u(ju) /usav(j)
if (x .eq. zero) goto 115
do 11 k=1,n
   y(k) = y(k) - x*p(k,j)
11 continue
flops = flops + 2*n
115 j = j-1
ju = ju -1
if (ju .ge. 1) goto 10
12 indp = indp + 1
if (indp .gt. lbp) indp = 1
usav(indp) = u(np)
do 13 k=1,n
   p(k,indp) = y(k)
13 continue
208 return
!-----------------------------------------------------------------------
!-------end-of-uppdir---------------------------------------------------
end subroutine uppdir
END MODULE ModuleIters