! LEGACY: External third-party library - exempt from UFC naming/style conventions
!===============================================================================
! ddeps.f90 - Fortran 90 free-format version of ddeps.f
! COPYRIGHT (c) 1988-2005 AEA Technology and CCLRC
! Original date 14 June 2001
! Converted to F90 free format: 2025
!
! Contains:
!   MC71AD  - Estimates the 1-norm of a square matrix (reverse communication)
!   FD15AD  - Machine constants (EPSILON, TINY, HUGE, RADIX)
!   MI21ID  - CG initialization
!   MI21AD  - Conjugate Gradient solver (reverse communication)
!   MI24ID  - GMRES initialization  
!   MI24AD  - GMRES solver (reverse communication)
!   MI26ID  - BiCGSTAB initialization
!   MI26AD  - BiCGSTAB solver (reverse communication)
!===============================================================================

!===============================================================================
! MC71AD: Estimates the 1-norm of a square matrix A
! Uses reverse communication for matrix-vector products
!===============================================================================
SUBROUTINE MC71AD(N,KASE,X,EST,W,IW,KEEP)
!
!  MC71A/AD ESTIMATES THE 1-NORM OF A SQUARE MATRIX A.
!  REVERSE COMMUNICATION IS USED FOR EVALUATING MATRIX-VECTOR PRODUCTS.
!
!  Arguments:
!    N       INTEGER - The order of the matrix. N >= 1.
!    KASE    INTEGER - Set initially to zero. On return:
!                      = 1 or 2: intermediate return
!                      = 0: success
!                      = -1: N <= 0
!    X       DOUBLE PRECISION(N) - Must be overwritten by A*X (KASE=1)
!                                  or TRANSPOSE(A)*X (KASE=2)
!    EST     DOUBLE PRECISION - Contains estimate (lower bound) for norm(A)
!    W       DOUBLE PRECISION(N) - Workspace, = A*V where EST = norm(W)/norm(V)
!    IW      INTEGER(N) - Workspace
!    KEEP    INTEGER(5) - Preserves private data between calls
!
    IMPLICIT NONE
    
    ! Parameters
    INTEGER(i4), PARAMETER :: ITMAX = 5
    DOUBLE PRECISION, PARAMETER :: ZERO = 0.0D0, ONE = 1.0D0
    
    ! Arguments
    DOUBLE PRECISION, INTENT(OUT) :: EST
    INTEGER(i4), INTENT(INOUT) :: KASE
    INTEGER(i4), INTENT(IN) :: N
    DOUBLE PRECISION, INTENT(INOUT) :: W(*), X(*)
    INTEGER(i4), INTENT(INOUT) :: IW(*), KEEP(5)
    
    ! Local variables
    DOUBLE PRECISION :: ALTSGN, TEMP
    INTEGER(i4) :: I, ITER, J, JLAST, JUMP
    
    ! External functions
    INTEGER(i4) :: IDAMAX
    EXTERNAL IDAMAX
    
    ! Intrinsic functions
    INTRINSIC ABS, SIGN, NINT, DBLE
    
    ! Check N
    IF (N .LE. 0) THEN
        KASE = -1
        RETURN
    END IF
    
    ! Initial call
    IF (KASE .EQ. 0) THEN
        DO I = 1, N
            X(I) = ONE / DBLE(N)
        END DO
        KASE = 1
        JUMP = 1
        KEEP(1) = JUMP
        KEEP(2) = 0
        KEEP(3) = 0
        KEEP(4) = 0
        RETURN
    END IF
    
    ! Restore state
    JUMP  = KEEP(1)
    ITER  = KEEP(2)
    J     = KEEP(3)
    JLAST = KEEP(4)
    
    ! Branch to appropriate entry point
    SELECT CASE (JUMP)
        CASE (1)
            GO TO 100
        CASE (2)
            GO TO 200
        CASE (3)
            GO TO 300
        CASE (4)
            GO TO 400
        CASE (5)
            GO TO 500
    END SELECT
    
    ! Entry (JUMP = 1)
100 CONTINUE
    IF (N .EQ. 1) THEN
        W(1) = X(1)
        EST = ABS(W(1))
        GO TO 510
    END IF
    
    DO I = 1, N
        X(I) = SIGN(ONE, X(I))
        IW(I) = NINT(X(I))
    END DO
    KASE = 2
    JUMP = 2
    GO TO 1010
    
    ! Entry (JUMP = 2)
200 CONTINUE
    J = IDAMAX(N, X, 1)
    ITER = 2
    
    ! Main loop - iterations 2,3,...,ITMAX
220 CONTINUE
    DO I = 1, N
        X(I) = ZERO
    END DO
    X(J) = ONE
    KASE = 1
    JUMP = 3
    GO TO 1010
    
    ! Entry (JUMP = 3)
300 CONTINUE
    ! Copy X into W
    DO I = 1, N
        W(I) = X(I)
    END DO
    DO I = 1, N
        IF (NINT(SIGN(ONE, X(I))) .NE. IW(I)) GO TO 330
    END DO
    ! Repeated sign vector detected, algorithm has converged
    GO TO 410
    
330 CONTINUE
    DO I = 1, N
        X(I) = SIGN(ONE, X(I))
        IW(I) = NINT(X(I))
    END DO
    KASE = 2
    JUMP = 4
    GO TO 1010
    
    ! Entry (JUMP = 4)
400 CONTINUE
    JLAST = J
    J = IDAMAX(N, X, 1)
    IF ((ABS(X(JLAST)) .NE. ABS(X(J))) .AND. (ITER .LT. ITMAX)) THEN
        ITER = ITER + 1
        GO TO 220
    END IF
    
    ! Iteration complete. Final stage.
410 CONTINUE
    EST = ZERO
    DO I = 1, N
        EST = EST + ABS(W(I))
    END DO
    
    ALTSGN = ONE
    DO I = 1, N
        X(I) = ALTSGN * (ONE + DBLE(I-1) / DBLE(N-1))
        ALTSGN = -ALTSGN
    END DO
    KASE = 1
    JUMP = 5
    GO TO 1010
    
    ! Entry (JUMP = 5)
