PROGRAM Test_Solver_Module
  !===============================================================================
  ! PROGRAM: Test_Solver_Module
  !
  ! DESCRIPTION: Solver 域单元测�?
  !              验证 GMRES/PCG 迭代法、预处理子、直接法正确�?
  !
  ! TEST CASES:
  !              1. LinearSolver TYPE 初始�?
  !              2. GMRES 求解稀疏线性系�?
  !              3. PCG 求解对称正定系统
  !              4. LU 直接法精度验�?
  !              5. Jacobi 预处理子加速收�?
  !
  ! AUTHOR:      UFC Core Team
  ! DATE:        2026-03-23
  !===============================================================================
  
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_Test_Framework
  USE NM_Solver_Types
  IMPLICIT NONE
  
  REAL(wp), PARAMETER :: TOL = 1.0E-8_wp   ! 迭代法容�?
  REAL(wp), PARAMETER :: DIRECT_TOL = 1.0E-12_wp  ! 直接法容�?
  
  PRINT *, "=============================================================="
  PRINT *, "         L2_NM Solver Module Unit Tests"
  PRINT *, "=============================================================="
  PRINT *
  
  !---------------------------------------------------------------------------
  ! 测试 1: LinearSolver TYPE 初始�?
  !---------------------------------------------------------------------------
  CALL Test_LinearSolver_Init()
  
  !---------------------------------------------------------------------------
  ! 测试 2: GMRES 求解稀疏线性系�?
  !---------------------------------------------------------------------------
  CALL Test_GMRES_Convergence()
  
  !---------------------------------------------------------------------------
  ! 测试 3: PCG 求解对称正定系统
  !---------------------------------------------------------------------------
  CALL Test_PCG_Convergence()
  
  !---------------------------------------------------------------------------
  ! 测试 4: LU 直接法精度验�?
  !---------------------------------------------------------------------------
  CALL Test_Direct_LU_Accuracy()
  
  !---------------------------------------------------------------------------
  ! 测试 5: Jacobi 预处理子加速收�?
  !---------------------------------------------------------------------------
  CALL Test_Jacobi_Precond()
  
  !---------------------------------------------------------------------------
  ! 生成测试报告
  !---------------------------------------------------------------------------
  PRINT *
  CALL TestReport()
  
