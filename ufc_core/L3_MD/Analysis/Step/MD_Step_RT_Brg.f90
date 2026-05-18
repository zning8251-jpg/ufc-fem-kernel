!===============================================================================
! MODULE:   MD_Step_RT_Brg
! LAYER:    L3_MD
! DOMAIN:   Analysis · Step
! ROLE:     Bridge_L5 — **PROC_*** → **RT_SOLVER_*** (DEP-001 exempt: *_RT_Brg)
! BRIEF:    Keeps RT_SolverType_Def USE out of MD_Step_Proc (guardian RT_* scan).
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Step | Role:Brg | FuncSet:Map | HotPath:No
!===============================================================================
MODULE MD_Step_RT_Brg
    USE IF_Prec_Core, ONLY: i4
    USE MD_Step_ProcIDs
    USE RT_SolverType_Def, ONLY: RT_SOLVER_UNKNOWN, RT_SOLVER_IMPLICIT, &
        RT_SOLVER_EXPLICIT, RT_SOLVER_CFD, RT_SOLVER_EMF, RT_SOLVER_THM, &
        RT_SOLVER_PMF, RT_SOLVER_DIF, RT_SOLVER_CPL
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: ProcToSolverType

CONTAINS

    !> Map PROC_* analysis procedure ID to RT_SOLVER_* routing axis (8 engines).
    SUBROUTINE ProcToSolverType(proc, solver_type, ierr)
        INTEGER(i4), INTENT(IN) :: proc
        INTEGER(i4), INTENT(OUT) :: solver_type
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        IF (PRESENT(ierr)) ierr = 0
        SELECT CASE (proc)
        CASE (PROC_STATIC, PROC_STATIC_RIKS, PROC_STATIC_PERTURBATION, PROC_VISCO)
            solver_type = RT_SOLVER_IMPLICIT
        CASE (PROC_DYNAMIC_IMPLICIT, PROC_DYNAMIC_SUBSPACE, PROC_MODAL_DYNAMIC)
            solver_type = RT_SOLVER_IMPLICIT
        CASE (PROC_DYNAMIC_EXPLICIT)
            solver_type = RT_SOLVER_EXPLICIT
        CASE (PROC_DYNAMIC_CTD_EXPLICIT)
            solver_type = RT_SOLVER_EXPLICIT
        CASE (PROC_ANNEAL)
            solver_type = RT_SOLVER_IMPLICIT
        CASE (PROC_MODAL, PROC_BUCKLE, PROC_FREQUENCY, &
              PROC_RANDOM_RESPONSE, PROC_RESPONSE_SPECTRUM, PROC_COMPLEX_FREQUENCY)
            solver_type = RT_SOLVER_IMPLICIT
        CASE (PROC_HEAT_TRANSFER)
            solver_type = RT_SOLVER_THM
        CASE (PROC_MASS_DIFFUSION)
            solver_type = RT_SOLVER_DIF
        CASE (PROC_COUPLED_TEMP_DISP, PROC_COUPLED_THERMAL_ELEC, PROC_PIEZOELECTRIC)
            solver_type = RT_SOLVER_IMPLICIT
        CASE (PROC_COUPLED_TES)
            solver_type = RT_SOLVER_CPL
        CASE (PROC_ELECTROMAGNETIC)
            solver_type = RT_SOLVER_EMF
        CASE (PROC_ACOUSTIC)
            solver_type = RT_SOLVER_IMPLICIT
        CASE (PROC_GEOSTATIC, PROC_SOILS)
            solver_type = RT_SOLVER_PMF
        CASE (PROC_STEADY_STATE_TRANSPORT, PROC_SUBSTRUCTURE)
            solver_type = RT_SOLVER_IMPLICIT
        CASE DEFAULT
            solver_type = RT_SOLVER_UNKNOWN
            IF (PRESENT(ierr)) ierr = -1
        END SELECT
    END SUBROUTINE ProcToSolverType

END MODULE MD_Step_RT_Brg
