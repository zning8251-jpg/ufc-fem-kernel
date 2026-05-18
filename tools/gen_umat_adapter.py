#!/usr/bin/env python3
"""
gen_umat_adapter.py — Generate UFC ABAQUS Adapter Files from Parameter Mapping

Reads ABAQUS Subroutine → UFC TYPE mapping data and generates Fortran
adapter files using Jinja2 templates.  Each adapter:
  1. Packs ABAQUS flat params → UFC TYPE structs
  2. Calls UFC native interface
  3. Unpacks results → ABAQUS flat arrays

Reference: docs/05_Project_Planning/PPLAN/06_核心架构/ABAQUS_Subroutine_UFC_TYPE_Mapping.md

Usage:
  # Generate all adapters
  python gen_umat_adapter.py --all

  # Generate specific group
  python gen_umat_adapter.py --group material
  python gen_umat_adapter.py --group element
  python gen_umat_adapter.py --group load
  python gen_umat_adapter.py --group bc
  python gen_umat_adapter.py --group contact
  python gen_umat_adapter.py --group constraint
  python gen_umat_adapter.py --group field
  python gen_umat_adapter.py --group analysis

  # Dry-run (print to stdout)
  python gen_umat_adapter.py --all --dry-run

  # Specify output directory
  python gen_umat_adapter.py --all --output ../ufc_core/L4_PH/Adapters/

Exit codes:
  0  — success
  1  — usage error
  2  — template not found
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path

# ── Try Jinja2; fall back to simple string-template if unavailable ──
try:
    from jinja2 import Environment, FileSystemLoader, select_autoescape

    _JINJA2_AVAILABLE = True
except ImportError:
    _JINJA2_AVAILABLE = False

# ── Root of this script ────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
TOOLS_DIR = SCRIPT_DIR.parent
TEMPLATE_DIR = SCRIPT_DIR / "gen_adapters" / "templates"
OUTPUT_BASE = TOOLS_DIR.parent / "ufc_core" / "L4_PH" / "Adapters"

# ─────────────────────────────────────────────────────────────────────────
#  SUBROUTINE DEFINITIONS
#  data structure per subroutine:
#    name          : ABAQUS subroutine name
#    group         : material|element|load|bc|contact|constraint|field|analysis
#    section       : section number in mapping doc
#    template      : Jinja2 template filename
#    module_name   : UFC module name (without _Mod suffix)
#    core_proc     : UFC native procedure to call
#    ufc_domain    : L4_PH domain name
#    parameters    : list of {abaqus_param, intent, array_dims, fortran_type,
#                              ufc_type, ufc_field, direction}
# ─────────────────────────────────────────────────────────────────────────

P = lambda abaqus, intent, dims, ftype, ufc_type, ufc_field, direction="": {
  "abaqus_param": abaqus,
  "intent": intent,
  "array_dims": dims,
  "fortran_type": ftype,
  "ufc_type": ufc_type,
  "ufc_field": ufc_field,
  "direction": direction,
}

ALL_SUBROUTINES: list[dict] = [

  # ═══════════════════════════════════════════════════════════════════════════
  #  §2  MATERIAL CONSTITUTIVE  (15 subroutines)
  # ═══════════════════════════════════════════════════════════════════════════

  {
    "name": "UMAT",
    "group": "material",
    "section": "2",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Mat_UMAT",
    "core_proc": "PH_Mat_UMAT_API",
    "ufc_domain": "Material",
    "parameters": [
      P("STRESS", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%stress(1:ntens)", "[IN/OUT]"),
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("DDSDDE", "OUT", 2, "REAL(wp)", "PH_Mat_Base_State", "state%ddsdde(1:ntens,1:ntens)", "[OUT]"),
      P("SSE", "INOUT", 0, "REAL(wp)", "PH_Mat_Base_State", "state%sse", "[IN/OUT]"),
      P("SPD", "INOUT", 0, "REAL(wp)", "PH_Mat_Base_State", "state%spd", "[IN/OUT]"),
      P("SCD", "INOUT", 0, "REAL(wp)", "PH_Mat_Base_State", "state%scd", "[IN/OUT]"),
      P("RPL", "INOUT", 0, "REAL(wp)", "PH_Mat_Base_State", "state%rpl", "[IN/OUT]"),
      P("DDSDDT", "OUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%ddsddt(1:ntens)", "[OUT]"),
      P("DRPLDE", "OUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%drplde(1:ntens)", "[OUT]"),
      P("DRPLDT", "OUT", 0, "REAL(wp)", "PH_Mat_Base_State", "state%drpldt", "[OUT]"),
      P("STRAN", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%stran(1:ntens)", "[IN]"),
      P("DSTRAN", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dstran(1:ntens)", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtime", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%temp", "[IN]"),
      P("DTEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtemp", "[IN]"),
      P("PREDEF", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%predef(1:npredf)", "[IN]"),
      P("DPRED", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dpred(1:npredf)", "[IN]"),
      P("CMNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Mat_Base_Desc", "desc%model_name", "[IN]"),
      P("NDI", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%ndi", "[IN]"),
      P("NSHR", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nshr", "[IN]"),
      P("NTENS", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%ntens", "[IN]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("DROT", "IN", 2, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%drot(1:3,1:3)", "[IN]"),
      P("PNEWDT", "OUT", 0, "REAL(wp)", "PH_Mat_Base_State", "state%pnewdt", "[OUT]"),
      P("CELENT", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%celent", "[IN]"),
      P("DFGRD0", "IN", 2, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dfgrd0(1:3,1:3)", "[IN]"),
      P("DFGRD1", "IN", 2, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dfgrd1(1:3,1:3)", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("LAYER", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%layer", "[IN]"),
      P("KSPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kspt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "VUMAT",
    "group": "material",
    "section": "2",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Mat_VUMAT",
    "core_proc": "PH_Mat_VUMAT_API",
    "ufc_domain": "Material",
    "parameters": [
      P("STRESS", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%stress(1:ntens)", "[IN/OUT]"),
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("NSTATEV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NFIELDS", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nfields", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("DSTRAN", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dstran(1:ntens)", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtime", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%temp", "[IN]"),
      P("DTEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtemp", "[IN]"),
      P("PREDEF", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%predef(1:npredf)", "[IN]"),
      P("DPRED", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dpred(1:npredf)", "[IN]"),
      P("CMNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Mat_Base_Desc", "desc%model_name", "[IN]"),
      P("NDI", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%ndi", "[IN]"),
      P("NSHR", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nshr", "[IN]"),
      P("NTENS", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%ntens", "[IN]"),
      P("NUMINT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("NLAYER", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%layer", "[IN]"),
      P("KSPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kspt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "UMATHT",
    "group": "material",
    "section": "2",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Mat_UMATHT",
    "core_proc": "PH_Mat_UMATHT_API",
    "ufc_domain": "Material",
    "parameters": [
      P("FLUX", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%flux(1:3)", "[IN/OUT]"),
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%temp", "[IN]"),
      P("DTEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtemp", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtime", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "CREEP",
    "group": "material",
    "section": "2",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Mat_CREEP",
    "core_proc": "PH_Mat_CREEP_API",
    "ufc_domain": "Material",
    "parameters": [
      P("ECR", "OUT", 0, "REAL(wp)", "PH_Mat_Base_State", "state%creep_strain", "[OUT]"),
      P("DECR", "OUT", 0, "REAL(wp)", "PH_Mat_Base_State", "state%creep_rate", "[OUT]"),
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtime", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%temp", "[IN]"),
      P("DTEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtemp", "[IN]"),
      P("TRESCA", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%stress_eq", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("KSPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kspt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "UHARD",
    "group": "material",
    "section": "2",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Mat_UHARD",
    "core_proc": "PH_Mat_UHARD_API",
    "ufc_domain": "Material",
    "parameters": [
      P("YIELD", "OUT", 0, "REAL(wp)", "PH_Mat_Base_State", "state%yield_stress", "[OUT]"),
      P("DYIELD", "OUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%yield_hardening(1:2)", "[OUT]"),
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("EQSTRAIN", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%eq_plastic_strain", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%temp", "[IN]"),
      P("DTEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtemp", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "UHYPER",
    "group": "material",
    "section": "2",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Mat_UHYPER",
    "core_proc": "PH_Mat_UHYPER_API",
    "ufc_domain": "Material",
    "parameters": [
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("STRETCH", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%stretch", "[IN]"),
      P("DTEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtemp", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "UMULLINS",
    "group": "material",
    "section": "2",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Mat_UMULLINS",
    "core_proc": "PH_Mat_UMULLINS_API",
    "ufc_domain": "Material",
    "parameters": [
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("STRMAX", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%max_stretch_ratio", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%temp", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  # ── Fields / SDV subroutines (shared between material & field domains) ──
  {
    "name": "USDFLD",
    "group": "field",
    "section": "8",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Field_USDFLD",
    "core_proc": "PH_Field_USDFLD_API",
    "ufc_domain": "Field",
    "parameters": [
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtime", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%temp", "[IN]"),
      P("DTEMP", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtemp", "[IN]"),
      P("PREDEF", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%predef(1:npredf)", "[IN]"),
      P("DPRED", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dpred(1:npredf)", "[IN]"),
      P("CMNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Mat_Base_Desc", "desc%model_name", "[IN]"),
      P("NDI", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%ndi", "[IN]"),
      P("NSHR", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nshr", "[IN]"),
      P("NTENS", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%ntens", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "SDVINI",
    "group": "field",
    "section": "8",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Field_SDVINI",
    "core_proc": "PH_Field_SDVINI_API",
    "ufc_domain": "Field",
    "parameters": [
      P("STATEV", "OUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%statev(1:nstatv)", "[OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "SIGINI",
    "group": "field",
    "section": "8",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Field_SIGINI",
    "core_proc": "PH_Field_SIGINI_API",
    "ufc_domain": "Field",
    "parameters": [
      P("STRESS", "OUT", 1, "REAL(wp)", "PH_Mat_Base_State", "state%stress(1:ntens)", "[OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Mat_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Mat_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  # ═══════════════════════════════════════════════════════════════════════════
  #  §3  USER ELEMENTS  (3 subroutines)
  # ═══════════════════════════════════════════════════════════════════════════

  {
    "name": "UEL",
    "group": "element",
    "section": "3",
    "template": "uel_adapter.f90.j2",
    "module_name": "PH_Elem_UEL",
    "core_proc": "PH_Elem_UEL_API",
    "ufc_domain": "Element",
    "parameters": [
      P("RHS", "OUT", 2, "REAL(wp)", "PH_Elem_Base_State", "elem_state_out%rhs(1:ndofel,1:nrhs)", "[OUT]"),
      P("AMATRX", "OUT", 2, "REAL(wp)", "PH_Elem_Base_State", "elem_state_out%amatrx(1:ndofel,1:ndofel)", "[OUT]"),
      P("SVARS", "INOUT", 1, "REAL(wp)", "MD_Elem_State", "elem_state%svars(1:nsvars)", "[IN/OUT]"),
      P(" ENERGY", "OUT", 1, "REAL(wp)", "PH_Elem_Base_State", "elem_state_out%energy(1:8)", "[OUT]"),
      P("JDLTYP", "IN", 1, "INTEGER(i4)", "MD_Elem_Desc", "elem_desc%jdltyp(1:njprop)", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%kinc", "[IN]"),
      P("JELEM", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%elem_id", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%step_time/elem_ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%dtime", "[IN]"),
      P("NODE", "IN", 1, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%node_ids(1:nnode)", "[IN]"),
      P("JDOF", "IN", 1, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%dof_map(1:ndofel)", "[IN]"),
      P("JTYPE", "IN", 0, "INTEGER(i4)", "MD_Elem_Desc", "elem_desc%jtype", "[IN]"),
      P("NNODE", "IN", 0, "INTEGER(i4)", "MD_Elem_Desc", "elem_desc%nnode", "[IN]"),
      P("NDOFEL", "IN", 0, "INTEGER(i4)", "MD_Elem_Desc", "elem_desc%ndofel", "[IN]"),
      P("NRHS", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%nrhs", "[IN]"),
      P("NSYMM", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%nsymm", "[IN]"),
      P("MLVARX", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%mlvarx", "[IN]"),
      P("NDLOAD", "IN", 0, "INTEGER(i4)", "MD_Elem_Desc", "elem_desc%ndload", "[IN]"),
      P("JDLTYP", "IN", 1, "INTEGER(i4)", "MD_Elem_Desc", "elem_desc%jdltyp(1:ndload)", "[IN]"),
      P("PERIOD", "IN", 0, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%period", "[IN]"),
      P("LFLAGS", "IN", 1, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%lflags(1:6)", "[IN]"),
      P("JPROPS", "IN", 1, "INTEGER(i4)", "MD_Elem_Desc", "elem_desc%jprops(1:njprop)", "[IN]"),
      P("NJPROP", "IN", 0, "INTEGER(i4)", "MD_Elem_Desc", "elem_desc%njprop", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Elem_Desc", "elem_desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Elem_Desc", "elem_desc%props(1:nprops)", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%coords_1d(1:3*nnode)", "[IN]"),
      P("NTENS", "IN", 0, "INTEGER(i4)", "MD_Elem_Algo", "elem_desc%ntens", "[IN]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "MD_Elem_State", "elem_state%nstatv", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%gauss_pt", "[IN]"),
      P("KSPT", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%kspt", "[IN]"),
      P("KSPG", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%kspg", "[IN]"),
      P("NLAYER", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%nlayer", "[IN]"),
      P("NPTT", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%npTT", "[IN]"),
      P("JSTEP", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%jstep", "[IN]"),
      P("JINCR", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%jincr", "[IN]"),
      P("QUERY", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%query_flag", "[IN]"),
      P("V", "IN", 1, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%v(1:ndofel)", "[IN]"),
      P("U", "IN", 1, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%u(1:ndofel)", "[IN]"),
      P("DU", "IN", 1, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%du(1:ndofel)", "[IN]"),
      P("A", "IN", 1, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%a(1:ndofel)", "[IN]"),
      P("PREDEF", "IN", 1, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%predef_ip(1:npredf,1:2)", "[IN]"),
      P("DPRED", "IN", 1, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%dpred_ip(1:npredf)", "[IN]"),
      P("CMAUR", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%cmaur", "[IN]"),
      P("NDLJD", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%ndljd", "[IN]"),
      P("MDLtyp", "IN", 1, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%mdltyp(1:ndljd)", "[IN]"),
      P("JDLJDs", "IN", 1, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%jdljds(1:ndljd)", "[IN]"),
      P("DLJDF", "IN", 1, "REAL(wp)", "PH_Elem_Base_Ctx", "elem_ctx%dljdf(1:mdof,1:nrhs)", "[IN]"),
      P("SNRM", "OUT", 0, "REAL(wp)", "PH_Elem_Base_State", "elem_state_out%norm_rhs", "[OUT]"),
      P("PNEWDT", "INOUT", 0, "REAL(wp)", "PH_Elem_Base_State", "elem_state_out%pnewdt", "[OUT]"),
      P("NFLUX", "IN", 0, "INTEGER(i4)", "PH_Elem_Base_Ctx", "elem_ctx%nflux", "[IN]"),
      P("DKDG", "OUT", 2, "REAL(wp)", "PH_Elem_Base_State", "elem_state_out%dkdg(1:mlvarx,1:mlvarx)", "[OUT]"),
      P("SCON", "OUT", 1, "REAL(wp)", "PH_Elem_Base_State", "elem_state_out%scond(1:nlayer)", "[OUT]"),
    ],
  },

  # ═══════════════════════════════════════════════════════════════════════════
  #  §4  DISTRIBUTED LOADS  (5 subroutines)
  # ═══════════════════════════════════════════════════════════════════════════

  {
    "name": "DLOAD",
    "group": "load",
    "section": "4",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Load_DLOAD",
    "core_proc": "PH_Load_DLOAD_API",
    "ufc_domain": "Load",
    "parameters": [
      P("F", "OUT", 0, "REAL(wp)", "PH_Load_Base_State", "state%load_value", "[OUT]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("DIRECT", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%load_direction(1:3)", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%temp", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("LFTAG", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%load_tag", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Load_Base_Desc", "desc%load_name", "[IN]"),
    ],
  },

  {
    "name": "VDLOAD",
    "group": "load",
    "section": "4",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Load_VDLOAD",
    "core_proc": "PH_Load_VDLOAD_API",
    "ufc_domain": "Load",
    "parameters": [
      P("F", "OUT", 1, "REAL(wp)", "PH_Load_Base_State", "state%load_vector(1:6)", "[OUT]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("DIRECT", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%load_direction(1:3)", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%temp", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("LFTAG", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%load_tag", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Load_Base_Desc", "desc%load_name", "[IN]"),
      P("NVAL", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Algo", "algo%nval", "[IN]"),
    ],
  },

  {
    "name": "CLOAD",
    "group": "load",
    "section": "4",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Load_CLOAD",
    "core_proc": "PH_Load_CLOAD_API",
    "ufc_domain": "Load",
    "parameters": [
      P("F", "OUT", 0, "REAL(wp)", "PH_Load_Base_State", "state%nodal_force", "[OUT]"),
      P("NODE", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%node_id", "[IN]"),
      P("NDOF", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%dof_number", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Load_Base_Desc", "desc%load_name", "[IN]"),
    ],
  },

  {
    "name": "FILM",
    "group": "load",
    "section": "4",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Load_FILM",
    "core_proc": "PH_Load_FILM_API",
    "ufc_domain": "Load",
    "parameters": [
      P("F", "OUT", 0, "REAL(wp)", "PH_Load_Base_State", "state%film_flux", "[OUT]"),
      P("H", "OUT", 0, "REAL(wp)", "PH_Load_Base_State", "state%film_coef", "[OUT]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%temp_surf", "[IN]"),
      P("TEMP0", "IN", 0, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%temp_ref", "[IN]"),
      P("TEMP1", "IN", 0, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%temp_film", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%dtime", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Load_Base_Desc", "desc%film_name", "[IN]"),
    ],
  },

  {
    "name": "HETVAL",
    "group": "load",
    "section": "4",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Load_HETVAL",
    "core_proc": "PH_Load_HETVAL_API",
    "ufc_domain": "Load",
    "parameters": [
      P("RHO", "OUT", 0, "REAL(wp)", "PH_Load_Base_State", "state%heat_gen_rate", "[OUT]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%dtime", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Load_Base_Ctx", "ctx%temp", "[IN]"),
      P("STATEV", "IN", 1, "REAL(wp)", "PH_Load_Base_State", "state%statev(1:nstatv)", "[IN]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Load_Base_Algo", "algo%nstatv", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Load_Base_Desc", "desc%nprops", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Load_Base_Desc", "desc%props(1:nprops)", "[IN]"),
    ],
  },

  # ═══════════════════════════════════════════════════════════════════════════
  #  §5  BOUNDARY CONDITIONS  (3 subroutines)
  # ═══════════════════════════════════════════════════════════════════════════

  {
    "name": "DISP",
    "group": "bc",
    "section": "5",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_BC_DISP",
    "core_proc": "PH_BC_DISP_API",
    "ufc_domain": "BC",
    "parameters": [
      P("U", "OUT", 1, "REAL(wp)", "PH_BC_Base_State", "state%bc_value(1:6)", "[OUT]"),
      P("NODE", "IN", 0, "INTEGER(i4)", "PH_BC_Base_Ctx", "ctx%node_id", "[IN]"),
      P("NDOF", "IN", 0, "INTEGER(i4)", "PH_BC_Base_Ctx", "ctx%dof_number", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_BC_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_BC_Base_Ctx", "ctx%dtime", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_BC_Base_Desc", "desc%bc_name", "[IN]"),
    ],
  },

  {
    "name": "UTEMP",
    "group": "bc",
    "section": "5",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_BC_UTEMP",
    "core_proc": "PH_BC_UTEMP_API",
    "ufc_domain": "BC",
    "parameters": [
      P("UTEMP", "OUT", 0, "REAL(wp)", "PH_BC_Base_State", "state%bc_temp", "[OUT]"),
      P("NODE", "IN", 0, "INTEGER(i4)", "PH_BC_Base_Ctx", "ctx%node_id", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_BC_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_BC_Base_Ctx", "ctx%dtime", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_BC_Base_Desc", "desc%bc_name", "[IN]"),
    ],
  },

  {
    "name": "UPSD",
    "group": "bc",
    "section": "5",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_BC_UPSD",
    "core_proc": "PH_BC_UPSD_API",
    "ufc_domain": "BC",
    "parameters": [
      P("S", "OUT", 1, "REAL(wp)", "PH_BC_Base_State", "state%bc_stress(1:6)", "[OUT]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_BC_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_BC_Base_Desc", "desc%bc_name", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_BC_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_BC_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_BC_Base_Ctx", "ctx%gauss_pt", "[IN]"),
    ],
  },

  # ═══════════════════════════════════════════════════════════════════════════
  #  §6  CONTACT / FRICTION  (6 subroutines)
  # ═══════════════════════════════════════════════════════════════════════════

  {
    "name": "UINTER",
    "group": "contact",
    "section": "6",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Cont_UINTER",
    "core_proc": "PH_Cont_UINTER_API",
    "ufc_domain": "Contact",
    "parameters": [
      P("NDIR", "OUT", 0, "INTEGER(i4)", "PH_Cont_Base_State", "state%nactive", "[OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Algo", "algo%nstatv", "[IN]"),
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Cont_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("U", "IN", 1, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%disp(1:6)", "[IN]"),
      P("V", "IN", 1, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%velocity(1:6)", "[IN]"),
      P("A", "IN", 1, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%accel(1:6)", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%slave_elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%slave_pt_id", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Cont_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Cont_Base_Desc", "desc%nprops", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("DGAM", "INOUT", 0, "REAL(wp)", "PH_Cont_Base_State", "state%dgamma", "[IN/OUT]"),
      P("DDD", "OUT", 2, "REAL(wp)", "PH_Cont_Base_State", "state%dddg(1:3,1:3)", "[OUT]"),
      P("SNAM", "IN", 0, "CHARACTER(LEN=80)", "MD_Cont_Base_Desc", "desc%pair_name", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "UFRIC",
    "group": "contact",
    "section": "6",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Cont_UFRIC",
    "core_proc": "PH_Cont_UFRIC_API",
    "ufc_domain": "Contact",
    "parameters": [
      P("TFRIC", "OUT", 0, "REAL(wp)", "PH_Cont_Base_State", "state%fric_stress", "[OUT]"),
      P("STATF", "OUT", 1, "REAL(wp)", "PH_Cont_Base_State", "state%statev(1:nstatv)", "[OUT]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("SLIP", "IN", 0, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%slip_magnitude", "[IN]"),
      P("SPRESS", "IN", 0, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%contact_pressure", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%temp", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%pt_id", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Fric_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Fric_Base_Desc", "desc%nprops", "[IN]"),
      P("NTENS", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Algo", "algo%ntens", "[IN]"),
      P("STATEV", "INOUT", 1, "REAL(wp)", "PH_Cont_Base_State", "state%statev(1:nstatv)", "[IN/OUT]"),
      P("NSTATV", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Algo", "algo%nstatv", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Fric_Base_Desc", "desc%fric_name", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "GAPCON",
    "group": "contact",
    "section": "6",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Cont_GAPCON",
    "core_proc": "PH_Cont_GAPCON_API",
    "ufc_domain": "Contact",
    "parameters": [
      P("FLOW", "OUT", 0, "REAL(wp)", "PH_Cont_Base_State", "state%gap_flow", "[OUT]"),
      P("DFLOW", "OUT", 0, "REAL(wp)", "PH_Cont_Base_State", "state%dgap_flow", "[OUT]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("TEMP", "IN", 0, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%temp", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Cont_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Cont_Base_Ctx", "ctx%pt_id", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Cont_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Cont_Base_Desc", "desc%nprops", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Cont_Base_Desc", "desc%pair_name", "[IN]"),
    ],
  },

  # ═══════════════════════════════════════════════════════════════════════════
  #  §7  CONSTRAINTS  (3 subroutines)
  # ═══════════════════════════════════════════════════════════════════════════

  {
    "name": "MPC",
    "group": "constraint",
    "section": "7",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Cons_MPC",
    "core_proc": "PH_Cons_MPC_API",
    "ufc_domain": "Constraint",
    "parameters": [
      P("AMATRX", "OUT", 2, "REAL(wp)", "PH_Cons_Base_State", "state%constraint_A(1:ndof,1:ndof)", "[OUT]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Cons_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("NODE", "IN", 1, "INTEGER(i4)", "PH_Cons_Base_Ctx", "ctx%node_ids(1:nnode)", "[IN]"),
      P("JDOF", "IN", 1, "INTEGER(i4)", "PH_Cons_Base_Ctx", "ctx%dof_map(1:ndof)", "[IN]"),
      P("NDOF", "IN", 0, "INTEGER(i4)", "PH_Cons_Base_Algo", "algo%ndof", "[IN]"),
      P("NNODE", "IN", 0, "INTEGER(i4)", "MD_Cons_Base_Desc", "desc%nnode", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Cons_Base_Ctx", "ctx%coords(1:3,1:nnode)", "[IN]"),
      P("JTYPE", "IN", 0, "INTEGER(i4)", "MD_Cons_Base_Desc", "desc%constraint_type", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Cons_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Cons_Base_Desc", "desc%nprops", "[IN]"),
      P("UE", "IN", 1, "REAL(wp)", "PH_Cons_Base_Ctx", "ctx%disp_master(1:ndof)", "[IN]"),
      P("DUE", "IN", 1, "REAL(wp)", "PH_Cons_Base_Ctx", "ctx%disp_inc(1:ndof)", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Cons_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Cons_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Cons_Base_Ctx", "ctx%kinc", "[IN]"),
    ],
  },

  {
    "name": "UMESHMOTION",
    "group": "constraint",
    "section": "7",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Cons_UMESHMOTION",
    "core_proc": "PH_Cons_UMESHMOTION_API",
    "ufc_domain": "Constraint",
    "parameters": [
      P("UREF", "OUT", 0, "REAL(wp)", "PH_Cons_Base_State", "state%mesh_disp_ref", "[OUT]"),
      P("DUREF", "OUT", 0, "REAL(wp)", "PH_Cons_Base_State", "state%mesh_disp_inc", "[OUT]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Cons_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Cons_Base_Ctx", "ctx%dtime", "[IN]"),
      P("NODE", "IN", 0, "INTEGER(i4)", "PH_Cons_Base_Ctx", "ctx%node_id", "[IN]"),
      P("NDOF", "IN", 0, "INTEGER(i4)", "PH_Cons_Base_Ctx", "ctx%dof_number", "[IN]"),
      P("JTYPE", "IN", 0, "INTEGER(i4)", "MD_Cons_Base_Desc", "desc%constraint_type", "[IN]"),
      P("PROPS", "IN", 1, "REAL(wp)", "MD_Cons_Base_Desc", "desc%props(1:nprops)", "[IN]"),
      P("NPROPS", "IN", 0, "INTEGER(i4)", "MD_Cons_Base_Desc", "desc%nprops", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Cons_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Cons_Base_Desc", "desc%constraint_name", "[IN]"),
    ],
  },

  # ═══════════════════════════════════════════════════════════════════════════
  #  §9  ANALYSIS CONTROL  (4 subroutines)
  # ═══════════════════════════════════════════════════════════════════════════

  {
    "name": "UAMP",
    "group": "analysis",
    "section": "9",
    "template": "umat_adapter.f90.j2",
    "module_name": "PH_Amp_UAMP",
    "core_proc": "PH_Amp_UAMP_API",
    "ufc_domain": "Analysis",
    "parameters": [
      P("AMPVAL", "OUT", 0, "REAL(wp)", "PH_Amp_Base_State", "state%amp_value", "[OUT]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Amp_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Amp_Base_Ctx", "ctx%dtime", "[IN]"),
      P("SNAME", "IN", 0, "CHARACTER(LEN=80)", "MD_Amp_Base_Desc", "desc%amp_name", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Amp_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Amp_Base_Ctx", "ctx%pt_id", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Amp_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Amp_Base_Ctx", "ctx%kinc", "[IN]"),
      P("LOCT", "IN", 1, "REAL(wp)", "PH_Amp_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
    ],
  },

  {
    "name": "UVARM",
    "group": "analysis",
    "section": "9",
    "template": "umat_adapter.f90.j2",
    "module_name": "RT_Output_UVARM",
    "core_proc": "RT_Output_UVARM_API",
    "ufc_domain": "Output",
    "parameters": [
      P("VAR", "OUT", 1, "REAL(wp)", "RT_Output_Ctx", "ctx%uvar(1:nuvarm)", "[OUT]"),
      P("TIME", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%dtime", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%kinc", "[IN]"),
      P("NOEL", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%elem_id", "[IN]"),
      P("NPT", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%gauss_pt", "[IN]"),
      P("NUVARM", "IN", 0, "INTEGER(i4)", "RT_Output_Ctx", "ctx%nuvarm", "[IN]"),
      P("JLTYP", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%output_type", "[IN]"),
      P("NNODE", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%nnode", "[IN]"),
      P("COORDS", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%coords(1:3)", "[IN]"),
      P("NFIELD", "IN", 0, "INTEGER(i4)", "PH_Mat_Base_Ctx", "ctx%nfield", "[IN]"),
      P("FIELD", "IN", 1, "REAL(wp)", "PH_Mat_Base_Ctx", "ctx%field(1:nfield)", "[IN]"),
    ],
  },

  {
    "name": "UEXTERNALDB",
    "group": "analysis",
    "section": "9",
    "template": "umat_adapter.f90.j2",
    "module_name": "RT_Analysis_UEXTERNALDB",
    "core_proc": "RT_Analysis_UEXTERNALDB_API",
    "ufc_domain": "Analysis",
    "parameters": [
      P("LOP", "IN", 0, "INTEGER(i4)", "RT_Analysis_Ctx", "ctx%db_operation", "[IN]"),
      P("TIME", "IN", 1, "REAL(wp)", "RT_Analysis_Ctx", "ctx%step_time/ctx%total_time", "[IN]"),
      P("DTIME", "IN", 0, "REAL(wp)", "RT_Analysis_Ctx", "ctx%dtime", "[IN]"),
      P("KSTEP", "IN", 0, "INTEGER(i4)", "RT_Analysis_Ctx", "ctx%kstep", "[IN]"),
      P("KINC", "IN", 0, "INTEGER(i4)", "RT_Analysis_Ctx", "ctx%kinc", "[IN]"),
      P("LREAD", "IN", 0, "INTEGER(i4)", "RT_Analysis_Ctx", "ctx%lread", "[IN]"),
      P("LSTOP", "IN", 0, "INTEGER(i4)", "RT_Analysis_Ctx", "ctx%lstop", "[IN]"),
      P("KOLD", "IN", 0, "INTEGER(i4)", "RT_Analysis_Ctx", "ctx%kold", "[IN]"),
    ],
  },

]

# ─────────────────────────────────────────────────────────────────────────
#  TEMPLATE RENDERER
# ─────────────────────────────────────────────────────────────────────────

def _render_fallback(sub: dict) -> str:
    """Simple string-template fallback when Jinja2 is not installed."""
    params = sub["parameters"]
    param_list = []
    for p in params:
        param_list.append(f"    {p['abaqus_param']}")
    # parameter_list_str is only needed for full template rendering
    _unused_params = ", ".join(p["abaqus_param"].strip() for p in params)
    return f"""! Auto-generated adapter for {sub['name']} — Jinja2 template not available.
