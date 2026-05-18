!===============================================================================
! MODULE: MD_L3_Layer
! LAYER:  L3_MD
! DOMAIN: Layer container (minimal material facet for L3↔L4 closure tests)
! BRIEF:  **`MD_L3_LayerContainer`** holds **`material`** facet with Init/Register
!         backed by **`MD_Mat_Registry`** + stable TARGET storage for descriptors.
!===============================================================================
MODULE MD_L3_Layer
  USE IF_Prec_Core, ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Registry, ONLY: MD_Mat_Registry_Init, MD_Mat_Registry_Finalize, MD_Mat_Registry_Register
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: MD_L3_MAT_STORE_MAX = 10000

  TYPE, PUBLIC :: MD_L3_Material_Block
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_L3_Material_Init
    PROCEDURE, PUBLIC :: Register => MD_L3_Material_Register
  END TYPE MD_L3_Material_Block

  TYPE, PUBLIC :: MD_L3_LayerContainer
    TYPE(MD_L3_Material_Block) :: material
  END TYPE MD_L3_LayerContainer

  TYPE(MD_Mat_Desc), ALLOCATABLE, TARGET, SAVE :: md_l3_mat_desc_store(:)

CONTAINS

  SUBROUTINE MD_L3_Material_Init(this, status)
    CLASS(MD_L3_Material_Block), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(ErrorStatusType) :: st_disc

    CALL MD_Mat_Registry_Finalize(st_disc)
    CALL MD_Mat_Registry_Init(status)
  END SUBROUTINE MD_L3_Material_Init

  SUBROUTINE MD_L3_Material_Register(this, mat_desc, mat_id, status)
    CLASS(MD_L3_Material_Block), INTENT(INOUT) :: this
    TYPE(MD_Mat_Desc), INTENT(IN), TARGET :: mat_desc
    INTEGER(i4), INTENT(IN) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: family_type, sub_type

    CALL init_error_status(status)
    IF (mat_id < 1_i4 .OR. mat_id > MD_L3_MAT_STORE_MAX) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_L3_Material_Register: mat_id out of store range"
      RETURN
    END IF

    IF (.NOT. ALLOCATED(md_l3_mat_desc_store)) THEN
      ALLOCATE(md_l3_mat_desc_store(MD_L3_MAT_STORE_MAX))
    END IF

    md_l3_mat_desc_store(mat_id) = mat_desc

    family_type = mat_desc%class_id
    sub_type = mat_desc%id
    IF (sub_type <= 0_i4) sub_type = mat_desc%pop%mat_model_id

    CALL MD_Mat_Registry_Register(mat_id, family_type, sub_type, &
                                   md_l3_mat_desc_store(mat_id), status)
  END SUBROUTINE MD_L3_Material_Register

END MODULE MD_L3_Layer
