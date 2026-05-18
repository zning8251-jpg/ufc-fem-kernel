!===============================================================================
! MODULE: PH_Elem_Def
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Def
! BRIEF:  Four-kind TYPE definitions for Element domain (Desc/Ctx/State/Algo)
!         + SIO Arg TYPEs for Phase 3C parameter bundling.
!         + Phase 6A: Integrator ABSTRACT INTERFACE & Procedure pointer.
! **W2**：L4 **四型** **`PH_Elem_*`** + **SIO Arg**；消费 **`PH_Elem_Desc`** 槽与 **`PH_Elem_Core`** 热路径；
!         与 L3 **`MD_Elem_*`**、L5 **`RT_Elem_*`** 分型对齐。
!===============================================================================
MODULE PH_Elem_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE PH_Elem_Aux_Def, ONLY: PH_Elem_Cfg_Init_Desc, PH_Elem_Pop_Vld_Desc, &
                              PH_Elem_Inc_Evo_Ctx, &
                              PH_Elem_Itr_Asm_Ctx, PH_Elem_Lcl_Comp_Ctx, &
                              PH_Elem_Lcl_Evo_Ctx, PH_Elem_Stp_Ctl_Algo, &
                              PH_Elem_Stp_Ctl_Dyn_Algo, &
                              PH_Elem_Stp_Evo_State, PH_Elem_Itr_Acc_State
  IMPLICIT NONE
  PRIVATE

  !--- [PUBLIC TYPES - Four-Kind] ---
  PUBLIC :: PH_Elem_Desc
  PUBLIC :: PH_Elem_Ctx
  PUBLIC :: PH_Elem_State
  PUBLIC :: PH_Elem_Algo

  !--- [PUBLIC ARG TYPES - SIO Phase 3C] ---
  PUBLIC :: PH_Elem_Core_Ke_Arg
  PUBLIC :: PH_Elem_Core_Fe_Arg
  PUBLIC :: PH_Elem_Core_Fint_Arg
  PUBLIC :: PH_Elem_Core_Mass_Arg
  PUBLIC :: PH_Elem_Eval_Ke_Arg
  PUBLIC :: PH_Elem_Eval_Fe_Arg
  PUBLIC :: PH_Elem_Eval_Mass_Arg
  PUBLIC :: PH_Elem_ComplexStiff_Form_Arg
  PUBLIC :: PH_Elem_NL_TL_Arg
  PUBLIC :: PH_Elem_NL_UL_Arg
  PUBLIC :: PH_Elem_JacB_Arg
  PUBLIC :: PH_Elem_Contact_Arg
  PUBLIC :: PH_Elem_Constraint_Arg
  PUBLIC :: PH_Element_Compute_Ke_Arg
  PUBLIC :: PH_Element_Compute_Fe_Arg

  !--- [PUBLIC - Phase 6A Integrator Strategy] ---
  PUBLIC :: PH_Elem_Stiff_Arg
  PUBLIC :: PH_Elem_Integrator_Ifc

  !--- [AUXILIARY TYPE RE-EXPORTS] ---
  PUBLIC :: PH_Elem_Cfg_Init_Desc
  PUBLIC :: PH_Elem_Pop_Vld_Desc
  PUBLIC :: PH_Elem_Itr_Asm_Ctx
  PUBLIC :: PH_Elem_Lcl_Comp_Ctx
  PUBLIC :: PH_Elem_Lcl_Evo_Ctx
  PUBLIC :: PH_Elem_Stp_Ctl_Algo
  PUBLIC :: PH_Elem_Stp_Ctl_Dyn_Algo
  PUBLIC :: PH_Elem_Stp_Evo_State
  PUBLIC :: PH_Elem_Itr_Acc_State

  !--- [PUBLIC PROCEDURES] ---
  ! (none - pure TYPE definitions)

  !===================================================================
  ! SECTION 1: FOUR-KIND TYPE DEFINITIONS
  !===================================================================

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Desc
  ! KIND: Desc
  ! DESC: Immutable element definition - cold metadata from L3 Populate.
  !       Read-only during computation. Topology, node count, integration info.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Desc
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Elem_Cfg_Init_Desc) :: cfg    ! Config+Init fields (cfg%elem_type_id, cfg%family_id, cfg%ndim, cfg%section_type)
    TYPE(PH_Elem_Pop_Vld_Desc)  :: pop    ! Populate+Vld fields (pop%n_nodes, pop%n_dof, pop%dof_per_node, pop%n_integration, pop%n_elements)
    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE PH_Elem_Desc

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Ctx
  ! KIND: Ctx
  ! DESC: Per-element call-time context - hot scratch workspace.
  !       Thread-local, no memory across steps. Coordinates, displacements,
  !       Jacobian cache, integration point index.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Elem_Inc_Evo_Ctx)  :: inc    ! Inc+Evo fields (inc%step_idx, inc%incr_idx)
    TYPE(PH_Elem_Itr_Asm_Ctx)  :: itr    ! Itr+Asm fields (itr%current_ip, itr%current_elem, itr%det_J, itr%weight)
    TYPE(PH_Elem_Lcl_Comp_Ctx) :: lcl    ! Lcl+Comp workspace (lcl%u_elem, lcl%du_elem, lcl%dN_dX, lcl%J_mat)
    TYPE(PH_Elem_Lcl_Evo_Ctx)  :: evo    ! Lcl+Evo workspace (evo%Ke_mat, evo%Ke_geo, evo%Ke, evo%R_int)
    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE PH_Elem_Ctx

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_State
  ! KIND: State
  ! DESC: Mutable runtime state - hot output (RHS/AMATRX/SVARS/energy/mass).
  !       Updated each iteration/step. Convergence tracking.
  !       G8: Expanded with auxiliary TYPE nesting (Depth 2 cap),
  !           matching PH_Elem_Desc/Ctx/Algo pattern.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_State
    !--- NEW: Auxiliary TYPE nesting (G8) ---
    TYPE(PH_Elem_Stp_Evo_State) :: stp    ! Step-level evolution (stp%initialized, stp%stiffness_built, stp%current_step, stp%n_active_elems, stp%n_converged)
    TYPE(PH_Elem_Itr_Acc_State) :: itr    ! Iteration-level accumulation (itr%rhs, itr%amatrx, itr%svars, itr%energy, itr%mass)
    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE PH_Elem_State

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Stiff_Arg
  ! KIND: Arg (Phase 6A evaluation bundle)
  ! DESC: Argument bundle for element integrator interface - wraps geometry,
  !       material D-matrix, output stiffness, internal force, and status.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Stiff_Arg
    REAL(wp), POINTER     :: coords(:,:) => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: D_mat(:,:)  => NULL()  ! [IN]  constitutive matrix (nstrs, nstrs)
    REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! [IN]  element displacement (n_dof)
    REAL(wp), ALLOCATABLE :: Ke(:,:)                ! [OUT] element stiffness (n_dof, n_dof)
    REAL(wp), ALLOCATABLE :: R_int(:)               ! [OUT] internal force vector (n_dof)
  END TYPE PH_Elem_Stiff_Arg

  !---------------------------------------------------------------------------
  ! ABSTRACT INTERFACE: PH_Elem_Integrator_Ifc
  ! DESC: Procedure-as-Parameter strategy for element integration.
  !       Allows runtime substitution between standard/reduced/selective
  !       integration schemes without modifying dispatch logic.
  !---------------------------------------------------------------------------
  ABSTRACT INTERFACE
    SUBROUTINE PH_Elem_Integrator_Ifc(desc, state, arg, status)
      IMPORT :: PH_Elem_Desc, PH_Elem_State, PH_Elem_Stiff_Arg, i4
      TYPE(PH_Elem_Desc),      INTENT(IN)    :: desc
      TYPE(PH_Elem_State),     INTENT(INOUT) :: state
      TYPE(PH_Elem_Stiff_Arg), INTENT(INOUT) :: arg
      INTEGER(i4),              INTENT(OUT)   :: status
    END SUBROUTINE
  END INTERFACE

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Algo
  ! KIND: Algo
  ! DESC: Algorithm configuration - step-level settings for integration,
  !       hourglass control, NLGeom, mass type, Rayleigh damping.
  !       Phase 6A: integrator procedure pointer for strategy pattern.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Algo
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Elem_Stp_Ctl_Algo)     :: stp    ! Step+Ctl static params (stp%integration_order, stp%hourglass_control, etc.)
    TYPE(PH_Elem_Stp_Ctl_Dyn_Algo) :: dyn    ! Step+Ctl dynamic params (dyn%reduced_integ, dyn%mass_type, etc.)
    ! [Phase:Cfg|Verb:Brg] strategy pointer — bare field
    PROCEDURE(PH_Elem_Integrator_Ifc), POINTER, NOPASS :: integrator => NULL()
    !--- All fields moved to nested auxiliary TYPEs (Depth 2 cap) ---
  END TYPE PH_Elem_Algo

  !--- Legacy aliases for previous naming (PH_Elem_Base_*) ---
  !    PH_Elem_Base_Desc  => PH_Elem_Desc
  !    PH_Elem_Base_State => PH_Elem_State
  !    PH_Elem_Base_Algo  => PH_Elem_Algo
  !    PH_Elem_Base_Ctx   => PH_Elem_Ctx

  !===================================================================
  ! SECTION 1B: ARG TYPE DEFINITIONS - SIO Phase 3C
  !===================================================================

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Core_Ke_Arg
  ! DESC: Arg bundle for PH_Elem_Core_Compute_Ke.
  !       Wraps geometry, material D-matrix, output stiffness Ke.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Core_Ke_Arg
    REAL(wp), POINTER     :: coords(:,:) => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: D_mat(:,:)  => NULL()  ! [IN]  constitutive matrix (nstrs, nstrs)
    REAL(wp), ALLOCATABLE :: Ke(:,:)                ! [OUT] element stiffness (n_dof, n_dof)
  END TYPE PH_Elem_Core_Ke_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Core_Fe_Arg
  ! DESC: Arg bundle for PH_Elem_Core_Compute_Fe.
  !       Wraps geometry, body force, output force vector.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Core_Fe_Arg
    REAL(wp), POINTER     :: coords(:,:)    => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: body_force(:)  => NULL()  ! [IN]  body force per dim (ndim)
    REAL(wp), ALLOCATABLE :: Fe(:)                     ! [OUT] element force vector (n_dof)
  END TYPE PH_Elem_Core_Fe_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Core_Fint_Arg
  ! DESC: Arg bundle for PH_Elem_Core_Compute_Fint.
  !       Wraps geometry, GP stresses, output internal force.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Core_Fint_Arg
    REAL(wp), POINTER     :: coords(:,:)    => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: stress_gp(:,:) => NULL()  ! [IN]  stress at GPs (n_gp, nstrs)
    REAL(wp), ALLOCATABLE :: Fint(:)                   ! [OUT] internal force vector (n_dof)
  END TYPE PH_Elem_Core_Fint_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Core_Mass_Arg
  ! DESC: Arg bundle for PH_Elem_Core_Compute_Mass.
  !       Wraps geometry, density, output mass matrix.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Core_Mass_Arg
    REAL(wp), POINTER     :: coords(:,:) => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp)              :: rho = 0.0_wp           ! [IN]  material density
    REAL(wp), ALLOCATABLE :: Me(:,:)                ! [OUT] element mass matrix (n_dof, n_dof)
  END TYPE PH_Elem_Core_Mass_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Eval_Ke_Arg
  ! DESC: Arg bundle for PH_Elem_Eval_Ke (dispatch-level).
  !       Wraps geometry, material props, output stiffness.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Eval_Ke_Arg
    REAL(wp), POINTER     :: coords(:,:)   => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: mat_props(:)  => NULL()  ! [IN]  material property array
    REAL(wp), ALLOCATABLE :: Ke(:,:)                  ! [OUT] element stiffness (n_dof, n_dof)
  END TYPE PH_Elem_Eval_Ke_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Eval_Fe_Arg
  ! DESC: Arg bundle for PH_Elem_Eval_Fe (dispatch-level).
  !       Wraps geometry, displacements, load info, output force.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Eval_Fe_Arg
    REAL(wp), POINTER     :: coords(:,:)   => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp), POINTER     :: u(:)          => NULL()  ! [IN]  displacement vector (n_dof)
    INTEGER(i4)           :: load_case     = 0_i4     ! [IN]  load case number
    REAL(wp), POINTER     :: load_magn(:)  => NULL()  ! [IN]  load magnitude array
    REAL(wp), ALLOCATABLE :: Fe(:)                    ! [OUT] element force vector (n_dof)
  END TYPE PH_Elem_Eval_Fe_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Eval_Mass_Arg
  ! DESC: Arg bundle for PH_Elem_Eval_Mass (dispatch-level).
  !       Wraps geometry, density, output mass matrix.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Eval_Mass_Arg
    REAL(wp), POINTER     :: coords(:,:) => NULL()  ! [IN]  nodal coordinates (ndim, n_nodes)
    REAL(wp)              :: density = 0.0_wp       ! [IN]  material density
    REAL(wp), ALLOCATABLE :: Me(:,:)                ! [OUT] element mass matrix (n_dof, n_dof)
  END TYPE PH_Elem_Eval_Mass_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_ComplexStiff_Form_Arg
  ! DESC: Arg bundle for PH_Elem_ComplexStiff_Form.
  !       Wraps CSR stiffness data, structural damping ratio, output arrays.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_ComplexStiff_Form_Arg
    REAL(wp), POINTER     :: K_val(:)   => NULL()  ! [IN]  stiffness values (CSR)
    INTEGER(i4), POINTER  :: ia(:)      => NULL()  ! [IN]  CSR row pointer
    INTEGER(i4), POINTER  :: ja(:)      => NULL()  ! [IN]  CSR column indices
    INTEGER(i4)           :: nnz        = 0_i4     ! [IN]  number of non-zeros
    REAL(wp)              :: eta        = 0.0_wp   ! [IN]  structural damping ratio
    REAL(wp), ALLOCATABLE :: K_real(:)             ! [OUT] real part of K*
    REAL(wp), ALLOCATABLE :: K_imag(:)             ! [OUT] imaginary part of K*
  END TYPE PH_Elem_ComplexStiff_Form_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_NL_TL_Arg
  ! DESC: Arg bundle for nonlinear Total-Lagrangian element kernels.
  !       Wraps reference coords, displacement, constitutive D, outputs.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_NL_TL_Arg
    REAL(wp), POINTER     :: coords_ref(:,:) => NULL()  ! [IN]  reference coordinates
    REAL(wp), POINTER     :: u_elem(:)       => NULL()  ! [IN]  element displacement
    REAL(wp), POINTER     :: D(:,:)          => NULL()  ! [IN]  constitutive matrix
    REAL(wp), ALLOCATABLE :: Ke_mat(:,:)                ! [OUT] material stiffness
    REAL(wp), ALLOCATABLE :: Ke_geo(:,:)                ! [OUT] geometric stiffness
    REAL(wp), ALLOCATABLE :: R_int(:)                   ! [OUT] internal residual
  END TYPE PH_Elem_NL_TL_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_NL_UL_Arg
  ! DESC: Arg bundle for nonlinear Updated-Lagrangian element kernels.
  !       Wraps previous-step coords, displacement increment, D, outputs.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_NL_UL_Arg
    REAL(wp), POINTER     :: coords_prev(:,:) => NULL()  ! [IN]  previous-step coordinates
    REAL(wp), POINTER     :: u_incr(:)        => NULL()  ! [IN]  displacement increment
    REAL(wp), POINTER     :: D(:,:)           => NULL()  ! [IN]  constitutive matrix
    REAL(wp), ALLOCATABLE :: Ke_mat(:,:)                 ! [OUT] material stiffness
    REAL(wp), ALLOCATABLE :: Ke_geo(:,:)                 ! [OUT] geometric stiffness
    REAL(wp), ALLOCATABLE :: R_int(:)                    ! [OUT] internal residual
  END TYPE PH_Elem_NL_UL_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_JacB_Arg
  ! DESC: Arg bundle for Jacobian + B-matrix evaluation at a parametric point.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_JacB_Arg
    REAL(wp), POINTER     :: coords(:,:)  => NULL()  ! [IN]  nodal coordinates
    REAL(wp)              :: xi   = 0.0_wp           ! [IN]  parametric coord xi
    REAL(wp)              :: eta  = 0.0_wp           ! [IN]  parametric coord eta
    REAL(wp)              :: zeta = 0.0_wp           ! [IN]  parametric coord zeta (3D)
    REAL(wp), ALLOCATABLE :: N(:)                    ! [OUT] shape function values
    REAL(wp), ALLOCATABLE :: dNdx(:,:)               ! [OUT] shape func derivatives (phys)
    REAL(wp), ALLOCATABLE :: J(:,:)                  ! [OUT] Jacobian matrix
    REAL(wp)              :: detJ = 0.0_wp           ! [OUT] Jacobian determinant
    REAL(wp), ALLOCATABLE :: B(:,:)                  ! [OUT] strain-displacement matrix
  END TYPE PH_Elem_JacB_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Contact_Arg
  ! DESC: Arg bundle for element-level contact contribution kernels.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Contact_Arg
    INTEGER(i4)           :: edge_id     = 0_i4      ! [IN]  edge / surface id
    REAL(wp)              :: xi          = 0.0_wp    ! [IN]  parametric coord xi
    REAL(wp)              :: eta         = 0.0_wp    ! [IN]  parametric coord eta
    REAL(wp), POINTER     :: N(:)        => NULL()   ! [IN]  shape function values
    REAL(wp), POINTER     :: n_vec(:)    => NULL()   ! [IN]  outward normal vector
    REAL(wp)              :: gap         = 0.0_wp    ! [IN]  contact gap
    REAL(wp)              :: penalty     = 0.0_wp    ! [IN]  penalty factor
    REAL(wp)              :: edge_len    = 0.0_wp    ! [IN]  edge length
    REAL(wp), POINTER     :: coords(:,:) => NULL()   ! [IN]  nodal coordinates (edge center)
    REAL(wp), ALLOCATABLE :: K_el(:,:)               ! [OUT] contact stiffness contribution
    REAL(wp), ALLOCATABLE :: F_el(:)                 ! [OUT] contact force contribution
  END TYPE PH_Elem_Contact_Arg

  !---------------------------------------------------------------------------
  ! L5 RT_Asm 金线：单元 Ke/Fe 参数包（与 CONTRACT_Element.md PH_Element_Compute_* 对齐）
  ! %evo%Ke 嵌套与 PH_Elem_Ctx%evo / PH_Elem_Lcl_Evo_Ctx 一致；u 定长与 RT_ASM_MAX_ELEM_DOF 对齐。
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_ASSEMBLY_U_MAX = 120_i4

  TYPE, PUBLIC :: PH_Element_Compute_Ke_Arg
    INTEGER(i4) :: elem_idx     = 0_i4              ! [IN]  element index
    INTEGER(i4) :: l3_elem_idx  = 0_i4              ! [IN]  L3 element index
    INTEGER(i4) :: mat_pt_idx   = 0_i4              ! [IN]  material point index
    INTEGER(i4) :: nDof         = 0_i4              ! [IN]  number of DOFs
    ! L5 从 ph_layer%material%slot_pool(mat_pt_idx)%desc%props 拷贝注入；
    ! TARGET 供 PH_Elem_Domain%Compute_Ke 内 eva%mat_props => ，避免 L4 USE 全局容器。
    REAL(wp), ALLOCATABLE :: mat_props_in(:)        ! [IN]  material property array
    TYPE(PH_Elem_Lcl_Evo_Ctx) :: evo                ! [INOUT] element evolution workspace
    TYPE(ErrorStatusType) :: status                 ! [OUT] error status
  END TYPE PH_Element_Compute_Ke_Arg

  TYPE, PUBLIC :: PH_Element_Compute_Fe_Arg
    INTEGER(i4) :: l3_elem_idx = 0_i4              ! [IN]  L3 element index
    INTEGER(i4) :: mat_pt_idx  = 0_i4              ! [IN]  material point index
    INTEGER(i4) :: nDof        = 0_i4              ! [IN]  number of DOFs
    REAL(wp) :: u(PH_ELEM_ASSEMBLY_U_MAX) = 0.0_wp ! [IN]  element nodal displacements
    INTEGER(i4) :: load_case = 0_i4                 ! [IN]  load case number
    ! L5 注入载荷幅值向量（与 PH_Elem_Eval_Fe / Compute_Fe 的 load_magn 对齐）；
    ! TARGET 供 PH_Elem_Domain%Compute_Fe 内 eva%load_magn => ，避免 L4 USE 全局容器。
    ! 若 RT_Asm_GlobalLoad 已将同项体力/分布载写入 F_ext，此处须保持零，避免 R=F_ext-F_int 双计。
    REAL(wp), ALLOCATABLE :: load_magn_in(:)        ! [IN]  load magnitude array
    REAL(wp), ALLOCATABLE :: Fe(:)                  ! [OUT] element force vector
    TYPE(ErrorStatusType) :: status                 ! [OUT] error status
  END TYPE PH_Element_Compute_Fe_Arg

  !---------------------------------------------------------------------------
  ! TYPE: PH_Elem_Constraint_Arg
  ! DESC: Arg bundle for constraint application on element matrices.
  !---------------------------------------------------------------------------
  TYPE :: PH_Elem_Constraint_Arg
    INTEGER(i4)           :: ctype    = 0_i4         ! [IN]  constraint type code
    INTEGER(i4)           :: idof     = 0_i4         ! [IN]  local DOF index
    REAL(wp)              :: val      = 0.0_wp       ! [IN]  prescribed value
    REAL(wp)              :: penalty  = 0.0_wp       ! [IN]  penalty factor
    REAL(wp), ALLOCATABLE :: K_el(:,:)               ! [INOUT] element stiffness
    REAL(wp), ALLOCATABLE :: F_el(:)                 ! [INOUT] element force
  END TYPE PH_Elem_Constraint_Arg

  !--- SECTION 2: MODULE CONSTANTS ---
  ! (none)

  !===================================================================
  ! SECTION 3: Real SIO ArgHub Aggregations (defined here to break
  !            circular dependency with PH_Elem_Aux_Def)
  !===================================================================

  PUBLIC :: PH_Elem_Itr_Asm_ArgHub_Real
  PUBLIC :: PH_Elem_Lcl_Comp_ArgHub_Real
  PUBLIC :: PH_Elem_Lcl_Brg_ArgHub_Real

  TYPE, PUBLIC :: PH_Elem_Itr_Asm_ArgHub_Real
    TYPE(PH_Elem_Core_Ke_Arg)   :: Ke
    TYPE(PH_Elem_Core_Fe_Arg)   :: Fe
    TYPE(PH_Elem_Core_Fint_Arg) :: Fint
    TYPE(PH_Elem_Core_Mass_Arg) :: Mass
  END TYPE PH_Elem_Itr_Asm_ArgHub_Real

  TYPE, PUBLIC :: PH_Elem_Lcl_Comp_ArgHub_Real
    TYPE(PH_Elem_NL_TL_Arg)           :: nl_tl
    TYPE(PH_Elem_NL_UL_Arg)           :: nl_ul
    TYPE(PH_Elem_JacB_Arg)            :: jacb
    TYPE(PH_Elem_ComplexStiff_Form_Arg) :: cpx
  END TYPE PH_Elem_Lcl_Comp_ArgHub_Real

  TYPE, PUBLIC :: PH_Elem_Lcl_Brg_ArgHub_Real
    TYPE(PH_Elem_Contact_Arg)    :: contact
    TYPE(PH_Elem_Constraint_Arg) :: constr
  END TYPE PH_Elem_Lcl_Brg_ArgHub_Real

END MODULE PH_Elem_Def