! Subroutine: {sub['name']} | Group: {sub['group']} | UFC Domain: {sub['ufc_domain']}
! Reference: ABAQUS_Subroutine_UFC_TYPE_Mapping.md §{sub['section']}
! Core: {sub['core_proc']}
! Generated: {datetime.now(timezone.utc).isoformat()}
! Parameters ({len(params)}):
""" + chr(10).join(f"!   {p['abaqus_param']:15s} → {p['ufc_type']}.{p['ufc_field']}"
                             for p in params) + f"""

MODULE {sub['module_name']}_Adapter_Mod
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: {sub['name']}
CONTAINS
  SUBROUTINE {sub['name']}({', '.join(p['abaqus_param'].strip() for p in params)})
    ! Stub — see templates/umat_adapter.f90.j2 or uel_adapter.f90.j2
    ! Install Jinja2: pip install jinja2
    PRINT *, '[{sub["name"]}] Adapter stub — implement usingumat_adapter.f90.j2'
  END SUBROUTINE {sub['name']}
END MODULE {sub['module_name']}_Adapter_Mod
"""


def _pad_filter(s, width):
    """Left-pad string to given width (like Fortran FORMAT A)."""
    return str(s).ljust(int(width))


def render_adapter(sub: dict, template_dir: Path, jinja2_available: bool) -> str:
    """Render one adapter from template + sub definition."""
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    ctx = {
        **sub,
        "timestamp": timestamp,
    }

    if not jinja2_available:
        return _render_fallback(sub)

    env = Environment(
        loader=FileSystemLoader(str(template_dir)),
        autoescape=select_autoescape(default=False),
        keep_trailing_newline=True,
    )
    env.filters["pad"] = _pad_filter
    tmpl = env.get_template(sub["template"])
    return tmpl.render(**ctx)


# ─────────────────────────────────────────────────────────────────────────
#  OUTPUT
# ─────────────────────────────────────────────────────────────────────────

# Directory mapping: group → subdirectory under OUTPUT_BASE/L4_PH/Adapters/
GROUP_DIRS: dict[str, str] = {
    "material":   "Material",
    "element":    "Element",
    "load":       "Load",
    "bc":         "BC",
    "contact":    "Contact",
    "constraint": "Constraint",
    "field":      "Field",
    "analysis":   "Analysis",
}


def generate(sub: dict, output_base: Path, dry_run: bool,
             jinja2_available: bool) -> tuple[int, Path]:
    """Generate one adapter file.  Returns (n_lines, output_path)."""
    content = render_adapter(sub, TEMPLATE_DIR, jinja2_available)
    group_dir = GROUP_DIRS.get(sub["group"], sub["group"])
    out_dir = output_base / group_dir
    out_file = out_dir / f"{sub['name']}_Adapter.f90"

    if dry_run:
        print(f"=== {out_file} ({len(content.splitlines())} lines) ===")
        # Write to stdout with UTF-8 encoding to avoid GBK errors on Windows
        try:
            import sys
            sys.stdout.buffer.write(content.encode("utf-8"))
        except Exception:
            print(content)
        return len(content.splitlines()), out_file

    out_dir.mkdir(parents=True, exist_ok=True)
    out_file.write_text(content, encoding="utf-8")
    return len(content.splitlines()), out_file


# ─────────────────────────────────────────────────────────────────────────
#  CLI
# ─────────────────────────────────────────────────────────────────────────

GROUPS = list(GROUP_DIRS.keys())


def _group_from_args(args) -> list[dict]:
    if args.all:
        return ALL_SUBROUTINES
    if args.group:
        g = args.group.lower()
        if g not in GROUPS:
            raise SystemExit(f"Unknown group: {g!r}.  Available: {', '.join(GROUPS)}")
        return [s for s in ALL_SUBROUTINES if s["group"] == g]
    raise SystemExit(
        "Specify --all or --group GROUP\n"
        f"  Groups: {', '.join(GROUPS)}"
    )


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Generate UFC ABAQUS adapter files from parameter mapping data.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--all", action="store_true", help="Generate all 54 adapters")
    ap.add_argument(
        "--group", choices=GROUPS, metavar="GROUP",
        help=f"Generate adapters for one group: {{{','.join(GROUPS)}}}",
    )
    ap.add_argument(
        "--dry-run", action="store_true",
        help="Print to stdout instead of writing files",
    )
    ap.add_argument(
        "--output", type=Path, default=OUTPUT_BASE,
        help=f"Output directory (default: {OUTPUT_BASE})",
    )
    ap.add_argument(
        "--check-jinja2", action="store_true",
        help="Print Jinja2 availability and exit",
    )
    args = ap.parse_args()

    if args.check_jinja2:
        print(f"Jinja2 available: {_JINJA2_AVAILABLE}")
        return 0

    try:
        subs = _group_from_args(args)
    except SystemExit as exc:
        return exc.code if isinstance(exc.code, int) else 1

    print(f"Generating {len(subs)} adapter(s)...")
    total_lines = 0
    for sub in subs:
        n, path = generate(sub, args.output, args.dry_run, _JINJA2_AVAILABLE)
        status = "DRY-RUN" if args.dry_run else "WRITTEN"
        print(f"  [{status}] {path}  ({n} lines)")
        total_lines += n

    print(f"\nTotal: {len(subs)} adapter(s), {total_lines} lines.")
    print(f"Jinja2: {'available' if _JINJA2_AVAILABLE else 'NOT available (using fallback renderer)'}")
    if not _JINJA2_AVAILABLE:
        print("\n  Install Jinja2 for full template rendering:")
        print("    pip install jinja2")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
