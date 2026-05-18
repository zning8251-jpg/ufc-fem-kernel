!===============================================================================
! MODULE: MD_MatPLM_Reg
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Reg
! BRIEF:  Plastic material registry -- in-memory table + built-in registration.
!         Split from legacy monolithic plastic reg; aggregated by
!         MD_MatPLM_PlastBase.
! **W1**?**???????** � **`UF_Plastic_*Reg`** / **`PlastModels_Desc`**?**mat_id??????**?**`props` ??** ?? **`MD_Mat_Desc`** / **Populate** / **L4 `desc%props`** ???? **MD_MatPLM_PlastBase** / **PlastCall** ????
!===============================================================================
MODULE MD_Mat_Plast_Reg
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_NOT_FOUND, MD_MAT_STATUS_OK, init_error_status, log_error, log_warning, uf_set_error_status
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Plast_JohnsonCook, ONLY: MD_MAT_JOHNSONCOOK_MAT, MD_MAT_JOHNSONCOOK_MAT_NAME
  USE MD_Mat_Plast_Chaboche, ONLY: MD_MAT_CHABOCHE_MAT_ID
  USE MD_Mat_Plast_Hill, ONLY: MD_MAT_HILL_MAT_ID, MD_MAT_HILL_MAT_NAME

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: UF_Plastic_GetMaterialInfo
  PUBLIC :: UF_Plastic_ValidMatID
  PUBLIC :: UF_Plastic_RegisterMaterial
  PUBLIC :: UF_Plastic_InitReg
  PUBLIC :: UF_Plastic_RegAllMats
  PUBLIC :: PlastModels_Desc
  PUBLIC :: PlastMatInfo
  PUBLIC :: PlastMat_GetInfo_In
  PUBLIC :: PlastMat_GetInfo_Out
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_MAX_PROPS = 50_i4
  TYPE, PUBLIC :: PlastModels_Desc
    INTEGER(i4) :: nprops = 0_i4
    REAL(wp)    :: props(MD_MAT_PLAST_MAX_PROPS) = 0.0_wp
  END TYPE PlastModels_Desc

  INTEGER(i4), PARAMETER :: MD_MAT_MAX_MATS = 100_i4

  TYPE, PUBLIC :: PlastMatInfo
    INTEGER(i4) :: material_id = 0
    CHARACTER(LEN=64) :: name = ""
    CHARACTER(LEN=32) :: category = ""
    INTEGER(i4) :: nprops_min = 0
    INTEGER(i4) :: nprops_max = 0
    INTEGER(i4) :: nstatev_min = 0
    INTEGER(i4) :: nstatev_max = 0
    LOGICAL :: available = .FALSE.
  END TYPE PlastMatInfo

  TYPE, PUBLIC :: PlastMat_GetInfo_In
    INTEGER(i4) :: material_id = 0
  END TYPE PlastMat_GetInfo_In

  TYPE, PUBLIC :: PlastMat_GetInfo_Out
    TYPE(PlastMatInfo) :: info
    TYPE(ErrorStatusType) :: status
  END TYPE PlastMat_GetInfo_Out

  TYPE(PlastMatInfo), SAVE, ALLOCATABLE :: material_regist(:)
  INTEGER(i4), SAVE :: n_registered = 0_i4
  LOGICAL, SAVE :: registry_initia = .FALSE.

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CDP = 205_i4

  PUBLIC :: MD_MAT_VONMISES_MAT_ID, MD_MAT_VONMISES_MAT_NA
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_VONMISES_MAT_ID = 201_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: MD_MAT_VONMISES_MAT_NA = "von Mises Plasticity"

  PUBLIC :: MD_MAT_DRUCKERPRAGER_M, MD_MAT_DRUCKERPRAGER_M_NAME
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DRUCKERPRAGER_M = 202_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: MD_MAT_DRUCKERPRAGER_M_NAME = "Drucker-Prager Plasticity"

  PUBLIC :: MD_MAT_JOHNSONCOOK_MAT, MD_MAT_JOHNSONCOOK_MAT_NAME
  PUBLIC :: MD_MAT_CHABOCHE_MAT_ID
  PUBLIC :: MD_MAT_HILL_MAT_ID, MD_MAT_HILL_MAT_NAME

  PUBLIC :: MD_MAT_CAMCLAY_MAT_ID, MD_MAT_CAMCLAY_MAT_NAME
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAMCLAY_MAT_ID = 203_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: MD_MAT_CAMCLAY_MAT_NAME = "Cam-Clay Plasticity"

  PUBLIC :: MD_MAT_MOHRCOULOMB_MAT, MD_MAT_MOHRCOULOMB_MAT_NAME
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MOHRCOULOMB_MAT = 204_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: MD_MAT_MOHRCOULOMB_MAT_NAME = "Mohr-Coulomb Plasticity"

  PUBLIC :: MD_MAT_GURSON_MAT_ID, MD_MAT_GURSON_MAT_NAME
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GURSON_MAT_ID = 207_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: MD_MAT_GURSON_MAT_NAME = "Gurson-Tvergaard-Needleman (GTN)"

  PUBLIC :: MD_MAT_VISCOPLASTIC_MAT_ID, MD_MAT_VISCOPLASTIC_MAT_NAME
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_VISCOPLASTIC_MAT_ID = 250_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: MD_MAT_VISCOPLASTIC_MAT_NAME = "Perzyna Viscoplasticity"

  PUBLIC :: MD_MAT_SOFTROCK_MAT_ID, SOFTROCK_MAT_NA
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_SOFTROCK_MAT_ID = 215_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: SOFTROCK_MAT_NA = "Soft Rock Plasticity"

  PUBLIC :: MD_MAT_CAP_PLASTICITY, CAP_PLASTICITY_NAME
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAP_PLASTICITY = 221_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: CAP_PLASTICITY_NAME = "Cap Plasticity"

  PUBLIC :: MD_MAT_CRUSHOAM_MAT_ID
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CRUSHOAM_MAT_ID = 212_i4

  PUBLIC :: MD_MAT_BIVISC_MAT_ID
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_BIVISC_MAT_ID = 255_i4

  PUBLIC :: MD_MAT_CAST_IRON_MAT_I, MD_MAT_CAST_IRON_MAT_N
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAST_IRON_MAT_I = 223_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: MD_MAT_CAST_IRON_MAT_N = "Cast Iron Plasticity"