500 CONTINUE
    TEMP = ZERO
    DO I = 1, N
        TEMP = TEMP + ABS(X(I))
    END DO
    TEMP = 2.0D0 * TEMP / DBLE(3*N)
    IF (TEMP .GT. EST) THEN
        ! Copy X into W
        DO I = 1, N
            W(I) = X(I)
        END DO
        EST = TEMP
    END IF
    
510 KASE = 0
    
1010 CONTINUE
    KEEP(1) = JUMP
    KEEP(2) = ITER
    KEEP(3) = J
    KEEP(4) = JLAST
    RETURN
    
END SUBROUTINE MC71AD

!===============================================================================
! FD15AD: Machine constants
! Fortran 77 implementation of Fortran 90 intrinsic functions
!===============================================================================
DOUBLE PRECISION FUNCTION FD15AD(T)
!
!  Returns machine constants:
!    'E' - EPSILON(DOUBLE PRECISION)
!    'T' - TINY(DOUBLE PRECISION)  
!    'H' - HUGE(DOUBLE PRECISION)
!    'R' - RADIX(DOUBLE PRECISION)
!
    IMPLICIT NONE
    CHARACTER, INTENT(IN) :: T
    
    IF (T .EQ. 'E') THEN
        FD15AD = EPSILON(1.0D0)
    ELSE IF (T .EQ. 'T') THEN
        FD15AD = TINY(1.0D0)
    ELSE IF (T .EQ. 'H') THEN
        FD15AD = HUGE(1.0D0)
    ELSE IF (T .EQ. 'R') THEN
        FD15AD = DBLE(RADIX(1.0D0))
    ELSE
        FD15AD = 0.0D0
    END IF
    RETURN
    
END FUNCTION FD15AD

!===============================================================================
! MI21ID: CG initialization
! Initializes control parameters for MI21AD
!===============================================================================
SUBROUTINE MI21ID(ICNTL, CNTL, ISAVE, RSAVE)
!
!  If A is symmetric, positive definite, MI21 solves A*x = b
!  using the Conjugate Gradients method with optional preconditioning.
!
!  Arguments:
!    ICNTL(8)  - INTEGER control array
!    CNTL(5)   - DOUBLE PRECISION control array
!    ISAVE(10) - INTEGER persistent data array
!    RSAVE(6)  - DOUBLE PRECISION persistent data array
!
    IMPLICIT NONE
    
    DOUBLE PRECISION, INTENT(OUT) :: CNTL(5)
    INTEGER(i4), INTENT(OUT) :: ICNTL(8)
    INTEGER(i4), INTENT(OUT) :: ISAVE(10)
    DOUBLE PRECISION, INTENT(OUT) :: RSAVE(6)
    
    INTEGER(i4) :: I
    
    INTRINSIC SQRT
    
    ICNTL(1) = 6    ! Error stream
    ICNTL(2) = 6    ! Warning stream
    ICNTL(3) = 0    ! No preconditioning
    ICNTL(4) = 0    ! Use internal convergence test
    ICNTL(5) = 0    ! No initial guess
    ICNTL(6) = -1   ! Max iterations = N
    ICNTL(7) = 0    ! Normalized curvature not used
    ICNTL(8) = 0    ! Spare
    
    CNTL(1) = SQRT(EPSILON(CNTL))
    CNTL(2) = 0.0D0
    CNTL(3) = -1.0D0
    CNTL(4) = 0.0D0
    CNTL(5) = 0.0D0
    
    ! Initialize persistent data
    DO I = 1, 10
        ISAVE(I) = 0
    END DO
    DO I = 1, 6
        RSAVE(I) = 0.0D0
    END DO
    RETURN
    
END SUBROUTINE MI21ID

