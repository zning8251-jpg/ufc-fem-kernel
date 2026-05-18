MODULE NM_Base_Def
  !===============================================================================
  ! MODULE: NM_Base_Def
  ! LAYER:  L2_NM - Base Domain
  ! PURPOSE: Mathematical constants for numerical algorithms
  ! DESIGN: Pure constants module - no procedures, no state
  !===============================================================================
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  
  !--------------------------------------------------------------------
  ! Mathematical constants (PUBLIC)
  !--------------------------------------------------------------------
  REAL(wp), PARAMETER, PUBLIC :: NM_PI = 3.14159265358979323846_wp
  REAL(wp), PARAMETER, PUBLIC :: NM_TWO_PI = 2.0_wp * NM_PI
  REAL(wp), PARAMETER, PUBLIC :: NM_HALF_PI = 0.5_wp * NM_PI
  REAL(wp), PARAMETER, PUBLIC :: NM_EULER = 2.71828182845904523536_wp
  REAL(wp), PARAMETER, PUBLIC :: NM_SQRT2 = 1.41421356237309504880_wp
  REAL(wp), PARAMETER, PUBLIC :: NM_SQRT3 = 1.73205080756887729352_wp
  
  !--------------------------------------------------------------------
  ! Default tolerances and limits
  !--------------------------------------------------------------------
  REAL(wp), PARAMETER, PUBLIC :: NM_TOL_DEFAULT = 1.0E-8_wp
  REAL(wp), PARAMETER, PUBLIC :: NM_TOL_STRICT = 1.0E-12_wp
  REAL(wp), PARAMETER, PUBLIC :: NM_TOL_LOOSE = 1.0E-6_wp
  REAL(wp), PARAMETER, PUBLIC :: NM_ZERO_TOL = 1.0E-14_wp
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MAX_ITER_DEFAULT = 1000_i4
  

  !---------------------------------------------------------------------------
  ! Merged from NM_Base_Def (solver/control types)
  !---------------------------------------------------------------------------
    PUBLIC :: NM_ArcLen_Type
    PUBLIC :: NM_EigenSolv_Type
    PUBLIC :: NM_LinSolv_Type
    PUBLIC :: NM_NLSolv_Type
    PUBLIC :: NM_NumCtrl_Type
    PUBLIC :: NM_Precond_Type
    PUBLIC :: NM_TimeInt_Type
    INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_DIRECT   = 1_i4  ! Direct solver
    INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_CG       = 2_i4  ! Conjugate Gradient
    INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_GMRES    = 3_i4  ! GMRES
    INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_BICGSTAB = 4_i4  ! BiCGSTAB
    INTEGER(i4), PARAMETER, PUBLIC :: NM_NL_NR        = 1_i4  ! Full Newton-Raphson
    INTEGER(i4), PARAMETER, PUBLIC :: NM_NL_MOD_NR    = 2_i4  ! Modified Newton-Raphson
    INTEGER(i4), PARAMETER, PUBLIC :: NM_NL_QUASI_NR  = 3_i4  ! Quasi-Newton (BFGS/L-BFGS)
    INTEGER(i4), PARAMETER, PUBLIC :: NM_NL_ARCLENGTH = 4_i4  ! Arc-length
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_NONE  = 0_i4  ! No preconditioner
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_DIAG  = 1_i4  ! Diagonal (Jacobi)
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_ILU0  = 2_i4  ! ILU(0)
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_ILUT  = 3_i4  ! ILUT
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_AMG   = 4_i4  ! Algebraic Multigrid
    INTEGER(i4), PARAMETER, PUBLIC :: NM_EIGEN_LANCZOS  = 1_i4  ! Lanczos
    INTEGER(i4), PARAMETER, PUBLIC :: NM_EIGEN_ARNOLDI  = 2_i4  ! Arnoldi / ARPACK
    INTEGER(i4), PARAMETER, PUBLIC :: NM_EIGEN_SUBSPACE = 3_i4  ! Subspace iteration
    INTEGER(i4), PARAMETER, PUBLIC :: NM_TI_NEWMARK_BETA   = 1_i4  ! Newmark-β
    INTEGER(i4), PARAMETER, PUBLIC :: NM_TI_HHT_ALPHA      = 2_i4  ! HHT-α
    INTEGER(i4), PARAMETER, PUBLIC :: NM_TI_CENTRAL_DIFF   = 3_i4  ! Central differences (explicit)
    INTEGER(i4), PARAMETER, PUBLIC :: NM_TI_BACKWARD_EULER = 4_i4  ! Backward Euler
    TYPE :: NM_ArcLen_Type
        REAL(wp)    :: arcLen     = 0.0_wp     ! Current arc-length
        INTEGER(i4) :: method     = 1_i4       ! 1=CRISFIELD, 2=RAMM, 3=RIKS
        REAL(wp)    :: maxStep    = 0.1_wp     ! Maximum step size
        REAL(wp)    :: minStep    = 1.0e-6_wp  ! Minimum step size
        LOGICAL     :: enAdaptStep = .TRUE.    ! Enable adaptive stepping
    END TYPE NM_ArcLen_Type

    TYPE :: NM_LinSolv_Type
        INTEGER(i4)        :: solvType   = NM_LINSOL_CG    ! Solver type
        INTEGER(i4)        :: precType   = NM_PREC_ILU0    ! Preconditioner type
        REAL(wp)           :: tol        = 1.0e-8_wp       ! Relative tolerance
        INTEGER(i4)        :: maxIter    = 1000_i4         ! Max iterations
        LOGICAL            :: usePrecond = .TRUE.           ! Use preconditioner
        LOGICAL            :: enResOut   = .FALSE.          ! Output residual history
        CHARACTER(LEN=64)  :: directSolv = "MUMPS"         ! Direct solver name
    END TYPE NM_LinSolv_Type

    TYPE :: NM_NLSolv_Type
        INTEGER(i4)  :: method       = NM_NL_NR    ! Nonlinear method
        REAL(wp)     :: tol          = 1.0e-6_wp   ! Force/energy tolerance
        INTEGER(i4)  :: maxIter      = 50_i4       ! Max Newton iterations
        LOGICAL      :: enLineSearch = .TRUE.       ! Enable line search
        TYPE(NM_ArcLen_Type) :: ArcLen              ! Arc-length parameters
    END TYPE NM_NLSolv_Type

    TYPE :: NM_EigenSolv_Type
        INTEGER(i4)  :: method    = NM_EIGEN_LANCZOS  ! Algorithm
        INTEGER(i4)  :: nEigen    = 10_i4             ! Number of eigenvalues
        REAL(wp)     :: tol       = 1.0e-8_wp         ! Convergence tolerance
        INTEGER(i4)  :: maxIter   = 300_i4            ! Max iterations
        INTEGER(i4)  :: blockSize = 1_i4              ! Block size (LOBPCG)
        LOGICAL      :: massNorm  = .TRUE.             ! Mass-normalise eigenvectors
    END TYPE NM_EigenSolv_Type

    TYPE :: NM_TimeInt_Type
        INTEGER(i4)  :: scheme     = NM_TI_NEWMARK_BETA  ! Scheme
        REAL(wp)     :: beta       = 0.25_wp             ! Newmark β
        REAL(wp)     :: gamma      = 0.5_wp              ! Newmark γ
        REAL(wp)     :: alpha      = 0.0_wp              ! HHT α (negative damping)
        LOGICAL      :: enAdapt    = .FALSE.              ! Adaptive time stepping
        REAL(wp)     :: dtMax      = 1.0_wp              ! Maximum dt
        REAL(wp)     :: dtMin      = 1.0e-8_wp           ! Minimum dt
    END TYPE NM_TimeInt_Type

    TYPE :: NM_Precond_Type
        INTEGER(i4)  :: precType   = NM_PREC_ILU0   ! Preconditioner type
        INTEGER(i4)  :: fillLevel  = 0_i4            ! ILU fill level
        REAL(wp)     :: dropTol    = 1.0e-4_wp       ! ILUT drop tolerance
        INTEGER(i4)  :: amgCycle   = 1_i4            ! AMG cycle: 1=V, 2=W, 3=F
        INTEGER(i4)  :: amgSmooth  = 2_i4            ! AMG smoother sweeps
        LOGICAL      :: enReorder  = .FALSE.          ! Enable matrix reordering
    END TYPE NM_Precond_Type

    TYPE :: NM_NumCtrl_Type
        TYPE(NM_LinSolv_Type)   :: LinSolv     ! Linear solver config
        TYPE(NM_NLSolv_Type)    :: NLSolv      ! Nonlinear solver config
        TYPE(NM_EigenSolv_Type) :: EigenSolv   ! Eigenvalue solver config
        TYPE(NM_TimeInt_Type)   :: TimeInt     ! Time integration config
        TYPE(NM_Precond_Type)   :: Precond     ! Preconditioner config
    END TYPE NM_NumCtrl_Type


END MODULE NM_Base_Def