CONTAINS

  SUBROUTINE UF_Plastic_GetMaterialInfo(material_id, info, status)
    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(PlastMatInfo), INTENT(OUT) :: info
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Init registry if needed
    IF (.NOT. registry_initia) THEN
      CALL UF_Plastic_InitReg(status)
      IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
    END IF

    ! Search registry
    DO i = 1, n_registered
      IF (material_regist(i)%material_id == material_id) THEN
        info = material_regist(i)
        status%status_code = MD_MAT_STATUS_OK
        RETURN
      END IF
    END DO

    ! Not found
    status%status_code = MD_MAT_STATUS_NOT_FOUND
    status%message = "Mat ID not found in registry"
    info%material_id = 0
    info%available = .FALSE.

  END SUBROUTINE UF_Plastic_GetMaterialInfo

  SUBROUTINE UF_Plastic_InitReg(status)
    !! Init the plastic Mat registry

    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    IF (registry_initia) THEN
      status%status_code = MD_MAT_STATUS_OK
      RETURN
    END IF

    ! Allocate registry
    IF (.NOT. ALLOCATED(material_regist)) THEN
      ALLOCATE(material_regist(MD_MAT_MAX_MATS))
    END IF

    ! Init entries
    DO i = 1, MD_MAT_MAX_MATS
      material_regist(i)%material_id = 0
      material_regist(i)%name = ""
      material_regist(i)%category = ""
      material_regist(i)%nprops_min = 0
      material_regist(i)%nprops_max = 0
      material_regist(i)%nstatev_min = 0
      material_regist(i)%nstatev_max = 0
      material_regist(i)%available = .FALSE.
    END DO

    ! Reg built-in materials
    CALL UF_Plastic_RegBuiltInMats(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    registry_initia = .TRUE.
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_Plastic_InitReg

  SUBROUTINE UF_Plastic_RegBuiltInMats(status)
    !! Reg all built-in plastic materials

    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: reg_status

    CALL init_error_status(status)

    ! Reg Von Mises
    CALL UF_Plastic_RegMat_Int(MD_MAT_VONMISES_MAT_ID, &
                                               "von Mises Plasticity", &
                                               "Plastic", &
                                               4_i4, 5_i4, 8_i4, 8_i4, reg_status)

    ! Reg Hill
    CALL UF_Plastic_RegMat_Int(MD_MAT_HILL_MAT_ID, &
                                               "Hill Anisotropic Plasticity", &
                                               "Plastic", &
                                               10_i4, 14_i4, 7_i4, 7_i4, reg_status)

    ! Reg Drucker-Prager
    CALL UF_Plastic_RegMat_Int(MD_MAT_DRUCKERPRAGER_M, &
                                                "Drucker-Prager Plasticity", &
                                                "Plastic", &
                                                4_i4, 6_i4, 8_i4, 8_i4, reg_status)

    ! Reg Cam-Clay
    CALL UF_Plastic_RegMat_Int(MD_MAT_CAMCLAY_MAT_ID, &
                                                "Cam-Clay Plasticity", &
                                                "Plastic", &
                                                6_i4, 8_i4, 9_i4, 9_i4, reg_status)

    ! Reg Mohr-Coulomb
    CALL UF_Plastic_RegMat_Int(MD_MAT_MOHRCOULOMB_MAT, &
                                               "Mohr-Coulomb Plasticity", &
                                               "Plastic", &
                                               5_i4, 9_i4, 11_i4, 11_i4, reg_status)

    ! Reg Johnson-Cook
    CALL UF_Plastic_RegMat_Int(MD_MAT_JOHNSONCOOK_MAT, &
                                               "Johnson-Cook Plasticity", &
                                               "Plastic", &
                                               7_i4, 10_i4, 9_i4, 9_i4, reg_status)

    ! Reg Gurson (GTN)
    CALL UF_Plastic_RegMat_Int(MD_MAT_GURSON_MAT_ID, &
                                               "Gurson-Tvergaard-Needleman (GTN)", &
                                               "Plastic", &
                                               10_i4, 13_i4, 12_i4, 15_i4, reg_status)

    ! Reg Chaboche
    CALL UF_Plastic_RegMat_Int(MD_MAT_CHABOCHE_MAT_ID, &
                                               "Chaboche Kinematic Hardening", &
                                               "Plastic", &
                                               9_i4, 11_i4, 15_i4, 27_i4, reg_status)

    CALL UF_Plastic_RegMat_Int(MD_MAT_VISCOPLASTIC_MAT_ID, &
                                               TRIM(MD_MAT_VISCOPLASTIC_MAT_NAME), &
                                               "Plastic", &
                                               5_i4, 10_i4, 9_i4, 9_i4, reg_status)

    CALL UF_Plastic_RegMat_Int(MD_MAT_SOFTROCK_MAT_ID, &
                                               TRIM(SOFTROCK_MAT_NA), &
                                               "Plastic", &
                                               5_i4, 7_i4, 7_i4, 7_i4, reg_status)

    CALL UF_Plastic_RegMat_Int(MD_MAT_CRUSHOAM_MAT_ID, &
                                               "Crushable Foam Plasticity", &
                                               "Plastic", &
                                               5_i4, 15_i4, 4_i4, 20_i4, reg_status)

    CALL UF_Plastic_RegMat_Int(MD_MAT_BIVISC_MAT_ID, &
                                               "Bilayer Viscoplastic", &
                                               "Plastic", &
                                               8_i4, 20_i4, 14_i4, 20_i4, reg_status)

    ! Reserved stubs (IDs must match L3 MD_MatPLMCrystal / RateDepPlast / ZaPlast)
    CALL UF_Plastic_RegMat_Int(266_i4, &
                                               "Crystal Plasticity (stub)", &
                                               "Plastic", &
                                               1_i4, 99_i4, 1_i4, 99_i4, reg_status)
    CALL UF_Plastic_RegMat_Int(267_i4, &
                                               "PlasticRateDep (stub)", &
                                               "Plastic", &
                                               1_i4, 99_i4, 1_i4, 99_i4, reg_status)
    CALL UF_Plastic_RegMat_Int(268_i4, &
                                               "Zerilli-Armstrong (stub)", &
                                               "Plastic", &
                                               1_i4, 99_i4, 1_i4, 99_i4, reg_status)

    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_Plastic_RegBuiltInMats

  SUBROUTINE UF_Plastic_RegisterMaterial(material_id, name, category, &
                                         nprops_min, nprops_max, &
                                         nstatev_min, nstatev_max, status)
    !! Public interface for registering a plastic Mat

    INTEGER(i4), INTENT(IN) :: material_id
    CHARACTER(LEN=*), INTENT(IN) :: name, category
    INTEGER(i4), INTENT(IN) :: nprops_min, nprops_max
    INTEGER(i4), INTENT(IN) :: nstatev_min, nstatev_max
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL UF_Plastic_RegMat_Int(material_id, name, category, &
                                              nprops_min, nprops_max, &
                                              nstatev_min, nstatev_max, status)

  END SUBROUTINE UF_Plastic_RegisterMaterial

  SUBROUTINE UF_Plastic_RegMat_Int(material_id, name, category, &
                                                   nprops_min, nprops_max, &
                                                   nstatev_min, nstatev_max, status)
    !! Reg a plastic Mat in the registry (internal)

    INTEGER(i4), INTENT(IN) :: material_id
    CHARACTER(LEN=*), INTENT(IN) :: name, category
    INTEGER(i4), INTENT(IN) :: nprops_min, nprops_max
    INTEGER(i4), INTENT(IN) :: nstatev_min, nstatev_max
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: idx, i

    CALL init_error_status(status)

    ! Init registry if needed
    IF (.NOT. registry_initia) THEN
      CALL UF_Plastic_InitReg(status)
      IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
    END IF

    ! Check if already registered
    DO i = 1, n_registered
      IF (material_regist(i)%material_id == material_id) THEN
        status%status_code = MD_MAT_STATUS_INVALID
        status%message = "Mat ID already registered"
        RETURN
      END IF
    END DO

    ! Check registry capacity
    IF (n_registered >= MD_MAT_MAX_MATS) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Mat registry full"
      RETURN
    END IF

    ! Add to registry
    idx = n_registered + 1
    material_regist(idx)%material_id = material_id
    material_regist(idx)%name = name
    material_regist(idx)%category = category
    material_regist(idx)%nprops_min = nprops_min
    material_regist(idx)%nprops_max = nprops_max
    material_regist(idx)%nstatev_min = nstatev_min
    material_regist(idx)%nstatev_max = nstatev_max
    material_regist(idx)%available = .TRUE.

    n_registered = n_registered + 1
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_Plastic_RegMat_Int

  SUBROUTINE UF_Plastic_ValidMatID(material_id, status)
    !! Valid if a Mat ID is registered

    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(PlastMatInfo) :: info

    CALL UF_Plastic_GetMaterialInfo(material_id, info, status)

    IF (status%status_code == MD_MAT_STATUS_OK .AND. info%available) THEN
      status%status_code = MD_MAT_STATUS_OK
    ELSE
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      status%message = "Mat ID not available"
    END IF

  END SUBROUTINE UF_Plastic_ValidMatID



  SUBROUTINE UF_Plastic_RegAllMats(status)
    !! Reg all new plastic Mat modules with the unified interface

    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: reg_status

    CALL init_error_status(status)

    ! Reg Von Mises (ID 201)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_VONMISES_MAT_ID, &
                                      "von Mises Plasticity", &
                                      "Plastic", &
                                      4_i4, 5_i4, 8_i4, 8_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Hill (ID 205, MAT_PLAST_ANISO_HIL)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_HILL_MAT_ID, &
                                      "Hill Anisotropic Plasticity", &
                                      "Plastic", &
                                      10_i4, 14_i4, 7_i4, 7_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Drucker-Prager (registry id 202; distinct from Hill 205)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_DRUCKERPRAGER_M, &
                                     "Drucker-Prager Plasticity", &
                                     "Plastic", &
                                     4_i4, 6_i4, 8_i4, 8_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Cam-Clay (ID 203)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_CAMCLAY_MAT_ID, &
                                     "Cam-Clay Plasticity", &
                                     "Plastic", &
                                     6_i4, 8_i4, 9_i4, 9_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Mohr-Coulomb (ID 204)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_MOHRCOULOMB_MAT, &
                                     "Mohr-Coulomb Plasticity", &
                                     "Plastic", &
                                     5_i4, 9_i4, 11_i4, 11_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Johnson-Cook (ID 206)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_JOHNSONCOOK_MAT, &
                                     "Johnson-Cook Plasticity", &
                                     "Plastic", &
                                     7_i4, 10_i4, 9_i4, 9_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Gurson (GTN) (ID 207)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_GURSON_MAT_ID, &
                                     "Gurson-Tvergaard-Needleman (GTN)", &
                                     "Plastic", &
                                     10_i4, 13_i4, 12_i4, 15_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Chaboche (ID 208)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_CHABOCHE_MAT_ID, &
                                     "Chaboche Kinematic Hardening", &
                                     "Plastic", &
                                     9_i4, 11_i4, 15_i4, 27_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Cap Plasticity (ID 221)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_CAP_PLASTICITY, &
                                     "Cap Plasticity", &
                                     "Plastic", &
                                     8_i4, 15_i4, 9_i4, 20_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Crushable Foam �?mat_id 212 (PH_Mat_Reg_Core); legacy MATLIB id 222 handled in Eval
    CALL UF_Plastic_RegisterMaterial(MD_MAT_CRUSHOAM_MAT_ID, &
                                     "Crushable Foam Plasticity", &
                                     "Plastic", &
                                     5_i4, 15_i4, 4_i4, 20_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Cast Iron (ID 223)
    CALL UF_Plastic_RegisterMaterial(MD_MAT_CAST_IRON_MAT_I, &
                                     "Cast Iron Plasticity", &
                                     "Plastic", &
                                     6_i4, 15_i4, 9_i4, 20_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg Perzyna viscoplasticity (ID 250) �?aligned with PH_Mat_PLM_Viscoplastic / Eval
    CALL UF_Plastic_RegisterMaterial(MD_MAT_VISCOPLASTIC_MAT_ID, &
                                     TRIM(MD_MAT_VISCOPLASTIC_MAT_NAME), &
                                     "Plastic", &
                                     5_i4, 10_i4, 9_i4, 9_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reg soft rock / elliptic yield (ID 215) �?Eval dispatches UF_SoftRock_UMAT
    CALL UF_Plastic_RegisterMaterial(MD_MAT_SOFTROCK_MAT_ID, &
                                     TRIM(SOFTROCK_MAT_NA), &
                                     "Plastic", &
                                     5_i4, 7_i4, 7_i4, 7_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Bilayer viscoplastic (ID 216) �?PH_Mat_Reg_Core
    CALL UF_Plastic_RegisterMaterial(MD_MAT_BIVISC_MAT_ID, &
                                     "Bilayer Viscoplastic", &
                                     "Plastic", &
                                     8_i4, 20_i4, 14_i4, 20_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    ! Reserved stub IDs (must match MD_MatPLMCrystal / RateDepPlast / ZaPlast PARAMETERs)
    CALL UF_Plastic_RegisterMaterial(266_i4, &
                                     "Crystal Plasticity (stub)", &
                                     "Plastic", &
                                     1_i4, 99_i4, 1_i4, 99_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    CALL UF_Plastic_RegisterMaterial(267_i4, &
                                     "PlasticRateDep (stub)", &
                                     "Plastic", &
                                     1_i4, 99_i4, 1_i4, 99_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    CALL UF_Plastic_RegisterMaterial(268_i4, &
                                     "Zerilli-Armstrong (stub)", &
                                     "Plastic", &
                                     1_i4, 99_i4, 1_i4, 99_i4, reg_status)
    IF (reg_status%status_code /= MD_MAT_STATUS_OK) THEN
      status = reg_status
      RETURN
    END IF

    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_Plastic_RegAllMats

END MODULE MD_Mat_Plast_Reg