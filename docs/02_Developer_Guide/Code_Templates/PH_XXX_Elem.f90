!===============================================================================
! Template: PH_XXX_Elem.f90                          [Template v2.0]
! Changelog:
!   v2.0 (2026-03)  Remove _In/_Out wrapper; use four types directly.
!                   Hot-path optimization: no interface abstraction overhead.
!   v1.2 (prev)     Had _In/_Out wrapper (over-designed for single module).
! Layer:  L4_PH - Physics Layer
! Domain: Element / [Family] (e.g., CONTI / SHELL / BEAM / TRUSS / ...)
!
! Purpose:
!   Hot-path element stiffness and internal force computation.
!   Four-type interface: Desc, State, Algo, Ctx.
!
! Template choice (UFC 默认):
!   For new **element** implementations, **prefer `PH_XXX_UEL.f90`** (section bridge,
!   per-IP UMAT, SVARS layout, SIO API/Impl split). Use **this** `PH_XXX_Elem.f90`
!   only when you deliberately want the minimal **four-type** call without the
!   UEL-shaped entry (`PH_XXX_Elem_Compute`).
!
! Four types:
!   Desc  — Element topology, material properties (cold path, read-only)
!   State — rhs, amatrx, svars, pnewdt, energy (hot path, read-write)
!   Algo  — compute_amatrx, compute_rhs, lflags (iter-read)
!   Ctx   — coords, disp_total, du, mat_ctx (hot buffer, no ALLOCATABLE)
!
! Call chain:
!   L5_RT RT_XXX_Elem_Proc
!     └─ PH_XXX_Elem_Compute(Desc, State, Algo, Ctx)  ← 4-param hot path
!
! Design principles:
!   SIO-01 ✓  Uses (Desc, State, Algo, Ctx) four-parameter form
!   SIO-09 ✓  No ALLOCATE in hot path (pre-allocated by init phase)
!   SIO-10 ✓  No hot-loop registry scan (resolved before calling this)
!   NO _In/_Out wrapper (hot-path modules forbid interface abstraction)
!
! HOW TO USE:
!   1. Copy to L4_PH/Element/[Family]/PH_XXX_Elem_Compute.f90
!   2. Replace XXX -> [Family]_[Model] (e.g., CONTI_C3D8)
!   3. Implement element physics in subroutine body
!===============================================================================
MODULE PH_XXX_Elem
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE MD_Elem_Types,   ONLY: MD_Elem_Base_Desc
  USE MD_Sect_Types,   ONLY: MD_Sect_Registry
  USE MD_Mat_Types,    ONLY: MD_Mat_Base_Desc, MD_Mat_Base_Algo
  USE PH_Elem_Types,   ONLY: PH_Elem_Base_Ctx, PH_Elem_Base_State
  USE PH_XXX_UMAT,     ONLY: PH_Mat_XXX_State, PH_XXX_UMAT_API
  USE MD_Mat_XXX_XXX,  ONLY: MD_Mat_XXX_Desc
  USE PH_Mat_Types,    ONLY: PH_Mat_Base_Algo, PH_Mat_Base_Ctx
  USE RT_Com_Types,    ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_XXX_Elem_Compute

