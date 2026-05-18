!======================================================================
! Module: MD_OutLib
! Layer:  L3_MD - Model Definition Layer
! Domain: Output / Library
! Purpose: Output library - field/history output definitions.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
!     - UF_OutputManager: Output manager (Ctx category)
!     - MD_Out_AddField_In/Out: Structured add field output interface
!     - MD_Out_AddHistory_In/Out: Structured add history output interface
!     - MD_Out_ShouldOutput_In/Out: Structured should output check interface
!   Subroutines:
!     - field_init: Initialize field output (legacy interface)
!     - field_add_variable: Add variable to field output (legacy interface)
!     - field_set_frequency: Set output frequency (legacy interface)
!     - field_should_output: Check if should output at increment/time (legacy interface)
!     - history_def_init: Initialize history output (legacy interface)
!     - history_state_init: Initialize history state storage (legacy interface)
!     - history_state_record_point: Record time history point (legacy interface)
!     - outmgr_init: Initialize output manager (legacy interface)
!     - outmgr_add_field: Add field output to manager (legacy interface)
!     - outmgr_add_history: Add history output to manager (legacy interface)
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Out | Role:Lib | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Output/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Out | Role:Lib | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Out_Lib
!> [CORE] Output request definitions for FEM analysis results
!> Theory: Field output (? ???^nstress, ? ???^nstrain, u ???^ndof), History output (t_i, y_i)
!> Status: CORE | Last verified: 2026-02-28
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE
    
    PUBLIC :: UF_OutputVar, UF_FieldOutputDef, UF_HistoryOutputDef
    PUBLIC :: UF_HistoryOutputState, UF_OutputManager
    PUBLIC :: MD_Out_AddField_In, MD_Out_AddField_Out
    PUBLIC :: MD_Out_AddHistory_In, MD_Out_AddHistory_Out
    PUBLIC :: MD_Out_ShouldOutput_In, MD_Out_ShouldOutput_Out
    PUBLIC :: MD_Out_AddField_Desc, MD_Out_AddField_Algo, MD_Out_AddField_Ctx, MD_Out_AddField_State
    
    INTEGER(i4), PARAMETER, PUBLIC :: MAX_OUTPUT_NAME = 64
    INTEGER(i4), PARAMETER, PUBLIC :: MAX_VARIABLES = 100
    INTEGER(i4), PARAMETER, PUBLIC :: MAX_FIELD_OUTPUTS = 50
    INTEGER(i4), PARAMETER, PUBLIC :: MAX_HISTORY_OUTPUTS = 100
    
    ! Output position
    INTEGER(i4), PARAMETER, PUBLIC :: POS_INTEGRATION_POINT = 1
    INTEGER(i4), PARAMETER, PUBLIC :: POS_CENTROID = 2
    INTEGER(i4), PARAMETER, PUBLIC :: POS_NODE = 3
    INTEGER(i4), PARAMETER, PUBLIC :: POS_ELEMENT = 4
    INTEGER(i4), PARAMETER, PUBLIC :: POS_SECTION_POINT = 5
    
    ! Variable categories
    INTEGER(i4), PARAMETER, PUBLIC :: VAR_NODAL = 1
    INTEGER(i4), PARAMETER, PUBLIC :: VAR_ELEMENT = 2
    INTEGER(i4), PARAMETER, PUBLIC :: VAR_CONTACT = 3
    INTEGER(i4), PARAMETER, PUBLIC :: VAR_ENERGY = 4
    
    ! Common output variable IDs (Abaqus compatible)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_U = 1       ! Displacement
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_V = 2       ! Velocity
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_A = 3       ! Acceleration
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_RF = 4      ! Reaction force
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_CF = 5      ! Concentrated force
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_NT = 6      ! Temperature
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_S = 11      ! Stress
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_E = 12      ! Total strain
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_PE = 13     ! Plastic strain
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_EE = 14     ! Elastic strain
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_LE = 15     ! Log strain
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_NE = 16     ! Nominal strain
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_PEEQ = 17   ! Equiv plastic strain
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_MISES = 18  ! Von Mises stress
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_PRESS = 19  ! Pressure
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_TRIAX = 20  ! Triaxiality
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_SDV = 21    ! State variables
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_STATUS = 22 ! Element/IP status (flag)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_SSE = 23    ! Elastic strain energy density (IP)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_SPD = 24    ! Plastic dissipation density (IP)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_SCD = 25    ! Creep/other dissipation density (IP)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_DAMAGE = 26 ! Damage variable at IP
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_STATUS_ELEM = 27 ! Element-level status (aggregated)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENER = 31   ! Energy quantities (IP total)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_EVOL = 32   ! Element volume
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_IVOL = 33   ! Integration volume
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_COORD = 41  ! Coordinates
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_HFL = 51    ! Heat flux
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_RFL = 52    ! Reaction heat flux

    ! History/energy scalar IDs (for History outputs)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENER_KE      = 60   ! Global kinetic energy (ALLKE)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENER_IE      = 61   ! Global internal energy (ALLIE)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENER_SE      = 62   ! Elastic strain energy (ALLSE)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENER_PD      = 63   ! Plastic dissipation (ALLPD)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENER_CD      = 64   ! Creep dissipation (ALLCD)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENER_WORKEXT = 65   ! External work (ALLWK)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENER_VD      = 66   ! Viscous dissipation (ALLVD)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENER_AE      = 67   ! Artificial energy (ALLAE)

    ! Contact scalar IDs (aggregated over all contact pairs)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_CACTIVE      = 70   ! Number of active contacts
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_CSTICK       = 71   ! Number of sticking nodes
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_CSLIDE       = 72   ! Number of sliding nodes
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_CMAXPEN      = 73   ! Max penetration
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_CFTOTAL      = 74   ! Total normal contact force
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_COPEN        = 75   ! Max opening (positive gap)
    INTEGER(i4), PARAMETER, PUBLIC :: OUT_CPRESS       = 76   ! Average contact pressure (approx.)

    !=============================================================================
    ! FOUR-CATEGORY TYPE SYSTEM: Desc/Algo/Ctx/State
    !=============================================================================
    
    !> @brief Descriptor for adding field output
    TYPE, PUBLIC :: MD_Out_AddField_Desc
      CHARACTER(LEN=MAX_OUTPUT_NAME) :: name = ""  ! Field output name
      CHARACTER(LEN=MAX_OUTPUT_NAME) :: region_name = ""  ! Output region name
      INTEGER(i4) :: region_type = 0  ! Region type: 0=all, 1=nset, 2=elset
      INTEGER(i4) :: position = POS_INTEGRATION_POINT  ! Output position
    END TYPE MD_Out_AddField_Desc
    
    !> @brief Algorithm parameters for adding field output
    TYPE, PUBLIC :: MD_Out_AddField_Algo
      INTEGER(i4) :: frequency = 1  ! Output frequency (every N increments)
      REAL(wp) :: time_interval = 0.0_wp  ! Time interval ?t ???^+ (0 = disabled)
      INTEGER(i4) :: num_time_marks = 0  ! Number of time marks ????
      REAL(wp), ALLOCATABLE :: time_marks(:)  ! Time marks t_i ???^+
    END TYPE MD_Out_AddField_Algo
    
    !> @brief Context for adding field output
    TYPE, PUBLIC :: MD_Out_AddField_Ctx
      LOGICAL :: verbose = .FALSE.  ! Verbose output flag
    END TYPE MD_Out_AddField_Ctx
    
    !> @brief State for adding field output
    TYPE, PUBLIC :: MD_Out_AddField_State
      INTEGER(i4) :: num_variables = 0  ! Number of variables added ????
      INTEGER(i4), ALLOCATABLE :: variables(:)  ! Variable IDs ???^+
    END TYPE MD_Out_AddField_State
    
    !> @brief Input structure for adding field output
    TYPE, PUBLIC :: MD_Out_AddField_In
      TYPE(MD_Out_AddField_Desc) :: desc
      TYPE(MD_Out_AddField_Algo) :: algo
      TYPE(MD_Out_AddField_Ctx) :: ctx
      TYPE(MD_Out_AddField_State) :: state
    END TYPE MD_Out_AddField_In
    
    !> @brief Output structure for adding field output
    TYPE, PUBLIC :: MD_Out_AddField_Out
      INTEGER(i4) :: field_output_id = 0  ! Assigned field output ID ???^+
      TYPE(MD_Out_AddField_State) :: state
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Out_AddField_Out
    
    !> @brief Input structure for adding history output
    TYPE, PUBLIC :: MD_Out_AddHistory_In
      CHARACTER(LEN=MAX_OUTPUT_NAME) :: name = ""  ! History output name
      CHARACTER(LEN=MAX_OUTPUT_NAME) :: region_name = ""  ! Output region name
      INTEGER(i4) :: frequency = 1  ! Output frequency (every N increments)
    END TYPE MD_Out_AddHistory_In
    
    !> @brief Output structure for adding history output
    TYPE, PUBLIC :: MD_Out_AddHistory_Out
      INTEGER(i4) :: history_output_id = 0  ! Assigned history output ID ???^+
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Out_AddHistory_Out
    
    !> @brief Input structure for should output check
    TYPE, PUBLIC :: MD_Out_ShouldOutput_In
      INTEGER(i4) :: increment = 0  ! Current increment n ???^+
      REAL(wp) :: time = 0.0_wp  ! Current time t ????
      INTEGER(i4) :: frequency = 1  ! Output frequency (every N increments)
      REAL(wp) :: time_interval = 0.0_wp  ! Time interval ?t ???^+ (0 = disabled)
      INTEGER(i4) :: num_time_marks = 0  ! Number of time marks ????
      REAL(wp), ALLOCATABLE :: time_marks(:)  ! Time marks t_i ???^+
    END TYPE MD_Out_ShouldOutput_In
    
    !> @brief Output structure for should output check
    TYPE, PUBLIC :: MD_Out_ShouldOutput_Out
      LOGICAL :: should_output = .FALSE.  ! Whether to output at this increment/time
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Out_ShouldOutput_Out
    
    !=============================================================================
    ! OUTPUT VARIABLE DEFINITION
    !=============================================================================
    
    !> @brief Output variable descriptor (Desc category)
    !! Theory: Defines output variable (displacement u, stress ?, strain ?, etc.)
    TYPE, PUBLIC :: UF_OutputVar
        INTEGER(i4) :: var_id = 0                    ! Variable ID ???^+
        CHARACTER(LEN=16) :: var_name = ""           ! Variable name (e.g., "U", "S", "E")
        INTEGER(i4) :: category = VAR_NODAL          ! Variable category: NODAL, ELEMENT, CONTACT, ENERGY
        INTEGER(i4) :: num_components = 1             ! Number of components ???^+
        LOGICAL :: is_tensor = .FALSE.                ! Is tensor variable (e.g., stress ?, strain ?)
        LOGICAL :: is_requested = .FALSE.             ! Is requested for output
    END TYPE UF_OutputVar
    
    !=============================================================================
    ! FIELD OUTPUT REQUEST (for ODB/VTK output)
    ! Theory: Spatial distribution fields at integration points or nodes
    !=============================================================================
    !> @brief Field output request (Desc category)
    !! Theory: Defines field output request for spatial distribution fields:
    !!   - Stress ? ???^nstress, strain ? ???^nstrain, displacement u ???^ndof
    !!   - Output frequency: every N increments, time intervals ?t, or time marks t_i
    TYPE, PUBLIC :: UF_FieldOutputDef
        CHARACTER(LEN=MAX_OUTPUT_NAME) :: name = ""  ! Field output name
        CHARACTER(LEN=MAX_OUTPUT_NAME) :: region_name = ""  ! Output region name
        INTEGER(i4) :: region_type = 0          ! Region type: 0=all, 1=nset, 2=elset
        INTEGER(i4) :: position = POS_INTEGRATION_POINT  ! Output position: IP, centroid, node, element
        INTEGER(i4) :: frequency = 1            ! Output frequency: every N increments ???^+
        INTEGER(i4) :: time_interval = 0         ! Time interval flag (0=disabled, >0=enabled)
        REAL(wp) :: time_marks(100) = 0.0_wp    ! Time marks t_i ???^+ for output
        INTEGER(i4) :: num_time_marks = 0        ! Number of time marks ????
        INTEGER(i4) :: num_variables = 0         ! Number of variables ????
        INTEGER(i4) :: variables(MAX_VARIABLES) = 0  ! Variable IDs ???^+
        LOGICAL :: is_active = .TRUE.            ! Active flag
    CONTAINS
        PROCEDURE :: init => field_init
        PROCEDURE :: add_variable => field_add_variable
        PROCEDURE :: add_variables => field_add_variables
        PROCEDURE :: set_frequency => field_set_frequency
        PROCEDURE :: should_output => field_should_output
        PROCEDURE :: print_info => field_print_info
    END TYPE UF_FieldOutputDef
    
    !=============================================================================
    ! HISTORY OUTPUT REQUEST (time history at specific points)
    ! Theory: Time series (t_i, y_i) where y_i ???^nvars
    !=============================================================================
    !> @brief History output request (Desc category)
    !! Theory: Defines history output request for time history data:
    !!   - Time series: (t_i, y_i) pairs where y_i ???^nvars
    !!   - Variables: Displacement u(t), stress ?(t), energy E(t), etc.
    !!   Note: UF_HistoryOutputDef (definition) + UF_HistoryOutputState (runtime storage)
    TYPE, PUBLIC :: UF_HistoryOutputDef
        CHARACTER(LEN=MAX_OUTPUT_NAME) :: name = ""  ! History output name
        CHARACTER(LEN=MAX_OUTPUT_NAME) :: region_name = ""  ! Output region name
        INTEGER(i4) :: region_type = 0          ! Region type: 0=all, 1=nset, 2=elset
        INTEGER(i4) :: frequency = 1             ! Output frequency: every N increments ???^+
        INTEGER(i4) :: num_variables = 0         ! Number of variables ????
        INTEGER(i4) :: variables(MAX_VARIABLES) = 0  ! Variable IDs ???^+
        LOGICAL :: is_active = .TRUE.            ! Active flag
    CONTAINS
        PROCEDURE :: init         => history_def_init
        PROCEDURE :: add_variable => history_def_add_variable
        PROCEDURE :: print_info   => history_def_print_info
    END TYPE UF_HistoryOutputDef

    !=============================================================================
    ! HISTORY OUTPUT RUNTIME STATE (storage of time history data)
    ! Theory: Stores time series (t_i, y_i) where t_i ???? y_i ???^nvars
    !=============================================================================
    !> @brief History output runtime state (State category)
    !! Theory: Stores time history data: time_data(t_i) and value_data(y_i) where y_i ???^nvars
    TYPE, PUBLIC :: UF_HistoryOutputState
        INTEGER(i4) :: max_points = 10000        ! Maximum number of time points ???^+
        INTEGER(i4) :: num_points = 0            ! Current number of points ????
        REAL(wp), ALLOCATABLE :: time_data(:)   ! Time array t_i ???^+
        REAL(wp), ALLOCATABLE :: value_data(:,:) ! Value array y_i ???^(nvars npoints)
    CONTAINS
        PROCEDURE :: init        => history_state_init
        PROCEDURE :: record_point => history_state_record_point
        PROCEDURE :: get_data    => history_state_get_data
        PROCEDURE :: destroy     => history_state_destroy
    END TYPE UF_HistoryOutputState

    
    !=============================================================================
    ! OUTPUT MANAGER
    ! Theory: Manages field outputs, history outputs, and output format settings
    !=============================================================================
    !> @brief Output manager (Ctx category)
    !! Theory: Manages field outputs (spatial fields ?, ?, u) and history outputs (time series)
    TYPE, PUBLIC :: UF_OutputManager
        INTEGER(i4) :: num_field = 0            ! Number of field outputs ????
        INTEGER(i4) :: num_history = 0           ! Number of history outputs ????
        TYPE(UF_FieldOutputDef), ALLOCATABLE :: fields(:)  ! Field output definitions
        TYPE(UF_HistoryOutputDef), ALLOCATABLE :: histories(:)  ! History output definitions
        TYPE(UF_HistoryOutputState), ALLOCATABLE :: history_states(:)  ! History output states
        ! Output format settings
        LOGICAL :: write_odb = .TRUE.           ! Write ODB format
        LOGICAL :: write_vtk = .FALSE.          ! Write VTK format
        LOGICAL :: write_csv = .FALSE.          ! Write CSV format
        LOGICAL :: write_dat = .FALSE.          ! Write DAT format
        LOGICAL :: write_txt = .FALSE.          ! Write TXT format
        CHARACTER(LEN=256) :: output_dir = "."  ! Output directory path
        CHARACTER(LEN=64) :: job_name = "Job-1" ! Job name (file prefix)
    CONTAINS

        PROCEDURE :: init => outmgr_init
        PROCEDURE :: add_field_output => outmgr_add_field
        PROCEDURE :: add_history_output => outmgr_add_history
        PROCEDURE :: get_field => outmgr_get_field
        PROCEDURE :: print_summary => outmgr_print_summary
        PROCEDURE :: destroy => outmgr_destroy
    END TYPE UF_OutputManager

    
