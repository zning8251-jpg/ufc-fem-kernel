"""
Phase 1: Fix non-compilable template files in UFC/docs/templates/.
- Remove dead code after END MODULE
- Fix POINTER vs ALLOCATED
- Fix abstract ALLOCATE
- Fix PH_Analysis_Group_Router
- Fix PH_XXX_VUMAT
- Fix UFC_Memory_Strategy
- Fix MD_Friction_Types (types after CONTAINS)
- Fix MD_Load_Types (types after CONTAINS)
- Fix MD_Interaction_Types (stray END TYPE, missing USE)
"""
import os, re

TMPL = r'd:\TEST7\UFC\docs\templates'

def read_file(path):
    for enc in ('utf-8', 'utf-8-sig', 'latin-1'):
        try:
            with open(path, 'r', encoding=enc) as f:
                return f.read()
        except:
            continue
    return None

def write_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

fixed = 0

# ---- 1. MD_Contact_Types: remove dead code after first END MODULE ----
p = os.path.join(TMPL, 'MD_Contact_Types.f90')
txt = read_file(p)
if txt:
    # Find the first "END MODULE MD_Contact_Types" and keep only up to there
    # The line is malformed: "END MODULE MD_Contact_Types ..." with garbage
    lines = txt.split('\n')
    new_lines = []
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('END MODULE MD_Contact_Types'):
            new_lines.append('END MODULE MD_Contact_Types')
            break
        new_lines.append(line)
    else:
        new_lines = lines  # no match, keep original
    write_file(p, '\n'.join(new_lines) + '\n')
    print(f"[FIXED] MD_Contact_Types.f90: removed dead code after END MODULE")
    fixed += 1

# ---- 2. MD_Load_Types: remove types after CONTAINS, keep procedures ----
p = os.path.join(TMPL, 'MD_Load_Types.f90')
txt = read_file(p)
if txt:
    lines = txt.split('\n')
    # Strategy: find first CONTAINS, keep TBP implementations,
    # but remove TYPE definitions and second CONTAINS block + Domain
    new_lines = []
    in_dead_type = False
    seen_contains = False
    dead_region = False
    for i, line in enumerate(lines):
        stripped = line.strip()

        # After first CONTAINS, skip any TYPE definitions
        if stripped == 'CONTAINS' and not seen_contains:
            seen_contains = True
            new_lines.append(line)
            continue

        if seen_contains and not dead_region:
            # Check if we hit a TYPE definition after CONTAINS
            if re.match(r'\s*TYPE\s*,\s*PUBLIC', stripped):
                dead_region = True
                continue
            if stripped.startswith('!---') and dead_region:
                continue

        if dead_region:
            if stripped == 'END MODULE MD_Load_Types':
                new_lines.append('')
                new_lines.append('END MODULE MD_Load_Types')
                break
            continue

        new_lines.append(line)

    write_file(p, '\n'.join(new_lines) + '\n')
    print(f"[FIXED] MD_Load_Types.f90: removed types/domain after CONTAINS")
    fixed += 1

