!===============================================================================
! Module: NM_Matrix_Domain_Template                           [Template v3.2]
! Layer:  L2_NM — Numerical Methods Layer
! Domain: Matrix — Domain 容器参考实现
!
! PURPOSE:
!   演示 NM_Matrix 域如何实现 Domain 容器模式，包括：
!   - ABSTRACT BASE TYPE + EXTENDS 多态设计
!   - Domain 容器与生命周期管理 (Init/Finalize/WriteBack)
!   - 精度统一 (wp, i4) + IF_Err_Brg structured status 返回机制
!
! MODIFICATIONS:
!   [Template v3.1] 初始版本 (基于 MD_Mat_Types.f90 范式)
!   [Template v3.2] 新增 Domain 容器完整实现、精度统一、错误处理
!   [Comment refresh] 注释对齐 IF_Err_Brg + structured status baseline
!===============================================================================
MODULE NM_Matrix_Domain_Template
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  ! ===== PUBLIC 接口 =====
  PUBLIC :: NM_Matrix_Base_Desc, NM_Matrix_Dense_Desc, NM_Matrix_Sparse_Desc
  PUBLIC :: NM_Matrix_State, NM_Matrix_Algo, NM_Matrix_Ctx, NM_Matrix_Domain

  ! ===== CONSTANTS =====
  INTEGER(i4), PARAMETER :: NM_MATRIX_DENSE = 1_i4
  INTEGER(i4), PARAMETER :: NM_MATRIX_SPARSE_CSR = 2_i4
  INTEGER(i4), PARAMETER :: NM_MATRIX_SPARSE_CSC = 3_i4

  ! ===============================================================================
  ! ABSTRACT BASE TYPE — 多态设计入口
  ! ===============================================================================
  TYPE, PUBLIC, ABSTRACT :: NM_Matrix_Base_Desc
    INTEGER(i4) :: nrow = 0_i4, ncol = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    CHARACTER(len=16) :: storage_fmt = "DENSE"
    LOGICAL :: is_symmetric = .FALSE.
    LOGICAL :: is_positive_definite = .FALSE.
    REAL(wp) :: condition_number = 0.0_wp
    REAL(wp) :: sparsity_ratio = 0.0_wp
  END TYPE NM_Matrix_Base_Desc

  ! ===============================================================================
  ! 具体扩展类型 1: 稠密矩阵
  ! ===============================================================================
  TYPE, PUBLIC, EXTENDS(NM_Matrix_Base_Desc) :: NM_Matrix_Dense_Desc
    INTEGER(i4) :: leading_dim = 0_i4
    INTEGER(i4), ALLOCATABLE :: perm(:)
  END TYPE NM_Matrix_Dense_Desc

  ! ===============================================================================
  ! 具体扩展类型 2: 稀疏矩阵 (CSR 格式)
  ! ===============================================================================
  TYPE, PUBLIC, EXTENDS(NM_Matrix_Base_Desc) :: NM_Matrix_Sparse_Desc
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)
    INTEGER(i4), ALLOCATABLE :: col_idx(:)
    REAL(wp), ALLOCATABLE :: val(:)
  END TYPE NM_Matrix_Sparse_Desc

  ! ===============================================================================
  ! State 类型 — 求解状态
  ! ===============================================================================
  TYPE, PUBLIC :: NM_Matrix_State
    INTEGER(i4) :: factorization_status = 0_i4  ! 0=未分解, 1=LU, 2=Cholesky, 3=QR
    LOGICAL :: is_singular = .FALSE.
    REAL(wp) :: residual_norm = 0.0_wp
    INTEGER(i4) :: rank_estimate = 0_i4
    INTEGER(i4) :: num_operations = 0_i4
    ! structured status; concrete bridges typically call init_error_status(...)
    ! and inspect status%status_code after Domain operations return
    TYPE(ErrorStatusType) :: status
  END TYPE NM_Matrix_State

  ! ===============================================================================
  ! Algo 类型 — 算法参数
  ! ===============================================================================
  TYPE, PUBLIC :: NM_Matrix_Algo
    LOGICAL :: use_pivot = .TRUE.
    LOGICAL :: check_symmetry = .FALSE.
    CHARACTER(len=16) :: norm_type = "L2"
    REAL(wp) :: drop_tolerance = 0.0_wp
    INTEGER(i4) :: max_rank = 0_i4
  END TYPE NM_Matrix_Algo

  ! ===============================================================================
  ! Ctx 类型 — 运行上下文
  ! ===============================================================================
  TYPE, PUBLIC :: NM_Matrix_Ctx
    INTEGER(i4) :: matrix_id = 0_i4
    CHARACTER(len=64) :: matrix_label = ""
    REAL(wp) :: assembly_time = 0.0_wp
    REAL(wp) :: factorization_time = 0.0_wp
    LOGICAL :: trace_operations = .FALSE.
    CHARACTER(len=256) :: operation_log_file = ""
  END TYPE NM_Matrix_Ctx

  ! ===============================================================================
  ! Domain 容器 — 矩阵集合的生命周期管理
  ! ===============================================================================
  TYPE, PUBLIC :: NM_Matrix_Domain
    CLASS(NM_Matrix_Base_Desc), POINTER :: desc(:) => NULL()
    TYPE(NM_Matrix_State), POINTER :: state(:) => NULL()
    TYPE(NM_Matrix_Algo), POINTER :: algo(:) => NULL()
    TYPE(NM_Matrix_Ctx), POINTER :: ctx(:) => NULL()
    INTEGER(i4) :: n_matrices = 0_i4
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => NM_Matrix_Domain_Init
    PROCEDURE :: Finalize => NM_Matrix_Domain_Finalize
    PROCEDURE :: WriteBack => NM_Matrix_WriteBack
  END TYPE NM_Matrix_Domain

