!===============================================================================
! MODULE:  MD_Model_Access
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Impl (accessor functions)
! BRIEF:   P0 Get/Set accessors for Model data. Direct ModelTree access for
!          Section, Material queries by ID or name.
!
! NOTE:    Refactored to use canonical MD_Model_Desc (from MD_Model_Def)
!          instead of the pre-existing broken 'Model' alias.
!===============================================================================
MODULE MD_Model_Access
  USE IF_Err_Brg,          ONLY: ErrorStatusType, init_error_status, &
                                  MD_MODEL_STATUS_OK, MD_MODEL_STATUS_INVALID, &
                                  MD_MODEL_STATUS_NOT_FOUND
  USE IF_Prec_Core,        ONLY: wp, i4, i8
  USE MD_Base_TreeIndex_API, ONLY: TreeNodeBase
  USE MD_Mat_Lib,          ONLY: MD_Mat_Desc
  USE MD_Model_Tree,       ONLY: ModelTree
  USE MD_Model_Def,        ONLY: MD_Model_Desc
  USE MD_Sect_Mgr,         ONLY: SectDesc, SolidSectDesc, ShellSectDesc, &
                                  BeamSectDesc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Model_Access_GetSection
  PUBLIC :: MD_Model_Access_GetMaterial
  PUBLIC :: MD_Model_Access_GetMaterialID
  PUBLIC :: MD_Model_Access_GetMatNameFromSect

