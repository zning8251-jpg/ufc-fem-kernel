!===============================================================================
! MODULE:   MD_Step_ProcIDs
! LAYER:    L3_MD
! DOMAIN:   Analysis · Step
! ROLE:     Def — **PROC_*** / **SSD_*** numeric IDs (SSOT for procedure routing)
! BRIEF:    Split from MD_Step_Proc so bridge modules can map PROC_* without
!           creating a circular USE with MD_Step_Proc (see MD_Step_RT_Brg).
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Step | Role:Def | FuncSet:PROC | HotPath:No
!===============================================================================
MODULE MD_Step_ProcIDs
    USE IF_Prec_Core, ONLY: i4
    IMPLICIT NONE
    PRIVATE

    ! ---------- Group A: Static & Quasi-Static (01-09) ----------
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_STATIC = 1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_STATIC_RIKS = 2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_STATIC_PERTURBATION = 3_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_VISCO = 4_i4

    ! ---------- Group B: Dynamic - Time Domain (10-19) ----------
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_DYNAMIC_IMPLICIT = 10_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_DYNAMIC_EXPLICIT = 11_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_DYNAMIC_SUBSPACE = 12_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_MODAL_DYNAMIC = 13_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_DYNAMIC_CTD_EXPLICIT = 14_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_ANNEAL = 15_i4

    ! ---------- Group C: Frequency Domain & Modal (20-29) ----------
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_MODAL = 20_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_BUCKLE = 21_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_FREQUENCY = 22_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_RANDOM_RESPONSE = 23_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_RESPONSE_SPECTRUM = 24_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_COMPLEX_FREQUENCY = 25_i4

    ! ---------- Group D: Heat Transfer & Diffusion (30-39) ----------
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_HEAT_TRANSFER = 30_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_MASS_DIFFUSION = 31_i4

    ! ---------- Group E: Coupled Multi-Physics (40-49) ----------
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_COUPLED_TEMP_DISP = 40_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_COUPLED_THERMAL_ELEC = 41_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_COUPLED_TES = 42_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_PIEZOELECTRIC = 43_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_ELECTROMAGNETIC = 44_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_ACOUSTIC = 45_i4

    ! ---------- Group F: Geotechnical (50-59) ----------
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_GEOSTATIC = 50_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_SOILS = 51_i4

    ! ---------- Group G: Special Purpose (60-69) ----------
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_STEADY_STATE_TRANSPORT = 60_i4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_SUBSTRUCTURE = 61_i4

    ! SSD sub-variants for PROC_FREQUENCY (ID=22)
    INTEGER(i4), PARAMETER, PUBLIC :: SSD_MODAL = 1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: SSD_SUBSPACE = 2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: SSD_DIRECT = 3_i4

END MODULE MD_Step_ProcIDs
