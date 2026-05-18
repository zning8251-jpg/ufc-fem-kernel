#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC Skeleton Generator — batch-creates _Def.f90, _Core.f90, _Brg.f90
for all domains that are missing standard skeleton files.

Only creates files that don't already exist. Skips domains with 0 f90.
"""
import os
import sys
import glob
import re
from collections import defaultdict

UFC_CORE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ufc_core")

LAYER_ABBREV = {
    "L1_IF": "IF",
    "L2_NM": "NM",
    "L3_MD": "MD",
    "L4_PH": "PH",
    "L5_RT": "RT",
    "L6_AP": "AP",
}

LAYER_FULLNAME = {
    "L1_IF": "Infrastructure Layer",
    "L2_NM": "Numerical Methods Layer",
    "L3_MD": "Model Data Layer",
    "L4_PH": "Physics Layer",
    "L5_RT": "Runtime Layer",
    "L6_AP": "Application Layer",
}

LAYER_DOMAIN_TYPE = {
    "L1_IF": "infrastructure",
    "L2_NM": "numerical",
    "L3_MD": "data",
    "L4_PH": "compute",
    "L5_RT": "orchestration",
    "L6_AP": "application",
}

SKIP_DIRS = {"contracts", "Tests", "tests", "__pycache__", ".git"}
SKIP_DOMAIN_NAMES = {"Bridge"}  # Bridge domains have specialized structure


def has_four_types(layer):
    return layer in ("L3_MD", "L4_PH", "L5_RT")


def get_domain_prefix(layer, domain):
    """Generate the naming prefix for a domain."""
    abbr = LAYER_ABBREV.get(layer, "XX")
    dom_parts = domain.split("/")
    if len(dom_parts) == 1:
        return f"{abbr}_{domain}"
    return f"{abbr}_{'_'.join(dom_parts)}"


def generate_def(layer, domain, prefix, domain_path):
    """Generate _Def.f90 skeleton."""
    abbr = LAYER_ABBREV.get(layer, "XX")
    fullname = LAYER_FULLNAME.get(layer, "Unknown")
    mod_name = f"{prefix}_Def"
    has_4t = has_four_types(layer)

    four_types = ""
    if has_4t:
        four_types = f"""
  !===========================================================================
  ! TYPE — Desc (Cold): model configuration, set at parse time
  !===========================================================================
  TYPE :: {prefix}_Desc
    INTEGER(i4) :: id       = 0_i4
    INTEGER(i4) :: type_id  = 0_i4
    LOGICAL     :: is_valid = .FALSE.
    ! TODO: Add domain-specific descriptor fields
  END TYPE {prefix}_Desc

  !===========================================================================
  ! TYPE — State (Warm): evolving data, changes per step/increment
  !===========================================================================
  TYPE :: {prefix}_State
    LOGICAL :: is_initialized = .FALSE.
    ! TODO: Add domain-specific state fields (or remove if not needed)
  END TYPE {prefix}_State

  !===========================================================================
  ! TYPE — Algo (Cold): algorithm control parameters
  !===========================================================================
  TYPE :: {prefix}_Algo
    INTEGER(i4) :: method = 1_i4
    ! TODO: Add algorithm selection parameters (or remove if not needed)
  END TYPE {prefix}_Algo

  !===========================================================================
  ! TYPE — Ctx (Hot): per-call scratch workspace
  !===========================================================================
  TYPE :: {prefix}_Ctx
    LOGICAL :: is_active = .FALSE.
    ! TODO: Add per-call work arrays (or remove if not needed)
  END TYPE {prefix}_Ctx
"""
        public_types = f"""  PUBLIC :: {prefix}_Desc
  PUBLIC :: {prefix}_State
  PUBLIC :: {prefix}_Algo
  PUBLIC :: {prefix}_Ctx
"""
    else:
        four_types = f"""
  !===========================================================================
  ! Domain configuration
  !===========================================================================
  TYPE :: {prefix}_Config
    INTEGER(i4) :: id = 0_i4
    LOGICAL :: is_initialized = .FALSE.
    ! TODO: Add domain-specific fields
  END TYPE {prefix}_Config
"""
        public_types = f"  PUBLIC :: {prefix}_Config\n"

    return f"""!===============================================================================
! Module:  {mod_name}
! Layer:   {layer} - {fullname}
! Domain:  {domain}
! Purpose: TYPE definitions for the {domain} domain.
!
! Status: SKELETON | Last verified: 2026-04-25
!===============================================================================
MODULE {mod_name}
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

{public_types}
{four_types}
END MODULE {mod_name}
"""


def generate_core(layer, domain, prefix, domain_path):
    """Generate _Core.f90 skeleton."""
    abbr = LAYER_ABBREV.get(layer, "XX")
    fullname = LAYER_FULLNAME.get(layer, "Unknown")
    mod_name = f"{prefix}_Core"
    def_mod = f"{prefix}_Def"
    has_4t = has_four_types(layer)

    if has_4t:
        use_def = f"  USE {def_mod}, ONLY: {prefix}_Desc, {prefix}_State, {prefix}_Ctx"
        init_params = f"""    TYPE({prefix}_Desc),  INTENT(IN)    :: desc
    TYPE({prefix}_State), INTENT(INOUT) :: state
    TYPE({prefix}_Ctx),   INTENT(INOUT) :: ctx"""
        fin_params = f"""    TYPE({prefix}_State), INTENT(INOUT) :: state
    TYPE({prefix}_Ctx),   INTENT(INOUT) :: ctx"""
    else:
        use_def = f"  USE {def_mod}, ONLY: {prefix}_Config"
        init_params = f"    TYPE({prefix}_Config), INTENT(INOUT) :: config"
        fin_params = f"    TYPE({prefix}_Config), INTENT(INOUT) :: config"

    return f"""!===============================================================================
