!===============================================================================
! MODULE:  MD_Sect_Lib
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Impl
! BRIEF:   Section library — P0 Library: section properties linking
!          elements to materials.
!===============================================================================

MODULE MD_Sect_Lib
    !! LAYER: L0 InputDef
    !! ROLE : input UF_SectionDef/SectionDBType ?material
    !! DEPENDS-ON: L0 Base, L0 UF_Material

    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    
    PRIVATE
    PUBLIC :: UF_SectionDef, UF_SectionDBType
    PUBLIC :: MAX_SECTION_NAME
    PUBLIC :: SECTION_SOLID, SECTION_SHELL, SECTION_BEAM, SECTION_MEMBRANE
    PUBLIC :: SECTION_TRUSS, SECTION_COHESIVE, SECTION_GASKET
    PUBLIC :: SECTION_CONNECTOR, SECTION_ACOUSTIC
    
    INTEGER(i4), PARAMETER :: MAX_SECTION_NAME = 80
    INTEGER(i4), PARAMETER :: MAX_SECTIONS = 1000
    
    ! Section type codes (canonical for UF_SectionDef%section_type; do not duplicate under L5_RT)
    INTEGER(i4), PARAMETER :: SECTION_SOLID = 1
    INTEGER(i4), PARAMETER :: SECTION_SHELL = 2
    INTEGER(i4), PARAMETER :: SECTION_BEAM = 3
    INTEGER(i4), PARAMETER :: SECTION_MEMBRANE = 4
    INTEGER(i4), PARAMETER :: SECTION_TRUSS = 5
    INTEGER(i4), PARAMETER :: SECTION_COHESIVE = 6
    INTEGER(i4), PARAMETER :: SECTION_GASKET = 7
    INTEGER(i4), PARAMETER :: SECTION_CONNECTOR = 8
    INTEGER(i4), PARAMETER :: SECTION_ACOUSTIC = 9
    
    ! Shell formulation types
    INTEGER, PARAMETER, PUBLIC :: SHELL_KIRCHHOFF = 1
    INTEGER, PARAMETER, PUBLIC :: SHELL_MINDLIN = 2
    
    ! Beam formulation types
    INTEGER, PARAMETER, PUBLIC :: BEAM_EULER = 1
    INTEGER, PARAMETER, PUBLIC :: BEAM_TIMOSHENKO = 2
    
    ! Beam cross-section types
    INTEGER, PARAMETER, PUBLIC :: BEAM_XSEC_RECT = 1
    INTEGER, PARAMETER, PUBLIC :: BEAM_XSEC_CIRCULAR = 2
    INTEGER, PARAMETER, PUBLIC :: BEAM_XSEC_PIPE = 3
    INTEGER, PARAMETER, PUBLIC :: BEAM_XSEC_I = 4
    INTEGER, PARAMETER, PUBLIC :: BEAM_XSEC_BOX = 5
    INTEGER, PARAMETER, PUBLIC :: BEAM_XSEC_GENERAL = 10
    
    ! ==========================================================================
    ! SECTION DEFINITION TYPE
    ! ==========================================================================
    TYPE, PUBLIC :: UF_SectionDef
        CHARACTER(LEN=MAX_SECTION_NAME) :: name = ""
        INTEGER(i4) :: id = 0
        INTEGER(i4) :: section_type = SECTION_SOLID
        
        ! Material reference
        CHARACTER(LEN=MAX_SECTION_NAME) :: material_name = ""
        INTEGER(i4) :: material_id = 0
        
        ! Element set this section is assigned to
        CHARACTER(LEN=MAX_SECTION_NAME) :: elset_name = ""
        
        ! Orientation (for anisotropic materials)
        CHARACTER(LEN=MAX_SECTION_NAME) :: orientation_name = ""
        
        ! ======================================================================
        ! SOLID SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: thickness = 1.0_wp           ! For 2D elements
        
        ! ======================================================================
        ! SHELL SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: shell_thickness = 0.0_wp
        INTEGER(i4) :: num_integration_points = 5   ! Through thickness
        INTEGER(i4) :: shell_formulation = SHELL_MINDLIN
        REAL(wp) :: offset_ratio = 0.0_wp        ! Shell offset ratio
        LOGICAL :: reduced_integration = .FALSE.
        
        ! ======================================================================
        ! BEAM SECTION PROPERTIES
        ! ======================================================================
        INTEGER(i4) :: beam_formulation = BEAM_TIMOSHENKO
        INTEGER(i4) :: xsec_type = BEAM_XSEC_RECT
        
        ! Cross-section dimensions (interpretation depends on xsec_type)
        REAL(wp) :: xsec_dims(10) = 0.0_wp
        ! For RECT: dims(1)=width, dims(2)=height
        ! For CIRCULAR: dims(1)=radius
        ! For PIPE: dims(1)=outer_radius, dims(2)=thickness
        ! For I: dims(1)=h, dims(2)=b1, dims(3)=b2, dims(4)=t1, dims(5)=t2, dims(6)=tw
        
        ! Computed cross-section properties
        REAL(wp) :: area = 0.0_wp
        REAL(wp) :: Iyy = 0.0_wp                 ! Second moment about y
        REAL(wp) :: Izz = 0.0_wp                 ! Second moment about z
        REAL(wp) :: Iyz = 0.0_wp                 ! Product of inertia
        REAL(wp) :: J = 0.0_wp                   ! Torsional constant
        REAL(wp) :: shear_factor_y = 0.0_wp      ! Shear correction factor
        REAL(wp) :: shear_factor_z = 0.0_wp
        
        ! ======================================================================
        ! MEMBRANE SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: membrane_thickness = 0.0_wp
        
        ! ======================================================================
        ! TRUSS SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: truss_area = 0.0_wp
        
        ! ======================================================================
        ! COHESIVE SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: cohesive_thickness = 1.0_wp
        INTEGER(i4) :: response_type = 1         ! 1=traction-separation
        
        ! ======================================================================
        ! GASKET SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: gasket_thickness = 1.0_wp
        REAL(wp) :: gasket_initial_gap = 0.0_wp
        REAL(wp) :: gasket_initial_void = 0.0_wp
        INTEGER(i4) :: gasket_type = 1           ! 1=thickness-direction only
        
        ! ======================================================================
        ! ACOUSTIC SECTION PROPERTIES
        ! ======================================================================
        REAL(wp) :: acoustic_bulk_modulus = 0.0_wp
        REAL(wp) :: acoustic_density = 0.0_wp
        
        ! ======================================================================
        ! CONNECTOR SECTION PROPERTIES
        ! ======================================================================
        INTEGER(i4) :: connector_type = 1        ! 1=JOIN, 2=HINGE, 3=SLIDER
        REAL(wp) :: connector_stiffness(6) = 0.0_wp
        REAL(wp) :: connector_damping(6) = 0.0_wp
        
        ! ======================================================================
        ! INTEGRATION CONTROL
        ! ======================================================================
        INTEGER(i4) :: num_gauss_points = 0      ! 0 = default for element type
        LOGICAL :: hourglass_control = .TRUE.
        REAL(wp) :: hourglass_stiffness = 0.0_wp
        
    CONTAINS
        PROCEDURE :: init => section_init
        PROCEDURE :: set_solid => section_set_solid
        PROCEDURE :: set_shell => section_set_shell
        PROCEDURE :: set_beam_rect => section_set_beam_rect
        PROCEDURE :: set_beam_circular => section_set_beam_circular
        PROCEDURE :: set_beam_general => section_set_beam_general
        PROCEDURE :: set_membrane => section_set_membrane
        PROCEDURE :: set_truss => section_set_truss
        PROCEDURE :: set_cohesive => section_set_cohesive
        PROCEDURE :: set_gasket => section_set_gasket
        PROCEDURE :: set_acoustic => section_set_acoustic
        PROCEDURE :: set_connector => section_set_connector
        PROCEDURE :: compute_beam_props => section_compute_beam_props
    END TYPE UF_SectionDef
    
    ! ==========================================================================
    ! SECTION DATABASE TYPE
    ! ==========================================================================
    TYPE, PUBLIC :: UF_SectionDBType

        INTEGER(i4) :: num_sections = 0
        TYPE(UF_SectionDef), ALLOCATABLE :: sections(:)
    CONTAINS
        PROCEDURE :: init => secdb_init
        PROCEDURE :: add_section => secdb_add_section
        PROCEDURE :: find_by_name => secdb_find_by_name
        PROCEDURE :: find_by_elset => secdb_find_by_elset
        PROCEDURE :: get_section => secdb_get_section
        PROCEDURE :: clear => secdb_clear
    END TYPE UF_SectionDBType

    
