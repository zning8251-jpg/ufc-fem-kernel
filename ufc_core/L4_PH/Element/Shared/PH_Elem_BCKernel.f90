!===============================================================================
! MODULE: PH_Elem_BCKernel
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  跨族通用约束/MPC内核
!===============================================================================
MODULE PH_Elem_BCKernel
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Elem_Aux_Def, ONLY: PH_Elem_Lcl_Evo_Ctx
  USE PH_Elem_Def, ONLY: PH_Elem_Desc
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! 输入/输出结构体（SIO 规范�?
  !---------------------------------------------------------------------------

  TYPE, PUBLIC :: Elem_BC_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
    TYPE(PH_Elem_Lcl_Evo_Ctx) :: evo                  ! penalty / MPC stiffness workspace
    REAL(wp), ALLOCATABLE :: Fe(:)                    ! [OUT] assembled force
    INTEGER(i4), ALLOCATABLE :: bc_dof(:)             ! [IN] constrained local DOF indices
    INTEGER(i4) :: bc_method = 0_i4                   ! [IN] 0=penalty (default)
    REAL(wp), ALLOCATABLE :: bc_val(:)                ! [IN] prescribed values
  END TYPE Elem_BC_Arg


  PUBLIC :: Apply_Constraint
  PUBLIC :: Apply_MPC

CONTAINS

  !----------------------------------------------------------------------------
  ! Apply_Constraint - 通用刚性约�?
  !----------------------------------------------------------------------------
  SUBROUTINE Apply_Constraint(desc, in, out, status)
    TYPE(PH_Elem_Desc), INTENT(IN)    :: desc
    TYPE(Elem_BC_Arg), INTENT(IN)    :: in
    TYPE(Elem_BC_Arg), INTENT(INOUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_bc, n_dof, i
    REAL(wp) :: penalty = 1.0e12_wp  ! 罚因子默认�?

    n_dof = desc%pop%n_dof

    ! 初始化输�?
    IF (.NOT. ASSOCIATED(out%evo%Ke)) ALLOCATE(out%evo%Ke(n_dof, n_dof))
    IF (.NOT. ALLOCATED(out%Fe)) ALLOCATE(out%Fe(n_dof))
    out%evo%Ke = 0.0_wp
    out%Fe = 0.0_wp

    IF (ALLOCATED(in%bc_dof)) THEN
      n_bc = SIZE(in%bc_dof, 1)

      DO i = 1, n_bc
        IF (in%bc_dof(i) > 0 .AND. in%bc_dof(i) <= n_dof) THEN
          IF (in%bc_method == 0) THEN
            ! 罚函数法
            out%evo%Ke(in%bc_dof(i), in%bc_dof(i)) = &
              out%evo%Ke(in%bc_dof(i), in%bc_dof(i)) + penalty
            IF (ALLOCATED(in%bc_val)) THEN
              out%Fe(in%bc_dof(i)) = out%Fe(in%bc_dof(i)) + penalty * in%bc_val(i)
            END IF
          END IF
          ! Lagrange 乘子法待扩展
        END IF
      END DO
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Apply_Constraint

  !----------------------------------------------------------------------------
  ! Apply_MPC - 通用多点约束
  !----------------------------------------------------------------------------
  SUBROUTINE Apply_MPC(desc, in, out, status)
    TYPE(PH_Elem_Desc), INTENT(IN)    :: desc
    TYPE(Elem_BC_Arg), INTENT(IN)    :: in
    TYPE(Elem_BC_Arg), INTENT(INOUT) :: out
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dof

    n_dof = desc%pop%n_dof

    IF (.NOT. ASSOCIATED(out%evo%Ke)) ALLOCATE(out%evo%Ke(n_dof, n_dof))
    IF (.NOT. ALLOCATED(out%Fe)) ALLOCATE(out%Fe(n_dof))
    out%evo%Ke = 0.0_wp
    out%Fe = 0.0_wp

    ! 占位骨架：MPC 扩展
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE Apply_MPC

END MODULE PH_Elem_BCKernel