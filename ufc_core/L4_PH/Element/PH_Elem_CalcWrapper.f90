!===============================================================================
! MODULE: PH_Elem_CalcWrapper
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  单元矩阵计算统一封装 (Ke/Fe/Me/Ce)
!===============================================================================
MODULE PH_Elem_CalcWrapper
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_State, PH_Elem_Algo, PH_Elem_Ctx

  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! TYPE: PH_Elem_Calc_Args
  ! 计算参数容器
  !============================================================================
  TYPE, PUBLIC :: PH_Elem_Calc_Args
    !-- Input: 几何与材料
    REAL(wp), ALLOCATABLE :: coords_ref(:,:)  ! [IN] 参考坐标 (nDim, nNode)
    REAL(wp), ALLOCATABLE :: disp(:,:)        ! [IN] 位移 (nDim, nNode)
    REAL(wp), ALLOCATABLE :: props(:)         ! [IN] 材料参数
    
    !-- Input: 计算控制
    INTEGER(i4) :: calc_mode = 1_i4           ! [IN] 1=线性, 2=非线性TL, 3=非线性UL
    LOGICAL :: compute_stiffness = .TRUE.     ! [IN] 计算Ke
    LOGICAL :: compute_force = .TRUE.         ! [IN] 计算Fe
    LOGICAL :: compute_mass = .FALSE.         ! [IN] 计算Me
    LOGICAL :: compute_damping = .FALSE.      ! [IN] 计算Ce
    LOGICAL :: nlgeom = .FALSE.               ! [IN] 几何非线性开关
    
    !-- Input: 时间参数
    REAL(wp) :: time = 0.0_wp                 ! [IN] 当前时间
    REAL(wp) :: dTime = 1.0_wp                ! [IN] 时间步长
    
    !-- Output: 矩阵结果
    REAL(wp), ALLOCATABLE :: Ke(:,:)          ! [OUT] 刚度矩阵
    REAL(wp), ALLOCATABLE :: Fe(:)            ! [OUT] 残力向量
    REAL(wp), ALLOCATABLE :: Me(:,:)          ! [OUT] 质量矩阵
    REAL(wp), ALLOCATABLE :: Ce(:,:)          ! [OUT] 阻尼矩阵
    
    !-- Output: 状态变量
    REAL(wp), ALLOCATABLE :: svars(:,:)       ! [OUT] 状态变量 (nIP, nSvar)
    REAL(wp) :: energy_internal = 0.0_wp      ! [OUT] 内能
    REAL(wp) :: energy_kinetic = 0.0_wp       ! [OUT] 动能
    REAL(wp) :: stable_dt = 0.0_wp            ! [OUT] 稳定时间步
  END TYPE PH_Elem_Calc_Args

  !============================================================================
  ! Public Interface: 计算封装入口
  !============================================================================
  PUBLIC :: PH_Elem_Calc_Ke
  PUBLIC :: PH_Elem_Calc_Fe
  PUBLIC :: PH_Elem_Calc_Me
  PUBLIC :: PH_Elem_Calc_Ce
  PUBLIC :: PH_Elem_Calc_All
  PUBLIC :: PH_Elem_Calc_Validate