CONTAINS

  !============================================================================
  !> PH_XXX_Elem_Compute — Hot-path element computation
  !>
  !> Four-parameter SIO form: (Desc, State, Algo, Ctx)
  !>
  !> Pre-condition:
  !>   State%amatrx and State%rhs must be pre-allocated during init phase.
  !>
  !> Contract:
  !>   Algo%compute_amatrx .FALSE. => skip stiffness assembly
  !>   Algo%compute_rhs    .FALSE. => skip residual assembly
  !>   State%pnewdt        MIN(pnewdt_ip) across all integration points
  !>   State%success       .TRUE. IFF all IPs converged
  !>
  !> SVARS layout (per IP):
  !>   slot = (ip-1) * NSVARS_PER_IP
  !>   [base+1..6]  : stress(6)
  !>   [base+7..12] : stran(6)
  !>   [base+13]    : ivar1 (e.g., peeq)
  !>   [base+14]    : ivar2
  !============================================================================
  ! Phase: Compute | Compute | HOT_PATH
  SUBROUTINE PH_XXX_Elem_Compute(Desc, State, Algo, Ctx)
    TYPE(MD_Elem_Base_Desc),  INTENT(IN)    :: Desc
    TYPE(PH_Elem_Base_State), INTENT(INOUT) :: State
    TYPE(RT_Com_Base_Ctx),    INTENT(IN)    :: Algo
    TYPE(PH_Elem_Base_Ctx),   INTENT(INOUT) :: Ctx

    !-- Material resolution (resolved before calling this — SIO-10)
    INTEGER(i4) :: SectIdx
    CLASS(MD_Mat_Base_Desc), POINTER :: MatDesc => NULL()

    !-- Per-IP UMAT workspace
    TYPE(PH_Mat_XXX_State) :: Mat_State
    TYPE(MD_Mat_Base_Algo) :: Mat_Algo
    TYPE(PH_Mat_Base_Algo) :: Mat_Algo_PH

    !-- Element arrays (stack-allocated; NO ALLOCATE in hot path)
    INTEGER(i4), PARAMETER :: NSVARS_PER_IP = 14
    REAL(wp) :: B(6,24), N(8), dNdX(3,8)
    REAL(wp) :: Xi, Eta, Zeta, W_IP, DetJ
    REAL(wp) :: DstranIP(6), Fint(24), PnewdtIP
    INTEGER(i4) :: IP, NDof, NIP, NT
    INTEGER(i4) :: SlotBase

    !-- Initialize
    CALL init_error_status(State%status)
    State%success = .FALSE.
    State%pnewdt  = RT_PNEWDT_NO_CHANGE
    State%energy  = 0.0_wp

    NDof = Desc%ndofel
    NIP  = Desc%integ_npts

    IF (NIP <= 0) THEN
      CALL init_error_status(State%status, IF_STATUS_ERROR, &
          message='[XXX_Elem_Compute]: integ_npts must be > 0')
      RETURN
    END IF

    !-- Initialize output arrays (zero-fill; pre-allocated by init phase)
    IF (ALLOCATED(State%rhs))     State%rhs     = 0.0_wp
    IF (ALLOCATED(State%amatrx)) State%amatrx  = 0.0_wp
    Fint = 0.0_wp

    NT = Mat_Algo%ntens
    IF (NT < 1 .OR. NT > 6) NT = 6

    !-- Per-integration-point loop
    DO IP = 1, NIP
      !-- SVARS LOAD: restore per-IP material state
      SlotBase = (IP - 1) * NSVARS_PER_IP
      IF (ALLOCATED(State%svars)) THEN
        Mat_State%stress(1:6) = State%svars(SlotBase+1  : SlotBase+6)
        Mat_State%stran(1:6)  = State%svars(SlotBase+7  : SlotBase+12)
        Mat_State%ivar1        = State%svars(SlotBase+13)
        Mat_State%ivar2        = State%svars(SlotBase+14)
      END IF

      !-- Gauss point and Jacobian
      CALL XXX_Get_Gauss_Point(IP, NIP, Xi, Eta, Zeta, W_IP)
      CALL XXX_Shape_Functions(Xi, Eta, Zeta, N)
      CALL XXX_Jacobian(Ctx%coords, N, Xi, Eta, Zeta, dNdX, DetJ)

      IF (DetJ <= 0.0_wp) THEN
        CALL init_error_status(State%status, IF_STATUS_ERROR, &
            message='[XXX_Elem_Compute]: non-positive Jacobian at IP')
        State%ip_failed = IP
        State%pnewdt    = 0.0_wp
        RETURN
      END IF

      !-- B-matrix and strain increment
      CALL XXX_B_Matrix(dNdX, B)
      DstranIP(1:NT) = MATMUL(B(1:NT, 1:NDof), Ctx%du(1, 1:NDof))
      IF (NT < 6) DstranIP(NT+1:6) = 0.0_wp
      Ctx%mat_ctx%dstran(1:NT) = DstranIP(1:NT)
      IF (NT < 6) Ctx%mat_ctx%dstran(NT+1:6) = 0.0_wp

      !-- Call UMAT
      PnewdtIP = RT_PNEWDT_NO_CHANGE
      MatDesc => Desc%mat_desc  ! Assumes mat_desc pointer set before call
      SELECT TYPE (md => MatDesc)
      TYPE IS (MD_Mat_XXX_Desc)
        CALL PH_XXX_UMAT_API(md, Ctx%mat_ctx, Mat_State, &
                             Mat_Algo, Mat_Algo_PH, Algo, PnewdtIP)
      CLASS DEFAULT
        CALL init_error_status(State%status, IF_STATUS_ERROR, &
            message='[XXX_Elem_Compute]: mat_desc type mismatch')
        State%ip_failed = IP
        State%pnewdt    = 0.0_wp
        RETURN
      END SELECT

      IF (Mat_State%status%status_code /= IF_STATUS_OK) THEN
        State%status    = Mat_State%status
        State%ip_failed = IP
        State%pnewdt    = 0.0_wp
        RETURN
      END IF

      State%pnewdt = MIN(State%pnewdt, PnewdtIP)

      !-- SVARS STORE
      IF (ALLOCATED(State%svars)) THEN
        State%svars(SlotBase+1  : SlotBase+6)  = Mat_State%stress(1:6)
        State%svars(SlotBase+7  : SlotBase+12) = Mat_State%stran(1:6)
        State%svars(SlotBase+13)                = Mat_State%ivar1
        State%svars(SlotBase+14)                = Mat_State%ivar2
      END IF

      !-- Assemble internal force
      IF (Algo%compute_rhs .AND. ALLOCATED(State%rhs)) THEN
        Fint(1:NDof) = Fint(1:NDof) &
            + MATMUL(TRANSPOSE(B(1:NT, 1:NDof)), Mat_State%stress(1:NT)) &
            * DetJ * W_IP
      END IF

      !-- Assemble stiffness matrix
      IF (Algo%compute_amatrx .AND. ALLOCATED(State%amatrx)) THEN
        State%amatrx(1:NDof, 1:NDof) = &
            State%amatrx(1:NDof, 1:NDof) &
            + MATMUL(MATMUL(TRANSPOSE(B(1:NT, 1:NDof)), &
                            Mat_State%ddsdde(1:NT, 1:NT)), &
                     B(1:NT, 1:NDof)) * DetJ * W_IP
      END IF

      !-- Accumulate energy
      State%energy(1) = State%energy(1) + Mat_State%elastic_energy * DetJ * W_IP
    END DO

    !-- Finalize residual (ABAQUS convention: rhs = -f_int)
    IF (Algo%compute_rhs .AND. ALLOCATED(State%rhs)) &
        State%rhs(1:NDof, 1) = -Fint(1:NDof)

    State%pnewdt  = MIN(RT_PNEWDT_NO_CHANGE, State%pnewdt)
    State%success = .TRUE.
    CALL init_error_status(State%status, IF_STATUS_OK)

  CONTAINS

    SUBROUTINE XXX_Get_Gauss_Point(IP, NPts, Xi, Eta, Zeta, W)
      INTEGER(i4), INTENT(IN)  :: IP, NPts
      REAL(wp),    INTENT(OUT) :: Xi, Eta, Zeta, W
      REAL(wp), PARAMETER :: GP1 = 0.577350269189626_wp
      SELECT CASE (IP)
      CASE (1);  Xi = -GP1; Eta = -GP1; Zeta = -GP1; W = 1.0_wp
      CASE (2);  Xi =  GP1; Eta = -GP1; Zeta = -GP1; W = 1.0_wp
      CASE (3);  Xi =  GP1; Eta =  GP1; Zeta = -GP1; W = 1.0_wp
      CASE (4);  Xi = -GP1; Eta =  GP1; Zeta = -GP1; W = 1.0_wp
      CASE (5);  Xi = -GP1; Eta = -GP1; Zeta =  GP1; W = 1.0_wp
      CASE (6);  Xi =  GP1; Eta = -GP1; Zeta =  GP1; W = 1.0_wp
      CASE (7);  Xi =  GP1; Eta =  GP1; Zeta =  GP1; W = 1.0_wp
      CASE (8);  Xi = -GP1; Eta =  GP1; Zeta =  GP1; W = 1.0_wp
      CASE DEFAULT; Xi = 0.0_wp; Eta = 0.0_wp; Zeta = 0.0_wp; W = 0.0_wp
      END SELECT
    END SUBROUTINE XXX_Get_Gauss_Point

    SUBROUTINE XXX_Shape_Functions(Xi, Eta, Zeta, N)
      REAL(wp), INTENT(IN)  :: Xi, Eta, Zeta
      REAL(wp), INTENT(OUT) :: N(:)
      N = 0.0_wp
      IF (SIZE(N) < 8) RETURN
      N(1) = 0.125_wp*(1.0_wp-Xi)*(1.0_wp-Eta)*(1.0_wp-Zeta)
      N(2) = 0.125_wp*(1.0_wp+Xi)*(1.0_wp-Eta)*(1.0_wp-Zeta)
      N(3) = 0.125_wp*(1.0_wp+Xi)*(1.0_wp+Eta)*(1.0_wp-Zeta)
      N(4) = 0.125_wp*(1.0_wp-Xi)*(1.0_wp+Eta)*(1.0_wp-Zeta)
      N(5) = 0.125_wp*(1.0_wp-Xi)*(1.0_wp-Eta)*(1.0_wp+Zeta)
      N(6) = 0.125_wp*(1.0_wp+Xi)*(1.0_wp-Eta)*(1.0_wp+Zeta)
      N(7) = 0.125_wp*(1.0_wp+Xi)*(1.0_wp+Eta)*(1.0_wp+Zeta)
      N(8) = 0.125_wp*(1.0_wp-Xi)*(1.0_wp+Eta)*(1.0_wp+Zeta)
    END SUBROUTINE XXX_Shape_Functions

    SUBROUTINE XXX_Jacobian(Coords, N, Xi, Eta, Zeta, dNdX, DetJ)
      REAL(wp), INTENT(IN)  :: Coords(:,:), N(:), Xi, Eta, Zeta
      REAL(wp), INTENT(OUT) :: dNdX(:,:), DetJ
      ! TODO: implement full Jacobian calculation
      dNdX = 0.0_wp; DetJ = 1.0_wp
    END SUBROUTINE XXX_Jacobian

    SUBROUTINE XXX_B_Matrix(dNdX, B)
      REAL(wp), INTENT(IN)  :: dNdX(:,:)
      REAL(wp), INTENT(OUT) :: B(:,:)
      ! TODO: implement B-matrix assembly for 3D solid (nt=6, ndofel=24)
      B = 0.0_wp
    END SUBROUTINE XXX_B_Matrix

  END SUBROUTINE PH_XXX_Elem_Compute

END MODULE PH_XXX_Elem
