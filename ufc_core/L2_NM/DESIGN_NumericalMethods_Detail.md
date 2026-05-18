# L2_NM 数值方法层详细设计说明

## 概述
L2_NM Numerical Methods层是UFC的数值计算核心，提供矩阵运算、线性求解器、时间积分等基础数值算法。

---

## Base/ - 数值基础域

### 功能描述
数值基础域提供系统级数值计算基础函数和数据结构。

### 参考文档
- Numerical Recipes in Fortran
- Fortran 2003 Handbook - Intrinsic Functions
- IEEE 754 Standard for Floating-Point Arithmetic

### 基础数据类型
```fortran
module NM_Base_Def
    ! 精度定义
    integer, parameter :: wp = 8  ! working precision (double)
    integer, parameter :: sp = 4  ! single precision
    integer, parameter :: qp = 16 ! quadruple precision
    
    ! 机器常数
    real(wp), parameter :: epsilon = epsilon(1.0_wp)
    real(wp), parameter :: tiny = tiny(1.0_wp)
    real(wp), parameter :: huge = huge(1.0_wp)
    
    ! 数学常数
    real(wp), parameter :: pi = 3.14159265358979323846264338327950288_wp
    real(wp), parameter :: two_pi = 2.0_wp * pi
    real(wp), parameter :: sqrt_pi = sqrt(pi)
end module
```

### 基础数学函数
1. **三角函数**
   - sin, cos, tan, asin, acos, atan
   - 双曲函数：sinh, cosh, tanh
   - 逆双曲函数：asinh, acosh, atanh

2. **指数和对数**
   - exp, log, log10
   - 自然对数、常用对数
   - 数值稳定性处理

3. **特殊函数**
   - 误差函数：erf, erfc
   - 伽马函数：gamma
   - 贝塞尔函数：bessel_j, bessel_y

### 数值微分
```fortran
subroutine numericalDerivative(f, x, h, dfdx)
    interface
        real(wp) function f(x)
            real(wp), intent(in) :: x
        end function
    end interface
    real(wp), intent(in) :: x, h
    real(wp), intent(out) :: dfdx
    
    ! 中心差分
    dfdx = (f(x + h) - f(x - h)) / (2.0_wp * h)
end subroutine
```

### 数值积分
1. **梯形法则**
   - 简单，一阶精度
   - 适用于平滑函数

2. **辛普森法则**
   - 二阶精度
   - 适用于光滑函数

3. **高斯积分**
   - 高阶精度
   - 适用于有限元积分

### 插值算法
1. **线性插值**
   - 简单快速
   - 一阶精度

2. **拉格朗日插值**
   - 高阶精度
   - 适用于任意节点

3. **样条插值**
   - 高阶精度
   - 光滑性好

---

## Bridge/ - 桥接模块域

### 功能描述
桥接模块域提供与外部数值库的接口。

### 参考文档
- BLAS User's Guide
- LAPACK User's Guide
- PETSc User Manual
- MKL Library Reference

### BLAS接口
```fortran
module NM_Bridge_BLAS
    interface
        ! Level 1 BLAS
        subroutine ddot(n, x, incx, y, incy, result)
            integer, intent(in) :: n, incx, incy
            real(wp), intent(in) :: x(*), y(*)
            real(wp), intent(out) :: result
        end subroutine
        
        ! Level 2 BLAS
        subroutine dgemv(trans, m, n, alpha, a, lda, x, incx, beta, y, incy)
            character, intent(in) :: trans
            integer, intent(in) :: m, n, lda, incx, incy
            real(wp), intent(in) :: alpha, beta
            real(wp), intent(in) :: a(lda,*), x(*)
            real(wp), intent(inout) :: y(*)
        end subroutine
        
        ! Level 3 BLAS
        subroutine dgemm(transa, transb, m, n, k, alpha, a, lda, b, ldb, beta, c, ldc)
            character, intent(in) :: transa, transb
            integer, intent(in) :: m, n, k, lda, ldb, ldc
            real(wp), intent(in) :: alpha, beta
            real(wp), intent(in) :: a(lda,*), b(ldb,*)
            real(wp), intent(inout) :: c(ldc,*)
        end subroutine
    end interface
end module
```

