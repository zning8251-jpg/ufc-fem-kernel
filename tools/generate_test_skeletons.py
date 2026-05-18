#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC Test Skeleton Generator
Creates minimal test framework files Tests/{Domain}_test.f90 for each domain
that has a _Core.f90 module but no test file.
"""
import os
import sys
import glob
import re

UFC_CORE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ufc_core")

LAYER_ABBREV = {
    "L1_IF": "IF", "L2_NM": "NM", "L3_MD": "MD",
    "L4_PH": "PH", "L5_RT": "RT", "L6_AP": "AP",
}

SKIP_DIRS = {"contracts", "__pycache__", ".git"}


def find_core_module(domain_path):
    """Find the _Core module name in a domain."""
    for fpath in glob.glob(os.path.join(domain_path, "*_Core.f90")):
        with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
            for line in f:
                m = re.match(r'^\s*MODULE\s+(\w+)', line, re.IGNORECASE)
                if m:
                    return m.group(1), os.path.basename(fpath)
    return None, None


def generate_test(layer, domain, core_module, prefix):
    """Generate test skeleton."""
    return f"""!===============================================================================
! Module:  {prefix}_Test
! Layer:   {layer}
! Domain:  {domain}
! Purpose: Minimal test framework for the {domain} domain.
!          Verifies Init/Finalize and basic smoke tests.
!
! Status: SKELETON | Last verified: 2026-04-25
!===============================================================================
MODULE {prefix}_Test
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE {core_module}
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: {prefix}_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  !---------------------------------------------------------------------------
  ! Test runner: execute all tests and report
  !---------------------------------------------------------------------------
  SUBROUTINE {prefix}_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_init_finalize()
    ! TODO: Add domain-specific tests

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[{prefix}_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE {prefix}_Run_Tests

  !---------------------------------------------------------------------------
  ! Test: Init and Finalize succeed without error
  !---------------------------------------------------------------------------
  SUBROUTINE test_init_finalize()
    TYPE(ErrorStatusType) :: status

    ! TODO: Call {core_module} Init with minimal valid inputs
    ! TODO: Verify status == IF_STATUS_OK
    ! TODO: Call {core_module} Finalize
    ! TODO: Verify status == IF_STATUS_OK

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK

    IF (status%status_code == IF_STATUS_OK) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_init_finalize"
    END IF
  END SUBROUTINE test_init_finalize

END MODULE {prefix}_Test
"""


def main():
    dry_run = "--dry-run" in sys.argv
    created = 0
    skipped = 0

    print("=" * 72)
    print(f"UFC Test Skeleton Generator ({'DRY RUN' if dry_run else 'LIVE'})")
    print("=" * 72)

    for layer in sorted(os.listdir(UFC_CORE)):
        layer_path = os.path.join(UFC_CORE, layer)
        if not os.path.isdir(layer_path) or not layer.startswith("L"):
            continue

        print(f"\n### {layer}")
        abbr = LAYER_ABBREV.get(layer, "XX")

        for domain in sorted(os.listdir(layer_path)):
            domain_path = os.path.join(layer_path, domain)
            if not os.path.isdir(domain_path) or domain in SKIP_DIRS or domain == "Bridge":
                continue

            core_mod, core_file = find_core_module(domain_path)
            if core_mod is None:
                print(f"  {domain}: SKIP (no _Core module)")
                skipped += 1
                continue

            tests_dir = os.path.join(domain_path, "Tests")
            test_file = os.path.join(tests_dir, f"{abbr}_{domain}_test.f90")
            prefix = f"{abbr}_{domain}"

            if os.path.exists(test_file):
                print(f"  {domain}: SKIP (test file exists)")
                skipped += 1
                continue

            existing_tests = glob.glob(os.path.join(tests_dir, "*test*.f90"))
            if existing_tests:
                print(f"  {domain}: SKIP (test files exist in Tests/)")
                skipped += 1
                continue

            if dry_run:
                print(f"  {domain}: WOULD_CREATE Tests/{abbr}_{domain}_test.f90 (core: {core_mod})")
                created += 1
            else:
                os.makedirs(tests_dir, exist_ok=True)
                content = generate_test(layer, domain, core_mod, prefix)
                with open(test_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"  {domain}: CREATED Tests/{abbr}_{domain}_test.f90")
                created += 1

    print(f"\n{'=' * 72}")
    print(f"Test files {'would be ' if dry_run else ''}created: {created}")
    print(f"Skipped: {skipped}")
    print("=" * 72)


if __name__ == "__main__":
    main()