CONTAINS
    
    ! ==========================================================================
    ! SECTION DEFINITION METHODS
    ! ==========================================================================
    SUBROUTINE section_init(this, name, sec_type, material_name)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: sec_type
        CHARACTER(LEN=*), INTENT(IN) :: material_name
        
        this%name = TRIM(name)
        this%section_type = sec_type
        this%id = 0
        this%material_name = TRIM(material_name)
        
    END SUBROUTINE section_init
    
    SUBROUTINE section_set_solid(this, thickness)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN), OPTIONAL :: thickness
        
        this%section_type = SECTION_SOLID
        this%thickness = 1.0_wp
        IF (PRESENT(thickness)) this%thickness = thickness
        
    END SUBROUTINE section_set_solid
    
    SUBROUTINE section_set_shell(this, thickness, num_ip, formulation)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: thickness
        INTEGER(i4), INTENT(IN), OPTIONAL :: num_ip
        INTEGER(i4), INTENT(IN), OPTIONAL :: formulation
        
        this%section_type = SECTION_SHELL
        this%shell_thickness = thickness
        this%num_integration_points = 5
        IF (PRESENT(num_ip)) this%num_integration_points = num_ip
        this%shell_formulation = SHELL_MINDLIN
        IF (PRESENT(formulation)) this%shell_formulation = formulation
        
    END SUBROUTINE section_set_shell
    
    SUBROUTINE section_set_beam_rect(this, width, height)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: width, height
        
        this%section_type = SECTION_BEAM
        this%xsec_type = BEAM_XSEC_RECT
        this%xsec_dims(1) = width
        this%xsec_dims(2) = height
        
        CALL this%compute_beam_props()
        
    END SUBROUTINE section_set_beam_rect
    
    SUBROUTINE section_set_beam_circular(this, radius)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: radius
        
        this%section_type = SECTION_BEAM
        this%xsec_type = BEAM_XSEC_CIRCULAR
        this%xsec_dims(1) = radius
        
        CALL this%compute_beam_props()
        
    END SUBROUTINE section_set_beam_circular
    
    SUBROUTINE section_set_beam_general(this, area, Iyy, Izz, J)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: area, Iyy, Izz, J
        
        this%section_type = SECTION_BEAM
        this%xsec_type = BEAM_XSEC_GENERAL
        this%area = area
        this%Iyy = Iyy
        this%Izz = Izz
        this%J = J
        
    END SUBROUTINE section_set_beam_general
    
    SUBROUTINE section_set_membrane(this, thickness)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: thickness
        
        this%section_type = SECTION_MEMBRANE
        this%membrane_thickness = thickness
        
    END SUBROUTINE section_set_membrane
    
    SUBROUTINE section_set_truss(this, area)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: area
        
        this%section_type = SECTION_TRUSS
        this%truss_area = area
        
    END SUBROUTINE section_set_truss

    ! --- Cohesive ---
    SUBROUTINE section_set_cohesive(this, thickness, response)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: thickness
        INTEGER(i4), INTENT(IN), OPTIONAL :: response

        this%section_type = SECTION_COHESIVE
        this%cohesive_thickness = thickness
        IF (PRESENT(response)) this%response_type = response
    END SUBROUTINE section_set_cohesive

    ! --- Gasket ---
    SUBROUTINE section_set_gasket(this, thickness, initial_gap, gasket_type_in)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: thickness
        REAL(wp), INTENT(IN), OPTIONAL :: initial_gap
        INTEGER(i4), INTENT(IN), OPTIONAL :: gasket_type_in

        this%section_type = SECTION_GASKET
        this%gasket_thickness = thickness
        IF (PRESENT(initial_gap)) this%gasket_initial_gap = initial_gap
        IF (PRESENT(gasket_type_in)) this%gasket_type = gasket_type_in
    END SUBROUTINE section_set_gasket

    ! --- Acoustic ---
    SUBROUTINE section_set_acoustic(this, bulk_modulus, density)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: bulk_modulus
        REAL(wp), INTENT(IN) :: density

        this%section_type = SECTION_ACOUSTIC
        this%acoustic_bulk_modulus = bulk_modulus
        this%acoustic_density = density
    END SUBROUTINE section_set_acoustic

    ! --- Connector ---
    SUBROUTINE section_set_connector(this, conn_type, stiffness, damping)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: conn_type
        REAL(wp), INTENT(IN), OPTIONAL :: stiffness(6)
        REAL(wp), INTENT(IN), OPTIONAL :: damping(6)

        this%section_type = SECTION_CONNECTOR
        this%connector_type = conn_type
        IF (PRESENT(stiffness)) this%connector_stiffness = stiffness
        IF (PRESENT(damping)) this%connector_damping = damping
    END SUBROUTINE section_set_connector
    
    SUBROUTINE section_compute_beam_props(this)
        CLASS(UF_SectionDef), INTENT(INOUT) :: this
        REAL(wp) :: b, h, r, ro, ri
        REAL(wp), PARAMETER :: PI = 3.141592653589793_wp
        
        SELECT CASE (this%xsec_type)
        CASE (BEAM_XSEC_RECT)
            b = this%xsec_dims(1)
            h = this%xsec_dims(2)
            this%area = b * h
            this%Iyy = b * h**3 / 12.0_wp
            this%Izz = h * b**3 / 12.0_wp
            this%J = b * h * (b**2 + h**2) / 12.0_wp  ! Approximate
            this%shear_factor_y = 5.0_wp / 6.0_wp
            this%shear_factor_z = 5.0_wp / 6.0_wp
            
        CASE (BEAM_XSEC_CIRCULAR)
            r = this%xsec_dims(1)
            this%area = PI * r**2
            this%Iyy = PI * r**4 / 4.0_wp
            this%Izz = this%Iyy
            this%J = PI * r**4 / 2.0_wp
            this%shear_factor_y = 6.0_wp / 7.0_wp
            this%shear_factor_z = 6.0_wp / 7.0_wp
            
        CASE (BEAM_XSEC_PIPE)
            ro = this%xsec_dims(1)
            ri = ro - this%xsec_dims(2)
            this%area = PI * (ro**2 - ri**2)
            this%Iyy = PI * (ro**4 - ri**4) / 4.0_wp
            this%Izz = this%Iyy
            this%J = PI * (ro**4 - ri**4) / 2.0_wp
            this%shear_factor_y = 0.5_wp
            this%shear_factor_z = 0.5_wp
            
        CASE DEFAULT
            ! General or unhandled type - properties must be set directly
        END SELECT
        
    END SUBROUTINE section_compute_beam_props
    
    ! ==========================================================================
    ! SECTION DATABASE METHODS
    ! ==========================================================================
    SUBROUTINE secdb_init(this, capacity)
        CLASS(UF_SectionDBType), INTENT(INOUT) :: this

        INTEGER(i4), INTENT(IN), OPTIONAL :: capacity
        INTEGER(i4) :: cap
        
        cap = 100
        IF (PRESENT(capacity)) cap = capacity
        
        this%num_sections = 0
        IF (ALLOCATED(this%sections)) DEALLOCATE(this%sections)
        ALLOCATE(this%sections(cap))
        
    END SUBROUTINE secdb_init
    
    SUBROUTINE secdb_add_section(this, sec)
        CLASS(UF_SectionDBType), INTENT(INOUT) :: this

        TYPE(UF_SectionDef), INTENT(IN) :: sec
        TYPE(UF_SectionDef), ALLOCATABLE :: temp(:)
        
        IF (.NOT. ALLOCATED(this%sections)) CALL this%init()
        
        IF (this%num_sections >= SIZE(this%sections)) THEN
            ALLOCATE(temp(SIZE(this%sections) * 2))
            temp(1:this%num_sections) = this%sections(1:this%num_sections)
            CALL MOVE_ALLOC(temp, this%sections)
        END IF
        
        this%num_sections = this%num_sections + 1
        this%sections(this%num_sections) = sec
        this%sections(this%num_sections)%id = this%num_sections
        
    END SUBROUTINE secdb_add_section
    
    FUNCTION secdb_find_by_name(this, name) RESULT(idx)
        CLASS(UF_SectionDBType), INTENT(IN) :: this

        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: idx
        INTEGER(i4) :: i
        
        idx = -1
        DO i = 1, this%num_sections
            IF (TRIM(this%sections(i)%name) == TRIM(name)) THEN
                idx = i
                RETURN
            END IF
        END DO
        
    END FUNCTION secdb_find_by_name
    
    FUNCTION secdb_find_by_elset(this, elset_name) RESULT(idx)
        CLASS(UF_SectionDBType), INTENT(IN) :: this

        CHARACTER(LEN=*), INTENT(IN) :: elset_name
        INTEGER(i4) :: idx
        INTEGER(i4) :: i
        
        idx = -1
        DO i = 1, this%num_sections
            IF (TRIM(this%sections(i)%elset_name) == TRIM(elset_name)) THEN
                idx = i
                RETURN
            END IF
        END DO
        
    END FUNCTION secdb_find_by_elset
    
    FUNCTION secdb_get_section(this, idx) RESULT(sec_ptr)
        CLASS(UF_SectionDBType), INTENT(IN), TARGET :: this

        INTEGER(i4), INTENT(IN) :: idx
        TYPE(UF_SectionDef), POINTER :: sec_ptr
        
        NULLIFY(sec_ptr)
        IF (idx >= 1 .AND. idx <= this%num_sections) THEN
            sec_ptr => this%sections(idx)
        END IF
        
    END FUNCTION secdb_get_section
    
    SUBROUTINE secdb_clear(this)
        CLASS(UF_SectionDBType), INTENT(INOUT) :: this

        this%num_sections = 0
        IF (ALLOCATED(this%sections)) DEALLOCATE(this%sections)
    END SUBROUTINE secdb_clear
    
END MODULE MD_Sect_Lib