!===============================================================================
! MI21AD: Conjugate Gradient solver (reverse communication)
!===============================================================================
SUBROUTINE MI21AD(IACT, N, W, LDW, LOCY, LOCZ, RESID, ICNTL, CNTL, INFO, ISAVE, RSAVE)
!
!  Solves A*x = b using Conjugate Gradients with optional preconditioning.
!  Uses reverse communication.
!
!  IACT values:
!    -1: Fatal error, terminate
!     0: Initial call
!     1: Convergence achieved (or user test required)
!     2: Perform y := A*z
!     3: Perform y := P*z (preconditioning)
!
    IMPLICIT NONE
    
    ! Parameters
    DOUBLE PRECISION, PARAMETER :: ONE = 1.0D+0, ZERO = 0.0D+0
    
    ! Arguments
    DOUBLE PRECISION, INTENT(OUT) :: RESID
    INTEGER(i4), INTENT(INOUT) :: IACT
    INTEGER(i4), INTENT(IN) :: LDW, N
    INTEGER(i4), INTENT(OUT) :: LOCY, LOCZ
    DOUBLE PRECISION, INTENT(INOUT) :: CNTL(5), W(LDW, 4)
    INTEGER(i4), INTENT(INOUT) :: ICNTL(8), INFO(4)
    INTEGER(i4), INTENT(INOUT) :: ISAVE(10)
    DOUBLE PRECISION, INTENT(INOUT) :: RSAVE(6)
    
    ! Local variables
    INTEGER(i4) :: I, IPOS, ITMAX, B, P, Q, R, X, Z
    DOUBLE PRECISION :: ALPHA, BETA, BNRM2, CURV, RHO, RHO1
    
    ! External functions
    DOUBLE PRECISION :: DDOT, DNRM2
    EXTERNAL DDOT, DNRM2
    
    ! Intrinsic functions
    INTRINSIC SQRT
    
    ! External subroutines
    EXTERNAL DAXPY, DCOPY, DSCAL
    
    ! Restore persistent data
    IPOS  = ISAVE(1)
    ITMAX = ISAVE(2)
    B     = ISAVE(3)
    P     = ISAVE(4)
    Q     = ISAVE(5)
    R     = ISAVE(6)
    X     = ISAVE(7)
    Z     = ISAVE(8)
    
    BNRM2 = RSAVE(1)
    RHO   = RSAVE(2)
    RHO1  = RSAVE(3)
    CURV  = RSAVE(4)
    
    ! Jump to appropriate place in code
    IF (IACT .NE. 0) THEN
        ! Immediate return if error on a previous call
        IF (IACT .LT. 0) GO TO 1000
        ! Immediate return if convergence already achieved
        IF (IACT .EQ. 1 .AND. ICNTL(4) .EQ. 0) GO TO 1000
        IF (IACT .EQ. 1 .AND. BNRM2 .EQ. ZERO) GO TO 1000
        ! Branch
        SELECT CASE (IPOS)
            CASE (1)
                GO TO 30
            CASE (2)
                GO TO 50
            CASE (3)
                GO TO 60
            CASE (4)
                GO TO 70
        END SELECT
    END IF
    
    ! Initial call
    INFO(1) = 0
    
    ! Test the input parameters
    IF (N .LT. 1) THEN
        INFO(1) = -1
    ELSE IF (LDW .LT. N) THEN
        INFO(1) = -2
    END IF
    IF (INFO(1) .LT. 0) THEN
        IACT = -1
        IF (ICNTL(1) .GT. 0) WRITE(ICNTL(1), 2000) INFO(1)
        GO TO 1000
    END IF
    
    ! Alias workspace columns
    B = 1
    R = B
    X = 2
    P = 3
    Q = 4
    IF (ICNTL(3) .NE. 0) THEN
        Z = Q
    ELSE
        Z = R
    END IF
    
    ! Set INFO(2) and ITMAX
    INFO(2) = 0
    IF (ICNTL(6) .GT. 0) THEN
        ITMAX = ICNTL(6)
    ELSE
        ITMAX = N
    END IF
    
    ! Set CNTL(3)
    IF (CNTL(3) .LE. ZERO) CNTL(3) = N * EPSILON(CNTL)
    
    ! Compute ||b||
    BNRM2 = DNRM2(N, W(1, B), 1)
    
    ! Immediate return if ||b|| = 0
    IF (BNRM2 .EQ. ZERO) THEN
        IACT = 1
        DO I = 1, N
            W(I, X) = ZERO
            W(I, B) = ZERO
        END DO
        RESID = ZERO
        GO TO 1000
    END IF
    
    ! Check value of CNTL(1)
    IF (ICNTL(4) .EQ. 0) THEN
        IF (CNTL(1) .LT. EPSILON(CNTL) .OR. CNTL(1) .GT. ONE) THEN
            INFO(1) = 1
            IF (ICNTL(2) .GT. 0) THEN
                WRITE(ICNTL(2), 2010) INFO(1)
                WRITE(ICNTL(2), 2020)
            END IF
            CNTL(1) = SQRT(EPSILON(CNTL))
        END IF
    END IF
    
    ! Compute initial residual
    ! If the user has not supplied an initial guess, set X = 0
    IF (ICNTL(5) .EQ. 0) THEN
        DO I = 1, N
            W(I, X) = ZERO
        END DO
        GO TO 40
    ELSE
        ! Initial guess supplied by user
        IF (DNRM2(N, W(1, X), 1) .EQ. ZERO) GO TO 40
        ! Return to user to compute Ax
        IPOS = 1
        IACT = 2
        LOCY = P
        LOCZ = X
        GO TO 1000
    END IF
    
    ! Compute r = b - Ax
30  CONTINUE
    CALL DAXPY(N, -ONE, W(1, P), 1, W(1, R), 1)
    
    ! Compute ||r||
    BNRM2 = DNRM2(N, W(1, R), 1)
    
    ! Main iteration loop
40  CONTINUE
    ! Update iteration count
    INFO(2) = INFO(2) + 1
    
    ! Check maximum number of iterations
    IF (INFO(2) .GT. ITMAX) THEN
        INFO(1) = -4
        IACT = -1
        IF (ICNTL(1) .GT. 0) THEN
            WRITE(ICNTL(1), 2000) INFO(1)
            WRITE(ICNTL(1), 2030) ITMAX
        END IF
        GO TO 1000
    END IF
    
    ! Return to user for preconditioner Z = P^-1 R
    IF (ICNTL(3) .NE. 0) THEN
        IPOS = 2
        IACT = 3
        LOCY = Z
        LOCZ = R
        GO TO 1000
    END IF
    
50  CONTINUE
    ! Compute inner product R^T Z
    RHO = DDOT(N, W(1, R), 1, W(1, Z), 1)
    
    ! Compute search direction P
    IF (INFO(2) .EQ. 1) THEN
        ! First iteration
        CALL DCOPY(N, W(1, Z), 1, W(1, P), 1)
    ELSE
        BETA = RHO / RHO1
        ! Later iterations
        CALL DSCAL(N, BETA, W(1, P), 1)
        CALL DAXPY(N, ONE, W(1, Z), 1, W(1, P), 1)
    END IF
    
    ! Return to user for matrix-vector product Q = A*P
    IPOS = 3
    IACT = 2
    LOCY = Q
    LOCZ = P
    GO TO 1000
    
60  CONTINUE
    ! Obtain the curvature along P
    CURV = DDOT(N, W(1, P), 1, W(1, Q), 1)
    
    ! If the curvature is negative, A is indefinite
    IF (ICNTL(7) .EQ. 1) THEN
        IF (CURV .LT. CNTL(3) * DDOT(N, W(1, P), 1, W(1, P), 1)) INFO(1) = -3
    ELSE IF (CURV .LT. CNTL(3)) THEN
        INFO(1) = -3
    END IF
    IF (INFO(1) .EQ. -3) THEN
        IACT = -1
        IF (ICNTL(1) .GT. 0) WRITE(ICNTL(1), 2000) INFO(1)
        GO TO 1000
    END IF
    
    ! Compute the stepsize
    ALPHA = RHO / CURV
    
    ! Update the estimate of the solution
    CALL DAXPY(N, ALPHA, W(1, P), 1, W(1, X), 1)
    
    ! Update the residual
    CALL DAXPY(N, -ALPHA, W(1, Q), 1, W(1, R), 1)
    
    ! Check convergence
    RESID = DNRM2(N, W(1, R), 1)
    IPOS = 4
    IF (ICNTL(4) .NE. 0) THEN
        ! Return residual to user for convergence testing
        IACT = 1
        GO TO 1000
    ELSE
        ! Test scaled residual for convergence
        IF (RESID .LE. MAX(BNRM2 * CNTL(1), CNTL(2))) THEN
            ! Convergence achieved
            IACT = 1
            GO TO 1000
        END IF
    END IF
    
