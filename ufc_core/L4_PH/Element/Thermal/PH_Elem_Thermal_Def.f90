!===============================================================================
! MODULE: PH_Elem_ThermDefinition
! LAYER:  L4_PH
! DOMAIN: Element/Thermal
! ROLE:   Def
! BRIEF:  Thermal element definition and calculation
! **W2**：热单元 **Defn**；温度形函数 / 传导矩阵路径与 **`PH_Elem_Therm*`**、**`PH_Elem_Core`**（热步）合同对齐。
!===============================================================================
MODULE PH_Elem_Thermal_Def
  USE IF_Prec_Core,   ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Elem_Def, ONLY: PH_Elem_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: UF_Elem_Therm_Calc
  PUBLIC :: PH_Elem_Therm_Args

  !=============================================================================
  ! TYPE: PH_Elem_Therm_Args
  ! Purpose: INTF-style argument bundle for thermal element calculation
  ! Status: INTF-001 Progressive Refactoring
  !=============================================================================
  TYPE :: PH_Elem_Therm_Args
    !-- Input: Element topology
    INTEGER(i4)           :: elem_type = 0_i4          ! [IN]  Element type code
    TYPE(PH_Elem_Ctx)     :: ctx                       ! [INOUT] Element context

    !-- Input: Material models
    CLASS(*), POINTER     :: mat_models(:) => NULL()   ! [IN]  Material models array

    !-- Output: Thermal matrices (optional)
    REAL(wp), ALLOCATABLE :: Kt(:,:)                   ! [OUT] Conductivity matrix
    REAL(wp), ALLOCATABLE :: Ct(:,:)                   ! [OUT] Heat capacity matrix
    REAL(wp), ALLOCATABLE :: Ft(:)                     ! [OUT] Heat flux vector

  END TYPE PH_Elem_Therm_Args

CONTAINS

  !> @brief Compute thermal element contributions: K_T, C_T, F_T.
  !> K_T = integral(B_T^T * k * B_T dV), conductivity matrix.
  !> C_T = integral(N^T * rho*cp * N dV), heat capacity matrix.
  !> F_T = integral(N^T * Q dV), heat source vector.
  SUBROUTINE UF_Elem_Therm_Calc(args, status)
    TYPE(PH_Elem_Therm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! TODO: Implement thermal element calculation
    ! Allocate and compute Kt, Ct, Ft based on args%elem_type
    ! Example:
    ! IF (.NOT. ALLOCATED(args%Kt)) ALLOCATE(args%Kt(n_nodes, n_nodes))
    ! args%Kt = 0.0_wp
    
  END SUBROUTINE UF_Elem_Therm_Calc

END MODULE PH_Elem_Thermal_Def