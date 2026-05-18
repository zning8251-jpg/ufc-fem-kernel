#!/usr/bin/env python3
"""Generate UFC/ufc_core/L3_MD/Material/Contract/MD_Mat_Def.f90 from extracted Lib fragment."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXTRACT = ROOT / "tools/_md_mat_def_extracted.f90"
OUT = ROOT / "ufc_core/L3_MD/Material/Contract/MD_Mat_Def.f90"


def main() -> None:
    frag = EXTRACT.read_text(encoding="utf-8")
    frag = frag.replace("nullify(this%sta)", "! sta is value TYPE(BaseSta); do not nullify")
    frag = frag.replace("call this%Destroy()", "call MatCtxLegacy_Clean(this)")
    # Rename duplicate generic Init/Clean in fragment to unique module procedure names
    repl = [
        (
            "  subroutine Init(this, kin, desc, material_id, nprops, nstatev, status)",
            "  subroutine MatCtxLegacy_InitLegacy(this, kin, desc, material_id, nprops, nstatev, status)",
        ),
        ("    status%status_code = MD_MAT_STATUS_OK\n  end subroutine Init\n\n  subroutine Clean(this)", "    status%status_code = MD_MAT_STATUS_OK\n  end subroutine MatCtxLegacy_InitLegacy\n\n  subroutine MatCtxLegacy_Clean(this)"),
        ("  end subroutine Clean\n\n  subroutine SetProps(this, props)", "  end subroutine MatCtxLegacy_Clean\n\n  subroutine SetProps(this, props)"),
        (
            "  subroutine Init(this, ntens, nstatev, status)\n    class(MatRes),",
            "  subroutine MatRes_InitArrays(this, ntens, nstatev, status)\n    class(MatRes),",
        ),
        ("    status%status_code = MD_MAT_STATUS_OK\n  end subroutine Init\n\n  subroutine Clean(this)\n    class(MatRes),", "    status%status_code = MD_MAT_STATUS_OK\n  end subroutine MatRes_InitArrays\n\n  subroutine MatRes_Clean(this)\n    class(MatRes),"),
        ("  end subroutine Clean\n\n  subroutine Reset(this)\n    class(MatRes),", "  end subroutine MatRes_Clean\n\n  subroutine Reset(this)\n    class(MatRes),"),
        (
            "  subroutine Init(this, material_id, nprops, status)\n    class(MatProps),",
            "  subroutine MatProps_InitArrays(this, material_id, nprops, status)\n    class(MatProps),",
        ),
        ("    status%status_code = MD_MAT_STATUS_OK\n  end subroutine Init\n\n  subroutine Clean(this)\n    class(MatProps),", "    status%status_code = MD_MAT_STATUS_OK\n  end subroutine MatProps_InitArrays\n\n  subroutine MatProps_Clean(this)\n    class(MatProps),"),
        ("  end subroutine Clean\n\n  subroutine SetProp(this, idx, value)", "  end subroutine MatProps_Clean\n\n  subroutine SetProp(this, idx, value)"),
        (
            "  subroutine Init(this, material_id, material_name, nprops, nstatev, &\n                                  requires_temp, supports_2d, supports_3d, status)\n    class(MD_MAT_UMAT_Intf),",
            "  subroutine MD_MAT_UMAT_Intf_Init0(this, material_id, material_name, nprops, nstatev, &\n                                  requires_temp, supports_2d, supports_3d, status)\n    class(MD_MAT_UMAT_Intf),",
        ),
        ("    status%status_code = MD_MAT_STATUS_OK\n  end subroutine Init\n\n  subroutine Valid(this, status)\n    class(MD_MAT_UMAT_Intf),", "    status%status_code = MD_MAT_STATUS_OK\n  end subroutine MD_MAT_UMAT_Intf_Init0\n\n  subroutine MD_MAT_UMAT_Intf_Valid0(this, status)\n    class(MD_MAT_UMAT_Intf),"),
        (
            "  subroutine Init(this, ntens, nstatv, nprops, status)\n    class(MD_MAT_UMAT_Input),",
            "  subroutine MD_MAT_UMAT_Input_Init0(this, ntens, nstatv, nprops, status)\n    class(MD_MAT_UMAT_Input),",
        ),
        ("    status%status_code = MD_MAT_STATUS_OK\n  end subroutine Init\n\n  subroutine Clean(this)\n    class(MD_MAT_UMAT_Input),", "    status%status_code = MD_MAT_STATUS_OK\n  end subroutine MD_MAT_UMAT_Input_Init0\n\n  subroutine MD_MAT_UMAT_Input_Clean0(this)\n    class(MD_MAT_UMAT_Input),"),
        ("  end subroutine Clean\n\n  subroutine FromKinematics(this, kin)", "  end subroutine MD_MAT_UMAT_Input_Clean0\n\n  subroutine FromKinematics(this, kin)"),
        (
            "  subroutine Init(this, ntens, nstatv, status)\n    class(MD_MAT_UMAT_Output),",
            "  subroutine MD_MAT_UMAT_Output_Init0(this, ntens, nstatv, status)\n    class(MD_MAT_UMAT_Output),",
        ),
        ("    status%status_code = MD_MAT_STATUS_OK\n  end subroutine Init\n\n  subroutine Clean(this)\n    class(MD_MAT_UMAT_Output),", "    status%status_code = MD_MAT_STATUS_OK\n  end subroutine MD_MAT_UMAT_Output_Init0\n\n  subroutine MD_MAT_UMAT_Output_Clean0(this)\n    class(MD_MAT_UMAT_Output),"),
        ("  end subroutine Clean\n\n  subroutine ToState(this, state)", "  end subroutine MD_MAT_UMAT_Output_Clean0\n\n  subroutine ToState(this, state)"),
    ]
    for a, b in repl:
        if a not in frag:
            raise SystemExit(f"pattern not found for replace block:\n{a[:80]}...")
        frag = frag.replace(a, b, 1)

    header = r'''!===============================================================================
! MODULE: MD_Mat_Def
! LAYER:  L3_MD / Material / Contract
! BRIEF:  Canonical material TYPE definitions + legacy MatCtx / UMAT helpers.
!         Restored 2026-04-30 from DomainProcedureRegistry excerpts + Lib extract.
!         W1: nested MD_Mat_Cfg_Init_Desc / MD_Mat_Pop_Vld_Desc under MD_MatDesc.
!===============================================================================
MODULE MD_Mat_Def

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, &
                        MD_MAT_STATUS_NOT_FOUND, MD_MAT_STATUS_ERROR, uf_set_error_status
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
                        IF_DATA_TYPE_INT, IF_DATA_TYPE_CHAR, IF_DATA_TYPE_DP
  USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, DescBase_Destroy, StateBase, StateBase_Init, StateBase_Destroy, &
                              CtxBase, CtxBase_Init, AlgoBase, AlgoBase_Init, &
                              CAT_DESC, CAT_STATE, CAT_CTX, CAT_ALGO, BaseSta, BaseSta_SetStatus, &
                              TreeSerializer, TreeDeserializer
  USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D, IF_MEM_DOMAIN_MAT
  USE MD_Kinematics_Def, ONLY: UF_Kinematics
  USE, INTRINSIC :: IEEE_ARITHMETIC, ONLY: ieee_is_finite

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_NOT_FOUND, MD_MAT_STATUS_ERROR

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MAX_MATERIALS = 1000_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MAX_PROPS = 256_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DESC_PROPS_MAX = 512_i4

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_UNKNO = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_ELAS = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_PLAST = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_HYP = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_VISC = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_CREEP = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_USER = 10_i4

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_GENERAL = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_EL = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_PL = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_DA = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_HY = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_VI = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_CR = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_CO = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_US = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_FOAM = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_GEOMAT = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_COMPOSITE = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_MULTIPHYS = 12_i4

  INTEGER(i4), PUBLIC, SAVE :: MATERIAL_DESC_I = -1_i4
  INTEGER(i4), PUBLIC, SAVE :: MATERIAL_ST_ID = -1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: g_material_id = 7_i4

  TYPE, PUBLIC :: MD_Mat_Cfg_Init_Desc
    INTEGER(i4)       :: id = 0_i4
    INTEGER(i4)       :: matId = 0_i4
    INTEGER(i4)       :: matModel = 0_i4
    CHARACTER(len=32) :: materialType = ""
    INTEGER(i4)       :: class_id = 0_i4
    CHARACTER(len=32) :: behavior = ""
    CHARACTER(len=64) :: description = ""
  END TYPE MD_Mat_Cfg_Init_Desc

  TYPE, PUBLIC :: MD_Mat_Pop_Vld_Desc
    INTEGER(i4) :: nProps = 0_i4
    INTEGER(i4) :: nStateV = 0_i4
    INTEGER(i4) :: mat_model_id = 0_i4
  END TYPE MD_Mat_Pop_Vld_Desc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_MatDesc
    TYPE(MD_Mat_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Pop_Vld_Desc)  :: pop
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4) :: id = 0_i4
    CHARACTER(len=32) :: materialType = ""
    INTEGER(i4) :: class_id = 0_i4
    INTEGER(i4) :: nProps = 0_i4
    INTEGER(i4) :: nStateV = 0_i4
    CHARACTER(len=32) :: behavior = ""
    CHARACTER(len=64) :: description = ""
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_MatDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_MatDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_MatDesc_Init_Base
    PROCEDURE, PUBLIC :: Destroy => MD_MatDesc_Destroy
    PROCEDURE, PUBLIC :: Valid => MD_MatDesc_Valid_Fn
  END TYPE MD_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatDesc) :: DP_MatDesc
    REAL(wp) :: E_young = 0.0_wp
    REAL(wp) :: nu_poisson = 0.0_wp
    REAL(wp) :: alpha_friction = 0.0_wp
    REAL(wp) :: k0_cohesion = 0.0_wp
    REAL(wp) :: H_hardening = 0.0_wp
    REAL(wp) :: beta_dilation = 0.0_wp
  END TYPE DP_MatDesc

  TYPE, PUBLIC :: MD_MatModel
    INTEGER(i4) :: id = 0_i4
    CHARACTER(len=64) :: name = ""
    INTEGER(i4) :: modelType = 0_i4
    INTEGER(i4) :: numProperties = 0_i4
    INTEGER(i4) :: nStatev = 0_i4
    REAL(wp), ALLOCATABLE :: properties(:)
    REAL(wp), ALLOCATABLE :: statev(:)
    INTEGER(i4), ALLOCATABLE :: propIds(:)
  END TYPE MD_MatModel

  TYPE, PUBLIC :: Desc_MaterialModel
    INTEGER(i4) :: material_id = 0_i4
    INTEGER(i4) :: nprops = 0_i4
    INTEGER(i4) :: nstatev = 0_i4
    CHARACTER(len=64) :: name = ""
    REAL(wp), ALLOCATABLE :: props(:)
    REAL(wp), ALLOCATABLE :: statev(:)
  END TYPE Desc_MaterialModel

  TYPE, PUBLIC :: State_IntPoint
    REAL(wp), ALLOCATABLE :: stress(:)
    TYPE(MD_Mat_Pop_Vld_Desc) :: pop
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp) :: sse = 0.0_wp
    REAL(wp) :: spd = 0.0_wp
    REAL(wp) :: scd = 0.0_wp
    REAL(wp) :: rpl = 0.0_wp
  END TYPE State_IntPoint

  TYPE, PUBLIC :: MatCtxLegacy
    TYPE(UF_Kinematics) :: kin
    TYPE(Desc_MaterialModel) :: desc
    REAL(wp), POINTER :: props(:) => NULL()
    REAL(wp), POINTER :: statev(:) => NULL()
    INTEGER(i4) :: material_id = 0_i4
    INTEGER(i4) :: nprops = 0_i4
    INTEGER(i4) :: nstatev = 0_i4
    INTEGER(i4) :: props_mem_id = 0_i4
    INTEGER(i4) :: statev_mem_id = 0_i4
    LOGICAL :: props_associate = .FALSE.
    LOGICAL :: statev_associat = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatCtxLegacy_InitLegacy
    PROCEDURE, PUBLIC :: Clean => MatCtxLegacy_Clean
    PROCEDURE, PUBLIC :: SetProps => SetProps
    PROCEDURE, PUBLIC :: SetStateV => SetStateV
    PROCEDURE, PUBLIC :: GetProps => GetProps
    PROCEDURE, PUBLIC :: GetStateV => GetStateV
    PROCEDURE, PUBLIC :: AllocateProps => AllocateProps
    PROCEDURE, PUBLIC :: AllocateStateV => AllocateStateV
    PROCEDURE, PUBLIC :: IsPropsAssociated => IsPropsAssociated
    PROCEDURE, PUBLIC :: IsStateVAssociated => IsStateVAssociated
  END TYPE MatCtxLegacy

  TYPE, PUBLIC :: MatRes
    REAL(wp), ALLOCATABLE :: stress(:)
    REAL(wp), ALLOCATABLE :: tangent(:, :)
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp) :: sse = 0.0_wp
    REAL(wp) :: spd = 0.0_wp
    REAL(wp) :: scd = 0.0_wp
    REAL(wp) :: rpl = 0.0_wp
    LOGICAL :: failed = .FALSE.
    LOGICAL :: is_plastic = .FALSE.
    LOGICAL :: suggest_cutback = .FALSE.
    REAL(wp) :: pnewdt_factor = 1.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatRes_InitArrays
    PROCEDURE, PUBLIC :: Clean => MatRes_Clean
    PROCEDURE, PUBLIC :: Reset => Reset
  END TYPE MatRes

  TYPE, PUBLIC :: MatFlags
    LOGICAL :: failed = .FALSE.
    LOGICAL :: suggest_cutback = .FALSE.
    LOGICAL :: is_plastic = .FALSE.
    REAL(wp) :: pnewdt_factor = 1.0_wp
  END TYPE MatFlags

  TYPE, PUBLIC :: MatProps
    INTEGER(i4) :: material_id = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4) :: nprops = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatProps_InitArrays
    PROCEDURE, PUBLIC :: Clean => MatProps_Clean
    PROCEDURE, PUBLIC :: SetProp => SetProp
    PROCEDURE, PUBLIC :: GetProp => GetProp
  END TYPE MatProps

  TYPE, PUBLIC :: MD_MAT_UMAT_Intf
    INTEGER(i4) :: material_id = 0_i4
    CHARACTER(len=80) :: material_name = ""
    INTEGER(i4) :: nprops = 0_i4
    INTEGER(i4) :: nstatev = 0_i4
    LOGICAL :: requires_temp = .FALSE.
    LOGICAL :: supports_2d = .TRUE.
    LOGICAL :: supports_3d = .TRUE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_MAT_UMAT_Intf_Init0
    PROCEDURE, PUBLIC :: Valid => MD_MAT_UMAT_Intf_Valid0
  END TYPE MD_MAT_UMAT_Intf

  TYPE, PUBLIC :: MD_MAT_UMAT_Input
    REAL(wp), ALLOCATABLE :: stress(:)
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp), ALLOCATABLE :: stran(:)
    REAL(wp), ALLOCATABLE :: dstran(:)
    REAL(wp), ALLOCATABLE :: props(:)
    REAL(wp) :: time(2) = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
    REAL(wp) :: coords(3) = 0.0_wp
    REAL(wp) :: drot(3, 3) = 0.0_wp
    REAL(wp) :: dfgrd0(3, 3) = 0.0_wp
    REAL(wp) :: dfgrd1(3, 3) = 0.0_wp
    REAL(wp) :: pnewdt = 1.0_wp
    REAL(wp) :: celent = 0.0_wp
    INTEGER(i4) :: noel = 0_i4
    INTEGER(i4) :: npt = 0_i4
    INTEGER(i4) :: layer = 0_i4
    INTEGER(i4) :: kspt = 0_i4
    INTEGER(i4) :: kstep = 0_i4
    INTEGER(i4) :: kinc = 0_i4
    INTEGER(i4) :: ndir = 3_i4
    INTEGER(i4) :: nshr = 3_i4
    INTEGER(i4) :: ntens = 6_i4
    INTEGER(i4) :: nstatv = 0_i4
    INTEGER(i4) :: nprops = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_MAT_UMAT_Input_Init0
    PROCEDURE, PUBLIC :: Clean => MD_MAT_UMAT_Input_Clean0
    PROCEDURE, PUBLIC :: FromKinematics => FromKinematics
  END TYPE MD_MAT_UMAT_Input

  TYPE, PUBLIC :: MD_MAT_UMAT_Output
    REAL(wp), ALLOCATABLE :: stress(:)
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp), ALLOCATABLE :: ddsdde(:, :)
    REAL(wp) :: sse = 0.0_wp
    REAL(wp) :: spd = 0.0_wp
    REAL(wp) :: scd = 0.0_wp
    REAL(wp) :: rpl = 0.0_wp
    REAL(wp), ALLOCATABLE :: ddsddt(:)
    REAL(wp), ALLOCATABLE :: drplde(:)
    REAL(wp) :: drpldt = 0.0_wp
    REAL(wp) :: pnewdt = 1.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_MAT_UMAT_Output_Init0
    PROCEDURE, PUBLIC :: Clean => MD_MAT_UMAT_Output_Clean0
    PROCEDURE, PUBLIC :: ToState => ToState
  END TYPE MD_MAT_UMAT_Output

  TYPE, PUBLIC :: MD_MatMeta
    INTEGER(i4) :: material_id = 0_i4
    CHARACTER(len=80) :: name = ""
    CHARACTER(len=80) :: description = ""
    INTEGER(i4) :: category = 0_i4
    CHARACTER(len=80) :: category_name = ""
    INTEGER(i4) :: nprops_min = 0_i4
    INTEGER(i4) :: nprops_max = 0_i4
    INTEGER(i4) :: nstatev_min = 0_i4
    INTEGER(i4) :: nstatev_max = 0_i4
    LOGICAL :: available = .FALSE.
    LOGICAL :: requires_temp = .FALSE.
    LOGICAL :: supports_2d = .TRUE.
    LOGICAL :: supports_3d = .TRUE.
    CHARACTER(len=200) :: prop_names = ""
    CHARACTER(len=200) :: statev_names = ""
  CONTAINS
    PROCEDURE, PUBLIC :: ValidateProps => MD_MatMeta_ValidateProps
  END TYPE MD_MatMeta

  TYPE, PUBLIC :: MatReg
    INTEGER(i4) :: nMats = 0_i4
    INTEGER(i4) :: MD_MAT_MAX_MATS = 100_i4
    TYPE(MD_MatMeta), ALLOCATABLE :: materials(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatReg_Init
    PROCEDURE, PUBLIC :: Clean => MatReg_Clean
    PROCEDURE, PUBLIC :: RegisterMaterial => MatReg_RegisterMaterial
    PROCEDURE, PUBLIC :: GetMaterial => MatReg_GetMaterial
    PROCEDURE, PUBLIC :: FindMaterial => MatReg_FindMaterial
    PROCEDURE, PUBLIC :: ListMaterials => MatReg_ListMaterials
    PROCEDURE, PUBLIC :: ValidateProps => MatReg_ValidateProps
    PROCEDURE, PUBLIC :: GetCategoryName => MatReg_GetCategoryName
  END TYPE MatReg

  TYPE, PUBLIC :: MatInst
    INTEGER(i4) :: instance_id = 0_i4
    INTEGER(i4) :: material_id = 0_i4
    CHARACTER(len=80) :: name = ""
    INTEGER(i4) :: nprops = 0_i4
    INTEGER(i4) :: nstatev = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    REAL(wp), ALLOCATABLE :: statev_initial(:)
    LOGICAL :: active = .FALSE.
    TYPE(MD_MatMeta) :: metadata
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatInst_Init
    PROCEDURE, PUBLIC :: Clean => MatInst_Clean
    PROCEDURE, PUBLIC :: SetProps => MatInst_SetProps
    PROCEDURE, PUBLIC :: GetProps => MatInst_GetProps
    PROCEDURE, PUBLIC :: Valid => MatInst_Valid
  END TYPE MatInst

  TYPE, PUBLIC :: MatPoolMgr
    INTEGER(i4) :: num_instances = 0_i4
    INTEGER(i4) :: max_instances = 1000_i4
    TYPE(MatInst), ALLOCATABLE :: instances(:)
    TYPE(MatReg) :: registry
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatPoolMgr_Init
    PROCEDURE, PUBLIC :: Clean => MatPoolMgr_Clean
    PROCEDURE, PUBLIC :: CreateInst => MatPoolMgr_CreateInst
    PROCEDURE, PUBLIC :: GetInst => MatPoolMgr_GetInst
    PROCEDURE, PUBLIC :: RemoveInst => MatPoolMgr_RemoveInst
    PROCEDURE, PUBLIC :: UpdateInst => MatPoolMgr_UpdateInst
    PROCEDURE, PUBLIC :: ListInsts => MatPoolMgr_ListInsts
    PROCEDURE, PUBLIC :: GetReg => MatPoolMgr_GetReg
  END TYPE MatPoolMgr

  TYPE, PUBLIC :: MatOri
    REAL(wp) :: angles(3) = 0.0_wp
    REAL(wp) :: rotationMatrix(3, 3) = 0.0_wp
    LOGICAL :: isSet = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatOri_Init
    PROCEDURE, PUBLIC :: GetRotMat => MatOri_GetRotMat
  END TYPE MatOri

  TYPE, PUBLIC :: MatPropValid
    INTEGER(i4) :: id = 0_i4
    INTEGER(i4) :: numProperties = 0_i4
    REAL(wp), ALLOCATABLE :: minValues(:)
    REAL(wp), ALLOCATABLE :: maxValues(:)
    LOGICAL, ALLOCATABLE :: required(:)
    CHARACTER(len=64), ALLOCATABLE :: propertyNames(:)
    LOGICAL :: isValid = .TRUE.
    CHARACTER(len=256) :: errorMessage = ""
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatPropValid_Init
    PROCEDURE, PUBLIC :: SetPropRange => MatPropValid_SetPropRange
    PROCEDURE, PUBLIC :: Valid => MatPropValid_Valid
    PROCEDURE, PUBLIC :: GetErrMsg => MatPropValid_GetErrMsg
  END TYPE MatPropValid

  TYPE, PUBLIC, ABSTRACT :: MD_Mat_Base_Desc
    INTEGER(i4) :: mat_kind = 0_i4
  END TYPE MD_Mat_Base_Desc

  TYPE, PUBLIC :: MD_Mat_Base_Algo
    INTEGER(i4) :: algo_id = 0_i4
  END TYPE MD_Mat_Base_Algo

  TYPE, PUBLIC :: MD_Mat_Base_State
    INTEGER(i4) :: state_id = 0_i4
  END TYPE MD_Mat_Base_State

  TYPE, PUBLIC :: MD_MaterialEntry
    TYPE(MD_Mat_Cfg_Init_Desc) :: cfg
    CHARACTER(LEN=128) :: name = ""
    INTEGER(i4) :: mat_type = 0_i4
    INTEGER(i4) :: n_props = 0_i4
    REAL(wp) :: props(MD_MAT_MAX_PROPS) = 0.0_wp
    LOGICAL :: valid = .FALSE.
  END TYPE MD_MaterialEntry

  TYPE, PUBLIC :: MD_Material_Desc
    INTEGER(i4) :: n_materials = 0_i4
    TYPE(MD_MaterialEntry) :: materials(MD_MAT_MAX_MATERIALS)
  END TYPE MD_Material_Desc

  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_MatState
    TYPE(MD_Mat_Cfg_Init_Desc) :: cfg
    INTEGER(i4) :: nIntPoints = 0_i4
    REAL(wp), ALLOCATABLE :: stress(:)
    REAL(wp), ALLOCATABLE :: strain(:)
    REAL(wp), ALLOCATABLE :: stateV(:)
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_MatState_Init_Base
    PROCEDURE, PUBLIC :: Destroy => MD_MatState_Destroy
  END TYPE MD_MatState

  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_MatSta
    INTEGER(i4) :: slot = 0_i4
  END TYPE MD_MatSta

  TYPE, PUBLIC, EXTENDS(CtxBase) :: MD_MatCtx
    INTEGER(i4) :: ctx_id = 0_i4
  END TYPE MD_MatCtx

  TYPE, PUBLIC, EXTENDS(AlgoBase) :: MD_MatAlgo
    INTEGER(i4) :: method = 0_i4
  END TYPE MD_MatAlgo

  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_MatPointSta
    INTEGER(i4) :: point_id = 0_i4
  END TYPE MD_MatPointSta

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_ElasticMatDesc
  END TYPE MD_ElasticMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_PlasticMatDesc
  END TYPE MD_PlasticMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_HyperElasticMatDesc
  END TYPE MD_HyperElasticMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_DamageMatDesc
  END TYPE MD_DamageMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_PronyMatDesc
  END TYPE MD_PronyMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_CompositeMatDesc
  END TYPE MD_CompositeMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_MatModelDesc
  END TYPE MD_MatModelDesc

  TYPE, PUBLIC :: MD_Material_Ctx
    TYPE(MD_MatDesc), POINTER :: desc => NULL()
    TYPE(MD_MatSta), POINTER :: mat_sta => NULL()
    TYPE(MD_MatAlgo), POINTER :: algo => NULL()
    TYPE(MatCtxLegacy), POINTER :: ctx => NULL()
    TYPE(MatRes), POINTER :: res => NULL()
    TYPE(UF_Kinematics), POINTER :: kin => NULL()
    TYPE(Desc_MaterialModel), POINTER :: desc_legacy => NULL()
    TYPE(BaseSta) :: sta
    LOGICAL :: init = .FALSE.
    LOGICAL :: success = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatCtx_Init
    PROCEDURE, PUBLIC :: Clean => MatCtx_Clean
    PROCEDURE, PUBLIC :: Reset => MatCtx_Reset
    PROCEDURE, PUBLIC :: GetStatus => MatCtx_GetStat
    PROCEDURE, PUBLIC :: SetStatus => MatCtx_SetStat
    PROCEDURE, PUBLIC :: ClearStatus => MatCtx_ClrStat
    PROCEDURE, PUBLIC :: IsOK => MatCtx_IsOk
    PROCEDURE, PUBLIC :: IsError => MatCtx_IsErr
    PROCEDURE, PUBLIC :: Bind => MatCtx_Bind
    PROCEDURE, PUBLIC :: Valid => MatCtx_Valid
    PROCEDURE, PUBLIC :: GetCtx => MatCtx_GetCtx
    PROCEDURE, PUBLIC :: GetRes => MatCtx_GetRes
    PROCEDURE, PUBLIC :: GetDesc => MatCtx_GetDesc
    PROCEDURE, PUBLIC :: GetSta => MatCtx_GetSta
    PROCEDURE, PUBLIC :: GetAlgo => MatCtx_GetAlgo
  END TYPE MD_Material_Ctx

  TYPE, PUBLIC :: ExpDataPt
    REAL(wp) :: strain = 0.0_wp
    REAL(wp) :: stress = 0.0_wp
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: weight = 1.0_wp
  END TYPE ExpDataPt

  TYPE, PUBLIC :: ExpDataSet
    INTEGER(i4) :: n_points = 0_i4
    TYPE(ExpDataPt), ALLOCATABLE :: data(:)
    CHARACTER(len=64) :: test_type = ""
  END TYPE ExpDataSet

  TYPE, PUBLIC :: MatParamId
    LOGICAL :: is_initialized = .FALSE.
    TYPE(ExpDataSet) :: exp_data
    REAL(wp), ALLOCATABLE :: param_lower(:)
    REAL(wp), ALLOCATABLE :: param_upper(:)
    REAL(wp), ALLOCATABLE :: param_initial(:)
    REAL(wp), ALLOCATABLE :: param_identifie(:)
    REAL(wp) :: fit_error = 0.0_wp
    INTEGER(i4) :: method = 1_i4
    INTEGER(i4) :: max_iterations = 1000_i4
    REAL(wp) :: tolerance = 1.0e-6_wp
  END TYPE MatParamId

  PUBLIC :: MD_MatDesc, MD_MatDesc_SyncDeprecatedFlat
  PUBLIC :: MD_Mat_Cfg_Init_Desc, MD_Mat_Pop_Vld_Desc
  PUBLIC :: MD_MatModel, Desc_MaterialModel, State_IntPoint
  PUBLIC :: MatCtxLegacy, MatRes, MatFlags, MatProps
  PUBLIC :: MD_MAT_UMAT_Intf, MD_MAT_UMAT_Input, MD_MAT_UMAT_Output
  PUBLIC :: MD_MatMeta, MatReg, MatInst, MatPoolMgr, MatOri, MatPropValid
  PUBLIC :: MD_Material_Ctx, MD_Material_Desc, MD_MaterialEntry
  PUBLIC :: MD_Mat_Base_Desc, MD_Mat_Base_Algo, MD_Mat_Base_State
  PUBLIC :: MD_MatState, MD_MatSta, MD_MatCtx, MD_MatAlgo, MD_MatPointSta
  PUBLIC :: MD_ElasticMatDesc, MD_PlasticMatDesc, MD_HyperElasticMatDesc
  PUBLIC :: MD_DamageMatDesc, MD_PronyMatDesc, MD_CompositeMatDesc, MD_MatModelDesc
  PUBLIC :: ExpDataPt, ExpDataSet, MatParamId
  PUBLIC :: MATERIAL_DESC_I, MATERIAL_ST_ID, g_material_id
  PUBLIC :: DP_MatDesc

CONTAINS

'''

    footer_types_impl = r'''
  SUBROUTINE MD_MatDesc_SyncDeprecatedFlat(this)
    CLASS(MD_MatDesc), INTENT(INOUT) :: this
    this%id = this%cfg%id
    this%materialType = this%cfg%materialType
    this%class_id = this%cfg%class_id
    this%nProps = this%pop%nProps
    this%nStateV = this%pop%nStateV
    this%behavior = this%cfg%behavior
    this%description = this%cfg%description
  END SUBROUTINE MD_MatDesc_SyncDeprecatedFlat

  SUBROUTINE MD_MatDesc_Init_Base(this)
    CLASS(MD_MatDesc), INTENT(INOUT) :: this
    CALL DescBase_Init(this)
    this%algo_type_name = "DESC::Mat"
  END SUBROUTINE MD_MatDesc_Init_Base

  SUBROUTINE MD_MatDesc_Init(this, id, name, materialType, class_id, nProps, nStateV, behavior, description)
    CLASS(MD_MatDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id, class_id, nProps, nStateV
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, materialType, behavior, description
    CALL MD_MatDesc_Init_Base(this)
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(materialType)) this%cfg%materialType = materialType
    IF (PRESENT(class_id)) this%cfg%class_id = class_id
    IF (PRESENT(nProps)) THEN
      this%pop%nProps = nProps
      IF (nProps > 0_i4 .AND. .NOT. ALLOCATED(this%props)) THEN
        ALLOCATE(this%props(nProps))
        this%props = 0.0_wp
      END IF
    END IF
    IF (PRESENT(nStateV)) this%pop%nStateV = nStateV
    IF (PRESENT(behavior)) this%cfg%behavior = behavior
    IF (PRESENT(description)) this%cfg%description = description
    CALL MD_MatDesc_SyncDeprecatedFlat(this)
    this%is_initialized = .TRUE.
  END SUBROUTINE MD_MatDesc_Init

  SUBROUTINE MD_MatDesc_Destroy(this)
    CLASS(MD_MatDesc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    CALL DescBase_Destroy(this)
  END SUBROUTINE MD_MatDesc_Destroy

  SUBROUTINE MD_MatDesc_RegLayout(this)
    CLASS(MD_MatDesc), INTENT(INOUT) :: this
    MARK_UNUSED(this)
  END SUBROUTINE MD_MatDesc_RegLayout

  SUBROUTINE MD_MatDesc_Ensure(this)
    CLASS(MD_MatDesc), INTENT(INOUT) :: this
    MARK_UNUSED(this)
  END SUBROUTINE MD_MatDesc_Ensure

  FUNCTION MD_MatDesc_Valid_Fn(this) RESULT(ok)
    CLASS(MD_MatDesc), INTENT(IN) :: this
    LOGICAL :: ok
    ok = (this%cfg%id >= 0_i4)
    MARK_UNUSED(this)
  END FUNCTION MD_MatDesc_Valid_Fn

  SUBROUTINE MD_MatState_Init_Base(this)
    CLASS(MD_MatState), INTENT(INOUT) :: this
    CALL StateBase_Init(this)
    this%algo_type_name = "STATE::Mat"
  END SUBROUTINE MD_MatState_Init_Base

  SUBROUTINE MD_MatState_Destroy(this)
    CLASS(MD_MatState), INTENT(INOUT) :: this
    IF (ALLOCATED(this%stress)) DEALLOCATE(this%stress)
    IF (ALLOCATED(this%strain)) DEALLOCATE(this%strain)
    IF (ALLOCATED(this%stateV)) DEALLOCATE(this%stateV)
    CALL StateBase_Destroy(this)
  END SUBROUTINE MD_MatState_Destroy

  SUBROUTINE MD_MatMeta_ValidateProps(this, nprops, nstatev, status)
    CLASS(MD_MatMeta), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: nprops, nstatev
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(nprops)
    MARK_UNUSED(nstatev)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_MatMeta_ValidateProps

  SUBROUTINE MatReg_Init(this, MD_MAT_MAX_MATS, status)
    CLASS(MatReg), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: MD_MAT_MAX_MATS
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%MD_MAT_MAX_MATS = MD_MAT_MAX_MATS
    IF (ALLOCATED(this%materials)) DEALLOCATE(this%materials)
    ALLOCATE(this%materials(MD_MAT_MAX_MATS))
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatReg_Init

  SUBROUTINE MatReg_Clean(this)
    CLASS(MatReg), INTENT(INOUT) :: this
    IF (ALLOCATED(this%materials)) DEALLOCATE(this%materials)
    this%nMats = 0_i4
    this%is_initialized = .FALSE.
  END SUBROUTINE MatReg_Clean

  SUBROUTINE MatReg_RegisterMaterial(this, material_id, name, description, category, status)
    CLASS(MatReg), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: material_id, category
    CHARACTER(len=*), INTENT(IN) :: name, description
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(material_id)
    MARK_UNUSED(name)
    MARK_UNUSED(description)
    MARK_UNUSED(category)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatReg_RegisterMaterial

  SUBROUTINE MatReg_GetMaterial(this, material_id, metadata, status)
    CLASS(MatReg), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(MD_MatMeta), INTENT(OUT) :: metadata
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(material_id)
    MARK_UNUSED(metadata)
    status%status_code = MD_MAT_STATUS_NOT_FOUND
  END SUBROUTINE MatReg_GetMaterial

  SUBROUTINE MatReg_FindMaterial(this, name, material_id, status)
    CLASS(MatReg), INTENT(IN) :: this
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(OUT) :: material_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(name)
    material_id = 0_i4
    status%status_code = MD_MAT_STATUS_NOT_FOUND
  END SUBROUTINE MatReg_FindMaterial

  SUBROUTINE MatReg_ListMaterials(this, material_ids, material_names, nFound, status)
    CLASS(MatReg), INTENT(IN) :: this
    INTEGER(i4), INTENT(OUT) :: material_ids(:)
    CHARACTER(len=*), INTENT(OUT) :: material_names(:)
    INTEGER(i4), INTENT(OUT) :: nFound
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(material_ids)
    MARK_UNUSED(material_names)
    nFound = 0_i4
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatReg_ListMaterials

  SUBROUTINE MatReg_ValidateProps(this, material_id, nprops, nstatev, status)
    CLASS(MatReg), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: material_id, nprops, nstatev
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(material_id)
    MARK_UNUSED(nprops)
    MARK_UNUSED(nstatev)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatReg_ValidateProps

  FUNCTION MatReg_GetCategoryName(this, category) RESULT(name)
    CLASS(MatReg), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: category
    CHARACTER(len=80) :: name
    MARK_UNUSED(this)
    WRITE (name, '("CAT",I0)') category
  END FUNCTION MatReg_GetCategoryName

  SUBROUTINE MatInst_Init(this, instance_id, material_id, name, metadata, nprops, nstatev, status)
    CLASS(MatInst), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: instance_id, material_id, nprops, nstatev
    CHARACTER(len=*), INTENT(IN) :: name
    TYPE(MD_MatMeta), INTENT(IN) :: metadata
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%instance_id = instance_id
    this%material_id = material_id
    this%name = name
    this%metadata = metadata
    this%nprops = nprops
    this%nstatev = nstatev
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatInst_Init

  SUBROUTINE MatInst_Clean(this)
    CLASS(MatInst), INTENT(INOUT) :: this
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    IF (ALLOCATED(this%statev_initial)) DEALLOCATE(this%statev_initial)
  END SUBROUTINE MatInst_Clean

  SUBROUTINE MatInst_SetProps(this, props, status)
    CLASS(MatInst), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(props)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatInst_SetProps

  SUBROUTINE MatInst_GetProps(this, props, status)
    CLASS(MatInst), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    props = 0.0_wp
    MARK_UNUSED(this)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatInst_GetProps

  SUBROUTINE MatInst_Valid(this, status)
    CLASS(MatInst), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatInst_Valid

  SUBROUTINE MatPoolMgr_Init(this, max_instances, status)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: max_instances
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%max_instances = max_instances
    IF (ALLOCATED(this%instances)) DEALLOCATE(this%instances)
    ALLOCATE(this%instances(max_instances))
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_Init

  SUBROUTINE MatPoolMgr_Clean(this)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    IF (ALLOCATED(this%instances)) DEALLOCATE(this%instances)
    this%is_initialized = .FALSE.
  END SUBROUTINE MatPoolMgr_Clean

  SUBROUTINE MatPoolMgr_CreateInst(this, material_id, name, props, instance_id, status)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: material_id
    CHARACTER(len=*), INTENT(IN) :: name
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(OUT) :: instance_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(material_id)
    MARK_UNUSED(name)
    MARK_UNUSED(props)
    instance_id = 0_i4
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_CreateInst

  SUBROUTINE MatPoolMgr_GetInst(this, instance_id, instance, status)
    CLASS(MatPoolMgr), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: instance_id
    TYPE(MatInst), INTENT(OUT) :: instance
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(instance_id)
    MARK_UNUSED(instance)
    status%status_code = MD_MAT_STATUS_NOT_FOUND
  END SUBROUTINE MatPoolMgr_GetInst

  SUBROUTINE MatPoolMgr_RemoveInst(this, instance_id, status)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: instance_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(instance_id)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_RemoveInst

  SUBROUTINE MatPoolMgr_UpdateInst(this, instance_id, props, status)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: instance_id
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(instance_id)
    MARK_UNUSED(props)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_UpdateInst

  SUBROUTINE MatPoolMgr_ListInsts(this, instance_ids, material_ids, names, nFound, status)
    CLASS(MatPoolMgr), INTENT(IN) :: this
    INTEGER(i4), INTENT(OUT) :: instance_ids(:), material_ids(:)
    CHARACTER(len=*), INTENT(OUT) :: names(:)
    INTEGER(i4), INTENT(OUT) :: nFound
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    MARK_UNUSED(this)
    MARK_UNUSED(instance_ids)
    MARK_UNUSED(material_ids)
    MARK_UNUSED(names)
    nFound = 0_i4
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_ListInsts

  FUNCTION MatPoolMgr_GetReg(this) RESULT(registry)
    CLASS(MatPoolMgr), INTENT(IN) :: this
    TYPE(MatReg) :: registry
    registry = this%registry
  END FUNCTION MatPoolMgr_GetReg

  SUBROUTINE MatOri_Init(this)
    CLASS(MatOri), INTENT(INOUT) :: this
    this%isSet = .FALSE.
  END SUBROUTINE MatOri_Init

  FUNCTION MatOri_GetRotMat(this) RESULT(rm)
    CLASS(MatOri), INTENT(IN) :: this
    REAL(wp) :: rm(3, 3)
    rm = this%rotationMatrix
    MARK_UNUSED(this)
  END FUNCTION MatOri_GetRotMat

  SUBROUTINE MatPropValid_Init(this)
    CLASS(MatPropValid), INTENT(INOUT) :: this
    this%isValid = .TRUE.
  END SUBROUTINE MatPropValid_Init

  SUBROUTINE MatPropValid_SetPropRange(this, idx, minVal, maxVal, required)
    CLASS(MatPropValid), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: idx
    REAL(wp), INTENT(IN) :: minVal, maxVal
    LOGICAL, INTENT(IN) :: required
    MARK_UNUSED(this)
    MARK_UNUSED(idx)
    MARK_UNUSED(minVal)
    MARK_UNUSED(maxVal)
    MARK_UNUSED(required)
  END SUBROUTINE MatPropValid_SetPropRange

  FUNCTION MatPropValid_Valid(this) RESULT(ok)
    CLASS(MatPropValid), INTENT(IN) :: this
    LOGICAL :: ok
    ok = this%isValid
  END FUNCTION MatPropValid_Valid

  FUNCTION MatPropValid_GetErrMsg(this) RESULT(msg)
    CLASS(MatPropValid), INTENT(IN) :: this
    CHARACTER(len=256) :: msg
    msg = this%errorMessage
  END FUNCTION MatPropValid_GetErrMsg

END MODULE MD_Mat_Def
'''

    # MARK_UNUSED macro as contained subroutine - use Fortran 2003: no macro; use explicit if (.false.)
    # Replace MARK_UNUSED(x) with pattern that compiles
    footer_types_impl = footer_types_impl.replace(
        "MARK_UNUSED(this)",
        "IF (.FALSE.) PRINT *, this%cfg%id",
    )
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(nprops)", "IF (.FALSE.) PRINT *, nprops")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(nstatev)", "IF (.FALSE.) PRINT *, nstatev")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(name)", "IF (.FALSE.) PRINT *, LEN_TRIM(name)")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(material_id)", "IF (.FALSE.) PRINT *, material_id")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(description)", "IF (.FALSE.) PRINT *, LEN_TRIM(description)")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(category)", "IF (.FALSE.) PRINT *, category")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(metadata)", "IF (.FALSE.) PRINT *, metadata%material_id")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(material_ids)", "IF (.FALSE.) PRINT *, SIZE(material_ids)")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(material_names)", "IF (.FALSE.) PRINT *, LEN(material_names)")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(props)", "IF (.FALSE.) PRINT *, SIZE(props)")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(instance)", "IF (.FALSE.) PRINT *, instance%instance_id")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(instance_ids)", "IF (.FALSE.) PRINT *, SIZE(instance_ids)")
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(instance_id)", "IF (.FALSE.) PRINT *, instance_id")

    # Fix invalid MARK_UNUSED left
    footer_types_impl = footer_types_impl.replace("MARK_UNUSED(x)", "IF (.FALSE.) CONTINUE")

    text = header + "\n" + frag + "\n" + footer_types_impl
    if "\x00" in text:
        raise SystemExit("NUL in output")
    tmp = OUT.with_suffix(".f90.tmp")
    tmp.write_text(text, encoding="utf-8", newline="\n")
    tmp.replace(OUT)
    print("Wrote", OUT, "chars", len(text))


if __name__ == "__main__":
    main()
