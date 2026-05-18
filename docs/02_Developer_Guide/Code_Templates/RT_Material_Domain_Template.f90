!===============================================================================
! Module: RT_Material_Domain_Template                          [Template v3.2]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Material — Domain 容器参考实现
!
! PURPOSE:
!   演示 RT_Material 域如何实现 Domain 容器模式，包括：
!   - ABSTRACT BASE TYPE + EXTENDS 多态设计（支持 UMAT/VUMAT）
!   - Domain 容器与生命周期管理 (Init/Finalize/WriteBack)
!   - 精度统一 (wp, i4) + IF_Err_Brg structured status 基线
!   - 材料库初始化、参数加载、UMAT 指针管理
!
! MODIFICATIONS:
!   [Template v3.1] 初始版本
!   [Template v3.2] 新增 Domain 容器、UMAT 调度框架、ErrorStatusType 集成
!   [Template v3.2] 注释对齐 IF_Err_Brg + structured status baseline
!===============================================================================
MODULE RT_Material_Domain_Template
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Material_Base_Desc, RT_Material_UMAT_Desc
  PUBLIC :: RT_Material_State, RT_Material_Algo, RT_Material_Ctx
  PUBLIC :: RT_Material_Domain

  ! ===== CONSTANTS =====
  INTEGER(i4), PARAMETER :: RT_MATERIAL_ELASTIC = 1_i4
  INTEGER(i4), PARAMETER :: RT_MATERIAL_PLASTIC = 2_i4
  INTEGER(i4), PARAMETER :: RT_MATERIAL_HYPER = 3_i4
  INTEGER(i4), PARAMETER :: RT_MATERIAL_THERMAL = 4_i4

  ! ===============================================================================
  ! ABSTRACT BASE TYPE — 多态设计入口
  ! ===============================================================================
  TYPE, PUBLIC, ABSTRACT :: RT_Material_Base_Desc
    INTEGER(i4) :: num_materials = 0_i4
    INTEGER(i4) :: max_statev = 1000_i4
    LOGICAL :: use_caching = .TRUE.
    INTEGER(i4) :: cache_size = 100_i4
    INTEGER(i4) :: num_elastic = 0_i4
    INTEGER(i4) :: num_plastic = 0_i4
    INTEGER(i4) :: num_hyperelastic = 0_i4
    INTEGER(i4) :: num_thermal = 0_i4
    CHARACTER(len=32) :: material_lib_version = "2.0"
    INTEGER(i4) :: material_update_counter = 0_i4
  END TYPE RT_Material_Base_Desc

  ! ===============================================================================
  ! 具体扩展类型: UMAT 材料族
  ! ===============================================================================
  TYPE, PUBLIC, EXTENDS(RT_Material_Base_Desc) :: RT_Material_UMAT_Desc
    CHARACTER(len=64) :: umat_dll_path = ""
    LOGICAL :: use_user_defined_umat = .FALSE.
    INTEGER(i4) :: umat_interface_version = 1_i4
  END TYPE RT_Material_UMAT_Desc

  ! ===============================================================================
  ! State 类型 — 材料库状态
  ! ===============================================================================
  TYPE, PUBLIC :: RT_Material_State
    INTEGER(i4), ALLOCATABLE :: mat_ids(:)
    CHARACTER(len=32), ALLOCATABLE :: families(:)
    REAL(wp), ALLOCATABLE :: props(:,:)
    REAL(wp), ALLOCATABLE :: statev(:)
    INTEGER(i4), ALLOCATABLE :: statev_offset(:)
    INTEGER(i4), ALLOCATABLE :: statev_length(:)
    INTEGER(i4) :: total_statev = 0_i4
    LOGICAL, ALLOCATABLE :: cache_valid(:)
    INTEGER(i4), ALLOCATABLE :: cache_step_id(:)
    INTEGER(i4), ALLOCATABLE :: cache_age(:)
    INTEGER(i4) :: umat_call_count = 0_i4
    REAL(wp) :: umat_total_time = 0.0_wp
    LOGICAL :: trace_material_calls = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Material_State

  ! ===============================================================================
  ! Algo 类型 — 算法控制
  ! ===============================================================================
  TYPE, PUBLIC :: RT_Material_Algo
    LOGICAL :: use_umat_init_mode = .TRUE.
    LOGICAL :: validate_props_before_compute = .TRUE.
    LOGICAL :: enable_material_caching = .TRUE.
    INTEGER(i4) :: cache_eviction_policy = 1_i4  ! 1=LRU, 2=FIFO
  END TYPE RT_Material_Algo

  ! ===============================================================================
  ! Ctx 类型 — 运行上下文
  ! ===============================================================================
  TYPE, PUBLIC :: RT_Material_Ctx
    INTEGER(i4) :: lib_id = 0_i4
    CHARACTER(len=64) :: lib_name = ""
    REAL(wp) :: init_time = 0.0_wp
    LOGICAL :: initialized = .FALSE.
    CHARACTER(len=256) :: log_file = ""
  END TYPE RT_Material_Ctx

  ! ===============================================================================
  ! Domain 容器 — 材料库集合的生命周期管理
  ! ===============================================================================
  TYPE, PUBLIC :: RT_Material_Domain
    CLASS(RT_Material_Base_Desc), POINTER :: desc(:) => NULL()
    TYPE(RT_Material_State), POINTER :: state(:) => NULL()
    TYPE(RT_Material_Algo), POINTER :: algo(:) => NULL()
    TYPE(RT_Material_Ctx), POINTER :: ctx(:) => NULL()
    INTEGER(i4) :: n_libs = 0_i4
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => RT_Material_Domain_Init
    PROCEDURE :: Finalize => RT_Material_Domain_Finalize
    PROCEDURE :: WriteBack => RT_Material_WriteBack
  END TYPE RT_Material_Domain

