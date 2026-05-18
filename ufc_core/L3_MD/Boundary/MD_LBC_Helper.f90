!===============================================================================
! MODULE:  MD_LBC_Helper
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Impl
! BRIEF:   Internal helper functions — face normal/area, nodal force assembly.
!===============================================================================
MODULE MD_LBC_Helper
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: MD_LoadBC_Helper_ComputeFaceNormalArea
    PUBLIC :: MD_LoadBC_Helper_AddNodalVectorForce

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_LoadBC_Helper_ComputeFaceNormalArea
  ! PHASE:      Compute
  ! PURPOSE:    Compute face normal and area from node coordinates
  !---------------------------------------------------------------------------
  SUBROUTINE MD_LoadBC_Helper_ComputeFaceNormalArea(coords, nNode, normal, area)
    REAL(wp), INTENT(IN) :: coords(3, :)
    INTEGER(i4), INTENT(IN) :: nNode
    REAL(wp), INTENT(OUT) :: normal(3)
    REAL(wp), INTENT(OUT) :: area
    REAL(wp) :: v1(3), v2(3)

    IF (nNode < 3) THEN
      normal = 0.0_wp
      area = 0.0_wp
      RETURN
    END IF

    v1 = coords(:, 2) - coords(:, 1)
    v2 = coords(:, 3) - coords(:, 1)

    normal(1) = v1(2) * v2(3) - v1(3) * v2(2)
    normal(2) = v1(3) * v2(1) - v1(1) * v2(3)
    normal(3) = v1(1) * v2(2) - v1(2) * v2(1)

    area = 0.5_wp * SQRT(SUM(normal**2))

    IF (area > 0.0_wp) THEN
      normal = normal / (2.0_wp * area)
    ELSE
      normal = 0.0_wp
    END IF
  END SUBROUTINE MD_LoadBC_Helper_ComputeFaceNormalArea

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_LoadBC_Helper_AddNodalVectorForce
  ! PHASE:      Mutate
  ! PURPOSE:    Add nodal vector force to global force vector
  !---------------------------------------------------------------------------
  SUBROUTINE MD_LoadBC_Helper_AddNodalVectorForce(id, force, F, dofMap)
    INTEGER(i4), INTENT(IN) :: id
    REAL(wp), INTENT(IN) :: force(3)
    REAL(wp), INTENT(INOUT) :: F(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dofMap(:)
    INTEGER(i4) :: globalDof, k, slot

    DO k = 1_i4, 3_i4
      IF (PRESENT(dofMap)) THEN
        slot = (id - 1_i4) * 3_i4 + k
        IF (slot < 1_i4 .OR. slot > SIZE(dofMap)) CYCLE
        globalDof = dofMap(slot)
      ELSE
        globalDof = (id - 1_i4) * 3_i4 + k
      END IF
      IF (globalDof > 0_i4 .AND. globalDof <= SIZE(F)) THEN
        F(globalDof) = F(globalDof) + force(k)
      END IF
    END DO
  END SUBROUTINE MD_LoadBC_Helper_AddNodalVectorForce

END MODULE MD_LBC_Helper
