#!/usr/bin/env python3
"""
Generate one L3 + one L4 Fortran module per 74-leaf row from
  Material/_inv/MAT_T1_SPEC/MAT_MODULE_NAMES_T1_SUFFIX.md

Creates missing files only (does not overwrite existing non-empty implementations).

Layout:
  L3_MD/Material/<T1>/<MD_Mat_...>.f90
  L4_PH/Material/<T1>/<PH_Mat_...>.f90

Run from anywhere:
  python UFC/ufc_core/tools/gen_mat_leaf74_modules.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # ufc_core
SPEC = ROOT / "L3_MD/Material/_inv/MAT_T1_SPEC/MAT_MODULE_NAMES_T1_SUFFIX.md"
ROW_RE = re.compile(
    r"^\|\s*(\d{3})\s*\|\s*([^|]+)\|\s*([A-Z]{3})\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|"
)


def parse_rows() -> list[dict]:
    out: list[dict] = []
    text = SPEC.read_text(encoding="utf-8", errors="replace")
    for line in text.splitlines():
        m = ROW_RE.match(line.strip())
        if not m:
            continue
        mid = int(m.group(1))
        if mid < 101 or mid > 708:
            continue
        out.append(
            {
                "mat_id": mid,
                "pascal_symbol": m.group(2).strip(),
                "t1": m.group(3).strip(),
                "t2": m.group(4).strip(),
                "model_tag": m.group(5).strip(),
                "l3_mod": m.group(6).strip(),
                "l4_mod": m.group(7).strip(),
            }
        )
    return out


def tripartite_snake(t2: str, mid: int) -> str:
    t2l = t2.strip().lower().replace("-", "_")
    return f"{t2l}.m{mid}_leaf"


def desc_type_name(model_tag: str, mat_id: int) -> str:
    """Fortran type name must start with a letter (e.g. J2 is invalid as first token)."""
    tag = model_tag.replace(" ", "")
    if tag and tag[0].isalpha():
        return f"{tag}_MatDesc"
    return f"Mat{mat_id}_MatDesc"


def l3_template(r: dict) -> str:
    mid = r["mat_id"]
    t1 = r["t1"]
    tag = r["model_tag"]
    l3 = r["l3_mod"]
    t2 = r["t2"]
    tri = tripartite_snake(t2, mid)
    # UF_* prefix from ModelTag (valid Fortran identifier)
    uf = tag.replace(" ", "")
    dtn = desc_type_name(tag, mid)
    return f"""! Tripartite: {tri}
! Leaf L3 — independent module skeleton (Desc); align hooks with L4 `{r["l4_mod"]}`.
! mat_id={mid} Primary T1={t1} — see MAT_LEAF_INDEX_74.md / MD_Mat_Ids.f90.
MODULE {l3}
  USE IF_Prec, ONLY: i4, wp
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK, STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MAT_ID_{mid}
  USE MD_Mat_Types, ONLY: MD_MatDesc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MAT_ID_LEAF_{mid}
  PUBLIC :: {dtn}
  PUBLIC :: UF_{uf}_L3_ValidateProps
  PUBLIC :: UF_{uf}_L3_InitPlaceholder

  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ID_LEAF_{mid} = MAT_ID_{mid}

  TYPE, PUBLIC, EXTENDS(MD_MatDesc) :: {dtn}
    INTEGER(i4) :: reserved = 0_i4
  END TYPE {dtn}

CONTAINS

  SUBROUTINE UF_{uf}_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    IF (nprops < 1_i4) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF
    st%status_code = STATUS_OK
  END SUBROUTINE UF_{uf}_L3_ValidateProps

  SUBROUTINE UF_{uf}_L3_InitPlaceholder(st)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    st%status_code = STATUS_OK
  END SUBROUTINE UF_{uf}_L3_InitPlaceholder

END MODULE {l3}
"""


def l4_template(r: dict) -> str:
    mid = r["mat_id"]
    t1 = r["t1"]
    tag = r["model_tag"]
    l4 = r["l4_mod"]
    t2 = r["t2"]
    tri = tripartite_snake(t2, mid)
    uf = tag.replace(" ", "")
    return f"""! Tripartite: {tri}
! Leaf L4 — independent module skeleton (σ / tangent / UMAT hooks TBD).
! mat_id={mid} Primary T1={t1} — pair with L3 `{r["l3_mod"]}`.
MODULE {l4}
  USE IF_Prec, ONLY: i4, wp
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK, STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MAT_ID_{mid}
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MAT_ID_LEAF_{mid}
  PUBLIC :: UF_{uf}_L4_StepPlaceholder

  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ID_LEAF_{mid} = MAT_ID_{mid}

CONTAINS

  SUBROUTINE UF_{uf}_L4_StepPlaceholder(st)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    st%status_code = STATUS_OK
  END SUBROUTINE UF_{uf}_L4_StepPlaceholder

END MODULE {l4}
"""


def find_under(material_root: Path, stem: str) -> Path | None:
    """Any existing leaf file under Material/ (any T1 subfolder)."""
    if not material_root.is_dir():
        return None
    for p in material_root.rglob(f"{stem}.f90"):
        if "_inv" in p.parts:
            continue
        return p
    return None


def should_skip_target(path: Path, stem: str, layer_root: Path) -> bool:
    if path.is_file() and path.stat().st_size > 64:
        return True
    elsewhere = find_under(layer_root, stem)
    if elsewhere is not None and elsewhere != path and elsewhere.stat().st_size > 64:
        return True
    return False


def main() -> int:
    rows = parse_rows()
    if len(rows) != 74:
        print(f"WARN: expected 74 rows, got {len(rows)}", file=sys.stderr)
    n_l3 = n_l4 = 0
    l3_mat = ROOT / "L3_MD" / "Material"
    l4_mat = ROOT / "L4_PH" / "Material"
    for r in rows:
        t1 = r["t1"]
        l3_path = l3_mat / t1 / f"{r['l3_mod']}.f90"
        l4_path = l4_mat / t1 / f"{r['l4_mod']}.f90"
        l3_path.parent.mkdir(parents=True, exist_ok=True)
        l4_path.parent.mkdir(parents=True, exist_ok=True)
        if not should_skip_target(l3_path, r["l3_mod"], l3_mat):
            l3_path.write_text(l3_template(r), encoding="utf-8", newline="\n")
            print(f"L3 create {l3_path.relative_to(ROOT)}")
            n_l3 += 1
        if not should_skip_target(l4_path, r["l4_mod"], l4_mat):
            l4_path.write_text(l4_template(r), encoding="utf-8", newline="\n")
            print(f"L4 create {l4_path.relative_to(ROOT)}")
            n_l4 += 1
    print(f"Done. New L3={n_l3}, new L4={n_l4} (skipped existing files > 64 bytes).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