70  CONTINUE
    RHO1 = RHO
    ! Next iteration
    GO TO 40
    
    ! Save persistent data and return
1000 CONTINUE
    ISAVE(1) = IPOS
    ISAVE(2) = ITMAX
    ISAVE(3) = B
    ISAVE(4) = P
    ISAVE(5) = Q
    ISAVE(6) = R
    ISAVE(7) = X
    ISAVE(8) = Z
    RSAVE(1) = BNRM2
    RSAVE(2) = RHO
    RSAVE(3) = RHO1
    RSAVE(4) = CURV
    RETURN
    
    ! Format statements
2000 FORMAT(/ ' Error message from MI21A/AD. INFO(1) = ', I4)
2010 FORMAT(/ ' Warning message from MI21A/AD. INFO(1) = ', I4)
2020 FORMAT(' Convergence tolerance out of range.')
2030 FORMAT(' Number of iterations required exceeds the maximum of ', &
            I8, / ' allowed by ICNTL(6)')
    
END SUBROUTINE MI21AD

!===============================================================================
! MI24ID: GMRES initialization
!===============================================================================
SUBROUTINE MI24ID(ICNTL, CNTL, ISAVE, RSAVE, LSAVE)
!
!  MI24 solves A*x = b using GMRES with restarts.
!  Optional left/right preconditioning.
!
    IMPLICIT NONE
    
    INTEGER(i4), INTENT(OUT) :: ICNTL(8)
    DOUBLE PRECISION, INTENT(OUT) :: CNTL(4)
    INTEGER(i4), INTENT(OUT) :: ISAVE(17)
    DOUBLE PRECISION, INTENT(OUT) :: RSAVE(9)
    LOGICAL, INTENT(OUT) :: LSAVE(4)
    
    INTEGER(i4) :: I
    
    INTRINSIC SQRT
    
    ICNTL(1) = 6    ! Error stream
    ICNTL(2) = 6    ! Warning stream
    ICNTL(3) = 0    ! No preconditioning (0=none, 1=left, 2=right)
    ICNTL(4) = 0    ! Use internal convergence test
    ICNTL(5) = 0    ! No initial guess
    ICNTL(6) = -1   ! Max iterations = 2*N
    ICNTL(7) = 0    ! Spare
    ICNTL(8) = 0    ! Spare
    
    CNTL(1) = SQRT(EPSILON(CNTL))
    CNTL(2) = 0.0D0
    CNTL(3) = 0.0D0
    CNTL(4) = 0.0D0
    
    ! Initialize persistent data
    DO I = 1, 17
        ISAVE(I) = 0
    END DO
    DO I = 1, 9
        RSAVE(I) = 0.0D0
    END DO
    DO I = 1, 4
        LSAVE(I) = .FALSE.
    END DO
    
    RETURN
    
END SUBROUTINE MI24ID

!===============================================================================
! MI24AD: GMRES solver (reverse communication)
!===============================================================================
SUBROUTINE MI24AD(IACT, N, M, W, LDW, LOCY, LOCZ, H, LDH, RESID, &
                  ICNTL, CNTL, INFO, ISAVE, RSAVE, LSAVE)
