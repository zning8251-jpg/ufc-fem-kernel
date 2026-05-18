!===============================================================================
! MODULE: IF_Sym_Stiffness
! LAYER:  L1_IF
! DOMAIN: Symbol
! ROLE:   Def — stiffness symbol family (matrix index / constitutive / tangent)
! BRIEF:  Compile-time PARAMETER constants for stiffness matrices, constitutive
!         matrix types, tangent stiffness types, and material stiffness params.
!===============================================================================

MODULE IF_Sym_Stiffness
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Part 1: 本构矩阵类型
  !=============================================================================
  !
  ! 用途: 材料本构矩阵类型选择
  ! 理论: D = ∂σ/∂ε (应力-应变关系)
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    CONSTITUTIVE_ELASTIC = 1_i4,       & ! 弹性本构矩阵
    CONSTITUTIVE_ELASTOPLASTIC = 2_i4, & ! 弹塑性本构矩阵
    CONSTITUTIVE_VISCOELASTIC = 3_i4,  & ! 粘弹性本构矩阵
    CONSTITUTIVE_HYPERELASTIC = 4_i4,  & ! 超弹性本构矩阵
    CONSTITUTIVE_DAMAGE = 5_i4,        & ! 损伤本构矩阵
    CONSTITUTIVE_COUPLED = 6_i4          ! 多场耦合本构矩阵

  !=============================================================================
  ! Part 2: 切线刚度类型
  !=============================================================================
  !
  ! 用途: 非线性分析中的切线刚度类型
  ! 理论: K_t = ∂R/∂u (残差对位移的导数)
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    TANGENT_MATERIAL = 1_i4,    & ! 材料切线刚度(本构关系)
    TANGENT_GEOMETRIC = 2_i4,   & ! 几何切线刚度(应力刚度)
    TANGENT_CONSISTENT = 3_i4,  & ! 一致切线刚度(牛顿法二次收敛)
    TANGENT_CONTINUUM = 4_i4,   & ! 连续切线刚度
    TANGENT_ALGORITHMIC = 5_i4    ! 算法切线刚度

  !=============================================================================
  ! Part 3: 单元刚度矩阵分量索引
  !=============================================================================
  !
  ! 用途: 单元刚度矩阵K_e(i,j)的索引约定
  ! 说明: 按节点-自由度顺序排列
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    ELEM_STIFF_ROW = 1_i4,  & ! 行索引(测试函数自由度)
    ELEM_STIFF_COL = 2_i4     ! 列索引( trial函数自由度)

  ! 单元刚度矩阵存储格式
  INTEGER(i4), PARAMETER, PUBLIC :: &
    STIFF_STORAGE_FULL = 1_i4,      & ! 全矩阵存储
    STIFF_STORAGE_SYMMETRIC = 2_i4, & ! 对称存储(上三角)
    STIFF_STORAGE_CSR = 3_i4,       & ! CSR稀疏格式
    STIFF_STORAGE_CSC = 4_i4          ! CSC稀疏格式

  !=============================================================================
  ! Part 4: 材料刚度参数索引
  !=============================================================================
  !
  ! 用途: 材料刚度参数数组索引
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    MAT_PARAM_YOUNG = 1_i4,    & ! 弹性模量 E
    MAT_PARAM_SHEAR = 2_i4,    & ! 剪切模量 G
    MAT_PARAM_BULK = 3_i4,     & ! 体积模量 K
    MAT_PARAM_POISSON = 4_i4,  & ! 泊松比 ν
    MAT_PARAM_LAME1 = 5_i4,    & ! Lamé第一参数 λ
    MAT_PARAM_LAME2 = 6_i4      ! Lamé第二参数 μ (=G)

  ! 材料刚度参数数量
  INTEGER(i4), PARAMETER, PUBLIC :: &
    N_MAT_STIFF_PARAMS = 6_i4

  !=============================================================================
  ! Part 5: 刚度矩阵对称性
  !=============================================================================
  !
  ! 用途: 刚度矩阵对称性标志
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    STIFF_SYMMETRIC = 1_i4,      & ! 对称矩阵
    STIFF_NONSYMMETRIC = 2_i4,   & ! 非对称矩阵
    STIFF_POSITIVE_DEF = 3_i4,   & ! 正定矩阵
    STIFF_INDEFINITE = 4_i4        ! 不定矩阵

  !=============================================================================
  ! Part 6: 刚度矩阵装配模式
  !=============================================================================
  !
  ! 用途: 全局刚度矩阵装配模式
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    ASSEMBLY_SERIAL = 1_i4,     & ! 串行装配
    ASSEMBLY_OMP = 2_i4,        & ! OpenMP并行装配
    ASSEMBLY_ATOMIC = 3_i4,     & ! 原子操作装配
    ASSEMBLY_MPI = 4_i4           ! MPI分布式装配

  !=============================================================================
  ! 初始化子程序(API一致性)
  !=============================================================================
  PUBLIC :: IF_Sym_Stiffness_Init

CONTAINS

  !=============================================================================
  ! IF_Sym_Stiffness_Init - 模块初始化
  !=============================================================================
  SUBROUTINE IF_Sym_Stiffness_Init()
    !! 刚度符号族初始化
    !! 说明: 所有常量为编译时PARAMETER,无需运行时初始化
    !! 存在目的: 与其他UFC模块API保持一致
    
    ! 编译时常量,无需运行时操作
    RETURN
    
  END SUBROUTINE IF_Sym_Stiffness_Init

END MODULE IF_Sym_Stiffness