CONTAINS

  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Access_GetMaterial
  ! PHASE:      P0
  ! PURPOSE:    Retrieve material descriptor by ID or name from ModelTree
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Access_GetMaterial(model, material_id, material_name, status) &
      RESULT(material_ptr)
    CLASS(MD_Model_Desc), INTENT(IN)              :: model          ! [in] model desc
    INTEGER(i4), INTENT(IN), OPTIONAL             :: material_id    ! [in] mat ID
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL        :: material_name  ! [in] mat name
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL  :: status         ! [out] status
    TYPE(MD_Mat_Desc), POINTER :: material_ptr

    CLASS(TreeNodeBase), POINTER :: tree_node_ptr
    TYPE(ModelTree), POINTER :: model_tree_ptr

    material_ptr => NULL()

    IF (PRESENT(status)) CALL init_error_status(status)

    SELECT TYPE (model)
    TYPE IS (ModelTree)
      model_tree_ptr => model

      IF (PRESENT(material_id)) THEN
        tree_node_ptr => model_tree_ptr%GetMaterial(id=material_id)
      ELSE IF (PRESENT(material_name)) THEN
        tree_node_ptr => model_tree_ptr%GetMaterial(name=TRIM(material_name))
      ELSE
        IF (PRESENT(status)) THEN
          status%status_code = MD_MODEL_STATUS_INVALID
          status%message = "MD_Model_Access_GetMaterial: Either material_id or " // &
                           "material_name must be provided"
        END IF
        RETURN
      END IF

      IF (ASSOCIATED(tree_node_ptr)) THEN
        SELECT TYPE (tree_node_ptr)
        TYPE IS (MD_Mat_Desc)
          material_ptr => tree_node_ptr
        CLASS DEFAULT
          IF (PRESENT(status)) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "MD_Model_Access_GetMaterial: Node is not MD_Mat_Desc type"
          END IF
        END SELECT
      ELSE
        IF (PRESENT(status)) THEN
          status%status_code = MD_MODEL_STATUS_NOT_FOUND
          status%message = "MD_Model_Access_GetMaterial: Not found in ModelTree"
        END IF
      END IF

    CLASS DEFAULT
      IF (PRESENT(status)) THEN
        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "MD_Model_Access_GetMaterial: Model desc is not ModelTree"
      END IF
    END SELECT

    IF (ASSOCIATED(material_ptr) .AND. PRESENT(status)) THEN
      status%status_code = MD_MODEL_STATUS_OK
    END IF
  END FUNCTION MD_Model_Access_GetMaterial


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Access_GetMaterialID
  ! PHASE:      P0
  ! PURPOSE:    Get material ID by name
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Access_GetMaterialID(model, material_name, status) RESULT(material_id)
    CLASS(MD_Model_Desc), INTENT(IN)              :: model          ! [in] model desc
    CHARACTER(LEN=*), INTENT(IN)                  :: material_name  ! [in] name
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL  :: status         ! [out] status
    INTEGER(i4) :: material_id

    TYPE(MD_Mat_Desc), POINTER :: mat_desc

    material_id = 0_i4

    IF (PRESENT(status)) CALL init_error_status(status)

    mat_desc => MD_Model_Access_GetMaterial(model, material_name=TRIM(material_name), &
                                     status=status)

    IF (ASSOCIATED(mat_desc)) THEN
      material_id = mat_desc%cfg%id
      IF (material_id <= 0_i4 .AND. PRESENT(status)) THEN
        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "MD_Model_Access_GetMaterialID: Mat found but has invalid ID"
      END IF
    END IF
  END FUNCTION MD_Model_Access_GetMaterialID


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Access_GetMatNameFromSect
  ! PHASE:      P0
  ! PURPOSE:    Get material name from section ID
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Access_GetMatNameFromSect(model, section_id, status) &
      RESULT(material_name)
    CLASS(MD_Model_Desc), INTENT(IN)              :: model        ! [in] model desc
    INTEGER(i4), INTENT(IN)                       :: section_id   ! [in] sect ID
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL  :: status       ! [out] status
    CHARACTER(LEN=64) :: material_name

    CLASS(SectDesc), POINTER :: section_ptr
    TYPE(SolidSectDesc), POINTER :: solid_section
    TYPE(ShellSectDesc), POINTER :: shell_section
    TYPE(BeamSectDesc), POINTER :: beam_section

    material_name = ""

    IF (PRESENT(status)) CALL init_error_status(status)

    section_ptr => MD_Model_Access_GetSection(model, section_id=section_id, status=status)

    IF (ASSOCIATED(section_ptr)) THEN
      SELECT TYPE (section_ptr)
      TYPE IS (SolidSectDesc)
        solid_section => section_ptr
        material_name = TRIM(solid_section%materialName)
      TYPE IS (ShellSectDesc)
        shell_section => section_ptr
        material_name = TRIM(shell_section%materialName)
      TYPE IS (BeamSectDesc)
        beam_section => section_ptr
        material_name = TRIM(beam_section%materialName)
      CLASS DEFAULT
        IF (PRESENT(status)) THEN
          status%status_code = MD_MODEL_STATUS_INVALID
          status%message = "MD_Model_Access_GetMatNameFromSect: Unknown section type"
        END IF
      END SELECT
    END IF
  END FUNCTION MD_Model_Access_GetMatNameFromSect


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Access_GetSection
  ! PHASE:      P0
  ! PURPOSE:    Retrieve section descriptor by ID or name from ModelTree
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Access_GetSection(model, section_id, section_name, status) &
      RESULT(section_ptr)
    CLASS(MD_Model_Desc), INTENT(IN)              :: model         ! [in] model desc
    INTEGER(i4), INTENT(IN), OPTIONAL             :: section_id    ! [in] sect ID
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL        :: section_name  ! [in] sect name
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL  :: status        ! [out] status
    CLASS(SectDesc), POINTER :: section_ptr

    CLASS(TreeNodeBase), POINTER :: tree_node_ptr
    TYPE(ModelTree), POINTER :: model_tree_ptr

    section_ptr => NULL()

    IF (PRESENT(status)) CALL init_error_status(status)

    SELECT TYPE (model)
    TYPE IS (ModelTree)
      model_tree_ptr => model

      IF (PRESENT(section_id)) THEN
        tree_node_ptr => model_tree_ptr%GetSection(id=section_id)
      ELSE IF (PRESENT(section_name)) THEN
        tree_node_ptr => model_tree_ptr%GetSection(name=TRIM(section_name))
      ELSE
        IF (PRESENT(status)) THEN
          status%status_code = MD_MODEL_STATUS_INVALID
          status%message = "MD_Model_Access_GetSection: Either section_id or " // &
                           "section_name must be provided"
        END IF
        RETURN
      END IF

      IF (ASSOCIATED(tree_node_ptr)) THEN
        SELECT TYPE (tree_node_ptr)
        TYPE IS (SectDesc)
          section_ptr => tree_node_ptr
        TYPE IS (SolidSectDesc)
          section_ptr => tree_node_ptr
        TYPE IS (ShellSectDesc)
          section_ptr => tree_node_ptr
        TYPE IS (BeamSectDesc)
          section_ptr => tree_node_ptr
        CLASS DEFAULT
          IF (PRESENT(status)) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "MD_Model_Access_GetSection: Node is not SectDesc type"
          END IF
        END SELECT
      ELSE
        IF (PRESENT(status)) THEN
          status%status_code = MD_MODEL_STATUS_NOT_FOUND
          status%message = "MD_Model_Access_GetSection: Not found in ModelTree"
        END IF
      END IF

    CLASS DEFAULT
      IF (PRESENT(status)) THEN
        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "MD_Model_Access_GetSection: Model desc is not ModelTree"
      END IF
    END SELECT

    IF (ASSOCIATED(section_ptr) .AND. PRESENT(status)) THEN
      status%status_code = MD_MODEL_STATUS_OK
    END IF
  END FUNCTION MD_Model_Access_GetSection

END MODULE MD_Model_Access