!
!  GMRES with restarts. Uses reverse communication.
!
!  IACT values:
!    -1: Fatal error
!     0: Initial call
!     1: Convergence (or user test)
!     2: Perform y := A*z
!     3: Perform y := P_L*z (left preconditioning)
!     4: Perform y := P_R*z (right preconditioning)
!
    IMPLICIT NONE
    
    ! Parameters
    DOUBLE PRECISION, PARAMETER :: ZERO = 0.0D+0, ONE = 1.0D+0, POINT1 = 1.0D-1
    
    ! Arguments
    DOUBLE PRECISION, INTENT(OUT) :: RESID
    INTEGER(i4), INTENT(INOUT) :: IACT
    INTEGER(i4), INTENT(IN) :: N, M, LDW, LDH
    INTEGER(i4), INTENT(OUT) :: LOCY, LOCZ
    DOUBLE PRECISION, INTENT(INOUT) :: CNTL(4), W(LDW, M+7), H(LDH, M+2)
    INTEGER(i4), INTENT(INOUT) :: ICNTL(8), INFO(4)
    INTEGER(i4), INTENT(INOUT) :: ISAVE(17)
    DOUBLE PRECISION, INTENT(INOUT) :: RSAVE(9)
    LOGICAL, INTENT(INOUT) :: LSAVE(4)
    
    ! Local variables
    INTEGER(i4) :: I, K, ITMAX, CS, SN, R, S, V, UU, Y, RES
    INTEGER(i4) :: B, X, IPOS, U
    LOGICAL :: LEFT, RIGHT
    DOUBLE PRECISION :: AA, BB, BNRM2, RNORM, RSTOP
    DOUBLE PRECISION :: PRESID, PRSTOP
    
    ! External functions and subroutines
    DOUBLE PRECISION :: DDOT, DNRM2
    EXTERNAL DAXPY, DCOPY, DDOT, DNRM2, DROT, DROTG, DSCAL
    EXTERNAL DTRSV, DGEMV
    
    ! Restore persistent data
    IPOS   = ISAVE(1)
    ITMAX  = ISAVE(2)
    B      = ISAVE(3)
    I      = ISAVE(4)
    K      = ISAVE(5)
    R      = ISAVE(6)
    X      = ISAVE(7)
    U      = ISAVE(8)
    V      = ISAVE(9)
    S      = ISAVE(10)
    Y      = ISAVE(11)
    CS     = ISAVE(12)
    SN     = ISAVE(13)
    UU     = ISAVE(14)
    RES    = ISAVE(15)
    
    BNRM2  = RSAVE(1)
    AA     = RSAVE(2)
    BB     = RSAVE(3)
    RNORM  = RSAVE(4)
    PRESID = RSAVE(5)
    RSTOP  = RSAVE(6)
    PRSTOP = RSAVE(7)
    
    LEFT   = LSAVE(1)
    RIGHT  = LSAVE(2)
    
    ! Jump to appropriate place
    IF (IACT .NE. 0) THEN
        IF (IACT .LT. 0) GO TO 1000
        IF (IACT .EQ. 1 .AND. ICNTL(4) .EQ. 0) GO TO 1000
        IF (IACT .EQ. 1 .AND. BNRM2 .EQ. ZERO) GO TO 1000
        SELECT CASE (IPOS)
            CASE (1)
                GO TO 40
            CASE (2)
                GO TO 60
            CASE (3)
                GO TO 70
            CASE (4)
                GO TO 100
            CASE (5)
                GO TO 110
            CASE (6)
                GO TO 120
            CASE (7)
                GO TO 160
        END SELECT
    END IF
    
    ! Initial call
    INFO(1) = 0
    
    ! Test input parameters
    IF (N .LT. 1) THEN
        INFO(1) = -1
    ELSE IF (M .LT. 1) THEN
        INFO(1) = -2
    ELSE IF (LDW .LT. MAX(1, N)) THEN
        INFO(1) = -3
    ELSE IF (LDH .LT. M + 1) THEN
        INFO(1) = -4
    END IF
    IF (INFO(1) .LT. 0) THEN
        IACT = -1
        IF (ICNTL(1) .GT. 0) WRITE(ICNTL(1), 2000) INFO(1)
        GO TO 1000
    END IF
    
    ! Set INFO(2) and ITMAX
    INFO(2) = 0
    IF (ICNTL(6) .GT. 0) THEN
        ITMAX = ICNTL(6)
    ELSE
        ITMAX = 2 * N
    END IF
    
    ! Alias workspace columns
    RES = 1
    X   = 2
    S   = 3
    B   = 4
    UU  = 5
    Y   = 6
    V   = 7
    
    ! Store Givens parameters in H
    CS = M + 1
    SN = CS + 1
    
    ! Compute ||b||
    BNRM2 = DNRM2(N, W(1, RES), 1)
    
    ! Immediate return if ||b|| = 0
    IF (BNRM2 .EQ. ZERO) THEN
        IACT = 1
        DO I = 1, N
            W(I, X) = ZERO
            W(I, RES) = ZERO
        END DO
        RESID = ZERO
        GO TO 1000
    END IF
    
    ! Check CNTL(1)
    IF (ICNTL(4) .EQ. 0) THEN
        IF (CNTL(1) .LT. EPSILON(CNTL) .OR. CNTL(1) .GT. ONE) THEN
            INFO(1) = 1
            IF (ICNTL(2) .GT. 0) THEN
                WRITE(ICNTL(2), 2010) INFO(1)
                WRITE(ICNTL(2), 2020)
            END IF
            CNTL(1) = SQRT(EPSILON(CNTL))
        END IF
    END IF
    
    ! Set preconditioning flags
    LEFT  = ICNTL(3) .EQ. 1 .OR. ICNTL(3) .EQ. 3
    RIGHT = ICNTL(3) .EQ. 2 .OR. ICNTL(3) .EQ. 3
    
    ! If no initial guess, set x to zero
    IF (ICNTL(5) .EQ. 0) THEN
        DO I = 1, N
            W(I, X) = ZERO
        END DO
    END IF
    
    ! Start computing residual
    CALL DCOPY(N, W(1, RES), 1, W(1, B), 1)
    IF (DNRM2(N, W(1, X), 1) .EQ. ZERO) GO TO 50
    
    ! Main iteration start
30  CONTINUE
    ! Return for Y = A * X
    IPOS = 1
    IACT = 2
    LOCY = Y
    LOCZ = X
    GO TO 1000
    
40  CONTINUE
    ! Finalize residual
    CALL DAXPY(N, -ONE, W(1, Y), 1, W(1, RES), 1)
    
50  CONTINUE
    ! Compute norm of residual
    RESID = DNRM2(N, W(1, RES), 1)
    
    ! Assign stopping tolerance on first iteration
    IF (INFO(2) .EQ. 0) THEN
        RSTOP  = MAX(RESID * CNTL(1), CNTL(2))
        PRSTOP = RSTOP
    END IF
    
    ! Check for error
    IF (INFO(1) .LT. 0) THEN
        IACT = -1
        IF (ICNTL(1) .GT. 0) WRITE(ICNTL(1), 2000) INFO(1)
        GO TO 1000
    END IF
    
    ! Return for left preconditioning R = P_L^-1 RES
    IF (LEFT) THEN
        R = UU
        IPOS = 2
        IACT = 3
        LOCY = R
        LOCZ = RES
        GO TO 1000
    ELSE
        R = RES
    END IF
    
60  CONTINUE
    ! Check convergence
    IF (ICNTL(4) .NE. 0 .OR. (ICNTL(4) .EQ. 0 .AND. RESID .LE. RSTOP)) THEN
        IACT = 1
        IPOS = 3
        GO TO 1000
    END IF
    
70  CONTINUE
    ! Construct first column of V
    CALL DCOPY(N, W(1, R), 1, W(1, V), 1)
    RNORM = DNRM2(N, W(1, V), 1)
    CALL DSCAL(N, ONE / RNORM, W(1, V), 1)
    
    ! Initialize S to E1 scaled by RNORM
    W(1, S) = RNORM
    DO K = 2, N
        W(K, S) = ZERO
    END DO
    
    ! Start inner iteration
    I = 0
    
90  CONTINUE
    I = I + 1
    
    ! Update iteration count
    INFO(2) = INFO(2) + 1
    
    ! Check max iterations
    IF (INFO(2) .GT. ITMAX) THEN
        I = I - 1
        INFO(1) = -5
        IF (ICNTL(1) .GT. 0) WRITE(ICNTL(1), 2030) ITMAX
        IF (I .NE. 0) GO TO 150
        IACT = -1
        IF (ICNTL(1) .GT. 0) WRITE(ICNTL(1), 2000) INFO(1)
        GO TO 1000
    END IF
    
    ! Return for right preconditioning Y = P_R^-1 V
    IF (RIGHT) THEN
        IPOS = 4
        IACT = 4
        LOCY = Y
        LOCZ = V + I - 1
        GO TO 1000
    END IF
    
100 CONTINUE
    ! Return for matrix-vector product
    IPOS = 5
    IACT = 2
    IF (RIGHT) THEN
        LOCY = RES
        LOCZ = Y
    ELSE
        LOCY = RES
        LOCZ = V + I - 1
    END IF
    GO TO 1000
    
