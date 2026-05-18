!===============================================================================
! MODULE: RT_Elem_UEL
! LAYER:  L5_RT
! DOMAIN: Element
! ROLE:   Brg — Thin adapter implementing standard UEL API (7 arguments)
! BRIEF:  Maps RT/MD/PH types to classic UEL 7-arg calling convention.
! **W2**：**UEL API** 薄适配；类型仍以 **`MD_Elem`/`PH_Elem`/`RT_Elem`** 合同为准，勿在本模块发明并行 Desc。
!===============================================================================
MODULE RT_Elem_UEL
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID
  USE MD_Elem_Mgr, ONLY: ElemType
  USE MD_Elem_UEL_Def, ONLY: MD_Elem_UEL_Desc
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Sect_Def, ONLY: MD_Sect_Registry, MD_Sect_Desc
  USE PH_Elem_Def, ONLY: PH_Elem_Ctx, PH_Elem_State
  USE RT_Com_Def, ONLY: RT_Com_Base_Ctx, RT_COM_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Elem_UEL_API
  PUBLIC :: RT_Elem_UEL_Probe
  
CONTAINS
  !=============================================================================
  ! Standard UEL API (7 arguments, v4.1 compliant)
  !=============================================================================
  SUBROUTINE RT_Elem_UEL_API(sect_registry, elem_desc, ph_ctx, ph_state, &
                              com_ctx, pnewdt, status)
    TYPE(MD_Sect_Registry), INTENT(IN), TARGET :: sect_registry
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: elem_desc
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: ph_ctx
    TYPE(PH_Elem_State), INTENT(INOUT) :: ph_state
    TYPE(RT_Com_Base_Ctx), INTENT(IN) :: com_ctx
    REAL(wp), INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: sect_id, sect_idx
    CLASS(MD_Mat_Desc), POINTER :: mat_desc => NULL()
    
    ! --- Contract Validation (thin validation, no computation) ---
    CALL init_error_status(status)
    
    ! 1. Validate integration points count > 0
    IF (elem_desc%integ_npts <= 0_i4) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[RT_Elem_UEL_API]: elem_desc%integ_npts must be > 0')
      pnewdt = 0.0_wp
      RETURN
    END IF
    
    ! 2. Validate jprops(1) exists for section_id
    IF (.NOT. ALLOCATED(elem_desc%jprops) .OR. &
        SIZE(elem_desc%jprops) < 1) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[RT_Elem_UEL_API]: jprops(1) required for section_id')
      pnewdt = 0.0_wp
      RETURN
    END IF
    
    ! 3. Lookup section in registry
    sect_id = elem_desc%jprops(1)
    sect_idx = sect_registry%GetSectIdx(sect_id)
    IF (sect_idx == 0_i4) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[RT_Elem_UEL_API]: section_id not found in registry')
      pnewdt = 0.0_wp
      RETURN
    END IF
    
    ! 4. Get material descriptor pointer
    mat_desc => sect_registry%sections(sect_idx)%mat_desc
    IF (.NOT. ASSOCIATED(mat_desc)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[RT_Elem_UEL_API]: section mat_desc not associated')
      pnewdt = 0.0_wp
      RETURN
    END IF
    
    ! --- Route to L4_PH UMAT kernel (SELECT TYPE dispatch) ---
    SELECT TYPE (mat_desc)
    TYPE IS (MD_Mat_Elastic_Desc)
      ! Elastic material - route to PH_Elastic_UMAT_API
      CALL PH_Elastic_UMAT_API(mat_desc, ph_ctx, ph_state, status)
      
    TYPE IS (MD_Mat_Plastic_Desc)
      ! Plastic material - route to PH_Plastic_UMAT_API
      CALL PH_Plastic_UMAT_API(mat_desc, ph_ctx, ph_state, status)
      
    TYPE IS (MD_Mat_Hyperelastic_Desc)
      ! Hyperelastic material - route to PH_Hyperelastic_UMAT_API
      CALL PH_Hyperelastic_UMAT_API(mat_desc, ph_ctx, ph_state, status)
      
    CLASS DEFAULT
      ! Unsupported material type
      CALL init_error_status(status, IF_STATUS_ERROR, &
           message='[RT_Elem_UEL_API]: Unsupported material type - install specific UMAT kernel')
      pnewdt = 0.0_wp
      RETURN
    END SELECT
    
    ! Note: This is a THIN adapter - actual computation in L4_PH UMAT kernels
    ! The UEL API only validates contract and routes to appropriate material kernel
    
  END SUBROUTINE RT_Elem_UEL_API
  
  !=============================================================================
  ! Cold-path probe utility for testing UEL contract
  !=============================================================================
  SUBROUTINE RT_Elem_UEL_Probe(elem_type, status)
    TYPE(ElemType), INTENT(IN) :: elem_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(MD_Sect_Registry), TARGET :: sect_registry
    TYPE(MD_Elem_UEL_Desc) :: ed
    TYPE(MD_Sect_Desc) :: sd
    TYPE(PH_Elem_Ctx) :: ph_ctx
    TYPE(PH_Elem_State) :: ph_state
    TYPE(RT_Com_Base_Ctx) :: rt_ctx
    REAL(wp) :: pndt
    INTEGER(i4) :: ndof, nip
    
    CALL init_error_status(status)
    
    ! Build minimal test environment
    ndof = elem_type%pop%n_nodes * elem_type%n_dof_per_node
    IF (ndof <= 0_i4) ndof = 24_i4
    nip = elem_type%n_int_points
    IF (nip <= 0_i4) nip = 8_i4
    
    ! Initialize element descriptor
    CALL ed%Init(0_i4, 1_i4, 0_i4, 0_i4, 2_i4)
    ed%ndofel = ndof
    ed%integ_npts = nip
    ed%jprops(1) = 1_i4
    
    ! Initialize section registry
    CALL sect_registry%Init(4_i4)
    sd%section_id = 1_i4
    CALL sect_registry%AddSection(sd)
    
    ! Setup context
    pndt = RT_COM_PNEWDT_NO_CHANGE
    rt_ctx%kstep = 1_i4
    rt_ctx%kinc = 1_i4
    
    ! Call UEL API (expects mat_desc error or stub INVALID)
    CALL RT_Elem_UEL_API(sect_registry, ed, ph_ctx, ph_state, rt_ctx, pndt, status)
    
    ! Cleanup
    CALL sect_registry%Clear()
    
  END SUBROUTINE RT_Elem_UEL_Probe
  
END MODULE RT_Elem_UEL