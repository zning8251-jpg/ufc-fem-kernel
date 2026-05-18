!===============================================================================
! MODULE: AP_Mat_Brg
! LAYER:  L6_AP
! DOMAIN: Bridge
! ROLE:   Brg — Material adapter (L6→L3)
! BRIEF:  Adapter layer for MaterialDesc <-> UF_MaterialDef conversion.
!===============================================================================

MODULE AP_Mat_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  
  ! Import legacy MaterialDesc type
  USE MD_Mat_Lib, ONLY: MD_Mat_Desc
  
  ! Import structured MaterialDef type and interfaces
  USE MD_Mat_Lib, ONLY: UF_MaterialDef, MaterialDef_Init_Structured, &
                         MaterialDef_Init_In, MAX_MATERIAL_PROPS, MAX_MATERIAL_NAME
  
  PUBLIC :: MaterialDesc_Init_Structured_Wrapper, &
            MD_Mat_Desc_To_UF_MaterialDef, &
            UF_MaterialDef_To_MD_Mat_Desc

CONTAINS
  
  !> @brief Convert MD_Mat_Desc to UF_MaterialDef
  !! @details Maps legacy MD_Mat_Desc fields to structured UF_MaterialDef
  !!   Theory: Type conversion preserving material properties σ, E, ν, etc.
  SUBROUTINE MD_Mat_Desc_To_UF_MaterialDef(md_desc, uf_def, status)
    TYPE(MD_Mat_Desc), INTENT(IN) :: md_desc
    TYPE(UF_MaterialDef), INTENT(OUT) :: uf_def
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n_props
    
    CALL init_error_status(status)
    
    ! Copy basic fields
    uf_def%name = md_desc%name(1:MIN(LEN(uf_def%name), LEN(md_desc%name)))
    uf_def%cfg%id = md_desc%cfg%id
    uf_def%material_type = md_desc%cfg%class_id
    uf_def%num_statev = md_desc%pop%nStateV
    
    ! Copy model keyword if available
    IF (LEN_TRIM(md_desc%cfg%materialType) > 0) THEN
        uf_def%model_keyword = md_desc%cfg%materialType(1:MIN(LEN(uf_def%model_keyword), LEN(md_desc%cfg%materialType)))
    END IF
    
    ! Copy properties array
    IF (ALLOCATED(md_desc%props)) THEN
        n_props = SIZE(md_desc%props)
        IF (n_props <= MAX_MATERIAL_PROPS) THEN
            uf_def%num_props = n_props
            uf_def%props(1:n_props) = md_desc%props(1:n_props)
        ELSE
            ! Truncate if too many properties
            uf_def%num_props = MAX_MATERIAL_PROPS
            uf_def%props(1:MAX_MATERIAL_PROPS) = md_desc%props(1:MAX_MATERIAL_PROPS)
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Mat_Desc_To_UF_MaterialDef: Properties truncated (exceeds MAX_MATERIAL_PROPS)"
            RETURN
        END IF
    ELSE
        uf_def%num_props = 0
    END IF
    
    ! Extract common elastic properties from props array if available
    ! Typical order: E, nu, G, K, density, etc.
    IF (uf_def%num_props >= 2) THEN
        uf_def%E = uf_def%props(1)
        uf_def%nu = uf_def%props(2)
        IF (uf_def%num_props >= 3) THEN
            uf_def%G = uf_def%props(3)
        END IF
        IF (uf_def%num_props >= 4) THEN
            uf_def%K = uf_def%props(4)
        END IF
        IF (uf_def%num_props >= 5) THEN
            uf_def%density = uf_def%props(5)
        END IF
    END IF
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Desc_To_UF_MaterialDef
  
  !> @brief Convert UF_MaterialDef to MD_Mat_Desc
  !! @details Maps structured UF_MaterialDef fields to legacy MD_Mat_Desc
  !!   Theory: Type conversion preserving material properties σ, E, ν, etc.
  SUBROUTINE UF_MaterialDef_To_MD_Mat_Desc(uf_def, md_desc, status)
    TYPE(UF_MaterialDef), INTENT(IN) :: uf_def
    TYPE(MD_Mat_Desc), INTENT(OUT) :: md_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n_props
    
    CALL init_error_status(status)
    
    ! Copy basic fields
    md_desc%name = uf_def%name(1:MIN(LEN(md_desc%name), LEN(uf_def%name)))
    md_desc%cfg%id = uf_def%cfg%id
    md_desc%cfg%class_id = uf_def%material_type
    md_desc%pop%nStateV = uf_def%num_statev
    
    ! Copy material type string if available
    IF (LEN_TRIM(uf_def%model_keyword) > 0) THEN
        md_desc%cfg%materialType = uf_def%model_keyword(1:MIN(LEN(md_desc%cfg%materialType), LEN(uf_def%model_keyword)))
    END IF
    
    ! Copy properties array
    IF (uf_def%num_props > 0) THEN
        n_props = uf_def%num_props
        IF (.NOT. ALLOCATED(md_desc%props)) THEN
            ALLOCATE(md_desc%props(n_props))
        ELSE IF (SIZE(md_desc%props) < n_props) THEN
            DEALLOCATE(md_desc%props)
            ALLOCATE(md_desc%props(n_props))
        END IF
        md_desc%pop%nProps = n_props
        md_desc%props(1:n_props) = uf_def%props(1:n_props)
    ELSE
        md_desc%pop%nProps = 0
        IF (ALLOCATED(md_desc%props)) THEN
            DEALLOCATE(md_desc%props)
        END IF
    END IF
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_MaterialDef_To_MD_Mat_Desc
  
  !> @brief Wrapper function for MaterialDesc initialization using structured interface
  !! @details Converts MD_Mat_Desc to UF_MaterialDef, calls structured interface, then converts back
  !!   Theory: Adapter pattern enabling legacy MaterialDesc to use new structured interfaces
  SUBROUTINE MaterialDesc_Init_Structured_Wrapper(in, material_desc, status)
    TYPE(MaterialDef_Init_In), INTENT(IN) :: in
    TYPE(MD_Mat_Desc), INTENT(INOUT) :: material_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(UF_MaterialDef) :: temp_material
    TYPE(ErrorStatusType) :: init_status, conv_status
    
    CALL init_error_status(status)
    
    ! Convert MD_Mat_Desc to UF_MaterialDef
    CALL MD_Mat_Desc_To_UF_MaterialDef(material_desc, temp_material, conv_status)
    IF (conv_status%status_code /= IF_STATUS_OK) THEN
        status = conv_status
        RETURN
    END IF
    
    ! Call structured interface
    CALL MaterialDef_Init_Structured(in, temp_material, init_status)
    IF (init_status%status_code /= IF_STATUS_OK) THEN
        status = init_status
        RETURN
    END IF
    
    ! Convert back to MD_Mat_Desc
    CALL UF_MaterialDef_To_MD_Mat_Desc(temp_material, material_desc, conv_status)
    IF (conv_status%status_code /= IF_STATUS_OK) THEN
        status = conv_status
        RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MaterialDesc_Init_Structured_Wrapper

END MODULE AP_Mat_Brg
