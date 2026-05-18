! LEGACY THIRD-PARTY (UFC_命名规范_v3.0 §10.1):
!   Module name `ModuleLapack` does not follow UFC layer prefix convention.
!   This is a LAPACK wrapper; not renamed to avoid breaking external API.
MODULE ModuleLapack
    USE ModuleBlas, ONLY: DAXPY, DCOPY, DDOT, DGEMV, DSCAL, IDAMAX, DASUM, &
        DGBMV, DGEMM, DGER, DROT, DSWAP, DSYMV, DTRMV, DTRSV, DNRM2
    ! Note: LSAME and XERBLA are defined locally in this module
    ! LAPACK Դ ģ - LAPACK ӳ
    PUBLIC

CONTAINS


! ===== Begin dgbsv.f90 =====

SUBROUTINE DGBSV( N, KL, KU, NRHS, AB, LDAB, IPIV, B, LDB, INFO )
!
!  -- LAPACK driver routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
INTEGER            INFO, KL, KU, LDAB, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   AB( LDAB, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DGBSV computes the solution to a real system of linear equations
!  A * X = B, where A is a band matrix of order N with KL subdiagonals
!  and KU superdiagonals, and X and B are N-by-NRHS matrices.
!
!  The LU decomposition with partial pivoting and row interchanges is
!  used to factor A as A = L * U, where L is a product of permutation
!  and unit lower triangular matrices with KL subdiagonals, and U is
!  upper triangular with KL+KU superdiagonals.  The factored form of A
!  is then used to solve the system of equations A * X = B.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of linear equations, i.e., the order of the
!          matrix A.  N >= 0.
!
!  KL      (input) INTEGER
!          The number of subdiagonals within the band of A.  KL >= 0.
!
!  KU      (input) INTEGER
!          The number of superdiagonals within the band of A.  KU >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  AB      (input/output) DOUBLE PRECISION array, dimension (LDAB,N)
!          On entry, the matrix A in band storage, in rows KL+1 to
!          2*KL+KU+1; rows 1 to KL of the array need not be set.
!          The j-th column of A is stored in the j-th column of the
!          array AB as follows:
!          AB(KL+KU+1+i-j,j) = A(i,j) for max(1,j-KU)<=i<=min(N,j+KL)
!          On exit, details of the factorization: U is stored as an
!          upper triangular band matrix with KL+KU superdiagonals in
!          rows 1 to KL+KU+1, and the multipliers used during the
!          factorization are stored in rows KL+KU+2 to 2*KL+KU+1.
!          See below for further details.
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= 2*KL+KU+1.
!
!  IPIV    (output) INTEGER array, dimension (N)
!          The pivot indices that define the permutation matrix P;
!          row i of the matrix was interchanged with row IPIV(i).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the N-by-NRHS right hand side matrix B.
!          On exit, if INFO = 0, the N-by-NRHS solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, U(i,i) is exactly zero.  The factorization
!                has been completed, but the factor U is exactly
!                singular, and the solution has not been computed.
!
!  Further Details
!  ===============
!
!  The band storage scheme is illustrated by the following example, when
!  M = N = 6, KL = 2, KU = 1:
!
!  On entry:                       On exit:
!
!      *    *    *    +    +    +       *    *    *   u14  u25  u36
!      *    *    +    +    +    +       *    *   u13  u24  u35  u46
!      *   a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
!     a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
!     a21  a32  a43  a54  a65   *      m21  m32  m43  m54  m65   *
!     a31  a42  a53  a64   *    *      m31  m42  m53  m64   *    *
!
!  Array elements marked * are not used by the routine; elements marked
!  + need not be set on entry, but are required by the routine to store
!  elements of U because of fill-in resulting from the row interchanges.
!
!  =====================================================================
!
!     .. External Subroutines ..
EXTERNAL           DGBTRF, DGBTRS, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
IF( N.LT.0 ) THEN
   INFO = -1
ELSE IF( KL.LT.0 ) THEN
   INFO = -2
ELSE IF( KU.LT.0 ) THEN
   INFO = -3
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -4
ELSE IF( LDAB.LT.2*KL+KU+1 ) THEN
   INFO = -6
ELSE IF( LDB.LT.MAX( N, 1 ) ) THEN
   INFO = -9
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGBSV ', -INFO )
   RETURN
END IF
!
!     Compute the LU factorization of the band matrix A.
!
CALL DGBTRF( N, N, KL, KU, AB, LDAB, IPIV, INFO )
IF( INFO.EQ.0 ) THEN
!
!        Solve the system A*X = B, overwriting B with X.
!
   CALL DGBTRS( 'No transpose', N, KL, KU, NRHS, AB, LDAB, IPIV, &
                    B, LDB, INFO )
END IF
RETURN
!
!     End of DGBSV
!
end subroutine dgbsv

! ===== End dgbsv.f90 =====


! ===== Begin dgbtf2.f90 =====

SUBROUTINE DGBTF2( M, N, KL, KU, AB, LDAB, IPIV, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            INFO, KL, KU, LDAB, M, N
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   AB( LDAB, * )
!     ..
!
!  Purpose
!  =======
!
!  DGBTF2 computes an LU factorization of a real m-by-n band matrix A
!  using partial pivoting with row interchanges.
!
!  This is the unblocked version of the algorithm, calling Level 2 BLAS.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  KL      (input) INTEGER
!          The number of subdiagonals within the band of A.  KL >= 0.
!
!  KU      (input) INTEGER
!          The number of superdiagonals within the band of A.  KU >= 0.
!
!  AB      (input/output) DOUBLE PRECISION array, dimension (LDAB,N)
!          On entry, the matrix A in band storage, in rows KL+1 to
!          2*KL+KU+1; rows 1 to KL of the array need not be set.
!          The j-th column of A is stored in the j-th column of the
!          array AB as follows:
!          AB(kl+ku+1+i-j,j) = A(i,j) for max(1,j-ku)<=i<=min(m,j+kl)
!
!          On exit, details of the factorization: U is stored as an
!          upper triangular band matrix with KL+KU superdiagonals in
!          rows 1 to KL+KU+1, and the multipliers used during the
!          factorization are stored in rows KL+KU+2 to 2*KL+KU+1.
!          See below for further details.
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= 2*KL+KU+1.
!
!  IPIV    (output) INTEGER array, dimension (min(M,N))
!          The pivot indices; for 1 <= i <= min(M,N), row i of the
!          matrix was interchanged with row IPIV(i).
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!          > 0: if INFO = +i, U(i,i) is exactly zero. The factorization
!               has been completed, but the factor U is exactly
!               singular, and division by zero will occur if it is used
!               to solve a system of equations.
!
!  Further Details
!  ===============
!
!  The band storage scheme is illustrated by the following example, when
!  M = N = 6, KL = 2, KU = 1:
!
!  On entry:                       On exit:
!
!      *    *    *    +    +    +       *    *    *   u14  u25  u36
!      *    *    +    +    +    +       *    *   u13  u24  u35  u46
!      *   a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
!     a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
!     a21  a32  a43  a54  a65   *      m21  m32  m43  m54  m65   *
!     a31  a42  a53  a64   *    *      m31  m42  m53  m64   *    *
!
!  Array elements marked * are not used by the routine; elements marked
!  + need not be set on entry, but are required by the routine to store
!  elements of U, because of fill-in resulting from the row
!  interchanges.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, J, JP, JU, KM, KV
!     ..
!     .. External Functions ..
INTEGER            IDAMAX
EXTERNAL           IDAMAX
!     ..
!     .. External Subroutines ..
EXTERNAL           DGER, DSCAL, DSWAP, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     KV is the number of superdiagonals in the factor U, allowing for
!     fill-in.
!
KV = KU + KL
!
!     Test the input parameters.
!
INFO = 0
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( KL.LT.0 ) THEN
   INFO = -3
ELSE IF( KU.LT.0 ) THEN
   INFO = -4
ELSE IF( LDAB.LT.KL+KV+1 ) THEN
   INFO = -6
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGBTF2', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( M.EQ.0 .OR. N.EQ.0 ) &
       RETURN
!
!     Gaussian elimination with partial pivoting
!
!     Set fill-in elements in columns KU+2 to KV to zero.
!
DO 20 J = KU + 2, MIN( KV, N )
   DO 10 I = KV - J + 2, KL
      AB( I, J ) = ZERO
10    CONTINUE
20 CONTINUE
!
!     JU is the index of the last column affected by the current stage
!     of the factorization.
!
JU = 1
!
DO 40 J = 1, MIN( M, N )
!
!        Set fill-in elements in column J+KV to zero.
!
   IF( J+KV.LE.N ) THEN
      DO 30 I = 1, KL
         AB( I, J+KV ) = ZERO
30       CONTINUE
   END IF
!
!        Find pivot and test for singularity. KM is the number of
!        subdiagonal elements in the current column.
!
   KM = MIN( KL, M-J )
   JP = IDAMAX( KM+1, AB( KV+1, J ), 1 )
   IPIV( J ) = JP + J - 1
   IF( AB( KV+JP, J ).NE.ZERO ) THEN
      JU = MAX( JU, MIN( J+KU+JP-1, N ) )
!
!           Apply interchange to columns J to JU.
!
      IF( JP.NE.1 ) &
             CALL DSWAP( JU-J+1, AB( KV+JP, J ), LDAB-1, &
                         AB( KV+1, J ), LDAB-1 )
!
      IF( KM.GT.0 ) THEN
!
!              Compute multipliers.
!
         CALL DSCAL( KM, ONE / AB( KV+1, J ), AB( KV+2, J ), 1 )
!
!              Update trailing submatrix within the band.
!
         IF( JU.GT.J ) &
                CALL DGER( KM, JU-J, -ONE, AB( KV+2, J ), 1, &
                           AB( KV, J+1 ), LDAB-1, AB( KV+1, J+1 ), &
                           LDAB-1 )
      END IF
   ELSE
!
!           If pivot is zero, set INFO to the index of the pivot
!           unless a zero pivot has already been found.
!
      IF( INFO.EQ.0 ) &
             INFO = J
   END IF
40 CONTINUE
RETURN
!
!     End of DGBTF2
!
end subroutine dgbtf2

! ===== End dgbtf2.f90 =====


! ===== Begin dgbtrf.f90 =====

SUBROUTINE DGBTRF( M, N, KL, KU, AB, LDAB, IPIV, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            INFO, KL, KU, LDAB, M, N
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   AB( LDAB, * )
!     ..
!
!  Purpose
!  =======
!
!  DGBTRF computes an LU factorization of a real m-by-n band matrix A
!  using partial pivoting with row interchanges.
!
!  This is the blocked version of the algorithm, calling Level 3 BLAS.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  KL      (input) INTEGER
!          The number of subdiagonals within the band of A.  KL >= 0.
!
!  KU      (input) INTEGER
!          The number of superdiagonals within the band of A.  KU >= 0.
!
!  AB      (input/output) DOUBLE PRECISION array, dimension (LDAB,N)
!          On entry, the matrix A in band storage, in rows KL+1 to
!          2*KL+KU+1; rows 1 to KL of the array need not be set.
!          The j-th column of A is stored in the j-th column of the
!          array AB as follows:
!          AB(kl+ku+1+i-j,j) = A(i,j) for max(1,j-ku)<=i<=min(m,j+kl)
!
!          On exit, details of the factorization: U is stored as an
!          upper triangular band matrix with KL+KU superdiagonals in
!          rows 1 to KL+KU+1, and the multipliers used during the
!          factorization are stored in rows KL+KU+2 to 2*KL+KU+1.
!          See below for further details.
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= 2*KL+KU+1.
!
!  IPIV    (output) INTEGER array, dimension (min(M,N))
!          The pivot indices; for 1 <= i <= min(M,N), row i of the
!          matrix was interchanged with row IPIV(i).
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!          > 0: if INFO = +i, U(i,i) is exactly zero. The factorization
!               has been completed, but the factor U is exactly
!               singular, and division by zero will occur if it is used
!               to solve a system of equations.
!
!  Further Details
!  ===============
!
!  The band storage scheme is illustrated by the following example, when
!  M = N = 6, KL = 2, KU = 1:
!
!  On entry:                       On exit:
!
!      *    *    *    +    +    +       *    *    *   u14  u25  u36
!      *    *    +    +    +    +       *    *   u13  u24  u35  u46
!      *   a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
!     a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
!     a21  a32  a43  a54  a65   *      m21  m32  m43  m54  m65   *
!     a31  a42  a53  a64   *    *      m31  m42  m53  m64   *    *
!
!  Array elements marked * are not used by the routine; elements marked
!  + need not be set on entry, but are required by the routine to store
!  elements of U because of fill-in resulting from the row interchanges.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
INTEGER            NBMAX, LDWORK
PARAMETER          ( NBMAX = 64, LDWORK = NBMAX+1 )
!     ..
!     .. Local Scalars ..
INTEGER            I, I2, I3, II, IP, J, J2, J3, JB, JJ, JM, JP, &
                       JU, K2, KM, KV, NB, NW
DOUBLE PRECISION   TEMP
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   WORK13( LDWORK, NBMAX ), &
                       WORK31( LDWORK, NBMAX )
!     ..
!     .. External Functions ..
INTEGER            IDAMAX, ILAENV
EXTERNAL           IDAMAX, ILAENV
!     ..
!     .. External Subroutines ..
EXTERNAL           DCOPY, DGBTF2, DGEMM, DGER, DLASWP, DSCAL, &
                       DSWAP, DTRSM, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     KV is the number of superdiagonals in the factor U, allowing for
!     fill-in
!
KV = KU + KL
!
!     Test the input parameters.
!
INFO = 0
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( KL.LT.0 ) THEN
   INFO = -3
ELSE IF( KU.LT.0 ) THEN
   INFO = -4
ELSE IF( LDAB.LT.KL+KV+1 ) THEN
   INFO = -6
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGBTRF', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( M.EQ.0 .OR. N.EQ.0 ) &
       RETURN
!
!     Determine the block size for this environment
!
NB = ILAENV( 1, 'DGBTRF', ' ', M, N, KL, KU )
!
!     The block size must not exceed the limit set by the size of the
!     local arrays WORK13 and WORK31.
!
NB = MIN( NB, NBMAX )
!
IF( NB.LE.1 .OR. NB.GT.KL ) THEN
!
!        Use unblocked code
!
   CALL DGBTF2( M, N, KL, KU, AB, LDAB, IPIV, INFO )
ELSE
!
!        Use blocked code
!
!        Zero the superdiagonal elements of the work array WORK13
!
   DO 20 J = 1, NB
      DO 10 I = 1, J - 1
         WORK13( I, J ) = ZERO
10       CONTINUE
20    CONTINUE
!
!        Zero the subdiagonal elements of the work array WORK31
!
   DO 40 J = 1, NB
      DO 30 I = J + 1, NB
         WORK31( I, J ) = ZERO
30       CONTINUE
40    CONTINUE
!
!        Gaussian elimination with partial pivoting
!
!        Set fill-in elements in columns KU+2 to KV to zero
!
   DO 60 J = KU + 2, MIN( KV, N )
      DO 50 I = KV - J + 2, KL
         AB( I, J ) = ZERO
50       CONTINUE
60    CONTINUE
!
!        JU is the index of the last column affected by the current
!        stage of the factorization
!
   JU = 1
!
   DO 180 J = 1, MIN( M, N ), NB
      JB = MIN( NB, MIN( M, N )-J+1 )
!
!           The active part of the matrix is partitioned
!
!              A11   A12   A13
!              A21   A22   A23
!              A31   A32   A33
!
!           Here A11, A21 and A31 denote the current block of JB columns
!           which is about to be factorized. The number of rows in the
!           partitioning are JB, I2, I3 respectively, and the numbers
!           of columns are JB, J2, J3. The superdiagonal elements of A13
!           and the subdiagonal elements of A31 lie outside the band.
!
      I2 = MIN( KL-JB, M-J-JB+1 )
      I3 = MIN( JB, M-J-KL+1 )
!
!           J2 and J3 are computed after JU has been updated.
!
!           Factorize the current block of JB columns
!
      DO 80 JJ = J, J + JB - 1
!
!              Set fill-in elements in column JJ+KV to zero
!
         IF( JJ+KV.LE.N ) THEN
            DO 70 I = 1, KL
               AB( I, JJ+KV ) = ZERO
70             CONTINUE
         END IF
!
!              Find pivot and test for singularity. KM is the number of
!              subdiagonal elements in the current column.
!
         KM = MIN( KL, M-JJ )
         JP = IDAMAX( KM+1, AB( KV+1, JJ ), 1 )
         IPIV( JJ ) = JP + JJ - J
         IF( AB( KV+JP, JJ ).NE.ZERO ) THEN
            JU = MAX( JU, MIN( JJ+KU+JP-1, N ) )
            IF( JP.NE.1 ) THEN
!
!                    Apply interchange to columns J to J+JB-1
!
               IF( JP+JJ-1.LT.J+KL ) THEN
!
                  CALL DSWAP( JB, AB( KV+1+JJ-J, J ), LDAB-1, &
                                  AB( KV+JP+JJ-J, J ), LDAB-1 )
               ELSE
!
!                       The interchange affects columns J to JJ-1 of A31
!                       which are stored in the work array WORK31
!
                  CALL DSWAP( JJ-J, AB( KV+1+JJ-J, J ), LDAB-1, &
                                  WORK31( JP+JJ-J-KL, 1 ), LDWORK )
                  CALL DSWAP( J+JB-JJ, AB( KV+1, JJ ), LDAB-1, &
                                  AB( KV+JP, JJ ), LDAB-1 )
               END IF
            END IF
!
!                 Compute multipliers
!
            CALL DSCAL( KM, ONE / AB( KV+1, JJ ), AB( KV+2, JJ ), &
                            1 )
!
!                 Update trailing submatrix within the band and within
!                 the current block. JM is the index of the last column
!                 which needs to be updated.
!
            JM = MIN( JU, J+JB-1 )
            IF( JM.GT.JJ ) &
                   CALL DGER( KM, JM-JJ, -ONE, AB( KV+2, JJ ), 1, &
                              AB( KV, JJ+1 ), LDAB-1, &
                              AB( KV+1, JJ+1 ), LDAB-1 )
         ELSE
!
!                 If pivot is zero, set INFO to the index of the pivot
!                 unless a zero pivot has already been found.
!
            IF( INFO.EQ.0 ) &
                   INFO = JJ
         END IF
!
!              Copy current column of A31 into the work array WORK31
!
         NW = MIN( JJ-J+1, I3 )
         IF( NW.GT.0 ) &
                CALL DCOPY( NW, AB( KV+KL+1-JJ+J, JJ ), 1, &
                            WORK31( 1, JJ-J+1 ), 1 )
80       CONTINUE
      IF( J+JB.LE.N ) THEN
!
!              Apply the row interchanges to the other blocks.
!
         J2 = MIN( JU-J+1, KV ) - JB
         J3 = MAX( 0, JU-J-KV+1 )
!
!              Use DLASWP to apply the row interchanges to A12, A22, and
!              A32.
!
         CALL DLASWP( J2, AB( KV+1-JB, J+JB ), LDAB-1, 1, JB, &
                          IPIV( J ), 1 )
!
!              Adjust the pivot indices.
!
         DO 90 I = J, J + JB - 1
            IPIV( I ) = IPIV( I ) + J - 1
90          CONTINUE
!
!              Apply the row interchanges to A13, A23, and A33
!              columnwise.
!
         K2 = J - 1 + JB + J2
         DO 110 I = 1, J3
            JJ = K2 + I
            DO 100 II = J + I - 1, J + JB - 1
               IP = IPIV( II )
               IF( IP.NE.II ) THEN
                  TEMP = AB( KV+1+II-JJ, JJ )
                  AB( KV+1+II-JJ, JJ ) = AB( KV+1+IP-JJ, JJ )
                  AB( KV+1+IP-JJ, JJ ) = TEMP
               END IF
100             CONTINUE
110          CONTINUE
!
!              Update the relevant part of the trailing submatrix
!
         IF( J2.GT.0 ) THEN
!
!                 Update A12
!
            CALL DTRSM( 'Left', 'Lower', 'No transpose', 'Unit', &
                            JB, J2, ONE, AB( KV+1, J ), LDAB-1, &
                            AB( KV+1-JB, J+JB ), LDAB-1 )
!
            IF( I2.GT.0 ) THEN
!
!                    Update A22
!
               CALL DGEMM( 'No transpose', 'No transpose', I2, J2, &
                               JB, -ONE, AB( KV+1+JB, J ), LDAB-1, &
                               AB( KV+1-JB, J+JB ), LDAB-1, ONE, &
                               AB( KV+1, J+JB ), LDAB-1 )
            END IF
!
            IF( I3.GT.0 ) THEN
!
!                    Update A32
!
               CALL DGEMM( 'No transpose', 'No transpose', I3, J2, &
                               JB, -ONE, WORK31, LDWORK, &
                               AB( KV+1-JB, J+JB ), LDAB-1, ONE, &
                               AB( KV+KL+1-JB, J+JB ), LDAB-1 )
            END IF
         END IF
!
         IF( J3.GT.0 ) THEN
!
!                 Copy the lower triangle of A13 into the work array
!                 WORK13
!
            DO 130 JJ = 1, J3
               DO 120 II = JJ, JB
                  WORK13( II, JJ ) = AB( II-JJ+1, JJ+J+KV-1 )
120                CONTINUE
130             CONTINUE
!
!                 Update A13 in the work array
!
            CALL DTRSM( 'Left', 'Lower', 'No transpose', 'Unit', &
                            JB, J3, ONE, AB( KV+1, J ), LDAB-1, &
                            WORK13, LDWORK )
!
            IF( I2.GT.0 ) THEN
!
!                    Update A23
!
               CALL DGEMM( 'No transpose', 'No transpose', I2, J3, &
                               JB, -ONE, AB( KV+1+JB, J ), LDAB-1, &
                               WORK13, LDWORK, ONE, AB( 1+JB, J+KV ), &
                               LDAB-1 )
            END IF
!
            IF( I3.GT.0 ) THEN
!
!                    Update A33
!
               CALL DGEMM( 'No transpose', 'No transpose', I3, J3, &
                               JB, -ONE, WORK31, LDWORK, WORK13, &
                               LDWORK, ONE, AB( 1+KL, J+KV ), LDAB-1 )
            END IF
!
!                 Copy the lower triangle of A13 back into place
!
            DO 150 JJ = 1, J3
               DO 140 II = JJ, JB
                  AB( II-JJ+1, JJ+J+KV-1 ) = WORK13( II, JJ )
140                CONTINUE
150             CONTINUE
         END IF
      ELSE
!
!              Adjust the pivot indices.
!
         DO 160 I = J, J + JB - 1
            IPIV( I ) = IPIV( I ) + J - 1
160          CONTINUE
      END IF
!
!           Partially undo the interchanges in the current block to
!           restore the upper triangular form of A31 and copy the upper
!           triangle of A31 back into place
!
      DO 170 JJ = J + JB - 1, J, -1
         JP = IPIV( JJ ) - JJ + 1
         IF( JP.NE.1 ) THEN
!
!                 Apply interchange to columns J to JJ-1
!
            IF( JP+JJ-1.LT.J+KL ) THEN
!
!                    The interchange does not affect A31
!
               CALL DSWAP( JJ-J, AB( KV+1+JJ-J, J ), LDAB-1, &
                               AB( KV+JP+JJ-J, J ), LDAB-1 )
            ELSE
!
!                    The interchange does affect A31
!
               CALL DSWAP( JJ-J, AB( KV+1+JJ-J, J ), LDAB-1, &
                               WORK31( JP+JJ-J-KL, 1 ), LDWORK )
            END IF
         END IF
!
!              Copy the current column of A31 back into place
!
         NW = MIN( I3, JJ-J+1 )
         IF( NW.GT.0 ) &
                CALL DCOPY( NW, WORK31( 1, JJ-J+1 ), 1, &
                            AB( KV+KL+1-JJ+J, JJ ), 1 )
170       CONTINUE
180    CONTINUE
END IF
!
RETURN
!
!     End of DGBTRF
!
end subroutine dgbtrf

! ===== End dgbtrf.f90 =====


! ===== Begin dgbtrs.f90 =====

SUBROUTINE DGBTRS( TRANS, N, KL, KU, NRHS, AB, LDAB, IPIV, B, LDB, &
                       INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
CHARACTER          TRANS
INTEGER            INFO, KL, KU, LDAB, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   AB( LDAB, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DGBTRS solves a system of linear equations
!     A * X = B  or  A' * X = B
!  with a general band matrix A using the LU factorization computed
!  by DGBTRF.
!
!  Arguments
!  =========
!
!  TRANS   (input) CHARACTER*1
!          Specifies the form of the system of equations.
!          = 'N':  A * X = B  (No transpose)
!          = 'T':  A'* X = B  (Transpose)
!          = 'C':  A'* X = B  (Conjugate transpose = Transpose)
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  KL      (input) INTEGER
!          The number of subdiagonals within the band of A.  KL >= 0.
!
!  KU      (input) INTEGER
!          The number of superdiagonals within the band of A.  KU >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  AB      (input) DOUBLE PRECISION array, dimension (LDAB,N)
!          Details of the LU factorization of the band matrix A, as
!          computed by DGBTRF.  U is stored as an upper triangular band
!          matrix with KL+KU superdiagonals in rows 1 to KL+KU+1, and
!          the multipliers used during the factorization are stored in
!          rows KL+KU+2 to 2*KL+KU+1.
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= 2*KL+KU+1.
!
!  IPIV    (input) INTEGER array, dimension (N)
!          The pivot indices; for 1 <= i <= N, row i of the matrix was
!          interchanged with row IPIV(i).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the right hand side matrix B.
!          On exit, the solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LNOTI, NOTRAN
INTEGER            I, J, KD, L, LM
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMV, DGER, DSWAP, DTBSV, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
NOTRAN = LSAME( TRANS, 'N' )
IF( .NOT.NOTRAN .AND. .NOT.LSAME( TRANS, 'T' ) .AND. .NOT. &
        LSAME( TRANS, 'C' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( KL.LT.0 ) THEN
   INFO = -3
ELSE IF( KU.LT.0 ) THEN
   INFO = -4
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -5
ELSE IF( LDAB.LT.( 2*KL+KU+1 ) ) THEN
   INFO = -7
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -10
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGBTRS', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 .OR. NRHS.EQ.0 ) &
       RETURN
!
KD = KU + KL + 1
LNOTI = KL.GT.0
!
IF( NOTRAN ) THEN
!
!        Solve  A*X = B.
!
!        Solve L*X = B, overwriting B with X.
!
!        L is represented as a product of permutations and unit lower
!        triangular matrices L = P(1) * L(1) * ... * P(n-1) * L(n-1),
!        where each transformation L(i) is a rank-one modification of
!        the identity matrix.
!
   IF( LNOTI ) THEN
      DO 10 J = 1, N - 1
         LM = MIN( KL, N-J )
         L = IPIV( J )
         IF( L.NE.J ) &
                CALL DSWAP( NRHS, B( L, 1 ), LDB, B( J, 1 ), LDB )
         CALL DGER( LM, NRHS, -ONE, AB( KD+1, J ), 1, B( J, 1 ), &
                        LDB, B( J+1, 1 ), LDB )
10       CONTINUE
   END IF
!
   DO 20 I = 1, NRHS
!
!           Solve U*X = B, overwriting B with X.
!
      CALL DTBSV( 'Upper', 'No transpose', 'Non-unit', N, KL+KU, &
                      AB, LDAB, B( 1, I ), 1 )
20    CONTINUE
!
ELSE
!
!        Solve A'*X = B.
!
   DO 30 I = 1, NRHS
!
!           Solve U'*X = B, overwriting B with X.
!
      CALL DTBSV( 'Upper', 'Transpose', 'Non-unit', N, KL+KU, AB, &
                      LDAB, B( 1, I ), 1 )
30    CONTINUE
!
!        Solve L'*X = B, overwriting B with X.
!
   IF( LNOTI ) THEN
      DO 40 J = N - 1, 1, -1
         LM = MIN( KL, N-J )
         CALL DGEMV( 'Transpose', LM, NRHS, -ONE, B( J+1, 1 ), &
                         LDB, AB( KD+1, J ), 1, ONE, B( J, 1 ), LDB )
         L = IPIV( J )
         IF( L.NE.J ) &
                CALL DSWAP( NRHS, B( L, 1 ), LDB, B( J, 1 ), LDB )
40       CONTINUE
   END IF
END IF
RETURN
!
!     End of DGBTRS
!
end subroutine dgbtrs

! ===== End dgbtrs.f90 =====


! ===== Begin dgebak.f90 =====

SUBROUTINE DGEBAK( JOB, SIDE, N, ILO, IHI, SCALE, M, V, LDV, &
                       INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER          JOB, SIDE
INTEGER            IHI, ILO, INFO, LDV, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   SCALE( * ), V( LDV, * )
!     ..
!
!  Purpose
!  =======
!
!  DGEBAK forms the right or left eigenvectors of a real general matrix
!  by backward transformation on the computed eigenvectors of the
!  balanced matrix output by DGEBAL.
!
!  Arguments
!  =========
!
!  JOB     (input) CHARACTER*1
!          Specifies the type of backward transformation required:
!          = 'N', do nothing, return immediately;
!          = 'P', do backward transformation for permutation only;
!          = 'S', do backward transformation for scaling only;
!          = 'B', do backward transformations for both permutation and
!                 scaling.
!          JOB must be the same as the argument JOB supplied to DGEBAL.
!
!  SIDE    (input) CHARACTER*1
!          = 'R':  V contains right eigenvectors;
!          = 'L':  V contains left eigenvectors.
!
!  N       (input) INTEGER
!          The number of rows of the matrix V.  N >= 0.
!
!  ILO     (input) INTEGER
!  IHI     (input) INTEGER
!          The integers ILO and IHI determined by DGEBAL.
!          1 <= ILO <= IHI <= N, if N > 0; ILO=1 and IHI=0, if N=0.
!
!  SCALE   (input) DOUBLE PRECISION array, dimension (N)
!          Details of the permutation and scaling factors, as returned
!          by DGEBAL.
!
!  M       (input) INTEGER
!          The number of columns of the matrix V.  M >= 0.
!
!  V       (input/output) DOUBLE PRECISION array, dimension (LDV,M)
!          On entry, the matrix of right or left eigenvectors to be
!          transformed, as returned by DHSEIN or DTREVC.
!          On exit, V is overwritten by the transformed eigenvectors.
!
!  LDV     (input) INTEGER
!          The leading dimension of the array V. LDV >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LEFTV, RIGHTV
INTEGER            I, II, K
DOUBLE PRECISION   S
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DSCAL, DSWAP, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Decode and Test the input parameters
!
RIGHTV = LSAME( SIDE, 'R' )
LEFTV = LSAME( SIDE, 'L' )
!
INFO = 0
IF( .NOT.LSAME( JOB, 'N' ) .AND. .NOT.LSAME( JOB, 'P' ) .AND. &
        .NOT.LSAME( JOB, 'S' ) .AND. .NOT.LSAME( JOB, 'B' ) ) THEN
   INFO = -1
ELSE IF( .NOT.RIGHTV .AND. .NOT.LEFTV ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( ILO.LT.1 .OR. ILO.GT.MAX( 1, N ) ) THEN
   INFO = -4
ELSE IF( IHI.LT.MIN( ILO, N ) .OR. IHI.GT.N ) THEN
   INFO = -5
ELSE IF( M.LT.0 ) THEN
   INFO = -7
ELSE IF( LDV.LT.MAX( 1, N ) ) THEN
   INFO = -9
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGEBAK', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
IF( M.EQ.0 ) &
       RETURN
IF( LSAME( JOB, 'N' ) ) &
       RETURN
!
IF( ILO.EQ.IHI ) &
       GO TO 30
!
!     Backward balance
!
IF( LSAME( JOB, 'S' ) .OR. LSAME( JOB, 'B' ) ) THEN
!
   IF( RIGHTV ) THEN
      DO 10 I = ILO, IHI
         S = SCALE( I )
         CALL DSCAL( M, S, V( I, 1 ), LDV )
10       CONTINUE
   END IF
!
   IF( LEFTV ) THEN
      DO 20 I = ILO, IHI
         S = ONE / SCALE( I )
         CALL DSCAL( M, S, V( I, 1 ), LDV )
20       CONTINUE
   END IF
!
END IF
!
!     Backward permutation
!
!     For  I = ILO-1 step -1 until 1,
!              IHI+1 step 1 until N do --
!
30 CONTINUE
IF( LSAME( JOB, 'P' ) .OR. LSAME( JOB, 'B' ) ) THEN
   IF( RIGHTV ) THEN
      DO 40 II = 1, N
         I = II
         IF( I.GE.ILO .AND. I.LE.IHI ) &
                GO TO 40
         IF( I.LT.ILO ) &
                I = ILO - II
         K = SCALE( I )
         IF( K.EQ.I ) &
                GO TO 40
         CALL DSWAP( M, V( I, 1 ), LDV, V( K, 1 ), LDV )
40       CONTINUE
   END IF
!
   IF( LEFTV ) THEN
      DO 50 II = 1, N
         I = II
         IF( I.GE.ILO .AND. I.LE.IHI ) &
                GO TO 50
         IF( I.LT.ILO ) &
                I = ILO - II
         K = SCALE( I )
         IF( K.EQ.I ) &
                GO TO 50
         CALL DSWAP( M, V( I, 1 ), LDV, V( K, 1 ), LDV )
50       CONTINUE
   END IF
END IF
!
RETURN
!
!     End of DGEBAK
!
end subroutine dgebak

! ===== End dgebak.f90 =====


! ===== Begin dgebal.f90 =====

SUBROUTINE DGEBAL( JOB, N, A, LDA, ILO, IHI, SCALE, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
CHARACTER          JOB
INTEGER            IHI, ILO, INFO, LDA, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), SCALE( * )
!     ..
!
!  Purpose
!  =======
!
!  DGEBAL balances a general real matrix A.  This involves, first,
!  permuting A by a similarity transformation to isolate eigenvalues
!  in the first 1 to ILO-1 and last IHI+1 to N elements on the
!  diagonal; and second, applying a diagonal similarity transformation
!  to rows and columns ILO to IHI to make the rows and columns as
!  close in norm as possible.  Both steps are optional.
!
!  Balancing may reduce the 1-norm of the matrix, and improve the
!  accuracy of the computed eigenvalues and/or eigenvectors.
!
!  Arguments
!  =========
!
!  JOB     (input) CHARACTER*1
!          Specifies the operations to be performed on A:
!          = 'N':  none:  simply set ILO = 1, IHI = N, SCALE(I) = 1.0
!                  for i = 1,...,N;
!          = 'P':  permute only;
!          = 'S':  scale only;
!          = 'B':  both permute and scale.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the input matrix A.
!          On exit,  A is overwritten by the balanced matrix.
!          If JOB = 'N', A is not referenced.
!          See Further Details.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  ILO     (output) INTEGER
!  IHI     (output) INTEGER
!          ILO and IHI are set to integers such that on exit
!          A(i,j) = 0 if i > j and j = 1,...,ILO-1 or I = IHI+1,...,N.
!          If JOB = 'N' or 'S', ILO = 1 and IHI = N.
!
!  SCALE   (output) DOUBLE PRECISION array, dimension (N)
!          Details of the permutations and scaling factors applied to
!          A.  If P(j) is the index of the row and column interchanged
!          with row and column j and D(j) is the scaling factor
!          applied to row and column j, then
!          SCALE(j) = P(j)    for j = 1,...,ILO-1
!                   = D(j)    for j = ILO,...,IHI
!                   = P(j)    for j = IHI+1,...,N.
!          The order in which the interchanges are made is N to IHI+1,
!          then 1 to ILO-1.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit.
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!
!  Further Details
!  ===============
!
!  The permutations consist of row and column interchanges which put
!  the matrix in the form
!
!             ( T1   X   Y  )
!     P A P = (  0   B   Z  )
!             (  0   0   T2 )
!
!  where T1 and T2 are upper triangular matrices whose eigenvalues lie
!  along the diagonal.  The column indices ILO and IHI mark the starting
!  and ending columns of the submatrix B. Balancing consists of applying
!  a diagonal similarity transformation inv(D) * B * D to make the
!  1-norms of each row of B and its corresponding column nearly equal.
!  The output matrix is
!
!     ( T1     X*D          Y    )
!     (  0  inv(D)*B*D  inv(D)*Z ).
!     (  0      0           T2   )
!
!  Information about the permutations P and the diagonal matrix D is
!  returned in the vector SCALE.
!
!  This subroutine is based on the EISPACK routine BALANC.
!
!  Modified by Tzu-Yi Chen, Computer Science Division, University of
!    California at Berkeley, USA
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
DOUBLE PRECISION   SCLFAC
PARAMETER          ( SCLFAC = 0.8D+1 )
DOUBLE PRECISION   FACTOR
PARAMETER          ( FACTOR = 0.95D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            NOCONV
INTEGER            I, ICA, IEXC, IRA, J, K, L, M
DOUBLE PRECISION   C, CA, F, G, R, RA, S, SFMAX1, SFMAX2, SFMIN1, &
                       SFMIN2
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            IDAMAX
DOUBLE PRECISION   DLAMCH
EXTERNAL           LSAME, IDAMAX, DLAMCH
!     ..
!     .. External Subroutines ..
EXTERNAL           DSCAL, DSWAP, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters
!
INFO = 0
IF( .NOT.LSAME( JOB, 'N' ) .AND. .NOT.LSAME( JOB, 'P' ) .AND. &
        .NOT.LSAME( JOB, 'S' ) .AND. .NOT.LSAME( JOB, 'B' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -4
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGEBAL', -INFO )
   RETURN
END IF
!
K = 1
L = N
!
IF( N.EQ.0 ) &
       GO TO 210
!
IF( LSAME( JOB, 'N' ) ) THEN
   DO 10 I = 1, N
      SCALE( I ) = ONE
10    CONTINUE
   GO TO 210
END IF
!
IF( LSAME( JOB, 'S' ) ) &
       GO TO 120
!
!     Permutation to isolate eigenvalues if possible
!
GO TO 50
!
!     Row and column exchange.
!
20 CONTINUE
SCALE( M ) = J
IF( J.EQ.M ) &
       GO TO 30
!
CALL DSWAP( L, A( 1, J ), 1, A( 1, M ), 1 )
CALL DSWAP( N-K+1, A( J, K ), LDA, A( M, K ), LDA )
!
30 CONTINUE
GO TO ( 40, 80 )IEXC
!
!     Search for rows isolating an eigenvalue and push them down.
!
40 CONTINUE
IF( L.EQ.1 ) &
       GO TO 210
L = L - 1
!
50 CONTINUE
DO 70 J = L, 1, -1
!
   DO 60 I = 1, L
      IF( I.EQ.J ) &
             GO TO 60
      IF( A( J, I ).NE.ZERO ) &
             GO TO 70
60    CONTINUE
!
   M = L
   IEXC = 1
   GO TO 20
70 CONTINUE
!
GO TO 90
!
!     Search for columns isolating an eigenvalue and push them left.
!
80 CONTINUE
K = K + 1
!
90 CONTINUE
DO 110 J = K, L
!
   DO 100 I = K, L
      IF( I.EQ.J ) &
             GO TO 100
      IF( A( I, J ).NE.ZERO ) &
             GO TO 110
100    CONTINUE
!
   M = K
   IEXC = 2
   GO TO 20
110 CONTINUE
!
120 CONTINUE
DO 130 I = K, L
   SCALE( I ) = ONE
130 CONTINUE
!
IF( LSAME( JOB, 'P' ) ) &
       GO TO 210
!
!     Balance the submatrix in rows K to L.
!
!     Iterative loop for norm reduction
!
SFMIN1 = DLAMCH( 'S' ) / DLAMCH( 'P' )
SFMAX1 = ONE / SFMIN1
SFMIN2 = SFMIN1*SCLFAC
SFMAX2 = ONE / SFMIN2
140 CONTINUE
NOCONV = .FALSE.
!
DO 200 I = K, L
   C = ZERO
   R = ZERO
!
   DO 150 J = K, L
      IF( J.EQ.I ) &
             GO TO 150
      C = C + ABS( A( J, I ) )
      R = R + ABS( A( I, J ) )
150    CONTINUE
   ICA = IDAMAX( L, A( 1, I ), 1 )
   CA = ABS( A( ICA, I ) )
   IRA = IDAMAX( N-K+1, A( I, K ), LDA )
   RA = ABS( A( I, IRA+K-1 ) )
!
!        Guard against zero C or R due to underflow.
!
   IF( C.EQ.ZERO .OR. R.EQ.ZERO ) &
          GO TO 200
   G = R / SCLFAC
   F = ONE
   S = C + R
160    CONTINUE
   IF( C.GE.G .OR. MAX( F, C, CA ).GE.SFMAX2 .OR. &
           MIN( R, G, RA ).LE.SFMIN2 )GO TO 170
   F = F*SCLFAC
   C = C*SCLFAC
   CA = CA*SCLFAC
   R = R / SCLFAC
   G = G / SCLFAC
   RA = RA / SCLFAC
   GO TO 160
!
170    CONTINUE
   G = C / SCLFAC
180    CONTINUE
   IF( G.LT.R .OR. MAX( R, RA ).GE.SFMAX2 .OR. &
           MIN( F, C, G, CA ).LE.SFMIN2 )GO TO 190
   F = F / SCLFAC
   C = C / SCLFAC
   G = G / SCLFAC
   CA = CA / SCLFAC
   R = R*SCLFAC
   RA = RA*SCLFAC
   GO TO 180
!
!        Now balance.
!
190    CONTINUE
   IF( ( C+R ).GE.FACTOR*S ) &
          GO TO 200
   IF( F.LT.ONE .AND. SCALE( I ).LT.ONE ) THEN
      IF( F*SCALE( I ).LE.SFMIN1 ) &
             GO TO 200
   END IF
   IF( F.GT.ONE .AND. SCALE( I ).GT.ONE ) THEN
      IF( SCALE( I ).GE.SFMAX1 / F ) &
             GO TO 200
   END IF
   G = ONE / F
   SCALE( I ) = SCALE( I )*F
   NOCONV = .TRUE.
!
   CALL DSCAL( N-K+1, G, A( I, K ), LDA )
   CALL DSCAL( L, F, A( 1, I ), 1 )
!
200 CONTINUE
!
IF( NOCONV ) &
       GO TO 140
!
210 CONTINUE
ILO = K
IHI = L
!
RETURN
!
!     End of DGEBAL
!
end subroutine dgebal

! ===== End dgebal.f90 =====


! ===== Begin dgeev.f90 =====

SUBROUTINE DGEEV( JOBVL, JOBVR, N, A, LDA, WR, WI, VL, LDVL, VR, &
                      LDVR, WORK, LWORK, INFO )
!
!  -- LAPACK driver routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     December 8, 1999
!
!     .. Scalar Arguments ..
CHARACTER          JOBVL, JOBVR
INTEGER            INFO, LDA, LDVL, LDVR, LWORK, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), VL( LDVL, * ), VR( LDVR, * ), &
                       WI( * ), WORK( * ), WR( * )
!     ..
!
!  Purpose
!  =======
!
!  DGEEV computes for an N-by-N real nonsymmetric matrix A, the
!  eigenvalues and, optionally, the left and/or right eigenvectors.
!
!  The right eigenvector v(j) of A satisfies
!                   A * v(j) = lambda(j) * v(j)
!  where lambda(j) is its eigenvalue.
!  The left eigenvector u(j) of A satisfies
!                u(j)**H * A = lambda(j) * u(j)**H
!  where u(j)**H denotes the conjugate transpose of u(j).
!
!  The computed eigenvectors are normalized to have Euclidean norm
!  equal to 1 and largest component real.
!
!  Arguments
!  =========
!
!  JOBVL   (input) CHARACTER*1
!          = 'N': left eigenvectors of A are not computed;
!          = 'V': left eigenvectors of A are computed.
!
!  JOBVR   (input) CHARACTER*1
!          = 'N': right eigenvectors of A are not computed;
!          = 'V': right eigenvectors of A are computed.
!
!  N       (input) INTEGER
!          The order of the matrix A. N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the N-by-N matrix A.
!          On exit, A has been overwritten.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  WR      (output) DOUBLE PRECISION array, dimension (N)
!  WI      (output) DOUBLE PRECISION array, dimension (N)
!          WR and WI contain the real and imaginary parts,
!          respectively, of the computed eigenvalues.  Complex
!          conjugate pairs of eigenvalues appear consecutively
!          with the eigenvalue having the positive imaginary part
!          first.
!
!  VL      (output) DOUBLE PRECISION array, dimension (LDVL,N)
!          If JOBVL = 'V', the left eigenvectors u(j) are stored one
!          after another in the columns of VL, in the same order
!          as their eigenvalues.
!          If JOBVL = 'N', VL is not referenced.
!          If the j-th eigenvalue is real, then u(j) = VL(:,j),
!          the j-th column of VL.
!          If the j-th and (j+1)-st eigenvalues form a complex
!          conjugate pair, then u(j) = VL(:,j) + i*VL(:,j+1) and
!          u(j+1) = VL(:,j) - i*VL(:,j+1).
!
!  LDVL    (input) INTEGER
!          The leading dimension of the array VL.  LDVL >= 1; if
!          JOBVL = 'V', LDVL >= N.
!
!  VR      (output) DOUBLE PRECISION array, dimension (LDVR,N)
!          If JOBVR = 'V', the right eigenvectors v(j) are stored one
!          after another in the columns of VR, in the same order
!          as their eigenvalues.
!          If JOBVR = 'N', VR is not referenced.
!          If the j-th eigenvalue is real, then v(j) = VR(:,j),
!          the j-th column of VR.
!          If the j-th and (j+1)-st eigenvalues form a complex
!          conjugate pair, then v(j) = VR(:,j) + i*VR(:,j+1) and
!          v(j+1) = VR(:,j) - i*VR(:,j+1).
!
!  LDVR    (input) INTEGER
!          The leading dimension of the array VR.  LDVR >= 1; if
!          JOBVR = 'V', LDVR >= N.
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.  LWORK >= max(1,3*N), and
!          if JOBVL = 'V' or JOBVR = 'V', LWORK >= 4*N.  For good
!          performance, LWORK must generally be larger.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!          > 0:  if INFO = i, the QR algorithm failed to compute all the
!                eigenvalues, and no eigenvectors have been computed;
!                elements i+1:N of WR and WI contain eigenvalues which
!                have converged.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D0, ONE = 1.0D0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LQUERY, SCALEA, WANTVL, WANTVR
CHARACTER          SIDE
INTEGER            HSWORK, I, IBAL, IERR, IHI, ILO, ITAU, IWRK, K, &
                       MAXB, MAXWRK, MINWRK, NOUT
DOUBLE PRECISION   ANRM, BIGNUM, CS, CSCALE, EPS, R, SCL, SMLNUM, &
                       SN
!     ..
!     .. Local Arrays ..
LOGICAL            SELECT( 1 )
DOUBLE PRECISION   DUM( 1 )
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEBAK, DGEBAL, DGEHRD, DHSEQR, DLACPY, DLARTG, &
                       DLASCL, DORGHR, DROT, DSCAL, DTREVC, XERBLA
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            IDAMAX, ILAENV
DOUBLE PRECISION   DLAMCH, DLANGE, DLAPY2, DNRM2
EXTERNAL           LSAME, IDAMAX, ILAENV, DLAMCH, DLANGE, DLAPY2, &
                       DNRM2
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN, SQRT
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
LQUERY = ( LWORK.EQ.-1 )
WANTVL = LSAME( JOBVL, 'V' )
WANTVR = LSAME( JOBVR, 'V' )
IF( ( .NOT.WANTVL ) .AND. ( .NOT.LSAME( JOBVL, 'N' ) ) ) THEN
   INFO = -1
ELSE IF( ( .NOT.WANTVR ) .AND. ( .NOT.LSAME( JOBVR, 'N' ) ) ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -5
ELSE IF( LDVL.LT.1 .OR. ( WANTVL .AND. LDVL.LT.N ) ) THEN
   INFO = -9
ELSE IF( LDVR.LT.1 .OR. ( WANTVR .AND. LDVR.LT.N ) ) THEN
   INFO = -11
END IF
!
!     Compute workspace
!      (Note: Comments in the code beginning "Workspace:" describe the
!       minimal amount of workspace needed at that point in the code,
!       as well as the preferred amount for good performance.
!       NB refers to the optimal block size for the immediately
!       following subroutine, as returned by ILAENV.
!       HSWORK refers to the workspace preferred by DHSEQR, as
!       calculated below. HSWORK is computed assuming ILO=1 and IHI=N,
!       the worst case.)
!
MINWRK = 1
IF( INFO.EQ.0 .AND. ( LWORK.GE.1 .OR. LQUERY ) ) THEN
   MAXWRK = 2*N + N*ILAENV( 1, 'DGEHRD', ' ', N, 1, N, 0 )
   IF( ( .NOT.WANTVL ) .AND. ( .NOT.WANTVR ) ) THEN
      MINWRK = MAX( 1, 3*N )
      MAXB = MAX( ILAENV( 8, 'DHSEQR', 'EN', N, 1, N, -1 ), 2 )
      K = MIN( MAXB, N, MAX( 2, ILAENV( 4, 'DHSEQR', 'EN', N, 1, &
              N, -1 ) ) )
      HSWORK = MAX( K*( K+2 ), 2*N )
      MAXWRK = MAX( MAXWRK, N+1, N+HSWORK )
   ELSE
      MINWRK = MAX( 1, 4*N )
      MAXWRK = MAX( MAXWRK, 2*N+( N-1 )* &
                   ILAENV( 1, 'DORGHR', ' ', N, 1, N, -1 ) )
      MAXB = MAX( ILAENV( 8, 'DHSEQR', 'SV', N, 1, N, -1 ), 2 )
      K = MIN( MAXB, N, MAX( 2, ILAENV( 4, 'DHSEQR', 'SV', N, 1, &
              N, -1 ) ) )
      HSWORK = MAX( K*( K+2 ), 2*N )
      MAXWRK = MAX( MAXWRK, N+1, N+HSWORK )
      MAXWRK = MAX( MAXWRK, 4*N )
   END IF
   WORK( 1 ) = MAXWRK
END IF
IF( LWORK.LT.MINWRK .AND. .NOT.LQUERY ) THEN
   INFO = -13
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGEEV ', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Get machine constants
!
EPS = DLAMCH( 'P' )
SMLNUM = DLAMCH( 'S' )
BIGNUM = ONE / SMLNUM
CALL DLABAD( SMLNUM, BIGNUM )
SMLNUM = SQRT( SMLNUM ) / EPS
BIGNUM = ONE / SMLNUM
!
!     Scale A if max element outside range [SMLNUM,BIGNUM]
!
ANRM = DLANGE( 'M', N, N, A, LDA, DUM )
SCALEA = .FALSE.
IF( ANRM.GT.ZERO .AND. ANRM.LT.SMLNUM ) THEN
   SCALEA = .TRUE.
   CSCALE = SMLNUM
ELSE IF( ANRM.GT.BIGNUM ) THEN
   SCALEA = .TRUE.
   CSCALE = BIGNUM
END IF
IF( SCALEA ) &
       CALL DLASCL( 'G', 0, 0, ANRM, CSCALE, N, N, A, LDA, IERR )
!
!     Balance the matrix
!     (Workspace: need N)
!
IBAL = 1
CALL DGEBAL( 'B', N, A, LDA, ILO, IHI, WORK( IBAL ), IERR )
!
!     Reduce to upper Hessenberg form
!     (Workspace: need 3*N, prefer 2*N+N*NB)
!
ITAU = IBAL + N
IWRK = ITAU + N
CALL DGEHRD( N, ILO, IHI, A, LDA, WORK( ITAU ), WORK( IWRK ), &
                 LWORK-IWRK+1, IERR )
!
IF( WANTVL ) THEN
!
!        Want left eigenvectors
!        Copy Householder vectors to VL
!
   SIDE = 'L'
   CALL DLACPY( 'L', N, N, A, LDA, VL, LDVL )
!
!        Generate orthogonal matrix in VL
!        (Workspace: need 3*N-1, prefer 2*N+(N-1)*NB)
!
   CALL DORGHR( N, ILO, IHI, VL, LDVL, WORK( ITAU ), WORK( IWRK ), &
                    LWORK-IWRK+1, IERR )
!
!        Perform QR iteration, accumulating Schur vectors in VL
!        (Workspace: need N+1, prefer N+HSWORK (see comments) )
!
   IWRK = ITAU
   CALL DHSEQR( 'S', 'V', N, ILO, IHI, A, LDA, WR, WI, VL, LDVL, &
                    WORK( IWRK ), LWORK-IWRK+1, INFO )
!
   IF( WANTVR ) THEN
!
!           Want left and right eigenvectors
!           Copy Schur vectors to VR
!
      SIDE = 'B'
      CALL DLACPY( 'F', N, N, VL, LDVL, VR, LDVR )
   END IF
!
ELSE IF( WANTVR ) THEN
!
!        Want right eigenvectors
!        Copy Householder vectors to VR
!
   SIDE = 'R'
   CALL DLACPY( 'L', N, N, A, LDA, VR, LDVR )
!
!        Generate orthogonal matrix in VR
!        (Workspace: need 3*N-1, prefer 2*N+(N-1)*NB)
!
   CALL DORGHR( N, ILO, IHI, VR, LDVR, WORK( ITAU ), WORK( IWRK ), &
                    LWORK-IWRK+1, IERR )
!
!        Perform QR iteration, accumulating Schur vectors in VR
!        (Workspace: need N+1, prefer N+HSWORK (see comments) )
!
   IWRK = ITAU
   CALL DHSEQR( 'S', 'V', N, ILO, IHI, A, LDA, WR, WI, VR, LDVR, &
                    WORK( IWRK ), LWORK-IWRK+1, INFO )
!
ELSE
!
!        Compute eigenvalues only
!        (Workspace: need N+1, prefer N+HSWORK (see comments) )
!
   IWRK = ITAU
   CALL DHSEQR( 'E', 'N', N, ILO, IHI, A, LDA, WR, WI, VR, LDVR, &
                    WORK( IWRK ), LWORK-IWRK+1, INFO )
END IF
!
!     If INFO > 0 from DHSEQR, then quit
!
IF( INFO.GT.0 ) &
       GO TO 50
!
IF( WANTVL .OR. WANTVR ) THEN
!
!        Compute left and/or right eigenvectors
!        (Workspace: need 4*N)
!
   CALL DTREVC( SIDE, 'B', SELECT, N, A, LDA, VL, LDVL, VR, LDVR, &
                    N, NOUT, WORK( IWRK ), IERR )
END IF
!
IF( WANTVL ) THEN
!
!        Undo balancing of left eigenvectors
!        (Workspace: need N)
!
   CALL DGEBAK( 'B', 'L', N, ILO, IHI, WORK( IBAL ), N, VL, LDVL, &
                    IERR )
!
!        Normalize left eigenvectors and make largest component real
!
   DO 20 I = 1, N
      IF( WI( I ).EQ.ZERO ) THEN
         SCL = ONE / DNRM2( N, VL( 1, I ), 1 )
         CALL DSCAL( N, SCL, VL( 1, I ), 1 )
      ELSE IF( WI( I ).GT.ZERO ) THEN
         SCL = ONE / DLAPY2( DNRM2( N, VL( 1, I ), 1 ), &
                   DNRM2( N, VL( 1, I+1 ), 1 ) )
         CALL DSCAL( N, SCL, VL( 1, I ), 1 )
         CALL DSCAL( N, SCL, VL( 1, I+1 ), 1 )
         DO 10 K = 1, N
            WORK( IWRK+K-1 ) = VL( K, I )**2 + VL( K, I+1 )**2
10          CONTINUE
         K = IDAMAX( N, WORK( IWRK ), 1 )
         CALL DLARTG( VL( K, I ), VL( K, I+1 ), CS, SN, R )
         CALL DROT( N, VL( 1, I ), 1, VL( 1, I+1 ), 1, CS, SN )
         VL( K, I+1 ) = ZERO
      END IF
20    CONTINUE
END IF
!
IF( WANTVR ) THEN
!
!        Undo balancing of right eigenvectors
!        (Workspace: need N)
!
   CALL DGEBAK( 'B', 'R', N, ILO, IHI, WORK( IBAL ), N, VR, LDVR, &
                    IERR )
!
!        Normalize right eigenvectors and make largest component real
!
   DO 40 I = 1, N
      IF( WI( I ).EQ.ZERO ) THEN
         SCL = ONE / DNRM2( N, VR( 1, I ), 1 )
         CALL DSCAL( N, SCL, VR( 1, I ), 1 )
      ELSE IF( WI( I ).GT.ZERO ) THEN
         SCL = ONE / DLAPY2( DNRM2( N, VR( 1, I ), 1 ), &
                   DNRM2( N, VR( 1, I+1 ), 1 ) )
         CALL DSCAL( N, SCL, VR( 1, I ), 1 )
         CALL DSCAL( N, SCL, VR( 1, I+1 ), 1 )
         DO 30 K = 1, N
            WORK( IWRK+K-1 ) = VR( K, I )**2 + VR( K, I+1 )**2
30          CONTINUE
         K = IDAMAX( N, WORK( IWRK ), 1 )
         CALL DLARTG( VR( K, I ), VR( K, I+1 ), CS, SN, R )
         CALL DROT( N, VR( 1, I ), 1, VR( 1, I+1 ), 1, CS, SN )
         VR( K, I+1 ) = ZERO
      END IF
40    CONTINUE
END IF
!
!     Undo scaling if necessary
!
50 CONTINUE
IF( SCALEA ) THEN
   CALL DLASCL( 'G', 0, 0, CSCALE, ANRM, N-INFO, 1, WR( INFO+1 ), &
                    MAX( N-INFO, 1 ), IERR )
   CALL DLASCL( 'G', 0, 0, CSCALE, ANRM, N-INFO, 1, WI( INFO+1 ), &
                    MAX( N-INFO, 1 ), IERR )
   IF( INFO.GT.0 ) THEN
      CALL DLASCL( 'G', 0, 0, CSCALE, ANRM, ILO-1, 1, WR, N, &
                       IERR )
      CALL DLASCL( 'G', 0, 0, CSCALE, ANRM, ILO-1, 1, WI, N, &
                       IERR )
   END IF
END IF
!
WORK( 1 ) = MAXWRK
RETURN
!
!     End of DGEEV
!
end subroutine dgeev

! ===== End dgeev.f90 =====


! ===== Begin dgehd2.f90 =====

SUBROUTINE DGEHD2( N, ILO, IHI, A, LDA, TAU, WORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
INTEGER            IHI, ILO, INFO, LDA, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGEHD2 reduces a real general matrix A to upper Hessenberg form H by
!  an orthogonal similarity transformation:  Q' * A * Q = H .
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  ILO     (input) INTEGER
!  IHI     (input) INTEGER
!          It is assumed that A is already upper triangular in rows
!          and columns 1:ILO-1 and IHI+1:N. ILO and IHI are normally
!          set by a previous call to DGEBAL; otherwise they should be
!          set to 1 and N respectively. See Further Details.
!          1 <= ILO <= IHI <= max(1,N).
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the n by n general matrix to be reduced.
!          On exit, the upper triangle and the first subdiagonal of A
!          are overwritten with the upper Hessenberg matrix H, and the
!          elements below the first subdiagonal, with the array TAU,
!          represent the orthogonal matrix Q as a product of elementary
!          reflectors. See Further Details.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  TAU     (output) DOUBLE PRECISION array, dimension (N-1)
!          The scalar factors of the elementary reflectors (see Further
!          Details).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (N)
!
!  INFO    (output) INTEGER
!          = 0:  successful exit.
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!
!  Further Details
!  ===============
!
!  The matrix Q is represented as a product of (ihi-ilo) elementary
!  reflectors
!
!     Q = H(ilo) H(ilo+1) . . . H(ihi-1).
!
!  Each H(i) has the form
!
!     H(i) = I - tau * v * v'
!
!  where tau is a real scalar, and v is a real vector with
!  v(1:i) = 0, v(i+1) = 1 and v(ihi+1:n) = 0; v(i+2:ihi) is stored on
!  exit in A(i+2:ihi,i), and tau in TAU(i).
!
!  The contents of A are illustrated by the following example, with
!  n = 7, ilo = 2 and ihi = 6:
!
!  on entry,                        on exit,
!
!  ( a   a   a   a   a   a   a )    (  a   a   h   h   h   h   a )
!  (     a   a   a   a   a   a )    (      a   h   h   h   h   a )
!  (     a   a   a   a   a   a )    (      h   h   h   h   h   h )
!  (     a   a   a   a   a   a )    (      v2  h   h   h   h   h )
!  (     a   a   a   a   a   a )    (      v2  v3  h   h   h   h )
!  (     a   a   a   a   a   a )    (      v2  v3  v4  h   h   h )
!  (                         a )    (                          a )
!
!  where a denotes an element of the original matrix A, h denotes a
!  modified element of the upper Hessenberg matrix H, and vi denotes an
!  element of the vector defining H(i).
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I
DOUBLE PRECISION   AII
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARF, DLARFG, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters
!
INFO = 0
IF( N.LT.0 ) THEN
   INFO = -1
ELSE IF( ILO.LT.1 .OR. ILO.GT.MAX( 1, N ) ) THEN
   INFO = -2
ELSE IF( IHI.LT.MIN( ILO, N ) .OR. IHI.GT.N ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -5
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGEHD2', -INFO )
   RETURN
END IF
!
DO 10 I = ILO, IHI - 1
!
!        Compute elementary reflector H(i) to annihilate A(i+2:ihi,i)
!
   CALL DLARFG( IHI-I, A( I+1, I ), A( MIN( I+2, N ), I ), 1, &
                    TAU( I ) )
   AII = A( I+1, I )
   A( I+1, I ) = ONE
!
!        Apply H(i) to A(1:ihi,i+1:ihi) from the right
!
   CALL DLARF( 'Right', IHI, IHI-I, A( I+1, I ), 1, TAU( I ), &
                   A( 1, I+1 ), LDA, WORK )
!
!        Apply H(i) to A(i+1:ihi,i+1:n) from the left
!
   CALL DLARF( 'Left', IHI-I, N-I, A( I+1, I ), 1, TAU( I ), &
                   A( I+1, I+1 ), LDA, WORK )
!
   A( I+1, I ) = AII
10 CONTINUE
!
RETURN
!
!     End of DGEHD2
!
end subroutine dgehd2

! ===== End dgehd2.f90 =====


! ===== Begin dgehrd.f90 =====

SUBROUTINE DGEHRD( N, ILO, IHI, A, LDA, TAU, WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            IHI, ILO, INFO, LDA, LWORK, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGEHRD reduces a real general matrix A to upper Hessenberg form H by
!  an orthogonal similarity transformation:  Q' * A * Q = H .
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  ILO     (input) INTEGER
!  IHI     (input) INTEGER
!          It is assumed that A is already upper triangular in rows
!          and columns 1:ILO-1 and IHI+1:N. ILO and IHI are normally
!          set by a previous call to DGEBAL; otherwise they should be
!          set to 1 and N respectively. See Further Details.
!          1 <= ILO <= IHI <= N, if N > 0; ILO=1 and IHI=0, if N=0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the N-by-N general matrix to be reduced.
!          On exit, the upper triangle and the first subdiagonal of A
!          are overwritten with the upper Hessenberg matrix H, and the
!          elements below the first subdiagonal, with the array TAU,
!          represent the orthogonal matrix Q as a product of elementary
!          reflectors. See Further Details.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  TAU     (output) DOUBLE PRECISION array, dimension (N-1)
!          The scalar factors of the elementary reflectors (see Further
!          Details). Elements 1:ILO-1 and IHI:N-1 of TAU are set to
!          zero.
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The length of the array WORK.  LWORK >= max(1,N).
!          For optimum performance LWORK >= N*NB, where NB is the
!          optimal blocksize.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!
!  Further Details
!  ===============
!
!  The matrix Q is represented as a product of (ihi-ilo) elementary
!  reflectors
!
!     Q = H(ilo) H(ilo+1) . . . H(ihi-1).
!
!  Each H(i) has the form
!
!     H(i) = I - tau * v * v'
!
!  where tau is a real scalar, and v is a real vector with
!  v(1:i) = 0, v(i+1) = 1 and v(ihi+1:n) = 0; v(i+2:ihi) is stored on
!  exit in A(i+2:ihi,i), and tau in TAU(i).
!
!  The contents of A are illustrated by the following example, with
!  n = 7, ilo = 2 and ihi = 6:
!
!  on entry,                        on exit,
!
!  ( a   a   a   a   a   a   a )    (  a   a   h   h   h   h   a )
!  (     a   a   a   a   a   a )    (      a   h   h   h   h   a )
!  (     a   a   a   a   a   a )    (      h   h   h   h   h   h )
!  (     a   a   a   a   a   a )    (      v2  h   h   h   h   h )
!  (     a   a   a   a   a   a )    (      v2  v3  h   h   h   h )
!  (     a   a   a   a   a   a )    (      v2  v3  v4  h   h   h )
!  (                         a )    (                          a )
!
!  where a denotes an element of the original matrix A, h denotes a
!  modified element of the upper Hessenberg matrix H, and vi denotes an
!  element of the vector defining H(i).
!
!  =====================================================================
!
!     .. Parameters ..
INTEGER            NBMAX, LDT
PARAMETER          ( NBMAX = 64, LDT = NBMAX+1 )
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LQUERY
INTEGER            I, IB, IINFO, IWS, LDWORK, LWKOPT, NB, NBMIN, &
                       NH, NX
DOUBLE PRECISION   EI
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   T( LDT, NBMAX )
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEHD2, DGEMM, DLAHRD, DLARFB, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. External Functions ..
INTEGER            ILAENV
EXTERNAL           ILAENV
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters
!
INFO = 0
NB = MIN( NBMAX, ILAENV( 1, 'DGEHRD', ' ', N, ILO, IHI, -1 ) )
LWKOPT = N*NB
WORK( 1 ) = LWKOPT
LQUERY = ( LWORK.EQ.-1 )
IF( N.LT.0 ) THEN
   INFO = -1
ELSE IF( ILO.LT.1 .OR. ILO.GT.MAX( 1, N ) ) THEN
   INFO = -2
ELSE IF( IHI.LT.MIN( ILO, N ) .OR. IHI.GT.N ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -5
ELSE IF( LWORK.LT.MAX( 1, N ) .AND. .NOT.LQUERY ) THEN
   INFO = -8
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGEHRD', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Set elements 1:ILO-1 and IHI:N-1 of TAU to zero
!
DO 10 I = 1, ILO - 1
   TAU( I ) = ZERO
10 CONTINUE
DO 20 I = MAX( 1, IHI ), N - 1
   TAU( I ) = ZERO
20 CONTINUE
!
!     Quick return if possible
!
NH = IHI - ILO + 1
IF( NH.LE.1 ) THEN
   WORK( 1 ) = 1
   RETURN
END IF
!
!     Determine the block size.
!
NB = MIN( NBMAX, ILAENV( 1, 'DGEHRD', ' ', N, ILO, IHI, -1 ) )
NBMIN = 2
IWS = 1
IF( NB.GT.1 .AND. NB.LT.NH ) THEN
!
!        Determine when to cross over from blocked to unblocked code
!        (last block is always handled by unblocked code).
!
   NX = MAX( NB, ILAENV( 3, 'DGEHRD', ' ', N, ILO, IHI, -1 ) )
   IF( NX.LT.NH ) THEN
!
!           Determine if workspace is large enough for blocked code.
!
      IWS = N*NB
      IF( LWORK.LT.IWS ) THEN
!
!              Not enough workspace to use optimal NB:  determine the
!              minimum value of NB, and reduce NB or force use of
!              unblocked code.
!
         NBMIN = MAX( 2, ILAENV( 2, 'DGEHRD', ' ', N, ILO, IHI, &
                     -1 ) )
         IF( LWORK.GE.N*NBMIN ) THEN
            NB = LWORK / N
         ELSE
            NB = 1
         END IF
      END IF
   END IF
END IF
LDWORK = N
!
IF( NB.LT.NBMIN .OR. NB.GE.NH ) THEN
!
!        Use unblocked code below
!
   I = ILO
!
ELSE
!
!        Use blocked code
!
   DO 30 I = ILO, IHI - 1 - NX, NB
      IB = MIN( NB, IHI-I )
!
!           Reduce columns i:i+ib-1 to Hessenberg form, returning the
!           matrices V and T of the block reflector H = I - V*T*V'
!           which performs the reduction, and also the matrix Y = A*V*T
!
      CALL DLAHRD( IHI, I, IB, A( 1, I ), LDA, TAU( I ), T, LDT, &
                       WORK, LDWORK )
!
!           Apply the block reflector H to A(1:ihi,i+ib:ihi) from the
!           right, computing  A := A - Y * V'. V(i+ib,ib-1) must be set
!           to 1.
!
      EI = A( I+IB, I+IB-1 )
      A( I+IB, I+IB-1 ) = ONE
      CALL DGEMM( 'No transpose', 'Transpose', IHI, IHI-I-IB+1, &
                      IB, -ONE, WORK, LDWORK, A( I+IB, I ), LDA, ONE, &
                      A( 1, I+IB ), LDA )
      A( I+IB, I+IB-1 ) = EI
!
!           Apply the block reflector H to A(i+1:ihi,i+ib:n) from the
!           left
!
      CALL DLARFB( 'Left', 'Transpose', 'Forward', 'Columnwise', &
                       IHI-I, N-I-IB+1, IB, A( I+1, I ), LDA, T, LDT, &
                       A( I+1, I+IB ), LDA, WORK, LDWORK )
30    CONTINUE
END IF
!
!     Use unblocked code to reduce the rest of the matrix
!
CALL DGEHD2( N, I, IHI, A, LDA, TAU, WORK, IINFO )
WORK( 1 ) = IWS
!
RETURN
!
!     End of DGEHRD
!
end subroutine dgehrd

! ===== End dgehrd.f90 =====


! ===== Begin dgelq2.f90 =====

SUBROUTINE DGELQ2( M, N, A, LDA, TAU, WORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDA, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGELQ2 computes an LQ factorization of a real m by n matrix A:
!  A = L * Q.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the m by n matrix A.
!          On exit, the elements on and below the diagonal of the array
!          contain the m by min(m,n) lower trapezoidal matrix L (L is
!          lower triangular if m <= n); the elements above the diagonal,
!          with the array TAU, represent the orthogonal matrix Q as a
!          product of elementary reflectors (see Further Details).
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  TAU     (output) DOUBLE PRECISION array, dimension (min(M,N))
!          The scalar factors of the elementary reflectors (see Further
!          Details).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (M)
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!
!  Further Details
!  ===============
!
!  The matrix Q is represented as a product of elementary reflectors
!
!     Q = H(k) . . . H(2) H(1), where k = min(m,n).
!
!  Each H(i) has the form
!
!     H(i) = I - tau * v * v'
!
!  where tau is a real scalar, and v is a real vector with
!  v(1:i-1) = 0 and v(i) = 1; v(i+1:n) is stored on exit in A(i,i+1:n),
!  and tau in TAU(i).
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, K
DOUBLE PRECISION   AII
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARF, DLARFG, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -4
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGELQ2', -INFO )
   RETURN
END IF
!
K = MIN( M, N )
!
DO 10 I = 1, K
!
!        Generate elementary reflector H(i) to annihilate A(i,i+1:n)
!
   CALL DLARFG( N-I+1, A( I, I ), A( I, MIN( I+1, N ) ), LDA, &
                    TAU( I ) )
   IF( I.LT.M ) THEN
!
!           Apply H(i) to A(i+1:m,i:n) from the right
!
      AII = A( I, I )
      A( I, I ) = ONE
      CALL DLARF( 'Right', M-I, N-I+1, A( I, I ), LDA, TAU( I ), &
                      A( I+1, I ), LDA, WORK )
      A( I, I ) = AII
   END IF
10 CONTINUE
RETURN
!
!     End of DGELQ2
!
end subroutine dgelq2

! ===== End dgelq2.f90 =====


! ===== Begin dgelqf.f90 =====

SUBROUTINE DGELQF( M, N, A, LDA, TAU, WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDA, LWORK, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGELQF computes an LQ factorization of a real M-by-N matrix A:
!  A = L * Q.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the M-by-N matrix A.
!          On exit, the elements on and below the diagonal of the array
!          contain the m-by-min(m,n) lower trapezoidal matrix L (L is
!          lower triangular if m <= n); the elements above the diagonal,
!          with the array TAU, represent the orthogonal matrix Q as a
!          product of elementary reflectors (see Further Details).
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  TAU     (output) DOUBLE PRECISION array, dimension (min(M,N))
!          The scalar factors of the elementary reflectors (see Further
!          Details).
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.  LWORK >= max(1,M).
!          For optimum performance LWORK >= M*NB, where NB is the
!          optimal blocksize.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  Further Details
!  ===============
!
!  The matrix Q is represented as a product of elementary reflectors
!
!     Q = H(k) . . . H(2) H(1), where k = min(m,n).
!
!  Each H(i) has the form
!
!     H(i) = I - tau * v * v'
!
!  where tau is a real scalar, and v is a real vector with
!  v(1:i-1) = 0 and v(i) = 1; v(i+1:n) is stored on exit in A(i,i+1:n),
!  and tau in TAU(i).
!
!  =====================================================================
!
!     .. Local Scalars ..
LOGICAL            LQUERY
INTEGER            I, IB, IINFO, IWS, K, LDWORK, LWKOPT, NB, &
                       NBMIN, NX
!     ..
!     .. External Subroutines ..
EXTERNAL           DGELQ2, DLARFB, DLARFT, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. External Functions ..
INTEGER            ILAENV
EXTERNAL           ILAENV
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
NB = ILAENV( 1, 'DGELQF', ' ', M, N, -1, -1 )
LWKOPT = M*NB
WORK( 1 ) = LWKOPT
LQUERY = ( LWORK.EQ.-1 )
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -4
ELSE IF( LWORK.LT.MAX( 1, M ) .AND. .NOT.LQUERY ) THEN
   INFO = -7
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGELQF', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
K = MIN( M, N )
IF( K.EQ.0 ) THEN
   WORK( 1 ) = 1
   RETURN
END IF
!
NBMIN = 2
NX = 0
IWS = M
IF( NB.GT.1 .AND. NB.LT.K ) THEN
!
!        Determine when to cross over from blocked to unblocked code.
!
   NX = MAX( 0, ILAENV( 3, 'DGELQF', ' ', M, N, -1, -1 ) )
   IF( NX.LT.K ) THEN
!
!           Determine if workspace is large enough for blocked code.
!
      LDWORK = M
      IWS = LDWORK*NB
      IF( LWORK.LT.IWS ) THEN
!
!              Not enough workspace to use optimal NB:  reduce NB and
!              determine the minimum value of NB.
!
         NB = LWORK / LDWORK
         NBMIN = MAX( 2, ILAENV( 2, 'DGELQF', ' ', M, N, -1, &
                     -1 ) )
      END IF
   END IF
END IF
!
IF( NB.GE.NBMIN .AND. NB.LT.K .AND. NX.LT.K ) THEN
!
!        Use blocked code initially
!
   DO 10 I = 1, K - NX, NB
      IB = MIN( K-I+1, NB )
!
!           Compute the LQ factorization of the current block
!           A(i:i+ib-1,i:n)
!
      CALL DGELQ2( IB, N-I+1, A( I, I ), LDA, TAU( I ), WORK, &
                       IINFO )
      IF( I+IB.LE.M ) THEN
!
!              Form the triangular factor of the block reflector
!              H = H(i) H(i+1) . . . H(i+ib-1)
!
         CALL DLARFT( 'Forward', 'Rowwise', N-I+1, IB, A( I, I ), &
                          LDA, TAU( I ), WORK, LDWORK )
!
!              Apply H to A(i+ib:m,i:n) from the right
!
         CALL DLARFB( 'Right', 'No transpose', 'Forward', &
                          'Rowwise', M-I-IB+1, N-I+1, IB, A( I, I ), &
                          LDA, WORK, LDWORK, A( I+IB, I ), LDA, &
                          WORK( IB+1 ), LDWORK )
      END IF
10    CONTINUE
ELSE
   I = 1
END IF
!
!     Use unblocked code to factor the last or only block.
!
IF( I.LE.K ) &
       CALL DGELQ2( M-I+1, N-I+1, A( I, I ), LDA, TAU( I ), WORK, &
                    IINFO )
!
WORK( 1 ) = IWS
RETURN
!
!     End of DGELQF
!
end subroutine dgelqf

! ===== End dgelqf.f90 =====


! ===== Begin dgels.f90 =====

SUBROUTINE DGELS( TRANS, M, N, NRHS, A, LDA, B, LDB, WORK, LWORK, &
                      INFO )
!
!  -- LAPACK driver routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
CHARACTER          TRANS
INTEGER            INFO, LDA, LDB, LWORK, M, N, NRHS
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), B( LDB, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGELS solves overdetermined or underdetermined real linear systems
!  involving an M-by-N matrix A, or its transpose, using a QR or LQ
!  factorization of A.  It is assumed that A has full rank.
!
!  The following options are provided:
!
!  1. If TRANS = 'N' and m >= n:  find the least squares solution of
!     an overdetermined system, i.e., solve the least squares problem
!                  minimize || B - A*X ||.
!
!  2. If TRANS = 'N' and m < n:  find the minimum norm solution of
!     an underdetermined system A * X = B.
!
!  3. If TRANS = 'T' and m >= n:  find the minimum norm solution of
!     an undetermined system A**T * X = B.
!
!  4. If TRANS = 'T' and m < n:  find the least squares solution of
!     an overdetermined system, i.e., solve the least squares problem
!                  minimize || B - A**T * X ||.
!
!  Several right hand side vectors b and solution vectors x can be
!  handled in a single call; they are stored as the columns of the
!  M-by-NRHS right hand side matrix B and the N-by-NRHS solution
!  matrix X.
!
!  Arguments
!  =========
!
!  TRANS   (input) CHARACTER
!          = 'N': the linear system involves A;
!          = 'T': the linear system involves A**T.
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of
!          columns of the matrices B and X. NRHS >=0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the M-by-N matrix A.
!          On exit,
!            if M >= N, A is overwritten by details of its QR
!                       factorization as returned by DGEQRF;
!            if M <  N, A is overwritten by details of its LQ
!                       factorization as returned by DGELQF.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the matrix B of right hand side vectors, stored
!          columnwise; B is M-by-NRHS if TRANS = 'N', or N-by-NRHS
!          if TRANS = 'T'.
!          On exit, B is overwritten by the solution vectors, stored
!          columnwise:
!          if TRANS = 'N' and m >= n, rows 1 to n of B contain the least
!          squares solution vectors; the residual sum of squares for the
!          solution in each column is given by the sum of squares of
!          elements N+1 to M in that column;
!          if TRANS = 'N' and m < n, rows 1 to N of B contain the
!          minimum norm solution vectors;
!          if TRANS = 'T' and m >= n, rows 1 to M of B contain the
!          minimum norm solution vectors;
!          if TRANS = 'T' and m < n, rows 1 to M of B contain the
!          least squares solution vectors; the residual sum of squares
!          for the solution in each column is given by the sum of
!          squares of elements M+1 to N in that column.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B. LDB >= MAX(1,M,N).
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.
!          LWORK >= max( 1, MN + max( MN, NRHS ) ).
!          For optimal performance,
!          LWORK >= max( 1, MN + max( MN, NRHS )*NB ).
!          where MN = min(M,N) and NB is the optimum block size.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D0, ONE = 1.0D0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LQUERY, TPSD
INTEGER            BROW, I, IASCL, IBSCL, J, MN, NB, SCLLEN, WSIZE
DOUBLE PRECISION   ANRM, BIGNUM, BNRM, SMLNUM
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   RWORK( 1 )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            ILAENV
DOUBLE PRECISION   DLAMCH, DLANGE
EXTERNAL           LSAME, ILAENV, DLAMCH, DLANGE
!     ..
!     .. External Subroutines ..
EXTERNAL           DGELQF, DGEQRF, DLASCL, DLASET, DORMLQ, DORMQR, &
                       DTRSM, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          DBLE, MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments.
!
INFO = 0
MN = MIN( M, N )
LQUERY = ( LWORK.EQ.-1 )
IF( .NOT.( LSAME( TRANS, 'N' ) .OR. LSAME( TRANS, 'T' ) ) ) THEN
   INFO = -1
ELSE IF( M.LT.0 ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -4
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -6
ELSE IF( LDB.LT.MAX( 1, M, N ) ) THEN
   INFO = -8
ELSE IF( LWORK.LT.MAX( 1, MN+MAX( MN, NRHS ) ) .AND. .NOT.LQUERY ) &
              THEN
   INFO = -10
END IF
!
!     Figure out optimal block size
!
IF( INFO.EQ.0 .OR. INFO.EQ.-10 ) THEN
!
   TPSD = .TRUE.
   IF( LSAME( TRANS, 'N' ) ) &
          TPSD = .FALSE.
!
   IF( M.GE.N ) THEN
      NB = ILAENV( 1, 'DGEQRF', ' ', M, N, -1, -1 )
      IF( TPSD ) THEN
         NB = MAX( NB, ILAENV( 1, 'DORMQR', 'LN', M, NRHS, N, &
                  -1 ) )
      ELSE
         NB = MAX( NB, ILAENV( 1, 'DORMQR', 'LT', M, NRHS, N, &
                  -1 ) )
      END IF
   ELSE
      NB = ILAENV( 1, 'DGELQF', ' ', M, N, -1, -1 )
      IF( TPSD ) THEN
         NB = MAX( NB, ILAENV( 1, 'DORMLQ', 'LT', N, NRHS, M, &
                  -1 ) )
      ELSE
         NB = MAX( NB, ILAENV( 1, 'DORMLQ', 'LN', N, NRHS, M, &
                  -1 ) )
      END IF
   END IF
!
   WSIZE = MAX( 1, MN+MAX( MN, NRHS )*NB )
   WORK( 1 ) = DBLE( WSIZE )
!
END IF
!
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGELS ', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
IF( MIN( M, N, NRHS ).EQ.0 ) THEN
   CALL DLASET( 'Full', MAX( M, N ), NRHS, ZERO, ZERO, B, LDB )
   RETURN
END IF
!
!     Get machine parameters
!
SMLNUM = DLAMCH( 'S' ) / DLAMCH( 'P' )
BIGNUM = ONE / SMLNUM
CALL DLABAD( SMLNUM, BIGNUM )
!
!     Scale A, B if max element outside range [SMLNUM,BIGNUM]
!
ANRM = DLANGE( 'M', M, N, A, LDA, RWORK )
IASCL = 0
IF( ANRM.GT.ZERO .AND. ANRM.LT.SMLNUM ) THEN
!
!        Scale matrix norm up to SMLNUM
!
   CALL DLASCL( 'G', 0, 0, ANRM, SMLNUM, M, N, A, LDA, INFO )
   IASCL = 1
ELSE IF( ANRM.GT.BIGNUM ) THEN
!
!        Scale matrix norm down to BIGNUM
!
   CALL DLASCL( 'G', 0, 0, ANRM, BIGNUM, M, N, A, LDA, INFO )
   IASCL = 2
ELSE IF( ANRM.EQ.ZERO ) THEN
!
!        Matrix all zero. Return zero solution.
!
   CALL DLASET( 'F', MAX( M, N ), NRHS, ZERO, ZERO, B, LDB )
   GO TO 50
END IF
!
BROW = M
IF( TPSD ) &
       BROW = N
BNRM = DLANGE( 'M', BROW, NRHS, B, LDB, RWORK )
IBSCL = 0
IF( BNRM.GT.ZERO .AND. BNRM.LT.SMLNUM ) THEN
!
!        Scale matrix norm up to SMLNUM
!
   CALL DLASCL( 'G', 0, 0, BNRM, SMLNUM, BROW, NRHS, B, LDB, &
                    INFO )
   IBSCL = 1
ELSE IF( BNRM.GT.BIGNUM ) THEN
!
!        Scale matrix norm down to BIGNUM
!
   CALL DLASCL( 'G', 0, 0, BNRM, BIGNUM, BROW, NRHS, B, LDB, &
                    INFO )
   IBSCL = 2
END IF
!
IF( M.GE.N ) THEN
!
!        compute QR factorization of A
!
   CALL DGEQRF( M, N, A, LDA, WORK( 1 ), WORK( MN+1 ), LWORK-MN, &
                    INFO )
!
!        workspace at least N, optimally N*NB
!
   IF( .NOT.TPSD ) THEN
!
!           Least-Squares Problem min || A * X - B ||
!
!           B(1:M,1:NRHS) := Q' * B(1:M,1:NRHS)
!
      CALL DORMQR( 'Left', 'Transpose', M, NRHS, N, A, LDA, &
                       WORK( 1 ), B, LDB, WORK( MN+1 ), LWORK-MN, &
                       INFO )
!
!           workspace at least NRHS, optimally NRHS*NB
!
!           B(1:N,1:NRHS) := inv(R) * B(1:N,1:NRHS)
!
      CALL DTRSM( 'Left', 'Upper', 'No transpose', 'Non-unit', N, &
                      NRHS, ONE, A, LDA, B, LDB )
!
      SCLLEN = N
!
   ELSE
!
!           Overdetermined system of equations A' * X = B
!
!           B(1:N,1:NRHS) := inv(R') * B(1:N,1:NRHS)
!
      CALL DTRSM( 'Left', 'Upper', 'Transpose', 'Non-unit', N, &
                      NRHS, ONE, A, LDA, B, LDB )
!
!           B(N+1:M,1:NRHS) = ZERO
!
      DO 20 J = 1, NRHS
         DO 10 I = N + 1, M
            B( I, J ) = ZERO
10          CONTINUE
20       CONTINUE
!
!           B(1:M,1:NRHS) := Q(1:N,:) * B(1:N,1:NRHS)
!
      CALL DORMQR( 'Left', 'No transpose', M, NRHS, N, A, LDA, &
                       WORK( 1 ), B, LDB, WORK( MN+1 ), LWORK-MN, &
                       INFO )
!
!           workspace at least NRHS, optimally NRHS*NB
!
      SCLLEN = M
!
   END IF
!
ELSE
!
!        Compute LQ factorization of A
!
   CALL DGELQF( M, N, A, LDA, WORK( 1 ), WORK( MN+1 ), LWORK-MN, &
                    INFO )
!
!        workspace at least M, optimally M*NB.
!
   IF( .NOT.TPSD ) THEN
!
!           underdetermined system of equations A * X = B
!
!           B(1:M,1:NRHS) := inv(L) * B(1:M,1:NRHS)
!
      CALL DTRSM( 'Left', 'Lower', 'No transpose', 'Non-unit', M, &
                      NRHS, ONE, A, LDA, B, LDB )
!
!           B(M+1:N,1:NRHS) = 0
!
      DO 40 J = 1, NRHS
         DO 30 I = M + 1, N
            B( I, J ) = ZERO
30          CONTINUE
40       CONTINUE
!
!           B(1:N,1:NRHS) := Q(1:N,:)' * B(1:M,1:NRHS)
!
      CALL DORMLQ( 'Left', 'Transpose', N, NRHS, M, A, LDA, &
                       WORK( 1 ), B, LDB, WORK( MN+1 ), LWORK-MN, &
                       INFO )
!
!           workspace at least NRHS, optimally NRHS*NB
!
      SCLLEN = N
!
   ELSE
!
!           overdetermined system min || A' * X - B ||
!
!           B(1:N,1:NRHS) := Q * B(1:N,1:NRHS)
!
      CALL DORMLQ( 'Left', 'No transpose', N, NRHS, M, A, LDA, &
                       WORK( 1 ), B, LDB, WORK( MN+1 ), LWORK-MN, &
                       INFO )
!
!           workspace at least NRHS, optimally NRHS*NB
!
!           B(1:M,1:NRHS) := inv(L') * B(1:M,1:NRHS)
!
      CALL DTRSM( 'Left', 'Lower', 'Transpose', 'Non-unit', M, &
                      NRHS, ONE, A, LDA, B, LDB )
!
      SCLLEN = M
!
   END IF
!
END IF
!
!     Undo scaling
!
IF( IASCL.EQ.1 ) THEN
   CALL DLASCL( 'G', 0, 0, ANRM, SMLNUM, SCLLEN, NRHS, B, LDB, &
                    INFO )
ELSE IF( IASCL.EQ.2 ) THEN
   CALL DLASCL( 'G', 0, 0, ANRM, BIGNUM, SCLLEN, NRHS, B, LDB, &
                    INFO )
END IF
IF( IBSCL.EQ.1 ) THEN
   CALL DLASCL( 'G', 0, 0, SMLNUM, BNRM, SCLLEN, NRHS, B, LDB, &
                    INFO )
ELSE IF( IBSCL.EQ.2 ) THEN
   CALL DLASCL( 'G', 0, 0, BIGNUM, BNRM, SCLLEN, NRHS, B, LDB, &
                    INFO )
END IF
!
50 CONTINUE
WORK( 1 ) = DBLE( WSIZE )
!
RETURN
!
!     End of DGELS
!
end subroutine dgels

! ===== End dgels.f90 =====


! ===== Begin dgeqr2.f90 =====

SUBROUTINE DGEQR2( M, N, A, LDA, TAU, WORK, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDA, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGEQR2 computes a QR factorization of a real m by n matrix A:
!  A = Q * R.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the m by n matrix A.
!          On exit, the elements on and above the diagonal of the array
!          contain the min(m,n) by n upper trapezoidal matrix R (R is
!          upper triangular if m >= n); the elements below the diagonal,
!          with the array TAU, represent the orthogonal matrix Q as a
!          product of elementary reflectors (see Further Details).
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  TAU     (output) DOUBLE PRECISION array, dimension (min(M,N))
!          The scalar factors of the elementary reflectors (see Further
!          Details).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (N)
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!
!  Further Details
!  ===============
!
!  The matrix Q is represented as a product of elementary reflectors
!
!     Q = H(1) H(2) . . . H(k), where k = min(m,n).
!
!  Each H(i) has the form
!
!     H(i) = I - tau * v * v'
!
!  where tau is a real scalar, and v is a real vector with
!  v(1:i-1) = 0 and v(i) = 1; v(i+1:m) is stored on exit in A(i+1:m,i),
!  and tau in TAU(i).
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, K
DOUBLE PRECISION   AII
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARF, DLARFG, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -4
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGEQR2', -INFO )
   RETURN
END IF
!
K = MIN( M, N )
!
DO 10 I = 1, K
!
!        Generate elementary reflector H(i) to annihilate A(i+1:m,i)
!
   CALL DLARFG( M-I+1, A( I, I ), A( MIN( I+1, M ), I ), 1, &
                    TAU( I ) )
   IF( I.LT.N ) THEN
!
!           Apply H(i) to A(i:m,i+1:n) from the left
!
      AII = A( I, I )
      A( I, I ) = ONE
      CALL DLARF( 'Left', M-I+1, N-I, A( I, I ), 1, TAU( I ), &
                      A( I, I+1 ), LDA, WORK )
      A( I, I ) = AII
   END IF
10 CONTINUE
RETURN
!
!     End of DGEQR2
!
end subroutine dgeqr2

! ===== End dgeqr2.f90 =====


! ===== Begin dgeqrf.f90 =====

SUBROUTINE DGEQRF( M, N, A, LDA, TAU, WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDA, LWORK, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGEQRF computes a QR factorization of a real M-by-N matrix A:
!  A = Q * R.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the M-by-N matrix A.
!          On exit, the elements on and above the diagonal of the array
!          contain the min(M,N)-by-N upper trapezoidal matrix R (R is
!          upper triangular if m >= n); the elements below the diagonal,
!          with the array TAU, represent the orthogonal matrix Q as a
!          product of min(m,n) elementary reflectors (see Further
!          Details).
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  TAU     (output) DOUBLE PRECISION array, dimension (min(M,N))
!          The scalar factors of the elementary reflectors (see Further
!          Details).
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.  LWORK >= max(1,N).
!          For optimum performance LWORK >= N*NB, where NB is
!          the optimal blocksize.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  Further Details
!  ===============
!
!  The matrix Q is represented as a product of elementary reflectors
!
!     Q = H(1) H(2) . . . H(k), where k = min(m,n).
!
!  Each H(i) has the form
!
!     H(i) = I - tau * v * v'
!
!  where tau is a real scalar, and v is a real vector with
!  v(1:i-1) = 0 and v(i) = 1; v(i+1:m) is stored on exit in A(i+1:m,i),
!  and tau in TAU(i).
!
!  =====================================================================
!
!     .. Local Scalars ..
LOGICAL            LQUERY
INTEGER            I, IB, IINFO, IWS, K, LDWORK, LWKOPT, NB, &
                       NBMIN, NX
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEQR2, DLARFB, DLARFT, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. External Functions ..
INTEGER            ILAENV
EXTERNAL           ILAENV
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
NB = ILAENV( 1, 'DGEQRF', ' ', M, N, -1, -1 )
LWKOPT = N*NB
WORK( 1 ) = LWKOPT
LQUERY = ( LWORK.EQ.-1 )
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -4
ELSE IF( LWORK.LT.MAX( 1, N ) .AND. .NOT.LQUERY ) THEN
   INFO = -7
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGEQRF', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
K = MIN( M, N )
IF( K.EQ.0 ) THEN
   WORK( 1 ) = 1
   RETURN
END IF
!
NBMIN = 2
NX = 0
IWS = N
IF( NB.GT.1 .AND. NB.LT.K ) THEN
!
!        Determine when to cross over from blocked to unblocked code.
!
   NX = MAX( 0, ILAENV( 3, 'DGEQRF', ' ', M, N, -1, -1 ) )
   IF( NX.LT.K ) THEN
!
!           Determine if workspace is large enough for blocked code.
!
      LDWORK = N
      IWS = LDWORK*NB
      IF( LWORK.LT.IWS ) THEN
!
!              Not enough workspace to use optimal NB:  reduce NB and
!              determine the minimum value of NB.
!
         NB = LWORK / LDWORK
         NBMIN = MAX( 2, ILAENV( 2, 'DGEQRF', ' ', M, N, -1, &
                     -1 ) )
      END IF
   END IF
END IF
!
IF( NB.GE.NBMIN .AND. NB.LT.K .AND. NX.LT.K ) THEN
!
!        Use blocked code initially
!
   DO 10 I = 1, K - NX, NB
      IB = MIN( K-I+1, NB )
!
!           Compute the QR factorization of the current block
!           A(i:m,i:i+ib-1)
!
      CALL DGEQR2( M-I+1, IB, A( I, I ), LDA, TAU( I ), WORK, &
                       IINFO )
      IF( I+IB.LE.N ) THEN
!
!              Form the triangular factor of the block reflector
!              H = H(i) H(i+1) . . . H(i+ib-1)
!
         CALL DLARFT( 'Forward', 'Columnwise', M-I+1, IB, &
                          A( I, I ), LDA, TAU( I ), WORK, LDWORK )
!
!              Apply H' to A(i:m,i+ib:n) from the left
!
         CALL DLARFB( 'Left', 'Transpose', 'Forward', &
                          'Columnwise', M-I+1, N-I-IB+1, IB, &
                          A( I, I ), LDA, WORK, LDWORK, A( I, I+IB ), &
                          LDA, WORK( IB+1 ), LDWORK )
      END IF
10    CONTINUE
ELSE
   I = 1
END IF
!
!     Use unblocked code to factor the last or only block.
!
IF( I.LE.K ) &
       CALL DGEQR2( M-I+1, N-I+1, A( I, I ), LDA, TAU( I ), WORK, &
                    IINFO )
!
WORK( 1 ) = IWS
RETURN
!
!     End of DGEQRF
!
end subroutine dgeqrf

! ===== End dgeqrf.f90 =====


! ===== Begin dgesv.f90 =====

SUBROUTINE DGESV( N, NRHS, A, LDA, IPIV, B, LDB, INFO )
!
!  -- LAPACK driver routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDA, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   A( LDA, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DGESV computes the solution to a real system of linear equations
!     A * X = B,
!  where A is an N-by-N matrix and X and B are N-by-NRHS matrices.
!
!  The LU decomposition with partial pivoting and row interchanges is
!  used to factor A as
!     A = P * L * U,
!  where P is a permutation matrix, L is unit lower triangular, and U is
!  upper triangular.  The factored form of A is then used to solve the
!  system of equations A * X = B.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of linear equations, i.e., the order of the
!          matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the N-by-N coefficient matrix A.
!          On exit, the factors L and U from the factorization
!          A = P*L*U; the unit diagonal elements of L are not stored.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  IPIV    (output) INTEGER array, dimension (N)
!          The pivot indices that define the permutation matrix P;
!          row i of the matrix was interchanged with row IPIV(i).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the N-by-NRHS matrix of right hand side matrix B.
!          On exit, if INFO = 0, the N-by-NRHS solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, U(i,i) is exactly zero.  The factorization
!                has been completed, but the factor U is exactly
!                singular, so the solution could not be computed.
!
!  =====================================================================
!
!     .. External Subroutines ..
EXTERNAL           DGETRF, DGETRS, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
IF( N.LT.0 ) THEN
   INFO = -1
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -4
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -7
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGESV ', -INFO )
   RETURN
END IF
!
!     Compute the LU factorization of A.
!
CALL DGETRF( N, N, A, LDA, IPIV, INFO )
IF( INFO.EQ.0 ) THEN
!
!        Solve the system A*X = B, overwriting B with X.
!
   CALL DGETRS( 'No transpose', N, NRHS, A, LDA, IPIV, B, LDB, &
                    INFO )
END IF
RETURN
!
!     End of DGESV
!
end subroutine dgesv

! ===== End dgesv.f90 =====


! ===== Begin dgetf2.f90 =====

SUBROUTINE DGETF2( M, N, A, LDA, IPIV, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1992
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDA, M, N
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DGETF2 computes an LU factorization of a general m-by-n matrix A
!  using partial pivoting with row interchanges.
!
!  The factorization has the form
!     A = P * L * U
!  where P is a permutation matrix, L is lower triangular with unit
!  diagonal elements (lower trapezoidal if m > n), and U is upper
!  triangular (upper trapezoidal if m < n).
!
!  This is the right-looking Level 2 BLAS version of the algorithm.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the m by n matrix to be factored.
!          On exit, the factors L and U from the factorization
!          A = P*L*U; the unit diagonal elements of L are not stored.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  IPIV    (output) INTEGER array, dimension (min(M,N))
!          The pivot indices; for 1 <= i <= min(M,N), row i of the
!          matrix was interchanged with row IPIV(i).
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -k, the k-th argument had an illegal value
!          > 0: if INFO = k, U(k,k) is exactly zero. The factorization
!               has been completed, but the factor U is exactly
!               singular, and division by zero will occur if it is used
!               to solve a system of equations.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            J, JP
!     ..
!     .. External Functions ..
INTEGER            IDAMAX
EXTERNAL           IDAMAX
!     ..
!     .. External Subroutines ..
EXTERNAL           DGER, DSCAL, DSWAP, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -4
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGETF2', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( M.EQ.0 .OR. N.EQ.0 ) &
       RETURN
!
DO 10 J = 1, MIN( M, N )
!
!        Find pivot and test for singularity.
!
   JP = J - 1 + IDAMAX( M-J+1, A( J, J ), 1 )
   IPIV( J ) = JP
   IF( A( JP, J ).NE.ZERO ) THEN
!
!           Apply the interchange to columns 1:N.
!
      IF( JP.NE.J ) &
             CALL DSWAP( N, A( J, 1 ), LDA, A( JP, 1 ), LDA )
!
!           Compute elements J+1:M of J-th column.
!
      IF( J.LT.M ) &
             CALL DSCAL( M-J, ONE / A( J, J ), A( J+1, J ), 1 )
!
   ELSE IF( INFO.EQ.0 ) THEN
!
      INFO = J
   END IF
!
   IF( J.LT.MIN( M, N ) ) THEN
!
!           Update trailing submatrix.
!
      CALL DGER( M-J, N-J, -ONE, A( J+1, J ), 1, A( J, J+1 ), LDA, &
                     A( J+1, J+1 ), LDA )
   END IF
10 CONTINUE
RETURN
!
!     End of DGETF2
!
end subroutine dgetf2

! ===== End dgetf2.f90 =====


! ===== Begin dgetrf.f90 =====

SUBROUTINE DGETRF( M, N, A, LDA, IPIV, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDA, M, N
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DGETRF computes an LU factorization of a general M-by-N matrix A
!  using partial pivoting with row interchanges.
!
!  The factorization has the form
!     A = P * L * U
!  where P is a permutation matrix, L is lower triangular with unit
!  diagonal elements (lower trapezoidal if m > n), and U is upper
!  triangular (upper trapezoidal if m < n).
!
!  This is the right-looking Level 3 BLAS version of the algorithm.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the M-by-N matrix to be factored.
!          On exit, the factors L and U from the factorization
!          A = P*L*U; the unit diagonal elements of L are not stored.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  IPIV    (output) INTEGER array, dimension (min(M,N))
!          The pivot indices; for 1 <= i <= min(M,N), row i of the
!          matrix was interchanged with row IPIV(i).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, U(i,i) is exactly zero. The factorization
!                has been completed, but the factor U is exactly
!                singular, and division by zero will occur if it is used
!                to solve a system of equations.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, IINFO, J, JB, NB
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMM, DGETF2, DLASWP, DTRSM, XERBLA
!     ..
!     .. External Functions ..
INTEGER            ILAENV
EXTERNAL           ILAENV
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -4
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGETRF', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( M.EQ.0 .OR. N.EQ.0 ) &
       RETURN
!
!     Determine the block size for this environment.
!
NB = ILAENV( 1, 'DGETRF', ' ', M, N, -1, -1 )
IF( NB.LE.1 .OR. NB.GE.MIN( M, N ) ) THEN
!
!        Use unblocked code.
!
   CALL DGETF2( M, N, A, LDA, IPIV, INFO )
ELSE
!
!        Use blocked code.
!
   DO 20 J = 1, MIN( M, N ), NB
      JB = MIN( MIN( M, N )-J+1, NB )
!
!           Factor diagonal and subdiagonal blocks and test for exact
!           singularity.
!
      CALL DGETF2( M-J+1, JB, A( J, J ), LDA, IPIV( J ), IINFO )
!
!           Adjust INFO and the pivot indices.
!
      IF( INFO.EQ.0 .AND. IINFO.GT.0 ) &
             INFO = IINFO + J - 1
      DO 10 I = J, MIN( M, J+JB-1 )
         IPIV( I ) = J - 1 + IPIV( I )
10       CONTINUE
!
!           Apply interchanges to columns 1:J-1.
!
      CALL DLASWP( J-1, A, LDA, J, J+JB-1, IPIV, 1 )
!
      IF( J+JB.LE.N ) THEN
!
!              Apply interchanges to columns J+JB:N.
!
         CALL DLASWP( N-J-JB+1, A( 1, J+JB ), LDA, J, J+JB-1, &
                          IPIV, 1 )
!
!              Compute block row of U.
!
         CALL DTRSM( 'Left', 'Lower', 'No transpose', 'Unit', JB, &
                         N-J-JB+1, ONE, A( J, J ), LDA, A( J, J+JB ), &
                         LDA )
         IF( J+JB.LE.M ) THEN
!
!                 Update trailing submatrix.
!
            CALL DGEMM( 'No transpose', 'No transpose', M-J-JB+1, &
                            N-J-JB+1, JB, -ONE, A( J+JB, J ), LDA, &
                            A( J, J+JB ), LDA, ONE, A( J+JB, J+JB ), &
                            LDA )
         END IF
      END IF
20    CONTINUE
END IF
RETURN
!
!     End of DGETRF
!
end subroutine dgetrf

! ===== End dgetrf.f90 =====


! ===== Begin dgetri.f90 =====

SUBROUTINE DGETRI( N, A, LDA, IPIV, WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDA, LWORK, N
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   A( LDA, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGETRI computes the inverse of a matrix using the LU factorization
!  computed by DGETRF.
!
!  This method inverts U and then computes inv(A) by solving the system
!  inv(A)*L = inv(U) for inv(A).
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the factors L and U from the factorization
!          A = P*L*U as computed by DGETRF.
!          On exit, if INFO = 0, the inverse of the original matrix A.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  IPIV    (input) INTEGER array, dimension (N)
!          The pivot indices from DGETRF; for 1<=i<=N, row i of the
!          matrix was interchanged with row IPIV(i).
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO=0, then WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.  LWORK >= max(1,N).
!          For optimal performance LWORK >= N*NB, where NB is
!          the optimal blocksize returned by ILAENV.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, U(i,i) is exactly zero; the matrix is
!                singular and its inverse could not be computed.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LQUERY
INTEGER            I, IWS, J, JB, JJ, JP, LDWORK, LWKOPT, NB, &
                       NBMIN, NN
!     ..
!     .. External Functions ..
INTEGER            ILAENV
EXTERNAL           ILAENV
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMM, DGEMV, DSWAP, DTRSM, DTRTRI, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
NB = ILAENV( 1, 'DGETRI', ' ', N, -1, -1, -1 )
LWKOPT = N*NB
WORK( 1 ) = LWKOPT
LQUERY = ( LWORK.EQ.-1 )
IF( N.LT.0 ) THEN
   INFO = -1
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -3
ELSE IF( LWORK.LT.MAX( 1, N ) .AND. .NOT.LQUERY ) THEN
   INFO = -6
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGETRI', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Form inv(U).  If INFO > 0 from DTRTRI, then U is singular,
!     and the inverse is not computed.
!
CALL DTRTRI( 'Upper', 'Non-unit', N, A, LDA, INFO )
IF( INFO.GT.0 ) &
       RETURN
!
NBMIN = 2
LDWORK = N
IF( NB.GT.1 .AND. NB.LT.N ) THEN
   IWS = MAX( LDWORK*NB, 1 )
   IF( LWORK.LT.IWS ) THEN
      NB = LWORK / LDWORK
      NBMIN = MAX( 2, ILAENV( 2, 'DGETRI', ' ', N, -1, -1, -1 ) )
   END IF
ELSE
   IWS = N
END IF
!
!     Solve the equation inv(A)*L = inv(U) for inv(A).
!
IF( NB.LT.NBMIN .OR. NB.GE.N ) THEN
!
!        Use unblocked code.
!
   DO 20 J = N, 1, -1
!
!           Copy current column of L to WORK and replace with zeros.
!
      DO 10 I = J + 1, N
         WORK( I ) = A( I, J )
         A( I, J ) = ZERO
10       CONTINUE
!
!           Compute current column of inv(A).
!
      IF( J.LT.N ) &
             CALL DGEMV( 'No transpose', N, N-J, -ONE, A( 1, J+1 ), &
                         LDA, WORK( J+1 ), 1, ONE, A( 1, J ), 1 )
20    CONTINUE
ELSE
!
!        Use blocked code.
!
   NN = ( ( N-1 ) / NB )*NB + 1
   DO 50 J = NN, 1, -NB
      JB = MIN( NB, N-J+1 )
!
!           Copy current block column of L to WORK and replace with
!           zeros.
!
      DO 40 JJ = J, J + JB - 1
         DO 30 I = JJ + 1, N
            WORK( I+( JJ-J )*LDWORK ) = A( I, JJ )
            A( I, JJ ) = ZERO
30          CONTINUE
40       CONTINUE
!
!           Compute current block column of inv(A).
!
      IF( J+JB.LE.N ) &
             CALL DGEMM( 'No transpose', 'No transpose', N, JB, &
                         N-J-JB+1, -ONE, A( 1, J+JB ), LDA, &
                         WORK( J+JB ), LDWORK, ONE, A( 1, J ), LDA )
      CALL DTRSM( 'Right', 'Lower', 'No transpose', 'Unit', N, JB, &
                      ONE, WORK( J ), LDWORK, A( 1, J ), LDA )
50    CONTINUE
END IF
!
!     Apply column interchanges.
!
DO 60 J = N - 1, 1, -1
   JP = IPIV( J )
   IF( JP.NE.J ) &
          CALL DSWAP( N, A( 1, J ), 1, A( 1, JP ), 1 )
60 CONTINUE
!
WORK( 1 ) = IWS
RETURN
!
!     End of DGETRI
!
end subroutine dgetri

! ===== End dgetri.f90 =====


! ===== Begin dgetrs.f90 =====

SUBROUTINE DGETRS( TRANS, N, NRHS, A, LDA, IPIV, B, LDB, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
CHARACTER          TRANS
INTEGER            INFO, LDA, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   A( LDA, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DGETRS solves a system of linear equations
!     A * X = B  or  A' * X = B
!  with a general N-by-N matrix A using the LU factorization computed
!  by DGETRF.
!
!  Arguments
!  =========
!
!  TRANS   (input) CHARACTER*1
!          Specifies the form of the system of equations:
!          = 'N':  A * X = B  (No transpose)
!          = 'T':  A'* X = B  (Transpose)
!          = 'C':  A'* X = B  (Conjugate transpose = Transpose)
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
!          The factors L and U from the factorization A = P*L*U
!          as computed by DGETRF.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  IPIV    (input) INTEGER array, dimension (N)
!          The pivot indices from DGETRF; for 1<=i<=N, row i of the
!          matrix was interchanged with row IPIV(i).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the right hand side matrix B.
!          On exit, the solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            NOTRAN
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DLASWP, DTRSM, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
NOTRAN = LSAME( TRANS, 'N' )
IF( .NOT.NOTRAN .AND. .NOT.LSAME( TRANS, 'T' ) .AND. .NOT. &
        LSAME( TRANS, 'C' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -5
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -8
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGETRS', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 .OR. NRHS.EQ.0 ) &
       RETURN
!
IF( NOTRAN ) THEN
!
!        Solve A * X = B.
!
!        Apply row interchanges to the right hand sides.
!
   CALL DLASWP( NRHS, B, LDB, 1, N, IPIV, 1 )
!
!        Solve L*X = B, overwriting B with X.
!
   CALL DTRSM( 'Left', 'Lower', 'No transpose', 'Unit', N, NRHS, &
                   ONE, A, LDA, B, LDB )
!
!        Solve U*X = B, overwriting B with X.
!
   CALL DTRSM( 'Left', 'Upper', 'No transpose', 'Non-unit', N, &
                   NRHS, ONE, A, LDA, B, LDB )
ELSE
!
!        Solve A' * X = B.
!
!        Solve U'*X = B, overwriting B with X.
!
   CALL DTRSM( 'Left', 'Upper', 'Transpose', 'Non-unit', N, NRHS, &
                   ONE, A, LDA, B, LDB )
!
!        Solve L'*X = B, overwriting B with X.
!
   CALL DTRSM( 'Left', 'Lower', 'Transpose', 'Unit', N, NRHS, ONE, &
                   A, LDA, B, LDB )
!
!        Apply row interchanges to the solution vectors.
!
   CALL DLASWP( NRHS, B, LDB, 1, N, IPIV, -1 )
END IF
!
RETURN
!
!     End of DGETRS
!
end subroutine dgetrs

! ===== End dgetrs.f90 =====


! ===== Begin dggbak.f90 =====

SUBROUTINE DGGBAK( JOB, SIDE, N, ILO, IHI, LSCALE, RSCALE, M, V, &
                       LDV, INFO )
!
!  -- LAPACK routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
CHARACTER          JOB, SIDE
INTEGER            IHI, ILO, INFO, LDV, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   LSCALE( * ), RSCALE( * ), V( LDV, * )
!     ..
!
!  Purpose
!  =======
!
!  DGGBAK forms the right or left eigenvectors of a real generalized
!  eigenvalue problem A*x = lambda*B*x, by backward transformation on
!  the computed eigenvectors of the balanced pair of matrices output by
!  DGGBAL.
!
!  Arguments
!  =========
!
!  JOB     (input) CHARACTER*1
!          Specifies the type of backward transformation required:
!          = 'N':  do nothing, return immediately;
!          = 'P':  do backward transformation for permutation only;
!          = 'S':  do backward transformation for scaling only;
!          = 'B':  do backward transformations for both permutation and
!                  scaling.
!          JOB must be the same as the argument JOB supplied to DGGBAL.
!
!  SIDE    (input) CHARACTER*1
!          = 'R':  V contains right eigenvectors;
!          = 'L':  V contains left eigenvectors.
!
!  N       (input) INTEGER
!          The number of rows of the matrix V.  N >= 0.
!
!  ILO     (input) INTEGER
!  IHI     (input) INTEGER
!          The integers ILO and IHI determined by DGGBAL.
!          1 <= ILO <= IHI <= N, if N > 0; ILO=1 and IHI=0, if N=0.
!
!  LSCALE  (input) DOUBLE PRECISION array, dimension (N)
!          Details of the permutations and/or scaling factors applied
!          to the left side of A and B, as returned by DGGBAL.
!
!  RSCALE  (input) DOUBLE PRECISION array, dimension (N)
!          Details of the permutations and/or scaling factors applied
!          to the right side of A and B, as returned by DGGBAL.
!
!  M       (input) INTEGER
!          The number of columns of the matrix V.  M >= 0.
!
!  V       (input/output) DOUBLE PRECISION array, dimension (LDV,M)
!          On entry, the matrix of right or left eigenvectors to be
!          transformed, as returned by DTGEVC.
!          On exit, V is overwritten by the transformed eigenvectors.
!
!  LDV     (input) INTEGER
!          The leading dimension of the matrix V. LDV >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit.
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!
!  Further Details
!  ===============
!
!  See R.C. Ward, Balancing the generalized eigenvalue problem,
!                 SIAM J. Sci. Stat. Comp. 2 (1981), 141-152.
!
!  =====================================================================
!
!     .. Local Scalars ..
LOGICAL            LEFTV, RIGHTV
INTEGER            I, K
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DSCAL, DSWAP, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters
!
RIGHTV = LSAME( SIDE, 'R' )
LEFTV = LSAME( SIDE, 'L' )
!
INFO = 0
IF( .NOT.LSAME( JOB, 'N' ) .AND. .NOT.LSAME( JOB, 'P' ) .AND. &
        .NOT.LSAME( JOB, 'S' ) .AND. .NOT.LSAME( JOB, 'B' ) ) THEN
   INFO = -1
ELSE IF( .NOT.RIGHTV .AND. .NOT.LEFTV ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( ILO.LT.1 ) THEN
   INFO = -4
ELSE IF( N.EQ.0 .AND. IHI.EQ.0 .AND. ILO.NE.1 ) THEN
   INFO = -4
ELSE IF( N.GT.0 .AND. ( IHI.LT.ILO .OR. IHI.GT.MAX( 1, N ) ) ) &
       THEN
   INFO = -5
ELSE IF( N.EQ.0 .AND. ILO.EQ.1 .AND. IHI.NE.0 ) THEN
   INFO = -5
ELSE IF( M.LT.0 ) THEN
   INFO = -8
ELSE IF( LDV.LT.MAX( 1, N ) ) THEN
   INFO = -10
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGGBAK', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
IF( M.EQ.0 ) &
       RETURN
IF( LSAME( JOB, 'N' ) ) &
       RETURN
!
IF( ILO.EQ.IHI ) &
       GO TO 30
!
!     Backward balance
!
IF( LSAME( JOB, 'S' ) .OR. LSAME( JOB, 'B' ) ) THEN
!
!        Backward transformation on right eigenvectors
!
   IF( RIGHTV ) THEN
      DO 10 I = ILO, IHI
         CALL DSCAL( M, RSCALE( I ), V( I, 1 ), LDV )
10       CONTINUE
   END IF
!
!        Backward transformation on left eigenvectors
!
   IF( LEFTV ) THEN
      DO 20 I = ILO, IHI
         CALL DSCAL( M, LSCALE( I ), V( I, 1 ), LDV )
20       CONTINUE
   END IF
END IF
!
!     Backward permutation
!
30 CONTINUE
IF( LSAME( JOB, 'P' ) .OR. LSAME( JOB, 'B' ) ) THEN
!
!        Backward permutation on right eigenvectors
!
   IF( RIGHTV ) THEN
      IF( ILO.EQ.1 ) &
             GO TO 50
!
      DO 40 I = ILO - 1, 1, -1
         K = RSCALE( I )
         IF( K.EQ.I ) &
                GO TO 40
         CALL DSWAP( M, V( I, 1 ), LDV, V( K, 1 ), LDV )
40       CONTINUE
!
50       CONTINUE
      IF( IHI.EQ.N ) &
             GO TO 70
      DO 60 I = IHI + 1, N
         K = RSCALE( I )
         IF( K.EQ.I ) &
                GO TO 60
         CALL DSWAP( M, V( I, 1 ), LDV, V( K, 1 ), LDV )
60       CONTINUE
   END IF
!
!        Backward permutation on left eigenvectors
!
70    CONTINUE
   IF( LEFTV ) THEN
      IF( ILO.EQ.1 ) &
             GO TO 90
      DO 80 I = ILO - 1, 1, -1
         K = LSCALE( I )
         IF( K.EQ.I ) &
                GO TO 80
         CALL DSWAP( M, V( I, 1 ), LDV, V( K, 1 ), LDV )
80       CONTINUE
!
90       CONTINUE
      IF( IHI.EQ.N ) &
             GO TO 110
      DO 100 I = IHI + 1, N
         K = LSCALE( I )
         IF( K.EQ.I ) &
                GO TO 100
         CALL DSWAP( M, V( I, 1 ), LDV, V( K, 1 ), LDV )
100       CONTINUE
   END IF
END IF
!
110 CONTINUE
!
RETURN
!
!     End of DGGBAK
!
end subroutine dggbak

! ===== End dggbak.f90 =====


! ===== Begin dggbal.f90 =====

SUBROUTINE DGGBAL( JOB, N, A, LDA, B, LDB, ILO, IHI, LSCALE, &
                       RSCALE, WORK, INFO )
!
!  -- LAPACK routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
CHARACTER          JOB
INTEGER            IHI, ILO, INFO, LDA, LDB, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), B( LDB, * ), LSCALE( * ), &
                       RSCALE( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGGBAL balances a pair of general real matrices (A,B).  This
!  involves, first, permuting A and B by similarity transformations to
!  isolate eigenvalues in the first 1 to ILO$-$1 and last IHI+1 to N
!  elements on the diagonal; and second, applying a diagonal similarity
!  transformation to rows and columns ILO to IHI to make the rows
!  and columns as close in norm as possible. Both steps are optional.
!
!  Balancing may reduce the 1-norm of the matrices, and improve the
!  accuracy of the computed eigenvalues and/or eigenvectors in the
!  generalized eigenvalue problem A*x = lambda*B*x.
!
!  Arguments
!  =========
!
!  JOB     (input) CHARACTER*1
!          Specifies the operations to be performed on A and B:
!          = 'N':  none:  simply set ILO = 1, IHI = N, LSCALE(I) = 1.0
!                  and RSCALE(I) = 1.0 for i = 1,...,N.
!          = 'P':  permute only;
!          = 'S':  scale only;
!          = 'B':  both permute and scale.
!
!  N       (input) INTEGER
!          The order of the matrices A and B.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the input matrix A.
!          On exit,  A is overwritten by the balanced matrix.
!          If JOB = 'N', A is not referenced.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A. LDA >= max(1,N).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,N)
!          On entry, the input matrix B.
!          On exit,  B is overwritten by the balanced matrix.
!          If JOB = 'N', B is not referenced.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B. LDB >= max(1,N).
!
!  ILO     (output) INTEGER
!  IHI     (output) INTEGER
!          ILO and IHI are set to integers such that on exit
!          A(i,j) = 0 and B(i,j) = 0 if i > j and
!          j = 1,...,ILO-1 or i = IHI+1,...,N.
!          If JOB = 'N' or 'S', ILO = 1 and IHI = N.
!
!  LSCALE  (output) DOUBLE PRECISION array, dimension (N)
!          Details of the permutations and scaling factors applied
!          to the left side of A and B.  If P(j) is the index of the
!          row interchanged with row j, and D(j)
!          is the scaling factor applied to row j, then
!            LSCALE(j) = P(j)    for J = 1,...,ILO-1
!                      = D(j)    for J = ILO,...,IHI
!                      = P(j)    for J = IHI+1,...,N.
!          The order in which the interchanges are made is N to IHI+1,
!          then 1 to ILO-1.
!
!  RSCALE  (output) DOUBLE PRECISION array, dimension (N)
!          Details of the permutations and scaling factors applied
!          to the right side of A and B.  If P(j) is the index of the
!          column interchanged with column j, and D(j)
!          is the scaling factor applied to column j, then
!            LSCALE(j) = P(j)    for J = 1,...,ILO-1
!                      = D(j)    for J = ILO,...,IHI
!                      = P(j)    for J = IHI+1,...,N.
!          The order in which the interchanges are made is N to IHI+1,
!          then 1 to ILO-1.
!
!  WORK    (workspace) REAL array, dimension (lwork)
!          lwork must be at least max(1,6*N) when JOB = 'S' or 'B', and
!          at least 1 when JOB = 'N' or 'P'.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!
!  Further Details
!  ===============
!
!  See R.C. WARD, Balancing the generalized eigenvalue problem,
!                 SIAM J. Sci. Stat. Comp. 2 (1981), 141-152.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, HALF, ONE
PARAMETER          ( ZERO = 0.0D+0, HALF = 0.5D+0, ONE = 1.0D+0 )
DOUBLE PRECISION   THREE, SCLFAC
PARAMETER          ( THREE = 3.0D+0, SCLFAC = 1.0D+1 )
!     ..
!     .. Local Scalars ..
INTEGER            I, ICAB, IFLOW, IP1, IR, IRAB, IT, J, JC, JP1, &
                       K, KOUNT, L, LCAB, LM1, LRAB, LSFMAX, LSFMIN, &
                       M, NR, NRP2
DOUBLE PRECISION   ALPHA, BASL, BETA, CAB, CMAX, COEF, COEF2, &
                       COEF5, COR, EW, EWC, GAMMA, PGAMMA, RAB, SFMAX, &
                       SFMIN, SUM, T, TA, TB, TC
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            IDAMAX
DOUBLE PRECISION   DDOT, DLAMCH
EXTERNAL           LSAME, IDAMAX, DDOT, DLAMCH
!     ..
!     .. External Subroutines ..
EXTERNAL           DAXPY, DSCAL, DSWAP, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, DBLE, INT, LOG10, MAX, MIN, SIGN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters
!
INFO = 0
IF( .NOT.LSAME( JOB, 'N' ) .AND. .NOT.LSAME( JOB, 'P' ) .AND. &
        .NOT.LSAME( JOB, 'S' ) .AND. .NOT.LSAME( JOB, 'B' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -4
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -6
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGGBAL', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) THEN
   ILO = 1
   IHI = N
   RETURN
END IF
!
IF( N.EQ.1 ) THEN
   ILO = 1
   IHI = N
   LSCALE( 1 ) = ONE
   RSCALE( 1 ) = ONE
   RETURN
END IF
!
IF( LSAME( JOB, 'N' ) ) THEN
   ILO = 1
   IHI = N
   DO 10 I = 1, N
      LSCALE( I ) = ONE
      RSCALE( I ) = ONE
10    CONTINUE
   RETURN
END IF
!
K = 1
L = N
IF( LSAME( JOB, 'S' ) ) &
       GO TO 190
!
GO TO 30
!
!     Permute the matrices A and B to isolate the eigenvalues.
!
!     Find row with one nonzero in columns 1 through L
!
20 CONTINUE
L = LM1
IF( L.NE.1 ) &
       GO TO 30
!
RSCALE( 1 ) = ONE
LSCALE( 1 ) = ONE
GO TO 190
!
30 CONTINUE
LM1 = L - 1
DO 80 I = L, 1, -1
   DO 40 J = 1, LM1
      JP1 = J + 1
      IF( A( I, J ).NE.ZERO .OR. B( I, J ).NE.ZERO ) &
             GO TO 50
40    CONTINUE
   J = L
   GO TO 70
!
50    CONTINUE
   DO 60 J = JP1, L
      IF( A( I, J ).NE.ZERO .OR. B( I, J ).NE.ZERO ) &
             GO TO 80
60    CONTINUE
   J = JP1 - 1
!
70    CONTINUE
   M = L
   IFLOW = 1
   GO TO 160
80 CONTINUE
GO TO 100
!
!     Find column with one nonzero in rows K through N
!
90 CONTINUE
K = K + 1
!
100 CONTINUE
DO 150 J = K, L
   DO 110 I = K, LM1
      IP1 = I + 1
      IF( A( I, J ).NE.ZERO .OR. B( I, J ).NE.ZERO ) &
             GO TO 120
110    CONTINUE
   I = L
   GO TO 140
120    CONTINUE
   DO 130 I = IP1, L
      IF( A( I, J ).NE.ZERO .OR. B( I, J ).NE.ZERO ) &
             GO TO 150
130    CONTINUE
   I = IP1 - 1
140    CONTINUE
   M = K
   IFLOW = 2
   GO TO 160
150 CONTINUE
GO TO 190
!
!     Permute rows M and I
!
160 CONTINUE
LSCALE( M ) = I
IF( I.EQ.M ) &
       GO TO 170
CALL DSWAP( N-K+1, A( I, K ), LDA, A( M, K ), LDA )
CALL DSWAP( N-K+1, B( I, K ), LDB, B( M, K ), LDB )
!
!     Permute columns M and J
!
170 CONTINUE
RSCALE( M ) = J
IF( J.EQ.M ) &
       GO TO 180
CALL DSWAP( L, A( 1, J ), 1, A( 1, M ), 1 )
CALL DSWAP( L, B( 1, J ), 1, B( 1, M ), 1 )
!
180 CONTINUE
GO TO ( 20, 90 )IFLOW
!
190 CONTINUE
ILO = K
IHI = L
!
IF( LSAME( JOB, 'P' ) ) THEN
   DO 195 I = ILO, IHI
      LSCALE( I ) = ONE
      RSCALE( I ) = ONE
195    CONTINUE
   RETURN
END IF
!
IF( ILO.EQ.IHI ) &
       RETURN
!
!     Balance the submatrix in rows ILO to IHI.
!
NR = IHI - ILO + 1
DO 200 I = ILO, IHI
   RSCALE( I ) = ZERO
   LSCALE( I ) = ZERO
!
   WORK( I ) = ZERO
   WORK( I+N ) = ZERO
   WORK( I+2*N ) = ZERO
   WORK( I+3*N ) = ZERO
   WORK( I+4*N ) = ZERO
   WORK( I+5*N ) = ZERO
200 CONTINUE
!
!     Compute right side vector in resulting linear equations
!
BASL = LOG10( SCLFAC )
DO 240 I = ILO, IHI
   DO 230 J = ILO, IHI
      TB = B( I, J )
      TA = A( I, J )
      IF( TA.EQ.ZERO ) &
             GO TO 210
      TA = LOG10( ABS( TA ) ) / BASL
210       CONTINUE
      IF( TB.EQ.ZERO ) &
             GO TO 220
      TB = LOG10( ABS( TB ) ) / BASL
220       CONTINUE
      WORK( I+4*N ) = WORK( I+4*N ) - TA - TB
      WORK( J+5*N ) = WORK( J+5*N ) - TA - TB
230    CONTINUE
240 CONTINUE
!
COEF = ONE / DBLE( 2*NR )
COEF2 = COEF*COEF
COEF5 = HALF*COEF2
NRP2 = NR + 2
BETA = ZERO
IT = 1
!
!     Start generalized conjugate gradient iteration
!
250 CONTINUE
!
GAMMA = DDOT( NR, WORK( ILO+4*N ), 1, WORK( ILO+4*N ), 1 ) + &
            DDOT( NR, WORK( ILO+5*N ), 1, WORK( ILO+5*N ), 1 )
!
EW = ZERO
EWC = ZERO
DO 260 I = ILO, IHI
   EW = EW + WORK( I+4*N )
   EWC = EWC + WORK( I+5*N )
260 CONTINUE
!
GAMMA = COEF*GAMMA - COEF2*( EW**2+EWC**2 ) - COEF5*( EW-EWC )**2
IF( GAMMA.EQ.ZERO ) &
       GO TO 350
IF( IT.NE.1 ) &
       BETA = GAMMA / PGAMMA
T = COEF5*( EWC-THREE*EW )
TC = COEF5*( EW-THREE*EWC )
!
CALL DSCAL( NR, BETA, WORK( ILO ), 1 )
CALL DSCAL( NR, BETA, WORK( ILO+N ), 1 )
!
CALL DAXPY( NR, COEF, WORK( ILO+4*N ), 1, WORK( ILO+N ), 1 )
CALL DAXPY( NR, COEF, WORK( ILO+5*N ), 1, WORK( ILO ), 1 )
!
DO 270 I = ILO, IHI
   WORK( I ) = WORK( I ) + TC
   WORK( I+N ) = WORK( I+N ) + T
270 CONTINUE
!
!     Apply matrix to vector
!
DO 300 I = ILO, IHI
   KOUNT = 0
   SUM = ZERO
   DO 290 J = ILO, IHI
      IF( A( I, J ).EQ.ZERO ) &
             GO TO 280
      KOUNT = KOUNT + 1
      SUM = SUM + WORK( J )
280       CONTINUE
      IF( B( I, J ).EQ.ZERO ) &
             GO TO 290
      KOUNT = KOUNT + 1
      SUM = SUM + WORK( J )
290    CONTINUE
   WORK( I+2*N ) = DBLE( KOUNT )*WORK( I+N ) + SUM
300 CONTINUE
!
DO 330 J = ILO, IHI
   KOUNT = 0
   SUM = ZERO
   DO 320 I = ILO, IHI
      IF( A( I, J ).EQ.ZERO ) &
             GO TO 310
      KOUNT = KOUNT + 1
      SUM = SUM + WORK( I+N )
310       CONTINUE
      IF( B( I, J ).EQ.ZERO ) &
             GO TO 320
      KOUNT = KOUNT + 1
      SUM = SUM + WORK( I+N )
320    CONTINUE
   WORK( J+3*N ) = DBLE( KOUNT )*WORK( J ) + SUM
330 CONTINUE
!
SUM = DDOT( NR, WORK( ILO+N ), 1, WORK( ILO+2*N ), 1 ) + &
          DDOT( NR, WORK( ILO ), 1, WORK( ILO+3*N ), 1 )
ALPHA = GAMMA / SUM
!
!     Determine correction to current iteration
!
CMAX = ZERO
DO 340 I = ILO, IHI
   COR = ALPHA*WORK( I+N )
   IF( ABS( COR ).GT.CMAX ) &
          CMAX = ABS( COR )
   LSCALE( I ) = LSCALE( I ) + COR
   COR = ALPHA*WORK( I )
   IF( ABS( COR ).GT.CMAX ) &
          CMAX = ABS( COR )
   RSCALE( I ) = RSCALE( I ) + COR
340 CONTINUE
IF( CMAX.LT.HALF ) &
       GO TO 350
!
CALL DAXPY( NR, -ALPHA, WORK( ILO+2*N ), 1, WORK( ILO+4*N ), 1 )
CALL DAXPY( NR, -ALPHA, WORK( ILO+3*N ), 1, WORK( ILO+5*N ), 1 )
!
PGAMMA = GAMMA
IT = IT + 1
IF( IT.LE.NRP2 ) &
       GO TO 250
!
!     End generalized conjugate gradient iteration
!
350 CONTINUE
SFMIN = DLAMCH( 'S' )
SFMAX = ONE / SFMIN
LSFMIN = INT( LOG10( SFMIN ) / BASL+ONE )
LSFMAX = INT( LOG10( SFMAX ) / BASL )
DO 360 I = ILO, IHI
   IRAB = IDAMAX( N-ILO+1, A( I, ILO ), LDA )
   RAB = ABS( A( I, IRAB+ILO-1 ) )
   IRAB = IDAMAX( N-ILO+1, B( I, ILO ), LDB )
   RAB = MAX( RAB, ABS( B( I, IRAB+ILO-1 ) ) )
   LRAB = INT( LOG10( RAB+SFMIN ) / BASL+ONE )
   IR = LSCALE( I ) + SIGN( HALF, LSCALE( I ) )
   IR = MIN( MAX( IR, LSFMIN ), LSFMAX, LSFMAX-LRAB )
   LSCALE( I ) = SCLFAC**IR
   ICAB = IDAMAX( IHI, A( 1, I ), 1 )
   CAB = ABS( A( ICAB, I ) )
   ICAB = IDAMAX( IHI, B( 1, I ), 1 )
   CAB = MAX( CAB, ABS( B( ICAB, I ) ) )
   LCAB = INT( LOG10( CAB+SFMIN ) / BASL+ONE )
   JC = RSCALE( I ) + SIGN( HALF, RSCALE( I ) )
   JC = MIN( MAX( JC, LSFMIN ), LSFMAX, LSFMAX-LCAB )
   RSCALE( I ) = SCLFAC**JC
360 CONTINUE
!
!     Row scaling of matrices A and B
!
DO 370 I = ILO, IHI
   CALL DSCAL( N-ILO+1, LSCALE( I ), A( I, ILO ), LDA )
   CALL DSCAL( N-ILO+1, LSCALE( I ), B( I, ILO ), LDB )
370 CONTINUE
!
!     Column scaling of matrices A and B
!
DO 380 J = ILO, IHI
   CALL DSCAL( IHI, RSCALE( J ), A( 1, J ), 1 )
   CALL DSCAL( IHI, RSCALE( J ), B( 1, J ), 1 )
380 CONTINUE
!
RETURN
!
!     End of DGGBAL
!
end subroutine dggbal

! ===== End dggbal.f90 =====


! ===== Begin dggev.f90 =====

SUBROUTINE DGGEV( JOBVL, JOBVR, N, A, LDA, B, LDB, ALPHAR, ALPHAI, &
                      BETA, VL, LDVL, VR, LDVR, WORK, LWORK, INFO )
!
!  -- LAPACK driver routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
CHARACTER          JOBVL, JOBVR
INTEGER            INFO, LDA, LDB, LDVL, LDVR, LWORK, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), ALPHAI( * ), ALPHAR( * ), &
                       B( LDB, * ), BETA( * ), VL( LDVL, * ), &
                       VR( LDVR, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DGGEV computes for a pair of N-by-N real nonsymmetric matrices (A,B)
!  the generalized eigenvalues, and optionally, the left and/or right
!  generalized eigenvectors.
!
!  A generalized eigenvalue for a pair of matrices (A,B) is a scalar
!  lambda or a ratio alpha/beta = lambda, such that A - lambda*B is
!  singular. It is usually represented as the pair (alpha,beta), as
!  there is a reasonable interpretation for beta=0, and even for both
!  being zero.
!
!  The right eigenvector v(j) corresponding to the eigenvalue lambda(j)
!  of (A,B) satisfies
!
!                   A * v(j) = lambda(j) * B * v(j).
!
!  The left eigenvector u(j) corresponding to the eigenvalue lambda(j)
!  of (A,B) satisfies
!
!                   u(j)**H * A  = lambda(j) * u(j)**H * B .
!
!  where u(j)**H is the conjugate-transpose of u(j).
!
!
!  Arguments
!  =========
!
!  JOBVL   (input) CHARACTER*1
!          = 'N':  do not compute the left generalized eigenvectors;
!          = 'V':  compute the left generalized eigenvectors.
!
!  JOBVR   (input) CHARACTER*1
!          = 'N':  do not compute the right generalized eigenvectors;
!          = 'V':  compute the right generalized eigenvectors.
!
!  N       (input) INTEGER
!          The order of the matrices A, B, VL, and VR.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA, N)
!          On entry, the matrix A in the pair (A,B).
!          On exit, A has been overwritten.
!
!  LDA     (input) INTEGER
!          The leading dimension of A.  LDA >= max(1,N).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB, N)
!          On entry, the matrix B in the pair (A,B).
!          On exit, B has been overwritten.
!
!  LDB     (input) INTEGER
!          The leading dimension of B.  LDB >= max(1,N).
!
!  ALPHAR  (output) DOUBLE PRECISION array, dimension (N)
!  ALPHAI  (output) DOUBLE PRECISION array, dimension (N)
!  BETA    (output) DOUBLE PRECISION array, dimension (N)
!          On exit, (ALPHAR(j) + ALPHAI(j)*i)/BETA(j), j=1,...,N, will
!          be the generalized eigenvalues.  If ALPHAI(j) is zero, then
!          the j-th eigenvalue is real; if positive, then the j-th and
!          (j+1)-st eigenvalues are a complex conjugate pair, with
!          ALPHAI(j+1) negative.
!
!          Note: the quotients ALPHAR(j)/BETA(j) and ALPHAI(j)/BETA(j)
!          may easily over- or underflow, and BETA(j) may even be zero.
!          Thus, the user should avoid naively computing the ratio
!          alpha/beta.  However, ALPHAR and ALPHAI will be always less
!          than and usually comparable with norm(A) in magnitude, and
!          BETA always less than and usually comparable with norm(B).
!
!  VL      (output) DOUBLE PRECISION array, dimension (LDVL,N)
!          If JOBVL = 'V', the left eigenvectors u(j) are stored one
!          after another in the columns of VL, in the same order as
!          their eigenvalues. If the j-th eigenvalue is real, then
!          u(j) = VL(:,j), the j-th column of VL. If the j-th and
!          (j+1)-th eigenvalues form a complex conjugate pair, then
!          u(j) = VL(:,j)+i*VL(:,j+1) and u(j+1) = VL(:,j)-i*VL(:,j+1).
!          Each eigenvector is scaled so the largest component has
!          abs(real part)+abs(imag. part)=1.
!          Not referenced if JOBVL = 'N'.
!
!  LDVL    (input) INTEGER
!          The leading dimension of the matrix VL. LDVL >= 1, and
!          if JOBVL = 'V', LDVL >= N.
!
!  VR      (output) DOUBLE PRECISION array, dimension (LDVR,N)
!          If JOBVR = 'V', the right eigenvectors v(j) are stored one
!          after another in the columns of VR, in the same order as
!          their eigenvalues. If the j-th eigenvalue is real, then
!          v(j) = VR(:,j), the j-th column of VR. If the j-th and
!          (j+1)-th eigenvalues form a complex conjugate pair, then
!          v(j) = VR(:,j)+i*VR(:,j+1) and v(j+1) = VR(:,j)-i*VR(:,j+1).
!          Each eigenvector is scaled so the largest component has
!          abs(real part)+abs(imag. part)=1.
!          Not referenced if JOBVR = 'N'.
!
!  LDVR    (input) INTEGER
!          The leading dimension of the matrix VR. LDVR >= 1, and
!          if JOBVR = 'V', LDVR >= N.
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (MAX(1,LWORK))
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.  LWORK >= max(1,8*N).
!          For good performance, LWORK must generally be larger.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!          = 1,...,N:
!                The QZ iteration failed.  No eigenvectors have been
!                calculated, but ALPHAR(j), ALPHAI(j), and BETA(j)
!                should be correct for j=INFO+1,...,N.
!          > N:  =N+1: other than QZ iteration failed in DHGEQZ.
!                =N+2: error return from DTGEVC.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            ILASCL, ILBSCL, ILV, ILVL, ILVR, LQUERY
CHARACTER          CHTEMP
INTEGER            ICOLS, IERR, IHI, IJOBVL, IJOBVR, ILEFT, ILO, &
                       IN, IRIGHT, IROWS, ITAU, IWRK, JC, JR, MAXWRK, &
                       MINWRK
DOUBLE PRECISION   ANRM, ANRMTO, BIGNUM, BNRM, BNRMTO, EPS, &
                       SMLNUM, TEMP
!     ..
!     .. Local Arrays ..
LOGICAL            LDUMMA( 1 )
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEQRF, DGGBAK, DGGBAL, DGGHRD, DHGEQZ, DLABAD, &
                       DLACPY,DLASCL, DLASET, DORGQR, DORMQR, DTGEVC, &
                       XERBLA
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            ILAENV
DOUBLE PRECISION   DLAMCH, DLANGE
EXTERNAL           LSAME, ILAENV, DLAMCH, DLANGE
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, SQRT
!     ..
!     .. Executable Statements ..
!
!     Decode the input arguments
!
IF( LSAME( JOBVL, 'N' ) ) THEN
   IJOBVL = 1
   ILVL = .FALSE.
ELSE IF( LSAME( JOBVL, 'V' ) ) THEN
   IJOBVL = 2
   ILVL = .TRUE.
ELSE
   IJOBVL = -1
   ILVL = .FALSE.
END IF
!
IF( LSAME( JOBVR, 'N' ) ) THEN
   IJOBVR = 1
   ILVR = .FALSE.
ELSE IF( LSAME( JOBVR, 'V' ) ) THEN
   IJOBVR = 2
   ILVR = .TRUE.
ELSE
   IJOBVR = -1
   ILVR = .FALSE.
END IF
ILV = ILVL .OR. ILVR
!
!     Test the input arguments
!
INFO = 0
LQUERY = ( LWORK.EQ.-1 )
IF( IJOBVL.LE.0 ) THEN
   INFO = -1
ELSE IF( IJOBVR.LE.0 ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -5
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -7
ELSE IF( LDVL.LT.1 .OR. ( ILVL .AND. LDVL.LT.N ) ) THEN
   INFO = -12
ELSE IF( LDVR.LT.1 .OR. ( ILVR .AND. LDVR.LT.N ) ) THEN
   INFO = -14
END IF
!
!     Compute workspace
!      (Note: Comments in the code beginning "Workspace:" describe the
!       minimal amount of workspace needed at that point in the code,
!       as well as the preferred amount for good performance.
!       NB refers to the optimal block size for the immediately
!       following subroutine, as returned by ILAENV. The workspace is
!       computed assuming ILO = 1 and IHI = N, the worst case.)
!
IF( INFO.EQ.0 ) THEN
   MINWRK = MAX( 1, 8*N )
   MAXWRK = MAX( 1, N*( 7 + &
                     ILAENV( 1, 'DGEQRF', ' ', N, 1, N, 0 ) ) )
   MAXWRK = MAX( MAXWRK, N*( 7 + &
                     ILAENV( 1, 'DORMQR', ' ', N, 1, N, 0 ) ) )
   IF( ILVL ) THEN
      MAXWRK = MAX( MAXWRK, N*( 7 + &
                     ILAENV( 1, 'DORGQR', ' ', N, 1, N, -1 ) ) )
   END IF
   WORK( 1 ) = MAXWRK
!
   IF( LWORK.LT.MINWRK .AND. .NOT.LQUERY ) &
          INFO = -16
END IF
!
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGGEV ', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Get machine constants
!
EPS = DLAMCH( 'P' )
SMLNUM = DLAMCH( 'S' )
BIGNUM = ONE / SMLNUM
CALL DLABAD( SMLNUM, BIGNUM )
SMLNUM = SQRT( SMLNUM ) / EPS
BIGNUM = ONE / SMLNUM
!
!     Scale A if max element outside range [SMLNUM,BIGNUM]
!
ANRM = DLANGE( 'M', N, N, A, LDA, WORK )
ILASCL = .FALSE.
IF( ANRM.GT.ZERO .AND. ANRM.LT.SMLNUM ) THEN
   ANRMTO = SMLNUM
   ILASCL = .TRUE.
ELSE IF( ANRM.GT.BIGNUM ) THEN
   ANRMTO = BIGNUM
   ILASCL = .TRUE.
END IF
IF( ILASCL ) &
       CALL DLASCL( 'G', 0, 0, ANRM, ANRMTO, N, N, A, LDA, IERR )
!
!     Scale B if max element outside range [SMLNUM,BIGNUM]
!
BNRM = DLANGE( 'M', N, N, B, LDB, WORK )
ILBSCL = .FALSE.
IF( BNRM.GT.ZERO .AND. BNRM.LT.SMLNUM ) THEN
   BNRMTO = SMLNUM
   ILBSCL = .TRUE.
ELSE IF( BNRM.GT.BIGNUM ) THEN
   BNRMTO = BIGNUM
   ILBSCL = .TRUE.
END IF
IF( ILBSCL ) &
       CALL DLASCL( 'G', 0, 0, BNRM, BNRMTO, N, N, B, LDB, IERR )
!
!     Permute the matrices A, B to isolate eigenvalues if possible
!     (Workspace: need 6*N)
!
ILEFT = 1
IRIGHT = N + 1
IWRK = IRIGHT + N
CALL DGGBAL( 'P', N, A, LDA, B, LDB, ILO, IHI, WORK( ILEFT ), &
                 WORK( IRIGHT ), WORK( IWRK ), IERR )
!
!     Reduce B to triangular form (QR decomposition of B)
!     (Workspace: need N, prefer N*NB)
!
IROWS = IHI + 1 - ILO
IF( ILV ) THEN
   ICOLS = N + 1 - ILO
ELSE
   ICOLS = IROWS
END IF
ITAU = IWRK
IWRK = ITAU + IROWS
CALL DGEQRF( IROWS, ICOLS, B( ILO, ILO ), LDB, WORK( ITAU ), &
                 WORK( IWRK ), LWORK+1-IWRK, IERR )
!
!     Apply the orthogonal transformation to matrix A
!     (Workspace: need N, prefer N*NB)
!
CALL DORMQR( 'L', 'T', IROWS, ICOLS, IROWS, B( ILO, ILO ), LDB, &
                 WORK( ITAU ), A( ILO, ILO ), LDA, WORK( IWRK ), &
                 LWORK+1-IWRK, IERR )
!
!     Initialize VL
!     (Workspace: need N, prefer N*NB)
!
IF( ILVL ) THEN
   CALL DLASET( 'Full', N, N, ZERO, ONE, VL, LDVL )
   IF( IROWS.GT.1 ) THEN
      CALL DLACPY( 'L', IROWS-1, IROWS-1, B( ILO+1, ILO ), LDB, &
                       VL( ILO+1, ILO ), LDVL )
   END IF
   CALL DORGQR( IROWS, IROWS, IROWS, VL( ILO, ILO ), LDVL, &
                    WORK( ITAU ), WORK( IWRK ), LWORK+1-IWRK, IERR )
END IF
!
!     Initialize VR
!
IF( ILVR ) &
       CALL DLASET( 'Full', N, N, ZERO, ONE, VR, LDVR )
!
!     Reduce to generalized Hessenberg form
!     (Workspace: none needed)
!
IF( ILV ) THEN
!
!        Eigenvectors requested -- work on whole matrix.
!
   CALL DGGHRD( JOBVL, JOBVR, N, ILO, IHI, A, LDA, B, LDB, VL, &
                    LDVL, VR, LDVR, IERR )
ELSE
   CALL DGGHRD( 'N', 'N', IROWS, 1, IROWS, A( ILO, ILO ), LDA, &
                    B( ILO, ILO ), LDB, VL, LDVL, VR, LDVR, IERR )
END IF
!
!     Perform QZ algorithm (Compute eigenvalues, and optionally, the
!     Schur forms and Schur vectors)
!     (Workspace: need N)
!
IWRK = ITAU
IF( ILV ) THEN
   CHTEMP = 'S'
ELSE
   CHTEMP = 'E'
END IF
CALL DHGEQZ( CHTEMP, JOBVL, JOBVR, N, ILO, IHI, A, LDA, B, LDB, &
                 ALPHAR, ALPHAI, BETA, VL, LDVL, VR, LDVR, &
                 WORK( IWRK ), LWORK+1-IWRK, IERR )
IF( IERR.NE.0 ) THEN
   IF( IERR.GT.0 .AND. IERR.LE.N ) THEN
      INFO = IERR
   ELSE IF( IERR.GT.N .AND. IERR.LE.2*N ) THEN
      INFO = IERR - N
   ELSE
      INFO = N + 1
   END IF
   GO TO 110
END IF
!
!     Compute Eigenvectors
!     (Workspace: need 6*N)
!
IF( ILV ) THEN
   IF( ILVL ) THEN
      IF( ILVR ) THEN
         CHTEMP = 'B'
      ELSE
         CHTEMP = 'L'
      END IF
   ELSE
      CHTEMP = 'R'
   END IF
   CALL DTGEVC( CHTEMP, 'B', LDUMMA, N, A, LDA, B, LDB, VL, LDVL, &
                    VR, LDVR, N, IN, WORK( IWRK ), IERR )
   IF( IERR.NE.0 ) THEN
      INFO = N + 2
      GO TO 110
   END IF
!
!        Undo balancing on VL and VR and normalization
!        (Workspace: none needed)
!
   IF( ILVL ) THEN
      CALL DGGBAK( 'P', 'L', N, ILO, IHI, WORK( ILEFT ), &
                       WORK( IRIGHT ), N, VL, LDVL, IERR )
      DO 50 JC = 1, N
         IF( ALPHAI( JC ).LT.ZERO ) &
                GO TO 50
         TEMP = ZERO
         IF( ALPHAI( JC ).EQ.ZERO ) THEN
            DO 10 JR = 1, N
               TEMP = MAX( TEMP, ABS( VL( JR, JC ) ) )
10             CONTINUE
         ELSE
            DO 20 JR = 1, N
               TEMP = MAX( TEMP, ABS( VL( JR, JC ) )+ &
                          ABS( VL( JR, JC+1 ) ) )
20             CONTINUE
         END IF
         IF( TEMP.LT.SMLNUM ) &
                GO TO 50
         TEMP = ONE / TEMP
         IF( ALPHAI( JC ).EQ.ZERO ) THEN
            DO 30 JR = 1, N
               VL( JR, JC ) = VL( JR, JC )*TEMP
30             CONTINUE
         ELSE
            DO 40 JR = 1, N
               VL( JR, JC ) = VL( JR, JC )*TEMP
               VL( JR, JC+1 ) = VL( JR, JC+1 )*TEMP
40             CONTINUE
         END IF
50       CONTINUE
   END IF
   IF( ILVR ) THEN
      CALL DGGBAK( 'P', 'R', N, ILO, IHI, WORK( ILEFT ), &
                       WORK( IRIGHT ), N, VR, LDVR, IERR )
      DO 100 JC = 1, N
         IF( ALPHAI( JC ).LT.ZERO ) &
                GO TO 100
         TEMP = ZERO
         IF( ALPHAI( JC ).EQ.ZERO ) THEN
            DO 60 JR = 1, N
               TEMP = MAX( TEMP, ABS( VR( JR, JC ) ) )
60             CONTINUE
         ELSE
            DO 70 JR = 1, N
               TEMP = MAX( TEMP, ABS( VR( JR, JC ) )+ &
                          ABS( VR( JR, JC+1 ) ) )
70             CONTINUE
         END IF
         IF( TEMP.LT.SMLNUM ) &
                GO TO 100
         TEMP = ONE / TEMP
         IF( ALPHAI( JC ).EQ.ZERO ) THEN
            DO 80 JR = 1, N
               VR( JR, JC ) = VR( JR, JC )*TEMP
80             CONTINUE
         ELSE
            DO 90 JR = 1, N
               VR( JR, JC ) = VR( JR, JC )*TEMP
               VR( JR, JC+1 ) = VR( JR, JC+1 )*TEMP
90             CONTINUE
         END IF
100       CONTINUE
   END IF
!
!        End of eigenvector calculation
!
END IF
!
!     Undo scaling if necessary
!
IF( ILASCL ) THEN
   CALL DLASCL( 'G', 0, 0, ANRMTO, ANRM, N, 1, ALPHAR, N, IERR )
   CALL DLASCL( 'G', 0, 0, ANRMTO, ANRM, N, 1, ALPHAI, N, IERR )
END IF
!
IF( ILBSCL ) THEN
   CALL DLASCL( 'G', 0, 0, BNRMTO, BNRM, N, 1, BETA, N, IERR )
END IF
!
110 CONTINUE
!
WORK( 1 ) = MAXWRK
!
RETURN
!
!     End of DGGEV
!
end subroutine dggev

! ===== End dggev.f90 =====


! ===== Begin dgghrd.f90 =====

SUBROUTINE DGGHRD( COMPQ, COMPZ, N, ILO, IHI, A, LDA, B, LDB, Q, &
                       LDQ, Z, LDZ, INFO )
!
!  -- LAPACK routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
CHARACTER          COMPQ, COMPZ
INTEGER            IHI, ILO, INFO, LDA, LDB, LDQ, LDZ, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), B( LDB, * ), Q( LDQ, * ), &
                       Z( LDZ, * )
!     ..
!
!  Purpose
!  =======
!
!  DGGHRD reduces a pair of real matrices (A,B) to generalized upper
!  Hessenberg form using orthogonal transformations, where A is a
!  general matrix and B is upper triangular.  The form of the
!  generalized eigenvalue problem is
!     A*x = lambda*B*x,
!  and B is typically made upper triangular by computing its QR
!  factorization and moving the orthogonal matrix Q to the left side
!  of the equation.
!
!  This subroutine simultaneously reduces A to a Hessenberg matrix H:
!     Q**T*A*Z = H
!  and transforms B to another upper triangular matrix T:
!     Q**T*B*Z = T
!  in order to reduce the problem to its standard form
!     H*y = lambda*T*y
!  where y = Z**T*x.
!
!  The orthogonal matrices Q and Z are determined as products of Givens
!  rotations.  They may either be formed explicitly, or they may be
!  postmultiplied into input matrices Q1 and Z1, so that
!
!       Q1 * A * Z1**T = (Q1*Q) * H * (Z1*Z)**T
!
!       Q1 * B * Z1**T = (Q1*Q) * T * (Z1*Z)**T
!
!  If Q1 is the orthogonal matrix from the QR factorization of B in the
!  original equation A*x = lambda*B*x, then DGGHRD reduces the original
!  problem to generalized Hessenberg form.
!
!  Arguments
!  =========
!
!  COMPQ   (input) CHARACTER*1
!          = 'N': do not compute Q;
!          = 'I': Q is initialized to the unit matrix, and the
!                 orthogonal matrix Q is returned;
!          = 'V': Q must contain an orthogonal matrix Q1 on entry,
!                 and the product Q1*Q is returned.
!
!  COMPZ   (input) CHARACTER*1
!          = 'N': do not compute Z;
!          = 'I': Z is initialized to the unit matrix, and the
!                 orthogonal matrix Z is returned;
!          = 'V': Z must contain an orthogonal matrix Z1 on entry,
!                 and the product Z1*Z is returned.
!
!  N       (input) INTEGER
!          The order of the matrices A and B.  N >= 0.
!
!  ILO     (input) INTEGER
!  IHI     (input) INTEGER
!          ILO and IHI mark the rows and columns of A which are to be
!          reduced.  It is assumed that A is already upper triangular
!          in rows and columns 1:ILO-1 and IHI+1:N.  ILO and IHI are
!          normally set by a previous call to SGGBAL; otherwise they
!          should be set to 1 and N respectively.
!          1 <= ILO <= IHI <= N, if N > 0; ILO=1 and IHI=0, if N=0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA, N)
!          On entry, the N-by-N general matrix to be reduced.
!          On exit, the upper triangle and the first subdiagonal of A
!          are overwritten with the upper Hessenberg matrix H, and the
!          rest is set to zero.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB, N)
!          On entry, the N-by-N upper triangular matrix B.
!          On exit, the upper triangular matrix T = Q**T B Z.  The
!          elements below the diagonal are set to zero.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  Q       (input/output) DOUBLE PRECISION array, dimension (LDQ, N)
!          On entry, if COMPQ = 'V', the orthogonal matrix Q1,
!          typically from the QR factorization of B.
!          On exit, if COMPQ='I', the orthogonal matrix Q, and if
!          COMPQ = 'V', the product Q1*Q.
!          Not referenced if COMPQ='N'.
!
!  LDQ     (input) INTEGER
!          The leading dimension of the array Q.
!          LDQ >= N if COMPQ='V' or 'I'; LDQ >= 1 otherwise.
!
!  Z       (input/output) DOUBLE PRECISION array, dimension (LDZ, N)
!          On entry, if COMPZ = 'V', the orthogonal matrix Z1.
!          On exit, if COMPZ='I', the orthogonal matrix Z, and if
!          COMPZ = 'V', the product Z1*Z.
!          Not referenced if COMPZ='N'.
!
!  LDZ     (input) INTEGER
!          The leading dimension of the array Z.
!          LDZ >= N if COMPZ='V' or 'I'; LDZ >= 1 otherwise.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit.
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!
!  Further Details
!  ===============
!
!  This routine reduces A to Hessenberg and B to triangular form by
!  an unblocked reduction, as described in _Matrix_Computations_,
!  by Golub and Van Loan (Johns Hopkins Press.)
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            ILQ, ILZ
INTEGER            ICOMPQ, ICOMPZ, JCOL, JROW
DOUBLE PRECISION   C, S, TEMP
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARTG, DLASET, DROT, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Decode COMPQ
!
IF( LSAME( COMPQ, 'N' ) ) THEN
   ILQ = .FALSE.
   ICOMPQ = 1
ELSE IF( LSAME( COMPQ, 'V' ) ) THEN
   ILQ = .TRUE.
   ICOMPQ = 2
ELSE IF( LSAME( COMPQ, 'I' ) ) THEN
   ILQ = .TRUE.
   ICOMPQ = 3
ELSE
   ICOMPQ = 0
END IF
!
!     Decode COMPZ
!
IF( LSAME( COMPZ, 'N' ) ) THEN
   ILZ = .FALSE.
   ICOMPZ = 1
ELSE IF( LSAME( COMPZ, 'V' ) ) THEN
   ILZ = .TRUE.
   ICOMPZ = 2
ELSE IF( LSAME( COMPZ, 'I' ) ) THEN
   ILZ = .TRUE.
   ICOMPZ = 3
ELSE
   ICOMPZ = 0
END IF
!
!     Test the input parameters.
!
INFO = 0
IF( ICOMPQ.LE.0 ) THEN
   INFO = -1
ELSE IF( ICOMPZ.LE.0 ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( ILO.LT.1 ) THEN
   INFO = -4
ELSE IF( IHI.GT.N .OR. IHI.LT.ILO-1 ) THEN
   INFO = -5
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -7
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -9
ELSE IF( ( ILQ .AND. LDQ.LT.N ) .OR. LDQ.LT.1 ) THEN
   INFO = -11
ELSE IF( ( ILZ .AND. LDZ.LT.N ) .OR. LDZ.LT.1 ) THEN
   INFO = -13
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGGHRD', -INFO )
   RETURN
END IF
!
!     Initialize Q and Z if desired.
!
IF( ICOMPQ.EQ.3 ) &
       CALL DLASET( 'Full', N, N, ZERO, ONE, Q, LDQ )
IF( ICOMPZ.EQ.3 ) &
       CALL DLASET( 'Full', N, N, ZERO, ONE, Z, LDZ )
!
!     Quick return if possible
!
IF( N.LE.1 ) &
       RETURN
!
!     Zero out lower triangle of B
!
DO 20 JCOL = 1, N - 1
   DO 10 JROW = JCOL + 1, N
      B( JROW, JCOL ) = ZERO
10    CONTINUE
20 CONTINUE
!
!     Reduce A and B
!
DO 40 JCOL = ILO, IHI - 2
!
   DO 30 JROW = IHI, JCOL + 2, -1
!
!           Step 1: rotate rows JROW-1, JROW to kill A(JROW,JCOL)
!
      TEMP = A( JROW-1, JCOL )
      CALL DLARTG( TEMP, A( JROW, JCOL ), C, S, &
                       A( JROW-1, JCOL ) )
      A( JROW, JCOL ) = ZERO
      CALL DROT( N-JCOL, A( JROW-1, JCOL+1 ), LDA, &
                     A( JROW, JCOL+1 ), LDA, C, S )
      CALL DROT( N+2-JROW, B( JROW-1, JROW-1 ), LDB, &
                     B( JROW, JROW-1 ), LDB, C, S )
      IF( ILQ ) &
             CALL DROT( N, Q( 1, JROW-1 ), 1, Q( 1, JROW ), 1, C, S )
!
!           Step 2: rotate columns JROW, JROW-1 to kill B(JROW,JROW-1)
!
      TEMP = B( JROW, JROW )
      CALL DLARTG( TEMP, B( JROW, JROW-1 ), C, S, &
                       B( JROW, JROW ) )
      B( JROW, JROW-1 ) = ZERO
      CALL DROT( IHI, A( 1, JROW ), 1, A( 1, JROW-1 ), 1, C, S )
      CALL DROT( JROW-1, B( 1, JROW ), 1, B( 1, JROW-1 ), 1, C, &
                     S )
      IF( ILZ ) &
             CALL DROT( N, Z( 1, JROW ), 1, Z( 1, JROW-1 ), 1, C, S )
30    CONTINUE
40 CONTINUE
!
RETURN
!
!     End of DGGHRD
!
end subroutine dgghrd

! ===== End dgghrd.f90 =====


! ===== Begin dgttrf.f90 =====

SUBROUTINE DGTTRF( N, DL, D, DU, DU2, IPIV, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
INTEGER            INFO, N
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   D( * ), DL( * ), DU( * ), DU2( * )
!     ..
!
!  Purpose
!  =======
!
!  DGTTRF computes an LU factorization of a real tridiagonal matrix A
!  using elimination with partial pivoting and row interchanges.
!
!  The factorization has the form
!     A = L * U
!  where L is a product of permutation and unit lower bidiagonal
!  matrices and U is upper triangular with nonzeros in only the main
!  diagonal and first two superdiagonals.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  DL      (input/output) DOUBLE PRECISION array, dimension (N-1)
!          On entry, DL must contain the (n-1) subdiagonal elements of
!          A.
!          On exit, DL is overwritten by the (n-1) multipliers that
!          define the matrix L from the LU factorization of A.
!
!  D       (input/output) DOUBLE PRECISION array, dimension (N)
!          On entry, D must contain the diagonal elements of A.
!          On exit, D is overwritten by the n diagonal elements of the
!          upper triangular matrix U from the LU factorization of A.
!
!  DU      (input/output) DOUBLE PRECISION array, dimension (N-1)
!          On entry, DU must contain the (n-1) superdiagonal elements
!          of A.
!          On exit, DU is overwritten by the (n-1) elements of the first
!          superdiagonal of U.
!
!  DU2     (output) DOUBLE PRECISION array, dimension (N-2)
!          On exit, DU2 is overwritten by the (n-2) elements of the
!          second superdiagonal of U.
!
!  IPIV    (output) INTEGER array, dimension (N)
!          The pivot indices; for 1 <= i <= n, row i of the matrix was
!          interchanged with row IPIV(i).  IPIV(i) will always be either
!          i or i+1; IPIV(i) = i indicates a row interchange was not
!          required.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, U(i,i) is exactly zero. The factorization
!                has been completed, but the factor U is exactly
!                singular, and division by zero will occur if it is used
!                to solve a system of equations.
!
!  =====================================================================
!
!     .. Local Scalars ..
INTEGER            I
DOUBLE PRECISION   FACT, TEMP
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS
!     ..
!     .. External Subroutines ..
EXTERNAL           XERBLA
!     ..
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D+0 )
!     ..
!     .. Executable Statements ..
!
INFO = 0
IF( N.LT.0 ) THEN
   INFO = -1
   CALL XERBLA( 'DGTTRF', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Initialize IPIV(i) = i
!
DO 10 I = 1, N
   IPIV( I ) = I
10 CONTINUE
!
DO 20 I = 1, N - 1
   IF( DL( I ).EQ.ZERO ) THEN
!
!           Subdiagonal is zero, no elimination is required.
!
      IF( D( I ).EQ.ZERO .AND. INFO.EQ.0 ) &
             INFO = I
      IF( I.LT.N-1 ) &
             DU2( I ) = ZERO
   ELSE IF( ABS( D( I ) ).GE.ABS( DL( I ) ) ) THEN
!
!           No row interchange required, eliminate DL(I)
!
      FACT = DL( I ) / D( I )
      DL( I ) = FACT
      D( I+1 ) = D( I+1 ) - FACT*DU( I )
      IF( I.LT.N-1 ) &
             DU2( I ) = ZERO
   ELSE
!
!           Interchange rows I and I+1, eliminate DL(I)
!
      FACT = D( I ) / DL( I )
      D( I ) = DL( I )
      DL( I ) = FACT
      TEMP = DU( I )
      DU( I ) = D( I+1 )
      D( I+1 ) = TEMP - FACT*D( I+1 )
      IF( I.LT.N-1 ) THEN
         DU2( I ) = DU( I+1 )
         DU( I+1 ) = -FACT*DU( I+1 )
      END IF
      IPIV( I ) = IPIV( I ) + 1
   END IF
20 CONTINUE
IF( D( N ).EQ.ZERO .AND. INFO.EQ.0 ) THEN
   INFO = N
   RETURN
END IF
!
RETURN
!
!     End of DGTTRF
!
end subroutine dgttrf

! ===== End dgttrf.f90 =====


! ===== Begin dgttrs.f90 =====

SUBROUTINE DGTTRS( TRANS, N, NRHS, DL, D, DU, DU2, IPIV, B, LDB, &
                       INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER          TRANS
INTEGER            INFO, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   B( LDB, * ), D( * ), DL( * ), DU( * ), DU2( * )
!     ..
!
!  Purpose
!  =======
!
!  DGTTRS solves one of the systems of equations
!     A*X = B  or  A'*X = B,
!  with a tridiagonal matrix A using the LU factorization computed
!  by DGTTRF.
!
!  Arguments
!  =========
!
!  TRANS   (input) CHARACTER
!          Specifies the form of the system of equations:
!          = 'N':  A * X = B  (No transpose)
!          = 'T':  A'* X = B  (Transpose)
!          = 'C':  A'* X = B  (Conjugate transpose = Transpose)
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  DL      (input) DOUBLE PRECISION array, dimension (N-1)
!          The (n-1) multipliers that define the matrix L from the
!          LU factorization of A.
!
!  D       (input) DOUBLE PRECISION array, dimension (N)
!          The n diagonal elements of the upper triangular matrix U from
!          the LU factorization of A.
!
!  DU      (input) DOUBLE PRECISION array, dimension (N-1)
!          The (n-1) elements of the first superdiagonal of U.
!
!  DU2     (input) DOUBLE PRECISION array, dimension (N-2)
!          The (n-2) elements of the second superdiagonal of U.
!
!  IPIV    (input) INTEGER array, dimension (N)
!          The pivot indices; for 1 <= i <= n, row i of the matrix was
!          interchanged with row IPIV(i).  IPIV(i) will always be either
!          i or i+1; IPIV(i) = i indicates a row interchange was not
!          required.
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the right hand side matrix B.
!          On exit, B is overwritten by the solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Local Scalars ..
LOGICAL            NOTRAN
INTEGER            I, J
DOUBLE PRECISION   TEMP
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
INFO = 0
NOTRAN = LSAME( TRANS, 'N' )
IF( .NOT.NOTRAN .AND. .NOT.LSAME( TRANS, 'T' ) .AND. .NOT. &
        LSAME( TRANS, 'C' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -3
ELSE IF( LDB.LT.MAX( N, 1 ) ) THEN
   INFO = -10
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DGTTRS', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 .OR. NRHS.EQ.0 ) &
       RETURN
!
IF( NOTRAN ) THEN
!
!        Solve A*X = B using the LU factorization of A,
!        overwriting each right hand side vector with its solution.
!
   DO 30 J = 1, NRHS
!
!           Solve L*x = b.
!
      DO 10 I = 1, N - 1
         IF( IPIV( I ).EQ.I ) THEN
            B( I+1, J ) = B( I+1, J ) - DL( I )*B( I, J )
         ELSE
            TEMP = B( I, J )
            B( I, J ) = B( I+1, J )
            B( I+1, J ) = TEMP - DL( I )*B( I, J )
         END IF
10       CONTINUE
!
!           Solve U*x = b.
!
      B( N, J ) = B( N, J ) / D( N )
      IF( N.GT.1 ) &
             B( N-1, J ) = ( B( N-1, J )-DU( N-1 )*B( N, J ) ) / &
                           D( N-1 )
      DO 20 I = N - 2, 1, -1
         B( I, J ) = ( B( I, J )-DU( I )*B( I+1, J )-DU2( I )* &
                         B( I+2, J ) ) / D( I )
20       CONTINUE
30    CONTINUE
ELSE
!
!        Solve A' * X = B.
!
   DO 60 J = 1, NRHS
!
!           Solve U'*x = b.
!
      B( 1, J ) = B( 1, J ) / D( 1 )
      IF( N.GT.1 ) &
             B( 2, J ) = ( B( 2, J )-DU( 1 )*B( 1, J ) ) / D( 2 )
      DO 40 I = 3, N
         B( I, J ) = ( B( I, J )-DU( I-1 )*B( I-1, J )-DU2( I-2 )* &
                         B( I-2, J ) ) / D( I )
40       CONTINUE
!
!           Solve L'*x = b.
!
      DO 50 I = N - 1, 1, -1
         IF( IPIV( I ).EQ.I ) THEN
            B( I, J ) = B( I, J ) - DL( I )*B( I+1, J )
         ELSE
            TEMP = B( I+1, J )
            B( I+1, J ) = B( I, J ) - DL( I )*TEMP
            B( I, J ) = TEMP
         END IF
50       CONTINUE
60    CONTINUE
END IF
!
!     End of DGTTRS
!
end subroutine dgttrs

! ===== End dgttrs.f90 =====


! ===== Begin dhgeqz.f90 =====

SUBROUTINE DHGEQZ( JOB, COMPQ, COMPZ, N, ILO, IHI, H, LDH, T, LDT, &
                       ALPHAR, ALPHAI, BETA, Q, LDQ, Z, LDZ, WORK, &
                       LWORK, INFO )
!
!  -- LAPACK routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
CHARACTER          COMPQ, COMPZ, JOB
INTEGER            IHI, ILO, INFO, LDH, LDQ, LDT, LDZ, LWORK, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   ALPHAI( * ), ALPHAR( * ), BETA( * ), &
                       H( LDH, * ), Q( LDQ, * ), T( LDT, * ), &
                       WORK( * ), Z( LDZ, * )
!     ..
!
!  Purpose
!  =======
!
!  DHGEQZ computes the eigenvalues of a real matrix pair (H,T),
!  where H is an upper Hessenberg matrix and T is upper triangular,
!  using the double-shift QZ method.
!  Matrix pairs of this type are produced by the reduction to
!  generalized upper Hessenberg form of a real matrix pair (A,B):
!
!     A = Q1*H*Z1**T,  B = Q1*T*Z1**T,
!
!  as computed by DGGHRD.
!
!  If JOB='S', then the Hessenberg-triangular pair (H,T) is
!  also reduced to generalized Schur form,
!  
!     H = Q*S*Z**T,  T = Q*P*Z**T,
!  
!  where Q and Z are orthogonal matrices, P is an upper triangular
!  matrix, and S is a quasi-triangular matrix with 1-by-1 and 2-by-2
!  diagonal blocks.
!
!  The 1-by-1 blocks correspond to real eigenvalues of the matrix pair
!  (H,T) and the 2-by-2 blocks correspond to complex conjugate pairs of
!  eigenvalues.
!
!  Additionally, the 2-by-2 upper triangular diagonal blocks of P
!  corresponding to 2-by-2 blocks of S are reduced to positive diagonal
!  form, i.e., if S(j+1,j) is non-zero, then P(j+1,j) = P(j,j+1) = 0,
!  P(j,j) > 0, and P(j+1,j+1) > 0.
!
!  Optionally, the orthogonal matrix Q from the generalized Schur
!  factorization may be postmultiplied into an input matrix Q1, and the
!  orthogonal matrix Z may be postmultiplied into an input matrix Z1.
!  If Q1 and Z1 are the orthogonal matrices from DGGHRD that reduced
!  the matrix pair (A,B) to generalized upper Hessenberg form, then the
!  output matrices Q1*Q and Z1*Z are the orthogonal factors from the
!  generalized Schur factorization of (A,B):
!
!     A = (Q1*Q)*S*(Z1*Z)**T,  B = (Q1*Q)*P*(Z1*Z)**T.
!  
!  To avoid overflow, eigenvalues of the matrix pair (H,T) (equivalently,
!  of (A,B)) are computed as a pair of values (alpha,beta), where alpha is
!  complex and beta real.
!  If beta is nonzero, lambda = alpha / beta is an eigenvalue of the
!  generalized nonsymmetric eigenvalue problem (GNEP)
!     A*x = lambda*B*x
!  and if alpha is nonzero, mu = beta / alpha is an eigenvalue of the
!  alternate form of the GNEP
!     mu*A*y = B*y.
!  Real eigenvalues can be read directly from the generalized Schur
!  form: 
!    alpha = S(i,i), beta = P(i,i).
!
!  Ref: C.B. Moler & G.W. Stewart, "An Algorithm for Generalized Matrix
!       Eigenvalue Problems", SIAM J. Numer. Anal., 10(1973),
!       pp. 241--256.
!
!  Arguments
!  =========
!
!  JOB     (input) CHARACTER*1
!          = 'E': Compute eigenvalues only;
!          = 'S': Compute eigenvalues and the Schur form. 
!
!  COMPQ   (input) CHARACTER*1
!          = 'N': Left Schur vectors (Q) are not computed;
!          = 'I': Q is initialized to the unit matrix and the matrix Q
!                 of left Schur vectors of (H,T) is returned;
!          = 'V': Q must contain an orthogonal matrix Q1 on entry and
!                 the product Q1*Q is returned.
!
!  COMPZ   (input) CHARACTER*1
!          = 'N': Right Schur vectors (Z) are not computed;
!          = 'I': Z is initialized to the unit matrix and the matrix Z
!                 of right Schur vectors of (H,T) is returned;
!          = 'V': Z must contain an orthogonal matrix Z1 on entry and
!                 the product Z1*Z is returned.
!
!  N       (input) INTEGER
!          The order of the matrices H, T, Q, and Z.  N >= 0.
!
!  ILO     (input) INTEGER
!  IHI     (input) INTEGER
!          ILO and IHI mark the rows and columns of H which are in
!          Hessenberg form.  It is assumed that A is already upper
!          triangular in rows and columns 1:ILO-1 and IHI+1:N.
!          If N > 0, 1 <= ILO <= IHI <= N; if N = 0, ILO=1 and IHI=0.
!
!  H       (input/output) DOUBLE PRECISION array, dimension (LDH, N)
!          On entry, the N-by-N upper Hessenberg matrix H.
!          On exit, if JOB = 'S', H contains the upper quasi-triangular
!          matrix S from the generalized Schur factorization;
!          2-by-2 diagonal blocks (corresponding to complex conjugate
!          pairs of eigenvalues) are returned in standard form, with
!          H(i,i) = H(i+1,i+1) and H(i+1,i)*H(i,i+1) < 0.
!          If JOB = 'E', the diagonal blocks of H match those of S, but
!          the rest of H is unspecified.
!
!  LDH     (input) INTEGER
!          The leading dimension of the array H.  LDH >= max( 1, N ).
!
!  T       (input/output) DOUBLE PRECISION array, dimension (LDT, N)
!          On entry, the N-by-N upper triangular matrix T.
!          On exit, if JOB = 'S', T contains the upper triangular
!          matrix P from the generalized Schur factorization;
!          2-by-2 diagonal blocks of P corresponding to 2-by-2 blocks of S
!          are reduced to positive diagonal form, i.e., if H(j+1,j) is
!          non-zero, then T(j+1,j) = T(j,j+1) = 0, T(j,j) > 0, and
!          T(j+1,j+1) > 0.
!          If JOB = 'E', the diagonal blocks of T match those of P, but
!          the rest of T is unspecified.
!
!  LDT     (input) INTEGER
!          The leading dimension of the array T.  LDT >= max( 1, N ).
!
!  ALPHAR  (output) DOUBLE PRECISION array, dimension (N)
!          The real parts of each scalar alpha defining an eigenvalue
!          of GNEP.
!
!  ALPHAI  (output) DOUBLE PRECISION array, dimension (N)
!          The imaginary parts of each scalar alpha defining an
!          eigenvalue of GNEP.
!          If ALPHAI(j) is zero, then the j-th eigenvalue is real; if
!          positive, then the j-th and (j+1)-st eigenvalues are a
!          complex conjugate pair, with ALPHAI(j+1) = -ALPHAI(j).
!
!  BETA    (output) DOUBLE PRECISION array, dimension (N)
!          The scalars beta that define the eigenvalues of GNEP.
!          Together, the quantities alpha = (ALPHAR(j),ALPHAI(j)) and
!          beta = BETA(j) represent the j-th eigenvalue of the matrix
!          pair (A,B), in one of the forms lambda = alpha/beta or
!          mu = beta/alpha.  Since either lambda or mu may overflow,
!          they should not, in general, be computed.
!
!  Q       (input/output) DOUBLE PRECISION array, dimension (LDQ, N)
!          On entry, if COMPZ = 'V', the orthogonal matrix Q1 used in
!          the reduction of (A,B) to generalized Hessenberg form.
!          On exit, if COMPZ = 'I', the orthogonal matrix of left Schur
!          vectors of (H,T), and if COMPZ = 'V', the orthogonal matrix
!          of left Schur vectors of (A,B).
!          Not referenced if COMPZ = 'N'.
!
!  LDQ     (input) INTEGER
!          The leading dimension of the array Q.  LDQ >= 1.
!          If COMPQ='V' or 'I', then LDQ >= N.
!
!  Z       (input/output) DOUBLE PRECISION array, dimension (LDZ, N)
!          On entry, if COMPZ = 'V', the orthogonal matrix Z1 used in
!          the reduction of (A,B) to generalized Hessenberg form.
!          On exit, if COMPZ = 'I', the orthogonal matrix of
!          right Schur vectors of (H,T), and if COMPZ = 'V', the
!          orthogonal matrix of right Schur vectors of (A,B).
!          Not referenced if COMPZ = 'N'.
!
!  LDZ     (input) INTEGER
!          The leading dimension of the array Z.  LDZ >= 1.
!          If COMPZ='V' or 'I', then LDZ >= N.
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (MAX(1,LWORK))
!          On exit, if INFO >= 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.  LWORK >= max(1,N).
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!          = 1,...,N: the QZ iteration did not converge.  (H,T) is not
!                     in Schur form, but ALPHAR(i), ALPHAI(i), and
!                     BETA(i), i=INFO+1,...,N should be correct.
!          = N+1,...,2*N: the shift calculation failed.  (H,T) is not
!                     in Schur form, but ALPHAR(i), ALPHAI(i), and
!                     BETA(i), i=INFO-N+1,...,N should be correct.
!
!  Further Details
!  ===============
!
!  Iteration counters:
!
!  JITER  -- counts iterations.
!  IITER  -- counts iterations run since ILAST was last
!            changed.  This is therefore reset only when a 1-by-1 or
!            2-by-2 block deflates off the bottom.
!
!  =====================================================================
!
!     .. Parameters ..
!    $                     SAFETY = 1.0E+0 )
DOUBLE PRECISION   HALF, ZERO, ONE, SAFETY
PARAMETER          ( HALF = 0.5D+0, ZERO = 0.0D+0, ONE = 1.0D+0, &
                       SAFETY = 1.0D+2 )
!     ..
!     .. Local Scalars ..
LOGICAL            ILAZR2, ILAZRO, ILPIVT, ILQ, ILSCHR, ILZ, &
                       LQUERY
INTEGER            ICOMPQ, ICOMPZ, IFIRST, IFRSTM, IITER, ILAST, &
                       ILASTM, IN, ISCHUR, ISTART, J, JC, JCH, JITER, &
                       JR, MAXIT
DOUBLE PRECISION   A11, A12, A1I, A1R, A21, A22, A2I, A2R, AD11, &
                       AD11L, AD12, AD12L, AD21, AD21L, AD22, AD22L, &
                       AD32L, AN, ANORM, ASCALE, ATOL, B11, B1A, B1I, &
                       B1R, B22, B2A, B2I, B2R, BN, BNORM, BSCALE, &
                       BTOL, C, C11I, C11R, C12, C21, C22I, C22R, CL, &
                       CQ, CR, CZ, ESHIFT, S, S1, S1INV, S2, SAFMAX, &
                       SAFMIN, SCALE, SL, SQI, SQR, SR, SZI, SZR, T1, &
                       TAU, TEMP, TEMP2, TEMPI, TEMPR, U1, U12, U12L, &
                       U2, ULP, VS, W11, W12, W21, W22, WABS, WI, WR, &
                       WR2
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   V( 3 )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
DOUBLE PRECISION   DLAMCH, DLANHS, DLAPY2, DLAPY3
EXTERNAL           LSAME, DLAMCH, DLANHS, DLAPY2, DLAPY3
!     ..
!     .. External Subroutines ..
EXTERNAL           DLAG2, DLARFG, DLARTG, DLASET, DLASV2, DROT, &
                       XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, DBLE, MAX, MIN, SQRT
!     ..
!     .. Executable Statements ..
!
!     Decode JOB, COMPQ, COMPZ
!
IF( LSAME( JOB, 'E' ) ) THEN
   ILSCHR = .FALSE.
   ISCHUR = 1
ELSE IF( LSAME( JOB, 'S' ) ) THEN
   ILSCHR = .TRUE.
   ISCHUR = 2
ELSE
   ISCHUR = 0
END IF
!
IF( LSAME( COMPQ, 'N' ) ) THEN
   ILQ = .FALSE.
   ICOMPQ = 1
ELSE IF( LSAME( COMPQ, 'V' ) ) THEN
   ILQ = .TRUE.
   ICOMPQ = 2
ELSE IF( LSAME( COMPQ, 'I' ) ) THEN
   ILQ = .TRUE.
   ICOMPQ = 3
ELSE
   ICOMPQ = 0
END IF
!
IF( LSAME( COMPZ, 'N' ) ) THEN
   ILZ = .FALSE.
   ICOMPZ = 1
ELSE IF( LSAME( COMPZ, 'V' ) ) THEN
   ILZ = .TRUE.
   ICOMPZ = 2
ELSE IF( LSAME( COMPZ, 'I' ) ) THEN
   ILZ = .TRUE.
   ICOMPZ = 3
ELSE
   ICOMPZ = 0
END IF
!
!     Check Argument Values
!
INFO = 0
WORK( 1 ) = MAX( 1, N )
LQUERY = ( LWORK.EQ.-1 )
IF( ISCHUR.EQ.0 ) THEN
   INFO = -1
ELSE IF( ICOMPQ.EQ.0 ) THEN
   INFO = -2
ELSE IF( ICOMPZ.EQ.0 ) THEN
   INFO = -3
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( ILO.LT.1 ) THEN
   INFO = -5
ELSE IF( IHI.GT.N .OR. IHI.LT.ILO-1 ) THEN
   INFO = -6
ELSE IF( LDH.LT.N ) THEN
   INFO = -8
ELSE IF( LDT.LT.N ) THEN
   INFO = -10
ELSE IF( LDQ.LT.1 .OR. ( ILQ .AND. LDQ.LT.N ) ) THEN
   INFO = -15
ELSE IF( LDZ.LT.1 .OR. ( ILZ .AND. LDZ.LT.N ) ) THEN
   INFO = -17
ELSE IF( LWORK.LT.MAX( 1, N ) .AND. .NOT.LQUERY ) THEN
   INFO = -19
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DHGEQZ', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.LE.0 ) THEN
   WORK( 1 ) = DBLE( 1 )
   RETURN
END IF
!
!     Initialize Q and Z
!
IF( ICOMPQ.EQ.3 ) &
       CALL DLASET( 'Full', N, N, ZERO, ONE, Q, LDQ )
IF( ICOMPZ.EQ.3 ) &
       CALL DLASET( 'Full', N, N, ZERO, ONE, Z, LDZ )
!
!     Machine Constants
!
IN = IHI + 1 - ILO
SAFMIN = DLAMCH( 'S' )
SAFMAX = ONE / SAFMIN
ULP = DLAMCH( 'E' )*DLAMCH( 'B' )
ANORM = DLANHS( 'F', IN, H( ILO, ILO ), LDH, WORK )
BNORM = DLANHS( 'F', IN, T( ILO, ILO ), LDT, WORK )
ATOL = MAX( SAFMIN, ULP*ANORM )
BTOL = MAX( SAFMIN, ULP*BNORM )
ASCALE = ONE / MAX( SAFMIN, ANORM )
BSCALE = ONE / MAX( SAFMIN, BNORM )
!
!     Set Eigenvalues IHI+1:N
!
DO 30 J = IHI + 1, N
   IF( T( J, J ).LT.ZERO ) THEN
      IF( ILSCHR ) THEN
         DO 10 JR = 1, J
            H( JR, J ) = -H( JR, J )
            T( JR, J ) = -T( JR, J )
10          CONTINUE
      ELSE
         H( J, J ) = -H( J, J )
         T( J, J ) = -T( J, J )
      END IF
      IF( ILZ ) THEN
         DO 20 JR = 1, N
            Z( JR, J ) = -Z( JR, J )
20          CONTINUE
      END IF
   END IF
   ALPHAR( J ) = H( J, J )
   ALPHAI( J ) = ZERO
   BETA( J ) = T( J, J )
30 CONTINUE
!
!     If IHI < ILO, skip QZ steps
!
IF( IHI.LT.ILO ) &
       GO TO 380
!
!     MAIN QZ ITERATION LOOP
!
!     Initialize dynamic indices
!
!     Eigenvalues ILAST+1:N have been found.
!        Column operations modify rows IFRSTM:whatever.
!        Row operations modify columns whatever:ILASTM.
!
!     If only eigenvalues are being computed, then
!        IFRSTM is the row of the last splitting row above row ILAST;
!        this is always at least ILO.
!     IITER counts iterations since the last eigenvalue was found,
!        to tell when to use an extraordinary shift.
!     MAXIT is the maximum number of QZ sweeps allowed.
!
ILAST = IHI
IF( ILSCHR ) THEN
   IFRSTM = 1
   ILASTM = N
ELSE
   IFRSTM = ILO
   ILASTM = IHI
END IF
IITER = 0
ESHIFT = ZERO
MAXIT = 30*( IHI-ILO+1 )
!
DO 360 JITER = 1, MAXIT
!
!        Split the matrix if possible.
!
!        Two tests:
!           1: H(j,j-1)=0  or  j=ILO
!           2: T(j,j)=0
!
   IF( ILAST.EQ.ILO ) THEN
!
!           Special case: j=ILAST
!
      GO TO 80
   ELSE
      IF( ABS( H( ILAST, ILAST-1 ) ).LE.ATOL ) THEN
         H( ILAST, ILAST-1 ) = ZERO
         GO TO 80
      END IF
   END IF
!
   IF( ABS( T( ILAST, ILAST ) ).LE.BTOL ) THEN
      T( ILAST, ILAST ) = ZERO
      GO TO 70
   END IF
!
!        General case: j<ILAST
!
   DO 60 J = ILAST - 1, ILO, -1
!
!           Test 1: for H(j,j-1)=0 or j=ILO
!
      IF( J.EQ.ILO ) THEN
         ILAZRO = .TRUE.
      ELSE
         IF( ABS( H( J, J-1 ) ).LE.ATOL ) THEN
            H( J, J-1 ) = ZERO
            ILAZRO = .TRUE.
         ELSE
            ILAZRO = .FALSE.
         END IF
      END IF
!
!           Test 2: for T(j,j)=0
!
      IF( ABS( T( J, J ) ).LT.BTOL ) THEN
         T( J, J ) = ZERO
!
!              Test 1a: Check for 2 consecutive small subdiagonals in A
!
         ILAZR2 = .FALSE.
         IF( .NOT.ILAZRO ) THEN
            TEMP = ABS( H( J, J-1 ) )
            TEMP2 = ABS( H( J, J ) )
            TEMPR = MAX( TEMP, TEMP2 )
            IF( TEMPR.LT.ONE .AND. TEMPR.NE.ZERO ) THEN
               TEMP = TEMP / TEMPR
               TEMP2 = TEMP2 / TEMPR
            END IF
            IF( TEMP*( ASCALE*ABS( H( J+1, J ) ) ).LE.TEMP2* &
                    ( ASCALE*ATOL ) )ILAZR2 = .TRUE.
         END IF
!
!              If both tests pass (1 & 2), i.e., the leading diagonal
!              element of B in the block is zero, split a 1x1 block off
!              at the top. (I.e., at the J-th row/column) The leading
!              diagonal element of the remainder can also be zero, so
!              this may have to be done repeatedly.
!
         IF( ILAZRO .OR. ILAZR2 ) THEN
            DO 40 JCH = J, ILAST - 1
               TEMP = H( JCH, JCH )
               CALL DLARTG( TEMP, H( JCH+1, JCH ), C, S, &
                                H( JCH, JCH ) )
               H( JCH+1, JCH ) = ZERO
               CALL DROT( ILASTM-JCH, H( JCH, JCH+1 ), LDH, &
                              H( JCH+1, JCH+1 ), LDH, C, S )
               CALL DROT( ILASTM-JCH, T( JCH, JCH+1 ), LDT, &
                              T( JCH+1, JCH+1 ), LDT, C, S )
               IF( ILQ ) &
                      CALL DROT( N, Q( 1, JCH ), 1, Q( 1, JCH+1 ), 1, &
                                 C, S )
               IF( ILAZR2 ) &
                      H( JCH, JCH-1 ) = H( JCH, JCH-1 )*C
               ILAZR2 = .FALSE.
               IF( ABS( T( JCH+1, JCH+1 ) ).GE.BTOL ) THEN
                  IF( JCH+1.GE.ILAST ) THEN
                     GO TO 80
                  ELSE
                     IFIRST = JCH + 1
                     GO TO 110
                  END IF
               END IF
               T( JCH+1, JCH+1 ) = ZERO
40             CONTINUE
            GO TO 70
         ELSE
!
!                 Only test 2 passed -- chase the zero to T(ILAST,ILAST)
!                 Then process as in the case T(ILAST,ILAST)=0
!
            DO 50 JCH = J, ILAST - 1
               TEMP = T( JCH, JCH+1 )
               CALL DLARTG( TEMP, T( JCH+1, JCH+1 ), C, S, &
                                T( JCH, JCH+1 ) )
               T( JCH+1, JCH+1 ) = ZERO
               IF( JCH.LT.ILASTM-1 ) &
                      CALL DROT( ILASTM-JCH-1, T( JCH, JCH+2 ), LDT, &
                                 T( JCH+1, JCH+2 ), LDT, C, S )
               CALL DROT( ILASTM-JCH+2, H( JCH, JCH-1 ), LDH, &
                              H( JCH+1, JCH-1 ), LDH, C, S )
               IF( ILQ ) &
                      CALL DROT( N, Q( 1, JCH ), 1, Q( 1, JCH+1 ), 1, &
                                 C, S )
               TEMP = H( JCH+1, JCH )
               CALL DLARTG( TEMP, H( JCH+1, JCH-1 ), C, S, &
                                H( JCH+1, JCH ) )
               H( JCH+1, JCH-1 ) = ZERO
               CALL DROT( JCH+1-IFRSTM, H( IFRSTM, JCH ), 1, &
                              H( IFRSTM, JCH-1 ), 1, C, S )
               CALL DROT( JCH-IFRSTM, T( IFRSTM, JCH ), 1, &
                              T( IFRSTM, JCH-1 ), 1, C, S )
               IF( ILZ ) &
                      CALL DROT( N, Z( 1, JCH ), 1, Z( 1, JCH-1 ), 1, &
                                 C, S )
50             CONTINUE
            GO TO 70
         END IF
      ELSE IF( ILAZRO ) THEN
!
!              Only test 1 passed -- work on J:ILAST
!
         IFIRST = J
         GO TO 110
      END IF
!
!           Neither test passed -- try next J
!
60    CONTINUE
!
!        (Drop-through is "impossible")
!
   INFO = N + 1
   GO TO 420
!
!        T(ILAST,ILAST)=0 -- clear H(ILAST,ILAST-1) to split off a
!        1x1 block.
!
70    CONTINUE
   TEMP = H( ILAST, ILAST )
   CALL DLARTG( TEMP, H( ILAST, ILAST-1 ), C, S, &
                    H( ILAST, ILAST ) )
   H( ILAST, ILAST-1 ) = ZERO
   CALL DROT( ILAST-IFRSTM, H( IFRSTM, ILAST ), 1, &
                  H( IFRSTM, ILAST-1 ), 1, C, S )
   CALL DROT( ILAST-IFRSTM, T( IFRSTM, ILAST ), 1, &
                  T( IFRSTM, ILAST-1 ), 1, C, S )
   IF( ILZ ) &
          CALL DROT( N, Z( 1, ILAST ), 1, Z( 1, ILAST-1 ), 1, C, S )
!
!        H(ILAST,ILAST-1)=0 -- Standardize B, set ALPHAR, ALPHAI,
!                              and BETA
!
80    CONTINUE
   IF( T( ILAST, ILAST ).LT.ZERO ) THEN
      IF( ILSCHR ) THEN
         DO 90 J = IFRSTM, ILAST
            H( J, ILAST ) = -H( J, ILAST )
            T( J, ILAST ) = -T( J, ILAST )
90          CONTINUE
      ELSE
         H( ILAST, ILAST ) = -H( ILAST, ILAST )
         T( ILAST, ILAST ) = -T( ILAST, ILAST )
      END IF
      IF( ILZ ) THEN
         DO 100 J = 1, N
            Z( J, ILAST ) = -Z( J, ILAST )
100          CONTINUE
      END IF
   END IF
   ALPHAR( ILAST ) = H( ILAST, ILAST )
   ALPHAI( ILAST ) = ZERO
   BETA( ILAST ) = T( ILAST, ILAST )
!
!        Go to next block -- exit if finished.
!
   ILAST = ILAST - 1
   IF( ILAST.LT.ILO ) &
          GO TO 380
!
!        Reset counters
!
   IITER = 0
   ESHIFT = ZERO
   IF( .NOT.ILSCHR ) THEN
      ILASTM = ILAST
      IF( IFRSTM.GT.ILAST ) &
             IFRSTM = ILO
   END IF
   GO TO 350
!
!        QZ step
!
!        This iteration only involves rows/columns IFIRST:ILAST. We
!        assume IFIRST < ILAST, and that the diagonal of B is non-zero.
!
110    CONTINUE
   IITER = IITER + 1
   IF( .NOT.ILSCHR ) THEN
      IFRSTM = IFIRST
   END IF
!
!        Compute single shifts.
!
!        At this point, IFIRST < ILAST, and the diagonal elements of
!        T(IFIRST:ILAST,IFIRST,ILAST) are larger than BTOL (in
!        magnitude)
!
   IF( ( IITER / 10 )*10.EQ.IITER ) THEN
!
!           Exceptional shift.  Chosen for no particularly good reason.
!           (Single shift only.)
!
      IF( ( DBLE( MAXIT )*SAFMIN )*ABS( H( ILAST-1, ILAST ) ).LT. &
              ABS( T( ILAST-1, ILAST-1 ) ) ) THEN
         ESHIFT = ESHIFT + H( ILAST-1, ILAST ) / &
                      T( ILAST-1, ILAST-1 )
      ELSE
         ESHIFT = ESHIFT + ONE / ( SAFMIN*DBLE( MAXIT ) )
      END IF
      S1 = ONE
      WR = ESHIFT
!
   ELSE
!
!           Shifts based on the generalized eigenvalues of the
!           bottom-right 2x2 block of A and B. The first eigenvalue
!           returned by DLAG2 is the Wilkinson shift (AEP p.512),
!
      CALL DLAG2( H( ILAST-1, ILAST-1 ), LDH, &
                      T( ILAST-1, ILAST-1 ), LDT, SAFMIN*SAFETY, S1, &
                      S2, WR, WR2, WI )
!
      TEMP = MAX( S1, SAFMIN*MAX( ONE, ABS( WR ), ABS( WI ) ) )
      IF( WI.NE.ZERO ) &
             GO TO 200
   END IF
!
!        Fiddle with shift to avoid overflow
!
   TEMP = MIN( ASCALE, ONE )*( HALF*SAFMAX )
   IF( S1.GT.TEMP ) THEN
      SCALE = TEMP / S1
   ELSE
      SCALE = ONE
   END IF
!
   TEMP = MIN( BSCALE, ONE )*( HALF*SAFMAX )
   IF( ABS( WR ).GT.TEMP ) &
          SCALE = MIN( SCALE, TEMP / ABS( WR ) )
   S1 = SCALE*S1
   WR = SCALE*WR
!
!        Now check for two consecutive small subdiagonals.
!
   DO 120 J = ILAST - 1, IFIRST + 1, -1
      ISTART = J
      TEMP = ABS( S1*H( J, J-1 ) )
      TEMP2 = ABS( S1*H( J, J )-WR*T( J, J ) )
      TEMPR = MAX( TEMP, TEMP2 )
      IF( TEMPR.LT.ONE .AND. TEMPR.NE.ZERO ) THEN
         TEMP = TEMP / TEMPR
         TEMP2 = TEMP2 / TEMPR
      END IF
      IF( ABS( ( ASCALE*H( J+1, J ) )*TEMP ).LE.( ASCALE*ATOL )* &
              TEMP2 )GO TO 130
120    CONTINUE
!
   ISTART = IFIRST
130    CONTINUE
!
!        Do an implicit single-shift QZ sweep.
!
!        Initial Q
!
   TEMP = S1*H( ISTART, ISTART ) - WR*T( ISTART, ISTART )
   TEMP2 = S1*H( ISTART+1, ISTART )
   CALL DLARTG( TEMP, TEMP2, C, S, TEMPR )
!
!        Sweep
!
   DO 190 J = ISTART, ILAST - 1
      IF( J.GT.ISTART ) THEN
         TEMP = H( J, J-1 )
         CALL DLARTG( TEMP, H( J+1, J-1 ), C, S, H( J, J-1 ) )
         H( J+1, J-1 ) = ZERO
      END IF
!
      DO 140 JC = J, ILASTM
         TEMP = C*H( J, JC ) + S*H( J+1, JC )
         H( J+1, JC ) = -S*H( J, JC ) + C*H( J+1, JC )
         H( J, JC ) = TEMP
         TEMP2 = C*T( J, JC ) + S*T( J+1, JC )
         T( J+1, JC ) = -S*T( J, JC ) + C*T( J+1, JC )
         T( J, JC ) = TEMP2
140       CONTINUE
      IF( ILQ ) THEN
         DO 150 JR = 1, N
            TEMP = C*Q( JR, J ) + S*Q( JR, J+1 )
            Q( JR, J+1 ) = -S*Q( JR, J ) + C*Q( JR, J+1 )
            Q( JR, J ) = TEMP
150          CONTINUE
      END IF
!
      TEMP = T( J+1, J+1 )
      CALL DLARTG( TEMP, T( J+1, J ), C, S, T( J+1, J+1 ) )
      T( J+1, J ) = ZERO
!
      DO 160 JR = IFRSTM, MIN( J+2, ILAST )
         TEMP = C*H( JR, J+1 ) + S*H( JR, J )
         H( JR, J ) = -S*H( JR, J+1 ) + C*H( JR, J )
         H( JR, J+1 ) = TEMP
160       CONTINUE
      DO 170 JR = IFRSTM, J
         TEMP = C*T( JR, J+1 ) + S*T( JR, J )
         T( JR, J ) = -S*T( JR, J+1 ) + C*T( JR, J )
         T( JR, J+1 ) = TEMP
170       CONTINUE
      IF( ILZ ) THEN
         DO 180 JR = 1, N
            TEMP = C*Z( JR, J+1 ) + S*Z( JR, J )
            Z( JR, J ) = -S*Z( JR, J+1 ) + C*Z( JR, J )
            Z( JR, J+1 ) = TEMP
180          CONTINUE
      END IF
190    CONTINUE
!
   GO TO 350
!
!        Use Francis double-shift
!
!        Note: the Francis double-shift should work with real shifts,
!              but only if the block is at least 3x3.
!              This code may break if this point is reached with
!              a 2x2 block with real eigenvalues.
!
200    CONTINUE
   IF( IFIRST+1.EQ.ILAST ) THEN
!
!           Special case -- 2x2 block with complex eigenvectors
!
!           Step 1: Standardize, that is, rotate so that
!
!                       ( B11  0  )
!                   B = (         )  with B11 non-negative.
!                       (  0  B22 )
!
      CALL DLASV2( T( ILAST-1, ILAST-1 ), T( ILAST-1, ILAST ), &
                       T( ILAST, ILAST ), B22, B11, SR, CR, SL, CL )
!
      IF( B11.LT.ZERO ) THEN
         CR = -CR
         SR = -SR
         B11 = -B11
         B22 = -B22
      END IF
!
      CALL DROT( ILASTM+1-IFIRST, H( ILAST-1, ILAST-1 ), LDH, &
                     H( ILAST, ILAST-1 ), LDH, CL, SL )
      CALL DROT( ILAST+1-IFRSTM, H( IFRSTM, ILAST-1 ), 1, &
                     H( IFRSTM, ILAST ), 1, CR, SR )
!
      IF( ILAST.LT.ILASTM ) &
             CALL DROT( ILASTM-ILAST, T( ILAST-1, ILAST+1 ), LDT, &
                        T( ILAST, ILAST+1 ), LDH, CL, SL )
      IF( IFRSTM.LT.ILAST-1 ) &
             CALL DROT( IFIRST-IFRSTM, T( IFRSTM, ILAST-1 ), 1, &
                        T( IFRSTM, ILAST ), 1, CR, SR )
!
      IF( ILQ ) &
             CALL DROT( N, Q( 1, ILAST-1 ), 1, Q( 1, ILAST ), 1, CL, &
                        SL )
      IF( ILZ ) &
             CALL DROT( N, Z( 1, ILAST-1 ), 1, Z( 1, ILAST ), 1, CR, &
                        SR )
!
      T( ILAST-1, ILAST-1 ) = B11
      T( ILAST-1, ILAST ) = ZERO
      T( ILAST, ILAST-1 ) = ZERO
      T( ILAST, ILAST ) = B22
!
!           If B22 is negative, negate column ILAST
!
      IF( B22.LT.ZERO ) THEN
         DO 210 J = IFRSTM, ILAST
            H( J, ILAST ) = -H( J, ILAST )
            T( J, ILAST ) = -T( J, ILAST )
210          CONTINUE
!
         IF( ILZ ) THEN
            DO 220 J = 1, N
               Z( J, ILAST ) = -Z( J, ILAST )
220             CONTINUE
         END IF
      END IF
!
!           Step 2: Compute ALPHAR, ALPHAI, and BETA (see refs.)
!
!           Recompute shift
!
      CALL DLAG2( H( ILAST-1, ILAST-1 ), LDH, &
                      T( ILAST-1, ILAST-1 ), LDT, SAFMIN*SAFETY, S1, &
                      TEMP, WR, TEMP2, WI )
!
!           If standardization has perturbed the shift onto real line,
!           do another (real single-shift) QR step.
!
      IF( WI.EQ.ZERO ) &
             GO TO 350
      S1INV = ONE / S1
!
!           Do EISPACK (QZVAL) computation of alpha and beta
!
      A11 = H( ILAST-1, ILAST-1 )
      A21 = H( ILAST, ILAST-1 )
      A12 = H( ILAST-1, ILAST )
      A22 = H( ILAST, ILAST )
!
!           Compute complex Givens rotation on right
!           (Assume some element of C = (sA - wB) > unfl )
!                            __
!           (sA - wB) ( CZ   -SZ )
!                     ( SZ    CZ )
!
      C11R = S1*A11 - WR*B11
      C11I = -WI*B11
      C12 = S1*A12
      C21 = S1*A21
      C22R = S1*A22 - WR*B22
      C22I = -WI*B22
!
      IF( ABS( C11R )+ABS( C11I )+ABS( C12 ).GT.ABS( C21 )+ &
              ABS( C22R )+ABS( C22I ) ) THEN
         T1 = DLAPY3( C12, C11R, C11I )
         CZ = C12 / T1
         SZR = -C11R / T1
         SZI = -C11I / T1
      ELSE
         CZ = DLAPY2( C22R, C22I )
         IF( CZ.LE.SAFMIN ) THEN
            CZ = ZERO
            SZR = ONE
            SZI = ZERO
         ELSE
            TEMPR = C22R / CZ
            TEMPI = C22I / CZ
            T1 = DLAPY2( CZ, C21 )
            CZ = CZ / T1
            SZR = -C21*TEMPR / T1
            SZI = C21*TEMPI / T1
         END IF
      END IF
!
!           Compute Givens rotation on left
!
!           (  CQ   SQ )
!           (  __      )  A or B
!           ( -SQ   CQ )
!
      AN = ABS( A11 ) + ABS( A12 ) + ABS( A21 ) + ABS( A22 )
      BN = ABS( B11 ) + ABS( B22 )
      WABS = ABS( WR ) + ABS( WI )
      IF( S1*AN.GT.WABS*BN ) THEN
         CQ = CZ*B11
         SQR = SZR*B22
         SQI = -SZI*B22
      ELSE
         A1R = CZ*A11 + SZR*A12
         A1I = SZI*A12
         A2R = CZ*A21 + SZR*A22
         A2I = SZI*A22
         CQ = DLAPY2( A1R, A1I )
         IF( CQ.LE.SAFMIN ) THEN
            CQ = ZERO
            SQR = ONE
            SQI = ZERO
         ELSE
            TEMPR = A1R / CQ
            TEMPI = A1I / CQ
            SQR = TEMPR*A2R + TEMPI*A2I
            SQI = TEMPI*A2R - TEMPR*A2I
         END IF
      END IF
      T1 = DLAPY3( CQ, SQR, SQI )
      CQ = CQ / T1
      SQR = SQR / T1
      SQI = SQI / T1
!
!           Compute diagonal elements of QBZ
!
      TEMPR = SQR*SZR - SQI*SZI
      TEMPI = SQR*SZI + SQI*SZR
      B1R = CQ*CZ*B11 + TEMPR*B22
      B1I = TEMPI*B22
      B1A = DLAPY2( B1R, B1I )
      B2R = CQ*CZ*B22 + TEMPR*B11
      B2I = -TEMPI*B11
      B2A = DLAPY2( B2R, B2I )
!
!           Normalize so beta > 0, and Im( alpha1 ) > 0
!
      BETA( ILAST-1 ) = B1A
      BETA( ILAST ) = B2A
      ALPHAR( ILAST-1 ) = ( WR*B1A )*S1INV
      ALPHAI( ILAST-1 ) = ( WI*B1A )*S1INV
      ALPHAR( ILAST ) = ( WR*B2A )*S1INV
      ALPHAI( ILAST ) = -( WI*B2A )*S1INV
!
!           Step 3: Go to next block -- exit if finished.
!
      ILAST = IFIRST - 1
      IF( ILAST.LT.ILO ) &
             GO TO 380
!
!           Reset counters
!
      IITER = 0
      ESHIFT = ZERO
      IF( .NOT.ILSCHR ) THEN
         ILASTM = ILAST
         IF( IFRSTM.GT.ILAST ) &
                IFRSTM = ILO
      END IF
      GO TO 350
   ELSE
!
!           Usual case: 3x3 or larger block, using Francis implicit
!                       double-shift
!
!                                    2
!           Eigenvalue equation is  w  - c w + d = 0,
!
!                                         -1 2        -1
!           so compute 1st column of  (A B  )  - c A B   + d
!           using the formula in QZIT (from EISPACK)
!
!           We assume that the block is at least 3x3
!
      AD11 = ( ASCALE*H( ILAST-1, ILAST-1 ) ) / &
                 ( BSCALE*T( ILAST-1, ILAST-1 ) )
      AD21 = ( ASCALE*H( ILAST, ILAST-1 ) ) / &
                 ( BSCALE*T( ILAST-1, ILAST-1 ) )
      AD12 = ( ASCALE*H( ILAST-1, ILAST ) ) / &
                 ( BSCALE*T( ILAST, ILAST ) )
      AD22 = ( ASCALE*H( ILAST, ILAST ) ) / &
                 ( BSCALE*T( ILAST, ILAST ) )
      U12 = T( ILAST-1, ILAST ) / T( ILAST, ILAST )
      AD11L = ( ASCALE*H( IFIRST, IFIRST ) ) / &
                  ( BSCALE*T( IFIRST, IFIRST ) )
      AD21L = ( ASCALE*H( IFIRST+1, IFIRST ) ) / &
                  ( BSCALE*T( IFIRST, IFIRST ) )
      AD12L = ( ASCALE*H( IFIRST, IFIRST+1 ) ) / &
                  ( BSCALE*T( IFIRST+1, IFIRST+1 ) )
      AD22L = ( ASCALE*H( IFIRST+1, IFIRST+1 ) ) / &
                  ( BSCALE*T( IFIRST+1, IFIRST+1 ) )
      AD32L = ( ASCALE*H( IFIRST+2, IFIRST+1 ) ) / &
                  ( BSCALE*T( IFIRST+1, IFIRST+1 ) )
      U12L = T( IFIRST, IFIRST+1 ) / T( IFIRST+1, IFIRST+1 )
!
      V( 1 ) = ( AD11-AD11L )*( AD22-AD11L ) - AD12*AD21 + &
                   AD21*U12*AD11L + ( AD12L-AD11L*U12L )*AD21L
      V( 2 ) = ( ( AD22L-AD11L )-AD21L*U12L-( AD11-AD11L )- &
                   ( AD22-AD11L )+AD21*U12 )*AD21L
      V( 3 ) = AD32L*AD21L
!
      ISTART = IFIRST
!
      CALL DLARFG( 3, V( 1 ), V( 2 ), 1, TAU )
      V( 1 ) = ONE
!
!           Sweep
!
      DO 290 J = ISTART, ILAST - 2
!
!              All but last elements: use 3x3 Householder transforms.
!
!              Zero (j-1)st column of A
!
         IF( J.GT.ISTART ) THEN
            V( 1 ) = H( J, J-1 )
            V( 2 ) = H( J+1, J-1 )
            V( 3 ) = H( J+2, J-1 )
!
            CALL DLARFG( 3, H( J, J-1 ), V( 2 ), 1, TAU )
            V( 1 ) = ONE
            H( J+1, J-1 ) = ZERO
            H( J+2, J-1 ) = ZERO
         END IF
!
         DO 230 JC = J, ILASTM
            TEMP = TAU*( H( J, JC )+V( 2 )*H( J+1, JC )+V( 3 )* &
                       H( J+2, JC ) )
            H( J, JC ) = H( J, JC ) - TEMP
            H( J+1, JC ) = H( J+1, JC ) - TEMP*V( 2 )
            H( J+2, JC ) = H( J+2, JC ) - TEMP*V( 3 )
            TEMP2 = TAU*( T( J, JC )+V( 2 )*T( J+1, JC )+V( 3 )* &
                        T( J+2, JC ) )
            T( J, JC ) = T( J, JC ) - TEMP2
            T( J+1, JC ) = T( J+1, JC ) - TEMP2*V( 2 )
            T( J+2, JC ) = T( J+2, JC ) - TEMP2*V( 3 )
230          CONTINUE
         IF( ILQ ) THEN
            DO 240 JR = 1, N
               TEMP = TAU*( Q( JR, J )+V( 2 )*Q( JR, J+1 )+V( 3 )* &
                          Q( JR, J+2 ) )
               Q( JR, J ) = Q( JR, J ) - TEMP
               Q( JR, J+1 ) = Q( JR, J+1 ) - TEMP*V( 2 )
               Q( JR, J+2 ) = Q( JR, J+2 ) - TEMP*V( 3 )
240             CONTINUE
         END IF
!
!              Zero j-th column of B (see DLAGBC for details)
!
!              Swap rows to pivot
!
         ILPIVT = .FALSE.
         TEMP = MAX( ABS( T( J+1, J+1 ) ), ABS( T( J+1, J+2 ) ) )
         TEMP2 = MAX( ABS( T( J+2, J+1 ) ), ABS( T( J+2, J+2 ) ) )
         IF( MAX( TEMP, TEMP2 ).LT.SAFMIN ) THEN
            SCALE = ZERO
            U1 = ONE
            U2 = ZERO
            GO TO 250
         ELSE IF( TEMP.GE.TEMP2 ) THEN
            W11 = T( J+1, J+1 )
            W21 = T( J+2, J+1 )
            W12 = T( J+1, J+2 )
            W22 = T( J+2, J+2 )
            U1 = T( J+1, J )
            U2 = T( J+2, J )
         ELSE
            W21 = T( J+1, J+1 )
            W11 = T( J+2, J+1 )
            W22 = T( J+1, J+2 )
            W12 = T( J+2, J+2 )
            U2 = T( J+1, J )
            U1 = T( J+2, J )
         END IF
!
!              Swap columns if nec.
!
         IF( ABS( W12 ).GT.ABS( W11 ) ) THEN
            ILPIVT = .TRUE.
            TEMP = W12
            TEMP2 = W22
            W12 = W11
            W22 = W21
            W11 = TEMP
            W21 = TEMP2
         END IF
!
!              LU-factor
!
         TEMP = W21 / W11
         U2 = U2 - TEMP*U1
         W22 = W22 - TEMP*W12
         W21 = ZERO
!
!              Compute SCALE
!
         SCALE = ONE
         IF( ABS( W22 ).LT.SAFMIN ) THEN
            SCALE = ZERO
            U2 = ONE
            U1 = -W12 / W11
            GO TO 250
         END IF
         IF( ABS( W22 ).LT.ABS( U2 ) ) &
                SCALE = ABS( W22 / U2 )
         IF( ABS( W11 ).LT.ABS( U1 ) ) &
                SCALE = MIN( SCALE, ABS( W11 / U1 ) )
!
!              Solve
!
         U2 = ( SCALE*U2 ) / W22
         U1 = ( SCALE*U1-W12*U2 ) / W11
!
250          CONTINUE
         IF( ILPIVT ) THEN
            TEMP = U2
            U2 = U1
            U1 = TEMP
         END IF
!
!              Compute Householder Vector
!
         T1 = SQRT( SCALE**2+U1**2+U2**2 )
         TAU = ONE + SCALE / T1
         VS = -ONE / ( SCALE+T1 )
         V( 1 ) = ONE
         V( 2 ) = VS*U1
         V( 3 ) = VS*U2
!
!              Apply transformations from the right.
!
         DO 260 JR = IFRSTM, MIN( J+3, ILAST )
            TEMP = TAU*( H( JR, J )+V( 2 )*H( JR, J+1 )+V( 3 )* &
                       H( JR, J+2 ) )
            H( JR, J ) = H( JR, J ) - TEMP
            H( JR, J+1 ) = H( JR, J+1 ) - TEMP*V( 2 )
            H( JR, J+2 ) = H( JR, J+2 ) - TEMP*V( 3 )
260          CONTINUE
         DO 270 JR = IFRSTM, J + 2
            TEMP = TAU*( T( JR, J )+V( 2 )*T( JR, J+1 )+V( 3 )* &
                       T( JR, J+2 ) )
            T( JR, J ) = T( JR, J ) - TEMP
            T( JR, J+1 ) = T( JR, J+1 ) - TEMP*V( 2 )
            T( JR, J+2 ) = T( JR, J+2 ) - TEMP*V( 3 )
270          CONTINUE
         IF( ILZ ) THEN
            DO 280 JR = 1, N
               TEMP = TAU*( Z( JR, J )+V( 2 )*Z( JR, J+1 )+V( 3 )* &
                          Z( JR, J+2 ) )
               Z( JR, J ) = Z( JR, J ) - TEMP
               Z( JR, J+1 ) = Z( JR, J+1 ) - TEMP*V( 2 )
               Z( JR, J+2 ) = Z( JR, J+2 ) - TEMP*V( 3 )
280             CONTINUE
         END IF
         T( J+1, J ) = ZERO
         T( J+2, J ) = ZERO
290       CONTINUE
!
!           Last elements: Use Givens rotations
!
!           Rotations from the left
!
      J = ILAST - 1
      TEMP = H( J, J-1 )
      CALL DLARTG( TEMP, H( J+1, J-1 ), C, S, H( J, J-1 ) )
      H( J+1, J-1 ) = ZERO
!
      DO 300 JC = J, ILASTM
         TEMP = C*H( J, JC ) + S*H( J+1, JC )
         H( J+1, JC ) = -S*H( J, JC ) + C*H( J+1, JC )
         H( J, JC ) = TEMP
         TEMP2 = C*T( J, JC ) + S*T( J+1, JC )
         T( J+1, JC ) = -S*T( J, JC ) + C*T( J+1, JC )
         T( J, JC ) = TEMP2
300       CONTINUE
      IF( ILQ ) THEN
         DO 310 JR = 1, N
            TEMP = C*Q( JR, J ) + S*Q( JR, J+1 )
            Q( JR, J+1 ) = -S*Q( JR, J ) + C*Q( JR, J+1 )
            Q( JR, J ) = TEMP
310          CONTINUE
      END IF
!
!           Rotations from the right.
!
      TEMP = T( J+1, J+1 )
      CALL DLARTG( TEMP, T( J+1, J ), C, S, T( J+1, J+1 ) )
      T( J+1, J ) = ZERO
!
      DO 320 JR = IFRSTM, ILAST
         TEMP = C*H( JR, J+1 ) + S*H( JR, J )
         H( JR, J ) = -S*H( JR, J+1 ) + C*H( JR, J )
         H( JR, J+1 ) = TEMP
320       CONTINUE
      DO 330 JR = IFRSTM, ILAST - 1
         TEMP = C*T( JR, J+1 ) + S*T( JR, J )
         T( JR, J ) = -S*T( JR, J+1 ) + C*T( JR, J )
         T( JR, J+1 ) = TEMP
330       CONTINUE
      IF( ILZ ) THEN
         DO 340 JR = 1, N
            TEMP = C*Z( JR, J+1 ) + S*Z( JR, J )
            Z( JR, J ) = -S*Z( JR, J+1 ) + C*Z( JR, J )
            Z( JR, J+1 ) = TEMP
340          CONTINUE
      END IF
!
!           End of Double-Shift code
!
   END IF
!
   GO TO 350
!
!        End of iteration loop
!
350    CONTINUE
360 CONTINUE
!
!     Drop-through = non-convergence
!
INFO = ILAST
GO TO 420
!
!     Successful completion of all QZ steps
!
380 CONTINUE
!
!     Set Eigenvalues 1:ILO-1
!
DO 410 J = 1, ILO - 1
   IF( T( J, J ).LT.ZERO ) THEN
      IF( ILSCHR ) THEN
         DO 390 JR = 1, J
            H( JR, J ) = -H( JR, J )
            T( JR, J ) = -T( JR, J )
390          CONTINUE
      ELSE
         H( J, J ) = -H( J, J )
         T( J, J ) = -T( J, J )
      END IF
      IF( ILZ ) THEN
         DO 400 JR = 1, N
            Z( JR, J ) = -Z( JR, J )
400          CONTINUE
      END IF
   END IF
   ALPHAR( J ) = H( J, J )
   ALPHAI( J ) = ZERO
   BETA( J ) = T( J, J )
410 CONTINUE
!
!     Normal Termination
!
INFO = 0
!
!     Exit (other than argument error) -- return optimal workspace size
!
420 CONTINUE
WORK( 1 ) = DBLE( N )
RETURN
!
!     End of DHGEQZ
!
end subroutine dhgeqz

! ===== End dhgeqz.f90 =====


! ===== Begin dhseqr.f90 =====

SUBROUTINE DHSEQR( JOB, COMPZ, N, ILO, IHI, H, LDH, WR, WI, Z, &
                       LDZ, WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
CHARACTER          COMPZ, JOB
INTEGER            IHI, ILO, INFO, LDH, LDZ, LWORK, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   H( LDH, * ), WI( * ), WORK( * ), WR( * ), &
                       Z( LDZ, * )
!     ..
!
!  Purpose
!  =======
!
!  DHSEQR computes the eigenvalues of a real upper Hessenberg matrix H
!  and, optionally, the matrices T and Z from the Schur decomposition
!  H = Z T Z**T, where T is an upper quasi-triangular matrix (the Schur
!  form), and Z is the orthogonal matrix of Schur vectors.
!
!  Optionally Z may be postmultiplied into an input orthogonal matrix Q,
!  so that this routine can give the Schur factorization of a matrix A
!  which has been reduced to the Hessenberg form H by the orthogonal
!  matrix Q:  A = Q*H*Q**T = (QZ)*T*(QZ)**T.
!
!  Arguments
!  =========
!
!  JOB     (input) CHARACTER*1
!          = 'E':  compute eigenvalues only;
!          = 'S':  compute eigenvalues and the Schur form T.
!
!  COMPZ   (input) CHARACTER*1
!          = 'N':  no Schur vectors are computed;
!          = 'I':  Z is initialized to the unit matrix and the matrix Z
!                  of Schur vectors of H is returned;
!          = 'V':  Z must contain an orthogonal matrix Q on entry, and
!                  the product Q*Z is returned.
!
!  N       (input) INTEGER
!          The order of the matrix H.  N >= 0.
!
!  ILO     (input) INTEGER
!  IHI     (input) INTEGER
!          It is assumed that H is already upper triangular in rows
!          and columns 1:ILO-1 and IHI+1:N. ILO and IHI are normally
!          set by a previous call to DGEBAL, and then passed to SGEHRD
!          when the matrix output by DGEBAL is reduced to Hessenberg
!          form. Otherwise ILO and IHI should be set to 1 and N
!          respectively.
!          1 <= ILO <= IHI <= N, if N > 0; ILO=1 and IHI=0, if N=0.
!
!  H       (input/output) DOUBLE PRECISION array, dimension (LDH,N)
!          On entry, the upper Hessenberg matrix H.
!          On exit, if JOB = 'S', H contains the upper quasi-triangular
!          matrix T from the Schur decomposition (the Schur form);
!          2-by-2 diagonal blocks (corresponding to complex conjugate
!          pairs of eigenvalues) are returned in standard form, with
!          H(i,i) = H(i+1,i+1) and H(i+1,i)*H(i,i+1) < 0. If JOB = 'E',
!          the contents of H are unspecified on exit.
!
!  LDH     (input) INTEGER
!          The leading dimension of the array H. LDH >= max(1,N).
!
!  WR      (output) DOUBLE PRECISION array, dimension (N)
!  WI      (output) DOUBLE PRECISION array, dimension (N)
!          The real and imaginary parts, respectively, of the computed
!          eigenvalues. If two eigenvalues are computed as a complex
!          conjugate pair, they are stored in consecutive elements of
!          WR and WI, say the i-th and (i+1)th, with WI(i) > 0 and
!          WI(i+1) < 0. If JOB = 'S', the eigenvalues are stored in the
!          same order as on the diagonal of the Schur form returned in
!          H, with WR(i) = H(i,i) and, if H(i:i+1,i:i+1) is a 2-by-2
!          diagonal block, WI(i) = sqrt(H(i+1,i)*H(i,i+1)) and
!          WI(i+1) = -WI(i).
!
!  Z       (input/output) DOUBLE PRECISION array, dimension (LDZ,N)
!          If COMPZ = 'N': Z is not referenced.
!          If COMPZ = 'I': on entry, Z need not be set, and on exit, Z
!          contains the orthogonal matrix Z of the Schur vectors of H.
!          If COMPZ = 'V': on entry Z must contain an N-by-N matrix Q,
!          which is assumed to be equal to the unit matrix except for
!          the submatrix Z(ILO:IHI,ILO:IHI); on exit Z contains Q*Z.
!          Normally Q is the orthogonal matrix generated by DORGHR after
!          the call to DGEHRD which formed the Hessenberg matrix H.
!
!  LDZ     (input) INTEGER
!          The leading dimension of the array Z.
!          LDZ >= max(1,N) if COMPZ = 'I' or 'V'; LDZ >= 1 otherwise.
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.  LWORK >= max(1,N).
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, DHSEQR failed to compute all of the
!                eigenvalues in a total of 30*(IHI-ILO+1) iterations;
!                elements 1:ilo-1 and i+1:n of WR and WI contain those
!                eigenvalues which have been successfully computed.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE, TWO
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0, TWO = 2.0D+0 )
DOUBLE PRECISION   CONST
PARAMETER          ( CONST = 1.5D+0 )
INTEGER            NSMAX, LDS
PARAMETER          ( NSMAX = 15, LDS = NSMAX )
!     ..
!     .. Local Scalars ..
LOGICAL            INITZ, LQUERY, WANTT, WANTZ
INTEGER            I, I1, I2, IERR, II, ITEMP, ITN, ITS, J, K, L, &
                       MAXB, NH, NR, NS, NV
DOUBLE PRECISION   ABSW, OVFL, SMLNUM, TAU, TEMP, TST1, ULP, UNFL
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   S( LDS, NSMAX ), V( NSMAX+1 ), VV( NSMAX+1 )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            IDAMAX, ILAENV
DOUBLE PRECISION   DLAMCH, DLANHS, DLAPY2
EXTERNAL           LSAME, IDAMAX, ILAENV, DLAMCH, DLANHS, DLAPY2
!     ..
!     .. External Subroutines ..
EXTERNAL           DCOPY, DGEMV, DLACPY, DLAHQR, DLARFG, DLARFX, &
                       DLASET, DSCAL, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Decode and test the input parameters
!
WANTT = LSAME( JOB, 'S' )
INITZ = LSAME( COMPZ, 'I' )
WANTZ = INITZ .OR. LSAME( COMPZ, 'V' )
!
INFO = 0
WORK( 1 ) = MAX( 1, N )
LQUERY = ( LWORK.EQ.-1 )
IF( .NOT.LSAME( JOB, 'E' ) .AND. .NOT.WANTT ) THEN
   INFO = -1
ELSE IF( .NOT.LSAME( COMPZ, 'N' ) .AND. .NOT.WANTZ ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( ILO.LT.1 .OR. ILO.GT.MAX( 1, N ) ) THEN
   INFO = -4
ELSE IF( IHI.LT.MIN( ILO, N ) .OR. IHI.GT.N ) THEN
   INFO = -5
ELSE IF( LDH.LT.MAX( 1, N ) ) THEN
   INFO = -7
ELSE IF( LDZ.LT.1 .OR. WANTZ .AND. LDZ.LT.MAX( 1, N ) ) THEN
   INFO = -11
ELSE IF( LWORK.LT.MAX( 1, N ) .AND. .NOT.LQUERY ) THEN
   INFO = -13
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DHSEQR', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Initialize Z, if necessary
!
IF( INITZ ) &
       CALL DLASET( 'Full', N, N, ZERO, ONE, Z, LDZ )
!
!     Store the eigenvalues isolated by DGEBAL.
!
DO 10 I = 1, ILO - 1
   WR( I ) = H( I, I )
   WI( I ) = ZERO
10 CONTINUE
DO 20 I = IHI + 1, N
   WR( I ) = H( I, I )
   WI( I ) = ZERO
20 CONTINUE
!
!     Quick return if possible.
!
IF( N.EQ.0 ) &
       RETURN
IF( ILO.EQ.IHI ) THEN
   WR( ILO ) = H( ILO, ILO )
   WI( ILO ) = ZERO
   RETURN
END IF
!
!     Set rows and columns ILO to IHI to zero below the first
!     subdiagonal.
!
DO 40 J = ILO, IHI - 2
   DO 30 I = J + 2, N
      H( I, J ) = ZERO
30    CONTINUE
40 CONTINUE
NH = IHI - ILO + 1
!
!     Determine the order of the multi-shift QR algorithm to be used.
!
NS = ILAENV( 4, 'DHSEQR', JOB // COMPZ, N, ILO, IHI, -1 )
MAXB = ILAENV( 8, 'DHSEQR', JOB // COMPZ, N, ILO, IHI, -1 )
IF( NS.LE.2 .OR. NS.GT.NH .OR. MAXB.GE.NH ) THEN
!
!        Use the standard double-shift algorithm
!
   CALL DLAHQR( WANTT, WANTZ, N, ILO, IHI, H, LDH, WR, WI, ILO, &
                    IHI, Z, LDZ, INFO )
   RETURN
END IF
MAXB = MAX( 3, MAXB )
NS = MIN( NS, MAXB, NSMAX )
!
!     Now 2 < NS <= MAXB < NH.
!
!     Set machine-dependent constants for the stopping criterion.
!     If norm(H) <= sqrt(OVFL), overflow should not occur.
!
UNFL = DLAMCH( 'Safe minimum' )
OVFL = ONE / UNFL
CALL DLABAD( UNFL, OVFL )
ULP = DLAMCH( 'Precision' )
SMLNUM = UNFL*( NH / ULP )
!
!     I1 and I2 are the indices of the first row and last column of H
!     to which transformations must be applied. If eigenvalues only are
!     being computed, I1 and I2 are set inside the main loop.
!
IF( WANTT ) THEN
   I1 = 1
   I2 = N
END IF
!
!     ITN is the total number of multiple-shift QR iterations allowed.
!
ITN = 30*NH
!
!     The main loop begins here. I is the loop index and decreases from
!     IHI to ILO in steps of at most MAXB. Each iteration of the loop
!     works with the active submatrix in rows and columns L to I.
!     Eigenvalues I+1 to IHI have already converged. Either L = ILO or
!     H(L,L-1) is negligible so that the matrix splits.
!
I = IHI
50 CONTINUE
L = ILO
IF( I.LT.ILO ) &
       GO TO 170
!
!     Perform multiple-shift QR iterations on rows and columns ILO to I
!     until a submatrix of order at most MAXB splits off at the bottom
!     because a subdiagonal element has become negligible.
!
DO 150 ITS = 0, ITN
!
!        Look for a single small subdiagonal element.
!
   DO 60 K = I, L + 1, -1
      TST1 = ABS( H( K-1, K-1 ) ) + ABS( H( K, K ) )
      IF( TST1.EQ.ZERO ) &
             TST1 = DLANHS( '1', I-L+1, H( L, L ), LDH, WORK )
      IF( ABS( H( K, K-1 ) ).LE.MAX( ULP*TST1, SMLNUM ) ) &
             GO TO 70
60    CONTINUE
70    CONTINUE
   L = K
   IF( L.GT.ILO ) THEN
!
!           H(L,L-1) is negligible.
!
      H( L, L-1 ) = ZERO
   END IF
!
!        Exit from loop if a submatrix of order <= MAXB has split off.
!
   IF( L.GE.I-MAXB+1 ) &
          GO TO 160
!
!        Now the active submatrix is in rows and columns L to I. If
!        eigenvalues only are being computed, only the active submatrix
!        need be transformed.
!
   IF( .NOT.WANTT ) THEN
      I1 = L
      I2 = I
   END IF
!
   IF( ITS.EQ.20 .OR. ITS.EQ.30 ) THEN
!
!           Exceptional shifts.
!
      DO 80 II = I - NS + 1, I
         WR( II ) = CONST*( ABS( H( II, II-1 ) )+ &
                        ABS( H( II, II ) ) )
         WI( II ) = ZERO
80       CONTINUE
   ELSE
!
!           Use eigenvalues of trailing submatrix of order NS as shifts.
!
      CALL DLACPY( 'Full', NS, NS, H( I-NS+1, I-NS+1 ), LDH, S, &
                       LDS )
      CALL DLAHQR( .FALSE., .FALSE., NS, 1, NS, S, LDS, &
                       WR( I-NS+1 ), WI( I-NS+1 ), 1, NS, Z, LDZ, &
                       IERR )
      IF( IERR.GT.0 ) THEN
!
!              If DLAHQR failed to compute all NS eigenvalues, use the
!              unconverged diagonal elements as the remaining shifts.
!
         DO 90 II = 1, IERR
            WR( I-NS+II ) = S( II, II )
            WI( I-NS+II ) = ZERO
90          CONTINUE
      END IF
   END IF
!
!        Form the first column of (G-w(1)) (G-w(2)) . . . (G-w(ns))
!        where G is the Hessenberg submatrix H(L:I,L:I) and w is
!        the vector of shifts (stored in WR and WI). The result is
!        stored in the local array V.
!
   V( 1 ) = ONE
   DO 100 II = 2, NS + 1
      V( II ) = ZERO
100    CONTINUE
   NV = 1
   DO 120 J = I - NS + 1, I
      IF( WI( J ).GE.ZERO ) THEN
         IF( WI( J ).EQ.ZERO ) THEN
!
!                 real shift
!
            CALL DCOPY( NV+1, V, 1, VV, 1 )
            CALL DGEMV( 'No transpose', NV+1, NV, ONE, H( L, L ), &
                            LDH, VV, 1, -WR( J ), V, 1 )
            NV = NV + 1
         ELSE IF( WI( J ).GT.ZERO ) THEN
!
!                 complex conjugate pair of shifts
!
            CALL DCOPY( NV+1, V, 1, VV, 1 )
            CALL DGEMV( 'No transpose', NV+1, NV, ONE, H( L, L ), &
                            LDH, V, 1, -TWO*WR( J ), VV, 1 )
            ITEMP = IDAMAX( NV+1, VV, 1 )
            TEMP = ONE / MAX( ABS( VV( ITEMP ) ), SMLNUM )
            CALL DSCAL( NV+1, TEMP, VV, 1 )
            ABSW = DLAPY2( WR( J ), WI( J ) )
            TEMP = ( TEMP*ABSW )*ABSW
            CALL DGEMV( 'No transpose', NV+2, NV+1, ONE, &
                            H( L, L ), LDH, VV, 1, TEMP, V, 1 )
            NV = NV + 2
         END IF
!
!              Scale V(1:NV) so that max(abs(V(i))) = 1. If V is zero,
!              reset it to the unit vector.
!
         ITEMP = IDAMAX( NV, V, 1 )
         TEMP = ABS( V( ITEMP ) )
         IF( TEMP.EQ.ZERO ) THEN
            V( 1 ) = ONE
            DO 110 II = 2, NV
               V( II ) = ZERO
110             CONTINUE
         ELSE
            TEMP = MAX( TEMP, SMLNUM )
            CALL DSCAL( NV, ONE / TEMP, V, 1 )
         END IF
      END IF
120    CONTINUE
!
!        Multiple-shift QR step
!
   DO 140 K = L, I - 1
!
!           The first iteration of this loop determines a reflection G
!           from the vector V and applies it from left and right to H,
!           thus creating a nonzero bulge below the subdiagonal.
!
!           Each subsequent iteration determines a reflection G to
!           restore the Hessenberg form in the (K-1)th column, and thus
!           chases the bulge one step toward the bottom of the active
!           submatrix. NR is the order of G.
!
      NR = MIN( NS+1, I-K+1 )
      IF( K.GT.L ) &
             CALL DCOPY( NR, H( K, K-1 ), 1, V, 1 )
      CALL DLARFG( NR, V( 1 ), V( 2 ), 1, TAU )
      IF( K.GT.L ) THEN
         H( K, K-1 ) = V( 1 )
         DO 130 II = K + 1, I
            H( II, K-1 ) = ZERO
130          CONTINUE
      END IF
      V( 1 ) = ONE
!
!           Apply G from the left to transform the rows of the matrix in
!           columns K to I2.
!
      CALL DLARFX( 'Left', NR, I2-K+1, V, TAU, H( K, K ), LDH, &
                       WORK )
!
!           Apply G from the right to transform the columns of the
!           matrix in rows I1 to min(K+NR,I).
!
      CALL DLARFX( 'Right', MIN( K+NR, I )-I1+1, NR, V, TAU, &
                       H( I1, K ), LDH, WORK )
!
      IF( WANTZ ) THEN
!
!              Accumulate transformations in the matrix Z
!
         CALL DLARFX( 'Right', NH, NR, V, TAU, Z( ILO, K ), LDZ, &
                          WORK )
      END IF
140    CONTINUE
!
150 CONTINUE
!
!     Failure to converge in remaining number of iterations
!
INFO = I
RETURN
!
160 CONTINUE
!
!     A submatrix of order <= MAXB in rows and columns L to I has split
!     off. Use the double-shift QR algorithm to handle it.
!
CALL DLAHQR( WANTT, WANTZ, N, L, I, H, LDH, WR, WI, ILO, IHI, Z, &
                 LDZ, INFO )
IF( INFO.GT.0 ) &
       RETURN
!
!     Decrement number of remaining iterations, and return to start of
!     the main loop with a new value of I.
!
ITN = ITN - ITS
I = L - 1
GO TO 50
!
170 CONTINUE
WORK( 1 ) = MAX( 1, N )
RETURN
!
!     End of DHSEQR
!
end subroutine dhseqr

! ===== End dhseqr.f90 =====


! ===== Begin dlabad.f90 =====

SUBROUTINE DLABAD( SMALL, LARGE )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   LARGE, SMALL
!     ..
!
!  Purpose
!  =======
!
!  DLABAD takes as input the values computed by SLAMCH for underflow and
!  overflow, and returns the square root of each of these values if the
!  log of LARGE is sufficiently large.  This subroutine is intended to
!  identify machines with a large exponent range, such as the Crays, and
!  redefine the underflow and overflow limits to be the square roots of
!  the values computed by DLAMCH.  This subroutine is needed because
!  DLAMCH does not compensate for poor arithmetic in the upper half of
!  the exponent range, as is found on a Cray.
!
!  Arguments
!  =========
!
!  SMALL   (input/output) DOUBLE PRECISION
!          On entry, the underflow threshold as computed by DLAMCH.
!          On exit, if LOG10(LARGE) is sufficiently large, the square
!          root of SMALL, otherwise unchanged.
!
!  LARGE   (input/output) DOUBLE PRECISION
!          On entry, the overflow threshold as computed by DLAMCH.
!          On exit, if LOG10(LARGE) is sufficiently large, the square
!          root of LARGE, otherwise unchanged.
!
!  =====================================================================
!
!     .. Intrinsic Functions ..
INTRINSIC          LOG10, SQRT
!     ..
!     .. Executable Statements ..
!
!     If it looks like we're on a Cray, take the square root of
!     SMALL and LARGE to avoid overflow and underflow problems.
!
IF( LOG10( LARGE ).GT.2000.D0 ) THEN
   SMALL = SQRT( SMALL )
   LARGE = SQRT( LARGE )
END IF
!
RETURN
!
!     End of DLABAD
!
end subroutine dlabad

! ===== End dlabad.f90 =====


! ===== Begin dlacon.f90 =====

SUBROUTINE DLACON( N, V, X, ISGN, EST, KASE )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            KASE, N
DOUBLE PRECISION   EST
!     ..
!     .. Array Arguments ..
INTEGER            ISGN( * )
DOUBLE PRECISION   V( * ), X( * )
!     ..
!
!  Purpose
!  =======
!
!  DLACON estimates the 1-norm of a square, real matrix A.
!  Reverse communication is used for evaluating matrix-vector products.
!
!  Arguments
!  =========
!
!  N      (input) INTEGER
!         The order of the matrix.  N >= 1.
!
!  V      (workspace) DOUBLE PRECISION array, dimension (N)
!         On the final return, V = A*W,  where  EST = norm(V)/norm(W)
!         (W is not returned).
!
!  X      (input/output) DOUBLE PRECISION array, dimension (N)
!         On an intermediate return, X should be overwritten by
!               A * X,   if KASE=1,
!               A' * X,  if KASE=2,
!         and DLACON must be re-called with all the other parameters
!         unchanged.
!
!  ISGN   (workspace) INTEGER array, dimension (N)
!
!  EST    (output) DOUBLE PRECISION
!         An estimate (a lower bound) for norm(A).
!
!  KASE   (input/output) INTEGER
!         On the initial call to DLACON, KASE should be 0.
!         On an intermediate return, KASE will be 1 or 2, indicating
!         whether X should be overwritten by A * X  or A' * X.
!         On the final return from DLACON, KASE will again be 0.
!
!  Further Details
!  ======= =======
!
!  Contributed by Nick Higham, University of Manchester.
!  Originally named SONEST, dated March 16, 1988.
!
!  Reference: N.J. Higham, "FORTRAN codes for estimating the one-norm of
!  a real or complex matrix, with applications to condition estimation",
!  ACM Trans. Math. Soft., vol. 14, no. 4, pp. 381-396, December 1988.
!
!  =====================================================================
!
!     .. Parameters ..
INTEGER            ITMAX
PARAMETER          ( ITMAX = 5 )
DOUBLE PRECISION   ZERO, ONE, TWO
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0, TWO = 2.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, ITER, J, JLAST, JUMP
DOUBLE PRECISION   ALTSGN, ESTOLD, TEMP
!     ..
!     .. External Functions ..
INTEGER            IDAMAX
DOUBLE PRECISION   DASUM
EXTERNAL           IDAMAX, DASUM
!     ..
!     .. External Subroutines ..
EXTERNAL           DCOPY
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, DBLE, NINT, SIGN
!     ..
!     .. Save statement ..
SAVE
!     ..
!     .. Executable Statements ..
!
IF( KASE.EQ.0 ) THEN
   DO 10 I = 1, N
      X( I ) = ONE / DBLE( N )
10    CONTINUE
   KASE = 1
   JUMP = 1
   RETURN
END IF
!
GO TO ( 20, 40, 70, 110, 140 )JUMP
!
!     ................ ENTRY   (JUMP = 1)
!     FIRST ITERATION.  X HAS BEEN OVERWRITTEN BY A*X.
!
20 CONTINUE
IF( N.EQ.1 ) THEN
   V( 1 ) = X( 1 )
   EST = ABS( V( 1 ) )
!        ... QUIT
   GO TO 150
END IF
EST = DASUM( N, X, 1 )
!
DO 30 I = 1, N
   X( I ) = SIGN( ONE, X( I ) )
   ISGN( I ) = NINT( X( I ) )
30 CONTINUE
KASE = 2
JUMP = 2
RETURN
!
!     ................ ENTRY   (JUMP = 2)
!     FIRST ITERATION.  X HAS BEEN OVERWRITTEN BY TRANDPOSE(A)*X.
!
40 CONTINUE
J = IDAMAX( N, X, 1 )
ITER = 2
!
!     MAIN LOOP - ITERATIONS 2,3,...,ITMAX.
!
50 CONTINUE
DO 60 I = 1, N
   X( I ) = ZERO
60 CONTINUE
X( J ) = ONE
KASE = 1
JUMP = 3
RETURN
!
!     ................ ENTRY   (JUMP = 3)
!     X HAS BEEN OVERWRITTEN BY A*X.
!
70 CONTINUE
CALL DCOPY( N, X, 1, V, 1 )
ESTOLD = EST
EST = DASUM( N, V, 1 )
DO 80 I = 1, N
   IF( NINT( SIGN( ONE, X( I ) ) ).NE.ISGN( I ) ) &
          GO TO 90
80 CONTINUE
!     REPEATED SIGN VECTOR DETECTED, HENCE ALGORITHM HAS CONVERGED.
GO TO 120
!
90 CONTINUE
!     TEST FOR CYCLING.
IF( EST.LE.ESTOLD ) &
       GO TO 120
!
DO 100 I = 1, N
   X( I ) = SIGN( ONE, X( I ) )
   ISGN( I ) = NINT( X( I ) )
100 CONTINUE
KASE = 2
JUMP = 4
RETURN
!
!     ................ ENTRY   (JUMP = 4)
!     X HAS BEEN OVERWRITTEN BY TRANDPOSE(A)*X.
!
110 CONTINUE
JLAST = J
J = IDAMAX( N, X, 1 )
IF( ( X( JLAST ).NE.ABS( X( J ) ) ) .AND. ( ITER.LT.ITMAX ) ) THEN
   ITER = ITER + 1
   GO TO 50
END IF
!
!     ITERATION COMPLETE.  FINAL STAGE.
!
120 CONTINUE
ALTSGN = ONE
DO 130 I = 1, N
   X( I ) = ALTSGN*( ONE+DBLE( I-1 ) / DBLE( N-1 ) )
   ALTSGN = -ALTSGN
130 CONTINUE
KASE = 1
JUMP = 5
RETURN
!
!     ................ ENTRY   (JUMP = 5)
!     X HAS BEEN OVERWRITTEN BY A*X.
!
140 CONTINUE
TEMP = TWO*( DASUM( N, X, 1 ) / DBLE( 3*N ) )
IF( TEMP.GT.EST ) THEN
   CALL DCOPY( N, X, 1, V, 1 )
   EST = TEMP
END IF
!
150 CONTINUE
KASE = 0
RETURN
!
!     End of DLACON
!
end subroutine dlacon

! ===== End dlacon.f90 =====


! ===== Begin dlacpy.f90 =====

SUBROUTINE DLACPY( UPLO, M, N, A, LDA, B, LDB )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          UPLO
INTEGER            LDA, LDB, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DLACPY copies all or part of a two-dimensional matrix A to another
!  matrix B.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          Specifies the part of the matrix A to be copied to B.
!          = 'U':      Upper triangular part
!          = 'L':      Lower triangular part
!          Otherwise:  All of the matrix A
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
!          The m by n matrix A.  If UPLO = 'U', only the upper triangle
!          or trapezoid is accessed; if UPLO = 'L', only the lower
!          triangle or trapezoid is accessed.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  B       (output) DOUBLE PRECISION array, dimension (LDB,N)
!          On exit, B = A in the locations specified by UPLO.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,M).
!
!  =====================================================================
!
!     .. Local Scalars ..
INTEGER            I, J
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MIN
!     ..
!     .. Executable Statements ..
!
IF( LSAME( UPLO, 'U' ) ) THEN
   DO 20 J = 1, N
      DO 10 I = 1, MIN( J, M )
         B( I, J ) = A( I, J )
10       CONTINUE
20    CONTINUE
ELSE IF( LSAME( UPLO, 'L' ) ) THEN
   DO 40 J = 1, N
      DO 30 I = J, M
         B( I, J ) = A( I, J )
30       CONTINUE
40    CONTINUE
ELSE
   DO 60 J = 1, N
      DO 50 I = 1, M
         B( I, J ) = A( I, J )
50       CONTINUE
60    CONTINUE
END IF
RETURN
!
!     End of DLACPY
!
end subroutine dlacpy

! ===== End dlacpy.f90 =====


! ===== Begin dladiv.f90 =====

SUBROUTINE DLADIV( A, B, C, D, P, Q )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   A, B, C, D, P, Q
!     ..
!
!  Purpose
!  =======
!
!  DLADIV performs complex division in  real arithmetic
!
!                        a + i*b
!             p + i*q = ---------
!                        c + i*d
!
!  The algorithm is due to Robert L. Smith and can be found
!  in D. Knuth, The art of Computer Programming, Vol.2, p.195
!
!  Arguments
!  =========
!
!  A       (input) DOUBLE PRECISION
!  B       (input) DOUBLE PRECISION
!  C       (input) DOUBLE PRECISION
!  D       (input) DOUBLE PRECISION
!          The scalars a, b, c, and d in the above expression.
!
!  P       (output) DOUBLE PRECISION
!  Q       (output) DOUBLE PRECISION
!          The scalars p and q in the above expression.
!
!  =====================================================================
!
!     .. Local Scalars ..
DOUBLE PRECISION   E, F
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS
!     ..
!     .. Executable Statements ..
!
IF( ABS( D ).LT.ABS( C ) ) THEN
   E = D / C
   F = C + D*E
   P = ( A+B*E ) / F
   Q = ( B-A*E ) / F
ELSE
   E = C / D
   F = D + C*E
   P = ( B+A*E ) / F
   Q = ( -A+B*E ) / F
END IF
!
RETURN
!
!     End of DLADIV
!
end subroutine dladiv

! ===== End dladiv.f90 =====


! ===== Begin dlae2.f90 =====

SUBROUTINE DLAE2( A, B, C, RT1, RT2 )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   A, B, C, RT1, RT2
!     ..
!
!  Purpose
!  =======
!
!  DLAE2  computes the eigenvalues of a 2-by-2 symmetric matrix
!     [  A   B  ]
!     [  B   C  ].
!  On return, RT1 is the eigenvalue of larger absolute value, and RT2
!  is the eigenvalue of smaller absolute value.
!
!  Arguments
!  =========
!
!  A       (input) DOUBLE PRECISION
!          The (1,1) element of the 2-by-2 matrix.
!
!  B       (input) DOUBLE PRECISION
!          The (1,2) and (2,1) elements of the 2-by-2 matrix.
!
!  C       (input) DOUBLE PRECISION
!          The (2,2) element of the 2-by-2 matrix.
!
!  RT1     (output) DOUBLE PRECISION
!          The eigenvalue of larger absolute value.
!
!  RT2     (output) DOUBLE PRECISION
!          The eigenvalue of smaller absolute value.
!
!  Further Details
!  ===============
!
!  RT1 is accurate to a few ulps barring over/underflow.
!
!  RT2 may be inaccurate if there is massive cancellation in the
!  determinant A*C-B*B; higher precision or correctly rounded or
!  correctly truncated arithmetic would be needed to compute RT2
!  accurately in all cases.
!
!  Overflow is possible only if RT1 is within a factor of 5 of overflow.
!  Underflow is harmless if the input data is 0 or exceeds
!     underflow_threshold / macheps.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D0 )
DOUBLE PRECISION   TWO
PARAMETER          ( TWO = 2.0D0 )
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D0 )
DOUBLE PRECISION   HALF
PARAMETER          ( HALF = 0.5D0 )
!     ..
!     .. Local Scalars ..
DOUBLE PRECISION   AB, ACMN, ACMX, ADF, DF, RT, SM, TB
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, SQRT
!     ..
!     .. Executable Statements ..
!
!     Compute the eigenvalues
!
SM = A + C
DF = A - C
ADF = ABS( DF )
TB = B + B
AB = ABS( TB )
IF( ABS( A ).GT.ABS( C ) ) THEN
   ACMX = A
   ACMN = C
ELSE
   ACMX = C
   ACMN = A
END IF
IF( ADF.GT.AB ) THEN
   RT = ADF*SQRT( ONE+( AB / ADF )**2 )
ELSE IF( ADF.LT.AB ) THEN
   RT = AB*SQRT( ONE+( ADF / AB )**2 )
ELSE
!
!        Includes case AB=ADF=0
!
   RT = AB*SQRT( TWO )
END IF
IF( SM.LT.ZERO ) THEN
   RT1 = HALF*( SM-RT )
!
!        Order of execution important.
!        To get fully accurate smaller eigenvalue,
!        next line needs to be executed in higher precision.
!
   RT2 = ( ACMX / RT1 )*ACMN - ( B / RT1 )*B
ELSE IF( SM.GT.ZERO ) THEN
   RT1 = HALF*( SM+RT )
!
!        Order of execution important.
!        To get fully accurate smaller eigenvalue,
!        next line needs to be executed in higher precision.
!
   RT2 = ( ACMX / RT1 )*ACMN - ( B / RT1 )*B
ELSE
!
!        Includes case RT1 = RT2 = 0
!
   RT1 = HALF*RT
   RT2 = -HALF*RT
END IF
RETURN
!
!     End of DLAE2
!
end subroutine dlae2

! ===== End dlae2.f90 =====


! ===== Begin dlaebz.f90 =====

SUBROUTINE DLAEBZ( IJOB, NITMAX, N, MMAX, MINP, NBMIN, ABSTOL, &
                       RELTOL, PIVMIN, D, E, E2, NVAL, AB, C, MOUT, &
                       NAB, WORK, IWORK, INFO )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            IJOB, INFO, MINP, MMAX, MOUT, N, NBMIN, NITMAX
DOUBLE PRECISION   ABSTOL, PIVMIN, RELTOL
!     ..
!     .. Array Arguments ..
INTEGER            IWORK( * ), NAB( MMAX, * ), NVAL( * )
DOUBLE PRECISION   AB( MMAX, * ), C( * ), D( * ), E( * ), E2( * ), &
                       WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DLAEBZ contains the iteration loops which compute and use the
!  function N(w), which is the count of eigenvalues of a symmetric
!  tridiagonal matrix T less than or equal to its argument  w.  It
!  performs a choice of two types of loops:
!
!  IJOB=1, followed by
!  IJOB=2: It takes as input a list of intervals and returns a list of
!          sufficiently small intervals whose union contains the same
!          eigenvalues as the union of the original intervals.
!          The input intervals are (AB(j,1),AB(j,2)], j=1,...,MINP.
!          The output interval (AB(j,1),AB(j,2)] will contain
!          eigenvalues NAB(j,1)+1,...,NAB(j,2), where 1 <= j <= MOUT.
!
!  IJOB=3: It performs a binary search in each input interval
!          (AB(j,1),AB(j,2)] for a point  w(j)  such that
!          N(w(j))=NVAL(j), and uses  C(j)  as the starting point of
!          the search.  If such a w(j) is found, then on output
!          AB(j,1)=AB(j,2)=w.  If no such w(j) is found, then on output
!          (AB(j,1),AB(j,2)] will be a small interval containing the
!          point where N(w) jumps through NVAL(j), unless that point
!          lies outside the initial interval.
!
!  Note that the intervals are in all cases half-open intervals,
!  i.e., of the form  (a,b] , which includes  b  but not  a .
!
!  To avoid underflow, the matrix should be scaled so that its largest
!  element is no greater than  overflow**(1/2) * underflow**(1/4)
!  in absolute value.  To assure the most accurate computation
!  of small eigenvalues, the matrix should be scaled to be
!  not much smaller than that, either.
!
!  See W. Kahan "Accurate Eigenvalues of a Symmetric Tridiagonal
!  Matrix", Report CS41, Computer Science Dept., Stanford
!  University, July 21, 1966
!
!  Note: the arguments are, in general, *not* checked for unreasonable
!  values.
!
!  Arguments
!  =========
!
!  IJOB    (input) INTEGER
!          Specifies what is to be done:
!          = 1:  Compute NAB for the initial intervals.
!          = 2:  Perform bisection iteration to find eigenvalues of T.
!          = 3:  Perform bisection iteration to invert N(w), i.e.,
!                to find a point which has a specified number of
!                eigenvalues of T to its left.
!          Other values will cause DLAEBZ to return with INFO=-1.
!
!  NITMAX  (input) INTEGER
!          The maximum number of "levels" of bisection to be
!          performed, i.e., an interval of width W will not be made
!          smaller than 2^(-NITMAX) * W.  If not all intervals
!          have converged after NITMAX iterations, then INFO is set
!          to the number of non-converged intervals.
!
!  N       (input) INTEGER
!          The dimension n of the tridiagonal matrix T.  It must be at
!          least 1.
!
!  MMAX    (input) INTEGER
!          The maximum number of intervals.  If more than MMAX intervals
!          are generated, then DLAEBZ will quit with INFO=MMAX+1.
!
!  MINP    (input) INTEGER
!          The initial number of intervals.  It may not be greater than
!          MMAX.
!
!  NBMIN   (input) INTEGER
!          The smallest number of intervals that should be processed
!          using a vector loop.  If zero, then only the scalar loop
!          will be used.
!
!  ABSTOL  (input) DOUBLE PRECISION
!          The minimum (absolute) width of an interval.  When an
!          interval is narrower than ABSTOL, or than RELTOL times the
!          larger (in magnitude) endpoint, then it is considered to be
!          sufficiently small, i.e., converged.  This must be at least
!          zero.
!
!  RELTOL  (input) DOUBLE PRECISION
!          The minimum relative width of an interval.  When an interval
!          is narrower than ABSTOL, or than RELTOL times the larger (in
!          magnitude) endpoint, then it is considered to be
!          sufficiently small, i.e., converged.  Note: this should
!          always be at least radix*machine epsilon.
!
!  PIVMIN  (input) DOUBLE PRECISION
!          The minimum absolute value of a "pivot" in the Sturm
!          sequence loop.  This *must* be at least  max |e(j)**2| *
!          safe_min  and at least safe_min, where safe_min is at least
!          the smallest number that can divide one without overflow.
!
!  D       (input) DOUBLE PRECISION array, dimension (N)
!          The diagonal elements of the tridiagonal matrix T.
!
!  E       (input) DOUBLE PRECISION array, dimension (N)
!          The offdiagonal elements of the tridiagonal matrix T in
!          positions 1 through N-1.  E(N) is arbitrary.
!
!  E2      (input) DOUBLE PRECISION array, dimension (N)
!          The squares of the offdiagonal elements of the tridiagonal
!          matrix T.  E2(N) is ignored.
!
!  NVAL    (input/output) INTEGER array, dimension (MINP)
!          If IJOB=1 or 2, not referenced.
!          If IJOB=3, the desired values of N(w).  The elements of NVAL
!          will be reordered to correspond with the intervals in AB.
!          Thus, NVAL(j) on output will not, in general be the same as
!          NVAL(j) on input, but it will correspond with the interval
!          (AB(j,1),AB(j,2)] on output.
!
!  AB      (input/output) DOUBLE PRECISION array, dimension (MMAX,2)
!          The endpoints of the intervals.  AB(j,1) is  a(j), the left
!          endpoint of the j-th interval, and AB(j,2) is b(j), the
!          right endpoint of the j-th interval.  The input intervals
!          will, in general, be modified, split, and reordered by the
!          calculation.
!
!  C       (input/output) DOUBLE PRECISION array, dimension (MMAX)
!          If IJOB=1, ignored.
!          If IJOB=2, workspace.
!          If IJOB=3, then on input C(j) should be initialized to the
!          first search point in the binary search.
!
!  MOUT    (output) INTEGER
!          If IJOB=1, the number of eigenvalues in the intervals.
!          If IJOB=2 or 3, the number of intervals output.
!          If IJOB=3, MOUT will equal MINP.
!
!  NAB     (input/output) INTEGER array, dimension (MMAX,2)
!          If IJOB=1, then on output NAB(i,j) will be set to N(AB(i,j)).
!          If IJOB=2, then on input, NAB(i,j) should be set.  It must
!             satisfy the condition:
!             N(AB(i,1)) <= NAB(i,1) <= NAB(i,2) <= N(AB(i,2)),
!             which means that in interval i only eigenvalues
!             NAB(i,1)+1,...,NAB(i,2) will be considered.  Usually,
!             NAB(i,j)=N(AB(i,j)), from a previous call to DLAEBZ with
!             IJOB=1.
!             On output, NAB(i,j) will contain
!             max(na(k),min(nb(k),N(AB(i,j)))), where k is the index of
!             the input interval that the output interval
!             (AB(j,1),AB(j,2)] came from, and na(k) and nb(k) are the
!             the input values of NAB(k,1) and NAB(k,2).
!          If IJOB=3, then on output, NAB(i,j) contains N(AB(i,j)),
!             unless N(w) > NVAL(i) for all search points  w , in which
!             case NAB(i,1) will not be modified, i.e., the output
!             value will be the same as the input value (modulo
!             reorderings -- see NVAL and AB), or unless N(w) < NVAL(i)
!             for all search points  w , in which case NAB(i,2) will
!             not be modified.  Normally, NAB should be set to some
!             distinctive value(s) before DLAEBZ is called.
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (MMAX)
!          Workspace.
!
!  IWORK   (workspace) INTEGER array, dimension (MMAX)
!          Workspace.
!
!  INFO    (output) INTEGER
!          = 0:       All intervals converged.
!          = 1--MMAX: The last INFO intervals did not converge.
!          = MMAX+1:  More than MMAX intervals were generated.
!
!  Further Details
!  ===============
!
!      This routine is intended to be called only by other LAPACK
!  routines, thus the interface is less user-friendly.  It is intended
!  for two purposes:
!
!  (a) finding eigenvalues.  In this case, DLAEBZ should have one or
!      more initial intervals set up in AB, and DLAEBZ should be called
!      with IJOB=1.  This sets up NAB, and also counts the eigenvalues.
!      Intervals with no eigenvalues would usually be thrown out at
!      this point.  Also, if not all the eigenvalues in an interval i
!      are desired, NAB(i,1) can be increased or NAB(i,2) decreased.
!      For example, set NAB(i,1)=NAB(i,2)-1 to get the largest
!      eigenvalue.  DLAEBZ is then called with IJOB=2 and MMAX
!      no smaller than the value of MOUT returned by the call with
!      IJOB=1.  After this (IJOB=2) call, eigenvalues NAB(i,1)+1
!      through NAB(i,2) are approximately AB(i,1) (or AB(i,2)) to the
!      tolerance specified by ABSTOL and RELTOL.
!
!  (b) finding an interval (a',b'] containing eigenvalues w(f),...,w(l).
!      In this case, start with a Gershgorin interval  (a,b).  Set up
!      AB to contain 2 search intervals, both initially (a,b).  One
!      NVAL element should contain  f-1  and the other should contain  l
!      , while C should contain a and b, resp.  NAB(i,1) should be -1
!      and NAB(i,2) should be N+1, to flag an error if the desired
!      interval does not lie in (a,b).  DLAEBZ is then called with
!      IJOB=3.  On exit, if w(f-1) < w(f), then one of the intervals --
!      j -- will have AB(j,1)=AB(j,2) and NAB(j,1)=NAB(j,2)=f-1, while
!      if, to the specified tolerance, w(f-k)=...=w(f+r), k > 0 and r
!      >= 0, then the interval will have  N(AB(j,1))=NAB(j,1)=f-k and
!      N(AB(j,2))=NAB(j,2)=f+r.  The cases w(l) < w(l+1) and
!      w(l-r)=...=w(l+k) are handled similarly.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, TWO, HALF
PARAMETER          ( ZERO = 0.0D0, TWO = 2.0D0, &
                       HALF = 1.0D0 / TWO )
!     ..
!     .. Local Scalars ..
INTEGER            ITMP1, ITMP2, J, JI, JIT, JP, KF, KFNEW, KL, &
                       KLNEW
DOUBLE PRECISION   TMP1, TMP2
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Check for Errors
!
INFO = 0
IF( IJOB.LT.1 .OR. IJOB.GT.3 ) THEN
   INFO = -1
   RETURN
END IF
!
!     Initialize NAB
!
IF( IJOB.EQ.1 ) THEN
!
!        Compute the number of eigenvalues in the initial intervals.
!
   MOUT = 0
!DIR$ NOVECTOR
   DO 30 JI = 1, MINP
      DO 20 JP = 1, 2
         TMP1 = D( 1 ) - AB( JI, JP )
         IF( ABS( TMP1 ).LT.PIVMIN ) &
                TMP1 = -PIVMIN
         NAB( JI, JP ) = 0
         IF( TMP1.LE.ZERO ) &
                NAB( JI, JP ) = 1
!
         DO 10 J = 2, N
            TMP1 = D( J ) - E2( J-1 ) / TMP1 - AB( JI, JP )
            IF( ABS( TMP1 ).LT.PIVMIN ) &
                   TMP1 = -PIVMIN
            IF( TMP1.LE.ZERO ) &
                   NAB( JI, JP ) = NAB( JI, JP ) + 1
10          CONTINUE
20       CONTINUE
      MOUT = MOUT + NAB( JI, 2 ) - NAB( JI, 1 )
30    CONTINUE
   RETURN
END IF
!
!     Initialize for loop
!
!     KF and KL have the following meaning:
!        Intervals 1,...,KF-1 have converged.
!        Intervals KF,...,KL  still need to be refined.
!
KF = 1
KL = MINP
!
!     If IJOB=2, initialize C.
!     If IJOB=3, use the user-supplied starting point.
!
IF( IJOB.EQ.2 ) THEN
   DO 40 JI = 1, MINP
      C( JI ) = HALF*( AB( JI, 1 )+AB( JI, 2 ) )
40    CONTINUE
END IF
!
!     Iteration loop
!
DO 130 JIT = 1, NITMAX
!
!        Loop over intervals
!
   IF( KL-KF+1.GE.NBMIN .AND. NBMIN.GT.0 ) THEN
!
!           Begin of Parallel Version of the loop
!
      DO 60 JI = KF, KL
!
!              Compute N(c), the number of eigenvalues less than c
!
         WORK( JI ) = D( 1 ) - C( JI )
         IWORK( JI ) = 0
         IF( WORK( JI ).LE.PIVMIN ) THEN
            IWORK( JI ) = 1
            WORK( JI ) = MIN( WORK( JI ), -PIVMIN )
         END IF
!
         DO 50 J = 2, N
            WORK( JI ) = D( J ) - E2( J-1 ) / WORK( JI ) - C( JI )
            IF( WORK( JI ).LE.PIVMIN ) THEN
               IWORK( JI ) = IWORK( JI ) + 1
               WORK( JI ) = MIN( WORK( JI ), -PIVMIN )
            END IF
50          CONTINUE
60       CONTINUE
!
      IF( IJOB.LE.2 ) THEN
!
!              IJOB=2: Choose all intervals containing eigenvalues.
!
         KLNEW = KL
         DO 70 JI = KF, KL
!
!                 Insure that N(w) is monotone
!
            IWORK( JI ) = MIN( NAB( JI, 2 ), &
                              MAX( NAB( JI, 1 ), IWORK( JI ) ) )
!
!                 Update the Queue -- add intervals if both halves
!                 contain eigenvalues.
!
            IF( IWORK( JI ).EQ.NAB( JI, 2 ) ) THEN
!
!                    No eigenvalue in the upper interval:
!                    just use the lower interval.
!
               AB( JI, 2 ) = C( JI )
!
            ELSE IF( IWORK( JI ).EQ.NAB( JI, 1 ) ) THEN
!
!                    No eigenvalue in the lower interval:
!                    just use the upper interval.
!
               AB( JI, 1 ) = C( JI )
            ELSE
               KLNEW = KLNEW + 1
               IF( KLNEW.LE.MMAX ) THEN
!
!                       Eigenvalue in both intervals -- add upper to
!                       queue.
!
                  AB( KLNEW, 2 ) = AB( JI, 2 )
                  NAB( KLNEW, 2 ) = NAB( JI, 2 )
                  AB( KLNEW, 1 ) = C( JI )
                  NAB( KLNEW, 1 ) = IWORK( JI )
                  AB( JI, 2 ) = C( JI )
                  NAB( JI, 2 ) = IWORK( JI )
               ELSE
                  INFO = MMAX + 1
               END IF
            END IF
70          CONTINUE
         IF( INFO.NE.0 ) &
                RETURN
         KL = KLNEW
      ELSE
!
!              IJOB=3: Binary search.  Keep only the interval containing
!                      w   s.t. N(w) = NVAL
!
         DO 80 JI = KF, KL
            IF( IWORK( JI ).LE.NVAL( JI ) ) THEN
               AB( JI, 1 ) = C( JI )
               NAB( JI, 1 ) = IWORK( JI )
            END IF
            IF( IWORK( JI ).GE.NVAL( JI ) ) THEN
               AB( JI, 2 ) = C( JI )
               NAB( JI, 2 ) = IWORK( JI )
            END IF
80          CONTINUE
      END IF
!
   ELSE
!
!           End of Parallel Version of the loop
!
!           Begin of Serial Version of the loop
!
      KLNEW = KL
      DO 100 JI = KF, KL
!
!              Compute N(w), the number of eigenvalues less than w
!
         TMP1 = C( JI )
         TMP2 = D( 1 ) - TMP1
         ITMP1 = 0
         IF( TMP2.LE.PIVMIN ) THEN
            ITMP1 = 1
            TMP2 = MIN( TMP2, -PIVMIN )
         END IF
!!
!!              A series of compiler directives to defeat vectorization
!!              for the next loop
!!
!!$PL$ CMCHAR=' '
!!DIR$          NEXTSCALAR
!!$DIR          SCALAR
!!DIR$          NEXT SCALAR
!!VD$L          NOVECTOR
!!DEC$          NOVECTOR
!!VD$           NOVECTOR
!!VDIR          NOVECTOR
!!VOCL          LOOP,SCALAR
!!IBM           PREFER SCALAR
!!$PL$ CMCHAR='*'
!!
         DO 90 J = 2, N
            TMP2 = D( J ) - E2( J-1 ) / TMP2 - TMP1
            IF( TMP2.LE.PIVMIN ) THEN
               ITMP1 = ITMP1 + 1
               TMP2 = MIN( TMP2, -PIVMIN )
            END IF
90          CONTINUE
!
         IF( IJOB.LE.2 ) THEN
!
!                 IJOB=2: Choose all intervals containing eigenvalues.
!
!                 Insure that N(w) is monotone
!
            ITMP1 = MIN( NAB( JI, 2 ), &
                        MAX( NAB( JI, 1 ), ITMP1 ) )
!
!                 Update the Queue -- add intervals if both halves
!                 contain eigenvalues.
!
            IF( ITMP1.EQ.NAB( JI, 2 ) ) THEN
!
!                    No eigenvalue in the upper interval:
!                    just use the lower interval.
!
               AB( JI, 2 ) = TMP1
!
            ELSE IF( ITMP1.EQ.NAB( JI, 1 ) ) THEN
!
!                    No eigenvalue in the lower interval:
!                    just use the upper interval.
!
               AB( JI, 1 ) = TMP1
            ELSE IF( KLNEW.LT.MMAX ) THEN
!
!                    Eigenvalue in both intervals -- add upper to queue.
!
               KLNEW = KLNEW + 1
               AB( KLNEW, 2 ) = AB( JI, 2 )
               NAB( KLNEW, 2 ) = NAB( JI, 2 )
               AB( KLNEW, 1 ) = TMP1
               NAB( KLNEW, 1 ) = ITMP1
               AB( JI, 2 ) = TMP1
               NAB( JI, 2 ) = ITMP1
            ELSE
               INFO = MMAX + 1
               RETURN
            END IF
         ELSE
!
!                 IJOB=3: Binary search.  Keep only the interval
!                         containing  w  s.t. N(w) = NVAL
!
            IF( ITMP1.LE.NVAL( JI ) ) THEN
               AB( JI, 1 ) = TMP1
               NAB( JI, 1 ) = ITMP1
            END IF
            IF( ITMP1.GE.NVAL( JI ) ) THEN
               AB( JI, 2 ) = TMP1
               NAB( JI, 2 ) = ITMP1
            END IF
         END IF
100       CONTINUE
      KL = KLNEW
!
!           End of Serial Version of the loop
!
   END IF
!
!        Check for convergence
!
   KFNEW = KF
   DO 110 JI = KF, KL
      TMP1 = ABS( AB( JI, 2 )-AB( JI, 1 ) )
      TMP2 = MAX( ABS( AB( JI, 2 ) ), ABS( AB( JI, 1 ) ) )
      IF( TMP1.LT.MAX( ABSTOL, PIVMIN, RELTOL*TMP2 ) .OR. &
              NAB( JI, 1 ).GE.NAB( JI, 2 ) ) THEN
!
!              Converged -- Swap with position KFNEW,
!                           then increment KFNEW
!
         IF( JI.GT.KFNEW ) THEN
            TMP1 = AB( JI, 1 )
            TMP2 = AB( JI, 2 )
            ITMP1 = NAB( JI, 1 )
            ITMP2 = NAB( JI, 2 )
            AB( JI, 1 ) = AB( KFNEW, 1 )
            AB( JI, 2 ) = AB( KFNEW, 2 )
            NAB( JI, 1 ) = NAB( KFNEW, 1 )
            NAB( JI, 2 ) = NAB( KFNEW, 2 )
            AB( KFNEW, 1 ) = TMP1
            AB( KFNEW, 2 ) = TMP2
            NAB( KFNEW, 1 ) = ITMP1
            NAB( KFNEW, 2 ) = ITMP2
            IF( IJOB.EQ.3 ) THEN
               ITMP1 = NVAL( JI )
               NVAL( JI ) = NVAL( KFNEW )
               NVAL( KFNEW ) = ITMP1
            END IF
         END IF
         KFNEW = KFNEW + 1
      END IF
110    CONTINUE
   KF = KFNEW
!
!        Choose Midpoints
!
   DO 120 JI = KF, KL
      C( JI ) = HALF*( AB( JI, 1 )+AB( JI, 2 ) )
120    CONTINUE
!
!        If no more intervals to refine, quit.
!
   IF( KF.GT.KL ) &
          GO TO 140
130 CONTINUE
!
!     Converged
!
140 CONTINUE
INFO = MAX( KL+1-KF, 0 )
MOUT = KL
!
RETURN
!
!     End of DLAEBZ
!
end subroutine dlaebz

! ===== End dlaebz.f90 =====


! ===== Begin dlaev2.f90 =====

SUBROUTINE DLAEV2( A, B, C, RT1, RT2, CS1, SN1 )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   A, B, C, CS1, RT1, RT2, SN1
!     ..
!
!  Purpose
!  =======
!
!  DLAEV2 computes the eigendecomposition of a 2-by-2 symmetric matrix
!     [  A   B  ]
!     [  B   C  ].
!  On return, RT1 is the eigenvalue of larger absolute value, RT2 is the
!  eigenvalue of smaller absolute value, and (CS1,SN1) is the unit right
!  eigenvector for RT1, giving the decomposition
!
!     [ CS1  SN1 ] [  A   B  ] [ CS1 -SN1 ]  =  [ RT1  0  ]
!     [-SN1  CS1 ] [  B   C  ] [ SN1  CS1 ]     [  0  RT2 ].
!
!  Arguments
!  =========
!
!  A       (input) DOUBLE PRECISION
!          The (1,1) element of the 2-by-2 matrix.
!
!  B       (input) DOUBLE PRECISION
!          The (1,2) element and the conjugate of the (2,1) element of
!          the 2-by-2 matrix.
!
!  C       (input) DOUBLE PRECISION
!          The (2,2) element of the 2-by-2 matrix.
!
!  RT1     (output) DOUBLE PRECISION
!          The eigenvalue of larger absolute value.
!
!  RT2     (output) DOUBLE PRECISION
!          The eigenvalue of smaller absolute value.
!
!  CS1     (output) DOUBLE PRECISION
!  SN1     (output) DOUBLE PRECISION
!          The vector (CS1, SN1) is a unit right eigenvector for RT1.
!
!  Further Details
!  ===============
!
!  RT1 is accurate to a few ulps barring over/underflow.
!
!  RT2 may be inaccurate if there is massive cancellation in the
!  determinant A*C-B*B; higher precision or correctly rounded or
!  correctly truncated arithmetic would be needed to compute RT2
!  accurately in all cases.
!
!  CS1 and SN1 are accurate to a few ulps barring over/underflow.
!
!  Overflow is possible only if RT1 is within a factor of 5 of overflow.
!  Underflow is harmless if the input data is 0 or exceeds
!     underflow_threshold / macheps.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D0 )
DOUBLE PRECISION   TWO
PARAMETER          ( TWO = 2.0D0 )
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D0 )
DOUBLE PRECISION   HALF
PARAMETER          ( HALF = 0.5D0 )
!     ..
!     .. Local Scalars ..
INTEGER            SGN1, SGN2
DOUBLE PRECISION   AB, ACMN, ACMX, ACS, ADF, CS, CT, DF, RT, SM, &
                       TB, TN
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, SQRT
!     ..
!     .. Executable Statements ..
!
!     Compute the eigenvalues
!
SM = A + C
DF = A - C
ADF = ABS( DF )
TB = B + B
AB = ABS( TB )
IF( ABS( A ).GT.ABS( C ) ) THEN
   ACMX = A
   ACMN = C
ELSE
   ACMX = C
   ACMN = A
END IF
IF( ADF.GT.AB ) THEN
   RT = ADF*SQRT( ONE+( AB / ADF )**2 )
ELSE IF( ADF.LT.AB ) THEN
   RT = AB*SQRT( ONE+( ADF / AB )**2 )
ELSE
!
!        Includes case AB=ADF=0
!
   RT = AB*SQRT( TWO )
END IF
IF( SM.LT.ZERO ) THEN
   RT1 = HALF*( SM-RT )
   SGN1 = -1
!
!        Order of execution important.
!        To get fully accurate smaller eigenvalue,
!        next line needs to be executed in higher precision.
!
   RT2 = ( ACMX / RT1 )*ACMN - ( B / RT1 )*B
ELSE IF( SM.GT.ZERO ) THEN
   RT1 = HALF*( SM+RT )
   SGN1 = 1
!
!        Order of execution important.
!        To get fully accurate smaller eigenvalue,
!        next line needs to be executed in higher precision.
!
   RT2 = ( ACMX / RT1 )*ACMN - ( B / RT1 )*B
ELSE
!
!        Includes case RT1 = RT2 = 0
!
   RT1 = HALF*RT
   RT2 = -HALF*RT
   SGN1 = 1
END IF
!
!     Compute the eigenvector
!
IF( DF.GE.ZERO ) THEN
   CS = DF + RT
   SGN2 = 1
ELSE
   CS = DF - RT
   SGN2 = -1
END IF
ACS = ABS( CS )
IF( ACS.GT.AB ) THEN
   CT = -TB / CS
   SN1 = ONE / SQRT( ONE+CT*CT )
   CS1 = CT*SN1
ELSE
   IF( AB.EQ.ZERO ) THEN
      CS1 = ONE
      SN1 = ZERO
   ELSE
      TN = -CS / TB
      CS1 = ONE / SQRT( ONE+TN*TN )
      SN1 = TN*CS1
   END IF
END IF
IF( SGN1.EQ.SGN2 ) THEN
   TN = CS1
   CS1 = -SN1
   SN1 = TN
END IF
RETURN
!
!     End of DLAEV2
!
end subroutine dlaev2

! ===== End dlaev2.f90 =====


! ===== Begin dlaexc.f90 =====

SUBROUTINE DLAEXC( WANTQ, N, T, LDT, Q, LDQ, J1, N1, N2, WORK, &
                       INFO )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
LOGICAL            WANTQ
INTEGER            INFO, J1, LDQ, LDT, N, N1, N2
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   Q( LDQ, * ), T( LDT, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DLAEXC swaps adjacent diagonal blocks T11 and T22 of order 1 or 2 in
!  an upper quasi-triangular matrix T by an orthogonal similarity
!  transformation.
!
!  T must be in Schur canonical form, that is, block upper triangular
!  with 1-by-1 and 2-by-2 diagonal blocks; each 2-by-2 diagonal block
!  has its diagonal elemnts equal and its off-diagonal elements of
!  opposite sign.
!
!  Arguments
!  =========
!
!  WANTQ   (input) LOGICAL
!          = .TRUE. : accumulate the transformation in the matrix Q;
!          = .FALSE.: do not accumulate the transformation.
!
!  N       (input) INTEGER
!          The order of the matrix T. N >= 0.
!
!  T       (input/output) DOUBLE PRECISION array, dimension (LDT,N)
!          On entry, the upper quasi-triangular matrix T, in Schur
!          canonical form.
!          On exit, the updated matrix T, again in Schur canonical form.
!
!  LDT     (input)  INTEGER
!          The leading dimension of the array T. LDT >= max(1,N).
!
!  Q       (input/output) DOUBLE PRECISION array, dimension (LDQ,N)
!          On entry, if WANTQ is .TRUE., the orthogonal matrix Q.
!          On exit, if WANTQ is .TRUE., the updated matrix Q.
!          If WANTQ is .FALSE., Q is not referenced.
!
!  LDQ     (input) INTEGER
!          The leading dimension of the array Q.
!          LDQ >= 1; and if WANTQ is .TRUE., LDQ >= N.
!
!  J1      (input) INTEGER
!          The index of the first row of the first block T11.
!
!  N1      (input) INTEGER
!          The order of the first block T11. N1 = 0, 1 or 2.
!
!  N2      (input) INTEGER
!          The order of the second block T22. N2 = 0, 1 or 2.
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (N)
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          = 1: the transformed matrix T would be too far from Schur
!               form; the blocks are not swapped and T and Q are
!               unchanged.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
DOUBLE PRECISION   TEN
PARAMETER          ( TEN = 1.0D+1 )
INTEGER            LDD, LDX
PARAMETER          ( LDD = 4, LDX = 2 )
!     ..
!     .. Local Scalars ..
INTEGER            IERR, J2, J3, J4, K, ND
DOUBLE PRECISION   CS, DNORM, EPS, SCALE, SMLNUM, SN, T11, T22, &
                       T33, TAU, TAU1, TAU2, TEMP, THRESH, WI1, WI2, &
                       WR1, WR2, XNORM
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   D( LDD, 4 ), U( 3 ), U1( 3 ), U2( 3 ), &
                       X( LDX, 2 )
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMCH, DLANGE
EXTERNAL           DLAMCH, DLANGE
!     ..
!     .. External Subroutines ..
EXTERNAL           DLACPY, DLANV2, DLARFG, DLARFX, DLARTG, DLASY2, &
                       DROT
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX
!     ..
!     .. Executable Statements ..
!
INFO = 0
!
!     Quick return if possible
!
IF( N.EQ.0 .OR. N1.EQ.0 .OR. N2.EQ.0 ) &
       RETURN
IF( J1+N1.GT.N ) &
       RETURN
!
J2 = J1 + 1
J3 = J1 + 2
J4 = J1 + 3
!
IF( N1.EQ.1 .AND. N2.EQ.1 ) THEN
!
!        Swap two 1-by-1 blocks.
!
   T11 = T( J1, J1 )
   T22 = T( J2, J2 )
!
!        Determine the transformation to perform the interchange.
!
   CALL DLARTG( T( J1, J2 ), T22-T11, CS, SN, TEMP )
!
!        Apply transformation to the matrix T.
!
   IF( J3.LE.N ) &
          CALL DROT( N-J1-1, T( J1, J3 ), LDT, T( J2, J3 ), LDT, CS, &
                     SN )
   CALL DROT( J1-1, T( 1, J1 ), 1, T( 1, J2 ), 1, CS, SN )
!
   T( J1, J1 ) = T22
   T( J2, J2 ) = T11
!
   IF( WANTQ ) THEN
!
!           Accumulate transformation in the matrix Q.
!
      CALL DROT( N, Q( 1, J1 ), 1, Q( 1, J2 ), 1, CS, SN )
   END IF
!
ELSE
!
!        Swapping involves at least one 2-by-2 block.
!
!        Copy the diagonal block of order N1+N2 to the local array D
!        and compute its norm.
!
   ND = N1 + N2
   CALL DLACPY( 'Full', ND, ND, T( J1, J1 ), LDT, D, LDD )
   DNORM = DLANGE( 'Max', ND, ND, D, LDD, WORK )
!
!        Compute machine-dependent threshold for test for accepting
!        swap.
!
   EPS = DLAMCH( 'P' )
   SMLNUM = DLAMCH( 'S' ) / EPS
   THRESH = MAX( TEN*EPS*DNORM, SMLNUM )
!
!        Solve T11*X - X*T22 = scale*T12 for X.
!
   CALL DLASY2( .FALSE., .FALSE., -1, N1, N2, D, LDD, &
                    D( N1+1, N1+1 ), LDD, D( 1, N1+1 ), LDD, SCALE, X, &
                    LDX, XNORM, IERR )
!
!        Swap the adjacent diagonal blocks.
!
   K = N1 + N1 + N2 - 3
   GO TO ( 10, 20, 30 )K
!
10    CONTINUE
!
!        N1 = 1, N2 = 2: generate elementary reflector H so that:
!
!        ( scale, X11, X12 ) H = ( 0, 0, * )
!
   U( 1 ) = SCALE
   U( 2 ) = X( 1, 1 )
   U( 3 ) = X( 1, 2 )
   CALL DLARFG( 3, U( 3 ), U, 1, TAU )
   U( 3 ) = ONE
   T11 = T( J1, J1 )
!
!        Perform swap provisionally on diagonal block in D.
!
   CALL DLARFX( 'L', 3, 3, U, TAU, D, LDD, WORK )
   CALL DLARFX( 'R', 3, 3, U, TAU, D, LDD, WORK )
!
!        Test whether to reject swap.
!
   IF( MAX( ABS( D( 3, 1 ) ), ABS( D( 3, 2 ) ), ABS( D( 3, &
           3 )-T11 ) ).GT.THRESH )GO TO 50
!
!        Accept swap: apply transformation to the entire matrix T.
!
   CALL DLARFX( 'L', 3, N-J1+1, U, TAU, T( J1, J1 ), LDT, WORK )
   CALL DLARFX( 'R', J2, 3, U, TAU, T( 1, J1 ), LDT, WORK )
!
   T( J3, J1 ) = ZERO
   T( J3, J2 ) = ZERO
   T( J3, J3 ) = T11
!
   IF( WANTQ ) THEN
!
!           Accumulate transformation in the matrix Q.
!
      CALL DLARFX( 'R', N, 3, U, TAU, Q( 1, J1 ), LDQ, WORK )
   END IF
   GO TO 40
!
20    CONTINUE
!
!        N1 = 2, N2 = 1: generate elementary reflector H so that:
!
!        H (  -X11 ) = ( * )
!          (  -X21 ) = ( 0 )
!          ( scale ) = ( 0 )
!
   U( 1 ) = -X( 1, 1 )
   U( 2 ) = -X( 2, 1 )
   U( 3 ) = SCALE
   CALL DLARFG( 3, U( 1 ), U( 2 ), 1, TAU )
   U( 1 ) = ONE
   T33 = T( J3, J3 )
!
!        Perform swap provisionally on diagonal block in D.
!
   CALL DLARFX( 'L', 3, 3, U, TAU, D, LDD, WORK )
   CALL DLARFX( 'R', 3, 3, U, TAU, D, LDD, WORK )
!
!        Test whether to reject swap.
!
   IF( MAX( ABS( D( 2, 1 ) ), ABS( D( 3, 1 ) ), ABS( D( 1, &
           1 )-T33 ) ).GT.THRESH )GO TO 50
!
!        Accept swap: apply transformation to the entire matrix T.
!
   CALL DLARFX( 'R', J3, 3, U, TAU, T( 1, J1 ), LDT, WORK )
   CALL DLARFX( 'L', 3, N-J1, U, TAU, T( J1, J2 ), LDT, WORK )
!
   T( J1, J1 ) = T33
   T( J2, J1 ) = ZERO
   T( J3, J1 ) = ZERO
!
   IF( WANTQ ) THEN
!
!           Accumulate transformation in the matrix Q.
!
      CALL DLARFX( 'R', N, 3, U, TAU, Q( 1, J1 ), LDQ, WORK )
   END IF
   GO TO 40
!
30    CONTINUE
!
!        N1 = 2, N2 = 2: generate elementary reflectors H(1) and H(2) so
!        that:
!
!        H(2) H(1) (  -X11  -X12 ) = (  *  * )
!                  (  -X21  -X22 )   (  0  * )
!                  ( scale    0  )   (  0  0 )
!                  (    0  scale )   (  0  0 )
!
   U1( 1 ) = -X( 1, 1 )
   U1( 2 ) = -X( 2, 1 )
   U1( 3 ) = SCALE
   CALL DLARFG( 3, U1( 1 ), U1( 2 ), 1, TAU1 )
   U1( 1 ) = ONE
!
   TEMP = -TAU1*( X( 1, 2 )+U1( 2 )*X( 2, 2 ) )
   U2( 1 ) = -TEMP*U1( 2 ) - X( 2, 2 )
   U2( 2 ) = -TEMP*U1( 3 )
   U2( 3 ) = SCALE
   CALL DLARFG( 3, U2( 1 ), U2( 2 ), 1, TAU2 )
   U2( 1 ) = ONE
!
!        Perform swap provisionally on diagonal block in D.
!
   CALL DLARFX( 'L', 3, 4, U1, TAU1, D, LDD, WORK )
   CALL DLARFX( 'R', 4, 3, U1, TAU1, D, LDD, WORK )
   CALL DLARFX( 'L', 3, 4, U2, TAU2, D( 2, 1 ), LDD, WORK )
   CALL DLARFX( 'R', 4, 3, U2, TAU2, D( 1, 2 ), LDD, WORK )
!
!        Test whether to reject swap.
!
   IF( MAX( ABS( D( 3, 1 ) ), ABS( D( 3, 2 ) ), ABS( D( 4, 1 ) ), &
           ABS( D( 4, 2 ) ) ).GT.THRESH )GO TO 50
!
!        Accept swap: apply transformation to the entire matrix T.
!
   CALL DLARFX( 'L', 3, N-J1+1, U1, TAU1, T( J1, J1 ), LDT, WORK )
   CALL DLARFX( 'R', J4, 3, U1, TAU1, T( 1, J1 ), LDT, WORK )
   CALL DLARFX( 'L', 3, N-J1+1, U2, TAU2, T( J2, J1 ), LDT, WORK )
   CALL DLARFX( 'R', J4, 3, U2, TAU2, T( 1, J2 ), LDT, WORK )
!
   T( J3, J1 ) = ZERO
   T( J3, J2 ) = ZERO
   T( J4, J1 ) = ZERO
   T( J4, J2 ) = ZERO
!
   IF( WANTQ ) THEN
!
!           Accumulate transformation in the matrix Q.
!
      CALL DLARFX( 'R', N, 3, U1, TAU1, Q( 1, J1 ), LDQ, WORK )
      CALL DLARFX( 'R', N, 3, U2, TAU2, Q( 1, J2 ), LDQ, WORK )
   END IF
!
40    CONTINUE
!
   IF( N2.EQ.2 ) THEN
!
!           Standardize new 2-by-2 block T11
!
      CALL DLANV2( T( J1, J1 ), T( J1, J2 ), T( J2, J1 ), &
                       T( J2, J2 ), WR1, WI1, WR2, WI2, CS, SN )
      CALL DROT( N-J1-1, T( J1, J1+2 ), LDT, T( J2, J1+2 ), LDT, &
                     CS, SN )
      CALL DROT( J1-1, T( 1, J1 ), 1, T( 1, J2 ), 1, CS, SN )
      IF( WANTQ ) &
             CALL DROT( N, Q( 1, J1 ), 1, Q( 1, J2 ), 1, CS, SN )
   END IF
!
   IF( N1.EQ.2 ) THEN
!
!           Standardize new 2-by-2 block T22
!
      J3 = J1 + N2
      J4 = J3 + 1
      CALL DLANV2( T( J3, J3 ), T( J3, J4 ), T( J4, J3 ), &
                       T( J4, J4 ), WR1, WI1, WR2, WI2, CS, SN )
      IF( J3+2.LE.N ) &
             CALL DROT( N-J3-1, T( J3, J3+2 ), LDT, T( J4, J3+2 ), &
                        LDT, CS, SN )
      CALL DROT( J3-1, T( 1, J3 ), 1, T( 1, J4 ), 1, CS, SN )
      IF( WANTQ ) &
             CALL DROT( N, Q( 1, J3 ), 1, Q( 1, J4 ), 1, CS, SN )
   END IF
!
END IF
RETURN
!
!     Exit with INFO = 1 if swap was rejected.
!
50 CONTINUE
INFO = 1
RETURN
!
!     End of DLAEXC
!
end subroutine dlaexc

! ===== End dlaexc.f90 =====


! ===== Begin dlag2.f90 =====

SUBROUTINE DLAG2( A, LDA, B, LDB, SAFMIN, SCALE1, SCALE2, WR1, &
                      WR2, WI )
!
!  -- LAPACK auxiliary routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
INTEGER            LDA, LDB
DOUBLE PRECISION   SAFMIN, SCALE1, SCALE2, WI, WR1, WR2
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DLAG2 computes the eigenvalues of a 2 x 2 generalized eigenvalue
!  problem  A - w B, with scaling as necessary to avoid over-/underflow.
!
!  The scaling factor "s" results in a modified eigenvalue equation
!
!      s A - w B
!
!  where  s  is a non-negative scaling factor chosen so that  w,  w B,
!  and  s A  do not overflow and, if possible, do not underflow, either.
!
!  Arguments
!  =========
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA, 2)
!          On entry, the 2 x 2 matrix A.  It is assumed that its 1-norm
!          is less than 1/SAFMIN.  Entries less than
!          sqrt(SAFMIN)*norm(A) are subject to being treated as zero.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= 2.
!
!  B       (input) DOUBLE PRECISION array, dimension (LDB, 2)
!          On entry, the 2 x 2 upper triangular matrix B.  It is
!          assumed that the one-norm of B is less than 1/SAFMIN.  The
!          diagonals should be at least sqrt(SAFMIN) times the largest
!          element of B (in absolute value); if a diagonal is smaller
!          than that, then  +/- sqrt(SAFMIN) will be used instead of
!          that diagonal.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= 2.
!
!  SAFMIN  (input) DOUBLE PRECISION
!          The smallest positive number s.t. 1/SAFMIN does not
!          overflow.  (This should always be DLAMCH('S') -- it is an
!          argument in order to avoid having to call DLAMCH frequently.)
!
!  SCALE1  (output) DOUBLE PRECISION
!          A scaling factor used to avoid over-/underflow in the
!          eigenvalue equation which defines the first eigenvalue.  If
!          the eigenvalues are complex, then the eigenvalues are
!          ( WR1  +/-  WI i ) / SCALE1  (which may lie outside the
!          exponent range of the machine), SCALE1=SCALE2, and SCALE1
!          will always be positive.  If the eigenvalues are real, then
!          the first (real) eigenvalue is  WR1 / SCALE1 , but this may
!          overflow or underflow, and in fact, SCALE1 may be zero or
!          less than the underflow threshhold if the exact eigenvalue
!          is sufficiently large.
!
!  SCALE2  (output) DOUBLE PRECISION
!          A scaling factor used to avoid over-/underflow in the
!          eigenvalue equation which defines the second eigenvalue.  If
!          the eigenvalues are complex, then SCALE2=SCALE1.  If the
!          eigenvalues are real, then the second (real) eigenvalue is
!          WR2 / SCALE2 , but this may overflow or underflow, and in
!          fact, SCALE2 may be zero or less than the underflow
!          threshhold if the exact eigenvalue is sufficiently large.
!
!  WR1     (output) DOUBLE PRECISION
!          If the eigenvalue is real, then WR1 is SCALE1 times the
!          eigenvalue closest to the (2,2) element of A B**(-1).  If the
!          eigenvalue is complex, then WR1=WR2 is SCALE1 times the real
!          part of the eigenvalues.
!
!  WR2     (output) DOUBLE PRECISION
!          If the eigenvalue is real, then WR2 is SCALE2 times the
!          other eigenvalue.  If the eigenvalue is complex, then
!          WR1=WR2 is SCALE1 times the real part of the eigenvalues.
!
!  WI      (output) DOUBLE PRECISION
!          If the eigenvalue is real, then WI is zero.  If the
!          eigenvalue is complex, then WI is SCALE1 times the imaginary
!          part of the eigenvalues.  WI will always be non-negative.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE, TWO
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0, TWO = 2.0D+0 )
DOUBLE PRECISION   HALF
PARAMETER          ( HALF = ONE / TWO )
DOUBLE PRECISION   FUZZY1
PARAMETER          ( FUZZY1 = ONE+1.0D-5 )
!     ..
!     .. Local Scalars ..
DOUBLE PRECISION   A11, A12, A21, A22, ABI22, ANORM, AS11, AS12, &
                       AS22, ASCALE, B11, B12, B22, BINV11, BINV22, &
                       BMIN, BNORM, BSCALE, BSIZE, C1, C2, C3, C4, C5, &
                       DIFF, DISCR, PP, QQ, R, RTMAX, RTMIN, S1, S2, &
                       SAFMAX, SHIFT, SS, SUM, WABS, WBIG, WDET, &
                       WSCALE, WSIZE, WSMALL
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN, SIGN, SQRT
!     ..
!     .. Executable Statements ..
!
RTMIN = SQRT( SAFMIN )
RTMAX = ONE / RTMIN
SAFMAX = ONE / SAFMIN
!
!     Scale A
!
ANORM = MAX( ABS( A( 1, 1 ) )+ABS( A( 2, 1 ) ), &
            ABS( A( 1, 2 ) )+ABS( A( 2, 2 ) ), SAFMIN )
ASCALE = ONE / ANORM
A11 = ASCALE*A( 1, 1 )
A21 = ASCALE*A( 2, 1 )
A12 = ASCALE*A( 1, 2 )
A22 = ASCALE*A( 2, 2 )
!
!     Perturb B if necessary to insure non-singularity
!
B11 = B( 1, 1 )
B12 = B( 1, 2 )
B22 = B( 2, 2 )
BMIN = RTMIN*MAX( ABS( B11 ), ABS( B12 ), ABS( B22 ), RTMIN )
IF( ABS( B11 ).LT.BMIN ) &
       B11 = SIGN( BMIN, B11 )
IF( ABS( B22 ).LT.BMIN ) &
       B22 = SIGN( BMIN, B22 )
!
!     Scale B
!
BNORM = MAX( ABS( B11 ), ABS( B12 )+ABS( B22 ), SAFMIN )
BSIZE = MAX( ABS( B11 ), ABS( B22 ) )
BSCALE = ONE / BSIZE
B11 = B11*BSCALE
B12 = B12*BSCALE
B22 = B22*BSCALE
!
!     Compute larger eigenvalue by method described by C. van Loan
!
!     ( AS is A shifted by -SHIFT*B )
!
BINV11 = ONE / B11
BINV22 = ONE / B22
S1 = A11*BINV11
S2 = A22*BINV22
IF( ABS( S1 ).LE.ABS( S2 ) ) THEN
   AS12 = A12 - S1*B12
   AS22 = A22 - S1*B22
   SS = A21*( BINV11*BINV22 )
   ABI22 = AS22*BINV22 - SS*B12
   PP = HALF*ABI22
   SHIFT = S1
ELSE
   AS12 = A12 - S2*B12
   AS11 = A11 - S2*B11
   SS = A21*( BINV11*BINV22 )
   ABI22 = -SS*B12
   PP = HALF*( AS11*BINV11+ABI22 )
   SHIFT = S2
END IF
QQ = SS*AS12
IF( ABS( PP*RTMIN ).GE.ONE ) THEN
   DISCR = ( RTMIN*PP )**2 + QQ*SAFMIN
   R = SQRT( ABS( DISCR ) )*RTMAX
ELSE
   IF( PP**2+ABS( QQ ).LE.SAFMIN ) THEN
      DISCR = ( RTMAX*PP )**2 + QQ*SAFMAX
      R = SQRT( ABS( DISCR ) )*RTMIN
   ELSE
      DISCR = PP**2 + QQ
      R = SQRT( ABS( DISCR ) )
   END IF
END IF
!
!     Note: the test of R in the following IF is to cover the case when
!           DISCR is small and negative and is flushed to zero during
!           the calculation of R.  On machines which have a consistent
!           flush-to-zero threshhold and handle numbers above that
!           threshhold correctly, it would not be necessary.
!
IF( DISCR.GE.ZERO .OR. R.EQ.ZERO ) THEN
   SUM = PP + SIGN( R, PP )
   DIFF = PP - SIGN( R, PP )
   WBIG = SHIFT + SUM
!
!        Compute smaller eigenvalue
!
   WSMALL = SHIFT + DIFF
   IF( HALF*ABS( WBIG ).GT.MAX( ABS( WSMALL ), SAFMIN ) ) THEN
      WDET = ( A11*A22-A12*A21 )*( BINV11*BINV22 )
      WSMALL = WDET / WBIG
   END IF
!
!        Choose (real) eigenvalue closest to 2,2 element of A*B**(-1)
!        for WR1.
!
   IF( PP.GT.ABI22 ) THEN
      WR1 = MIN( WBIG, WSMALL )
      WR2 = MAX( WBIG, WSMALL )
   ELSE
      WR1 = MAX( WBIG, WSMALL )
      WR2 = MIN( WBIG, WSMALL )
   END IF
   WI = ZERO
ELSE
!
!        Complex eigenvalues
!
   WR1 = SHIFT + PP
   WR2 = WR1
   WI = R
END IF
!
!     Further scaling to avoid underflow and overflow in computing
!     SCALE1 and overflow in computing w*B.
!
!     This scale factor (WSCALE) is bounded from above using C1 and C2,
!     and from below using C3 and C4.
!        C1 implements the condition  s A  must never overflow.
!        C2 implements the condition  w B  must never overflow.
!        C3, with C2,
!           implement the condition that s A - w B must never overflow.
!        C4 implements the condition  s    should not underflow.
!        C5 implements the condition  max(s,|w|) should be at least 2.
!
C1 = BSIZE*( SAFMIN*MAX( ONE, ASCALE ) )
C2 = SAFMIN*MAX( ONE, BNORM )
C3 = BSIZE*SAFMIN
IF( ASCALE.LE.ONE .AND. BSIZE.LE.ONE ) THEN
   C4 = MIN( ONE, ( ASCALE / SAFMIN )*BSIZE )
ELSE
   C4 = ONE
END IF
IF( ASCALE.LE.ONE .OR. BSIZE.LE.ONE ) THEN
   C5 = MIN( ONE, ASCALE*BSIZE )
ELSE
   C5 = ONE
END IF
!
!     Scale first eigenvalue
!
WABS = ABS( WR1 ) + ABS( WI )
WSIZE = MAX( SAFMIN, C1, FUZZY1*( WABS*C2+C3 ), &
            MIN( C4, HALF*MAX( WABS, C5 ) ) )
IF( WSIZE.NE.ONE ) THEN
   WSCALE = ONE / WSIZE
   IF( WSIZE.GT.ONE ) THEN
      SCALE1 = ( MAX( ASCALE, BSIZE )*WSCALE )* &
                   MIN( ASCALE, BSIZE )
   ELSE
      SCALE1 = ( MIN( ASCALE, BSIZE )*WSCALE )* &
                   MAX( ASCALE, BSIZE )
   END IF
   WR1 = WR1*WSCALE
   IF( WI.NE.ZERO ) THEN
      WI = WI*WSCALE
      WR2 = WR1
      SCALE2 = SCALE1
   END IF
ELSE
   SCALE1 = ASCALE*BSIZE
   SCALE2 = SCALE1
END IF
!
!     Scale second eigenvalue (if real)
!
IF( WI.EQ.ZERO ) THEN
   WSIZE = MAX( SAFMIN, C1, FUZZY1*( ABS( WR2 )*C2+C3 ), &
               MIN( C4, HALF*MAX( ABS( WR2 ), C5 ) ) )
   IF( WSIZE.NE.ONE ) THEN
      WSCALE = ONE / WSIZE
      IF( WSIZE.GT.ONE ) THEN
         SCALE2 = ( MAX( ASCALE, BSIZE )*WSCALE )* &
                      MIN( ASCALE, BSIZE )
      ELSE
         SCALE2 = ( MIN( ASCALE, BSIZE )*WSCALE )* &
                      MAX( ASCALE, BSIZE )
      END IF
      WR2 = WR2*WSCALE
   ELSE
      SCALE2 = ASCALE*BSIZE
   END IF
END IF
!
!     End of DLAG2
!
RETURN
end subroutine dlag2

! ===== End dlag2.f90 =====


! ===== Begin dlagtf.f90 =====

SUBROUTINE DLAGTF( N, A, LAMBDA, B, C, TOL, D, IN, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            INFO, N
DOUBLE PRECISION   LAMBDA, TOL
!     ..
!     .. Array Arguments ..
INTEGER            IN( * )
DOUBLE PRECISION   A( * ), B( * ), C( * ), D( * )
!     ..
!
!  Purpose
!  =======
!
!  DLAGTF factorizes the matrix (T - lambda*I), where T is an n by n
!  tridiagonal matrix and lambda is a scalar, as
!
!     T - lambda*I = PLU,
!
!  where P is a permutation matrix, L is a unit lower tridiagonal matrix
!  with at most one non-zero sub-diagonal elements per column and U is
!  an upper triangular matrix with at most two non-zero super-diagonal
!  elements per column.
!
!  The factorization is obtained by Gaussian elimination with partial
!  pivoting and implicit row scaling.
!
!  The parameter LAMBDA is included in the routine so that DLAGTF may
!  be used, in conjunction with DLAGTS, to obtain eigenvectors of T by
!  inverse iteration.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix T.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (N)
!          On entry, A must contain the diagonal elements of T.
!
!          On exit, A is overwritten by the n diagonal elements of the
!          upper triangular matrix U of the factorization of T.
!
!  LAMBDA  (input) DOUBLE PRECISION
!          On entry, the scalar lambda.
!
!  B       (input/output) DOUBLE PRECISION array, dimension (N-1)
!          On entry, B must contain the (n-1) super-diagonal elements of
!          T.
!
!          On exit, B is overwritten by the (n-1) super-diagonal
!          elements of the matrix U of the factorization of T.
!
!  C       (input/output) DOUBLE PRECISION array, dimension (N-1)
!          On entry, C must contain the (n-1) sub-diagonal elements of
!          T.
!
!          On exit, C is overwritten by the (n-1) sub-diagonal elements
!          of the matrix L of the factorization of T.
!
!  TOL     (input) DOUBLE PRECISION
!          On entry, a relative tolerance used to indicate whether or
!          not the matrix (T - lambda*I) is nearly singular. TOL should
!          normally be chose as approximately the largest relative error
!          in the elements of T. For example, if the elements of T are
!          correct to about 4 significant figures, then TOL should be
!          set to about 5*10**(-4). If TOL is supplied as less than eps,
!          where eps is the relative machine precision, then the value
!          eps is used in place of TOL.
!
!  D       (output) DOUBLE PRECISION array, dimension (N-2)
!          On exit, D is overwritten by the (n-2) second super-diagonal
!          elements of the matrix U of the factorization of T.
!
!  IN      (output) INTEGER array, dimension (N)
!          On exit, IN contains details of the permutation matrix P. If
!          an interchange occurred at the kth step of the elimination,
!          then IN(k) = 1, otherwise IN(k) = 0. The element IN(n)
!          returns the smallest positive integer j such that
!
!             abs( u(j,j) ).le. norm( (T - lambda*I)(j) )*TOL,
!
!          where norm( A(j) ) denotes the sum of the absolute values of
!          the jth row of the matrix A. If no such j exists then IN(n)
!          is returned as zero. If IN(n) is returned as positive, then a
!          diagonal element of U is small, indicating that
!          (T - lambda*I) is singular or nearly singular,
!
!  INFO    (output) INTEGER
!          = 0   : successful exit
!          .lt. 0: if INFO = -k, the kth argument had an illegal value
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            K
DOUBLE PRECISION   EPS, MULT, PIV1, PIV2, SCALE1, SCALE2, TEMP, TL
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMCH
EXTERNAL           DLAMCH
!     ..
!     .. External Subroutines ..
EXTERNAL           XERBLA
!     ..
!     .. Executable Statements ..
!
INFO = 0
IF( N.LT.0 ) THEN
   INFO = -1
   CALL XERBLA( 'DLAGTF', -INFO )
   RETURN
END IF
!
IF( N.EQ.0 ) &
       RETURN
!
A( 1 ) = A( 1 ) - LAMBDA
IN( N ) = 0
IF( N.EQ.1 ) THEN
   IF( A( 1 ).EQ.ZERO ) &
          IN( 1 ) = 1
   RETURN
END IF
!
EPS = DLAMCH( 'Epsilon' )
!
TL = MAX( TOL, EPS )
SCALE1 = ABS( A( 1 ) ) + ABS( B( 1 ) )
DO 10 K = 1, N - 1
   A( K+1 ) = A( K+1 ) - LAMBDA
   SCALE2 = ABS( C( K ) ) + ABS( A( K+1 ) )
   IF( K.LT.( N-1 ) ) &
          SCALE2 = SCALE2 + ABS( B( K+1 ) )
   IF( A( K ).EQ.ZERO ) THEN
      PIV1 = ZERO
   ELSE
      PIV1 = ABS( A( K ) ) / SCALE1
   END IF
   IF( C( K ).EQ.ZERO ) THEN
      IN( K ) = 0
      PIV2 = ZERO
      SCALE1 = SCALE2
      IF( K.LT.( N-1 ) ) &
             D( K ) = ZERO
   ELSE
      PIV2 = ABS( C( K ) ) / SCALE2
      IF( PIV2.LE.PIV1 ) THEN
         IN( K ) = 0
         SCALE1 = SCALE2
         C( K ) = C( K ) / A( K )
         A( K+1 ) = A( K+1 ) - C( K )*B( K )
         IF( K.LT.( N-1 ) ) &
                D( K ) = ZERO
      ELSE
         IN( K ) = 1
         MULT = A( K ) / C( K )
         A( K ) = C( K )
         TEMP = A( K+1 )
         A( K+1 ) = B( K ) - MULT*TEMP
         IF( K.LT.( N-1 ) ) THEN
            D( K ) = B( K+1 )
            B( K+1 ) = -MULT*D( K )
         END IF
         B( K ) = TEMP
         C( K ) = MULT
      END IF
   END IF
   IF( ( MAX( PIV1, PIV2 ).LE.TL ) .AND. ( IN( N ).EQ.0 ) ) &
          IN( N ) = K
10 CONTINUE
IF( ( ABS( A( N ) ).LE.SCALE1*TL ) .AND. ( IN( N ).EQ.0 ) ) &
       IN( N ) = N
!
RETURN
!
!     End of DLAGTF
!
end subroutine dlagtf

! ===== End dlagtf.f90 =====


! ===== Begin dlagtm.f90 =====

SUBROUTINE DLAGTM( TRANS, N, NRHS, ALPHA, DL, D, DU, X, LDX, BETA, &
                       B, LDB )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
CHARACTER          TRANS
INTEGER            LDB, LDX, N, NRHS
DOUBLE PRECISION   ALPHA, BETA
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   B( LDB, * ), D( * ), DL( * ), DU( * ), &
                       X( LDX, * )
!     ..
!
!  Purpose
!  =======
!
!  DLAGTM performs a matrix-vector product of the form
!
!     B := alpha * A * X + beta * B
!
!  where A is a tridiagonal matrix of order N, B and X are N by NRHS
!  matrices, and alpha and beta are real scalars, each of which may be
!  0., 1., or -1.
!
!  Arguments
!  =========
!
!  TRANS   (input) CHARACTER
!          Specifies the operation applied to A.
!          = 'N':  No transpose, B := alpha * A * X + beta * B
!          = 'T':  Transpose,    B := alpha * A'* X + beta * B
!          = 'C':  Conjugate transpose = Transpose
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrices X and B.
!
!  ALPHA   (input) DOUBLE PRECISION
!          The scalar alpha.  ALPHA must be 0., 1., or -1.; otherwise,
!          it is assumed to be 0.
!
!  DL      (input) DOUBLE PRECISION array, dimension (N-1)
!          The (n-1) sub-diagonal elements of T.
!
!  D       (input) DOUBLE PRECISION array, dimension (N)
!          The diagonal elements of T.
!
!  DU      (input) DOUBLE PRECISION array, dimension (N-1)
!          The (n-1) super-diagonal elements of T.
!
!  X       (input) DOUBLE PRECISION array, dimension (LDX,NRHS)
!          The N by NRHS matrix X.
!  LDX     (input) INTEGER
!          The leading dimension of the array X.  LDX >= max(N,1).
!
!  BETA    (input) DOUBLE PRECISION
!          The scalar beta.  BETA must be 0., 1., or -1.; otherwise,
!          it is assumed to be 1.
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the N by NRHS matrix B.
!          On exit, B is overwritten by the matrix expression
!          B := alpha * A * X + beta * B.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(N,1).
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, J
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Executable Statements ..
!
IF( N.EQ.0 ) &
       RETURN
!
!     Multiply B by BETA if BETA.NE.1.
!
IF( BETA.EQ.ZERO ) THEN
   DO 20 J = 1, NRHS
      DO 10 I = 1, N
         B( I, J ) = ZERO
10       CONTINUE
20    CONTINUE
ELSE IF( BETA.EQ.-ONE ) THEN
   DO 40 J = 1, NRHS
      DO 30 I = 1, N
         B( I, J ) = -B( I, J )
30       CONTINUE
40    CONTINUE
END IF
!
IF( ALPHA.EQ.ONE ) THEN
   IF( LSAME( TRANS, 'N' ) ) THEN
!
!           Compute B := B + A*X
!
      DO 60 J = 1, NRHS
         IF( N.EQ.1 ) THEN
            B( 1, J ) = B( 1, J ) + D( 1 )*X( 1, J )
         ELSE
            B( 1, J ) = B( 1, J ) + D( 1 )*X( 1, J ) + &
                            DU( 1 )*X( 2, J )
            B( N, J ) = B( N, J ) + DL( N-1 )*X( N-1, J ) + &
                            D( N )*X( N, J )
            DO 50 I = 2, N - 1
               B( I, J ) = B( I, J ) + DL( I-1 )*X( I-1, J ) + &
                               D( I )*X( I, J ) + DU( I )*X( I+1, J )
50             CONTINUE
         END IF
60       CONTINUE
   ELSE
!
!           Compute B := B + A'*X
!
      DO 80 J = 1, NRHS
         IF( N.EQ.1 ) THEN
            B( 1, J ) = B( 1, J ) + D( 1 )*X( 1, J )
         ELSE
            B( 1, J ) = B( 1, J ) + D( 1 )*X( 1, J ) + &
                            DL( 1 )*X( 2, J )
            B( N, J ) = B( N, J ) + DU( N-1 )*X( N-1, J ) + &
                            D( N )*X( N, J )
            DO 70 I = 2, N - 1
               B( I, J ) = B( I, J ) + DU( I-1 )*X( I-1, J ) + &
                               D( I )*X( I, J ) + DL( I )*X( I+1, J )
70             CONTINUE
         END IF
80       CONTINUE
   END IF
ELSE IF( ALPHA.EQ.-ONE ) THEN
   IF( LSAME( TRANS, 'N' ) ) THEN
!
!           Compute B := B - A*X
!
      DO 100 J = 1, NRHS
         IF( N.EQ.1 ) THEN
            B( 1, J ) = B( 1, J ) - D( 1 )*X( 1, J )
         ELSE
            B( 1, J ) = B( 1, J ) - D( 1 )*X( 1, J ) - &
                            DU( 1 )*X( 2, J )
            B( N, J ) = B( N, J ) - DL( N-1 )*X( N-1, J ) - &
                            D( N )*X( N, J )
            DO 90 I = 2, N - 1
               B( I, J ) = B( I, J ) - DL( I-1 )*X( I-1, J ) - &
                               D( I )*X( I, J ) - DU( I )*X( I+1, J )
90             CONTINUE
         END IF
100       CONTINUE
   ELSE
!
!           Compute B := B - A'*X
!
      DO 120 J = 1, NRHS
         IF( N.EQ.1 ) THEN
            B( 1, J ) = B( 1, J ) - D( 1 )*X( 1, J )
         ELSE
            B( 1, J ) = B( 1, J ) - D( 1 )*X( 1, J ) - &
                            DL( 1 )*X( 2, J )
            B( N, J ) = B( N, J ) - DU( N-1 )*X( N-1, J ) - &
                            D( N )*X( N, J )
            DO 110 I = 2, N - 1
               B( I, J ) = B( I, J ) - DU( I-1 )*X( I-1, J ) - &
                               D( I )*X( I, J ) - DL( I )*X( I+1, J )
110             CONTINUE
         END IF
120       CONTINUE
   END IF
END IF
RETURN
!
!     End of DLAGTM
!
end subroutine dlagtm

! ===== End dlagtm.f90 =====


! ===== Begin dlagts.f90 =====

SUBROUTINE DLAGTS( JOB, N, A, B, C, D, IN, Y, TOL, INFO )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
INTEGER            INFO, JOB, N
DOUBLE PRECISION   TOL
!     ..
!     .. Array Arguments ..
INTEGER            IN( * )
DOUBLE PRECISION   A( * ), B( * ), C( * ), D( * ), Y( * )
!     ..
!
!  Purpose
!  =======
!
!  DLAGTS may be used to solve one of the systems of equations
!
!     (T - lambda*I)*x = y   or   (T - lambda*I)'*x = y,
!
!  where T is an n by n tridiagonal matrix, for x, following the
!  factorization of (T - lambda*I) as
!
!     (T - lambda*I) = P*L*U ,
!
!  by routine DLAGTF. The choice of equation to be solved is
!  controlled by the argument JOB, and in each case there is an option
!  to perturb zero or very small diagonal elements of U, this option
!  being intended for use in applications such as inverse iteration.
!
!  Arguments
!  =========
!
!  JOB     (input) INTEGER
!          Specifies the job to be performed by DLAGTS as follows:
!          =  1: The equations  (T - lambda*I)x = y  are to be solved,
!                but diagonal elements of U are not to be perturbed.
!          = -1: The equations  (T - lambda*I)x = y  are to be solved
!                and, if overflow would otherwise occur, the diagonal
!                elements of U are to be perturbed. See argument TOL
!                below.
!          =  2: The equations  (T - lambda*I)'x = y  are to be solved,
!                but diagonal elements of U are not to be perturbed.
!          = -2: The equations  (T - lambda*I)'x = y  are to be solved
!                and, if overflow would otherwise occur, the diagonal
!                elements of U are to be perturbed. See argument TOL
!                below.
!
!  N       (input) INTEGER
!          The order of the matrix T.
!
!  A       (input) DOUBLE PRECISION array, dimension (N)
!          On entry, A must contain the diagonal elements of U as
!          returned from DLAGTF.
!
!  B       (input) DOUBLE PRECISION array, dimension (N-1)
!          On entry, B must contain the first super-diagonal elements of
!          U as returned from DLAGTF.
!
!  C       (input) DOUBLE PRECISION array, dimension (N-1)
!          On entry, C must contain the sub-diagonal elements of L as
!          returned from DLAGTF.
!
!  D       (input) DOUBLE PRECISION array, dimension (N-2)
!          On entry, D must contain the second super-diagonal elements
!          of U as returned from DLAGTF.
!
!  IN      (input) INTEGER array, dimension (N)
!          On entry, IN must contain details of the matrix P as returned
!          from DLAGTF.
!
!  Y       (input/output) DOUBLE PRECISION array, dimension (N)
!          On entry, the right hand side vector y.
!          On exit, Y is overwritten by the solution vector x.
!
!  TOL     (input/output) DOUBLE PRECISION
!          On entry, with  JOB .lt. 0, TOL should be the minimum
!          perturbation to be made to very small diagonal elements of U.
!          TOL should normally be chosen as about eps*norm(U), where eps
!          is the relative machine precision, but if TOL is supplied as
!          non-positive, then it is reset to eps*max( abs( u(i,j) ) ).
!          If  JOB .gt. 0  then TOL is not referenced.
!
!          On exit, TOL is changed as described above, only if TOL is
!          non-positive on entry. Otherwise TOL is unchanged.
!
!  INFO    (output) INTEGER
!          = 0   : successful exit
!          .lt. 0: if INFO = -i, the i-th argument had an illegal value
!          .gt. 0: overflow would occur when computing the INFO(th)
!                  element of the solution vector x. This can only occur
!                  when JOB is supplied as positive and either means
!                  that a diagonal element of U is very small, or that
!                  the elements of the right-hand side vector y are very
!                  large.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            K
DOUBLE PRECISION   ABSAK, AK, BIGNUM, EPS, PERT, SFMIN, TEMP
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, SIGN
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMCH
EXTERNAL           DLAMCH
!     ..
!     .. External Subroutines ..
EXTERNAL           XERBLA
!     ..
!     .. Executable Statements ..
!
INFO = 0
IF( ( ABS( JOB ).GT.2 ) .OR. ( JOB.EQ.0 ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DLAGTS', -INFO )
   RETURN
END IF
!
IF( N.EQ.0 ) &
       RETURN
!
EPS = DLAMCH( 'Epsilon' )
SFMIN = DLAMCH( 'Safe minimum' )
BIGNUM = ONE / SFMIN
!
IF( JOB.LT.0 ) THEN
   IF( TOL.LE.ZERO ) THEN
      TOL = ABS( A( 1 ) )
      IF( N.GT.1 ) &
             TOL = MAX( TOL, ABS( A( 2 ) ), ABS( B( 1 ) ) )
      DO 10 K = 3, N
         TOL = MAX( TOL, ABS( A( K ) ), ABS( B( K-1 ) ), &
                   ABS( D( K-2 ) ) )
10       CONTINUE
      TOL = TOL*EPS
      IF( TOL.EQ.ZERO ) &
             TOL = EPS
   END IF
END IF
!
IF( ABS( JOB ).EQ.1 ) THEN
   DO 20 K = 2, N
      IF( IN( K-1 ).EQ.0 ) THEN
         Y( K ) = Y( K ) - C( K-1 )*Y( K-1 )
      ELSE
         TEMP = Y( K-1 )
         Y( K-1 ) = Y( K )
         Y( K ) = TEMP - C( K-1 )*Y( K )
      END IF
20    CONTINUE
   IF( JOB.EQ.1 ) THEN
      DO 30 K = N, 1, -1
         IF( K.LE.N-2 ) THEN
            TEMP = Y( K ) - B( K )*Y( K+1 ) - D( K )*Y( K+2 )
         ELSE IF( K.EQ.N-1 ) THEN
            TEMP = Y( K ) - B( K )*Y( K+1 )
         ELSE
            TEMP = Y( K )
         END IF
         AK = A( K )
         ABSAK = ABS( AK )
         IF( ABSAK.LT.ONE ) THEN
            IF( ABSAK.LT.SFMIN ) THEN
               IF( ABSAK.EQ.ZERO .OR. ABS( TEMP )*SFMIN.GT.ABSAK ) &
                        THEN
                  INFO = K
                  RETURN
               ELSE
                  TEMP = TEMP*BIGNUM
                  AK = AK*BIGNUM
               END IF
            ELSE IF( ABS( TEMP ).GT.ABSAK*BIGNUM ) THEN
               INFO = K
               RETURN
            END IF
         END IF
         Y( K ) = TEMP / AK
30       CONTINUE
   ELSE
      DO 50 K = N, 1, -1
         IF( K.LE.N-2 ) THEN
            TEMP = Y( K ) - B( K )*Y( K+1 ) - D( K )*Y( K+2 )
         ELSE IF( K.EQ.N-1 ) THEN
            TEMP = Y( K ) - B( K )*Y( K+1 )
         ELSE
            TEMP = Y( K )
         END IF
         AK = A( K )
         PERT = SIGN( TOL, AK )
40          CONTINUE
         ABSAK = ABS( AK )
         IF( ABSAK.LT.ONE ) THEN
            IF( ABSAK.LT.SFMIN ) THEN
               IF( ABSAK.EQ.ZERO .OR. ABS( TEMP )*SFMIN.GT.ABSAK ) &
                        THEN
                  AK = AK + PERT
                  PERT = 2*PERT
                  GO TO 40
               ELSE
                  TEMP = TEMP*BIGNUM
                  AK = AK*BIGNUM
               END IF
            ELSE IF( ABS( TEMP ).GT.ABSAK*BIGNUM ) THEN
               AK = AK + PERT
               PERT = 2*PERT
               GO TO 40
            END IF
         END IF
         Y( K ) = TEMP / AK
50       CONTINUE
   END IF
ELSE
!
!        Come to here if  JOB = 2 or -2
!
   IF( JOB.EQ.2 ) THEN
      DO 60 K = 1, N
         IF( K.GE.3 ) THEN
            TEMP = Y( K ) - B( K-1 )*Y( K-1 ) - D( K-2 )*Y( K-2 )
         ELSE IF( K.EQ.2 ) THEN
            TEMP = Y( K ) - B( K-1 )*Y( K-1 )
         ELSE
            TEMP = Y( K )
         END IF
         AK = A( K )
         ABSAK = ABS( AK )
         IF( ABSAK.LT.ONE ) THEN
            IF( ABSAK.LT.SFMIN ) THEN
               IF( ABSAK.EQ.ZERO .OR. ABS( TEMP )*SFMIN.GT.ABSAK ) &
                        THEN
                  INFO = K
                  RETURN
               ELSE
                  TEMP = TEMP*BIGNUM
                  AK = AK*BIGNUM
               END IF
            ELSE IF( ABS( TEMP ).GT.ABSAK*BIGNUM ) THEN
               INFO = K
               RETURN
            END IF
         END IF
         Y( K ) = TEMP / AK
60       CONTINUE
   ELSE
      DO 80 K = 1, N
         IF( K.GE.3 ) THEN
            TEMP = Y( K ) - B( K-1 )*Y( K-1 ) - D( K-2 )*Y( K-2 )
         ELSE IF( K.EQ.2 ) THEN
            TEMP = Y( K ) - B( K-1 )*Y( K-1 )
         ELSE
            TEMP = Y( K )
         END IF
         AK = A( K )
         PERT = SIGN( TOL, AK )
70          CONTINUE
         ABSAK = ABS( AK )
         IF( ABSAK.LT.ONE ) THEN
            IF( ABSAK.LT.SFMIN ) THEN
               IF( ABSAK.EQ.ZERO .OR. ABS( TEMP )*SFMIN.GT.ABSAK ) &
                        THEN
                  AK = AK + PERT
                  PERT = 2*PERT
                  GO TO 70
               ELSE
                  TEMP = TEMP*BIGNUM
                  AK = AK*BIGNUM
               END IF
            ELSE IF( ABS( TEMP ).GT.ABSAK*BIGNUM ) THEN
               AK = AK + PERT
               PERT = 2*PERT
               GO TO 70
            END IF
         END IF
         Y( K ) = TEMP / AK
80       CONTINUE
   END IF
!
   DO 90 K = N, 2, -1
      IF( IN( K-1 ).EQ.0 ) THEN
         Y( K-1 ) = Y( K-1 ) - C( K-1 )*Y( K )
      ELSE
         TEMP = Y( K-1 )
         Y( K-1 ) = Y( K )
         Y( K ) = TEMP - C( K-1 )*Y( K )
      END IF
90    CONTINUE
END IF
!
!     End of DLAGTS
!
end subroutine dlagts

! ===== End dlagts.f90 =====


! ===== Begin dlahqr.f90 =====

SUBROUTINE DLAHQR( WANTT, WANTZ, N, ILO, IHI, H, LDH, WR, WI, &
                       ILOZ, IHIZ, Z, LDZ, INFO )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
LOGICAL            WANTT, WANTZ
INTEGER            IHI, IHIZ, ILO, ILOZ, INFO, LDH, LDZ, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   H( LDH, * ), WI( * ), WR( * ), Z( LDZ, * )
!     ..
!
!  Purpose
!  =======
!
!  DLAHQR is an auxiliary routine called by DHSEQR to update the
!  eigenvalues and Schur decomposition already computed by DHSEQR, by
!  dealing with the Hessenberg submatrix in rows and columns ILO to IHI.
!
!  Arguments
!  =========
!
!  WANTT   (input) LOGICAL
!          = .TRUE. : the full Schur form T is required;
!          = .FALSE.: only eigenvalues are required.
!
!  WANTZ   (input) LOGICAL
!          = .TRUE. : the matrix of Schur vectors Z is required;
!          = .FALSE.: Schur vectors are not required.
!
!  N       (input) INTEGER
!          The order of the matrix H.  N >= 0.
!
!  ILO     (input) INTEGER
!  IHI     (input) INTEGER
!          It is assumed that H is already upper quasi-triangular in
!          rows and columns IHI+1:N, and that H(ILO,ILO-1) = 0 (unless
!          ILO = 1). DLAHQR works primarily with the Hessenberg
!          submatrix in rows and columns ILO to IHI, but applies
!          transformations to all of H if WANTT is .TRUE..
!          1 <= ILO <= max(1,IHI); IHI <= N.
!
!  H       (input/output) DOUBLE PRECISION array, dimension (LDH,N)
!          On entry, the upper Hessenberg matrix H.
!          On exit, if WANTT is .TRUE., H is upper quasi-triangular in
!          rows and columns ILO:IHI, with any 2-by-2 diagonal blocks in
!          standard form. If WANTT is .FALSE., the contents of H are
!          unspecified on exit.
!
!  LDH     (input) INTEGER
!          The leading dimension of the array H. LDH >= max(1,N).
!
!  WR      (output) DOUBLE PRECISION array, dimension (N)
!  WI      (output) DOUBLE PRECISION array, dimension (N)
!          The real and imaginary parts, respectively, of the computed
!          eigenvalues ILO to IHI are stored in the corresponding
!          elements of WR and WI. If two eigenvalues are computed as a
!          complex conjugate pair, they are stored in consecutive
!          elements of WR and WI, say the i-th and (i+1)th, with
!          WI(i) > 0 and WI(i+1) < 0. If WANTT is .TRUE., the
!          eigenvalues are stored in the same order as on the diagonal
!          of the Schur form returned in H, with WR(i) = H(i,i), and, if
!          H(i:i+1,i:i+1) is a 2-by-2 diagonal block,
!          WI(i) = sqrt(H(i+1,i)*H(i,i+1)) and WI(i+1) = -WI(i).
!
!  ILOZ    (input) INTEGER
!  IHIZ    (input) INTEGER
!          Specify the rows of Z to which transformations must be
!          applied if WANTZ is .TRUE..
!          1 <= ILOZ <= ILO; IHI <= IHIZ <= N.
!
!  Z       (input/output) DOUBLE PRECISION array, dimension (LDZ,N)
!          If WANTZ is .TRUE., on entry Z must contain the current
!          matrix Z of transformations accumulated by DHSEQR, and on
!          exit Z has been updated; transformations are applied only to
!          the submatrix Z(ILOZ:IHIZ,ILO:IHI).
!          If WANTZ is .FALSE., Z is not referenced.
!
!  LDZ     (input) INTEGER
!          The leading dimension of the array Z. LDZ >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          > 0: DLAHQR failed to compute all the eigenvalues ILO to IHI
!               in a total of 30*(IHI-ILO+1) iterations; if INFO = i,
!               elements i+1:ihi of WR and WI contain those eigenvalues
!               which have been successfully computed.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
DOUBLE PRECISION   DAT1, DAT2
PARAMETER          ( DAT1 = 0.75D+0, DAT2 = -0.4375D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, I1, I2, ITN, ITS, J, K, L, M, NH, NR, NZ
DOUBLE PRECISION   CS, H00, H10, H11, H12, H21, H22, H33, H33S, &
                       H43H34, H44, H44S, OVFL, S, SMLNUM, SN, SUM, &
                       T1, T2, T3, TST1, ULP, UNFL, V1, V2, V3
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   V( 3 ), WORK( 1 )
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMCH, DLANHS
EXTERNAL           DLAMCH, DLANHS
!     ..
!     .. External Subroutines ..
EXTERNAL           DCOPY, DLABAD, DLANV2, DLARFG, DROT
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN
!     ..
!     .. Executable Statements ..
!
INFO = 0
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
IF( ILO.EQ.IHI ) THEN
   WR( ILO ) = H( ILO, ILO )
   WI( ILO ) = ZERO
   RETURN
END IF
!
NH = IHI - ILO + 1
NZ = IHIZ - ILOZ + 1
!
!     Set machine-dependent constants for the stopping criterion.
!     If norm(H) <= sqrt(OVFL), overflow should not occur.
!
UNFL = DLAMCH( 'Safe minimum' )
OVFL = ONE / UNFL
CALL DLABAD( UNFL, OVFL )
ULP = DLAMCH( 'Precision' )
SMLNUM = UNFL*( NH / ULP )
!
!     I1 and I2 are the indices of the first row and last column of H
!     to which transformations must be applied. If eigenvalues only are
!     being computed, I1 and I2 are set inside the main loop.
!
IF( WANTT ) THEN
   I1 = 1
   I2 = N
END IF
!
!     ITN is the total number of QR iterations allowed.
!
ITN = 30*NH
!
!     The main loop begins here. I is the loop index and decreases from
!     IHI to ILO in steps of 1 or 2. Each iteration of the loop works
!     with the active submatrix in rows and columns L to I.
!     Eigenvalues I+1 to IHI have already converged. Either L = ILO or
!     H(L,L-1) is negligible so that the matrix splits.
!
I = IHI
10 CONTINUE
L = ILO
IF( I.LT.ILO ) &
       GO TO 150
!
!     Perform QR iterations on rows and columns ILO to I until a
!     submatrix of order 1 or 2 splits off at the bottom because a
!     subdiagonal element has become negligible.
!
DO 130 ITS = 0, ITN
!
!        Look for a single small subdiagonal element.
!
   DO 20 K = I, L + 1, -1
      TST1 = ABS( H( K-1, K-1 ) ) + ABS( H( K, K ) )
      IF( TST1.EQ.ZERO ) &
             TST1 = DLANHS( '1', I-L+1, H( L, L ), LDH, WORK )
      IF( ABS( H( K, K-1 ) ).LE.MAX( ULP*TST1, SMLNUM ) ) &
             GO TO 30
20    CONTINUE
30    CONTINUE
   L = K
   IF( L.GT.ILO ) THEN
!
!           H(L,L-1) is negligible
!
      H( L, L-1 ) = ZERO
   END IF
!
!        Exit from loop if a submatrix of order 1 or 2 has split off.
!
   IF( L.GE.I-1 ) &
          GO TO 140
!
!        Now the active submatrix is in rows and columns L to I. If
!        eigenvalues only are being computed, only the active submatrix
!        need be transformed.
!
   IF( .NOT.WANTT ) THEN
      I1 = L
      I2 = I
   END IF
!
   IF( ITS.EQ.10 .OR. ITS.EQ.20 ) THEN
!
!           Exceptional shift.
!
      S = ABS( H( I, I-1 ) ) + ABS( H( I-1, I-2 ) )
      H44 = DAT1*S
      H33 = H44
      H43H34 = DAT2*S*S
   ELSE
!
!           Prepare to use Wilkinson's double shift
!
      H44 = H( I, I )
      H33 = H( I-1, I-1 )
      H43H34 = H( I, I-1 )*H( I-1, I )
   END IF
!
!        Look for two consecutive small subdiagonal elements.
!
   DO 40 M = I - 2, L, -1
!
!           Determine the effect of starting the double-shift QR
!           iteration at row M, and see if this would make H(M,M-1)
!           negligible.
!
      H11 = H( M, M )
      H22 = H( M+1, M+1 )
      H21 = H( M+1, M )
      H12 = H( M, M+1 )
      H44S = H44 - H11
      H33S = H33 - H11
      V1 = ( H33S*H44S-H43H34 ) / H21 + H12
      V2 = H22 - H11 - H33S - H44S
      V3 = H( M+2, M+1 )
      S = ABS( V1 ) + ABS( V2 ) + ABS( V3 )
      V1 = V1 / S
      V2 = V2 / S
      V3 = V3 / S
      V( 1 ) = V1
      V( 2 ) = V2
      V( 3 ) = V3
      IF( M.EQ.L ) &
             GO TO 50
      H00 = H( M-1, M-1 )
      H10 = H( M, M-1 )
      TST1 = ABS( V1 )*( ABS( H00 )+ABS( H11 )+ABS( H22 ) )
      IF( ABS( H10 )*( ABS( V2 )+ABS( V3 ) ).LE.ULP*TST1 ) &
             GO TO 50
40    CONTINUE
50    CONTINUE
!
!        Double-shift QR step
!
   DO 120 K = M, I - 1
!
!           The first iteration of this loop determines a reflection G
!           from the vector V and applies it from left and right to H,
!           thus creating a nonzero bulge below the subdiagonal.
!
!           Each subsequent iteration determines a reflection G to
!           restore the Hessenberg form in the (K-1)th column, and thus
!           chases the bulge one step toward the bottom of the active
!           submatrix. NR is the order of G.
!
      NR = MIN( 3, I-K+1 )
      IF( K.GT.M ) &
             CALL DCOPY( NR, H( K, K-1 ), 1, V, 1 )
      CALL DLARFG( NR, V( 1 ), V( 2 ), 1, T1 )
      IF( K.GT.M ) THEN
         H( K, K-1 ) = V( 1 )
         H( K+1, K-1 ) = ZERO
         IF( K.LT.I-1 ) &
                H( K+2, K-1 ) = ZERO
      ELSE IF( M.GT.L ) THEN
         H( K, K-1 ) = -H( K, K-1 )
      END IF
      V2 = V( 2 )
      T2 = T1*V2
      IF( NR.EQ.3 ) THEN
         V3 = V( 3 )
         T3 = T1*V3
!
!              Apply G from the left to transform the rows of the matrix
!              in columns K to I2.
!
         DO 60 J = K, I2
            SUM = H( K, J ) + V2*H( K+1, J ) + V3*H( K+2, J )
            H( K, J ) = H( K, J ) - SUM*T1
            H( K+1, J ) = H( K+1, J ) - SUM*T2
            H( K+2, J ) = H( K+2, J ) - SUM*T3
60          CONTINUE
!
!              Apply G from the right to transform the columns of the
!              matrix in rows I1 to min(K+3,I).
!
         DO 70 J = I1, MIN( K+3, I )
            SUM = H( J, K ) + V2*H( J, K+1 ) + V3*H( J, K+2 )
            H( J, K ) = H( J, K ) - SUM*T1
            H( J, K+1 ) = H( J, K+1 ) - SUM*T2
            H( J, K+2 ) = H( J, K+2 ) - SUM*T3
70          CONTINUE
!
         IF( WANTZ ) THEN
!
!                 Accumulate transformations in the matrix Z
!
            DO 80 J = ILOZ, IHIZ
               SUM = Z( J, K ) + V2*Z( J, K+1 ) + V3*Z( J, K+2 )
               Z( J, K ) = Z( J, K ) - SUM*T1
               Z( J, K+1 ) = Z( J, K+1 ) - SUM*T2
               Z( J, K+2 ) = Z( J, K+2 ) - SUM*T3
80             CONTINUE
         END IF
      ELSE IF( NR.EQ.2 ) THEN
!
!              Apply G from the left to transform the rows of the matrix
!              in columns K to I2.
!
         DO 90 J = K, I2
            SUM = H( K, J ) + V2*H( K+1, J )
            H( K, J ) = H( K, J ) - SUM*T1
            H( K+1, J ) = H( K+1, J ) - SUM*T2
90          CONTINUE
!
!              Apply G from the right to transform the columns of the
!              matrix in rows I1 to min(K+3,I).
!
         DO 100 J = I1, I
            SUM = H( J, K ) + V2*H( J, K+1 )
            H( J, K ) = H( J, K ) - SUM*T1
            H( J, K+1 ) = H( J, K+1 ) - SUM*T2
100          CONTINUE
!
         IF( WANTZ ) THEN
!
!                 Accumulate transformations in the matrix Z
!
            DO 110 J = ILOZ, IHIZ
               SUM = Z( J, K ) + V2*Z( J, K+1 )
               Z( J, K ) = Z( J, K ) - SUM*T1
               Z( J, K+1 ) = Z( J, K+1 ) - SUM*T2
110             CONTINUE
         END IF
      END IF
120    CONTINUE
!
130 CONTINUE
!
!     Failure to converge in remaining number of iterations
!
INFO = I
RETURN
!
140 CONTINUE
!
IF( L.EQ.I ) THEN
!
!        H(I,I-1) is negligible: one eigenvalue has converged.
!
   WR( I ) = H( I, I )
   WI( I ) = ZERO
ELSE IF( L.EQ.I-1 ) THEN
!
!        H(I-1,I-2) is negligible: a pair of eigenvalues have converged.
!
!        Transform the 2-by-2 submatrix to standard Schur form,
!        and compute and store the eigenvalues.
!
   CALL DLANV2( H( I-1, I-1 ), H( I-1, I ), H( I, I-1 ), &
                    H( I, I ), WR( I-1 ), WI( I-1 ), WR( I ), WI( I ), &
                    CS, SN )
!
   IF( WANTT ) THEN
!
!           Apply the transformation to the rest of H.
!
      IF( I2.GT.I ) &
             CALL DROT( I2-I, H( I-1, I+1 ), LDH, H( I, I+1 ), LDH, &
                        CS, SN )
      CALL DROT( I-I1-1, H( I1, I-1 ), 1, H( I1, I ), 1, CS, SN )
   END IF
   IF( WANTZ ) THEN
!
!           Apply the transformation to Z.
!
      CALL DROT( NZ, Z( ILOZ, I-1 ), 1, Z( ILOZ, I ), 1, CS, SN )
   END IF
END IF
!
!     Decrement number of remaining iterations, and return to start of
!     the main loop with new value of I.
!
ITN = ITN - ITS
I = L - 1
GO TO 10
!
150 CONTINUE
RETURN
!
!     End of DLAHQR
!
end subroutine dlahqr

! ===== End dlahqr.f90 =====


! ===== Begin dlahrd.f90 =====

SUBROUTINE DLAHRD( N, K, NB, A, LDA, TAU, T, LDT, Y, LDY )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            K, LDA, LDT, LDY, N, NB
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), T( LDT, NB ), TAU( NB ), &
                       Y( LDY, NB )
!     ..
!
!  Purpose
!  =======
!
!  DLAHRD reduces the first NB columns of a real general n-by-(n-k+1)
!  matrix A so that elements below the k-th subdiagonal are zero. The
!  reduction is performed by an orthogonal similarity transformation
!  Q' * A * Q. The routine returns the matrices V and T which determine
!  Q as a block reflector I - V*T*V', and also the matrix Y = A * V * T.
!
!  This is an auxiliary routine called by DGEHRD.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix A.
!
!  K       (input) INTEGER
!          The offset for the reduction. Elements below the k-th
!          subdiagonal in the first NB columns are reduced to zero.
!
!  NB      (input) INTEGER
!          The number of columns to be reduced.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N-K+1)
!          On entry, the n-by-(n-k+1) general matrix A.
!          On exit, the elements on and above the k-th subdiagonal in
!          the first NB columns are overwritten with the corresponding
!          elements of the reduced matrix; the elements below the k-th
!          subdiagonal, with the array TAU, represent the matrix Q as a
!          product of elementary reflectors. The other columns of A are
!          unchanged. See Further Details.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  TAU     (output) DOUBLE PRECISION array, dimension (NB)
!          The scalar factors of the elementary reflectors. See Further
!          Details.
!
!  T       (output) DOUBLE PRECISION array, dimension (NB,NB)
!          The upper triangular matrix T.
!
!  LDT     (input) INTEGER
!          The leading dimension of the array T.  LDT >= NB.
!
!  Y       (output) DOUBLE PRECISION array, dimension (LDY,NB)
!          The n-by-nb matrix Y.
!
!  LDY     (input) INTEGER
!          The leading dimension of the array Y. LDY >= N.
!
!  Further Details
!  ===============
!
!  The matrix Q is represented as a product of nb elementary reflectors
!
!     Q = H(1) H(2) . . . H(nb).
!
!  Each H(i) has the form
!
!     H(i) = I - tau * v * v'
!
!  where tau is a real scalar, and v is a real vector with
!  v(1:i+k-1) = 0, v(i+k) = 1; v(i+k+1:n) is stored on exit in
!  A(i+k+1:n,i), and tau in TAU(i).
!
!  The elements of the vectors v together form the (n-k+1)-by-nb matrix
!  V which is needed, with T and Y, to apply the transformation to the
!  unreduced part of the matrix, using an update of the form:
!  A := (I - V*T*V') * (A - Y*V').
!
!  The contents of A on exit are illustrated by the following example
!  with n = 7, k = 3 and nb = 2:
!
!     ( a   h   a   a   a )
!     ( a   h   a   a   a )
!     ( a   h   a   a   a )
!     ( h   h   a   a   a )
!     ( v1  h   a   a   a )
!     ( v1  v2  a   a   a )
!     ( v1  v2  a   a   a )
!
!  where a denotes an element of the original matrix A, h denotes a
!  modified element of the upper Hessenberg matrix H, and vi denotes an
!  element of the vector defining H(i).
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I
DOUBLE PRECISION   EI
!     ..
!     .. External Subroutines ..
EXTERNAL           DAXPY, DCOPY, DGEMV, DLARFG, DSCAL, DTRMV
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MIN
!     ..
!     .. Executable Statements ..
!
!     Quick return if possible
!
IF( N.LE.1 ) &
       RETURN
!
DO 10 I = 1, NB
   IF( I.GT.1 ) THEN
!
!           Update A(1:n,i)
!
!           Compute i-th column of A - Y * V'
!
      CALL DGEMV( 'No transpose', N, I-1, -ONE, Y, LDY, &
                      A( K+I-1, 1 ), LDA, ONE, A( 1, I ), 1 )
!
!           Apply I - V * T' * V' to this column (call it b) from the
!           left, using the last column of T as workspace
!
!           Let  V = ( V1 )   and   b = ( b1 )   (first I-1 rows)
!                    ( V2 )             ( b2 )
!
!           where V1 is unit lower triangular
!
!           w := V1' * b1
!
      CALL DCOPY( I-1, A( K+1, I ), 1, T( 1, NB ), 1 )
      CALL DTRMV( 'Lower', 'Transpose', 'Unit', I-1, A( K+1, 1 ), &
                      LDA, T( 1, NB ), 1 )
!
!           w := w + V2'*b2
!
      CALL DGEMV( 'Transpose', N-K-I+1, I-1, ONE, A( K+I, 1 ), &
                      LDA, A( K+I, I ), 1, ONE, T( 1, NB ), 1 )
!
!           w := T'*w
!
      CALL DTRMV( 'Upper', 'Transpose', 'Non-unit', I-1, T, LDT, &
                      T( 1, NB ), 1 )
!
!           b2 := b2 - V2*w
!
      CALL DGEMV( 'No transpose', N-K-I+1, I-1, -ONE, A( K+I, 1 ), &
                      LDA, T( 1, NB ), 1, ONE, A( K+I, I ), 1 )
!
!           b1 := b1 - V1*w
!
      CALL DTRMV( 'Lower', 'No transpose', 'Unit', I-1, &
                      A( K+1, 1 ), LDA, T( 1, NB ), 1 )
      CALL DAXPY( I-1, -ONE, T( 1, NB ), 1, A( K+1, I ), 1 )
!
      A( K+I-1, I-1 ) = EI
   END IF
!
!        Generate the elementary reflector H(i) to annihilate
!        A(k+i+1:n,i)
!
   CALL DLARFG( N-K-I+1, A( K+I, I ), A( MIN( K+I+1, N ), I ), 1, &
                    TAU( I ) )
   EI = A( K+I, I )
   A( K+I, I ) = ONE
!
!        Compute  Y(1:n,i)
!
   CALL DGEMV( 'No transpose', N, N-K-I+1, ONE, A( 1, I+1 ), LDA, &
                   A( K+I, I ), 1, ZERO, Y( 1, I ), 1 )
   CALL DGEMV( 'Transpose', N-K-I+1, I-1, ONE, A( K+I, 1 ), LDA, &
                   A( K+I, I ), 1, ZERO, T( 1, I ), 1 )
   CALL DGEMV( 'No transpose', N, I-1, -ONE, Y, LDY, T( 1, I ), 1, &
                   ONE, Y( 1, I ), 1 )
   CALL DSCAL( N, TAU( I ), Y( 1, I ), 1 )
!
!        Compute T(1:i,i)
!
   CALL DSCAL( I-1, -TAU( I ), T( 1, I ), 1 )
   CALL DTRMV( 'Upper', 'No transpose', 'Non-unit', I-1, T, LDT, &
                   T( 1, I ), 1 )
   T( I, I ) = TAU( I )
!
10 CONTINUE
A( K+NB, NB ) = EI
!
RETURN
!
!     End of DLAHRD
!
end subroutine dlahrd

! ===== End dlahrd.f90 =====


! ===== Begin dlaln2.f90 =====

SUBROUTINE DLALN2( LTRANS, NA, NW, SMIN, CA, A, LDA, D1, D2, B, &
                       LDB, WR, WI, X, LDX, SCALE, XNORM, INFO )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
LOGICAL            LTRANS
INTEGER            INFO, LDA, LDB, LDX, NA, NW
DOUBLE PRECISION   CA, D1, D2, SCALE, SMIN, WI, WR, XNORM
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), B( LDB, * ), X( LDX, * )
!     ..
!
!  Purpose
!  =======
!
!  DLALN2 solves a system of the form  (ca A - w D ) X = s B
!  or (ca A' - w D) X = s B   with possible scaling ("s") and
!  perturbation of A.  (A' means A-transpose.)
!
!  A is an NA x NA real matrix, ca is a real scalar, D is an NA x NA
!  real diagonal matrix, w is a real or complex value, and X and B are
!  NA x 1 matrices -- real if w is real, complex if w is complex.  NA
!  may be 1 or 2.
!
!  If w is complex, X and B are represented as NA x 2 matrices,
!  the first column of each being the real part and the second
!  being the imaginary part.
!
!  "s" is a scaling factor (.LE. 1), computed by DLALN2, which is
!  so chosen that X can be computed without overflow.  X is further
!  scaled if necessary to assure that norm(ca A - w D)*norm(X) is less
!  than overflow.
!
!  If both singular values of (ca A - w D) are less than SMIN,
!  SMIN*identity will be used instead of (ca A - w D).  If only one
!  singular value is less than SMIN, one element of (ca A - w D) will be
!  perturbed enough to make the smallest singular value roughly SMIN.
!  If both singular values are at least SMIN, (ca A - w D) will not be
!  perturbed.  In any case, the perturbation will be at most some small
!  multiple of max( SMIN, ulp*norm(ca A - w D) ).  The singular values
!  are computed by infinity-norm approximations, and thus will only be
!  correct to a factor of 2 or so.
!
!  Note: all input quantities are assumed to be smaller than overflow
!  by a reasonable factor.  (See BIGNUM.)
!
!  Arguments
!  ==========
!
!  LTRANS  (input) LOGICAL
!          =.TRUE.:  A-transpose will be used.
!          =.FALSE.: A will be used (not transposed.)
!
!  NA      (input) INTEGER
!          The size of the matrix A.  It may (only) be 1 or 2.
!
!  NW      (input) INTEGER
!          1 if "w" is real, 2 if "w" is complex.  It may only be 1
!          or 2.
!
!  SMIN    (input) DOUBLE PRECISION
!          The desired lower bound on the singular values of A.  This
!          should be a safe distance away from underflow or overflow,
!          say, between (underflow/machine precision) and  (machine
!          precision * overflow ).  (See BIGNUM and ULP.)
!
!  CA      (input) DOUBLE PRECISION
!          The coefficient c, which A is multiplied by.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,NA)
!          The NA x NA matrix A.
!
!  LDA     (input) INTEGER
!          The leading dimension of A.  It must be at least NA.
!
!  D1      (input) DOUBLE PRECISION
!          The 1,1 element in the diagonal matrix D.
!
!  D2      (input) DOUBLE PRECISION
!          The 2,2 element in the diagonal matrix D.  Not used if NW=1.
!
!  B       (input) DOUBLE PRECISION array, dimension (LDB,NW)
!          The NA x NW matrix B (right-hand side).  If NW=2 ("w" is
!          complex), column 1 contains the real part of B and column 2
!          contains the imaginary part.
!
!  LDB     (input) INTEGER
!          The leading dimension of B.  It must be at least NA.
!
!  WR      (input) DOUBLE PRECISION
!          The real part of the scalar "w".
!
!  WI      (input) DOUBLE PRECISION
!          The imaginary part of the scalar "w".  Not used if NW=1.
!
!  X       (output) DOUBLE PRECISION array, dimension (LDX,NW)
!          The NA x NW matrix X (unknowns), as computed by DLALN2.
!          If NW=2 ("w" is complex), on exit, column 1 will contain
!          the real part of X and column 2 will contain the imaginary
!          part.
!
!  LDX     (input) INTEGER
!          The leading dimension of X.  It must be at least NA.
!
!  SCALE   (output) DOUBLE PRECISION
!          The scale factor that B must be multiplied by to insure
!          that overflow does not occur when computing X.  Thus,
!          (ca A - w D) X  will be SCALE*B, not B (ignoring
!          perturbations of A.)  It will be at most 1.
!
!  XNORM   (output) DOUBLE PRECISION
!          The infinity-norm of X, when X is regarded as an NA x NW
!          real matrix.
!
!  INFO    (output) INTEGER
!          An error flag.  It will be set to zero if no error occurs,
!          a negative number if an argument is in error, or a positive
!          number if  ca A - w D  had to be perturbed.
!          The possible values are:
!          = 0: No error occurred, and (ca A - w D) did not have to be
!                 perturbed.
!          = 1: (ca A - w D) had to be perturbed to make its smallest
!               (or only) singular value greater than SMIN.
!          NOTE: In the interests of speed, this routine does not
!                check the inputs for errors.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D0, ONE = 1.0D0 )
DOUBLE PRECISION   TWO
PARAMETER          ( TWO = 2.0D0 )
!     ..
!     .. Local Scalars ..
INTEGER            ICMAX, J
DOUBLE PRECISION   BBND, BI1, BI2, BIGNUM, BNORM, BR1, BR2, CI21, &
                       CI22, CMAX, CNORM, CR21, CR22, CSI, CSR, LI21, &
                       LR21, SMINI, SMLNUM, TEMP, U22ABS, UI11, UI11R, &
                       UI12, UI12S, UI22, UR11, UR11R, UR12, UR12S, &
                       UR22, XI1, XI2, XR1, XR2
!     ..
!     .. Local Arrays ..
LOGICAL            RSWAP( 4 ), ZSWAP( 4 )
INTEGER            IPIVOT( 4, 4 )
DOUBLE PRECISION   CI( 2, 2 ), CIV( 4 ), CR( 2, 2 ), CRV( 4 )
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMCH
EXTERNAL           DLAMCH
!     ..
!     .. External Subroutines ..
EXTERNAL           DLADIV
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX
!     ..
!     .. Equivalences ..
EQUIVALENCE        ( CI( 1, 1 ), CIV( 1 ) ), &
                       ( CR( 1, 1 ), CRV( 1 ) )
!     ..
!     .. Data statements ..
DATA               ZSWAP / .FALSE., .FALSE., .TRUE., .TRUE. /
DATA               RSWAP / .FALSE., .TRUE., .FALSE., .TRUE. /
DATA               IPIVOT / 1, 2, 3, 4, 2, 1, 4, 3, 3, 4, 1, 2, 4, &
                       3, 2, 1 /
!     ..
!     .. Executable Statements ..
!
!     Compute BIGNUM
!
SMLNUM = TWO*DLAMCH( 'Safe minimum' )
BIGNUM = ONE / SMLNUM
SMINI = MAX( SMIN, SMLNUM )
!
!     Don't check for input errors
!
INFO = 0
!
!     Standard Initializations
!
SCALE = ONE
!
IF( NA.EQ.1 ) THEN
!
!        1 x 1  (i.e., scalar) system   C X = B
!
   IF( NW.EQ.1 ) THEN
!
!           Real 1x1 system.
!
!           C = ca A - w D
!
      CSR = CA*A( 1, 1 ) - WR*D1
      CNORM = ABS( CSR )
!
!           If | C | < SMINI, use C = SMINI
!
      IF( CNORM.LT.SMINI ) THEN
         CSR = SMINI
         CNORM = SMINI
         INFO = 1
      END IF
!
!           Check scaling for  X = B / C
!
      BNORM = ABS( B( 1, 1 ) )
      IF( CNORM.LT.ONE .AND. BNORM.GT.ONE ) THEN
         IF( BNORM.GT.BIGNUM*CNORM ) &
                SCALE = ONE / BNORM
      END IF
!
!           Compute X
!
      X( 1, 1 ) = ( B( 1, 1 )*SCALE ) / CSR
      XNORM = ABS( X( 1, 1 ) )
   ELSE
!
!           Complex 1x1 system (w is complex)
!
!           C = ca A - w D
!
      CSR = CA*A( 1, 1 ) - WR*D1
      CSI = -WI*D1
      CNORM = ABS( CSR ) + ABS( CSI )
!
!           If | C | < SMINI, use C = SMINI
!
      IF( CNORM.LT.SMINI ) THEN
         CSR = SMINI
         CSI = ZERO
         CNORM = SMINI
         INFO = 1
      END IF
!
!           Check scaling for  X = B / C
!
      BNORM = ABS( B( 1, 1 ) ) + ABS( B( 1, 2 ) )
      IF( CNORM.LT.ONE .AND. BNORM.GT.ONE ) THEN
         IF( BNORM.GT.BIGNUM*CNORM ) &
                SCALE = ONE / BNORM
      END IF
!
!           Compute X
!
      CALL DLADIV( SCALE*B( 1, 1 ), SCALE*B( 1, 2 ), CSR, CSI, &
                       X( 1, 1 ), X( 1, 2 ) )
      XNORM = ABS( X( 1, 1 ) ) + ABS( X( 1, 2 ) )
   END IF
!
ELSE
!
!        2x2 System
!
!        Compute the real part of  C = ca A - w D  (or  ca A' - w D )
!
   CR( 1, 1 ) = CA*A( 1, 1 ) - WR*D1
   CR( 2, 2 ) = CA*A( 2, 2 ) - WR*D2
   IF( LTRANS ) THEN
      CR( 1, 2 ) = CA*A( 2, 1 )
      CR( 2, 1 ) = CA*A( 1, 2 )
   ELSE
      CR( 2, 1 ) = CA*A( 2, 1 )
      CR( 1, 2 ) = CA*A( 1, 2 )
   END IF
!
   IF( NW.EQ.1 ) THEN
!
!           Real 2x2 system  (w is real)
!
!           Find the largest element in C
!
      CMAX = ZERO
      ICMAX = 0
!
      DO 10 J = 1, 4
         IF( ABS( CRV( J ) ).GT.CMAX ) THEN
            CMAX = ABS( CRV( J ) )
            ICMAX = J
         END IF
10       CONTINUE
!
!           If norm(C) < SMINI, use SMINI*identity.
!
      IF( CMAX.LT.SMINI ) THEN
         BNORM = MAX( ABS( B( 1, 1 ) ), ABS( B( 2, 1 ) ) )
         IF( SMINI.LT.ONE .AND. BNORM.GT.ONE ) THEN
            IF( BNORM.GT.BIGNUM*SMINI ) &
                   SCALE = ONE / BNORM
         END IF
         TEMP = SCALE / SMINI
         X( 1, 1 ) = TEMP*B( 1, 1 )
         X( 2, 1 ) = TEMP*B( 2, 1 )
         XNORM = TEMP*BNORM
         INFO = 1
         RETURN
      END IF
!
!           Gaussian elimination with complete pivoting.
!
      UR11 = CRV( ICMAX )
      CR21 = CRV( IPIVOT( 2, ICMAX ) )
      UR12 = CRV( IPIVOT( 3, ICMAX ) )
      CR22 = CRV( IPIVOT( 4, ICMAX ) )
      UR11R = ONE / UR11
      LR21 = UR11R*CR21
      UR22 = CR22 - UR12*LR21
!
!           If smaller pivot < SMINI, use SMINI
!
      IF( ABS( UR22 ).LT.SMINI ) THEN
         UR22 = SMINI
         INFO = 1
      END IF
      IF( RSWAP( ICMAX ) ) THEN
         BR1 = B( 2, 1 )
         BR2 = B( 1, 1 )
      ELSE
         BR1 = B( 1, 1 )
         BR2 = B( 2, 1 )
      END IF
      BR2 = BR2 - LR21*BR1
      BBND = MAX( ABS( BR1*( UR22*UR11R ) ), ABS( BR2 ) )
      IF( BBND.GT.ONE .AND. ABS( UR22 ).LT.ONE ) THEN
         IF( BBND.GE.BIGNUM*ABS( UR22 ) ) &
                SCALE = ONE / BBND
      END IF
!
      XR2 = ( BR2*SCALE ) / UR22
      XR1 = ( SCALE*BR1 )*UR11R - XR2*( UR11R*UR12 )
      IF( ZSWAP( ICMAX ) ) THEN
         X( 1, 1 ) = XR2
         X( 2, 1 ) = XR1
      ELSE
         X( 1, 1 ) = XR1
         X( 2, 1 ) = XR2
      END IF
      XNORM = MAX( ABS( XR1 ), ABS( XR2 ) )
!
!           Further scaling if  norm(A) norm(X) > overflow
!
      IF( XNORM.GT.ONE .AND. CMAX.GT.ONE ) THEN
         IF( XNORM.GT.BIGNUM / CMAX ) THEN
            TEMP = CMAX / BIGNUM
            X( 1, 1 ) = TEMP*X( 1, 1 )
            X( 2, 1 ) = TEMP*X( 2, 1 )
            XNORM = TEMP*XNORM
            SCALE = TEMP*SCALE
         END IF
      END IF
   ELSE
!
!           Complex 2x2 system  (w is complex)
!
!           Find the largest element in C
!
      CI( 1, 1 ) = -WI*D1
      CI( 2, 1 ) = ZERO
      CI( 1, 2 ) = ZERO
      CI( 2, 2 ) = -WI*D2
      CMAX = ZERO
      ICMAX = 0
!
      DO 20 J = 1, 4
         IF( ABS( CRV( J ) )+ABS( CIV( J ) ).GT.CMAX ) THEN
            CMAX = ABS( CRV( J ) ) + ABS( CIV( J ) )
            ICMAX = J
         END IF
20       CONTINUE
!
!           If norm(C) < SMINI, use SMINI*identity.
!
      IF( CMAX.LT.SMINI ) THEN
         BNORM = MAX( ABS( B( 1, 1 ) )+ABS( B( 1, 2 ) ), &
                     ABS( B( 2, 1 ) )+ABS( B( 2, 2 ) ) )
         IF( SMINI.LT.ONE .AND. BNORM.GT.ONE ) THEN
            IF( BNORM.GT.BIGNUM*SMINI ) &
                   SCALE = ONE / BNORM
         END IF
         TEMP = SCALE / SMINI
         X( 1, 1 ) = TEMP*B( 1, 1 )
         X( 2, 1 ) = TEMP*B( 2, 1 )
         X( 1, 2 ) = TEMP*B( 1, 2 )
         X( 2, 2 ) = TEMP*B( 2, 2 )
         XNORM = TEMP*BNORM
         INFO = 1
         RETURN
      END IF
!
!           Gaussian elimination with complete pivoting.
!
      UR11 = CRV( ICMAX )
      UI11 = CIV( ICMAX )
      CR21 = CRV( IPIVOT( 2, ICMAX ) )
      CI21 = CIV( IPIVOT( 2, ICMAX ) )
      UR12 = CRV( IPIVOT( 3, ICMAX ) )
      UI12 = CIV( IPIVOT( 3, ICMAX ) )
      CR22 = CRV( IPIVOT( 4, ICMAX ) )
      CI22 = CIV( IPIVOT( 4, ICMAX ) )
      IF( ICMAX.EQ.1 .OR. ICMAX.EQ.4 ) THEN
!
!              Code when off-diagonals of pivoted C are real
!
         IF( ABS( UR11 ).GT.ABS( UI11 ) ) THEN
            TEMP = UI11 / UR11
            UR11R = ONE / ( UR11*( ONE+TEMP**2 ) )
            UI11R = -TEMP*UR11R
         ELSE
            TEMP = UR11 / UI11
            UI11R = -ONE / ( UI11*( ONE+TEMP**2 ) )
            UR11R = -TEMP*UI11R
         END IF
         LR21 = CR21*UR11R
         LI21 = CR21*UI11R
         UR12S = UR12*UR11R
         UI12S = UR12*UI11R
         UR22 = CR22 - UR12*LR21
         UI22 = CI22 - UR12*LI21
      ELSE
!
!              Code when diagonals of pivoted C are real
!
         UR11R = ONE / UR11
         UI11R = ZERO
         LR21 = CR21*UR11R
         LI21 = CI21*UR11R
         UR12S = UR12*UR11R
         UI12S = UI12*UR11R
         UR22 = CR22 - UR12*LR21 + UI12*LI21
         UI22 = -UR12*LI21 - UI12*LR21
      END IF
      U22ABS = ABS( UR22 ) + ABS( UI22 )
!
!           If smaller pivot < SMINI, use SMINI
!
      IF( U22ABS.LT.SMINI ) THEN
         UR22 = SMINI
         UI22 = ZERO
         INFO = 1
      END IF
      IF( RSWAP( ICMAX ) ) THEN
         BR2 = B( 1, 1 )
         BR1 = B( 2, 1 )
         BI2 = B( 1, 2 )
         BI1 = B( 2, 2 )
      ELSE
         BR1 = B( 1, 1 )
         BR2 = B( 2, 1 )
         BI1 = B( 1, 2 )
         BI2 = B( 2, 2 )
      END IF
      BR2 = BR2 - LR21*BR1 + LI21*BI1
      BI2 = BI2 - LI21*BR1 - LR21*BI1
      BBND = MAX( ( ABS( BR1 )+ABS( BI1 ) )* &
                 ( U22ABS*( ABS( UR11R )+ABS( UI11R ) ) ), &
                 ABS( BR2 )+ABS( BI2 ) )
      IF( BBND.GT.ONE .AND. U22ABS.LT.ONE ) THEN
         IF( BBND.GE.BIGNUM*U22ABS ) THEN
            SCALE = ONE / BBND
            BR1 = SCALE*BR1
            BI1 = SCALE*BI1
            BR2 = SCALE*BR2
            BI2 = SCALE*BI2
         END IF
      END IF
!
      CALL DLADIV( BR2, BI2, UR22, UI22, XR2, XI2 )
      XR1 = UR11R*BR1 - UI11R*BI1 - UR12S*XR2 + UI12S*XI2
      XI1 = UI11R*BR1 + UR11R*BI1 - UI12S*XR2 - UR12S*XI2
      IF( ZSWAP( ICMAX ) ) THEN
         X( 1, 1 ) = XR2
         X( 2, 1 ) = XR1
         X( 1, 2 ) = XI2
         X( 2, 2 ) = XI1
      ELSE
         X( 1, 1 ) = XR1
         X( 2, 1 ) = XR2
         X( 1, 2 ) = XI1
         X( 2, 2 ) = XI2
      END IF
      XNORM = MAX( ABS( XR1 )+ABS( XI1 ), ABS( XR2 )+ABS( XI2 ) )
!
!           Further scaling if  norm(A) norm(X) > overflow
!
      IF( XNORM.GT.ONE .AND. CMAX.GT.ONE ) THEN
         IF( XNORM.GT.BIGNUM / CMAX ) THEN
            TEMP = CMAX / BIGNUM
            X( 1, 1 ) = TEMP*X( 1, 1 )
            X( 2, 1 ) = TEMP*X( 2, 1 )
            X( 1, 2 ) = TEMP*X( 1, 2 )
            X( 2, 2 ) = TEMP*X( 2, 2 )
            XNORM = TEMP*XNORM
            SCALE = TEMP*SCALE
         END IF
      END IF
   END IF
END IF
!
RETURN
!
!     End of DLALN2
!
end subroutine dlaln2

! ===== End dlaln2.f90 =====


! ===== Begin dlamch.f90 =====

DOUBLE PRECISION FUNCTION DLAMCH( CMACH )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
CHARACTER          CMACH
!     ..
!
!  Purpose
!  =======
!
!  DLAMCH determines double precision machine parameters.
!
!  Arguments
!  =========
!
!  CMACH   (input) CHARACTER*1
!          Specifies the value to be returned by DLAMCH:
!          = 'E' or 'e',   DLAMCH := eps
!          = 'S' or 's ,   DLAMCH := sfmin
!          = 'B' or 'b',   DLAMCH := base
!          = 'P' or 'p',   DLAMCH := eps*base
!          = 'N' or 'n',   DLAMCH := t
!          = 'R' or 'r',   DLAMCH := rnd
!          = 'M' or 'm',   DLAMCH := emin
!          = 'U' or 'u',   DLAMCH := rmin
!          = 'L' or 'l',   DLAMCH := emax
!          = 'O' or 'o',   DLAMCH := rmax
!
!          where
!
!          eps   = relative machine precision
!          sfmin = safe minimum, such that 1/sfmin does not overflow
!          base  = base of the machine
!          prec  = eps*base
!          t     = number of (base) digits in the mantissa
!          rnd   = 1.0 when rounding occurs in addition, 0.0 otherwise
!          emin  = minimum exponent before (gradual) underflow
!          rmin  = underflow threshold - base**(emin-1)
!          emax  = largest exponent before overflow
!          rmax  = overflow threshold  - (base**emax)*(1-eps)
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            FIRST, LRND
INTEGER            BETA, IMAX, IMIN, IT
DOUBLE PRECISION   BASE, EMAX, EMIN, EPS, PREC, RMACH, RMAX, RMIN, &
                       RND, SFMIN, SMALL, T
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DLAMC2
!     ..
!     .. Save statement ..
SAVE               FIRST, EPS, SFMIN, BASE, T, RND, EMIN, RMIN, &
                       EMAX, RMAX, PREC
!     ..
!     .. Data statements ..
DATA               FIRST / .TRUE. /
!     ..
!     .. Executable Statements ..
!
IF( FIRST ) THEN
   FIRST = .FALSE.
   CALL DLAMC2( BETA, IT, LRND, EPS, IMIN, RMIN, IMAX, RMAX )
   BASE = BETA
   T = IT
   IF( LRND ) THEN
      RND = ONE
      EPS = ( BASE**( 1-IT ) ) / 2
   ELSE
      RND = ZERO
      EPS = BASE**( 1-IT )
   END IF
   PREC = EPS*BASE
   EMIN = IMIN
   EMAX = IMAX
   SFMIN = RMIN
   SMALL = ONE / RMAX
   IF( SMALL.GE.SFMIN ) THEN
!
!           Use SMALL plus a bit, to avoid the possibility of rounding
!           causing overflow when computing  1/sfmin.
!
      SFMIN = SMALL*( ONE+EPS )
   END IF
END IF
!
IF( LSAME( CMACH, 'E' ) ) THEN
   RMACH = EPS
ELSE IF( LSAME( CMACH, 'S' ) ) THEN
   RMACH = SFMIN
ELSE IF( LSAME( CMACH, 'B' ) ) THEN
   RMACH = BASE
ELSE IF( LSAME( CMACH, 'P' ) ) THEN
   RMACH = PREC
ELSE IF( LSAME( CMACH, 'N' ) ) THEN
   RMACH = T
ELSE IF( LSAME( CMACH, 'R' ) ) THEN
   RMACH = RND
ELSE IF( LSAME( CMACH, 'M' ) ) THEN
   RMACH = EMIN
ELSE IF( LSAME( CMACH, 'U' ) ) THEN
   RMACH = RMIN
ELSE IF( LSAME( CMACH, 'L' ) ) THEN
   RMACH = EMAX
ELSE IF( LSAME( CMACH, 'O' ) ) THEN
   RMACH = RMAX
END IF
!
DLAMCH = RMACH
RETURN
!
!     End of DLAMCH
!
end function dlamch
!
!***********************************************************************
!
SUBROUTINE DLAMC1( BETA, T, RND, IEEE1 )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
LOGICAL            IEEE1, RND
INTEGER            BETA, T
!     ..
!
!  Purpose
!  =======
!
!  DLAMC1 determines the machine parameters given by BETA, T, RND, and
!  IEEE1.
!
!  Arguments
!  =========
!
!  BETA    (output) INTEGER
!          The base of the machine.
!
!  T       (output) INTEGER
!          The number of ( BETA ) digits in the mantissa.
!
!  RND     (output) LOGICAL
!          Specifies whether proper rounding  ( RND = .TRUE. )  or
!          chopping  ( RND = .FALSE. )  occurs in addition. This may not
!          be a reliable guide to the way in which the machine performs
!          its arithmetic.
!
!  IEEE1   (output) LOGICAL
!          Specifies whether rounding appears to be done in the IEEE
!          'round to nearest' style.
!
!  Further Details
!  ===============
!
!  The routine is based on the routine  ENVRON  by Malcolm and
!  incorporates suggestions by Gentleman and Marovich. See
!
!     Malcolm M. A. (1972) Algorithms to reveal properties of
!        floating-point arithmetic. Comms. of the ACM, 15, 949-951.
!
!     Gentleman W. M. and Marovich S. B. (1974) More on algorithms
!        that reveal properties of floating point arithmetic units.
!        Comms. of the ACM, 17, 276-277.
!
! =====================================================================
!
!     .. Local Scalars ..
LOGICAL            FIRST, LIEEE1, LRND
INTEGER            LBETA, LT
DOUBLE PRECISION   A, B, C, F, ONE, QTR, SAVEC, T1, T2
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMC3
EXTERNAL           DLAMC3
!     ..
!     .. Save statement ..
SAVE               FIRST, LIEEE1, LBETA, LRND, LT
!     ..
!     .. Data statements ..
DATA               FIRST / .TRUE. /
!     ..
!     .. Executable Statements ..
!
IF( FIRST ) THEN
   FIRST = .FALSE.
   ONE = 1
!
!        LBETA,  LIEEE1,  LT and  LRND  are the  local values  of  BETA,
!        IEEE1, T and RND.
!
!        Throughout this routine  we use the function  DLAMC3  to ensure
!        that relevant values are  stored and not held in registers,  or
!        are not affected by optimizers.
!
!        Compute  a = 2.0**m  with the  smallest positive integer m such
!        that
!
!           fl( a + 1.0 ) = a.
!
   A = 1
   C = 1
!
!+       WHILE( C.EQ.ONE )LOOP
10    CONTINUE
   IF( C.EQ.ONE ) THEN
      A = 2*A
      C = DLAMC3( A, ONE )
      C = DLAMC3( C, -A )
      GO TO 10
   END IF
!+       END WHILE
!
!        Now compute  b = 2.0**m  with the smallest positive integer m
!        such that
!
!           fl( a + b ) .gt. a.
!
   B = 1
   C = DLAMC3( A, B )
!
!+       WHILE( C.EQ.A )LOOP
20    CONTINUE
   IF( C.EQ.A ) THEN
      B = 2*B
      C = DLAMC3( A, B )
      GO TO 20
   END IF
!+       END WHILE
!
!        Now compute the base.  a and c  are neighbouring floating point
!        numbers  in the  interval  ( beta**t, beta**( t + 1 ) )  and so
!        their difference is beta. Adding 0.25 to c is to ensure that it
!        is truncated to beta and not ( beta - 1 ).
!
   QTR = ONE / 4
   SAVEC = C
   C = DLAMC3( C, -A )
   LBETA = C + QTR
!
!        Now determine whether rounding or chopping occurs,  by adding a
!        bit  less  than  beta/2  and a  bit  more  than  beta/2  to  a.
!
   B = LBETA
   F = DLAMC3( B / 2, -B / 100 )
   C = DLAMC3( F, A )
   IF( C.EQ.A ) THEN
      LRND = .TRUE.
   ELSE
      LRND = .FALSE.
   END IF
   F = DLAMC3( B / 2, B / 100 )
   C = DLAMC3( F, A )
   IF( ( LRND ) .AND. ( C.EQ.A ) ) &
          LRND = .FALSE.
!
!        Try and decide whether rounding is done in the  IEEE  'round to
!        nearest' style. B/2 is half a unit in the last place of the two
!        numbers A and SAVEC. Furthermore, A is even, i.e. has last  bit
!        zero, and SAVEC is odd. Thus adding B/2 to A should not  change
!        A, but adding B/2 to SAVEC should change SAVEC.
!
   T1 = DLAMC3( B / 2, A )
   T2 = DLAMC3( B / 2, SAVEC )
   LIEEE1 = ( T1.EQ.A ) .AND. ( T2.GT.SAVEC ) .AND. LRND
!
!        Now find  the  mantissa, t.  It should  be the  integer part of
!        log to the base beta of a,  however it is safer to determine  t
!        by powering.  So we find t as the smallest positive integer for
!        which
!
!           fl( beta**t + 1.0 ) = 1.0.
!
   LT = 0
   A = 1
   C = 1
!
!+       WHILE( C.EQ.ONE )LOOP
30    CONTINUE
   IF( C.EQ.ONE ) THEN
      LT = LT + 1
      A = A*LBETA
      C = DLAMC3( A, ONE )
      C = DLAMC3( C, -A )
      GO TO 30
   END IF
!+       END WHILE
!
END IF
!
BETA = LBETA
T = LT
RND = LRND
IEEE1 = LIEEE1
RETURN
!
!     End of DLAMC1
!
end subroutine dlamc1
!
!***********************************************************************
!
SUBROUTINE DLAMC2( BETA, T, RND, EPS, EMIN, RMIN, EMAX, RMAX )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
LOGICAL            RND
INTEGER            BETA, EMAX, EMIN, T
DOUBLE PRECISION   EPS, RMAX, RMIN
!     ..
!
!  Purpose
!  =======
!
!  DLAMC2 determines the machine parameters specified in its argument
!  list.
!
!  Arguments
!  =========
!
!  BETA    (output) INTEGER
!          The base of the machine.
!
!  T       (output) INTEGER
!          The number of ( BETA ) digits in the mantissa.
!
!  RND     (output) LOGICAL
!          Specifies whether proper rounding  ( RND = .TRUE. )  or
!          chopping  ( RND = .FALSE. )  occurs in addition. This may not
!          be a reliable guide to the way in which the machine performs
!          its arithmetic.
!
!  EPS     (output) DOUBLE PRECISION
!          The smallest positive number such that
!
!             fl( 1.0 - EPS ) .LT. 1.0,
!
!          where fl denotes the computed value.
!
!  EMIN    (output) INTEGER
!          The minimum exponent before (gradual) underflow occurs.
!
!  RMIN    (output) DOUBLE PRECISION
!          The smallest normalized number for the machine, given by
!          BASE**( EMIN - 1 ), where  BASE  is the floating point value
!          of BETA.
!
!  EMAX    (output) INTEGER
!          The maximum exponent before overflow occurs.
!
!  RMAX    (output) DOUBLE PRECISION
!          The largest positive number for the machine, given by
!          BASE**EMAX * ( 1 - EPS ), where  BASE  is the floating point
!          value of BETA.
!
!  Further Details
!  ===============
!
!  The computation of  EPS  is based on a routine PARANOIA by
!  W. Kahan of the University of California at Berkeley.
!
! =====================================================================
!
!     .. Local Scalars ..
LOGICAL            FIRST, IEEE, IWARN, LIEEE1, LRND
INTEGER            GNMIN, GPMIN, I, LBETA, LEMAX, LEMIN, LT, &
                       NGNMIN, NGPMIN
DOUBLE PRECISION   A, B, C, HALF, LEPS, LRMAX, LRMIN, ONE, RBASE, &
                       SIXTH, SMALL, THIRD, TWO, ZERO
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMC3
EXTERNAL           DLAMC3
!     ..
!     .. External Subroutines ..
EXTERNAL           DLAMC1, DLAMC4, DLAMC5
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN
!     ..
!     .. Save statement ..
SAVE               FIRST, IWARN, LBETA, LEMAX, LEMIN, LEPS, LRMAX, &
                       LRMIN, LT
!     ..
!     .. Data statements ..
DATA               FIRST / .TRUE. / , IWARN / .FALSE. /
!     ..
!     .. Executable Statements ..
!
IF( FIRST ) THEN
   FIRST = .FALSE.
   ZERO = 0
   ONE = 1
   TWO = 2
!
!        LBETA, LT, LRND, LEPS, LEMIN and LRMIN  are the local values of
!        BETA, T, RND, EPS, EMIN and RMIN.
!
!        Throughout this routine  we use the function  DLAMC3  to ensure
!        that relevant values are stored  and not held in registers,  or
!        are not affected by optimizers.
!
!        DLAMC1 returns the parameters  LBETA, LT, LRND and LIEEE1.
!
   CALL DLAMC1( LBETA, LT, LRND, LIEEE1 )
!
!        Start to find EPS.
!
   B = LBETA
   A = B**( -LT )
   LEPS = A
!
!        Try some tricks to see whether or not this is the correct  EPS.
!
   B = TWO / 3
   HALF = ONE / 2
   SIXTH = DLAMC3( B, -HALF )
   THIRD = DLAMC3( SIXTH, SIXTH )
   B = DLAMC3( THIRD, -HALF )
   B = DLAMC3( B, SIXTH )
   B = ABS( B )
   IF( B.LT.LEPS ) &
          B = LEPS
!
   LEPS = 1
!
!+       WHILE( ( LEPS.GT.B ).AND.( B.GT.ZERO ) )LOOP
10    CONTINUE
   IF( ( LEPS.GT.B ) .AND. ( B.GT.ZERO ) ) THEN
      LEPS = B
      C = DLAMC3( HALF*LEPS, ( TWO**5 )*( LEPS**2 ) )
      C = DLAMC3( HALF, -C )
      B = DLAMC3( HALF, C )
      C = DLAMC3( HALF, -B )
      B = DLAMC3( HALF, C )
      GO TO 10
   END IF
!+       END WHILE
!
   IF( A.LT.LEPS ) &
          LEPS = A
!
!        Computation of EPS complete.
!
!        Now find  EMIN.  Let A = + or - 1, and + or - (1 + BASE**(-3)).
!        Keep dividing  A by BETA until (gradual) underflow occurs. This
!        is detected when we cannot recover the previous A.
!
   RBASE = ONE / LBETA
   SMALL = ONE
   DO 20 I = 1, 3
      SMALL = DLAMC3( SMALL*RBASE, ZERO )
20    CONTINUE
   A = DLAMC3( ONE, SMALL )
   CALL DLAMC4( NGPMIN, ONE, LBETA )
   CALL DLAMC4( NGNMIN, -ONE, LBETA )
   CALL DLAMC4( GPMIN, A, LBETA )
   CALL DLAMC4( GNMIN, -A, LBETA )
   IEEE = .FALSE.
!
   IF( ( NGPMIN.EQ.NGNMIN ) .AND. ( GPMIN.EQ.GNMIN ) ) THEN
      IF( NGPMIN.EQ.GPMIN ) THEN
         LEMIN = NGPMIN
!            ( Non twos-complement machines, no gradual underflow;
!              e.g.,  VAX )
      ELSE IF( ( GPMIN-NGPMIN ).EQ.3 ) THEN
         LEMIN = NGPMIN - 1 + LT
         IEEE = .TRUE.
!            ( Non twos-complement machines, with gradual underflow;
!              e.g., IEEE standard followers )
      ELSE
         LEMIN = MIN( NGPMIN, GPMIN )
!            ( A guess; no known machine )
         IWARN = .TRUE.
      END IF
!
   ELSE IF( ( NGPMIN.EQ.GPMIN ) .AND. ( NGNMIN.EQ.GNMIN ) ) THEN
      IF( ABS( NGPMIN-NGNMIN ).EQ.1 ) THEN
         LEMIN = MAX( NGPMIN, NGNMIN )
!            ( Twos-complement machines, no gradual underflow;
!              e.g., CYBER 205 )
      ELSE
         LEMIN = MIN( NGPMIN, NGNMIN )
!            ( A guess; no known machine )
         IWARN = .TRUE.
      END IF
!
   ELSE IF( ( ABS( NGPMIN-NGNMIN ).EQ.1 ) .AND. &
                ( GPMIN.EQ.GNMIN ) ) THEN
      IF( ( GPMIN-MIN( NGPMIN, NGNMIN ) ).EQ.3 ) THEN
         LEMIN = MAX( NGPMIN, NGNMIN ) - 1 + LT
!            ( Twos-complement machines with gradual underflow;
!              no known machine )
      ELSE
         LEMIN = MIN( NGPMIN, NGNMIN )
!            ( A guess; no known machine )
         IWARN = .TRUE.
      END IF
!
   ELSE
      LEMIN = MIN( NGPMIN, NGNMIN, GPMIN, GNMIN )
!         ( A guess; no known machine )
      IWARN = .TRUE.
   END IF
!**
! Comment out this if block if EMIN is ok
   IF( IWARN ) THEN
      FIRST = .TRUE.
      WRITE( 6, FMT = 9999 )LEMIN
   END IF
!**
!
!        Assume IEEE arithmetic if we found denormalised  numbers above,
!        or if arithmetic seems to round in the  IEEE style,  determined
!        in routine DLAMC1. A true IEEE machine should have both  things
!        true; however, faulty machines may have one or the other.
!
   IEEE = IEEE .OR. LIEEE1
!
!        Compute  RMIN by successive division by  BETA. We could compute
!        RMIN as BASE**( EMIN - 1 ),  but some machines underflow during
!        this computation.
!
   LRMIN = 1
   DO 30 I = 1, 1 - LEMIN
      LRMIN = DLAMC3( LRMIN*RBASE, ZERO )
30    CONTINUE
!
!        Finally, call DLAMC5 to compute EMAX and RMAX.
!
   CALL DLAMC5( LBETA, LT, LEMIN, IEEE, LEMAX, LRMAX )
END IF
!
BETA = LBETA
T = LT
RND = LRND
EPS = LEPS
EMIN = LEMIN
RMIN = LRMIN
EMAX = LEMAX
RMAX = LRMAX
!
RETURN
!
9999 FORMAT( / / ' WARNING. The value EMIN may be incorrect:-', &
          '  EMIN = ', I8, / &
          ' If, after inspection, the value EMIN looks', &
          ' acceptable please comment out ', &
          / ' the IF block as marked within the code of routine', &
          ' DLAMC2,', / ' otherwise supply EMIN explicitly.', / )
!
!     End of DLAMC2
!
end subroutine dlamc2
!
!***********************************************************************
!
DOUBLE PRECISION FUNCTION DLAMC3( A, B )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   A, B
!     ..
!
!  Purpose
!  =======
!
!  DLAMC3  is intended to force  A  and  B  to be stored prior to doing
!  the addition of  A  and  B ,  for use in situations where optimizers
!  might hold one of these in a register.
!
!  Arguments
!  =========
!
!  A, B    (input) DOUBLE PRECISION
!          The values A and B.
!
! =====================================================================
!
!     .. Executable Statements ..
!
DLAMC3 = A + B
!
RETURN
!
!     End of DLAMC3
!
end function dlamc3
!
!***********************************************************************
!
SUBROUTINE DLAMC4( EMIN, START, BASE )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
INTEGER            BASE, EMIN
DOUBLE PRECISION   START
!     ..
!
!  Purpose
!  =======
!
!  DLAMC4 is a service routine for DLAMC2.
!
!  Arguments
!  =========
!
!  EMIN    (output) EMIN
!          The minimum exponent before (gradual) underflow, computed by
!          setting A = START and dividing by BASE until the previous A
!          can not be recovered.
!
!  START   (input) DOUBLE PRECISION
!          The starting point for determining EMIN.
!
!  BASE    (input) INTEGER
!          The base of the machine.
!
! =====================================================================
!
!     .. Local Scalars ..
INTEGER            I
DOUBLE PRECISION   A, B1, B2, C1, C2, D1, D2, ONE, RBASE, ZERO
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMC3
EXTERNAL           DLAMC3
!     ..
!     .. Executable Statements ..
!
A = START
ONE = 1
RBASE = ONE / BASE
ZERO = 0
EMIN = 1
B1 = DLAMC3( A*RBASE, ZERO )
C1 = A
C2 = A
D1 = A
D2 = A
!+    WHILE( ( C1.EQ.A ).AND.( C2.EQ.A ).AND.
!    $       ( D1.EQ.A ).AND.( D2.EQ.A )      )LOOP
10 CONTINUE
IF( ( C1.EQ.A ) .AND. ( C2.EQ.A ) .AND. ( D1.EQ.A ) .AND. &
        ( D2.EQ.A ) ) THEN
   EMIN = EMIN - 1
   A = B1
   B1 = DLAMC3( A / BASE, ZERO )
   C1 = DLAMC3( B1*BASE, ZERO )
   D1 = ZERO
   DO 20 I = 1, BASE
      D1 = D1 + B1
20    CONTINUE
   B2 = DLAMC3( A*RBASE, ZERO )
   C2 = DLAMC3( B2 / RBASE, ZERO )
   D2 = ZERO
   DO 30 I = 1, BASE
      D2 = D2 + B2
30    CONTINUE
   GO TO 10
END IF
!+    END WHILE
!
RETURN
!
!     End of DLAMC4
!
end subroutine dlamc4
!
!***********************************************************************
!
SUBROUTINE DLAMC5( BETA, P, EMIN, IEEE, EMAX, RMAX )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
LOGICAL            IEEE
INTEGER            BETA, EMAX, EMIN, P
DOUBLE PRECISION   RMAX
!     ..
!
!  Purpose
!  =======
!
!  DLAMC5 attempts to compute RMAX, the largest machine floating-point
!  number, without overflow.  It assumes that EMAX + abs(EMIN) sum
!  approximately to a power of 2.  It will fail on machines where this
!  assumption does not hold, for example, the Cyber 205 (EMIN = -28625,
!  EMAX = 28718).  It will also fail if the value supplied for EMIN is
!  too large (i.e. too close to zero), probably with overflow.
!
!  Arguments
!  =========
!
!  BETA    (input) INTEGER
!          The base of floating-point arithmetic.
!
!  P       (input) INTEGER
!          The number of base BETA digits in the mantissa of a
!          floating-point value.
!
!  EMIN    (input) INTEGER
!          The minimum exponent before (gradual) underflow.
!
!  IEEE    (input) LOGICAL
!          A logical flag specifying whether or not the arithmetic
!          system is thought to comply with the IEEE standard.
!
!  EMAX    (output) INTEGER
!          The largest exponent before overflow
!
!  RMAX    (output) DOUBLE PRECISION
!          The largest machine floating-point number.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D0, ONE = 1.0D0 )
!     ..
!     .. Local Scalars ..
INTEGER            EXBITS, EXPSUM, I, LEXP, NBITS, TRY, UEXP
DOUBLE PRECISION   OLDY, RECBAS, Y, Z
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMC3
EXTERNAL           DLAMC3
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MOD
!     ..
!     .. Executable Statements ..
!
!     First compute LEXP and UEXP, two powers of 2 that bound
!     abs(EMIN). We then assume that EMAX + abs(EMIN) will sum
!     approximately to the bound that is closest to abs(EMIN).
!     (EMAX is the exponent of the required number RMAX).
!
LEXP = 1
EXBITS = 1
10 CONTINUE
TRY = LEXP*2
IF( TRY.LE.( -EMIN ) ) THEN
   LEXP = TRY
   EXBITS = EXBITS + 1
   GO TO 10
END IF
IF( LEXP.EQ.-EMIN ) THEN
   UEXP = LEXP
ELSE
   UEXP = TRY
   EXBITS = EXBITS + 1
END IF
!
!     Now -LEXP is less than or equal to EMIN, and -UEXP is greater
!     than or equal to EMIN. EXBITS is the number of bits needed to
!     store the exponent.
!
IF( ( UEXP+EMIN ).GT.( -LEXP-EMIN ) ) THEN
   EXPSUM = 2*LEXP
ELSE
   EXPSUM = 2*UEXP
END IF
!
!     EXPSUM is the exponent range, approximately equal to
!     EMAX - EMIN + 1 .
!
EMAX = EXPSUM + EMIN - 1
NBITS = 1 + EXBITS + P
!
!     NBITS is the total number of bits needed to store a
!     floating-point number.
!
IF( ( MOD( NBITS, 2 ).EQ.1 ) .AND. ( BETA.EQ.2 ) ) THEN
!
!        Either there are an odd number of bits used to store a
!        floating-point number, which is unlikely, or some bits are
!        not used in the representation of numbers, which is possible,
!        (e.g. Cray machines) or the mantissa has an implicit bit,
!        (e.g. IEEE machines, Dec Vax machines), which is perhaps the
!        most likely. We have to assume the last alternative.
!        If this is true, then we need to reduce EMAX by one because
!        there must be some way of representing zero in an implicit-bit
!        system. On machines like Cray, we are reducing EMAX by one
!        unnecessarily.
!
   EMAX = EMAX - 1
END IF
!
IF( IEEE ) THEN
!
!        Assume we are on an IEEE machine which reserves one exponent
!        for infinity and NaN.
!
   EMAX = EMAX - 1
END IF
!
!     Now create RMAX, the largest machine number, which should
!     be equal to (1.0 - BETA**(-P)) * BETA**EMAX .
!
!     First compute 1.0 - BETA**(-P), being careful that the
!     result is less than 1.0 .
!
RECBAS = ONE / BETA
Z = BETA - ONE
Y = ZERO
DO 20 I = 1, P
   Z = Z*RECBAS
   IF( Y.LT.ONE ) &
          OLDY = Y
   Y = DLAMC3( Y, Z )
20 CONTINUE
IF( Y.GE.ONE ) &
       Y = OLDY
!
!     Now multiply by BETA**EMAX to get RMAX.
!
DO 30 I = 1, EMAX
   Y = DLAMC3( Y*BETA, ZERO )
30 CONTINUE
!
RMAX = Y
RETURN
!
!     End of DLAMC5
!
end subroutine dlamc5

! ===== End dlamch.f90 =====


! ===== Begin dlange.f90 =====

DOUBLE PRECISION FUNCTION DLANGE( NORM, M, N, A, LDA, WORK )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
CHARACTER          NORM
INTEGER            LDA, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DLANGE  returns the value of the one norm,  or the Frobenius norm, or
!  the  infinity norm,  or the  element of  largest absolute value  of a
!  real matrix A.
!
!  Description
!  ===========
!
!  DLANGE returns the value
!
!     DLANGE = ( max(abs(A(i,j))), NORM = 'M' or 'm'
!              (
!              ( norm1(A),         NORM = '1', 'O' or 'o'
!              (
!              ( normI(A),         NORM = 'I' or 'i'
!              (
!              ( normF(A),         NORM = 'F', 'f', 'E' or 'e'
!
!  where  norm1  denotes the  one norm of a matrix (maximum column sum),
!  normI  denotes the  infinity norm  of a matrix  (maximum row sum) and
!  normF  denotes the  Frobenius norm of a matrix (square root of sum of
!  squares).  Note that  max(abs(A(i,j)))  is not a  matrix norm.
!
!  Arguments
!  =========
!
!  NORM    (input) CHARACTER*1
!          Specifies the value to be returned in DLANGE as described
!          above.
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.  When M = 0,
!          DLANGE is set to zero.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.  When N = 0,
!          DLANGE is set to zero.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
!          The m by n matrix A.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(M,1).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (LWORK),
!          where LWORK >= M when NORM = 'I'; otherwise, WORK is not
!          referenced.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, J
DOUBLE PRECISION   SCALE, SUM, VALUE
!     ..
!     .. External Subroutines ..
EXTERNAL           DLASSQ
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN, SQRT
!     ..
!     .. Executable Statements ..
!
IF( MIN( M, N ).EQ.0 ) THEN
   VALUE = ZERO
ELSE IF( LSAME( NORM, 'M' ) ) THEN
!
!        Find max(abs(A(i,j))).
!
   VALUE = ZERO
   DO 20 J = 1, N
      DO 10 I = 1, M
         VALUE = MAX( VALUE, ABS( A( I, J ) ) )
10       CONTINUE
20    CONTINUE
ELSE IF( ( LSAME( NORM, 'O' ) ) .OR. ( NORM.EQ.'1' ) ) THEN
!
!        Find norm1(A).
!
   VALUE = ZERO
   DO 40 J = 1, N
      SUM = ZERO
      DO 30 I = 1, M
         SUM = SUM + ABS( A( I, J ) )
30       CONTINUE
      VALUE = MAX( VALUE, SUM )
40    CONTINUE
ELSE IF( LSAME( NORM, 'I' ) ) THEN
!
!        Find normI(A).
!
   DO 50 I = 1, M
      WORK( I ) = ZERO
50    CONTINUE
   DO 70 J = 1, N
      DO 60 I = 1, M
         WORK( I ) = WORK( I ) + ABS( A( I, J ) )
60       CONTINUE
70    CONTINUE
   VALUE = ZERO
   DO 80 I = 1, M
      VALUE = MAX( VALUE, WORK( I ) )
80    CONTINUE
ELSE IF( ( LSAME( NORM, 'F' ) ) .OR. ( LSAME( NORM, 'E' ) ) ) THEN
!
!        Find normF(A).
!
   SCALE = ZERO
   SUM = ONE
   DO 90 J = 1, N
      CALL DLASSQ( M, A( 1, J ), 1, SCALE, SUM )
90    CONTINUE
   VALUE = SCALE*SQRT( SUM )
END IF
!
DLANGE = VALUE
RETURN
!
!     End of DLANGE
!
end function dlange

! ===== End dlange.f90 =====


! ===== Begin dlanhs.f90 =====

DOUBLE PRECISION FUNCTION DLANHS( NORM, N, A, LDA, WORK )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
CHARACTER          NORM
INTEGER            LDA, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DLANHS  returns the value of the one norm,  or the Frobenius norm, or
!  the  infinity norm,  or the  element of  largest absolute value  of a
!  Hessenberg matrix A.
!
!  Description
!  ===========
!
!  DLANHS returns the value
!
!     DLANHS = ( max(abs(A(i,j))), NORM = 'M' or 'm'
!              (
!              ( norm1(A),         NORM = '1', 'O' or 'o'
!              (
!              ( normI(A),         NORM = 'I' or 'i'
!              (
!              ( normF(A),         NORM = 'F', 'f', 'E' or 'e'
!
!  where  norm1  denotes the  one norm of a matrix (maximum column sum),
!  normI  denotes the  infinity norm  of a matrix  (maximum row sum) and
!  normF  denotes the  Frobenius norm of a matrix (square root of sum of
!  squares).  Note that  max(abs(A(i,j)))  is not a  matrix norm.
!
!  Arguments
!  =========
!
!  NORM    (input) CHARACTER*1
!          Specifies the value to be returned in DLANHS as described
!          above.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.  When N = 0, DLANHS is
!          set to zero.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
!          The n by n upper Hessenberg matrix A; the part of A below the
!          first sub-diagonal is not referenced.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(N,1).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (LWORK),
!          where LWORK >= N when NORM = 'I'; otherwise, WORK is not
!          referenced.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, J
DOUBLE PRECISION   SCALE, SUM, VALUE
!     ..
!     .. External Subroutines ..
EXTERNAL           DLASSQ
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN, SQRT
!     ..
!     .. Executable Statements ..
!
IF( N.EQ.0 ) THEN
   VALUE = ZERO
ELSE IF( LSAME( NORM, 'M' ) ) THEN
!
!        Find max(abs(A(i,j))).
!
   VALUE = ZERO
   DO 20 J = 1, N
      DO 10 I = 1, MIN( N, J+1 )
         VALUE = MAX( VALUE, ABS( A( I, J ) ) )
10       CONTINUE
20    CONTINUE
ELSE IF( ( LSAME( NORM, 'O' ) ) .OR. ( NORM.EQ.'1' ) ) THEN
!
!        Find norm1(A).
!
   VALUE = ZERO
   DO 40 J = 1, N
      SUM = ZERO
      DO 30 I = 1, MIN( N, J+1 )
         SUM = SUM + ABS( A( I, J ) )
30       CONTINUE
      VALUE = MAX( VALUE, SUM )
40    CONTINUE
ELSE IF( LSAME( NORM, 'I' ) ) THEN
!
!        Find normI(A).
!
   DO 50 I = 1, N
      WORK( I ) = ZERO
50    CONTINUE
   DO 70 J = 1, N
      DO 60 I = 1, MIN( N, J+1 )
         WORK( I ) = WORK( I ) + ABS( A( I, J ) )
60       CONTINUE
70    CONTINUE
   VALUE = ZERO
   DO 80 I = 1, N
      VALUE = MAX( VALUE, WORK( I ) )
80    CONTINUE
ELSE IF( ( LSAME( NORM, 'F' ) ) .OR. ( LSAME( NORM, 'E' ) ) ) THEN
!
!        Find normF(A).
!
   SCALE = ZERO
   SUM = ONE
   DO 90 J = 1, N
      CALL DLASSQ( MIN( N, J+1 ), A( 1, J ), 1, SCALE, SUM )
90    CONTINUE
   VALUE = SCALE*SQRT( SUM )
END IF
!
DLANHS = VALUE
RETURN
!
!     End of DLANHS
!
end function dlanhs

! ===== End dlanhs.f90 =====


! ===== Begin dlansb.f90 =====

DOUBLE PRECISION FUNCTION DLANSB( NORM, UPLO, N, K, AB, LDAB, &
                     WORK )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
CHARACTER          NORM, UPLO
INTEGER            K, LDAB, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   AB( LDAB, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DLANSB  returns the value of the one norm,  or the Frobenius norm, or
!  the  infinity norm,  or the element of  largest absolute value  of an
!  n by n symmetric band matrix A,  with k super-diagonals.
!
!  Description
!  ===========
!
!  DLANSB returns the value
!
!     DLANSB = ( max(abs(A(i,j))), NORM = 'M' or 'm'
!              (
!              ( norm1(A),         NORM = '1', 'O' or 'o'
!              (
!              ( normI(A),         NORM = 'I' or 'i'
!              (
!              ( normF(A),         NORM = 'F', 'f', 'E' or 'e'
!
!  where  norm1  denotes the  one norm of a matrix (maximum column sum),
!  normI  denotes the  infinity norm  of a matrix  (maximum row sum) and
!  normF  denotes the  Frobenius norm of a matrix (square root of sum of
!  squares).  Note that  max(abs(A(i,j)))  is not a  matrix norm.
!
!  Arguments
!  =========
!
!  NORM    (input) CHARACTER*1
!          Specifies the value to be returned in DLANSB as described
!          above.
!
!  UPLO    (input) CHARACTER*1
!          Specifies whether the upper or lower triangular part of the
!          band matrix A is supplied.
!          = 'U':  Upper triangular part is supplied
!          = 'L':  Lower triangular part is supplied
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.  When N = 0, DLANSB is
!          set to zero.
!
!  K       (input) INTEGER
!          The number of super-diagonals or sub-diagonals of the
!          band matrix A.  K >= 0.
!
!  AB      (input) DOUBLE PRECISION array, dimension (LDAB,N)
!          The upper or lower triangle of the symmetric band matrix A,
!          stored in the first K+1 rows of AB.  The j-th column of A is
!          stored in the j-th column of the array AB as follows:
!          if UPLO = 'U', AB(k+1+i-j,j) = A(i,j) for max(1,j-k)<=i<=j;
!          if UPLO = 'L', AB(1+i-j,j)   = A(i,j) for j<=i<=min(n,j+k).
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= K+1.
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (LWORK),
!          where LWORK >= N when NORM = 'I' or '1' or 'O'; otherwise,
!          WORK is not referenced.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, J, L
DOUBLE PRECISION   ABSA, SCALE, SUM, VALUE
!     ..
!     .. External Subroutines ..
EXTERNAL           DLASSQ
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN, SQRT
!     ..
!     .. Executable Statements ..
!
IF( N.EQ.0 ) THEN
   VALUE = ZERO
ELSE IF( LSAME( NORM, 'M' ) ) THEN
!
!        Find max(abs(A(i,j))).
!
   VALUE = ZERO
   IF( LSAME( UPLO, 'U' ) ) THEN
      DO 20 J = 1, N
         DO 10 I = MAX( K+2-J, 1 ), K + 1
            VALUE = MAX( VALUE, ABS( AB( I, J ) ) )
10          CONTINUE
20       CONTINUE
   ELSE
      DO 40 J = 1, N
         DO 30 I = 1, MIN( N+1-J, K+1 )
            VALUE = MAX( VALUE, ABS( AB( I, J ) ) )
30          CONTINUE
40       CONTINUE
   END IF
ELSE IF( ( LSAME( NORM, 'I' ) ) .OR. ( LSAME( NORM, 'O' ) ) .OR. &
             ( NORM.EQ.'1' ) ) THEN
!
!        Find normI(A) ( = norm1(A), since A is symmetric).
!
   VALUE = ZERO
   IF( LSAME( UPLO, 'U' ) ) THEN
      DO 60 J = 1, N
         SUM = ZERO
         L = K + 1 - J
         DO 50 I = MAX( 1, J-K ), J - 1
            ABSA = ABS( AB( L+I, J ) )
            SUM = SUM + ABSA
            WORK( I ) = WORK( I ) + ABSA
50          CONTINUE
         WORK( J ) = SUM + ABS( AB( K+1, J ) )
60       CONTINUE
      DO 70 I = 1, N
         VALUE = MAX( VALUE, WORK( I ) )
70       CONTINUE
   ELSE
      DO 80 I = 1, N
         WORK( I ) = ZERO
80       CONTINUE
      DO 100 J = 1, N
         SUM = WORK( J ) + ABS( AB( 1, J ) )
         L = 1 - J
         DO 90 I = J + 1, MIN( N, J+K )
            ABSA = ABS( AB( L+I, J ) )
            SUM = SUM + ABSA
            WORK( I ) = WORK( I ) + ABSA
90          CONTINUE
         VALUE = MAX( VALUE, SUM )
100       CONTINUE
   END IF
ELSE IF( ( LSAME( NORM, 'F' ) ) .OR. ( LSAME( NORM, 'E' ) ) ) THEN
!
!        Find normF(A).
!
   SCALE = ZERO
   SUM = ONE
   IF( K.GT.0 ) THEN
      IF( LSAME( UPLO, 'U' ) ) THEN
         DO 110 J = 2, N
            CALL DLASSQ( MIN( J-1, K ), AB( MAX( K+2-J, 1 ), J ), &
                             1, SCALE, SUM )
110          CONTINUE
         L = K + 1
      ELSE
         DO 120 J = 1, N - 1
            CALL DLASSQ( MIN( N-J, K ), AB( 2, J ), 1, SCALE, &
                             SUM )
120          CONTINUE
         L = 1
      END IF
      SUM = 2*SUM
   ELSE
      L = 1
   END IF
   CALL DLASSQ( N, AB( L, 1 ), LDAB, SCALE, SUM )
   VALUE = SCALE*SQRT( SUM )
END IF
!
DLANSB = VALUE
RETURN
!
!     End of DLANSB
!
end function dlansb

! ===== End dlansb.f90 =====


! ===== Begin dlanst.f90 =====

DOUBLE PRECISION FUNCTION DLANST( NORM, N, D, E )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          NORM
INTEGER            N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   D( * ), E( * )
!     ..
!
!  Purpose
!  =======
!
!  DLANST  returns the value of the one norm,  or the Frobenius norm, or
!  the  infinity norm,  or the  element of  largest absolute value  of a
!  real symmetric tridiagonal matrix A.
!
!  Description
!  ===========
!
!  DLANST returns the value
!
!     DLANST = ( max(abs(A(i,j))), NORM = 'M' or 'm'
!              (
!              ( norm1(A),         NORM = '1', 'O' or 'o'
!              (
!              ( normI(A),         NORM = 'I' or 'i'
!              (
!              ( normF(A),         NORM = 'F', 'f', 'E' or 'e'
!
!  where  norm1  denotes the  one norm of a matrix (maximum column sum),
!  normI  denotes the  infinity norm  of a matrix  (maximum row sum) and
!  normF  denotes the  Frobenius norm of a matrix (square root of sum of
!  squares).  Note that  max(abs(A(i,j)))  is not a  matrix norm.
!
!  Arguments
!  =========
!
!  NORM    (input) CHARACTER*1
!          Specifies the value to be returned in DLANST as described
!          above.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.  When N = 0, DLANST is
!          set to zero.
!
!  D       (input) DOUBLE PRECISION array, dimension (N)
!          The diagonal elements of A.
!
!  E       (input) DOUBLE PRECISION array, dimension (N-1)
!          The (n-1) sub-diagonal or super-diagonal elements of A.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I
DOUBLE PRECISION   ANORM, SCALE, SUM
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DLASSQ
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, SQRT
!     ..
!     .. Executable Statements ..
!
IF( N.LE.0 ) THEN
   ANORM = ZERO
ELSE IF( LSAME( NORM, 'M' ) ) THEN
!
!        Find max(abs(A(i,j))).
!
   ANORM = ABS( D( N ) )
   DO 10 I = 1, N - 1
      ANORM = MAX( ANORM, ABS( D( I ) ) )
      ANORM = MAX( ANORM, ABS( E( I ) ) )
10    CONTINUE
ELSE IF( LSAME( NORM, 'O' ) .OR. NORM.EQ.'1' .OR. &
             LSAME( NORM, 'I' ) ) THEN
!
!        Find norm1(A).
!
   IF( N.EQ.1 ) THEN
      ANORM = ABS( D( 1 ) )
   ELSE
      ANORM = MAX( ABS( D( 1 ) )+ABS( E( 1 ) ), &
                  ABS( E( N-1 ) )+ABS( D( N ) ) )
      DO 20 I = 2, N - 1
         ANORM = MAX( ANORM, ABS( D( I ) )+ABS( E( I ) )+ &
                     ABS( E( I-1 ) ) )
20       CONTINUE
   END IF
ELSE IF( ( LSAME( NORM, 'F' ) ) .OR. ( LSAME( NORM, 'E' ) ) ) THEN
!
!        Find normF(A).
!
   SCALE = ZERO
   SUM = ONE
   IF( N.GT.1 ) THEN
      CALL DLASSQ( N-1, E, 1, SCALE, SUM )
      SUM = 2*SUM
   END IF
   CALL DLASSQ( N, D, 1, SCALE, SUM )
   ANORM = SCALE*SQRT( SUM )
END IF
!
DLANST = ANORM
RETURN
!
!     End of DLANST
!
end function dlanst

! ===== End dlanst.f90 =====


! ===== Begin dlanv2.f90 =====

SUBROUTINE DLANV2( A, B, C, D, RT1R, RT1I, RT2R, RT2I, CS, SN )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994 
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   A, B, C, CS, D, RT1I, RT1R, RT2I, RT2R, SN
!     ..
!
!  Purpose
!  =======
!
!  DLANV2 computes the Schur factorization of a real 2-by-2 nonsymmetric
!  matrix in standard form:
!
!       [ A  B ] = [ CS -SN ] [ AA  BB ] [ CS  SN ]
!       [ C  D ]   [ SN  CS ] [ CC  DD ] [-SN  CS ]
!
!  where either
!  1) CC = 0 so that AA and DD are real eigenvalues of the matrix, or
!  2) AA = DD and BB*CC < 0, so that AA + or - sqrt(BB*CC) are complex
!  conjugate eigenvalues.
!
!  Arguments
!  =========
!
!  A       (input/output) DOUBLE PRECISION
!  B       (input/output) DOUBLE PRECISION
!  C       (input/output) DOUBLE PRECISION
!  D       (input/output) DOUBLE PRECISION
!          On entry, the elements of the input matrix.
!          On exit, they are overwritten by the elements of the
!          standardised Schur form.
!
!  RT1R    (output) DOUBLE PRECISION
!  RT1I    (output) DOUBLE PRECISION
!  RT2R    (output) DOUBLE PRECISION
!  RT2I    (output) DOUBLE PRECISION
!          The real and imaginary parts of the eigenvalues. If the
!          eigenvalues are both real, abs(RT1R) >= abs(RT2R); if the
!          eigenvalues are a complex conjugate pair, RT1I > 0.
!
!  CS      (output) DOUBLE PRECISION
!  SN      (output) DOUBLE PRECISION
!          Parameters of the rotation matrix.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, HALF, ONE
PARAMETER          ( ZERO = 0.0D+0, HALF = 0.5D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
DOUBLE PRECISION   AA, BB, CC, CS1, DD, P, SAB, SAC, SIGMA, SN1, &
                       TAU, TEMP
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAPY2
EXTERNAL           DLAPY2
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, SIGN, SQRT
!     ..
!     .. Executable Statements ..
!
!     Initialize CS and SN
!
CS = ONE
SN = ZERO
!
IF( C.EQ.ZERO ) THEN
   GO TO 10
!
ELSE IF( B.EQ.ZERO ) THEN
!
!        Swap rows and columns
!
   CS = ZERO
   SN = ONE
   TEMP = D
   D = A
   A = TEMP
   B = -C
   C = ZERO
   GO TO 10
ELSE IF( (A-D).EQ.ZERO .AND. SIGN( ONE, B ).NE. &
       SIGN( ONE, C ) ) THEN
   GO TO 10
ELSE
!
!        Make diagonal elements equal
!
   TEMP = A - D
   P = HALF*TEMP
   SIGMA = B + C
   TAU = DLAPY2( SIGMA, TEMP )
   CS1 = SQRT( HALF*( ONE+ABS( SIGMA ) / TAU ) )
   SN1 = -( P / ( TAU*CS1 ) )*SIGN( ONE, SIGMA )
!
!        Compute [ AA  BB ] = [ A  B ] [ CS1 -SN1 ]
!                [ CC  DD ]   [ C  D ] [ SN1  CS1 ]
!
   AA = A*CS1 + B*SN1
   BB = -A*SN1 + B*CS1
   CC = C*CS1 + D*SN1
   DD = -C*SN1 + D*CS1
!
!        Compute [ A  B ] = [ CS1  SN1 ] [ AA  BB ]
!                [ C  D ]   [-SN1  CS1 ] [ CC  DD ]
!
   A = AA*CS1 + CC*SN1
   B = BB*CS1 + DD*SN1
   C = -AA*SN1 + CC*CS1
   D = -BB*SN1 + DD*CS1
!
!        Accumulate transformation
!
   TEMP = CS*CS1 - SN*SN1
   SN = CS*SN1 + SN*CS1
   CS = TEMP
!
   TEMP = HALF*( A+D )
   A = TEMP
   D = TEMP
!
   IF( C.NE.ZERO ) THEN
      IF( B.NE.ZERO ) THEN
         IF( SIGN( ONE, B ).EQ.SIGN( ONE, C ) ) THEN
!
!                 Real eigenvalues: reduce to upper triangular form
!
            SAB = SQRT( ABS( B ) )
            SAC = SQRT( ABS( C ) )
            P = SIGN( SAB*SAC, C )
            TAU = ONE / SQRT( ABS( B+C ) )
            A = TEMP + P
            D = TEMP - P
            B = B - C
            C = ZERO
            CS1 = SAB*TAU
            SN1 = SAC*TAU
            TEMP = CS*CS1 - SN*SN1
            SN = CS*SN1 + SN*CS1
            CS = TEMP
         END IF
      ELSE
         B = -C
         C = ZERO
         TEMP = CS
         CS = -SN
         SN = TEMP
      END IF
   END IF
END IF
!
10 CONTINUE
!
!     Store eigenvalues in (RT1R,RT1I) and (RT2R,RT2I).
!
RT1R = A
RT2R = D
IF( C.EQ.ZERO ) THEN
   RT1I = ZERO
   RT2I = ZERO
ELSE
   RT1I = SQRT( ABS( B ) )*SQRT( ABS( C ) )
   RT2I = -RT1I
END IF
RETURN
!
!     End of DLANV2
!
end subroutine dlanv2

! ===== End dlanv2.f90 =====


! ===== Begin dlaptm.f90 =====

SUBROUTINE DLAPTM( N, NRHS, ALPHA, D, E, X, LDX, BETA, B, LDB )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            LDB, LDX, N, NRHS
DOUBLE PRECISION   ALPHA, BETA
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   B( LDB, * ), D( * ), E( * ), X( LDX, * )
!     ..
!
!  Purpose
!  =======
!
!  DLAPTM multiplies an N by NRHS matrix X by a symmetric tridiagonal
!  matrix A and stores the result in a matrix B.  The operation has the
!  form
!
!     B := alpha * A * X + beta * B
!
!  where alpha may be either 1. or -1. and beta may be 0., 1., or -1.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrices X and B.
!
!  ALPHA   (input) DOUBLE PRECISION
!          The scalar alpha.  ALPHA must be 1. or -1.; otherwise,
!          it is assumed to be 0.
!
!  D       (input) DOUBLE PRECISION array, dimension (N)
!          The n diagonal elements of the tridiagonal matrix A.
!
!  E       (input) DOUBLE PRECISION array, dimension (N-1)
!          The (n-1) subdiagonal or superdiagonal elements of A.
!
!  X       (input) DOUBLE PRECISION array, dimension (LDX,NRHS)
!          The N by NRHS matrix X.
!
!  LDX     (input) INTEGER
!          The leading dimension of the array X.  LDX >= max(N,1).
!
!  BETA    (input) DOUBLE PRECISION
!          The scalar beta.  BETA must be 0., 1., or -1.; otherwise,
!          it is assumed to be 1.
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the N by NRHS matrix B.
!          On exit, B is overwritten by the matrix expression
!          B := alpha * A * X + beta * B.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(N,1).
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, J
!     ..
!     .. Executable Statements ..
!
IF( N.EQ.0 ) &
       RETURN
!
!     Multiply B by BETA if BETA.NE.1.
!
IF( BETA.EQ.ZERO ) THEN
   DO 20 J = 1, NRHS
      DO 10 I = 1, N
         B( I, J ) = ZERO
10       CONTINUE
20    CONTINUE
ELSE IF( BETA.EQ.-ONE ) THEN
   DO 40 J = 1, NRHS
      DO 30 I = 1, N
         B( I, J ) = -B( I, J )
30       CONTINUE
40    CONTINUE
END IF
!
IF( ALPHA.EQ.ONE ) THEN
!
!        Compute B := B + A*X
!
   DO 60 J = 1, NRHS
      IF( N.EQ.1 ) THEN
         B( 1, J ) = B( 1, J ) + D( 1 )*X( 1, J )
      ELSE
         B( 1, J ) = B( 1, J ) + D( 1 )*X( 1, J ) + &
                         E( 1 )*X( 2, J )
         B( N, J ) = B( N, J ) + E( N-1 )*X( N-1, J ) + &
                         D( N )*X( N, J )
         DO 50 I = 2, N - 1
            B( I, J ) = B( I, J ) + E( I-1 )*X( I-1, J ) + &
                            D( I )*X( I, J ) + E( I )*X( I+1, J )
50          CONTINUE
      END IF
60    CONTINUE
ELSE IF( ALPHA.EQ.-ONE ) THEN
!
!        Compute B := B - A*X
!
   DO 80 J = 1, NRHS
      IF( N.EQ.1 ) THEN
         B( 1, J ) = B( 1, J ) - D( 1 )*X( 1, J )
      ELSE
         B( 1, J ) = B( 1, J ) - D( 1 )*X( 1, J ) - &
                         E( 1 )*X( 2, J )
         B( N, J ) = B( N, J ) - E( N-1 )*X( N-1, J ) - &
                         D( N )*X( N, J )
         DO 70 I = 2, N - 1
            B( I, J ) = B( I, J ) - E( I-1 )*X( I-1, J ) - &
                            D( I )*X( I, J ) - E( I )*X( I+1, J )
70          CONTINUE
      END IF
80    CONTINUE
END IF
RETURN
!
!     End of DLAPTM
!
end subroutine dlaptm

! ===== End dlaptm.f90 =====


! ===== Begin dlapy2.f90 =====

DOUBLE PRECISION FUNCTION DLAPY2( X, Y )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   X, Y
!     ..
!
!  Purpose
!  =======
!
!  DLAPY2 returns sqrt(x**2+y**2), taking care not to cause unnecessary
!  overflow.
!
!  Arguments
!  =========
!
!  X       (input) DOUBLE PRECISION
!  Y       (input) DOUBLE PRECISION
!          X and Y specify the values x and y.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D0 )
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D0 )
!     ..
!     .. Local Scalars ..
DOUBLE PRECISION   W, XABS, YABS, Z
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN, SQRT
!     ..
!     .. Executable Statements ..
!
XABS = ABS( X )
YABS = ABS( Y )
W = MAX( XABS, YABS )
Z = MIN( XABS, YABS )
IF( Z.EQ.ZERO ) THEN
   DLAPY2 = W
ELSE
   DLAPY2 = W*SQRT( ONE+( Z / W )**2 )
END IF
RETURN
!
!     End of DLAPY2
!
end function dlapy2

! ===== End dlapy2.f90 =====


! ===== Begin dlapy3.f90 =====

DOUBLE PRECISION FUNCTION DLAPY3( X, Y, Z )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   X, Y, Z
!     ..
!
!  Purpose
!  =======
!
!  DLAPY3 returns sqrt(x**2+y**2+z**2), taking care not to cause
!  unnecessary overflow.
!
!  Arguments
!  =========
!
!  X       (input) DOUBLE PRECISION
!  Y       (input) DOUBLE PRECISION
!  Z       (input) DOUBLE PRECISION
!          X, Y and Z specify the values x, y and z.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D0 )
!     ..
!     .. Local Scalars ..
DOUBLE PRECISION   W, XABS, YABS, ZABS
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, SQRT
!     ..
!     .. Executable Statements ..
!
XABS = ABS( X )
YABS = ABS( Y )
ZABS = ABS( Z )
W = MAX( XABS, YABS, ZABS )
IF( W.EQ.ZERO ) THEN
   DLAPY3 = ZERO
ELSE
   DLAPY3 = W*SQRT( ( XABS / W )**2+( YABS / W )**2+ &
                ( ZABS / W )**2 )
END IF
RETURN
!
!     End of DLAPY3
!
end function dlapy3

! ===== End dlapy3.f90 =====


! ===== Begin dlar2v.f90 =====

SUBROUTINE DLAR2V( N, X, Y, Z, INCX, C, S, INCC )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            INCC, INCX, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   C( * ), S( * ), X( * ), Y( * ), Z( * )
!     ..
!
!  Purpose
!  =======
!
!  DLAR2V applies a vector of real plane rotations from both sides to
!  a sequence of 2-by-2 real symmetric matrices, defined by the elements
!  of the vectors x, y and z. For i = 1,2,...,n
!
!     ( x(i)  z(i) ) := (  c(i)  s(i) ) ( x(i)  z(i) ) ( c(i) -s(i) )
!     ( z(i)  y(i) )    ( -s(i)  c(i) ) ( z(i)  y(i) ) ( s(i)  c(i) )
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of plane rotations to be applied.
!
!  X       (input/output) DOUBLE PRECISION array,
!                         dimension (1+(N-1)*INCX)
!          The vector x.
!
!  Y       (input/output) DOUBLE PRECISION array,
!                         dimension (1+(N-1)*INCX)
!          The vector y.
!
!  Z       (input/output) DOUBLE PRECISION array,
!                         dimension (1+(N-1)*INCX)
!          The vector z.
!
!  INCX    (input) INTEGER
!          The increment between elements of X, Y and Z. INCX > 0.
!
!  C       (input) DOUBLE PRECISION array, dimension (1+(N-1)*INCC)
!          The cosines of the plane rotations.
!
!  S       (input) DOUBLE PRECISION array, dimension (1+(N-1)*INCC)
!          The sines of the plane rotations.
!
!  INCC    (input) INTEGER
!          The increment between elements of C and S. INCC > 0.
!
!  =====================================================================
!
!     .. Local Scalars ..
INTEGER            I, IC, IX
DOUBLE PRECISION   CI, SI, T1, T2, T3, T4, T5, T6, XI, YI, ZI
!     ..
!     .. Executable Statements ..
!
IX = 1
IC = 1
DO 10 I = 1, N
   XI = X( IX )
   YI = Y( IX )
   ZI = Z( IX )
   CI = C( IC )
   SI = S( IC )
   T1 = SI*ZI
   T2 = CI*ZI
   T3 = T2 - SI*XI
   T4 = T2 + SI*YI
   T5 = CI*XI + T1
   T6 = CI*YI - T1
   X( IX ) = CI*T5 + SI*T4
   Y( IX ) = CI*T6 - SI*T3
   Z( IX ) = CI*T4 - SI*T5
   IX = IX + INCX
   IC = IC + INCC
10 CONTINUE
!
!     End of DLAR2V
!
RETURN
end subroutine dlar2v

! ===== End dlar2v.f90 =====


! ===== Begin dlaran.f90 =====

DOUBLE PRECISION FUNCTION DLARAN( ISEED )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Array Arguments ..
INTEGER            ISEED( 4 )
!     ..
!
!  Purpose
!  =======
!
!  DLARAN returns a random real number from a uniform (0,1)
!  distribution.
!
!  Arguments
!  =========
!
!  ISEED   (input/output) INTEGER array, dimension (4)
!          On entry, the seed of the random number generator; the array
!          elements must be between 0 and 4095, and ISEED(4) must be
!          odd.
!          On exit, the seed is updated.
!
!  Further Details
!  ===============
!
!  This routine uses a multiplicative congruential method with modulus
!  2**48 and multiplier 33952834046453 (see G.S.Fishman,
!  'Multiplicative congruential random number generators with modulus
!  2**b: an exhaustive analysis for b = 32 and a partial analysis for
!  b = 48', Math. Comp. 189, pp 331-344, 1990).
!
!  48-bit integers are stored in 4 integer array elements with 12 bits
!  per element. Hence the routine is portable across machines with
!  integers of 32 bits or more.
!
!  =====================================================================
!
!     .. Parameters ..
INTEGER            M1, M2, M3, M4
PARAMETER          ( M1 = 494, M2 = 322, M3 = 2508, M4 = 2549 )
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
INTEGER            IPW2
DOUBLE PRECISION   R
PARAMETER          ( IPW2 = 4096, R = ONE / IPW2 )
!     ..
!     .. Local Scalars ..
INTEGER            IT1, IT2, IT3, IT4
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          DBLE, MOD
!     ..
!     .. Executable Statements ..
!
!     multiply the seed by the multiplier modulo 2**48
!
IT4 = ISEED( 4 )*M4
IT3 = IT4 / IPW2
IT4 = IT4 - IPW2*IT3
IT3 = IT3 + ISEED( 3 )*M4 + ISEED( 4 )*M3
IT2 = IT3 / IPW2
IT3 = IT3 - IPW2*IT2
IT2 = IT2 + ISEED( 2 )*M4 + ISEED( 3 )*M3 + ISEED( 4 )*M2
IT1 = IT2 / IPW2
IT2 = IT2 - IPW2*IT1
IT1 = IT1 + ISEED( 1 )*M4 + ISEED( 2 )*M3 + ISEED( 3 )*M2 + &
          ISEED( 4 )*M1
IT1 = MOD( IT1, IPW2 )
!
!     return updated seed
!
ISEED( 1 ) = IT1
ISEED( 2 ) = IT2
ISEED( 3 ) = IT3
ISEED( 4 ) = IT4
!
!     convert 48-bit integer to a real number in the interval (0,1)
!
DLARAN = R*( DBLE( IT1 )+R*( DBLE( IT2 )+R*( DBLE( IT3 )+R* &
             ( DBLE( IT4 ) ) ) ) )
RETURN
!
!     End of DLARAN
!
end function dlaran

! ===== End dlaran.f90 =====


! ===== Begin dlarf.f90 =====

SUBROUTINE DLARF( SIDE, M, N, V, INCV, TAU, C, LDC, WORK )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          SIDE
INTEGER            INCV, LDC, M, N
DOUBLE PRECISION   TAU
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   C( LDC, * ), V( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DLARF applies a real elementary reflector H to a real m by n matrix
!  C, from either the left or the right. H is represented in the form
!
!        H = I - tau * v * v'
!
!  where tau is a real scalar and v is a real vector.
!
!  If tau = 0, then H is taken to be the unit matrix.
!
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          = 'L': form  H * C
!          = 'R': form  C * H
!
!  M       (input) INTEGER
!          The number of rows of the matrix C.
!
!  N       (input) INTEGER
!          The number of columns of the matrix C.
!
!  V       (input) DOUBLE PRECISION array, dimension
!                     (1 + (M-1)*abs(INCV)) if SIDE = 'L'
!                  or (1 + (N-1)*abs(INCV)) if SIDE = 'R'
!          The vector v in the representation of H. V is not used if
!          TAU = 0.
!
!  INCV    (input) INTEGER
!          The increment between elements of v. INCV <> 0.
!
!  TAU     (input) DOUBLE PRECISION
!          The value tau in the representation of H.
!
!  C       (input/output) DOUBLE PRECISION array, dimension (LDC,N)
!          On entry, the m by n matrix C.
!          On exit, C is overwritten by the matrix H * C if SIDE = 'L',
!          or C * H if SIDE = 'R'.
!
!  LDC     (input) INTEGER
!          The leading dimension of the array C. LDC >= max(1,M).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension
!                         (N) if SIDE = 'L'
!                      or (M) if SIDE = 'R'
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMV, DGER
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Executable Statements ..
!
IF( LSAME( SIDE, 'L' ) ) THEN
!
!        Form  H * C
!
   IF( TAU.NE.ZERO ) THEN
!
!           w := C' * v
!
      CALL DGEMV( 'Transpose', M, N, ONE, C, LDC, V, INCV, ZERO, &
                      WORK, 1 )
!
!           C := C - v * w'
!
      CALL DGER( M, N, -TAU, V, INCV, WORK, 1, C, LDC )
   END IF
ELSE
!
!        Form  C * H
!
   IF( TAU.NE.ZERO ) THEN
!
!           w := C * v
!
      CALL DGEMV( 'No transpose', M, N, ONE, C, LDC, V, INCV, &
                      ZERO, WORK, 1 )
!
!           C := C - w * v'
!
      CALL DGER( M, N, -TAU, WORK, 1, V, INCV, C, LDC )
   END IF
END IF
RETURN
!
!     End of DLARF
!
end subroutine dlarf

! ===== End dlarf.f90 =====


! ===== Begin dlarfb.f90 =====

SUBROUTINE DLARFB( SIDE, TRANS, DIRECT, STOREV, M, N, K, V, LDV, &
                       T, LDT, C, LDC, WORK, LDWORK )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          DIRECT, SIDE, STOREV, TRANS
INTEGER            K, LDC, LDT, LDV, LDWORK, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   C( LDC, * ), T( LDT, * ), V( LDV, * ), &
                       WORK( LDWORK, * )
!     ..
!
!  Purpose
!  =======
!
!  DLARFB applies a real block reflector H or its transpose H' to a
!  real m by n matrix C, from either the left or the right.
!
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          = 'L': apply H or H' from the Left
!          = 'R': apply H or H' from the Right
!
!  TRANS   (input) CHARACTER*1
!          = 'N': apply H (No transpose)
!          = 'T': apply H' (Transpose)
!
!  DIRECT  (input) CHARACTER*1
!          Indicates how H is formed from a product of elementary
!          reflectors
!          = 'F': H = H(1) H(2) . . . H(k) (Forward)
!          = 'B': H = H(k) . . . H(2) H(1) (Backward)
!
!  STOREV  (input) CHARACTER*1
!          Indicates how the vectors which define the elementary
!          reflectors are stored:
!          = 'C': Columnwise
!          = 'R': Rowwise
!
!  M       (input) INTEGER
!          The number of rows of the matrix C.
!
!  N       (input) INTEGER
!          The number of columns of the matrix C.
!
!  K       (input) INTEGER
!          The order of the matrix T (= the number of elementary
!          reflectors whose product defines the block reflector).
!
!  V       (input) DOUBLE PRECISION array, dimension
!                                (LDV,K) if STOREV = 'C'
!                                (LDV,M) if STOREV = 'R' and SIDE = 'L'
!                                (LDV,N) if STOREV = 'R' and SIDE = 'R'
!          The matrix V. See further details.
!
!  LDV     (input) INTEGER
!          The leading dimension of the array V.
!          If STOREV = 'C' and SIDE = 'L', LDV >= max(1,M);
!          if STOREV = 'C' and SIDE = 'R', LDV >= max(1,N);
!          if STOREV = 'R', LDV >= K.
!
!  T       (input) DOUBLE PRECISION array, dimension (LDT,K)
!          The triangular k by k matrix T in the representation of the
!          block reflector.
!
!  LDT     (input) INTEGER
!          The leading dimension of the array T. LDT >= K.
!
!  C       (input/output) DOUBLE PRECISION array, dimension (LDC,N)
!          On entry, the m by n matrix C.
!          On exit, C is overwritten by H*C or H'*C or C*H or C*H'.
!
!  LDC     (input) INTEGER
!          The leading dimension of the array C. LDA >= max(1,M).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (LDWORK,K)
!
!  LDWORK  (input) INTEGER
!          The leading dimension of the array WORK.
!          If SIDE = 'L', LDWORK >= max(1,N);
!          if SIDE = 'R', LDWORK >= max(1,M).
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
CHARACTER          TRANST
INTEGER            I, J
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DCOPY, DGEMM, DTRMM
!     ..
!     .. Executable Statements ..
!
!     Quick return if possible
!
IF( M.LE.0 .OR. N.LE.0 ) &
       RETURN
!
IF( LSAME( TRANS, 'N' ) ) THEN
   TRANST = 'T'
ELSE
   TRANST = 'N'
END IF
!
IF( LSAME( STOREV, 'C' ) ) THEN
!
   IF( LSAME( DIRECT, 'F' ) ) THEN
!
!           Let  V =  ( V1 )    (first K rows)
!                     ( V2 )
!           where  V1  is unit lower triangular.
!
      IF( LSAME( SIDE, 'L' ) ) THEN
!
!              Form  H * C  or  H' * C  where  C = ( C1 )
!                                                  ( C2 )
!
!              W := C' * V  =  (C1'*V1 + C2'*V2)  (stored in WORK)
!
!              W := C1'
!
         DO 10 J = 1, K
            CALL DCOPY( N, C( J, 1 ), LDC, WORK( 1, J ), 1 )
10          CONTINUE
!
!              W := W * V1
!
         CALL DTRMM( 'Right', 'Lower', 'No transpose', 'Unit', N, &
                         K, ONE, V, LDV, WORK, LDWORK )
         IF( M.GT.K ) THEN
!
!                 W := W + C2'*V2
!
            CALL DGEMM( 'Transpose', 'No transpose', N, K, M-K, &
                            ONE, C( K+1, 1 ), LDC, V( K+1, 1 ), LDV, &
                            ONE, WORK, LDWORK )
         END IF
!
!              W := W * T'  or  W * T
!
         CALL DTRMM( 'Right', 'Upper', TRANST, 'Non-unit', N, K, &
                         ONE, T, LDT, WORK, LDWORK )
!
!              C := C - V * W'
!
         IF( M.GT.K ) THEN
!
!                 C2 := C2 - V2 * W'
!
            CALL DGEMM( 'No transpose', 'Transpose', M-K, N, K, &
                            -ONE, V( K+1, 1 ), LDV, WORK, LDWORK, ONE, &
                            C( K+1, 1 ), LDC )
         END IF
!
!              W := W * V1'
!
         CALL DTRMM( 'Right', 'Lower', 'Transpose', 'Unit', N, K, &
                         ONE, V, LDV, WORK, LDWORK )
!
!              C1 := C1 - W'
!
         DO 30 J = 1, K
            DO 20 I = 1, N
               C( J, I ) = C( J, I ) - WORK( I, J )
20             CONTINUE
30          CONTINUE
!
      ELSE IF( LSAME( SIDE, 'R' ) ) THEN
!
!              Form  C * H  or  C * H'  where  C = ( C1  C2 )
!
!              W := C * V  =  (C1*V1 + C2*V2)  (stored in WORK)
!
!              W := C1
!
         DO 40 J = 1, K
            CALL DCOPY( M, C( 1, J ), 1, WORK( 1, J ), 1 )
40          CONTINUE
!
!              W := W * V1
!
         CALL DTRMM( 'Right', 'Lower', 'No transpose', 'Unit', M, &
                         K, ONE, V, LDV, WORK, LDWORK )
         IF( N.GT.K ) THEN
!
!                 W := W + C2 * V2
!
            CALL DGEMM( 'No transpose', 'No transpose', M, K, N-K, &
                            ONE, C( 1, K+1 ), LDC, V( K+1, 1 ), LDV, &
                            ONE, WORK, LDWORK )
         END IF
!
!              W := W * T  or  W * T'
!
         CALL DTRMM( 'Right', 'Upper', TRANS, 'Non-unit', M, K, &
                         ONE, T, LDT, WORK, LDWORK )
!
!              C := C - W * V'
!
         IF( N.GT.K ) THEN
!
!                 C2 := C2 - W * V2'
!
            CALL DGEMM( 'No transpose', 'Transpose', M, N-K, K, &
                            -ONE, WORK, LDWORK, V( K+1, 1 ), LDV, ONE, &
                            C( 1, K+1 ), LDC )
         END IF
!
!              W := W * V1'
!
         CALL DTRMM( 'Right', 'Lower', 'Transpose', 'Unit', M, K, &
                         ONE, V, LDV, WORK, LDWORK )
!
!              C1 := C1 - W
!
         DO 60 J = 1, K
            DO 50 I = 1, M
               C( I, J ) = C( I, J ) - WORK( I, J )
50             CONTINUE
60          CONTINUE
      END IF
!
   ELSE
!
!           Let  V =  ( V1 )
!                     ( V2 )    (last K rows)
!           where  V2  is unit upper triangular.
!
      IF( LSAME( SIDE, 'L' ) ) THEN
!
!              Form  H * C  or  H' * C  where  C = ( C1 )
!                                                  ( C2 )
!
!              W := C' * V  =  (C1'*V1 + C2'*V2)  (stored in WORK)
!
!              W := C2'
!
         DO 70 J = 1, K
            CALL DCOPY( N, C( M-K+J, 1 ), LDC, WORK( 1, J ), 1 )
70          CONTINUE
!
!              W := W * V2
!
         CALL DTRMM( 'Right', 'Upper', 'No transpose', 'Unit', N, &
                         K, ONE, V( M-K+1, 1 ), LDV, WORK, LDWORK )
         IF( M.GT.K ) THEN
!
!                 W := W + C1'*V1
!
            CALL DGEMM( 'Transpose', 'No transpose', N, K, M-K, &
                            ONE, C, LDC, V, LDV, ONE, WORK, LDWORK )
         END IF
!
!              W := W * T'  or  W * T
!
         CALL DTRMM( 'Right', 'Lower', TRANST, 'Non-unit', N, K, &
                         ONE, T, LDT, WORK, LDWORK )
!
!              C := C - V * W'
!
         IF( M.GT.K ) THEN
!
!                 C1 := C1 - V1 * W'
!
            CALL DGEMM( 'No transpose', 'Transpose', M-K, N, K, &
                            -ONE, V, LDV, WORK, LDWORK, ONE, C, LDC )
         END IF
!
!              W := W * V2'
!
         CALL DTRMM( 'Right', 'Upper', 'Transpose', 'Unit', N, K, &
                         ONE, V( M-K+1, 1 ), LDV, WORK, LDWORK )
!
!              C2 := C2 - W'
!
         DO 90 J = 1, K
            DO 80 I = 1, N
               C( M-K+J, I ) = C( M-K+J, I ) - WORK( I, J )
80             CONTINUE
90          CONTINUE
!
      ELSE IF( LSAME( SIDE, 'R' ) ) THEN
!
!              Form  C * H  or  C * H'  where  C = ( C1  C2 )
!
!              W := C * V  =  (C1*V1 + C2*V2)  (stored in WORK)
!
!              W := C2
!
         DO 100 J = 1, K
            CALL DCOPY( M, C( 1, N-K+J ), 1, WORK( 1, J ), 1 )
100          CONTINUE
!
!              W := W * V2
!
         CALL DTRMM( 'Right', 'Upper', 'No transpose', 'Unit', M, &
                         K, ONE, V( N-K+1, 1 ), LDV, WORK, LDWORK )
         IF( N.GT.K ) THEN
!
!                 W := W + C1 * V1
!
            CALL DGEMM( 'No transpose', 'No transpose', M, K, N-K, &
                            ONE, C, LDC, V, LDV, ONE, WORK, LDWORK )
         END IF
!
!              W := W * T  or  W * T'
!
         CALL DTRMM( 'Right', 'Lower', TRANS, 'Non-unit', M, K, &
                         ONE, T, LDT, WORK, LDWORK )
!
!              C := C - W * V'
!
         IF( N.GT.K ) THEN
!
!                 C1 := C1 - W * V1'
!
            CALL DGEMM( 'No transpose', 'Transpose', M, N-K, K, &
                            -ONE, WORK, LDWORK, V, LDV, ONE, C, LDC )
         END IF
!
!              W := W * V2'
!
         CALL DTRMM( 'Right', 'Upper', 'Transpose', 'Unit', M, K, &
                         ONE, V( N-K+1, 1 ), LDV, WORK, LDWORK )
!
!              C2 := C2 - W
!
         DO 120 J = 1, K
            DO 110 I = 1, M
               C( I, N-K+J ) = C( I, N-K+J ) - WORK( I, J )
110             CONTINUE
120          CONTINUE
      END IF
   END IF
!
ELSE IF( LSAME( STOREV, 'R' ) ) THEN
!
   IF( LSAME( DIRECT, 'F' ) ) THEN
!
!           Let  V =  ( V1  V2 )    (V1: first K columns)
!           where  V1  is unit upper triangular.
!
      IF( LSAME( SIDE, 'L' ) ) THEN
!
!              Form  H * C  or  H' * C  where  C = ( C1 )
!                                                  ( C2 )
!
!              W := C' * V'  =  (C1'*V1' + C2'*V2') (stored in WORK)
!
!              W := C1'
!
         DO 130 J = 1, K
            CALL DCOPY( N, C( J, 1 ), LDC, WORK( 1, J ), 1 )
130          CONTINUE
!
!              W := W * V1'
!
         CALL DTRMM( 'Right', 'Upper', 'Transpose', 'Unit', N, K, &
                         ONE, V, LDV, WORK, LDWORK )
         IF( M.GT.K ) THEN
!
!                 W := W + C2'*V2'
!
            CALL DGEMM( 'Transpose', 'Transpose', N, K, M-K, ONE, &
                            C( K+1, 1 ), LDC, V( 1, K+1 ), LDV, ONE, &
                            WORK, LDWORK )
         END IF
!
!              W := W * T'  or  W * T
!
         CALL DTRMM( 'Right', 'Upper', TRANST, 'Non-unit', N, K, &
                         ONE, T, LDT, WORK, LDWORK )
!
!              C := C - V' * W'
!
         IF( M.GT.K ) THEN
!
!                 C2 := C2 - V2' * W'
!
            CALL DGEMM( 'Transpose', 'Transpose', M-K, N, K, -ONE, &
                            V( 1, K+1 ), LDV, WORK, LDWORK, ONE, &
                            C( K+1, 1 ), LDC )
         END IF
!
!              W := W * V1
!
         CALL DTRMM( 'Right', 'Upper', 'No transpose', 'Unit', N, &
                         K, ONE, V, LDV, WORK, LDWORK )
!
!              C1 := C1 - W'
!
         DO 150 J = 1, K
            DO 140 I = 1, N
               C( J, I ) = C( J, I ) - WORK( I, J )
140             CONTINUE
150          CONTINUE
!
      ELSE IF( LSAME( SIDE, 'R' ) ) THEN
!
!              Form  C * H  or  C * H'  where  C = ( C1  C2 )
!
!              W := C * V'  =  (C1*V1' + C2*V2')  (stored in WORK)
!
!              W := C1
!
         DO 160 J = 1, K
            CALL DCOPY( M, C( 1, J ), 1, WORK( 1, J ), 1 )
160          CONTINUE
!
!              W := W * V1'
!
         CALL DTRMM( 'Right', 'Upper', 'Transpose', 'Unit', M, K, &
                         ONE, V, LDV, WORK, LDWORK )
         IF( N.GT.K ) THEN
!
!                 W := W + C2 * V2'
!
            CALL DGEMM( 'No transpose', 'Transpose', M, K, N-K, &
                            ONE, C( 1, K+1 ), LDC, V( 1, K+1 ), LDV, &
                            ONE, WORK, LDWORK )
         END IF
!
!              W := W * T  or  W * T'
!
         CALL DTRMM( 'Right', 'Upper', TRANS, 'Non-unit', M, K, &
                         ONE, T, LDT, WORK, LDWORK )
!
!              C := C - W * V
!
         IF( N.GT.K ) THEN
!
!                 C2 := C2 - W * V2
!
            CALL DGEMM( 'No transpose', 'No transpose', M, N-K, K, &
                            -ONE, WORK, LDWORK, V( 1, K+1 ), LDV, ONE, &
                            C( 1, K+1 ), LDC )
         END IF
!
!              W := W * V1
!
         CALL DTRMM( 'Right', 'Upper', 'No transpose', 'Unit', M, &
                         K, ONE, V, LDV, WORK, LDWORK )
!
!              C1 := C1 - W
!
         DO 180 J = 1, K
            DO 170 I = 1, M
               C( I, J ) = C( I, J ) - WORK( I, J )
170             CONTINUE
180          CONTINUE
!
      END IF
!
   ELSE
!
!           Let  V =  ( V1  V2 )    (V2: last K columns)
!           where  V2  is unit lower triangular.
!
      IF( LSAME( SIDE, 'L' ) ) THEN
!
!              Form  H * C  or  H' * C  where  C = ( C1 )
!                                                  ( C2 )
!
!              W := C' * V'  =  (C1'*V1' + C2'*V2') (stored in WORK)
!
!              W := C2'
!
         DO 190 J = 1, K
            CALL DCOPY( N, C( M-K+J, 1 ), LDC, WORK( 1, J ), 1 )
190          CONTINUE
!
!              W := W * V2'
!
         CALL DTRMM( 'Right', 'Lower', 'Transpose', 'Unit', N, K, &
                         ONE, V( 1, M-K+1 ), LDV, WORK, LDWORK )
         IF( M.GT.K ) THEN
!
!                 W := W + C1'*V1'
!
            CALL DGEMM( 'Transpose', 'Transpose', N, K, M-K, ONE, &
                            C, LDC, V, LDV, ONE, WORK, LDWORK )
         END IF
!
!              W := W * T'  or  W * T
!
         CALL DTRMM( 'Right', 'Lower', TRANST, 'Non-unit', N, K, &
                         ONE, T, LDT, WORK, LDWORK )
!
!              C := C - V' * W'
!
         IF( M.GT.K ) THEN
!
!                 C1 := C1 - V1' * W'
!
            CALL DGEMM( 'Transpose', 'Transpose', M-K, N, K, -ONE, &
                            V, LDV, WORK, LDWORK, ONE, C, LDC )
         END IF
!
!              W := W * V2
!
         CALL DTRMM( 'Right', 'Lower', 'No transpose', 'Unit', N, &
                         K, ONE, V( 1, M-K+1 ), LDV, WORK, LDWORK )
!
!              C2 := C2 - W'
!
         DO 210 J = 1, K
            DO 200 I = 1, N
               C( M-K+J, I ) = C( M-K+J, I ) - WORK( I, J )
200             CONTINUE
210          CONTINUE
!
      ELSE IF( LSAME( SIDE, 'R' ) ) THEN
!
!              Form  C * H  or  C * H'  where  C = ( C1  C2 )
!
!              W := C * V'  =  (C1*V1' + C2*V2')  (stored in WORK)
!
!              W := C2
!
         DO 220 J = 1, K
            CALL DCOPY( M, C( 1, N-K+J ), 1, WORK( 1, J ), 1 )
220          CONTINUE
!
!              W := W * V2'
!
         CALL DTRMM( 'Right', 'Lower', 'Transpose', 'Unit', M, K, &
                         ONE, V( 1, N-K+1 ), LDV, WORK, LDWORK )
         IF( N.GT.K ) THEN
!
!                 W := W + C1 * V1'
!
            CALL DGEMM( 'No transpose', 'Transpose', M, K, N-K, &
                            ONE, C, LDC, V, LDV, ONE, WORK, LDWORK )
         END IF
!
!              W := W * T  or  W * T'
!
         CALL DTRMM( 'Right', 'Lower', TRANS, 'Non-unit', M, K, &
                         ONE, T, LDT, WORK, LDWORK )
!
!              C := C - W * V
!
         IF( N.GT.K ) THEN
!
!                 C1 := C1 - W * V1
!
            CALL DGEMM( 'No transpose', 'No transpose', M, N-K, K, &
                            -ONE, WORK, LDWORK, V, LDV, ONE, C, LDC )
         END IF
!
!              W := W * V2
!
         CALL DTRMM( 'Right', 'Lower', 'No transpose', 'Unit', M, &
                         K, ONE, V( 1, N-K+1 ), LDV, WORK, LDWORK )
!
!              C1 := C1 - W
!
         DO 240 J = 1, K
            DO 230 I = 1, M
               C( I, N-K+J ) = C( I, N-K+J ) - WORK( I, J )
230             CONTINUE
240          CONTINUE
!
      END IF
!
   END IF
END IF
!
RETURN
!
!     End of DLARFB
!
end subroutine dlarfb

! ===== End dlarfb.f90 =====


! ===== Begin dlarfg.f90 =====

SUBROUTINE DLARFG( N, ALPHA, X, INCX, TAU )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
INTEGER            INCX, N
DOUBLE PRECISION   ALPHA, TAU
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   X( * )
!     ..
!
!  Purpose
!  =======
!
!  DLARFG generates a real elementary reflector H of order n, such
!  that
!
!        H * ( alpha ) = ( beta ),   H' * H = I.
!            (   x   )   (   0  )
!
!  where alpha and beta are scalars, and x is an (n-1)-element real
!  vector. H is represented in the form
!
!        H = I - tau * ( 1 ) * ( 1 v' ) ,
!                      ( v )
!
!  where tau is a real scalar and v is a real (n-1)-element
!  vector.
!
!  If the elements of x are all zero, then tau = 0 and H is taken to be
!  the unit matrix.
!
!  Otherwise  1 <= tau <= 2.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the elementary reflector.
!
!  ALPHA   (input/output) DOUBLE PRECISION
!          On entry, the value alpha.
!          On exit, it is overwritten with the value beta.
!
!  X       (input/output) DOUBLE PRECISION array, dimension
!                         (1+(N-2)*abs(INCX))
!          On entry, the vector x.
!          On exit, it is overwritten with the vector v.
!
!  INCX    (input) INTEGER
!          The increment between elements of X. INCX > 0.
!
!  TAU     (output) DOUBLE PRECISION
!          The value tau.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            J, KNT
DOUBLE PRECISION   BETA, RSAFMN, SAFMIN, XNORM
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMCH, DLAPY2, DNRM2
EXTERNAL           DLAMCH, DLAPY2, DNRM2
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, SIGN
!     ..
!     .. External Subroutines ..
EXTERNAL           DSCAL
!     ..
!     .. Executable Statements ..
!
IF( N.LE.1 ) THEN
   TAU = ZERO
   RETURN
END IF
!
XNORM = DNRM2( N-1, X, INCX )
!
IF( XNORM.EQ.ZERO ) THEN
!
!        H  =  I
!
   TAU = ZERO
ELSE
!
!        general case
!
   BETA = -SIGN( DLAPY2( ALPHA, XNORM ), ALPHA )
   SAFMIN = DLAMCH( 'S' ) / DLAMCH( 'E' )
   IF( ABS( BETA ).LT.SAFMIN ) THEN
!
!           XNORM, BETA may be inaccurate; scale X and recompute them
!
      RSAFMN = ONE / SAFMIN
      KNT = 0
10       CONTINUE
      KNT = KNT + 1
      CALL DSCAL( N-1, RSAFMN, X, INCX )
      BETA = BETA*RSAFMN
      ALPHA = ALPHA*RSAFMN
      IF( ABS( BETA ).LT.SAFMIN ) &
             GO TO 10
!
!           New BETA is at most 1, at least SAFMIN
!
      XNORM = DNRM2( N-1, X, INCX )
      BETA = -SIGN( DLAPY2( ALPHA, XNORM ), ALPHA )
      TAU = ( BETA-ALPHA ) / BETA
      CALL DSCAL( N-1, ONE / ( ALPHA-BETA ), X, INCX )
!
!           If ALPHA is subnormal, it may lose relative accuracy
!
      ALPHA = BETA
      DO 20 J = 1, KNT
         ALPHA = ALPHA*SAFMIN
20       CONTINUE
   ELSE
      TAU = ( BETA-ALPHA ) / BETA
      CALL DSCAL( N-1, ONE / ( ALPHA-BETA ), X, INCX )
      ALPHA = BETA
   END IF
END IF
!
RETURN
!
!     End of DLARFG
!
end subroutine dlarfg

! ===== End dlarfg.f90 =====


! ===== Begin dlarft.f90 =====

SUBROUTINE DLARFT( DIRECT, STOREV, N, K, V, LDV, TAU, T, LDT )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          DIRECT, STOREV
INTEGER            K, LDT, LDV, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   T( LDT, * ), TAU( * ), V( LDV, * )
!     ..
!
!  Purpose
!  =======
!
!  DLARFT forms the triangular factor T of a real block reflector H
!  of order n, which is defined as a product of k elementary reflectors.
!
!  If DIRECT = 'F', H = H(1) H(2) . . . H(k) and T is upper triangular;
!
!  If DIRECT = 'B', H = H(k) . . . H(2) H(1) and T is lower triangular.
!
!  If STOREV = 'C', the vector which defines the elementary reflector
!  H(i) is stored in the i-th column of the array V, and
!
!     H  =  I - V * T * V'
!
!  If STOREV = 'R', the vector which defines the elementary reflector
!  H(i) is stored in the i-th row of the array V, and
!
!     H  =  I - V' * T * V
!
!  Arguments
!  =========
!
!  DIRECT  (input) CHARACTER*1
!          Specifies the order in which the elementary reflectors are
!          multiplied to form the block reflector:
!          = 'F': H = H(1) H(2) . . . H(k) (Forward)
!          = 'B': H = H(k) . . . H(2) H(1) (Backward)
!
!  STOREV  (input) CHARACTER*1
!          Specifies how the vectors which define the elementary
!          reflectors are stored (see also Further Details):
!          = 'C': columnwise
!          = 'R': rowwise
!
!  N       (input) INTEGER
!          The order of the block reflector H. N >= 0.
!
!  K       (input) INTEGER
!          The order of the triangular factor T (= the number of
!          elementary reflectors). K >= 1.
!
!  V       (input/output) DOUBLE PRECISION array, dimension
!                               (LDV,K) if STOREV = 'C'
!                               (LDV,N) if STOREV = 'R'
!          The matrix V. See further details.
!
!  LDV     (input) INTEGER
!          The leading dimension of the array V.
!          If STOREV = 'C', LDV >= max(1,N); if STOREV = 'R', LDV >= K.
!
!  TAU     (input) DOUBLE PRECISION array, dimension (K)
!          TAU(i) must contain the scalar factor of the elementary
!          reflector H(i).
!
!  T       (output) DOUBLE PRECISION array, dimension (LDT,K)
!          The k by k triangular factor T of the block reflector.
!          If DIRECT = 'F', T is upper triangular; if DIRECT = 'B', T is
!          lower triangular. The rest of the array is not used.
!
!  LDT     (input) INTEGER
!          The leading dimension of the array T. LDT >= K.
!
!  Further Details
!  ===============
!
!  The shape of the matrix V and the storage of the vectors which define
!  the H(i) is best illustrated by the following example with n = 5 and
!  k = 3. The elements equal to 1 are not stored; the corresponding
!  array elements are modified but restored on exit. The rest of the
!  array is not used.
!
!  DIRECT = 'F' and STOREV = 'C':         DIRECT = 'F' and STOREV = 'R':
!
!               V = (  1       )                 V = (  1 v1 v1 v1 v1 )
!                   ( v1  1    )                     (     1 v2 v2 v2 )
!                   ( v1 v2  1 )                     (        1 v3 v3 )
!                   ( v1 v2 v3 )
!                   ( v1 v2 v3 )
!
!  DIRECT = 'B' and STOREV = 'C':         DIRECT = 'B' and STOREV = 'R':
!
!               V = ( v1 v2 v3 )                 V = ( v1 v1  1       )
!                   ( v1 v2 v3 )                     ( v2 v2 v2  1    )
!                   (  1 v2 v3 )                     ( v3 v3 v3 v3  1 )
!                   (     1 v3 )
!                   (        1 )
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, J
DOUBLE PRECISION   VII
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMV, DTRMV
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Executable Statements ..
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
IF( LSAME( DIRECT, 'F' ) ) THEN
   DO 20 I = 1, K
      IF( TAU( I ).EQ.ZERO ) THEN
!
!              H(i)  =  I
!
         DO 10 J = 1, I
            T( J, I ) = ZERO
10          CONTINUE
      ELSE
!
!              general case
!
         VII = V( I, I )
         V( I, I ) = ONE
         IF( LSAME( STOREV, 'C' ) ) THEN
!
!                 T(1:i-1,i) := - tau(i) * V(i:n,1:i-1)' * V(i:n,i)
!
            CALL DGEMV( 'Transpose', N-I+1, I-1, -TAU( I ), &
                            V( I, 1 ), LDV, V( I, I ), 1, ZERO, &
                            T( 1, I ), 1 )
         ELSE
!
!                 T(1:i-1,i) := - tau(i) * V(1:i-1,i:n) * V(i,i:n)'
!
            CALL DGEMV( 'No transpose', I-1, N-I+1, -TAU( I ), &
                            V( 1, I ), LDV, V( I, I ), LDV, ZERO, &
                            T( 1, I ), 1 )
         END IF
         V( I, I ) = VII
!
!              T(1:i-1,i) := T(1:i-1,1:i-1) * T(1:i-1,i)
!
         CALL DTRMV( 'Upper', 'No transpose', 'Non-unit', I-1, T, &
                         LDT, T( 1, I ), 1 )
         T( I, I ) = TAU( I )
      END IF
20    CONTINUE
ELSE
   DO 40 I = K, 1, -1
      IF( TAU( I ).EQ.ZERO ) THEN
!
!              H(i)  =  I
!
         DO 30 J = I, K
            T( J, I ) = ZERO
30          CONTINUE
      ELSE
!
!              general case
!
         IF( I.LT.K ) THEN
            IF( LSAME( STOREV, 'C' ) ) THEN
               VII = V( N-K+I, I )
               V( N-K+I, I ) = ONE
!
!                    T(i+1:k,i) :=
!                            - tau(i) * V(1:n-k+i,i+1:k)' * V(1:n-k+i,i)
!
               CALL DGEMV( 'Transpose', N-K+I, K-I, -TAU( I ), &
                               V( 1, I+1 ), LDV, V( 1, I ), 1, ZERO, &
                               T( I+1, I ), 1 )
               V( N-K+I, I ) = VII
            ELSE
               VII = V( I, N-K+I )
               V( I, N-K+I ) = ONE
!
!                    T(i+1:k,i) :=
!                            - tau(i) * V(i+1:k,1:n-k+i) * V(i,1:n-k+i)'
!
               CALL DGEMV( 'No transpose', K-I, N-K+I, -TAU( I ), &
                               V( I+1, 1 ), LDV, V( I, 1 ), LDV, ZERO, &
                               T( I+1, I ), 1 )
               V( I, N-K+I ) = VII
            END IF
!
!                 T(i+1:k,i) := T(i+1:k,i+1:k) * T(i+1:k,i)
!
            CALL DTRMV( 'Lower', 'No transpose', 'Non-unit', K-I, &
                            T( I+1, I+1 ), LDT, T( I+1, I ), 1 )
         END IF
         T( I, I ) = TAU( I )
      END IF
40    CONTINUE
END IF
RETURN
!
!     End of DLARFT
!
end subroutine dlarft

! ===== End dlarft.f90 =====


! ===== Begin dlarfx.f90 =====

SUBROUTINE DLARFX( SIDE, M, N, V, TAU, C, LDC, WORK )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          SIDE
INTEGER            LDC, M, N
DOUBLE PRECISION   TAU
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   C( LDC, * ), V( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DLARFX applies a real elementary reflector H to a real m by n
!  matrix C, from either the left or the right. H is represented in the
!  form
!
!        H = I - tau * v * v'
!
!  where tau is a real scalar and v is a real vector.
!
!  If tau = 0, then H is taken to be the unit matrix
!
!  This version uses inline code if H has order < 11.
!
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          = 'L': form  H * C
!          = 'R': form  C * H
!
!  M       (input) INTEGER
!          The number of rows of the matrix C.
!
!  N       (input) INTEGER
!          The number of columns of the matrix C.
!
!  V       (input) DOUBLE PRECISION array, dimension (M) if SIDE = 'L'
!                                     or (N) if SIDE = 'R'
!          The vector v in the representation of H.
!
!  TAU     (input) DOUBLE PRECISION
!          The value tau in the representation of H.
!
!  C       (input/output) DOUBLE PRECISION array, dimension (LDC,N)
!          On entry, the m by n matrix C.
!          On exit, C is overwritten by the matrix H * C if SIDE = 'L',
!          or C * H if SIDE = 'R'.
!
!  LDC     (input) INTEGER
!          The leading dimension of the array C. LDA >= (1,M).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension
!                      (N) if SIDE = 'L'
!                      or (M) if SIDE = 'R'
!          WORK is not referenced if H has order < 11.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            J
DOUBLE PRECISION   SUM, T1, T10, T2, T3, T4, T5, T6, T7, T8, T9, &
                       V1, V10, V2, V3, V4, V5, V6, V7, V8, V9
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMV, DGER
!     ..
!     .. Executable Statements ..
!
IF( TAU.EQ.ZERO ) &
       RETURN
IF( LSAME( SIDE, 'L' ) ) THEN
!
!        Form  H * C, where H has order m.
!
   GO TO ( 10, 30, 50, 70, 90, 110, 130, 150, &
               170, 190 )M
!
!        Code for general M
!
!        w := C'*v
!
   CALL DGEMV( 'Transpose', M, N, ONE, C, LDC, V, 1, ZERO, WORK, &
                   1 )
!
!        C := C - tau * v * w'
!
   CALL DGER( M, N, -TAU, V, 1, WORK, 1, C, LDC )
   GO TO 410
10    CONTINUE
!
!        Special code for 1 x 1 Householder
!
   T1 = ONE - TAU*V( 1 )*V( 1 )
   DO 20 J = 1, N
      C( 1, J ) = T1*C( 1, J )
20    CONTINUE
   GO TO 410
30    CONTINUE
!
!        Special code for 2 x 2 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   DO 40 J = 1, N
      SUM = V1*C( 1, J ) + V2*C( 2, J )
      C( 1, J ) = C( 1, J ) - SUM*T1
      C( 2, J ) = C( 2, J ) - SUM*T2
40    CONTINUE
   GO TO 410
50    CONTINUE
!
!        Special code for 3 x 3 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   DO 60 J = 1, N
      SUM = V1*C( 1, J ) + V2*C( 2, J ) + V3*C( 3, J )
      C( 1, J ) = C( 1, J ) - SUM*T1
      C( 2, J ) = C( 2, J ) - SUM*T2
      C( 3, J ) = C( 3, J ) - SUM*T3
60    CONTINUE
   GO TO 410
70    CONTINUE
!
!        Special code for 4 x 4 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   DO 80 J = 1, N
      SUM = V1*C( 1, J ) + V2*C( 2, J ) + V3*C( 3, J ) + &
                V4*C( 4, J )
      C( 1, J ) = C( 1, J ) - SUM*T1
      C( 2, J ) = C( 2, J ) - SUM*T2
      C( 3, J ) = C( 3, J ) - SUM*T3
      C( 4, J ) = C( 4, J ) - SUM*T4
80    CONTINUE
   GO TO 410
90    CONTINUE
!
!        Special code for 5 x 5 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   DO 100 J = 1, N
      SUM = V1*C( 1, J ) + V2*C( 2, J ) + V3*C( 3, J ) + &
                V4*C( 4, J ) + V5*C( 5, J )
      C( 1, J ) = C( 1, J ) - SUM*T1
      C( 2, J ) = C( 2, J ) - SUM*T2
      C( 3, J ) = C( 3, J ) - SUM*T3
      C( 4, J ) = C( 4, J ) - SUM*T4
      C( 5, J ) = C( 5, J ) - SUM*T5
100    CONTINUE
   GO TO 410
110    CONTINUE
!
!        Special code for 6 x 6 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   DO 120 J = 1, N
      SUM = V1*C( 1, J ) + V2*C( 2, J ) + V3*C( 3, J ) + &
                V4*C( 4, J ) + V5*C( 5, J ) + V6*C( 6, J )
      C( 1, J ) = C( 1, J ) - SUM*T1
      C( 2, J ) = C( 2, J ) - SUM*T2
      C( 3, J ) = C( 3, J ) - SUM*T3
      C( 4, J ) = C( 4, J ) - SUM*T4
      C( 5, J ) = C( 5, J ) - SUM*T5
      C( 6, J ) = C( 6, J ) - SUM*T6
120    CONTINUE
   GO TO 410
130    CONTINUE
!
!        Special code for 7 x 7 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   V7 = V( 7 )
   T7 = TAU*V7
   DO 140 J = 1, N
      SUM = V1*C( 1, J ) + V2*C( 2, J ) + V3*C( 3, J ) + &
                V4*C( 4, J ) + V5*C( 5, J ) + V6*C( 6, J ) + &
                V7*C( 7, J )
      C( 1, J ) = C( 1, J ) - SUM*T1
      C( 2, J ) = C( 2, J ) - SUM*T2
      C( 3, J ) = C( 3, J ) - SUM*T3
      C( 4, J ) = C( 4, J ) - SUM*T4
      C( 5, J ) = C( 5, J ) - SUM*T5
      C( 6, J ) = C( 6, J ) - SUM*T6
      C( 7, J ) = C( 7, J ) - SUM*T7
140    CONTINUE
   GO TO 410
150    CONTINUE
!
!        Special code for 8 x 8 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   V7 = V( 7 )
   T7 = TAU*V7
   V8 = V( 8 )
   T8 = TAU*V8
   DO 160 J = 1, N
      SUM = V1*C( 1, J ) + V2*C( 2, J ) + V3*C( 3, J ) + &
                V4*C( 4, J ) + V5*C( 5, J ) + V6*C( 6, J ) + &
                V7*C( 7, J ) + V8*C( 8, J )
      C( 1, J ) = C( 1, J ) - SUM*T1
      C( 2, J ) = C( 2, J ) - SUM*T2
      C( 3, J ) = C( 3, J ) - SUM*T3
      C( 4, J ) = C( 4, J ) - SUM*T4
      C( 5, J ) = C( 5, J ) - SUM*T5
      C( 6, J ) = C( 6, J ) - SUM*T6
      C( 7, J ) = C( 7, J ) - SUM*T7
      C( 8, J ) = C( 8, J ) - SUM*T8
160    CONTINUE
   GO TO 410
170    CONTINUE
!
!        Special code for 9 x 9 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   V7 = V( 7 )
   T7 = TAU*V7
   V8 = V( 8 )
   T8 = TAU*V8
   V9 = V( 9 )
   T9 = TAU*V9
   DO 180 J = 1, N
      SUM = V1*C( 1, J ) + V2*C( 2, J ) + V3*C( 3, J ) + &
                V4*C( 4, J ) + V5*C( 5, J ) + V6*C( 6, J ) + &
                V7*C( 7, J ) + V8*C( 8, J ) + V9*C( 9, J )
      C( 1, J ) = C( 1, J ) - SUM*T1
      C( 2, J ) = C( 2, J ) - SUM*T2
      C( 3, J ) = C( 3, J ) - SUM*T3
      C( 4, J ) = C( 4, J ) - SUM*T4
      C( 5, J ) = C( 5, J ) - SUM*T5
      C( 6, J ) = C( 6, J ) - SUM*T6
      C( 7, J ) = C( 7, J ) - SUM*T7
      C( 8, J ) = C( 8, J ) - SUM*T8
      C( 9, J ) = C( 9, J ) - SUM*T9
180    CONTINUE
   GO TO 410
190    CONTINUE
!
!        Special code for 10 x 10 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   V7 = V( 7 )
   T7 = TAU*V7
   V8 = V( 8 )
   T8 = TAU*V8
   V9 = V( 9 )
   T9 = TAU*V9
   V10 = V( 10 )
   T10 = TAU*V10
   DO 200 J = 1, N
      SUM = V1*C( 1, J ) + V2*C( 2, J ) + V3*C( 3, J ) + &
                V4*C( 4, J ) + V5*C( 5, J ) + V6*C( 6, J ) + &
                V7*C( 7, J ) + V8*C( 8, J ) + V9*C( 9, J ) + &
                V10*C( 10, J )
      C( 1, J ) = C( 1, J ) - SUM*T1
      C( 2, J ) = C( 2, J ) - SUM*T2
      C( 3, J ) = C( 3, J ) - SUM*T3
      C( 4, J ) = C( 4, J ) - SUM*T4
      C( 5, J ) = C( 5, J ) - SUM*T5
      C( 6, J ) = C( 6, J ) - SUM*T6
      C( 7, J ) = C( 7, J ) - SUM*T7
      C( 8, J ) = C( 8, J ) - SUM*T8
      C( 9, J ) = C( 9, J ) - SUM*T9
      C( 10, J ) = C( 10, J ) - SUM*T10
200    CONTINUE
   GO TO 410
ELSE
!
!        Form  C * H, where H has order n.
!
   GO TO ( 210, 230, 250, 270, 290, 310, 330, 350, &
               370, 390 )N
!
!        Code for general N
!
!        w := C * v
!
   CALL DGEMV( 'No transpose', M, N, ONE, C, LDC, V, 1, ZERO, &
                   WORK, 1 )
!
!        C := C - tau * w * v'
!
   CALL DGER( M, N, -TAU, WORK, 1, V, 1, C, LDC )
   GO TO 410
210    CONTINUE
!
!        Special code for 1 x 1 Householder
!
   T1 = ONE - TAU*V( 1 )*V( 1 )
   DO 220 J = 1, M
      C( J, 1 ) = T1*C( J, 1 )
220    CONTINUE
   GO TO 410
230    CONTINUE
!
!        Special code for 2 x 2 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   DO 240 J = 1, M
      SUM = V1*C( J, 1 ) + V2*C( J, 2 )
      C( J, 1 ) = C( J, 1 ) - SUM*T1
      C( J, 2 ) = C( J, 2 ) - SUM*T2
240    CONTINUE
   GO TO 410
250    CONTINUE
!
!        Special code for 3 x 3 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   DO 260 J = 1, M
      SUM = V1*C( J, 1 ) + V2*C( J, 2 ) + V3*C( J, 3 )
      C( J, 1 ) = C( J, 1 ) - SUM*T1
      C( J, 2 ) = C( J, 2 ) - SUM*T2
      C( J, 3 ) = C( J, 3 ) - SUM*T3
260    CONTINUE
   GO TO 410
270    CONTINUE
!
!        Special code for 4 x 4 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   DO 280 J = 1, M
      SUM = V1*C( J, 1 ) + V2*C( J, 2 ) + V3*C( J, 3 ) + &
                V4*C( J, 4 )
      C( J, 1 ) = C( J, 1 ) - SUM*T1
      C( J, 2 ) = C( J, 2 ) - SUM*T2
      C( J, 3 ) = C( J, 3 ) - SUM*T3
      C( J, 4 ) = C( J, 4 ) - SUM*T4
280    CONTINUE
   GO TO 410
290    CONTINUE
!
!        Special code for 5 x 5 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   DO 300 J = 1, M
      SUM = V1*C( J, 1 ) + V2*C( J, 2 ) + V3*C( J, 3 ) + &
                V4*C( J, 4 ) + V5*C( J, 5 )
      C( J, 1 ) = C( J, 1 ) - SUM*T1
      C( J, 2 ) = C( J, 2 ) - SUM*T2
      C( J, 3 ) = C( J, 3 ) - SUM*T3
      C( J, 4 ) = C( J, 4 ) - SUM*T4
      C( J, 5 ) = C( J, 5 ) - SUM*T5
300    CONTINUE
   GO TO 410
310    CONTINUE
!
!        Special code for 6 x 6 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   DO 320 J = 1, M
      SUM = V1*C( J, 1 ) + V2*C( J, 2 ) + V3*C( J, 3 ) + &
                V4*C( J, 4 ) + V5*C( J, 5 ) + V6*C( J, 6 )
      C( J, 1 ) = C( J, 1 ) - SUM*T1
      C( J, 2 ) = C( J, 2 ) - SUM*T2
      C( J, 3 ) = C( J, 3 ) - SUM*T3
      C( J, 4 ) = C( J, 4 ) - SUM*T4
      C( J, 5 ) = C( J, 5 ) - SUM*T5
      C( J, 6 ) = C( J, 6 ) - SUM*T6
320    CONTINUE
   GO TO 410
330    CONTINUE
!
!        Special code for 7 x 7 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   V7 = V( 7 )
   T7 = TAU*V7
   DO 340 J = 1, M
      SUM = V1*C( J, 1 ) + V2*C( J, 2 ) + V3*C( J, 3 ) + &
                V4*C( J, 4 ) + V5*C( J, 5 ) + V6*C( J, 6 ) + &
                V7*C( J, 7 )
      C( J, 1 ) = C( J, 1 ) - SUM*T1
      C( J, 2 ) = C( J, 2 ) - SUM*T2
      C( J, 3 ) = C( J, 3 ) - SUM*T3
      C( J, 4 ) = C( J, 4 ) - SUM*T4
      C( J, 5 ) = C( J, 5 ) - SUM*T5
      C( J, 6 ) = C( J, 6 ) - SUM*T6
      C( J, 7 ) = C( J, 7 ) - SUM*T7
340    CONTINUE
   GO TO 410
350    CONTINUE
!
!        Special code for 8 x 8 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   V7 = V( 7 )
   T7 = TAU*V7
   V8 = V( 8 )
   T8 = TAU*V8
   DO 360 J = 1, M
      SUM = V1*C( J, 1 ) + V2*C( J, 2 ) + V3*C( J, 3 ) + &
                V4*C( J, 4 ) + V5*C( J, 5 ) + V6*C( J, 6 ) + &
                V7*C( J, 7 ) + V8*C( J, 8 )
      C( J, 1 ) = C( J, 1 ) - SUM*T1
      C( J, 2 ) = C( J, 2 ) - SUM*T2
      C( J, 3 ) = C( J, 3 ) - SUM*T3
      C( J, 4 ) = C( J, 4 ) - SUM*T4
      C( J, 5 ) = C( J, 5 ) - SUM*T5
      C( J, 6 ) = C( J, 6 ) - SUM*T6
      C( J, 7 ) = C( J, 7 ) - SUM*T7
      C( J, 8 ) = C( J, 8 ) - SUM*T8
360    CONTINUE
   GO TO 410
370    CONTINUE
!
!        Special code for 9 x 9 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   V7 = V( 7 )
   T7 = TAU*V7
   V8 = V( 8 )
   T8 = TAU*V8
   V9 = V( 9 )
   T9 = TAU*V9
   DO 380 J = 1, M
      SUM = V1*C( J, 1 ) + V2*C( J, 2 ) + V3*C( J, 3 ) + &
                V4*C( J, 4 ) + V5*C( J, 5 ) + V6*C( J, 6 ) + &
                V7*C( J, 7 ) + V8*C( J, 8 ) + V9*C( J, 9 )
      C( J, 1 ) = C( J, 1 ) - SUM*T1
      C( J, 2 ) = C( J, 2 ) - SUM*T2
      C( J, 3 ) = C( J, 3 ) - SUM*T3
      C( J, 4 ) = C( J, 4 ) - SUM*T4
      C( J, 5 ) = C( J, 5 ) - SUM*T5
      C( J, 6 ) = C( J, 6 ) - SUM*T6
      C( J, 7 ) = C( J, 7 ) - SUM*T7
      C( J, 8 ) = C( J, 8 ) - SUM*T8
      C( J, 9 ) = C( J, 9 ) - SUM*T9
380    CONTINUE
   GO TO 410
390    CONTINUE
!
!        Special code for 10 x 10 Householder
!
   V1 = V( 1 )
   T1 = TAU*V1
   V2 = V( 2 )
   T2 = TAU*V2
   V3 = V( 3 )
   T3 = TAU*V3
   V4 = V( 4 )
   T4 = TAU*V4
   V5 = V( 5 )
   T5 = TAU*V5
   V6 = V( 6 )
   T6 = TAU*V6
   V7 = V( 7 )
   T7 = TAU*V7
   V8 = V( 8 )
   T8 = TAU*V8
   V9 = V( 9 )
   T9 = TAU*V9
   V10 = V( 10 )
   T10 = TAU*V10
   DO 400 J = 1, M
      SUM = V1*C( J, 1 ) + V2*C( J, 2 ) + V3*C( J, 3 ) + &
                V4*C( J, 4 ) + V5*C( J, 5 ) + V6*C( J, 6 ) + &
                V7*C( J, 7 ) + V8*C( J, 8 ) + V9*C( J, 9 ) + &
                V10*C( J, 10 )
      C( J, 1 ) = C( J, 1 ) - SUM*T1
      C( J, 2 ) = C( J, 2 ) - SUM*T2
      C( J, 3 ) = C( J, 3 ) - SUM*T3
      C( J, 4 ) = C( J, 4 ) - SUM*T4
      C( J, 5 ) = C( J, 5 ) - SUM*T5
      C( J, 6 ) = C( J, 6 ) - SUM*T6
      C( J, 7 ) = C( J, 7 ) - SUM*T7
      C( J, 8 ) = C( J, 8 ) - SUM*T8
      C( J, 9 ) = C( J, 9 ) - SUM*T9
      C( J, 10 ) = C( J, 10 ) - SUM*T10
400    CONTINUE
   GO TO 410
END IF
410 CONTINUE
RETURN
!
!     End of DLARFX
!
end subroutine dlarfx

! ===== End dlarfx.f90 =====


! ===== Begin dlargv.f90 =====

SUBROUTINE DLARGV( N, X, INCX, Y, INCY, C, INCC )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            INCC, INCX, INCY, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   C( * ), X( * ), Y( * )
!     ..
!
!  Purpose
!  =======
!
!  DLARGV generates a vector of real plane rotations, determined by
!  elements of the real vectors x and y. For i = 1,2,...,n
!
!     (  c(i)  s(i) ) ( x(i) ) = ( a(i) )
!     ( -s(i)  c(i) ) ( y(i) ) = (   0  )
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of plane rotations to be generated.
!
!  X       (input/output) DOUBLE PRECISION array,
!                         dimension (1+(N-1)*INCX)
!          On entry, the vector x.
!          On exit, x(i) is overwritten by a(i), for i = 1,...,n.
!
!  INCX    (input) INTEGER
!          The increment between elements of X. INCX > 0.
!
!  Y       (input/output) DOUBLE PRECISION array,
!                         dimension (1+(N-1)*INCY)
!          On entry, the vector y.
!          On exit, the sines of the plane rotations.
!
!  INCY    (input) INTEGER
!          The increment between elements of Y. INCY > 0.
!
!  C       (output) DOUBLE PRECISION array, dimension (1+(N-1)*INCC)
!          The cosines of the plane rotations.
!
!  INCC    (input) INTEGER
!          The increment between elements of C. INCC > 0.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, IC, IX, IY
DOUBLE PRECISION   F, G, T, TT
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, SQRT
!     ..
!     .. Executable Statements ..
!
IX = 1
IY = 1
IC = 1
DO 10 I = 1, N
   F = X( IX )
   G = Y( IY )
   IF( G.EQ.ZERO ) THEN
      C( IC ) = ONE
   ELSE IF( F.EQ.ZERO ) THEN
      C( IC ) = ZERO
      Y( IY ) = ONE
      X( IX ) = G
   ELSE IF( ABS( F ).GT.ABS( G ) ) THEN
      T = G / F
      TT = SQRT( ONE+T*T )
      C( IC ) = ONE / TT
      Y( IY ) = T*C( IC )
      X( IX ) = F*TT
   ELSE
      T = F / G
      TT = SQRT( ONE+T*T )
      Y( IY ) = ONE / TT
      C( IC ) = T*Y( IY )
      X( IX ) = G*TT
   END IF
   IC = IC + INCC
   IY = IY + INCY
   IX = IX + INCX
10 CONTINUE
RETURN
!
!     End of DLARGV
!
end subroutine dlargv

! ===== End dlargv.f90 =====


! ===== Begin dlarnd.f90 =====

DOUBLE PRECISION FUNCTION DLARND( IDIST, ISEED )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
INTEGER            IDIST
!     ..
!     .. Array Arguments ..
INTEGER            ISEED( 4 )
!     ..
!
!  Purpose
!  =======
!
!  DLARND returns a random real number from a uniform or normal
!  distribution.
!
!  Arguments
!  =========
!
!  IDIST   (input) INTEGER
!          Specifies the distribution of the random numbers:
!          = 1:  uniform (0,1)
!          = 2:  uniform (-1,1)
!          = 3:  normal (0,1)
!
!  ISEED   (input/output) INTEGER array, dimension (4)
!          On entry, the seed of the random number generator; the array
!          elements must be between 0 and 4095, and ISEED(4) must be
!          odd.
!          On exit, the seed is updated.
!
!  Further Details
!  ===============
!
!  This routine calls the auxiliary routine DLARAN to generate a random
!  real number from a uniform (0,1) distribution. The Box-Muller method
!  is used to transform numbers from a uniform to a normal distribution.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, TWO
PARAMETER          ( ONE = 1.0D+0, TWO = 2.0D+0 )
DOUBLE PRECISION   TWOPI
PARAMETER          ( TWOPI = 6.2831853071795864769252867663D+0 )
!     ..
!     .. Local Scalars ..
DOUBLE PRECISION   T1, T2
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLARAN
EXTERNAL           DLARAN
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          COS, LOG, SQRT
!     ..
!     .. Executable Statements ..
!
!     Generate a real random number from a uniform (0,1) distribution
!
T1 = DLARAN( ISEED )
!
IF( IDIST.EQ.1 ) THEN
!
!        uniform (0,1)
!
   DLARND = T1
ELSE IF( IDIST.EQ.2 ) THEN
!
!        uniform (-1,1)
!
   DLARND = TWO*T1 - ONE
ELSE IF( IDIST.EQ.3 ) THEN
!
!        normal (0,1)
!
   T2 = DLARAN( ISEED )
   DLARND = SQRT( -TWO*LOG( T1 ) )*COS( TWOPI*T2 )
END IF
RETURN
!
!     End of DLARND
!
end function dlarnd

! ===== End dlarnd.f90 =====


! ===== Begin dlarnv.f90 =====

SUBROUTINE DLARNV( IDIST, ISEED, N, X )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
INTEGER            IDIST, N
!     ..
!     .. Array Arguments ..
INTEGER            ISEED( 4 )
DOUBLE PRECISION   X( * )
!     ..
!
!  Purpose
!  =======
!
!  DLARNV returns a vector of n random real numbers from a uniform or
!  normal distribution.
!
!  Arguments
!  =========
!
!  IDIST   (input) INTEGER
!          Specifies the distribution of the random numbers:
!          = 1:  uniform (0,1)
!          = 2:  uniform (-1,1)
!          = 3:  normal (0,1)
!
!  ISEED   (input/output) INTEGER array, dimension (4)
!          On entry, the seed of the random number generator; the array
!          elements must be between 0 and 4095, and ISEED(4) must be
!          odd.
!          On exit, the seed is updated.
!
!  N       (input) INTEGER
!          The number of random numbers to be generated.
!
!  X       (output) DOUBLE PRECISION array, dimension (N)
!          The generated random numbers.
!
!  Further Details
!  ===============
!
!  This routine calls the auxiliary routine DLARUV to generate random
!  real numbers from a uniform (0,1) distribution, in batches of up to
!  128 using vectorisable code. The Box-Muller method is used to
!  transform numbers from a uniform to a normal distribution.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, TWO
PARAMETER          ( ONE = 1.0D+0, TWO = 2.0D+0 )
INTEGER            LV
PARAMETER          ( LV = 128 )
DOUBLE PRECISION   TWOPI
PARAMETER          ( TWOPI = 6.2831853071795864769252867663D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, IL, IL2, IV
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   U( LV )
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          COS, LOG, MIN, SQRT
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARUV
!     ..
!     .. Executable Statements ..
!
DO 40 IV = 1, N, LV / 2
   IL = MIN( LV / 2, N-IV+1 )
   IF( IDIST.EQ.3 ) THEN
      IL2 = 2*IL
   ELSE
      IL2 = IL
   END IF
!
!        Call DLARUV to generate IL2 numbers from a uniform (0,1)
!        distribution (IL2 <= LV)
!
   CALL DLARUV( ISEED, IL2, U )
!
   IF( IDIST.EQ.1 ) THEN
!
!           Copy generated numbers
!
      DO 10 I = 1, IL
         X( IV+I-1 ) = U( I )
10       CONTINUE
   ELSE IF( IDIST.EQ.2 ) THEN
!
!           Convert generated numbers to uniform (-1,1) distribution
!
      DO 20 I = 1, IL
         X( IV+I-1 ) = TWO*U( I ) - ONE
20       CONTINUE
   ELSE IF( IDIST.EQ.3 ) THEN
!
!           Convert generated numbers to normal (0,1) distribution
!
      DO 30 I = 1, IL
         X( IV+I-1 ) = SQRT( -TWO*LOG( U( 2*I-1 ) ) )* &
                           COS( TWOPI*U( 2*I ) )
30       CONTINUE
   END IF
40 CONTINUE
RETURN
!
!     End of DLARNV
!
end subroutine dlarnv

! ===== End dlarnv.f90 =====


! ===== Begin dlartg.f90 =====

SUBROUTINE DLARTG( F, G, CS, SN, R )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   CS, F, G, R, SN
!     ..
!
!  Purpose
!  =======
!
!  DLARTG generate a plane rotation so that
!
!     [  CS  SN  ]  .  [ F ]  =  [ R ]   where CS**2 + SN**2 = 1.
!     [ -SN  CS  ]     [ G ]     [ 0 ]
!
!  This is a slower, more accurate version of the BLAS1 routine DROTG,
!  with the following other differences:
!     F and G are unchanged on return.
!     If G=0, then CS=1 and SN=0.
!     If F=0 and (G .ne. 0), then CS=0 and SN=1 without doing any
!        floating point operations (saves work in DBDSQR when
!        there are zeros on the diagonal).
!
!  If F exceeds G in magnitude, CS will be positive.
!
!  Arguments
!  =========
!
!  F       (input) DOUBLE PRECISION
!          The first component of vector to be rotated.
!
!  G       (input) DOUBLE PRECISION
!          The second component of vector to be rotated.
!
!  CS      (output) DOUBLE PRECISION
!          The cosine of the rotation.
!
!  SN      (output) DOUBLE PRECISION
!          The sine of the rotation.
!
!  R       (output) DOUBLE PRECISION
!          The nonzero component of the rotated vector.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D0 )
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D0 )
DOUBLE PRECISION   TWO
PARAMETER          ( TWO = 2.0D0 )
!     ..
!     .. Local Scalars ..
LOGICAL            FIRST
INTEGER            COUNT, I
DOUBLE PRECISION   EPS, F1, G1, SAFMIN, SAFMN2, SAFMX2, SCALE
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMCH
EXTERNAL           DLAMCH
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, INT, LOG, MAX, SQRT
!     ..
!     .. Save statement ..
SAVE               FIRST, SAFMX2, SAFMIN, SAFMN2
!     ..
!     .. Data statements ..
DATA               FIRST / .TRUE. /
!     ..
!     .. Executable Statements ..
!
IF( FIRST ) THEN
   FIRST = .FALSE.
   SAFMIN = DLAMCH( 'S' )
   EPS = DLAMCH( 'E' )
   SAFMN2 = DLAMCH( 'B' )**INT( LOG( SAFMIN / EPS ) / &
                LOG( DLAMCH( 'B' ) ) / TWO )
   SAFMX2 = ONE / SAFMN2
END IF
IF( G.EQ.ZERO ) THEN
   CS = ONE
   SN = ZERO
   R = F
ELSE IF( F.EQ.ZERO ) THEN
   CS = ZERO
   SN = ONE
   R = G
ELSE
   F1 = F
   G1 = G
   SCALE = MAX( ABS( F1 ), ABS( G1 ) )
   IF( SCALE.GE.SAFMX2 ) THEN
      COUNT = 0
10       CONTINUE
      COUNT = COUNT + 1
      F1 = F1*SAFMN2
      G1 = G1*SAFMN2
      SCALE = MAX( ABS( F1 ), ABS( G1 ) )
      IF( SCALE.GE.SAFMX2 ) &
             GO TO 10
      R = SQRT( F1**2+G1**2 )
      CS = F1 / R
      SN = G1 / R
      DO 20 I = 1, COUNT
         R = R*SAFMX2
20       CONTINUE
   ELSE IF( SCALE.LE.SAFMN2 ) THEN
      COUNT = 0
30       CONTINUE
      COUNT = COUNT + 1
      F1 = F1*SAFMX2
      G1 = G1*SAFMX2
      SCALE = MAX( ABS( F1 ), ABS( G1 ) )
      IF( SCALE.LE.SAFMN2 ) &
             GO TO 30
      R = SQRT( F1**2+G1**2 )
      CS = F1 / R
      SN = G1 / R
      DO 40 I = 1, COUNT
         R = R*SAFMN2
40       CONTINUE
   ELSE
      R = SQRT( F1**2+G1**2 )
      CS = F1 / R
      SN = G1 / R
   END IF
   IF( ABS( F ).GT.ABS( G ) .AND. CS.LT.ZERO ) THEN
      CS = -CS
      SN = -SN
      R = -R
   END IF
END IF
RETURN
!
!     End of DLARTG
!
end subroutine dlartg

! ===== End dlartg.f90 =====


! ===== Begin dlartv.f90 =====

SUBROUTINE DLARTV( N, X, INCX, Y, INCY, C, S, INCC )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            INCC, INCX, INCY, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   C( * ), S( * ), X( * ), Y( * )
!     ..
!
!  Purpose
!  =======
!
!  DLARTV applies a vector of real plane rotations to elements of the
!  real vectors x and y. For i = 1,2,...,n
!
!     ( x(i) ) := (  c(i)  s(i) ) ( x(i) )
!     ( y(i) )    ( -s(i)  c(i) ) ( y(i) )
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of plane rotations to be applied.
!
!  X       (input/output) DOUBLE PRECISION array,
!                         dimension (1+(N-1)*INCX)
!          The vector x.
!
!  INCX    (input) INTEGER
!          The increment between elements of X. INCX > 0.
!
!  Y       (input/output) DOUBLE PRECISION array,
!                         dimension (1+(N-1)*INCY)
!          The vector y.
!
!  INCY    (input) INTEGER
!          The increment between elements of Y. INCY > 0.
!
!  C       (input) DOUBLE PRECISION array, dimension (1+(N-1)*INCC)
!          The cosines of the plane rotations.
!
!  S       (input) DOUBLE PRECISION array, dimension (1+(N-1)*INCC)
!          The sines of the plane rotations.
!
!  INCC    (input) INTEGER
!          The increment between elements of C and S. INCC > 0.
!
!  =====================================================================
!
!     .. Local Scalars ..
INTEGER            I, IC, IX, IY
DOUBLE PRECISION   XI, YI
!     ..
!     .. Executable Statements ..
!
IX = 1
IY = 1
IC = 1
DO 10 I = 1, N
   XI = X( IX )
   YI = Y( IY )
   X( IX ) = C( IC )*XI + S( IC )*YI
   Y( IY ) = C( IC )*YI - S( IC )*XI
   IX = IX + INCX
   IY = IY + INCY
   IC = IC + INCC
10 CONTINUE
RETURN
!
!     End of DLARTV
!
end subroutine dlartv

! ===== End dlartv.f90 =====


! ===== Begin dlaruv.f90 =====

SUBROUTINE DLARUV( ISEED, N, X )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
INTEGER            N
!     ..
!     .. Array Arguments ..
INTEGER            ISEED( 4 )
DOUBLE PRECISION   X( N )
!     ..
!
!  Purpose
!  =======
!
!  DLARUV returns a vector of n random real numbers from a uniform (0,1)
!  distribution (n <= 128).
!
!  This is an auxiliary routine called by DLARNV and ZLARNV.
!
!  Arguments
!  =========
!
!  ISEED   (input/output) INTEGER array, dimension (4)
!          On entry, the seed of the random number generator; the array
!          elements must be between 0 and 4095, and ISEED(4) must be
!          odd.
!          On exit, the seed is updated.
!
!  N       (input) INTEGER
!          The number of random numbers to be generated. N <= 128.
!
!  X       (output) DOUBLE PRECISION array, dimension (N)
!          The generated random numbers.
!
!  Further Details
!  ===============
!
!  This routine uses a multiplicative congruential method with modulus
!  2**48 and multiplier 33952834046453 (see G.S.Fishman,
!  'Multiplicative congruential random number generators with modulus
!  2**b: an exhaustive analysis for b = 32 and a partial analysis for
!  b = 48', Math. Comp. 189, pp 331-344, 1990).
!
!  48-bit integers are stored in 4 integer array elements with 12 bits
!  per element. Hence the routine is portable across machines with
!  integers of 32 bits or more.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D0 )
INTEGER            LV, IPW2
DOUBLE PRECISION   R
PARAMETER          ( LV = 128, IPW2 = 4096, R = ONE / IPW2 )
!     ..
!     .. Local Scalars ..
INTEGER            I, I1, I2, I3, I4, IT1, IT2, IT3, IT4, J
!     ..
!     .. Local Arrays ..
INTEGER            MM( LV, 4 )
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          DBLE, MIN, MOD
!     ..
!     .. Data statements ..
DATA               ( MM( 1, J ), J = 1, 4 ) / 494, 322, 2508, &
                       2549 /
DATA               ( MM( 2, J ), J = 1, 4 ) / 2637, 789, 3754, &
                       1145 /
DATA               ( MM( 3, J ), J = 1, 4 ) / 255, 1440, 1766, &
                       2253 /
DATA               ( MM( 4, J ), J = 1, 4 ) / 2008, 752, 3572, &
                       305 /
DATA               ( MM( 5, J ), J = 1, 4 ) / 1253, 2859, 2893, &
                       3301 /
DATA               ( MM( 6, J ), J = 1, 4 ) / 3344, 123, 307, &
                       1065 /
DATA               ( MM( 7, J ), J = 1, 4 ) / 4084, 1848, 1297, &
                       3133 /
DATA               ( MM( 8, J ), J = 1, 4 ) / 1739, 643, 3966, &
                       2913 /
DATA               ( MM( 9, J ), J = 1, 4 ) / 3143, 2405, 758, &
                       3285 /
DATA               ( MM( 10, J ), J = 1, 4 ) / 3468, 2638, 2598, &
                       1241 /
DATA               ( MM( 11, J ), J = 1, 4 ) / 688, 2344, 3406, &
                       1197 /
DATA               ( MM( 12, J ), J = 1, 4 ) / 1657, 46, 2922, &
                       3729 /
DATA               ( MM( 13, J ), J = 1, 4 ) / 1238, 3814, 1038, &
                       2501 /
DATA               ( MM( 14, J ), J = 1, 4 ) / 3166, 913, 2934, &
                       1673 /
DATA               ( MM( 15, J ), J = 1, 4 ) / 1292, 3649, 2091, &
                       541 /
DATA               ( MM( 16, J ), J = 1, 4 ) / 3422, 339, 2451, &
                       2753 /
DATA               ( MM( 17, J ), J = 1, 4 ) / 1270, 3808, 1580, &
                       949 /
DATA               ( MM( 18, J ), J = 1, 4 ) / 2016, 822, 1958, &
                       2361 /
DATA               ( MM( 19, J ), J = 1, 4 ) / 154, 2832, 2055, &
                       1165 /
DATA               ( MM( 20, J ), J = 1, 4 ) / 2862, 3078, 1507, &
                       4081 /
DATA               ( MM( 21, J ), J = 1, 4 ) / 697, 3633, 1078, &
                       2725 /
DATA               ( MM( 22, J ), J = 1, 4 ) / 1706, 2970, 3273, &
                       3305 /
DATA               ( MM( 23, J ), J = 1, 4 ) / 491, 637, 17, &
                       3069 /
DATA               ( MM( 24, J ), J = 1, 4 ) / 931, 2249, 854, &
                       3617 /
DATA               ( MM( 25, J ), J = 1, 4 ) / 1444, 2081, 2916, &
                       3733 /
DATA               ( MM( 26, J ), J = 1, 4 ) / 444, 4019, 3971, &
                       409 /
DATA               ( MM( 27, J ), J = 1, 4 ) / 3577, 1478, 2889, &
                       2157 /
DATA               ( MM( 28, J ), J = 1, 4 ) / 3944, 242, 3831, &
                       1361 /
DATA               ( MM( 29, J ), J = 1, 4 ) / 2184, 481, 2621, &
                       3973 /
DATA               ( MM( 30, J ), J = 1, 4 ) / 1661, 2075, 1541, &
                       1865 /
DATA               ( MM( 31, J ), J = 1, 4 ) / 3482, 4058, 893, &
                       2525 /
DATA               ( MM( 32, J ), J = 1, 4 ) / 657, 622, 736, &
                       1409 /
DATA               ( MM( 33, J ), J = 1, 4 ) / 3023, 3376, 3992, &
                       3445 /
DATA               ( MM( 34, J ), J = 1, 4 ) / 3618, 812, 787, &
                       3577 /
DATA               ( MM( 35, J ), J = 1, 4 ) / 1267, 234, 2125, &
                       77 /
DATA               ( MM( 36, J ), J = 1, 4 ) / 1828, 641, 2364, &
                       3761 /
DATA               ( MM( 37, J ), J = 1, 4 ) / 164, 4005, 2460, &
                       2149 /
DATA               ( MM( 38, J ), J = 1, 4 ) / 3798, 1122, 257, &
                       1449 /
DATA               ( MM( 39, J ), J = 1, 4 ) / 3087, 3135, 1574, &
                       3005 /
DATA               ( MM( 40, J ), J = 1, 4 ) / 2400, 2640, 3912, &
                       225 /
DATA               ( MM( 41, J ), J = 1, 4 ) / 2870, 2302, 1216, &
                       85 /
DATA               ( MM( 42, J ), J = 1, 4 ) / 3876, 40, 3248, &
                       3673 /
DATA               ( MM( 43, J ), J = 1, 4 ) / 1905, 1832, 3401, &
                       3117 /
DATA               ( MM( 44, J ), J = 1, 4 ) / 1593, 2247, 2124, &
                       3089 /
DATA               ( MM( 45, J ), J = 1, 4 ) / 1797, 2034, 2762, &
                       1349 /
DATA               ( MM( 46, J ), J = 1, 4 ) / 1234, 2637, 149, &
                       2057 /
DATA               ( MM( 47, J ), J = 1, 4 ) / 3460, 1287, 2245, &
                       413 /
DATA               ( MM( 48, J ), J = 1, 4 ) / 328, 1691, 166, &
                       65 /
DATA               ( MM( 49, J ), J = 1, 4 ) / 2861, 496, 466, &
                       1845 /
DATA               ( MM( 50, J ), J = 1, 4 ) / 1950, 1597, 4018, &
                       697 /
DATA               ( MM( 51, J ), J = 1, 4 ) / 617, 2394, 1399, &
                       3085 /
DATA               ( MM( 52, J ), J = 1, 4 ) / 2070, 2584, 190, &
                       3441 /
DATA               ( MM( 53, J ), J = 1, 4 ) / 3331, 1843, 2879, &
                       1573 /
DATA               ( MM( 54, J ), J = 1, 4 ) / 769, 336, 153, &
                       3689 /
DATA               ( MM( 55, J ), J = 1, 4 ) / 1558, 1472, 2320, &
                       2941 /
DATA               ( MM( 56, J ), J = 1, 4 ) / 2412, 2407, 18, &
                       929 /
DATA               ( MM( 57, J ), J = 1, 4 ) / 2800, 433, 712, &
                       533 /
DATA               ( MM( 58, J ), J = 1, 4 ) / 189, 2096, 2159, &
                       2841 /
DATA               ( MM( 59, J ), J = 1, 4 ) / 287, 1761, 2318, &
                       4077 /
DATA               ( MM( 60, J ), J = 1, 4 ) / 2045, 2810, 2091, &
                       721 /
DATA               ( MM( 61, J ), J = 1, 4 ) / 1227, 566, 3443, &
                       2821 /
DATA               ( MM( 62, J ), J = 1, 4 ) / 2838, 442, 1510, &
                       2249 /
DATA               ( MM( 63, J ), J = 1, 4 ) / 209, 41, 449, &
                       2397 /
DATA               ( MM( 64, J ), J = 1, 4 ) / 2770, 1238, 1956, &
                       2817 /
DATA               ( MM( 65, J ), J = 1, 4 ) / 3654, 1086, 2201, &
                       245 /
DATA               ( MM( 66, J ), J = 1, 4 ) / 3993, 603, 3137, &
                       1913 /
DATA               ( MM( 67, J ), J = 1, 4 ) / 192, 840, 3399, &
                       1997 /
DATA               ( MM( 68, J ), J = 1, 4 ) / 2253, 3168, 1321, &
                       3121 /
DATA               ( MM( 69, J ), J = 1, 4 ) / 3491, 1499, 2271, &
                       997 /
DATA               ( MM( 70, J ), J = 1, 4 ) / 2889, 1084, 3667, &
                       1833 /
DATA               ( MM( 71, J ), J = 1, 4 ) / 2857, 3438, 2703, &
                       2877 /
DATA               ( MM( 72, J ), J = 1, 4 ) / 2094, 2408, 629, &
                       1633 /
DATA               ( MM( 73, J ), J = 1, 4 ) / 1818, 1589, 2365, &
                       981 /
DATA               ( MM( 74, J ), J = 1, 4 ) / 688, 2391, 2431, &
                       2009 /
DATA               ( MM( 75, J ), J = 1, 4 ) / 1407, 288, 1113, &
                       941 /
DATA               ( MM( 76, J ), J = 1, 4 ) / 634, 26, 3922, &
                       2449 /
DATA               ( MM( 77, J ), J = 1, 4 ) / 3231, 512, 2554, &
                       197 /
DATA               ( MM( 78, J ), J = 1, 4 ) / 815, 1456, 184, &
                       2441 /
DATA               ( MM( 79, J ), J = 1, 4 ) / 3524, 171, 2099, &
                       285 /
DATA               ( MM( 80, J ), J = 1, 4 ) / 1914, 1677, 3228, &
                       1473 /
DATA               ( MM( 81, J ), J = 1, 4 ) / 516, 2657, 4012, &
                       2741 /
DATA               ( MM( 82, J ), J = 1, 4 ) / 164, 2270, 1921, &
                       3129 /
DATA               ( MM( 83, J ), J = 1, 4 ) / 303, 2587, 3452, &
                       909 /
DATA               ( MM( 84, J ), J = 1, 4 ) / 2144, 2961, 3901, &
                       2801 /
DATA               ( MM( 85, J ), J = 1, 4 ) / 3480, 1970, 572, &
                       421 /
DATA               ( MM( 86, J ), J = 1, 4 ) / 119, 1817, 3309, &
                       4073 /
DATA               ( MM( 87, J ), J = 1, 4 ) / 3357, 676, 3171, &
                       2813 /
DATA               ( MM( 88, J ), J = 1, 4 ) / 837, 1410, 817, &
                       2337 /
DATA               ( MM( 89, J ), J = 1, 4 ) / 2826, 3723, 3039, &
                       1429 /
DATA               ( MM( 90, J ), J = 1, 4 ) / 2332, 2803, 1696, &
                       1177 /
DATA               ( MM( 91, J ), J = 1, 4 ) / 2089, 3185, 1256, &
                       1901 /
DATA               ( MM( 92, J ), J = 1, 4 ) / 3780, 184, 3715, &
                       81 /
DATA               ( MM( 93, J ), J = 1, 4 ) / 1700, 663, 2077, &
                       1669 /
DATA               ( MM( 94, J ), J = 1, 4 ) / 3712, 499, 3019, &
                       2633 /
DATA               ( MM( 95, J ), J = 1, 4 ) / 150, 3784, 1497, &
                       2269 /
DATA               ( MM( 96, J ), J = 1, 4 ) / 2000, 1631, 1101, &
                       129 /
DATA               ( MM( 97, J ), J = 1, 4 ) / 3375, 1925, 717, &
                       1141 /
DATA               ( MM( 98, J ), J = 1, 4 ) / 1621, 3912, 51, &
                       249 /
DATA               ( MM( 99, J ), J = 1, 4 ) / 3090, 1398, 981, &
                       3917 /
DATA               ( MM( 100, J ), J = 1, 4 ) / 3765, 1349, 1978, &
                       2481 /
DATA               ( MM( 101, J ), J = 1, 4 ) / 1149, 1441, 1813, &
                       3941 /
DATA               ( MM( 102, J ), J = 1, 4 ) / 3146, 2224, 3881, &
                       2217 /
DATA               ( MM( 103, J ), J = 1, 4 ) / 33, 2411, 76, &
                       2749 /
DATA               ( MM( 104, J ), J = 1, 4 ) / 3082, 1907, 3846, &
                       3041 /
DATA               ( MM( 105, J ), J = 1, 4 ) / 2741, 3192, 3694, &
                       1877 /
DATA               ( MM( 106, J ), J = 1, 4 ) / 359, 2786, 1682, &
                       345 /
DATA               ( MM( 107, J ), J = 1, 4 ) / 3316, 382, 124, &
                       2861 /
DATA               ( MM( 108, J ), J = 1, 4 ) / 1749, 37, 1660, &
                       1809 /
DATA               ( MM( 109, J ), J = 1, 4 ) / 185, 759, 3997, &
                       3141 /
DATA               ( MM( 110, J ), J = 1, 4 ) / 2784, 2948, 479, &
                       2825 /
DATA               ( MM( 111, J ), J = 1, 4 ) / 2202, 1862, 1141, &
                       157 /
DATA               ( MM( 112, J ), J = 1, 4 ) / 2199, 3802, 886, &
                       2881 /
DATA               ( MM( 113, J ), J = 1, 4 ) / 1364, 2423, 3514, &
                       3637 /
DATA               ( MM( 114, J ), J = 1, 4 ) / 1244, 2051, 1301, &
                       1465 /
DATA               ( MM( 115, J ), J = 1, 4 ) / 2020, 2295, 3604, &
                       2829 /
DATA               ( MM( 116, J ), J = 1, 4 ) / 3160, 1332, 1888, &
                       2161 /
DATA               ( MM( 117, J ), J = 1, 4 ) / 2785, 1832, 1836, &
                       3365 /
DATA               ( MM( 118, J ), J = 1, 4 ) / 2772, 2405, 1990, &
                       361 /
DATA               ( MM( 119, J ), J = 1, 4 ) / 1217, 3638, 2058, &
                       2685 /
DATA               ( MM( 120, J ), J = 1, 4 ) / 1822, 3661, 692, &
                       3745 /
DATA               ( MM( 121, J ), J = 1, 4 ) / 1245, 327, 1194, &
                       2325 /
DATA               ( MM( 122, J ), J = 1, 4 ) / 2252, 3660, 20, &
                       3609 /
DATA               ( MM( 123, J ), J = 1, 4 ) / 3904, 716, 3285, &
                       3821 /
DATA               ( MM( 124, J ), J = 1, 4 ) / 2774, 1842, 2046, &
                       3537 /
DATA               ( MM( 125, J ), J = 1, 4 ) / 997, 3987, 2107, &
                       517 /
DATA               ( MM( 126, J ), J = 1, 4 ) / 2573, 1368, 3508, &
                       3017 /
DATA               ( MM( 127, J ), J = 1, 4 ) / 1148, 1848, 3525, &
                       2141 /
DATA               ( MM( 128, J ), J = 1, 4 ) / 545, 2366, 3801, &
                       1537 /
!     ..
!     .. Executable Statements ..
!
I1 = ISEED( 1 )
I2 = ISEED( 2 )
I3 = ISEED( 3 )
I4 = ISEED( 4 )
!
DO 10 I = 1, MIN( N, LV )
!
!        Multiply the seed by i-th power of the multiplier modulo 2**48
!
   IT4 = I4*MM( I, 4 )
   IT3 = IT4 / IPW2
   IT4 = IT4 - IPW2*IT3
   IT3 = IT3 + I3*MM( I, 4 ) + I4*MM( I, 3 )
   IT2 = IT3 / IPW2
   IT3 = IT3 - IPW2*IT2
   IT2 = IT2 + I2*MM( I, 4 ) + I3*MM( I, 3 ) + I4*MM( I, 2 )
   IT1 = IT2 / IPW2
   IT2 = IT2 - IPW2*IT1
   IT1 = IT1 + I1*MM( I, 4 ) + I2*MM( I, 3 ) + I3*MM( I, 2 ) + &
             I4*MM( I, 1 )
   IT1 = MOD( IT1, IPW2 )
!
!        Convert 48-bit integer to a real number in the interval (0,1)
!
   X( I ) = R*( DBLE( IT1 )+R*( DBLE( IT2 )+R*( DBLE( IT3 )+R* &
                DBLE( IT4 ) ) ) )
10 CONTINUE
!
!     Return final value of seed
!
ISEED( 1 ) = IT1
ISEED( 2 ) = IT2
ISEED( 3 ) = IT3
ISEED( 4 ) = IT4
RETURN
!
!     End of DLARUV
!
end subroutine dlaruv

! ===== End dlaruv.f90 =====


! ===== Begin dlascl.f90 =====

SUBROUTINE DLASCL( TYPE, KL, KU, CFROM, CTO, M, N, A, LDA, INFO )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          TYPE
INTEGER            INFO, KL, KU, LDA, M, N
DOUBLE PRECISION   CFROM, CTO
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DLASCL multiplies the M by N real matrix A by the real scalar
!  CTO/CFROM.  This is done without over/underflow as long as the final
!  result CTO*A(I,J)/CFROM does not over/underflow. TYPE specifies that
!  A may be full, upper triangular, lower triangular, upper Hessenberg,
!  or banded.
!
!  Arguments
!  =========
!
!  TYPE    (input) CHARACTER*1
!          TYPE indices the storage type of the input matrix.
!          = 'G':  A is a full matrix.
!          = 'L':  A is a lower triangular matrix.
!          = 'U':  A is an upper triangular matrix.
!          = 'H':  A is an upper Hessenberg matrix.
!          = 'B':  A is a symmetric band matrix with lower bandwidth KL
!                  and upper bandwidth KU and with the only the lower
!                  half stored.
!          = 'Q':  A is a symmetric band matrix with lower bandwidth KL
!                  and upper bandwidth KU and with the only the upper
!                  half stored.
!          = 'Z':  A is a band matrix with lower bandwidth KL and upper
!                  bandwidth KU.
!
!  KL      (input) INTEGER
!          The lower bandwidth of A.  Referenced only if TYPE = 'B',
!          'Q' or 'Z'.
!
!  KU      (input) INTEGER
!          The upper bandwidth of A.  Referenced only if TYPE = 'B',
!          'Q' or 'Z'.
!
!  CFROM   (input) DOUBLE PRECISION
!  CTO     (input) DOUBLE PRECISION
!          The matrix A is multiplied by CTO/CFROM. A(I,J) is computed
!          without over/underflow if the final result CTO*A(I,J)/CFROM
!          can be represented without over/underflow.  CFROM must be
!          nonzero.
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,M)
!          The matrix to be multiplied by CTO/CFROM.  See TYPE for the
!          storage type.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  INFO    (output) INTEGER
!          0  - successful exit
!          <0 - if INFO = -i, the i-th argument had an illegal value.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D0, ONE = 1.0D0 )
!     ..
!     .. Local Scalars ..
LOGICAL            DONE
INTEGER            I, ITYPE, J, K1, K2, K3, K4
DOUBLE PRECISION   BIGNUM, CFROM1, CFROMC, CTO1, CTOC, MUL, SMLNUM
!     ..
!     .. External Functions ..
LOGICAL            LSAME
DOUBLE PRECISION   DLAMCH
EXTERNAL           LSAME, DLAMCH
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN
!     ..
!     .. External Subroutines ..
EXTERNAL           XERBLA
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
!
IF( LSAME( TYPE, 'G' ) ) THEN
   ITYPE = 0
ELSE IF( LSAME( TYPE, 'L' ) ) THEN
   ITYPE = 1
ELSE IF( LSAME( TYPE, 'U' ) ) THEN
   ITYPE = 2
ELSE IF( LSAME( TYPE, 'H' ) ) THEN
   ITYPE = 3
ELSE IF( LSAME( TYPE, 'B' ) ) THEN
   ITYPE = 4
ELSE IF( LSAME( TYPE, 'Q' ) ) THEN
   ITYPE = 5
ELSE IF( LSAME( TYPE, 'Z' ) ) THEN
   ITYPE = 6
ELSE
   ITYPE = -1
END IF
!
IF( ITYPE.EQ.-1 ) THEN
   INFO = -1
ELSE IF( CFROM.EQ.ZERO ) THEN
   INFO = -4
ELSE IF( M.LT.0 ) THEN
   INFO = -6
ELSE IF( N.LT.0 .OR. ( ITYPE.EQ.4 .AND. N.NE.M ) .OR. &
             ( ITYPE.EQ.5 .AND. N.NE.M ) ) THEN
   INFO = -7
ELSE IF( ITYPE.LE.3 .AND. LDA.LT.MAX( 1, M ) ) THEN
   INFO = -9
ELSE IF( ITYPE.GE.4 ) THEN
   IF( KL.LT.0 .OR. KL.GT.MAX( M-1, 0 ) ) THEN
      INFO = -2
   ELSE IF( KU.LT.0 .OR. KU.GT.MAX( N-1, 0 ) .OR. &
                ( ( ITYPE.EQ.4 .OR. ITYPE.EQ.5 ) .AND. KL.NE.KU ) ) &
                 THEN
      INFO = -3
   ELSE IF( ( ITYPE.EQ.4 .AND. LDA.LT.KL+1 ) .OR. &
                ( ITYPE.EQ.5 .AND. LDA.LT.KU+1 ) .OR. &
                ( ITYPE.EQ.6 .AND. LDA.LT.2*KL+KU+1 ) ) THEN
      INFO = -9
   END IF
END IF
!
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DLASCL', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 .OR. M.EQ.0 ) &
       RETURN
!
!     Get machine parameters
!
SMLNUM = DLAMCH( 'S' )
BIGNUM = ONE / SMLNUM
!
CFROMC = CFROM
CTOC = CTO
!
10 CONTINUE
CFROM1 = CFROMC*SMLNUM
CTO1 = CTOC / BIGNUM
IF( ABS( CFROM1 ).GT.ABS( CTOC ) .AND. CTOC.NE.ZERO ) THEN
   MUL = SMLNUM
   DONE = .FALSE.
   CFROMC = CFROM1
ELSE IF( ABS( CTO1 ).GT.ABS( CFROMC ) ) THEN
   MUL = BIGNUM
   DONE = .FALSE.
   CTOC = CTO1
ELSE
   MUL = CTOC / CFROMC
   DONE = .TRUE.
END IF
!
IF( ITYPE.EQ.0 ) THEN
!
!        Full matrix
!
   DO 30 J = 1, N
      DO 20 I = 1, M
         A( I, J ) = A( I, J )*MUL
20       CONTINUE
30    CONTINUE
!
ELSE IF( ITYPE.EQ.1 ) THEN
!
!        Lower triangular matrix
!
   DO 50 J = 1, N
      DO 40 I = J, M
         A( I, J ) = A( I, J )*MUL
40       CONTINUE
50    CONTINUE
!
ELSE IF( ITYPE.EQ.2 ) THEN
!
!        Upper triangular matrix
!
   DO 70 J = 1, N
      DO 60 I = 1, MIN( J, M )
         A( I, J ) = A( I, J )*MUL
60       CONTINUE
70    CONTINUE
!
ELSE IF( ITYPE.EQ.3 ) THEN
!
!        Upper Hessenberg matrix
!
   DO 90 J = 1, N
      DO 80 I = 1, MIN( J+1, M )
         A( I, J ) = A( I, J )*MUL
80       CONTINUE
90    CONTINUE
!
ELSE IF( ITYPE.EQ.4 ) THEN
!
!        Lower half of a symmetric band matrix
!
   K3 = KL + 1
   K4 = N + 1
   DO 110 J = 1, N
      DO 100 I = 1, MIN( K3, K4-J )
         A( I, J ) = A( I, J )*MUL
100       CONTINUE
110    CONTINUE
!
ELSE IF( ITYPE.EQ.5 ) THEN
!
!        Upper half of a symmetric band matrix
!
   K1 = KU + 2
   K3 = KU + 1
   DO 130 J = 1, N
      DO 120 I = MAX( K1-J, 1 ), K3
         A( I, J ) = A( I, J )*MUL
120       CONTINUE
130    CONTINUE
!
ELSE IF( ITYPE.EQ.6 ) THEN
!
!        Band matrix
!
   K1 = KL + KU + 2
   K2 = KL + 1
   K3 = 2*KL + KU + 1
   K4 = KL + KU + 1 + M
   DO 150 J = 1, N
      DO 140 I = MAX( K1-J, K2 ), MIN( K3, K4-J )
         A( I, J ) = A( I, J )*MUL
140       CONTINUE
150    CONTINUE
!
END IF
!
IF( .NOT.DONE ) &
       GO TO 10
!
RETURN
!
!     End of DLASCL
!
end subroutine dlascl

! ===== End dlascl.f90 =====


! ===== Begin dlaset.f90 =====

SUBROUTINE DLASET( UPLO, M, N, ALPHA, BETA, A, LDA )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
CHARACTER          UPLO
INTEGER            LDA, M, N
DOUBLE PRECISION   ALPHA, BETA
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DLASET initializes an m-by-n matrix A to BETA on the diagonal and
!  ALPHA on the offdiagonals.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          Specifies the part of the matrix A to be set.
!          = 'U':      Upper triangular part is set; the strictly lower
!                      triangular part of A is not changed.
!          = 'L':      Lower triangular part is set; the strictly upper
!                      triangular part of A is not changed.
!          Otherwise:  All of the matrix A is set.
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 0.
!
!  ALPHA   (input) DOUBLE PRECISION
!          The constant to which the offdiagonal elements are to be set.
!
!  BETA    (input) DOUBLE PRECISION
!          The constant to which the diagonal elements are to be set.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On exit, the leading m-by-n submatrix of A is set as follows:
!
!          if UPLO = 'U', A(i,j) = ALPHA, 1<=i<=j-1, 1<=j<=n,
!          if UPLO = 'L', A(i,j) = ALPHA, j+1<=i<=m, 1<=j<=n,
!          otherwise,     A(i,j) = ALPHA, 1<=i<=m, 1<=j<=n, i.ne.j,
!
!          and, for all UPLO, A(i,i) = BETA, 1<=i<=min(m,n).
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
! =====================================================================
!
!     .. Local Scalars ..
INTEGER            I, J
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MIN
!     ..
!     .. Executable Statements ..
!
IF( LSAME( UPLO, 'U' ) ) THEN
!
!        Set the strictly upper triangular or trapezoidal part of the
!        array to ALPHA.
!
   DO 20 J = 2, N
      DO 10 I = 1, MIN( J-1, M )
         A( I, J ) = ALPHA
10       CONTINUE
20    CONTINUE
!
ELSE IF( LSAME( UPLO, 'L' ) ) THEN
!
!        Set the strictly lower triangular or trapezoidal part of the
!        array to ALPHA.
!
   DO 40 J = 1, MIN( M, N )
      DO 30 I = J + 1, M
         A( I, J ) = ALPHA
30       CONTINUE
40    CONTINUE
!
ELSE
!
!        Set the leading m-by-n submatrix to ALPHA.
!
   DO 60 J = 1, N
      DO 50 I = 1, M
         A( I, J ) = ALPHA
50       CONTINUE
60    CONTINUE
END IF
!
!     Set the first min(M,N) diagonal elements to BETA.
!
DO 70 I = 1, MIN( M, N )
   A( I, I ) = BETA
70 CONTINUE
!
RETURN
!
!     End of DLASET
!
end subroutine dlaset

! ===== End dlaset.f90 =====


! ===== Begin dlasr.f90 =====

SUBROUTINE DLASR( SIDE, PIVOT, DIRECT, M, N, C, S, A, LDA )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
CHARACTER          DIRECT, PIVOT, SIDE
INTEGER            LDA, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), C( * ), S( * )
!     ..
!
!  Purpose
!  =======
!
!  DLASR   performs the transformation
!
!     A := P*A,   when SIDE = 'L' or 'l'  (  Left-hand side )
!
!     A := A*P',  when SIDE = 'R' or 'r'  ( Right-hand side )
!
!  where A is an m by n real matrix and P is an orthogonal matrix,
!  consisting of a sequence of plane rotations determined by the
!  parameters PIVOT and DIRECT as follows ( z = m when SIDE = 'L' or 'l'
!  and z = n when SIDE = 'R' or 'r' ):
!
!  When  DIRECT = 'F' or 'f'  ( Forward sequence ) then
!
!     P = P( z - 1 )*...*P( 2 )*P( 1 ),
!
!  and when DIRECT = 'B' or 'b'  ( Backward sequence ) then
!
!     P = P( 1 )*P( 2 )*...*P( z - 1 ),
!
!  where  P( k ) is a plane rotation matrix for the following planes:
!
!     when  PIVOT = 'V' or 'v'  ( Variable pivot ),
!        the plane ( k, k + 1 )
!
!     when  PIVOT = 'T' or 't'  ( Top pivot ),
!        the plane ( 1, k + 1 )
!
!     when  PIVOT = 'B' or 'b'  ( Bottom pivot ),
!        the plane ( k, z )
!
!  c( k ) and s( k )  must contain the  cosine and sine that define the
!  matrix  P( k ).  The two by two plane rotation part of the matrix
!  P( k ), R( k ), is assumed to be of the form
!
!     R( k ) = (  c( k )  s( k ) ).
!              ( -s( k )  c( k ) )
!
!  This version vectorises across rows of the array A when SIDE = 'L'.
!
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          Specifies whether the plane rotation matrix P is applied to
!          A on the left or the right.
!          = 'L':  Left, compute A := P*A
!          = 'R':  Right, compute A:= A*P'
!
!  DIRECT  (input) CHARACTER*1
!          Specifies whether P is a forward or backward sequence of
!          plane rotations.
!          = 'F':  Forward, P = P( z - 1 )*...*P( 2 )*P( 1 )
!          = 'B':  Backward, P = P( 1 )*P( 2 )*...*P( z - 1 )
!
!  PIVOT   (input) CHARACTER*1
!          Specifies the plane for which P(k) is a plane rotation
!          matrix.
!          = 'V':  Variable pivot, the plane (k,k+1)
!          = 'T':  Top pivot, the plane (1,k+1)
!          = 'B':  Bottom pivot, the plane (k,z)
!
!  M       (input) INTEGER
!          The number of rows of the matrix A.  If m <= 1, an immediate
!          return is effected.
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.  If n <= 1, an
!          immediate return is effected.
!
!  C, S    (input) DOUBLE PRECISION arrays, dimension
!                  (M-1) if SIDE = 'L'
!                  (N-1) if SIDE = 'R'
!          c(k) and s(k) contain the cosine and sine that define the
!          matrix P(k).  The two by two plane rotation part of the
!          matrix P(k), R(k), is assumed to be of the form
!          R( k ) = (  c( k )  s( k ) ).
!                   ( -s( k )  c( k ) )
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          The m by n matrix A.  On exit, A is overwritten by P*A if
!          SIDE = 'R' or by A*P' if SIDE = 'L'.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, INFO, J
DOUBLE PRECISION   CTEMP, STEMP, TEMP
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters
!
INFO = 0
IF( .NOT.( LSAME( SIDE, 'L' ) .OR. LSAME( SIDE, 'R' ) ) ) THEN
   INFO = 1
ELSE IF( .NOT.( LSAME( PIVOT, 'V' ) .OR. LSAME( PIVOT, &
             'T' ) .OR. LSAME( PIVOT, 'B' ) ) ) THEN
   INFO = 2
ELSE IF( .NOT.( LSAME( DIRECT, 'F' ) .OR. LSAME( DIRECT, 'B' ) ) ) &
              THEN
   INFO = 3
ELSE IF( M.LT.0 ) THEN
   INFO = 4
ELSE IF( N.LT.0 ) THEN
   INFO = 5
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = 9
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DLASR ', INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( ( M.EQ.0 ) .OR. ( N.EQ.0 ) ) &
       RETURN
IF( LSAME( SIDE, 'L' ) ) THEN
!
!        Form  P * A
!
   IF( LSAME( PIVOT, 'V' ) ) THEN
      IF( LSAME( DIRECT, 'F' ) ) THEN
         DO 20 J = 1, M - 1
            CTEMP = C( J )
            STEMP = S( J )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 10 I = 1, N
                  TEMP = A( J+1, I )
                  A( J+1, I ) = CTEMP*TEMP - STEMP*A( J, I )
                  A( J, I ) = STEMP*TEMP + CTEMP*A( J, I )
10                CONTINUE
            END IF
20          CONTINUE
      ELSE IF( LSAME( DIRECT, 'B' ) ) THEN
         DO 40 J = M - 1, 1, -1
            CTEMP = C( J )
            STEMP = S( J )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 30 I = 1, N
                  TEMP = A( J+1, I )
                  A( J+1, I ) = CTEMP*TEMP - STEMP*A( J, I )
                  A( J, I ) = STEMP*TEMP + CTEMP*A( J, I )
30                CONTINUE
            END IF
40          CONTINUE
      END IF
   ELSE IF( LSAME( PIVOT, 'T' ) ) THEN
      IF( LSAME( DIRECT, 'F' ) ) THEN
         DO 60 J = 2, M
            CTEMP = C( J-1 )
            STEMP = S( J-1 )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 50 I = 1, N
                  TEMP = A( J, I )
                  A( J, I ) = CTEMP*TEMP - STEMP*A( 1, I )
                  A( 1, I ) = STEMP*TEMP + CTEMP*A( 1, I )
50                CONTINUE
            END IF
60          CONTINUE
      ELSE IF( LSAME( DIRECT, 'B' ) ) THEN
         DO 80 J = M, 2, -1
            CTEMP = C( J-1 )
            STEMP = S( J-1 )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 70 I = 1, N
                  TEMP = A( J, I )
                  A( J, I ) = CTEMP*TEMP - STEMP*A( 1, I )
                  A( 1, I ) = STEMP*TEMP + CTEMP*A( 1, I )
70                CONTINUE
            END IF
80          CONTINUE
      END IF
   ELSE IF( LSAME( PIVOT, 'B' ) ) THEN
      IF( LSAME( DIRECT, 'F' ) ) THEN
         DO 100 J = 1, M - 1
            CTEMP = C( J )
            STEMP = S( J )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 90 I = 1, N
                  TEMP = A( J, I )
                  A( J, I ) = STEMP*A( M, I ) + CTEMP*TEMP
                  A( M, I ) = CTEMP*A( M, I ) - STEMP*TEMP
90                CONTINUE
            END IF
100          CONTINUE
      ELSE IF( LSAME( DIRECT, 'B' ) ) THEN
         DO 120 J = M - 1, 1, -1
            CTEMP = C( J )
            STEMP = S( J )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 110 I = 1, N
                  TEMP = A( J, I )
                  A( J, I ) = STEMP*A( M, I ) + CTEMP*TEMP
                  A( M, I ) = CTEMP*A( M, I ) - STEMP*TEMP
110                CONTINUE
            END IF
120          CONTINUE
      END IF
   END IF
ELSE IF( LSAME( SIDE, 'R' ) ) THEN
!
!        Form A * P'
!
   IF( LSAME( PIVOT, 'V' ) ) THEN
      IF( LSAME( DIRECT, 'F' ) ) THEN
         DO 140 J = 1, N - 1
            CTEMP = C( J )
            STEMP = S( J )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 130 I = 1, M
                  TEMP = A( I, J+1 )
                  A( I, J+1 ) = CTEMP*TEMP - STEMP*A( I, J )
                  A( I, J ) = STEMP*TEMP + CTEMP*A( I, J )
130                CONTINUE
            END IF
140          CONTINUE
      ELSE IF( LSAME( DIRECT, 'B' ) ) THEN
         DO 160 J = N - 1, 1, -1
            CTEMP = C( J )
            STEMP = S( J )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 150 I = 1, M
                  TEMP = A( I, J+1 )
                  A( I, J+1 ) = CTEMP*TEMP - STEMP*A( I, J )
                  A( I, J ) = STEMP*TEMP + CTEMP*A( I, J )
150                CONTINUE
            END IF
160          CONTINUE
      END IF
   ELSE IF( LSAME( PIVOT, 'T' ) ) THEN
      IF( LSAME( DIRECT, 'F' ) ) THEN
         DO 180 J = 2, N
            CTEMP = C( J-1 )
            STEMP = S( J-1 )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 170 I = 1, M
                  TEMP = A( I, J )
                  A( I, J ) = CTEMP*TEMP - STEMP*A( I, 1 )
                  A( I, 1 ) = STEMP*TEMP + CTEMP*A( I, 1 )
170                CONTINUE
            END IF
180          CONTINUE
      ELSE IF( LSAME( DIRECT, 'B' ) ) THEN
         DO 200 J = N, 2, -1
            CTEMP = C( J-1 )
            STEMP = S( J-1 )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 190 I = 1, M
                  TEMP = A( I, J )
                  A( I, J ) = CTEMP*TEMP - STEMP*A( I, 1 )
                  A( I, 1 ) = STEMP*TEMP + CTEMP*A( I, 1 )
190                CONTINUE
            END IF
200          CONTINUE
      END IF
   ELSE IF( LSAME( PIVOT, 'B' ) ) THEN
      IF( LSAME( DIRECT, 'F' ) ) THEN
         DO 220 J = 1, N - 1
            CTEMP = C( J )
            STEMP = S( J )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 210 I = 1, M
                  TEMP = A( I, J )
                  A( I, J ) = STEMP*A( I, N ) + CTEMP*TEMP
                  A( I, N ) = CTEMP*A( I, N ) - STEMP*TEMP
210                CONTINUE
            END IF
220          CONTINUE
      ELSE IF( LSAME( DIRECT, 'B' ) ) THEN
         DO 240 J = N - 1, 1, -1
            CTEMP = C( J )
            STEMP = S( J )
            IF( ( CTEMP.NE.ONE ) .OR. ( STEMP.NE.ZERO ) ) THEN
               DO 230 I = 1, M
                  TEMP = A( I, J )
                  A( I, J ) = STEMP*A( I, N ) + CTEMP*TEMP
                  A( I, N ) = CTEMP*A( I, N ) - STEMP*TEMP
230                CONTINUE
            END IF
240          CONTINUE
      END IF
   END IF
END IF
!
RETURN
!
!     End of DLASR
!
end subroutine dlasr

! ===== End dlasr.f90 =====


! ===== Begin dlasrt.f90 =====

SUBROUTINE DLASRT( ID, N, D, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER          ID
INTEGER            INFO, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   D( * )
!     ..
!
!  Purpose
!  =======
!
!  Sort the numbers in D in increasing order (if ID = 'I') or
!  in decreasing order (if ID = 'D' ).
!
!  Use Quick Sort, reverting to Insertion sort on arrays of
!  size <= 20. Dimension of STACK limits N to about 2**32.
!
!  Arguments
!  =========
!
!  ID      (input) CHARACTER*1
!          = 'I': sort D in increasing order;
!          = 'D': sort D in decreasing order.
!
!  N       (input) INTEGER
!          The length of the array D.
!
!  D       (input/output) DOUBLE PRECISION array, dimension (N)
!          On entry, the array to be sorted.
!          On exit, D has been sorted into increasing order
!          (D(1) <= ... <= D(N) ) or into decreasing order
!          (D(1) >= ... >= D(N) ), depending on ID.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
INTEGER            SELECT
PARAMETER          ( SELECT = 20 )
!     ..
!     .. Local Scalars ..
INTEGER            DIR, ENDD, I, J, START, STKPNT
DOUBLE PRECISION   D1, D2, D3, DMNMX, TMP
!     ..
!     .. Local Arrays ..
INTEGER            STACK( 2, 32 )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           XERBLA
!     ..
!     .. Executable Statements ..
!
!     Test the input paramters.
!
INFO = 0
DIR = -1
IF( LSAME( ID, 'D' ) ) THEN
   DIR = 0
ELSE IF( LSAME( ID, 'I' ) ) THEN
   DIR = 1
END IF
IF( DIR.EQ.-1 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DLASRT', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.LE.1 ) &
       RETURN
!
STKPNT = 1
STACK( 1, 1 ) = 1
STACK( 2, 1 ) = N
10 CONTINUE
START = STACK( 1, STKPNT )
ENDD = STACK( 2, STKPNT )
STKPNT = STKPNT - 1
IF( ENDD-START.LE.SELECT .AND. ENDD-START.GT.0 ) THEN
!
!        Do Insertion sort on D( START:ENDD )
!
   IF( DIR.EQ.0 ) THEN
!
!           Sort into decreasing order
!
      DO 30 I = START + 1, ENDD
         DO 20 J = I, START + 1, -1
            IF( D( J ).GT.D( J-1 ) ) THEN
               DMNMX = D( J )
               D( J ) = D( J-1 )
               D( J-1 ) = DMNMX
            ELSE
               GO TO 30
            END IF
20          CONTINUE
30       CONTINUE
!
   ELSE
!
!           Sort into increasing order
!
      DO 50 I = START + 1, ENDD
         DO 40 J = I, START + 1, -1
            IF( D( J ).LT.D( J-1 ) ) THEN
               DMNMX = D( J )
               D( J ) = D( J-1 )
               D( J-1 ) = DMNMX
            ELSE
               GO TO 50
            END IF
40          CONTINUE
50       CONTINUE
!
   END IF
!
ELSE IF( ENDD-START.GT.SELECT ) THEN
!
!        Partition D( START:ENDD ) and stack parts, largest one first
!
!        Choose partition entry as median of 3
!
   D1 = D( START )
   D2 = D( ENDD )
   I = ( START+ENDD ) / 2
   D3 = D( I )
   IF( D1.LT.D2 ) THEN
      IF( D3.LT.D1 ) THEN
         DMNMX = D1
      ELSE IF( D3.LT.D2 ) THEN
         DMNMX = D3
      ELSE
         DMNMX = D2
      END IF
   ELSE
      IF( D3.LT.D2 ) THEN
         DMNMX = D2
      ELSE IF( D3.LT.D1 ) THEN
         DMNMX = D3
      ELSE
         DMNMX = D1
      END IF
   END IF
!
   IF( DIR.EQ.0 ) THEN
!
!           Sort into decreasing order
!
      I = START - 1
      J = ENDD + 1
60       CONTINUE
70       CONTINUE
      J = J - 1
      IF( D( J ).LT.DMNMX ) &
             GO TO 70
80       CONTINUE
      I = I + 1
      IF( D( I ).GT.DMNMX ) &
             GO TO 80
      IF( I.LT.J ) THEN
         TMP = D( I )
         D( I ) = D( J )
         D( J ) = TMP
         GO TO 60
      END IF
      IF( J-START.GT.ENDD-J-1 ) THEN
         STKPNT = STKPNT + 1
         STACK( 1, STKPNT ) = START
         STACK( 2, STKPNT ) = J
         STKPNT = STKPNT + 1
         STACK( 1, STKPNT ) = J + 1
         STACK( 2, STKPNT ) = ENDD
      ELSE
         STKPNT = STKPNT + 1
         STACK( 1, STKPNT ) = J + 1
         STACK( 2, STKPNT ) = ENDD
         STKPNT = STKPNT + 1
         STACK( 1, STKPNT ) = START
         STACK( 2, STKPNT ) = J
      END IF
   ELSE
!
!           Sort into increasing order
!
      I = START - 1
      J = ENDD + 1
90       CONTINUE
100       CONTINUE
      J = J - 1
      IF( D( J ).GT.DMNMX ) &
             GO TO 100
110       CONTINUE
      I = I + 1
      IF( D( I ).LT.DMNMX ) &
             GO TO 110
      IF( I.LT.J ) THEN
         TMP = D( I )
         D( I ) = D( J )
         D( J ) = TMP
         GO TO 90
      END IF
      IF( J-START.GT.ENDD-J-1 ) THEN
         STKPNT = STKPNT + 1
         STACK( 1, STKPNT ) = START
         STACK( 2, STKPNT ) = J
         STKPNT = STKPNT + 1
         STACK( 1, STKPNT ) = J + 1
         STACK( 2, STKPNT ) = ENDD
      ELSE
         STKPNT = STKPNT + 1
         STACK( 1, STKPNT ) = J + 1
         STACK( 2, STKPNT ) = ENDD
         STKPNT = STKPNT + 1
         STACK( 1, STKPNT ) = START
         STACK( 2, STKPNT ) = J
      END IF
   END IF
END IF
IF( STKPNT.GT.0 ) &
       GO TO 10
RETURN
!
!     End of DLASRT
!
end subroutine dlasrt

! ===== End dlasrt.f90 =====


! ===== Begin dlassq.f90 =====

SUBROUTINE DLASSQ( N, X, INCX, SCALE, SUMSQ )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            INCX, N
DOUBLE PRECISION   SCALE, SUMSQ
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   X( * )
!     ..
!
!  Purpose
!  =======
!
!  DLASSQ  returns the values  scl  and  smsq  such that
!
!     ( scl**2 )*smsq = x( 1 )**2 +...+ x( n )**2 + ( scale**2 )*sumsq,
!
!  where  x( i ) = X( 1 + ( i - 1 )*INCX ). The value of  sumsq  is
!  assumed to be non-negative and  scl  returns the value
!
!     scl = max( scale, abs( x( i ) ) ).
!
!  scale and sumsq must be supplied in SCALE and SUMSQ and
!  scl and smsq are overwritten on SCALE and SUMSQ respectively.
!
!  The routine makes only one pass through the vector x.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of elements to be used from the vector X.
!
!  X       (input) DOUBLE PRECISION array, dimension (N)
!          The vector for which a scaled sum of squares is computed.
!             x( i )  = X( 1 + ( i - 1 )*INCX ), 1 <= i <= n.
!
!  INCX    (input) INTEGER
!          The increment between successive values of the vector X.
!          INCX > 0.
!
!  SCALE   (input/output) DOUBLE PRECISION
!          On entry, the value  scale  in the equation above.
!          On exit, SCALE is overwritten with  scl , the scaling factor
!          for the sum of squares.
!
!  SUMSQ   (input/output) DOUBLE PRECISION
!          On entry, the value  sumsq  in the equation above.
!          On exit, SUMSQ is overwritten with  smsq , the basic sum of
!          squares from which  scl  has been factored out.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            IX
DOUBLE PRECISION   ABSXI
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS
!     ..
!     .. Executable Statements ..
!
IF( N.GT.0 ) THEN
   DO 10 IX = 1, 1 + ( N-1 )*INCX, INCX
      IF( X( IX ).NE.ZERO ) THEN
         ABSXI = ABS( X( IX ) )
         IF( SCALE.LT.ABSXI ) THEN
            SUMSQ = 1 + SUMSQ*( SCALE / ABSXI )**2
            SCALE = ABSXI
         ELSE
            SUMSQ = SUMSQ + ( ABSXI / SCALE )**2
         END IF
      END IF
10    CONTINUE
END IF
RETURN
!
!     End of DLASSQ
!
end subroutine dlassq

! ===== End dlassq.f90 =====


! ===== Begin dlasv2.f90 =====

SUBROUTINE DLASV2( F, G, H, SSMIN, SSMAX, SNR, CSR, SNL, CSL )
!
!  -- LAPACK auxiliary routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
DOUBLE PRECISION   CSL, CSR, F, G, H, SNL, SNR, SSMAX, SSMIN
!     ..
!
!  Purpose
!  =======
!
!  DLASV2 computes the singular value decomposition of a 2-by-2
!  triangular matrix
!     [  F   G  ]
!     [  0   H  ].
!  On return, abs(SSMAX) is the larger singular value, abs(SSMIN) is the
!  smaller singular value, and (CSL,SNL) and (CSR,SNR) are the left and
!  right singular vectors for abs(SSMAX), giving the decomposition
!
!     [ CSL  SNL ] [  F   G  ] [ CSR -SNR ]  =  [ SSMAX   0   ]
!     [-SNL  CSL ] [  0   H  ] [ SNR  CSR ]     [  0    SSMIN ].
!
!  Arguments
!  =========
!
!  F       (input) DOUBLE PRECISION
!          The (1,1) element of the 2-by-2 matrix.
!
!  G       (input) DOUBLE PRECISION
!          The (1,2) element of the 2-by-2 matrix.
!
!  H       (input) DOUBLE PRECISION
!          The (2,2) element of the 2-by-2 matrix.
!
!  SSMIN   (output) DOUBLE PRECISION
!          abs(SSMIN) is the smaller singular value.
!
!  SSMAX   (output) DOUBLE PRECISION
!          abs(SSMAX) is the larger singular value.
!
!  SNL     (output) DOUBLE PRECISION
!  CSL     (output) DOUBLE PRECISION
!          The vector (CSL, SNL) is a unit left singular vector for the
!          singular value abs(SSMAX).
!
!  SNR     (output) DOUBLE PRECISION
!  CSR     (output) DOUBLE PRECISION
!          The vector (CSR, SNR) is a unit right singular vector for the
!          singular value abs(SSMAX).
!
!  Further Details
!  ===============
!
!  Any input parameter may be aliased with any output parameter.
!
!  Barring over/underflow and assuming a guard digit in subtraction, all
!  output quantities are correct to within a few units in the last
!  place (ulps).
!
!  In IEEE arithmetic, the code works correctly if one matrix element is
!  infinite.
!
!  Overflow will not occur unless the largest singular value itself
!  overflows or is within a few ulps of overflow. (On machines with
!  partial overflow, like the Cray, overflow may occur if the largest
!  singular value is within a factor of 2 of overflow.)
!
!  Underflow is harmless if underflow is gradual. Otherwise, results
!  may correspond to a matrix modified by perturbations of size near
!  the underflow threshold.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D0 )
DOUBLE PRECISION   HALF
PARAMETER          ( HALF = 0.5D0 )
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D0 )
DOUBLE PRECISION   TWO
PARAMETER          ( TWO = 2.0D0 )
DOUBLE PRECISION   FOUR
PARAMETER          ( FOUR = 4.0D0 )
!     ..
!     .. Local Scalars ..
LOGICAL            GASMAL, SWAP
INTEGER            PMAX
DOUBLE PRECISION   A, CLT, CRT, D, FA, FT, GA, GT, HA, HT, L, M, &
                       MM, R, S, SLT, SRT, T, TEMP, TSIGN, TT
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, SIGN, SQRT
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMCH
EXTERNAL           DLAMCH
!     ..
!     .. Executable Statements ..
!
FT = F
FA = ABS( FT )
HT = H
HA = ABS( H )
!
!     PMAX points to the maximum absolute element of matrix
!       PMAX = 1 if F largest in absolute values
!       PMAX = 2 if G largest in absolute values
!       PMAX = 3 if H largest in absolute values
!
PMAX = 1
SWAP = ( HA.GT.FA )
IF( SWAP ) THEN
   PMAX = 3
   TEMP = FT
   FT = HT
   HT = TEMP
   TEMP = FA
   FA = HA
   HA = TEMP
!
!        Now FA .ge. HA
!
END IF
GT = G
GA = ABS( GT )
IF( GA.EQ.ZERO ) THEN
!
!        Diagonal matrix
!
   SSMIN = HA
   SSMAX = FA
   CLT = ONE
   CRT = ONE
   SLT = ZERO
   SRT = ZERO
ELSE
   GASMAL = .TRUE.
   IF( GA.GT.FA ) THEN
      PMAX = 2
      IF( ( FA / GA ).LT.DLAMCH( 'EPS' ) ) THEN
!
!              Case of very large GA
!
         GASMAL = .FALSE.
         SSMAX = GA
         IF( HA.GT.ONE ) THEN
            SSMIN = FA / ( GA / HA )
         ELSE
            SSMIN = ( FA / GA )*HA
         END IF
         CLT = ONE
         SLT = HT / GT
         SRT = ONE
         CRT = FT / GT
      END IF
   END IF
   IF( GASMAL ) THEN
!
!           Normal case
!
      D = FA - HA
      IF( D.EQ.FA ) THEN
!
!              Copes with infinite F or H
!
         L = ONE
      ELSE
         L = D / FA
      END IF
!
!           Note that 0 .le. L .le. 1
!
      M = GT / FT
!
!           Note that abs(M) .le. 1/macheps
!
      T = TWO - L
!
!           Note that T .ge. 1
!
      MM = M*M
      TT = T*T
      S = SQRT( TT+MM )
!
!           Note that 1 .le. S .le. 1 + 1/macheps
!
      IF( L.EQ.ZERO ) THEN
         R = ABS( M )
      ELSE
         R = SQRT( L*L+MM )
      END IF
!
!           Note that 0 .le. R .le. 1 + 1/macheps
!
      A = HALF*( S+R )
!
!           Note that 1 .le. A .le. 1 + abs(M)
!
      SSMIN = HA / A
      SSMAX = FA*A
      IF( MM.EQ.ZERO ) THEN
!
!              Note that M is very tiny
!
         IF( L.EQ.ZERO ) THEN
            T = SIGN( TWO, FT )*SIGN( ONE, GT )
         ELSE
            T = GT / SIGN( D, FT ) + M / T
         END IF
      ELSE
         T = ( M / ( S+T )+M / ( R+L ) )*( ONE+A )
      END IF
      L = SQRT( T*T+FOUR )
      CRT = TWO / L
      SRT = T / L
      CLT = ( CRT+SRT*M ) / A
      SLT = ( HT / FT )*SRT / A
   END IF
END IF
IF( SWAP ) THEN
   CSL = SRT
   SNL = CRT
   CSR = SLT
   SNR = CLT
ELSE
   CSL = CLT
   SNL = SLT
   CSR = CRT
   SNR = SRT
END IF
!
!     Correct signs of SSMAX and SSMIN
!
IF( PMAX.EQ.1 ) &
       TSIGN = SIGN( ONE, CSR )*SIGN( ONE, CSL )*SIGN( ONE, F )
IF( PMAX.EQ.2 ) &
       TSIGN = SIGN( ONE, SNR )*SIGN( ONE, CSL )*SIGN( ONE, G )
IF( PMAX.EQ.3 ) &
       TSIGN = SIGN( ONE, SNR )*SIGN( ONE, SNL )*SIGN( ONE, H )
SSMAX = SIGN( SSMAX, TSIGN )
SSMIN = SIGN( SSMIN, TSIGN*SIGN( ONE, F )*SIGN( ONE, H ) )
RETURN
!
!     End of DLASV2
!
end subroutine dlasv2

! ===== End dlasv2.f90 =====


! ===== Begin dlaswp.f90 =====

SUBROUTINE DLASWP( N, A, LDA, K1, K2, IPIV, INCX )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
INTEGER            INCX, K1, K2, LDA, N
!     ..
!     .. Array Arguments ..
INTEGER            IPIV( * )
DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DLASWP performs a series of row interchanges on the matrix A.
!  One row interchange is initiated for each of rows K1 through K2 of A.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of columns of the matrix A.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the matrix of column dimension N to which the row
!          interchanges will be applied.
!          On exit, the permuted matrix.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.
!
!  K1      (input) INTEGER
!          The first element of IPIV for which a row interchange will
!          be done.
!
!  K2      (input) INTEGER
!          The last element of IPIV for which a row interchange will
!          be done.
!
!  IPIV    (input) INTEGER array, dimension (M*abs(INCX))
!          The vector of pivot indices.  Only the elements in positions
!          K1 through K2 of IPIV are accessed.
!          IPIV(K) = L implies rows K and L are to be interchanged.
!
!  INCX    (input) INTEGER
!          The increment between successive values of IPIV.  If IPIV
!          is negative, the pivots are applied in reverse order.
!
! =====================================================================
!
!     .. Local Scalars ..
INTEGER            I, IP, IX
!     ..
!     .. External Subroutines ..
EXTERNAL           DSWAP
!     ..
!     .. Executable Statements ..
!
!     Interchange row I with row IPIV(I) for each of rows K1 through K2.
!
IF( INCX.EQ.0 ) &
       RETURN
IF( INCX.GT.0 ) THEN
   IX = K1
ELSE
   IX = 1 + ( 1-K2 )*INCX
END IF
IF( INCX.EQ.1 ) THEN
   DO 10 I = K1, K2
      IP = IPIV( I )
      IF( IP.NE.I ) &
             CALL DSWAP( N, A( I, 1 ), LDA, A( IP, 1 ), LDA )
10    CONTINUE
ELSE IF( INCX.GT.1 ) THEN
   DO 20 I = K1, K2
      IP = IPIV( IX )
      IF( IP.NE.I ) &
             CALL DSWAP( N, A( I, 1 ), LDA, A( IP, 1 ), LDA )
      IX = IX + INCX
20    CONTINUE
ELSE IF( INCX.LT.0 ) THEN
   DO 30 I = K2, K1, -1
      IP = IPIV( IX )
      IF( IP.NE.I ) &
             CALL DSWAP( N, A( I, 1 ), LDA, A( IP, 1 ), LDA )
      IX = IX + INCX
30    CONTINUE
END IF
!
RETURN
!
!     End of DLASWP
!
end subroutine dlaswp

! ===== End dlaswp.f90 =====


! ===== Begin dlasy2.f90 =====

SUBROUTINE DLASY2( LTRANL, LTRANR, ISGN, N1, N2, TL, LDTL, TR, &
                       LDTR, B, LDB, SCALE, X, LDX, XNORM, INFO )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
LOGICAL            LTRANL, LTRANR
INTEGER            INFO, ISGN, LDB, LDTL, LDTR, LDX, N1, N2
DOUBLE PRECISION   SCALE, XNORM
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   B( LDB, * ), TL( LDTL, * ), TR( LDTR, * ), &
                       X( LDX, * )
!     ..
!
!  Purpose
!  =======
!
!  DLASY2 solves for the N1 by N2 matrix X, 1 <= N1,N2 <= 2, in
!
!         op(TL)*X + ISGN*X*op(TR) = SCALE*B,
!
!  where TL is N1 by N1, TR is N2 by N2, B is N1 by N2, and ISGN = 1 or
!  -1.  op(T) = T or T', where T' denotes the transpose of T.
!
!  Arguments
!  =========
!
!  LTRANL  (input) LOGICAL
!          On entry, LTRANL specifies the op(TL):
!             = .FALSE., op(TL) = TL,
!             = .TRUE., op(TL) = TL'.
!
!  LTRANR  (input) LOGICAL
!          On entry, LTRANR specifies the op(TR):
!            = .FALSE., op(TR) = TR,
!            = .TRUE., op(TR) = TR'.
!
!  ISGN    (input) INTEGER
!          On entry, ISGN specifies the sign of the equation
!          as described before. ISGN may only be 1 or -1.
!
!  N1      (input) INTEGER
!          On entry, N1 specifies the order of matrix TL.
!          N1 may only be 0, 1 or 2.
!
!  N2      (input) INTEGER
!          On entry, N2 specifies the order of matrix TR.
!          N2 may only be 0, 1 or 2.
!
!  TL      (input) DOUBLE PRECISION array, dimension (LDTL,2)
!          On entry, TL contains an N1 by N1 matrix.
!
!  LDTL    (input) INTEGER
!          The leading dimension of the matrix TL. LDTL >= max(1,N1).
!
!  TR      (input) DOUBLE PRECISION array, dimension (LDTR,2)
!          On entry, TR contains an N2 by N2 matrix.
!
!  LDTR    (input) INTEGER
!          The leading dimension of the matrix TR. LDTR >= max(1,N2).
!
!  B       (input) DOUBLE PRECISION array, dimension (LDB,2)
!          On entry, the N1 by N2 matrix B contains the right-hand
!          side of the equation.
!
!  LDB     (input) INTEGER
!          The leading dimension of the matrix B. LDB >= max(1,N1).
!
!  SCALE   (output) DOUBLE PRECISION
!          On exit, SCALE contains the scale factor. SCALE is chosen
!          less than or equal to 1 to prevent the solution overflowing.
!
!  X       (output) DOUBLE PRECISION array, dimension (LDX,2)
!          On exit, X contains the N1 by N2 solution.
!
!  LDX     (input) INTEGER
!          The leading dimension of the matrix X. LDX >= max(1,N1).
!
!  XNORM   (output) DOUBLE PRECISION
!          On exit, XNORM is the infinity-norm of the solution.
!
!  INFO    (output) INTEGER
!          On exit, INFO is set to
!             0: successful exit.
!             1: TL and TR have too close eigenvalues, so TL or
!                TR is perturbed to get a nonsingular equation.
!          NOTE: In the interests of speed, this routine does not
!                check the inputs for errors.
!
! =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
DOUBLE PRECISION   TWO, HALF, EIGHT
PARAMETER          ( TWO = 2.0D+0, HALF = 0.5D+0, EIGHT = 8.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            BSWAP, XSWAP
INTEGER            I, IP, IPIV, IPSV, J, JP, JPSV, K
DOUBLE PRECISION   BET, EPS, GAM, L21, SGN, SMIN, SMLNUM, TAU1, &
                       TEMP, U11, U12, U22, XMAX
!     ..
!     .. Local Arrays ..
LOGICAL            BSWPIV( 4 ), XSWPIV( 4 )
INTEGER            JPIV( 4 ), LOCL21( 4 ), LOCU12( 4 ), &
                       LOCU22( 4 )
DOUBLE PRECISION   BTMP( 4 ), T16( 4, 4 ), TMP( 4 ), X2( 2 )
!     ..
!     .. External Functions ..
INTEGER            IDAMAX
DOUBLE PRECISION   DLAMCH
EXTERNAL           IDAMAX, DLAMCH
!     ..
!     .. External Subroutines ..
EXTERNAL           DCOPY, DSWAP
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX
!     ..
!     .. Data statements ..
DATA               LOCU12 / 3, 4, 1, 2 / , LOCL21 / 2, 1, 4, 3 / , &
                       LOCU22 / 4, 3, 2, 1 /
DATA               XSWPIV / .FALSE., .FALSE., .TRUE., .TRUE. /
DATA               BSWPIV / .FALSE., .TRUE., .FALSE., .TRUE. /
!     ..
!     .. Executable Statements ..
!
!     Do not check the input parameters for errors
!
INFO = 0
!
!     Quick return if possible
!
IF( N1.EQ.0 .OR. N2.EQ.0 ) &
       RETURN
!
!     Set constants to control overflow
!
EPS = DLAMCH( 'P' )
SMLNUM = DLAMCH( 'S' ) / EPS
SGN = ISGN
!
K = N1 + N1 + N2 - 2
GO TO ( 10, 20, 30, 50 )K
!
!     1 by 1: TL11*X + SGN*X*TR11 = B11
!
10 CONTINUE
TAU1 = TL( 1, 1 ) + SGN*TR( 1, 1 )
BET = ABS( TAU1 )
IF( BET.LE.SMLNUM ) THEN
   TAU1 = SMLNUM
   BET = SMLNUM
   INFO = 1
END IF
!
SCALE = ONE
GAM = ABS( B( 1, 1 ) )
IF( SMLNUM*GAM.GT.BET ) &
       SCALE = ONE / GAM
!
X( 1, 1 ) = ( B( 1, 1 )*SCALE ) / TAU1
XNORM = ABS( X( 1, 1 ) )
RETURN
!
!     1 by 2:
!     TL11*[X11 X12] + ISGN*[X11 X12]*op[TR11 TR12]  = [B11 B12]
!                                       [TR21 TR22]
!
20 CONTINUE
!
SMIN = MAX( EPS*MAX( ABS( TL( 1, 1 ) ), ABS( TR( 1, 1 ) ), &
           ABS( TR( 1, 2 ) ), ABS( TR( 2, 1 ) ), ABS( TR( 2, 2 ) ) ), &
           SMLNUM )
TMP( 1 ) = TL( 1, 1 ) + SGN*TR( 1, 1 )
TMP( 4 ) = TL( 1, 1 ) + SGN*TR( 2, 2 )
IF( LTRANR ) THEN
   TMP( 2 ) = SGN*TR( 2, 1 )
   TMP( 3 ) = SGN*TR( 1, 2 )
ELSE
   TMP( 2 ) = SGN*TR( 1, 2 )
   TMP( 3 ) = SGN*TR( 2, 1 )
END IF
BTMP( 1 ) = B( 1, 1 )
BTMP( 2 ) = B( 1, 2 )
GO TO 40
!
!     2 by 1:
!          op[TL11 TL12]*[X11] + ISGN* [X11]*TR11  = [B11]
!            [TL21 TL22] [X21]         [X21]         [B21]
!
30 CONTINUE
SMIN = MAX( EPS*MAX( ABS( TR( 1, 1 ) ), ABS( TL( 1, 1 ) ), &
           ABS( TL( 1, 2 ) ), ABS( TL( 2, 1 ) ), ABS( TL( 2, 2 ) ) ), &
           SMLNUM )
TMP( 1 ) = TL( 1, 1 ) + SGN*TR( 1, 1 )
TMP( 4 ) = TL( 2, 2 ) + SGN*TR( 1, 1 )
IF( LTRANL ) THEN
   TMP( 2 ) = TL( 1, 2 )
   TMP( 3 ) = TL( 2, 1 )
ELSE
   TMP( 2 ) = TL( 2, 1 )
   TMP( 3 ) = TL( 1, 2 )
END IF
BTMP( 1 ) = B( 1, 1 )
BTMP( 2 ) = B( 2, 1 )
40 CONTINUE
!
!     Solve 2 by 2 system using complete pivoting.
!     Set pivots less than SMIN to SMIN.
!
IPIV = IDAMAX( 4, TMP, 1 )
U11 = TMP( IPIV )
IF( ABS( U11 ).LE.SMIN ) THEN
   INFO = 1
   U11 = SMIN
END IF
U12 = TMP( LOCU12( IPIV ) )
L21 = TMP( LOCL21( IPIV ) ) / U11
U22 = TMP( LOCU22( IPIV ) ) - U12*L21
XSWAP = XSWPIV( IPIV )
BSWAP = BSWPIV( IPIV )
IF( ABS( U22 ).LE.SMIN ) THEN
   INFO = 1
   U22 = SMIN
END IF
IF( BSWAP ) THEN
   TEMP = BTMP( 2 )
   BTMP( 2 ) = BTMP( 1 ) - L21*TEMP
   BTMP( 1 ) = TEMP
ELSE
   BTMP( 2 ) = BTMP( 2 ) - L21*BTMP( 1 )
END IF
SCALE = ONE
IF( ( TWO*SMLNUM )*ABS( BTMP( 2 ) ).GT.ABS( U22 ) .OR. &
        ( TWO*SMLNUM )*ABS( BTMP( 1 ) ).GT.ABS( U11 ) ) THEN
   SCALE = HALF / MAX( ABS( BTMP( 1 ) ), ABS( BTMP( 2 ) ) )
   BTMP( 1 ) = BTMP( 1 )*SCALE
   BTMP( 2 ) = BTMP( 2 )*SCALE
END IF
X2( 2 ) = BTMP( 2 ) / U22
X2( 1 ) = BTMP( 1 ) / U11 - ( U12 / U11 )*X2( 2 )
IF( XSWAP ) THEN
   TEMP = X2( 2 )
   X2( 2 ) = X2( 1 )
   X2( 1 ) = TEMP
END IF
X( 1, 1 ) = X2( 1 )
IF( N1.EQ.1 ) THEN
   X( 1, 2 ) = X2( 2 )
   XNORM = ABS( X( 1, 1 ) ) + ABS( X( 1, 2 ) )
ELSE
   X( 2, 1 ) = X2( 2 )
   XNORM = MAX( ABS( X( 1, 1 ) ), ABS( X( 2, 1 ) ) )
END IF
RETURN
!
!     2 by 2:
!     op[TL11 TL12]*[X11 X12] +ISGN* [X11 X12]*op[TR11 TR12] = [B11 B12]
!       [TL21 TL22] [X21 X22]        [X21 X22]   [TR21 TR22]   [B21 B22]
!
!     Solve equivalent 4 by 4 system using complete pivoting.
!     Set pivots less than SMIN to SMIN.
!
50 CONTINUE
SMIN = MAX( ABS( TR( 1, 1 ) ), ABS( TR( 1, 2 ) ), &
           ABS( TR( 2, 1 ) ), ABS( TR( 2, 2 ) ) )
SMIN = MAX( SMIN, ABS( TL( 1, 1 ) ), ABS( TL( 1, 2 ) ), &
           ABS( TL( 2, 1 ) ), ABS( TL( 2, 2 ) ) )
SMIN = MAX( EPS*SMIN, SMLNUM )
BTMP( 1 ) = ZERO
CALL DCOPY( 16, BTMP, 0, T16, 1 )
T16( 1, 1 ) = TL( 1, 1 ) + SGN*TR( 1, 1 )
T16( 2, 2 ) = TL( 2, 2 ) + SGN*TR( 1, 1 )
T16( 3, 3 ) = TL( 1, 1 ) + SGN*TR( 2, 2 )
T16( 4, 4 ) = TL( 2, 2 ) + SGN*TR( 2, 2 )
IF( LTRANL ) THEN
   T16( 1, 2 ) = TL( 2, 1 )
   T16( 2, 1 ) = TL( 1, 2 )
   T16( 3, 4 ) = TL( 2, 1 )
   T16( 4, 3 ) = TL( 1, 2 )
ELSE
   T16( 1, 2 ) = TL( 1, 2 )
   T16( 2, 1 ) = TL( 2, 1 )
   T16( 3, 4 ) = TL( 1, 2 )
   T16( 4, 3 ) = TL( 2, 1 )
END IF
IF( LTRANR ) THEN
   T16( 1, 3 ) = SGN*TR( 1, 2 )
   T16( 2, 4 ) = SGN*TR( 1, 2 )
   T16( 3, 1 ) = SGN*TR( 2, 1 )
   T16( 4, 2 ) = SGN*TR( 2, 1 )
ELSE
   T16( 1, 3 ) = SGN*TR( 2, 1 )
   T16( 2, 4 ) = SGN*TR( 2, 1 )
   T16( 3, 1 ) = SGN*TR( 1, 2 )
   T16( 4, 2 ) = SGN*TR( 1, 2 )
END IF
BTMP( 1 ) = B( 1, 1 )
BTMP( 2 ) = B( 2, 1 )
BTMP( 3 ) = B( 1, 2 )
BTMP( 4 ) = B( 2, 2 )
!
!     Perform elimination
!
DO 100 I = 1, 3
   XMAX = ZERO
   DO 70 IP = I, 4
      DO 60 JP = I, 4
         IF( ABS( T16( IP, JP ) ).GE.XMAX ) THEN
            XMAX = ABS( T16( IP, JP ) )
            IPSV = IP
            JPSV = JP
         END IF
60       CONTINUE
70    CONTINUE
   IF( IPSV.NE.I ) THEN
      CALL DSWAP( 4, T16( IPSV, 1 ), 4, T16( I, 1 ), 4 )
      TEMP = BTMP( I )
      BTMP( I ) = BTMP( IPSV )
      BTMP( IPSV ) = TEMP
   END IF
   IF( JPSV.NE.I ) &
          CALL DSWAP( 4, T16( 1, JPSV ), 1, T16( 1, I ), 1 )
   JPIV( I ) = JPSV
   IF( ABS( T16( I, I ) ).LT.SMIN ) THEN
      INFO = 1
      T16( I, I ) = SMIN
   END IF
   DO 90 J = I + 1, 4
      T16( J, I ) = T16( J, I ) / T16( I, I )
      BTMP( J ) = BTMP( J ) - T16( J, I )*BTMP( I )
      DO 80 K = I + 1, 4
         T16( J, K ) = T16( J, K ) - T16( J, I )*T16( I, K )
80       CONTINUE
90    CONTINUE
100 CONTINUE
IF( ABS( T16( 4, 4 ) ).LT.SMIN ) &
       T16( 4, 4 ) = SMIN
SCALE = ONE
IF( ( EIGHT*SMLNUM )*ABS( BTMP( 1 ) ).GT.ABS( T16( 1, 1 ) ) .OR. &
        ( EIGHT*SMLNUM )*ABS( BTMP( 2 ) ).GT.ABS( T16( 2, 2 ) ) .OR. &
        ( EIGHT*SMLNUM )*ABS( BTMP( 3 ) ).GT.ABS( T16( 3, 3 ) ) .OR. &
        ( EIGHT*SMLNUM )*ABS( BTMP( 4 ) ).GT.ABS( T16( 4, 4 ) ) ) THEN
   SCALE = ( ONE / EIGHT ) / MAX( ABS( BTMP( 1 ) ), &
               ABS( BTMP( 2 ) ), ABS( BTMP( 3 ) ), ABS( BTMP( 4 ) ) )
   BTMP( 1 ) = BTMP( 1 )*SCALE
   BTMP( 2 ) = BTMP( 2 )*SCALE
   BTMP( 3 ) = BTMP( 3 )*SCALE
   BTMP( 4 ) = BTMP( 4 )*SCALE
END IF
DO 120 I = 1, 4
   K = 5 - I
   TEMP = ONE / T16( K, K )
   TMP( K ) = BTMP( K )*TEMP
   DO 110 J = K + 1, 4
      TMP( K ) = TMP( K ) - ( TEMP*T16( K, J ) )*TMP( J )
110    CONTINUE
120 CONTINUE
DO 130 I = 1, 3
   IF( JPIV( 4-I ).NE.4-I ) THEN
      TEMP = TMP( 4-I )
      TMP( 4-I ) = TMP( JPIV( 4-I ) )
      TMP( JPIV( 4-I ) ) = TEMP
   END IF
130 CONTINUE
X( 1, 1 ) = TMP( 1 )
X( 2, 1 ) = TMP( 2 )
X( 1, 2 ) = TMP( 3 )
X( 2, 2 ) = TMP( 4 )
XNORM = MAX( ABS( TMP( 1 ) )+ABS( TMP( 3 ) ), &
            ABS( TMP( 2 ) )+ABS( TMP( 4 ) ) )
RETURN
!
!     End of DLASY2
!
end subroutine dlasy2

! ===== End dlasy2.f90 =====


! ===== Begin dorg2r.f90 =====

SUBROUTINE DORG2R( M, N, K, A, LDA, TAU, WORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            INFO, K, LDA, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DORG2R generates an m by n real matrix Q with orthonormal columns,
!  which is defined as the first n columns of a product of k elementary
!  reflectors of order m
!
!        Q  =  H(1) H(2) . . . H(k)
!
!  as returned by DGEQRF.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix Q. M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix Q. M >= N >= 0.
!
!  K       (input) INTEGER
!          The number of elementary reflectors whose product defines the
!          matrix Q. N >= K >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the i-th column must contain the vector which
!          defines the elementary reflector H(i), for i = 1,2,...,k, as
!          returned by DGEQRF in the first k columns of its array
!          argument A.
!          On exit, the m-by-n matrix Q.
!
!  LDA     (input) INTEGER
!          The first dimension of the array A. LDA >= max(1,M).
!
!  TAU     (input) DOUBLE PRECISION array, dimension (K)
!          TAU(i) must contain the scalar factor of the elementary
!          reflector H(i), as returned by DGEQRF.
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (N)
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument has an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I, J, L
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARF, DSCAL, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 .OR. N.GT.M ) THEN
   INFO = -2
ELSE IF( K.LT.0 .OR. K.GT.N ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -5
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DORG2R', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.LE.0 ) &
       RETURN
!
!     Initialise columns k+1:n to columns of the unit matrix
!
DO 20 J = K + 1, N
   DO 10 L = 1, M
      A( L, J ) = ZERO
10    CONTINUE
   A( J, J ) = ONE
20 CONTINUE
!
DO 40 I = K, 1, -1
!
!        Apply H(i) to A(i:m,i:n) from the left
!
   IF( I.LT.N ) THEN
      A( I, I ) = ONE
      CALL DLARF( 'Left', M-I+1, N-I, A( I, I ), 1, TAU( I ), &
                      A( I, I+1 ), LDA, WORK )
   END IF
   IF( I.LT.M ) &
          CALL DSCAL( M-I, -TAU( I ), A( I+1, I ), 1 )
   A( I, I ) = ONE - TAU( I )
!
!        Set A(1:i-1,i) to zero
!
   DO 30 L = 1, I - 1
      A( L, I ) = ZERO
30    CONTINUE
40 CONTINUE
RETURN
!
!     End of DORG2R
!
end subroutine dorg2r

! ===== End dorg2r.f90 =====


! ===== Begin dorghr.f90 =====

SUBROUTINE DORGHR( N, ILO, IHI, A, LDA, TAU, WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            IHI, ILO, INFO, LDA, LWORK, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DORGHR generates a real orthogonal matrix Q which is defined as the
!  product of IHI-ILO elementary reflectors of order N, as returned by
!  DGEHRD:
!
!  Q = H(ilo) H(ilo+1) . . . H(ihi-1).
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix Q. N >= 0.
!
!  ILO     (input) INTEGER
!  IHI     (input) INTEGER
!          ILO and IHI must have the same values as in the previous call
!          of DGEHRD. Q is equal to the unit matrix except in the
!          submatrix Q(ilo+1:ihi,ilo+1:ihi).
!          1 <= ILO <= IHI <= N, if N > 0; ILO=1 and IHI=0, if N=0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the vectors which define the elementary reflectors,
!          as returned by DGEHRD.
!          On exit, the N-by-N orthogonal matrix Q.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A. LDA >= max(1,N).
!
!  TAU     (input) DOUBLE PRECISION array, dimension (N-1)
!          TAU(i) must contain the scalar factor of the elementary
!          reflector H(i), as returned by DGEHRD.
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK. LWORK >= IHI-ILO.
!          For optimum performance LWORK >= (IHI-ILO)*NB, where NB is
!          the optimal blocksize.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LQUERY
INTEGER            I, IINFO, J, LWKOPT, NB, NH
!     ..
!     .. External Subroutines ..
EXTERNAL           DORGQR, XERBLA
!     ..
!     .. External Functions ..
INTEGER            ILAENV
EXTERNAL           ILAENV
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
NH = IHI - ILO
LQUERY = ( LWORK.EQ.-1 )
IF( N.LT.0 ) THEN
   INFO = -1
ELSE IF( ILO.LT.1 .OR. ILO.GT.MAX( 1, N ) ) THEN
   INFO = -2
ELSE IF( IHI.LT.MIN( ILO, N ) .OR. IHI.GT.N ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -5
ELSE IF( LWORK.LT.MAX( 1, NH ) .AND. .NOT.LQUERY ) THEN
   INFO = -8
END IF
!
IF( INFO.EQ.0 ) THEN
   NB = ILAENV( 1, 'DORGQR', ' ', NH, NH, NH, -1 )
   LWKOPT = MAX( 1, NH )*NB
   WORK( 1 ) = LWKOPT
END IF
!
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DORGHR', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) THEN
   WORK( 1 ) = 1
   RETURN
END IF
!
!     Shift the vectors which define the elementary reflectors one
!     column to the right, and set the first ilo and the last n-ihi
!     rows and columns to those of the unit matrix
!
DO 40 J = IHI, ILO + 1, -1
   DO 10 I = 1, J - 1
      A( I, J ) = ZERO
10    CONTINUE
   DO 20 I = J + 1, IHI
      A( I, J ) = A( I, J-1 )
20    CONTINUE
   DO 30 I = IHI + 1, N
      A( I, J ) = ZERO
30    CONTINUE
40 CONTINUE
DO 60 J = 1, ILO
   DO 50 I = 1, N
      A( I, J ) = ZERO
50    CONTINUE
   A( J, J ) = ONE
60 CONTINUE
DO 80 J = IHI + 1, N
   DO 70 I = 1, N
      A( I, J ) = ZERO
70    CONTINUE
   A( J, J ) = ONE
80 CONTINUE
!
IF( NH.GT.0 ) THEN
!
!        Generate Q(ilo+1:ihi,ilo+1:ihi)
!
   CALL DORGQR( NH, NH, NH, A( ILO+1, ILO+1 ), LDA, TAU( ILO ), &
                    WORK, LWORK, IINFO )
END IF
WORK( 1 ) = LWKOPT
RETURN
!
!     End of DORGHR
!
end subroutine dorghr

! ===== End dorghr.f90 =====


! ===== Begin dorgqr.f90 =====

SUBROUTINE DORGQR( M, N, K, A, LDA, TAU, WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            INFO, K, LDA, LWORK, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DORGQR generates an M-by-N real matrix Q with orthonormal columns,
!  which is defined as the first N columns of a product of K elementary
!  reflectors of order M
!
!        Q  =  H(1) H(2) . . . H(k)
!
!  as returned by DGEQRF.
!
!  Arguments
!  =========
!
!  M       (input) INTEGER
!          The number of rows of the matrix Q. M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix Q. M >= N >= 0.
!
!  K       (input) INTEGER
!          The number of elementary reflectors whose product defines the
!          matrix Q. N >= K >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the i-th column must contain the vector which
!          defines the elementary reflector H(i), for i = 1,2,...,k, as
!          returned by DGEQRF in the first k columns of its array
!          argument A.
!          On exit, the M-by-N matrix Q.
!
!  LDA     (input) INTEGER
!          The first dimension of the array A. LDA >= max(1,M).
!
!  TAU     (input) DOUBLE PRECISION array, dimension (K)
!          TAU(i) must contain the scalar factor of the elementary
!          reflector H(i), as returned by DGEQRF.
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK. LWORK >= max(1,N).
!          For optimum performance LWORK >= N*NB, where NB is the
!          optimal blocksize.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument has an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LQUERY
INTEGER            I, IB, IINFO, IWS, J, KI, KK, L, LDWORK, &
                       LWKOPT, NB, NBMIN, NX
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARFB, DLARFT, DORG2R, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. External Functions ..
INTEGER            ILAENV
EXTERNAL           ILAENV
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
NB = ILAENV( 1, 'DORGQR', ' ', M, N, K, -1 )
LWKOPT = MAX( 1, N )*NB
WORK( 1 ) = LWKOPT
LQUERY = ( LWORK.EQ.-1 )
IF( M.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 .OR. N.GT.M ) THEN
   INFO = -2
ELSE IF( K.LT.0 .OR. K.GT.N ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -5
ELSE IF( LWORK.LT.MAX( 1, N ) .AND. .NOT.LQUERY ) THEN
   INFO = -8
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DORGQR', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.LE.0 ) THEN
   WORK( 1 ) = 1
   RETURN
END IF
!
NBMIN = 2
NX = 0
IWS = N
IF( NB.GT.1 .AND. NB.LT.K ) THEN
!
!        Determine when to cross over from blocked to unblocked code.
!
   NX = MAX( 0, ILAENV( 3, 'DORGQR', ' ', M, N, K, -1 ) )
   IF( NX.LT.K ) THEN
!
!           Determine if workspace is large enough for blocked code.
!
      LDWORK = N
      IWS = LDWORK*NB
      IF( LWORK.LT.IWS ) THEN
!
!              Not enough workspace to use optimal NB:  reduce NB and
!              determine the minimum value of NB.
!
         NB = LWORK / LDWORK
         NBMIN = MAX( 2, ILAENV( 2, 'DORGQR', ' ', M, N, K, -1 ) )
      END IF
   END IF
END IF
!
IF( NB.GE.NBMIN .AND. NB.LT.K .AND. NX.LT.K ) THEN
!
!        Use blocked code after the last block.
!        The first kk columns are handled by the block method.
!
   KI = ( ( K-NX-1 ) / NB )*NB
   KK = MIN( K, KI+NB )
!
!        Set A(1:kk,kk+1:n) to zero.
!
   DO 20 J = KK + 1, N
      DO 10 I = 1, KK
         A( I, J ) = ZERO
10       CONTINUE
20    CONTINUE
ELSE
   KK = 0
END IF
!
!     Use unblocked code for the last or only block.
!
IF( KK.LT.N ) &
       CALL DORG2R( M-KK, N-KK, K-KK, A( KK+1, KK+1 ), LDA, &
                    TAU( KK+1 ), WORK, IINFO )
!
IF( KK.GT.0 ) THEN
!
!        Use blocked code
!
   DO 50 I = KI + 1, 1, -NB
      IB = MIN( NB, K-I+1 )
      IF( I+IB.LE.N ) THEN
!
!              Form the triangular factor of the block reflector
!              H = H(i) H(i+1) . . . H(i+ib-1)
!
         CALL DLARFT( 'Forward', 'Columnwise', M-I+1, IB, &
                          A( I, I ), LDA, TAU( I ), WORK, LDWORK )
!
!              Apply H to A(i:m,i+ib:n) from the left
!
         CALL DLARFB( 'Left', 'No transpose', 'Forward', &
                          'Columnwise', M-I+1, N-I-IB+1, IB, &
                          A( I, I ), LDA, WORK, LDWORK, A( I, I+IB ), &
                          LDA, WORK( IB+1 ), LDWORK )
      END IF
!
!           Apply H to rows i:m of current block
!
      CALL DORG2R( M-I+1, IB, IB, A( I, I ), LDA, TAU( I ), WORK, &
                       IINFO )
!
!           Set rows 1:i-1 of current block to zero
!
      DO 40 J = I, I + IB - 1
         DO 30 L = 1, I - 1
            A( L, J ) = ZERO
30          CONTINUE
40       CONTINUE
50    CONTINUE
END IF
!
WORK( 1 ) = IWS
RETURN
!
!     End of DORGQR
!
end subroutine dorgqr

! ===== End dorgqr.f90 =====


! ===== Begin dorm2r.f90 =====

SUBROUTINE DORM2R( SIDE, TRANS, M, N, K, A, LDA, TAU, C, LDC, &
                       WORK, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          SIDE, TRANS
INTEGER            INFO, K, LDA, LDC, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), C( LDC, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DORM2R overwrites the general real m by n matrix C with
!
!        Q * C  if SIDE = 'L' and TRANS = 'N', or
!
!        Q'* C  if SIDE = 'L' and TRANS = 'T', or
!
!        C * Q  if SIDE = 'R' and TRANS = 'N', or
!
!        C * Q' if SIDE = 'R' and TRANS = 'T',
!
!  where Q is a real orthogonal matrix defined as the product of k
!  elementary reflectors
!
!        Q = H(1) H(2) . . . H(k)
!
!  as returned by DGEQRF. Q is of order m if SIDE = 'L' and of order n
!  if SIDE = 'R'.
!
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          = 'L': apply Q or Q' from the Left
!          = 'R': apply Q or Q' from the Right
!
!  TRANS   (input) CHARACTER*1
!          = 'N': apply Q  (No transpose)
!          = 'T': apply Q' (Transpose)
!
!  M       (input) INTEGER
!          The number of rows of the matrix C. M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix C. N >= 0.
!
!  K       (input) INTEGER
!          The number of elementary reflectors whose product defines
!          the matrix Q.
!          If SIDE = 'L', M >= K >= 0;
!          if SIDE = 'R', N >= K >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,K)
!          The i-th column must contain the vector which defines the
!          elementary reflector H(i), for i = 1,2,...,k, as returned by
!          DGEQRF in the first k columns of its array argument A.
!          A is modified by the routine but restored on exit.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.
!          If SIDE = 'L', LDA >= max(1,M);
!          if SIDE = 'R', LDA >= max(1,N).
!
!  TAU     (input) DOUBLE PRECISION array, dimension (K)
!          TAU(i) must contain the scalar factor of the elementary
!          reflector H(i), as returned by DGEQRF.
!
!  C       (input/output) DOUBLE PRECISION array, dimension (LDC,N)
!          On entry, the m by n matrix C.
!          On exit, C is overwritten by Q*C or Q'*C or C*Q' or C*Q.
!
!  LDC     (input) INTEGER
!          The leading dimension of the array C. LDC >= max(1,M).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension
!                                   (N) if SIDE = 'L',
!                                   (M) if SIDE = 'R'
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LEFT, NOTRAN
INTEGER            I, I1, I2, I3, IC, JC, MI, NI, NQ
DOUBLE PRECISION   AII
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARF, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
LEFT = LSAME( SIDE, 'L' )
NOTRAN = LSAME( TRANS, 'N' )
!
!     NQ is the order of Q
!
IF( LEFT ) THEN
   NQ = M
ELSE
   NQ = N
END IF
IF( .NOT.LEFT .AND. .NOT.LSAME( SIDE, 'R' ) ) THEN
   INFO = -1
ELSE IF( .NOT.NOTRAN .AND. .NOT.LSAME( TRANS, 'T' ) ) THEN
   INFO = -2
ELSE IF( M.LT.0 ) THEN
   INFO = -3
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( K.LT.0 .OR. K.GT.NQ ) THEN
   INFO = -5
ELSE IF( LDA.LT.MAX( 1, NQ ) ) THEN
   INFO = -7
ELSE IF( LDC.LT.MAX( 1, M ) ) THEN
   INFO = -10
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DORM2R', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( M.EQ.0 .OR. N.EQ.0 .OR. K.EQ.0 ) &
       RETURN
!
IF( ( LEFT .AND. .NOT.NOTRAN ) .OR. ( .NOT.LEFT .AND. NOTRAN ) ) &
         THEN
   I1 = 1
   I2 = K
   I3 = 1
ELSE
   I1 = K
   I2 = 1
   I3 = -1
END IF
!
IF( LEFT ) THEN
   NI = N
   JC = 1
ELSE
   MI = M
   IC = 1
END IF
!
DO 10 I = I1, I2, I3
   IF( LEFT ) THEN
!
!           H(i) is applied to C(i:m,1:n)
!
      MI = M - I + 1
      IC = I
   ELSE
!
!           H(i) is applied to C(1:m,i:n)
!
      NI = N - I + 1
      JC = I
   END IF
!
!        Apply H(i)
!
   AII = A( I, I )
   A( I, I ) = ONE
   CALL DLARF( SIDE, MI, NI, A( I, I ), 1, TAU( I ), C( IC, JC ), &
                   LDC, WORK )
   A( I, I ) = AII
10 CONTINUE
RETURN
!
!     End of DORM2R
!
end subroutine dorm2r

! ===== End dorm2r.f90 =====


! ===== Begin dorml2.f90 =====

SUBROUTINE DORML2( SIDE, TRANS, M, N, K, A, LDA, TAU, C, LDC, &
                       WORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          SIDE, TRANS
INTEGER            INFO, K, LDA, LDC, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), C( LDC, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DORML2 overwrites the general real m by n matrix C with
!
!        Q * C  if SIDE = 'L' and TRANS = 'N', or
!
!        Q'* C  if SIDE = 'L' and TRANS = 'T', or
!
!        C * Q  if SIDE = 'R' and TRANS = 'N', or
!
!        C * Q' if SIDE = 'R' and TRANS = 'T',
!
!  where Q is a real orthogonal matrix defined as the product of k
!  elementary reflectors
!
!        Q = H(k) . . . H(2) H(1)
!
!  as returned by DGELQF. Q is of order m if SIDE = 'L' and of order n
!  if SIDE = 'R'.
!
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          = 'L': apply Q or Q' from the Left
!          = 'R': apply Q or Q' from the Right
!
!  TRANS   (input) CHARACTER*1
!          = 'N': apply Q  (No transpose)
!          = 'T': apply Q' (Transpose)
!
!  M       (input) INTEGER
!          The number of rows of the matrix C. M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix C. N >= 0.
!
!  K       (input) INTEGER
!          The number of elementary reflectors whose product defines
!          the matrix Q.
!          If SIDE = 'L', M >= K >= 0;
!          if SIDE = 'R', N >= K >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension
!                               (LDA,M) if SIDE = 'L',
!                               (LDA,N) if SIDE = 'R'
!          The i-th row must contain the vector which defines the
!          elementary reflector H(i), for i = 1,2,...,k, as returned by
!          DGELQF in the first k rows of its array argument A.
!          A is modified by the routine but restored on exit.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A. LDA >= max(1,K).
!
!  TAU     (input) DOUBLE PRECISION array, dimension (K)
!          TAU(i) must contain the scalar factor of the elementary
!          reflector H(i), as returned by DGELQF.
!
!  C       (input/output) DOUBLE PRECISION array, dimension (LDC,N)
!          On entry, the m by n matrix C.
!          On exit, C is overwritten by Q*C or Q'*C or C*Q' or C*Q.
!
!  LDC     (input) INTEGER
!          The leading dimension of the array C. LDC >= max(1,M).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension
!                                   (N) if SIDE = 'L',
!                                   (M) if SIDE = 'R'
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            LEFT, NOTRAN
INTEGER            I, I1, I2, I3, IC, JC, MI, NI, NQ
DOUBLE PRECISION   AII
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARF, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
LEFT = LSAME( SIDE, 'L' )
NOTRAN = LSAME( TRANS, 'N' )
!
!     NQ is the order of Q
!
IF( LEFT ) THEN
   NQ = M
ELSE
   NQ = N
END IF
IF( .NOT.LEFT .AND. .NOT.LSAME( SIDE, 'R' ) ) THEN
   INFO = -1
ELSE IF( .NOT.NOTRAN .AND. .NOT.LSAME( TRANS, 'T' ) ) THEN
   INFO = -2
ELSE IF( M.LT.0 ) THEN
   INFO = -3
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( K.LT.0 .OR. K.GT.NQ ) THEN
   INFO = -5
ELSE IF( LDA.LT.MAX( 1, K ) ) THEN
   INFO = -7
ELSE IF( LDC.LT.MAX( 1, M ) ) THEN
   INFO = -10
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DORML2', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( M.EQ.0 .OR. N.EQ.0 .OR. K.EQ.0 ) &
       RETURN
!
IF( ( LEFT .AND. NOTRAN ) .OR. ( .NOT.LEFT .AND. .NOT.NOTRAN ) ) &
         THEN
   I1 = 1
   I2 = K
   I3 = 1
ELSE
   I1 = K
   I2 = 1
   I3 = -1
END IF
!
IF( LEFT ) THEN
   NI = N
   JC = 1
ELSE
   MI = M
   IC = 1
END IF
!
DO 10 I = I1, I2, I3
   IF( LEFT ) THEN
!
!           H(i) is applied to C(i:m,1:n)
!
      MI = M - I + 1
      IC = I
   ELSE
!
!           H(i) is applied to C(1:m,i:n)
!
      NI = N - I + 1
      JC = I
   END IF
!
!        Apply H(i)
!
   AII = A( I, I )
   A( I, I ) = ONE
   CALL DLARF( SIDE, MI, NI, A( I, I ), LDA, TAU( I ), &
                   C( IC, JC ), LDC, WORK )
   A( I, I ) = AII
10 CONTINUE
RETURN
!
!     End of DORML2
!
end subroutine dorml2

! ===== End dorml2.f90 =====


! ===== Begin dormlq.f90 =====

SUBROUTINE DORMLQ( SIDE, TRANS, M, N, K, A, LDA, TAU, C, LDC, &
                       WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
CHARACTER          SIDE, TRANS
INTEGER            INFO, K, LDA, LDC, LWORK, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), C( LDC, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DORMLQ overwrites the general real M-by-N matrix C with
!
!                  SIDE = 'L'     SIDE = 'R'
!  TRANS = 'N':      Q * C          C * Q
!  TRANS = 'T':      Q**T * C       C * Q**T
!
!  where Q is a real orthogonal matrix defined as the product of k
!  elementary reflectors
!
!        Q = H(k) . . . H(2) H(1)
!
!  as returned by DGELQF. Q is of order M if SIDE = 'L' and of order N
!  if SIDE = 'R'.
!
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          = 'L': apply Q or Q**T from the Left;
!          = 'R': apply Q or Q**T from the Right.
!
!  TRANS   (input) CHARACTER*1
!          = 'N':  No transpose, apply Q;
!          = 'T':  Transpose, apply Q**T.
!
!  M       (input) INTEGER
!          The number of rows of the matrix C. M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix C. N >= 0.
!
!  K       (input) INTEGER
!          The number of elementary reflectors whose product defines
!          the matrix Q.
!          If SIDE = 'L', M >= K >= 0;
!          if SIDE = 'R', N >= K >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension
!                               (LDA,M) if SIDE = 'L',
!                               (LDA,N) if SIDE = 'R'
!          The i-th row must contain the vector which defines the
!          elementary reflector H(i), for i = 1,2,...,k, as returned by
!          DGELQF in the first k rows of its array argument A.
!          A is modified by the routine but restored on exit.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A. LDA >= max(1,K).
!
!  TAU     (input) DOUBLE PRECISION array, dimension (K)
!          TAU(i) must contain the scalar factor of the elementary
!          reflector H(i), as returned by DGELQF.
!
!  C       (input/output) DOUBLE PRECISION array, dimension (LDC,N)
!          On entry, the M-by-N matrix C.
!          On exit, C is overwritten by Q*C or Q**T*C or C*Q**T or C*Q.
!
!  LDC     (input) INTEGER
!          The leading dimension of the array C. LDC >= max(1,M).
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.
!          If SIDE = 'L', LWORK >= max(1,N);
!          if SIDE = 'R', LWORK >= max(1,M).
!          For optimum performance LWORK >= N*NB if SIDE = 'L', and
!          LWORK >= M*NB if SIDE = 'R', where NB is the optimal
!          blocksize.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
INTEGER            NBMAX, LDT
PARAMETER          ( NBMAX = 64, LDT = NBMAX+1 )
!     ..
!     .. Local Scalars ..
LOGICAL            LEFT, LQUERY, NOTRAN
CHARACTER          TRANST
INTEGER            I, I1, I2, I3, IB, IC, IINFO, IWS, JC, LDWORK, &
                       LWKOPT, MI, NB, NBMIN, NI, NQ, NW
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   T( LDT, NBMAX )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            ILAENV
EXTERNAL           LSAME, ILAENV
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARFB, DLARFT, DORML2, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
LEFT = LSAME( SIDE, 'L' )
NOTRAN = LSAME( TRANS, 'N' )
LQUERY = ( LWORK.EQ.-1 )
!
!     NQ is the order of Q and NW is the minimum dimension of WORK
!
IF( LEFT ) THEN
   NQ = M
   NW = N
ELSE
   NQ = N
   NW = M
END IF
IF( .NOT.LEFT .AND. .NOT.LSAME( SIDE, 'R' ) ) THEN
   INFO = -1
ELSE IF( .NOT.NOTRAN .AND. .NOT.LSAME( TRANS, 'T' ) ) THEN
   INFO = -2
ELSE IF( M.LT.0 ) THEN
   INFO = -3
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( K.LT.0 .OR. K.GT.NQ ) THEN
   INFO = -5
ELSE IF( LDA.LT.MAX( 1, K ) ) THEN
   INFO = -7
ELSE IF( LDC.LT.MAX( 1, M ) ) THEN
   INFO = -10
ELSE IF( LWORK.LT.MAX( 1, NW ) .AND. .NOT.LQUERY ) THEN
   INFO = -12
END IF
!
IF( INFO.EQ.0 ) THEN
!
!        Determine the block size.  NB may be at most NBMAX, where NBMAX
!        is used to define the local array T.
!
   NB = MIN( NBMAX, ILAENV( 1, 'DORMLQ', SIDE // TRANS, M, N, K, &
            -1 ) )
   LWKOPT = MAX( 1, NW )*NB
   WORK( 1 ) = LWKOPT
END IF
!
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DORMLQ', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
IF( M.EQ.0 .OR. N.EQ.0 .OR. K.EQ.0 ) THEN
   WORK( 1 ) = 1
   RETURN
END IF
!
NBMIN = 2
LDWORK = NW
IF( NB.GT.1 .AND. NB.LT.K ) THEN
   IWS = NW*NB
   IF( LWORK.LT.IWS ) THEN
      NB = LWORK / LDWORK
      NBMIN = MAX( 2, ILAENV( 2, 'DORMLQ', SIDE // TRANS, M, N, K, &
                  -1 ) )
   END IF
ELSE
   IWS = NW
END IF
!
IF( NB.LT.NBMIN .OR. NB.GE.K ) THEN
!
!        Use unblocked code
!
   CALL DORML2( SIDE, TRANS, M, N, K, A, LDA, TAU, C, LDC, WORK, &
                    IINFO )
ELSE
!
!        Use blocked code
!
   IF( ( LEFT .AND. NOTRAN ) .OR. &
           ( .NOT.LEFT .AND. .NOT.NOTRAN ) ) THEN
      I1 = 1
      I2 = K
      I3 = NB
   ELSE
      I1 = ( ( K-1 ) / NB )*NB + 1
      I2 = 1
      I3 = -NB
   END IF
!
   IF( LEFT ) THEN
      NI = N
      JC = 1
   ELSE
      MI = M
      IC = 1
   END IF
!
   IF( NOTRAN ) THEN
      TRANST = 'T'
   ELSE
      TRANST = 'N'
   END IF
!
   DO 10 I = I1, I2, I3
      IB = MIN( NB, K-I+1 )
!
!           Form the triangular factor of the block reflector
!           H = H(i) H(i+1) . . . H(i+ib-1)
!
      CALL DLARFT( 'Forward', 'Rowwise', NQ-I+1, IB, A( I, I ), &
                       LDA, TAU( I ), T, LDT )
      IF( LEFT ) THEN
!
!              H or H' is applied to C(i:m,1:n)
!
         MI = M - I + 1
         IC = I
      ELSE
!
!              H or H' is applied to C(1:m,i:n)
!
         NI = N - I + 1
         JC = I
      END IF
!
!           Apply H or H'
!
      CALL DLARFB( SIDE, TRANST, 'Forward', 'Rowwise', MI, NI, IB, &
                       A( I, I ), LDA, T, LDT, C( IC, JC ), LDC, WORK, &
                       LDWORK )
10    CONTINUE
END IF
WORK( 1 ) = LWKOPT
RETURN
!
!     End of DORMLQ
!
end subroutine dormlq

! ===== End dormlq.f90 =====


! ===== Begin dormqr.f90 =====

SUBROUTINE DORMQR( SIDE, TRANS, M, N, K, A, LDA, TAU, C, LDC, &
                       WORK, LWORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
CHARACTER          SIDE, TRANS
INTEGER            INFO, K, LDA, LDC, LWORK, M, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), C( LDC, * ), TAU( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DORMQR overwrites the general real M-by-N matrix C with
!
!                  SIDE = 'L'     SIDE = 'R'
!  TRANS = 'N':      Q * C          C * Q
!  TRANS = 'T':      Q**T * C       C * Q**T
!
!  where Q is a real orthogonal matrix defined as the product of k
!  elementary reflectors
!
!        Q = H(1) H(2) . . . H(k)
!
!  as returned by DGEQRF. Q is of order M if SIDE = 'L' and of order N
!  if SIDE = 'R'.
!
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          = 'L': apply Q or Q**T from the Left;
!          = 'R': apply Q or Q**T from the Right.
!
!  TRANS   (input) CHARACTER*1
!          = 'N':  No transpose, apply Q;
!          = 'T':  Transpose, apply Q**T.
!
!  M       (input) INTEGER
!          The number of rows of the matrix C. M >= 0.
!
!  N       (input) INTEGER
!          The number of columns of the matrix C. N >= 0.
!
!  K       (input) INTEGER
!          The number of elementary reflectors whose product defines
!          the matrix Q.
!          If SIDE = 'L', M >= K >= 0;
!          if SIDE = 'R', N >= K >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,K)
!          The i-th column must contain the vector which defines the
!          elementary reflector H(i), for i = 1,2,...,k, as returned by
!          DGEQRF in the first k columns of its array argument A.
!          A is modified by the routine but restored on exit.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.
!          If SIDE = 'L', LDA >= max(1,M);
!          if SIDE = 'R', LDA >= max(1,N).
!
!  TAU     (input) DOUBLE PRECISION array, dimension (K)
!          TAU(i) must contain the scalar factor of the elementary
!          reflector H(i), as returned by DGEQRF.
!
!  C       (input/output) DOUBLE PRECISION array, dimension (LDC,N)
!          On entry, the M-by-N matrix C.
!          On exit, C is overwritten by Q*C or Q**T*C or C*Q**T or C*Q.
!
!  LDC     (input) INTEGER
!          The leading dimension of the array C. LDC >= max(1,M).
!
!  WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK)
!          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.
!          If SIDE = 'L', LWORK >= max(1,N);
!          if SIDE = 'R', LWORK >= max(1,M).
!          For optimum performance LWORK >= N*NB if SIDE = 'L', and
!          LWORK >= M*NB if SIDE = 'R', where NB is the optimal
!          blocksize.
!
!          If LWORK = -1, then a workspace query is assumed; the routine
!          only calculates the optimal size of the WORK array, returns
!          this value as the first entry of the WORK array, and no error
!          message related to LWORK is issued by XERBLA.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
INTEGER            NBMAX, LDT
PARAMETER          ( NBMAX = 64, LDT = NBMAX+1 )
!     ..
!     .. Local Scalars ..
LOGICAL            LEFT, LQUERY, NOTRAN
INTEGER            I, I1, I2, I3, IB, IC, IINFO, IWS, JC, LDWORK, &
                       LWKOPT, MI, NB, NBMIN, NI, NQ, NW
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   T( LDT, NBMAX )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            ILAENV
EXTERNAL           LSAME, ILAENV
!     ..
!     .. External Subroutines ..
EXTERNAL           DLARFB, DLARFT, DORM2R, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments
!
INFO = 0
LEFT = LSAME( SIDE, 'L' )
NOTRAN = LSAME( TRANS, 'N' )
LQUERY = ( LWORK.EQ.-1 )
!
!     NQ is the order of Q and NW is the minimum dimension of WORK
!
IF( LEFT ) THEN
   NQ = M
   NW = N
ELSE
   NQ = N
   NW = M
END IF
IF( .NOT.LEFT .AND. .NOT.LSAME( SIDE, 'R' ) ) THEN
   INFO = -1
ELSE IF( .NOT.NOTRAN .AND. .NOT.LSAME( TRANS, 'T' ) ) THEN
   INFO = -2
ELSE IF( M.LT.0 ) THEN
   INFO = -3
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( K.LT.0 .OR. K.GT.NQ ) THEN
   INFO = -5
ELSE IF( LDA.LT.MAX( 1, NQ ) ) THEN
   INFO = -7
ELSE IF( LDC.LT.MAX( 1, M ) ) THEN
   INFO = -10
ELSE IF( LWORK.LT.MAX( 1, NW ) .AND. .NOT.LQUERY ) THEN
   INFO = -12
END IF
!
IF( INFO.EQ.0 ) THEN
!
!        Determine the block size.  NB may be at most NBMAX, where NBMAX
!        is used to define the local array T.
!
   NB = MIN( NBMAX, ILAENV( 1, 'DORMQR', SIDE // TRANS, M, N, K, &
            -1 ) )
   LWKOPT = MAX( 1, NW )*NB
   WORK( 1 ) = LWKOPT
END IF
!
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DORMQR', -INFO )
   RETURN
ELSE IF( LQUERY ) THEN
   RETURN
END IF
!
!     Quick return if possible
!
IF( M.EQ.0 .OR. N.EQ.0 .OR. K.EQ.0 ) THEN
   WORK( 1 ) = 1
   RETURN
END IF
!
NBMIN = 2
LDWORK = NW
IF( NB.GT.1 .AND. NB.LT.K ) THEN
   IWS = NW*NB
   IF( LWORK.LT.IWS ) THEN
      NB = LWORK / LDWORK
      NBMIN = MAX( 2, ILAENV( 2, 'DORMQR', SIDE // TRANS, M, N, K, &
                  -1 ) )
   END IF
ELSE
   IWS = NW
END IF
!
IF( NB.LT.NBMIN .OR. NB.GE.K ) THEN
!
!        Use unblocked code
!
   CALL DORM2R( SIDE, TRANS, M, N, K, A, LDA, TAU, C, LDC, WORK, &
                    IINFO )
ELSE
!
!        Use blocked code
!
   IF( ( LEFT .AND. .NOT.NOTRAN ) .OR. &
           ( .NOT.LEFT .AND. NOTRAN ) ) THEN
      I1 = 1
      I2 = K
      I3 = NB
   ELSE
      I1 = ( ( K-1 ) / NB )*NB + 1
      I2 = 1
      I3 = -NB
   END IF
!
   IF( LEFT ) THEN
      NI = N
      JC = 1
   ELSE
      MI = M
      IC = 1
   END IF
!
   DO 10 I = I1, I2, I3
      IB = MIN( NB, K-I+1 )
!
!           Form the triangular factor of the block reflector
!           H = H(i) H(i+1) . . . H(i+ib-1)
!
      CALL DLARFT( 'Forward', 'Columnwise', NQ-I+1, IB, A( I, I ), &
                       LDA, TAU( I ), T, LDT )
      IF( LEFT ) THEN
!
!              H or H' is applied to C(i:m,1:n)
!
         MI = M - I + 1
         IC = I
      ELSE
!
!              H or H' is applied to C(1:m,i:n)
!
         NI = N - I + 1
         JC = I
      END IF
!
!           Apply H or H'
!
      CALL DLARFB( SIDE, TRANS, 'Forward', 'Columnwise', MI, NI, &
                       IB, A( I, I ), LDA, T, LDT, C( IC, JC ), LDC, &
                       WORK, LDWORK )
10    CONTINUE
END IF
WORK( 1 ) = LWKOPT
RETURN
!
!     End of DORMQR
!
end subroutine dormqr

! ===== End dormqr.f90 =====


! ===== Begin dpbsv.f90 =====

SUBROUTINE DPBSV( UPLO, N, KD, NRHS, AB, LDAB, B, LDB, INFO )
!
!  -- LAPACK driver routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
CHARACTER          UPLO
INTEGER            INFO, KD, LDAB, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   AB( LDAB, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DPBSV computes the solution to a real system of linear equations
!     A * X = B,
!  where A is an N-by-N symmetric positive definite band matrix and X
!  and B are N-by-NRHS matrices.
!
!  The Cholesky decomposition is used to factor A as
!     A = U**T * U,  if UPLO = 'U', or
!     A = L * L**T,  if UPLO = 'L',
!  where U is an upper triangular band matrix, and L is a lower
!  triangular band matrix, with the same number of superdiagonals or
!  subdiagonals as A.  The factored form of A is then used to solve the
!  system of equations A * X = B.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  Upper triangle of A is stored;
!          = 'L':  Lower triangle of A is stored.
!
!  N       (input) INTEGER
!          The number of linear equations, i.e., the order of the
!          matrix A.  N >= 0.
!
!  KD      (input) INTEGER
!          The number of superdiagonals of the matrix A if UPLO = 'U',
!          or the number of subdiagonals if UPLO = 'L'.  KD >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  AB      (input/output) DOUBLE PRECISION array, dimension (LDAB,N)
!          On entry, the upper or lower triangle of the symmetric band
!          matrix A, stored in the first KD+1 rows of the array.  The
!          j-th column of A is stored in the j-th column of the array AB
!          as follows:
!          if UPLO = 'U', AB(KD+1+i-j,j) = A(i,j) for max(1,j-KD)<=i<=j;
!          if UPLO = 'L', AB(1+i-j,j)    = A(i,j) for j<=i<=min(N,j+KD).
!          See below for further details.
!
!          On exit, if INFO = 0, the triangular factor U or L from the
!          Cholesky factorization A = U**T*U or A = L*L**T of the band
!          matrix A, in the same storage format as A.
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= KD+1.
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the N-by-NRHS right hand side matrix B.
!          On exit, if INFO = 0, the N-by-NRHS solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, the leading minor of order i of A is not
!                positive definite, so the factorization could not be
!                completed, and the solution has not been computed.
!
!  Further Details
!  ===============
!
!  The band storage scheme is illustrated by the following example, when
!  N = 6, KD = 2, and UPLO = 'U':
!
!  On entry:                       On exit:
!
!      *    *   a13  a24  a35  a46      *    *   u13  u24  u35  u46
!      *   a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
!     a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
!
!  Similarly, if UPLO = 'L' the format of A is as follows:
!
!  On entry:                       On exit:
!
!     a11  a22  a33  a44  a55  a66     l11  l22  l33  l44  l55  l66
!     a21  a32  a43  a54  a65   *      l21  l32  l43  l54  l65   *
!     a31  a42  a53  a64   *    *      l31  l42  l53  l64   *    *
!
!  Array elements marked * are not used by the routine.
!
!  =====================================================================
!
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DPBTRF, DPBTRS, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
IF( .NOT.LSAME( UPLO, 'U' ) .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( KD.LT.0 ) THEN
   INFO = -3
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -4
ELSE IF( LDAB.LT.KD+1 ) THEN
   INFO = -6
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -8
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DPBSV ', -INFO )
   RETURN
END IF
!
!     Compute the Cholesky factorization A = U'*U or A = L*L'.
!
CALL DPBTRF( UPLO, N, KD, AB, LDAB, INFO )
IF( INFO.EQ.0 ) THEN
!
!        Solve the system A*X = B, overwriting B with X.
!
   CALL DPBTRS( UPLO, N, KD, NRHS, AB, LDAB, B, LDB, INFO )
!
END IF
RETURN
!
!     End of DPBSV
!
end subroutine dpbsv

! ===== End dpbsv.f90 =====


! ===== Begin dpbtf2.f90 =====

SUBROUTINE DPBTF2( UPLO, N, KD, AB, LDAB, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          UPLO
INTEGER            INFO, KD, LDAB, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   AB( LDAB, * )
!     ..
!
!  Purpose
!  =======
!
!  DPBTF2 computes the Cholesky factorization of a real symmetric
!  positive definite band matrix A.
!
!  The factorization has the form
!     A = U' * U ,  if UPLO = 'U', or
!     A = L  * L',  if UPLO = 'L',
!  where U is an upper triangular matrix, U' is the transpose of U, and
!  L is lower triangular.
!
!  This is the unblocked version of the algorithm, calling Level 2 BLAS.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          Specifies whether the upper or lower triangular part of the
!          symmetric matrix A is stored:
!          = 'U':  Upper triangular
!          = 'L':  Lower triangular
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  KD      (input) INTEGER
!          The number of super-diagonals of the matrix A if UPLO = 'U',
!          or the number of sub-diagonals if UPLO = 'L'.  KD >= 0.
!
!  AB      (input/output) DOUBLE PRECISION array, dimension (LDAB,N)
!          On entry, the upper or lower triangle of the symmetric band
!          matrix A, stored in the first KD+1 rows of the array.  The
!          j-th column of A is stored in the j-th column of the array AB
!          as follows:
!          if UPLO = 'U', AB(kd+1+i-j,j) = A(i,j) for max(1,j-kd)<=i<=j;
!          if UPLO = 'L', AB(1+i-j,j)    = A(i,j) for j<=i<=min(n,j+kd).
!
!          On exit, if INFO = 0, the triangular factor U or L from the
!          Cholesky factorization A = U'*U or A = L*L' of the band
!          matrix A, in the same storage format as A.
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= KD+1.
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -k, the k-th argument had an illegal value
!          > 0: if INFO = k, the leading minor of order k is not
!               positive definite, and the factorization could not be
!               completed.
!
!  Further Details
!  ===============
!
!  The band storage scheme is illustrated by the following example, when
!  N = 6, KD = 2, and UPLO = 'U':
!
!  On entry:                       On exit:
!
!      *    *   a13  a24  a35  a46      *    *   u13  u24  u35  u46
!      *   a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
!     a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
!
!  Similarly, if UPLO = 'L' the format of A is as follows:
!
!  On entry:                       On exit:
!
!     a11  a22  a33  a44  a55  a66     l11  l22  l33  l44  l55  l66
!     a21  a32  a43  a54  a65   *      l21  l32  l43  l54  l65   *
!     a31  a42  a53  a64   *    *      l31  l42  l53  l64   *    *
!
!  Array elements marked * are not used by the routine.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            UPPER
INTEGER            J, KLD, KN
DOUBLE PRECISION   AJJ
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DSCAL, DSYR, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN, SQRT
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
UPPER = LSAME( UPLO, 'U' )
IF( .NOT.UPPER .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( KD.LT.0 ) THEN
   INFO = -3
ELSE IF( LDAB.LT.KD+1 ) THEN
   INFO = -5
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DPBTF2', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
KLD = MAX( 1, LDAB-1 )
!
IF( UPPER ) THEN
!
!        Compute the Cholesky factorization A = U'*U.
!
   DO 10 J = 1, N
!
!           Compute U(J,J) and test for non-positive-definiteness.
!
      AJJ = AB( KD+1, J )
      IF( AJJ.LE.ZERO ) &
             GO TO 30
      AJJ = SQRT( AJJ )
      AB( KD+1, J ) = AJJ
!
!           Compute elements J+1:J+KN of row J and update the
!           trailing submatrix within the band.
!
      KN = MIN( KD, N-J )
      IF( KN.GT.0 ) THEN
         CALL DSCAL( KN, ONE / AJJ, AB( KD, J+1 ), KLD )
         CALL DSYR( 'Upper', KN, -ONE, AB( KD, J+1 ), KLD, &
                        AB( KD+1, J+1 ), KLD )
      END IF
10    CONTINUE
ELSE
!
!        Compute the Cholesky factorization A = L*L'.
!
   DO 20 J = 1, N
!
!           Compute L(J,J) and test for non-positive-definiteness.
!
      AJJ = AB( 1, J )
      IF( AJJ.LE.ZERO ) &
             GO TO 30
      AJJ = SQRT( AJJ )
      AB( 1, J ) = AJJ
!
!           Compute elements J+1:J+KN of column J and update the
!           trailing submatrix within the band.
!
      KN = MIN( KD, N-J )
      IF( KN.GT.0 ) THEN
         CALL DSCAL( KN, ONE / AJJ, AB( 2, J ), 1 )
         CALL DSYR( 'Lower', KN, -ONE, AB( 2, J ), 1, &
                        AB( 1, J+1 ), KLD )
      END IF
20    CONTINUE
END IF
RETURN
!
30 CONTINUE
INFO = J
RETURN
!
!     End of DPBTF2
!
end subroutine dpbtf2

! ===== End dpbtf2.f90 =====


! ===== Begin dpbtrf.f90 =====

SUBROUTINE DPBTRF( UPLO, N, KD, AB, LDAB, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
CHARACTER          UPLO
INTEGER            INFO, KD, LDAB, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   AB( LDAB, * )
!     ..
!
!  Purpose
!  =======
!
!  DPBTRF computes the Cholesky factorization of a real symmetric
!  positive definite band matrix A.
!
!  The factorization has the form
!     A = U**T * U,  if UPLO = 'U', or
!     A = L  * L**T,  if UPLO = 'L',
!  where U is an upper triangular matrix and L is lower triangular.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  Upper triangle of A is stored;
!          = 'L':  Lower triangle of A is stored.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  KD      (input) INTEGER
!          The number of superdiagonals of the matrix A if UPLO = 'U',
!          or the number of subdiagonals if UPLO = 'L'.  KD >= 0.
!
!  AB      (input/output) DOUBLE PRECISION array, dimension (LDAB,N)
!          On entry, the upper or lower triangle of the symmetric band
!          matrix A, stored in the first KD+1 rows of the array.  The
!          j-th column of A is stored in the j-th column of the array AB
!          as follows:
!          if UPLO = 'U', AB(kd+1+i-j,j) = A(i,j) for max(1,j-kd)<=i<=j;
!          if UPLO = 'L', AB(1+i-j,j)    = A(i,j) for j<=i<=min(n,j+kd).
!
!          On exit, if INFO = 0, the triangular factor U or L from the
!          Cholesky factorization A = U**T*U or A = L*L**T of the band
!          matrix A, in the same storage format as A.
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= KD+1.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, the leading minor of order i is not
!                positive definite, and the factorization could not be
!                completed.
!
!  Further Details
!  ===============
!
!  The band storage scheme is illustrated by the following example, when
!  N = 6, KD = 2, and UPLO = 'U':
!
!  On entry:                       On exit:
!
!      *    *   a13  a24  a35  a46      *    *   u13  u24  u35  u46
!      *   a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
!     a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
!
!  Similarly, if UPLO = 'L' the format of A is as follows:
!
!  On entry:                       On exit:
!
!     a11  a22  a33  a44  a55  a66     l11  l22  l33  l44  l55  l66
!     a21  a32  a43  a54  a65   *      l21  l32  l43  l54  l65   *
!     a31  a42  a53  a64   *    *      l31  l42  l53  l64   *    *
!
!  Array elements marked * are not used by the routine.
!
!  Contributed by
!  Peter Mayes and Giuseppe Radicati, IBM ECSEC, Rome, March 23, 1989
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
INTEGER            NBMAX, LDWORK
PARAMETER          ( NBMAX = 32, LDWORK = NBMAX+1 )
!     ..
!     .. Local Scalars ..
INTEGER            I, I2, I3, IB, II, J, JJ, NB
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   WORK( LDWORK, NBMAX )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            ILAENV
EXTERNAL           LSAME, ILAENV
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMM, DPBTF2, DPOTF2, DSYRK, DTRSM, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
IF( ( .NOT.LSAME( UPLO, 'U' ) ) .AND. &
        ( .NOT.LSAME( UPLO, 'L' ) ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( KD.LT.0 ) THEN
   INFO = -3
ELSE IF( LDAB.LT.KD+1 ) THEN
   INFO = -5
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DPBTRF', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Determine the block size for this environment
!
NB = ILAENV( 1, 'DPBTRF', UPLO, N, KD, -1, -1 )
!
!     The block size must not exceed the semi-bandwidth KD, and must not
!     exceed the limit set by the size of the local array WORK.
!
NB = MIN( NB, NBMAX )
!
IF( NB.LE.1 .OR. NB.GT.KD ) THEN
!
!        Use unblocked code
!
   CALL DPBTF2( UPLO, N, KD, AB, LDAB, INFO )
ELSE
!
!        Use blocked code
!
   IF( LSAME( UPLO, 'U' ) ) THEN
!
!           Compute the Cholesky factorization of a symmetric band
!           matrix, given the upper triangle of the matrix in band
!           storage.
!
!           Zero the upper triangle of the work array.
!
      DO 20 J = 1, NB
         DO 10 I = 1, J - 1
            WORK( I, J ) = ZERO
10          CONTINUE
20       CONTINUE
!
!           Process the band matrix one diagonal block at a time.
!
      DO 70 I = 1, N, NB
         IB = MIN( NB, N-I+1 )
!
!              Factorize the diagonal block
!
         CALL DPOTF2( UPLO, IB, AB( KD+1, I ), LDAB-1, II )
         IF( II.NE.0 ) THEN
            INFO = I + II - 1
            GO TO 150
         END IF
         IF( I+IB.LE.N ) THEN
!
!                 Update the relevant part of the trailing submatrix.
!                 If A11 denotes the diagonal block which has just been
!                 factorized, then we need to update the remaining
!                 blocks in the diagram:
!
!                    A11   A12   A13
!                          A22   A23
!                                A33
!
!                 The numbers of rows and columns in the partitioning
!                 are IB, I2, I3 respectively. The blocks A12, A22 and
!                 A23 are empty if IB = KD. The upper triangle of A13
!                 lies outside the band.
!
            I2 = MIN( KD-IB, N-I-IB+1 )
            I3 = MIN( IB, N-I-KD+1 )
!
            IF( I2.GT.0 ) THEN
!
!                    Update A12
!
               CALL DTRSM( 'Left', 'Upper', 'Transpose', &
                               'Non-unit', IB, I2, ONE, AB( KD+1, I ), &
                               LDAB-1, AB( KD+1-IB, I+IB ), LDAB-1 )
!
!                    Update A22
!
               CALL DSYRK( 'Upper', 'Transpose', I2, IB, -ONE, &
                               AB( KD+1-IB, I+IB ), LDAB-1, ONE, &
                               AB( KD+1, I+IB ), LDAB-1 )
            END IF
!
            IF( I3.GT.0 ) THEN
!
!                    Copy the lower triangle of A13 into the work array.
!
               DO 40 JJ = 1, I3
                  DO 30 II = JJ, IB
                     WORK( II, JJ ) = AB( II-JJ+1, JJ+I+KD-1 )
30                   CONTINUE
40                CONTINUE
!
!                    Update A13 (in the work array).
!
               CALL DTRSM( 'Left', 'Upper', 'Transpose', &
                               'Non-unit', IB, I3, ONE, AB( KD+1, I ), &
                               LDAB-1, WORK, LDWORK )
!
!                    Update A23
!
               IF( I2.GT.0 ) &
                      CALL DGEMM( 'Transpose', 'No Transpose', I2, I3, &
                                  IB, -ONE, AB( KD+1-IB, I+IB ), &
                                  LDAB-1, WORK, LDWORK, ONE, &
                                  AB( 1+IB, I+KD ), LDAB-1 )
!
!                    Update A33
!
               CALL DSYRK( 'Upper', 'Transpose', I3, IB, -ONE, &
                               WORK, LDWORK, ONE, AB( KD+1, I+KD ), &
                               LDAB-1 )
!
!                    Copy the lower triangle of A13 back into place.
!
               DO 60 JJ = 1, I3
                  DO 50 II = JJ, IB
                     AB( II-JJ+1, JJ+I+KD-1 ) = WORK( II, JJ )
50                   CONTINUE
60                CONTINUE
            END IF
         END IF
70       CONTINUE
   ELSE
!
!           Compute the Cholesky factorization of a symmetric band
!           matrix, given the lower triangle of the matrix in band
!           storage.
!
!           Zero the lower triangle of the work array.
!
      DO 90 J = 1, NB
         DO 80 I = J + 1, NB
            WORK( I, J ) = ZERO
80          CONTINUE
90       CONTINUE
!
!           Process the band matrix one diagonal block at a time.
!
      DO 140 I = 1, N, NB
         IB = MIN( NB, N-I+1 )
!
!              Factorize the diagonal block
!
         CALL DPOTF2( UPLO, IB, AB( 1, I ), LDAB-1, II )
         IF( II.NE.0 ) THEN
            INFO = I + II - 1
            GO TO 150
         END IF
         IF( I+IB.LE.N ) THEN
!
!                 Update the relevant part of the trailing submatrix.
!                 If A11 denotes the diagonal block which has just been
!                 factorized, then we need to update the remaining
!                 blocks in the diagram:
!
!                    A11
!                    A21   A22
!                    A31   A32   A33
!
!                 The numbers of rows and columns in the partitioning
!                 are IB, I2, I3 respectively. The blocks A21, A22 and
!                 A32 are empty if IB = KD. The lower triangle of A31
!                 lies outside the band.
!
            I2 = MIN( KD-IB, N-I-IB+1 )
            I3 = MIN( IB, N-I-KD+1 )
!
            IF( I2.GT.0 ) THEN
!
!                    Update A21
!
               CALL DTRSM( 'Right', 'Lower', 'Transpose', &
                               'Non-unit', I2, IB, ONE, AB( 1, I ), &
                               LDAB-1, AB( 1+IB, I ), LDAB-1 )
!
!                    Update A22
!
               CALL DSYRK( 'Lower', 'No Transpose', I2, IB, -ONE, &
                               AB( 1+IB, I ), LDAB-1, ONE, &
                               AB( 1, I+IB ), LDAB-1 )
            END IF
!
            IF( I3.GT.0 ) THEN
!
!                    Copy the upper triangle of A31 into the work array.
!
               DO 110 JJ = 1, IB
                  DO 100 II = 1, MIN( JJ, I3 )
                     WORK( II, JJ ) = AB( KD+1-JJ+II, JJ+I-1 )
100                   CONTINUE
110                CONTINUE
!
!                    Update A31 (in the work array).
!
               CALL DTRSM( 'Right', 'Lower', 'Transpose', &
                               'Non-unit', I3, IB, ONE, AB( 1, I ), &
                               LDAB-1, WORK, LDWORK )
!
!                    Update A32
!
               IF( I2.GT.0 ) &
                      CALL DGEMM( 'No transpose', 'Transpose', I3, I2, &
                                  IB, -ONE, WORK, LDWORK, &
                                  AB( 1+IB, I ), LDAB-1, ONE, &
                                  AB( 1+KD-IB, I+IB ), LDAB-1 )
!
!                    Update A33
!
               CALL DSYRK( 'Lower', 'No Transpose', I3, IB, -ONE, &
                               WORK, LDWORK, ONE, AB( 1, I+KD ), &
                               LDAB-1 )
!
!                    Copy the upper triangle of A31 back into place.
!
               DO 130 JJ = 1, IB
                  DO 120 II = 1, MIN( JJ, I3 )
                     AB( KD+1-JJ+II, JJ+I-1 ) = WORK( II, JJ )
120                   CONTINUE
130                CONTINUE
            END IF
         END IF
140       CONTINUE
   END IF
END IF
RETURN
!
150 CONTINUE
RETURN
!
!     End of DPBTRF
!
end subroutine dpbtrf

! ===== End dpbtrf.f90 =====


! ===== Begin dpbtrs.f90 =====

SUBROUTINE DPBTRS( UPLO, N, KD, NRHS, AB, LDAB, B, LDB, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER          UPLO
INTEGER            INFO, KD, LDAB, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   AB( LDAB, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DPBTRS solves a system of linear equations A*X = B with a symmetric
!  positive definite band matrix A using the Cholesky factorization
!  A = U**T*U or A = L*L**T computed by DPBTRF.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  Upper triangular factor stored in AB;
!          = 'L':  Lower triangular factor stored in AB.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  KD      (input) INTEGER
!          The number of superdiagonals of the matrix A if UPLO = 'U',
!          or the number of subdiagonals if UPLO = 'L'.  KD >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  AB      (input) DOUBLE PRECISION array, dimension (LDAB,N)
!          The triangular factor U or L from the Cholesky factorization
!          A = U**T*U or A = L*L**T of the band matrix A, stored in the
!          first KD+1 rows of the array.  The j-th column of U or L is
!          stored in the j-th column of the array AB as follows:
!          if UPLO ='U', AB(kd+1+i-j,j) = U(i,j) for max(1,j-kd)<=i<=j;
!          if UPLO ='L', AB(1+i-j,j)    = L(i,j) for j<=i<=min(n,j+kd).
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= KD+1.
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the right hand side matrix B.
!          On exit, the solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Local Scalars ..
LOGICAL            UPPER
INTEGER            J
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DTBSV, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
UPPER = LSAME( UPLO, 'U' )
IF( .NOT.UPPER .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( KD.LT.0 ) THEN
   INFO = -3
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -4
ELSE IF( LDAB.LT.KD+1 ) THEN
   INFO = -6
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -8
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DPBTRS', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 .OR. NRHS.EQ.0 ) &
       RETURN
!
IF( UPPER ) THEN
!
!        Solve A*X = B where A = U'*U.
!
   DO 10 J = 1, NRHS
!
!           Solve U'*X = B, overwriting B with X.
!
      CALL DTBSV( 'Upper', 'Transpose', 'Non-unit', N, KD, AB, &
                      LDAB, B( 1, J ), 1 )
!
!           Solve U*X = B, overwriting B with X.
!
      CALL DTBSV( 'Upper', 'No transpose', 'Non-unit', N, KD, AB, &
                      LDAB, B( 1, J ), 1 )
10    CONTINUE
ELSE
!
!        Solve A*X = B where A = L*L'.
!
   DO 20 J = 1, NRHS
!
!           Solve L*X = B, overwriting B with X.
!
      CALL DTBSV( 'Lower', 'No transpose', 'Non-unit', N, KD, AB, &
                      LDAB, B( 1, J ), 1 )
!
!           Solve L'*X = B, overwriting B with X.
!
      CALL DTBSV( 'Lower', 'Transpose', 'Non-unit', N, KD, AB, &
                      LDAB, B( 1, J ), 1 )
20    CONTINUE
END IF
!
RETURN
!
!     End of DPBTRS
!
end subroutine dpbtrs

! ===== End dpbtrs.f90 =====


! ===== Begin dpotf2.f90 =====

SUBROUTINE DPOTF2( UPLO, N, A, LDA, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          UPLO
INTEGER            INFO, LDA, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DPOTF2 computes the Cholesky factorization of a real symmetric
!  positive definite matrix A.
!
!  The factorization has the form
!     A = U' * U ,  if UPLO = 'U', or
!     A = L  * L',  if UPLO = 'L',
!  where U is an upper triangular matrix and L is lower triangular.
!
!  This is the unblocked version of the algorithm, calling Level 2 BLAS.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          Specifies whether the upper or lower triangular part of the
!          symmetric matrix A is stored.
!          = 'U':  Upper triangular
!          = 'L':  Lower triangular
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the symmetric matrix A.  If UPLO = 'U', the leading
!          n by n upper triangular part of A contains the upper
!          triangular part of the matrix A, and the strictly lower
!          triangular part of A is not referenced.  If UPLO = 'L', the
!          leading n by n lower triangular part of A contains the lower
!          triangular part of the matrix A, and the strictly upper
!          triangular part of A is not referenced.
!
!          On exit, if INFO = 0, the factor U or L from the Cholesky
!          factorization A = U'*U  or A = L*L'.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -k, the k-th argument had an illegal value
!          > 0: if INFO = k, the leading minor of order k is not
!               positive definite, and the factorization could not be
!               completed.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            UPPER
INTEGER            J
DOUBLE PRECISION   AJJ
!     ..
!     .. External Functions ..
LOGICAL            LSAME
DOUBLE PRECISION   DDOT
EXTERNAL           LSAME, DDOT
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMV, DSCAL, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, SQRT
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
UPPER = LSAME( UPLO, 'U' )
IF( .NOT.UPPER .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -4
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DPOTF2', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
IF( UPPER ) THEN
!
!        Compute the Cholesky factorization A = U'*U.
!
   DO 10 J = 1, N
!
!           Compute U(J,J) and test for non-positive-definiteness.
!
      AJJ = A( J, J ) - DDOT( J-1, A( 1, J ), 1, A( 1, J ), 1 )
      IF( AJJ.LE.ZERO ) THEN
         A( J, J ) = AJJ
         GO TO 30
      END IF
      AJJ = SQRT( AJJ )
      A( J, J ) = AJJ
!
!           Compute elements J+1:N of row J.
!
      IF( J.LT.N ) THEN
         CALL DGEMV( 'Transpose', J-1, N-J, -ONE, A( 1, J+1 ), &
                         LDA, A( 1, J ), 1, ONE, A( J, J+1 ), LDA )
         CALL DSCAL( N-J, ONE / AJJ, A( J, J+1 ), LDA )
      END IF
10    CONTINUE
ELSE
!
!        Compute the Cholesky factorization A = L*L'.
!
   DO 20 J = 1, N
!
!           Compute L(J,J) and test for non-positive-definiteness.
!
      AJJ = A( J, J ) - DDOT( J-1, A( J, 1 ), LDA, A( J, 1 ), &
                LDA )
      IF( AJJ.LE.ZERO ) THEN
         A( J, J ) = AJJ
         GO TO 30
      END IF
      AJJ = SQRT( AJJ )
      A( J, J ) = AJJ
!
!           Compute elements J+1:N of column J.
!
      IF( J.LT.N ) THEN
         CALL DGEMV( 'No transpose', N-J, J-1, -ONE, A( J+1, 1 ), &
                         LDA, A( J, 1 ), LDA, ONE, A( J+1, J ), 1 )
         CALL DSCAL( N-J, ONE / AJJ, A( J+1, J ), 1 )
      END IF
20    CONTINUE
END IF
GO TO 40
!
30 CONTINUE
INFO = J
!
40 CONTINUE
RETURN
!
!     End of DPOTF2
!
end subroutine dpotf2

! ===== End dpotf2.f90 =====


! ===== Begin dpotrf.f90 =====

SUBROUTINE DPOTRF( UPLO, N, A, LDA, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
CHARACTER          UPLO
INTEGER            INFO, LDA, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DPOTRF computes the Cholesky factorization of a real symmetric
!  positive definite matrix A.
!
!  The factorization has the form
!     A = U**T * U,  if UPLO = 'U', or
!     A = L  * L**T,  if UPLO = 'L',
!  where U is an upper triangular matrix and L is lower triangular.
!
!  This is the block version of the algorithm, calling Level 3 BLAS.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  Upper triangle of A is stored;
!          = 'L':  Lower triangle of A is stored.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the symmetric matrix A.  If UPLO = 'U', the leading
!          N-by-N upper triangular part of A contains the upper
!          triangular part of the matrix A, and the strictly lower
!          triangular part of A is not referenced.  If UPLO = 'L', the
!          leading N-by-N lower triangular part of A contains the lower
!          triangular part of the matrix A, and the strictly upper
!          triangular part of A is not referenced.
!
!          On exit, if INFO = 0, the factor U or L from the Cholesky
!          factorization A = U**T*U or A = L*L**T.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, the leading minor of order i is not
!                positive definite, and the factorization could not be
!                completed.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            UPPER
INTEGER            J, JB, NB
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            ILAENV
EXTERNAL           LSAME, ILAENV
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMM, DPOTF2, DSYRK, DTRSM, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
UPPER = LSAME( UPLO, 'U' )
IF( .NOT.UPPER .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -4
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DPOTRF', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Determine the block size for this environment.
!
NB = ILAENV( 1, 'DPOTRF', UPLO, N, -1, -1, -1 )
IF( NB.LE.1 .OR. NB.GE.N ) THEN
!
!        Use unblocked code.
!
   CALL DPOTF2( UPLO, N, A, LDA, INFO )
ELSE
!
!        Use blocked code.
!
   IF( UPPER ) THEN
!
!           Compute the Cholesky factorization A = U'*U.
!
      DO 10 J = 1, N, NB
!
!              Update and factorize the current diagonal block and test
!              for non-positive-definiteness.
!
         JB = MIN( NB, N-J+1 )
         CALL DSYRK( 'Upper', 'Transpose', JB, J-1, -ONE, &
                         A( 1, J ), LDA, ONE, A( J, J ), LDA )
         CALL DPOTF2( 'Upper', JB, A( J, J ), LDA, INFO )
         IF( INFO.NE.0 ) &
                GO TO 30
         IF( J+JB.LE.N ) THEN
!
!                 Compute the current block row.
!
            CALL DGEMM( 'Transpose', 'No transpose', JB, N-J-JB+1, &
                            J-1, -ONE, A( 1, J ), LDA, A( 1, J+JB ), &
                            LDA, ONE, A( J, J+JB ), LDA )
            CALL DTRSM( 'Left', 'Upper', 'Transpose', 'Non-unit', &
                            JB, N-J-JB+1, ONE, A( J, J ), LDA, &
                            A( J, J+JB ), LDA )
         END IF
10       CONTINUE
!
   ELSE
!
!           Compute the Cholesky factorization A = L*L'.
!
      DO 20 J = 1, N, NB
!
!              Update and factorize the current diagonal block and test
!              for non-positive-definiteness.
!
         JB = MIN( NB, N-J+1 )
         CALL DSYRK( 'Lower', 'No transpose', JB, J-1, -ONE, &
                         A( J, 1 ), LDA, ONE, A( J, J ), LDA )
         CALL DPOTF2( 'Lower', JB, A( J, J ), LDA, INFO )
         IF( INFO.NE.0 ) &
                GO TO 30
         IF( J+JB.LE.N ) THEN
!
!                 Compute the current block column.
!
            CALL DGEMM( 'No transpose', 'Transpose', N-J-JB+1, JB, &
                            J-1, -ONE, A( J+JB, 1 ), LDA, A( J, 1 ), &
                            LDA, ONE, A( J+JB, J ), LDA )
            CALL DTRSM( 'Right', 'Lower', 'Transpose', 'Non-unit', &
                            N-J-JB+1, JB, ONE, A( J, J ), LDA, &
                            A( J+JB, J ), LDA )
         END IF
20       CONTINUE
   END IF
END IF
GO TO 40
!
30 CONTINUE
INFO = INFO + J - 1
!
40 CONTINUE
RETURN
!
!     End of DPOTRF
!
end subroutine dpotrf

! ===== End dpotrf.f90 =====


! ===== Begin dpotrs.f90 =====

SUBROUTINE DPOTRS( UPLO, N, NRHS, A, LDA, B, LDB, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
CHARACTER          UPLO
INTEGER            INFO, LDA, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DPOTRS solves a system of linear equations A*X = B with a symmetric
!  positive definite matrix A using the Cholesky factorization
!  A = U**T*U or A = L*L**T computed by DPOTRF.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  Upper triangle of A is stored;
!          = 'L':  Lower triangle of A is stored.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
!          The triangular factor U or L from the Cholesky factorization
!          A = U**T*U or A = L*L**T, as computed by DPOTRF.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the right hand side matrix B.
!          On exit, the solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            UPPER
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DTRSM, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
UPPER = LSAME( UPLO, 'U' )
IF( .NOT.UPPER .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -5
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -7
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DPOTRS', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 .OR. NRHS.EQ.0 ) &
       RETURN
!
IF( UPPER ) THEN
!
!        Solve A*X = B where A = U'*U.
!
!        Solve U'*X = B, overwriting B with X.
!
   CALL DTRSM( 'Left', 'Upper', 'Transpose', 'Non-unit', N, NRHS, &
                   ONE, A, LDA, B, LDB )
!
!        Solve U*X = B, overwriting B with X.
!
   CALL DTRSM( 'Left', 'Upper', 'No transpose', 'Non-unit', N, &
                   NRHS, ONE, A, LDA, B, LDB )
ELSE
!
!        Solve A*X = B where A = L*L'.
!
!        Solve L*X = B, overwriting B with X.
!
   CALL DTRSM( 'Left', 'Lower', 'No transpose', 'Non-unit', N, &
                   NRHS, ONE, A, LDA, B, LDB )
!
!        Solve L'*X = B, overwriting B with X.
!
   CALL DTRSM( 'Left', 'Lower', 'Transpose', 'Non-unit', N, NRHS, &
                   ONE, A, LDA, B, LDB )
END IF
!
RETURN
!
!     End of DPOTRS
!
end subroutine dpotrs

! ===== End dpotrs.f90 =====


! ===== Begin dpttrf.f90 =====

SUBROUTINE DPTTRF( N, D, E, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
INTEGER            INFO, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   D( * ), E( * )
!     ..
!
!  Purpose
!  =======
!
!  DPTTRF computes the factorization of a real symmetric positive
!  definite tridiagonal matrix A.
!
!  If the subdiagonal elements of A are supplied in the array E, the
!  factorization has the form A = L*D*L**T, where D is diagonal and L
!  is unit lower bidiagonal; if the superdiagonal elements of A are
!  supplied, it has the form A = U**T*D*U, where U is unit upper
!  bidiagonal.  (The two forms are equivalent if A is real.)
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  D       (input/output) DOUBLE PRECISION array, dimension (N)
!          On entry, the n diagonal elements of the tridiagonal matrix
!          A.  On exit, the n diagonal elements of the diagonal matrix
!          D from the L*D*L**T factorization of A.
!
!  E       (input/output) DOUBLE PRECISION array, dimension (N-1)
!          On entry, the (n-1) off-diagonal elements of the tridiagonal
!          matrix A.
!          On exit, the (n-1) off-diagonal elements of the unit
!          bidiagonal factor L or U from the factorization of A.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, the leading minor of order i is not
!                positive definite; if i < N, the factorization could
!                not be completed, while if i = N, the factorization was
!                completed, but D(N) = 0.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
INTEGER            I
DOUBLE PRECISION   DI, EI
!     ..
!     .. External Subroutines ..
EXTERNAL           XERBLA
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
IF( N.LT.0 ) THEN
   INFO = -1
   CALL XERBLA( 'DPTTRF', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Compute the L*D*L' (or U'*D*U) factorization of A.
!
DO 10 I = 1, N - 1
!
!        Drop out of the loop if d(i) <= 0: the matrix is not positive
!        definite.
!
   DI = D( I )
   IF( DI.LE.ZERO ) &
          GO TO 20
!
!        Solve for e(i) and d(i+1).
!
   EI = E( I )
   E( I ) = EI / DI
   D( I+1 ) = D( I+1 ) - E( I )*EI
10 CONTINUE
!
!     Check d(n) for positive definiteness.
!
I = N
IF( D( I ).GT.ZERO ) &
       GO TO 30
!
20 CONTINUE
INFO = I
!
30 CONTINUE
RETURN
!
!     End of DPTTRF
!
end subroutine dpttrf

! ===== End dpttrf.f90 =====


! ===== Begin dpttrs.f90 =====

SUBROUTINE DPTTRS( N, NRHS, D, E, B, LDB, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   B( LDB, * ), D( * ), E( * )
!     ..
!
!  Purpose
!  =======
!
!  DPTTRS solves a system of linear equations A * X = B with a
!  symmetric positive definite tridiagonal matrix A using the
!  factorization A = L*D*L**T or A = U**T*D*U computed by DPTTRF.
!  (The two forms are equivalent if A is real.)
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the tridiagonal matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  D       (input) DOUBLE PRECISION array, dimension (N)
!          The n diagonal elements of the diagonal matrix D from the
!          factorization computed by DPTTRF.
!
!  E       (input) DOUBLE PRECISION array, dimension (N-1)
!          The (n-1) off-diagonal elements of the unit bidiagonal factor
!          U or L from the factorization computed by DPTTRF.
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the right hand side matrix B.
!          On exit, the solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  =====================================================================
!
!     .. Local Scalars ..
INTEGER            I, J
!     ..
!     .. External Subroutines ..
EXTERNAL           XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input arguments.
!
INFO = 0
IF( N.LT.0 ) THEN
   INFO = -1
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -2
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -6
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DPTTRS', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Solve A * X = B using the factorization A = L*D*L',
!     overwriting each right hand side vector with its solution.
!
DO 30 J = 1, NRHS
!
!        Solve L * x = b.
!
   DO 10 I = 2, N
      B( I, J ) = B( I, J ) - B( I-1, J )*E( I-1 )
10    CONTINUE
!
!        Solve D * L' * x = b.
!
   B( N, J ) = B( N, J ) / D( N )
   DO 20 I = N - 1, 1, -1
      B( I, J ) = B( I, J ) / D( I ) - B( I+1, J )*E( I )
20    CONTINUE
30 CONTINUE
!
RETURN
!
!     End of DPTTRS
!
end subroutine dpttrs

! ===== End dpttrs.f90 =====


! ===== Begin dsbevx.f90 =====

SUBROUTINE DSBEVX( JOBZ, RANGE, UPLO, N, KD, AB, LDAB, Q, LDQ, VL, &
                       VU, IL, IU, ABSTOL, M, W, Z, LDZ, WORK, IWORK, &
                       IFAIL, INFO )
!
!  -- LAPACK driver routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
CHARACTER          JOBZ, RANGE, UPLO
INTEGER            IL, INFO, IU, KD, LDAB, LDQ, LDZ, M, N
DOUBLE PRECISION   ABSTOL, VL, VU
!     ..
!     .. Array Arguments ..
INTEGER            IFAIL( * ), IWORK( * )
DOUBLE PRECISION   AB( LDAB, * ), Q( LDQ, * ), W( * ), WORK( * ), &
                       Z( LDZ, * )
!     ..
!
!  Purpose
!  =======
!
!  DSBEVX computes selected eigenvalues and, optionally, eigenvectors
!  of a real symmetric band matrix A.  Eigenvalues and eigenvectors can
!  be selected by specifying either a range of values or a range of
!  indices for the desired eigenvalues.
!
!  Arguments
!  =========
!
!  JOBZ    (input) CHARACTER*1
!          = 'N':  Compute eigenvalues only;
!          = 'V':  Compute eigenvalues and eigenvectors.
!
!  RANGE   (input) CHARACTER*1
!          = 'A': all eigenvalues will be found;
!          = 'V': all eigenvalues in the half-open interval (VL,VU]
!                 will be found;
!          = 'I': the IL-th through IU-th eigenvalues will be found.
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  Upper triangle of A is stored;
!          = 'L':  Lower triangle of A is stored.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  KD      (input) INTEGER
!          The number of superdiagonals of the matrix A if UPLO = 'U',
!          or the number of subdiagonals if UPLO = 'L'.  KD >= 0.
!
!  AB      (input/output) DOUBLE PRECISION array, dimension (LDAB, N)
!          On entry, the upper or lower triangle of the symmetric band
!          matrix A, stored in the first KD+1 rows of the array.  The
!          j-th column of A is stored in the j-th column of the array AB
!          as follows:
!          if UPLO = 'U', AB(kd+1+i-j,j) = A(i,j) for max(1,j-kd)<=i<=j;
!          if UPLO = 'L', AB(1+i-j,j)    = A(i,j) for j<=i<=min(n,j+kd).
!
!          On exit, AB is overwritten by values generated during the
!          reduction to tridiagonal form.  If UPLO = 'U', the first
!          superdiagonal and the diagonal of the tridiagonal matrix T
!          are returned in rows KD and KD+1 of AB, and if UPLO = 'L',
!          the diagonal and first subdiagonal of T are returned in the
!          first two rows of AB.
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= KD + 1.
!
!  Q       (output) DOUBLE PRECISION array, dimension (LDQ, N)
!          If JOBZ = 'V', the N-by-N orthogonal matrix used in the
!                         reduction to tridiagonal form.
!          If JOBZ = 'N', the array Q is not referenced.
!
!  LDQ     (input) INTEGER
!          The leading dimension of the array Q.  If JOBZ = 'V', then
!          LDQ >= max(1,N).
!
!  VL      (input) DOUBLE PRECISION
!  VU      (input) DOUBLE PRECISION
!          If RANGE='V', the lower and upper bounds of the interval to
!          be searched for eigenvalues. VL < VU.
!          Not referenced if RANGE = 'A' or 'I'.
!
!  IL      (input) INTEGER
!  IU      (input) INTEGER
!          If RANGE='I', the indices (in ascending order) of the
!          smallest and largest eigenvalues to be returned.
!          1 <= IL <= IU <= N, if N > 0; IL = 1 and IU = 0 if N = 0.
!          Not referenced if RANGE = 'A' or 'V'.
!
!  ABSTOL  (input) DOUBLE PRECISION
!          The absolute error tolerance for the eigenvalues.
!          An approximate eigenvalue is accepted as converged
!          when it is determined to lie in an interval [a,b]
!          of width less than or equal to
!
!                  ABSTOL + EPS *   max( |a|,|b| ) ,
!
!          where EPS is the machine precision.  If ABSTOL is less than
!          or equal to zero, then  EPS*|T|  will be used in its place,
!          where |T| is the 1-norm of the tridiagonal matrix obtained
!          by reducing AB to tridiagonal form.
!
!          Eigenvalues will be computed most accurately when ABSTOL is
!          set to twice the underflow threshold 2*DLAMCH('S'), not zero.
!          If this routine returns with INFO>0, indicating that some
!          eigenvectors did not converge, try setting ABSTOL to
!          2*DLAMCH('S').
!
!          See "Computing Small Singular Values of Bidiagonal Matrices
!          with Guaranteed High Relative Accuracy," by Demmel and
!          Kahan, LAPACK Working Note #3.
!
!  M       (output) INTEGER
!          The total number of eigenvalues found.  0 <= M <= N.
!          If RANGE = 'A', M = N, and if RANGE = 'I', M = IU-IL+1.
!
!  W       (output) DOUBLE PRECISION array, dimension (N)
!          The first M elements contain the selected eigenvalues in
!          ascending order.
!
!  Z       (output) DOUBLE PRECISION array, dimension (LDZ, max(1,M))
!          If JOBZ = 'V', then if INFO = 0, the first M columns of Z
!          contain the orthonormal eigenvectors of the matrix A
!          corresponding to the selected eigenvalues, with the i-th
!          column of Z holding the eigenvector associated with W(i).
!          If an eigenvector fails to converge, then that column of Z
!          contains the latest approximation to the eigenvector, and the
!          index of the eigenvector is returned in IFAIL.
!          If JOBZ = 'N', then Z is not referenced.
!          Note: the user must ensure that at least max(1,M) columns are
!          supplied in the array Z; if RANGE = 'V', the exact value of M
!          is not known in advance and an upper bound must be used.
!
!  LDZ     (input) INTEGER
!          The leading dimension of the array Z.  LDZ >= 1, and if
!          JOBZ = 'V', LDZ >= max(1,N).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (7*N)
!
!  IWORK   (workspace) INTEGER array, dimension (5*N)
!
!  IFAIL   (output) INTEGER array, dimension (N)
!          If JOBZ = 'V', then if INFO = 0, the first M elements of
!          IFAIL are zero.  If INFO > 0, then IFAIL contains the
!          indices of the eigenvectors that failed to converge.
!          If JOBZ = 'N', then IFAIL is not referenced.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit.
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!          > 0:  if INFO = i, then i eigenvectors failed to converge.
!                Their indices are stored in array IFAIL.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D0, ONE = 1.0D0 )
!     ..
!     .. Local Scalars ..
LOGICAL            ALLEIG, INDEIG, LOWER, VALEIG, WANTZ
CHARACTER          ORDER
INTEGER            I, IINFO, IMAX, INDD, INDE, INDEE, INDIBL, &
                       INDISP, INDIWO, INDWRK, ISCALE, ITMP1, J, JJ, &
                       NSPLIT
DOUBLE PRECISION   ABSTLL, ANRM, BIGNUM, EPS, RMAX, RMIN, SAFMIN, &
                       SIGMA, SMLNUM, TMP1, VLL, VUU
!     ..
!     .. External Functions ..
LOGICAL            LSAME
DOUBLE PRECISION   DLAMCH, DLANSB
EXTERNAL           LSAME, DLAMCH, DLANSB
!     ..
!     .. External Subroutines ..
EXTERNAL           DCOPY, DGEMV, DLACPY, DLASCL, DSBTRD, DSCAL, &
                       DSTEBZ, DSTEIN, DSTEQR, DSTERF, DSWAP, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN, SQRT
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
WANTZ = LSAME( JOBZ, 'V' )
ALLEIG = LSAME( RANGE, 'A' )
VALEIG = LSAME( RANGE, 'V' )
INDEIG = LSAME( RANGE, 'I' )
LOWER = LSAME( UPLO, 'L' )
!
INFO = 0
IF( .NOT.( WANTZ .OR. LSAME( JOBZ, 'N' ) ) ) THEN
   INFO = -1
ELSE IF( .NOT.( ALLEIG .OR. VALEIG .OR. INDEIG ) ) THEN
   INFO = -2
ELSE IF( .NOT.( LOWER .OR. LSAME( UPLO, 'U' ) ) ) THEN
   INFO = -3
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( KD.LT.0 ) THEN
   INFO = -5
ELSE IF( LDAB.LT.KD+1 ) THEN
   INFO = -7
ELSE IF( WANTZ .AND. LDQ.LT.MAX( 1, N ) ) THEN
   INFO = -9
ELSE
   IF( VALEIG ) THEN
      IF( N.GT.0 .AND. VU.LE.VL ) &
             INFO = -11
   ELSE IF( INDEIG ) THEN
      IF( IL.LT.1 .OR. IL.GT.MAX( 1, N ) ) THEN
         INFO = -12
      ELSE IF( IU.LT.MIN( N, IL ) .OR. IU.GT.N ) THEN
         INFO = -13
      END IF
   END IF
END IF
IF( INFO.EQ.0 ) THEN
   IF( LDZ.LT.1 .OR. ( WANTZ .AND. LDZ.LT.N ) ) &
          INFO = -18
END IF
!
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DSBEVX', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
M = 0
IF( N.EQ.0 ) &
       RETURN
!
IF( N.EQ.1 ) THEN
   M = 1
   IF( LOWER ) THEN
      TMP1 = AB( 1, 1 )
   ELSE
      TMP1 = AB( KD+1, 1 )
   END IF
   IF( VALEIG ) THEN
      IF( .NOT.( VL.LT.TMP1 .AND. VU.GE.TMP1 ) ) &
             M = 0
   END IF
   IF( M.EQ.1 ) THEN
      W( 1 ) = TMP1
      IF( WANTZ ) &
             Z( 1, 1 ) = ONE
   END IF
   RETURN
END IF
!
!     Get machine constants.
!
SAFMIN = DLAMCH( 'Safe minimum' )
EPS = DLAMCH( 'Precision' )
SMLNUM = SAFMIN / EPS
BIGNUM = ONE / SMLNUM
RMIN = SQRT( SMLNUM )
RMAX = MIN( SQRT( BIGNUM ), ONE / SQRT( SQRT( SAFMIN ) ) )
!
!     Scale matrix to allowable range, if necessary.
!
ISCALE = 0
ABSTLL = ABSTOL
IF( VALEIG ) THEN
   VLL = VL
   VUU = VU
ELSE
   VLL = ZERO
   VUU = ZERO
END IF
ANRM = DLANSB( 'M', UPLO, N, KD, AB, LDAB, WORK )
IF( ANRM.GT.ZERO .AND. ANRM.LT.RMIN ) THEN
   ISCALE = 1
   SIGMA = RMIN / ANRM
ELSE IF( ANRM.GT.RMAX ) THEN
   ISCALE = 1
   SIGMA = RMAX / ANRM
END IF
IF( ISCALE.EQ.1 ) THEN
   IF( LOWER ) THEN
      CALL DLASCL( 'B', KD, KD, ONE, SIGMA, N, N, AB, LDAB, INFO )
   ELSE
      CALL DLASCL( 'Q', KD, KD, ONE, SIGMA, N, N, AB, LDAB, INFO )
   END IF
   IF( ABSTOL.GT.0 ) &
          ABSTLL = ABSTOL*SIGMA
   IF( VALEIG ) THEN
      VLL = VL*SIGMA
      VUU = VU*SIGMA
   END IF
END IF
!
!     Call DSBTRD to reduce symmetric band matrix to tridiagonal form.
!
INDD = 1
INDE = INDD + N
INDWRK = INDE + N
CALL DSBTRD( JOBZ, UPLO, N, KD, AB, LDAB, WORK( INDD ), &
                 WORK( INDE ), Q, LDQ, WORK( INDWRK ), IINFO )
!
!     If all eigenvalues are desired and ABSTOL is less than or equal
!     to zero, then call DSTERF or SSTEQR.  If this fails for some
!     eigenvalue, then try DSTEBZ.
!
IF( ( ALLEIG .OR. ( INDEIG .AND. IL.EQ.1 .AND. IU.EQ.N ) ) .AND. &
        ( ABSTOL.LE.ZERO ) ) THEN
   CALL DCOPY( N, WORK( INDD ), 1, W, 1 )
   INDEE = INDWRK + 2*N
   IF( .NOT.WANTZ ) THEN
      CALL DCOPY( N-1, WORK( INDE ), 1, WORK( INDEE ), 1 )
      CALL DSTERF( N, W, WORK( INDEE ), INFO )
   ELSE
      CALL DLACPY( 'A', N, N, Q, LDQ, Z, LDZ )
      CALL DCOPY( N-1, WORK( INDE ), 1, WORK( INDEE ), 1 )
      CALL DSTEQR( JOBZ, N, W, WORK( INDEE ), Z, LDZ, &
                       WORK( INDWRK ), INFO )
      IF( INFO.EQ.0 ) THEN
         DO 10 I = 1, N
            IFAIL( I ) = 0
10          CONTINUE
      END IF
   END IF
   IF( INFO.EQ.0 ) THEN
      M = N
      GO TO 30
   END IF
   INFO = 0
END IF
!
!     Otherwise, call DSTEBZ and, if eigenvectors are desired, SSTEIN.
!
IF( WANTZ ) THEN
   ORDER = 'B'
ELSE
   ORDER = 'E'
END IF
INDIBL = 1
INDISP = INDIBL + N
INDIWO = INDISP + N
CALL DSTEBZ( RANGE, ORDER, N, VLL, VUU, IL, IU, ABSTLL, &
                 WORK( INDD ), WORK( INDE ), M, NSPLIT, W, &
                 IWORK( INDIBL ), IWORK( INDISP ), WORK( INDWRK ), &
                 IWORK( INDIWO ), INFO )
!
IF( WANTZ ) THEN
   CALL DSTEIN( N, WORK( INDD ), WORK( INDE ), M, W, &
                    IWORK( INDIBL ), IWORK( INDISP ), Z, LDZ, &
                    WORK( INDWRK ), IWORK( INDIWO ), IFAIL, INFO )
!
!        Apply orthogonal matrix used in reduction to tridiagonal
!        form to eigenvectors returned by DSTEIN.
!
   DO 20 J = 1, M
      CALL DCOPY( N, Z( 1, J ), 1, WORK( 1 ), 1 )
      CALL DGEMV( 'N', N, N, ONE, Q, LDQ, WORK, 1, ZERO, &
                      Z( 1, J ), 1 )
20    CONTINUE
END IF
!
!     If matrix was scaled, then rescale eigenvalues appropriately.
!
30 CONTINUE
IF( ISCALE.EQ.1 ) THEN
   IF( INFO.EQ.0 ) THEN
      IMAX = M
   ELSE
      IMAX = INFO - 1
   END IF
   CALL DSCAL( IMAX, ONE / SIGMA, W, 1 )
END IF
!
!     If eigenvalues are not in order, then sort them, along with
!     eigenvectors.
!
IF( WANTZ ) THEN
   DO 50 J = 1, M - 1
      I = 0
      TMP1 = W( J )
      DO 40 JJ = J + 1, M
         IF( W( JJ ).LT.TMP1 ) THEN
            I = JJ
            TMP1 = W( JJ )
         END IF
40       CONTINUE
!
      IF( I.NE.0 ) THEN
         ITMP1 = IWORK( INDIBL+I-1 )
         W( I ) = W( J )
         IWORK( INDIBL+I-1 ) = IWORK( INDIBL+J-1 )
         W( J ) = TMP1
         IWORK( INDIBL+J-1 ) = ITMP1
         CALL DSWAP( N, Z( 1, I ), 1, Z( 1, J ), 1 )
         IF( INFO.NE.0 ) THEN
            ITMP1 = IFAIL( I )
            IFAIL( I ) = IFAIL( J )
            IFAIL( J ) = ITMP1
         END IF
      END IF
50    CONTINUE
END IF
!
RETURN
!
!     End of DSBEVX
!
end subroutine dsbevx

! ===== End dsbevx.f90 =====


! ===== Begin dsbtrd.f90 =====

SUBROUTINE DSBTRD( VECT, UPLO, N, KD, AB, LDAB, D, E, Q, LDQ, &
                       WORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
CHARACTER          UPLO, VECT
INTEGER            INFO, KD, LDAB, LDQ, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   AB( LDAB, * ), D( * ), E( * ), Q( LDQ, * ), &
                       WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DSBTRD reduces a real symmetric band matrix A to symmetric
!  tridiagonal form T by an orthogonal similarity transformation:
!  Q**T * A * Q = T.
!
!  Arguments
!  =========
!
!  VECT    (input) CHARACTER*1
!          = 'N':  do not form Q;
!          = 'V':  form Q;
!          = 'U':  update a matrix X, by forming X*Q.
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  Upper triangle of A is stored;
!          = 'L':  Lower triangle of A is stored.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  KD      (input) INTEGER
!          The number of superdiagonals of the matrix A if UPLO = 'U',
!          or the number of subdiagonals if UPLO = 'L'.  KD >= 0.
!
!  AB      (input/output) DOUBLE PRECISION array, dimension (LDAB,N)
!          On entry, the upper or lower triangle of the symmetric band
!          matrix A, stored in the first KD+1 rows of the array.  The
!          j-th column of A is stored in the j-th column of the array AB
!          as follows:
!          if UPLO = 'U', AB(kd+1+i-j,j) = A(i,j) for max(1,j-kd)<=i<=j;
!          if UPLO = 'L', AB(1+i-j,j)    = A(i,j) for j<=i<=min(n,j+kd).
!          On exit, the diagonal elements of AB are overwritten by the
!          diagonal elements of the tridiagonal matrix T; if KD > 0, the
!          elements on the first superdiagonal (if UPLO = 'U') or the
!          first subdiagonal (if UPLO = 'L') are overwritten by the
!          off-diagonal elements of T; the rest of AB is overwritten by
!          values generated during the reduction.
!
!  LDAB    (input) INTEGER
!          The leading dimension of the array AB.  LDAB >= KD+1.
!
!  D       (output) DOUBLE PRECISION array, dimension (N)
!          The diagonal elements of the tridiagonal matrix T.
!
!  E       (output) DOUBLE PRECISION array, dimension (N-1)
!          The off-diagonal elements of the tridiagonal matrix T:
!          E(i) = T(i,i+1) if UPLO = 'U'; E(i) = T(i+1,i) if UPLO = 'L'.
!
!  Q       (input/output) DOUBLE PRECISION array, dimension (LDQ,N)
!          On entry, if VECT = 'U', then Q must contain an N-by-N
!          matrix X; if VECT = 'N' or 'V', then Q need not be set.
!
!          On exit:
!          if VECT = 'V', Q contains the N-by-N orthogonal matrix Q;
!          if VECT = 'U', Q contains the product X*Q;
!          if VECT = 'N', the array Q is not referenced.
!
!  LDQ     (input) INTEGER
!          The leading dimension of the array Q.
!          LDQ >= 1, and LDQ >= N if VECT = 'V' or 'U'.
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (N)
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  Further Details
!  ===============
!
!  Modified by Linda Kaufman, Bell Labs.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            INITQ, UPPER, WANTQ
INTEGER            I, I2, IBL, INCA, INCX, IQAEND, IQB, IQEND, J, &
                       J1, J1END, J1INC, J2, JEND, JIN, JINC, K, KD1, &
                       KDM1, KDN, L, LAST, LEND, NQ, NR, NRT
DOUBLE PRECISION   TEMP
!     ..
!     .. External Subroutines ..
EXTERNAL           DLAR2V, DLARGV, DLARTG, DLARTV, DLASET, DROT, &
                       XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters
!
INITQ = LSAME( VECT, 'V' )
WANTQ = INITQ .OR. LSAME( VECT, 'U' )
UPPER = LSAME( UPLO, 'U' )
KD1 = KD + 1
KDM1 = KD - 1
INCX = LDAB - 1
IQEND = 1
!
INFO = 0
IF( .NOT.WANTQ .AND. .NOT.LSAME( VECT, 'N' ) ) THEN
   INFO = -1
ELSE IF( .NOT.UPPER .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( KD.LT.0 ) THEN
   INFO = -4
ELSE IF( LDAB.LT.KD1 ) THEN
   INFO = -6
ELSE IF( LDQ.LT.MAX( 1, N ) .AND. WANTQ ) THEN
   INFO = -10
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DSBTRD', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Initialize Q to the unit matrix, if needed
!
IF( INITQ ) &
       CALL DLASET( 'Full', N, N, ZERO, ONE, Q, LDQ )
!
!     Wherever possible, plane rotations are generated and applied in
!     vector operations of length NR over the index set J1:J2:KD1.
!
!     The cosines and sines of the plane rotations are stored in the
!     arrays D and WORK.
!
INCA = KD1*LDAB
KDN = MIN( N-1, KD )
IF( UPPER ) THEN
!
   IF( KD.GT.1 ) THEN
!
!           Reduce to tridiagonal form, working with upper triangle
!
      NR = 0
      J1 = KDN + 2
      J2 = 1
!
      DO 90 I = 1, N - 2
!
!              Reduce i-th row of matrix to tridiagonal form
!
         DO 80 K = KDN + 1, 2, -1
            J1 = J1 + KDN
            J2 = J2 + KDN
!
            IF( NR.GT.0 ) THEN
!
!                    generate plane rotations to annihilate nonzero
!                    elements which have been created outside the band
!
               CALL DLARGV( NR, AB( 1, J1-1 ), INCA, WORK( J1 ), &
                                KD1, D( J1 ), KD1 )
!
!                    apply rotations from the right
!
!
!                    Dependent on the the number of diagonals either
!                    DLARTV or DROT is used
!
               IF( NR.GE.2*KD-1 ) THEN
                  DO 10 L = 1, KD - 1
                     CALL DLARTV( NR, AB( L+1, J1-1 ), INCA, &
                                      AB( L, J1 ), INCA, D( J1 ), &
                                      WORK( J1 ), KD1 )
10                   CONTINUE
!
               ELSE
                  JEND = J1 + ( NR-1 )*KD1
                  DO 20 JINC = J1, JEND, KD1
                     CALL DROT( KDM1, AB( 2, JINC-1 ), 1, &
                                    AB( 1, JINC ), 1, D( JINC ), &
                                    WORK( JINC ) )
20                   CONTINUE
               END IF
            END IF
!
!
            IF( K.GT.2 ) THEN
               IF( K.LE.N-I+1 ) THEN
!
!                       generate plane rotation to annihilate a(i,i+k-1)
!                       within the band
!
                  CALL DLARTG( AB( KD-K+3, I+K-2 ), &
                                   AB( KD-K+2, I+K-1 ), D( I+K-1 ), &
                                   WORK( I+K-1 ), TEMP )
                  AB( KD-K+3, I+K-2 ) = TEMP
!
!                       apply rotation from the right
!
                  CALL DROT( K-3, AB( KD-K+4, I+K-2 ), 1, &
                                 AB( KD-K+3, I+K-1 ), 1, D( I+K-1 ), &
                                 WORK( I+K-1 ) )
               END IF
               NR = NR + 1
               J1 = J1 - KDN - 1
            END IF
!
!                 apply plane rotations from both sides to diagonal
!                 blocks
!
            IF( NR.GT.0 ) &
                   CALL DLAR2V( NR, AB( KD1, J1-1 ), AB( KD1, J1 ), &
                                AB( KD, J1 ), INCA, D( J1 ), &
                                WORK( J1 ), KD1 )
!
!                 apply plane rotations from the left
!
            IF( NR.GT.0 ) THEN
               IF( 2*KD-1.LT.NR ) THEN
!
!                    Dependent on the the number of diagonals either
!                    DLARTV or DROT is used
!
                  DO 30 L = 1, KD - 1
                     IF( J2+L.GT.N ) THEN
                        NRT = NR - 1
                     ELSE
                        NRT = NR
                     END IF
                     IF( NRT.GT.0 ) &
                            CALL DLARTV( NRT, AB( KD-L, J1+L ), INCA, &
                                         AB( KD-L+1, J1+L ), INCA, &
                                         D( J1 ), WORK( J1 ), KD1 )
30                   CONTINUE
               ELSE
                  J1END = J1 + KD1*( NR-2 )
                  IF( J1END.GE.J1 ) THEN
                     DO 40 JIN = J1, J1END, KD1
                        CALL DROT( KD-1, AB( KD-1, JIN+1 ), INCX, &
                                       AB( KD, JIN+1 ), INCX, &
                                       D( JIN ), WORK( JIN ) )
40                      CONTINUE
                  END IF
                  LEND = MIN( KDM1, N-J2 )
                  LAST = J1END + KD1
                  IF( LEND.GT.0 ) &
                         CALL DROT( LEND, AB( KD-1, LAST+1 ), INCX, &
                                    AB( KD, LAST+1 ), INCX, D( LAST ), &
                                    WORK( LAST ) )
               END IF
            END IF
!
            IF( WANTQ ) THEN
!
!                    accumulate product of plane rotations in Q
!
               IF( INITQ ) THEN
!
!                 take advantage of the fact that Q was
!                 initially the Identity matrix
!
                  IQEND = MAX( IQEND, J2 )
                  I2 = MAX( 0, K-3 )
                  IQAEND = 1 + I*KD
                  IF( K.EQ.2 ) &
                         IQAEND = IQAEND + KD
                  IQAEND = MIN( IQAEND, IQEND )
                  DO 50 J = J1, J2, KD1
                     IBL = I - I2 / KDM1
                     I2 = I2 + 1
                     IQB = MAX( 1, J-IBL )
                     NQ = 1 + IQAEND - IQB
                     IQAEND = MIN( IQAEND+KD, IQEND )
                     CALL DROT( NQ, Q( IQB, J-1 ), 1, Q( IQB, J ), &
                                    1, D( J ), WORK( J ) )
50                   CONTINUE
               ELSE
!
                  DO 60 J = J1, J2, KD1
                     CALL DROT( N, Q( 1, J-1 ), 1, Q( 1, J ), 1, &
                                    D( J ), WORK( J ) )
60                   CONTINUE
               END IF
!
            END IF
!
            IF( J2+KDN.GT.N ) THEN
!
!                    adjust J2 to keep within the bounds of the matrix
!
               NR = NR - 1
               J2 = J2 - KDN - 1
            END IF
!
            DO 70 J = J1, J2, KD1
!
!                    create nonzero element a(j-1,j+kd) outside the band
!                    and store it in WORK
!
               WORK( J+KD ) = WORK( J )*AB( 1, J+KD )
               AB( 1, J+KD ) = D( J )*AB( 1, J+KD )
70             CONTINUE
80          CONTINUE
90       CONTINUE
   END IF
!
   IF( KD.GT.0 ) THEN
!
!           copy off-diagonal elements to E
!
      DO 100 I = 1, N - 1
         E( I ) = AB( KD, I+1 )
100       CONTINUE
   ELSE
!
!           set E to zero if original matrix was diagonal
!
      DO 110 I = 1, N - 1
         E( I ) = ZERO
110       CONTINUE
   END IF
!
!        copy diagonal elements to D
!
   DO 120 I = 1, N
      D( I ) = AB( KD1, I )
120    CONTINUE
!
ELSE
!
   IF( KD.GT.1 ) THEN
!
!           Reduce to tridiagonal form, working with lower triangle
!
      NR = 0
      J1 = KDN + 2
      J2 = 1
!
      DO 210 I = 1, N - 2
!
!              Reduce i-th column of matrix to tridiagonal form
!
         DO 200 K = KDN + 1, 2, -1
            J1 = J1 + KDN
            J2 = J2 + KDN
!
            IF( NR.GT.0 ) THEN
!
!                    generate plane rotations to annihilate nonzero
!                    elements which have been created outside the band
!
               CALL DLARGV( NR, AB( KD1, J1-KD1 ), INCA, &
                                WORK( J1 ), KD1, D( J1 ), KD1 )
!
!                    apply plane rotations from one side
!
!
!                    Dependent on the the number of diagonals either
!                    DLARTV or DROT is used
!
               IF( NR.GT.2*KD-1 ) THEN
                  DO 130 L = 1, KD - 1
                     CALL DLARTV( NR, AB( KD1-L, J1-KD1+L ), INCA, &
                                      AB( KD1-L+1, J1-KD1+L ), INCA, &
                                      D( J1 ), WORK( J1 ), KD1 )
130                   CONTINUE
               ELSE
                  JEND = J1 + KD1*( NR-1 )
                  DO 140 JINC = J1, JEND, KD1
                     CALL DROT( KDM1, AB( KD, JINC-KD ), INCX, &
                                    AB( KD1, JINC-KD ), INCX, &
                                    D( JINC ), WORK( JINC ) )
140                   CONTINUE
               END IF
!
            END IF
!
            IF( K.GT.2 ) THEN
               IF( K.LE.N-I+1 ) THEN
!
!                       generate plane rotation to annihilate a(i+k-1,i)
!                       within the band
!
                  CALL DLARTG( AB( K-1, I ), AB( K, I ), &
                                   D( I+K-1 ), WORK( I+K-1 ), TEMP )
                  AB( K-1, I ) = TEMP
!
!                       apply rotation from the left
!
                  CALL DROT( K-3, AB( K-2, I+1 ), LDAB-1, &
                                 AB( K-1, I+1 ), LDAB-1, D( I+K-1 ), &
                                 WORK( I+K-1 ) )
               END IF
               NR = NR + 1
               J1 = J1 - KDN - 1
            END IF
!
!                 apply plane rotations from both sides to diagonal
!                 blocks
!
            IF( NR.GT.0 ) &
                   CALL DLAR2V( NR, AB( 1, J1-1 ), AB( 1, J1 ), &
                                AB( 2, J1-1 ), INCA, D( J1 ), &
                                WORK( J1 ), KD1 )
!
!                 apply plane rotations from the right
!
!
!                    Dependent on the the number of diagonals either
!                    DLARTV or DROT is used
!
            IF( NR.GT.0 ) THEN
               IF( NR.GT.2*KD-1 ) THEN
                  DO 150 L = 1, KD - 1
                     IF( J2+L.GT.N ) THEN
                        NRT = NR - 1
                     ELSE
                        NRT = NR
                     END IF
                     IF( NRT.GT.0 ) &
                            CALL DLARTV( NRT, AB( L+2, J1-1 ), INCA, &
                                         AB( L+1, J1 ), INCA, D( J1 ), &
                                         WORK( J1 ), KD1 )
150                   CONTINUE
               ELSE
                  J1END = J1 + KD1*( NR-2 )
                  IF( J1END.GE.J1 ) THEN
                     DO 160 J1INC = J1, J1END, KD1
                        CALL DROT( KDM1, AB( 3, J1INC-1 ), 1, &
                                       AB( 2, J1INC ), 1, D( J1INC ), &
                                       WORK( J1INC ) )
160                      CONTINUE
                  END IF
                  LEND = MIN( KDM1, N-J2 )
                  LAST = J1END + KD1
                  IF( LEND.GT.0 ) &
                         CALL DROT( LEND, AB( 3, LAST-1 ), 1, &
                                    AB( 2, LAST ), 1, D( LAST ), &
                                    WORK( LAST ) )
               END IF
            END IF
!
!
!
            IF( WANTQ ) THEN
!
!                    accumulate product of plane rotations in Q
!
               IF( INITQ ) THEN
!
!                 take advantage of the fact that Q was
!                 initially the Identity matrix
!
                  IQEND = MAX( IQEND, J2 )
                  I2 = MAX( 0, K-3 )
                  IQAEND = 1 + I*KD
                  IF( K.EQ.2 ) &
                         IQAEND = IQAEND + KD
                  IQAEND = MIN( IQAEND, IQEND )
                  DO 170 J = J1, J2, KD1
                     IBL = I - I2 / KDM1
                     I2 = I2 + 1
                     IQB = MAX( 1, J-IBL )
                     NQ = 1 + IQAEND - IQB
                     IQAEND = MIN( IQAEND+KD, IQEND )
                     CALL DROT( NQ, Q( IQB, J-1 ), 1, Q( IQB, J ), &
                                    1, D( J ), WORK( J ) )
170                   CONTINUE
               ELSE
!
                  DO 180 J = J1, J2, KD1
                     CALL DROT( N, Q( 1, J-1 ), 1, Q( 1, J ), 1, &
                                    D( J ), WORK( J ) )
180                   CONTINUE
               END IF
            END IF
!
            IF( J2+KDN.GT.N ) THEN
!
!                    adjust J2 to keep within the bounds of the matrix
!
               NR = NR - 1
               J2 = J2 - KDN - 1
            END IF
!
            DO 190 J = J1, J2, KD1
!
!                    create nonzero element a(j+kd,j-1) outside the
!                    band and store it in WORK
!
               WORK( J+KD ) = WORK( J )*AB( KD1, J )
               AB( KD1, J ) = D( J )*AB( KD1, J )
190             CONTINUE
200          CONTINUE
210       CONTINUE
   END IF
!
   IF( KD.GT.0 ) THEN
!
!           copy off-diagonal elements to E
!
      DO 220 I = 1, N - 1
         E( I ) = AB( 2, I )
220       CONTINUE
   ELSE
!
!           set E to zero if original matrix was diagonal
!
      DO 230 I = 1, N - 1
         E( I ) = ZERO
230       CONTINUE
   END IF
!
!        copy diagonal elements to D
!
   DO 240 I = 1, N
      D( I ) = AB( 1, I )
240    CONTINUE
END IF
!
RETURN
!
!     End of DSBTRD
!
end subroutine dsbtrd

! ===== End dsbtrd.f90 =====


! ===== Begin dstebz.f90 =====

SUBROUTINE DSTEBZ( RANGE, ORDER, N, VL, VU, IL, IU, ABSTOL, D, E, &
                       M, NSPLIT, W, IBLOCK, ISPLIT, WORK, IWORK, &
                       INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
CHARACTER          ORDER, RANGE
INTEGER            IL, INFO, IU, M, N, NSPLIT
DOUBLE PRECISION   ABSTOL, VL, VU
!     ..
!     .. Array Arguments ..
INTEGER            IBLOCK( * ), ISPLIT( * ), IWORK( * )
DOUBLE PRECISION   D( * ), E( * ), W( * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DSTEBZ computes the eigenvalues of a symmetric tridiagonal
!  matrix T.  The user may ask for all eigenvalues, all eigenvalues
!  in the half-open interval (VL, VU], or the IL-th through IU-th
!  eigenvalues.
!
!  To avoid overflow, the matrix must be scaled so that its
!  largest element is no greater than overflow**(1/2) *
!  underflow**(1/4) in absolute value, and for greatest
!  accuracy, it should not be much smaller than that.
!
!  See W. Kahan "Accurate Eigenvalues of a Symmetric Tridiagonal
!  Matrix", Report CS41, Computer Science Dept., Stanford
!  University, July 21, 1966.
!
!  Arguments
!  =========
!
!  RANGE   (input) CHARACTER
!          = 'A': ("All")   all eigenvalues will be found.
!          = 'V': ("Value") all eigenvalues in the half-open interval
!                           (VL, VU] will be found.
!          = 'I': ("Index") the IL-th through IU-th eigenvalues (of the
!                           entire matrix) will be found.
!
!  ORDER   (input) CHARACTER
!          = 'B': ("By Block") the eigenvalues will be grouped by
!                              split-off block (see IBLOCK, ISPLIT) and
!                              ordered from smallest to largest within
!                              the block.
!          = 'E': ("Entire matrix")
!                              the eigenvalues for the entire matrix
!                              will be ordered from smallest to
!                              largest.
!
!  N       (input) INTEGER
!          The order of the tridiagonal matrix T.  N >= 0.
!
!  VL      (input) DOUBLE PRECISION
!  VU      (input) DOUBLE PRECISION
!          If RANGE='V', the lower and upper bounds of the interval to
!          be searched for eigenvalues.  Eigenvalues less than or equal
!          to VL, or greater than VU, will not be returned.  VL < VU.
!          Not referenced if RANGE = 'A' or 'I'.
!
!  IL      (input) INTEGER
!  IU      (input) INTEGER
!          If RANGE='I', the indices (in ascending order) of the
!          smallest and largest eigenvalues to be returned.
!          1 <= IL <= IU <= N, if N > 0; IL = 1 and IU = 0 if N = 0.
!          Not referenced if RANGE = 'A' or 'V'.
!
!  ABSTOL  (input) DOUBLE PRECISION
!          The absolute tolerance for the eigenvalues.  An eigenvalue
!          (or cluster) is considered to be located if it has been
!          determined to lie in an interval whose width is ABSTOL or
!          less.  If ABSTOL is less than or equal to zero, then ULP*|T|
!          will be used, where |T| means the 1-norm of T.
!
!          Eigenvalues will be computed most accurately when ABSTOL is
!          set to twice the underflow threshold 2*DLAMCH('S'), not zero.
!
!  D       (input) DOUBLE PRECISION array, dimension (N)
!          The n diagonal elements of the tridiagonal matrix T.
!
!  E       (input) DOUBLE PRECISION array, dimension (N-1)
!          The (n-1) off-diagonal elements of the tridiagonal matrix T.
!
!  M       (output) INTEGER
!          The actual number of eigenvalues found. 0 <= M <= N.
!          (See also the description of INFO=2,3.)
!
!  NSPLIT  (output) INTEGER
!          The number of diagonal blocks in the matrix T.
!          1 <= NSPLIT <= N.
!
!  W       (output) DOUBLE PRECISION array, dimension (N)
!          On exit, the first M elements of W will contain the
!          eigenvalues.  (DSTEBZ may use the remaining N-M elements as
!          workspace.)
!
!  IBLOCK  (output) INTEGER array, dimension (N)
!          At each row/column j where E(j) is zero or small, the
!          matrix T is considered to split into a block diagonal
!          matrix.  On exit, if INFO = 0, IBLOCK(i) specifies to which
!          block (from 1 to the number of blocks) the eigenvalue W(i)
!          belongs.  (DSTEBZ may use the remaining N-M elements as
!          workspace.)
!
!  ISPLIT  (output) INTEGER array, dimension (N)
!          The splitting points, at which T breaks up into submatrices.
!          The first submatrix consists of rows/columns 1 to ISPLIT(1),
!          the second of rows/columns ISPLIT(1)+1 through ISPLIT(2),
!          etc., and the NSPLIT-th consists of rows/columns
!          ISPLIT(NSPLIT-1)+1 through ISPLIT(NSPLIT)=N.
!          (Only the first NSPLIT elements will actually be used, but
!          since the user cannot know a priori what value NSPLIT will
!          have, N words must be reserved for ISPLIT.)
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (4*N)
!
!  IWORK   (workspace) INTEGER array, dimension (3*N)
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  some or all of the eigenvalues failed to converge or
!                were not computed:
!                =1 or 3: Bisection failed to converge for some
!                        eigenvalues; these eigenvalues are flagged by a
!                        negative block number.  The effect is that the
!                        eigenvalues may not be as accurate as the
!                        absolute and relative tolerances.  This is
!                        generally caused by unexpectedly inaccurate
!                        arithmetic.
!                =2 or 3: RANGE='I' only: Not all of the eigenvalues
!                        IL:IU were found.
!                        Effect: M < IU+1-IL
!                        Cause:  non-monotonic arithmetic, causing the
!                                Sturm sequence to be non-monotonic.
!                        Cure:   recalculate, using RANGE='A', and pick
!                                out eigenvalues IL:IU.  In some cases,
!                                increasing the PARAMETER "FUDGE" may
!                                make things work.
!                = 4:    RANGE='I', and the Gershgorin interval
!                        initially used was too small.  No eigenvalues
!                        were computed.
!                        Probable cause: your machine has sloppy
!                                        floating-point arithmetic.
!                        Cure: Increase the PARAMETER "FUDGE",
!                              recompile, and try again.
!
!  Internal Parameters
!  ===================
!
!  RELFAC  DOUBLE PRECISION, default = 2.0e0
!          The relative tolerance.  An interval (a,b] lies within
!          "relative tolerance" if  b-a < RELFAC*ulp*max(|a|,|b|),
!          where "ulp" is the machine precision (distance from 1 to
!          the next larger floating point number.)
!
!  FUDGE   DOUBLE PRECISION, default = 2
!          A "fudge factor" to widen the Gershgorin intervals.  Ideally,
!          a value of 1 should work, but on machines with sloppy
!          arithmetic, this needs to be larger.  The default for
!          publicly released versions should be large enough to handle
!          the worst machine around.  Note that this has no effect
!          on accuracy of the solution.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE, TWO, HALF
PARAMETER          ( ZERO = 0.0D0, ONE = 1.0D0, TWO = 2.0D0, &
                       HALF = 1.0D0 / TWO )
DOUBLE PRECISION   FUDGE, RELFAC
PARAMETER          ( FUDGE = 2.0D0, RELFAC = 2.0D0 )
!     ..
!     .. Local Scalars ..
LOGICAL            NCNVRG, TOOFEW
INTEGER            IB, IBEGIN, IDISCL, IDISCU, IE, IEND, IINFO, &
                       IM, IN, IOFF, IORDER, IOUT, IRANGE, ITMAX, &
                       ITMP1, IW, IWOFF, J, JB, JDISC, JE, NB, NWL, &
                       NWU
DOUBLE PRECISION   ATOLI, BNORM, GL, GU, PIVMIN, RTOLI, SAFEMN, &
                       TMP1, TMP2, TNORM, ULP, WKILL, WL, WLU, WU, WUL
!     ..
!     .. Local Arrays ..
INTEGER            IDUMMA( 1 )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            ILAENV
DOUBLE PRECISION   DLAMCH
EXTERNAL           LSAME, ILAENV, DLAMCH
!     ..
!     .. External Subroutines ..
EXTERNAL           DLAEBZ, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, INT, LOG, MAX, MIN, SQRT
!     ..
!     .. Executable Statements ..
!
INFO = 0
!
!     Decode RANGE
!
IF( LSAME( RANGE, 'A' ) ) THEN
   IRANGE = 1
ELSE IF( LSAME( RANGE, 'V' ) ) THEN
   IRANGE = 2
ELSE IF( LSAME( RANGE, 'I' ) ) THEN
   IRANGE = 3
ELSE
   IRANGE = 0
END IF
!
!     Decode ORDER
!
IF( LSAME( ORDER, 'B' ) ) THEN
   IORDER = 2
ELSE IF( LSAME( ORDER, 'E' ) ) THEN
   IORDER = 1
ELSE
   IORDER = 0
END IF
!
!     Check for Errors
!
IF( IRANGE.LE.0 ) THEN
   INFO = -1
ELSE IF( IORDER.LE.0 ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( IRANGE.EQ.2 ) THEN
   IF( VL.GE.VU ) &
          INFO = -5
ELSE IF( IRANGE.EQ.3 .AND. ( IL.LT.1 .OR. IL.GT.MAX( 1, N ) ) ) &
              THEN
   INFO = -6
ELSE IF( IRANGE.EQ.3 .AND. ( IU.LT.MIN( N, IL ) .OR. IU.GT.N ) ) &
              THEN
   INFO = -7
END IF
!
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DSTEBZ', -INFO )
   RETURN
END IF
!
!     Initialize error flags
!
INFO = 0
NCNVRG = .FALSE.
TOOFEW = .FALSE.
!
!     Quick return if possible
!
M = 0
IF( N.EQ.0 ) &
       RETURN
!
!     Simplifications:
!
IF( IRANGE.EQ.3 .AND. IL.EQ.1 .AND. IU.EQ.N ) &
       IRANGE = 1
!
!     Get machine constants
!     NB is the minimum vector length for vector bisection, or 0
!     if only scalar is to be done.
!
SAFEMN = DLAMCH( 'S' )
ULP = DLAMCH( 'P' )
RTOLI = ULP*RELFAC
NB = ILAENV( 1, 'DSTEBZ', ' ', N, -1, -1, -1 )
IF( NB.LE.1 ) &
       NB = 0
!
!     Special Case when N=1
!
IF( N.EQ.1 ) THEN
   NSPLIT = 1
   ISPLIT( 1 ) = 1
   IF( IRANGE.EQ.2 .AND. ( VL.GE.D( 1 ) .OR. VU.LT.D( 1 ) ) ) THEN
      M = 0
   ELSE
      W( 1 ) = D( 1 )
      IBLOCK( 1 ) = 1
      M = 1
   END IF
   RETURN
END IF
!
!     Compute Splitting Points
!
NSPLIT = 1
WORK( N ) = ZERO
PIVMIN = ONE
!
!DIR$ NOVECTOR
DO 10 J = 2, N
   TMP1 = E( J-1 )**2
   IF( ABS( D( J )*D( J-1 ) )*ULP**2+SAFEMN.GT.TMP1 ) THEN
      ISPLIT( NSPLIT ) = J - 1
      NSPLIT = NSPLIT + 1
      WORK( J-1 ) = ZERO
   ELSE
      WORK( J-1 ) = TMP1
      PIVMIN = MAX( PIVMIN, TMP1 )
   END IF
10 CONTINUE
ISPLIT( NSPLIT ) = N
PIVMIN = PIVMIN*SAFEMN
!
!     Compute Interval and ATOLI
!
IF( IRANGE.EQ.3 ) THEN
!
!        RANGE='I': Compute the interval containing eigenvalues
!                   IL through IU.
!
!        Compute Gershgorin interval for entire (split) matrix
!        and use it as the initial interval
!
   GU = D( 1 )
   GL = D( 1 )
   TMP1 = ZERO
!
   DO 20 J = 1, N - 1
      TMP2 = SQRT( WORK( J ) )
      GU = MAX( GU, D( J )+TMP1+TMP2 )
      GL = MIN( GL, D( J )-TMP1-TMP2 )
      TMP1 = TMP2
20    CONTINUE
!
   GU = MAX( GU, D( N )+TMP1 )
   GL = MIN( GL, D( N )-TMP1 )
   TNORM = MAX( ABS( GL ), ABS( GU ) )
   GL = GL - FUDGE*TNORM*ULP*N - FUDGE*TWO*PIVMIN
   GU = GU + FUDGE*TNORM*ULP*N + FUDGE*PIVMIN
!
!        Compute Iteration parameters
!
   ITMAX = INT( ( LOG( TNORM+PIVMIN )-LOG( PIVMIN ) ) / &
               LOG( TWO ) ) + 2
   IF( ABSTOL.LE.ZERO ) THEN
      ATOLI = ULP*TNORM
   ELSE
      ATOLI = ABSTOL
   END IF
!
   WORK( N+1 ) = GL
   WORK( N+2 ) = GL
   WORK( N+3 ) = GU
   WORK( N+4 ) = GU
   WORK( N+5 ) = GL
   WORK( N+6 ) = GU
   IWORK( 1 ) = -1
   IWORK( 2 ) = -1
   IWORK( 3 ) = N + 1
   IWORK( 4 ) = N + 1
   IWORK( 5 ) = IL - 1
   IWORK( 6 ) = IU
!
   CALL DLAEBZ( 3, ITMAX, N, 2, 2, NB, ATOLI, RTOLI, PIVMIN, D, E, &
                    WORK, IWORK( 5 ), WORK( N+1 ), WORK( N+5 ), IOUT, &
                    IWORK, W, IBLOCK, IINFO )
!
   IF( IWORK( 6 ).EQ.IU ) THEN
      WL = WORK( N+1 )
      WLU = WORK( N+3 )
      NWL = IWORK( 1 )
      WU = WORK( N+4 )
      WUL = WORK( N+2 )
      NWU = IWORK( 4 )
   ELSE
      WL = WORK( N+2 )
      WLU = WORK( N+4 )
      NWL = IWORK( 2 )
      WU = WORK( N+3 )
      WUL = WORK( N+1 )
      NWU = IWORK( 3 )
   END IF
!
   IF( NWL.LT.0 .OR. NWL.GE.N .OR. NWU.LT.1 .OR. NWU.GT.N ) THEN
      INFO = 4
      RETURN
   END IF
ELSE
!
!        RANGE='A' or 'V' -- Set ATOLI
!
   TNORM = MAX( ABS( D( 1 ) )+ABS( E( 1 ) ), &
               ABS( D( N ) )+ABS( E( N-1 ) ) )
!
   DO 30 J = 2, N - 1
      TNORM = MAX( TNORM, ABS( D( J ) )+ABS( E( J-1 ) )+ &
                  ABS( E( J ) ) )
30    CONTINUE
!
   IF( ABSTOL.LE.ZERO ) THEN
      ATOLI = ULP*TNORM
   ELSE
      ATOLI = ABSTOL
   END IF
!
   IF( IRANGE.EQ.2 ) THEN
      WL = VL
      WU = VU
   ELSE
      WL = ZERO
      WU = ZERO
   END IF
END IF
!
!     Find Eigenvalues -- Loop Over Blocks and recompute NWL and NWU.
!     NWL accumulates the number of eigenvalues .le. WL,
!     NWU accumulates the number of eigenvalues .le. WU
!
M = 0
IEND = 0
INFO = 0
NWL = 0
NWU = 0
!
DO 70 JB = 1, NSPLIT
   IOFF = IEND
   IBEGIN = IOFF + 1
   IEND = ISPLIT( JB )
   IN = IEND - IOFF
!
   IF( IN.EQ.1 ) THEN
!
!           Special Case -- IN=1
!
      IF( IRANGE.EQ.1 .OR. WL.GE.D( IBEGIN )-PIVMIN ) &
             NWL = NWL + 1
      IF( IRANGE.EQ.1 .OR. WU.GE.D( IBEGIN )-PIVMIN ) &
             NWU = NWU + 1
      IF( IRANGE.EQ.1 .OR. ( WL.LT.D( IBEGIN )-PIVMIN .AND. WU.GE. &
              D( IBEGIN )-PIVMIN ) ) THEN
         M = M + 1
         W( M ) = D( IBEGIN )
         IBLOCK( M ) = JB
      END IF
   ELSE
!
!           General Case -- IN > 1
!
!           Compute Gershgorin Interval
!           and use it as the initial interval
!
      GU = D( IBEGIN )
      GL = D( IBEGIN )
      TMP1 = ZERO
!
      DO 40 J = IBEGIN, IEND - 1
         TMP2 = ABS( E( J ) )
         GU = MAX( GU, D( J )+TMP1+TMP2 )
         GL = MIN( GL, D( J )-TMP1-TMP2 )
         TMP1 = TMP2
40       CONTINUE
!
      GU = MAX( GU, D( IEND )+TMP1 )
      GL = MIN( GL, D( IEND )-TMP1 )
      BNORM = MAX( ABS( GL ), ABS( GU ) )
      GL = GL - FUDGE*BNORM*ULP*IN - FUDGE*PIVMIN
      GU = GU + FUDGE*BNORM*ULP*IN + FUDGE*PIVMIN
!
!           Compute ATOLI for the current submatrix
!
      IF( ABSTOL.LE.ZERO ) THEN
         ATOLI = ULP*MAX( ABS( GL ), ABS( GU ) )
      ELSE
         ATOLI = ABSTOL
      END IF
!
      IF( IRANGE.GT.1 ) THEN
         IF( GU.LT.WL ) THEN
            NWL = NWL + IN
            NWU = NWU + IN
            GO TO 70
         END IF
         GL = MAX( GL, WL )
         GU = MIN( GU, WU )
         IF( GL.GE.GU ) &
                GO TO 70
      END IF
!
!           Set Up Initial Interval
!
      WORK( N+1 ) = GL
      WORK( N+IN+1 ) = GU
      CALL DLAEBZ( 1, 0, IN, IN, 1, NB, ATOLI, RTOLI, PIVMIN, &
                       D( IBEGIN ), E( IBEGIN ), WORK( IBEGIN ), &
                       IDUMMA, WORK( N+1 ), WORK( N+2*IN+1 ), IM, &
                       IWORK, W( M+1 ), IBLOCK( M+1 ), IINFO )
!
      NWL = NWL + IWORK( 1 )
      NWU = NWU + IWORK( IN+1 )
      IWOFF = M - IWORK( 1 )
!
!           Compute Eigenvalues
!
      ITMAX = INT( ( LOG( GU-GL+PIVMIN )-LOG( PIVMIN ) ) / &
                  LOG( TWO ) ) + 2
      CALL DLAEBZ( 2, ITMAX, IN, IN, 1, NB, ATOLI, RTOLI, PIVMIN, &
                       D( IBEGIN ), E( IBEGIN ), WORK( IBEGIN ), &
                       IDUMMA, WORK( N+1 ), WORK( N+2*IN+1 ), IOUT, &
                       IWORK, W( M+1 ), IBLOCK( M+1 ), IINFO )
!
!           Copy Eigenvalues Into W and IBLOCK
!           Use -JB for block number for unconverged eigenvalues.
!
      DO 60 J = 1, IOUT
         TMP1 = HALF*( WORK( J+N )+WORK( J+IN+N ) )
!
!              Flag non-convergence.
!
         IF( J.GT.IOUT-IINFO ) THEN
            NCNVRG = .TRUE.
            IB = -JB
         ELSE
            IB = JB
         END IF
         DO 50 JE = IWORK( J ) + 1 + IWOFF, &
                     IWORK( J+IN ) + IWOFF
            W( JE ) = TMP1
            IBLOCK( JE ) = IB
50          CONTINUE
60       CONTINUE
!
      M = M + IM
   END IF
70 CONTINUE
!
!     If RANGE='I', then (WL,WU) contains eigenvalues NWL+1,...,NWU
!     If NWL+1 < IL or NWU > IU, discard extra eigenvalues.
!
IF( IRANGE.EQ.3 ) THEN
   IM = 0
   IDISCL = IL - 1 - NWL
   IDISCU = NWU - IU
!
   IF( IDISCL.GT.0 .OR. IDISCU.GT.0 ) THEN
      DO 80 JE = 1, M
         IF( W( JE ).LE.WLU .AND. IDISCL.GT.0 ) THEN
            IDISCL = IDISCL - 1
         ELSE IF( W( JE ).GE.WUL .AND. IDISCU.GT.0 ) THEN
            IDISCU = IDISCU - 1
         ELSE
            IM = IM + 1
            W( IM ) = W( JE )
            IBLOCK( IM ) = IBLOCK( JE )
         END IF
80       CONTINUE
      M = IM
   END IF
   IF( IDISCL.GT.0 .OR. IDISCU.GT.0 ) THEN
!
!           Code to deal with effects of bad arithmetic:
!           Some low eigenvalues to be discarded are not in (WL,WLU],
!           or high eigenvalues to be discarded are not in (WUL,WU]
!           so just kill off the smallest IDISCL/largest IDISCU
!           eigenvalues, by simply finding the smallest/largest
!           eigenvalue(s).
!
!           (If N(w) is monotone non-decreasing, this should never
!               happen.)
!
      IF( IDISCL.GT.0 ) THEN
         WKILL = WU
         DO 100 JDISC = 1, IDISCL
            IW = 0
            DO 90 JE = 1, M
               IF( IBLOCK( JE ).NE.0 .AND. &
                       ( W( JE ).LT.WKILL .OR. IW.EQ.0 ) ) THEN
                  IW = JE
                  WKILL = W( JE )
               END IF
90             CONTINUE
            IBLOCK( IW ) = 0
100          CONTINUE
      END IF
      IF( IDISCU.GT.0 ) THEN
!
         WKILL = WL
         DO 120 JDISC = 1, IDISCU
            IW = 0
            DO 110 JE = 1, M
               IF( IBLOCK( JE ).NE.0 .AND. &
                       ( W( JE ).GT.WKILL .OR. IW.EQ.0 ) ) THEN
                  IW = JE
                  WKILL = W( JE )
               END IF
110             CONTINUE
            IBLOCK( IW ) = 0
120          CONTINUE
      END IF
      IM = 0
      DO 130 JE = 1, M
         IF( IBLOCK( JE ).NE.0 ) THEN
            IM = IM + 1
            W( IM ) = W( JE )
            IBLOCK( IM ) = IBLOCK( JE )
         END IF
130       CONTINUE
      M = IM
   END IF
   IF( IDISCL.LT.0 .OR. IDISCU.LT.0 ) THEN
      TOOFEW = .TRUE.
   END IF
END IF
!
!     If ORDER='B', do nothing -- the eigenvalues are already sorted
!        by block.
!     If ORDER='E', sort the eigenvalues from smallest to largest
!
IF( IORDER.EQ.1 .AND. NSPLIT.GT.1 ) THEN
   DO 150 JE = 1, M - 1
      IE = 0
      TMP1 = W( JE )
      DO 140 J = JE + 1, M
         IF( W( J ).LT.TMP1 ) THEN
            IE = J
            TMP1 = W( J )
         END IF
140       CONTINUE
!
      IF( IE.NE.0 ) THEN
         ITMP1 = IBLOCK( IE )
         W( IE ) = W( JE )
         IBLOCK( IE ) = IBLOCK( JE )
         W( JE ) = TMP1
         IBLOCK( JE ) = ITMP1
      END IF
150    CONTINUE
END IF
!
INFO = 0
IF( NCNVRG ) &
       INFO = INFO + 1
IF( TOOFEW ) &
       INFO = INFO + 2
RETURN
!
!     End of DSTEBZ
!
end subroutine dstebz

! ===== End dstebz.f90 =====


! ===== Begin dstein.f90 =====

SUBROUTINE DSTEIN( N, D, E, M, W, IBLOCK, ISPLIT, Z, LDZ, WORK, &
                       IWORK, IFAIL, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
INTEGER            INFO, LDZ, M, N
!     ..
!     .. Array Arguments ..
INTEGER            IBLOCK( * ), IFAIL( * ), ISPLIT( * ), &
                       IWORK( * )
DOUBLE PRECISION   D( * ), E( * ), W( * ), WORK( * ), Z( LDZ, * )
!     ..
!
!  Purpose
!  =======
!
!  DSTEIN computes the eigenvectors of a real symmetric tridiagonal
!  matrix T corresponding to specified eigenvalues, using inverse
!  iteration.
!
!  The maximum number of iterations allowed for each eigenvector is
!  specified by an internal parameter MAXITS (currently set to 5).
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix.  N >= 0.
!
!  D       (input) DOUBLE PRECISION array, dimension (N)
!          The n diagonal elements of the tridiagonal matrix T.
!
!  E       (input) DOUBLE PRECISION array, dimension (N)
!          The (n-1) subdiagonal elements of the tridiagonal matrix
!          T, in elements 1 to N-1.  E(N) need not be set.
!
!  M       (input) INTEGER
!          The number of eigenvectors to be found.  0 <= M <= N.
!
!  W       (input) DOUBLE PRECISION array, dimension (N)
!          The first M elements of W contain the eigenvalues for
!          which eigenvectors are to be computed.  The eigenvalues
!          should be grouped by split-off block and ordered from
!          smallest to largest within the block.  ( The output array
!          W from DSTEBZ with ORDER = 'B' is expected here. )
!
!  IBLOCK  (input) INTEGER array, dimension (N)
!          The submatrix indices associated with the corresponding
!          eigenvalues in W; IBLOCK(i)=1 if eigenvalue W(i) belongs to
!          the first submatrix from the top, =2 if W(i) belongs to
!          the second submatrix, etc.  ( The output array IBLOCK
!          from DSTEBZ is expected here. )
!
!  ISPLIT  (input) INTEGER array, dimension (N)
!          The splitting points, at which T breaks up into submatrices.
!          The first submatrix consists of rows/columns 1 to
!          ISPLIT( 1 ), the second of rows/columns ISPLIT( 1 )+1
!          through ISPLIT( 2 ), etc.
!          ( The output array ISPLIT from DSTEBZ is expected here. )
!
!  Z       (output) DOUBLE PRECISION array, dimension (LDZ, M)
!          The computed eigenvectors.  The eigenvector associated
!          with the eigenvalue W(i) is stored in the i-th column of
!          Z.  Any vector which fails to converge is set to its current
!          iterate after MAXITS iterations.
!
!  LDZ     (input) INTEGER
!          The leading dimension of the array Z.  LDZ >= max(1,N).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (5*N)
!
!  IWORK   (workspace) INTEGER array, dimension (N)
!
!  IFAIL   (output) INTEGER array, dimension (M)
!          On normal exit, all elements of IFAIL are zero.
!          If one or more eigenvectors fail to converge after
!          MAXITS iterations, then their indices are stored in
!          array IFAIL.
!
!  INFO    (output) INTEGER
!          = 0: successful exit.
!          < 0: if INFO = -i, the i-th argument had an illegal value
!          > 0: if INFO = i, then i eigenvectors failed to converge
!               in MAXITS iterations.  Their indices are stored in
!               array IFAIL.
!
!  Internal Parameters
!  ===================
!
!  MAXITS  INTEGER, default = 5
!          The maximum number of iterations performed.
!
!  EXTRA   INTEGER, default = 2
!          The number of iterations performed after norm growth
!          criterion is satisfied, should be at least 1.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE, TEN, ODM3, ODM1
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0, TEN = 1.0D+1, &
                       ODM3 = 1.0D-3, ODM1 = 1.0D-1 )
INTEGER            MAXITS, EXTRA
PARAMETER          ( MAXITS = 5, EXTRA = 2 )
!     ..
!     .. Local Scalars ..
INTEGER            B1, BLKSIZ, BN, GPIND, I, IINFO, INDRV1, &
                       INDRV2, INDRV3, INDRV4, INDRV5, ITS, J, J1, &
                       JBLK, JMAX, NBLK, NRMCHK
DOUBLE PRECISION   DTPCRT, EPS, EPS1, NRM, ONENRM, ORTOL, PERTOL, &
                       SCL, SEP, TOL, XJ, XJM, ZTR
!     ..
!     .. Local Arrays ..
INTEGER            ISEED( 4 )
!     ..
!     .. External Functions ..
INTEGER            IDAMAX
DOUBLE PRECISION   DASUM, DDOT, DLAMCH, DNRM2
EXTERNAL           IDAMAX, DASUM, DDOT, DLAMCH, DNRM2
!     ..
!     .. External Subroutines ..
EXTERNAL           DAXPY, DCOPY, DLAGTF, DLAGTS, DLARNV, DSCAL, &
                       XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, SQRT
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
DO 10 I = 1, M
   IFAIL( I ) = 0
10 CONTINUE
!
IF( N.LT.0 ) THEN
   INFO = -1
ELSE IF( M.LT.0 .OR. M.GT.N ) THEN
   INFO = -4
ELSE IF( LDZ.LT.MAX( 1, N ) ) THEN
   INFO = -9
ELSE
   DO 20 J = 2, M
      IF( IBLOCK( J ).LT.IBLOCK( J-1 ) ) THEN
         INFO = -6
         GO TO 30
      END IF
      IF( IBLOCK( J ).EQ.IBLOCK( J-1 ) .AND. W( J ).LT.W( J-1 ) ) &
               THEN
         INFO = -5
         GO TO 30
      END IF
20    CONTINUE
30    CONTINUE
END IF
!
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DSTEIN', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 .OR. M.EQ.0 ) THEN
   RETURN
ELSE IF( N.EQ.1 ) THEN
   Z( 1, 1 ) = ONE
   RETURN
END IF
!
!     Get machine constants.
!
EPS = DLAMCH( 'Precision' )
!
!     Initialize seed for random number generator DLARNV.
!
DO 40 I = 1, 4
   ISEED( I ) = 1
40 CONTINUE
!
!     Initialize pointers.
!
INDRV1 = 0
INDRV2 = INDRV1 + N
INDRV3 = INDRV2 + N
INDRV4 = INDRV3 + N
INDRV5 = INDRV4 + N
!
!     Compute eigenvectors of matrix blocks.
!
J1 = 1
DO 160 NBLK = 1, IBLOCK( M )
!
!        Find starting and ending indices of block nblk.
!
   IF( NBLK.EQ.1 ) THEN
      B1 = 1
   ELSE
      B1 = ISPLIT( NBLK-1 ) + 1
   END IF
   BN = ISPLIT( NBLK )
   BLKSIZ = BN - B1 + 1
   IF( BLKSIZ.EQ.1 ) &
          GO TO 60
   GPIND = B1
!
!        Compute reorthogonalization criterion and stopping criterion.
!
   ONENRM = ABS( D( B1 ) ) + ABS( E( B1 ) )
   ONENRM = MAX( ONENRM, ABS( D( BN ) )+ABS( E( BN-1 ) ) )
   DO 50 I = B1 + 1, BN - 1
      ONENRM = MAX( ONENRM, ABS( D( I ) )+ABS( E( I-1 ) )+ &
                   ABS( E( I ) ) )
50    CONTINUE
   ORTOL = ODM3*ONENRM
!
   DTPCRT = SQRT( ODM1 / BLKSIZ )
!
!        Loop through eigenvalues of block nblk.
!
60    CONTINUE
   JBLK = 0
   DO 150 J = J1, M
      IF( IBLOCK( J ).NE.NBLK ) THEN
         J1 = J
         GO TO 160
      END IF
      JBLK = JBLK + 1
      XJ = W( J )
!
!           Skip all the work if the block size is one.
!
      IF( BLKSIZ.EQ.1 ) THEN
         WORK( INDRV1+1 ) = ONE
         GO TO 120
      END IF
!
!           If eigenvalues j and j-1 are too close, add a relatively
!           small perturbation.
!
      IF( JBLK.GT.1 ) THEN
         EPS1 = ABS( EPS*XJ )
         PERTOL = TEN*EPS1
         SEP = XJ - XJM
         IF( SEP.LT.PERTOL ) &
                XJ = XJM + PERTOL
      END IF
!
      ITS = 0
      NRMCHK = 0
!
!           Get random starting vector.
!
      CALL DLARNV( 2, ISEED, BLKSIZ, WORK( INDRV1+1 ) )
!
!           Copy the matrix T so it won't be destroyed in factorization.
!
      CALL DCOPY( BLKSIZ, D( B1 ), 1, WORK( INDRV4+1 ), 1 )
      CALL DCOPY( BLKSIZ-1, E( B1 ), 1, WORK( INDRV2+2 ), 1 )
      CALL DCOPY( BLKSIZ-1, E( B1 ), 1, WORK( INDRV3+1 ), 1 )
!
!           Compute LU factors with partial pivoting  ( PT = LU )
!
      TOL = ZERO
      CALL DLAGTF( BLKSIZ, WORK( INDRV4+1 ), XJ, WORK( INDRV2+2 ), &
                       WORK( INDRV3+1 ), TOL, WORK( INDRV5+1 ), IWORK, &
                       IINFO )
!
!           Update iteration count.
!
70       CONTINUE
      ITS = ITS + 1
      IF( ITS.GT.MAXITS ) &
             GO TO 100
!
!           Normalize and scale the righthand side vector Pb.
!
      SCL = BLKSIZ*ONENRM*MAX( EPS, &
                ABS( WORK( INDRV4+BLKSIZ ) ) ) / &
                DASUM( BLKSIZ, WORK( INDRV1+1 ), 1 )
      CALL DSCAL( BLKSIZ, SCL, WORK( INDRV1+1 ), 1 )
!
!           Solve the system LU = Pb.
!
      CALL DLAGTS( -1, BLKSIZ, WORK( INDRV4+1 ), WORK( INDRV2+2 ), &
                       WORK( INDRV3+1 ), WORK( INDRV5+1 ), IWORK, &
                       WORK( INDRV1+1 ), TOL, IINFO )
!
!           Reorthogonalize by modified Gram-Schmidt if eigenvalues are
!           close enough.
!
      IF( JBLK.EQ.1 ) &
             GO TO 90
      IF( ABS( XJ-XJM ).GT.ORTOL ) &
             GPIND = J
      IF( GPIND.NE.J ) THEN
         DO 80 I = GPIND, J - 1
            ZTR = -DDOT( BLKSIZ, WORK( INDRV1+1 ), 1, Z( B1, I ), &
                      1 )
            CALL DAXPY( BLKSIZ, ZTR, Z( B1, I ), 1, &
                            WORK( INDRV1+1 ), 1 )
80          CONTINUE
      END IF
!
!           Check the infinity norm of the iterate.
!
90       CONTINUE
      JMAX = IDAMAX( BLKSIZ, WORK( INDRV1+1 ), 1 )
      NRM = ABS( WORK( INDRV1+JMAX ) )
!
!           Continue for additional iterations after norm reaches
!           stopping criterion.
!
      IF( NRM.LT.DTPCRT ) &
             GO TO 70
      NRMCHK = NRMCHK + 1
      IF( NRMCHK.LT.EXTRA+1 ) &
             GO TO 70
!
      GO TO 110
!
!           If stopping criterion was not satisfied, update info and
!           store eigenvector number in array ifail.
!
100       CONTINUE
      INFO = INFO + 1
      IFAIL( INFO ) = J
!
!           Accept iterate as jth eigenvector.
!
110       CONTINUE
      SCL = ONE / DNRM2( BLKSIZ, WORK( INDRV1+1 ), 1 )
      JMAX = IDAMAX( BLKSIZ, WORK( INDRV1+1 ), 1 )
      IF( WORK( INDRV1+JMAX ).LT.ZERO ) &
             SCL = -SCL
      CALL DSCAL( BLKSIZ, SCL, WORK( INDRV1+1 ), 1 )
120       CONTINUE
      DO 130 I = 1, N
         Z( I, J ) = ZERO
130       CONTINUE
      DO 140 I = 1, BLKSIZ
         Z( B1+I-1, J ) = WORK( INDRV1+I )
140       CONTINUE
!
!           Save the shift to check eigenvalue spacing at next
!           iteration.
!
      XJM = XJ
!
150    CONTINUE
160 CONTINUE
!
RETURN
!
!     End of DSTEIN
!
end subroutine dstein

! ===== End dstein.f90 =====


! ===== Begin dsteqr.f90 =====

SUBROUTINE DSTEQR( COMPZ, N, D, E, Z, LDZ, WORK, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER          COMPZ
INTEGER            INFO, LDZ, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   D( * ), E( * ), WORK( * ), Z( LDZ, * )
!     ..
!
!  Purpose
!  =======
!
!  DSTEQR computes all eigenvalues and, optionally, eigenvectors of a
!  symmetric tridiagonal matrix using the implicit QL or QR method.
!  The eigenvectors of a full or band symmetric matrix can also be found
!  if DSYTRD or DSPTRD or DSBTRD has been used to reduce this matrix to
!  tridiagonal form.
!
!  Arguments
!  =========
!
!  COMPZ   (input) CHARACTER*1
!          = 'N':  Compute eigenvalues only.
!          = 'V':  Compute eigenvalues and eigenvectors of the original
!                  symmetric matrix.  On entry, Z must contain the
!                  orthogonal matrix used to reduce the original matrix
!                  to tridiagonal form.
!          = 'I':  Compute eigenvalues and eigenvectors of the
!                  tridiagonal matrix.  Z is initialized to the identity
!                  matrix.
!
!  N       (input) INTEGER
!          The order of the matrix.  N >= 0.
!
!  D       (input/output) DOUBLE PRECISION array, dimension (N)
!          On entry, the diagonal elements of the tridiagonal matrix.
!          On exit, if INFO = 0, the eigenvalues in ascending order.
!
!  E       (input/output) DOUBLE PRECISION array, dimension (N-1)
!          On entry, the (n-1) subdiagonal elements of the tridiagonal
!          matrix.
!          On exit, E has been destroyed.
!
!  Z       (input/output) DOUBLE PRECISION array, dimension (LDZ, N)
!          On entry, if  COMPZ = 'V', then Z contains the orthogonal
!          matrix used in the reduction to tridiagonal form.
!          On exit, if INFO = 0, then if  COMPZ = 'V', Z contains the
!          orthonormal eigenvectors of the original symmetric matrix,
!          and if COMPZ = 'I', Z contains the orthonormal eigenvectors
!          of the symmetric tridiagonal matrix.
!          If COMPZ = 'N', then Z is not referenced.
!
!  LDZ     (input) INTEGER
!          The leading dimension of the array Z.  LDZ >= 1, and if
!          eigenvectors are desired, then  LDZ >= max(1,N).
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (max(1,2*N-2))
!          If COMPZ = 'N', then WORK is not referenced.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  the algorithm has failed to find all the eigenvalues in
!                a total of 30*N iterations; if INFO = i, then i
!                elements of E have not converged to zero; on exit, D
!                and E contain the elements of a symmetric tridiagonal
!                matrix which is orthogonally similar to the original
!                matrix.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE, TWO, THREE
PARAMETER          ( ZERO = 0.0D0, ONE = 1.0D0, TWO = 2.0D0, &
                       THREE = 3.0D0 )
INTEGER            MAXIT
PARAMETER          ( MAXIT = 30 )
!     ..
!     .. Local Scalars ..
INTEGER            I, ICOMPZ, II, ISCALE, J, JTOT, K, L, L1, LEND, &
                       LENDM1, LENDP1, LENDSV, LM1, LSV, M, MM, MM1, &
                       NM1, NMAXIT
DOUBLE PRECISION   ANORM, B, C, EPS, EPS2, F, G, P, R, RT1, RT2, &
                       S, SAFMAX, SAFMIN, SSFMAX, SSFMIN, TST
!     ..
!     .. External Functions ..
LOGICAL            LSAME
DOUBLE PRECISION   DLAMCH, DLANST, DLAPY2
EXTERNAL           LSAME, DLAMCH, DLANST, DLAPY2
!     ..
!     .. External Subroutines ..
EXTERNAL           DLAE2, DLAEV2, DLARTG, DLASCL, DLASET, DLASR, &
                       DLASRT, DSWAP, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, SIGN, SQRT
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
!
IF( LSAME( COMPZ, 'N' ) ) THEN
   ICOMPZ = 0
ELSE IF( LSAME( COMPZ, 'V' ) ) THEN
   ICOMPZ = 1
ELSE IF( LSAME( COMPZ, 'I' ) ) THEN
   ICOMPZ = 2
ELSE
   ICOMPZ = -1
END IF
IF( ICOMPZ.LT.0 ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( ( LDZ.LT.1 ) .OR. ( ICOMPZ.GT.0 .AND. LDZ.LT.MAX( 1, &
             N ) ) ) THEN
   INFO = -6
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DSTEQR', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
IF( N.EQ.1 ) THEN
   IF( ICOMPZ.EQ.2 ) &
          Z( 1, 1 ) = ONE
   RETURN
END IF
!
!     Determine the unit roundoff and over/underflow thresholds.
!
EPS = DLAMCH( 'E' )
EPS2 = EPS**2
SAFMIN = DLAMCH( 'S' )
SAFMAX = ONE / SAFMIN
SSFMAX = SQRT( SAFMAX ) / THREE
SSFMIN = SQRT( SAFMIN ) / EPS2
!
!     Compute the eigenvalues and eigenvectors of the tridiagonal
!     matrix.
!
IF( ICOMPZ.EQ.2 ) &
       CALL DLASET( 'Full', N, N, ZERO, ONE, Z, LDZ )
!
NMAXIT = N*MAXIT
JTOT = 0
!
!     Determine where the matrix splits and choose QL or QR iteration
!     for each block, according to whether top or bottom diagonal
!     element is smaller.
!
L1 = 1
NM1 = N - 1
!
10 CONTINUE
IF( L1.GT.N ) &
       GO TO 160
IF( L1.GT.1 ) &
       E( L1-1 ) = ZERO
IF( L1.LE.NM1 ) THEN
   DO 20 M = L1, NM1
      TST = ABS( E( M ) )
      IF( TST.EQ.ZERO ) &
             GO TO 30
      IF( TST.LE.( SQRT( ABS( D( M ) ) )*SQRT( ABS( D( M+ &
              1 ) ) ) )*EPS ) THEN
         E( M ) = ZERO
         GO TO 30
      END IF
20    CONTINUE
END IF
M = N
!
30 CONTINUE
L = L1
LSV = L
LEND = M
LENDSV = LEND
L1 = M + 1
IF( LEND.EQ.L ) &
       GO TO 10
!
!     Scale submatrix in rows and columns L to LEND
!
ANORM = DLANST( 'I', LEND-L+1, D( L ), E( L ) )
ISCALE = 0
IF( ANORM.EQ.ZERO ) &
       GO TO 10
IF( ANORM.GT.SSFMAX ) THEN
   ISCALE = 1
   CALL DLASCL( 'G', 0, 0, ANORM, SSFMAX, LEND-L+1, 1, D( L ), N, &
                    INFO )
   CALL DLASCL( 'G', 0, 0, ANORM, SSFMAX, LEND-L, 1, E( L ), N, &
                    INFO )
ELSE IF( ANORM.LT.SSFMIN ) THEN
   ISCALE = 2
   CALL DLASCL( 'G', 0, 0, ANORM, SSFMIN, LEND-L+1, 1, D( L ), N, &
                    INFO )
   CALL DLASCL( 'G', 0, 0, ANORM, SSFMIN, LEND-L, 1, E( L ), N, &
                    INFO )
END IF
!
!     Choose between QL and QR iteration
!
IF( ABS( D( LEND ) ).LT.ABS( D( L ) ) ) THEN
   LEND = LSV
   L = LENDSV
END IF
!
IF( LEND.GT.L ) THEN
!
!        QL Iteration
!
!        Look for small subdiagonal element.
!
40    CONTINUE
   IF( L.NE.LEND ) THEN
      LENDM1 = LEND - 1
      DO 50 M = L, LENDM1
         TST = ABS( E( M ) )**2
         IF( TST.LE.( EPS2*ABS( D( M ) ) )*ABS( D( M+1 ) )+ &
                 SAFMIN )GO TO 60
50       CONTINUE
   END IF
!
   M = LEND
!
60    CONTINUE
   IF( M.LT.LEND ) &
          E( M ) = ZERO
   P = D( L )
   IF( M.EQ.L ) &
          GO TO 80
!
!        If remaining matrix is 2-by-2, use DLAE2 or SLAEV2
!        to compute its eigensystem.
!
   IF( M.EQ.L+1 ) THEN
      IF( ICOMPZ.GT.0 ) THEN
         CALL DLAEV2( D( L ), E( L ), D( L+1 ), RT1, RT2, C, S )
         WORK( L ) = C
         WORK( N-1+L ) = S
         CALL DLASR( 'R', 'V', 'B', N, 2, WORK( L ), &
                         WORK( N-1+L ), Z( 1, L ), LDZ )
      ELSE
         CALL DLAE2( D( L ), E( L ), D( L+1 ), RT1, RT2 )
      END IF
      D( L ) = RT1
      D( L+1 ) = RT2
      E( L ) = ZERO
      L = L + 2
      IF( L.LE.LEND ) &
             GO TO 40
      GO TO 140
   END IF
!
   IF( JTOT.EQ.NMAXIT ) &
          GO TO 140
   JTOT = JTOT + 1
!
!        Form shift.
!
   G = ( D( L+1 )-P ) / ( TWO*E( L ) )
   R = DLAPY2( G, ONE )
   G = D( M ) - P + ( E( L ) / ( G+SIGN( R, G ) ) )
!
   S = ONE
   C = ONE
   P = ZERO
!
!        Inner loop
!
   MM1 = M - 1
   DO 70 I = MM1, L, -1
      F = S*E( I )
      B = C*E( I )
      CALL DLARTG( G, F, C, S, R )
      IF( I.NE.M-1 ) &
             E( I+1 ) = R
      G = D( I+1 ) - P
      R = ( D( I )-G )*S + TWO*C*B
      P = S*R
      D( I+1 ) = G + P
      G = C*R - B
!
!           If eigenvectors are desired, then save rotations.
!
      IF( ICOMPZ.GT.0 ) THEN
         WORK( I ) = C
         WORK( N-1+I ) = -S
      END IF
!
70    CONTINUE
!
!        If eigenvectors are desired, then apply saved rotations.
!
   IF( ICOMPZ.GT.0 ) THEN
      MM = M - L + 1
      CALL DLASR( 'R', 'V', 'B', N, MM, WORK( L ), WORK( N-1+L ), &
                      Z( 1, L ), LDZ )
   END IF
!
   D( L ) = D( L ) - P
   E( L ) = G
   GO TO 40
!
!        Eigenvalue found.
!
80    CONTINUE
   D( L ) = P
!
   L = L + 1
   IF( L.LE.LEND ) &
          GO TO 40
   GO TO 140
!
ELSE
!
!        QR Iteration
!
!        Look for small superdiagonal element.
!
90    CONTINUE
   IF( L.NE.LEND ) THEN
      LENDP1 = LEND + 1
      DO 100 M = L, LENDP1, -1
         TST = ABS( E( M-1 ) )**2
         IF( TST.LE.( EPS2*ABS( D( M ) ) )*ABS( D( M-1 ) )+ &
                 SAFMIN )GO TO 110
100       CONTINUE
   END IF
!
   M = LEND
!
110    CONTINUE
   IF( M.GT.LEND ) &
          E( M-1 ) = ZERO
   P = D( L )
   IF( M.EQ.L ) &
          GO TO 130
!
!        If remaining matrix is 2-by-2, use DLAE2 or SLAEV2
!        to compute its eigensystem.
!
   IF( M.EQ.L-1 ) THEN
      IF( ICOMPZ.GT.0 ) THEN
         CALL DLAEV2( D( L-1 ), E( L-1 ), D( L ), RT1, RT2, C, S )
         WORK( M ) = C
         WORK( N-1+M ) = S
         CALL DLASR( 'R', 'V', 'F', N, 2, WORK( M ), &
                         WORK( N-1+M ), Z( 1, L-1 ), LDZ )
      ELSE
         CALL DLAE2( D( L-1 ), E( L-1 ), D( L ), RT1, RT2 )
      END IF
      D( L-1 ) = RT1
      D( L ) = RT2
      E( L-1 ) = ZERO
      L = L - 2
      IF( L.GE.LEND ) &
             GO TO 90
      GO TO 140
   END IF
!
   IF( JTOT.EQ.NMAXIT ) &
          GO TO 140
   JTOT = JTOT + 1
!
!        Form shift.
!
   G = ( D( L-1 )-P ) / ( TWO*E( L-1 ) )
   R = DLAPY2( G, ONE )
   G = D( M ) - P + ( E( L-1 ) / ( G+SIGN( R, G ) ) )
!
   S = ONE
   C = ONE
   P = ZERO
!
!        Inner loop
!
   LM1 = L - 1
   DO 120 I = M, LM1
      F = S*E( I )
      B = C*E( I )
      CALL DLARTG( G, F, C, S, R )
      IF( I.NE.M ) &
             E( I-1 ) = R
      G = D( I ) - P
      R = ( D( I+1 )-G )*S + TWO*C*B
      P = S*R
      D( I ) = G + P
      G = C*R - B
!
!           If eigenvectors are desired, then save rotations.
!
      IF( ICOMPZ.GT.0 ) THEN
         WORK( I ) = C
         WORK( N-1+I ) = S
      END IF
!
120    CONTINUE
!
!        If eigenvectors are desired, then apply saved rotations.
!
   IF( ICOMPZ.GT.0 ) THEN
      MM = L - M + 1
      CALL DLASR( 'R', 'V', 'F', N, MM, WORK( M ), WORK( N-1+M ), &
                      Z( 1, M ), LDZ )
   END IF
!
   D( L ) = D( L ) - P
   E( LM1 ) = G
   GO TO 90
!
!        Eigenvalue found.
!
130    CONTINUE
   D( L ) = P
!
   L = L - 1
   IF( L.GE.LEND ) &
          GO TO 90
   GO TO 140
!
END IF
!
!     Undo scaling if necessary
!
140 CONTINUE
IF( ISCALE.EQ.1 ) THEN
   CALL DLASCL( 'G', 0, 0, SSFMAX, ANORM, LENDSV-LSV+1, 1, &
                    D( LSV ), N, INFO )
   CALL DLASCL( 'G', 0, 0, SSFMAX, ANORM, LENDSV-LSV, 1, E( LSV ), &
                    N, INFO )
ELSE IF( ISCALE.EQ.2 ) THEN
   CALL DLASCL( 'G', 0, 0, SSFMIN, ANORM, LENDSV-LSV+1, 1, &
                    D( LSV ), N, INFO )
   CALL DLASCL( 'G', 0, 0, SSFMIN, ANORM, LENDSV-LSV, 1, E( LSV ), &
                    N, INFO )
END IF
!
!     Check for no convergence to an eigenvalue after a total
!     of N*MAXIT iterations.
!
IF( JTOT.LT.NMAXIT ) &
       GO TO 10
DO 150 I = 1, N - 1
   IF( E( I ).NE.ZERO ) &
          INFO = INFO + 1
150 CONTINUE
GO TO 190
!
!     Order eigenvalues and eigenvectors.
!
160 CONTINUE
IF( ICOMPZ.EQ.0 ) THEN
!
!        Use Quick Sort
!
   CALL DLASRT( 'I', N, D, INFO )
!
ELSE
!
!        Use Selection Sort to minimize swaps of eigenvectors
!
   DO 180 II = 2, N
      I = II - 1
      K = I
      P = D( I )
      DO 170 J = II, N
         IF( D( J ).LT.P ) THEN
            K = J
            P = D( J )
         END IF
170       CONTINUE
      IF( K.NE.I ) THEN
         D( K ) = D( I )
         D( I ) = P
         CALL DSWAP( N, Z( 1, I ), 1, Z( 1, K ), 1 )
      END IF
180    CONTINUE
END IF
!
190 CONTINUE
RETURN
!
!     End of DSTEQR
!
end subroutine dsteqr

! ===== End dsteqr.f90 =====


! ===== Begin dsterf.f90 =====

SUBROUTINE DSTERF( N, D, E, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
INTEGER            INFO, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   D( * ), E( * )
!     ..
!
!  Purpose
!  =======
!
!  DSTERF computes all eigenvalues of a symmetric tridiagonal matrix
!  using the Pal-Walker-Kahan variant of the QL or QR algorithm.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The order of the matrix.  N >= 0.
!
!  D       (input/output) DOUBLE PRECISION array, dimension (N)
!          On entry, the n diagonal elements of the tridiagonal matrix.
!          On exit, if INFO = 0, the eigenvalues in ascending order.
!
!  E       (input/output) DOUBLE PRECISION array, dimension (N-1)
!          On entry, the (n-1) subdiagonal elements of the tridiagonal
!          matrix.
!          On exit, E has been destroyed.
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  the algorithm failed to find all of the eigenvalues in
!                a total of 30*N iterations; if INFO = i, then i
!                elements of E have not converged to zero.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE, TWO, THREE
PARAMETER          ( ZERO = 0.0D0, ONE = 1.0D0, TWO = 2.0D0, &
                       THREE = 3.0D0 )
INTEGER            MAXIT
PARAMETER          ( MAXIT = 30 )
!     ..
!     .. Local Scalars ..
INTEGER            I, ISCALE, JTOT, L, L1, LEND, LENDSV, LSV, M, &
                       NMAXIT
DOUBLE PRECISION   ALPHA, ANORM, BB, C, EPS, EPS2, GAMMA, OLDC, &
                       OLDGAM, P, R, RT1, RT2, RTE, S, SAFMAX, SAFMIN, &
                       SIGMA, SSFMAX, SSFMIN
!     ..
!     .. External Functions ..
DOUBLE PRECISION   DLAMCH, DLANST, DLAPY2
EXTERNAL           DLAMCH, DLANST, DLAPY2
!     ..
!     .. External Subroutines ..
EXTERNAL           DLAE2, DLASCL, DLASRT, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, SIGN, SQRT
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
!
!     Quick return if possible
!
IF( N.LT.0 ) THEN
   INFO = -1
   CALL XERBLA( 'DSTERF', -INFO )
   RETURN
END IF
IF( N.LE.1 ) &
       RETURN
!
!     Determine the unit roundoff for this environment.
!
EPS = DLAMCH( 'E' )
EPS2 = EPS**2
SAFMIN = DLAMCH( 'S' )
SAFMAX = ONE / SAFMIN
SSFMAX = SQRT( SAFMAX ) / THREE
SSFMIN = SQRT( SAFMIN ) / EPS2
!
!     Compute the eigenvalues of the tridiagonal matrix.
!
NMAXIT = N*MAXIT
SIGMA = ZERO
JTOT = 0
!
!     Determine where the matrix splits and choose QL or QR iteration
!     for each block, according to whether top or bottom diagonal
!     element is smaller.
!
L1 = 1
!
10 CONTINUE
IF( L1.GT.N ) &
       GO TO 170
IF( L1.GT.1 ) &
       E( L1-1 ) = ZERO
DO 20 M = L1, N - 1
   IF( ABS( E( M ) ).LE.( SQRT( ABS( D( M ) ) )*SQRT( ABS( D( M+ &
           1 ) ) ) )*EPS ) THEN
      E( M ) = ZERO
      GO TO 30
   END IF
20 CONTINUE
M = N
!
30 CONTINUE
L = L1
LSV = L
LEND = M
LENDSV = LEND
L1 = M + 1
IF( LEND.EQ.L ) &
       GO TO 10
!
!     Scale submatrix in rows and columns L to LEND
!
ANORM = DLANST( 'I', LEND-L+1, D( L ), E( L ) )
ISCALE = 0
IF( ANORM.GT.SSFMAX ) THEN
   ISCALE = 1
   CALL DLASCL( 'G', 0, 0, ANORM, SSFMAX, LEND-L+1, 1, D( L ), N, &
                    INFO )
   CALL DLASCL( 'G', 0, 0, ANORM, SSFMAX, LEND-L, 1, E( L ), N, &
                    INFO )
ELSE IF( ANORM.LT.SSFMIN ) THEN
   ISCALE = 2
   CALL DLASCL( 'G', 0, 0, ANORM, SSFMIN, LEND-L+1, 1, D( L ), N, &
                    INFO )
   CALL DLASCL( 'G', 0, 0, ANORM, SSFMIN, LEND-L, 1, E( L ), N, &
                    INFO )
END IF
!
DO 40 I = L, LEND - 1
   E( I ) = E( I )**2
40 CONTINUE
!
!     Choose between QL and QR iteration
!
IF( ABS( D( LEND ) ).LT.ABS( D( L ) ) ) THEN
   LEND = LSV
   L = LENDSV
END IF
!
IF( LEND.GE.L ) THEN
!
!        QL Iteration
!
!        Look for small subdiagonal element.
!
50    CONTINUE
   IF( L.NE.LEND ) THEN
      DO 60 M = L, LEND - 1
         IF( ABS( E( M ) ).LE.EPS2*ABS( D( M )*D( M+1 ) ) ) &
                GO TO 70
60       CONTINUE
   END IF
   M = LEND
!
70    CONTINUE
   IF( M.LT.LEND ) &
          E( M ) = ZERO
   P = D( L )
   IF( M.EQ.L ) &
          GO TO 90
!
!        If remaining matrix is 2 by 2, use DLAE2 to compute its
!        eigenvalues.
!
   IF( M.EQ.L+1 ) THEN
      RTE = SQRT( E( L ) )
      CALL DLAE2( D( L ), RTE, D( L+1 ), RT1, RT2 )
      D( L ) = RT1
      D( L+1 ) = RT2
      E( L ) = ZERO
      L = L + 2
      IF( L.LE.LEND ) &
             GO TO 50
      GO TO 150
   END IF
!
   IF( JTOT.EQ.NMAXIT ) &
          GO TO 150
   JTOT = JTOT + 1
!
!        Form shift.
!
   RTE = SQRT( E( L ) )
   SIGMA = ( D( L+1 )-P ) / ( TWO*RTE )
   R = DLAPY2( SIGMA, ONE )
   SIGMA = P - ( RTE / ( SIGMA+SIGN( R, SIGMA ) ) )
!
   C = ONE
   S = ZERO
   GAMMA = D( M ) - SIGMA
   P = GAMMA*GAMMA
!
!        Inner loop
!
   DO 80 I = M - 1, L, -1
      BB = E( I )
      R = P + BB
      IF( I.NE.M-1 ) &
             E( I+1 ) = S*R
      OLDC = C
      C = P / R
      S = BB / R
      OLDGAM = GAMMA
      ALPHA = D( I )
      GAMMA = C*( ALPHA-SIGMA ) - S*OLDGAM
      D( I+1 ) = OLDGAM + ( ALPHA-GAMMA )
      IF( C.NE.ZERO ) THEN
         P = ( GAMMA*GAMMA ) / C
      ELSE
         P = OLDC*BB
      END IF
80    CONTINUE
!
   E( L ) = S*P
   D( L ) = SIGMA + GAMMA
   GO TO 50
!
!        Eigenvalue found.
!
90    CONTINUE
   D( L ) = P
!
   L = L + 1
   IF( L.LE.LEND ) &
          GO TO 50
   GO TO 150
!
ELSE
!
!        QR Iteration
!
!        Look for small superdiagonal element.
!
100    CONTINUE
   DO 110 M = L, LEND + 1, -1
      IF( ABS( E( M-1 ) ).LE.EPS2*ABS( D( M )*D( M-1 ) ) ) &
             GO TO 120
110    CONTINUE
   M = LEND
!
120    CONTINUE
   IF( M.GT.LEND ) &
          E( M-1 ) = ZERO
   P = D( L )
   IF( M.EQ.L ) &
          GO TO 140
!
!        If remaining matrix is 2 by 2, use DLAE2 to compute its
!        eigenvalues.
!
   IF( M.EQ.L-1 ) THEN
      RTE = SQRT( E( L-1 ) )
      CALL DLAE2( D( L ), RTE, D( L-1 ), RT1, RT2 )
      D( L ) = RT1
      D( L-1 ) = RT2
      E( L-1 ) = ZERO
      L = L - 2
      IF( L.GE.LEND ) &
             GO TO 100
      GO TO 150
   END IF
!
   IF( JTOT.EQ.NMAXIT ) &
          GO TO 150
   JTOT = JTOT + 1
!
!        Form shift.
!
   RTE = SQRT( E( L-1 ) )
   SIGMA = ( D( L-1 )-P ) / ( TWO*RTE )
   R = DLAPY2( SIGMA, ONE )
   SIGMA = P - ( RTE / ( SIGMA+SIGN( R, SIGMA ) ) )
!
   C = ONE
   S = ZERO
   GAMMA = D( M ) - SIGMA
   P = GAMMA*GAMMA
!
!        Inner loop
!
   DO 130 I = M, L - 1
      BB = E( I )
      R = P + BB
      IF( I.NE.M ) &
             E( I-1 ) = S*R
      OLDC = C
      C = P / R
      S = BB / R
      OLDGAM = GAMMA
      ALPHA = D( I+1 )
      GAMMA = C*( ALPHA-SIGMA ) - S*OLDGAM
      D( I ) = OLDGAM + ( ALPHA-GAMMA )
      IF( C.NE.ZERO ) THEN
         P = ( GAMMA*GAMMA ) / C
      ELSE
         P = OLDC*BB
      END IF
130    CONTINUE
!
   E( L-1 ) = S*P
   D( L ) = SIGMA + GAMMA
   GO TO 100
!
!        Eigenvalue found.
!
140    CONTINUE
   D( L ) = P
!
   L = L - 1
   IF( L.GE.LEND ) &
          GO TO 100
   GO TO 150
!
END IF
!
!     Undo scaling if necessary
!
150 CONTINUE
IF( ISCALE.EQ.1 ) &
       CALL DLASCL( 'G', 0, 0, SSFMAX, ANORM, LENDSV-LSV+1, 1, &
                    D( LSV ), N, INFO )
IF( ISCALE.EQ.2 ) &
       CALL DLASCL( 'G', 0, 0, SSFMIN, ANORM, LENDSV-LSV+1, 1, &
                    D( LSV ), N, INFO )
!
!     Check for no convergence to an eigenvalue after a total
!     of N*MAXIT iterations.
!
IF( JTOT.LT.NMAXIT ) &
       GO TO 10
DO 160 I = 1, N - 1
   IF( E( I ).NE.ZERO ) &
          INFO = INFO + 1
160 CONTINUE
GO TO 180
!
!     Sort eigenvalues in increasing order.
!
170 CONTINUE
CALL DLASRT( 'I', N, D, INFO )
!
180 CONTINUE
RETURN
!
!     End of DSTERF
!
end subroutine dsterf

! ===== End dsterf.f90 =====


! ===== Begin dtgevc.f90 =====

SUBROUTINE DTGEVC( SIDE, HOWMNY, SELECT, N, S, LDS, P, LDP, VL, &
                       LDVL, VR, LDVR, MM, M, WORK, INFO )
!
!  -- LAPACK routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
CHARACTER          HOWMNY, SIDE
INTEGER            INFO, LDP, LDS, LDVL, LDVR, M, MM, N
!     ..
!     .. Array Arguments ..
LOGICAL            SELECT( * )
DOUBLE PRECISION   P( LDP, * ), S( LDS, * ), VL( LDVL, * ), &
                       VR( LDVR, * ), WORK( * )
!     ..
!
!
!  Purpose
!  =======
!
!  DTGEVC computes some or all of the right and/or left eigenvectors of
!  a pair of real matrices (S,P), where S is a quasi-triangular matrix
!  and P is upper triangular.  Matrix pairs of this type are produced by
!  the generalized Schur factorization of a matrix pair (A,B):
!
!     A = Q*S*Z**T,  B = Q*P*Z**T
!
!  as computed by DGGHRD + DHGEQZ.
!
!  The right eigenvector x and the left eigenvector y of (S,P)
!  corresponding to an eigenvalue w are defined by:
!  
!     S*x = w*P*x,  (y**H)*S = w*(y**H)*P,
!  
!  where y**H denotes the conjugate tranpose of y.
!  The eigenvalues are not input to this routine, but are computed
!  directly from the diagonal blocks of S and P.
!  
!  This routine returns the matrices X and/or Y of right and left
!  eigenvectors of (S,P), or the products Z*X and/or Q*Y,
!  where Z and Q are input matrices.
!  If Q and Z are the orthogonal factors from the generalized Schur
!  factorization of a matrix pair (A,B), then Z*X and Q*Y
!  are the matrices of right and left eigenvectors of (A,B).
! 
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          = 'R': compute right eigenvectors only;
!          = 'L': compute left eigenvectors only;
!          = 'B': compute both right and left eigenvectors.
!
!  HOWMNY  (input) CHARACTER*1
!          = 'A': compute all right and/or left eigenvectors;
!          = 'B': compute all right and/or left eigenvectors,
!                 backtransformed by the matrices in VR and/or VL;
!          = 'S': compute selected right and/or left eigenvectors,
!                 specified by the logical array SELECT.
!
!  SELECT  (input) LOGICAL array, dimension (N)
!          If HOWMNY='S', SELECT specifies the eigenvectors to be
!          computed.  If w(j) is a real eigenvalue, the corresponding
!          real eigenvector is computed if SELECT(j) is .TRUE..
!          If w(j) and w(j+1) are the real and imaginary parts of a
!          complex eigenvalue, the corresponding complex eigenvector
!          is computed if either SELECT(j) or SELECT(j+1) is .TRUE.,
!          and on exit SELECT(j) is set to .TRUE. and SELECT(j+1) is
!          set to .FALSE..
!          Not referenced if HOWMNY = 'A' or 'B'.
!
!  N       (input) INTEGER
!          The order of the matrices S and P.  N >= 0.
!
!  S       (input) DOUBLE PRECISION array, dimension (LDS,N)
!          The upper quasi-triangular matrix S from a generalized Schur
!          factorization, as computed by DHGEQZ.
!
!  LDS     (input) INTEGER
!          The leading dimension of array S.  LDS >= max(1,N).
!
!  P       (input) DOUBLE PRECISION array, dimension (LDP,N)
!          The upper triangular matrix P from a generalized Schur
!          factorization, as computed by DHGEQZ.
!          2-by-2 diagonal blocks of P corresponding to 2-by-2 blocks
!          of S must be in positive diagonal form.
!
!  LDP     (input) INTEGER
!          The leading dimension of array P.  LDP >= max(1,N).
!
!  VL      (input/output) DOUBLE PRECISION array, dimension (LDVL,MM)
!          On entry, if SIDE = 'L' or 'B' and HOWMNY = 'B', VL must
!          contain an N-by-N matrix Q (usually the orthogonal matrix Q
!          of left Schur vectors returned by DHGEQZ).
!          On exit, if SIDE = 'L' or 'B', VL contains:
!          if HOWMNY = 'A', the matrix Y of left eigenvectors of (S,P);
!          if HOWMNY = 'B', the matrix Q*Y;
!          if HOWMNY = 'S', the left eigenvectors of (S,P) specified by
!                      SELECT, stored consecutively in the columns of
!                      VL, in the same order as their eigenvalues.
!
!          A complex eigenvector corresponding to a complex eigenvalue
!          is stored in two consecutive columns, the first holding the
!          real part, and the second the imaginary part.
!
!          Not referenced if SIDE = 'R'.
!
!  LDVL    (input) INTEGER
!          The leading dimension of array VL.  LDVL >= 1, and if
!          SIDE = 'L' or 'B', LDVL >= N.
!
!  VR      (input/output) DOUBLE PRECISION array, dimension (LDVR,MM)
!          On entry, if SIDE = 'R' or 'B' and HOWMNY = 'B', VR must
!          contain an N-by-N matrix Z (usually the orthogonal matrix Z
!          of right Schur vectors returned by DHGEQZ).
!
!          On exit, if SIDE = 'R' or 'B', VR contains:
!          if HOWMNY = 'A', the matrix X of right eigenvectors of (S,P);
!          if HOWMNY = 'B' or 'b', the matrix Z*X;
!          if HOWMNY = 'S' or 's', the right eigenvectors of (S,P)
!                      specified by SELECT, stored consecutively in the
!                      columns of VR, in the same order as their
!                      eigenvalues.
!
!          A complex eigenvector corresponding to a complex eigenvalue
!          is stored in two consecutive columns, the first holding the
!          real part and the second the imaginary part.
!          
!          Not referenced if SIDE = 'L'.
!
!  LDVR    (input) INTEGER
!          The leading dimension of the array VR.  LDVR >= 1, and if
!          SIDE = 'R' or 'B', LDVR >= N.
!
!  MM      (input) INTEGER
!          The number of columns in the arrays VL and/or VR. MM >= M.
!
!  M       (output) INTEGER
!          The number of columns in the arrays VL and/or VR actually
!          used to store the eigenvectors.  If HOWMNY = 'A' or 'B', M
!          is set to N.  Each selected real eigenvector occupies one
!          column and each selected complex eigenvector occupies two
!          columns.
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (6*N)
!
!  INFO    (output) INTEGER
!          = 0:  successful exit.
!          < 0:  if INFO = -i, the i-th argument had an illegal value.
!          > 0:  the 2-by-2 block (INFO:INFO+1) does not have a complex
!                eigenvalue.
!
!  Further Details
!  ===============
!
!  Allocation of workspace:
!  ---------- -- ---------
!
!     WORK( j ) = 1-norm of j-th column of A, above the diagonal
!     WORK( N+j ) = 1-norm of j-th column of B, above the diagonal
!     WORK( 2*N+1:3*N ) = real part of eigenvector
!     WORK( 3*N+1:4*N ) = imaginary part of eigenvector
!     WORK( 4*N+1:5*N ) = real part of back-transformed eigenvector
!     WORK( 5*N+1:6*N ) = imaginary part of back-transformed eigenvector
!
!  Rowwise vs. columnwise solution methods:
!  ------- --  ---------- -------- -------
!
!  Finding a generalized eigenvector consists basically of solving the
!  singular triangular system
!
!   (A - w B) x = 0     (for right) or:   (A - w B)**H y = 0  (for left)
!
!  Consider finding the i-th right eigenvector (assume all eigenvalues
!  are real). The equation to be solved is:
!       n                   i
!  0 = sum  C(j,k) v(k)  = sum  C(j,k) v(k)     for j = i,. . .,1
!      k=j                 k=j
!
!  where  C = (A - w B)  (The components v(i+1:n) are 0.)
!
!  The "rowwise" method is:
!
!  (1)  v(i) := 1
!  for j = i-1,. . .,1:
!                          i
!      (2) compute  s = - sum C(j,k) v(k)   and
!                        k=j+1
!
!      (3) v(j) := s / C(j,j)
!
!  Step 2 is sometimes called the "dot product" step, since it is an
!  inner product between the j-th row and the portion of the eigenvector
!  that has been computed so far.
!
!  The "columnwise" method consists basically in doing the sums
!  for all the rows in parallel.  As each v(j) is computed, the
!  contribution of v(j) times the j-th column of C is added to the
!  partial sums.  Since FORTRAN arrays are stored columnwise, this has
!  the advantage that at each step, the elements of C that are accessed
!  are adjacent to one another, whereas with the rowwise method, the
!  elements accessed at a step are spaced LDS (and LDP) words apart.
!
!  When finding left eigenvectors, the matrix in question is the
!  transpose of the one in storage, so the rowwise method then
!  actually accesses columns of A and B at each step, and so is the
!  preferred method.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE, SAFETY
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0, &
                       SAFETY = 1.0D+2 )
!     ..
!     .. Local Scalars ..
LOGICAL            COMPL, COMPR, IL2BY2, ILABAD, ILALL, ILBACK, &
                       ILBBAD, ILCOMP, ILCPLX, LSA, LSB
INTEGER            I, IBEG, IEIG, IEND, IHWMNY, IINFO, IM, ISIDE, &
                       J, JA, JC, JE, JR, JW, NA, NW
DOUBLE PRECISION   ACOEF, ACOEFA, ANORM, ASCALE, BCOEFA, BCOEFI, &
                       BCOEFR, BIG, BIGNUM, BNORM, BSCALE, CIM2A, &
                       CIM2B, CIMAGA, CIMAGB, CRE2A, CRE2B, CREALA, &
                       CREALB, DMIN, SAFMIN, SALFAR, SBETA, SCALE, &
                       SMALL, TEMP, TEMP2, TEMP2I, TEMP2R, ULP, XMAX, &
                       XSCALE
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   BDIAG( 2 ), SUM( 2, 2 ), SUMS( 2, 2 ), &
                       SUMP( 2, 2 )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
DOUBLE PRECISION   DLAMCH
EXTERNAL           LSAME, DLAMCH
!     ..
!     .. External Subroutines ..
EXTERNAL           DGEMV, DLABAD, DLACPY, DLAG2, DLALN2, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Decode and Test the input parameters
!
IF( LSAME( HOWMNY, 'A' ) ) THEN
   IHWMNY = 1
   ILALL = .TRUE.
   ILBACK = .FALSE.
ELSE IF( LSAME( HOWMNY, 'S' ) ) THEN
   IHWMNY = 2
   ILALL = .FALSE.
   ILBACK = .FALSE.
ELSE IF( LSAME( HOWMNY, 'B' ) ) THEN
   IHWMNY = 3
   ILALL = .TRUE.
   ILBACK = .TRUE.
ELSE
   IHWMNY = -1
   ILALL = .TRUE.
END IF
!
IF( LSAME( SIDE, 'R' ) ) THEN
   ISIDE = 1
   COMPL = .FALSE.
   COMPR = .TRUE.
ELSE IF( LSAME( SIDE, 'L' ) ) THEN
   ISIDE = 2
   COMPL = .TRUE.
   COMPR = .FALSE.
ELSE IF( LSAME( SIDE, 'B' ) ) THEN
   ISIDE = 3
   COMPL = .TRUE.
   COMPR = .TRUE.
ELSE
   ISIDE = -1
END IF
!
INFO = 0
IF( ISIDE.LT.0 ) THEN
   INFO = -1
ELSE IF( IHWMNY.LT.0 ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( LDS.LT.MAX( 1, N ) ) THEN
   INFO = -6
ELSE IF( LDP.LT.MAX( 1, N ) ) THEN
   INFO = -8
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTGEVC', -INFO )
   RETURN
END IF
!
!     Count the number of eigenvectors to be computed
!
IF( .NOT.ILALL ) THEN
   IM = 0
   ILCPLX = .FALSE.
   DO 10 J = 1, N
      IF( ILCPLX ) THEN
         ILCPLX = .FALSE.
         GO TO 10
      END IF
      IF( J.LT.N ) THEN
         IF( S( J+1, J ).NE.ZERO ) &
                ILCPLX = .TRUE.
      END IF
      IF( ILCPLX ) THEN
         IF( SELECT( J ) .OR. SELECT( J+1 ) ) &
                IM = IM + 2
      ELSE
         IF( SELECT( J ) ) &
                IM = IM + 1
      END IF
10    CONTINUE
ELSE
   IM = N
END IF
!
!     Check 2-by-2 diagonal blocks of A, B
!
ILABAD = .FALSE.
ILBBAD = .FALSE.
DO 20 J = 1, N - 1
   IF( S( J+1, J ).NE.ZERO ) THEN
      IF( P( J, J ).EQ.ZERO .OR. P( J+1, J+1 ).EQ.ZERO .OR. &
              P( J, J+1 ).NE.ZERO )ILBBAD = .TRUE.
      IF( J.LT.N-1 ) THEN
         IF( S( J+2, J+1 ).NE.ZERO ) &
                ILABAD = .TRUE.
      END IF
   END IF
20 CONTINUE
!
IF( ILABAD ) THEN
   INFO = -5
ELSE IF( ILBBAD ) THEN
   INFO = -7
ELSE IF( COMPL .AND. LDVL.LT.N .OR. LDVL.LT.1 ) THEN
   INFO = -10
ELSE IF( COMPR .AND. LDVR.LT.N .OR. LDVR.LT.1 ) THEN
   INFO = -12
ELSE IF( MM.LT.IM ) THEN
   INFO = -13
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTGEVC', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
M = IM
IF( N.EQ.0 ) &
       RETURN
!
!     Machine Constants
!
SAFMIN = DLAMCH( 'Safe minimum' )
BIG = ONE / SAFMIN
CALL DLABAD( SAFMIN, BIG )
ULP = DLAMCH( 'Epsilon' )*DLAMCH( 'Base' )
SMALL = SAFMIN*N / ULP
BIG = ONE / SMALL
BIGNUM = ONE / ( SAFMIN*N )
!
!     Compute the 1-norm of each column of the strictly upper triangular
!     part (i.e., excluding all elements belonging to the diagonal
!     blocks) of A and B to check for possible overflow in the
!     triangular solver.
!
ANORM = ABS( S( 1, 1 ) )
IF( N.GT.1 ) &
       ANORM = ANORM + ABS( S( 2, 1 ) )
BNORM = ABS( P( 1, 1 ) )
WORK( 1 ) = ZERO
WORK( N+1 ) = ZERO
!
DO 50 J = 2, N
   TEMP = ZERO
   TEMP2 = ZERO
   IF( S( J, J-1 ).EQ.ZERO ) THEN
      IEND = J - 1
   ELSE
      IEND = J - 2
   END IF
   DO 30 I = 1, IEND
      TEMP = TEMP + ABS( S( I, J ) )
      TEMP2 = TEMP2 + ABS( P( I, J ) )
30    CONTINUE
   WORK( J ) = TEMP
   WORK( N+J ) = TEMP2
   DO 40 I = IEND + 1, MIN( J+1, N )
      TEMP = TEMP + ABS( S( I, J ) )
      TEMP2 = TEMP2 + ABS( P( I, J ) )
40    CONTINUE
   ANORM = MAX( ANORM, TEMP )
   BNORM = MAX( BNORM, TEMP2 )
50 CONTINUE
!
ASCALE = ONE / MAX( ANORM, SAFMIN )
BSCALE = ONE / MAX( BNORM, SAFMIN )
!
!     Left eigenvectors
!
IF( COMPL ) THEN
   IEIG = 0
!
!        Main loop over eigenvalues
!
   ILCPLX = .FALSE.
   DO 220 JE = 1, N
!
!           Skip this iteration if (a) HOWMNY='S' and SELECT=.FALSE., or
!           (b) this would be the second of a complex pair.
!           Check for complex eigenvalue, so as to be sure of which
!           entry(-ies) of SELECT to look at.
!
      IF( ILCPLX ) THEN
         ILCPLX = .FALSE.
         GO TO 220
      END IF
      NW = 1
      IF( JE.LT.N ) THEN
         IF( S( JE+1, JE ).NE.ZERO ) THEN
            ILCPLX = .TRUE.
            NW = 2
         END IF
      END IF
      IF( ILALL ) THEN
         ILCOMP = .TRUE.
      ELSE IF( ILCPLX ) THEN
         ILCOMP = SELECT( JE ) .OR. SELECT( JE+1 )
      ELSE
         ILCOMP = SELECT( JE )
      END IF
      IF( .NOT.ILCOMP ) &
             GO TO 220
!
!           Decide if (a) singular pencil, (b) real eigenvalue, or
!           (c) complex eigenvalue.
!
      IF( .NOT.ILCPLX ) THEN
         IF( ABS( S( JE, JE ) ).LE.SAFMIN .AND. &
                 ABS( P( JE, JE ) ).LE.SAFMIN ) THEN
!
!                 Singular matrix pencil -- return unit eigenvector
!
            IEIG = IEIG + 1
            DO 60 JR = 1, N
               VL( JR, IEIG ) = ZERO
60             CONTINUE
            VL( IEIG, IEIG ) = ONE
            GO TO 220
         END IF
      END IF
!
!           Clear vector
!
      DO 70 JR = 1, NW*N
         WORK( 2*N+JR ) = ZERO
70       CONTINUE
!                                                 T
!           Compute coefficients in  ( a A - b B )  y = 0
!              a  is  ACOEF
!              b  is  BCOEFR + i*BCOEFI
!
      IF( .NOT.ILCPLX ) THEN
!
!              Real eigenvalue
!
         TEMP = ONE / MAX( ABS( S( JE, JE ) )*ASCALE, &
                    ABS( P( JE, JE ) )*BSCALE, SAFMIN )
         SALFAR = ( TEMP*S( JE, JE ) )*ASCALE
         SBETA = ( TEMP*P( JE, JE ) )*BSCALE
         ACOEF = SBETA*ASCALE
         BCOEFR = SALFAR*BSCALE
         BCOEFI = ZERO
!
!              Scale to avoid underflow
!
         SCALE = ONE
         LSA = ABS( SBETA ).GE.SAFMIN .AND. ABS( ACOEF ).LT.SMALL
         LSB = ABS( SALFAR ).GE.SAFMIN .AND. ABS( BCOEFR ).LT. &
                   SMALL
         IF( LSA ) &
                SCALE = ( SMALL / ABS( SBETA ) )*MIN( ANORM, BIG )
         IF( LSB ) &
                SCALE = MAX( SCALE, ( SMALL / ABS( SALFAR ) )* &
                        MIN( BNORM, BIG ) )
         IF( LSA .OR. LSB ) THEN
            SCALE = MIN( SCALE, ONE / &
                        ( SAFMIN*MAX( ONE, ABS( ACOEF ), &
                        ABS( BCOEFR ) ) ) )
            IF( LSA ) THEN
               ACOEF = ASCALE*( SCALE*SBETA )
            ELSE
               ACOEF = SCALE*ACOEF
            END IF
            IF( LSB ) THEN
               BCOEFR = BSCALE*( SCALE*SALFAR )
            ELSE
               BCOEFR = SCALE*BCOEFR
            END IF
         END IF
         ACOEFA = ABS( ACOEF )
         BCOEFA = ABS( BCOEFR )
!
!              First component is 1
!
         WORK( 2*N+JE ) = ONE
         XMAX = ONE
      ELSE
!
!              Complex eigenvalue
!
         CALL DLAG2( S( JE, JE ), LDS, P( JE, JE ), LDP, &
                         SAFMIN*SAFETY, ACOEF, TEMP, BCOEFR, TEMP2, &
                         BCOEFI )
         BCOEFI = -BCOEFI
         IF( BCOEFI.EQ.ZERO ) THEN
            INFO = JE
            RETURN
         END IF
!
!              Scale to avoid over/underflow
!
         ACOEFA = ABS( ACOEF )
         BCOEFA = ABS( BCOEFR ) + ABS( BCOEFI )
         SCALE = ONE
         IF( ACOEFA*ULP.LT.SAFMIN .AND. ACOEFA.GE.SAFMIN ) &
                SCALE = ( SAFMIN / ULP ) / ACOEFA
         IF( BCOEFA*ULP.LT.SAFMIN .AND. BCOEFA.GE.SAFMIN ) &
                SCALE = MAX( SCALE, ( SAFMIN / ULP ) / BCOEFA )
         IF( SAFMIN*ACOEFA.GT.ASCALE ) &
                SCALE = ASCALE / ( SAFMIN*ACOEFA )
         IF( SAFMIN*BCOEFA.GT.BSCALE ) &
                SCALE = MIN( SCALE, BSCALE / ( SAFMIN*BCOEFA ) )
         IF( SCALE.NE.ONE ) THEN
            ACOEF = SCALE*ACOEF
            ACOEFA = ABS( ACOEF )
            BCOEFR = SCALE*BCOEFR
            BCOEFI = SCALE*BCOEFI
            BCOEFA = ABS( BCOEFR ) + ABS( BCOEFI )
         END IF
!
!              Compute first two components of eigenvector
!
         TEMP = ACOEF*S( JE+1, JE )
         TEMP2R = ACOEF*S( JE, JE ) - BCOEFR*P( JE, JE )
         TEMP2I = -BCOEFI*P( JE, JE )
         IF( ABS( TEMP ).GT.ABS( TEMP2R )+ABS( TEMP2I ) ) THEN
            WORK( 2*N+JE ) = ONE
            WORK( 3*N+JE ) = ZERO
            WORK( 2*N+JE+1 ) = -TEMP2R / TEMP
            WORK( 3*N+JE+1 ) = -TEMP2I / TEMP
         ELSE
            WORK( 2*N+JE+1 ) = ONE
            WORK( 3*N+JE+1 ) = ZERO
            TEMP = ACOEF*S( JE, JE+1 )
            WORK( 2*N+JE ) = ( BCOEFR*P( JE+1, JE+1 )-ACOEF* &
                                 S( JE+1, JE+1 ) ) / TEMP
            WORK( 3*N+JE ) = BCOEFI*P( JE+1, JE+1 ) / TEMP
         END IF
         XMAX = MAX( ABS( WORK( 2*N+JE ) )+ABS( WORK( 3*N+JE ) ), &
                    ABS( WORK( 2*N+JE+1 ) )+ABS( WORK( 3*N+JE+1 ) ) )
      END IF
!
      DMIN = MAX( ULP*ACOEFA*ANORM, ULP*BCOEFA*BNORM, SAFMIN )
!
!                                           T
!           Triangular solve of  (a A - b B)  y = 0
!
!                                   T
!           (rowwise in  (a A - b B) , or columnwise in (a A - b B) )
!
      IL2BY2 = .FALSE.
!
      DO 160 J = JE + NW, N
         IF( IL2BY2 ) THEN
            IL2BY2 = .FALSE.
            GO TO 160
         END IF
!
         NA = 1
         BDIAG( 1 ) = P( J, J )
         IF( J.LT.N ) THEN
            IF( S( J+1, J ).NE.ZERO ) THEN
               IL2BY2 = .TRUE.
               BDIAG( 2 ) = P( J+1, J+1 )
               NA = 2
            END IF
         END IF
!
!              Check whether scaling is necessary for dot products
!
         XSCALE = ONE / MAX( ONE, XMAX )
         TEMP = MAX( WORK( J ), WORK( N+J ), &
                    ACOEFA*WORK( J )+BCOEFA*WORK( N+J ) )
         IF( IL2BY2 ) &
                TEMP = MAX( TEMP, WORK( J+1 ), WORK( N+J+1 ), &
                       ACOEFA*WORK( J+1 )+BCOEFA*WORK( N+J+1 ) )
         IF( TEMP.GT.BIGNUM*XSCALE ) THEN
            DO 90 JW = 0, NW - 1
               DO 80 JR = JE, J - 1
                  WORK( ( JW+2 )*N+JR ) = XSCALE* &
                         WORK( ( JW+2 )*N+JR )
80                CONTINUE
90             CONTINUE
            XMAX = XMAX*XSCALE
         END IF
!
!              Compute dot products
!
!                    j-1
!              SUM = sum  conjg( a*S(k,j) - b*P(k,j) )*x(k)
!                    k=je
!
!              To reduce the op count, this is done as
!
!              _        j-1                  _        j-1
!              a*conjg( sum  S(k,j)*x(k) ) - b*conjg( sum  P(k,j)*x(k) )
!                       k=je                          k=je
!
!              which may cause underflow problems if A or B are close
!              to underflow.  (E.g., less than SMALL.)
!
!
!              A series of compiler directives to defeat vectorization
!              for the next loop
!
!!$PL$ CMCHAR=' '
!!DIR$          NEXTSCALAR
!!$DIR          SCALAR
!!DIR$          NEXT SCALAR
!!VD$L          NOVECTOR
!!DEC$          NOVECTOR
!!VD$           NOVECTOR
!!VDIR          NOVECTOR
!!VOCL          LOOP,SCALAR
!!IBM           PREFER SCALAR
!!$PL$ CMCHAR='*'
!!
         DO 120 JW = 1, NW
!!
!!$PL$ CMCHAR=' '
!!DIR$             NEXTSCALAR
!!$DIR             SCALAR
!!DIR$             NEXT SCALAR
!!VD$L             NOVECTOR
!!DEC$             NOVECTOR
!!VD$              NOVECTOR
!!VDIR             NOVECTOR
!!VOCL             LOOP,SCALAR
!!IBM              PREFER SCALAR
!!$PL$ CMCHAR='*'
!!
            DO 110 JA = 1, NA
               SUMS( JA, JW ) = ZERO
               SUMP( JA, JW ) = ZERO
!
               DO 100 JR = JE, J - 1
                  SUMS( JA, JW ) = SUMS( JA, JW ) + &
                                       S( JR, J+JA-1 )* &
                                       WORK( ( JW+1 )*N+JR )
                  SUMP( JA, JW ) = SUMP( JA, JW ) + &
                                       P( JR, J+JA-1 )* &
                                       WORK( ( JW+1 )*N+JR )
100                CONTINUE
110             CONTINUE
120          CONTINUE
!!
!!$PL$ CMCHAR=' '
!!DIR$          NEXTSCALAR
!!$DIR          SCALAR
!!DIR$          NEXT SCALAR
!!VD$L          NOVECTOR
!!DEC$          NOVECTOR
!!VD$           NOVECTOR
!!VDIR          NOVECTOR
!!VOCL          LOOP,SCALAR
!!IBM           PREFER SCALAR
!!$PL$ CMCHAR='*'
!!
         DO 130 JA = 1, NA
            IF( ILCPLX ) THEN
               SUM( JA, 1 ) = -ACOEF*SUMS( JA, 1 ) + &
                                  BCOEFR*SUMP( JA, 1 ) - &
                                  BCOEFI*SUMP( JA, 2 )
               SUM( JA, 2 ) = -ACOEF*SUMS( JA, 2 ) + &
                                  BCOEFR*SUMP( JA, 2 ) + &
                                  BCOEFI*SUMP( JA, 1 )
            ELSE
               SUM( JA, 1 ) = -ACOEF*SUMS( JA, 1 ) + &
                                  BCOEFR*SUMP( JA, 1 )
            END IF
130          CONTINUE
!
!                                  T
!              Solve  ( a A - b B )  y = SUM(,)
!              with scaling and perturbation of the denominator
!
         CALL DLALN2( .TRUE., NA, NW, DMIN, ACOEF, S( J, J ), LDS, &
                          BDIAG( 1 ), BDIAG( 2 ), SUM, 2, BCOEFR, &
                          BCOEFI, WORK( 2*N+J ), N, SCALE, TEMP, &
                          IINFO )
         IF( SCALE.LT.ONE ) THEN
            DO 150 JW = 0, NW - 1
               DO 140 JR = JE, J - 1
                  WORK( ( JW+2 )*N+JR ) = SCALE* &
                         WORK( ( JW+2 )*N+JR )
140                CONTINUE
150             CONTINUE
            XMAX = SCALE*XMAX
         END IF
         XMAX = MAX( XMAX, TEMP )
160       CONTINUE
!
!           Copy eigenvector to VL, back transforming if
!           HOWMNY='B'.
!
      IEIG = IEIG + 1
      IF( ILBACK ) THEN
         DO 170 JW = 0, NW - 1
            CALL DGEMV( 'N', N, N+1-JE, ONE, VL( 1, JE ), LDVL, &
                            WORK( ( JW+2 )*N+JE ), 1, ZERO, &
                            WORK( ( JW+4 )*N+1 ), 1 )
170          CONTINUE
         CALL DLACPY( ' ', N, NW, WORK( 4*N+1 ), N, VL( 1, JE ), &
                          LDVL )
         IBEG = 1
      ELSE
         CALL DLACPY( ' ', N, NW, WORK( 2*N+1 ), N, VL( 1, IEIG ), &
                          LDVL )
         IBEG = JE
      END IF
!
!           Scale eigenvector
!
      XMAX = ZERO
      IF( ILCPLX ) THEN
         DO 180 J = IBEG, N
            XMAX = MAX( XMAX, ABS( VL( J, IEIG ) )+ &
                       ABS( VL( J, IEIG+1 ) ) )
180          CONTINUE
      ELSE
         DO 190 J = IBEG, N
            XMAX = MAX( XMAX, ABS( VL( J, IEIG ) ) )
190          CONTINUE
      END IF
!
      IF( XMAX.GT.SAFMIN ) THEN
         XSCALE = ONE / XMAX
!
         DO 210 JW = 0, NW - 1
            DO 200 JR = IBEG, N
               VL( JR, IEIG+JW ) = XSCALE*VL( JR, IEIG+JW )
200             CONTINUE
210          CONTINUE
      END IF
      IEIG = IEIG + NW - 1
!
220    CONTINUE
END IF
!
!     Right eigenvectors
!
IF( COMPR ) THEN
   IEIG = IM + 1
!
!        Main loop over eigenvalues
!
   ILCPLX = .FALSE.
   DO 500 JE = N, 1, -1
!
!           Skip this iteration if (a) HOWMNY='S' and SELECT=.FALSE., or
!           (b) this would be the second of a complex pair.
!           Check for complex eigenvalue, so as to be sure of which
!           entry(-ies) of SELECT to look at -- if complex, SELECT(JE)
!           or SELECT(JE-1).
!           If this is a complex pair, the 2-by-2 diagonal block
!           corresponding to the eigenvalue is in rows/columns JE-1:JE
!
      IF( ILCPLX ) THEN
         ILCPLX = .FALSE.
         GO TO 500
      END IF
      NW = 1
      IF( JE.GT.1 ) THEN
         IF( S( JE, JE-1 ).NE.ZERO ) THEN
            ILCPLX = .TRUE.
            NW = 2
         END IF
      END IF
      IF( ILALL ) THEN
         ILCOMP = .TRUE.
      ELSE IF( ILCPLX ) THEN
         ILCOMP = SELECT( JE ) .OR. SELECT( JE-1 )
      ELSE
         ILCOMP = SELECT( JE )
      END IF
      IF( .NOT.ILCOMP ) &
             GO TO 500
!
!           Decide if (a) singular pencil, (b) real eigenvalue, or
!           (c) complex eigenvalue.
!
      IF( .NOT.ILCPLX ) THEN
         IF( ABS( S( JE, JE ) ).LE.SAFMIN .AND. &
                 ABS( P( JE, JE ) ).LE.SAFMIN ) THEN
!
!                 Singular matrix pencil -- unit eigenvector
!
            IEIG = IEIG - 1
            DO 230 JR = 1, N
               VR( JR, IEIG ) = ZERO
230             CONTINUE
            VR( IEIG, IEIG ) = ONE
            GO TO 500
         END IF
      END IF
!
!           Clear vector
!
      DO 250 JW = 0, NW - 1
         DO 240 JR = 1, N
            WORK( ( JW+2 )*N+JR ) = ZERO
240          CONTINUE
250       CONTINUE
!
!           Compute coefficients in  ( a A - b B ) x = 0
!              a  is  ACOEF
!              b  is  BCOEFR + i*BCOEFI
!
      IF( .NOT.ILCPLX ) THEN
!
!              Real eigenvalue
!
         TEMP = ONE / MAX( ABS( S( JE, JE ) )*ASCALE, &
                    ABS( P( JE, JE ) )*BSCALE, SAFMIN )
         SALFAR = ( TEMP*S( JE, JE ) )*ASCALE
         SBETA = ( TEMP*P( JE, JE ) )*BSCALE
         ACOEF = SBETA*ASCALE
         BCOEFR = SALFAR*BSCALE
         BCOEFI = ZERO
!
!              Scale to avoid underflow
!
         SCALE = ONE
         LSA = ABS( SBETA ).GE.SAFMIN .AND. ABS( ACOEF ).LT.SMALL
         LSB = ABS( SALFAR ).GE.SAFMIN .AND. ABS( BCOEFR ).LT. &
                   SMALL
         IF( LSA ) &
                SCALE = ( SMALL / ABS( SBETA ) )*MIN( ANORM, BIG )
         IF( LSB ) &
                SCALE = MAX( SCALE, ( SMALL / ABS( SALFAR ) )* &
                        MIN( BNORM, BIG ) )
         IF( LSA .OR. LSB ) THEN
            SCALE = MIN( SCALE, ONE / &
                        ( SAFMIN*MAX( ONE, ABS( ACOEF ), &
                        ABS( BCOEFR ) ) ) )
            IF( LSA ) THEN
               ACOEF = ASCALE*( SCALE*SBETA )
            ELSE
               ACOEF = SCALE*ACOEF
            END IF
            IF( LSB ) THEN
               BCOEFR = BSCALE*( SCALE*SALFAR )
            ELSE
               BCOEFR = SCALE*BCOEFR
            END IF
         END IF
         ACOEFA = ABS( ACOEF )
         BCOEFA = ABS( BCOEFR )
!
!              First component is 1
!
         WORK( 2*N+JE ) = ONE
         XMAX = ONE
!
!              Compute contribution from column JE of A and B to sum
!              (See "Further Details", above.)
!
         DO 260 JR = 1, JE - 1
            WORK( 2*N+JR ) = BCOEFR*P( JR, JE ) - &
                                 ACOEF*S( JR, JE )
260          CONTINUE
      ELSE
!
!              Complex eigenvalue
!
         CALL DLAG2( S( JE-1, JE-1 ), LDS, P( JE-1, JE-1 ), LDP, &
                         SAFMIN*SAFETY, ACOEF, TEMP, BCOEFR, TEMP2, &
                         BCOEFI )
         IF( BCOEFI.EQ.ZERO ) THEN
            INFO = JE - 1
            RETURN
         END IF
!
!              Scale to avoid over/underflow
!
         ACOEFA = ABS( ACOEF )
         BCOEFA = ABS( BCOEFR ) + ABS( BCOEFI )
         SCALE = ONE
         IF( ACOEFA*ULP.LT.SAFMIN .AND. ACOEFA.GE.SAFMIN ) &
                SCALE = ( SAFMIN / ULP ) / ACOEFA
         IF( BCOEFA*ULP.LT.SAFMIN .AND. BCOEFA.GE.SAFMIN ) &
                SCALE = MAX( SCALE, ( SAFMIN / ULP ) / BCOEFA )
         IF( SAFMIN*ACOEFA.GT.ASCALE ) &
                SCALE = ASCALE / ( SAFMIN*ACOEFA )
         IF( SAFMIN*BCOEFA.GT.BSCALE ) &
                SCALE = MIN( SCALE, BSCALE / ( SAFMIN*BCOEFA ) )
         IF( SCALE.NE.ONE ) THEN
            ACOEF = SCALE*ACOEF
            ACOEFA = ABS( ACOEF )
            BCOEFR = SCALE*BCOEFR
            BCOEFI = SCALE*BCOEFI
            BCOEFA = ABS( BCOEFR ) + ABS( BCOEFI )
         END IF
!
!              Compute first two components of eigenvector
!              and contribution to sums
!
         TEMP = ACOEF*S( JE, JE-1 )
         TEMP2R = ACOEF*S( JE, JE ) - BCOEFR*P( JE, JE )
         TEMP2I = -BCOEFI*P( JE, JE )
         IF( ABS( TEMP ).GE.ABS( TEMP2R )+ABS( TEMP2I ) ) THEN
            WORK( 2*N+JE ) = ONE
            WORK( 3*N+JE ) = ZERO
            WORK( 2*N+JE-1 ) = -TEMP2R / TEMP
            WORK( 3*N+JE-1 ) = -TEMP2I / TEMP
         ELSE
            WORK( 2*N+JE-1 ) = ONE
            WORK( 3*N+JE-1 ) = ZERO
            TEMP = ACOEF*S( JE-1, JE )
            WORK( 2*N+JE ) = ( BCOEFR*P( JE-1, JE-1 )-ACOEF* &
                                 S( JE-1, JE-1 ) ) / TEMP
            WORK( 3*N+JE ) = BCOEFI*P( JE-1, JE-1 ) / TEMP
         END IF
!
         XMAX = MAX( ABS( WORK( 2*N+JE ) )+ABS( WORK( 3*N+JE ) ), &
                    ABS( WORK( 2*N+JE-1 ) )+ABS( WORK( 3*N+JE-1 ) ) )
!
!              Compute contribution from columns JE and JE-1
!              of A and B to the sums.
!
         CREALA = ACOEF*WORK( 2*N+JE-1 )
         CIMAGA = ACOEF*WORK( 3*N+JE-1 )
         CREALB = BCOEFR*WORK( 2*N+JE-1 ) - &
                      BCOEFI*WORK( 3*N+JE-1 )
         CIMAGB = BCOEFI*WORK( 2*N+JE-1 ) + &
                      BCOEFR*WORK( 3*N+JE-1 )
         CRE2A = ACOEF*WORK( 2*N+JE )
         CIM2A = ACOEF*WORK( 3*N+JE )
         CRE2B = BCOEFR*WORK( 2*N+JE ) - BCOEFI*WORK( 3*N+JE )
         CIM2B = BCOEFI*WORK( 2*N+JE ) + BCOEFR*WORK( 3*N+JE )
         DO 270 JR = 1, JE - 2
            WORK( 2*N+JR ) = -CREALA*S( JR, JE-1 ) + &
                                 CREALB*P( JR, JE-1 ) - &
                                 CRE2A*S( JR, JE ) + CRE2B*P( JR, JE )
            WORK( 3*N+JR ) = -CIMAGA*S( JR, JE-1 ) + &
                                 CIMAGB*P( JR, JE-1 ) - &
                                 CIM2A*S( JR, JE ) + CIM2B*P( JR, JE )
270          CONTINUE
      END IF
!
      DMIN = MAX( ULP*ACOEFA*ANORM, ULP*BCOEFA*BNORM, SAFMIN )
!
!           Columnwise triangular solve of  (a A - b B)  x = 0
!
      IL2BY2 = .FALSE.
      DO 370 J = JE - NW, 1, -1
!
!              If a 2-by-2 block, is in position j-1:j, wait until
!              next iteration to process it (when it will be j:j+1)
!
         IF( .NOT.IL2BY2 .AND. J.GT.1 ) THEN
            IF( S( J, J-1 ).NE.ZERO ) THEN
               IL2BY2 = .TRUE.
               GO TO 370
            END IF
         END IF
         BDIAG( 1 ) = P( J, J )
         IF( IL2BY2 ) THEN
            NA = 2
            BDIAG( 2 ) = P( J+1, J+1 )
         ELSE
            NA = 1
         END IF
!
!              Compute x(j) (and x(j+1), if 2-by-2 block)
!
         CALL DLALN2( .FALSE., NA, NW, DMIN, ACOEF, S( J, J ), &
                          LDS, BDIAG( 1 ), BDIAG( 2 ), WORK( 2*N+J ), &
                          N, BCOEFR, BCOEFI, SUM, 2, SCALE, TEMP, &
                          IINFO )
         IF( SCALE.LT.ONE ) THEN
!
            DO 290 JW = 0, NW - 1
               DO 280 JR = 1, JE
                  WORK( ( JW+2 )*N+JR ) = SCALE* &
                         WORK( ( JW+2 )*N+JR )
280                CONTINUE
290             CONTINUE
         END IF
         XMAX = MAX( SCALE*XMAX, TEMP )
!
         DO 310 JW = 1, NW
            DO 300 JA = 1, NA
               WORK( ( JW+1 )*N+J+JA-1 ) = SUM( JA, JW )
300             CONTINUE
310          CONTINUE
!
!              w = w + x(j)*(a S(*,j) - b P(*,j) ) with scaling
!
         IF( J.GT.1 ) THEN
!
!                 Check whether scaling is necessary for sum.
!
            XSCALE = ONE / MAX( ONE, XMAX )
            TEMP = ACOEFA*WORK( J ) + BCOEFA*WORK( N+J )
            IF( IL2BY2 ) &
                   TEMP = MAX( TEMP, ACOEFA*WORK( J+1 )+BCOEFA* &
                          WORK( N+J+1 ) )
            TEMP = MAX( TEMP, ACOEFA, BCOEFA )
            IF( TEMP.GT.BIGNUM*XSCALE ) THEN
!
               DO 330 JW = 0, NW - 1
                  DO 320 JR = 1, JE
                     WORK( ( JW+2 )*N+JR ) = XSCALE* &
                            WORK( ( JW+2 )*N+JR )
320                   CONTINUE
330                CONTINUE
               XMAX = XMAX*XSCALE
            END IF
!
!                 Compute the contributions of the off-diagonals of
!                 column j (and j+1, if 2-by-2 block) of A and B to the
!                 sums.
!
!
            DO 360 JA = 1, NA
               IF( ILCPLX ) THEN
                  CREALA = ACOEF*WORK( 2*N+J+JA-1 )
                  CIMAGA = ACOEF*WORK( 3*N+J+JA-1 )
                  CREALB = BCOEFR*WORK( 2*N+J+JA-1 ) - &
                               BCOEFI*WORK( 3*N+J+JA-1 )
                  CIMAGB = BCOEFI*WORK( 2*N+J+JA-1 ) + &
                               BCOEFR*WORK( 3*N+J+JA-1 )
                  DO 340 JR = 1, J - 1
                     WORK( 2*N+JR ) = WORK( 2*N+JR ) - &
                                          CREALA*S( JR, J+JA-1 ) + &
                                          CREALB*P( JR, J+JA-1 )
                     WORK( 3*N+JR ) = WORK( 3*N+JR ) - &
                                          CIMAGA*S( JR, J+JA-1 ) + &
                                          CIMAGB*P( JR, J+JA-1 )
340                   CONTINUE
               ELSE
                  CREALA = ACOEF*WORK( 2*N+J+JA-1 )
                  CREALB = BCOEFR*WORK( 2*N+J+JA-1 )
                  DO 350 JR = 1, J - 1
                     WORK( 2*N+JR ) = WORK( 2*N+JR ) - &
                                          CREALA*S( JR, J+JA-1 ) + &
                                          CREALB*P( JR, J+JA-1 )
350                   CONTINUE
               END IF
360             CONTINUE
         END IF
!
         IL2BY2 = .FALSE.
370       CONTINUE
!
!           Copy eigenvector to VR, back transforming if
!           HOWMNY='B'.
!
      IEIG = IEIG - NW
      IF( ILBACK ) THEN
!
         DO 410 JW = 0, NW - 1
            DO 380 JR = 1, N
               WORK( ( JW+4 )*N+JR ) = WORK( ( JW+2 )*N+1 )* &
                                           VR( JR, 1 )
380             CONTINUE
!
!                 A series of compiler directives to defeat
!                 vectorization for the next loop
!
!
            DO 400 JC = 2, JE
               DO 390 JR = 1, N
                  WORK( ( JW+4 )*N+JR ) = WORK( ( JW+4 )*N+JR ) + &
                         WORK( ( JW+2 )*N+JC )*VR( JR, JC )
390                CONTINUE
400             CONTINUE
410          CONTINUE
!
         DO 430 JW = 0, NW - 1
            DO 420 JR = 1, N
               VR( JR, IEIG+JW ) = WORK( ( JW+4 )*N+JR )
420             CONTINUE
430          CONTINUE
!
         IEND = N
      ELSE
         DO 450 JW = 0, NW - 1
            DO 440 JR = 1, N
               VR( JR, IEIG+JW ) = WORK( ( JW+2 )*N+JR )
440             CONTINUE
450          CONTINUE
!
         IEND = JE
      END IF
!
!           Scale eigenvector
!
      XMAX = ZERO
      IF( ILCPLX ) THEN
         DO 460 J = 1, IEND
            XMAX = MAX( XMAX, ABS( VR( J, IEIG ) )+ &
                       ABS( VR( J, IEIG+1 ) ) )
460          CONTINUE
      ELSE
         DO 470 J = 1, IEND
            XMAX = MAX( XMAX, ABS( VR( J, IEIG ) ) )
470          CONTINUE
      END IF
!
      IF( XMAX.GT.SAFMIN ) THEN
         XSCALE = ONE / XMAX
         DO 490 JW = 0, NW - 1
            DO 480 JR = 1, IEND
               VR( JR, IEIG+JW ) = XSCALE*VR( JR, IEIG+JW )
480             CONTINUE
490          CONTINUE
      END IF
500    CONTINUE
END IF
!
RETURN
!
!     End of DTGEVC
!
end subroutine dtgevc

! ===== End dtgevc.f90 =====


! ===== Begin dtpsv.f90 =====

SUBROUTINE DTPSV(UPLO,TRANS,DIAG,N,AP,X,INCX)
!     .. Scalar Arguments ..
INTEGER INCX,N
CHARACTER DIAG,TRANS,UPLO
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION AP(*),X(*)
!     ..
!
!  Purpose
!  =======
!
!  DTPSV  solves one of the systems of equations
!
!     A*x = b,   or   A'*x = b,
!
!  where b and x are n element vectors and A is an n by n unit, or
!  non-unit, upper or lower triangular matrix, supplied in packed form.
!
!  No test for singularity or near-singularity is included in this
!  routine. Such tests must be performed before calling this routine.
!
!  Arguments
!  ==========
!
!  UPLO   - CHARACTER*1.
!           On entry, UPLO specifies whether the matrix is an upper or
!           lower triangular matrix as follows:
!
!              UPLO = 'U' or 'u'   A is an upper triangular matrix.
!
!              UPLO = 'L' or 'l'   A is a lower triangular matrix.
!
!           Unchanged on exit.
!
!  TRANS  - CHARACTER*1.
!           On entry, TRANS specifies the equations to be solved as
!           follows:
!
!              TRANS = 'N' or 'n'   A*x = b.
!
!              TRANS = 'T' or 't'   A'*x = b.
!
!              TRANS = 'C' or 'c'   A'*x = b.
!
!           Unchanged on exit.
!
!  DIAG   - CHARACTER*1.
!           On entry, DIAG specifies whether or not A is unit
!           triangular as follows:
!
!              DIAG = 'U' or 'u'   A is assumed to be unit triangular.
!
!              DIAG = 'N' or 'n'   A is not assumed to be unit
!                                  triangular.
!
!           Unchanged on exit.
!
!  N      - INTEGER.
!           On entry, N specifies the order of the matrix A.
!           N must be at least zero.
!           Unchanged on exit.
!
!  AP     - DOUBLE PRECISION array of DIMENSION at least
!           ( ( n*( n + 1 ) )/2 ).
!           Before entry with  UPLO = 'U' or 'u', the array AP must
!           contain the upper triangular matrix packed sequentially,
!           column by column, so that AP( 1 ) contains a( 1, 1 ),
!           AP( 2 ) and AP( 3 ) contain a( 1, 2 ) and a( 2, 2 )
!           respectively, and so on.
!           Before entry with UPLO = 'L' or 'l', the array AP must
!           contain the lower triangular matrix packed sequentially,
!           column by column, so that AP( 1 ) contains a( 1, 1 ),
!           AP( 2 ) and AP( 3 ) contain a( 2, 1 ) and a( 3, 1 )
!           respectively, and so on.
!           Note that when  DIAG = 'U' or 'u', the diagonal elements of
!           A are not referenced, but are assumed to be unity.
!           Unchanged on exit.
!
!  X      - DOUBLE PRECISION array of dimension at least
!           ( 1 + ( n - 1 )*abs( INCX ) ).
!           Before entry, the incremented array X must contain the n
!           element right-hand side vector b. On exit, X is overwritten
!           with the solution vector x.
!
!  INCX   - INTEGER.
!           On entry, INCX specifies the increment for the elements of
!           X. INCX must not be zero.
!           Unchanged on exit.
!
!
!  Level 2 Blas routine.
!
!  -- Written on 22-October-1986.
!     Jack Dongarra, Argonne National Lab.
!     Jeremy Du Croz, Nag Central Office.
!     Sven Hammarling, Nag Central Office.
!     Richard Hanson, Sandia National Labs.
!
!
!     .. Parameters ..
DOUBLE PRECISION ZERO
PARAMETER (ZERO=0.0D+0)
!     ..
!     .. Local Scalars ..
DOUBLE PRECISION TEMP
INTEGER I,INFO,IX,J,JX,K,KK,KX
LOGICAL NOUNIT
!     ..
!     .. External Functions ..
LOGICAL LSAME
EXTERNAL LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL XERBLA
!     ..
!
!     Test the input parameters.
!
INFO = 0
IF (.NOT.LSAME(UPLO,'U') .AND. .NOT.LSAME(UPLO,'L')) THEN
    INFO = 1
ELSE IF (.NOT.LSAME(TRANS,'N') .AND. .NOT.LSAME(TRANS,'T') .AND. &
             .NOT.LSAME(TRANS,'C')) THEN
    INFO = 2
ELSE IF (.NOT.LSAME(DIAG,'U') .AND. .NOT.LSAME(DIAG,'N')) THEN
    INFO = 3
ELSE IF (N.LT.0) THEN
    INFO = 4
ELSE IF (INCX.EQ.0) THEN
    INFO = 7
END IF
IF (INFO.NE.0) THEN
    CALL XERBLA('DTPSV ',INFO)
    RETURN
END IF
!
!     Quick return if possible.
!
IF (N.EQ.0) RETURN
!
NOUNIT = LSAME(DIAG,'N')
!
!     Set up the start point in X if the increment is not unity. This
!     will be  ( N - 1 )*INCX  too small for descending loops.
!
IF (INCX.LE.0) THEN
    KX = 1 - (N-1)*INCX
ELSE IF (INCX.NE.1) THEN
    KX = 1
END IF
!
!     Start the operations. In this version the elements of AP are
!     accessed sequentially with one pass through AP.
!
IF (LSAME(TRANS,'N')) THEN
!
!        Form  x := inv( A )*x.
!
    IF (LSAME(UPLO,'U')) THEN
        KK = (N* (N+1))/2
        IF (INCX.EQ.1) THEN
            DO 20 J = N,1,-1
                IF (X(J).NE.ZERO) THEN
                    IF (NOUNIT) X(J) = X(J)/AP(KK)
                    TEMP = X(J)
                    K = KK - 1
                    DO 10 I = J - 1,1,-1
                        X(I) = X(I) - TEMP*AP(K)
                        K = K - 1
10                     CONTINUE
                END IF
                KK = KK - J
20             CONTINUE
        ELSE
            JX = KX + (N-1)*INCX
            DO 40 J = N,1,-1
                IF (X(JX).NE.ZERO) THEN
                    IF (NOUNIT) X(JX) = X(JX)/AP(KK)
                    TEMP = X(JX)
                    IX = JX
                    DO 30 K = KK - 1,KK - J + 1,-1
                        IX = IX - INCX
                        X(IX) = X(IX) - TEMP*AP(K)
30                     CONTINUE
                END IF
                JX = JX - INCX
                KK = KK - J
40             CONTINUE
        END IF
    ELSE
        KK = 1
        IF (INCX.EQ.1) THEN
            DO 60 J = 1,N
                IF (X(J).NE.ZERO) THEN
                    IF (NOUNIT) X(J) = X(J)/AP(KK)
                    TEMP = X(J)
                    K = KK + 1
                    DO 50 I = J + 1,N
                        X(I) = X(I) - TEMP*AP(K)
                        K = K + 1
50                     CONTINUE
                END IF
                KK = KK + (N-J+1)
60             CONTINUE
        ELSE
            JX = KX
            DO 80 J = 1,N
                IF (X(JX).NE.ZERO) THEN
                    IF (NOUNIT) X(JX) = X(JX)/AP(KK)
                    TEMP = X(JX)
                    IX = JX
                    DO 70 K = KK + 1,KK + N - J
                        IX = IX + INCX
                        X(IX) = X(IX) - TEMP*AP(K)
70                     CONTINUE
                END IF
                JX = JX + INCX
                KK = KK + (N-J+1)
80             CONTINUE
        END IF
    END IF
ELSE
!
!        Form  x := inv( A' )*x.
!
    IF (LSAME(UPLO,'U')) THEN
        KK = 1
        IF (INCX.EQ.1) THEN
            DO 100 J = 1,N
                TEMP = X(J)
                K = KK
                DO 90 I = 1,J - 1
                    TEMP = TEMP - AP(K)*X(I)
                    K = K + 1
90                 CONTINUE
                IF (NOUNIT) TEMP = TEMP/AP(KK+J-1)
                X(J) = TEMP
                KK = KK + J
100             CONTINUE
        ELSE
            JX = KX
            DO 120 J = 1,N
                TEMP = X(JX)
                IX = KX
                DO 110 K = KK,KK + J - 2
                    TEMP = TEMP - AP(K)*X(IX)
                    IX = IX + INCX
110                 CONTINUE
                IF (NOUNIT) TEMP = TEMP/AP(KK+J-1)
                X(JX) = TEMP
                JX = JX + INCX
                KK = KK + J
120             CONTINUE
        END IF
    ELSE
        KK = (N* (N+1))/2
        IF (INCX.EQ.1) THEN
            DO 140 J = N,1,-1
                TEMP = X(J)
                K = KK
                DO 130 I = N,J + 1,-1
                    TEMP = TEMP - AP(K)*X(I)
                    K = K - 1
130                 CONTINUE
                IF (NOUNIT) TEMP = TEMP/AP(KK-N+J)
                X(J) = TEMP
                KK = KK - (N-J+1)
140             CONTINUE
        ELSE
            KX = KX + (N-1)*INCX
            JX = KX
            DO 160 J = N,1,-1
                TEMP = X(JX)
                IX = KX
                DO 150 K = KK,KK - (N- (J+1)),-1
                    TEMP = TEMP - AP(K)*X(IX)
                    IX = IX - INCX
150                 CONTINUE
                IF (NOUNIT) TEMP = TEMP/AP(KK-N+J)
                X(JX) = TEMP
                JX = JX - INCX
                KK = KK - (N-J+1)
160             CONTINUE
        END IF
    END IF
END IF
!
RETURN
!
!     End of DTPSV .
!
end subroutine dtpsv

! ===== End dtpsv.f90 =====


! ===== Begin dtptrs.f90 =====

SUBROUTINE DTPTRS( UPLO, TRANS, DIAG, N, NRHS, AP, B, LDB, INFO )
!
!  -- LAPACK routine (version 3.2) --
!  -- LAPACK is a software package provided by Univ. of Tennessee,    --
!  -- Univ. of California Berkeley, Univ. of Colorado Denver and NAG Ltd..--
!     November 2006
!
!     .. Scalar Arguments ..
CHARACTER          DIAG, TRANS, UPLO
INTEGER            INFO, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   AP( * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DTPTRS solves a triangular system of the form
!
!     A * X = B  or  A**T * X = B,
!
!  where A is a triangular matrix of order N stored in packed format,
!  and B is an N-by-NRHS matrix.  A check is made to verify that A is
!  nonsingular.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  A is upper triangular;
!          = 'L':  A is lower triangular.
!
!  TRANS   (input) CHARACTER*1
!          Specifies the form of the system of equations:
!          = 'N':  A * X = B  (No transpose)
!          = 'T':  A**T * X = B  (Transpose)
!          = 'C':  A**H * X = B  (Conjugate transpose = Transpose)
!
!  DIAG    (input) CHARACTER*1
!          = 'N':  A is non-unit triangular;
!          = 'U':  A is unit triangular.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  AP      (input) DOUBLE PRECISION array, dimension (N*(N+1)/2)
!          The upper or lower triangular matrix A, packed columnwise in
!          a linear array.  The j-th column of A is stored in the array
!          AP as follows:
!          if UPLO = 'U', AP(i + (j-1)*j/2) = A(i,j) for 1<=i<=j;
!          if UPLO = 'L', AP(i + (j-1)*(2*n-j)/2) = A(i,j) for j<=i<=n.
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the right hand side matrix B.
!          On exit, if INFO = 0, the solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          > 0:  if INFO = i, the i-th diagonal element of A is zero,
!                indicating that the matrix is singular and the
!                solutions X have not been computed.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            NOUNIT, UPPER
INTEGER            J, JC
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DTPSV, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
UPPER = LSAME( UPLO, 'U' )
NOUNIT = LSAME( DIAG, 'N' )
IF( .NOT.UPPER .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( .NOT.LSAME( TRANS, 'N' ) .AND. .NOT. &
             LSAME( TRANS, 'T' ) .AND. .NOT.LSAME( TRANS, 'C' ) ) THEN
   INFO = -2
ELSE IF( .NOT.NOUNIT .AND. .NOT.LSAME( DIAG, 'U' ) ) THEN
   INFO = -3
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -5
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -8
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTPTRS', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Check for singularity.
!
IF( NOUNIT ) THEN
   IF( UPPER ) THEN
      JC = 1
      DO 10 INFO = 1, N
         IF( AP( JC+INFO-1 ).EQ.ZERO ) &
                RETURN
         JC = JC + INFO
10       CONTINUE
   ELSE
      JC = 1
      DO 20 INFO = 1, N
         IF( AP( JC ).EQ.ZERO ) &
                RETURN
         JC = JC + N - INFO + 1
20       CONTINUE
   END IF
END IF
INFO = 0
!
!     Solve A * x = b  or  A' * x = b.
!
DO 30 J = 1, NRHS
   CALL DTPSV( UPLO, TRANS, DIAG, N, AP, B( 1, J ), 1 )
30 CONTINUE
!
RETURN
!
!     End of DTPTRS
!
end subroutine dtptrs

! ===== End dtptrs.f90 =====


! ===== Begin dtrevc.f90 =====

SUBROUTINE DTREVC( SIDE, HOWMNY, SELECT, N, T, LDT, VL, LDVL, VR, &
                       LDVR, MM, M, WORK, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER          HOWMNY, SIDE
INTEGER            INFO, LDT, LDVL, LDVR, M, MM, N
!     ..
!     .. Array Arguments ..
LOGICAL            SELECT( * )
DOUBLE PRECISION   T( LDT, * ), VL( LDVL, * ), VR( LDVR, * ), &
                       WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DTREVC computes some or all of the right and/or left eigenvectors of
!  a real upper quasi-triangular matrix T.
!
!  The right eigenvector x and the left eigenvector y of T corresponding
!  to an eigenvalue w are defined by:
!
!               T*x = w*x,     y'*T = w*y'
!
!  where y' denotes the conjugate transpose of the vector y.
!
!  If all eigenvectors are requested, the routine may either return the
!  matrices X and/or Y of right or left eigenvectors of T, or the
!  products Q*X and/or Q*Y, where Q is an input orthogonal
!  matrix. If T was obtained from the real-Schur factorization of an
!  original matrix A = Q*T*Q', then Q*X and Q*Y are the matrices of
!  right or left eigenvectors of A.
!
!  T must be in Schur canonical form (as returned by DHSEQR), that is,
!  block upper triangular with 1-by-1 and 2-by-2 diagonal blocks; each
!  2-by-2 diagonal block has its diagonal elements equal and its
!  off-diagonal elements of opposite sign.  Corresponding to each 2-by-2
!  diagonal block is a complex conjugate pair of eigenvalues and
!  eigenvectors; only one eigenvector of the pair is computed, namely
!  the one corresponding to the eigenvalue with positive imaginary part.
!
!
!  Arguments
!  =========
!
!  SIDE    (input) CHARACTER*1
!          = 'R':  compute right eigenvectors only;
!          = 'L':  compute left eigenvectors only;
!          = 'B':  compute both right and left eigenvectors.
!
!  HOWMNY  (input) CHARACTER*1
!          = 'A':  compute all right and/or left eigenvectors;
!          = 'B':  compute all right and/or left eigenvectors,
!                  and backtransform them using the input matrices
!                  supplied in VR and/or VL;
!          = 'S':  compute selected right and/or left eigenvectors,
!                  specified by the logical array SELECT.
!
!  SELECT  (input/output) LOGICAL array, dimension (N)
!          If HOWMNY = 'S', SELECT specifies the eigenvectors to be
!          computed.
!          If HOWMNY = 'A' or 'B', SELECT is not referenced.
!          To select the real eigenvector corresponding to a real
!          eigenvalue w(j), SELECT(j) must be set to .TRUE..  To select
!          the complex eigenvector corresponding to a complex conjugate
!          pair w(j) and w(j+1), either SELECT(j) or SELECT(j+1) must be
!          set to .TRUE.; then on exit SELECT(j) is .TRUE. and
!          SELECT(j+1) is .FALSE..
!
!  N       (input) INTEGER
!          The order of the matrix T. N >= 0.
!
!  T       (input) DOUBLE PRECISION array, dimension (LDT,N)
!          The upper quasi-triangular matrix T in Schur canonical form.
!
!  LDT     (input) INTEGER
!          The leading dimension of the array T. LDT >= max(1,N).
!
!  VL      (input/output) DOUBLE PRECISION array, dimension (LDVL,MM)
!          On entry, if SIDE = 'L' or 'B' and HOWMNY = 'B', VL must
!          contain an N-by-N matrix Q (usually the orthogonal matrix Q
!          of Schur vectors returned by DHSEQR).
!          On exit, if SIDE = 'L' or 'B', VL contains:
!          if HOWMNY = 'A', the matrix Y of left eigenvectors of T;
!          if HOWMNY = 'B', the matrix Q*Y;
!          if HOWMNY = 'S', the left eigenvectors of T specified by
!                           SELECT, stored consecutively in the columns
!                           of VL, in the same order as their
!                           eigenvalues.
!          A complex eigenvector corresponding to a complex eigenvalue
!          is stored in two consecutive columns, the first holding the
!          real part, and the second the imaginary part.
!          If SIDE = 'R', VL is not referenced.
!
!  LDVL    (input) INTEGER
!          The leading dimension of the array VL.  LDVL >= max(1,N) if
!          SIDE = 'L' or 'B'; LDVL >= 1 otherwise.
!
!  VR      (input/output) DOUBLE PRECISION array, dimension (LDVR,MM)
!          On entry, if SIDE = 'R' or 'B' and HOWMNY = 'B', VR must
!          contain an N-by-N matrix Q (usually the orthogonal matrix Q
!          of Schur vectors returned by DHSEQR).
!          On exit, if SIDE = 'R' or 'B', VR contains:
!          if HOWMNY = 'A', the matrix X of right eigenvectors of T;
!          if HOWMNY = 'B', the matrix Q*X;
!          if HOWMNY = 'S', the right eigenvectors of T specified by
!                           SELECT, stored consecutively in the columns
!                           of VR, in the same order as their
!                           eigenvalues.
!          A complex eigenvector corresponding to a complex eigenvalue
!          is stored in two consecutive columns, the first holding the
!          real part and the second the imaginary part.
!          If SIDE = 'L', VR is not referenced.
!
!  LDVR    (input) INTEGER
!          The leading dimension of the array VR.  LDVR >= max(1,N) if
!          SIDE = 'R' or 'B'; LDVR >= 1 otherwise.
!
!  MM      (input) INTEGER
!          The number of columns in the arrays VL and/or VR. MM >= M.
!
!  M       (output) INTEGER
!          The number of columns in the arrays VL and/or VR actually
!          used to store the eigenvectors.
!          If HOWMNY = 'A' or 'B', M is set to N.
!          Each selected real eigenvector occupies one column and each
!          selected complex eigenvector occupies two columns.
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (3*N)
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!
!  Further Details
!  ===============
!
!  The algorithm used in this program is basically backward (forward)
!  substitution, with scaling to make the the code robust against
!  possible overflow.
!
!  Each eigenvector is normalized so that the element of largest
!  magnitude has magnitude 1; here the magnitude of a complex number
!  (x,y) is taken to be |x| + |y|.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            ALLV, BOTHV, LEFTV, OVER, PAIR, RIGHTV, SOMEV
INTEGER            I, IERR, II, IP, IS, J, J1, J2, JNXT, K, KI, N2
DOUBLE PRECISION   BETA, BIGNUM, EMAX, OVFL, REC, REMAX, SCALE, &
                       SMIN, SMLNUM, ULP, UNFL, VCRIT, VMAX, WI, WR, &
                       XNORM
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            IDAMAX
DOUBLE PRECISION   DDOT, DLAMCH
EXTERNAL           LSAME, IDAMAX, DDOT, DLAMCH
!     ..
!     .. External Subroutines ..
EXTERNAL           DAXPY, DCOPY, DGEMV, DLABAD, DLALN2, DSCAL, &
                       XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, SQRT
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   X( 2, 2 )
!     ..
!     .. Executable Statements ..
!
!     Decode and test the input parameters
!
BOTHV = LSAME( SIDE, 'B' )
RIGHTV = LSAME( SIDE, 'R' ) .OR. BOTHV
LEFTV = LSAME( SIDE, 'L' ) .OR. BOTHV
!
ALLV = LSAME( HOWMNY, 'A' )
OVER = LSAME( HOWMNY, 'B' ) .OR. LSAME( HOWMNY, 'O' )
SOMEV = LSAME( HOWMNY, 'S' )
!
INFO = 0
IF( .NOT.RIGHTV .AND. .NOT.LEFTV ) THEN
   INFO = -1
ELSE IF( .NOT.ALLV .AND. .NOT.OVER .AND. .NOT.SOMEV ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( LDT.LT.MAX( 1, N ) ) THEN
   INFO = -6
ELSE IF( LDVL.LT.1 .OR. ( LEFTV .AND. LDVL.LT.N ) ) THEN
   INFO = -8
ELSE IF( LDVR.LT.1 .OR. ( RIGHTV .AND. LDVR.LT.N ) ) THEN
   INFO = -10
ELSE
!
!        Set M to the number of columns required to store the selected
!        eigenvectors, standardize the array SELECT if necessary, and
!        test MM.
!
   IF( SOMEV ) THEN
      M = 0
      PAIR = .FALSE.
      DO 10 J = 1, N
         IF( PAIR ) THEN
            PAIR = .FALSE.
            SELECT( J ) = .FALSE.
         ELSE
            IF( J.LT.N ) THEN
               IF( T( J+1, J ).EQ.ZERO ) THEN
                  IF( SELECT( J ) ) &
                         M = M + 1
               ELSE
                  PAIR = .TRUE.
                  IF( SELECT( J ) .OR. SELECT( J+1 ) ) THEN
                     SELECT( J ) = .TRUE.
                     M = M + 2
                  END IF
               END IF
            ELSE
               IF( SELECT( N ) ) &
                      M = M + 1
            END IF
         END IF
10       CONTINUE
   ELSE
      M = N
   END IF
!
   IF( MM.LT.M ) THEN
      INFO = -11
   END IF
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTREVC', -INFO )
   RETURN
END IF
!
!     Quick return if possible.
!
IF( N.EQ.0 ) &
       RETURN
!
!     Set the constants to control overflow.
!
UNFL = DLAMCH( 'Safe minimum' )
OVFL = ONE / UNFL
CALL DLABAD( UNFL, OVFL )
ULP = DLAMCH( 'Precision' )
SMLNUM = UNFL*( N / ULP )
BIGNUM = ( ONE-ULP ) / SMLNUM
!
!     Compute 1-norm of each column of strictly upper triangular
!     part of T to control overflow in triangular solver.
!
WORK( 1 ) = ZERO
DO 30 J = 2, N
   WORK( J ) = ZERO
   DO 20 I = 1, J - 1
      WORK( J ) = WORK( J ) + ABS( T( I, J ) )
20    CONTINUE
30 CONTINUE
!
!     Index IP is used to specify the real or complex eigenvalue:
!       IP = 0, real eigenvalue,
!            1, first of conjugate complex pair: (wr,wi)
!           -1, second of conjugate complex pair: (wr,wi)
!
N2 = 2*N
!
IF( RIGHTV ) THEN
!
!        Compute right eigenvectors.
!
   IP = 0
   IS = M
   DO 140 KI = N, 1, -1
!
      IF( IP.EQ.1 ) &
             GO TO 130
      IF( KI.EQ.1 ) &
             GO TO 40
      IF( T( KI, KI-1 ).EQ.ZERO ) &
             GO TO 40
      IP = -1
!
40       CONTINUE
      IF( SOMEV ) THEN
         IF( IP.EQ.0 ) THEN
            IF( .NOT.SELECT( KI ) ) &
                   GO TO 130
         ELSE
            IF( .NOT.SELECT( KI-1 ) ) &
                   GO TO 130
         END IF
      END IF
!
!           Compute the KI-th eigenvalue (WR,WI).
!
      WR = T( KI, KI )
      WI = ZERO
      IF( IP.NE.0 ) &
             WI = SQRT( ABS( T( KI, KI-1 ) ) )* &
                  SQRT( ABS( T( KI-1, KI ) ) )
      SMIN = MAX( ULP*( ABS( WR )+ABS( WI ) ), SMLNUM )
!
      IF( IP.EQ.0 ) THEN
!
!              Real right eigenvector
!
         WORK( KI+N ) = ONE
!
!              Form right-hand side
!
         DO 50 K = 1, KI - 1
            WORK( K+N ) = -T( K, KI )
50          CONTINUE
!
!              Solve the upper quasi-triangular system:
!                 (T(1:KI-1,1:KI-1) - WR)*X = SCALE*WORK.
!
         JNXT = KI - 1
         DO 60 J = KI - 1, 1, -1
            IF( J.GT.JNXT ) &
                   GO TO 60
            J1 = J
            J2 = J
            JNXT = J - 1
            IF( J.GT.1 ) THEN
               IF( T( J, J-1 ).NE.ZERO ) THEN
                  J1 = J - 1
                  JNXT = J - 2
               END IF
            END IF
!
            IF( J1.EQ.J2 ) THEN
!
!                    1-by-1 diagonal block
!
               CALL DLALN2( .FALSE., 1, 1, SMIN, ONE, T( J, J ), &
                                LDT, ONE, ONE, WORK( J+N ), N, WR, &
                                ZERO, X, 2, SCALE, XNORM, IERR )
!
!                    Scale X(1,1) to avoid overflow when updating
!                    the right-hand side.
!
               IF( XNORM.GT.ONE ) THEN
                  IF( WORK( J ).GT.BIGNUM / XNORM ) THEN
                     X( 1, 1 ) = X( 1, 1 ) / XNORM
                     SCALE = SCALE / XNORM
                  END IF
               END IF
!
!                    Scale if necessary
!
               IF( SCALE.NE.ONE ) &
                      CALL DSCAL( KI, SCALE, WORK( 1+N ), 1 )
               WORK( J+N ) = X( 1, 1 )
!
!                    Update right-hand side
!
               CALL DAXPY( J-1, -X( 1, 1 ), T( 1, J ), 1, &
                               WORK( 1+N ), 1 )
!
            ELSE
!
!                    2-by-2 diagonal block
!
               CALL DLALN2( .FALSE., 2, 1, SMIN, ONE, &
                                T( J-1, J-1 ), LDT, ONE, ONE, &
                                WORK( J-1+N ), N, WR, ZERO, X, 2, &
                                SCALE, XNORM, IERR )
!
!                    Scale X(1,1) and X(2,1) to avoid overflow when
!                    updating the right-hand side.
!
               IF( XNORM.GT.ONE ) THEN
                  BETA = MAX( WORK( J-1 ), WORK( J ) )
                  IF( BETA.GT.BIGNUM / XNORM ) THEN
                     X( 1, 1 ) = X( 1, 1 ) / XNORM
                     X( 2, 1 ) = X( 2, 1 ) / XNORM
                     SCALE = SCALE / XNORM
                  END IF
               END IF
!
!                    Scale if necessary
!
               IF( SCALE.NE.ONE ) &
                      CALL DSCAL( KI, SCALE, WORK( 1+N ), 1 )
               WORK( J-1+N ) = X( 1, 1 )
               WORK( J+N ) = X( 2, 1 )
!
!                    Update right-hand side
!
               CALL DAXPY( J-2, -X( 1, 1 ), T( 1, J-1 ), 1, &
                               WORK( 1+N ), 1 )
               CALL DAXPY( J-2, -X( 2, 1 ), T( 1, J ), 1, &
                               WORK( 1+N ), 1 )
            END IF
60          CONTINUE
!
!              Copy the vector x or Q*x to VR and normalize.
!
         IF( .NOT.OVER ) THEN
            CALL DCOPY( KI, WORK( 1+N ), 1, VR( 1, IS ), 1 )
!
            II = IDAMAX( KI, VR( 1, IS ), 1 )
            REMAX = ONE / ABS( VR( II, IS ) )
            CALL DSCAL( KI, REMAX, VR( 1, IS ), 1 )
!
            DO 70 K = KI + 1, N
               VR( K, IS ) = ZERO
70             CONTINUE
         ELSE
            IF( KI.GT.1 ) &
                   CALL DGEMV( 'N', N, KI-1, ONE, VR, LDVR, &
                               WORK( 1+N ), 1, WORK( KI+N ), &
                               VR( 1, KI ), 1 )
!
            II = IDAMAX( N, VR( 1, KI ), 1 )
            REMAX = ONE / ABS( VR( II, KI ) )
            CALL DSCAL( N, REMAX, VR( 1, KI ), 1 )
         END IF
!
      ELSE
!
!              Complex right eigenvector.
!
!              Initial solve
!                [ (T(KI-1,KI-1) T(KI-1,KI) ) - (WR + I* WI)]*X = 0.
!                [ (T(KI,KI-1)   T(KI,KI)   )               ]
!
         IF( ABS( T( KI-1, KI ) ).GE.ABS( T( KI, KI-1 ) ) ) THEN
            WORK( KI-1+N ) = ONE
            WORK( KI+N2 ) = WI / T( KI-1, KI )
         ELSE
            WORK( KI-1+N ) = -WI / T( KI, KI-1 )
            WORK( KI+N2 ) = ONE
         END IF
         WORK( KI+N ) = ZERO
         WORK( KI-1+N2 ) = ZERO
!
!              Form right-hand side
!
         DO 80 K = 1, KI - 2
            WORK( K+N ) = -WORK( KI-1+N )*T( K, KI-1 )
            WORK( K+N2 ) = -WORK( KI+N2 )*T( K, KI )
80          CONTINUE
!
!              Solve upper quasi-triangular system:
!              (T(1:KI-2,1:KI-2) - (WR+i*WI))*X = SCALE*(WORK+i*WORK2)
!
         JNXT = KI - 2
         DO 90 J = KI - 2, 1, -1
            IF( J.GT.JNXT ) &
                   GO TO 90
            J1 = J
            J2 = J
            JNXT = J - 1
            IF( J.GT.1 ) THEN
               IF( T( J, J-1 ).NE.ZERO ) THEN
                  J1 = J - 1
                  JNXT = J - 2
               END IF
            END IF
!
            IF( J1.EQ.J2 ) THEN
!
!                    1-by-1 diagonal block
!
               CALL DLALN2( .FALSE., 1, 2, SMIN, ONE, T( J, J ), &
                                LDT, ONE, ONE, WORK( J+N ), N, WR, WI, &
                                X, 2, SCALE, XNORM, IERR )
!
!                    Scale X(1,1) and X(1,2) to avoid overflow when
!                    updating the right-hand side.
!
               IF( XNORM.GT.ONE ) THEN
                  IF( WORK( J ).GT.BIGNUM / XNORM ) THEN
                     X( 1, 1 ) = X( 1, 1 ) / XNORM
                     X( 1, 2 ) = X( 1, 2 ) / XNORM
                     SCALE = SCALE / XNORM
                  END IF
               END IF
!
!                    Scale if necessary
!
               IF( SCALE.NE.ONE ) THEN
                  CALL DSCAL( KI, SCALE, WORK( 1+N ), 1 )
                  CALL DSCAL( KI, SCALE, WORK( 1+N2 ), 1 )
               END IF
               WORK( J+N ) = X( 1, 1 )
               WORK( J+N2 ) = X( 1, 2 )
!
!                    Update the right-hand side
!
               CALL DAXPY( J-1, -X( 1, 1 ), T( 1, J ), 1, &
                               WORK( 1+N ), 1 )
               CALL DAXPY( J-1, -X( 1, 2 ), T( 1, J ), 1, &
                               WORK( 1+N2 ), 1 )
!
            ELSE
!
!                    2-by-2 diagonal block
!
               CALL DLALN2( .FALSE., 2, 2, SMIN, ONE, &
                                T( J-1, J-1 ), LDT, ONE, ONE, &
                                WORK( J-1+N ), N, WR, WI, X, 2, SCALE, &
                                XNORM, IERR )
!
!                    Scale X to avoid overflow when updating
!                    the right-hand side.
!
               IF( XNORM.GT.ONE ) THEN
                  BETA = MAX( WORK( J-1 ), WORK( J ) )
                  IF( BETA.GT.BIGNUM / XNORM ) THEN
                     REC = ONE / XNORM
                     X( 1, 1 ) = X( 1, 1 )*REC
                     X( 1, 2 ) = X( 1, 2 )*REC
                     X( 2, 1 ) = X( 2, 1 )*REC
                     X( 2, 2 ) = X( 2, 2 )*REC
                     SCALE = SCALE*REC
                  END IF
               END IF
!
!                    Scale if necessary
!
               IF( SCALE.NE.ONE ) THEN
                  CALL DSCAL( KI, SCALE, WORK( 1+N ), 1 )
                  CALL DSCAL( KI, SCALE, WORK( 1+N2 ), 1 )
               END IF
               WORK( J-1+N ) = X( 1, 1 )
               WORK( J+N ) = X( 2, 1 )
               WORK( J-1+N2 ) = X( 1, 2 )
               WORK( J+N2 ) = X( 2, 2 )
!
!                    Update the right-hand side
!
               CALL DAXPY( J-2, -X( 1, 1 ), T( 1, J-1 ), 1, &
                               WORK( 1+N ), 1 )
               CALL DAXPY( J-2, -X( 2, 1 ), T( 1, J ), 1, &
                               WORK( 1+N ), 1 )
               CALL DAXPY( J-2, -X( 1, 2 ), T( 1, J-1 ), 1, &
                               WORK( 1+N2 ), 1 )
               CALL DAXPY( J-2, -X( 2, 2 ), T( 1, J ), 1, &
                               WORK( 1+N2 ), 1 )
            END IF
90          CONTINUE
!
!              Copy the vector x or Q*x to VR and normalize.
!
         IF( .NOT.OVER ) THEN
            CALL DCOPY( KI, WORK( 1+N ), 1, VR( 1, IS-1 ), 1 )
            CALL DCOPY( KI, WORK( 1+N2 ), 1, VR( 1, IS ), 1 )
!
            EMAX = ZERO
            DO 100 K = 1, KI
               EMAX = MAX( EMAX, ABS( VR( K, IS-1 ) )+ &
                          ABS( VR( K, IS ) ) )
100             CONTINUE
!
            REMAX = ONE / EMAX
            CALL DSCAL( KI, REMAX, VR( 1, IS-1 ), 1 )
            CALL DSCAL( KI, REMAX, VR( 1, IS ), 1 )
!
            DO 110 K = KI + 1, N
               VR( K, IS-1 ) = ZERO
               VR( K, IS ) = ZERO
110             CONTINUE
!
         ELSE
!
            IF( KI.GT.2 ) THEN
               CALL DGEMV( 'N', N, KI-2, ONE, VR, LDVR, &
                               WORK( 1+N ), 1, WORK( KI-1+N ), &
                               VR( 1, KI-1 ), 1 )
               CALL DGEMV( 'N', N, KI-2, ONE, VR, LDVR, &
                               WORK( 1+N2 ), 1, WORK( KI+N2 ), &
                               VR( 1, KI ), 1 )
            ELSE
               CALL DSCAL( N, WORK( KI-1+N ), VR( 1, KI-1 ), 1 )
               CALL DSCAL( N, WORK( KI+N2 ), VR( 1, KI ), 1 )
            END IF
!
            EMAX = ZERO
            DO 120 K = 1, N
               EMAX = MAX( EMAX, ABS( VR( K, KI-1 ) )+ &
                          ABS( VR( K, KI ) ) )
120             CONTINUE
            REMAX = ONE / EMAX
            CALL DSCAL( N, REMAX, VR( 1, KI-1 ), 1 )
            CALL DSCAL( N, REMAX, VR( 1, KI ), 1 )
         END IF
      END IF
!
      IS = IS - 1
      IF( IP.NE.0 ) &
             IS = IS - 1
130       CONTINUE
      IF( IP.EQ.1 ) &
             IP = 0
      IF( IP.EQ.-1 ) &
             IP = 1
140    CONTINUE
END IF
!
IF( LEFTV ) THEN
!
!        Compute left eigenvectors.
!
   IP = 0
   IS = 1
   DO 260 KI = 1, N
!
      IF( IP.EQ.-1 ) &
             GO TO 250
      IF( KI.EQ.N ) &
             GO TO 150
      IF( T( KI+1, KI ).EQ.ZERO ) &
             GO TO 150
      IP = 1
!
150       CONTINUE
      IF( SOMEV ) THEN
         IF( .NOT.SELECT( KI ) ) &
                GO TO 250
      END IF
!
!           Compute the KI-th eigenvalue (WR,WI).
!
      WR = T( KI, KI )
      WI = ZERO
      IF( IP.NE.0 ) &
             WI = SQRT( ABS( T( KI, KI+1 ) ) )* &
                  SQRT( ABS( T( KI+1, KI ) ) )
      SMIN = MAX( ULP*( ABS( WR )+ABS( WI ) ), SMLNUM )
!
      IF( IP.EQ.0 ) THEN
!
!              Real left eigenvector.
!
         WORK( KI+N ) = ONE
!
!              Form right-hand side
!
         DO 160 K = KI + 1, N
            WORK( K+N ) = -T( KI, K )
160          CONTINUE
!
!              Solve the quasi-triangular system:
!                 (T(KI+1:N,KI+1:N) - WR)'*X = SCALE*WORK
!
         VMAX = ONE
         VCRIT = BIGNUM
!
         JNXT = KI + 1
         DO 170 J = KI + 1, N
            IF( J.LT.JNXT ) &
                   GO TO 170
            J1 = J
            J2 = J
            JNXT = J + 1
            IF( J.LT.N ) THEN
               IF( T( J+1, J ).NE.ZERO ) THEN
                  J2 = J + 1
                  JNXT = J + 2
               END IF
            END IF
!
            IF( J1.EQ.J2 ) THEN
!
!                    1-by-1 diagonal block
!
!                    Scale if necessary to avoid overflow when forming
!                    the right-hand side.
!
               IF( WORK( J ).GT.VCRIT ) THEN
                  REC = ONE / VMAX
                  CALL DSCAL( N-KI+1, REC, WORK( KI+N ), 1 )
                  VMAX = ONE
                  VCRIT = BIGNUM
               END IF
!
               WORK( J+N ) = WORK( J+N ) - &
                                 DDOT( J-KI-1, T( KI+1, J ), 1, &
                                 WORK( KI+1+N ), 1 )
!
!                    Solve (T(J,J)-WR)'*X = WORK
!
               CALL DLALN2( .FALSE., 1, 1, SMIN, ONE, T( J, J ), &
                                LDT, ONE, ONE, WORK( J+N ), N, WR, &
                                ZERO, X, 2, SCALE, XNORM, IERR )
!
!                    Scale if necessary
!
               IF( SCALE.NE.ONE ) &
                      CALL DSCAL( N-KI+1, SCALE, WORK( KI+N ), 1 )
               WORK( J+N ) = X( 1, 1 )
               VMAX = MAX( ABS( WORK( J+N ) ), VMAX )
               VCRIT = BIGNUM / VMAX
!
            ELSE
!
!                    2-by-2 diagonal block
!
!                    Scale if necessary to avoid overflow when forming
!                    the right-hand side.
!
               BETA = MAX( WORK( J ), WORK( J+1 ) )
               IF( BETA.GT.VCRIT ) THEN
                  REC = ONE / VMAX
                  CALL DSCAL( N-KI+1, REC, WORK( KI+N ), 1 )
                  VMAX = ONE
                  VCRIT = BIGNUM
               END IF
!
               WORK( J+N ) = WORK( J+N ) - &
                                 DDOT( J-KI-1, T( KI+1, J ), 1, &
                                 WORK( KI+1+N ), 1 )
!
               WORK( J+1+N ) = WORK( J+1+N ) - &
                                   DDOT( J-KI-1, T( KI+1, J+1 ), 1, &
                                   WORK( KI+1+N ), 1 )
!
!                    Solve
!                      [T(J,J)-WR   T(J,J+1)     ]'* X = SCALE*( WORK1 )
!                      [T(J+1,J)    T(J+1,J+1)-WR]             ( WORK2 )
!
               CALL DLALN2( .TRUE., 2, 1, SMIN, ONE, T( J, J ), &
                                LDT, ONE, ONE, WORK( J+N ), N, WR, &
                                ZERO, X, 2, SCALE, XNORM, IERR )
!
!                    Scale if necessary
!
               IF( SCALE.NE.ONE ) &
                      CALL DSCAL( N-KI+1, SCALE, WORK( KI+N ), 1 )
               WORK( J+N ) = X( 1, 1 )
               WORK( J+1+N ) = X( 2, 1 )
!
               VMAX = MAX( ABS( WORK( J+N ) ), &
                          ABS( WORK( J+1+N ) ), VMAX )
               VCRIT = BIGNUM / VMAX
!
            END IF
170          CONTINUE
!
!              Copy the vector x or Q*x to VL and normalize.
!
         IF( .NOT.OVER ) THEN
            CALL DCOPY( N-KI+1, WORK( KI+N ), 1, VL( KI, IS ), 1 )
!
            II = IDAMAX( N-KI+1, VL( KI, IS ), 1 ) + KI - 1
            REMAX = ONE / ABS( VL( II, IS ) )
            CALL DSCAL( N-KI+1, REMAX, VL( KI, IS ), 1 )
!
            DO 180 K = 1, KI - 1
               VL( K, IS ) = ZERO
180             CONTINUE
!
         ELSE
!
            IF( KI.LT.N ) &
                   CALL DGEMV( 'N', N, N-KI, ONE, VL( 1, KI+1 ), LDVL, &
                               WORK( KI+1+N ), 1, WORK( KI+N ), &
                               VL( 1, KI ), 1 )
!
            II = IDAMAX( N, VL( 1, KI ), 1 )
            REMAX = ONE / ABS( VL( II, KI ) )
            CALL DSCAL( N, REMAX, VL( 1, KI ), 1 )
!
         END IF
!
      ELSE
!
!              Complex left eigenvector.
!
!               Initial solve:
!                 ((T(KI,KI)    T(KI,KI+1) )' - (WR - I* WI))*X = 0.
!                 ((T(KI+1,KI) T(KI+1,KI+1))                )
!
         IF( ABS( T( KI, KI+1 ) ).GE.ABS( T( KI+1, KI ) ) ) THEN
            WORK( KI+N ) = WI / T( KI, KI+1 )
            WORK( KI+1+N2 ) = ONE
         ELSE
            WORK( KI+N ) = ONE
            WORK( KI+1+N2 ) = -WI / T( KI+1, KI )
         END IF
         WORK( KI+1+N ) = ZERO
         WORK( KI+N2 ) = ZERO
!
!              Form right-hand side
!
         DO 190 K = KI + 2, N
            WORK( K+N ) = -WORK( KI+N )*T( KI, K )
            WORK( K+N2 ) = -WORK( KI+1+N2 )*T( KI+1, K )
190          CONTINUE
!
!              Solve complex quasi-triangular system:
!              ( T(KI+2,N:KI+2,N) - (WR-i*WI) )*X = WORK1+i*WORK2
!
         VMAX = ONE
         VCRIT = BIGNUM
!
         JNXT = KI + 2
         DO 200 J = KI + 2, N
            IF( J.LT.JNXT ) &
                   GO TO 200
            J1 = J
            J2 = J
            JNXT = J + 1
            IF( J.LT.N ) THEN
               IF( T( J+1, J ).NE.ZERO ) THEN
                  J2 = J + 1
                  JNXT = J + 2
               END IF
            END IF
!
            IF( J1.EQ.J2 ) THEN
!
!                    1-by-1 diagonal block
!
!                    Scale if necessary to avoid overflow when
!                    forming the right-hand side elements.
!
               IF( WORK( J ).GT.VCRIT ) THEN
                  REC = ONE / VMAX
                  CALL DSCAL( N-KI+1, REC, WORK( KI+N ), 1 )
                  CALL DSCAL( N-KI+1, REC, WORK( KI+N2 ), 1 )
                  VMAX = ONE
                  VCRIT = BIGNUM
               END IF
!
               WORK( J+N ) = WORK( J+N ) - &
                                 DDOT( J-KI-2, T( KI+2, J ), 1, &
                                 WORK( KI+2+N ), 1 )
               WORK( J+N2 ) = WORK( J+N2 ) - &
                                  DDOT( J-KI-2, T( KI+2, J ), 1, &
                                  WORK( KI+2+N2 ), 1 )
!
!                    Solve (T(J,J)-(WR-i*WI))*(X11+i*X12)= WK+I*WK2
!
               CALL DLALN2( .FALSE., 1, 2, SMIN, ONE, T( J, J ), &
                                LDT, ONE, ONE, WORK( J+N ), N, WR, &
                                -WI, X, 2, SCALE, XNORM, IERR )
!
!                    Scale if necessary
!
               IF( SCALE.NE.ONE ) THEN
                  CALL DSCAL( N-KI+1, SCALE, WORK( KI+N ), 1 )
                  CALL DSCAL( N-KI+1, SCALE, WORK( KI+N2 ), 1 )
               END IF
               WORK( J+N ) = X( 1, 1 )
               WORK( J+N2 ) = X( 1, 2 )
               VMAX = MAX( ABS( WORK( J+N ) ), &
                          ABS( WORK( J+N2 ) ), VMAX )
               VCRIT = BIGNUM / VMAX
!
            ELSE
!
!                    2-by-2 diagonal block
!
!                    Scale if necessary to avoid overflow when forming
!                    the right-hand side elements.
!
               BETA = MAX( WORK( J ), WORK( J+1 ) )
               IF( BETA.GT.VCRIT ) THEN
                  REC = ONE / VMAX
                  CALL DSCAL( N-KI+1, REC, WORK( KI+N ), 1 )
                  CALL DSCAL( N-KI+1, REC, WORK( KI+N2 ), 1 )
                  VMAX = ONE
                  VCRIT = BIGNUM
               END IF
!
               WORK( J+N ) = WORK( J+N ) - &
                                 DDOT( J-KI-2, T( KI+2, J ), 1, &
                                 WORK( KI+2+N ), 1 )
!
               WORK( J+N2 ) = WORK( J+N2 ) - &
                                  DDOT( J-KI-2, T( KI+2, J ), 1, &
                                  WORK( KI+2+N2 ), 1 )
!
               WORK( J+1+N ) = WORK( J+1+N ) - &
                                   DDOT( J-KI-2, T( KI+2, J+1 ), 1, &
                                   WORK( KI+2+N ), 1 )
!
               WORK( J+1+N2 ) = WORK( J+1+N2 ) - &
                                    DDOT( J-KI-2, T( KI+2, J+1 ), 1, &
                                    WORK( KI+2+N2 ), 1 )
!
!                    Solve 2-by-2 complex linear equation
!                      ([T(j,j)   T(j,j+1)  ]'-(wr-i*wi)*I)*X = SCALE*B
!                      ([T(j+1,j) T(j+1,j+1)]             )
!
               CALL DLALN2( .TRUE., 2, 2, SMIN, ONE, T( J, J ), &
                                LDT, ONE, ONE, WORK( J+N ), N, WR, &
                                -WI, X, 2, SCALE, XNORM, IERR )
!
!                    Scale if necessary
!
               IF( SCALE.NE.ONE ) THEN
                  CALL DSCAL( N-KI+1, SCALE, WORK( KI+N ), 1 )
                  CALL DSCAL( N-KI+1, SCALE, WORK( KI+N2 ), 1 )
               END IF
               WORK( J+N ) = X( 1, 1 )
               WORK( J+N2 ) = X( 1, 2 )
               WORK( J+1+N ) = X( 2, 1 )
               WORK( J+1+N2 ) = X( 2, 2 )
               VMAX = MAX( ABS( X( 1, 1 ) ), ABS( X( 1, 2 ) ), &
                          ABS( X( 2, 1 ) ), ABS( X( 2, 2 ) ), VMAX )
               VCRIT = BIGNUM / VMAX
!
            END IF
200          CONTINUE
!
!              Copy the vector x or Q*x to VL and normalize.
!
210          CONTINUE
         IF( .NOT.OVER ) THEN
            CALL DCOPY( N-KI+1, WORK( KI+N ), 1, VL( KI, IS ), 1 )
            CALL DCOPY( N-KI+1, WORK( KI+N2 ), 1, VL( KI, IS+1 ), &
                            1 )
!
            EMAX = ZERO
            DO 220 K = KI, N
               EMAX = MAX( EMAX, ABS( VL( K, IS ) )+ &
                          ABS( VL( K, IS+1 ) ) )
220             CONTINUE
            REMAX = ONE / EMAX
            CALL DSCAL( N-KI+1, REMAX, VL( KI, IS ), 1 )
            CALL DSCAL( N-KI+1, REMAX, VL( KI, IS+1 ), 1 )
!
            DO 230 K = 1, KI - 1
               VL( K, IS ) = ZERO
               VL( K, IS+1 ) = ZERO
230             CONTINUE
         ELSE
            IF( KI.LT.N-1 ) THEN
               CALL DGEMV( 'N', N, N-KI-1, ONE, VL( 1, KI+2 ), &
                               LDVL, WORK( KI+2+N ), 1, WORK( KI+N ), &
                               VL( 1, KI ), 1 )
               CALL DGEMV( 'N', N, N-KI-1, ONE, VL( 1, KI+2 ), &
                               LDVL, WORK( KI+2+N2 ), 1, &
                               WORK( KI+1+N2 ), VL( 1, KI+1 ), 1 )
            ELSE
               CALL DSCAL( N, WORK( KI+N ), VL( 1, KI ), 1 )
               CALL DSCAL( N, WORK( KI+1+N2 ), VL( 1, KI+1 ), 1 )
            END IF
!
            EMAX = ZERO
            DO 240 K = 1, N
               EMAX = MAX( EMAX, ABS( VL( K, KI ) )+ &
                          ABS( VL( K, KI+1 ) ) )
240             CONTINUE
            REMAX = ONE / EMAX
            CALL DSCAL( N, REMAX, VL( 1, KI ), 1 )
            CALL DSCAL( N, REMAX, VL( 1, KI+1 ), 1 )
!
         END IF
!
      END IF
!
      IS = IS + 1
      IF( IP.NE.0 ) &
             IS = IS + 1
250       CONTINUE
      IF( IP.EQ.-1 ) &
             IP = 0
      IF( IP.EQ.1 ) &
             IP = -1
!
260    CONTINUE
!
END IF
!
RETURN
!
!     End of DTREVC
!
end subroutine dtrevc

! ===== End dtrevc.f90 =====


! ===== Begin dtrexc.f90 =====

SUBROUTINE DTREXC( COMPQ, N, T, LDT, Q, LDQ, IFST, ILST, WORK, &
                       INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
CHARACTER          COMPQ
INTEGER            IFST, ILST, INFO, LDQ, LDT, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   Q( LDQ, * ), T( LDT, * ), WORK( * )
!     ..
!
!  Purpose
!  =======
!
!  DTREXC reorders the real Schur factorization of a real matrix
!  A = Q*T*Q**T, so that the diagonal block of T with row index IFST is
!  moved to row ILST.
!
!  The real Schur form T is reordered by an orthogonal similarity
!  transformation Z**T*T*Z, and optionally the matrix Q of Schur vectors
!  is updated by postmultiplying it with Z.
!
!  T must be in Schur canonical form (as returned by DHSEQR), that is,
!  block upper triangular with 1-by-1 and 2-by-2 diagonal blocks; each
!  2-by-2 diagonal block has its diagonal elements equal and its
!  off-diagonal elements of opposite sign.
!
!  Arguments
!  =========
!
!  COMPQ   (input) CHARACTER*1
!          = 'V':  update the matrix Q of Schur vectors;
!          = 'N':  do not update Q.
!
!  N       (input) INTEGER
!          The order of the matrix T. N >= 0.
!
!  T       (input/output) DOUBLE PRECISION array, dimension (LDT,N)
!          On entry, the upper quasi-triangular matrix T, in Schur
!          Schur canonical form.
!          On exit, the reordered upper quasi-triangular matrix, again
!          in Schur canonical form.
!
!  LDT     (input) INTEGER
!          The leading dimension of the array T. LDT >= max(1,N).
!
!  Q       (input/output) DOUBLE PRECISION array, dimension (LDQ,N)
!          On entry, if COMPQ = 'V', the matrix Q of Schur vectors.
!          On exit, if COMPQ = 'V', Q has been postmultiplied by the
!          orthogonal transformation matrix Z which reorders T.
!          If COMPQ = 'N', Q is not referenced.
!
!  LDQ     (input) INTEGER
!          The leading dimension of the array Q.  LDQ >= max(1,N).
!
!  IFST    (input/output) INTEGER
!  ILST    (input/output) INTEGER
!          Specify the reordering of the diagonal blocks of T.
!          The block with row index IFST is moved to row ILST, by a
!          sequence of transpositions between adjacent blocks.
!          On exit, if IFST pointed on entry to the second row of a
!          2-by-2 block, it is changed to point to the first row; ILST
!          always points to the first row of the block in its final
!          position (which may differ from its input value by +1 or -1).
!          1 <= IFST <= N; 1 <= ILST <= N.
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (N)
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0:  if INFO = -i, the i-th argument had an illegal value
!          = 1:  two adjacent blocks were too close to swap (the problem
!                is very ill-conditioned); T may have been partially
!                reordered, and ILST points to the first row of the
!                current position of the block being moved.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO
PARAMETER          ( ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            WANTQ
INTEGER            HERE, NBF, NBL, NBNEXT
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DLAEXC, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Decode and test the input arguments.
!
INFO = 0
WANTQ = LSAME( COMPQ, 'V' )
IF( .NOT.WANTQ .AND. .NOT.LSAME( COMPQ, 'N' ) ) THEN
   INFO = -1
ELSE IF( N.LT.0 ) THEN
   INFO = -2
ELSE IF( LDT.LT.MAX( 1, N ) ) THEN
   INFO = -4
ELSE IF( LDQ.LT.1 .OR. ( WANTQ .AND. LDQ.LT.MAX( 1, N ) ) ) THEN
   INFO = -6
ELSE IF( IFST.LT.1 .OR. IFST.GT.N ) THEN
   INFO = -7
ELSE IF( ILST.LT.1 .OR. ILST.GT.N ) THEN
   INFO = -8
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTREXC', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.LE.1 ) &
       RETURN
!
!     Determine the first row of specified block
!     and find out it is 1 by 1 or 2 by 2.
!
IF( IFST.GT.1 ) THEN
   IF( T( IFST, IFST-1 ).NE.ZERO ) &
          IFST = IFST - 1
END IF
NBF = 1
IF( IFST.LT.N ) THEN
   IF( T( IFST+1, IFST ).NE.ZERO ) &
          NBF = 2
END IF
!
!     Determine the first row of the final block
!     and find out it is 1 by 1 or 2 by 2.
!
IF( ILST.GT.1 ) THEN
   IF( T( ILST, ILST-1 ).NE.ZERO ) &
          ILST = ILST - 1
END IF
NBL = 1
IF( ILST.LT.N ) THEN
   IF( T( ILST+1, ILST ).NE.ZERO ) &
          NBL = 2
END IF
!
IF( IFST.EQ.ILST ) &
       RETURN
!
IF( IFST.LT.ILST ) THEN
!
!        Update ILST
!
   IF( NBF.EQ.2 .AND. NBL.EQ.1 ) &
          ILST = ILST - 1
   IF( NBF.EQ.1 .AND. NBL.EQ.2 ) &
          ILST = ILST + 1
!
   HERE = IFST
!
10    CONTINUE
!
!        Swap block with next one below
!
   IF( NBF.EQ.1 .OR. NBF.EQ.2 ) THEN
!
!           Current block either 1 by 1 or 2 by 2
!
      NBNEXT = 1
      IF( HERE+NBF+1.LE.N ) THEN
         IF( T( HERE+NBF+1, HERE+NBF ).NE.ZERO ) &
                NBNEXT = 2
      END IF
      CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE, NBF, NBNEXT, &
                       WORK, INFO )
      IF( INFO.NE.0 ) THEN
         ILST = HERE
         RETURN
      END IF
      HERE = HERE + NBNEXT
!
!           Test if 2 by 2 block breaks into two 1 by 1 blocks
!
      IF( NBF.EQ.2 ) THEN
         IF( T( HERE+1, HERE ).EQ.ZERO ) &
                NBF = 3
      END IF
!
   ELSE
!
!           Current block consists of two 1 by 1 blocks each of which
!           must be swapped individually
!
      NBNEXT = 1
      IF( HERE+3.LE.N ) THEN
         IF( T( HERE+3, HERE+2 ).NE.ZERO ) &
                NBNEXT = 2
      END IF
      CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE+1, 1, NBNEXT, &
                       WORK, INFO )
      IF( INFO.NE.0 ) THEN
         ILST = HERE
         RETURN
      END IF
      IF( NBNEXT.EQ.1 ) THEN
!
!              Swap two 1 by 1 blocks, no problems possible
!
         CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE, 1, NBNEXT, &
                          WORK, INFO )
         HERE = HERE + 1
      ELSE
!
!              Recompute NBNEXT in case 2 by 2 split
!
         IF( T( HERE+2, HERE+1 ).EQ.ZERO ) &
                NBNEXT = 1
         IF( NBNEXT.EQ.2 ) THEN
!
!                 2 by 2 Block did not split
!
            CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE, 1, &
                             NBNEXT, WORK, INFO )
            IF( INFO.NE.0 ) THEN
               ILST = HERE
               RETURN
            END IF
            HERE = HERE + 2
         ELSE
!
!                 2 by 2 Block did split
!
            CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE, 1, 1, &
                             WORK, INFO )
            CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE+1, 1, 1, &
                             WORK, INFO )
            HERE = HERE + 2
         END IF
      END IF
   END IF
   IF( HERE.LT.ILST ) &
          GO TO 10
!
ELSE
!
   HERE = IFST
20    CONTINUE
!
!        Swap block with next one above
!
   IF( NBF.EQ.1 .OR. NBF.EQ.2 ) THEN
!
!           Current block either 1 by 1 or 2 by 2
!
      NBNEXT = 1
      IF( HERE.GE.3 ) THEN
         IF( T( HERE-1, HERE-2 ).NE.ZERO ) &
                NBNEXT = 2
      END IF
      CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE-NBNEXT, NBNEXT, &
                       NBF, WORK, INFO )
      IF( INFO.NE.0 ) THEN
         ILST = HERE
         RETURN
      END IF
      HERE = HERE - NBNEXT
!
!           Test if 2 by 2 block breaks into two 1 by 1 blocks
!
      IF( NBF.EQ.2 ) THEN
         IF( T( HERE+1, HERE ).EQ.ZERO ) &
                NBF = 3
      END IF
!
   ELSE
!
!           Current block consists of two 1 by 1 blocks each of which
!           must be swapped individually
!
      NBNEXT = 1
      IF( HERE.GE.3 ) THEN
         IF( T( HERE-1, HERE-2 ).NE.ZERO ) &
                NBNEXT = 2
      END IF
      CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE-NBNEXT, NBNEXT, &
                       1, WORK, INFO )
      IF( INFO.NE.0 ) THEN
         ILST = HERE
         RETURN
      END IF
      IF( NBNEXT.EQ.1 ) THEN
!
!              Swap two 1 by 1 blocks, no problems possible
!
         CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE, NBNEXT, 1, &
                          WORK, INFO )
         HERE = HERE - 1
      ELSE
!
!              Recompute NBNEXT in case 2 by 2 split
!
         IF( T( HERE, HERE-1 ).EQ.ZERO ) &
                NBNEXT = 1
         IF( NBNEXT.EQ.2 ) THEN
!
!                 2 by 2 Block did not split
!
            CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE-1, 2, 1, &
                             WORK, INFO )
            IF( INFO.NE.0 ) THEN
               ILST = HERE
               RETURN
            END IF
            HERE = HERE - 2
         ELSE
!
!                 2 by 2 Block did split
!
            CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE, 1, 1, &
                             WORK, INFO )
            CALL DLAEXC( WANTQ, N, T, LDT, Q, LDQ, HERE-1, 1, 1, &
                             WORK, INFO )
            HERE = HERE - 2
         END IF
      END IF
   END IF
   IF( HERE.GT.ILST ) &
          GO TO 20
END IF
ILST = HERE
!
RETURN
!
!     End of DTREXC
!
end subroutine dtrexc

! ===== End dtrexc.f90 =====


! ===== Begin dtrsen.f90 =====

SUBROUTINE DTRSEN( JOB, COMPQ, SELECT, N, T, LDT, Q, LDQ, WR, WI, &
                       M, S, SEP, WORK, LWORK, IWORK, LIWORK, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER          COMPQ, JOB
INTEGER            INFO, LDQ, LDT, LIWORK, LWORK, M, N
DOUBLE PRECISION   S, SEP
!     ..
!     .. Array Arguments ..
LOGICAL            SELECT( * )
INTEGER            IWORK( * )
DOUBLE PRECISION   Q( LDQ, * ), T( LDT, * ), WI( * ), WORK( * ), &
                       WR( * )
!     ..
!
!  Purpose
!  =======
!
!  DTRSEN reorders the real Schur factorization of a real matrix
!  A = Q*T*Q**T, so that a selected cluster of eigenvalues appears in
!  the leading diagonal blocks of the upper quasi-triangular matrix T,
!  and the leading columns of Q form an orthonormal basis of the
!  corresponding right invariant subspace.
!
!  Optionally the routine computes the reciprocal condition numbers of
!  the cluster of eigenvalues and/or the invariant subspace.
!
!  T must be in Schur canonical form (as returned by DHSEQR), that is,
!  block upper triangular with 1-by-1 and 2-by-2 diagonal blocks; each
!  2-by-2 diagonal block has its diagonal elemnts equal and its
!  off-diagonal elements of opposite sign.
!
!  Arguments
!  =========
!
!  JOB     (input) CHARACTER*1
!          Specifies whether condition numbers are required for the
!          cluster of eigenvalues (S) or the invariant subspace (SEP):
!          = 'N': none;
!          = 'E': for eigenvalues only (S);
!          = 'V': for invariant subspace only (SEP);
!          = 'B': for both eigenvalues and invariant subspace (S and
!                 SEP).
!
!  COMPQ   (input) CHARACTER*1
!          = 'V': update the matrix Q of Schur vectors;
!          = 'N': do not update Q.
!
!  SELECT  (input) LOGICAL array, dimension (N)
!          SELECT specifies the eigenvalues in the selected cluster. To
!          select a real eigenvalue w(j), SELECT(j) must be set to
!          .TRUE.. To select a complex conjugate pair of eigenvalues
!          w(j) and w(j+1), corresponding to a 2-by-2 diagonal block,
!          either SELECT(j) or SELECT(j+1) or both must be set to
!          .TRUE.; a complex conjugate pair of eigenvalues must be
!          either both included in the cluster or both excluded.
!
!  N       (input) INTEGER
!          The order of the matrix T. N >= 0.
!
!  T       (input/output) DOUBLE PRECISION array, dimension (LDT,N)
!          On entry, the upper quasi-triangular matrix T, in Schur
!          canonical form.
!          On exit, T is overwritten by the reordered matrix T, again in
!          Schur canonical form, with the selected eigenvalues in the
!          leading diagonal blocks.
!
!  LDT     (input) INTEGER
!          The leading dimension of the array T. LDT >= max(1,N).
!
!  Q       (input/output) DOUBLE PRECISION array, dimension (LDQ,N)
!          On entry, if COMPQ = 'V', the matrix Q of Schur vectors.
!          On exit, if COMPQ = 'V', Q has been postmultiplied by the
!          orthogonal transformation matrix which reorders T; the
!          leading M columns of Q form an orthonormal basis for the
!          specified invariant subspace.
!          If COMPQ = 'N', Q is not referenced.
!
!  LDQ     (input) INTEGER
!          The leading dimension of the array Q.
!          LDQ >= 1; and if COMPQ = 'V', LDQ >= N.
!
!  WR      (output) DOUBLE PRECISION array, dimension (N)
!  WI      (output) DOUBLE PRECISION array, dimension (N)
!          The real and imaginary parts, respectively, of the reordered
!          eigenvalues of T. The eigenvalues are stored in the same
!          order as on the diagonal of T, with WR(i) = T(i,i) and, if
!          T(i:i+1,i:i+1) is a 2-by-2 diagonal block, WI(i) > 0 and
!          WI(i+1) = -WI(i). Note that if a complex eigenvalue is
!          sufficiently ill-conditioned, then its value may differ
!          significantly from its value before reordering.
!
!  M       (output) INTEGER
!          The dimension of the specified invariant subspace.
!          0 < = M <= N.
!
!  S       (output) DOUBLE PRECISION
!          If JOB = 'E' or 'B', S is a lower bound on the reciprocal
!          condition number for the selected cluster of eigenvalues.
!          S cannot underestimate the true reciprocal condition number
!          by more than a factor of sqrt(N). If M = 0 or N, S = 1.
!          If JOB = 'N' or 'V', S is not referenced.
!
!  SEP     (output) DOUBLE PRECISION
!          If JOB = 'V' or 'B', SEP is the estimated reciprocal
!          condition number of the specified invariant subspace. If
!          M = 0 or N, SEP = norm(T).
!          If JOB = 'N' or 'E', SEP is not referenced.
!
!  WORK    (workspace) DOUBLE PRECISION array, dimension (LWORK)
!
!  LWORK   (input) INTEGER
!          The dimension of the array WORK.
!          If JOB = 'N', LWORK >= max(1,N);
!          if JOB = 'E', LWORK >= M*(N-M);
!          if JOB = 'V' or 'B', LWORK >= 2*M*(N-M).
!
!  IWORK   (workspace) INTEGER array, dimension (LIWORK)
!          IF JOB = 'N' or 'E', IWORK is not referenced.
!
!  LIWORK  (input) INTEGER
!          The dimension of the array IWORK.
!          If JOB = 'N' or 'E', LIWORK >= 1;
!          if JOB = 'V' or 'B', LIWORK >= M*(N-M).
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!          = 1: reordering of T failed because some eigenvalues are too
!               close to separate (the problem is very ill-conditioned);
!               T may have been partially reordered, and WR and WI
!               contain the eigenvalues in the same order as in T; S and
!               SEP (if requested) are set to zero.
!
!  Further Details
!  ===============
!
!  DTRSEN first collects the selected eigenvalues by computing an
!  orthogonal transformation Z to move them to the top left corner of T.
!  In other words, the selected eigenvalues are the eigenvalues of T11
!  in:
!
!                Z'*T*Z = ( T11 T12 ) n1
!                         (  0  T22 ) n2
!                            n1  n2
!
!  where N = n1+n2 and Z' means the transpose of Z. The first n1 columns
!  of Z span the specified invariant subspace of T.
!
!  If T has been obtained from the real Schur factorization of a matrix
!  A = Q*T*Q', then the reordered real Schur factorization of A is given
!  by A = (Q*Z)*(Z'*T*Z)*(Q*Z)', and the first n1 columns of Q*Z span
!  the corresponding invariant subspace of A.
!
!  The reciprocal condition number of the average of the eigenvalues of
!  T11 may be returned in S. S lies between 0 (very badly conditioned)
!  and 1 (very well conditioned). It is computed as follows. First we
!  compute R so that
!
!                         P = ( I  R ) n1
!                             ( 0  0 ) n2
!                               n1 n2
!
!  is the projector on the invariant subspace associated with T11.
!  R is the solution of the Sylvester equation:
!
!                        T11*R - R*T22 = T12.
!
!  Let F-norm(M) denote the Frobenius-norm of M and 2-norm(M) denote
!  the two-norm of M. Then S is computed as the lower bound
!
!                      (1 + F-norm(R)**2)**(-1/2)
!
!  on the reciprocal of 2-norm(P), the true reciprocal condition number.
!  S cannot underestimate 1 / 2-norm(P) by more than a factor of
!  sqrt(N).
!
!  An approximate error bound for the computed average of the
!  eigenvalues of T11 is
!
!                         EPS * norm(T) / S
!
!  where EPS is the machine precision.
!
!  The reciprocal condition number of the right invariant subspace
!  spanned by the first n1 columns of Z (or of Q*Z) is returned in SEP.
!  SEP is defined as the separation of T11 and T22:
!
!                     sep( T11, T22 ) = sigma-min( C )
!
!  where sigma-min(C) is the smallest singular value of the
!  n1*n2-by-n1*n2 matrix
!
!     C  = kprod( I(n2), T11 ) - kprod( transpose(T22), I(n1) )
!
!  I(m) is an m by m identity matrix, and kprod denotes the Kronecker
!  product. We estimate sigma-min(C) by the reciprocal of an estimate of
!  the 1-norm of inverse(C). The true reciprocal 1-norm of inverse(C)
!  cannot differ from sigma-min(C) by more than a factor of sqrt(n1*n2).
!
!  When SEP is small, small changes in T can cause large changes in
!  the invariant subspace. An approximate bound on the maximum angular
!  error in the computed right invariant subspace is
!
!                      EPS * norm(T) / SEP
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            PAIR, SWAP, WANTBH, WANTQ, WANTS, WANTSP
INTEGER            IERR, K, KASE, KK, KS, N1, N2, NN
DOUBLE PRECISION   EST, RNORM, SCALE
!     ..
!     .. External Functions ..
LOGICAL            LSAME
DOUBLE PRECISION   DLANGE
EXTERNAL           LSAME, DLANGE
!     ..
!     .. External Subroutines ..
EXTERNAL           DLACON, DLACPY, DTREXC, DTRSYL, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, MAX, SQRT
!     ..
!     .. Executable Statements ..
!
!     Decode and test the input parameters
!
WANTBH = LSAME( JOB, 'B' )
WANTS = LSAME( JOB, 'E' ) .OR. WANTBH
WANTSP = LSAME( JOB, 'V' ) .OR. WANTBH
WANTQ = LSAME( COMPQ, 'V' )
!
INFO = 0
IF( .NOT.LSAME( JOB, 'N' ) .AND. .NOT.WANTS .AND. .NOT.WANTSP ) &
         THEN
   INFO = -1
ELSE IF( .NOT.LSAME( COMPQ, 'N' ) .AND. .NOT.WANTQ ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( LDT.LT.MAX( 1, N ) ) THEN
   INFO = -6
ELSE IF( LDQ.LT.1 .OR. ( WANTQ .AND. LDQ.LT.N ) ) THEN
   INFO = -8
ELSE
!
!        Set M to the dimension of the specified invariant subspace,
!        and test LWORK and LIWORK.
!
   M = 0
   PAIR = .FALSE.
   DO 10 K = 1, N
      IF( PAIR ) THEN
         PAIR = .FALSE.
      ELSE
         IF( K.LT.N ) THEN
            IF( T( K+1, K ).EQ.ZERO ) THEN
               IF( SELECT( K ) ) &
                      M = M + 1
            ELSE
               PAIR = .TRUE.
               IF( SELECT( K ) .OR. SELECT( K+1 ) ) &
                      M = M + 2
            END IF
         ELSE
            IF( SELECT( N ) ) &
                   M = M + 1
         END IF
      END IF
10    CONTINUE
!
   N1 = M
   N2 = N - M
   NN = N1*N2
!
   IF( LWORK.LT.1 .OR. ( ( WANTS .AND. .NOT.WANTSP ) .AND. &
           LWORK.LT.NN ) .OR. ( WANTSP .AND. LWORK.LT.2*NN ) ) THEN
      INFO = -15
   ELSE IF( LIWORK.LT.1 .OR. ( WANTSP .AND. LIWORK.LT.NN ) ) THEN
      INFO = -17
   END IF
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTRSEN', -INFO )
   RETURN
END IF
!
!     Quick return if possible.
!
IF( M.EQ.N .OR. M.EQ.0 ) THEN
   IF( WANTS ) &
          S = ONE
   IF( WANTSP ) &
          SEP = DLANGE( '1', N, N, T, LDT, WORK )
   GO TO 40
END IF
!
!     Collect the selected blocks at the top-left corner of T.
!
KS = 0
PAIR = .FALSE.
DO 20 K = 1, N
   IF( PAIR ) THEN
      PAIR = .FALSE.
   ELSE
      SWAP = SELECT( K )
      IF( K.LT.N ) THEN
         IF( T( K+1, K ).NE.ZERO ) THEN
            PAIR = .TRUE.
            SWAP = SWAP .OR. SELECT( K+1 )
         END IF
      END IF
      IF( SWAP ) THEN
         KS = KS + 1
!
!              Swap the K-th block to position KS.
!
         IERR = 0
         KK = K
         IF( K.NE.KS ) &
                CALL DTREXC( COMPQ, N, T, LDT, Q, LDQ, KK, KS, WORK, &
                             IERR )
         IF( IERR.EQ.1 .OR. IERR.EQ.2 ) THEN
!
!                 Blocks too close to swap: exit.
!
            INFO = 1
            IF( WANTS ) &
                   S = ZERO
            IF( WANTSP ) &
                   SEP = ZERO
            GO TO 40
         END IF
         IF( PAIR ) &
                KS = KS + 1
      END IF
   END IF
20 CONTINUE
!
IF( WANTS ) THEN
!
!        Solve Sylvester equation for R:
!
!           T11*R - R*T22 = scale*T12
!
   CALL DLACPY( 'F', N1, N2, T( 1, N1+1 ), LDT, WORK, N1 )
   CALL DTRSYL( 'N', 'N', -1, N1, N2, T, LDT, T( N1+1, N1+1 ), &
                    LDT, WORK, N1, SCALE, IERR )
!
!        Estimate the reciprocal of the condition number of the cluster
!        of eigenvalues.
!
   RNORM = DLANGE( 'F', N1, N2, WORK, N1, WORK )
   IF( RNORM.EQ.ZERO ) THEN
      S = ONE
   ELSE
      S = SCALE / ( SQRT( SCALE*SCALE / RNORM+RNORM )* &
              SQRT( RNORM ) )
   END IF
END IF
!
IF( WANTSP ) THEN
!
!        Estimate sep(T11,T22).
!
   EST = ZERO
   KASE = 0
30    CONTINUE
   CALL DLACON( NN, WORK( NN+1 ), WORK, IWORK, EST, KASE )
   IF( KASE.NE.0 ) THEN
      IF( KASE.EQ.1 ) THEN
!
!              Solve  T11*R - R*T22 = scale*X.
!
         CALL DTRSYL( 'N', 'N', -1, N1, N2, T, LDT, &
                          T( N1+1, N1+1 ), LDT, WORK, N1, SCALE, &
                          IERR )
      ELSE
!
!              Solve  T11'*R - R*T22' = scale*X.
!
         CALL DTRSYL( 'T', 'T', -1, N1, N2, T, LDT, &
                          T( N1+1, N1+1 ), LDT, WORK, N1, SCALE, &
                          IERR )
      END IF
      GO TO 30
   END IF
!
   SEP = SCALE / EST
END IF
!
40 CONTINUE
!
!     Store the output eigenvalues in WR and WI.
!
DO 50 K = 1, N
   WR( K ) = T( K, K )
   WI( K ) = ZERO
50 CONTINUE
DO 60 K = 1, N - 1
   IF( T( K+1, K ).NE.ZERO ) THEN
      WI( K ) = SQRT( ABS( T( K, K+1 ) ) )* &
                    SQRT( ABS( T( K+1, K ) ) )
      WI( K+1 ) = -WI( K )
   END IF
60 CONTINUE
RETURN
!
!     End of DTRSEN
!
end subroutine dtrsen

! ===== End dtrsen.f90 =====


! ===== Begin dtrsyl.f90 =====

SUBROUTINE DTRSYL( TRANA, TRANB, ISGN, M, N, A, LDA, B, LDB, C, &
                       LDC, SCALE, INFO )
!
!  -- LAPACK routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
CHARACTER          TRANA, TRANB
INTEGER            INFO, ISGN, LDA, LDB, LDC, M, N
DOUBLE PRECISION   SCALE
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), B( LDB, * ), C( LDC, * )
!     ..
!
!  Purpose
!  =======
!
!  DTRSYL solves the real Sylvester matrix equation:
!
!     op(A)*X + X*op(B) = scale*C or
!     op(A)*X - X*op(B) = scale*C,
!
!  where op(A) = A or A**T, and  A and B are both upper quasi-
!  triangular. A is M-by-M and B is N-by-N; the right hand side C and
!  the solution X are M-by-N; and scale is an output scale factor, set
!  <= 1 to avoid overflow in X.
!
!  A and B must be in Schur canonical form (as returned by DHSEQR), that
!  is, block upper triangular with 1-by-1 and 2-by-2 diagonal blocks;
!  each 2-by-2 diagonal block has its diagonal elements equal and its
!  off-diagonal elements of opposite sign.
!
!  Arguments
!  =========
!
!  TRANA   (input) CHARACTER*1
!          Specifies the option op(A):
!          = 'N': op(A) = A    (No transpose)
!          = 'T': op(A) = A**T (Transpose)
!          = 'C': op(A) = A**H (Conjugate transpose = Transpose)
!
!  TRANB   (input) CHARACTER*1
!          Specifies the option op(B):
!          = 'N': op(B) = B    (No transpose)
!          = 'T': op(B) = B**T (Transpose)
!          = 'C': op(B) = B**H (Conjugate transpose = Transpose)
!
!  ISGN    (input) INTEGER
!          Specifies the sign in the equation:
!          = +1: solve op(A)*X + X*op(B) = scale*C
!          = -1: solve op(A)*X - X*op(B) = scale*C
!
!  M       (input) INTEGER
!          The order of the matrix A, and the number of rows in the
!          matrices X and C. M >= 0.
!
!  N       (input) INTEGER
!          The order of the matrix B, and the number of columns in the
!          matrices X and C. N >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,M)
!          The upper quasi-triangular matrix A, in Schur canonical form.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A. LDA >= max(1,M).
!
!  B       (input) DOUBLE PRECISION array, dimension (LDB,N)
!          The upper quasi-triangular matrix B, in Schur canonical form.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B. LDB >= max(1,N).
!
!  C       (input/output) DOUBLE PRECISION array, dimension (LDC,N)
!          On entry, the M-by-N right hand side matrix C.
!          On exit, C is overwritten by the solution matrix X.
!
!  LDC     (input) INTEGER
!          The leading dimension of the array C. LDC >= max(1,M)
!
!  SCALE   (output) DOUBLE PRECISION
!          The scale factor, scale, set <= 1 to avoid overflow in X.
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!          = 1: A and B have common or very close eigenvalues; perturbed
!               values were used to solve the equation (but the matrices
!               A and B are unchanged).
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            NOTRNA, NOTRNB
INTEGER            IERR, J, K, K1, K2, KNEXT, L, L1, L2, LNEXT
DOUBLE PRECISION   A11, BIGNUM, DA11, DB, EPS, SCALOC, SGN, SMIN, &
                       SMLNUM, SUML, SUMR, XNORM
!     ..
!     .. Local Arrays ..
DOUBLE PRECISION   DUM( 1 ), VEC( 2, 2 ), X( 2, 2 )
!     ..
!     .. External Functions ..
LOGICAL            LSAME
DOUBLE PRECISION   DDOT, DLAMCH, DLANGE
EXTERNAL           LSAME, DDOT, DLAMCH, DLANGE
!     ..
!     .. External Subroutines ..
EXTERNAL           DLABAD, DLALN2, DLASY2, DSCAL, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, DBLE, MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Decode and Test input parameters
!
NOTRNA = LSAME( TRANA, 'N' )
NOTRNB = LSAME( TRANB, 'N' )
!
INFO = 0
IF( .NOT.NOTRNA .AND. .NOT.LSAME( TRANA, 'T' ) .AND. .NOT. &
        LSAME( TRANA, 'C' ) ) THEN
   INFO = -1
ELSE IF( .NOT.NOTRNB .AND. .NOT.LSAME( TRANB, 'T' ) .AND. .NOT. &
             LSAME( TRANB, 'C' ) ) THEN
   INFO = -2
ELSE IF( ISGN.NE.1 .AND. ISGN.NE.-1 ) THEN
   INFO = -3
ELSE IF( M.LT.0 ) THEN
   INFO = -4
ELSE IF( N.LT.0 ) THEN
   INFO = -5
ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
   INFO = -7
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -9
ELSE IF( LDC.LT.MAX( 1, M ) ) THEN
   INFO = -11
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTRSYL', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( M.EQ.0 .OR. N.EQ.0 ) &
       RETURN
!
!     Set constants to control overflow
!
EPS = DLAMCH( 'P' )
SMLNUM = DLAMCH( 'S' )
BIGNUM = ONE / SMLNUM
CALL DLABAD( SMLNUM, BIGNUM )
SMLNUM = SMLNUM*DBLE( M*N ) / EPS
BIGNUM = ONE / SMLNUM
!
SMIN = MAX( SMLNUM, EPS*DLANGE( 'M', M, M, A, LDA, DUM ), &
           EPS*DLANGE( 'M', N, N, B, LDB, DUM ) )
!
SCALE = ONE
SGN = ISGN
!
IF( NOTRNA .AND. NOTRNB ) THEN
!
!        Solve    A*X + ISGN*X*B = scale*C.
!
!        The (K,L)th block of X is determined starting from
!        bottom-left corner column by column by
!
!         A(K,K)*X(K,L) + ISGN*X(K,L)*B(L,L) = C(K,L) - R(K,L)
!
!        Where
!                  M                         L-1
!        R(K,L) = SUM [A(K,I)*X(I,L)] + ISGN*SUM [X(K,J)*B(J,L)].
!                I=K+1                       J=1
!
!        Start column loop (index = L)
!        L1 (L2) : column index of the first (first) row of X(K,L).
!
   LNEXT = 1
   DO 60 L = 1, N
      IF( L.LT.LNEXT ) &
             GO TO 60
      IF( L.EQ.N ) THEN
         L1 = L
         L2 = L
      ELSE
         IF( B( L+1, L ).NE.ZERO ) THEN
            L1 = L
            L2 = L + 1
            LNEXT = L + 2
         ELSE
            L1 = L
            L2 = L
            LNEXT = L + 1
         END IF
      END IF
!
!           Start row loop (index = K)
!           K1 (K2): row index of the first (last) row of X(K,L).
!
      KNEXT = M
      DO 50 K = M, 1, -1
         IF( K.GT.KNEXT ) &
                GO TO 50
         IF( K.EQ.1 ) THEN
            K1 = K
            K2 = K
         ELSE
            IF( A( K, K-1 ).NE.ZERO ) THEN
               K1 = K - 1
               K2 = K
               KNEXT = K - 2
            ELSE
               K1 = K
               K2 = K
               KNEXT = K - 1
            END IF
         END IF
!
         IF( L1.EQ.L2 .AND. K1.EQ.K2 ) THEN
            SUML = DDOT( M-K1, A( K1, MIN( K1+1, M ) ), LDA, &
                       C( MIN( K1+1, M ), L1 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
            SCALOC = ONE
!
            A11 = A( K1, K1 ) + SGN*B( L1, L1 )
            DA11 = ABS( A11 )
            IF( DA11.LE.SMIN ) THEN
               A11 = SMIN
               DA11 = SMIN
               INFO = 1
            END IF
            DB = ABS( VEC( 1, 1 ) )
            IF( DA11.LT.ONE .AND. DB.GT.ONE ) THEN
               IF( DB.GT.BIGNUM*DA11 ) &
                      SCALOC = ONE / DB
            END IF
            X( 1, 1 ) = ( VEC( 1, 1 )*SCALOC ) / A11
!
            IF( SCALOC.NE.ONE ) THEN
               DO 10 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
10                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
!
         ELSE IF( L1.EQ.L2 .AND. K1.NE.K2 ) THEN
!
            SUML = DDOT( M-K2, A( K1, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L1 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( M-K2, A( K2, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L1 ), 1 )
            SUMR = DDOT( L1-1, C( K2, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 2, 1 ) = C( K2, L1 ) - ( SUML+SGN*SUMR )
!
            CALL DLALN2( .FALSE., 2, 1, SMIN, ONE, A( K1, K1 ), &
                             LDA, ONE, ONE, VEC, 2, -SGN*B( L1, L1 ), &
                             ZERO, X, 2, SCALOC, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 20 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
20                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K2, L1 ) = X( 2, 1 )
!
         ELSE IF( L1.NE.L2 .AND. K1.EQ.K2 ) THEN
!
            SUML = DDOT( M-K1, A( K1, MIN( K1+1, M ) ), LDA, &
                       C( MIN( K1+1, M ), L1 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 1, 1 ) = SGN*( C( K1, L1 )-( SUML+SGN*SUMR ) )
!
            SUML = DDOT( M-K1, A( K1, MIN( K1+1, M ) ), LDA, &
                       C( MIN( K1+1, M ), L2 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L2 ), 1 )
            VEC( 2, 1 ) = SGN*( C( K1, L2 )-( SUML+SGN*SUMR ) )
!
            CALL DLALN2( .TRUE., 2, 1, SMIN, ONE, B( L1, L1 ), &
                             LDB, ONE, ONE, VEC, 2, -SGN*A( K1, K1 ), &
                             ZERO, X, 2, SCALOC, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 30 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
30                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K1, L2 ) = X( 2, 1 )
!
         ELSE IF( L1.NE.L2 .AND. K1.NE.K2 ) THEN
!
            SUML = DDOT( M-K2, A( K1, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L1 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( M-K2, A( K1, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L2 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L2 ), 1 )
            VEC( 1, 2 ) = C( K1, L2 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( M-K2, A( K2, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L1 ), 1 )
            SUMR = DDOT( L1-1, C( K2, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 2, 1 ) = C( K2, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( M-K2, A( K2, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L2 ), 1 )
            SUMR = DDOT( L1-1, C( K2, 1 ), LDC, B( 1, L2 ), 1 )
            VEC( 2, 2 ) = C( K2, L2 ) - ( SUML+SGN*SUMR )
!
            CALL DLASY2( .FALSE., .FALSE., ISGN, 2, 2, &
                             A( K1, K1 ), LDA, B( L1, L1 ), LDB, VEC, &
                             2, SCALOC, X, 2, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 40 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
40                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K1, L2 ) = X( 1, 2 )
            C( K2, L1 ) = X( 2, 1 )
            C( K2, L2 ) = X( 2, 2 )
         END IF
!
50       CONTINUE
!
60    CONTINUE
!
ELSE IF( .NOT.NOTRNA .AND. NOTRNB ) THEN
!
!        Solve    A' *X + ISGN*X*B = scale*C.
!
!        The (K,L)th block of X is determined starting from
!        upper-left corner column by column by
!
!          A(K,K)'*X(K,L) + ISGN*X(K,L)*B(L,L) = C(K,L) - R(K,L)
!
!        Where
!                   K-1                        L-1
!          R(K,L) = SUM [A(I,K)'*X(I,L)] +ISGN*SUM [X(K,J)*B(J,L)]
!                   I=1                        J=1
!
!        Start column loop (index = L)
!        L1 (L2): column index of the first (last) row of X(K,L)
!
   LNEXT = 1
   DO 120 L = 1, N
      IF( L.LT.LNEXT ) &
             GO TO 120
      IF( L.EQ.N ) THEN
         L1 = L
         L2 = L
      ELSE
         IF( B( L+1, L ).NE.ZERO ) THEN
            L1 = L
            L2 = L + 1
            LNEXT = L + 2
         ELSE
            L1 = L
            L2 = L
            LNEXT = L + 1
         END IF
      END IF
!
!           Start row loop (index = K)
!           K1 (K2): row index of the first (last) row of X(K,L)
!
      KNEXT = 1
      DO 110 K = 1, M
         IF( K.LT.KNEXT ) &
                GO TO 110
         IF( K.EQ.M ) THEN
            K1 = K
            K2 = K
         ELSE
            IF( A( K+1, K ).NE.ZERO ) THEN
               K1 = K
               K2 = K + 1
               KNEXT = K + 2
            ELSE
               K1 = K
               K2 = K
               KNEXT = K + 1
            END IF
         END IF
!
         IF( L1.EQ.L2 .AND. K1.EQ.K2 ) THEN
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
            SCALOC = ONE
!
            A11 = A( K1, K1 ) + SGN*B( L1, L1 )
            DA11 = ABS( A11 )
            IF( DA11.LE.SMIN ) THEN
               A11 = SMIN
               DA11 = SMIN
               INFO = 1
            END IF
            DB = ABS( VEC( 1, 1 ) )
            IF( DA11.LT.ONE .AND. DB.GT.ONE ) THEN
               IF( DB.GT.BIGNUM*DA11 ) &
                      SCALOC = ONE / DB
            END IF
            X( 1, 1 ) = ( VEC( 1, 1 )*SCALOC ) / A11
!
            IF( SCALOC.NE.ONE ) THEN
               DO 70 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
70                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
!
         ELSE IF( L1.EQ.L2 .AND. K1.NE.K2 ) THEN
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( K1-1, A( 1, K2 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( L1-1, C( K2, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 2, 1 ) = C( K2, L1 ) - ( SUML+SGN*SUMR )
!
            CALL DLALN2( .TRUE., 2, 1, SMIN, ONE, A( K1, K1 ), &
                             LDA, ONE, ONE, VEC, 2, -SGN*B( L1, L1 ), &
                             ZERO, X, 2, SCALOC, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 80 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
80                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K2, L1 ) = X( 2, 1 )
!
         ELSE IF( L1.NE.L2 .AND. K1.EQ.K2 ) THEN
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 1, 1 ) = SGN*( C( K1, L1 )-( SUML+SGN*SUMR ) )
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L2 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L2 ), 1 )
            VEC( 2, 1 ) = SGN*( C( K1, L2 )-( SUML+SGN*SUMR ) )
!
            CALL DLALN2( .TRUE., 2, 1, SMIN, ONE, B( L1, L1 ), &
                             LDB, ONE, ONE, VEC, 2, -SGN*A( K1, K1 ), &
                             ZERO, X, 2, SCALOC, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 90 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
90                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K1, L2 ) = X( 2, 1 )
!
         ELSE IF( L1.NE.L2 .AND. K1.NE.K2 ) THEN
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L2 ), 1 )
            SUMR = DDOT( L1-1, C( K1, 1 ), LDC, B( 1, L2 ), 1 )
            VEC( 1, 2 ) = C( K1, L2 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( K1-1, A( 1, K2 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( L1-1, C( K2, 1 ), LDC, B( 1, L1 ), 1 )
            VEC( 2, 1 ) = C( K2, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( K1-1, A( 1, K2 ), 1, C( 1, L2 ), 1 )
            SUMR = DDOT( L1-1, C( K2, 1 ), LDC, B( 1, L2 ), 1 )
            VEC( 2, 2 ) = C( K2, L2 ) - ( SUML+SGN*SUMR )
!
            CALL DLASY2( .TRUE., .FALSE., ISGN, 2, 2, A( K1, K1 ), &
                             LDA, B( L1, L1 ), LDB, VEC, 2, SCALOC, X, &
                             2, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 100 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
100                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K1, L2 ) = X( 1, 2 )
            C( K2, L1 ) = X( 2, 1 )
            C( K2, L2 ) = X( 2, 2 )
         END IF
!
110       CONTINUE
120    CONTINUE
!
ELSE IF( .NOT.NOTRNA .AND. .NOT.NOTRNB ) THEN
!
!        Solve    A'*X + ISGN*X*B' = scale*C.
!
!        The (K,L)th block of X is determined starting from
!        top-right corner column by column by
!
!           A(K,K)'*X(K,L) + ISGN*X(K,L)*B(L,L)' = C(K,L) - R(K,L)
!
!        Where
!                     K-1                          N
!            R(K,L) = SUM [A(I,K)'*X(I,L)] + ISGN*SUM [X(K,J)*B(L,J)'].
!                     I=1                        J=L+1
!
!        Start column loop (index = L)
!        L1 (L2): column index of the first (last) row of X(K,L)
!
   LNEXT = N
   DO 180 L = N, 1, -1
      IF( L.GT.LNEXT ) &
             GO TO 180
      IF( L.EQ.1 ) THEN
         L1 = L
         L2 = L
      ELSE
         IF( B( L, L-1 ).NE.ZERO ) THEN
            L1 = L - 1
            L2 = L
            LNEXT = L - 2
         ELSE
            L1 = L
            L2 = L
            LNEXT = L - 1
         END IF
      END IF
!
!           Start row loop (index = K)
!           K1 (K2): row index of the first (last) row of X(K,L)
!
      KNEXT = 1
      DO 170 K = 1, M
         IF( K.LT.KNEXT ) &
                GO TO 170
         IF( K.EQ.M ) THEN
            K1 = K
            K2 = K
         ELSE
            IF( A( K+1, K ).NE.ZERO ) THEN
               K1 = K
               K2 = K + 1
               KNEXT = K + 2
            ELSE
               K1 = K
               K2 = K
               KNEXT = K + 1
            END IF
         END IF
!
         IF( L1.EQ.L2 .AND. K1.EQ.K2 ) THEN
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( N-L1, C( K1, MIN( L1+1, N ) ), LDC, &
                       B( L1, MIN( L1+1, N ) ), LDB )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
            SCALOC = ONE
!
            A11 = A( K1, K1 ) + SGN*B( L1, L1 )
            DA11 = ABS( A11 )
            IF( DA11.LE.SMIN ) THEN
               A11 = SMIN
               DA11 = SMIN
               INFO = 1
            END IF
            DB = ABS( VEC( 1, 1 ) )
            IF( DA11.LT.ONE .AND. DB.GT.ONE ) THEN
               IF( DB.GT.BIGNUM*DA11 ) &
                      SCALOC = ONE / DB
            END IF
            X( 1, 1 ) = ( VEC( 1, 1 )*SCALOC ) / A11
!
            IF( SCALOC.NE.ONE ) THEN
               DO 130 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
130                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
!
         ELSE IF( L1.EQ.L2 .AND. K1.NE.K2 ) THEN
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( K1-1, A( 1, K2 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( N-L2, C( K2, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 2, 1 ) = C( K2, L1 ) - ( SUML+SGN*SUMR )
!
            CALL DLALN2( .TRUE., 2, 1, SMIN, ONE, A( K1, K1 ), &
                             LDA, ONE, ONE, VEC, 2, -SGN*B( L1, L1 ), &
                             ZERO, X, 2, SCALOC, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 140 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
140                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K2, L1 ) = X( 2, 1 )
!
         ELSE IF( L1.NE.L2 .AND. K1.EQ.K2 ) THEN
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 1, 1 ) = SGN*( C( K1, L1 )-( SUML+SGN*SUMR ) )
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L2 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L2, MIN( L2+1, N ) ), LDB )
            VEC( 2, 1 ) = SGN*( C( K1, L2 )-( SUML+SGN*SUMR ) )
!
            CALL DLALN2( .FALSE., 2, 1, SMIN, ONE, B( L1, L1 ), &
                             LDB, ONE, ONE, VEC, 2, -SGN*A( K1, K1 ), &
                             ZERO, X, 2, SCALOC, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 150 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
150                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K1, L2 ) = X( 2, 1 )
!
         ELSE IF( L1.NE.L2 .AND. K1.NE.K2 ) THEN
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( K1-1, A( 1, K1 ), 1, C( 1, L2 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L2, MIN( L2+1, N ) ), LDB )
            VEC( 1, 2 ) = C( K1, L2 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( K1-1, A( 1, K2 ), 1, C( 1, L1 ), 1 )
            SUMR = DDOT( N-L2, C( K2, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 2, 1 ) = C( K2, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( K1-1, A( 1, K2 ), 1, C( 1, L2 ), 1 )
            SUMR = DDOT( N-L2, C( K2, MIN( L2+1, N ) ), LDC, &
                       B( L2, MIN( L2+1, N ) ), LDB )
            VEC( 2, 2 ) = C( K2, L2 ) - ( SUML+SGN*SUMR )
!
            CALL DLASY2( .TRUE., .TRUE., ISGN, 2, 2, A( K1, K1 ), &
                             LDA, B( L1, L1 ), LDB, VEC, 2, SCALOC, X, &
                             2, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 160 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
160                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K1, L2 ) = X( 1, 2 )
            C( K2, L1 ) = X( 2, 1 )
            C( K2, L2 ) = X( 2, 2 )
         END IF
!
170       CONTINUE
180    CONTINUE
!
ELSE IF( NOTRNA .AND. .NOT.NOTRNB ) THEN
!
!        Solve    A*X + ISGN*X*B' = scale*C.
!
!        The (K,L)th block of X is determined starting from
!        bottom-right corner column by column by
!
!            A(K,K)*X(K,L) + ISGN*X(K,L)*B(L,L)' = C(K,L) - R(K,L)
!
!        Where
!                      M                          N
!            R(K,L) = SUM [A(K,I)*X(I,L)] + ISGN*SUM [X(K,J)*B(L,J)'].
!                    I=K+1                      J=L+1
!
!        Start column loop (index = L)
!        L1 (L2): column index of the first (last) row of X(K,L)
!
   LNEXT = N
   DO 240 L = N, 1, -1
      IF( L.GT.LNEXT ) &
             GO TO 240
      IF( L.EQ.1 ) THEN
         L1 = L
         L2 = L
      ELSE
         IF( B( L, L-1 ).NE.ZERO ) THEN
            L1 = L - 1
            L2 = L
            LNEXT = L - 2
         ELSE
            L1 = L
            L2 = L
            LNEXT = L - 1
         END IF
      END IF
!
!           Start row loop (index = K)
!           K1 (K2): row index of the first (last) row of X(K,L)
!
      KNEXT = M
      DO 230 K = M, 1, -1
         IF( K.GT.KNEXT ) &
                GO TO 230
         IF( K.EQ.1 ) THEN
            K1 = K
            K2 = K
         ELSE
            IF( A( K, K-1 ).NE.ZERO ) THEN
               K1 = K - 1
               K2 = K
               KNEXT = K - 2
            ELSE
               K1 = K
               K2 = K
               KNEXT = K - 1
            END IF
         END IF
!
         IF( L1.EQ.L2 .AND. K1.EQ.K2 ) THEN
            SUML = DDOT( M-K1, A( K1, MIN( K1+1, M ) ), LDA, &
                       C( MIN( K1+1, M ), L1 ), 1 )
            SUMR = DDOT( N-L1, C( K1, MIN( L1+1, N ) ), LDC, &
                       B( L1, MIN( L1+1, N ) ), LDB )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
            SCALOC = ONE
!
            A11 = A( K1, K1 ) + SGN*B( L1, L1 )
            DA11 = ABS( A11 )
            IF( DA11.LE.SMIN ) THEN
               A11 = SMIN
               DA11 = SMIN
               INFO = 1
            END IF
            DB = ABS( VEC( 1, 1 ) )
            IF( DA11.LT.ONE .AND. DB.GT.ONE ) THEN
               IF( DB.GT.BIGNUM*DA11 ) &
                      SCALOC = ONE / DB
            END IF
            X( 1, 1 ) = ( VEC( 1, 1 )*SCALOC ) / A11
!
            IF( SCALOC.NE.ONE ) THEN
               DO 190 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
190                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
!
         ELSE IF( L1.EQ.L2 .AND. K1.NE.K2 ) THEN
!
            SUML = DDOT( M-K2, A( K1, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L1 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( M-K2, A( K2, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L1 ), 1 )
            SUMR = DDOT( N-L2, C( K2, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 2, 1 ) = C( K2, L1 ) - ( SUML+SGN*SUMR )
!
            CALL DLALN2( .FALSE., 2, 1, SMIN, ONE, A( K1, K1 ), &
                             LDA, ONE, ONE, VEC, 2, -SGN*B( L1, L1 ), &
                             ZERO, X, 2, SCALOC, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 200 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
200                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K2, L1 ) = X( 2, 1 )
!
         ELSE IF( L1.NE.L2 .AND. K1.EQ.K2 ) THEN
!
            SUML = DDOT( M-K1, A( K1, MIN( K1+1, M ) ), LDA, &
                       C( MIN( K1+1, M ), L1 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 1, 1 ) = SGN*( C( K1, L1 )-( SUML+SGN*SUMR ) )
!
            SUML = DDOT( M-K1, A( K1, MIN( K1+1, M ) ), LDA, &
                       C( MIN( K1+1, M ), L2 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L2, MIN( L2+1, N ) ), LDB )
            VEC( 2, 1 ) = SGN*( C( K1, L2 )-( SUML+SGN*SUMR ) )
!
            CALL DLALN2( .FALSE., 2, 1, SMIN, ONE, B( L1, L1 ), &
                             LDB, ONE, ONE, VEC, 2, -SGN*A( K1, K1 ), &
                             ZERO, X, 2, SCALOC, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 210 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
210                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K1, L2 ) = X( 2, 1 )
!
         ELSE IF( L1.NE.L2 .AND. K1.NE.K2 ) THEN
!
            SUML = DDOT( M-K2, A( K1, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L1 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 1, 1 ) = C( K1, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( M-K2, A( K1, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L2 ), 1 )
            SUMR = DDOT( N-L2, C( K1, MIN( L2+1, N ) ), LDC, &
                       B( L2, MIN( L2+1, N ) ), LDB )
            VEC( 1, 2 ) = C( K1, L2 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( M-K2, A( K2, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L1 ), 1 )
            SUMR = DDOT( N-L2, C( K2, MIN( L2+1, N ) ), LDC, &
                       B( L1, MIN( L2+1, N ) ), LDB )
            VEC( 2, 1 ) = C( K2, L1 ) - ( SUML+SGN*SUMR )
!
            SUML = DDOT( M-K2, A( K2, MIN( K2+1, M ) ), LDA, &
                       C( MIN( K2+1, M ), L2 ), 1 )
            SUMR = DDOT( N-L2, C( K2, MIN( L2+1, N ) ), LDC, &
                       B( L2, MIN( L2+1, N ) ), LDB )
            VEC( 2, 2 ) = C( K2, L2 ) - ( SUML+SGN*SUMR )
!
            CALL DLASY2( .FALSE., .TRUE., ISGN, 2, 2, A( K1, K1 ), &
                             LDA, B( L1, L1 ), LDB, VEC, 2, SCALOC, X, &
                             2, XNORM, IERR )
            IF( IERR.NE.0 ) &
                   INFO = 1
!
            IF( SCALOC.NE.ONE ) THEN
               DO 220 J = 1, N
                  CALL DSCAL( M, SCALOC, C( 1, J ), 1 )
220                CONTINUE
               SCALE = SCALE*SCALOC
            END IF
            C( K1, L1 ) = X( 1, 1 )
            C( K1, L2 ) = X( 1, 2 )
            C( K2, L1 ) = X( 2, 1 )
            C( K2, L2 ) = X( 2, 2 )
         END IF
!
230       CONTINUE
240    CONTINUE
!
END IF
!
RETURN
!
!     End of DTRSYL
!
end subroutine dtrsyl

! ===== End dtrsyl.f90 =====


! ===== Begin dtrti2.f90 =====

SUBROUTINE DTRTI2( UPLO, DIAG, N, A, LDA, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
CHARACTER          DIAG, UPLO
INTEGER            INFO, LDA, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DTRTI2 computes the inverse of a real upper or lower triangular
!  matrix.
!
!  This is the Level 2 BLAS version of the algorithm.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          Specifies whether the matrix A is upper or lower triangular.
!          = 'U':  Upper triangular
!          = 'L':  Lower triangular
!
!  DIAG    (input) CHARACTER*1
!          Specifies whether or not the matrix A is unit triangular.
!          = 'N':  Non-unit triangular
!          = 'U':  Unit triangular
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the triangular matrix A.  If UPLO = 'U', the
!          leading n by n upper triangular part of the array A contains
!          the upper triangular matrix, and the strictly lower
!          triangular part of A is not referenced.  If UPLO = 'L', the
!          leading n by n lower triangular part of the array A contains
!          the lower triangular matrix, and the strictly upper
!          triangular part of A is not referenced.  If DIAG = 'U', the
!          diagonal elements of A are also not referenced and are
!          assumed to be 1.
!
!          On exit, the (triangular) inverse of the original matrix, in
!          the same storage format.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -k, the k-th argument had an illegal value
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE
PARAMETER          ( ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            NOUNIT, UPPER
INTEGER            J
DOUBLE PRECISION   AJJ
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DSCAL, DTRMV, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
UPPER = LSAME( UPLO, 'U' )
NOUNIT = LSAME( DIAG, 'N' )
IF( .NOT.UPPER .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( .NOT.NOUNIT .AND. .NOT.LSAME( DIAG, 'U' ) ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -5
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTRTI2', -INFO )
   RETURN
END IF
!
IF( UPPER ) THEN
!
!        Compute inverse of upper triangular matrix.
!
   DO 10 J = 1, N
      IF( NOUNIT ) THEN
         A( J, J ) = ONE / A( J, J )
         AJJ = -A( J, J )
      ELSE
         AJJ = -ONE
      END IF
!
!           Compute elements 1:j-1 of j-th column.
!
      CALL DTRMV( 'Upper', 'No transpose', DIAG, J-1, A, LDA, &
                      A( 1, J ), 1 )
      CALL DSCAL( J-1, AJJ, A( 1, J ), 1 )
10    CONTINUE
ELSE
!
!        Compute inverse of lower triangular matrix.
!
   DO 20 J = N, 1, -1
      IF( NOUNIT ) THEN
         A( J, J ) = ONE / A( J, J )
         AJJ = -A( J, J )
      ELSE
         AJJ = -ONE
      END IF
      IF( J.LT.N ) THEN
!
!              Compute elements j+1:n of j-th column.
!
         CALL DTRMV( 'Lower', 'No transpose', DIAG, N-J, &
                         A( J+1, J+1 ), LDA, A( J+1, J ), 1 )
         CALL DSCAL( N-J, AJJ, A( J+1, J ), 1 )
      END IF
20    CONTINUE
END IF
!
RETURN
!
!     End of DTRTI2
!
end subroutine dtrti2

! ===== End dtrti2.f90 =====


! ===== Begin dtrtri.f90 =====

SUBROUTINE DTRTRI( UPLO, DIAG, N, A, LDA, INFO )
!
!  -- LAPACK routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     March 31, 1993
!
!     .. Scalar Arguments ..
CHARACTER          DIAG, UPLO
INTEGER            INFO, LDA, N
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * )
!     ..
!
!  Purpose
!  =======
!
!  DTRTRI computes the inverse of a real upper or lower triangular
!  matrix A.
!
!  This is the Level 3 BLAS version of the algorithm.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  A is upper triangular;
!          = 'L':  A is lower triangular.
!
!  DIAG    (input) CHARACTER*1
!          = 'N':  A is non-unit triangular;
!          = 'U':  A is unit triangular.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the triangular matrix A.  If UPLO = 'U', the
!          leading N-by-N upper triangular part of the array A contains
!          the upper triangular matrix, and the strictly lower
!          triangular part of A is not referenced.  If UPLO = 'L', the
!          leading N-by-N lower triangular part of the array A contains
!          the lower triangular matrix, and the strictly upper
!          triangular part of A is not referenced.  If DIAG = 'U', the
!          diagonal elements of A are also not referenced and are
!          assumed to be 1.
!          On exit, the (triangular) inverse of the original matrix, in
!          the same storage format.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0: successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!          > 0: if INFO = i, A(i,i) is exactly zero.  The triangular
!               matrix is singular and its inverse can not be computed.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ONE, ZERO
PARAMETER          ( ONE = 1.0D+0, ZERO = 0.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            NOUNIT, UPPER
INTEGER            J, JB, NB, NN
!     ..
!     .. External Functions ..
LOGICAL            LSAME
INTEGER            ILAENV
EXTERNAL           LSAME, ILAENV
!     ..
!     .. External Subroutines ..
EXTERNAL           DTRMM, DTRSM, DTRTI2, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX, MIN
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
UPPER = LSAME( UPLO, 'U' )
NOUNIT = LSAME( DIAG, 'N' )
IF( .NOT.UPPER .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( .NOT.NOUNIT .AND. .NOT.LSAME( DIAG, 'U' ) ) THEN
   INFO = -2
ELSE IF( N.LT.0 ) THEN
   INFO = -3
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -5
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTRTRI', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Check for singularity if non-unit.
!
IF( NOUNIT ) THEN
   DO 10 INFO = 1, N
      IF( A( INFO, INFO ).EQ.ZERO ) &
             RETURN
10    CONTINUE
   INFO = 0
END IF
!
!     Determine the block size for this environment.
!
NB = ILAENV( 1, 'DTRTRI', UPLO // DIAG, N, -1, -1, -1 )
IF( NB.LE.1 .OR. NB.GE.N ) THEN
!
!        Use unblocked code
!
   CALL DTRTI2( UPLO, DIAG, N, A, LDA, INFO )
ELSE
!
!        Use blocked code
!
   IF( UPPER ) THEN
!
!           Compute inverse of upper triangular matrix
!
      DO 20 J = 1, N, NB
         JB = MIN( NB, N-J+1 )
!
!              Compute rows 1:j-1 of current block column
!
         CALL DTRMM( 'Left', 'Upper', 'No transpose', DIAG, J-1, &
                         JB, ONE, A, LDA, A( 1, J ), LDA )
         CALL DTRSM( 'Right', 'Upper', 'No transpose', DIAG, J-1, &
                         JB, -ONE, A( J, J ), LDA, A( 1, J ), LDA )
!
!              Compute inverse of current diagonal block
!
         CALL DTRTI2( 'Upper', DIAG, JB, A( J, J ), LDA, INFO )
20       CONTINUE
   ELSE
!
!           Compute inverse of lower triangular matrix
!
      NN = ( ( N-1 ) / NB )*NB + 1
      DO 30 J = NN, 1, -NB
         JB = MIN( NB, N-J+1 )
         IF( J+JB.LE.N ) THEN
!
!                 Compute rows j+jb:n of current block column
!
            CALL DTRMM( 'Left', 'Lower', 'No transpose', DIAG, &
                            N-J-JB+1, JB, ONE, A( J+JB, J+JB ), LDA, &
                            A( J+JB, J ), LDA )
            CALL DTRSM( 'Right', 'Lower', 'No transpose', DIAG, &
                            N-J-JB+1, JB, -ONE, A( J, J ), LDA, &
                            A( J+JB, J ), LDA )
         END IF
!
!              Compute inverse of current diagonal block
!
         CALL DTRTI2( 'Lower', DIAG, JB, A( J, J ), LDA, INFO )
30       CONTINUE
   END IF
END IF
!
RETURN
!
!     End of DTRTRI
!
end subroutine dtrtri

! ===== End dtrtri.f90 =====


! ===== Begin dtrtrs.f90 =====

SUBROUTINE DTRTRS( UPLO, TRANS, DIAG, N, NRHS, A, LDA, B, LDB, &
                       INFO )
!
!  -- LAPACK routine (version 3.1) --
!     Univ. of Tennessee, Univ. of California Berkeley and NAG Ltd..
!     November 2006
!
!     .. Scalar Arguments ..
CHARACTER          DIAG, TRANS, UPLO
INTEGER            INFO, LDA, LDB, N, NRHS
!     ..
!     .. Array Arguments ..
DOUBLE PRECISION   A( LDA, * ), B( LDB, * )
!     ..
!
!  Purpose
!  =======
!
!  DTRTRS solves a triangular system of the form
!
!     A * X = B  or  A**T * X = B,
!
!  where A is a triangular matrix of order N, and B is an N-by-NRHS
!  matrix.  A check is made to verify that A is nonsingular.
!
!  Arguments
!  =========
!
!  UPLO    (input) CHARACTER*1
!          = 'U':  A is upper triangular;
!          = 'L':  A is lower triangular.
!
!  TRANS   (input) CHARACTER*1
!          Specifies the form of the system of equations:
!          = 'N':  A * X = B  (No transpose)
!          = 'T':  A**T * X = B  (Transpose)
!          = 'C':  A**H * X = B  (Conjugate transpose = Transpose)
!
!  DIAG    (input) CHARACTER*1
!          = 'N':  A is non-unit triangular;
!          = 'U':  A is unit triangular.
!
!  N       (input) INTEGER
!          The order of the matrix A.  N >= 0.
!
!  NRHS    (input) INTEGER
!          The number of right hand sides, i.e., the number of columns
!          of the matrix B.  NRHS >= 0.
!
!  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
!          The triangular matrix A.  If UPLO = 'U', the leading N-by-N
!          upper triangular part of the array A contains the upper
!          triangular matrix, and the strictly lower triangular part of
!          A is not referenced.  If UPLO = 'L', the leading N-by-N lower
!          triangular part of the array A contains the lower triangular
!          matrix, and the strictly upper triangular part of A is not
!          referenced.  If DIAG = 'U', the diagonal elements of A are
!          also not referenced and are assumed to be 1.
!
!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).
!
!  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
!          On entry, the right hand side matrix B.
!          On exit, if INFO = 0, the solution matrix X.
!
!  LDB     (input) INTEGER
!          The leading dimension of the array B.  LDB >= max(1,N).
!
!  INFO    (output) INTEGER
!          = 0:  successful exit
!          < 0: if INFO = -i, the i-th argument had an illegal value
!          > 0: if INFO = i, the i-th diagonal element of A is zero,
!               indicating that the matrix is singular and the solutions
!               X have not been computed.
!
!  =====================================================================
!
!     .. Parameters ..
DOUBLE PRECISION   ZERO, ONE
PARAMETER          ( ZERO = 0.0D+0, ONE = 1.0D+0 )
!     ..
!     .. Local Scalars ..
LOGICAL            NOUNIT
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. External Subroutines ..
EXTERNAL           DTRSM, XERBLA
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          MAX
!     ..
!     .. Executable Statements ..
!
!     Test the input parameters.
!
INFO = 0
NOUNIT = LSAME( DIAG, 'N' )
IF( .NOT.LSAME( UPLO, 'U' ) .AND. .NOT.LSAME( UPLO, 'L' ) ) THEN
   INFO = -1
ELSE IF( .NOT.LSAME( TRANS, 'N' ) .AND. .NOT. &
             LSAME( TRANS, 'T' ) .AND. .NOT.LSAME( TRANS, 'C' ) ) THEN
   INFO = -2
ELSE IF( .NOT.NOUNIT .AND. .NOT.LSAME( DIAG, 'U' ) ) THEN
   INFO = -3
ELSE IF( N.LT.0 ) THEN
   INFO = -4
ELSE IF( NRHS.LT.0 ) THEN
   INFO = -5
ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
   INFO = -7
ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
   INFO = -9
END IF
IF( INFO.NE.0 ) THEN
   CALL XERBLA( 'DTRTRS', -INFO )
   RETURN
END IF
!
!     Quick return if possible
!
IF( N.EQ.0 ) &
       RETURN
!
!     Check for singularity.
!
IF( NOUNIT ) THEN
   DO 10 INFO = 1, N
      IF( A( INFO, INFO ).EQ.ZERO ) &
             RETURN
10    CONTINUE
END IF
INFO = 0
!
!     Solve A * x = b  or  A' * x = b.
!
CALL DTRSM( 'Left', UPLO, TRANS, DIAG, N, NRHS, ONE, A, LDA, B, &
                LDB )
!
RETURN
!
!     End of DTRTRS
!
end subroutine dtrtrs

! ===== End dtrtrs.f90 =====


! ===== Begin dzsum1.f90 =====

DOUBLE PRECISION FUNCTION DZSUM1( N, CX, INCX )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     October 31, 1992
!
!     .. Scalar Arguments ..
INTEGER            INCX, N
!     ..
!     .. Array Arguments ..
COMPLEX*16         CX( * )
!     ..
!
!  Purpose
!  =======
!
!  DZSUM1 takes the sum of the absolute values of a complex
!  vector and returns a double precision result.
!
!  Based on DZASUM from the Level 1 BLAS.
!  The change is to use the 'genuine' absolute value.
!
!  Contributed by Nick Higham for use with ZLACON.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of elements in the vector CX.
!
!  CX      (input) COMPLEX*16 array, dimension (N)
!          The vector whose elements will be summed.
!
!  INCX    (input) INTEGER
!          The spacing between successive values of CX.  INCX > 0.
!
!  =====================================================================
!
!     .. Local Scalars ..
INTEGER            I, NINCX
DOUBLE PRECISION   STEMP
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS
!     ..
!     .. Executable Statements ..
!
DZSUM1 = 0.0D0
STEMP = 0.0D0
IF( N.LE.0 ) &
       RETURN
IF( INCX.EQ.1 ) &
       GO TO 20
!
!     CODE FOR INCREMENT NOT EQUAL TO 1
!
NINCX = N*INCX
DO 10 I = 1, NINCX, INCX
!
!        NEXT LINE MODIFIED.
!
   STEMP = STEMP + ABS( CX( I ) )
10 CONTINUE
DZSUM1 = STEMP
RETURN
!
!     CODE FOR INCREMENT EQUAL TO 1
!
20 CONTINUE
DO 30 I = 1, N
!
!        NEXT LINE MODIFIED.
!
   STEMP = STEMP + ABS( CX( I ) )
30 CONTINUE
DZSUM1 = STEMP
RETURN
!
!     End of DZSUM1
!
end function dzsum1

! ===== End dzsum1.f90 =====


! ===== Begin icmax1.f90 =====

INTEGER          FUNCTION ICMAX1( N, CX, INCX )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
INTEGER            INCX, N
!     ..
!     .. Array Arguments ..
COMPLEX            CX( * )
!     ..
!
!  Purpose
!  =======
!
!  ICMAX1 finds the index of the element whose real part has maximum
!  absolute value.
!
!  Based on ICAMAX from Level 1 BLAS.
!  The change is to use the 'genuine' absolute value.
!
!  Contributed by Nick Higham for use with CLACON.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of elements in the vector CX.
!
!  CX      (input) COMPLEX array, dimension (N)
!          The vector whose elements will be summed.
!
!  INCX    (input) INTEGER
!          The spacing between successive values of CX.  INCX >= 1.
!
! =====================================================================
!
!     .. Local Scalars ..
INTEGER            I, IX
REAL               SMAX
COMPLEX            ZDUM
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, REAL
!     ..
!     .. Statement Functions ..
REAL               CABS1
!     ..
!     .. Statement Function definitions ..
!
!     NEXT LINE IS THE ONLY MODIFICATION.
CABS1( ZDUM ) = ABS( REAL( ZDUM ) )
!     ..
!     .. Executable Statements ..
!
ICMAX1 = 0
IF( N.LT.1 ) &
       RETURN
ICMAX1 = 1
IF( N.EQ.1 ) &
       RETURN
IF( INCX.EQ.1 ) &
       GO TO 30
!
!     CODE FOR INCREMENT NOT EQUAL TO 1
!
IX = 1
SMAX = CABS1( CX( 1 ) )
IX = IX + INCX
DO 20 I = 2, N
   IF( CABS1( CX( IX ) ).LE.SMAX ) &
          GO TO 10
   ICMAX1 = I
   SMAX = CABS1( CX( IX ) )
10    CONTINUE
   IX = IX + INCX
20 CONTINUE
RETURN
!
!     CODE FOR INCREMENT EQUAL TO 1
!
30 CONTINUE
SMAX = CABS1( CX( 1 ) )
DO 40 I = 2, N
   IF( CABS1( CX( I ) ).LE.SMAX ) &
          GO TO 40
   ICMAX1 = I
   SMAX = CABS1( CX( I ) )
40 CONTINUE
RETURN
!
!     End of ICMAX1
!
end function icmax1

! ===== End icmax1.f90 =====


! ===== Begin ieeeck.f90 =====

INTEGER          FUNCTION IEEECK( ISPEC, ZERO, ONE )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1998
!
!     .. Scalar Arguments ..
INTEGER            ISPEC
REAL               ONE, ZERO
!     ..
!
!  Purpose
!  =======
!
!  IEEECK is called from the ILAENV to verify that Infinity and
!  possibly NaN arithmetic is safe (i.e. will not trap).
!
!  Arguments
!  =========
!
!  ISPEC   (input) INTEGER
!          Specifies whether to test just for inifinity arithmetic
!          or whether to test for infinity and NaN arithmetic.
!          = 0: Verify infinity arithmetic only.
!          = 1: Verify infinity and NaN arithmetic.
!
!  ZERO    (input) REAL
!          Must contain the value 0.0
!          This is passed to prevent the compiler from optimizing
!          away this code.
!
!  ONE     (input) REAL
!          Must contain the value 1.0
!          This is passed to prevent the compiler from optimizing
!          away this code.
!
!  RETURN VALUE:  INTEGER
!          = 0:  Arithmetic failed to produce the correct answers
!          = 1:  Arithmetic produced the correct answers
!
!     .. Local Scalars ..
REAL               NAN1, NAN2, NAN3, NAN4, NAN5, NAN6, NEGINF, &
                       NEGZRO, NEWZRO, POSINF
!     ..
!     .. Executable Statements ..
IEEECK = 1
!
POSINF = ONE / ZERO
IF( POSINF.LE.ONE ) THEN
   IEEECK = 0
   RETURN
END IF
!
NEGINF = -ONE / ZERO
IF( NEGINF.GE.ZERO ) THEN
   IEEECK = 0
   RETURN
END IF
!
NEGZRO = ONE / ( NEGINF+ONE )
IF( NEGZRO.NE.ZERO ) THEN
   IEEECK = 0
   RETURN
END IF
!
NEGINF = ONE / NEGZRO
IF( NEGINF.GE.ZERO ) THEN
   IEEECK = 0
   RETURN
END IF
!
NEWZRO = NEGZRO + ZERO
IF( NEWZRO.NE.ZERO ) THEN
   IEEECK = 0
   RETURN
END IF
!
POSINF = ONE / NEWZRO
IF( POSINF.LE.ONE ) THEN
   IEEECK = 0
   RETURN
END IF
!
NEGINF = NEGINF*POSINF
IF( NEGINF.GE.ZERO ) THEN
   IEEECK = 0
   RETURN
END IF
!
POSINF = POSINF*POSINF
IF( POSINF.LE.ONE ) THEN
   IEEECK = 0
   RETURN
END IF
!
!
!
!
!     Return if we were only asked to check infinity arithmetic
!
IF( ISPEC.EQ.0 ) &
       RETURN
!
NAN1 = POSINF + NEGINF
!
NAN2 = POSINF / NEGINF
!
NAN3 = POSINF / POSINF
!
NAN4 = POSINF*ZERO
!
NAN5 = NEGINF*NEGZRO
!
NAN6 = NAN5*0.0
!
IF( NAN1.EQ.NAN1 ) THEN
   IEEECK = 0
   RETURN
END IF
!
IF( NAN2.EQ.NAN2 ) THEN
   IEEECK = 0
   RETURN
END IF
!
IF( NAN3.EQ.NAN3 ) THEN
   IEEECK = 0
   RETURN
END IF
!
IF( NAN4.EQ.NAN4 ) THEN
   IEEECK = 0
   RETURN
END IF
!
IF( NAN5.EQ.NAN5 ) THEN
   IEEECK = 0
   RETURN
END IF
!
IF( NAN6.EQ.NAN6 ) THEN
   IEEECK = 0
   RETURN
END IF
!
RETURN
end function ieeeck

! ===== End ieeeck.f90 =====


! ===== Begin ilaenv.f90 =====

INTEGER          FUNCTION ILAENV( ISPEC, NAME, OPTS, N1, N2, N3, &
                     N4 )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     June 30, 1999
!
!     .. Scalar Arguments ..
CHARACTER*( * )    NAME, OPTS
INTEGER            ISPEC, N1, N2, N3, N4
!     ..
!
!  Purpose
!  =======
!
!  ILAENV is called from the LAPACK routines to choose problem-dependent
!  parameters for the local environment.  See ISPEC for a description of
!  the parameters.
!
!  This version provides a set of parameters which should give good,
!  but not optimal, performance on many of the currently available
!  computers.  Users are encouraged to modify this subroutine to set
!  the tuning parameters for their particular machine using the option
!  and problem size information in the arguments.
!
!  This routine will not function correctly if it is converted to all
!  lower case.  Converting it to all upper case is allowed.
!
!  Arguments
!  =========
!
!  ISPEC   (input) INTEGER
!          Specifies the parameter to be returned as the value of
!          ILAENV.
!          = 1: the optimal blocksize; if this value is 1, an unblocked
!               algorithm will give the best performance.
!          = 2: the minimum block size for which the block routine
!               should be used; if the usable block size is less than
!               this value, an unblocked routine should be used.
!          = 3: the crossover point (in a block routine, for N less
!               than this value, an unblocked routine should be used)
!          = 4: the number of shifts, used in the nonsymmetric
!               eigenvalue routines
!          = 5: the minimum column dimension for blocking to be used;
!               rectangular blocks must have dimension at least k by m,
!               where k is given by ILAENV(2,...) and m by ILAENV(5,...)
!          = 6: the crossover point for the SVD (when reducing an m by n
!               matrix to bidiagonal form, if max(m,n)/min(m,n) exceeds
!               this value, a QR factorization is used first to reduce
!               the matrix to a triangular form.)
!          = 7: the number of processors
!          = 8: the crossover point for the multishift QR and QZ methods
!               for nonsymmetric eigenvalue problems.
!          = 9: maximum size of the subproblems at the bottom of the
!               computation tree in the divide-and-conquer algorithm
!               (used by xGELSD and xGESDD)
!          =10: ieee NaN arithmetic can be trusted not to trap
!          =11: infinity arithmetic can be trusted not to trap
!
!  NAME    (input) CHARACTER*(*)
!          The name of the calling subroutine, in either upper case or
!          lower case.
!
!  OPTS    (input) CHARACTER*(*)
!          The character options to the subroutine NAME, concatenated
!          into a single character string.  For example, UPLO = 'U',
!          TRANS = 'T', and DIAG = 'N' for a triangular routine would
!          be specified as OPTS = 'UTN'.
!
!  N1      (input) INTEGER
!  N2      (input) INTEGER
!  N3      (input) INTEGER
!  N4      (input) INTEGER
!          Problem dimensions for the subroutine NAME; these may not all
!          be required.
!
! (ILAENV) (output) INTEGER
!          >= 0: the value of the parameter specified by ISPEC
!          < 0:  if ILAENV = -k, the k-th argument had an illegal value.
!
!  Further Details
!  ===============
!
!  The following conventions have been used when calling ILAENV from the
!  LAPACK routines:
!  1)  OPTS is a concatenation of all of the character options to
!      subroutine NAME, in the same order that they appear in the
!      argument list for NAME, even if they are not used in determining
!      the value of the parameter specified by ISPEC.
!  2)  The problem dimensions N1, N2, N3, N4 are specified in the order
!      that they appear in the argument list for NAME.  N1 is used
!      first, N2 second, and so on, and unused problem dimensions are
!      passed a value of -1.
!  3)  The parameter value returned by ILAENV is checked for validity in
!      the calling subroutine.  For example, ILAENV is used to retrieve
!      the optimal blocksize for STRTRI as follows:
!
!      NB = ILAENV( 1, 'STRTRI', UPLO // DIAG, N, -1, -1, -1 )
!      IF( NB.LE.1 ) NB = MAX( 1, N )
!
!  =====================================================================
!
!     .. Local Scalars ..
LOGICAL            CNAME, SNAME
CHARACTER*1        C1
CHARACTER*2        C2, C4
CHARACTER*3        C3
CHARACTER*6        SUBNAM
INTEGER            I, IC, IZ, NB, NBMIN, NX
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          CHAR, ICHAR, INT, MIN, REAL
!     ..
!     .. External Functions ..
INTEGER            IEEECK
EXTERNAL           IEEECK
!     ..
!     .. Executable Statements ..
!
GO TO ( 100, 100, 100, 400, 500, 600, 700, 800, 900, 1000, &
            1100 ) ISPEC
!
!     Invalid value for ISPEC
!
ILAENV = -1
RETURN
!
100 CONTINUE
!
!     Convert NAME to upper case if the first character is lower case.
!
ILAENV = 1
SUBNAM = NAME
IC = ICHAR( SUBNAM( 1:1 ) )
IZ = ICHAR( 'Z' )
IF( IZ.EQ.90 .OR. IZ.EQ.122 ) THEN
!
!        ASCII character set
!
   IF( IC.GE.97 .AND. IC.LE.122 ) THEN
      SUBNAM( 1:1 ) = CHAR( IC-32 )
      DO 10 I = 2, 6
         IC = ICHAR( SUBNAM( I:I ) )
         IF( IC.GE.97 .AND. IC.LE.122 ) &
                SUBNAM( I:I ) = CHAR( IC-32 )
10       CONTINUE
   END IF
!
ELSE IF( IZ.EQ.233 .OR. IZ.EQ.169 ) THEN
!
!        EBCDIC character set
!
   IF( ( IC.GE.129 .AND. IC.LE.137 ) .OR. &
           ( IC.GE.145 .AND. IC.LE.153 ) .OR. &
           ( IC.GE.162 .AND. IC.LE.169 ) ) THEN
      SUBNAM( 1:1 ) = CHAR( IC+64 )
      DO 20 I = 2, 6
         IC = ICHAR( SUBNAM( I:I ) )
         IF( ( IC.GE.129 .AND. IC.LE.137 ) .OR. &
                 ( IC.GE.145 .AND. IC.LE.153 ) .OR. &
                 ( IC.GE.162 .AND. IC.LE.169 ) ) &
                SUBNAM( I:I ) = CHAR( IC+64 )
20       CONTINUE
   END IF
!
ELSE IF( IZ.EQ.218 .OR. IZ.EQ.250 ) THEN
!
!        Prime machines:  ASCII+128
!
   IF( IC.GE.225 .AND. IC.LE.250 ) THEN
      SUBNAM( 1:1 ) = CHAR( IC-32 )
      DO 30 I = 2, 6
         IC = ICHAR( SUBNAM( I:I ) )
         IF( IC.GE.225 .AND. IC.LE.250 ) &
                SUBNAM( I:I ) = CHAR( IC-32 )
30       CONTINUE
   END IF
END IF
!
C1 = SUBNAM( 1:1 )
SNAME = C1.EQ.'S' .OR. C1.EQ.'D'
CNAME = C1.EQ.'C' .OR. C1.EQ.'Z'
IF( .NOT.( CNAME .OR. SNAME ) ) &
       RETURN
C2 = SUBNAM( 2:3 )
C3 = SUBNAM( 4:6 )
C4 = C3( 2:3 )
!
GO TO ( 110, 200, 300 ) ISPEC
!
110 CONTINUE
!
!     ISPEC = 1:  block size
!
!     In these examples, separate code is provided for setting NB for
!     real and complex.  We assume that NB will take the same value in
!     single or double precision.
!
NB = 1
!
IF( C2.EQ.'GE' ) THEN
   IF( C3.EQ.'TRF' ) THEN
      IF( SNAME ) THEN
         NB = 64
      ELSE
         NB = 64
      END IF
   ELSE IF( C3.EQ.'QRF' .OR. C3.EQ.'RQF' .OR. C3.EQ.'LQF' .OR. &
                C3.EQ.'QLF' ) THEN
      IF( SNAME ) THEN
         NB = 32
      ELSE
         NB = 32
      END IF
   ELSE IF( C3.EQ.'HRD' ) THEN
      IF( SNAME ) THEN
         NB = 32
      ELSE
         NB = 32
      END IF
   ELSE IF( C3.EQ.'BRD' ) THEN
      IF( SNAME ) THEN
         NB = 32
      ELSE
         NB = 32
      END IF
   ELSE IF( C3.EQ.'TRI' ) THEN
      IF( SNAME ) THEN
         NB = 64
      ELSE
         NB = 64
      END IF
   END IF
ELSE IF( C2.EQ.'PO' ) THEN
   IF( C3.EQ.'TRF' ) THEN
      IF( SNAME ) THEN
         NB = 64
      ELSE
         NB = 64
      END IF
   END IF
ELSE IF( C2.EQ.'SY' ) THEN
   IF( C3.EQ.'TRF' ) THEN
      IF( SNAME ) THEN
         NB = 64
      ELSE
         NB = 64
      END IF
   ELSE IF( SNAME .AND. C3.EQ.'TRD' ) THEN
      NB = 32
   ELSE IF( SNAME .AND. C3.EQ.'GST' ) THEN
      NB = 64
   END IF
ELSE IF( CNAME .AND. C2.EQ.'HE' ) THEN
   IF( C3.EQ.'TRF' ) THEN
      NB = 64
   ELSE IF( C3.EQ.'TRD' ) THEN
      NB = 32
   ELSE IF( C3.EQ.'GST' ) THEN
      NB = 64
   END IF
ELSE IF( SNAME .AND. C2.EQ.'OR' ) THEN
   IF( C3( 1:1 ).EQ.'G' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NB = 32
      END IF
   ELSE IF( C3( 1:1 ).EQ.'M' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NB = 32
      END IF
   END IF
ELSE IF( CNAME .AND. C2.EQ.'UN' ) THEN
   IF( C3( 1:1 ).EQ.'G' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NB = 32
      END IF
   ELSE IF( C3( 1:1 ).EQ.'M' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NB = 32
      END IF
   END IF
ELSE IF( C2.EQ.'GB' ) THEN
   IF( C3.EQ.'TRF' ) THEN
      IF( SNAME ) THEN
         IF( N4.LE.64 ) THEN
            NB = 1
         ELSE
            NB = 32
         END IF
      ELSE
         IF( N4.LE.64 ) THEN
            NB = 1
         ELSE
            NB = 32
         END IF
      END IF
   END IF
ELSE IF( C2.EQ.'PB' ) THEN
   IF( C3.EQ.'TRF' ) THEN
      IF( SNAME ) THEN
         IF( N2.LE.64 ) THEN
            NB = 1
         ELSE
            NB = 32
         END IF
      ELSE
         IF( N2.LE.64 ) THEN
            NB = 1
         ELSE
            NB = 32
         END IF
      END IF
   END IF
ELSE IF( C2.EQ.'TR' ) THEN
   IF( C3.EQ.'TRI' ) THEN
      IF( SNAME ) THEN
         NB = 64
      ELSE
         NB = 64
      END IF
   END IF
ELSE IF( C2.EQ.'LA' ) THEN
   IF( C3.EQ.'UUM' ) THEN
      IF( SNAME ) THEN
         NB = 64
      ELSE
         NB = 64
      END IF
   END IF
ELSE IF( SNAME .AND. C2.EQ.'ST' ) THEN
   IF( C3.EQ.'EBZ' ) THEN
      NB = 1
   END IF
END IF
ILAENV = NB
RETURN
!
200 CONTINUE
!
!     ISPEC = 2:  minimum block size
!
NBMIN = 2
IF( C2.EQ.'GE' ) THEN
   IF( C3.EQ.'QRF' .OR. C3.EQ.'RQF' .OR. C3.EQ.'LQF' .OR. &
           C3.EQ.'QLF' ) THEN
      IF( SNAME ) THEN
         NBMIN = 2
      ELSE
         NBMIN = 2
      END IF
   ELSE IF( C3.EQ.'HRD' ) THEN
      IF( SNAME ) THEN
         NBMIN = 2
      ELSE
         NBMIN = 2
      END IF
   ELSE IF( C3.EQ.'BRD' ) THEN
      IF( SNAME ) THEN
         NBMIN = 2
      ELSE
         NBMIN = 2
      END IF
   ELSE IF( C3.EQ.'TRI' ) THEN
      IF( SNAME ) THEN
         NBMIN = 2
      ELSE
         NBMIN = 2
      END IF
   END IF
ELSE IF( C2.EQ.'SY' ) THEN
   IF( C3.EQ.'TRF' ) THEN
      IF( SNAME ) THEN
         NBMIN = 8
      ELSE
         NBMIN = 8
      END IF
   ELSE IF( SNAME .AND. C3.EQ.'TRD' ) THEN
      NBMIN = 2
   END IF
ELSE IF( CNAME .AND. C2.EQ.'HE' ) THEN
   IF( C3.EQ.'TRD' ) THEN
      NBMIN = 2
   END IF
ELSE IF( SNAME .AND. C2.EQ.'OR' ) THEN
   IF( C3( 1:1 ).EQ.'G' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NBMIN = 2
      END IF
   ELSE IF( C3( 1:1 ).EQ.'M' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NBMIN = 2
      END IF
   END IF
ELSE IF( CNAME .AND. C2.EQ.'UN' ) THEN
   IF( C3( 1:1 ).EQ.'G' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NBMIN = 2
      END IF
   ELSE IF( C3( 1:1 ).EQ.'M' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NBMIN = 2
      END IF
   END IF
END IF
ILAENV = NBMIN
RETURN
!
300 CONTINUE
!
!     ISPEC = 3:  crossover point
!
NX = 0
IF( C2.EQ.'GE' ) THEN
   IF( C3.EQ.'QRF' .OR. C3.EQ.'RQF' .OR. C3.EQ.'LQF' .OR. &
           C3.EQ.'QLF' ) THEN
      IF( SNAME ) THEN
         NX = 128
      ELSE
         NX = 128
      END IF
   ELSE IF( C3.EQ.'HRD' ) THEN
      IF( SNAME ) THEN
         NX = 128
      ELSE
         NX = 128
      END IF
   ELSE IF( C3.EQ.'BRD' ) THEN
      IF( SNAME ) THEN
         NX = 128
      ELSE
         NX = 128
      END IF
   END IF
ELSE IF( C2.EQ.'SY' ) THEN
   IF( SNAME .AND. C3.EQ.'TRD' ) THEN
      NX = 32
   END IF
ELSE IF( CNAME .AND. C2.EQ.'HE' ) THEN
   IF( C3.EQ.'TRD' ) THEN
      NX = 32
   END IF
ELSE IF( SNAME .AND. C2.EQ.'OR' ) THEN
   IF( C3( 1:1 ).EQ.'G' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NX = 128
      END IF
   END IF
ELSE IF( CNAME .AND. C2.EQ.'UN' ) THEN
   IF( C3( 1:1 ).EQ.'G' ) THEN
      IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR. &
              C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR. &
              C4.EQ.'BR' ) THEN
         NX = 128
      END IF
   END IF
END IF
ILAENV = NX
RETURN
!
400 CONTINUE
!
!     ISPEC = 4:  number of shifts (used by xHSEQR)
!
ILAENV = 6
RETURN
!
500 CONTINUE
!
!     ISPEC = 5:  minimum column dimension (not used)
!
ILAENV = 2
RETURN
!
600 CONTINUE
!
!     ISPEC = 6:  crossover point for SVD (used by xGELSS and xGESVD)
!
ILAENV = INT( REAL( MIN( N1, N2 ) )*1.6E0 )
RETURN
!
700 CONTINUE
!
!     ISPEC = 7:  number of processors (not used)
!
ILAENV = 1
RETURN
!
800 CONTINUE
!
!     ISPEC = 8:  crossover point for multishift (used by xHSEQR)
!
ILAENV = 50
RETURN
!
900 CONTINUE
!
!     ISPEC = 9:  maximum size of the subproblems at the bottom of the
!                 computation tree in the divide-and-conquer algorithm
!                 (used by xGELSD and xGESDD)
!
ILAENV = 25
RETURN
!
1000 CONTINUE
!
!     ISPEC = 10: ieee NaN arithmetic can be trusted not to trap
!
!     ILAENV = 0
ILAENV = 1
IF( ILAENV.EQ.1 ) THEN
   ILAENV = IEEECK( 0, 0.0, 1.0 )
END IF
RETURN
!
1100 CONTINUE
!
!     ISPEC = 11: infinity arithmetic can be trusted not to trap
!
!     ILAENV = 0
ILAENV = 1
IF( ILAENV.EQ.1 ) THEN
   ILAENV = IEEECK( 1, 0.0, 1.0 )
END IF
RETURN
!
!     End of ILAENV
!
end function ilaenv

! ===== End ilaenv.f90 =====


! ===== Begin izmax1.f90 =====

INTEGER          FUNCTION IZMAX1( N, CX, INCX )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
INTEGER            INCX, N
!     ..
!     .. Array Arguments ..
COMPLEX*16         CX( * )
!     ..
!
!  Purpose
!  =======
!
!  IZMAX1 finds the index of the element whose real part has maximum
!  absolute value.
!
!  Based on IZAMAX from Level 1 BLAS.
!  The change is to use the 'genuine' absolute value.
!
!  Contributed by Nick Higham for use with ZLACON.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of elements in the vector CX.
!
!  CX      (input) COMPLEX*16 array, dimension (N)
!          The vector whose elements will be summed.
!
!  INCX    (input) INTEGER
!          The spacing between successive values of CX.  INCX >= 1.
!
! =====================================================================
!
!     .. Local Scalars ..
INTEGER            I, IX
DOUBLE PRECISION   SMAX
COMPLEX*16         ZDUM
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          ABS, DBLE
!     ..
!     .. Statement Functions ..
DOUBLE PRECISION   CABS1
!     ..
!     .. Statement Function definitions ..
!
!     NEXT LINE IS THE ONLY MODIFICATION.
CABS1( ZDUM ) = ABS( DBLE( ZDUM ) )
!     ..
!     .. Executable Statements ..
!
IZMAX1 = 0
IF( N.LT.1 ) &
       RETURN
IZMAX1 = 1
IF( N.EQ.1 ) &
       RETURN
IF( INCX.EQ.1 ) &
       GO TO 30
!
!     CODE FOR INCREMENT NOT EQUAL TO 1
!
IX = 1
SMAX = CABS1( CX( 1 ) )
IX = IX + INCX
DO 20 I = 2, N
   IF( CABS1( CX( IX ) ).LE.SMAX ) &
          GO TO 10
   IZMAX1 = I
   SMAX = CABS1( CX( IX ) )
10    CONTINUE
   IX = IX + INCX
20 CONTINUE
RETURN
!
!     CODE FOR INCREMENT EQUAL TO 1
!
30 CONTINUE
SMAX = CABS1( CX( 1 ) )
DO 40 I = 2, N
   IF( CABS1( CX( I ) ).LE.SMAX ) &
          GO TO 40
   IZMAX1 = I
   SMAX = CABS1( CX( I ) )
40 CONTINUE
RETURN
!
!     End of IZMAX1
!
end function izmax1

! ===== End izmax1.f90 =====


! ===== Begin lsame.f90 =====

LOGICAL          FUNCTION LSAME( CA, CB )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER          CA, CB
!     ..
!
!  Purpose
!  =======
!
!  LSAME returns .TRUE. if CA is the same letter as CB regardless of
!  case.
!
!  Arguments
!  =========
!
!  CA      (input) CHARACTER*1
!  CB      (input) CHARACTER*1
!          CA and CB specify the single characters to be compared.
!
! =====================================================================
!
!     .. Intrinsic Functions ..
INTRINSIC          ICHAR
!     ..
!     .. Local Scalars ..
INTEGER            INTA, INTB, ZCODE
!     ..
!     .. Executable Statements ..
!
!     Test if the characters are equal
!
LSAME = CA.EQ.CB
IF( LSAME ) &
       RETURN
!
!     Now test for equivalence if both characters are alphabetic.
!
ZCODE = ICHAR( 'Z' )
!
!     Use 'Z' rather than 'A' so that ASCII can be detected on Prime
!     machines, on which ICHAR returns a value with bit 8 set.
!     ICHAR('A') on Prime machines returns 193 which is the same as
!     ICHAR('A') on an EBCDIC machine.
!
INTA = ICHAR( CA )
INTB = ICHAR( CB )
!
IF( ZCODE.EQ.90 .OR. ZCODE.EQ.122 ) THEN
!
!        ASCII is assumed - ZCODE is the ASCII code of either lower or
!        upper case 'Z'.
!
   IF( INTA.GE.97 .AND. INTA.LE.122 ) INTA = INTA - 32
   IF( INTB.GE.97 .AND. INTB.LE.122 ) INTB = INTB - 32
!
ELSE IF( ZCODE.EQ.233 .OR. ZCODE.EQ.169 ) THEN
!
!        EBCDIC is assumed - ZCODE is the EBCDIC code of either lower or
!        upper case 'Z'.
!
   IF( INTA.GE.129 .AND. INTA.LE.137 .OR. &
           INTA.GE.145 .AND. INTA.LE.153 .OR. &
           INTA.GE.162 .AND. INTA.LE.169 ) INTA = INTA + 64
   IF( INTB.GE.129 .AND. INTB.LE.137 .OR. &
           INTB.GE.145 .AND. INTB.LE.153 .OR. &
           INTB.GE.162 .AND. INTB.LE.169 ) INTB = INTB + 64
!
ELSE IF( ZCODE.EQ.218 .OR. ZCODE.EQ.250 ) THEN
!
!        ASCII is assumed, on Prime machines - ZCODE is the ASCII code
!        plus 128 of either lower or upper case 'Z'.
!
   IF( INTA.GE.225 .AND. INTA.LE.250 ) INTA = INTA - 32
   IF( INTB.GE.225 .AND. INTB.LE.250 ) INTB = INTB - 32
END IF
LSAME = INTA.EQ.INTB
!
!     RETURN
!
!     End of LSAME
!
end function lsame

! ===== End lsame.f90 =====


! ===== Begin lsamen.f90 =====

LOGICAL          FUNCTION LSAMEN( N, CA, CB )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER*( * )    CA, CB
INTEGER            N
!     ..
!
!  Purpose
!  =======
!
!  LSAMEN  tests if the first N letters of CA are the same as the
!  first N letters of CB, regardless of case.
!  LSAMEN returns .TRUE. if CA and CB are equivalent except for case
!  and .FALSE. otherwise.  LSAMEN also returns .FALSE. if LEN( CA )
!  or LEN( CB ) is less than N.
!
!  Arguments
!  =========
!
!  N       (input) INTEGER
!          The number of characters in CA and CB to be compared.
!
!  CA      (input) CHARACTER*(*)
!  CB      (input) CHARACTER*(*)
!          CA and CB specify two character strings of length at least N.
!          Only the first N characters of each string will be accessed.
!
! =====================================================================
!
!     .. Local Scalars ..
INTEGER            I
!     ..
!     .. External Functions ..
LOGICAL            LSAME
EXTERNAL           LSAME
!     ..
!     .. Intrinsic Functions ..
INTRINSIC          LEN
!     ..
!     .. Executable Statements ..
!
LSAMEN = .FALSE.
IF( LEN( CA ).LT.N .OR. LEN( CB ).LT.N ) &
       GO TO 20
!
!     Do for each character in the two strings.
!
DO 10 I = 1, N
!
!        Test if the characters are equal using LSAME.
!
   IF( .NOT.LSAME( CA( I: I ), CB( I: I ) ) ) &
          GO TO 20
!
10 CONTINUE
LSAMEN = .TRUE.
!
20 CONTINUE
RETURN
!
!     End of LSAMEN
!
end function lsamen

! ===== End lsamen.f90 =====


! ===== Begin xerbla.f90 =====

SUBROUTINE XERBLA( SRNAME, INFO )
!
!  -- LAPACK auxiliary routine (version 3.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     September 30, 1994
!
!     .. Scalar Arguments ..
CHARACTER*6        SRNAME
INTEGER            INFO
!     ..
!
!  Purpose
!  =======
!
!  XERBLA  is an error handler for the LAPACK routines.
!  It is called by an LAPACK routine if an input parameter has an
!  invalid value.  A message is printed and execution stops.
!
!  Installers may consider modifying the STOP statement in order to
!  call system-specific exception-handling facilities.
!
!  Arguments
!  =========
!
!  SRNAME  (input) CHARACTER*6
!          The name of the routine which called XERBLA.
!
!  INFO    (input) INTEGER
!          The position of the invalid parameter in the parameter list
!          of the calling routine.
!
! =====================================================================
!
!     .. Executable Statements ..
!
WRITE( *, FMT = 9999 )SRNAME, INFO
!
STOP
!
9999 FORMAT( ' ** On entry to ', A6, ' parameter number ', I2, ' had ', &
          'an illegal value' )
!
!     End of XERBLA
!
end subroutine xerbla

! ===== End xerbla.f90 =====


! ===== Begin xlaenv.f90 =====

SUBROUTINE XLAENV( ISPEC, NVALUE )
!
!  -- LAPACK auxiliary routine (version 2.0) --
!     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
!     Courant Institute, Argonne National Lab, and Rice University
!     February 29, 1992
!
!     .. Scalar Arguments ..
INTEGER            ISPEC, NVALUE
!     ..
!
!  Purpose
!  =======
!
!  XLAENV sets certain machine- and problem-dependent quantities
!  which will later be retrieved by ILAENV.
!
!  Arguments
!  =========
!
!  ISPEC   (input) INTEGER
!          Specifies the parameter to be set in the COMMON array IPARMS.
!          = 1: the optimal blocksize; if this value is 1, an unblocked
!               algorithm will give the best performance.
!          = 2: the minimum block size for which the block routine
!               should be used; if the usable block size is less than
!               this value, an unblocked routine should be used.
!          = 3: the crossover point (in a block routine, for N less
!               than this value, an unblocked routine should be used)
!          = 4: the number of shifts, used in the nonsymmetric
!               eigenvalue routines
!          = 5: the minimum column dimension for blocking to be used;
!               rectangular blocks must have dimension at least k by m,
!               where k is given by ILAENV(2,...) and m by ILAENV(5,...)
!          = 6: the crossover point for the SVD (when reducing an m by n
!               matrix to bidiagonal form, if max(m,n)/min(m,n) exceeds
!               this value, a QR factorization is used first to reduce
!               the matrix to a triangular form)
!          = 7: the number of processors
!          = 8: another crossover point, for the multishift QR and QZ
!               methods for nonsymmetric eigenvalue problems.
!
!  NVALUE  (input) INTEGER
!          The value of the parameter specified by ISPEC.
!
!  =====================================================================
!
!     .. Arrays in Common ..
INTEGER            IPARMS( 100 )
!     ..
!     .. Common blocks ..
COMMON             / CLAENV / IPARMS
!     ..
!     .. Save statement ..
SAVE               / CLAENV /
!     ..
!     .. Executable Statements ..
!
IF( ISPEC.GE.1 .AND. ISPEC.LE.8 ) THEN
   IPARMS( ISPEC ) = NVALUE
END IF
!
RETURN
!
!     End of XLAENV
!
end subroutine xlaenv

! ===== End xlaenv.f90 =====


END MODULE ModuleLapack

