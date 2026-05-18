!===============================================================================
! MODULE: IF_Sym_Stress
! LAYER:  L1_IF
! DOMAIN: Symbol
! ROLE:   Def — stress symbol family (components / invariants / yield criteria)
! BRIEF:  Voigt stress indices, I1/J2/J3/Lode invariants, Cauchy/Kirchhoff
!         stress rates, Von Mises/Tresca/Drucker-Prager yield criteria.
!===============================================================================

MODULE IF_Sym_Stress
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  ! PUBLIC declarations for API
  PUBLIC :: IF_Sym_Stress_Init
  PUBLIC :: N_STRESS_3D, N_STRESS_2D, N_STRESS_1D
  PUBLIC :: N_STRESS_INV, N_PRINCIPAL_STRESS
  PUBLIC :: STRESS_XX, STRESS_YY, STRESS_ZZ, STRESS_XY, STRESS_YZ, STRESS_XZ
  PUBLIC :: INV_I1, INV_J2, INV_J3, INV_LODE
  PUBLIC :: PRINCIPAL_S1, PRINCIPAL_S2, PRINCIPAL_S3
  PUBLIC :: STRESS_RATE_CAUCHY, STRESS_RATE_KIRCHHOFF, STRESS_RATE_NOMINAL
  PUBLIC :: STRESS_RATE_2PK, STRESS_RATE_JAUMANN, STRESS_RATE_TRUESDELL
  PUBLIC :: YIELD_VON_MISES, YIELD_TRESCA, YIELD_DRUCKER_PRAGER
  PUBLIC :: YIELD_MOHR_COULOMB, YIELD_HILL, YIELD_BARLAT
  PUBLIC :: EQUIV_STRESS_VON_MISES, EQUIV_STRESS_TRESCA

  !=============================================================================
  ! Part 1: 应力分量索引 (Voigt记号)
  !=============================================================================
  !
  ! 用途: 应力/应变张量的Voigt记号索引
  ! 说明: 3D情况下6个分量,2D情况下4个分量
  !
  INTEGER(i4), PARAMETER :: &
    STRESS_XX = 1_i4,  & ! σ_xx (正应力-x方向)
    STRESS_YY = 2_i4,  & ! σ_yy (正应力-y方向)
    STRESS_ZZ = 3_i4,  & ! σ_zz (正应力-z方向)
    STRESS_XY = 4_i4,  & ! τ_xy (剪应力-xy平面)
    STRESS_YZ = 5_i4,  & ! τ_yz (剪应力-yz平面)
    STRESS_XZ = 6_i4     ! τ_xz (剪应力-xz平面)

  ! 应力分量数量
  INTEGER(i4), PARAMETER :: &
    N_STRESS_3D = 6_i4,  & ! 3D应力分量数
    N_STRESS_2D = 4_i4,  & ! 2D应力分量数(平面应力/应变)
    N_STRESS_1D = 1_i4     ! 1D应力分量数(杆/梁)

  !=============================================================================
  ! Part 2: 应力不变量索引
  !=============================================================================
  !
  ! 用途: 应力不变量计算与存储索引
  ! 理论: I1=tr(σ), J2=1/2*s:s, J3=det(s), θ=Lode角
  !
  INTEGER(i4), PARAMETER :: &
    INV_I1 = 1_i4,  & ! 第一应力不变量 I1 = σ_kk
    INV_J2 = 2_i4,  & ! 第二偏应力不变量 J2 = 1/2*s_ij*s_ij
    INV_J3 = 3_i4,  & ! 第三偏应力不变量 J3 = det(s_ij)
    INV_LODE = 4_i4   ! Lode角 θ = 1/3*arcsin(-3√3/2 * J3/J2^(3/2))

  ! 应力不变量数量
  INTEGER(i4), PARAMETER :: &
    N_STRESS_INV = 4_i4

  !=============================================================================
  ! Part 3: 主应力索引
  !=============================================================================
  !
  ! 用途: 主应力排序(σ1≥σ2≥σ3)
  !
  INTEGER(i4), PARAMETER :: &
    PRINCIPAL_S1 = 1_i4,  & ! 第一主应力(最大)
    PRINCIPAL_S2 = 2_i4,  & ! 第二主应力
    PRINCIPAL_S3 = 3_i4     ! 第三主应力(最小)

  ! 主应力数量
  INTEGER(i4), PARAMETER :: &
    N_PRINCIPAL_STRESS = 3_i4

  !=============================================================================
  ! Part 4: 应力率类型
  !=============================================================================
  !
  ! 用途: 大变形分析中的应力率类型选择
  ! 理论: 不同应力率适用于不同本构框架
  !
  INTEGER(i4), PARAMETER :: &
    STRESS_RATE_CAUCHY = 1_i4,      & ! Cauchy应力率(小变形)
    STRESS_RATE_KIRCHHOFF = 2_i4,   & ! Kirchhoff应力率(τ=Jσ)
    STRESS_RATE_NOMINAL = 3_i4,     & ! 名义应力率(第一Piola-Kirchhoff)
    STRESS_RATE_2PK = 4_i4,         & ! 第二Piola-Kirchhoff应力率
    STRESS_RATE_JAUMANN = 5_i4,     & ! Jaumann应力率(客观应力率)
    STRESS_RATE_TRUESDELL = 6_i4      ! Truesdell应力率(客观应力率)

  !=============================================================================
  ! Part 5: 屈服准则索引
  !=============================================================================
  !
  ! 用途: 塑性本构中的屈服准则选择
  !
  INTEGER(i4), PARAMETER :: &
    YIELD_VON_MISES = 1_i4,       & ! Von Mises准则(J2)
    YIELD_TRESCA = 2_i4,          & ! Tresca准则(最大剪应力)
    YIELD_DRUCKER_PRAGER = 3_i4,  & ! Drucker-Prager准则(地质材料)
    YIELD_MOHR_COULOMB = 4_i4,    & ! Mohr-Coulomb准则(地质材料)
    YIELD_HILL = 5_i4,            & ! Hill'48准则(各向异性)
    YIELD_BARLAT = 6_i4             ! Barlat Yld2000准则(薄板)

  !=============================================================================
  ! Part 6: 等效应力类型
  !=============================================================================
  !
  ! 用途: 等效应力(Von Mises应力)计算
  !
  INTEGER(i4), PARAMETER :: &
    EQUIV_STRESS_VON_MISES = 1_i4,  & ! Von Mises等效应力
    EQUIV_STRESS_TRESCA = 2_i4        ! Tresca等效应力

  !=============================================================================
  ! 初始化子程序(API一致性)
  !=============================================================================

CONTAINS

  !=============================================================================
  ! IF_Sym_Stress_Init - 模块初始化
  !=============================================================================
  SUBROUTINE IF_Sym_Stress_Init()
    !! 应力符号族初始化
    !! 说明: 所有常量为编译时PARAMETER,无需运行时初始化
    !! 存在目的: 与其他UFC模块API保持一致
    
    ! 编译时常量,无需运行时操作
    RETURN
    
  END SUBROUTINE IF_Sym_Stress_Init

END MODULE IF_Sym_Stress