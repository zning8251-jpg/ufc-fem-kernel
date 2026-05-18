!===============================================================================
! MODULE: MD_Elem_Def
! LAYER:  L3_MD
! DOMAIN: Element
! ROLE:   Def (Definition) — AUTHORITY (four-class TYPEs + family Desc/Algo)
! BRIEF:  L3 element four-class TYPE definitions, enums, and 12-family descriptors.
!         P1 2026-05-05: MD_ELEM_FORM_*/MD_ELEM_HG_*/MD_ELEM_MASS_*/MD_ELEM_INTEG_*.
! NOTE:   Single source file at L3_MD/Element/Elem/MD_Elem_Def.f90. Populate,
!         Reg, Domain, Validate live in sibling modules under the same Elem/ tree.
!===============================================================================
MODULE MD_Elem_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! SECTION: Element Formulation & Control Enum Constants (P1 fill 2026-05-05)
  !=============================================================================

  !-- Formulation variants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FORM_DISP           = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FORM_HYBRID         = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FORM_INCOMPAT       = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FORM_REDUCED        = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FORM_SELECTIVE      = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FORM_FBAR           = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_FORM_ASSUMED_STRAIN = 6_i4

  !-- Hourglass control methods
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_HG_NONE      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_HG_STIFFNESS  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_HG_VISCOUS    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_HG_ENHANCED   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_HG_RELAXED    = 4_i4

  !-- Mass matrix types
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_MASS_CONSISTENT = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_MASS_LUMPED     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_MASS_HRZ        = 3_i4

  !-- Integration scheme types
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_INTEG_FULL      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_INTEG_REDUCED   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_INTEG_USER      = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ELEM_INTEG_SELECTIVE = 3_i4

  !=============================================================================
  ! SECTION: Base Four-Class TYPEs (aligned L3↔L4↔L5)
  !=============================================================================

  !===========================================================================
  ! SECTION: Auxiliary Desc Types (Phase x Verb grouping, Depth 2)
  !===========================================================================

  !--- [Phase:Cfg|Verb:Init] Element identification & classification ---
  TYPE, PUBLIC :: MD_Elem_Cfg_Id_Desc
    INTEGER(i4) :: id           = 0_i4   ! Unique instance ID
    INTEGER(i4) :: elem_type_id = 0_i4   ! Element type ID (10=C3D8 etc.)
    INTEGER(i4) :: family_id    = 0_i4   ! Family ID (C3D/CPE/CPS/...)
    INTEGER(i4) :: sect_id      = 0_i4   ! Associated section ID
    INTEGER(i4) :: mat_id       = 0_i4   ! Associated material ID
  END TYPE MD_Elem_Cfg_Id_Desc

  !--- [Phase:Cfg|Verb:Init] Element topology configuration ---
  TYPE, PUBLIC :: MD_Elem_Cfg_Topo_Desc
    INTEGER(i4) :: n_nodes      = 0_i4   ! Number of nodes
    INTEGER(i4) :: n_dof        = 0_i4   ! Total DOFs = n_nodes * dof_per_node
    INTEGER(i4) :: dof_per_node = 0_i4   ! DOFs per node (3D:3, 2D:2, 1D:1)
    INTEGER(i4) :: ndim         = 0_i4   ! Space dimension (2 or 3)
    INTEGER(i4) :: n_ip         = 0_i4   ! Default integration points
  END TYPE MD_Elem_Cfg_Topo_Desc

  !--- [Phase:Cfg|Verb:Init] Element geometric classification ---
  TYPE, PUBLIC :: MD_Elem_Cfg_Geom_Desc
    INTEGER(i4) :: geom_kind    = 0_i4   ! 0=iso 1=axisym 2=pstress 3=pstrain
    REAL(wp)    :: thickness    = 0.0_wp ! Section thickness (for 2D)
  END TYPE MD_Elem_Cfg_Geom_Desc

  !--- [Phase:Pop|Verb:Vld] Element physical capability flags ---
  TYPE, PUBLIC :: MD_Elem_Pop_Flag_Desc
    LOGICAL     :: has_mass    = .FALSE. ! Supports mass matrix
    LOGICAL     :: has_damp    = .FALSE. ! Supports damping matrix
    LOGICAL     :: has_thermal = .FALSE. ! Thermal-mechanical coupled
    LOGICAL     :: has_porous  = .FALSE. ! Porous medium / consolidation
    LOGICAL     :: nlgeom      = .FALSE. ! Geometric nonlinearity support
  END TYPE MD_Elem_Pop_Flag_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Desc
  ! KIND: Desc
  ! DESC: Immutable element definition — registry cold data
  !       W2: nested auxiliary TYPEs under Depth 2 cap.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Desc
    !--- NEW: Auxiliary TYPE nesting (Phase x Verb grouping) ---
    TYPE(MD_Elem_Cfg_Id_Desc)   :: cfg_id   ! Config+Init: identification
    TYPE(MD_Elem_Cfg_Topo_Desc) :: cfg_topo ! Config+Init: topology
    TYPE(MD_Elem_Cfg_Geom_Desc) :: cfg_geom ! Config+Init: geometry
    TYPE(MD_Elem_Pop_Flag_Desc) :: pop_flag ! Populate+Validate: capability flags

    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE MD_Elem_Desc

  !===========================================================================
  ! SECTION: Auxiliary Algo Types (Phase x Verb grouping, Depth 2)
  !===========================================================================

  !--- [Phase:Stp|Verb:Ctl] Step control: integration & hourglass ---
  TYPE, PUBLIC :: MD_Elem_Stp_Ctl_Algo
    INTEGER(i4) :: ip_scheme       = 0_i4     ! 0=full, 1=reduced, 2=user
    INTEGER(i4) :: ip_override     = 0_i4     ! User-specified IP count (0=default)
    REAL(wp)    :: hourglass_coeff = 0.05_wp  ! Hourglass control coefficient
    INTEGER(i4) :: hourglass_type  = 0_i4     ! 0=none, 1=stiffness, 2=viscous
    LOGICAL     :: use_eas         = .FALSE.  ! Enhanced Assumed Strain (EAS)
    LOGICAL     :: use_fbar        = .FALSE.  ! F-bar volumetric locking
  END TYPE MD_Elem_Stp_Ctl_Algo

  !--- [Phase:Stp|Verb:Ctl] Step control: damping & mass ---
  TYPE, PUBLIC :: MD_Elem_Stp_Dyn_Algo
    REAL(wp)    :: struct_damp_eta = 0.0_wp   ! Structural damping coefficient
    REAL(wp)    :: rayleigh_alpha  = 0.0_wp   ! Rayleigh mass proportional
    REAL(wp)    :: rayleigh_beta   = 0.0_wp   ! Rayleigh stiffness proportional
    INTEGER(i4) :: mass_type       = 0_i4     ! 0=consistent, 1=lumped
  END TYPE MD_Elem_Stp_Dyn_Algo

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Algo
  ! KIND: Algo
  ! DESC: Algorithm configuration parameters — cold-path settings
  !       W2: nested auxiliary TYPEs under Depth 2 cap.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Algo
    !--- NEW: Auxiliary TYPE nesting (Phase x Verb grouping) ---
    TYPE(MD_Elem_Stp_Ctl_Algo) :: stp ! Step+Control: integration/hourglass/EAS
    TYPE(MD_Elem_Stp_Dyn_Algo) :: dyn ! Step+Control: damping/mass

    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE MD_Elem_Algo

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Ctx
  ! KIND: Ctx
  ! DESC: Model-level context metadata (NOT runtime — that is L4 responsibility)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Ctx
    !--- Model-level metadata ---
    INTEGER(i4) :: model_id    = 0_i4         ! Parent model ID
    INTEGER(i4) :: part_id     = 0_i4         ! Associated part ID
    INTEGER(i4) :: assembly_id = 0_i4         ! Associated assembly ID
    !--- Instance tracking ---
    INTEGER(i4) :: n_instances = 0_i4         ! Number of element instances
    LOGICAL     :: is_active   = .TRUE.       ! Active flag
  END TYPE MD_Elem_Ctx

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_State
  ! KIND: State
  ! DESC: Mutable model-level aggregations (NOT element matrices — that is L4)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_State
    !--- Model-level aggregations ---
    INTEGER(i4) :: total_elements  = 0_i4     ! Total element count in model
    INTEGER(i4) :: active_elements = 0_i4     ! Active element count
    !--- Summary statistics ---
    REAL(wp)    :: total_mass      = 0.0_wp   ! Total mass (all elements)
    REAL(wp)    :: total_stiffness = 0.0_wp   ! Sum stiffness contributions
  END TYPE MD_Elem_State

  !=============================================================================
  ! SECTION: Family-Specific Desc Types (12 families aligned with L4_PH)
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Solid3D_Desc
  ! KIND: Desc
  ! DESC: 3D solid element family descriptor (18 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Solid3D_Desc
    INTEGER(i4) :: id                  = 0_i4       ! Unique ID
    INTEGER(i4) :: n_ip_default        = 0_i4       ! Default IP count
    INTEGER(i4) :: n_ip_vol            = 0_i4       ! Volumetric IP (hourglass)
    REAL(wp)    :: bulk_modulus_ref     = 0.0_wp     ! Reference bulk modulus
    LOGICAL     :: reduced_integration = .FALSE.     ! Reduced integration flag
    LOGICAL     :: incompatible_mode   = .FALSE.     ! Incompatible mode (EAS)
  END TYPE MD_Elem_Solid3D_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Shell_Desc
  ! KIND: Desc
  ! DESC: Shell element family descriptor (24 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Shell_Desc
    INTEGER(i4) :: id                       = 0_i4   ! Unique ID
    REAL(wp)    :: thickness                = 0.0_wp  ! Shell thickness
    INTEGER(i4) :: n_layers                 = 1_i4    ! Section layers
    INTEGER(i4) :: integration_pts_thickness = 0_i4   ! Through-thickness IP
    LOGICAL     :: section_props_provided   = .FALSE. ! Section props given
    LOGICAL     :: predefined_section       = .FALSE. ! Predefined section
    INTEGER(i4) :: drill_dof               = 0_i4    ! 0=none 1=std 2=reduced
    INTEGER(i4) :: sc8r_control            = 0_i4    ! SC8R specific control
  END TYPE MD_Elem_Shell_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Beam_Desc
  ! KIND: Desc
  ! DESC: Beam element family descriptor (16 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Beam_Desc
    INTEGER(i4) :: id           = 0_i4        ! Unique ID
    REAL(wp)    :: section_area = 0.0_wp      ! Cross-section area
    REAL(wp)    :: I1           = 0.0_wp      ! Second moment I1
    REAL(wp)    :: I2           = 0.0_wp      ! Second moment I2
    REAL(wp)    :: I12          = 0.0_wp      ! Product of inertia
    REAL(wp)    :: J            = 0.0_wp      ! Torsional constant
    INTEGER(i4) :: section_type = 0_i4        ! 0=ARBITRARY 1=BEAM 2=PIPE
    INTEGER(i4) :: beam_theory  = 0_i4        ! 0=Timoshenko 1=Euler-Bernoulli
    LOGICAL     :: warping      = .FALSE.     ! Warping transmission
  END TYPE MD_Elem_Beam_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Truss_Desc
  ! KIND: Desc
  ! DESC: Truss element family descriptor (6 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Truss_Desc
    INTEGER(i4) :: id               = 0_i4    ! Unique ID
    REAL(wp)    :: cross_section     = 0.0_wp  ! Cross-sectional area
    REAL(wp)    :: initial_stress    = 0.0_wp  ! Initial stress state
    LOGICAL     :: tension_only      = .FALSE. ! Cable/ropelike
    LOGICAL     :: compression_only  = .FALSE. ! Compression only
  END TYPE MD_Elem_Truss_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Solid2D_Desc
  ! KIND: Desc
  ! DESC: 2D solid family descriptor (18 variants: CPE/CPS/CAX)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Solid2D_Desc
    INTEGER(i4) :: id                = 0_i4    ! Unique ID
    REAL(wp)    :: thickness          = 0.0_wp  ! Out-of-plane thickness
    INTEGER(i4) :: formulation        = 0_i4    ! 0=displacement 1=hybrid
    INTEGER(i4) :: plane_strain_opts  = 0_i4    ! For CPE variants
    LOGICAL     :: initially_stressed = .FALSE. ! Initially stressed
  END TYPE MD_Elem_Solid2D_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Infinite_Desc
  ! KIND: Desc
  ! DESC: Infinite element family descriptor (8 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Infinite_Desc
    INTEGER(i4) :: id             = 0_i4       ! Unique ID
    INTEGER(i4) :: decay_function = 0_i4       ! 0=const 1=linear 2=quadratic
    REAL(wp)    :: r_decay        = 0.0_wp     ! Decay radius ratio
    LOGICAL     :: mapped         = .FALSE.    ! Mapped infinite elements
  END TYPE MD_Elem_Infinite_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Cohesive_Desc
  ! KIND: Desc
  ! DESC: Cohesive element family descriptor (12 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Cohesive_Desc
    INTEGER(i4) :: id            = 0_i4        ! Unique ID
    REAL(wp)    :: thickness0    = 0.0_wp      ! Initial thickness
    INTEGER(i4) :: traction_law  = 0_i4        ! 0=exp 1=poly 2=user
    REAL(wp)    :: G_c           = 0.0_wp      ! Fracture energy
    REAL(wp)    :: sigma_max     = 0.0_wp      ! Peak traction
    LOGICAL     :: mixed_mode    = .FALSE.     ! Mixed mode loading
  END TYPE MD_Elem_Cohesive_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Spring_Desc
  ! KIND: Desc
  ! DESC: Spring element family descriptor (4 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Spring_Desc
    INTEGER(i4) :: id                  = 0_i4  ! Unique ID
    REAL(wp)    :: spring_stiffness    = 0.0_wp ! Spring stiffness
    INTEGER(i4) :: direction           = 0_i4  ! 0=ALL 1=x 2=y 3=z
    INTEGER(i4) :: dof_id              = 0_i4  ! Specified DOF
    LOGICAL     :: orientation_defined = .FALSE. ! Orientation defined
  END TYPE MD_Elem_Spring_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Dashpot_Desc
  ! KIND: Desc
  ! DESC: Dashpot element family descriptor (2 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Dashpot_Desc
    INTEGER(i4) :: id            = 0_i4        ! Unique ID
    REAL(wp)    :: dashpot_coeff = 0.0_wp      ! Damping coefficient
    INTEGER(i4) :: direction     = 0_i4        ! 0=ALL 1=x 2=y 3=z
    INTEGER(i4) :: dof_id        = 0_i4        ! Specified DOF
  END TYPE MD_Elem_Dashpot_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Mass_Desc
  ! KIND: Desc
  ! DESC: Mass element family descriptor (2 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Mass_Desc
    INTEGER(i4) :: id             = 0_i4       ! Unique ID
    REAL(wp)    :: mass_value     = 0.0_wp     ! Concentrated mass
    REAL(wp)    :: I11 = 0.0_wp, I22 = 0.0_wp, I33 = 0.0_wp  ! Moments of inertia
    REAL(wp)    :: I12 = 0.0_wp, I13 = 0.0_wp, I23 = 0.0_wp  ! Products of inertia
    LOGICAL     :: rotary_inertia = .FALSE.    ! Include rotary inertia
  END TYPE MD_Elem_Mass_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Gasket_Desc
  ! KIND: Desc
  ! DESC: Gasket element family descriptor (6 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Gasket_Desc
    INTEGER(i4) :: id                = 0_i4    ! Unique ID
    REAL(wp)    :: thickness0        = 0.0_wp  ! Nominal gap/overclosure
    REAL(wp)    :: normal_stiffness  = 0.0_wp  ! Normal stiffness
    REAL(wp)    :: shear_stiffness1  = 0.0_wp  ! Shear stiffness 1
    REAL(wp)    :: shear_stiffness2  = 0.0_wp  ! Shear stiffness 2
    INTEGER(i4) :: gasket_type       = 0_i4    ! 0=Gasket 1=Kappa
  END TYPE MD_Elem_Gasket_Desc

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Surface_Desc
  ! KIND: Desc
  ! DESC: Surface effect element family descriptor (8 variants)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Surface_Desc
    INTEGER(i4) :: id                 = 0_i4   ! Unique ID
    INTEGER(i4) :: surface_type       = 0_i4   ! 0=element-based 1=node-based
    INTEGER(i4) :: distribution_type  = 0_i4   ! 0=uniform 1=user-defined
    LOGICAL     :: film_coef_provided = .FALSE. ! Heat transfer coeff flag
  END TYPE MD_Elem_Surface_Desc

  !=============================================================================
  ! SECTION: Family-Specific Algo Types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Solid3D_Algo
  ! KIND: Algo
  ! DESC: Solid3D integration scheme configuration
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Solid3D_Algo
    INTEGER(i4) :: ip_scheme        = 0_i4     ! 0=full 1=reduced 2=selective
    INTEGER(i4) :: n_ip_override    = 0_i4     ! Override default IP count
    REAL(wp)    :: hourglass_control = 0.05_wp ! Hourglass coefficient
    INTEGER(i4) :: hourglass_type   = 0_i4     ! 0=none 1=stiffness 2=viscous
  END TYPE MD_Elem_Solid3D_Algo

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Shell_Algo
  ! KIND: Algo
  ! DESC: Shell integration scheme configuration
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Shell_Algo
    INTEGER(i4) :: through_thickness_ip = 0_i4 ! Simpson/Lobatto
    INTEGER(i4) :: membrane_ip          = 0_i4 ! In-plane integration
    LOGICAL     :: use_eas              = .FALSE. ! Enhanced assumed strain
    LOGICAL     :: use_fbar             = .FALSE. ! F-bar method
  END TYPE MD_Elem_Shell_Algo

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Beam_Algo
  ! KIND: Algo
  ! DESC: Beam integration scheme configuration
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Beam_Algo
    INTEGER(i4) :: integration_points = 0_i4   ! Gauss points along beam
    INTEGER(i4) :: shear_locking      = 0_i4   ! 0=none 1=reduced 2=selective
    INTEGER(i4) :: warping_solver     = 0_i4   ! 0=exact 1=approx
  END TYPE MD_Elem_Beam_Algo

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Truss_Algo
  ! KIND: Algo
  ! DESC: Truss algorithm configuration (placeholder)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Truss_Algo
    ! Base + truss-specific overrides if needed
  END TYPE MD_Elem_Truss_Algo

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Cohesive_Algo
  ! KIND: Algo
  ! DESC: Cohesive softening model configuration
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Cohesive_Algo
    INTEGER(i4) :: softening_model = 0_i4      ! 0=exp 1=linear 2=tabular
  END TYPE MD_Elem_Cohesive_Algo

  !---------------------------------------------------------------------------
  ! TYPE: MD_Elem_Mass_Algo
  ! KIND: Algo
  ! DESC: Mass matrix type configuration
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_Mass_Algo
    INTEGER(i4) :: mass_type = 0_i4            ! 0=consistent 1=lumped
  END TYPE MD_Elem_Mass_Algo

END MODULE MD_Elem_Def
