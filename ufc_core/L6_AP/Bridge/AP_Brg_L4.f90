!===============================================================================
! MODULE: AP_Brg_L4
! LAYER:  L6_AP
! DOMAIN: Bridge
! ROLE:   Brg — L6→L4 bridge
! BRIEF:  Bridge for user output to physical results conversion.
!===============================================================================

MODULE AP_Brg_L4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_Def, ONLY: PH_Elem_Ctx
  ! PH_Base_Algo - Physical layer core types
  USE PH_Base_Mgr, ONLY: PH_Field_Desc, PH_PhysCfg_Desc, PH_FieldMgr_Ctx, &
                      PH_ElemAlg_Algo, PH_Constitutive_State, &
                      PH_Constr_Ctx, PH_Contact_State, &
                      PH_Couple_Ctx, PH_PhysCtrl_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Brg_AP_Get_Physical_Results
  PUBLIC :: Brg_AP_Get_Physical_Results_FromCtx
  PUBLIC :: Brg_AP_Format_Output
  PUBLIC :: Brg_AP_Query_Element_Response
  PUBLIC :: Brg_AP_Query_Element_Response_FromCtx

  ! Re-export PH_Base_Algo types for L6_AP use
  PUBLIC :: PH_Field_Desc, PH_PhysCfg_Desc, PH_FieldMgr_Ctx, &
            PH_ElemAlg_Algo, PH_Constitutive_State, &
            PH_Constr_Ctx, PH_Contact_State, &
            PH_Couple_Ctx, PH_PhysCtrl_Ctx

CONTAINS

  SUBROUTINE Brg_AP_Get_Physical_Results_FromCtx(elem_ctx, result_type, values, status)
    TYPE(PH_Elem_Ctx), INTENT(IN) :: elem_ctx
    CHARACTER(LEN=*), INTENT(IN) :: result_type
    REAL(wp), INTENT(OUT), ALLOCATABLE, OPTIONAL :: values(:)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: n, i

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. elem_ctx%is_initialized) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (PRESENT(values)) THEN
      IF (ALLOCATED(values)) DEALLOCATE(values)

      IF (result_type == "stiffness" .OR. result_type == "Ke") THEN
        ! stiffness matrix
        IF (ASSOCIATED(elem_ctx%evo%Ke)) THEN
          n = SIZE(elem_ctx%evo%Ke, 1) * SIZE(elem_ctx%evo%Ke, 2)
          ALLOCATE(values(n))
          n = 0
          DO i = 1, SIZE(elem_ctx%evo%Ke, 2)
            values(n+1:n+SIZE(elem_ctx%evo%Ke, 1)) = elem_ctx%evo%Ke(:, i)
            n = n + SIZE(elem_ctx%evo%Ke, 1)
          END DO
        ELSE
          ALLOCATE(values(0))
        END IF

      ELSE IF (result_type == "residual" .OR. result_type == "Re" .OR. result_type == "force") THEN
        !  forcevector
        IF (ALLOCATED(elem_ctx%Re)) THEN
          n = SIZE(elem_ctx%Re)
          ALLOCATE(values(n))
          values = elem_ctx%Re
        ELSE
          ALLOCATE(values(0))
        END IF

      ELSE
        !  
        ALLOCATE(values(0))
        IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Brg_AP_Get_Physical_Results_FromCtx

  SUBROUTINE Brg_AP_Get_Physical_Results(elem_id, result_type, values, ierr)
    INTEGER(i4), INTENT(IN) :: elem_id
    CHARACTER(LEN=*), INTENT(IN) :: result_type
    REAL(wp), INTENT(OUT), ALLOCATABLE, OPTIONAL :: values(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    IF (PRESENT(ierr)) ierr = 0
    ! Base version: call Brg_AP_Get_Physical_Results_FromCtx when elem_ctx needed
  END SUBROUTINE Brg_AP_Get_Physical_Results
END MODULE AP_Brg_L4