110 CONTINUE
    ! Return for left preconditioning W = P_L^-1 RES
    IF (LEFT) THEN
        U = UU
        IPOS = 6
        IACT = 3
        LOCY = UU
        LOCZ = RES
        GO TO 1000
    ELSE
        U = RES
    END IF
    
120 CONTINUE
    ! Gram-Schmidt orthogonalization
    DO K = 1, I
        H(K, I) = DDOT(N, W(1, U), 1, W(1, V + K - 1), 1)
        CALL DAXPY(N, -H(K, I), W(1, V + K - 1), 1, W(1, U), 1)
    END DO
    H(I + 1, I) = DNRM2(N, W(1, U), 1)
    CALL DCOPY(N, W(1, U), 1, W(1, V + I), 1)
    CALL DSCAL(N, ONE / H(I + 1, I), W(1, V + I), 1)
    
    ! Apply previous Givens rotations to H
    DO K = 1, I - 1
        CALL DROT(1, H(K, I), LDH, H(K + 1, I), LDH, H(K, CS), H(K, SN))
    END DO
    
    ! Construct new Givens rotation
    AA = H(I, I)
    BB = H(I + 1, I)
    CALL DROTG(AA, BB, H(I, CS), H(I, SN))
    CALL DROT(1, H(I, I), LDH, H(I + 1, I), LDH, H(I, CS), H(I, SN))
    
    ! Apply rotation to S
    IF (I .LT. N) THEN
        CALL DROT(1, W(I, S), LDW, W(I + 1, S), LDW, H(I, CS), H(I, SN))
        PRESID = ABS(W(I + 1, S))
        IF (PRESID .LE. PRSTOP .AND. ICNTL(4) .EQ. 0) THEN
            PRSTOP = PRSTOP * POINT1
            GO TO 150
        END IF
        IF (I .LT. M) GO TO 90
    END IF
    
    ! Compute solution vector X
150 CONTINUE
    CALL DCOPY(I, W(1, S), 1, W(1, Y), 1)
    CALL DTRSV('UPPER', 'NOTRANS', 'NONUNIT', I, H, LDH, W(1, Y), 1)
    
    ! Compute update UU = V*Y
    CALL DGEMV('NOTRANS', N, I, ONE, W(1, V), LDW, W(1, Y), 1, ZERO, W(1, UU), 1)
    
    ! Return for right preconditioning Y = P_R^-1 UU
    IF (RIGHT) THEN
        IPOS = 7
        IACT = 4
        LOCY = Y
        LOCZ = UU
        GO TO 1000
    END IF
    
160 CONTINUE
    ! Update X
    IF (RIGHT) THEN
        CALL DAXPY(N, ONE, W(1, Y), 1, W(1, X), 1)
    ELSE
        CALL DAXPY(N, ONE, W(1, UU), 1, W(1, X), 1)
    END IF
    
    ! Start computing residual
    CALL DCOPY(N, W(1, B), 1, W(1, RES), 1)
    
    ! Restart
    GO TO 30
    
    ! Save persistent data and return
1000 CONTINUE
    ISAVE(1) = IPOS
    ISAVE(2) = ITMAX
    ISAVE(3) = B
    ISAVE(4) = I
    ISAVE(5) = K
    ISAVE(6) = R
    ISAVE(7) = X
    ISAVE(8) = U
    ISAVE(9) = V
    ISAVE(10) = S
    ISAVE(11) = Y
    ISAVE(12) = CS
    ISAVE(13) = SN
    ISAVE(14) = UU
    ISAVE(15) = RES
    
    RSAVE(1) = BNRM2
    RSAVE(2) = AA
    RSAVE(3) = BB
    RSAVE(4) = RNORM
    RSAVE(5) = PRESID
    RSAVE(6) = RSTOP
    RSAVE(7) = PRSTOP
    
    LSAVE(1) = LEFT
    LSAVE(2) = RIGHT
    RETURN
    
    ! Format statements
2000 FORMAT(/ ' Error message from MI24A/AD. INFO(1) = ', I4)
2010 FORMAT(/ ' Warning message from MI24A/AD. INFO(1) = ', I4)
2020 FORMAT(' Convergence tolerance out of range.')
2030 FORMAT(/, ' # iterations required exceeds the maximum of ', &
            I8, ' allowed by ICNTL(6)')
    
END SUBROUTINE MI24AD

!===============================================================================
! MI26ID: BiCGSTAB initialization
!===============================================================================
SUBROUTINE MI26ID(ICNTL, CNTL, ISAVE, RSAVE)
!
!  MI26 solves A*x = b using BiConjugate Gradient Stabilized method
!  with optional preconditioning.
!
    IMPLICIT NONE
    
    DOUBLE PRECISION, INTENT(OUT) :: CNTL(5)
    INTEGER(i4), INTENT(OUT) :: ICNTL(8)
    INTEGER(i4), INTENT(OUT) :: ISAVE(14)
    DOUBLE PRECISION, INTENT(OUT) :: RSAVE(9)
    
    INTEGER(i4) :: I
    DOUBLE PRECISION, PARAMETER :: ZERO = 0.0D+0
    
    ! External functions
    DOUBLE PRECISION :: FD15AD
    EXTERNAL FD15AD
    
    INTRINSIC SQRT
    
    ICNTL(1) = 6    ! Error stream
    ICNTL(2) = 6    ! Warning stream
    ICNTL(3) = 0    ! No preconditioning
    ICNTL(4) = 0    ! Use internal convergence test
    ICNTL(5) = 0    ! No initial guess
    ICNTL(6) = -1   ! Max iterations = N
    ICNTL(7) = 0    ! Spare
    ICNTL(8) = 0    ! Spare
    
    CNTL(1) = SQRT(FD15AD('E'))
    CNTL(2) = ZERO
    CNTL(3) = FD15AD('E')
    CNTL(4) = ZERO
    CNTL(5) = ZERO
    
    ! Initialize persistent data
    DO I = 1, 14
        ISAVE(I) = 0
    END DO
    DO I = 1, 9
        RSAVE(I) = 0.0D0
    END DO
    
    RETURN
    
END SUBROUTINE MI26ID

