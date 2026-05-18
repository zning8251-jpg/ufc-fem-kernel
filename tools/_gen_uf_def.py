# One-off: build MD_Amplitude_UF.f90 from MD_Amplitude_Algo.f90 slices (legacy; tree file may have more).
# If revived: post-process maps legacy UF amplitude symbols → current `MD_Amp_Slot_*` / `MD_Amp_MATH_PI`.
from pathlib import Path

def main():
    root = Path(__file__).resolve().parents[1]
    algo = root / "ufc_core/L3_MD/Analysis/Amplitude/MD_Amplitude_Algo.f90"
    lines = algo.read_text(encoding="utf-8").splitlines()

    def slice_between(start_sub, end_sub):
        s = e = None
        for i, L in enumerate(lines):
            if start_sub in L and s is None:
                s = i
            if s is not None and end_sub in L:
                e = i
                break
        if s is None or e is None:
            raise SystemExit(f"slice fail {start_sub!r} {end_sub!r}")
        return lines[s : e + 1]

    spec = slice_between(
        "INTEGER(i4), PARAMETER :: MAX_AMPLITUDE_NAME",
        "    END TYPE UF_AmplitudeDB",
    )
    body = slice_between(
        "    SUBROUTINE ampdb_add_amplitude(this, amp)",
        "    END FUNCTION amplitude_evaluate",
    )

    header = """!===============================================================================
! Module: MD_Amplitude_UF
! Layer:  L3_MD - Model Data Layer
! Domain: Amplitude — legacy UF_AmplitudeDef / UF_AmplitudeDB + UAMP Eval bundle
! Purpose: Types + type-bound workers only. Does NOT USE MD_Amplitude_Algo.
!   AMP_* / INTERP_* from MD_Amplitude_Def. See Amplitude/CONTRACT.md.
!===============================================================================
!>>> UFC_L3_TAG | layer:L3_MD | domain:Amplitude | role:UF
!>>> UFC_L3_CONTRACT | Amplitude/CONTRACT.md

MODULE MD_Amplitude_UF
    USE IF_Err_Brg, ONLY: ErrorStatusType
    USE IF_Prec_Algo, ONLY: wp, i4
    USE MD_Amplitude_Def, ONLY: &
         AMP_TABULAR, AMP_SMOOTH, AMP_PERIODIC, AMP_MODULATED, AMP_DECAY, AMP_USER, &
         AMP_EQUALLY_SPACED, AMP_RAMP, AMP_SOLUTION_DEPENDENT, AMP_ACTUATOR, AMP_SPECTRUM, AMP_PSD, &
         INTERP_LINEAR, INTERP_SMOOTH
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: UF_AmplitudeDef, UF_AmplitudeDB
    PUBLIC :: MAX_AMPLITUDE_NAME, MAX_AMP_POINTS, MAX_AMPLITUDES, AMPDB_INIT_CAP_DEFAULT
    PUBLIC :: TIME_STEP, TIME_TOTAL
    PUBLIC :: UF_AMP_MATH_PI
    PUBLIC :: MD_Amplitude_Eval_In, MD_Amplitude_Eval_Out
    PUBLIC :: MD_Amplitude_Eval_Desc, MD_Amplitude_Eval_Algo
    PUBLIC :: MD_Amplitude_Eval_Ctx, MD_Amplitude_Eval_State

"""

    spec2 = []
    for L in spec:
        if "PARAMETER, PRIVATE :: AMP_MATH_PI" in L:
            spec2.append(
                "    REAL(wp), PARAMETER, PUBLIC :: UF_AMP_MATH_PI = "
                "3.1415926535897932384626433832795_wp"
            )
            continue
        spec2.append(L.replace("AMP_MATH_PI", "UF_AMP_MATH_PI"))

    body2 = [L.replace("AMP_MATH_PI", "UF_AMP_MATH_PI") for L in body]

    out = (
        header
        + "\n".join(spec2)
        + "\n\nCONTAINS\n\n"
        + "\n".join(body2)
        + "\n\nEND MODULE MD_Amplitude_UF\n"
    )
    out = (
        out.replace("UF_AmplitudeDef", "MD_Amp_Slot_Desc")
        .replace("UF_AmplitudeDB", "MD_Amp_Slot_Ctx")
        .replace("UF_AMP_MATH_PI", "MD_Amp_MATH_PI")
    )
    out_path = root / "ufc_core/L3_MD/Analysis/Amplitude/MD_Amplitude_UF.f90"
    out_path.write_text(out, encoding="utf-8")
    print("Wrote", out_path, "lines", len(out.splitlines()))


if __name__ == "__main__":
    main()
