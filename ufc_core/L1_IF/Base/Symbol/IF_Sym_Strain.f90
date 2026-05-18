!===============================================================================
! MODULE: IF_Sym_Strain
! LAYER:  L1_IF
! DOMAIN: Symbol
! ROLE:   Def — strain symbol family (components / invariants / measures)
! BRIEF:  Voigt strain indices, volumetric/equivalent invariants,
!         Green-Lagrange/Almansi measures, strain-rate types.
!===============================================================================

MODULE IF_Sym_Strain
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Part 1: 应变分量索引 (Voigt记号)
  !=============================================================================
  !
  ! 用途: 应变张量的Voigt记号索引
  ! 说明: 工程剪应变γ_ij = 2*ε_ij (i≠j)
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    STRAIN_XX = 1_i4,  & ! ε_xx (正应变-x方向)
    STRAIN_YY = 2_i4,  & ! ε_yy (正应变-y方向)
    STRAIN_ZZ = 3_i4,  & ! ε_zz (正应变-z方向)
    STRAIN_XY = 4_i4,  & ! γ_xy = 2*ε_xy (工程剪应变-xy平面)
    STRAIN_YZ = 5_i4,  & ! γ_yz = 2*ε_yz (工程剪应变-yz平面)
    STRAIN_XZ = 6_i4     ! γ_xz = 2*ε_xz (工程剪应变-xz平面)

  ! 应变分量数量
  INTEGER(i4), PARAMETER, PUBLIC :: &
    N_STRAIN_3D = 6_i4,  & ! 3D应变分量数
    N_STRAIN_2D = 4_i4,  & ! 2D应变分量数(平面应力/应变)
    N_STRAIN_1D = 1_i4     ! 1D应变分量数(杆/梁)

  !=============================================================================
  ! Part 2: 应变不变量索引
  !=============================================================================
  !
  ! 用途: 应变不变量计算与存储索引
  ! 理论: ε_v=tr(ε), ε_eq=√(2/3*ε':ε')
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    STRAIN_INV_VOL = 1_i4,   & ! 体积应变 ε_v = ε_kk
    STRAIN_INV_EQ = 2_i4,    & ! 等效应变 ε_eq = √(2/3*ε'_ij*ε'_ij)
    STRAIN_INV_MAX_SHEAR = 3_i4 ! 最大剪应变 γ_max = ε1 - ε3

  ! 应变不变量数量
  INTEGER(i4), PARAMETER, PUBLIC :: &
    N_STRAIN_INV = 3_i4

  !=============================================================================
  ! Part 3: 主应变索引
  !=============================================================================
  !
  ! 用途: 主应变排序(ε1≥ε2≥ε3)
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    PRINCIPAL_E1 = 1_i4,  & ! 第一主应变(最大)
    PRINCIPAL_E2 = 2_i4,  & ! 第二主应变
    PRINCIPAL_E3 = 3_i4     ! 第三主应变(最小)

  ! 主应变数量
  INTEGER(i4), PARAMETER, PUBLIC :: &
    N_PRINCIPAL_STRAIN = 3_i4

  !=============================================================================
  ! Part 4: 应变度量类型
  !=============================================================================
  !
  ! 用途: 大变形分析中的应变度量选择
  ! 理论: 不同应变度量适用于不同本构框架
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    STRAIN_MEASURE_ENG = 1_i4,            & ! 工程应变(小变形)
    STRAIN_MEASURE_GREEN_LAGRANGE = 2_i4, & ! Green-Lagrange应变 E = 1/2(F^T·F - I)
    STRAIN_MEASURE_ALMANSI = 3_i4,        & ! Almansi应变 e = 1/2(I - F^(-T)·F^(-1))
    STRAIN_MEASURE_LOG = 4_i4,            & ! 对数应变(自然应变) ε = ln(λ)
    STRAIN_MEASURE_BIOT = 5_i4              ! Biot应变 U - I

  !=============================================================================
  ! Part 5: 应变率类型
  !=============================================================================
  !
  ! 用途: 率相关本构中的应变率类型
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    STRAIN_RATE_SMALL = 1_i4,        & ! 小变形应变率 ε̇ = dε/dt
    STRAIN_RATE_DEFORMATION = 2_i4,  & ! 变形率张量 D = sym(L)
    STRAIN_RATE_GREEN_LAGRANGE = 3_i4  ! Green-Lagrange应变率 Ė

  !=============================================================================
  ! Part 6: 等效应变类型
  !=============================================================================
  !
  ! 用途: 等效应变计算
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    EQUIV_STRAIN_VON_MISES = 1_i4,  & ! Von Mises等效应变
    EQUIV_STRAIN_TRESCA = 2_i4        ! Tresca等效应变

  !=============================================================================
  ! 初始化子程序(API一致性)
  !=============================================================================
  PUBLIC :: IF_Sym_Strain_Init

CONTAINS

  !=============================================================================
  ! IF_Sym_Strain_Init - 模块初始化
  !=============================================================================
  SUBROUTINE IF_Sym_Strain_Init()
    !! 应变符号族初始化
    !! 说明: 所有常量为编译时PARAMETER,无需运行时初始化
    !! 存在目的: 与其他UFC模块API保持一致
    
    ! 编译时常量,无需运行时操作
    RETURN
    
  END SUBROUTINE IF_Sym_Strain_Init

END MODULE IF_Sym_Strain