CONTAINS
  
  !===========================================================================
  ! SUBROUTINE: Test_LinearSolver_Init
  !===========================================================================
  SUBROUTINE Test_LinearSolver_Init()
    TYPE(LinearSolver) :: solver
    
    CALL TEST_START("LinearSolver_Init")
    
    ! 验证默认参数
    CALL ASSERT_EQ(solver%solver_type, SOLVER_DIRECT, "Default should be direct solver", __LINE__)
    CALL ASSERT_EQ(solver%precond_type, PRECOND_NONE, "Default precond should be none", __LINE__)
    CALL ASSERT_EQ(solver%max_iter, 1000_i4, "Default max_iter should be 1000", __LINE__)
    CALL ASSERT_NEAR(solver%tolerance, 1.0E-8_wp, 1.0E-10_wp, "Default tolerance", __LINE__)
    CALL ASSERT_TRUE(solver%use_restart, "Default should use restart", __LINE__)
    CALL ASSERT_EQ(solver%restart_freq, 50_i4, "Default restart frequency", __LINE__)
    
    CALL TEST_END()
  END SUBROUTINE Test_LinearSolver_Init
  
  !===========================================================================
  ! SUBROUTINE: Test_GMRES_Convergence
  !===========================================================================
  SUBROUTINE Test_GMRES_Convergence()
    TYPE(SparseMatrix_CSR) :: A
    TYPE(LinearSolver) :: solver
    TYPE(SolverStats) :: stats
    REAL(wp), ALLOCATABLE :: x(:), b(:), x_exact(:), residual(:)
    INTEGER(i4) :: n, nnz, i
    REAL(wp) :: rel_error
    
    CALL TEST_START("GMRES_Convergence")
    
    ! 创建测试问题：A*x = b，已知精确解 x_exact
    n = 100_i4
    nnz = 5*n  ! 五对角矩�?
    
    CALL Create_SparseCSR(A, n, n, nnz)
    ALLOCATE(x(n), b(n), x_exact(n), residual(n))
    
    ! 构造五对角矩阵（对角占优，保证非奇异）
    ! A = tridiag(-1, 4, -1) + corner terms
    CALL Build_Pentadiagonal_CSR(A, 4.0_wp, -1.0_wp)
    
    ! 设置精确解（正弦波）
    DO i = 1, n
      x_exact(i) = SIN(REAL(i, wp) / REAL(n, wp) * 3.14159265358979_wp)
    END DO
    
    ! 计算右端�?b = A * x_exact
    CALL MatVec_CSR(A, x_exact, b)
    
    ! 初始猜测为零
    x = 0.0_wp
    
    ! 设置 GMRES 参数
    solver%solver_type = SOLVER_ITERATIVE
    solver%iter_method = ITER_GMRES
    solver%max_iter = 200_i4
    solver%tolerance = TOL
    solver%use_restart = .TRUE.
    solver%restart_freq = 50_i4
    
    ! 调用 GMRES 求解
    CALL GMRES_Solve(A, b, x, solver, stats)
    
    ! 验证收敛
    CALL ASSERT_TRUE(stats%converged, "GMRES should converge", __LINE__)
    CALL ASSERT_TRUE(stats%iterations <= solver%max_iter, "Iterations within limit", __LINE__)
    
    ! 计算相对误差
    residual = x - x_exact
    rel_error = SQRT(DOT_PRODUCT(residual, residual)) / &
                SQRT(DOT_PRODUCT(x_exact, x_exact))
    
    CALL ASSERT_TRUE(rel_error < TOL*10.0_wp, "Solution accuracy should be good", __LINE__)
    
    ! 打印收敛信息
    PRINT '(A,I6,A,ES10.3)', "       GMRES converged in ", stats%iterations, &
                           " iterations, rel_error=", rel_error
    
    ! 清理
    CALL Destroy_SparseCSR(A)
    DEALLOCATE(x, b, x_exact, residual)
    
    CALL TEST_END()
  END SUBROUTINE Test_GMRES_Convergence
  
  !===========================================================================
  ! SUBROUTINE: Test_PCG_Convergence
  !===========================================================================
  SUBROUTINE Test_PCG_Convergence()
    TYPE(SparseMatrix_CSR) :: A
    TYPE(LinearSolver) :: solver
    TYPE(SolverStats) :: stats
    REAL(wp), ALLOCATABLE :: x(:), b(:), x_exact(:), residual(:)
    INTEGER(i4) :: n, nnz, i
    REAL(wp) :: rel_error
    
    CALL TEST_START("PCG_Convergence")
    
    ! 创建对称正定矩阵
    n = 100_i4
    nnz = 5*n
    
    CALL Create_SparseCSR(A, n, n, nnz)
    ALLOCATE(x(n), b(n), x_exact(n), residual(n))
    
    ! 构造对称正定五对角矩阵
    CALL Build_Pentadiagonal_CSR(A, 4.0_wp, -1.0_wp)
    
    ! 精确�?
    DO i = 1, n
      x_exact(i) = SIN(REAL(i, wp) / REAL(n, wp) * 3.14159265358979_wp)
    END DO
    
    ! b = A * x_exact
    CALL MatVec_CSR(A, x_exact, b)
    
    ! 零初始猜�?
    x = 0.0_wp
    
    ! 设置 PCG 参数
    solver%solver_type = SOLVER_ITERATIVE
    solver%iter_method = ITER_CG
    solver%max_iter = 500_i4
    solver%tolerance = TOL
    
    ! 调用 PCG 求解
    CALL CG_Solve(A, b, x, solver, stats)
    
    ! 验证收敛（CG �?SPD 矩阵应在 n 步内收敛�?
    CALL ASSERT_TRUE(stats%converged, "PCG should converge", __LINE__)
    CALL ASSERT_TRUE(stats%iterations <= n, "CG should converge in <= n steps", __LINE__)
    
    ! 计算相对误差
    residual = x - x_exact
    rel_error = SQRT(DOT_PRODUCT(residual, residual)) / &
                SQRT(DOT_PRODUCT(x_exact, x_exact))
    
    CALL ASSERT_TRUE(rel_error < TOL, "PCG solution accuracy", __LINE__)
    
    PRINT '(A,I6,A,ES10.3)', "       PCG converged in ", stats%iterations, &
                           " iterations, rel_error=", rel_error
    
    ! 清理
    CALL Destroy_SparseCSR(A)
    DEALLOCATE(x, b, x_exact, residual)
    
    CALL TEST_END()
  END SUBROUTINE Test_PCG_Convergence
  
  !===========================================================================
  ! SUBROUTINE: Test_Direct_LU_Accuracy
  !===========================================================================
  SUBROUTINE Test_Direct_LU_Accuracy()
    TYPE(DenseMatrix) :: A
    TYPE(LinearSolver) :: solver
    TYPE(SolverStats) :: stats
    REAL(wp), ALLOCATABLE :: x(:), b(:), x_exact(:), residual(:)
    INTEGER(i4) :: n, i
    REAL(wp) :: rel_error
    
    CALL TEST_START("Direct_LU_Accuracy")
    
    ! 创建稠密矩阵
    n = 50_i4
    CALL Create_DenseMatrix(A, n, n)
    ALLOCATE(x(n), b(n), x_exact(n), residual(n))
    
    ! 构造随机矩阵（对角占优�?
    CALL RANDOM_NUMBER(A%data)
    DO i = 1, n
      A%data(i,i) = A%data(i,i) + REAL(n, wp)  ! 对角占优
    END DO
    
    ! 精确�?
    DO i = 1, n
      x_exact(i) = SIN(REAL(i, wp) * 0.1_wp)
    END DO
    
    ! b = A * x_exact
    CALL DGEMV('N', n, n, 1.0_wp, A%data, n, x_exact, 1, 0.0_wp, b, 1)
    
    ! 零初始猜�?
    x = 0.0_wp
    
    ! 直接法求�?
    solver%solver_type = SOLVER_DIRECT
    solver%direct_method = DIRECT_LU
    
    CALL Solve_Direct_LU(A, b, x, stats)
    
    ! 验证求解成功
    CALL ASSERT_TRUE(stats%success, "LU solve should succeed", __LINE__)
    
    ! 计算残差 ||b - A*x|| / ||b||
    residual = b
    CALL DGEMV('N', n, n, -1.0_wp, A%data, n, x, 1, 1.0_wp, residual, 1)
    rel_error = SQRT(DOT_PRODUCT(residual, residual)) / &
                SQRT(DOT_PRODUCT(b, b))
    
    CALL ASSERT_TRUE(rel_error < DIRECT_TOL, "LU direct method accuracy", __LINE__)
    
    PRINT '(A,ES10.3)', "       LU direct solve, residual norm=", rel_error
    
    ! 清理
    CALL Destroy_DenseMatrix(A)
    DEALLOCATE(x, b, x_exact, residual)
    
    CALL TEST_END()
  END SUBROUTINE Test_Direct_LU_Accuracy
  
  !===========================================================================
  ! SUBROUTINE: Test_Jacobi_Precond
  !===========================================================================
  SUBROUTINE Test_Jacobi_Precond()
    TYPE(SparseMatrix_CSR) :: A
    TYPE(Preconditioner) :: precond
    TYPE(LinearSolver) :: solver
    TYPE(SolverStats) :: stats_no_precond, stats_with_precond
    REAL(wp), ALLOCATABLE :: x(:), b(:), x_exact(:)
    INTEGER(i4) :: n, nnz, i
    REAL(wp) :: rel_error
    
    CALL TEST_START("Jacobi_Precond_Acceleration")
    
    ! 创建病态矩阵（条件数大，需要预处理�?
    n = 200_i4
    nnz = 5*n
    
    CALL Create_SparseCSR(A, n, n, nnz)
    ALLOCATE(x(n), b(n), x_exact(n))
    
    ! 构造五对角矩阵（较小的对角占优度）
    CALL Build_Pentadiagonal_CSR(A, 2.0_wp, -0.9_wp)
    
    ! 精确�?
    DO i = 1, n
      x_exact(i) = SIN(REAL(i, wp) / REAL(n, wp) * 3.14159265358979_wp)
    END DO
    
    ! b = A * x_exact
    CALL MatVec_CSR(A, x_exact, b)
    
    ! ===== 测试 1: 无预处理 GMRES =====
    x = 0.0_wp
    solver%solver_type = SOLVER_ITERATIVE
    solver%iter_method = ITER_GMRES
    solver%max_iter = 500_i4
    solver%tolerance = TOL
    solver%precond_type = PRECOND_NONE
    
    CALL GMRES_Solve(A, b, x, solver, stats_no_precond)
    
    ! ===== 测试 2: Jacobi 预处�?GMRES =====
    ! 构�?Jacobi 预处理子
    CALL Construct_Jacobi_Precond(A, precond)
    CALL ASSERT_TRUE(precond%is_constructed, "Jacobi precond should be constructed", __LINE__)
    
    x = 0.0_wp
    solver%precond_type = PRECOND_JACOBI
    
    CALL GMRES_Solve(A, b, x, solver, stats_with_precond, precond)
    
    ! 验证预处理加速效�?
    PRINT '(A,I6,A,I6)', "       GMRES iterations: no_precond=", &
           stats_no_precond%iterations, ", with_Jacobi=", stats_with_precond%iterations
    
    ! 预处理应该减少迭代次数（至少不增加）
    CALL ASSERT_TRUE(stats_with_precond%iterations <= stats_no_precond%iterations, &
                    "Jacobi should reduce iterations", __LINE__)
    
    ! 验证解的精度
    rel_error = SQRT(DOT_PRODUCT(x-x_exact, x-x_exact)) / &
                SQRT(DOT_PRODUCT(x_exact, x_exact))
    CALL ASSERT_TRUE(rel_error < TOL*10.0_wp, "Preconditioned GMRES accuracy", __LINE__)
    
    ! 清理
    CALL Destroy_SparseCSR(A)
    CALL Destroy_Precond(precond)
    DEALLOCATE(x, b, x_exact)
    
    CALL TEST_END()
  END SUBROUTINE Test_Jacobi_Precond
  
  !===========================================================================
  ! AUXILIARY: Build_Pentadiagonal_CSR
  !===========================================================================
  SUBROUTINE Build_Pentadiagonal_CSR(A, diag_val, off_diag_val)
    ! 构造五对角矩阵 CSR 格式
    TYPE(SparseMatrix_CSR), INTENT(INOUT) :: A
    REAL(wp), INTENT(IN) :: diag_val, off_diag_val
    INTEGER(i4) :: i, idx
    
    idx = 1_i4
    DO i = 1, A%nrows
      ! 主对角线
      A%row_ptr(i) = idx
      A%col_idx(idx) = i
      A%values(idx) = diag_val
      idx = idx + 1_i4
      
      ! 上次对角�?
      IF (i > 1) THEN
        A%col_idx(idx) = i - 1
        A%values(idx) = off_diag_val
        idx = idx + 1_i4
      END IF
      
      ! 下次对角�?
      IF (i < A%nrows) THEN
        A%col_idx(idx) = i + 1
        A%values(idx) = off_diag_val
        idx = idx + 1_i4
      END IF
      
      ! 上上次对角线（五对角�?
      IF (i > 2) THEN
        A%col_idx(idx) = i - 2
        A%values(idx) = off_diag_val * 0.1_wp
        idx = idx + 1_i4
      END IF
      
      ! 下下次对角线（五对角�?
      IF (i < A%nrows - 1) THEN
        A%col_idx(idx) = i + 2
        A%values(idx) = off_diag_val * 0.1_wp
        idx = idx + 1_i4
      END IF
    END DO
    A%row_ptr(A%nrows+1) = idx
    A%nnz = idx - 1_i8
  END SUBROUTINE Build_Pentadiagonal_CSR
  
  !===========================================================================
  ! AUXILIARY: MatVec_CSR
  !===========================================================================
  SUBROUTINE MatVec_CSR(A, x, y)
    ! CSR 矩阵向量乘法 y = A*x
    TYPE(SparseMatrix_CSR), INTENT(IN) :: A
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)
    INTEGER(i4) :: i, j, row_start, row_end
    
    y = 0.0_wp
    DO i = 1, A%nrows
      row_start = A%row_ptr(i)
      row_end = A%row_ptr(i+1) - 1
      DO j = row_start, row_end
        y(i) = y(i) + A%values(j) * x(A%col_idx(j))
      END DO
    END DO
  END SUBROUTINE MatVec_CSR
  
END PROGRAM Test_Solver_Module