! Module:  {mod_name}
! Layer:   {layer} - {fullname}
! Domain:  {domain}
! Purpose: Core operations for the {domain} domain.
!
! Status: SKELETON | Last verified: 2026-04-25
!===============================================================================
MODULE {mod_name}
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
{use_def}
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: {prefix}_Core_Init
  PUBLIC :: {prefix}_Core_Finalize

CONTAINS

  !---------------------------------------------------------------------------
  ! Init
  ! COLD_PATH
  !---------------------------------------------------------------------------
  SUBROUTINE {prefix}_Core_Init({('desc, state, ctx' if has_4t else 'config')}, status)
{init_params}
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ! TODO: Initialize domain
    status%status_code = IF_STATUS_OK
  END SUBROUTINE {prefix}_Core_Init

  !---------------------------------------------------------------------------
  ! Finalize
  ! COLD_PATH
  !---------------------------------------------------------------------------
  SUBROUTINE {prefix}_Core_Finalize({('state, ctx' if has_4t else 'config')}, status)
{fin_params}
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ! TODO: Release resources
    status%status_code = IF_STATUS_OK
  END SUBROUTINE {prefix}_Core_Finalize

END MODULE {mod_name}
"""


def generate_brg(layer, domain, prefix, domain_path):
    """Generate _Brg.f90 skeleton."""
    abbr = LAYER_ABBREV.get(layer, "XX")
    fullname = LAYER_FULLNAME.get(layer, "Unknown")
    mod_name = f"{prefix}_Brg"

    return f"""!===============================================================================
! Module:  {mod_name}
! Layer:   {layer} - {fullname}
! Domain:  {domain}
! Purpose: Bridge module for the {domain} domain.
!          Cross-layer type adaptation and data transfer.
!
! Status: SKELETON | Last verified: 2026-04-25
!===============================================================================
MODULE {mod_name}
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  ! PUBLIC :: {prefix}_Brg_FromL3  ! TODO: Add bridge procedures

CONTAINS

  ! TODO: Add bridge procedures for cross-layer data transfer

END MODULE {mod_name}
"""


def find_existing_patterns(domain_path, prefix):
    """Check which skeleton patterns already exist."""
    existing = {"def": False, "core": False, "brg": False}
    for root, dirs, files in os.walk(domain_path):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            if not f.endswith(".f90"):
                continue
            fl = f.lower()
            if "_def" in fl or "def." in fl:
                existing["def"] = True
            if "_core" in fl:
                existing["core"] = True
            if "_brg" in fl:
                existing["brg"] = True
    return existing


def process_domain(layer, domain, domain_path, dry_run=False):
    """Process a single domain."""
    f90_count = len(glob.glob(os.path.join(domain_path, "**", "*.f90"), recursive=True))
    prefix = get_domain_prefix(layer, domain)
    existing = find_existing_patterns(domain_path, prefix)

    results = []

    for role, generator in [("def", generate_def), ("core", generate_core), ("brg", generate_brg)]:
        suffix_map = {"def": "_Def.f90", "core": "_Core.f90", "brg": "_Brg.f90"}
        filename = f"{prefix}{suffix_map[role]}"
        filepath = os.path.join(domain_path, filename)

        if os.path.exists(filepath):
            results.append(f"  {role}: SKIP (file exists: {filename})")
            continue

        if existing[role]:
            results.append(f"  {role}: SKIP (pattern exists in domain)")
            continue

        if role == "brg" and layer in ("L1_IF",):
            results.append(f"  {role}: SKIP (L1 has no bridge)")
            continue

        content = generator(layer, domain, prefix, domain_path)

        if dry_run:
            results.append(f"  {role}: WOULD_CREATE {filename}")
        else:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            results.append(f"  {role}: CREATED {filename}")

    return results


def main():
    dry_run = "--dry-run" in sys.argv
    created = 0
    skipped = 0
    total_domains = 0

    print("=" * 72)
    print(f"UFC Skeleton Generator ({'DRY RUN' if dry_run else 'LIVE'})")
    print("=" * 72)

    for layer in sorted(os.listdir(UFC_CORE)):
        layer_path = os.path.join(UFC_CORE, layer)
        if not os.path.isdir(layer_path) or not layer.startswith("L"):
            continue

        print(f"\n### {layer}")

        for domain in sorted(os.listdir(layer_path)):
            domain_path = os.path.join(layer_path, domain)
            if not os.path.isdir(domain_path) or domain in SKIP_DIRS:
                continue
            if domain in SKIP_DOMAIN_NAMES:
                print(f"  {domain}: SKIP (Bridge domain)")
                continue

            total_domains += 1
            results = process_domain(layer, domain, domain_path, dry_run)
            print(f"  {domain}:")
            for r in results:
                print(f"    {r}")
                if "CREATED" in r or "WOULD_CREATE" in r:
                    created += 1
                else:
                    skipped += 1

    print(f"\n{'=' * 72}")
    print(f"Domains processed: {total_domains}")
    print(f"Files {'would be ' if dry_run else ''}created: {created}")
    print(f"Files skipped: {skipped}")
    print("=" * 72)


if __name__ == "__main__":
    main()