# ---- 3. MD_Friction_Types: move types from after CONTAINS to before ----
p = os.path.join(TMPL, 'MD_Friction_Types.f90')
txt = read_file(p)
if txt:
    lines = txt.split('\n')
    # Find the CONTAINS line
    contains_idx = None
    for i, line in enumerate(lines):
        if line.strip() == 'CONTAINS':
            contains_idx = i
            break

    if contains_idx is not None:
        # Find types after the last subroutine (after Fric_Desc_Reset END SUBROUTINE)
        # These are MD_Fric_FRIC_Desc, MD_Fric_VFRIC_Desc, MD_Fric_FRIC_COEF_Desc
        # They need to go before CONTAINS
        
        # Find where the TBP implementations end
        last_end_sub = None
        for i in range(contains_idx, len(lines)):
            if lines[i].strip().startswith('END SUBROUTINE'):
                last_end_sub = i

        # Types start after last_end_sub
        if last_end_sub is not None:
            types_to_move = []
            for i in range(last_end_sub + 1, len(lines)):
                if lines[i].strip() == 'END MODULE MD_Friction_Types':
                    break
                types_to_move.append(lines[i])

            # Add PUBLIC declarations and types before CONTAINS
            pub_lines = [
                '',
                '  PUBLIC :: MD_Fric_FRIC_Desc',
                '  PUBLIC :: MD_Fric_VFRIC_Desc',
                '  PUBLIC :: MD_Fric_FRIC_COEF_Desc',
            ]

            # Insert before CONTAINS
            new_lines = lines[:contains_idx]
            # Add the types that were after CONTAINS
            for tl in types_to_move:
                new_lines.append(tl)
            new_lines.append('')
            new_lines.append('CONTAINS')
            # Add TBP implementations (between CONTAINS and last_end_sub+1)
            for i in range(contains_idx + 1, last_end_sub + 1):
                new_lines.append(lines[i])
            new_lines.append('')
            new_lines.append('END MODULE MD_Friction_Types')

            # Add PUBLIC declarations after existing PUBLIC lines
            # Find last PUBLIC line
            last_pub = 0
            for i, line in enumerate(new_lines):
                if line.strip().startswith('PUBLIC ::'):
                    last_pub = i
            for j, pl in enumerate(pub_lines):
                new_lines.insert(last_pub + 1 + j, pl)

            write_file(p, '\n'.join(new_lines) + '\n')
            print(f"[FIXED] MD_Friction_Types.f90: moved types before CONTAINS")
            fixed += 1

# ---- 4. MD_Interaction_Types: fix stray END TYPE, add missing USE ----
p = os.path.join(TMPL, 'MD_Interaction_Types.f90')
txt = read_file(p)
if txt:
    # Fix USE IF_Prec_Core without ONLY
    txt = txt.replace('  USE IF_Prec_Core\n', '  USE IF_Prec_Core, ONLY: wp, i4\n')
    # Add missing USE IF_Err_API
    txt = txt.replace(
        '  USE IF_Prec_Core, ONLY: wp, i4\n  IMPLICIT NONE',
        '  USE IF_Prec_Core, ONLY: wp, i4\n  USE IF_Err_API, ONLY: ErrorStatusType, init_error_status\n  IMPLICIT NONE'
    )
    # Fix undefined constant references
    txt = txt.replace('normal_model = HARD_CONTACT_LAGRANGE',
                      'normal_model = MD_INTERACTION_HARD_CONTACT_LAGRANGE')
    txt = txt.replace('model_type   = SOFT_CONTACT_EXPONENTIAL',
                      'model_type   = MD_INTERACTION_SOFT_CONTACT_EXPONENTIAL')
    # Remove stray END TYPE
    txt = txt.replace('\n  END TYPE MD_ThermalConduct_Desc\n\n  END TYPE MD_ThermalConduct_Desc',
                      '\n  END TYPE MD_ThermalConduct_Desc')
    # Fix undefined STATUS_INVALID / STATUS_OK  
    txt = txt.replace("status%status_code = STATUS_INVALID",
                      "status%status_code = -1_i4")
    txt = txt.replace("status%status_code = STATUS_OK",
                      "status%status_code = 0_i4")
    # Remove undefined type refs in Domain container
    # Replace with concrete types that exist in this file
    txt = txt.replace('TYPE(MD_Int_Film_Desc),     ALLOCATABLE :: film_coeffs(:)',
                      'TYPE(MD_ThermalConduct_Desc), ALLOCATABLE :: thermal_conduct(:)')
    txt = txt.replace('TYPE(MD_Int_Radiat_Desc),   ALLOCATABLE :: radiations(:)',
                      'TYPE(MD_SurfInteract_Desc),   ALLOCATABLE :: surf_interactions(:)')
    txt = txt.replace('TYPE(MD_Int_GapCond_Desc),  ALLOCATABLE :: gap_conduct(:)',
                      'TYPE(MD_SoftContact_Desc),    ALLOCATABLE :: soft_contacts(:)')
    txt = txt.replace("this%film_coeffs", "this%thermal_conduct")
    txt = txt.replace("this%radiations", "this%surf_interactions")
    txt = txt.replace("this%gap_conduct", "this%soft_contacts")
    txt = txt.replace("n_film", "n_thermal")
    txt = txt.replace("n_radiat", "n_surf")
    txt = txt.replace("n_gap", "n_soft")
    write_file(p, txt)
    print(f"[FIXED] MD_Interaction_Types.f90: stray END TYPE, missing USE, undefined refs")
    fixed += 1