### LAPACK接口
```fortran
module NM_Bridge_LAPACK
    interface
        ! 线性方程组求解
        subroutine dgesv(n, nrhs, a, lda, ipiv, b, ldb, info)
            integer, intent(in) :: n, nrhs, lda, ldb, info
            integer, intent(out) :: ipiv(*)
            real(wp), intent(inout) :: a(lda,*), b(ldb,*)
        end subroutine
        
        ! 对称正定方程组
        subroutine dposv(uplo, n, nrhs, a, lda, b, ldb, info)
            character, intent(in) :: uplo
            integer, intent(in) :: n, nrhs, lda, ldb, info
            real(wp), intent(inout) :: a(lda,*), b(ldb,*)
        end subroutine
        
        ! 特征值问题
        subroutine dgeev(jobvl, jobvr, n, a, lda, wr, wi, vl, ldvl, vr, ldvr, work, lwork, info)
            character, intent(in) :: jobvl, jobvr
            integer, intent(in) :: n, lda, ldvl, ldvr, lwork, info
            real(wp), intent(inout) :: a(lda,*)
            real(wp), intent(out) :: wr(*), wi(*)
            real(wp), intent(out) :: vl(ldvl,*), vr(ldvr,*)
            real(wp), intent(inout) :: work(*)
        end subroutine
    end interface
end module
```

### PETSc接口
```fortran
module NM_Bridge_PETSc
    use petsc
    implicit none
    
    ! PETSc向量接口
    interface
        subroutine VecCreate(comm, n, vec, ierr)
            MPI_Comm, intent(in) :: comm
            integer, intent(in) :: n
            Vec, intent(out) :: vec
            integer, intent(out) :: ierr
        end subroutine
    end interface
    
    ! PETSc矩阵接口
    interface
        subroutine MatCreate(comm, m, n, mat, ierr)
            MPI_Comm, intent(in) :: comm
            integer, intent(in) :: m, n
            Mat, intent(out) :: mat
            integer, intent(out) :: ierr
        end subroutine
    end interface
end module
```

### 库选择策略
- 优先顺序：MKL > OpenBLAS > ATLAS
- 自动检测可用库
- 运行时切换
- 性能基准测试

---

## ExternalLibs/ - 外部库域

### 功能描述
外部库域集成第三方数值计算库。

### 参考文档
- ARPACK Documentation
- METIS Documentation
- SuiteSparse Documentation
- FFTW Documentation

### ARPACK（特征值库）
```fortran
module NM_ExternalLibs_ARPACK
    ! ARPACK接口用于大规模特征值问题
    interface
        subroutine dsaupd(ido, bmat, n, which, nev, tol, resid, ncv, v, ldv, iparam, ipntr, workd, workl, lworkl, info)
            integer, intent(inout) :: ido
            character, intent(in) :: bmat, which
            integer, intent(in) :: n, nev, ncv, ldv, lworkl, info
            real(wp), intent(in) :: tol
            real(wp), intent(inout) :: resid(*), v(ldv,*), workd(*), workl(*)
            integer, intent(inout) :: iparam(*), ipntr(*)
        end subroutine
    end interface
end module
```

### METIS（图划分库）
```fortran
module NM_ExternalLibs_METIS
    ! METIS接口用于网格划分
    interface
        subroutine METIS_PartGraphKway(nvtxs, ncon, xadj, adjncy, vwgt, vsize, adjwgt, nparts, tpwgts, options, objval, part, edgecut)
            integer, intent(in) :: nvtxs, ncon, nparts
            integer, intent(in) :: xadj(*), adjncy(*)
            integer, intent(in) :: vwgt(*), vsize(*), adjwgt(*)
            real(wp), intent(in) :: tpwgts(*)
            integer, intent(in) :: options(*)
            integer, intent(out) :: part(*), edgecut
            real(wp), intent(out) :: objval
        end subroutine
    end interface
end module
```

