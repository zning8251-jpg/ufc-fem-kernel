!===============================================================================
! MODULE: PH_Mat_Elas_Brg
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Brg
! BRIEF:  Cold-path bridge L3 MD_Mat_Elas_Desc → L4 PH_Mat_Elas_Desc (family fields).
!===============================================================================
MODULE PH_Mat_Elas_Brg
  USE IF_Prec_Core,         ONLY: wp, i4
  USE IF_Err_Brg,           ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Elas_Def,      ONLY: PH_Mat_Elas_Desc
  USE MD_Mat_Elas_Def,      ONLY: MD_Mat_Elas_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Elas_Brg_FromL3Desc

CONTAINS

  SUBROUTINE PH_Mat_Elas_Brg_FromL3Desc(l3_desc, l4_desc, status)
    TYPE(MD_Mat_Elas_Desc),  INTENT(IN)  :: l3_desc
    TYPE(PH_Mat_Elas_Desc), INTENT(OUT) :: l4_desc
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    INTEGER(i4) :: i, j, npack, nrow, ncol

    CALL init_error_status(status)

    l4_desc%family_type    = l3_desc%family_type
    l4_desc%sub_type       = l3_desc%sub_type
    l4_desc%property_flags = l3_desc%property_flags
    l4_desc%num_constants  = l3_desc%num_constants
    l4_desc%dependencies   = l3_desc%dependencies

    IF (ALLOCATED(l4_desc%props)) DEALLOCATE (l4_desc%props)
    IF (ALLOCATED(l3_desc%constants)) THEN
      nrow = SIZE(l3_desc%constants, 1)
      ncol = SIZE(l3_desc%constants, 2)
      npack = nrow * ncol
      ALLOCATE (l4_desc%props(npack))
      DO j = 1, ncol
        DO i = 1, nrow
          l4_desc%props(i + (j - 1) * nrow) = l3_desc%constants(i, j)
        END DO
      END DO
    END IF

    l4_desc%E   = l3_desc%E
    l4_desc%nu  = l3_desc%nu
    l4_desc%G   = l3_desc%G
    l4_desc%K   = l3_desc%K
    l4_desc%lambda = l3_desc%lambda
    l4_desc%mu     = l3_desc%mu

    l4_desc%E11 = l3_desc%E11
    l4_desc%E22 = l3_desc%E22
    l4_desc%E33 = l3_desc%E33
    l4_desc%nu12 = l3_desc%nu12
    l4_desc%nu13 = l3_desc%nu13
    l4_desc%nu23 = l3_desc%nu23
    l4_desc%G12 = l3_desc%G12
    l4_desc%G13 = l3_desc%G13
    l4_desc%G23 = l3_desc%G23

    l4_desc%C = l3_desc%C

    l4_desc%is_valid = l3_desc%is_initialized

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Elas_Brg_FromL3Desc

END MODULE PH_Mat_Elas_Brg