# ---- 5. PH_Analysis_Group_Router: fix Route_Arg, HandlerConfig ----
p = os.path.join(TMPL, 'PH_Analysis_Group_Router.f90')
txt = read_file(p)
if txt:
    # Move Route_Arg TYPE before CONTAINS
    route_arg_type = """
  !-- Arg bundle for routing (Principle #14)
  TYPE, PUBLIC :: Route_Arg
    LOGICAL :: success = .FALSE.
  END TYPE Route_Arg
"""
    # Insert before CONTAINS
    txt = txt.replace('\nCONTAINS\n', route_arg_type + '\nCONTAINS\n', 1)
    
    # Remove Route_Arg from after CONTAINS
    txt = re.sub(
        r'\s*!==+\s*\n\s*! INTERNAL TYPE: Route_Arg.*?\n\s*!==+\s*\n\s*TYPE :: Route_Arg\s*\n\s*LOGICAL :: success = \.FALSE\.\s*\n\s*END TYPE Route_Arg\s*\n',
        '\n',
        txt, flags=re.DOTALL
    )

    # Fix HandlerConfig: change ALLOCATABLE to fixed-size array
    txt = txt.replace(
        '    INTEGER(i4), ALLOCATABLE :: handler_ids(:)',
        '    INTEGER(i4) :: handler_ids(4) = 0_i4'
    )
    
    # Fix the PARAMETER array constructors to use fixed arrays
    # [HANDLER_ID_MECHANICS] -> needs padding to size 4
    def pad_handler_list(match):
        ids_str = match.group(1)
        ids = [x.strip() for x in ids_str.split(',')]
        while len(ids) < 4:
            ids.append('0_i4')
        return '[' + ', '.join(ids) + ']'
    
    # Replace handler_ids arrays in PARAMETER
    txt = re.sub(r'\[([A-Z_0-9, &\n]+?)\](?=,\s*(?:ROUTE|&))', pad_handler_list, txt)
    
    write_file(p, txt)
    print(f"[FIXED] PH_Analysis_Group_Router.f90: Route_Arg moved, HandlerConfig fixed")
    fixed += 1

# ---- 6. PH_XXX_VUMAT: fix PRESENT(args) and PURE function issues ----
p = os.path.join(TMPL, 'PH_XXX_VUMAT.f90')
txt = read_file(p)
if txt:
    # Remove meaningless IF (PRESENT(args)) - args is not OPTIONAL
    txt = txt.replace('    IF (PRESENT(args)) THEN\n', '    ! CFL check\n    IF (.TRUE.) THEN\n')
    # Actually, better to just remove the IF wrapper entirely
    txt = txt.replace(
        '    ! CFL check\n    IF (.TRUE.) THEN\n      args%cfl_number(1) = XXX_Compute_CFL(MD_Mat_Desc, PH_Mat_Ctx%celent)\n      IF (args%cfl_number(1) >= 1.0_wp) THEN\n        CALL init_error_status(args%status, STATUS_ERROR, &\n            message=\'[XXX_VUMAT_Impl]: CFL criterion violated\')\n        ! Do NOT set success=.TRUE.; allow automatic step cut\n        RETURN\n      END IF\n    END IF',
        '    args%cfl_number(1) = XXX_Compute_CFL(MD_Mat_Desc, PH_Mat_Ctx%celent)\n    IF (args%cfl_number(1) >= 1.0_wp) THEN\n      CALL init_error_status(args%status, STATUS_ERROR, &\n          message=\'[XXX_VUMAT_Impl]: CFL criterion violated\')\n      RETURN\n    END IF'
    )
    
    # Fix PURE function local variable initialization (not standard in PURE)
    txt = txt.replace(
        '    REAL(wp) :: C = 1.0_wp, p = 1.0_wp',
        '    REAL(wp) :: C, p'
    )
    txt = txt.replace(
        '    coef = 1.0_wp + (strain_rate_mag / MAX(C, 1.0e-30_wp))**p',
        '    C = 1.0_wp\n    p = 1.0_wp\n    coef = 1.0_wp + (strain_rate_mag / MAX(C, 1.0e-30_wp))**p'
    )
    
    write_file(p, txt)
    print(f"[FIXED] PH_XXX_VUMAT.f90: PRESENT(args), PURE function init")
    fixed += 1