### SuiteSparse（稀疏矩阵库）
```fortran
module NM_ExternalLibs_SuiteSparse
    ! UMFPACK接口
    interface
        subroutine umfpack_di_symbolic(n, Ap, Ai, Symbolic, Control, Info)
            integer, intent(in) :: n
            integer, intent(in) :: Ap(*), Ai(*)
            integer, intent(out) :: Symbolic(*)
            real(wp), intent(in) :: Control(*)
            integer, intent(out) :: Info(*)
        end subroutine
    end interface
end module
```

### FFTW（快速傅里叶变换）
```fortran
module NM_ExternalLibs_FFTW
    use iso_c_binding
    implicit none
    
    type, bind(C) :: fftw_plan
        type(c_ptr) :: ptr
    end type fftw_plan
    
    interface
        type(fftw_plan) function fftw_plan_dft_1d(n, in, out, sign, flags)
            integer(c_int), value :: n, sign, flags
            type(c_ptr), value :: in, out
        end function
    end interface
end module
```

---

## Matrix/ - 矩阵运算域

### 功能描述
矩阵运算域提供稠密和稀疏矩阵运算。

### 参考文档
- Golub, G.H., Van Loan, C.F. - Matrix Computations
- Higham, N.J. - Accuracy and Stability of Numerical Algorithms
- Demmel, J.W. - Applied Numerical Linear Algebra

### 稠密矩阵运算
```fortran
module NM_Matrix_Dense
    ! 矩阵乘法
    subroutine matrixMultiply(A, B, C, m, n, k)
        integer, intent(in) :: m, n, k
        real(wp), intent(in) :: A(m,k), B(k,n)
        real(wp), intent(out) :: C(m,n)
        
        C = 0.0_wp
        do i = 1, m
            do j = 1, n
                do l = 1, k
                    C(i,j) = C(i,j) + A(i,l) * B(l,j)
                end do
            end do
        end do
    end subroutine
end module
```

### 稀疏矩阵格式
1. **CSR格式（Compressed Sparse Row）**
```fortran
type :: SparseMatrixCSR
    integer :: n  ! 矩阵行数
    integer :: m  ! 矩阵列数
    integer :: nnz  ! 非零元素个数
    integer, allocatable :: rowPtr(:)  ! 行指针
    integer, allocatable :: colInd(:)  ! 列索引
    real(wp), allocatable :: values(:)  ! 非零值
end type SparseMatrixCSR
```

2. **CSC格式（Compressed Sparse Column）**
```fortran
type :: SparseMatrixCSC
    integer :: n  ! 矩阵行数
    integer :: m  ! 矩阵列数
    integer :: nnz  ! 非零元素个数
    integer, allocatable :: colPtr(:)  ! 列指针
    integer, allocatable :: rowInd(:)  ! 行索引
    real(wp), allocatable :: values(:)  ! 非零值
end type SparseMatrixCSC
```

### 矩阵分解
1. **LU分解**
```fortran
subroutine luDecomposition(A, L, U, P, n, info)
    integer, intent(in) :: n
    real(wp), intent(in) :: A(n,n)
    real(wp), intent(out) :: L(n,n), U(n,n)
    integer, intent(out) :: P(n)
    integer, intent(out) :: info
    
    ! Doolittle算法
    ! P*A = L*U
end subroutine
```

2. **Cholesky分解**
```fortran
subroutine choleskyDecomposition(A, L, n, info)
    integer, intent(in) :: n
    real(wp), intent(in) :: A(n,n)
    real(wp), intent(out) :: L(n,n)
    integer, intent(out) :: info
    
    ! A = L*L^T
    ! 仅适用于对称正定矩阵
end subroutine
```

3. **QR分解**
```fortran
subroutine qrDecomposition(A, Q, R, m, n, info)
    integer, intent(in) :: m, n
    real(wp), intent(in) :: A(m,n)
    real(wp), intent(out) :: Q(m,m), R(m,n)
    integer, intent(out) :: info
    
    ! A = Q*R
    ! Householder变换
end subroutine
```

