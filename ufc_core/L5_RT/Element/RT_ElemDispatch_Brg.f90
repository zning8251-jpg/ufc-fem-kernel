!===============================================================================
! MODULE: RT_ElemDispatch_Brg
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Brg — Bridge to L4_PH dispatchers (Ke/Fe/Me/Ce)
! BRIEF:  Routes L5 element compute requests → L4 PH_Elem dispatch functions.
!===============================================================================
MODULE RT_ElemDispatch_Brg
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Elem_Proc, ONLY: Elem_Ke_In, Elem_Ke_Out, &
                          Elem_Fe_In, Elem_Fe_Out, &
                          Elem_Me_In, Elem_Me_Out

  ! L4_PH Dispatcher 接口
  USE PH_ElemKeDispatch, ONLY: Compute_Ke
  USE PH_ElemFeDispatch, ONLY: Compute_Fe
  USE PH_Elem_MassDispatch, ONLY: Compute_Me, Compute_Ce

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Elem_Brg_ComputeKe
  PUBLIC :: RT_Elem_Brg_ComputeFe
  PUBLIC :: RT_Elem_Brg_ComputeMe
  PUBLIC :: RT_Elem_Brg_ComputeCe

CONTAINS

  !============================================================================
  ! RT_Elem_Brg_ComputeKe - 刚度矩阵计算桥接
  ! 目的: �?RT_ElemProc 调用转接�?PH_ElemKeDispatch_Algo
  !============================================================================
  SUBROUTINE RT_Elem_Brg_ComputeKe(elem_type, ke_in, ke_out, status)
    INTEGER(i4),    INTENT(IN)  :: elem_type    ! 单元类型ID
    TYPE(Elem_Ke_In),  INTENT(IN)  :: ke_in       ! 输入
    TYPE(Elem_Ke_Out), INTENT(OUT) :: ke_out      ! 输出
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof
    REAL(wp), ALLOCATABLE :: Ke(:,:)
    REAL(wp), ALLOCATABLE :: algo_params(:)

    n_dof = SIZE(ke_in%u, 1)

    ! 分配输出
    ALLOCATE(ke_out%Ke(n_dof, n_dof))
    ALLOCATE(ke_out%Fe(n_dof))
    ke_out%Ke = 0.0_wp
    ke_out%Fe = 0.0_wp

    ! 算法参数（待完善：从 RT_Elem_Algo 提取�?
    ALLOCATE(algo_params(1))
    algo_params(1) = 0.0_wp  ! 默认积分阶次

    ! 调用 L4_PH Ke Dispatcher
    CALL Compute_Ke( &
      elem_type, &
      ke_in%coords, &
      ke_in%u, &           ! 简化：材料参数待提�?
      algo_params, &
      ke_out%Ke, &
      status &
    )

    ! 若有几何非线性，还需叠加几何刚度（后�?ST-4�?

  END SUBROUTINE RT_Elem_Brg_ComputeKe

  !============================================================================
  ! RT_Elem_Brg_ComputeFe - 载荷向量计算桥接
  ! 目的: �?RT_ElemProc 调用转接�?PH_ElemFeDispatch_Algo
  !============================================================================
  SUBROUTINE RT_Elem_Brg_ComputeFe(elem_type, fe_in, fe_out, status)
    INTEGER(i4),    INTENT(IN)  :: elem_type
    TYPE(Elem_Fe_In),  INTENT(IN)  :: fe_in
    TYPE(Elem_Fe_Out), INTENT(OUT) :: fe_out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof, load_case
    REAL(wp), ALLOCATABLE :: load_magn(:)

    n_dof = SIZE(fe_in%u, 1)

    ! 分配输出
    ALLOCATE(fe_out%Fe(n_dof))
    fe_out%Fe = 0.0_wp

    ! 载荷参数（待完善�?
    load_case = fe_in%load_case
    ALLOCATE(load_magn(1))
    load_magn(1) = 1.0_wp  ! 默认幅�?

    ! 调用 L4_PH Fe Dispatcher
    CALL Compute_Fe( &
      elem_type, &
      fe_in%coords, &
      fe_in%u, &
      load_case, &
      load_magn, &
      fe_out%Fe, &
      status &
    )

  END SUBROUTINE RT_Elem_Brg_ComputeFe

  !============================================================================
  ! RT_Elem_Brg_ComputeMe - 质量矩阵计算桥接
  ! 目的: �?RT_ElemProc 调用转接�?PH_ElemMassDispatch_Algo
  !============================================================================
  SUBROUTINE RT_Elem_Brg_ComputeMe(elem_type, me_in, me_out, status)
    INTEGER(i4),    INTENT(IN)  :: elem_type
    TYPE(Elem_Me_In),  INTENT(IN)  :: me_in
    TYPE(Elem_Me_Out), INTENT(OUT) :: me_out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof
    REAL(wp) :: density, mass_type

    n_dof = SIZE(me_in%coords, 1) * SIZE(me_in%coords, 2)

    ! 分配输出
    ALLOCATE(me_out%Me(n_dof, n_dof))
    me_out%Me = 0.0_wp

    ! 材料参数
    density = me_in%mass_density
    mass_type = 0  ! 默认一致质�?

    ! 调用 L4_PH Mass Dispatcher
    CALL Compute_Me( &
      elem_type, &
      me_in%coords, &
      density, &
      INT(mass_type, i4), &
      me_out%Me, &
      status &
    )

  END SUBROUTINE RT_Elem_Brg_ComputeMe

  !============================================================================
  ! RT_Elem_Brg_ComputeCe - 阻尼矩阵计算桥接
  ! 目的: �?RT_ElemProc 调用转接�?PH_ElemMassDispatch_Algo
  !============================================================================
  SUBROUTINE RT_Elem_Brg_ComputeCe(elem_type, coords, alpha, beta, Ce, status)
    INTEGER(i4),    INTENT(IN)  :: elem_type
    REAL(wp),     INTENT(IN)  :: coords(:,:)
    REAL(wp),     INTENT(IN)  :: alpha, beta
    REAL(wp),     INTENT(OUT) :: Ce(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof

    n_dof = SIZE(coords, 1) * SIZE(coords, 2)

    ! 分配输出
    IF (.NOT. ALLOCATED(Ce)) ALLOCATE(Ce(n_dof, n_dof))
    Ce = 0.0_wp

    ! 调用 L4_PH Mass Dispatcher (Ce 计算)
    CALL Compute_Ce( &
      elem_type, &
      coords, &
      alpha, &
      beta, &
      Ce, &
      status &
    )

  END SUBROUTINE RT_Elem_Brg_ComputeCe

END MODULE RT_ElemDispatch_Brg