CONTAINS

  ! ===============================================================================
  ! 实现: Domain 初始化
  ! ===============================================================================
  SUBROUTINE NM_Matrix_Domain_Init(this, n_matrices, status)
    CLASS(NM_Matrix_Domain), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: n_matrices
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! 输入检查
    IF (n_matrices <= 0_i4) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "NM_Matrix_Domain_Init: n_matrices 必须 > 0"
      RETURN
    END IF

    ! 分配数组
    IF (ASSOCIATED(this%desc)) DEALLOCATE(this%desc)
    IF (ASSOCIATED(this%state)) DEALLOCATE(this%state)
    IF (ASSOCIATED(this%algo)) DEALLOCATE(this%algo)
    IF (ASSOCIATED(this%ctx)) DEALLOCATE(this%ctx)

    ALLOCATE(NM_Matrix_Dense_Desc :: this%desc(n_matrices))
    ALLOCATE(this%state(n_matrices))
    ALLOCATE(this%algo(n_matrices))
    ALLOCATE(this%ctx(n_matrices))

    this%n_matrices = n_matrices
    this%initialized = .TRUE.

    ! 返回 structured status success; caller inspects status%status_code
    status%status_code = IF_STATUS_OK
    status%message = "NM_Matrix_Domain 初始化成功"
  END SUBROUTINE NM_Matrix_Domain_Init

  ! ===============================================================================
  ! 实现: Domain 清理
  ! ===============================================================================
  SUBROUTINE NM_Matrix_Domain_Finalize(this, status)
    CLASS(NM_Matrix_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "NM_Matrix_Domain 未初始化"
      RETURN
    END IF

    ! 释放矩阵特定的内存 (如稀疏矩阵的 row_ptr, col_idx, val)
    ! 这里仅演示框架，具体实现需根据 desc(:) 的类型来处理
    
    ! 释放容器本身
    IF (ASSOCIATED(this%desc)) DEALLOCATE(this%desc)
    IF (ASSOCIATED(this%state)) DEALLOCATE(this%state)
    IF (ASSOCIATED(this%algo)) DEALLOCATE(this%algo)
    IF (ASSOCIATED(this%ctx)) DEALLOCATE(this%ctx)

    this%n_matrices = 0_i4
    this%initialized = .FALSE.

    ! 返回 structured status success; caller inspects status%status_code
    status%status_code = IF_STATUS_OK
    status%message = "NM_Matrix_Domain 清理完成"
  END SUBROUTINE NM_Matrix_Domain_Finalize

  ! ===============================================================================
  ! 实现: Domain WriteBack — 将计算结果写回或持久化
  ! ===============================================================================
  SUBROUTINE NM_Matrix_WriteBack(this, status)
    CLASS(NM_Matrix_Domain), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "NM_Matrix_Domain 未初始化"
      RETURN
    END IF

    ! 演示: 将每个矩阵的求解统计写到日志
    DO i = 1_i4, this%n_matrices
      IF (LEN_TRIM(this%ctx(i)%operation_log_file) > 0_i4) THEN
        ! 这里可以实现具体的文件 I/O 逻辑
        PRINT *, "WriteBack: 矩阵 #", i, " -> ", TRIM(this%ctx(i)%operation_log_file)
      END IF
    END DO

    ! 返回 structured status success; caller inspects status%status_code
    status%status_code = IF_STATUS_OK
    status%message = "NM_Matrix_Domain WriteBack 完成"
  END SUBROUTINE NM_Matrix_WriteBack

END MODULE NM_Matrix_Domain_Template
