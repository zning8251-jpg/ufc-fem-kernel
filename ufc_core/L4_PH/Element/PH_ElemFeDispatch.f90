!===============================================================================
! MODULE: PH_ElemFeDispatch
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Dispatch
! BRIEF:  �?PH_ElemDomain_Ops 拆分的载荷向量计算路�?
!===============================================================================
MODULE PH_ElemFeDispatch
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Elem_Def, ONLY: PH_Elem_Desc
  USE PH_Elem_LoadKernel, ONLY: Elem_Load_In, Elem_Load_Out, &
                               Compute_BodyForce, Compute_SurfPressure, Compute_EdgePressure

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Compute_Fe

CONTAINS

  !----------------------------------------------------------------------------
  ! Compute_Fe - 载荷向量计算路由
  ! 输入: elem_type, coords, u, load_case, load_magn
  ! 输出: Fe (单元内力等效向量，供 L5 R=F_ext-F_int), status
  ! load_magn: 仅单元弱式专用幅值；勿与 RT_Asm_GlobalLoad 已写入 F_ext 的项重复。
  !----------------------------------------------------------------------------
  SUBROUTINE Compute_Fe(elem_type, coords, u, load_case, load_magn, Fe, status)
    INTEGER(i4), INTENT(IN)  :: elem_type      ! 单元类型ID
    REAL(wp),   INTENT(IN)  :: coords(:,:)   ! [ndim, n_nodes] 坐标
    REAL(wp),   INTENT(IN)  :: u(:)         ! [n_dof] 位移
    INTEGER(i4), INTENT(IN)  :: load_case    ! 载荷工况编号
    REAL(wp),   INTENT(IN)  :: load_magn(:) ! 载荷幅值数�?
    REAL(wp),   INTENT(OUT) :: Fe(:)        ! [n_dof] 残差向量
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof
    TYPE(PH_Elem_Desc) :: desc
    TYPE(Elem_Load_In) :: load_in
    TYPE(Elem_Load_Out) :: load_out

    n_dof = SIZE(Fe, 1)

    ! 初始�?
    Fe = 0.0_wp

    ! 构建 Desc 用于 Load_Kernel
    desc%cfg%elem_type_id = elem_type
    desc%pop%n_dof = n_dof
    desc%pop%n_nodes = SIZE(coords, 2)
    desc%cfg%ndim = SIZE(coords, 1)

    ! 构建 Load 输入
    ALLOCATE(load_in%coords(ndim, n_nodes))
    load_in%coords = coords
    load_in%load_kind = load_case
    IF (SIZE(load_magn) > 0) load_in%magn = load_magn(1)

    ! 调用通用 Load_Kernel（体力）
    load_in%face_id = 0  ! 体力标志
    ALLOCATE(load_in%coords(SIZE(coords,1), SIZE(coords,2)))
    load_in%coords = coords

    CALL Compute_BodyForce(desc, load_in, load_out, status)

    IF (ALLOCATED(load_out%Fe)) Fe = load_out%Fe

  END SUBROUTINE Compute_Fe

  !----------------------------------------------------------------------------
  ! Compute_Fe_Distributed - 分布载荷
  !----------------------------------------------------------------------------
  SUBROUTINE Compute_Fe_Distributed(elem_type, coords, face_id, pressure, Fe, status)
    INTEGER(i4), INTENT(IN)  :: elem_type
    REAL(wp),   INTENT(IN)  :: coords(:,:)
    INTEGER(i4), INTENT(IN)  :: face_id
    REAL(wp),   INTENT(IN)  :: pressure
    REAL(wp),   INTENT(OUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(PH_Elem_Desc) :: desc
    TYPE(Elem_Load_In) :: load_in
    TYPE(Elem_Load_Out) :: load_out

    ! 根据维度判断用面压力还是边压�?
    IF (SIZE(coords,1) == 3) THEN
      ! 3D：面压力
      ALLOCATE(load_in%coords(SIZE(coords,1), SIZE(coords,2)))
      load_in%coords = coords
      load_in%face_id = face_id
      load_in%magn = pressure

      CALL Compute_SurfPressure(desc, load_in, load_out, status)
    ELSE
      ! 2D：边压力
      ALLOCATE(load_in%coords(SIZE(coords,1), SIZE(coords,2)))
      load_in%coords = coords
      load_in%edge_id = face_id
      load_in%magn = pressure

      CALL Compute_EdgePressure(desc, load_in, load_out, status)
    END IF

    IF (ALLOCATED(load_out%Fe)) Fe = load_out%Fe

  END SUBROUTINE Compute_Fe_Distributed

END MODULE PH_ElemFeDispatch