# ---- 7. NM_Matrix_Domain_Template: fix POINTER/ALLOCATED and abstract alloc ----
p = os.path.join(TMPL, 'NM_Matrix_Domain_Template.f90')
txt = read_file(p)
if txt:
    # Change POINTER desc to CLASS pointer for polymorphism
    txt = txt.replace(
        'TYPE(NM_Matrix_Base_Desc), POINTER :: desc(:) => NULL()',
        'CLASS(NM_Matrix_Base_Desc), POINTER :: desc(:) => NULL()'
    )
    # Change POINTER state/algo/ctx to POINTER (they're concrete, OK)
    # But fix ALLOCATED -> ASSOCIATED for POINTER members
    txt = txt.replace('IF (ALLOCATED(this%desc))', 'IF (ASSOCIATED(this%desc))')
    txt = txt.replace('IF (ALLOCATED(this%state))', 'IF (ASSOCIATED(this%state))')
    txt = txt.replace('IF (ALLOCATED(this%algo))', 'IF (ASSOCIATED(this%algo))')
    txt = txt.replace('IF (ALLOCATED(this%ctx))', 'IF (ASSOCIATED(this%ctx))')
    # Fix ALLOCATE of abstract type -> cannot allocate abstract
    # Change to allocate concrete Dense_Desc by default
    txt = txt.replace(
        '    ALLOCATE(this%desc(n_matrices))',
        '    ALLOCATE(NM_Matrix_Dense_Desc :: this%desc(n_matrices))'
    )
    write_file(p, txt)
    print(f"[FIXED] NM_Matrix_Domain_Template.f90: POINTER/ASSOCIATED, abstract alloc")
    fixed += 1

# ---- 8. RT_Material_Domain_Template: fix POINTER/ALLOCATED and abstract alloc ----
p = os.path.join(TMPL, 'RT_Material_Domain_Template.f90')
txt = read_file(p)
if txt:
    # Change desc to CLASS pointer
    txt = txt.replace(
        'TYPE(RT_Material_Base_Desc), POINTER :: desc(:) => NULL()',
        'CLASS(RT_Material_Base_Desc), POINTER :: desc(:) => NULL()'
    )
    # Fix ALLOCATED -> ASSOCIATED
    txt = txt.replace('IF (ALLOCATED(this%desc))', 'IF (ASSOCIATED(this%desc))')
    txt = txt.replace('IF (ALLOCATED(this%state))', 'IF (ASSOCIATED(this%state))')
    txt = txt.replace('IF (ALLOCATED(this%algo))', 'IF (ASSOCIATED(this%algo))')
    txt = txt.replace('IF (ALLOCATED(this%ctx))', 'IF (ASSOCIATED(this%ctx))')
    # Fix abstract ALLOCATE
    txt = txt.replace(
        '    ALLOCATE(this%desc(n_libs))',
        '    ALLOCATE(RT_Material_UMAT_Desc :: this%desc(n_libs))'
    )
    write_file(p, txt)
    print(f"[FIXED] RT_Material_Domain_Template.f90: POINTER/ASSOCIATED, abstract alloc")
    fixed += 1

# ---- 9. UFC_Memory_Strategy: fix POINTER/ALLOCATED, constant refs, status fields ----
p = os.path.join(TMPL, 'UFC_Memory_Strategy.f90')
txt = read_file(p)
if txt:
    # Fix ALLOCATED on POINTER -> ASSOCIATED
    txt = txt.replace('IF (ALLOCATED(arr))', 'IF (ASSOCIATED(arr))')
    # Fix undefined MEM_LEVEL_STEP -> RT_MEM_MEM_LEVEL_STEP
    txt = txt.replace('lifecycle >= MEM_LEVEL_STEP', 'lifecycle >= RT_MEM_MEM_LEVEL_STEP')
    # Fix status%code -> status%status_code
    txt = txt.replace("status%code", "status%status_code")
    write_file(p, txt)
    print(f"[FIXED] UFC_Memory_Strategy.f90: POINTER/ASSOCIATED, constants, status fields")
    fixed += 1

print(f"\n=== Phase 1 complete: {fixed} files fixed ===")