!===============================================================================
! MI26AD: BiCGSTAB solver (reverse communication)
!===============================================================================
SUBROUTINE MI26AD(IACT, N, W, LDW, LOCY, LOCZ, RESID, ICNTL, CNTL, INFO, &
                  ISAVE, RSAVE)
!
!  BiCGSTAB solver. Uses reverse communication.
!
!  IACT values:
!    -1: Fatal error
!     0: Initial call
!     1: Convergence (or user test)
!     2: Perform y := A*z
!     3: Perform y := P*z (preconditioning)
!
    IMPLICIT NONE
    
    ! Parameters
    DOUBLE PRECISION, PARAMETER :: ONE = 1.0D+0, ZERO = 0.0D+0
    
    ! Arguments
    DOUBLE PRECISION, INTENT(OUT) :: RESID
    INTEGER(i4), INTENT(INOUT) :: IACT
    INTEGER(i4), INTENT(IN) :: LDW, N
    INTEGER(i4), INTENT(OUT) :: LOCY, LOCZ
    DOUBLE PRECISION, INTENT(INOUT) :: CNTL(5), W(LDW, 8)
    INTEGER(i4), INTENT(INOUT) :: ICNTL(8), INFO(4)
    INTEGER(i4), INTENT(INOUT) :: ISAVE(14)
    DOUBLE PRECISION, INTENT(INOUT) :: RSAVE(9)
    
    ! Local variables
    DOUBLE PRECISION :: ALPHA, BETA, BNRM2, OMEGA, RHO, RHO1, RNRM2, RTNRM2
    DOUBLE PRECISION :: RSTOP, SNORM2, TNORM2
    INTEGER(i4) :: B, I, IPOS, ITMAX, P, PHAT, R, RTLD, S, SHAT, T, V, X
    
    ! External functions
    DOUBLE PRECISION :: DDOT, DNRM2, FD15AD
    EXTERNAL DDOT, DNRM2, FD15AD
    
    INTRINSIC ABS, MAX, SQRT
    
    ! External subroutines
    EXTERNAL DAXPY, DCOPY, DSCAL
    
    ! Restore persistent data
    IPOS   = ISAVE(1)
    ITMAX  = ISAVE(2)
    B      = ISAVE(3)
    R      = ISAVE(4)
    X      = ISAVE(5)
    P      = ISAVE(6)
    S      = ISAVE(7)
    T      = ISAVE(8)
    V      = ISAVE(9)
    PHAT   = ISAVE(10)
    RTLD   = ISAVE(11)
    SHAT   = ISAVE(12)
    
    BNRM2  = RSAVE(1)
    ALPHA  = RSAVE(2)
    BETA   = RSAVE(3)
    RHO    = RSAVE(4)
    RHO1   = RSAVE(5)
    RSTOP  = RSAVE(6)
    OMEGA  = RSAVE(7)
    
    ! Jump to appropriate place
    IF (IACT .EQ. 0) GO TO 10
    ! Immediate return if error on previous call
    IF (IACT .LT. 0) GO TO 1000
    ! Immediate return if convergence already achieved
    IF (IACT .EQ. 1 .AND. ICNTL(4) .EQ. 0) GO TO 1000
    IF (IACT .EQ. 1 .AND. BNRM2 .EQ. ZERO) GO TO 1000
    
    IF (IPOS .EQ. 1) GO TO 40
    IF (IPOS .EQ. 2) GO TO 70
    IF (IPOS .EQ. 3) GO TO 80
    IF (IPOS .EQ. 4) GO TO 90
    IF (IPOS .EQ. 5) GO TO 100
    IF (IPOS .EQ. 6) GO TO 110
    IF (IPOS .EQ. 7) GO TO 120
    
10  CONTINUE
    ! Initial call
    INFO(1) = 0
    
    ! Test input parameters
    IF (N .LE. 0) THEN
        INFO(1) = -1
    ELSE IF (LDW .LT. MAX(1, N)) THEN
        INFO(1) = -2
    END IF
    IF (INFO(1) .LT. 0) THEN
        IACT = -1
        IF (ICNTL(1) .GT. 0) WRITE(ICNTL(1), FMT=9000) INFO(1)
        GO TO 1000
    END IF
    
    ! Alias workspace columns
    B = 1
    X = 2
    R = 1
    RTLD = 3
    P = 4
    V = 5
    T = 6
    PHAT = 7
    SHAT = 8
    S = 1
    
    ! Set INFO(2) and ITMAX
    INFO(2) = 0
    ITMAX = N
    IF (ICNTL(6) .GT. 0) ITMAX = ICNTL(6)
    
    ! Compute ||b||
    BNRM2 = DNRM2(N, W(1, B), 1)
    
    ! Immediate return if ||b|| = 0
    IF (BNRM2 .EQ. ZERO) THEN
        IACT = 1
        DO I = 1, N
            W(I, X) = ZERO
            W(I, B) = ZERO
        END DO
        RESID = ZERO
        GO TO 1000
    END IF
    
    IF (ICNTL(4) .EQ. 0) THEN
        ! Check CNTL(1)
        IF (CNTL(1) .LT. FD15AD('E') .OR. CNTL(1) .GT. ONE) THEN
            INFO(1) = 1
            IF (ICNTL(2) .GT. 0) THEN
                WRITE(ICNTL(2), FMT=9010) INFO(1)
                WRITE(ICNTL(2), FMT=9020)
            END IF
            CNTL(1) = SQRT(FD15AD('E'))
        END IF
    END IF
    
    ! Compute initial residual
    IF (ICNTL(5) .EQ. 0) THEN
        DO I = 1, N
            W(I, X) = ZERO
        END DO
        GO TO 50
    ELSE
        ! Initial guess supplied
        IF (DNRM2(N, W(1, X), 1) .EQ. ZERO) GO TO 50
        ! Return to compute Ax
        IPOS = 1
        IACT = 2
        LOCY = P
        LOCZ = X
        GO TO 1000
    END IF
    
    ! Compute r = b - Ax
40  CALL DAXPY(N, -ONE, W(1, P), 1, W(1, R), 1)
    
50  CONTINUE
    ! Compute norm of initial residual
    RSTOP = DNRM2(N, W(1, R), 1)
    
    ! Choose RTLD = R
    CALL DCOPY(N, W(1, R), 1, W(1, RTLD), 1)
    
    ! BiCGSTAB iteration