### 矩阵求逆
```fortran
subroutine matrixInverse(A, Ainv, n, info)
    integer, intent(in) :: n
    real(wp), intent(in) :: A(n,n)
    real(wp), intent(out) :: Ainv(n,n)
    integer, intent(out) :: info
    
    ! 使用LU分解求逆
    call luDecomposition(A, L, U, P, n, info)
    if (info /= 0) return
    
    ! 求逆
    call solveLU(L, U, P, identity, Ainv, n, info)
end subroutine
```

### 特征值和特征向量
```fortran
subroutine eigenvalues(A, eigenvalues, eigenvectors, n, info)
    integer, intent(in) :: n
    real(wp), intent(in) :: A(n,n)
    real(wp), intent(out) :: eigenvalues(n)
    real(wp), intent(out) :: eigenvectors(n,n)
    integer, intent(out) :: info
    
    ! QR算法
    ! 或调用LAPACK dgeev
end subroutine
```

### 条件数估计
```fortran
function conditionNumber(A, n) result(cond)
    integer, intent(in) :: n
    real(wp), intent(in) :: A(n,n)
    real(wp) :: cond
    
    ! cond(A) = ||A|| * ||A^-1||
    real(wp) :: normA, normAinv
    
    normA = matrixNorm(A, n)
    call matrixInverse(A, Ainv, n, info)
    normAinv = matrixNorm(Ainv, n)
    
    cond = normA * normAinv
end function
```

---

## Solver/ - 求解器域

### 功能描述
求解器域提供线性方程组求解算法。

### 参考文档
- Saad, Y. - Iterative Methods for Sparse Linear Systems
- Templates for the Solution of Linear Systems
- Barrett, R., et al. - Templates for the Solution of Linear Systems

### 直接求解器
```fortran
module NM_Solver_Direct
    ! 高斯消元法
    subroutine gaussianElimination(A, b, x, n, info)
        integer, intent(in) :: n
        real(wp), intent(in) :: A(n,n), b(n)
        real(wp), intent(out) :: x(n)
        integer, intent(out) :: info
        
        ! 前向消元
        do k = 1, n-1
            do i = k+1, n
                factor = A(i,k) / A(k,k)
                A(i,k:n) = A(i,k:n) - factor * A(k,k:n)
                b(i) = b(i) - factor * b(k)
            end do
        end do
        
        ! 回代
        x(n) = b(n) / A(n,n)
        do i = n-1, 1, -1
            x(i) = (b(i) - sum(A(i,i+1:n), x(i+1:n))) / A(i,i)
        end do
    end subroutine
end module
```

### 迭代求解器
1. **共轭梯度法（CG）**
```fortran
subroutine conjugateGradient(A, b, x, n, tolerance, maxIter, info)
    integer, intent(in) :: n, maxIter
    real(wp), intent(in) :: A(n,n), b(n)
    real(wp), intent(out) :: x(n)
    real(wp), intent(in) :: tolerance
    integer, intent(out) :: info
    
    real(wp) :: r(n), p(n), Ap(n), alpha, beta, r_dot_r, r_dot_r_old
    
    ! 初始化
    x = 0.0_wp
    r = b
    p = r
    r_dot_r = dot_product(r, r)
    
    ! CG迭代
    do iter = 1, maxIter
        Ap = matmul(A, p)
        alpha = r_dot_r / dot_product(p, Ap)
        x = x + alpha * p
        r = r - alpha * Ap
        r_dot_r_old = r_dot_r
        r_dot_r = dot_product(r, r)
        
        if (sqrt(r_dot_r) < tolerance) then
            info = 0
            return
        end if
        
        beta = r_dot_r / r_dot_r_old
        p = r + beta * p
    end do
    
    info = -1  ! 未收敛
end subroutine
```

2. **GMRES**
```fortran
subroutine gmres(A, b, x, n, kmax, tolerance, maxIter, info)
    integer, intent(in) :: n, kmax, maxIter
    real(wp), intent(in) :: A(n,n), b(n)
    real(wp), intent(out) :: x(n)
    real(wp), intent(in) :: tolerance
    integer, intent(out) :: info
    
    ! GMRES(m)算法
    ! 使用Arnoldi过程构建Krylov子空间
    ! 最小化残差
end subroutine
```