CONTAINS

    !=============================================================================
    ! Field Output Methods (legacy interfaces)
    ! Theory: Initialize, add variables, set frequency, check should output
    !=============================================================================
    !> @brief Initialize field output (legacy interface)
    !! @details Initializes field output with name and optional region
    !! @param[inout] this Field output definition (will be initialized)
    !! @param[in] name Field output name
    !! @param[in] region Output region name (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE field_init(this, name, region)
        CLASS(UF_FieldOutputDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: region
        this%name = TRIM(name)
        IF (PRESENT(region)) this%region_name = TRIM(region)
        this%num_variables = 0
        this%is_active = .TRUE.
    END SUBROUTINE field_init
    
    !> @brief Add variable to field output (legacy interface)
    !! @details Adds variable ID to field output variable list
    !! @param[inout] this Field output definition
    !! @param[in] var_id Variable ID ???^+
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE field_add_variable(this, var_id)
        CLASS(UF_FieldOutputDef), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: var_id
        IF (this%num_variables >= MAX_VARIABLES) RETURN
        this%num_variables = this%num_variables + 1
        this%variables(this%num_variables) = var_id
    END SUBROUTINE field_add_variable
    
    SUBROUTINE field_add_variables(this, var_ids, n)
        CLASS(UF_FieldOutputDef), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: var_ids(:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4) :: i
        DO i = 1, n
            CALL this%add_variable(var_ids(i))
        END DO
    END SUBROUTINE field_add_variables
    
    !> @brief Set output frequency (legacy interface)
    !! @details Sets output frequency: every N increments or time interval ?t
    !! @param[inout] this Field output definition
    !! @param[in] freq Output frequency: every N increments ???^+ (optional)
    !! @param[in] interval Time interval ?t ???^+ (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE field_set_frequency(this, freq, interval)
        CLASS(UF_FieldOutputDef), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: freq
        REAL(wp), INTENT(IN), OPTIONAL :: interval
        IF (PRESENT(freq)) this%frequency = freq
        IF (PRESENT(interval)) this%time_interval = interval
    END SUBROUTINE field_set_frequency
    
    !> @brief Check if should output at increment/time (legacy interface)
    !! @details Checks if output should occur based on frequency, time interval, or time marks
    !!   Theory: Output if increment mod frequency == 0, or t matches time interval ?t, or t matches time marks t_i
    !! @param[in] this Field output definition
    !! @param[in] increment Current increment n ???^+
    !! @param[in] timeVal Current time t ????(optional)
    !! @return Whether to output at this increment/time
    !! @note Legacy interface - parameters should be encapsulated in structured types
    FUNCTION field_should_output(this, increment, timeVal) RESULT(should)
        CLASS(UF_FieldOutputDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: increment
        REAL(wp), INTENT(IN), OPTIONAL :: timeVal
        LOGICAL :: should
        REAL(wp) :: t, dt, mark
        INTEGER(i4) :: k, n

        should = .FALSE.
        IF (.NOT. this%is_active) RETURN

        ! 1) Increment-based control: output every N increments
        IF (this%frequency > 0) THEN
            IF (MOD(increment, this%frequency) == 0) should = .TRUE.
        END IF

        ! 2) Time-based control: time_interval ?t or time_marks t_i
        IF (PRESENT(timeVal)) THEN
            t = timeVal

            ! 2.1 Time interval: time_interval > 0, output at t = n ?t
            IF (this%time_interval > 0.0_wp) THEN
                dt = this%time_interval
                n  = NINT(t/dt)
                mark = REAL(n, wp) * dt
                IF (ABS(t - mark) <= 1.0e-6_wp * MAX(1.0_wp, ABS(t))) THEN
                    should = .TRUE.
                END IF
            END IF

            ! 2.2 Time marks: time_marks(1:num_time_marks), output at t = t_i
            IF (this%num_time_marks > 0) THEN
                DO k = 1, this%num_time_marks
                    mark = this%time_marks(k)
                    IF (ABS(t - mark) <= 1.0e-6_wp * MAX(1.0_wp, ABS(mark))) THEN
                        should = .TRUE.
                        EXIT
                    END IF
                END DO
            END IF
        END IF
    END FUNCTION field_should_output

    
    SUBROUTINE field_print_info(this, unit_num)
        CLASS(UF_FieldOutputDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A,A)') '  Field Output: ', TRIM(this%name)
        WRITE(unit_num, '(A,I5)') '    Variables: ', this%num_variables
        WRITE(unit_num, '(A,I5)') '    Frequency: ', this%frequency
    END SUBROUTINE field_print_info
    
    !=============================================================================
    ! History Output Methods (legacy interfaces)
    ! Theory: Initialize definition, add variables, initialize state storage, record time points
    !=============================================================================
    !> @brief Initialize history output (legacy interface)
    !! @details Initializes history output definition with name and optional region
    !!   Note: Def = description, State = time history storage
    !! @param[inout] this History output definition (will be initialized)
    !! @param[in] name History output name
    !! @param[in] region Output region name (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE history_def_init(this, name, region)
        CLASS(UF_HistoryOutputDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: region

        this%name = TRIM(name)
        IF (PRESENT(region)) this%region_name = TRIM(region)
        this%num_variables = 0
        this%is_active = .TRUE.
    END SUBROUTINE history_def_init
    
    !> @brief Add variable to history output (legacy interface)
    !! @details Adds variable ID to history output variable list
    !! @param[inout] this History output definition
    !! @param[in] var_id Variable ID ???^+
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE history_def_add_variable(this, var_id)
        CLASS(UF_HistoryOutputDef), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: var_id
        IF (this%num_variables >= MAX_VARIABLES) RETURN
        this%num_variables = this%num_variables + 1
        this%variables(this%num_variables) = var_id
    END SUBROUTINE history_def_add_variable
    
    SUBROUTINE history_def_print_info(this, unit_num)
        CLASS(UF_HistoryOutputDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A,A)') '  History Output: ', TRIM(this%name)
        WRITE(unit_num, '(A,I5)') '    Variables: ', this%num_variables
    END SUBROUTINE history_def_print_info
    
    !> @brief Initialize history state storage (legacy interface)
    !! @details Initializes history output state storage for time series (t_i, y_i)
    !! @param[inout] this History output state (will be initialized)
    !! @param[in] max_pts Maximum number of time points ???^+ (optional)
    !! @param[in] nvars Number of variables ???^+ (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE history_state_init(this, max_pts, nvars)
        CLASS(UF_HistoryOutputState), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_pts, nvars
        INTEGER(i4) :: mp, nv

        mp = this%max_points
        IF (PRESENT(max_pts)) mp = max_pts
        this%max_points = mp

        IF (PRESENT(nvars)) THEN
            nv = nvars
        ELSE
            nv = MAX_VARIABLES
        END IF

        IF (ALLOCATED(this%time_data)) DEALLOCATE(this%time_data)
        IF (ALLOCATED(this%value_data)) DEALLOCATE(this%value_data)

        ALLOCATE(this%time_data(this%max_points))
        ALLOCATE(this%value_data(nv, this%max_points))

        this%time_data = 0.0_wp
        this%value_data = 0.0_wp
        this%num_points = 0
    END SUBROUTINE history_state_init
    
    !> @brief Record time history point (legacy interface)
    !! @details Records time point (t, y) to history state storage
    !!   Theory: Stores (t_i, y_i) where t_i ???? y_i ???^nvars
    !! @param[inout] this History output state
    !! @param[in] time Time t ????
    !! @param[in] values Variable values y ???^nvars
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE history_state_record_point(this, time, values)
        CLASS(UF_HistoryOutputState), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: time
        REAL(wp), INTENT(IN) :: values(:)
        INTEGER(i4) :: i, ncomp

        IF (this%max_points <= 0) RETURN
        IF (.NOT. ALLOCATED(this%time_data)) RETURN
        IF (.NOT. ALLOCATED(this%value_data)) RETURN

        IF (this%num_points >= this%max_points) RETURN

        this%num_points = this%num_points + 1
        this%time_data(this%num_points) = time

        ncomp = MIN(SIZE(values), SIZE(this%value_data, 1))
        DO i = 1, ncomp
            this%value_data(i, this%num_points) = values(i)
        END DO
    END SUBROUTINE history_state_record_point
    
    SUBROUTINE history_state_get_data(this, times, values, n)
        CLASS(UF_HistoryOutputState), INTENT(IN) :: this
        REAL(wp), INTENT(OUT) :: times(:), values(:,:)
        INTEGER(i4), INTENT(OUT) :: n

        n = this%num_points
        IF (n <= 0) RETURN
        times(1:n) = this%time_data(1:n)
        values(:, 1:n) = this%value_data(:, 1:n)
    END SUBROUTINE history_state_get_data
    
    SUBROUTINE history_state_destroy(this)
        CLASS(UF_HistoryOutputState), INTENT(INOUT) :: this
        IF (ALLOCATED(this%time_data)) DEALLOCATE(this%time_data)
        IF (ALLOCATED(this%value_data)) DEALLOCATE(this%value_data)
        this%num_points = 0
    END SUBROUTINE history_state_destroy


    !=============================================================================
    ! Output Manager Methods (legacy interfaces)
    ! Theory: Initialize manager, add field/history outputs, query outputs
    !=============================================================================
    !> @brief Initialize output manager (legacy interface)
    !! @details Initializes output manager with job name and output directory
    !! @param[inout] this Output manager (will be initialized)
    !! @param[in] job_name Job name (optional)
    !! @param[in] output_dir Output directory path (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE outmgr_init(this, job_name, output_dir)
        CLASS(UF_OutputManager), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: job_name, output_dir
        IF (PRESENT(job_name)) this%job_name = TRIM(job_name)
        IF (PRESENT(output_dir)) this%output_dir = TRIM(output_dir)
        ALLOCATE(this%fields(MAX_FIELD_OUTPUTS))
        ALLOCATE(this%histories(MAX_HISTORY_OUTPUTS))
        ALLOCATE(this%history_states(MAX_HISTORY_OUTPUTS))
        this%num_field = 0
        this%num_history = 0
    END SUBROUTINE outmgr_init

    
    !> @brief Add field output to manager (legacy interface)
    !! @details Adds field output definition to output manager
    !! @param[inout] this Output manager
    !! @param[in] field Field output definition to add
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE outmgr_add_field(this, field)
        CLASS(UF_OutputManager), INTENT(INOUT) :: this
        TYPE(UF_FieldOutputDef), INTENT(IN) :: field
        IF (this%num_field >= MAX_FIELD_OUTPUTS) RETURN
        this%num_field = this%num_field + 1
        this%fields(this%num_field) = field
    END SUBROUTINE outmgr_add_field
    
    !> @brief Add history output to manager (legacy interface)
    !! @details Adds history output definition to output manager
    !! @param[inout] this Output manager
    !! @param[in] history History output definition to add
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE outmgr_add_history(this, history)
        CLASS(UF_OutputManager), INTENT(INOUT) :: this
        TYPE(UF_HistoryOutputDef), INTENT(IN) :: history
        IF (this%num_history >= MAX_HISTORY_OUTPUTS) RETURN
        this%num_history = this%num_history + 1
        this%histories(this%num_history) = history
    END SUBROUTINE outmgr_add_history
    
    FUNCTION outmgr_get_field(this, name) RESULT(ptr)
        CLASS(UF_OutputManager), INTENT(IN), TARGET :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(UF_FieldOutputDef), POINTER :: ptr
        INTEGER(i4) :: i
        ptr => NULL()
        DO i = 1, this%num_field
            IF (TRIM(this%fields(i)%name) == TRIM(name)) THEN
                ptr => this%fields(i)
                RETURN
            END IF
        END DO
    END FUNCTION outmgr_get_field
    
    SUBROUTINE outmgr_print_summary(this, unit_num)
        CLASS(UF_OutputManager), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        INTEGER(i4) :: i
        WRITE(unit_num, '(A)') '=== Output Summary ==='
        WRITE(unit_num, '(A,A)') '  Job name: ', TRIM(this%job_name)
        WRITE(unit_num, '(A,I5)') '  Field outputs:   ', this%num_field
        WRITE(unit_num, '(A,I5)') '  History outputs: ', this%num_history
        DO i = 1, this%num_field
            CALL this%fields(i)%print_info(unit_num)
        END DO
    END SUBROUTINE outmgr_print_summary
    
    SUBROUTINE outmgr_destroy(this)
        CLASS(UF_OutputManager), INTENT(INOUT) :: this
        INTEGER(i4) :: i
        DO i = 1, this%num_history
            CALL this%history_states(i)%destroy()
        END DO
        IF (ALLOCATED(this%fields)) DEALLOCATE(this%fields)
        IF (ALLOCATED(this%histories)) DEALLOCATE(this%histories)
        IF (ALLOCATED(this%history_states)) DEALLOCATE(this%history_states)
        this%num_field = 0
        this%num_history = 0
    END SUBROUTINE outmgr_destroy


END MODULE MD_Out_Lib