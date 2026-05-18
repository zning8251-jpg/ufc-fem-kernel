!> @file MD_Orientation_Types.f90
!> @brief L3_MD层 — 材料方向/局部坐标系描述类型
!>
!> 覆盖：局部坐标系、铺层方向、各向异性方向、ORIENT算法控制
!> 语义分类：
!>   Desc  — INP不可变配置（分析期固定）
!>   Algo  — 方向更新算法控制参数
!>
MODULE MD_Orientation_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! ----------------------------------------------------------------
  ! 方向定义方式常量
  ! ----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_ORIENT_DEF_RECT      = 1_i4  ! 直角坐标矩形  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_ORIENT_DEF_CYLI      = 2_i4  ! 圆柱坐标  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_ORIENT_DEF_SPHER     = 3_i4  ! 球坐标  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_ORIENT_DEF_USER      = 4_i4  ! ORIENT子程序  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_ORIENT_DEF_DISCRETE  = 5_i4  ! 离散方向场  ! migrated

  ! 铺层方向参考面常量
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_PLY_REF_ELEM         = 1_i4  ! 单元参考面  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_PLY_REF_GLOBAL       = 2_i4  ! 全局参考面  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_PLY_REF_USER         = 3_i4  ! 用户定义  ! migrated

  ! 方向更新算法常量
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_ORIENT_UPD_NONE      = 0_i4  ! 不更新（小变形）  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_ORIENT_UPD_JAUMANN   = 1_i4  ! Jaumann率  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_ORIENT_UPD_GREEN_NAGDHI = 2_i4  ! Green-Naghdi率  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ORIENT_ORIENT_UPD_POLAR     = 3_i4  ! 极分解更新  ! migrated

  ! ----------------------------------------------------------------
  !> @type MD_LocalCoord_Desc
  !> @brief 局部坐标系描述（INP静态配置，Desc类）
  !>
  !> 存储单元/积分点局部坐标系的参考方向向量及其定义方式。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_LocalCoord_Desc
    INTEGER(i4)  :: def_mode      = MD_ORIENT_ORIENT_DEF_RECT  ! 坐标系定义方式
    INTEGER(i4)  :: csys_id       = 0_i4             ! 关联坐标系ID
    REAL(wp)     :: a_vec(3)      = 0.0_wp           ! 局部a方向向量（全局坐标）
    REAL(wp)     :: b_vec(3)      = 0.0_wp           ! 局部b方向向量（全局坐标）
    REAL(wp)     :: origin(3)     = 0.0_wp           ! 坐标系原点
    REAL(wp)     :: angle_offset  = 0.0_wp           ! 附加旋转角（度）
    LOGICAL      :: is_user       = .FALSE.           ! 是否由ORIENT子程序提供
    LOGICAL      :: is_active     = .TRUE.            ! 是否激活
    TYPE(ErrorStatusType) :: status
  END TYPE MD_LocalCoord_Desc

  ! ----------------------------------------------------------------
  !> @type MD_Ply_Orient_Desc
  !> @brief 复合材料铺层方向描述（Desc类）
  !>
  !> 描述壳/复合单元中每一层的铺层角度、厚度及参考面。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_Ply_Orient_Desc
    INTEGER(i4)  :: n_plies       = 0_i4     ! 铺层总数
    INTEGER(i4)  :: ref_surface   = PLY_REF_ELEM  ! 参考面类型
    INTEGER(i4)  :: mat_id        = 0_i4     ! 对应材料集ID
    INTEGER(i4)  :: section_id    = 0_i4     ! 对应截面ID
    REAL(wp), ALLOCATABLE :: ply_angle(:)    ! 铺层角（度），shape(n_plies)
    REAL(wp), ALLOCATABLE :: ply_thick(:)    ! 铺层厚度，shape(n_plies)
    INTEGER(i4), ALLOCATABLE :: ply_mat_id(:) ! 每铺层材料ID，shape(n_plies)
    LOGICAL      :: symmetric     = .FALSE.   ! 是否对称铺层
    REAL(wp)     :: total_thick   = 0.0_wp   ! 总厚度（预计算）
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Ply_Orient_Desc

  ! ----------------------------------------------------------------
  !> @type MD_AnisoDir_Desc
  !> @brief 各向异性材料纤维方向描述（Desc类）
  !>
  !> 存储单元级或积分点级纤维方向（a0、b0向量），用于
  !> UANISOHYPER等各向异性超弹性/弹性计算。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_AnisoDir_Desc
    INTEGER(i4)  :: n_fiber_dirs  = 1_i4     ! 纤维方向数（1或2）
    REAL(wp)     :: a0(3)         = 0.0_wp   ! 第1纤维参考方向（单位向量）
    REAL(wp)     :: b0(3)         = 0.0_wp   ! 第2纤维参考方向（单位向量，若n>=2）
    REAL(wp)     :: sheet_dir(3)  = 0.0_wp   ! 面内第三正交方向（心肌用途等）
    LOGICAL      :: normalize_on_read = .TRUE.  ! 读入时自动归一化
    LOGICAL      :: from_orient   = .FALSE.   ! 从ORIENT子程序获取
    INTEGER(i4)  :: orient_id     = 0_i4     ! 关联ORIENT描述ID
    TYPE(ErrorStatusType) :: status
  END TYPE MD_AnisoDir_Desc

  ! ----------------------------------------------------------------
  !> @type MD_ORIENT_Algo
  !> @brief 方向更新算法控制参数（Algo类）
  !>
  !> 控制大变形下局部坐标系随变形的跟随/更新策略。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_ORIENT_Algo
    INTEGER(i4)  :: update_scheme = MD_ORIENT_ORIENT_UPD_JAUMANN  ! 更新方案
    LOGICAL      :: update_on_inc = .TRUE.   ! 每增量步更新
    LOGICAL      :: store_rotation= .TRUE.   ! 存储旋转张量
    REAL(wp)     :: tol_ortho     = 1.0e-8_wp  ! 正交归一化容差
    INTEGER(i4)  :: max_iter_orth = 10_i4    ! 最大正交化迭代数
    LOGICAL      :: use_polar_decomp = .FALSE.  ! 强制极分解
    TYPE(ErrorStatusType) :: status
  END TYPE MD_ORIENT_Algo

END MODULE MD_Orientation_Types