3. **BiCGStab**
```fortran
subroutine bicgstab(A, b, x, n, tolerance, maxIter, info)
    integer, intent(in) :: n, maxIter
    real(wp), intent(in) :: A(n,n), b(n)
    real(wp), intent(out) :: x(n)
    real(wp), intent(in) :: tolerance
    integer, intent(out) :: info
    
    ! BiCGStab算法
    ! 适用于非对称矩阵
    ! 收敛速度比CG慢，但更稳定
end subroutine
```

### 预处理技术
1. **ILU预处理（不完全LU分解）**
```fortran
subroutine iluPreconditioner(A, L, U, n, fillLevel)
    integer, intent(in) :: n, fillLevel
    real(wp), intent(in) :: A(n,n)
    real(wp), intent(out) :: L(n,n), U(n,n)
    
    ! ILU(k)分解
    ! k为填充级别
end subroutine
```

2. **SSOR预处理（对称超松弛）**
```fortran
subroutine ssorPreconditioner(A, M, n, omega)
    integer, intent(in) :: n
    real(wp), intent(in) :: A(n,n), omega
    real(wp), intent(out) :: M(n,n)
    
    ! SSOR预处理矩阵
    ! M = (D/omega - L) * D^-1 * (D/omega - U)
end subroutine
```

3. **代数多重网格（AMG）**
```fortran
subroutine amgPreconditioner(A, P, n, levels)
    integer, intent(in) :: n, levels
    real(wp), intent(in) :: A(n,n)
    real(wp), intent(out) :: P(n,n)
    
    ! AMG预处理
    ! 粗网格校正
    ! 细网格平滑
end subroutine
```

### 收敛判定
```fortran
function checkConvergence(r, tolerance) result(converged)
    real(wp), intent(in) :: r(:)
    real(wp), intent(in) :: tolerance
    logical :: converged
    
    real(wp) :: r_norm
    
    r_norm = sqrt(dot_product(r, r))
    converged = (r_norm < tolerance)
end function
```

---

## TimeInt/ - 时间积分域

### 功能描述
时间积分域提供各种时间积分算法。

### 参考文档
- Hairer, E., Norsett, S.P., Wanner, G. - Solving Ordinary Differential Equations
- Bathe, K.J. - Finite Element Procedures (Chapter 9)
- Hughes, T.J.R. - The Finite Element Method: Linear Static and Dynamic Finite Element Analysis

### 显式时间积分
1. **中心差分法**
```fortran
subroutine centralDifference(u, v, a, M, K, C, F, dt, totalTime)
    real(wp), intent(inout) :: u(:), v(:), a(:)
    real(wp), intent(in) :: M(:,:), K(:,:), C(:,:), F(:)
    real(wp), intent(in) :: dt, totalTime
    
    real(wp) :: effectiveMass
    integer :: n, i
    
    n = size(u)
    
    ! 有效质量矩阵
    effectiveMass = M(1,1) + dt/2 * C(1,1) + dt^2/4 * K(1,1)
    
    ! 时间步推进
    do while (currentTime < totalTime)
        ! 计算加速度
        a = (F - C*v - K*u) / effectiveMass
        
        ! 更新速度和位移
        v = v + dt * a
        u = u + dt * v
        
        currentTime = currentTime + dt
    end do
end subroutine
```

2. **速度Verlet法**
```fortran
subroutine velocityVerlet(u, v, a, force, mass, dt)
    real(wp), intent(inout) :: u(:), v(:), a(:)
    real(wp), intent(in) :: force(:), mass, dt
    
    ! 半步速度更新
    v = v + 0.5_wp * dt * a
    
    ! 位移更新
    u = u + dt * v
    
    ! 计算新加速度
    a = force / mass
    
    ! 半步速度更新
    v = v + 0.5_wp * dt * a
end subroutine
```