CONTAINS

  ! ===============================================================================
  ! 实现: Domain 初始化
  ! ===============================================================================
  SUBROUTINE RT_Material_Domain_Init(this, n_libs, status)
    CLASS(RT_Material_Domain), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: n_libs
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (n_libs <= 0_i4) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "RT_Material_Domain_Init: n_libs 必须 > 0"
      RETURN
    END IF

    ! 释放已有的数组（如果存在）
    IF (ASSOCIATED(this%desc)) DEALLOCATE(this%desc)
    IF (ASSOCIATED(this%state)) DEALLOCATE(this%state)
    IF (ASSOCIATED(this%algo)) DEALLOCATE(this%algo)
    IF (ASSOCIATED(this%ctx)) DEALLOCATE(this%ctx)

    ! 分配新数组
    ALLOCATE(RT_Material_UMAT_Desc :: this%desc(n_libs))
    ALLOCATE(this%state(n_libs))
    ALLOCATE(this%algo(n_libs))
    ALLOCATE(this%ctx(n_libs))

    this%n_libs = n_libs
    this%initialized = .TRUE.

    status%status_code = IF_STATUS_OK
    status%message = "RT_Material_Domain 初始化成功"
  END SUBROUTINE RT_Material_Domain_Init

  ! ===============================================================================
  ! 实现: Domain 清理
  ! ===============================================================================
  SUBROUTINE RT_Material_Domain_Finalize(this, status)
    CLASS(RT_Material_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "RT_Material_Domain 未初始化"
      RETURN
    END IF

    ! 释放每个材料库的动态分配内存
    DO i = 1_i4, this%n_libs
      IF (ALLOCATED(this%state(i)%mat_ids)) DEALLOCATE(this%state(i)%mat_ids)
      IF (ALLOCATED(this%state(i)%families)) DEALLOCATE(this%state(i)%families)
      IF (ALLOCATED(this%state(i)%props)) DEALLOCATE(this%state(i)%props)
      IF (ALLOCATED(this%state(i)%statev)) DEALLOCATE(this%state(i)%statev)
      IF (ALLOCATED(this%state(i)%statev_offset)) DEALLOCATE(this%state(i)%statev_offset)
      IF (ALLOCATED(this%state(i)%statev_length)) DEALLOCATE(this%state(i)%statev_length)
      IF (ALLOCATED(this%state(i)%cache_valid)) DEALLOCATE(this%state(i)%cache_valid)
      IF (ALLOCATED(this%state(i)%cache_step_id)) DEALLOCATE(this%state(i)%cache_step_id)
      IF (ALLOCATED(this%state(i)%cache_age)) DEALLOCATE(this%state(i)%cache_age)
    END DO

    ! 释放容器本身
    IF (ASSOCIATED(this%desc)) DEALLOCATE(this%desc)
    IF (ASSOCIATED(this%state)) DEALLOCATE(this%state)
    IF (ASSOCIATED(this%algo)) DEALLOCATE(this%algo)
    IF (ASSOCIATED(this%ctx)) DEALLOCATE(this%ctx)

    this%n_libs = 0_i4
    this%initialized = .FALSE.

    status%status_code = IF_STATUS_OK
    status%message = "RT_Material_Domain 清理完成"
  END SUBROUTINE RT_Material_Domain_Finalize

  ! ===============================================================================
  ! 实现: Domain WriteBack — 将材料库信息写回
  ! ===============================================================================
  SUBROUTINE RT_Material_WriteBack(this, status)
    CLASS(RT_Material_Domain), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "RT_Material_Domain 未初始化"
      RETURN
    END IF

    ! 演示: 将每个材料库的统计信息写到日志
    DO i = 1_i4, this%n_libs
      IF (LEN_TRIM(this%ctx(i)%log_file) > 0_i4) THEN
        PRINT *, "WriteBack: 材料库 #", i, " (&
                  & num_materials=", this%desc(i)%num_materials, &
                  & ", umat_calls=", this%state(i)%umat_call_count, ")"
      END IF
    END DO

    status%status_code = IF_STATUS_OK
    status%message = "RT_Material_Domain WriteBack 完成"
  END SUBROUTINE RT_Material_WriteBack

END MODULE RT_Material_Domain_Template
