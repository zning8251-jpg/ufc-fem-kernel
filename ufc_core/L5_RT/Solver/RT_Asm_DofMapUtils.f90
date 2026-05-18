!===============================================================================
! MODULE: RT_Asm_DofMapUtils
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Util (DofMap)
! BRIEF:  DOF map utility functions for global equation mapping
!===============================================================================
!
! Process族:
!   P1: Map (UF_GetEqId, UF_GetEqIdByDofType, RT_GetEqId)  [HOT_PATH]
!
! Status: STUB | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Asm_DofMapUtils
  USE IF_Prec_Core,      ONLY: wp, i4
  USE RT_Solv_Def, ONLY: RT_Sol_DofMap
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: UF_GetEqId
  PUBLIC :: UF_GetEqIdByDofType
  PUBLIC :: RT_GetEqId

CONTAINS

  !> @brief Get equation ID for (node_id, dof_local) pair from DOF map.
  !> Returns 0 if not found or inactive DOF.
  PURE FUNCTION UF_GetEqId(dofMap, node_id, dof_local) RESULT(eq_id)
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    INTEGER(i4),         INTENT(IN) :: node_id
    INTEGER(i4),         INTENT(IN) :: dof_local
    INTEGER(i4) :: eq_id

    ! Stub: in production, look up dofMap%nodeToEq(node_id, dof_local)
    eq_id = 0_i4
    IF (dof_local < 1 .OR. dof_local > 6) RETURN
    IF (.NOT. ALLOCATED(dofMap%eqToLocal)) RETURN

    ! Real implementation: index into dofMap arrays
    ! eq_id = dofMap%nodeEqStart(node_id) + dof_local - 1
    eq_id = 0_i4  ! stub placeholder

  END FUNCTION UF_GetEqId

  !> @brief Get equation ID by DOF type enum (UF_DOF_U1=1, U2=2, U3=3, ...).
  !> Returns 0 if inactive.
  FUNCTION UF_GetEqIdByDofType(model, dofMap, node_id, dof_type) RESULT(eq_id)
    CLASS(*),            INTENT(IN) :: model
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    INTEGER(i4),         INTENT(IN) :: node_id
    INTEGER(i4),         INTENT(IN) :: dof_type
    INTEGER(i4) :: eq_id

    ! Stub: delegate to UF_GetEqId using dof_type as dof_local
    eq_id = UF_GetEqId(dofMap, node_id, dof_type)

  END FUNCTION UF_GetEqIdByDofType

  !> @brief Alias of UF_GetEqId for use in contact bridge (RT_GetEqId).
  PURE FUNCTION RT_GetEqId(dofMap, node_id, dof_local) RESULT(eq_id)
    TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
    INTEGER(i4),         INTENT(IN) :: node_id
    INTEGER(i4),         INTENT(IN) :: dof_local
    INTEGER(i4) :: eq_id

    eq_id = UF_GetEqId(dofMap, node_id, dof_local)

  END FUNCTION RT_GetEqId

END MODULE RT_Asm_DofMapUtils