CONTAINS

  !============================================================================
  ! Subroutine: PH_Elem_Calc_Ke
  ! Purpose: 计算单元刚度矩阵
  !============================================================================
  SUBROUTINE PH_Elem_Calc_Ke(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nDOF

    ! Validate inputs
    IF (.NOT. ALLOCATED(args%coords_ref)) THEN
      CALL init_error_status(status, STATUS_ERR, &
           message='PH_Elem_Calc_Ke: coords_ref not allocated')
      RETURN
    END IF

    nDOF = desc%nDOF

    ! Allocate output
    IF (.NOT. ALLOCATED(args%Ke)) THEN
      ALLOCATE(args%Ke(nDOF, nDOF))
    END IF
    args%Ke = 0.0_wp

    ! Dispatch to family-specific computation
    SELECT CASE (desc%cfg%family_id)
    CASE (1:18)  ! Solid3D family
      CALL Calc_Ke_Solid3D(desc, state, algo, ctx, args, status)
    CASE (19:42) ! Shell family
      CALL Calc_Ke_Shell(desc, state, algo, ctx, args, status)
    CASE (43:54) ! Beam family
      CALL Calc_Ke_Beam(desc, state, algo, ctx, args, status)
    CASE DEFAULT
      CALL init_error_status(status, STATUS_ERR, &
           message='PH_Elem_Calc_Ke: unsupported family_id')
    END SELECT

    ! Update state
    IF (status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(state%stiffness)) THEN
        state%stiffness(1:nDOF, 1:nDOF) = args%Ke
      END IF
    END IF

  END SUBROUTINE PH_Elem_Calc_Ke

  !============================================================================
  ! Subroutine: PH_Elem_Calc_Fe
  ! Purpose: 计算单元残力向量
  !============================================================================
  SUBROUTINE PH_Elem_Calc_Fe(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nDOF

    nDOF = desc%nDOF

    ! Allocate output
    IF (.NOT. ALLOCATED(args%Fe)) THEN
      ALLOCATE(args%Fe(nDOF))
    END IF
    args%Fe = 0.0_wp

    ! Dispatch to family-specific computation
    SELECT CASE (desc%cfg%family_id)
    CASE (1:18)  ! Solid3D family
      CALL Calc_Fe_Solid3D(desc, state, algo, ctx, args, status)
    CASE (19:42) ! Shell family
      CALL Calc_Fe_Shell(desc, state, algo, ctx, args, status)
    CASE (43:54) ! Beam family
      CALL Calc_Fe_Beam(desc, state, algo, ctx, args, status)
    CASE DEFAULT
      CALL init_error_status(status, STATUS_ERR, &
           message='PH_Elem_Calc_Fe: unsupported family_id')
    END SELECT

    ! Update state
    IF (status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(state%residual)) THEN
        state%residual(1:nDOF) = args%Fe
      END IF
    END IF

  END SUBROUTINE PH_Elem_Calc_Fe

  !============================================================================
  ! Subroutine: PH_Elem_Calc_Me
  ! Purpose: 计算单元质量矩阵
  !============================================================================
  SUBROUTINE PH_Elem_Calc_Me(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nDOF

    nDOF = desc%nDOF

    ! Allocate output
    IF (.NOT. ALLOCATED(args%Me)) THEN
      ALLOCATE(args%Me(nDOF, nDOF))
    END IF
    args%Me = 0.0_wp

    ! Dispatch to family-specific computation
    SELECT CASE (desc%cfg%family_id)
    CASE (1:18)  ! Solid3D family
      CALL Calc_Me_Solid3D(desc, state, algo, ctx, args, status)
    CASE (19:42) ! Shell family
      CALL Calc_Me_Shell(desc, state, algo, ctx, args, status)
    CASE (43:54) ! Beam family
      CALL Calc_Me_Beam(desc, state, algo, ctx, args, status)
    CASE DEFAULT
      CALL init_error_status(status, STATUS_ERR, &
           message='PH_Elem_Calc_Me: unsupported family_id')
    END SELECT

    ! Update state
    IF (status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(state%mass)) THEN
        state%mass(1:nDOF, 1:nDOF) = args%Me
      END IF
    END IF

  END SUBROUTINE PH_Elem_Calc_Me

  !============================================================================
  ! Subroutine: PH_Elem_Calc_Ce
  ! Purpose: 计算单元阻尼矩阵 (Rayleigh: C = αM + βK)
  !============================================================================
  SUBROUTINE PH_Elem_Calc_Ce(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nDOF

    nDOF = desc%nDOF

    ! Allocate output
    IF (.NOT. ALLOCATED(args%Ce)) THEN
      ALLOCATE(args%Ce(nDOF, nDOF))
    END IF
    args%Ce = 0.0_wp

    ! Rayleigh damping: C = alpha_M * M + beta_K * K
    IF (ALLOCATED(state%mass) .AND. ALLOCATED(state%stiffness)) THEN
      args%Ce = algo%damping_coeff_alpha * state%mass + &
                algo%damping_coeff_beta * state%stiffness
    END IF

    ! Update state
    IF (status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(state%damping)) THEN
        state%damping(1:nDOF, 1:nDOF) = args%Ce
      END IF
    END IF

  END SUBROUTINE PH_Elem_Calc_Ce

  !============================================================================
  ! Subroutine: PH_Elem_Calc_All
  ! Purpose: 计算全矩阵 (Ke+Fe+Me+Ce)
  !============================================================================
  SUBROUTINE PH_Elem_Calc_All(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: local_status

    ! Initialize
    CALL init_error_status(status, IF_STATUS_OK)

    ! Compute stiffness (if requested)
    IF (args%compute_stiffness) THEN
      CALL PH_Elem_Calc_Ke(desc, state, algo, ctx, args, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
      END IF
    END IF

    ! Compute force (if requested)
    IF (args%compute_force) THEN
      CALL PH_Elem_Calc_Fe(desc, state, algo, ctx, args, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
      END IF
    END IF

    ! Compute mass (if requested)
    IF (args%compute_mass) THEN
      CALL PH_Elem_Calc_Me(desc, state, algo, ctx, args, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
      END IF
    END IF

    ! Compute damping (if requested)
    IF (args%compute_damping) THEN
      CALL PH_Elem_Calc_Ce(desc, state, algo, ctx, args, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
      END IF
    END IF

  END SUBROUTINE PH_Elem_Calc_All

  !============================================================================
  ! Function: PH_Elem_Calc_Validate
  ! Purpose: 验证计算参数
  !============================================================================
  FUNCTION PH_Elem_Calc_Validate(args, desc) RESULT(is_valid)
    TYPE(PH_Elem_Calc_Args), INTENT(IN) :: args
    TYPE(PH_Elem_Desc), INTENT(IN), OPTIONAL :: desc
    LOGICAL :: is_valid

    is_valid = .TRUE.

    ! Check coordinates
    IF (.NOT. ALLOCATED(args%coords_ref)) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    ! Check time step
    IF (args%dTime <= 0.0_wp) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    ! Check desc if provided
    IF (PRESENT(desc)) THEN
      IF (desc%nDOF <= 0) THEN
        is_valid = .FALSE.
        RETURN
      END IF
    END IF

  END FUNCTION PH_Elem_Calc_Validate

  !============================================================================
  ! 以下为族专用计算子程序（占位，实际调用PH_Elem_SLD3D_Core等）
  !============================================================================

  SUBROUTINE Calc_Ke_Solid3D(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    USE PH_ElemKeDispatch, ONLY: Compute_Ke
    REAL(wp), ALLOCATABLE :: mat_props_loc(:)
    REAL(wp), ALLOCATABLE :: algo_params_loc(:)

    CALL init_error_status(status)

    ! Pack material props from args
    IF (ALLOCATED(args%props)) THEN
      mat_props_loc = args%props
    ELSE
      ALLOCATE(mat_props_loc(2))
      mat_props_loc = 0.0_wp
    END IF

    ALLOCATE(algo_params_loc(1))
    algo_params_loc(1) = REAL(args%calc_mode, wp)

    ! Delegate to PH_ElemKeDispatch via procedure-pointer if algo has integrator
    CALL Compute_Ke(desc%cfg%elem_type_id, args%coords_ref, mat_props_loc, &
                    algo_params_loc, args%Ke, status, &
                    desc=desc, elem_state=state, algo=algo)

    IF (ALLOCATED(mat_props_loc))  DEALLOCATE(mat_props_loc)
    IF (ALLOCATED(algo_params_loc)) DEALLOCATE(algo_params_loc)
  END SUBROUTINE

  SUBROUTINE Calc_Fe_Solid3D(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nDOF, i

    CALL init_error_status(status)
    nDOF = desc%nDOF

    ! Internal force: Fe = Ke * u (linear approximation)
    ! For nonlinear: Fe = int(B^T * sigma dV) computed at Gauss points
    IF (ALLOCATED(args%Ke) .AND. ALLOCATED(args%disp)) THEN
      ! Linear path: Fe = Ke * u_vec
      BLOCK
        REAL(wp), ALLOCATABLE :: u_vec(:)
        ALLOCATE(u_vec(nDOF))
        u_vec = RESHAPE(args%disp, [nDOF])
        args%Fe(1:nDOF) = MATMUL(args%Ke(1:nDOF, 1:nDOF), u_vec)
        DEALLOCATE(u_vec)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE Calc_Me_Solid3D(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: rho
    INTEGER(i4) :: nDOF, i

    CALL init_error_status(status)
    nDOF = desc%nDOF

    ! Lumped mass approximation: Me = rho * V / nDOF * I
    ! Where rho is density from material props
    IF (ALLOCATED(args%props) .AND. SIZE(args%props) >= 3) THEN
      rho = args%props(3)  ! density typically at index 3
    ELSE
      rho = 1.0_wp  ! default
    END IF

    ! Diagonal lumped mass: Me(i,i) = total_mass / n_nodes (per DOF)
    ! Placeholder: uniform diagonal
    DO i = 1, nDOF
      args%Me(i, i) = rho  ! Will be refined with actual volume integration
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE Calc_Ke_Shell(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    USE PH_ElemKeDispatch, ONLY: Compute_Ke
    REAL(wp), ALLOCATABLE :: mat_props_loc(:), algo_params_loc(:)

    CALL init_error_status(status)

    IF (ALLOCATED(args%props)) THEN
      mat_props_loc = args%props
    ELSE
      ALLOCATE(mat_props_loc(2))
      mat_props_loc = 0.0_wp
    END IF
    ALLOCATE(algo_params_loc(1))
    algo_params_loc(1) = REAL(args%calc_mode, wp)

    CALL Compute_Ke(desc%cfg%elem_type_id, args%coords_ref, mat_props_loc, &
                    algo_params_loc, args%Ke, status, &
                    desc=desc, elem_state=state, algo=algo)

    IF (ALLOCATED(mat_props_loc))  DEALLOCATE(mat_props_loc)
    IF (ALLOCATED(algo_params_loc)) DEALLOCATE(algo_params_loc)
  END SUBROUTINE

  SUBROUTINE Calc_Fe_Shell(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nDOF

    CALL init_error_status(status)
    nDOF = desc%nDOF

    ! Shell internal force: Fe = Ke * u (linear) or int(B^T * N dA)
    IF (ALLOCATED(args%Ke) .AND. ALLOCATED(args%disp)) THEN
      BLOCK
        REAL(wp), ALLOCATABLE :: u_vec(:)
        ALLOCATE(u_vec(nDOF))
        u_vec = RESHAPE(args%disp, [nDOF])
        args%Fe(1:nDOF) = MATMUL(args%Ke(1:nDOF, 1:nDOF), u_vec)
        DEALLOCATE(u_vec)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE Calc_Me_Shell(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: rho, thick
    INTEGER(i4) :: nDOF, i

    CALL init_error_status(status)
    nDOF = desc%nDOF

    ! Shell mass: M = rho * h * A * diag(1/n)
    IF (ALLOCATED(args%props) .AND. SIZE(args%props) >= 4) THEN
      rho   = args%props(3)  ! density
      thick = args%props(4)  ! thickness
    ELSE
      rho   = 1.0_wp
      thick = 1.0_wp
    END IF

    DO i = 1, nDOF
      args%Me(i, i) = rho * thick
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE Calc_Ke_Beam(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    USE PH_ElemKeDispatch, ONLY: Compute_Ke
    REAL(wp), ALLOCATABLE :: mat_props_loc(:), algo_params_loc(:)

    CALL init_error_status(status)

    IF (ALLOCATED(args%props)) THEN
      mat_props_loc = args%props
    ELSE
      ALLOCATE(mat_props_loc(2))
      mat_props_loc = 0.0_wp
    END IF
    ALLOCATE(algo_params_loc(1))
    algo_params_loc(1) = REAL(args%calc_mode, wp)

    CALL Compute_Ke(desc%cfg%elem_type_id, args%coords_ref, mat_props_loc, &
                    algo_params_loc, args%Ke, status, &
                    desc=desc, elem_state=state, algo=algo)

    IF (ALLOCATED(mat_props_loc))  DEALLOCATE(mat_props_loc)
    IF (ALLOCATED(algo_params_loc)) DEALLOCATE(algo_params_loc)
  END SUBROUTINE

  SUBROUTINE Calc_Fe_Beam(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nDOF

    CALL init_error_status(status)
    nDOF = desc%nDOF

    ! Beam internal force: Fe = Ke * u
    IF (ALLOCATED(args%Ke) .AND. ALLOCATED(args%disp)) THEN
      BLOCK
        REAL(wp), ALLOCATABLE :: u_vec(:)
        ALLOCATE(u_vec(nDOF))
        u_vec = RESHAPE(args%disp, [nDOF])
        args%Fe(1:nDOF) = MATMUL(args%Ke(1:nDOF, 1:nDOF), u_vec)
        DEALLOCATE(u_vec)
      END BLOCK
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE Calc_Me_Beam(desc, state, algo, ctx, args, status)
    TYPE(PH_Elem_Desc), INTENT(IN) :: desc
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo), INTENT(IN) :: algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Calc_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: rho, area
    INTEGER(i4) :: nDOF, i

    CALL init_error_status(status)
    nDOF = desc%nDOF

    ! Beam lumped mass: M(i,i) = rho * A * L / n_nodes
    IF (ALLOCATED(args%props) .AND. SIZE(args%props) >= 4) THEN
      rho  = args%props(3)  ! density
      area = args%props(4)  ! cross-section area
    ELSE
      rho  = 1.0_wp
      area = 1.0_wp
    END IF

    ! Translational DOFs only: lumped diagonal
    DO i = 1, nDOF
      args%Me(i, i) = rho * area
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE

END MODULE PH_Elem_CalcWrapper