60  CONTINUE
    ! Update iteration count
    INFO(2) = INFO(2) + 1
    
    ! Check max iterations
    IF (INFO(2) .GT. ITMAX) THEN
        INFO(1) = -4
        IACT = -1
        IF (ICNTL(1) .GT. 0) THEN
            WRITE(ICNTL(1), FMT=9000) INFO(1)
            WRITE(ICNTL(1), FMT=9030) ITMAX
        END IF
        GO TO 1000
    END IF
    
    RHO = DDOT(N, W(1, RTLD), 1, W(1, R), 1)
    
    ! Check for breakdown
    IF (ABS(RHO) .LT. CNTL(3) * N) THEN
        RNRM2 = DNRM2(N, W(1, R), 1)
        RTNRM2 = DNRM2(N, W(1, RTLD), 1)
        IF (ABS(RHO) .LT. CNTL(3) * RNRM2 * RTNRM2) THEN
            INFO(1) = -3
            IACT = -1
            IF (ICNTL(1) .GT. 0) WRITE(ICNTL(1), FMT=9000) INFO(1)
            GO TO 1000
        END IF
    END IF
    
    ! Compute P
    IF (INFO(2) .GT. 1) THEN
        BETA = (RHO / RHO1) * (ALPHA / OMEGA)
        CALL DAXPY(N, -OMEGA, W(1, V), 1, W(1, P), 1)
        CALL DSCAL(N, BETA, W(1, P), 1)
        CALL DAXPY(N, ONE, W(1, R), 1, W(1, P), 1)
    ELSE
        CALL DCOPY(N, W(1, R), 1, W(1, P), 1)
    END IF
    
    ! Compute PHAT and ALPHA
    IF (ICNTL(3) .NE. 0) THEN
        ! Return for preconditioning
        IPOS = 2
        IACT = 3
        LOCY = PHAT
        LOCZ = P
        GO TO 1000
    ELSE
        CALL DCOPY(N, W(1, P), 1, W(1, PHAT), 1)
    END IF
    
70  CONTINUE
    ! Return for matrix-vector product
    IPOS = 3
    IACT = 2
    LOCY = V
    LOCZ = PHAT
    GO TO 1000
    
80  CONTINUE
    ALPHA = RHO / DDOT(N, W(1, RTLD), 1, W(1, V), 1)
    
    ! Early check for tolerance
    CALL DAXPY(N, -ALPHA, W(1, V), 1, W(1, R), 1)
    ! Note: R=1 and S=1, so no copy needed
    CALL DAXPY(N, ALPHA, W(1, PHAT), 1, W(1, X), 1)
    
    RESID = DNRM2(N, W(1, S), 1)
    IPOS = 4
    IF (ICNTL(4) .NE. 0) THEN
        IACT = 1
        GO TO 1000
    ELSE
        IF (RESID .LE. MAX(CNTL(2), RSTOP * CNTL(1))) THEN
            IACT = 1
            GO TO 1000
        END IF
    END IF
    
90  CONTINUE
    ! Compute SHAT and OMEGA
    IF (ICNTL(3) .NE. 0) THEN
        IPOS = 5
        IACT = 3
        LOCY = SHAT
        LOCZ = S
        GO TO 1000
    ELSE
        CALL DCOPY(N, W(1, S), 1, W(1, SHAT), 1)
    END IF
    
100 CONTINUE
    ! Return for matrix-vector product
    IPOS = 6
    IACT = 2
    LOCY = T
    LOCZ = SHAT
    GO TO 1000
    
110 CONTINUE
    OMEGA = DDOT(N, W(1, T), 1, W(1, S), 1) / DDOT(N, W(1, T), 1, W(1, T), 1)
    
    ! Check OMEGA
    IF (ABS(OMEGA) .LT. CNTL(3) * N) THEN
        SNORM2 = DNRM2(N, W(1, S), 1)
        TNORM2 = DNRM2(N, W(1, T), 1)
        IF (ABS(RHO) .LT. CNTL(3) * SNORM2 / TNORM2) THEN
            INFO(1) = -3
            IACT = -1
            IF (ICNTL(1) .GT. 0) WRITE(ICNTL(1), FMT=9000) INFO(1)
            GO TO 1000
        END IF
    END IF
    
    ! Compute new X
    CALL DAXPY(N, OMEGA, W(1, SHAT), 1, W(1, X), 1)
    
    ! Compute residual R
    CALL DAXPY(N, -OMEGA, W(1, T), 1, W(1, R), 1)
    
    RESID = DNRM2(N, W(1, R), 1)
    IPOS = 7
    IF (ICNTL(4) .NE. 0) THEN
        IACT = 1
        GO TO 1000
    ELSE
        IF (RESID .LE. MAX(CNTL(2), RSTOP * CNTL(1))) THEN
            IACT = 1
            GO TO 1000
        END IF
    END IF
    
120 CONTINUE
    RHO1 = RHO
    ! Next iteration
    GO TO 60
    
    ! Save persistent data and return
1000 CONTINUE
    ISAVE(1)  = IPOS
    ISAVE(2)  = ITMAX
    ISAVE(3)  = B
    ISAVE(4)  = R
    ISAVE(5)  = X
    ISAVE(6)  = P
    ISAVE(7)  = S
    ISAVE(8)  = T
    ISAVE(9)  = V
    ISAVE(10) = PHAT
    ISAVE(11) = RTLD
    ISAVE(12) = SHAT
    
    RSAVE(1)  = BNRM2
    RSAVE(2)  = ALPHA
    RSAVE(3)  = BETA
    RSAVE(4)  = RHO
    RSAVE(5)  = RHO1
    RSAVE(6)  = RSTOP
    RSAVE(7)  = OMEGA
    RETURN
    
    ! Format statements
9000 FORMAT(/ ' Error message from MI26A/AD. INFO(1) = ', I4)
9010 FORMAT(/ ' Warning message from MI26A/AD. INFO(1) = ', I4)
9020 FORMAT(' Convergence tolerance out of range.')
9030 FORMAT(' Number of iterations required exceeds the maximum of ', &
            I8, / ' allowed by ICNTL(6)')
    
END SUBROUTINE MI26AD