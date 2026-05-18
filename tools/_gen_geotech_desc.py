# Historical one-shot: sliced DP/MC from legacy monolithic L3 plastic .f90 into Geotech Desc.
#
# After strip (DP/MC live only in Geotech), the line ranges below are STALE.
# Do not run unless you point `p` at an archival snapshot and re-measure slices.
# Source of truth: L3_MD/Material/PLG/MD_Mat_Plast_Geotech_Desc.f90
import pathlib

p = pathlib.Path(__file__).resolve().parents[1] / "L3_MD/Material/Dispatch/PLM/MD_Mat_PLM_PlastBase.f90"
L = p.read_text(encoding="utf-8", errors="replace").splitlines(True)

body_dp = "".join(L[2775:3145])
body_mc_a = "".join(L[3325:3464])
body_mc_b = "".join(L[3486:3648])

fixes = [
    ("SUBROUTINE Dr_Clear(this)", "SUBROUTINE DPProperties_Clear(this)"),
    ("SUBROUTINE Dr_Add(this, prop, status)", "SUBROUTINE DPPropertiesManager_Add(this, prop, status)"),
    (
        "SUBROUTINE Dr_Clear(this)\n        CLASS(DPPropertiesManager)",
        "SUBROUTINE DPPropertiesManager_Clear(this)\n        CLASS(DPPropertiesManager)",
    ),
    ("SUBROUTINE Mo_Add(this, prop, status)", "SUBROUTINE MCPropertiesManager_Add(this, prop, status)"),
    ("SUBROUTINE Mo_Clear(this)", "SUBROUTINE MCPropertiesManager_Clear(this)"),
]


def fix(s: str) -> str:
    for a, b in fixes:
        s = s.replace(a, b)
    return s


body_dp = fix(body_dp)
body_mc_a = fix(body_mc_a)

header = """! ======================================================================
! Module  : MD_MAT_PLG_GEOTECH_DESC
! Layer   : L3_MD / Material / Geotech
! Purpose : Drucker-Prager & Mohr-Coulomb keyword Desc types + parsers
!           (split from legacy monolithic L3 plastic registry).
! ======================================================================
MODULE MD_MAT_PLG_GEOTECH_DESC
    USE IF_ERR_API, ONLY: ErrorStatusType, STATUS_INVALID, STATUS_OK, &
        init_error_status, uf_set_error
    USE IF_PREC, ONLY: i4, wp
    USE MD_BASE_OBJMODEL_CORE, ONLY: DescBase, DescBase_Init, UF_Model
    USE MD_KW_TYPES, ONLY: KW_ASTNodeType, KW_MAX_NAME_LEN, KW_MAX_VALUE_LEN
    IMPLICIT NONE
    PRIVATE

"""

mid = """
    !=============================================================================
    ! Drucker-Prager Properties Manager
    !=============================================================================
    TYPE, PUBLIC :: DPPropertiesManager
        INTEGER(i4) :: numProperties = 0_i4
        TYPE(DPProperties), ALLOCATABLE :: properties(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add => DPPropertiesManager_Add
        PROCEDURE, PUBLIC :: Find => DPPropertiesManager_Find
        PROCEDURE, PUBLIC :: Clear => DPPropertiesManager_Clear
    END TYPE DPPropertiesManager

    TYPE, PUBLIC, EXTENDS(DPProperties) :: DruckerPragerProperties
    END TYPE DruckerPragerProperties

    PUBLIC :: DPProperties, DruckerPragerProperties, DPPropertiesManager
    PUBLIC :: DP_SHEAR_LINEAR, DP_SHEAR_HYPERBOLIC, DP_SHEAR_EXPONENT
    PUBLIC :: MD_Mat_DruckerPrager_Unified_Configure
    PUBLIC :: MD_Mat_DruckerPrager_Unified_Parse
    PUBLIC :: Parse_DRUCKER_PRAGER_Keyword
    PUBLIC :: Valid_DRUCKER_PRAGER_Keyword
    PUBLIC :: Valid_DRUCKER_PRAGER_Mat
    PUBLIC :: Validate_DRUCKER_PRAGER_PhysicalValues

    ! --- from MD_MAT_MC ---
"""

mc_tail = """
    TYPE, PUBLIC :: MCPropertiesManager
        INTEGER(i4) :: numProperties = 0_i4
        TYPE(MCProperties), ALLOCATABLE :: properties(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add => MCPropertiesManager_Add
        PROCEDURE, PUBLIC :: Find => MCPropertiesManager_Find
        PROCEDURE, PUBLIC :: Clear => MCPropertiesManager_Clear
    END TYPE MCPropertiesManager

    TYPE, PUBLIC, EXTENDS(MCProperties) :: MohrCoulombProperties
    END TYPE MohrCoulombProperties

    PUBLIC :: MCProperties, MohrCoulombProperties, MCPropertiesManager
    PUBLIC :: MD_Mat_MohrCoulomb_Unified_Configure
    PUBLIC :: MD_Mat_MohrCoulomb_Unified_Parse
    PUBLIC :: Parse_MOHR_COULOMB_Keyword
    PUBLIC :: Valid_MOHR_COULOMB_Keyword
    PUBLIC :: Valid_MOHR_COULOMB_Mat
    PUBLIC :: Validate_MOHR_COULOMB_PhysicalValues

CONTAINS

"""

dp_lines = L[183:219]
dp_body = "".join(dp_lines).rstrip()
dp_type = (
    "    ! --- from MD_MAT_DP ---\n"
    + dp_body
    + "\n"
    + "    CONTAINS\n"
    + "        PROCEDURE, PUBLIC :: Init => DPProperties_Init_Base\n"
    + "        PROCEDURE, PUBLIC :: Valid => DPProperties_Valid_Fn\n"
    + "        PROCEDURE, PUBLIC :: Clear => DPProperties_Clear\n"
    + "        PROCEDURE, PUBLIC :: ComputeYieldFunction => DPProperties_ComputeYieldFunction\n"
    + "    END TYPE DPProperties\n\n"
)

mc_lines = L[242:261]
mc_body = "".join(mc_lines).rstrip()
mc_type = (
    mc_body
    + "\n"
    + "    CONTAINS\n"
    + "        PROCEDURE, PUBLIC :: Init => MCProperties_Init_Base\n"
    + "        PROCEDURE, PUBLIC :: Valid => MCProperties_Valid_Fn\n"
    + "        PROCEDURE, PUBLIC :: Clear => MCProperties_Clear\n"
    + "        PROCEDURE, PUBLIC :: ComputeYieldFunction => MCProperties_ComputeYieldFunction\n"
    + "    END TYPE MCProperties\n\n"
)

out = (
    header
    + dp_type
    + mid
    + mc_type
    + mc_tail
    + body_dp
    + body_mc_a
    + body_mc_b
    + "\nEND MODULE MD_MAT_PLG_GEOTECH_DESC\n"
)

outp = pathlib.Path(__file__).resolve().parents[1] / "L3_MD/Material/PLG/MD_Mat_Plast_Geotech_Desc.f90"
outp.write_text(out, encoding="utf-8")
print("written", outp, "len", len(out))
