!===============================================================================
! Template: PH_XXX_UEL.f90                                      [Template v4.3]
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v4.3 (2026-03)  Single PH_XXX_UEL_Args (replaces _In/_Out pair); _Impl(args).
!   v4.2 (2026-03)  Add PH_XXX_UEL_In/_Out TYPE pair (Principle #14 SIO);
!                   split API/Impl; add svars load/store skeleton; improve
!                   Jacobian/B-matrix STUB comments; Impl exposed as PRIVATE.
!   v4.1 (prev)     sect_registry explicit; uel_status INTENT(OUT);
!                   nip from MD_Elem_Base_Desc%integ_npts
! Layer:  L4_PH - Physics Layer
! Domain: Element / [Family] (e.g., CONTI / SHELL / BEAM / TRUSS / ...)
!
! PURPOSE:
!   UFC-native element compute interface.
!   This module implements the element stiffness/residual computation using
!   the typed-struct 8-TYPE minimal system, NOT ABAQUS flat-array UEL ABI.
!
! Template choice (UFC 默认):
!   **Preferred** entry for new **element** work vs. `PH_XXX_Elem.f90` (four-type
!   minimal). Use UEL when you need section→material dispatch, per-GP UMAT calls,
!   and the documented SVARS / contract alignment with `PH_XXX_UMAT.f90`.
!
! DESIGN: "shen si ABAQUS UEL er xing bu si"  [8-TYPE minimal, v4.1]
!   - v4.1: sect_registry passed explicitly; uel_status INTENT(OUT); no module-level registry
!   - Material Desc: pointer from section (no value copy of polymorphic Desc)
!   - nip from MD_Elem_Base_Desc%integ_npts (>0 required); ntens from MD_Mat_Base_Algo%ntens
!   - PH_Elem_Base_Algo ELIMINATED: Newmark in RT_Com_Base_Ctx%newmark_params
!   - pnewdt bare REAL(wp) INOUT; ABAQUS adapter packs/unpacks only in adapter
!
! SECTION-AS-BRIDGE (UEL -> UMAT):
!   Section is resolved INSIDE PH_XXX_UEL_API using sect_registry passed by L5_RT.
!
!     ┌─ UEL kernel interface (v4.1, 7 arguments) ─────────────────────────────┐
!     │  PH_XXX_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx,             │
!     │                 PH_Elem_State, RT_Com_Ctx, pnewdt, uel_status)          │
!     │    uel_status: INTENT(OUT) structured ErrorStatusType status;          │
!     │               check uel_status%status_code == IF_STATUS_OK             │
!     │    mat_desc: CLASS pointer from registry; SELECT TYPE -> PH_*_UMAT_API │
!     └────────────────────────────────────────────────────────────────────────┘
!
! UEL -> UMAT CALL CHAIN:
!   [0] Resolve section_id = jprops(1) -> registry -> mat_desc pointer
!   [1] Per IP: B, dstran -> mat_ctx; CALL PH_XXX_UMAT_API(md, ...)
!
! PER-INTEGRATION-POINT STATE OWNERSHIP (do not misuse this template)
!   UFC_Harness (`ufc_harness/`) does not fix material layout; the contract lives in
!   `ufc_core` types.  In PH_Elem_Types.f90, ABAQUS SVARS maps to:
!     PH_Elem_Base_State % svars(:)   [nsvars, allocated by UEL bridge / L5 setup]
!   Decision (template default, aligned with core + adapter path):
!     * Authoritative persistence across increments and across Gauss points:
!         pack internal variables (stress, SDVs, history) into svars using a
!         documented layout:  svars( (ip-1)*stride + 1 : ip*stride )  or equivalent.
!     * The stack variable PH_Mat_XXX_State inside PH_XXX_UEL_API is only a
!         per-IP WORKSPACE for the current PH_XXX_UMAT_API call.  You MUST either:
!         (a) before each IP: load that slice of svars into PH_Mat_State; after
!             UMAT returns: write PH_Mat_State back to the same slice; or
!         (b) replace the stack scalar with an ALLOCATABLE array of size nip
!             (element-family extended State type), and still serialize to svars
!             at increment end if the runtime/ABAQUS adapter requires SVARS.
!   Prefer (a) when interoperability with SVARS/nsvars is required; (b) is for
!   pure UFC-native tests where L5 still mirrors SVARS length into svars.
!
! Fixed nsvars / IP slice table (authoritative):
!   ufc_core/L4_PH/contracts/CONTRACT_SVARS_IP_LAYOUT.md
! Material statev slot meanings (per mat_id):
!   docs/05_Project_Planning/PPLAN/06_核心架构/UFC_UMAT_Props_Statev_Layout.md
!
! NAMING: Module PH_[ElemType]_UEL; API PH_[ElemType]_UEL_API; XXX = C3D8, S4R, ...
!
! HOW TO USE:
!   1. Copy to L4_PH/Element/[Family]/, rename PH_[ElemType]_UEL.f90
!   2. Replace XXX -> element type; replace MD_Mat_XXX_Desc / PH_XXX_UMAT with real material
!   3. Set MD_Elem_Desc%integ_npts before call; ensure jprops(1)=section_id and ALLOCATED(jprops)
!   4. Fill MD_Mat_Algo%ndi/%nshr/%ntens (or rely on defaults 3/3/6 for 3D solid)
!   5. Implement XXX_Shape_Functions / Jacobian / B_Matrix for topology
!
! Contract: L4_PH/contracts/CONTRACT_UEL_UMAT_Element_Material.md
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  PH_XXX_UEL_API: 7 params (L4 ABI; 6 + uel_status; see v4.2 exception note)
!   SIO-02 ✓  _Impl 6th param is PH_XXX_UEL_Args (INOUT unified bundle)
!   SIO-03 ✓  PH_XXX_UEL_Args carries structured ErrorStatusType status ([OUT]);
!             check %status_code == IF_STATUS_OK
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  _In TYPE has no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  _In TYPE has no ALLOCATABLE members
!   NOTE: uel_status INTENT(OUT) is the L4 structured-status channel; pnewdt remains a
!         bare REAL(wp) INOUT for direct ABAQUS adapter compatibility.
!===============================================================================
MODULE PH_XXX_UEL
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_Elem_Types,   ONLY: MD_Elem_Base_Desc
  USE MD_Sect_Types,   ONLY: MD_Sect_Base_Desc, MD_Sect_Registry
  USE MD_Mat_Types,    ONLY: MD_Mat_Base_Desc, MD_Mat_Base_Algo
  USE PH_Elem_Types,   ONLY: PH_Elem_Base_Ctx, PH_Elem_Base_State
  USE PH_XXX_UMAT,     ONLY: PH_Mat_XXX_State, PH_XXX_UMAT_API   ! UMAT state + entry
  USE MD_Mat_XXX_XXX,  ONLY: MD_Mat_XXX_Desc                      ! [MD] Desc for SELECT TYPE
  USE PH_Mat_Types,    ONLY: PH_Mat_Base_Algo, PH_Mat_Base_Ctx
  USE RT_Com_Types,    ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_XXX_UEL_Args  ! Unified call-time IO bundle (Principle #14)
  PUBLIC :: PH_XXX_UEL_API   ! UFC-native UEL entry (thin wrapper -> _Impl)
  ! PH_XXX_UEL_Impl is PRIVATE: UEL physics lives there; API is pure glue.

  !---------------------------------------------------------------------------
  ! PH_XXX_UEL_Args — unified call-time bundle (Principle #14, L4 adaptation)
  !
  !   [IN]  flags and scalars only — SIO-14: no ALLOCATABLE; SIO-13: no
  !         _Desc/_State/_Algo/_Ctx members on this TYPE.
!   [OUT] status, pnewdt, diagnostics — SIO-03: structured ErrorStatusType
!         status; initialize with init_error_status(...) and inspect via %status_code.
  !
  !   Usage (L5_RT or harness calling _Impl directly):
  !     TYPE(PH_XXX_UEL_Args) :: uel_args
  !     uel_args%compute_amatrx = .TRUE.
  !     uel_args%success        = .FALSE.
  !     CALL PH_XXX_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx,
  !                           PH_Elem_State, RT_Com_Ctx, uel_args)
!     IF (uel_args%status%status_code == IF_STATUS_OK) pnewdt = uel_args%pnewdt
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_XXX_UEL_Args
    !-- [IN]
    LOGICAL     :: compute_amatrx = .TRUE.
    LOGICAL     :: compute_rhs    = .TRUE.
    INTEGER(i4) :: lflags_kstep   = 0_i4
    !-- TODO: element-type-specific [IN] fields (scalars / fixed arrays only)
    !-- [OUT]
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success      = .FALSE.
    REAL(wp)              :: pnewdt       = 1.0_wp
    REAL(wp)              :: strain_energy = 0.0_wp
    INTEGER(i4)           :: ip_failed    = 0_i4
    !-- TODO: element-specific [OUT] diagnostics
  END TYPE PH_XXX_UEL_Args

CONTAINS

  !===========================================================================
  ! PUBLIC API — thin wrapper (Principle #14 / SIO adaptation for L4_PH UEL)
  !===========================================================================
  !> PH_XXX_UEL_API
  !>
  !> ROLE: THIN WRAPPER ONLY — fills PH_XXX_UEL_Args, delegates to PH_XXX_UEL_Impl.
  !>   DO NOT add element physics here; implement in PH_XXX_UEL_Impl.
  !>
  !> Parameters (unchanged from v4.1 ABI — backward compatible):
  !>   sect_registry  [MD] section registry (TARGET for pointer resolution)
  !>   MD_Elem_Desc   [MD] element topology and property descriptor
  !>   PH_Elem_Ctx    [PH] per-increment element driving inputs (INOUT)
  !>   PH_Elem_State  [PH] UEL outputs: rhs, amatrx, svars, energy (INOUT)
  !>   RT_Com_Ctx     [RT] runtime bookkeeping: step, inc, lflags, etc.
  !>   pnewdt         [RT] REAL(wp) INOUT: minimum pnewdt across all IPs
  !>   uel_status     [OUT] structured ErrorStatusType status;
  !>                  check uel_status%status_code == IF_STATUS_OK
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE PH_XXX_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
      RT_Com_Ctx, pnewdt, uel_status)
    TYPE(MD_Sect_Registry),    INTENT(IN), TARGET :: sect_registry
    TYPE(MD_Elem_Base_Desc),   INTENT(IN)    :: MD_Elem_Desc
    TYPE(PH_Elem_Base_Ctx),    INTENT(INOUT) :: PH_Elem_Ctx
    TYPE(PH_Elem_Base_State),  INTENT(INOUT) :: PH_Elem_State
    TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                  INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType),     INTENT(OUT)   :: uel_status

    TYPE(PH_XXX_UEL_Args) :: uel_args

    uel_args%compute_amatrx = .TRUE.   ! TODO: read from lflags if needed
    uel_args%compute_rhs    = .TRUE.
    uel_args%lflags_kstep   = RT_Com_Ctx%lflags(1)
    !-- TODO: fill additional model-specific uel_args [IN] fields

    uel_args%success = .FALSE.    ! always reset before delegate call

    CALL PH_XXX_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
        RT_Com_Ctx, uel_args)

    pnewdt     = uel_args%pnewdt
    uel_status = uel_args%status
  END SUBROUTINE PH_XXX_UEL_API

  !===========================================================================
  ! PRIVATE IMPLEMENTATION — all UEL physics here
  !===========================================================================
  !> PH_XXX_UEL_Impl
  !>
  !>  Six-parameter inner interface (Principle #14, L4 hot-path form).
  !>  Callers: PH_XXX_UEL_API (production) and unit-test harness (direct).
  !>
  !>  Contract:
  !>    args%compute_amatrx  .FALSE. => skip K_e assembly (residual-only calls)
  !>    args%compute_rhs     .FALSE. => skip f_int assembly
  !>    args%success         .TRUE. IFF all IPs converged and state is valid
  !>    args%pnewdt          MIN(pnewdt_ip) across all integration points
  !>    args%ip_failed       index of first failed IP (0 if none)
  !>    PH_Elem_State        updated in-place for rhs, amatrx, svars, energy
  !>
  !>  SVARS LAYOUT (authoritative contract):
  !>    Stride per IP = nsvars_per_ip  (see CONTRACT_SVARS_IP_LAYOUT.md)
  !>    slot base = (ip-1) * nsvars_per_ip
  !>    [base+1 .. base+6]  : stress(6)        [Pa]
  !>    [base+7 .. base+12] : stran(6)         [-]
  !>    [base+13]           : ivar1 (e.g. peeq) [-]
  !>    [base+14]           : ivar2             [-]
  !>    Extend as needed; document in CONTRACT_SVARS_IP_LAYOUT.md.
  SUBROUTINE PH_XXX_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
      RT_Com_Ctx, args)
    TYPE(MD_Sect_Registry),    INTENT(IN), TARGET :: sect_registry
    TYPE(MD_Elem_Base_Desc),   INTENT(IN)    :: MD_Elem_Desc
    TYPE(PH_Elem_Base_Ctx),    INTENT(INOUT) :: PH_Elem_Ctx
    TYPE(PH_Elem_Base_State),  INTENT(INOUT) :: PH_Elem_State
    TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx
    TYPE(PH_XXX_UEL_Args),     INTENT(INOUT) :: args

    !-- Local variables (stack-allocated; NO ALLOCATE in hot path — SIO-09)
    !$UFC HOT_PATH
    INTEGER(i4) :: sect_id, sect_idx
    CLASS(MD_Mat_Base_Desc), POINTER :: mat_d => NULL()
    !-- Per-IP UMAT workspace: persistent SDVs live in PH_Elem_State%svars (see header)
    TYPE(PH_Mat_XXX_State)    :: PH_Mat_State
    TYPE(MD_Mat_Base_Algo)    :: MD_Mat_Algo
    TYPE(PH_Mat_Base_Algo)    :: PH_Mat_Algo
    REAL(wp)                  :: pnewdt_ip

    !-- TODO: adjust array sizes for actual element topology
    !   B(nt, ndofel): strain-displacement matrix [nt x ndofel]
    !   N(nnode):      shape function values at IP
    !   dNdX(mcrd, nnode): shape function physical derivatives
    REAL(wp) :: B(6,24), N(8), dNdX(3,8)
    REAL(wp) :: xi, eta, zeta, w_ip, det_J
    REAL(wp) :: dstran_ip(6), fint(24), pnewdt_min
    INTEGER(i4) :: ip, ndofel, nip, nt
    !-- svars load/store helpers
    INTEGER(i4) :: nsvars_per_ip, slot_base

    !-- SVARS stride: must match CONTRACT_SVARS_IP_LAYOUT.md
    !   For PH_Mat_XXX_State: stress(6) + stran(6) + ivar1 + ivar2 = 14 reals
    !   TODO: update NSVARS_PER_IP to match your actual state layout
    INTEGER(i4), PARAMETER :: NSVARS_PER_IP = 14

    CALL init_error_status(args%status)
    args%success       = .FALSE.
    args%pnewdt        = RT_PNEWDT_NO_CHANGE
    args%strain_energy = 0.0_wp
    args%ip_failed     = 0

    ndofel = MD_Elem_Desc%ndofel
    nip    = MD_Elem_Desc%integ_npts
    IF (nip <= 0) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_UEL_Impl]: MD_Elem_Desc%integ_npts must be > 0')
      RETURN
    END IF
    IF (.NOT. ALLOCATED(MD_Elem_Desc%jprops) .OR. SIZE(MD_Elem_Desc%jprops) < 1) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_UEL_Impl]: jprops(1) required for section_id')
      RETURN
    END IF
    IF (.NOT. ALLOCATED(PH_Elem_State%svars) .OR. &
        SIZE(PH_Elem_State%svars) < nip * NSVARS_PER_IP) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_UEL_Impl]: svars too small; expected nip*NSVARS_PER_IP slots')
      RETURN
    END IF

    pnewdt_min   = RT_PNEWDT_NO_CHANGE
    nsvars_per_ip = NSVARS_PER_IP
    nt = MD_Mat_Algo%ntens
    IF (nt < 1 .OR. nt > 6) nt = 6

    IF (ALLOCATED(PH_Elem_State%rhs))    PH_Elem_State%rhs    = 0.0_wp
    IF (ALLOCATED(PH_Elem_State%amatrx)) PH_Elem_State%amatrx = 0.0_wp
    PH_Elem_State%energy = 0.0_wp
    fint = 0.0_wp

    !-- Section registry lookup (NO hot-loop scan — SIO-10)
    sect_id  = MD_Elem_Desc%jprops(1)
    sect_idx = sect_registry%GetSectIdx(sect_id)
    IF (sect_idx == 0) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_UEL_Impl]: section_id not found in registry')
      RETURN
    END IF

    mat_d => sect_registry%sections(sect_idx)%mat_desc
    IF (.NOT. ASSOCIATED(mat_d)) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_UEL_Impl]: section mat_desc not associated')
      RETURN
    END IF

    DO ip = 1, nip
      !-----------------------------------------------------------------------
      ! SVARS LOAD: restore per-IP material state from persistent svars slice
      !   slot_base is 0-based; Fortran array is 1-based => add 1 explicitly.
      !   Layout contract: see NSVARS_PER_IP parameter and _Impl doc block.
      !-----------------------------------------------------------------------
      slot_base = (ip - 1) * nsvars_per_ip
      IF (ALLOCATED(PH_Elem_State%svars)) THEN
        PH_Mat_State%stress(1:6) = PH_Elem_State%svars(slot_base+1  : slot_base+6)
        PH_Mat_State%stran(1:6)  = PH_Elem_State%svars(slot_base+7  : slot_base+12)
        PH_Mat_State%ivar1       = PH_Elem_State%svars(slot_base+13)
        PH_Mat_State%ivar2       = PH_Elem_State%svars(slot_base+14)
        !-- TODO: load additional ISVs if NSVARS_PER_IP > 14
      END IF

      !-- Gauss point coordinates and weight
      CALL XXX_Get_Gauss_Point(ip, nip, xi, eta, zeta, w_ip)

      !-- Shape functions and physical derivatives
      CALL XXX_Shape_Functions(xi, eta, zeta, N)
      CALL XXX_Jacobian(PH_Elem_Ctx%coords, N, xi, eta, zeta, dNdX, det_J)

      IF (det_J <= 0.0_wp) THEN
        CALL init_error_status(args%status, IF_STATUS_ERROR, &
            message='[XXX_UEL_Impl]: non-positive Jacobian det at IP')
        args%ip_failed = ip
        args%pnewdt    = 0.0_wp
        RETURN
      END IF

      !-- B-matrix: strain-displacement operator [nt x ndofel]
      CALL XXX_B_Matrix(dNdX, B)

      !-- Strain increment at IP: delta_eps = B * delta_u
      dstran_ip(1:nt) = MATMUL(B(1:nt,1:ndofel), PH_Elem_Ctx%du(1,1:ndofel))
      IF (nt < 6) dstran_ip(nt+1:6) = 0.0_wp

      PH_Elem_Ctx%mat_ctx%dstran(1:nt) = dstran_ip(1:nt)
      IF (nt < 6) PH_Elem_Ctx%mat_ctx%dstran(nt+1:6) = 0.0_wp

      !-- Call UMAT for this IP (SELECT TYPE resolves to concrete Desc)
      pnewdt_ip = RT_PNEWDT_NO_CHANGE
      SELECT TYPE (md => mat_d)
      TYPE IS (MD_Mat_XXX_Desc)
        CALL PH_XXX_UMAT_API(md, PH_Elem_Ctx%mat_ctx, PH_Mat_State, &
            MD_Mat_Algo, PH_Mat_Algo, RT_Com_Ctx, pnewdt_ip)
      CLASS DEFAULT
        CALL init_error_status(args%status, IF_STATUS_ERROR, &
            message='[XXX_UEL_Impl]: mat_desc type mismatch' // &
            ' — for multi-material use UF_Mat_Eval_Dispatch pattern')
        args%ip_failed = ip
        args%pnewdt    = 0.0_wp
        RETURN
      END SELECT

      !-- Propagate UMAT error
      IF (PH_Mat_State%status%status_code /= IF_STATUS_OK) THEN
        args%status    = PH_Mat_State%status
        args%ip_failed = ip
        args%pnewdt    = 0.0_wp
        RETURN
      END IF

      pnewdt_min = MIN(pnewdt_min, pnewdt_ip)

      !-----------------------------------------------------------------------
      ! SVARS STORE: write updated material state back to persistent svars slice
      !   Must mirror the LOAD block above exactly.
      !   Write-back happens regardless of args%compute_rhs/amatrx flags —
      !   state variables ALWAYS persist after UMAT call.
      !-----------------------------------------------------------------------
      IF (ALLOCATED(PH_Elem_State%svars)) THEN
        PH_Elem_State%svars(slot_base+1  : slot_base+6)  = PH_Mat_State%stress(1:6)
        PH_Elem_State%svars(slot_base+7  : slot_base+12) = PH_Mat_State%stran(1:6)
        PH_Elem_State%svars(slot_base+13)                = PH_Mat_State%ivar1
        PH_Elem_State%svars(slot_base+14)                = PH_Mat_State%ivar2
        !-- TODO: store additional ISVs if NSVARS_PER_IP > 14
      END IF

      !-- Assemble internal force vector: f_int += B^T * sigma * det_J * w
      IF (args%compute_rhs .AND. ALLOCATED(PH_Elem_State%rhs)) THEN
        fint(1:ndofel) = fint(1:ndofel) &
            + MATMUL(TRANSPOSE(B(1:nt,1:ndofel)), PH_Mat_State%stress(1:nt)) &
            * det_J * w_ip
      END IF

      !-- Assemble stiffness matrix: K += B^T * D_tan * B * det_J * w
      IF (args%compute_amatrx .AND. ALLOCATED(PH_Elem_State%amatrx)) THEN
        PH_Elem_State%amatrx(1:ndofel,1:ndofel) = &
            PH_Elem_State%amatrx(1:ndofel,1:ndofel) &
            + MATMUL(MATMUL(TRANSPOSE(B(1:nt,1:ndofel)), &
                            PH_Mat_State%ddsdde(1:nt,1:nt)), &
                     B(1:nt,1:ndofel)) * det_J * w_ip
      END IF

      !-- Accumulate elastic strain energy (energy(1) = SSE)
      args%strain_energy = args%strain_energy &
          + PH_Mat_State%elastic_energy * det_J * w_ip
      PH_Elem_State%energy(1) = PH_Elem_State%energy(1) &
          + PH_Mat_State%elastic_energy * det_J * w_ip
      !-- TODO: energy(2..8) = other ABAQUS energy components
      !   energy(2) = SPD (plastic), (3)=SCD (creep), (4)=RPCRT, (5)=AENRGY,
      !   (6)=ELCD,  (7)=ETOTAL,    (8)=DMENER — see ABAQUS UEL doc §2.1
    END DO

    IF (args%compute_rhs .AND. ALLOCATED(PH_Elem_State%rhs)) &
        PH_Elem_State%rhs(1:ndofel,1) = -fint(1:ndofel)

    args%pnewdt = MIN(RT_PNEWDT_NO_CHANGE, pnewdt_min)
    args%success = .TRUE.
    CALL init_error_status(args%status, IF_STATUS_OK)

  CONTAINS

    !=========================================================================
    ! ELEMENT-TOPOLOGY PRIVATE HELPERS
    !   All contained in PH_XXX_UEL_Impl (not visible outside the subroutine).
    !   When instantiating: implement the actual formulas for your element type.
    !=========================================================================

    !> XXX_Get_Gauss_Point
    !>   Return natural coordinates (xi, eta, zeta) and weight w for point ip.
    !>   Default: 2x2x2 Gauss rule for trilinear hexahedron (8 IPs).
    !>   For nip=1 (reduced integration): ip=1 at (0,0,0), w=8.
    !>   For shell (nip=4): drop zeta; adjust npts logic.
    SUBROUTINE XXX_Get_Gauss_Point(ip, npts, xi_out, eta_out, zeta_out, w_out)
      INTEGER(i4), INTENT(IN)  :: ip, npts
      REAL(wp),    INTENT(OUT) :: xi_out, eta_out, zeta_out, w_out
      REAL(wp), PARAMETER :: GP1 = 0.577350269189626_wp  ! 1/sqrt(3)
      !-- TODO: add CASE for npts==1 (reduced integration) if needed
      SELECT CASE (ip)
      CASE (1)
        xi_out  = -GP1
        eta_out = -GP1
        zeta_out= -GP1
        w_out   = 1.0_wp
      CASE (2)
        xi_out  =  GP1
        eta_out = -GP1
        zeta_out= -GP1
        w_out   = 1.0_wp
      CASE (3)
        xi_out  =  GP1
        eta_out =  GP1
        zeta_out= -GP1
        w_out   = 1.0_wp
      CASE (4)
        xi_out  = -GP1
        eta_out =  GP1
        zeta_out= -GP1
        w_out   = 1.0_wp
      CASE (5)
        xi_out  = -GP1
        eta_out = -GP1
        zeta_out=  GP1
        w_out   = 1.0_wp
      CASE (6)
        xi_out  =  GP1
        eta_out = -GP1
        zeta_out=  GP1
        w_out   = 1.0_wp
      CASE (7)
        xi_out  =  GP1
        eta_out =  GP1
        zeta_out=  GP1
        w_out   = 1.0_wp
      CASE (8)
        xi_out  = -GP1
        eta_out =  GP1
        zeta_out=  GP1
        w_out   = 1.0_wp
      CASE DEFAULT  ! npts outside 1..8 — zero weight => contributes nothing
        xi_out  = 0.0_wp
        eta_out = 0.0_wp
        zeta_out= 0.0_wp
        w_out   = 0.0_wp
      END SELECT
    END SUBROUTINE XXX_Get_Gauss_Point

    !> XXX_Shape_Functions
    !>   Trilinear hexahedron (C3D8) shape functions N_a(xi,eta,zeta).
    !>   Node ordering follows ABAQUS C3D8 convention (see ProgGuide §2.3).
    !>   For other topologies (C3D4, S4R, C3D20R):
    !>     Extend SIZE check and add appropriate N_out(a) formulas.
    SUBROUTINE XXX_Shape_Functions(xi_in, eta_in, zeta_in, N_out)
      REAL(wp), INTENT(IN)  :: xi_in, eta_in, zeta_in
      REAL(wp), INTENT(OUT) :: N_out(:)  ! size must be >= nnode
      N_out = 0.0_wp
      IF (SIZE(N_out) < 8) RETURN   ! guard: wrong topology
      N_out(1) = 0.125_wp*(1.0_wp-xi_in)*(1.0_wp-eta_in)*(1.0_wp-zeta_in)
      N_out(2) = 0.125_wp*(1.0_wp+xi_in)*(1.0_wp-eta_in)*(1.0_wp-zeta_in)
      N_out(3) = 0.125_wp*(1.0_wp+xi_in)*(1.0_wp+eta_in)*(1.0_wp-zeta_in)
      N_out(4) = 0.125_wp*(1.0_wp-xi_in)*(1.0_wp+eta_in)*(1.0_wp-zeta_in)
      N_out(5) = 0.125_wp*(1.0_wp-xi_in)*(1.0_wp-eta_in)*(1.0_wp+zeta_in)
      N_out(6) = 0.125_wp*(1.0_wp+xi_in)*(1.0_wp-eta_in)*(1.0_wp+zeta_in)
      N_out(7) = 0.125_wp*(1.0_wp+xi_in)*(1.0_wp+eta_in)*(1.0_wp+zeta_in)
      N_out(8) = 0.125_wp*(1.0_wp-xi_in)*(1.0_wp+eta_in)*(1.0_wp+zeta_in)
    END SUBROUTINE XXX_Shape_Functions

    !> XXX_Jacobian
    !>   Compute physical shape-function derivatives dN/dX and Jacobian det.
    !>   J_{ij} = sum_a (dN_a/d_xi_j) * X_{ai}
    !>   dNdX_{ij} = J^{-1}_{ij} * dN/d_xi   (chain rule)
    !>
    !>   TODO: implement
    !>     1. Build dNdxi(3,nnode): dN_a/d_xi, dN_a/d_eta, dN_a/d_zeta
    !>     2. J(3,3)    = MATMUL(dNdxi, coords_in^T)
    !>     3. Jdet      = determinant(J) — check > 0 on return
    !>     4. Jinv(3,3) = inverse(J)
    !>     5. dNdX_out  = MATMUL(Jinv, dNdxi)
    !>   Reference: Zienkiewicz & Taylor Vol.1, Ch.7
    SUBROUTINE XXX_Jacobian(coords_in, N_in, xi_in, eta_in, zeta_in, &
        dNdX_out, detJ_out)
      REAL(wp), INTENT(IN)  :: coords_in(:,:)  ! [mcrd, nnode] nodal coords
      REAL(wp), INTENT(IN)  :: N_in(:)          ! [nnode] shape values (unused here but
      REAL(wp), INTENT(IN)  :: xi_in, eta_in, zeta_in  !  kept for future serendipity)
      REAL(wp), INTENT(OUT) :: dNdX_out(:,:)    ! [3, nnode] physical deriv.
      REAL(wp), INTENT(OUT) :: detJ_out         ! Jacobian determinant
      !-- TODO: replace stubs with actual implementation (see doc block above)
      dNdX_out = 0.0_wp
      detJ_out = 1.0_wp   ! stub returns 1.0 to avoid false non-positive Jac error
      !-- STUB REMINDER: a real det_J of 1.0 for every IP means geometry is ignored.
      !   The IP loop guard (det_J <= 0) will not fire, but assembled matrices will
      !   be WRONG until this subroutine is fully implemented.
    END SUBROUTINE XXX_Jacobian

    !> XXX_B_Matrix
    !>   Strain-displacement matrix B [nt x ndofel] from physical derivatives dNdX.
    !>   Voigt layout for 3D solid (nt=6):
    !>     row 1: d/dX  (eps_11)
    !>     row 2: d/dY  (eps_22)
    !>     row 3: d/dZ  (eps_33)
    !>     row 4: d/dY + d/dX (2*eps_12 = gamma_12)
    !>     row 5: d/dZ + d/dX (2*eps_13)
    !>     row 6: d/dZ + d/dY (2*eps_23)
    !>   For node a, columns (3*a-2, 3*a-1, 3*a) contribute:
    !>     B(1,3a-2)=dN_a/dX,  B(4,3a-2)=dN_a/dY,  B(5,3a-2)=dN_a/dZ
    !>     B(2,3a-1)=dN_a/dY,  B(4,3a-1)=dN_a/dX,  B(6,3a-1)=dN_a/dZ
    !>     B(3,3a  )=dN_a/dZ,  B(5,3a  )=dN_a/dX,  B(6,3a  )=dN_a/dY
    !>   TODO: implement the loop over nodes using dNdX_in.
    SUBROUTINE XXX_B_Matrix(dNdX_in, B_out)
      REAL(wp), INTENT(IN)  :: dNdX_in(:,:)  ! [3, nnode] physical deriv.
      REAL(wp), INTENT(OUT) :: B_out(:,:)    ! [nt, ndofel]
      !-- TODO: replace stub with actual B-matrix assembly (see doc block above)
      B_out = 0.0_wp
      !-- STUB REMINDER: zero B means zero strain; internal forces will be zero.
      !   Implement before any mechanical analysis.
    END SUBROUTINE XXX_B_Matrix

  END SUBROUTINE PH_XXX_UEL_Impl

END MODULE PH_XXX_UEL