### 隐式时间积分
1. **Newmark方法**
```fortran
subroutine newmark(u, v, a, M, K, C, F, dt, gamma, beta)
    real(wp), intent(inout) :: u(:), v(:), a(:)
    real(wp), intent(in) :: M(:,:), K(:,:), C(:,:), F(:)
    real(wp), intent(in) :: dt, gamma, beta
    
    real(wp) :: u_pred, v_pred, a_new, u_new, v_new
    real(wp) :: K_eff(:,:), F_eff(:)
    
    ! 预测步
    u_pred = u + dt * v + (0.5_wp - beta) * dt^2 * a
    v_pred = v + (1.0_wp - gamma) * dt * a
    
    ! 有效刚度
    K_eff = M + gamma*dt*C + beta*dt^2*K
    
    ! 有效载荷
    F_eff = F + M*((1/dt)*v + (1/(2*dt)-beta)*a) + C*(gamma*v + (gamma-1)*dt*a)
    
    ! 求解线性方程组
    call solveLinearSystem(K_eff, F_eff, delta_u)
    
    ! 修正步
    a_new = (1/(beta*dt^2)) * delta_u
    v_new = v_pred + gamma*dt*a_new
    u_new = u_pred + delta_u
    
    ! 更新
    u = u_new
    v = v_new
    a = a_new
end subroutine
```

2. **HHT方法（Hilber-Hughes-Taylor）**
```fortran
subroutine hht(u, v, a, M, K, C, F, dt, alpha, gamma, beta)
    real(wp), intent(inout) :: u(:), v(:), a(:)
    real(wp), intent(in) :: M(:,:), K(:,:), C(:,:), F(:)
    real(wp), intent(in) :: dt, alpha, gamma, beta
    
    ! HHT方法引入数值阻尼
    ! alpha控制数值阻尼
    ! gamma, beta与Newmark相同
    
    ! 有效刚度
    K_eff = (1+alpha)*M + gamma*dt*C + beta*dt^2*K
    
    ! 有效载荷
    F_eff = (1+alpha)*F - alpha*K*u_pred + M*((1/dt)*v + (1/(2*dt)-beta)*a)
    
    ! 其余步骤与Newmark类似
end subroutine
```

3. **BDF方法（Backward Differentiation Formula）**
```fortran
subroutine bdf(u, u_history, dt, order)
    real(wp), intent(inout) :: u(:)
    real(wp), intent(in) :: u_history(:,:)  ! 历史位移
    real(wp), intent(in) :: dt
    integer, intent(in) :: order
    
    ! BDF(k)方法
    ! 使用前k个时间步的位移
    ! 高阶精度
end subroutine
```

### 自适应时间步长
```fortran
subroutine adaptiveTimeStep(u, v, a, errorEstimator, dt, minDt, maxDt)
    real(wp), intent(in) :: u(:), v(:), a(:)
    real(wp), intent(in) :: errorEstimator
    real(wp), intent(inout) :: dt
    real(wp), intent(in) :: minDt, maxDt
    
    real(wp) :: newDt, safetyFactor = 0.9_wp
    
    ! 基于误差估计调整步长
    newDt = safetyFactor * dt * sqrt(tolerance / errorEstimator)
    
    ! 限制步长范围
    newDt = max(minDt, min(maxDt, newDt))
    
    dt = newDt
end subroutine
```

### 稳定性分析
```fortran
subroutine checkStability(dt, eigenvalues, stable)
    real(wp), intent(in) :: dt
    real(wp), intent(in) :: eigenvalues(:)
    logical, intent(out) :: stable
    
    ! 检查Courant条件
    ! dt <= 2/omega_max
    real(wp) :: omega_max
    
    omega_max = maxval(abs(eigenvalues))
    stable = (dt * omega_max <= 2.0_wp)
end subroutine
```

---

## 总结

L2_NM数值方法层包含6个主要域：
1. **Base/** - 数值基础域：基础数学函数、数值微分积分、插值算法
2. **Bridge/** - 桥接模块域：BLAS、LAPACK、PETSc接口
3. **ExternalLibs/** - 外部库域：ARPACK、METIS、SuiteSparse、FFTW
4. **Matrix/** - 矩阵运算域：稠密/稀疏矩阵运算、矩阵分解、特征值
5. **Solver/** - 求解器域：直接求解器、迭代求解器、预处理技术
6. **TimeInt/** - 时间积分域：显式/隐式时间积分、自适应步长、稳定性分析

每个模块都有详细的算法实现、接口定义和参考文档。
